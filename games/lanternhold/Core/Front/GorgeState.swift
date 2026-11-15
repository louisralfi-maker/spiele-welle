/// One beacon site in the gorge (docs/REALM.md section 5).
enum GorgeSiteState: String, Codable, Sendable, CaseIterable {
    /// Never raised: the ground is bare (and the next one can be raised there).
    case wild
    /// The builders are raising it (`GorgeState.raise`).
    case raising
    /// It burns: the fog cannot pass it.
    case lit
    /// It stood and fell: a cold beacon, relit by day for a third of its price.
    case dark
}

/// One beacon in a realm: its state and, while it burns, its strength.
struct GorgeSite: Codable, Sendable, Equatable {
    var state: GorgeSiteState = .wild
    var strength: Double = 0

    init(state: GorgeSiteState = .wild, strength: Double = 0) {
        self.state = state
        self.strength = strength
    }

    init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        state = (try? c.decodeIfPresent(GorgeSiteState.self, forKey: .state)) ?? .wild
        strength = max(0, (try? c.decodeIfPresent(Double.self, forKey: .strength)) ?? 0)
    }
}

/// The thing a beacon frees, one per stretch of the gorge (docs/REALM.md section 5: "one thing seen and one small gain
/// per stretch"). Stretch `rawValue` is held while beacon `rawValue` burns.
enum GorgeLand: Int, Codable, Sendable, CaseIterable {
    /// Stretch 1: every wall and gate work costs a little less.
    case quarry = 0
    /// Stretch 2: may be raised as a forward archers' post.
    case watchtower = 1
    /// Stretch 3: the braziers burn brighter.
    case camp = 2
    /// Stretch 4: a flag for the picture.
    case stones = 3
}

/// The builders raising a beacon: builder-seconds of work done and needed.
struct GorgeRaise: Codable, Sendable, Equatable {
    var site: Int
    var work: Double
    var total: Double
    /// The day it was ordered.
    var day: Int

    var progress: Double { total > 0 ? min(1, work / total) : 1 }
}

/// A moment for the picture: a new `at` (`GameState.simTime`) is a new event at `site`.
struct GorgeStamp: Codable, Sendable, Equatable {
    var at: Double
    var site: Int
}

/// The fog line moving: from where it stood (nil: no beacon held it) to where it stands now, over
/// `GorgeTuning.fogSeconds` from `at`.
struct GorgeFogShift: Codable, Sendable, Equatable {
    var at: Double
    var from: Double?
    var to: Double?
}

/// Tonight's tally (the dawn report and the T15 runs).
struct GorgeNightTally: Codable, Sendable, Equatable {
    var night = 0
    /// The harm the beacons took tonight.
    var struck = 0.0
    /// The beacons that fell tonight, in the order they fell.
    var fell: [Int] = []
    /// Arrows the watch loosed from the old watchtower.
    var watchShots = 0

    init(night: Int = 0) { self.night = night }

    init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        night = (try? c.decodeIfPresent(Int.self, forKey: .night)) ?? 0
        struck = max(0, (try? c.decodeIfPresent(Double.self, forKey: .struck)) ?? 0)
        fell = ((try? c.decodeIfPresent([Int].self, forKey: .fell)) ?? []).filter { (0..<Gorge.sites).contains($0) }
        watchShots = max(0, (try? c.decodeIfPresent(Int.self, forKey: .watchShots)) ?? 0)
    }
}

/// The gorge beacons' own state in a realm (docs/REALM.md section 5). `GameState.gorge` is nil for a realm without the
/// rule (the reference bots, saves from before it); `Gorge.adopt` turns it on. Saved with the dawn snapshot: every field
/// decodes with a default, so a field added later never makes a save corrupt, and a state that breaks the rule's order
/// (a beacon lit beyond a cold one) is mended on load.
struct GorgeState: Codable, Sendable, Equatable {
    /// The four sites, nearest first.
    var sites: [GorgeSite] = Array(repeating: GorgeSite(), count: Gorge.sites)
    /// The beacon being raised, if any (one at a time).
    var raise: GorgeRaise?
    /// The ruined watchtower was raised as a forward post (it is manned while its stretch is held).
    var watchtowerRaised = false
    /// Seconds until the watch looses again.
    var watchCooldown = 0.0
    /// How many beacons burned at the last dawn (the report tells what changed since: land freed).
    var heldAtDawn = 0
    /// The beacons lit since the last dawn (raised or relit by day), and whether each was a relight.
    var litToday: [Int] = []
    var relitToday: [Int] = []
    /// The watchtower was raised since the last dawn.
    var watchRaisedToday = false
    var tonight = GorgeNightTally()
    /// The fog line's last move, so the bank rolls instead of jumping.
    var fogShift: GorgeFogShift?
    /// The stamps for the picture: the last beacon lit, the last that fell.
    var lastLit: GorgeStamp?
    var lastFall: GorgeStamp?

    init() {}

    init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        var read = (try? c.decodeIfPresent([GorgeSite].self, forKey: .sites)) ?? []
        read = Array(read.prefix(Gorge.sites))
        while read.count < Gorge.sites { read.append(GorgeSite()) }
        sites = read
        let site = 0..<Gorge.sites
        raise = try? c.decodeIfPresent(GorgeRaise.self, forKey: .raise)
        if let job = raise, !site.contains(job.site) || job.total <= 0 { raise = nil }
        watchtowerRaised = (try? c.decodeIfPresent(Bool.self, forKey: .watchtowerRaised)) ?? false
        watchCooldown = max(0, (try? c.decodeIfPresent(Double.self, forKey: .watchCooldown)) ?? 0)
        heldAtDawn = min(Gorge.sites, max(0, (try? c.decodeIfPresent(Int.self, forKey: .heldAtDawn)) ?? 0))
        litToday = ((try? c.decodeIfPresent([Int].self, forKey: .litToday)) ?? []).filter { site.contains($0) }
        relitToday = ((try? c.decodeIfPresent([Int].self, forKey: .relitToday)) ?? []).filter { site.contains($0) }
        watchRaisedToday = (try? c.decodeIfPresent(Bool.self, forKey: .watchRaisedToday)) ?? false
        tonight = (try? c.decodeIfPresent(GorgeNightTally.self, forKey: .tonight)) ?? GorgeNightTally()
        fogShift = try? c.decodeIfPresent(GorgeFogShift.self, forKey: .fogShift)
        lastLit = try? c.decodeIfPresent(GorgeStamp.self, forKey: .lastLit)
        lastFall = try? c.decodeIfPresent(GorgeStamp.self, forKey: .lastFall)
        mend()
    }

    /// Beacons burn nearest first: one lit beyond a site that does not burn is cold (`dark`), a raise is only ever the
    /// site after the last lit one, and only one site is being raised.
    mutating func mend() {
        var open = true
        for index in sites.indices {
            if sites[index].state == .lit && !open { sites[index].state = .dark }
            if sites[index].state != .lit { open = false }
            if sites[index].state != .lit { sites[index].strength = 0 }
        }
        let next = held
        for index in sites.indices where sites[index].state == .raising {
            if raise?.site != index || index != next { sites[index].state = .wild }
        }
        if let job = raise {
            if job.site != next || !sites.indices.contains(job.site) {
                raise = nil
            } else if sites[job.site].state == .wild {
                sites[job.site].state = .raising
            } else if sites[job.site].state != .raising {
                raise = nil
            }
        }
    }

    /// The beacons that burn, nearest first (always the first `held` sites).
    var held: Int {
        var count = 0
        for site in sites {
            guard site.state == .lit else { break }
            count += 1
        }
        return count
    }
}

/// The gorge half of the dawn report (`DawnReport.gorge`). Pure data; the lines are `lines()`, worded by `GorgeText`
/// from Front.xcstrings.
struct GorgeDawnReport: Codable, Sendable, Equatable {
    /// Beacons raised yesterday that burned through the night (nearest first).
    var lit: [Int] = []
    /// Beacons relit yesterday that burned through the night.
    var relit: [Int] = []
    /// Beacons that fell in the night, in the order they fell.
    var lost: [Int] = []
    /// Land freed since the last dawn (held now, not then).
    var freed: [GorgeLand] = []
    /// Beacons burning at this dawn.
    var held = 0
    /// The watchtower was raised yesterday and is manned.
    var watchRaised = false

    init(lit: [Int] = [], relit: [Int] = [], lost: [Int] = [], freed: [GorgeLand] = [], held: Int = 0,
         watchRaised: Bool = false) {
        self.lit = lit
        self.relit = relit
        self.lost = lost
        self.freed = freed
        self.held = held
        self.watchRaised = watchRaised
    }

    init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let site = 0..<Gorge.sites
        lit = ((try? c.decodeIfPresent([Int].self, forKey: .lit)) ?? []).filter { site.contains($0) }
        relit = ((try? c.decodeIfPresent([Int].self, forKey: .relit)) ?? []).filter { site.contains($0) }
        lost = ((try? c.decodeIfPresent([Int].self, forKey: .lost)) ?? []).filter { site.contains($0) }
        freed = (try? c.decodeIfPresent([GorgeLand].self, forKey: .freed)) ?? []
        held = min(Gorge.sites, max(0, (try? c.decodeIfPresent(Int.self, forKey: .held)) ?? 0))
        watchRaised = (try? c.decodeIfPresent(Bool.self, forKey: .watchRaised)) ?? false
    }

    /// The report's gorge lines: what fell in the night first (the news), then what burns anew, then the land freed and
    /// the watch. A night with nothing new says nothing.
    func lines() -> [GorgeLine] {
        var lines: [GorgeLine] = []
        if !lost.isEmpty {
            if held == 0 && lit.isEmpty && relit.isEmpty {
                lines.append(GorgeLine(key: GorgeLine.lostAll))
            } else {
                lines.append(GorgeLine(key: lost.count == 1 ? GorgeLine.lostOne : GorgeLine.lostMore))
            }
        }
        if !lit.isEmpty { lines.append(GorgeLine(key: GorgeLine.lit)) }
        if !relit.isEmpty { lines.append(GorgeLine(key: relit.count == 1 ? GorgeLine.relitOne : GorgeLine.relitMore)) }
        for land in freed { lines.append(GorgeLine(key: GorgeLine.freed(land))) }
        if watchRaised { lines.append(GorgeLine(key: GorgeLine.watch)) }
        return lines
    }
}

/// One line of the report's gorge half: a key of Front.xcstrings.
struct GorgeLine: Sendable, Equatable {
    static let lit = "front.gorge.lit"
    static let relitOne = "front.gorge.relit.one"
    static let relitMore = "front.gorge.relit.more"
    static let lostOne = "front.gorge.lost.one"
    static let lostMore = "front.gorge.lost.more"
    static let lostAll = "front.gorge.lost.all"
    static let quarry = "front.gorge.land.quarry"
    static let watchtower = "front.gorge.land.watchtower"
    static let camp = "front.gorge.land.camp"
    static let stones = "front.gorge.land.stones"
    static let watch = "front.gorge.watch"

    /// Every key (the text tests check each in English and German).
    static let reportKeys = [lit, relitOne, relitMore, lostOne, lostMore, lostAll, quarry, watchtower, camp, stones,
                             watch]

    /// The line for a stretch freed.
    static func freed(_ land: GorgeLand) -> String {
        switch land {
        case .quarry: return quarry
        case .watchtower: return watchtower
        case .camp: return camp
        case .stones: return stones
        }
    }

    var key: String
}
