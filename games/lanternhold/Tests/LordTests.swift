import Foundation
import XCTest
@testable import Lanternhold

/// The lord pass (DESIGN.md "The lord pass and the story pass"): the name's filter and limit, the placeholders
/// `{lord}` and `{a|b}`, the validator counting the longest name, the lord in the save (old saves read as the
/// Burgherr named Robin), the debug arguments, when a launch asks for the lord, and the benches' seated strips.
final class LordTests: XCTestCase {
    func testTheNameIsFilteredTrimmedAndCut() {
        XCTAssertEqual(LordIdentity.nameLimit, 16)
        XCTAssertEqual(LordIdentity.clean(""), "Robin", "nothing typed: the default name")
        XCTAssertEqual(LordIdentity.clean("   \n "), "Robin")
        XCTAssertEqual(LordIdentity.clean("1234 {}|%@"), "Robin", "nothing drawable left")
        XCTAssertEqual(LordIdentity.clean("Mira"), "Mira")
        XCTAssertEqual(LordIdentity.clean("  Anna-Lena  "), "Anna-Lena")
        XCTAssertEqual(LordIdentity.clean("Ada   von  Berg"), "Ada von Berg", "single spaces")
        XCTAssertEqual(LordIdentity.clean("O'Neil"), "O'Neil")
        XCTAssertEqual(LordIdentity.clean("M1r4{lord}|%@"), "Mrlord", "letters only: no brace, bar or format sign")
        XCTAssertEqual(LordIdentity.clean("Maximiliane Theodora"), "Maximiliane Theo", "cut at the limit")
        XCTAssertEqual(LordIdentity.clean("Wilhelmina Anne Marie"), "Wilhelmina Anne", "no space left at the cut")
        XCTAssertEqual(LordIdentity.clean("ひかり"), "ひかり", "letters of any script")
        XCTAssertEqual(LordIdentity.clean("Zoë Müller"), "Zoë Müller")
        XCTAssertEqual(LordIdentity.clean("-'Ed"), "Ed", "no mark before the first letter")
        XCTAssertEqual(LordIdentity.typed("Anna "), "Anna ", "while typing a second word may follow")
        XCTAssertEqual(LordIdentity.typed(""), "", "an empty field stays empty")
        XCTAssertEqual(LordIdentity.typed("Anna9"), "Anna")
        for raw in ["Mira", "  x  ", "", "Maximiliane Theodora von und zu", "a{b|c}"] {
            let name = LordIdentity.clean(raw)
            XCTAssertFalse(name.isEmpty)
            XCTAssertLessThanOrEqual(name.count, LordIdentity.nameLimit)
            XCTAssertEqual(LordIdentity.clean(name), name, "cleaning twice changes nothing")
            XCTAssertEqual(LordText.problems(name), [], "a name never carries a placeholder's brace")
        }
        XCTAssertEqual(LordIdentity(name: " 7 ", form: .lady), LordIdentity(name: "Robin", form: .lady))
        XCTAssertEqual(LordIdentity.standard, LordIdentity(name: "Robin", form: .lord))
    }

    func testThePlaceholdersTakeTheNameAndTheForm() {
        let mira = LordIdentity(name: "Mira", form: .lady)
        let text = "Welcome, {lord}. Sit, {my lord|my lady}."
        XCTAssertEqual(LordText.resolve(text, lord: mira), "Welcome, Mira. Sit, my lady.")
        XCTAssertEqual(LordText.resolve(text, lord: .standard), "Welcome, Robin. Sit, my lord.")
        XCTAssertEqual(LordText.resolve("{Der Burgherr|Die Burgherrin} {lord} von Haus Lantern", lord: mira),
                       "Die Burgherrin Mira von Haus Lantern")
        XCTAssertEqual(LordText.resolve("No braces here.", lord: mira), "No braces here.")
        XCTAssertEqual(LordText.resolve("{Lord|Lady} {lord}{|, at last}", lord: mira), "Lady Mira, at last")
        XCTAssertEqual(LordText.resolve("{Lord|Lady} {lord}{|, at last}", lord: .standard), "Lord Robin")
        XCTAssertTrue(LordText.usesLord(text))
        XCTAssertFalse(LordText.usesLord("No braces here."))

        XCTAssertEqual(LordText.longest("{lord}"), LordIdentity.nameLimit)
        XCTAssertEqual(LordText.longest("a {Herr|Herrin} b"), 10, "the longer half")
        XCTAssertEqual(LordText.longest("plain"), 5)
        XCTAssertEqual(LordText.longest(text), text.count - 6 + 16 - 17 + 7)
        let longName = LordIdentity(name: String(repeating: "W", count: 40), form: .lady)
        XCTAssertEqual(longName.name.count, LordIdentity.nameLimit)
        XCTAssertLessThanOrEqual(LordText.resolve(text, lord: longName).count, LordText.longest(text),
                                 "no lord makes a text longer than the validator counted")

        XCTAssertEqual(LordText.problems(text), [])
        XCTAssertEqual(LordText.problems("Hello {name}."), ["{name}"])
        XCTAssertEqual(LordText.problems("{a|b|c}"), ["{a|b|c}"])
        XCTAssertEqual(LordText.problems("a } b"), ["}"])
        XCTAssertEqual(LordText.problems("open {lord"), ["{lord"])
        XCTAssertEqual(LordText.resolve("Hello {name}.", lord: mira), "Hello {name}.", "shown as written")
    }

    func testTheValidatorCountsTheLongestNameAndReportsBrokenBraces() {
        var table = StoryTable()
        let limit = CourtValidator.choiceLimit
        table.english["fits"] = String(repeating: "x", count: limit.english - 16) + "{lord}"
        table.german["fits"] = String(repeating: "x", count: limit.german - 6) + "{Herr|Herrin}"
        XCTAssertEqual(CourtValidator.text("fits", limit: limit, what: "t", table: table), [])
        table.english["long"] = String(repeating: "x", count: limit.english - 15) + "{lord}"
        table.german["long"] = String(repeating: "x", count: limit.german - 5) + "{Herr|Herrin}"
        XCTAssertEqual(CourtValidator.text("long", limit: limit, what: "t", table: table), [
            "t: long is \(limit.english + 1) characters in English (at most \(limit.english))",
            "t: long is \(limit.german + 1) characters in German (at most \(limit.german))",
        ], "a text that fits only a short name is too long")
        table.english["broken"] = "Hello {name}"
        table.german["broken"] = "Hallo {lord}"
        let problems = CourtValidator.text("broken", limit: limit, what: "t", table: table)
        XCTAssertEqual(problems.count, 1)
        XCTAssertTrue(problems.first?.contains("neither {lord} nor {a|b} in English: {name}") == true, "\(problems)")
        XCTAssertEqual(CourtValidator.text("missing", limit: limit, what: "t", table: table),
                       ["t: missing has no English text", "t: missing has no German text"])
    }

    func testTheSaveKeepsTheLordAndOldSavesReadAsTheBurgherr() throws {
        var state = GameState.newRealm(seed: 7)
        XCTAssertNil(state.lord, "a new realm has no lord until the name entry")
        XCTAssertEqual(state.lordOrDefault, .standard)
        let plain = String(decoding: try SaveGame(state: state).encoded(), as: UTF8.self)
        XCTAssertFalse(plain.contains("\"lord\""), "no lord: the field is left out, as in a save from before it")
        state.lord = LordIdentity(name: "Mira", form: .lady)
        let data = try SaveGame(state: state).encoded()
        guard case .loaded(let back) = SaveGame.decode(data) else { return XCTFail("the save does not load") }
        XCTAssertEqual(back.state.lord, LordIdentity(name: "Mira", form: .lady))
        XCTAssertTrue(back.state == state)

        guard case .loaded(let old) = SaveGame.decode(Data(SaveFixtures.versionOne.utf8)) else {
            return XCTFail("the version 1 save does not load")
        }
        XCTAssertNil(old.state.lord)
        XCTAssertEqual(old.state.lordOrDefault, LordIdentity(name: "Robin", form: .lord))

        let decoder = JSONDecoder()
        func lord(_ json: String) throws -> LordIdentity {
            try decoder.decode(LordIdentity.self, from: Data(json.utf8))
        }
        XCTAssertEqual(try lord(#"{"name": "Mira", "form": "lady"}"#), LordIdentity(name: "Mira", form: .lady))
        XCTAssertEqual(try lord(#"{"name": "Mira", "form": "duke"}"#), LordIdentity(name: "Mira", form: .lord))
        XCTAssertEqual(try lord(#"{"form": "lady"}"#), LordIdentity(name: "Robin", form: .lady))
        XCTAssertEqual(try lord(#"{"name": "M{1}ra", "futureField": 3}"#), LordIdentity(name: "Mra", form: .lord))
    }

    func testTheDebugArgumentsNameTheLord() {
        XCTAssertNil(DebugArgs(values: [:]).lordIdentity)
        XCTAssertNil(DebugArgs(values: ["GWLord": "queen"]).lordIdentity)
        XCTAssertEqual(DebugArgs(values: ["GWLord": "lady"]).lordIdentity, LordIdentity(name: "Robin", form: .lady))
        XCTAssertEqual(DebugArgs(values: ["GWLord": " Lady ", "GWLordName": "Mira"]).lordIdentity,
                       LordIdentity(name: "Mira", form: .lady))
        XCTAssertEqual(DebugArgs(values: ["GWLordName": "Maximiliane Theodora"]).lordIdentity,
                       LordIdentity(name: "Maximiliane Theo", form: .lord))
        let realm = GameStart.realm(args: DebugArgs(values: ["GWLord": "lady", "GWLordName": "Mira"]), saved: nil)
        XCTAssertEqual(realm.state.lord, LordIdentity(name: "Mira", form: .lady))
        XCTAssertNil(GameStart.realm(args: DebugArgs(values: [:]), saved: nil).state.lord)
    }

    func testOnlyAFreshRealmAsksForTheLord() {
        let fresh = GameState.newRealm(seed: 1)
        XCTAssertTrue(LordEntry.asks(args: DebugArgs(values: [:]), state: fresh))
        XCTAssertTrue(LordEntry.asks(args: DebugArgs(values: ["GWReset": "YES", "GWSeed": "4"]), state: fresh))
        let quiet: [[String: String]] = [
            ["GWSkipOnboarding": "YES"], ["GWLord": "lady"], ["GWLordName": "Mira"], ["GWAutoplay": "play"],
            ["GWScreen": "report"], ["GWDay": "3"], ["GWNight": "2"], ["GWHour": "12"],
        ]
        for values in quiet {
            XCTAssertFalse(LordEntry.asks(args: DebugArgs(values: values), state: fresh), "\(values)")
        }
        var named = fresh
        named.lord = .standard
        XCTAssertFalse(LordEntry.asks(args: DebugArgs(values: [:]), state: named), "the lord is chosen")
        var later = fresh
        later.day = 2
        later.dawns = 1
        XCTAssertFalse(LordEntry.asks(args: DebugArgs(values: [:]), state: later), "an old save in mid-chapter")
    }

    func testWaitingTownsfolkSitOnTheBenches() {
        XCTAssertEqual(CourtLayout.seatedStrip(.citizen), .citizenSeated)
        XCTAssertEqual(CourtLayout.seatedStrip(.citizenB), .citizenBSeated)
        XCTAssertEqual(CourtLayout.seatedStrip(.citizenC), .citizenCSeated)
        XCTAssertNil(CourtLayout.seatedStrip(.petitionerD), "no seated strip: she stands at the bench")
        XCTAssertNil(CourtLayout.seatedStrip(.guardsman))
        // Each bench seats two, the nearer bench to the throne first.
        XCTAssertEqual(CourtLayout.seats, [CourtLayout.benches[1] + 24, CourtLayout.benches[1] + 8,
                                           CourtLayout.benches[0] + 24, CourtLayout.benches[0] + 8])
        let speakers = [("ask", "farmer"), ("well", "townswoman"), ("road", "refugee"), ("loss", "widow"),
                        ("kin", "farmwife")]
        let catalog = PetitionTests.catalog(speakers.map { id, speaker in
            """
            {"id": "\(id)", "speaker": "\(speaker)", "kind": "random", "text": "t",
             "choices": [{"label": "a"}, {"label": "b"}]}
            """
        }.joined(separator: ","))
        var queue: [Petitioner] = []
        for (index, id) in ["ask", "well", "road", "loss", "kin"].enumerated() {
            queue.append(Petitioner(id: id, reason: .random, look: index * 7))
        }
        let waiting = CourtLayout.figures(day: 5, hour: 9, flags: [], queue: queue, catalog: catalog)
            .filter { $0.petition != nil }
        XCTAssertEqual(waiting.map(\.seated), [.citizenCSeated, nil, .citizenBSeated, .citizenSeated, nil])
        XCTAssertEqual(Array(waiting.prefix(4)).map(\.x), CourtLayout.seats)
        XCTAssertFalse(CourtLayout.seats.contains(waiting[4].x), "the fifth stands behind, so she is not seated")

        var s = GameState.newRealm(seed: 3)
        s.day = 5
        s.hour = 9
        s.court = CourtState()
        s.court?.queue = queue
        s.court?.queueDay = 5
        let scene = CourtScene(rooms: RoomFades(kingX: 1800))
        let drawn = CourtFrames.figures(state: s, catalog: catalog, scene: scene, animTime: 2)
        let farmer = drawn.first { $0.petition == "ask" }
        XCTAssertEqual(farmer?.seated, .citizenCSeated)
        XCTAssertEqual(farmer?.sprite, .citizenCSeated)
        XCTAssertEqual(farmer?.frame, CourtFrames.seatedFrame(animTime: 2, key: "p:ask"))
        XCTAssertEqual(drawn.first { $0.petition == "well" }?.sprite, .petitionerD, "the townswoman stands")
        // Whoever still walks to his place stands.
        var walking = scene
        walking.drawn["p:ask"] = CourtLayout.seats[0] - 20
        let onTheWay = CourtFrames.figures(state: s, catalog: catalog, scene: walking, animTime: 2)
        XCTAssertNil(onTheWay.first { $0.petition == "ask" }?.seated)
        XCTAssertEqual(onTheWay.first { $0.petition == "ask" }?.sprite, .citizenC)
        // The nod comes now and then: frame 1 for half a second every six.
        var frames = Set<Int>()
        for step in 0..<140 { frames.insert(CourtFrames.seatedFrame(animTime: Double(step) * 0.1, key: "p:ask")) }
        XCTAssertEqual(frames, [0, 1])
        XCTAssertEqual(CourtFrames.seatedFrame(animTime: 0, key: "p:ask"), 0)
    }

    func testTheLordsSpritesAndTheSittingDown() {
        let lord = LordIdentity.standard
        let lady = LordIdentity(name: "Mira", form: .lady)
        XCTAssertEqual([lord.body, lord.glow, lord.seated, lord.seatedGlow, lord.portrait],
                       [.king, .kingGlow, .kingSeated, .kingSeatedGlow, .portraitKing])
        XCTAssertEqual([lady.body, lady.glow, lady.seated, lady.seatedGlow, lady.portrait],
                       [.lady, .ladyGlow, .ladySeated, .ladySeatedGlow, .portraitLady])
        for sprite in [SpriteID.king, .lady, .kingSeated, .ladySeated] { XCTAssertTrue(sprite.isLord) }
        for sprite in [SpriteID.kingGlow, .ladyGlow, .citizen, .odile] { XCTAssertFalse(sprite.isLord) }
        // The seated strips keep the walking strips' frame size, so the lord stays where he stood.
        XCTAssertEqual(SpriteID.kingSeated.size.width, SpriteID.king.size.width)
        XCTAssertEqual(SpriteID.kingSeated.size.height, SpriteID.king.size.height)
        XCTAssertEqual(SpriteID.ladySeated.size.width, SpriteID.lady.size.width)
        XCTAssertEqual(SpriteID.lady.size.width, SpriteID.king.size.width)
        XCTAssertEqual(CourtFrames.lordSeatedFrame(seconds: 0, animTime: 0), 0, "sitting down")
        XCTAssertEqual(CourtFrames.lordSeatedFrame(seconds: CourtFrames.sitSeconds * 0.75, animTime: 0), 1)
        XCTAssertEqual(CourtFrames.lordSeatedFrame(seconds: CourtFrames.sitSeconds, animTime: 0), 2, "seated")
        XCTAssertEqual(CourtFrames.lordSeatedFrame(seconds: 5, animTime: CourtFrames.breathSeconds), 3, "breathing")
        XCTAssertEqual(CourtFrames.lordSeatedFrame(seconds: nil, animTime: 0), 2, "Reduce Motion: seated at once")
    }
}

/// The name entry and the lord in the game (the lord pass): a new realm opens on the entry and keeps the answer in
/// the save, a restart asks again with the old lord, the lord sits on the throne during an audience and the Burgherrin
/// walks in her own sprites.
@MainActor
final class LordEntryTests: XCTestCase {
    private var directory: URL!

    override func setUp() async throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("lanternhold-tests-\(UUID().uuidString)", isDirectory: true)
    }

    override func tearDown() async throws {
        if let directory { try? FileManager.default.removeItem(at: directory) }
    }

    private func model(_ values: [String: String]) -> GameModel {
        GameModel(args: DebugArgs(values: values), kind: .world, store: SaveStore(directory: directory))
    }

    private func savedLord() -> LordIdentity? {
        guard case .loaded(let save)? = SaveStore(directory: directory).read() else { return nil }
        return save.state.lord
    }

    private func sprites(_ game: GameModel) -> [SpriteID] {
        game.frame(physicalWidth: 2622, physicalHeight: 1206).actors.map(\.sprite)
    }

    func testANewRealmAsksForTheLordAndKeepsTheAnswer() throws {
        let game = model(["GWReset": "YES"])
        XCTAssertEqual(game.overlay, .lordEntry, "a new realm opens on the name entry")
        XCTAssertTrue(game.isPaused, "nothing steps behind it")
        XCTAssertNil(game.lordDraft, "an empty field, the Burgherr marked")
        XCTAssertEqual(game.lord, .standard)
        let hour = game.driver?.state.hour
        for _ in 0..<8 { game.advance(by: 0.25) }
        XCTAssertEqual(game.driver?.state.hour, hour)
        game.pauseForBackground()
        XCTAssertEqual(game.overlay, .lordEntry, "the background leaves the entry open")

        game.confirmLord(name: "  Mira 2 ", form: .lady)
        XCTAssertNil(game.overlay, "the day starts")
        XCTAssertFalse(game.isPaused)
        XCTAssertEqual(game.lord, LordIdentity(name: "Mira", form: .lady))
        XCTAssertEqual(game.driver?.dawnSnapshot.lord, game.lord, "a replayed day keeps the lord")
        XCTAssertEqual(savedLord(), game.lord, "written at once")
        game.advance(by: 0.1)
        XCTAssertEqual(game.target, .throne, "day 1 as before: the farmer waits at the throne")
        game.confirmLord(name: "Other", form: .lord)
        XCTAssertEqual(game.lord.name, "Mira", "only the entry sets the lord")

        // The next launch loads the realm with its lord and asks nothing.
        let again = model([:])
        XCTAssertNil(again.overlay)
        XCTAssertEqual(again.lord, LordIdentity(name: "Mira", form: .lady))
        XCTAssertTrue(sprites(again).contains(.lady), "the Burgherrin walks in her own sprites")
        XCTAssertFalse(sprites(again).contains(.king))
    }

    func testAnEmptyNameIsRobinAndQuittingBeforeTheAnswerAsksAgain() throws {
        let first = model(["GWReset": "YES"])
        XCTAssertEqual(first.overlay, .lordEntry)
        first.saveNow()
        let second = model([:])
        XCTAssertEqual(second.overlay, .lordEntry, "no answer yet: the entry comes again")
        second.confirmLord(name: "", form: .lord)
        XCTAssertEqual(second.lord, LordIdentity(name: "Robin", form: .lord))
        XCTAssertEqual(savedLord(), .standard)
        XCTAssertTrue(sprites(second).contains(.king))
        XCTAssertFalse(sprites(second).contains(.lady))
    }

    func testARestartAsksAgainWithTheOldLord() throws {
        let game = model(["GWReset": "YES"])
        game.confirmLord(name: "Mira", form: .lady)
        game.openPause()
        game.restartChapter()
        XCTAssertEqual(game.overlay, .lordEntry, "a new realm asks who holds it")
        XCTAssertEqual(game.lordDraft, LordIdentity(name: "Mira", form: .lady), "the old lord stands in the entry")
        XCTAssertEqual(game.day, 1)
        game.confirmLord(name: "Ada", form: .lord)
        XCTAssertNil(game.overlay)
        XCTAssertEqual(game.lord, LordIdentity(name: "Ada", form: .lord))
        XCTAssertEqual(savedLord(), game.lord)
    }

    func testTheLordSitsOnTheThroneDuringAnAudience() throws {
        let game = model(["GWReset": "YES", "GWSkipOnboarding": "YES", "GWLord": "lady", "GWLordName": "Mira"])
        XCTAssertNil(game.overlay, "the arguments name the lord: no entry")
        XCTAssertTrue(sprites(game).contains(.lady))
        XCTAssertTrue(sprites(game).contains(.citizenCSeated), "the farmer waits seated on the bench")
        game.performAction()
        XCTAssertEqual(game.overlay, .audience)
        XCTAssertEqual(game.driver?.state.king.x, WorldLayout.throneX, "on the throne in the dais's middle")
        XCTAssertEqual(game.court.lordSeated, 0, "sitting down")
        var frame = game.frame(physicalWidth: 2622, physicalHeight: 1206)
        XCTAssertEqual(frame.actors.first { $0.sprite == .ladySeated }?.frame, 0)
        XCTAssertFalse(frame.actors.contains { $0.sprite == .lady }, "the seated strip stands in for the walking one")
        XCTAssertTrue(frame.actors.contains { $0.sprite == .citizenC }, "the farmer got up and walks to the throne")
        XCTAssertFalse(frame.actors.contains { $0.sprite == .citizenCSeated })
        for _ in 0..<16 { game.advance(by: 0.1) }
        frame = game.frame(physicalWidth: 2622, physicalHeight: 1206)
        let seated = try XCTUnwrap(frame.actors.first { $0.sprite == .ladySeated })
        XCTAssertTrue((2...3).contains(seated.frame), "seated and breathing")
        XCTAssertTrue(seated.flipped, "turned to the petitioner")
        game.standUp()
        XCTAssertNil(game.court.lordSeated)
        XCTAssertTrue(sprites(game).contains(.lady), "she stands again")
        XCTAssertFalse(sprites(game).contains(.ladySeated))

        let still = model(["GWReset": "YES", "GWSkipOnboarding": "YES", "GWReduceMotion": "YES"])
        still.performAction()
        XCTAssertNil(still.court.lordSeated, "Reduce Motion: seated at once")
        let king = try XCTUnwrap(still.frame(physicalWidth: 2622, physicalHeight: 1206).actors
            .first { $0.sprite == .kingSeated })
        XCTAssertTrue((2...3).contains(king.frame))
    }

    func testTheStoryTextsTakeTheLord() throws {
        let game = model(["GWReset": "YES", "GWSkipOnboarding": "YES", "GWLord": "lady", "GWLordName": "Mira"])
        let keys = CourtValidator.keys(petitions: .standard, lines: .standard)
        var named = 0
        var turned = 0
        for key in keys {
            let shown = game.story(key)
            XCTAssertFalse(shown.contains("{") || shown.contains("}"), "\(key): \(shown)")
            for language in ["en", "de"] {
                guard let raw = StoryText.string(key, language: language) else { continue }
                if raw.contains("{lord}") { named += 1 }
                if LordText.usesLord(raw.replacingOccurrences(of: "{lord}", with: "")) { turned += 1 }
                let lady = LordText.resolve(raw, lord: game.lord)
                let lord = LordText.resolve(raw, lord: .standard)
                XCTAssertFalse(lady.contains("{") || lord.contains("{"), "\(key) in \(language)")
            }
        }
        XCTAssertGreaterThan(named, 0, "the story names the lord somewhere (STORY.md, decision 3)")
        XCTAssertGreaterThan(turned, 0, "and turns on Burgherr and Burgherrin")
    }
}
