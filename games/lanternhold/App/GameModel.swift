import Foundation
import Observation
import UIKit

/// What the probe's action button does: light or snuff the brazier in reach (the game's button offers a `KingTarget`).
enum BrazierAction: Sendable, Equatable {
    case light, snuff, patch
}

/// The driver of the screen (DESIGN.md "Code layout": `GameModel`, the save, the screen state, the sim driver). In the
/// game (`-GWScene world`, the default, M2b) it owns the simulation through `SimDriver` (a fixed 60 Hz step on an
/// accumulator; the day clock is the simulation's hour), draws it with `SceneFilter` and `EntityFrames` into the M1b
/// world, turns the simulation's events into visual effects, feedback cues, the horn banner, the screen shake, the
/// dawn report and the defeat card, and saves the dawn snapshot at every dawn and when the app goes to the background.
/// Navigation is a state machine here (DESIGN.md "Screens"): `overlay` is the card, report, defeat card or pause sheet
/// over the world, and while one is open the simulation does not step. The light probe (`-GWScene probe`) and the light
/// lab keep milestone 1's scene as data: its clock and walking king step on the same fixed step. The renderer asks for
/// one `FrameDesc` per drawn frame.
@MainActor
@Observable
final class GameModel {
    enum SceneKind: Sendable, Equatable {
        /// The game: the simulation drawn into the M1b world.
        case world
        /// The M1b light probe: the scene as placed for the shots, no simulation.
        case probe
        case lightLab
    }

    /// What covers the world (DESIGN.md "Screens"): the build card above a plot, the barracks' recruit card, the tax
    /// lectern at the throne, the dawn report, the defeat card, the pause sheet.
    enum Overlay: Sendable, Equatable {
        case build(plot: Int)
        case recruit
        case taxes
        case report(DawnReport)
        case defeat
        case pause
        /// M3: the audience at the throne or the gate (`GameModel+Court.swift`; the card is `audience`).
        case audience

        /// The three cards opened by the action button (they close with a tap beside them).
        var isCard: Bool {
            switch self {
            case .build, .recruit, .taxes: return true
            default: return false
            }
        }

        /// A whole screen over the stopped world (the dawn report, the defeat card, the pause sheet): the HUD's pause
        /// button goes too and the world draws at 20 fps (M2b review). The audience is no screen (M3): the hall lives
        /// on under its card (the walk up, the fades, the court breathing), and the pause sheet ends it.
        var isScreen: Bool {
            switch self {
            case .report, .defeat, .pause: return true
            case .build, .recruit, .taxes, .audience: return false
            }
        }
    }

    /// The defeat card's facts.
    struct DefeatInfo: Sendable, Equatable {
        var night: Int
        /// The night the second chance can be taken again; nil when it can be taken now.
        var secondChanceFrom: Int?
        /// "Replay the day" goes back to this day's dawn.
        var replayDay: Int
    }

    /// The fixed simulation step.
    static let step = 1.0 / 60.0
    /// Autoplay walks this far before it turns.
    static let autoplayLeg = 2400.0
    /// A brazier this close (game px) can be lit or snuffed.
    static let actionReach = 40.0
    /// Drag distances in points: below the dead zone the king stands, beyond the run distance he runs.
    static let dragDeadZone = 6.0
    static let runDistance = 40.0
    /// The probe's default clock position: just before dusk, so the first picture shows fire against the coming night.
    static let defaultTimeOfDay = 0.79
    /// At night at the front the game's camera aims this far left of the king, toward the Gloom (M2b).
    nonisolated static let nightLead = 60.0
    /// The horn banner shows this many real seconds.
    static let hornBannerSeconds = 3.6
    /// A second chance once per five nights in the chapter, once per ten in endless (DESIGN.md "Losing a night").
    static let secondChanceGap = 5
    static let secondChanceGapEndless = 10

    let args: DebugArgs
    let kind: SceneKind
    /// Reduce Motion: `-GWReduceMotion` or the system setting, followed while the game runs (M2b review: read once at
    /// launch, turning it on kept the shake, the camera lag and the card transitions until the next launch).
    private(set) var reduceMotion: Bool
    /// The probe's scene, and in the game the scene the filter starts from.
    @ObservationIgnored private(set) var scene: PlaceholderScene
    /// The probe's day clock; in the game only its running seconds count (flicker, fire, particles, banners).
    @ObservationIgnored private(set) var clock: DayClock
    @ObservationIgnored private(set) var camera: Camera?
    @ObservationIgnored private var accumulator = 0.0
    @ObservationIgnored private var dragOffset: Double?
    @ObservationIgnored private var autoplay: Bool
    @ObservationIgnored private var autoplayRange: ClosedRange<Double>
    @ObservationIgnored private var autoplayDirection: Int
    @ObservationIgnored private var steps = 0
    @ObservationIgnored private var renderedFrames = 0
    @ObservationIgnored private var smoothedInterval = 1.0 / 60.0
    @ObservationIgnored private var lastStatsTime = -1.0
    /// Thermal state `.serious`: the renderer drops bloom and one fog plane.
    @ObservationIgnored var reducedEffects = false

    // The game (kind == .world).
    @ObservationIgnored private(set) var driver: SimDriver?
    @ObservationIgnored private(set) var effects = BattleEffects()
    @ObservationIgnored private var store: SaveStore?
    @ObservationIgnored private var chronicle: Chronicle?
    @ObservationIgnored private var adPacing = AdPacing()
    @ObservationIgnored private var events: [SimEvent] = []
    @ObservationIgnored private var shake = ScreenShake()
    @ObservationIgnored private var thinner = FeedbackThinner()
    @ObservationIgnored private var hornUntil = 0.0
    /// The feedback hub (silent until M6).
    @ObservationIgnored var feedback: any FeedbackHub = SilentFeedback()
    /// Creature bodies in the last drawn frame (the scene value's `seen:`, so UI tests catch the fight in view).
    @ObservationIgnored private var seenCreatures = 0
    /// Archers drawing or loosing in the last drawn frame (the scene value's `aim:`).
    @ObservationIgnored private var aimingArchers = 0
    /// The game's view of the scene, kept while the beacon's site and the rooms' fades stay as they are (M2b review:
    /// filtered every frame, the whole prop list with its emitters, masks and lights was copied 60 times a second).
    @ObservationIgnored private var filteredScene: (built: Bool, rooms: CastleRooms.SceneKey, scene: PlaceholderScene)?
    /// Where first light's front stands on screen (0 ... 1), nil when it is not on screen (the scene value's `dawn:`).
    @ObservationIgnored private var dawnFront: Double?

    private(set) var day: Int
    private(set) var clockText: String
    /// The probe's action button.
    private(set) var action: BrazierAction?
    /// The game's action button: what is in front of the king (nil: the button hides).
    private(set) var target: KingTarget? = nil
    /// Why the button cannot act now (drawn greyed, with the missing gold or the cooldown), nil when it can.
    private(set) var targetHold: KingTargetHold? = nil
    /// At a plot: whether the hammer builds, upgrades or rebuilds (its caption says so).
    private(set) var targetVerb: KingTargets.BuildVerb? = nil
    private(set) var debugKingX = 0
    private(set) var debugCameraX = 0.0
    private(set) var statsText = ""
    /// The game's state for UI tests in the scene's accessibility value: "day:12 hour:21.50 alive:9 seen:4 shots:2
    /// kx:654" (creatures alive, creature bodies in the last frame, projectiles in flight, the king's x), with "dawn:0.42"
    /// while first light's front is on screen.
    private(set) var sceneStatus = ""

    // The HUD and the screens (the game).
    private(set) var overlay: Overlay? = nil
    /// Where the open card's place is on screen, 0 ... 1 of the width (the card stands above it).
    private(set) var cardAnchor = 0.5
    private(set) var gold = 0
    private(set) var happiness = 0
    /// Citizens, soldiers included (DESIGN.md "Economy": people), and how many of them are soldiers.
    private(set) var people = 0
    private(set) var soldiers = 0
    private(set) var strip: RealmStrip? = nil
    /// The horn banner shows the coming night's number while set.
    private(set) var hornNight: Int? = nil
    private(set) var settings = SaveSettings()
    /// Bumped by every action of the player, so the open card reads the realm again.
    private(set) var revision = 0

    // The court (M3 step 3, `GameModel+Court.swift`): the rooms cut away, the audience, talking.
    @ObservationIgnored var court = CourtScene(rooms: RoomFades(kingX: 0))
    @ObservationIgnored var talkLog = TalkLog()
    /// The last frame's pixel scale (the bubble's and the card's anchors).
    @ObservationIgnored var lastPixelScale: PixelScale?
    /// The audience card while it shows (nil while the petitioner walks up).
    var audience: AudienceCard? = nil
    /// A court member's line in a bubble over him.
    var talkBubble: TalkBubble? = nil
    /// Where the audience's speaker stands on screen (0 ... 1 of the width) and the top of the figures (0 ... 1 of
    /// the height): the card stands above them with its pointer down to the speaker.
    var stageAnchor = 0.45
    var figureTop = 0.7

    /// `store` is where the game's save lives (the app's own by default; the tests pass a temporary one, so they never
    /// touch the simulator app's real save).
    init(args: DebugArgs, kind: SceneKind, store saveStore: SaveStore? = SaveStore.standard()) {
        self.args = args
        self.kind = kind
        reduceMotion = args.reduceMotion || UIAccessibility.isReduceMotionEnabled
        var world = PlaceholderScene.world(seed: args.seed)
        var start = min(WorldLayout.walkEnd, max(0, args.cameraX ?? world.king.x))
        var dayClock: DayClock
        var loadedSettings = SaveSettings()
        if kind == .world {
            let store = saveStore
            if args.reset { store?.reset() }
            var saved: GameState?
            switch store?.read() {
            case .loaded(let save)?:
                saved = save.state
                chronicle = args.reset ? nil : save.chronicle
                loadedSettings = save.settings ?? SaveSettings()
                adPacing = save.adPacing ?? AdPacing()
            case .corrupt?:
                store?.keepCorrupt()
            case nil:
                break
            }
            let begin = GameStart.realm(args: args, saved: saved, balance: .standard)
            var simDriver = SimDriver(state: begin.state, balance: .standard,
                                      bot: args.autoplay == .play ? begin.bot : nil, dawnSnapshot: begin.dawn)
            if args.autoplay == .walk { simDriver.walker = KingWalker.around(begin.state.king.x) }
            simDriver.isFrozen = args.freezeTime
            driver = simDriver
            self.store = store
            start = begin.state.king.x
            dayClock = DayClock(hour: begin.state.hour, day: begin.state.day)
            dayClock.isFrozen = true
        } else {
            let fallback = kind == .lightLab ? 0.95 : GameModel.defaultTimeOfDay
            dayClock = DayClock(timeOfDay: args.timeOfDay ?? fallback)
            dayClock.isFrozen = args.freezeTime
        }
        world.king.x = start
        scene = world
        clock = dayClock
        court = CourtScene(rooms: RoomFades(kingX: start))
        autoplay = args.autoplay == .walk && kind == .probe
        if start + GameModel.autoplayLeg <= WorldLayout.walkEnd - 20 {
            autoplayRange = start...(start + GameModel.autoplayLeg)
            autoplayDirection = 1
        } else {
            autoplayRange = max(20, start - GameModel.autoplayLeg)...start
            autoplayDirection = -1
        }
        day = driver?.state.day ?? dayClock.day
        clockText = GameModel.format(hour: driver?.state.hour ?? dayClock.hour)
        action = nil
        settings = loadedSettings
        feedback.soundOn = settings.sound
        feedback.hapticsOn = settings.haptics
        applyScreen()
        refreshHUD()
    }

    /// The debug values (`debug-king-x`, `debug-camera-x`, the scene value's `king:` and `cam:`) show while the king
    /// walks for the jitter test (`-GWAutoplay walk`) or the stats run; the bot playing (`play`) keeps the picture clean.
    var showsDebugValues: Bool { args.autoplay == .walk || args.stats }
    var showsStats: Bool { args.stats }
    /// The reference bot plays for the screenshots (`-GWAutoplay play`): only the clock (and the screens) over the
    /// picture.
    var isShowcase: Bool { args.autoplay == .play }

    /// The frame options of the debug arguments, with the system's Reduce Motion.
    var options: FrameOptions {
        var options = args.frameOptions
        options.reduceMotion = reduceMotion
        return options
    }

    /// Flicker, idle and particle time: `-GWFlickerTime` fixes it, else the clock's running seconds.
    var animationTime: Double { args.flickerTime ?? clock.elapsed }

    var renderSettings: RenderSettings {
        RenderSettings(args: args, time: animationTime, reduceMotion: reduceMotion, reducedEffects: reducedEffects)
    }

    // MARK: - The game's pause rules

    /// A card, a screen or the pause sheet is open: the simulation does not step.
    var isPaused: Bool { driver?.isPaused ?? false }

    /// The app became active or left it: nothing steps in the background.
    func setActive(_ active: Bool) {
        driver?.isInBackground = !active
    }

    /// Writes the dawn snapshot now (the app goes to the background).
    func saveNow() {
        writeSave()
    }

    /// The app went to the background: the game comes back paused (unless a screen is already open).
    func pauseForBackground() {
        guard kind == .world, overlay == nil, !isShowcase, driver?.state.defeated == false else { return }
        setOverlay(.pause)
    }

    // MARK: - Simulation

    /// Runs whole fixed steps for `seconds` of real time (at most a quarter second at once, so a stall never
    /// fast-forwards the world).
    func advance(by seconds: Double) {
        guard seconds > 0 else { return }
        if kind == .world {
            advanceGame(by: min(seconds, 0.25))
            return
        }
        accumulator += min(seconds, 0.25)
        while accumulator >= GameModel.step {
            stepOnce()
            accumulator -= GameModel.step
        }
    }

    private func advanceGame(by seconds: Double) {
        guard var game = driver else { return }
        if !game.isInBackground {
            clock.advance(by: seconds)
        }
        events.removeAll(keepingCapacity: true)
        // `-GWTimeScale` (tests): more simulated time per real second; the driver still caps a frame's catch-up.
        game.accumulate(seconds * args.timeScale)
        let tracking = !game.state.creatures.isEmpty && DayClock.phase(at: game.state.hour) != .day
        let before = tracking ? game.state.creatures : []
        var stepped = 0
        var mark = 0
        while game.stepIfDue(events: &events) {
            stepped += 1
            if var follow = camera {
                follow.follow(targetX: game.state.king.x + GameModel.cameraLead(game.state),
                              targetVelocity: game.state.king.velocity, dt: GameModel.step, reduceMotion: reduceMotion)
                camera = follow
            }
            // The dawn's report and the defeat card stop the world in the step that brings them.
            if GameModel.opensScreen(events[mark...]) { break }
            mark = events.count
        }
        driver = game
        if !events.isEmpty {
            effects.note(events, state: game.state, balance: game.balance, time: animationTime)
            if tracking { dissolveSwept(before: before, state: game.state, balance: game.balance) }
            handle(events, state: game.state)
        }
        // Under a card the camera still settles on the king (the audience seats him on the throne).
        if stepped == 0, game.isPaused, var follow = camera {
            follow.follow(targetX: game.state.king.x + GameModel.cameraLead(game.state), targetVelocity: 0,
                          dt: seconds, reduceMotion: reduceMotion)
            camera = follow
        }
        stepCourt(seconds, state: game.state)
        effects.prune(time: animationTime)
        shake.prune(time: clock.elapsed)
        if hornNight != nil && clock.elapsed > hornUntil {
            hornNight = nil
        }
        if stepped > 0 {
            let before = steps
            steps += stepped
            if before / 6 != steps / 6 {
                refreshHUD()
            }
        }
    }

    /// True when one of the events opens a screen (the dawn report, the defeat card).
    nonisolated static func opensScreen(_ events: ArraySlice<SimEvent>) -> Bool {
        events.contains { event in
            switch event {
            case .dawn, .defeat: return true
            default: return false
            }
        }
    }

    /// The frame's events beyond the visual effects: the dawn's save and report, the defeat card, the horn banner, the
    /// screen shake and the feedback cues.
    private func handle(_ frameEvents: [SimEvent], state: GameState) {
        let time = clock.elapsed
        for event in frameEvents {
            switch event {
            case .dawn:
                writeSave()
                if let report = state.lastReport, overlay != .defeat {
                    setOverlay(.report(report))
                }
            case .defeat:
                setOverlay(.defeat)
            case .horn:
                if !isShowcase {
                    hornNight = state.nightNumber
                    hornUntil = time + GameModel.hornBannerSeconds
                }
            case .wallBroken(let plot):
                guard plot >= 0, plot < Realm.plots.count else { continue }
                shake.kick(ScreenShake.strength(ScreenShake.wallBreak, at: Realm.plots[plot].x,
                                                listenerX: state.king.x), at: time)
            case .stomp(let x):
                shake.kick(ScreenShake.strength(ScreenShake.stomp, at: x, listenerX: state.king.x), at: time)
            default:
                break
            }
        }
        for cue in thinner.cues(for: frameEvents, time: time, listenerX: state.king.x) {
            feedback.play(cue)
        }
    }

    /// Creatures that vanished without a kill this frame (swept away at first light, receding with the Gloom when the
    /// Lightless King fell, gone at dawn) dissolve in a puff of soot like any other (DESIGN.md "Feel").
    private func dissolveSwept(before: [Creature], state: GameState, balance: Balance) {
        var swept = DayClock.phase(at: state.hour) == .firstLight
        var kills: [(kind: CreatureKind, x: Double)] = []
        for event in events {
            switch event {
            case .gloomRecedes, .dawn: swept = true
            case .creatureKilled(let kind, let x): kills.append((kind, x))
            default: break
            }
        }
        guard swept else { return }
        var alive = Set<Int>()
        for c in state.creatures { alive.insert(c.id) }
        var puffs: [SimEvent] = []
        for c in before where !alive.contains(c.id) {
            if let match = kills.firstIndex(where: { $0.kind == c.kind && abs($0.x - c.x) < 24 }) {
                kills.remove(at: match)
                continue
            }
            puffs.append(.creatureKilled(kind: c.kind, x: c.x))
        }
        if !puffs.isEmpty {
            effects.note(puffs, state: state, balance: balance, time: animationTime)
        }
    }

    private func stepOnce() {
        let dt = GameModel.step
        clock.advance(by: dt)
        if kind == .probe {
            scene.king.velocity = kingVelocity()
            scene.king.step(dt: dt)
            if var follow = camera {
                follow.follow(targetX: scene.king.x, targetVelocity: scene.king.velocity, dt: dt,
                              reduceMotion: reduceMotion)
                camera = follow
            }
        }
        steps += 1
        if steps % 6 == 0 {
            refreshHUD()
        }
    }

    /// The probe's king: the drag wins; else autoplay walks back and forth; else he stands.
    private func kingVelocity() -> Double {
        if let drag = dragOffset {
            let distance = abs(drag)
            guard distance >= GameModel.dragDeadZone else { return 0 }
            let speed = distance > GameModel.runDistance ? KingState.runSpeed : KingState.walkSpeed
            return drag > 0 ? speed : -speed
        }
        guard autoplay else { return 0 }
        let x = scene.king.x
        if autoplayDirection > 0 && x >= autoplayRange.upperBound {
            autoplayDirection = -1
        } else if autoplayDirection < 0 && x <= autoplayRange.lowerBound {
            autoplayDirection = 1
        }
        return Double(autoplayDirection) * KingState.walkSpeed
    }

    // MARK: - Input

    /// The walk pad's horizontal drag in points from where the finger went down; nil when it lifts. Any drag ends
    /// autoplay and a walk the realm strip started. In the game it sets the simulation's king intent.
    func setDrag(offset: Double?) {
        if kind == .world {
            guard overlay == nil else { return }
            driver?.setDrag(offset: offset, deadZone: GameModel.dragDeadZone, runDistance: GameModel.runDistance)
            return
        }
        dragOffset = offset
        if offset != nil {
            autoplay = false
        }
    }

    /// The action button: in the probe it lights or snuffs the brazier in reach; in the game it opens the card of
    /// what is in front of the king (a plot's build card, the barracks, the tax lectern) or, from the horn to dawn,
    /// lights a snuffed brazier or patches a damaged wall.
    func performAction() {
        switch kind {
        case .world:
            guard let target, var game = driver, overlay == nil else { return }
            switch target {
            case .build(let plot):
                let anchor = KingTargets.anchorX(target, state: game.state, balance: game.balance)
                openCard(.build(plot: plot), anchorX: anchor)
            case .recruit:
                openCard(.recruit, anchorX: KingTargets.barracksX)
            case .throne:
                // M3: the crown opens the audience while petitioners wait in the hall, else the tax card.
                if AudienceRules.hall(game.state, catalog: .standard).isEmpty {
                    openCard(.taxes, anchorX: KingTargets.throneX)
                } else {
                    openAudience(.throne)
                }
            case .lectern:
                openCard(.taxes, anchorX: KingTargets.lecternX)
            case .stranger:
                openAudience(.gate)
            case .talk(let who):
                talk(to: who)
            case .light(let plot), .patch(let plot):
                let action: KingAction = {
                    if case .light = target { return .light(plot: plot) }
                    return .patch(plot: plot)
                }()
                var actionEvents: [SimEvent] = []
                let done = game.perform(action, events: &actionEvents)
                driver = game
                if !actionEvents.isEmpty {
                    effects.note(actionEvents, state: game.state, balance: game.balance, time: animationTime)
                    handle(actionEvents, state: game.state)
                }
                if !done { feedback.play(.refused) }
                refreshHUD()
            }
        case .probe:
            scene.toggleBrazier(near: scene.king.x, reach: GameModel.actionReach)
            refreshAction()
        case .lightLab:
            break
        }
    }

    /// A tap on the realm strip at `fraction` of its width: the king runs there (DESIGN.md "Controls").
    func travel(toFraction fraction: Double) {
        guard kind == .world, overlay == nil, driver != nil else { return }
        driver?.travel(to: RealmStrip.worldX(fraction: fraction))
        refreshHUD()
    }

    // MARK: - The screens (DESIGN.md "Screens")

    func setOverlay(_ next: Overlay?) {
        if next != nil && next != .audience { closeTalk() }
        if overlay != next { overlay = next }
        driver?.isPaused = next != nil
        if next != nil { driver?.setDrag(offset: nil) }
        refreshHUD()
    }

    private func openCard(_ card: Overlay, anchorX: Double) {
        // Acting at a place ends a walk the realm strip started.
        driver?.travelTarget = nil
        if let view = camera {
            cardAnchor = min(1, max(0, (anchorX - view.x) / max(1, view.viewWidth)))
        }
        feedback.play(.cardOpened)
        setOverlay(card)
    }

    /// Changes the realm through the simulation's driver (the court's actions, `GameModel+Court.swift`).
    @discardableResult
    func withDriver<T>(_ body: (inout SimDriver) -> T) -> T? {
        guard var game = driver else { return nil }
        let result = body(&game)
        driver = game
        return result
    }

    /// Closes a card (the close button, a tap beside it).
    func closeCard() {
        guard overlay?.isCard == true else { return }
        feedback.play(.cardClosed)
        setOverlay(nil)
    }

    /// The build card of the plot that is open.
    var buildCard: BuildCard? {
        guard case .build(let plot)? = overlay, let game = driver else { return nil }
        _ = revision
        let reachable = KingTargets.buildPlots(game.state, balance: game.balance, near: game.state.king.x)
        return BuildCard.make(game.state, plot: plot, balance: game.balance, reachable: reachable)
    }

    /// The build card's arrows: another plot in reach.
    func showPlot(_ plot: Int) {
        guard case .build? = overlay, let game = driver, plot >= 0, plot < Realm.plots.count else { return }
        let x = KingTargets.spotX(plot: plot, layouts: KingTargets.layouts(game.state, balance: game.balance))
        openCard(.build(plot: plot), anchorX: x)
    }

    /// Orders `item` on the open card's plot through the simulation; the card closes when the order stands.
    func order(_ item: BuildItem) {
        guard case .build(let plot)? = overlay, var game = driver else { return }
        var orderEvents: [SimEvent] = []
        let result = Build.order(&game.state, plot: plot, item: item, balance: game.balance, events: &orderEvents)
        driver = game
        revision += 1
        if result == .ordered {
            handle(orderEvents, state: game.state)
            setOverlay(nil)
        } else {
            feedback.play(.refused)
            refreshHUD()
        }
    }

    var recruitCard: RecruitCard? {
        guard overlay == .recruit, let game = driver else { return nil }
        _ = revision
        return RecruitCard.make(game.state, balance: game.balance)
    }

    /// Recruits a soldier at the barracks; the card stays open for the next one.
    func recruit(_ kind: SoldierKind) {
        guard overlay == .recruit, var game = driver else { return }
        var recruitEvents: [SimEvent] = []
        let done = Build.recruit(&game.state, kind: kind, balance: game.balance, events: &recruitEvents)
        driver = game
        revision += 1
        if done { handle(recruitEvents, state: game.state) } else { feedback.play(.refused) }
        refreshHUD()
    }

    var taxCard: TaxCard? {
        guard overlay == .taxes, let game = driver else { return nil }
        _ = revision
        return TaxCard.make(game.state, balance: game.balance)
    }

    /// Sets the tax at the lectern (the war tax once it is unlocked).
    func setTax(_ rate: TaxRate) {
        guard overlay == .taxes, var game = driver else { return }
        let done = Economy.setTax(&game.state, rate)
        driver = game
        revision += 1
        feedback.play(done ? .taxSet : .refused)
        refreshHUD()
    }

    var reportCard: ReportCard? {
        guard case .report(let report)? = overlay else { return nil }
        return ReportCard.make(report, flags: driver?.state.flags ?? [])
    }

    /// The dawn report's Continue: the day begins.
    func continueReport() {
        guard case .report(let report)? = overlay else { return }
        let delta = report.happinessAfter - report.happinessBefore
        if delta > 0 { feedback.play(.happinessUp) }
        if delta < 0 { feedback.play(.happinessDown) }
        setOverlay(nil)
    }

    var defeatInfo: DefeatInfo? {
        guard overlay == .defeat, let game = driver else { return nil }
        let night = max(1, game.state.night.night > 0 ? game.state.night.night : game.state.nightNumber)
        return DefeatInfo(night: night, secondChanceFrom: secondChanceFrom(night: night, mode: game.state.mode),
                          replayDay: game.dawnSnapshot.day)
    }

    /// The night from which the second chance can be taken again, nil when now.
    private func secondChanceFrom(night: Int, mode: GameMode) -> Int? {
        let last = adPacing.lastSecondChanceNight
        guard last > 0 else { return nil }
        let gap = mode == .endless ? GameModel.secondChanceGapEndless : GameModel.secondChanceGap
        return night - last >= gap ? nil : last + gap
    }

    /// The defeat card's second chance (a placeholder for the rewarded video of M7): the hearth flares up, the
    /// creatures burn away, dawn comes at once and its report follows.
    func takeSecondChance() {
        guard let info = defeatInfo, info.secondChanceFrom == nil, var game = driver else { return }
        var chanceEvents: [SimEvent] = []
        game.secondChance(events: &chanceEvents)
        driver = game
        adPacing.lastSecondChanceNight = info.night
        restartView(game.state)
        overlay = nil
        effects.note(chanceEvents, state: game.state, balance: game.balance, time: animationTime)
        handle(chanceEvents, state: game.state)
        if overlay == nil { setOverlay(nil) }
    }

    /// The defeat card's "Replay the day": back to this day's dawn.
    func replayDay() {
        guard overlay == .defeat, var game = driver else { return }
        game.replayDay()
        driver = game
        restartView(game.state)
        setOverlay(nil)
    }

    func openPause() {
        guard kind == .world, overlay == nil || overlay?.isCard == true || overlay == .audience else { return }
        if overlay == .audience { leaveAudience(feedbackCue: false) }
        setOverlay(.pause)
    }

    func resume() {
        guard overlay == .pause else { return }
        setOverlay(nil)
    }

    /// The pause sheet offers "Sound the horn" by day while the player drives (not under the reference bot).
    var canCallTheNight: Bool {
        guard kind == .world, let game = driver, game.bot == nil, !game.state.defeated else { return false }
        return DayClock.phase(at: game.state.hour) == .day && game.state.hour < SimDriver.hornCallHour - 1e-6
    }

    /// The petitioners still waiting today, the Stranger at the gate included: the horn's confirmation says they go
    /// home unheard (M3 fix, C2: calling the night early cost happiness without a word).
    var petitionersWaiting: Int {
        guard let state = driver?.state, let court = state.court, court.queueDay == state.day else { return 0 }
        return court.queue.count
    }

    /// The pause sheet's "Sound the horn" (after its confirmation): the day plays on to 18:59 at once and the horn
    /// sounds a moment after the sheet closes.
    func callTheNight() {
        guard overlay == .pause, canCallTheNight, var game = driver else { return }
        game.callTheNight()
        driver = game
        revision += 1
        setOverlay(nil)
        refreshHUD()
    }

    /// The system's Reduce Motion changed (GameView follows `accessibilityReduceMotion`).
    func setSystemReduceMotion(_ on: Bool) {
        let value = args.reduceMotion || on
        if value != reduceMotion { reduceMotion = value }
    }

    func setSound(_ on: Bool) {
        settings.sound = on
        feedback.soundOn = on
        writeSave()
    }

    func setHaptics(_ on: Bool) {
        settings.haptics = on
        feedback.hapticsOn = on
        writeSave()
    }

    /// The pause sheet's "Restart chapter" (after its confirmation): a new realm on day 1; the Chronicle stays.
    func restartChapter() {
        guard overlay == .pause, var game = driver else { return }
        let seed = SeededRandom.mix(game.state.seed &+ 0x9E37_79B9_7F4A_7C15 &* UInt64(max(1, game.state.day)))
        game.restart(seed: seed)
        driver = game
        // The new realm starts with fresh ad pacing (M2b review: only the second chance's night was reset, so the old
        // realm's double-taxes and interstitial days would have held the new one back).
        adPacing = AdPacing()
        restartView(game.state)
        writeSave()
        setOverlay(nil)
    }

    /// After a jump in time or place: the camera cuts to the king, effects and shakes end, and the court starts
    /// afresh (M3 fix, C4: a replayed day kept the bubble, who had been talked to, the walkers on their way out and
    /// the smoothed places of the day that was undone).
    private func restartView(_ state: GameState) {
        camera?.jump(toFocus: state.king.x + GameModel.cameraLead(state))
        effects = BattleEffects()
        shake = ScreenShake()
        hornNight = nil
        closeTalk()
        talkLog = TalkLog()
        audience = nil
        court = CourtScene(rooms: RoomFades(kingX: state.king.x))
    }

    /// `-GWScreen report|finale|defeat`: that screen with sample data over the realm the other arguments made.
    private func applyScreen() {
        guard kind == .world, var game = driver else { return }
        switch args.screen {
        case .report?:
            setOverlay(.report(ReportCard.sampleReport()))
        case .finale?:
            // The sample's dawn quotes a speech (M3 fix, U1): the first one unless the realm brought its own.
            if Remembered.speechKey(flags: game.state.flags) == nil {
                game.state.flags.append(Remembered.speeches[0])
                game.state.flags.sort()
                driver = game
            }
            setOverlay(.report(ReportCard.sampleFinale()))
        case .petition?:
            openPetitionSample()
        case .defeat?:
            if DayClock.phase(at: game.state.hour) == .day {
                game.state.hour = 2.5
                game.state.night.night = game.state.nightNumber
            }
            game.state.hearth = 0
            game.state.defeated = true
            game.state.night.defeatHour = game.state.hour
            driver = game
            setOverlay(.defeat)
        default:
            break
        }
    }

    // MARK: - Frames

    /// The frame to draw on a screen of this physical size.
    func frame(physicalWidth: Int, physicalHeight: Int) -> FrameDesc {
        let options = self.options
        let pixelScale = options.pixelScale(physicalWidth: physicalWidth, physicalHeight: physicalHeight)
        let frame: FrameDesc
        switch kind {
        case .lightLab:
            return LightLabScene.frame(clock: clock, pixelScale: pixelScale, options: options, animTime: animationTime)
        case .probe:
            let view = ensureCamera(pixelScale, focus: scene.king.x)
            frame = FrameBuilder.build(scene: scene, clock: clock, camera: view, pixelScale: pixelScale,
                                       options: options)
        case .world:
            guard let game = driver else {
                let view = ensureCamera(pixelScale, focus: scene.king.x)
                return FrameBuilder.build(scene: scene, clock: clock, camera: view, pixelScale: pixelScale,
                                          options: options)
            }
            let state = game.state
            var view = ensureCamera(pixelScale, focus: state.king.x + GameModel.cameraLead(state))
            let sway = shake.offset(at: clock.elapsed, reduceMotion: reduceMotion)
            if sway != 0 {
                view.jump(toFocus: view.focusX + sway)
            }
            // The filtered scene is kept while the beacon's site and the rooms stay as they are (M2b review), and
            // drawn with the rooms cut away as they stand (M3, `CastleRooms.scene`).
            let built = SceneFilter.beaconBuilt(state)
            let rooms = CastleRooms.sceneKey(state: state, rooms: court.rooms)
            var filtered: PlaceholderScene
            if let cached = filteredScene, cached.built == built, cached.rooms == rooms {
                filtered = cached.scene
                filtered.king = KingState(x: state.king.x, facing: state.king.facing, velocity: state.king.velocity)
                filtered.bankRestingEdge = state.bankEdge
                filtered.bankNightEdge = state.bankEdge
            } else {
                filtered = CastleRooms.scene(SceneFilter.gameScene(scene, state: state), state: state,
                                             rooms: court.rooms)
                filteredScene = (built: built, rooms: rooms, scene: filtered)
            }
            var layer = EntityFrames.layer(state: state, balance: game.balance, scene: filtered, camera: view,
                                           pixelScale: pixelScale, options: options, animTime: animationTime,
                                           effects: effects)
            // M3: the court, the rooms cut away, the castle's world changes (`CourtFrames`).
            CourtFrames.apply(&layer, state: state, catalog: .standard, scene: court,
                              view: EntityFrames.ActorView(camera: view, pixelScale: pixelScale,
                                                           mode: options.actorMode),
                              ambient: AmbientRamp.sample(at: state.hour, look: options.look), animTime: animationTime,
                              reduceMotion: reduceMotion)
            noteCourtFrame(camera: view, pixelScale: pixelScale)
            for light in DawnSweep.lights(hour: state.hour) {
                layer.lights.append((source: light, plane: .world))
            }
            dawnFront = DawnSweep.screenFraction(hour: state.hour, cameraX: view.x, viewWidth: view.viewWidth)
            var frameClock = DayClock(hour: state.hour, day: state.day)
            frameClock.isFrozen = true
            frameClock.advance(by: clock.elapsed)
            frame = FrameBuilder.build(scene: filtered, clock: frameClock, camera: view, pixelScale: pixelScale,
                                       options: options, entities: layer)
            var seen = 0
            var aiming = 0
            for actor in frame.actors {
                if actor.sprite == .archer {
                    if actor.frame >= 2 { aiming += 1 }
                } else if !actor.isEmissive && actor.sprite != .king && EntityFrames.glowStrip(actor.sprite) != nil {
                    seen += 1
                }
            }
            seenCreatures = seen
            aimingArchers = aiming
        }
        renderedFrames += 1
        if renderedFrames % 6 == 1 {
            publishDebug(frame)
            if kind == .world { refreshGameStatus() }
        }
        return frame
    }

    /// Where the game's camera aims relative to the king: at night in front of the castle, `nightLead` toward the
    /// Gloom, so the approach and its eyes show; eased in through the dusk, out through first light, and faded out
    /// as the king walks into the castle front.
    nonisolated static func cameraLead(_ state: GameState) -> Double {
        let hour = state.hour
        var night = 0.0
        if hour >= 19 && hour < 20 {
            night = hour - 19
        } else if hour >= 20 || hour < 5 {
            night = 1
        } else if hour >= 5 && hour < 6 {
            night = 6 - hour
        }
        let front = min(1, max(0, (WorldLayout.castleFrontX + 60 - state.king.x) / 120))
        return -nightLead * night * front
    }

    private func ensureCamera(_ pixelScale: PixelScale, focus: Double) -> Camera {
        if let camera, camera.viewWidth == pixelScale.visibleColumns {
            return camera
        }
        let made = Camera(focusX: focus, pixelScale: pixelScale)
        camera = made
        return made
    }

    private func publishDebug(_ frame: FrameDesc) {
        guard showsDebugValues else { return }
        if frame.kingScreenX != debugKingX {
            debugKingX = frame.kingScreenX
        }
        let cameraX = (frame.cameraX * 100).rounded() / 100
        if cameraX != debugCameraX {
            debugCameraX = cameraX
        }
    }

    /// After each drawn frame: the smoothed frame rate and, with `-GWStats`, the overlay text twice a second.
    func noteRendered(_ stats: RenderStats, interval: Double, frame: FrameDesc) {
        guard args.stats else { return }
        if interval > 0 && interval < 1 {
            smoothedInterval = smoothedInterval * 0.9 + interval * 0.1
        }
        let now = clock.elapsed
        guard now - lastStatsTime >= 0.5 else { return }
        lastStatsTime = now
        let fps = smoothedInterval > 0 ? 1 / smoothedInterval : 0
        let cpu = String(format: "%.2f", stats.cpuMilliseconds)
        let gpu = String(format: "%.2f", stats.gpuMilliseconds)
        let rate = String(format: "%.0f", fps)
        let thermal = GameModel.thermalName(ProcessInfo.processInfo.thermalState)
        let size = "\(frame.targetWidth)x\(frame.targetHeight)"
        statsText = "cpu \(cpu) ms  gpu \(gpu) ms  \(rate) fps  s \(frame.scale)  \(size)  \(thermal)\n"
            + "instances \(stats.instances)  lights \(stats.lights)  draws \(stats.drawCalls)  passes \(stats.passes)"
    }

    static func thermalName(_ state: ProcessInfo.ThermalState) -> String {
        switch state {
        case .nominal: return "nominal"
        case .fair: return "fair"
        case .serious: return "serious"
        case .critical: return "critical"
        @unknown default: return "unknown"
        }
    }

    // MARK: - Saving

    /// The save of the last dawn: written at every dawn, when the app goes to the background and when a setting
    /// changes; the Chronicle counts each dawn once. Settings and ad pacing travel with it.
    private func writeSave() {
        guard kind == .world, let store, let game = driver else { return }
        var save = SaveGame(state: game.dawnSnapshot, chronicle: chronicle, settings: settings, adPacing: adPacing)
        save.countDawn()
        chronicle = save.chronicle
        try? store.write(save)
    }

    // MARK: - HUD

    func refreshHUD() {
        let currentDay = driver?.state.day ?? clock.day
        if currentDay != day {
            day = currentDay
        }
        let text = GameModel.format(hour: driver?.state.hour ?? clock.hour)
        if text != clockText {
            clockText = text
        }
        if let game = driver {
            let s = game.state
            if s.gold != gold { gold = s.gold }
            if s.happiness != happiness { happiness = s.happiness }
            if s.citizens != people { people = s.citizens }
            if s.soldiers.count != soldiers { soldiers = s.soldiers.count }
            let window = camera.map { RealmStrip.window(cameraX: $0.x, viewWidth: $0.viewWidth) }
            let next = RealmStrip.make(s, balance: game.balance, travelTarget: game.travelTarget, window: window)
            if next != strip { strip = next }
            refreshCourt(s)
        }
        refreshAction()
        refreshGameStatus()
    }

    private func refreshAction() {
        switch kind {
        case .world:
            var next: KingTarget?
            var hold: KingTargetHold?
            var verb: KingTargets.BuildVerb?
            if let game = driver, overlay == nil, game.bot == nil {
                next = KingTargets.target(game.state, balance: game.balance)
                hold = next.flatMap { KingTargets.hold($0, state: game.state, balance: game.balance) }
                if case .build(let plot)? = next { verb = KingTargets.verb(game.state, plot: plot) }
            }
            if next != target { target = next }
            if hold != targetHold { targetHold = hold }
            if verb != targetVerb { targetVerb = verb }
        case .probe:
            var next: BrazierAction?
            var best = GameModel.actionReach
            for prop in scene.braziers {
                let centre = prop.x + Double(prop.width) / 2
                let distance = abs(centre - scene.king.x)
                if distance <= best {
                    best = distance
                    next = prop.isLit ? .snuff : .light
                }
            }
            if next != action { action = next }
        case .lightLab:
            if action != nil { action = nil }
        }
    }

    private func refreshGameStatus() {
        guard let game = driver else { return }
        let state = game.state
        var text = "day:\(state.day) hour:\(String(format: "%.2f", state.hour)) alive:\(state.creatures.count) "
            + "seen:\(seenCreatures) shots:\(state.projectiles.count) aim:\(aimingArchers) "
            + "kx:\(Int(state.king.x.rounded()))"
        if let front = dawnFront {
            text += " dawn:\(String(format: "%.2f", front))"
        }
        if text != sceneStatus {
            sceneStatus = text
        }
    }

    /// "HH:MM" of an hour 0 ..< 24.
    static func format(hour: Double) -> String {
        let minutes = Int((hour * 60).rounded(.down)) % (24 * 60)
        let safe = max(0, minutes)
        return String(format: "%02d:%02d", safe / 60, safe % 60)
    }
}
