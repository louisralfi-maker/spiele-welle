import Foundation

/// The collector's hire by touch on the screen (the join; `CollectorTouch` holds the rules): Saul Tolliver's words in
/// the talk bubble over his head at his post, and the second touch's answer.
extension GameModel {
    /// The bubble's speaker key for Saul (no court member: `stepCourt` keeps the bubble while the lord stays near).
    nonisolated static let collectorSpeaker = "collector"

    /// Saul says one of his lines (`CollectorWords`, Town.xcstrings) in the bubble over his head at his post.
    func collectorSays(_ words: CollectorWords) {
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
        var bubble = TalkBubble(who: GameModel.collectorSpeaker, nameKey: nil, textKey: words.key, anchorX: anchorX,
                                headY: headY)
        bubble.nameText = TownText.collectorName()
        bubble.text = TownText.string(words.key)
        talkBubble = bubble
        feedback.play(.cardOpened)
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
