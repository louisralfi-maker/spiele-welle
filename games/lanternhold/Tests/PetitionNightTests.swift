import Foundation
import XCTest
@testable import Lanternhold

/// Night modifiers in the battle (M3, `NightModifier`, `NightPlanModifiers`): the ids, fewer creatures of a kind, a
/// smaller or bigger night, fog that brings the darkness bank further, nothing changed without a modifier, a heard
/// petition's `night` effect reaching tonight's plan, spent at dawn.
final class PetitionNightTests: XCTestCase {
    private let balance = Balance.standard

    func testTheIdsParse() {
        XCTAssertEqual(NightModifier(id: "crows-2"), .fewer(.sootCrow, 2))
        XCTAssertEqual(NightModifier(id: "hounds-1"), .fewer(.shadehound, 1))
        XCTAssertEqual(NightModifier(id: "brutes-3"), .fewer(.ashBrute, 3))
        XCTAssertEqual(NightModifier(id: "weavers-1"), .fewer(.gloomweaver, 1))
        XCTAssertEqual(NightModifier(id: "sootlings-9"), .fewer(.sootling, 9))
        XCTAssertEqual(NightModifier(id: "wave-10pct"), .wave(percent: -10))
        XCTAssertEqual(NightModifier(id: "wave+25pct"), .wave(percent: 25))
        XCTAssertEqual(NightModifier(id: "fog"), .fog)
        for bad in ["crows", "crows-0", "crows-10", "crows+1", "wave-60pct", "wave10pct", "wave-pct", "fog2", "giants-1",
                    ""] {
            XCTAssertNil(NightModifier(id: bad), bad)
        }
        let folded = NightPlanModifiers(ids: ["wave-30pct", "wave-30pct", "crows-1", "crows-2", "fog", "nonsense"])
        XCTAssertEqual(folded.budgetScale, 0.5, accuracy: 1e-12, "at most −50 %")
        XCTAssertEqual(folded.fewer[.sootCrow], 3)
        XCTAssertEqual(folded.bankShift, NightPlanModifiers.fogShift)
        XCTAssertEqual(NightPlanModifiers(ids: []), NightPlanModifiers.calm)
    }

    /// A realm on the evening of day `night` with the given modifiers for tonight.
    private func eve(_ night: Int, seed: UInt64 = 9, modifiers: [String]) -> GameState {
        var s = GameState.newRealm(seed: seed, balance: balance)
        s.day = night
        s.hour = 19.99
        if !modifiers.isEmpty {
            var court = CourtState()
            court.nightModifiers = modifiers.map { NightModifierEntry(night: night, id: $0) }
            s.court = court
        }
        return s
    }

    private func planned(_ s: GameState) -> [CreatureKind] {
        var copy = s
        Battle.planNight(&copy, balance: balance)
        return copy.spawns.map(\.kind)
    }

    private func count(_ list: [CreatureKind], _ kind: CreatureKind) -> Int {
        list.filter { $0 == kind }.count
    }

    private func points(_ list: [CreatureKind]) -> Int {
        var total = 0
        for kind in list { total += balance.creature(kind).points }
        return total
    }

    func testFewerCreaturesOfAKind() {
        let plain = planned(eve(9, modifiers: []))
        let fewer = planned(eve(9, modifiers: ["crows-2", "brutes-1"]))
        XCTAssertGreaterThanOrEqual(count(plain, .sootCrow), 2, "night 9 has crows")
        XCTAssertEqual(count(fewer, .sootCrow), count(plain, .sootCrow) - 2)
        XCTAssertEqual(count(fewer, .ashBrute), max(0, count(plain, .ashBrute) - 1))
        XCTAssertEqual(count(fewer, .sootling), count(plain, .sootling))
        XCTAssertEqual(count(fewer, .shadehound), count(plain, .shadehound))
    }

    func testAWaveModifierScalesTheNight() {
        let plain = planned(eve(9, modifiers: []))
        let smaller = planned(eve(9, modifiers: ["wave-20pct"]))
        let bigger = planned(eve(9, modifiers: ["wave+20pct"]))
        XCTAssertLessThan(smaller.count, plain.count)
        XCTAssertGreaterThan(bigger.count, plain.count)
        XCTAssertEqual(Double(points(smaller)), Double(points(plain)) * 0.8, accuracy: 2.5)
        XCTAssertEqual(Double(points(bigger)), Double(points(plain)) * 1.2, accuracy: 2.5)
    }

    func testFogBringsTheDarknessBankFurther() {
        var clear = eve(9, modifiers: [])
        var foggy = eve(9, modifiers: ["fog"])
        clear.hour = 22
        foggy.hour = 22
        let edge = Battle.bankEdge(clear, balance: balance)
        XCTAssertEqual(edge, DarknessBank.nightEdge(night: 9), accuracy: 1e-9)
        XCTAssertEqual(Battle.bankEdge(foggy, balance: balance) - edge, NightPlanModifiers.fogShift, accuracy: 1e-9)
        clear.hour = 12
        foggy.hour = 12
        XCTAssertEqual(Battle.bankEdge(foggy, balance: balance), Battle.bankEdge(clear, balance: balance), accuracy: 1e-9,
                       "by day the bank rests where it always rests")
        var other = eve(9, modifiers: [])
        other.court = CourtState()
        other.court?.nightModifiers = [NightModifierEntry(night: 8, id: "fog")]
        other.hour = 22
        XCTAssertEqual(Battle.bankEdge(other, balance: balance), edge, accuracy: 1e-9, "last night's fog is gone")
    }

    func testWithoutAModifierTheNightIsPlannedAsBefore() {
        var bare = eve(12, modifiers: [])
        var withCourt = bare
        withCourt.court = CourtState()
        withCourt.court?.nightModifiers = [NightModifierEntry(night: 11, id: "crows-3")]
        Battle.planNight(&bare, balance: balance)
        Battle.planNight(&withCourt, balance: balance)
        XCTAssertEqual(bare.spawns, withCourt.spawns)
        XCTAssertEqual(bare.rng, withCourt.rng)
    }

    func testAHeardPetitionsNightEffectReachesTonightAndIsSpentAtDawn() throws {
        let book = PetitionTests.catalog("""
        {"id": "scarecrow", "speaker": "child", "kind": "random", "text": "t",
         "choices": [{"label": "a", "night": ["crows-2"]}, {"label": "b"}]}
        """)
        var plain = GameState.newRealm(seed: 4, balance: balance)
        plain.day = 9
        plain.hour = 10
        PetitionEngine.prepare(&plain, catalog: book)
        XCTAssertEqual(plain.court?.queue.map(\.id), ["scarecrow"])
        var heard = plain
        let outcome = try XCTUnwrap(PetitionEngine.hear(&heard, choice: 0, catalog: book, balance: balance))
        XCTAssertEqual(outcome.night, ["crows-2"])
        var idleA = Autoplay.buildsNothing
        var idleB = Autoplay.buildsNothing
        Sim.run(&plain, untilHour: 20.3, balance: balance, bot: &idleA)
        Sim.run(&heard, untilHour: 20.3, balance: balance, bot: &idleB)
        let crowsPlain = count(plain.spawns.map(\.kind) + plain.creatures.map(\.kind), .sootCrow)
        let crowsHeard = count(heard.spawns.map(\.kind) + heard.creatures.map(\.kind), .sootCrow)
        XCTAssertGreaterThanOrEqual(crowsPlain, 2)
        XCTAssertEqual(crowsHeard, crowsPlain - 2, "the battle honours the petition")
        heard.day = 10
        heard.hour = 6
        PetitionEngine.dawn(&heard)
        XCTAssertEqual(heard.court?.nightModifiers, [], "spent at dawn")
    }
}
