import Foundation

/// Burgherr or Burgherrin (STORY.md, Louis' decision 3): the player chooses it with the name at the start of a new
/// game. It picks the lord's sprites and portrait and the gendered half of every `{a|b}` in the story texts.
enum LordForm: String, Codable, Sendable, Equatable, CaseIterable {
    /// The Burgherr (Lord Lantern, "my lord", "mein Herr").
    case lord
    /// The Burgherrin (Lady Lantern, "my lady", "meine Herrin").
    case lady
}

/// Who the player is: the typed name and Burgherr or Burgherrin (DESIGN.md "The lord pass and the story pass"). It
/// lives in the save (`GameState.lord`); a save from before the lord pass has none and reads as `standard`. The name
/// never leaves the device: it is drawn on this player's cards only.
struct LordIdentity: Codable, Sendable, Equatable {
    /// The longest name in characters (the name entry cuts there, and the validator counts every `{lord}` as this).
    static let nameLimit = 16
    /// The name of a lord who typed none.
    static let defaultName = "Robin"
    /// The lord of every save from before the lord pass and of every start that asks nobody (tests, the bot).
    static let standard = LordIdentity(name: defaultName, form: .lord)

    var name: String
    var form: LordForm

    /// The name is cleaned (`clean`), so a stored name is always drawable and within the limit.
    init(name: String, form: LordForm) {
        self.name = LordIdentity.clean(name)
        self.form = form
    }

    private enum CodingKeys: String, CodingKey {
        case name, form
    }

    /// Lenient: a missing or unknown field reads as the standard's, and the name is cleaned again.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let name = try container.decodeIfPresent(String.self, forKey: .name) ?? LordIdentity.defaultName
        let form = (try? container.decodeIfPresent(String.self, forKey: .form)).flatMap { LordForm(rawValue: $0) }
        self.init(name: name, form: form ?? .lord)
    }

    /// What the name entry keeps of a typed name: letters of any script, single spaces, hyphens, apostrophes and
    /// full stops; no digits, symbols, emoji or line breaks (so a name can never carry a `{` of the text
    /// placeholders); trimmed, at most `nameLimit` characters. Nothing left: the default name.
    static func clean(_ raw: String) -> String {
        var name = typed(raw)
        while let last = name.last, last == " " || last == "-" {
            name.removeLast()
        }
        return name.isEmpty ? defaultName : name
    }

    /// The same filter while the name is being typed (the name entry's field): a space or hyphen at the end stays, so
    /// a second word can follow, and an empty field stays empty (the field shows the default name as its prompt).
    static func typed(_ raw: String) -> String {
        var kept = ""
        var lastWasSpace = true
        for character in raw {
            if character.isLetter {
                kept.append(character)
                lastWasSpace = false
            } else if character == "-" || character == "'" || character == "\u{2019}" || character == "." {
                if !kept.isEmpty {
                    kept.append(character)
                    lastWasSpace = false
                }
            } else if character.isWhitespace {
                if !lastWasSpace {
                    kept.append(" ")
                    lastWasSpace = true
                }
            }
        }
        return String(kept.prefix(nameLimit))
    }

    // MARK: Sprites

    /// The walking lord (walk 0 ... 5, idle 6 ... 7, command 8 ... 9) and the glow strip of the lantern.
    var body: SpriteID { form == .lady ? .lady : .king }
    var glow: SpriteID { form == .lady ? .ladyGlow : .kingGlow }
    /// The lord on the throne (sit down 0 ... 1, seated idle 2 ... 3) and its glow strip.
    var seated: SpriteID { form == .lady ? .ladySeated : .kingSeated }
    var seatedGlow: SpriteID { form == .lady ? .ladySeatedGlow : .kingSeatedGlow }
    var portrait: SpriteID { form == .lady ? .portraitLady : .portraitKing }
}

extension SpriteID {
    /// The lord's own sprites, walking or seated (the Burgherr's or the Burgherrin's), without the glow strips.
    var isLord: Bool {
        switch self {
        case .king, .lady, .kingSeated, .ladySeated: return true
        default: return false
        }
    }
}

/// The placeholders of the story texts (STORY.md, Louis' decision 3). Two forms, in English and German alike:
/// `{lord}` is the typed name, and `{a|b}` reads `a` for the Burgherr and `b` for the Burgherrin
/// (`{my lord|my lady}`, `{Herr|Herrin}`). Nothing nests; a brace that is neither is a mistake the validator
/// reports.
enum LordText {
    /// The name's placeholder.
    static let nameToken = "lord"

    /// One piece of a text.
    enum Piece: Equatable, Sendable {
        case text(String)
        case name
        case choice(lord: String, lady: String)
        /// A brace group that is neither form, or a brace without its partner (kept as written).
        case broken(String)
    }

    static func pieces(_ text: String) -> [Piece] {
        guard text.contains("{") || text.contains("}") else { return [.text(text)] }
        var pieces: [Piece] = []
        var plain = ""
        var rest = Substring(text)
        func flush() {
            if !plain.isEmpty {
                pieces.append(.text(plain))
                plain = ""
            }
        }
        while let character = rest.first {
            if character == "{" {
                guard let close = rest.firstIndex(of: "}") else {
                    flush()
                    pieces.append(.broken(String(rest)))
                    return pieces
                }
                let inner = rest[rest.index(after: rest.startIndex)..<close]
                rest = rest[rest.index(after: close)...]
                flush()
                let parts = inner.split(separator: "|", omittingEmptySubsequences: false)
                if inner == nameToken {
                    pieces.append(.name)
                } else if parts.count == 2, !inner.contains("{") {
                    pieces.append(.choice(lord: String(parts[0]), lady: String(parts[1])))
                } else {
                    pieces.append(.broken("{" + inner + "}"))
                }
            } else if character == "}" {
                flush()
                pieces.append(.broken("}"))
                rest = rest.dropFirst()
            } else {
                plain.append(character)
                rest = rest.dropFirst()
            }
        }
        flush()
        return pieces
    }

    /// The text as this lord reads it.
    static func resolve(_ text: String, lord: LordIdentity) -> String {
        guard text.contains("{") else { return text }
        var result = ""
        for piece in pieces(text) {
            switch piece {
            case .text(let value), .broken(let value): result += value
            case .name: result += lord.name
            case .choice(let forLord, let forLady): result += lord.form == .lady ? forLady : forLord
            }
        }
        return result
    }

    /// The longest the text can get, in characters: every name as long as the limit allows, every choice its longer
    /// half. The validator holds the text limits against this.
    static func longest(_ text: String) -> Int {
        var count = 0
        for piece in pieces(text) {
            switch piece {
            case .text(let value), .broken(let value): count += value.count
            case .name: count += LordIdentity.nameLimit
            case .choice(let forLord, let forLady): count += max(forLord.count, forLady.count)
            }
        }
        return count
    }

    /// The brace groups that are neither `{lord}` nor `{a|b}` (empty when the text is sound).
    static func problems(_ text: String) -> [String] {
        pieces(text).compactMap { piece in
            if case .broken(let value) = piece { return value }
            return nil
        }
    }

    /// Whether the text names the lord or turns on Burgherr or Burgherrin.
    static func usesLord(_ text: String) -> Bool {
        pieces(text).contains { piece in
            switch piece {
            case .name, .choice: return true
            default: return false
            }
        }
    }
}
