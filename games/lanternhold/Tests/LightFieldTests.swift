import XCTest
@testable import Lanternhold

/// The light as a game mechanic (DESIGN.md "Light rules").
final class LightFieldTests: XCTestCase {
    func testFalloffValues() {
        XCTAssertEqual(LightField.falloff(distance: 0, radius: 56), 1)
        XCTAssertEqual(LightField.falloff(distance: 28, radius: 56), 0.25, accuracy: 1e-12)
        XCTAssertEqual(LightField.falloff(distance: 14, radius: 56), 0.5625, accuracy: 1e-12)
        XCTAssertEqual(LightField.falloff(distance: 56, radius: 56), 0)
        XCTAssertEqual(LightField.falloff(distance: 90, radius: 56), 0)
        XCTAssertEqual(LightField.falloff(distance: 0, radius: 0), 0)
    }

    func testDefaultRadiiFromTheDesign() {
        XCTAssertEqual(LightKind.brazier.defaultRadius, 56)
        XCTAssertEqual(LightKind.fireTower.defaultRadius, 90)
        XCTAssertEqual(LightKind.torch.defaultRadius, 30)
        XCTAssertEqual(LightKind.fireArrow.defaultRadius, 22)
        XCTAssertEqual(LightKind.firepot.defaultRadius, 48)
        XCTAssertEqual(LightKind.lantern.defaultRadius, 40)
        XCTAssertEqual(LightKind.hearth.defaultRadius, 70)
        XCTAssertEqual(LightKind.beacon.defaultRadius, Balance.standard.beaconRadius)
    }

    func testLitAtTheThresholdRadius() {
        let torch = LightSource(kind: .torch, x: 100, y: 0)
        let field = LightField(sources: [torch])
        let litRadius = 30 * LightField.litRadiusFraction
        XCTAssertEqual(litRadius, 19.6077, accuracy: 1e-3, "lit within 1 − sqrt(0.12) of the radius")
        XCTAssertEqual(field.illumination(x: 100 + litRadius, y: 0), LightField.litThreshold, accuracy: 1e-9)
        XCTAssertTrue(field.isLit(x: 100 + litRadius - 0.1, y: 0))
        XCTAssertFalse(field.isLit(x: 100 + litRadius + 0.1, y: 0))
        XCTAssertTrue(field.isLit(x: 100 - litRadius + 0.1, y: 0), "both sides")
        XCTAssertFalse(field.isLit(x: 100 - litRadius - 0.1, y: 0))
        XCTAssertFalse(field.isLit(x: 100 + 29, y: 0), "the outer pool is visible but does not count")
        XCTAssertGreaterThan(field.illumination(x: 100 + 29, y: 0), 0)
    }

    func testDistanceIsEllipticSoPoolsSitFlat() {
        let source = LightSource(kind: .torch, x: 100, y: 0)
        let field = LightField(sources: [source])
        XCTAssertEqual(field.illumination(x: 110, y: 0), pow(1 - 10.0 / 30.0, 2), accuracy: 1e-12)
        XCTAssertEqual(field.illumination(x: 100, y: 10), pow(1 - 12.5 / 30.0, 2), accuracy: 1e-12,
                       "vertical distance counts 1.25 times")
        XCTAssertEqual(LightField.distance(dx: 3, dy: 0), 3)
        XCTAssertEqual(LightField.distance(dx: 0, dy: 4), 5)
        XCTAssertGreaterThan(field.illumination(x: 110, y: 0), field.illumination(x: 100, y: 10))
    }

    func testHighestSourceWinsAndLightsDoNotAdd() {
        let left = LightSource(kind: .torch, x: 100, y: 0)
        let right = LightSource(kind: .torch, x: 130, y: 0)
        let field = LightField(sources: [left, right])
        XCTAssertEqual(field.illumination(x: 115, y: 0), 0.25, accuracy: 1e-12, "max, not 0.5")
        let brazier = LightSource(kind: .brazier, x: 115, y: 0)
        let both = LightField(sources: [left, brazier])
        XCTAssertEqual(both.illumination(x: 115, y: 0), 1, accuracy: 1e-12)
        XCTAssertEqual(LightField(sources: []).illumination(x: 0, y: 0), 0)
    }

    func testIntensityAndFlickerDoNotChangeTheGameplayField() {
        let dim = LightSource(kind: .brazier, x: 0, y: 0, intensity: 0.3, flickerSeed: 1)
        let bright = LightSource(kind: .brazier, x: 0, y: 0, intensity: 1.5, flickerSeed: 99)
        XCTAssertEqual(LightField(sources: [dim]).illumination(x: 20, y: 0),
                       LightField(sources: [bright]).illumination(x: 20, y: 0))
    }

    func testWindowsCandlesAndTheMoonLightOnlyTheScene() {
        let scene: [LightSource] = [
            LightSource(kind: .window, x: 50, y: 0),
            LightSource(kind: .candle, x: 50, y: 0),
            LightSource(kind: .moon, x: 50, y: 0),
        ]
        let field = LightField(sources: scene)
        XCTAssertTrue(field.sources.isEmpty)
        XCTAssertEqual(field.illumination(x: 50, y: 0), 0)
        XCTAssertTrue(LightKind.hearth.affectsBattle)
        XCTAssertTrue(LightKind.lantern.affectsBattle)
    }

    func testDarknessBankShrinksLightsInsideIt() {
        let inside = LightSource(kind: .brazier, x: 200, y: 0, radius: 50)
        let bank = DarknessBank(edgeX: 300)
        let open = LightField(sources: [inside])
        let swallowed = LightField(sources: [inside], bank: bank)
        XCTAssertEqual(open.illumination(x: 225, y: 0), 0.25, accuracy: 1e-12)
        XCTAssertEqual(swallowed.effectiveRadius(of: inside), 30, accuracy: 1e-12, "radius × 0.6")
        XCTAssertEqual(swallowed.illumination(x: 225, y: 0), pow(1 - 25.0 / 30.0, 2), accuracy: 1e-12)
        XCTAssertEqual(swallowed.illumination(x: 231, y: 0), 0)

        let outside = LightSource(kind: .brazier, x: 320, y: 0, radius: 50)
        let edgeField = LightField(sources: [outside], bank: bank)
        XCTAssertEqual(edgeField.effectiveRadius(of: outside), 50, "a light outside keeps its radius")
        XCTAssertEqual(edgeField.illumination(x: 295, y: 0), 0.25, accuracy: 1e-12, "and reaches into the bank")

        XCTAssertEqual(swallowed.ambientScale(atX: 100), 0.4)
        XCTAssertEqual(swallowed.ambientScale(atX: 400), 1)
        XCTAssertEqual(open.ambientScale(atX: 100), 1, "no bank, no dimming")
    }

    func testDarknessBankOverTheDayAndNights() {
        XCTAssertEqual(DarknessBank.nightEdge(night: 1), 280)
        XCTAssertEqual(DarknessBank.nightEdge(night: 5), 360)
        XCTAssertEqual(DarknessBank.nightEdge(night: 20), 600, "at most 600")
        let rest = 200.0
        let night = 300.0
        XCTAssertEqual(DarknessBank.edge(hour: 12, restingEdge: rest, nightEdge: night), rest)
        XCTAssertEqual(DarknessBank.edge(hour: 23, restingEdge: rest, nightEdge: night), night)
        XCTAssertEqual(DarknessBank.edge(hour: 2, restingEdge: rest, nightEdge: night), night)
        let swelling = DarknessBank.edge(hour: 19.5, restingEdge: rest, nightEdge: night)
        XCTAssertGreaterThan(swelling, rest)
        XCTAssertLessThan(swelling, 220, "only a small swell at dusk")
        let advancing = DarknessBank.edge(hour: 20.5, restingEdge: rest, nightEdge: night)
        XCTAssertGreaterThan(advancing, swelling)
        XCTAssertLessThan(advancing, night, "the advance takes 20 s (1.67 game hours)")
        XCTAssertEqual(DarknessBank.edge(hour: 20 + 20.0 / 12.0, restingEdge: rest, nightEdge: night), night,
                       accuracy: 1e-9)
        let retreating = DarknessBank.edge(hour: 5.5, restingEdge: rest, nightEdge: night)
        XCTAssertEqual(retreating, 250, accuracy: 1e-9, "first light pushes it back")
    }

    func testPlaceholderCreaturesWaitOutsideTheLightAtNight() {
        let scene = PlaceholderScene.world()
        let field = scene.battleField(hour: 22.8)
        let creatures = scene.actors.filter { $0.kind.isCreature }
        XCTAssertEqual(creatures.count, 6)
        for creature in creatures {
            XCTAssertFalse(field.isLit(x: creature.x, y: creature.litY), "creature at \(creature.x) is unlit")
            XCTAssertFalse(field.bank?.contains(x: creature.x) ?? true, "and outside the darkness bank")
        }
        for brazier in scene.braziers {
            let centre = brazier.x + Double(brazier.width) / 2
            XCTAssertTrue(field.isLit(x: centre, y: 0), "the ground at the brazier is lit")
        }
        XCTAssertTrue(field.isLit(x: scene.king.x, y: scene.king.litY), "the king's lantern lights him")
    }
}
