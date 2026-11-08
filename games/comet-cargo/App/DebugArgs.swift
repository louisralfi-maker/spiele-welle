import Foundation

/// Launch arguments that let UI tests and screenshots reach any state (DESIGN.md "Debug launch arguments").
struct DebugArgs: Sendable, Equatable {
    var reset = false
    var autoplay = false
    var coins: Int?
    /// "mid" or "max".
    var upgrades: String?
    /// "demo".
    var network: String?
    /// "results".
    var screen: String?

    static func fromProcess() -> DebugArgs {
        let defaults = UserDefaults.standard
        var args = DebugArgs()
        args.reset = defaults.bool(forKey: "GWReset")
        args.autoplay = defaults.bool(forKey: "GWAutoplay")
        if defaults.object(forKey: "GWCoins") != nil {
            args.coins = defaults.integer(forKey: "GWCoins")
        }
        args.upgrades = defaults.string(forKey: "GWUpgrades")
        args.network = defaults.string(forKey: "GWNetwork")
        args.screen = defaults.string(forKey: "GWScreen")
        return args
    }

    var changesSave: Bool {
        reset || coins != nil || upgrades != nil || network != nil
    }

    func apply(to save: inout SaveGame) {
        if let coins { save.coins = max(0, coins) }
        switch upgrades {
        case "mid": save.levels = .mid
        case "max": save.levels = .maxed
        default: break
        }
        if network == "demo" {
            save.ringDeliveries = [5, 5, 5, 5, 4, 3, 3, 2, 1, 1, 0, 0, 0, 0, 0]
            save.bestApex = 420
            save.lastApex = 384
        }
        save.normalize()
    }

    /// The fixed sample flight `-GWScreen results` opens with (nothing is booked).
    static let sampleSettlement: Economy.Settlement = {
        var settlement = Economy.Settlement()
        settlement.deliveries = [
            Delivery(ring: 5, rating: .perfect, pay: Economy.deliveryPay(ring: 5, rating: .perfect), altitude: 150.2, tick: 2_400),
            Delivery(ring: 6, rating: .great, pay: Economy.deliveryPay(ring: 6, rating: .great), altitude: 202.1, tick: 2_900),
            Delivery(ring: 7, rating: .good, pay: Economy.deliveryPay(ring: 7, rating: .good), altitude: 255.9, tick: 3_500),
        ]
        settlement.drops = [.perfect, .great, .perfect]
        settlement.lost = 1
        settlement.deliveryPay = settlement.deliveries.reduce(0) { $0 + $1.pay }
        settlement.completedRings = [5]
        settlement.bonusPay = Economy.ringBonus(5)
        settlement.apex = 284
        settlement.newBest = true
        return settlement
    }()
}
