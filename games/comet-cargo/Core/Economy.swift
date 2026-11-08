import Foundation

/// Prices, pay and the ring network. Coins come only from deliveries and ring bonuses.
///
/// Prices are tuned so the economy bot of tools/tune.py (Perfect drops, satellites at ring centres, the best affordable
/// apex gain per coin after each flight) first delivers into ring 15 after 112 flights (target 90 to 180). The design's
/// start prices (20 × 1.42^L) let it get there in 13 flights. The first engines and tanks level costs only 30, so even a
/// so-so first flight ends with a purchase.
enum Economy {
    static let ringSlots = 5
    static let ringBonusFactor = 10
    static let firstLevelPrice = 30
    static let stagePrices = [800, 10_000, 60_000]
    static let cargoPrices = [150, 800, 3_000, 10_000]

    /// Price of the step from `level` to `level + 1`, or nil when the track is maxed.
    static func price(_ track: UpgradeTrack, level: Int) -> Int? {
        guard level < track.maxLevel, level >= track.minLevel else { return nil }
        switch track {
        case .engines, .tanks:
            if level == 0 { return firstLevelPrice }
            return Int((60.0 * pow(1.8, Double(level))).rounded())
        case .stages:
            return stagePrices[level - 2]
        case .cargo:
            return cargoPrices[level - 2]
        case .guidance:
            return Int((50.0 * pow(1.8, Double(level))).rounded())
        }
    }

    static func deliveryPay(ring: Int?, rating: ReleaseRating) -> Int {
        guard let ring else { return 0 }
        return Int((Double(Rings.basePay(ring)) * rating.payMultiplier).rounded())
    }

    static func ringBonus(_ ring: Int) -> Int {
        ringBonusFactor * Rings.basePay(ring)
    }

    /// One ring this flight delivered to: its slot count before and after, and the bonus if the flight completed it.
    struct RingProgress: Codable, Sendable, Equatable {
        var ring: Int
        var before: Int
        var after: Int
        var completed: Bool
        var bonus: Int
    }

    /// What a flight earned, line by line, for the results screen.
    struct Settlement: Codable, Sendable, Equatable {
        var deliveries: [Delivery] = []
        var drops: [DropRating] = []
        var lost = 0
        var deliveryPay = 0
        /// Rings completed by this flight with their bonus.
        var completedRings: [Int] = []
        var bonusPay = 0
        var apex = 0.0
        var newBest = false
        /// Every ring delivered to, ascending.
        var progress: [RingProgress] = []
        /// Stages the rocket never used (it fell back while a spent stage was still attached).
        var unusedStages = 0
        /// Coins after booking, and the cheapest upgrade left, for the "next upgrade" strip.
        var coinsAfter = 0
        var nextTrack: UpgradeTrack?
        var nextPrice = 0
        var total: Int { deliveryPay + bonusPay }
    }

    /// Books a finished flight into the save: coins, ring slots, completion bonuses, best and last apex.
    static func settle(_ result: FlightResult, into save: inout SaveGame) -> Settlement {
        var settlement = Settlement()
        settlement.deliveries = result.deliveries
        settlement.drops = result.drops.map(\.rating)
        settlement.apex = result.apex
        settlement.lost = result.lost + result.deliveries.filter { $0.ring == nil }.count
        settlement.unusedStages = result.unusedStages
        save.normalize()
        var before: [Int: Int] = [:]
        for delivery in result.deliveries {
            settlement.deliveryPay += delivery.pay
            guard let ring = delivery.ring, ring >= 0, ring < save.ringDeliveries.count else { continue }
            if before[ring] == nil { before[ring] = save.ringDeliveries[ring] }
            save.ringDeliveries[ring] += 1
            if save.ringDeliveries[ring] == ringSlots {
                settlement.completedRings.append(ring)
                settlement.bonusPay += ringBonus(ring)
            }
        }
        save.coins += settlement.total
        settlement.newBest = result.apex > save.bestApex
        save.bestApex = max(save.bestApex, result.apex)
        save.lastApex = result.apex
        save.flights += 1
        settlement.progress = progress(before: before, save: save)
        settlement.coinsAfter = save.coins
        if let next = cheapestUpgrade(in: save) {
            settlement.nextTrack = next.track
            settlement.nextPrice = next.price
        }
        return settlement
    }

    /// The ring lines for the results: slot counts before and after the flight, ascending by ring.
    static func progress(before: [Int: Int], save: SaveGame) -> [RingProgress] {
        var lines: [RingProgress] = []
        for ring in before.keys.sorted() {
            let start = before[ring] ?? 0
            let after = save.ringDeliveries[ring]
            let completed = start < ringSlots && after >= ringSlots
            let bonus = completed ? ringBonus(ring) : 0
            lines.append(RingProgress(ring: ring, before: start, after: after, completed: completed, bonus: bonus))
        }
        return lines
    }

    /// The upgrade with the lowest price that is not maxed yet.
    static func cheapestUpgrade(in save: SaveGame) -> (track: UpgradeTrack, price: Int)? {
        var best: (track: UpgradeTrack, price: Int)?
        for track in UpgradeTrack.allCases {
            guard let cost = price(track, level: save.levels[track]) else { continue }
            if let current = best, current.price <= cost { continue }
            best = (track, cost)
        }
        return best
    }

    static func canBuy(_ track: UpgradeTrack, in save: SaveGame) -> Bool {
        guard let cost = price(track, level: save.levels[track]) else { return false }
        return save.coins >= cost
    }

    /// Buys one level; false when maxed or too expensive.
    @discardableResult
    static func buy(_ track: UpgradeTrack, in save: inout SaveGame) -> Bool {
        guard let cost = price(track, level: save.levels[track]), save.coins >= cost else { return false }
        save.coins -= cost
        save.levels[track] += 1
        return true
    }
}
