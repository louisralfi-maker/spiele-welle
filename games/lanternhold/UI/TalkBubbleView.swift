import SwiftUI

/// A court member's line in a speech bubble over his head (DESIGN.md "Talking"; M3 step 3; `talk-bubble`): a pane of
/// night glass with his name in lantern gold and the line, its tail pointing down at him, following him on screen. A tap closes it
/// (walking away closes it too, `GameModel.stepCourt`). Polish B3: it comes and goes by the presence rule (`GameView`:
/// quick in rising 2 game px, quick out in place), and at Saul's post it carries the second touch's deed.
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
            VStack(spacing: 0) {
                Button {
                    model.closeTalk()
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
                        // on him does), in the slip's caps, under his line; nil for every other bubble.
                        if let deed = model.collectorDeed(bubble) {
                            Text(inked: deed, .footnote)
                                .font(Theme.caps(.footnote))
                                .foregroundStyle(Theme.ink)
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
                .accessibilityHint(Text("Tap to close"))
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
