/// What the action button offers the king where he stands (DESIGN.md "Controls": one context action button whose icon
/// names what is in front of him; M2b part 2).
///
/// - By day: a plot's build card (hammer: build, upgrade or rebuild; also at a plot that is still locked, so its card
///   tells the unlock day), the barracks' recruit card (coins) and the throne's tax card (crown; the audience comes in
///   M3, and talking to the court in M3 too).
/// - From the horn to dawn: light a snuffed brazier or patch a damaged wall (`Sim.kingAction`); the barracks still
///   recruit (`Build.recruit` posts a recruit at once at night).
///
/// The nearest target in reach (`Balance.kingReach`) wins; a plot counts where its structure is drawn (its marker and
/// scaffolding), so the king stops where the player sees it.
enum KingTarget: Sendable, Equatable {
    case build(plot: Int)
    case recruit
    case throne
    case light(plot: Int)
    case patch(plot: Int)
}

/// Why an offered night action cannot be done right now: the button shows it greyed (M2b review: Patch offered without
/// the gold or during its cooldown, and Light pressed while he was lighting, did nothing at all).
enum KingTargetHold: Sendable, Equatable {
    /// Patch: this much gold is missing.
    case missingGold(Int)
    /// Patch: the share of the cooldown still to run (1 just after a patch), in sixteenths.
    case cooldown(Double)
    /// Light: he is lighting a brazier already.
    case busy
}

enum KingTargets {
    /// The barracks' door: the middle of the drawn barracks in the courtyard.
    static let barracksX = EntityFrames.barracksLeft + Double(SpriteID.barracks.size.width) / 2
    /// The throne in the great hall (the tax lectern stands beside it).
    static let throneX = Realm.throneX

    /// Where the lines' parts are drawn now.
    static func layouts(_ s: GameState, balance: Balance) -> [LineLayout] {
        (0..<Realm.lines.count).map { EntityFrames.lineLayout($0, state: s, balance: balance) }
    }

    /// Where the king stands to work on a plot: where its structure, marker or scaffolding is drawn (line 1's engine
    /// plot by its marker on the ground, below the wall walk).
    static func spotX(plot: Int, layouts: [LineLayout]) -> Double {
        let spec = Realm.plots[plot]
        if spec.line == 1 && spec.slot == .engine { return spec.x }
        return EntityFrames.drawnCentre(plot: plot, layouts: layouts).x
    }

    /// True when the plot's card has something to order (locked offers included); never while a job runs.
    static func hasCard(_ s: GameState, plot: Int, balance: Balance) -> Bool {
        !Build.options(s, plot: plot, balance: balance).isEmpty
    }

    /// The plots whose card the king can open from `x`, nearest first (ties: the lower plot id).
    static func buildPlots(_ s: GameState, balance: Balance, near x: Double, layouts: [LineLayout]) -> [Int] {
        var list: [(plot: Int, distance: Double)] = []
        for plot in Realm.plots.indices where plot < s.plots.count && hasCard(s, plot: plot, balance: balance) {
            let distance = abs(spotX(plot: plot, layouts: layouts) - x)
            if distance <= balance.kingReach { list.append((plot, distance)) }
        }
        list.sort { $0.distance == $1.distance ? $0.plot < $1.plot : $0.distance < $1.distance }
        return list.map(\.plot)
    }

    /// The same, with the lines laid out as they are now.
    static func buildPlots(_ s: GameState, balance: Balance, near x: Double) -> [Int] {
        buildPlots(s, balance: balance, near: x, layouts: layouts(s, balance: balance))
    }

    /// What the action button offers now; nil when there is nothing to do (the button hides).
    static func target(_ s: GameState, balance: Balance) -> KingTarget? {
        guard !s.defeated else { return nil }
        let x = s.king.x
        let reach = balance.kingReach
        if DayClock.phase(at: s.hour) != .day {
            if let action = Sim.kingAction(s, balance: balance) {
                switch action {
                case .light(let plot): return .light(plot: plot)
                case .patch(let plot): return .patch(plot: plot)
                }
            }
            return abs(x - barracksX) <= reach ? .recruit : nil
        }
        var best: KingTarget?
        var bestDistance = Double.infinity
        func consider(_ target: KingTarget, _ distance: Double) {
            guard distance <= reach, distance < bestDistance else { return }
            best = target
            bestDistance = distance
        }
        let drawn = layouts(s, balance: balance)
        if let plot = buildPlots(s, balance: balance, near: x, layouts: drawn).first {
            consider(.build(plot: plot), abs(spotX(plot: plot, layouts: drawn) - x))
        }
        consider(.recruit, abs(x - barracksX))
        consider(.throne, abs(x - throneX))
        return best
    }

    /// What the hammer does at a plot: build on an empty plot, upgrade what stands, rebuild rubble (the caption says
    /// which, M2b review).
    enum BuildVerb: Sendable, Equatable {
        case build, upgrade, rebuild
    }

    static func verb(_ s: GameState, plot: Int) -> BuildVerb {
        let state = s.plots[plot]
        if state.item != nil && state.isRubble { return .rebuild }
        return state.item == nil ? .build : .upgrade
    }

    /// What keeps `target` from being done now, nil when the button acts at once.
    static func hold(_ target: KingTarget, state s: GameState, balance: Balance) -> KingTargetHold? {
        switch target {
        case .patch:
            if s.king.patchCooldown > 0 {
                let share = min(1, s.king.patchCooldown / max(0.001, balance.patchCooldown))
                return .cooldown((share * 16).rounded(.up) / 16)
            }
            if s.gold < balance.patchCost { return .missingGold(balance.patchCost - s.gold) }
            return nil
        case .light:
            return s.king.lightingPlot >= 0 ? .busy : nil
        case .build, .recruit, .throne:
            return nil
        }
    }

    /// The world x of a target, for placing its card over it.
    static func anchorX(_ target: KingTarget, state s: GameState, balance: Balance) -> Double {
        switch target {
        case .build(let plot), .light(let plot), .patch(let plot):
            return spotX(plot: plot, layouts: layouts(s, balance: balance))
        case .recruit:
            return barracksX
        case .throne:
            return throneX
        }
    }
}
