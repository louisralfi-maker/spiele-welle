import Foundation
import XCTest
@testable import Lanternhold

/// The game's debug launch arguments (M2b, DESIGN.md "Debug launch arguments"): parsing, and the starts they ask for
/// (`GameStart`): a day's morning or a night's 20:00 played by the seeded headless reference bot, the demo build, the
/// numbers, the save.
final class GameStartTests: XCTestCase {
    private let balance = Balance.standard

    func testTheGameArgumentsParse() {
        let args = DebugArgs(values: [
            "GWScene": "probe", "GWDay": "12", "GWNight": "7", "GWBuild": "demo", "GWAutoplay": "play",
            "GWGold": "250", "GWHappiness": "140", "GWReset": "YES",
        ])
        XCTAssertEqual(args.scene, "probe")
        XCTAssertEqual(args.day, 12)
        XCTAssertEqual(args.night, 7)
        XCTAssertEqual(args.build, .demo)
        XCTAssertEqual(args.autoplay, .play)
        XCTAssertEqual(args.gold, 250)
        XCTAssertEqual(args.happiness, 100, "clamped to 0 ... 100")
        XCTAssertTrue(args.reset)
        let defaults = DebugArgs(values: [:])
        XCTAssertNil(defaults.day)
        XCTAssertNil(defaults.night)
        XCTAssertNil(defaults.build)
        XCTAssertNil(defaults.gold)
        XCTAssertNil(defaults.happiness)
        XCTAssertFalse(defaults.reset)
    }

    func testMalformedGameArgumentsKeepTheDefaults() {
        let args = DebugArgs(values: [
            "GWDay": "0", "GWNight": "-3", "GWBuild": "castle", "GWGold": "-5", "GWHappiness": "-20", "GWReset": "NO",
        ])
        XCTAssertNil(args.day)
        XCTAssertNil(args.night)
        XCTAssertNil(args.build)
        XCTAssertNil(args.gold)
        XCTAssertEqual(args.happiness, 0)
        XCTAssertFalse(args.reset)
        XCTAssertEqual(DebugArgs(values: ["GWNight": "twelve"]).night, nil)
        XCTAssertTrue(DebugArgs.keys.contains("GWNight"))
        XCTAssertTrue(DebugArgs.keys.contains("GWBuild"))
    }

    func testADayStartsAtThatMorning() {
        let start = GameStart.realm(args: DebugArgs(values: ["GWDay": "3", "GWSeed": "5"]), saved: nil)
        XCTAssertEqual(start.state.day, 3)
        XCTAssertEqual(start.state.hour, 6, accuracy: 0.05)
        XCTAssertEqual(start.state.seed, 5)
        XCTAssertTrue(start.dawn == start.state, "the morning is the dawn snapshot")
        XCTAssertGreaterThan(start.state.buildingsBuilt, 2, "the reference bot built")
        XCTAssertNotNil(start.state.lastReport, "two nights played")
        XCTAssertGreaterThan(start.bot.cursor, 0, "the bot hands over where it stopped in its order")
    }

    func testANightStartsAtNightfall() {
        let start = GameStart.realm(args: DebugArgs(values: ["GWNight": "2", "GWSeed": "5"]), saved: nil)
        XCTAssertEqual(start.state.day, 2)
        XCTAssertEqual(start.state.hour, 20, accuracy: 0.02)
        XCTAssertEqual(start.dawn.day, 2)
        XCTAssertEqual(start.dawn.hour, 6, accuracy: 0.05)
        // The first live step crosses nightfall if the headless run stopped a hair before it.
        var s = start.state
        var events: [SimEvent] = []
        Sim.step(&s, dt: Sim.frameStep, balance: balance, events: &events)
        XCTAssertFalse(s.spawns.isEmpty && s.creatures.isEmpty, "the night's waves are planned")
        XCTAssertEqual(DayClock.phase(at: s.hour), .night)
    }

    func testTheDemoBuildsARealmForScreenshots() {
        let night = GameStart.realm(args: DebugArgs(values: ["GWNight": "12", "GWBuild": "demo"]), saved: nil).state
        func item(_ key: String) -> BuildItem? { night.plots[Realm.plotID(key) ?? 0].item }
        XCTAssertEqual(item("l2.wall"), .stoneWall)
        XCTAssertEqual(item("l3.wall"), .stoneWall)
        XCTAssertEqual(item("l1.wall"), .ironGate)
        XCTAssertEqual(item("l2.tower"), .watchtower)
        XCTAssertEqual(item("l3.engine"), .catapult)
        XCTAssertEqual(item("l2.engine"), .ballista)
        XCTAssertEqual(item("l3.trap"), .stakePit)
        XCTAssertEqual(night.beaconStage, 2)
        XCTAssertEqual(item("castle.smithy"), .smithy)
        XCTAssertEqual(item("castle.lodge"), .lodge)
        XCTAssertEqual(item("town.market.6"), .market)
        XCTAssertEqual(night.count(.fireTower), 2)
        XCTAssertGreaterThanOrEqual(night.archerCount, 14)
        XCTAssertGreaterThanOrEqual(night.guardCount, 4)
        XCTAssertGreaterThanOrEqual(night.soldiers.filter { $0.state == .posted }.count, 12,
                                    "at night the archers stand on their posts at once")
        XCTAssertTrue(night.plots.allSatisfy { $0.job == nil }, "no scaffolding in the night shots")
        XCTAssertEqual(night.builders.count, balance.buildersLodge)

        let day = GameStart.realm(args: DebugArgs(values: ["GWDay": "12", "GWBuild": "demo"]), saved: nil).state
        XCTAssertNotNil(day.plots[Realm.beaconPlot].job, "the third stage is being raised")
        XCTAssertNotNil(day.plots[Realm.lines[2].tower].job)
        XCTAssertTrue(day.builders.allSatisfy { $0.task == .building }, "the builders are at work")
        var s = day
        var events: [SimEvent] = []
        let before = s.plots[Realm.beaconPlot].job?.work ?? 0
        for _ in 0..<60 {
            Sim.step(&s, dt: Sim.frameStep, balance: balance, events: &events)
        }
        XCTAssertGreaterThan(s.plots[Realm.beaconPlot].job?.work ?? 0, before, "and they really build")
    }

    func testNumbersCameraAndTheSave() {
        let args = DebugArgs(values: ["GWGold": "321", "GWHappiness": "12", "GWCameraX": "640"])
        let start = GameStart.realm(args: args, saved: nil)
        XCTAssertEqual(start.state.gold, 321)
        XCTAssertEqual(start.state.happiness, 12)
        XCTAssertEqual(start.state.king.x, 640)
        XCTAssertEqual(start.state.day, 1, "a new realm")

        var saved = GameState.newRealm(seed: 9)
        saved.day = 5
        saved.gold = 77
        let resumed = GameStart.realm(args: DebugArgs(values: [:]), saved: saved)
        XCTAssertEqual(resumed.state.day, 5, "the save's last dawn resumes")
        XCTAssertEqual(resumed.state.gold, 77)
        let fresh = GameStart.realm(args: DebugArgs(values: ["GWReset": "YES"]), saved: saved)
        XCTAssertEqual(fresh.state.day, 1, "-GWReset starts afresh")
        let debugStart = GameStart.realm(args: DebugArgs(values: ["GWDay": "2"]), saved: saved)
        XCTAssertEqual(debugStart.state.day, 2, "a debug start ignores the save")
        XCTAssertNotEqual(debugStart.state.seed, 9)
    }

    func testTheSaveStoreWritesReadsAndKeepsACorruptFile() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("lanternhold-save-\(UUID().uuidString)", isDirectory: true)
        let store = SaveStore(directory: directory)
        defer { try? FileManager.default.removeItem(at: directory) }
        XCTAssertNil(store.read(), "no save yet")
        var state = GameState.newRealm(seed: 21)
        state.gold = 99
        try store.write(SaveGame(state: state))
        guard case .loaded(let save)? = store.read() else {
            return XCTFail("the save reads back")
        }
        XCTAssertEqual(save.state.gold, 99)
        try Data("not a save".utf8).write(to: store.fileURL)
        guard case .corrupt? = store.read() else {
            return XCTFail("garbage is reported as corrupt")
        }
        store.keepCorrupt()
        XCTAssertNil(store.read(), "the corrupt file moved aside")
        let names = try FileManager.default.contentsOfDirectory(atPath: directory.path)
        XCTAssertTrue(names.contains { $0.hasPrefix("save-corrupt-") }, "kept as a backup")
        try store.write(SaveGame(state: state))
        store.reset()
        XCTAssertNil(store.read(), "-GWReset removes the save")
    }
}
