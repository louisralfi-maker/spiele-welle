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
        _ = run(&count, seconds: 0.1, gold: 100)
        XCTAssertEqual(count.placed, 1, "a tap sets one coin")
        count.tap()
        count.tap()
        _ = run(&count, seconds: 0.3, gold: 100)
        XCTAssertEqual(count.placed, 3, "every tap one coin")
        // A quick press that set no coin is a tap.
        count.press()
        count.lift(tap: true)
        _ = run(&count, seconds: 0.1, gold: 100)
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
        XCTAssertEqual(seals(run(&atOnce, seconds: 0.2, gold: 100)), 1, "VoiceOver pays in one step")
    }

    func testTheBoardRisesAndTheCoinsSlideInTheirTime() {
        var count = PayCount(thing: "t", offer: .patch(plot: 0), price: 20, holding: false)
        XCTAssertEqual(count.riseShare, 0)
        _ = run(&count, seconds: PayCount.boardDelay + 0.01, gold: 100)
        XCTAssertEqual(count.riseShare, 1, "up 0.15 s after the touch")
        count.arrive()
        count.tap()
        _ = run(&count, seconds: 0.1, gold: 100)
        XCTAssertNil(count.slideShare, "the coin lies on the board")
        var beats: [PayBeat] = []
        while !beats.contains(.slideBack) { beats += count.step(step, gold: 100) }
        XCTAssertEqual(count.result, .letGo, "two seconds without a touch")
        XCTAssertEqual(count.slideShare ?? -1, 0, accuracy: 0.06, "the slide starts")
        _ = run(&count, seconds: PayCount.slideSeconds + step, gold: 100)
        XCTAssertEqual(count.slideShare ?? 0, 1, accuracy: 1e-9, "back in 0.3 s")
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
        run(game, seconds: 1)
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
        XCTAssertEqual(game.purse.target, 200 - held, "the purse shows the coins on the board as gone")
        XCTAssertEqual(game.purse.shown, 200 - held, "the figure in step with the board, never trailing it")
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
        XCTAssertTrue(frame.actors.contains { $0.sprite == .siteLantern && $0.frame == 0 }, "the lantern unlit")
        XCTAssertTrue(frame.actors.contains { $0.sprite == .hudCoinTen }, "the first coin rocks over its hollow")
    }
}
