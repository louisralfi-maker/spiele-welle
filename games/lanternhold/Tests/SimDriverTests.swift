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

    /// Step A1b rewrote this test: a drag walks him through the simulation's intent as a tap does (the start, the
    /// turn, the brake), no longer at full pace and to a stop within the call.
    func testTheDragMovesTheKingThroughTheSimulationsIntent() {
        var driver = morning()
        var events: [SimEvent] = []
        let start = driver.state.king.x
        driver.setDrag(offset: 3)
        driver.advance(by: 0.25, events: &events)
        XCTAssertEqual(driver.state.king.velocity, 0, "inside the dead zone he stands")
        XCTAssertEqual(driver.state.king.x, start)
        driver.setDrag(offset: 20)
        driver.advance(by: 0.25, events: &events)
        XCTAssertEqual(driver.state.king.velocity, balance.kingWalkSpeed, "the walk, once started")
        let walked = driver.state.king.x
        XCTAssertGreaterThan(walked, start)
        driver.setDrag(offset: -60)
        driver.advance(by: 0.25, events: &events)
        driver.advance(by: 0.25, events: &events)
        XCTAssertEqual(driver.state.king.velocity, -balance.kingRunSpeed, "turned, then the run")
        XCTAssertLessThan(driver.state.king.x, walked, "the sim moved him")
        XCTAssertEqual(driver.state.king.facing, -1)
        let lifted = driver.state.king.x
        driver.setDrag(offset: nil)
        for _ in 0..<30 { driver.advance(by: SimDriver.step, events: &events) }
        XCTAssertEqual(driver.state.king.velocity, 0, "lifting the finger stops him")
        XCTAssertEqual(lifted - driver.state.king.x, FigureMotion.brakePixels, accuracy: 1e-9,
                       "after the brake, 4 px on from where the finger let go")
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

    // MARK: - Step A1b: a drag walks like a tap, the hall's walker the same, law 1's numbers

    /// The walk pad held at `offset` from standing; every step's velocity.
    private func dragged(_ driver: inout SimDriver, offset: Double, steps: Int) -> [Double] {
        driver.setDrag(offset: offset)
        var speeds: [Double] = []
        for _ in 0..<steps {
            step(&driver)
            speeds.append(driver.state.king.velocity)
        }
        return speeds
    }

    func testADragStartsAsATapDoesAndReachesItsPaceInTwelveHundredths() {
        for (offset, pace) in [(20.0, balance.kingWalkSpeed), (-60.0, -balance.kingRunSpeed)] {
            var driver = standing()
            driver.state.king.facing = offset > 0 ? 1 : -1
            let x = driver.state.king.x
            driver.setDrag(offset: offset)
            step(&driver)
            let first = driver.state.king.velocity
            XCTAssertGreaterThan(first * pace, 0, "\(offset): the first step moves him his way")
            XCTAssertLessThan(abs(first), abs(pace), "\(offset): short of his pace at first")
            XCTAssertNotEqual(driver.state.king.x, x)
            XCTAssertEqual(driver.gait.frame, 0, "\(offset): walk frame 0 first")
            var speeds = [first]
            speeds += dragged(&driver, offset: offset, steps: 11)
            let reached = Int((0.12 / SimDriver.step - 1e-9).rounded(.up))
            for index in 0..<(reached - 1) {
                XCTAssertLessThan(abs(speeds[index]), abs(speeds[index + 1]), "\(offset): gaining at \(index + 1)")
            }
            XCTAssertEqual(speeds[reached - 1], pace, accuracy: 1e-9, "\(offset): his pace by 0.12 s")
            XCTAssertEqual(speeds[11], pace, accuracy: 1e-9)
        }
    }

    func testADragChangesBetweenTheWalkAndTheRunInAQuarterSecond() {
        var driver = standing()
        let walk = balance.kingWalkSpeed
        let run = balance.kingRunSpeed
        _ = dragged(&driver, offset: 20, steps: 30)
        XCTAssertEqual(driver.state.king.velocity, walk, accuracy: 1e-9)
        let up = dragged(&driver, offset: 60, steps: 20)
        let reached = Int((0.25 / SimDriver.step - 1e-9).rounded(.up))
        XCTAssertGreaterThan(up[0], walk, "it answers at once")
        for index in 0..<(reached - 1) {
            XCTAssertLessThan(up[index], run, "step \(index + 1): still easing")
            XCTAssertLessThan(up[index], up[index + 1])
        }
        XCTAssertEqual(up[reached - 1], run, accuracy: 1e-9, "the run by 0.25 s")
        let down = dragged(&driver, offset: 25, steps: 20)
        XCTAssertLessThan(down[0], run)
        XCTAssertGreaterThan(down[0], walk)
        XCTAssertEqual(down[reached - 1], walk, accuracy: 1e-9, "the walk again by 0.25 s")
    }

    func testADragReversedTurnsHimHoldsAndStartsAgain() {
        var driver = standing()
        let walk = balance.kingWalkSpeed
        _ = dragged(&driver, offset: 20, steps: 30)
        driver.setDrag(offset: -20)
        step(&driver)
        XCTAssertEqual(driver.state.king.facing, -1, "the reversal turns him in the very next step")
        XCTAssertEqual(driver.state.king.velocity, 0, "and he stands turned")
        XCTAssertEqual(driver.gait.frame, FigureMotion.lordIdleFrame)
        var held = 1
        while driver.state.king.velocity == 0 && held < 20 {
            step(&driver)
            if driver.state.king.velocity == 0 { held += 1 }
        }
        XCTAssertEqual(Double(held) * SimDriver.step, 0.07, accuracy: SimDriver.step, "the turn's 0.07 s hold")
        XCTAssertLessThan(driver.state.king.velocity, 0)
        XCTAssertGreaterThan(driver.state.king.velocity, -walk, "from the start of the ramp")
        XCTAssertEqual(driver.gait.frame, 0, "walk frame 0 again")
    }

    /// The finger lets go: the gait alone at `dt` as the driver runs it (the drag's pace, then the brake to 4 × (speed /
    /// pace)² on); where he comes to rest and every step's x.
    private func letGo(after: Int, offset: Double, dt: Double) -> (release: Double, xs: [Double]) {
        var gait = LordGait()
        let pace = (abs(offset) > 40 ? balance.kingRunSpeed : balance.kingWalkSpeed) * (offset > 0 ? 1 : -1)
        var x = 1000.0
        var velocity = 0.0
        for _ in 0..<after {
            velocity = gait.drive(want: pace, current: velocity, dt: dt).velocity
            x += velocity * dt
        }
        let release = x
        let spot = x + Double(gait.direction) * gait.brakeDistance
        var xs: [Double] = []
        for _ in 0..<Int(5 / dt) {
            guard spot != x else { break }
            let move = gait.travel(x: x, target: spot, want: gait.paceTo, current: velocity, dt: dt)
            velocity = move.velocity
            x += velocity * dt
            if move.lands {
                XCTAssertEqual(x, spot, accuracy: 1e-9)
                x = spot
            }
            xs.append(x)
            if move.lands { break }
        }
        return (release, xs)
    }

    func testLettingGoBrakesOverFourPixelsExactlyWithNoCreep() {
        for dt in [1.0 / 60, 1.0 / 20] {
            for offset in [20.0, -20.0, 60.0, -60.0] {
                for after in [2, 5, 60] {
                    let label = "dt \(dt), drag \(offset), let go after \(after) steps"
                    let way = offset > 0 ? 1.0 : -1.0
                    let (release, xs) = letGo(after: after, offset: offset, dt: dt)
                    let rest = xs.last ?? release
                    XCTAssertGreaterThanOrEqual((rest - release) * way, 0, "\(label): on, never back")
                    XCTAssertLessThanOrEqual((rest - release) * way, 4 + 1e-9, "\(label): at most 4 px on")
                    if Double(after) * dt > 0.12 + dt {
                        XCTAssertEqual((rest - release) * way, 4, accuracy: 1e-9, "\(label): 4 px from his pace")
                    }
                    var previous = release
                    for x in xs {
                        XCTAssertGreaterThanOrEqual((x - previous) * way, -1e-12, "\(label): no step back")
                        XCTAssertLessThanOrEqual((x - rest) * way, 1e-12, "\(label): never past where he rests")
                        previous = x
                    }
                    XCTAssertLessThanOrEqual(Double(xs.count) * dt, 0.3, "\(label): no creep (\(xs.count) steps)")
                }
            }
        }
        // Through the driver: let go at a run, he stands 4 px on and stays.
        var driver = standing()
        _ = dragged(&driver, offset: 60, steps: 40)
        let release = driver.state.king.x
        driver.setDrag(offset: nil)
        var steps = 0
        while driver.state.king.velocity != 0 && steps < 60 {
            step(&driver)
            steps += 1
        }
        XCTAssertEqual(driver.state.king.x - release, 4, accuracy: 1e-9)
        XCTAssertLessThanOrEqual(steps, 6, "the brake at a run")
        XCTAssertEqual(driver.gait.frame, FigureMotion.lordIdleFrame, "the landing step draws the standing pose")
        for _ in 0..<30 { step(&driver) }
        XCTAssertEqual(driver.state.king.x - release, 4, accuracy: 1e-9, "no creep")
        // Someone else stops him (an errand at once): the drag's walk ends there.
        var stopped = standing()
        _ = dragged(&stopped, offset: 20, steps: 30)
        stopped.state.king.velocity = 0
        let x = stopped.state.king.x
        for _ in 0..<10 { step(&stopped) }
        XCTAssertEqual(stopped.state.king.x, x, "stopped from outside, he stays")
    }

    /// The hall's walker (`HallWalker`): the same start, change of pace, turn and brake as in the world.
    func testTheHallsWalkerStartsTurnsAndBrakesAsInTheWorld() {
        let dt = 1.0 / 60
        var walker = HallWalker(x: 200, facing: 1)
        walker.setDrag(offset: 20, deadZone: 6, runDistance: 40)
        var speeds: [Double] = []
        for _ in 0..<30 {
            walker.step(dt: dt)
            speeds.append(walker.velocity)
        }
        XCTAssertGreaterThan(speeds[0], 0, "the first step moves him")
        XCTAssertLessThan(speeds[0], KingState.walkSpeed, "short of his pace")
        XCTAssertEqual(speeds[7], KingState.walkSpeed, accuracy: 1e-9, "his pace by 0.12 s")
        walker.setDrag(offset: 60, deadZone: 6, runDistance: 40)
        var run: [Double] = []
        for _ in 0..<20 {
            walker.step(dt: dt)
            run.append(walker.velocity)
        }
        XCTAssertLessThan(run[13], KingState.runSpeed)
        XCTAssertEqual(run[14], KingState.runSpeed, accuracy: 1e-9, "the run by 0.25 s")
        let release = walker.x
        walker.setDrag(offset: nil, deadZone: 6, runDistance: 40)
        var steps = 0
        while walker.velocity != 0 && steps < 60 {
            walker.step(dt: dt)
            steps += 1
        }
        XCTAssertEqual(walker.x - release, 4, accuracy: 1e-9, "let go: 4 px on, exactly")
        XCTAssertEqual(walker.gait.frame, FigureMotion.lordIdleFrame, "the landing step draws the standing pose")
        for _ in 0..<30 { walker.step(dt: dt) }
        XCTAssertEqual(walker.x - release, 4, accuracy: 1e-9, "no creep")
        // A reversal: the turn's hold.
        walker.setDrag(offset: 20, deadZone: 6, runDistance: 40)
        for _ in 0..<30 { walker.step(dt: dt) }
        walker.setDrag(offset: -20, deadZone: 6, runDistance: 40)
        walker.step(dt: dt)
        XCTAssertEqual(walker.facing, -1)
        XCTAssertEqual(walker.velocity, 0)
        var held = 1
        while walker.velocity == 0 && held < 20 {
            walker.step(dt: dt)
            if walker.velocity == 0 { held += 1 }
        }
        XCTAssertEqual(Double(held) * dt, 0.07, accuracy: dt, "the turn's 0.07 s hold")
        XCTAssertLessThan(walker.velocity, 0)
        // A walk to a place: the start, the brake, exactly on the spot.
        var to = HallWalker(x: 200, facing: 1)
        to.walk(to: 250.5, speed: KingState.walkSpeed)
        to.step(dt: dt)
        XCTAssertGreaterThan(to.velocity, 0)
        XCTAssertLessThan(to.velocity, KingState.walkSpeed)
        for _ in 0..<200 { to.step(dt: dt) }
        XCTAssertEqual(to.x, 250.5, "exactly on the spot")
        XCTAssertNil(to.target)
        XCTAssertEqual(to.velocity, 0)
        // Stopped from outside (an errand, the walk out past the door): he stays.
        var outside = HallWalker(x: 200, facing: 1)
        outside.setDrag(offset: 20, deadZone: 6, runDistance: 40)
        for _ in 0..<30 { outside.step(dt: dt) }
        outside.velocity = 0
        outside.target = nil
        let x = outside.x
        for _ in 0..<10 { outside.step(dt: dt) }
        XCTAssertEqual(outside.x, x)
    }

    /// Law 1, figures (step A1b, A1-C7): the figures' own numbers by their literal values, and the ones that are a
    /// tempo of `Motion` pointing at it.
    func testTheFiguresNumbersAreLawOnesByTheirValues() {
        XCTAssertEqual(FigureMotion.startSeconds, 0.12, "start 0.12 s")
        XCTAssertEqual(FigureMotion.brakePixels, 4, "brake over 4 px")
        XCTAssertEqual(FigureMotion.turnHoldSeconds, 0.07, "turn hold 0.07 s")
        XCTAssertEqual(FigureMotion.lordStride, 4, "stride 4 px")
        XCTAssertEqual(FigureMotion.breathA, 1.15, "idle 1.15 s")
        XCTAssertEqual(FigureMotion.breathB, 0.85, "and 0.85 s")
        XCTAssertEqual(FigureMotion.phaseStep, 0.37, "phase id x 0.37 s")
        XCTAssertEqual(FigureMotion.idleHoldSeconds, 0.25, "idle hold 0.25 s")
        XCTAssertEqual(FigureMotion.idleHoldSeconds, MotionToken.normal.inSeconds, "the normal tempo")
        XCTAssertEqual(FigureMotion.paceChangeSeconds, 0.25, "pace change 0.25 s")
        XCTAssertEqual(FigureMotion.paceChangeSeconds, MotionToken.normal.inSeconds, "the normal tempo")
        XCTAssertEqual(Camera.followOmega, Motion.followOmega, "the camera's follow is the settle token's spring")
        // The start runs on Motion's enter curve.
        var gait = LordGait()
        let dt = SimDriver.step
        for index in 1...7 {
            let speed = gait.drive(want: 36, current: 0, dt: dt).velocity
            XCTAssertEqual(speed, 36 * Motion.enter(Double(index) * dt / 0.12), accuracy: 1e-9, "step \(index)")
        }
    }
}
