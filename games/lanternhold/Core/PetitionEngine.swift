/// Why a choice cannot be taken now (the audience card greys it with the reason).
enum ChoiceBlock: Sendable, Equatable {
    case gold(missing: Int)
    /// A `citizens` loss needs that many taxpayers.
    case taxpayers(missing: Int)
    case archers(missing: Int)
    case guards(missing: Int)
    /// The castle keeps at least one builder.
    case builders(missing: Int)
}

/// What hearing a petition did: the reaction to show and every change, after clamping (gold never below 0, happiness
/// 0 to 100), for the HUD's numbers and the world's changes.
struct PetitionOutcome: Sendable, Equatable {
    var petition: String
    var choice: Int
    /// The reaction's text key: the choice's, or the one of the chance side that came (the deepest one wins).
    var reaction: String?
    var gold = 0
    var happiness = 0
    var citizens = 0
    var archers = 0
    var guards = 0
    var builders = 0
    var flagsSet: [String] = []
    var flagsCleared: [String] = []
    var worldAdded: [String] = []
    var worldRemoved: [String] = []
    var scheduled: [ScheduledPetition] = []
    var unlocked: [String] = []
    var night: [String] = []
    /// Each chance rolled, in order: true when its `then` side came.
    var rolls: [Bool] = []
}

/// The audience's rules (DESIGN.md "The throne: audiences and decisions", "M3 in detail"), pure and deterministic.
///
/// - `prepare` draws today's petitioners once a day, by day: day 1 one (the tutorial), else 2 to 4; story petitions on
///   their days first (until heard), follow-ups due today next, then random ones by weight among the eligible, never the
///   same one twice in five days; endless-only ones only in endless. The draw uses its own stream made from the seed
///   and the day, so the queue never moves the simulation's random stream.
/// - `hear` applies a choice through the simulation's own rules; a chance rolls the simulation's seeded stream.
/// - `horn` (from `Sim` at 19:00) sends the waiting home: each costs 1 happiness at dawn
///   (`Balance.happinessPerUnheard`, shown in the dawn report's realm column).
/// - `dawn` (from `Sim` at 06:00) spends the past night's modifiers and prunes the history.
/// The drivers call `prepare`: `SimDriver` after every step, the reference bot through `holdAudience`.
enum PetitionEngine {
    /// The chapter the realm plays (chapter 1 until the coast and the long wall come as updates).
    static let chapter = 1
    /// A random petition shown on day d may come again from day d + 5.
    static let repeatGap = 5
    /// Days of history kept (the five-day rule needs four).
    static let historyDays = 10
    static let fewest = 2
    static let most = 4
    static let firstDay = 1

    // MARK: - Today's queue

    /// Draws today's queue once, from 06:00 to the horn (`SimDriver` calls it after every step, the bot before it
    /// acts); a queue drawn already only loses petitioners whose petition no longer exists.
    static func prepare(_ s: inout GameState, catalog: PetitionCatalog) {
        guard DayClock.phase(at: s.hour) == .day, !s.defeated else { return }
        var court = s.court ?? CourtState()
        if court.queueDay == s.day {
            let before = court.queue.count
            court.queue.removeAll { catalog.petition($0.id) == nil }
            if court.queue.count != before { s.court = court }
            return
        }
        court.queueDay = s.day
        court.queue = draw(s, court: court, catalog: catalog)
        s.court = court
    }

    /// Today's petitioners as the rules give them (`prepare` keeps them in the save).
    static func draw(_ s: GameState, court: CourtState, catalog: PetitionCatalog) -> [Petitioner] {
        let day = s.day
        var rng = SeededRandom(seed: queueSeed(s.seed, day: day))
        let target = day <= 1 ? firstDay : fewest + rng.int(in: 0...(most - fewest))
        var picked: [Petitioner] = []
        func has(_ id: String) -> Bool { picked.contains { $0.id == id } }
        if s.mode == .chapter {
            for petition in catalog.petitions where isStoryDue(petition, s, court: court) {
                picked.append(Petitioner(id: petition.id, reason: .story, look: look(s.seed, day: day, id: petition.id)))
            }
        }
        for entry in court.scheduled where entry.day == day && !has(entry.id) {
            guard let petition = catalog.petition(entry.id), petition.allows(flags: s.flags) else { continue }
            picked.append(Petitioner(id: petition.id, reason: .followUp, look: look(s.seed, day: day, id: petition.id)))
        }
        var pool: [Petition] = []
        for petition in catalog.petitions where isDrawable(petition, s, court: court) && !has(petition.id) {
            pool.append(petition)
        }
        while picked.count < target && !pool.isEmpty {
            var total = 0.0
            for petition in pool { total += petition.drawWeight }
            guard total > 0 else { break }
            var roll = rng.nextDouble() * total
            var chosen = pool.count - 1
            for (position, petition) in pool.enumerated() {
                roll -= petition.drawWeight
                if roll < 0 {
                    chosen = position
                    break
                }
            }
            let petition = pool.remove(at: chosen)
            picked.append(Petitioner(id: petition.id, reason: .random, look: look(s.seed, day: day, id: petition.id)))
        }
        return picked
    }

    /// A story petition comes on each day of its range (in the chapter) until it is heard, while its flags and its
    /// happiness range allow.
    static func isStoryDue(_ petition: Petition, _ s: GameState, court: CourtState) -> Bool {
        guard petition.kind == .story, let range = petition.dayRange, range.contains(s.day) else { return false }
        guard (petition.chapter ?? chapter) == chapter, !court.heard.contains(petition.id) else { return false }
        return petition.allows(flags: s.flags) && petition.allows(happiness: s.happiness)
    }

    /// A random petition (an endless one only in endless) with weight, on its days, its flags and happiness range
    /// allowing, not shown in the last five days.
    static func isDrawable(_ petition: Petition, _ s: GameState, court: CourtState) -> Bool {
        switch petition.kind {
        case .story: return false
        case .random: break
        case .endless: if s.mode != .endless { return false }
        }
        guard petition.drawWeight > 0, (petition.chapter ?? chapter) == chapter, petition.comes(onDay: s.day) else {
            return false
        }
        guard petition.allows(flags: s.flags), petition.allows(happiness: s.happiness) else { return false }
        return !shownRecently(petition.id, day: s.day, court: court)
    }

    /// True when the petition was shown (heard or sent home) less than `repeatGap` days ago.
    static func shownRecently(_ id: String, day: Int, court: CourtState) -> Bool {
        for entry in court.history where entry.id == id && entry.day > day - repeatGap {
            return true
        }
        return false
    }

    /// The queue's own stream for a day.
    static func queueSeed(_ seed: UInt64, day: Int) -> UInt64 {
        SeededRandom.mix((seed ^ 0x5045_5449_5449_4F4E) &+ UInt64(truncatingIfNeeded: day) &* SeededRandom.increment)
    }

    /// A petitioner's look: 31 bits from the seed, the day and the petition.
    static func look(_ seed: UInt64, day: Int, id: String) -> Int {
        var key = SeededRandom.hash(seed, Int64(day))
        for scalar in id.unicodeScalars {
            key = (key ^ UInt64(scalar.value)) &* 0x0000_0100_0000_01B3
        }
        return Int(SeededRandom.mix(key) >> 33)
    }

    /// Today's petitioners with their petitions, in the order they walk up.
    static func waiting(_ s: GameState, catalog: PetitionCatalog) -> [(petitioner: Petitioner, petition: Petition)] {
        guard let court = s.court, court.queueDay == s.day else { return [] }
        var list: [(petitioner: Petitioner, petition: Petition)] = []
        for petitioner in court.queue {
            if let petition = catalog.petition(petitioner.id) { list.append((petitioner, petition)) }
        }
        return list
    }

    // MARK: - The clock

    /// The horn: the petitioners still waiting go home unheard (each costs 1 happiness at dawn, and counts as shown for
    /// the five-day rule).
    static func horn(_ s: inout GameState) {
        guard var court = s.court, !court.queue.isEmpty else { return }
        for petitioner in court.queue {
            court.history.append(HeardPetition(id: petitioner.id, day: s.day, choice: nil))
        }
        s.unheardPetitioners += court.queue.count
        court.queue.removeAll()
        s.court = court
    }

    /// The dawn (the new day): the past night's modifiers are spent, the history keeps its last days, follow-ups that
    /// could not come are dropped.
    static func dawn(_ s: inout GameState) {
        guard var court = s.court else { return }
        let day = s.day
        court.nightModifiers.removeAll { $0.night < day }
        court.history.removeAll { $0.day <= day - historyDays }
        court.scheduled.removeAll { $0.day < day }
        s.court = court
    }

    // MARK: - Choosing

    /// Why the choice cannot be taken now, or nil. Only the choice's own effect counts (a chance's sides are a risk).
    static func blocker(_ choice: PetitionChoice, _ s: GameState) -> ChoiceBlock? {
        let effect = choice.effect
        if let gold = effect.gold, gold < 0, s.gold < -gold { return .gold(missing: -gold - s.gold) }
        if let count = effect.archers, count < 0, s.archerCount < -count {
            return .archers(missing: -count - s.archerCount)
        }
        if let count = effect.guards, count < 0, s.guardCount < -count { return .guards(missing: -count - s.guardCount) }
        if let count = effect.citizens, count < 0, s.taxpayers < -count {
            return .taxpayers(missing: -count - s.taxpayers)
        }
        if let count = effect.builders, count < 0, s.builders.count + count < 1 {
            return .builders(missing: 1 - s.builders.count - count)
        }
        return nil
    }

    /// Hears the petitioner at `position` of today's queue (the next one by default) with choice `choice`: the
    /// petitioner leaves the queue, the history notes it, every effect applies. Nil when there is no such petitioner
    /// or choice, or the choice is blocked.
    @discardableResult
    static func hear(_ s: inout GameState, choice: Int, at position: Int = 0, catalog: PetitionCatalog,
                     balance: Balance) -> PetitionOutcome? {
        guard var court = s.court, court.queueDay == s.day, position >= 0, position < court.queue.count else {
            return nil
        }
        let petitioner = court.queue[position]
        guard let petition = catalog.petition(petitioner.id), choice >= 0, choice < petition.choices.count else {
            return nil
        }
        let picked = petition.choices[choice]
        guard blocker(picked, s) == nil else { return nil }
        court.queue.remove(at: position)
        court.history.append(HeardPetition(id: petition.id, day: s.day, choice: choice))
        if !court.heard.contains(petition.id) {
            court.heard.append(petition.id)
            court.heard.sort()
        }
        court.heardCount += 1
        s.court = court
        var outcome = PetitionOutcome(petition: petition.id, choice: choice)
        outcome.reaction = picked.effect.reaction
        apply(picked.effect, to: &s, balance: balance, outcome: &outcome)
        return outcome
    }

    /// Applies one effect (and, for a chance, the side the seeded stream picks).
    static func apply(_ effect: PetitionEffect, to s: inout GameState, balance: Balance,
                      outcome: inout PetitionOutcome) {
        if let gold = effect.gold, gold != 0 {
            let before = s.gold
            s.gold = max(0, s.gold + gold)
            outcome.gold += s.gold - before
        }
        if let delta = effect.happiness, delta != 0 {
            let before = s.happiness
            s.happiness = min(100, max(0, s.happiness + delta))
            outcome.happiness += s.happiness - before
        }
        if let count = effect.citizens, count != 0 { outcome.citizens += changeCitizens(&s, by: count) }
        if let count = effect.archers, count != 0 {
            outcome.archers += changeSoldiers(&s, kind: .archer, by: count, balance: balance)
        }
        if let count = effect.guards, count != 0 {
            outcome.guards += changeSoldiers(&s, kind: .guardsman, by: count, balance: balance)
        }
        if let count = effect.builders, count != 0 { outcome.builders += changeBuilders(&s, by: count, balance: balance) }
        for flag in effect.flags ?? [] {
            setFlag(&s, flag, outcome: &outcome)
        }
        var court = s.court ?? CourtState()
        for change in effect.world ?? [] {
            if change.hasPrefix("-") {
                let id = String(change.dropFirst())
                if let found = court.world.firstIndex(of: id) {
                    court.world.remove(at: found)
                    outcome.worldRemoved.append(id)
                }
            } else if !court.world.contains(change) {
                court.world.append(change)
                court.world.sort()
                outcome.worldAdded.append(change)
            }
        }
        for follow in effect.schedule ?? [] {
            let entry = ScheduledPetition(id: follow.id, day: s.day + max(1, follow.inDays))
            court.scheduled.append(entry)
            outcome.scheduled.append(entry)
        }
        for id in effect.night ?? [] where NightModifier(id: id) != nil {
            court.nightModifiers.append(NightModifierEntry(night: s.nightNumber, id: id))
            outcome.night.append(id)
        }
        s.court = court
        for id in effect.unlock ?? [] {
            if unlock(&s, id) { outcome.unlocked.append(id) }
        }
        if let chance = effect.chance {
            let then = s.rng.nextDouble() < chance.p
            outcome.rolls.append(then)
            let side = then ? chance.then : chance.otherwise
            if let reaction = side.reaction { outcome.reaction = reaction }
            apply(side, to: &s, balance: balance, outcome: &outcome)
        }
    }

    /// New people move in (+n, even beyond the houses' room: growth waits until there is room), or people leave (−n:
    /// taxpayers first, then soldiers). Returns the change.
    static func changeCitizens(_ s: inout GameState, by count: Int) -> Int {
        let before = s.citizens
        if count > 0 {
            s.citizens += count
            return count
        }
        var leaving = min(-count, s.citizens)
        let fromTaxpayers = min(leaving, s.taxpayers)
        s.citizens -= fromTaxpayers
        leaving -= fromTaxpayers
        while leaving > 0 && !s.soldiers.isEmpty {
            s.soldiers.removeLast()
            s.citizens -= 1
            leaving -= 1
        }
        return s.citizens - before
    }

    /// +n: new people arrive as soldiers of that kind (like the volunteer at dawn, names from the seeded stream); −n:
    /// soldiers of that kind lay down their arms and go back to the town as taxpayers (the last recruited first).
    static func changeSoldiers(_ s: inout GameState, kind: SoldierKind, by count: Int, balance: Balance) -> Int {
        if count > 0 {
            for _ in 0..<count {
                s.citizens += 1
                s.addSoldier(kind, balance: balance)
            }
            if DayClock.phase(at: s.hour) != .day {
                Battle.assignPosts(&s, balance: balance, fromScratch: false)
                Battle.updateGuards(&s, balance: balance)
            }
            return count
        }
        var removed = 0
        var index = s.soldiers.count - 1
        while removed < -count && index >= 0 {
            if s.soldiers[index].kind == kind {
                s.soldiers.remove(at: index)
                removed += 1
            }
            index -= 1
        }
        return -removed
    }

    /// Castle staff beyond the lodge (kept in `CourtState.extraBuilders`, so a new lodge keeps them); the castle keeps
    /// at least one builder. Returns the change.
    static func changeBuilders(_ s: inout GameState, by count: Int, balance: Balance) -> Int {
        let before = s.builders.count
        var court = s.court ?? CourtState()
        court.extraBuilders = max(1 - s.lodgeBuilders(balance), court.extraBuilders + count)
        s.court = court
        Build.syncBuilders(&s, balance: balance)
        return s.builders.count - before
    }

    /// Sets a flag, or clears it when written `-name`.
    static func setFlag(_ s: inout GameState, _ flag: String, outcome: inout PetitionOutcome) {
        if flag.hasPrefix("-") {
            let name = String(flag.dropFirst())
            if let found = s.flags.firstIndex(of: name) {
                s.flags.remove(at: found)
                outcome.flagsCleared.append(name)
            }
        } else if !s.flags.contains(flag) {
            s.flags.append(flag)
            s.flags.sort()
            outcome.flagsSet.append(flag)
        }
    }

    /// The `unlock` ids: the war tax, the chapel's blessing (+1 happiness each dawn; `-blessing` lifts it), and the
    /// middle line, the outer line and the beacon site before their day.
    static let unlockIDs: Set<String> = ["warTax", "blessing", "-blessing", "line2", "line3", "beacon"]

    /// Applies an unlock; false when it changed nothing (already open, or an unknown id).
    @discardableResult
    static func unlock(_ s: inout GameState, _ id: String) -> Bool {
        switch id {
        case "warTax":
            guard !s.warTaxUnlocked else { return false }
            s.warTaxUnlocked = true
        case "blessing":
            guard !s.chapelBlessed else { return false }
            s.chapelBlessed = true
        case "-blessing":
            guard s.chapelBlessed else { return false }
            s.chapelBlessed = false
        case "line2", "line3", "beacon":
            var court = s.court ?? CourtState()
            guard !court.unlocks.contains(id) else { return false }
            court.unlocks.append(id)
            court.unlocks.sort()
            s.court = court
        default:
            return false
        }
        return true
    }

    // MARK: - The reference bot

    /// The bot's fixed policy (DESIGN.md "M3 in detail"): Odile's counsel when it can be taken, else the cheapest
    /// choice that can (the most gold kept; ties: the first); nil when none can.
    static func botChoice(_ petition: Petition, _ s: GameState) -> Int? {
        if let counsel = petition.counsel, counsel >= 0, counsel < petition.choices.count,
           blocker(petition.choices[counsel], s) == nil {
            return counsel
        }
        var best: Int?
        var bestGold = Int.min
        for (position, choice) in petition.choices.enumerated() where blocker(choice, s) == nil {
            let gold = choice.effect.gold ?? 0
            if gold > bestGold {
                best = position
                bestGold = gold
            }
        }
        return best
    }

    /// The bot holds audience by day: today's queue drawn, then every petitioner heard with `botChoice` (one it cannot
    /// answer keeps waiting and goes home at the horn).
    @discardableResult
    static func holdAudience(_ s: inout GameState, catalog: PetitionCatalog, balance: Balance) -> [PetitionOutcome] {
        prepare(&s, catalog: catalog)
        var outcomes: [PetitionOutcome] = []
        var rounds = 0
        while rounds < 16, let court = s.court, court.queueDay == s.day, !court.queue.isEmpty {
            rounds += 1
            var heardOne = false
            for position in court.queue.indices {
                guard let petition = catalog.petition(court.queue[position].id),
                      let pick = botChoice(petition, s) else { continue }
                if let outcome = hear(&s, choice: pick, at: position, catalog: catalog, balance: balance) {
                    outcomes.append(outcome)
                    heardOne = true
                }
                break
            }
            if !heardOne { break }
        }
        return outcomes
    }
}
