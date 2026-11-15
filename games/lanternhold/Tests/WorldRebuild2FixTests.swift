import Foundation
import XCTest
@testable import Lanternhold

/// World-2 fix round 1 (the critic's look 1 of step world-2, 15.11.2026; DESIGN.md "World rebuild (14.11.2026)"): the
/// keep has light of its own (a bloom round each lit window, a brazier on its wall walk) and mist at its foot over the
/// curtain; the hall door's wedge widens from the door's width to 2.5 times it; the castle's fires are shaped pools in
/// fire-gold; the smoke rises in puffs and stands still with Reduce Motion; the moon stands still on the sky inside the
/// walls and shows only through a wedge, clear of the keep; `-GWCastle` sets the gate's tier too.
final class WorldRebuild2FixTests: XCTestCase {
    private func frame(_ scene: PlaceholderScene, timeOfDay: Double, focus: Double,
                       reduceMotion: Bool = false, time: Double = 2.5) -> FrameDesc {
        var options = FrameOptions(flickerTime: time)
        options.look = .two
        options.reduceMotion = reduceMotion
        var clock = DayClock(timeOfDay: timeOfDay)
        clock.isFrozen = true
        let pixelScale = options.pixelScale(physicalWidth: 2622, physicalHeight: 1206)
        return FrameBuilder.build(scene: scene, clock: clock, camera: Camera(focusX: focus, pixelScale: pixelScale),
                                  pixelScale: pixelScale, options: options)
    }

    private static let keeps: Set<SpriteID> = [.keepT1, .keepT2, .keepT3, .keepT2Build, .keepT3Build]

    func testTheKeepHasLightOfItsOwn() {
        for stage in [CastleStage(tier: 1), CastleStage(tier: 2), CastleStage(tier: 3), CastleStage(tier: 2, building: true),
                      CastleStage(tier: 3, building: true)] {
            let world = PlaceholderScene.world(look: .two, castle: stage)
            guard let keep = world.props.first(where: { WorldRebuild2FixTests.keeps.contains($0.sprite) }) else {
                return XCTFail("\(stage): a keep")
            }
            let twins = keep.masks.filter { $0.width == 7 }
            let halos = keep.emissive.filter { $0.sprite == .keepPaneHalo }
            XCTAssertEqual(halos.count, twins.count, "\(stage): a bloom round every lit twin window")
            XCTAssertTrue(halos.allSatisfy { $0.fadesByDay }, "\(stage): only while the windows are lit")
            let fire = keep.emissive.contains { $0.sprite == .brazierFlame }
            XCTAssertEqual(fire, !stage.building, "\(stage): a brazier on the wall walk, none among the builders")
        }
        // The brazier's light at night, not at noon; it lies on the keep (the near plane's picture).
        let world = PlaceholderScene.world(look: .two, castle: CastleStage(tier: 2))
        XCTAssertTrue(frame(world, timeOfDay: 0.97, focus: 1830).emissives.contains { $0.sprite == .keepFireGlow })
        XCTAssertFalse(frame(world, timeOfDay: 0.5, focus: 1830).emissives.contains { $0.sprite == .keepFireGlow })
        // A world change darkens one window and its bloom with it.
        let dark = CastleRooms.scene(world, state: GameFrameSupport.demoDay(hour: 10).withWorld(["castle.keep.window.dark"]),
                                     rooms: RoomFades(kingX: 1600))
        if let keep = dark.props.first(where: { $0.sprite == .keepT2 }) {
            XCTAssertEqual(keep.emissive.filter { $0.sprite == .keepPaneHalo }.count,
                           keep.masks.filter { $0.width == 7 }.count)
        }
    }

    func testTheMistStandsAtTheKeepsFootOverTheCurtain() {
        let world = PlaceholderScene.world(look: .two)
        guard let mist = world.props.first(where: { $0.sprite == .keepMist }) else { return XCTFail("the keep's mist") }
        XCTAssertEqual(mist.plane, .near)
        XCTAssertEqual(mist.movesWith, .mistBand)
        XCTAssertGreaterThan(mist.y + Double(mist.height), 72 + 4, "its billows stand over the curtain's crenels")
        let night = frame(world, timeOfDay: 0.97, focus: 1830).layer(.near).sprites.first { $0.sprite == .keepMist }
        XCTAssertGreaterThan(night?.tint.w ?? 0, 0.3, "a mist you see at night")
        XCTAssertNil(frame(world, timeOfDay: 0.5, focus: 1830).layer(.near).sprites.first { $0.sprite == .keepMist },
                     "none at noon")
    }

    /// Blocker 2: the wedge of light widens from the door's width at the threshold to about 2.5 times it on the
    /// cobbles, in smooth alpha that stays low enough for the stones to show through.
    func testTheDoorsWedgeWidens() {
        let layout = AtlasLayout.shared
        let cell = layout.cell(.hallDoorWedge, frame: 0)
        func span(_ row: Int) -> Int {
            (0..<cell.width).filter { layout.image[cell.x + $0, cell.y + row].a > 20 }.count
        }
        let top = span(0)
        let bottom = span(cell.height - 1)
        XCTAssertEqual(Double(top), 18, accuracy: 3, "the door's width at the threshold")
        XCTAssertGreaterThanOrEqual(Double(bottom) / Double(top), 2.1, "about 2.5 times it out on the cobbles")
        var peak: UInt8 = 0
        for row in 0..<cell.height {
            for column in 0..<cell.width { peak = max(peak, layout.image[cell.x + column, cell.y + row].a) }
        }
        XCTAssertLessThan(peak, 140, "the stones show through")
    }

    /// High 2: the chapel's fire is a pool on the ground, a cone up the wall and a core, in fire-gold, a third smaller.
    func testTheCastleFiresAreShapedPools() {
        let props = PlaceholderScene.world(look: .two).props
        guard let fire = props.first(where: { $0.sprite == .brazier && abs($0.x - (SceneLayout.castleChapelX + 31)) < 1 })
        else { return XCTFail("the Flame's brazier") }
        XCTAssertEqual(fire.lights.count, 3)
        XCTAssertTrue(fire.lights.contains { ($0.squash ?? 0) > 2 }, "a flat pool on the cobbles")
        XCTAssertTrue(fire.lights.contains { ($0.squash ?? 1.25) < 1 }, "a cone up the wall")
        XCTAssertTrue(fire.lights.allSatisfy { $0.radius <= 37 && $0.color == GamePalette.fireGold })
        let desc = frame(PlaceholderScene.world(look: .two), timeOfDay: 0.97, focus: 2000)
        XCTAssertTrue(desc.lights.contains { $0.ellipseY > 2 }, "the shape reaches the light pass")
    }

    func testTheSmokeRisesInPuffsAndStandsStillWithReduceMotion() {
        let a = CastleSmoke.puffs(time: 1, wind: 0.3, seed: 1245)
        let b = CastleSmoke.puffs(time: 2.5, wind: 0.3, seed: 1245)
        XCTAssertEqual(a.count, CastleSmoke.count)
        XCTAssertNotEqual(a, b, "the puffs rise")
        XCTAssertTrue(a.allSatisfy { $0.rise >= 0 && $0.rise <= CastleSmoke.rise && (0...2).contains($0.frame) })
        let world = PlaceholderScene.world(look: .two)
        func puffs(_ time: Double, _ reduce: Bool) -> [SIMD4<Float>] {
            frame(world, timeOfDay: 0.8, focus: 1830, reduceMotion: reduce, time: time).layer(.near).sprites
                .filter { $0.sprite == .smokePuff }.map(\.rect)
        }
        XCTAssertNotEqual(puffs(2, false), puffs(5, false))
        XCTAssertEqual(puffs(2, true), puffs(5, true), "Reduce Motion: the smoke stands still")
    }

    /// High 10: inside the walls the moon stands still on the screen (factor 0), under the HUD, laid before the cleft's
    /// rock so the rock hides it but in a wedge; where the Throat's wedge passes over it the keep is far to its right.
    func testTheMoonStandsStillOnTheSky() {
        let world = PlaceholderScene.world(look: .two, castle: CastleStage(tier: 3))
        var xs: Set<Float> = []
        for focus in stride(from: 1500.0, through: 2100, by: 50) {
            let desc = frame(world, timeOfDay: 0.97, focus: focus)
            guard let moon = desc.emissives.first(where: { $0.sprite == .moon && $0.kind == .glow }) else {
                return XCTFail("the moon at \(focus)")
            }
            xs.insert(moon.rect.x)
            XCTAssertEqual(moon.plane, .mid, "before the rock: the cleft hides it")
            if (1560...1660).contains(focus) {
                let keep = desc.layer(.near).sprites.first { WorldRebuild2FixTests.keeps.contains($0.sprite) }
                XCTAssertGreaterThan(keep?.rect.x ?? 999, moon.rect.x + moon.rect.z + 50, "clear of the keep at \(focus)")
            }
        }
        XCTAssertEqual(xs.count, 1, "factor 0: the same column at every camera")
    }

    /// High 1: `-GWCastle` sets the gate's tier, so every fixed stage shows a gatehouse a player can reach.
    func testTheCastleArgumentSetsTheGate() {
        let plot = Realm.lines[0].wall
        for (stage, gate) in [("1", BuildItem.gate), ("2", .ironGate), ("2b", .gate), ("3", .greatGate), ("3b", .ironGate)] {
            let args = DebugArgs(values: ["GWReset": "YES", "GWBuild": "demo", "GWCastle": stage])
            let realm = GameStart.realm(args: args, saved: nil)
            XCTAssertEqual(realm.state.plots[plot].item, gate, "-GWCastle \(stage)")
            XCTAssertNil(realm.state.plots[plot].job)
        }
        let free = GameStart.realm(args: DebugArgs(values: ["GWReset": "YES", "GWBuild": "demo"]), saved: nil)
        XCTAssertEqual(free.state.plots[plot].item, .ironGate, "without it the demo build's iron gate stands")
    }
}

private extension GameState {
    func withWorld(_ flags: [String]) -> GameState {
        var s = self
        var court = s.court ?? CourtState()
        court.world = (court.world + flags).sorted()
        s.court = court
        return s
    }
}
