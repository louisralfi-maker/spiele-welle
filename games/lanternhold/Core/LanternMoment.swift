import Foundation

/// The interface on the world after docs/HUD.md (stage lane, step stage-3-interface, 15.11.2026): nothing stands on
/// the walked world. A touch on the lord is the lantern moment (the world stands still; above him the gold, the mood
/// and the people in the interface kit's pixel figures, the day under them as the dawn sign and its number, the realm
/// strip at the top, the gear in a corner). While coins reach or leave him, the coin and the figure stand above him and
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

    /// The lantern moment's block: the row (coin and gold, the face, the people and their count), 2 px, and centred
    /// under it the day line (the dawn sign and the day's number). Its top-left is (0, 0).
    static func moment(gold: Int, happiness: Int, people: Int, day: Int) -> Block {
        let top = row([group(sign: .hudCoin, number: gold),
                       group(sign: .hudFace, frame: faceFrame(happiness: happiness)),
                       group(sign: .hudPeople, number: people)])
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
            lastTick = now
            nextTick = now + PurseTicker.tickSeconds
            return true
        }
        if gold != target {
            target = gold
        }
        guard var value = shown else { return false }
        while value != target && now >= nextTick {
            let gap = target - value
            let move = min(abs(gap), PurseTicker.step(gap))
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
/// again once a game hour while the call is open, so it is never a standing thing (rule 1); it goes as soon as the
/// call is answered. Inside the hall the petitioners do not call (he is there). Pure.
struct StripCall: Sendable, Equatable {
    /// The call's size last seen (0: none).
    var size = 0
    /// The game hour it last came up for an open call.
    var shownHour = -10.0
    /// The clock's second it goes.
    var until = 0.0

    static let seconds = 6.0

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

    /// One frame: true while the strip stands by itself.
    mutating func update(_ strip: RealmStrip?, hour: Double, clock: Double, allowed: Bool) -> Bool {
        let now = StripCall.size(strip)
        defer { size = now }
        guard now > 0 else {
            until = 0
            return false
        }
        guard allowed else { return false }
        let gap = (hour - shownHour + 48).truncatingRemainder(dividingBy: 24)
        if now > size || gap >= 1 {
            shownHour = hour
            until = clock + StripCall.seconds
        }
        return clock < until
    }
}

/// The kit's pieces as unlit actors on a stage's pixel grid: a block centred over the lord, its bottom
/// `HUDKit.purseAbove` px above his head.
enum HUDKitActors {
    static func actors(_ block: HUDKit.Block, lordX: Double, groundLift: Double, framing: TouchFraming)
        -> [ActorInstance] {
        let viewLeft = framing.viewLeft.rounded(.up) + 2
        let viewRight = framing.viewRight.rounded(.down) - 2
        var left = HUDKit.centredLeft(lordX: lordX, width: block.width)
        left = Int(min(max(Double(left), viewLeft), viewRight - Double(block.width)))
        let top = groundLift + Double(HUDKit.lordHead + HUDKit.purseAbove + block.height)
        let scale = Float(framing.scale)
        return block.pieces.map { piece in
            let size = piece.sprite.size
            let x = framing.deviceX(stageX: Double(left + piece.x))
            let y = framing.deviceY(lift: top - Double(piece.y))
            return ActorInstance(sprite: piece.sprite, frame: piece.frame,
                                 rect: SIMD4<Float>(Float(x), Float(y), Float(size.width) * scale,
                                                    Float(size.height) * scale),
                                 tint: SIMD4<Float>(1, 1, 1, 1), flipped: false, isEmissive: true, isLit: true)
        }
    }
}
