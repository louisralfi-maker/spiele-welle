import Foundation
import XCTest
@testable import Lanternhold

/// The story in the six other languages (the i18n lane, docs/lanes/i18n.md), held where `PetitionDataTests` and
/// `LordTests` hold English and German: every key in the source catalogue within its budget, every key compiled into
/// the app bundle, every text read right by a lord and by a lady, and the validator catching the usual mistakes.
final class StoryLanguagesTests: XCTestCase {
    private static let gameFolder = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        .deletingLastPathComponent()

    private var kinds: [(key: String, kind: StoryLanguages.Kind)] {
        StoryLanguages.kinds(petitions: .standard, lines: .standard)
    }

    /// Story.xcstrings as written in the source; if the source is out of reach, the texts the app bundle compiled.
    private func storyTexts() -> (texts: [String: [String: String]], source: String) {
        let url = Self.gameFolder.appendingPathComponent("Resources/Story.xcstrings")
        if let data = try? Data(contentsOf: url), let texts = StoryLanguages.parse(data) { return (texts, url.path) }
        return (StoryLanguages.compiled(keys: kinds.map(\.key), bundle: .main), "the app bundle")
    }

    func testEveryLanguageHasEveryStoryTextWithinItsBudget() {
        let story = storyTexts()
        let problems = StoryLanguages.problems(kinds: kinds, texts: story.texts)
        let attachment = XCTAttachment(string: "Story table: \(story.source)\nproblems:\n"
                                       + problems.joined(separator: "\n"))
        attachment.name = "story-languages"
        attachment.lifetime = .keepAlways
        add(attachment)
        XCTAssertEqual(problems, [], problems.prefix(40).joined(separator: "\n"))
        for language in StoryLanguages.all {
            XCTAssertEqual(story.texts[language]?.count, story.texts["en"]?.count,
                           "\(language) has exactly the keys English has")
        }
    }

    func testTheBuildCompiledEveryStoryKeyInTheSixLanguages() {
        let keys = CourtValidator.keys(petitions: .standard, lines: .standard)
        for language in StoryLanguages.all {
            var missing: [String] = []
            for key in keys where StoryText.string(key, language: language) == nil { missing.append(key) }
            XCTAssertEqual(missing, [], "\(language): \(missing.count) keys not in the bundle")
        }
        let roles = ["fr": "Chancelière", "es": "Canciller", "it": "Cancelliera", "pt-BR": "Chanceler", "ja": "家宰",
                     "zh-Hans": "家宰"]
        for (language, role) in roles {
            XCTAssertEqual(StoryText.string("speaker.odile.role", language: language), role, language)
        }
        XCTAssertEqual(StoryText.string("remember.tower_promised", language: "es"), "Brannock le toma la palabra: la torre.")
        XCTAssertEqual(StoryText.string("remember.tower_promised", language: "zh-Hans"), "布兰诺克记着你许下的那座塔。")
        XCTAssertNil(StoryText.string("petition.nothing.text", language: "fr"))
    }

    /// The lord pass in every language: no brace is left for a lord or a lady, the Romance languages turn on lord or
    /// lady somewhere, and `{lord}` stands where the English has it.
    func testTheStoryTextsTakeTheLordInEveryLanguage() {
        let mira = LordIdentity(name: "Mira", form: .lady)
        let texts = storyTexts().texts
        for language in StoryLanguages.all {
            var turned = 0
            var named = 0
            for item in kinds {
                guard let raw = texts[language]?[item.key] else { continue }
                if raw.contains("{lord}") { named += 1 }
                if LordText.usesLord(raw.replacingOccurrences(of: "{lord}", with: "")) { turned += 1 }
                for lord in [mira, LordIdentity.standard] {
                    let shown = LordText.resolve(raw, lord: lord)
                    XCTAssertFalse(shown.contains("{") || shown.contains("}"), "\(item.key) in \(language): \(shown)")
                }
            }
            XCTAssertGreaterThan(named, 0, "\(language) names the lord somewhere")
            if !StoryLanguages.wide.contains(language) {
                XCTAssertGreaterThan(turned, 50, "\(language) turns on lord and lady")
            }
        }
    }

    /// The table is the validator's for English and German, and the kinds follow the key names the tools read.
    func testTheBudgetsAndKindsMatchTheValidatorAndTheTools() {
        let pairs: [(StoryLanguages.Kind, CourtValidator.Limit)] = [
            (.text, CourtValidator.textLimit), (.hint, CourtValidator.hintLimit),
            (.choice, CourtValidator.choiceLimit), (.reaction, CourtValidator.reactionLimit),
            (.line, CourtValidator.lineLimit), (.ending, CourtValidator.endingLimit),
            (.remembered, CourtValidator.rememberedLimit), (.tile, CourtValidator.tileLimit),
            (.name, CourtValidator.nameLimit), (.role, CourtValidator.roleLimit),
        ]
        XCTAssertEqual(pairs.count, StoryLanguages.Kind.allCases.count)
        for (kind, limit) in pairs {
            XCTAssertEqual(StoryLanguages.budget(kind, language: "en"), limit.english, kind.rawValue)
            XCTAssertEqual(StoryLanguages.budget(kind, language: "de"), limit.german, kind.rawValue)
            for language in StoryLanguages.all {
                let budget = StoryLanguages.budget(kind, language: language) ?? 0
                XCTAssertGreaterThanOrEqual(budget, limit.english, "\(kind.rawValue) in \(language)")
            }
        }
        let all = kinds
        XCTAssertEqual(Set(all.map(\.key)), Set(CourtValidator.keys(petitions: .standard, lines: .standard)))
        for item in all {
            XCTAssertEqual(StoryLanguages.kind(of: item.key), item.kind, item.key)
        }
        XCTAssertEqual(StoryLanguages.kind(of: "petition.x.r2b"), .reaction)
        XCTAssertEqual(StoryLanguages.kind(of: "petition.x.c3"), .choice)
        XCTAssertNil(StoryLanguages.kind(of: "petition.x.c12"))
        XCTAssertNil(StoryLanguages.kind(of: "note.x"))
    }

    func testWidthUnitsCountAWideCharacterTwice() {
        XCTAssertEqual(StoryLanguages.width("Robin"), 5)
        XCTAssertEqual(StoryLanguages.width("ランタン"), 8)
        XCTAssertEqual(StoryLanguages.width("圣焰。"), 6)
        XCTAssertEqual(StoryLanguages.width("「6人」"), 7, "a half-width figure counts 1")
        XCTAssertEqual(StoryLanguages.width("……"), 2, "the ellipsis is narrow")
        XCTAssertEqual(StoryLanguages.width("ｱ！"), 3, "half-width kana 1, full-width punctuation 2")
        XCTAssertEqual(StoryLanguages.measure("Chancelière", language: "fr"), 11)
        XCTAssertEqual(StoryLanguages.measure("Chancelie\u{300}re", language: "fr"), 11, "composed before counting")
        XCTAssertEqual(StoryLanguages.longest("{lord}様", language: "ja"), LordIdentity.nameLimit + 2)
        XCTAssertEqual(StoryLanguages.longest("{prêt|prête} !", language: "fr"), 7)
    }

    func testTheLanguageValidatorCatchesTheUsualMistakes() {
        let kinds: [(key: String, kind: StoryLanguages.Kind)] = [
            ("petition.a.c1", .choice), ("petition.a.text", .text), ("line.b", .line), ("speaker.c.role", .role),
        ]
        var texts: [String: [String: String]] = ["en": [
            "petition.a.c1": "Pay {lord}", "petition.a.text": "Hello", "line.b": "Fine", "speaker.c.role": "Farmer",
        ]]
        texts["fr"] = [
            "petition.a.c1": String(repeating: "x", count: 48 - 16 - 4) + "{lord}" + "{a|bb}",
            "petition.a.text": "Bonjour {seigneur}",
            "line.b": "Bien | mal",
        ]
        texts["ja"] = [
            "petition.a.c1": String(repeating: "あ", count: 25),
            "petition.a.text": "こんにちは",
            "line.b": "",
            "speaker.c.role": "農夫",
        ]
        let problems = StoryLanguages.problems(kinds: kinds, texts: texts, languages: ["fr", "ja"])
        XCTAssertEqual(problems, [
            "fr: petition.a.text has a brace group that is neither {lord} nor {a|b}: {seigneur}",
            "fr: line.b has a | outside a {a|b} group",
            "fr: speaker.c.role has no text",
            "ja: petition.a.c1 is 50 width units (at most 48 for a choice)",
            "ja: petition.a.c1 has {lord} 0 times, the English 1",
            "ja: line.b has no text",
        ])
        texts["fr"]?["petition.a.c1"] = String(repeating: "x", count: 48 - 16 - 1) + "{lord}" + "{a|bb}"
        XCTAssertEqual(StoryLanguages.problems(key: "petition.a.c1", kind: .choice, text: texts["fr"]?["petition.a.c1"],
                                               english: "Pay {lord}", language: "fr"),
                       ["fr: petition.a.c1 is 49 characters (at most 48 for a choice)"],
                       "a text that fits only a short name or only the lord's half is too long")
        XCTAssertEqual(StoryLanguages.problems(key: "k", kind: .text, text: "x", english: nil, language: "xx"),
                       ["xx: k has no budget (an unknown language)"])
    }
}
