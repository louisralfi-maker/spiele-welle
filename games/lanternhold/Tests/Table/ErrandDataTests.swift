import Foundation
import XCTest
@testable import Lanternhold

/// The Lantern Table's data (docs/QUESTS.md 4.1): the bundled table file loads without a problem, the validator finds
/// nothing wrong with it (every text key in English and German in Quests.xcstrings within its length, every reference
/// known, the seal's and the chips' rules), the build compiled every key, the validator catches the usual mistakes,
/// a broken entry costs only itself, and sendings 1, 5 and 11 are there as QUESTS.md 3.2 writes them.
final class ErrandDataTests: XCTestCase {
    /// The game's folder in the runner's checkout, from this file's path (the simulator reads the host's files).
    private static let gameFolder = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        .deletingLastPathComponent().deletingLastPathComponent()

    /// Quests.xcstrings as written in the source; if the source is out of reach, the texts the app bundle compiled.
    private func questTable(keys: [String]) -> (table: StoryTable, source: String) {
        let url = Self.gameFolder.appendingPathComponent("Resources/Quests.xcstrings")
        if let data = try? Data(contentsOf: url), let table = StoryTable.parse(data) { return (table, url.path) }
        var table = StoryTable()
        for key in keys {
            if let text = QuestText.string(key, language: "en") { table.english[key] = text }
            if let text = QuestText.string(key, language: "de") { table.german[key] = text }
        }
        return (table, "the app bundle")
    }

    private func bundledFiles() throws -> [(name: String, data: Data)] {
        try ErrandCatalog.fileURLs(bundle: .main).map { ($0.lastPathComponent, try Data(contentsOf: $0)) }
    }

    func testTheBundledTableLoadsWithoutProblems() {
        let loaded = ErrandCatalog.load(bundle: .main)
        XCTAssertEqual(loaded.files, ["errands-ch1.json"], "the table file is in the app bundle")
        XCTAssertEqual(loaded.problems, [])
        XCTAssertEqual(ErrandCatalog.standard, loaded.catalog, "the game plays with it")
        XCTAssertEqual(loaded.catalog.lanterns, [38, 39, 40])
        XCTAssertEqual(loaded.catalog.reserved, [41])
        XCTAssertEqual(loaded.catalog.places.count, 11, "eleven carved places, Lanternhold among them")
        XCTAssertNotNil(loaded.catalog.report(ErrandCatalog.lostReportID))
    }

    func testTheValidatorFindsNothingWrongWithTheContent() throws {
        let files = try bundledFiles()
        let keys = ErrandValidator.keys(.standard)
        let quests = questTable(keys: keys)
        let problems = ErrandValidator.problems(files: files, table: quests.table, petitions: .standard)
        let attachment = XCTAttachment(string: "Quests table: \(quests.source)\nfiles: \(files.map { $0.name })\n"
                                       + "keys: \(keys.count)\nproblems:\n" + problems.joined(separator: "\n"))
        attachment.name = "table-validator"
        attachment.lifetime = .keepAlways
        add(attachment)
        XCTAssertEqual(problems, [], problems.joined(separator: "\n"))
    }

    func testTheSourceFolderHoldsOnlyTableFilesTheBundleHas() throws {
        let folder = Self.gameFolder.appendingPathComponent("Resources/Errands")
        guard let names = try? FileManager.default.contentsOfDirectory(atPath: folder.path) else {
            throw XCTSkip("the source folder \(folder.path) is out of reach")
        }
        let bundled = Set(ErrandCatalog.fileURLs(bundle: .main).map(\.lastPathComponent))
        for name in names where name.hasSuffix(".json") {
            XCTAssertTrue(name.hasPrefix("errands-"), "\(name) must be named errands-<chapter>.json")
            XCTAssertTrue(bundled.contains(name), "\(name) is in the app bundle")
        }
        let source = ErrandCatalog.load(directory: folder)
        XCTAssertEqual(source.problems, [])
        XCTAssertEqual(source.catalog, ErrandCatalog.standard, "the source folder and the bundle agree")
    }

    func testTheBuildCompiledEveryTableKeyInEnglishAndGerman() {
        for key in ErrandValidator.keys(.standard) {
            XCTAssertNotNil(QuestText.string(key, language: "en"), "\(key) in English")
            XCTAssertNotNil(QuestText.string(key, language: "de"), "\(key) in German")
        }
        XCTAssertEqual(QuestText.string("table.title", language: "en"), "The Lantern Table")
        XCTAssertEqual(QuestText.string("table.title", language: "de"), "Der Laternentisch")
        XCTAssertEqual(QuestText.string("table.risk.few", language: "de"), "Wenige kehren heim")
        XCTAssertEqual(QuestText.string("errand.highcairn_count.title", language: "de"), "Die Zählung für Highcairn")
        XCTAssertNil(QuestText.string("errand.nothing.title", language: "en"))
    }

    /// `{lantern}` is filled in digits, `{n}` too, and the lord's forms resolve after them.
    func testPlaceholdersAndCounts() {
        XCTAssertEqual(QuestText.fill("Lantern {lantern} is home", ["lantern": "39"]), "Lantern 39 is home")
        XCTAssertEqual(QuestText.fill("{n} of {total}", ["n": "2", "total": "3"]), "2 of 3")
        XCTAssertEqual(QuestText.fill("no braces", ["n": "2"]), "no braces")
        let lady = LordIdentity(name: "Mara", form: .lady)
        let filled = LordText.resolve(QuestText.fill("{Der Laternenanzünder|Die Laternenanzünderin} {lantern}",
                                                     ["lantern": "40"]), lord: lady)
        XCTAssertEqual(filled, "Die Laternenanzünderin 40")
        XCTAssertTrue(QuestText.count("table.nights", 1).contains("1"))
        XCTAssertTrue(QuestText.count("table.nights", 3).contains("3"))
    }

    /// Sendings 1, 5 and 11 as QUESTS.md 3.2 writes them.
    func testTheThreeSendingsOfRoundOne() throws {
        let catalog = ErrandCatalog.standard
        let oil = try XCTUnwrap(catalog.errand("oil_round"))
        XCTAssertEqual(oil.number, 1)
        XCTAssertEqual(oil.place, "tallowford")
        XCTAssertEqual(oil.dayRange, 2...6)
        XCTAssertEqual(oil.orders.count, 1)
        XCTAssertEqual(oil.orders[0].goes, ["pip"])
        XCTAssertEqual(oil.orders[0].goldCost, 5)
        XCTAssertEqual(oil.orders[0].nights, 1)
        XCTAssertTrue(oil.orders[0].isSealed)
        XCTAssertEqual(oil.orders[0].riskTier, .none)

        let count = try XCTUnwrap(catalog.errand("highcairn_count"))
        XCTAssertEqual(count.number, 5)
        XCTAssertEqual(count.dayRange, 5...11)
        XCTAssertEqual(count.requires, ["varn_with"])
        XCTAssertEqual(count.orders.map(\.isSealed), [true, false])
        XCTAssertEqual(count.orders.map(\.nights), [2, 2])
        XCTAssertEqual(count.orders.map(\.goldCost), [8, 8])
        XCTAssertEqual(count.orders[1].cost?.flags, ["count_rounded"])
        XCTAssertEqual(count.orders.map(\.report), ["highcairn_true", "highcairn_rounded"])
        XCTAssertEqual(count.atReturn?.flags, ["varn_road"])

        let statues = try XCTUnwrap(catalog.errand("beacon_statues"))
        XCTAssertEqual(statues.number, 11)
        XCTAssertEqual(statues.dayRange, 11...16)
        XCTAssertEqual(statues.unlocked, ["beacon"])
        XCTAssertEqual(statues.orders.map(\.riskTier), [.none, .fewComeBack])
        XCTAssertEqual(statues.orders[1].risk, 0.25)
        XCTAssertEqual(statues.orders[1].atReturn?.world, ["table.west.2"])
        XCTAssertEqual(statues.atReturn?.world, ["table.west.1"])
        XCTAssertEqual(statues.atReturn?.flags, ["statues_counted"])

        let lost = try XCTUnwrap(catalog.report(ErrandCatalog.lostReportID))
        XCTAssertEqual(lost.speaker, "brannock")
        XCTAssertEqual(lost.choices.compactMap { $0.effect.flags?.first }, ["mourning_kept", "hook_hidden"])
    }

    func testTheValidatorCatchesTheUsualMistakes() {
        let json = """
        {"chapter": 1, "lanterns": [38, 38], "reserved": [38], "colour": "teal",
         "places": [{"id": "far", "kind": "house", "nights": 9}],
         "errands": [
          {"id": "Bad-Id", "number": 1, "place": "nowhere", "days": [1, 3], "requires": ["never_set_flag"],
           "unlocked": ["moon"], "heard": ["no_petition"],
           "orders": [
             {"seal": true, "nights": 1, "risk": 0.5, "cost": {"gold": -50, "happiness": -1},
              "lend": {"archers": 3, "knights": 1}, "report": "missing_report"},
             {"nights": 7, "risk": 0.2, "late": true, "goes": ["dragon"], "report": "rep"}
           ]},
          {"id": "sealed_never", "number": 1, "place": "far", "days": [7, 7],
           "orders": [{"seal": true, "nights": 1, "lend": {"guards": 1}, "report": "rep"}]}
         ],
         "reports": [
          {"id": "rep", "speaker": "pip", "text": "report.rep.text",
           "choices": [{"label": "report.rep.c1", "gold": -5, "night": ["sootlings-2"], "chance": {"p": 0.5}},
                       {"label": "report.rep.c2", "archers": -1, "unlock": ["beacon"], "world": ["moon.base"]}]}
         ]}
        """
        let table = StoryTable()
        let problems = ErrandValidator.problems(files: [("errands-bad.json", Data(json.utf8))], table: table,
                                                petitions: .standard)
        let all = problems.joined(separator: "\n")
        for expected in ["unknown top-level key colour", "unknown key knights", "a road lantern is on the rail twice",
                         "lantern 38 is both a road lantern and reserved", "nights 9 outside",
                         "the id must be lowercase", "unknown place nowhere", "under its cloth before day 2",
                         "never_set_flag is never set", "heard no_petition is no petition",
                         "unlocked moon is not one of", "a sealed order risks nothing",
                         "a sealed order lends at most 2 soldiers", "a cost is gold and flags only",
                         "gold -50 outside", "report missing_report is missing", "risk 0.5 is in no chip's band",
                         "risk 0.2 is in no chip's band", "nights 7 outside", "unknown speaker dragon",
                         "a sending with two orders labels each", "the seal can never hold",
                         "a sealed order's report needs a counsel choice", "number 1 is",
                         "the table uses no chance", "the table unlocks nothing", "world moon.base is unknown",
                         "a night needs an `instead`", "one choice is always free",
                         "the report lantern_lost (a lantern that did not come home) is missing",
                         "report.rep.text has no English text", "table.title has no German text"] {
            XCTAssertTrue(all.contains(expected), "the validator reports: \(expected)\n\(all)")
        }
    }

    func testABrokenEntryCostsOnlyItself() {
        let json = """
        {"chapter": 1, "lanterns": [38], "places": [{"id": "a", "kind": "valley", "nights": 1}],
         "errands": [{"id": "broken", "number": 2}, {"id": "fine", "number": 1, "place": "a", "days": [2, 3],
                      "orders": [{"nights": 1, "goes": ["pip"], "report": "r"}]}],
         "reports": [{"id": "r", "speaker": "pip", "text": "t", "choices": []}]}
        """
        let loaded = ErrandCatalog.merge([("errands-x.json", Data(json.utf8))])
        XCTAssertEqual(loaded.catalog.errands.map(\.id), ["fine"])
        XCTAssertEqual(loaded.catalog.reports.map(\.id), ["r"])
        XCTAssertEqual(loaded.problems.count, 1)
        XCTAssertTrue(loaded.problems[0].contains("broken"))
    }

    /// A report choice writes its effect beside its label, and `instead` beside it, as a petition's choice does.
    func testAReportChoiceRoundTrips() throws {
        let choice = ReportChoice(label: "x.c1", effect: PetitionEffect(night: ["brutes-2"], reaction: "x.r1"),
                                  instead: PetitionEffect(happiness: 1))
        let data = try JSONEncoder().encode(choice)
        let object = try XCTUnwrap(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertEqual(Set(object.keys), ["label", "night", "reaction", "instead"])
        XCTAssertEqual(try JSONDecoder().decode(ReportChoice.self, from: data), choice)
    }
}
