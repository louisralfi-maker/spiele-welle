import Foundation

/// When a launch asks for the lord (the lord pass, DESIGN.md "The lord pass and the story pass").
enum LordEntry {
    /// A new realm asks who holds it: day 1 before its first dawn, no lord chosen yet. Never under the debug
    /// arguments that skip the onboarding, name the lord, let the reference bot play or open a sample screen (tests,
    /// screenshots, the showcase), so every start they make is the same as before the lord pass.
    static func asks(args: DebugArgs, state: GameState) -> Bool {
        guard state.lord == nil, state.day == 1, state.dawns == 0, !state.defeated else { return false }
        if args.skipOnboarding || args.lordIdentity != nil || args.autoplay != nil || args.screen != nil {
            return false
        }
        return args.day == nil && args.night == nil && args.hour == nil
    }
}

/// The lord's part of the screen state machine: the name entry of a new realm and the lord's name and form in the
/// story texts.
extension GameModel {
    /// Who the player is (the standard lord until the name entry was confirmed).
    var lord: LordIdentity { driver?.state.lordOrDefault ?? .standard }

    /// What the name entry starts with: nil on the first start (an empty field, the Burgherr marked), the old
    /// realm's lord after a restart.
    var lordDraft: LordIdentity? { driver?.state.lord }

    /// A story text in the device's language with the lord's name and form filled in (`LordText`).
    func story(_ key: String) -> String {
        StoryText.string(key, lord: lord)
    }

    /// The name entry's "Begin": the lord is stored in the realm and in its dawn snapshot, the save is written and
    /// the day starts.
    func confirmLord(name: String, form: LordForm) {
        guard overlay == .lordEntry else { return }
        withDriver { $0.setLord(LordIdentity(name: name, form: form)) }
        saveNow()
        feedback.play(.cardClosed)
        setOverlay(nil)
        // Panels lane: day 1 begins after the prologue (UI/Slides/GameModel+Slides.swift).
        presentPrologueAfterEntry()
    }
}
