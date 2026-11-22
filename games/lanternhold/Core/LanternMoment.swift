import Foundation

/// The interface on the world after docs/HUD.md (stage lane, step stage-3-interface, 15.11.2026): nothing stands on
/// the walked world. A touch on the lord is the lantern moment (the world stands still; above him the gold in the
/// interface kit's pixel figures, the day under it as the dawn sign and its number, the realm strip at the top with the
/// town's banner at its town end (build 3: the mood and the people, `MoodBanner`), the gear in a corner). While coins
/// reach or leave him, the coin and the figure stand above him and
/// tick (`PurseTicker`); a change of the mood or the people shows its sign with a small arrow for 2 s (`ChangeNotes`).
/// Everything here is pure: the pieces' places in game pixels, the ticks and their timing. `GameModel+Lantern.swift`
/// draws them.
enum HUDKit {
    /// Game pixels from one figure to the next (their 1-px ink edges overlap; ci-out/director/hud-kit.md).
    static let advance = 6
    /// Game pixels between a sign's right edge and its number.
    static let signGap = 1
    /// Game pixels between two groups of the row (coin and gold, face, people and count).
    static let space = 5
    /// The row's height (figures, coin, face, people).
    static let rowHeight = 9
    /// Game pixels between the row and the day line under it.
    static let lineGap = 2
    /// The lantern moment: the day line's bottom stands this far above the top of the lord's head.
    static let momentAbove = 8
    /// The gold alone (a walking lord): its bottom stands this far above his head.
    static let purseAbove = 6
    /// The lord's head: the top of his 30-row strip above the walk line.
    static let lordHead = 30

    /// One piece of the kit: its sprite and frame, its top-left corner in game px from the block's top-left.
    struct Piece: Sendable, Equatable {
        var sprite: SpriteID
        var frame: Int
        var x: Int
        var y: Int
    }

    /// A block of pieces and its size in game px.
    struct Block: Sendable, Equatable {
        var pieces: [Piece] = []
        var width = 0
        var height = 0
        /// Build 3, lane 5 step 5 (the vignette): the lantern moment's row is drawn over the finished picture, after
        /// the grade and the lantern's dim (`ActorDim.over`), in the kit's own colours; false for the walking row.
        var over = false

        /// The pieces moved by (dx, dy).
        func shifted(_ dx: Int, _ dy: Int) -> [Piece] {
            pieces.map { Piece(sprite: $0.sprite, frame: $0.frame, x: $0.x + dx, y: $0.y + dy) }
        }
    }

    /// The figure frames of a number: its digits, a leading minus (frame 11) when negative; `plus` puts a plus
    /// (frame 10) before a positive number.
    static func figureFrames(_ value: Int, plus: Bool = false) -> [Int] {
        var frames = String(abs(value)).compactMap { Int(String($0)) }
        if value < 0 { frames.insert(11, at: 0) }
        if value > 0 && plus { frames.insert(10, at: 0) }
        return frames
    }

    /// The width of `count` figures side by side.
    static func figuresWidth(_ count: Int) -> Int {
        count <= 0 ? 0 : advance * (count - 1) + SpriteID.hudFigures.size.width
    }

    /// A sign and, after it, a number (or an arrow), on one 9-px row; a 10 or 11 px sign stands 1 px over the row.
    static func group(sign: SpriteID, frame: Int = 0, number: Int? = nil, arrowUp: Bool? = nil) -> Block {
        var block = Block()
        let signSize = sign.size
        let rise = max(0, signSize.height - rowHeight)
        block.pieces.append(Piece(sprite: sign, frame: frame, x: 0, y: -rise))
        var x = signSize.width + signGap
        if let number {
            let frames = figureFrames(number)
            for (index, figure) in frames.enumerated() {
                block.pieces.append(Piece(sprite: .hudFigures, frame: figure, x: x + advance * index, y: 0))
            }
            x += figuresWidth(frames.count)
        } else if let up = arrowUp {
            block.pieces.append(Piece(sprite: .hudArrow, frame: up ? 0 : 1, x: x, y: 0))
            x += SpriteID.hudArrow.size.width
        } else {
            x = signSize.width
        }
        block.width = x
        block.height = rowHeight
        return block
    }

    /// Groups side by side, `space` px apart, on one row.
    static func row(_ groups: [Block]) -> Block {
        var block = Block()
        var x = 0
        for (index, group) in groups.enumerated() {
            if index > 0 { x += space }
            block.pieces += group.shifted(x, 0)
            x += group.width
        }
        block.width = x
        block.height = rowHeight
        return block
    }

    /// The face's frame for a happiness (the ledger's five bands on the kit's four moods): glad from 60 (joyful and
    /// content), even from 30, grim from 15, unrest below.
    static func faceFrame(happiness: Int) -> Int {
        if happiness >= 60 { return 0 }
        if happiness >= 30 { return 1 }
        if happiness >= 15 { return 2 }
        return 3
    }

    /// The lantern moment's block: the row, 2 px, and centred under it the day line (the dawn sign and the day's
    /// number). Its top-left is (0, 0). Build 3, lane 5 step 4 (decision 6): the row is the purse alone (the coin and
    /// the gold); the town's mood and the people's count stand at the realm strip's town end (`MoodBanner`).
    static func moment(gold: Int, day: Int) -> Block {
        let top = row([group(sign: .hudCoin, number: gold)])
        let line = group(sign: .hudDawn, number: day)
        let width = max(top.width, line.width)
        var block = Block()
        let rowX = (width - top.width) / 2
        block.pieces += top.shifted(rowX, 0)
        let lineX = (width - line.width) / 2
        block.pieces += line.shifted(lineX, rowHeight + lineGap)
        block.width = width
        block.height = rowHeight + lineGap + rowHeight
        return block
    }

    /// The left edge (game px, whole) of a block of `width` centred over the lord at `lordX`.
    static func centredLeft(lordX: Double, width: Int) -> Int {
        Int((lordX - Double(width) / 2).rounded(.down))
    }
}

/// The gold at the lord (HUD.md section 3): while coins reach him or leave him, the coin and the figure stand above
/// him and tick toward the treasury, one coin at a time (more per tick for a big sum, so a change never ticks longer
/// than about a second), and go 2 s after the last coin. Changes made while a card covers the world tick once the
/// world shows again. Pure: `GameModel+Lantern.swift` steps it with the clock's seconds.
struct PurseTicker: Sendable, Equatable {
    /// The figure on show, nil while the purse is away.
    var shown: Int?
    /// The treasury it ticks toward (the last treasury seen).
    var target: Int
    /// The clock's second of the last tick (or of the moment it came).
    var lastTick = 0.0
    /// The clock's second of the next tick.
    var nextTick = 0.0
    /// Coins per tick for the change on show (set when it starts or its target moves, so a sum ticks evenly).
    var stride = 1

    /// It stays this long after the last coin.
    static let linger = 2.0
    /// Seconds between two ticks: quick, so a sum of 30 ticks in about a second.
    static let tickSeconds = 0.035
    /// At most this many ticks for one change (a big sum moves several coins a tick).
    static let maxTicks = 30

    init(gold: Int) {
        target = gold
    }

    /// The coins a tick moves for the gap `gap`.
    static func step(_ gap: Int) -> Int {
        max(1, (abs(gap) + maxTicks - 1) / maxTicks)
    }

    /// One frame: `gold` is the treasury now, `now` the clock's seconds, `visible` whether the world shows (no card,
    /// no change of stage). Returns true when what shows changed.
    @discardableResult
    mutating func update(gold: Int, now: Double, visible: Bool) -> Bool {
        let before = shown
        // Under a card the purse rests where it is; the change ticks on the next visible frame.
        guard visible else { return false }
        if shown == nil {
            guard gold != target else { return false }
            shown = target
            target = gold
            stride = PurseTicker.step(gold - (shown ?? gold))
            lastTick = now
            nextTick = now + PurseTicker.tickSeconds
            return true
        }
        guard var value = shown else { return false }
        if gold != target {
            target = gold
            stride = PurseTicker.step(gold - value)
        }
        while value != target && now >= nextTick {
            let gap = target - value
            let move = min(abs(gap), stride)
            value += gap > 0 ? move : -move
            lastTick = now
            nextTick += PurseTicker.tickSeconds
            if nextTick < now - 0.2 { nextTick = now }
        }
        shown = value
        if value == target && now - lastTick >= PurseTicker.linger {
            shown = nil
        }
        return shown != before
    }

    /// A jump (a new realm, a replayed day): the purse goes and takes the treasury as it is.
    mutating func reset(gold: Int) {
        shown = nil
        target = gold
    }
}

/// The change notes (HUD.md section 3): when the mood or the people change, their sign with a small arrow up or down
/// stands above the lord for 2 s. Changes under a card show once the world shows again.
struct ChangeNotes: Sendable, Equatable {
    /// The last happiness and people seen while the world showed.
    var happiness: Int
    var people: Int
    /// The arrows on show (true: up) and when they go.
    var mood: Bool?
    var moodUntil = 0.0
    var crowd: Bool?
    var crowdUntil = 0.0

    static let seconds = 2.0

    init(happiness: Int, people: Int) {
        self.happiness = happiness
        self.people = people
    }

    /// One frame; returns true when what shows changed.
    @discardableResult
    mutating func update(happiness now: Int, people count: Int, clock: Double, visible: Bool) -> Bool {
        let before = (mood, crowd)
        if visible {
            if now != happiness {
                mood = now > happiness
                moodUntil = clock + ChangeNotes.seconds
                happiness = now
            }
            if count != people {
                crowd = count > people
                crowdUntil = clock + ChangeNotes.seconds
                people = count
            }
            if mood != nil && clock >= moodUntil { mood = nil }
            if crowd != nil && clock >= crowdUntil { crowd = nil }
        }
        return before.0 != mood || before.1 != crowd
    }

    mutating func reset(happiness: Int, people: Int) {
        self = ChangeNotes(happiness: happiness, people: people)
    }
}

/// What stands above the walking lord: the gold while it ticks and the change notes, side by side on one row whose
/// bottom is `HUDKit.purseAbove` px over his head. Empty when nothing changes.
enum LordNotes {
    static func block(purse: Int?, happiness: Int, mood: Bool?, crowd: Bool?) -> HUDKit.Block {
        var groups: [HUDKit.Block] = []
        if let purse { groups.append(HUDKit.group(sign: .hudCoin, number: purse)) }
        if let mood {
            groups.append(HUDKit.group(sign: .hudFace, frame: HUDKit.faceFrame(happiness: happiness), arrowUp: mood))
        }
        if let crowd { groups.append(HUDKit.group(sign: .hudPeople, arrowUp: crowd)) }
        guard !groups.isEmpty else { return HUDKit.Block() }
        return HUDKit.row(groups)
    }
}

/// When the realm strip comes by itself (HUD.md section 3): a call (petitioners wait in the hall, the Stranger at the
/// gate, a wall below half at night) brings it up with its tag. It stands for `seconds` when a call begins or grows and
/// again every `again` seconds while the call is open (round lh-s3-3: once a game hour kept it up half the time), so
/// it is never a standing thing (rule 1); it goes as soon as the call is answered. Inside the hall the petitioners do
/// not call (he is there). Pure; the seconds are the clock's real ones.
struct StripCall: Sendable, Equatable {
    /// The call's size last seen (0: none).
    var size = 0
    /// The clock's second it last came up for the open call.
    var shownAt = -1_000.0
    /// The clock's second it goes.
    var until = 0.0
    /// Fix lane D (player-loop-1): the day whose owing doors last raised the strip (0: none yet).
    var doorsShown = 0
    /// The clock's second the doors' own raise goes (kept apart from the calls', so an answered call still goes at
    /// once).
    var doorsUntil = 0.0

    static let seconds = 6.0
    static let again = 45.0
    /// The days on whose morning the owing doors raise the strip once by themselves; later their tag shows only in
    /// the lantern moment's strip.
    static let doorsDays = 2...3

    /// The day whose owing doors call now (2 or 3 while a door owes; 0 otherwise).
    static func doorsDay(_ strip: RealmStrip?) -> Int {
        guard let strip, strip.owingDoors > 0, doorsDays.contains(strip.day) else { return 0 }
        return strip.day
    }

    /// What calls now: waiting petitioners (not while he is in the hall), the Stranger, and at night a wall below half.
    static func size(_ strip: RealmStrip?) -> Int {
        guard let strip else { return 0 }
        var calls = strip.inHall ? 0 : strip.petitioners
        if strip.strangerAtGate { calls += 1 }
        if strip.isNight {
            calls += strip.lines.filter { $0.mark == .damaged || $0.mark == .rubble }.count
        }
        return calls
    }

    /// One frame: true while the strip stands by itself. `held` (fix round 2, the critic's high 5: a hint slip stands
    /// at the top centre) keeps the call waiting, not seen: its 6 s start once the slip has gone, so a hint slip and
    /// the call's strip never stand at the top centre together.
    /// Fix lane D (player-loop-1): on the mornings of days 2 and 3 the owing doors raise it once, as a new call does,
    /// as soon as it may stand (the dawn report closed, no hint slip); it goes when the last door has paid.
    mutating func update(_ strip: RealmStrip?, hour: Double, clock: Double, allowed: Bool, held: Bool = false) -> Bool {
        let now = StripCall.size(strip)
        let doors = StripCall.doorsDay(strip)
        if now == 0 {
            // Answered: the call's strip goes at once, even while the doors still owe.
            size = 0
            until = 0
        }
        guard now > 0 || doors > 0 else {
            doorsUntil = 0
            return false
        }
        if held {
            until = 0
            doorsUntil = 0
            return false
        }
        defer { size = now }
        guard allowed else { return false }
        if now > 0 && (now > size || clock - shownAt >= StripCall.again) {
            shownAt = clock
            until = clock + StripCall.seconds
        }
        if doors > 0 && doors != doorsShown {
            doorsShown = doors
            doorsUntil = clock + StripCall.seconds
        }
        return clock < max(until, doors > 0 ? doorsUntil : 0)
    }
}

/// The kit's pieces as unlit actors on a stage's pixel grid: a block centred over the lord, its bottom
/// `HUDKit.purseAbove` px above his head.
///
/// Lane 5 step 2a (the smooth walk, suspect 1): the left edge is not floored to a whole game px. The lord is a smooth
/// actor (`Camera.deviceX`, device px), so a floored row buzzed 3 to 5 device px against him on every frame of a walk;
/// unfloored, `framing.deviceX` puts the row on the lord's own grid and it keeps a fixed device distance to him. The
/// still lantern moment keeps `HUDKit.centredLeft`.
enum HUDKitActors {
    static func actors(_ block: HUDKit.Block, lordX: Double, groundLift: Double, framing: TouchFraming)
        -> [ActorInstance] {
        let viewLeft = framing.viewLeft.rounded(.up) + 2
        let viewRight = framing.viewRight.rounded(.down) - 2
        let left = min(max(lordX - Double(block.width) / 2, viewLeft), viewRight - Double(block.width))
        let top = groundLift + Double(HUDKit.lordHead + HUDKit.purseAbove + block.height)
        return placed(block, left: left, top: top, framing: framing)
    }

    /// Build 3, lane 5 step 4 (the step 2b critic's H1): the lantern moment's block (the purse and the day line) in the
    /// same frame as the world, so it can never trail the world during the look-around's pan. `left` is its left edge
    /// on the stage (game px, whole: placed when the moment opened, `LanternMomentShow.blockX`), never clamped to the
    /// view, so in a pan it rides with the world over the lord; its day line's bottom `HUDKit.momentAbove` px above
    /// his head.
    static func moment(_ block: HUDKit.Block, left: Double, groundLift: Double, framing: TouchFraming,
                       alpha: Float = 1) -> [ActorInstance] {
        let top = groundLift + Double(HUDKit.lordHead + HUDKit.momentAbove + block.height)
        return placed(block, left: left, top: top, framing: framing, alpha: alpha)
    }

    /// The block's pieces as unlit actors with `left`, `top` its top-left on the stage (game px, `top` over the walk
    /// line). Build 3, lane 5 step 5: the lantern moment's row (`HUDKit.Block.over`) is drawn over the finished
    /// picture with no make-up tint (the step-4 tint of 1/0.82 under the flat dim is gone with the dim), so its bone
    /// lands on 222,210,184 like the banner's count; `alpha` is its share while the look-around's clean frame fades it
    /// (`LanternVeil.signs`).
    static func placed(_ block: HUDKit.Block, left: Double, top: Double, framing: TouchFraming,
                       alpha: Float = 1) -> [ActorInstance] {
        let scale = Float(framing.scale)
        let rule: ActorDim = block.over ? .over : .world
        return block.pieces.map { piece in
            let size = piece.sprite.size
            let x = framing.deviceX(stageX: left + Double(piece.x))
            let y = framing.deviceY(lift: top - Double(piece.y))
            var actor = ActorInstance(sprite: piece.sprite, frame: piece.frame,
                                      rect: SIMD4<Float>(Float(x), Float(y), Float(size.width) * scale,
                                                         Float(size.height) * scale),
                                      tint: SIMD4<Float>(1, 1, 1, alpha), flipped: false, isEmissive: true,
                                      isLit: true)
            actor.dimRule = rule
            return actor
        }
    }
}

/// Build 3, lane 5 step 4 (decision 6, form C; the director's notes of 16.11. and 21.11.2026, Louis: "neben der Map
/// oben eine Anzeige, wie die Buerger drauf sind"): the town's mood stands at the realm strip's town end as the
/// town's banner, so caring for the people is never out of sight while the strip shows (the lantern moment, a call).
/// It hangs on two cords under the strip's town end: a short pole, the cloth in the mood's colour with a swallowtail,
/// the hood face sewn on it in the kit's four moods (step 5: the hem's marks are gone; the arrow is the only sign of
/// the trend). Beside it the people, their count and the mood's trend since the last dawn, each piece in its own 1 px
/// ink edge as the atlas draws it (step 5b, the director's ruling M1: step 5's shared edge is gone). A touch on it
/// gives one slip with the main reason, read from what the dawn report knows of the day's happiness changes and the
/// knocks at the doors. No rule or number of the happiness changes here: the bands are the face's
/// (`HUDKit.faceFrame`). The picture is `Resources/Art/moodBanner.png` (tools/hudart.py), drawn by SwiftUI under the
/// strip (`MoodBannerView`), never by the renderer. Pure.
enum MoodBanner {
    /// One frame of the banner's picture: pole, cords, cloth and face (game px).
    static let size = PixelSize(width: 21, height: 25)
    /// Its frames: one per mood, in the face's order (step 5: the hem's marks and their twelve frames are gone).
    static let frameCount = 4
    /// The cloth's depth under the pole and the whole picture's with the cords and the pole (game px).
    static let clothDepth = 21
    static let depth = 25
    /// The banner's left edge under the strip, in the strip's columns (its pole spans 128 to 148 of 150, under the
    /// strip's town end; the people and their count stand beyond the strip's end).
    static let column = 128
    /// The people group's top-left beside the banner (game px from the banner's top-left): one px after the pole's
    /// knob, its 9 px row level with the face.
    static let peopleX = 22
    static let peopleY = 8
    /// The cloth's left edge and width in the picture (with its ink edge): the slip hangs under its middle.
    static let clothLeft = 2
    static let clothWidth = 17

    /// The mood: 0 glad, 1 even, 2 grim, 3 unrest (the face's bands).
    static func mood(happiness: Int) -> Int {
        HUDKit.faceFrame(happiness: happiness)
    }

    /// The banner's frame in its picture: its mood.
    static func frame(happiness: Int) -> Int {
        mood(happiness: happiness)
    }

    /// The mood's trend: +1 rising, -1 falling, 0 even, against the happiness before the last dawn (0 without one).
    static func trend(happiness: Int, report: DawnReport?) -> Int {
        guard let report else { return 0 }
        let delta = happiness - report.happinessBefore
        return delta > 0 ? 1 : (delta < 0 ? -1 : 0)
    }

    /// The pieces beside the banner: the people, their count and, on a trend, its arrow 1 px after the count.
    static func people(_ count: Int, trend: Int) -> HUDKit.Block {
        var block = HUDKit.group(sign: .hudPeople, number: count)
        if trend != 0 {
            block.pieces.append(HUDKit.Piece(sprite: .hudArrow, frame: trend > 0 ? 0 : 1, x: block.width + 1, y: 0))
            block.width += 1 + SpriteID.hudArrow.size.width
        }
        return block
    }

    /// What the slip names as the mood's main reason.
    enum Reason: Sendable, Equatable {
        /// A line of the dawn report's happiness column.
        case dawn(HappinessReason)
        /// The knocks at the town's doors, today and yesterday (each cost happiness at once).
        case knocked
        /// Nothing has moved them (no change to name): the slip names the mood itself (step 5).
        case quiet
    }

    /// The main reason: of the day's changes (the dawn's lines, and `knocked`, the happiness the knocks cost), the one
    /// that carries the mood: the largest gain while the town is glad, the largest loss while it is grim or in unrest,
    /// the largest either way while it is even (and when the mood's own side has none). The first wins a tie.
    static func reason(happiness: Int, changes: [HappinessChange], knocked: Int) -> Reason {
        var items: [(reason: Reason, delta: Int)] = changes.filter { $0.delta != 0 }.map {
            (reason: Reason.dawn($0.reason), delta: $0.delta)
        }
        if knocked < 0 { items.append((reason: Reason.knocked, delta: knocked)) }
        func largest(_ list: [(reason: Reason, delta: Int)]) -> Reason? {
            var best: (reason: Reason, delta: Int)?
            for item in list where best == nil || abs(item.delta) > abs(best?.delta ?? 0) {
                best = item
            }
            return best?.reason
        }
        let side: [(reason: Reason, delta: Int)]
        switch mood(happiness: happiness) {
        case 0: side = items.filter { $0.delta > 0 }
        case 2, 3: side = items.filter { $0.delta < 0 }
        default: side = items
        }
        return largest(side) ?? largest(items) ?? .quiet
    }

    /// The main reason in a realm: the last dawn's lines, the knocks of yesterday (as that dawn told them) and today.
    static func reason(_ s: GameState, balance: Balance) -> Reason {
        let report = s.lastReport
        var knocked = report?.town?.happinessCost ?? 0
        if let today = s.town?.today { knocked += Town.knockCost(today, balance: balance) }
        return reason(happiness: s.happiness, changes: report?.happinessChanges ?? [], knocked: knocked)
    }
}

// MARK: - Build 3, lane 5 step 5: the lantern's own light

/// How the lantern moment's dim treats an actor (build 3, lane 5 step 5; `ActorInstance.dimRule`): `world` is dimmed
/// with the picture it stands in; `kept` is drawn as before but never dimmed (the touch marks, the sparks of the
/// lord's lantern); `over` is drawn over the finished picture, after the grade and the dim, in its own colours (the
/// moment's row, whose bone lands on 222,210,184 like the banner's count; the hint's glint and the raise's flare).
enum ActorDim: Sendable, Equatable {
    case world, kept, over
}

/// The lord's raised glass and the dim's strength in one frame (`FrameDesc.lanternDim`, `LanternLight`).
struct LanternDim: Sendable, Equatable {
    /// The glass's middle on the stage (world px) and its height over the walk line (world px).
    var x: Double
    var lift: Double
    /// 0 ... 1: the share of the rings' dim (`LanternVeil.dim`).
    var strength: Double
}

/// The lantern's own light (build 3, lane 5 step 5; the director's ruling of 22.11.2026): while the lantern is up the
/// picture darkens by the distance from the lord's raised glass, in stepped rings on the world's grid, anchored in the
/// world: a world pixel (its column on the stage, its row over the walk line) keeps one dim in every frame of a pan,
/// and a game pixel of the world never holds two. No dim within 48 game px of the glass, then 0.08 up to 80, 0.16 up to
/// 120, 0.24 up to 170 and 0.30 beyond; between two rings a band 4 px wide in a 2 x 2 ordered dither of the two. The
/// dark leans to the night ink 42,34,48, never to black. `lh_lantern_dim` in Shaders.metal is the same sum. Pure.
enum LanternLight {
    /// The rings' radii (game px from the glass) and the dim inside the first ring, between them and beyond the last.
    static let rings: [Double] = [48, 80, 120, 170]
    static let levels: [Double] = [0, 0.08, 0.16, 0.24, 0.30]
    /// The dithered band between two rings, centred on the ring (game px).
    static let band = 4.0
    /// The circle's height over its width (1: a circle; 0.8 would squash it).
    static let squash = 1.0
    /// The night ink the dark leans to (42,34,48).
    static let ink = SIMD3<Float>(42.0 / 255, 34.0 / 255, 48.0 / 255)
    /// The 2 x 2 ordered dither's thresholds, by (row & 1) * 2 + (column & 1) of the world pixel.
    static let order: [Double] = [0.125, 0.625, 0.875, 0.375]

    /// Game px from the glass to the middle of the world pixel at column `x`, row `lift` (vertical in `squash`).
    static func distance(x: Int, lift: Int, glassX: Double, glassLift: Double) -> Double {
        let dx = Double(x) + 0.5 - glassX
        let dy = (Double(lift) + 0.5 - glassLift) / squash
        return (dx * dx + dy * dy).squareRoot()
    }

    /// The rings' dim at `distance` game px without the dither (strength 1).
    static func level(distance: Double) -> Double {
        var value = levels[0]
        for (index, ring) in rings.enumerated() where distance >= ring {
            value = levels[index + 1]
        }
        return value
    }

    /// The dim of the world pixel at column `x` and row `lift` (its bottom `lift` px over the walk line) under the
    /// glass: 0 ... 0.30 times its strength.
    static func dim(x: Int, lift: Int, glass: LanternDim) -> Double {
        let strength = min(1, max(0, glass.strength))
        guard strength > 0 else { return 0 }
        let r = distance(x: x, lift: lift, glassX: glass.x, glassLift: glass.lift)
        let half = band / 2
        for (index, ring) in rings.enumerated() {
            if r < ring - half { return levels[index] * strength }
            if r < ring + half {
                let share = (r - (ring - half)) / band
                let outer = share > order[(lift & 1) * 2 + (x & 1)]
                return levels[outer ? index + 1 : index] * strength
            }
        }
        return levels[levels.count - 1] * strength
    }

    /// A colour (0 ... 1) under `dim`: mixed toward the night ink.
    static func dimmed(_ color: SIMD3<Float>, by dim: Double) -> SIMD3<Float> {
        color + (ink - color) * Float(dim)
    }
}

/// The lantern moment's two motions, one value each (build 3, lane 5 step 5), stepped by the frame's seconds:
/// - `light`, the lantern's own light: it comes in over 0.15 s as the lantern goes up and leaves in 0.1 s as it comes
///   down, in even steps (no ease);
/// - `clean`, the clean frame of the look-around: while a finger holds a pan of more than 6 game px from home, the
///   moment's own signs (the lord's row, the town's banner, the gear; never the people of the world) fade out in
///   0.15 s and the dim lifts to 40 % of its strength; when the finger lets go and the glide home starts (0.35 s)
///   they come back in 0.15 s, whole before he is home. The lantern going down clears it at once.
/// Under Reduce Motion both are there and gone at once; with VoiceOver running nothing fades. `dim` is the strength of
/// `LanternLight`'s rings, `signs` the share the moment's signs show at. Picture only, never saved.
struct LanternVeil: Sendable, Equatable {
    /// 0 ... 1: the lantern's own light.
    private(set) var light = 0.0
    /// 0 ... 1: the clean frame (0: the moment's signs whole, 1: gone).
    private(set) var clean = 0.0

    static let upSeconds = 0.15
    static let downSeconds = 0.1
    /// The clean frame's fade, out and back.
    static let cleanSeconds = 0.15
    /// A held pan fades the signs past this many game px from home.
    static let cleanFrom = 6.0
    /// The dim's share while the frame is clean.
    static let heldDim = 0.4

    /// The strength of the rings' dim now.
    var dim: Double { light * (1 - (1 - LanternVeil.heldDim) * clean) }
    /// The share the moment's own signs show at (1 whole, 0 gone).
    var signs: Double { 1 - clean }

    /// One step of `seconds`: `raised` while the lantern is up, `held` while a finger holds the look-around's view,
    /// `pan` how far it stands slid (game px).
    mutating func step(_ seconds: Double, raised: Bool, held: Bool = false, pan: Double = 0, reduceMotion: Bool,
                       voiceOver: Bool = false) {
        let dt = max(0, seconds)
        let target = raised ? 1.0 : 0.0
        if reduceMotion {
            light = target
        } else if light < target {
            light = LanternVeil.toward(light, target, by: dt / LanternVeil.upSeconds)
        } else if light > target {
            light = LanternVeil.toward(light, target, by: dt / LanternVeil.downSeconds)
        }
        let wanted = raised && held && abs(pan) > LanternVeil.cleanFrom && !voiceOver ? 1.0 : 0.0
        if !raised || voiceOver || reduceMotion {
            clean = wanted
        } else if clean != wanted {
            clean = LanternVeil.toward(clean, wanted, by: dt / LanternVeil.cleanSeconds)
        }
    }

    /// `value` moved by `amount` toward `target`, landing on it within a hair (so 0.15 s of sixtieths reach it).
    static func toward(_ value: Double, _ target: Double, by amount: Double) -> Double {
        let next = value < target ? min(target, value + amount) : max(target, value - amount)
        return abs(next - target) < 1e-9 ? target : next
    }
}

/// The hint's glint and the raise's flare as light (build 3, lane 5 step 5; the step-4 critic's M3, the director's
/// ruling): whole game px round the lord's glass (`dx` right of its column, `dy` up from its row), opaque, in their own
/// colours, drawn over the finished picture (`ActorDim.over`), stepping instead of fading so they read at phone size.
/// Their soft halo is the world's glow at the glass (`GameModel.lanternHalo`). Nothing under Reduce Motion. Pure.
enum LanternSparkle {
    struct Spot: Sendable, Equatable {
        var dx: Int
        var dy: Int
        var color: SIMD3<Float>
    }

    /// The glint: its centre 255,250,235, its arms 240,220,170.
    static let glintCentre = SIMD3<Float>(255.0 / 255, 250.0 / 255, 235.0 / 255)
    static let glintArm = SIMD3<Float>(240.0 / 255, 220.0 / 255, 170.0 / 255)
    /// The flare: a white centre, a ring and rays of fire gold 255,200,96.
    static let flareCentre = SIMD3<Float>(1, 1, 1)
    static let flareGold = SIMD3<Float>(255.0 / 255, 200.0 / 255, 96.0 / 255)

    /// The pulse (0 ... 1) from which the glint's centre shows, and from which each arm is 1, 2, 3 px long.
    static let glintFrom = 0.12
    static let armFrom: [Double] = [0.3, 0.55, 0.8]

    /// The glint at `pulse`: a cross of 7 px at its peak (the centre and four arms of 3 px), growing and shrinking a
    /// pixel at a time with the pulse.
    static func glint(pulse: Double) -> [Spot] {
        guard pulse > glintFrom else { return [] }
        var spots = [Spot(dx: 0, dy: 0, color: glintCentre)]
        for (index, from) in armFrom.enumerated() where pulse > from {
            let k = index + 1
            spots += [Spot(dx: -k, dy: 0, color: glintArm), Spot(dx: k, dy: 0, color: glintArm),
                      Spot(dx: 0, dy: -k, color: glintArm), Spot(dx: 0, dy: k, color: glintArm)]
        }
        return spots
    }

    /// The flare at `strength` (1 at the raise, 0 after `LanternFlare.seconds`): the white centre, the ring of fire
    /// gold round it (its eight neighbours) while it is strong, and four diagonal rays of 4 px from the ring, a pixel
    /// shorter at each quarter of its strength.
    static func flare(strength: Double) -> [Spot] {
        guard strength > 0.02 else { return [] }
        var spots = [Spot(dx: 0, dy: 0, color: flareCentre)]
        if strength > 0.25 {
            for dy in -1...1 {
                for dx in -1...1 where dx != 0 || dy != 0 {
                    spots.append(Spot(dx: dx, dy: dy, color: flareGold))
                }
            }
        }
        let rays = min(4, Int((strength * 4).rounded(.up)))
        for k in 0..<rays {
            let d = 2 + k
            for (sx, sy) in [(-1, -1), (1, -1), (-1, 1), (1, 1)] {
                spots.append(Spot(dx: sx * d, dy: sy * d, color: flareGold))
            }
        }
        return spots
    }
}
