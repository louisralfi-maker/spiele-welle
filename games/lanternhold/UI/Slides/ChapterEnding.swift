import Foundation

/// The chapter's end (panels-2, docs/lanes/panels.md): the three endings of chapter 1 as lantern slides (STORY.md "The
/// endings"), the lord's leaning (STORY.md section 4), the houses that stood with the realm, and the realm's tale on the
/// end card. Plain data and pure rules, so the unit tests read them without a screen.

/// The three endings, in STORY.md's order (`-GWSlides ending1|ending2|ending3`). DESIGN.md "Endings by the finale":
/// a hated lord gets the Guttering Lantern whatever night 20 brought; the King slain with the town glad and Seren kept
/// gives the Open Lantern; every other case (held until dawn, a middling town, Seren handed over, a finale saved by a
/// second chance) the Shuttered Lantern.
enum ChapterEnding: String, CaseIterable, Sendable {
    /// Was the Bright Crown: the King falls in the beacon's light, happiness 60 or more, Seren not handed over.
    case openLantern = "ending1"
    /// Was the Iron Crown: every other case.
    case shutteredLantern = "ending2"
    /// Was the Ash Crown: happiness below 30.
    case gutteringLantern = "ending3"

    static let gutterBelow = 30
    static let openFrom = 60

    /// The ending a realm earned at the finale's dawn.
    static func decide(happiness: Int, kingSlain: Bool, flags: [String]) -> ChapterEnding {
        if happiness < gutterBelow { return .gutteringLantern }
        if kingSlain, happiness >= openFrom, !flags.contains(RealmTale.serenHandedOverFlag) { return .openLantern }
        return .shutteredLantern
    }

    /// Each ending's own light on the stage: the first true dawn, a cold grey first light, a drowning ember.
    var lamp: SlideLamp {
        switch self {
        case .openLantern: return .dawn
        case .shutteredLantern: return .grey
        case .gutteringLantern: return .ember
        }
    }

    /// The three pictures (`Resources/Slides`). The middle slide of two endings shows the chosen lord or lady.
    var pictures: [SlidePicture] {
        switch self {
        case .openLantern:
            return [.fixed("slideOpen1"), .byLord(lord: "slideOpen2Lord", lady: "slideOpen2Lady"), .fixed("slideOpen3")]
        case .shutteredLantern:
            return [.fixed("slideShut1"), .fixed("slideShut2"), .fixed("slideShut3")]
        case .gutteringLantern:
            return [.fixed("slideGutter1"), .byLord(lord: "slideGutter2Lord", lady: "slideGutter2Lady"),
                    .fixed("slideGutter3")]
        }
    }

    /// The Shuttered Lantern's middle picture when Seren was not handed over (critic 1 of panels-2, high 3): the
    /// house's banners hanging wet and grey on the shut gate, so the picture follows the words.
    static let shutGatePicture = "slideShut2Gate"

    /// Every picture this ending may show (the Shuttered Lantern's middle slide has two).
    var pictureNames: [String] {
        pictures.flatMap(\.names) + (self == .shutteredLantern ? [ChapterEnding.shutGatePicture] : [])
    }

    /// The ending's name on the end card ("The Open Lantern").
    var nameKey: String { "end.name.\(rawValue)" }
    /// The first slide's words (what happened) and the third's (the first big hint).
    var firstKey: String { "slides.\(rawValue).1" }
    var thirdKey: String { "slides.\(rawValue).3" }

    /// The middle slide's first line: the leaning in one sentence, said as this ending's mood says it.
    func leaningKey(_ leaning: Leaning) -> String { "slides.\(rawValue).lean.\(leaning.rawValue)" }
}

/// How the lord ruled, read from the flags the petitions set (STORY.md section 4, "How choices shape the lord"); no
/// meter and no screen ever shows it. The last stand's speech is the lord's own leaning said aloud: it counts twice
/// and decides a tie.
enum Leaning: String, CaseIterable, Sendable {
    /// Lets people in: the stranger, the refugees, the blessed plough, the coast's promise.
    case openHand
    /// Takes no risk: the stranger and the refugees turned away, the tribute refused or paid without a word.
    case shutGate
    /// Tells the town what is true: the beacon's plans shown, the town called to the vigil, the honest speech.
    case honestLamp

    static let signs: [Leaning: [String]] = [
        .openHand: ["stranger_in", "refugees_in", "refugees_some", "plough_blessed", "coast_promise", "coast_helped",
                    "cough_cured"],
        .shutGate: ["stranger_turned_away", "refugees_turned_away", "tribute_paid", "sick_sent_away", "seren_outside",
                    RealmTale.serenHandedOverFlag],
        .honestLamp: ["beacon_shown", "town_vigil", "blessing_asked"],
    ]
    /// The last stand's three speeches (day 20).
    static let speeches: [String: Leaning] = ["speech_aldric": .openHand, "speech_dawn": .shutGate,
                                              "speech_honest": .honestLamp]
    /// Without a speech a tie goes this way.
    static let order: [Leaning] = [.openHand, .honestLamp, .shutGate]

    static func read(flags: [String]) -> Leaning {
        let set = Set(flags)
        var score: [Leaning: Int] = [:]
        for leaning in Leaning.allCases {
            score[leaning] = (signs[leaning] ?? []).filter { set.contains($0) }.count
        }
        // The herald refused in silence is the shut gate; refused with the whole hall laughing is not "without a word".
        if set.contains("herald_refused"), !set.contains("herald_mocked") { score[.shutGate, default: 0] += 1 }
        let spoken = speeches.first { set.contains($0.key) }?.value
        if let spoken { score[spoken, default: 0] += 2 }
        let best = score.values.max() ?? 0
        let tied = order.filter { score[$0] == best }
        if let spoken, tied.contains(spoken) { return spoken }
        return tied.first ?? .openHand
    }

    /// Its name on the end card ("The Open Hand").
    var nameKey: String { "end.leaning.\(rawValue)" }
}

/// The five houses of the Morninglands (STORY.md section 5). A house stood with the realm when its audience ended in
/// friendship (`<house>_with`); their banners hung in the hall when the lord hung the tithe letters' banners.
enum House: String, CaseIterable, Sendable {
    case varn, brine, oxmoor, calder, lorn

    var flag: String { "\(rawValue)_with" }
    /// Names of houses are never translated (STORY.md).
    var name: String { rawValue.prefix(1).uppercased() + rawValue.dropFirst() }
    /// The house's banner as the hall hangs it (`Resources/Art`, 20 x 41, ART-look2.md 19.3).
    var banner: String { "banner" + name }
}

/// A realm's tale at the chapter's end: which ending, the lord's leaning, who stood by, and the few numbers a player
/// cares about. It builds the ending's three slides and fills the end card.
struct RealmTale: Sendable, Equatable {
    static let serenHandedOverFlag = "seren_handed_over"
    static let bannersHungFlag = "banners_hung"

    var ending: ChapterEnding
    var leaning: Leaning
    /// The houses that stood with the realm, in the map's order.
    var houses: [House]
    /// The houses' banners hung in the hall (`tithe_letters`, day 16).
    var bannersHung: Bool
    var serenHandedOver: Bool
    /// Nights held (the realm's best night; a night saved by a second chance does not count as held).
    var nightsHeld: Int
    /// Petitions heard and judged in this realm.
    var judgments: Int
    /// Soldiers fallen on the walls in this realm.
    var fallen: Int
    var lord: LordIdentity

    /// The tale of a realm at the finale's dawn (`report` is night 20's dawn report).
    static func make(state: GameState, report: DawnReport) -> RealmTale {
        let flags = state.flags
        let set = Set(flags)
        let held = report.held ? report.night : 0
        return RealmTale(ending: ChapterEnding.decide(happiness: report.happinessAfter, kingSlain: report.slewTheKing,
                                                      flags: flags),
                         leaning: Leaning.read(flags: flags),
                         houses: House.allCases.filter { set.contains($0.flag) },
                         bannersHung: set.contains(bannersHungFlag),
                         serenHandedOver: set.contains(serenHandedOverFlag),
                         nightsHeld: max(state.records.bestNight, held),
                         judgments: state.court?.heardCount ?? 0,
                         fallen: state.records.fallenTotal,
                         lord: state.lordOrDefault)
    }

    /// `-GWSlides ending1|ending2|ending3|end`: a sample tale for each ending, so each shows another leaning and
    /// another line of houses (the Open Lantern with Varn's and Brine's banners, the Shuttered Lantern with Seren
    /// handed over, the Guttering Lantern alone).
    static func sample(_ ending: ChapterEnding, lord: LordIdentity) -> RealmTale {
        switch ending {
        case .openLantern:
            return RealmTale(ending: ending, leaning: .openHand, houses: [.varn, .brine], bannersHung: true,
                             serenHandedOver: false, nightsHeld: 20, judgments: 46, fallen: 4, lord: lord)
        case .shutteredLantern:
            return RealmTale(ending: ending, leaning: .shutGate, houses: [.oxmoor, .calder, .lorn], bannersHung: true,
                             serenHandedOver: true, nightsHeld: 20, judgments: 39, fallen: 9, lord: lord)
        case .gutteringLantern:
            return RealmTale(ending: ending, leaning: .honestLamp, houses: [], bannersHung: false,
                             serenHandedOver: false, nightsHeld: 19, judgments: 31, fallen: 17, lord: lord)
        }
    }

    /// The middle slide's second line: Seren's grey lantern in the Shuttered Lantern if she was handed over; else
    /// the houses' banners (by name, all five, a few without a friend, or none but our own).
    var secondLineKey: String {
        if ending == .shutteredLantern && serenHandedOver { return "slides.seren.lantern" }
        if !bannersHung { return "slides.houses.alone" }
        if houses.isEmpty { return "slides.houses.few" }
        if houses.count == House.allCases.count { return "slides.houses.all" }
        return "slides.houses.some"
    }

    /// The middle slide's picture follows its second line: in the Shuttered Lantern Seren's grey lantern on the wall
    /// only when she was handed over, otherwise the house's banners wet and grey on the shut gate.
    var middlePicture: SlidePicture {
        if ending == .shutteredLantern && !serenHandedOver { return .fixed(ChapterEnding.shutGatePicture) }
        return ending.pictures[1]
    }

    /// The houses' names joined as the player's language joins a list ("Varn and Brine", „Varn und Brine“).
    func housesList(language: String? = nil) -> String {
        let formatter = ListFormatter()
        let code = language ?? Bundle.main.preferredLocalizations.first ?? "en"
        formatter.locale = Locale(identifier: code)
        return formatter.string(from: houses.map(\.name)) ?? houses.map(\.name).joined(separator: ", ")
    }

    /// The ending's three slides on its own light; "Skip" leads to the end card as the last tap does.
    func show(language: String? = nil) -> SlideShow {
        let pictures = ending.pictures
        let second = secondLineKey
        let fill = second == "slides.houses.some" ? housesList(language: language) : nil
        return SlideShow(id: ending.rawValue, slides: [
            Slide(picture: pictures[0], textKey: ending.firstKey, timing: .ending),
            Slide(picture: middlePicture, textKey: ending.leaningKey(leaning), timing: .ending, moreKeys: [second],
                  fill: fill),
            Slide(picture: pictures[2], textKey: ending.thirdKey, timing: .ending),
        ], skippable: true, lamp: ending.lamp, lastHintKey: "slides.end")
    }
}

extension SlideTiming {
    /// An ending's slides rise a little slower and hold a moment longer before a tap turns them: these are the words a
    /// player has played twenty nights for.
    static let ending = SlideTiming(hold: 0.8, textDelay: 0.6, settle: 0.8)
}
