import Foundation
import XCTest
@testable import Lanternhold

/// The game's fixed-step driver (M2b, `SimDriver`): 60 steps a second whatever the frame rate, no step while paused,
/// in the background, frozen or fallen, the catch-up capped, the king moved through the simulation's own intent.
final class SimDriverTests: XCTestCase {
    private let balance = Balance.standard

    private func morning() -> SimDriver {
        SimDriver(state: GameState.newRealm(seed: 6), balance: balance)
    }

    func testItStepsSixtyTimesASecondWhateverTheFrameRate() {
        var driver = morning()
        var events: [SimEvent] = []
        let hour = driver.state.hour
        var total = 0
        for _ in 0..<10 {
            total += driver.advance(by: 0.1, events: &events)
        }
        XCTAssertEqual(total, 60, accuracy: 1, "ten frames of 0.1 s are sixty steps")
        var odd = morning()
        var steps = 0
        for frame in 0..<120 {
            steps += odd.advance(by: frame % 2 == 0 ? 1.0 / 30 : 1.0 / 120, events: &events)
        }
        XCTAssertEqual(steps, 150, accuracy: 1, "uneven frames still give 60 steps per second")
        XCTAssertEqual(driver.state.hour - hour, Double(driver.steps) * SimDriver.step / DayClock.secondsPerHour,
                       accuracy: 1e-9, "a real second is 1/12 of an in-game hour: the clock is the simulation's")
        XCTAssertEqual(driver.steps, total)
    }

    func testNothingStepsWhilePausedOrInTheBackgroundOrFrozen() {
        var events: [SimEvent] = []
        for setting in ["paused", "background", "frozen", "fallen"] {
            var driver = morning()
            switch setting {
            case "paused": driver.isPaused = true
            case "background": driver.isInBackground = true
            case "frozen": driver.isFrozen = true
            default: driver.state.defeated = true
            }
            let before = driver.state
            XCTAssertFalse(driver.canStep, setting)
            XCTAssertEqual(driver.advance(by: 0.2, events: &events), 0, "\(setting): no step")
            XCTAssertTrue(driver.state == before, "\(setting): the realm stands still")
            // render-2: the accumulator rests at half a step (`SimDriver.startPhase`), no longer at 0.
            XCTAssertEqual(driver.accumulator, SimDriver.startPhase,
                           "\(setting): the time is dropped, not caught up later")
            driver.isPaused = false
            driver.isInBackground = false
            driver.isFrozen = false
            driver.state.defeated = false
            XCTAssertEqual(driver.advance(by: 0.05, events: &events), 3, accuracy: 1, "\(setting): steps again afterwards")
        }
    }

    func testAStallNeverFastForwardsTheWorld() {
        var driver = morning()
        var events: [SimEvent] = []
        XCTAssertEqual(driver.advance(by: 2.0, events: &events), 15, accuracy: 1, "at most a quarter second at once")
        XCTAssertEqual(driver.advance(by: 0, events: &events), 0)
        XCTAssertEqual(driver.advance(by: -1, events: &events), 0)
    }

    func testTheDragMovesTheKingThroughTheSimulationsIntent() {
        var driver = morning()
        var events: [SimEvent] = []
        let start = driver.state.king.x
        driver.setDrag(offset: 3)
        XCTAssertEqual(driver.state.king.velocity, 0, "inside the dead zone he stands")
        driver.setDrag(offset: 20)
        XCTAssertEqual(driver.state.king.velocity, balance.kingWalkSpeed)
        driver.setDrag(offset: -60)
        XCTAssertEqual(driver.state.king.velocity, -balance.kingRunSpeed)
        let steps = driver.advance(by: 0.25, events: &events) + driver.advance(by: 0.25, events: &events)
        XCTAssertEqual(driver.state.king.x, start - balance.kingRunSpeed * Double(steps) * SimDriver.step,
                       accuracy: 0.01, "the sim moved him")
        XCTAssertEqual(driver.state.king.facing, -1)
        driver.setDrag(offset: nil)
        XCTAssertEqual(driver.state.king.velocity, 0, "lifting the finger stops him")
    }

    func testAutoplayPlaysLiveUntilADrag() {
        var driver = SimDriver(state: GameState.newRealm(seed: 6), balance: balance, bot: Autoplay.reference())
        var events: [SimEvent] = []
        let gold = driver.state.gold
        for _ in 0..<12 {
            driver.advance(by: 0.25, events: &events)
        }
        XCTAssertLessThan(driver.state.gold, gold, "the bot ordered its first builds")
        XCTAssertTrue(events.contains { if case .buildOrdered = $0 { return true } else { return false } })
        driver.setDrag(offset: 30)
        XCTAssertNil(driver.bot, "a drag ends autoplay")
        var walker = SimDriver(state: GameState.newRealm(seed: 6), balance: balance)
        walker.walker = KingWalker.around(700)
        walker.advance(by: 0.25, events: &events)
        XCTAssertEqual(walker.state.king.velocity, balance.kingWalkSpeed, "-GWAutoplay walk walks")
    }

    func testTheDawnRenewsTheSnapshotTheSaveWrites() {
        var s = GameState.newRealm(seed: 6)
        var bot = Autoplay.reference()
        Sim.run(&s, untilHour: 5.99, balance: balance, bot: &bot)
        var driver = SimDriver(state: s, balance: balance)
        XCTAssertEqual(driver.dawnSnapshot.day, 1)
        var events: [SimEvent] = []
        for _ in 0..<8 {
            driver.advance(by: 0.25, events: &events)
        }
        XCTAssertEqual(driver.state.day, 2)
        XCTAssertEqual(driver.dawnSnapshot.day, 2, "the dawn's realm is kept for the save")
        XCTAssertEqual(driver.dawnSnapshot.hour, 6, accuracy: 0.01)
        XCTAssertNotNil(driver.dawnSnapshot.lastReport)
    }

    func testTheCameraLooksTowardTheGloomAtNightAtTheFront() {
        var s = GameState.newRealm(seed: 6)
        s.king.x = 654
        s.hour = 12
        XCTAssertEqual(GameModel.cameraLead(s), 0, "by day the camera centres on the king")
        s.hour = 22
        XCTAssertEqual(GameModel.cameraLead(s), -GameModel.nightLead, "at night it looks toward the Gloom")
        s.hour = 19.5
        XCTAssertEqual(GameModel.cameraLead(s), -GameModel.nightLead / 2, accuracy: 1e-9, "eased in through the dusk")
        s.hour = 5.75
        XCTAssertEqual(GameModel.cameraLead(s), -GameModel.nightLead / 4, accuracy: 1e-9, "eased out at first light")
        s.hour = 22
        s.king.x = 1824
        XCTAssertEqual(GameModel.cameraLead(s), 0, "inside the castle it centres on the king")
    }

    func testTheActionButtonLightsASnuffedBrazierAtNight() {
        var s = GameFrameSupport.demoNight()
        let plot = Realm.lines[2].braziers[0]
        s.plots[plot].snuffed = true
        s.king.x = Realm.plots[plot].x
        var driver = SimDriver(state: s, balance: balance)
        XCTAssertEqual(driver.kingAction, KingAction.light(plot: plot))
        var events: [SimEvent] = []
        XCTAssertTrue(driver.perform(.light(plot: plot), events: &events))
        for _ in 0..<6 {
            driver.advance(by: 0.25, events: &events)
        }
        XCTAssertFalse(driver.state.plots[plot].snuffed, "lit again after a second")
    }

    // MARK: - Polish step A1: the walk (`LordGait`; law 1, figures)

    /// A day in the open town (no set piece, no brazier), the lord standing at `x`.
    private func standing(at x: Double = 2700) -> SimDriver {
        var s = GameState.newRealm(seed: 6)
        s.hour = 10
        s.king.x = x
        s.king.velocity = 0
        s.king.facing = 1
        return SimDriver(state: s, balance: balance)
    }

    /// One fixed step (the accumulator rests at half a step, so one step's time runs exactly one step).
    private func step(_ driver: inout SimDriver) {
        var events: [SimEvent] = []
        XCTAssertEqual(driver.advance(by: SimDriver.step, events: &events), 1)
    }

    func testTheWalkAnswersAtOnceAndReachesItsPaceInTwelveHundredths() {
        var driver = standing()
        let walk = balance.kingWalkSpeed
        driver.travel(to: 2800, speed: walk)
        var speeds: [Double] = []
        var x = driver.state.king.x
        for _ in 0..<12 {
            step(&driver)
            speeds.append(driver.state.king.velocity)
            if speeds.count == 1 {
                XCTAssertGreaterThan(driver.state.king.x, x, "he moves in the very first step after the tap")
                XCTAssertEqual(driver.gait.frame, 0, "walk frame 0 first")
            }
            x = driver.state.king.x
        }
        XCTAssertGreaterThan(speeds[0], 0, "the first step is greater than 0")
        XCTAssertLessThan(speeds[0], walk * 0.5, "short of his pace at first")
        let reached = Int((FigureMotion.startSeconds / SimDriver.step - 1e-9).rounded(.up))
        for index in 0..<(reached - 1) {
            XCTAssertLessThan(speeds[index], walk, "step \(index + 1): still ramping")
            XCTAssertLessThan(speeds[index], speeds[index + 1], "step \(index + 1): gaining")
        }
        // 0.12 s is 7.2 steps: the eighth step ends past it and is at full pace.
        XCTAssertEqual(speeds[reached - 1], walk, accuracy: 1e-9, "his pace by 0.12 s")
        XCTAssertEqual(speeds[11], walk, accuracy: 1e-9)
    }

    /// The gait alone at `dt`: from standing at `from` to `to`; every step's x and speed.
    private func gaitWalk(from: Double, to: Double, pace: Double, dt: Double) -> [(x: Double, speed: Double)] {
        var gait = LordGait()
        var x = from
        var velocity = 0.0
        var steps: [(x: Double, speed: Double)] = []
        for _ in 0..<Int(30 / dt) {
            let move = gait.travel(x: x, target: to, want: pace, current: velocity, dt: dt)
            velocity = move.velocity
            x += velocity * dt
            if move.lands {
                XCTAssertEqual(x, to, accuracy: 1e-9, "the landing step reaches the spot")
                x = to
            }
            steps.append((x, abs(velocity)))
            if move.lands { return steps }
        }
        XCTFail("he never arrived (dt \(dt))")
        return steps
    }

    func testTheBrakeEndsExactlyOnTheSpotWithNoOvershootAndNoCreep() {
        for dt in [1.0 / 60, 1.0 / 20] {
            for (from, to, pace) in [(1000.0, 1030.0, 36.0), (1000.0, 970.0, 36.0), (1000.0, 1100.0, 80.0),
                                     (1000.0, 1002.5, 36.0)] {
                let label = "dt \(dt), \(from) to \(to) at \(pace)"
                let way = to > from ? 1.0 : -1.0
                let steps = gaitWalk(from: from, to: to, pace: pace, dt: dt)
                XCTAssertEqual(steps.last?.x, to, "\(label): ends exactly on the spot")
                for step in steps {
                    XCTAssertLessThanOrEqual((step.x - to) * way, 1e-12, "\(label): never past the spot")
                }
                // The brake: within the last 4 px the speed only falls (a walk that starts inside them ramps first),
                // and it never creeps.
                var previous = Double.infinity
                var braking = 0
                for (index, step) in steps.enumerated() where index > 0 && abs(to - steps[index - 1].x) < 4 {
                    if abs(to - from) > 8 {
                        XCTAssertLessThanOrEqual(step.speed, previous + 1e-9, "\(label): the brake only slows")
                    }
                    XCTAssertLessThan(step.speed, pace + 1e-9)
                    previous = step.speed
                    braking += 1
                }
                if abs(to - from) > 8 {
                    XCTAssertGreaterThanOrEqual(braking, dt < 0.03 ? 4 : 1, "\(label): a brake, not a dead stop")
                }
                XCTAssertLessThanOrEqual(Double(braking) * dt, 0.3, "\(label): no creep (\(braking) steps)")
                // Before the last 4 px (once ramped) he walks at his pace.
                for (index, step) in steps.enumerated()
                where Double(index + 1) * dt > FigureMotion.startSeconds + dt && abs(to - step.x) > 4 + pace * dt {
                    XCTAssertEqual(step.speed, pace, accuracy: 1e-9, "\(label): his pace at step \(index)")
                }
            }
        }
    }

    func testTheDriverLandsHimOnTheSpotAndHeStands() {
        var driver = standing()
        driver.travel(to: 2731.25, speed: balance.kingWalkSpeed)
        for _ in 0..<120 { step(&driver) }
        XCTAssertEqual(driver.state.king.x, 2731.25, "exactly on the spot")
        XCTAssertEqual(driver.state.king.velocity, 0)
        XCTAssertNil(driver.travelTarget, "the walk is over")
        XCTAssertEqual(driver.state.king.facing, 1)
        // A tap closer than half a pixel does not move him.
        driver.travel(to: 2731.5, speed: balance.kingWalkSpeed)
        step(&driver)
        XCTAssertEqual(driver.state.king.x, 2731.25)
        XCTAssertNil(driver.travelTarget)
    }

    func testAChangeOfPaceTakesAQuarterSecond() {
        var driver = standing()
        let walk = balance.kingWalkSpeed
        let hurry = TouchRules.hurrySpeed
        driver.travel(to: 3200, speed: walk)
        for _ in 0..<30 { step(&driver) }
        XCTAssertEqual(driver.state.king.velocity, walk, accuracy: 1e-9, "walking")
        driver.travel(to: 3200, speed: hurry)
        var speeds: [Double] = []
        for _ in 0..<24 {
            step(&driver)
            speeds.append(driver.state.king.velocity)
        }
        let reached = Int((FigureMotion.paceChangeSeconds / SimDriver.step - 1e-9).rounded(.up))
        XCTAssertGreaterThan(speeds[0], walk, "it answers at once")
        for index in 0..<(reached - 1) {
            XCTAssertLessThan(speeds[index], hurry, "step \(index + 1): still easing")
            XCTAssertLessThan(speeds[index], speeds[index + 1])
        }
        XCTAssertEqual(speeds[reached - 1], hurry, accuracy: 1e-9, "the hurry by 0.25 s")
        // And back down to the walk, as gently.
        driver.travel(to: 3200, speed: walk)
        step(&driver)
        XCTAssertLessThan(driver.state.king.velocity, hurry)
        XCTAssertGreaterThan(driver.state.king.velocity, walk)
        for _ in 0..<reached { step(&driver) }
        XCTAssertEqual(driver.state.king.velocity, walk, accuracy: 1e-9)
    }

    func testASecondTapTurnsHimAtOnceHoldsAndStartsAgain() {
        var driver = standing()
        let walk = balance.kingWalkSpeed
        driver.travel(to: 2800, speed: walk)
        for _ in 0..<30 { step(&driver) }
        let x = driver.state.king.x
        driver.travel(to: 2600, speed: walk)
        step(&driver)
        XCTAssertEqual(driver.state.king.facing, -1, "the tap turns him in the very next step")
        XCTAssertEqual(driver.state.king.velocity, 0, "and he stands turned")
        XCTAssertEqual(driver.gait.frame, FigureMotion.lordIdleFrame, "the standing pose")
        var held = 1
        while driver.state.king.velocity == 0 && held < 20 {
            step(&driver)
            if driver.state.king.velocity == 0 { held += 1 }
        }
        XCTAssertEqual(Double(held) * SimDriver.step, FigureMotion.turnHoldSeconds, accuracy: SimDriver.step,
                       "the turn holds 0.07 s")
        XCTAssertLessThan(driver.state.king.velocity, 0, "then he walks west")
        XCTAssertGreaterThan(driver.state.king.velocity, -walk, "from the start of his ramp")
        XCTAssertEqual(driver.gait.frame, 0, "walk frame 0 again")
        XCTAssertLessThanOrEqual(driver.state.king.x, x)
        // A second tap the same way only moves the spot: no hold, no dip.
        var on = standing()
        on.travel(to: 2800, speed: walk)
        for _ in 0..<30 { on.travel(to: 2800, speed: walk); step(&on) }
        on.travel(to: 2900, speed: walk)
        step(&on)
        XCTAssertEqual(on.state.king.velocity, walk, accuracy: 1e-9, "on at his pace")
    }

    func testTheHoldsAfterAStopAndTheBreath() {
        var driver = standing()
        driver.travel(to: 2720, speed: balance.kingWalkSpeed)
        while driver.travelTarget != nil { step(&driver) }
        var frames: [Int] = []
        for _ in 0..<150 {
            step(&driver)
            frames.append(driver.gait.frame)
        }
        let hold = Int((FigureMotion.idleHoldSeconds / SimDriver.step).rounded())
        let breathB = Int(((FigureMotion.idleHoldSeconds + FigureMotion.breathA) / SimDriver.step).rounded())
        XCTAssertTrue(frames[0..<hold].allSatisfy { $0 == FigureMotion.lordIdleFrame }, "the standing pose held")
        XCTAssertTrue(frames[0..<(breathB - 1)].allSatisfy { $0 == FigureMotion.lordIdleFrame },
                      "then frame A of the breath first")
        XCTAssertEqual(frames[breathB + 1], FigureMotion.lordIdleFrame + 1, "frame B after 0.25 + 1.15 s")
    }
}
