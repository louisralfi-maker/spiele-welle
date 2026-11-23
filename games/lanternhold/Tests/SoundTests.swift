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
        // Polish D1: `hit` plays the creature's blow; the old `creatureHit` is retired (silent, never played).
        XCTAssertEqual(FeedbackCue.hit.sound?.id, .creatureHit)
        XCTAssertNil(FeedbackCue.creatureHit.sound)
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
        // Polish D2 0a rewrote this line (D1 had the old card pair silent): the card pair answers as the pane pair.
        XCTAssertEqual(FeedbackCue.paneOpen.sound?.id, .tap)
        XCTAssertEqual(FeedbackCue.cardOpened.sound, FeedbackCue.paneOpen.sound)
        XCTAssertEqual(FeedbackCue.cardClosed.sound, FeedbackCue.paneClose.sound)
        XCTAssertEqual(FeedbackCue.manFell.sound?.id, .manFall)
        XCTAssertEqual(FeedbackCue.manHit.sound?.id, FeedbackCue.soldierGrunts ? .grunt1 : .arrowHit)
        XCTAssertEqual(FeedbackCue.wallCracked.sound?.id, .wallCrack)
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
        // The count's clink steps are played by `FeedbackHub.countCoin` (build 3, b3-count), not by a cue (and by the tax
        // coins' chain in the gate, D2); step_2, step_3, tap_2, tap_3 and grunt_2 are their first file's partners in turn
        // (`FeedbackGate`; D2 0g added the taps' and the third step).
        let turns: Set<SoundID> = [.step2, .step3, .tap2, .tap3]
        let partners: Set<SoundID> = turns.union(FeedbackCue.soldierGrunts ? [.grunt2] : [.grunt1, .grunt2])
        for id in SoundID.allCases where !id.isLoop && !partners.contains(id) && !SoundID.coinSteps.contains(id) {
            XCTAssertTrue(used.contains(id), "\(id.rawValue) is played by some cue")
        }
    }

    func testTheHaptics() {
        // Polish D2 rewrote this line (it was light): a building standing is law 4's step 3, success then light.
        XCTAssertEqual(FeedbackCue.buildDone.haptic, .success)
        XCTAssertEqual(FeedbackCue.buildDone.hapticEchoKind, .light)
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
        XCTAssertEqual(dawn, [.coin], "the dawn counts no coins since the taxes went on foot (town-1)")
        let counted = thinner.cues(for: [], extra: [(.taxesCounted, nil), (.coin, nil)], time: 6, listenerX: 600)
        XCTAssertEqual(counted, [.taxesCounted], "counted coins, not a single coin as well")
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
        // Polish D1: a blow on a creature is the contract's `hit`, at the creature's x (the old `creatureHit` retired).
        s.creatures[0].hp = 6
        s.creatures[0].lastHit = .archer
        let arrow = watch.cues(s, balance: .standard, moving: true)
        XCTAssertEqual(arrow.map { $0.cue }, [.arrowHit, .hit])
        XCTAssertEqual(arrow.last?.x, 660)
        s.creatures[0].hp = 4
        s.creatures[0].lastHit = .guards
        XCTAssertEqual(watch.cues(s, balance: .standard, moving: true).map { $0.cue }, [.hit])
        XCTAssertTrue(watch.cues(s, balance: .standard, moving: true).isEmpty, "nothing changed, nothing heard")
    }

    /// Polish D1: a blow on a soldier is `manHit` at his x, a soldier fallen (a new name on tonight's fallen, gone from
    /// the file) is `manFell` at the x the last frame saw him; the old `creatureHit` and `soldierFell` never come.
    func testTheWatchHearsAManStruckAndAManFallen() throws {
        var watch = SoundWatch()
        var s = GameState.newRealm(seed: 3)
        s.hour = 22
        s.soldiers.removeAll()
        s.addSoldier(.guardsman, balance: .standard)
        s.addSoldier(.archer, balance: .standard)
        s.soldiers[0].x = 900
        s.soldiers[1].x = 1010
        XCTAssertTrue(watch.cues(s, balance: .standard, moving: false).isEmpty, "the first frame only primes")
        s.soldiers[0].hp -= 2
        let struck = watch.cues(s, balance: .standard, moving: false)
        XCTAssertEqual(struck.map { $0.cue }, [.manHit])
        XCTAssertEqual(struck.first?.x, 900)
        XCTAssertTrue(watch.cues(s, balance: .standard, moving: false).isEmpty, "no blow, no grunt")
        s.soldiers[1].x = 1004
        s.soldiers[1].hp += 1
        XCTAssertTrue(watch.cues(s, balance: .standard, moving: false).isEmpty, "a man healed is no blow")
        // The guardsman falls: the battle takes him off the file and writes his name on tonight's fallen.
        let fallen = s.soldiers.removeFirst()
        s.night.fallen.append(FallenSoldier(name: fallen.name, kind: fallen.kind))
        let fall = watch.cues(s, balance: .standard, moving: false)
        XCTAssertEqual(fall.map { $0.cue }, [.manFell])
        XCTAssertEqual(fall.first?.x, 900, "at his last place")
        XCTAssertTrue(watch.cues(s, balance: .standard, moving: false).isEmpty, "a man falls once")
        // A soldier sent away (no name on the fallen) is no fall.
        s.soldiers.removeAll()
        XCTAssertTrue(watch.cues(s, balance: .standard, moving: false).isEmpty)
        // Through the thinner the frame's cues keep their places; the old cues never come.
        var thinner = FeedbackThinner()
        let placed = thinner.placedCues(for: [.soldierFell(name: fallen.name)], extra: fall + struck, time: 1,
                                        listenerX: 950)
        XCTAssertEqual(placed.map { $0.cue }, [.manFell, .manHit])
        XCTAssertEqual(placed.first?.x, 900)
        XCTAssertNil(FeedbackThinner.cue(for: .soldierFell(name: fallen.name)), "the event plays nothing itself")
        for cue in placed.map({ $0.cue }) + arrowAndBlow() {
            XCTAssertNotEqual(cue, .creatureHit)
            XCTAssertNotEqual(cue, .soldierFell)
        }
    }

    private func arrowAndBlow() -> [FeedbackCue] {
        var watch = SoundWatch()
        var s = GameState.newRealm(seed: 5)
        s.creatures = [Creature(id: 3, kind: .sootling, x: 700, hp: 10, maxHP: 10)]
        _ = watch.cues(s, balance: .standard, moving: false)
        s.creatures[0].hp = 3
        s.creatures[0].lastHit = .ballista
        return watch.cues(s, balance: .standard, moving: false).map { $0.cue }
    }

    /// Polish D1 (F11): a wall that falls below half cracks once a wall and night, at its plot's x; a blow above half
    /// or a second fall below it the same night is only a blow.
    func testTheWatchHearsAWallCrackOnceANight() {
        var watch = SoundWatch()
        var s = GameState.newRealm(seed: 3)
        s.hour = 22
        s.plots[0].item = .palisade
        s.plots[0].isRubble = false
        let full = Build.maxHP(.palisade, balance: .standard)
        s.plots[0].hp = full
        _ = watch.cues(s, balance: .standard, moving: false)
        s.plots[0].hp = full * 0.6
        XCTAssertEqual(watch.cues(s, balance: .standard, moving: false).map { $0.cue }, [.wallHit])
        s.plots[0].hp = full * 0.45
        let crack = watch.cues(s, balance: .standard, moving: false)
        XCTAssertEqual(crack.map { $0.cue }, [.wallHit, .wallCracked])
        XCTAssertEqual(crack.last?.x, Realm.plots[0].x)
        s.plots[0].hp = full * 0.3
        XCTAssertEqual(watch.cues(s, balance: .standard, moving: false).map { $0.cue }, [.wallHit])
        s.plots[0].hp = full * 0.8
        _ = watch.cues(s, balance: .standard, moving: false)
        s.plots[0].hp = full * 0.4
        XCTAssertEqual(watch.cues(s, balance: .standard, moving: false).map { $0.cue }, [.wallHit],
                       "once a wall and night")
        // D1 gate M3: a replayed night (the same day, `reset`) cracks the wall again.
        watch.reset()
        s.plots[0].hp = full * 0.8
        XCTAssertTrue(watch.cues(s, balance: .standard, moving: false).isEmpty, "after a reset the frame only primes")
        s.plots[0].hp = full * 0.4
        XCTAssertEqual(watch.cues(s, balance: .standard, moving: false).map { $0.cue }, [.wallHit, .wallCracked],
                       "a replayed night cracks again")
        s.day += 1
        s.plots[0].hp = full
        _ = watch.cues(s, balance: .standard, moving: false)
        s.plots[0].hp = full * 0.2
        XCTAssertEqual(watch.cues(s, balance: .standard, moving: false).map { $0.cue }, [.wallHit, .wallCracked],
                       "the next night it cracks again")
        s.plots[0].hp = 0
        s.plots[0].isRubble = true
        XCTAssertTrue(watch.cues(s, balance: .standard, moving: false).isEmpty, "a breach is the wall's own cue")
        XCTAssertEqual(FeedbackCue.wallCracked.haptic, .medium)
        XCTAssertEqual(FeedbackCue.wallCracked.answerSize, .triumph)
    }

    /// Polish D2 part 5 (F17): Silas lights a street lamp: the watch hears it at the hour the town's lamps say, at the
    /// lamp's glass, once; never in unrest or with the hearth out; heard one screen far through the thinner.
    func testTheWatchHearsALampLit() throws {
        let first = try XCTUnwrap(TownLamps.litHour(0), "a lamp is lit in the evening")
        let glass = TownLamps.glassX(try XCTUnwrap(TownLamps.posts.first))
        var watch = SoundWatch()
        var s = GameState.newRealm(seed: 3)
        s.happiness = 50
        s.hour = first - 0.05
        _ = watch.cues(s, balance: .standard, moving: false)
        s.hour = first + 0.01
        let lit = watch.cues(s, balance: .standard, moving: false).filter { $0.cue == .lampLit }
        XCTAssertEqual(lit.count, 1)
        XCTAssertEqual(lit.first?.x, glass)
        s.hour = first + 0.02
        XCTAssertTrue(watch.cues(s, balance: .standard, moving: false).filter { $0.cue == .lampLit }.isEmpty, "once")
        var unrest = SoundWatch()
        var u = GameState.newRealm(seed: 3)
        u.happiness = 5
        u.hour = first - 0.05
        _ = unrest.cues(u, balance: .standard, moving: false)
        u.hour = first + 0.01
        XCTAssertTrue(unrest.cues(u, balance: .standard, moving: false).filter { $0.cue == .lampLit }.isEmpty,
                      "nobody lights them in unrest")
        var dark = SoundWatch()
        var d = GameState.newRealm(seed: 3)
        d.happiness = 50
        d.hearth = 0
        d.hour = first - 0.05
        _ = dark.cues(d, balance: .standard, moving: false)
        d.hour = first + 0.01
        XCTAssertTrue(dark.cues(d, balance: .standard, moving: false).filter { $0.cue == .lampLit }.isEmpty,
                      "nothing to light them with")
        XCTAssertTrue(FeedbackCue.lampLit.isPositional)
        XCTAssertEqual(FeedbackCue.lampLit.hearing, 440)
        XCTAssertEqual(FeedbackCue.lampLit.sound, SoundPlay(id: .lanternHigh, volume: 0.5))
        XCTAssertNil(FeedbackCue.lampLit.haptic)
        var thinner = FeedbackThinner()
        XCTAssertEqual(thinner.cues(for: [], extra: lit, time: 1, listenerX: glass - 300), [.lampLit], "near: heard")
        XCTAssertEqual(thinner.cues(for: [], extra: lit, time: 2, listenerX: glass - 700), [], "two screens off: not")
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
        // Step 0b (law 4's one duck rule): the screen duck no longer sits inside the beds; it rides beside them
        // (`ducks`) and the ear hears the bed at half once the hub's follower has caught up.
        let ducked = AmbienceMix.target(hour: 12, rain: 0, place: .outside, fire: 0, ducked: true)
        // D2 0f rewrote this line: what is heard is the bed under its ceiling (`bed`), halved by the screen duck.
        XCTAssertEqual(ducked.heard(.ambDay), noon.bed(.ambDay) / 2, accuracy: 1e-9)
        XCTAssertEqual(ducked.day, noon.day, accuracy: 1e-9, "the bed itself is not multiplied")
        XCTAssertTrue(ducked.ducks.screen)
        XCTAssertEqual(SoundPlace.at(x: WorldLayout.throneX, inAudience: false), .hall)
        XCTAssertEqual(SoundPlace.at(x: 700, inAudience: false), .outside)
        XCTAssertEqual(SoundPlace.at(x: 1500, inAudience: false), .castle)
        XCTAssertEqual(SoundPlace.at(x: 700, inAudience: true), .hall)
    }

    /// M12 (stage-3-interface): each place along the strip has its bed, and two beds cross over 120 px.
    func testThePlacesHaveTheirBedsAndCrossOver120Px() {
        let throat = AmbienceMix.target(hour: 12, rain: 0, place: .outside, fire: 0, x: 900)
        XCTAssertGreaterThan(throat.throat, 0.3)
        XCTAssertEqual(throat.bailey, 0)
        XCTAssertEqual(throat.valley, 0)
        let bailey = AmbienceMix.target(hour: 12, rain: 0, place: .outside, fire: 0, x: 1600)
        XCTAssertEqual(bailey.throat, 0)
        XCTAssertGreaterThan(bailey.bailey, 0.3, "the forge and the voices")
        XCTAssertLessThan(bailey.day, throat.day, "the wind falls back inside the walls")
        let valley = AmbienceMix.target(hour: 12, rain: 0, place: .outside, fire: 0, x: 3000)
        XCTAssertGreaterThan(valley.valley, 0.2, "the birds")
        XCTAssertEqual(valley.river, 0)
        let bank = AmbienceMix.target(hour: 12, rain: 0, place: .outside, fire: 0, x: 3750)
        XCTAssertGreaterThan(bank.river, 0.4, "the river at its bank")
        let night = AmbienceMix.target(hour: 0, rain: 0, place: .outside, fire: 0, x: 3000)
        XCTAssertEqual(night.valley, 0, "no birds at night")
        XCTAssertEqual(AmbienceMix.target(hour: 0, rain: 0, place: .outside, fire: 0, x: 1600).bailey, 0,
                       "the forge sleeps")
        // The crossfade at the front gate: 120 px from all Throat to all bailey, half and half at the passage.
        let gate = AmbienceMix.places(x: AmbienceMix.throatEnd)
        XCTAssertEqual(gate.throat, 0.5, accuracy: 1e-9)
        XCTAssertEqual(gate.bailey, 0.5, accuracy: 1e-9)
        XCTAssertEqual(AmbienceMix.places(x: AmbienceMix.throatEnd - 60).throat, 1, accuracy: 1e-9)
        XCTAssertEqual(AmbienceMix.places(x: AmbienceMix.throatEnd + 60).bailey, 1, accuracy: 1e-9)
        for x in stride(from: 0.0, through: 3900, by: 50) {
            let at = AmbienceMix.places(x: x)
            XCTAssertEqual(at.throat + at.bailey + at.valley, 1, accuracy: 1e-9, "\(x)")
        }
        XCTAssertEqual(AmbienceMix.target(hour: 12, rain: 0, place: .hall, fire: 0, x: 1830).bailey, 0,
                       "in the hall only the hall")
        XCTAssertEqual(AmbienceMix.target(hour: 12, rain: 0, place: .outside, fire: 0), noonWithoutPlace(),
                       "without a place the mix is as before")
    }

    private func noonWithoutPlace() -> AmbienceMix {
        var mix = AmbienceMix()
        mix.day = AmbienceMix.dayVolume
        return mix
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

    /// Step 0b: every cue, the contract's too, plays a file that is in the app and in MANIFEST.txt; the two mood cues
    /// stay silent (their crowd sounds are D4's). Polish D1 retired two on purpose, named here: `creatureHit` (`hit`
    /// plays the blow) and `soldierFell` (`manFell` plays the fall at the man's place). D2 0a rewrote the set: the card
    /// pair (D1 had it silent too) answers as the pane pair.
    func testEveryCuePlaysAFileThatShipsAndIsInTheManifest() throws {
        let folder = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        let manifestURL = folder.appendingPathComponent("Resources/Sound/MANIFEST.txt")
        var found = try? String(contentsOf: manifestURL, encoding: .utf8)
        if found == nil, let url = Bundle.main.url(forResource: "MANIFEST", withExtension: "txt") {
            found = try? String(contentsOf: url, encoding: .utf8)
        }
        let text = try XCTUnwrap(found, "MANIFEST.txt is found")
        let listed = Set(text.split(separator: "\n").compactMap { $0.split(separator: " ").first.map(String.init) })
        // Polish D1: the new files and the re-made breach are in the manifest, with their size and sha256.
        for id in [SoundID.manFall, .grunt1, .grunt2, .wallCrack, .wallBreak] {
            XCTAssertTrue(listed.contains(id.rawValue), "\(id.rawValue) is in MANIFEST.txt")
            let line = text.split(separator: "\n").first { $0.hasPrefix(id.rawValue + " ") }.map(String.init) ?? ""
            let parts = line.split(separator: " ")
            XCTAssertEqual(parts.count, 3, line)
            XCTAssertEqual(parts.last?.count, 64, "\(id.rawValue): a sha256")
        }
        let retired: Set<FeedbackCue> = [.creatureHit, .soldierFell]
        let silentOnPurpose: Set<FeedbackCue> = Set([.happinessUp, .happinessDown]).union(retired)
        for cue in retired {
            XCTAssertNil(cue.sound, "\(cue) is retired")
            XCTAssertNil(cue.haptic, "\(cue) is retired")
        }
        for cue in FeedbackCue.allCases where !silentOnPurpose.contains(cue) {
            let sound = try XCTUnwrap(cue.sound, "\(cue) is not silent")
            XCTAssertGreaterThan(sound.volume, 0, "\(cue)")
            XCTAssertTrue(listed.contains(sound.id.rawValue), "\(cue): \(sound.id.rawValue) is in MANIFEST.txt")
            let url = Bundle.main.url(forResource: sound.id.rawValue, withExtension: "wav", subdirectory: "Sound")
                ?? Bundle.main.url(forResource: sound.id.rawValue, withExtension: "wav")
            XCTAssertNotNil(url, "\(cue): \(sound.id.rawValue).wav is in the app")
        }
        let contract: [FeedbackCue] = [.lanternUp, .lanternDown, .paneOpen, .paneClose, .bubbleClose, .plaquePress,
                                       .boardSet, .hit, .manHit, .dawnGate, .buildStood, .manFell, .dawnHeld,
                                       .dawnToll, .wallCracked]
        for cue in contract {
            XCTAssertNotNil(cue.answerSize, "\(cue) has its step on the ladder")
            XCTAssertNotNil(cue.sound, "\(cue)")
        }
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
        // Polish D2 0b rewrote the budget (it was 4,000,000 over the SoundID files only): the director's call after D1
        // is 5,000,000 bytes for every wav in Resources/Sound, every file counted (WindSound's two as well), until D3 has
        // re-made the beds. The folder is summed where the sources are, and the app's own wav files as well.
        XCTAssertLessThan(total, 5_000_000, "the SoundID files alone")
        let folder = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Resources/Sound")
        let manager = FileManager.default
        let sources = ((try? manager.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)) ?? [])
            .filter { $0.pathExtension == "wav" }
        var shipped: [String: URL] = [:]
        for url in (Bundle.main.urls(forResourcesWithExtension: "wav", subdirectory: nil) ?? [])
            + (Bundle.main.urls(forResourcesWithExtension: "wav", subdirectory: "Sound") ?? []) {
            shipped[url.lastPathComponent] = url
        }
        let names = Set(SoundID.allCases.map { $0.rawValue + ".wav" } + WindSound.files.map { $0 + ".wav" })
        for (label, files) in [("the folder", sources), ("the app", Array(shipped.values))] where !files.isEmpty {
            var sum = 0
            for url in files {
                sum += try Data(contentsOf: url).count
            }
            XCTAssertTrue(names.isSubset(of: Set(files.map { $0.lastPathComponent })), "\(label) holds every sound")
            XCTAssertGreaterThanOrEqual(sum, total, label)
            XCTAssertLessThan(sum, 5_000_000, "every wav in \(label) together stays under 5,000,000 bytes (\(sum))")
        }
        XCTAssertFalse(shipped.isEmpty, "the app's wav files are found")
        for id in [SoundID.manFall, .grunt1, .grunt2, .wallCrack, .wallBreak] {
            let url = Bundle.main.url(forResource: id.rawValue, withExtension: "wav", subdirectory: "Sound")
                ?? Bundle.main.url(forResource: id.rawValue, withExtension: "wav")
            XCTAssertNotNil(url, "\(id.rawValue).wav ships")
        }
    }
}
