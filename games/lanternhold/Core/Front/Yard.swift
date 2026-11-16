/// The drill yard's rules (docs/YARD.md sections 2 to 4; build 3, wave 2, lane 2, step 1): stage 2 and the pitch kettle
/// are ordered by day through the count (docs/PAY.md: `PayOffer.yard`) and stand from the next dawn; while the yard
/// stands every soldier drills from 09:00 to 16:00, the roll is taken at noon (a man sworn in after it starts the next
/// day) and the day counts at 16:00 for everyone on it, twice once a day when the lord stood at the fence for three
/// seconds; after three days of drill a recruit is trained at the next dawn (an archer looses faster, a guard holds
/// more); the kettle makes every third arrow a fire arrow. Pure functions of `GameState`; `Sim` calls `step`, `horn` and
/// `dawn`, `Battle` asks `archerPeriod`, and `balance` changes the night's numbers by values. A realm without a yard
/// (`GameState.yard` nil: every older save, every reference bot) plays exactly as before.
enum Yard {
    // MARK: - The place (game px of the world strip; step 1's placeholder ground, the picture step lays it out)

    /// The yard's ground in the courtyard, between the gatehouse's back and the barracks (YARD.md section 1: where the
    /// barracks stands, against the inner face of the wall).
    static let groundLeft = 1446.0
    static let groundRight = 1480.0
    /// Where the yard's thing stands (the drill yard's site, then the kettle's tripod) and half its width.
    static let plotX = 1464.0
    static let plotHalf = 9.0
    /// The fence's middle (the lord at the fence: `YardTuning.fenceReach`).
    static let fenceX = 1464.0

    // MARK: - What is bought

    /// What the yard offers now (one thing at a time), nil when nothing: from day `YardTuning.stageDay` the drill yard
    /// while none stands; once it stands, the pitch kettle until it is ordered. Nothing while an order waits for its
    /// dawn.
    static func offer(_ s: GameState, balance: Balance) -> YardOffer? {
        guard !s.defeated else { return nil }
        let yard = s.yard ?? YardState()
        if yard.orderedStage != nil { return nil }
        if !yard.stands { return s.day >= balance.yard.stageDay ? .stage(2) : nil }
        if yard.kettle == nil { return .kettle }
        return nil
    }

    /// An offer's price.
    static func price(_ offer: YardOffer, balance: Balance) -> Int {
        switch offer {
        case .stage:
            return balance.yard.stagePrice
        case .kettle:
            return balance.yard.kettlePrice
        }
    }

    /// True while `offer` can be ordered now, the purse aside: by day, and it is what the yard offers.
    static func isOpen(_ offer: YardOffer, state s: GameState, balance: Balance) -> Bool {
        DayClock.phase(at: s.hour) == .day && Yard.offer(s, balance: balance) == offer
    }

    /// Orders `offer` (the count's seal): its price leaves the purse; the stage stands and Bram brings the kettle at the
    /// next dawn. False, and nothing changed, when it is not open or the purse is short.
    @discardableResult
    static func order(_ s: inout GameState, _ offer: YardOffer, balance: Balance) -> Bool {
        guard isOpen(offer, state: s, balance: balance) else { return false }
        let cost = price(offer, balance: balance)
        guard s.gold >= cost else { return false }
        s.gold -= cost
        var yard = s.yard ?? YardState()
        switch offer {
        case .stage(let stage):
            yard.orderedStage = stage
        case .kettle:
            yard.kettle = .ordered
        }
        s.yard = yard
        return true
    }

    /// True while `offer` was ordered and waits for its dawn (the site lantern burns until then).
    static func isPending(_ offer: YardOffer, state s: GameState) -> Bool {
        guard let yard = s.yard else { return false }
        switch offer {
        case .stage(let stage):
            return yard.orderedStage == stage
        case .kettle:
            return yard.kettle == .ordered
        }
    }

    // MARK: - The day

    /// True when the clock went over `hour` in a step from `before` to `after` (within one day).
    static func crossed(_ hour: Double, from before: Double, to after: Double) -> Bool {
        before < hour && after >= hour && after >= before
    }

    /// True while the soldiers drill (the yard stands, 09:00 to 16:00).
    static func drilling(_ s: GameState, balance: Balance) -> Bool {
        guard let yard = s.yard, yard.stands, !s.defeated else { return false }
        return s.hour >= balance.yard.drillFrom && s.hour < balance.yard.drillUntil
    }

    /// One step of the day (`Sim.step`, after the clock moved from `before`): the roll at noon, the lord at the fence,
    /// the day counted at the end of the drill.
    static func step(_ s: inout GameState, from before: Double, dt: Double, balance: Balance) {
        guard var yard = s.yard, yard.stands, !s.defeated else { return }
        let t = balance.yard
        let hour = s.hour
        if crossed(t.rollHour, from: before, to: hour) {
            yard.rollDay = s.day
            yard.roll = s.soldiers.filter { $0.trained != true }.map(\.id)
        }
        if hour >= t.drillFrom && hour < t.drillUntil && yard.doubledDay != s.day {
            let still = abs(s.king.velocity) < t.stillSpeed
            if still && abs(s.king.x - fenceX) <= t.fenceReach {
                yard.fenceWatch += dt
                if yard.fenceWatch >= t.fenceSeconds - 1e-9 {
                    yard.doubledDay = s.day
                    yard.fenceWatch = 0
                }
            } else {
                yard.fenceWatch = 0
            }
        } else if yard.fenceWatch != 0 {
            yard.fenceWatch = 0
        }
        if crossed(t.drillUntil, from: before, to: hour) {
            if yard.rollDay == s.day && !yard.roll.isEmpty {
                let days = yard.doubledDay == s.day ? max(1, t.doubleDay) : 1
                let roll = Set(yard.roll)
                for index in s.soldiers.indices where roll.contains(s.soldiers[index].id) {
                    guard s.soldiers[index].trained != true else { continue }
                    s.soldiers[index].drilled = (s.soldiers[index].drilled ?? 0) + days
                }
            }
            yard.roll = []
        }
        if s.yard != yard { s.yard = yard }
    }

    /// True when the lord made today count double.
    static func doubledToday(_ s: GameState) -> Bool {
        guard let yard = s.yard else { return false }
        return yard.doubledDay == s.day
    }

    // MARK: - The night

    /// The horn (`Sim.step`): the trained soldiers' names, so the dawn can name a trained man who fell.
    static func horn(_ s: inout GameState) {
        guard var yard = s.yard else { return }
        var names: [String] = []
        for soldier in s.soldiers where soldier.trained == true { names.append(soldier.name) }
        yard.nightTrained = names
        if s.yard != yard { s.yard = yard }
    }

    /// A trained archer looses every `YardTuning.trainedArcherPeriod` seconds, a recruit every `Balance.archerPeriod`.
    static func archerPeriod(_ soldier: Soldier, balance: Balance) -> Double {
        soldier.trained == true ? balance.yard.trainedArcherPeriod : balance.archerPeriod
    }

    /// The night's numbers with the yard's works in use (by values; unchanged without a yard): the pitch kettle makes
    /// every third arrow a fire arrow.
    static func balance(_ base: Balance, for s: GameState) -> Balance {
        guard let yard = s.yard, yard.kettleInUse else { return base }
        var b = base
        b.fireArrowEvery = max(1, min(base.fireArrowEvery, base.yard.kettleFireEvery))
        return b
    }

    // MARK: - The dawn

    /// The dawn (`Sim.dawn`, after the report is made): the trained men who fell are named, the stage ordered stands,
    /// Bram brings the kettle, and every recruit with his days of drill is trained (Brannock hands him the company's
    /// coat). The report's yard half is set when it has something to tell; returned for the tests.
    @discardableResult
    static func dawn(_ s: inout GameState, balance: Balance) -> YardDawnReport? {
        guard var yard = s.yard else { return nil }
        var report = YardDawnReport()
        var fallen = Set<String>()
        for soldier in s.night.fallen { fallen.insert(soldier.name) }
        report.fallenTrained = yard.nightTrained.filter { fallen.contains($0) }
        yard.nightTrained = []
        if let stage = yard.orderedStage {
            yard.stage = max(yard.stage, stage)
            yard.orderedStage = nil
            report.raised = yard.stage
        }
        if yard.kettle == .ordered {
            yard.kettle = .inUse
            report.kettle = true
        }
        for index in s.soldiers.indices {
            var soldier = s.soldiers[index]
            guard soldier.trained != true, (soldier.drilled ?? 0) >= balance.yard.trainDays else { continue }
            train(&soldier, balance: balance)
            report.trained.append(soldier.name)
            s.soldiers[index] = soldier
        }
        yard.roll = []
        yard.fenceWatch = 0
        s.yard = yard
        if !report.isEmpty { s.lastReport?.yard = report }
        return report
    }

    /// Makes `soldier` trained: a guard holds `YardTuning.trainedGuardHP` from now on (healed to it); an archer's faster
    /// loose is `archerPeriod`.
    static func train(_ soldier: inout Soldier, balance: Balance) {
        soldier.trained = true
        if soldier.kind == .guardsman {
            soldier.maxHP = max(soldier.maxHP, balance.yard.trainedGuardHP)
            soldier.hp = soldier.maxHP
        }
    }

    // MARK: - Debug and tests

    /// The yard for a picture (`-GWYard`, `-GWTrained`, Debug only; the unit tests): `stage` stands (1 leaves no yard
    /// unless the kettle is asked), the kettle in use, every soldier trained.
    static func proof(_ s: inout GameState, stage: Int?, kettle: Bool, trained: Bool, balance: Balance) {
        if let stage, stage >= 2 || kettle {
            var yard = s.yard ?? YardState()
            yard.stage = max(yard.stage, max(2, stage))
            yard.orderedStage = nil
            if kettle { yard.kettle = .inUse }
            s.yard = yard
        }
        if trained {
            for index in s.soldiers.indices where s.soldiers[index].trained != true {
                s.soldiers[index].drilled = max(s.soldiers[index].drilled ?? 0, balance.yard.trainDays)
                train(&s.soldiers[index], balance: balance)
            }
        }
    }

    /// The yard for the scene's value (Debug, the UI tests): `none`, or `<stage>[+<ordered>]` with `k:o` (ordered) or
    /// `k:u` (in use), the trained and the soldiers, the days drilled in all, `x2` on a double day, `drill` while they
    /// drill.
    static func word(_ s: GameState, balance: Balance) -> String {
        guard let yard = s.yard else { return "none" }
        var text = "\(yard.stage)"
        if let ordered = yard.orderedStage { text += "+\(ordered)" }
        switch yard.kettle {
        case .ordered?: text += ",k:o"
        case .inUse?: text += ",k:u"
        case nil: break
        }
        var trained = 0
        var days = 0
        for soldier in s.soldiers {
            if soldier.trained == true { trained += 1 }
            days += soldier.drilled ?? 0
        }
        text += ",t:\(trained)/\(s.soldiers.count),d:\(days)"
        if yard.doubledDay == s.day { text += ",x2" }
        if drilling(s, balance: balance) { text += ",drill" }
        return text
    }
}
