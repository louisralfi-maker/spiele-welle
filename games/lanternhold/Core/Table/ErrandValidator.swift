import Foundation

/// Checks the Lantern Table's content (docs/QUESTS.md 4.1 and 4.3): every table file against the schema (no unknown
/// key, which catches typos the decoder would skip), every reference (places, reports, speakers, petitions heard,
/// world changes, sites, night modifiers; every flag a sending or an order requires is set somewhere), the rules of
/// the seal and of the risk chips, the rules of reports (no chance, schedule or unlock; a night only with `instead`;
/// one free choice) and every text key in English and German within its length (QUESTS.md 5.5; reports as
/// petitions). `ErrandDataTests` runs it over the bundle's files and the source folder.
enum ErrandValidator {
    typealias Limit = CourtValidator.Limit

    static let titleLimit = Limit(english: 28, german: 38)
    static let hookLimit = Limit(english: 60, german: 80)
    static let orderLimit = Limit(english: 40, german: 52)
    static let placeLimit = Limit(english: 24, german: 28)
    /// Gold for the road: 0 to 30 (QUESTS.md 2.3).
    static let goldCostLimit = 30
    /// Nights away: 1 to 5.
    static let nightsLimit = 1...5
    /// People one order lends, of each kind.
    static let lendLimit = 3

    /// Every problem of the table files; empty when all is well. `petitions` gives the flags the court sets and the
    /// petitions a sending may need heard.
    static func problems(files: [(name: String, data: Data)], table: StoryTable,
                         petitions: PetitionCatalog) -> [String] {
        var out: [String] = []
        for file in files { out += rawProblems(file.data, file: file.name) }
        let merged = ErrandCatalog.merge(files)
        out += merged.problems
        let catalog = merged.catalog
        out += railProblems(catalog)
        let known = CourtValidator.flagsSet(in: petitions).union(CourtValidator.codeFlags).union(flagsSet(in: catalog))
        for place in catalog.places { out += check(place, table: table) }
        var numbers: [Int: String] = [:]
        for errand in catalog.errands {
            if let other = numbers[errand.number] {
                out.append("\(errand.id): number \(errand.number) is \(other)'s too")
            }
            numbers[errand.number] = errand.id
            out += check(errand, catalog: catalog, known: known, petitions: petitions, table: table)
        }
        var used: Set<String> = [ErrandCatalog.lostReportID]
        for errand in catalog.errands {
            if let lost = errand.lostReport { used.insert(lost) }
            for order in errand.orders {
                used.insert(order.report)
                for alt in order.altReport ?? [] { used.insert(alt.report) }
            }
        }
        if catalog.report(ErrandCatalog.lostReportID) == nil && !catalog.errands.isEmpty {
            out.append("the report \(ErrandCatalog.lostReportID) (a lantern that did not come home) is missing")
        }
        for report in catalog.reports {
            if !used.contains(report.id) { out.append("report \(report.id): no order brings it home") }
            out += check(report, table: table)
        }
        if let lost = catalog.report(ErrandCatalog.lostReportID) {
            for (index, choice) in lost.choices.enumerated() where !CourtValidator.costsNothing(choice.effect) {
                out.append("report \(lost.id) choice \(index + 1): both choices of a lost lantern are free")
            }
        }
        for entry in QuestText.uiKeys { out += text(entry.key, limit: entry.limit, what: "table screen", table: table) }
        return out
    }

    /// Every flag the table sets (costs, returns, losses, report choices).
    static func flagsSet(in catalog: ErrandCatalog) -> Set<String> {
        var flags = Set<String>()
        func add(_ effect: PetitionEffect?) {
            for flag in effect?.flags ?? [] where !flag.hasPrefix("-") { flags.insert(flag) }
        }
        for errand in catalog.errands {
            add(errand.atReturn)
            for order in errand.orders {
                add(order.cost)
                add(order.atReturn)
                add(order.atLoss)
            }
        }
        for report in catalog.reports {
            for choice in report.choices {
                add(choice.effect)
                add(choice.instead)
            }
        }
        return flags
    }

    /// The rail: road lanterns, distinct, the reserved ones apart.
    static func railProblems(_ catalog: ErrandCatalog) -> [String] {
        var out: [String] = []
        if catalog.lanterns.isEmpty && !catalog.errands.isEmpty { out.append("the rail has no road lanterns") }
        if Set(catalog.lanterns).count != catalog.lanterns.count { out.append("a road lantern is on the rail twice") }
        for number in catalog.reserved where catalog.lanterns.contains(number) {
            out.append("lantern \(number) is both a road lantern and reserved")
        }
        for number in catalog.lanterns + catalog.reserved where number < 1 || number > 99 {
            out.append("lantern \(number) needs a number from 1 to 99")
        }
        return out
    }

    // MARK: - Schema

    /// Keys the decoder would skip silently.
    static func rawProblems(_ data: Data, file: String) -> [String] {
        guard let root = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else { return [] }
        var out: [String] = []
        for key in root.keys.sorted() where !ErrandCatalog.fileKeys.contains(key) {
            out.append("\(file): unknown top-level key \(key)")
        }
        func objects(_ key: String) -> [(id: String, object: [String: Any])] {
            var list: [(id: String, object: [String: Any])] = []
            for (position, item) in ((root[key] as? [Any]) ?? []).enumerated() {
                guard let object = item as? [String: Any] else {
                    out.append("\(file): \(key) #\(position) is not an object")
                    continue
                }
                list.append(((object["id"] as? String) ?? "#\(position)", object))
            }
            return list
        }
        func effect(_ value: Any?, at place: String) {
            guard let value else { return }
            guard let object = value as? [String: Any] else {
                out.append("\(place) is not an object")
                return
            }
            out += CourtValidator.unknownKeys(object, allowed: PetitionEffect.keys, at: place)
        }
        for (id, place) in objects("places") {
            out += CourtValidator.unknownKeys(place, allowed: TablePlace.keys, at: "\(file): place \(id)")
        }
        for (id, errand) in objects("errands") {
            let at = "\(file): \(id)"
            out += CourtValidator.unknownKeys(errand, allowed: Errand.keys, at: at)
            effect(errand["atReturn"], at: "\(at) atReturn")
            for (index, item) in ((errand["orders"] as? [Any]) ?? []).enumerated() {
                let here = "\(at) order \(index + 1)"
                guard let order = item as? [String: Any] else {
                    out.append("\(here) is not an object")
                    continue
                }
                out += CourtValidator.unknownKeys(order, allowed: ErrandOrder.keys, at: here)
                if let lend = order["lend"] as? [String: Any] {
                    out += CourtValidator.unknownKeys(lend, allowed: ErrandLend.keys, at: "\(here) lend")
                }
                for alt in (order["altReport"] as? [Any]) ?? [] {
                    if let object = alt as? [String: Any] {
                        out += CourtValidator.unknownKeys(object, allowed: AltReport.keys, at: "\(here) altReport")
                    }
                }
                effect(order["cost"], at: "\(here) cost")
                effect(order["atReturn"], at: "\(here) atReturn")
                effect(order["atLoss"], at: "\(here) atLoss")
            }
        }
        for (id, report) in objects("reports") {
            let at = "\(file): report \(id)"
            out += CourtValidator.unknownKeys(report, allowed: TableReport.keys, at: at)
            for (index, item) in ((report["choices"] as? [Any]) ?? []).enumerated() {
                guard let choice = item as? [String: Any] else {
                    out.append("\(at) choice \(index + 1) is not an object")
                    continue
                }
                out += CourtValidator.unknownKeys(choice, allowed: ReportChoice.keys, at: "\(at) choice \(index + 1)")
                effect(choice["instead"], at: "\(at) choice \(index + 1) instead")
            }
        }
        return out
    }

    // MARK: - Places, sendings, orders

    static func check(_ place: TablePlace, table: StoryTable) -> [String] {
        var out: [String] = []
        if !CourtValidator.isName(place.id) {
            out.append("place \(place.id): the id must be lowercase letters, digits and _")
        }
        if place.kind == .home {
            if place.nights != 0 { out.append("place \(place.id): home takes no nights") }
        } else if !nightsLimit.contains(place.nights) {
            out.append("place \(place.id): nights \(place.nights) outside \(nightsLimit)")
        }
        out += text(place.nameKey, limit: placeLimit, what: "place \(place.id) name", table: table)
        return out
    }

    static func check(_ errand: Errand, catalog: ErrandCatalog, known: Set<String>, petitions: PetitionCatalog,
                      table: StoryTable) -> [String] {
        var out: [String] = []
        let id = errand.id
        func note(_ text: String) { out.append("\(id): \(text)") }
        if !CourtValidator.isName(id) { note("the id must be lowercase letters, digits and _") }
        if errand.number < 1 { note("number \(errand.number) below 1") }
        if let place = catalog.place(errand.place) {
            if place.kind == .home { note("nobody is sent home") }
        } else {
            note("unknown place \(errand.place)")
        }
        if let chapter = errand.chapter, chapter != catalog.chapter { note("chapter \(chapter) is not the table's") }
        if !CourtValidator.validDays(errand.days) { note("days must be [day] or [from, to], from day 1") }
        if errand.dayRange.lowerBound < ErrandEngine.firstDay {
            note("the table is under its cloth before day \(ErrandEngine.firstDay)")
        }
        for flag in (errand.requires ?? []) + (errand.requiresAny ?? []) + (errand.forbids ?? []) {
            if !CourtValidator.isName(flag) { note("the flag \(flag) must be lowercase letters, digits and _") }
        }
        for flag in (errand.requires ?? []) + (errand.requiresAny ?? []) where !known.contains(flag) {
            note("the flag \(flag) is never set")
        }
        for petition in errand.heard ?? [] where petitions.petition(petition) == nil {
            note("heard \(petition) is no petition")
        }
        for change in errand.world ?? [] where !TableWorld.isKnown(change) { note("world \(change) is unknown") }
        for site in errand.unlocked ?? [] where !ErrandEngine.sites.contains(site) {
            note("unlocked \(site) is not one of \(ErrandEngine.sites.sorted())")
        }
        if let lantern = errand.lantern, !catalog.lanterns.contains(lantern) && !catalog.reserved.contains(lantern) {
            note("lantern \(lantern) is not on the rail")
        }
        if let lost = errand.lostReport, catalog.report(lost) == nil { note("lostReport \(lost) is no report") }
        if errand.orders.isEmpty || errand.orders.count > 2 { note("needs one or two orders") }
        if let effect = errand.atReturn { out += check(effect, place: "\(id) atReturn", returnOnly: true) }
        if errand.offered != false {
            out += text(errand.titleKey, limit: titleLimit, what: "\(id) title", table: table)
            for key in errand.hookKeys { out += text(key, limit: hookLimit, what: "\(id) hook", table: table) }
        }
        for (index, order) in errand.orders.enumerated() {
            out += check(order, index: index, of: errand, catalog: catalog, known: known, table: table)
        }
        return out
    }

    static func check(_ order: ErrandOrder, index: Int, of errand: Errand, catalog: ErrandCatalog, known: Set<String>,
                      table: StoryTable) -> [String] {
        var out: [String] = []
        let place = "\(errand.id) order \(index + 1)"
        func note(_ text: String) { out.append("\(place): \(text)") }
        if !nightsLimit.contains(order.nights) { note("nights \(order.nights) outside \(nightsLimit)") }
        for (flag, nights) in order.nightsWith ?? [:] {
            if !known.contains(flag) { note("nightsWith \(flag) is never set") }
            if nights < 1 || nights >= order.nights {
                note("nightsWith \(flag) must shorten the road (1 to \(order.nights - 1))")
            }
        }
        if let cost = order.cost {
            var rest = cost
            rest.gold = nil
            rest.flags = nil
            if rest != PetitionEffect() { note("a cost is gold and flags only") }
            if let gold = cost.gold, gold > 0 || -gold > goldCostLimit {
                note("gold \(gold) outside 0 to -\(goldCostLimit)")
            }
            for flag in cost.flags ?? [] {
                let name = flag.hasPrefix("-") ? String(flag.dropFirst()) : flag
                if !CourtValidator.isName(name) { note("the flag \(flag) must be lowercase letters, digits and _") }
            }
        }
        let lend = order.lend ?? ErrandLend()
        for (name, value) in [("archers", lend.archers), ("guards", lend.guards), ("builders", lend.builders),
                              ("citizens", lend.citizens)] {
            if let value, value < 0 || value > lendLimit { note("lend \(name) \(value) outside 0 to \(lendLimit)") }
        }
        for who in order.goes ?? [] where !Speakers.isKnown(who) { note("goes: unknown speaker \(who)") }
        if lend.isEmpty && (order.goes ?? []).isEmpty { note("nobody carries the lantern") }
        let risk = order.risk ?? 0
        let tier = RiskTier(risk)
        if risk < 0 || !tier.band.contains(risk) {
            note("risk \(risk) is in no chip's band (0, 0.10 to 0.15, 0.25 to 0.30)")
        }
        if order.late == true && risk <= 0 { note("late without a risk") }
        if order.isSealed {
            if risk > 0 { note("a sealed order risks nothing") }
            if lend.soldiers > ErrandEngine.sealMostSoldiers {
                note("a sealed order lends at most \(ErrandEngine.sealMostSoldiers) soldiers")
            }
            if !sealCanHold(order, days: errand.dayRange) {
                note("the seal can never hold: every day's nights away include night 7, 10 or 17 to 20")
            }
            if let report = catalog.report(order.report), report.counsel == nil {
                note("a sealed order's report needs a counsel choice")
            }
        }
        for flag in (order.requires ?? []) + (order.forbids ?? []) where !CourtValidator.isName(flag) {
            note("the flag \(flag) must be lowercase letters, digits and _")
        }
        for flag in order.requires ?? [] where !known.contains(flag) { note("the flag \(flag) is never set") }
        if catalog.report(order.report) == nil { note("report \(order.report) is missing") }
        for alt in order.altReport ?? [] where catalog.report(alt.report) == nil {
            note("altReport \(alt.report) is missing")
        }
        if let effect = order.atReturn { out += check(effect, place: "\(place) atReturn", returnOnly: true) }
        if let effect = order.atLoss { out += check(effect, place: "\(place) atLoss", returnOnly: true) }
        if errand.orders.count > 1 {
            if let label = order.label {
                out += text(label, limit: orderLimit, what: "\(place) label", table: table)
            } else {
                note("a sending with two orders labels each")
            }
        } else if let label = order.label {
            out += text(label, limit: orderLimit, what: "\(place) label", table: table)
        }
        return out
    }

    /// True when some day of the window lets the seal hold by its nights (7, 10 and 17 to 20 never away).
    static func sealCanHold(_ order: ErrandOrder, days: ClosedRange<Int>) -> Bool {
        for day in days {
            let nights = day...(day + max(1, order.nights) - 1)
            if !nights.contains(where: { ErrandEngine.sealBlockedNights.contains($0) }) { return true }
        }
        return false
    }

    // MARK: - Reports and effects

    static func check(_ report: TableReport, table: StoryTable) -> [String] {
        var out: [String] = []
        let id = "report \(report.id)"
        func note(_ text: String) { out.append("\(id): \(text)") }
        if !CourtValidator.isName(report.id) { note("the id must be lowercase letters, digits and _") }
        if !Speakers.isKnown(report.speaker) { note("unknown speaker \(report.speaker)") }
        out += text(report.text, limit: CourtValidator.textLimit, what: "\(id) text", table: table)
        if report.choices.count < 2 || report.choices.count > 3 { note("needs 2 or 3 choices") }
        if let counsel = report.counsel, counsel < 0 || counsel >= report.choices.count {
            note("counsel \(counsel) is not one of the choices")
        }
        var free = false
        for (index, choice) in report.choices.enumerated() {
            let place = "\(id) choice \(index + 1)"
            out += text(choice.label, limit: CourtValidator.choiceLimit, what: "\(place) label", table: table)
            if CourtValidator.costsNothing(choice.effect) { free = true }
            out += check(choice.effect, place: place, returnOnly: false)
            if let reaction = choice.effect.reaction {
                out += text(reaction, limit: CourtValidator.reactionLimit, what: "\(place) reaction", table: table)
            }
            let night = choice.effect.night ?? []
            if !night.isEmpty && choice.instead == nil {
                out.append("\(place): a night needs an `instead` for the days outside 4 to 14")
            }
            if let instead = choice.instead {
                if night.isEmpty { out.append("\(place): `instead` without a night") }
                if !(instead.night ?? []).isEmpty { out.append("\(place): `instead` changes no night") }
                out += check(instead, place: "\(place) instead", returnOnly: false)
                if let reaction = instead.reaction {
                    out += text(reaction, limit: CourtValidator.reactionLimit, what: "\(place) instead reaction",
                                table: table)
                }
            }
        }
        if !free { note("one choice is always free") }
        return out
    }

    /// An effect of the table: no chance, schedule or unlock; known world changes and night modifiers; the petitions'
    /// limits. A return or a loss changes no night either.
    static func check(_ effect: PetitionEffect, place: String, returnOnly: Bool) -> [String] {
        var out: [String] = []
        if effect.chance != nil { out.append("\(place): the table uses no chance") }
        if effect.schedule != nil { out.append("\(place): the table schedules no petition") }
        if effect.unlock != nil { out.append("\(place): the table unlocks nothing") }
        if returnOnly && effect.night != nil { out.append("\(place): a return changes no night") }
        if returnOnly && effect.reaction != nil { out.append("\(place): a return has no reaction") }
        if let happiness = effect.happiness, abs(happiness) > CourtValidator.happinessLimit {
            out.append("\(place): happiness \(happiness) beyond ±\(CourtValidator.happinessLimit)")
        }
        if let gold = effect.gold, abs(gold) > CourtValidator.goldLimit {
            out.append("\(place): gold \(gold) beyond ±\(CourtValidator.goldLimit)")
        }
        for (name, value) in [("citizens", effect.citizens), ("archers", effect.archers), ("guards", effect.guards),
                              ("builders", effect.builders)] {
            if let value, abs(value) > CourtValidator.peopleLimit {
                out.append("\(place): \(name) \(value) beyond ±\(CourtValidator.peopleLimit)")
            }
        }
        for flag in effect.flags ?? [] {
            let name = flag.hasPrefix("-") ? String(flag.dropFirst()) : flag
            if !CourtValidator.isName(name) {
                out.append("\(place): the flag \(flag) must be lowercase letters, digits and _")
            }
        }
        for change in effect.world ?? [] where !TableWorld.isKnown(change) {
            out.append("\(place): world \(change) is unknown")
        }
        for night in effect.night ?? [] where NightModifier(id: night) == nil {
            out.append("\(place): night \(night) is unknown")
        }
        return out
    }

    /// A text key: English and German exist, and each stays within its limit at its longest (placeholders at their
    /// longest values, `{lord}` a long name, `{a|b}` its longer half); a brace group left over is a problem.
    static func text(_ key: String, limit: Limit, what: String, table: StoryTable) -> [String] {
        var out: [String] = []
        let sides: [(name: String, text: String?, limit: Int)] = [
            ("English", table.english[key], limit.english), ("German", table.german[key], limit.german),
        ]
        for side in sides {
            guard let text = side.text, !text.isEmpty else {
                out.append("\(what): \(key) has no \(side.name) text")
                continue
            }
            let filled = QuestText.fill(text, QuestText.longestValues)
            let length = LordText.longest(filled)
            if length > side.limit {
                out.append("\(what): \(key) is \(length) characters in \(side.name) (at most \(side.limit))")
            }
            for broken in LordText.problems(filled) {
                out.append("\(what): \(key) has a brace group that is no placeholder in \(side.name): \(broken)")
            }
        }
        return out
    }

    /// Every text key the table's content and screen use.
    static func keys(_ catalog: ErrandCatalog) -> [String] {
        var keys: [String] = QuestText.uiKeys.map { $0.key }
        for place in catalog.places { keys.append(place.nameKey) }
        for errand in catalog.errands {
            keys.append(errand.titleKey)
            keys += errand.hookKeys
            for order in errand.orders { if let label = order.label { keys.append(label) } }
        }
        for report in catalog.reports {
            keys.append(report.text)
            for choice in report.choices {
                keys.append(choice.label)
                if let reaction = choice.effect.reaction { keys.append(reaction) }
                if let reaction = choice.instead?.reaction { keys.append(reaction) }
            }
        }
        return keys
    }
}
