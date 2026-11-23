/// Brannock offers the horn (the polish audit's thing 6, step E1; law 3.3, "the thread of the run": when the day is
/// done, the world offers its end; critic-run R1). On days 1 to 3, from 09:00 to 17:30, once nothing the purse can pay
/// is left, no deal waits and no coins wait in the town, Brannock carries his talk mark again (for as long as the offer
/// stands, until the night is called: polish E1b) and his line says the day may end: "Nothing more to build today. Say
/// the word and I sound the horn." A second touch on him while that line stands calls the night
/// (`SimDriver.callTheNight`, the dusk played in 4.0 s). Pure: derived from the realm's state every frame, nothing is
/// saved. Whether the line was heard or the night called today is the talk log's (UI state, never saved: `heardKey`,
/// `calledKey`).
enum NightOffer {
    /// Who offers the horn.
    static let speaker = "brannock"
    /// His line (Story.xcstrings, English only for now).
    static let lineKey = "line.brannock_horn_offer"
    /// The talk log's note that the offer was heard today (or answered: the night was called). Not a speaker id, so it
    /// never shifts anyone's lines (`TalkLog`, `GameModel.talkedToday`).
    static let heardKey = "brannock.horn"
    /// Polish E1b (the director's call after E1, law 3.3: the standing offer): the talk log's note that the night was
    /// called today (Brannock's word or the pause sheet). Until then his mark stands, heard or not.
    static let calledKey = "brannock.horn.called"
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
    /// (`payable`), no deal waiting (`dealWaits`) and no coins of the day still waiting in the town (`coinsWait`).
    /// The count's own open order (a board up) is the model's to add (`GameModel.nightOfferStands`).
    static func stands(_ s: GameState, balance: Balance) -> Bool {
        guard !s.defeated, days.contains(s.day), DayClock.phase(at: s.hour) == .day,
              s.hour >= fromHour - 1e-9, s.hour <= untilHour + 1e-9, s.hour < SimDriver.hornCallHour else {
            return false
        }
        return !payable(s, balance: balance) && !dealWaits(s) && !coinsWait(s, balance: balance)
    }

    /// E1 gate (B1, P1): the day's coins still wait in the town, so "nothing more to build" would be false and the
    /// horn would let the people keep them (`Town.horn`): a household still owes with its door open (the first
    /// morning's 16 included, a field's too: the farmer pays only the lord), or the collector is on his way home with
    /// coins in his box. With the doors shut (unrest) nobody pays, so nothing waits; after the horn nothing does.
    static func coinsWait(_ s: GameState, balance: Balance) -> Bool {
        guard let day = s.town?.today, !day.closed else { return false }
        if !Town.waiting(s, balance: balance).isEmpty { return true }
        return day.collectorOut == true && day.collectorBack != true && day.collectorBox > 0
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

    /// Brannock carries his talk mark for the offer for as long as it stands, heard or not, until the night is called
    /// (polish E1b, the director's call: an offer, not a line heard once; so the one mark left in the world always
    /// says where the day goes on).
    static func marks(_ s: GameState, balance: Balance, talked: Set<String>) -> Bool {
        !talked.contains(calledKey) && stands(s, balance: balance)
    }
}
