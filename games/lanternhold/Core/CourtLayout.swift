/// What a court figure does in a frame.
enum CourtPose: String, Sendable, Equatable {
    case idle, walk
}

/// One figure in the castle: a court member at his round, a guest, or a petitioner waiting for the audience.
struct CourtFigure: Sendable, Equatable {
    /// The speaker id (`Speakers`).
    var who: String
    var sprite: SpriteID
    var glow: SpriteID?
    /// The foot point's world x.
    var x: Double
    /// 1 faces right, −1 left (the strip faces right; the renderer mirrors it).
    var facing: Int
    var pose: CourtPose
    /// The frame in its strip (`SpeakerBody`'s walk or idle frames).
    var frame: Int
    var room: WorldLayout.RoomID?
    /// The petition a waiting figure brings (nil for the court at its round).
    var petition: String?
    /// A waiting petitioner's look (the composed portrait and the name of townsfolk).
    var look: Int?
    /// The seated strip of a petitioner who waits on a bench (the lord pass; nil: he stands).
    var seated: SpriteID? = nil
}

/// A prop of the court: the benches, the tax lectern, Marek's cart on his days, the statue once a petition raised it.
struct CourtProp: Sendable, Equatable {
    var sprite: SpriteID
    /// The left edge in world px (props stand on the ground line).
    var x: Double
}

/// A court member's daily round: the stops he strolls between, which way he looks there, how long he stays; and where
/// he is from the horn to dawn.
struct CourtRoutine: Sendable, Equatable {
    var stops: [Double]
    var faces: [Int]
    var dwell: [Double]
    var night: Double
    var nightFacing: Int
    /// Px per second (a stroll; the king walks 36).
    var speed = 16.0
    /// Seconds into the round at 06:00, so the court never moves in step.
    var offset = 0.0
}

/// The court's places (DESIGN.md "M3 in detail"): a pure function of the day, the hour, the flags and today's queue
/// that puts every court member and today's guests in the castle, and today's petitioners on the great hall's benches.
///
/// - Odile by the throne in the hall (stepping to her tax lectern beyond the hearth now and then); Brannock in the
///   bunkhouse door by the drill yard (b3-yard); Pip wandering the courtyard and the hall; Mother Hesper in the chapel by day and at the hearth at
///   night; Tamsin in the kitchen; Bram at the smithy; Marek with his cart in the courtyard on his days (every third
///   day, and any day he brings a petition), by day only.
/// - Seren: waiting at the front gate on the day her petition comes, then from the moment she is let in
///   (`stranger_in`) in the great hall's far corner, gone once handed over (`seren_handed_over`).
/// - Guests stand in the hall on their petition's day while they wait; townsfolk petitioners take the benches'
///   four places, the next one nearest the throne (seated where a seated strip of their body exists, `seatedStrip`;
///   the others stand there), more of them stand behind. Court members who petition stay at their round
///   (the audience calls them up). Heard petitioners have left the queue, so they are not placed.
enum CourtLayout {
    /// Where the heard petitioner stands before the throne (the throne's middle is x 1837, `WorldLayout.throneX`).
    static let audienceSpot = 1800.0
    /// The tax lectern (its left edge): Odile's desk beyond the hearth, well away from the throne (M3 fix, U2: beside
    /// the throne the lectern, the throne and Odile lay within 16 px, so "Taxes" hid the audience).
    static let lecternX = 1908.0
    /// The dais: from the benches' end to the hearth. While petitioners wait in the hall the throne owns all of it
    /// (`KingTargets.target`), whoever stands there.
    static let dais: ClosedRange<Double> = 1792...1870
    /// The two benches' left edges, and the four waiting places at them, the next petitioner nearest the throne. A
    /// bench seats two: the sitters' 12 px frames stand at the bench's x + 2 and + 18 (ART-look2.md 15.2), so their
    /// middles are at + 8 and + 24.
    static let benches: [Double] = [1712, 1760]
    static let seats: [Double] = [1784, 1768, 1736, 1720]
    /// The seated strip of a waiting body (frame 0 sits, frame 1 nods), nil for a body that has none and stands.
    static func seatedStrip(_ body: SpriteID) -> SpriteID? {
        switch body {
        case .citizen: return .citizenSeated
        case .citizenB: return .citizenBSeated
        case .citizenC: return .citizenCSeated
        default: return nil
        }
    }
    /// Standing places for guests and for petitioners beyond the four.
    static let standing: [Double] = [1706, 1754, 1698, 1748, 1690]
    static let serenCorner = 1950.0
    /// Before the gatehouse's portcullis, in the gorge: where the Stranger waits to be let in.
    static let strangerAtGate = 1352.0
    /// b3-yard (build 3, wave 2, lane 2, step 3; the director's ruling of 21.11.2026, 17:10, and his pick at 17:31): Marek's
    /// cart stands at the castle's east end, flush with the bakehouse's east wall (2218 to 2266), just inside the back
    /// gate he comes through from Tallowford (it stood before the barracks at 1486, which is the drill yard's bunkhouse
    /// now). Clear of Tamsin's oven stop (2208), the lord's talk spot for the collector (2272) and the collector's post.
    static let marekCartX = 2218.0
    static let statueX = 1680.0
    static let marekEvery = 3
    static let serenInFlag = "stranger_in"
    static let serenGoneFlag = "seren_handed_over"
    /// A walk frame every 7 game px; the breath is the one breath (polish step A1, `FigureMotion.breath`: frame A held
    /// 1.15 s, this, then frame B 0.85 s).
    static let walkFramePixels = 7.0
    static let breathSeconds = FigureMotion.breathA

    static let courtOrder = ["odile", "brannock", "pip", "hesper", "tamsin", "bram", "marek", "seren"]

    static let routines: [String: CourtRoutine] = [
        // M3 fix (U2) and the lord pass: Odile stands a step off the throne (its middle is 1837; she is 21 px to its
        // right, as in the art's hall scenes, and never covers the seated lord) and walks round the hearth to her
        // lectern's near side (1894, the lectern from 1908), where she faces it.
        "odile": CourtRoutine(stops: [1858, 1894], faces: [-1, 1], dwell: [14, 6], night: 1860, nightFacing: -1),
        // b3-yard (build 3, wave 2, lane 2, step 3; the director's pick of 21.11.2026, 17:31, and the critic's H1):
        // Brannock, the drill master, stands in the bunkhouse door at 1513 ("the captain in his doorway"; the door,
        // 1505 to 1516, is allowed to him alone), by day and by night. Both day stops are the door: he only turns,
        // watching the drill westward and the butts eastward (his walk along the line comes in a later step). Step 2's
        // 1428 stood on the gate's catapult model and against the archer, 1472 before the butt, and the night's 1424
        // on the catapult model among the waiting guards. Clear of the lord's lane, the site's middle (1456) and its
        // tag, of every yard thing, more than 8 px from every mark (the barracks' recruit marks 1497 and 1529, the
        // yard's 1456), and under the arrow's arc (`YardLook`, part C). The review: 1513, not 1511, so his talk tag
        // stands a full tag (16 px) from both recruit tags (1497, 1529) and none of the three gives way
        // (`TouchRules.marked`); the arrow still passes 5.3 px over him, and his box (1505 to 1520) covers the rear
        // butt's first two columns.
        "brannock": CourtRoutine(stops: [1513, 1513], faces: [-1, 1], dwell: [9, 9], night: 1513, nightFacing: -1,
                                 offset: 5.5),
        "pip": CourtRoutine(stops: [1612, 1690, 1770, 1700], faces: [1, 1, -1, -1], dwell: [5, 4, 7, 3], night: 1880,
                            nightFacing: -1, speed: 22, offset: 11),
        // M3 step 3: Hesper at the altar (2058) and by the pews (2012), Tamsin at her table (2158) and at the
        // oven-hearth under the chimney (2208), where the art lane's interiors put them (ART-court.md).
        "hesper": CourtRoutine(stops: [2058, 2012], faces: [1, -1], dwell: [12, 8], night: 1900, nightFacing: -1,
                               offset: 3),
        "tamsin": CourtRoutine(stops: [2158, 2208], faces: [1, 1], dwell: [8, 10], night: 2170, nightFacing: -1,
                               offset: 7),
        "bram": CourtRoutine(stops: [1566, 1588], faces: [1, 1], dwell: [10, 6], night: 1580, nightFacing: 1,
                             offset: 2),
        // b3-yard (step 3): Marek stands before his cart's east half (2242 to 2266) like a seller at his stall, at 2256
        // and 2249, facing the castle the lord comes from; his box (14 px) ends at 2262, so the lord talking to the
        // collector from the west (2272, his box from 2264) never touches him. By day only (the night stop is beside
        // the cart too).
        "marek": CourtRoutine(stops: [2256, 2249], faces: [-1, -1], dwell: [10, 8], night: 2249, nightFacing: -1,
                              offset: 4),
    ]

    /// Marek and his cart come every third day, and on any day he brings a petition.
    static func isMarekDay(_ day: Int, speakers: [String]) -> Bool {
        day % marekEvery == 0 || speakers.contains("marek")
    }

    /// Where a round puts its walker `seconds` after dawn: the spot, the way he faces, whether he walks and how far
    /// along the current leg (for the walk frame).
    static func place(_ routine: CourtRoutine, seconds: Double) -> (x: Double, facing: Int, walking: Bool,
                                                                   walked: Double) {
        let n = min(routine.stops.count, routine.faces.count, routine.dwell.count)
        guard n > 1 else { return (routine.stops.first ?? routine.night, routine.faces.first ?? 1, false, 0) }
        var cycle = 0.0
        for i in 0..<n {
            cycle += routine.dwell[i] + abs(routine.stops[(i + 1) % n] - routine.stops[i]) / routine.speed
        }
        guard cycle > 0 else { return (routine.stops[0], routine.faces[0], false, 0) }
        var t = (seconds + routine.offset).truncatingRemainder(dividingBy: cycle)
        if t < 0 { t += cycle }
        for i in 0..<n {
            if t < routine.dwell[i] { return (routine.stops[i], routine.faces[i], false, 0) }
            t -= routine.dwell[i]
            let from = routine.stops[i]
            let to = routine.stops[(i + 1) % n]
            let leg = abs(to - from) / routine.speed
            if t < leg {
                let walked = t * routine.speed
                return (to > from ? from + walked : from - walked, to >= from ? 1 : -1, true, walked)
            }
            t -= leg
        }
        return (routine.stops[0], routine.faces[0], false, 0)
    }

    /// The frame of a body: walking, one walk frame every `walkFramePixels`; standing, a breath every
    /// `breathSeconds`.
    static func frame(_ body: SpeakerBody, walking: Bool, walked: Double, seconds: Double) -> Int {
        if walking {
            return body.walk.lowerBound + Int(max(0, walked) / walkFramePixels) % max(1, body.walk.count)
        }
        guard body.idle.count > 1 else { return body.idle.lowerBound }
        return body.idle.lowerBound + FigureMotion.breath(time: max(0, seconds), id: 0)
    }

    /// Seconds since 06:00 (for the rounds and the breath).
    static func secondsSinceDawn(_ hour: Double) -> Double {
        var hours = DayClock.wrap(hour) - 6
        if hours < 0 { hours += DayClock.hoursPerDay }
        return hours * DayClock.secondsPerHour
    }

    /// Every figure of the castle now (see the type's rules).
    static func figures(day: Int, hour: Double, flags: [String], queue: [Petitioner],
                        catalog: PetitionCatalog) -> [CourtFigure] {
        let byDay = DayClock.phase(at: hour) == .day
        let seconds = secondsSinceDawn(hour)
        let waiting = byDay ? queue : []
        var speakers: [String] = []
        for petitioner in waiting {
            if let petition = catalog.petition(petitioner.id) { speakers.append(petition.speaker) }
        }
        var list: [CourtFigure] = []
        for id in courtOrder {
            guard let speaker = Speakers.speaker(id) else { continue }
            let body = speaker.body
            let still = frame(body, walking: false, walked: 0, seconds: seconds)
            if id == "seren" {
                if flags.contains(serenGoneFlag) { continue }
                if flags.contains(serenInFlag) {
                    list.append(CourtFigure(who: id, sprite: body.sprite, glow: body.glow, x: serenCorner, facing: -1,
                                            pose: .idle, frame: still,
                                            room: WorldLayout.room(at: serenCorner), petition: nil, look: nil))
                } else if let found = waiting.first(where: { catalog.petition($0.id)?.speaker == id }) {
                    list.append(CourtFigure(who: id, sprite: body.sprite, glow: body.glow, x: strangerAtGate, facing: 1,
                                            pose: .idle, frame: still,
                                            room: WorldLayout.room(at: strangerAtGate), petition: found.id,
                                            look: found.look))
                }
                continue
            }
            if id == "marek" && !(byDay && isMarekDay(day, speakers: speakers)) { continue }
            guard let routine = routines[id] else { continue }
            if byDay {
                let at = place(routine, seconds: seconds)
                list.append(CourtFigure(who: id, sprite: body.sprite, glow: body.glow, x: at.x, facing: at.facing,
                                        pose: at.walking ? .walk : .idle,
                                        frame: frame(body, walking: at.walking, walked: at.walked, seconds: seconds),
                                        room: WorldLayout.room(at: at.x), petition: nil, look: nil))
            } else {
                list.append(CourtFigure(who: id, sprite: body.sprite, glow: body.glow, x: routine.night,
                                        facing: routine.nightFacing, pose: .idle,
                                        frame: frame(body, walking: false, walked: 0, seconds: seconds),
                                        room: WorldLayout.room(at: routine.night), petition: nil, look: nil))
            }
        }
        var seat = 0
        var stand = 0
        func standingSpot() -> Double {
            var spot = standing.last ?? 1690
            if stand < standing.count {
                spot = standing[stand]
            } else {
                spot -= 8 * Double(stand - standing.count + 1)
            }
            stand += 1
            return spot
        }
        for petitioner in waiting {
            guard let petition = catalog.petition(petitioner.id),
                  let speaker = Speakers.speaker(petition.speaker) else { continue }
            let body = speaker.body
            let x: Double
            var seated: SpriteID?
            switch speaker.role {
            case .court:
                continue
            case .guest:
                x = standingSpot()
            case .townsfolk:
                if seat < seats.count {
                    x = seats[seat]
                    seat += 1
                    seated = seatedStrip(body.sprite)
                } else {
                    x = standingSpot()
                }
            }
            list.append(CourtFigure(who: speaker.id, sprite: body.sprite, glow: body.glow, x: x, facing: 1, pose: .idle,
                                    frame: frame(body, walking: false, walked: 0,
                                                 seconds: seconds + Double(seat + stand)),
                                    room: WorldLayout.room(at: x), petition: petition.id, look: petitioner.look,
                                    seated: seated))
        }
        return list
    }

    /// The figures of the realm now (today's queue only while it is today's).
    static func figures(_ s: GameState, catalog: PetitionCatalog) -> [CourtFigure] {
        figures(day: s.day, hour: s.hour, flags: s.flags, queue: todaysQueue(s), catalog: catalog)
    }

    static func todaysQueue(_ s: GameState) -> [Petitioner] {
        guard let court = s.court, court.queueDay == s.day else { return [] }
        return court.queue
    }

    /// The court's props: the two benches and the tax lectern always, Marek's cart on his days (by day) or every day
    /// once `castle.courtyard.stall` shows, the statue once `castle.statue` shows.
    static func props(day: Int, hour: Double, world: [String], queue: [Petitioner],
                      catalog: PetitionCatalog) -> [CourtProp] {
        var list = benches.map { CourtProp(sprite: .bench, x: $0) }
        list.append(CourtProp(sprite: .taxLectern, x: lecternX))
        let byDay = DayClock.phase(at: hour) == .day
        var speakers: [String] = []
        if byDay {
            for petitioner in queue {
                if let petition = catalog.petition(petitioner.id) { speakers.append(petition.speaker) }
            }
        }
        if world.contains("castle.courtyard.stall") || (byDay && isMarekDay(day, speakers: speakers)) {
            list.append(CourtProp(sprite: .marekCart, x: marekCartX))
        }
        if world.contains("castle.statue") { list.append(CourtProp(sprite: .statue, x: statueX)) }
        return list
    }

    static func props(_ s: GameState, catalog: PetitionCatalog) -> [CourtProp] {
        props(day: s.day, hour: s.hour, world: s.court?.world ?? [], queue: todaysQueue(s), catalog: catalog)
    }
}
