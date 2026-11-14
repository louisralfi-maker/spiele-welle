import Foundation
import XCTest
@testable import Lanternhold

/// The rule that carries the Lantern Table (docs/QUESTS.md 4): a realm that never sends a lantern plays exactly as it
/// does today. With the table's files loaded, the table uncovered on day 2 and every slip read at every step of every
/// day (offers, blockers, the seal) but nobody sent, the reference bot's chapter is bit for bit the one without: the
/// realm at every dawn is equal, and seed 1's nights read line for line what the tuning report printed in rounds
/// `lh-snd-1` and `lh-snd-2` (the integration branch, build 86 plus sound), the line the tuning has held since
/// `lh-m3-j3`'s targets.
final class TableNeutralityTests: XCTestCase {
    /// The tuning report's "reference bot, seed 1" (rounds lh-snd-1 and lh-snd-2, identical): nights 1 to 19 with one
    /// reference bot, night 20 with a fresh one, as `TuningRun.measure` plays it.
    static let todaysLine: [String] = [
        "night 1: held, spawned 25, killed 25, dissolved 0, walls lost 0, fallen 0, hearth 100, snuffed 0, patches 0 | gold 70, taxes 49, happiness 63, citizens 15, archers 3, guards 2, buildings 3",
        "night 2: held, spawned 34, killed 34, dissolved 0, walls lost 0, fallen 0, hearth 100, snuffed 0, patches 0 | gold 91, taxes 61, happiness 67, citizens 16, archers 3, guards 2, buildings 4",
        "night 3: held, spawned 38, killed 38, dissolved 0, walls lost 0, fallen 0, hearth 100, snuffed 0, patches 0 | gold 70, taxes 61, happiness 68, citizens 16, archers 4, guards 2, buildings 7",
        "night 4: held, spawned 45, killed 45, dissolved 0, walls lost 0, fallen 0, hearth 100, snuffed 0, patches 0 | gold 58, taxes 50, happiness 69, citizens 17, archers 6, guards 2, buildings 8",
        "night 5: held, spawned 48, killed 48, dissolved 0, walls lost 0, fallen 0, hearth 100, snuffed 1, patches 0 | gold 95, taxes 62, happiness 71, citizens 18, archers 6, guards 2, buildings 9",
        "night 6: held, spawned 55, killed 55, dissolved 0, walls lost 0, fallen 0, hearth 100, snuffed 1, patches 0 | gold 79, taxes 69, happiness 74, citizens 20, archers 7, guards 2, buildings 9",
        "night 7: held, spawned 49, killed 48, dissolved 1, walls lost 0, fallen 0, hearth 100, snuffed 1, patches 0 | gold 89, taxes 75, happiness 75, citizens 21, archers 7, guards 2, buildings 9",
        "night 8: held, spawned 62, killed 62, dissolved 0, walls lost 0, fallen 0, hearth 100, snuffed 0, patches 0 | gold 111, taxes 77, happiness 79, citizens 23, archers 8, guards 3, buildings 10",
        "night 9: held, spawned 71, killed 70, dissolved 1, walls lost 0, fallen 0, hearth 100, snuffed 0, patches 0 | gold 121, taxes 85, happiness 84, citizens 26, archers 9, guards 3, buildings 10",
        "night 10: held, spawned 61, killed 57, dissolved 4, walls lost 0, fallen 0, hearth 100, snuffed 0, patches 1 | gold 131, taxes 115, happiness 89, citizens 28, archers 9, guards 3, buildings 11",
        "night 11: held, spawned 70, killed 69, dissolved 1, walls lost 0, fallen 0, hearth 100, snuffed 0, patches 0 | gold 213, taxes 132, happiness 93, citizens 28, archers 9, guards 3, buildings 12",
        "night 12: held, spawned 66, killed 60, dissolved 6, walls lost 1, fallen 0, hearth 100, snuffed 2, patches 0 | gold 227, taxes 134, happiness 97, citizens 28, archers 9, guards 3, buildings 13",
        "night 13: held, spawned 64, killed 54, dissolved 10, walls lost 0, fallen 0, hearth 100, snuffed 12, patches 0 | gold 312, taxes 135, happiness 99, citizens 28, archers 9, guards 3, buildings 13",
        "night 14: held, spawned 78, killed 70, dissolved 8, walls lost 1, fallen 0, hearth 100, snuffed 11, patches 0 | gold 236, taxes 139, happiness 100, citizens 28, archers 9, guards 3, buildings 13",
        "night 15: held, spawned 75, killed 66, dissolved 9, walls lost 1, fallen 1, hearth 100, snuffed 0, patches 0 | gold 330, taxes 139, happiness 98, citizens 28, archers 9, guards 2, buildings 13",
        "night 16: held, spawned 79, killed 71, dissolved 8, walls lost 1, fallen 4, hearth 100, snuffed 2, patches 0 | gold 424, taxes 138, happiness 87, citizens 26, archers 6, guards 2, buildings 13",
        "night 17: held, spawned 110, killed 102, dissolved 8, walls lost 2, fallen 1, hearth 100, snuffed 5, patches 0 | gold 127, taxes 127, happiness 83, citizens 27, archers 8, guards 1, buildings 16",
        "night 18: held, spawned 114, killed 106, dissolved 8, walls lost 2, fallen 1, hearth 100, snuffed 13, patches 1 | gold 143, taxes 135, happiness 83, citizens 28, archers 8, guards 1, buildings 17",
        "night 19: held, spawned 112, killed 98, dissolved 14, walls lost 1, fallen 0, hearth 100, snuffed 5, patches 3 | gold 164, taxes 145, happiness 91, citizens 28, archers 8, guards 2, buildings 18",
        "night 20: held, spawned 101, killed 67, dissolved 34, walls lost 1, fallen 2, hearth 100, snuffed 4, patches 1 | gold 161, taxes 117, happiness 86, citizens 28, archers 12, guards 0, buildings 19",
    ]

    /// One dawn of a run: the realm then (or at its fall) and its line in the tuning report's words.
    struct Dawn {
        var state: GameState
        var line: String
    }

    /// The tuning report's line for a night (`TuningRun.logLine`'s words).
    static func line(night: Int, _ s: GameState, taxes: Int) -> String {
        let n = s.night
        var line = "night \(night): " + (s.defeated ? "FELL" : "held")
        line += ", spawned \(n.spawned), killed \(n.killed), dissolved \(n.dissolved), walls lost \(n.wallsLost.count)"
        line += ", fallen \(n.fallen.count), hearth \(Int(n.hearthLowest.rounded()))"
        line += ", snuffed \(n.braziersSnuffed), patches \(n.patches)"
        line += " | gold \(s.gold), taxes \(taxes), happiness \(s.happiness), citizens \(s.citizens)"
        line += ", archers \(s.archerCount), guards \(s.guardCount), buildings \(s.buildingsBuilt)"
        return line
    }

    /// The same words from a `TuningRun` outcome.
    static func line(_ o: NightOutcome) -> String {
        var line = "night \(o.night): " + (o.survived ? "held" : "FELL")
        line += ", spawned \(o.spawned), killed \(o.killed), dissolved \(o.dissolved), walls lost \(o.wallsLost)"
        line += ", fallen \(o.fallen), hearth \(Int(o.hearthLowest.rounded()))"
        line += ", snuffed \(o.snuffed), patches \(o.patches)"
        line += " | gold \(o.gold), taxes \(o.taxes), happiness \(o.happiness), citizens \(o.citizens)"
        line += ", archers \(o.archers), guards \(o.guards), buildings \(o.buildings)"
        return line
    }

    /// Reads the whole table as a player would who looks and never sends: the cloth off, every slip, every order's
    /// blockers and seal. Notes every sending that was offered.
    static func look(_ s: inout GameState, catalog: ErrandCatalog, seen: inout Set<String>) {
        ErrandEngine.uncover(&s, catalog: catalog)
        for errand in ErrandEngine.offers(s, catalog: catalog) {
            seen.insert(errand.id)
            for index in errand.orders.indices {
                _ = ErrandEngine.blockers(errand, order: index, s, catalog: catalog)
                _ = ErrandEngine.sealHolds(errand, order: index, s)
            }
        }
    }

    /// `Sim.runToDawn`'s loop, step for step; with `visit`, the table is read before every step by day.
    static func runToDawn(_ s: inout GameState, bot: inout Autoplay, visit: Bool, catalog: ErrandCatalog,
                          seen: inout Set<String>) -> DawnReport? {
        let balance = Balance.standard
        var events: [SimEvent] = []
        let startDay = s.day
        var steps = 0
        while !s.defeated && steps < 5_000_000 {
            events.removeAll(keepingCapacity: true)
            var dt = Sim.nightStep
            if DayClock.phase(at: s.hour) == .day {
                let toHorn = (19 - s.hour) * DayClock.secondsPerHour
                dt = max(Sim.nightStep, min(Sim.dayStep, toHorn))
                if visit { look(&s, catalog: catalog, seen: &seen) }
            }
            bot.act(&s, dt: dt, balance: balance, events: &events)
            Sim.step(&s, dt: dt, balance: balance, events: &events)
            steps += 1
            if s.day != startDay { return s.lastReport }
        }
        return nil
    }

    /// A seed's chapter as `TuningRun.measure` plays it: nights 1 to 19 with one reference bot, night 20 with a fresh
    /// one.
    static func chapter(seed: UInt64, visit: Bool, catalog: ErrandCatalog = .standard,
                        seen: inout Set<String>) -> [Dawn] {
        var s = GameState.newRealm(seed: seed, balance: .standard)
        var bot = Autoplay.reference()
        var dawns: [Dawn] = []
        for night in 1...20 {
            if night == 20 { bot = Autoplay.reference() }
            let report = runToDawn(&s, bot: &bot, visit: visit, catalog: catalog, seen: &seen)
            dawns.append(Dawn(state: s, line: line(night: night, s, taxes: report?.taxes.total ?? 0)))
            if s.defeated { break }
        }
        return dawns
    }

    private func attach(_ name: String, _ lines: [String]) {
        let attachment = XCTAttachment(string: lines.joined(separator: "\n"))
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// The table's hooks (the dawn step, the field in the realm) leave today's chapter as it was: `TuningRun` and
    /// this test's own loop both walk today's line.
    func testTodaysLineIsUnchanged() {
        let start = GameState.newRealm(seed: 1, balance: .standard)
        let first = TuningRun.play(start, bot: .reference(), balance: .standard, nights: 19)
        let last = TuningRun.play(first.final, bot: .reference(), balance: .standard, nights: 1)
        let lines = (first.outcomes + last.outcomes).map { Self.line($0) }
        attach("table-neutral-tuningrun", lines)
        XCTAssertEqual(lines, Self.todaysLine)
        XCTAssertNil(last.final.table, "the bot never touches the table")
        var seen = Set<String>()
        let mine = Self.chapter(seed: 1, visit: false, seen: &seen).map(\.line)
        XCTAssertEqual(mine, Self.todaysLine, "the test's loop is Sim.runToDawn's")
    }

    /// With the table's files loaded and read every day, and nobody sent, seed 1 walks today's line and every dawn
    /// is the realm of the run without the table.
    func testWithTheTableLoadedAndNobodySentSeedOneWalksTodaysLine() {
        let catalog = ErrandCatalog.standard
        XCTAssertGreaterThanOrEqual(catalog.errands.count, 3, "the table's files loaded")
        var seen = Set<String>()
        let with = Self.chapter(seed: 1, visit: true, catalog: catalog, seen: &seen)
        var none = Set<String>()
        let without = Self.chapter(seed: 1, visit: false, catalog: catalog, seen: &none)
        attach("table-neutral-seed1", with.map(\.line))
        XCTAssertEqual(with.map(\.line), Self.todaysLine)
        XCTAssertEqual(with.count, without.count)
        for (a, b) in zip(with, without) {
            var plain = a.state
            XCTAssertNotNil(plain.table, "the table was uncovered on day 2")
            XCTAssertEqual(plain.table?.sent, [], "nobody was sent")
            plain.table = nil
            XCTAssertTrue(plain == b.state, "day \(b.state.day): the realm is the one without the table")
        }
        XCTAssertTrue(seen.isSuperset(of: ["oil_round", "highcairn_count", "beacon_statues"]),
                      "every slip of round 1 was on the table on its days (\(seen.sorted()))")
    }

    /// The same for the other seeds T1 and T3 count, and one more.
    func testNobodySentChangesNothingOnTheTuningSeeds() {
        for seed in UInt64(2)...UInt64(4) {
            var seen = Set<String>()
            let with = Self.chapter(seed: seed, visit: true, seen: &seen)
            var none = Set<String>()
            let without = Self.chapter(seed: seed, visit: false, seen: &none)
            XCTAssertEqual(with.map(\.line), without.map(\.line), "seed \(seed) line for line")
            for (a, b) in zip(with, without) {
                var plain = a.state
                plain.table = nil
                XCTAssertTrue(plain == b.state, "seed \(seed) day \(b.state.day): the realm is the one without")
            }
            XCTAssertFalse(seen.isEmpty, "seed \(seed): the table offered sendings")
        }
    }
}
