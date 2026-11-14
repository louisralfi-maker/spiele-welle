import Foundation
import XCTest
@testable import Lanternhold

/// The driver's new moves for the UI (M2b part 2): walking to a tap on the realm strip, the second chance, replaying
/// the day, restarting; the new debug arguments (`-GWTimeScale`, `-GWHour`, `-GWScreen`, `-GWSkipOnboarding`).
final class DriverMovesTests: XCTestCase {
    private let balance = Balance.standard

    func testATapOnTheStripWalksTheKingThereAndADragCancelsIt() {
        var driver = SimDriver(state: GameState.newRealm(seed: 3), balance: balance)
        var events: [SimEvent] = []
        driver.travel(to: 1500)
        XCTAssertEqual(driver.travelTarget, 1500)
        for _ in 0..<40 {
            driver.advance(by: 0.25, events: &events)
        }
        XCTAssertEqual(driver.state.king.x, 1500, accuracy: 1e-9, "he stops exactly there")
        XCTAssertNil(driver.travelTarget)
        XCTAssertEqual(driver.state.king.velocity, 0)
        driver.travel(to: 9000)
        XCTAssertEqual(driver.travelTarget, Realm.walkEnd, "inside his walk")
        driver.advance(by: 0.25, events: &events)
        XCTAssertEqual(driver.state.king.velocity, balance.kingRunSpeed, "he runs")
        driver.setDrag(offset: -20)
        XCTAssertNil(driver.travelTarget, "a drag cancels the walk")
        XCTAssertEqual(driver.state.king.velocity, -balance.kingWalkSpeed)
        var bot = SimDriver(state: GameState.newRealm(seed: 3), balance: balance, bot: Autoplay.reference())
        bot.travel(to: 900)
        XCTAssertNil(bot.bot, "a tap on the strip ends autoplay")
    }

    func testReplayAndRestart() {
        var s = GameState.newRealm(seed: 3)
        var bot = Autoplay.reference()
        Sim.runToDawn(&s, balance: balance, bot: &bot)
        var driver = SimDriver(state: s, balance: balance)
        var events: [SimEvent] = []
        for _ in 0..<200 {
            driver.advance(by: 0.25, events: &events)
        }
        XCTAssertGreaterThan(driver.state.hour, 9)
        driver.replayDay()
        XCTAssertEqual(driver.state, driver.dawnSnapshot)
        XCTAssertEqual(driver.state.day, 2)
        XCTAssertEqual(driver.state.hour, 6, accuracy: 0.01, "the dawn's step overshoots 06:00 by at most one step")
        driver.restart(seed: 77)
        XCTAssertEqual(driver.state.day, 1)
        XCTAssertEqual(driver.state.seed, 77)
        XCTAssertEqual(driver.state.gold, balance.startGold)
        XCTAssertEqual(driver.dawnSnapshot, driver.state)
    }

    func testTheNewArgumentsParse() {
        let args = DebugArgs(values: ["GWTimeScale": "4", "GWHour": "5.8", "GWScreen": "Report",
                                      "GWSkipOnboarding": "YES"])
        XCTAssertEqual(args.timeScale, 4)
        XCTAssertEqual(args.hour ?? -1, 5.8, accuracy: 1e-12)
        XCTAssertEqual(args.screen, .report)
        XCTAssertTrue(args.skipOnboarding)
        XCTAssertEqual(DebugArgs(values: ["GWTimeScale": "100"]).timeScale, 20)
        XCTAssertEqual(DebugArgs(values: ["GWTimeScale": "0"]).timeScale, 1)
        XCTAssertEqual(DebugArgs(values: ["GWTimeScale": "fast"]).timeScale, 1)
        XCTAssertNil(DebugArgs(values: ["GWHour": "30"]).hour)
        XCTAssertEqual(DebugArgs(values: ["GWScreen": "finale"]).screen, .finale)
        XCTAssertEqual(DebugArgs(values: ["GWScreen": "defeat"]).screen, .defeat)
        XCTAssertNil(DebugArgs(values: ["GWScreen": "credits"]).screen)
        let defaults = DebugArgs(values: [:])
        XCTAssertEqual(defaults.timeScale, 1)
        XCTAssertNil(defaults.hour)
        XCTAssertNil(defaults.screen)
        XCTAssertFalse(defaults.skipOnboarding)
        for key in ["GWTimeScale", "GWHour", "GWScreen", "GWSkipOnboarding"] {
            XCTAssertTrue(DebugArgs.keys.contains(key), key)
        }
    }

    func testAnHourPlaysOnFromTheStart() {
        let night = GameStart.realm(args: DebugArgs(values: ["GWNight": "3", "GWHour": "2", "GWSeed": "5"]),
                                    saved: nil)
        XCTAssertEqual(night.state.day, 3)
        XCTAssertEqual(night.state.hour, 2, accuracy: 0.02)
        XCTAssertEqual(night.dawn.day, 3, "no dawn on the way: the snapshot stays the morning of day 3")
        let morning = GameStart.realm(args: DebugArgs(values: ["GWNight": "2", "GWHour": "7", "GWSeed": "5"]),
                                      saved: nil)
        XCTAssertEqual(morning.state.day, 3)
        XCTAssertEqual(morning.state.hour, 7, accuracy: 0.02)
        XCTAssertEqual(morning.dawn.day, 3, "the dawn on the way renews the snapshot")
        XCTAssertEqual(morning.dawn.hour, 6, accuracy: 0.02)
        XCTAssertNotNil(morning.dawn.lastReport)
        XCTAssertEqual(GameStart.gap(from: 20, to: 6), 10, accuracy: 1e-9)
        XCTAssertEqual(GameStart.gap(from: 6, to: 6), 24, accuracy: 1e-9)
        let dawnHour = GameStart.realm(args: DebugArgs(values: ["GWNight": "2", "GWHour": "6", "GWSeed": "5"]),
                                       saved: nil)
        XCTAssertEqual(dawnHour.state.day, 3, "a run to 06:00 ends at the dawn report")
        XCTAssertEqual(dawnHour.state.hour, 6, accuracy: 0.02)
        let same = GameStart.realm(args: DebugArgs(values: ["GWDay": "2", "GWHour": "6", "GWSeed": "5"]), saved: nil)
        XCTAssertEqual(same.state.day, 2, "the hour it already shows: nothing to play")
    }
}

/// The screen state machine of `GameModel` (M2b part 2, DESIGN.md "Screens"): the action button opens the cards, the
/// cards act through the simulation, the simulation pauses under every screen, the dawn brings the report, the defeat
/// card's two ways out, the pause sheet. Each test starts a fresh realm (`-GWReset YES`).
@MainActor
final class GameScreensTests: XCTestCase {
    /// A temporary save directory per test (M2b review: the tests deleted and overwrote the simulator app's real save).
    private var directory: URL!

    override func setUp() async throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("lanternhold-tests-\(UUID().uuidString)", isDirectory: true)
    }

    override func tearDown() async throws {
        if let directory { try? FileManager.default.removeItem(at: directory) }
    }

    private func model(_ values: [String: String], reset: Bool = true) -> GameModel {
        var all = values
        if reset { all["GWReset"] = "YES" }
        // The lord pass: a fresh realm would open on the name entry (`LordEntryTests` covers it).
        if all["GWSkipOnboarding"] == nil { all["GWSkipOnboarding"] = "YES" }
        return GameModel(args: DebugArgs(values: all), kind: .world, store: SaveStore(directory: directory))
    }

    func testTheSettingsAndTheSecondChanceSurviveARelaunch() throws {
        // DESIGN.md: the sound and haptics switches and the second chance's pacing are kept in the save.
        let first = model(["GWScreen": "defeat"])
        XCTAssertNil(try XCTUnwrap(first.defeatInfo).secondChanceFrom, "the first second chance is free")
        first.takeSecondChance()
        first.continueReport()
        first.openPause()
        first.setSound(false)
        first.resume()
        let second = model(["GWScreen": "defeat"], reset: false)
        XCTAssertFalse(second.settings.sound, "the sound switch came back from the save")
        XCTAssertEqual(second.day, 2, "the relaunch resumed the saved realm at its dawn")
        XCTAssertEqual(try XCTUnwrap(second.defeatInfo).secondChanceFrom, 1 + GameModel.secondChanceGap,
                       "the second chance taken on night 1 waits five nights, across a relaunch")
    }

    func testTheHammerOpensTheBuildCardAndTheOrderGoesThroughTheSimulation() throws {
        let game = model(["GWCameraX": "1255"])
        let plot = Realm.lines[0].braziers[0]
        XCTAssertEqual(game.target, .build(plot: plot))
        XCTAssertEqual(game.gold, 60)
        game.performAction()
        XCTAssertEqual(game.overlay, .build(plot: plot))
        XCTAssertTrue(game.isPaused, "nothing steps while a card is open")
        XCTAssertNil(game.target, "the button hides under the card")
        let card = try XCTUnwrap(game.buildCard)
        XCTAssertEqual(card.options.map(\.item), [.brazier])
        let hour = game.driver?.state.hour
        game.advance(by: 0.2)
        XCTAssertEqual(game.driver?.state.hour, hour, "paused")
        game.order(.brazier)
        XCTAssertNil(game.overlay, "the card closes when the order stands")
        XCTAssertFalse(game.isPaused)
        XCTAssertEqual(game.gold, 48)
        XCTAssertEqual(game.driver?.state.plots[plot].job?.target, .brazier)
    }

    func testTheNeighbourArrowAndClosing() throws {
        let game = model(["GWCameraX": "1267"])
        game.performAction()
        let first = try XCTUnwrap(game.buildCard)
        let next = try XCTUnwrap(first.next)
        game.showPlot(next)
        XCTAssertEqual(game.overlay, .build(plot: next))
        game.closeCard()
        XCTAssertNil(game.overlay)
        XCTAssertFalse(game.isPaused)
    }

    func testTheBarracksAndTheThrone() throws {
        let barracks = model(["GWCameraX": "\(KingTargets.barracksX)"])
        XCTAssertEqual(barracks.target, .recruit)
        barracks.performAction()
        XCTAssertEqual(barracks.overlay, .recruit)
        barracks.recruit(.archer)
        XCTAssertEqual(barracks.overlay, .recruit, "the card stays open for the next recruit")
        XCTAssertEqual(barracks.recruitCard?.archers, 4)
        XCTAssertEqual(barracks.gold, 50)
        XCTAssertEqual(barracks.soldiers, 6)
        // M3: a petitioner waits on day 1, so the crown opens the audience; the tax lectern beside the throne keeps
        // the tax card.
        let crown = model([:])
        XCTAssertEqual(crown.target, .throne)
        crown.performAction()
        XCTAssertEqual(crown.overlay, .audience)
        crown.standUp()
        XCTAssertNil(crown.overlay)
        let throne = model(["GWStage": "hall", "GWHallX": "\(HallLayout.lecternX)"])
        XCTAssertEqual(throne.target, .lectern)
        throne.performAction()
        XCTAssertEqual(throne.overlay, .taxes)
        throne.setTax(.low)
        XCTAssertEqual(throne.taxCard?.current, .low)
        throne.setTax(.war)
        XCTAssertEqual(throne.driver?.state.tax, .low, "the war tax is locked until day 8")
        throne.closeCard()
        XCTAssertNil(throne.overlay)
    }

    func testTheDawnBringsTheReportAndContinueStartsTheDay() throws {
        let game = model(["GWNight": "1", "GWSeed": "4", "GWCameraX": "1150"])
        var guardFrames = 0
        while game.overlay == nil && guardFrames < 2000 {
            game.advance(by: 0.25)
            guardFrames += 1
        }
        let card = try XCTUnwrap(game.reportCard, "the report opened at dawn")
        XCTAssertEqual(card.night, 1)
        XCTAssertEqual(card.day, 2)
        XCTAssertTrue(game.isPaused)
        XCTAssertEqual(game.day, 2)
        let hour = game.driver?.state.hour ?? 0
        XCTAssertEqual(hour, 6, accuracy: 0.01)
        game.continueReport()
        XCTAssertNil(game.overlay)
        game.advance(by: 0.25)
        XCTAssertGreaterThan(game.driver?.state.hour ?? 0, hour, "the day runs again")
    }

    func testTheDefeatCardsTwoWaysOut() throws {
        let chance = model(["GWScreen": "defeat"])
        let info = try XCTUnwrap(chance.defeatInfo)
        XCTAssertEqual(info.night, 1)
        XCTAssertNil(info.secondChanceFrom, "the first second chance is free to take")
        XCTAssertEqual(info.replayDay, 1)
        chance.takeSecondChance()
        let report = try XCTUnwrap(chance.reportCard, "dawn comes at once and its report follows")
        XCTAssertTrue(report.banners.contains(.secondChance))
        XCTAssertEqual(chance.driver?.state.defeated, false)
        chance.continueReport()
        XCTAssertNil(chance.overlay)

        let replay = model(["GWScreen": "defeat", "GWNight": "2", "GWSeed": "4"])
        XCTAssertEqual(replay.overlay, .defeat)
        replay.replayDay()
        XCTAssertNil(replay.overlay)
        XCTAssertEqual(replay.driver?.state.defeated, false)
        XCTAssertEqual(replay.driver?.state.day, 2)
        XCTAssertEqual(replay.driver?.state.hour ?? 0, 6, accuracy: 0.01, "back to this day's dawn")
    }

    func testThePauseSheetAndTheRestart() {
        let game = model(["GWDay": "3", "GWSeed": "4"])
        XCTAssertEqual(game.day, 3)
        game.openPause()
        XCTAssertEqual(game.overlay, .pause)
        XCTAssertTrue(game.isPaused)
        game.resume()
        XCTAssertNil(game.overlay)
        game.openPause()
        let sound = game.settings.sound
        game.setSound(!sound)
        XCTAssertEqual(game.settings.sound, !sound)
        XCTAssertEqual(game.feedback.soundOn, !sound)
        game.setSound(sound)
        game.restartChapter()
        XCTAssertNil(game.overlay)
        XCTAssertEqual(game.day, 1)
        XCTAssertEqual(game.gold, 60)
        XCTAssertNotEqual(game.driver?.state.seed, 4, "a new realm")
    }

    func testThePauseSheetSoundsTheHornByDay() throws {
        // M2b review: by day the pause sheet calls the night; the day plays on to 18:59 at once, so the brazier ordered
        // this morning stands when the horn sounds a moment later.
        let game = model(["GWCameraX": "1255"])
        let plot = Realm.lines[0].braziers[0]
        game.performAction()
        game.order(.brazier)
        game.openPause()
        XCTAssertTrue(game.canCallTheNight)
        game.callTheNight()
        XCTAssertNil(game.overlay, "the sheet closes")
        XCTAssertEqual(game.driver?.state.hour ?? 0, SimDriver.hornCallHour, accuracy: 0.01)
        XCTAssertEqual(game.driver?.state.plots[plot].item, .brazier, "the builders finished the day's work")
        for _ in 0..<4 { game.advance(by: 0.25) }
        XCTAssertGreaterThanOrEqual(game.driver?.state.hour ?? 0, 19, "the horn sounded")
        XCTAssertEqual(game.hornNight, 1)
        game.openPause()
        XCTAssertFalse(game.canCallTheNight, "not from the horn on")
    }

    /// M3 fix (C2): the horn's confirmation knows who still waits, and the horn sends them home unheard.
    func testTheHornSendsTheWaitingPetitionersHome() throws {
        let game = model([:])
        XCTAssertEqual(game.petitionersWaiting, 1, "day 1: the farmer waits")
        game.openPause()
        XCTAssertTrue(game.canCallTheNight)
        game.callTheNight()
        XCTAssertEqual(game.petitionersWaiting, 1, "a minute before the horn he still waits")
        for _ in 0..<4 { game.advance(by: 0.25) }
        let state = try XCTUnwrap(game.driver?.state)
        XCTAssertGreaterThanOrEqual(state.hour, 19, "the horn sounded")
        XCTAssertEqual(state.unheardPetitioners, 1)
        XCTAssertEqual(state.court?.history.last, HeardPetition(id: "first_plough", day: 1, choice: nil))
        XCTAssertEqual(game.petitionersWaiting, 0)
    }

    /// M3 fix (C4): replaying the day starts the court afresh: the bubble closes and whoever was talked to on the
    /// day that was undone has his speech mark and his first line again.
    func testReplayingTheDayStartsTheCourtAfresh() throws {
        let game = model(["GWScreen": "defeat", "GWNight": "2", "GWSeed": "4"])
        XCTAssertEqual(game.overlay, .defeat)
        game.talkLog.note("odile", day: 2)
        game.court.talking = "odile"
        game.court.leavers = [CourtLeaver(who: "farmer", body: .townsfolk(.petitionerD), look: 3, from: 1800, to: CourtLeaver.hallDoor)]
        XCTAssertEqual(game.talkLog.count("odile", day: 2), 1)
        game.replayDay()
        XCTAssertNil(game.overlay)
        XCTAssertEqual(game.talkLog.count("odile", day: 2), 0, "the day is new: nobody was talked to")
        XCTAssertNil(game.court.talking)
        XCTAssertNil(game.talkBubble)
        XCTAssertTrue(game.court.leavers.isEmpty, "nobody is still walking out of the day that was undone")
        XCTAssertNil(game.audience)

        let chance = model(["GWScreen": "defeat"])
        chance.court.leavers = [CourtLeaver(who: "farmer", body: .townsfolk(.petitionerD), look: 3, from: 1800,
                                            to: CourtLeaver.hallDoor)]
        chance.takeSecondChance()
        XCTAssertTrue(chance.court.leavers.isEmpty, "the second chance's dawn starts the court afresh too")
        XCTAssertNotNil(chance.reportCard, "and its report still follows")
    }

    func testTheStripTapAndTheSampleScreens() {
        let game = model([:])
        game.travel(toFraction: 0.25)
        XCTAssertEqual(game.driver?.travelTarget ?? 0, Realm.worldWidth / 4, accuracy: 1e-9)
        XCTAssertNotNil(game.strip)
        XCTAssertTrue(model(["GWScreen": "report"]).reportCard?.fallen.isEmpty == false)
        XCTAssertEqual(model(["GWScreen": "finale"]).reportCard?.banners.first, .kingSlain)
        let showcase = model(["GWNight": "1", "GWAutoplay": "play"])
        XCTAssertTrue(showcase.isShowcase)
        XCTAssertNil(showcase.target, "the bot plays: no button over the picture")
    }
}
