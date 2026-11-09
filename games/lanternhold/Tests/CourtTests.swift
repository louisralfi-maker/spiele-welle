import Foundation
import XCTest
@testable import Lanternhold

/// The court's state (M3, DESIGN.md "M3 in detail"): every court member in his room by day and gathered at night,
/// Seren following the story, guests and petitioners waiting at the benches, positions as a pure function, the court
/// lines preferring a hint about today's petitions, the props, the world registry, the composed portrait, the driver
/// drawing each day's petitioners, and the save keeping the court while old saves still load.
final class CourtTests: XCTestCase {
    private static let sample = PetitionTests.catalog("""
    {"id": "well", "speaker": "townswoman", "kind": "random", "text": "t", "choices": [{"label": "a"}, {"label": "b"}]},
    {"id": "ask", "speaker": "farmer", "kind": "random", "text": "t", "choices": [{"label": "a"}, {"label": "b"}]},
    {"id": "trade", "speaker": "merchant", "kind": "random", "text": "t", "choices": [{"label": "a"}, {"label": "b"}]},
    {"id": "knight", "speaker": "serLudo", "kind": "random", "text": "t", "choices": [{"label": "a"}, {"label": "b"}]},
    {"id": "deal", "speaker": "marek", "kind": "random", "text": "t", "choices": [{"label": "a"}, {"label": "b"}]},
    {"id": "stranger", "speaker": "seren", "kind": "story", "days": [4, 5], "text": "t",
     "choices": [{"label": "a"}, {"label": "b"}]},
    {"id": "widow", "speaker": "widow", "kind": "random", "text": "t", "choices": [{"label": "a"}, {"label": "b"}]},
    {"id": "kid", "speaker": "child", "kind": "random", "text": "t", "choices": [{"label": "a"}, {"label": "b"}]}
    """)

    private func queue(_ ids: [String]) -> [Petitioner] {
        var list: [Petitioner] = []
        for (index, id) in ids.enumerated() { list.append(Petitioner(id: id, reason: .random, look: index * 7)) }
        return list
    }

    /// A court member at his round (not a waiting petitioner).
    private func member(_ list: [CourtFigure], _ who: String) -> CourtFigure? {
        list.first { $0.who == who && $0.petition == nil }
    }

    func testByDayEveryCourtMemberIsInHisRoom() {
        for hour in stride(from: 6.0, to: 19.0, by: 0.37) {
            let list = CourtLayout.figures(day: 2, hour: hour, flags: [], queue: [], catalog: Self.sample)
            XCTAssertEqual(member(list, "odile")?.room, .greatHall, "Odile by the throne at \(hour)")
            let brannock = member(list, "brannock")?.x ?? 0
            XCTAssertTrue((1420.0...1480.0).contains(brannock), "Brannock between the courtyard and the gatehouse")
            let pip = member(list, "pip")?.room
            XCTAssertTrue(pip == .courtyard || pip == .greatHall, "Pip wanders the courtyard and the hall")
            XCTAssertEqual(member(list, "hesper")?.room, .chapel)
            XCTAssertEqual(member(list, "tamsin")?.room, .kitchen)
            XCTAssertTrue((1546.0...1606.0).contains(member(list, "bram")?.x ?? 0), "Bram at the smithy")
            XCTAssertNil(member(list, "marek"), "day 2 is not one of Marek's days")
            XCTAssertNil(member(list, "seren"), "not let in")
        }
        let marekDay = CourtLayout.figures(day: 3, hour: 10, flags: [], queue: [], catalog: Self.sample)
        XCTAssertEqual(member(marekDay, "marek")?.room, .courtyard, "every third day")
        let brings = CourtLayout.figures(day: 4, hour: 10, flags: [], queue: queue(["deal"]), catalog: Self.sample)
        XCTAssertNotNil(member(brings, "marek"), "and the day he brings a petition")
    }

    func testAtNightTheCourtGathersAndTheGuestsAreGone() {
        let list = CourtLayout.figures(day: 3, hour: 23, flags: [], queue: queue(["well", "knight"]),
                                       catalog: Self.sample)
        XCTAssertEqual(list.map(\.who), ["odile", "brannock", "pip", "hesper", "tamsin", "bram"],
                       "no Marek, no guests, no petitioners")
        XCTAssertEqual(member(list, "hesper")?.room, .greatHall, "she keeps the hearth at night")
        XCTAssertTrue(list.allSatisfy { $0.pose == .idle })
        let late = CourtLayout.figures(day: 3, hour: 4.5, flags: [CourtLayout.serenInFlag], queue: [],
                                       catalog: Self.sample)
        XCTAssertEqual(member(late, "seren")?.x, CourtLayout.serenCorner)
    }

    func testSerenFollowsTheStory() {
        let waiting = CourtLayout.figures(day: 4, hour: 17, flags: [], queue: queue(["stranger"]), catalog: Self.sample)
        let atGate = waiting.first { $0.who == "seren" }
        XCTAssertEqual(atGate?.x, CourtLayout.strangerAtGate, "she waits at the front gate")
        XCTAssertEqual(atGate?.petition, "stranger")
        XCTAssertEqual(atGate?.facing, 1)
        let inside = CourtLayout.figures(day: 6, hour: 11, flags: ["stranger_in"], queue: [], catalog: Self.sample)
        XCTAssertEqual(inside.first { $0.who == "seren" }?.room, .greatHall)
        XCTAssertEqual(inside.first { $0.who == "seren" }?.glow, .serenGlow, "her grey lantern glows")
        let gone = CourtLayout.figures(day: 18, hour: 11, flags: ["stranger_in", "seren_handed_over"], queue: [],
                                       catalog: Self.sample)
        XCTAssertNil(gone.first { $0.who == "seren" })
    }

    func testTodaysPetitionersWaitAtTheBenches() {
        let ids = ["well", "knight", "ask", "trade", "widow", "kid"]
        let list = CourtLayout.figures(day: 5, hour: 9, flags: [], queue: queue(ids), catalog: Self.sample)
        let waiting = list.filter { $0.petition != nil }
        XCTAssertEqual(waiting.compactMap(\.petition), ids, "in the order they walk up")
        XCTAssertEqual(waiting.first?.x, CourtLayout.seats[0], "the next one nearest the throne")
        let folk = waiting.filter { $0.who != "serLudo" }
        XCTAssertEqual(Array(folk.prefix(4)).map(\.x), CourtLayout.seats)
        XCTAssertEqual(waiting.first { $0.who == "serLudo" }?.x, CourtLayout.standing[0], "the guest stands")
        XCTAssertEqual(folk.last?.x, CourtLayout.standing[1], "a fifth townsperson stands behind")
        XCTAssertTrue(waiting.allSatisfy { $0.facing == 1 && $0.room == .greatHall && $0.pose == .idle })
        XCTAssertEqual(waiting.first { $0.petition == "trade" }?.sprite, .petitionerE)
        XCTAssertEqual(waiting.first { $0.petition == "kid" }?.look, 35)
    }

    func testPositionsAreAPureFunctionAndTheRoundsMove() {
        let waiting = queue(["well", "knight", "ask"])
        for hour in stride(from: 0.0, to: 24.0, by: 0.53) {
            let a = CourtLayout.figures(day: 6, hour: hour, flags: ["stranger_in"], queue: waiting, catalog: Self.sample)
            let b = CourtLayout.figures(day: 6, hour: hour, flags: ["stranger_in"], queue: waiting, catalog: Self.sample)
            XCTAssertEqual(a, b)
            for figure in a {
                XCTAssertTrue((0..<figure.sprite.frameCount).contains(figure.frame), "\(figure.who) frame \(figure.frame)")
                XCTAssertTrue(figure.facing == 1 || figure.facing == -1)
            }
        }
        var spots = Set<Int>()
        var walked = false
        for step in 0..<400 {
            let hour = 6 + Double(step) * 13 / 400
            let list = CourtLayout.figures(day: 2, hour: hour, flags: [], queue: [], catalog: Self.sample)
            if let odile = member(list, "odile") { spots.insert(Int(odile.x)) }
            if list.contains(where: { $0.pose == .walk }) { walked = true }
        }
        XCTAssertGreaterThan(spots.count, 3, "Odile steps to the lectern and back")
        XCTAssertTrue(walked)
    }

    func testCourtLinesPreferAHintAboutTodaysPetitions() {
        let lines = CourtLineBook([
            CourtLine(id: "tamsin_gossip", speaker: "tamsin", text: "a"),
            CourtLine(id: "tamsin_bread", speaker: "tamsin", weight: 3, text: "b"),
            CourtLine(id: "tamsin_well", speaker: "tamsin", text: "c", about: "well"),
            CourtLine(id: "tamsin_day1", speaker: "tamsin", days: [1, 1], text: "d"),
            CourtLine(id: "tamsin_grudge", speaker: "tamsin", requires: ["grudge"], text: "e"),
        ])
        var s = GameState.newRealm(seed: 5)
        s.day = 3
        s.hour = 9
        XCTAssertFalse(lines.lines(for: "tamsin", state: s).contains { $0.id == "tamsin_well" },
                       "a hint only while its petition waits")
        XCTAssertFalse(lines.hasHint(for: "tamsin", state: s))
        var court = CourtState()
        court.queueDay = 3
        court.queue = [Petitioner(id: "well", reason: .random, look: 0)]
        s.court = court
        XCTAssertEqual(lines.line(for: "tamsin", state: s)?.id, "tamsin_well", "the hint first")
        XCTAssertTrue(lines.hasHint(for: "tamsin", state: s))
        let order = lines.lines(for: "tamsin", state: s).map(\.id)
        XCTAssertEqual(Set(order), ["tamsin_well", "tamsin_gossip", "tamsin_bread"], "not day 1's, not without the flag")
        XCTAssertEqual(lines.line(for: "tamsin", state: s, nth: 3)?.id, order[0], "talking on goes round")
        XCTAssertEqual(lines.lines(for: "tamsin", state: s).map(\.id), order, "the same day, the same order")
        XCTAssertNil(lines.line(for: "bram", state: s))
        var bread = 0
        var gossip = 0
        for day in 2...401 {
            s.day = day
            s.court?.queueDay = day
            switch lines.lines(for: "tamsin", state: s).first(where: { $0.about == nil })?.id {
            case "tamsin_bread"?: bread += 1
            case "tamsin_gossip"?: gossip += 1
            default: break
            }
        }
        XCTAssertGreaterThan(bread, 2 * gossip, "weight 3 against 1: \(bread) to \(gossip)")
    }

    func testTheCourtsProps() {
        let base = CourtLayout.props(day: 2, hour: 10, world: [], queue: [], catalog: Self.sample)
        XCTAssertEqual(base.map(\.sprite), [.bench, .bench, .taxLectern])
        let marekDay = CourtLayout.props(day: 3, hour: 10, world: [], queue: [], catalog: Self.sample)
        XCTAssertTrue(marekDay.contains(CourtProp(sprite: .marekCart, x: CourtLayout.marekCartX)))
        XCTAssertFalse(CourtLayout.props(day: 3, hour: 22, world: [], queue: [], catalog: Self.sample)
            .contains { $0.sprite == .marekCart }, "the cart is gone at night")
        let built = CourtLayout.props(day: 2, hour: 22, world: ["castle.statue", "castle.courtyard.stall"], queue: [],
                                      catalog: Self.sample)
        XCTAssertTrue(built.contains { $0.sprite == .statue })
        XCTAssertTrue(built.contains { $0.sprite == .marekCart })
    }

    func testTheWorldRegistry() {
        let ids = CourtWorld.registry.map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count, "every id once")
        XCTAssertTrue(CourtWorld.isRegistered("town.well.repaired"))
        XCTAssertTrue(CourtWorld.isRegistered("-castle.statue"))
        XCTAssertFalse(CourtWorld.isRegistered("castle.moat"))
        XCTAssertTrue(CourtWorld.registry.contains { $0.place == .castle && $0.drawnIn == "M3" })
        XCTAssertTrue(CourtWorld.registry.contains { $0.place == .town && $0.drawnIn == "M4" })
        for change in CourtWorld.registry {
            switch change.place {
            case .castle: XCTAssertTrue((1240.0...2430.0).contains(change.x), change.id)
            case .town: XCTAssertTrue((2430.0...3680.0).contains(change.x), change.id)
            }
        }
    }

    func testAComposedPortraitWearsTheTargetRamps() {
        let recipe = PortraitRecipe(clothes: PortraitPart.tunic, face: PortraitPart.round, beard: PortraitPart.fullBeard,
                                    hair: PortraitPart.shortHair, hat: PortraitPart.noHat, skin: .deep, hairColor: .red,
                                    cloth: .teal, female: false)
        let image = PortraitComposer.compose(recipe) { PlaceholderCourt.part($0, frame: $1) }
        XCTAssertFalse(image.isEmpty)
        var colours = Set<RGBA>()
        for y in 0..<image.height {
            for x in 0..<image.width where image[x, y].a > 0 { colours.insert(image[x, y]) }
        }
        for hex in PortraitRamps.skin + PortraitRamps.hair + PortraitRamps.cloth {
            XCTAssertFalse(colours.contains(RGBA(hex)), String(hex, radix: 16) + ": no swap colour is left")
        }
        XCTAssertFalse(colours.isDisjoint(with: SkinTone.deep.ramp.map { RGBA($0) }), "the deep skin")
        XCTAssertFalse(colours.isDisjoint(with: HairTone.red.ramp.map { RGBA($0) }), "the red beard and hair")
        XCTAssertFalse(colours.isDisjoint(with: ClothTone.teal.ramp.map { RGBA($0) }), "the teal tunic")
        let parts: [SpriteID] = [.portraitClothes, .portraitFace, .portraitBeard, .portraitHair]
        if parts.allSatisfy({ AtlasLayout.shared.sources[$0] == .placeholder }) {
            XCTAssertEqual(PortraitComposer.compose(recipe, atlas: .shared), image, "the atlas cut gives the same picture")
        }
    }

    func testTheDriverDrawsEachDaysPetitioners() {
        let driver = SimDriver(state: GameState.newRealm(seed: 3), balance: .standard)
        XCTAssertEqual(driver.state.court?.queueDay, 1)
        XCTAssertEqual(driver.state.court?.queue.map(\.id), ["first_plough"], "the tutorial on day 1")
        XCTAssertEqual(driver.dawnSnapshot, driver.state, "the snapshot has today's petitioners too")
        let figures = CourtLayout.figures(driver.state, catalog: .standard)
        XCTAssertEqual(figures.first { $0.petition == "first_plough" }?.x, CourtLayout.seats[0],
                       "the farmer waits at the bench")
    }

    func testTheSaveKeepsTheCourtAndOldSavesStillLoad() throws {
        var s = GameState.newRealm(seed: 21)
        var court = CourtState()
        court.queueDay = 1
        court.queue = [Petitioner(id: "well_repair", reason: .random, look: 123_456),
                       Petitioner(id: "first_plough", reason: .story, look: 7)]
        court.history = [HeardPetition(id: "old_sergeant", day: 1, choice: 0),
                         HeardPetition(id: "crow_rags", day: 1, choice: nil)]
        court.heard = ["old_sergeant"]
        court.heardCount = 4
        court.scheduled = [ScheduledPetition(id: "well_dispute", day: 4)]
        court.world = ["town.well.repaired"]
        court.nightModifiers = [NightModifierEntry(night: 1, id: "crows-2")]
        court.unlocks = ["line3"]
        court.extraBuilders = 1
        s.court = court
        s.flags = ["plough_blessed", "stranger_in"]
        let data = try SaveGame(state: s).encoded()
        guard case .loaded(let back) = SaveGame.decode(data) else { return XCTFail("the save loads") }
        XCTAssertEqual(back.state.court, court)
        XCTAssertEqual(back.state.flags, s.flags)
        XCTAssertTrue(back.state == s)
        XCTAssertEqual(try back.encoded(), data, "the same bytes again")
        guard case .loaded(let frozen) = SaveGame.decode(Data(SaveFixtures.versionOne.utf8)) else {
            return XCTFail("the frozen version 1 save still loads")
        }
        XCTAssertNil(frozen.state.court)
        let empty = try JSONDecoder().decode(CourtState.self, from: Data("{}".utf8))
        XCTAssertEqual(empty, CourtState(), "every field has a default")
        let partial = try JSONDecoder().decode(CourtState.self,
                                               from: Data("{\"queueDay\": 3, \"world\": [\"castle.statue\"]}".utf8))
        XCTAssertEqual(partial.queueDay, 3)
        XCTAssertEqual(partial.world, ["castle.statue"])
        XCTAssertEqual(partial.extraBuilders, 0)
    }
}
