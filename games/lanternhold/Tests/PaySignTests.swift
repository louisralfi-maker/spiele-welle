import CoreGraphics
import Foundation
import XCTest
@testable import Lanternhold

/// The count's step 5 (build 3, lane 1; the director's notes of 16.11., 12:44, P1 to P7): at a plot with more than one
/// offer the builder's models stand on their trestles on the side of the lord's spot away from his board; no figure, no
/// coin, no sign. The row's places and catch areas for two and three offers (P5, P6), the main gate's row clear of the
/// lord and of the gate's opening (P3, P7), a row moved to fit, the hop and the glint (P4); through the game: the models
/// in the world behind the figures with no mark and no figure at the plot, a touch bringing the counter in the row's slot
/// with the models on its cap, the chosen one lifted and the other dimmed (step 6, R1), the swap a plank up or down
/// (R2), the main gate fitting on every day and the line-2 and line-3 plots (R8), no gold at nothing paid (R4), the fade as the plot is built, no catch at night, VoiceOver's names and prices, no card from a plot.
/// (The file keeps its step 4 name for the join.)
@MainActor
final class PaySignTests: XCTestCase {
    private var directory: URL!
    private let pro = PixelScale(physicalWidth: 2622, physicalHeight: 1206)
    private let proPoints = CGSize(width: 874, height: 402)

    override func setUp() async throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("lanternhold-models-\(UUID().uuidString)", isDirectory: true)
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

    /// The smallest touch target in game px on the phones the game runs on (44 pt: 22 px at 2 points per game px, 19 on
    /// a Pro Max, 15 to 18 on the 2x phones with a small scale).
    private let minimums: [Double] = [15, 18, 19, 22]

    /// The gatehouse's passage and the postern's as a row sees them.
    private var passages: [PayDoor] {
        SceneLayout.castlePassages.map { PayDoor.passage($0, leaf: PayModelRow.doorCover) }
    }

    /// The line-1 engine's empty plot (the main gate's), the only plot with two offers on day 3 (seed 2), the lord
    /// standing at its spot.
    private func engineGame(gold: Int = 200, hour: String = "10", reduceMotion: Bool = false) -> GameModel {
        var values = ["GWStage": "world", "GWSeed": "2", "GWCameraX": "1455", "GWGold": "\(gold)",
                      "GWWeather": "clear"]
        if Double(hour) ?? 10 >= 18 {
            values["GWNight"] = "3"
            values["GWHour"] = hour
        } else {
            values["GWDay"] = "3"
            values["GWClock"] = hour
        }
        if reduceMotion { values["GWReduceMotion"] = "YES" }
        let game = model(values)
        game.withDriver { driver in
            driver.state.plots[Realm.lines[0].engine].item = nil
            driver.state.plots[Realm.lines[0].engine].job = nil
        }
        _ = game.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
        _ = game.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
        // LANE-B: B3 (gate M2): the marks come by the presence rule (from share 0 over 0.15 s), so the two frames above
        // ask for them but draw none; one presence step and a frame bring them whole, as they stood before B3, so a
        // mark the tests find absent is absent by the rule, not caught before its coming. Nothing else moves.
        game.stepPresence(0.3)
        _ = game.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
        // LANE-B end
        return game
    }

    private func meets(_ a: SIMD4<Float>, _ b: SIMD4<Float>) -> Bool {
        a.x < b.x + b.z && b.x < a.x + a.z && a.y < b.y + b.w && b.y < a.y + a.w
    }

    // MARK: - The pure places

    /// Two and three offers (P6), the board on either side, at every scale: the trestles 3 px apart, the nearest 4 px
    /// from the lord's rect on the side away from the board, each model's top at most at his shoulder; each catch area
    /// its trestle and model together, at least the touch target both ways and 24 px tall (P5), the areas never
    /// overlapping.
    func testTheRowsPlacesAndCatchAreasForTwoAndThreeOffers() {
        for minimum in minimums {
            for count in [2, 3] {
                for side in [1.0, -1.0] {
                    let row = PayModelRow.make(plot: 4, spot: 1440, side: side, offers: offers(count), minimum: minimum)
                    let what = "\(count) offers, side \(side), minimum \(minimum)"
                    XCTAssertEqual(row.models.count, count, what)
                    XCTAssertEqual(row.side, side, what)
                    XCTAssertEqual(row.right - row.left, PayModelRow.width(count), accuracy: 1e-9, what)
                    // Step 6 (R1): `side` is the slot's side (with no board wider than the row, the slot is the row).
                    if side > 0 {
                        XCTAssertEqual(row.left - row.lordSpan.upperBound, PayModelRow.lordGap, accuracy: 1e-9,
                                       what + ": 4 px from his rect, right of him")
                    } else {
                        XCTAssertEqual(row.lordSpan.lowerBound - row.right, PayModelRow.lordGap, accuracy: 1e-9,
                                       what + ": 4 px from his rect, left of him")
                    }
                    let slotted = PayModelRow.make(plot: 4, spot: 1440, side: side, offers: offers(count),
                                                   minimum: minimum, slotWidth: 90)
                    XCTAssertEqual(slotted.slotWidth, 90, what)
                    XCTAssertEqual(slotted.left - slotted.slotLeft, ((90 - PayModelRow.width(count)) / 2).rounded(.down),
                                   accuracy: 1e-9, what + ": the trestles centred in a wider slot")
                    for model in row.models {
                        let drawn = model.drawn()
                        // Step 6 (R3): the catapult's cup rises 4 px over the ballista's top, so over his shoulder.
                        let rise = model.item == .catapult ? 4.0 : 0
                        XCTAssertLessThanOrEqual(drawn.top, PayModelRow.shoulder + rise, what + ": at most at his shoulder")
                        XCTAssertGreaterThanOrEqual(model.area.width, minimum - 1e-9, what + ": 44 pt wide")
                        XCTAssertGreaterThanOrEqual(model.area.height, max(PayModelRow.catchHeight, minimum) - 1e-9,
                                                    what + ": 48 pt tall")
                        XCTAssertLessThanOrEqual(model.area.left, drawn.left + 1.5, what + ": the trestle inside")
                        XCTAssertGreaterThanOrEqual(model.area.right, drawn.right - 1.5, what)
                        XCTAssertLessThanOrEqual(model.area.bottom, 0, what + ": from the ground")
                        XCTAssertGreaterThanOrEqual(model.area.top, model.drawn(lift: PayModelRow.chosenLift).top,
                                                    what + ": over the chosen model too")
                    }
                    for (a, b) in zip(row.models, row.models.dropFirst()) {
                        XCTAssertEqual(b.left - (a.left + Double(PayModelRow.cell)), Double(PayModelRow.gap),
                                       accuracy: 1e-9, what + ": 3 px between the trestles")
                        XCTAssertLessThanOrEqual(a.area.right, b.area.left + 1e-9, what + ": the areas never overlap")
                    }
                }
            }
        }
    }

    /// R1, R8 (pure): the main gate's engine plot. The slot (66 px, the widest board of 70 and 110 in coins only) stands
    /// on the gate's side of the lord, between the gate's right leaf (covered by 6 px at most, the opening free) and the
    /// barracks' archer half; the lord moved 15 px to make room (the director's call 1). Every board stands in the slot,
    /// off the recruits' halves and Marek's cart, so it fits on every day.
    func testTheMainGatesRow() {
        let plot = Realm.lines[0].engine
        let options = [BuildOption(item: .ballista, price: Balance.standard.price(.ballista), isRebuild: false),
                       BuildOption(item: .catapult, price: Balance.standard.price(.catapult), isRebuild: false)]
        let widths = PayModelRow.boardWidths(options)
        XCTAssertEqual(widths, [66, 66], "seven and eleven big coins, five to a row")
        let archerX = KingTargets.barracksX - TouchThings.recruitOffset
        let guardX = KingTargets.barracksX + TouchThings.recruitOffset
        let blocks = [(archerX - TouchThings.recruitHalf)...(archerX + TouchThings.recruitHalf),
                      (guardX - TouchThings.recruitHalf)...(guardX + TouchThings.recruitHalf),
                      CourtLayout.marekCartX...(CourtLayout.marekCartX + Double(SpriteID.marekCart.size.width))]
        let row = PayModelRow.place(plot: plot, base: Realm.plots[plot].x, offers: options, minimum: 22,
                                    doors: passages, others: [], boardWidths: widths, bounds: 0...Realm.walkEnd,
                                    blocks: blocks)
        XCTAssertTrue(row.fits, "it fits, the cart's days included")
        XCTAssertEqual(row.side, -1, "the slot on the gate's side")
        XCTAssertEqual(row.shift, 15, accuracy: 1e-9, "the lord moved 15 px")
        XCTAssertEqual(row.spot, 1455, accuracy: 1e-9)
        XCTAssertEqual(row.slotLeft, 1377, accuracy: 1e-9)
        XCTAssertEqual(row.slotRight, 1443, accuracy: 1e-9)
        XCTAssertEqual(row.lordSpan.lowerBound - row.slotRight, PayModelRow.lordGap, accuracy: 1e-9, "4 px from him")
        XCTAssertEqual(row.models.map(\.item), [.ballista, .catapult])
        XCTAssertGreaterThanOrEqual(row.left, row.slotLeft - 1e-9, "the trestles inside the slot")
        XCTAssertLessThanOrEqual(row.right, row.slotRight + 1e-9)
        let gate = passages[0]
        XCTAssertGreaterThanOrEqual(row.slot.lowerBound, gate.opening.upperBound - 1e-9, "never before the opening")
        XCTAssertLessThanOrEqual(gate.span.upperBound - row.slot.lowerBound, PayModelRow.doorCover + 1e-9,
                                 "the leaf: 6 px at most")
        XCTAssertTrue(row.clear(of: passages))
        for width in widths {
            let board = row.boardSpan(width: width)
            XCTAssertGreaterThanOrEqual(board.lowerBound, row.slotLeft - 1e-9, "the board in the slot")
            XCTAssertLessThanOrEqual(board.upperBound, row.slotRight + 1e-9)
            for block in blocks {
                XCTAssertFalse(board.lowerBound < block.upperBound && block.lowerBound < board.upperBound,
                               "the board off \(block)")
            }
        }
        for block in blocks {
            XCTAssertFalse(row.lordSpan.lowerBound < block.upperBound && block.lowerBound < row.lordSpan.upperBound,
                           "the lord off \(block)")
        }
    }

    /// R1 (call 1): a slot that meets a door's opening at its plot moves the lord's spot away from it by the missing
    /// pixels, 15 px at most at a plot with models; past that it does not force it.
    func testARowMovesTheSpotToFitAndNeverPastFifteen() {
        // A door whose leaves stand 6 px inside 920 ... 945: its opening 926 ... 939. At 1000 the slot (937 ... 988) would
        // stand 2 px in front of the opening; two pixels to the right it covers only the 6 px leaf.
        let door = PayDoor.passage(920...945, leaf: 6)
        let row = PayModelRow.place(plot: 4, base: 1000, offers: offers(2), minimum: 22, doors: [door], others: [],
                                    boardWidths: [40], bounds: 0...Realm.walkEnd)
        XCTAssertTrue(row.fits)
        XCTAssertEqual(row.side, -1, "a tie keeps the slot on the left")
        XCTAssertEqual(row.shift, 2, accuracy: 1e-9, "moved by the missing pixels")
        XCTAssertEqual(row.spot, 1002, accuracy: 1e-9)
        XCTAssertGreaterThanOrEqual(row.slot.lowerBound, door.opening.upperBound - 1e-9)
        // The right side blocked: a door whose opening ends at 952 needs exactly 15 px, one at 953 needs 16.
        let blocked: [ClosedRange<Double>] = [1012...1100]
        let fifteen = PayModelRow.place(plot: 4, base: 1000, offers: offers(2), minimum: 22,
                                        doors: [PayDoor.passage(920...958, leaf: 6)], others: [], boardWidths: [40],
                                        bounds: 0...Realm.walkEnd, blocks: blocked)
        XCTAssertTrue(fifteen.fits)
        XCTAssertEqual(fifteen.side, -1)
        XCTAssertEqual(fifteen.shift, 15, accuracy: 1e-9, "15 px is allowed at a plot with models")
        let sixteen = PayModelRow.place(plot: 4, base: 1000, offers: offers(2), minimum: 22,
                                        doors: [PayDoor.passage(920...959, leaf: 6)], others: [], boardWidths: [40],
                                        bounds: 0...Realm.walkEnd, blocks: blocked)
        XCTAssertFalse(sixteen.fits, "16 px is not: said, not forced")
        XCTAssertTrue(sixteen.clear(of: [PayDoor.passage(920...959, leaf: 6)]), "the doors still free")
        // A door all round the plot: neither side fits within 15 px: unforced at the plot's place.
        let wide = PayDoor.passage(900...1100, leaf: 6)
        let unforced = PayModelRow.place(plot: 4, base: 1000, offers: offers(2), minimum: 22, doors: [wide],
                                         others: [], boardWidths: [80], bounds: 0...Realm.walkEnd)
        XCTAssertFalse(unforced.fits, "said so, not forced")
        XCTAssertEqual(unforced.spot, 1000, accuracy: 1e-9)
        // Two sides that fit: the one whose slot covers less of the other things wins.
        let crowded = PayModelRow.place(plot: 4, base: 1000, offers: offers(2), minimum: 22, doors: [],
                                        others: [940...990], boardWidths: [40], bounds: 0...Realm.walkEnd)
        XCTAssertEqual(crowded.side, 1, "the models stand where nothing else does")
        XCTAssertEqual(crowded.shift, 0, accuracy: 1e-9)
    }

    /// A slot keeps off `blocks` (Marek's cart, the barracks' recruit halves) as well. When no place keeps off them, the
    /// first place that keeps the doors free stands, and the row says so (`fits` false).
    func testABoardKeepsOffTheBlocksOrTheRowSaysSo() {
        // A block on the right: the slot goes left.
        let left = PayModelRow.place(plot: 4, base: 1000, offers: offers(2), minimum: 22, doors: [], others: [],
                                     boardWidths: [40], bounds: 0...Realm.walkEnd, blocks: [1020...1040])
        XCTAssertTrue(left.fits)
        XCTAssertEqual(left.side, -1, "the slot on the free side")
        // Blocks on both sides and a door on the left: the doors still win, the row says it does not fit.
        let door = PayDoor.passage(900...945, leaf: 6)
        let boxed = PayModelRow.place(plot: 4, base: 1000, offers: offers(2), minimum: 22, doors: [door], others: [],
                                      boardWidths: [40], bounds: 0...Realm.walkEnd, blocks: [930...990, 1012...1070])
        XCTAssertFalse(boxed.fits, "said so")
        XCTAssertTrue(boxed.clear(of: [door]), "the door's opening stays free")
        XCTAssertEqual(boxed.side, -1)
    }

    /// R1, R8 through the game: on day 3 the main gate's row fits (`fits` true), the slot at 1377 ... 1443 and the lord at
    /// 1455; on every day of two weeks (Marek's days among them) the same place holds and the boards stand off every
    /// door's opening, the recruits' halves and the cart.
    func testTheMainGatesCounterFitsOnEveryDay() throws {
        let game = engineGame()
        let plot = Realm.lines[0].engine
        let row = try XCTUnwrap(game.touch.models.first { $0.plot == plot })
        let state = try XCTUnwrap(game.driver?.state)
        XCTAssertTrue(row.fits, "it fits")
        XCTAssertEqual(row.side, -1)
        XCTAssertEqual(row.spot, 1455, accuracy: 1e-9)
        XCTAssertEqual(row.slotLeft, 1377, accuracy: 1e-9)
        XCTAssertEqual(row.slotRight, 1443, accuracy: 1e-9)
        let doors = game.modelDoors(state)
        XCTAssertTrue(row.clear(of: doors), "the doors free")
        let framing = try XCTUnwrap(game.touch.framing)
        let minimum = game.touchMinimum(framing: framing)
        let offers = Build.options(state, plot: plot, balance: .standard)
        XCTAssertEqual(offers.count, 2)
        let recruits = game.touch.things.filter { $0.kind == .recruit }.map { ($0.x - $0.halfWidth)...($0.x + $0.halfWidth) }
        XCTAssertEqual(recruits.count, 2, "the archer's half and the guard's")
        let cart = CourtLayout.marekCartX...(CourtLayout.marekCartX + Double(SpriteID.marekCart.size.width))
        var cartDays = 0
        for day in 1...14 {
            var dayState = state
            dayState.day = day
            dayState.hour = 12
            if CourtLayout.props(dayState, catalog: .standard).contains(where: { $0.sprite == .marekCart }) { cartDays += 1 }
            let dayRow = game.modelRow(plot, offers: offers, state: dayState, balance: .standard, minimum: minimum,
                                       key: "every-day-\(day)")
            XCTAssertTrue(dayRow.fits, "day \(day): fits")
            XCTAssertEqual(dayRow.slotLeft, 1377, accuracy: 1e-9, "day \(day)")
            XCTAssertTrue(dayRow.clear(of: doors), "day \(day): no door's opening, a leaf by 6 px at most")
            for width in PayModelRow.boardWidths(offers) {
                let board = dayRow.boardSpan(width: width)
                for block in recruits + [cart] {
                    XCTAssertFalse(board.lowerBound < block.upperBound && block.lowerBound < board.upperBound,
                                   "day \(day): the board off \(block)")
                }
            }
        }
        XCTAssertGreaterThan(cartDays, 0, "Marek's days were among them")
    }

    /// R8: the engine plots of lines 2 and 3 (990, 676) take the same law: the slot beside the lord, 4 px from him, off
    /// every door's opening, the lord moved 15 px at most, every board inside the slot.
    func testTheLineTwoAndThreeEngineRowsFit() throws {
        let game = engineGame()
        let state = try XCTUnwrap(game.driver?.state)
        let framing = try XCTUnwrap(game.touch.framing)
        let minimum = game.touchMinimum(framing: framing)
        let options = [BuildOption(item: .ballista, price: Balance.standard.price(.ballista), isRebuild: false),
                       BuildOption(item: .catapult, price: Balance.standard.price(.catapult), isRebuild: false)]
        let doors = game.modelDoors(state)
        for plot in [Realm.lines[1].engine, Realm.lines[2].engine] {
            let row = game.modelRow(plot, offers: options, state: state, balance: .standard, minimum: minimum,
                                    key: "line-\(plot)")
            XCTAssertTrue(row.fits, "plot \(plot): fits")
            XCTAssertLessThanOrEqual(row.shift, Double(PayModelRow.maxShift), "plot \(plot)")
            XCTAssertTrue(row.clear(of: doors), "plot \(plot): the doors free")
            let gap = row.side < 0 ? row.lordSpan.lowerBound - row.slotRight : row.slotLeft - row.lordSpan.upperBound
            XCTAssertEqual(gap, PayModelRow.lordGap, accuracy: 1e-9, "plot \(plot): 4 px from him")
            XCTAssertGreaterThanOrEqual(row.left, row.slotLeft - 1e-9, "plot \(plot): the trestles in the slot")
            XCTAssertLessThanOrEqual(row.right, row.slotRight + 1e-9)
            for width in PayModelRow.boardWidths(options) {
                let board = row.boardSpan(width: width)
                XCTAssertGreaterThanOrEqual(board.lowerBound, row.slotLeft - 1e-9, "plot \(plot): the board in the slot")
                XCTAssertLessThanOrEqual(board.upperBound, row.slotRight + 1e-9)
                XCTAssertFalse(board.lowerBound < row.lordSpan.upperBound && row.lordSpan.lowerBound < board.upperBound,
                               "plot \(plot): the lord off the board")
            }
        }
    }

    /// P6: three offers take three models in one row, side by side, every area apart and inside the world.
    func testThreeOffersTakeThreeModels() {
        let row = PayModelRow.place(plot: 4, base: 1000, offers: offers(3), minimum: 22, doors: [], others: [],
                                    boardWidths: [40, 40, 40], bounds: 0...Realm.walkEnd)
        XCTAssertEqual(row.models.map(\.item), [.ballista, .catapult, .archerTower])
        XCTAssertEqual(row.models.map { PayModelRow.frame(for: $0.item) }, [1, 2, 3], "the house for any other building")
        XCTAssertEqual(row.right - row.left, Double(3 * PayModelRow.cell + 2 * PayModelRow.gap), accuracy: 1e-9)
        for model in row.models {
            XCTAssertEqual(row.model(x: model.middle, lift: 12)?.item, model.item, "a touch finds its model")
        }
        XCTAssertNil(row.model(x: row.left - 30, lift: 12), "beside the row: nothing")
        XCTAssertNil(row.model(x: row.models[0].middle, lift: 60), "far above it: nothing")
        let edge = PayModelRow.place(plot: 4, base: 60, offers: offers(3), minimum: 22, doors: [], others: [],
                                     boardWidths: [40, 40, 40], bounds: 0...Realm.walkEnd)
        XCTAssertGreaterThanOrEqual(edge.slot.lowerBound, 0, "at the world's left end the row stands inside it")
    }

    /// The strip's frames: the trestle, three models, their rims and four glint steps each, and the row's second
    /// trestle (step 6), in the 24 x 17 cell.
    func testTheModelsFrames() {
        XCTAssertEqual(SpriteID.paySign.size, PixelSize(width: 24, height: 17))
        XCTAssertEqual(SpriteID.paySign.size, PixelSize(width: PayModelRow.cell, height: PayModelRow.cellHeight))
        XCTAssertEqual(SpriteID.paySign.frameCount, 23)
        XCTAssertEqual(PayModelRow.shadowFrame(for: .ballista), 20)
        XCTAssertEqual(PayModelRow.shadowFrame(for: .smithy), 22)
        XCTAssertEqual(PayModelRow.trestleFrame, 0)
        XCTAssertEqual(PayModelRow.trestleFrame(index: 0), 0)
        XCTAssertEqual(PayModelRow.trestleFrame(index: 1), 19, "the second trestle is its own")
        XCTAssertEqual(PayModelRow.frame(for: .ballista), 1)
        XCTAssertEqual(PayModelRow.frame(for: .catapult), 2)
        XCTAssertEqual(PayModelRow.frame(for: .smithy), 3)
        XCTAssertEqual(PayModelRow.rimFrame(for: .catapult), 5)
        XCTAssertEqual(PayModelRow.glintFrame(for: .ballista, step: 0), 7)
        XCTAssertEqual(PayModelRow.glintFrame(for: .smithy, step: 3), 18)
        XCTAssertEqual(PayFreeze.parse("hop:0.075"), .hop(0.075))
        XCTAssertEqual(PayFreeze.hop(0.2).hopHold, 0.2)
        XCTAssertNil(PayFreeze.parse("hop:x"))
    }

    /// P4, R5, R6: the hop (each model 2 px for 0.15 s, 0.12 s after the one before; on the first touch of a row the
    /// touched model first; none under Reduce Motion) and the glint (3.4 to 4.8 s apart, about one in five left out,
    /// each model in its own phase; none under Reduce Motion).
    func testTheHopAndTheGlint() {
        XCTAssertEqual(PayModelRow.hop(age: 0, index: 0, reduceMotion: false), 0)
        XCTAssertEqual(PayModelRow.hop(age: 0.075, index: 0, reduceMotion: false), 2, "the first at its top")
        XCTAssertEqual(PayModelRow.hop(age: 0.075, index: 1, reduceMotion: false), 0, "the second not yet")
        XCTAssertEqual(PayModelRow.hop(age: 0.195, index: 1, reduceMotion: false), 2, "the second 0.12 s later")
        XCTAssertEqual(PayModelRow.hop(age: 0.195, index: 0, reduceMotion: false), 0, "the first down again")
        XCTAssertEqual(PayModelRow.hop(age: 1, index: 0, reduceMotion: false), 0, "and at rest")
        XCTAssertEqual(PayModelRow.hop(age: 0.075, index: 1, reduceMotion: false, lead: 1, count: 2), 2,
                       "R5: the touched one (the second) hops first")
        XCTAssertEqual(PayModelRow.hop(age: 0.075, index: 0, reduceMotion: false, lead: 1, count: 2), 0)
        XCTAssertEqual(PayModelRow.hop(age: 0.195, index: 0, reduceMotion: false, lead: 1, count: 2), 2,
                       "the other 0.12 s later")
        XCTAssertEqual(PayModelRow.hopLength(2), 0.27, accuracy: 1e-9, "the board rises after 0.27 s")
        for age in stride(from: 0.0, to: 0.6, by: 0.01) {
            XCTAssertEqual(PayModelRow.hop(age: age, index: 0, reduceMotion: true), 0, "Reduce Motion: no hop")
        }
        for plot in [4, 10, 16] {
            for index in 0..<2 {
                var steps: [Int: Int] = [:]
                for tick in 0..<(160 * 100) {
                    if let step = PayModelRow.glint(time: Double(tick) / 100, plot: plot, index: index,
                                                    reduceMotion: false) {
                        steps[tick] = step
                    }
                }
                let starts = steps.keys.filter { steps[$0] == 0 && steps[$0 - 1] == nil }.sorted()
                let gaps = zip(starts, starts.dropFirst()).map { Double($1 - $0) / 100 }
                let what = "plot \(plot), model \(index)"
                XCTAssertGreaterThan(gaps.count, 20, what)
                for gap in gaps {
                    XCTAssertTrue((3.39...4.81).contains(gap) || gap > 7.4, what + ": a gap of \(gap) s")
                }
                let even = gaps.filter { $0 <= 4.81 }
                XCTAssertGreaterThan((even.max() ?? 0) - (even.min() ?? 0), 0.4, what + ": not a metronome")
                let skipped = gaps.filter { $0 > 7.4 }.count
                XCTAssertGreaterThan(skipped, 0, what + ": some cycles are left out")
                XCTAssertLessThan(skipped, gaps.count / 2, what + ": about one in five")
                XCTAssertEqual(Set(steps.values), [0, 1, 2, 3], what + ": it passes over in four steps")
            }
        }
        let first = (0..<800).first { PayModelRow.glint(time: Double($0) / 100, plot: 4, index: 0, reduceMotion: false) != nil }
        let second = (0..<800).first { PayModelRow.glint(time: Double($0) / 100, plot: 4, index: 1, reduceMotion: false) != nil }
        XCTAssertNotEqual(first, second, "out of phase")
        let still = (0..<800).compactMap { PayModelRow.glint(time: Double($0) / 100, plot: 4, index: 0, reduceMotion: true) }
        XCTAssertTrue(still.isEmpty, "Reduce Motion: no glint (a still one would blink)")
    }

    // MARK: - Through the game

    /// P4 idle, P7: by day the main gate's engine plot carries its two models on their trestles, lit by the hour, drawn
    /// behind the lord; his rect meets no model's; no model stands in front of a door's opening; at the plot there is no
    /// figure, no coin, no hollow and no mark (the models replace the site's mark, its pool and its footing).
    func testTheModelsStandInTheWorld() throws {
        let game = engineGame()
        let plot = Realm.lines[0].engine
        let row = try XCTUnwrap(game.touch.models.first { $0.plot == plot }, "the engine's row")
        XCTAssertEqual(row.models.map(\.item), [.ballista, .catapult])
        XCTAssertEqual(row.spot, 1455, accuracy: 1e-9, "moved 15 px from the plot's place (call 1)")
        let state = try XCTUnwrap(game.driver?.state)
        XCTAssertTrue(row.clear(of: game.modelDoors(state)), "off every door's opening")
        let frame = game.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
        let framing = try XCTUnwrap(game.touch.framing)
        let models = frame.actors.filter { $0.sprite == .paySign }
        XCTAssertEqual(models.filter { $0.frame == PayModelRow.trestleFrame }.count, 1, "two trestles")
        XCTAssertEqual(models.filter { $0.frame == PayModelRow.secondTrestleFrame }.count, 1, "the second its own")
        XCTAssertTrue(models.contains { $0.frame == 1 } && models.contains { $0.frame == 2 }, "the two models")
        XCTAssertFalse(models.contains { $0.frame == 4 || $0.frame == 5 }, "no rim at rest")
        // R8: at idle the models' feet stand on the trestles' beam, and no shadow (that is the counter's).
        let beam = framing.deviceY(lift: PayModelRow.modelLift)
        for frameIndex in [PayModelRow.frame(for: .ballista), PayModelRow.frame(for: .catapult)] {
            let actor = try XCTUnwrap(models.first { $0.frame == frameIndex })
            XCTAssertEqual(Double(actor.rect.y + actor.rect.w), beam, accuracy: 0.5, "model \(frameIndex) on its trestle")
        }
        XCTAssertFalse(models.contains { $0.frame >= 20 }, "no contact shadow at rest")
        XCTAssertTrue(models.allSatisfy { $0.isLit && !$0.isEmissive }, "things of the world, lit by the hour")
        let body = state.lordOrDefault.body
        let lordIndex = try XCTUnwrap(frame.actors.firstIndex { $0.sprite == body }, "the lord is drawn")
        let lord = frame.actors[lordIndex]
        for model in models {
            XCTAssertFalse(meets(model.rect, lord.rect), "the lord's rect meets no model's")
        }
        XCTAssertTrue(frame.actors.indices.filter { frame.actors[$0].sprite == .paySign }.allSatisfy { $0 < lordIndex },
                      "behind the figures")
        let left = Float(framing.deviceX(stageX: row.left - 2))
        let right = Float(framing.deviceX(stageX: row.right + 2))
        let quiet: Set<SpriteID> = [.payCoin, .hudCoinTen, .hudHollow, .hudHollowTen, .tapBuild]
        let atThePlot = frame.actors.filter {
            (quiet.contains($0.sprite) || ($0.sprite == .hudFigures && !$0.isEmissive))
                && $0.rect.x + $0.rect.z > left && $0.rect.x < right
        }
        XCTAssertTrue(atThePlot.isEmpty, "no figure, coin or hollow at the plot (\(atThePlot.map(\.sprite)))")
        let markX = framing.deviceX(stageX: KingTargets.spotX(plot: plot, layouts: KingTargets.layouts(state,
                                                                                                     balance: .standard)))
        XCTAssertFalse(frame.actors.contains {
            $0.sprite == .tapBuild && abs(Double($0.rect.x + $0.rect.z / 2) - markX) < 4 * framing.scale
        }, "the models replace the site's mark")
        // LANE-B: B3 (gate M2): the control: every mark this frame asks for stands whole (none is caught in its coming),
        // and the plot asks for none.
        XCTAssertTrue(game.touch.markShows.values.allSatisfy { !$0.wanted || $0.whole.isWhole }, "the marks have come")
        XCTAssertNil(game.touch.markShows["touch-plot-\(plot)"], "the plot asks for no mark")
        // LANE-B end
        XCTAssertTrue(game.modelWord.contains("\(plot):ballista,catapult"), "the scene names it (\(game.modelWord))")
    }

    /// R1, R2, R4, R5, R8, the director's calls 2, 5 and 7: a touch on the ballista plays the hop (the ballista first)
    /// and then brings its counter: seven big coins (no bar) on the ground in the row's slot, on no post, the trestles
    /// gone, both models standing on its top cap with their contact shadows (the ballista lifted 2 px with its rim, the
    /// catapult at 75 %); nothing paid shows no gold; the lord's rect meets no model and no board; every throw's peak
    /// clears the taller model by 2 px; a hold pays it once, the work starts and the models fade within 0.3 s. No card.
    func testATouchOnAModelRaisesItsCounter() throws {
        let game = engineGame()
        let plot = Realm.lines[0].engine
        let row = try XCTUnwrap(game.touch.models.first { $0.plot == plot })
        let ballista = try XCTUnwrap(row.models.first { $0.item == .ballista })
        let framing = try XCTUnwrap(game.touch.framing)
        let minimum = game.touchMinimum(framing: framing)
        XCTAssertEqual(game.modelAt((x: ballista.middle, lift: 12, minimum: minimum))?.item, .ballista,
                       "the finger finds the ballista")
        game.touchModel(ballista, holding: false)
        let board = try XCTUnwrap(game.touch.countBoard)
        XCTAssertEqual(board.model, .ballista)
        XCTAssertTrue(board.counter, "a counter")
        XCTAssertEqual(board.bottom, 0, "on the ground")
        XCTAssertEqual(game.touch.count?.price, Balance.standard.price(.ballista))
        XCTAssertEqual(board.layout.hollows.map(\.coin), Array(repeating: .big, count: 7), "seven big coins, no bar")
        XCTAssertEqual(board.stand, row.spot, accuracy: 1e-9, "he stands at the row's spot")
        XCTAssertEqual(Double(board.left), row.slotLeft, accuracy: 1e-9, "the counter in the row's slot")
        XCTAssertEqual(Double(board.left + board.layout.width), row.slotRight, accuracy: 1e-9)
        XCTAssertEqual(board.modelsTop, PayModelRow.height(.catapult), accuracy: 1e-9, "the catapult is the taller")
        XCTAssertEqual(try XCTUnwrap(game.touch.modelHop[plot]), game.clock.elapsed, accuracy: 1e-9,
                       "R5: the hop on the first touch")
        XCTAssertEqual(game.touch.modelHopLead[plot], 0, "the ballista first")
        XCTAssertEqual(game.touch.count?.riseShare ?? 1, 0, "the board waits for the hop")
        XCTAssertNil(game.overlay, "no card")
        run(game, seconds: 0.2)
        XCTAssertEqual(game.touch.count?.riseShare ?? 1, 0, "still waiting at 0.2 s")
        run(game, seconds: 1.0)
        XCTAssertEqual(game.touch.count?.riseShare ?? 0, 1, "then it rises")
        XCTAssertTrue(game.modelWord.contains("\(plot):ballista,catapult=ballista"), "the ballista chosen")
        XCTAssertEqual(game.touch.modelRide[plot] ?? 0, board.top, accuracy: 1e-9, "the models rode up onto the cap")
        let frame = game.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
        let seen = try XCTUnwrap(game.touch.framing)
        let models = frame.actors.filter { $0.sprite == .paySign }
        XCTAssertFalse(models.contains { $0.frame == PayModelRow.trestleFrame || $0.frame == PayModelRow.secondTrestleFrame },
                       "the trestles have gone")
        XCTAssertTrue(models.contains { $0.frame == PayModelRow.rimFrame(for: .ballista) }, "its warm rim")
        let catapult = try XCTUnwrap(models.first { $0.frame == PayModelRow.frame(for: .catapult) })
        XCTAssertEqual(catapult.tint.x, PayModelRow.dimmed, accuracy: 1e-6, "the other at 75 %")
        let ballistaActor = try XCTUnwrap(models.first { $0.frame == PayModelRow.frame(for: .ballista) })
        let rimActor = try XCTUnwrap(models.first { $0.frame == PayModelRow.rimFrame(for: .ballista) })
        XCTAssertEqual(ballistaActor.rect.y, rimActor.rect.y, "the rim on the model")
        XCTAssertEqual(Double(catapult.rect.y - ballistaActor.rect.y), 2 * seen.scale, accuracy: 0.5,
                       "the chosen one 2 px higher")
        let capY = seen.deviceY(lift: board.top)
        XCTAssertEqual(Double(catapult.rect.y + catapult.rect.w), capY, accuracy: 0.5, "its feet on the cap")
        XCTAssertEqual(models.filter { $0.frame == PayModelRow.shadowFrame(for: .ballista)
                                       || $0.frame == PayModelRow.shadowFrame(for: .catapult) }.count, 2,
                       "a contact shadow under each")
        for shadow in models where shadow.frame >= 20 {
            XCTAssertEqual(Double(shadow.rect.y + shadow.rect.w), capY + seen.scale, accuracy: 0.5,
                           "the shadow on the cap's top row")
        }
        XCTAssertFalse(frame.actors.contains { $0.sprite == .payBoard && $0.frame == PayBoardLayout.post },
                       "no post under a counter")
        XCTAssertFalse(frame.actors.contains { [.hudCoinTen, .payCoin, .hudCoinBar].contains($0.sprite) },
                       "R4: nothing paid, no gold on the board")
        let state = try XCTUnwrap(game.driver?.state)
        let body = state.lordOrDefault.body
        let lord = try XCTUnwrap(frame.actors.first { $0.sprite == body })
        for actor in frame.actors where actor.sprite == .paySign || actor.sprite == .payBoard {
            XCTAssertFalse(meets(actor.rect, lord.rect), "the lord's rect meets no model and no board")
        }
        let gate = SceneLayout.castlePassages[0]
        XCTAssertLessThanOrEqual(gate.upperBound - Double(board.left), PayModelRow.doorCover + 1e-9,
                                 "the counter covers the gate's leaf by 6 px at most")
        // The throw over the counter (call 2): at its peak the whole coin stands 2 px over the taller model.
        let clear = GameModel.countModelsClear(boardTop: board.top, modelsTop: board.modelsTop, coinHeight: 11)
        let peak = GameModel.countThrow(0.45, fromX: 1450, fromLift: 31, toX: 1420, toLift: board.top - 3, coinHeight: 11,
                                        clear: clear)
        XCTAssertGreaterThanOrEqual(peak.lift - 11, board.top + board.modelsTop + 2 - 1e-9, "the peak clears them")
        // The hold.
        run(game, seconds: 12) { game.touch.count?.ready == true }
        var count = try XCTUnwrap(game.touch.count)
        count.press()
        game.touch.count = count
        var highest = -Double.infinity
        for _ in 0..<120 {
            run(game, seconds: 1.0 / 60)
            let shot = game.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
            let shotFraming = try XCTUnwrap(game.touch.framing)
            for coin in shot.actors where coin.sprite == .hudCoinTen {
                highest = max(highest, shotFraming.lift(deviceY: Double(coin.rect.y + coin.rect.w)))
            }
            if game.touch.countLast.hasPrefix("paid") { break }
        }
        XCTAssertGreaterThanOrEqual(highest, board.top + board.modelsTop + 2 - 1.0,
                                    "the coins in the air went over the models")
        run(game, seconds: 3) { game.touch.countLast.hasPrefix("paid") }
        XCTAssertEqual(game.touch.countLast, "paid:touch-plot-\(plot)", "the hold paid the ballista")
        XCTAssertEqual(game.driver?.state.plots[plot].job?.target, .ballista, "the work starts")
        XCTAssertEqual(game.driver?.state.gold, 200 - Balance.standard.price(.ballista), "paid once")
        _ = game.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
        XCTAssertFalse(game.touch.models.contains { $0.plot == plot }, "built: the row has gone")
        XCTAssertFalse(game.touch.modelFades.isEmpty, "it fades")
        run(game, seconds: 0.4)
        _ = game.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
        XCTAssertTrue(game.touch.modelFades.isEmpty, "gone within 0.3 s")
    }

    /// R2: a touch on the other model swaps the counter at once (one board at the thing, never two): the catapult's
    /// eleven big coins in three rows, a plank higher than the ballista's seven in two, never fewer hollows nor a smaller
    /// board; the models ride with it; a let go hands the row back to its rest and pays nothing; a tap on the chosen model
    /// is a coin.
    func testTheOtherModelChangesTheBoard() throws {
        let game = engineGame()
        let plot = Realm.lines[0].engine
        let row = try XCTUnwrap(game.touch.models.first { $0.plot == plot })
        let ballista = try XCTUnwrap(row.models.first { $0.item == .ballista })
        let catapult = try XCTUnwrap(row.models.first { $0.item == .catapult })
        game.touchModel(ballista, holding: false)
        run(game, seconds: 1)
        let first = try XCTUnwrap(game.touch.countBoard)
        game.touchModel(catapult, holding: false)
        XCTAssertEqual(game.touch.count?.offer, .build(plot: plot, item: .catapult), "the catapult's board")
        let second = try XCTUnwrap(game.touch.countBoard)
        XCTAssertEqual(second.model, .catapult)
        XCTAssertNil(game.touch.countOld, "never two boards at the plot")
        XCTAssertEqual(game.touch.count?.riseShare ?? 0, 1, "the swapped counter stands at once")
        XCTAssertEqual(second.layout.hollows.map(\.coin), Array(repeating: .big, count: 11), "eleven big coins, no bar")
        XCTAssertGreaterThan(second.layout.hollows.count, first.layout.hollows.count, "the dearer has more hollows")
        XCTAssertGreaterThanOrEqual(second.layout.width, first.layout.width, "and no smaller board")
        XCTAssertEqual(second.layout.rows, 3)
        XCTAssertEqual(second.top - first.top, Double(PayBoardLayout.plank), accuracy: 1e-9, "a plank higher")
        XCTAssertEqual(second.left, first.left, "in the same slot")
        run(game, seconds: 0.3)
        XCTAssertEqual(game.touch.modelRide[plot] ?? 0, second.top, accuracy: 1e-9, "the models rode up with it")
        run(game, seconds: 12) { game.touch.count?.ready == true }
        game.touchModel(catapult, holding: false)
        XCTAssertEqual(game.touch.count?.offer, .build(plot: plot, item: .catapult), "a tap on the chosen one is a coin")
        run(game, seconds: 0.5)
        XCTAssertGreaterThan(game.touch.count?.placed ?? 0, 0, "the coin is on the board")
        var count = try XCTUnwrap(game.touch.count)
        count.letGo()
        game.touch.count = count
        run(game, seconds: 1.5)
        XCTAssertNil(game.touch.count, "the board has gone")
        XCTAssertNil(game.modelChosen(plot), "the row at rest again")
        XCTAssertEqual(game.touch.modelRide[plot] ?? 0, PayModelRow.modelLift, accuracy: 1e-9, "back on the trestles")
        XCTAssertNil(game.driver?.state.plots[plot].job, "nothing paid")
        XCTAssertEqual(game.driver?.state.gold, 200)
    }

    /// R1 under Reduce Motion: no hop and no ride; the models at rest and on the counter's cap change place in a
    /// cross-fade, and once it stands they are on the cap.
    func testReduceMotionCrossFadesOntoTheCounter() throws {
        let game = engineGame(reduceMotion: true)
        let plot = Realm.lines[0].engine
        let row = try XCTUnwrap(game.touch.models.first { $0.plot == plot })
        let ballista = try XCTUnwrap(row.models.first { $0.item == .ballista })
        game.touchModel(ballista, holding: false)
        XCTAssertEqual(game.touch.count?.riseShare ?? 1, 0)
        run(game, seconds: 0.5)
        let board = try XCTUnwrap(game.touch.countBoard)
        XCTAssertEqual(game.touch.modelRide[plot] ?? 0, board.top, accuracy: 1e-9, "on the cap, no ride")
        let frame = game.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
        let framing = try XCTUnwrap(game.touch.framing)
        let catapult = try XCTUnwrap(frame.actors.first { $0.sprite == .paySign && $0.frame == 2 && $0.tint.w > 0.5 })
        XCTAssertEqual(Double(catapult.rect.y + catapult.rect.w), framing.deviceY(lift: board.top), accuracy: 0.5)
    }

    /// The touch rule: a person standing inside a model's catch area wins the touch there.
    func testAPersonInsideTheCatchAreaWinsTheTouch() throws {
        let game = engineGame()
        let plot = Realm.lines[0].engine
        let row = try XCTUnwrap(game.touch.models.first { $0.plot == plot })
        let catapult = try XCTUnwrap(row.models.first { $0.item == .catapult })
        let framing = try XCTUnwrap(game.touch.framing)
        let minimum = game.touchMinimum(framing: framing)
        let place = (x: catapult.middle, lift: 12.0, minimum: minimum)
        // Step 6: with the lord at 1455 a townsman of day 3 may pass in front of the catapult (round lh-b3c-62); the
        // rule is tested from an empty street, then with one person put inside the area.
        game.touch.things.removeAll { $0.isPerson }
        XCTAssertEqual(game.modelAt(place)?.item, .catapult)
        game.touch.things.append(TouchThing(id: "touch-talk-test", kind: .talk, act: .talk(who: "test"),
                                            x: catapult.middle, standX: catapult.middle + 12, halfWidth: 6, top: 30,
                                            rank: TouchRules.rank(.talk), who: "test"))
        XCTAssertNil(game.modelAt(place), "the person wins")
    }

    /// The arrival (P4): the lord standing at the spot with no offer chosen set the hop going; under Reduce Motion the
    /// models do not hop and take a still warm rim for 0.6 s.
    func testTheArrivalHopAndItsStillForm() throws {
        let game = engineGame()
        let plot = Realm.lines[0].engine
        XCTAssertNotNil(game.touch.modelHop[plot], "he stands at the spot: the hop began")
        let still = engineGame(reduceMotion: true)
        XCTAssertNotNil(still.touch.modelHop[plot])
        let frame = still.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
        let models = frame.actors.filter { $0.sprite == .paySign }
        XCTAssertTrue(models.contains { $0.frame == PayModelRow.rimFrame(for: .ballista) }, "the still rim")
        XCTAssertTrue(models.contains { $0.frame == PayModelRow.rimFrame(for: .catapult) })
        let ballista = try XCTUnwrap(models.first { $0.frame == PayModelRow.frame(for: .ballista) })
        let catapult = try XCTUnwrap(models.first { $0.frame == PayModelRow.frame(for: .catapult) })
        XCTAssertEqual(ballista.rect.y, catapult.rect.y, "no hop")
        run(still, seconds: 0.8)
        let later = still.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
        XCTAssertFalse(later.actors.contains { $0.sprite == .paySign && $0.frame == PayModelRow.rimFrame(for: .ballista) },
                       "the rim goes after 0.6 s")
    }

    /// At night the models stand unlit and take no touch: the plot is no thing to touch, so no model catches a finger
    /// and none is an accessibility element; no glint.
    func testNightGivesNoCatch() throws {
        let game = engineGame(hour: "22")
        let plot = Realm.lines[0].engine
        let row = try XCTUnwrap(game.touch.models.first { $0.plot == plot }, "they still stand there at night")
        let framing = try XCTUnwrap(game.touch.framing)
        let frame = game.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
        let models = frame.actors.filter { $0.sprite == .paySign }
        XCTAssertFalse(models.isEmpty)
        XCTAssertTrue(models.allSatisfy { $0.isLit && !$0.isEmissive }, "unlit by anything of their own")
        XCTAssertFalse(models.contains { (7...18).contains($0.frame) }, "no glint at night")
        let minimum = game.touchMinimum(framing: framing)
        for model in row.models {
            XCTAssertNil(game.modelAt((x: model.middle, lift: 12, minimum: minimum)), "no catch at night")
        }
        game.setTouchViewSize(proPoints)
        game.refreshTouchSpots()
        XCTAssertFalse(game.touchSpots.contains { $0.id.hasPrefix("touch-model-") }, "no element at night")
    }

    /// VoiceOver: each model is an element named for its building and priced, at least 44 pt, left to right; the plot
    /// itself is no element while its models stand; a double tap pays the offer in one step.
    func testVoiceOverNamesAndPricesEachModel() throws {
        let game = engineGame()
        let plot = Realm.lines[0].engine
        game.setTouchViewSize(proPoints)
        _ = game.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
        game.refreshTouchSpots()
        let ballista = try XCTUnwrap(game.touchSpots.first { $0.id == "touch-model-\(plot)-ballista" })
        let catapult = try XCTUnwrap(game.touchSpots.first { $0.id == "touch-model-\(plot)-catapult" })
        XCTAssertEqual(ballista.label, "Build: Ballista")
        XCTAssertEqual(ballista.value, "\(Balance.standard.price(.ballista)) gold")
        XCTAssertEqual(catapult.value, "\(Balance.standard.price(.catapult)) gold")
        XCTAssertFalse(game.touchSpots.contains { $0.id == "touch-plot-\(plot)" }, "the plot gives way to its models")
        for spot in [ballista, catapult] {
            XCTAssertGreaterThanOrEqual(spot.rect.width * proPoints.width, 43.5, "\(spot.id) 44 pt wide")
            XCTAssertGreaterThanOrEqual(spot.rect.height * proPoints.height, 47.5, "\(spot.id) 48 pt tall")
        }
        XCTAssertLessThanOrEqual(ballista.rect.maxX, catapult.rect.minX + 0.0001, "side by side, never over each other")
        let xs = game.touchSpots.map(\.rect.minX)
        XCTAssertEqual(xs, xs.sorted(), "left to right")
        game.touchSpot(ballista.id)
        XCTAssertEqual(game.touch.count?.offer, .build(plot: plot, item: .ballista), "its board")
        XCTAssertEqual(game.touch.count?.atOnce, true, "paid in one step once he stands there")
    }

    /// No card from a plot: a touch on the engine's plot beside its models walks the lord to the row's spot and does
    /// nothing new; H1: the other boards keep clear of the models, the gate's passage and the other plots.
    func testNoCardFromAPlotAndTheBoardsKeepClear() throws {
        let game = engineGame()
        let plot = Realm.lines[0].engine
        let row = try XCTUnwrap(game.touch.models.first { $0.plot == plot })
        let thing = try XCTUnwrap(game.touch.things.first { $0.id == "touch-plot-\(plot)" })
        game.touchThing(thing)
        XCTAssertNil(game.touch.count, "no board for the plot itself")
        run(game, seconds: 12) { game.touch.errand == nil }
        XCTAssertNil(game.overlay, "no card on arrival")
        XCTAssertNil(game.touch.count)
        XCTAssertEqual(game.driver?.state.king.x ?? 0, row.spot, accuracy: TouchRules.arrival, "at the row's spot")
        let archer = try XCTUnwrap(game.touch.things.first { $0.id == "touch-recruit-archer" })
        let boxes = game.countObstacles(archer)
        XCTAssertTrue(boxes.contains { $0.lowerBound <= row.left && $0.upperBound >= row.right }, "the models")
        for passage in SceneLayout.castlePassages {
            XCTAssertTrue(boxes.contains { $0 == passage }, "the passage \(passage)")
        }
        let brazierA = game.touch.things.first { $0.id == "touch-plot-\(Realm.lines[0].braziers[0])" }
        let brazierB = game.touch.things.first { $0.id == "touch-plot-\(Realm.lines[0].braziers[1])" }
        if let brazierA, let brazierB {
            XCTAssertTrue(game.countObstacles(brazierA).contains {
                $0.lowerBound <= brazierB.x - brazierB.halfWidth && $0.upperBound >= brazierB.x + brazierB.halfWidth
            }, "brazier A's board keeps off brazier B")
        }
    }
}
