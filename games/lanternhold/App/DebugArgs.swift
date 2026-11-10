import Foundation

/// Launch arguments that let UI tests and screenshots reach any state (DESIGN.md "Debug launch arguments"): the
/// light-lab group (scene, clock, camera, pixel scale and effect experiments) and, from M2b, the game's starts
/// (`-GWDay`, `-GWNight`, `-GWBuild`, `-GWGold`, `-GWHappiness`, `-GWReset`). Values are plain parsed data; an unknown
/// or malformed value keeps the default.
struct DebugArgs: Sendable, Equatable {
    /// "world" (default: the game), "probe" (the M1b light probe: the scene as data, no simulation), "lightlab" or
    /// "testpattern".
    var scene = "world"
    /// Target game-pixel rows of the scale rule (180 by default, 135 for the chunkier look).
    var virtualHeight = 180
    /// Forces device pixels per game pixel.
    var scaleOverride: Int?

    /// `-GWTimeOfDay <0…1>`: clock position (0 midnight, 0.25 dawn, 0.5 noon, 0.8 dusk).
    var timeOfDay: Double?
    /// `-GWFreezeTime YES`: the clock stands still.
    var freezeTime = false
    /// `-GWFlickerTime <s>`: fixes flicker and idle animation at this simulation time.
    var flickerTime: Double?
    /// `-GWSeed <n>`: seed of the random stream.
    var seed: UInt64 = 1
    /// `-GWCameraX <px>`: camera focus; the king stands there.
    var cameraX: Double?
    /// `-GWAutoplay walk|play`.
    var autoplay: Autoplay?
    /// `-GWActorMode smooth|snapped`.
    var actorMode: ActorMode = .smooth
    /// `-GWLightStyle smooth|banded|dithered`.
    var lightStyle: LightStyle = .smooth
    /// `-GWEffects all|nobloom|nofog|minimal`.
    var effects: EffectLevel = .all
    /// `-GWShowLowRes YES`: the raw low-resolution image without the upscale.
    var showLowRes = false
    /// `-GWShowBuffer light|emissive|bloom|fog`.
    var showBuffer: DebugBuffer?
    /// `-GWDebugLights YES`: light radius rings and ids.
    var debugLights = false
    /// `-GWStats YES`: the stats overlay.
    var stats = false
    /// `-GWReduceMotion YES`: Reduce Motion without the system setting.
    var reduceMotion = false
    /// `-GWDay <n>`: the seeded headless reference bot plays a new realm to that day's morning, then hands over.
    var day: Int?
    /// `-GWNight <n>`: the same to that night's 20:00.
    var night: Int?
    /// `-GWBuild demo`: a built-up realm for screenshots.
    var build: BuildPreset?
    /// `-GWGold <n>`, `-GWHappiness <n>` (0 ... 100): set the numbers.
    var gold: Int?
    var happiness: Int?
    /// `-GWReset YES`: a fresh save.
    var reset = false
    /// `-GWTimeScale <x>` (0.25 ... 20, tests only): real time runs the game's simulation x times as fast.
    var timeScale = 1.0
    /// `-GWHour <h>` (0 ... 24): after the start (a day, a night, the save or a new realm, and the demo build), the
    /// reference bot plays on headless until the clock next shows this hour.
    var hour: Double?
    /// `-GWScreen title|audience|report|defeat|story|finale|petition`: opens that screen with sample data (M2b:
    /// report, defeat and finale, the dawn report of night 20 with the Lightless King slain; M3: petition, the herald
    /// of the Lightless King before the throne on day 17).
    var screen: Screen?
    /// `-GWClock <h>` (tests): the clock of the start state is set to this hour by day (6 ... 19) without anyone
    /// playing on, so today's petitioners still wait (`-GWHour` lets the reference bot play, and it hears them).
    var clock: Double?
    /// `-GWLook 1|2`: the look (1: the M1b to M3 picture; 2: "farbig-düster", docs/PORT-look2.md).
    var look: LookVersion = .standard
    /// `-GWCastle 1|1b|2|2b|3|3b` (look 2): the castle's tier as drawn, with "b" in its building state (SPRITES.md
    /// "The castle grows"). Drawing only; nothing in play raises it yet.
    var castle: CastleStage = .standard
    /// `-GWSkipOnboarding YES`: no hints (the onboarding comes in M7; accepted now so tests already pass it).
    var skipOnboarding = false

    /// `-GWBuild` presets.
    enum BuildPreset: String, Sendable, CaseIterable, Equatable {
        case demo
    }

    /// `-GWScreen` screens.
    enum Screen: String, Sendable, CaseIterable, Equatable {
        case title, audience, report, defeat, story, finale, petition
    }

    /// `-GWAutoplay` modes.
    enum Autoplay: String, Sendable, CaseIterable, Equatable {
        /// The king walks back and forth.
        case walk
        /// A bot plays whole days.
        case play
    }

    /// `-GWShowBuffer` views.
    enum DebugBuffer: String, Sendable, CaseIterable, Equatable {
        case light, emissive, bloom, fog
    }

    /// Every argument key (without the leading dash).
    static let keys = [
        "GWScene", "GWVirtualHeight", "GWScaleOverride", "GWTimeOfDay", "GWFreezeTime", "GWFlickerTime", "GWSeed",
        "GWCameraX", "GWAutoplay", "GWActorMode", "GWLightStyle", "GWEffects", "GWShowLowRes", "GWShowBuffer",
        "GWDebugLights", "GWStats", "GWReduceMotion", "GWDay", "GWNight", "GWBuild", "GWGold", "GWHappiness",
        "GWReset", "GWTimeScale", "GWHour", "GWScreen", "GWSkipOnboarding", "GWClock", "GWLook", "GWCastle",
    ]

    static func fromProcess() -> DebugArgs {
        let defaults = UserDefaults.standard
        var values: [String: String] = [:]
        for key in keys {
            if let value = defaults.string(forKey: key) {
                values[key] = value
            }
        }
        return DebugArgs(values: values)
    }

    /// Parses argument values by key (`"GWTimeOfDay": "0.95"`).
    init(values: [String: String]) {
        if let scene = values["GWScene"], !scene.isEmpty {
            self.scene = scene
        }
        if let virtualHeight = DebugArgs.int(values["GWVirtualHeight"]), virtualHeight > 0 {
            self.virtualHeight = virtualHeight
        }
        if let scaleOverride = DebugArgs.int(values["GWScaleOverride"]), scaleOverride > 0 {
            self.scaleOverride = scaleOverride
        }
        if let timeOfDay = DebugArgs.double(values["GWTimeOfDay"]) {
            self.timeOfDay = min(1, max(0, timeOfDay))
        }
        freezeTime = DebugArgs.bool(values["GWFreezeTime"])
        if let flickerTime = DebugArgs.double(values["GWFlickerTime"]), flickerTime >= 0 {
            self.flickerTime = flickerTime
        }
        if let text = values["GWSeed"], let seed = UInt64(text.trimmingCharacters(in: .whitespaces)) {
            self.seed = seed
        }
        if let cameraX = DebugArgs.double(values["GWCameraX"]) {
            self.cameraX = cameraX
        }
        autoplay = values["GWAutoplay"].flatMap { Autoplay(rawValue: $0.lowercased()) }
        if let mode = values["GWActorMode"].flatMap({ ActorMode(rawValue: $0.lowercased()) }) {
            actorMode = mode
        }
        if let style = values["GWLightStyle"].flatMap({ LightStyle(rawValue: $0.lowercased()) }) {
            lightStyle = style
        }
        if let level = values["GWEffects"].flatMap({ EffectLevel(rawValue: $0.lowercased()) }) {
            effects = level
        }
        showLowRes = DebugArgs.bool(values["GWShowLowRes"])
        showBuffer = values["GWShowBuffer"].flatMap { DebugBuffer(rawValue: $0.lowercased()) }
        debugLights = DebugArgs.bool(values["GWDebugLights"])
        stats = DebugArgs.bool(values["GWStats"])
        reduceMotion = DebugArgs.bool(values["GWReduceMotion"])
        if let day = DebugArgs.int(values["GWDay"]), day >= 1 {
            self.day = min(day, 999)
        }
        if let night = DebugArgs.int(values["GWNight"]), night >= 1 {
            self.night = min(night, 999)
        }
        build = values["GWBuild"].flatMap { BuildPreset(rawValue: $0.lowercased()) }
        if let gold = DebugArgs.int(values["GWGold"]), gold >= 0 {
            self.gold = gold
        }
        if let happiness = DebugArgs.int(values["GWHappiness"]) {
            self.happiness = min(100, max(0, happiness))
        }
        reset = DebugArgs.bool(values["GWReset"])
        if let scale = DebugArgs.double(values["GWTimeScale"]), scale > 0 {
            timeScale = min(20, max(0.25, scale))
        }
        if let hour = DebugArgs.double(values["GWHour"]), hour >= 0, hour <= 24 {
            self.hour = DayClock.wrap(hour)
        }
        screen = values["GWScreen"].flatMap { Screen(rawValue: $0.lowercased()) }
        skipOnboarding = DebugArgs.bool(values["GWSkipOnboarding"])
        if let look = DebugArgs.int(values["GWLook"]).flatMap({ LookVersion(rawValue: $0) }) {
            self.look = look
        }
        if let castle = values["GWCastle"].flatMap({ CastleStage(argument: $0) }) {
            self.castle = castle
        }
        if let clock = DebugArgs.double(values["GWClock"]), clock >= 6, clock < 19 {
            self.clock = clock
        }
    }

    init() {}

    /// The frame options these arguments ask for.
    var frameOptions: FrameOptions {
        FrameOptions(lightStyle: lightStyle, effects: effects, actorMode: actorMode, reduceMotion: reduceMotion,
                     virtualHeight: virtualHeight, scaleOverride: scaleOverride, flickerTime: flickerTime,
                     debugLights: debugLights, look: look)
    }

    private static func int(_ text: String?) -> Int? {
        guard let trimmed = text?.trimmingCharacters(in: .whitespaces), !trimmed.isEmpty else { return nil }
        if let value = Int(trimmed) { return value }
        if let value = Double(trimmed), value.isFinite, abs(value) < 1_000_000 { return Int(value) }
        return nil
    }

    private static func double(_ text: String?) -> Double? {
        guard let trimmed = text?.trimmingCharacters(in: .whitespaces), let value = Double(trimmed),
              value.isFinite else { return nil }
        return value
    }

    /// "YES", "true" and positive numbers are true, like `UserDefaults.bool(forKey:)`.
    private static func bool(_ text: String?) -> Bool {
        guard let trimmed = text?.trimmingCharacters(in: .whitespaces).lowercased(), !trimmed.isEmpty else {
            return false
        }
        if trimmed == "yes" || trimmed == "true" || trimmed == "y" || trimmed == "t" { return true }
        if let number = Double(trimmed) { return number > 0 }
        return false
    }
}
