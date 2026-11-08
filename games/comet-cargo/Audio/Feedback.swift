import UIKit

/// Everything the player feels goes through here. Version 0.1 plays haptics only (UIKit feedback generators) and respects
/// the haptics setting; synthesized sound effects come in the juice step. No music, ever.
enum FeedbackCue: Sendable, Equatable {
    case ignite
    case stageDrop(DropRating)
    case release(ReleaseRating)
    case lost
    case coin
    case ringComplete
    case button
    /// A drop tap on the last stage.
    case refused
}

@MainActor
final class Feedback {
    static let shared = Feedback()

    var hapticsOn = true
    /// Kept for the juice step; nothing plays sound yet.
    var soundOn = true

    private let light = UIImpactFeedbackGenerator(style: .light)
    private let medium = UIImpactFeedbackGenerator(style: .medium)
    private let heavy = UIImpactFeedbackGenerator(style: .heavy)
    private let rigid = UIImpactFeedbackGenerator(style: .rigid)
    private let soft = UIImpactFeedbackGenerator(style: .soft)
    private let notice = UINotificationFeedbackGenerator()
    private let selection = UISelectionFeedbackGenerator()

    private init() {}

    /// Wakes the Taptic Engine before a flight so the first cue is on time.
    func prepare() {
        guard hapticsOn else { return }
        heavy.prepare()
        rigid.prepare()
        notice.prepare()
    }

    func play(_ cue: FeedbackCue) {
        guard hapticsOn else { return }
        switch cue {
        case .ignite:
            heavy.impactOccurred(intensity: 1.0)
        case .stageDrop(let rating):
            switch rating {
            case .perfect: rigid.impactOccurred(intensity: 1.0)
            case .great: rigid.impactOccurred(intensity: 0.75)
            case .good: medium.impactOccurred(intensity: 0.6)
            case .early, .late: soft.impactOccurred(intensity: 0.5)
            }
        case .release(let rating):
            switch rating {
            case .perfect: notice.notificationOccurred(.success)
            case .great: medium.impactOccurred(intensity: 0.8)
            case .good: light.impactOccurred(intensity: 0.7)
            case .lost: notice.notificationOccurred(.warning)
            }
        case .lost:
            notice.notificationOccurred(.warning)
        case .coin:
            light.impactOccurred(intensity: 0.6)
        case .ringComplete:
            notice.notificationOccurred(.success)
        case .button:
            selection.selectionChanged()
        case .refused:
            soft.impactOccurred(intensity: 0.4)
        }
    }
}
