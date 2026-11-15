import CoreGraphics
import Foundation
import XCTest
@testable import Lanternhold

/// docs/HUD.md on screen (stage lane, step stage-3-interface): the lantern moment's pieces on the kit's grid, the gold
/// that ticks at the lord, the change notes, the strip that comes for a call, the realm strip's pixels, and the flow
/// through the model (a tap on the lord stills the world, any other touch runs it on, the gear opens the pause sheet,
/// the background raises the lantern, nothing stands on the walked world).
@MainActor
final class LanternMomentTests: XCTestCase {
    private let pro = PixelScale(physicalWidth: 2622, physicalHeight: 1206)
    private let proPoints = CGSize(width: 874, height: 402)
    private var directory: URL!

    override func setUp() async throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("lanternhold-lantern-\(UUID().uuidString)", isDirectory: true)
    }

    override func tearDown() async throws {
        if let directory { try? FileManager.default.removeItem(at: directory) }
    }

    private func model(_ values: [String: String]) -> GameModel {
        var all = values
        all["GWReset"] = "YES"
        if all["GWSkipOnboarding"] == nil { all["GWSkipOnboarding"] = "YES" }
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

    /// The point on the lord's body, in points of the 17 Pro's screen.
    private func lordPoint(_ game: GameModel) throws -> CGPoint {
        let framing = try XCTUnwrap(game.touch.framing)
        let x = game.stageLordX
        return CGPoint(x: framing.deviceX(stageX: x) / 3, y: framing.deviceY(lift: 15) / 3)
    }

    // MARK: - The pieces

    func testTheMomentsRowAndDayLineSitOnTheKitsGrid() {
        let block = HUDKit.moment(gold: 93, happiness: 70, people: 28, day: 12)
        XCTAssertEqual(block.height, 9 + 2 + 9, "the row, 2 px, the day line")
        let coin = block.pieces.first { $0.sprite == .hudCoin }
        let face = block.pieces.first { $0.sprite == .hudFace }
        let people = block.pieces.first { $0.sprite == .hudPeople }
        let dawn = block.pieces.first { $0.sprite == .hudDawn }
        XCTAssertNotNil(coin)
        XCTAssertEqual(face?.frame, 0, "70: the face is glad")
        XCTAssertNotNil(people)
        XCTAssertEqual(dawn?.y, 11, "the day line under the row")
        // coin (9) + 1 + "93" (6 + 7) = 23; + 5 + face 9 = 37; + 5 + people 13 + 1 + "28" 13 = 69.
        XCTAssertEqual(block.width, 69)
        let figures = block.pieces.filter { $0.sprite == .hudFigures && $0.y == 0 }
        XCTAssertEqual(figures.map(\.frame), [9, 3, 2, 8])
        XCTAssertEqual(figures[1].x - figures[0].x, HUDKit.advance, "tabular figures")
        XCTAssertEqual(figures[0].x, (coin?.x ?? 0) + 9 + 1, "the number 1 px after its sign")
        // The day line: dawn (11) + 1 + "12" (13) = 25, centred under the 69 px row.
        XCTAssertEqual(dawn?.x, (69 - 25) / 2)
        XCTAssertTrue(block.pieces.allSatisfy { $0.x >= 0 && $0.x + $0.sprite.size.width <= block.width })
    }

    func testTheFaceTakesTheLedgersBands() {
        XCTAssertEqual(HUDKit.faceFrame(happiness: 95), 0)
        XCTAssertEqual(HUDKit.faceFrame(happiness: 60), 0)
        XCTAssertEqual(HUDKit.faceFrame(happiness: 59), 1)
        XCTAssertEqual(HUDKit.faceFrame(happiness: 30), 1)
        XCTAssertEqual(HUDKit.faceFrame(happiness: 29), 2)
        XCTAssertEqual(HUDKit.faceFrame(happiness: 14), 3)
        XCTAssertEqual(HUDKit.figureFrames(-12), [11, 1, 2])
        XCTAssertEqual(HUDKit.figureFrames(5, plus: true), [10, 5])
        XCTAssertEqual(HUDKit.figuresWidth(3), 19)
    }

    func testThePurseTicksCoinByCoinAndGoes() {
        var purse = PurseTicker(gold: 60)
        XCTAssertFalse(purse.update(gold: 60, now: 0, visible: true), "nothing changed")
        XCTAssertNil(purse.shown)
        purse.update(gold: 48, now: 1, visible: true)
        XCTAssertEqual(purse.shown, 60, "it comes with the old treasury")
        var t = 1.0
        var seen: [Int] = []
        while t < 1.6 {
            t += 1.0 / 60
            purse.update(gold: 48, now: t, visible: true)
            if let shown = purse.shown, seen.last != shown { seen.append(shown) }
        }
        XCTAssertEqual(seen.first, 60)
        XCTAssertEqual(seen.last, 48, "it ticked down to the treasury")
        XCTAssertEqual(seen.count, 13, "one coin a tick")
        purse.update(gold: 48, now: t + 2.1, visible: true)
        XCTAssertNil(purse.shown, "2 s after the last coin it goes")
        // A big sum ticks in about a second.
        purse.update(gold: 948, now: 10, visible: true)
        var now = 10.0
        while purse.shown != 948 && now < 13 {
            now += 1.0 / 60
            purse.update(gold: 948, now: now, visible: true)
        }
        XCTAssertLessThan(now - 10, 1.3, "a big sum ticks quickly")
        // Under a card nothing shows; the change ticks once the world shows.
        var hidden = PurseTicker(gold: 10)
        hidden.update(gold: 30, now: 0, visible: false)
        XCTAssertNil(hidden.shown)
        hidden.update(gold: 30, now: 0.5, visible: true)
        XCTAssertEqual(hidden.shown, 10)
    }

    func testTheChangeNotesComeAndGo() {
        var notes = ChangeNotes(happiness: 60, people: 20)
        notes.update(happiness: 58, people: 21, clock: 1, visible: true)
        XCTAssertEqual(notes.mood, false, "the mood went down")
        XCTAssertEqual(notes.crowd, true, "one more person")
        notes.update(happiness: 58, people: 21, clock: 3.1, visible: true)
        XCTAssertNil(notes.mood)
        XCTAssertNil(notes.crowd)
        let block = LordNotes.block(purse: 48, happiness: 58, mood: true, crowd: nil)
        XCTAssertTrue(block.pieces.contains { $0.sprite == .hudArrow && $0.frame == 0 })
        XCTAssertTrue(block.pieces.contains { $0.sprite == .hudCoin })
        XCTAssertTrue(LordNotes.block(purse: nil, happiness: 50, mood: nil, crowd: nil).pieces.isEmpty)
    }

    func testTheStripComesForACallAndGoes() {
        var s = GameState.newRealm(seed: 2)
        s.hour = 9
        var strip = RealmStrip.make(s, balance: .standard, travelTarget: nil)
        strip.petitioners = 2
        var call = StripCall()
        XCTAssertTrue(call.update(strip, hour: 9, clock: 0, allowed: true), "a call brings it up")
        XCTAssertTrue(call.update(strip, hour: 9.1, clock: 5, allowed: true))
        XCTAssertFalse(call.update(strip, hour: 9.2, clock: 7, allowed: true), "it goes after a few seconds")
        XCTAssertFalse(call.update(strip, hour: 10.2, clock: 30, allowed: true), "not standing while the call waits")
        XCTAssertTrue(call.update(strip, hour: 11.0, clock: 46, allowed: true), "again after a while")
        strip.inHall = true
        XCTAssertEqual(StripCall.size(strip), 0, "in the hall the petitioners do not call")
        strip.inHall = false
        strip.petitioners = 0
        XCTAssertFalse(call.update(strip, hour: 11.1, clock: 47, allowed: true), "answered: it goes at once")

        // Fix round 2 (the critic's high 5): while a hint slip holds it, the call waits, and its 6 s start after.
        var held = StripCall()
        var calling = strip
        calling.petitioners = 1
        XCTAssertFalse(held.update(calling, hour: 9, clock: 0, allowed: true, held: true), "held under the hint")
        XCTAssertFalse(held.update(calling, hour: 9.1, clock: 8, allowed: true, held: true))
        XCTAssertTrue(held.update(calling, hour: 9.2, clock: 10, allowed: true), "the hint gone: the call comes")
        XCTAssertTrue(held.update(calling, hour: 9.3, clock: 15, allowed: true))
        XCTAssertFalse(held.update(calling, hour: 9.4, clock: 16.5, allowed: true), "its 6 s from the slip's end")
    }

    func testTheRealmStripIsAMapOfPixels() {
        var s = GameState.newRealm(seed: 2)
        s.hour = 9
        s.king.x = 1830
        var strip = RealmStrip.make(s, balance: .standard, travelTarget: nil,
                                    window: RealmStrip.window(cameraX: 1600, viewWidth: 437))
        strip.petitioners = 3
        let image = RealmMapPixels.image(strip)
        XCTAssertEqual(image.width, 150)
        XCTAssertEqual(image.height, 25)
        // The lord's lantern: gold glass over his column.
        let x = RealmMapPixels.column(1830)
        XCTAssertEqual(image[x, RealmMapPixels.groundRow - 3], RealmMapPixels.gold)
        // The tag of the waiting above the pane, the pane's brass line.
        XCTAssertTrue((0..<10).contains { y in (0..<150).contains { image[$0, y] == RealmMapPixels.ember } })
        XCTAssertEqual(image[10, RealmMapPixels.tagHeight + 1], RealmMapPixels.brass)
        // Taps: a column back to its share of the world.
        for world in [0.0, 1300, 1830, 3900] {
            let column = Double(RealmMapPixels.column(world))
            XCTAssertEqual(RealmMapPixels.fraction(column: column) * Realm.worldWidth, world, accuracy: 28)
        }
        strip.inHall = true
        let inside = RealmMapPixels.image(strip)
        XCTAssertFalse((0..<10).contains { y in (0..<150).contains { inside[$0, y] == RealmMapPixels.ember } },
                       "no tag while he is in the hall")
    }

    // MARK: - Through the model

    func testATapOnTheLordStillsTheWorldAndAnyTouchRunsItOn() throws {
        let game = model(["GWStage": "world", "GWSeed": "1", "GWClock": "9", "GWCameraX": "2900"])
        _ = game.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
        XCTAssertNil(game.lanternMoment)
        game.refreshHUD()
        XCTAssertTrue(game.sceneStatus.contains("gold:"), game.sceneStatus)
        let hour = try XCTUnwrap(game.driver?.state.hour)
        game.tap(at: try lordPoint(game), in: proPoints)
        let show = try XCTUnwrap(game.lanternMoment, "the tap on the lord raised the lantern")
        XCTAssertTrue(game.isPaused, "the world stands still")
        XCTAssertEqual(show.gold, game.driver?.state.gold)
        XCTAssertGreaterThan(show.block.width, 0)
        XCTAssertLessThan(show.top, Double(pro.physicalHeight) * 0.75, "above the lord")
        run(game, seconds: 1)
        XCTAssertEqual(game.driver?.state.hour, hour, "no time passes")
        game.refreshHUD()
        XCTAssertTrue(game.sceneStatus.contains("hud:moment"), game.sceneStatus)
        game.lowerLanternMoment()
        XCTAssertNil(game.lanternMoment)
        XCTAssertFalse(game.isPaused, "the world runs on")
        run(game, seconds: 0.5)
        XCTAssertGreaterThan(try XCTUnwrap(game.driver?.state.hour), hour)
    }

    func testTheGearOpensThePauseSheetAndTheBackgroundRaisesTheLantern() throws {
        let game = model(["GWStage": "world", "GWSeed": "1", "GWClock": "9", "GWCameraX": "2900"])
        _ = game.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
        game.openLanternMoment()
        XCTAssertNotNil(game.lanternMoment)
        game.openPauseFromLantern()
        XCTAssertNil(game.lanternMoment)
        XCTAssertEqual(game.overlay, .pause, "the gear opens the pause sheet")
        game.resume()
        XCTAssertFalse(game.isPaused)
        game.pauseForBackground()
        XCTAssertNotNil(game.lanternMoment, "the app going to the background raises the lantern")
        XCTAssertNil(game.overlay)
        XCTAssertTrue(game.isPaused)
        // A card lowers it.
        game.setOverlay(.pause)
        XCTAssertNil(game.lanternMoment)
        game.resume()
        XCTAssertFalse(game.isPaused)
    }

    func testTheGoldStandsAboveTheLordWhileItChanges() throws {
        let game = model(["GWStage": "world", "GWSeed": "1", "GWClock": "9", "GWCameraX": "2900", "GWGold": "60"])
        run(game, seconds: 0.2)
        var frame = game.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
        XCTAssertFalse(frame.actors.contains { $0.sprite == .hudCoin }, "nothing over the walking lord")
        game.withDriver { $0.state.gold -= 12 }
        run(game, seconds: 0.2)
        frame = game.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
        let coin = try XCTUnwrap(frame.actors.first { $0.sprite == .hudCoin }, "the coin over the lord")
        XCTAssertTrue(coin.isEmissive, "unlit")
        game.refreshHUD()
        XCTAssertFalse(game.sceneStatus.contains("hud:none"), game.sceneStatus)
        run(game, seconds: 3)
        frame = game.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
        XCTAssertFalse(frame.actors.contains { $0.sprite == .hudCoin }, "gone 2 s after the last coin")
    }

    /// Rounds lh-s3-4 and lh-s3-5: FirstDay's touch on the lord standing on the site he just ordered opened the site's
    /// card. The same path through the model, with what the touch found in the message.
    func testATouchOnTheLordStandingOnHisSiteRaisesTheLantern() throws {
        let game = model(["GWStage": "world", "GWCameraX": "1150"])
        run(game, seconds: 0.3)
        let site = try XCTUnwrap(game.touch.things.first { $0.id == "touch-plot-2" }, "the brazier site offers")
        game.touchThing(site)
        run(game, seconds: 20) { game.overlay != nil }
        XCTAssertEqual(game.overlay, .build(plot: 2), "the card on arrival")
        game.order(.brazier)
        XCTAssertNil(game.overlay)
        run(game, seconds: 1.5)
        game.setTouchViewSize(proPoints)
        game.refreshTouchSpots()
        let lord = try XCTUnwrap(game.touchSpots.first { $0.id == "touch-lord" })
        let point = CGPoint(x: lord.rect.midX * proPoints.width,
                            y: (lord.rect.minY + 0.62 * lord.rect.height) * proPoints.height)
        let place = try XCTUnwrap(game.stagePoint(point, in: proPoints))
        let picked = TouchRules.pick(x: place.x, lift: place.lift, things: game.touch.things, minimum: place.minimum)
        let detail = "lord \(game.stageLordX), place x \(place.x) lift \(place.lift), picked \(picked?.id ?? "none") at "
            + "\(picked?.x ?? -1), body \(game.isOnLordsBody(place)), prefers \(picked.map { game.prefersLord(over: $0, x: place.x) } ?? true)"
        game.tap(at: point, in: proPoints)
        XCTAssertNotNil(game.lanternMoment, "the lantern moment: " + detail)
        XCTAssertNil(game.overlay, "no card: " + detail)
    }

    /// The join (the director's note of 15:55), the rule of 7c397e5 in numbers: on his body the lord wins unless the
    /// finger is more than 3 px nearer the thing's middle. Standing half a game px off a site's middle, a touch on his
    /// middle is his, and so is a touch 4 px toward the site (with the site's middle half a px off him no finger on his
    /// body is 3 px nearer it); a site whose middle lies 8 px off him opens for a finger 6 px toward it.
    func testTheLordWinsOnHisBodyUnlessTheFingerIsClearlyNearerTheThing() throws {
        let game = model(["GWStage": "world", "GWCameraX": "1150"])
        run(game, seconds: 0.3)
        let lord = game.stageLordX
        func site(_ x: Double) -> TouchThing {
            TouchThing(id: "touch-plot-test", kind: .plot, act: .build(plot: 2), x: x, standX: x, halfWidth: 10, top: 14,
                       rank: TouchRules.rank(.plot))
        }
        XCTAssertTrue(game.prefersLord(over: site(lord + 0.5), x: lord), "half a px off the site: his middle is his")
        XCTAssertTrue(game.prefersLord(over: site(lord + 0.5), x: lord + 4), "4 px toward it: still nearer than 3 px")
        XCTAssertFalse(game.prefersLord(over: site(lord + 8), x: lord + 6), "6 px toward a site 8 px off: the site")
        XCTAssertTrue(game.prefersLord(over: site(lord + 8), x: lord + 2), "2 px toward it: still the lord")
    }

    /// The join (the director's note of 17:10): beside a person the lord wins a touch on his own body unless she
    /// stands on his spot (6 px) or he waits there to pay; between them the nearer middle wins, a tie is hers.
    func testTheLordBesideAPersonStillsTheWorld() throws {
        let game = model(["GWStage": "world", "GWCameraX": "1150"])
        run(game, seconds: 0.3)
        let lord = game.stageLordX
        func person(_ x: Double) -> TouchThing {
            TouchThing(id: "touch-talk-test", kind: .talk, act: .talk(who: "tamsin"), x: x, standX: x - 12,
                       halfWidth: 6, top: 30, rank: TouchRules.rank(.talk))
        }
        XCTAssertTrue(game.prefersLord(over: person(lord + 12), x: lord), "12 px off, his middle: his")
        XCTAssertTrue(game.prefersLord(over: person(lord + 12), x: lord + 5), "5 px toward her: his")
        XCTAssertFalse(game.prefersLord(over: person(lord + 12), x: lord + 7), "7 px toward her: hers")
        XCTAssertFalse(game.prefersLord(over: person(lord + 12), x: lord + 6), "a tie: hers")
        XCTAssertFalse(game.prefersLord(over: person(lord + 4), x: lord), "she stands on his spot: hers")
        let waiting = person(lord + 12)
        game.touch.errand = TouchErrand(id: waiting.id, stage: game.stage, act: waiting.act, standX: waiting.standX,
                                        run: false, waiting: true)
        XCTAssertFalse(game.prefersLord(over: waiting, x: lord), "he waits there for the second touch: hers")
        game.touch.errand = nil
    }

    func testTheLordIsAnElementThatRaisesTheLantern() throws {
        let game = model(["GWStage": "world", "GWSeed": "1", "GWClock": "9", "GWCameraX": "2900"])
        _ = game.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
        game.setTouchViewSize(proPoints)
        game.refreshTouchSpots()
        let lord = try XCTUnwrap(game.touchSpots.first { $0.id == "touch-lord" })
        XCTAssertGreaterThanOrEqual(lord.rect.width * proPoints.width, 44 - 0.5)
        XCTAssertGreaterThanOrEqual(lord.rect.height * proPoints.height, 44 - 0.5)
        XCTAssertTrue(lord.label.contains("60") || lord.label.contains("gold"), lord.label)
        let xs = game.touchSpots.map(\.rect.minX)
        XCTAssertEqual(xs, xs.sorted(), "left to right, the lord among the things")
    }
}
