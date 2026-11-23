import Foundation

/// Polish E1b (the audit's R10; Louis' answer 4 of 22.11.: "both"): the run's far goal is said twice in the first
/// days, so days 1 to 10 are not a loop without a shape. The horn's ribbon reads "Night {n} of {N}" (`hornLine`; the
/// ribbon is a pane, HUD.md), and Mother Hesper says it once in her own voice on the first days (`line`, `place`).
/// Pure: nothing is saved; whether her line was heard is the talk log's, which lives for one day only.
enum FarGoal {
    // MARK: - The ribbon

    /// N: the night the run asks for, the Lightless King's night, read from the rule that ends the chapter
    /// (`ReportCard.finaleNight`, which `endChapterIfFinale` checks).
    static var lastNight: Int { ReportCard.finaleNight }

    /// The ribbon's N for night `night`: N while the night lies inside the run (1 ... N); nil past it (the Long Watch
    /// goes on from night 21), where the ribbon keeps its old wording.
    static func hornTotal(night: Int) -> Int? {
        night >= 1 && night <= lastNight ? lastNight : nil
    }

    /// The ribbon's second line (`HornBanner`, its `LANE-E: E1b` block): "Night 3 of 20" inside the run, "Night 21 is
    /// coming" past it (the wording before E1b). Localizable.xcstrings, English only for now.
    static func hornLine(night: Int) -> String {
        if let total = hornTotal(night: night) { return String(localized: "Night \(night) of \(total)") }
        return String(localized: "Night \(night) is coming")
    }

    /// Polish E2 (law 3.6, the dawn card is the one place the plan is said in words): the card's head says the night
    /// that ended as the ribbon said it the evening before, "Night 2 of 20" inside the run; past it the card's old
    /// words, "Night 21 is over" (the ribbon's fallback is "is coming", which a night that ended cannot say).
    static func reportLine(night: Int) -> String {
        if let total = hornTotal(night: night) { return String(localized: "Night \(night) of \(total)") }
        return String(localized: "Night \(night) is over")
    }

    // MARK: - Mother Hesper's line

    /// Who says it.
    static let speaker = "hesper"
    /// Its id among her lines (not in lines.json: there the six other languages would become required keys, and this
    /// build is English only; the same reason as Brannock's offer, `NightOffer.lineKey`).
    static let lineID = "hesper_far_goal"
    /// Story.xcstrings, English only for now.
    static let lineKey = "line.hesper_far_goal"
    /// The first days, when the player learns what the run is for.
    static let days = 1...3
    /// The days her line carries its own mark (the speech mark of an unheard line, `CourtTalk.marks`). The talk log is
    /// UI state of one day and nothing is saved, so on day 2 nobody knows whether it was heard on day 1: there the
    /// line still comes, unmarked, after whatever she has newer to say.
    static let markedDays = 1...1

    /// Her line as the court's talk takes it.
    static let line = CourtLine(id: lineID, speaker: speaker, days: [days.lowerBound, days.upperBound], requires: nil,
                                forbids: nil, weight: nil, text: lineKey, about: nil, answer: nil)

    /// Her day-1 greeting ("Welcome, heir of the house", lines.json): on a marked day she welcomes the heir before she
    /// tells him the far goal (E1b gate F1).
    static let greetingID = "hesper_first"

    /// `list`: what `who` may say today (`CourtLineBook.lines(for:state:)`), with her far-goal line placed on its days.
    /// On a marked day it comes right after the hints about today's petitioners (they are preferred, as ever) and her
    /// greeting (moved up to them when she has it today), before everything else; on the other days it comes last,
    /// once she has nothing newer to say. A speaker who says nothing today (absent, `ErrandEngine.isAbsent`) stays
    /// silent.
    static func place(_ list: [CourtLine], who: String, day: Int) -> [CourtLine] {
        guard who == speaker, days.contains(day), !list.isEmpty, !list.contains(where: { $0.id == lineID }) else {
            return list
        }
        var placed = list
        if markedDays.contains(day) {
            var at = placed.prefix { $0.about != nil }.count
            if let greeting = placed.firstIndex(where: { $0.id == greetingID }), greeting >= at {
                let moved = placed.remove(at: greeting)
                placed.insert(moved, at: at)
                at += 1
            }
            placed.insert(line, at: at)
        } else {
            placed.append(line)
        }
        return placed
    }

    /// The talk log's note that the far goal was heard today (UI state of one day, never saved; the pattern of
    /// `NightOffer.heardKey`). Her greeting comes before it on day 1, so the mark rests on this note, not on whether
    /// she was talked to (E1b gate F1).
    static let heardKey = "hesper.far_goal"

    /// True while `who` is Hesper on a marked day, her far goal is among her lines of today and `talked` (the talk
    /// log's keys of today) does not hold `heardKey`: she keeps the mark of an unheard line until it is heard.
    static func stillMarked(_ who: String, state: GameState, lines: CourtLineBook, talked: Set<String>) -> Bool {
        guard who == speaker, markedDays.contains(state.day), !talked.contains(heardKey) else { return false }
        return CourtTalk.todaysLines(who, state: state, lines: lines).contains { $0.id == lineID }
    }
}
