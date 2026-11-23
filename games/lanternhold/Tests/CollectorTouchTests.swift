import CoreGraphics
import Foundation
import XCTest
@testable import Lanternhold

/// The collector's hire by touch (the join, the director's note of 15.11.2026 10:52; `CollectorTouch`): his target at
/// his post by day and never on his round, the offer's talk mark until he is taken on, the second touch's answers
/// (taken on, sent home, taken on again), the labels, the dawn snapshot, and Saul standing at his post in the game.
@MainActor
final class CollectorTouchTests: XCTestCase {
    private let balance = Balance.standard

    /// A new realm on day 1 at `hour`, the lord in the courtyard.
    private func firstDay(_ hour: Double) -> GameState {
        var s = GameState.newRealm(seed: 1, balance: balance)
        s.hour = hour
        s.king.x = 1500
        return s
    }

    /// The dawn of day 2 with the collector taken on during day 1 (he walks today), at `hour`.
    private func secondDay(_ hour: Double) -> GameState {
        var s = GameState.newRealm(seed: 1, balance: balance)
        Town.collectAll(&s, balance: balance)
        Town.setCollector(&s, hired: true)
        Town.horn(&s, balance: balance)
        s.day = 2
        s.hour = 6
        Economy.dawn(&s, fallen: 0, balance: balance)
        s.hour = hour
        return s
    }

    private let english: [String: String] = [
        "town.collector.name": "Saul Tolliver", "town.collector.hire": "Take him on",
        "town.collector.act.hire": "Take on %@", "town.collector.act.dismiss": "Send %@ home",
    ]

    func testHeStandsAtHisPostByDayFromTheFirstDay() throws {
        let s = firstDay(9)
        XCTAssertNotNil(s.town, "a new realm has its town")
        let thing = try XCTUnwrap(CollectorTouch.thing(s), "a target at his post on day 1")
        XCTAssertEqual(thing.id, "touch-collector")
        XCTAssertEqual(thing.act, .collector)
        XCTAssertEqual(thing.x, Town.collectorPost)
        XCTAssertEqual(thing.standX, Town.collectorPost - CollectorTouch.standOff, "the lord stops on his own side")
        XCTAssertTrue(thing.marked, "his offer still to make: the talk mark")
        XCTAssertEqual(KingTargets.anchorX(.collector, state: s, balance: balance), Town.collectorPost)
        XCTAssertNil(KingTargets.hold(.collector, state: s, balance: balance))
        XCTAssertTrue(TouchThings.world(s, balance: balance, figures: [], talked: []).contains { $0.id == thing.id })
        XCTAssertNil(CollectorTouch.thing(firstDay(22)), "not at night")
        XCTAssertNil(CollectorTouch.thing(firstDay(5.5)), "not before the dawn's report")
        XCTAssertNil(CollectorTouch.thing(firstDay(19.2)), "off at the horn")
        // In the game (no -GWCollector) the town's picture puts him there too.
        let quiet = TownLife.Context(cloth: .hamlet, reduceMotion: false, hearth: 1, collectorOut: false, nobleDue: false)
        let saul = try XCTUnwrap(TownLife.collector(s, time: 1, context: quiet))
        XCTAssertEqual(saul.x, Town.collectorPost)
        XCTAssertEqual(saul.sprite, .collector)
    }

    func testTheSecondTouchTakesHimOnAndLaterTogglesHim() {
        var s = firstDay(10)
        XCTAssertEqual(CollectorTouch.offer(s), .hire)
        XCTAssertEqual(CollectorTouch.answer(&s), .hired)
        XCTAssertTrue(Town.collectorHired(s), "taken on")
        XCTAssertFalse(Town.collectorWalksToday(s), "from the next morning")
        XCTAssertEqual(CollectorTouch.offer(s), .dismiss)
        XCTAssertEqual(CollectorTouch.thing(s)?.marked, false, "no talk mark once his offer was answered")
        XCTAssertEqual(CollectorTouch.answer(&s), .dismissed)
        XCTAssertFalse(Town.collectorHired(s))
        XCTAssertEqual(CollectorTouch.offer(s), .rehire)
        XCTAssertEqual(CollectorTouch.thing(s)?.marked, false)
        XCTAssertEqual(CollectorTouch.answer(&s), .rehired)
        XCTAssertTrue(Town.collectorHired(s))
    }

    func testTheLabelsNameTheActFirst() {
        var s = firstDay(10)
        let lookup: (String) -> String = { self.english[$0] ?? $0 }
        XCTAssertEqual(CollectorTouch.label(s, waiting: false, lookup: lookup), "Take on Saul Tolliver")
        XCTAssertEqual(CollectorTouch.label(s, waiting: true, lookup: lookup), "Take him on", "his offer's slip")
        CollectorTouch.answer(&s)
        XCTAssertEqual(CollectorTouch.label(s, waiting: true, lookup: lookup), "Send Saul Tolliver home")
        CollectorTouch.answer(&s)
        XCTAssertEqual(CollectorTouch.label(s, waiting: false, lookup: lookup), "Take on Saul Tolliver")
        // The two new keys are in the app's English.
        XCTAssertEqual(TownText.string(CollectorTouch.actHireKey, language: "en"), "Take on %@")
        XCTAssertEqual(TownText.string(CollectorTouch.actDismissKey, language: "en"), "Send %@ home")
    }

    func testOnHisRoundHeIsNoTarget() throws {
        let morning = secondDay(8)
        XCTAssertTrue(Town.collectorWalksToday(morning), "taken on yesterday, he walks today")
        XCTAssertNil(CollectorTouch.thing(morning), "out on his round")
        // Back at his post in the afternoon he is a target again, without a talk mark.
        var hour = 8.0
        var back: GameState?
        while hour < 19 {
            let s = secondDay(hour)
            if CollectorTouch.atPost(s) { back = s; break }
            hour += 0.25
        }
        let home = try XCTUnwrap(back, "home before the horn")
        XCTAssertEqual(CollectorTouch.thing(home)?.marked, false)
    }

    func testTheAnswerKeepsInTheDawnSnapshot() {
        var driver = SimDriver(state: firstDay(10))
        XCTAssertEqual(driver.answerCollector(), .hired)
        XCTAssertTrue(Town.collectorHired(driver.state))
        XCTAssertTrue(Town.collectorHired(driver.dawnSnapshot), "a replayed day keeps him")
    }

    /// Polish B3 (H4): no slip over Saul's post. While the lord walks to him his mark is pressed; standing before him the
    /// second touch's deed stands in his bubble under his offer ("Take him on", the slip's words), the bubble over his
    /// mark by the slip's old rule (its lower edge 2 game px over the mark's top); the second touch takes him on and the
    /// deed goes with the wait. VoiceOver keeps the label.
    func testHisBubbleCarriesTheSecondTouchsDeed() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("lanternhold-collector-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let pro = PixelScale(physicalWidth: 2622, physicalHeight: 1206)
        let game = GameModel(args: DebugArgs(values: ["GWReset": "YES", "GWSkipOnboarding": "YES", "GWStage": "world",
                                                      "GWClock": "10",
                                                      "GWCameraX": "\(Int(Town.collectorPost) - 70)"]),
                             kind: .world, store: SaveStore(directory: directory))
        game.setTouchViewSize(CGSize(width: 874, height: 402))
        func frames(_ seconds: Double, until done: () -> Bool = { false }) {
            var left = seconds
            while left > 1e-9 {
                game.advance(by: 1.0 / 60)
                _ = game.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
                left -= 1.0 / 60
                if done() { return }
            }
        }
        frames(0.3)
        let saul = try XCTUnwrap(game.touch.things.first { $0.id == CollectorTouch.id }, "Saul at his post")
        game.touchThing(saul)
        frames(0.3)
        XCTAssertNil(game.errandSlip, "no slip on the way")
        XCTAssertEqual(game.touch.markShows[CollectorTouch.id]?.mark.pressed, true, "his mark is the errand's sign")
        frames(6) { game.talkBubble != nil }
        let bubble = try XCTUnwrap(game.talkBubble, "he makes his offer as the lord stands before him")
        XCTAssertEqual(game.touch.errand?.waiting, true, "the second touch waits")
        XCTAssertNil(game.errandSlip, "and no slip says so")
        let state = try XCTUnwrap(game.driver?.state)
        XCTAssertEqual(game.collectorDeed(bubble), CollectorTouch.label(state, waiting: true),
                       "his bubble carries the deed the slip said")
        XCTAssertEqual(game.collectorDeed(bubble), TownText.string(CollectorWords.hire.key))
        XCTAssertEqual(game.touch.markShows[CollectorTouch.id]?.mark.pressed, false, "arrived: the mark rests")
        // The bubble over the mark: its head line at most the mark's top less 2 game px, plus the view's 4 pt.
        frames(0.1)
        let framing = try XCTUnwrap(game.touch.framing)
        let thing = try XCTUnwrap(game.touch.things.first { $0.id == CollectorTouch.id })
        let markTop = framing.deviceY(lift: thing.markLift + TouchRules.markHeight) / framing.physicalHeight
        let shown = try XCTUnwrap(game.talkBubble)
        XCTAssertLessThanOrEqual(shown.headY, markTop - 2 * framing.scale / framing.physicalHeight + 4.0 / 402 + 1e-6,
                                 "the bubble stands over his mark")
        // VoiceOver keeps the slip's words.
        game.refreshTouchSpots()
        XCTAssertEqual(game.touchSpots.first { $0.id == CollectorTouch.id }?.label,
                       CollectorTouch.label(state, waiting: true))
        // B3 gate (M1): a tap on his bubble while the deed waits keeps it (the slip stayed until the second touch).
        game.tapTalkBubble(try XCTUnwrap(game.talkBubble))
        XCTAssertNotNil(game.talkBubble, "a tap keeps the bubble while the deed waits")
        XCTAssertEqual(game.touch.errand?.waiting, true, "and the second touch still waits")
        XCTAssertNotNil(game.collectorDeed(try XCTUnwrap(game.talkBubble)), "with the deed on it")
        // The second touch takes him on; the deed goes with the wait.
        let again = try XCTUnwrap(game.touch.things.first { $0.id == CollectorTouch.id })
        game.touchThing(again)
        XCTAssertTrue(Town.collectorHired(try XCTUnwrap(game.driver?.state)), "taken on")
        let answer = try XCTUnwrap(game.talkBubble)
        XCTAssertNil(game.collectorDeed(answer), "his answer carries no deed")
        game.tapTalkBubble(answer)
        XCTAssertNil(game.talkBubble, "his answer closes on a tap")
    }
}
