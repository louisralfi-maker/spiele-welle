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
        // Polish B3b part 5 (rewritten from the B3 gate's M1, "a tap keeps the bubble"): the bubble says the deed, so a
        // tap on it while the deed waits does it, as the second touch would; the deed goes with the wait.
        game.tapTalkBubble(try XCTUnwrap(game.talkBubble))
        XCTAssertTrue(Town.collectorHired(try XCTUnwrap(game.driver?.state)), "taken on")
        XCTAssertNil(game.touch.errand, "the wait is over")
        let answer = try XCTUnwrap(game.talkBubble)
        XCTAssertNil(game.collectorDeed(answer), "his answer carries no deed")
        game.tapTalkBubble(answer)
        XCTAssertNil(game.talkBubble, "his answer closes on a tap")
    }

    // MARK: - Polish B3b part 5: Saul's bubble does what it says

    /// A realm on day 1 at 10:00 with the lord standing before Saul at his post, his offer in the bubble and the second
    /// touch waiting, and a recording hub.
    private func standingBeforeSaul(_ directory: URL) throws -> (game: GameModel, hub: SilentFeedback,
                                                                  frames: (Double) -> Void) {
        let pro = PixelScale(physicalWidth: 2622, physicalHeight: 1206)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let game = GameModel(args: DebugArgs(values: ["GWReset": "YES", "GWSkipOnboarding": "YES", "GWStage": "world",
                                                      "GWClock": "10",
                                                      "GWCameraX": "\(Int(Town.collectorPost) - 70)"]),
                             kind: .world, store: SaveStore(directory: directory))
        let hub = SilentFeedback()
        game.feedback = hub
        game.setTouchViewSize(CGSize(width: 874, height: 402))
        let frames: (Double) -> Void = { seconds in
            var left = seconds
            while left > 1e-9 {
                game.advance(by: 1.0 / 60)
                _ = game.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
                left -= 1.0 / 60
            }
        }
        frames(0.3)
        let saul = try XCTUnwrap(game.touch.things.first { $0.id == CollectorTouch.id }, "Saul at his post")
        game.touchThing(saul)
        var waited = 0.0
        while game.talkBubble == nil && waited < 6 {
            frames(0.1)
            waited += 0.1
        }
        XCTAssertNotNil(game.talkBubble, "his offer as the lord stands before him")
        XCTAssertEqual(game.touch.errand?.waiting, true, "the second touch waits")
        frames(0.2)
        return (game, hub, frames)
    }

    /// Polish B3b part 5 (the director's call after B3): while the deed waits and its words stand in his bubble, a tap
    /// on the bubble does the deed: the same function, the same sounds and the same result as the second touch on him
    /// (two realms side by side). It does it once: a second tap (on the bubble the deed replaced) does nothing more. The
    /// deed line reads the published state: it stands while the deed waits and is gone the frame after. His answer, a
    /// bubble with no deed, closes on a tap as any bubble does, its going heard once.
    func testATapOnHisBubbleDoesTheDeedOnce() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("lanternhold-collector-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let byBubble = try standingBeforeSaul(root.appendingPathComponent("a", isDirectory: true))
        let byTouch = try standingBeforeSaul(root.appendingPathComponent("b", isDirectory: true))
        let game = byBubble.game
        let offer = try XCTUnwrap(game.talkBubble)
        let state = try XCTUnwrap(game.driver?.state)
        XCTAssertEqual(WalkSigns.shared.bubbleDeed, CollectorTouch.label(state, waiting: true),
                       "the deed published while it waits")
        XCTAssertFalse(Town.collectorHired(state), "not yet taken on")

        // The tap on the bubble and the second touch on him, from the same moment.
        let bubbleMark = byBubble.hub.played.count
        let touchMark = byTouch.hub.played.count
        game.tapTalkBubble(offer)
        let saul = try XCTUnwrap(byTouch.game.touch.things.first { $0.id == CollectorTouch.id })
        byTouch.game.touchThing(saul)
        let bubbleCues = Array(byBubble.hub.played.dropFirst(bubbleMark))
        let touchCues = Array(byTouch.hub.played.dropFirst(touchMark))
        XCTAssertEqual(bubbleCues, touchCues, "the same sounds as the second touch")
        XCTAssertTrue(bubbleCues.contains(.touched), "the touch's own tick")
        XCTAssertTrue(Town.collectorHired(try XCTUnwrap(game.driver?.state)), "taken on")
        XCTAssertTrue(Town.collectorHired(try XCTUnwrap(byTouch.game.driver?.state)), "taken on by the touch too")
        XCTAssertNil(game.touch.errand, "the wait is over")
        let answer = try XCTUnwrap(game.talkBubble, "his answer")
        XCTAssertEqual(answer.textKey, try XCTUnwrap(byTouch.game.talkBubble).textKey, "the same answer")
        XCTAssertNil(game.collectorDeed(answer), "his answer carries no deed")

        // A second tap on the bubble the deed replaced does nothing more.
        let afterDeed = byBubble.hub.played.count
        game.tapTalkBubble(offer)
        XCTAssertTrue(Town.collectorHired(try XCTUnwrap(game.driver?.state)), "still taken on, never sent home")
        XCTAssertEqual(game.talkBubble, answer, "his answer stands")
        XCTAssertEqual(byBubble.hub.played.count, afterDeed, "no sound")

        // The deed line follows the published state the next frame.
        byBubble.frames(1.0 / 60)
        XCTAssertNil(WalkSigns.shared.bubbleDeed, "no deed once it no longer waits")

        // His answer closes on a tap, its going heard once.
        let beforeClose = byBubble.hub.played.filter { $0 == .bubbleClose }.count
        game.tapTalkBubble(answer)
        XCTAssertNil(game.talkBubble, "his answer closes on a tap")
        byBubble.frames(0.3)
        XCTAssertEqual(byBubble.hub.played.filter { $0 == .bubbleClose }.count, beforeClose + 1, "bubbleClose once")
    }

    /// Polish B3b part 5: a bubble with no deed waiting closes on a tap as before (another speaker's line; Saul's own
    /// offer once the lord walked off and the wait was dropped).
    func testABubbleWithNoDeedClosesOnATap() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("lanternhold-collector-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let saul = try standingBeforeSaul(root)
        let game = saul.game
        game.cancelErrand()
        let bubble = try XCTUnwrap(game.talkBubble)
        XCTAssertNil(game.collectorDeed(bubble), "no deed once the wait is dropped")
        saul.frames(1.0 / 60)
        XCTAssertNil(WalkSigns.shared.bubbleDeed, "and none published")
        game.tapTalkBubble(bubble)
        XCTAssertNil(game.talkBubble, "the tap closes it")
        XCTAssertFalse(Town.collectorHired(try XCTUnwrap(game.driver?.state)), "and does no deed")
    }
}
