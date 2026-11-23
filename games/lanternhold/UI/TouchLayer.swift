import Observation
import SwiftUI

/// Touch the world (stage lane, step stage-2, 15.11.2026; DESIGN.md "Controls 2: touch the world"): the whole screen
/// takes the finger, in place of the old walk pad and the action button. A touch that never moves 10 pt is a tap (on a
/// thing he walks to it and does what it offers, on the ground he walks there); past 10 pt it is a drag, anywhere: he
/// walks toward it and runs past 40 pt, and stops when the finger lifts. `GameModel+Touch.swift` decides; this view
/// only passes the finger on. It says nothing to VoiceOver: the things have their own elements (`TouchSpotsView`).
/// Build 3, lane 5: a lift while the scene is not active is never a tap (`touchEnded(active:)`).
@MainActor
struct TouchLayer: View {
    let model: GameModel
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        GeometryReader { geometry in
            Color.clear
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0, coordinateSpace: .local)
                        .onChanged { value in
                            // Build 3, lane 5 step 4: a touch anywhere on the world shuts the town banner's slip.
                            MoodSlip.shared.close()
                            model.touchChanged(start: value.startLocation, at: value.location,
                                               translation: value.translation, in: geometry.size)
                        }
                        .onEnded { value in
                            model.touchEnded(at: value.location, translation: value.translation, in: geometry.size,
                                             active: scenePhase == .active)
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
                        .accessibilityHint(spot.id == "touch-lord" ? Text("Double tap to pause") : Text(verbatim: ""))
                        .accessibilityIdentifier(spot.id)
                        .accessibilityAction {
                            if spot.id == "touch-lord" { model.activateLordElement() } else { model.touchSpot(spot.id) }
                        }
                }
            }
            .frame(width: width, height: height, alignment: .topLeading)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityElement(children: .contain)
    }
}

/// The lord's hint over his head ("Touch the lord to still the world", fix round 1), its pixel tail down to him, on night
/// glass in the quiet hand. Polish B3 (H4): the errand slip that used this view is gone (the errand's sign is the
/// thing's own mark); the hint comes and goes by the presence rule (`GameView`) and stands only while he stands.
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
        Text(verbatim: slip.text)
            .font(Theme.italic(.subheadline))
            .foregroundStyle(Theme.ink)
            .lineLimit(1)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(GlassPanelBackground())
            .overlay(alignment: .bottom) {
                GlassTail()
                    .offset(y: 4 * NightGlass.pointsPerPixel)
            }
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("touch-lord-hint")
    }
}

/// Polish B3: whether the lord walks now, published only when it flips (the model's own `driver` is not observed), so
/// the two teaching slips are never drawn over a walking lord (`GameView`; law 2).
@MainActor
@Observable
final class WalkSigns {
    static let shared = WalkSigns()
    var lordWalks = false
    /// Polish B3b part 5: the deed the talk bubble carries now (`GameModel.collectorDeed`), nil for none; the bubble's
    /// view reads it so that it is drawn again when the deed comes or goes.
    var bubbleDeed: String? = nil

    /// Polish B3: a teaching slip (the first minute's, the lord's hint) is drawn only while it is due, no card is open,
    /// the lantern is down and the lord stands.
    nonisolated static func slipDrawn(due: Bool, card: Bool, lantern: Bool, walking: Bool) -> Bool {
        due && !card && !lantern && !walking
    }
}

/// The first minute's one slip, once: "Touch what the lord shall do." (the first mark is the lesson), high in the
/// middle of the screen under the realm strip, clear of the lord and the lane (the first sweep: low, it covered his
/// feet).
@MainActor
struct FirstTouchSlipView: View {
    /// The slip's words (Story.xcstrings `touch.first`, the lord's form filled in).
    let text: String

    var body: some View {
        VStack {
            Text(verbatim: text)
                .font(Theme.italic(.subheadline))
                .foregroundStyle(Theme.ink)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(SlipBackground())
                .accessibilityIdentifier("touch-first-slip")
                .padding(.top, 62)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
        .allowsHitTesting(false)
    }
}
