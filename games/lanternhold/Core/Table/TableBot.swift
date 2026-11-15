/// Soldiers out with a road lantern: 0 without the table. The reference bot counts them as its own army, so it does not
/// recruit in their place while they are on the road (the hook in `Autoplay.planDay`, docs/lanes/quests.md); a lantern
/// that does not come home takes its soldiers off the road, and the bot replaces them as fallen.
extension GameState {
    var archersOnTheRoad: Int { table?.soldiersOut(.archer) ?? 0 }
    var guardsOnTheRoad: Int { table?.soldiersOut(.guardsman) ?? 0 }
}

extension TableState {
    /// The soldiers of a kind out with every party on the road.
    func soldiersOut(_ kind: SoldierKind) -> Int {
        var count = 0
        for sending in out {
            for soldier in sending.lent where soldier.kind == kind { count += 1 }
        }
        return count
    }

    /// True while every road lantern of the rail (38, 39, 40; not the reserved 41) is out with a party.
    var allRoadLanternsOut: Bool {
        let road = lanterns.filter { !$0.reserved }
        return !road.isEmpty && road.allSatisfy { $0.state == .out }
    }
}

/// The Lantern Table's two bots (docs/QUESTS.md 4.3). They ride on the reference bot (`Autoplay`), which keeps
/// building, recruiting and holding the audience as it always does; once a day, by day and after the audience, a table
/// bot uncovers the table, reads every waiting report and sends.
/// - `sender`: reads each report with Odile's counsel (when the counsel holds today and can be taken, else the first
///   choice that neither costs nor gives people or gold, else the first that costs nothing) and sends every offered
///   order that carries Odile's seal today (`ErrandEngine.sealHolds`) and that it can pay, lowest number first.
/// - `greedy`: reads each report with the choice that brings the most people, then the most gold; sends whatever it
///   can pay, red chips too, always the second order first where a sending has two. It exists to prove that sending
///   everything is not the best way to play.
/// Both keep what the tuning measures: the days all three road lanterns were out (T11), the sendings they wanted and
/// could not send only for want of a lantern on the hook (T11), and a log of what went.
struct TableBot: Sendable, Equatable {
    enum Policy: String, Sendable, CaseIterable {
        case sender, greedy
    }

    let policy: Policy
    /// The day the bot last looked at the table (it looks once a day).
    private(set) var lookedDay = 0
    /// Sendings the bot wanted on some day and could not send only because no lantern hung on the hook.
    private(set) var starved: Set<String> = []
    /// The days on which all three road lanterns were out after the bot's morning at the table.
    private(set) var fullDays: [Int] = []
    /// "5:highcairn_count.1" for every sending, in the order they left (day, id, order from 1).
    private(set) var log: [String] = []
    /// Reports the bot has answered.
    private(set) var reportsRead = 0

    init(policy: Policy) {
        self.policy = policy
    }

    static let sender = TableBot(policy: .sender)
    static let greedy = TableBot(policy: .greedy)

    /// Called after the reference bot, before every simulation step; acts on the first step of a day within the
    /// table's hours (06:00 to 18:00).
    mutating func act(_ s: inout GameState, catalog: ErrandCatalog, balance: Balance) {
        guard !s.defeated, s.mode == .chapter, s.day >= ErrandEngine.firstDay, s.day != lookedDay,
              DayClock.phase(at: s.hour) == .day, ErrandEngine.sendHours.contains(s.hour) else { return }
        lookedDay = s.day
        ErrandEngine.uncover(&s, catalog: catalog)
        guard s.table != nil else { return }
        readReports(&s, catalog: catalog, balance: balance)
        for errand in ErrandEngine.offers(s, catalog: catalog) {
            send(errand, &s, catalog: catalog, balance: balance)
        }
        if s.table?.allRoadLanternsOut == true { fullDays.append(s.day) }
    }

    /// The offered sendings that stayed unsent although the bot wanted them on a day with no lantern on the hook.
    func unsentForWantOfAHook(_ s: GameState) -> [String] {
        let sent = Set(s.table?.sent ?? [])
        return starved.subtracting(sent).sorted()
    }

    // MARK: - Reports

    private mutating func readReports(_ s: inout GameState, catalog: ErrandCatalog, balance: Balance) {
        var rounds = 0
        while rounds < 16, let table = s.table, let position = ErrandEngine.nextReport(table, catalog: catalog),
              let report = catalog.report(table.reports[position].report) {
            rounds += 1
            guard let pick = choice(report, s),
                  ErrandEngine.read(&s, at: position, choice: pick, catalog: catalog, balance: balance) != nil else {
                return
            }
            reportsRead += 1
        }
    }

    /// The bot's answer to a report today (nil when no choice can be taken).
    func choice(_ report: TableReport, _ s: GameState) -> Int? {
        let open = report.choices.indices.filter { ErrandEngine.readBlock(report.choices[$0], s) == nil }
        guard !open.isEmpty else { return nil }
        switch policy {
        case .sender:
            if let counsel = ErrandEngine.counsel(report, s), open.contains(counsel) { return counsel }
            // Without the counsel: a choice that neither costs nor gives people or gold (no late gifts on Odile's path),
            // else one that costs nothing.
            let free = open.filter { CourtValidator.costsNothing(ErrandEngine.effect(report.choices[$0], day: s.day)) }
            for index in free {
                let today = ErrandEngine.effect(report.choices[index], day: s.day)
                let gains = [today.citizens, today.archers, today.guards, today.builders, today.gold]
                if !gains.contains(where: { ($0 ?? 0) > 0 }) { return index }
            }
            return free.first ?? open[0]
        case .greedy:
            func gain(_ index: Int) -> (people: Int, gold: Int) {
                let today = ErrandEngine.effect(report.choices[index], day: s.day)
                var people = 0
                for value in [today.citizens, today.archers, today.guards, today.builders] { people += max(0, value ?? 0) }
                return (people, today.gold ?? 0)
            }
            var best = open[0]
            for index in open.dropFirst() {
                let a = gain(index)
                let b = gain(best)
                if a.people > b.people || (a.people == b.people && a.gold > b.gold) { best = index }
            }
            return best
        }
    }

    // MARK: - Sending

    /// The orders the bot would send, in the order it tries them.
    func preference(_ errand: Errand, _ s: GameState) -> [Int] {
        switch policy {
        case .sender:
            return errand.orders.indices.filter { ErrandEngine.sealHolds(errand, order: $0, s) }
        case .greedy:
            return Array(errand.orders.indices.reversed())
        }
    }

    private mutating func send(_ errand: Errand, _ s: inout GameState, catalog: ErrandCatalog, balance: Balance) {
        let orders = preference(errand, s)
        var wantedAHook = false
        for index in orders {
            let blocks = ErrandEngine.blockers(errand, order: index, s, catalog: catalog)
            if blocks.isEmpty {
                if ErrandEngine.send(&s, errand: errand.id, order: index, catalog: catalog, balance: balance) != nil {
                    log.append("\(s.day):\(errand.id).\(index + 1)")
                    return
                }
            } else if blocks == [.noLantern] {
                wantedAHook = true
            }
        }
        if wantedAHook { starved.insert(errand.id) }
    }
}
