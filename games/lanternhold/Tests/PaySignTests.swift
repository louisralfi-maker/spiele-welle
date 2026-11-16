import CoreGraphics
import Foundation
import XCTest
@testable import Lanternhold

/// The count's step 4 (build 3, lane 1; the director's notes of 16.11., 09:34, part B): a plot with more than one offer
/// carries a signpost in world pixels, one wooden shingle per offer (the building's silhouette, a coin and the price,
/// no words). The shingles' places and catch areas for two and three offers (44 pt both ways, no overlap, inside the
/// world at either end), the chosen shingle on the board's post, the signpost going and coming back, a hollow coin for
/// a poor purse, no catch at night, VoiceOver's names and prices, no card from a plot.
@MainActor
final class PaySignTests: XCTestCase {
    private var directory: URL!
    private let pro = PixelScale(physicalWidth: 2622, physicalHeight: 1206)
    private let proPoints = CGSize(width: 874, height: 402)

    override func setUp() async throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("lanternhold-sign-\(UUID().uuidString)", isDirectory: true)
    }

    override func tearDown() async throws {
        if let directory { try? FileManager.default.removeItem(at: directory) }
    }

    private func model(_ values: [String: String]) -> GameModel {
        var all = values
        all["GWReset"] = "YES"
        all["GWSkipOnboarding"] = "YES"
        return GameModel(args: DebugArgs(values: all), kind: .world, store: SaveStore(directory: directory))
    }

    private func run(_ game: GameModel, seconds: Double, until done: () -> Bool = { false }) {
        var left = seconds
        var frames = 0
        while left > 1e-9 {
            game.advance(by: 1.0 / 60)
            frames += 1
            if frames % 4 == 0 { _ = game.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight) }
            left -= 1.0 / 60
            if done() { return }
        }
    }

    private func offers(_ count: Int) -> [BuildOption] {
        let items: [BuildItem] = [.ballista, .catapult, .archerTower]
        return (0..<count).map { BuildOption(item: items[$0], price: 40 + 30 * $0, isRebuild: false) }
    }

    /// The smallest touch target in game px at the world's scales on 3x and 2x screens (44 pt).
    private var minimums: [Double] {
        var list: [Double] = []
        for scale in [4.0, 5.0, 6.0] {
            for screen in [2.0, 3.0] {
                list.append(TouchRules.minimumSide(pointsPerPixel: TouchRules.pointsPerPixel(scale: scale,
                                                                                            screenScale: screen)))
            }
        }
        return list
    }

    /// The line-1 engine's empty plot, the only plot with two offers on day 3 (seed 2), by day at its place.
    private func engineGame(gold: Int = 200, hour: String = "10") -> GameModel {
        var values = ["GWStage": "world", "GWSeed": "2", "GWCameraX": "1440", "GWGold": "\(gold)",
                      "GWWeather": "clear"]
        if Double(hour) ?? 10 >= 18 {
            values["GWNight"] = "3"
            values["GWHour"] = hour
        } else {
            values["GWDay"] = "3"
            values["GWClock"] = hour
        }
        let game = model(values)
        game.withDriver { driver in
            driver.state.plots[Realm.lines[0].engine].item = nil
            driver.state.plots[Realm.lines[0].engine].job = nil
        }
        _ = game.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
        _ = game.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
        return game
    }

    // MARK: - The pure places

    /// Two and three offers, on every side of the post, at every scale: each catch area at least 44 pt both ways and at
    /// least the shingle, the areas side by side without overlap, each shingle inside its own area, the shingles apart.
    func testTheShinglesPlacesAndCatchAreasForTwoAndThreeOffers() {
        for minimum in minimums {
            for count in [2, 3] {
                for side in PaySignpost.Side.allCases {
                    let sign = PaySignpost.make(plot: 4, x: 1440, offers: offers(count), side: side, minimum: minimum)
                    let what = "\(count) offers, \(side), minimum \(minimum)"
                    XCTAssertEqual(sign.shingles.count, count, what)
                    for shingle in sign.shingles {
                        XCTAssertGreaterThanOrEqual(shingle.area.width, minimum - 1e-9, what + ": 44 pt wide")
                        XCTAssertGreaterThanOrEqual(shingle.area.height, minimum - 1e-9, what + ": 44 pt tall")
                        XCTAssertGreaterThanOrEqual(shingle.area.width, Double(PaySignpost.shingleWidth) - 1e-9)
                        XCTAssertLessThanOrEqual(shingle.area.left, shingle.left + 0.5, what + ": the shingle inside")
                        XCTAssertGreaterThanOrEqual(shingle.area.right,
                                                    shingle.left + Double(PaySignpost.shingleWidth) - 0.5, what)
                        XCTAssertGreaterThanOrEqual(shingle.area.bottom, -TouchRules.footRoom - 1e-9, what)
                    }
                    for (a, b) in zip(sign.shingles, sign.shingles.dropFirst()) {
                        XCTAssertLessThanOrEqual(a.area.right, b.area.left + 1e-9, what + ": the areas never overlap")
                        XCTAssertGreaterThanOrEqual(b.left - (a.left + Double(PaySignpost.shingleWidth)),
                                                    Double(PaySignpost.gap) - 1, what + ": wood between them")
                    }
                    XCTAssertTrue(sign.barLeft <= Int(sign.shingles[0].left), what + ": the bar carries them all")
                    XCTAssertTrue(sign.barLeft + sign.barWidth >= Int(sign.shingles[count - 1].left)
                                  + PaySignpost.shingleWidth, what)
                    let post = Double(sign.postLeft) + 3
                    XCTAssertTrue(Double(sign.barLeft) <= post && post <= Double(sign.barLeft + sign.barWidth),
                                  what + ": the bar on its post")
                }
            }
        }
    }

    /// At the world's left and right ends the whole signpost stays inside the world strip (so on the screen the camera
    /// shows there), its post going with it.
    func testTheSignpostStaysInsideAtTheWorldsEnds() {
        for minimum in minimums {
            for count in [2, 3] {
                for side in PaySignpost.Side.allCases {
                    for x in [0.0, 6.0, Realm.worldWidth - 6, Realm.worldWidth] {
                        let sign = PaySignpost.make(plot: 4, x: x, offers: offers(count), side: side, minimum: minimum)
                        for shingle in sign.shingles {
                            XCTAssertGreaterThanOrEqual(shingle.area.left, -1e-9, "x \(x): inside on the left")
                            XCTAssertLessThanOrEqual(shingle.area.right, Realm.worldWidth + 1e-9, "x \(x): and right")
                        }
                    }
                }
            }
        }
    }

    /// A touch inside a shingle's area finds it; between two areas or above them, nothing.
    func testATouchFindsItsShingle() throws {
        let sign = PaySignpost.make(plot: 4, x: 1440, offers: offers(3), side: .centre, minimum: 22)
        for shingle in sign.shingles {
            let middleLift = PaySignpost.foot + Double(PaySignpost.shingleHeight) / 2
            XCTAssertEqual(sign.shingle(x: shingle.middle, lift: middleLift)?.item, shingle.item)
        }
        XCTAssertNil(sign.shingle(x: 1440, lift: 200), "far above it")
        XCTAssertNil(sign.shingle(x: 1000, lift: 15), "far beside it")
    }

    /// The chosen shingle on the board's post: centred on the post, its feet clear over the board's top.
    func testTheChosenShingleHangsOnTheBoardsPost() {
        let place = PaySignpost.onBoard(postLeft: 100, boardTop: 32)
        XCTAssertEqual(place.left + Double(PaySignpost.shingleWidth) / 2, 103, accuracy: 0.51, "on the post's middle")
        XCTAssertGreaterThanOrEqual(place.top - Double(PaySignpost.shingleHeight), 32 + 3, "over the post's plate")
        let layout = PayBoardLayout.make(PayCount.hollows(price: 70))
        var board = CountBoard(x: 200, stand: 160, act: .build(plot: 4), layout: layout)
        XCTAssertEqual(board.carryTop, board.top, "no shingle: the board's own top")
        board.shingle = .ballista
        XCTAssertGreaterThan(board.carryTop, board.top + Double(PaySignpost.shingleHeight), "it carries the shingle")
    }

    func testWhichPlotsCarryASignpost() {
        var s = GameState.newRealm(seed: 2)
        s.hour = 10
        let engine = Realm.lines[0].engine
        s.plots[engine].item = nil
        s.plots[engine].job = nil
        let plots = PaySignpost.plots(s, balance: .standard)
        let entry = plots.first { $0.plot == engine }
        XCTAssertEqual(entry?.offers.map(\.item), [.ballista, .catapult], "the engine's two")
        XCTAssertFalse(plots.contains { $0.plot == Realm.lines[0].braziers[0] }, "one offer: no signpost")
        XCTAssertTrue(plots.allSatisfy { $0.offers.count > 1 })
        XCTAssertEqual(PaySignpost.frame(for: .ballista), 0)
        XCTAssertEqual(PaySignpost.frame(for: .catapult), 1)
        XCTAssertEqual(PaySignpost.frame(for: .smithy), 2)
        XCTAssertEqual(SpriteID.paySign.frameCount, 3, "three silhouettes")
        XCTAssertEqual(SpriteID.paySign.size, PixelSize(width: PaySignpost.shingleWidth, height: PaySignpost.shingleHeight))
    }

    // MARK: - Through the game

    /// By day the engine's plot carries its signpost, drawn as a thing of the world (lit, not interface): the post,
    /// the bar, two shingles with their silhouettes, a gold coin and the price each; the plot's mark gives way to it.
    func testTheSignpostStandsInTheWorld() throws {
        let game = engineGame()
        let plot = Realm.lines[0].engine
        let sign = try XCTUnwrap(game.touch.signs.first { $0.plot == plot }, "the engine's signpost")
        XCTAssertEqual(sign.shingles.map(\.item), [.ballista, .catapult])
        let frame = game.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
        let shingles = frame.actors.filter { $0.sprite == .paySign }
        XCTAssertEqual(Set(shingles.map(\.frame)), [0, 1], "the ballista's and the catapult's silhouettes")
        XCTAssertTrue(shingles.allSatisfy { $0.isLit && !$0.isEmissive }, "a thing of the world, lit by the hour")
        XCTAssertTrue(frame.actors.contains { $0.sprite == .payBoard && $0.frame == PayBoardLayout.signBarMiddle },
                      "its iron bar")
        XCTAssertEqual(frame.actors.filter { $0.sprite == .payCoin && $0.frame == 0 }.count, 2, "a gold coin each")
        let figures = frame.actors.filter { $0.sprite == .hudFigures && !$0.isEmissive }
        XCTAssertEqual(figures.count, 2 + 3, "70 and 110 in the purse's figures, lit")
        XCTAssertTrue(game.signWord.contains("\(plot):ballista,catapult"), "the scene names it (\(game.signWord))")
    }

    /// A shingle whose price the purse does not hold shows its coin as a dark hollow; a touch on it still brings its
    /// board (the count then waits, as it does today).
    func testAPoorPurseShowsAHollowCoin() throws {
        let game = engineGame(gold: 80)
        let frame = game.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
        XCTAssertEqual(frame.actors.filter { $0.sprite == .payCoin && $0.frame == 0 }.count, 1, "70: a gold coin")
        XCTAssertEqual(frame.actors.filter { $0.sprite == .hudHollow && $0.frame == 0 }.count, 1, "110: a hollow")
        let plot = Realm.lines[0].engine
        let catapult = try XCTUnwrap(game.touch.signs.first { $0.plot == plot }?.shingles.first { $0.item == .catapult })
        game.touchShingle(catapult, holding: false)
        XCTAssertEqual(game.touch.count?.thing, "touch-plot-\(plot)", "its board still comes up")
        XCTAssertEqual(game.touch.count?.offer, .build(plot: plot, item: .catapult))
    }

    /// A touch on a shingle brings that offer's board at the plot and sends the lord; the chosen shingle hangs on the
    /// board's post and the signpost goes while the board stands; let go, the signpost comes back whole. A hold pays it
    /// and the building's work starts. No card opens.
    func testATouchOnAShingleBringsItsBoardAndTheShingleOnItsPost() throws {
        let game = engineGame()
        let plot = Realm.lines[0].engine
        let ballista = try XCTUnwrap(game.touch.signs.first { $0.plot == plot }?.shingles.first { $0.item == .ballista })
        let framing = try XCTUnwrap(game.touch.framing)
        let minimum = game.touchMinimum(framing: framing)
        let place = (x: ballista.middle, lift: PaySignpost.foot + 10, minimum: minimum)
        XCTAssertEqual(game.signShingle(at: place)?.item, .ballista, "the finger finds the ballista's shingle")
        game.touchShingle(ballista, holding: false)
        let board = try XCTUnwrap(game.touch.countBoard)
        XCTAssertEqual(board.shingle, .ballista, "the chosen shingle goes onto the board's post")
        XCTAssertEqual(game.touch.count?.price, Balance.standard.price(.ballista))
        XCTAssertNil(game.overlay, "no card")
        run(game, seconds: 0.3)
        XCTAssertFalse(game.touch.signs.contains { $0.plot == plot }, "the signpost goes while the board stands")
        let frame = game.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
        let shingles = frame.actors.filter { $0.sprite == .paySign }
        XCTAssertEqual(shingles.count, 1, "only the chosen one")
        XCTAssertEqual(shingles.first?.frame, 0, "the ballista's")
        let postMiddle = framing.deviceX(stageX: Double(board.postLeft) + 3)
        if let chosen = shingles.first {
            XCTAssertEqual(Double(chosen.rect.x + chosen.rect.z / 2), postMiddle, accuracy: Double(framing.scale) * 1.6,
                           "centred on the board's post")
            XCTAssertLessThan(Double(chosen.rect.y + chosen.rect.w), framing.deviceY(lift: board.top),
                              "over the board")
        }
        run(game, seconds: 12) { game.touch.count?.ready == true }
        var count = try XCTUnwrap(game.touch.count)
        count.press()
        game.touch.count = count
        run(game, seconds: 3) { game.touch.countLast.hasPrefix("paid") }
        XCTAssertEqual(game.touch.countLast, "paid:touch-plot-\(plot)", "the hold paid the ballista")
        XCTAssertEqual(game.driver?.state.plots[plot].job?.target, .ballista, "the work starts")
        XCTAssertEqual(game.driver?.state.gold, 200 - Balance.standard.price(.ballista), "paid once")
    }

    func testTheSignpostComesBackWhenTheCountIsLetGo() throws {
        let game = engineGame()
        let plot = Realm.lines[0].engine
        let catapult = try XCTUnwrap(game.touch.signs.first { $0.plot == plot }?.shingles.first { $0.item == .catapult })
        game.touchShingle(catapult, holding: false)
        run(game, seconds: 0.5)
        XCTAssertFalse(game.touch.signs.contains { $0.plot == plot })
        var count = try XCTUnwrap(game.touch.count)
        count.letGo()
        game.touch.count = count
        run(game, seconds: 1.5)
        XCTAssertNil(game.touch.count, "the board has gone")
        let back = try XCTUnwrap(game.touch.signs.first { $0.plot == plot }, "the signpost comes back")
        XCTAssertEqual(back.shingles.map(\.item), [.ballista, .catapult], "whole")
        XCTAssertNil(game.driver?.state.plots[plot].job, "nothing paid")
    }

    /// At night the signpost hangs unlit and takes no touch: the plot is no thing to touch, so no shingle catches a
    /// finger and no shingle is an accessibility element.
    func testNightGivesNoCatch() throws {
        let game = engineGame(hour: "22")
        let plot = Realm.lines[0].engine
        let sign = try XCTUnwrap(game.touch.signs.first { $0.plot == plot }, "it still hangs there at night")
        let framing = try XCTUnwrap(game.touch.framing)
        let frame = game.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
        XCTAssertTrue(frame.actors.filter { $0.sprite == .paySign }.allSatisfy { $0.isLit && !$0.isEmissive },
                      "unlit by anything of its own")
        let minimum = game.touchMinimum(framing: framing)
        for shingle in sign.shingles {
            XCTAssertNil(game.signShingle(at: (x: shingle.middle, lift: PaySignpost.foot + 10, minimum: minimum)),
                         "no catch at night")
        }
        game.setTouchViewSize(proPoints)
        game.refreshTouchSpots()
        XCTAssertFalse(game.touchSpots.contains { $0.id.hasPrefix("touch-shingle-") }, "no element at night")
    }

    /// VoiceOver: each shingle is an element named for its building and priced, at least 44 pt, in the left-to-right
    /// order; the plot itself is no element while its signpost stands; a double tap pays the offer in one step.
    func testVoiceOverNamesAndPricesEachShingle() throws {
        let game = engineGame()
        let plot = Realm.lines[0].engine
        game.setTouchViewSize(proPoints)
        _ = game.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
        game.refreshTouchSpots()
        let ballista = try XCTUnwrap(game.touchSpots.first { $0.id == "touch-shingle-\(plot)-ballista" })
        let catapult = try XCTUnwrap(game.touchSpots.first { $0.id == "touch-shingle-\(plot)-catapult" })
        XCTAssertEqual(ballista.label, "Build: Ballista")
        XCTAssertEqual(ballista.value, "\(Balance.standard.price(.ballista)) gold")
        XCTAssertEqual(catapult.value, "\(Balance.standard.price(.catapult)) gold")
        XCTAssertFalse(game.touchSpots.contains { $0.id == "touch-plot-\(plot)" }, "the plot gives way to its shingles")
        for spot in [ballista, catapult] {
            XCTAssertGreaterThanOrEqual(spot.rect.width * proPoints.width, 43.5, "\(spot.id) 44 pt wide")
            XCTAssertGreaterThanOrEqual(spot.rect.height * proPoints.height, 43.5, "\(spot.id) 44 pt tall")
        }
        XCTAssertLessThanOrEqual(ballista.rect.maxX, catapult.rect.minX + 0.0001, "side by side, never over each other")
        let xs = game.touchSpots.map(\.rect.minX)
        XCTAssertEqual(xs, xs.sorted(), "left to right")
        game.touchSpot(ballista.id)
        XCTAssertEqual(game.touch.count?.offer, .build(plot: plot, item: .ballista), "its board")
        XCTAssertEqual(game.touch.count?.atOnce, true, "paid in one step once he stands there")
    }

    /// No card from a plot: a touch on the engine's plot beside its shingles walks the lord there and does nothing
    /// new; an empty plot with one offer brings its board. The shingles hang still under Reduce Motion.
    func testNoCardFromAPlotAndStillUnderReduceMotion() throws {
        let game = engineGame()
        let plot = Realm.lines[0].engine
        let thing = try XCTUnwrap(game.touch.things.first { $0.id == "touch-plot-\(plot)" })
        game.touchThing(thing)
        XCTAssertNil(game.touch.count, "no board for the plot itself")
        run(game, seconds: 12) { game.touch.errand == nil }
        XCTAssertNil(game.overlay, "no card on arrival")
        XCTAssertNil(game.touch.count)
        let still = model(["GWStage": "world", "GWSeed": "2", "GWDay": "3", "GWClock": "10", "GWCameraX": "1440",
                           "GWReduceMotion": "YES"])
        for age in stride(from: 0.0, to: 1.0, by: 0.05) {
            XCTAssertEqual(still.signSwing(age: age), 0, "Reduce Motion: they hang still")
        }
        XCTAssertTrue(stride(from: 0.0, to: 0.9, by: 0.05).contains { game.signSwing(age: $0) != 0 },
                      "otherwise they swing as they appear")
        XCTAssertEqual(game.signSwing(age: 1.0), 0, "and come to rest")
    }
}
