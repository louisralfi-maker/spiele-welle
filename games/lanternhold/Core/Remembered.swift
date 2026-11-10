/// What a story choice leaves behind when it changes no number (M3 fix, U1: the tower promised or the light first,
/// the Stranger turned away, the last speech: every such choice set a flag and showed "No cost" and an empty change
/// row). The choice tile says "Will be remembered"; the reaction card's change row names it in one line
/// (`remember.<flag>` in Story.xcstrings); and the court answers it in the hall (`CourtLine.answer`).
enum Remembered {
    /// The flags with a line, in the order the reaction card lists them.
    static let flags: [String] = [
        "tower_promised", Build.brazierGiftFlag, "stranger_in", "stranger_turned_away", "arrows_refused",
        "vigil_kept", "giant_unwarned", "beacon_doubted", "vow_aldric", "seren_doubted", "seren_outside",
        "pip_joke_told", "pip_joke_saved", "speech_dawn", "speech_aldric", "speech_honest",
        // The houses' audiences (STORY.md 9.3).
        "varn_with", "varn_stung", "oxmoor_lamp", "oxmoor_debt", "oxmoor_refused", "calder_with", "calder_coddled",
        "calder_refused", "lorn_heard", "stubs_known", "lorn_dismissed", "banners_hung", "holds_alone", "hild_stays",
        "hild_rode",
    ]
    /// The last stand's speeches (day 20): the finale's dawn report quotes the one the king gave.
    static let speeches: [String] = ["speech_dawn", "speech_aldric", "speech_honest"]
    /// At most this long, English and German: one line of the reaction card's change row.
    static let limit = 56

    static func key(_ flag: String) -> String { "remember." + flag }

    /// The lines of the flags a choice set, in the list's order.
    static func keys(_ flagsSet: [String]) -> [String] {
        flags.filter { flagsSet.contains($0) }.map(key)
    }

    /// True when a choice's own effect (not a chance's sides) sets a remembered flag: its tile says so.
    static func remembers(_ effect: PetitionEffect) -> Bool {
        !keys(effect.flags ?? []).isEmpty
    }

    /// What a tile says instead of "Will be remembered" where two or three words name it: the free brazier.
    static let tileKeys: [String: String] = [Build.brazierGiftFlag: "remember.brazier_gift.tile"]
    static let tileLimit = 28

    static func tileKey(_ effect: PetitionEffect) -> String? {
        flags.first { (effect.flags ?? []).contains($0) && tileKeys[$0] != nil }.flatMap { tileKeys[$0] }
    }

    /// Every text key of the remembered lines, the tiles and the speeches.
    static var allKeys: [String] { flags.map(key) + tileKeys.values.sorted() + speechKeys }

    /// The finale report's line for the speech the king gave (`ending.<speech>`), nil without one.
    static func speechKey(flags: [String]) -> String? {
        speeches.first { flags.contains($0) }.map { "ending." + $0 }
    }

    static var speechKeys: [String] { speeches.map { "ending." + $0 } }
}
