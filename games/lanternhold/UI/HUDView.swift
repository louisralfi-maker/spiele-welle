import SwiftUI

/// The HUD (DESIGN.md "Controls 2", "Screens"). The game's (M2b part 2): pause top left (44 pt in a 60 pt area), the realm
/// strip at the top centre, the day and clock top right with gold, the happiness face and the people under them, the
/// horn banner at 19:00. Touch the world (step stage-2, 15.11.2026) removed the action button and its caption: the
/// lord goes where the finger points (`TouchLayer`). In the map's style
/// (docs/UI-look.md): the clock and the three numbers are one slip of the steward's ledger, the strip a strip of map,
/// pause and the action button wax seals, the caption a slip of parchment. While the reference bot
/// plays for the screenshots (`-GWAutoplay play`) only the clock sits over the picture. The light probe and the light
/// lab keep milestone 1's HUD: the clock, the brazier button and the debug readouts. Plain views only (no materials
/// over the running scene); it respects the safe area while the scene renders under the sensor housing.
@MainActor
struct HUDView: View {
    let model: GameModel

    var body: some View {
        if model.kind == .world {
            GameHUD(model: model)
        } else {
            ProbeHUD(model: model)
        }
    }
}

/// Milestone 1's HUD for the light probe and the light lab.
@MainActor
struct ProbeHUD: View {
    let model: GameModel

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                if model.showsStats {
                    StatsPanel(text: model.statsText)
                }
                Spacer(minLength: 0)
                ClockBadge(day: model.day, time: model.clockText)
            }
            Spacer(minLength: 0)
            HStack(alignment: .bottom, spacing: 12) {
                if model.showsDebugValues {
                    DebugValues(kingX: model.debugKingX, cameraX: model.debugCameraX)
                }
                Spacer(minLength: 0)
                if let action = model.action {
                    ActionButton(glyph: ActionGlyph(action), label: ActionGlyph(action).label) {
                        model.performAction()
                    }
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.top, 8)
        .padding(.bottom, 2)
    }
}

/// The game's HUD after docs/HUD.md (stage lane, step stage-3-interface, 15.11.2026): nothing stands on the walked
/// world. The ledger slip, the pause seal and the standing realm strip are gone; a tap on the lord is the lantern moment
/// (`LanternMomentView`: the figures above him, the strip, the gear). What stays here comes by itself and goes: the
/// realm strip while something calls (petitioners, the Stranger, a breach at night; `StripCall`), and the horn's ribbon
/// at 19:00. The gold and the notes above the walking lord are drawn in the world (`GameModel+Lantern.swift`).
@MainActor
struct GameHUD: View {
    let model: GameModel

    var body: some View {
        ZStack(alignment: .top) {
            if !model.isShowcase {
                VStack(spacing: 8) {
                    if model.stripCalling, model.lanternMoment == nil, model.overlay == nil, let strip = model.strip {
                        RealmStripView(strip: strip, reduceMotion: model.reduceMotion) { fraction in
                            model.travel(toFraction: fraction)
                        }
                        .transition(model.reduceMotion ? AnyTransition.identity : AnyTransition.opacity)
                    }
                    if let night = model.hornNight, model.lanternMoment == nil {
                        HornBanner(night: night)
                            .transition(model.reduceMotion ? AnyTransition.identity : AnyTransition.opacity)
                    }
                }
                .padding(.top, 4)
                .animation(model.reduceMotion ? nil : .easeInOut(duration: 0.35), value: model.hornNight)
                .animation(model.reduceMotion ? nil : .easeInOut(duration: 0.3), value: model.stripCalling)
                .hiddenUnder(model.overlay != nil && model.overlay != .audience)
            }
            if model.showsDebugValues || model.showsStats {
                VStack {
                    Spacer(minLength: 0)
                    HStack(alignment: .bottom) {
                        if model.showsStats { StatsPanel(text: model.statsText) }
                        if model.showsDebugValues {
                            DebugValues(kingX: model.debugKingX, cameraX: model.debugCameraX)
                        }
                        Spacer(minLength: 0)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.horizontal, 8)
        .padding(.top, 2)
        .padding(.bottom, 2)
    }
}

extension View {
    /// Gone from sight, touch and VoiceOver while `hidden` (the HUD under a card or a screen), keeping its place.
    func hiddenUnder(_ hidden: Bool) -> some View {
        opacity(hidden ? 0 : 1)
            .allowsHitTesting(!hidden)
            .accessibilityHidden(hidden)
    }
}

/// "Day 3  22:48" (`hud-clock`): the day as a rubric in small capitals, the hour in the ledger's figures. On its own
/// slip of parchment, or bare as the first line of the HUD's ledger.
struct ClockBadge: View {
    let day: Int
    let time: String
    var framed = true

    var body: some View {
        HStack(spacing: 8) {
            Text(inked: String(localized: "Day \(day)"), size: 15)
                .font(Theme.hand(15, .caps))
                .tracking(0.6)
                .foregroundStyle(Theme.rubric)
            Text(verbatim: time)
                .font(Theme.figures(16))
                .monospacedDigit()
                .foregroundStyle(Theme.ink)
        }
        .lineLimit(1)
        .fixedSize()
        .padding(.horizontal, framed ? 12 : 0)
        .padding(.vertical, framed ? 5 : 0)
        .background {
            if framed { SlipBackground() }
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("hud-clock")
    }
}

/// Gold, happiness and people under the clock (DESIGN.md "Economy": the three numbers of the HUD), each with its icon
/// drawn in ink. The numbers roll when they change and the face gives a little hop (not with Reduce Motion).
struct RealmNumbers: View {
    let gold: Int
    let happiness: Int
    let people: Int
    let reduceMotion: Bool
    var framed = true

    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 5) {
                CoinIcon(size: 16)
                number(gold)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("Gold"))
            .accessibilityValue(Text(verbatim: "\(gold)"))
            .accessibilityIdentifier("hud-gold")
            HStack(spacing: 5) {
                HappinessFace(happiness: happiness, size: 18)
                    .keyframeAnimator(initialValue: 1.0, trigger: happiness) { face, scale in
                        face.scaleEffect(reduceMotion ? 1 : scale)
                    } keyframes: { _ in
                        KeyframeTrack {
                            CubicKeyframe(1.3, duration: 0.14)
                            CubicKeyframe(0.94, duration: 0.12)
                            CubicKeyframe(1.0, duration: 0.14)
                        }
                    }
                number(happiness)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("Happiness"))
            .accessibilityValue(Text(verbatim: "\(happiness)"))
            .accessibilityIdentifier("hud-happiness")
            HStack(spacing: 5) {
                PeopleIcon(size: 17)
                number(people)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("People"))
            .accessibilityValue(Text(verbatim: "\(people)"))
            .accessibilityIdentifier("hud-people")
        }
        .padding(.horizontal, framed ? 12 : 0)
        .padding(.vertical, framed ? 5 : 0)
        .background {
            if framed { SlipBackground() }
        }
        .fixedSize()
    }

    private func number(_ value: Int) -> some View {
        Text(verbatim: "\(value)")
            .font(Theme.figures(17))
            .monospacedDigit()
            .foregroundStyle(Theme.ink)
            .contentTransition(reduceMotion ? .identity : .numericText(value: Double(value)))
            .animation(reduceMotion ? nil : .easeOut(duration: 0.35), value: value)
    }
}

/// Pause, top left: a 44 pt wax seal in a 60 pt touch area (DESIGN.md "Controls").
struct PauseButton: View {
    let action: @MainActor () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                WaxSeal()
                Image(systemName: "pause.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Theme.sealWords)
            }
            .shadow(color: .black.opacity(0.4), radius: 2, x: 0, y: 1)
            .frame(width: 44, height: 44)
            .frame(width: 60, height: 60, alignment: .topLeading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("Pause"))
        .accessibilityIdentifier("hud-pause")
    }
}

/// What the action button shows (DESIGN.md "Controls": a hammer, coins, the lord's circlet, a flame, a patch; M3:
/// the tax lectern's book and a speech bubble).
enum ActionGlyph: Sendable, Equatable {
    case build, recruit, throne, light, snuff, patch, talk
    /// The hall stage (stage lane, 14.11.2026): the hall's door, in from the bailey or out from the hall.
    case door

    init(_ action: BrazierAction) {
        switch action {
        case .light: self = .light
        case .snuff: self = .snuff
        case .patch: self = .patch
        }
    }

    /// The button's VoiceOver label in the light probe.
    var label: Text {
        switch self {
        case .build: return Text("Build")
        case .recruit: return Text("Recruit at the barracks")
        case .throne: return Text("Sit on the throne")
        case .talk: return Text("Talk")
        case .light: return Text("Light the brazier")
        case .snuff: return Text("Snuff the brazier")
        case .patch: return Text("Patch the wall")
        case .door: return Text("Enter the great hall")
        }
    }
}

/// The context action button (DESIGN.md "Controls"): an 88 pt wax seal inside a 128 pt touch area, the lord's seal on
/// what is done. Its wax is grey while what it offers cannot be done now (`KingTargetHold`), with a ring that fills
/// back through the Patch cooldown.
struct ActionButton: View {
    let glyph: ActionGlyph
    let label: Text
    var hold: KingTargetHold? = nil
    let perform: @MainActor () -> Void

    var body: some View {
        Button(action: perform) {
            ZStack {
                WaxSeal(spent: hold != nil)
                    .shadow(color: .black.opacity(0.45), radius: 3, x: 0, y: 2)
                Circle()
                    .strokeBorder(hold == nil ? Theme.goldHi.opacity(0.9) : Theme.boneDim.opacity(0.6), lineWidth: 2)
                if case .cooldown(let share)? = hold {
                    Circle()
                        .trim(from: 0, to: CGFloat(1 - share))
                        .stroke(Theme.goldHi, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .padding(1.5)
                }
                icon
                    .opacity(hold == nil ? 1 : 0.45)
                    .saturation(hold == nil ? 1 : 0.2)
            }
            .frame(width: 88, height: 88)
            .frame(width: 128, height: 128)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("probe-action")
        .accessibilityLabel(label)
    }

    @ViewBuilder private var icon: some View {
        switch glyph {
        case .recruit:
            CoinStack(size: 40)
        case .throne:
            // The painted circlet in its own gold, 2 pt to the art pixel (48x32 pt).
            CircletIcon(scale: 2)
        default:
            Image(systemName: iconName)
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(iconColor)
        }
    }

    private var iconName: String {
        switch glyph {
        case .build: return "hammer.fill"
        case .recruit: return "circle.fill"
        case .throne: return "circle.fill"
        case .talk: return "bubble.left.fill"
        case .light: return "flame.fill"
        case .snuff: return "wind"
        case .patch: return "bandage.fill"
        case .door: return "door.left.hand.open"
        }
    }

    private var iconColor: Color {
        switch glyph {
        case .build: return Color(red: 0.86, green: 0.8, blue: 0.7)
        case .recruit, .throne: return Color(red: 1.0, green: 0.8, blue: 0.36)
        case .talk: return Color(red: 0.95, green: 0.89, blue: 0.77)
        case .light: return Color(red: 1.0, green: 0.78, blue: 0.35)
        case .snuff: return Color(red: 0.76, green: 0.8, blue: 0.92)
        case .patch: return Color(red: 0.92, green: 0.84, blue: 0.72)
        case .door: return Color(red: 0.95, green: 0.84, blue: 0.62)
        }
    }
}

/// The horn at 19:00 (DESIGN.md "Day and night": a low horn sounds, the Gloom stirs): a ribbon of night glass for a
/// few seconds, lettered in lantern gold (TITLE.md section 4).
struct HornBanner: View {
    let night: Int

    var body: some View {
        VStack(spacing: 2) {
            Text("The horn sounds")
                .font(Theme.caps(.headline))
                .tracking(1)
                .foregroundStyle(Theme.goldHi)
            // LANE-E: E1b (the far goal said twice, R10: "Night {n} of {N}" while the night lies inside the run;
            // past it, the Long Watch, the old wording)
            Text(inked: FarGoal.hornLine(night: night), .subheadline)
                .font(Theme.italic(.subheadline))
                .foregroundStyle(Theme.bone)
            // LANE-E end
        }
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal, 36)
        .padding(.vertical, 8)
        .background(GlassRibbonBackground(height: 30))
        .allowsHitTesting(false)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("horn-banner")
    }
}

/// The jitter test's readouts (`debug-king-x` in device pixels, `debug-camera-x` in game pixels).
struct DebugValues: View {
    let kingX: Int
    let cameraX: Double

    var body: some View {
        let king = "\(kingX)"
        let camera = String(format: "%.2f", cameraX)
        VStack(alignment: .leading, spacing: 2) {
            Text(verbatim: king)
                .accessibilityIdentifier("debug-king-x")
                .accessibilityValue(Text(verbatim: king))
            Text(verbatim: camera)
                .accessibilityIdentifier("debug-camera-x")
                .accessibilityValue(Text(verbatim: camera))
        }
        .font(.system(size: 9, weight: .regular, design: .monospaced))
        .foregroundStyle(Color.white.opacity(0.55))
        .allowsHitTesting(false)
    }
}

/// `-GWStats`: CPU and GPU ms, fps, thermal state, s, target size and counts.
struct StatsPanel: View {
    let text: String

    var body: some View {
        Text(verbatim: text)
            .font(.system(size: 10, weight: .regular, design: .monospaced))
            .foregroundStyle(Color.white)
            .padding(6)
            .background(Color.black.opacity(0.55))
            .allowsHitTesting(false)
            .accessibilityIdentifier("debug-stats")
    }
}
