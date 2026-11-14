import Foundation

/// The great hall as a stage of its own (stage lane, 14.11.2026; DESIGN.md "The hall stage and touch the world",
/// SPRITES.md "The great hall as a stage", docs/REVIEW-look-2.md 2.6): its geometry, its places and its lights, in hall
/// px. x runs from the hall's left edge (0 ... 600), rows from its top (0 ... 201); a thing "stands on row r" when its
/// lowest row is r − 1, and its lift is how far that is above the nave's walk line (row 175), which lies 26 rows above
/// the hall's bottom like the world's ground line. The world's old cut-away places (`CastleRooms`, `CourtLayout`'s hall
/// slot) are left unused on the stage.
enum HallLayout {
    static let width = 600.0
    static let height = 201
    /// The nave's walk line (the long carpet), the wall line (benches, guards, the waiting), Pip's row, the dais.
    static let floorRow = 175
    static let wallRow = 169
    static let pipRow = 171
    static let daisRow = 166
    /// Three treads of 4 px, 3 px high each, then the dais from x 376.
    static let stepsX = 364.0
    static let daisX = 376.0

    // MARK: - The doors

    /// The hall's door in the world (the forebuilding the world lane paints, REVIEW-look-2.md 2.1).
    static let worldDoorX = 1830.0
    /// Where the lord stands inside when he comes in, the door behind him.
    static let doorX = 68.0
    /// Walking left past this, he goes out.
    static let exitX = 40.0
    /// The door's opening: its top row (the horn's slip hangs above it).
    static let doorTop = 110
    /// The audience's letter ends left of this (Odile's left edge, with the lectern under the letter's foot): it never
    /// covers the throne, the petitioner or the hearth (docs/REVIEW-look-2.md H4).
    static let letterEdgeX = 386.0
    /// Where the lord may walk: from the door's side to the dais's far end.
    static let walkRange: ClosedRange<Double> = 30...584

    // MARK: - The court's places

    static let throneX = 416.0
    static let lecternX = 385.0
    /// Where the petitioner stands before the throne (and the one after him rises from his bench).
    static let spotX = 338.0
    /// Where the lord stands on a new realm's first morning: before his throne, ready to sit.
    static let firstMorningX = 404.0
    /// The two benches' middles, under the tall windows; three seats each, the first in line nearest the throne.
    static let benches: [Double] = [184, 300]
    static let seats: [Double] = [308, 300, 292, 192, 184, 176]
    /// Where guests and petitioners beyond the six seats stand, on the wall line between the window bays and by the
    /// door bay.
    static let standing: [Double] = [228, 256, 140, 118, 268, 106]
    /// The four candle stands, one each side of a bench (their candles burn while someone waits on it).
    static let stands: [Double] = [160, 208, 276, 324]
    /// The door's guards (facing it) and the guard under the arms by day.
    static let doorGuards: [(x: Double, facing: Int)] = [(37, 1), (100, -1)]
    static let armsGuard = (x: 448.0, facing: -1)
    /// The Stranger once she was let in: the hall's far corner beyond the hearth.
    static let serenCorner = 580.0
    /// Her grey lantern on the far wall (`castle.seren.lantern`), its bottom row.
    static let serenLantern = (x: 583.0, row: 128)
    /// Where heard petitioners walk while the lord still sits (out of the audience framing), and the door the horn
    /// sends everyone through.
    static let leaveX = 200.0
    /// The banner places (left edges, top row): a house's banner covers the hall's painted one whole.
    static let bannerXs: [Double] = [137, 211, 253, 327, 368]
    static let bannerTop = 62
    /// The tapestry of Aldric (`castle.hall.tapestry`): on the gallery's wall left of the door bay window.
    static let tapestry = (x: 88.0, row: 98)

    /// The court's own small rounds in the hall (the same walk as the castle's, `CourtLayout.place`): Odile at her
    /// place between the throne and the nave, looking down the hall and now and then back to the throne (she keeps 12
    /// px from her lectern, so the action button tells them apart), Mother Hesper at the hearth, Pip at the foot of the
    /// steps.
    static let routines: [String: CourtRoutine] = [
        "odile": CourtRoutine(stops: [397, 397], faces: [-1, 1], dwell: [16, 6], night: 397, nightFacing: -1,
                              speed: 10),
        "hesper": CourtRoutine(stops: [497, 485], faces: [1, -1], dwell: [12, 7], night: 497, nightFacing: 1,
                               speed: 10, offset: 3),
        "pip": CourtRoutine(stops: [350, 343], faces: [1, -1], dwell: [9, 5], night: 352, nightFacing: -1,
                            speed: 12, offset: 11),
    ]

    /// The row a court member stands on: the dais for the court on it, Pip a step before it.
    static func row(of who: String, x: Double) -> Int {
        who == "pip" ? pipRow : row(at: x)
    }

    /// The row of the floor at `x`: the nave's walk line, the three treads, the dais.
    static func row(at x: Double) -> Int {
        floorRow - Int(lift(at: x))
    }

    /// How far the floor at `x` stands above the walk line: 0 in the nave, 3, 6 and 9 on the treads, 9 on the dais.
    static func lift(at x: Double) -> Double {
        guard x >= stepsX else { return 0 }
        let tread = min(3, Int((x - stepsX) / 4) + 1)
        return Double(3 * tread)
    }

    // MARK: - The lights (python3 tools/hallart.py anchors greatHall)

    /// The great fire: bottom row 145, centred on x 532; its light at (532, 128) with a radius of 60 + 60 × the
    /// hearth's strength; below a third of it the small fire burns instead.
    static let hearthX = 532.0
    static let fireBottomRow = 145
    static let hearthLight = (x: 532.0, row: 128)
    static let hearthRadius = (base: 60.0, perStrength: 60.0)
    static let smallFireBelow = 1.0 / 3.0
    /// The long warm pool the hearth lays on the flags before it.
    static let floorPool = (x: 520.0, row: 184, radius: 120.0, squash: 3.2)
    static let chandeliers: [Double] = [184, 300]
    static let chandelierRow = 39
    static let chandelierCandles: [(x: Double, row: Int)] = [(-16, 39), (-10, 35), (-4, 42), (4, 34), (10, 41),
                                                              (16, 37)]
    static let standRow = 141
    static let standCandles: [(dx: Double, row: Int)] = [(-3, 141), (0, 139), (3, 141)]
    static let torches: [(x: Double, row: Int)] = [(38, 116), (98, 116)]
    static let mantelCandles: [(x: Double, row: Int)] = [(499, 93), (505, 94), (559, 94), (565, 93)]
    static let armsCandles: [(x: Double, row: Int)] = [(452, 123), (460, 123)]
    static let armsLight = (x: 456.0, row: 123)
    static let newelCandles: [(x: Double, row: Int)] = [(15, 70), (121, 70)]

    // MARK: - The windows and the day's light

    /// The two tall windows' left edges (30 px wide, glass rows 58 ... 130): the day's shafts fall from them.
    static let windowLefts: [Double] = [169, 285]
    /// The shaft's top row (the lancets' spring), its slant (px across per row down) as painted (tools/hallstage.py).
    static let shaftTop = 72
    static let shaftSlant = 0.44
    /// The near arcade's pillars (`hallPillarNear`, parallax 1.25): their hall x.
    static let nearPillars: [Double] = [161, 254]
    static let nearParallax = 1.25

    /// The plaster patches (`hallWash`'s eight frames): each frame's top-left on the hall (tools/hallstage.py).
    static let washPatches: [(x: Double, row: Int)] = [(80, 92), (140, 36), (124, 104), (256, 40), (316, 100),
                                                        (440, 100), (476, 96), (536, 128)]

    /// The Weltmauer behind the windows (on a plane at parallax 0.3): its top row on the hall (its peaks stand in
    /// the tall windows' lower half, the sky above them), and where its left edge stands (plane x) when the camera's
    /// left edge is at 0.
    static let weltmauerTop = 86
    static let weltmauerLeft = -150.0
    static let weltmauerParallax = 0.3
}
