/// What a touch on the next beacon site would do: raise a beacon on bare ground, or relight a cold one (docs/REALM.md
/// section 5). The picture shows the price as coins at the site; the count (docs/PAY.md) pays it and calls
/// `Gorge.order`.
struct GorgeOffer: Sendable, Equatable {
    /// The site (0 is the nearest).
    var site: Int
    var x: Double
    var price: Int
    /// A cold beacon that fell: relit at once for a third. Else a new one the builders raise in about a day.
    var relight: Bool
    /// By day, from day 3.
    var open: Bool
    /// The purse holds the price.
    var affordable: Bool

    /// A touch would order it now.
    var ready: Bool { open && affordable }
}

/// What a touch on the ruined watchtower would do: raise it as a forward archers' post (its stretch is held).
struct GorgeWatchOffer: Sendable, Equatable {
    var x: Double
    var price: Int
    /// By day.
    var open: Bool
    var affordable: Bool

    var ready: Bool { open && affordable }
}

/// One beacon site for the picture.
struct GorgeSitePicture: Sendable, Equatable {
    var site: Int
    var x: Double
    var state: GorgeSiteState
    /// What is left of its strength (1 whole, 0 gone); 0 unless it burns.
    var strength: Double
    /// How far the builders are (0 ... 1) while it is being raised; nil otherwise.
    var raised: Double?
    /// The raise waits: a beacon nearer the castle went dark, and the builders stay away until it burns again (the
    /// scaffolding stands, no crew at it).
    var paused: Bool = false
}

/// One stretch of the gorge for the picture: the thing that stands in it and whether the stretch is held.
struct GorgeLandPicture: Sendable, Equatable {
    var land: GorgeLand
    var x: Double
    /// The beacon that clears it burns: the land is ours (out of the fog, people at work there by day).
    var held: Bool
    /// The watchtower only: raised as a forward post, and manned now (raised and held).
    var watchRaised: Bool
    var manned: Bool
}

/// Everything the picture needs from the gorge beacons in one frame (docs/lanes/front.md, "front-3": what the world
/// shows): read-only, built from the state.
struct GorgePicture: Sendable, Equatable {
    var ruleOn: Bool
    /// The fog line: where the furthest lit beacon holds the fog (the next site, or the fog's last line at x 37 once all
    /// four burn); nil when no beacon burns. The darkness bank itself is `GameState.bankEdge`, which the rule holds there by
    /// day and by night (rolling over `GorgeTuning.fogSeconds` when it moves); with no beacon it rests by day at the
    /// first site.
    var fogLine: Double?
    /// Beacons burning (always the nearest ones).
    var held: Int
    var sites: [GorgeSitePicture]
    var lands: [GorgeLandPicture]
    /// What a touch on the next site would do (nil: all four burn, one is being raised, or the realm fell).
    var offer: GorgeOffer?
    /// What a touch on the ruined watchtower would do (nil: not freed, or raised already).
    var watchOffer: GorgeWatchOffer?
    /// The stamps: a new `at` is a beacon lit (raised or relit) or a beacon fallen.
    var lastLit: GorgeStamp?
    var lastFall: GorgeStamp?
    /// A wall stands whole beyond the gate, so the beacons are tended from it by day (people walk out to them).
    var tended: Bool = true
}

/// The gorge beacons (docs/REALM.md section 5, "Beacons into the gorge (forward)"). Four sites beyond the gate, at
/// growing distances. From day 3 the next one is raised by day (60, 90, 130, 180 gold; the builders need about a day),
/// each only once the one before it burns. Each beacon holds the fog off the stretch beyond it, up to the next site:
/// the darkness bank rests at that line by day and by night, so every beacon pushes the fog back one stretch and frees
/// the thing in it (the old quarry, the ruined watchtower, the charcoal burners' camp, the far stones), and the next
/// site stands at the fog's rim. With no beacon the fog comes at night as it always came and rests by day at the
/// first site. Every lit beacon burns as a fire under the existing light rules: creatures that walk through it are seen
/// and slow to their lit speed, and sootlings burn. Creatures strike the furthest lit beacon as they pass; at 0 strength
/// it falls, and the fog comes back to it. A standing beacon is tended from the wall: full again at dawn while a wall
/// beyond the gate stands whole. A cold beacon is relit by day for a third of its price.
///
/// Creatures still leave the Gloom where they always did (`Realm.spawnX`, x 40), west of every site, so they walk the
/// whole gorge in the beacons' light, slower and under the watch's arrows; they come out of the fog at the fog line (the
/// picture hides what is inside the bank).
///
/// Deterministic: nothing here draws from the random stream. Nothing runs for a realm without `GameState.gorge`.
enum Gorge {
    /// The number of beacon sites.
    static let sites = 4

    // MARK: - The rule on

    /// Turns the rule on for this realm (the join calls it for the player's realm). A realm that has it keeps it.
    static func adopt(_ s: inout GameState) {
        guard s.gorge == nil else { return }
        var g = GorgeState()
        g.tonight = GorgeNightTally(night: s.nightNumber)
        s.gorge = g
    }

    // MARK: - Places

    private static func x(_ fraction: Double, _ tuning: GorgeTuning) -> Double {
        tuning.gorgeFrontX - fraction * (tuning.gorgeFrontX - tuning.gorgeWestX)
    }

    /// Where beacon site `index` stands (a fraction of the gorge from the castle front).
    static func siteX(_ index: Int, tuning: GorgeTuning) -> Double {
        let list = tuning.siteFractions
        return x(list.isEmpty ? 0 : list[min(max(0, index), list.count - 1)], tuning)
    }

    /// Where the fog rests while `held` beacons burn: the next site (the first with none), or the fog's last line
    /// (`GorgeTuning.lastLineFraction`, x 37) once all four burn.
    static func lineX(_ held: Int, tuning: GorgeTuning) -> Double {
        held < sites ? siteX(held, tuning: tuning) : x(tuning.lastLineFraction, tuning)
    }

    /// Where a freed thing stands.
    static func landX(_ land: GorgeLand, tuning: GorgeTuning) -> Double {
        let list = tuning.landFractions
        return x(list.isEmpty ? 0 : list[min(land.rawValue, list.count - 1)], tuning)
    }

    /// Beacons burning (the nearest ones); 0 without the rule.
    static func held(_ s: GameState) -> Int { s.gorge?.held ?? 0 }

    /// The stretch of this thing is held (the beacon that clears it burns).
    static func holds(_ s: GameState, _ land: GorgeLand) -> Bool { held(s) > land.rawValue }

    /// A wall stands whole beyond the gate (the middle or the outer line's, built and not rubble): the beacons are
    /// tended from it.
    static func wallBeyondGate(_ s: GameState) -> Bool {
        for line in Realm.lines.dropFirst() {
            let plot = s.plots[line.wall]
            if plot.item != nil && !plot.isRubble { return true }
        }
        return false
    }

    /// The fog line: where the furthest lit beacon holds the fog (the next site, or the fog's last line); nil when none
    /// burns (the fog comes as it always came).
    static func fogLine(_ s: GameState, balance: Balance) -> Double? {
        let count = held(s)
        guard count > 0 else { return nil }
        return lineX(count, tuning: balance.front.gorge)
    }

    /// Where the rule holds the bank before any roll: with a beacon burning at the fog line, by day and by night; with
    /// none, as the fog comes (`edge`) but never further west than the first site, so by day it rests there. A
    /// petition's fog tonight (`petitionFog`: `NightPlanModifiers.fogShift` at night, 0 by day) still comes on past the
    /// beacons' line, up to the furthest lit beacon and never over it (`GorgeTuning.petitionFogPresses`; fix round 2, the
    /// critic's smaller point 2: a lit beacon erased the petition's consequence). With no beacon it is in `edge` already.
    static func restingBank(held: Int, edge: Double, tuning: GorgeTuning, petitionFog: Double = 0) -> Double {
        guard held > 0 else { return max(edge, siteX(0, tuning: tuning)) }
        let line = lineX(held, tuning: tuning)
        guard tuning.petitionFogPresses && petitionFog > 0 else { return line }
        return max(line, min(line + petitionFog, siteX(held - 1, tuning: tuning)))
    }

    /// A petition's fog at this hour: how much further it brings the bank tonight (`NightPlanModifiers.bankShift`, swelling
    /// and ebbing with the night as the bank does); 0 by day and on a night without it.
    static func petitionFog(_ s: GameState) -> Double {
        let shift = NightPlanModifiers.bankShift(s)
        guard shift > 0 else { return 0 }
        return DarknessBank.edge(hour: s.hour, restingEdge: 0, nightEdge: shift)
    }

    /// The darkness bank's edge under the rule (`Battle.bankEdge` asks it last): held at the fog line, or by day at the
    /// first site, rolling to a new line over `fogSeconds` (from wherever the bank stood when the line moved). Without the
    /// rule `edge` itself. With no beacon the bank differs from `edge` only between it and the first site (x 200 to 300),
    /// where nothing of the battle stands, so a realm that raises nothing plays its nights exactly as before. On the
    /// King's night, once the Great Beacon flares (unless `holdFogOnFinale`), the fog rolls over the small beacons to
    /// where the Great Beacon holds it, over `fogSeconds` from the King's leaving, and from then on the night is exactly
    /// today's.
    static func holdFog(_ s: GameState, edge: Double, balance: Balance) -> Double {
        guard let g = s.gorge else { return edge }
        let tuning = balance.front.gorge
        var bank = restingBank(held: g.held, edge: edge, tuning: tuning, petitionFog: petitionFog(s))
        if let shift = g.fogShift, let from = shift.from, tuning.fogSeconds > 0, s.simTime >= shift.at,
           s.simTime - shift.at < tuning.fogSeconds {
            bank = from + (bank - from) * (s.simTime - shift.at) / tuning.fogSeconds
        }
        if !tuning.holdFogOnFinale && Battle.beaconRadius(s, balance: balance) > 0 && bank < edge {
            var share = 0.0
            if let left = s.night.kingLeftSecond {
                share = tuning.fogSeconds > 0 ? min(1, max(0, (s.nightTime - left) / tuning.fogSeconds)) : 1
            }
            bank += (edge - bank) * share
        }
        return bank
    }

    // MARK: - Prices and strength

    /// What beacon `index` costs to raise.
    static func price(_ index: Int, tuning: GorgeTuning) -> Int {
        let list = tuning.prices
        return list.isEmpty ? 0 : list[min(max(0, index), list.count - 1)]
    }

    /// What a cold beacon costs to relight: a third of its price, rounded up.
    static func relightPrice(_ index: Int, tuning: GorgeTuning) -> Int {
        Int((Double(price(index, tuning: tuning)) * tuning.relightShare - 1e-9).rounded(.up))
    }

    /// A lit beacon's full strength.
    static func strength(_ index: Int, tuning: GorgeTuning) -> Double {
        let list = tuning.strength
        return list.isEmpty ? 1 : list[min(max(0, index), list.count - 1)]
    }

    // MARK: - By day: raising, relighting, the watchtower

    /// What a touch on the next site would do now; nil without the rule, after the fall, when all four burn or while
    /// the next one is being raised. While a raise waits beyond a cold beacon (it fell in the night), the cold one is
    /// offered: relit, it lets the builders go on.
    static func offer(_ s: GameState, balance: Balance) -> GorgeOffer? {
        guard let g = s.gorge, !s.defeated else { return nil }
        let next = g.held
        guard next < sites else { return nil }
        let state = g.sites[next].state
        if let job = g.raise, job.site == next || state != .dark { return nil }
        guard state == .wild || state == .dark else { return nil }
        let tuning = balance.front.gorge
        let relight = state == .dark
        let cost = relight ? relightPrice(next, tuning: tuning) : price(next, tuning: tuning)
        let open = DayClock.phase(at: s.hour) == .day && s.day >= tuning.raiseFromDay
            && (!tuning.raiseNeedsWall || wallBeyondGate(s))
        return GorgeOffer(site: next, x: siteX(next, tuning: tuning), price: cost, relight: relight, open: open,
                          affordable: s.gold >= cost)
    }

    /// Raises the next beacon or relights it (the count calls it when the last coin lands): the gold goes at once; a
    /// relit beacon burns at once, a new one when the builders are done. False (and nothing changes) when the offer is
    /// not ready.
    @discardableResult
    static func order(_ s: inout GameState, balance: Balance) -> Bool {
        guard let offer = offer(s, balance: balance), offer.ready, var g = s.gorge else { return false }
        let tuning = balance.front.gorge
        s.gold -= offer.price
        if offer.relight {
            g.sites[offer.site] = GorgeSite(state: .lit, strength: strength(offer.site, tuning: tuning))
            g.relitToday.append(offer.site)
            g.lastLit = GorgeStamp(at: s.simTime, site: offer.site)
            s.gorge = g
            moveFog(&s)
        } else {
            g.sites[offer.site].state = .raising
            g.raise = GorgeRaise(site: offer.site, work: 0, total: max(1e-6, tuning.raiseWork), day: s.day)
            s.gorge = g
        }
        return true
    }

    /// What a touch on the ruined watchtower would do now.
    static func watchOffer(_ s: GameState, balance: Balance) -> GorgeWatchOffer? {
        guard let g = s.gorge, !s.defeated, !g.watchtowerRaised, holds(s, .watchtower) else { return nil }
        let tuning = balance.front.gorge
        return GorgeWatchOffer(x: landX(.watchtower, tuning: tuning), price: tuning.watchtowerPrice,
                               open: DayClock.phase(at: s.hour) == .day, affordable: s.gold >= tuning.watchtowerPrice)
    }

    /// Raises the ruined watchtower as a forward post (the count calls it): manned from the next dusk while its
    /// stretch is held. False when the offer is not ready.
    @discardableResult
    static func raiseWatchtower(_ s: inout GameState, balance: Balance) -> Bool {
        guard let offer = watchOffer(s, balance: balance), offer.ready, var g = s.gorge else { return false }
        s.gold -= offer.price
        g.watchtowerRaised = true
        g.watchRaisedToday = true
        s.gorge = g
        return true
    }

    /// One step (`Sim.step`, after the builders): by day the builders without other work raise the beacon (the happy
    /// realm's faster builders included; a raise that waits beyond a cold beacon gets no work), and the bank rests at
    /// the fog line.
    static func step(_ s: inout GameState, dt: Double, balance: Balance) {
        guard var g = s.gorge, !s.defeated, DayClock.phase(at: s.hour) == .day else { return }
        if var job = g.raise, job.site == g.held {
            var idle = 0
            for builder in s.builders where builder.plot < 0 { idle += 1 }
            let factor = s.happiness >= balance.fastGrowthFrom ? balance.happyBuildFactor : 1
            job.work += Double(idle) * dt * factor
            if job.work >= job.total {
                g.raise = nil
                g.sites[job.site] = GorgeSite(state: .lit, strength: strength(job.site, tuning: balance.front.gorge))
                g.litToday.append(job.site)
                g.lastLit = GorgeStamp(at: s.simTime, site: job.site)
                s.gorge = g
                moveFog(&s)
            } else {
                g.raise = job
                s.gorge = g
            }
        }
        if s.creatures.isEmpty { s.bankEdge = Battle.bankEdge(s, balance: balance) }
    }

    /// The fog line moved (a beacon lit or fallen): the bank rolls from where it stands now.
    private static func moveFog(_ s: inout GameState) {
        guard var g = s.gorge else { return }
        g.fogShift = GorgeFogShift(at: s.simTime, from: s.bankEdge, to: nil)
        s.gorge = g
    }

    // MARK: - The night

    /// The beacons' fires for the battle and the picture (`Battle.lightSources` adds them last): one fire per lit
    /// beacon; with the charcoal burners' camp held, the braziers and fire towers burn brighter.
    static func addLights(_ lights: inout [LightSource], _ s: GameState, balance: Balance) {
        guard let g = s.gorge else { return }
        let tuning = balance.front.gorge
        let count = g.held
        if count > GorgeLand.camp.rawValue && tuning.charcoalRadius != 1 {
            for index in lights.indices where lights[index].kind == .brazier || lights[index].kind == .fireTower {
                lights[index].radius *= tuning.charcoalRadius
            }
        }
        for site in 0..<count {
            lights.append(LightSource(kind: .brazier, x: siteX(site, tuning: tuning), y: tuning.flameY,
                                      radius: tuning.lightRadius,
                                      flickerSeed: SeededRandom.mix(UInt64(0x4743_0000 + site))))
        }
    }

    /// After the creatures walked (`Battle.step`): they strike the furthest lit beacon as they pass, and the watch
    /// looses from the old watchtower.
    static func battle(_ s: inout GameState, dt: Double, balance: Balance, creatureStartX: [Double],
                       walkTimes: [Double], events: inout [SimEvent]) {
        guard s.gorge != nil else { return }
        strike(&s, balance: balance, creatureStartX: creatureStartX, walkTimes: walkTimes)
        watch(&s, dt: dt, balance: balance, events: &events)
    }

    /// The harm of every creature on the ground that walked within `strikeReach` of the furthest lit beacon this step
    /// (harm × the time within reach, worked out from its path as the battle strikes soldiers in passing). At 0 it
    /// falls: cold, and the fog comes back to it. A raise beyond it waits until it burns again (`GorgeState.raise`).
    static func strike(_ s: inout GameState, balance: Balance, creatureStartX: [Double], walkTimes: [Double]) {
        guard var g = s.gorge else { return }
        let count = g.held
        guard count > 0 else { return }
        let site = count - 1
        let tuning = balance.front.gorge
        let x = siteX(site, tuning: tuning)
        let reach = tuning.strikeReach
        let creatures = min(walkTimes.count, creatureStartX.count, s.creatures.count)
        var harm = 0.0
        for index in 0..<creatures {
            let walk = walkTimes[index]
            guard walk > 0 else { continue }
            let c = s.creatures[index]
            guard c.hp > 0, !c.kind.flies else { continue }
            let c0 = creatureStartX[index]
            if max(c0, c.x) < x - reach || min(c0, c.x) > x + reach { continue }
            let time = Battle.contactTime(c0: c0, c1: c.x, walk: walk, s0: x, s1: x, move: 0, reach: reach)
            if time > 0 { harm += balance.creature(c.kind).harm * time }
        }
        guard harm > 0 else { return }
        let dealt = harm * balance.creatureHarmScale
        g.sites[site].strength -= dealt
        g.tonight.struck += dealt
        guard g.sites[site].strength <= 0 else {
            s.gorge = g
            return
        }
        g.sites[site] = GorgeSite(state: .dark, strength: 0)
        g.tonight.fell.append(site)
        g.lastFall = GorgeStamp(at: s.simTime, site: site)
        s.gorge = g
        moveFog(&s)
    }

    /// The watch of the old watchtower (raised, its stretch held, at night): `watchArchers` bowmen loose at the King
    /// when he can be hurt, else at the most advanced lit creature in reach that arrows in flight do not already cover.
    static func watch(_ s: inout GameState, dt: Double, balance: Balance, events: inout [SimEvent]) {
        guard var g = s.gorge, g.watchtowerRaised, holds(s, .watchtower),
              DayClock.phase(at: s.hour) != .day else { return }
        let tuning = balance.front.gorge
        guard tuning.watchArchers > 0 else { return }
        g.watchCooldown -= dt
        guard g.watchCooldown <= 0 else {
            s.gorge = g
            return
        }
        let x = landX(.watchtower, tuning: tuning)
        guard let target = watchTarget(s, x: x, range: tuning.watchRange, balance: balance) else {
            g.watchCooldown = 0
            s.gorge = g
            return
        }
        let c = s.creatures[target]
        let height = balance.creature(c.kind).height
        let duration = max(0.15, abs(c.x - x) / balance.arrowSpeed)
        s.projectiles.append(Projectile(kind: .arrow, fromX: x, fromY: tuning.watchHeight, toX: c.x,
                                        toY: c.y + height * 0.5, duration: duration, target: c.id,
                                        damage: tuning.watchDamage))
        s.creatures[target].incoming += tuning.watchDamage
        g.watchCooldown += tuning.watchPeriod / Double(tuning.watchArchers)
        g.tonight.watchShots += 1
        s.gorge = g
        events.append(.arrow(fire: false, x: x))
    }

    /// The watch's mark: the King while he can be hurt (as the archers aim), else the most advanced lit creature in
    /// reach not already covered.
    static func watchTarget(_ s: GameState, x: Double, range: Double, balance: Balance) -> Int? {
        if balance.aimAtTheKing {
            for index in s.creatures.indices {
                let c = s.creatures[index]
                if c.kind == .lightlessKing && c.isLit && c.hp - c.incoming > 0 && abs(c.x - x) <= range {
                    return index
                }
            }
        }
        var best = -1
        var bestX = -Double.infinity
        for index in s.creatures.indices {
            let c = s.creatures[index]
            guard c.isLit, c.hp - c.incoming > 0, abs(c.x - x) <= range else { continue }
            if c.x > bestX {
                bestX = c.x
                best = index
            }
        }
        return best >= 0 ? best : nil
    }

    // MARK: - Freed land: the old quarry

    /// The build card of a wall plot while the old quarry is held (`Build.options` asks it after the hearth): the same
    /// lines, every price a little less (`quarryDiscount`, rounded). nil for any other plot, and always without the rule
    /// or the quarry.
    static func options(_ state: GameState, plot: Int, balance: Balance) -> [BuildOption]? {
        let discount = balance.front.gorge.quarryDiscount
        guard state.gorge != nil, discount > 0, holds(state, .quarry), Realm.plots[plot].slot == .wall else {
            return nil
        }
        func cut(_ price: Int) -> Int { max(0, Int((Double(price) * (1 - discount)).rounded())) }
        let current = state.plots[plot]
        if current.job != nil { return [] }
        guard let item = current.item else {
            return Realm.plots[plot].firstItems.map {
                BuildOption(item: $0, price: cut(balance.price($0)), isRebuild: false)
            }
        }
        if current.isRubble {
            return [BuildOption(item: item, price: cut(Build.rebuildPrice(item, balance: balance)), isRebuild: true)]
        }
        if let next = item.upgrade { return [BuildOption(item: next, price: cut(balance.price(next)), isRebuild: false)] }
        return []
    }

    // MARK: - The dawn

    /// At the dawn report (`Sim.dawn`, after the report is made): the night's beacons into `DawnReport.gorge` (what
    /// fell, what burns anew, the land freed, the watch, the beacons left untended), the standing beacons tended from
    /// the wall (full strength while a wall beyond the gate stands whole), a fresh tally, and the bank at rest at the
    /// fog line.
    static func dawn(_ s: inout GameState, balance: Balance) {
        guard var g = s.gorge else { return }
        let tuning = balance.front.gorge
        let count = g.held
        var report = GorgeDawnReport()
        report.lost = g.tonight.fell
        report.lit = g.litToday.filter { $0 < count }
        report.relit = g.relitToday.filter { $0 < count }
        report.held = count
        if count > g.heldAtDawn {
            report.freed = (g.heldAtDawn..<count).compactMap { GorgeLand(rawValue: $0) }
        }
        report.watchRaised = g.watchRaisedToday && count > GorgeLand.watchtower.rawValue
        report.towerRaised = g.watchtowerRaised
        let tended = !tuning.tendedFromWall || wallBeyondGate(s)
        for site in 0..<count {
            let full = strength(site, tuning: tuning)
            if tended {
                g.sites[site].strength = full
            } else if g.sites[site].strength < full {
                report.untended = true
            }
        }
        g.heldAtDawn = count
        g.litToday = []
        g.relitToday = []
        g.watchRaisedToday = false
        g.watchCooldown = 0
        g.tonight = GorgeNightTally(night: s.nightNumber)
        s.gorge = g
        s.lastReport?.gorge = report
        s.bankEdge = Battle.bankEdge(s, balance: balance)
    }

    // MARK: - The picture

    /// Everything the picture reads in one frame.
    static func picture(_ s: GameState, balance: Balance) -> GorgePicture {
        let tuning = balance.front.gorge
        guard let g = s.gorge else {
            return GorgePicture(ruleOn: false, fogLine: nil, held: 0, sites: [], lands: [], offer: nil, watchOffer: nil,
                                lastLit: nil, lastFall: nil)
        }
        var sites: [GorgeSitePicture] = []
        for index in 0..<Gorge.sites {
            let site = g.sites[index]
            let full = strength(index, tuning: tuning)
            let share = site.state == .lit && full > 0 ? max(0, min(1, site.strength / full)) : 0
            let job = site.state == .raising && g.raise?.site == index ? g.raise : nil
            sites.append(GorgeSitePicture(site: index, x: siteX(index, tuning: tuning), state: site.state,
                                          strength: share, raised: job?.progress, paused: job.map { $0.site > g.held }
                                            ?? false))
        }
        var lands: [GorgeLandPicture] = []
        for land in GorgeLand.allCases {
            let held = holds(s, land)
            let tower = land == .watchtower && g.watchtowerRaised
            lands.append(GorgeLandPicture(land: land, x: landX(land, tuning: tuning), held: held, watchRaised: tower,
                                          manned: tower && held))
        }
        return GorgePicture(ruleOn: true, fogLine: fogLine(s, balance: balance), held: g.held, sites: sites,
                            lands: lands, offer: offer(s, balance: balance), watchOffer: watchOffer(s, balance: balance),
                            lastLit: g.lastLit, lastFall: g.lastFall,
                            tended: !tuning.tendedFromWall || wallBeyondGate(s))
    }
}
