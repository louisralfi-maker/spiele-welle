/// The build card above a plot (DESIGN.md "The front by day: building", "Screens": the build card; M2b part 2): what
/// the plot is, what it offers now (`Build.options`: the first builds of an empty plot, the next tier, the rubble's
/// rebuild) with price, time and effect; an option the treasury cannot pay is greyed with the missing gold, a plot that
/// opens later is locked with its day. Ordering goes through the simulation (`Build.order`). Pure data; the UI words it.
struct BuildCard: Sendable, Equatable {
    enum Availability: Sendable, Equatable {
        case available
        case tooExpensive(missing: Int)
        case locked(day: Int)
    }

    struct Option: Sendable, Equatable {
        var item: BuildItem
        var price: Int
        /// Real seconds today's builders need for it at today's pace (their walk not counted).
        var seconds: Int
        var isRebuild: Bool
        var availability: Availability

        var canOrder: Bool { availability == .available }
    }

    var plot: Int
    var slot: SlotKind
    /// 1 ... 3 for the defence lines, 0 elsewhere.
    var line: Int
    /// What stands on the plot (or lies there as rubble).
    var current: BuildItem?
    var isRubble: Bool
    /// The job on the plot and how far it is (0 ... 1); a card is never opened on such a plot, but the model says so.
    var jobTarget: BuildItem?
    var jobProgress: Double
    var options: [Option]
    /// The nearest other plot with a card in the king's reach to the left and to the right (the card's arrows).
    var previous: Int?
    var next: Int?

    /// The card of `plot` as the realm stands; `reachable` are the plots the king can open from where he stands.
    static func make(_ s: GameState, plot: Int, balance: Balance, reachable: [Int] = []) -> BuildCard {
        let spec = Realm.plots[plot]
        let state = s.plots[plot]
        let locked = !s.isUnlocked(plot: plot)
        var options: [Option] = []
        for offer in Build.options(s, plot: plot, balance: balance) {
            let availability: Availability
            if locked {
                availability = .locked(day: spec.unlockDay)
            } else if s.gold < offer.price {
                availability = .tooExpensive(missing: offer.price - s.gold)
            } else {
                availability = .available
            }
            options.append(Option(item: offer.item, price: offer.price,
                                  seconds: seconds(offer.item, rebuild: offer.isRebuild, state: s, balance: balance),
                                  isRebuild: offer.isRebuild, availability: availability))
        }
        let neighbours = BuildCard.neighbours(of: plot, among: reachable, state: s, balance: balance)
        return BuildCard(plot: plot, slot: spec.slot, line: spec.line, current: state.item, isRubble: state.isRubble,
                         jobTarget: state.job?.target, jobProgress: state.job?.progress ?? 0, options: options,
                         previous: neighbours.previous, next: neighbours.next)
    }

    /// Real seconds for a job with today's builders: the design's time is for two builders (`Build.work` is
    /// builder-seconds), builders are 20 % faster at happiness 80 and up; rounded up to whole seconds.
    static func seconds(_ item: BuildItem, rebuild: Bool, state s: GameState, balance: Balance) -> Int {
        var pace = Double(max(1, s.builders.count))
        if s.happiness >= balance.fastGrowthFrom { pace *= balance.happyBuildFactor }
        let work = Build.work(item, rebuild: rebuild, balance: balance)
        return max(1, Int((work / pace - 1e-9).rounded(.up)))
    }

    /// The nearest plots of `among` left and right of `plot`, by where they are drawn (equal places by plot id).
    static func neighbours(of plot: Int, among plots: [Int], state s: GameState,
                           balance: Balance) -> (previous: Int?, next: Int?) {
        let layouts = KingTargets.layouts(s, balance: balance)
        let here = KingTargets.spotX(plot: plot, layouts: layouts)
        var previous: (plot: Int, x: Double)?
        var next: (plot: Int, x: Double)?
        for other in plots where other != plot {
            let x = KingTargets.spotX(plot: other, layouts: layouts)
            let isLeft = x < here || (x == here && other < plot)
            if isLeft {
                if previous == nil || x > previous!.x { previous = (other, x) }
            } else {
                if next == nil || x < next!.x { next = (other, x) }
            }
        }
        return (previous?.plot, next?.plot)
    }

    /// The first option that can be ordered now.
    var firstOrderable: Option? { options.first { $0.canOrder } }
}

/// The barracks' card (DESIGN.md "The front by day: building": the barracks recruit archers and guards; a taxpayer
/// becomes a soldier): the two kinds with their price, greyed with the missing gold, closed when nobody is left who
/// pays taxes; how many there are and how many archer posts stand free.
struct RecruitCard: Sendable, Equatable {
    enum Availability: Sendable, Equatable {
        case available
        case tooExpensive(missing: Int)
        case noOneLeft
    }

    struct Option: Sendable, Equatable {
        var kind: SoldierKind
        var price: Int
        var availability: Availability

        var canRecruit: Bool { availability == .available }
    }

    var archers: Int
    var guards: Int
    /// Archer posts on standing walls and towers with nobody assigned to them (archers beyond the posts wait in the
    /// keep).
    var freePosts: Int
    var taxpayers: Int
    var options: [Option]

    static func make(_ s: GameState, balance: Balance) -> RecruitCard {
        var options: [Option] = []
        for kind in SoldierKind.allCases {
            let price = kind == .archer ? balance.archerPrice : balance.guardPrice
            let availability: Availability
            if s.taxpayers <= 0 {
                availability = .noOneLeft
            } else if s.gold < price {
                availability = .tooExpensive(missing: price - s.gold)
            } else {
                availability = .available
            }
            options.append(Option(kind: kind, price: price, availability: availability))
        }
        let posts = Battle.posts(s, balance: balance).count
        return RecruitCard(archers: s.archerCount, guards: s.guardCount, freePosts: max(0, posts - s.archerCount),
                           taxpayers: s.taxpayers, options: options)
    }
}

/// The tax lectern beside the throne (DESIGN.md "Taxes": Low, Normal, High and from story day 8 War tax, set any time
/// by day): each rate with its share of the taxes, its happiness change at dawn and the taxes it would bring at the
/// next dawn as the realm stands now.
struct TaxCard: Sendable, Equatable {
    struct Option: Sendable, Equatable {
        var rate: TaxRate
        /// The rate's multiplier in per cent (60, 100, 140, 180).
        var percent: Int
        /// Happiness at every dawn (+3, 0, −7, −10).
        var happiness: Int
        /// Taxes at the next dawn at this rate and today's happiness.
        var forecast: Int
        var isCurrent: Bool
        /// The war tax before it unlocks: the day it does.
        var lockedUntil: Int?
    }

    var options: [Option]
    var current: TaxRate

    static func make(_ s: GameState, balance: Balance) -> TaxCard {
        var options: [Option] = []
        for rate in TaxRate.allCases {
            var trial = s
            trial.tax = rate
            let forecast = Economy.taxes(trial, happiness: s.happiness, balance: balance).total
            let locked = rate == .war && !s.warTaxUnlocked
            options.append(Option(rate: rate, percent: Int((balance.rate(rate) * 100).rounded()),
                                  happiness: balance.happinessChange(rate), forecast: forecast,
                                  isCurrent: s.tax == rate, lockedUntil: locked ? Realm.warTaxDay : nil))
        }
        return TaxCard(options: options, current: s.tax)
    }
}
