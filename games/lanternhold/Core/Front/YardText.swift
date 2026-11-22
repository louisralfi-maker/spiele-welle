import Foundation

/// One line of the dawn report's yard half, or the words of a thing at the yard: a key of Front.xcstrings and, for the
/// lines with names, the names.
struct YardLine: Sendable, Equatable {
    /// "Trained: Wat, Ilse." (YARD.md section 3, the moment).
    static let trained = "yard.report.trained"
    /// A trained man who fell in the night, named as one (YARD.md section 3, loss).
    static let fallen = "yard.report.fallen"
    /// The drill yard stands from this dawn.
    static let raised = "yard.report.raised"
    /// Bram brought the pitch kettle.
    static let kettle = "yard.report.kettle"
    /// The things at the yard (VoiceOver and the slip: what a touch there buys).
    static let offerStage = "yard.offer.stage"
    static let offerKettle = "yard.offer.kettle"
    /// Step 4 (the director's ruling E5): a long list of names cut short, "Wat, Ilse, Odo and 15 more".
    static let namesMore = "yard.names.more"

    /// Every key of the report's yard lines.
    static let reportKeys = [trained, fallen, raised, kettle]
    /// Every key of this file.
    static let allKeys = reportKeys + [offerStage, offerKettle, namesMore]

    var key: String
    var names: [String] = []
}

extension YardDawnReport {
    /// The report's yard lines, in order: what came at this dawn, who was trained, the trained men who fell.
    func lines() -> [YardLine] {
        var lines: [YardLine] = []
        if raised != nil { lines.append(YardLine(key: YardLine.raised)) }
        if kettle { lines.append(YardLine(key: YardLine.kettle)) }
        if !trained.isEmpty { lines.append(YardLine(key: YardLine.trained, names: trained)) }
        if !fallenTrained.isEmpty { lines.append(YardLine(key: YardLine.fallen, names: fallenTrained)) }
        return lines
    }
}

/// The drill yard's words (Resources/Front.xcstrings; English only in build 3's waves, the other languages at the store
/// pass). Kept out of the simulation files, so the tuning runs compile the rule without the bundle.
enum YardText {
    /// The text of `key` in the player's language (the key itself when it is missing, so a gap shows).
    static func string(_ key: String, bundle: Bundle = .main) -> String {
        FrontText.string(key, bundle: bundle)
    }

    /// Step 4 (E5): up to this many names are listed in full; from one more on the line reads the first `namesShown`
    /// and how many more (the dawn card of a whole company named 18 men on four lines).
    static let namesInFull = 4
    static let namesShown = 3

    /// One line in the player's language, the names filled in (one `%@`, the names joined, `names(_:)`).
    static func text(_ line: YardLine, bundle: Bundle = .main) -> String {
        let format = string(line.key, bundle: bundle)
        guard !line.names.isEmpty else { return format }
        return String(format: format, names(line.names, bundle: bundle))
    }

    /// The names of a line: all of them joined with commas up to `namesInFull`, else the first `namesShown` "and N
    /// more".
    static func names(_ names: [String], bundle: Bundle = .main) -> String {
        guard names.count > namesInFull else { return names.joined(separator: ", ") }
        let shown = names.prefix(namesShown).joined(separator: ", ")
        return String(format: string(YardLine.namesMore, bundle: bundle), shown, names.count - namesShown)
    }

    /// The dawn report's yard lines in the player's language (none without a yard or with nothing to tell).
    static func lines(_ report: DawnReport, bundle: Bundle = .main) -> [String] {
        guard let yard = report.yard else { return [] }
        return yard.lines().map { text($0, bundle: bundle) }
    }

    /// What a touch on the yard's thing buys ("Build the drill yard", "Order the pitch kettle").
    static func label(_ offer: YardOffer, bundle: Bundle = .main) -> String {
        switch offer {
        case .stage:
            return string(YardLine.offerStage, bundle: bundle)
        case .kettle:
            return string(YardLine.offerKettle, bundle: bundle)
        }
    }
}
