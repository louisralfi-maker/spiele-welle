/// What the present bot was about at a moment of the night.
enum PresentErrand: Sendable, Equatable {
    /// Standing where the fight is: behind the wall that takes the wave, or behind the guards in a breach.
    case stand
    /// Walking to a wall below half its strength under attack, to patch it where it stands.
    case patch(plot: Int)
    /// Fetching a dead brazier near its place while no creature is near it.
    case relight(plot: Int)
}

/// What the present bot did in one night: the chore guard of front-1 (docs/REALM.md section 6: "whether presence makes
/// the night a chore"). A move is a change of the place it stands at; trips are its errands.
struct PresentTally: Sendable, Equatable {
    /// A change of the standing place by more than this many px counts as a move.
    static let moveThreshold = 30.0
    /// The log keeps at most this many lines.
    static let logLines = 16

    var night = 0
    var moves = 0
    var patchTrips = 0
    var relightTrips = 0
    var patches = 0
    /// Seconds it ran, and how far it ran.
    var runSeconds = 0.0
    var distance = 0.0
    /// Seconds it stood with the guards in a breach.
    var guardSeconds = 0.0
    /// Its standing place now (nil before the first move).
    var spot: Double?
    /// The night in a few lines ("t 31 s: to the guards in the outer breach, x 664").
    var log: [String] = []

    init(night: Int = 0) {
        self.night = night
    }

    mutating func note(_ line: String) {
        if log.count < PresentTally.logLines { log.append(line) }
    }
}

/// The "present" bot of T13 (docs/REALM.md section 3): by day exactly the reference bot (`Autoplay.reference`, its build
/// order, taxes and audiences), so a night played from the same eve differs only by the night. At night it plays by the
/// front rule: it takes the lord to where the fight is (the wall the next wave lands on; when the guards hold a breach
/// and the way is clear, behind them), patches as the reference does but standing at the wall, fetches a dead brazier
/// near its place only while no creature is near it (relighting by passing; never the old Light action), and keeps out
/// of the creatures' way, since a creature that reaches the lord throws him back and shakes him.
struct PresentBot: Sendable {
    /// The reference bot that plays the day.
    var day: Autoplay
    var patchesTonight = 0
    var errand: PresentErrand = .stand
    var tally = PresentTally()

    init(day: Autoplay = .reference()) {
        self.day = day
    }

    /// Called before every sim step, as `Autoplay.act`.
    mutating func act(_ s: inout GameState, dt: Double, balance: Balance, events: inout [SimEvent],
                      petitions: PetitionCatalog = .standard) {
        FrontNight.adopt(&s)
        if DayClock.phase(at: s.hour) == .day {
            day.act(&s, dt: dt, balance: balance, events: &events, petitions: petitions)
            return
        }
        if tally.night != s.nightNumber {
            tally = PresentTally(night: s.nightNumber)
            patchesTonight = 0
            errand = .stand
        }
        let (goal, next, withGuards) = choose(s, balance: balance)
        if next != errand {
            switch next {
            case .patch(let plot):
                tally.patchTrips += 1
                tally.note("\(clock(s)): to patch \(Realm.plots[plot].key)")
            case .relight(let plot):
                tally.relightTrips += 1
                tally.note("\(clock(s)): to fetch the dead brazier \(Realm.plots[plot].key)")
            case .stand:
                break
            }
            errand = next
        }
        if next == .stand {
            if tally.spot == nil || abs(goal - (tally.spot ?? goal)) > PresentTally.moveThreshold {
                tally.moves += 1
                tally.note("\(clock(s)): to \(withGuards ? "the guards in the breach" : placeName(goal)), x \(Int(goal))")
            }
            tally.spot = goal
            if withGuards { tally.guardSeconds += dt }
        }
        walk(&s, to: goal, dt: dt, balance: balance)
        if case .patch(let plot) = next, s.king.patchCooldown <= 0, s.gold >= balance.patchCost,
           FrontNight.patch(&s, plot: plot, balance: balance, events: &events) {
            patchesTonight += 1
            tally.patches += 1
        }
        if s.king.velocity != 0 {
            tally.runSeconds += dt
            tally.distance += abs(s.king.velocity) * dt
        }
    }

    // MARK: - Choosing

    /// Where to go now and why: a patch first (as the reference: a wall below half under attack, at most three a night,
    /// never while saving for the Great Beacon), then a dead brazier near its place while it is safe, else its place.
    func choose(_ s: GameState, balance: Balance) -> (goal: Double, errand: PresentErrand, withGuards: Bool) {
        let tuning = balance.front
        let saving = day.buildsBeacon && s.day >= Realm.beaconUnlockDay && s.beaconStage < 3
        if patchesTonight < tuning.botMaxPatches && !saving && s.gold >= balance.patchCost {
            for plot in Realm.wallsOuterFirst {
                let state = s.plots[plot]
                guard let item = state.item, !state.isRubble else { continue }
                let full = Build.maxHP(item, balance: balance)
                guard state.hp < full * tuning.botPatchBelow, PresentBot.underAttack(s, plot: plot) else { continue }
                return (Realm.plots[plot].x + min(item.width, 40) / 2, .patch(plot: plot), false)
            }
        }
        let (stand, withGuards) = PresentBot.place(s, balance: balance)
        if let plot = PresentBot.brazierToFetch(s, near: stand, balance: balance) {
            return (Realm.plots[plot].x, .relight(plot: plot), false)
        }
        return (stand, .stand, withGuards)
    }

    /// Its place: behind the guards while they hold a breach and nothing stands between the lord and them, else behind
    /// the face of the first standing wall (the wall the next wave lands on), else behind the hearth.
    static func place(_ s: GameState, balance: Balance) -> (x: Double, withGuards: Bool) {
        let tuning = balance.front
        var wallSpot = Realm.hearthX + tuning.botBehindWall
        for plot in Realm.wallsOuterFirst where s.plots[plot].stands {
            wallSpot = Realm.plots[plot].x + tuning.botBehindWall
            break
        }
        if tuning.botJoinsGuards && s.guardsHolding && s.guardPostX < wallSpot {
            let spot = s.guardPostX + tuning.botBehindGuards
            let low = min(spot, s.king.x)
            let high = max(spot, s.king.x)
            var clear = true
            for c in s.creatures where c.hp > 0 && !c.kind.flies && c.x >= s.guardPostX && c.x >= low - tuning.touchReach
                && c.x <= high + tuning.touchReach {
                clear = false
                break
            }
            if clear { return (spot, true) }
        }
        return (wallSpot, false)
    }

    /// The nearest dead brazier within `botRelightDetour` of its place whose way is safe: no creature on the ground from
    /// `botRelightSafe` px in front of the brazier to the lord, and the lantern ready by the time he gets there.
    static func brazierToFetch(_ s: GameState, near stand: Double, balance: Balance) -> Int? {
        guard let front = s.front else { return nil }
        let tuning = balance.front
        var best: Int?
        var bestDistance = Double.infinity
        for plot in Realm.brazierPlots where s.plots[plot].item != nil && s.plots[plot].snuffed {
            let x = Realm.plots[plot].x
            guard abs(x - stand) <= tuning.botRelightDetour else { continue }
            let distance = abs(x - s.king.x)
            let arrival = max(0, distance - tuning.relightReach) / max(1, balance.kingRunSpeed)
            guard front.relightCooldown <= arrival + 0.05 else { continue }
            var safe = true
            for c in s.creatures where c.hp > 0 && !c.kind.flies && c.x >= x - tuning.botRelightSafe
                && c.x <= max(x, s.king.x) + tuning.touchReach {
                safe = false
                break
            }
            if safe && distance < bestDistance {
                best = plot
                bestDistance = distance
            }
        }
        return best
    }

    static func underAttack(_ s: GameState, plot: Int) -> Bool {
        for c in s.creatures where c.hp > 0 && c.action == .attackingWall && c.target == plot { return true }
        return false
    }

    /// Sets the lord running toward `x`, arriving exactly (as `Autoplay` walks him).
    private func walk(_ s: inout GameState, to x: Double, dt: Double, balance: Balance) {
        let dx = x - s.king.x
        if abs(dx) < 0.5 || dt <= 0 {
            s.king.velocity = 0
            return
        }
        let speed = balance.kingRunSpeed
        s.king.velocity = max(-speed, min(speed, dx / dt))
    }

    // MARK: - The log's words

    private func clock(_ s: GameState) -> String {
        DayClock.phase(at: s.hour) == .dusk ? "dusk" : "t \(Int(s.nightTime.rounded())) s"
    }

    private func placeName(_ x: Double) -> String {
        for plot in Realm.wallsOuterFirst where abs(Realm.plots[plot].x - x) < 40 {
            switch Realm.plots[plot].line {
            case 3: return "the outer wall"
            case 2: return "the middle wall"
            default: return "the gatehouse"
            }
        }
        return "the hearth"
    }
}
