import Foundation
import XCTest
@testable import Lanternhold

/// Polish step 0b (polish-audit.md law 4): the cue contract's levels on the ladder, the one duck rule, space (fall-off
/// and pan), the chain, the plaque's haptic behind the Haptics switch, the dawn verdict's tolls and the title's beds.
final class SoundMixTests: XCTestCase {
    private static let contract: [FeedbackCue] = [.lanternUp, .lanternDown, .paneOpen, .paneClose, .bubbleClose,
                                                  .plaquePress, .boardSet, .hit, .manHit, .dawnGate, .buildStood,
                                                  .manFell, .dawnHeld, .dawnToll]

    // MARK: - The ladder

    func testTheLaddersFourSizes() {
        XCTAssertEqual(AnswerSize.allCases.map(\.rawValue), [1, 2, 3, 4])
        XCTAssertEqual(AnswerSize.touch.band, -24 ... -20)
        XCTAssertEqual(AnswerSize.deed.band, -20 ... -16)
        XCTAssertEqual(AnswerSize.triumph.band, -16 ... -13)
        XCTAssertEqual(AnswerSize.realm.band, -12 ... -10)
        XCTAssertTrue(AnswerSize.touch.jitters)
        XCTAssertFalse(AnswerSize.triumph.jitters, "step 3 is never randomised")
        XCTAssertFalse(AnswerSize.realm.jitters)
        XCTAssertEqual(AnswerSize.triumph.bedDuck, 0.7)
        XCTAssertEqual(AnswerSize.realm.bedDuck, 0.25)
        XCTAssertNil(AnswerSize.touch.bedDuck)
        for size in AnswerSize.allCases {
            let level = AnswerSize.level(fileRMS: -16, volume: size.volume(fileRMS: -16))
            if size.band.upperBound <= -16 {
                XCTAssertEqual(level, (size.band.lowerBound + size.band.upperBound) / 2, accuracy: 1e-9, "\(size)")
            } else {
                XCTAssertEqual(size.volume(fileRMS: -16), 1, "a quiet file is played full, never over 1")
            }
        }
        XCTAssertNil(FeedbackCue.horn.answerSize, "the cues made before the ladder keep their levels until D2")
    }

    /// The law's stand-ins as it names them, and every chosen stand-in inside its step's band (inventory.md's measure:
    /// the file's whole RMS + 20 log10 volume). The law's own numbers stand where that measure reads them outside.
    func testTheContractsStandInsSitOnTheirStep() throws {
        XCTAssertEqual(FeedbackCue.paneOpen.sound, SoundPlay(id: .tap, volume: 0.55))
        XCTAssertEqual(FeedbackCue.paneClose.sound, SoundPlay(id: .tap, volume: 0.45, rate: 0.85))
        XCTAssertEqual(FeedbackCue.bubbleClose.sound, SoundPlay(id: .tap, volume: 0.3, rate: 0.85))
        XCTAssertEqual(FeedbackCue.lanternUp.sound?.volume, 0.55)
        XCTAssertEqual(FeedbackCue.lanternDown.sound?.volume, 0.4)
        XCTAssertEqual(FeedbackCue.boardSet.sound, SoundPlay(id: .knock, volume: 0.4, rate: 0.62))
        XCTAssertEqual(FeedbackCue.dawnGate.sound, SoundPlay(id: .gate, volume: 0.6, rate: 1.05))
        XCTAssertEqual(FeedbackCue.dawnHeld.sound, SoundPlay(id: .bell, volume: 0.5, rate: 0.9))
        XCTAssertEqual(FeedbackCue.dawnToll.sound?.id, .bell)
        XCTAssertEqual(FeedbackCue.dawnToll.sound?.rate, 0.55)
        XCTAssertEqual(FeedbackCue.lanternRaised.sound, SoundPlay(id: .lantern, volume: 0.8, rate: 1.3),
                       "the night raise keeps lantern.wav at rate 1.3")
        let lawOutsideTheMeasure: Set<FeedbackCue> = [.bubbleClose, .dawnGate, .dawnHeld, .dawnToll]
        for cue in Self.contract where !lawOutsideTheMeasure.contains(cue) {
            let sound = try XCTUnwrap(cue.sound)
            let size = try XCTUnwrap(cue.answerSize)
            let level = AnswerSize.level(fileRMS: try Self.fileRMS(sound.id), volume: sound.volume)
            // 0.1 dB: the measure's own rounding (law 4's lantern_down 0.4 on tap.wav lands at -24.01).
            XCTAssertGreaterThanOrEqual(level, size.band.lowerBound - 0.1, "\(cue) at \(level) dBFS")
            XCTAssertLessThanOrEqual(level, size.band.upperBound + 0.1, "\(cue) at \(level) dBFS")
            XCTAssertTrue((0.5...2).contains(sound.rate), "\(cue)")
        }
    }

    func testTheContractsHaptics() {
        XCTAssertEqual(FeedbackCue.lanternUp.haptic, .soft)
        XCTAssertEqual(FeedbackCue.lanternUp.hapticStrength, 0.5)
        XCTAssertNil(FeedbackCue.lanternDown.haptic, "law 4: none for the lantern down")
        XCTAssertNil(FeedbackCue.bubbleClose.haptic, "law 4: none for the bubble close")
        XCTAssertEqual(FeedbackCue.plaquePress.haptic, .selection)
        XCTAssertEqual(FeedbackCue.buildStood.haptic, .success)
        XCTAssertEqual(FeedbackCue.dawnHeld.haptic, .success)
        XCTAssertEqual(FeedbackCue.manFell.haptic, .heavy)
        XCTAssertNil(FeedbackCue.hit.haptic, "no haptic for every blow")
        for cue in Self.contract where cue.answerSize == .touch && cue.haptic == .soft {
            XCTAssertTrue((0.3...0.5).contains(cue.hapticStrength), "\(cue): law 4's soft 0.3-0.5")
        }
        XCTAssertEqual(FeedbackCue.coin.hapticStrength, 0.6, "today's soft tick stays 0.6")
        XCTAssertEqual(FeedbackCue.horn.hapticStrength, 1)
    }

    // MARK: - The plaque behind the Haptics switch

    @MainActor
    func testThePlaquePressGivesNoHapticWithHapticsOff() throws {
        XCTAssertNil(FeedbackGate.haptic(.plaquePress, hapticsOn: false))
        XCTAssertEqual(FeedbackGate.haptic(.plaquePress, hapticsOn: true), .selection)
        var gate = FeedbackGate()
        let off = gate.answer(.plaquePress, soundOn: true, hapticsOn: false, now: 1)
        XCTAssertNil(off.haptic, "Haptics off: no tick")
        XCTAssertEqual(off.sound?.id, .tap, "the sound still plays")
        XCTAssertEqual(gate.answer(.plaquePress, soundOn: true, hapticsOn: true, now: 2).haptic, .selection)
        XCTAssertNil(gate.answer(.plaquePress, soundOn: false, hapticsOn: true, now: 3).sound, "Sound off: silent")

        // Through the game's own switch (the pause sheet's Haptics toggle) to the hub.
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("mix-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: directory) }
        let args = DebugArgs(values: ["GWReset": "YES", "GWSkipOnboarding": "YES", "GWSeed": "4"])
        let game = GameModel(args: args, kind: .world, store: SaveStore(directory: directory))
        let silent = SilentFeedback()
        game.installFeedback(silent)
        game.setHaptics(false)
        let before = silent.felt.count
        game.feedback.play(.plaquePress)
        XCTAssertEqual(silent.played.last, .plaquePress)
        XCTAssertEqual(silent.felt.count, before, "Haptics off silences the plaque")
        game.setHaptics(true)
        game.feedback.play(.plaquePress)
        XCTAssertEqual(silent.felt.count, before + 1)
        XCTAssertEqual(silent.felt.last, .selection)
    }

    func testTheGateKeepsStepThreeSteady() {
        var gate = FeedbackGate()
        XCTAssertTrue(SoundID.wallHit.varies)
        XCTAssertFalse(gate.answer(.manFell, soundOn: true, hapticsOn: true, now: 1).jitter, "step 3 never varies")
        XCTAssertTrue(gate.answer(.wallHit, soundOn: true, hapticsOn: true, now: 2).jitter, "old cues as before")
        XCTAssertTrue(gate.answer(.hit, soundOn: true, hapticsOn: true, now: 3).jitter)
        let first = gate.answer(.step, soundOn: true, hapticsOn: true, now: 4).sound?.id
        let second = gate.answer(.step, soundOn: true, hapticsOn: true, now: 5).sound?.id
        XCTAssertEqual(first, .step1)
        XCTAssertEqual(second, .step2, "the steps still alternate")
        XCTAssertEqual(gate.answer(.paneOpen, soundOn: true, hapticsOn: true, now: 6).sound?.id, .tap)
        XCTAssertNil(gate.answer(.paneClose, soundOn: true, hapticsOn: true, now: 6.01).sound, "tap's throttle holds")
    }

    // MARK: - Space

    func testSpaceFallsOffAndPans() throws {
        XCTAssertEqual(SoundSpace.gain(distance: 0, hearing: 240), 1)
        XCTAssertEqual(SoundSpace.gain(distance: 120, hearing: 240), 0.5, accuracy: 1e-12)
        XCTAssertEqual(SoundSpace.gain(distance: -120, hearing: 240), 0.5, accuracy: 1e-12)
        XCTAssertEqual(SoundSpace.gain(distance: 240, hearing: 240), 0.35, accuracy: 1e-12, "0.35 at the hearing")
        // Polish D1 rewrote this line (the edge of hearing): far beyond the hearing a cue is gone, not held at 0.35.
        XCTAssertEqual(SoundSpace.gain(distance: 900, hearing: 240), 0, "far beyond it: nothing")
        XCTAssertEqual(SoundSpace.gain(distance: 900, hearing: .infinity), 1, "an everywhere cue is not faded")
        let lord = 1500.0
        XCTAssertEqual(SoundSpace.pan(x: lord, listenerX: lord), 0)
        XCTAssertEqual(SoundSpace.pan(x: lord + 160, listenerX: lord), 0.5, accuracy: 1e-12, "east of him: right")
        XCTAssertEqual(SoundSpace.pan(x: lord - 160, listenerX: lord), -0.5, accuracy: 1e-12, "west of him: left")
        XCTAssertEqual(SoundSpace.pan(x: lord + 224, listenerX: lord), 0.7, accuracy: 1e-12)
        XCTAssertEqual(SoundSpace.pan(x: lord + 2000, listenerX: lord), 0.7, "clamped at 0.7")
        XCTAssertEqual(SoundSpace.pan(x: lord - 2000, listenerX: lord), -0.7)
        // D1 gate M1 rewrote the blow's lines below for its hearing of one screen (440 px; it was 240).
        let blow = FeedbackCue.hit.hearing
        XCTAssertEqual(blow, 440)
        XCTAssertEqual(FeedbackCue.manHit.hearing, 440)
        let near = try XCTUnwrap(SoundSpace.place(.hit, x: lord + 100, listenerX: lord))
        XCTAssertEqual(near.gain, 1 - 100.0 / blow, accuracy: 1e-12)
        XCTAssertEqual(near.pan, 100.0 / 320, accuracy: 1e-12)
        // Polish D1 rewrote these lines: beyond its hearing a cue fades over the edge and is gone at 1.5 x (it was cut
        // at once); a cue that is not positional plays as made, never panned (0b's L4; it was panned to -0.7).
        XCTAssertNotNil(SoundSpace.place(.hit, x: lord + blow + 1, listenerX: lord), "just beyond its hearing: heard")
        XCTAssertNil(SoundSpace.place(.hit, x: lord + blow * 1.5, listenerX: lord), "at 1.5 x its hearing: not played")
        XCTAssertEqual(SoundSpace.place(.buildStood, x: lord - 3000, listenerX: lord)?.gain, 1)
        XCTAssertEqual(SoundSpace.place(.buildStood, x: lord - 3000, listenerX: lord)?.pan, 0)
        XCTAssertTrue(FeedbackCue.hit.isPositional && FeedbackCue.manHit.isPositional)
    }

    /// Polish D1, law 4's edge of hearing (the director's call on 0b's M3): 0.35 at the hearing distance, half of that
    /// a quarter of it further out, nothing at 1.5 x; the thinner lets a cue through to the edge's end.
    func testTheEdgeOfHearing() throws {
        let hearing = 240.0
        XCTAssertEqual(SoundSpace.edge, 0.5)
        XCTAssertEqual(SoundSpace.gain(distance: hearing, hearing: hearing), 0.35, accuracy: 1e-12)
        XCTAssertEqual(SoundSpace.gain(distance: hearing * 1.25, hearing: hearing), 0.175, accuracy: 1e-12,
                       "half of 0.35 a quarter further out")
        XCTAssertEqual(SoundSpace.gain(distance: -hearing * 1.25, hearing: hearing), 0.175, accuracy: 1e-12)
        XCTAssertEqual(SoundSpace.gain(distance: hearing * 1.5, hearing: hearing), 0, "nothing at 1.5 x")
        XCTAssertEqual(SoundSpace.gain(distance: hearing * 2, hearing: hearing), 0)
        var last = 1.0
        for k in 0...150 {
            let g = SoundSpace.gain(distance: Double(k) * hearing / 100, hearing: hearing)
            XCTAssertLessThanOrEqual(g, last + 1e-12, "never louder farther out (\(k) %)")
            last = g
        }
        XCTAssertTrue(SoundSpace.heard(distance: hearing * 1.49, hearing: hearing))
        XCTAssertFalse(SoundSpace.heard(distance: hearing * 1.5, hearing: hearing))
        XCTAssertTrue(SoundSpace.near(distance: hearing, hearing: hearing))
        XCTAssertFalse(SoundSpace.near(distance: hearing + 1, hearing: hearing))
        let lord = 1500.0
        // D1 gate M1 rewrote the blow's places for its hearing of 440 px (they were 300, 335 and 360 for 240).
        let blow = FeedbackCue.hit.hearing
        let edge = try XCTUnwrap(SoundSpace.place(.hit, x: lord + blow * 1.25, listenerX: lord))
        XCTAssertEqual(edge.gain, 0.175, accuracy: 1e-12)
        XCTAssertEqual(edge.pan, 0.7, "clamped")
        var thinner = FeedbackThinner()
        XCTAssertEqual(thinner.cues(for: [], extra: [(.hit, lord - blow * 1.4)], time: 1, listenerX: lord), [.hit],
                       "inside the edge: through")
        XCTAssertEqual(thinner.cues(for: [], extra: [(.hit, lord - blow * 1.5)], time: 2, listenerX: lord), [],
                       "past the edge: dropped")
        XCTAssertTrue(FeedbackCue.manFell.isPositional && FeedbackCue.wallCracked.isPositional)
        XCTAssertEqual(FeedbackCue.manFell.hearing, 900)
    }

    /// 0b's L4: a cue that is not positional is never panned or faded, whatever x it comes with; the placed play sends a
    /// positional cue through space and every other one as made.
    @MainActor
    func testOnlyPositionalCuesArePlaced() {
        let silent = SilentFeedback()
        silent.play(placed: (cue: .hit, x: 1400), listenerX: 1500)
        silent.play(placed: (cue: .horn, x: 1400), listenerX: 1500)
        silent.play(placed: (cue: .manFell, x: nil), listenerX: 1500)
        XCTAssertEqual(silent.played, [.hit, .horn, .manFell])
        XCTAssertEqual(silent.placed.map { $0.cue }, [.hit], "only the positional cue with an x is placed")
        XCTAssertEqual(silent.placed.first?.x, 1400)
        for cue in FeedbackCue.allCases where !cue.isPositional {
            let place = SoundSpace.place(cue, x: 5000, listenerX: 100)
            XCTAssertEqual(place?.gain, 1, "\(cue)")
            XCTAssertEqual(place?.pan, 0, "\(cue)")
        }
    }

    /// 0b's L6: a hub that knows only the requirements from before step 0b still builds and plays a placed cue.
    @MainActor
    func testAnOlderHubStillBuilds() {
        let hub = OlderHub()
        hub.play(.hit, at: 900, listenerX: 800)
        hub.startTitleBeds()
        hub.stopTitleBeds()
        hub.play(placed: (cue: .wallHit, x: 700), listenerX: 800)
        XCTAssertEqual(hub.played, [.hit, .wallHit])
    }

    @MainActor
    func testTheHubTakesAPlace() {
        let silent = SilentFeedback()
        silent.play(.hit, at: 900, listenerX: 800)
        XCTAssertEqual(silent.played, [.hit])
        XCTAssertEqual(silent.placed.first?.x, 900)
        XCTAssertEqual(silent.placed.first?.listenerX, 800)
    }

    func testTheThinnerKeepsWhereACueCameFrom() {
        var thinner = FeedbackThinner()
        let placed = thinner.placedCues(for: [], extra: [(.wallHit, 640), (.coin, nil)], time: 1, listenerX: 600)
        XCTAssertEqual(placed.map { $0.cue }, [.coin, .wallHit])
        XCTAssertEqual(placed.first { $0.cue == .wallHit }?.x, 640)
        XCTAssertNil(placed.first { $0.cue == .coin }?.x)
        // D1 gate M4: a cue heard twice in a frame keeps its nearest place, not its first.
        var twice = FeedbackThinner()
        let blows = twice.placedCues(for: [], extra: [(.hit, 1000), (.hit, 610), (.hit, 400)], time: 1, listenerX: 600)
        XCTAssertEqual(blows.map { $0.cue }, [.hit])
        XCTAssertEqual(blows.first?.x, 610, "the blow at his feet, not the faint one at the edge")
    }

    // MARK: - The one duck rule

    func testTheDeepestDuckWinsNeverTheProduct() {
        XCTAssertEqual(BedDucks().depth, 1, "no duck: full beds")
        let two = BedDucks(screen: true, battleNear: true)
        XCTAssertEqual(two.depth, 0.5, accuracy: 1e-12)
        XCTAssertNotEqual(two.depth, 0.5 * 0.6, accuracy: 1e-6, "not their product")
        let three = BedDucks(screen: true, battleNear: true, answer3Age: 0.2)
        XCTAssertEqual(three.active.count, 3)
        XCTAssertEqual(three.depth, 0.5, accuracy: 1e-12)
        XCTAssertNotEqual(three.depth, 0.5 * 0.6 * 0.7, accuracy: 1e-6)
        XCTAssertEqual(BedDucks(battleNear: true, answer3Age: 0.2).depth, 0.6, accuracy: 1e-12)
        XCTAssertEqual(BedDucks(screen: true, answer4Age: 0.5).depth, 0.25, accuracy: 1e-12)
        XCTAssertEqual(BedDucks(answer4Age: 2.5).depth, 0.25 + 0.75 * 0.5, accuracy: 1e-12, "step 4 comes back over 2 s")
        XCTAssertEqual(BedDucks(screen: true, answer4Age: 2.5).depth, 0.5, accuracy: 1e-12)
        XCTAssertEqual(BedDucks(answer4Age: 3.6).depth, 1)
        XCTAssertEqual(BedDucks(answer3Age: 0.69).depth, 0.7)
        XCTAssertEqual(BedDucks(answer3Age: 0.7).depth, 1, "step 3 holds 0.7 s")
        XCTAssertEqual(BedDucks(hornIn: 0.5).depth, 0.3, "the horn from 0.6 s before it")
        XCTAssertEqual(BedDucks(hornIn: 0.7).depth, 1)
        XCTAssertEqual(BedDucks(hornIn: -0.1).depth, 0.3, "the horn's duck holds while it sounds")
        XCTAssertEqual(BedDucks(hornIn: -1.29).depth, 0.3, "until its first tone ends")
        XCTAssertEqual(BedDucks(hornIn: -1.31).depth, 1)
        XCTAssertTrue(BedDucks.battleNear([1200, 1790], listenerX: 1500))
        XCTAssertFalse(BedDucks.battleNear([1199, 1801], listenerX: 1500), "only within 300 px")
        let mix = AmbienceMix.target(hour: 22, rain: 0, place: .outside, fire: 0, ducked: true,
                                     ducks: BedDucks(battleNear: true), x: 900)
        XCTAssertEqual(mix.ducks.depth, 0.5, accuracy: 1e-12)
        XCTAssertEqual(mix.heard(.ambNight), mix.night * 0.5, accuracy: 1e-12)
    }

    /// Polish D1, the battle duck: a blow, a fall, a crack or a kill heard within 300 px of the lord keeps the beds at
    /// x 0.6 for 1.2 s after the last one (`FightNear`); alone it is 0.6, under a deeper duck the deeper one wins.
    func testTheBattleDuckAloneAndUnderADeeperOne() {
        var fight = FightNear()
        XCTAssertFalse(fight.near(at: 0))
        fight.note(.volley, distance: 0, now: 1)
        XCTAssertFalse(fight.near(at: 1.1), "an arrow leaving the wall is no fight")
        fight.note(.hit, distance: 301, now: 1)
        XCTAssertFalse(fight.near(at: 1.1), "a blow 301 px away is not near")
        fight.note(.hit, distance: -300, now: 2)
        XCTAssertTrue(fight.near(at: 2))
        XCTAssertTrue(fight.near(at: 3.19))
        XCTAssertFalse(fight.near(at: 3.2), "1.2 s after the last near blow it lifts")
        for cue in [FeedbackCue.manHit, .manFell, .wallHit, .wallCracked, .creatureDissolved, .arrowHit, .stomp] {
            var f = FightNear()
            f.note(cue, distance: 100, now: 5)
            XCTAssertTrue(f.near(at: 5.5), "\(cue)")
        }
        XCTAssertEqual(BedDucks(battleNear: true).depth, 0.6, accuracy: 1e-12, "alone: x 0.6")
        XCTAssertEqual(BedDucks(screen: true, battleNear: true).depth, 0.5, accuracy: 1e-12, "the lantern is deeper")
        XCTAssertEqual(BedDucks(battleNear: true, answer3Age: 0.3).depth, 0.6, accuracy: 1e-12,
                       "a fall's 0.7 is shallower than the fight")
        XCTAssertEqual(BedDucks(battleNear: true, answer4Age: 1).depth, 0.25, accuracy: 1e-12, "a breach is deeper")
        XCTAssertEqual(BedDucks(battleNear: true, answer4Age: 3.2).depth, 0.6, accuracy: 1e-12,
                       "the breach's return stops at the fight's duck")
        XCTAssertEqual(BedDucks(battleNear: true, hornIn: 0.2).depth, 0.3, accuracy: 1e-12)
        // L5: the frame's depth builds no array and always agrees with the record of active ducks.
        for screen in [false, true] {
            for battle in [false, true] {
                for age3 in [nil, 0.3, 0.9] as [Double?] {
                    for age4 in [nil, 0.5, 2.4, 4] as [Double?] {
                        let ducks = BedDucks(screen: screen, battleNear: battle, answer3Age: age3, answer4Age: age4)
                        XCTAssertEqual(ducks.depth, ducks.active.min() ?? 1, accuracy: 1e-12)
                    }
                }
            }
        }
    }

    /// Polish D1, the breach (law 4's step 4): heavy, heavy again after 0.12 s, and the beds x 0.25, held 1.5 s, back
    /// over 2 s. 0b's L1: the duck is laid only when the sound really plays.
    func testTheStepFourDuckHoldsAndReturns() {
        var gate = FeedbackGate()
        let breach = gate.answer(.wallBroken, soundOn: true, hapticsOn: true, now: 10)
        XCTAssertEqual(breach.haptic, .heavy)
        XCTAssertEqual(breach.echo, 0.12)
        XCTAssertEqual(breach.duck, .realm)
        XCTAssertEqual(breach.sound?.id, .wallBreak)
        XCTAssertFalse(breach.jitter, "step 4 is never randomised")
        XCTAssertEqual(FeedbackCue.wallBroken.answerSize, .realm)
        XCTAssertNil(FeedbackCue.horn.hapticEcho, "the horn and the defeat wait for D2")
        XCTAssertEqual(BedDucks(answer4Age: 0).depth, 0.25)
        XCTAssertEqual(BedDucks(answer4Age: 1.49).depth, 0.25, "held")
        XCTAssertEqual(BedDucks(answer4Age: 1.5).depth, 0.25, accuracy: 1e-12, "the return begins at 1.5 s")
        XCTAssertEqual(BedDucks(answer4Age: 2.5).depth, 0.625, accuracy: 1e-12, "half way 1 s later")
        XCTAssertEqual(BedDucks(answer4Age: 3.49).depth, 0.25 + 0.75 * 1.99 / 2, accuracy: 1e-9)
        XCTAssertEqual(BedDucks(answer4Age: 3.5).depth, 1, "back over 2 s")
        // L1: thrown away by the throttle, or with Sound off, no duck (the haptic still comes with Sound off).
        let throttled = gate.answer(.wallBroken, soundOn: true, hapticsOn: true, now: 10.1)
        XCTAssertNil(throttled.sound)
        XCTAssertNil(throttled.duck, "a throttled breach lays no duck")
        var quiet = FeedbackGate()
        let off = quiet.answer(.manFell, soundOn: false, hapticsOn: true, now: 1)
        XCTAssertEqual(off.haptic, .heavy)
        XCTAssertNil(off.duck, "Sound off: no duck")
        XCTAssertEqual(quiet.answer(.manFell, soundOn: true, hapticsOn: true, now: 2).duck, .triumph)
        XCTAssertNil(quiet.answer(.hit, soundOn: true, hapticsOn: true, now: 3).duck, "step 2 lays none")
        XCTAssertEqual(quiet.answer(.wallCracked, soundOn: true, hapticsOn: false, now: 4).duck, .triumph)
        // D1 gate M5: at the edge of hearing (beyond it) a fall, a crack or a breach-sized cue is only its faded sound:
        // no haptic, no echo, no duck; the near one after it still has its full answer (no throttle was spent).
        var edge = FeedbackGate()
        for (k, cue) in [FeedbackCue.manFell, .wallCracked, .wallHit].enumerated() {
            let far = edge.answer(cue, soundOn: true, hapticsOn: true, now: 20 + Double(k), near: false)
            XCTAssertNotNil(far.sound, "\(cue): heard, faded")
            XCTAssertNil(far.haptic, "\(cue): no hand at the edge")
            XCTAssertNil(far.echo, "\(cue)")
            XCTAssertNil(far.duck, "\(cue): no duck at the edge")
        }
        XCTAssertEqual(edge.answer(.manFell, soundOn: true, hapticsOn: true, now: 20.1, near: true).haptic, .heavy,
                       "a near fall right after a far one keeps its heavy")
        let nearCrack = edge.answer(.wallCracked, soundOn: true, hapticsOn: true, now: 30, near: true)
        XCTAssertEqual(nearCrack.haptic, .medium)
        XCTAssertEqual(nearCrack.duck, .triumph)
    }

    /// Polish D1: a man struck grunts at most once every 0.5 s, grunt_1 and grunt_2 in turn among those that play.
    func testTheGruntsKeepHalfASecondApart() {
        guard FeedbackCue.soldierGrunts else { return }
        var gate = FeedbackGate()
        let times = [1.0, 1.2, 1.49, 1.5, 1.7, 2.0, 2.3, 2.6]
        let heard = times.map { gate.answer(.manHit, soundOn: true, hapticsOn: true, now: $0).sound?.id }
        XCTAssertEqual(heard, [.grunt1, nil, nil, .grunt2, nil, .grunt1, nil, .grunt2])
        XCTAssertEqual(SoundID.grunt1.throttleKey, SoundID.grunt2.throttleKey, "one throttle for both files")
        XCTAssertEqual(FeedbackGate.gruntSpacing, 0.5)
        XCTAssertNil(FeedbackCue.manHit.haptic, "no haptic for every blow")
        XCTAssertTrue(gate.answer(.manHit, soundOn: true, hapticsOn: true, now: 5).jitter, "step 2: +-4 %")
    }

    /// Polish D1, one touch, one tick (law 4, the director's call of 22.11.): a pane cue within 0.25 s after a plaque
    /// press plays its sound and no haptic; later, or without a press, it keeps its own tick.
    func testOneTouchOneTick() {
        var gate = FeedbackGate()
        let press = gate.answer(.plaquePress, soundOn: true, hapticsOn: true, now: 1)
        XCTAssertEqual(press.haptic, .selection)
        XCTAssertEqual(press.sound?.id, .tap)
        let open = gate.answer(.paneOpen, soundOn: true, hapticsOn: true, now: 1.016)
        XCTAssertNil(open.haptic, "the press's tick stands for the pane")
        XCTAssertEqual(open.sound?.id, .tap, "the pane's sound plays (inside tap.wav's throttle too)")
        let close = gate.answer(.paneClose, soundOn: true, hapticsOn: true, now: 1.25)
        XCTAssertNil(close.haptic, "0.25 s after the press: still one touch")
        XCTAssertNotNil(close.sound)
        XCTAssertEqual(gate.answer(.paneOpen, soundOn: true, hapticsOn: true, now: 1.6).haptic, .soft, "later: its own")
        var bare = FeedbackGate()
        XCTAssertEqual(bare.answer(.paneOpen, soundOn: true, hapticsOn: true, now: 3).haptic, .soft, "no press: its own")
        XCTAssertNil(bare.answer(.lanternUp, soundOn: true, hapticsOn: true, now: 3.01).sound, "tap's throttle holds")
        var haptics = FeedbackGate()
        _ = haptics.answer(.plaquePress, soundOn: true, hapticsOn: false, now: 1)
        XCTAssertNil(haptics.answer(.paneClose, soundOn: true, hapticsOn: true, now: 1.1).haptic,
                     "a press with Haptics off still makes it one touch")
    }

    /// Polish D1: the old card pair, `creatureHit` and `soldierFell` are silent in sound and hand.
    @MainActor
    func testTheRetiredCuesAreSilentInSoundAndHand() {
        var gate = FeedbackGate()
        for (k, cue) in [FeedbackCue.cardOpened, .cardClosed, .creatureHit, .soldierFell].enumerated() {
            let answer = gate.answer(cue, soundOn: true, hapticsOn: true, now: Double(k))
            XCTAssertNil(answer.sound, "\(cue)")
            XCTAssertNil(answer.haptic, "\(cue)")
            XCTAssertNil(answer.duck, "\(cue)")
        }
        let silent = SilentFeedback()
        silent.play(.cardOpened)
        silent.play(.cardClosed)
        XCTAssertEqual(silent.played, [.cardOpened, .cardClosed], "the call sites still reach the hub")
        XCTAssertTrue(silent.felt.isEmpty, "no tick in the hand")
        XCTAssertNil(FeedbackThinner.cue(for: .soldierFell(name: "Aldo")))
    }

    /// Polish D1 gate M2 rewrote this test (it pinned the chain's rates): the kills' chain is not built, since a
    /// player's rate stretches time and keeps the pitch. Every kill plays dissolve as made at rate 1, near or at the
    /// edge, and varies a little like any step 2 answer. `AnswerChain` keeps its own rates and caps for pitched files.
    func testKillsPlayAsMadeTheChainIsNotBuilt() {
        var gate = FeedbackGate()
        for k in 0..<10 {
            let answer = gate.answer(.creatureDissolved, soundOn: true, hapticsOn: true, now: Double(k) * 0.3)
            XCTAssertEqual(answer.sound?.id, .dissolve)
            XCTAssertEqual(answer.sound?.rate, 1, "kill \(k): no stretched chain")
            XCTAssertTrue(answer.jitter, "step 2: +-4 %")
            XCTAssertNil(answer.haptic, "the chain's hand is not built either")
        }
        let far = gate.answer(.creatureDissolved, soundOn: true, hapticsOn: true, now: 3.2, near: false)
        XCTAssertEqual(far.sound?.rate, 1, "at the edge: as made")
        XCTAssertEqual(FeedbackCue.creatureDissolved.answerSize, .deed)
        XCTAssertEqual(AnswerChain.killCap, 7, "the law's cap waits for pitched files")
    }

    /// 0b's L2: after a shallower duck the beds come back over 1.2 s from it, not at the pace a deeper duck before it
    /// set.
    func testTheReturnAfterAShallowerDuckTakesTheSettleTime() {
        let frame = 1.0 / 60
        var duck = DuckFollower()
        for _ in 0..<30 { duck.step(toward: 0.25, dt: frame) }
        for _ in 0..<24 { duck.step(toward: 1, dt: frame) }
        XCTAssertEqual(duck.value, 0.25 + 24 * frame * 0.75 / 1.2, accuracy: 1e-9, "on its way back from 0.25")
        for _ in 0..<30 { duck.step(toward: 0.6, dt: frame) }
        XCTAssertEqual(duck.value, 0.6, accuracy: 1e-9, "held at the fight's 0.6")
        var frames = 0
        while duck.value < 1 && frames < 600 {
            duck.step(toward: 1, dt: frame)
            frames += 1
        }
        XCTAssertEqual(Double(frames) * frame, DuckFollower.settle, accuracy: frame + 1e-9,
                       "from 0.6 back over the settle time")
        // Step 4's own return (a goal that moves every frame) is still followed, not slowed.
        var step4 = DuckFollower()
        for k in 0..<240 {
            let age = Double(k) * frame
            step4.step(toward: BedDucks(answer4Age: age).depth, dt: frame)
            // From the end of the 0.15 s attack on, the follower sits on the moving goal.
            if k >= 10 {
                XCTAssertEqual(step4.value, BedDucks(answer4Age: age).depth, accuracy: 0.02, "at \(age) s")
            }
        }
    }

    // MARK: - D1's levels

    /// Polish D1: the night's cues on law 4's ladder (inventory.md's measure, the file's whole RMS + 20 log10 volume),
    /// and the blows at least 3 dB over the night bed in the gorge under the battle duck.
    func testTheNightsCuesSitOnTheirSteps() throws {
        let night: [FeedbackCue] = [.hit, .manHit, .arrowHit, .wallHit, .creatureDissolved, .manFell, .wallCracked,
                                    .wallBroken]
        var levels: [FeedbackCue: Double] = [:]
        for cue in night {
            let sound = try XCTUnwrap(cue.sound, "\(cue)")
            let size = try XCTUnwrap(cue.answerSize, "\(cue)")
            let level = AnswerSize.level(fileRMS: try Self.fileRMS(sound.id), volume: sound.volume)
            levels[cue] = level
            XCTAssertGreaterThanOrEqual(level, size.band.lowerBound - 0.1, "\(cue) at \(level) dBFS")
            XCTAssertLessThanOrEqual(level, size.band.upperBound + 0.1, "\(cue) at \(level) dBFS")
        }
        if FeedbackCue.soldierGrunts {
            let other = AnswerSize.level(fileRMS: try Self.fileRMS(.grunt2), volume: FeedbackCue.manHit.sound?.volume ?? 0)
            XCTAssertTrue(AnswerSize.deed.band.contains(other), "grunt_2 at \(other) dBFS")
        }
        // The night bed in the gorge (no fire): amb_night and amb_throat as the mix plays them, summed by power,
        // under the battle duck.
        let mix = AmbienceMix.target(hour: 23, rain: 0, place: .outside, fire: 0, x: 900)
        var power = 0.0
        for id in [SoundID.ambNight, .ambThroat] {
            power += pow(10, AnswerSize.level(fileRMS: try Self.fileRMS(id), volume: mix.level(id)) / 10)
        }
        let bed = 10 * log10(power)
        let ducked = bed + 20 * log10(BedDucks.battleDepth)
        for cue in [FeedbackCue.hit, .manHit] {
            XCTAssertGreaterThanOrEqual(try XCTUnwrap(levels[cue]) - ducked, 3, "\(cue) over the ducked bed \(ducked)")
        }
        // D1 gate M1: a blow on a creature 100 px from the lord, faded by its hearing, still clears the ducked bed by
        // 3 dB.
        let fade = SoundSpace.gain(distance: 100, hearing: FeedbackCue.hit.hearing)
        let away = try XCTUnwrap(levels[.hit]) + 20 * log10(fade)
        XCTAssertGreaterThanOrEqual(away - ducked, 3, "a blow 100 px away at \(away) over \(ducked)")
    }

    func testTheBedsDuckAtQuickAndComeBackOverTheSettleTime() {
        let frame = 1.0 / 60
        var duck = DuckFollower()
        for _ in 0..<9 { duck.step(toward: 0.5, dt: frame) }
        XCTAssertEqual(duck.value, 0.5, accuracy: 1e-6, "down in 0.15 s")
        duck.step(toward: 0.5, dt: frame)
        XCTAssertEqual(duck.value, 0.5)
        var frames = 0
        while duck.value < 1 && frames < 600 {
            duck.step(toward: 1, dt: frame)
            frames += 1
            if frames == 36 { XCTAssertEqual(duck.value, 0.75, accuracy: 1e-6, "half way at 0.6 s, linear") }
        }
        XCTAssertEqual(Double(frames) * frame, DuckFollower.settle, accuracy: frame + 1e-9, "back in 1.2 s")
        // The deepest of three ducks comes back over the same 1.2 s.
        let three = BedDucks(screen: true, battleNear: true, answer4Age: 0.1)
        var deep = DuckFollower()
        for _ in 0..<30 { deep.step(toward: three.depth, dt: frame) }
        XCTAssertEqual(deep.value, 0.25, accuracy: 1e-9)
        frames = 0
        while deep.value < 1 && frames < 600 {
            deep.step(toward: BedDucks().depth, dt: frame)
            frames += 1
        }
        XCTAssertEqual(Double(frames) * frame, DuckFollower.settle, accuracy: frame + 1e-9)
        // A return slower than the settle time (step 4's 2 s) is followed, not outrun.
        var slow = DuckFollower()
        for _ in 0..<30 { slow.step(toward: 0.25, dt: frame) }
        slow.step(toward: 0.3, dt: frame)
        XCTAssertEqual(slow.value, 0.25 + frame * 0.75 / 1.2, accuracy: 1e-9)
        slow.step(toward: 0.26, dt: frame)
        XCTAssertEqual(slow.value, 0.26, accuracy: 1e-9)
    }

    // MARK: - The chain

    func testTheChainClimbsASemitoneARepeatAndResets() {
        for n in 0...12 {
            XCTAssertEqual(AnswerChain.rate(step: n), pow(2, Double(n) / 12), accuracy: 1e-12)
            XCTAssertEqual(SoundID.coinStep(rate: AnswerChain.rate(step: n)), SoundID.coinSteps[n],
                           "step \(n) is the count's coin step \(n)")
        }
        XCTAssertEqual(AnswerChain.rate(step: 12), 2, accuracy: 1e-12)
        XCTAssertEqual(AnswerChain.countCap, 12)
        XCTAssertEqual(AnswerChain.taxCap, 7)
        XCTAssertEqual(AnswerChain.killCap, 7)
        var chain = AnswerChain(cap: AnswerChain.taxCap)
        var steps: [Int] = []
        for k in 0..<10 { steps.append(chain.next(at: Double(k) * 0.3)) }
        XCTAssertEqual(steps, [0, 1, 2, 3, 4, 5, 6, 7, 7, 7], "the cap holds")
        XCTAssertEqual(chain.rate, pow(2, 7.0 / 12), accuracy: 1e-12)
        XCTAssertEqual(chain.strength(), 1, accuracy: 1e-12)
        XCTAssertEqual(chain.next(at: 2.7 + 1.49), 7, "a repeat within 1.5 s goes on")
        XCTAssertEqual(chain.next(at: 2.7 + 1.49 + 1.5), 0, "1.5 s without a repeat: back to the root")
        XCTAssertEqual(chain.strength(), 0.35, accuracy: 1e-12)
        XCTAssertEqual(chain.next(at: 2.7 + 1.49 + 1.5 + 0.3), 1)
        XCTAssertEqual(chain.next(at: 1), 0, "a clock that went back starts again")
        var count = AnswerChain(cap: AnswerChain.countCap)
        for k in 0..<20 { count.next(at: Double(k) * 0.05) }
        XCTAssertEqual(count.step, 12)
    }

    // MARK: - The dawn verdict and the title's beds

    func testTheDawnVerdictRingsOrTolls() {
        XCTAssertEqual(DawnVerdict.cue(fallen: 0), .dawnHeld)
        XCTAssertEqual(DawnVerdict.cue(fallen: 2), .dawnToll)
        XCTAssertEqual(DawnVerdict.cues(fallen: 0).map { $0.cue }, [.dawnHeld])
        let two = DawnVerdict.cues(fallen: 2)
        XCTAssertEqual(two.map { $0.cue }, [.dawnToll, .dawnToll])
        XCTAssertEqual(two.map { $0.delay }, [0, DawnVerdict.tollGap])
        XCTAssertEqual(DawnVerdict.cues(fallen: 9).count, 3, "at most three tolls")
        XCTAssertGreaterThanOrEqual(DawnVerdict.tollGap, SoundID.bell.minimumInterval,
                                    "the stand-in bell's throttle lets every toll through")
        XCTAssertGreaterThanOrEqual(SoundID.bell.voices, 3, "the tolls ring into each other's tails")
    }

    @MainActor
    func testTheTitlesBeds() {
        XCTAssertEqual(AmbienceMix.titleBeds.map { $0.id }, [.ambThroat, .ambFire])
        XCTAssertTrue(AmbienceMix.titleBeds.allSatisfy { $0.id.isLoop && $0.level > 0 && $0.level <= 1 })
        XCTAssertEqual(AmbienceMix.titleFadeIn, 1.5)
        let silent = SilentFeedback()
        silent.startTitleBeds()
        XCTAssertTrue(silent.titleBeds)
        silent.stopTitleBeds()
        XCTAssertFalse(silent.titleBeds)
    }

    // MARK: - Helpers

    /// A hub as another lane may still write it: only the requirements from before step 0b (0b's L6).
    @MainActor
    private final class OlderHub: FeedbackHub {
        var soundOn = true
        var hapticsOn = true
        var played: [FeedbackCue] = []
        func play(_ cue: FeedbackCue) { played.append(cue) }
        func countCoin(rate: Double, strength: Double) {}
        func countTick(strength: Double) {}
        func countWarm() {}
        func ambience(_ mix: AmbienceMix) {}
    }

    /// A wav's whole RMS in dBFS (16 bit PCM mono, as `tools/soundsynth.py` writes them), read from the app's bundle.
    private static func fileRMS(_ id: SoundID) throws -> Double {
        let url = try XCTUnwrap(Bundle.main.url(forResource: id.rawValue, withExtension: "wav", subdirectory: "Sound")
            ?? Bundle.main.url(forResource: id.rawValue, withExtension: "wav"), id.rawValue)
        let data = try Data(contentsOf: url)
        var offset = 12
        while offset + 8 <= data.count {
            let tag = String(decoding: data[offset..<offset + 4], as: UTF8.self)
            let size = Int(data[offset + 4]) | Int(data[offset + 5]) << 8 | Int(data[offset + 6]) << 16
                | Int(data[offset + 7]) << 24
            if tag == "data" {
                let end = min(data.count, offset + 8 + size)
                var sum = 0.0
                var n = 0
                var i = offset + 8
                while i + 1 < end {
                    let sample = Int16(bitPattern: UInt16(data[i]) | UInt16(data[i + 1]) << 8)
                    let v = Double(sample) / 32768
                    sum += v * v
                    n += 1
                    i += 2
                }
                return 20 * log10(max(1e-9, (sum / Double(max(1, n))).squareRoot()))
            }
            offset += 8 + size + (size & 1)
        }
        XCTFail("\(id.rawValue) has no data chunk")
        return 0
    }
}
