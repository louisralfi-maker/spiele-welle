/// A variant of the table's values for the tuning pass (never shipped): a name and its catalogue. `TableTuning.variants`
/// measures the sender and greedy cells for each, so one runner round can decide between values (QUESTS.md 4.4: tune
/// by values only).
struct TableVariant: Sendable {
    var name: String
    var catalog: ErrandCatalog

    /// The catalogue with some sendings and reports changed.
    static func make(_ name: String, from base: ErrandCatalog, errands: (inout Errand) -> Void = { _ in },
                     reports: (inout TableReport) -> Void = { _ in }) -> TableVariant {
        var list = base.errands
        for index in list.indices { errands(&list[index]) }
        var cards = base.reports
        for index in cards.indices { reports(&cards[index]) }
        return TableVariant(name: name, catalog: ErrandCatalog(chapter: base.chapter, lanterns: base.lanterns,
                                                               reserved: base.reserved, places: base.places,
                                                               errands: list, reports: cards))
    }
}

extension TableTuning {
    /// The sender and greedy cells for each variant against the given reference runs (no endless: T7 is the shipped
    /// values' only), one line per variant.
    static func variants(_ list: [TableVariant], reference: [TableSeedRun], balance: Balance = .standard,
                         seeds: Int = TableTuning.seeds) -> String {
        struct Job: Sendable {
            var variant: Int
            var seed: Int
            var policy: TableBot.Policy
        }
        var jobs: [Job] = []
        for variant in list.indices {
            for policy in TableBot.Policy.allCases {
                for seed in 1...max(1, seeds) { jobs.append(Job(variant: variant, seed: seed, policy: policy)) }
            }
        }
        let work = jobs
        let catalogs = list.map(\.catalog)
        let runs = parallel(work.count) { index in
            TableTuning.chapter(seed: work[index].seed, policy: work[index].policy,
                                catalog: catalogs[work[index].variant], balance: balance, endless: false)
        }
        var lines = ["Variants (not shipped, not asserted), \(seeds) seeds each, against the same reference runs:"]
        for (index, variant) in list.enumerated() {
            var m = TableTuning()
            m.reference = reference
            for (job, run) in zip(work, runs) where job.variant == index {
                if job.policy == .sender { m.sender.append(run) } else { m.greedy.append(run) }
            }
            m.sender.sort { $0.seed < $1.seed }
            m.greedy.sort { $0.seed < $1.seed }
            let d = m.t10Differences
            let full = m.sender.map { $0.fullDays.count }
            let starved = m.greedy.map { $0.unsentForWantOfAHook.count }
            func mark(_ ok: Bool) -> String { ok ? "ok" : "NO" }
            let held = TableTuning.heldWithout(m.sender)
            var line = "\(variant.name): T6 sender won \(TableTuning.won(m.sender)), without held \(held) "
            line += "[\(mark(10 * held >= 3 * m.sender.count && 10 * held <= 6 * m.sender.count))]"
            line += " | T10 gold \(TuningRun.tenths(TableTuning.median(d.gold))), soldiers "
            line += "\(TuningRun.tenths(TableTuning.median(d.soldiers))), happiness "
            line += "\(TuningRun.tenths(TableTuning.median(d.happiness))) [\(mark(m.passes("T10")))]"
            line += " | T11 sender median \(TuningRun.tenths(TableTuning.median(full))) \(full) [\(mark(m.passes("T11 sender")))]"
            line += " | T11 greedy median \(TuningRun.tenths(TableTuning.median(starved))) \(starved) "
            line += "[\(mark(m.passes("T11 greedy")))]"
            line += " | greedy without held \(TableTuning.heldWithout(m.greedy)) [\(mark(m.passes("T6 greedy")))]"
            line += " | greedy lost \(m.greedy.map(\.lanternsLost).reduce(0, +))"
            lines.append(line)
        }
        return lines.joined(separator: "\n")
    }
}
