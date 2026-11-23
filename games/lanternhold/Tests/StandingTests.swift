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

    /// The dust starts at the event at the work's foot (the chimney's puffs tinted to ground dust: the broken wall's
    /// soot shards did not read on the day's ground), is fullest at the swap (every piece in, at its own peak alpha of
    /// 0.6 to 0.9, standing 0 to 8 px over the foot; step A2b, was every piece at alpha 1 and 1 to 9 px up), then thins
    /// and is gone by 1.1 s. Its own kind (`standDust`); the broken wall's dust stays as it was.
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
        XCTAssertTrue(peak.allSatisfy { $0.tint.w >= 0.6 - 1e-6 && $0.tint.w <= 0.9 + 1e-6 },
                      "each piece at its own peak at the swap: \(peak.map(\.tint.w))")
        XCTAssertTrue(lifts(peak).allSatisfy { $0 >= 0 && $0 <= 8 * scale }, "at the foot and over it: \(lifts(peak))")
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

    /// A work's dust from its event to its end: the puffs of every frame (`step` seconds a frame), with the clock.
    private func dustFrames(_ finish: (before: GameState, after: GameState, events: [SimEvent]), step seconds: Double,
                            until end: Double = 1.15) -> (dust: VisualEffect?, frames: [(at: Double, puffs: [ActorInstance])]) {
        var effects = BattleEffects()
        step(&effects, finish.events, before: finish.before.plots, state: finish.after, seconds: 0, castleGrows: false)
        guard let dust = effects.items.first(where: { $0.kind == .standDust && $0.plane == .world }) else { return (nil, []) }
        var frames: [(at: Double, puffs: [ActorInstance])] = []
        while true {
            let at = effects.standClock - dust.start
            frames.append((at, GameFrameSupport.frame(finish.after, focus: dust.x, effects: effects).layer.actors
                .filter { $0.sprite == .smokePuff }))
            guard at < end - 1e-9 else { break }
            step(&effects, state: finish.after, seconds: min(seconds, end - at), castleGrows: false)
        }
        return (dust, frames)
    }

    /// The device columns of the work's foot a frame's puffs cover, and the work's columns.
    private func coverage(_ puffs: [ActorInstance], dust: VisualEffect) -> (covered: Int, columns: Int) {
        let camera = Camera(focusX: dust.x, pixelScale: pro)
        let scale = Float(pro.scale)
        let cell = Float(SpriteID.smokePuff.size.width)
        let left = camera.deviceX(worldX: dust.x - dust.width / 2, scale: pro.scale, mode: .smooth)
        let right = camera.deviceX(worldX: dust.x + dust.width / 2, scale: pro.scale, mode: .smooth)
        var covered = Set<Int>()
        for puff in puffs {
            let side = Float(CastleSmoke.side(frame: puff.frame))
            let x0 = Int(puff.rect.x + ((cell - side) / 2).rounded(.down) * scale)
            for column in x0..<(x0 + Int(side * scale)) where column >= left && column < right { covered.insert(column) }
        }
        return (covered.count, right - left)
    }

    /// The puffs' cover (area x alpha).
    private func cover(_ puffs: [ActorInstance]) -> Float {
        puffs.reduce(0) { sum, puff in
            let side = Float(CastleSmoke.side(frame: puff.frame))
            return sum + side * side * puff.tint.w
        }
    }

    /// Step A2b (rewritten from the gate of A2's test, which pinned every puff at the largest frame and 90 % of the
    /// foot; the brief changes the rule): in the swap's frame the puffs cover at least 70 % of the work's foot (the
    /// line's stone wall, a new palisade, the gate, a house's next tier, the big house of 72 px), and their cover
    /// (area x alpha) peaks in that frame: never more in any frame of the dust at 60 frames a second.
    func testTheDustCoversTheFootAtTheSwap() throws {
        let wall = Realm.lines[1].wall
        let works = [
            ("stone wall", finishing(wall, from: .palisade, to: .stoneWall)),
            ("new palisade", finishing(wall, from: nil, to: .palisade)),
            ("gate", finishing(Realm.lines[0].wall, from: .gate, to: .ironGate)),
            ("big house", finishing(Realm.townPlots[2], from: .house, to: .bigHouse)),
        ]
        for (name, finish) in works {
            let (found, frames) = dustFrames(finish, step: frame)
            let dust = try XCTUnwrap(found, name)
            let swap = try XCTUnwrap(frames.first { $0.at >= BattleEffects.standSwap - 1e-9 }, name)
            let (covered, columns) = coverage(swap.puffs, dust: dust)
            XCTAssertGreaterThanOrEqual(Double(covered), 0.7 * Double(columns),
                                        "\(name) (\(dust.width) px): \(covered) of \(columns) columns")
            let peak = cover(swap.puffs)
            for other in frames where abs(other.at - swap.at) > 1e-9 {
                XCTAssertLessThanOrEqual(cover(other.puffs), peak + 1e-4, "\(name): more cover at \(other.at) s")
            }
            let rising = try XCTUnwrap(frames.first { $0.at >= 0.06 - 1e-9 }, name)
            let later = try XCTUnwrap(frames.first { $0.at >= 0.3 - 1e-9 }, name)
            XCTAssertGreaterThan(peak, cover(rising.puffs), "\(name): growing to the swap")
            XCTAssertGreaterThan(peak, cover(later.puffs), "\(name): thinning after it")
        }
    }

    /// Step A2b: the dust is clumps, not a row. In the swap's frame of the stone wall's and the big house's dust the
    /// puffs (in x order) are not evenly spaced, stand at more than two heights, and no two neighbours stand at one
    /// height; they show both sizes (4 and 5 px); they hold exactly two tones, the darker 15 % below the lighter, none
    /// brighter than the dust's light tone (under the lit stone and plaster); the top edge stands 4 to 10 px over the
    /// foot. The layout keeps the brief's numbers for every width a work can have: at most 12 pieces, 3 to 5 clumps
    /// (the keep up to 6), peak alpha 0.6 to 0.9, an end 0.7 to 1.1 s after the event, a drift of at most 3 px.
    func testTheDustGathersInClumpsNotARow() throws {
        let scale = pro.scale
        let ground = Camera.groundDeviceY(physicalHeight: pro.physicalHeight, scale: scale)
        let works = [
            ("stone wall", finishing(Realm.lines[1].wall, from: .palisade, to: .stoneWall)),
            ("big house", finishing(Realm.townPlots[2], from: .house, to: .bigHouse)),
        ]
        for (name, finish) in works {
            let (_, frames) = dustFrames(finish, step: frame, until: BattleEffects.standSwap + 0.01)
            let puffs = try XCTUnwrap(frames.last, name).puffs.sorted { $0.rect.x < $1.rect.x }
            XCTAssertGreaterThanOrEqual(puffs.count, 6, name)
            let lefts = puffs.map { Int($0.rect.x) / scale }
            let spacings = zip(lefts, lefts.dropFirst()).map { $1 - $0 }
            XCTAssertGreaterThan(Set(spacings).count, 1, "\(name): not an even row: \(spacings)")
            let bottoms = puffs.map { (ground - Int($0.rect.y + $0.rect.w)) / scale }
            XCTAssertGreaterThan(Set(bottoms).count, 2, "\(name): more than two heights: \(bottoms)")
            for k in bottoms.indices.dropFirst() {
                XCTAssertNotEqual(bottoms[k], bottoms[k - 1], "\(name): neighbours \(k - 1), \(k) at one height")
            }
            let sides = puffs.map { CastleSmoke.side(frame: $0.frame) }
            XCTAssertEqual(Set(sides), [4, 5], "\(name): both sizes")
            let tops = zip(bottoms, sides).map { $0 + $1 }
            XCTAssertTrue(tops.allSatisfy { $0 >= 4 && $0 <= 10 }, "\(name): the top edge \(tops)")
            XCTAssertGreaterThan(Set(tops).count, 2, "\(name): a ragged top \(tops)")
            let tones = Set(puffs.map { [$0.tint.x, $0.tint.y, $0.tint.z] })
            XCTAssertEqual(tones.count, 2, "\(name): two tones")
            let light = BattleEffects.standDustLight
            for tone in tones {
                XCTAssertTrue(tone[0] <= light.x + 1e-6 && tone[1] <= light.y + 1e-6 && tone[2] <= light.z + 1e-6,
                              "\(name): no tone above the light one: \(tone)")
            }
            let values = tones.map { $0[0] }.sorted()
            XCTAssertEqual(values[0] / values[1], BattleEffects.standDustDark, accuracy: 1e-4, "\(name): 15 % apart")
        }
        for width in stride(from: 8.0, through: 130, by: 1) {
            let pieces = BattleEffects.standDust(width: width, key: BattleEffects.standKey(x: 1000, width: width))
            XCTAssertLessThanOrEqual(pieces.count, BattleEffects.standPieces, "\(width) px")
            XCTAssertEqual(pieces.count, BattleEffects.standDustCount(width: width), "\(width) px")
            let puffs = pieces.filter { $0.size > 0 }
            XCTAssertTrue(puffs.allSatisfy { $0.size == 4 || $0.size == 5 }, "\(width) px")
            XCTAssertTrue(pieces.allSatisfy { $0.alpha >= 0.6 && $0.alpha <= 0.9 }, "\(width) px")
            XCTAssertTrue(pieces.allSatisfy { $0.life >= 0.7 - 1e-9 && $0.life <= BattleEffects.standDustSeconds + 1e-9 })
            XCTAssertTrue(pieces.allSatisfy { ($0.driftX * $0.driftX + $0.driftY * $0.driftY).squareRoot() <= 3 })
            XCTAssertTrue(pieces.allSatisfy { $0.bottom >= 0 && $0.bottom + Double(max($0.size, 3)) <= 10 })
            XCTAssertTrue(pieces.allSatisfy { $0.left == $0.left.rounded() && $0.bottom == $0.bottom.rounded() },
                          "whole game px")
            XCTAssertGreaterThan(Set(pieces.map(\.life)).count, 1, "each its own end")
        }
    }

    /// Step A2b: the same pieces everywhere. Two builds of the same standing give the same puffs in every frame; a
    /// standing after other effects (the effects' counter moved on) gives the same dust as a fresh one, since it is
    /// placed by the plot; at 30 frames a second the dust at a shared moment is the one at 60.
    func testTheDustIsTheSameOnEveryBuild() throws {
        let finish = finishing(Realm.lines[1].wall, from: .palisade, to: .stoneWall)
        func key(_ list: [ActorInstance]) -> [String] {
            list.map { "\($0.frame) \($0.rect) \($0.tint)" }
        }
        let first = dustFrames(finish, step: frame)
        let second = dustFrames(finish, step: frame)
        XCTAssertEqual(first.frames.count, second.frames.count)
        for (a, b) in zip(first.frames, second.frames) { XCTAssertEqual(key(a.puffs), key(b.puffs), "at \(a.at) s") }
        var moved = BattleEffects()
        moved.note([.creatureKilled(kind: .shadehound, x: 500), .creatureKilled(kind: .shadehound, x: 520)],
                   state: finish.after, balance: balance, time: 0)
        step(&moved, finish.events, before: finish.before.plots, state: finish.after, seconds: 0)
        let dust = try XCTUnwrap(moved.items.first { $0.kind == .standDust })
        run(&moved, to: 0.3, state: finish.after)
        let swap = try XCTUnwrap(first.frames.first { abs($0.at - 0.3) < 1e-6 })
        let movedPuffs = GameFrameSupport.frame(finish.after, focus: dust.x, effects: moved).layer.actors
            .filter { $0.sprite == .smokePuff }
        XCTAssertEqual(key(movedPuffs), key(swap.puffs), "placed by the plot, not by the effects before it")
        let slow = dustFrames(finish, step: 1.0 / 30)
        for moment in [0.0, 0.2, 0.3, 0.6] {
            let a = try XCTUnwrap(first.frames.first { abs($0.at - moment) < 1e-6 }, "\(moment)")
            let b = try XCTUnwrap(slow.frames.first { abs($0.at - moment) < 1e-6 }, "\(moment)")
            XCTAssertEqual(a.puffs.map { "\($0.frame) \($0.rect)" }, b.puffs.map { "\($0.frame) \($0.rect)" },
                           "the same at 30 and 60 frames a second at \(moment) s")
            for (p, q) in zip(a.puffs, b.puffs) { XCTAssertEqual(p.tint.w, q.tint.w, accuracy: 1e-5) }
        }
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
