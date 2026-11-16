/// What the lord can buy at the drill yard (docs/YARD.md sections 2 and 4), each paid coin by coin at its counter
/// (docs/PAY.md; `PayOffer.yard`, `KingTarget.yard`). Step 1: stage 2 and the pitch kettle.
enum YardOffer: Sendable, Equatable {
    /// A stage of the yard (2: the drill yard).
    case stage(Int)
    /// The pitch kettle (Pechkessel): Bram makes it and brings it at the next dawn.
    case kettle
}

/// A work of the yard (YARD.md section 4): ordered by day, brought over by Bram at the next dawn, in use from then on.
enum YardWorkState: String, Codable, Sendable {
    case ordered, inUse
}

/// The drill yard's own state in a realm (docs/YARD.md; build 3, wave 2, lane 2). `GameState.yard` is nil for the
/// realm without a yard (stage 1, the barracks only, nobody trained: every older save, every reference bot). Saved
/// with the dawn snapshot: every field decodes with a default, so a field added later never makes a save corrupt.
struct YardState: Codable, Sendable, Equatable {
    /// The stage that stands (1 the barracks, 2 the drill yard).
    var stage = 1
    /// A stage ordered today: it stands at the next dawn (nil: none).
    var orderedStage: Int?
    /// The pitch kettle (nil: not ordered).
    var kettle: YardWorkState?
    /// Today's roll, taken at noon (`YardTuning.rollHour`): the soldiers whose day counts at the end of the drill. A
    /// man sworn in after noon is not on it and starts the next day.
    var rollDay = 0
    var roll: [Int] = []
    /// Seconds the lord has stood still at the fence while they drill, and the day he made count double (0 never).
    var fenceWatch = 0.0
    var doubledDay = 0
    /// The trained soldiers' names at the horn, so the dawn names a trained man who fell in the night.
    var nightTrained: [String] = []

    init() {}

    init(stage: Int) {
        self.stage = stage
    }

    init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        stage = max(1, (try? c.decodeIfPresent(Int.self, forKey: .stage)) ?? 1)
        orderedStage = try? c.decodeIfPresent(Int.self, forKey: .orderedStage)
        kettle = try? c.decodeIfPresent(YardWorkState.self, forKey: .kettle)
        rollDay = max(0, (try? c.decodeIfPresent(Int.self, forKey: .rollDay)) ?? 0)
        roll = (try? c.decodeIfPresent([Int].self, forKey: .roll)) ?? []
        fenceWatch = max(0, (try? c.decodeIfPresent(Double.self, forKey: .fenceWatch)) ?? 0)
        doubledDay = max(0, (try? c.decodeIfPresent(Int.self, forKey: .doubledDay)) ?? 0)
        nightTrained = (try? c.decodeIfPresent([String].self, forKey: .nightTrained)) ?? []
    }

    /// The drill yard stands (stage 2 or more): the soldiers drill by day.
    var stands: Bool { stage >= 2 }

    /// The pitch kettle is in use (Bram brought it).
    var kettleInUse: Bool { kettle == .inUse }
}

/// The yard's half of the dawn report (`DawnReport.yard`): who was trained this morning, which trained men fell in the
/// night, what Bram and the builders brought. Pure data; the lines are `YardText`'s (Front.xcstrings).
struct YardDawnReport: Codable, Sendable, Equatable {
    /// Trained this morning: Brannock hands them the company's coat at the muster board ("Trained: Wat, Ilse.").
    var trained: [String] = []
    /// Trained soldiers who fell in the night, by name (they are also among `DawnReport.fallen`).
    var fallenTrained: [String] = []
    /// The stage that stands from this dawn (nil: none new).
    var raised: Int?
    /// The pitch kettle came this dawn.
    var kettle = false

    init(trained: [String] = [], fallenTrained: [String] = [], raised: Int? = nil, kettle: Bool = false) {
        self.trained = trained
        self.fallenTrained = fallenTrained
        self.raised = raised
        self.kettle = kettle
    }

    init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        trained = (try? c.decodeIfPresent([String].self, forKey: .trained)) ?? []
        fallenTrained = (try? c.decodeIfPresent([String].self, forKey: .fallenTrained)) ?? []
        raised = try? c.decodeIfPresent(Int.self, forKey: .raised)
        kettle = (try? c.decodeIfPresent(Bool.self, forKey: .kettle)) ?? false
    }

    /// Nothing to tell.
    var isEmpty: Bool { trained.isEmpty && fallenTrained.isEmpty && raised == nil && !kettle }
}
