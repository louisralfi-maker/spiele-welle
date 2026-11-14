import Foundation
import XCTest
@testable import Lanternhold

/// Sound and haptics (DESIGN.md "Sound and haptics"): the cues' sounds and haptics, the throttles, `SoundWatch`
/// reading cues off the realm's state, the ambience's mix, the launch rule and the files in the app.
final class SoundTests: XCTestCase {
    // MARK: - The mapping

    func testTheMomentsHaveTheirSounds() {
        XCTAssertEqual(FeedbackCue.horn.sound?.id, .horn)
        XCTAssertEqual(FeedbackCue.firstLight.sound?.id, .bell)
        XCTAssertEqual(FeedbackCue.volley.sound?.id, .bow)
        XCTAssertEqual(FeedbackCue.arrowHit.sound?.id, .arrowHit)
        XCTAssertEqual(FeedbackCue.creatureHit.sound?.id, .creatureHit)
        XCTAssertEqual(FeedbackCue.creatureDissolved.sound?.id, .dissolve)
        XCTAssertEqual(FeedbackCue.wallHit.sound?.id, .wallHit)
        XCTAssertEqual(FeedbackCue.wallBroken.sound?.id, .wallBreak)
        XCTAssertEqual(FeedbackCue.gate.sound?.id, .gate)
        XCTAssertEqual(FeedbackCue.coin.sound?.id, .coin)
        XCTAssertEqual(FeedbackCue.paid.sound?.id, .coins)
        XCTAssertEqual(FeedbackCue.taxesCounted.sound?.id, .coins)
        XCTAssertEqual(FeedbackCue.buildOrdered.sound?.id, .buildStart)
        XCTAssertEqual(FeedbackCue.buildDone.sound?.id, .buildDone)
        XCTAssertEqual(FeedbackCue.brazierLit.sound?.id, .lantern)
        XCTAssertEqual(FeedbackCue.step.sound?.id, .step1)
        XCTAssertEqual(FeedbackCue.audienceOpened.sound?.id, .parchment)
        XCTAssertEqual(FeedbackCue.cardOpened.sound?.id, .tap)
        XCTAssertEqual(FeedbackCue.choiceMade.sound?.id, .seal)
        XCTAssertEqual(FeedbackCue.refused.sound?.id, .decline)
        for cue in FeedbackCue.allCases {
            guard let sound = cue.sound else { continue }
            XCTAssertFalse(sound.id.isLoop, "\(cue) plays a one-shot")
            XCTAssertGreaterThan(sound.volume, 0, "\(cue)")
            XCTAssertLessThanOrEqual(sound.volume, 1, "\(cue)")
            XCTAssertTrue((0.5...2).contains(sound.rate), "\(cue)")
        }
        let used = Set(FeedbackCue.allCases.compactMap { $0.sound?.id })
        for id in SoundID.allCases where !id.isLoop && id != .step2 {
            XCTAssertTrue(used.contains(id), "\(id.rawValue) is played by some cue")
        }
    }

    func testTheHaptics() {
        XCTAssertEqual(FeedbackCue.buildDone.haptic, .light)
        XCTAssertEqual(FeedbackCue.coin.haptic, .soft)
        XCTAssertEqual(FeedbackCue.wallHit.haptic, .medium)
        XCTAssertEqual(FeedbackCue.wallBroken.haptic, .heavy)
        XCTAssertEqual(FeedbackCue.hearthHit.haptic, .heavy, "creatures break through to the hearth")
        XCTAssertEqual(FeedbackCue.horn.haptic, .rigid)
        XCTAssertEqual(FeedbackCue.taxesCounted.haptic, .success, "the dawn survived")
        XCTAssertEqual(FeedbackCue.defeat.haptic, .error)
        XCTAssertNil(FeedbackCue.volley.haptic, "no haptic for every arrow")
        XCTAssertGreaterThan(FeedbackCue.coin.hapticGap, 0, "the coin's tap is throttled")
    }

    // MARK: - Throttling

    func testTheThrottleKeepsItsGapPerKey() {
        var throttle = SoundThrottle()
        XCTAssertTrue(throttle.allow("bow", gap: 0.1, now: 1))
        XCTAssertFalse(throttle.allow("bow", gap: 0.1, now: 1.05))
        XCTAssertTrue(throttle.allow("coin", gap: 0.1, now: 1.05), "another sound has its own gap")
        XCTAssertTrue(throttle.allow("bow", gap: 0.1, now: 1.11))
        XCTAssertTrue(throttle.allow("bow", gap: 0.1, now: 0.2), "a clock that went back lets it through")
        var many = SoundThrottle()
        var heard = 0
        for k in 0..<60 {
            if many.allow(SoundID.bow.rawValue, gap: SoundID.bow.minimumInterval, now: Double(k) / 60) { heard += 1 }
        }
        XCTAssertTrue((8...10).contains(heard), "sixty bows in a second sound about ten times, not \(heard)")
        XCTAssertGreaterThan(SoundID.horn.minimumInterval, 1)
    }

    func testTheThinnerTakesTheWatchsCues() {
        var thinner = FeedbackThinner()
        let far = thinner.cues(for: [], extra: [(.wallHit, 2000), (.coin, nil)], time: 1, listenerX: 600)
        XCTAssertEqual(far, [.coin], "a wall hit far away is not heard")
        let near = thinner.cues(for: [], extra: [(.wallHit, 640)], time: 2, listenerX: 600)
        XCTAssertEqual(near, [.wallHit])
        XCTAssertEqual(thinner.cues(for: [], extra: [(.wallHit, 640)], time: 2.1, listenerX: 600), [],
                       "wall hits wait their gap")
        let dawn = thinner.cues(for: [.dawn(day: 3)], extra: [(.coin, nil)], time: 5, listenerX: 600)
        XCTAssertEqual(dawn, [.taxesCounted], "the dawn's coins, not a single coin as well")
        XCTAssertEqual(thinner.cues(for: [.horn], time: 9, listenerX: 600), [.horn], "the old call still works")
    }

    // MARK: - SoundWatch

    func testTheWatchHearsGoldWallsAndCreatures() {
        var watch = SoundWatch()
        var s = GameState.newRealm(seed: 3)
        s.hour = 21
        s.king.x = 700
        s.creatures = [Creature(id: 7, kind: .sootling, x: 660, hp: 10, maxHP: 10)]
        XCTAssertTrue(watch.cues(s, balance: .standard, moving: true).isEmpty, "the first frame only primes")
        s.gold += 5
        XCTAssertEqual(watch.cues(s, balance: .standard, moving: true).map { $0.cue }, [.coin])
        s.gold -= 12
        XCTAssertEqual(watch.cues(s, balance: .standard, moving: true).map { $0.cue }, [.paid])
        s.plots[0].hp -= 3
        let hit = watch.cues(s, balance: .standard, moving: true)
        XCTAssertEqual(hit.map { $0.cue }, [.wallHit])
        XCTAssertEqual(hit.first?.x, Realm.plots[0].x)
        s.creatures[0].hp = 6
        s.creatures[0].lastHit = .archer
        XCTAssertEqual(watch.cues(s, balance: .standard, moving: true).map { $0.cue }, [.arrowHit, .creatureHit])
        s.creatures[0].hp = 4
        s.creatures[0].lastHit = .guards
        XCTAssertEqual(watch.cues(s, balance: .standard, moving: true).map { $0.cue }, [.creatureHit])
        XCTAssertTrue(watch.cues(s, balance: .standard, moving: true).isEmpty, "nothing changed, nothing heard")
    }

    func testTheGateShutsAtNightfall() {
        var watch = SoundWatch()
        var s = GameState.newRealm(seed: 3)
        s.hour = 19.98
        _ = watch.cues(s, balance: .standard, moving: true)
        s.hour = 20.01
        XCTAssertEqual(watch.cues(s, balance: .standard, moving: true).map { $0.cue }, [.gate])
        s.hour = 20.05
        XCTAssertTrue(watch.cues(s, balance: .standard, moving: true).isEmpty)
    }

    func testTheLordsStepsFollowHisWalk() {
        var watch = SoundWatch()
        var s = GameState.newRealm(seed: 3)
        s.king.x = 1000
        _ = watch.cues(s, balance: .standard, moving: true)
        s.king.velocity = Balance.standard.kingWalkSpeed
        var steps = 0
        for _ in 0..<120 {
            s.king.x += Balance.standard.kingWalkSpeed / 60
            steps += watch.cues(s, balance: .standard, moving: true).filter { $0.cue == .step }.count
        }
        // Two seconds of walking, 72 px: the first step soon after setting off, then one every 18 px.
        XCTAssertEqual(steps, 4)
        s.king.x += 400
        XCTAssertTrue(watch.cues(s, balance: .standard, moving: true).isEmpty, "a jump is no step")
        s.king.x += 10
        XCTAssertTrue(watch.cues(s, balance: .standard, moving: false).isEmpty, "no steps under a card")
        watch.reset()
        XCTAssertTrue(watch.cues(s, balance: .standard, moving: true).isEmpty, "after a reset it primes again")
    }

    // MARK: - Ambience

    func testTheAmbienceFollowsDayNightRainAndPlace() {
        let noon = AmbienceMix.target(hour: 12, rain: 0, place: .outside, fire: 0)
        XCTAssertGreaterThan(noon.day, 0)
        XCTAssertEqual(noon.night, 0)
        XCTAssertEqual(noon.rain, 0)
        XCTAssertEqual(noon.hall, 0)
        let midnight = AmbienceMix.target(hour: 0, rain: 0, place: .outside, fire: 0)
        XCTAssertEqual(midnight.day, 0)
        XCTAssertGreaterThan(midnight.night, 0)
        let dusk = AmbienceMix.target(hour: 19.5, rain: 0, place: .outside, fire: 0)
        XCTAssertGreaterThan(dusk.day, 0)
        XCTAssertGreaterThan(dusk.night, 0, "the night fades in through the dusk")
        let wet = AmbienceMix.target(hour: 12, rain: 0.8, place: .outside, fire: 0)
        XCTAssertGreaterThan(wet.rain, 0, "rain only while it rains")
        let hall = AmbienceMix.target(hour: 12, rain: 0, place: .hall, fire: 0)
        XCTAssertGreaterThan(hall.hall, hall.day * 3, "in the great hall the hall is heard, the wind only faintly")
        let ducked = AmbienceMix.target(hour: 12, rain: 0, place: .outside, fire: 0, ducked: true)
        XCTAssertEqual(ducked.day, noon.day / 2, accuracy: 1e-9)
        XCTAssertEqual(SoundPlace.at(x: WorldLayout.throneX, inAudience: false), .hall)
        XCTAssertEqual(SoundPlace.at(x: 700, inAudience: false), .outside)
        XCTAssertEqual(SoundPlace.at(x: 1500, inAudience: false), .castle)
        XCTAssertEqual(SoundPlace.at(x: 700, inAudience: true), .hall)
    }

    func testFireIsHeardNearBraziersAndTheBeacon() {
        var s = GameState.newRealm(seed: 3)
        s.hour = 22
        XCTAssertEqual(AmbienceMix.fireLevel(s, balance: .standard, x: 100), 0, "no fire out at the Gloom")
        s.beaconLit = true
        XCTAssertGreaterThan(AmbienceMix.fireLevel(s, balance: .standard, x: Realm.beaconX), 0.9)
        XCTAssertEqual(AmbienceMix.fireLevel(s, balance: .standard, x: Realm.beaconX - 400), 0)
        var level = 0.0
        for _ in 0..<600 { level = AmbienceMix.approach(level, 0.5, dt: 1.0 / 60) }
        XCTAssertEqual(level, 0.5, "the crossfade settles on its target")
        XCTAssertEqual(AmbienceMix.approach(0.2, 0.5, dt: 0), 0.2)
        XCTAssertGreaterThan(AmbienceMix.approach(0, 0.5, dt: 0.1), 0)
        XCTAssertLessThan(AmbienceMix.approach(0, 0.5, dt: 0.1), 0.1, "no jump: a fade over about a second")
    }

    @MainActor
    func testTheGameFeedsTheHubWithoutTouchingTheSimulation() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("sound-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: directory) }
        let args = DebugArgs(values: ["GWReset": "YES", "GWSkipOnboarding": "YES", "GWNight": "2", "GWSeed": "4"])
        let game = GameModel(args: args, kind: .world, store: SaveStore(directory: directory))
        let silent = SilentFeedback()
        game.installFeedback(silent)
        let twin = GameModel(args: args, kind: .world, store: SaveStore(directory: directory))
        for _ in 0..<240 {
            game.advance(by: 1.0 / 60)
            twin.advance(by: 1.0 / 60)
        }
        let mix = try XCTUnwrap(silent.lastMix, "the hub hears the ambience every frame")
        XCTAssertGreaterThan(mix.night, mix.day, "night 2's ambience is the night's")
        XCTAssertEqual(game.driver?.state, twin.driver?.state, "the hub changes nothing in the realm")
    }

    // MARK: - The launch rule and the files

    func testSoundIsOffInTestsUnlessAskedFor() {
        XCTAssertTrue(SoundDirector.allowed(args: DebugArgs(values: [:]), environment: [:]), "a plain launch plays")
        XCTAssertFalse(SoundDirector.allowed(args: DebugArgs(values: ["GWReset": "YES"]), environment: [:]),
                       "a UI test's launch is silent")
        XCTAssertTrue(SoundDirector.allowed(args: DebugArgs(values: ["GWReset": "YES", "GWSound": "YES"]),
                                            environment: [:]))
        XCTAssertFalse(SoundDirector.allowed(args: DebugArgs(values: ["GWSound": "NO"]), environment: [:]))
        XCTAssertFalse(SoundDirector.allowed(args: DebugArgs(values: [:]),
                                             environment: ["XCTestConfigurationFilePath": "/x"]))
        XCTAssertTrue(DebugArgs.keys.contains("GWSound"))
        XCTAssertEqual(DebugArgs(values: ["GWSound": "YES"]).sound, true)
        XCTAssertNil(DebugArgs(values: [:]).sound)
    }

    func testEveryFileIsInTheAppAndSmall() throws {
        var total = 0
        for id in SoundID.allCases {
            let url = Bundle.main.url(forResource: id.rawValue, withExtension: "wav", subdirectory: "Sound")
                ?? Bundle.main.url(forResource: id.rawValue, withExtension: "wav")
            let found = try XCTUnwrap(url, "\(id.rawValue).wav is in the app")
            let data = try Data(contentsOf: found)
            total += data.count
            // RIFF/WAVE, PCM, mono, 16 bit, 22.05 kHz.
            XCTAssertEqual(String(decoding: data.prefix(4), as: UTF8.self), "RIFF")
            XCTAssertEqual(String(decoding: data[8..<12], as: UTF8.self), "WAVE")
            let channels = UInt16(data[22]) | UInt16(data[23]) << 8
            let rate = UInt32(data[24]) | UInt32(data[25]) << 8 | UInt32(data[26]) << 16 | UInt32(data[27]) << 24
            let bits = UInt16(data[34]) | UInt16(data[35]) << 8
            XCTAssertEqual(channels, 1, id.rawValue)
            XCTAssertEqual(rate, 22050, id.rawValue)
            XCTAssertEqual(bits, 16, id.rawValue)
        }
        XCTAssertLessThan(total, 3_200_000, "all sounds together stay under about 3 MB")
    }
}
