/// What became of a craftsman's offer.
enum CraftAnswer: String, Codable, Sendable {
    /// He waits in the hall today (first visit or back once).
    case waiting
    /// "Not now" (or not heard by the horn on his first visit): he comes back once, on `returnDay` or the next free day.
    case later
    case commissioned
    /// "No, thank you" (or "not now" again, or not heard on his return): he never comes back.
    case declined
}

/// One craftsman the realm has met.
struct CraftMeeting: Codable, Sendable, Equatable {
    var id: String
    /// The day he first came.
    var day: Int
    var answer: CraftAnswer
    /// "Not now": the day he may come back.
    var returnDay: Int?
    /// He came back once already.
    var returned = false

    init(id: String, day: Int, answer: CraftAnswer, returnDay: Int? = nil, returned: Bool = false) {
        self.id = id
        self.day = day
        self.answer = answer
        self.returnDay = returnDay
        self.returned = returned
    }

    init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        day = try c.decodeIfPresent(Int.self, forKey: .day) ?? 0
        answer = try c.decodeIfPresent(CraftAnswer.self, forKey: .answer) ?? .declined
        returnDay = try c.decodeIfPresent(Int.self, forKey: .returnDay)
        returned = try c.decodeIfPresent(Bool.self, forKey: .returned) ?? false
    }
}

/// A commissioned work: paid on `orderedDay`, it stands from the dawn of `readyDay`.
struct CraftOrder: Codable, Sendable, Equatable {
    /// The craftsman (his work and its effect are in the book).
    var id: String
    var orderedDay: Int
    var readyDay: Int
    var stands = false

    init(id: String, orderedDay: Int, readyDay: Int, stands: Bool = false) {
        self.id = id
        self.orderedDay = orderedDay
        self.readyDay = readyDay
        self.stands = stands
    }

    init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        orderedDay = try c.decodeIfPresent(Int.self, forKey: .orderedDay) ?? 0
        readyDay = try c.decodeIfPresent(Int.self, forKey: .readyDay) ?? 0
        stands = try c.decodeIfPresent(Bool.self, forKey: .stands) ?? false
    }
}

/// The craftsmen's state in the save (`GameState.craft`, Optional: nil is a realm without craftsmen, which is every
/// bot's and test's realm and every save from before build 3 until the game starts it, `CraftVisits.begin`). Every
/// field decodes with a default.
struct CraftState: Codable, Sendable, Equatable {
    /// The day the visit rules last ran (they run once a day, once the day's petitioners are drawn).
    var checkedDay = 0
    /// The visit day whose craftsman has not come yet (0: none open): it opens on days 4, 7, 10, ... and waits for a
    /// free day until the next one opens.
    var slotDay = 0
    /// Every craftsman met, in the order they first came.
    var met: [CraftMeeting] = []
    /// Every work commissioned, in order.
    var works: [CraftOrder] = []

    init() {}

    init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        checkedDay = try c.decodeIfPresent(Int.self, forKey: .checkedDay) ?? 0
        slotDay = try c.decodeIfPresent(Int.self, forKey: .slotDay) ?? 0
        met = try c.decodeIfPresent([CraftMeeting].self, forKey: .met) ?? []
        works = try c.decodeIfPresent([CraftOrder].self, forKey: .works) ?? []
    }

    func meeting(_ id: String) -> CraftMeeting? { met.first { $0.id == id } }

    /// True when the work of this craftsman stands.
    func stands(_ id: String) -> Bool { works.contains { $0.id == id && $0.stands } }

    var anyStands: Bool { works.contains { $0.stands } }
}

/// The travelling craftsmen's visits (docs/TOWN.md section 4), pure and deterministic:
///
/// - From day 4 a visit is due every third day (4, 7, 10, ...). It waits for a free day (no story petition in today's
///   queue except the houses' audiences that come on top) until the next one is due; then one craftsman joins the
///   audience after the day's petitioners, drawn with his own stream from the seed and the day among those not yet
///   met whose day has come and whose `needs` stand. One craftsman a day at most.
/// - "Not now" brings him back once, four days later or on the next free day after it (before a new one); a craftsman
///   not heard by the horn on his first visit counts as "not now", on his return as "no". Nobody's happiness suffers
///   for an unheard craftsman: he is a trader, not a subject.
/// - Commissioning pays at once (the offer's gold); the work stands from the dawn `days` later (`CraftWorks.dawn`).
/// - Bots never commission: the reference bot's audience passes the craftsman by, so a realm in which nobody is
///   commissioned plays exactly as one without craftsmen (`CraftTests.testARunWithoutCommissionsIsTodaysRun`).
enum CraftVisits {
    /// Starts the craftsmen in a realm the player plays (the hooks in `GameStart.realm` and `SimDriver.restart`).
    static func begin(_ s: inout GameState) {
        if s.craft == nil { s.craft = CraftState() }
    }

    static func isOffer(_ id: String) -> Bool { CraftBook.isCraft(id) }

    static func isVisitDay(_ day: Int, rules: CraftRules) -> Bool {
        let every = max(1, rules.every)
        return day >= rules.firstDay && (day - rules.firstDay) % every == 0
    }

    /// A story day: today's queue holds a story petition, on its days or as a follow-up, that does not come on top
    /// (the houses' audiences do).
    static func isStoryDay(_ queue: [Petitioner], catalog: PetitionCatalog) -> Bool {
        for petitioner in queue {
            guard let petition = catalog.petition(petitioner.id), petition.kind == .story else { continue }
            if petition.onTop != true { return true }
        }
        return false
    }

    /// The craftsman's look: 31 bits from his id (his portrait has fixed parts; the look keeps the hall's walkers apart).
    static func look(_ id: String) -> Int {
        var key: UInt64 = 0x4352_4146_5453_4D4E
        for scalar in id.unicodeScalars {
            key = (key ^ UInt64(scalar.value)) &* 0x0000_0100_0000_01B3
        }
        return Int(SeededRandom.mix(key) >> 33)
    }

    /// The day's own stream for the draw (it never moves the simulation's stream or the petitions' queue stream).
    static func drawSeed(_ seed: UInt64, day: Int) -> UInt64 {
        SeededRandom.mix((seed ^ 0x4352_4146_5453_4D45) &+ UInt64(truncatingIfNeeded: day) &* SeededRandom.increment)
    }

    /// True when one of the craftsman's `needs` stands (or he needs nothing).
    static func needsMet(_ craftsman: Craftsman, _ s: GameState) -> Bool {
        if craftsman.needs.isEmpty { return true }
        for name in craftsman.needs {
            if let item = BuildItem(rawValue: name), s.has(item) { return true }
        }
        return false
    }

    /// The craftsmen who may come for the first time today, in the book's order.
    static func newcomers(_ s: GameState, craft: CraftState, book: CraftBook) -> [Craftsman] {
        book.craftsmen.filter { c in
            craft.meeting(c.id) == nil && s.day >= max(c.from, book.rules.firstDay) && needsMet(c, s)
        }
    }

    /// Runs once a day by day, after the day's petitioners are drawn (the hook in `PetitionEngine.prepare`): opens the
    /// visit on its day and lets a craftsman join the queue on a free day.
    static func arrive(_ s: inout GameState, catalog: PetitionCatalog, book: CraftBook = .standard) {
        guard var craft = s.craft, craft.checkedDay != s.day, var court = s.court, court.queueDay == s.day else {
            return
        }
        craft.checkedDay = s.day
        if isVisitDay(s.day, rules: book.rules) { craft.slotDay = s.day }
        defer { s.craft = craft }
        guard !book.craftsmen.isEmpty, !isStoryDay(court.queue, catalog: catalog),
              !court.queue.contains(where: { isOffer($0.id) }) else { return }
        var visitor: String?
        var again = false
        if let position = craft.met.firstIndex(where: { $0.answer == .later && ($0.returnDay ?? Int.max) <= s.day }),
           book.craftsman(craft.met[position].id) != nil {
            craft.met[position].answer = .waiting
            craft.met[position].returned = true
            visitor = craft.met[position].id
            again = true
        } else if craft.slotDay > 0 {
            let open = newcomers(s, craft: craft, book: book)
            if !open.isEmpty {
                var rng = SeededRandom(seed: drawSeed(s.seed, day: s.day))
                let pick = open[rng.int(in: 0...(open.count - 1))]
                craft.met.append(CraftMeeting(id: pick.id, day: s.day, answer: .waiting))
                craft.slotDay = 0
                visitor = pick.id
            }
        }
        guard let id = visitor else { return }
        court.queue.append(Petitioner(id: CraftBook.offerID(id, again: again), reason: .random, look: look(id)))
        s.court = court
    }

    /// The craftsman was heard (the hook in `PetitionEngine.hear`, after the offer's gold was paid): the commission
    /// is ordered, "not now" sets his return, "no, thank you" sends him on.
    static func heard(_ s: inout GameState, petition id: String, choice: Int, book: CraftBook = .standard) {
        guard let visit = CraftBook.visit(id), let craftsman = book.craftsman(visit.craftsman) else { return }
        var craft = s.craft ?? CraftState()
        var meeting = craft.meeting(craftsman.id) ?? CraftMeeting(id: craftsman.id, day: s.day, answer: .waiting)
        if choice == 0 {
            meeting.answer = .commissioned
            meeting.returnDay = nil
            craft.works.append(CraftOrder(id: craftsman.id, orderedDay: s.day, readyDay: s.day + max(1, craftsman.days)))
        } else if choice == 1 && !visit.again {
            meeting.answer = .later
            meeting.returnDay = s.day + max(1, book.rules.returnAfter)
        } else {
            meeting.answer = .declined
            meeting.returnDay = nil
        }
        if let position = craft.met.firstIndex(where: { $0.id == craftsman.id }) {
            craft.met[position] = meeting
        } else {
            craft.met.append(meeting)
        }
        s.craft = craft
    }

    /// The horn (the hook at the start of `PetitionEngine.horn`): a craftsman still waiting leaves without costing
    /// happiness; on his first visit he comes back once, on his return he is gone.
    static func horn(_ s: inout GameState, book: CraftBook = .standard) {
        guard var court = s.court, court.queue.contains(where: { isOffer($0.id) }) else { return }
        var craft = s.craft ?? CraftState()
        for petitioner in court.queue {
            guard let visit = CraftBook.visit(petitioner.id),
                  let position = craft.met.firstIndex(where: { $0.id == visit.craftsman }) else { continue }
            if visit.again {
                craft.met[position].answer = .declined
                craft.met[position].returnDay = nil
            } else {
                craft.met[position].answer = .later
                craft.met[position].returnDay = s.day + max(1, book.rules.returnAfter)
            }
        }
        court.queue.removeAll { isOffer($0.id) }
        s.court = court
        if s.craft != nil { s.craft = craft }
    }
}
