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
        XCTAssertEqual(SoundSpace.gain(distance: 900, hearing: 240), 0.35, accuracy: 1e-12, "and beyond it")
        XCTAssertEqual(SoundSpace.gain(distance: 900, hearing: .infinity), 1, "an everywhere cue is not faded")
        let lord = 1500.0
        XCTAssertEqual(SoundSpace.pan(x: lord, listenerX: lord), 0)
        XCTAssertEqual(SoundSpace.pan(x: lord + 160, listenerX: lord), 0.5, accuracy: 1e-12, "east of him: right")
        XCTAssertEqual(SoundSpace.pan(x: lord - 160, listenerX: lord), -0.5, accuracy: 1e-12, "west of him: left")
        XCTAssertEqual(SoundSpace.pan(x: lord + 224, listenerX: lord), 0.7, accuracy: 1e-12)
        XCTAssertEqual(SoundSpace.pan(x: lord + 2000, listenerX: lord), 0.7, "clamped at 0.7")
        XCTAssertEqual(SoundSpace.pan(x: lord - 2000, listenerX: lord), -0.7)
        let near = try XCTUnwrap(SoundSpace.place(.hit, x: lord + 100, listenerX: lord))
        XCTAssertEqual(near.gain, 1 - 100.0 / 240, accuracy: 1e-12)
        XCTAssertEqual(near.pan, 100.0 / 320, accuracy: 1e-12)
        XCTAssertNil(SoundSpace.place(.hit, x: lord + 241, listenerX: lord), "beyond its hearing: not played")
        XCTAssertEqual(SoundSpace.place(.buildStood, x: lord - 3000, listenerX: lord)?.gain, 1)
        XCTAssertEqual(SoundSpace.place(.buildStood, x: lord - 3000, listenerX: lord)?.pan, -0.7)
        XCTAssertTrue(FeedbackCue.hit.isPositional && FeedbackCue.manHit.isPositional)
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
        XCTAssertEqual(BedDucks(hornIn: -0.1).depth, 1)
        XCTAssertTrue(BedDucks.battleNear([1200, 1790], listenerX: 1500))
        XCTAssertFalse(BedDucks.battleNear([1199, 1801], listenerX: 1500), "only within 300 px")
        let mix = AmbienceMix.target(hour: 22, rain: 0, place: .outside, fire: 0, ducked: true,
                                     ducks: BedDucks(battleNear: true), x: 900)
        XCTAssertEqual(mix.ducks.depth, 0.5, accuracy: 1e-12)
        XCTAssertEqual(mix.heard(.ambNight), mix.night * 0.5, accuracy: 1e-12)
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
        XCTAssertEqual(chain.next(at: 4.5), 1)
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
