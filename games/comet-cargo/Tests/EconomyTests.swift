import XCTest
@testable import CometCargo

final class EconomyTests: XCTestCase {
    func testBasePayRunsFrom5To271() {
        XCTAssertEqual((0..<Rings.count).map(Rings.basePay), [5, 7, 9, 12, 16, 21, 28, 37, 49, 65, 87, 115, 153, 204, 271])
    }

    func testDeliveryPayByRating() {
        XCTAssertEqual(Economy.deliveryPay(ring: 4, rating: .perfect), 32)
        XCTAssertEqual(Economy.deliveryPay(ring: 4, rating: .great), 24)
        XCTAssertEqual(Economy.deliveryPay(ring: 4, rating: .good), 16)
        XCTAssertEqual(Economy.deliveryPay(ring: 1, rating: .great), 11, "7 × 1.5 = 10.5 rounds up")
        XCTAssertEqual(Economy.deliveryPay(ring: nil, rating: .lost), 0)
    }

    func testPrices() {
        XCTAssertEqual(Economy.price(.engines, level: 0), 60)
        XCTAssertEqual(Economy.price(.engines, level: 1), 108)
        XCTAssertEqual(Economy.price(.tanks, level: 9), 11_902)
        XCTAssertNil(Economy.price(.engines, level: 10))
        XCTAssertEqual(Economy.price(.stages, level: 2), 800)
        XCTAssertEqual(Economy.price(.stages, level: 4), 60_000)
        XCTAssertNil(Economy.price(.stages, level: 5))
        XCTAssertEqual(Economy.price(.cargo, level: 2), 150)
        XCTAssertNil(Economy.price(.cargo, level: 6))
        XCTAssertEqual(Economy.price(.guidance, level: 0), 50)
        XCTAssertEqual(Economy.price(.guidance, level: 4), 525)
        XCTAssertNil(Economy.price(.guidance, level: 5))
    }

    func testFifthDeliveryCompletesTheRingOnce() {
        var save = SaveGame()
        save.ringDeliveries[3] = 4
        let delivery = Delivery(ring: 3, rating: .perfect, pay: 24, altitude: 80, tick: 100)
        let result = FlightResult(apex: 90, flightTime: 20, drops: [], deliveries: [delivery, delivery], lost: 0)
        let settlement = Economy.settle(result, into: &save)
        XCTAssertEqual(settlement.completedRings, [3])
        XCTAssertEqual(settlement.bonusPay, 120)
        XCTAssertEqual(settlement.deliveryPay, 48)
        XCTAssertEqual(save.coins, 168)
        XCTAssertEqual(save.ringDeliveries[3], 6)
        XCTAssertTrue(save.isComplete(3))
        let again = Economy.settle(result, into: &save)
        XCTAssertEqual(again.bonusPay, 0, "The bonus comes once")
    }

    func testSettleTracksBestAndLostSatellites() {
        var save = SaveGame()
        save.bestApex = 100
        let lostOne = Delivery(ring: nil, rating: .lost, pay: 0, altitude: 45, tick: 10)
        let result = FlightResult(apex: 130, flightTime: 25, drops: [], deliveries: [lostOne], lost: 1)
        let settlement = Economy.settle(result, into: &save)
        XCTAssertTrue(settlement.newBest)
        XCTAssertEqual(settlement.lost, 2)
        XCTAssertEqual(save.bestApex, 130)
        XCTAssertEqual(save.lastApex, 130)
        XCTAssertEqual(save.flights, 1)
        XCTAssertEqual(save.coins, 0)
    }

    func testBuyingNeedsCoinsAndStopsAtTheTop() {
        var save = SaveGame()
        XCTAssertFalse(Economy.buy(.engines, in: &save))
        save.coins = 100
        XCTAssertTrue(Economy.buy(.engines, in: &save))
        XCTAssertEqual(save.levels.engines, 1)
        XCTAssertEqual(save.coins, 40)
        save.levels.stages = 5
        save.coins = 1_000_000
        XCTAssertFalse(Economy.canBuy(.stages, in: save))
        XCTAssertFalse(Economy.buy(.stages, in: &save))
    }

    func testAFullFlightPaysForItsDeliveries() {
        var save = SaveGame()
        let sim = Autopilot.fly(RocketConfig(levels: .starter))
        let settlement = Economy.settle(sim.result, into: &save)
        XCTAssertEqual(settlement.total, 56, "Perfect into rings 4 and 5: 24 + 32")
        XCTAssertEqual(save.coins, 56)
    }
}
