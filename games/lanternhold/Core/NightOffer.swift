/// Brannock offers the horn (the polish audit's thing 6, step E1; law 3.3, "the thread of the run": when the day is
/// done, the world offers its end; critic-run R1). On days 1 to 3, from 09:00 to 17:30, once nothing the purse can pay
/// is left and no deal waits, Brannock carries his talk mark again and his line says the day may end: "Nothing more to
/// build today. Say the word and I sound the horn." A second touch on him while that line stands calls the night
/// (`SimDriver.callTheNight`, the dusk played in 4.0 s). Pure: derived from the realm's state every frame, nothing is
/// saved. Whether the line was heard today is the talk log's (UI state, never saved: `heardKey`).
enum NightOffer {
    /// Who offers the horn.
    static let speaker = "brannock"
    /// His line (Story.xcstrings, English only for now).
    static let lineKey = "line.brannock_horn_offer"
    /// The talk log's note that the offer was heard today (or answered: the night was called). Not a speaker id, so it
    /// never shifts anyone's lines (`TalkLog`, `GameModel.talkedToday`).
    static let heardKey = "brannock.horn"
    /// Law 3.3: the first three days (the player learns the day; later days have work enough).
    static let days = 1...3
    /// Law 3.3: from 09:00 (the morning's work first) to 17:30 (after that the horn comes by itself soon enough).
    static let fromHour = 9.0
    static let untilHour = 17.5
    /// The second touch counts once the line has stood this long (law 1's slow beat, 0.6 s): a double tap that only
    /// wanted to hear him never ends the day.
    static let wordAfter = MotionToken.slow.inSeconds

    /// True when the day's work is done and the offer stands (critic-run R1: "while no plot, recruit or yard offer is
    /// affordable and no order is open"): by day on days 1 to 3 between 09:00 and 17:30, nothing the purse can pay
    /// (`payable`) and no deal waiting (`dealWaits`). The count's own open order (a board up) is the model's to add
    /// (`GameModel.nightOfferStands`).
    static func stands(_ s: GameState, balance: Balance) -> Bool {
        guard !s.defeated, days.contains(s.day), DayClock.phase(at: s.hour) == .day,
              s.hour >= fromHour - 1e-9, s.hour <= untilHour + 1e-9, s.hour < SimDriver.hornCallHour else {
            return false
        }
        return !payable(s, balance: balance) && !dealWaits(s)
    }

    /// True while the purse can pay something now: a plot's offer (a free gift included), a recruit, the yard. The
    /// same rule as the marks of `TouchThings.world` ("marks only while the purse can pay"), so the offer comes
    /// exactly when the last bought thing's mark goes out.
    static func payable(_ s: GameState, balance: Balance) -> Bool {
        for plot in Realm.plots.indices where plot < s.plots.count {
            guard s.isUnlocked(plot: plot), KingTargets.hasCard(s, plot: plot, balance: balance) else { continue }
            if Build.options(s, plot: plot, balance: balance).contains(where: { $0.price <= s.gold }) { return true }
        }
        if RecruitCard.make(s, balance: balance).options.contains(where: { $0.canRecruit }) { return true }
        if let yard = TouchThings.yardThing(s, balance: balance), yard.marked { return true }
        return false
    }

    /// True while a deal waits today: a petitioner for the audience in the hall, or the Stranger at the gate (the
    /// horn would send them home unheard).
    static func dealWaits(_ s: GameState) -> Bool {
        !AudienceRules.queue(s, catalog: .standard).isEmpty
    }

    /// Brannock carries his talk mark for the offer: it stands and he was not heard saying it today.
    static func marks(_ s: GameState, balance: Balance, talked: Set<String>) -> Bool {
        !talked.contains(heardKey) && stands(s, balance: balance)
    }
}
