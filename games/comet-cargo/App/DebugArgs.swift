import Foundation

/// Launch arguments that let UI tests and screenshots reach any state (DESIGN.md "Debug launch arguments").
struct DebugArgs: Sendable, Equatable {
    var reset = false
    var autoplay = false
    /// No first-flight hints (UI tests that play by hand).
    var skipOnboarding = false
    var coins: Int?
    /// "mid" or "max".
    var upgrades: String?
    /// Exact upgrade levels "engines,tanks,stages,cargo,guidance" (`-GWLevels 7,7,4,5,3`); wins over `upgrades`.
    var levels: UpgradeLevels?
    /// "demo" or "grown".
    var network: String?
    /// "results" (the sample report) or "report" (the store-shot report).
    var screen: String?
    /// `-GWFreeze <seconds>`: the flight starts at once and stands still at this second of its clock (store shots).
    var freeze: Double?
    /// `-GWStoreShot <n>`: App Store screenshot n (`StoreShot`): its caption band above the scaled-down live screen.
    var storeShot: Int?

    static func fromProcess() -> DebugArgs {
        let defaults = UserDefaults.standard
        var args = DebugArgs()
        args.reset = defaults.bool(forKey: "GWReset")
        args.autoplay = defaults.bool(forKey: "GWAutoplay")
        args.skipOnboarding = defaults.bool(forKey: "GWSkipOnboarding")
        if defaults.object(forKey: "GWCoins") != nil {
            args.coins = defaults.integer(forKey: "GWCoins")
        }
        args.upgrades = defaults.string(forKey: "GWUpgrades")
        args.levels = defaults.string(forKey: "GWLevels").flatMap(DebugArgs.parseLevels)
        args.network = defaults.string(forKey: "GWNetwork")
        args.screen = defaults.string(forKey: "GWScreen")
        if defaults.object(forKey: "GWFreeze") != nil {
            let seconds = defaults.double(forKey: "GWFreeze")
            if seconds.isFinite && seconds > 0 { args.freeze = min(seconds, 300) }
        }
        if defaults.object(forKey: "GWStoreShot") != nil {
            args.storeShot = defaults.integer(forKey: "GWStoreShot")
        }
        return args
    }

    /// "7,7,4,5,3" → engines 7, tanks 7, 4 stages, 5 satellites, guidance 3 (clamped to each track's range); nil unless
    /// there are exactly five whole numbers.
    static func parseLevels(_ text: String) -> UpgradeLevels? {
        let numbers = text.split(separator: ",").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
        guard numbers.count == 5 else { return nil }
        var levels = UpgradeLevels(engines: numbers[0], tanks: numbers[1], stages: numbers[2], cargo: numbers[3],
                                   guidance: numbers[4])
        levels.clamp()
        return levels
    }

    /// Store shots: every animation of the hangar and the report stands in its end state, no sound, no vibration.
    var still: Bool { storeShot != nil }

    /// Hints are off while the autopilot plays, with -GWSkipOnboarding YES, in a frozen flight and in store shots.
    var hintsAllowed: Bool { !autoplay && !skipOnboarding && freeze == nil && storeShot == nil }

    var changesSave: Bool {
        reset || coins != nil || upgrades != nil || levels != nil || network != nil
    }

    func apply(to save: inout SaveGame) {
        if let coins { save.coins = max(0, coins) }
        switch upgrades {
        case "mid": save.levels = .mid
        case "max": save.levels = .maxed
        default: break
        }
        if let levels { save.levels = levels }
        switch network {
        case "demo":
            save.ringDeliveries = [5, 5, 5, 5, 4, 3, 3, 2, 1, 1, 0, 0, 0, 0, 0]
            save.bestApex = 420
            save.lastApex = 384
        case "grown":
            // Store shots: seven gold rings, the next five filling up, best 612 km (the next goal is ring 13).
            save.ringDeliveries = [5, 5, 5, 5, 5, 5, 5, 4, 3, 2, 1, 0, 0, 0, 0]
            save.bestApex = 612
            save.lastApex = 598
        default:
            break
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
        settlement.progress = [
            Economy.RingProgress(ring: 5, before: 4, after: 5, completed: true, bonus: Economy.ringBonus(5)),
            Economy.RingProgress(ring: 6, before: 1, after: 2, completed: false, bonus: 0),
            Economy.RingProgress(ring: 7, before: 0, after: 1, completed: false, bonus: 0),
        ]
        settlement.coinsAfter = 420
        settlement.nextTrack = .engines
        settlement.nextPrice = 583
        return settlement
    }()

    /// The store-shot report `-GWScreen report` opens with (nothing is booked): two Perfect deliveries, ring 10 completed
    /// (gold, with its bonus) and a new best. Short enough that the ring network card with the gold ring stands above the
    /// Collect bar on the 6.9-inch screen.
    static let storeSettlement: Economy.Settlement = {
        var settlement = Economy.Settlement()
        settlement.deliveries = [
            Delivery(ring: 8, rating: .perfect, pay: Economy.deliveryPay(ring: 8, rating: .perfect), altitude: 330.1, tick: 3_180),
            Delivery(ring: 9, rating: .perfect, pay: Economy.deliveryPay(ring: 9, rating: .perfect), altitude: 410.2, tick: 3_700),
        ]
        settlement.drops = [.perfect, .perfect, .perfect]
        settlement.lost = 0
        settlement.deliveryPay = settlement.deliveries.reduce(0) { $0 + $1.pay }
        settlement.completedRings = [9]
        settlement.bonusPay = Economy.ringBonus(9)
        settlement.apex = 452
        settlement.newBest = true
        settlement.progress = [
            Economy.RingProgress(ring: 8, before: 2, after: 3, completed: false, bonus: 0),
            Economy.RingProgress(ring: 9, before: 4, after: 5, completed: true, bonus: Economy.ringBonus(9)),
        ]
        settlement.coinsAfter = 2_140
        settlement.nextTrack = .cargo
        settlement.nextPrice = 3_000
        return settlement
    }()
}
