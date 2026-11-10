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

    /// The line the king hears now from `who` (the next one of today's list).
    static func line(_ who: String, state: GameState, lines: CourtLineBook, log: TalkLog) -> CourtLine? {
        lines.line(for: who, state: state, nth: log.count(who, day: state.day))
    }

    /// The speech mark (SPRITES.md `speakerMark`): over a court member or guest who has a hint about one of today's
    /// waiting petitions, until the king has talked to him today. By day only.
    static func marks(_ s: GameState, figures: [CourtFigure], lines: CourtLineBook, log: TalkLog) -> Set<String> {
        guard DayClock.phase(at: s.hour) == .day, !s.defeated else { return [] }
        var marked = Set<String>()
        for figure in figures where Speakers.canTalk(figure.who) && !marked.contains(figure.who) {
            if figure.who == "seren" && figure.petition != nil { continue }
            if log.count(figure.who, day: s.day) == 0 && lines.hasHint(for: figure.who, state: s) {
                marked.insert(figure.who)
            }
        }
        return marked
    }
}
