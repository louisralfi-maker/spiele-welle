import Foundation

/// The court's ties (the director's note of 14.11.2026 15:03; docs/HOUSE.md section 2: "they have ties among each
/// other ... who stands with whom, who leaves when the other comes, a line overheard, an object that changes hands"):
/// one more idle per court member, two frames, played toward another person. Frame 0 a nod (the chin dipped a pixel,
/// the shoulders still), frame 1 the thread itself (docs/SPRITES-people.md "The court's ties", tools/courtties.py):
/// Odile holds out the ledger, Brannock the key of the wall stair, Pip a juggling ball, Tamsin a bowl of supper, Bram the
/// clasp he mended, Marek the first orange of winter, Seren a coin of her house's debt; Mother Hesper holds her nod
/// with her hand on her heart. Separate sheets of the members' own size, so their 8-frame sheets stay as the hall's
/// rebuild has them.
///
/// The hall plays them at the join (the stage lane's rebuilt court; docs/lanes/people.md "people-2 fix round 1"): a
/// member draws `sheet(for:)` instead of its own sheet while it faces another person it is tied to, frame 0 for
/// `nodSeconds`, then frame 1 for `holdSeconds`, then back to its idle; mirrored to face them; with Reduce Motion frame 1
/// alone. Picture only.
enum CourtTies {
    /// Each court member and its tie sheet.
    static let sheets: [SpriteID: SpriteID] = [
        .odile: .odileTie, .brannock: .brannockTie, .pip: .pipTie, .hesper: .hesperTie, .tamsin: .tamsinTie,
        .bram: .bramTie, .marek: .marekTie, .seren: .serenTie,
    ]

    /// The glow strips of the two sheets whose member carries a light (Hesper's staff, Seren's grey lantern).
    static let glows: [SpriteID: SpriteID] = [.hesperTie: .hesperTieGlow, .serenTie: .serenTieGlow]

    /// Every tie sprite, the glow strips included, in `SpriteID` order.
    static let all: [SpriteID] = (Array(sheets.values) + Array(glows.values)).sorted { $0.rawValue < $1.rawValue }

    /// The frames of every tie sheet: the nod and the thread.
    static let frameCount = 2
    static let nodFrame = 0
    static let threadFrame = 1
    static let nodSeconds = 0.6
    static let holdSeconds = 1.6

    /// The member sprite a tie sprite is drawn like (its size; the glow strips their member's glow strip), nil for every
    /// other sprite.
    static func member(of sprite: SpriteID) -> SpriteID? {
        members[sprite]
    }

    private static let members: [SpriteID: SpriteID] = {
        var map: [SpriteID: SpriteID] = [:]
        for (member, tie) in sheets { map[tie] = member }
        map[.hesperTieGlow] = .hesperGlow
        map[.serenTieGlow] = .serenGlow
        return map
    }()

    /// A tie sprite's frame size: its member's.
    static func size(of sprite: SpriteID) -> PixelSize {
        member(of: sprite)?.size ?? PixelSize(width: 14, height: 30)
    }

    /// The tie sheet of a court member (nil: no tie sheet).
    static func sheet(for member: SpriteID) -> SpriteID? {
        sheets[member]
    }

    /// The frame of the tie `t` seconds after it began toward the other person, or nil once it is over (back to the
    /// member's own idle). With Reduce Motion the nod is skipped and the thread held.
    static func frame(since t: Double, reduceMotion: Bool) -> Int? {
        guard t >= 0 else { return nil }
        if reduceMotion { return t < nodSeconds + holdSeconds ? threadFrame : nil }
        if t < nodSeconds { return nodFrame }
        return t < nodSeconds + holdSeconds ? threadFrame : nil
    }
}
