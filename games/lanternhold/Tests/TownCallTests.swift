import XCTest
@testable import Lanternhold

/// Fix lane D for the review of build 2, player-loop-1: from day 2 every coin waits at the town's doors, far east of
/// the hall, and nothing pointed there. While it is day and a door still owes, the realm strip carries the town's
/// call (the kit's coin and the number of doors that owe, over the town); on the mornings of days 2 and 3 it raises
/// the strip once by itself, from day 4 never; the dawn report says "Never asked at the town's doors" on a day nobody
/// asked at one.
@MainActor
final class TownCallTests: XCTestCase {
    private let balance = Balance.standard

    /// A new realm at the dawn of day 2 (06:00): the lord took the first morning's coins, and the first dawn opened
    /// the ledger, so the cottages owe.
    private func secondMorning() -> GameState {
        var s = GameState.newRealm(seed: 1, balance: balance)
        Town.collectAll(&s, balance: balance)
        s.happiness = 60
        Town.horn(&s, balance: balance)
        s.day = 2
        s.hour = 6
        Economy.dawn(&s, fallen: 0, balance: balance)
        return s
    }

    private func owing(_ s: GameState) -> [TownPlace] {
        (s.town?.today?.places ?? []).filter { $0.owes }
    }

    /// The strip with only the doors calling (no petitioners, no Stranger).
    private func strip(_ s: GameState) -> RealmStrip {
        var strip = RealmStrip.make(s, balance: balance, travelTarget: nil)
        strip.petitioners = 0
        strip.strangerAtGate = false
        return strip
    }

    private var townColumn: Int {
        RealmMapPixels.column(fraction: (RealmStrip.town.lowerBound + RealmStrip.town.upperBound) / 2)
    }

    // MARK: - The call

    func testTheTownCallsWithTheDoorsThatOweUntilTheLastHasPaid() throws {
        var s = secondMorning()
        s.hour = 9
        let doors = owing(s)
        XCTAssertGreaterThan(doors.count, 0, "the doors owe on day 2")
        var strip = strip(s)
        XCTAssertEqual(strip.owingDoors, doors.count)
        XCTAssertEqual(strip.day, 2)
        let tag = try XCTUnwrap(RealmMapPixels.tags(strip).first { $0.sign == .hudCoin }, "the town's tag")
        XCTAssertEqual(tag.count, doors.count, "the number of doors that owe")
        XCTAssertEqual(tag.x, townColumn, "over the town")
        XCTAssertTrue(tag.glyph.isEmpty, "the kit's coin, no new glyph")
        XCTAssertEqual(tag.width, 1 + SpriteID.hudCoin.size.width + 1 + SpriteID.hudFigures.size.width + 1)
        let image = RealmMapPixels.image(strip)
        let column = townColumn
        XCTAssertTrue((0..<RealmMapPixels.tagHeight).contains { y in image[column, y].a > 0 },
                      "the tag is drawn above the town")

        // Beside the petitioners' tag: both stand, moved apart.
        var both = strip
        both.petitioners = 2
        let tags = RealmMapPixels.tags(both)
        XCTAssertEqual(tags.count, 2)
        let lefts = RealmMapPixels.tagLefts(tags)
        XCTAssertLessThan(lefts[0] + tags[0].width, lefts[1], "the tags do not touch")

        // One door pays: one fewer; the last pays: the call goes.
        Town.collect(&s, plot: doors[0].plot, balance: balance)
        strip = self.strip(s)
        XCTAssertEqual(strip.owingDoors, doors.count - 1)
        Town.collectAll(&s, balance: balance)
        strip = self.strip(s)
        XCTAssertEqual(strip.owingDoors, 0, "every door has paid")
        XCTAssertNil(RealmMapPixels.tags(strip).first { $0.sign == .hudCoin })
        XCTAssertEqual(StripCall.doorsDay(strip), 0)
    }

    func testNoTownCallAtNightNorOnTheFirstMorning() {
        var s = secondMorning()
        XCTAssertGreaterThan(owing(s).count, 0)
        for hour in [19.5, 21, 2, 5.5] {
            s.hour = hour
            XCTAssertEqual(RealmStrip.make(s, balance: balance, travelTarget: nil).owingDoors, 0, "none at \(hour)")
        }
        var first = GameState.newRealm(seed: 1, balance: balance)
        first.hour = 9
        XCTAssertGreaterThan(owing(first).count, 0, "the first morning's household owes in the courtyard")
        let strip = RealmStrip.make(first, balance: balance, travelTarget: nil)
        XCTAssertEqual(strip.owingDoors, 0, "day 1's lesson is the courtyard's toss: no tag")
        XCTAssertNil(RealmMapPixels.tags(strip).first { $0.sign == .hudCoin })
    }

    // MARK: - The strip comes by itself on days 2 and 3

    func testTheDoorsRaiseTheStripOnceOnDays2And3AndNeverFromDay4() {
        var s = secondMorning()
        s.hour = 6.2
        let day2 = strip(s)
        XCTAssertEqual(StripCall.size(day2), 0, "the doors are no repeating call")
        var call = StripCall()
        XCTAssertFalse(call.update(day2, hour: 6.0, clock: 0, allowed: false), "under the dawn report it waits")
        XCTAssertFalse(call.update(day2, hour: 6.05, clock: 1, allowed: true, held: true), "under a hint slip too")
        XCTAssertTrue(call.update(day2, hour: 6.1, clock: 2, allowed: true), "the report closed: it comes up")
        XCTAssertTrue(call.update(day2, hour: 6.2, clock: 7, allowed: true))
        XCTAssertFalse(call.update(day2, hour: 6.3, clock: 8.5, allowed: true), "6 s, then away")
        XCTAssertFalse(call.update(day2, hour: 9, clock: 60, allowed: true), "once: not again after 45 s")
        XCTAssertFalse(call.update(day2, hour: 12, clock: 200, allowed: true))

        var day3 = day2
        day3.day = 3
        XCTAssertTrue(call.update(day3, hour: 6.1, clock: 300, allowed: true), "day 3's morning: once more")
        XCTAssertFalse(call.update(day3, hour: 6.5, clock: 310, allowed: true))
        XCTAssertFalse(call.update(day3, hour: 9, clock: 400, allowed: true), "once")

        var day4 = day2
        day4.day = 4
        XCTAssertEqual(StripCall.doorsDay(day4), 0)
        XCTAssertFalse(call.update(day4, hour: 6.1, clock: 500, allowed: true), "day 4: never by itself")
        var fresh = StripCall()
        XCTAssertFalse(fresh.update(day4, hour: 6.1, clock: 0, allowed: true), "day 4: never by itself")
        XCTAssertNotNil(RealmMapPixels.tags(day4).first { $0.sign == .hudCoin }, "its tag still shows in the strip")

        // The last door paid while it stands: it goes at once.
        var paid = StripCall()
        XCTAssertTrue(paid.update(day2, hour: 6.1, clock: 0, allowed: true))
        var none = day2
        none.owingDoors = 0
        XCTAssertFalse(paid.update(none, hour: 6.2, clock: 1, allowed: true), "answered: it goes")

        // The review's should-fix: a petitioners' call answered while the doors still owe goes at once; the doors'
        // own raise does not keep the call's seconds alive.
        var answered = StripCall()
        XCTAssertTrue(answered.update(day2, hour: 6.1, clock: 0, allowed: true), "the doors' raise")
        XCTAssertFalse(answered.update(day2, hour: 7, clock: 10, allowed: true))
        var asking = day2
        asking.petitioners = 1
        XCTAssertTrue(answered.update(asking, hour: 8, clock: 20, allowed: true), "a petitioner calls")
        XCTAssertFalse(answered.update(day2, hour: 8.05, clock: 21, allowed: true), "answered: it goes at once")
    }

    /// The review's should-fix: the doors' pointer reaches VoiceOver too, through the strip's value.
    func testTheStripTellsVoiceOverOfTheDoors() {
        var s = secondMorning()
        s.hour = 6.2
        var owing = strip(s)
        XCTAssertGreaterThan(owing.owingDoors, 0)
        XCTAssertEqual(RealmStripView.callsValue(owing), String(localized: "Doors owing: \(owing.owingDoors)"))
        owing.petitioners = 2
        XCTAssertEqual(RealmStripView.callsValue(owing),
                       String(localized: "Petitioners waiting: \(owing.petitioners)") + ", "
                           + String(localized: "Doors owing: \(owing.owingDoors)"))
        owing.petitioners = 0
        owing.owingDoors = 0
        XCTAssertEqual(RealmStripView.callsValue(owing), "", "nothing calls: no value")
    }

    // MARK: - The dawn report

    func testTheReportSaysWhenNobodyAskedAtTheDoors() {
        let english: (String) -> String = { TownText.string($0, language: "en") ?? $0 }
        let never = TownSummary(day: 2, tossGold: 0, knockGold: 0, kept: 49, spared: [], knockedAt: [], leviedAt: [],
                                doubled: false, unrest: false, happinessGain: 0, happinessCost: 0)
        XCTAssertEqual(TownText.reportLines(never, lookup: english).map(\.key), [TownText.neverAskedKey])
        XCTAssertEqual(TownText.reportDetail(never, lookup: english), "Never asked at the town's doors: 49")
        XCTAssertEqual(TownText.reportLines(never, lookup: { $0 }).map(\.key), ["town.report.kept"],
                       "a language without the new line keeps the old one, never the bare key")

        var asked = never
        asked.tossGold = 11
        asked.kept = 38
        XCTAssertEqual(TownText.reportDetail(asked, lookup: english), "Left to the people: 38", "one door was asked")

        var collector = never
        collector.collectorOut = true
        collector.collectorGold = 0
        collector.collectorWage = 0
        XCTAssertEqual(TownText.reportLines(collector, lookup: english).first?.text, "Left to the people: 49",
                       "the collector asked")

        var firstMorning = never
        firstMorning.day = 1
        firstMorning.kept = 16
        XCTAssertEqual(TownText.reportDetail(firstMorning, lookup: english), "Left to the people: 16",
                       "day 1's coins waited in the courtyard, not at the doors")

        // It fits the report card's line (the 46 characters every town line keeps) with a three-digit sum.
        var long = never
        long.kept = 888
        let line = TownText.reportDetail(long, lookup: english) ?? ""
        XCTAssertFalse(line.contains("%"), line)
        XCTAssertLessThanOrEqual(line.count, 46, line)
    }
}
