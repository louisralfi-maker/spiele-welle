/// The craftsmen's works in the simulation (docs/TOWN.md section 4): when a work stands, and its one small effect.
/// Every effect is behind its flag, the work standing (`CraftState.stands`), and read through three hooks:
///
/// - `balance(_:for:)`: at the top of `Sim.step` and `Sim.patch`, the step plays with a balance that the standing
///   works changed by values (the bell, the glass, the mortar, the banners, the handcarts, the road lanterns, the
///   pitch, the gate bands). With no work standing it is the balance itself, so nothing moves.
/// - `houseCoins(_:happiness:balance:)`: in `Economy.taxes` (the statue).
/// - `dawn(_:)`: in `PetitionEngine.dawn`, works whose day has come stand (the portrait's happiness once).
///
/// Every effect moves its own number by about 4 %, at least 2 % and at most 6 %
/// (`CraftTests.testNoWorkMovesItsSystemMoreThanAboutFivePercent`: the statue, the road lanterns and the portrait in the
/// reference bots' runs, every other work in its scene of play, `CraftMeasures`).
enum CraftWorks {
    /// The balance a step plays with: `base` changed by every standing work.
    static func balance(_ base: Balance, for s: GameState, book: CraftBook = .standard) -> Balance {
        guard let craft = s.craft, craft.anyStands else { return base }
        var b = base
        for order in craft.works where order.stands {
            guard let c = book.craftsman(order.id) else { continue }
            apply(c.effect, amount: c.amount, to: &b)
        }
        return b
    }

    /// One work's change of the balance (the statue and the portrait work elsewhere).
    static func apply(_ effect: CraftEffect, amount: Double, to b: inout Balance) {
        switch effect {
        case .rallyReach:
            b.rallyRadius *= 1 + amount
        case .lightRadius:
            b.brazierRadius *= 1 + amount
            b.fireTowerRadius *= 1 + amount
        case .patchShare:
            b.patchShare = min(1, b.patchShare + amount)
        case .guardHold:
            b.guardRetreatShare = max(0, b.guardRetreatShare - amount)
        case .builderWalk:
            b.builderSpeed *= 1 + amount
        case .unrestLine:
            let lower = Int(amount.rounded())
            b.unrestBelow = max(0, b.unrestBelow - lower)
            b.grumbleBelow = max(0, b.grumbleBelow - lower)
        case .fireArrowStrike:
            b.fireArrowStrike *= 1 + amount
        case .gateStrength:
            b.gateHP = b.gateHP.map { $0 * (1 + amount) }
        case .houseCoin, .happinessOnce:
            break
        }
    }

    /// The statue: coins each house adds to the dawn's taxes, while happiness is at the growth line or above.
    static func houseCoins(_ s: GameState, happiness: Int, balance: Balance, book: CraftBook = .standard) -> Int {
        guard let craft = s.craft, craft.anyStands, happiness >= balance.growthFrom else { return 0 }
        var coins = 0
        for order in craft.works where order.stands {
            guard let c = book.craftsman(order.id), c.effect == .houseCoin else { continue }
            coins += Int(c.amount.rounded()) * (s.count(.house) + s.count(.bigHouse))
        }
        return coins
    }

    /// The dawn (the hook in `PetitionEngine.dawn`, after the economy): works whose day has come stand; the portrait's
    /// happiness comes once, as it is hung. Returns the craftsmen whose works stood up this dawn.
    @discardableResult
    static func dawn(_ s: inout GameState, book: CraftBook = .standard) -> [String] {
        guard var craft = s.craft, craft.works.contains(where: { !$0.stands && $0.readyDay <= s.day }) else { return [] }
        var done: [String] = []
        for index in craft.works.indices where !craft.works[index].stands && craft.works[index].readyDay <= s.day {
            craft.works[index].stands = true
            done.append(craft.works[index].id)
            if let c = book.craftsman(craft.works[index].id), c.effect == .happinessOnce {
                s.happiness = min(100, max(0, s.happiness + Int(c.amount.rounded())))
            }
        }
        s.craft = craft
        return done
    }

    /// The craftsmen whose works stand, in the order they were commissioned (the world draws them after the join).
    static func standing(_ s: GameState) -> [String] {
        (s.craft?.works ?? []).filter(\.stands).map(\.id)
    }

    /// Works that stand in the town (the town's standing, docs/TOWN.md section 3, counts one point for each).
    static func townWorks(_ s: GameState, book: CraftBook = .standard) -> Int {
        standing(s).filter { book.craftsman($0)?.place == .town }.count
    }
}
