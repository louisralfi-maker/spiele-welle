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
        // The moment's figures ride with the world over the lord (step 4: drawn in the world's frame).
        let frame = game.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
        let show = try XCTUnwrap(game.lanternMoment)
        let slid = try XCTUnwrap(game.touch.framing)
        let coin = try XCTUnwrap(frame.actors.first { $0.sprite == .hudCoin }, "the purse's coin in the frame")
        let coinX = try XCTUnwrap(show.blockX) + Double(show.block.pieces.first { $0.sprite == .hudCoin }?.x ?? 0)
        XCTAssertEqual(Double(coin.rect.x), slid.deviceX(stageX: coinX), accuracy: 0.01,
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
    /// ground's grid. A faint one is not drawn; under 1 its strength is its share, over 1 it brightens. Step 5: the
    /// glint and the flare are opaque marks now (`GameModel.lanternMark`, pinned on the same columns in
    /// `testTheGlintAndTheFlareReadAsLight`); the sparks keep `lanternPixel`, never dimmed by the lantern's light.
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
        XCTAssertEqual(bright.dimRule, .kept, "the lantern's own pixels are never dimmed")
    }

    // MARK: - Lane 5 step 4: the town's banner at the strip's town end (decision 6, form C)

    /// Beside the banner: the people, their count and the mood's trend since the last dawn as the kit's arrow.
    func testTheBannersPeopleCountAndTrend() {
        let report = ReportCard.sampleReport()
        XCTAssertEqual(MoodBanner.trend(happiness: 65, report: report), 1, "over the 64 before the dawn: rising")
        XCTAssertEqual(MoodBanner.trend(happiness: 64, report: report), 0)
        XCTAssertEqual(MoodBanner.trend(happiness: 60, report: report), -1, "falling")
        XCTAssertEqual(MoodBanner.trend(happiness: 60, report: nil), 0, "no dawn yet: no arrow")
        let up = MoodBanner.people(14, trend: 1)
        XCTAssertEqual(up.pieces.first?.sprite, .hudPeople)
        XCTAssertEqual(up.pieces.filter { $0.sprite == .hudFigures }.map(\.frame), [1, 4])
        let arrow = up.pieces.first { $0.sprite == .hudArrow }
        XCTAssertEqual(arrow?.frame, 0, "up")
        // people (13) + 1 + "14" (13) = 27, the arrow 1 px after it: 28 ... 36.
        XCTAssertEqual(arrow?.x, 28)
        XCTAssertEqual(up.width, 36)
        XCTAssertEqual(MoodBanner.people(14, trend: -1).pieces.first { $0.sprite == .hudArrow }?.frame, 1, "down")
        let even = MoodBanner.people(14, trend: 0)
        XCTAssertFalse(even.pieces.contains { $0.sprite == .hudArrow })
        XCTAssertEqual(even.width, 27)
    }

    /// The slip's main reason: the largest gain while the town is glad, the largest loss while it is grim or in
    /// unrest, the largest either way while it is even; the knocks at the doors count as one reason.
    func testTheBannersSlipNamesTheMainReason() {
        let changes = ReportCard.sampleReport().happinessChanges   // the tavern +1, the fallen -3
        XCTAssertEqual(MoodBanner.reason(happiness: 62, changes: changes, knocked: 0), .dawn(.tavern), "glad")
        XCTAssertEqual(MoodBanner.reason(happiness: 20, changes: changes, knocked: 0), .dawn(.fallen), "grim")
        XCTAssertEqual(MoodBanner.reason(happiness: 45, changes: changes, knocked: 0), .dawn(.fallen), "even")
        XCTAssertEqual(MoodBanner.reason(happiness: 62, changes: changes, knocked: -6), .dawn(.tavern),
                       "glad names a gain")
        XCTAssertEqual(MoodBanner.reason(happiness: 10, changes: changes, knocked: -6), .knocked, "unrest")
        XCTAssertEqual(MoodBanner.reason(happiness: 10, changes: [HappinessChange(reason: .tavern, delta: 1)],
                                         knocked: 0), .dawn(.tavern), "no loss to name: the gain")
        XCTAssertEqual(MoodBanner.reason(happiness: 50, changes: [], knocked: 0), .quiet)
        XCTAssertEqual(MoodBanner.reason(happiness: 50, changes: [HappinessChange(reason: .chapel, delta: 0)],
                                         knocked: 0), .quiet, "a change of 0 is none")
        // In a realm: the first morning knows nothing yet; after a dawn its lines.
        var s = GameState.newRealm(seed: 2)
        s.hour = 9
        XCTAssertEqual(MoodBanner.reason(s, balance: .standard), .quiet)
        s.lastReport = ReportCard.sampleReport()
        s.happiness = 20
        XCTAssertEqual(MoodBanner.reason(s, balance: .standard), .dawn(.fallen))
        let strip = RealmStrip.make(s, balance: .standard, travelTarget: nil)
        XCTAssertEqual(strip.happiness, 20)
        XCTAssertEqual(strip.people, s.citizens)
        XCTAssertEqual(strip.moodTrend, -1, "20 under the 64 before the dawn")
        XCTAssertEqual(strip.moodReason, .dawn(.fallen))
        // The words, English, one short line each.
        XCTAssertEqual(MoodBannerView.reasonText(.dawn(.fallen), happiness: 20), "They mourn the fallen.")
        XCTAssertEqual(MoodBannerView.reasonText(.knocked, happiness: 10), "You knocked at their doors.")
        // Step 5 (the step-4 critic's M4, the director's words): with nothing to name the slip names the mood.
        XCTAssertEqual(MoodBannerView.reasonText(.quiet, happiness: 80), "The town is in good heart.")
        XCTAssertEqual(MoodBannerView.reasonText(.quiet, happiness: 45), "The town goes about its days.")
        XCTAssertEqual(MoodBannerView.reasonText(.quiet, happiness: 20), "The town is weary.")
        XCTAssertEqual(MoodBannerView.reasonText(.quiet, happiness: 8), "The town is angry.")
        XCTAssertEqual(MoodBannerView.reasonText(.quiet, happiness: 60), "The town is in good heart.",
                       "the face's bands")
        XCTAssertEqual(MoodBannerView.reasonText(.quiet, happiness: 59), "The town goes about its days.")
        for reason in [MoodBanner.Reason.quiet, .knocked, .dawn(.leftAlone), .dawn(.tavern), .dawn(.chapel),
                       .dawn(.noLosses), .dawn(.fallen), .dawn(.unheard), .dawn(.lowTax), .dawn(.normalTax),
                       .dawn(.highTax), .dawn(.warTax)] {
            for happiness in [80, 45, 20, 8] {
                XCTAssertLessThanOrEqual(MoodBannerView.reasonText(reason, happiness: happiness).count, 36,
                                         "\(reason), happiness \(happiness): one short line")
            }
        }
        XCTAssertEqual(MoodBannerView.voiceValue(strip), "the town is grim, \(s.citizens) people, the mood is falling")
    }

    /// The banner's picture (tools/hudart.py `moodBanner`): 4 frames of 21 x 25 (one per mood), the cloth in the mood's
    /// colour inside an ink edge. Step 5: the hem's marks are gone (the step-4 critic's M2): under the face the coat
    /// line in the hood's colour, then the cloth's own colour; the even cloth's lower third is a step darker,
    /// 200,186,156 (L4); each cord has 1 px of bone on its light side (M1).
    func testTheBannersPictureCarriesTheMoodsColour() throws {
        let frames = MoodBannerArt.frames()
        XCTAssertEqual(frames.count, MoodBanner.frameCount)
        XCTAssertEqual(MoodBanner.frameCount, 4, "one frame per mood")
        XCTAssertEqual(MoodBanner.frame(happiness: 95), 0, "glad")
        XCTAssertEqual(MoodBanner.frame(happiness: 45), 1, "even")
        XCTAssertEqual(MoodBanner.frame(happiness: 20), 2, "grim")
        XCTAssertEqual(MoodBanner.frame(happiness: 8), 3, "unrest")
        XCTAssertEqual(MoodBanner.mood(happiness: 70), HUDKit.faceFrame(happiness: 70), "the face's bands")
        let ink = RGBA(r: 42, g: 34, b: 48)
        let bone = RGBA(r: 222, g: 210, b: 184)
        let evenLow = RGBA(r: 200, g: 186, b: 156)
        let tail = [RGBA(r: 224, g: 174, b: 72), evenLow, RGBA(r: 126, g: 137, b: 182), RGBA(r: 184, g: 72, b: 58)]
        // The hood's colour (palette woodLight, plaster, mistDark, crimson): the coat line under the face.
        let coat = [RGBA(r: 138, g: 99, b: 64), RGBA(r: 200, g: 174, b: 132), RGBA(r: 106, g: 115, b: 147),
                    RGBA(r: 142, g: 43, b: 42)]
        for mood in 0..<4 {
            let full = frames[mood]
            XCTAssertEqual(full.width, 21)
            XCTAssertEqual(full.height, 25)
            XCTAssertEqual(full[4, 21], tail[mood], "mood \(mood): the cloth's colour on its tail")
            XCTAssertEqual(full[2, 21], ink, "mood \(mood): its ink edge")
            XCTAssertEqual(full[2, 4], ink, "the cloth's top edge under the pole")
            XCTAssertTrue((0..<21).contains { full[$0, 24].a > 0 }, "the cloth's foot on the last row")
            XCTAssertEqual(full[10, 24].a, 0, "the swallowtail's notch stays open")
            for x in 4...16 {
                XCTAssertEqual(full[x, 19], coat[mood], "mood \(mood): the coat line under the face at \(x), no mark")
                XCTAssertEqual(full[x, 20], tail[mood], "mood \(mood): the cloth's own colour at \(x), no mark")
            }
            for cord in [6, 14] {
                for y in 0...1 {
                    XCTAssertEqual(full[cord, y], ink, "mood \(mood): the cord at \(cord), \(y)")
                    XCTAssertEqual(full[cord - 1, y], bone, "mood \(mood): its bone on the light side")
                }
            }
        }
        // Composed with the people beside it, each piece in its own ink edge (step 5b: no extra column for a shared one).
        let pixels = try XCTUnwrap(MoodBannerArt.pixels(frame: 2, people: MoodBanner.people(14, trend: 1)))
        XCTAssertEqual(pixels.width, MoodBanner.peopleX + 36)
        XCTAssertEqual(pixels.height, 25)
        // The banner with its people is a 44 pt target at the strip's 2 pt a game px.
        XCTAssertGreaterThanOrEqual(CGFloat(pixels.width) * RealmStripView.unit, 44)
        XCTAssertGreaterThanOrEqual(MoodBannerView.height, 44)
    }

    /// The slip: a touch on the banner opens it, a second shuts it; lowering the lantern shuts it.
    func testTheBannersSlipOpensAndShuts() throws {
        let slip = MoodSlip.shared
        slip.close()
        slip.toggle("They mourn the fallen.")
        XCTAssertEqual(slip.text, "They mourn the fallen.")
        slip.toggle("They mourn the fallen.")
        XCTAssertNil(slip.text, "a second touch shuts it")
        let game = try raised(["GWStage": "world", "GWSeed": "1", "GWClock": "9", "GWCameraX": "1830"])
        slip.open("You left their doors alone.")
        game.lowerLanternMoment()
        XCTAssertNil(slip.text, "lowering the lantern shuts it")
    }

    /// Step 4 (the step 2b critic's H1): while the lantern is up the lord's row is drawn in Metal, in the world's own
    /// frame, so over a pan of 60 frames its first actor keeps one device distance to the hall's door under it; the
    /// moment is not published again for the row's place. Step 5 (the vignette): the row is drawn over the finished
    /// picture (`ActorDim.over`) with no make-up tint (step 4's 1/0.82 under the flat dim is gone).
    func testTheMomentsRowRidesThePanInTheWorldsOwnFrame() throws {
        let game = try raised(["GWStage": "world", "GWSeed": "1", "GWClock": "9", "GWCameraX": "1640"])
        let door = try XCTUnwrap(game.touch.things.first { $0.id == "touch-door-hall" }, "the hall's door offers")
        let doorX = TouchRules.area(door, minimum: 0).left
        let show = try XCTUnwrap(game.lanternMoment)
        XCTAssertEqual(show.block.pieces.first?.sprite, .hudCoin, "the row's first piece is the purse's coin")
        let start = CGPoint(x: 600, y: 250)
        game.touchChanged(start: start, at: start, translation: .zero, in: proPoints)
        var gaps: Set<Double> = []
        var views: Set<Double> = []
        var tint: Float = 0
        var rule = ActorDim.world
        for step in 1...60 {
            drag(game, from: start, dx: -3.7 * Double(step))
            game.advance(by: 1.0 / 60)
            let frame = game.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
            let framing = try XCTUnwrap(game.touch.framing)
            let coin = try XCTUnwrap(frame.actors.first { $0.sprite == .hudCoin }, "frame \(step): the coin")
            gaps.insert(((Double(coin.rect.x) - framing.deviceX(stageX: doorX)) * 1000).rounded() / 1000)
            views.insert(try XCTUnwrap(game.camera?.x))
            tint = coin.tint.x
            rule = coin.dimRule
        }
        XCTAssertGreaterThanOrEqual(views.count, 50, "the view slid in the frames: \(views.count) places")
        XCTAssertEqual(gaps.count, 1, "one device distance to the door in every frame: \(gaps.sorted())")
        XCTAssertEqual(game.lanternMoment, show, "the moment is not published again for the row's place")
        XCTAssertEqual(tint, 1, accuracy: 1e-6, "no make-up tint")
        XCTAssertEqual(rule, .over, "drawn over the finished picture, never dimmed")
        // The walking row is part of the world's picture.
        let walking = HUDKitActors.actors(HUDKit.group(sign: .hudCoin, number: 5), lordX: 1000, groundLift: 0,
                                          framing: try XCTUnwrap(game.touch.framing))
        XCTAssertEqual(walking.first?.tint.x, 1)
        XCTAssertEqual(walking.first?.dimRule, .world)
    }

    /// Step 4 (the step 2b critic's M4): the strip's view bracket is bone with an ink edge wherever the view stands,
    /// on the bank's black at the west end as at home and at the east end; the pane's brass line stays.
    func testTheStripsBracketIsBoneWithAnInkEdgeEverywhere() {
        var s = GameState.newRealm(seed: 2)
        s.hour = 9
        s.king.x = 1830
        let bottomBrass = RealmMapPixels.tagHeight + RealmMapPixels.paneHeight - 2
        for cameraX in [0.0, 1600, 3463] {
            let window = RealmStrip.window(cameraX: cameraX, viewWidth: 437)
            let strip = RealmStrip.make(s, balance: .standard, travelTarget: nil, window: window)
            let image = RealmMapPixels.image(strip)
            let left = RealmMapPixels.column(fraction: window.lowerBound)
            let right = max(left + 3, RealmMapPixels.column(fraction: window.upperBound))
            for y in (RealmMapPixels.tagHeight + 3)...(RealmMapPixels.groundRow + 1) {
                XCTAssertEqual(image[left, y], RealmMapPixels.bone, "camera \(cameraX): the left bracket at row \(y)")
                XCTAssertEqual(image[right, y], RealmMapPixels.bone, "camera \(cameraX): the right bracket")
            }
            XCTAssertEqual(image[left - 1, RealmMapPixels.groundRow - 3], RealmMapPixels.ink, "its ink edge outside")
            XCTAssertEqual(image[right + 1, RealmMapPixels.groundRow - 3], RealmMapPixels.ink)
            XCTAssertEqual(image[left, RealmMapPixels.tagHeight + 2], RealmMapPixels.ink, "and over its head")
            XCTAssertEqual(image[left, bottomBrass], RealmMapPixels.brass, "the pane's brass line stays")
        }
    }

    /// Step 4 (the step 2b critic's M1): the glint and the raise's flare get back a soft halo at the glass, a glow of
    /// the world that feeds the bloom (their pixels are emissive actors since step 2b, which the bloom never sees):
    /// centred on the glass, while the flare burns, never under Reduce Motion, none when too faint. Step 5 (the step-4
    /// critic's M3): it peaks at 0.8 at the glint's peak and at 1.0 at the raise.
    func testTheGlintAndTheFlareHaveTheirHaloBack() throws {
        XCTAssertEqual(GameModel.hintHaloStrength, 0.8, "the glint's halo at its peak")
        XCTAssertEqual(GameModel.raiseHaloStrength, 1.0, "the flare's at the raise")
        let raise = try XCTUnwrap(GameModel.lanternHalo(kingX: 1000.4, facing: 1, row: 22,
                                                        strength: GameModel.raiseHaloStrength))
        XCTAssertEqual(Double(raise.color.x), Double(GamePalette.fireGold.x), accuracy: 1e-5, "whole at the raise")
        let halo = try XCTUnwrap(GameModel.lanternHalo(kingX: 1000.4, facing: 1, row: 22, strength: 0.8))
        XCTAssertEqual(halo.sprite, .siteHalo)
        XCTAssertEqual(halo.x + 12, 1000.4 + EntityFrames.kingGlass.dx, accuracy: 1e-9, "centred on the glass")
        XCTAssertEqual(halo.y + 12, 22, accuracy: 1e-9, "on the glass's row")
        XCTAssertEqual(Double(halo.color.x), Double(GamePalette.fireGold.x) * 0.8, accuracy: 1e-5)
        let left = try XCTUnwrap(GameModel.lanternHalo(kingX: 1000.4, facing: -1, row: 22, strength: 0.8))
        XCTAssertEqual(left.x + 12, 1000.4 - EntityFrames.kingGlass.dx, accuracy: 1e-9, "facing left")
        XCTAssertNil(GameModel.lanternHalo(kingX: 1000, facing: 1, row: 22, strength: 0.005), "too faint")
        for reduce in [false, true] {
            var values = ["GWStage": "world", "GWSeed": "1", "GWClock": "9", "GWCameraX": "1830"]
            if reduce { values["GWReduceMotion"] = "YES" }
            let game = model(values)
            run(game, seconds: 0.3)
            for (since, burns) in [(0.05, true), (0.15, true), (0.30, true), (0.6, false)] {
                game.withDriver { $0.state.king.lanternSince = since }
                let frame = game.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
                let shown = frame.emissives.contains { $0.sprite == .siteHalo }
                XCTAssertEqual(shown, burns && !reduce, "raised \(since) s ago, reduce motion \(reduce)")
            }
        }
    }

    // MARK: - Lane 5 step 5: the lantern's own light (the vignette)

    /// `LanternLight`: no dim at the glass, never less with distance, 0.30 at the most, each pixel of a ring's band one
    /// of its two neighbours (the 2 x 2 dither); over the home frame by day the mean lies between 0.14 and 0.24.
    func testTheLanternsLightFallsInRingsFromTheGlass() throws {
        let glass = LanternDim(x: 1000.5, lift: 24.5, strength: 1)
        XCTAssertEqual(LanternLight.dim(x: 1000, lift: 24, glass: glass), 0, "none at the glass")
        var last = 0.0
        for step in 0...400 {
            let r = Double(step) * 0.5
            let level = LanternLight.level(distance: r)
            XCTAssertGreaterThanOrEqual(level, last, "never less at \(r) px")
            last = level
        }
        XCTAssertEqual(last, 0.30, accuracy: 1e-12, "0.30 beyond the last ring")
        var highest = 0.0
        var strays = 0
        var dithered = Set<Double>()
        for x in 760...1240 {
            for lift in -26...190 {
                let r = LanternLight.distance(x: x, lift: lift, glassX: glass.x, glassLift: glass.lift)
                let dim = LanternLight.dim(x: x, lift: lift, glass: glass)
                highest = max(highest, dim)
                let inner = LanternLight.level(distance: r - LanternLight.band / 2)
                let outer = LanternLight.level(distance: r + LanternLight.band / 2)
                if dim != inner && dim != outer { strays += 1 }
                if inner != outer { dithered.insert(dim) }
                if r < 46 && dim != 0 { strays += 1 }
            }
        }
        XCTAssertEqual(strays, 0, "every pixel is its ring's dim or, in a band, one of its two neighbours")
        XCTAssertEqual(highest, 0.30, accuracy: 1e-12, "0.30 at the most")
        XCTAssertGreaterThanOrEqual(dithered.count, 5, "the bands mix their two rings: \(dithered.sorted())")
        let half = LanternDim(x: 1000.5, lift: 24.5, strength: 0.5)
        XCTAssertEqual(LanternLight.dim(x: 700, lift: 150, glass: half), 0.15, accuracy: 1e-12, "times its strength")
        let color = LanternLight.dimmed(SIMD3<Float>(1, 1, 1), by: 0.30)
        XCTAssertEqual(Double(color.x), 1 - 0.30 * (1 - 42.0 / 255), accuracy: 1e-6, "toward the night ink")
        XCTAssertEqual(Double(color.z), 1 - 0.30 * (1 - 48.0 / 255), accuracy: 1e-6)
        // The home frame by day, the lantern up at the hall's door.
        let game = try raised(["GWStage": "world", "GWSeed": "1", "GWClock": "9", "GWCameraX": "1830"])
        let lit = try XCTUnwrap(game.lanternDimNow, "the lantern's light is up")
        XCTAssertEqual(lit.strength, 1, accuracy: 1e-9)
        let framing = try XCTUnwrap(game.touch.framing)
        let left = Int(framing.viewLeft.rounded(.down))
        let right = Int(framing.viewRight.rounded(.up))
        let rows = Int(framing.physicalHeight / framing.scale)
        var sum = 0.0
        var count = 0.0
        for x in left..<right {
            for lift in -WorldLayout.groundRowsBelow..<(rows - WorldLayout.groundRowsBelow) {
                sum += LanternLight.dim(x: x, lift: lift, glass: lit)
                count += 1
            }
        }
        let mean = sum / max(1, count)
        XCTAssertGreaterThanOrEqual(mean, 0.14, "the home frame's mean dim \(mean)")
        XCTAssertLessThanOrEqual(mean, 0.24, "the home frame's mean dim \(mean)")
    }

    /// The light is anchored in the world: over a pan of 60 frames the glass stands at one place of the stage, every
    /// device px of a world pixel reads that pixel back as the composite reads it (the world plane's whole offset plus
    /// its column), and so each world pixel keeps one ring's dim in every frame.
    func testAWorldPixelKeepsItsDimThroughAPan() throws {
        let game = try raised(["GWStage": "world", "GWSeed": "1", "GWClock": "9", "GWCameraX": "1830"])
        let start = CGPoint(x: 600, y: 250)
        game.touchChanged(start: start, at: start, translation: .zero, in: proPoints)
        let pixels: [(x: Int, lift: Int)] = [(1700, 10), (1830, 40), (1905, 90), (2010, -12), (1600, 150),
                                             (1790, 61), (1880, 3)]
        var seen: [Int: Set<Double>] = [:]
        var glasses: Set<String> = []
        var views: Set<Double> = []
        var misread = 0
        for step in 1...60 {
            drag(game, from: start, dx: -3.7 * Double(step))
            game.advance(by: 1.0 / 60)
            var frame = game.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
            game.lanternLight(&frame)
            let glass = try XCTUnwrap(frame.lanternDim, "frame \(step): the lantern's light")
            let uniform = Renderer.lanternUniform(frame)
            XCTAssertEqual(Double(uniform.x), glass.x, accuracy: 0.001)
            XCTAssertEqual(Double(uniform.y), glass.lift, accuracy: 0.001)
            glasses.insert("\(glass.x) \(glass.lift)")
            let framing = try XCTUnwrap(game.touch.framing)
            views.insert(try XCTUnwrap(game.camera?.x))
            for (index, pixel) in pixels.enumerated() {
                let left = Int(framing.deviceX(stageX: Double(pixel.x)))
                for px in left..<(left + Int(framing.scale)) {
                    let column = Int(framing.whole) + Int(((Double(px) + framing.deviceShift) / framing.scale)
                        .rounded(.down))
                    if column != pixel.x { misread += 1 }
                }
                let ring = LanternLight.dim(x: pixel.x, lift: pixel.lift,
                                            glass: LanternDim(x: glass.x, lift: glass.lift, strength: 1))
                seen[index, default: []].insert(ring)
            }
        }
        XCTAssertGreaterThanOrEqual(views.count, 50, "the view slid in the frames: \(views.count) places")
        XCTAssertEqual(glasses.count, 1, "the glass stands at one place of the world: \(glasses)")
        XCTAssertEqual(misread, 0, "every device px of a world pixel reads that pixel")
        for (index, dims) in seen {
            XCTAssertEqual(dims.count, 1, "world pixel \(pixels[index]): one dim in every frame: \(dims.sorted())")
        }
    }

    /// An offscreen render with the lantern up: a pixel beside the glass stays as it is with the lantern down (within
    /// 2/255), a far corner is 0.30 of the way to the night ink (within 0.03).
    func testTheRenderedFrameDarkensFarFromTheGlassOnly() throws {
        let context = try XCTUnwrap(MetalContext.shared, "No Metal device: see MetalProbeTests")
        let renderer = try Renderer(context: context)
        var settings = RenderSettings()
        settings.time = 1.5
        let game = try raised(["GWStage": "world", "GWSeed": "1", "GWClock": "9", "GWCameraX": "1830"])
        let down = game.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
        var up = down
        game.lanternLight(&up)
        let glass = try XCTUnwrap(up.lanternDim, "the lantern's light is up")
        XCTAssertNil(down.lanternDim, "the model's own frame carries no light; GameView adds it")
        let lit = try renderer.renderOffscreen(up, settings: settings)
        let plain = try renderer.renderOffscreen(down, settings: settings)
        let framing = try XCTUnwrap(game.touch.framing)
        let s = Int(framing.scale)
        for (dx, dy) in [(-4.0, 0.0), (4.0, 2.0), (0.0, -6.0), (-9.0, 8.0)] {
            let x = Int(framing.deviceX(stageX: glass.x + dx)) + s / 2
            let y = Int(framing.deviceY(lift: glass.lift + dy)) - s / 2
            let a = lit.color(x: x, y: y)
            let b = plain.color(x: x, y: y)
            XCTAssertLessThanOrEqual(Double(max(abs(a.x - b.x), max(abs(a.y - b.y), abs(a.z - b.z)))), 2.0 / 255,
                                     "beside the glass (\(dx), \(dy)): as with the lantern down")
        }
        let corners = [(3, pro.physicalHeight - 3), (pro.physicalWidth - 4, pro.physicalHeight - 4)]
        var farthest = 0.0
        for (x, y) in corners {
            let column = Int(framing.whole) + Int(((Double(x) + framing.deviceShift) / framing.scale).rounded(.down))
            let lift = (pro.physicalHeight - 1 - y) / s - WorldLayout.groundRowsBelow
            let dim = LanternLight.dim(x: column, lift: lift, glass: glass)
            farthest = max(farthest, dim)
            let expected = LanternLight.dimmed(plain.color(x: x, y: y), by: dim)
            let got = lit.color(x: x, y: y)
            XCTAssertEqual(Double(got.x), Double(expected.x), accuracy: 0.03, "corner (\(x), \(y)): red")
            XCTAssertEqual(Double(got.y), Double(expected.y), accuracy: 0.03, "corner (\(x), \(y)): green")
            XCTAssertEqual(Double(got.z), Double(expected.z), accuracy: 0.03, "corner (\(x), \(y)): blue")
        }
        XCTAssertEqual(farthest, 0.30, accuracy: 1e-9, "a far corner lies beyond the last ring: darkened by 0.30")
    }

    /// The moment's row is drawn over the finished picture with no make-up tint: its bone lands on 222,210,184
    /// (within 2 per channel) by day at the hall's door, at dusk in the town and at night before the gatehouse, the
    /// same as the banner's count.
    func testTheMomentsRowKeepsItsBoneByDayAtDuskAndAtNight() throws {
        let context = try XCTUnwrap(MetalContext.shared, "No Metal device: see MetalProbeTests")
        let renderer = try Renderer(context: context)
        var settings = RenderSettings()
        settings.time = 1.5
        let scenes: [(name: String, values: [String: String])] = [
            ("day", ["GWStage": "world", "GWSeed": "1", "GWClock": "9", "GWCameraX": "1830"]),
            ("dusk", ["GWStage": "world", "GWDay": "3", "GWSeed": "2", "GWClock": "18.97", "GWCameraX": "2900"]),
            ("night", ["GWStage": "world", "GWNight": "3", "GWSeed": "2", "GWHour": "21.5", "GWCameraX": "1240"]),
        ]
        let layout = AtlasLayout.shared
        let bone = RGBA(r: 222, g: 210, b: 184)
        for scene in scenes {
            let game = try raised(scene.values)
            var frame = game.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
            game.lanternLight(&frame)
            XCTAssertNotNil(frame.lanternDim, "\(scene.name): the lantern's light is up")
            let shot = try renderer.renderOffscreen(frame, settings: settings)
            let row = frame.actors.filter { $0.dimRule == .over && $0.sprite == .hudFigures }
            XCTAssertFalse(row.isEmpty, "\(scene.name): the row's figures are drawn over the picture")
            var measured = 0
            var worst = 0
            for actor in row {
                XCTAssertEqual(actor.tint, SIMD4<Float>(1, 1, 1, 1), "\(scene.name): no make-up tint")
                let cell = layout.cell(actor.sprite, frame: actor.frame)
                let s = Double(actor.rect.z) / Double(cell.width)
                for ty in 0..<cell.height {
                    for tx in 0..<cell.width where layout.image[cell.x + tx, cell.y + ty] == bone {
                        let x = Int(Double(actor.rect.x) + (Double(tx) + 0.5) * s)
                        let y = Int(Double(actor.rect.y) + (Double(ty) + 0.5) * s)
                        guard x >= 0, x < shot.width, y >= 0, y < shot.height else { continue }
                        let c = shot.color(x: x, y: y) * 255
                        let off = max(abs(Int(c.x.rounded()) - 222), max(abs(Int(c.y.rounded()) - 210),
                                                                        abs(Int(c.z.rounded()) - 184)))
                        worst = max(worst, off)
                        measured += 1
                    }
                }
            }
            XCTAssertGreaterThan(measured, 10, "\(scene.name): bone pixels measured")
            XCTAssertLessThanOrEqual(worst, 2, "\(scene.name): the row's bone is 222,210,184 within \(worst)")
        }
    }

    /// `LanternVeil`: the light comes in over 0.15 s in even steps (no ease) as the lantern goes up and leaves in 0.1 s
    /// as it comes down. Polish B1 (rewritten to pin the brief's rule; it was "under Reduce Motion there and gone at
    /// once"): under Reduce Motion the moment comes and goes by opacity at law 1's quick tempo, the same 0.15 s in and
    /// 0.10 s out, linear. Through the model it follows the moment.
    func testTheLanternsLightComesAndGoesAndReduceMotionRampsAtQuick() throws {
        let step = 1.0 / 60
        var veil = LanternVeil()
        veil.step(step, raised: true, reduceMotion: false)
        XCTAssertEqual(veil.dim, step / LanternVeil.upSeconds, accuracy: 1e-9, "even steps, no ease")
        veil.step(step, raised: true, reduceMotion: false)
        XCTAssertEqual(veil.dim, 2 * step / LanternVeil.upSeconds, accuracy: 1e-9)
        for _ in 2..<9 { veil.step(step, raised: true, reduceMotion: false) }
        XCTAssertEqual(veil.dim, 1, "whole in 0.15 s")
        for _ in 0..<5 { veil.step(step, raised: false, reduceMotion: false) }
        XCTAssertGreaterThan(veil.dim, 0, "still going after 5 sixtieths")
        veil.step(step, raised: false, reduceMotion: false)
        XCTAssertEqual(veil.dim, 0, "gone in 0.1 s")
        XCTAssertEqual(LanternVeil.reducedUpSeconds, MotionToken.quick.inSeconds, "Reduce Motion: law 1's quick in")
        XCTAssertEqual(LanternVeil.reducedDownSeconds, MotionToken.quick.outSeconds, "and its quick out")
        var still = LanternVeil()
        still.step(step, raised: true, reduceMotion: true)
        XCTAssertEqual(still.dim, step / LanternVeil.reducedUpSeconds, accuracy: 1e-9, "Reduce Motion: even steps")
        for _ in 1..<9 { still.step(step, raised: true, reduceMotion: true) }
        XCTAssertEqual(still.dim, 1, "whole in 0.15 s")
        for _ in 0..<5 { still.step(step, raised: false, reduceMotion: true) }
        XCTAssertGreaterThan(still.dim, 0, "still going after 5 sixtieths")
        still.step(step, raised: false, reduceMotion: true)
        XCTAssertEqual(still.dim, 0, "gone in 0.10 s")
        let game = try raised(["GWStage": "world", "GWSeed": "1", "GWClock": "9", "GWCameraX": "1830"])
        XCTAssertEqual(game.touch.veil.dim, 1, accuracy: 1e-9, "up with the moment")
        game.lowerLanternMoment()
        run(game, seconds: 0.2)
        XCTAssertEqual(game.touch.veil.dim, 0, "down with it")
        XCTAssertNil(game.lanternDimNow, "no light on the frame once it is gone")
    }

    // MARK: - Lane 5 step 5: the clean frame during the look-around

    /// `LanternVeil.clean` walked by the fixed sim step: below 6 game px of held pan nothing fades; past it the value
    /// reaches 1 in 0.15 s and the dim lifts to 40 % of its strength; on release it is back at 0 within 0.15 s; Reduce
    /// Motion jumps; with VoiceOver running nothing fades; the lantern lowered in mid pan clears it at once.
    func testTheCleanFrameFadesTheMomentsSignsWhileAPanIsHeld() {
        let step = GameModel.step
        var veil = LanternVeil()
        veil.step(1, raised: true, reduceMotion: false)
        XCTAssertEqual(veil.dim, 1)
        for _ in 0..<30 { veil.step(step, raised: true, held: true, pan: 6, reduceMotion: false) }
        XCTAssertEqual(veil.clean, 0, "a pan of 6 px fades nothing")
        for _ in 0..<30 { veil.step(step, raised: true, held: false, pan: 300, reduceMotion: false) }
        XCTAssertEqual(veil.clean, 0, "a view slid by no finger fades nothing")
        veil.step(step, raised: true, held: true, pan: -6.5, reduceMotion: false)
        XCTAssertEqual(veil.clean, step / LanternVeil.cleanSeconds, accuracy: 1e-9, "past 6 px it starts, both ways")
        for _ in 1..<9 { veil.step(step, raised: true, held: true, pan: 40, reduceMotion: false) }
        XCTAssertEqual(veil.clean, 1, "gone in 0.15 s")
        XCTAssertEqual(veil.signs, 0)
        XCTAssertEqual(veil.dim, 0.4, accuracy: 1e-9, "the dim lifts to 40 % of its strength")
        for _ in 0..<9 { veil.step(step, raised: true, held: false, pan: 40, reduceMotion: false) }
        XCTAssertEqual(veil.clean, 0, "back within 0.15 s of the release, before the 0.35 s glide is home")
        XCTAssertEqual(veil.dim, 1, "the dim returns")
        var still = LanternVeil()
        still.step(step, raised: true, held: true, pan: 50, reduceMotion: true)
        XCTAssertEqual(still.clean, 1, "Reduce Motion: no fade, a switch")
        still.step(step, raised: true, held: false, pan: 50, reduceMotion: true)
        XCTAssertEqual(still.clean, 0)
        var heard = LanternVeil()
        for _ in 0..<20 { heard.step(step, raised: true, held: true, pan: 50, reduceMotion: false, voiceOver: true) }
        XCTAssertEqual(heard.clean, 0, "with VoiceOver running nothing fades")
        XCTAssertEqual(heard.dim, 1)
        for _ in 0..<9 { veil.step(step, raised: true, held: true, pan: 40, reduceMotion: false) }
        XCTAssertEqual(veil.clean, 1)
        veil.step(step, raised: false, held: true, pan: 40, reduceMotion: false)
        XCTAssertEqual(veil.clean, 0, "the lantern lowered in mid pan clears it")
    }

    /// Through the model: a held drag past 6 px shuts the banner's slip, fades the lord's row (its alpha) and the
    /// SwiftUI signs (`MomentFade`) and lifts the frame's dim to 40 %; the release brings them back within 0.15 s.
    func testAHeldPanCleansTheFrameAndTheReleaseBringsItBack() throws {
        let game = try raised(["GWStage": "world", "GWSeed": "1", "GWClock": "9", "GWCameraX": "1830"])
        MoodSlip.shared.open("You left their doors alone.")
        let start = CGPoint(x: 600, y: 250)
        game.touchChanged(start: start, at: start, translation: .zero, in: proPoints)
        drag(game, from: start, dx: -20)
        XCTAssertNil(MoodSlip.shared.text, "the slip shuts when the pan starts")
        drag(game, from: start, dx: -120)
        run(game, seconds: 0.3)
        XCTAssertTrue(game.touch.look.isHeld)
        XCTAssertEqual(game.touch.veil.clean, 1, "a held pan cleans the frame")
        XCTAssertEqual(MomentFade.shared.clean, 1, "the banner and the gear read it")
        var frame = game.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
        game.lanternLight(&frame)
        XCTAssertEqual(try XCTUnwrap(frame.lanternDim?.strength), 0.4, accuracy: 1e-9, "the dim lifts to 40 %")
        let faded = try XCTUnwrap(frame.actors.first { $0.sprite == .hudCoin }, "the row's coin")
        XCTAssertEqual(faded.tint.w, 0, accuracy: 1e-6, "the lord's row is gone")
        game.touchEnded(at: CGPoint(x: start.x - 120, y: start.y), translation: CGSize(width: -120, height: 0),
                        in: proPoints)
        XCTAssertNotNil(game.lanternMoment, "the lantern stays up")
        run(game, seconds: 0.16)
        XCTAssertEqual(game.touch.veil.clean, 0, "back within 0.15 s of the release")
        XCTAssertEqual(MomentFade.shared.clean, 0)
        let back = game.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
        XCTAssertEqual(try XCTUnwrap(back.actors.first { $0.sprite == .hudCoin }).tint.w, 1, accuracy: 1e-6)
        XCTAssertNotEqual(try XCTUnwrap(game.camera?.pan), 0, "the glide home is still on its way")
    }

    // MARK: - Lane 5 step 5: the banner critic's fixes

    /// Step 5b (the director's ruling M1 of 22.11.2026, which replaces step 5's C1): the people, the count and the
    /// arrow each stand in the 1 px ink edge their atlas piece already has, as in step 4 and as the lord's row does. In
    /// the composed picture every pixel of the people group's area is exactly what the atlas pieces draw (no pixel
    /// added: no fill between the pieces, no second ring, no plate), and the column between the people and the first
    /// digit is clear in the heads' row, so the world shows there.
    func testThePeopleCountAndArrowEachKeepTheirOwnInkEdge() throws {
        let layout = AtlasLayout.shared
        for (count, trend) in [(17, 1), (7, -1), (128, 0), (14, 1)] {
            let people = MoodBanner.people(count, trend: trend)
            let pixels = try XCTUnwrap(MoodBannerArt.pixels(frame: 0, people: people))
            XCTAssertEqual(pixels.width, MoodBanner.peopleX + people.width, "\(count) \(trend): no extra column")
            // What the atlas pieces alone draw, in the picture's coordinates (a later piece over an earlier one).
            var drawn = PixelImage(width: pixels.width, height: pixels.height)
            for piece in people.pieces {
                let cell = layout.cell(piece.sprite, frame: piece.frame)
                let texels = layout.image.cropped(x: cell.x, y: cell.y, width: cell.width, height: cell.height)
                for y in 0..<texels.height {
                    for x in 0..<texels.width where texels[x, y].a > 0 {
                        drawn[MoodBanner.peopleX + piece.x + x, MoodBanner.peopleY + piece.y + y] = texels[x, y]
                    }
                }
            }
            let top = MoodBanner.peopleY + (people.pieces.map(\.y).min() ?? 0)
            let bottom = MoodBanner.peopleY + (people.pieces.map { $0.y + $0.sprite.size.height }.max() ?? 0)
            var added: [String] = []
            for y in max(0, top - 1)..<min(pixels.height, bottom + 1) {
                // From the column after the banner's 21 (the banner never reaches it) to the picture's end.
                for x in MoodBanner.size.width..<pixels.width where pixels[x, y] != drawn[x, y] {
                    added.append("\(x),\(y)")
                }
            }
            XCTAssertEqual(added, [], "\(count) \(trend): every pixel of the group's area is the atlas pieces' own")
            XCTAssertTrue((0..<SpriteID.hudPeople.size.width).contains { drawn[MoodBanner.peopleX + $0, MoodBanner.peopleY + 4].a > 0 },
                          "the people are drawn")
            // Between the people (13 px) and the first digit (1 px after them), in the heads' row: clear.
            let gap = MoodBanner.peopleX + SpriteID.hudPeople.size.width
            XCTAssertEqual(people.pieces[1].x, SpriteID.hudPeople.size.width + HUDKit.signGap, "the first digit")
            XCTAssertEqual(pixels[gap, MoodBanner.peopleY + 1].a, 0, "\(count) \(trend): the world shows between them")
        }
    }

    /// Step 5b (the director's ruling of 22.11.2026, the red notes sign): the calls' tags are their own layer of the
    /// strip, so they fade with the banner in the clean frame: the strip without them and the tags alone laid over it
    /// give the whole picture pixel for pixel, and without a call there is no tag layer.
    func testTheStripsCallTagsAreTheirOwnLayer() throws {
        var s = GameState.newRealm(seed: 2)
        s.hour = 9
        s.king.x = 1830
        let window = RealmStrip.window(cameraX: 1600, viewWidth: 437)
        var strip = RealmStrip.make(s, balance: .standard, travelTarget: nil, window: window)
        strip.inHall = false
        strip.isNight = false
        strip.strangerAtGate = false
        strip.petitioners = 2
        strip.owingDoors = 3
        XCTAssertEqual(RealmMapPixels.tags(strip).count, 2, "the waiting and the owing doors call")
        let whole = RealmMapPixels.image(strip)
        let bare = RealmMapPixels.image(strip, withTags: false)
        let tags = try XCTUnwrap(RealmMapPixels.tagsImage(strip))
        var laid = bare
        var tagPixels = 0
        for y in 0..<tags.height {
            for x in 0..<tags.width where tags[x, y].a > 0 {
                laid[x, y] = tags[x, y]
                tagPixels += 1
            }
        }
        XCTAssertGreaterThan(tagPixels, 100, "the tags are drawn: \(tagPixels) px")
        XCTAssertEqual(laid, whole, "the strip and its tags laid over it are the whole picture")
        strip.petitioners = 0
        strip.owingDoors = 0
        XCTAssertNil(RealmMapPixels.tagsImage(strip), "nothing calls: no tag layer")
        XCTAssertEqual(RealmMapPixels.image(strip, withTags: false), RealmMapPixels.image(strip))
    }

    /// C6: the banner's depth, which step 4 left unpinned: the cloth 21 px under the pole (its top ink edge on row 4,
    /// its foot on row 24), 25 px with the cords and the pole (the cords from row 0); the people inside it.
    func testTheBannersDepthIsTwentyOneUnderThePoleAndTwentyFiveWithCordsAndPole() throws {
        XCTAssertEqual(MoodBanner.clothDepth, 21)
        XCTAssertEqual(MoodBanner.depth, 25)
        XCTAssertEqual(MoodBanner.size.height, MoodBanner.depth)
        XCTAssertEqual(MoodBannerView.height, CGFloat(MoodBanner.depth) * RealmStripView.unit, "50 pt under the strip")
        let ink = RGBA(r: 42, g: 34, b: 48)
        for (mood, frame) in MoodBannerArt.frames().enumerated() {
            let rows = (0..<frame.height).filter { y in (0..<frame.width).contains { frame[$0, y].a > 0 } }
            XCTAssertEqual(rows.first, 0, "mood \(mood): the cords start on the top row")
            XCTAssertEqual(rows.last, MoodBanner.depth - 1, "mood \(mood): 25 px with the cords and the pole")
            // Rows 1 to 3 of the cloth's first column are the pole's knob (its top ink edge, then two rows of wood),
            // so the cloth's own top edge is the first ink below the knob's wood.
            let clothTop = 4
            XCTAssertEqual(frame[MoodBanner.clothLeft, clothTop], ink, "mood \(mood): the cloth's top ink edge under the pole")
            XCTAssertNotEqual(frame[MoodBanner.clothLeft, clothTop - 1], ink, "mood \(mood): the pole's wood above the cloth's edge")
            XCTAssertEqual(MoodBanner.depth - clothTop, MoodBanner.clothDepth, "mood \(mood): 21 px of cloth")
        }
        let pixels = try XCTUnwrap(MoodBannerArt.pixels(frame: 1, people: MoodBanner.people(128, trend: -1)))
        XCTAssertEqual(pixels.height, MoodBanner.depth, "the people never make it deeper")
    }

    /// C3 (the step-4 critic's M3): the glint is a cross of 7 px at its peak (centre 255,250,235, arms 240,220,170);
    /// the flare a white centre, a ring of fire gold 255,200,96 and four rays of 4 px, shortening as it burns down;
    /// both opaque over the finished picture on the lord's own columns, and none under Reduce Motion. The halos: 0.8 at
    /// the glint's peak, 1.0 falling to 0 over the flare's 0.45 s, at least 6 game px round.
    func testTheGlintAndTheFlareReadAsLight() throws {
        let peak = LanternSparkle.glint(pulse: 1)
        XCTAssertEqual(peak.count, 13, "a centre and four arms of 3 px")
        XCTAssertEqual(peak.map(\.dx).min(), -3)
        XCTAssertEqual(peak.map(\.dx).max(), 3, "7 px across")
        XCTAssertEqual(peak.map(\.dy).max(), 3, "7 px high")
        XCTAssertEqual(peak.first { $0.dx == 0 && $0.dy == 0 }?.color, SIMD3<Float>(255, 250, 235) / 255)
        let arm = SIMD3<Float>(240, 220, 170) / 255
        XCTAssertTrue(peak.filter { $0.dx != 0 || $0.dy != 0 }.allSatisfy { $0.color == arm }, "the arms' colour")
        XCTAssertTrue(LanternSparkle.glint(pulse: 0.1).isEmpty, "nothing at the pulse's foot")
        XCTAssertEqual(LanternSparkle.glint(pulse: 0.5).count, 5, "it grows a pixel at a time")
        let flare = LanternSparkle.flare(strength: 1)
        let gold = SIMD3<Float>(255, 200, 96) / 255
        XCTAssertEqual(flare.first { $0.dx == 0 && $0.dy == 0 }?.color, SIMD3<Float>(1, 1, 1), "a white centre")
        XCTAssertEqual(flare.filter { abs($0.dx) <= 1 && abs($0.dy) <= 1 && ($0.dx != 0 || $0.dy != 0) }.count, 8,
                       "a ring round it")
        let rays = flare.filter { abs($0.dx) >= 2 }
        XCTAssertEqual(rays.count, 16, "four rays of 4 px")
        XCTAssertTrue(rays.allSatisfy { abs($0.dx) == abs($0.dy) && abs($0.dx) <= 5 && $0.color == gold })
        XCTAssertEqual(LanternSparkle.flare(strength: 0.3).filter { abs($0.dx) >= 2 }.count, 8, "shorter as it fades")
        XCTAssertTrue(LanternSparkle.flare(strength: 0.01).isEmpty)
        XCTAssertEqual(GameModel.hintHaloStrength, 0.8)
        XCTAssertEqual(GameModel.raiseHaloStrength, 1.0)
        let layout = AtlasLayout.shared
        let halo = layout.cell(.siteHalo, frame: 0)
        XCTAssertGreaterThan(layout.image[halo.x + halo.width / 2 + 6, halo.y + halo.height / 2].a, 0,
                             "the halo reaches 6 game px from the glass")
        // On the lord's own columns over a walk, opaque, in its own colour, over the finished picture.
        for facing in [1, -1] {
            var gaps: Set<Double> = []
            for step in 0..<120 {
                let lordX = 1000.3 + 0.6 * Double(step * facing)
                let camera = Camera(focusX: lordX, pixelScale: pro)
                let framing = TouchFraming.world(camera: camera, pixelScale: pro)
                let mark = GameModel.lanternMark(kingX: lordX, facing: facing, dx: -2, row: 24, color: gold,
                                                 framing: framing)
                gaps.insert(Double(mark.rect.x) - Double(camera.deviceX(worldX: lordX, scale: pro.scale,
                                                                        mode: .smooth)))
                XCTAssertEqual(mark.tint, SIMD4<Float>(gold.x, gold.y, gold.z, 1))
                XCTAssertEqual(mark.dimRule, .over)
            }
            XCTAssertEqual(gaps.count, 1, "facing \(facing): one distance in every frame: \(gaps.sorted())")
            let glass = (EntityFrames.kingGlass.dx * Double(facing)).rounded(.down)
            XCTAssertEqual(gaps.first ?? 0, (glass - 2) * Double(pro.scale), accuracy: 0.001, "on its column")
        }
        // Through the model: the flare's pixels while it burns, none under Reduce Motion.
        for reduce in [false, true] {
            var values = ["GWStage": "world", "GWSeed": "1", "GWClock": "9", "GWCameraX": "1830"]
            if reduce { values["GWReduceMotion"] = "YES" }
            let game = model(values)
            run(game, seconds: 0.3)
            game.withDriver { $0.state.king.lanternSince = 0.05 }
            let frame = game.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
            let marks = frame.actors.filter { $0.sprite == .hallMote && $0.dimRule == .over }
            if reduce {
                XCTAssertTrue(marks.isEmpty, "Reduce Motion: no flare")
            } else {
                XCTAssertGreaterThanOrEqual(marks.count, 20, "the flare burns: \(marks.count) pixels")
                XCTAssertTrue(marks.contains { $0.tint == SIMD4<Float>(1, 1, 1, 1) }, "its white centre")
            }
        }
    }

    // MARK: - Polish B1: one lantern instrument

    /// An empty patch of ground under the lantern: 12 game px below the walk line (the UI helpers' lowering spot,
    /// `TouchSupport.emptyWorld`), where no thing, door, board, model or the lord answers.
    private func emptyGround(_ game: GameModel) throws -> CGPoint {
        let lord = game.stageLordX
        for dx in [60.0, -60, 90, -90, 120, -120] {
            let p = try screenPoint(game, x: lord + dx, lift: -12)
            if game.thingAt(p, in: proPoints) == nil, game.townDoor(at: p, in: proPoints) == nil,
               let place = game.stagePoint(p, in: proPoints), game.modelAt(place) == nil, !game.isOnLord(place) {
                return p
            }
        }
        return try XCTUnwrap(nil as CGPoint?, "empty ground in view")
    }

    /// One driver (M3 = H6, law 1): at every frame of the raise and of the lowering the dim's strength, the SwiftUI
    /// layer's opacity (`MomentFade.light`) and the Metal block's alpha all come from `LanternVeil.light`: the dim and
    /// the SwiftUI layer are the light itself, the block is the light in three steps; the lord's pose is the lift frame
    /// 8 for the first 0.05 s and 9 after it, and on the way down 9, then 8 for the last 0.05 s, then his own frame.
    /// After the lowering the block is drawn on until the light is gone.
    func testOneDriverTakesEveryLayerOfTheMomentUpAndDown() throws {
        let game = model(["GWStage": "world", "GWSeed": "1", "GWClock": "9", "GWCameraX": "1830"])
        run(game, seconds: 0.3)
        let state = try XCTUnwrap(game.driver?.state)
        let body = state.lordOrDefault.body
        game.openLanternMoment()
        var poses: [Int] = []
        func check(_ name: String, raised: Bool) throws {
            let frame = game.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
            let light = game.touch.veil.light
            XCTAssertEqual(MomentFade.shared.light, light, accuracy: 1e-12, "\(name): the SwiftUI layer reads the light")
            if light > 0.001 {
                XCTAssertEqual(try XCTUnwrap(game.lanternDimNow).strength, light, accuracy: 1e-12,
                               "\(name): the dim reads the light")
            } else {
                XCTAssertNil(game.lanternDimNow, "\(name): no dim without light")
            }
            // The B1 gate (M1): the nearest third, never more than a sixth from the light.
            let stepped = light > 1e-9 ? (light * 3).rounded() / 3 : 0
            XCTAssertLessThanOrEqual(abs(stepped - light), 1.0 / 6 + 1e-9, "\(name): the block keeps with the light")
            let coins = frame.actors.filter { $0.sprite == .hudCoin }
            if stepped > 0 {
                let coin = try XCTUnwrap(coins.first, "\(name): the block is drawn while the light shows")
                XCTAssertEqual(Double(coin.tint.w), stepped, accuracy: 1e-6, "\(name): the block's alpha in thirds")
                XCTAssertTrue(coins.allSatisfy { abs(Double($0.tint.w) - stepped) < 1e-6 }, "\(name): one alpha")
            } else if light > 1e-9 {
                XCTAssertTrue(coins.allSatisfy { $0.tint.w == 0 }, "\(name): under a sixth of light the block is clear")
            } else {
                XCTAssertTrue(coins.isEmpty, "\(name): no block once the light is gone")
            }
            let lord = try XCTUnwrap(frame.actors.first { $0.sprite == body }, "\(name): the lord is drawn")
            let expected: Int?
            if raised {
                expected = light * LanternVeil.upSeconds < LanternVeil.poseHoldSeconds - 1e-9 ? 8 : 9
            } else {
                expected = light <= 1e-9 ? nil : (light * LanternVeil.downSeconds > LanternVeil.poseHoldSeconds + 1e-9
                                                    ? 9 : 8)
            }
            if let expected {
                XCTAssertEqual(lord.frame, expected, "\(name): the pose at light \(light)")
                poses.append(expected)
            } else {
                XCTAssertNotEqual(lord.frame, 9, "\(name): his own frame once the light is gone")
                XCTAssertNotEqual(lord.frame, 8, "\(name): his own frame once the light is gone")
            }
        }
        for index in 0..<12 {
            game.advance(by: 1.0 / 60)
            try check("up \(index)", raised: true)
        }
        XCTAssertEqual(game.touch.veil.light, 1, "whole in 0.15 s")
        XCTAssertEqual(poses.prefix(3), [8, 8, 9], "the lift frame for 0.05 s, then the raised frame")
        poses = []
        game.lowerLanternMoment()
        XCTAssertNil(game.lanternMoment)
        XCTAssertNotNil(game.momentShown, "the last block stays while the light leaves")
        for index in 0..<8 {
            game.advance(by: 1.0 / 60)
            try check("down \(index)", raised: false)
        }
        XCTAssertEqual(poses, [9, 9, 8, 8, 8], "9, then the lift frame for the last 0.05 s")
        XCTAssertNil(game.momentShown, "gone with the light")
    }

    /// Reduce Motion (law 1): the moment still comes and goes by opacity at the quick tempo (the light ramps), and the
    /// pose swaps without the held frame: 9 from the first frame, his own frame from the lowering.
    func testUnderReduceMotionTheMomentFadesAtQuickAndThePoseHasNoHeldFrame() throws {
        let game = model(["GWStage": "world", "GWSeed": "1", "GWClock": "9", "GWCameraX": "1830",
                          "GWReduceMotion": "YES"])
        run(game, seconds: 0.3)
        let body = try XCTUnwrap(game.driver?.state.lordOrDefault.body)
        game.openLanternMoment()
        game.advance(by: 1.0 / 60)
        var frame = game.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
        XCTAssertEqual(game.touch.veil.light, (1.0 / 60) / MotionToken.quick.inSeconds, accuracy: 1e-9,
                       "an opacity ramp at quick, not a cut")
        XCTAssertEqual(frame.actors.first { $0.sprite == body }?.frame, 9, "the raised frame at once")
        run(game, seconds: 0.3)
        game.lowerLanternMoment()
        game.advance(by: 1.0 / 60)
        frame = game.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
        XCTAssertGreaterThan(game.touch.veil.light, 0, "the light leaves at quick")
        XCTAssertNotNil(frame.actors.first { $0.sprite == .hudCoin }, "the block fades with it")
        let pose = frame.actors.first { $0.sprite == body }?.frame
        XCTAssertNotEqual(pose, 9, "his own frame at once")
        XCTAssertNotEqual(pose, 8, "no held frame")
    }

    /// F7 (law 4 step 1): the raise plays `lanternUp` once and never the ground tap with it; every way down plays
    /// `lanternDown` once: a tap on the empty world, a tap on a thing (its deed's own cue follows), the gear, the
    /// lowering after the app came back from the background, a drag in the hall.
    func testTheLanternSoundsUpAndDownOncePerWay() throws {
        let game = model(["GWStage": "world", "GWSeed": "1", "GWClock": "9", "GWCameraX": "1640"])
        let hub = SilentFeedback()
        game.feedback = hub
        run(game, seconds: 0.3)
        func count(_ cue: FeedbackCue, from: Int) -> Int { hub.played.dropFirst(from).filter { $0 == cue }.count }
        // The raise by a tap on the lord.
        var mark = hub.played.count
        tapThrough(game, try lordPoint(game))
        XCTAssertNotNil(game.lanternMoment, "the tap on the lord raised the lantern")
        XCTAssertEqual(count(.lanternUp, from: mark), 1, "lanternUp once")
        XCTAssertEqual(count(.touched, from: mark), 0, "and no ground tap with it")
        XCTAssertEqual(count(.lanternDown, from: mark), 0)
        // Down by a tap on the empty world.
        run(game, seconds: 0.3)
        mark = hub.played.count
        tapThrough(game, try emptyGround(game))
        XCTAssertNil(game.lanternMoment)
        XCTAssertEqual(count(.lanternDown, from: mark), 1, "the empty world: lanternDown once")
        XCTAssertEqual(count(.lanternUp, from: mark), 0)
        // Down by a tap on a thing: lanternDown once, then the deed's own cue.
        run(game, seconds: 0.3)
        game.openLanternMoment()
        run(game, seconds: 0.3)
        let door = try XCTUnwrap(game.touch.things.first { $0.id == "touch-door-hall" }, "the hall's door offers")
        mark = hub.played.count
        tapThrough(game, try thingPoint(game, door))
        XCTAssertEqual(game.touch.errand?.id, door.id, "the deed began")
        XCTAssertEqual(count(.lanternDown, from: mark), 1, "a thing: lanternDown once")
        XCTAssertEqual(Array(hub.played.dropFirst(mark).prefix(2)), [.lanternDown, .touched],
                       "the lowering first, then the deed's own cue")
        // He stays out of the hall for the rest of the test.
        game.cancelErrand()
        game.stopWalking()
        // Down by the gear.
        run(game, seconds: 0.3)
        game.openLanternMoment()
        mark = hub.played.count
        game.openPauseFromLantern()
        XCTAssertEqual(count(.lanternDown, from: mark), 1, "the gear: lanternDown once")
        game.resume()
        // Raised by the background, lowered after the return.
        run(game, seconds: 0.3)
        mark = hub.played.count
        game.pauseForBackground()
        XCTAssertNotNil(game.lanternMoment)
        XCTAssertEqual(count(.lanternUp, from: mark), 1, "the background's raise: lanternUp once")
        XCTAssertEqual(count(.touched, from: mark), 0)
        run(game, seconds: 0.3)
        mark = hub.played.count
        tapThrough(game, try emptyGround(game))
        XCTAssertEqual(count(.lanternDown, from: mark), 1, "after the return: lanternDown once")
        // A drag in the hall lowers it and walks: lanternDown once.
        let hall = model(["GWDay": "3", "GWSeed": "2", "GWClock": "11", "GWStage": "hall", "GWHallX": "200"])
        let hallHub = SilentFeedback()
        hall.feedback = hallHub
        run(hall, seconds: 0.3)
        hall.openLanternMoment()
        XCTAssertNotNil(hall.lanternMoment, "the lantern up in the hall")
        let start = CGPoint(x: 400, y: 250)
        let before = hallHub.played.count
        hall.touchChanged(start: start, at: start, translation: .zero, in: proPoints)
        drag(hall, from: start, dx: -40)
        XCTAssertNil(hall.lanternMoment, "the hall's drag lowered it")
        hall.touchEnded(at: CGPoint(x: 360, y: 250), translation: CGSize(width: -40, height: 0), in: proPoints)
        XCTAssertEqual(hallHub.played.dropFirst(before).filter { $0 == .lanternDown }.count, 1,
                       "the hall's drag: lanternDown once")
    }

    /// H8 and the refuter's missed point 1: the errand survives the moment. Raised on the way (by a tap on the lord or
    /// by the background), the world stands and the errand stays; a tap on the empty world lowers it, he walks on and
    /// does his deed (the hall's door: in he goes). A tap on another thing under the lantern replaces it.
    func testTheErrandSurvivesTheLanternMoment() throws {
        for background in [false, true] {
            let name = background ? "background" : "tap"
            let game = model(["GWStage": "world", "GWSeed": "1", "GWClock": "9", "GWCameraX": "1640"])
            run(game, seconds: 0.3)
            let door = try XCTUnwrap(game.touch.things.first { $0.id == "touch-door-hall" }, "the hall's door offers")
            game.touchThing(door)
            XCTAssertEqual(game.touch.errand?.id, door.id, "\(name): the errand began")
            XCTAssertNotNil(game.driver?.travelTarget, "\(name): he walks")
            run(game, seconds: 0.25)
            let x = try XCTUnwrap(game.driver?.state.king.x)
            if background {
                game.pauseForBackground()
            } else {
                game.openLanternMoment()
            }
            XCTAssertNotNil(game.lanternMoment, "\(name): the lantern is up")
            XCTAssertEqual(game.touch.errand?.id, door.id, "\(name): the raise keeps the errand")
            run(game, seconds: 1)
            XCTAssertEqual(try XCTUnwrap(game.driver?.state.king.x), x, accuracy: 0.01, "\(name): the world stands")
            XCTAssertEqual(game.touch.errand?.id, door.id, "\(name): it waits under the lantern")
            tapThrough(game, try emptyGround(game))
            XCTAssertNil(game.lanternMoment, "\(name): lowered")
            XCTAssertEqual(game.touch.lastTap, "lowered", "\(name): the empty world only lowers")
            XCTAssertEqual(game.touch.errand?.id, door.id, "\(name): the kept errand goes on")
            run(game, seconds: 20) { game.stageChange != nil || game.stage == .hall }
            XCTAssertTrue(game.stageChange != nil || game.stage == .hall,
                          "\(name): he arrived and did his deed (the hall's door)")
        }
        // A tap on another thing under the lantern replaces the kept errand.
        let game = model(["GWStage": "world", "GWSeed": "1", "GWClock": "9", "GWCameraX": "1640"])
        run(game, seconds: 0.3)
        let door = try XCTUnwrap(game.touch.things.first { $0.id == "touch-door-hall" })
        game.touchThing(door)
        run(game, seconds: 0.25)
        game.openLanternMoment()
        run(game, seconds: 0.3)
        var other: (TouchThing, CGPoint)?
        for thing in game.touch.things where thing.id != door.id {
            let p = try thingPoint(game, thing)
            guard p.x > 20, p.x < proPoints.width - 20, game.thingAt(p, in: proPoints)?.id == thing.id,
                  let place = game.stagePoint(p, in: proPoints), !game.isOnLordsBody(place), !game.isOnLord(place)
            else { continue }
            other = (thing, p)
            break
        }
        let (thing, p) = try XCTUnwrap(other, "another thing in view")
        tapThrough(game, p)
        XCTAssertNil(game.lanternMoment, "lowered")
        XCTAssertNotEqual(game.touch.errand?.id, door.id, "the kept errand is replaced")
        XCTAssertTrue(game.touch.errand?.id == thing.id || game.touch.count?.thing == thing.id
                      || game.touch.lastTap == thing.id,
                      "by the new thing's deed (\(thing.id)): errand \(game.touch.errand?.id ?? "none")")
    }

    /// PAY.md 4: a count is still cut at the raise, and the walk to its board goes with it: he stands, and after the
    /// lowering nothing comes back and nothing is paid. A kept errand whose aim is gone when the lantern comes down
    /// ends quietly: he stops, nothing opens.
    func testTheRaiseStillCutsACountAndAVanishedAimEndsQuietly() throws {
        let game = model(["GWStage": "world", "GWSeed": "2", "GWDay": "3", "GWClock": "10", "GWCameraX": "1240",
                          "GWGold": "200"])
        _ = game.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
        let gate = try XCTUnwrap(game.touch.things.first { $0.id == "touch-plot-0" }, "the gate offers")
        game.touchThing(gate)
        XCTAssertEqual(game.touch.count?.thing, gate.id, "the board came")
        run(game, seconds: 0.2)
        if game.touch.errand?.id == gate.id {
            game.openLanternMoment()
            XCTAssertNil(game.touch.errand, "the walk to the cut board goes with it")
            XCTAssertNil(game.driver?.travelTarget, "he stands")
        } else {
            game.openLanternMoment()
        }
        XCTAssertEqual(game.touch.countLast, "cutOff:\(gate.id)", "the raise cuts the count (PAY.md 4)")
        XCTAssertNotEqual(game.touch.count?.isOpen, true)
        run(game, seconds: 0.5)
        tapThrough(game, try emptyGround(game))
        run(game, seconds: 3)
        XCTAssertNotEqual(game.touch.count?.isOpen, true, "no board comes back")
        XCTAssertEqual(game.driver?.state.gold, 200, "nothing paid")
        // A vanished aim: the kept errand's thing is no longer offered when the lantern comes down.
        let other = model(["GWStage": "world", "GWSeed": "1", "GWClock": "9", "GWCameraX": "1640"])
        run(other, seconds: 0.3)
        let door = try XCTUnwrap(other.touch.things.first { $0.id == "touch-door-hall" })
        other.touchThing(door)
        run(other, seconds: 0.25)
        other.openLanternMoment()
        // The aim goes (simulated: the errand now names a thing the world no longer lists).
        other.touch.errand?.id = "touch-plot-gone"
        run(other, seconds: 0.3)
        XCTAssertEqual(other.touch.errand?.id, "touch-plot-gone", "under the lantern the errand waits")
        let x = try XCTUnwrap(other.driver?.state.king.x)
        tapThrough(other, try emptyGround(other))
        XCTAssertNil(other.touch.errand, "its aim gone, the errand ends")
        XCTAssertNil(other.driver?.travelTarget, "he stops")
        run(other, seconds: 1)
        XCTAssertEqual(try XCTUnwrap(other.driver?.state.king.x), x, accuracy: 1, "he stands where he was")
        XCTAssertNil(other.stageChange, "nothing opens")
        XCTAssertNil(other.overlay)
    }

    /// The refuter's missed point 2 (the step-5 ruling, H1's cause): the marks stay visible under the lantern, never
    /// dimmed, so the player sees which tap does a deed; VoiceOver reaches the marked things as without it.
    func testTheMarksStayUnderTheLantern() throws {
        let game = model(["GWStage": "world", "GWSeed": "1", "GWClock": "9", "GWCameraX": "1640"])
        run(game, seconds: 0.3)
        let markSprites: Set<SpriteID> = [.tapTalk, .tapThrone, .tapDoor, .tapRecruit, .tapLight, .tapBuild, .tapRepair]
        var frame = game.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
        let before = frame.actors.filter { markSprites.contains($0.sprite) }
        XCTAssertFalse(before.isEmpty, "marks on the walked world")
        game.openLanternMoment()
        run(game, seconds: 0.3)
        frame = game.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
        let under = frame.actors.filter { markSprites.contains($0.sprite) }
        XCTAssertEqual(Set(under.map(\.sprite)), Set(before.map(\.sprite)), "the same marks under the lantern")
        XCTAssertTrue(under.allSatisfy { $0.dimRule == .kept }, "never dimmed by its light")
        game.setTouchViewSize(proPoints)
        game.refreshTouchSpots()
        XCTAssertTrue(game.touchSpots.contains { $0.id == "touch-door-hall" }, "VoiceOver reaches the door")
    }
}
