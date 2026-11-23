import SwiftUI

/// A court member's line in a speech bubble over his head (DESIGN.md "Talking"; M3 step 3; `talk-bubble`): a pane of
/// night glass with his name in lantern gold and the line, its tail pointing down at him, following him on screen. A tap closes it
/// (walking away closes it too, `GameModel.stepCourt`). Polish B3: it comes and goes by the presence rule (`GameView`:
/// quick in rising 2 game px, quick out in place), and at Saul's post it carries the second touch's deed; while that
/// deed waits a tap on it does the deed, as the second touch on him (polish B3b part 5).
@MainActor
struct TalkBubbleView: View {
    let bubble: TalkBubble
    let model: GameModel

    var body: some View {
        GeometryReader { geometry in
            let width = min(300, geometry.size.width - 40)
            let x = CGFloat(bubble.anchorX) * geometry.size.width
            let head = CGFloat(bubble.headY) * geometry.size.height
            let left = min(max(20, x - width / 2), geometry.size.width - width - 20)
            let tail = min(max(16, x - left), width - 16)
            // Polish B3 gate (P1, M1): over Saul while the second touch waits, the deed that touch does. Polish B3b part 5
            // (B3's L3): read fresh from the model, and drawn again whenever the published deed changes.
            let _ = WalkSigns.shared.bubbleDeed
            let deed = model.collectorDeed(bubble)
            VStack(spacing: 0) {
                Button {
                    model.tapTalkBubble(bubble)
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        if let name = bubble.nameText ?? bubble.nameKey.map({ model.story($0) }) {
                            Text(verbatim: name)
                                .font(Theme.caps(.caption))
                                .tracking(0.8)
                                .foregroundStyle(Theme.rubric)
                        }
                        let line = bubble.text ?? model.story(bubble.textKey)
                        if !line.isEmpty {
                            Text(inked: line, .subheadline)
                                .font(Theme.serif(.subheadline))
                                .foregroundStyle(Theme.ink)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        // Polish B3 (H4): the deed the errand slip used to name over Saul's post (what the second touch
                        // on him does), under his line; nil for every other bubble. B3 gate (P1): in the lord's quiet
                        // hand (the italic of his hint), not in caps, so it reads neither as Saul's voice nor as a button.
                        if let deed {
                            Text(inked: deed, .subheadline)
                                .font(Theme.italic(.subheadline))
                                .foregroundStyle(Theme.ink)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.top, 2)
                        }
                    }
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .frame(width: width, alignment: .leading)
                    .frame(minHeight: 44)
                    .background(GlassPanelBackground())
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                // Polish B3b part 5: while the deed waits a tap on the bubble does it (`GameModel.tapTalkBubble`), and
                // VoiceOver offers the deed's own words as the bubble's action.
                .accessibilityHint(deed == nil ? Text("Tap to close") : Text(verbatim: ""))
                .accessibilityActions {
                    if let deed {
                        Button(deed) { model.tapTalkBubble(bubble) }
                    }
                }
                .accessibilityIdentifier("talk-bubble")
                GlassTail()
                    .offset(x: tail - width / 2)
                    .accessibilityHidden(true)
            }
            .frame(width: width)
            .offset(x: left)
            .frame(width: geometry.size.width, height: max(0, head - 4), alignment: .bottomLeading)
        }
        .ignoresSafeArea()
    }
}

/// The bubble's tail: a small triangle pointing down, open at the top where it meets the bubble.
struct TailShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        return path
    }
}
