/// `-GWScreen craft` (craft lane): a travelling craftsman waits alone before the throne on a morning, his offer about
/// to be heard. `-GWCraft <id>` picks him (the stonemason by default), `-GWCraftAgain YES` makes it his return visit
/// after "not now" (two answers), `-GWCraftStage hamlet|village|town` the realm's stage the painter speaks to (its
/// happiness; left out: the realm's own). The realm gets enough gold for the commission, so the commissioned card can be
/// shown.
enum CraftSample {
    static let defaultCraftsman = "mason"
    /// Day 9 (a craftsman's day after the war tax's story, which the sample's queue leaves out) at 10:30.
    static let day = 9
    static let hour = 10.5

    /// The realm with the craftsman waiting; false when the book has no such craftsman (the realm stays as it was).
    @discardableResult
    static func prepare(_ s: inout GameState, craftsman id: String, again: Bool, stage: CraftStage? = nil,
                        book: CraftBook = .standard) -> Bool {
        guard let craftsman = book.craftsman(id) else { return false }
        if let stage { s.happiness = stage.sampleHappiness() }
        s.day = max(s.day, day)
        s.hour = hour
        CraftVisits.begin(&s)
        var craft = s.craft ?? CraftState()
        craft.checkedDay = s.day
        craft.slotDay = 0
        craft.met.removeAll { $0.id == craftsman.id }
        craft.works.removeAll { $0.id == craftsman.id }
        craft.met.append(CraftMeeting(id: craftsman.id, day: again ? s.day - book.rules.returnAfter : s.day,
                                      answer: .waiting, returnDay: nil, returned: again))
        s.craft = craft
        var court = s.court ?? CourtState()
        court.queueDay = s.day
        court.queue = [Petitioner(id: CraftBook.offerID(craftsman.id, again: again), reason: .random,
                                  look: CraftVisits.look(craftsman.id))]
        s.court = court
        s.gold = max(s.gold, craftsman.price + 40)
        s.king.x = KingTargets.throneX
        s.king.velocity = 0
        return true
    }
}
