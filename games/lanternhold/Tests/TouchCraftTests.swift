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
        // The join: the world lane's forebuilding paints the door; its middle is the line of light under it.
        XCTAssertEqual(door, SceneLayout.castleHallDoorX, "the world's one named value of the painted door")
        let sill = SceneLayout.castleForebuildingX + SceneLayout.castleDoorGap.dx
            + Double(SceneLayout.castleDoorGap.width) / 2
        XCTAssertEqual(sill, door, "the middle of the line of light under the forebuilding's door")
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
        XCTAssertEqual(thing("site", kind: .plot, x: 100, top: 6).markLift, TouchRules.siteTip,
                       "a low site's sign over the heads (stage-3-interface)")
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

    func testTheErrandsThingTakesItsGroupsPlace() {
        let a = thing("a", kind: .plot, x: 100)
        let b = thing("b", kind: .plot, x: 124)
        let door = thing("door", kind: .door, x: 300)
        let marked = TouchRules.marked([a, b, door], lordX: 90, viewLeft: 0, viewRight: 400)
        XCTAssertEqual(marked.map(\.id), ["a", "door"])
        XCTAssertEqual(TouchRules.withErrand(marked, b).map(\.id), ["b", "door"],
                       "the touched site's mark, not a pair of hammers")
        XCTAssertEqual(TouchRules.withErrand(marked, a).map(\.id), ["a", "door"], "already marked: as it was")
    }

    func testAWallCarriesNoMarkWhileItsRepairCoolsDown() throws {
        var s = GameState.newRealm(seed: 2)
        s.hour = 22
        let wall = Realm.lines[0].wall
        if s.plots[wall].item == nil { s.plots[wall].item = .gate }
        let item = s.plots[wall].item ?? .gate
        s.plots[wall].hp = Build.maxHP(item, balance: .standard) / 2
        let ready = try XCTUnwrap(TouchThings.world(s, balance: .standard, figures: [], talked: []).first {
            $0.id == "touch-wall-\(wall)"
        })
        XCTAssertTrue(ready.marked)
        XCTAssertEqual(ready.rimX, EntityFrames.drawnCentre(plot: wall, layouts: KingTargets.layouts(s,
                                                            balance: .standard)).x, "the rim on the gate as drawn")
        s.king.patchCooldown = 3
        let cooling = try XCTUnwrap(TouchThings.world(s, balance: .standard, figures: [], talked: []).first {
            $0.id == "touch-wall-\(wall)"
        })
        XCTAssertFalse(cooling.marked, "just paid: no mark that would only be refused")
    }

    func testTheBarracksCarryTheirMarkOnlyWhileARecruitCanBePaid() {
        // Build 3, the count: each half of the barracks is a thing with its own recruit and price.
        var s = GameState.newRealm(seed: 2)
        s.hour = 10
        s.gold = 0
        let poor = TouchThings.world(s, balance: .standard, figures: [], talked: [])
        let archer = poor.first { $0.id == "touch-recruit-archer" }
        XCTAssertEqual(archer?.marked, false, "no mark that leads to a refusal")
        XCTAssertEqual(archer?.price, Balance.standard.archerPrice, "the archer's price")
        XCTAssertEqual(poor.first { $0.id == "touch-recruit-guard" }?.price, Balance.standard.guardPrice)
        s.gold = 1_000
        let rich = TouchThings.world(s, balance: .standard, figures: [], talked: []).first {
            $0.id == "touch-recruit-guard"
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
        XCTAssertEqual(site.markLift, TouchRules.siteTip, "over the heads of who stands there (stage-3-interface)")
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
        var marked = props
        TouchRims.mark(&marked, marks: [mark], night: 0)
        XCTAssertEqual(marked.map { $0.emissive.filter(\.rim).count }, [1, 0, 0],
                       "the brazier under the mark, nothing else (a part of the prop: what stands before it hides it)")
        let rim = try XCTUnwrap(marked[0].emissive.first { $0.rim })
        var pressed = mark
        pressed.pressed = true
        var held = props
        TouchRims.mark(&held, marks: [pressed], night: 0)
        let bright = try XCTUnwrap(held[0].emissive.first { $0.rim })
        XCTAssertGreaterThan(bright.color.x, rim.color.x, "brighter while the finger is down")
        let body = SpeakerBody.court(.petitionerD)
        let figure = DrawnFigure(who: "tamsin", key: "tamsin", body: body, x: 150, y: 0, facing: -1, frame: 2,
                                 alpha: 1, look: nil, petition: nil, talking: false)
        let talk = TouchMark(sprite: .tapTalk, x: 150, lift: 33, pressed: false, poolX: 150, kind: .talk,
                             who: "tamsin", half: 4, footing: nil)
        let person = try XCTUnwrap(TouchRims.world([talk, mark], figures: [figure], night: 1).first)
        XCTAssertEqual(TouchRims.world([talk, mark], figures: [figure], night: 1).count, 1, "people only")
        XCTAssertEqual(person.kind, .rim)
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

    // MARK: - Stage-3-interface: the stage-2 critic's second look

    func testByDayThreeMarksAndBuildingsKeepTheirDistance() {
        let list = [thing("site", kind: .plot, x: 100), thing("tower", kind: .plot, x: 180),
                    thing("tamsin", kind: .talk, x: 120), thing("barracks", kind: .recruit, x: 300),
                    thing("door", kind: .door, x: 520)]
        let marked = TouchRules.marked(list, lordX: 100, viewLeft: 0, viewRight: 700)
        let day = TouchRules.thinned(marked, night: 0).map(\.id)
        XCTAssertFalse(day.contains("tower"), "two building marks closer than 120 px: the farther gives way")
        XCTAssertLessThanOrEqual(day.count, TouchRules.dayMarks, "by day three at most")
        XCTAssertEqual(day.first, "site", "the nearest first")
        let night = TouchRules.thinned(marked, night: 1)
        XCTAssertGreaterThanOrEqual(night.count, day.count, "at night the four of M11")
    }

    func testTheRimIsQuieterByDay() {
        let day = TouchRules.rimColor(pressed: false, night: 0)
        let dusk = TouchRules.rimColor(pressed: false, night: 1)
        XCTAssertEqual(day.x, GamePalette.gold.x * 0.5, accuracy: 0.001, "0.5 by day")
        XCTAssertGreaterThan(TouchRules.rimColor(pressed: true, night: 0).x, day.x)
        XCTAssertLessThan(dusk.z, dusk.x, "warm at night")
    }

    func testAHiddenMarkIsNotDrawnAndTheCartCarriesNoRim() throws {
        var mark = TouchMark(sprite: .tapBuild, x: 100, lift: 22, pressed: false, poolX: 100, kind: .plot)
        let framing = TouchFraming(stage: .world, whole: 0, deviceShift: 0, scale: 6, groundY: 1050,
                                   physicalWidth: 2622, physicalHeight: 1206)
        XCTAssertEqual(TouchMarks.actors([mark], framing: framing, night: 0).count, 1)
        mark.hidden = true
        XCTAssertTrue(TouchMarks.actors([mark], framing: framing, night: 0).isEmpty, "the slip takes its place")
        // Day 3 of seed 2 is one of Marek's days (HallUITests' walk of the castle).
        var s = GameState.newRealm(seed: 2)
        s.day = 3
        s.hour = 10
        s.gold = 1_000
        let barracks = try XCTUnwrap(TouchThings.world(s, balance: .standard, figures: [], talked: []).first {
            $0.id == "touch-recruit-archer"
        })
        // b3-yard (build 3, wave 2, lane 2, step 3): Marek's cart stands by the back gate now, so on his days the
        // barracks keep their rim and their own mark (the cart's cases and `barracksFreeX` went).
        XCTAssertTrue(CourtLayout.props(s, catalog: .standard).contains(where: { $0.sprite == .marekCart }),
                      "day 3 is one of Marek's days")
        XCTAssertFalse(barracks.noRim, "the barracks carry their rim on his days too")
        XCTAssertEqual(barracks.markX, barracks.x, "and their own mark")
    }

    func testTheLiftThrowsSparksNotARing() {
        let early = LanternFlare.sparks(t: 0.05)
        XCTAssertEqual(early.count, 4)
        XCTAssertTrue(early.allSatisfy { $0.dy >= 1 && $0.share > 0.5 })
        let late = LanternFlare.sparks(t: 0.29)
        XCTAssertTrue(late.allSatisfy { $0.dy <= 6 && $0.dy >= 3 }, "they rise 3 to 5 px")
        XCTAssertTrue(LanternFlare.sparks(t: 0.3).isEmpty, "gone after 0.3 s")
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
