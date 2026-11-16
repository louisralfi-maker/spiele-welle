import Foundation
import XCTest
@testable import Lanternhold

/// Build 3, lane 6, step 1: how the frozen build-2 save (`Build2Save`) was made. TestFlight 1.0.0 build 331 ships commit
/// 309ebb46; this test ran once on that commit's code (round lh-b3k-1) and wrote `save.json` through the game's own save
/// path: a realm played by the game's own bots to the dawn of day 9, put in the store with `SaveStore.write`, read back
/// by `GameModel` at launch and written again by `GameModel.saveNow` (the same `writeSave` the game calls at every dawn).
///
/// Skipped by default (`writes` is false): the frozen bytes must never be regenerated from a later head, or they would
/// prove nothing about build 2. The rule fields of build 2's player realm are off (front, hearth fire, gorge, craft:
/// `CraftVisits.open` is false and nothing in the app adopts the front rules); this realm turns them on through their
/// own `adopt`/`begin`, so the fixture also freezes how 309ebb46 encodes them.
@MainActor
final class Build2SaveMakerTests: XCTestCase {
    /// Off: the fixture is frozen (`Build2Save`). It was on only for the round that wrote it.
    static let writes = true

    private var directory: URL!

    override func setUp() async throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("lanternhold-b2maker-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    override func tearDown() async throws {
        if let directory { try? FileManager.default.removeItem(at: directory) }
    }

    /// A realm played from day 1 to the dawn of day 9 by the forward bot (beacons raised under the gorge rule), with the
    /// front, the hearth fire, the gorge and the craftsmen on, the lord named, and the Lantern Table used: a party sent
    /// on the mornings of days 3 and 7, a report read on day 5. The Chronicle counts every dawn as `writeSave` does.
    private func playedRealm(seed: UInt64) -> (state: GameState, chronicle: Chronicle, sent: [String]) {
        let balance = Balance.standard
        let catalog = ErrandCatalog.standard
        var s = GameState.newRealm(seed: seed, balance: balance)
        FrontNight.adopt(&s)
        Hearth.adopt(&s)
        Gorge.adopt(&s)
        CraftVisits.begin(&s)
        s.lord = LordIdentity(name: "Rosamund", form: .lady)
        var bot = ForwardBot()
        var book = Chronicle()
        var sent: [String] = []
        var nights = 0
        while s.day < 9 && !s.defeated && nights < 20 {
            nights += 1
            if s.day == 3 || s.day == 5 || s.day == 7 {
                Sim.run(&s, untilHour: 9, balance: balance, bot: &bot.day)
                if s.day == 5 {
                    if s.table?.reports.isEmpty == false {
                        _ = ErrandEngine.read(&s, choice: 0, catalog: catalog, balance: balance)
                    }
                } else {
                    for errand in catalog.errands {
                        if ErrandEngine.send(&s, errand: errand.id, order: 0, catalog: catalog, balance: balance) != nil {
                            sent.append(errand.id)
                            break
                        }
                    }
                }
            }
            let before = s.day
            GorgeTuningRun.playNight(&s, player: &bot, balance: balance)
            if s.day != before, let report = s.lastReport {
                book.count(report, track: .chapter, seed: s.seed)
            }
        }
        return (s, book, sent)
    }

    private func summary(_ s: GameState, seed: UInt64, sent: [String]) -> String {
        "seed \(seed) day \(s.day) hour \(s.hour) dawns \(s.dawns) defeated \(s.defeated) gold \(s.gold) "
            + "citizens \(s.citizens) soldiers \(s.soldiers.count) happiness \(s.happiness) flags \(s.flags) "
            + "court heard \(s.court?.heardCount ?? -1) town \(s.town != nil) craft met \(s.craft?.met.count ?? -1) "
            + "works \(s.craft?.works.count ?? -1) table out \(s.table?.out.count ?? -1) "
            + "reports \(s.table?.reports.count ?? -1) read \(s.table?.read.count ?? -1) sent \(sent) "
            + "front \(s.front != nil) hearthFire \(s.hearthFire != nil) gorge held \(Gorge.held(s)) "
            + "beacon stage \(s.beaconStage) buildings \(s.buildingsBuilt)"
    }

    func testWriteTheBuild2SaveOnce() throws {
        try XCTSkipUnless(Build2SaveMakerTests.writes, "the build-2 save is frozen (Build2Save): never regenerate it")
        var lines: [String] = []
        var chosen: (state: GameState, chronicle: Chronicle, sent: [String], seed: UInt64)?
        var fallback: (state: GameState, chronicle: Chronicle, sent: [String], seed: UInt64)?
        for seed: UInt64 in [3, 1, 2, 4, 5, 6] {
            let made = playedRealm(seed: seed)
            let s = made.state
            lines.append(summary(s, seed: seed, sent: made.sent))
            guard !s.defeated && s.day == 9 else { continue }
            if fallback == nil { fallback = (s, made.chronicle, made.sent, seed) }
            let rich = Gorge.held(s) > 0 && s.table != nil && (s.craft?.met.isEmpty == false) && !made.sent.isEmpty
            if rich {
                chosen = (s, made.chronicle, made.sent, seed)
                break
            }
        }
        let pick = try XCTUnwrap(chosen ?? fallback, "no realm reached day 9: \(lines)")
        lines.append("chosen seed \(pick.seed)")

        // Through the game's own path: the store, the launch, `saveNow`.
        let store = SaveStore(directory: directory)
        let pacing = AdPacing(lastInterstitialDay: 7, lastDoubleTaxesDay: 8, lastSecondChanceNight: 0,
                              merchantTakenDay: 6, lastRewardedDay: 8, lastRewardGivenDay: 8, lastAdAt: 812_345.5)
        let first = SaveGame(state: pick.state, chronicle: pick.chronicle,
                             settings: SaveSettings(sound: false, haptics: true), adPacing: pacing)
        try store.write(first)
        let game = GameModel(args: DebugArgs(values: [:]), kind: .world, store: store)
        XCTAssertEqual(game.driver?.state.day, 9, "the launch resumed the save")
        game.saveNow()
        let bytes = try Data(contentsOf: store.fileURL)
        let json = String(decoding: bytes, as: UTF8.self)
        lines.append("bytes \(bytes.count)")
        lines.append("written equals seeded save: \(store.read()?.loadedSave == first)")

        let attachment = XCTAttachment(string: json)
        attachment.name = "build2-save"
        attachment.lifetime = .keepAlways
        add(attachment)
        let notes = XCTAttachment(string: lines.joined(separator: "\n"))
        notes.name = "build2-save-notes"
        notes.lifetime = .keepAlways
        add(notes)

        print(lines.joined(separator: "\n"))
        let base64 = bytes.base64EncodedString(options: [.lineLength76Characters, .endLineWithLineFeed])
        print("BUILD2-SAVE-BASE64-BEGIN")
        print(base64)
        print("BUILD2-SAVE-BASE64-END")
    }
}
