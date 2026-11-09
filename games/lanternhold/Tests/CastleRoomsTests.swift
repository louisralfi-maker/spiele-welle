import Foundation
import XCTest
@testable import Lanternhold

/// The castle's rooms cut away and the court drawn in them (M3 step 3): a front fades over 0.25 s when the king steps
/// in and returns when he leaves (at once with Reduce Motion); a shut room hides its figures, its furniture and its warm
/// lights, an open one shows its interior lit; the court walks its rounds as actors with talk frames and speech
/// marks, petitioners wait on the benches, Marek's cart on his days, the castle's world changes; the frame stays inside
/// its budget.
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

    func testAFrontFadesInAQuarterSecondAndSwapsAtOnceWithReduceMotion() {
        var rooms = RoomFades(kingX: 1650)
        XCTAssertEqual(rooms.openness(.greatHall), 0, "the king in the courtyard: the hall is shut")
        XCTAssertEqual(rooms.front(.greatHall), 1)
        rooms.step(kingX: 1830, dt: 0.1, reduceMotion: false)
        XCTAssertEqual(rooms.openness(.greatHall), 0.4, accuracy: 1e-9)
        XCTAssertFalse(rooms.isSettled)
        rooms.step(kingX: 1830, dt: 0.2, reduceMotion: false)
        XCTAssertEqual(rooms.openness(.greatHall), 1, "open after 0.25 s")
        XCTAssertEqual(rooms.openness(.chapel), 0)
        rooms.step(kingX: 2040, dt: 0.125, reduceMotion: false)
        XCTAssertEqual(rooms.openness(.greatHall), 0.5, accuracy: 1e-9, "the hall shuts while the chapel opens")
        XCTAssertEqual(rooms.openness(.chapel), 0.5, accuracy: 1e-9)
        rooms.step(kingX: 2180, dt: 0.01, reduceMotion: true)
        XCTAssertEqual(rooms.openness(.kitchen), 1, "Reduce Motion: an instant swap")
        XCTAssertEqual(rooms.openness(.chapel), 0)
        XCTAssertEqual(rooms.openness(.greatHall), 0)
        XCTAssertTrue(rooms.isSettled)
        XCTAssertEqual(rooms.visibility(x: 1500), 1, "the courtyard has no front")
        XCTAssertEqual(rooms.visibility(x: 2190), 1)
        XCTAssertEqual(rooms.visibility(x: 1850), 0)
        XCTAssertEqual(RoomFades(kingX: 1830).openness(.greatHall), 1, "no fade at the start")
    }

    func testTheShutHallHidesItsCourtAndTheOpenHallShowsIt() {
        let outside = realm(kingX: 1650)
        let shut = Self.frame(outside, focus: 1650, court: CourtScene(rooms: RoomFades(kingX: 1650)))
        XCTAssertTrue(sprites(shut.desc).contains(.hallFront), "the hall's front from the courtyard")
        XCTAssertFalse(shut.desc.actors.contains { $0.sprite == .odile }, "Odile is inside the shut hall")
        XCTAssertFalse(sprites(shut.desc).contains(.bench), "the benches are inside")
        let inside = realm(kingX: 1830)
        let open = Self.frame(inside, focus: 1830, court: CourtScene(rooms: RoomFades(kingX: 1830)))
        XCTAssertFalse(sprites(open.desc).contains(.hallFront), "a front that is gone is not drawn")
        XCTAssertTrue(open.desc.actors.contains { $0.sprite == .odile }, "Odile by the throne")
        XCTAssertTrue(sprites(open.desc).contains(.bench))
        XCTAssertTrue(sprites(open.desc).contains(.taxLectern))
        let waiting = AudienceRules.hall(inside, catalog: .standard).count
        XCTAssertGreaterThan(waiting, 0)
        let bodies: Set<SpriteID> = [.citizen, .citizenB, .citizenC, .petitionerD, .petitionerE, .guardsman, .builder,
                                     .serLudo, .bard, .envoy, .herald]
        let inHall = open.desc.actors.filter { bodies.contains($0.sprite) }.count
        XCTAssertGreaterThanOrEqual(inHall, 1, "today's petitioners wait in the hall")
        // The king stays in front of the court.
        let kingIndex = open.desc.actors.lastIndex { $0.sprite == .king } ?? -1
        let odileIndex = open.desc.actors.firstIndex { $0.sprite == .odile } ?? Int.max
        XCTAssertLessThan(odileIndex, kingIndex)
        // Halfway through the fade the front is translucent.
        var half = RoomFades(kingX: 1650)
        half.step(kingX: 1830, dt: 0.125, reduceMotion: false)
        let fading = Self.frame(inside, focus: 1830, court: CourtScene(rooms: half))
        let front = fading.desc.layer(.world).sprites.first { $0.sprite == .hallFront }
        XCTAssertEqual(front?.tint.w ?? 0, 0.5, accuracy: 1e-6)
        let odile = fading.desc.actors.first { $0.sprite == .odile }
        XCTAssertEqual(odile?.tint.w ?? 0, 0.5, accuracy: 1e-6, "the court fades in with the room")
    }

    func testTheChapelAndTheKitchenOpenWithTheirInteriorsLit() {
        let night = realm(day: 2, hour: 22, kingX: 2040)
        let chapel = Self.frame(night, focus: 2040, court: CourtScene(rooms: RoomFades(kingX: 2040)))
        XCTAssertTrue(sprites(chapel.desc).contains(.chapelInterior))
        XCTAssertFalse(sprites(chapel.desc).contains(.chapel), "the chapel's front is gone")
        XCTAssertTrue(sprites(chapel.desc).contains(.kitchen), "the kitchen stays shut")
        XCTAssertFalse(sprites(chapel.desc).contains(.kitchenInterior))
        XCTAssertTrue(chapel.layer.glows.contains { $0.sprite == .brazierFlame && abs($0.x - (CastleRooms.chapelX + 112)) < 0.5 },
                      "the Flame burns in its bowl")
        XCTAssertTrue(chapel.layer.lights.contains { $0.source.kind == .brazier && abs($0.source.x - 2076) < 0.5 },
                      "and lights the chapel")
        XCTAssertLessThan(chapel.desc.counts.lights, 40)
        let shutHall = chapel.layer.lights.first { $0.source.kind == .hearth && abs($0.source.x - (Realm.hearthX + 13)) < 0.5 }
        XCTAssertEqual(shutHall?.source.intensity ?? 0, 0, accuracy: 1e-9, "the shut hall's hearth paints no pool outside")

        let kitchenDay = realm(day: 2, hour: 11, kingX: 2183)
        let kitchen = Self.frame(kitchenDay, focus: 2183, court: CourtScene(rooms: RoomFades(kingX: 2183)))
        XCTAssertTrue(sprites(kitchen.desc).contains(.kitchenInterior))
        XCTAssertFalse(sprites(kitchen.desc).contains(.kitchen))
        XCTAssertTrue(kitchen.desc.actors.contains { $0.sprite == .tamsin }, "Tamsin in her kitchen")
        XCTAssertTrue(kitchen.layer.glows.contains { $0.sprite == .hearthFire && abs($0.x - (CastleRooms.kitchenX + 95)) < 0.5 },
                      "the oven-hearth burns")

        let scene = CastleRooms.scene(GameFrameSupport.world, state: kitchenDay, rooms: RoomFades(kingX: 1650))
        let chapelFront = scene.props.first { $0.sprite == .chapel }
        XCTAssertEqual(chapelFront?.alpha, 1)
        XCTAssertEqual(chapelFront?.masks.count, CastleRooms.chapelMasks.count, "glowing through its real panes")
        XCTAssertTrue(chapelFront?.emissive.isEmpty ?? false)
    }

    func testTheCourtWalksTalksAndCarriesItsMarks() {
        var s = realm(day: 3, hour: 10, kingX: 1530)
        var court = CourtScene(rooms: RoomFades(kingX: 1530))
        let figures = CourtFrames.figures(state: s, catalog: .standard, scene: court, animTime: 2)
        XCTAssertTrue(figures.contains { $0.who == "marek" }, "day 3 is one of Marek's days")
        let yard = Self.frame(s, focus: 1530, court: court)
        XCTAssertTrue(sprites(yard.desc).contains(.marekCart), "his cart in the courtyard")
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

    /// M3 fix (U2): a gold mark over the throne while petitioners wait in the hall by day (the same art as the speech
    /// mark, drawn after the lighting); gone with the last petitioner, at night and under the audience.
    func testTheThroneIsMarkedWhilePetitionersWait() {
        var s = realm(day: 3, hour: 10, kingX: 1830)
        XCTAssertFalse(AudienceRules.hall(s, catalog: .standard).isEmpty, "petitioners wait on day 3")
        let court = CourtScene(rooms: RoomFades(kingX: 1830))
        func marks(_ state: GameState) -> [ActorInstance] {
            Self.frame(state, focus: 1830, court: court).desc.actors.filter { $0.sprite == .speakerMark }
        }
        let waiting = marks(s)
        XCTAssertEqual(waiting.count, 1, "one mark over the throne")
        XCTAssertEqual(waiting.first?.isEmissive, true, "it reads in the dim hall")
        XCTAssertEqual(waiting.first?.tint.x, CourtFrames.throneMarkGold.x)
        var night = s
        night.hour = 22
        XCTAssertTrue(marks(night).isEmpty, "they went home at the horn")
        s.court?.queue = []
        XCTAssertTrue(marks(s).isEmpty, "nobody waits")
    }

    func testTheCastlesWorldChangesAreDrawn() {
        let changes = ["castle.statue", "castle.guards.wall", "castle.banners.new", "castle.hall.tapestry",
                       "castle.courtyard.stall", "castle.seren.lantern"]
        let yard = realm(day: 2, hour: 10, kingX: 1500, world: changes)
        let courtyard = Self.frame(yard, focus: 1500, court: CourtScene(rooms: RoomFades(kingX: 1500)))
        XCTAssertTrue(sprites(courtyard.desc).contains(.statue), "the statue of the lamplighter king")
        XCTAssertTrue(sprites(courtyard.desc).contains(.marekCart), "the stall every day")
        XCTAssertEqual(courtyard.desc.actors.filter { $0.sprite == .guardsman && $0.rect.y < 600 }.count, 2,
                       "two guards on the wall walk (the others wait on the ground)")
        let hall = realm(day: 2, hour: 22, kingX: 1830, world: changes)
        let inside = Self.frame(hall, focus: 1830, court: CourtScene(rooms: RoomFades(kingX: 1830)))
        XCTAssertEqual(sprites(inside.desc).filter { $0 == .hallBanner }.count, CourtFrames.bannerXs.count)
        XCTAssertTrue(sprites(inside.desc).contains(.tapestry))
        XCTAssertTrue(sprites(inside.desc).contains(.serenLantern))
        XCTAssertTrue(inside.layer.lights.contains { $0.source.color == CourtFrames.coldLight }, "its cold light")
        let chapel = realm(day: 2, hour: 10, kingX: 2040,
                           world: ["castle.chapel.candles", "castle.chapel.bell.missing"])
        let open = Self.frame(chapel, focus: 2040, court: CourtScene(rooms: RoomFades(kingX: 2040)))
        XCTAssertTrue(sprites(open.desc).contains(.votiveCandles))
        XCTAssertTrue(sprites(open.desc).contains(.bellGone))
        let lit = CastleRooms.scene(GameFrameSupport.world, state: realm(day: 2, hour: 22, kingX: 1360),
                                    rooms: RoomFades(kingX: 1360))
        let mourning = realm(day: 2, hour: 22, kingX: 1360, world: ["castle.keep.window.dark"])
        let dark = CastleRooms.scene(GameFrameSupport.world, state: mourning, rooms: RoomFades(kingX: 1360))
        let litMasks = lit.props.first { $0.sprite == .keepTop }?.masks.count ?? 0
        let darkMasks = dark.props.first { $0.sprite == .keepTop }?.masks.count ?? 0
        XCTAssertEqual(darkMasks, litMasks - 1, "one keep window stays dark")
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
}
