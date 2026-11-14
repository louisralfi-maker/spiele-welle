/// Why an order cannot be sent now (the table greys its tile and turns the missing chip red, QUESTS.md 2.3).
enum SendBlock: Sendable, Equatable {
    /// Not on the table today (its days, its conditions, sent already, the cloth still on).
    case notOffered
    /// Sendings leave from 06:00 to 18:00, never at night or after the realm fell.
    case closed
    /// A report waits: reports are read first (QUESTS.md 2.5).
    case reportWaits
    /// The order needs a flag the realm lacks, or has one it must not have.
    case needs(String)
    case forbids(String)
    /// No lantern on the hook.
    case noLantern
    /// The named person is out with another lantern.
    case away(String)
    case gold(missing: Int)
    case archers(missing: Int)
    case guards(missing: Int)
    /// Bearers come from the taxpayers.
    case taxpayers(missing: Int)
    /// The castle keeps at least one builder.
    case builders(missing: Int)
}

/// The Lantern Table's rules (docs/QUESTS.md sections 2 and 4), pure and deterministic.
///
/// - The table opens on day 2 (Pip pulls the cloth off). A sending is offered while the day is in its `days`, its
///   conditions hold and it has not been sent; a window that closes takes it away.
/// - `send` takes the lowest free road lantern, pays the cost, lends the people and rolls the risk once, from a
///   stream of its own (`errandSeed`, built like `PetitionEngine.queueSeed`); the result is kept in `TableState.out`.
///   "Call back" undoes a sending while the clock has not moved since.
/// - `dawn` (from `Sim.dawn`, after the night is accounted and before the economy and the dawn report) brings the
///   parties home: what was lent comes back, the sending's `atReturn` applies, the report waits at the table. A lost
///   lantern leaves its hook empty for the chapter, darkens a keep window and costs 2 happiness.
/// - `read` answers a waiting report by day, with the petitions' effects.
/// The engine never draws from `GameState.rng`: soldiers a report or a return brings get their names from the table's
/// own stream, so the nights of a seed stay the same with or without lanterns out, except for the soldiers really
/// missing. A realm that never touches the table (`GameState.table == nil`) plays exactly as before.
enum ErrandEngine {
    /// The cloth comes off on day 2.
    static let firstDay = 2
    /// Parties leave from 06:00 until 18:00.
    static let sendHours = 6.0..<18.0
    /// A report changes the night only on these days; outside them a choice's `instead` applies (QUESTS.md 2.6).
    static let nightDays = 4...14
    /// Odile's seal: no sealed party is away on these nights (QUESTS.md 4.3) ...
    static let sealBlockedNights: Set<Int> = [7, 10, 17, 18, 19, 20]
    /// ... and sealed parties never have more than two soldiers out on one night.
    static let sealMostSoldiers = 2
    /// The counsel's report choice gives no people or gold after this day.
    static let counselGainLastDay = 14
    /// A lost lantern: happiness at that dawn, and the keep window that stays dark.
    static let lossHappiness = -2
    static let darkWindow = "castle.keep.window.dark"

    // MARK: - The table's offers

    /// True while the realm meets the sending's conditions (flags, petitions heard, world changes, sites open).
    static func conditionsHold(_ errand: Errand, _ s: GameState) -> Bool {
        for flag in errand.requires ?? [] where !s.flags.contains(flag) { return false }
        for flag in errand.forbids ?? [] where s.flags.contains(flag) { return false }
        if let any = errand.requiresAny, !any.isEmpty, !any.contains(where: { s.flags.contains($0) }) { return false }
        let court = s.court
        for id in errand.heard ?? [] where !(court?.heard.contains(id) ?? false) { return false }
        for id in errand.world ?? [] where !(court?.shows(id) ?? false) { return false }
        for site in errand.unlocked ?? [] where !isOpen(site, s) { return false }
        return true
    }

    /// A site (`line2`, `line3`, `beacon`) is open: its day has come, or a petition opened it early.
    static func isOpen(_ site: String, _ s: GameState) -> Bool {
        switch site {
        case "line2": return s.isUnlocked(plot: Realm.lines[1].wall)
        case "line3": return s.isUnlocked(plot: Realm.lines[2].wall)
        case "beacon": return s.isUnlocked(plot: Realm.beaconPlot)
        default: return false
        }
    }

    /// The sites `unlocked` may name.
    static let sites: Set<String> = ["line2", "line3", "beacon"]

    /// On the table today: the chapter's own, on one of its days, its conditions met, not sent yet, the cloth off.
    static func isOffered(_ errand: Errand, _ s: GameState) -> Bool {
        guard errand.offered != false, s.mode == .chapter, !s.defeated else { return false }
        guard (errand.chapter ?? PetitionEngine.chapter) == PetitionEngine.chapter else { return false }
        guard s.day >= firstDay, errand.dayRange.contains(s.day) else { return false }
        if s.table?.sent.contains(errand.id) == true { return false }
        return conditionsHold(errand, s)
    }

    /// Today's slips, by their number on the table.
    static func offers(_ s: GameState, catalog: ErrandCatalog) -> [Errand] {
        var list: [Errand] = []
        for errand in catalog.errands where isOffered(errand, s) { list.append(errand) }
        list.sort { ($0.number, $0.id) < ($1.number, $1.id) }
        return list
    }

    /// The nights an order is away today (`nightsWith`: the smallest value among the flags set).
    static func nights(_ order: ErrandOrder, _ s: GameState) -> Int {
        var nights = order.nights
        for (flag, value) in order.nightsWith ?? [:] where s.flags.contains(flag) { nights = min(nights, value) }
        return max(1, nights)
    }

    /// The lantern a sending would take now: its own, or the lowest road lantern on its hook.
    static func freeLantern(_ errand: Errand, table: TableState) -> Int? {
        if let fixed = errand.lantern {
            return table.lantern(fixed)?.state == .hook ? fixed : nil
        }
        return table.lanterns.filter { !$0.reserved && $0.state == .hook }.map { $0.number }.min()
    }

    /// Everything that keeps an order from leaving now; empty when it can go. A sending not on the table, the closed
    /// hours and a waiting report come alone.
    static func blockers(_ errand: Errand, order index: Int, _ s: GameState, catalog: ErrandCatalog) -> [SendBlock] {
        guard index >= 0, index < errand.orders.count, isOffered(errand, s) else { return [.notOffered] }
        guard sendHours.contains(s.hour) else { return [.closed] }
        let table = s.table ?? .start(catalog)
        guard table.reports.isEmpty else { return [.reportWaits] }
        let order = errand.orders[index]
        var list: [SendBlock] = []
        for flag in order.requires ?? [] where !s.flags.contains(flag) { list.append(.needs(flag)) }
        for flag in order.forbids ?? [] where s.flags.contains(flag) { list.append(.forbids(flag)) }
        if freeLantern(errand, table: table) == nil { list.append(.noLantern) }
        for who in order.goes ?? [] where table.isAway(who) { list.append(.away(who)) }
        if order.goldCost > s.gold { list.append(.gold(missing: order.goldCost - s.gold)) }
        let lend = order.lend ?? ErrandLend()
        let archers = max(0, lend.archers ?? 0)
        if archers > s.archerCount { list.append(.archers(missing: archers - s.archerCount)) }
        let guards = max(0, lend.guards ?? 0)
        if guards > s.guardCount { list.append(.guards(missing: guards - s.guardCount)) }
        let bearers = max(0, lend.citizens ?? 0)
        if bearers > s.taxpayers { list.append(.taxpayers(missing: bearers - s.taxpayers)) }
        let builders = max(0, lend.builders ?? 0)
        if builders > 0 && s.builders.count - builders < 1 {
            list.append(.builders(missing: 1 - (s.builders.count - builders)))
        }
        return list
    }

    /// The first thing that keeps an order from leaving, or nil.
    static func blocker(_ errand: Errand, order index: Int, _ s: GameState, catalog: ErrandCatalog) -> SendBlock? {
        blockers(errand, order: index, s, catalog: catalog).first
    }

    /// Odile's seal holds for the order if it left today (QUESTS.md 4.3): the order carries it, risks nothing, lends
    /// at most two soldiers, is away on none of nights 7, 10 and 17 to 20, and sealed parties would not have more than
    /// two soldiers out on any of its nights. On a day it would break a rule the engine withholds the seal.
    static func sealHolds(_ errand: Errand, order index: Int, _ s: GameState) -> Bool {
        guard index >= 0, index < errand.orders.count else { return false }
        let order = errand.orders[index]
        guard order.isSealed, order.lostChance == 0, order.lateChance == 0 else { return false }
        let soldiers = (order.lend ?? ErrandLend()).soldiers
        guard soldiers <= sealMostSoldiers else { return false }
        let first = s.day
        let last = s.day + nights(order, s) - 1
        for night in first...last {
            if sealBlockedNights.contains(night) { return false }
            var out = soldiers
            for sending in s.table?.out ?? [] where sending.sealed { out += sending.soldiers(onNight: night) }
            if out > sealMostSoldiers { return false }
        }
        return true
    }

    // MARK: - The stream of its own

    /// A sending's own stream: the seed, the sending and the order (never `GameState.rng`).
    static func errandSeed(_ seed: UInt64, errand: String, order: Int) -> UInt64 {
        var key = seed ^ 0x4C41_4E54_4552_4E53
        for scalar in errand.unicodeScalars {
            key = (key ^ UInt64(scalar.value)) &* 0x0000_0100_0000_01B3
        }
        return SeededRandom.mix(key &+ UInt64(truncatingIfNeeded: order) &* SeededRandom.increment)
    }

    /// The stream that names soldiers a return or a report brings.
    static func nameSeed(_ seed: UInt64, key: String, day: Int) -> UInt64 {
        errandSeed(seed ^ 0x4E41_4D45_5300_0000, errand: key, order: day)
    }

    /// What the roll of a sending gives: lost, late, or home on its dawn. The same seed, sending and order always give
    /// the same answer, so calling back and sending again cannot change it.
    static func roll(_ seed: UInt64, errand: String, order index: Int,
                     _ order: ErrandOrder) -> (lost: Bool, late: Bool) {
        var stream = SeededRandom(seed: errandSeed(seed, errand: errand, order: index))
        let draw = stream.nextDouble()
        return (order.lostChance > 0 && draw < order.lostChance, order.lateChance > 0 && draw < order.lateChance)
    }

    // MARK: - Sending

    /// The table uncovered: the rail at the chapter's start (the table screen calls it when it opens). Nothing else
    /// changes.
    static func uncover(_ s: inout GameState, catalog: ErrandCatalog) {
        guard s.table == nil, s.mode == .chapter, s.day >= firstDay else { return }
        s.table = .start(catalog)
    }

    /// Sends a party with `order` of the sending `id`: the lantern leaves its hook, the cost is paid, the people go,
    /// the risk is rolled and kept. Nil when the order cannot leave now.
    @discardableResult
    static func send(_ s: inout GameState, errand id: String, order index: Int, catalog: ErrandCatalog,
                     balance: Balance) -> Sending? {
        guard let errand = catalog.errand(id), blockers(errand, order: index, s, catalog: catalog).isEmpty else {
            return nil
        }
        var table = s.table ?? .start(catalog)
        guard let number = freeLantern(errand, table: table) else { return nil }
        let order = errand.orders[index]
        let sealed = sealHolds(errand, order: index, s)
        let due = s.day + nights(order, s)
        let rolled = roll(s.seed, errand: errand.id, order: index, order)
        let gold = order.goldCost
        s.gold -= gold
        var paid = PetitionOutcome(petition: errand.id, choice: index)
        for flag in order.cost?.flags ?? [] { PetitionEngine.setFlag(&s, flag, outcome: &paid) }
        let lend = order.lend ?? ErrandLend()
        var lent = take(&s, .archer, max(0, lend.archers ?? 0))
        lent += take(&s, .guardsman, max(0, lend.guards ?? 0))
        lent.sort { $0.id < $1.id }
        let bearers = max(0, lend.citizens ?? 0)
        s.citizens -= lent.count + bearers
        let builders = max(0, lend.builders ?? 0)
        if builders > 0 { changeBuilders(&s, by: -builders, balance: balance) }
        var atReturn: [PetitionEffect] = []
        if let effect = errand.atReturn { atReturn.append(effect) }
        if let effect = order.atReturn { atReturn.append(effect) }
        let sending = Sending(errand: errand.id, order: index, lantern: number, place: errand.place, sentDay: s.day,
                              sentAt: s.simTime, dueDay: due, homeDay: rolled.late ? due + 1 : due,
                              lost: rolled.lost, late: rolled.late, sealed: sealed, gold: gold,
                              flagsSet: paid.flagsSet, flagsCleared: paid.flagsCleared, lent: lent,
                              citizens: bearers, builders: builders, goes: order.goes ?? [], report: order.report,
                              altReport: order.altReport ?? [],
                              lostReport: errand.lostReport ?? ErrandCatalog.lostReportID, atReturn: atReturn,
                              atLoss: order.atLoss)
        table.out.append(sending)
        table.out.sort { $0.lantern < $1.lantern }
        setLantern(&table, number, .out)
        if !table.sent.contains(errand.id) {
            table.sent.append(errand.id)
            table.sent.sort()
        }
        s.table = table
        return sending
    }

    /// True while a sending can still be called back at no cost: sent today and the clock has not moved since (the
    /// table screen stops it; QUESTS.md 5.2).
    static func canCallBack(_ s: GameState, errand: String) -> Bool {
        guard !s.defeated, let sending = s.table?.sending(errand) else { return false }
        return sending.sentDay == s.day && sending.sentAt == s.simTime
    }

    /// "Call back": the party never left. Gold, flags, soldiers (as they were), bearers and builders come back, the
    /// lantern hangs on its hook and the sending is on the table again.
    @discardableResult
    static func callBack(_ s: inout GameState, errand: String, balance: Balance) -> Bool {
        guard canCallBack(s, errand: errand), var table = s.table,
              let position = table.out.firstIndex(where: { $0.errand == errand }) else { return false }
        let sending = table.out.remove(at: position)
        s.gold += sending.gold
        for flag in sending.flagsSet { s.flags.removeAll { $0 == flag } }
        for flag in sending.flagsCleared where !s.flags.contains(flag) { s.flags.append(flag) }
        s.flags.sort()
        for soldier in sending.lent { insert(&s, soldier) }
        s.citizens += sending.lent.count + sending.citizens
        if sending.builders > 0 { changeBuilders(&s, by: sending.builders, balance: balance) }
        setLantern(&table, sending.lantern, .hook)
        table.sent.removeAll { $0 == errand }
        s.table = table
        return true
    }

    // MARK: - The dawn

    /// The parties due at this dawn come home or are counted lost (from `Sim.dawn`, after the night is accounted and
    /// before the economy and the dawn report, so the report and the save see them). Nothing happens without parties
    /// out.
    static func dawn(_ s: inout GameState, balance: Balance) {
        guard var table = s.table, !table.out.isEmpty else { return }
        var returns: [LanternReturn] = []
        var staying: [Sending] = []
        for sending in table.out.sorted(by: { $0.lantern < $1.lantern }) {
            guard sending.homeDay <= s.day else {
                if sending.late && sending.dueDay == s.day {
                    returns.append(LanternReturn(lantern: sending.lantern, errand: sending.errand,
                                                 place: sending.place, outcome: .late,
                                                 names: sending.lent.map { $0.name }, happiness: 0))
                }
                staying.append(sending)
                continue
            }
            let names = sending.lent.map { $0.name }
            var outcome = PetitionOutcome(petition: sending.errand, choice: sending.order)
            if sending.lost {
                apply(PetitionEffect(happiness: lossHappiness, world: [darkWindow]), to: &s, balance: balance,
                      names: nameSeed(s.seed, key: sending.errand, day: s.day), outcome: &outcome)
                let loss = outcome.happiness
                if let effect = sending.atLoss {
                    apply(effect, to: &s, balance: balance, names: nameSeed(s.seed, key: sending.errand, day: s.day),
                          outcome: &outcome)
                }
                setLantern(&table, sending.lantern, .lost)
                table.reports.append(WaitingReport(report: sending.lostReport, errand: sending.errand,
                                                   lantern: sending.lantern, place: sending.place, day: s.day,
                                                   lost: true, names: names))
                returns.append(LanternReturn(lantern: sending.lantern, errand: sending.errand, place: sending.place,
                                             outcome: .lost, names: names, happiness: loss))
            } else {
                for soldier in sending.lent { insert(&s, rested(soldier)) }
                s.citizens += sending.lent.count + sending.citizens
                if sending.builders > 0 { changeBuilders(&s, by: sending.builders, balance: balance) }
                for (step, effect) in sending.atReturn.enumerated() {
                    apply(effect, to: &s, balance: balance,
                          names: nameSeed(s.seed, key: sending.errand, day: s.day &* 4 &+ step), outcome: &outcome)
                }
                setLantern(&table, sending.lantern, .back)
                table.reports.append(WaitingReport(report: report(for: sending, s), errand: sending.errand,
                                                   lantern: sending.lantern, place: sending.place, day: s.day,
                                                   names: names))
                returns.append(LanternReturn(lantern: sending.lantern, errand: sending.errand, place: sending.place,
                                             outcome: .home, names: names, happiness: 0))
            }
        }
        table.out = staying
        if !returns.isEmpty { table.dawn = TableDawn(day: s.day, returns: returns) }
        s.table = table
    }

    /// The report a party brings home: the first alternative whose condition holds at this dawn, else the order's.
    static func report(for sending: Sending, _ s: GameState) -> String {
        for alt in sending.altReport {
            if let from = alt.fromDay, s.day < from { continue }
            if (alt.requires ?? []).contains(where: { !s.flags.contains($0) }) { continue }
            if (alt.forbids ?? []).contains(where: { s.flags.contains($0) }) { continue }
            return alt.report
        }
        return sending.report
    }

    // MARK: - Reading a report

    /// The effect a report choice has today: its own, or its `instead` on a day its night cannot apply (outside days
    /// 4 to 14). A choice without `instead` simply loses its night then; `instead` keeps the choice's reaction unless
    /// it names its own.
    static func effect(_ choice: ReportChoice, day: Int) -> PetitionEffect {
        let night = choice.effect.night ?? []
        guard !night.isEmpty, !nightDays.contains(day) else { return choice.effect }
        guard var instead = choice.instead else {
            var plain = choice.effect
            plain.night = nil
            return plain
        }
        if instead.reaction == nil { instead.reaction = choice.effect.reaction }
        instead.night = nil
        return instead
    }

    /// Odile's counsel on a report today: its counsel choice, withheld after day 14 when it would give people or
    /// gold (QUESTS.md 4.3).
    static func counsel(_ report: TableReport, _ s: GameState) -> Int? {
        guard let index = report.counsel, index >= 0, index < report.choices.count else { return nil }
        let today = effect(report.choices[index], day: s.day)
        let people = [today.citizens, today.archers, today.guards, today.builders].contains { ($0 ?? 0) > 0 }
        if s.day > counselGainLastDay && (people || (today.gold ?? 0) > 0) { return nil }
        return index
    }

    /// The report card of a waiting report.
    static func card(_ waiting: WaitingReport, catalog: ErrandCatalog) -> TableReport? {
        catalog.report(waiting.report)
    }

    /// Why a report choice cannot be taken now (it costs gold or people the realm lacks), or nil.
    static func readBlock(_ choice: ReportChoice, _ s: GameState) -> ChoiceBlock? {
        PetitionEngine.blocker(PetitionChoice(label: choice.label, effect: effect(choice, day: s.day)), s)
    }

    /// Answers the waiting report at `position` (the oldest by default) with `choice`, by day: the report leaves the
    /// table, its lantern hangs on its hook again, the choice's effect applies. Nil when there is no such report or
    /// choice, at night, or when the choice is blocked.
    @discardableResult
    static func read(_ s: inout GameState, at position: Int = 0, choice: Int, catalog: ErrandCatalog,
                     balance: Balance) -> PetitionOutcome? {
        guard DayClock.phase(at: s.hour) == .day, !s.defeated, var table = s.table, position >= 0,
              position < table.reports.count else { return nil }
        let waiting = table.reports[position]
        guard let report = catalog.report(waiting.report), choice >= 0, choice < report.choices.count else {
            return nil
        }
        let picked = report.choices[choice]
        guard readBlock(picked, s) == nil else { return nil }
        let today = effect(picked, day: s.day)
        table.reports.remove(at: position)
        table.read.append(ReadReport(report: report.id, errand: waiting.errand, day: s.day, choice: choice))
        if table.lantern(waiting.lantern)?.state == .back { setLantern(&table, waiting.lantern, .hook) }
        s.table = table
        var outcome = PetitionOutcome(petition: report.id, choice: choice)
        outcome.reaction = today.reaction
        apply(today, to: &s, balance: balance, names: nameSeed(s.seed, key: report.id, day: s.day),
              outcome: &outcome)
        return outcome
    }

    // MARK: - Helpers

    /// Applies an effect with the petitions' rules, except that new soldiers get their names from `names` (the
    /// table's stream), never from `GameState.rng`. Reports and returns use no chance (the validator).
    static func apply(_ effect: PetitionEffect, to s: inout GameState, balance: Balance, names seed: UInt64,
                      outcome: inout PetitionOutcome) {
        var rest = effect
        let archers = max(0, effect.archers ?? 0)
        let guards = max(0, effect.guards ?? 0)
        if archers > 0 { rest.archers = nil }
        if guards > 0 { rest.guards = nil }
        rest.chance = nil
        let reaction = outcome.reaction
        PetitionEngine.apply(rest, to: &s, balance: balance, outcome: &outcome)
        outcome.reaction = reaction ?? effect.reaction
        var stream = SeededRandom(seed: seed)
        for _ in 0..<archers {
            addSoldier(&s, .archer, balance: balance, stream: &stream)
            outcome.archers += 1
        }
        for _ in 0..<guards {
            addSoldier(&s, .guardsman, balance: balance, stream: &stream)
            outcome.guards += 1
        }
    }

    /// A new soldier who joins through the table (a citizen more), named from the table's stream, avoiding the names
    /// of the soldiers at home and those out with a lantern.
    static func addSoldier(_ s: inout GameState, _ kind: SoldierKind, balance: Balance, stream: inout SeededRandom) {
        var used = s.soldiers.map { $0.name }
        for sending in s.table?.out ?? [] { used += sending.lent.map { $0.name } }
        let name = Names.pick(&stream, avoiding: used)
        let hp = kind == .archer ? balance.archerHP : balance.guardHP
        let soldier = Soldier(id: s.makeID(), name: name, kind: kind, hp: hp, maxHP: hp, x: Realm.keepX,
                              targetX: Realm.keepX)
        s.soldiers.append(soldier)
        s.citizens += 1
    }

    /// Takes the newest `count` soldiers of a kind out of the realm (the last recruited first).
    static func take(_ s: inout GameState, _ kind: SoldierKind, _ count: Int) -> [Soldier] {
        var taken: [Soldier] = []
        var index = s.soldiers.count - 1
        while taken.count < count && index >= 0 {
            if s.soldiers[index].kind == kind { taken.append(s.soldiers.remove(at: index)) }
            index -= 1
        }
        return taken
    }

    /// Puts a soldier back in his place among the others (they are kept in the order they joined, by id).
    static func insert(_ s: inout GameState, _ soldier: Soldier) {
        let position = s.soldiers.firstIndex { $0.id > soldier.id } ?? s.soldiers.count
        s.soldiers.insert(soldier, at: position)
    }

    /// A soldier home from the road as every soldier is at dawn (`Battle.endNight`): healed, waiting in the keep.
    static func rested(_ soldier: Soldier) -> Soldier {
        var back = soldier
        back.hp = back.maxHP
        back.state = .reserve
        back.goal = .reserve
        back.x = Realm.keepX
        back.targetX = Realm.keepX
        back.y = 0
        back.postPlot = -1
        back.cooldown = 0
        return back
    }

    /// Builders away or back: the court's extra builders (`PetitionEngine.changeBuilders` keeps at least one).
    static func changeBuilders(_ s: inout GameState, by count: Int, balance: Balance) {
        var court = s.court ?? CourtState()
        court.extraBuilders += count
        s.court = court
        Build.syncBuilders(&s, balance: balance)
    }

    static func setLantern(_ table: inout TableState, _ number: Int, _ state: LanternState) {
        guard let index = table.lanterns.firstIndex(where: { $0.number == number }) else { return }
        table.lanterns[index].state = state
    }
}
