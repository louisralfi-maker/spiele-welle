import Foundation

/// What offers something on a stage now (stage lane, step stage-2; DESIGN.md "Controls 2: touch the world"): every
/// thing the finger can send the lord to, with its touch area's size, its standing place, its mark and its rank. Pure
/// functions of the realm's state and the figures as drawn; `GameModel+Touch.swift` asks for them a few times a
/// second.
///
/// - **The world:** by day every plot whose card offers something and is open (an empty site, a building that can
///   grow, rubble: `tapBuild`; M6: the plot markers are gone, the mark is the site's sign while it offers something),
///   the court and the guests with a word (`tapTalk`, marked while they have a new line today), the Stranger asking
///   at the gate; at night every cold brazier (`tapLight`) and every damaged wall (`tapRepair`, its price); day and
///   night the barracks (`tapRecruit`, marked while a recruit can be paid) and the great hall's door where the hall
///   front paints it (`tapDoor`, `HallDoor`).
/// - **The great hall:** the inner door (`tapDoor`); by day the empty throne while an audience can be held
///   (`tapThrone`), each occupied bench as one target with its mark over the first in line, the court with a word,
///   and the tax lectern (no mark) while nobody waits.
enum TouchThings {
    // MARK: - The world

    /// The world's things now. `figures`: the court as `CourtFrames` draws it this frame; `talked`: who was heard
    /// today (their mark goes).
    static func world(_ s: GameState, balance: Balance, figures: [DrawnFigure], talked: Set<String>,
                      lines: CourtLineBook = .standard) -> [TouchThing] {
        guard !s.defeated else { return [] }
        var list: [TouchThing] = []
        let day = DayClock.phase(at: s.hour) == .day
        let layouts = KingTargets.layouts(s, balance: balance)
        if day {
            for plot in Realm.plots.indices where plot < s.plots.count {
                guard s.isUnlocked(plot: plot), KingTargets.hasCard(s, plot: plot, balance: balance) else { continue }
                let x = KingTargets.spotX(plot: plot, layouts: layouts)
                let size = extent(plot: plot, state: s, layouts: layouts)
                // Its mark only while the treasury can pay something on its card (a free gift included); the site
                // still answers a touch (its card shows the prices).
                let options = Build.options(s, plot: plot, balance: balance)
                let affordable = options.contains { $0.price <= s.gold }
                // Fix round 1: the slip names the cheapest price with its coin (none for a gift); an empty plot shows
                // its footing while its mark shows.
                let cheapest = options.map(\.price).min()
                // The footing only where its building stands on the lane (not on the gatehouse's wall walk); the
                // mark's tip then hangs just over its cord.
                let footed = s.plots[plot].item == nil && s.plots[plot].job == nil
                    && EntityFrames.drawnCentre(plot: plot, layouts: layouts).y < 2
                list.append(TouchThing(id: "touch-plot-\(plot)", kind: .plot, act: .build(plot: plot), x: x,
                                       standX: x, halfWidth: size.half,
                                       top: footed ? Double(TouchFooting.stakeHeight) : size.top,
                                       rank: TouchRules.rank(.plot), price: cheapest.flatMap { $0 > 0 ? $0 : nil },
                                       marked: affordable,
                                       footing: footed ? TouchFooting.half(plot: plot, state: s, layouts: layouts) : nil))
            }
            var seen = Set<String>()
            for figure in figures where figure.alpha > 0.5 && figure.petition == nil && !seen.contains(figure.who) {
                guard Speakers.canTalk(figure.who), !HallRules.livesInHallNow(figure.who, flags: s.flags),
                      lines.line(for: figure.who, state: s) != nil else { continue }
                seen.insert(figure.who)
                list.append(person(figure, act: .talk(who: figure.who), lordX: s.king.x,
                                   court: Speakers.speaker(figure.who)?.role == .court,
                                   marked: !talked.contains(figure.who)))
            }
            // Build 3, the drill yard (wave 2, lane 2): its site in the courtyard while it offers something; a touch
            // brings its counter (the count, docs/PAY.md), marked while the purse can pay it.
            if let yard = yardThing(s, balance: balance) { list.append(yard) }
            if AudienceRules.gate(s, catalog: .standard) != nil {
                let x = CourtLayout.strangerAtGate
                list.append(TouchThing(id: "touch-talk-seren", kind: .talk, act: .stranger, x: x,
                                       standX: x + TouchRules.armsLength * (s.king.x < x ? -1 : 1), halfWidth: 6,
                                       top: 30, rank: TouchRules.rank(.talk, court: true), who: "seren"))
            }
        } else {
            for plot in Realm.brazierPlots where plot < s.plots.count {
                guard s.plots[plot].item != nil, s.plots[plot].snuffed else { continue }
                let x = Realm.plots[plot].x
                let size = extent(plot: plot, state: s, layouts: layouts)
                list.append(TouchThing(id: "touch-brazier-\(plot)", kind: .brazier, act: .light(plot: plot), x: x,
                                       standX: x, halfWidth: size.half, top: size.top,
                                       rank: TouchRules.rank(.brazier)))
            }
            for plot in Realm.wallsOuterFirst where plot < s.plots.count {
                let state = s.plots[plot]
                guard let item = state.item, item.isWall, !state.isRubble,
                      state.hp < Build.maxHP(item, balance: balance) else { continue }
                let x = Realm.plots[plot].x + min(item.width, 40) / 2
                let size = extent(plot: plot, state: s, layouts: layouts)
                // Fix round 1: no mark while the last repair's cooldown runs (it would only be refused; after the
                // second touch paid the mark stayed and read as unpaid); the rim on the wall as drawn.
                list.append(TouchThing(id: "touch-wall-\(plot)", kind: .wall, act: .patch(plot: plot), x: x,
                                       standX: x, halfWidth: size.half, top: size.top,
                                       rank: TouchRules.rank(.wall), price: balance.patchCost,
                                       marked: s.king.patchCooldown <= 0,
                                       rimX: EntityFrames.drawnCentre(plot: plot, layouts: layouts).x))
            }
        }
        // Fix round 1: the barracks carry their mark only while the treasury can pay a recruit (the sites' rule; at 3
        // gold the mark led to a card of refusals). Build 3, the count (PAY.md): the barracks are two things, the
        // archer's half on the left and the guard's on the right, each with its own tally board and price; the mark
        // shows over the one nearer the lord (the building spacing keeps it to one).
        let recruits = RecruitCard.make(s, balance: balance).options
        let cart = CourtLayout.props(s, catalog: .standard).contains(where: { $0.sprite == .marekCart })
        for option in recruits {
            let archer = option.kind == .archer
            let x = KingTargets.barracksX + (archer ? -1 : 1) * TouchThings.recruitOffset
            var recruit = TouchThing(id: archer ? "touch-recruit-archer" : "touch-recruit-guard", kind: .recruit,
                                     act: .recruit, x: x, standX: x, halfWidth: TouchThings.recruitHalf,
                                     top: Double(SpriteID.barracks.size.height) - 4, rank: TouchRules.rank(.recruit),
                                     price: option.price, marked: option.canRecruit, soldier: option.kind)
            // Stage-3-interface (stage-2 critic look 2, high 3): on Marek's days his cart stands before the barracks;
            // the barracks' sign hangs at the edge the cart leaves free, and the barracks carry no rim (it read as the
            // cart's).
            if cart {
                recruit.markAt = TouchRules.barracksFreeX
                recruit.noRim = true
            }
            list.append(recruit)
        }
        list.append(TouchThing(id: "touch-door-hall", kind: .door, act: .hallDoor, x: HallRules.doorX,
                               standX: HallRules.doorX, halfWidth: 9, top: worldDoorTop,
                               rank: TouchRules.rank(.door), marked: abs(s.king.x - HallRules.doorX) > doorQuiet))
        // The join: Saul Tolliver at his post just inside the town gate (`CollectorTouch`), never on his round.
        if let collector = CollectorTouch.thing(s) { list.append(collector) }
        return list
    }

    /// Build 3, the drill yard (docs/YARD.md sections 2 and 4; wave 2, lane 2): the yard's site by day while it offers
    /// something (from day 4 the drill yard, once it stands the pitch kettle), nil otherwise and at night. Its id is
    /// `touch-yard` (the stage) or `touch-yard-kettle`; it is bought by its count like every bought thing.
    static func yardThing(_ s: GameState, balance: Balance) -> TouchThing? {
        guard !s.defeated, DayClock.phase(at: s.hour) == .day, let offer = Yard.offer(s, balance: balance) else {
            return nil
        }
        let price = Yard.price(offer, balance: balance)
        let id: String
        switch offer {
        case .stage:
            id = "touch-yard"
        case .kettle:
            id = "touch-yard-kettle"
        }
        // Step 2: the empty site is marked out by its own stakes and cord over the whole ground (`yardSite`, drawn by
        // `EntityFrames.yardProps` day and night), so no footing is laid over them; the kettle's place stands in the
        // yard.
        return TouchThing(id: id, kind: .plot, act: .yard(offer), x: Yard.plotX, standX: Yard.plotX,
                          halfWidth: Yard.plotHalf, top: Double(TouchFooting.stakeHeight),
                          rank: TouchRules.rank(.plot), price: price, marked: price <= s.gold, footing: nil)
    }

    /// Build 3, the count: each recruit's half of the barracks, its middle this far from the barracks' middle, and
    /// half its width.
    static let recruitOffset = 16.0
    static let recruitHalf = 14.0

    /// While the lord stands this near a door (he just came through it) its mark rests; the door still answers a
    /// touch (the first sweep: the door's mark over his head was the first thing he saw inside).
    static let doorQuiet = 40.0

    /// The great hall's door in the world: its top above the walk line (the painted door's arch, `HallDoor`).
    static let worldDoorTop = 40.0

    /// Someone with a word: his touch area is his body, his mark over his head, and the lord stops an arm's length
    /// before him on the side he comes from.
    static func person(_ figure: DrawnFigure, act: KingTarget, lordX: Double, court: Bool, marked: Bool,
                       id: String? = nil) -> TouchThing {
        let size = figure.sprite.size
        let side: Double = lordX < figure.x ? -1 : 1
        return TouchThing(id: id ?? "touch-talk-\(figure.who)", kind: .talk, act: act, x: figure.x,
                          standX: figure.x + TouchRules.armsLength * side, halfWidth: Double(size.width) / 2 - 4,
                          top: figure.y + Double(size.height), rank: TouchRules.rank(.talk, court: court),
                          marked: marked, who: figure.who, look: figure.look)
    }

    /// Half the drawn width and the drawn top of what stands on a plot (game px; an empty site: a small sign's
    /// height, its mark low over the ground).
    static func extent(plot: Int, state s: GameState, layouts: [LineLayout]) -> (half: Double, top: Double) {
        let spec = Realm.plots[plot]
        let lift = EntityFrames.drawnCentre(plot: plot, layouts: layouts).y
        guard let item = s.plots[plot].item else { return (6, max(6, lift)) }
        switch item {
        case .gate, .ironGate, .greatGate: return (24, 64)
        case .palisade: return (10, 34)
        case .stoneWall: return (16, 50)
        case .bastion: return (20, 58)
        case .archerTower: return (10, 56)
        case .watchtower: return (11, 66)
        case .brazier: return (5, 14)
        case .fireTower: return (8, 34)
        case .ballista, .catapult: return (11, lift + 18)
        case .stakePit: return (10, 6)
        case .beaconBase: return (20, 30)
        case .beaconTower: return (20, 52)
        case .greatBeacon: return (22, 70)
        case .smithy, .masterSmithy: return (28, 44)
        case .lodge, .bigLodge: return (26, 42)
        case .house: return (22, 46)
        case .bigHouse: return (26, 54)
        case .field: return (spec.slot == .field ? 26 : 20, 8)
        case .market: return (28, 36)
        case .tavern: return (28, 50)
        // The join: the town lane's grown tiers (build 3, `TownGrowth.growthOpen`) take their base building's area.
        case .townhouse: return (26, 54)
        case .marketHall: return (28, 36)
        case .inn: return (28, 50)
        case .farmstead: return (spec.slot == .field ? 26 : 20, 8)
        case .treasury: return (24, 44)
        }
    }

    // MARK: - The great hall

    /// The hall's things now. `figures`: the hall's figures as drawn; `talked`: who was heard today; `lordX`: where
    /// he stands in the hall.
    static func hall(_ s: GameState, figures: [DrawnFigure], talked: Set<String>, lordX: Double,
                     lines: CourtLineBook = .standard) -> [TouchThing] {
        guard !s.defeated else { return [] }
        var list: [TouchThing] = []
        let doorTop = Double(HallLayout.floorRow - HallLayout.doorTop)
        list.append(TouchThing(id: "touch-door-hall", kind: .door, act: .hallDoor, x: HallLayout.doorX,
                               standX: HallLayout.doorX, halfWidth: 12, top: doorTop, rank: TouchRules.rank(.door),
                               marked: abs(lordX - HallLayout.doorX) > doorQuiet))
        guard DayClock.phase(at: s.hour) == .day else { return list }
        let waiting = !AudienceRules.hall(s, catalog: .standard).isEmpty
        if waiting {
            let lift = HallLayout.lift(at: HallLayout.throneX)
            list.append(TouchThing(id: "touch-throne", kind: .throne, act: .throne, x: HallLayout.throneX,
                                   standX: HallLayout.throneX, halfWidth: 10, top: lift + CourtFrames.throneMarkY - 4,
                                   rank: TouchRules.rank(.throne)))
        }
        // Town-2 (the join): the lectern is furniture; the taxes are paid on foot at the doors.
        // Each occupied bench is one target: the seated sit 11 px apart, too close for a finger.
        let order = s.court?.queue.map(\.id) ?? []
        let benchHalf = Double(SpriteID.bench.size.width) / 2
        for (index, centre) in HallLayout.benches.enumerated() {
            let seated = figures.filter { figure in
                figure.petition != nil && !figure.key.hasPrefix("leaving:") && figure.onBench
                    && abs(figure.x - centre) <= benchHalf + 4
            }
            guard !seated.isEmpty else { continue }
            let first = seated.min { a, b in
                (order.firstIndex(of: a.petition ?? "") ?? Int.max) < (order.firstIndex(of: b.petition ?? "") ?? Int.max)
            } ?? seated[0]
            let top = seated.map { $0.y + Double($0.sprite.size.height) }.max() ?? 24
            let side: Double = lordX < first.x ? -1 : 1
            list.append(TouchThing(id: "touch-bench-\(index)", kind: .bench, act: .bench(index: index), x: centre,
                                   standX: first.x + TouchRules.armsLength * side, halfWidth: benchHalf + 2, top: top,
                                   rank: TouchRules.rank(.bench), markAt: first.x, who: first.who, look: first.look))
        }
        var seen = Set<String>()
        for figure in figures where figure.petition == nil && !seen.contains(figure.who) {
            guard !figure.key.hasPrefix("leaving:"), Speakers.canTalk(figure.who),
                  lines.line(for: figure.who, state: s) != nil else { continue }
            seen.insert(figure.who)
            list.append(person(figure, act: .talk(who: figure.who), lordX: lordX,
                               court: Speakers.speaker(figure.who)?.role == .court,
                               marked: !talked.contains(figure.who)))
        }
        return list
    }
}

extension HallRules {
    /// True for the hall's own court, who never stand in the world now (Odile, Mother Hesper, the Stranger once let
    /// in); the court of the world's rounds is drawn where it walks.
    static func livesInHallNow(_ who: String, flags: [String]) -> Bool {
        switch who {
        case "odile", "hesper": return true
        case "seren": return flags.contains(CourtLayout.serenInFlag)
        default: return false
        }
    }
}
