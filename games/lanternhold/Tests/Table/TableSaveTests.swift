import Foundation
import XCTest
@testable import Lanternhold

/// The Lantern Table in the dawn save (docs/QUESTS.md 4.1, 4.2): `GameState.table` is optional, so the frozen version
/// 1 save and every realm that never touched the table load and write as before; parties out, their rolls and the
/// waiting reports come back from a save exactly, and a table written before a field existed still loads.
final class TableSaveTests: XCTestCase {
    private let balance = Balance.standard
    private let catalog = ErrandCatalog.standard

    private func load(_ data: Data) -> SaveGame? {
        if case .loaded(let save) = SaveGame.decode(data) { return save }
        return nil
    }

    func testARealmThatNeverTouchedTheTableWritesNoTable() throws {
        let state = GameState.newRealm(seed: 11, balance: balance)
        let json = String(decoding: try SaveGame(state: state).encoded(), as: UTF8.self)
        XCTAssertFalse(json.contains("\"table\""), "no key, as in every save before the table")
    }

    func testTheFrozenVersionOneSaveHasNoTable() throws {
        let save = try XCTUnwrap(load(Data(SaveFixtures.versionOne.utf8)))
        XCTAssertNil(save.state.table)
    }

    /// Parties out (one of them rolled lost), a waiting report and a lost hook come back from the save, and the next
    /// dawn plays the same from the loaded realm as from the one that wrote it.
    func testPartiesOutAndReportsComeBackFromTheSave() throws {
        let lamp = try XCTUnwrap(catalog.errand("beacon_statues")).orders[1]
        var losing: UInt64 = 1
        while !ErrandEngine.roll(losing, errand: "beacon_statues", order: 1, lamp).lost { losing += 1 }
        var s = GameState.newRealm(seed: losing, balance: balance)
        s.day = 2
        s.hour = 9
        s.gold = 200
        XCTAssertNotNil(ErrandEngine.send(&s, errand: "oil_round", order: 0, catalog: catalog, balance: balance))
        s.day = 3
        s.hour = 6
        ErrandEngine.dawn(&s, balance: balance)
        s.hour = 9
        XCTAssertNotNil(ErrandEngine.read(&s, choice: 0, catalog: catalog, balance: balance))
        s.day = 12
        s.flags = ["varn_with"]
        XCTAssertNotNil(ErrandEngine.send(&s, errand: "beacon_statues", order: 1, catalog: catalog, balance: balance))
        XCTAssertEqual(s.table?.out.first?.lost, true)

        let data = try SaveGame(state: s).encoded()
        let back = try XCTUnwrap(load(data))
        XCTAssertTrue(back.state == s, "every field of the table comes back")
        XCTAssertEqual(back.state.table, s.table)
        XCTAssertEqual(try back.encoded(), data, "the same table writes the same bytes")

        var a = s
        var b = back.state
        a.day = 13
        b.day = 13
        a.hour = 6
        b.hour = 6
        ErrandEngine.dawn(&a, balance: balance)
        ErrandEngine.dawn(&b, balance: balance)
        XCTAssertTrue(a == b, "the loaded realm's dawn is the same")
        XCTAssertEqual(b.table?.lantern(38)?.state, .lost, "lantern 38 went out again and did not come home")
        XCTAssertEqual(b.table?.reports.map(\.report), ["lantern_lost"])
    }

    /// A saved table holds report ids this catalogue no longer knows (renamed at the join, say): they never hold the
    /// table up. Nothing is "read first" for them, `read` passes over them, and when the table opens they go, their
    /// lantern back on its hook (a lost one stays lost), with nothing applied or recorded as read.
    func testAReportTheCatalogueNoLongerKnowsDoesNotHoldTheTable() throws {
        var state = GameState.newRealm(seed: 13, balance: balance)
        state.day = 5
        state.hour = 9
        state.gold = 100
        state.flags = ["varn_with"]
        let object = try JSONSerialization.jsonObject(with: try SaveGame(state: state).encoded())
        var save = try XCTUnwrap(object as? [String: Any])
        var realm = try XCTUnwrap(save["state"] as? [String: Any])
        let lanterns: [[String: Any]] = [["number": 38, "state": "back"], ["number": 39],
                                         ["number": 40, "state": "lost"], ["number": 41, "reserved": true]]
        let reports: [[String: Any]] = [
            ["report": "oil_round_v0", "errand": "oil_round", "lantern": 38, "place": "tallowford", "day": 4],
            ["report": "lantern_lost_v0", "errand": "beacon_statues", "lantern": 40, "place": "beacon", "day": 4,
             "lost": true],
        ]
        let saved: [String: Any] = ["chapter": 1, "lanterns": lanterns, "sent": ["beacon_statues"],
                                    "reports": reports]
        realm["table"] = saved
        save["state"] = realm
        let loaded = try XCTUnwrap(load(try JSONSerialization.data(withJSONObject: save))).state
        XCTAssertEqual(loaded.table?.reports.count, 2, "the save keeps what it holds")

        let oil = try XCTUnwrap(catalog.errand("oil_round"))
        let count = try XCTUnwrap(catalog.errand("highcairn_count"))
        let savedTable = try XCTUnwrap(loaded.table)
        XCTAssertNil(ErrandEngine.nextReport(savedTable, catalog: catalog))
        XCTAssertEqual(ErrandEngine.blockers(oil, order: 0, loaded, catalog: catalog), [], "nothing waits to be read")
        XCTAssertEqual(ErrandEngine.blockers(count, order: 0, loaded, catalog: catalog), [])
        var reading = loaded
        XCTAssertNil(ErrandEngine.read(&reading, choice: 0, catalog: catalog, balance: balance))
        XCTAssertTrue(reading == loaded, "a report without a card is never answered")
        var sending = loaded
        XCTAssertEqual(ErrandEngine.send(&sending, errand: "oil_round", order: 0, catalog: catalog,
                                         balance: balance)?.lantern, 39, "38 is not on its hook yet, 40 is gone")

        var opened = loaded
        ErrandEngine.uncover(&opened, catalog: catalog)
        let table = try XCTUnwrap(opened.table)
        XCTAssertEqual(table.reports, [])
        XCTAssertEqual(table.read, [], "nothing was answered")
        XCTAssertEqual(table.lantern(38)?.state, .hook, "its lantern hangs again")
        XCTAssertEqual(table.lantern(40)?.state, .lost, "a lost lantern's hook stays empty for the chapter")
        XCTAssertEqual(table.sent, ["beacon_statues"])
        var rest = opened
        rest.table = loaded.table
        XCTAssertTrue(rest == loaded, "the rest of the realm is untouched")
        XCTAssertEqual(ErrandEngine.send(&opened, errand: "oil_round", order: 0, catalog: catalog,
                                         balance: balance)?.lantern, 38)
        var again = loaded
        XCTAssertEqual(ErrandEngine.tidy(&again, catalog: catalog), 2)
        let tidied = again
        XCTAssertEqual(ErrandEngine.tidy(&again, catalog: catalog), 0)
        XCTAssertTrue(again == tidied, "a tidy table stays as it is")

        // An unknown report before a known one: the known one is read first, and only it holds the table.
        var mixed = loaded
        mixed.table?.lanterns[0].state = .back
        mixed.table?.lanterns[1].state = .back
        mixed.table?.reports = [
            WaitingReport(report: "oil_round_v0", errand: "oil_round", lantern: 38, place: "tallowford", day: 4),
            WaitingReport(report: "oil_round", errand: "oil_round", lantern: 39, place: "tallowford", day: 4),
        ]
        let mixedTable = try XCTUnwrap(mixed.table)
        XCTAssertEqual(ErrandEngine.nextReport(mixedTable, catalog: catalog), 1)
        XCTAssertEqual(ErrandEngine.blockers(count, order: 0, mixed, catalog: catalog), [.reportWaits])
        let outcome = try XCTUnwrap(ErrandEngine.read(&mixed, choice: 0, catalog: catalog, balance: balance))
        XCTAssertEqual(outcome.petition, "oil_round")
        XCTAssertEqual(mixed.table?.reports.map(\.report), ["oil_round_v0"])
        XCTAssertEqual(mixed.table?.lantern(39)?.state, .hook)
        XCTAssertEqual(ErrandEngine.blockers(count, order: 0, mixed, catalog: catalog), [])
    }

    /// A table written before a field existed (here: almost every field) loads with the fields' defaults.
    func testAnOlderTableWithoutNewerFieldsLoads() throws {
        let state = GameState.newRealm(seed: 12, balance: balance)
        let object = try JSONSerialization.jsonObject(with: try SaveGame(state: state).encoded())
        var save = try XCTUnwrap(object as? [String: Any])
        var realm = try XCTUnwrap(save["state"] as? [String: Any])
        realm["table"] = [
            "lanterns": [["number": 38], ["number": 39, "state": "out"]],
            "out": [["errand": "oil_round", "lantern": 39, "sentDay": 2, "homeDay": 3]],
            "reports": [["report": "oil_round"]],
        ]
        save["state"] = realm
        let loaded = try XCTUnwrap(load(try JSONSerialization.data(withJSONObject: save)))
        let table = try XCTUnwrap(loaded.state.table)
        XCTAssertEqual(table.chapter, 1)
        XCTAssertEqual(table.lanterns, [RoadLantern(number: 38), RoadLantern(number: 39, state: .out)])
        XCTAssertEqual(table.sent, [])
        let out = try XCTUnwrap(table.out.first)
        XCTAssertEqual(out.dueDay, 3)
        XCTAssertFalse(out.lost)
        XCTAssertEqual(out.lent, [])
        XCTAssertEqual(out.lostReport, ErrandCatalog.lostReportID)
        XCTAssertEqual(table.reports.first?.lantern, 0)
        XCTAssertNil(table.dawn)
        XCTAssertEqual(table.gone, [], "nobody lost before the field existed")
    }
}
