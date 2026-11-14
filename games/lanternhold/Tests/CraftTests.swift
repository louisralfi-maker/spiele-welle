import Foundation
import XCTest
@testable import Lanternhold

/// The travelling craftsmen (craft lane, step 1; docs/TOWN.md section 4, docs/lanes/craft.md): the book of ten, their
/// words in English and German within the audience card's limits, the offer as an audience, the visits (from day 4 about
/// every third day, never on a story day, "not now" once, "no" for good, nobody hurt by an unheard craftsman), the
/// commission and its building time, every work's effect behind its flag, the save, a run without commissions that is
/// today's run line for line, and the size of every effect measured with the reference bots.
final class CraftTests: XCTestCase {
    private static let gameFolder = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        .deletingLastPathComponent()

    private var book: CraftBook { .standard }

    /// A realm with the craftsmen begun, on `day` at 07:00, no petitioners drawn yet.
    private func realm(seed: UInt64 = 7, day: Int = 1) -> GameState {
        var s = GameState.newRealm(seed: seed)
        CraftVisits.begin(&s)
        s.day = day
        s.hour = 7
        return s
    }

    /// The craftsman in today's queue, if one waits: his offer id and position.
    private func visitor(_ s: GameState) -> (id: String, position: Int)? {
        guard let queue = s.court?.queue, let position = queue.firstIndex(where: { CraftBook.isCraft($0.id) }) else {
            return nil
        }
        return (queue[position].id, position)
    }

    /// The morning of `day`: the day's queue is drawn (and a craftsman may join it).
    private func morning(_ s: inout GameState, day: Int, catalog: PetitionCatalog = .empty) {
        s.day = day
        s.hour = 7
        PetitionEngine.prepare(&s, catalog: catalog)
    }

    private func evening(_ s: inout GameState) {
        s.hour = 19
        PetitionEngine.horn(&s)
    }

    private func standing(_ ids: [String], ordered day: Int = 1) -> CraftState {
        var craft = CraftState()
        craft.works = ids.map { CraftOrder(id: $0, orderedDay: day, readyDay: day + 1, stands: true) }
        return craft
    }

    // MARK: - The book

    func testTheBookHoldsTenCraftsmenWithTenWorks() throws {
        let loaded = CraftBook.load(bundle: .main)
        XCTAssertTrue(loaded.found, "craftsmen.json is in the app bundle")
        XCTAssertEqual(loaded.problems, [])
        XCTAssertEqual(loaded.book, CraftBook.standard, "the game plays with it")
        XCTAssertEqual(book.rules, CraftRules(firstDay: 4, every: 3, returnAfter: 4))
        XCTAssertEqual(book.craftsmen.count, 10)
        XCTAssertEqual(Set(book.craftsmen.map(\.effect)), Set(CraftEffect.allCases), "one effect each, all ten")
        XCTAssertEqual(Set(book.craftsmen.map(\.work)).count, 10)
        XCTAssertEqual(book.craftsmen.filter(\.pride).map(\.work).sorted(), ["bell", "portrait", "statue"],
                       "three works of pride")
        for c in book.craftsmen {
            XCTAssertTrue((20...150).contains(c.price), "\(c.id) price \(c.price)")
            XCTAssertTrue((1...2).contains(c.days), "\(c.id): the work stands one or two days later")
            XCTAssertGreaterThanOrEqual(c.from, book.rules.firstDay, c.id)
            XCTAssertTrue((0...2).contains(c.counsel), c.id)
            XCTAssertNotNil(SpriteID(rawValue: c.body), "\(c.id) stands in the hall as \(c.body)")
            XCTAssertNotNil(CraftBook.portraitStyle(c.look), "\(c.id)'s portrait parts")
            XCTAssertTrue(c.amount > 0, c.id)
            for need in c.needs { XCTAssertNotNil(BuildItem(rawValue: need), "\(c.id) needs \(need)") }
            XCTAssertFalse(c.id.contains("_"), "\(c.id): the offer ids end with _again")
        }
        XCTAssertEqual(book.craftsmen.filter { $0.place == .town }.map(\.work).sorted(), ["lanterns", "statue"])
    }

    func testTheWordsAreInEnglishAndGermanWithinTheCardsLimits() throws {
        let url = Self.gameFolder.appendingPathComponent("Resources/Craftsmen.xcstrings")
        let keys = CraftText.keys(book)
        let table: StoryTable
        if let data = try? Data(contentsOf: url), let parsed = StoryTable.parse(data) {
            table = parsed
        } else {
            table = StoryTable.compiled(keys: keys, bundle: .main)
        }
        func limit(_ key: String) -> CourtValidator.Limit {
            if key == CraftText.later || key == CraftText.no { return CourtValidator.choiceLimit }
            switch key.split(separator: ".").last.map(String.init) ?? "" {
            case "name": return CourtValidator.nameLimit
            case "role": return CourtValidator.roleLimit
            case "text", "again": return CourtValidator.textLimit
            case "hint": return CourtValidator.hintLimit
            case "c1": return CourtValidator.choiceLimit
            default: return CourtValidator.reactionLimit
            }
        }
        XCTAssertEqual(keys.count, 92)
        var lines: [String] = []
        for key in keys {
            let english = try XCTUnwrap(table.english[key], "\(key) in English")
            let german = try XCTUnwrap(table.german[key], "\(key) in German")
            let bound = limit(key)
            XCTAssertFalse(english.isEmpty || german.isEmpty, key)
            XCTAssertLessThanOrEqual(english.count, bound.english, "\(key) English: \(english.count)")
            XCTAssertLessThanOrEqual(german.count, bound.german, "\(key) German: \(german.count)")
            for text in [english, german] {
                XCTAssertFalse(LordText.pieces(text).contains { if case .broken = $0 { return true }; return false },
                               "\(key): a broken {a|b}")
                XCTAssertFalse(text.contains("{lord}"), "\(key): the limits count no long name")
            }
            if key.hasSuffix(".name") {
                XCTAssertEqual(english, german, "\(key): names are never translated")
            } else {
                XCTAssertNotEqual(english, german, "\(key) is translated")
            }
            // The build compiled it into its own table, and the story's texts reach it.
            XCTAssertEqual(StoryText.string(key, language: "en"), english, "\(key) compiled in English")
            XCTAssertEqual(StoryText.string(key, language: "de"), german, "\(key) compiled in German")
            lines.append("\(key) en \(english.count)/\(bound.english) de \(german.count)/\(bound.german)")
        }
        XCTAssertEqual(StoryText.string("speaker.odile.role", language: "de"), "Kanzlerin", "the story's table still")
        let attachment = XCTAttachment(string: lines.joined(separator: "\n"))
        attachment.name = "craft-text-lengths"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    // MARK: - The offer as an audience

    func testAnOfferIsAnAudienceCard() throws {
        let mason = try XCTUnwrap(book.craftsman("mason"))
        let offer = try XCTUnwrap(PetitionCatalog.standard.petition("craft_mason"))
        XCTAssertEqual(offer.choices.map(\.label), ["craft.mason.c1", CraftText.later, CraftText.no])
        XCTAssertEqual(offer.choices[0].effect.gold, -mason.price)
        XCTAssertEqual(offer.choices[1].effect.gold, nil, "not now costs nothing")
        XCTAssertEqual(offer.choices.map { $0.effect.reaction }, ["craft.mason.r1", "craft.mason.r2", "craft.mason.r3"])
        XCTAssertEqual(offer.text, "craft.mason.text")
        XCTAssertEqual(offer.hint, "craft.mason.hint")
        XCTAssertEqual(offer.counsel, mason.counsel)
        XCTAssertEqual(offer.drawWeight, 0, "the petition engine never draws it")
        XCTAssertEqual(offer.kind, .random)
        let again = try XCTUnwrap(PetitionCatalog.empty.petition("craft_mason_again"), "every catalogue finds it")
        XCTAssertEqual(again.choices.map(\.label), ["craft.mason.c1", CraftText.no], "back once: commission or no")
        XCTAssertEqual(again.text, "craft.mason.again")
        XCTAssertNil(PetitionCatalog.standard.petition("craft_nobody"))
        XCTAssertFalse(PetitionCatalog.standard.petitions.contains { CraftBook.isCraft($0.id) },
                       "the catalogue's own list stays the petition files'")
        XCTAssertEqual(CraftBook.visit("craft_mason_again")?.craftsman, "mason")
        XCTAssertEqual(CraftBook.visit("craft_mason_again")?.again, true)
        XCTAssertEqual(CraftBook.visit("craft_mason")?.again, false)

        let speaker = try XCTUnwrap(Speakers.speaker("craft_mason"))
        XCTAssertEqual(speaker.role, .guest)
        XCTAssertEqual(speaker.nameKey, "craft.mason.name")
        XCTAssertEqual(speaker.roleKey, "craft.mason.role")
        XCTAssertTrue(Speakers.isKnown("craft_mason"))
        XCTAssertFalse(Speakers.all.contains { CraftBook.isCraft($0.id) }, "the court's list stays as it was")
        XCTAssertEqual(Speakers.recipe("craft_mason", look: 3), Speakers.recipe("craft_mason", look: 99_999),
                       "one fixed face")
        XCTAssertEqual(Speakers.recipe("craft_mason", look: 3)?.female, true)
        XCTAssertEqual(Speakers.recipe("craft_painter", look: 3)?.female, false)

        var s = realm(day: 9)
        XCTAssertTrue(CraftSample.prepare(&s, craftsman: "mason", again: false))
        XCTAssertEqual(s.court?.queue.map(\.id), ["craft_mason"])
        XCTAssertEqual(AudienceRules.hall(s, catalog: .standard).map(\.petitioner.id), ["craft_mason"])
        let session = try XCTUnwrap(AudienceSession.begin(.throne, state: s, catalog: .standard, figures: [],
                                                          reduceMotion: true))
        let card = try XCTUnwrap(AudienceCard.make(session: session, state: s, catalog: .standard))
        XCTAssertEqual(card.nameKey, "craft.mason.name")
        XCTAssertEqual(card.roleKey, "craft.mason.role")
        XCTAssertEqual(card.textKey, "craft.mason.text")
        XCTAssertEqual(card.options.map(\.gold), [-mason.price, 0, 0])
        XCTAssertTrue(card.options.allSatisfy(\.enabled))
        guard case .composed = card.portrait else { return XCTFail("a composed portrait") }
        var poor = s
        poor.gold = 10
        let greyed = try XCTUnwrap(AudienceCard.make(session: session, state: poor, catalog: .standard))
        XCTAssertEqual(greyed.options[0].blocker, .gold(missing: mason.price - 10), "greyed with the reason")
        XCTAssertNil(PetitionEngine.hear(&poor, choice: 0, catalog: .standard, balance: .standard))
        let figures = CourtLayout.figures(s, catalog: .standard)
        XCTAssertTrue(figures.contains { $0.who == "craft_mason" && $0.petition == "craft_mason" },
                      "he stands in the hall")
        var unknown = realm()
        XCTAssertFalse(CraftSample.prepare(&unknown, craftsman: "nobody", again: false))
    }

    // MARK: - The visits

    func testNoCraftsmanComesToARealmWithoutThem() {
        var s = GameState.newRealm(seed: 3)
        for day in 1...30 {
            morning(&s, day: day, catalog: .standard)
            XCTAssertNil(visitor(s), "day \(day)")
            evening(&s)
        }
        XCTAssertNil(s.craft)
    }

    func testTheVisitsComeEveryThirdDayAndEachComesBackOnceAfterNotNow() {
        var s = realm(seed: 11)
        var firsts: [(day: Int, id: String)] = []
        var returns: [(day: Int, id: String)] = []
        for day in 1...45 {
            morning(&s, day: day)
            let waiting = (s.court?.queue ?? []).filter { CraftBook.isCraft($0.id) }
            XCTAssertLessThanOrEqual(waiting.count, 1, "day \(day): one craftsman a day at most")
            if let id = waiting.first?.id, let visit = CraftBook.visit(id) {
                if visit.again { returns.append((day, visit.craftsman)) } else { firsts.append((day, visit.craftsman)) }
                let from = book.craftsman(visit.craftsman)?.from ?? 99
                XCTAssertGreaterThanOrEqual(day, from, "\(visit.craftsman) not before his day")
            }
            evening(&s)
            XCTAssertEqual(s.unheardPetitioners, 0, "an unheard craftsman costs nobody's happiness")
        }
        // Nobody built a brazier, so the glazier never comes: nine craftsmen, each back once four days later.
        XCTAssertEqual(firsts.map { $0.day }, [4, 7, 10, 13, 16, 19, 22, 25, 28])
        XCTAssertEqual(Set(firsts.map { $0.id }).count, 9)
        XCTAssertFalse(firsts.contains { $0.id == "glazier" }, "the glazier needs a brazier or a fire tower")
        XCTAssertEqual(returns.map { $0.id }, firsts.map { $0.id })
        XCTAssertEqual(returns.map { $0.day }, firsts.map { $0.day + 4 })
        XCTAssertTrue(s.craft?.met.allSatisfy { $0.answer == .declined && $0.returned } ?? false,
                      "unheard twice: gone for good")
        XCTAssertEqual(s.court?.history.filter { CraftBook.isCraft($0.id) }.count, 0, "never counted as unheard")

        // The same seed draws the same order; with a brazier the glazier comes too.
        var again = realm(seed: 11)
        var withBrazier = realm(seed: 11)
        if let plot = Realm.plotID("l1.brazier.a") { withBrazier.plots[plot].item = .brazier }
        var order: [String] = []
        var orderWith: [String] = []
        for day in 1...45 {
            morning(&again, day: day)
            morning(&withBrazier, day: day)
            if let id = visitor(again)?.id, CraftBook.visit(id)?.again == false { order.append(id) }
            if let id = visitor(withBrazier)?.id, CraftBook.visit(id)?.again == false { orderWith.append(id) }
            evening(&again)
            evening(&withBrazier)
        }
        XCTAssertEqual(order, firsts.map { "craft_" + $0.id })
        XCTAssertEqual(orderWith.count, 10)
        XCTAssertTrue(orderWith.contains("craft_glazier"))
    }

    func testAStoryDayHoldsTheVisitBackButTheHousesAudiencesDoNot() throws {
        let story = Petition(id: "story7", speaker: "farmer", kind: .story, days: [7, 7], text: "t",
                             choices: [PetitionChoice(label: "ok")])
        let house = Petition(id: "house10", speaker: "farmer", kind: .story, days: [10, 10], onTop: true, text: "t",
                             choices: [PetitionChoice(label: "ok")])
        let catalog = PetitionCatalog([story, house])
        var s = realm(seed: 5)
        var days: [Int] = []
        for day in 1...11 {
            morning(&s, day: day, catalog: catalog)
            if let found = visitor(s) {
                days.append(day)
                XCTAssertNotNil(PetitionEngine.hear(&s, choice: 2, at: found.position, catalog: catalog,
                                                    balance: .standard), "no, thank you")
            }
            evening(&s)
        }
        XCTAssertEqual(days, [4, 8, 10], "day 7 is a story day: the visit waits for day 8; a house on top is no story")
        // A story petition that comes as a follow-up makes a story day too; a random one does not.
        let random = Petition(id: "plain", speaker: "farmer", kind: .random, text: "t",
                              choices: [PetitionChoice(label: "ok")])
        let all = PetitionCatalog([story, house, random])
        XCTAssertTrue(CraftVisits.isStoryDay([Petitioner(id: "story7", reason: .followUp, look: 1)], catalog: all))
        XCTAssertFalse(CraftVisits.isStoryDay([Petitioner(id: "house10", reason: .story, look: 1),
                                               Petitioner(id: "plain", reason: .random, look: 2),
                                               Petitioner(id: "craft_mason", reason: .random, look: 3)], catalog: all))
    }

    func testNotNowBringsHimBackOnceAndNoSendsHimOn() throws {
        var s = realm(seed: 2)
        morning(&s, day: 4)
        let first = try XCTUnwrap(visitor(s))
        let id = try XCTUnwrap(CraftBook.visit(first.id)?.craftsman)
        let gold = s.gold
        XCTAssertNotNil(PetitionEngine.hear(&s, choice: 1, at: first.position, catalog: .empty, balance: .standard))
        XCTAssertEqual(s.gold, gold, "not now is free")
        XCTAssertEqual(s.craft?.meeting(id)?.answer, .later)
        XCTAssertEqual(s.craft?.meeting(id)?.returnDay, 8)
        XCTAssertNil(visitor(s), "heard: he leaves the queue")
        evening(&s)
        for day in 5...6 {
            morning(&s, day: day)
            XCTAssertNil(visitor(s), "day \(day)")
            evening(&s)
        }
        morning(&s, day: 7)
        let second = try XCTUnwrap(visitor(s), "a new one on day 7")
        XCTAssertNotEqual(CraftBook.visit(second.id)?.craftsman, id)
        XCTAssertNotNil(PetitionEngine.hear(&s, choice: 2, at: second.position, catalog: .empty, balance: .standard))
        XCTAssertEqual(s.craft?.meeting(CraftBook.visit(second.id)?.craftsman ?? "")?.answer, .declined)
        evening(&s)
        morning(&s, day: 8)
        let back = try XCTUnwrap(visitor(s), "back on day 8")
        XCTAssertEqual(back.id, CraftBook.offerID(id, again: true))
        XCTAssertEqual(PetitionCatalog.empty.petition(back.id)?.choices.count, 2)
        XCTAssertNotNil(PetitionEngine.hear(&s, choice: 1, at: back.position, catalog: .empty, balance: .standard),
                        "the second answer of his return is no, thank you")
        XCTAssertEqual(s.craft?.meeting(id)?.answer, .declined)
        evening(&s)
        for day in 9...40 {
            morning(&s, day: day)
            if let found = visitor(s), let visit = CraftBook.visit(found.id) {
                XCTAssertNotEqual(visit.craftsman, id, "day \(day): never again")
                XCTAssertNotEqual(visit.craftsman, CraftBook.visit(second.id)?.craftsman, "day \(day): never again")
            }
            evening(&s)
        }
    }

    func testACommissionIsPaidAtOnceAndTheWorkStandsDaysLater() throws {
        var s = realm(seed: 4)
        XCTAssertTrue(CraftSample.prepare(&s, craftsman: "mason", again: false))
        let mason = try XCTUnwrap(book.craftsman("mason"))
        let gold = s.gold
        let outcome = try XCTUnwrap(PetitionEngine.hear(&s, choice: 0, catalog: .standard, balance: .standard))
        XCTAssertEqual(outcome.gold, -mason.price)
        XCTAssertEqual(outcome.reaction, "craft.mason.r1")
        XCTAssertEqual(s.gold, gold - mason.price, "paid at once")
        XCTAssertEqual(s.craft?.works, [CraftOrder(id: "mason", orderedDay: 9, readyDay: 9 + mason.days)])
        XCTAssertEqual(s.craft?.meeting("mason")?.answer, .commissioned)
        XCTAssertFalse(s.craft?.stands("mason") ?? true)
        // Through the simulation's dawn: the work stands from the dawn `days` later, not before.
        var events: [SimEvent] = []
        s.day = 10
        s.hour = 6
        Sim.dawn(&s, balance: .standard, events: &events)
        XCTAssertFalse(s.craft?.stands("mason") ?? true, "the day after: still under way")
        s.day = 11
        Sim.dawn(&s, balance: .standard, events: &events)
        XCTAssertTrue(s.craft?.stands("mason") ?? false, "two days later it stands")
        XCTAssertEqual(CraftWorks.standing(s), ["mason"])
        XCTAssertEqual(CraftWorks.townWorks(s), 1, "the statue stands in the town")
    }

    // MARK: - The effects, each behind its flag

    func testAWorkThatDoesNotStandChangesNothing() {
        var s = realm()
        XCTAssertEqual(CraftWorks.balance(.standard, for: s), .standard)
        s.craft?.works = book.craftsmen.map { CraftOrder(id: $0.id, orderedDay: 1, readyDay: 5) }
        XCTAssertEqual(CraftWorks.balance(.standard, for: s), .standard, "ordered, not standing")
        XCTAssertEqual(CraftWorks.houseCoins(s, happiness: 90, balance: .standard), 0)
        s.craft = nil
        XCTAssertEqual(CraftWorks.balance(.standard, for: s), .standard)
    }

    func testTheStatueAddsACoinPerHouseWhileTheTownIsContent() {
        var s = realm()
        let houses = s.count(.house) + s.count(.bigHouse)
        XCTAssertGreaterThan(houses, 0)
        let before = Economy.taxes(s, happiness: 70, balance: .standard)
        s.craft = standing(["mason"])
        let after = Economy.taxes(s, happiness: 70, balance: .standard)
        XCTAssertEqual(after.taxPart, before.taxPart + houses)
        XCTAssertEqual(after.total, before.total + houses)
        var without = s
        without.craft = nil
        XCTAssertEqual(Economy.taxes(s, happiness: 59, balance: .standard),
                       Economy.taxes(without, happiness: 59, balance: .standard), "below the growth line: nothing")
    }

    func testThePortraitGivesItsHappinessOnceAsItIsHung() {
        var s = realm()
        s.happiness = 60
        s.craft?.works = [CraftOrder(id: "painter", orderedDay: 2, readyDay: 3)]
        s.day = 2
        XCTAssertEqual(CraftWorks.dawn(&s), [])
        XCTAssertEqual(s.happiness, 60)
        s.day = 3
        XCTAssertEqual(CraftWorks.dawn(&s), ["painter"])
        XCTAssertEqual(s.happiness, 63)
        s.day = 4
        CraftWorks.dawn(&s)
        XCTAssertEqual(s.happiness, 63, "once")
        XCTAssertEqual(CraftWorks.balance(.standard, for: s), .standard, "nothing else")
    }

    func testTheBalanceWorksChangeTheirOneValue() {
        let base = Balance.standard
        func with(_ id: String) -> Balance {
            var s = realm()
            s.craft = standing([id])
            return CraftWorks.balance(base, for: s)
        }
        var expected = base
        expected.soldierSpeed *= 1 + 0.1
        XCTAssertEqual(with("founder").soldierSpeed, expected.soldierSpeed, accuracy: 1e-9)
        XCTAssertEqual(with("founder"), expected, "the bell changes only the soldiers' speed")

        expected = base
        expected.brazierRadius *= 1 + 0.05
        expected.fireTowerRadius *= 1 + 0.05
        XCTAssertEqual(with("glazier"), expected)

        expected = base
        expected.patchShare = base.patchShare + 0.05
        XCTAssertEqual(with("limeburner").patchShare, 0.30, accuracy: 1e-9)
        XCTAssertEqual(with("limeburner"), expected)

        expected = base
        expected.guardRetreatShare = base.guardRetreatShare - 0.05
        XCTAssertEqual(with("weaver").guardRetreatShare, 0.25, accuracy: 1e-9)
        XCTAssertEqual(with("weaver"), expected)

        expected = base
        expected.builderSpeed *= 1 + 0.1
        XCTAssertEqual(with("wheelwright"), expected)

        expected = base
        expected.unrestBelow = base.unrestBelow - 3
        expected.grumbleBelow = base.grumbleBelow - 3
        XCTAssertEqual(with("lampmaker"), expected)

        expected = base
        expected.fireArrowSeconds += 1.0
        XCTAssertEqual(with("fletcher"), expected)

        let gate = with("ironwright")
        XCTAssertEqual(Build.maxHP(.gate, balance: gate), Build.maxHP(.gate, balance: base) * 1.05, accuracy: 1e-6)
        XCTAssertEqual(Build.maxHP(.greatGate, balance: gate), Build.maxHP(.greatGate, balance: base) * 1.05,
                       accuracy: 1e-6)
        XCTAssertEqual(Build.maxHP(.stoneWall, balance: gate), Build.maxHP(.stoneWall, balance: base), "only the gate")

        XCTAssertEqual(with("mason"), base, "the statue works in the taxes")
        XCTAssertEqual(with("painter"), base, "the portrait works once at its dawn")
    }

    func testTheRoadLanternsHoldUnrestOffAtDawnThroughTheSimulation() {
        func dawn(lanterns: Bool) -> DawnReport? {
            var s = realm()
            if lanterns { s.craft = standing(["lampmaker"]) }
            s.happiness = 13
            s.hour = 5.95
            var events: [SimEvent] = []
            Sim.step(&s, dt: 1, balance: .standard, events: &events)
            return s.lastReport
        }
        XCTAssertEqual(dawn(lanterns: false)?.taxes.unrest, true, "below 15: unrest")
        XCTAssertEqual(dawn(lanterns: true)?.taxes.unrest, false, "the lit road: the line sits at 12")
        XCTAssertGreaterThan(dawn(lanterns: true)?.taxes.total ?? 0, 0)
    }

    func testTheMortarMakesEveryPatchMendMore() throws {
        func patched(mortar: Bool) throws -> Double {
            var s = realm()
            if mortar { s.craft = standing(["limeburner"]) }
            s.hour = 22
            s.gold = 50
            let plot = Realm.lines[0].wall
            let item = try XCTUnwrap(s.plots[plot].item)
            s.plots[plot].hp = 1000
            s.king.x = Realm.plots[plot].x + min(item.width, 40) / 2
            var events: [SimEvent] = []
            XCTAssertTrue(Sim.patch(&s, plot: plot, balance: .standard, events: &events))
            return (s.plots[plot].hp - 1000) / Build.maxHP(item, balance: .standard)
        }
        XCTAssertEqual(try patched(mortar: false), 0.25, accuracy: 1e-9)
        XCTAssertEqual(try patched(mortar: true), 0.30, accuracy: 1e-9)
    }

    func testThePitchKeepsAFireArrowsFireBurningLonger() {
        var s = realm()
        s.craft = standing(["fletcher"])
        let tuned = CraftWorks.balance(.standard, for: s)
        XCTAssertEqual(tuned.fireArrowSeconds, Balance.standard.fireArrowSeconds + 1, accuracy: 1e-9)
    }

    // MARK: - The save

    func testTheCraftsmenRideInTheSave() throws {
        var s = realm(seed: 9, day: 8)
        var craft = CraftState()
        craft.checkedDay = 8
        craft.slotDay = 7
        craft.met = [CraftMeeting(id: "mason", day: 6, answer: .commissioned),
                     CraftMeeting(id: "weaver", day: 7, answer: .later, returnDay: 11)]
        craft.works = [CraftOrder(id: "mason", orderedDay: 6, readyDay: 8, stands: true)]
        s.craft = craft
        let data = try JSONEncoder().encode(s)
        XCTAssertEqual(try JSONDecoder().decode(GameState.self, from: data), s)

        // A save from before the craftsmen: no key, nil (the game starts them, `CraftVisits.begin`).
        var old = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        old.removeValue(forKey: "craft")
        let plain = try JSONDecoder().decode(GameState.self, from: JSONSerialization.data(withJSONObject: old))
        XCTAssertNil(plain.craft)
        var started = plain
        CraftVisits.begin(&started)
        XCTAssertEqual(started.craft, CraftState())
        CraftVisits.begin(&s)
        XCTAssertEqual(s.craft, craft, "begin keeps what a realm has")

        // Fields added later read with defaults.
        let empty = try JSONDecoder().decode(CraftState.self, from: Data("{}".utf8))
        XCTAssertEqual(empty, CraftState())
        let meeting = try JSONDecoder().decode(CraftMeeting.self, from: Data(#"{"id": "mason"}"#.utf8))
        XCTAssertEqual(meeting.answer, .declined)
        let order = try JSONDecoder().decode(CraftOrder.self, from: Data(#"{"id": "mason", "readyDay": 3}"#.utf8))
        XCTAssertFalse(order.stands)
    }

    // MARK: - Neutrality and the size of every effect (the reference bots)

    /// Bots never commission: a realm the craftsmen visit plays exactly as one they never visit, line for line.
    func testARunWithoutCommissionsIsTodaysRun() {
        var lines: [String] = []
        let runs: [(UInt64, Autoplay)] = [(1, .reference()), (2, .reference()), (3, .reference(tax: .high))]
        for (seed, bot) in runs {
            let plain = GameState.newRealm(seed: seed)
            var visited = plain
            CraftVisits.begin(&visited)
            let a = TuningRun.play(plain, bot: bot, balance: .standard, nights: 14)
            let b = TuningRun.play(visited, bot: bot, balance: .standard, nights: 14)
            XCTAssertEqual(a.outcomes.count, b.outcomes.count, "seed \(seed)")
            for (x, y) in zip(a.outcomes, b.outcomes) {
                XCTAssertEqual(x, y, "seed \(seed) night \(x.night)")
                lines.append("seed \(seed) night \(x.night): gold \(x.gold)/\(y.gold) happiness \(x.happiness)/"
                             + "\(y.happiness) taxes \(x.taxes)/\(y.taxes) killed \(x.killed)/\(y.killed)")
            }
            var after = b.final
            let craft = after.craft
            after.craft = nil
            XCTAssertEqual(a.final, after, "seed \(seed): the same realm, but for who came")
            XCTAssertGreaterThanOrEqual(craft?.met.count ?? 0, 3, "seed \(seed): craftsmen came")
            XCTAssertEqual(craft?.works ?? [], [], "seed \(seed): bots never commission")
            lines.append("seed \(seed): met \((craft?.met ?? []).map { "\($0.id)@\($0.day)" })")
        }
        let attachment = XCTAttachment(string: lines.joined(separator: "\n"))
        attachment.name = "craft-neutrality"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// The sums of some nights of runs.
    private struct Measure {
        var taxes = 0
        var happiness = 0
        var killed = 0
        var fallen = 0
        var wallsLost = 0
        var hearthLost = 0.0
        var buildings = 0
        var survived = 0

        init(_ runs: [[NightOutcome]], from first: Int = 1) {
            for run in runs {
                for night in run where night.night >= first {
                    taxes += night.taxes
                    happiness += night.happiness
                    killed += night.killed
                    fallen += night.fallen
                    wallsLost += night.wallsLost
                    hearthLost += 100 - night.hearthLowest
                    survived += night.survived ? 1 : 0
                }
                buildings += run.last?.buildings ?? 0
            }
        }
    }

    static let measuredNights = 14

    /// The nights of `bot` over the seeds, with the craftsman's work commissioned on the first day he can come (it
    /// stands from the dawn `days` later; its price is left out, so this is the most the effect can do).
    private func runs(_ craftsman: Craftsman?, bot: Autoplay, seeds: [UInt64]) -> [[NightOutcome]] {
        seeds.map { seed in
            var s = GameState.newRealm(seed: seed)
            if let c = craftsman {
                var craft = CraftState()
                craft.works = [CraftOrder(id: c.id, orderedDay: c.from, readyDay: c.from + c.days)]
                s.craft = craft
            }
            return TuningRun.play(s, bot: bot, balance: .standard, nights: Self.measuredNights).outcomes
        }
    }

    /// No effect moves its system by more than about 5 % (docs/TOWN.md section 4): each work, commissioned on the first
    /// day its craftsman can come, is measured against the same realm without it over 14 nights and two seeds, on the
    /// number its system makes over the nights it stands (the statue and the road lanterns: taxes; the portrait:
    /// happiness; the handcarts: buildings; the night's works: creatures stopped). The whole run is reported too.
    func testNoWorkMovesItsSystemMoreThanAboutFivePercent() {
        let seeds: [UInt64] = [1, 2]
        let normal = runs(nil, bot: .reference(), seeds: seeds)
        let high = runs(nil, bot: .reference(tax: .high), seeds: seeds)
        let n = Measure(normal)
        let h = Measure(high)
        var lines = ["base normal: taxes \(n.taxes) happiness \(n.happiness) killed \(n.killed) fallen \(n.fallen) "
                     + "walls \(n.wallsLost) buildings \(n.buildings)",
                     "base high: taxes \(h.taxes) happiness \(h.happiness) killed \(h.killed)"]
        func share(_ value: Int, _ base: Int) -> Double { base == 0 ? 0 : Double(value - base) / Double(base) }
        func pct(_ x: Double) -> String { String(Int((x * 1000).rounded())) + "‰" }
        for c in book.craftsmen {
            let highTax = c.effect == .unrestLine
            let baseRuns = highTax ? high : normal
            let workRuns = runs(c, bot: highTax ? .reference(tax: .high) : .reference(), seeds: seeds)
            let ready = c.from + c.days
            let base = Measure(baseRuns, from: ready)
            let with = Measure(workRuns, from: ready)
            let wholeBase = Measure(baseRuns)
            let whole = Measure(workRuns)
            let system: String
            let moved: Double
            let movedWhole: Double
            var countTolerance = 0.0
            switch c.effect {
            case .houseCoin, .unrestLine:
                system = "taxes"
                moved = share(with.taxes, base.taxes)
                movedWhole = share(whole.taxes, wholeBase.taxes)
            case .happinessOnce:
                system = "happiness"
                moved = share(with.happiness, base.happiness)
                movedWhole = share(whole.happiness, wholeBase.happiness)
            case .builderWalk:
                system = "buildings"
                moved = share(with.buildings, base.buildings)
                movedWhole = moved
                countTolerance = 1 / Double(max(1, base.buildings))
            case .soldierSpeed, .lightRadius, .patchShare, .guardHold, .fireArrowBurn, .gateStrength:
                system = "creatures stopped"
                moved = share(with.killed, base.killed)
                movedWhole = share(whole.killed, wholeBase.killed)
            }
            lines.append("\(c.id) (\(c.work), \(c.effect.rawValue) \(c.amount), stands from dawn \(ready)): \(system) "
                         + "\(pct(moved)) while it stands, \(pct(movedWhole)) over the run; taxes "
                         + "\(pct(share(with.taxes, base.taxes))) happiness \(pct(share(with.happiness, base.happiness))) "
                         + "killed \(pct(share(with.killed, base.killed))) fallen \(with.fallen)/\(base.fallen) walls "
                         + "\(with.wallsLost)/\(base.wallsLost) hearth lost \(Int(with.hearthLost))/\(Int(base.hearthLost)) "
                         + "buildings \(with.buildings)/\(base.buildings) nights held \(whole.survived)/\(wholeBase.survived)")
            XCTAssertLessThanOrEqual(abs(moved), max(0.06, countTolerance),
                                     "\(c.id) moves \(system) by \(pct(moved)) while it stands")
            XCTAssertGreaterThanOrEqual(whole.survived, wholeBase.survived, "\(c.id): a work never costs a night")
        }
        // Reported, not asserted: the night's works on harder nights (a bot that keeps four in five people at work, so
        // few soldiers), where walls fall, guards hold breaches and the king patches.
        var stress = Autoplay.reference()
        stress.soldierShare = 0.8
        let hard = runs(nil, bot: stress, seeds: seeds)
        let hb = Measure(hard)
        lines.append("hard nights (soldierShare 0.8), base: killed \(hb.killed) fallen \(hb.fallen) walls \(hb.wallsLost) "
                     + "hearth lost \(Int(hb.hearthLost)) nights held \(hb.survived)")
        for c in book.craftsmen where [.soldierSpeed, .lightRadius, .patchShare, .guardHold, .fireArrowBurn,
                                       .gateStrength].contains(c.effect) {
            let m = Measure(runs(c, bot: stress, seeds: seeds))
            lines.append("hard nights, \(c.id) (\(c.work)): killed \(pct(share(m.killed, hb.killed))) fallen "
                         + "\(m.fallen)/\(hb.fallen) walls \(m.wallsLost)/\(hb.wallsLost) hearth lost "
                         + "\(Int(m.hearthLost))/\(Int(hb.hearthLost)) nights held \(m.survived)/\(hb.survived)")
        }
        let attachment = XCTAttachment(string: lines.joined(separator: "\n"))
        attachment.name = "craft-effect-sizes"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
