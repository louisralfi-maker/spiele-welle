import SwiftUI
import XCTest
@testable import Lanternhold

/// The motion vocabulary (polish audit, law 1 and the pane part of law 2; fix step 0a): the four tokens, the three
/// curves, the presence stepper with its whole-pixel rise, the one Reduce Motion switch, the follow's spring, and the
/// SwiftUI side reading the same numbers.
final class MotionTests: XCTestCase {
    private let frame60 = 1.0 / 60
    private let frame20 = 1.0 / 20

    // MARK: Tokens

    func testTheFourTokens() {
        XCTAssertEqual(MotionToken.quick.inSeconds, 0.15)
        XCTAssertEqual(MotionToken.quick.outSeconds, 0.10)
        XCTAssertEqual(MotionToken.normal.inSeconds, 0.25)
        XCTAssertEqual(MotionToken.normal.outSeconds, 0.15)
        XCTAssertEqual(MotionToken.slow.inSeconds, 0.6)
        XCTAssertEqual(MotionToken.settle.inSeconds, 1.2)
        XCTAssertEqual(MotionToken.allCases.count, 4)
    }

    // MARK: Curves

    func testEachCurveRunsFromZeroToOneAndNeverGoesBack() {
        for curve in [MotionCurve.enter, MotionCurve.leave, MotionCurve.linear] {
            XCTAssertEqual(curve.value(0), 0)
            XCTAssertEqual(curve.value(1), 1)
            XCTAssertEqual(curve.value(-0.3), 0)
            XCTAssertEqual(curve.value(1.7), 1)
            var last = 0.0
            for step in 0...1000 {
                let value = curve.value(Double(step) / 1000)
                XCTAssertGreaterThanOrEqual(value, last, "\(curve) goes back at \(step)")
                XCTAssertLessThanOrEqual(value, 1)
                last = value
            }
        }
        XCTAssertEqual(Motion.enter(0), 0)
        XCTAssertEqual(Motion.enter(1), 1)
        XCTAssertEqual(Motion.leave(0), 0)
        XCTAssertEqual(Motion.leave(1), 1)
    }

    func testEaseOutIsAheadOfLinearAndEaseInBehind() {
        XCTAssertGreaterThan(Motion.enter(0.5), 0.5)
        XCTAssertLessThan(Motion.leave(0.5), 0.5)
        XCTAssertEqual(Motion.linear(0.5), 0.5)
        for step in 1..<100 {
            let t = Double(step) / 100
            XCTAssertGreaterThanOrEqual(Motion.enter(t), t)
            XCTAssertLessThanOrEqual(Motion.leave(t), t)
        }
    }

    func testTheCurvesControlPoints() {
        XCTAssertEqual(MotionCurve.enter, MotionCurve(0, 0, 0.58, 1))
        XCTAssertEqual(MotionCurve.leave, MotionCurve(0.42, 0, 1, 1))
        // The two are mirror images: leaving is entering run backwards.
        for step in 0...20 {
            let t = Double(step) / 20
            XCTAssertEqual(Motion.leave(t), 1 - Motion.enter(1 - t), accuracy: 1e-9)
        }
    }

    /// Step 0a's review, L2: reference values computed outside the code (the same cubic Bezier in python, 60
    /// halvings), so a solver error that keeps the curves symmetric and monotone still fails here. The Metal side
    /// (`Presence`) and the SwiftUI side (`timingCurve`) run on this one curve.
    func testTheCurvesMeetTheirReferenceValues() {
        XCTAssertEqual(Motion.enter(0.5), 0.684643, accuracy: 1e-5)
        XCTAssertEqual(Motion.leave(0.5), 0.315357, accuracy: 1e-5)
        XCTAssertEqual(MotionCurve.enter.value(0.5), 0.684643, accuracy: 1e-5)
        XCTAssertEqual(MotionCurve.leave.value(0.5), 0.315357, accuracy: 1e-5)
    }

    func testTheCurveInvertsItself() {
        for curve in [MotionCurve.enter, MotionCurve.leave] {
            for step in 0...20 {
                let t = Double(step) / 20
                XCTAssertEqual(curve.time(at: curve.value(t)), t, accuracy: 1e-6)
            }
        }
    }

    // MARK: Presence

    /// Steps `presence` at `dt` until `done` holds; the seconds it took (nil after 5 s).
    private func seconds(_ presence: inout Presence, dt: Double, shown: Bool, mode: MotionMode,
                         until done: (Presence) -> Bool) -> Double? {
        for step in 1...Int(5 / dt) {
            presence.step(dt, shown: shown, mode: mode)
            if done(presence) { return Double(step) * dt }
        }
        return nil
    }

    func testAQuickPresenceIsWholeAtFifteenHundredthsWithinOneFrame() throws {
        var presence = Presence(token: .quick)
        XCTAssertTrue(presence.isGone)
        let came = try XCTUnwrap(seconds(&presence, dt: frame60, shown: true, mode: .full) { $0.isWhole })
        XCTAssertEqual(came, 0.15, accuracy: frame60 + 1e-9)
        XCTAssertEqual(presence.alpha, 1)
        let went = try XCTUnwrap(seconds(&presence, dt: frame60, shown: false, mode: .full) { $0.isGone })
        XCTAssertEqual(went, 0.10, accuracy: frame60 + 1e-9)
        XCTAssertEqual(presence.alpha, 0)
    }

    func testANormalPresenceComesInAQuarterAndGoesInFifteenHundredths() throws {
        var presence = Presence(token: .normal)
        let came = try XCTUnwrap(seconds(&presence, dt: frame60, shown: true, mode: .full) { $0.isWhole })
        XCTAssertEqual(came, 0.25, accuracy: frame60 + 1e-9)
        let went = try XCTUnwrap(seconds(&presence, dt: frame60, shown: false, mode: .full) { $0.isGone })
        XCTAssertEqual(went, 0.15, accuracy: frame60 + 1e-9)
    }

    func testThePresenceComesOnTheEaseOutAndGoesOnTheEaseIn() {
        var coming = Presence(token: .normal)
        for _ in 0..<6 { coming.step(frame60, shown: true, mode: .full) }
        XCTAssertEqual(coming.alpha, Motion.enter(0.1 / 0.25), accuracy: 1e-9)
        var going = Presence(token: .normal, shown: true)
        for _ in 0..<6 { going.step(frame60, shown: false, mode: .full) }
        XCTAssertEqual(going.alpha, 1 - Motion.leave(0.1 / 0.15), accuracy: 1e-9)
    }

    func testTheRiseRunsTwoOneZeroInWholePixels() {
        XCTAssertEqual(Motion.rise(alpha: 0), 2)
        XCTAssertEqual(Motion.rise(alpha: 0.5), 1)
        XCTAssertEqual(Motion.rise(alpha: 1), 0)
        for token in [MotionToken.quick, .normal, .slow] {
            var presence = Presence(token: token)
            XCTAssertEqual(presence.rise, 2)
            var rises: [Int] = []
            for _ in 0..<Int((token.inSeconds + 0.1) / frame60) {
                presence.step(frame60, shown: true, mode: .full)
                rises.append(presence.rise)
            }
            XCTAssertEqual(rises.first, 2, "\(token)")
            XCTAssertEqual(rises.last, 0, "\(token)")
            XCTAssertTrue(rises.contains(1), "\(token): \(rises)")
            XCTAssertTrue(Set(rises).isSubset(of: [0, 1, 2]), "\(token): \(rises)")
            XCTAssertEqual(rises, rises.sorted(by: >), "\(token): the rise never climbs back: \(rises)")
            XCTAssertTrue(presence.isWhole)
        }
    }

    func testGoingItFadesInPlaceAndTurnedRoundItNeverJumps() {
        var presence = Presence(token: .normal)
        for _ in 0..<6 { presence.step(frame60, shown: true, mode: .full) }
        let midway = presence.alpha
        let rise = presence.rise
        XCTAssertGreaterThan(midway, 0)
        XCTAssertLessThan(midway, 1)
        // Turned round: no step of time, no change.
        presence.step(0, shown: false, mode: .full)
        XCTAssertEqual(presence.alpha, midway, accuracy: 1e-6)
        var last = presence.alpha
        while !presence.isGone {
            presence.step(frame60, shown: false, mode: .full)
            XCTAssertLessThanOrEqual(presence.alpha, last)
            if !presence.isGone {
                XCTAssertLessThanOrEqual(presence.rise, rise, "it goes in place")
            }
            last = presence.alpha
        }
        // Gone, it comes again from its full rise.
        presence.step(frame60, shown: true, mode: .full)
        XCTAssertEqual(presence.rise, 2)
        // Turned round while going: it comes back from where it is.
        var back = Presence(token: .quick, shown: true)
        for _ in 0..<3 { back.step(frame60, shown: false, mode: .full) }
        let low = back.alpha
        back.step(0, shown: true, mode: .full)
        XCTAssertEqual(back.alpha, low, accuracy: 1e-6)
        XCTAssertEqual(back.rise, 0, "a thing turned round on its way out does not drop to rise again")
    }

    // MARK: Reduce Motion

    func testUnderReduceMotionThereIsNoRiseAndTheAlphaStillArrivesAtQuick() throws {
        XCTAssertEqual(MotionMode.reduced.token(.normal), .quick)
        XCTAssertEqual(MotionMode.reduced.token(.slow), .quick)
        XCTAssertEqual(MotionMode.full.token(.slow), .slow)
        XCTAssertEqual(MotionMode.reduced.travel(2), 0)
        XCTAssertEqual(MotionMode.full.travel(2), 2)
        XCTAssertFalse(MotionMode.reduced.allowsScale)
        XCTAssertEqual(Motion.rise(alpha: 0, mode: .reduced), 0)
        for token in MotionToken.allCases {
            var presence = Presence(token: token)
            var rises: [Int] = []
            var steps = 0
            while !presence.isWhole && steps < 600 {
                presence.step(frame60, shown: true, reduceMotion: true)
                rises.append(presence.rise)
                steps += 1
            }
            XCTAssertEqual(Double(steps) * frame60, 0.15, accuracy: frame60 + 1e-9, "\(token)")
            XCTAssertEqual(Set(rises), [0], "\(token)")
            let went = try XCTUnwrap(seconds(&presence, dt: frame60, shown: false, mode: .reduced) { $0.isGone })
            XCTAssertEqual(went, 0.10, accuracy: frame60 + 1e-9, "\(token)")
            XCTAssertEqual(presence.rise, 0)
        }
    }

    // MARK: The follow

    func testTheFollowNeverOvershootsAndSettlesWithinTheSettleToken() {
        for dt in [frame60, frame20] {
            for (start, target, speed) in [(0.0, 100.0, 0.0), (0.0, -37.0, 0.0), (250.0, 10.0, 0.0),
                                           (0.0, 100.0, 4000.0), (0.0, 100.0, -300.0), (5.0, 6.0, 900.0)] {
                var value = start
                var velocity = speed
                var settledAt: Double?
                let distance = abs(target - start)
                for step in 1...Int(3 / dt) {
                    (value, velocity) = Motion.follow(value: value, velocity: velocity, target: target, dt: dt)
                    let past = target > start ? value > target : value < target
                    XCTAssertFalse(past, "dt \(dt) from \(start) to \(target) at \(speed): overshoot to \(value)")
                    if settledAt == nil, abs(value - target) <= Motion.settledShare * distance {
                        settledAt = Double(step) * dt
                    }
                }
                if speed == 0 {
                    let at = settledAt ?? 99
                    XCTAssertLessThanOrEqual(at, MotionToken.settle.inSeconds + 1e-9,
                                             "dt \(dt) from \(start) to \(target): settled at \(at)")
                }
                XCTAssertEqual(value, target, accuracy: 1e-3)
            }
        }
    }

    func testTheFollowFromRestApproachesWithoutTurning() {
        for dt in [frame60, frame20] {
            var value = 0.0
            var velocity = 0.0
            var last = value
            for _ in 0..<Int(3 / dt) {
                (value, velocity) = Motion.follow(value: value, velocity: velocity, target: 1, dt: dt)
                XCTAssertGreaterThanOrEqual(value, last)
                last = value
            }
        }
    }

    func testTheFollowIsTheSameCurveAtAnyStep() {
        var fine = (value: 0.0, velocity: 0.0)
        var coarse = (value: 0.0, velocity: 0.0)
        for _ in 0..<12 {
            for _ in 0..<3 {
                fine = Motion.follow(value: fine.value, velocity: fine.velocity, target: 80, dt: frame60)
            }
            coarse = Motion.follow(value: coarse.value, velocity: coarse.velocity, target: 80, dt: frame20)
            XCTAssertEqual(fine.value, coarse.value, accuracy: 1e-9)
            XCTAssertEqual(fine.velocity, coarse.velocity, accuracy: 1e-9)
        }
    }

    func testUnderReduceMotionTheFollowSitsOnItsTarget() {
        let next = Motion.follow(value: 3, velocity: 40, target: 90, dt: frame60, mode: .reduced)
        XCTAssertEqual(next.value, 90)
        XCTAssertEqual(next.velocity, 0)
        XCTAssertNil(Animation.lhFollow(mode: .reduced))
    }

    func testTheFollowIsTheCamerasSpring() {
        XCTAssertEqual(Motion.followOmega, Camera.followOmega)
    }

    // MARK: Determinism

    func testTheSameSecondsGiveTheSameValues() {
        let steps: [Double] = [0.016, 0.017, 0.05, 0.0, 0.033, 0.016, 0.1, 0.008, 0.05, 0.05, 0.016, 0.2]
        let shown: [Bool] = [true, true, true, false, false, true, true, false, true, true, false, true]
        func run() -> [Double] {
            var presence = Presence(token: .normal)
            var follow = (value: 0.0, velocity: 0.0)
            var values: [Double] = []
            for (dt, on) in zip(steps, shown) {
                presence.step(dt, shown: on, mode: .full)
                follow = Motion.follow(value: follow.value, velocity: follow.velocity, target: on ? 50 : -20, dt: dt)
                values += [presence.alpha, Double(presence.rise), follow.value, follow.velocity]
            }
            return values
        }
        XCTAssertEqual(run(), run())
    }

    // MARK: The SwiftUI side reads Core's numbers

    func testTheSwiftUIDurationsAreCoresTokens() {
        for token in MotionToken.allCases {
            XCTAssertEqual(MotionStyle.inSeconds(token, mode: .full), token.inSeconds)
            XCTAssertEqual(MotionStyle.outSeconds(token, mode: .full), token.outSeconds)
            XCTAssertEqual(MotionStyle.inSeconds(token, mode: .reduced), MotionToken.quick.inSeconds)
            XCTAssertEqual(MotionStyle.outSeconds(token, mode: .reduced), MotionToken.quick.outSeconds)
        }
        XCTAssertEqual(MotionStyle.followStiffness, Motion.followOmega * Motion.followOmega)
        XCTAssertEqual(MotionStyle.followDamping, 2 * Motion.followOmega)
        XCTAssertEqual(MotionStyle.dim, 0.40)
        XCTAssertEqual(MotionStyle.pointsPerPixel, 2)
        XCTAssertEqual(MotionStyle.mode(game: nil, system: true), .reduced)
        // A game flag of false never turns the system's Reduce Motion off (gate M2).
        XCTAssertEqual(MotionStyle.mode(game: false, system: true), .reduced)
        XCTAssertEqual(MotionStyle.mode(game: true, system: false), .reduced)
        XCTAssertEqual(MotionStyle.mode(game: false, system: false), .full)
        XCTAssertEqual(MotionStyle.mode(game: nil, system: false), .full)
    }

    /// Step 0a's review, L1: the animations themselves, not only the seconds they read. A literal duration or a
    /// curve written into `lhEnter` / `lhLeave` fails here.
    func testTheSwiftUIAnimationsAreTheTimingCurvesOfTheTokens() {
        for token in MotionToken.allCases {
            XCTAssertEqual(Animation.lhEnter(token), .timingCurve(0, 0, 0.58, 1, duration: token.inSeconds),
                           "\(token) enter")
            XCTAssertEqual(Animation.lhLeave(token), .timingCurve(0.42, 0, 1, 1, duration: token.outSeconds),
                           "\(token) leave")
            XCTAssertEqual(Animation.lhEnter(token, mode: .reduced), .timingCurve(0, 0, 0.58, 1, duration: 0.15),
                           "\(token) enter, Reduce Motion")
            XCTAssertEqual(Animation.lhLeave(token, mode: .reduced), .timingCurve(0.42, 0, 1, 1, duration: 0.10),
                           "\(token) leave, Reduce Motion")
        }
        XCTAssertEqual(Animation.lhEnter(.normal), .timingCurve(0, 0, 0.58, 1, duration: 0.25))
        XCTAssertEqual(Animation.lhLeave(.normal), .timingCurve(0.42, 0, 1, 1, duration: 0.15))
        XCTAssertNotEqual(Animation.lhEnter(.normal), .timingCurve(0, 0, 0.58, 1, duration: 0.22))
    }

    @MainActor
    func testThePaneLookAnimatesOneShareForOpacityAndRise() {
        var look = LHPaneLook(shown: 0, rises: true)
        look.animatableData = 0.5
        XCTAssertEqual(look.shown, 0.5)
        XCTAssertEqual(look.animatableData, 0.5)
    }

    func testThePaneRisesTwoGamePixelsInWholeSteps() {
        XCTAssertEqual(MotionStyle.risePoints(shown: 0, rises: true), 4)
        XCTAssertEqual(MotionStyle.risePoints(shown: 0.5, rises: true), 2)
        XCTAssertEqual(MotionStyle.risePoints(shown: 1, rises: true), 0)
        XCTAssertEqual(MotionStyle.risePoints(shown: 0, rises: false), 0)
        for step in 0...100 {
            let points = MotionStyle.risePoints(shown: Double(step) / 100, rises: true)
            XCTAssertEqual(points.truncatingRemainder(dividingBy: MotionStyle.pointsPerPixel), 0,
                           "a part of a game px at \(step)")
        }
    }

    // MARK: The title's tempos (polish C2)

    /// The title's reveal is the one stage beat with its own tempo and curve (the director's call on thing 8): 1.6 s on
    /// (0.45, 0, 0.25, 1), 116 to 340 game px. The wait breathes 0.5 s / 0.35 s. The step into the game: the raise
    /// 3 x 0.1 s, the close from 0.15 s over 0.45 s on the leave curve, the flame 0.10 s, the hall over the slow token
    /// (0.25 s under Reduce Motion) and the pane the normal token later.
    func testTheTitlesTemposArePinned() {
        XCTAssertEqual(TitleTempo.catchSteps, 6)
        XCTAssertEqual(TitleTempo.catchStepSeconds, 0.2)
        XCTAssertEqual(TitleTempo.breathSteps.high, 6)
        XCTAssertEqual(TitleTempo.breathSteps.low, 5)
        XCTAssertEqual(TitleTempo.breathHighSeconds, 0.5)
        XCTAssertEqual(TitleTempo.breathLowSeconds, 0.35)
        XCTAssertEqual(TitleTempo.revealSeconds, 1.6)
        XCTAssertEqual(TitleTempo.revealCurve, MotionCurve(0.45, 0, 0.25, 1))
        XCTAssertNotEqual(TitleTempo.revealCurve, MotionCurve.enter)
        XCTAssertNotEqual(TitleTempo.revealCurve, MotionCurve.leave)
        XCTAssertEqual(TitleTempo.revealFrom, 116)
        XCTAssertEqual(TitleTempo.revealTo, 340)
        XCTAssertEqual(StepIn.raiseFrames, 3)
        XCTAssertEqual(StepIn.raiseFrameSeconds, 0.1)
        XCTAssertEqual(StepIn.closeFrom, 0.15)
        XCTAssertEqual(StepIn.closeSeconds, 0.45)
        XCTAssertEqual(StepIn.flameSeconds, 0.10)
        XCTAssertEqual(StepIn.blackAt, 0.60, accuracy: 1e-12)
        XCTAssertEqual(StepIn.riseFrom, 0.70, accuracy: 1e-12)
        XCTAssertEqual(StepIn.riseSeconds(.full), MotionToken.slow.inSeconds)
        XCTAssertEqual(StepIn.riseSeconds(.reduced), 0.25)
        XCTAssertEqual(StepIn.reducedFadeSeconds, MotionToken.quick.inSeconds)
        XCTAssertEqual(StepIn.paneDelay, MotionToken.normal.inSeconds)
        XCTAssertEqual(StepIn.hallWholeAt(.full), 1.30, accuracy: 1e-12)
        XCTAssertEqual(StepIn.panesAt(.full), 1.55, accuracy: 1e-12)
        XCTAssertEqual(StepIn.hallWholeAt(.reduced), 0.95, accuracy: 1e-12)
        XCTAssertEqual(StepIn.panesAt(.reduced), 1.20, accuracy: 1e-12)
    }
}
