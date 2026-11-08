import CoreHaptics
import Foundation

// MARK: - Authored patterns

/// One authored vibration, as plain data: taps and rumbles on a timeline, and curves that shape the rumbles' strength. The
/// hub turns it into a Core Haptics pattern; keeping it data makes the patterns testable without a Taptic Engine (the
/// simulator has none) and short enough to read. Adapted from the starter kit.
struct HapticScore: Sendable, Equatable {
    struct Event: Sendable, Equatable {
        /// Seconds from the start of the pattern.
        var time: Double
        /// nil is a tap (a transient); otherwise a rumble of this length (a continuous event).
        var length: Double?
        /// 0…1, how strong.
        var intensity: Double
        /// 0…1, how crisp (low is a dull thud, high is a tick).
        var sharpness: Double

        static func tap(_ time: Double, _ intensity: Double, _ sharpness: Double) -> Event {
            Event(time: time, length: nil, intensity: intensity, sharpness: sharpness)
        }

        static func rumble(_ time: Double, _ length: Double, _ intensity: Double, _ sharpness: Double) -> Event {
            Event(time: time, length: length, intensity: intensity, sharpness: sharpness)
        }

        /// When the event is over.
        var end: Double { time + (length ?? 0.04) }
    }

    /// A multiplier (0…1) on the strength of everything playing, moving through `points` from `start`.
    struct Curve: Sendable, Equatable {
        struct Point: Sendable, Equatable {
            var time: Double
            var value: Double
        }
        var start: Double
        var points: [Point]
    }

    var events: [Event]
    var curves: [Curve] = []

    /// Seconds until the last event is over.
    var duration: Double { events.map(\.end).max() ?? 0 }
    /// Seconds of continuous vibration in all (the battery's measure: taps are almost free, a rumble is not).
    var rumbleTime: Double { events.compactMap(\.length).reduce(0, +) }

    /// The Core Haptics pattern. Throws if a value is out of range (the tests keep every score inside it).
    func pattern() throws -> CHHapticPattern {
        let hapticEvents = events.map { e -> CHHapticEvent in
            let parameters = [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: Float(e.intensity)),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: Float(e.sharpness)),
            ]
            if let length = e.length {
                return CHHapticEvent(eventType: .hapticContinuous, parameters: parameters, relativeTime: e.time, duration: length)
            }
            return CHHapticEvent(eventType: .hapticTransient, parameters: parameters, relativeTime: e.time)
        }
        let parameterCurves = curves.map { curve in
            CHHapticParameterCurve(parameterID: .hapticIntensityControl,
                                   controlPoints: curve.points.map { .init(relativeTime: $0.time, value: Float($0.value)) },
                                   relativeTime: curve.start)
        }
        return try CHHapticPattern(events: hapticEvents, parameterCurves: parameterCurves)
    }
}

/// The vibrations of the game, one per sound cue (`FeedbackCue` pairs them). They stand alone: a player with the sound
/// off still feels them.
enum HapticPattern: String, CaseIterable, Sendable {
    /// A firm kick and a low rumble that swells and fades with the ignition sound.
    case ignite
    /// The clunk (a heavy tap) and the pop (a crisp one) of a stage drop.
    case stageDrop
    /// A Perfect drop: a harder clunk, the pop, and a bright tick for the chime.
    case stageDropPerfect
    /// An Early or Late drop: one soft, dull tap.
    case stageDropSoft
    /// The latch's click and a faint breath of whoosh.
    case release
    /// A Perfect release: the click and two bright ticks for the chime.
    case releasePerfect
    /// A satellite lost: three taps falling away.
    case lost
    /// One tick of the total rolling up.
    case coinTick
    /// Coins: two light, crisp taps.
    case coin
    /// A ring complete: four rising taps with the arpeggio and a short swell.
    case ringComplete
    /// A new best: a fine shimmer of light ticks.
    case newBest
    /// A button.
    case button
    /// Nothing to drop: a dull bump.
    case refused

    var score: HapticScore {
        switch self {
        case .ignite:
            return HapticScore(
                events: [.tap(0, 1.0, 0.45), .rumble(0, 0.6, 0.8, 0.12)],
                curves: [.init(start: 0, points: [.init(time: 0, value: 0.6), .init(time: 0.08, value: 1),
                                                  .init(time: 0.6, value: 0)])]
            )
        case .stageDrop:
            return HapticScore(events: [.tap(0, 0.85, 0.35), .rumble(0, 0.07, 0.5, 0.15), .tap(0.05, 0.5, 0.8)])
        case .stageDropPerfect:
            return HapticScore(events: [.tap(0, 1.0, 0.4), .rumble(0, 0.08, 0.6, 0.15), .tap(0.05, 0.6, 0.85),
                                        .tap(0.08, 0.45, 1.0)])
        case .stageDropSoft:
            return HapticScore(events: [.tap(0, 0.5, 0.2)])
        case .release:
            return HapticScore(events: [.tap(0, 0.6, 0.85), .rumble(0.01, 0.14, 0.18, 0.5)],
                               curves: [.init(start: 0.01, points: [.init(time: 0, value: 1), .init(time: 0.14, value: 0)])])
        case .releasePerfect:
            return HapticScore(events: [.tap(0, 0.7, 0.85), .rumble(0.01, 0.12, 0.18, 0.5), .tap(0.08, 0.55, 1.0),
                                        .tap(0.14, 0.5, 1.0)])
        case .lost:
            return HapticScore(events: [.tap(0, 0.5, 0.3), .tap(0.1, 0.32, 0.25), .tap(0.2, 0.18, 0.2)])
        case .coinTick:
            return HapticScore(events: [.tap(0, 0.3, 0.95)])
        case .coin:
            return HapticScore(events: [.tap(0, 0.55, 0.9), .tap(0.075, 0.4, 0.95)])
        case .ringComplete:
            let notes = (0..<4).map { k in HapticScore.Event.tap(0.07 * Double(k), 0.5 + 0.12 * Double(k), 0.7 + 0.08 * Double(k)) }
            return HapticScore(events: notes + [.rumble(0.21, 0.25, 0.35, 0.3)],
                               curves: [.init(start: 0.21, points: [.init(time: 0, value: 1), .init(time: 0.25, value: 0)])])
        case .newBest:
            let ticks = (0..<10).map { k in HapticScore.Event.tap(0.07 * Double(k), 0.35 - 0.02 * Double(k), 1.0) }
            return HapticScore(events: ticks)
        case .button:
            return HapticScore(events: [.tap(0, 0.4, 0.6)])
        case .refused:
            return HapticScore(events: [.tap(0, 0.4, 0.15)])
        }
    }
}
