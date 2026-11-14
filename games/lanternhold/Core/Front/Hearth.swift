/// What a touch on the hearth would do: feed the fire with wood (docs/REALM.md section 4: "Once a day the lord can feed
/// it"). The picture shows the price as coins at the hearth; the count (docs/PAY.md) pays it and calls `Hearth.feed`.
struct HearthFeedOffer: Sendable, Equatable {
    var price: Int
    /// The fire now (low or embers: a bright fire and a dead one take no wood).
    var level: HearthLevel
    /// Already fed today (once a day, by the day's number).
    var fedToday: Bool
    /// The purse holds the price.
    var affordable: Bool
    /// The lord stands at the hearth.
    var inReach: Bool

    /// A touch would feed it now.
    var ready: Bool { !fedToday && affordable && inReach }
}

/// A place that lies burnt, for the picture (charred beams, no light in it) and for the count (its rebuild price).
struct HearthRuin: Sendable, Equatable {
    var plot: Int
    /// What stood there and comes back.
    var item: BuildItem
    /// The townspeople of a burnt house who shelter in the chapel.
    var household: Int
    /// What the rebuild costs (a third of what it cost).
    var price: Int
    /// The builders are at it (the rebuild is paid).
    var rebuilding: Bool
}

/// Everything the picture needs from the hearth rule in one frame (docs/lanes/front.md, "front-2": what the screen
/// shows): read-only, built from the state.
struct HearthPicture: Sendable, Equatable {
    /// The rule is on for this realm.
    var ruleOn: Bool
    var level: HearthLevel
    /// The hearth light's intensity by step (`HearthTuning.glow`): the renderer multiplies the hearth light by it, and
    /// the town's street lanterns burn as the hearth does (docs/TOWN.md section 7).
    var glow: Double
    var ruins: [HearthRuin]
    /// Townspeople sheltering in the chapel (their houses lie burnt).
    var sheltering: Int
    /// The street lanterns burn tonight (one house fewer in a broken night).
    var lanternsLit: Bool
    /// What a touch on the hearth would do now (nil when the fire takes no wood).
    var feed: HearthFeedOffer?
    /// The stamps: a new `at` is a new breach or a new feeding.
    var lastBreak: HearthBreak?
    var lastFeed: HearthFeed?
}

/// The hearth rule (docs/REALM.md section 4, "The hearth (losing)"). The hearth is the realm's life and is seen as fire:
/// bright, low, embers, out. When creatures drain the hearth's strength (what makes the realm fall under the old rules)
/// the night breaks: the fire drops a step, a broken night's cost is taken (houses burn, townspeople with names die, a
/// fifth of the purse is gone, happiness falls), the creatures burn away and dawn comes at once. A night without a breach
/// raises the fire a step at dawn; once a day the lord can feed it. Out: the realm falls, and the fall card wakes at one
/// of the last three dawns (`DawnRing`). Night 20: the Lightless King at the hearth ends the chapter as today, whatever
/// the fire's state.
///
/// Deterministic: the cost draws from its own stream, seeded by the realm's seed and the night. Nothing here runs for a
/// realm without `GameState.hearthFire`.
enum Hearth {
    /// Mixed into the seed of a broken night's own random stream.
    static let salt: UInt64 = 0x4845_4152_5448

    // MARK: - The rule on

    /// Turns the rule on for this realm (the join calls it for the player's realm: a new realm and a loaded save). A
    /// realm that has it keeps it.
    static func adopt(_ s: inout GameState) {
        if s.hearthFire == nil { s.hearthFire = HearthState() }
    }

    /// The Lightless King's night (night 20 of the chapter): the hearth reached ends the chapter as today.
    static func isKingsNight(_ s: GameState) -> Bool {
        Battle.boss(night: s.nightNumber) == .lightlessKing
    }

    /// Whether the town's street lanterns burn tonight: the input (`HearthState.lanterns`) when the town or the people
    /// lane sets it, else the default rule (lit every evening, not in unrest).
    static func lanternsLit(_ s: GameState, balance: Balance) -> Bool {
        s.hearthFire?.lanterns ?? (s.happiness >= balance.unrestBelow)
    }

    // MARK: - The breach

    /// After the battle's step (`Sim.step`): when the creatures drained the hearth this step (the battle set
    /// `defeated`), the night breaks instead. The fire drops `breachSteps`; the cost is taken; above out the `.defeat`
    /// event goes, the creatures burn away and dawn comes at once (`Sim.secondChance`, which the defeat card uses too);
    /// at out the realm stays fallen (the fall card). On the Lightless King's night nothing changes: the realm falls as
    /// today.
    static func afterBattle(_ s: inout GameState, balance: Balance, events: inout [SimEvent]) {
        guard s.defeated, let fire = s.hearthFire, fire.level != .out, fire.pending?.night != s.nightNumber else {
            return
        }
        if isKingsNight(s) { return }
        let tuning = balance.front.hearth
        let before = fire.level
        let after = before.lowered(by: max(1, tuning.breachSteps))
        var brk = HearthBreak(at: s.simTime, night: s.nightNumber, hour: s.night.defeatHour ?? s.hour, before: before,
                              after: after)
        takeCost(&s, &brk, balance: balance)
        guard var marked = s.hearthFire else { return }
        marked.level = after
        marked.pending = brk
        marked.lastBreak = brk
        marked.brokenNights.append(brk.night)
        s.hearthFire = marked
        if after == .out { return }
        if let index = events.lastIndex(of: .defeat) { events.remove(at: index) }
        Sim.secondChance(&s, balance: balance, events: &events)
    }

    /// A broken night's cost (docs/REALM.md section 4), taken at the breach from the night's own seeded stream: one to
    /// three townspeople with names die (taxpayers, never soldiers); one or two houses burn (one fewer with the street
    /// lanterns lit, never fewer than one), or a field or the market stall when no house stands; a fifth of the purse is
    /// gone (at most 60); happiness falls by 8. Each burnt house's household shelters in the chapel.
    static func takeCost(_ s: inout GameState, _ brk: inout HearthBreak, balance: Balance) {
        guard var fire = s.hearthFire else { return }
        let tuning = balance.front.hearth
        var rng = SeededRandom(seed: SeededRandom.hash(s.seed ^ salt, Int64(brk.night)))
        brk.lanternsLit = lanternsLit(s, balance: balance)

        // The dead.
        let rolled = rng.int(in: tuning.deadLeast...max(tuning.deadLeast, tuning.deadMost))
        let deadCount = max(0, min(s.taxpayers, rolled))
        var used = Set(s.soldiers.map { $0.name })
        for entry in fire.dead { used.insert(entry.name) }
        for _ in 0..<deadCount {
            let name = HearthNames.pick(&rng, avoiding: used)
            used.insert(name)
            brk.dead.append(name)
            fire.dead.append(HearthDead(name: name, night: brk.night))
        }
        s.citizens -= deadCount
        s.hearthFire = fire

        // What burns.
        var houses = rng.int(in: tuning.housesLeast...max(tuning.housesLeast, tuning.housesMost))
        if brk.lanternsLit { houses = max(tuning.housesLeast, houses - tuning.lanternsSpare) }
        var pool = Realm.townPlots.filter { s.plots[$0].item?.slot == .house }
        var burning: [Int] = []
        if pool.isEmpty {
            let others = Realm.townPlots.filter {
                let slot = s.plots[$0].item?.slot
                return slot == .field || slot == .market
            }
            if !others.isEmpty { burning.append(others[rng.int(in: 0...(others.count - 1))]) }
        } else {
            for _ in 0..<min(max(0, houses), pool.count) {
                burning.append(pool.remove(at: rng.int(in: 0...(pool.count - 1))))
            }
        }
        let homes = households(s, balance: balance)
        for plot in burning.sorted() {
            guard let item = s.plots[plot].item else { continue }
            let household = item.slot == .house ? homes[plot] ?? 0 : 0
            fire.burnt.append(HearthBurnt(plot: plot, item: item, household: household, night: brk.night))
            brk.burnt.append(HearthPlace(plot: plot, item: item))
            s.plots[plot] = PlotState()
        }
        s.hearthFire = fire

        // The purse and the mood.
        let taken = min(tuning.goldCap, Int((Double(max(0, s.gold)) * tuning.goldShare).rounded(.down)))
        s.gold -= max(0, taken)
        brk.goldTaken = max(0, taken)
        let mood = s.happiness
        s.happiness = max(0, s.happiness - max(0, tuning.happinessLoss))
        brk.happinessLost = mood - s.happiness
    }

    /// The taxpayers who live in each standing house, spread by room (largest remainder, so the parts add up; the
    /// people already sheltering in the chapel are not in it).
    static func households(_ s: GameState, balance: Balance) -> [Int: Int] {
        let houses = Realm.townPlots.filter { s.plots[$0].item?.slot == .house }
        let rooms = houses.map { s.plots[$0].item == .bigHouse ? balance.bigHouseRoom : balance.houseRoom }
        let total = rooms.reduce(0, +)
        let people = max(0, s.taxpayers - sheltering(s))
        guard total > 0 else { return [:] }
        var parts: [Int] = []
        var fractions: [(fraction: Double, index: Int)] = []
        for (index, room) in rooms.enumerated() {
            let exact = Double(people) * Double(room) / Double(total)
            parts.append(Int(exact.rounded(.down)))
            fractions.append((exact - exact.rounded(.down), index))
        }
        fractions.sort { $0.fraction != $1.fraction ? $0.fraction > $1.fraction : $0.index < $1.index }
        var left = people - parts.reduce(0, +)
        var k = 0
        while left > 0 && k < fractions.count {
            parts[fractions[k].index] += 1
            left -= 1
            k += 1
        }
        var map: [Int: Int] = [:]
        for (index, plot) in houses.enumerated() { map[plot] = parts[index] }
        return map
    }

    // MARK: - The dawn

    /// At the dawn report (`Sim.dawn`, after the report is made): a broken night's tally goes into `DawnReport.hearth`
    /// (a fire that went out and was brought back by the second chance glows again at embers); after a night without a
    /// breach the fire rises a step. Rebuilt places leave the burnt list.
    static func dawn(_ s: inout GameState, balance: Balance) {
        guard var fire = s.hearthFire else { return }
        let tuning = balance.front.hearth
        let night = s.lastReport?.night ?? max(0, s.day - 1)
        var report = HearthDawnReport(before: fire.level, after: fire.level)
        if let brk = fire.pending, brk.night == night {
            report.broken = true
            report.before = brk.before
            report.burnt = brk.burnt
            report.dead = brk.dead
            report.goldTaken = brk.goldTaken
            report.happinessLost = brk.happinessLost
            if fire.level == .out {
                fire.level = max(.embers, tuning.secondChanceLevel)
                report.rekindled = true
            }
        } else if s.lastReport?.realmFell != true && fire.level > .out && fire.level < .bright {
            // A night without a breach (a night lost on the King's night and saved by the second chance is none).
            fire.level = fire.level.raised(by: tuning.recoverSteps)
        }
        report.after = fire.level
        fire.pending = nil
        s.hearthFire = fire
        tidy(&s)
        s.lastReport?.hearth = report
    }

    /// Drops the burnt entries whose plot stands again (the rebuild finished).
    static func tidy(_ s: inout GameState) {
        guard var fire = s.hearthFire else { return }
        let before = fire.burnt.count
        fire.burnt.removeAll { s.plots[$0.plot].item != nil }
        if fire.burnt.count != before { s.hearthFire = fire }
    }

    // MARK: - Wood

    /// What a touch on the hearth would do now; nil without the rule, after the fall, and while the fire is bright or
    /// out (it takes no wood then).
    static func feedOffer(_ s: GameState, balance: Balance) -> HearthFeedOffer? {
        guard let fire = s.hearthFire, !s.defeated, fire.level > .out, fire.level < .bright else { return nil }
        let tuning = balance.front.hearth
        return HearthFeedOffer(price: tuning.feedPrice, level: fire.level, fedToday: fire.fedDay == s.day,
                               affordable: s.gold >= tuning.feedPrice,
                               inReach: abs(s.king.x - Realm.hearthX) <= tuning.feedReach)
    }

    /// Feeds the fire (the count calls it when the last coin lands): one step, the price from the purse, once a day,
    /// the lord at the hearth. False (and nothing changes) when the offer is not ready.
    @discardableResult
    static func feed(_ s: inout GameState, balance: Balance) -> Bool {
        guard let offer = feedOffer(s, balance: balance), offer.ready, var fire = s.hearthFire else { return false }
        let tuning = balance.front.hearth
        let before = fire.level
        fire.level = before.raised(by: max(1, tuning.feedSteps))
        fire.fedDay = s.day
        fire.lastFeed = HearthFeed(at: s.simTime, day: s.day, before: before, after: fire.level)
        s.gold -= offer.price
        s.hearthFire = fire
        return true
    }

    // MARK: - Building up again

    /// A third (`rebuildShare`) of what the item cost, every tier it went through (a big house: the house and the big
    /// house), rounded up.
    static func rebuildPrice(_ item: BuildItem, balance: Balance) -> Int {
        var total = 0
        var tier: BuildItem? = item
        while let current = tier {
            total += balance.price(current)
            tier = BuildItem.allCases.first { $0.upgrade == current }
        }
        return Int((Double(total) * balance.front.hearth.rebuildShare - 1e-9).rounded(.up))
    }

    /// The build card's one line for a burnt plot (`Build.options` asks it first): the same item back, at a third,
    /// built as a rebuild. nil for any other plot (and always without the rule).
    static func rebuildOption(_ s: GameState, plot: Int, balance: Balance) -> BuildOption? {
        guard let fire = s.hearthFire, s.plots[plot].item == nil, s.plots[plot].job == nil,
              let burnt = fire.burntEntry(at: plot) else { return nil }
        return BuildOption(item: burnt.item, price: rebuildPrice(burnt.item, balance: balance), isRebuild: true)
    }

    /// Orders the rebuild of a burnt plot (the count calls it when the last coin lands): `Build.order` with the burnt
    /// item, so the gold goes at once and the builders come by day.
    @discardableResult
    static func rebuild(_ s: inout GameState, plot: Int, balance: Balance, events: inout [SimEvent]) -> OrderResult {
        guard let option = rebuildOption(s, plot: plot, balance: balance) else { return .notOffered }
        return Build.order(&s, plot: plot, item: option.item, balance: balance, events: &events)
    }

    /// The places that lie burnt (a paid rebuild included until it stands).
    static func ruins(_ s: GameState, balance: Balance) -> [HearthRuin] {
        guard let fire = s.hearthFire else { return [] }
        var list: [HearthRuin] = []
        for burnt in fire.burnt where s.plots[burnt.plot].item == nil {
            list.append(HearthRuin(plot: burnt.plot, item: burnt.item, household: burnt.household,
                                   price: rebuildPrice(burnt.item, balance: balance),
                                   rebuilding: s.plots[burnt.plot].job != nil))
        }
        return list
    }

    /// Townspeople sheltering in the chapel: the households of the burnt houses not yet rebuilt (never more than the
    /// taxpayers). At the join the town's ledger leaves them out of the day's taxes (docs/lanes/front.md, "front-2").
    static func sheltering(_ s: GameState) -> Int {
        guard let fire = s.hearthFire else { return 0 }
        var count = 0
        for burnt in fire.burnt where s.plots[burnt.plot].item == nil { count += burnt.household }
        return min(count, s.taxpayers)
    }

    /// Everything the picture reads in one frame.
    static func picture(_ s: GameState, balance: Balance) -> HearthPicture {
        guard let fire = s.hearthFire else {
            return HearthPicture(ruleOn: false, level: .bright, glow: 1, ruins: [], sheltering: 0, lanternsLit: true,
                                 feed: nil, lastBreak: nil, lastFeed: nil)
        }
        let glow = balance.front.hearth.glow
        let share = fire.level.rank < glow.count ? glow[fire.level.rank] : 1
        return HearthPicture(ruleOn: true, level: fire.level, glow: share, ruins: ruins(s, balance: balance),
                             sheltering: sheltering(s), lanternsLit: lanternsLit(s, balance: balance) && fire.level > .out,
                             feed: feedOffer(s, balance: balance), lastBreak: fire.lastBreak, lastFeed: fire.lastFeed)
    }
}
