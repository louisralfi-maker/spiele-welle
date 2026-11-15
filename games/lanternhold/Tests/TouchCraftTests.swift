import Foundation
import XCTest
@testable import Lanternhold

/// Touch the world, fix round 1 (stage lane, step stage-2; the critic's look 1): the hall door where the facade paints
/// it, the marks in one height band and clear of the screen's edges, one mark for sites side by side, the barracks'
/// mark only while a recruit can be paid, the site's cheapest price on its slip, an empty plot's footing, the gold rim
/// on the marked thing, the raised lantern's pose, flare and ring, and the launch arguments of the night's pictures.
@MainActor
final class TouchCraftTests: XCTestCase {
    private func thing(_ id: String, kind: TouchKind, x: Double, half: Double = 4, top: Double = 10) -> TouchThing {
        TouchThing(id: id, kind: kind, act: .recruit, x: x, standX: x, halfWidth: half, top: top,
                   rank: TouchRules.rank(kind))
    }

    // MARK: - The hall door

    func testTheHallDoorStandsOnThePaintedDoor() {
        let door = HallLayout.worldDoorX
        XCTAssertEqual(door, CastleRooms.hallX + 47, "the middle of the line of light under the painted door")
        let lanterns = CastleRooms.hallFrontLights.filter { $0.kind == .lantern }.map { CastleRooms.hallX + $0.dx }
        XCTAssertEqual(lanterns.count, 2)
        XCTAssertTrue(lanterns.allSatisfy { abs($0 - door) < 25 }, "between the door's two wall lanterns")
        for window in CastleRooms.hallFrontLights where window.kind == .window {
            XCTAssertGreaterThan(abs(CastleRooms.hallX + window.dx - door), 40, "clear of every window")
        }
        var s = GameState.newRealm(seed: 2)
        s.hour = 10
        s.king.x = door + 80
        let things = TouchThings.world(s, balance: .standard, figures: [], talked: [])
        let target = things.first { $0.id == "touch-door-hall" }
        XCTAssertEqual(target?.x, door, "the target")
        XCTAssertEqual(target?.standX, door, "his standing place")
        XCTAssertEqual(target?.marked, true, "its mark, from 80 px away")
        XCTAssertEqual(HallRules.doorX, door, "the way in and out")
    }

    func testTheTestsCanStandAtTheDoor() {
        XCTAssertEqual(DebugArgs(values: ["GWCameraX": "hallDoor"]).cameraX, HallLayout.worldDoorX)
        XCTAssertEqual(DebugArgs(values: ["GWCameraX": "hallDoor+80"]).cameraX, HallLayout.worldDoorX + 80)
        XCTAssertEqual(DebugArgs(values: ["GWCameraX": "hallDoor-12"]).cameraX, HallLayout.worldDoorX - 12)
        XCTAssertEqual(DebugArgs(values: ["GWCameraX": "1500"]).cameraX, 1500)
        XCTAssertNil(DebugArgs(values: ["GWCameraX": "hallDoor+x"]).cameraX)
    }

    // MARK: - The marks

    func testTheMarksKeepToOneBand() {
        let tower = thing("tower", kind: .plot, x: 100, half: 10, top: 66)
        XCTAssertEqual(tower.markLift, TouchRules.bandTip, "at the building's door, not at its crown")
        XCTAssertLessThanOrEqual(tower.markLift + TouchRules.markHeight, 48)
        XCTAssertGreaterThanOrEqual(TouchRules.area(tower, minimum: 22).top, 66, "the building answers to its top")
        XCTAssertEqual(thing("site", kind: .plot, x: 100, top: 6).markLift, 6 + TouchRules.markGap, "a low site")
        XCTAssertEqual(thing("barracks", kind: .recruit, x: 100, top: 44).markLift, TouchRules.bandTip)
        XCTAssertEqual(thing("tamsin", kind: .talk, x: 100, top: 30).markLift, 30 + TouchRules.markGap,
                       "over a person's head")
        XCTAssertEqual(thing("door", kind: .door, x: 100, top: 40).markLift, 40 + TouchRules.markGap,
                       "over the door's arch")
    }

    func testNoMarkAtTheScreensEdges() {
        let list = [thing("left", kind: .door, x: 20), thing("inside", kind: .recruit, x: 140),
                    thing("right", kind: .plot, x: 385)]
        let marked = TouchRules.marked(list, lordX: 200, viewLeft: 0, viewRight: 400).map(\.id)
        XCTAssertEqual(marked, ["inside"], "a thing within 30 px of an edge carries no mark")
    }

    func testOneMarkForSitesSideBySide() {
        let sites = [thing("a", kind: .plot, x: 100), thing("b", kind: .plot, x: 124)]
        XCTAssertEqual(TouchRules.marked(sites, lordX: 90, viewLeft: 0, viewRight: 400).map(\.id), ["a"],
                       "the nearer of two braziers' sites")
        let fires = [thing("c", kind: .brazier, x: 255), thing("d", kind: .brazier, x: 279)]
        XCTAssertEqual(TouchRules.marked(fires, lordX: 300, viewLeft: 0, viewRight: 400).map(\.id), ["d"])
        let apart = [thing("e", kind: .plot, x: 100), thing("f", kind: .plot, x: 160)]
        XCTAssertEqual(TouchRules.marked(apart, lordX: 90, viewLeft: 0, viewRight: 400).count, 2)
    }

    func testTheBarracksCarryTheirMarkOnlyWhileARecruitCanBePaid() {
        var s = GameState.newRealm(seed: 2)
        s.hour = 10
        s.gold = 0
        let poor = TouchThings.world(s, balance: .standard, figures: [], talked: []).first {
            $0.id == "touch-recruit-barracks"
        }
        XCTAssertEqual(poor?.marked, false, "no mark that leads to a card of refusals")
        let cheapest = min(Balance.standard.archerPrice, Balance.standard.guardPrice)
        XCTAssertEqual(poor?.price, cheapest, "the slip names the cheapest recruit")
        s.gold = 1_000
        let rich = TouchThings.world(s, balance: .standard, figures: [], talked: []).first {
            $0.id == "touch-recruit-barracks"
        }
        XCTAssertEqual(rich?.marked, s.taxpayers > 0)
    }

    func testTheSiteNamesItsCheapestPriceAndShowsItsFooting() throws {
        var s = GameState.newRealm(seed: 2)
        s.hour = 9
        s.gold = 500
        let plot = Realm.lines[0].braziers[0]
        let things = TouchThings.world(s, balance: .standard, figures: [], talked: [])
        let site = try XCTUnwrap(things.first { $0.id == "touch-plot-\(plot)" })
        let cheapest = Build.options(s, plot: plot, balance: .standard).map(\.price).min()
        XCTAssertEqual(site.price, cheapest.flatMap { $0 > 0 ? $0 : nil }, "the cheapest price with its coin")
        XCTAssertNotNil(site.footing, "an empty plot has a footing")
        let footing = try XCTUnwrap(site.footing)
        XCTAssertTrue((8...24).contains(footing))
        let marks = TouchMarks.marks([site], pressed: nil)
        XCTAssertEqual(marks.first?.footing, footing)
        let framing = TouchFraming(stage: .world, whole: 0, deviceShift: 0, scale: 6, groundY: 1050,
                                   physicalWidth: 2622, physicalHeight: 1206)
        var near = marks
        near[0].poolX = 200
        let actors = TouchFooting.actors(near, framing: framing)
        XCTAssertEqual(actors.count, TouchFooting.pixels(x: 200, half: footing).count)
        XCTAssertTrue(actors.allSatisfy { !$0.isEmissive && $0.isLit }, "part of the world, lit")
        near[0].footing = nil
        XCTAssertTrue(TouchFooting.actors(near, framing: framing).isEmpty, "only while its mark shows")
    }

    func testTheFootingIsTwoStakesACordAndAChalkLine() {
        let pixels = TouchFooting.pixels(x: 100, half: 10)
        let stakes = pixels.filter { $0.color == TouchFooting.woodColor }
        XCTAssertEqual(stakes.count, 2 * TouchFooting.stakeHeight)
        XCTAssertEqual(Set(stakes.map(\.x)), [90, 110])
        XCTAssertTrue(pixels.contains { $0.color == TouchFooting.chalkColor && $0.lift == -1 }, "the chalk line")
        let cord = pixels.filter { $0.color == TouchFooting.cordColor }
        XCTAssertEqual(cord.count, 19)
        XCTAssertTrue(cord.contains { $0.lift == 2 } && cord.contains { $0.lift == 3 }, "it sags in the middle")
    }

    // MARK: - The rim

    func testTheRimIsOnTheMarkedThing() throws {
        let mark = TouchMark(sprite: .tapBuild, x: 100, lift: 17, pressed: false, poolX: 100, kind: .brazier,
                             who: nil, half: 5, footing: nil)
        let width = Double(SpriteID.brazier.size.width)
        let props = [
            Prop(id: EntityFrames.propIDBase + 1, sprite: .brazier, plane: .world, x: 100 - width / 2, y: 0),
            Prop(id: EntityFrames.propIDBase + 2, sprite: .brazier, plane: .world, x: 300, y: 0),
            Prop(id: CourtFrames.propIDBase + 1, sprite: .bench, plane: .world, x: 96, y: 0),
        ]
        let rims = TouchRims.world([mark], props: props, figures: [], night: 0)
        XCTAssertEqual(rims.count, 1, "the brazier under the mark, nothing else")
        let rim = try XCTUnwrap(rims.first)
        XCTAssertEqual(rim.kind, .rim)
        XCTAssertEqual(rim.sprite, .brazier)
        var pressed = mark
        pressed.pressed = true
        let bright = try XCTUnwrap(TouchRims.world([pressed], props: props, figures: [], night: 0).first)
        XCTAssertGreaterThan(bright.color.x, rim.color.x, "brighter while the finger is down")
        let body = SpeakerBody.court(.petitionerD)
        let figure = DrawnFigure(who: "tamsin", key: "tamsin", body: body, x: 150, y: 0, facing: -1, frame: 2,
                                 alpha: 1, look: nil, petition: nil, talking: false)
        let talk = TouchMark(sprite: .tapTalk, x: 150, lift: 33, pressed: false, poolX: 150, kind: .talk,
                             who: "tamsin", half: 4, footing: nil)
        let person = try XCTUnwrap(TouchRims.world([talk], props: props, figures: [figure], night: 1).first)
        XCTAssertEqual(person.sprite, figure.sprite)
        XCTAssertEqual(person.frame, 2)
        XCTAssertTrue(person.flipped)
        XCTAssertLessThan(person.color.z, person.color.x, "warm at night")
    }

    func testTheRimsQuadReachesAPixelPastTheSprite() throws {
        var layer = EntityLayer()
        var glow = EntityGlow(.brazier, x: 100, y: 0, color: SIMD4<Float>(1, 1, 1, 1))
        glow.kind = .rim
        layer.glows = [glow]
        let item = try XCTUnwrap(layer.emissives(worldWhole: 0, groundRow: 150, targetWidth: 400).first)
        let size = SpriteID.brazier.size
        XCTAssertEqual(item.kind, .rim)
        XCTAssertEqual(item.rect, SIMD4<Float>(99, Float(150 - size.height - 1), Float(size.width + 2),
                                               Float(size.height + 1)), "left, right and up, not below")
    }

    // MARK: - Raise the lantern

    func testTheRaisedLanternLiftsThePoleAndFlares() {
        XCTAssertEqual(LanternFlare.frame(since: 0.05, standing: true), 8, "the lift")
        XCTAssertEqual(LanternFlare.frame(since: 1.0, standing: true), 9, "held high")
        XCTAssertNil(LanternFlare.frame(since: 1.0, standing: false), "walking, his walk")
        XCTAssertNil(LanternFlare.frame(since: LanternRaise.raisedSeconds + 0.1, standing: true), "guttering")
        XCTAssertNil(LanternFlare.frame(since: nil, standing: true))
        XCTAssertEqual(LanternFlare.strength(since: 0), 1)
        XCTAssertEqual(LanternFlare.strength(since: LanternFlare.seconds), 0)
        XCTAssertEqual(LanternFlare.strength(since: nil), 0)
        let ring = LanternFlare.ring(cx: 0, cy: 20, radius: LanternRaise.raisedRadius, floor: -26)
        XCTAssertGreaterThan(ring.count, 250, "a whole edge of pixels")
        for pixel in ring {
            let r = hypot(pixel.x + 0.5, pixel.y + 0.5 - 20)
            XCTAssertEqual(r, LanternRaise.raisedRadius, accuracy: 1.5)
            XCTAssertGreaterThanOrEqual(pixel.y, -26, "nothing under the lane")
        }
        XCTAssertEqual(Set(ring.map { "\($0.x),\($0.y)" }).count, ring.count, "each pixel once")
    }

    // MARK: - The night's pictures

    func testTheNightsPicturesCanBeForced() {
        let args = DebugArgs(values: ["GWDamage": "0, 6", "GWSnuff": "2", "GWPressed": "nearest"])
        XCTAssertEqual(args.damage, [0, 6])
        XCTAssertEqual(args.snuff, [2])
        XCTAssertEqual(args.pressed, "nearest")
        var s = GameState.newRealm(seed: 2)
        let wall = Realm.lines[0].wall
        let brazier = Realm.lines[0].braziers[0]
        s.plots[brazier].item = .brazier
        if s.plots[wall].item == nil {
            s.plots[wall].item = .gate
            s.plots[wall].hp = Build.maxHP(.gate, balance: .standard)
        }
        let item = s.plots[wall].item ?? .gate
        GameStart.applyTouchProofs(&s, args: args, balance: .standard)
        XCTAssertLessThan(s.plots[wall].hp, Build.maxHP(item, balance: .standard), "the gate damaged")
        XCTAssertTrue(s.plots[brazier].snuffed, "the brazier cold")
        s.hour = 22
        let things = TouchThings.world(s, balance: .standard, figures: [], talked: [])
        XCTAssertTrue(things.contains { $0.id == "touch-wall-\(wall)" })
        XCTAssertTrue(things.contains { $0.id == "touch-brazier-\(brazier)" })
    }
}
