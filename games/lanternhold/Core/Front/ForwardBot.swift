/// What a T15 bot did with the gorge in a run.
struct ForwardTally: Sendable, Equatable {
    /// Beacons it had raised and relit, and the gold it paid for them.
    var raises = 0
    var relights = 0
    var beaconGold = 0
    /// It raised the ruined watchtower (and paid for it).
    var watchtower = false
    var watchGold = 0
}

/// The T15 bots (docs/REALM.md section 5): the reference bot by day and by night (`Autoplay`), plus the gorge.
///
/// - **Forward** (`neglectsWalls` off): it keeps the reference's walls (their rubble first, its whole build order) and
///   puts the beacons into that order (`GorgeTuning.botBeaconSteps`): the first once the middle line stands with its
///   braziers, the second once that line has its stone wall and tower, the last two once the Great Beacon is ordered.
///   When the order reaches a beacon's place it saves for it (the reference's next steps wait); the old watchtower it
///   raises when the purse holds its price and `GorgeTuning.botReserve` besides, a cold beacon it relights the same
///   way. While the reference saves for the Great Beacon (day 11 until its third stage stands) it relights nothing
///   (`GorgeTuning.botGreatBeaconFirst`): the chapter's goal first.
/// - **Neglect** (`neglectsWalls` on): it raises and relights beacons first, at any gold, and neglects the walls: no
///   wall is built or raised a tier (the order's wall steps are skipped), no wall is patched at night. It still
///   rebuilds the gatehouse's rubble, as the reference does.
/// - **Walls neglected, no beacons** (`neglectsWalls` on, `raisesBeacons` off): the control of T15b.
/// - **Outpost** (`neglectsWalls` and `forwardHabits` on): the forward bot's beacons, watchtower and Great Beacon in the
///   forward bot's order, but no wall built, raised or patched (T15c: beacons and the Great Beacon without walls must
///   not beat the reference).
///
/// The reference bots of T1 to T8 are untouched; these play only under the gorge rule (`Gorge.adopt`).
struct ForwardBot: Sendable {
    var day: Autoplay
    var neglectsWalls = false
    var raisesBeacons = true
    /// With `neglectsWalls`: buy the beacons as the forward bot does (in its order, the Great Beacon first), not first
    /// at any gold.
    var forwardHabits = false
    var tally = ForwardTally()

    init(day: Autoplay = .reference(), neglectsWalls: Bool = false, raisesBeacons: Bool = true,
         forwardHabits: Bool = false) {
        self.day = day
        self.neglectsWalls = neglectsWalls
        self.raisesBeacons = raisesBeacons
        self.forwardHabits = forwardHabits
        if neglectsWalls { self.day.maxPatchesPerNight = 0 }
    }

    /// Called before every sim step.
    mutating func act(_ s: inout GameState, dt: Double, balance: Balance, events: inout [SimEvent],
                      petitions: PetitionCatalog = .standard) {
        let isDay = DayClock.phase(at: s.hour) == .day
        guard isDay, s.gorge != nil else {
            day.act(&s, dt: dt, balance: balance, events: &events, petitions: petitions)
            return
        }
        if neglectsWalls { skipWallSteps() }
        if neglectsWalls && !forwardHabits {
            buy(&s, balance: balance, reserve: 0)
            day.act(&s, dt: dt, balance: balance, events: &events, petitions: petitions)
            return
        }
        let tuning = balance.front.gorge
        let saving = day.buildsBeacon && s.day >= Realm.beaconUnlockDay && s.beaconStage < 3
            && tuning.botGreatBeaconFirst
        var waits = false
        if raisesBeacons && !wallInRubble(s), let offer = Gorge.offer(s, balance: balance), offer.open {
            if offer.relight {
                let allowed = !saving || offer.price <= tuning.botRelightWhileSaving
                if allowed && s.gold >= offer.price + tuning.botReserve { order(&s, offer, balance: balance) }
            } else if offer.site < tuning.botBeaconSteps.count && day.cursor >= tuning.botBeaconSteps[offer.site] {
                if s.gold >= offer.price {
                    order(&s, offer, balance: balance)
                    day.thinkTimer = 0
                } else {
                    waits = true
                }
            }
        }
        if waits { day.thinkTimer = 1e9 } else if day.thinkTimer > 1e8 { day.thinkTimer = 0 }
        day.act(&s, dt: dt, balance: balance, events: &events, petitions: petitions)
        if raisesBeacons && !wallInRubble(s), day.cursor >= tuning.botWatchStep,
           let offer = Gorge.watchOffer(s, balance: balance), offer.open, s.gold >= offer.price + tuning.botReserve,
           Gorge.raiseWatchtower(&s, balance: balance) {
            tally.watchtower = true
            tally.watchGold += offer.price
        }
    }

    private mutating func order(_ s: inout GameState, _ offer: GorgeOffer, balance: Balance) {
        guard Gorge.order(&s, balance: balance) else { return }
        if offer.relight { tally.relights += 1 } else { tally.raises += 1 }
        tally.beaconGold += offer.price
    }

    /// The neglect bot's order without its wall steps.
    private mutating func skipWallSteps() {
        let order = Autoplay.referenceOrder
        while day.cursor < order.count, case .build(_, let item) = order[day.cursor], item.isWall {
            day.cursor += 1
        }
    }

    private func wallInRubble(_ s: GameState) -> Bool {
        for plot in Realm.wallsOuterFirst where s.plots[plot].item != nil && s.plots[plot].isRubble { return true }
        return false
    }

    /// The next beacon (or its relight), then the watchtower, while the purse holds the price and `reserve`.
    private mutating func buy(_ s: inout GameState, balance: Balance, reserve: Int) {
        guard raisesBeacons else { return }
        if let offer = Gorge.offer(s, balance: balance), offer.open, s.gold >= offer.price + reserve {
            if Gorge.order(&s, balance: balance) {
                if offer.relight { tally.relights += 1 } else { tally.raises += 1 }
                tally.beaconGold += offer.price
            }
        }
        if let offer = Gorge.watchOffer(s, balance: balance), offer.open, s.gold >= offer.price + reserve {
            if Gorge.raiseWatchtower(&s, balance: balance) {
                tally.watchtower = true
                tally.watchGold += offer.price
            }
        }
    }
}
