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

    /// Build 3, lane 5 step 4 (decision 6): the row over the lord is the purse alone, the coin and its figures; the
    /// face and the people stand at the strip's town end. The day line stays centred under it.
    func testTheMomentsRowAndDayLineSitOnTheKitsGrid() {
        let block = HUDKit.moment(gold: 93, day: 12)
        XCTAssertEqual(block.height, 9 + 2 + 9, "the row, 2 px, the day line")
        let coin = block.pieces.first { $0.sprite == .hudCoin }
        let dawn = block.pieces.first { $0.sprite == .hudDawn }
        XCTAssertNotNil(coin)
        XCTAssertFalse(block.pieces.contains { $0.sprite == .hudFace }, "no face in the lord's row")
        XCTAssertFalse(block.pieces.contains { $0.sprite == .hudPeople }, "no people in the lord's row")
        XCTAssertEqual(dawn?.y, 11, "the day line under the row")
        // The row: coin (9) + 1 + "93" (6 + 7) = 23; the day line: dawn (11) + 1 + "12" (13) = 25, the wider.
        XCTAssertEqual(block.width, 25)
        let figures = block.pieces.filter { $0.sprite == .hudFigures && $0.y == 0 }
        XCTAssertEqual(figures.map(\.frame), [9, 3])
        XCTAssertEqual(figures[1].x - figures[0].x, HUDKit.advance, "tabular figures")
        XCTAssertEqual(figures[0].x, (coin?.x ?? 0) + 9 + 1, "the number 1 px after its sign")
        XCTAssertEqual(coin?.x, (25 - 23) / 2, "the purse centred over the day line")
        XCTAssertEqual(dawn?.x, 0)
        // A purse wider than the day line: the line is centred under it.
        let rich = HUDKit.moment(gold: 1234, day: 3)
        // coin (9) + 1 + "1234" (3 x 6 + 7) = 35; dawn (11) + 1 + "3" (7) = 19.
        XCTAssertEqual(rich.width, 35)
        XCTAssertEqual(rich.pieces.first { $0.sprite == .hudCoin }?.x, 0)
        XCTAssertEqual(rich.pieces.first { $0.sprite == .hudDawn }?.x, (35 - 19) / 2)
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
        // Build 3, the count's step 4: the site brings its tally board (no card from a plot); he pays it there.
        game.touchThing(site)
        XCTAssertEqual(game.touch.count?.thing, site.id, "the site's board")
        run(game, seconds: 20) { game.touch.count?.ready == true }
        var count = try XCTUnwrap(game.touch.count)
        count.payAtOnce()
        game.touch.count = count
        run(game, seconds: 3) { game.touch.countLast.hasPrefix("paid") }
        XCTAssertEqual(game.touch.countLast, "paid:\(site.id)", "paid")
        XCTAssertNil(game.overlay, "no card")
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

    // MARK: - Build 3, lane 5: the lantern moment answers the hand (no dead tap, the look-around)

    /// A point of the 17 Pro's screen (points) at a stage x and a lift over the walk line.
    private func screenPoint(_ game: GameModel, x: Double, lift: Double) throws -> CGPoint {
        let framing = try XCTUnwrap(game.touch.framing)
        return CGPoint(x: framing.deviceX(stageX: x) / 3, y: framing.deviceY(lift: lift) / 3)
    }

    /// The middle of a thing's touch area on screen.
    private func thingPoint(_ game: GameModel, _ thing: TouchThing) throws -> CGPoint {
        let area = TouchRules.area(thing, minimum: 0)
        return try screenPoint(game, x: (area.left + area.right) / 2, lift: (area.top + area.bottom) / 2)
    }

    /// One finger through the touch layer's path: down at `point`, up at `point` (a tap).
    private func tapThrough(_ game: GameModel, _ point: CGPoint) {
        game.touchChanged(start: point, at: point, translation: .zero, in: proPoints)
        game.touchEnded(at: point, translation: .zero, in: proPoints)
    }

    /// The finger that went down at `start` is `dx` pt to the side of it.
    private func drag(_ game: GameModel, from start: CGPoint, dx: Double) {
        game.touchChanged(start: start, at: CGPoint(x: start.x + dx, y: start.y),
                          translation: CGSize(width: dx, height: 0), in: proPoints)
    }

    /// Game px of the world per point of the finger on the 17 Pro.
    private func pixelsPerPoint(_ game: GameModel) throws -> Double {
        let framing = try XCTUnwrap(game.touch.framing)
        return framing.physicalWidth / Double(proPoints.width) / framing.scale
    }

    /// A raised lantern over a world whose camera has settled on the lord.
    private func raised(_ values: [String: String]) throws -> GameModel {
        let game = model(values)
        run(game, seconds: 0.2)
        game.openLanternMoment()
        XCTAssertNotNil(game.lanternMoment, "the lantern is up")
        run(game, seconds: 1.5)
        return game
    }

    /// No dead tap: with the lantern up, a tap on a thing lowers it and starts the thing's errand in the same touch.
    func testATapOnAThingWhileTheLanternIsUpLowersItAndStartsItsErrand() throws {
        let game = try raised(["GWStage": "world", "GWSeed": "1", "GWClock": "9", "GWCameraX": "1640"])
        let door = try XCTUnwrap(game.touch.things.first { $0.id == "touch-door-hall" }, "the hall's door offers")
        let p = try thingPoint(game, door)
        XCTAssertEqual(game.thingAt(p, in: proPoints)?.id, door.id, "the finger is on the door")
        tapThrough(game, p)
        XCTAssertNil(game.lanternMoment, "the same touch lowered the lantern")
        XCTAssertFalse(game.isPaused, "the world runs on")
        XCTAssertEqual(game.touch.lastTap, door.id)
        XCTAssertEqual(game.touch.errand?.id, door.id, "and started the door's errand")
        XCTAssertNotNil(game.driver?.travelTarget, "he walks there")
    }

    /// With the lantern up, a tap on the empty world, or on the lord himself, only lowers it.
    func testATapOnNothingWhileTheLanternIsUpOnlyLowersIt() throws {
        let game = try raised(["GWStage": "world", "GWSeed": "1", "GWClock": "9", "GWCameraX": "2900"])
        let lord = game.stageLordX
        var empty: CGPoint?
        for dx in [60.0, -60, 90, -90, 120, -120, 150, -150, 180, -180] {
            let p = try screenPoint(game, x: lord + dx, lift: -3)
            if game.thingAt(p, in: proPoints) == nil, game.townDoor(at: p, in: proPoints) == nil,
               let place = game.stagePoint(p, in: proPoints), game.modelAt(place) == nil {
                empty = p
                break
            }
        }
        let p = try XCTUnwrap(empty, "an empty patch of ground in view")
        let x = try XCTUnwrap(game.driver?.state.king.x)
        tapThrough(game, p)
        XCTAssertNil(game.lanternMoment, "lowered")
        XCTAssertEqual(game.touch.lastTap, "lowered", "and nothing else")
        XCTAssertNil(game.touch.errand)
        XCTAssertNil(game.driver?.travelTarget, "he does not walk")
        run(game, seconds: 0.5)
        XCTAssertEqual(try XCTUnwrap(game.driver?.state.king.x), x, accuracy: 0.01, "he stands")
        // A tap on the lord under the lantern lowers it and never raises it again in the same touch.
        game.openLanternMoment()
        run(game, seconds: 0.2)
        tapThrough(game, try lordPoint(game))
        XCTAssertNil(game.lanternMoment, "a tap on the lord lowered it")
        XCTAssertEqual(game.touch.lastTap, "lowered")
    }

    /// The look-around: with the lantern up a sideways drag slides the still realm one to one with the finger, the
    /// view stops at both ends of the world and turns back with the finger at once, and the strip's bracket moves.
    func testTheLookAroundSlidesTheRealmOneToOneAndClampsAtBothEnds() throws {
        let game = try raised(["GWStage": "world", "GWSeed": "1", "GWClock": "9", "GWCameraX": "1830"])
        let home = try XCTUnwrap(game.camera?.x)
        let perPoint = try pixelsPerPoint(game)
        let hour = try XCTUnwrap(game.driver?.state.hour)
        let start = CGPoint(x: 600, y: 250)
        game.touchChanged(start: start, at: start, translation: .zero, in: proPoints)
        drag(game, from: start, dx: -20)
        XCTAssertTrue(game.touch.panning, "past 10 pt the touch is a look-around")
        drag(game, from: start, dx: -120)
        game.advance(by: 1.0 / 60)
        XCTAssertEqual(try XCTUnwrap(game.camera?.x), home + 100 * perPoint, accuracy: 0.05,
                       "the finger 100 pt left: the realm slid 100 pt left with it")
        XCTAssertNotNil(game.lanternMoment, "the lantern stays up during the pan")
        XCTAssertTrue(game.isPaused, "the world stays still")
        XCTAssertNil(game.driver?.travelTarget, "a drag under the lantern is no walk")
        XCTAssertEqual(try XCTUnwrap(game.driver?.state.king.velocity), 0, "he stands")
        // Far past the east end, then 10 pt back.
        drag(game, from: start, dx: -20_000)
        game.advance(by: 1.0 / 60)
        let east = try XCTUnwrap(game.camera)
        XCTAssertEqual(east.x, east.maxLeft, accuracy: 0.01, "the view stops at the east end")
        drag(game, from: start, dx: -19_990)
        game.advance(by: 1.0 / 60)
        XCTAssertEqual(try XCTUnwrap(game.camera?.x), east.maxLeft - 10 * perPoint, accuracy: 0.01,
                       "back with the finger at once")
        drag(game, from: start, dx: 20_000)
        game.advance(by: 1.0 / 60)
        XCTAssertEqual(try XCTUnwrap(game.camera?.x), 0, accuracy: 0.01, "the view stops at the west end")
        game.refreshHUD()
        XCTAssertEqual(try XCTUnwrap(game.strip?.window?.lowerBound), 0, accuracy: 0.001,
                       "the strip's view bracket moved along")
        XCTAssertEqual(game.driver?.state.hour, hour, "no time passed")
        // The moment's figures ride with the world over the lord.
        _ = game.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
        let show = try XCTUnwrap(game.lanternMoment)
        let slid = try XCTUnwrap(game.touch.framing)
        XCTAssertEqual(show.left, slid.deviceX(stageX: try XCTUnwrap(show.blockX)), accuracy: 0.5,
                       "the block stands over the lord in the slid view")
    }

    /// Letting go glides the view home to the lord (an ease-out of about 0.35 s); the lantern stays up. Under Reduce
    /// Motion the view is home at once.
    func testLettingGoGlidesHomeAndReduceMotionJumps() throws {
        for reduce in [false, true] {
            var values = ["GWStage": "world", "GWSeed": "1", "GWClock": "9", "GWCameraX": "1830"]
            if reduce { values["GWReduceMotion"] = "YES" }
            let game = try raised(values)
            let home = try XCTUnwrap(game.camera?.x)
            let perPoint = try pixelsPerPoint(game)
            let start = CGPoint(x: 600, y: 250)
            game.touchChanged(start: start, at: start, translation: .zero, in: proPoints)
            drag(game, from: start, dx: -20)
            drag(game, from: start, dx: -220)
            game.advance(by: 1.0 / 60)
            let slid = 200 * perPoint
            XCTAssertEqual(try XCTUnwrap(game.camera?.x), home + slid, accuracy: 0.05)
            game.touchEnded(at: CGPoint(x: start.x - 220, y: start.y), translation: CGSize(width: -220, height: 0),
                            in: proPoints)
            XCTAssertFalse(game.touch.panning)
            XCTAssertNotNil(game.lanternMoment, "the lantern stays up after the pan")
            game.advance(by: 1.0 / 60)
            if reduce {
                XCTAssertEqual(try XCTUnwrap(game.camera?.x), home, accuracy: 0.01, "Reduce Motion: home at once")
            } else {
                let first = try XCTUnwrap(game.camera?.x) - home
                XCTAssertGreaterThan(first, slid * 0.5, "it glides, it does not jump")
                XCTAssertLessThan(first, slid, "it set off at once")
                game.advance(by: 0.1)
                let mid = try XCTUnwrap(game.camera?.x) - home
                XCTAssertGreaterThan(mid, 0)
                XCTAssertLessThan(mid, slid * 0.5, "an ease-out: past half way within a third of the glide")
                game.advance(by: 0.25)
                XCTAssertEqual(try XCTUnwrap(game.camera?.x), home, accuracy: 0.01, "home after about 0.35 s")
            }
            XCTAssertNotNil(game.lanternMoment, "the lantern is still up")
            XCTAssertTrue(game.isPaused, "the world still stands")
            XCTAssertEqual(try XCTUnwrap(game.camera?.pan), 0)
        }
    }

    /// A view still slid when a tap lowers the lantern glides home while the world runs on.
    func testLoweringTheLanternWhileSlidGlidesHome() throws {
        let game = try raised(["GWStage": "world", "GWSeed": "1", "GWClock": "9", "GWCameraX": "1830"])
        let start = CGPoint(x: 600, y: 250)
        game.touchChanged(start: start, at: start, translation: .zero, in: proPoints)
        drag(game, from: start, dx: -20)
        drag(game, from: start, dx: -220)
        game.advance(by: 1.0 / 60)
        game.lowerLanternMoment()
        XCTAssertNil(game.lanternMoment)
        run(game, seconds: 0.6)
        XCTAssertEqual(try XCTUnwrap(game.camera?.pan), 0, "home with the world running")
        XCTAssertFalse(game.touch.look.isHeld)
    }

    /// A swipe under the lantern that never goes 10 pt sideways is no look-around: on lift it lowers the lantern, so
    /// the touch is never swallowed. A sideways pan that comes back near its start keeps the lantern up.
    func testAnUprightSwipeUnderTheLanternLowersIt() throws {
        let game = try raised(["GWStage": "world", "GWSeed": "1", "GWClock": "9", "GWCameraX": "1830"])
        let start = CGPoint(x: 600, y: 250)
        game.touchChanged(start: start, at: start, translation: .zero, in: proPoints)
        game.touchChanged(start: start, at: CGPoint(x: 603, y: 150), translation: CGSize(width: 3, height: -100),
                          in: proPoints)
        game.touchEnded(at: CGPoint(x: 603, y: 150), translation: CGSize(width: 3, height: -100), in: proPoints)
        XCTAssertNil(game.lanternMoment, "an upright swipe lowered the lantern")
        XCTAssertEqual(game.touch.lastTap, "lowered")
        XCTAssertNil(game.touch.errand)
        // A sideways pan that ends near where it began still keeps the lantern up.
        game.openLanternMoment()
        run(game, seconds: 0.2)
        game.touchChanged(start: start, at: start, translation: .zero, in: proPoints)
        drag(game, from: start, dx: -60)
        drag(game, from: start, dx: -2)
        game.touchEnded(at: CGPoint(x: start.x - 2, y: start.y), translation: CGSize(width: -2, height: 0),
                        in: proPoints)
        XCTAssertNotNil(game.lanternMoment, "a look-around keeps the lantern up")
    }

    /// VoiceOver's double tap on a thing under the lantern lowers it and does the deed, as the finger's tap does.
    func testAVoiceOverDeedUnderTheLanternLowersIt() throws {
        let game = try raised(["GWStage": "world", "GWSeed": "1", "GWClock": "9", "GWCameraX": "1640"])
        let door = try XCTUnwrap(game.touch.things.first { $0.id == "touch-door-hall" }, "the hall's door offers")
        game.touchSpot(door.id)
        XCTAssertNil(game.lanternMoment, "the deed lowered the lantern")
        XCTAssertFalse(game.isPaused, "the world runs on")
        XCTAssertEqual(game.touch.errand?.id, door.id, "and started the door's errand")
    }

    /// A lift after the scene went inactive is never a tap: not with the lantern down, not with it up; nor is a lift
    /// while the scene is not active. A new touch afterwards is a tap again.
    func testALiftAfterTheSceneWentInactiveIsNoTap() throws {
        let game = model(["GWStage": "world", "GWSeed": "1", "GWClock": "9", "GWCameraX": "1640"])
        run(game, seconds: 0.2)
        let door = try XCTUnwrap(game.touch.things.first { $0.id == "touch-door-hall" })
        let p = try thingPoint(game, door)
        XCTAssertEqual(game.thingAt(p, in: proPoints)?.id, door.id)
        // The lantern down: the finger on the door, the scene goes inactive, the same touch moves and lifts later.
        game.touchChanged(start: p, at: p, translation: .zero, in: proPoints)
        game.voidTouch()
        game.touchChanged(start: p, at: p, translation: .zero, in: proPoints)
        XCTAssertNil(game.touch.down, "the forgotten touch stays forgotten")
        game.touchEnded(at: p, translation: .zero, in: proPoints)
        XCTAssertNil(game.touch.errand, "no errand from the stale lift")
        XCTAssertNil(game.driver?.travelTarget)
        XCTAssertEqual(game.touch.lastTap, "none")
        // A lift while the scene is not active.
        game.touchChanged(start: p, at: p, translation: .zero, in: proPoints)
        game.touchEnded(at: p, translation: .zero, in: proPoints, active: false)
        XCTAssertNil(game.touch.errand, "no errand from a lift while inactive")
        XCTAssertNil(game.touch.down)
        // The lantern up: the stale lift neither lowers it nor does the deed.
        game.openLanternMoment()
        XCTAssertNotNil(game.lanternMoment)
        game.touchChanged(start: p, at: p, translation: .zero, in: proPoints)
        game.voidTouch()
        game.touchEnded(at: p, translation: .zero, in: proPoints)
        XCTAssertNotNil(game.lanternMoment, "the lantern stays up")
        XCTAssertNil(game.touch.errand)
        // A new touch is a tap again: it lowers the lantern and sends him to the door.
        tapThrough(game, p)
        XCTAssertNil(game.lanternMoment)
        XCTAssertEqual(game.touch.errand?.id, door.id, "a fresh touch counts")
    }

    // MARK: - Lane 5 step 2a: the smooth walk

    /// Suspect 1: the coin and notes row above the walking lord keeps one distance in device px to him (a smooth
    /// actor, `Camera.deviceX`) in every frame of a walk; floored to whole game px it buzzed 3 to 5 device px.
    func testTheRowAboveTheWalkingLordKeepsItsDistanceToHim() throws {
        let block = HUDKit.moment(gold: 93, day: 12)
        var gaps: Set<Double> = []
        for step in 0..<120 {
            let lordX = 1000.3 + 0.6 * Double(step)
            let camera = Camera(focusX: lordX, pixelScale: pro)
            let framing = TouchFraming.world(camera: camera, pixelScale: pro)
            let actors = HUDKitActors.actors(block, lordX: lordX, groundLift: 0, framing: framing)
            let first = try XCTUnwrap(actors.first)
            let anchor = camera.deviceX(worldX: lordX, scale: pro.scale, mode: .smooth)
            gaps.insert(Double(first.rect.x) - Double(anchor))
        }
        XCTAssertEqual(gaps.count, 1, "one distance to the lord in every frame: \(gaps.sorted())")
    }

    /// Suspect 2: the raise flame over the lantern's glass at night keeps one distance in device px to the walking
    /// lord, whichever way he faces, on one of his own sprite columns (where the floored flame stood on average).
    func testTheRaiseFlameKeepsItsDistanceToTheWalkingLord() {
        for facing in [1, -1] {
            var gaps: Set<Double> = []
            for step in 0..<120 {
                let lordX = 1000.3 + 0.6 * Double(step * facing)
                let camera = Camera(focusX: lordX, pixelScale: pro)
                let framing = TouchFraming.world(camera: camera, pixelScale: pro)
                let left = GameModel.raiseFlameLeft(kingX: lordX, facing: facing, framing: framing)
                let anchor = camera.deviceX(worldX: lordX, scale: pro.scale, mode: .smooth)
                gaps.insert(left - Double(anchor))
            }
            XCTAssertEqual(gaps.count, 1, "facing \(facing): one distance in every frame: \(gaps.sorted())")
            let column = (EntityFrames.kingGlass.dx * Double(facing)).rounded(.down) * Double(pro.scale)
            XCTAssertEqual(gaps.first ?? 0, column, accuracy: 0.001, "facing \(facing): on the glass's column")
        }
    }

    /// Lane 5 step 2b (what step 2a left): the hint's glint and the raise's flare and sparks are emissive actors on the
    /// lord's own columns (`GameModel.lanternPixel`): over a 120-step walk with the camera following, each keeps one
    /// device distance to his anchor, the glass's column plus its own whole game px. As world glows they stood on the
    /// ground's grid. A faint one is not drawn; under 1 its strength is its share, over 1 it brightens.
    func testTheLanternsPixelsKeepTheirDistanceToTheWalkingLord() throws {
        for facing in [1, -1] {
            for dx in [-2.0, -1.3, 0, 1, 2.6] {
                var gaps: Set<Double> = []
                for step in 0..<120 {
                    let lordX = 1000.3 + 0.6 * Double(step * facing)
                    let camera = Camera(focusX: lordX, pixelScale: pro)
                    let framing = TouchFraming.world(camera: camera, pixelScale: pro)
                    let pixel = try XCTUnwrap(GameModel.lanternPixel(kingX: lordX, facing: facing, dx: dx, row: 30,
                                                                     rgb: SIMD3<Float>(1, 0.9, 0.6),
                                                                     framing: framing))
                    let anchor = camera.deviceX(worldX: lordX, scale: pro.scale, mode: .smooth)
                    gaps.insert(Double(pixel.rect.x) - Double(anchor))
                }
                XCTAssertEqual(gaps.count, 1, "facing \(facing), dx \(dx): one distance in every frame: \(gaps.sorted())")
                let glass = (EntityFrames.kingGlass.dx * Double(facing)).rounded(.down)
                XCTAssertEqual(gaps.first ?? 0, (glass + dx.rounded(.down)) * Double(pro.scale), accuracy: 0.001,
                               "facing \(facing), dx \(dx): on its column")
            }
        }
        let framing = TouchFraming.world(camera: Camera(focusX: 1000, pixelScale: pro), pixelScale: pro)
        func pixel(_ rgb: SIMD3<Float>) -> ActorInstance? {
            GameModel.lanternPixel(kingX: 1000, facing: 1, dx: 0, row: 30, rgb: rgb, framing: framing)
        }
        XCTAssertNil(pixel(SIMD3<Float>(0.001, 0.001, 0.001)), "too faint to draw")
        let dim = try XCTUnwrap(pixel(SIMD3<Float>(0.5, 0.45, 0.3)))
        XCTAssertEqual(dim.tint.w, 0.5, accuracy: 1e-6, "its strength is its share")
        XCTAssertTrue(dim.isEmissive)
        let bright = try XCTUnwrap(pixel(SIMD3<Float>(1.4, 1.26, 0.84)))
        XCTAssertEqual(bright.tint.w, 1, accuracy: 1e-6)
        XCTAssertEqual(bright.tint.x, 1.4, accuracy: 1e-5, "over 1 it brightens")
        XCTAssertEqual(Double(bright.rect.w), Double(pro.scale), "one game px")
        XCTAssertEqual(Double(bright.rect.y), framing.deviceY(lift: 31), "its row over the walk line")
    }
}
