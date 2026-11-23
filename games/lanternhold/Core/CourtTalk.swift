/// How often the king talked to whom today (UI state, not saved): talking again goes on through a speaker's lines
/// (`CourtLineBook.line(for:state:nth:)`), and the speech mark leaves a speaker once the king heard him today.
struct TalkLog: Sendable, Equatable {
    private(set) var day = 0
    private(set) var counts: [String: Int] = [:]

    /// Lines heard from `who` on `day`.
    func count(_ who: String, day: Int) -> Int {
        day == self.day ? counts[who] ?? 0 : 0
    }

    /// One more line heard from `who` on `day` (a new day starts the count afresh).
    mutating func note(_ who: String, day: Int) {
        if day != self.day {
            self.day = day
            counts = [:]
        }
        counts[who, default: 0] += 1
    }
}

/// Talking to the court (DESIGN.md "Talking": the action button beside a court member shows one speech-bubble line:
/// gossip, a joke, or a hint about today's petitions; M3 step 3). By day only: at night the court keeps the hearth and
/// the king the walls. The court and the guests talk (`Speakers.canTalk`); townsfolk petitioners speak at the
/// throne; the Stranger at the gate asks her own question (`KingTarget.stranger`).
enum CourtTalk {
    /// How close the king stands to talk (closer than the action button's reach, so walking past the court does not
    /// keep offering the speech bubble).
    static let reach = 28.0
    /// Walking this far from the speaker closes his bubble.
    static let leaveDistance = 52.0

    /// The figures the king can talk to now, with their places (nobody at night or after the realm fell).
    static func candidates(_ s: GameState, figures: [CourtFigure], lines: CourtLineBook) -> [(who: String, x: Double)] {
        guard DayClock.phase(at: s.hour) == .day, !s.defeated else { return [] }
        var list: [(who: String, x: Double)] = []
        var seen = Set<String>()
        for figure in figures where Speakers.canTalk(figure.who) && !seen.contains(figure.who) {
            if figure.who == "seren" && figure.petition != nil { continue }
            guard lines.line(for: figure.who, state: s) != nil else { continue }
            seen.insert(figure.who)
            list.append((figure.who, figure.x))
        }
        return list
    }

    /// The speaker nearest the king within `reach`, if any.
    static func nearest(_ s: GameState, figures: [CourtFigure], lines: CourtLineBook) -> (who: String, x: Double)? {
        var best: (who: String, x: Double)?
        var bestDistance = reach
        for candidate in candidates(s, figures: figures, lines: lines) {
            let distance = abs(candidate.x - s.king.x)
            if distance <= bestDistance {
                best = candidate
                bestDistance = distance
            }
        }
        return best
    }

    /// What `who` says today, in the order the king hears it: the book's lines (`CourtLineBook.lines(for:state:)`),
    /// with Mother Hesper's far-goal line placed on the first days (polish E1b, `FarGoal.place`).
    static func todaysLines(_ who: String, state: GameState, lines: CourtLineBook) -> [CourtLine] {
        FarGoal.place(lines.lines(for: who, state: state), who: who, day: state.day)
    }

    /// The line the king hears now from `who` (the next one of today's list; talking again goes round again).
    static func line(_ who: String, state: GameState, lines: CourtLineBook, log: TalkLog) -> CourtLine? {
        let list = todaysLines(who, state: state, lines: lines)
        guard !list.isEmpty else { return nil }
        let nth = log.count(who, day: state.day)
        return list[((nth % list.count) + list.count) % list.count]
    }

    /// True when `who`'s first line today is worth a mark: a hint about one of today's waiting petitions or an answer
    /// to what the king decided (`CourtLineBook.hasHint`).
    static func hasMarkedLine(_ who: String, state: GameState, lines: CourtLineBook) -> Bool {
        guard let first = todaysLines(who, state: state, lines: lines).first else { return false }
        return first.about != nil || first.isAnswer
    }

    /// The speech mark (SPRITES.md `speakerMark`): over a court member or guest who has a hint about one of today's
    /// waiting petitions or an answer, until the king has talked to him today; over Hesper on day 1 until her far goal
    /// was heard (polish E1b, `FarGoal.stillMarked`: her greeting comes first). By day only.
    static func marks(_ s: GameState, figures: [CourtFigure], lines: CourtLineBook, log: TalkLog) -> Set<String> {
        guard DayClock.phase(at: s.hour) == .day, !s.defeated else { return [] }
        var marked = Set<String>()
        for figure in figures where Speakers.canTalk(figure.who) && !marked.contains(figure.who) {
            if figure.who == "seren" && figure.petition != nil { continue }
            if log.count(figure.who, day: s.day) == 0 && hasMarkedLine(figure.who, state: s, lines: lines) {
                marked.insert(figure.who)
            } else if log.count(FarGoal.heardKey, day: s.day) == 0
                        && FarGoal.stillMarked(figure.who, state: s, lines: lines, talked: []) {
                marked.insert(figure.who)
            }
        }
        return marked
    }
}
