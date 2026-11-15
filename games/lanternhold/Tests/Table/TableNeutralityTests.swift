import Foundation
import XCTest
@testable import Lanternhold

/// The rule that carries the Lantern Table (docs/QUESTS.md 4): a realm that never sends a lantern plays exactly as it
/// does today. With the table's files loaded, the table uncovered on day 2 and every slip read at every step of every
/// day (offers, blockers, the seal) but nobody sent, the reference bot's chapter is bit for bit the one without: the
/// realm at every dawn is equal and every night's line the same. `testTodaysLineIsUnchanged` also checks the one pinned
/// line (`TableNeutralityLine`, rounds `lh-snd-1` and `lh-snd-2`), so a change to the game itself shows there alone.
final class TableNeutralityTests: XCTestCase {
    /// The line the tuning runs walk today: `TableNeutralityLine.pinned`, the one constant the join re-pins.
    static var todaysLine: [String] { TableNeutralityLine.pinned }

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
            // The town's morning right after the dawn, as `TuningRun.play` plays it (the join with the taxes on foot).
            bot.morning(&s, balance: .standard)
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
        XCTAssertEqual(mine, lines, "the test's loop is Sim.runToDawn's")
    }

    /// With the table's files loaded and read every day, and nobody sent, seed 1 walks the line of the run without
    /// the table, and every dawn is that run's realm (no pinned number: the run without the table is the reference).
    func testWithTheTableLoadedAndNobodySentSeedOneWalksTodaysLine() {
        let catalog = ErrandCatalog.standard
        XCTAssertGreaterThanOrEqual(catalog.errands.count, 3, "the table's files loaded")
        var seen = Set<String>()
        let with = Self.chapter(seed: 1, visit: true, catalog: catalog, seen: &seen)
        var none = Set<String>()
        let without = Self.chapter(seed: 1, visit: false, catalog: catalog, seen: &none)
        attach("table-neutral-seed1", with.map(\.line))
        XCTAssertEqual(with.map(\.line), without.map(\.line), "line for line the run without the table")
        XCTAssertEqual(with.count, 20, "the whole chapter")
        XCTAssertEqual(with.count, without.count)
        for (a, b) in zip(with, without) {
            var plain = a.state
            // The dawn of day 2 comes before the first look at the table that day.
            if plain.day > ErrandEngine.firstDay { XCTAssertNotNil(plain.table, "the table was uncovered on day 2") }
            XCTAssertEqual(plain.table?.sent ?? [], [], "nobody was sent")
            XCTAssertEqual(plain.table?.out ?? [], [], "no party is out")
            plain.table = nil
            XCTAssertTrue(plain == b.state, "day \(b.state.day): the realm is the one without the table")
        }
        XCTAssertTrue(seen.isSuperset(of: ["oil_round", "mill_herbs", "ford_planks", "highcairn_count",
                                           "goldenacre_cart", "stillmere_proof", "greybell_bell", "beaconfoot_smoke",
                                           "beacon_statues"]),
                      "every slip the reference realm's flags open was on the table on its days (\(seen.sorted()))")
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
