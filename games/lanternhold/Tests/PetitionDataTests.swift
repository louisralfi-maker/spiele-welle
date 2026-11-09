import Foundation
import XCTest
@testable import Lanternhold

/// The content's data (M3, DESIGN.md "Petition data", "M3 in detail"): the bundled petition files and court lines load
/// without a problem, the validator finds nothing wrong with them (every text key in English and German in
/// Story.xcstrings, every follow-up, world change, speaker, unlock and night modifier known, the English length
/// limits), the build compiled every key, the validator catches the usual mistakes, a broken petition costs only itself,
/// and every speaker has a body and a portrait.
final class PetitionDataTests: XCTestCase {
    /// The game's folder in the runner's checkout, from this file's path (the simulator reads the host's files).
    private static let gameFolder = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        .deletingLastPathComponent()

    /// Story.xcstrings as written in the source; if the source is out of reach, the texts the app bundle compiled.
    private func storyTable(keys: [String]) -> (table: StoryTable, source: String) {
        let url = Self.gameFolder.appendingPathComponent("Resources/Story.xcstrings")
        if let data = try? Data(contentsOf: url), let table = StoryTable.parse(data) { return (table, url.path) }
        return (StoryTable.compiled(keys: keys, bundle: .main), "the app bundle")
    }

    func testTheBundledPetitionsAndLinesLoadWithoutProblems() {
        let loaded = PetitionCatalog.load(bundle: .main)
        XCTAssertFalse(loaded.files.isEmpty, "the petition files are in the app bundle")
        XCTAssertEqual(loaded.problems, [])
        XCTAssertGreaterThanOrEqual(loaded.catalog.petitions.count, 3)
        XCTAssertEqual(PetitionCatalog.standard, loaded.catalog, "the game plays with them")
        let lines = CourtLineBook.load(bundle: .main)
        XCTAssertTrue(lines.found, "lines.json is in the app bundle")
        XCTAssertEqual(lines.problems, [])
        XCTAssertGreaterThan(lines.book.lines.count, 3)
        XCTAssertEqual(CourtLineBook.standard, lines.book)
    }

    func testTheValidatorFindsNothingWrongWithTheContent() throws {
        var files: [(name: String, data: Data)] = []
        for url in PetitionCatalog.fileURLs(bundle: .main) {
            files.append((url.lastPathComponent, try Data(contentsOf: url)))
        }
        let linesData = CourtLineBook.fileURL(bundle: .main).flatMap { try? Data(contentsOf: $0) }
        let keys = CourtValidator.keys(petitions: .standard, lines: .standard)
        let story = storyTable(keys: keys)
        let problems = CourtValidator.problems(petitionFiles: files, linesData: linesData, table: story.table)
        let attachment = XCTAttachment(string: "Story table: \(story.source)\nfiles: \(files.map { $0.name })\n"
                                       + "problems:\n" + problems.joined(separator: "\n"))
        attachment.name = "petition-validator"
        attachment.lifetime = .keepAlways
        add(attachment)
        XCTAssertEqual(problems, [], problems.joined(separator: "\n"))
    }

    func testTheSourceFolderHoldsOnlyPetitionFilesTheBundleHas() throws {
        let folder = Self.gameFolder.appendingPathComponent("Resources/Petitions")
        guard let names = try? FileManager.default.contentsOfDirectory(atPath: folder.path) else {
            throw XCTSkip("the source folder \(folder.path) is out of reach")
        }
        let bundled = Set(PetitionCatalog.fileURLs(bundle: .main).map(\.lastPathComponent))
        for name in names where name.hasSuffix(".json") {
            XCTAssertTrue(name.hasPrefix("petitions-"), "\(name) must be named petitions-<group>.json")
            XCTAssertTrue(bundled.contains(name), "\(name) is in the app bundle")
        }
    }

    func testTheBuildCompiledEveryStoryKeyInEnglishAndGerman() {
        for key in CourtValidator.keys(petitions: .standard, lines: .standard) {
            XCTAssertNotNil(StoryText.string(key, language: "en"), "\(key) in English")
            XCTAssertNotNil(StoryText.string(key, language: "de"), "\(key) in German")
        }
        XCTAssertEqual(StoryText.string("speaker.odile.role", language: "de"), "Kanzlerin")
        XCTAssertEqual(StoryText.string("speaker.odile.role", language: "en"), "Chancellor")
        XCTAssertNil(StoryText.string("petition.nothing.text", language: "en"))
        XCTAssertEqual(StoryText.name(speaker: "seren", look: nil, day: 6, flags: []),
                       StoryText.string("speaker.stranger.name"))
        XCTAssertNotNil(StoryText.name(speaker: "farmer", look: 12, day: 6, flags: []))
    }

    func testTheValidatorCatchesTheUsualMistakes() {
        let json = """
        {"petitions": [
          {"id": "Bad-Id", "speaker": "dragon", "kind": "random", "weight": 0, "hapiness": 3, "text": "missing.text",
           "counsel": 5, "choices": [{"label": "ok.label", "gold": -10, "world": ["castle.moat"], "night": ["dragons-1"],
             "unlock": ["catapult"], "schedule": [{"id": "nowhere", "inDays": 0, "when": 1}],
             "chance": {"p": 1.5, "then": {"golt": 1}}, "reaction": "long.reaction"}]}
        ], "extra": 1}
        """
        var table = StoryTable()
        table.english["ok.label"] = "Fine"
        table.german["ok.label"] = "Gut"
        table.english["long.reaction"] = String(repeating: "x", count: 141)
        table.german["long.reaction"] = "lang"
        let lines = """
        {"lines": [{"id": "l", "speaker": "farmer", "text": "none", "about": "ghost", "mood": 1}]}
        """
        let problems = CourtValidator.problems(petitionFiles: [("petitions-broken.json", Data(json.utf8))],
                                               linesData: Data(lines.utf8), table: table)
        let text = problems.joined(separator: "\n")
        let expected = [
            "unknown top-level key extra", "unknown key hapiness", "unknown speaker dragon",
            "missing.text has no English text", "counsel 5", "needs 2 or 3 choices", "castle.moat", "dragons-1",
            "unlock catapult", "schedule nowhere", "inDays", "unknown schedule key when", "chance p",
            "unknown key golt", "141 characters", "every choice costs", "weight 0 and no schedule", "the id must be",
            "farmer does not talk", "about ghost", "lines.json: l: unknown key mood", "speaker odile role",
        ]
        for snippet in expected {
            XCTAssertTrue(text.contains(snippet), "expected a problem with \"\(snippet)\" in:\n\(text)")
        }
    }

    func testTheLoaderSkipsABrokenPetitionAndKeepsTheRest() {
        let json = """
        {"petitions": [
          {"id": "fine", "speaker": "farmer", "kind": "random", "text": "t", "choices": [{"label": "a"}, {"label": "b"}]},
          {"id": "broken", "speaker": "farmer", "kind": "sometimes", "text": "t", "choices": []},
          {"id": "fine", "speaker": "farmer", "kind": "random", "text": "t2", "choices": [{"label": "a"}, {"label": "b"}]}
        ]}
        """
        let decoded = PetitionCatalog.decode(Data(json.utf8), file: "petitions-test.json")
        XCTAssertEqual(decoded.petitions.map(\.id), ["fine", "fine"])
        XCTAssertEqual(decoded.problems.count, 1)
        XCTAssertTrue(decoded.problems.first?.contains("broken") ?? false)
        let catalog = PetitionCatalog(decoded.petitions)
        XCTAssertEqual(catalog.petitions.count, 1, "of two with one id the first stays")
        XCTAssertEqual(catalog.petition("fine")?.text, "t")
        XCTAssertEqual(PetitionCatalog.decode(Data("[1, 2]".utf8), file: "x.json").problems.count, 1)
        let round = try? JSONDecoder().decode(Petition.self, from: JSONEncoder().encode(catalog.petitions[0]))
        XCTAssertEqual(round, catalog.petitions[0], "a petition encodes and decodes the same")
    }

    func testEverySpeakerHasABodyAndAPortrait() throws {
        for speaker in Speakers.all {
            let frames = speaker.body.sprite.frameCount
            XCTAssertGreaterThan(frames, speaker.body.walk.upperBound, "\(speaker.id) walk frames")
            XCTAssertGreaterThan(frames, speaker.body.idle.upperBound, "\(speaker.id) idle frames")
            if let talk = speaker.body.talk { XCTAssertGreaterThan(frames, talk.upperBound, "\(speaker.id) talk frames") }
            if let glow = speaker.body.glow {
                XCTAssertEqual(glow.size, speaker.body.sprite.size)
                XCTAssertEqual(glow.frameCount, frames)
            }
            switch speaker.role {
            case .court, .guest:
                XCTAssertEqual(speaker.portrait?.size, PixelSize(width: 48, height: 48), speaker.id)
            case .townsfolk:
                XCTAssertNil(speaker.portrait)
                for look in 0..<40 {
                    let recipe = try XCTUnwrap(Speakers.recipe(speaker.id, look: look), speaker.id)
                    XCTAssertTrue((0..<SpriteID.portraitClothes.frameCount).contains(recipe.clothes))
                    XCTAssertTrue((0..<SpriteID.portraitFace.frameCount).contains(recipe.face))
                    XCTAssertTrue((0..<SpriteID.portraitBeard.frameCount).contains(recipe.beard))
                    XCTAssertTrue((0..<SpriteID.portraitHair.frameCount).contains(recipe.hair))
                    XCTAssertTrue((0..<SpriteID.portraitHat.frameCount).contains(recipe.hat))
                    if recipe.female { XCTAssertEqual(recipe.beard, PortraitPart.noBeard) }
                    XCTAssertEqual(Speakers.recipe(speaker.id, look: look), recipe, "the same look, the same face")
                    XCTAssertNotNil(Speakers.townsfolkName(speaker.id, look: look))
                }
            }
        }
        XCTAssertEqual(Speakers.nameKey("seren", day: 5, flags: []), "speaker.stranger.name")
        XCTAssertEqual(Speakers.nameKey("seren", day: 15, flags: []), "speaker.seren.name")
        XCTAssertEqual(Speakers.nameKey("seren", day: 9, flags: [Speakers.serenRevealedFlag]), "speaker.seren.name")
        XCTAssertEqual(Speakers.portraitFrame("seren", day: 3, flags: []), 0)
        XCTAssertEqual(Speakers.portraitFrame("seren", day: 16, flags: []), 1)
        XCTAssertTrue(Speakers.isKnown("farmer"))
        XCTAssertFalse(Speakers.isKnown("dragon"))
        XCTAssertFalse(Speakers.canTalk("farmer"))
        XCTAssertTrue(Speakers.canTalk("serLudo"))
        var faces = Set<String>()
        for look in 0..<30 {
            if let r = Speakers.recipe("townswoman", look: look) {
                faces.insert("\(r.face)-\(r.hair)-\(r.hat)-\(r.skin)-\(r.cloth)-\(r.hairColor)")
            }
        }
        XCTAssertGreaterThan(faces.count, 10, "townsfolk of one kind look different")
    }
}
