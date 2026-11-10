import SwiftUI

/// The HUD (DESIGN.md "Controls", "Screens"). The game's (M2b part 2): pause top left (44 pt in a 60 pt area), the realm
/// strip at the top centre, the day and clock top right with gold, the happiness face and the people under them, the
/// horn banner at 19:00, and the action button bottom right with a caption naming what it does. While the reference bot
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

/// The game's HUD.
@MainActor
struct GameHUD: View {
    let model: GameModel
    /// Room kept on each side of the realm strip for the pause button and the clock column.
    static let sideRoom: CGFloat = 196

    /// A card or a screen is open (M2b review: the HUD's clock, numbers and strip peeked out beside and under every
    /// card as cut fragments; the cards that spend gold show the treasury themselves). The audience is neither (M3):
    /// its card stands below the HUD, whose numbers roll in their place after a choice, and the strip rests for
    /// Odile's counsel.
    private var covered: Bool { model.overlay != nil && model.overlay != .audience }
    /// A whole screen is open (the dawn report, the defeat card, the pause sheet): the pause button goes too. During
    /// the audience it stays, since the pause sheet ends the audience (M3).
    private var screen: Bool { model.overlay?.isScreen ?? false }

    var body: some View {
        GeometryReader { geometry in
            let stripWidth = max(160, min(380, geometry.size.width - 2 * GameHUD.sideRoom))
            ZStack(alignment: .top) {
                if model.isShowcase {
                    HStack {
                        Spacer(minLength: 0)
                        ClockBadge(day: model.day, time: model.clockText)
                            .hiddenUnder(covered)
                    }
                } else {
                    topBar
                    VStack(spacing: 8) {
                        // M3: the strip rests during the audience (Odile's counsel shows there).
                        if let strip = model.strip, model.overlay != .audience {
                            RealmStripView(strip: strip, reduceMotion: model.reduceMotion) { fraction in
                                model.travel(toFraction: fraction)
                            }
                            .frame(width: stripWidth, height: RealmStripView.height)
                        }
                        if let night = model.hornNight {
                            HornBanner(night: night)
                                .transition(model.reduceMotion ? AnyTransition.identity : AnyTransition.opacity)
                        }
                    }
                    .animation(model.reduceMotion ? nil : .easeInOut(duration: 0.35), value: model.hornNight)
                    .hiddenUnder(covered)
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
                if let target = model.target, model.overlay == nil, !model.isShowcase {
                    VStack {
                        Spacer(minLength: 0)
                        HStack {
                            Spacer(minLength: 0)
                            ActionArea(target: target, model: model)
                        }
                    }
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)
        }
        .padding(.horizontal, 8)
        .padding(.top, 6)
        .padding(.bottom, 2)
    }

    private var topBar: some View {
        HStack(alignment: .top, spacing: 8) {
            PauseButton { model.openPause() }
                .hiddenUnder(screen)
            Spacer(minLength: 0)
            VStack(alignment: .trailing, spacing: 6) {
                ClockBadge(day: model.day, time: model.clockText)
                RealmNumbers(gold: model.gold, happiness: model.happiness, people: model.people,
                             reduceMotion: model.reduceMotion)
            }
            .hiddenUnder(covered)
        }
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

/// "Day 3  22:48" on a dark capsule (`hud-clock`).
struct ClockBadge: View {
    let day: Int
    let time: String

    var body: some View {
        HStack(spacing: 8) {
            Text("Day \(day)")
            Text(verbatim: time)
                .monospacedDigit()
        }
        .font(.system(size: 15, weight: .semibold, design: .rounded))
        .foregroundStyle(Color(red: 0.95, green: 0.89, blue: 0.77))
        .lineLimit(1)
        .fixedSize()
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Capsule().fill(Color(red: 0.05, green: 0.04, blue: 0.09).opacity(0.62)))
        .overlay(Capsule().strokeBorder(Color(red: 0.91, green: 0.72, blue: 0.29).opacity(0.45), lineWidth: 1))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("hud-clock")
    }
}

/// Gold, happiness and people on one capsule under the clock (DESIGN.md "Economy": the three numbers of the HUD).
/// The numbers roll when they change and the face gives a little hop (not with Reduce Motion).
struct RealmNumbers: View {
    let gold: Int
    let happiness: Int
    let people: Int
    let reduceMotion: Bool

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
                Image(systemName: "person.2.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.parchment.opacity(0.85))
                number(people)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("People"))
            .accessibilityValue(Text(verbatim: "\(people)"))
            .accessibilityIdentifier("hud-people")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 5)
        .background(Capsule().fill(Theme.hudFill))
        .overlay(Capsule().strokeBorder(Theme.hudStroke, lineWidth: 1))
        .fixedSize()
    }

    private func number(_ value: Int) -> some View {
        Text(verbatim: "\(value)")
            .font(Theme.rounded(15, .bold))
            .monospacedDigit()
            .foregroundStyle(Theme.parchment)
            .contentTransition(reduceMotion ? .identity : .numericText(value: Double(value)))
            .animation(reduceMotion ? nil : .easeOut(duration: 0.35), value: value)
    }
}

/// Pause, top left: a 44 pt button in a 60 pt touch area (DESIGN.md "Controls").
struct PauseButton: View {
    let action: @MainActor () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle().fill(Theme.hudFill)
                Circle().strokeBorder(Theme.hudStroke, lineWidth: 1)
                Image(systemName: "pause.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Theme.parchment)
            }
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
    case build, recruit, throne, light, snuff, patch, lectern, talk

    init(_ action: BrazierAction) {
        switch action {
        case .light: self = .light
        case .snuff: self = .snuff
        case .patch: self = .patch
        }
    }

    init(_ target: KingTarget) {
        switch target {
        case .build: self = .build
        case .recruit: self = .recruit
        case .throne: self = .throne
        case .lectern: self = .lectern
        case .talk, .stranger: self = .talk
        case .light: self = .light
        case .patch: self = .patch
        }
    }

    /// The button's VoiceOver label in the light probe.
    var label: Text {
        switch self {
        case .build: return Text("Build")
        case .recruit: return Text("Recruit at the barracks")
        case .throne, .lectern: return Text("Set the taxes")
        case .talk: return Text("Talk")
        case .light: return Text("Light the brazier")
        case .snuff: return Text("Snuff the brazier")
        case .patch: return Text("Patch the wall")
        }
    }
}

/// The action button with its caption above it: "Build" and the plot, "Recruit", "Taxes", "Light", "Patch" and its
/// price; M3: "Audience (n)" at the throne while petitioners wait, a court member's name for talking.
@MainActor
struct ActionArea: View {
    let target: KingTarget
    let model: GameModel

    var body: some View {
        VStack(alignment: .trailing, spacing: 0) {
            caption
                .padding(.trailing, 20)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
            ActionButton(glyph: ActionGlyph(target), label: label, hold: model.targetHold) {
                model.performAction()
            }
        }
    }

    private var captionText: String {
        switch target {
        case .build(let plot):
            // The action and the plot (M2b review: the plot alone did not tell a build from an upgrade).
            let name = Texts.slotName(Realm.plots[plot].slot)
            switch model.targetVerb {
            case .upgrade?: return String(localized: "Upgrade: \(name)")
            case .rebuild?: return String(localized: "Rebuild: \(name)")
            default: return String(localized: "Build: \(name)")
            }
        case .recruit:
            return String(localized: "Recruit")
        case .throne:
            let waiting = model.strip?.petitioners ?? 0
            return waiting > 0 ? String(localized: "Audience (\(waiting))") : String(localized: "Taxes")
        case .lectern:
            return String(localized: "Taxes")
        case .talk(let who):
            return speakerName(who)
        case .stranger:
            return speakerName("seren")
        case .light:
            return String(localized: "Light")
        case .patch:
            return String(localized: "Patch")
        }
    }

    private var shortOfGold: Bool {
        if case .missingGold? = model.targetHold { return true }
        return false
    }

    private var caption: some View {
        HStack(spacing: 5) {
            Text(verbatim: captionText)
            if case .patch = target {
                // The price turns red while the treasury cannot pay it (M2b review).
                GoldAmount(amount: Balance.standard.patchCost, size: 12,
                           color: shortOfGold ? Color(red: 1.0, green: 0.5, blue: 0.38) : Theme.parchment)
            }
        }
        .font(Theme.serif(.footnote, .semibold))
        .foregroundStyle(Theme.parchment)
        .lineLimit(1)
        .fixedSize()
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(Capsule().fill(Theme.hudFill))
        .overlay(Capsule().strokeBorder(Theme.hudStroke, lineWidth: 1))
    }

    private var label: Text {
        switch (target, model.targetHold) {
        case (.build(let plot), _):
            return Text("Build: \(Texts.plotTitle(slot: Realm.plots[plot].slot, line: Realm.plots[plot].line))")
        case (.throne, _) where (model.strip?.petitioners ?? 0) > 0:
            return Text("Hold audience")
        case (.talk(let who), _):
            return Text("Talk to \(speakerName(who))")
        case (.stranger, _):
            return Text("Speak with \(speakerName("seren"))")
        case (_, .missingGold?):
            return Text("Patch the wall: not enough gold")
        case (_, .cooldown?):
            return Text("Patch the wall: ready again soon")
        case (_, .busy?):
            return Text("Lighting the brazier")
        default:
            return ActionGlyph(target).label
        }
    }

    /// A court member's or guest's name (the role for the unnamed guests).
    private func speakerName(_ who: String) -> String {
        let flags = model.driver?.state.flags ?? []
        return StoryText.name(speaker: who, look: nil, day: model.day, flags: flags)
            ?? StoryText.role(speaker: who) ?? who
    }
}

/// The context action button (DESIGN.md "Controls"): an 88 pt circle inside a 128 pt touch area. Greyed while what it
/// offers cannot be done now (`KingTargetHold`), with a ring that fills back through the Patch cooldown.
struct ActionButton: View {
    let glyph: ActionGlyph
    let label: Text
    var hold: KingTargetHold? = nil
    let perform: @MainActor () -> Void

    private static let gold = Color(red: 0.91, green: 0.72, blue: 0.29)

    var body: some View {
        Button(action: perform) {
            ZStack {
                Circle()
                    .fill(Color(red: 0.09, green: 0.07, blue: 0.14).opacity(0.8))
                Circle()
                    .strokeBorder(hold == nil ? ActionButton.gold : Color(white: 0.5), lineWidth: 3)
                if case .cooldown(let share)? = hold {
                    Circle()
                        .trim(from: 0, to: CGFloat(1 - share))
                        .stroke(ActionButton.gold, style: StrokeStyle(lineWidth: 3, lineCap: .round))
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
        .accessibilityIdentifier("action-button")
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
        case .lectern: return "book.fill"
        case .talk: return "bubble.left.fill"
        case .light: return "flame.fill"
        case .snuff: return "wind"
        case .patch: return "bandage.fill"
        }
    }

    private var iconColor: Color {
        switch glyph {
        case .build: return Color(red: 0.86, green: 0.8, blue: 0.7)
        case .recruit, .throne, .lectern: return Color(red: 1.0, green: 0.8, blue: 0.36)
        case .talk: return Color(red: 0.95, green: 0.89, blue: 0.77)
        case .light: return Color(red: 1.0, green: 0.78, blue: 0.35)
        case .snuff: return Color(red: 0.76, green: 0.8, blue: 0.92)
        case .patch: return Color(red: 0.92, green: 0.84, blue: 0.72)
        }
    }
}

/// The horn at 19:00 (DESIGN.md "Day and night": a low horn sounds, the Gloom stirs): a dark ribbon for a few seconds.
struct HornBanner: View {
    let night: Int

    var body: some View {
        VStack(spacing: 2) {
            Text("The horn sounds")
                .font(Theme.serif(.headline, .bold))
                .foregroundStyle(Theme.fireGold)
            Text("Night \(night) is coming")
                .font(Theme.serif(.subheadline))
                .foregroundStyle(Theme.parchment)
        }
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal, 36)
        .padding(.vertical, 8)
        .background(RibbonShape(notch: 14).fill(Theme.night1.opacity(0.88)))
        .overlay(RibbonShape(notch: 14).stroke(Theme.gold.opacity(0.6), lineWidth: 1.2))
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
