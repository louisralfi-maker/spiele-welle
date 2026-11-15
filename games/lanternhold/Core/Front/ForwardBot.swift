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
///   raises the next beacon, relights a cold one and raises the old watchtower whenever the purse holds the price and
///   `GorgeTuning.botReserve` besides. The reference's order waits a little for what the beacons took.
/// - **Neglect** (`neglectsWalls` on): it raises and relights beacons first, at any gold, and neglects the walls: no
///   wall is built or raised a tier (the order's wall steps are skipped), no wall is patched at night. It still
///   rebuilds the gatehouse's rubble, as the reference does.
///
/// The reference bots of T1 to T8 are untouched; these play only under the gorge rule (`Gorge.adopt`).
struct ForwardBot: Sendable {
    var day: Autoplay
    var neglectsWalls = false
    var tally = ForwardTally()

    init(day: Autoplay = .reference(), neglectsWalls: Bool = false) {
        self.day = day
        self.neglectsWalls = neglectsWalls
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
        if neglectsWalls {
            skipWallSteps()
            buy(&s, balance: balance, reserve: 0)
            day.act(&s, dt: dt, balance: balance, events: &events, petitions: petitions)
            return
        }
        day.act(&s, dt: dt, balance: balance, events: &events, petitions: petitions)
        if !wallInRubble(s) { buy(&s, balance: balance, reserve: balance.front.gorge.botReserve) }
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
