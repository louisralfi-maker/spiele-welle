import Foundation
import XCTest
@testable import Lanternhold

/// The great hall as a stage of its own (stage lane, 14.11.2026; DESIGN.md "The hall stage and touch the world",
/// docs/REVIEW-look-2.md 2.6, 2.7, H4, H9, H10): the change of stage through dark in 0.35 s (a cut with Reduce
/// Motion), the walking framing at s 7 and the audience's at s 8 with the eased move, the court in its places on the
/// stage, the world offering the door instead of the throne, the hall's targets, the frame (the hall, its light as the
/// realm's state, the shafts by day, the interior light), the horn, the hall answering its lord, the sound's place.
@MainActor
final class HallStageTests: XCTestCase {
    private var directory: URL!
    private let pro = PixelScale(physicalWidth: 2622, physicalHeight: 1206)

    override func setUp() async throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("lanternhold-hall-\(UUID().uuidString)", isDirectory: true)
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

    private func wait(_ game: GameModel, seconds: Double, step: Double = 1.0 / 60) {
        var left = seconds
        while left > 1e-9 {
            game.advance(by: step)
            left -= step
        }
    }

    private func realm(day: Int = 1, hour: Double = 9) -> GameState {
        var s = GameState.newRealm(seed: 5)
        s.day = day
        s.hour = hour
        PetitionEngine.prepare(&s, catalog: .standard)
        return s
    }

    // MARK: - The change of stage

    func testTheChangeGoesThroughDarkInAThirdOfASecondAndCutsWithReduceMotion() {
        var change = StageChange(to: .hall, phase: .approach)
        XCTAssertEqual(change.step(dt: 1, reduceMotion: false).switchNow, false, "he walks to the door first")
        change.arrived()
        XCTAssertTrue(change.doorOpen)
        var dark: [Double] = []
        var switchedAt: Double?
        var time = 0.0
        var done = false
        while !done && time < 2 {
            let result = change.step(dt: 0.01, reduceMotion: false)
            time += 0.01
            if result.switchNow { switchedAt = time }
            dark.append(change.darkness)
            done = result.done
        }
        XCTAssertTrue(done)
        let darkTime = Double(dark.filter { $0 > 0 }.count) * 0.01
        XCTAssertEqual(darkTime, 0.35, accuracy: 0.03, "through dark in 0.35 s")
        XCTAssertEqual(dark.max() ?? 0, 1, accuracy: 1e-9, "full dark at the switch")
        XCTAssertEqual(switchedAt ?? 0, StageChange.openSeconds + StageChange.darkSeconds, accuracy: 0.02)

        var cut = StageChange(to: .world, phase: .opening)
        var cutDark = 0.0
        var cutResult = (switchNow: false, done: false)
        while !cutResult.done {
            cutResult = cut.step(dt: 0.01, reduceMotion: true)
            cutDark = max(cutDark, cut.darkness)
        }
        XCTAssertTrue(cutResult.switchNow, "Reduce Motion: the stage changes in one step")
        XCTAssertEqual(cutDark, 0, "and never goes dark")
    }

    func testTheLordGoesInByTheDoorAndOutPastIt() throws {
        let game = model(["GWStage": "world", "GWDay": "2", "GWSeed": "1", "GWClock": "10",
                          "GWCameraX": "\(HallLayout.worldDoorX)"])
        XCTAssertEqual(game.stage, .world)
        XCTAssertEqual(game.target, .hallDoor, "at the hall's door the button offers the hall, not the throne")
        game.performAction()
        XCTAssertNotNil(game.stageChange)
        XCTAssertEqual(game.soundPlace(try XCTUnwrap(game.driver?.state)), .hall,
                       "the ear arrives first: the door is open, the hall is heard")
        var darkest = 0.0
        for _ in 0..<60 {
            game.advance(by: 1.0 / 60)
            darkest = max(darkest, game.stageDarkness)
        }
        XCTAssertEqual(game.stage, .hall)
        XCTAssertNil(game.stageChange, "the change is over")
        XCTAssertEqual(darkest, 1, accuracy: 0.05, "through dark")
        XCTAssertEqual(game.hall?.walker.x, HallLayout.doorX, "he stands inside at the door")
        XCTAssertEqual(game.hall?.walker.facing, 1)
        XCTAssertEqual(game.stageDarkness, 0)
        XCTAssertFalse(game.isPaused, "the clock runs in the hall")
        XCTAssertTrue(game.sceneStatus.contains("stage:hall"), game.sceneStatus)
        XCTAssertTrue(game.sceneStatus.contains("hx:68"), game.sceneStatus)
        XCTAssertEqual(game.target, .hallDoor, "the inner door beside him")

        // Out: walking left past hall x 40.
        game.setDrag(offset: -20)
        wait(game, seconds: 1.4)
        game.setDrag(offset: nil)
        XCTAssertEqual(game.stage, .world, "past x 40 he went out")
        let state = try XCTUnwrap(game.driver?.state)
        XCTAssertEqual(state.king.x, HallLayout.worldDoorX, "he stands at the door in the world")
        XCTAssertEqual(state.king.facing, 1, "facing right")
        XCTAssertTrue(game.sceneStatus.contains("stage:world"), game.sceneStatus)

        // Reduce Motion: the same without the dark.
        let still = model(["GWStage": "world", "GWReduceMotion": "YES", "GWCameraX": "\(HallLayout.worldDoorX)"])
        still.performAction()
        var dark = 0.0
        for _ in 0..<30 {
            still.advance(by: 1.0 / 60)
            dark = max(dark, still.stageDarkness)
        }
        XCTAssertEqual(still.stage, .hall)
        XCTAssertEqual(dark, 0, "a cut")
    }

    func testTheRealmStripSendsTheLordOutAndOn() throws {
        let game = model(["GWStage": "hall", "GWHallX": "200"])
        XCTAssertEqual(game.stage, .hall)
        game.travel(toFraction: 1500 / Realm.worldWidth)
        wait(game, seconds: 6, step: 0.05)
        XCTAssertEqual(game.stage, .world, "out through the door")
        wait(game, seconds: 6, step: 0.05)
        let x = try XCTUnwrap(game.driver?.state.king.x)
        XCTAssertEqual(x, 1500, accuracy: 1, "and on to the point of the strip")
    }

    // MARK: - The framing

    func testTheWalkingFramingIsOneStepAboveTheWorldAndTheAudienceTwo() {
        XCTAssertEqual(pro.scale, 6)
        let scales = HallFraming.scales(pro)
        XCTAssertEqual(scales.walk, 7)
        XCTAssertEqual(scales.audience, 8)
        let walkWidth = HallFraming.viewWidth(pro, scale: 7)
        XCTAssertEqual(walkWidth, 374.57, accuracy: 0.01, "375 columns walking")
        XCTAssertEqual(HallLayout.width - walkWidth, 225.4, accuracy: 0.1, "the camera's x runs 0 ... 225")
        let audienceWidth = HallFraming.viewWidth(pro, scale: 8)
        XCTAssertEqual(HallFraming.audienceLeft(width: audienceWidth), 232, accuracy: 1, "left edge at hall x 232")
        let rest = HallFraming.framing(pro, walkLeft: 100, progress: 0)
        XCTAssertEqual(rest.scale, 7)
        XCTAssertEqual(rest.left, 100)
        let half = HallFraming.framing(pro, walkLeft: 100, progress: 0.5)
        XCTAssertEqual(half.scale, 7.5, accuracy: 1e-9, "eased through fractional scales")
        XCTAssertEqual(half.targetScale, 7, "the targets keep the walking size while the move runs")
        let seated = HallFraming.framing(pro, walkLeft: 100, progress: 1)
        XCTAssertEqual(seated.scale, 8)
        XCTAssertEqual(seated.targetScale, 8)
        XCTAssertEqual(seated.left, HallFraming.audienceLeft(width: audienceWidth), accuracy: 1e-9)
        // The audience framing's top: the hall's row 50.
        let target = PixelScale(physicalWidth: 2622, physicalHeight: 1206, override: 8)
        XCTAssertEqual(HallLayout.height - target.targetHeight, 50)
    }

    func testTheAudienceFramingEasesInOverSixTenthsOfASecond() throws {
        let game = model(["GWStage": "hall"])
        _ = game.frame(physicalWidth: 2622, physicalHeight: 1206)
        XCTAssertEqual(game.target, .throne)
        game.performAction()
        XCTAssertEqual(game.overlay, .audience)
        wait(game, seconds: 0.3)
        let mid = try XCTUnwrap(game.hall?.zoom)
        XCTAssertEqual(mid, 0.5, accuracy: 0.05)
        let moving = game.frame(physicalWidth: 2622, physicalHeight: 1206)
        XCTAssertNotNil(moving.zoom, "a fractional scale while it moves")
        XCTAssertEqual(moving.scale, 7)
        wait(game, seconds: 0.4)
        XCTAssertEqual(game.hall?.zoom, 1)
        let framed = game.frame(physicalWidth: 2622, physicalHeight: 1206)
        XCTAssertNil(framed.zoom)
        XCTAssertEqual(framed.scale, 8)
        XCTAssertEqual(framed.cameraX, 232, accuracy: 1)
        game.standUp()
        wait(game, seconds: 0.7)
        XCTAssertEqual(game.hall?.zoom, 0, "and back out")

        let still = model(["GWStage": "hall", "GWReduceMotion": "YES"])
        still.performAction()
        still.advance(by: 1.0 / 60)
        XCTAssertEqual(still.hall?.zoom, 1, "Reduce Motion: a cut")
    }

    func testTheLettersRoomLeavesTheThronePetitionerAndHearthInSight() throws {
        let game = model(["GWStage": "hall"])
        game.performAction()
        wait(game, seconds: 1.6)
        _ = game.frame(physicalWidth: 2622, physicalHeight: 1206)
        XCTAssertNotNil(game.audience)
        let throne = game.hallScreenFraction(HallLayout.throneX - 7)
        let petitioner = game.hallScreenFraction(HallLayout.spotX)
        let hearth = game.hallScreenFraction(HallLayout.hearthX)
        XCTAssertLessThan(game.hallLetterEdge, throne, "the letter ends left of the throne")
        XCTAssertGreaterThan(game.hallLetterEdge, 0.4, "and has the room of the left half")
        XCTAssertGreaterThan(hearth, game.hallLetterEdge)
        XCTAssertGreaterThan(petitioner, 0.2)
        // His head stands below the letter's foot: the letter ends above `figureTop`.
        XCTAssertGreaterThan(game.figureTop, 0.5)
        XCTAssertLessThan(game.figureTop, 0.75)
        XCTAssertEqual(game.stageAnchor, petitioner, accuracy: 0.01, "the card knows where he stands")
    }

    // MARK: - The court on the stage

    func testTheCourtLivesInTheHall() throws {
        let s = realm()
        let specs = HallCourt.specs(s, catalog: .standard)
        let odile = try XCTUnwrap(specs.first { $0.who == "odile" })
        XCTAssertEqual(odile.x, 397)
        XCTAssertEqual(odile.row, HallLayout.daisRow, "on the dais")
        XCTAssertNotNil(specs.first { $0.who == "hesper" }, "Mother Hesper at the hearth")
        let guards = specs.filter { $0.who == "guard" }
        XCTAssertEqual(guards.map(\.x).sorted(), [37, 100, 448], "two at the door, one under the arms by day")
        let farmer = try XCTUnwrap(specs.first { $0.petition == "first_plough" })
        XCTAssertEqual(farmer.x, HallLayout.seats[0], "the first in line nearest the throne")
        XCTAssertEqual(farmer.row, HallLayout.wallRow)
        XCTAssertNotNil(farmer.seated, "seated on the bench")
        XCTAssertEqual(HallCourt.occupiedBenches(specs), [1], "the bench he waits on has its candles lit")

        let night = realm(day: 1, hour: 22)
        let late = HallCourt.specs(night, catalog: .standard)
        XCTAssertNil(late.first { $0.petition != nil }, "at night nobody waits")
        XCTAssertEqual(late.filter { $0.who == "guard" }.count, 2)
        XCTAssertTrue(HallCourt.occupiedBenches(late).isEmpty)

        // The places keep the touch rule's 22 px between things that offer something at the same time.
        XCTAssertGreaterThanOrEqual(abs(HallLayout.throneX - HallLayout.spotX), 22)
        XCTAssertGreaterThanOrEqual(abs(HallLayout.benches[1] - HallLayout.benches[0]), 22)
        XCTAssertGreaterThanOrEqual(abs(odile.x - HallLayout.lecternX), 12)
    }

    func testTheWorldOffersTheDoorAndKeepsTheHallsPeopleInside() {
        var s = realm()
        s.king.x = HallLayout.worldDoorX
        XCTAssertEqual(HallRules.worldTarget(s, balance: .standard), .hallDoor, "the door, not the throne")
        s.king.x = HallLayout.worldDoorX + 21
        XCTAssertEqual(HallRules.worldTarget(s, balance: .standard), .hallDoor)
        s.king.x = KingTargets.lecternX
        XCTAssertNotEqual(HallRules.worldTarget(s, balance: .standard), .lectern, "the lectern is inside")
        s.king.x = KingTargets.barracksX
        XCTAssertEqual(HallRules.worldTarget(s, balance: .standard), .recruit)
        s.hour = 22
        s.king.x = HallLayout.worldDoorX
        XCTAssertEqual(HallRules.worldTarget(s, balance: .standard), .hallDoor, "the door also at night")
        XCTAssertEqual(HallRules.roomsX(HallLayout.worldDoorX), -1_000, "the old cut-away never opens")
        XCTAssertEqual(HallRules.roomsX(2040), 2040)
        let day = realm()
        let world = HallRules.worldFigures(day, catalog: .standard)
        XCTAssertFalse(world.contains { $0.who == "odile" })
        XCTAssertFalse(world.contains { $0.petition != nil }, "the waiting wait in the hall")
        XCTAssertTrue(world.contains { $0.who == "brannock" }, "Brannock keeps the gate")
        XCTAssertTrue(HallRules.startsInHall(kingX: Realm.throneX), "a new realm's lord stands in the hall's slot")
        XCTAssertFalse(HallRules.startsInHall(kingX: 1500))
    }

    func testTheHallsTargets() {
        let s = realm()
        let figures: [DrawnFigure] = []
        XCTAssertEqual(HallTargets.target(s, x: 404, figures: figures, lines: .standard, balance: .standard), .throne)
        XCTAssertEqual(HallTargets.target(s, x: HallLayout.lecternX, figures: figures, lines: .standard,
                                          balance: .standard), .lectern, "the taxes while people wait")
        XCTAssertEqual(HallTargets.target(s, x: HallLayout.doorX, figures: figures, lines: .standard,
                                          balance: .standard), .hallDoor)
        XCTAssertNil(HallTargets.target(s, x: 240, figures: figures, lines: .standard, balance: .standard))
        let night = realm(day: 1, hour: 22)
        XCTAssertNil(HallTargets.target(night, x: 404, figures: figures, lines: .standard, balance: .standard))
        XCTAssertEqual(HallTargets.target(night, x: 60, figures: figures, lines: .standard, balance: .standard),
                       .hallDoor, "out at night too")
    }

    // MARK: - The frame

    func testTheHallsFrameAndItsLight() throws {
        let game = model(["GWStage": "hall", "GWHallX": "300", "GWClock": "9", "GWWeather": "clear",
                          "GWFlickerTime": "2"])
        let day = game.frame(physicalWidth: 2622, physicalHeight: 1206)
        XCTAssertEqual(day.scale, 7, "one step above the world's")
        XCTAssertEqual(day.targetHeight, 173)
        XCTAssertTrue(day.layer(.world).sprites.contains { $0.sprite == .greatHall })
        XCTAssertTrue(day.layer(.far).sprites.contains { $0.sprite == .weltmauer }, "the Weltmauer behind the windows")
        XCTAssertEqual(day.layer(.far).offset.offset, day.cameraX * HallLayout.weltmauerParallax, accuracy: 1e-9)
        XCTAssertTrue(day.layer(.world).sprites.contains { $0.sprite == .hallWash }, "plaster over the brick")
        XCTAssertNotNil(day.interior, "the hall's own light")
        XCTAssertTrue(day.emissives.contains { $0.sprite == .hallShaft }, "the morning's shafts")
        XCTAssertTrue(day.emissives.contains { $0.sprite == .hallMote }, "dust in them")
        XCTAssertTrue(day.lights.contains { $0.kind == .hearth }, "the hearth")
        XCTAssertTrue(day.actors.contains { $0.sprite == .king }, "the lord")
        XCTAssertTrue(day.actors.contains { $0.sprite == .odile } || day.cameraX + 375 < 397)
        XCTAssertLessThanOrEqual(day.counts.lights, 64)
        XCTAssertLessThan(day.counts.instances, 400)

        let noon = model(["GWStage": "hall", "GWClock": "12", "GWWeather": "clear"])
        let midday = noon.frame(physicalWidth: 2622, physicalHeight: 1206)
        XCTAssertFalse(midday.emissives.contains { $0.sprite == .hallShaft }, "no shafts with the sun over the roof")

        let night = model(["GWStage": "hall", "GWNight": "2", "GWSeed": "4", "GWHallX": "120"])
        let dark = night.frame(physicalWidth: 2622, physicalHeight: 1206)
        XCTAssertFalse(dark.emissives.contains { $0.sprite == .hallShaft })
        XCTAssertTrue(dark.lights.contains { $0.kind == .torch }, "the door's torches from the dusk")
        XCTAssertTrue(dark.actors.contains { $0.sprite == .kingGlow }, "his lantern glows")
    }

    func testTheHearthsPoolFollowsTheHearthsStrength() throws {
        let strong = model(["GWStage": "hall", "GWHallX": "500", "GWFlickerTime": "1"])
        let full = strong.frame(physicalWidth: 2622, physicalHeight: 1206)
        let fullPool = try XCTUnwrap(full.lights.filter { $0.kind == .hearth }.map(\.circle.z).max())
        var s = try XCTUnwrap(strong.driver?.state)
        s.hearth = 0.25 * strong.driver!.balance.hearthStrength
        strong.withDriver { $0.state = s }
        let low = strong.frame(physicalWidth: 2622, physicalHeight: 1206)
        let lowPool = try XCTUnwrap(low.lights.filter { $0.kind == .hearth }.map(\.circle.z).max())
        XCTAssertLessThan(lowPool, fullPool - 20, "a weak hearth lays a smaller pool")
        XCTAssertTrue(low.emissives.contains { $0.sprite == .hearthFire }, "below a third the small fire burns")
        XCTAssertFalse(low.emissives.contains { $0.sprite == .hallFire })
    }

    func testTheHornSendsTheWaitingHomeAndHangsASlipAtTheDoor() throws {
        let game = model(["GWStage": "hall", "GWHallX": "90", "GWClock": "18.98"])
        _ = game.frame(physicalWidth: 2622, physicalHeight: 1206)
        XCTAssertEqual(game.petitionersWaiting, 1)
        var guardSteps = 0
        while (game.driver?.state.hour ?? 0) < 19.01 && guardSteps < 600 {
            game.advance(by: 0.1)
            guardSteps += 1
        }
        _ = game.frame(physicalWidth: 2622, physicalHeight: 1206)
        XCTAssertEqual(game.stage, .hall, "the lord stays where he is: the player decides")
        XCTAssertEqual(game.hall?.hornSlip, true)
        XCTAssertNotNil(game.hornSlip, "the slip hangs over the door")
        XCTAssertEqual(game.court.leavers.first?.who, "farmer", "the farmer goes home")
        XCTAssertEqual(game.court.leavers.first?.toX, HallLayout.doorX, "by the door")
        game.leaveHall()
        wait(game, seconds: 2)
        XCTAssertEqual(game.stage, .world)
        XCTAssertNil(game.hornSlip, "outside the slip is gone")
    }

    func testTheHallAnswersItsLord() throws {
        let s = realm()
        let specs = HallCourt.specs(s, catalog: .standard)
        let residents = HallCourt.residents(day: s.day, hour: s.hour, flags: s.flags)
        let scene = HallScene(walker: HallWalker(x: HallLayout.doorX, facing: 1))
        let court = CourtScene(rooms: RoomFades(kingX: -1_000))
        let entering = HallFrames.drawnFigures(specs, scene: scene, court: court, residents: residents,
                                               lordX: HallLayout.doorX, since: 0.5, animTime: 3)
        let guards = entering.filter { $0.who == "guard" && $0.x < 120 }
        XCTAssertEqual(guards.count, 2)
        for guardsman in guards {
            XCTAssertEqual(guardsman.frame, 0, "standing straight: no breath")
            XCTAssertEqual(guardsman.y, Double(HallLayout.floorRow - HallLayout.wallRow) + 1, "a pixel taller")
        }
        let farmer = try XCTUnwrap(entering.first { $0.petition == "first_plough" })
        XCTAssertEqual(farmer.facing, -1, "he turns his head to the lord at the door")

        let later = HallFrames.drawnFigures(specs, scene: scene, court: court, residents: residents,
                                            lordX: HallLayout.doorX, since: 10, animTime: 3)
        XCTAssertEqual(later.first { $0.petition == "first_plough" }?.facing, 1, "then back to the throne")
        XCTAssertEqual(later.first { $0.who == "guard" && $0.x < 120 }?.y,
                       Double(HallLayout.floorRow - HallLayout.wallRow), "the guards stand easy again")

        let passing = HallFrames.drawnFigures(specs, scene: scene, court: court, residents: residents,
                                              lordX: HallLayout.seats[0] - 4, since: 10, animTime: 3)
        let close = try XCTUnwrap(passing.first { $0.petition == "first_plough" })
        XCTAssertEqual(close.facing, -1, "whom he passes looks at him")
        XCTAssertEqual(close.frame, 1, "and bows his head")
        let odile = HallFrames.drawnFigures(specs, scene: scene, court: court, residents: residents,
                                            lordX: 412, since: 10, animTime: 3).first { $0.who == "odile" }
        XCTAssertEqual(odile?.facing, 1, "Odile turns to him beside her")
    }

    // MARK: - Sound and arguments

    func testTheHallIsHeardInsideAndTheDoorCreaks() {
        XCTAssertEqual(SoundPlace.of(stage: .hall, worldX: 100), .hall)
        XCTAssertEqual(SoundPlace.of(stage: .world, worldX: HallLayout.worldDoorX), .castle,
                       "outside the hall's door is the bailey")
        XCTAssertEqual(SoundPlace.of(stage: .world, worldX: 700), .outside)
        XCTAssertEqual(FeedbackCue.doorOpened.sound?.id, .doorCreak)
        XCTAssertEqual(FeedbackCue.doorShut.sound?.id, .doorLatch)
        XCTAssertEqual(FeedbackCue.doorShut.haptic, .soft)
        let game = model(["GWStage": "hall"])
        XCTAssertEqual(game.soundPlace(game.driver!.state), .hall)
    }

    func testTheStageArguments() {
        XCTAssertEqual(DebugArgs(values: ["GWStage": "hall"]).stage, .hall)
        XCTAssertEqual(DebugArgs(values: ["GWStage": "World"]).stage, .world)
        XCTAssertNil(DebugArgs(values: ["GWStage": "attic"]).stage)
        XCTAssertEqual(DebugArgs(values: ["GWHallX": "900"]).hallX, HallLayout.width)
        XCTAssertTrue(DebugArgs.keys.contains("GWStage"))
        XCTAssertTrue(DebugArgs.keys.contains("GWHallX"))
        XCTAssertEqual(model(["GWStage": "hall", "GWHallX": "250"]).hall?.walker.x, 250)
        XCTAssertEqual(model([:]).stage, .hall, "a new realm's first morning")
        XCTAssertEqual(model(["GWCameraX": "1500"]).stage, .world)
    }
}
