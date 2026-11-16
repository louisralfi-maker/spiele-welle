import CoreGraphics
import Foundation
import XCTest
@testable import Lanternhold

/// The count (build 3, lane 1, step 1; docs/PAY.md sections 1, 2 and 4): a price as hollows (45 is four big and five
/// small, never more than 20), the schedule (the first coin 0.3 s after the touch, the gaps from 0.14 s down to 0.05 s,
/// the last a beat late, the whole count never longer than 1.6 s), the clink's rise (an octave at most), and the
/// rules of PAY.md section 4: letting go before the board is full pays nothing, a full count pays once and only once, a
/// price above the gold never pays, a count cut off (a card, the horn, the background) pays nothing. Then the board's
/// layout, what is bought by a count, the Debug freeze, and the count through the game's model.
@MainActor
final class PayCountTests: XCTestCase {
    private let step = 1.0 / 60

    /// Steps `count` for `seconds` with `gold` in the treasury; every beat in order.
    private func run(_ count: inout PayCount, seconds: Double, gold: Int) -> [PayBeat] {
        var beats: [PayBeat] = []
        var left = seconds
        while left > 1e-9 {
            beats += count.step(step, gold: gold)
            left -= step
        }
        return beats
    }

    private func seals(_ beats: [PayBeat]) -> Int { beats.filter { $0 == .seal }.count }
    private func coins(_ beats: [PayBeat]) -> Int {
        beats.filter { if case .coin = $0 { return true } else { return false } }.count
    }

    // MARK: - The price as hollows

    func testAPriceBecomesHollowsTheBiggestFirst() {
        XCTAssertEqual(PayCount.hollows(price: 45), [.big, .big, .big, .big, .small, .small, .small, .small, .small],
                       "45 is four big and five small")
        XCTAssertEqual(PayCount.hollows(price: 12), [.big, .small, .small])
        XCTAssertEqual(PayCount.hollows(price: 10), [.big], "a repair is one big coin")
        XCTAssertEqual(PayCount.hollows(price: 330), [.bar, .bar, .bar, .big, .big, .big], "a bar counts a hundred")
        XCTAssertEqual(PayCount.hollows(price: 0), [])
        for price in 1...999 {
            let coins = PayCount.hollows(price: price)
            XCTAssertLessThanOrEqual(coins.count, PayCount.maxHollows, "\(price)")
            XCTAssertFalse(coins.isEmpty, "\(price)")
            if coins.count < PayCount.maxHollows {
                XCTAssertEqual(coins.reduce(0) { $0 + $1.value }, price, "\(price) in full")
            }
        }
        // Every price the game asks fits in full.
        for item in BuildItem.allCases {
            let price = Balance.standard.price(item)
            XCTAssertEqual(PayCount.hollows(price: price).reduce(0) { $0 + $1.value }, price, "\(item)")
        }
    }

    // MARK: - The schedule

    func testTheCountIsNeverLongerThanItsSecondAndAHalf() {
        for count in 1...PayCount.maxHollows {
            let times = PayCount.landings(count: count)
            XCTAssertEqual(times.count, count)
            XCTAssertLessThanOrEqual(times.last ?? 0, PayCount.longest + 1e-9, "\(count) coins")
            XCTAssertEqual(times.first ?? 0, count == 1 ? PayCount.firstCoin + PayCount.lastBeat : PayCount.firstCoin,
                           accuracy: 1e-9, "the first coin 0.3 s after the touch")
            guard count > 1 else { continue }
            for index in 1..<count {
                let gap = PayCount.gap(before: index, count: count) - (index == count - 1 ? PayCount.lastBeat : 0)
                XCTAssertGreaterThanOrEqual(gap, PayCount.gapEnd - 1e-9, "\(count) coins, gap \(index)")
                XCTAssertLessThanOrEqual(gap, PayCount.gapStart + 1e-9, "\(count) coins, gap \(index)")
                if index >= 2 && index < count - 1 {
                    XCTAssertLessThanOrEqual(PayCount.gap(before: index, count: count),
                                             PayCount.gap(before: index - 1, count: count) + 1e-9, "it gets faster")
                }
            }
            XCTAssertGreaterThanOrEqual(PayCount.gap(before: count - 1, count: count), PayCount.lastBeat,
                                        "the last coin a beat late")
        }
        XCTAssertEqual(PayCount.gap(before: 1, count: 9), PayCount.gapStart, accuracy: 1e-9, "it starts slowly")
    }

    func testTheClinkRisesAtMostAnOctaveAndTheTickGrows() {
        for count in [1, 3, 9, 20] {
            var last = 0.0
            for index in 0..<count {
                let rate = PayCount.rate(index: index, count: count)
                XCTAssertGreaterThanOrEqual(rate, last, "each a little higher")
                XCTAssertLessThanOrEqual(rate, 2 + 1e-9, "an octave at most")
                last = rate
            }
            XCTAssertEqual(PayCount.rate(index: 0, count: count), 1, accuracy: 1e-9)
            XCTAssertLessThanOrEqual(PayCount.strength(index: 0, count: count),
                                     PayCount.strength(index: count - 1, count: count))
        }
        XCTAssertGreaterThan(PayCount.rate(index: 1, count: 9), 1, "the second coin is higher")
    }

    /// Step 2 (the critic's H4): the rising clink is thirteen files, each a semitone over the last (a player's rate
    /// only stretches time), all in the app (step 0 is the coin itself, `coin.wav`); their zero-crossing rate rises
    /// from step to step, and the count's rates pick them in order.
    func testTheRisingClinkIsThirteenFilesThatRise() throws {
        XCTAssertEqual(SoundID.coinSteps.count, 13)
        var last = 0.0
        for (k, id) in SoundID.coinSteps.enumerated() {
            XCTAssertEqual(id.rawValue, k == 0 ? "coin" : String(format: "coin_p%02d", k))
            let url = Bundle.main.url(forResource: id.rawValue, withExtension: "wav", subdirectory: "Sound")
                ?? Bundle.main.url(forResource: id.rawValue, withExtension: "wav")
            let data = try Data(contentsOf: try XCTUnwrap(url, "\(id.rawValue).wav is in the app"))
            let samples = PayCountTests.samples(data)
            XCTAssertGreaterThan(samples.count, 1000, id.rawValue)
            guard samples.count > 1 else { continue }
            var crossings = 0
            for i in 1..<samples.count where (samples[i - 1] < 0) != (samples[i] < 0) { crossings += 1 }
            let rate = Double(crossings) / (Double(samples.count) / 22050)
            XCTAssertGreaterThan(rate, last, "\(id.rawValue) rings higher than the step before")
            last = rate
        }
        XCTAssertEqual(SoundID.coinStep(rate: 1), .coin)
        XCTAssertEqual(SoundID.coinStep(rate: 2), .coinP12)
        XCTAssertEqual(SoundID.coinStep(rate: pow(2, 5.0 / 12)), .coinP05)
        XCTAssertEqual(SoundID.coinStep(rate: 4), .coinP12, "never past the octave")
        XCTAssertEqual(SoundID.coinStep(rate: 0.5), .coin)
        let steps = (0..<9).map { SoundID.coinStep(rate: PayCount.rate(index: $0, count: 9)) }
        XCTAssertEqual(Set(steps).count, 9, "nine coins, nine steps up")
        XCTAssertEqual(steps.first, .coin)
    }

    /// The 16-bit mono samples of a WAV file's data chunk.
    private static func samples(_ data: Data) -> [Int16] {
        let bytes = [UInt8](data)
        var pos = 12
        while pos + 8 <= bytes.count {
            let id = String(decoding: bytes[pos..<pos + 4], as: UTF8.self)
            let size = Int(bytes[pos + 4]) | Int(bytes[pos + 5]) << 8 | Int(bytes[pos + 6]) << 16
                | Int(bytes[pos + 7]) << 24
            if id == "data" {
                let end = min(bytes.count, pos + 8 + size)
                var out: [Int16] = []
                out.reserveCapacity(max(0, (end - pos - 8) / 2))
                var i = pos + 8
                while i + 1 < end {
                    out.append(Int16(bitPattern: UInt16(bytes[i]) | UInt16(bytes[i + 1]) << 8))
                    i += 2
                }
                return out
            }
            pos += 8 + size + (size & 1)
        }
        return []
    }

    // MARK: - PAY.md section 4

    func testAFullCountPaysOnceAndOnlyOnce() {
        var count = PayCount(thing: "t", offer: .patch(plot: 0), price: 45, holding: true)
        count.arrive()
        let beats = run(&count, seconds: 2.0, gold: 100)
        XCTAssertEqual(coins(beats), 9, "every coin seen on its own")
        XCTAssertEqual(seals(beats), 1, "one seal")
        XCTAssertEqual(count.result, .paid)
        XCTAssertLessThanOrEqual(count.landed.last ?? 9, PayCount.longest + step + 1e-9, "within 1.6 s")
        XCTAssertEqual(count.heldValue, 0, "the treasury paid it: the purse holds nothing back")
        let later = run(&count, seconds: 3, gold: 100)
        XCTAssertEqual(seals(later), 0, "and never again")
        count.press()
        count.tap()
        count.cut()
        XCTAssertEqual(seals(run(&count, seconds: 1, gold: 100)), 0)
        XCTAssertEqual(count.result, .paid, "a cut after the seal changes nothing")
        XCTAssertTrue(count.isGone, "the board went down")
        XCTAssertEqual(later.filter { $0 == .gone }.count, 1)
    }

    func testLettingGoBeforeTheBoardIsFullPaysNothing() {
        var count = PayCount(thing: "t", offer: .patch(plot: 0), price: 45, holding: true)
        count.arrive()
        var beats = run(&count, seconds: 0.5, gold: 100)
        XCTAssertGreaterThan(count.placed, 0)
        XCTAssertLessThan(count.placed, 9)
        XCTAssertEqual(count.heldValue, count.placedValue, "the coins on the board are held back from the purse")
        count.lift(tap: false)
        beats += run(&count, seconds: 1.9, gold: 100)
        XCTAssertTrue(count.isOpen, "the board waits two seconds for the finger")
        beats += run(&count, seconds: 1.5, gold: 100)
        XCTAssertEqual(seals(beats), 0, "nothing paid")
        XCTAssertEqual(count.result, .letGo)
        XCTAssertTrue(beats.contains(.slideBack), "the coins slide back")
        XCTAssertEqual(count.heldValue, 0)
        XCTAssertTrue(count.isGone)
    }

    func testAPriceAboveTheGoldNeverPays() {
        var count = PayCount(thing: "t", offer: .patch(plot: 0), price: 45, holding: true)
        count.arrive()
        let beats = run(&count, seconds: 3, gold: 30)
        XCTAssertEqual(seals(beats), 0)
        XCTAssertEqual(count.result, .short, "the count stops when the purse is empty")
        XCTAssertEqual(count.placed, 3, "three big coins of 30, the fourth missing")
        XCTAssertTrue(beats.contains(.short))
        XCTAssertTrue(beats.contains(.slideBack), "then the coins go back")
        if let short = beats.firstIndex(of: .short), let back = beats.firstIndex(of: .slideBack) {
            XCTAssertLessThan(short, back, "the empty hollows blink first")
        }
        var poor = PayCount(thing: "t", offer: .patch(plot: 0), price: 10, holding: true)
        poor.arrive()
        XCTAssertEqual(seals(run(&poor, seconds: 3, gold: 9)), 0)
        XCTAssertEqual(poor.placed, 0)
    }

    func testACountCutOffPaysNothing() {
        var count = PayCount(thing: "t", offer: .patch(plot: 0), price: 45, holding: true)
        count.arrive()
        var beats = run(&count, seconds: 0.6, gold: 100)
        count.cut()
        beats += run(&count, seconds: 3, gold: 100)
        XCTAssertEqual(seals(beats), 0)
        XCTAssertEqual(count.result, .cutOff)
        // Cut between the last coin and the seal: still nothing.
        var late = PayCount(thing: "t", offer: .patch(plot: 0), price: 12, holding: true)
        late.arrive()
        var lateBeats: [PayBeat] = []
        while !late.isFull { lateBeats += late.step(step, gold: 100) }
        XCTAssertEqual(seals(lateBeats), 0, "the seal falls a moment after the last coin")
        late.cut()
        XCTAssertEqual(seals(run(&late, seconds: 2, gold: 100)), 0)
        XCTAssertEqual(late.result, .cutOff)
    }

    func testATapSetsOneCoinAndTapsAndHoldsMix() {
        var count = PayCount(thing: "t", offer: .patch(plot: 0), price: 45, holding: false)
        count.arrive()
        _ = run(&count, seconds: 0.5, gold: 100)
        XCTAssertEqual(count.placed, 0, "the first touch brings the board, no coin")
        count.tap()
        // Step 2: the coin flies from his hand and lands a flight later.
        _ = run(&count, seconds: 0.2, gold: 100)
        XCTAssertEqual(count.placed, 1, "a tap sets one coin")
        count.tap()
        count.tap()
        _ = run(&count, seconds: 0.3, gold: 100)
        XCTAssertEqual(count.placed, 3, "every tap one coin")
        // A quick press that set no coin is a tap.
        count.press()
        count.lift(tap: true)
        _ = run(&count, seconds: 0.2, gold: 100)
        XCTAssertEqual(count.placed, 4)
        // A hold goes on from there.
        count.press()
        let beats = run(&count, seconds: 2, gold: 100)
        XCTAssertEqual(count.result, .paid)
        XCTAssertEqual(seals(beats), 1)
    }

    func testTheCoinsWaitForTheLord() {
        var count = PayCount(thing: "t", offer: .patch(plot: 0), price: 30, holding: true)
        _ = run(&count, seconds: 3, gold: 100)
        XCTAssertEqual(count.placed, 0, "he still walks to the board")
        XCTAssertTrue(count.isOpen, "and the board waits for him")
        count.arrive()
        let beats = run(&count, seconds: 2, gold: 100)
        XCTAssertEqual(seals(beats), 1, "the hold counts once he stands there")
        var atOnce = PayCount(thing: "t", offer: .patch(plot: 0), price: 45, holding: false)
        atOnce.payAtOnce()
        atOnce.arrive()
        // Step 3 (the director's call 3): the last coin's beat holds for VoiceOver too, so the seal falls
        // `sealDelay` after the coins (all of them on the first step).
        XCTAssertEqual(seals(run(&atOnce, seconds: PayCount.sealDelay + 0.1, gold: 100)), 1,
                       "VoiceOver pays in one step")
    }

    func testTheBoardRisesAndTheCoinsSlideInTheirTime() {
        var count = PayCount(thing: "t", offer: .patch(plot: 0), price: 20, holding: false)
        XCTAssertEqual(count.riseShare, 0)
        _ = run(&count, seconds: PayCount.boardDelay + 0.01, gold: 100)
        XCTAssertEqual(count.riseShare, 1, "up 0.15 s after the touch")
        count.arrive()
        count.tap()
        _ = run(&count, seconds: 0.2, gold: 100)
        XCTAssertEqual(count.placed, 1)
        XCTAssertNil(count.slideShare, "the coin lies on the board")
        var beats: [PayBeat] = []
        while !beats.contains(.slideBack) { beats += count.step(step, gold: 100) }
        XCTAssertEqual(count.result, .letGo, "two seconds without a touch")
        XCTAssertEqual(count.slideShare ?? -1, 0, accuracy: 0.1, "the slide starts")
        _ = run(&count, seconds: PayCount.slideSeconds + step, gold: 100)
        XCTAssertEqual(count.slideShare ?? 0, 1, accuracy: 1e-9, "one coin home in its flight")
    }

    // MARK: - Step 2: the flight, the waits, the way home

    /// The critic's blocker: every coin leaves the lord's hand a flight before its moment and lands on it, so the
    /// schedule of PAY.md section 2 stands; never more than two coins in the air, even on the longest board.
    func testACoinFliesFromTheHandAndLandsOnItsMoment() throws {
        // Step 3 (the director's call 1): the far hollows fly up to 0.16 s; the flights are cut so the landings stay.
        for (price, flights) in [(90, [Double]()), (199, []), (90, Array(repeating: PayCount.flightFar, count: 20)),
                                 (199, Array(repeating: PayCount.flightFar, count: 20))] {
            var count = PayCount(thing: "t", offer: .patch(plot: 0), price: price, holding: true, flights: flights)
            count.arrive()
            let n = count.coins.count
            let landings = PayCount.landings(count: n)
            var beats: [PayBeat] = []
            var sawInAir = false
            var most = 0
            while count.result == nil && count.time < 3 {
                beats += count.step(step, gold: 500)
                most = max(most, count.inFlight)
                if count.placed == 0, let share = count.flightShare(0), share > 0, share < 1 { sawInAir = true }
            }
            XCTAssertTrue(sawInAir, "\(price): the first coin is seen in the air")
            XCTAssertEqual(count.launched.count, n)
            XCTAssertEqual(count.landed.count, n)
            for index in 0..<min(n, count.landed.count) {
                let flight = try XCTUnwrap(count.flightSeconds(index))
                XCTAssertEqual(count.launched[index] + flight, landings[index], accuracy: 1e-6,
                               "\(price): coin \(index) leaves his hand a flight before its moment")
                XCTAssertLessThanOrEqual(flight, count.plannedFlight(index) + 1e-9, "never longer than planned")
                XCTAssertGreaterThanOrEqual(flight, PayCount.flightShortest - 1e-9)
                XCTAssertEqual(count.landed[index], landings[index], accuracy: 1e-6, "\(price): and lands on it")
            }
            if !flights.isEmpty {
                XCTAssertEqual(count.flightSeconds(0) ?? 0, PayCount.flightFar, accuracy: 1e-6,
                               "the first far coin flies its whole flight")
            }
            XCTAssertLessThanOrEqual(most, 2, "\(price): at most two coins in the air")
            XCTAssertEqual(coins(beats), n, "a clink for every landing")
            XCTAssertEqual(count.result, .paid)
        }
        XCTAssertGreaterThanOrEqual(PayCount.flight, 0.11, "the near one")
        XCTAssertLessThanOrEqual(PayCount.flightFar, 0.16, "the far one")
    }

    /// Step 3 (the director's call 1): quick taps never put a third coin in the air, and a tapped coin never lands
    /// before the one ahead of it.
    func testTapsKeepTwoCoinsInTheAirAtMost() {
        var count = PayCount(thing: "t", offer: .patch(plot: 0), price: 90, holding: false,
                             flights: [0.16, 0.11, 0.16, 0.11, 0.16, 0.11, 0.16, 0.11, 0.16])
        count.arrive()
        _ = run(&count, seconds: 0.4, gold: 500)
        for _ in 0..<9 { count.tap() }
        var most = 0
        while count.result == nil && count.time < 4 {
            _ = count.step(step, gold: 500)
            most = max(most, count.inFlight)
        }
        XCTAssertLessThanOrEqual(most, 2, "at most two in the air")
        XCTAssertEqual(count.result, .paid)
        XCTAssertEqual(count.landed, count.landed.sorted(), "each lands after the one ahead of it")
    }

    /// Step 3 (the director's call 1): the throw goes up and falls in. At mid-flight the coin is over both the hand and
    /// the hollow; by 70 % of the way it is over its hollow and still high, so the rest is a drop; the far hollow flies
    /// longer than the near one. Step 4 (call 1): it turns half, face, half with the face at the peak, never the edge,
    /// the odd coins in their own phase; the peak never stands lower than its clearance over the board.
    func testTheThrowGoesUpAndFallsIn() throws {
        let mid = GameModel.countThrow(0.5, fromX: 0, fromLift: 31, toX: 40, toLift: 22, coinHeight: 11)
        XCTAssertGreaterThan(mid.lift, 31 + 8, "at mid-flight over the hand")
        XCTAssertGreaterThan(mid.lift, 22 + 8, "and over the hollow")
        let late = GameModel.countThrow(0.7, fromX: 0, fromLift: 31, toX: 40, toLift: 22, coinHeight: 11)
        XCTAssertEqual(late.x, 40, accuracy: 1e-9, "over its hollow by 70 % of the way")
        XCTAssertGreaterThan(late.lift, 22 + 8, "still high over it: the last 30 % is the drop")
        let end = GameModel.countThrow(1, fromX: 0, fromLift: 31, toX: 40, toLift: 22, coinHeight: 11)
        XCTAssertEqual(end.lift, 22, accuracy: 1e-9)
        XCTAssertEqual(end.x, 40, accuracy: 1e-9)
        let even = stride(from: 0.0, to: 1.0, by: 0.05).map { GameModel.countSpin($0, index: 0, face: 1) }
        let odd = stride(from: 0.0, to: 1.0, by: 0.05).map { GameModel.countSpin($0, index: 1, face: 1) }
        XCTAssertEqual(even.first, 4, "a coin leaves half turned")
        XCTAssertEqual(even.last, 4, "and comes down half turned")
        XCTAssertFalse(even.contains(3) || odd.contains(3), "never the edge: the half turn is the narrowest frame")
        XCTAssertTrue(even.contains(1) && odd.contains(1), "half, face, half")
        XCTAssertNotEqual(even, odd, "two in the air never spin in step")
        for index in 0..<6 {
            XCTAssertEqual(GameModel.countSpin(0.45, index: index, face: 2), 2, "coin \(index): the face at the peak")
        }
        let high = GameModel.countThrow(0.45, fromX: 0, fromLift: 31, toX: 40, toLift: 22, coinHeight: 11, clear: 60)
        XCTAssertEqual(high.lift, 60, accuracy: 1e-9, "the peak never under its clearance over the board")
        XCTAssertEqual(GameModel.countPeakClear(boardTop: 32, coinHeight: 11), 47, "its whole rect 4 px over the top")

        let game = gateGame(gold: 200)
        let gate = try XCTUnwrap(game.touch.things.first { $0.id == "touch-plot-0" })
        game.touchThing(gate)
        let board = try XCTUnwrap(game.touch.countBoard)
        let flights = try XCTUnwrap(game.touch.count?.flights)
        XCTAssertEqual(flights.count, board.layout.hollows.count)
        XCTAssertTrue(flights.allSatisfy { $0 >= PayCount.flight - 1e-9 && $0 <= PayCount.flightFar + 1e-9 })
        let toward: Double = board.x >= board.stand ? 1 : -1
        let near = flights.indices.min { toward * Double(board.layout.hollows[$0].x)
            < toward * Double(board.layout.hollows[$1].x) } ?? 0
        let far = flights.indices.max { toward * Double(board.layout.hollows[$0].x)
            < toward * Double(board.layout.hollows[$1].x) } ?? 0
        XCTAssertGreaterThan(flights[far], flights[near], "the far hollow flies longer")
    }

    #if DEBUG
    /// Step 3 (the director's call 1), on the drawn frame: coin 3 thrown to hollow 3 passes over coins 1 and 2 lying in
    /// their hollows, never along the board's face.
    func testTheThirdCoinPassesOverTheFirstTwo() throws {
        let game = model(["GWStage": "world", "GWSeed": "2", "GWDay": "3", "GWClock": "10", "GWCameraX": "1240",
                          "GWGold": "200", "GWCountFreeze": "fly:2:0.4"])
        _ = game.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
        let gate = try XCTUnwrap(game.touch.things.first { $0.id == "touch-plot-0" })
        game.touchThing(gate)
        run(game, seconds: 10) { game.touch.count?.ready == true }
        var count = try XCTUnwrap(game.touch.count)
        count.press()
        game.touch.count = count
        let freeze = PayFreeze.flight(coin: 2, share: 0.4)
        run(game, seconds: 3) { game.touch.count.map { freeze.holds($0) } == true }
        let live = try XCTUnwrap(game.touch.count)
        XCTAssertTrue(freeze.holds(live), "frozen with coin 3 in the air")
        XCTAssertGreaterThanOrEqual(live.placed, 2, "coins 1 and 2 lie in their hollows")
        let frame = game.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
        let board = try XCTUnwrap(game.touch.countBoard)
        XCTAssertLessThan(board.side, 0, "the gate's board stands left of it, the lord on its outer side: the hollows "
                          + "fill from his side, so each coin flies over the ones already laid")
        let framing = try XCTUnwrap(game.touch.framing)
        let laid = board.layout.hollows.prefix(2)
        let laidTop = laid.map { framing.deviceY(lift: board.top - Double($0.y)) }.min() ?? 0
        let spanA = laid.map { framing.deviceX(stageX: Double(board.left + $0.x)) }.min() ?? 0
        let spanB = laid.map { framing.deviceX(stageX: Double(board.left + $0.x + $0.coin.hollow.size.width)) }
            .max() ?? 0
        let over = frame.actors.filter { actor in
            guard actor.sprite == .hudCoinTen else { return false }
            let bottom = Double(actor.rect.y + actor.rect.w)
            let left = Double(actor.rect.x)
            let right = Double(actor.rect.x + actor.rect.z)
            return bottom <= laidTop + 1 && right > spanA && left < spanB
        }
        XCTAssertFalse(over.isEmpty, "coin 3 is drawn over coins 1 and 2, clear of them")
    }
    #endif

    #if DEBUG
    /// Step 4 (the director's call 1), on the drawn frame: coin 3 of a hold frozen at 45 % of its throw shows its face,
    /// and its whole rect stands at least 4 px over the board's top, so it covers neither a landed coin nor a plank.
    func testTheCoinShowsItsFaceAtThePeakAboveTheBoard() throws {
        let game = model(["GWStage": "world", "GWSeed": "2", "GWDay": "3", "GWClock": "10", "GWCameraX": "1240",
                          "GWGold": "200", "GWCountFreeze": "fly:2:0.45"])
        _ = game.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
        let gate = try XCTUnwrap(game.touch.things.first { $0.id == "touch-plot-0" })
        game.touchThing(gate)
        run(game, seconds: 10) { game.touch.count?.ready == true }
        var count = try XCTUnwrap(game.touch.count)
        count.press()
        game.touch.count = count
        let freeze = PayFreeze.flight(coin: 2, share: 0.45)
        run(game, seconds: 3) { game.touch.count.map { freeze.holds($0) } == true }
        let live = try XCTUnwrap(game.touch.count)
        XCTAssertTrue(freeze.holds(live), "frozen with coin 3 at its peak")
        let frame = game.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
        let board = try XCTUnwrap(game.touch.countBoard)
        let framing = try XCTUnwrap(game.touch.framing)
        let clearLine = framing.deviceY(lift: board.top + 4) + 0.5
        let peak = frame.actors.filter { actor in
            actor.sprite == .hudCoinTen && Double(actor.rect.y + actor.rect.w) <= clearLine
        }
        XCTAssertFalse(peak.isEmpty, "coin 3 stands with its whole rect 4 px over the board's top")
        XCTAssertTrue(peak.allSatisfy { $0.frame < 3 }, "showing its face, never the edge or the half turn")
    }
    #endif

    /// A tap: the coin leaves his hand at once and lands a flight later; the clink comes at the landing.
    func testATapLeavesAtOnceAndLandsAFlightLater() {
        var count = PayCount(thing: "t", offer: .patch(plot: 0), price: 45, holding: false)
        count.arrive()
        _ = run(&count, seconds: 0.5, gold: 100)
        count.tap()
        let tapped = count.time
        var beats = count.step(step, gold: 100)
        XCTAssertEqual(count.launched.count, 1, "the tapped coin leaves his hand at once")
        XCTAssertEqual(count.placed, 0, "it is in the air")
        XCTAssertEqual(coins(beats), 0, "no clink yet")
        beats += run(&count, seconds: PayCount.flight - 2 * step, gold: 100)
        XCTAssertEqual(count.placed, 0, "still in the air")
        beats += run(&count, seconds: 3 * step, gold: 100)
        XCTAssertEqual(count.placed, 1, "it lands a flight later")
        XCTAssertEqual(coins(beats), 1, "the clink at the landing")
        XCTAssertEqual(count.launched.first ?? 0, tapped + step, accuracy: 1e-9)
        XCTAssertEqual((count.landed.first ?? 0) - (count.launched.first ?? 0), PayCount.flight, accuracy: 1e-6)
    }

    /// The critic's H5: an empty board waits five seconds for the finger (the rocking coin is the lesson); once a
    /// coin lies on it, two.
    func testAnEmptyBoardWaitsFiveSecondsAndALaidCoinTwo() {
        var empty = PayCount(thing: "t", offer: .patch(plot: 0), price: 45, holding: false)
        empty.arrive()
        _ = run(&empty, seconds: PayCount.emptyWait - 0.2, gold: 100)
        XCTAssertTrue(empty.isOpen, "an empty board waits five seconds")
        _ = run(&empty, seconds: 0.4, gold: 100)
        XCTAssertEqual(empty.result, .letGo)
        var laid = PayCount(thing: "t", offer: .patch(plot: 0), price: 45, holding: false)
        laid.arrive()
        laid.tap()
        _ = run(&laid, seconds: 0.3, gold: 100)
        XCTAssertEqual(laid.placed, 1)
        _ = run(&laid, seconds: PayCount.slideAfter - 0.3, gold: 100)
        XCTAssertTrue(laid.isOpen, "a coin on the board: it waits two seconds after it")
        _ = run(&laid, seconds: 0.5, gold: 100)
        XCTAssertEqual(laid.result, .letGo)
    }

    /// The critic's H5: let go, the coins come home one by one, the last laid first, `homeGap` apart, and the purse
    /// takes each as it arrives (`heldValue` counts the coins not yet home).
    func testTheCoinsComeHomeOneByOneTheLastFirst() {
        var count = PayCount(thing: "t", offer: .patch(plot: 0), price: 45, holding: false)
        count.arrive()
        for _ in 0..<4 { count.tap() }
        _ = run(&count, seconds: 0.5, gold: 100)
        XCTAssertEqual(count.placed, 4)
        XCTAssertEqual(count.heldValue, 40)
        count.letGo()
        XCTAssertEqual(count.heldValue, 40, "nothing is home yet")
        var homes: [Int] = []
        var moments: [Double] = []
        var values = [count.heldValue]
        var guardSteps = 0
        while !count.isGone && guardSteps < 600 {
            guardSteps += 1
            for beat in count.step(step, gold: 100) {
                if case .home(let index) = beat {
                    homes.append(index)
                    moments.append(count.time)
                }
            }
            if values.last != count.heldValue { values.append(count.heldValue) }
        }
        XCTAssertEqual(homes, [3, 2, 1, 0], "the last laid first")
        XCTAssertEqual(values, [40, 30, 20, 10, 0], "the purse takes each coin as it arrives")
        for index in moments.indices.dropFirst() {
            XCTAssertEqual(moments[index] - moments[index - 1], PayCount.homeGap, accuracy: step + 1e-9)
        }
        XCTAssertEqual(count.homeShare(0), 1)
        XCTAssertTrue(count.isGone, "then the board goes down")
    }

    /// The critic's H1 and M1: each plank tile is picked by a hash, never the same as its neighbour, and stays put;
    /// the coins' faces never run in a plain cycle.
    func testTheTilesAndFacesVary() {
        for thing in ["touch-plot-0", "touch-wall-6", "touch-recruit-guard"] {
            for row in 0..<3 {
                var previous: Int?
                var seen = Set<Int>()
                for index in 0..<12 {
                    let pick = PayBoardLayout.pick(PayBoardLayout.plankMiddles, thing: thing, row: row, index: index,
                                                   previous: previous)
                    XCTAssertTrue(PayBoardLayout.plankMiddles.contains(pick))
                    XCTAssertNotEqual(pick, previous, "no two alike side by side")
                    XCTAssertEqual(pick, PayBoardLayout.pick(PayBoardLayout.plankMiddles, thing: thing, row: row,
                                                             index: index, previous: previous), "it stays put")
                    seen.insert(pick)
                    previous = pick
                }
                XCTAssertGreaterThanOrEqual(seen.count, 2)
            }
        }
        let faces = (0..<9).map { PayBoardLayout.face(of: $0) }
        XCTAssertEqual(Set(faces), [0, 1, 2], "three faces")
        XCTAssertNotEqual(faces, [0, 1, 2, 0, 1, 2, 0, 1, 2], "not a plain cycle")
        XCTAssertEqual(SpriteID.hudHollowTen.frameCount, 4, "empty and three faces")
        XCTAssertEqual(SpriteID.payCoin.frameCount, 5, "three faces, the edge and the half turn")
        XCTAssertEqual(SpriteID.siteLantern.size, PixelSize(width: 9, height: 13), "the lantern is no speck")
    }

    // MARK: - The board

    func testTheBoardsLayoutFitsItsHollows() {
        for price in [10, 12, 14, 45, 90, 330, 245, 199, 999] {
            let coins = PayCount.hollows(price: price)
            let layout = PayBoardLayout.make(coins)
            XCTAssertEqual(layout.hollows.count, coins.count, "\(price)")
            XCTAssertEqual(layout.width % PayBoardLayout.tile, 0, "whole tiles: \(price)")
            XCTAssertLessThanOrEqual(layout.rows, 4, "\(price)")
            XCTAssertEqual(layout.height, PayBoardLayout.cap + layout.rows * PayBoardLayout.plank + PayBoardLayout.foot)
            for hollow in layout.hollows {
                let size = hollow.coin.hollow.size
                XCTAssertGreaterThanOrEqual(hollow.x, PayBoardLayout.margin, "\(price)")
                XCTAssertLessThanOrEqual(hollow.x + size.width, layout.width - PayBoardLayout.margin, "\(price)")
                XCTAssertGreaterThanOrEqual(hollow.y, PayBoardLayout.cap)
                XCTAssertLessThanOrEqual(hollow.y + size.height, layout.height - PayBoardLayout.foot)
            }
        }
        let tally = PayBoardLayout.make(PayCount.hollows(price: 45))
        XCTAssertEqual(tally.rows, 2, "the big coins on one plank, the small on the next")
        XCTAssertEqual(PayBoardLayout.make(PayCount.hollows(price: 90)).rows, 2, "five to a row")
        XCTAssertEqual(PayBoardLayout.make(PayCount.hollows(price: 10)).rows, 1)
        for item in BuildItem.allCases {
            XCTAssertLessThanOrEqual(PayBoardLayout.make(PayCount.hollows(price: Balance.standard.price(item))).rows, 3,
                                     "\(item)")
        }
    }

    // MARK: - What is bought

    func testWhatACountIsFor() throws {
        var s = GameState.newRealm(seed: 2)
        s.hour = 10
        s.gold = 500
        let things = TouchThings.world(s, balance: .standard, figures: [], talked: [])
        let gate = try XCTUnwrap(things.first { $0.id == "touch-plot-0" }, "the gate can grow")
        let offer = try XCTUnwrap(PayOffers.offer(gate, state: s, balance: .standard))
        XCTAssertEqual(offer.offer, .build(plot: 0, item: .ironGate))
        XCTAssertEqual(offer.price, Balance.standard.price(.ironGate))
        let brazier = Realm.lines[0].braziers[0]
        let site = try XCTUnwrap(things.first { $0.id == "touch-plot-\(brazier)" })
        XCTAssertNil(PayOffers.offer(site, state: s, balance: .standard), "an empty plot keeps its card")
        let archer = try XCTUnwrap(things.first { $0.id == "touch-recruit-archer" })
        let guardsman = try XCTUnwrap(things.first { $0.id == "touch-recruit-guard" })
        XCTAssertEqual(PayOffers.offer(archer, state: s, balance: .standard)?.offer, .recruit(.archer))
        XCTAssertEqual(PayOffers.offer(guardsman, state: s, balance: .standard)?.price, Balance.standard.guardPrice)
        XCTAssertLessThan(archer.x, guardsman.x, "the archer's half on the left")
        XCTAssertFalse(things.contains { $0.id == "touch-recruit-barracks" })
        let door = try XCTUnwrap(things.first { $0.id == "touch-door-hall" })
        XCTAssertNil(PayOffers.offer(door, state: s, balance: .standard))
        s.hour = 22
        let wall = Realm.lines[0].wall
        if let item = s.plots[wall].item { s.plots[wall].hp = Build.maxHP(item, balance: .standard) / 2 }
        let night = TouchThings.world(s, balance: .standard, figures: [], talked: [])
        let repair = try XCTUnwrap(night.first { $0.id == "touch-wall-\(wall)" })
        XCTAssertEqual(PayOffers.offer(repair, state: s, balance: .standard)?.offer, .patch(plot: wall))
        s.king.patchCooldown = 2
        XCTAssertTrue(PayOffers.refused(.patch(plot: wall), state: s, balance: .standard), "cooling down: refused")
    }

    func testTheFreezeHoldsTheCountForItsPictures() {
        XCTAssertEqual(PayFreeze.parse("0.5"), .share(0.5))
        XCTAssertEqual(PayFreeze.parse("full"), .full)
        XCTAssertEqual(PayFreeze.parse("1"), .full)
        XCTAssertEqual(PayFreeze.parse("sealed"), .sealed)
        XCTAssertEqual(PayFreeze.parse("back"), .back)
        XCTAssertEqual(PayFreeze.parse("lit:0.3"), .lit(0.3), "step 3: the light by day held at an age")
        XCTAssertEqual(PayFreeze.lit(0.3).litHold, 0.3)
        XCTAssertNil(PayFreeze.sealed.litHold)
        XCTAssertNil(PayFreeze.parse("soon"))
        XCTAssertNil(PayFreeze.parse(nil))
        #if DEBUG
        XCTAssertEqual(DebugArgs(values: ["GWCountFreeze": "0.25"]).countFreeze, .share(0.25))
        #endif
        var count = PayCount(thing: "t", offer: .patch(plot: 0), price: 90, holding: true)
        count.arrive()
        let half = PayFreeze.share(0.5)
        while !half.holds(count) { _ = count.step(step, gold: 500) }
        XCTAssertEqual(count.placed, 4, "half of nine coins")
        XCTAssertTrue(PayFreeze.share(0).holds(count))
        XCTAssertFalse(PayFreeze.full.holds(count))
        // Step 2's filmstrips: a coin at an exact share of its flight.
        XCTAssertEqual(PayFreeze.parse("fly:1:0.5"), .flight(coin: 1, share: 0.5))
        XCTAssertNil(PayFreeze.parse("fly:x:0.5"))
        XCTAssertNil(PayFreeze.parse("fly:1"))
        var held = PayCount(thing: "t", offer: .patch(plot: 0), price: 90, holding: true)
        held.arrive()
        let fly = PayFreeze.flight(coin: 1, share: 0.5)
        var frames = 0
        while !fly.holds(held) && frames < 600 {
            frames += 1
            let room = fly.room(held) ?? step
            _ = held.step(min(step, room), gold: 500)
        }
        XCTAssertEqual(held.flightShare(1) ?? -1, 0.5, accuracy: 1e-6, "frozen on the exact moment")
        XCTAssertEqual(held.placed, 1, "the first coin lies, the second is half way")
    }

    // MARK: - Through the game

    private var directory: URL!
    private let pro = PixelScale(physicalWidth: 2622, physicalHeight: 1206)
    private let proPoints = CGSize(width: 874, height: 402)

    override func setUp() async throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("lanternhold-count-\(UUID().uuidString)", isDirectory: true)
    }

    override func tearDown() async throws {
        if let directory { try? FileManager.default.removeItem(at: directory) }
    }

    private func model(_ values: [String: String]) -> GameModel {
        var all = values
        all["GWReset"] = "YES"
        all["GWSkipOnboarding"] = "YES"
        return GameModel(args: DebugArgs(values: all), kind: .world, store: SaveStore(directory: directory))
    }

    private func run(_ game: GameModel, seconds: Double, until done: () -> Bool = { false }) {
        var left = seconds
        var frames = 0
        while left > 1e-9 {
            game.advance(by: 1.0 / 60)
            frames += 1
            if frames % 4 == 0 { _ = game.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight) }
            left -= 1.0 / 60
            if done() { return }
        }
    }

    private func gateGame(gold: Int) -> GameModel {
        let game = model(["GWStage": "world", "GWSeed": "2", "GWDay": "3", "GWClock": "10", "GWCameraX": "1240",
                          "GWGold": "\(gold)"])
        _ = game.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
        return game
    }

    func testAHoldOnTheGatePaysItsUpgradeCoinByCoin() throws {
        let game = gateGame(gold: 200)
        let hub = SilentFeedback()
        game.feedback = hub
        let gate = try XCTUnwrap(game.touch.things.first { $0.id == "touch-plot-0" })
        let price = Balance.standard.price(.ironGate)
        // The first touch brings the board and sends him beside it; then a hold counts.
        game.touchThing(gate)
        XCTAssertEqual(game.touch.count?.thing, gate.id, "the board comes up at the gate")
        XCTAssertNil(game.overlay, "no card")
        XCTAssertNil(game.errandSlip, "no slip: the board is the price")
        run(game, seconds: 10) { game.touch.count?.ready == true }
        XCTAssertEqual(game.touch.count?.ready, true, "he stands beside the board")
        XCTAssertEqual(game.driver?.state.gold, 200, "nothing paid yet")
        var count = try XCTUnwrap(game.touch.count)
        count.press()
        game.touch.count = count
        run(game, seconds: 0.6)
        XCTAssertEqual(game.driver?.state.gold, 200, "nothing leaves the treasury before the board is full")
        XCTAssertGreaterThan(game.touch.count?.placed ?? 0, 0, "coins on the board")
        run(game, seconds: 2) { game.touch.countLast.hasPrefix("paid") }
        XCTAssertEqual(game.touch.countLast, "paid:\(gate.id)")
        XCTAssertEqual(game.driver?.state.gold, 200 - price, "paid once, in full")
        XCTAssertEqual(game.driver?.state.plots[0].job?.target, .ironGate, "the work starts at the seal")
        XCTAssertEqual(hub.coins.count, PayCount.hollows(price: price).count, "a clink and a tick for every coin")
        let rates = hub.coins.map { $0.rate }
        XCTAssertEqual(rates, rates.sorted(), "each a little higher")
        XCTAssertTrue(hub.played.contains(.countSeal), "the seal")
        XCTAssertFalse(hub.played.contains(.countLantern), "the lantern waits for the board to go")
        run(game, seconds: CountLantern.catchAfterSeal + 0.1)
        XCTAssertTrue(hub.played.contains(.countLantern), "then the lantern")
        XCTAssertTrue(hub.played.contains(.buildOrdered), "then the work's own sound")
        run(game, seconds: 3)
        XCTAssertEqual(game.driver?.state.gold, 200 - price, "and only once")
        XCTAssertNil(game.touch.count, "the board went down")
    }

    func testACardTheHornAndTheBackgroundCutACountOff() throws {
        let game = gateGame(gold: 200)
        let gate = try XCTUnwrap(game.touch.things.first { $0.id == "touch-plot-0" })
        game.touchThing(gate)
        run(game, seconds: 10) { game.touch.count?.ready == true }
        var count = try XCTUnwrap(game.touch.count)
        count.press()
        game.touch.count = count
        run(game, seconds: 0.5)
        game.openPause()
        XCTAssertEqual(game.touch.count?.result, .cutOff, "a card cuts it off")
        game.resume()
        run(game, seconds: 3)
        XCTAssertEqual(game.driver?.state.gold, 200, "and it paid nothing")
        // The background.
        if let again = game.touch.things.first(where: { $0.id == gate.id }) {
            game.touchThing(again)
            run(game, seconds: 10) { game.touch.count?.ready == true }
            game.pauseForBackground()
            XCTAssertNotEqual(game.touch.count?.result, .paid)
            XCTAssertEqual(game.driver?.state.gold, 200)
        }
    }

    /// The review's must-fix 3: the finger owns its press, not the board. A hold that pays in full and stays down past
    /// the board's life lifts into nothing: no build card, no errand, no new board.
    func testAFingerHeldPastTheBoardOpensNothingWhenItLifts() throws {
        let game = gateGame(gold: 200)
        let gate = try XCTUnwrap(game.touch.things.first { $0.id == "touch-plot-0" })
        let framing = try XCTUnwrap(game.touch.framing)
        let p = CGPoint(x: framing.deviceX(stageX: gate.x) / 3, y: framing.deviceY(lift: 20) / 3)
        guard game.thingAt(p, in: proPoints)?.id == gate.id else {
            throw XCTSkip("someone stands before the gate")
        }
        game.touchChanged(start: p, at: p, translation: .zero, in: proPoints)
        run(game, seconds: 12) { game.touch.countLast.hasPrefix("paid") }
        XCTAssertEqual(game.touch.countLast, "paid:\(gate.id)", "the hold paid it")
        run(game, seconds: 3)
        XCTAssertNil(game.touch.count, "the board went down under the finger")
        game.touchEnded(at: p, translation: .zero, in: proPoints)
        XCTAssertNil(game.overlay, "no card")
        XCTAssertNil(game.touch.errand, "no errand")
        XCTAssertNil(game.touch.count, "no new board")
        run(game, seconds: 4)
        XCTAssertNil(game.overlay, "and none later")
        XCTAssertEqual(game.driver?.state.gold, 200 - Balance.standard.price(.ironGate), "paid once")
    }

    /// PAY.md 4: the horn cuts a count off, it pays nothing (the review's should-fix: the horn was untested).
    func testTheHornCutsACountOff() throws {
        let game = model(["GWStage": "world", "GWSeed": "2", "GWDay": "3", "GWClock": "18.95", "GWCameraX": "1240",
                          "GWGold": "200"])
        _ = game.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
        let gate = try XCTUnwrap(game.touch.things.first { $0.id == "touch-plot-0" })
        game.touchThing(gate)
        var count = try XCTUnwrap(game.touch.count, "the board comes up before the horn")
        count.press()
        game.touch.count = count
        run(game, seconds: 3) { (game.driver?.state.hour ?? 0) >= 19 }
        XCTAssertGreaterThanOrEqual(game.driver?.state.hour ?? 0, 19, "the horn sounded")
        XCTAssertEqual(game.touch.count?.result, .cutOff, "the horn cut the count off")
        XCTAssertEqual(game.touch.countLast, "cutOff:\(gate.id)")
        run(game, seconds: 3)
        XCTAssertEqual(game.driver?.state.gold, 200, "and it paid nothing")
        XCTAssertNil(game.driver?.state.plots[0].job, "no work ordered")
    }

    /// The review's must-fix 1: by day a touch on a town door knocks (the taxes on foot), though the house's area,
    /// which a count could buy, covers the door.
    func testATouchOnATownDoorKnocksAndBringsNoBoard() throws {
        let game = model(["GWStage": "world", "GWDay": "2", "GWTown": "owed", "GWClock": "14", "GWHappiness": "66",
                          "GWCameraX": "2400"])
        _ = game.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
        game.refreshTownMarks()
        let doors = game.townMarks.map { CGPoint(x: $0.x * proPoints.width, y: $0.y * proPoints.height) }
            .filter { game.townDoor(at: $0, in: proPoints) != nil }
            .filter { point in game.stagePoint(point, in: proPoints).map { !game.isOnLordsBody($0) } ?? false }
        XCTAssertFalse(doors.isEmpty, "doors on screen, the lord on none")
        // The door inside a house's touch area if there is one (the case the count took), else any door.
        let door = try XCTUnwrap(doors.first { game.thingAt($0, in: proPoints) != nil } ?? doors.first)
        game.touchChanged(start: door, at: door, translation: .zero, in: proPoints)
        XCTAssertNil(game.touch.count, "no board for a door")
        game.touchEnded(at: door, translation: .zero, in: proPoints)
        XCTAssertEqual(game.touch.lastTap, "door", "the lift knocks")
        XCTAssertNotNil(game.townRun.walk, "he walks to the door")
        XCTAssertNil(game.touch.count)
    }

    func testTheRepairIsPaidByItsCount() throws {
        let game = model(["GWStage": "world", "GWSeed": "1", "GWNight": "1", "GWHour": "22", "GWGold": "50",
                          "GWCameraX": "1280"])
        let wall = Realm.lines[0].wall
        game.withDriver { driver in
            if let item = driver.state.plots[wall].item {
                driver.state.plots[wall].hp = Build.maxHP(item, balance: driver.balance) / 2
            }
            driver.state.gold = 50
        }
        _ = game.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
        let repair = try XCTUnwrap(game.touch.things.first { $0.id == "touch-wall-\(wall)" }, "the wall offers")
        let hp = try XCTUnwrap(game.driver?.state.plots[wall].hp)
        game.touchThing(repair)
        XCTAssertEqual(game.touch.count?.coins, [.big], "one big coin for the repair")
        // Step 2 (M7): the one-hollow board catches a finger at least 44 pt wide.
        let board = try XCTUnwrap(game.touch.countBoard)
        let probe = try XCTUnwrap(game.stagePoint(CGPoint(x: 400, y: 200), in: proPoints))
        let reach = max(Double(board.layout.width), probe.minimum) / 2 - 0.5
        XCTAssertGreaterThanOrEqual(2 * reach + 1, probe.minimum)
        for dx in [-reach, reach] {
            XCTAssertEqual(game.countBoardThing((x: board.x + dx, lift: 10, minimum: probe.minimum))?.id, repair.id,
                           "the board catches the touch \(dx) px from its middle")
        }
        run(game, seconds: 8) { game.touch.count?.ready == true }
        XCTAssertEqual(game.driver?.state.gold, 50, "the touch that brings the board pays nothing")
        // A second touch on the wall sets the coin: the board is full, the seal falls.
        let again = try XCTUnwrap(game.touch.things.first { $0.id == "touch-wall-\(wall)" })
        game.touchThing(again)
        run(game, seconds: 1) { game.touch.countLast.hasPrefix("paid") }
        XCTAssertEqual(game.driver?.state.gold, 50 - Balance.standard.patchCost, "paid")
        XCTAssertGreaterThan(try XCTUnwrap(game.driver?.state.plots[wall].hp), hp, "and repaired")
    }

    func testARecruitIsCountedAtHisHalfOfTheBarracks() throws {
        let game = model(["GWStage": "world", "GWSeed": "1", "GWClock": "9", "GWCameraX": "1560", "GWGold": "40"])
        _ = game.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
        let guardsman = try XCTUnwrap(game.touch.things.first { $0.id == "touch-recruit-guard" })
        let before = game.driver?.state.guardCount ?? 0
        game.touchSpot(guardsman.id)
        run(game, seconds: 10) { game.touch.countLast.hasPrefix("paid") }
        XCTAssertEqual(game.touch.countLast, "paid:touch-recruit-guard", "VoiceOver's double tap pays in one step")
        XCTAssertEqual(game.driver?.state.gold, 40 - Balance.standard.guardPrice)
        XCTAssertEqual(game.driver?.state.guardCount, before + 1)
    }

    func testADragBeforeTheBoardIsUpIsAWalk() throws {
        let game = gateGame(gold: 200)
        let gate = try XCTUnwrap(game.touch.things.first { $0.id == "touch-plot-0" })
        let framing = try XCTUnwrap(game.touch.framing)
        let p = CGPoint(x: framing.deviceX(stageX: gate.x) / 3, y: framing.deviceY(lift: 20) / 3)
        guard game.thingAt(p, in: proPoints)?.id == gate.id else {
            throw XCTSkip("someone stands before the gate")
        }
        game.touchChanged(start: p, at: p, translation: .zero, in: proPoints)
        XCTAssertEqual(game.touch.count?.thing, gate.id, "the board starts to come up")
        game.advance(by: 0.05)
        let moved = CGPoint(x: p.x - 30, y: p.y)
        game.touchChanged(start: p, at: moved, translation: CGSize(width: -30, height: 0), in: proPoints)
        XCTAssertNil(game.touch.count, "a drag is a walk, never a count")
        game.touchEnded(at: moved, translation: CGSize(width: -30, height: 0), in: proPoints)
        // A hold on the same place counts from the touch.
        game.touchChanged(start: p, at: p, translation: .zero, in: proPoints)
        run(game, seconds: 12) { game.touch.countLast.hasPrefix("paid") }
        game.touchEnded(at: p, translation: .zero, in: proPoints)
        XCTAssertEqual(game.touch.countLast, "paid:\(gate.id)", "the hold paid it")
        XCTAssertEqual(game.driver?.state.gold, 200 - Balance.standard.price(.ironGate))
    }

    func testThePurseRunsDownWithTheCoinsAndBackWhenLetGo() throws {
        let game = gateGame(gold: 200)
        let gate = try XCTUnwrap(game.touch.things.first { $0.id == "touch-plot-0" })
        game.touchThing(gate)
        run(game, seconds: 10) { game.touch.count?.ready == true }
        var count = try XCTUnwrap(game.touch.count)
        count.press()
        game.touch.count = count
        run(game, seconds: 0.55)
        let held = game.countHeld
        XCTAssertGreaterThan(held, 0)
        // The purse shows the treasury less the town's coins still in the air (round lh-b3c-21: a tax of 3 was on its
        // way while the lord walked to the board beside the gate), and less the coins on the board.
        let state = try XCTUnwrap(game.driver?.state)
        let balance = try XCTUnwrap(game.driver?.balance)
        let seen = game.townShownGold(state, balance: balance)
        XCTAssertEqual(game.purse.target, seen - held, "the purse shows the coins on the board as gone")
        XCTAssertEqual(game.purse.shown, seen - held, "the figure in step with the board, never trailing it")
        var lifted = try XCTUnwrap(game.touch.count)
        lifted.lift(tap: false)
        game.touch.count = lifted
        run(game, seconds: 3)
        XCTAssertEqual(game.touch.countLast, "letGo:\(gate.id)")
        XCTAssertEqual(game.driver?.state.gold, 200)
        XCTAssertEqual(game.purse.target, 200, "and back when they slide back")
    }

    func testTheBoardIsDrawnInTheWorld() throws {
        let game = gateGame(gold: 200)
        let gate = try XCTUnwrap(game.touch.things.first { $0.id == "touch-plot-0" })
        game.touchThing(gate)
        run(game, seconds: 0.3)
        let frame = game.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
        let board = frame.actors.filter { $0.sprite == .payBoard }
        XCTAssertFalse(board.isEmpty, "the board on its post")
        XCTAssertTrue(board.allSatisfy { $0.isLit && !$0.isEmissive }, "a thing in the world, lit by it")
        XCTAssertEqual(frame.actors.filter { $0.sprite == .hudHollowTen }.count, 9, "nine hollows for 90")
        XCTAssertFalse(frame.actors.contains { $0.sprite == .siteLantern }, "no lantern on top of its post")
        XCTAssertTrue(frame.actors.contains { $0.sprite == .hudCoinTen }, "the first coin rocks over its hollow")
    }

    // MARK: - Step 2 through the game

    /// The critic's blocker: on a hold the coin is drawn in the air between the lord's hand and its hollow, turning
    /// (step 4: half turned, then its face, never the edge), and lands in the hollow.
    func testTheCoinIsDrawnFlyingFromTheLordsHand() throws {
        let game = gateGame(gold: 200)
        let gate = try XCTUnwrap(game.touch.things.first { $0.id == "touch-plot-0" })
        game.touchThing(gate)
        run(game, seconds: 10) { game.touch.count?.ready == true }
        var count = try XCTUnwrap(game.touch.count)
        count.press()
        game.touch.count = count
        let board = try XCTUnwrap(game.touch.countBoard)
        var sawOff = false
        var sawHalf = false
        var sawFace = false
        for _ in 0..<40 {
            game.advance(by: 1.0 / 60)
            let frame = game.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
            guard let live = game.touch.count, live.inFlight > 0, let framing = game.touch.framing else { continue }
            let lordX = framing.deviceX(stageX: game.driver?.state.king.x ?? 0)
            let near = board.side < 0 ? board.left : board.left + board.layout.width
            let nearEdge = framing.deviceX(stageX: Double(near))
            let boardTop = framing.deviceY(lift: board.top)
            for actor in frame.actors where actor.sprite == .hudCoinTen {
                let middle = Double(actor.rect.x + actor.rect.z / 2)
                // Off the board: between his hand and the board's near edge, or over the board's top on its arc.
                let beside = (middle - lordX) * (nearEdge - lordX) >= 0 && abs(middle - lordX) <= abs(nearEdge - lordX)
                if beside || Double(actor.rect.y) < boardTop { sawOff = true }
                XCTAssertNotEqual(actor.frame, 3, "never the edge in the air")
                if actor.frame == 4 { sawHalf = true }
                if actor.frame < 3 { sawFace = true }
            }
        }
        XCTAssertTrue(sawOff, "a coin in the air off the board, on its way from his hand")
        XCTAssertTrue(sawHalf && sawFace, "turning in the air")
        XCTAssertGreaterThan(game.touch.count?.placed ?? 0, 0, "and they land")
    }

    /// The critic's H3: the gate's board stands beside the gatehouse on the lord's side, never over the gate; the
    /// recruits' boards beside the barracks, clear of Marek's cart; the lord on the board's outer side.
    func testTheBoardStandsBesideItsThing() throws {
        let game = gateGame(gold: 200)
        let gate = try XCTUnwrap(game.touch.things.first { $0.id == "touch-plot-0" })
        let lordX = try XCTUnwrap(game.driver?.state.king.x)
        game.touchThing(gate)
        let board = try XCTUnwrap(game.touch.countBoard)
        let half = Double(board.layout.width) / 2
        XCTAssertTrue(board.x + half <= gate.x - gate.halfWidth || board.x - half >= gate.x + gate.halfWidth,
                      "never over the gate or its doorway")
        XCTAssertEqual(board.side, lordX <= gate.x ? -1 : 1, "on the lord's side")
        XCTAssertEqual(board.stand > board.x, board.side > 0, "he stands on its outer side")
        let edge = board.side < 0 ? gate.x - gate.halfWidth - (board.x + half)
            : board.x - half - (gate.x + gate.halfWidth)
        XCTAssertLessThanOrEqual(edge, Double(GameModel.countBoardSearch) + 1, "beside it")
        let blocked = game.countObstacles(gate)
        let clear = !blocked.contains { $0.lowerBound < board.x + half + 1 && $0.upperBound > board.x - half - 1 }
        let ideal = board.side < 0 ? (gate.x - gate.halfWidth - half).rounded(.down)
            : (gate.x + gate.halfWidth + half).rounded(.up)
        XCTAssertTrue(clear || board.x == ideal, "clear of everyone and every door, or no clear place within reach")

        let barracks = model(["GWStage": "world", "GWSeed": "2", "GWDay": "3", "GWClock": "10", "GWCameraX": "1580",
                              "GWGold": "60"])
        _ = barracks.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
        let cartLeft = CourtLayout.marekCartX
        let cartRight = cartLeft + Double(SpriteID.marekCart.size.width)
        let wallLeft = EntityFrames.barracksLeft
        let wallRight = wallLeft + Double(SpriteID.barracks.size.width)
        for id in ["touch-recruit-archer", "touch-recruit-guard"] {
            let thing = try XCTUnwrap(barracks.touch.things.first { $0.id == id })
            let layout = PayBoardLayout.make(PayCount.hollows(price: thing.price ?? 10))
            let place = barracks.countBoardPlace(thing, layout: layout)
            let w = Double(layout.width) / 2
            XCTAssertFalse(place.x - w < cartRight && place.x + w > cartLeft, "\(id): never in Marek's cart")
            XCTAssertFalse(place.x - w < wallRight && place.x + w > wallLeft, "\(id): beside the barracks")
            XCTAssertEqual(place.side, id.hasSuffix("archer") ? -1 : 1, "\(id): at its own wall")
        }
        // The review of step 2: standing on the board's outer side he turns to it, so the coins never leave a hand
        // behind his back (he walks past the archer's board from the right and would stop facing left).
        for id in ["touch-recruit-archer", "touch-recruit-guard"] {
            let game = model(["GWStage": "world", "GWSeed": "2", "GWDay": "3", "GWClock": "10", "GWCameraX": "1580",
                              "GWGold": "60"])
            _ = game.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
            let thing = try XCTUnwrap(game.touch.things.first { $0.id == id })
            game.touchThing(thing)
            run(game, seconds: 12) { game.touch.count?.ready == true }
            let board = try XCTUnwrap(game.touch.countBoard, id)
            XCTAssertEqual(game.touch.count?.ready, true, "\(id): he reached the board")
            let king = try XCTUnwrap(game.driver?.state.king)
            XCTAssertEqual(king.facing, board.x >= king.x ? 1 : -1, "\(id): he faces the board")
        }
    }

    /// Step 3 (the director's call 4): a board of two or three planks hangs low, its lowest row a few pixels over the
    /// ground, its top row at the lord's reach (between his shoulder, where the coins leave his hand, and a little
    /// over his head); a one-plank board stands on its post as before.
    func testTheBoardHangsAtTheLordsReach() throws {
        for price in [90, 180, 14, 40] {
            let layout = PayBoardLayout.make(PayCount.hollows(price: price))
            let board = CountBoard(x: 100, stand: 60, act: .build(plot: 0), layout: layout)
            let topRow = try XCTUnwrap(layout.hollows.first)
            let rowMiddle = board.top - Double(topRow.y) - Double(topRow.coin.hollow.size.height) / 2
            let lowest = try XCTUnwrap(layout.hollows.last)
            let lowestBottom = board.top - Double(lowest.y + lowest.coin.hollow.size.height)
            if layout.rows >= 2 {
                XCTAssertLessThanOrEqual(lowestBottom, 8, "\(price): the lowest row a few px over the ground")
                XCTAssertGreaterThanOrEqual(lowestBottom, 3, "\(price): never on it")
                XCTAssertGreaterThanOrEqual(rowMiddle, GameModel.countHandLift - 6, "\(price): the top row at his reach")
                XCTAssertLessThanOrEqual(rowMiddle, Double(HUDKit.lordHead) + 8, "\(price): never far over his head")
            } else {
                XCTAssertEqual(board.bottom, CountBoard.lift, "\(price): one plank stands on its post")
            }
        }
    }

    /// Step 3 (the director's call 3): after the last coin lands it settles, then 0.12 s of stillness, then the lid.
    func testTheLastCoinGetsItsBeat() {
        var count = PayCount(thing: "t", offer: .patch(plot: 0), price: 45, holding: true)
        count.arrive()
        while count.result == nil && count.time < 4 { _ = count.step(step, gold: 100) }
        XCTAssertEqual(count.result, .paid)
        let last = count.landed.last ?? 0
        XCTAssertEqual(count.resultAt - last, PayCount.sealDelay, accuracy: 1e-6, "the seal a beat after the last coin")
        XCTAssertGreaterThanOrEqual(PayCount.sealDelay - PayCount.settleSeconds - PayCount.squashSeconds,
                                    0.12 - 1e-9, "0.12 s of stillness once it sat down")
    }

    /// Step 3 (the director's call 2): the board takes the weight: a ten dips it a pixel, a bar two, back in two
    /// frames; a small coin does not move it; never under Reduce Motion.
    func testTheBoardTakesTheWeight() {
        let frame = 1.0 / 60
        XCTAssertEqual(GameModel.countDip(.small, since: 0, reduceMotion: false), 0)
        XCTAssertEqual(GameModel.countDip(.big, since: 0, reduceMotion: false), 1)
        XCTAssertEqual(GameModel.countDip(.big, since: 1.5 * frame, reduceMotion: false), 1)
        XCTAssertEqual(GameModel.countDip(.big, since: 2.5 * frame, reduceMotion: false), 0)
        XCTAssertEqual(GameModel.countDip(.bar, since: 0, reduceMotion: false), 2)
        XCTAssertEqual(GameModel.countDip(.bar, since: 1.5 * frame, reduceMotion: false), 1)
        XCTAssertEqual(GameModel.countDip(.bar, since: 2.5 * frame, reduceMotion: false), 0)
        XCTAssertEqual(GameModel.countDip(.bar, since: 0, reduceMotion: true), 0)
    }

    #if DEBUG
    /// Step 3 (the director's call 2), on the drawn frame: the great gate's bar lands and the board's cap is drawn two
    /// pixels under its rest; under Reduce Motion it stays.
    func testTheBoardDipsUnderABar() throws {
        for still in [false, true] {
            var values = ["GWStage": "world", "GWSeed": "2", "GWDay": "3", "GWClock": "10", "GWCameraX": "1240",
                          "GWCastle": "2", "GWGold": "500", "GWCountFreeze": "fly:0:1.0"]
            if still { values["GWReduceMotion"] = "YES" }
            let game = model(values)
            _ = game.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
            let gate = try XCTUnwrap(game.touch.things.first { $0.id == "touch-plot-0" })
            game.touchThing(gate)
            run(game, seconds: 10) { game.touch.count?.ready == true }
            XCTAssertEqual(game.touch.count?.coins.first, .bar, "the great gate's board starts with its bar")
            var count = try XCTUnwrap(game.touch.count)
            count.press()
            game.touch.count = count
            run(game, seconds: 3) { (game.touch.count?.placed ?? 0) >= 1 }
            run(game, seconds: 2.0 / 60)
            XCTAssertEqual(game.touch.count?.placed, 1, "frozen as the bar lands")
            let frame = game.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
            let board = try XCTUnwrap(game.touch.countBoard)
            let framing = try XCTUnwrap(game.touch.framing)
            let cap = try XCTUnwrap(frame.actors.first { $0.sprite == .payBoard && $0.frame == PayBoardLayout.capLeft })
            let rest = framing.deviceY(lift: board.top + Double(PayBoardLayout.plank - PayBoardLayout.cap))
            XCTAssertEqual(Double(cap.rect.y) - Double(rest), (still ? 0 : 2) * Double(framing.scale), accuracy: 1.01,
                           still ? "Reduce Motion: no dip" : "the board dips two pixels under the bar")
        }
    }
    #endif

    /// Step 3 (the director's call 2): a coin that has sat down glints once, one white pixel for one frame; never
    /// under Reduce Motion.
    func testALaidCoinGlintsOnce() throws {
        for still in [false, true] {
            var values = ["GWStage": "world", "GWSeed": "2", "GWDay": "3", "GWClock": "10", "GWCameraX": "1240",
                          "GWGold": "200"]
            if still { values["GWReduceMotion"] = "YES" }
            let game = model(values)
            _ = game.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
            let gate = try XCTUnwrap(game.touch.things.first { $0.id == "touch-plot-0" })
            game.touchThing(gate)
            run(game, seconds: 10) { game.touch.count?.ready == true }
            var count = try XCTUnwrap(game.touch.count)
            count.tap()
            game.touch.count = count
            let state = try XCTUnwrap(game.driver?.state)
            let framing = try XCTUnwrap(game.touch.framing)
            var glintFrames = 0
            for _ in 0..<40 {
                game.advance(by: 1.0 / 60)
                var layer = EntityLayer()
                game.countWorld(&layer, state: state, framing: framing)
                if layer.glows.contains(where: { $0.sprite == .hallMote }) { glintFrames += 1 }
            }
            XCTAssertEqual(game.touch.count?.placed, 1, "the coin landed")
            if still {
                XCTAssertEqual(glintFrames, 0, "Reduce Motion: no glint")
            } else {
                XCTAssertTrue((1...2).contains(glintFrames), "one glint as it sits down, not \(glintFrames) frames")
            }
        }
    }

    /// Step 3 (the director's call 7, M-b): one look tells 1 from 10. The small coin and its hollow are 7 px, the big
    /// ones 11 px, in the art and as drawn on the guard's mixed board (one big coin, four small).
    func testOneLookTellsOneFromTen() throws {
        XCTAssertEqual(SpriteID.payCoin.size, PixelSize(width: 7, height: 7))
        XCTAssertEqual(SpriteID.hudHollow.size, PixelSize(width: 7, height: 7))
        XCTAssertEqual(SpriteID.hudCoinTen.size, PixelSize(width: 11, height: 11))
        XCTAssertEqual(SpriteID.hudHollowTen.size, PixelSize(width: 11, height: 11))
        let game = model(["GWStage": "world", "GWSeed": "2", "GWDay": "3", "GWClock": "10", "GWCameraX": "1580",
                          "GWGold": "60"])
        _ = game.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
        let guardsman = try XCTUnwrap(game.touch.things.first { $0.id == "touch-recruit-guard" })
        game.touchThing(guardsman)
        run(game, seconds: 0.4)
        let frame = game.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
        let scale = Float(try XCTUnwrap(game.touch.framing).scale)
        let small = frame.actors.filter { $0.sprite == .hudHollow }
        let big = frame.actors.filter { $0.sprite == .hudHollowTen }
        XCTAssertFalse(small.isEmpty, "small hollows on the guard's board")
        XCTAssertFalse(big.isEmpty, "and a big one")
        for actor in small { XCTAssertEqual(actor.rect.z, 7 * scale, accuracy: 0.5, "a small hollow is 7 px") }
        for actor in big { XCTAssertEqual(actor.rect.z, 11 * scale, accuracy: 0.5, "a big hollow is 11 px") }
    }

    /// Step 3 (the director's call 8, M-a): let go, each coin flies home on the throw's high arc at its full size for
    /// the first 60 % of the way and shrinks over the last 40 %; drawn: early in its way a coin is whole, late it is
    /// smaller.
    func testTheCoinsGoHomeWholeThenShrink() throws {
        XCTAssertEqual(GameModel.countHomeScale(0), 1)
        XCTAssertEqual(GameModel.countHomeScale(0.6), 1, accuracy: 1e-9, "whole for 60 % of the way")
        XCTAssertEqual(GameModel.countHomeScale(0.8), 0.5, accuracy: 1e-9)
        XCTAssertEqual(GameModel.countHomeScale(1), 0)
        let game = gateGame(gold: 200)
        let gate = try XCTUnwrap(game.touch.things.first { $0.id == "touch-plot-0" })
        game.touchThing(gate)
        run(game, seconds: 10) { game.touch.count?.ready == true }
        var count = try XCTUnwrap(game.touch.count)
        for _ in 0..<4 { count.tap() }
        game.touch.count = count
        run(game, seconds: 1)
        XCTAssertEqual(game.touch.count?.placed, 4)
        var letGo = try XCTUnwrap(game.touch.count)
        letGo.letGo()
        game.touch.count = letGo
        let scale = Float(try XCTUnwrap(game.touch.framing).scale)
        var sawWhole = false
        var sawShrunk = false
        for _ in 0..<30 {
            game.advance(by: 1.0 / 60)
            guard let live = game.touch.count, let share = live.homeShare(3), share > 0, share < 1 else { continue }
            let frame = game.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
            let flying = frame.actors.filter { $0.sprite == .hudCoinTen }
            if share < 0.55, flying.contains(where: { abs($0.rect.z - 11 * scale) < 0.5 }) { sawWhole = true }
            if share > 0.85, flying.contains(where: { $0.rect.z < 11 * scale - 0.5 }) { sawShrunk = true }
        }
        XCTAssertTrue(sawWhole, "a coin on its way home is whole early on")
        XCTAssertTrue(sawShrunk, "and shrinks near the hand")
    }

    /// Step 3 (the director's call 9, M-e and M-c): the seal is the rendered deep seal played at rate 1; the planks
    /// have five middles, one of them knotted, so one tile in five shows a knot.
    func testTheSealIsRenderedDeepAndThePlanksKnotted() {
        XCTAssertEqual(FeedbackCue.countSeal.sound, SoundPlay(id: .sealLow, volume: 0.85), "seal_low at rate 1")
        XCTAssertEqual(FeedbackCue.countSeal.haptic, .heavy, "the seal keeps the heavy beat")
        XCTAssertEqual(PayBoardLayout.plankMiddles.count, 5)
        XCTAssertTrue(PayBoardLayout.plankMiddles.contains(PayBoardLayout.plankKnot))
        XCTAssertEqual(SpriteID.payBoard.frameCount, 28)
        var knots = 0
        var tiles = 0
        for thing in ["touch-plot-0", "touch-plot-3", "touch-wall-6", "touch-recruit-guard", "touch-recruit-archer"] {
            for row in 0..<3 {
                var previous: Int?
                for index in 0..<12 {
                    let pick = PayBoardLayout.pick(PayBoardLayout.plankMiddles, thing: thing, row: row, index: index,
                                                   previous: previous)
                    previous = pick
                    tiles += 1
                    if pick == PayBoardLayout.plankKnot { knots += 1 }
                }
            }
        }
        XCTAssertGreaterThan(knots, tiles / 10, "knots are seen")
        XCTAssertLessThan(knots, tiles * 3 / 10, "about one tile in five")
    }

    /// Step 3 (the director's call 9): a count cut while coins are in the air never shows the purse dipping (those
    /// coins were never taken from its figure); the ones laid come home as before.
    func testACutMidFlightNeverDipsThePurse() {
        var count = PayCount(thing: "t", offer: .patch(plot: 0), price: 90, holding: true)
        count.arrive()
        while (count.inFlight == 0 || count.placed < 2) && count.time < 3 { _ = count.step(step, gold: 500) }
        XCTAssertGreaterThan(count.inFlight, 0, "a coin in the air")
        let before = count.heldValue
        count.cut()
        XCTAssertLessThanOrEqual(count.heldValue, before, "the figure never dips at the cut")
        var most = count.heldValue
        while !count.isGone && count.time < 5 {
            _ = count.step(step, gold: 500)
            most = max(most, count.heldValue)
        }
        XCTAssertLessThanOrEqual(most, before, "nor while the coins go home")
        XCTAssertEqual(count.heldValue, 0)
    }

    /// Step 3 (the director's call 9): the coin steps are made ready as the first board rises; a recount of the same
    /// thing never stacks two boards; a jump to a new realm leaves no board, no coins going home and no site lantern.
    func testTheCountsSmallEdges() throws {
        let game = gateGame(gold: 200)
        let hub = SilentFeedback()
        game.feedback = hub
        let gate = try XCTUnwrap(game.touch.things.first { $0.id == "touch-plot-0" })
        game.touchThing(gate)
        XCTAssertGreaterThanOrEqual(hub.warmed, 1, "the clink's steps are made ready as the board rises")
        run(game, seconds: 10) { game.touch.count?.ready == true }
        var count = try XCTUnwrap(game.touch.count)
        count.tap()
        count.tap()
        game.touch.count = count
        run(game, seconds: 0.6)
        var lifted = try XCTUnwrap(game.touch.count)
        lifted.letGo()
        game.touch.count = lifted
        game.touchThing(gate)
        XCTAssertEqual(game.touch.count?.thing, gate.id, "the gate's board again")
        XCTAssertNil(game.touch.countOld, "never two boards stacked on one place")
        XCTAssertNil(game.touch.countOldBoard)
        game.touch.countLanterns = [CountLantern(offer: .recruit(.archer), postLeft: 1200, litAt: 0)]
        game.resetLanternHUD()
        XCTAssertNil(game.touch.count, "a jump leaves no board")
        XCTAssertNil(game.touch.countOld)
        XCTAssertTrue(game.touch.countLanterns.isEmpty, "and no site lantern of the realm before")
        XCTAssertEqual(game.driver?.state.gold, 200, "nothing paid")
    }

    #if DEBUG
    /// Step 3 (the director's call 9, M-f): a count frozen for its pictures keeps the purse's figure up, showing the
    /// gold less the coins on the board.
    func testAFrozenCountKeepsThePurseUp() throws {
        let game = model(["GWStage": "world", "GWSeed": "2", "GWDay": "3", "GWClock": "10", "GWCameraX": "1240",
                          "GWGold": "200", "GWCountFreeze": "0.5"])
        _ = game.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
        let gate = try XCTUnwrap(game.touch.things.first { $0.id == "touch-plot-0" })
        game.touchThing(gate)
        run(game, seconds: 10) { game.touch.count?.ready == true }
        var count = try XCTUnwrap(game.touch.count)
        count.press()
        game.touch.count = count
        run(game, seconds: 3) { game.countFrozen }
        XCTAssertTrue(game.countFrozen, "frozen half full")
        run(game, seconds: 4)
        let held = game.touch.count?.heldValue ?? 0
        XCTAssertGreaterThan(held, 0)
        let driver = try XCTUnwrap(game.driver)
        let seen = game.townShownGold(driver.state, balance: driver.balance)
        XCTAssertEqual(game.purse.shown, seen - held, "the figure stays up, the gold run down")
    }
    #endif

    /// The critic's M2: the purse's figure never touches a board that stands by the lord.
    func testThePurseFigureStandsClearOfTheBoard() throws {
        let game = gateGame(gold: 200)
        let gate = try XCTUnwrap(game.touch.things.first { $0.id == "touch-plot-0" })
        game.touchThing(gate)
        run(game, seconds: 10) { game.touch.count?.ready == true }
        let board = try XCTUnwrap(game.touch.countBoard)
        let lordX = try XCTUnwrap(game.driver?.state.king.x)
        for width in [17, 27, 33] {
            let room = game.countPurseRoom(width: width, lordX: lordX)
            let left = Double(HUDKit.centredLeft(lordX: room.x, width: width))
            let right = left + Double(width)
            let bottom = Double(HUDKit.lordHead + HUDKit.purseAbove) + room.ground
            let overlaps = left < Double(board.left + board.layout.width) && right > Double(board.left)
            XCTAssertTrue(!overlaps || bottom >= board.top + 4, "a figure \(width) px wide clears the board")
        }
    }

    /// The critic's H2: the seal lights the site lantern; it stays lit on its post, with its halo and without the
    /// board, while the work runs, and goes out when the work is done.
    func testTheLitLanternBurnsWhileTheJobRuns() throws {
        let game = gateGame(gold: 200)
        let gate = try XCTUnwrap(game.touch.things.first { $0.id == "touch-plot-0" })
        game.touchThing(gate)
        run(game, seconds: 10) { game.touch.count?.ready == true }
        var count = try XCTUnwrap(game.touch.count)
        count.press()
        game.touch.count = count
        run(game, seconds: 3) { game.touch.countLast.hasPrefix("paid") }
        XCTAssertEqual(game.touch.countLanterns.count, 1, "the seal lit the site lantern")
        run(game, seconds: 2.5)
        XCTAssertNil(game.touch.count, "the board has gone")
        XCTAssertNotNil(game.driver?.state.plots[0].job, "the work runs")
        XCTAssertEqual(game.touch.countLanterns.count, 1)
        XCTAssertNil(game.touch.countLanterns.first?.outAt, "its lantern burns on")
        let frame = game.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
        XCTAssertTrue(frame.actors.contains { $0.sprite == .siteLantern && $0.frame == 1 }, "lit on its post")
        XCTAssertTrue(frame.actors.contains { $0.sprite == .payBoard }, "its post stands")
        XCTAssertFalse(frame.actors.contains { $0.sprite == .hudHollowTen }, "without the board")
        XCTAssertTrue(frame.emissives.contains { $0.sprite == .siteHalo }, "with its halo")
        XCTAssertTrue(game.countWord.contains("lanterns:1"))
        game.withDriver { driver in driver.state.plots[0].job = nil }
        run(game, seconds: 1.5)
        XCTAssertTrue(game.touch.countLanterns.isEmpty, "out and gone when the work is done")
    }

    /// Step 3 (the director's call 5; the review: on a post of its own past the board's edge the lantern hung over the
    /// gate's portcullis): no lantern stands on the board's post while the count runs; from the seal the site lantern
    /// hangs from a crook on the board's own post, unlit behind the shut board, and once the board has gone it burns
    /// there, the post cut to about the lord's shoulder. Drawn: the lantern is clear of the post's column, under the
    /// crook's top, over the ground, inside the board's own door-clear span, and the crook reaches no higher than his
    /// head.
    func testTheLanternHangsFromACrook() throws {
        let game = gateGame(gold: 200)
        let gate = try XCTUnwrap(game.touch.things.first { $0.id == "touch-plot-0" })
        game.touchThing(gate)
        run(game, seconds: 10) { game.touch.count?.ready == true }
        let board = try XCTUnwrap(game.touch.countBoard)
        XCTAssertEqual(board.toward, gate.x > board.x ? 1 : -1, "the crook points at the work")
        XCTAssertEqual(board.lanternPostLeft, board.postLeft, "on the board's own post")
        let counting = game.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
        XCTAssertFalse(counting.actors.contains { $0.sprite == .siteLantern }, "no lantern on the post while it counts")
        func check(_ frame: FrameDesc, lit: Bool, _ when: String) throws {
            let framing = try XCTUnwrap(game.touch.framing)
            let boardLeft = framing.deviceX(stageX: Double(board.left))
            let boardRight = framing.deviceX(stageX: Double(board.left + board.layout.width))
            let lantern = try XCTUnwrap(frame.actors.first { $0.sprite == .siteLantern && ($0.frame > 0) == lit },
                                        "\(when): the lantern")
            let postLeft = framing.deviceX(stageX: Double(board.lanternPostLeft + 1))
            let postRight = framing.deviceX(stageX: Double(board.lanternPostLeft + 5))
            let left = Double(lantern.rect.x)
            let right = Double(lantern.rect.x + lantern.rect.z)
            XCTAssertTrue(right <= postLeft + 1 || left >= postRight - 1,
                          "\(when): beside its post, never on top of it")
            XCTAssertTrue(left >= boardLeft - 1 && right <= boardRight + 1,
                          "\(when): inside the board's span, clear of the doorway")
            let crookTop = framing.deviceY(lift: CountLantern.crookTop)
            XCTAssertGreaterThan(Double(lantern.rect.y), crookTop, "\(when): it hangs under the crook")
            XCTAssertLessThan(Double(lantern.rect.y + lantern.rect.w), framing.deviceY(lift: 0),
                              "\(when): over the ground")
            let crookTiles = [PayBoardLayout.crookRightPost, PayBoardLayout.crookRightArm, PayBoardLayout.crookLeftPost,
                              PayBoardLayout.crookLeftArm]
            XCTAssertTrue(frame.actors.contains { $0.sprite == .payBoard && crookTiles.contains($0.frame) },
                          "\(when): its crook")
            XCTAssertLessThanOrEqual(CountLantern.crookTop, Double(HUDKit.lordHead), "cut to about his shoulder")
        }
        var count = try XCTUnwrap(game.touch.count)
        count.press()
        game.touch.count = count
        run(game, seconds: 3) { game.touch.countLast.hasPrefix("paid") }
        run(game, seconds: 0.3)
        XCTAssertNotNil(game.touch.count, "the board stands shut")
        let shut = game.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
        try check(shut, lit: false, "behind the shut board")
        let lanternIndex = try XCTUnwrap(shut.actors.firstIndex { $0.sprite == .siteLantern })
        let hollowIndex = try XCTUnwrap(shut.actors.firstIndex { $0.sprite == .hudHollowTen })
        XCTAssertLessThan(lanternIndex, hollowIndex, "drawn behind the board's face")
        run(game, seconds: 2.2)
        XCTAssertNil(game.touch.count, "the board has gone")
        let after = game.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
        try check(after, lit: true, "while the work runs")
        let cut = try XCTUnwrap(game.touch.framing).deviceY(lift: CountLantern.crookTop) - 0.5
        XCTAssertTrue(after.actors.filter { $0.sprite == .payBoard }.allSatisfy { Double($0.rect.y) >= cut },
                      "the post stands cut to the crook, no higher")
    }

    /// Step 3 (the director's call 6), on the drawn pixels: the same scene rendered with the site lantern burning and
    /// gone out. At night the light round it is warm (the halo and its light add far more red than blue: never
    /// cream-white); by day the halo is still seen beside the lantern. The halo's own tint is warm at any hour, and
    /// while the work runs the post's lit side and the crook carry the warm rim (on the drawn glows: a rendered pixel
    /// there also takes the halo and the wall's light, so it cannot tell the rim apart).
    func testTheLanternsLightIsWarmByNightAndSeenByDay() throws {
        let context = try XCTUnwrap(MetalContext.shared, "No Metal device: see MetalProbeTests")
        let renderer = try Renderer(context: context)
        var settings = RenderSettings()
        settings.time = 2
        // The board's place (so the lantern's post) is worked out once, by day: the plots are things to touch by day
        // only (TouchThings.world), and the gate stands where it stands at any hour.
        let dayGame = model(["GWStage": "world", "GWSeed": "2", "GWCameraX": "1240", "GWDay": "3", "GWClock": "10"])
        _ = dayGame.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
        let gate = try XCTUnwrap(dayGame.touch.things.first { $0.id == "touch-plot-0" })
        let layout = PayBoardLayout.make(PayCount.hollows(price: 90))
        let place = dayGame.countBoardPlace(gate, layout: layout)
        let board = CountBoard(x: place.x, stand: place.x, act: gate.act, layout: layout, side: place.side)
        for night in [true, false] {
            let when = night ? "night" : "day"
            var values = ["GWStage": "world", "GWSeed": "2", "GWCameraX": "1240", "GWWeather": "clear",
                          "GWFlickerTime": "2"]
            if night {
                values["GWNight"] = "3"
                values["GWHour"] = "21.5"
            } else {
                values["GWDay"] = "3"
                values["GWClock"] = "10"
            }
            let game = model(values)
            _ = game.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
            let now = game.clock.elapsed
            let burning = CountLantern(offer: .recruit(.archer), postLeft: board.lanternPostLeft, toward: board.toward,
                                       litAt: now - 2)
            var out = burning
            out.outAt = now
            game.touch.countLanterns = [burning]
            let lit = try renderer.renderOffscreen(game.frame(physicalWidth: pro.physicalWidth,
                                                              physicalHeight: pro.physicalHeight), settings: settings)
            let framing = try XCTUnwrap(game.touch.framing)
            let state = try XCTUnwrap(game.driver?.state)
            var layer = EntityLayer()
            game.countWorld(&layer, state: state, framing: framing)
            game.touch.countLanterns = [out]
            let dark = try renderer.renderOffscreen(game.frame(physicalWidth: pro.physicalWidth,
                                                               physicalHeight: pro.physicalHeight), settings: settings)
            let half = Double(framing.scale) / 2
            /// The mean added light over a 3 x 3 block of game pixels round (`x`, `lift`).
            func added(_ x: Double, _ lift: Double) -> SIMD3<Float> {
                var sum = SIMD3<Float>(0, 0, 0)
                for dx in -1...1 {
                    for dy in -1...1 {
                        let px = Int(framing.deviceX(stageX: x + Double(dx)) + half)
                        let py = Int(framing.deviceY(lift: lift + Double(dy)) - half)
                        sum += lit.color(x: px, y: py) - dark.color(x: px, y: py)
                    }
                }
                return sum / 9
            }
            let lanternLeft = Double(CountLantern.lanternLeft(postLeft: board.lanternPostLeft, toward: board.toward))
            let lanternTop = CountLantern.crookTop - CountLantern.hang
            let middleX = lanternLeft + 4.5
            let middleLift = lanternTop - 7
            let beside = added(middleX + 8 * board.toward, middleLift)
            print("count light \(when): beside \(beside)")
            // The halo's tint (fireWhite, cream, has blue at three quarters of its red; fireGold far less).
            let halo = try XCTUnwrap(layer.glows.first { $0.sprite == .siteHalo }, "\(when): the halo")
            XCTAssertLessThan(halo.color.z, 0.45 * halo.color.x, "\(when): the halo is warm, never cream-white")
            if night {
                XCTAssertGreaterThan(beside.x, 0.04, "the halo is seen at night")
                XCTAssertGreaterThan(beside.x, beside.y, "warm: more red than green")
                XCTAssertGreaterThan(beside.y, beside.z, "warm: more green than blue")
                XCTAssertLessThan(beside.z, 0.7 * beside.x, "never cream-white")
            } else {
                XCTAssertGreaterThan(beside.x, 0.02, "by day the halo is still seen beside the lantern")
                // The rim: a warm glow on each pixel of the post's lit column from the crook's band down past the
                // lantern's foot, and on the crook's arm.
                let rimX = Double(board.lanternPostLeft + (board.toward > 0 ? 3 : 2))
                let rim = layer.glows.filter { $0.sprite == .hallMote && $0.x == rimX }
                XCTAssertGreaterThanOrEqual(rim.count, 10, "by day the post's lit side takes a warm rim (\(rim.count))")
                XCTAssertTrue(rim.allSatisfy { $0.color.x > $0.color.z }, "a warm one")
                let crookRow = layer.glows.filter { $0.sprite == .hallMote && $0.y == CountLantern.crookTop - 2 }
                XCTAssertGreaterThanOrEqual(crookRow.count, 4, "and the crook's arm over the lantern")
            }
        }
    }

    /// Step 3 (the director's call 6): as the lantern catches, three or four embers rise from its cap once, about
    /// 6 px, and are gone; never under Reduce Motion.
    func testEmbersRiseOnceAsTheLanternCatches() throws {
        for still in [false, true] {
            var values = ["GWStage": "world", "GWSeed": "2", "GWDay": "3", "GWClock": "10", "GWCameraX": "1240"]
            if still { values["GWReduceMotion"] = "YES" }
            let game = model(values)
            _ = game.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
            let framing = try XCTUnwrap(game.touch.framing)
            let state = try XCTUnwrap(game.driver?.state)
            let lanternTop = CountLantern.crookTop - CountLantern.hang
            func embers(age: Double) -> [EntityGlow] {
                game.touch.countLanterns = [CountLantern(offer: .recruit(.archer), postLeft: 1200, toward: 1,
                                                         litAt: game.clock.elapsed - age)]
                var layer = EntityLayer()
                game.countWorld(&layer, state: state, framing: framing)
                // The embers are the orange points (the flame's heart is white, the rim gold).
                return layer.glows.filter { $0.sprite == .hallMote && $0.color.y < 0.65 * $0.color.x }
            }
            let rising = embers(age: 0.3)
            let gone = embers(age: 1.2)
            if still {
                XCTAssertTrue(rising.isEmpty, "Reduce Motion: no embers")
            } else {
                XCTAssertTrue((2...4).contains(rising.count), "embers rise (\(rising.count))")
                XCTAssertTrue(rising.contains { $0.y >= lanternTop + 1 }, "over the lantern's top")
                XCTAssertTrue(rising.allSatisfy { $0.y <= lanternTop - 2 + GameModel.countEmberRise + 0.5 },
                              "about 6 px, no higher")
            }
            XCTAssertTrue(gone.isEmpty, "and gone")
        }
    }

    /// The review of step 2: a second recruit's board comes up on the post where the last recruit's lantern still
    /// burns; that lantern gives way, so an unlit lantern is never drawn over a lit one.
    func testANewBoardTakesThePostOfALitLantern() throws {
        let game = model(["GWStage": "world", "GWSeed": "2", "GWDay": "3", "GWClock": "10", "GWCameraX": "1580",
                          "GWGold": "60"])
        _ = game.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
        let thing = try XCTUnwrap(game.touch.things.first { $0.id == "touch-recruit-guard" })
        let layout = PayBoardLayout.make(PayCount.hollows(price: thing.price ?? 14))
        let place = game.countBoardPlace(thing, layout: layout)
        let post = CountBoard(x: place.x, stand: place.x, act: thing.act, layout: layout, side: place.side)
        game.touch.countLanterns = [CountLantern(offer: .recruit(.guardsman), postLeft: post.lanternPostLeft,
                                                 toward: post.toward, litAt: 0)]
        game.touchThing(thing)
        let board = try XCTUnwrap(game.touch.countBoard, "the guard's board comes up")
        XCTAssertEqual(board.lanternPostLeft, post.lanternPostLeft, "on the same post")
        XCTAssertTrue(game.touch.countLanterns.isEmpty, "the lit lantern there gave way")
    }

    /// Step 2's small edges: a count started on another thing lets the old board's coins come home one by one (the
    /// purse ticks up with each) while the new board comes up; nothing is paid.
    func testANewCountLetsTheOldBoardsCoinsComeHome() throws {
        let game = gateGame(gold: 200)
        let hub = SilentFeedback()
        game.feedback = hub
        let gate = try XCTUnwrap(game.touch.things.first { $0.id == "touch-plot-0" })
        game.touchThing(gate)
        run(game, seconds: 10) { game.touch.count?.ready == true }
        var count = try XCTUnwrap(game.touch.count)
        count.press()
        game.touch.count = count
        run(game, seconds: 0.6)
        var lifted = try XCTUnwrap(game.touch.count)
        lifted.lift(tap: false)
        game.touch.count = lifted
        XCTAssertGreaterThan(lifted.placed, 0)
        let other = try XCTUnwrap(game.touch.things.first { thing in
            guard thing.id != gate.id, let found = game.countOffer(thing), let driver = game.driver else {
                return false
            }
            return !PayOffers.refused(found.offer, state: driver.state, balance: driver.balance)
        }, "another thing to buy")
        game.touchThing(other)
        XCTAssertEqual(game.touch.count?.thing, other.id, "the new board")
        XCTAssertEqual(game.touch.countOld?.result, .letGo, "the old one lets its coins go")
        let laid = game.touch.countOld?.placed ?? 0
        XCTAssertGreaterThan(game.countHeld, 0, "its coins are not home yet")
        run(game, seconds: 1)
        XCTAssertNil(game.touch.countOld, "home, and the old board went down")
        XCTAssertEqual(hub.ticks.count, laid, "a soft tick for every coin home")
        XCTAssertEqual(game.driver?.state.gold, 200, "nothing paid")
    }
}
