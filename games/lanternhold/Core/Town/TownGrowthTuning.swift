/// Target T12 (docs/TOWN.md section 3, town-3): "a player who grows the town fully by night 14 earns 25 to 35 % more
/// taxes than one who does not, and still cannot skip the defence. Bots that do not grow the town give today's numbers."
///
/// Measured with three bots on the same seeds, each the reference bot with its order changed (`Autoplay.order(for:)`):
///
/// - **The grower** builds the middle line as the reference does, then puts the whole growth before the beacon: the
///   two far fields as soon as they open, the fourth big house, the market, the tavern, every farmstead, the
///   townhouses, the inn and the market hall (`growthSteps`).
/// - **The old town** plays the same game without the new growth: the same middle line, then the fourth big house,
///   the market and the tavern before the beacon (`oldTownSteps`). It is "one who does not grow the town": the gold the
///   grower puts into the growth it keeps for the beacon and the rest of the order.
/// - **The skipper** builds the first line and then only the town, the growth included, and no defence beyond it
///   (`skipsDefence`): it must not reach the chapter's end. (Round lh-t3-1: the first line alone holds to night 14 on
///   every seed, so the skipper is played to night 20; its hearth and its fallen by night 14 are reported.)
///
/// T12 passes when the grower's taxes at the dawn after night 14 are 25 to 35 % above the old town's (the mean over
/// the seeds), the grower held every night to it, and the skipper fell by night 20 on every seed. The reference bot's
/// own taxes are reported beside them: it fills its houses on day 13 and builds its fourth big house only after the
/// beacon, so a grower is further ahead of it. `tools/tune.py` mirrors the economy half; it leaves out the court and the
/// battle, and its grower's people grow more slowly than on the runner (T12 there reads about 8 points lower).
extension Autoplay {
    /// Inserted right after the reference's `.build("town.field.8", .field)`: the far fields, from day 5.
    static let farFieldSteps: [BotStep] = [
        .build("town.field.9", .field),
        .build("town.field.10", .field),
    ]

    /// The grower's town, inserted right before the reference's `.build("town.house.4", .bigHouse)` (after the middle
    /// line); the reference's own town steps that follow find it built and pass. `tools/tune.py` reads these lines.
    static let growthSteps: [BotStep] = [
        .build("town.house.4", .bigHouse),
        .build("town.house.5", .bigHouse),
        .build("town.market.6", .market),
        .build("town.tavern.7", .tavern),
        .build("town.field.2", .farmstead),
        .build("town.field.8", .farmstead),
        .build("town.house.1", .townhouse),
        .build("town.house.3", .townhouse),
        .build("town.field.9", .farmstead),
        .build("town.field.10", .farmstead),
        .build("town.house.4", .townhouse),
        .build("town.house.5", .townhouse),
        .build("town.tavern.7", .inn),
        .build("town.market.6", .marketHall),
    ]

    /// The old town's, at the same place: the town of before, built as early as the grower builds its own.
    static let oldTownSteps: [BotStep] = [
        .build("town.house.4", .bigHouse),
        .build("town.house.5", .bigHouse),
        .build("town.market.6", .market),
        .build("town.tavern.7", .tavern),
    ]

    /// The reference order with `steps` inserted before its first `.build("town.house.4", .bigHouse)` and, with `far`,
    /// the far fields after its `.build("town.field.8", .field)`.
    static func referenceOrder(inserting steps: [BotStep], farFields far: Bool) -> [BotStep] {
        var order: [BotStep] = []
        var inserted = false
        for step in referenceOrder {
            if !inserted && step == .build("town.house.4", .bigHouse) {
                order += steps
                inserted = true
            }
            order.append(step)
            if far && step == .build("town.field.8", .field) { order += farFieldSteps }
        }
        return order
    }

    /// The grower's order.
    static let growerOrder: [BotStep] = referenceOrder(inserting: growthSteps, farFields: true)

    /// The old town's order.
    static let oldTownOrder: [BotStep] = referenceOrder(inserting: oldTownSteps, farFields: false)

    /// The skipper's order: the reference's first line (up to its middle line's palisade), then its town steps, the far
    /// fields and the growth, and nothing more.
    static let skipsDefenceOrder: [BotStep] = {
        var order: [BotStep] = []
        for step in referenceOrder {
            if step == .build("l2.wall", .palisade) { break }
            order.append(step)
        }
        for step in referenceOrder.dropFirst(order.count) {
            if case .build(let key, _) = step, key.hasPrefix("town.") { order.append(step) }
        }
        return order + farFieldSteps + growthSteps
    }()

    /// The build order of a plan (`planDay`): the reference's for the reference bot and for the bot that builds
    /// nothing (which never reaches it).
    static func order(for plan: Plan) -> [BotStep] {
        switch plan {
        case .reference, .buildsNothing: return referenceOrder
        case .grower: return growerOrder
        case .oldTown: return oldTownOrder
        case .skipsDefence: return skipsDefenceOrder
        }
    }

    /// A bot of `plan` with the reference bot's habits (normal tax, it builds the beacon, it hears the court).
    static func town(_ plan: Plan) -> Autoplay {
        Autoplay(plan: plan)
    }
}

/// T12's numbers: per seed the taxes owed at the dawn after night 14 (the day's whole sum, `DawnReport.taxes.total`)
/// of the grower, the old town and the reference bot, the grower's standing then, the nights it held, and the night
/// the skipper fell (0: it held night 14).
struct TownGrowthMetrics: Sendable {
    /// T12 compares at the dawn after this night.
    static let night = 14
    /// The skipper is played to this night (the chapter's last).
    static let skipperNights = 20
    /// The band of the grower's taxes over the old town's (the mean over the seeds).
    static let band: ClosedRange<Double> = 0.25...0.35

    var seeds: [UInt64] = []
    var growerTaxes: [Int] = []
    var oldTownTaxes: [Int] = []
    var referenceTaxes: [Int] = []
    /// The taxes over every dawn from the first to the one after night 14, summed (reported).
    var growerTaxesSum: [Int] = []
    var oldTownTaxesSum: [Int] = []
    var growerStanding: [Int] = []
    var growerStage: [RealmStage] = []
    /// The dawn on which the grower's realm became a village, a town (0: not by night 14).
    var growerVillageDay: [Int] = []
    var growerTownDay: [Int] = []
    var growerHeld: [Int] = []
    var growerFallen: [Int] = []
    var oldTownFallen: [Int] = []
    /// The night the skipper fell (0: it held night 20), and by night 14 its hearth's lowest strength and its fallen.
    var skipperFellOn: [Int] = []
    var skipperHearthLowest: [Int] = []
    var skipperFallen: [Int] = []
    var log: [String] = []

    /// The grower over the old town, seed by seed (0 where the grower fell).
    var ratios: [Double] {
        zip(growerTaxes, oldTownTaxes).map { $1 > 0 ? Double($0) / Double($1) - 1 : 0 }
    }

    var meanRatio: Double { ratios.isEmpty ? 0 : ratios.reduce(0, +) / Double(ratios.count) }

    /// The grower over the reference bot, seed by seed.
    var referenceRatios: [Double] {
        zip(growerTaxes, referenceTaxes).map { $1 > 0 ? Double($0) / Double($1) - 1 : 0 }
    }

    var passes: Bool {
        !seeds.isEmpty && TownGrowthMetrics.band.contains(meanRatio)
            && growerHeld.allSatisfy { $0 >= TownGrowthMetrics.night }
            && skipperFellOn.allSatisfy { $0 > 0 && $0 <= TownGrowthMetrics.skipperNights }
    }

    var report: String {
        func percent(_ value: Double) -> String {
            let tenths = Int((value * 1000).rounded())
            return (tenths < 0 ? "-" : "+") + String(abs(tenths) / 10) + "." + String(abs(tenths) % 10) + " %"
        }
        var lines: [String] = []
        lines.append("T12 \(passes ? "PASS" : "FAIL") the grower's taxes at the dawn after night \(TownGrowthMetrics.night) "
                     + "over the old town's: \(percent(meanRatio)) (target +25 to +35 %), seeds \(seeds): "
                     + "\(ratios.map(percent)); grower \(growerTaxes), old town \(oldTownTaxes); held \(growerHeld) "
                     + "(target \(TownGrowthMetrics.night)); the skipper fell on \(skipperFellOn) (target by night "
                     + "\(TownGrowthMetrics.skipperNights); 0 = held); by night \(TownGrowthMetrics.night) its hearth's "
                     + "lowest \(skipperHearthLowest), its fallen \(skipperFallen)")
        lines.append("   reported: over the reference bot \(referenceRatios.map(percent)) (reference \(referenceTaxes)); "
                     + "taxes over dawns 1-\(TownGrowthMetrics.night): grower \(growerTaxesSum), old town "
                     + "\(oldTownTaxesSum); standing \(growerStanding) (\(growerStage.map(\.rawValue))), a village on "
                     + "dawn \(growerVillageDay), a town on dawn \(growerTownDay) (0 = not yet); fallen: grower "
                     + "\(growerFallen), old town \(oldTownFallen)")
        lines.append("")
        lines.append(contentsOf: log)
        return lines.joined(separator: "\n")
    }
}

/// The bot runs of T12.
enum TownGrowthTuning {
    static func measure(balance: Balance, seeds: [UInt64] = [1, 2, 3]) -> TownGrowthMetrics {
        var m = TownGrowthMetrics()
        let nights = TownGrowthMetrics.night
        for seed in seeds {
            m.seeds.append(seed)
            let start = GameState.newRealm(seed: seed, balance: balance)
            let grower = TuningRun.play(start, bot: .town(.grower), balance: balance, nights: nights)
            let old = TuningRun.play(start, bot: .town(.oldTown), balance: balance, nights: nights)
            let reference = TuningRun.play(start, bot: .reference(), balance: balance, nights: nights)
            let skipper = TuningRun.play(start, bot: .town(.skipsDefence), balance: balance,
                                         nights: TownGrowthMetrics.skipperNights)
            func last(_ run: PlayResult) -> Int {
                run.fellOnNight == nil && run.outcomes.count == nights ? run.outcomes[nights - 1].taxes : 0
            }
            m.growerTaxes.append(last(grower))
            m.oldTownTaxes.append(last(old))
            m.referenceTaxes.append(last(reference))
            m.growerTaxesSum.append(grower.outcomes.reduce(0) { $0 + $1.taxes })
            m.oldTownTaxesSum.append(old.outcomes.reduce(0) { $0 + $1.taxes })
            m.growerStanding.append(TownGrowth.standing(grower.final, balance: balance))
            m.growerStage.append(TownGrowth.look(grower.final))
            m.growerHeld.append(grower.outcomes.filter(\.survived).count)
            m.growerFallen.append(grower.outcomes.reduce(0) { $0 + $1.fallen })
            m.oldTownFallen.append(old.outcomes.reduce(0) { $0 + $1.fallen })
            m.skipperFellOn.append(skipper.fellOnNight ?? 0)
            let early = skipper.outcomes.prefix(nights)
            m.skipperHearthLowest.append(Int((early.map(\.hearthLowest).min() ?? 100).rounded()))
            m.skipperFallen.append(early.reduce(0) { $0 + $1.fallen })
            let stages = stageDays(start, bot: .town(.grower), balance: balance, nights: nights)
            m.growerVillageDay.append(stages.village)
            m.growerTownDay.append(stages.town)
            if seed == seeds.first {
                m.log.append("seed \(seed), dawn by dawn: taxes grower / old town / reference, the grower's standing")
                for index in 0..<min(grower.outcomes.count, old.outcomes.count, reference.outcomes.count) {
                    let g = grower.outcomes[index]
                    m.log.append("  night \(g.night): \(g.taxes) / \(old.outcomes[index].taxes) / "
                                 + "\(reference.outcomes[index].taxes), citizens \(g.citizens) / "
                                 + "\(old.outcomes[index].citizens) / \(reference.outcomes[index].citizens), gold "
                                 + "\(g.gold) / \(old.outcomes[index].gold), buildings \(g.buildings)")
                }
            }
        }
        return m
    }

    /// The dawns on which a bot's realm became a village and a town (0: not within `nights`).
    static func stageDays(_ start: GameState, bot: Autoplay, balance: Balance, nights: Int) -> (village: Int, town: Int) {
        var s = start
        var player = bot
        var village = 0
        var town = 0
        for _ in 0..<nights {
            guard let report = Sim.runToDawn(&s, balance: balance, bot: &player) else { break }
            player.morning(&s, balance: balance)
            switch report.town?.stageReached {
            case .village?: village = report.day
            case .town?: town = report.day
            default: break
            }
        }
        return (village, town)
    }
}
