import Foundation
import XCTest
@testable import Lanternhold

/// The dawn save (DESIGN.md "Progression and saving"): round trip, newer fields ignored, older saves, corrupt files.
final class SaveGameTests: XCTestCase {
    private let balance = Balance.standard

    private func midChapter() -> (GameState, Autoplay) {
        var s = GameState.newRealm(seed: 0xDEAD_BEEF_1234_5678, balance: balance)
        var bot = Autoplay.reference()
        for _ in 0..<3 { Sim.runToDawn(&s, balance: balance, bot: &bot) }
        return (s, bot)
    }

    private func load(_ data: Data) -> SaveGame? {
        if case .loaded(let save) = SaveGame.decode(data) { return save }
        return nil
    }

    private func text(_ data: Data) -> String {
        String(decoding: data, as: UTF8.self)
    }

    func testARoundTripGivesTheSameRealm() throws {
        let (state, _) = midChapter()
        XCTAssertNotNil(state.lastReport)
        let save = SaveGame(state: state, settings: SaveSettings(sound: false, haptics: true), adPacing: AdPacing(),
                            hintFlags: ["walk", "build"])
        let data = try save.encoded()
        let back = try XCTUnwrap(load(data))
        XCTAssertEqual(back.version, SaveGame.currentVersion)
        XCTAssertEqual(back.mode, .chapter)
        XCTAssertTrue(back.state == state, "every field comes back")
        XCTAssertTrue(back == save)
        XCTAssertEqual(try back.encoded(), data, "the same state writes the same bytes")
        XCTAssertEqual(back.continueDay, 4)
        XCTAssertEqual(back.state.rng, state.rng, "the random stream goes on where it stopped")
        XCTAssertEqual(back.state.seed, 0xDEAD_BEEF_1234_5678)
    }

    func testUnknownFieldsOfNewerVersionsAreIgnored() throws {
        let (state, _) = midChapter()
        var json = text(try SaveGame(state: state).encoded())
        XCTAssertTrue(json.hasPrefix("{"))
        json = "{\"futureField\":{\"anything\":[1,2]}," + json.dropFirst()
        XCTAssertTrue(json.contains("\"state\":{"))
        json = json.replacingOccurrences(of: "\"state\":{", with: "\"state\":{\"weatherOfTomorrow\":\"rain\",")
        json = json.replacingOccurrences(of: "\"version\":1", with: "\"version\":7")
        let back = try XCTUnwrap(load(Data(json.utf8)))
        XCTAssertEqual(back.version, 7)
        XCTAssertTrue(back.state == state)
    }

    func testAnOlderSaveWithoutOptionalFieldsLoads() throws {
        var (state, _) = midChapter()
        state.lastReport = nil
        let json = text(try SaveGame(state: state).encoded())
        XCTAssertFalse(json.contains("\"settings\""), "nil fields are left out, as in a save from before they existed")
        XCTAssertFalse(json.contains("\"lastReport\""))
        let back = try XCTUnwrap(load(Data(json.utf8)))
        XCTAssertNil(back.settings)
        XCTAssertNil(back.hintFlags)
        XCTAssertNil(back.adPacing)
        XCTAssertNil(back.state.lastReport)
        XCTAssertTrue(back.state == state)
    }

    func testACorruptFileIsReportedAsCorrupt() throws {
        let (state, _) = midChapter()
        let data = try SaveGame(state: state).encoded()
        let zero = text(data).replacingOccurrences(of: "\"version\":1", with: "\"version\":0")
        let missingGold = text(data).replacingOccurrences(of: "\"gold\":", with: "\"golden\":")
        let samples: [Data] = [
            Data("not a save".utf8),
            data.prefix(data.count / 2),
            Data("{\"version\": 1}".utf8),
            Data(),
            Data(zero.utf8),
            Data(missingGold.utf8),
        ]
        for (index, sample) in samples.enumerated() {
            guard case .corrupt = SaveGame.decode(sample) else {
                XCTFail("sample \(index) should be reported as corrupt")
                continue
            }
        }
    }

    /// The frozen version 1 save (`SaveFixtures`) loads with every value, and the fields added since read as absent.
    func testTheFrozenVersionOneSaveStillLoads() throws {
        let decoded = SaveGame.decode(Data(SaveFixtures.versionOne.utf8))
        if case .corrupt(let reason) = decoded { XCTFail("the version 1 save no longer loads: \(reason)") }
        let save = try XCTUnwrap(load(Data(SaveFixtures.versionOne.utf8)))
        XCTAssertEqual(save.version, 1)
        XCTAssertEqual(save.mode, .chapter)
        XCTAssertEqual(save.continueDay, 4)
        XCTAssertNil(save.track)
        XCTAssertNil(save.chronicle)
        XCTAssertEqual(save.countsFor, .chapter)
        XCTAssertEqual(save.settings, SaveSettings(sound: true, haptics: false))
        XCTAssertEqual(save.adPacing?.lastDoubleTaxesDay, 2)
        XCTAssertEqual(save.hintFlags, ["walk"])
        let state = save.state
        XCTAssertEqual(state.seed, 4242)
        XCTAssertEqual(state.rng.state, 9_876_543_210_123_456_789, "the random stream as text, all 64 bits")
        XCTAssertEqual(state.gold, 37)
        XCTAssertEqual(state.plots.count, Realm.plots.count)
        XCTAssertEqual(state.plots[0].item, .gate)
        XCTAssertEqual(state.plots[0].hp, 3650.5)
        XCTAssertEqual(state.plots[6].job?.target, .stoneWall)
        XCTAssertEqual(state.plots[6].job?.order, 9)
        XCTAssertTrue(state.plots[3].snuffed)
        XCTAssertEqual(state.builders.map { $0.task }, [.idle, .walking])
        XCTAssertEqual(state.soldiers.map { $0.name }, ["Aldric", "Brenna", "Corwin", "Dagny", "Edwin", "Ffion"])
        XCTAssertEqual(state.soldiers[2].state, .posted)
        XCTAssertEqual(state.creatures.first?.action, .perching)
        XCTAssertEqual(state.projectiles.first?.target, 11)
        XCTAssertEqual(state.glows.first?.kind, .fireArrow)
        XCTAssertEqual(state.spawns.first?.kind, .sootling)
        XCTAssertEqual(state.night.wallFallSeconds, [61.5])
        XCTAssertEqual(state.night.hearthFirstHitSecond, 88.25)
        XCTAssertNil(state.night.defeatHour)
        XCTAssertEqual(state.records.creaturesStopped, 101)
        let report = try XCTUnwrap(state.lastReport)
        XCTAssertEqual(report.taxes.total, 58)
        XCTAssertEqual(report.happinessChanges, [HappinessChange(reason: .fallen, delta: -3)])
        XCTAssertNil(report.realmFell)
        XCTAssertTrue(report.held)
        XCTAssertNil(report.kingSlain, "saved before the field: the King was not slain")
        XCTAssertFalse(report.slewTheKing)
        XCTAssertNil(state.night.kingLeftSecond)
        XCTAssertNil(state.night.kingSlainSecond)
        XCTAssertFalse(state.night.kingSlain)
        XCTAssertNil(state.night.kingLightLeft)
        XCTAssertNil(SaveGame.indexProblem(state))
        let again = try XCTUnwrap(load(try save.encoded()))
        XCTAssertTrue(again == save, "it writes back what it read")
    }

    private func editedFixture(_ change: (inout [String: Any]) -> Void) throws -> Data {
        let object = try JSONSerialization.jsonObject(with: Data(SaveFixtures.versionOne.utf8))
        var save = try XCTUnwrap(object as? [String: Any])
        var state = try XCTUnwrap(save["state"] as? [String: Any])
        change(&state)
        save["state"] = state
        return try JSONSerialization.data(withJSONObject: save)
    }

    /// A save with fewer plots (from before a plot was added) gets the missing ones as on day 1; more plots than the
    /// realm has, or a plot index out of range, is corrupt instead of a crash later.
    func testPlotCountsAndIndicesAreCheckedOnLoad() throws {
        let short = try editedFixture { state in
            let plots = state["plots"] as? [Any] ?? []
            state["plots"] = Array(plots.prefix(20))
        }
        let padded = try XCTUnwrap(load(short))
        XCTAssertEqual(padded.state.plots.count, Realm.plots.count)
        XCTAssertEqual(padded.state.plots[6].item, .palisade, "the saved plots stay as they were")
        XCTAssertEqual(padded.state.plots[Realm.townPlots[0]].item, .house, "a missing prebuilt plot comes back")
        XCTAssertNil(padded.state.plots[Realm.townPlots[1]].item)

        let long = try editedFixture { state in
            var plots = state["plots"] as? [Any] ?? []
            plots.append(plots[0])
            state["plots"] = plots
        }
        let broken: [Data] = [
            long,
            try editedFixture { state in
                var soldiers = state["soldiers"] as? [[String: Any]] ?? []
                soldiers[0]["postPlot"] = 40
                state["soldiers"] = soldiers
            },
            try editedFixture { state in
                var builders = state["builders"] as? [[String: Any]] ?? []
                builders[1]["plot"] = Realm.plots.count
                state["builders"] = builders
            },
            try editedFixture { state in
                var creatures = state["creatures"] as? [[String: Any]] ?? []
                creatures[0]["target"] = -2
                state["creatures"] = creatures
            },
            try editedFixture { state in
                var king = state["king"] as? [String: Any] ?? [:]
                king["lightingPlot"] = 99
                state["king"] = king
            },
        ]
        for (index, sample) in broken.enumerated() {
            guard case .corrupt = SaveGame.decode(sample) else {
                XCTFail("sample \(index) should be reported as corrupt")
                continue
            }
        }
    }

    /// The Chronicle keeps records per track beside the snapshot, so a new realm keeps them; a dawn counts once; a
    /// night saved by a second chance is not a night held.
    func testTheChronicleKeepsRecordsPerTrackAcrossRealms() throws {
        let (state, _) = midChapter()
        let report = try XCTUnwrap(state.lastReport)
        var save = SaveGame(state: state)
        save.countDawn()
        save.countDawn()
        let chapter = try XCTUnwrap(save.chronicle?.records(.chapter))
        XCTAssertEqual(chapter.bestNight, 3)
        XCTAssertEqual(chapter.creaturesStopped, report.creaturesStopped, "the same dawn counts once")
        XCTAssertEqual(chapter.nightsWithoutLosses, report.noLosses ? 1 : 0)

        var fresh = GameState.newRealm(seed: 99, balance: balance, mode: .endless)
        var bot = Autoplay.reference()
        Sim.runToDawn(&fresh, balance: balance, bot: &bot)
        var next = SaveGame(state: fresh, track: .endlessNew, chronicle: save.chronicle)
        next.countDawn()
        let back = try XCTUnwrap(load(try next.encoded()))
        XCTAssertEqual(back.countsFor, .endlessNew)
        XCTAssertEqual(back.chronicle?.records(.chapter), chapter, "a new realm keeps the chapter's records")
        XCTAssertEqual(back.chronicle?.records(.endlessNew).bestNight, 1)
        XCTAssertEqual(back.chronicle?.records(.endlessContinued), TrackRecords())

        var lost = report
        lost.realmFell = true
        var book = Chronicle()
        book.count(lost, track: .chapter, seed: 1)
        XCTAssertEqual(book.records(.chapter).bestNight, 0)
        XCTAssertEqual(book.records(.chapter).creaturesStopped, report.creaturesStopped)
    }

    func testPlayingOnFromALoadedSaveMatchesPlayingStraightOn() throws {
        let (state, bot) = midChapter()
        let back = try XCTUnwrap(load(try SaveGame(state: state).encoded()))
        var straight = state
        var loaded = back.state
        var botA = bot
        var botB = bot
        for _ in 0..<2 {
            Sim.runToDawn(&straight, balance: balance, bot: &botA)
            Sim.runToDawn(&loaded, balance: balance, bot: &botB)
        }
        XCTAssertTrue(straight == loaded, "the save keeps everything the realm needs")
    }
}
