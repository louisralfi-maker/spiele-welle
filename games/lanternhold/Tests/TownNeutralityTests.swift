import XCTest
@testable import Lanternhold

/// The taxes went on foot (town-1) without moving the tuning: a bot that collects everything at dawn gets, dawn by dawn,
/// exactly the gold the old dawn sum put into the purse and no happiness change, so the reference runs (T1, T2, T3 with
/// normal tax, T5 to T8) play the same game line for line. Only the low and high bots changed (`TownHabit`); their T3
/// and T4 numbers are reported by `TuningTests`.
final class TownNeutralityTests: XCTestCase {
    private let balance = Balance.standard

    /// At every dawn of a reference run the bot's morning collects exactly the day's taxes (the old dawn sum), changes
    /// no happiness, and nobody is left alone or knocked at.
    func testTheReferenceBotGetsExactlyWhatTheOldDawnGave() throws {
        for seed in 1...2 {
            var s = GameState.newRealm(seed: UInt64(seed), balance: balance)
            var bot = Autoplay.reference()
            var yesterday = balance.town.firstMorningGold
            for night in 1...20 {
                guard let report = Sim.runToDawn(&s, balance: balance, bot: &bot) else {
                    return XCTFail("seed \(seed) fell on night \(night)")
                }
                XCTAssertEqual(report.goldAfter, s.gold, "seed \(seed) night \(night): the dawn adds nothing itself")
                let gold = s.gold
                let happiness = s.happiness
                bot.morning(&s, balance: balance)
                XCTAssertEqual(s.gold - gold, report.taxes.total, "seed \(seed) night \(night): the old dawn sum")
                XCTAssertEqual(s.happiness, happiness, "seed \(seed) night \(night)")
                XCTAssertEqual(s.town?.today?.owing, 0)
                XCTAssertFalse(report.happinessChanges.contains { $0.reason == .leftAlone })
                let town = try XCTUnwrap(report.town, "seed \(seed) night \(night)")
                XCTAssertEqual(town.collected, yesterday,
                               "seed \(seed) night \(night): all of yesterday's taxes (night 1: the first morning's)")
                XCTAssertEqual(town.kept, 0)
                XCTAssertEqual(town.spared, [])
                XCTAssertEqual(town.knockedAt, [])
                XCTAssertEqual(town.happinessGain, 0)
                XCTAssertEqual(town.happinessCost, 0)
                XCTAssertNil(town.collectorOut, "the reference bots never hire the collector")
                yesterday = report.taxes.total
            }
        }
    }

    /// The first morning (town-1 fix round 1) gives back the starting purse of before: 44 in the purse and 16 in the
    /// first household's hands make the old 60, and every bot habit takes them at its first step without a knock, a
    /// house left alone or a change of happiness, so the purse at the first build is what it was.
    func testTheFirstMorningGivesBackTheOldStartingPurse() throws {
        XCTAssertEqual(balance.startGold + balance.town.firstMorningGold, 60, "the realm's 60 gold of before")
        for habit in [TownHabit.collect, .spare, .knock, .levy] {
            var s = GameState.newRealm(seed: 1, balance: balance)
            XCTAssertEqual(s.gold, balance.startGold)
            Town.morning(&s, habit: habit, balance: balance)
            XCTAssertEqual(s.gold, 60, "\(habit)")
            XCTAssertEqual(s.happiness, balance.startHappiness, "\(habit): no knock on the first morning")
            XCTAssertEqual(s.town?.today?.owing, 0, "\(habit)")
            XCTAssertEqual(s.town?.today?.places.map(\.knocks), [0], "\(habit)")
        }
        // Every bot plan: its first step on day 1 brings the coins in before anything is bought.
        for bot in [Autoplay.reference(), Autoplay.reference(tax: .low), Autoplay.reference(tax: .high),
                    Autoplay.buildsNothing] {
            var s = GameState.newRealm(seed: 2, balance: balance)
            var player = bot
            var events: [SimEvent] = []
            player.act(&s, dt: Sim.dayStep, balance: balance, events: &events)
            XCTAssertEqual(s.town?.today?.owing, 0, "its first step took the first morning's coins")
            XCTAssertEqual(s.town?.today?.places.first?.tossGold, balance.town.firstMorningGold)
        }
    }

    /// The reference bot's seed 1, night by night, as the tuning report of round lh-snd-1 (the integration branch before
    /// the taxes went on foot) printed it: the same waves, kills, losses, gold, taxes, happiness, people and buildings.
    /// A deliberate retune changes these lines; then take them from the new round's `tuning-report.txt`.
    func testSeedOnePlaysAsTheRoundBeforeTheTaxesWentOnFoot() {
        let first = TuningRun.play(GameState.newRealm(seed: 1, balance: balance), bot: Autoplay.reference(),
                                   balance: balance, nights: 19)
        let last = TuningRun.play(first.final, bot: Autoplay.reference(), balance: balance, nights: 1)
        let lines = (first.outcomes + last.outcomes).map(TownNeutralityTests.line)
        let attachment = XCTAttachment(string: lines.joined(separator: "\n"))
        attachment.name = "town-neutrality-seed1"
        attachment.lifetime = .keepAlways
        add(attachment)
        XCTAssertEqual(lines.count, TownNeutralityTests.before.count)
        for (now, then) in zip(lines, TownNeutralityTests.before) {
            XCTAssertEqual(now, then)
        }
    }

    /// `TuningRun`'s log line for one night.
    private static func line(_ o: NightOutcome) -> String {
        var line = "night \(o.night): " + (o.survived ? "held" : "FELL")
        line += ", spawned \(o.spawned), killed \(o.killed), dissolved \(o.dissolved), walls lost \(o.wallsLost)"
        line += ", fallen \(o.fallen), hearth \(Int(o.hearthLowest.rounded()))"
        line += ", snuffed \(o.snuffed), patches \(o.patches)"
        line += " | gold \(o.gold), taxes \(o.taxes), happiness \(o.happiness), citizens \(o.citizens)"
        line += ", archers \(o.archers), guards \(o.guards), buildings \(o.buildings)"
        return line
    }

    /// Round lh-snd-1 (on 72b7a99, whose Core is this branch's base), `tuning-report.txt`, "reference bot, seed 1".
    private static let before: [String] = [
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
}
