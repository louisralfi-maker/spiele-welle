import CoreGraphics
import Foundation
import XCTest
@testable import Lanternhold

/// Touch the world (stage lane, step stage-2; DESIGN.md "Controls 2: touch the world", docs/REVIEW-look-2.md B3, M6,
/// M11, M13): the pure rules (every touch area at least 44 x 44 pt at every scale, the nearer centre wins, a tie goes by
/// rank, a person before a wall wins, a bench is one target, 10 pt or less is a tap, at most four marks nearest first,
/// the marks at night, the pace), what offers something on each stage, and the errands through the game's model: a tap
/// on a site opens its card when he arrives, a tap on the throne holds the audience, a tap on the hall's door changes
/// the stage, a tap on the ground walks him there, a drag calls him off, a second tap makes him run.
@MainActor
final class TouchWorldTests: XCTestCase {
    private var directory: URL!
    /// The runner's iPhone 17 Pro: 2622 x 1206 device px, 3 per point.
    private let pro = PixelScale(physicalWidth: 2622, physicalHeight: 1206)
    private let proPoints = CGSize(width: 874, height: 402)

    override func setUp() async throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("lanternhold-touch-\(UUID().uuidString)", isDirectory: true)
    }

    override func tearDown() async throws {
        if let directory { try? FileManager.default.removeItem(at: directory) }
    }

    private func model(_ values: [String: String]) -> GameModel {
        var all = values
        all["GWReset"] = "YES"
        if all["GWSkipOnboarding"] == nil { all["GWSkipOnboarding"] = "YES" }
        return GameModel(args: DebugArgs(values: all), kind: .world, store: SaveStore(directory: directory))
    }

    private func thing(_ id: String, kind: TouchKind, x: Double, half: Double = 4, top: Double = 10,
                       rank: Int? = nil) -> TouchThing {
        TouchThing(id: id, kind: kind, act: .recruit, x: x, standX: x, halfWidth: half, top: top,
                   rank: rank ?? TouchRules.rank(kind))
    }

    /// Steps the game and draws a frame now and then (the frame lists the things and places the framing).
    private func run(_ game: GameModel, seconds: Double, until done: () -> Bool = { false }) {
        var left = seconds
        var frames = 0
        while left > 1e-9 {
            game.advance(by: 1.0 / 60)
            frames += 1
            if frames % 4 == 0 { _ = game.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight) }
            left -= 1.0 / 60
            if done() { return }
        }
    }

    /// The point (in points of the 17 Pro's screen) at a thing's middle.
    private func point(of thing: TouchThing, in game: GameModel) throws -> CGPoint {
        let framing = try XCTUnwrap(game.touch.framing)
        let x = framing.deviceX(stageX: thing.x) / 3
        let y = framing.deviceY(lift: min(thing.top, 30) / 2) / 3
        return CGPoint(x: x, y: y)
    }

    // MARK: - The pure rules

    func testEveryTouchAreaIsAtLeast44PointsAtEveryScale() {
        // The world's scale and the hall's two (walking, audience) on 3x and 2x screens.
        for (scale, screen) in [(6.0, 3.0), (7.0, 3.0), (8.0, 3.0), (4.0, 2.0), (5.0, 2.0), (6.0, 2.0)] {
            let perPixel = TouchRules.pointsPerPixel(scale: scale, screenScale: screen)
            let minimum = TouchRules.minimumSide(pointsPerPixel: perPixel)
            for kind in TouchKind.allCases {
                let small = thing("t", kind: kind, x: 100, half: 1, top: 0)
                let area = TouchRules.area(small, minimum: minimum)
                XCTAssertGreaterThanOrEqual(area.width * perPixel, 44 - 1e-9, "\(kind) at s \(scale) on @\(screen)x")
                XCTAssertGreaterThanOrEqual(area.height * perPixel, 44 - 1e-9, "\(kind) at s \(scale) on @\(screen)x")
                XCTAssertTrue(area.contains(x: 100, lift: 0), "its standing place is inside")
            }
        }
        XCTAssertEqual(TouchRules.minimumSide(pointsPerPixel: 2), 22, "22 game px at the world's scale")
        XCTAssertEqual(TouchRules.minimumSide(pointsPerPixel: 8.0 / 3), 17, "17 in the audience framing")
        let big = thing("wall", kind: .wall, x: 100, half: 20, top: 50)
        let area = TouchRules.area(big, minimum: 22)
        XCTAssertEqual(area.width, 40, "a big thing keeps its own width")
        // Fix round 1: a wall's mark keeps to the band; the wall still answers up to its top.
        XCTAssertEqual(area.top, max(50, TouchRules.bandTip + TouchRules.markHeight), "up to its top")
    }

    func testTheNearerCentreWins() {
        let a = thing("a", kind: .plot, x: 100)
        let b = thing("b", kind: .plot, x: 115)
        XCTAssertEqual(TouchRules.pick(x: 104, lift: 5, things: [a, b], minimum: 22)?.id, "a")
        XCTAssertEqual(TouchRules.pick(x: 112, lift: 5, things: [a, b], minimum: 22)?.id, "b")
        XCTAssertNil(TouchRules.pick(x: 160, lift: 5, things: [a, b], minimum: 22), "the ground")
        XCTAssertNil(TouchRules.pick(x: 100, lift: 80, things: [a, b], minimum: 22), "the sky over it")
        // Within 4 px it is a tie: the rank decides (the throne before a brazier).
        let throne = thing("throne", kind: .throne, x: 100)
        let brazier = thing("brazier", kind: .brazier, x: 106)
        XCTAssertEqual(TouchRules.pick(x: 104, lift: 5, things: [brazier, throne], minimum: 22)?.id, "throne")
    }

    func testAPersonBeforeAWallWins() {
        let wall = thing("touch-wall-6", kind: .wall, x: 100, half: 20, top: 50)
        let odile = thing("touch-talk-odile", kind: .talk, x: 112, half: 5, top: 30, rank: TouchRules.rank(.talk))
        // Nearer the wall's centre, but on the person: the person.
        XCTAssertEqual(TouchRules.pick(x: 104, lift: 10, things: [wall, odile], minimum: 22)?.id, "touch-talk-odile")
        // Beside him, the wall.
        XCTAssertEqual(TouchRules.pick(x: 86, lift: 10, things: [wall, odile], minimum: 22)?.id, "touch-wall-6")
    }

    func testABenchIsOneTarget() {
        var s = GameState.newRealm(seed: 5)
        s.hour = 10
        let body = SpeakerBody.court(.petitionerD)
        let seats = [195.0, 184, 173]
        let figures = seats.enumerated().map { index, x in
            DrawnFigure(who: "petitionerD", key: "p:\(index)", body: body, x: x, y: 6, facing: -1, frame: 4,
                        alpha: 1, look: index, petition: "p\(index)", talking: false, onBench: true)
        }
        let things = TouchThings.hall(s, figures: figures, talked: [], lordX: 300)
        let benches = things.filter { $0.kind == .bench }
        XCTAssertEqual(benches.count, 1, "three seated, one target")
        XCTAssertEqual(benches.first?.id, "touch-bench-0")
        for x in seats {
            XCTAssertEqual(TouchRules.pick(x: x, lift: 12, things: things, minimum: 19)?.id, "touch-bench-0",
                           "a tap on any seat is the bench (\(x))")
        }
        XCTAssertFalse(things.contains { $0.id.hasPrefix("touch-talk-petitioner") }, "nobody on it alone")
    }

    func testTenPointsOrLessIsATap() {
        XCTAssertTrue(TouchRules.isTap(travel: 0))
        XCTAssertTrue(TouchRules.isTap(travel: 10))
        XCTAssertFalse(TouchRules.isTap(travel: 10.5))
        XCTAssertFalse(TouchRules.isTap(travel: 40))
    }

    func testAtMostFourMarksTheNearestFirstTwoSitesAndOneWall() {
        var list: [TouchThing] = []
        for i in 0..<4 { list.append(thing("plot-\(i)", kind: .plot, x: 100 + Double(i) * 40)) }
        // Fix round 1: a wall's mark keeps to the band, low enough to give way to a site's beside it: the row of walls
        // stands away from the sites.
        list.append(thing("wall-a", kind: .wall, x: 255, half: 15, top: 40))
        list.append(thing("wall-b", kind: .wall, x: 259, half: 15, top: 40))
        list.append(thing("odile", kind: .talk, x: 300))
        list.append(thing("door", kind: .door, x: 340))
        var quiet = thing("tamsin", kind: .talk, x: 102)
        quiet.marked = false
        list.append(quiet)
        let marked = TouchRules.marked(list, lordX: 100, viewLeft: 0, viewRight: 400)
        XCTAssertEqual(marked.count, TouchRules.maxMarks)
        XCTAssertEqual(marked.filter { $0.kind == .wall }.count, 1, "of a row of walls only the nearest")
        XCTAssertEqual(marked.filter { $0.kind == .plot }.count, TouchRules.maxSiteMarks, "two sites at most")
        XCTAssertEqual(marked.first?.id, "plot-0")
        XCTAssertTrue(marked.contains { $0.id == "odile" }, "then the next nearest of another kind")
        XCTAssertFalse(marked.contains { $0.id == "tamsin" }, "nothing new to say, no mark")
        XCTAssertTrue(TouchRules.marked(list, lordX: 100, viewLeft: 500, viewRight: 900).isEmpty, "none out of view")
        // Two tags side by side: the farther gives way.
        let close = [thing("a", kind: .door, x: 100), thing("b", kind: .recruit, x: 108)]
        XCTAssertEqual(TouchRules.marked(close, lordX: 100, viewLeft: 0, viewRight: 400).map(\.id), ["a"])
    }

    /// Polish B3 (M2, the 12 px memory): a walk along a row of five people (four marks at most) changes the set of
    /// marks only once a thing not shown is nearer to the lord by more than `TouchRules.keepMargin`, and a step back
    /// and forth inside the margin changes nothing; without the memory the set flips at the half-way point. The
    /// errand's thing stays in the set whatever the nearest four are.
    func testAWalkPastFiveThingsChangesTheMarksOnlyPastTheMargin() {
        XCTAssertEqual(TouchRules.keepMargin, 12)
        let row = (0..<5).map { thing("p\($0)", kind: .talk, x: 100 + Double($0) * 40) }
        func set(_ lordX: Double, _ shown: Set<String>) -> Set<String> {
            Set(TouchRules.marked(row, lordX: lordX, viewLeft: 0, viewRight: 1000, shown: shown).map(\.id))
        }
        // East along the row, one px a frame, each frame remembering the last.
        var shown = set(100, [])
        XCTAssertEqual(shown, ["p0", "p1", "p2", "p3"])
        var changes: [(x: Double, gone: Set<String>, came: Set<String>)] = []
        for x in stride(from: 100.0, through: 260, by: 1) {
            let next = set(x, shown)
            if next != shown { changes.append((x, shown.subtracting(next), next.subtracting(shown))) }
            shown = next
        }
        XCTAssertEqual(changes.count, 1, "one change on the way: \(changes.map(\.x))")
        for change in changes {
            let gone = row.first { change.gone.contains($0.id) }!
            let came = row.first { change.came.contains($0.id) }!
            XCTAssertLessThan(abs(came.x - change.x), abs(gone.x - change.x) - TouchRules.keepMargin,
                              "the new one is nearer by more than 12 px at \(change.x)")
        }
        // p0 (100) and p4 (260) are as near at 180: the change comes at 187 going east, at 173 going west.
        XCTAssertEqual(changes.first?.x, 187)
        var west = set(260, [])
        var westChanges: [Double] = []
        for x in stride(from: 260.0, through: 100, by: -1) {
            let next = set(x, west)
            if next != west { westChanges.append(x) }
            west = next
        }
        XCTAssertEqual(westChanges, [173], "and back west only past the margin the other way")
        // Back and forth inside the margin around the half-way point: nothing changes.
        var held = set(180, ["p0", "p1", "p2", "p3"])
        let start = held
        for x in [181.0, 179, 183, 177, 185, 175, 186, 174, 180] {
            held = set(x, held)
            XCTAssertEqual(held, start, "inside the 12 px at \(x)")
        }
        // Without the memory the nearest four flip at the half-way point.
        XCTAssertNotEqual(set(179, []), set(181, []), "the old rule flipped with one step")
        // The errand's thing stays among the marks, also when it is the farthest.
        let errandThing = row[4]
        let marked = TouchRules.marked(row, lordX: 100, viewLeft: 0, viewRight: 1000, shown: shown)
        XCTAssertFalse(marked.contains { $0.id == errandThing.id })
        XCTAssertTrue(TouchRules.withErrand(marked, errandThing).contains { $0.id == errandThing.id },
                      "the errand's mark is in the set")
        XCTAssertLessThanOrEqual(TouchRules.withErrand(marked, errandThing).count, TouchRules.maxMarks)
    }

    /// Polish B3 (law 1 quick): a mark comes in 0.15 s on the ease-out curve, rising 2 whole game px to its place, and
    /// goes in 0.10 s in place; a mark that stays keeps its presence when the set around it changes; under Reduce
    /// Motion alpha only, at quick; its pool follows its share.
    func testAMarkComesAndGoesByThePresenceRule() {
        func mark(_ id: String, x: Double) -> TouchMark {
            TouchMark(sprite: .tapTalk, x: x, lift: 30, pressed: false, poolX: x, kind: .talk, id: id)
        }
        var shows: [String: MarkShow] = [:]
        let step = 1.0 / 60
        MarkPresence.merge(&shows, wanted: [mark("a", x: 100)])
        XCTAssertTrue(MarkPresence.drawn(shows).isEmpty, "not yet begun: nothing drawn in its first frame")
        var rises: [Int] = []
        var alphas: [Double] = []
        for _ in 0..<9 {
            MarkPresence.step(&shows, seconds: step, mode: .full)
            let drawn = MarkPresence.drawn(shows)
            rises.append(drawn.first?.rise ?? -1)
            alphas.append(drawn.first?.alpha ?? -1)
        }
        XCTAssertEqual(alphas.last ?? 0, 1, accuracy: 1e-9, "whole after 0.15 s")
        XCTAssertEqual(rises.last, 0, "at its place")
        XCTAssertEqual(rises.first, 2, "it starts 2 px low")
        XCTAssertEqual(rises, rises.sorted(by: >), "it only rises")
        XCTAssertTrue(Set(rises).isSubset(of: [0, 1, 2]), "whole px only")
        XCTAssertEqual(alphas, alphas.sorted(), "it only grows")
        XCTAssertLessThan(alphas[1], 1, "it grows over frames")
        // Its pool and its tag at its share; no scale.
        var half = mark("h", x: 0)
        half.alpha = 0.5
        XCTAssertEqual(TouchMarks.pools([half]).first?.intensity ?? 0, TouchRules.poolStrength * 0.5, accuracy: 1e-6)
        let framing = TouchFraming(stage: .world, whole: 0, deviceShift: 0, scale: 6, groundY: 1000,
                                   physicalWidth: 2622, physicalHeight: 1206)
        let actor = TouchMarks.actors([half], framing: framing, night: 0).first
        XCTAssertEqual(actor?.tint.w ?? 0, 0.5, accuracy: 1e-6)
        XCTAssertEqual(actor?.rect.z, Float(SpriteID.tapTalk.size.width) * 6, "never scaled")
        var low = half
        low.rise = 2
        XCTAssertEqual(TouchMarks.rect(low, framing: framing).y - TouchMarks.rect(half, framing: framing).y, 12,
                       "2 game px = 12 device px lower while it comes")
        // A second mark comes; the first stays as it is (no restart, no move).
        MarkPresence.merge(&shows, wanted: [mark("b", x: 140), mark("a", x: 100)])
        MarkPresence.step(&shows, seconds: step, mode: .full)
        let a = MarkPresence.drawn(shows).first { $0.id == "a" }
        XCTAssertEqual(a?.alpha, 1, "the mark that stays keeps its presence")
        XCTAssertEqual(a?.rise, 0)
        XCTAssertEqual(a?.x, 100)
        // The first goes: in place, gone after 0.10 s.
        MarkPresence.merge(&shows, wanted: [mark("b", x: 140)])
        var out: [Double] = []
        for _ in 0..<6 {
            MarkPresence.step(&shows, seconds: step, mode: .full)
            if let going = MarkPresence.drawn(shows).first(where: { $0.id == "a" }) {
                XCTAssertEqual(going.rise, 0, "it goes in place")
                out.append(going.alpha)
            }
        }
        XCTAssertEqual(out.count, 5, "drawn going for 5 frames of 6 (0.10 s)")
        XCTAssertEqual(out, out.sorted(by: >))
        XCTAssertNil(shows["a"], "gone and dropped")
        // A tag that gives way to a board goes at quick out; its pool stays.
        var boarded = mark("b", x: 140)
        boarded.hidden = true
        MarkPresence.merge(&shows, wanted: [boarded])
        for _ in 0..<7 { MarkPresence.step(&shows, seconds: step, mode: .full) }
        let b = MarkPresence.drawn(shows).first { $0.id == "b" }
        XCTAssertEqual(b?.alpha, 1, "its pool and rim stay")
        XCTAssertEqual(b?.hidden, true, "its tag gave way")
        // Reduce Motion: alpha only, at quick.
        var reduced: [String: MarkShow] = [:]
        MarkPresence.merge(&reduced, wanted: [mark("r", x: 100)])
        var reducedRises: Set<Int> = []
        for _ in 0..<9 {
            MarkPresence.step(&reduced, seconds: step, mode: .reduced)
            reducedRises.insert(MarkPresence.drawn(reduced).first?.rise ?? -1)
        }
        XCTAssertEqual(reducedRises, [0], "no rise under Reduce Motion")
        XCTAssertEqual(MarkPresence.drawn(reduced).first?.alpha ?? 0, 1, accuracy: 1e-9, "whole at quick")
    }

    /// Polish B3: a talk bubble's going is heard once (`bubbleClose`) on every way it goes (a tap, a card), never when
    /// the next line of the same speaker takes its place.
    func testABubblesGoingIsHeardOnce() throws {
        let game = model(["GWDay": "3", "GWSeed": "2", "GWClock": "10", "GWStage": "world", "GWCameraX": "2120"])
        let hub = SilentFeedback()
        game.feedback = hub
        run(game, seconds: 0.3)
        // A member of the court in view who has a line; the lord stands by him (walking away would close it).
        var found: String?
        for thing in game.touch.things where thing.kind == .talk {
            guard let who = thing.who else { continue }
            game.withDriver { $0.state.king.x = thing.x - 12 }
            game.talk(to: who)
            if game.talkBubble != nil {
                found = who
                break
            }
        }
        let speaker = try XCTUnwrap(found, "someone with a word in view")
        func closes() -> Int { hub.played.filter { $0 == .bubbleClose }.count }
        XCTAssertNotNil(game.talkBubble, "\(speaker) speaks")
        run(game, seconds: 0.2)
        XCTAssertEqual(closes(), 0)
        game.talk(to: speaker)
        run(game, seconds: 0.2)
        XCTAssertEqual(closes(), 0, "the next line takes its place: no going")
        game.closeTalk()
        run(game, seconds: 0.2)
        XCTAssertEqual(closes(), 1, "a tap closed it: heard once")
        run(game, seconds: 0.5)
        XCTAssertEqual(closes(), 1, "and only once")
        game.talk(to: speaker)
        run(game, seconds: 0.2)
        game.openPause()
        run(game, seconds: 0.2)
        XCTAssertNil(game.talkBubble, "the card closed it")
        XCTAssertEqual(closes(), 2, "a card closed it: heard once")
    }

    func testTheMarksAtNightAreDarkerAndWarm() {
        let day = TouchRules.markTint(night: 0)
        XCTAssertEqual(day, SIMD3<Float>(repeating: 1), "by day as drawn")
        let night = TouchRules.markTint(night: 1)
        let value = max(night.x, max(night.y, night.z))
        XCTAssertEqual(value, 0.78, accuracy: 0.04, "about three quarters of its value")
        XCTAssertGreaterThan(night.x, night.z + 0.15, "warm")
    }

    func testThePace() {
        let walk = 36.0
        let run = 80.0
        XCTAssertEqual(TouchRules.pace(distance: 200, night: false, run: false, walk: walk, runSpeed: run), walk)
        XCTAssertEqual(TouchRules.pace(distance: -600, night: false, run: false, walk: walk, runSpeed: run),
                       TouchRules.hurrySpeed, "far: he hurries")
        XCTAssertEqual(TouchRules.pace(distance: 50, night: true, run: false, walk: walk, runSpeed: run),
                       TouchRules.hurrySpeed, "at night he always hurries")
        XCTAssertEqual(TouchRules.pace(distance: 50, night: false, run: true, walk: walk, runSpeed: run), run)
        XCTAssertEqual(TouchRules.hurrySpeed / walk, 1.9, accuracy: 0.05)
    }

    /// The stage-1 critic's fourth high: while an audience runs, whoever stands within 28 px of the petitioner's place
    /// steps out toward the nave; the seated and the guards stay.
    func testThePetitionerHasTheFloorAlone() {
        let body = SpeakerBody.court(.pip)
        let specs = [
            HallFigureSpec(who: "pip", key: "pip", body: body, x: 350, row: HallLayout.pipRow, facing: 1),
            HallFigureSpec(who: "petitionerD", key: "p:a", body: body, x: 311, row: HallLayout.wallRow, facing: 1,
                           sits: true, petition: "a"),
            HallFigureSpec(who: "guard", key: "guard:arms", body: body, x: 448, row: HallLayout.daisRow, facing: -1),
            HallFigureSpec(who: "petitionerE", key: "p:walker", body: body, x: 338, row: HallLayout.wallRow, facing: 1),
        ]
        let targets = ["pip": 350.0, "p:a": 311, "guard:arms": 448, "p:walker": 338]
        let cleared = HallCourt.clearingTheFloor(targets, specs: specs, walkerKey: "p:walker", spot: 338)
        XCTAssertGreaterThanOrEqual(abs((cleared["pip"] ?? 0) - 338), HallCourt.clearZone, "Pip steps aside")
        XCTAssertLessThan(cleared["pip"] ?? 999, 338, "toward the nave")
        XCTAssertEqual(cleared["p:a"], 311, "the seated stay seated")
        XCTAssertEqual(cleared["guard:arms"], 448)
        XCTAssertEqual(cleared["p:walker"], 338, "the petitioner keeps his place")
    }

    /// M14: the slips' German lines stay one short line (the slip has one line and no wrap): at most 34 characters for
    /// the longest act with a place's name, the two arrivals for VoiceOver excepted.
    func testTheGermanSlipsFit() throws {
        let folder = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        let url = folder.appendingPathComponent("Resources/Localizable.xcstrings")
        guard let data = try? Data(contentsOf: url),
              let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let strings = json["strings"] as? [String: Any] else {
            throw XCTSkip("the source catalog \(url.path) is out of reach")
        }
        func german(_ key: String) -> String? {
            let entry = strings[key] as? [String: Any]
            let de = (entry?["localizations"] as? [String: Any])?["de"] as? [String: Any]
            return (de?["stringUnit"] as? [String: Any])?["value"] as? String
        }
        // The longest place a slip names is the slot's name "Großes Leuchtfeuer" (`Texts.slotName`).
        for key in ["Build: %@", "Upgrade: %@", "Rebuild: %@"] {
            let line = try XCTUnwrap(german(key), key).replacingOccurrences(of: "%@", with: "Großes Leuchtfeuer")
            XCTAssertLessThanOrEqual(line.count, 34, line)
        }
        for key in ["Sit on the throne", "Repair the wall", "Leave the great hall", "Enter the great hall",
                    "Light the brazier", "Recruit"] {
            let line = try XCTUnwrap(german(key), key)
            XCTAssertLessThanOrEqual(line.count, 30, line)
        }
        XCTAssertNotNil(german("Walk left"))
        XCTAssertNotNil(german("Walk right"))
        XCTAssertNotNil(german("Raise the lantern"))
        XCTAssertNotNil(german("%lld gold"))
    }

    /// The director's note of 14.11. 22:17: the atlas's row count in every step report (the seventh mark, `tapDoor`,
    /// joined it in this step).
    func testTheAtlasStillFitsOnePage() {
        let layout = AtlasBuilder.build(bundle: .main)
        // The join: the world's second page (`AtlasLayout.pages`), as PeopleCastTests.
        XCTAssertLessThanOrEqual(layout.height, AtlasLayout.maxHeight)
        let attachment = XCTAttachment(string: "atlas: \(layout.width) x \(layout.height) of \(AtlasLayout.maxHeight)")
        attachment.name = "atlas-rows"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    // MARK: - What offers something

    func testTheWorldOffersSitesTheBarracksAndTheDoorByDay() {
        var s = GameState.newRealm(seed: 2)
        s.hour = 9
        let things = TouchThings.world(s, balance: .standard, figures: [], talked: [])
        let brazier = Realm.lines[0].braziers[0]
        XCTAssertTrue(things.contains { $0.id == "touch-plot-\(brazier)" && $0.kind == .plot }, "line 1's empty site")
        XCTAssertFalse(things.contains { $0.id == "touch-plot-\(Realm.lines[1].wall)" }, "the middle line opens later")
        // Build 3, the count: the barracks are two things, a board each.
        XCTAssertTrue(things.contains { $0.id == "touch-recruit-archer" && $0.soldier == .archer })
        XCTAssertTrue(things.contains { $0.id == "touch-recruit-guard" && $0.soldier == .guardsman })
        XCTAssertTrue(things.contains { $0.id == "touch-door-hall" && $0.x == HallLayout.worldDoorX })
        XCTAssertFalse(things.contains { $0.kind == .wall || $0.kind == .brazier }, "no repair or fire by day")
        for thing in things {
            XCTAssertNotNil(thing.kind.mark, "\(thing.id) carries a mark")
            XCTAssertTrue(thing.id.hasPrefix("touch-"), thing.id)
        }
    }

    func testTheNightOffersColdBraziersAndDamagedWalls() {
        var s = GameState.newRealm(seed: 2)
        s.hour = 22
        let wall = Realm.lines[0].wall
        if let item = s.plots[wall].item {
            s.plots[wall].hp = Build.maxHP(item, balance: .standard) / 2
        }
        let brazier = Realm.lines[0].braziers[0]
        s.plots[brazier].item = .brazier
        s.plots[brazier].snuffed = true
        let things = TouchThings.world(s, balance: .standard, figures: [], talked: [])
        let repair = things.first { $0.id == "touch-wall-\(wall)" }
        XCTAssertEqual(repair?.kind, .wall)
        XCTAssertEqual(repair?.price, Balance.standard.patchCost, "its price for the slip")
        XCTAssertEqual(repair?.act, .patch(plot: wall))
        XCTAssertEqual(things.first { $0.id == "touch-brazier-\(brazier)" }?.act, .light(plot: brazier))
        XCTAssertFalse(things.contains { $0.kind == .plot }, "no building at night")
        s.defeated = true
        XCTAssertTrue(TouchThings.world(s, balance: .standard, figures: [], talked: []).isEmpty)
    }

    // MARK: - The errands

    /// Build 3, the count's step 4: a tap on an empty site with one offer brings its tally board and walks the lord
    /// beside it; no card opens from a plot any more.
    func testATapOnASiteBringsItsBoardAndNoCard() throws {
        // Step 5 (H1): the board keeps off the trap's site beside brazier A, so it stands further out, its stand
        // near 1175; the lord starts well away from it (round lh-b3c-51: at 1180 he already stood there).
        let game = model(["GWStage": "world", "GWSeed": "1", "GWClock": "9", "GWCameraX": "1110"])
        _ = game.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
        let plot = Realm.lines[0].braziers[0]
        let site = try XCTUnwrap(game.touch.things.first { $0.id == "touch-plot-\(plot)" }, "the site offers")
        XCTAssertNil(game.overlay)
        game.tap(at: try point(of: site, in: game), in: proPoints)
        XCTAssertEqual(game.touch.count?.thing, site.id, "its board comes up")
        XCTAssertEqual(game.touch.errand?.id, site.id, "he sets off to stand beside it")
        run(game, seconds: 12) { game.touch.count?.ready == true }
        XCTAssertEqual(game.touch.count?.ready, true, "he stands beside the board")
        XCTAssertNil(game.overlay, "no card from a plot")
        let x = try XCTUnwrap(game.driver?.state.king.x)
        let board = try XCTUnwrap(game.touch.countBoard)
        XCTAssertEqual(x, board.stand, accuracy: TouchRules.arrival)
    }

    func testATapOnTheGroundWalksHimThereAndADragCallsHimOff() throws {
        let game = model(["GWStage": "world", "GWSeed": "1", "GWClock": "9", "GWCameraX": "2900"])
        _ = game.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
        let framing = try XCTUnwrap(game.touch.framing)
        let goal = framing.viewLeft + 40
        // Low on the lane, where nothing stands.
        let p = CGPoint(x: framing.deviceX(stageX: goal) / 3, y: framing.deviceY(lift: -3) / 3)
        let start = try XCTUnwrap(game.driver?.state.king.x)
        if game.thingAt(p, in: proPoints) == nil {
            game.tap(at: p, in: proPoints)
            run(game, seconds: 8) { game.driver?.travelTarget == nil }
            XCTAssertEqual(try XCTUnwrap(game.driver?.state.king.x), goal, accuracy: 1, "he walked to the finger's x")
        }
        // A tap far right, then a drag: called off.
        let far = CGPoint(x: framing.deviceX(stageX: start + 150) / 3, y: framing.deviceY(lift: -3) / 3)
        game.tap(at: far, in: proPoints)
        XCTAssertNotNil(game.driver?.travelTarget)
        game.touchChanged(start: CGPoint(x: 400, y: 300), at: CGPoint(x: 380, y: 300),
                          translation: CGSize(width: -20, height: 0), in: proPoints)
        XCTAssertNil(game.driver?.travelTarget, "the drag took over")
        // LANE-A: A1b
        // Polish step A1b (a drag walks like a tap): the drag sets his walk, the driver's steps turn and start him.
        XCTAssertLessThan(try XCTUnwrap(game.driver?.dragPace), 0, "walking toward the drag")
        run(game, seconds: 0.4)
        XCTAssertLessThan(try XCTUnwrap(game.driver?.state.king.velocity), 0, "walking toward the drag")
        let lifted = try XCTUnwrap(game.driver?.state.king.x)
        game.touchEnded(at: CGPoint(x: 380, y: 300), translation: CGSize(width: -20, height: 0), in: proPoints)
        run(game, seconds: 0.4)
        XCTAssertEqual(try XCTUnwrap(game.driver?.state.king.velocity), 0, "the finger lifts: he stops")
        XCTAssertLessThanOrEqual(lifted - (try XCTUnwrap(game.driver?.state.king.x)), 4 + 1e-9, "after the brake")
        // LANE-A end
    }

    func testASecondTapMakesHimRun() throws {
        // Build 3: the barracks are bought by the count now; the hall's door still takes an errand.
        let game = model(["GWStage": "world", "GWSeed": "1", "GWClock": "9", "GWCameraX": "1640"])
        _ = game.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
        let door = try XCTUnwrap(game.touch.things.first { $0.id == "touch-door-hall" })
        game.touchThing(door)
        XCTAssertEqual(game.driver?.travelSpeed, Balance.standard.kingWalkSpeed, "a walk")
        game.touchThing(door)
        XCTAssertEqual(game.driver?.travelSpeed, Balance.standard.kingRunSpeed, "the second tap: a run")
        XCTAssertEqual(game.touch.errand?.run, true)
    }

    func testTheHallDoorChangesTheStage() throws {
        let game = model(["GWStage": "world", "GWSeed": "1", "GWClock": "10", "GWCameraX": "1760"])
        _ = game.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
        let door = try XCTUnwrap(game.touch.things.first { $0.id == "touch-door-hall" })
        game.touchThing(door)
        run(game, seconds: 6) { game.stage == .hall && game.stageChange == nil }
        XCTAssertEqual(game.stage, .hall, "in by the door")
        _ = game.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
        let inner = try XCTUnwrap(game.touch.things.first { $0.id == "touch-door-hall" }, "the inner door")
        XCTAssertEqual(inner.x, HallLayout.doorX)
        XCTAssertFalse(inner.marked, "he just came through it: its mark rests")
        game.touchThing(inner)
        run(game, seconds: 4) { game.stage == .world && game.stageChange == nil }
        XCTAssertEqual(game.stage, .world, "out by the inner door")
    }

    func testTheThroneHoldsTheAudienceAndABenchSpeaks() throws {
        // Day 1: the tutorial's farmer waits.
        let game = model(["GWStage": "hall", "GWHallX": "150", "GWSeed": "1", "GWClock": "9"])
        run(game, seconds: 0.5)
        let things = game.touch.things
        let throne = try XCTUnwrap(things.first { $0.id == "touch-throne" }, "the throne offers the audience")
        XCTAssertEqual(throne.kind.mark, .tapThrone)
        if let bench = things.first(where: { $0.kind == .bench }) {
            game.touchThing(bench)
            run(game, seconds: 8) { game.talkBubble != nil }
            XCTAssertNotNil(game.talkBubble, "the first in line speaks")
            XCTAssertNotNil(game.talkBubble?.nameText, "his name over the line")
        }
        game.touchThing(throne)
        run(game, seconds: 12) { game.overlay == .audience }
        XCTAssertEqual(game.overlay, .audience, "he sits and the audience begins")
    }

    /// Build 3: a damaged wall's repair is paid by its count (PayCountTests' `testTheRepairIsPaidByItsCount`); the
    /// second touch that paid at once is gone.

    func testAHoldOnTheLordAtNightRaisesTheLantern() throws {
        // In the town, where nothing offers anything at night.
        let game = model(["GWStage": "world", "GWSeed": "1", "GWNight": "1", "GWHour": "22", "GWCameraX": "2600"])
        _ = game.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
        let framing = try XCTUnwrap(game.touch.framing)
        let x = try XCTUnwrap(game.driver?.state.king.x)
        let on = CGPoint(x: framing.deviceX(stageX: x) / 3, y: framing.deviceY(lift: 15) / 3)
        game.touchChanged(start: on, at: on, translation: .zero, in: proPoints)
        run(game, seconds: 0.5)
        XCTAssertEqual(LanternRaise.phase(since: game.driver?.state.king.lanternSince), .raised, "the hold raised it")
        game.touchEnded(at: on, translation: .zero, in: proPoints)
        XCTAssertNil(game.touch.errand, "and the lift did nothing more")
        XCTAssertEqual(try XCTUnwrap(game.driver?.state.king.x), x, accuracy: 0.5, "he did not walk")
        game.refreshHUD()
        XCTAssertTrue(game.sceneStatus.contains("lantern:raised"), game.sceneStatus)
    }

    /// Build 2 review, app-ui-3: while Marek's offer is open a touch on his cart opens his gift card (no debug argument,
    /// so in Release too). b3-yard (build 3, wave 2, lane 2, step 3): the cart stands by the back gate now (2218), on
    /// free ground: with no offer open a touch there walks the lord, as on any ground; a touch on Marek himself before
    /// the cart's east half opens his card while he has no mark. (A card cutting a count off is PayCountTests' "a card
    /// cuts it off"; the cart no longer stands over a thing that is bought.)
    func testATouchOnMareksCartOpensHisCardWhileTheOfferIsOpen() throws {
        let game = model(["GWDay": "3", "GWStage": "world", "GWCameraX": "2200"])
        let stub = StubAdProvider()
        let ads = AdDirector(mode: .stub, provider: stub, clock: CountedClock())
        ads.attach(game)
        XCTAssertNotNil(ads.merchantOffer, "his cart stands on day 3")
        _ = game.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
        let framing = try XCTUnwrap(game.touch.framing)
        // Between Tamsin at her oven (2208) and Marek before the cart's east half, each with a 44 pt touch area.
        let cart = CGPoint(x: framing.deviceX(stageX: CourtLayout.marekCartX + 11) / 3,
                           y: framing.deviceY(lift: 12) / 3)
        XCTAssertNil(game.thingAt(cart, in: proPoints), "nobody and nothing that is bought at the cart's west half")
        // Build 3: through the finger's own path (down, then lift).
        game.touchChanged(start: cart, at: cart, translation: .zero, in: proPoints)
        XCTAssertNil(game.touch.count, "no count starts on his cart")
        game.touchEnded(at: cart, translation: .zero, in: proPoints)
        XCTAssertTrue(ads.merchantCardOpen, "the touch on the cart opens his card")
        XCTAssertEqual(game.touch.lastTap, "merchant")
        XCTAssertNil(game.touch.errand, "no walk")
        ads.closeMerchantCard()
        // No offer open (no video ready): the ground's touch, he walks there.
        stub.rewardedReady = false
        XCTAssertNil(ads.merchantOffer)
        game.touchChanged(start: cart, at: cart, translation: .zero, in: proPoints)
        game.touchEnded(at: cart, translation: .zero, in: proPoints)
        XCTAssertFalse(ads.merchantCardOpen)
        XCTAssertEqual(game.touch.lastTap, "ground", "free ground by the back gate")
        XCTAssertNil(game.touch.count, "nothing is counted at the cart")
        // Marek before his cart's east half is a person (his 44 pt area covers most of the cart). The review: heard
        // today (no mark), a touch on him is the seller's stall, his card, so the whole cart stays one target; with his
        // mark up his word comes first (`GameModel.cartTakesTouch`).
        stub.rewardedReady = true
        XCTAssertNotNil(ads.merchantOffer)
        game.talkLog.note("marek", day: 3)
        run(game, seconds: 0.1)
        let now = try XCTUnwrap(game.touch.framing)
        let marek = try XCTUnwrap(game.touch.things.first(where: { $0.who == "marek" }),
                                  "Marek before his cart is a person with a word on day 3")
        XCTAssertFalse(marek.marked, "heard today: no mark over him")
        let on = CGPoint(x: now.deviceX(stageX: marek.x) / 3, y: now.deviceY(lift: 14) / 3)
        XCTAssertEqual(game.thingAt(on, in: proPoints)?.id, marek.id, "a touch on Marek finds him")
        game.touchChanged(start: on, at: on, translation: .zero, in: proPoints)
        game.touchEnded(at: on, translation: .zero, in: proPoints)
        XCTAssertTrue(ads.merchantCardOpen, "without his mark the seller opens his stall: his card")
        XCTAssertEqual(game.touch.lastTap, "merchant")
        ads.closeMerchantCard()
        var hinted = marek
        hinted.marked = true
        XCTAssertFalse(GameModel.cartTakesTouch(from: hinted), "with his mark up, his word first")
        XCTAssertTrue(GameModel.cartTakesTouch(from: nil), "the bare cart is the cart's")
    }

    /// Build 2 fix A's review: the background under Marek's card raises the lantern moment behind it; closing the card
    /// leaves the world standing under that moment.
    func testClosingMareksCardKeepsTheWorldUnderALanternMoment() throws {
        let game = model(["GWDay": "3", "GWStage": "world", "GWCameraX": "1430"])
        let ads = AdDirector(mode: .stub, provider: StubAdProvider(), clock: CountedClock())
        ads.attach(game)
        _ = game.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
        ads.openMerchantCard()
        XCTAssertTrue(ads.merchantCardOpen)
        game.pauseForBackground()
        XCTAssertNotNil(game.lanternMoment, "the background raised the moment behind the card")
        ads.closeMerchantCard()
        XCTAssertNotNil(game.lanternMoment)
        XCTAssertTrue(game.isPaused, "the moment still holds the world")
    }

    /// Build 2 review, app-ui-2: by day a press on the lord held 0.35 s or longer opens the lantern moment like a short
    /// tap (the hold raises no lantern by day).
    func testALongPressOnTheLordByDayOpensTheLanternMoment() throws {
        let game = model(["GWStage": "world", "GWSeed": "1", "GWClock": "9", "GWCameraX": "2900"])
        _ = game.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
        let framing = try XCTUnwrap(game.touch.framing)
        let on = CGPoint(x: framing.deviceX(stageX: game.stageLordX) / 3, y: framing.deviceY(lift: 15) / 3)
        // Nothing offers under the finger, so the press is on the lord alone (the steps below draw no frame).
        game.touch.things = []
        game.touchChanged(start: on, at: on, translation: .zero, in: proPoints)
        XCTAssertTrue(game.touch.onLord, "the press is on the lord")
        for _ in 0..<30 { game.advance(by: 1.0 / 60) }
        XCTAssertNil(game.lanternMoment, "nothing before the finger lifts")
        game.touchEnded(at: on, translation: .zero, in: proPoints)
        XCTAssertNotNil(game.lanternMoment, "the long press opened the lantern moment")
        XCTAssertEqual(game.touch.lastTap, "moment")
    }

    /// Build 2 review, app-ui-1: a touch the system cancels (the notification shade, Control Center, the home edge)
    /// never ends. A new start point is a new touch; the scene going inactive (`GameView` calls `resetTouch`), a card
    /// and the lantern moment forget the finger.
    func testACancelledTouchLeavesNoStaleFinger() throws {
        let game = model(["GWStage": "world", "GWSeed": "1", "GWClock": "9", "GWCameraX": "2900"])
        _ = game.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
        let framing = try XCTUnwrap(game.touch.framing)
        let x = try XCTUnwrap(game.driver?.state.king.x)
        // A drag the system cancels: no end comes.
        game.touchChanged(start: CGPoint(x: 400, y: 300), at: CGPoint(x: 380, y: 300),
                          translation: CGSize(width: -20, height: 0), in: proPoints)
        XCTAssertTrue(game.touch.dragging)
        // The next touch starts elsewhere: a tap of its own, not the end of the dead drag.
        let p = CGPoint(x: framing.deviceX(stageX: x + 60) / 3, y: framing.deviceY(lift: -3) / 3)
        game.touchChanged(start: p, at: p, translation: .zero, in: proPoints)
        XCTAssertFalse(game.touch.dragging, "a new touch")
        XCTAssertEqual(game.touch.down, p)
        game.touchEnded(at: p, translation: .zero, in: proPoints)
        XCTAssertNotEqual(game.touch.lastTap, "none", "the tap counted")

        // The scene goes inactive during a drag: the finger is forgotten and he stops.
        game.touchChanged(start: CGPoint(x: 500, y: 300), at: CGPoint(x: 470, y: 300),
                          translation: CGSize(width: -30, height: 0), in: proPoints)
        // LANE-A: A1b
        // Polish step A1b (a drag walks like a tap): the drag sets his walk, the driver's steps start him, and the
        // forgotten finger lets go: the brake, then he stands.
        XCTAssertLessThan(try XCTUnwrap(game.driver?.dragPace), 0, "walking toward the drag")
        run(game, seconds: 0.4)
        XCTAssertLessThan(try XCTUnwrap(game.driver?.state.king.velocity), 0, "walking toward the drag")
        game.resetTouch()
        XCTAssertNil(game.touch.down)
        XCTAssertFalse(game.touch.dragging)
        XCTAssertNil(game.driver?.dragPace, "the finger is forgotten")
        run(game, seconds: 0.4)
        // LANE-A end
        XCTAssertEqual(try XCTUnwrap(game.driver?.state.king.velocity), 0, "he stops")

        // A card opens under a finger.
        game.touchChanged(start: CGPoint(x: 600, y: 300), at: CGPoint(x: 570, y: 300),
                          translation: CGSize(width: -30, height: 0), in: proPoints)
        game.openPause()
        XCTAssertEqual(game.overlay, .pause)
        XCTAssertNil(game.touch.down, "the card takes the finger's state")
        XCTAssertFalse(game.touch.dragging)
        game.resume()

        // The lantern moment opens under a finger (the app goes to the background mid-touch).
        game.touchChanged(start: p, at: p, translation: .zero, in: proPoints)
        XCTAssertNotNil(game.touch.down)
        game.pauseForBackground()
        XCTAssertNotNil(game.lanternMoment)
        XCTAssertNil(game.touch.down, "no finger under the moment")
        XCTAssertNil(game.touch.pressed)
    }

    /// Build 2 review, app-ui-1: a hold on the lord at night that the system cancels raises nothing by itself.
    func testACancelledHoldOnTheLordAtNightRaisesNothing() throws {
        let game = model(["GWStage": "world", "GWSeed": "1", "GWNight": "1", "GWHour": "22", "GWCameraX": "2600"])
        _ = game.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
        let framing = try XCTUnwrap(game.touch.framing)
        let x = try XCTUnwrap(game.driver?.state.king.x)
        let on = CGPoint(x: framing.deviceX(stageX: x) / 3, y: framing.deviceY(lift: 15) / 3)
        game.touchChanged(start: on, at: on, translation: .zero, in: proPoints)
        XCTAssertTrue(game.touch.onLord)
        game.resetTouch()
        run(game, seconds: 0.5)
        XCTAssertNotEqual(LanternRaise.phase(since: game.driver?.state.king.lanternSince), .raised, "nothing raised")
    }

    func testTheSceneValueCarriesTheLordAndTheErrand() throws {
        let game = model(["GWStage": "world", "GWSeed": "1", "GWClock": "9", "GWCameraX": "1700"])
        _ = game.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
        game.refreshHUD()
        XCTAssertTrue(game.sceneStatus.contains("errand:none"), game.sceneStatus)
        XCTAssertTrue(game.sceneStatus.contains("lx:1700"), game.sceneStatus)
        XCTAssertTrue(game.sceneStatus.contains("stage:world"), game.sceneStatus)
        let recruit = try XCTUnwrap(game.touch.things.first { $0.id == "touch-recruit-archer" })
        game.touchThing(recruit)
        game.refreshHUD()
        XCTAssertTrue(game.sceneStatus.contains("errand:touch-recruit-archer"), game.sceneStatus)
        #if DEBUG
        XCTAssertTrue(game.sceneStatus.contains("count:touch-recruit-archer:0/1:open"), game.sceneStatus)
        #endif
    }

    func testTheMarksAreDrawnAndTheSpotsPlaced() throws {
        let game = model(["GWStage": "world", "GWSeed": "1", "GWClock": "9", "GWCameraX": "1180"])
        // Polish B3: the marks come at quick (0.15 s) from the first frame that lists them, so they are drawn once
        // their coming has run.
        run(game, seconds: 0.3)
        let frame = game.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
        let marks = frame.actors.filter { [.tapBuild, .tapRecruit, .tapDoor, .tapTalk].contains($0.sprite) }
        XCTAssertFalse(marks.isEmpty, "a mark over what offers something")
        XCTAssertLessThanOrEqual(marks.count, TouchRules.maxMarks)
        XCTAssertTrue(marks.allSatisfy { $0.isEmissive }, "drawn unlit")
        game.refreshTouchSpots()
        XCTAssertFalse(game.touchSpots.isEmpty, "the things in view are elements")
        let xs = game.touchSpots.map(\.rect.minX)
        XCTAssertEqual(xs, xs.sorted(), "left to right")
        for spot in game.touchSpots {
            XCTAssertGreaterThanOrEqual(spot.rect.width * proPoints.width, 44 - 0.5, spot.id)
            XCTAssertGreaterThanOrEqual(spot.rect.height * proPoints.height, 44 - 0.5, spot.id)
            XCTAssertFalse(spot.label.isEmpty, spot.id)
        }
    }

    /// Polish B3 (H4): no slip over the errand's thing; its own mark is its sign, pressed (pool x 1.4) from the touch
    /// until he arrives, among the marks drawn in every frame of the walk while it stands clear of the edges, over its
    /// thing within one device px (the smooth walk's proof, lane 5 step 2a, which the slip's test held before).
    func testTheErrandsMarkIsItsSignInEveryFrameOfAWalk() throws {
        let game = model(["GWStage": "world", "GWSeed": "1", "GWClock": "9", "GWCameraX": "1640"])
        _ = game.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
        let door = try XCTUnwrap(game.touch.things.first { $0.id == "touch-door-hall" })
        game.touchThing(door)
        XCTAssertEqual(game.touch.errand?.id, door.id, "he sets off to the door")
        var seen: Set<Double> = []
        var drawnPressed = 0
        for _ in 0..<120 {
            game.advance(by: 1.0 / 60)
            let frame = game.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
            XCTAssertNil(game.errandSlip, "no words over the walked world")
            guard game.touch.errand?.id == door.id, game.touch.errand?.waiting == false else { break }
            let framing = try XCTUnwrap(game.touch.framing)
            let thing = try XCTUnwrap(game.touch.things.first { $0.id == door.id })
            guard TouchRules.clearOfEdges(thing.markX, viewLeft: framing.viewLeft, viewRight: framing.viewRight)
            else { continue }
            let show = try XCTUnwrap(game.touch.markShows[door.id], "the errand's mark is among the marks")
            XCTAssertTrue(show.wanted)
            XCTAssertTrue(show.mark.pressed, "pressed while he walks to it")
            XCTAssertFalse(show.mark.hidden, "never hidden")
            let thingX = framing.deviceX(stageX: thing.markX)
            if let tag = frame.actors.first(where: { $0.sprite == .tapDoor }), show.whole.isWhole {
                XCTAssertEqual(tag.frame, 1, "the pressed frame")
                let tip = Double(tag.rect.x) + Double(SpriteID.tapDoor.size.width / 2) * framing.scale
                XCTAssertEqual(tip, thingX, accuracy: 1, "the mark stands over its thing")
                drawnPressed += 1
            }
            seen.insert(thingX)
        }
        XCTAssertGreaterThan(drawnPressed, 20, "the pressed mark was drawn through the walk")
        XCTAssertGreaterThan(seen.count, 20, "the door moved on the screen while he walked")
    }

    /// Polish B1 (rider 2): while Brannock's offer of the horn takes the touch, his element names the deed ("Sound the
    /// horn"); otherwise it is a talk as for everyone. Polish B3 (part 5, B1's L4): each case sets the state it asserts
    /// (heard today, a word of his own still to say, gold enough that the offer does not stand) instead of branching on
    /// what it meets.
    func testBrannocksElementSaysSoundTheHornWhileHisOfferTakesTheTouch() throws {
        let args = ["GWHour": "11", "GWGold": "9", "GWStage": "world", "GWCameraX": "1540"]
        // Heard today: the offer takes the touch.
        let heard = model(args)
        _ = heard.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
        let state = try XCTUnwrap(heard.driver?.state)
        let him = try XCTUnwrap(heard.touch.things.first { $0.id == "touch-talk-brannock" }, "Brannock in view")
        XCTAssertTrue(heard.nightOfferStands, "the day's work is done: his offer stands")
        heard.talkLog.note(NightOffer.speaker, day: state.day)
        XCTAssertTrue(heard.nightOfferTakesTouch, "heard today, the touch is the word")
        XCTAssertEqual(heard.touchLabel(him, state: state), String(localized: "Sound the horn"))
        // A word of his own about today's petitions still to say: his own line comes first.
        let hinted = model(args)
        _ = hinted.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
        let hintedState = try XCTUnwrap(hinted.driver?.state)
        let hintedHim = try XCTUnwrap(hinted.touch.things.first { $0.id == "touch-talk-brannock" })
        hinted.touch.hinted.insert(NightOffer.speaker)
        XCTAssertTrue(hinted.nightOfferStands)
        XCTAssertFalse(hinted.nightOfferTakesTouch, "his own line first")
        XCTAssertTrue(hinted.touchLabel(hintedHim, state: hintedState).hasPrefix("Talk to"), "his own line comes first")
        // Gold enough to build: no offer stands, a talk as for everyone.
        var rich = args
        rich["GWGold"] = "900"
        let morning = model(rich)
        _ = morning.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
        let early = try XCTUnwrap(morning.driver?.state)
        let brannock = try XCTUnwrap(morning.touch.things.first { $0.id == "touch-talk-brannock" })
        XCTAssertFalse(morning.nightOfferStands, "something can still be bought")
        XCTAssertFalse(morning.nightOfferTakesTouch)
        XCTAssertTrue(morning.touchLabel(brannock, state: early).hasPrefix("Talk to"), "a talk as for everyone")
    }

    // MARK: - Polish B3b part 4: VoiceOver is held in the dawn wait

    /// Polish B3b part 4 (E2's L2): in the 0.6 s between the open gate and the dawn card the world takes no touch, and
    /// the VoiceOver actions are held by the same rule (`TouchHold`, read from E2's `dawnCardWaits`): a thing's element,
    /// "Walk right" and the lord's element do nothing there, exactly as a tap does nothing. The control: the same
    /// actions act on a morning with no card waiting, so the absences can fail.
    func testTheDawnWaitHoldsVoiceOverAsItHoldsTheFinger() throws {
        XCTAssertTrue(TouchHold.takesTouch(dawnCardWaits: false))
        XCTAssertFalse(TouchHold.takesTouch(dawnCardWaits: true))
        // The control: by day the three actions act.
        let day = model(["GWStage": "world", "GWSeed": "1", "GWClock": "9", "GWCameraX": "1640"])
        run(day, seconds: 0.3)
        XCTAssertTrue(day.worldTakesTouch)
        day.walkScreen(1)
        XCTAssertNotNil(day.driver?.travelTarget, "control: Walk right walks him")
        day.stopWalking()
        run(day, seconds: 0.3)
        day.activateLordElement()
        XCTAssertNotNil(day.lanternMoment, "control: the lord's element raises the lantern")
        day.lowerLanternMoment()
        run(day, seconds: 0.3)
        let door = try XCTUnwrap(day.touch.things.first { $0.id == "touch-door-hall" }, "the hall's door offers")
        day.touchSpot(door.id)
        XCTAssertEqual(day.touch.errand?.id, door.id, "control: a thing's element starts its errand")

        // Night 1 (seed 4) played to its dawn: the card waits.
        let game = model(["GWNight": "1", "GWSeed": "4", "GWCameraX": "1150"])
        var frames = 0
        while !game.dawnCardWaits && game.overlay == nil && frames < 2000 {
            game.advance(by: 0.25)
            frames += 1
        }
        XCTAssertTrue(game.dawnCardWaits, "the dawn came and the card waits")
        _ = game.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
        XCTAssertFalse(game.worldTakesTouch, "the wait takes no touch")
        // A tap does nothing ...
        let point = CGPoint(x: 437, y: 260)
        game.touchChanged(start: point, at: point, translation: .zero, in: proPoints)
        XCTAssertNil(game.touch.down, "no finger is taken")
        game.touchEnded(at: point, translation: .zero, in: proPoints)
        // ... and neither does VoiceOver.
        let ids = game.touch.things.map(\.id) + ["touch-door-hall", "touch-plot-0"]
        for id in ids { game.touchSpot(id) }
        XCTAssertNil(game.touch.errand, "no thing's element starts an errand")
        XCTAssertNil(game.touch.count, "nor brings a board")
        game.walkScreen(1)
        game.walkScreen(-1)
        XCTAssertNil(game.driver?.travelTarget, "Walk left and right do not walk him")
        game.activateLordElement()
        XCTAssertNil(game.lanternMoment, "the lord's element raises no lantern")
        XCTAssertNil(game.overlay, "and nothing opens")
        XCTAssertTrue(game.dawnCardWaits, "the card still waits")
    }
}
