import Foundation

/// Everything the player hears and feels goes through here: one call plays a moment's synthesised sound (`AudioHub`,
/// behind the sound switch, muted by the ring/silent switch) and its authored vibration (`HapticHub`, behind the haptics
/// switch). No audio files, no music, ever.
enum FeedbackCue: Sendable, Equatable {
    case ignite
    case stageDrop(DropRating)
    case release(ReleaseRating)
    case lost
    /// Coins spent or collected.
    case coin
    /// One tick of a total rolling up.
    case coinTick
    case ringComplete
    case newBest
    case button
    /// A drop tap on the last stage.
    case refused

    /// The sound of the moment.
    var sound: SoundCue {
        switch self {
        case .ignite: return .ignite
        case .stageDrop(let rating): return rating == .perfect ? .stageDropPerfect : .stageDrop
        case .release(let rating):
            switch rating {
            case .perfect: return .releasePerfect
            case .great, .good: return .release
            case .lost: return .lost
            }
        case .lost: return .lost
        case .coin: return .coin
        case .coinTick: return .coinTick
        case .ringComplete: return .ringComplete
        case .newBest: return .newBest
        case .button: return .button
        case .refused: return .refused
        }
    }

    /// The vibration that goes with it (the same beat in the hand).
    var haptic: HapticPattern {
        switch self {
        case .ignite: return .ignite
        case .stageDrop(let rating):
            switch rating {
            case .perfect: return .stageDropPerfect
            case .great, .good: return .stageDrop
            case .early, .late: return .stageDropSoft
            }
        case .release(let rating):
            switch rating {
            case .perfect: return .releasePerfect
            case .great, .good: return .release
            case .lost: return .lost
            }
        case .lost: return .lost
        case .coin: return .coin
        case .coinTick: return .coinTick
        case .ringComplete: return .ringComplete
        case .newBest: return .newBest
        case .button: return .button
        case .refused: return .refused
        }
    }
}

@MainActor
final class Feedback {
    static let shared = Feedback()

    var hapticsOn: Bool {
        get { HapticHub.shared.isEnabled }
        set { HapticHub.shared.isEnabled = newValue }
    }

    var soundOn: Bool {
        get { AudioHub.shared.isEnabled }
        set { AudioHub.shared.isEnabled = newValue }
    }

    private init() {}

    /// At launch: brings the audio session up and synthesises every cue in the background.
    func prepare() async {
        await AudioHub.shared.prepare()
    }

    /// A flight starts: the Taptic Engine stays warm until it ends, so the first stage drop is felt on time.
    func flightBegan() {
        HapticHub.shared.hold()
    }

    func flightEnded() {
        HapticHub.shared.release()
    }

    func play(_ cue: FeedbackCue) {
        AudioHub.shared.play(cue.sound)
        HapticHub.shared.play(cue.haptic)
    }
}
