/// What the action button offers the king where he stands (DESIGN.md "Controls": one context action button whose icon
/// names what is in front of him; M2b part 2).
///
/// - By day: a plot's build card (hammer: build, upgrade or rebuild; also at a plot that is still locked, so its card
///   tells the unlock day), the barracks' recruit card (coins), the throne (crown: the audience while petitioners wait
///   in the hall, else the tax card), and from M3 the tax lectern beside it, the Stranger at the front gate and the
///   court member or guest in talking reach (a speech bubble).
/// - From the horn to dawn: light a snuffed brazier or patch a damaged wall (`Sim.kingAction`); the barracks still
///   recruit (`Build.recruit` posts a recruit at once at night).
///
/// The nearest target in reach (`Balance.kingReach`) wins; a plot counts where its structure is drawn (its marker and
/// scaffolding), so the king stops where the player sees it.
enum KingTarget: Sendable, Equatable {
    case build(plot: Int)
    case recruit
    /// The throne: the audience while petitioners wait in the hall, else the tax card (M3).
    case throne
    /// The tax lectern beside the throne, its own place (M3).
    case lectern
    /// A court member or guest to talk to, by day (M3).
    case talk(who: String)
    /// The Stranger asking at the front gate (M3).
    case stranger
    case light(plot: Int)
    case patch(plot: Int)
}

enum KingTargets {
    /// The barracks' door: the middle of the drawn barracks in the courtyard.
    static let barracksX = EntityFrames.barracksLeft + Double(SpriteID.barracks.size.width) / 2
    /// The throne in the great hall (the tax lectern stands beside it).
    static let throneX = Realm.throneX
    /// The tax lectern's middle (M3: its own place beside the throne).
    static let lecternX = CourtLayout.lecternX + Double(SpriteID.taxLectern.size.width) / 2
    /// A court member counts this much farther than he stands, so the lectern, the throne or a plot beside him wins a
    /// close call (Odile steps up to the lectern now and then).
    static let talkBias = 6.0

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
        // M3: the lectern, the Stranger at the gate, the court to talk to (`CourtTalk`, closer than the reach).
        consider(.lectern, abs(x - lecternX))
        if AudienceRules.gate(s, catalog: .standard) != nil {
            consider(.stranger, abs(x - CourtLayout.strangerAtGate))
        }
        // People walk, places stand: a court member yields a close call to the place beside him (`talkBias`).
        if let near = CourtTalk.nearest(s, figures: CourtLayout.figures(s, catalog: .standard), lines: .standard) {
            consider(.talk(who: near.who), abs(near.x - x) + talkBias)
        }
        return best
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
        case .lectern:
            return lecternX
        case .stranger:
            return CourtLayout.strangerAtGate
        case .talk(let who):
            return CourtLayout.figures(s, catalog: .standard).first { $0.who == who }?.x ?? s.king.x
        }
    }
}
