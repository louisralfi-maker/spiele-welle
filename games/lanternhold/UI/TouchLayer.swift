import SwiftUI

/// Touch the world (stage lane, step stage-2, 15.11.2026; DESIGN.md "Controls 2: touch the world"): the whole screen
/// takes the finger, in place of the old walk pad and the action button. A touch that never moves 10 pt is a tap (on a
/// thing he walks to it and does what it offers, on the ground he walks there); past 10 pt it is a drag, anywhere: he
/// walks toward it and runs past 40 pt, and stops when the finger lifts. `GameModel+Touch.swift` decides; this view
/// only passes the finger on. It says nothing to VoiceOver: the things have their own elements (`TouchSpotsView`).
@MainActor
struct TouchLayer: View {
    let model: GameModel

    var body: some View {
        GeometryReader { geometry in
            Color.clear
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0, coordinateSpace: .local)
                        .onChanged { value in
                            model.touchChanged(start: value.startLocation, at: value.location,
                                               translation: value.translation, in: geometry.size)
                        }
                        .onEnded { value in
                            model.touchEnded(at: value.location, translation: value.translation, in: geometry.size)
                        }
                )
                .onAppear { model.setTouchViewSize(geometry.size) }
                .onChange(of: geometry.size) { _, size in model.setTouchViewSize(size) }
        }
        .accessibilityHidden(true)
    }
}

/// The things in view as accessibility elements (M13): each a button at its touch area on screen, labelled with the act
/// first ("Talk to Tamsin", "Repair the wall"), its price as the value, identified `touch-<kind>-<id>` for the UI
/// tests; placed again four times a second, gone under a card. Activating one is the tap. They take no finger (the
/// touch layer under them does), so the UI tests tap their coordinates.
@MainActor
struct TouchSpotsView: View {
    let model: GameModel

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            ZStack(alignment: .topLeading) {
                ForEach(model.touchSpots) { spot in
                    Rectangle()
                        .fill(Color.white.opacity(0.001))
                        .frame(width: max(1, spot.rect.width * width), height: max(1, spot.rect.height * height))
                        .position(x: spot.rect.midX * width, y: spot.rect.midY * height)
                        .accessibilityElement()
                        .accessibilityLabel(Text(verbatim: spot.label))
                        .accessibilityValue(Text(verbatim: spot.value ?? ""))
                        .accessibilityAddTraits(.isButton)
                        .accessibilityIdentifier(spot.id)
                        .accessibilityAction { model.touchSpot(spot.id) }
                }
            }
            .frame(width: width, height: height, alignment: .topLeading)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityElement(children: .contain)
    }
}

/// The slip above the thing the lord walks to: what he is about to do and what it costs ("Repair the wall" and the
/// coin with 10), on the interface's slip, its pointer down to the thing's mark. Over a damaged wall it stays once he
/// stands there, until a second touch pays; the price turns red while the treasury cannot pay it.
@MainActor
struct ErrandSlipView: View {
    let slip: ErrandSlip

    var body: some View {
        GeometryReader { geometry in
            let insets = geometry.safeAreaInsets
            let fullWidth = geometry.size.width + insets.leading + insets.trailing
            let fullHeight = geometry.size.height + insets.top + insets.bottom
            let x = slip.x * fullWidth - insets.leading
            let foot = slip.y * fullHeight - insets.top
            content
                .fixedSize()
                .position(x: min(max(x, 90), geometry.size.width - 90), y: max(22, foot - 18))
        }
        .allowsHitTesting(false)
    }

    private var content: some View {
        HStack(spacing: 6) {
            Text(inked: slip.text, .footnote)
                .font(Theme.caps(.footnote))
                .foregroundStyle(Theme.ink)
            if let price = slip.price {
                GoldAmount(amount: price, size: 12, color: slip.shortOfGold ? Theme.rubric : Theme.ink)
            }
        }
        .lineLimit(1)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(SlipBackground())
        .overlay(alignment: .bottom) {
            PointerShape()
                .fill(Theme.rule)
                .frame(width: 10, height: 5)
                .offset(y: 5)
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("touch-slip")
    }
}

/// The first minute's one slip, once: "Touch what the lord shall do." (the first mark is the lesson), low in the middle
/// of the screen over the lane.
@MainActor
struct FirstTouchSlipView: View {
    /// The slip's words (Story.xcstrings `touch.first`, the lord's form filled in).
    let text: String

    var body: some View {
        VStack {
            Spacer(minLength: 0)
            Text(verbatim: text)
                .font(Theme.italic(.subheadline))
                .foregroundStyle(Theme.ink)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(SlipBackground())
                .accessibilityIdentifier("touch-first-slip")
                .padding(.bottom, 26)
        }
        .frame(maxWidth: .infinity)
        .allowsHitTesting(false)
    }
}
