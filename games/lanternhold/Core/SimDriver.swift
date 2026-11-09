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

    init(state: GameState, balance: Balance = .standard, bot: Autoplay? = nil, dawnSnapshot: GameState? = nil) {
        self.state = state
        self.balance = balance
        self.bot = bot
        self.dawnSnapshot = dawnSnapshot ?? state
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
        if var player = bot {
            player.act(&state, dt: dt, balance: balance, events: &events)
            bot = player
        }
        Sim.step(&state, dt: dt, balance: balance, events: &events)
        steps += 1
        for event in events[first...] {
            if case .dawn = event {
                dawnSnapshot = state
            }
        }
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

    /// The action button: lights or patches. Returns true when it did something.
    @discardableResult
    mutating func perform(_ action: KingAction, events: inout [SimEvent]) -> Bool {
        switch action {
        case .light(let plot): return Sim.light(&state, plot: plot, balance: balance)
        case .patch(let plot): return Sim.patch(&state, plot: plot, balance: balance, events: &events)
        }
    }
}
