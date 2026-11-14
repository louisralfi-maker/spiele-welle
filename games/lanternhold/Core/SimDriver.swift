/// The king walking back and forth for `-GWAutoplay walk` (the filmstrip's walk, now through the simulation).
struct KingWalker: Sendable, Equatable {
    var range: ClosedRange<Double>
    var direction: Int

    /// A walk of `leg` px from `x`, to the right when it fits before the river, else to the left.
    static func around(_ x: Double, leg: Double = 2400) -> KingWalker {
        if x + leg <= Realm.walkEnd - 20 {
            return KingWalker(range: x...(x + leg), direction: 1)
        }
        return KingWalker(range: max(20, x - leg)...max(20, x), direction: -1)
    }

    /// The velocity for the king at `x`, turning at the ends.
    mutating func velocity(kingX x: Double, speed: Double) -> Double {
        if direction > 0 && x >= range.upperBound {
            direction = -1
        } else if direction < 0 && x <= range.lowerBound {
            direction = 1
        }
        return Double(direction) * speed
    }
}

/// The game's fixed-step driver (M2b, DESIGN.md "Tech plan": the sim runs a fixed 60 Hz step with an accumulator and
/// never assumes a frame rate): real time accumulates, whole steps of 1/60 s run `Sim.step`, and the day clock is the
/// simulation's hour (one truth). Nothing steps while a card or the pause sheet is open (`isPaused`, set by the UI),
/// while the app is in the background, while `-GWFreezeTime` holds the clock or after the realm fell; time that passes
/// meanwhile is dropped, never caught up. The king moves through the simulation's own intent, `GameState.king.velocity`,
/// the one the reference bot (`Autoplay`) sets: a drag sets it, `-GWAutoplay play` lets the bot act before every
/// step, and any drag ends the bot. It keeps the realm of the last dawn for the save.
struct SimDriver: Sendable {
    static let step = Sim.frameStep
    /// A stalled frame never fast-forwards the world by more than this.
    static let maxCatchUp = 0.25

    var state: GameState
    let balance: Balance
    /// The reference bot playing live (`-GWAutoplay play`); nil while the player drives.
    var bot: Autoplay?
    /// `-GWAutoplay walk`.
    var walker: KingWalker?
    /// Where a tap on the realm strip sends the king (DESIGN.md "Controls"): he runs there and stops; nil when he does
    /// not travel. Any drag cancels it.
    var travelTarget: Double?
    /// A card or the pause sheet is open (the UI sets it).
    var isPaused = false
    /// The app is not active.
    var isInBackground = false
    /// `-GWFreezeTime YES`: the clock stands still.
    var isFrozen = false
    private(set) var accumulator = 0.0
    /// Steps run so far.
    private(set) var steps = 0
    /// The realm at its last dawn (what the save writes).
    private(set) var dawnSnapshot: GameState
    /// The petitions (M3): the driver draws each day's petitioners (`PetitionEngine.prepare`) after every step.
    let petitions: PetitionCatalog

    init(state: GameState, balance: Balance = .standard, bot: Autoplay? = nil, dawnSnapshot: GameState? = nil,
         petitions: PetitionCatalog = .standard) {
        var start = state
        PetitionEngine.prepare(&start, catalog: petitions)
        var snapshot = dawnSnapshot ?? start
        PetitionEngine.prepare(&snapshot, catalog: petitions)
        self.state = start
        self.balance = balance
        self.bot = bot
        self.dawnSnapshot = snapshot
        self.petitions = petitions
    }

    /// True while the simulation may step.
    var canStep: Bool { !isPaused && !isInBackground && !isFrozen && !state.defeated }

    /// Adds real seconds (at most `maxCatchUp` at once); while stepping is not allowed nothing is kept.
    mutating func accumulate(_ seconds: Double) {
        guard canStep else {
            accumulator = 0
            return
        }
        guard seconds > 0 else { return }
        accumulator += min(seconds, SimDriver.maxCatchUp)
    }

    /// Runs one fixed step when one is due; false when none is (or stepping is not allowed).
    mutating func stepIfDue(events: inout [SimEvent]) -> Bool {
        guard canStep, accumulator >= SimDriver.step else { return false }
        accumulator -= SimDriver.step
        stepOnce(events: &events)
        return true
    }

    /// Accumulates `seconds` and runs every step that is due; returns how many ran.
    @discardableResult
    mutating func advance(by seconds: Double, events: inout [SimEvent]) -> Int {
        accumulate(seconds)
        var count = 0
        while stepIfDue(events: &events) {
            count += 1
        }
        return count
    }

    private mutating func stepOnce(events: inout [SimEvent]) {
        let dt = SimDriver.step
        let first = events.count
        if var walk = walker {
            state.king.velocity = walk.velocity(kingX: state.king.x, speed: balance.kingWalkSpeed)
            walker = walk
        }
        if let target = travelTarget, bot == nil {
            let gap = target - state.king.x
            if abs(gap) < 0.5 || state.king.lightingPlot >= 0 {
                state.king.velocity = 0
                travelTarget = nil
            } else {
                let speed = balance.kingRunSpeed
                state.king.velocity = max(-speed, min(speed, gap / dt))
            }
        }
        if var player = bot {
            player.act(&state, dt: dt, balance: balance, events: &events, petitions: petitions)
            bot = player
        }
        Sim.step(&state, dt: dt, balance: balance, events: &events)
        PetitionEngine.prepare(&state, catalog: petitions)
        steps += 1
        for event in events[first...] {
            if case .dawn = event {
                dawnSnapshot = state
            }
        }
    }

    /// Where "Sound the horn" takes the clock: a minute before the horn.
    static let hornCallHour = 19.0 - 1.0 / 60

    /// The player sounds the horn by day (the pause sheet; M2b review: once day 1's gold was spent, two minutes of the
    /// day had nothing left to do): the realm plays on headless to 18:59 in the day's one-second steps, so the builders
    /// finish what they can, and the horn sounds at 19:00 a moment later. The king stands still meanwhile. False when it
    /// is not day.
    @discardableResult
    mutating func callTheNight() -> Bool {
        guard DayClock.phase(at: state.hour) == .day, state.hour < SimDriver.hornCallHour - 1e-6, !state.defeated else {
            return false
        }
        state.king.velocity = 0
        travelTarget = nil
        var remaining = (SimDriver.hornCallHour - state.hour) * DayClock.secondsPerHour
        var events: [SimEvent] = []
        while remaining > 1e-9 && !state.defeated {
            let dt = min(Sim.dayStep, remaining)
            events.removeAll(keepingCapacity: true)
            Sim.step(&state, dt: dt, balance: balance, events: &events)
            remaining -= dt
        }
        accumulator = 0
        return true
    }

    /// The walk pad's horizontal drag in points from where the finger went down (nil when it lifts): below the dead
    /// zone the king stands, beyond `runDistance` he runs (DESIGN.md "Controls": walk 36, run 80 game px/s). Any drag
    /// ends autoplay.
    mutating func setDrag(offset: Double?, deadZone: Double = 6, runDistance: Double = 40) {
        guard let offset else {
            if bot == nil && walker == nil { state.king.velocity = 0 }
            return
        }
        bot = nil
        walker = nil
        travelTarget = nil
        let distance = abs(offset)
        guard distance >= deadZone else {
            state.king.velocity = 0
            return
        }
        let speed = distance > runDistance ? balance.kingRunSpeed : balance.kingWalkSpeed
        state.king.velocity = offset > 0 ? speed : -speed
    }

    /// What the action button offers now (at night: light a snuffed brazier, patch a damaged wall).
    var kingAction: KingAction? {
        Sim.kingAction(state, balance: balance)
    }

    /// A tap on the realm strip: the king runs to `x` (inside his walk) and stops there; autoplay ends.
    mutating func travel(to x: Double) {
        bot = nil
        walker = nil
        travelTarget = min(Realm.walkEnd, max(0, x))
    }

    /// The defeat card's second chance (DESIGN.md "Losing a night"; the rewarded video comes in M7): the hearth flares
    /// up, every creature burns away and dawn comes at once. The new dawn is the snapshot the save writes.
    mutating func secondChance(events: inout [SimEvent]) {
        guard state.defeated else { return }
        Sim.secondChance(&state, balance: balance, events: &events)
        PetitionEngine.prepare(&state, catalog: petitions)
        accumulator = 0
        dawnSnapshot = state
    }

    /// The defeat card's "Replay the day": the realm as it was at this day's dawn.
    mutating func replayDay() {
        state = dawnSnapshot
        state.king.velocity = 0
        dawnSnapshot = state
        accumulator = 0
        travelTarget = nil
    }

    /// The pause sheet's "Restart chapter": a new realm on the morning of day 1, the player at the controls. The lord
    /// stays who he or she was until the name entry answers again.
    mutating func restart(seed: UInt64) {
        let lord = state.lord
        state = GameState.newRealm(seed: seed, balance: balance)
        state.lord = lord
        PetitionEngine.prepare(&state, catalog: petitions)
        dawnSnapshot = state
        accumulator = 0
        bot = nil
        walker = nil
        travelTarget = nil
    }

    /// The name entry's answer (the lord pass): the lord of the realm now and of its last dawn, so the save has it
    /// at once and a replayed day keeps it.
    mutating func setLord(_ lord: LordIdentity) {
        state.lord = lord
        dawnSnapshot.lord = lord
    }

    /// The ads (a rewarded video's gold: double taxes, Marek's gift): into the realm now and into its last dawn, so a
    /// watched video always pays, after a relaunch from the save and after "Replay the day" too.
    mutating func bankReward(gold: Int) {
        guard gold > 0 else { return }
        state.gold += gold
        dawnSnapshot.gold += gold
    }

    /// The action button: lights or patches. Returns true when it did something.
    @discardableResult
    mutating func perform(_ action: KingAction, events: inout [SimEvent]) -> Bool {
        switch action {
        case .light(let plot): return Sim.light(&state, plot: plot, balance: balance)
        case .patch(let plot): return Sim.patch(&state, plot: plot, balance: balance, events: &events)
        }
    }
}
