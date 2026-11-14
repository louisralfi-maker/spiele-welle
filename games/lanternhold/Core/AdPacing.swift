import Foundation

/// The three rewarded offers (DESIGN.md "Ads (AdMob, no purchases)"). Each names its reward on its button, says plainly
/// that a video plays and shows only while a video is ready; without one the game goes on with no dead button.
enum AdOffer: String, Codable, Sendable, CaseIterable {
    /// The dawn report: this dawn's taxes come in a second time (at most every second dawn).
    case doubleTaxes
    /// The defeat card: the hearth is rekindled, every creature inside the castle burns away and dawn comes at once
    /// (once per five nights, once per ten in endless; DESIGN.md "Losing a night").
    case secondChance
    /// Marek's cart on his days: +40 % of that dawn's taxes, at least 15 gold, until the horn.
    case merchantGift
}

/// The real-time clock the ad rules read, in seconds. The app's is the wall clock, so "6 real minutes after any ad"
/// holds across launches; the tests count by hand.
protocol AdClock: Sendable {
    var now: TimeInterval { get }
}

/// The app's clock for the ad rules: seconds since 1970.
struct WallClock: AdClock {
    var now: TimeInterval { Date().timeIntervalSince1970 }
}

/// Where the game stands when an interstitial is asked for.
enum AdPlace: Sendable, Equatable {
    /// The dawn report, on "Continue" after it has been read: the one place an interstitial may come.
    case dawnReport
    /// The last "Continue" of a chapter's end (the story panels' flow, after the ending's scene): once per chapter.
    case chapterEnd(chapter: Int)
    /// At the throne, in an audience.
    case throne
    /// Inside a story scene (prologue, beat, ending panels).
    case storyScene
    /// Anywhere else: walking, a card, the pause sheet.
    case world
}

/// One request for an interstitial: where, on which day, and what the game knows about that moment.
struct InterstitialMoment: Sendable, Equatable {
    /// The day that began with this dawn (the report's day).
    var day: Int
    var place: AdPlace
    /// The clock stands between the horn and the dawn report.
    var atNight: Bool
    /// A story scene belongs to this dawn (`AdPacing.isStoryDawn`, or the story panels' own word at the join).
    var storyDawn: Bool

    init(day: Int, place: AdPlace = .dawnReport, atNight: Bool = false, storyDawn: Bool = false) {
        self.day = day
        self.place = place
        self.atNight = atNight
        self.storyDawn = storyDawn
    }
}

/// Why an interstitial does not come.
enum InterstitialHold: String, Sendable, Equatable, CaseIterable {
    /// Not at the dawn report (or a chapter's end).
    case notAtReport
    case atNight
    case atThrone
    case inStoryScene
    /// This chapter's ending already had its interstitial.
    case chapterEndShown
    case beforeDayFour
    case storyDawn
    /// A rewarded video was watched on this dawn (never right after one).
    case afterRewarded
    /// Fewer than three in-game days since the last interstitial.
    case tooFewDays
    /// Fewer than six real minutes since any ad.
    case tooFewMinutes
}

/// The rules' answer for an interstitial.
enum InterstitialVerdict: Sendable, Equatable {
    case allowed
    case held(InterstitialHold)
}

/// Marek's gift on one of his days: what a video gives the treasury.
struct MerchantGift: Sendable, Equatable {
    var day: Int
    var gold: Int
}

/// The ads' rules and their memory (DESIGN.md "Ads (AdMob, no purchases)", "Losing a night"), kept with the save
/// (`SaveGame.adPacing`). Pure: no SDK, no UIKit, no clock of its own; the real time comes in as `now` from an
/// injected `AdClock`. The app's `AdDirector` asks it which offer is open and whether an interstitial may come, and
/// tells it what was shown.
///
/// - **Double taxes** at the dawn report: at most every second dawn (taken, or passed by with Continue), and only on a
///   dawn that brought taxes.
/// - **Second chance** on the defeat card: once per five nights, once per ten in endless.
/// - **Merchant's gift** on Marek's days (every third dawn): +40 % of that dawn's taxes, at least 15 gold, once, by
///   day until the horn.
/// - **Interstitial** only on the dawn report's Continue: at most every third in-game day, at least 6 real minutes
///   after any ad, never before day 4, never on a story dawn, never right after a rewarded video, never at night, at
///   the throne or in a story scene; after a chapter's ending at most once.
///
/// Every field decodes with a default (the M2b review's rule for saved types): an older save, the frozen version 1
/// fixture included, never reads as corrupt. The JSON stays flat (numbers and a list of numbers), so `SaveGameTests`'
/// pattern for an empty block still finds it. The realm's restart starts it afresh (`GameModel.restartChapter`).
struct AdPacing: Codable, Sendable, Equatable {
    /// Double taxes at most every second dawn.
    static let doubleTaxesEvery = 2
    /// A second chance once per five nights in the chapter, once per ten in endless.
    static let secondChanceGap = 5
    static let secondChanceGapEndless = 10
    /// Marek's days: every third day (as his cart in the courtyard, `CourtLayout.marekEvery`).
    static let merchantEvery = 3
    /// The gift: 40 % of that dawn's taxes, at least 15 gold.
    static let merchantShare = 0.4
    static let merchantMinimum = 15
    /// The cart stands from the dawn report to the horn.
    static let merchantArrives = 6.0
    static let merchantLeaves = 19.0
    /// The interstitial: at most every third in-game day, never before day 4, at least 6 real minutes after any ad.
    static let interstitialDayGap = 3
    static let firstInterstitialDay = 4
    static let secondsBetweenAds: TimeInterval = 6 * 60
    /// The dawns of chapter 1 that carry a story beat (DESIGN.md "Story": the table's days from 4 on, and day 21,
    /// whose dawn ends the chapter). Days 1 to 3 need no entry (no interstitial before day 4). The story panels can
    /// name their own beats at the join (`InterstitialMoment.storyDawn`).
    static let storyDays: Set<Int> = [4, 6, 8, 10, 11, 13, 15, 17, 19, 20, 21]

    /// The day of the last interstitial (0: none yet).
    var lastInterstitialDay = 0
    /// The last dawn whose double taxes were taken or passed by (0: none yet).
    var lastDoubleTaxesDay = 0
    /// The night of the last second chance (0: none yet).
    var lastSecondChanceNight = 0
    /// The day Marek's gift was last taken (0: never).
    var merchantTakenDay = 0
    /// The day of the dawn a rewarded video was last watched on (0: never): no interstitial on that dawn's Continue.
    var lastRewardedDay = 0
    /// When the last ad of any kind was shown, by the injected clock (nil: none yet).
    var lastAdAt: TimeInterval?
    /// The chapters whose ending has had its interstitial.
    var chapterEndings: [Int] = []

    init(lastInterstitialDay: Int = 0, lastDoubleTaxesDay: Int = 0, lastSecondChanceNight: Int = 0,
         merchantTakenDay: Int = 0, lastRewardedDay: Int = 0, lastAdAt: TimeInterval? = nil,
         chapterEndings: [Int] = []) {
        self.lastInterstitialDay = lastInterstitialDay
        self.lastDoubleTaxesDay = lastDoubleTaxesDay
        self.lastSecondChanceNight = lastSecondChanceNight
        self.merchantTakenDay = merchantTakenDay
        self.lastRewardedDay = lastRewardedDay
        self.lastAdAt = lastAdAt
        self.chapterEndings = chapterEndings
    }

    init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        lastInterstitialDay = try c.decodeIfPresent(Int.self, forKey: .lastInterstitialDay) ?? 0
        lastDoubleTaxesDay = try c.decodeIfPresent(Int.self, forKey: .lastDoubleTaxesDay) ?? 0
        lastSecondChanceNight = try c.decodeIfPresent(Int.self, forKey: .lastSecondChanceNight) ?? 0
        merchantTakenDay = try c.decodeIfPresent(Int.self, forKey: .merchantTakenDay) ?? 0
        lastRewardedDay = try c.decodeIfPresent(Int.self, forKey: .lastRewardedDay) ?? 0
        lastAdAt = try c.decodeIfPresent(TimeInterval.self, forKey: .lastAdAt)
        chapterEndings = try c.decodeIfPresent([Int].self, forKey: .chapterEndings) ?? []
    }

    // MARK: - Which offer is open

    /// Double taxes at this dawn: open on a dawn that brought taxes, at most every second dawn.
    func doubleTaxesOpen(day: Int, taxes: Int) -> Bool {
        taxes > 0 && day - lastDoubleTaxesDay >= AdPacing.doubleTaxesEvery
    }

    /// The night from which the second chance can be taken again; nil when it can be taken now.
    func secondChanceFrom(night: Int, mode: GameMode) -> Int? {
        guard lastSecondChanceNight > 0 else { return nil }
        let gap = mode == .endless ? AdPacing.secondChanceGapEndless : AdPacing.secondChanceGap
        return night - lastSecondChanceNight >= gap ? nil : lastSecondChanceNight + gap
    }

    /// Marek's days: every third day.
    static func isMerchantDay(_ day: Int) -> Bool {
        day > 0 && day % merchantEvery == 0
    }

    /// The gift for a dawn that brought `taxes`: 40 % of them, at least 15 gold.
    static func merchantGold(taxes: Int) -> Int {
        max(merchantMinimum, Int((Double(max(0, taxes)) * merchantShare).rounded()))
    }

    /// Marek's gift while his cart stands (his day, by day until the horn, not yet taken); nil otherwise.
    /// `dawnTaxes`: what this day's dawn brought (the report's taxes).
    func merchantGift(day: Int, hour: Double, dawnTaxes: Int) -> MerchantGift? {
        guard AdPacing.isMerchantDay(day), merchantTakenDay != day,
              hour >= AdPacing.merchantArrives - 1e-6, hour < AdPacing.merchantLeaves else { return nil }
        return MerchantGift(day: day, gold: AdPacing.merchantGold(taxes: dawnTaxes))
    }

    /// The realm's gift right now, from its state: today's dawn report gives the taxes.
    func merchantGift(_ state: GameState) -> MerchantGift? {
        let taxes = state.lastReport.map { $0.day == state.day ? $0.goldIn : 0 } ?? 0
        return merchantGift(day: state.day, hour: state.hour, dawnTaxes: taxes)
    }

    /// The dawns of chapter 1 with a story beat; endless has none.
    static func isStoryDawn(day: Int, mode: GameMode) -> Bool {
        mode == .chapter && storyDays.contains(day)
    }

    // MARK: - The interstitial

    /// Whether an interstitial may come at `moment`, by the injected clock's `now`.
    func interstitial(_ moment: InterstitialMoment, now: TimeInterval) -> InterstitialVerdict {
        switch moment.place {
        case .throne: return .held(.atThrone)
        case .storyScene: return .held(.inStoryScene)
        case .world: return .held(.notAtReport)
        case .dawnReport, .chapterEnd: break
        }
        if moment.atNight { return .held(.atNight) }
        if case .chapterEnd(let chapter) = moment.place, chapterEndings.contains(chapter) {
            return .held(.chapterEndShown)
        }
        if moment.day < AdPacing.firstInterstitialDay { return .held(.beforeDayFour) }
        // A chapter's end comes after its story scene; a dawn report never comes with one.
        if moment.place == .dawnReport && moment.storyDawn { return .held(.storyDawn) }
        if lastRewardedDay > 0 && lastRewardedDay == moment.day { return .held(.afterRewarded) }
        if lastInterstitialDay > 0 && moment.day - lastInterstitialDay < AdPacing.interstitialDayGap {
            return .held(.tooFewDays)
        }
        if let last = lastAdAt {
            let elapsed = now - last
            // A clock set back (elapsed below zero) tells nothing: it must not hold the ads back for good.
            if elapsed >= 0 && elapsed < AdPacing.secondsBetweenAds { return .held(.tooFewMinutes) }
        }
        return .allowed
    }

    // MARK: - What was shown

    /// A rewarded video was watched to its end and its reward given. `day`: the day of the dawn it belongs to (for the
    /// second chance, the dawn it brought); `night`: the night a second chance saved.
    mutating func rewardedWatched(_ offer: AdOffer, day: Int, night: Int = 0, at now: TimeInterval) {
        lastAdAt = now
        lastRewardedDay = day
        switch offer {
        case .doubleTaxes: lastDoubleTaxesDay = day
        case .merchantGift: merchantTakenDay = day
        case .secondChance: lastSecondChanceNight = max(lastSecondChanceNight, night)
        }
    }

    /// The report closed with its double taxes offered and not taken: the next offer waits two dawns.
    mutating func doubleTaxesPassed(day: Int) {
        lastDoubleTaxesDay = max(lastDoubleTaxesDay, day)
    }

    /// An interstitial showed at `moment`.
    mutating func interstitialShown(_ moment: InterstitialMoment, at now: TimeInterval) {
        lastAdAt = now
        lastInterstitialDay = moment.day
        if case .chapterEnd(let chapter) = moment.place, !chapterEndings.contains(chapter) {
            chapterEndings.append(chapter)
            chapterEndings.sort()
        }
    }
}
