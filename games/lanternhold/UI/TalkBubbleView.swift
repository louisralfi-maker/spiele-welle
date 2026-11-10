import SwiftUI

/// A court member's line in a speech bubble over his head (DESIGN.md "Talking"; M3 step 3; `talk-bubble`): a slip of
/// parchment with his name as a rubric and the line, its tail pointing down at him, following him on screen. A tap closes it
/// (walking away closes it too, `GameModel.stepCourt`).
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
                        if let key = bubble.nameKey {
                            Text(verbatim: model.story(key))
                                .font(Theme.caps(.caption))
                                .tracking(0.8)
                                .foregroundStyle(Theme.rubric)
                        }
                        Text(inked: model.story(bubble.textKey), .subheadline)
                            .font(Theme.serif(.subheadline))
                            .foregroundStyle(Theme.ink)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .frame(width: width, alignment: .leading)
                    .frame(minHeight: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .fill(Theme.parchment)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .strokeBorder(Theme.rule, lineWidth: 1.2)
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityHint(Text("Tap to close"))
                .accessibilityIdentifier("talk-bubble")
                TailShape()
                    .fill(Theme.parchment)
                    .overlay(TailShape().stroke(Theme.rule, lineWidth: 1.2))
                    .frame(width: 14, height: 9)
                    .offset(x: tail - width / 2, y: -1.2)
                    .accessibilityHidden(true)
            }
            .shadow(color: .black.opacity(0.35), radius: 6, x: 0, y: 3)
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
