import Foundation
import XCTest
@testable import Lanternhold

/// Build 3's save rule: a save written by build 2 (TestFlight 1.0.0 build 331, commit 309ebb46) must load and resume in
/// every later build. `Build2Save` holds such a save, written by 309ebb46's own code and frozen. Today's loading path
/// reads it field by field as build 2 wrote it, writes back exactly its own bytes (so no saved field was added or
/// changed), and the game resumes it on day 9 without moving the file aside.
@MainActor
final class Build2SaveTests: XCTestCase {
    private var directory: URL!

    override func setUp() async throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("lanternhold-b2-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    override func tearDown() async throws {
        if let directory { try? FileManager.default.removeItem(at: directory) }
    }

    private var store: SaveStore { SaveStore(directory: directory) }

    /// The frozen bytes through the real load path (`SaveGame.decode`, what `SaveStore.read` calls).
    private func frozen() throws -> SaveGame {
        let load = SaveGame.decode(Build2Save.data)
        guard case .loaded(let save) = load else {
            XCTFail("build 2's save reads as corrupt: \(load)")
            throw Unreadable(reason: "\(load)")
        }
        return save
    }

    private func names() throws -> [String] {
        try FileManager.default.contentsOfDirectory(atPath: directory.path).sorted()
    }

    /// The Chronicle build 2 wrote.
    private var build2Chronicle: Chronicle {
        var records = TrackRecords()
        records.bestNight = 8
        records.creaturesStopped = 346
        records.fallenTotal = 0
        records.nightsWithoutLosses = 8
        var book = Chronicle()
        book.chapter = records
        book.lastCounted = "1:9"
        return book
    }

    private var build2Pacing: AdPacing {
        AdPacing(lastInterstitialDay: 7, lastDoubleTaxesDay: 8, lastSecondChanceNight: 0, merchantTakenDay: 6,
                 lastRewardedDay: 8, lastRewardGivenDay: 8, lastAdAt: 812_345.5)
    }

    func testTheFrozenBytesAreBuild2s() {
        XCTAssertEqual(Build2Save.commit, "309ebb46")
        XCTAssertEqual(Build2Save.data.count, 12158, "the frozen bytes were changed: never regenerate them")
        XCTAssertTrue(Build2Save.json.hasPrefix(#"{"adPacing":{"chapterEndings":[],"lastAdAt":812345.5,"#))
        XCTAssertTrue(Build2Save.json.hasSuffix(#""version":1}"#))
    }

    func testTheSaveAndItsSettingsAndPacing() throws {
        let save = try frozen()
        XCTAssertEqual(save.version, 1)
        XCTAssertEqual(SaveGame.currentVersion, 1, "build 3 keeps version 1")
        XCTAssertEqual(save.mode, .chapter)
        XCTAssertNil(save.track, "build 2's writeSave sets no track")
        XCTAssertNil(save.hintFlags)
        XCTAssertNil(save.dawns)
        XCTAssertEqual(save.countsFor, .chapter)
        XCTAssertEqual(save.continueDay, 9)
        XCTAssertEqual(save.settings, SaveSettings(sound: false, haptics: true))
        XCTAssertEqual(save.adPacing, build2Pacing)
        XCTAssertEqual(save.adPacing?.lastAdAt, 812_345.5)
        XCTAssertEqual(save.adPacing?.chapterEndings, [])
        XCTAssertEqual(save.chronicle, build2Chronicle)
    }

    func testTheRealmsNumbers() throws {
        let s = try frozen().state
        XCTAssertEqual(s.mode, .chapter)
        XCTAssertEqual(s.seed, 1)
        XCTAssertEqual(s.day, 9)
        XCTAssertEqual(s.dawns, 8)
        XCTAssertEqual(s.hour, 6.008333333333137, accuracy: 1e-12)
        XCTAssertEqual(s.simTime, 2304.0999999994224, accuracy: 1e-9)
        XCTAssertEqual(s.gold, 20, "the purse")
        XCTAssertEqual(s.happiness, 80)
        XCTAssertEqual(s.citizens, 24)
        XCTAssertEqual(s.hearth, 100)
        XCTAssertEqual(s.bankEdge, 229.4000000000001, accuracy: 1e-9)
        XCTAssertEqual(s.tax, .normal)
        XCTAssertTrue(s.warTaxUnlocked)
        XCTAssertFalse(s.chapelBlessed)
        XCTAssertFalse(s.beaconLit)
        XCTAssertFalse(s.defeated)
        XCTAssertEqual(s.unheardPetitioners, 0)
        XCTAssertEqual(s.nextID, 360)
        XCTAssertEqual(s.orderCounter, 12)
        XCTAssertEqual(s.lord, LordIdentity(name: "Rosamund", form: .lady))
        XCTAssertEqual(s.king.x, 954)
        XCTAssertEqual(s.king.lightingPlot, -1)
        XCTAssertEqual(s.records.bestNight, 8)
        XCTAssertEqual(s.records.creaturesStopped, 346)
        XCTAssertEqual(s.records.nightsWithoutLosses, 8)
        XCTAssertEqual(s.night.night, 8)
        XCTAssertTrue(s.creatures.isEmpty)
        XCTAssertTrue(s.spawns.isEmpty)
        XCTAssertEqual(s.flags.count, 29)
        XCTAssertTrue(s.flags.contains("varn_with"))
        XCTAssertTrue(s.flags.contains("war_tax_promised"))
        XCTAssertTrue(s.flags.contains("sergeant_joined"))
    }

    func testThePeopleAndThePlots() throws {
        let s = try frozen().state
        XCTAssertEqual(s.soldiers.map(\.name),
                       ["Varo", "Davor", "Per", "Finn", "Jory", "Zoran", "Hamon", "Wendel", "Hedda", "Nolan"])
        XCTAssertEqual(s.soldiers.filter { $0.kind == .archer }.count, 7)
        XCTAssertEqual(s.soldiers.filter { $0.kind == .guardsman }.count, 3)
        XCTAssertEqual(s.builders.count, 2)
        XCTAssertEqual(Realm.plots.count, s.plots.count, "build 2 wrote every plot of its realm")
        let items: [String?] = ["gate", "archerTower", "brazier", "brazier", nil, "stakePit", "stoneWall", nil, "brazier",
                                "brazier", nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, "bigHouse", "field",
                                "bigHouse", "house", "house", nil, nil, "field", nil, nil, nil]
        XCTAssertEqual(s.plots.prefix(items.count).map { $0.item?.rawValue }, items)
        XCTAssertEqual(s.buildingsBuilt, 9)
    }

    func testTheCourtAndTheCraft() throws {
        let s = try frozen().state
        let court = try XCTUnwrap(s.court)
        XCTAssertEqual(court.heardCount, 23)
        XCTAssertEqual(court.heard.count, 23)
        XCTAssertTrue(court.heard.contains("war_tax"))
        XCTAssertEqual(court.history.first?.id, "first_plough")
        XCTAssertEqual(court.queueDay, 9)
        XCTAssertEqual(court.queue.map(\.id), ["odile_ledger", "lantern_lanes", "ludo_tourney", "craft_fletcher_again"])
        XCTAssertEqual(court.world, ["castle.seren.lantern", "town.lanterns.extra", "town.market.stall",
                                     "town.scarecrow", "town.well.repaired"])
        let craft = try XCTUnwrap(s.craft)
        XCTAssertEqual(craft.checkedDay, 9)
        XCTAssertEqual(craft.slotDay, 7)
        XCTAssertEqual(craft.met.count, 1)
        XCTAssertEqual(craft.met.first?.id, "fletcher")
        XCTAssertEqual(craft.met.first?.day, 5)
        XCTAssertEqual(craft.met.first?.answer, .waiting)
        XCTAssertEqual(craft.met.first?.returnDay, 9)
        XCTAssertEqual(craft.met.first?.returned, true)
        XCTAssertTrue(craft.works.isEmpty)
    }

    func testTheTownAndTheTable() throws {
        let s = try frozen().state
        let town = try XCTUnwrap(s.town)
        let today = try XCTUnwrap(town.today)
        XCTAssertEqual(today.day, 9)
        XCTAssertEqual(today.places.map(\.plot), [21, 22, 23, 24, 25, 28])
        XCTAssertEqual(today.places.map(\.owed), [25, 5, 24, 12, 12, 5])
        XCTAssertFalse(today.places.contains { $0.collected }, "nothing collected yet on day 9")
        XCTAssertFalse(today.closed)
        XCTAssertEqual(town.yesterday?.day, 8)
        XCTAssertEqual(town.yesterday?.closed, true)
        let table = try XCTUnwrap(s.table)
        XCTAssertEqual(table.chapter, 1)
        XCTAssertEqual(table.sent, ["mill_herbs", "oil_round"])
        XCTAssertTrue(table.out.isEmpty)
        XCTAssertEqual(table.read.map(\.errand), ["oil_round"])
        XCTAssertEqual(table.reports.map(\.errand), ["mill_herbs"])
        XCTAssertEqual(table.reports.first?.lantern, 38)
        XCTAssertEqual(table.reports.first?.day, 8)
        XCTAssertEqual(table.lanterns.map(\.number), [38, 39, 40, 41])
        XCTAssertEqual(table.lanterns.first?.state, .back)
        XCTAssertEqual(table.dawn?.day, 8)
    }

    func testTheFrontTheHearthAndTheGorge() throws {
        let s = try frozen().state
        let front = try XCTUnwrap(s.front)
        XCTAssertEqual(front.lastRelight?.plot, 8)
        XCTAssertEqual(front.relightCooldown, 0)
        let fire = try XCTUnwrap(s.hearthFire)
        XCTAssertEqual(fire.level, .bright)
        let gorge = try XCTUnwrap(s.gorge)
        XCTAssertEqual(gorge.heldAtDawn, 1)
        XCTAssertEqual(gorge.sites.map(\.state), [.lit, .wild, .wild, .wild])
        XCTAssertEqual(gorge.sites.first?.strength, 600)
        XCTAssertFalse(gorge.watchtowerRaised)
        XCTAssertEqual(Gorge.held(s), 1)
        let report = try XCTUnwrap(s.lastReport)
        XCTAssertEqual(report.day, 9)
        XCTAssertEqual(report.night, 8)
        XCTAssertEqual(report.creaturesStopped, 53)
        XCTAssertTrue(report.fallen.isEmpty)
        XCTAssertEqual(report.goldAfter, 20)
        XCTAssertEqual(report.citizensAfter, 24)
        XCTAssertEqual(report.grown, 2)
        XCTAssertEqual(report.taxes.taxPart, 73)
        XCTAssertEqual(report.town?.tossGold, 76)
        XCTAssertEqual(report.front?.relit, 1)
        XCTAssertEqual(report.gorge?.held, 1)
        XCTAssertEqual(report.hearth?.after, .bright)
    }

    /// Load, save, load: the same save, and the same bytes as build 2 wrote (a field added, renamed or changed in any
    /// saved type would show here).
    func testLoadSaveLoadIsTheSameSaveAndTheSameBytes() throws {
        let first = try frozen()
        let written = try first.encoded()
        let load = SaveGame.decode(written)
        guard case .loaded(let second) = load else {
            XCTFail("today's own save of build 2's realm reads as corrupt: \(load)")
            return
        }
        XCTAssertTrue(second == first, "every field comes back")
        XCTAssertTrue(second.state == first.state)
        XCTAssertEqual(written, Build2Save.data, "today writes back build 2's bytes exactly")
    }

    /// The game launches on build 2's file: it resumes day 9 as it was, moves nothing aside, carries settings, pacing
    /// and the Chronicle, and its next save is build 2's bytes again.
    func testTheGameResumesBuild2sSave() throws {
        try Build2Save.data.write(to: store.fileURL)
        let expected = try frozen()

        let game = GameModel(args: DebugArgs(values: [:]), kind: .world, store: store)
        let driver = try XCTUnwrap(game.driver, "the game runs")
        XCTAssertEqual(driver.state.day, 9, "day 9 resumes")
        XCTAssertEqual(driver.state.dawns, 8)
        XCTAssertEqual(driver.state.gold, 20)
        XCTAssertEqual(driver.state.seed, 1)
        XCTAssertEqual(driver.state.lord, LordIdentity(name: "Rosamund", form: .lady))
        XCTAssertNotNil(driver.state.town)
        XCTAssertTrue(driver.dawnSnapshot == expected.state, "the dawn snapshot is build 2's realm")
        XCTAssertNotEqual(game.overlay, .lordEntry, "no name entry: the lord is known")
        XCTAssertEqual(game.settings, SaveSettings(sound: false, haptics: true))
        XCTAssertEqual(game.adPacing, build2Pacing)
        XCTAssertEqual(try names(), [Build2Save.fileName], "nothing moved aside, nothing called corrupt")
        XCTAssertEqual(try Data(contentsOf: store.fileURL), Build2Save.data, "the launch writes nothing")

        game.saveNow()
        XCTAssertEqual(try Data(contentsOf: store.fileURL), Build2Save.data, "the next save is build 2's bytes again")
        XCTAssertEqual(store.read(), SaveLoad.loaded(expected))
    }
}

/// The frozen bytes did not load.
private struct Unreadable: Error {
    let reason: String
}
