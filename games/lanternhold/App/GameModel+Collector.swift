import Foundation

/// The collector's hire by touch on the screen (the join; `CollectorTouch` holds the rules): Saul Tolliver's words in
/// the talk bubble over his head at his post, and the second touch's answer.
extension GameModel {
    /// The bubble's speaker key for Saul (no court member: `stepCourt` keeps the bubble while the lord stays near).
    nonisolated static let collectorSpeaker = "collector"

    /// Saul says one of his lines (`CollectorWords`, Town.xcstrings) in the bubble over his head at his post.
    func collectorSays(_ words: CollectorWords) {
        collectorBubble(text: TownText.string(words.key), key: words.key)
    }

    /// Polish B3 (H4): the lord stands before him and the second touch waits: his offer while he was never taken on;
    /// once he was, a bubble with no line of his own, only the deed the slip used to name ("Send Saul Tolliver home",
    /// "Take on Saul Tolliver"; `collectorDeed`).
    func collectorAwaits(_ offer: CollectorTouch.Offer) {
        if offer == .hire {
            collectorSays(.offer)
        } else {
            collectorBubble(text: "", key: CollectorWords.hire.key)
        }
    }

    /// The bubble over Saul at his post.
    private func collectorBubble(text: String, key: String) {
        guard overlay == nil, stage == .world, driver != nil else { return }
        let x = Town.collectorPost
        let height = Double(SpriteID.collector.size.height)
        closeTalk()
        court.talking = GameModel.collectorSpeaker
        court.talkX = x
        var anchorX = 0.5
        var headY = figureTop
        if let pixelScale = lastPixelScale, let view = camera {
            let ground = Double(Camera.groundDeviceY(physicalHeight: pixelScale.physicalHeight,
                                                     scale: pixelScale.scale))
            anchorX = Double(view.deviceX(worldX: x, scale: pixelScale.scale, mode: options.actorMode))
                / Double(max(1, pixelScale.physicalWidth))
            headY = (ground - height * Double(pixelScale.scale)) / Double(max(1, pixelScale.physicalHeight))
        }
        headY = collectorBubbleHeadY(headY)
        var bubble = TalkBubble(who: GameModel.collectorSpeaker, nameKey: nil, textKey: key, anchorX: anchorX,
                                headY: headY)
        bubble.nameText = TownText.collectorName()
        bubble.text = text
        talkBubble = bubble
        feedback.play(.cardOpened)
    }

    /// Polish B3 (H4): the deed a bubble carries under its line: over Saul while the lord stands at his post and the
    /// second touch waits, what that touch does (`CollectorTouch.label` with `waiting`: "Take him on", "Send Saul
    /// Tolliver home", "Take on Saul Tolliver"), the words the errand slip said there. Nil for every other bubble.
    func collectorDeed(_ bubble: TalkBubble) -> String? {
        guard bubble.who == GameModel.collectorSpeaker, let errand = touch.errand, errand.id == CollectorTouch.id,
              errand.waiting, let state = driver?.state else { return nil }
        return CollectorTouch.label(state, waiting: true)
    }

    /// Polish B3 gate (M1, P1): a tap on a talk bubble closes it, except over Saul while the second touch waits.
    /// Polish B3b part 5 (the director's call after B3): then the bubble says the deed in words, so it is also a place to
    /// do it: the tap is the second touch on him (`touchThing` on his thing: the same function, the same sound, the same
    /// result; the deed's own answer replaces the bubble, which then closes as any bubble does). A tap on a bubble that
    /// no longer shows (a second tap that reaches the one the deed replaced) does nothing. What a touch on Saul does is
    /// unchanged.
    func tapTalkBubble(_ bubble: TalkBubble) {
        guard let shown = talkBubble, shown.who == bubble.who, shown.textKey == bubble.textKey,
              shown.text == bubble.text else { return }
        if collectorDeed(shown) != nil {
            guard let saul = touch.things.first(where: { $0.id == CollectorTouch.id }) else { return }
            touchThing(saul)
            return
        }
        closeTalk()
    }

    /// While his errand runs, the bubble stands above his mark: its lower edge 2 game px over the mark's top (the
    /// director's note of 14:22 gave that rule over the slip; polish B3 keeps it over the mark that replaced the slip,
    /// at the mark's place whether it is drawn or not). `fallback` is the head's height otherwise.
    func collectorBubbleHeadY(_ fallback: Double) -> Double {
        guard touch.errand?.id == CollectorTouch.id, let framing = touch.framing, framing.stage == stage,
              let thing = touch.things.first(where: { $0.id == CollectorTouch.id }), let pixelScale = lastPixelScale,
              touch.viewWidth > 0 else { return fallback }
        let width = Double(max(1, pixelScale.physicalWidth))
        let height = Double(max(1, pixelScale.physicalHeight))
        let points = touch.viewWidth * min(width, height) / max(width, height)
        let markTop = framing.deviceY(lift: thing.markLift + TouchRules.markHeight) / height
        let gap = 2 * Double(pixelScale.scale) / height
        // TalkBubbleView ends 4 pt over its head line.
        return min(fallback, markTop - gap + 4 / points)
    }

    /// The second touch at his post: taken on, sent home or taken on again (from the next morning, now and in the
    /// day's dawn snapshot), and his answer.
    func collectorAnswers() {
        guard let words = withDriver({ $0.answerCollector() }) ?? nil else {
            feedback.play(.refused)
            return
        }
        collectorSays(words)
        refreshHUD()
    }
}
