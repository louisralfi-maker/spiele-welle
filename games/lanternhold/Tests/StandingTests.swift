import Foundation
import XCTest
@testable import Lanternhold

/// Polish step A2, "it stands" (polish audit thing 4, M4 = F4; ROUND.md law 1 and law 4's step 3): a building's finish
/// in the drawing. The simulation counts the work at its `buildDone`; the picture keeps the scaffold over the old picture
/// for 0.12 s while dust rises at the work's foot over its width, swaps in one frame, settles 1 px; a wall turned
/// damaged or rubble drops 1 px for 0.05 s; Reduce Motion fades the scaffold over the new sprite; `.buildStood` plays
/// once per building at the swap, at the plot's x, and nothing answers the event itself.
@MainActor
final class StandingTests: XCTestCase {
    private let balance = Balance.standard
    private let frame = 1.0 / 60
    private let pro = FrameOptions(flickerTime: 1.5).pixelScale(physicalWidth: 2622, physicalHeight: 1206)

    /// A day realm (the demo build) with `plot` holding `old` under a finished job toward `target`; the realm the frame
    /// before the event drew, and the one the simulation has after it with the event.
    private func finishing(_ plot: Int, from old: BuildItem?, to target: BuildItem, rebuild: Bool = false,
                           base: GameState? = nil) -> (before: GameState, after: GameState, events: [SimEvent]) {
        var before = base ?? GameFrameSupport.demoDay()
        before.plots[plot].item = old
        before.plots[plot].isRubble = rebuild
        before.plots[plot].hp = old.map { $0.isWall ? Build.maxHP($0, balance: balance) * (rebuild ? 0 : 1) : 0 } ?? 0
        let total = Build.work(target, rebuild: rebuild, balance: balance)
        before.plots[plot].job = BuildJob(target: target, work: total, total: total, isRebuild: rebuild, order: 99)
        var after = before
        var events: [SimEvent] = []
        Build.complete(&after, plot: plot, balance: balance, events: &events)
        return (before, after, events)
    }

    /// One frame of the model's effects: `seconds` on the standings' clock, the frame's events.
    @discardableResult
    private func step(_ effects: inout BattleEffects, _ events: [SimEvent] = [], before: [PlotState] = [],
                      state: GameState, seconds: Double? = nil, reduceMotion: Bool = false,
                      castleGrows: Bool = true, listenerX: Double? = nil) -> [Double] {
        effects.stand(events, before: before, state: state, balance: balance, seconds: seconds ?? frame,
                      reduceMotion: reduceMotion, castleGrows: castleGrows, listenerX: listenerX)
    }

    /// Steps until the standings' clock is `age` seconds after the first standing's event.
    @discardableResult
    private func run(_ effects: inout BattleEffects, to age: Double, state: GameState,
                     reduceMotion: Bool = false, listenerX: Double? = nil) -> [Double] {
        let start = effects.standings.first?.start ?? effects.standClock
        var due: [Double] = []
        while effects.standClock - start < age - 1e-9 {
            let left = age - (effects.standClock - start)
            due += step(&effects, state: state, seconds: min(frame, left), reduceMotion: reduceMotion,
                        listenerX: listenerX)
        }
        return due
    }

    private func props(_ s: GameState, effects: BattleEffects = BattleEffects(), options: FrameOptions? = nil)
        -> [Prop] {
        var opts = options ?? FrameOptions(flickerTime: 1.5)
        opts.flickerTime = 1.5
        let camera = Camera(focusX: 1500, pixelScale: pro)
        let scene = SceneFilter.gameScene(GameFrameSupport.world, state: s)
        return EntityFrames.layer(state: s, balance: balance, scene: scene, camera: camera, pixelScale: pro,
                                  options: opts, animTime: 1.5, effects: effects).props
    }

    /// The dust in a frame: its puffs (no other actor is a smoke puff; the chimneys' are the scene's) and its motes
    /// (the flakes tinted above 1).
    private func shards(_ s: GameState, effects: BattleEffects, focus: Double) -> [ActorInstance] {
        GameFrameSupport.frame(s, focus: focus, effects: effects).layer.actors.filter {
            $0.sprite == .smokePuff || ($0.sprite == .sootFlake && $0.tint.x > 1)
        }
    }

    // MARK: - Part 1: the old picture, the swap, the settle

    /// Every kind of work that ends in `buildDone` (the line's wall, the gate, a tower, a brazier, an engine, a stake
    /// pit, the beacon, the smithy, the lodge, a house): before 0.12 s the props are exactly the old picture's (its
    /// scaffold over what stood), from the swap the new sprite's with no scaffold at the plot, 1 px high, and after the
    /// settle exactly the finished realm's.
    func testEveryWorkKeepsItsOldPictureUntilTheSwapThenSettles() {
        let works: [(plot: Int, old: BuildItem?, target: BuildItem)] = [
            (Realm.lines[1].wall, .palisade, .stoneWall), (Realm.lines[0].wall, .ironGate, .greatGate),
            (Realm.lines[1].tower, nil, .archerTower), (Realm.lines[1].braziers[0], nil, .brazier),
            (Realm.lines[1].engine, nil, .ballista), (Realm.lines[1].trap, nil, .stakePit),
            (Realm.beaconPlot, .beaconTower, .greatBeacon), (Realm.smithyPlot, .smithy, .masterSmithy),
            (Realm.lodgePlot, .lodge, .bigLodge), (Realm.townPlots[2], .house, .bigHouse),
        ]
        for work in works {
            let (before, after, events) = finishing(work.plot, from: work.old, to: work.target)
            XCTAssertEqual(events, [.buildDone(plot: work.plot)], "\(work.target)")
            var effects = BattleEffects()
            step(&effects, state: before)
            XCTAssertTrue(step(&effects, events, before: before.plots, state: after).isEmpty,
                          "\(work.target): nothing sounds at the event")
            let old = props(before)
            XCTAssertEqual(props(after, effects: effects), old, "\(work.target): the event's frame is the old picture")
            XCTAssertTrue(run(&effects, to: 0.11, state: after).isEmpty)
            XCTAssertEqual(props(after, effects: effects), old, "\(work.target): 0.11 s, still the old picture")
            let due = run(&effects, to: BattleEffects.standSwap, state: after)
            XCTAssertEqual(due, [Realm.plots[work.plot].x], "\(work.target): it sounds once at the swap, at the plot's x")
            let finished = props(after)
            let swapped = props(after, effects: effects)
            XCTAssertEqual(swapped.count, finished.count, "\(work.target): the swap's frame has the new picture's props")
            var lifted = 0
            for (shown, plain) in zip(swapped, finished) {
                XCTAssertEqual(shown.sprite, plain.sprite)
                XCTAssertEqual(shown.x, plain.x)
                XCTAssertTrue(shown.y == plain.y || shown.y == plain.y + 1, "\(work.target): whole px, at most 1 high")
                if shown.y == plain.y + 1 { lifted += 1 }
            }
            XCTAssertGreaterThan(lifted, 0, "\(work.target): the new sprite is drawn 1 px above its place")
            XCTAssertEqual(swapped.filter { $0.sprite == .scaffold }.count, finished.filter { $0.sprite == .scaffold }.count,
                           "\(work.target): the scaffold has gone in the swap's frame")
            XCTAssertTrue(run(&effects, to: 1.0, state: after).isEmpty, "\(work.target): it sounds once")
            XCTAssertEqual(props(after, effects: effects), finished, "\(work.target): settled, the finished picture")
        }
    }

    /// The settle is one whole pixel and falls once: 1 px from the swap until the eased lift passes half a pixel
    /// (0.12 + 0.15 x 0.3425 = 0.171 s after the event: the fourth frame after the swap at 60 fps), then 0.
    func testTheSettleIsOnePixelAndFallsOnce() {
        XCTAssertEqual(BattleEffects.standSwap, 0.12)
        XCTAssertEqual(BattleEffects.standSettle, 0.15)
        XCTAssertEqual(BattleEffects.settleFall, 0.12 + 0.15 * MotionCurve.enter.time(at: 0.5), accuracy: 1e-12)
        XCTAssertEqual(BattleEffects.settleFall, 0.1714, accuracy: 0.0005)
        let plot = Realm.lines[1].wall
        let (before, after, events) = finishing(plot, from: .palisade, to: .stoneWall)
        var effects = BattleEffects()
        step(&effects, events, before: before.plots, state: after)
        var seen: [Double] = []
        let start = effects.standings[0].start
        while effects.standClock - start < 0.4 {
            step(&effects, state: after)
            seen.append(effects.shifts(reduceMotion: false)[plot] ?? 0)
            let age = effects.standClock - start
            if age < BattleEffects.standSwap - 1e-9 || age >= BattleEffects.settleFall + 1e-9 {
                XCTAssertEqual(effects.shifts(reduceMotion: false)[plot] ?? 0, 0, "age \(age)")
            } else if age < BattleEffects.settleFall - 1e-9 {
                XCTAssertEqual(effects.shifts(reduceMotion: false)[plot], 1, "age \(age)")
            }
        }
        XCTAssertEqual(Set(seen), [0, 1], "whole pixels only")
        let ones = seen.enumerated().filter { $0.element == 1 }.map(\.offset)
        XCTAssertEqual(ones, Array((ones.first ?? 0)...(ones.last ?? 0)), "one step up, one step down")
        // The event on a frame: the swap's frame is the first at or after 0.12 s (8/60 = 0.133 s), the 1 px comes down
        // in the frame at 11/60 = 0.183 s (the first after 0.171 s): 1 px high for three frames.
        XCTAssertEqual(ones.count, 3, "1 px high in the swap's frame and the two after it at 60 fps")
        XCTAssertEqual(ones.first, 7, "the swap's frame: the eighth after the event")
    }

    // MARK: - The dust

    /// The dust starts at the event at the work's foot over its whole width (the chimney's puffs and two grey flakes
    /// tinted to pale stone dust: the broken wall's soot shards did not read on the day's ground), is fullest at the
    /// swap (every particle in, at full alpha, risen 1 to 9 px over the foot), then thins and is gone by 1.1 s. Its own kind (`standDust`); the broken wall's dust stays as it was.
    func testTheDustRisesOverTheWorksWidthAndPeaksAtTheSwap() throws {
        let plot = Realm.lines[1].wall
        let (before, after, events) = finishing(plot, from: .palisade, to: .stoneWall)
        var effects = BattleEffects()
        step(&effects, events, before: before.plots, state: after)
        let dust = try XCTUnwrap(effects.items.first { $0.kind == .standDust })
        XCTAssertEqual(effects.items.filter { $0.kind == .standDust }.count, 1, "one dust, no keep (not the gate)")
        // The palisade's scaffold for the stone wall, from the wall's left over the stone wall's 36 px, and the stone
        // wall's anchor's end piece that appears with it, to 56 px right of the wall's left (`EntityFrames.anchorReach`).
        XCTAssertEqual(dust.x, Realm.wallX[1] + 28)
        XCTAssertEqual(dust.width, 56)
        XCTAssertEqual(dust.y, 0)
        XCTAssertEqual(dust.plane, .world)
        // A new palisade: from the wall's left over its scaffold and the palisade anchor's door piece (31 px).
        let wood = finishing(plot, from: nil, to: .palisade)
        var fresh = BattleEffects()
        step(&fresh, wood.events, before: wood.before.plots, state: wood.after)
        let woodDust = try XCTUnwrap(fresh.items.first { $0.kind == .standDust })
        XCTAssertEqual(woodDust.x - woodDust.width / 2, Realm.wallX[1], accuracy: 1e-9)
        XCTAssertGreaterThanOrEqual(woodDust.x + woodDust.width / 2, Realm.wallX[1] + 31 - 1e-9)
        XCTAssertEqual(dust.lifetime, 1.1)
        let focus = 960.0
        let camera = Camera(focusX: focus, pixelScale: pro)
        let ground = Camera.groundDeviceY(physicalHeight: pro.physicalHeight, scale: pro.scale)
        let scale = pro.scale
        func lifts(_ list: [ActorInstance]) -> [Int] { list.map { ground - Int($0.rect.y + $0.rect.w) } }
        let count = BattleEffects.standDustCount(width: dust.width)
        let first = shards(after, effects: effects, focus: focus)
        XCTAssertEqual(first.count, count, "every particle at the event")
        XCTAssertTrue(lifts(first).allSatisfy { $0 == 0 }, "at the foot")
        run(&effects, to: BattleEffects.standSwap, state: after)
        let peak = shards(after, effects: effects, focus: focus)
        XCTAssertEqual(peak.count, count)
        XCTAssertTrue(peak.allSatisfy { $0.tint.w == 1 }, "fullest at the swap")
        XCTAssertTrue(lifts(peak).allSatisfy { $0 >= 1 * scale && $0 <= 9 * scale }, "risen over the foot: \(lifts(peak))")
        XCTAssertEqual(peak.filter { $0.sprite == .smokePuff }.count, BattleEffects.standPuffCount(width: dust.width),
                       "round puffs")
        let left = camera.deviceX(worldX: dust.x - dust.width / 2 - 2, scale: scale, mode: .smooth)
        let right = camera.deviceX(worldX: dust.x + dust.width / 2 + 2, scale: scale, mode: .smooth)
        let anchors = peak.map { Int($0.rect.x + $0.rect.z / 2) }
        XCTAssertTrue(anchors.allSatisfy { $0 >= left && $0 <= right }, "over the work's width")
        XCTAssertGreaterThan((anchors.max() ?? 0) - (anchors.min() ?? 0), 20 * scale, "spread over it, not a puff")
        run(&effects, to: 0.6, state: after)
        let thinning = shards(after, effects: effects, focus: focus)
        XCTAssertTrue(thinning.allSatisfy { $0.tint.w < 1 && $0.tint.w > 0 }, "thinning")
        run(&effects, to: 1.15, state: after)
        XCTAssertTrue(shards(after, effects: effects, focus: focus).isEmpty, "gone after 1.1 s")
        effects.prune(time: 0)
        XCTAssertTrue(effects.items.isEmpty, "pruned by the standings' clock")
        XCTAssertTrue(effects.standings.isEmpty)
        // The broken wall keeps its own dust, at the animation's time.
        var broken = BattleEffects()
        broken.note([.wallBroken(plot: plot)], state: after, balance: balance, time: 3)
        XCTAssertEqual(broken.items.map(\.kind), [.wallDust])
    }

    /// The gate of A2 (A2-P1, M1, M2): in the swap's frame the puffs are all at their largest frame and together cover
    /// at least nine tenths of the work's width at its foot; their cover (area x alpha) is greater there than halfway
    /// up the rise (0.06 s) and than after it (0.3 s).
    func testTheDustCoversTheFootAtTheSwap() throws {
        let plot = Realm.lines[1].wall
        let (before, after, events) = finishing(plot, from: .palisade, to: .stoneWall)
        var effects = BattleEffects()
        step(&effects, events, before: before.plots, state: after)
        let dust = try XCTUnwrap(effects.items.first { $0.kind == .standDust })
        let focus = 960.0
        let camera = Camera(focusX: focus, pixelScale: pro)
        let scale = Float(pro.scale)
        let cell = Float(SpriteID.smokePuff.size.width)
        func puffs() -> [ActorInstance] {
            GameFrameSupport.frame(after, focus: focus, effects: effects).layer.actors.filter { $0.sprite == .smokePuff }
        }
        func cover(_ list: [ActorInstance]) -> Float {
            list.reduce(0) { sum, puff in
                let side = Float(CastleSmoke.side(frame: puff.frame))
                return sum + side * side * puff.tint.w
            }
        }
        run(&effects, to: 0.06, state: after)
        let rising = cover(puffs())
        run(&effects, to: BattleEffects.standSwap, state: after)
        let peak = puffs()
        XCTAssertEqual(peak.count, BattleEffects.standPuffCount(width: dust.width))
        XCTAssertTrue(peak.allSatisfy { $0.frame == CastleSmoke.sizes - 1 }, "the largest frame at the swap")
        let left = camera.deviceX(worldX: dust.x - dust.width / 2, scale: pro.scale, mode: .smooth)
        let right = camera.deviceX(worldX: dust.x + dust.width / 2, scale: pro.scale, mode: .smooth)
        var covered = Set<Int>()
        for puff in peak {
            let side = Float(CastleSmoke.side(frame: puff.frame))
            let x0 = Int(puff.rect.x + ((cell - side) / 2).rounded(.down) * scale)
            for column in x0..<(x0 + Int(side * scale)) where column >= left && column < right { covered.insert(column) }
        }
        XCTAssertGreaterThanOrEqual(Double(covered.count), 0.9 * Double(right - left), "the foot covered")
        let full = cover(peak)
        run(&effects, to: 0.3, state: after)
        let later = cover(puffs())
        XCTAssertGreaterThan(full, rising, "growing to the swap")
        XCTAssertGreaterThan(full, later, "thinning after it")
    }

    /// The gate raised a tier (look 2's castle grows with it): the keep gets a second dust at its own foot on the
    /// mistBand plane, silent (one building, one answer), and its scene swaps with the gate (`drawn`). A rebuilt gate
    /// (the same tier) or a fixed castle gets none.
    func testTheKeepGetsASecondSilentDustWhenTheGateRaisesItsTier() throws {
        let gate = Realm.lines[0].wall
        let (before, after, events) = finishing(gate, from: .ironGate, to: .greatGate)
        XCTAssertNotEqual(CastleStage.grown(before), CastleStage.grown(after))
        var effects = BattleEffects()
        XCTAssertTrue(step(&effects, events, before: before.plots, state: after).isEmpty)
        let dusts = effects.items.filter { $0.kind == .standDust }
        XCTAssertEqual(dusts.count, 2, "the gate's and the keep's")
        let keep = try XCTUnwrap(dusts.first { $0.plane == .mistBand })
        XCTAssertEqual(keep.x, SceneLayout.castleKeepX + SceneLayout.castleKeepMiddle)
        XCTAssertEqual(keep.y, BattleEffects.keepDustY)
        XCTAssertEqual(keep.start, dusts[0].start, "at the same moment")
        XCTAssertEqual(CastleStage.grown(effects.drawn(after)), CastleStage.grown(before), "the keep as it stood")
        let due = run(&effects, to: 0.5, state: after)
        XCTAssertEqual(due, [Realm.plots[gate].x], "one answer, at the gate's place")
        XCTAssertEqual(CastleStage.grown(effects.drawn(after)), CastleStage.grown(after), "swapped with the gate")
        var fixed = BattleEffects()
        step(&fixed, events, before: before.plots, state: after, castleGrows: false)
        XCTAssertEqual(fixed.items.filter { $0.kind == .standDust }.count, 1, "a fixed castle: the gate's dust only")
        var fallen = after
        fallen.plots[gate].isRubble = true
        let rebuilt = finishing(gate, from: .greatGate, to: .greatGate, rebuild: true, base: fallen)
        var again = BattleEffects()
        step(&again, rebuilt.events, before: rebuilt.before.plots, state: rebuilt.after)
        XCTAssertEqual(again.items.filter { $0.kind == .standDust }.count, 1, "a rebuild is no growth")
    }

    /// Two works finishing in the same frame each get their own standing and their own dust; they are answered once
    /// (the gate of A2, P3 and L2: two `.buildStood` in one frame doubled the success haptic and its echo, and the
    /// hub's sound throttle kept whichever came first), at the one nearest the listener.
    func testTwoWorksAtOnceEachStand() {
        let wall = Realm.lines[1].wall
        let house = Realm.townPlots[2]
        let first = finishing(wall, from: .palisade, to: .stoneWall)
        let both = finishing(house, from: .house, to: .bigHouse, base: first.before)
        var after = both.after
        var events = both.events
        Build.complete(&after, plot: wall, balance: balance, events: &events)
        XCTAssertEqual(events.count, 2)
        var effects = BattleEffects()
        step(&effects, events, before: both.before.plots, state: after, listenerX: Realm.plots[house].x - 40)
        XCTAssertEqual(effects.standings.map(\.plot).sorted(), [wall, house].sorted())
        XCTAssertEqual(effects.items.filter { $0.kind == .standDust }.count, 2)
        XCTAssertEqual(props(after, effects: effects), props(both.before), "both drawn as they stood")
        var nearWall = effects
        let due = run(&effects, to: 0.5, state: after, listenerX: Realm.plots[house].x - 40)
        XCTAssertEqual(due, [Realm.plots[house].x], "one answer, at the nearer one")
        XCTAssertTrue(effects.standings.allSatisfy(\.sounded) || effects.standings.isEmpty, "neither answered later")
        XCTAssertEqual(run(&nearWall, to: 0.5, state: after, listenerX: Realm.plots[wall].x), [Realm.plots[wall].x])
        XCTAssertTrue(run(&effects, to: 1.2, state: after).isEmpty, "never a second answer")
    }

    /// A second work standing within 0.4 s of the last answer is not answered again (the thinner's old gap for
    /// `.buildDone`); one standing 0.4 s or more after it is.
    func testASecondStandingSoonAfterIsNotAnsweredAgain() {
        let wall = Realm.lines[1].wall
        let house = Realm.townPlots[2]
        let first = finishing(wall, from: .palisade, to: .stoneWall)
        let both = finishing(house, from: .house, to: .bigHouse, base: first.before)
        var after = both.after
        var wallEvents: [SimEvent] = []
        Build.complete(&after, plot: wall, balance: balance, events: &wallEvents)
        for (delay, answered) in [(0.2, false), (0.45, true)] {
            var effects = BattleEffects()
            var due = step(&effects, wallEvents, before: both.before.plots, state: after)
            due += run(&effects, to: delay, state: after)
            XCTAssertEqual(due, [Realm.plots[wall].x], "the first at its swap")
            due = step(&effects, both.events, before: both.before.plots, state: after)
            due += run(&effects, to: delay + 0.5, state: after)
            XCTAssertEqual(due, answered ? [Realm.plots[house].x] : [], "the second \(delay) s later")
        }
    }

    // MARK: - Part 3: damage does not swap silently

    /// A wall turning to its damaged frame, and one falling to rubble, is drawn 1 px lower for 0.05 s in the frame of
    /// the change, then at its place; a repair that brings the whole frame back gets nothing; none under Reduce Motion.
    func testADamagedOrFallenWallJoltsOnePixel() throws {
        let plot = Realm.lines[1].wall
        var s = GameFrameSupport.demoNight()
        let full = Build.maxHP(.stoneWall, balance: balance)
        var effects = BattleEffects()
        step(&effects, state: s)
        XCTAssertTrue(effects.jolts.isEmpty, "the first look only remembers")
        s.plots[plot].hp = full * 0.3
        step(&effects, state: s)
        XCTAssertEqual(effects.shifts(reduceMotion: false)[plot], -1, "damaged: 1 px down")
        XCTAssertNil(effects.shifts(reduceMotion: true)[plot], "no jolt under Reduce Motion")
        let wall = try XCTUnwrap(props(s, effects: effects).first { $0.sprite == .stoneWall && $0.x == Realm.wallX[1] })
        XCTAssertEqual(wall.frame, 1)
        XCTAssertEqual(wall.y, -1)
        step(&effects, state: s, seconds: 0.034)
        XCTAssertEqual(effects.shifts(reduceMotion: false)[plot], -1, "0.05 s")
        step(&effects, state: s, seconds: 0.034)
        XCTAssertNil(effects.shifts(reduceMotion: false)[plot], "then at its place")
        s.plots[plot].hp = 0
        s.plots[plot].isRubble = true
        step(&effects, state: s)
        let rubble = try XCTUnwrap(props(s, effects: effects).first { $0.sprite == .rubbleStone })
        XCTAssertEqual(rubble.y, -1, "rubble: 1 px down")
        step(&effects, state: s, seconds: 0.06)
        s.plots[plot].isRubble = false
        s.plots[plot].hp = full
        step(&effects, state: s)
        XCTAssertNil(effects.shifts(reduceMotion: false)[plot], "a whole frame back: nothing new")
        // The gate too.
        let gate = Realm.lines[0].wall
        s.plots[gate].hp = Build.maxHP(.ironGate, balance: balance) * 0.4
        step(&effects, state: s)
        XCTAssertEqual(effects.shifts(reduceMotion: false)[gate], -1)
    }

    // MARK: - Part 5: Reduce Motion

    /// Under Reduce Motion the new sprite stands at the event's frame, the scaffold goes over it by opacity in 0.15 s
    /// (eased as what leaves), there is no dust, no settle and no jolt; `.buildStood` plays at the event.
    func testReduceMotionStandsAtOnceAndFadesTheScaffold() {
        let plot = Realm.lines[1].wall
        let (before, after, events) = finishing(plot, from: .palisade, to: .stoneWall)
        var effects = BattleEffects()
        let due = step(&effects, events, before: before.plots, state: after, reduceMotion: true)
        XCTAssertEqual(due, [Realm.plots[plot].x], "the answer at the event")
        XCTAssertTrue(effects.items.isEmpty, "no dust")
        var options = FrameOptions(flickerTime: 1.5)
        options.reduceMotion = true
        let finished = props(after, options: options)
        let shown = props(after, effects: effects, options: options)
        XCTAssertEqual(Array(shown.prefix(finished.count)).map(\.sprite), finished.map(\.sprite))
        XCTAssertTrue(zip(shown, finished).allSatisfy { $0.0.y == $0.1.y }, "no settle")
        let extra = shown.dropFirst(finished.count)
        XCTAssertEqual(extra.map(\.sprite), [.scaffold, .scaffold], "the old scaffold over the new wall")
        XCTAssertTrue(extra.allSatisfy { $0.alpha == 1 }, "whole at the event")
        run(&effects, to: 0.075, state: after, reduceMotion: true)
        let half = props(after, effects: effects, options: options).dropFirst(finished.count)
        XCTAssertEqual(half.count, 2)
        XCTAssertTrue(half.allSatisfy { $0.alpha > 0 && $0.alpha < 1 }, "fading")
        XCTAssertEqual(Double(half.first?.alpha ?? 0), 1 - Motion.leave(0.5), accuracy: 1e-5)
        run(&effects, to: 0.16, state: after, reduceMotion: true)
        XCTAssertEqual(props(after, effects: effects, options: options), finished, "gone after 0.15 s")
        XCTAssertTrue(effects.shifts(reduceMotion: true).isEmpty)
        XCTAssertTrue(run(&effects, to: 1, state: after, reduceMotion: true).isEmpty, "once")
    }

    // MARK: - A loaded save, the cap

    /// A save loaded after the event shows the finished building with no standing: new effects (`restartView`) and
    /// a new driver's frame draw the finished realm, no dust, no answer.
    func testALoadedSaveShowsTheFinishedBuilding() {
        let plot = Realm.lines[1].wall
        let (_, after, _) = finishing(plot, from: .palisade, to: .stoneWall)
        var effects = BattleEffects()
        XCTAssertTrue(step(&effects, state: after).isEmpty)
        XCTAssertTrue(effects.standings.isEmpty)
        XCTAssertTrue(effects.items.isEmpty)
        XCTAssertEqual(effects.drawn(after), after)
        XCTAssertEqual(props(after, effects: effects), props(after))
        let driver = SimDriver(state: after)
        XCTAssertTrue(driver.framePlots.isEmpty, "nothing of the standing is saved or carried")
    }

    /// Part 4: the effects list holds 32 (was 24); the oldest give way.
    func testTheEffectsHoldThirtyTwo() {
        XCTAssertEqual(BattleEffects.maxEffects, 32)
        var effects = BattleEffects()
        let s = GameFrameSupport.demoNight()
        for k in 0..<40 {
            effects.note([.creatureKilled(kind: .shadehound, x: 500 + Double(k))], state: s, balance: balance, time: 1)
        }
        XCTAssertEqual(effects.items.count, 32)
        XCTAssertEqual(effects.items.first?.x, 508, "the oldest gave way")
    }

    // MARK: - Part 2: one answer, at the swap, through the game

    /// Through the game and a recording hub: a work finishing gives nothing from the thinner at the event, then
    /// `.buildStood` once at the swap at the plot's x; never the old `.buildDone`.
    func testTheGameAnswersOnceAtTheSwap() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("lanternhold-stand-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let values = ["GWReset": "YES", "GWSkipOnboarding": "YES", "GWStage": "world", "GWSeed": "2", "GWDay": "3",
                      "GWClock": "10", "GWCameraX": "1000", "GWWeather": "clear"]
        let game = GameModel(args: DebugArgs(values: values), kind: .world, store: SaveStore(directory: directory))
        let silent = SilentFeedback()
        game.feedback = silent
        _ = game.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
        let plot = Realm.lines[1].wall
        game.withDriver { driver in
            let total = Build.work(.palisade, rebuild: false, balance: driver.balance)
            driver.state.plots[plot].item = nil
            driver.state.plots[plot].job = BuildJob(target: .palisade, work: total - 0.001, total: total,
                                                    isRebuild: false, order: 99)
            for index in driver.state.builders.indices {
                driver.state.builders[index].plot = plot
                driver.state.builders[index].x = Realm.plots[plot].x + Double(index % 4) * 5 - 7
                driver.state.builders[index].task = .building
            }
        }
        var eventAt: Double?
        var frames = 0
        while frames < 240 {
            game.advance(by: frame)
            frames += 1
            if eventAt == nil, game.driver?.state.plots[plot].item == .palisade {
                eventAt = game.effects.standClock
                XCTAssertEqual(game.effects.standings.map(\.plot), [plot], "the standing's record")
                XCTAssertFalse(silent.placed.contains { $0.cue == .buildStood }, "nothing at the event")
            }
            if let at = eventAt, game.effects.standClock - at < BattleEffects.standSwap - 1e-9 {
                XCTAssertFalse(silent.placed.contains { $0.cue == .buildStood }, "nothing before the swap")
            }
        }
        XCTAssertNotNil(eventAt, "the palisade stood")
        let stood = silent.placed.filter { $0.cue == .buildStood }
        XCTAssertEqual(stood.count, 1, "once per building")
        XCTAssertEqual(stood.first?.x, Realm.plots[plot].x, "at the plot's x")
        XCTAssertFalse(silent.played.contains(.buildDone), "never the event's old answer")
    }
}
