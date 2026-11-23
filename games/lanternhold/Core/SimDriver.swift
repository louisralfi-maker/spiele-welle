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
    /// render-2 (review of build 2): the accumulator starts at half a step and returns to it at every reset, so the
    /// display's 1/60 s frames land mid-step: a callback jitter under half a frame never gives a frame without a step or
    /// one with two (the walk and the scroll judder). Game time stays within half a step of real time.
    static let startPhase = step / 2

    var state: GameState
    let balance: Balance
    /// The reference bot playing live (`-GWAutoplay play`); nil while the player drives.
    var bot: Autoplay?
    /// `-GWAutoplay walk`.
    var walker: KingWalker?
    /// Where a tap on the realm strip sends the king (DESIGN.md "Controls"): he runs there and stops; nil when he does
    /// not travel. Any drag cancels it.
    var travelTarget: Double?
    /// Touch the world (stage lane, step stage-2): the pace of that walk (a walk, a hurry or a run); nil runs, as the
    /// realm strip always did.
    var travelSpeed: Double?
    /// Polish step A1: the lord's gait (the player's walk and what the picture needs of it); never saved.
    private(set) var gait = LordGait()
    /// Step A1b (a drag walks like a tap): the walk pad's pace while the finger is down (signed game px/s; nil when
    /// no drag walks him), the spot the brake brings him to once it lets go and that brake's pace, and the velocity the
    /// drag set in the last step (anyone else who changes it, an errand, a card, the called night, stops the drag's walk).
    /// Never saved.
    private(set) var dragPace: Double?
    private(set) var dragStop: Double?
    private var dragStopPace = 0.0
    private var dragDriven: Double?
    /// A card or the pause sheet is open (the UI sets it).
    var isPaused = false
    /// The app is not active.
    var isInBackground = false
    /// `-GWFreezeTime YES`: the clock stands still.
    var isFrozen = false
    private(set) var accumulator = SimDriver.startPhase
    /// Steps run so far.
    private(set) var steps = 0
    /// The realm at its last dawn (what the save writes).
    private(set) var dawnSnapshot: GameState
    /// The last three dawns (front lane hook, docs/lanes/front.md "front-2"): the fall wakes at one of them
    /// (`wake(back:)`); the save keeps them (`SaveGame.dawns`). A fall never overwrites them.
    private(set) var dawnRing: DawnRing
    /// The petitions (M3): the driver draws each day's petitioners (`PetitionEngine.prepare`) after every step.
    let petitions: PetitionCatalog

    init(state: GameState, balance: Balance = .standard, bot: Autoplay? = nil, dawnSnapshot: GameState? = nil,
         petitions: PetitionCatalog = .standard, dawnRing: DawnRing? = nil) {
        var start = state
        PetitionEngine.prepare(&start, catalog: petitions)
        var snapshot = dawnSnapshot ?? start
        PetitionEngine.prepare(&snapshot, catalog: petitions)
        self.state = start
        self.balance = balance
        self.bot = bot
        self.dawnSnapshot = snapshot
        self.petitions = petitions
        var ring = dawnRing ?? DawnRing()
        ring.record(snapshot, keep: balance.front.hearth.dawnsKept)
        self.dawnRing = ring
    }

    /// True while the simulation may step.
    var canStep: Bool { !isPaused && !isInBackground && !isFrozen && !state.defeated }

    /// Adds real seconds (at most `maxCatchUp` at once); while stepping is not allowed nothing is kept (the accumulator
    /// rests at `startPhase`).
    mutating func accumulate(_ seconds: Double) {
        guard canStep else {
            accumulator = SimDriver.startPhase
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
        // Polish step A1 (`LordGait`): the player's walk to a spot starts over 0.12 s, brakes over the last 4 px onto
        // the spot exactly, turns after a 0.07 s hold and changes pace over 0.25 s. Step A1b: the walk pad's drag the
        // same (`dragPace`), and let go it brakes onto `dragStop`. Only here: `Sim.stepKing` and the bots move as they
        // always did.
        if let driven = dragDriven, travelTarget == nil, state.king.velocity != driven {
            // Someone else stopped him (an errand at once, a card, the called night, a lit brazier): the drag's walk ends.
            dragPace = nil
            dragStop = nil
            gait.halt()
        }
        dragDriven = nil
        var landing: Double?
        var drives = false
        if let target = travelTarget ?? dragStop, bot == nil {
            let gap = target - state.king.x
            if state.king.lightingPlot >= 0 || gap == 0 || (gait.direction == 0 && abs(gap) < 0.5) {
                state.king.velocity = 0
                travelTarget = nil
                dragStop = nil
                gait.halt()
            } else {
                let pace = travelTarget != nil ? travelSpeed ?? balance.kingRunSpeed : dragStopPace
                let step = gait.travel(x: state.king.x, target: target, want: pace, current: state.king.velocity,
                                       dt: dt)
                state.king.velocity = step.velocity
                if let facing = step.facing { state.king.facing = facing }
                if step.lands { landing = target }
                drives = travelTarget == nil
            }
        } else if let want = dragPace, bot == nil, walker == nil {
            if state.king.lightingPlot >= 0 {
                state.king.velocity = 0
                gait.halt()
            } else {
                let step = gait.drive(want: want, current: state.king.velocity, dt: dt)
                state.king.velocity = step.velocity
                if let facing = step.facing { state.king.facing = facing }
                drives = true
            }
        } else {
            gait.halt()
        }
        if var player = bot {
            player.act(&state, dt: dt, balance: balance, events: &events, petitions: petitions)
            bot = player
        }
        let before = state.king.x
        Sim.step(&state, dt: dt, balance: balance, events: &events)
        var landed = false
        if let target = landing, abs(state.king.x - target) < 1e-6 {
            // On the spot exactly: he stands from this step on.
            state.king.x = target
            state.king.velocity = 0
            travelTarget = nil
            dragStop = nil
            gait.halt()
            landed = true
            drives = false
        }
        if drives { dragDriven = state.king.velocity }
        let spot = travelTarget ?? dragStop
        gait.note(moved: abs(state.king.x - before), dt: dt, left: spot.map { abs($0 - state.king.x) }, landed: landed)
        // b3-horde (build 3, lane 4 step A, step 4; one block for the join): the runner's clip of the horde holds the
        // night's clock and keeps its stream coming (`HordeProof.drive`, a `-GWHorde dark` launch of a Debug build only).
        #if DEBUG
        if HordeProof.probing { HordeProof.drive(&state, balance: balance) }
        #endif
        PetitionEngine.prepare(&state, catalog: petitions)
        steps += 1
        for event in events[first...] {
            if case .dawn = event {
                dawnSnapshot = state
                dawnRing.record(state, keep: balance.front.hearth.dawnsKept)
            }
        }
    }

    // LANE-E: E1 (the polish audit's thing 6; law 3.3: the dusk played in 4.0 s instead of a cut to 18:59)
    /// Where the played dusk's quick steps take the clock: a minute before the horn. The last minute the realm steps as
    /// ever, so the horn sounds by itself at 19:00 and the night begins exactly as a night that came by itself.
    static let hornCallHour = 19.0 - 1.0 / 60
    /// Law 3.3: the dusk played, from the call to the horn, in seconds of the driver's time.
    static let duskSeconds = 4.0
    /// The last minute before the horn at the day's own pace (0.2 s); the quick steps take the rest of the 4.0 s.
    static let duskLastMinute = (19.0 - hornCallHour) * DayClock.secondsPerHour

    /// A dusk being played (not saved): the day and the hour of the call, and the driver's seconds since.
    struct Dusk: Sendable, Equatable {
        var day: Int
        var fromHour: Double
        var elapsed = 0.0

        /// The clock's hour the dusk wants now: linear (law 1: the time of day is linear) from the call to the horn's
        /// minute over 4.0 s less the last minute.
        var targetHour: Double {
            let ramp = max(1e-9, SimDriver.duskSeconds - SimDriver.duskLastMinute)
            let share = min(1, max(0, elapsed / ramp))
            return fromHour + (SimDriver.hornCallHour - fromHour) * share
        }

        /// How far the dusk is (0 ... 1 of its 4.0 s).
        var share: Double { min(1, max(0, elapsed / SimDriver.duskSeconds)) }
    }

    /// The dusk being played since the call; nil when none.
    private(set) var dusk: Dusk?

    /// True while a dusk is being played on this day (a dusk of a day undone by a restart or a wake is not).
    var playsDusk: Bool {
        guard let played = dusk else { return false }
        return played.day == state.day && state.hour >= played.fromHour - 1e-6 && !state.defeated
            && DayClock.phase(at: state.hour) == .day && state.hour < 19
    }

    /// The player sounds the horn by day (Brannock's offer, the pause sheet): the dusk is played, not cut. From now
    /// on `playDusk` steps the realm on in its own 1/60 s steps, as many each frame as bring the clock to the horn's
    /// minute in 4.0 s (the sky, the lamps, the builders and the town's evening run as at any dusk); the last minute
    /// runs at the day's pace and the horn sounds by itself. The lord stops where he is (he may walk again). False when
    /// it is not day, the horn is a minute off, the realm fell, or a dusk is already played.
    @discardableResult
    mutating func callTheNight() -> Bool {
        guard !playsDusk, DayClock.phase(at: state.hour) == .day, state.hour < SimDriver.hornCallHour - 1e-6,
              !state.defeated else {
            return false
        }
        state.king.velocity = 0
        travelTarget = nil
        dusk = Dusk(day: state.day, fromHour: state.hour)
        return true
    }

    /// One frame of a played dusk (`GameModel.advanceGame`, after the frame's own steps): `seconds` of the driver's
    /// time pass for the dusk (at most `maxCatchUp`; none while the world is held), and the realm takes the extra 1/60 s
    /// steps that bring the clock to the dusk's hour, each the frame step's own work (the simulation, the petitions),
    /// with the lord's intent at rest during them, so he keeps his own pace. The dusk ends at the horn's minute's
    /// end, a new day, a fall or a jump in time. Returns the extra steps taken.
    @discardableResult
    mutating func playDusk(seconds: Double, events: inout [SimEvent]) -> Int {
        guard var played = dusk else { return 0 }
        guard playsDusk else {
            dusk = nil
            return 0
        }
        guard canStep else { return 0 }
        played.elapsed += min(max(0, seconds), SimDriver.maxCatchUp)
        dusk = played
        let target = played.targetHour
        let half = SimDriver.step / DayClock.secondsPerHour / 2
        let intent = state.king.velocity
        var taken = 0
        while state.hour + half < target && !state.defeated && taken < 4_000 {
            state.king.velocity = 0
            let first = events.count
            Sim.step(&state, dt: SimDriver.step, balance: balance, events: &events)
            #if DEBUG
            if HordeProof.probing { HordeProof.drive(&state, balance: balance) }
            #endif
            PetitionEngine.prepare(&state, catalog: petitions)
            steps += 1
            taken += 1
            for event in events[first...] {
                if case .dawn = event {
                    dawnSnapshot = state
                    dawnRing.record(state, keep: balance.front.hearth.dawnsKept)
                }
            }
        }
        state.king.velocity = intent
        return taken
    }
    // LANE-E end

    /// The walk pad's horizontal drag in points from where the finger went down (nil when it lifts): below the dead
    /// zone the king stands, beyond `runDistance` he runs (DESIGN.md "Controls": walk 36, run 80 game px/s). Any drag
    /// ends autoplay. Step A1b (Louis, 22.11.: a drag walks the lord): it walks him as a tap does, through his gait
    /// (the start over 0.12 s, walk to run over 0.25 s, a reversal as a turn with its 0.07 s hold), each step of the
    /// driver; let go (or back inside the dead zone) he brakes from where he is and comes to rest at most 4 px on.
    mutating func setDrag(offset: Double?, deadZone: Double = 6, runDistance: Double = 40) {
        guard let offset, abs(offset) >= deadZone else {
            if offset != nil {
                bot = nil
                walker = nil
                travelTarget = nil
            }
            letGo()
            return
        }
        bot = nil
        walker = nil
        travelTarget = nil
        dragStop = nil
        let speed = abs(offset) > runDistance ? balance.kingRunSpeed : balance.kingWalkSpeed
        dragPace = offset > 0 ? speed : -speed
    }

    /// The finger lets go of a walking drag: the brake from where he is, on to `dragStop` (4 px from his pace, less from
    /// a pace still ramping), exactly, with no creep; he stands at once when he was not walking.
    private mutating func letGo() {
        if isPaused && (dragPace != nil || dragStop != nil) {
            // The A1b gate (F1, P7): a card, the lantern, a slide, the table or the end card takes the finger while the
            // world stands still. The drag's walk ends there, as before A1b (the card covers that moment), so no brake
            // waits under the card and the raised lantern finds him standing.
            dragPace = nil
            dragStop = nil
            dragDriven = nil
            state.king.velocity = 0
            gait.halt()
            return
        }
        guard dragPace != nil else {
            // As before A1b (a card, a slide, the lantern lift the finger for him), unless the brake is under way.
            if bot == nil && walker == nil && dragStop == nil { state.king.velocity = 0 }
            return
        }
        dragPace = nil
        let distance = gait.brakeDistance
        if distance > 1e-9, gait.direction != 0, state.king.velocity * Double(gait.direction) > 0 {
            dragStop = min(Realm.walkEnd, max(0, state.king.x + Double(gait.direction) * distance))
            dragStopPace = gait.paceTo
        } else {
            dragStop = nil
            state.king.velocity = 0
            gait.halt()
        }
    }

    /// A new realm or a replayed one: no drag walks him.
    private mutating func clearDrag() {
        dragPace = nil
        dragStop = nil
        dragDriven = nil
    }

    /// What the action button offers now (at night: light a snuffed brazier, patch a damaged wall).
    var kingAction: KingAction? {
        Sim.kingAction(state, balance: balance)
    }

    /// A tap on the realm strip: the king runs to `x` (inside his walk) and stops there; autoplay ends.
    mutating func travel(to x: Double, speed: Double? = nil) {
        bot = nil
        walker = nil
        dragPace = nil
        dragStop = nil
        travelTarget = min(Realm.walkEnd, max(0, x))
        travelSpeed = speed
    }

    /// The defeat card's second chance (DESIGN.md "Losing a night"; the rewarded video comes in M7): the hearth flares
    /// up, every creature burns away and dawn comes at once. The new dawn is the snapshot the save writes.
    mutating func secondChance(events: inout [SimEvent]) {
        guard state.defeated else { return }
        guard Hearth.secondChanceOffered(state, balance: balance) else { return }  // front lane hook ("front-2")
        Sim.secondChance(&state, balance: balance, events: &events)
        PetitionEngine.prepare(&state, catalog: petitions)
        accumulator = SimDriver.startPhase
        dawnSnapshot = state
        dawnRing.record(state, keep: balance.front.hearth.dawnsKept)
    }

    /// The defeat card's "Replay the day": the realm as it was at this day's dawn.
    mutating func replayDay() {
        state = dawnSnapshot
        gait = LordGait()
        clearDrag()
        state.king.velocity = 0
        dawnSnapshot = state
        accumulator = SimDriver.startPhase
        travelTarget = nil
    }

    /// The pause sheet's "Restart chapter": a new realm on the morning of day 1, the player at the controls. The lord
    /// stays who he or she was until the name entry answers again.
    mutating func restart(seed: UInt64) {
        let lord = state.lord
        gait = LordGait()
        clearDrag()
        state = GameState.newRealm(seed: seed, balance: balance)
        state.lord = lord
        // Craft lane hook: a restarted chapter meets the travelling craftsmen too (build 3: `CraftVisits.open`).
        if CraftVisits.open { CraftVisits.begin(&state) }
        PetitionEngine.prepare(&state, catalog: petitions)
        dawnSnapshot = state
        dawnRing = DawnRing(state, keep: balance.front.hearth.dawnsKept)
        accumulator = SimDriver.startPhase
        bot = nil
        walker = nil
        travelTarget = nil
    }

    /// The name entry's answer (the lord pass): the lord of the realm now and of its last dawn, so the save has it
    /// at once and a replayed day keeps it.
    mutating func setLord(_ lord: LordIdentity) {
        state.lord = lord
        dawnSnapshot.lord = lord
        dawnRing.setLord(lord)
    }

    /// The fall card's "wake" (front lane hook, docs/lanes/front.md "front-2"; docs/REALM.md section 4): the realm as it
    /// was at the dawn `back` mornings before the newest kept one (0 is the newest, "this morning", which is what
    /// "Replay the day" does). That dawn and the older ones stay kept, the newer go. False (and nothing changes) when
    /// there is no such dawn.
    @discardableResult
    mutating func wake(back: Int) -> Bool {
        guard let dawn = dawnRing.wake(back: back) else { return false }
        state = dawn
        gait = LordGait()
        clearDrag()
        state.king.velocity = 0
        dawnSnapshot = state
        accumulator = SimDriver.startPhase
        travelTarget = nil
        return true
    }

    /// The ads (a rewarded video's gold: Marek's gift): into the realm now and into its last dawn, so a watched video
    /// always pays, after a relaunch from the save and after "Replay the day" too.
    mutating func bankReward(gold: Int) {
        guard gold > 0 else { return }
        state.gold += gold
        dawnSnapshot.gold += gold
    }

    /// The ads' "Double taxes" (the dawn report's video): the town's one flag for the day (`Town.grantDoubleTaxes`), now
    /// and in its last dawn, so a relaunch and "Replay the day" keep it. No gold moves here: the coins count twice at
    /// the doors. False when the town has no running day to double (after the horn, the first morning, done already).
    @discardableResult
    mutating func grantDoubleTaxes() -> Bool {
        let granted = Town.grantDoubleTaxes(&state)
        if granted { Town.grantDoubleTaxes(&dawnSnapshot) }
        return granted
    }

    /// The join (`CollectorTouch`): the collector's answer at his post (taken on, sent home, taken on again), now and in
    /// its last dawn, as the double taxes, so a relaunch and "Replay the day" keep it. Nil when nothing changed.
    @discardableResult
    mutating func answerCollector() -> CollectorWords? {
        let words = CollectorTouch.answer(&state)
        if words != nil, dawnSnapshot.town != nil {
            Town.setCollector(&dawnSnapshot, hired: Town.collectorHired(state))
        }
        return words
    }

    /// Panels lane (the chapter's end card, "Hold the realm"): the realm goes on in the Long Watch, now and in its last
    /// dawn, so the save counts it as endless at once.
    mutating func holdTheRealm() {
        state.mode = .endless
        dawnSnapshot.mode = .endless
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
