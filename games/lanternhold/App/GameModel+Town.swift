import CoreGraphics
import Foundation

/// The lord's walk to a door the player touched (town-2): `knock` when the house has paid today and may still be
/// knocked at, `collect` when its household still waits (he only walks past and takes the toss), `refused` when nobody
/// will open (paid and knocked at as often as allowed, or the doors shut): he knocks once and nothing happens.
struct TownWalk: Sendable, Equatable {
    enum Purpose: Sendable, Equatable {
        case knock, collect, refused
    }

    var plot: Int
    var spot: Double
    var purpose: Purpose
}

/// The lord's half step back from a door he knocked at (fix round 2): where he knocked, the door, the knock's sim time.
struct TownStepBack: Sendable, Equatable {
    var doorX: Double
    var knockX: Double
    var at: Double
}

/// The screen's own state of the taxes on foot (`GameModel.townRun`): the walk to a door, a knock nobody answers, the
/// half step back after a knock, the sim time the cues were last read at.
struct TownRun: Sendable, Equatable {
    var walk: TownWalk?
    var refused: TownShow.Refused?
    var stepBack: TownStepBack?
    var cuesAt: Double?
    var marksAt = -1
}

/// A door on screen for VoiceOver and the UI tests (`TownTapLayer`): where it is (fractions of the screen), whether a
/// touch knocks, and its words.
struct TownDoorMark: Sendable, Equatable, Identifiable {
    var plot: Int
    var x: Double
    var y: Double
    var width: Double
    var height: Double
    var knockable: Bool
    var label: String

    var id: Int { plot }
}

/// The taxes on foot on the screen (docs/TOWN.md section 1, town-2): the knock's touch on a door, the lord's walk up,
/// the knocks' and shutters' sounds, the coins' landings held back from the purse until they land, and the doors as
/// accessibility elements. The pictures are `TownFrames`; the rules are `Town`.
extension GameModel {
    /// The town's frame work after the simulation stepped (`advanceGame`): the walk to a door arrives, the knock
    /// happens, the cues of the moment play, the door marks follow the camera.
    func stepTown() {
        guard kind == .world, let game = driver else { return }
        let state = game.state
        let now = state.simTime
        if let walk = townRun.walk, game.travelTarget == nil {
            townRun.walk = nil
            if abs(state.king.x - walk.spot) < 1.5 {
                arrive(walk, state: state, balance: game.balance)
            }
        }
        if let refused = townRun.refused, now - refused.at > 1.5 { townRun.refused = nil }
        stepBackFromDoor(game.travelTarget == nil ? state : nil)
        let from = townRun.cuesAt ?? now
        if now > from {
            for cue in TownShow.cues(driver?.state ?? state, balance: game.balance, from: from, to: now,
                                     refused: townRun.refused) {
                switch cue {
                case .knock: feedback.play(.knock)
                case .shutter: feedback.play(.shutter)
                case .counted: feedback.play(.taxesCounted)
                }
            }
        }
        townRun.cuesAt = now
        townRun.marksAt += 1
        if townRun.marksAt % 6 == 0 { refreshTownMarks() }
    }

    /// The lord reached the door he was sent to.
    private func arrive(_ walk: TownWalk, state: GameState, balance: Balance) {
        switch walk.purpose {
        case .knock:
            if Town.canKnock(state, plot: walk.plot, balance: balance) {
                withDriver { sim in
                    sim.state.king.velocity = 0
                    _ = Town.knock(&sim.state, plot: walk.plot, balance: balance)
                }
                if let spot = TownShow.spots(state).first(where: { $0.plot == walk.plot }) {
                    townRun.stepBack = TownStepBack(doorX: spot.doorX, knockX: state.king.x, at: state.simTime)
                }
                refreshHUD()
            } else {
                townRun.refused = TownShow.Refused(plot: walk.plot, at: state.simTime)
            }
        case .refused:
            townRun.refused = TownShow.Refused(plot: walk.plot, at: state.simTime)
        case .collect:
            break
        }
    }

    /// A touch on the world at `point` of a screen `size`: a door there sends the lord to it (to knock, to take the
    /// toss, or to knock where nobody opens). Returns whether a door took the touch.
    @discardableResult
    func touchTown(at point: CGPoint, in size: CGSize) -> Bool {
        guard kind == .world, overlay == nil, let game = driver, game.bot == nil, let view = camera,
              let pixelScale = lastPixelScale, size.width > 0, size.height > 0 else { return false }
        let fx = Double(point.x / size.width)
        let fy = Double(point.y / size.height)
        let height = Double(pixelScale.physicalHeight)
        let ground = Double(Camera.groundDeviceY(physicalHeight: pixelScale.physicalHeight, scale: pixelScale.scale))
        let worldX = view.x + fx * view.viewWidth
        let worldY = (ground - fy * height) / Double(max(1, pixelScale.scale))
        guard let plot = TownShow.door(atX: worldX, y: worldY, state: game.state) else { return false }
        return knock(plot: plot)
    }

    /// While the door he knocked at opens, the lord takes half a step back (`TownShow.knockBackX`), facing it still,
    /// so the household bows in a free doorway. Ends at once when he is sent elsewhere (`state` nil, or he moves).
    private func stepBackFromDoor(_ state: GameState?) {
        guard let step = townRun.stepBack else { return }
        guard let state, state.king.velocity == 0 else {
            townRun.stepBack = nil
            return
        }
        let t = state.simTime - step.at
        guard t >= TownShow.stepBackFrom else { return }
        let x = TownShow.knockBackX(doorX: step.doorX, knockX: step.knockX, t: t)
        if abs(state.king.x - x) > 1e-6 {
            withDriver { sim in
                sim.state.king.x = x
            }
        }
        if t >= TownShow.stepBackUntil { townRun.stepBack = nil }
    }

    /// Sends the lord to the door of `plot` (the touch, or VoiceOver's action on the door): by day only.
    @discardableResult
    func knock(plot: Int) -> Bool {
        guard kind == .world, overlay == nil, let game = driver, game.bot == nil else { return false }
        let state = game.state
        guard DayClock.phase(at: state.hour) == .day,
              let spot = TownShow.spots(state).first(where: { $0.plot == plot }) else { return false }
        let purpose: TownWalk.Purpose
        if Town.canKnock(state, plot: plot, balance: game.balance) {
            purpose = .knock
        } else if Town.waiting(state, balance: game.balance).contains(plot) {
            purpose = .collect
        } else {
            purpose = .refused
        }
        let target = purpose == .collect ? TownShow.collectSpot(doorX: spot.doorX, kingX: state.king.x)
            : TownShow.knockSpot(doorX: spot.doorX, kingX: state.king.x)
        townRun.walk = TownWalk(plot: plot, spot: target, purpose: purpose)
        townRun.refused = nil
        townRun.stepBack = nil
        withDriver { sim in
            sim.travelTarget = target
        }
        refreshHUD()
        return true
    }

    /// The purse the player sees: the gold of the coins still in the air is held back until they land.
    func townShownGold(_ state: GameState, balance: Balance) -> Int {
        state.gold - TownShow.goldInFlight(state, balance: balance)
    }

    /// The doors on screen as accessibility elements, and the town's state for the UI tests (`town-status`).
    func refreshTownMarks() {
        guard let game = driver, let view = camera, let pixelScale = lastPixelScale else { return }
        let state = game.state
        let width = Double(pixelScale.physicalWidth)
        let height = Double(pixelScale.physicalHeight)
        let scale = Double(pixelScale.scale)
        let ground = Double(Camera.groundDeviceY(physicalHeight: pixelScale.physicalHeight, scale: pixelScale.scale))
        var marks: [TownDoorMark] = []
        let isDay = DayClock.phase(at: state.hour) == .day
        if isDay && overlay == nil {
            for spot in TownShow.spots(state) {
                let fx = (spot.doorX - view.x) / max(1, view.viewWidth)
                guard fx > 0.02, fx < 0.98 else { continue }
                let knockable = Town.canKnock(state, plot: spot.plot, balance: game.balance)
                let door = TownText.doorKey(plot: spot.plot).map { TownText.string($0) } ?? ""
                let label = TownText.fill(TownText.string(knockable ? "town.access.knock" : "town.access.door"),
                                          [door])
                marks.append(TownDoorMark(plot: spot.plot, x: fx,
                                          y: (ground - TownShow.doorTouch.height / 2 * scale) / height,
                                          width: TownShow.doorTouch.halfWidth * 2 * scale / width,
                                          height: TownShow.doorTouch.height * scale / height,
                                          knockable: knockable, label: label))
            }
        }
        if marks != townMarks { townMarks = marks }
        let status = TownRun.status(state, balance: game.balance)
        if status != townStatus { townStatus = status }
    }
}

extension TownRun {
    /// "owing:21,23 paid:24 knocked:23 shut:23 hand:21 held:4": the places that still owe, those paid today, those
    /// knocked at, the houses whose shutters are closed, the places handing the collector their coins right now, the
    /// gold still in the air.
    static func status(_ s: GameState, balance: Balance) -> String {
        guard let day = s.town?.today else { return "town:none" }
        let owing = day.places.filter(\.owes).map { String($0.plot) }
        let paid = day.places.filter(\.collected).map { String($0.plot) }
        let knocked = day.places.filter { $0.knocks > 0 }.map { String($0.plot) }
        let shut = TownShow.scene(s, balance: balance, reduceMotion: true).houses.filter(\.shutters)
            .map { String($0.plot) }
        let hand = day.places.filter { place in
            guard let at = place.tossedAt, let paid = place.collectorGold, paid > 0, s.simTime >= at else { return false }
            let last = TownShow.handTimes(count: Town.coins(for: paid, rules: balance.town)).last ?? 0
            return s.simTime - at < last + TownShow.handDeep
        }.map { String($0.plot) }
        return "day:\(day.day) owing:\(owing.joined(separator: ",")) paid:\(paid.joined(separator: ",")) "
            + "knocked:\(knocked.joined(separator: ",")) shut:\(shut.joined(separator: ",")) "
            + "hand:\(hand.joined(separator: ",")) held:\(TownShow.goldInFlight(s, balance: balance))"
    }
}
