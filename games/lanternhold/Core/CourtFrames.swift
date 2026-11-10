import Foundation

/// A heard petitioner leaving (M3 step 3): townsfolk and guests walk out of the great hall by its door after their
/// audience, the Stranger into the castle when she is let in or back into the gorge when she is not; each fades at the
/// end of its walk. Court members who petitioned walk back to their round instead (`CourtMotion`).
struct CourtLeaver: Sendable, Equatable {
    static let speed = 56.0
    static let fadeSeconds = 0.35
    /// Where townsfolk and guests leave the hall (the door of `hallFront` is on its courtyard side).
    static let hallDoor = 1712.0

    var who: String
    var body: SpeakerBody
    var look: Int?
    var x: Double
    var toX: Double
    var facing: Int
    /// 1 while walking, falling to 0 after arriving.
    var alpha = 1.0

    init(who: String, body: SpeakerBody, look: Int?, from x: Double, to toX: Double) {
        self.who = who
        self.body = body
        self.look = look
        self.x = x
        self.toX = toX
        facing = toX >= x ? 1 : -1
    }

    var isWalking: Bool { abs(toX - x) > 0.01 }

    /// Moves the walk on; false once the leaver is gone.
    mutating func step(dt: Double) -> Bool {
        let move = CourtLeaver.speed * max(0, dt)
        let gap = toX - x
        if abs(gap) > move {
            x += gap > 0 ? move : -move
            return true
        }
        x = toX
        alpha -= max(0, dt) / CourtLeaver.fadeSeconds
        return alpha > 0
    }
}

/// Smooths where the court is drawn (UI only): each figure walks toward its place from `CourtLayout` at a stroll, so a
/// court member walks back to his round after his audience or a talk instead of jumping; a new figure appears at its
/// place, a jump farther than `snap` (Seren let in, a day passing) is taken at once, and Reduce Motion takes every
/// change at once.
enum CourtMotion {
    static let speed = 42.0
    static let snap = 240.0

    static func step(_ drawn: [String: Double], targets: [String: Double], dt: Double,
                     reduceMotion: Bool) -> [String: Double] {
        var next: [String: Double] = [:]
        for (key, target) in targets {
            guard let current = drawn[key], !reduceMotion, abs(target - current) <= snap else {
                next[key] = target
                continue
            }
            let move = speed * max(0, dt)
            let gap = target - current
            next[key] = abs(gap) <= move ? target : current + (gap > 0 ? move : -move)
        }
        return next
    }
}

/// What the UI adds to the court's picture (`GameModel` keeps and steps it): the rooms' fades, the audience on stage,
/// the leavers, who is talking and where he stands, the speech marks, the smoothed places.
struct CourtScene: Sendable, Equatable {
    var rooms: RoomFades
    var audience: AudienceSession? = nil
    var leavers: [CourtLeaver] = []
    var talking: String? = nil
    var talkX: Double? = nil
    var marks: Set<String> = []
    var drawn: [String: Double] = [:]
    /// Real seconds since the lord sat down on the throne for the audience in progress (the lord pass): the sit-down
    /// frames play over the first `CourtFrames.sitSeconds`. nil: seated and settled (Reduce Motion, tests).
    var lordSeated: Double? = nil

    init(rooms: RoomFades) {
        self.rooms = rooms
    }
}

/// One court figure as it is drawn now.
struct DrawnFigure: Sendable, Equatable {
    var who: String
    var key: String
    var body: SpeakerBody
    var x: Double
    var y: Double
    var facing: Int
    var frame: Int
    /// 0 ... 1: a figure inside a shut room does not show.
    var alpha: Double
    var look: Int?
    var petition: String?
    var talking: Bool
    /// A petitioner waiting seated on a bench: the seated strip drawn instead of the body (`frame` is its frame).
    var seated: SpriteID? = nil

    /// The strip that is drawn.
    var sprite: SpriteID { seated ?? body.sprite }
}

/// The court in the castle (DESIGN.md "The castle": the court lives there and walks small routines; M3 step 3): every
/// court member at his place from `CourtLayout` (walking his round, breathing, talking with his talk frames), today's
/// guests and petitioners waiting on the hall's benches, the petitioner before the throne, the leavers, two guards on
/// the wall walk once posted there, the speech mark over a member with a hint; the benches, the tax lectern, Marek's
/// cart on his days, the statue and the castle's other world changes; the rooms cut away (`CastleRooms`). Figures
/// inside a shut room do not show. Pure: the same state, scene and time give the same additions.
enum CourtFrames {
    static let propIDBase = 2_000_000
    /// A breath every 0.8 s (as `CourtLayout`), on the animation clock, so the court breathes while the clock
    /// stands still under the audience card; talk frames every 0.35 s.
    static let breathSeconds = 0.8
    static let talkSeconds = 0.35
    /// The wall walk's two guards (`castle.guards.wall`).
    static let wallGuards: [Double] = [1324, 1396]
    /// The throne's mark while petitioners wait (M3 fix, U2): above the lord's head when he stands at the throne, in
    /// gold (the speech mark's parchment times this tint).
    static let throneMarkY = 36.0
    /// The lord sits down over this long (the seated strips' frames 0 and 1, half each), then breathes (2 and 3).
    static let sitSeconds = 0.4
    /// A seated petitioner nods (the seated strips' frame 1) for `nodSeconds` every `nodEvery` seconds.
    static let nodEvery = 6.0
    static let nodSeconds = 0.5
    static let throneMarkGold = SIMD3<Float>(1.0, 0.80, 0.34)
    /// The renewed banners over the hall's five (`castle.banners.new`): their left edges, their bottom 28 px up.
    static let bannerXs: [Double] = [1745, 1784, 1821, 1859, 1896]
    static let bannerY = 28.0
    /// The houses' banners (SPRITES.md "The houses' banners"; STORY.md section 5): once the lord had them hung
    /// (`tithe_letters`, the world change `houseBannersHung`), the banner of every house that stands with him (its
    /// flag) hangs over the hall's painted banner at its place and hides it; left to right Brine, Calder, Varn (over
    /// the throne), Lorn, Oxmoor. Their left edges, their bottom 25 px up, behind the throne.
    static let houseBannersHung = "castle.hall.banners.houses"
    static let houseBanners: [(flag: String, sprite: SpriteID, x: Double)] = [
        ("brine_with", .bannerBrine, 1744), ("calder_with", .bannerCalder, 1783), ("varn_with", .bannerVarn, 1821),
        ("lorn_with", .bannerLorn, 1858), ("oxmoor_with", .bannerOxmoor, 1895),
    ]
    static let houseBannerY = 25.0

    /// The places (0 ... 4, left to right) where a house's banner hangs.
    static func houseBannerPlaces(world: [String], flags: [String]) -> [Int] {
        guard world.contains(houseBannersHung) else { return [] }
        return houseBanners.indices.filter { flags.contains(houseBanners[$0].flag) }
    }
    static let tapestryX = 1764.0
    static let tapestryY = 30.0
    /// Seren's grey lantern on the hall's far wall (`castle.seren.lantern`), its glass and its cold light.
    static let serenLanternX = 1930.0
    static let serenLanternY = 34.0
    static let coldLight = SIMD3<Float>(0.78, 0.84, 1.0)
    /// The votive candles before the chapel's altar step (`castle.chapel.candles`).
    static let votiveX = 2064.0
    /// Where the bell hung in the chapel's belfry (`castle.chapel.bell.missing`).
    static let bellGoneX = 1985.0
    static let bellGoneY = 71.0

    /// The key of a figure for the smoothed places: a court member by name, a petitioner by its petition.
    static func key(_ figure: CourtFigure) -> String {
        figure.petition.map { "p:" + $0 } ?? figure.who
    }

    /// The key of the audience's walker: a court member by name (he walks back to his round afterwards), anyone else
    /// by the petition (his place on the benches or where a guest stands).
    static func key(_ session: AudienceSession, catalog: PetitionCatalog) -> String {
        guard let speaker = Speakers.speaker(session.speaker), speaker.role == .court else {
            return "p:" + session.petitionID
        }
        return session.speaker
    }

    /// A fixed phase per figure, so the court never breathes in step.
    static func phase(_ key: String) -> Double {
        var value: UInt64 = 0xCBF2_9CE4_8422_2325
        for scalar in key.unicodeScalars {
            value = (value ^ UInt64(scalar.value)) &* 0x0000_0100_0000_01B3
        }
        return Double(value % 800) / 1000
    }

    /// Where each figure is headed now: its place from `CourtLayout`, the talking member where he stopped.
    static func targets(_ figures: [CourtFigure], scene: CourtScene, catalog: PetitionCatalog) -> [String: Double] {
        var list: [String: Double] = [:]
        for figure in figures {
            let figureKey = key(figure)
            if list[figureKey] != nil { continue }
            if let talking = scene.talking, figure.who == talking, let x = scene.talkX {
                list[figureKey] = x
            } else {
                list[figureKey] = figure.x
            }
        }
        if let session = scene.audience {
            list[key(session, catalog: catalog)] = session.walkerX
        }
        return list
    }

    /// The figures as drawn now (the layout's places smoothed, the audience's walker on stage, the talking member held
    /// and gesturing, the leavers), each with its frame, facing and how much of it shows.
    static func figures(state s: GameState, catalog: PetitionCatalog, scene: CourtScene,
                        animTime: Double) -> [DrawnFigure] {
        let layout = CourtLayout.figures(s, catalog: catalog)
        var stageKey: String?
        // A court member before the throne or at the gate: none of his other places show meanwhile.
        var stageWho: String?
        if let session = scene.audience {
            stageKey = key(session, catalog: catalog)
            if Speakers.speaker(session.speaker)?.role == .court { stageWho = session.speaker }
        }
        var list: [DrawnFigure] = []
        var seen = Set<String>()
        for figure in layout {
            let figureKey = key(figure)
            guard figureKey != stageKey, figure.who != stageWho, !seen.contains(figureKey),
                  let body = Speakers.speaker(figure.who)?.body else { continue }
            seen.insert(figureKey)
            let talking = scene.talking == figure.who
            let target = talking ? (scene.talkX ?? figure.x) : figure.x
            let x = scene.drawn[figureKey] ?? target
            var facing = figure.facing
            var frame: Int
            // Seated only at rest on the bench: whoever walks to his place or is spoken to stands.
            var seated: SpriteID?
            if talking {
                frame = talkFrame(body, animTime: animTime, key: figureKey)
                facing = s.king.x >= x ? 1 : -1
            } else if abs(x - target) > 0.75 {
                frame = walkFrame(body, x: x)
                facing = target > x ? 1 : -1
            } else if figure.pose == .walk {
                frame = figure.frame
            } else if let strip = figure.seated {
                seated = strip
                frame = seatedFrame(animTime: animTime, key: figureKey)
            } else {
                frame = idleFrame(body, animTime: animTime, key: figureKey)
            }
            list.append(DrawnFigure(who: figure.who, key: figureKey, body: body, x: x, y: 0, facing: facing,
                                    frame: frame,
                                    alpha: scene.rooms.visibility(x: x), look: figure.look, petition: figure.petition,
                                    talking: talking, seated: seated))
        }
        if let session = scene.audience, let body = Speakers.speaker(session.speaker)?.body {
            let x = session.walkerX
            let frame: Int
            if session.isWalking {
                frame = walkFrame(body, x: x)
            } else if body.talk != nil {
                frame = talkFrame(body, animTime: animTime, key: session.petitionID)
            } else {
                frame = idleFrame(body, animTime: animTime, key: session.petitionID)
            }
            list.append(DrawnFigure(who: session.speaker, key: stageKey ?? session.speaker, body: body, x: x, y: 0,
                                    facing: session.walkerFacing, frame: frame, alpha: scene.rooms.visibility(x: x),
                                    look: session.petitioner.look, petition: session.petitionID,
                                    talking: !session.isWalking))
        }
        for leaver in scene.leavers {
            let frame = leaver.isWalking ? walkFrame(leaver.body, x: leaver.x)
                : idleFrame(leaver.body, animTime: animTime, key: leaver.who)
            list.append(DrawnFigure(who: leaver.who, key: "leaving:" + leaver.who, body: leaver.body, x: leaver.x,
                                    y: 0, facing: leaver.facing, frame: frame,
                                    alpha: leaver.alpha * scene.rooms.visibility(x: leaver.x), look: leaver.look,
                                    petition: nil, talking: false))
        }
        return list
    }

    static func walkFrame(_ body: SpeakerBody, x: Double) -> Int {
        body.walk.lowerBound + Int(abs(x) / CourtLayout.walkFramePixels) % max(1, body.walk.count)
    }

    static func idleFrame(_ body: SpeakerBody, animTime: Double, key: String) -> Int {
        body.idle.lowerBound + Int(max(0, animTime + phase(key)) / breathSeconds) % max(1, body.idle.count)
    }

    /// A seated petitioner: frame 0, and the nod (frame 1) now and then, never in step with his neighbour.
    static func seatedFrame(animTime: Double, key: String) -> Int {
        let time = max(0, animTime) + phase(key) * nodEvery / 0.8
        return time.truncatingRemainder(dividingBy: nodEvery) < nodSeconds && time >= nodEvery ? 1 : 0
    }

    /// The lord on the throne: he sits down (frames 0 and 1) over `sitSeconds`, then breathes (2 and 3). `seconds`
    /// nil: settled at once.
    static func lordSeatedFrame(seconds: Double?, animTime: Double) -> Int {
        if let seconds, seconds < sitSeconds { return seconds < sitSeconds / 2 ? 0 : 1 }
        return 2 + Int(max(0, animTime) / breathSeconds) % 2
    }

    /// Talk frames (a gesture while speaking); a body without them idles.
    static func talkFrame(_ body: SpeakerBody, animTime: Double, key: String) -> Int {
        guard let talk = body.talk else { return idleFrame(body, animTime: animTime, key: key) }
        return talk.lowerBound + Int(max(0, animTime) / talkSeconds) % max(1, talk.count)
    }

    // MARK: - The frame

    /// Adds the court to the simulation's layer: the rooms' fronts, interiors, flames and lights; the court's props
    /// and world changes; the hearth's glow and light only while the hall is open; the figures as actors, drawn before
    /// the lord (he stays in front; seated on the throne during the audience there), each with its glow strip, and the
    /// speech marks.
    static func apply(_ layer: inout EntityLayer, state s: GameState, catalog: PetitionCatalog, scene: CourtScene,
                      view: EntityFrames.ActorView, ambient: AmbientSample, animTime: Double, reduceMotion: Bool) {
        let rooms = scene.rooms
        let hall = rooms.openness(.greatHall)
        let torch = min(1, max(0, ambient.torchStrength))
        let isDay = DayClock.phase(at: s.hour) == .day

        // The hearth burns inside the hall: its glow and its light show while the hall is open.
        if hall < 1 {
            for index in layer.glows.indices where layer.glows[index].sprite == .hearthFire
                && abs(layer.glows[index].x - (Realm.hearthX + 5)) < 0.5 {
                layer.glows[index].color *= SIMD4<Float>(Float(hall), Float(hall), Float(hall), 1)
            }
            for index in layer.lights.indices where layer.lights[index].source.kind == .hearth
                && abs(layer.lights[index].source.x - (Realm.hearthX + 13)) < 0.5 {
                layer.lights[index].source.intensity *= hall
            }
        }

        // The rooms.
        let additions = CastleRooms.additions(rooms: rooms, animTime: animTime, reduceMotion: reduceMotion, torch: torch,
                                              idBase: propIDBase)
        layer.props += additions.props
        layer.glows += additions.glows
        for light in additions.lights where light.intensity > 0.01 {
            layer.lights.append((source: light, plane: .world))
        }

        // The court's props and the castle's world changes.
        var props: [Prop] = []
        var lights: [LightSource] = []
        var glows: [EntityGlow] = []
        func prop(_ sprite: SpriteID, x: Double, y: Double = 0, z: Int = 1, masks: [GlassMask] = []) {
            props.append(Prop(id: propIDBase + 100 + props.count, sprite: sprite, plane: .world, x: x, y: y, z: z,
                              region: .castle, masks: masks))
        }
        for item in CourtLayout.props(s, catalog: catalog) where rooms.visibility(x: item.x + 1) > 0 {
            switch item.sprite {
            case .marekCart:
                prop(.marekCart, x: item.x, masks: [CastleRooms.glass(37, 20, 1, 2, color: CastleRooms.lanternColor)])
                lights.append(LightSource(kind: .lantern, x: item.x + 37, y: 20, radius: 20, flickerSeed: 0x4D41_524B))
            default:
                prop(item.sprite, x: item.x)
            }
        }
        let world = s.court?.world ?? []
        if hall > 0 {
            // A house's banner takes the place of the realm's renewed one.
            let houses = houseBannerPlaces(world: world, flags: s.flags)
            if world.contains("castle.banners.new") {
                for (place, x) in bannerXs.enumerated() where !houses.contains(place) {
                    prop(.hallBanner, x: x, y: bannerY)
                }
            }
            for place in houses {
                prop(houseBanners[place].sprite, x: houseBanners[place].x, y: houseBannerY, z: -1)
            }
            if world.contains("castle.hall.tapestry") { prop(.tapestry, x: tapestryX, y: tapestryY) }
            if world.contains("castle.seren.lantern") {
                prop(.serenLantern, x: serenLanternX, y: serenLanternY,
                     masks: [CastleRooms.glass(2, 2, 3, 4, color: coldLight)])
                lights.append(LightSource(kind: .lantern, x: serenLanternX + 3, y: serenLanternY + 4, radius: 18,
                                          color: coldLight, intensity: 0.8 * hall, flickerSeed: 0x5345_5245))
            }
        }
        let chapel = rooms.openness(.chapel)
        if chapel > 0 {
            if world.contains("castle.chapel.bell.missing") { prop(.bellGone, x: bellGoneX, y: bellGoneY, z: -1) }
            if world.contains("castle.chapel.candles") {
                prop(.votiveCandles, x: votiveX, z: -1)
                for (index, dx) in [2.0, 6, 10].enumerated() {
                    let flame = CastleRooms.Flame(sprite: .candleFlame, dx: dx, dy: 4, color: GamePalette.fireWhite,
                                                  fadesByDay: false, seed: 0x564F_5449 &+ UInt64(index))
                    if let candle = CastleRooms.glow(flame, x: votiveX, share: chapel, animTime: animTime,
                                                     reduceMotion: reduceMotion, torch: torch) {
                        glows.append(candle)
                    }
                }
                lights.append(LightSource(kind: .candle, x: votiveX + 7, y: 6, radius: 14, intensity: chapel,
                                          flickerSeed: 0x564F_5449))
            }
        }
        layer.props += props
        layer.glows += glows
        for light in lights where light.intensity > 0.01 {
            layer.lights.append((source: light, plane: .world))
        }

        // The figures, before the king.
        var actors: [ActorInstance] = []
        func add(_ sprite: SpriteID, frame: Int, x: Double, y: Double, facing: Int, alpha: Double,
                 shade: Float = 1, emissive: Bool = false) {
            guard alpha > 0.003 else { return }
            let rect = view.rect(sprite, x: x, y: y)
            guard view.isOnScreen(rect) else { return }
            actors.append(ActorInstance(sprite: sprite, frame: frame, rect: rect,
                                        tint: SIMD4<Float>(shade, shade, shade, Float(min(1, alpha))),
                                        flipped: facing < 0, isEmissive: emissive, isLit: true))
        }
        let glass = 0.5 + 0.5 * torch
        for figure in figures(state: s, catalog: catalog, scene: scene, animTime: animTime) {
            add(figure.sprite, frame: figure.frame, x: figure.x, y: figure.y, facing: figure.facing,
                alpha: figure.alpha)
            if figure.seated == nil, let strip = figure.body.glow {
                add(strip, frame: figure.frame, x: figure.x, y: figure.y, facing: figure.facing, alpha: figure.alpha,
                    shade: glass, emissive: true)
            }
            if scene.marks.contains(figure.who) && figure.petition == nil {
                let pulse = reduceMotion ? 1 : Int(max(0, animTime) / 0.6) % 2
                let height = Double(figure.sprite.size.height)
                add(.speakerMark, frame: pulse, x: figure.x + 2, y: height + 2, facing: 1, alpha: figure.alpha,
                    emissive: true)
            }
        }
        // M3 fix (U2): while petitioners wait in the hall a gold mark stands over the throne (the speech mark, tinted
        // gold, pulsing; held on its lit frame with Reduce Motion), so the place of the audience shows from across
        // the hall. Not while the audience runs, and not over a shut hall.
        if scene.audience == nil && hall > 0.003 && !AudienceRules.hall(s, catalog: catalog).isEmpty {
            let rect = view.rect(.speakerMark, x: WorldLayout.throneX, y: throneMarkY)
            if view.isOnScreen(rect) {
                let pulse = reduceMotion ? 1 : Int(max(0, animTime) / 0.6) % 2
                actors.append(ActorInstance(sprite: .speakerMark, frame: pulse, rect: rect,
                                            tint: SIMD4<Float>(throneMarkGold.x, throneMarkGold.y, throneMarkGold.z,
                                                               Float(min(1, hall))),
                                            flipped: false, isEmissive: true, isLit: true))
            }
        }
        // Two guards on the wall walk by day once a petition posted them there.
        if isDay && world.contains("castle.guards.wall") {
            for (index, x) in wallGuards.enumerated() {
                let frame = Int(max(0, animTime + Double(index) * 0.45) / breathSeconds) % 2
                add(.guardsman, frame: frame, x: x, y: WorldLayout.wallWalkY, facing: -1, alpha: 1)
            }
        }
        // The lord pass: during the audience at the throne the lord sits on it (the seated strips have the walking
        // strips' size and lantern anchor, so the actor's place holds and only the strip and the frame change).
        if scene.audience?.place == .throne {
            let lord = s.lordOrDefault
            let frame = lordSeatedFrame(seconds: reduceMotion ? nil : scene.lordSeated, animTime: animTime)
            for index in layer.actors.indices {
                if layer.actors[index].sprite == lord.body {
                    layer.actors[index].sprite = lord.seated
                    layer.actors[index].frame = frame
                } else if layer.actors[index].sprite == lord.glow {
                    layer.actors[index].sprite = lord.seatedGlow
                    layer.actors[index].frame = frame
                }
            }
        }
        if let king = layer.actors.lastIndex(where: { $0.sprite.isLord }) {
            layer.actors.insert(contentsOf: actors, at: king)
        } else {
            layer.actors += actors
        }
    }
}
