import Foundation
import XCTest
@testable import Lanternhold

/// Polish step A5 (the gate moves; `GateMotion`): line 1's gate never changes between shut and open in one frame. The
/// closed frame travels in whole rows inside the gateway (0.8 s up on the enter curve, 0.6 s down on the leave curve),
/// on the picture's wall clock, the same at any frame rate; a flip goes on from the row where it stands; after a load
/// it stands at once; under Reduce Motion no row travels, only the opacity changes over 0.15 s. The frame draws it as
/// two cut props (`EntityFrames.gate`, `Prop.cropTop`), the renderer cuts the sprite and its glow occluder alike.
final class GateMotionTests: XCTestCase {
    private let balance = Balance.standard

    /// Steps a gate that stood shut at `start` toward `open` at `rate` frames a second for `seconds`, noting the target
    /// every frame as the model does; returns each frame's time and look.
    private func run(from shut: Bool = true, to open: Bool = true, rate: Double, seconds: Double, start: Double = 10,
                     reduceMotion: Bool = false) -> (gate: GateMotion, frames: [(t: Double, look: GateMotion.Look)]) {
        var gate = GateMotion()
        gate.note(open: !shut, time: start - 1, reduceMotion: reduceMotion)
        var frames: [(t: Double, look: GateMotion.Look)] = []
        let count = Int((seconds * rate).rounded())
        for index in 0...count {
            let t = start + Double(index) / rate
            gate.note(open: open, time: t, reduceMotion: reduceMotion)
            frames.append((t: t, look: gate.look!))
        }
        return (gate, frames)
    }

    // MARK: - The numbers

    func testTheNumbersAreTheBriefsAndTheLaws() {
        XCTAssertEqual(GateMotion.openSeconds, 0.8)
        XCTAssertEqual(GateMotion.closeSeconds, 0.6, "law 1's slow tempo")
        XCTAssertEqual(GateMotion.closeSeconds, MotionToken.slow.inSeconds)
        XCTAssertEqual(GateMotion.reducedSeconds, 0.15, "law 1's quick tempo under Reduce Motion")
        XCTAssertEqual(GateMotion.reducedSeconds, MotionToken.quick.inSeconds)
        XCTAssertEqual(GateMotion.openCurve, MotionCurve.enter, "ease-out: heaved up, it settles")
        XCTAssertEqual(GateMotion.closeCurve, MotionCurve.leave, "ease-in: it drops and lands")
        XCTAssertEqual(GateMotion.fullRows, 60, "the gate frame's full height")
        for sprite in [SpriteID.gateWood, .gateIron, .gateGreat] {
            XCTAssertEqual(sprite.size.height, GateMotion.fullRows, "\(sprite)")
        }
    }

    // MARK: - The travel

    func testTheOpeningRisesInWholeRowsNeverBackAndEndsAtTheFullHeight() {
        var started = GateMotion()
        started.note(open: false, time: 9, reduceMotion: false)
        XCTAssertEqual(started.note(open: true, time: 10, reduceMotion: false), .opens)
        XCTAssertEqual(started.standsOpenAt ?? 0, 10 + GateMotion.openSeconds, accuracy: 1e-9, "open 0.8 s on")
        let (gate, frames) = run(rate: 60, seconds: 1.0)
        XCTAssertEqual(frames[0].look.rows, 0, "no row up in the change's frame")
        XCTAssertEqual(gate.standsOpenAt ?? 0, frames.last!.t, accuracy: 1e-9, "once it stands: the note's own time")
        var last = 0
        var steps = Set<Int>()
        for frame in frames {
            let rows = frame.look.rows
            XCTAssertGreaterThanOrEqual(rows, last, "never back on the way up (t \(frame.t))")
            XCTAssertLessThanOrEqual(rows - last, 6, "whole rows, a few a frame at most (t \(frame.t))")
            XCTAssertEqual(frame.look.openAlpha, 1, "no part alpha in the full form")
            XCTAssertEqual(frame.look.closedAlpha, 1)
            if frame.t >= 10 + GateMotion.openSeconds - 1e-9 {
                XCTAssertEqual(rows, GateMotion.fullRows, "the full height at the end (t \(frame.t))")
            } else {
                XCTAssertLessThan(frame.look.share, 1, "still travelling before the end (t \(frame.t))")
            }
            steps.insert(rows)
            last = rows
        }
        XCTAssertGreaterThan(steps.count, 30, "it travels through the rows, it does not cut")
        // Ease-out: the first half of the time takes more than half of the way.
        let half = frames.first { $0.t >= 10 + GateMotion.openSeconds / 2 - 1e-9 }!
        XCTAssertGreaterThan(half.look.rows, GateMotion.fullRows / 2)
    }

    func testTheClosingFallsInWholeRowsNeverUpAndLands() {
        let (gate, frames) = run(from: false, to: false, rate: 60, seconds: 0.8)
        XCTAssertNil(gate.standsOpenAt, "its target is shut")
        XCTAssertEqual(frames[0].look.rows, GateMotion.fullRows, "still all the way up in the change's frame")
        var last = GateMotion.fullRows
        for frame in frames {
            XCTAssertLessThanOrEqual(frame.look.rows, last, "never up on the way down (t \(frame.t))")
            if frame.t >= 10 + GateMotion.closeSeconds - 1e-9 {
                XCTAssertEqual(frame.look.rows, 0, "shut at the end (t \(frame.t))")
            }
            last = frame.look.rows
        }
        // Ease-in: at half the time less than half of the way is down.
        let half = frames.first { $0.t >= 10 + GateMotion.closeSeconds / 2 - 1e-9 }!
        XCTAssertGreaterThan(half.look.rows, GateMotion.fullRows / 2)
    }

    func testTheSameAtSixtyAndAtOneHundredTwentyFramesASecond() {
        for open in [true, false] {
            let slow = run(from: !open ? false : true, to: open, rate: 60, seconds: 1.0)
            let fast = run(from: !open ? false : true, to: open, rate: 120, seconds: 1.0)
            for (index, frame) in slow.frames.enumerated() {
                let twin = fast.frames[index * 2]
                XCTAssertEqual(twin.t, frame.t, accuracy: 1e-9)
                XCTAssertEqual(twin.look.rows, frame.look.rows, "the same row at the same time (t \(frame.t))")
            }
            XCTAssertEqual(slow.frames.last?.look.rows, fast.frames.last?.look.rows, "the same end")
            XCTAssertEqual(slow.frames.last?.look.rows, open ? GateMotion.fullRows : 0)
        }
    }

    func testAFlipInMidTravelGoesOnFromTheRowWhereItStands() {
        var gate = GateMotion()
        gate.note(open: false, time: 0, reduceMotion: false)
        XCTAssertEqual(gate.note(open: true, time: 1, reduceMotion: false), .opens)
        gate.note(open: true, time: 1.3, reduceMotion: false)
        let standing = gate.look!
        XCTAssertGreaterThan(standing.rows, 0)
        XCTAssertLessThan(standing.rows, GateMotion.fullRows)
        XCTAssertEqual(gate.note(open: false, time: 1.3, reduceMotion: false), .closes, "creatures came near")
        XCTAssertEqual(gate.look?.rows, standing.rows, "it goes on from the row where it stands, no jump")
        let rest = GateMotion.closeSeconds * standing.share
        XCTAssertEqual(gate.remaining, rest, accuracy: 1e-9, "the rest of the way takes its share of the 0.6 s")
        var last = standing.rows
        var t = 1.3
        var landed: Double?
        while t < 1.3 + rest + 0.1 {
            t += 1.0 / 60
            gate.note(open: false, time: t, reduceMotion: false)
            XCTAssertLessThanOrEqual(gate.look!.rows, last, "down from there, never up")
            last = gate.look!.rows
            if landed == nil && !gate.isMoving { landed = t }
        }
        XCTAssertEqual(last, 0)
        XCTAssertEqual(landed ?? 0, 1.3 + rest, accuracy: 1.0 / 60 + 1e-9, "landed after its share of the time")
        // And round again: from the row where it stands, up.
        gate.note(open: true, time: t, reduceMotion: false)
        gate.note(open: true, time: t + 0.2, reduceMotion: false)
        let midway = gate.look!.rows
        gate.note(open: false, time: t + 0.2, reduceMotion: false)
        XCTAssertEqual(gate.look?.rows, midway)
    }

    func testAfterALoadOrAStageChangeTheGateStandsInItsTarget() {
        // A fresh motion (a load, a continued launch, a jump: `GameModel.restartView` makes new effects): no travel.
        var gate = GateMotion()
        XCTAssertNil(gate.look, "nothing noted yet: the frame draws the rule")
        XCTAssertEqual(gate.note(open: true, time: 50, reduceMotion: false), .none)
        XCTAssertEqual(gate.look, .open, "open at once")
        XCTAssertFalse(gate.isMoving)
        var shut = GameMotionSupport.fresh()
        XCTAssertEqual(shut.note(open: false, time: 50, reduceMotion: false), .none)
        XCTAssertEqual(shut.look, .shut)
        // Off the world stage the gate follows its target (a dawn still begins its opening there) ...
        XCTAssertEqual(shut.note(open: true, time: 51, reduceMotion: false, seen: false), .opens)
        XCTAssertTrue(shut.isMoving)
        // ... and on the first frame back it stands in its target.
        XCTAssertEqual(shut.note(open: true, time: 51.1, reduceMotion: false, seen: true), .none)
        XCTAssertEqual(shut.look, .open, "back on the world stage: open at once, no travel on the first frame")
        XCTAssertEqual(shut.standsOpenAt, 51.1)
        // The model's effects: new ones stand the gate on their first note.
        var effects = BattleEffects()
        let day = GameFrameSupport.demoDay()
        XCTAssertEqual(effects.stepGate(day, balance: balance, time: 3, reduceMotion: false, seen: true), .none)
        XCTAssertEqual(effects.gate.look, .open)
    }

    func testRubbleOrNoGateHasNoMotion() {
        var effects = BattleEffects()
        var night = GameFrameSupport.demoNight()
        effects.stepGate(night, balance: balance, time: 1, reduceMotion: false, seen: true)
        night.plots[Realm.lines[0].wall].isRubble = true
        XCTAssertEqual(effects.stepGate(night, balance: balance, time: 2, reduceMotion: false, seen: true), .none)
        XCTAssertNil(effects.gate.look, "rubble: nothing moves")
        XCTAssertNil(effects.gate.standsOpenAt)
        var day = night
        day.hour = 8
        XCTAssertEqual(effects.stepGate(day, balance: balance, time: 3, reduceMotion: false, seen: true), .none,
                       "the dawn over rubble starts nothing")
        // Rebuilt: it stands in its target at once (the standing's own swap is step A2's).
        day.plots[Realm.lines[0].wall].isRubble = false
        XCTAssertEqual(effects.stepGate(day, balance: balance, time: 4, reduceMotion: false, seen: true), .none)
        XCTAssertEqual(effects.gate.look, .open)
        // No gate at all.
        var bare = GameMotionSupport.fresh()
        XCTAssertEqual(bare.note(open: nil, time: 0, reduceMotion: false), .none)
        XCTAssertNil(bare.look)
        XCTAssertNil(EntityFrames.gateTarget(night, balance: balance, isDay: false), "rubble has no target")
    }

    func testUnderReduceMotionNoRowTravelsOnlyTheOpacityOverFifteenHundredths() {
        var started = GateMotion()
        started.note(open: false, time: 9, reduceMotion: true)
        started.note(open: true, time: 10, reduceMotion: true)
        XCTAssertEqual(started.standsOpenAt ?? 0, 10 + GateMotion.reducedSeconds, accuracy: 1e-9, "open 0.15 s on")
        let (_, frames) = run(rate: 60, seconds: 0.4, reduceMotion: true)
        var lastOpen: Float = 0
        for frame in frames {
            XCTAssertEqual(frame.look.rows, 0, "no shifted row in any frame (t \(frame.t))")
            XCTAssertEqual(frame.look.openCut, 0, "no cut")
            XCTAssertEqual(frame.look.openAlpha + frame.look.closedAlpha, 1, accuracy: 1e-6)
            XCTAssertGreaterThanOrEqual(frame.look.openAlpha, lastOpen, "the closed frame fades out, never back")
            lastOpen = frame.look.openAlpha
            if frame.t >= 10 + GateMotion.reducedSeconds - 1e-9 {
                XCTAssertEqual(frame.look.share, 1, "open after 0.15 s")
                XCTAssertFalse(frame.look.showsClosed)
            }
        }
        XCTAssertTrue(frames.contains { $0.look.openAlpha > 0.2 && $0.look.openAlpha < 0.8 }, "a fade, not a cut")
        let down = run(from: false, to: false, rate: 60, seconds: 0.4, reduceMotion: true)
        for frame in down.frames {
            XCTAssertEqual(frame.look.rows, 0)
            if frame.t >= 10 + GateMotion.reducedSeconds - 1e-9 { XCTAssertEqual(frame.look.share, 0) }
        }
    }

    func testAStalledFrameMovesTheGateByTheLongestStepOnly() {
        XCTAssertEqual(GateMotion.longestStep, 0.05)
        var gate = GateMotion()
        gate.note(open: false, time: 0, reduceMotion: false)
        gate.note(open: true, time: 1, reduceMotion: false)
        gate.note(open: true, time: 1.3, reduceMotion: false)
        XCTAssertEqual(gate.travelled, GateMotion.longestStep, accuracy: 1e-12, "a 0.3 s frame moves it 0.05 s on")
        XCTAssertLessThanOrEqual(gate.look!.rows, 7, "a few rows, not most of the way")
        XCTAssertEqual(gate.standsOpenAt ?? 0, 1.3 + GateMotion.openSeconds - GateMotion.longestStep, accuracy: 1e-9,
                       "its open moment moves on with the lost time")
    }

    // MARK: - The cue's lead (gate review A5-P1)

    func testACuedOpeningHoldsItsLeadAndItsLastRowLandsOnTheCuesHit() throws {
        XCTAssertEqual(GateMotion.cueHit, 0.95, "gate.wav's one audible part, the hit")
        XCTAssertEqual(GateMotion.cueLead, 0.2)
        XCTAssertEqual(GateMotion.reducedCueLead, GateMotion.cueHit - GateMotion.reducedSeconds, accuracy: 1e-12)
        var gate = GateMotion()
        gate.note(open: false, time: 9, reduceMotion: false)
        XCTAssertEqual(gate.note(open: true, time: 10, reduceMotion: false, cued: true), .opens)
        XCTAssertTrue(gate.isMoving, "the lead is part of the opening")
        XCTAssertEqual(gate.standsOpenAt ?? 0, 10 + GateMotion.cueLead + GateMotion.openSeconds, accuracy: 1e-9)
        var t = 10.0
        var last = 0
        var landed: Double?
        while t < 11.2 {
            t += 1.0 / 60
            gate.note(open: true, time: t, reduceMotion: false)
            let rows = gate.look!.rows
            if t < 10 + GateMotion.cueLead - 1e-9 { XCTAssertEqual(rows, 0, "the door holds its lead (t \(t))") }
            XCTAssertGreaterThanOrEqual(rows, last, "never back on the way up (t \(t))")
            XCTAssertLessThanOrEqual(rows - last, 6, "whole rows, a few a frame at most (t \(t))")
            if landed == nil && rows == GateMotion.fullRows { landed = t }
            last = rows
        }
        let top = try XCTUnwrap(landed)
        XCTAssertEqual(top - 10, GateMotion.cueHit, accuracy: 1.0 / 60 + 1e-9, "the last row moves on the cue's hit")
        XCTAssertFalse(gate.isMoving)
        // Uncued (creatures gone by day: no cue), and closing: no lead.
        var plain = GateMotion()
        plain.note(open: false, time: 9, reduceMotion: false)
        plain.note(open: true, time: 10, reduceMotion: false)
        XCTAssertEqual(plain.standsOpenAt ?? 0, 10 + GateMotion.openSeconds, accuracy: 1e-9, "no lead without the cue")
        var falling = GateMotion()
        falling.note(open: true, time: 9, reduceMotion: false)
        XCTAssertEqual(falling.note(open: false, time: 10, reduceMotion: false, cued: true), .closes)
        XCTAssertEqual(falling.travelled, 0, "a closing never holds a lead")
        XCTAssertEqual(falling.remaining, GateMotion.closeSeconds, accuracy: 1e-9)
    }

    func testUnderReduceMotionACuedOpeningFadesOnTheCuesHit() {
        var gate = GateMotion()
        gate.note(open: false, time: 9, reduceMotion: true)
        gate.note(open: true, time: 10, reduceMotion: true, cued: true)
        XCTAssertEqual(gate.standsOpenAt ?? 0, 10 + GateMotion.cueHit, accuracy: 1e-9, "the fade ends on the hit")
        var t = 10.0
        while t < 11.1 {
            t += 1.0 / 60
            gate.note(open: true, time: t, reduceMotion: true)
            let look = gate.look!
            XCTAssertEqual(look.rows, 0, "no shifted row (t \(t))")
            if t < 10 + GateMotion.reducedCueLead - 1e-9 { XCTAssertEqual(look.openAlpha, 0, "held (t \(t))") }
            if t >= 10 + GateMotion.cueHit + 1.0 / 120 { XCTAssertEqual(look.share, 1, "open (t \(t))") }
        }
    }

    func testAFlipDuringTheLeadStandsShutAtOnce() {
        var gate = GateMotion()
        gate.note(open: false, time: 9, reduceMotion: false)
        gate.note(open: true, time: 10, reduceMotion: false, cued: true)
        gate.note(open: true, time: 10.1, reduceMotion: false)
        XCTAssertEqual(gate.look?.rows, 0, "still in its lead")
        gate.note(open: false, time: 10.1, reduceMotion: false)
        XCTAssertEqual(gate.look, .shut, "not a row had moved: it stands shut, no jump")
        XCTAssertFalse(gate.isMoving)
        XCTAssertNil(gate.standsOpenAt)
    }

    // MARK: - The frame

    /// The model's effects with the gate opening since `start` and noted at `at`.
    private func opening(at: Double, start: Double = 100, reduceMotion: Bool = false) -> BattleEffects {
        var effects = BattleEffects()
        effects.stepGate(GameFrameSupport.demoNight(), balance: balance, time: start - 1, reduceMotion: reduceMotion,
                         seen: true)
        let day = GameFrameSupport.demoDay()
        XCTAssertEqual(effects.stepGate(day, balance: balance, time: start, reduceMotion: reduceMotion, seen: true),
                       .opens)
        var t = start
        while t < at - 1e-9 {
            t = min(at, t + 1.0 / 60)
            effects.stepGate(day, balance: balance, time: t, reduceMotion: reduceMotion, seen: true)
        }
        return effects
    }

    func testWhileItTravelsTheClosedFrameStandsUpCutAtTheGatewaysTopAndTheOpenFrameShowsBelowIt() throws {
        let effects = opening(at: 100.3)
        let rows = try XCTUnwrap(effects.gate.look?.rows)
        XCTAssertGreaterThan(rows, 0)
        XCTAssertLessThan(rows, GateMotion.fullRows)
        let day = GameFrameSupport.demoDay()
        let (desc, layer) = GameFrameSupport.frame(day, focus: 1360, effects: effects)
        let gates = layer.props.filter { $0.sprite == .gateIron }
        XCTAssertEqual(gates.count, 2, "the open frame and the closed frame share the gateway")
        let open = try XCTUnwrap(gates.first { $0.frame == 2 })
        let closed = try XCTUnwrap(gates.first { $0.frame != 2 })
        XCTAssertLessThan(open.id, closed.id, "the closed frame over the open one")
        XCTAssertEqual(open.x, EntityFrames.gatewayX)
        XCTAssertEqual(closed.x, EntityFrames.gatewayX)
        XCTAssertEqual(open.y, 0, "the open frame where it is")
        XCTAssertEqual(open.cropTop, GateMotion.fullRows - rows, "the open frame only below the closed frame's edge")
        XCTAssertEqual(closed.frame, 0, "the rule's closed frame")
        XCTAssertEqual(closed.y, Double(rows), "the closed frame stands whole rows up")
        XCTAssertEqual(closed.cropTop, rows, "cut at the gateway's top")
        XCTAssertEqual(open.alpha, 1)
        XCTAssertEqual(closed.alpha, 1, "no part alpha in the full form")

        // The plane sprites: the closed frame's quad starts at the shut gate's top row, nothing above the arch.
        let shutDesc = GameFrameSupport.frame(GameFrameSupport.demoNight(), focus: 1360).desc
        let shut = try XCTUnwrap(sprites(shutDesc, .gateIron).first)
        XCTAssertNil(shut.source, "the shut gate whole, as before")
        let drawn = sprites(desc, .gateIron)
        XCTAssertEqual(drawn.count, 2)
        let up = try XCTUnwrap(drawn.first { $0.frame != 2 })
        let below = try XCTUnwrap(drawn.first { $0.frame == 2 })
        XCTAssertEqual(up.rect.x, shut.rect.x)
        XCTAssertEqual(up.rect.y, shut.rect.y, "the closed frame's quad begins at the gateway's top edge")
        XCTAssertEqual(up.rect.w, Float(GateMotion.fullRows - rows))
        XCTAssertEqual(up.source, SIMD4<Float>(0, Float(rows), 46, Float(GateMotion.fullRows - rows)),
                       "its rows from `rows` down: shifted up, the top cut")
        XCTAssertEqual(below.rect.y + below.rect.w, shut.rect.y + shut.rect.w, "the open frame stands on the ground")
        XCTAssertEqual(below.rect.y, up.rect.y + up.rect.w, "the open frame begins at the closed frame's edge")
        XCTAssertEqual(below.source, SIMD4<Float>(0, Float(GateMotion.fullRows - rows), 46, Float(rows)))
        // A glow occluder of a cut sprite is cut the same way.
        for occluder in desc.emissives where occluder.kind == .occluder && occluder.sprite == .gateIron {
            XCTAssertTrue(occluder.source == up.source || occluder.source == below.source,
                          "the occluder shows the cut part")
        }
    }

    func testAtEitherEndOneWholeFrameAsBefore() {
        let day = GameFrameSupport.demoDay()
        let open = GameFrameSupport.frame(day, focus: 1360, effects: opening(at: 101)).layer
            .props.filter { $0.sprite == .gateIron }
        XCTAssertEqual(open.count, 1)
        XCTAssertEqual(open.first?.frame, 2)
        XCTAssertEqual(open.first?.cropTop, 0, "no cut at the end")
        let start = GameFrameSupport.frame(day, focus: 1360, effects: opening(at: 100)).layer
            .props.filter { $0.sprite == .gateIron }
        XCTAssertEqual(start.count, 1, "the change's frame: only the closed frame")
        XCTAssertEqual(start.first?.frame, 0)
        XCTAssertEqual(start.first?.cropTop, 0)
        XCTAssertEqual(start.first?.y, 0)
    }

    func testUnderReduceMotionBothFramesStandInPlaceByOpacity() throws {
        let effects = opening(at: 100.06, reduceMotion: true)
        let look = try XCTUnwrap(effects.gate.look)
        XCTAssertTrue(look.reduced)
        let gates = GameFrameSupport.frame(GameFrameSupport.demoDay(), focus: 1360, effects: effects).layer
            .props.filter { $0.sprite == .gateIron }
        XCTAssertEqual(gates.count, 2)
        XCTAssertTrue(gates.allSatisfy { $0.y == 0 && $0.cropTop == 0 }, "no travel, no cut")
        let open = try XCTUnwrap(gates.first { $0.frame == 2 })
        let closed = try XCTUnwrap(gates.first { $0.frame != 2 })
        XCTAssertEqual(open.alpha, Float(look.share), accuracy: 1e-6)
        XCTAssertEqual(closed.alpha, Float(1 - look.share), accuracy: 1e-6)
        XCTAssertGreaterThan(closed.alpha, 0)
        XCTAssertLessThan(closed.alpha, 1)
    }

    /// Gate review M1: a touch rim is the whole sprite at the prop's place, so on the travelling gate (a cut prop) it
    /// would outline the cut rows above the arch. A cut prop draws no rim; the standing gate keeps its rim.
    func testATravellingGateDrawsNoTouchRimAboveTheArch() throws {
        func rims(_ effects: BattleEffects) -> [EmissiveInstance] {
            let s = GameFrameSupport.demoDay()
            let options = FrameOptions(flickerTime: 1.5)
            let pixelScale = options.pixelScale(physicalWidth: GameFrameSupport.pro.0,
                                                physicalHeight: GameFrameSupport.pro.1)
            let camera = Camera(focusX: 1360, pixelScale: pixelScale)
            let scene = SceneFilter.gameScene(GameFrameSupport.world, state: s)
            var layer = EntityFrames.layer(state: s, balance: .standard, scene: scene, camera: camera,
                                           pixelScale: pixelScale, options: options, animTime: 1.5, effects: effects)
            // The rim part as `TouchRims.mark` puts it on every prop a marked plot's thing stands on.
            let rim = EmissivePart(sprite: .hallMote, dx: 0, dy: 0, color: SIMD3<Float>(1, 0.8, 0.3), intensity: 1,
                                   flickerSeed: nil, fadesByDay: false, isFire: false, rim: true)
            for index in layer.props.indices where layer.props[index].sprite == .gateIron {
                layer.props[index].emissive.append(rim)
            }
            var clock = DayClock(hour: s.hour, day: s.day)
            clock.isFrozen = true
            clock.advance(by: 1.5)
            let desc = FrameBuilder.build(scene: scene, clock: clock, camera: camera, pixelScale: pixelScale,
                                          options: options, entities: layer)
            return desc.emissives.filter { $0.kind == .rim && $0.sprite == .gateIron }
        }
        let travelling = opening(at: 100.3)
        XCTAssertTrue(travelling.gate.isMoving)
        XCTAssertEqual(rims(travelling).count, 0, "no gold outline of the cut door above the arch")
        let standing = opening(at: 101.2)
        XCTAssertFalse(standing.gate.isMoving)
        XCTAssertEqual(rims(standing).count, 1, "the standing gate keeps its rim, as before")
    }

    @MainActor
    func testTheRenderersOccluderShowsThePartItsSourceNames() {
        let layout = AtlasLayout.shared
        let cell = layout.cell(.gateWood, frame: 0)
        let rect = SIMD4<Float>(0, 0, 46, 40)
        let cut = EmissiveInstance(sprite: .gateWood, plane: .world, rect: rect, color: SIMD4<Float>(0, 0, 0, 1),
                                   kind: .occluder, source: SIMD4<Float>(0, 20, 46, 40))
        XCTAssertEqual(Renderer.quad(cut, layout: layout).texel,
                       AtlasCell(x: cell.x, y: cell.y + 20, width: 46, height: 40).texels(flipped: false))
        let whole = EmissiveInstance(sprite: .gateWood, plane: .world, rect: SIMD4<Float>(0, 0, 46, 60),
                                     color: SIMD4<Float>(0, 0, 0, 1), kind: .occluder)
        XCTAssertEqual(Renderer.quad(whole, layout: layout).texel, cell.texels(flipped: false),
                       "every other occluder: the whole cell, as before")
    }

    private func sprites(_ desc: FrameDesc, _ sprite: SpriteID) -> [SpriteInstance] {
        desc.planes.flatMap { $0.sprites }.filter { $0.sprite == sprite }
    }
}

/// A fresh gate motion (named, so a test reads as what it means).
enum GameMotionSupport {
    static func fresh() -> GateMotion { GateMotion() }
}
