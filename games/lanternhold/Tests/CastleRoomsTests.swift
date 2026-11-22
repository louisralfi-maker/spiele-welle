import Foundation
import XCTest
@testable import Lanternhold

/// The castle's exteriors and the court drawn at them. M3 step 3 cut the rooms away; world-2 (REVIEW-look-2.md B1)
/// draws the castle closed: no fade, no front, no interior; the hall door opens for the lord, the gate passage's arch
/// frames him, the chapel's bell and the keep's dark window follow the realm; the court walks its rounds as actors with
/// talk frames and speech marks, petitioners wait on the benches, Marek's cart on his days, the castle's world
/// changes; the frame stays inside its budget.
final class CastleRoomsTests: XCTestCase {
    private let balance = Balance.standard

    /// A game frame with the court, as `GameModel` builds it.
    static func frame(_ s: GameState, focus: Double, court: CourtScene, time: Double = 1.5,
                      screen: (Int, Int) = GameFrameSupport.pro) -> (desc: FrameDesc, layer: EntityLayer) {
        let options = FrameOptions(flickerTime: time)
        let pixelScale = options.pixelScale(physicalWidth: screen.0, physicalHeight: screen.1)
        let camera = Camera(focusX: focus, pixelScale: pixelScale)
        let scene = CastleRooms.scene(SceneFilter.gameScene(GameFrameSupport.world, state: s), state: s,
                                      rooms: court.rooms)
        var layer = EntityFrames.layer(state: s, balance: .standard, scene: scene, camera: camera,
                                       pixelScale: pixelScale, options: options, animTime: time)
        CourtFrames.apply(&layer, state: s, catalog: .standard, scene: court,
                          view: EntityFrames.ActorView(camera: camera, pixelScale: pixelScale, mode: options.actorMode),
                          ambient: AmbientRamp.sample(at: s.hour), animTime: time, reduceMotion: false)
        var clock = DayClock(hour: s.hour, day: s.day)
        clock.isFrozen = true
        clock.advance(by: time)
        let desc = FrameBuilder.build(scene: scene, clock: clock, camera: camera, pixelScale: pixelScale,
                                      options: options, entities: layer)
        return (desc, layer)
    }

    /// A realm on `day` at `hour` with the king at `x`, today's queue drawn by the driver.
    private func realm(day: Int = 2, hour: Double = 10, kingX: Double, world: [String] = [],
                       flags: [String] = []) -> GameState {
        var s = GameState.newRealm(seed: 5)
        s.day = day
        s.hour = hour
        s.flags = flags
        PetitionEngine.prepare(&s, catalog: .standard)
        s.king.x = kingX
        if !world.isEmpty {
            var court = s.court ?? CourtState()
            court.world = world.sorted()
            s.court = court
        }
        return s
    }

    private func sprites(_ desc: FrameDesc) -> [SpriteID] {
        desc.layer(.world).sprites.map(\.sprite)
    }

    /// World-2 (REVIEW-look-2.md B1: exteriors only): no room fades, no front and no interior is drawn; whoever stands
    /// in the castle is seen where he stands.
    func testNoRoomIsCutAwaySinceWorldTwo() {
        var rooms = RoomFades(kingX: 1650)
        XCTAssertTrue(RoomFades.rooms.isEmpty)
        for room in WorldLayout.RoomID.allCases {
            XCTAssertEqual(rooms.openness(room), 0, "\(room): shut, seen from outside")
            XCTAssertEqual(rooms.front(room), 0, "no front is drawn")
        }
        rooms.step(kingX: 1830, dt: 0.1, reduceMotion: false)
        XCTAssertTrue(rooms.isSettled)
        XCTAssertEqual(rooms.visibility(x: 1830), 1)
        XCTAssertEqual(rooms.visibility(x: 2040), 1)
        let additions = CastleRooms.additions(rooms: rooms, animTime: 1, reduceMotion: false, torch: 1, idBase: 9000)
        XCTAssertTrue(additions.props.isEmpty && additions.glows.isEmpty && additions.lights.isEmpty)
        let outside = realm(kingX: 1650)
        let frame = Self.frame(outside, focus: 1830, court: CourtScene(rooms: RoomFades(kingX: 1650)))
        for gone in [SpriteID.hallFront, .chapelInterior, .kitchenInterior] {
            XCTAssertFalse(sprites(frame.desc).contains(gone), "\(gone) is not drawn")
        }
        XCTAssertTrue(frame.desc.actors.contains { $0.sprite == .odile }, "the court stands where it stands")
        let kingIndex = frame.desc.actors.lastIndex { $0.sprite == .king } ?? -1
        let odileIndex = frame.desc.actors.firstIndex { $0.sprite == .odile } ?? Int.max
        XCTAssertLessThan(odileIndex, kingIndex, "the king stays in front of the court")
    }

    /// World-2: the hall door opens while the lord stands at it: the open frame, the hall's warm light in it (dim by
    /// day), its wedge on the cobbles and a warm pool at dusk and night; shut, a thin line of light under the door.
    func testTheHallDoorOpensForTheLordAndThrowsItsLight() {
        let world = PlaceholderScene.world(look: .two)
        func door(_ kingX: Double, hour: Double) -> Prop? {
            let s = realm(day: 2, hour: hour, kingX: kingX)
            return CastleRooms.scene(world, state: s, rooms: RoomFades(kingX: kingX)).props
                .first { $0.sprite == .forebuilding }
        }
        let gap = SceneLayout.castleDoorGap
        guard let shut = door(1700, hour: 22), let open = door(1830, hour: 22) else {
            return XCTFail("the forebuilding stands in look 2")
        }
        XCTAssertEqual(shut.frame, 0)
        XCTAssertTrue(shut.masks.contains { $0.dx == gap.dx && $0.dy == gap.dy }, "the line under the shut door")
        XCTAssertFalse(shut.emissive.contains { $0.sprite == .hallDoorGlow || $0.sprite == .hallDoorWedge })
        XCTAssertEqual(open.frame, 1)
        XCTAssertFalse(open.masks.contains { $0.dx == gap.dx && $0.dy == gap.dy })
        XCTAssertTrue(open.emissive.contains { $0.sprite == .hallDoorGlow && !$0.fadesByDay }, "the hall's light by day")
        XCTAssertTrue(open.emissive.contains { $0.sprite == .hallDoorWedge && $0.fadesByDay && $0.dy < 0 },
                      "the wedge on the cobbles, at dusk and night")
        XCTAssertTrue(open.lights.contains { $0.kind == .lantern && $0.x == SceneLayout.castleHallDoorX })
        XCTAssertEqual(door(1830 + CastleRooms.doorReach + 1, hour: 22)?.frame, 0)
        // At night the wedge lies on the lane before the door.
        let night = realm(day: 2, hour: 22, kingX: 1830)
        var options = FrameOptions(flickerTime: 1.5)
        options.look = .two
        let pixelScale = options.pixelScale(physicalWidth: 2622, physicalHeight: 1206)
        let camera = Camera(focusX: 1830, pixelScale: pixelScale)
        let scene = CastleRooms.scene(world, state: night, rooms: RoomFades(kingX: 1830))
        let desc = FrameBuilder.build(scene: scene, clock: DayClock(hour: 22, day: 2), camera: camera,
                                      pixelScale: pixelScale, options: options)
        let wedge = desc.emissives.first { $0.sprite == .hallDoorWedge }
        XCTAssertNotNil(wedge)
        if let wedge {
            // Fix round 1: from the threshold over the steps out onto the cobbles, 12 rows under the ground line.
            let ground = Camera.groundRow(targetHeight: desc.targetHeight)
            XCTAssertEqual(Int(wedge.rect.y + wedge.rect.w), ground + 12, "it reaches 12 rows out on the cobbles")
            XCTAssertLessThan(Int(wedge.rect.y), ground, "it starts on the steps")
        }
        let day = FrameBuilder.build(scene: scene, clock: DayClock(hour: 12, day: 2), camera: camera,
                                     pixelScale: pixelScale, options: options)
        XCTAssertNil(day.emissives.first { $0.sprite == .hallDoorWedge }, "no wedge by day")
        XCTAssertNotNil(day.emissives.first { $0.sprite == .hallDoorGlow }, "the hall's light shows by day too")
    }

    /// World-2 fix round 2 (the critic's blockers 1 and 2): no foreground frame stands at either gate, wherever the
    /// lord stands (the pier in front of the gatehouse and the slab in front of the postern are gone). The chapel's
    /// belfry stands empty once the bell is melted; a world change darkens one of the keep's windows.
    func testNoGateFrameTheBellAndTheKeepsWindow() {
        let world = PlaceholderScene.world(look: .two)
        var spots: [Double] = [1300, 1600]
        for passage in SceneLayout.castlePassages {
            spots += [passage.lowerBound, (passage.lowerBound + passage.upperBound) / 2, passage.upperBound]
        }
        for kingX in spots {
            let props = CastleRooms.scene(world, state: realm(kingX: kingX), rooms: RoomFades(kingX: kingX)).props
            XCTAssertFalse(props.contains { $0.sprite == .gateArchFg }, "no gate frame with the lord at \(kingX)")
            XCTAssertFalse(props.contains { $0.plane == .foreground && $0.region == .castle },
                           "no castle stone in the foreground at \(kingX)")
        }
        let bell = CastleRooms.scene(world, state: realm(kingX: 1600, world: ["castle.chapel.bell.missing"]),
                                     rooms: RoomFades(kingX: 1600))
        XCTAssertEqual(bell.props.first { $0.sprite == .chapelTower }?.frame, 1, "the empty belfry")
        XCTAssertEqual(CastleRooms.scene(world, state: realm(kingX: 1600), rooms: RoomFades(kingX: 1600))
            .props.first { $0.sprite == .chapelTower }?.frame, 0)
        let lit = CastleRooms.scene(world, state: realm(kingX: 1600), rooms: RoomFades(kingX: 1600))
        let dark = CastleRooms.scene(world, state: realm(kingX: 1600, world: ["castle.keep.window.dark"]),
                                     rooms: RoomFades(kingX: 1600))
        let litPanes = lit.props.first { $0.sprite == .keepT1 }?.masks.count ?? 0
        XCTAssertEqual(dark.props.first { $0.sprite == .keepT1 }?.masks.count, litPanes - 1, "one keep window dark")
    }

    func testTheCourtWalksTalksAndCarriesItsMarks() {
        var s = realm(day: 3, hour: 10, kingX: 1530)
        var court = CourtScene(rooms: RoomFades(kingX: 1530))
        let figures = CourtFrames.figures(state: s, catalog: .standard, scene: court, animTime: 2)
        XCTAssertTrue(figures.contains { $0.who == "marek" }, "day 3 is one of Marek's days")
        let yard = Self.frame(s, focus: 1530, court: court)
        // b3-yard (build 3, wave 2, lane 2, step 3): his cart stands by the back gate (2218), the drill yard's bunkhouse
        // keeps its front.
        let backGate = Self.frame(s, focus: CourtLayout.marekCartX + 24, court: court)
        XCTAssertTrue(sprites(backGate.desc).contains(.marekCart), "his cart in the courtyard by the back gate")
        XCTAssertTrue(yard.desc.actors.contains { $0.sprite == .brannock })
        XCTAssertTrue(yard.desc.actors.contains { $0.sprite == .bram })

        // Talking: Bram stops where he stands, turns to the king and gestures.
        let bram = figures.first { $0.who == "bram" }
        court.talking = "bram"
        court.talkX = bram?.x
        s.king.x = (bram?.x ?? 1570) + 20
        let talking = CourtFrames.figures(state: s, catalog: .standard, scene: court, animTime: 2)
        let speaking = talking.first { $0.who == "bram" }
        XCTAssertEqual(speaking?.talking, true)
        XCTAssertTrue((6...7).contains(speaking?.frame ?? -1), "his talk frames")
        XCTAssertEqual(speaking?.facing, 1, "turned to the king")

        // The speech mark over a member with a hint.
        court.marks = ["bram"]
        let marked = Self.frame(s, focus: 1530, court: court)
        XCTAssertTrue(marked.desc.actors.contains { $0.sprite == .speakerMark && $0.isEmissive },
                      "the mark reads at night too")

        // The smoothed places: a member walks back toward his round at a stroll; a far jump is taken at once.
        let drawn = CourtMotion.step(["bram": 1500, "pip": 100], targets: ["bram": 1580, "pip": 1700, "odile": 1856],
                                     dt: 0.5, reduceMotion: false)
        XCTAssertEqual(drawn["bram"] ?? 0, 1500 + CourtMotion.speed * 0.5, accuracy: 1e-9)
        XCTAssertEqual(drawn["pip"], 1700)
        XCTAssertEqual(drawn["odile"], 1856, "a new figure appears at its place")
        XCTAssertEqual(CourtMotion.step(["bram": 1500], targets: ["bram": 1580], dt: 0.1, reduceMotion: true)["bram"],
                       1580)
    }

    /// M3 fix (U2) drew a gold mark over the throne while petitioners waited in the cut-away hall. World-2: the hall is
    /// shut in the world (the throne and its marks are the stage lane's hall stage), so no such mark stands outside.
    func testNoThroneMarkStandsInTheWorld() {
        let s = realm(day: 3, hour: 10, kingX: 1830)
        XCTAssertFalse(AudienceRules.hall(s, catalog: .standard).isEmpty, "petitioners wait on day 3")
        let court = CourtScene(rooms: RoomFades(kingX: 1830))
        let marks = Self.frame(s, focus: 1830, court: court).desc.actors.filter { $0.sprite == .speakerMark
            && $0.tint.x == CourtFrames.throneMarkGold.x }
        XCTAssertTrue(marks.isEmpty)
    }

    /// Stage 7's banners: a house's banner hangs once the banners are hung (`tithe_letters`) and the house stands
    /// with the lord; the realm's renewed banner gives way at that place.
    func testAHousesBannerHangsWhereItStandsWithTheLord() {
        let hung = CourtFrames.houseBannersHung
        XCTAssertEqual(CourtFrames.houseBanners.map { $0.sprite },
                       [.bannerBrine, .bannerCalder, .bannerVarn, .bannerLorn, .bannerOxmoor])
        XCTAssertEqual(CourtFrames.houseBanners.count, CourtFrames.bannerXs.count, "one place each")
        XCTAssertTrue(CourtWorld.registry.contains { $0.id == hung })
        XCTAssertEqual(CourtFrames.houseBannerPlaces(world: [], flags: ["varn_with"]), [], "not hung yet")
        XCTAssertEqual(CourtFrames.houseBannerPlaces(world: [hung], flags: []), [], "no house stands with the lord")
        XCTAssertEqual(CourtFrames.houseBannerPlaces(world: [hung], flags: ["lorn_with", "varn_with"]), [2, 3])
        let houses = Set(CourtFrames.houseBanners.map { $0.sprite })
        // World-2: the hall is shut in the world (its banners hang in the stage lane's hall): none is drawn outside.
        let outside = realm(day: 2, hour: 22, kingX: 1830, world: ["castle.banners.new", hung],
                            flags: CourtFrames.houseBanners.map { $0.flag })
        let drawn = Self.frame(outside, focus: 1830, court: CourtScene(rooms: RoomFades(kingX: 1830))).layer.props
        XCTAssertFalse(drawn.contains { houses.contains($0.sprite) || $0.sprite == .hallBanner },
                       "no hall banner in the world")
    }

    func testTheCastlesWorldChangesAreDrawn() {
        let changes = ["castle.statue", "castle.guards.wall", "castle.banners.new", "castle.hall.tapestry",
                       "castle.courtyard.stall", "castle.seren.lantern"]
        let yard = realm(day: 2, hour: 10, kingX: 1500, world: changes)
        let courtyard = Self.frame(yard, focus: 1500, court: CourtScene(rooms: RoomFades(kingX: 1500)))
        XCTAssertTrue(sprites(courtyard.desc).contains(.statue), "the statue of the lamplighter saint")
        // b3-yard (step 3): the stall stands by the back gate.
        let stall = Self.frame(yard, focus: CourtLayout.marekCartX + 24, court: CourtScene(rooms: RoomFades(kingX: 1500)))
        XCTAssertTrue(sprites(stall.desc).contains(.marekCart), "the stall every day")
        XCTAssertEqual(courtyard.desc.actors.filter { $0.sprite == .guardsman && $0.rect.y < 600 }.count, 2,
                       "two guards on the wall walk (the others wait on the ground)")
        // World-2: the hall's and the chapel's insides do not show in the world (the stage lane's hall shows its own).
        let hall = realm(day: 2, hour: 22, kingX: 1830, world: changes)
        let outside = Self.frame(hall, focus: 1830, court: CourtScene(rooms: RoomFades(kingX: 1830)))
        for inside in [SpriteID.hallBanner, .tapestry, .serenLantern] {
            XCTAssertFalse(sprites(outside.desc).contains(inside), "\(inside) is inside the shut hall")
        }
        let chapel = realm(day: 2, hour: 10, kingX: 2040,
                           world: ["castle.chapel.candles", "castle.chapel.bell.missing"])
        let shut = Self.frame(chapel, focus: 2040, court: CourtScene(rooms: RoomFades(kingX: 2040)))
        XCTAssertFalse(sprites(shut.desc).contains(.votiveCandles), "the candles burn inside the chapel")
        XCTAssertFalse(sprites(shut.desc).contains(.bellGone), "the empty belfry is the chapel tower's own frame")
        let lit = CastleRooms.scene(GameFrameSupport.world, state: realm(day: 2, hour: 22, kingX: 1360),
                                    rooms: RoomFades(kingX: 1360))
        let mourning = realm(day: 2, hour: 22, kingX: 1360, world: ["castle.keep.window.dark"])
        let dark = CastleRooms.scene(GameFrameSupport.world, state: mourning, rooms: RoomFades(kingX: 1360))
        let litMasks = lit.props.first { $0.sprite == .keepTop }?.masks.count ?? 0
        let darkMasks = dark.props.first { $0.sprite == .keepTop }?.masks.count ?? 0
        XCTAssertEqual(darkMasks, litMasks - 1, "one keep window stays dark")
        // M3 fix (C6): both far keeps (the gorge's at mid x 641, the valley's at 560) lose exactly their upper right
        // pane.
        for (x, paneX) in [(641.0, SceneLayout.gorgeKeepDarkPaneX), (560.0, SceneLayout.valleyKeepDarkPaneX)] {
            let before = lit.props.first { $0.plane == .mid && $0.sprite == .keepFar && $0.x == x }?.masks ?? []
            let after = dark.props.first { $0.plane == .mid && $0.sprite == .keepFar && $0.x == x }?.masks ?? []
            XCTAssertGreaterThanOrEqual(before.count, 2, "the far keep at \(x) has its windows")
            XCTAssertEqual(after.count, before.count - 1, "the far keep at \(x) loses one pane")
            let gone = before.filter { !after.contains($0) }
            XCTAssertEqual(gone.map(\.dx), [paneX])
            XCTAssertEqual(gone.map(\.dy), [SceneLayout.keepFarDarkPaneY])
            XCTAssertEqual(gone.first?.dy, before.map(\.dy).max(), "the upper row")
            XCTAssertEqual(gone.first?.dx, before.filter { $0.dy == SceneLayout.keepFarDarkPaneY }.map(\.dx).max(),
                           "its right pane")
        }
    }

    func testACrowdedCastleFrameKeepsItsBudget() {
        for hour in [10.0, 21.5] {
            let s = realm(day: 9, hour: hour, kingX: 1830, world: CourtWorld.registry.map(\.id),
                          flags: [CourtLayout.serenInFlag])
            for focus in [1450.0, 1650, 1830, 2040, 2180] {
                for x in [1650.0, 1830, 2040, 2180] {
                    var at = s
                    at.king.x = x
                    let (desc, _) = Self.frame(at, focus: focus, court: CourtScene(rooms: RoomFades(kingX: x)))
                    let place = "\(hour) h, focus \(Int(focus)), king \(Int(x))"
                    XCTAssertLessThan(desc.counts.instances, 300, "\(place): \(desc.counts.instances) instances")
                    XCTAssertLessThan(desc.counts.lights, 40, "\(place): \(desc.counts.lights) lights")
                }
            }
        }
    }

    /// World-2: the closed castle of look 2 at its third tier at night stays inside the frame's budget everywhere
    /// from the gatehouse to the postern.
    func testTheClosedCastleKeepsItsBudget() {
        let world = PlaceholderScene.world(look: .two, castle: CastleStage(tier: 3))
        var options = FrameOptions(flickerTime: 1.5)
        options.look = .two
        let pixelScale = options.pixelScale(physicalWidth: 2622, physicalHeight: 1206)
        for focus in stride(from: 1300.0, through: 2500, by: 100) {
            let s = realm(day: 9, hour: 21.5, kingX: focus)
            let scene = CastleRooms.scene(world, state: s, rooms: RoomFades(kingX: focus))
            let desc = FrameBuilder.build(scene: scene, clock: DayClock(hour: 21.5, day: 9),
                                          camera: Camera(focusX: focus, pixelScale: pixelScale),
                                          pixelScale: pixelScale, options: options)
            XCTAssertLessThan(desc.counts.instances, 300, "focus \(Int(focus)): \(desc.counts.instances) instances")
            XCTAssertLessThan(desc.counts.lights, 40, "focus \(Int(focus)): \(desc.counts.lights) lights")
        }
    }
}
