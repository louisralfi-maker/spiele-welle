import SwiftUI

/// The flight screen: the Canvas scene, the HUD and the pause card. A touch anywhere outside the buttons ignites on the
/// pad and drops the current stage in flight. Every timing input fires when the finger touches down, not when it lifts,
/// so how long the finger rests never shifts a rating.
struct FlightView: View {
    let driver: FlightDriver
    let model: GameModel

    var body: some View {
        ZStack {
            FlightSceneView(driver: driver)
                .ignoresSafeArea()
            PaperGrain(opacity: 0.035)
                .equatable()
                .ignoresSafeArea()
            FlightHUD(driver: driver)
            if driver.paused {
                PauseCard(onResume: { driver.resume() }, onAbort: { model.abortFlight() })
                    .transition(.opacity)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("flight-root")
    }
}

/// The part that redraws every frame. It is also the big "tap anywhere" control: VoiceOver reads it as a button
/// ("Launch" on the pad, then "Drop stage") with an action, since a tap on the screen is the only other way to do that.
struct FlightSceneView: View {
    let driver: FlightDriver
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(driver: FlightDriver) {
        self.driver = driver
    }

    var body: some View {
        let state = driver.sceneState(reduceMotion: reduceMotion)
        let onPad = state.phase == .pad
        Canvas { context, size in
            FlightScene.draw(&context, size: size, state: state)
        }
        .contentShape(Rectangle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: 10_000, perform: {}, onPressingChanged: { pressing in
            if pressing { driver.tapScene() }
        })
        .accessibilityElement()
        .accessibilityLabel(onPad ? Text("Launch") : Text("Drop stage"))
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { driver.tapScene() }
        .accessibilityIdentifier("flight-scene")
    }
}

/// How the rocket sits relative to a ring right now, for the release button.
enum BandCue: Sendable, Equatable {
    case outside
    case inside
    case perfect
}

struct FlightHUD: View {
    let driver: FlightDriver
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(driver: FlightDriver) {
        self.driver = driver
    }

    var body: some View {
        GeometryReader { geo in
            let sim = driver.sim
            let clock = driver.clock
            ZStack {
                VStack(spacing: 0) {
                    topBar(sim)
                    Spacer(minLength: 0)
                    if sim.phase == .pad && !driver.autoplay {
                        TapToLaunch(opacity: launchPulse(clock))
                            .padding(.bottom, geo.size.height * 0.12)
                    }
                    HStack {
                        Spacer()
                        releaseButton(sim, clock: clock)
                    }
                }
                HStack {
                    TankGauge(
                        fraction: sim.phase == .pad ? 1 : sim.fuelFraction,
                        cue: sim.gaugeCue,
                        zones: Ratings.gaugeZones(guidance: sim.rocket.guidance),
                        clock: clock,
                        refusedAge: clock - driver.refusedAt,
                        stageCount: sim.stageCount,
                        stageIndex: sim.stageIndex,
                        reduceMotion: reduceMotion
                    )
                    .frame(height: geo.size.height * 0.4 + 60)
                    .padding(.leading, 10)
                    Spacer()
                }
                .allowsHitTesting(false)
            }
        }
    }

    private func topBar(_ sim: FlightSim) -> some View {
        ZStack {
            HStack {
                PauseButton(driver: driver)
                Spacer()
                CoinPill(value: driver.flightCoins)
                    .padding(.trailing, 8)
            }
            AltitudeReadout(
                km: Int(sim.altitude.rounded()),
                tenths: Int((max(0, sim.speed) * 10).rounded()),
                fastForward: driver.fastForward
            )
            .allowsHitTesting(false)
        }
        .padding(.horizontal, 6)
        .padding(.top, 2)
    }

    private func releaseButton(_ sim: FlightSim, clock: Double) -> some View {
        let band = bandCue(sim)
        var scale: CGFloat = 1
        if band != .outside && !reduceMotion {
            scale = CGFloat(1.05 + 0.04 * sin(clock * 14))
        }
        return ReleaseButton(
            count: sim.satellitesAboard,
            enabled: sim.isFlying && sim.satellitesAboard > 0,
            band: band,
            scale: scale,
            driver: driver
        )
    }

    private func bandCue(_ sim: FlightSim) -> BandCue {
        guard let band = sim.liveBand else { return .outside }
        return band.rating == .perfect ? .perfect : .inside
    }

    private func launchPulse(_ clock: Double) -> Double {
        reduceMotion ? 1 : 0.6 + 0.4 * abs(sin(clock * 2.6))
    }
}

struct TapToLaunch: View {
    let opacity: Double

    var body: some View {
        Text("Tap to launch")
            .font(.rounded(28, .black))
            .foregroundStyle(Palette.ink)
            .padding(.horizontal, 22)
            .padding(.vertical, 12)
            .background(Capsule().fill(Palette.paper.opacity(0.85)))
            .opacity(opacity)
            .allowsHitTesting(false)
    }
}

/// Altitude and speed on a dark capsule, readable over clouds and over space. Only plain values, so SwiftUI skips it
/// while the numbers stay the same.
struct AltitudeReadout: View {
    let km: Int
    let tenths: Int
    let fastForward: Bool

    var body: some View {
        VStack(spacing: 0) {
            Text("\(km) km")
                .font(.rounded(34, .black).monospacedDigit())
                .foregroundStyle(Palette.paper)
                .shadow(color: Palette.ink.opacity(0.5), radius: 0, x: 0, y: 2)
                .accessibilityIdentifier("flight-altitude")
            HStack(spacing: 6) {
                Text(verbatim: "\((Double(tenths) / 10).formatted(.number.precision(.fractionLength(1)))) km/s")
                    .font(.rounded(14, .bold).monospacedDigit())
                    .foregroundStyle(Palette.paper)
                if fastForward {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundStyle(Palette.mustard)
                }
            }
            .accessibilityHidden(true)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
        .background(Capsule().fill(Palette.night.opacity(0.35)))
    }
}

struct CoinPill: View {
    let value: Int

    var body: some View {
        CoinAmount(value: value, size: 20, color: Palette.paper)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Capsule().fill(Palette.deepTeal.opacity(0.85)))
            .overlay(Capsule().stroke(Palette.paper.opacity(0.5), lineWidth: 1.5))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("\(value) coins"))
    }
}

/// The pause button: a 44 pt circle inside a 60 pt square that catches near misses, so they never drop a stage.
struct PauseButton: View {
    let driver: FlightDriver

    var body: some View {
        Button {
            Feedback.shared.play(.button)
            driver.pause()
        } label: {
            Image(systemName: "pause.fill")
                .font(.system(size: 18, weight: .heavy))
                .foregroundStyle(Palette.paper)
                .frame(width: 44, height: 44)
                .background(Circle().fill(Palette.deepTeal.opacity(0.85)))
                .overlay(Circle().stroke(Palette.paper.opacity(0.5), lineWidth: 1.5))
                .frame(width: 60, height: 60)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("Pause"))
        .accessibilityIdentifier("flight-pause")
    }
}

/// The tank of the burning stage. The fuel is a warm orange column that drains; the zones (Perfect at the bottom in
/// mustard, Great in teal, Good in paper) show along both edges and as a ruler on the right. In the Perfect window the
/// gauge glows and pulses; once the stage is burnt out it blinks mustard and coral through the grace time, then coral.
/// On the last stage the zones disappear (there is nothing to drop). Shakes when a drop is refused.
struct TankGauge: View {
    let fraction: Double
    let cue: GaugeCue
    let zones: (perfect: Double, great: Double, good: Double)
    let clock: Double
    let refusedAge: Double
    let stageCount: Int
    let stageIndex: Int
    let reduceMotion: Bool

    var body: some View {
        VStack(spacing: 10) {
            Canvas { context, size in
                TankGaugeDrawing.draw(context, size: size, fraction: fraction, cue: cue, zones: zones, clock: clock,
                                      reduceMotion: reduceMotion)
            }
            .frame(width: 52)
            StagePips(count: stageCount, index: stageIndex)
        }
        .offset(x: shakeOffset)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Fuel"))
        .accessibilityValue(Text(verbatim: "\(Int((min(1, max(0, fraction)) * 100).rounded())) %"))
    }

    private var shakeOffset: CGFloat {
        guard !reduceMotion, refusedAge >= 0, refusedAge < 0.35 else { return 0 }
        let decay = 1 - refusedAge / 0.35
        return CGFloat(sin(refusedAge * 70) * 7 * decay)
    }
}

/// One pip per stage, the burning one ringed in mustard.
struct StagePips: View {
    let count: Int
    let index: Int

    var body: some View {
        VStack(spacing: 5) {
            ForEach(0..<max(0, count), id: \.self) { row in
                let stage = count - 1 - row
                Circle()
                    .fill(stage >= index ? Palette.paper : Palette.paper.opacity(0.15))
                    .overlay(Circle().stroke(stage == index ? Palette.mustard : Palette.ink.opacity(0.4), lineWidth: 2))
                    .frame(width: 11, height: 11)
            }
        }
        .padding(.trailing, 10)
    }
}

/// The gauge drawing, a plain enum so it carries no actor isolation.
enum TankGaugeDrawing {
    static func draw(_ context: GraphicsContext, size: CGSize, fraction: Double, cue: GaugeCue,
                     zones: (perfect: Double, great: Double, good: Double), clock: Double, reduceMotion: Bool) {
        let track = CGRect(x: 6, y: 6, width: 30, height: max(10, size.height - 12))
        let shape = Path(roundedRect: track, cornerRadius: track.width / 2)
        let dropNow = cue == .perfect || cue == .grace
        if dropNow {
            let pulse = reduceMotion ? 1.0 : 0.55 + 0.45 * abs(sin(clock * 9))
            context.stroke(shape, with: .color(Palette.mustard.opacity(0.5 * pulse)), lineWidth: 12)
        }
        context.fill(shape, with: .color(Palette.night.opacity(0.6)))
        var inner = context
        inner.clip(to: shape)
        if cue != .last {
            drawZones(inner, track: track, zones: zones)
        }
        drawFuel(inner, track: track, fraction: fraction, cue: cue)
        drawEmpty(inner, track: track, cue: cue, clock: clock, reduceMotion: reduceMotion)
        let outline: Color
        switch cue {
        case .perfect, .grace: outline = Palette.mustard
        case .late: outline = Palette.coral
        case .calm, .last: outline = Palette.paper.opacity(0.9)
        }
        context.stroke(shape, with: .color(outline), lineWidth: dropNow ? 3.5 : 2.5)
        if cue != .last {
            drawRuler(context, track: track, zones: zones)
        }
    }

    /// The zones as full-width bands; the fuel column is narrower, so they stay visible along its edges.
    static func drawZones(_ ctx: GraphicsContext, track: CGRect, zones: (perfect: Double, great: Double, good: Double)) {
        let bands: [(Double, Color)] = [
            (zones.good, Palette.paper.opacity(0.3)),
            (zones.great, Palette.skyTeal.opacity(0.75)),
            (zones.perfect, Palette.mustard),
        ]
        for (top, color) in bands {
            let h = track.height * CGFloat(top)
            ctx.fill(Path(CGRect(x: track.minX, y: track.maxY - h, width: track.width, height: h)), with: .color(color))
        }
    }

    static func drawFuel(_ ctx: GraphicsContext, track: CGRect, fraction: Double, cue: GaugeCue) {
        let level = track.height * CGFloat(min(1, max(0, fraction)))
        guard level > 0.5 else { return }
        let column = CGRect(x: track.minX + 6, y: track.maxY - level, width: track.width - 12, height: level)
        let color = cue == .perfect ? Palette.mustard : Palette.fuel
        let shine = cue == .perfect ? Palette.paper : Palette.mustard
        ctx.fill(Path(roundedRect: column, cornerRadius: 5), with: .linearGradient(
            Gradient(colors: [shine, color]),
            startPoint: CGPoint(x: 0, y: column.minY), endPoint: CGPoint(x: 0, y: column.minY + 14)))
        var edge = Path()
        edge.move(to: CGPoint(x: track.minX, y: column.minY))
        edge.addLine(to: CGPoint(x: track.maxX, y: column.minY))
        ctx.stroke(edge, with: .color(Palette.paper), lineWidth: 2.5)
    }

    /// Burnt out but still attached: blinks mustard and coral while a drop is still Perfect, then coral (steady with
    /// Reduce Motion).
    static func drawEmpty(_ ctx: GraphicsContext, track: CGRect, cue: GaugeCue, clock: Double, reduceMotion: Bool) {
        guard cue == .grace || cue == .late else { return }
        let on = sin(clock * 14) > 0
        let color: Color
        if cue == .grace {
            color = (reduceMotion || on) ? Palette.mustard : Palette.coral
        } else {
            color = Palette.coral
        }
        let alpha = reduceMotion ? 0.6 : (on ? 0.75 : 0.3)
        ctx.fill(Path(track), with: .color(color.opacity(alpha)))
    }

    /// A ruler right of the tank: one coloured bar per zone and a tick at each zone's top.
    static func drawRuler(_ ctx: GraphicsContext, track: CGRect, zones: (perfect: Double, great: Double, good: Double)) {
        let x = track.maxX + 4
        let marks: [(low: Double, high: Double, color: Color)] = [
            (0, zones.perfect, Palette.mustard),
            (zones.perfect, zones.great, Palette.skyTeal),
            (zones.great, zones.good, Palette.paper),
        ]
        for mark in marks {
            let top = track.maxY - track.height * CGFloat(mark.high)
            let bottom = track.maxY - track.height * CGFloat(mark.low)
            let bar = CGRect(x: x, y: top + 1, width: 4, height: max(1, bottom - top - 2))
            ctx.fill(Path(roundedRect: bar, cornerRadius: 2), with: .color(mark.color))
            var tick = Path()
            tick.move(to: CGPoint(x: track.maxX - 4, y: top))
            tick.addLine(to: CGPoint(x: x + 8, y: top))
            ctx.stroke(tick, with: .color(mark.color), lineWidth: 2)
        }
    }
}

/// The release button: a circle of 92 pt with a satellite and the number left, inside a 128 pt square that catches near
/// misses (also while it is disabled), so a slightly missed tap never drops a stage. It fires on touch-down. Inside a
/// ring band its rim turns mustard and it pulses; while a release would be Perfect the rim is gold.
struct ReleaseButton: View {
    let count: Int
    let enabled: Bool
    let band: BandCue
    let scale: CGFloat
    let driver: FlightDriver

    var body: some View {
        let rim = rimColor
        let rimWidth: CGFloat = band == .outside ? 3 : (band == .perfect ? 8 : 5)
        let glow = band == .outside ? 0 : (band == .perfect ? 0.55 : 0.35)
        ZStack(alignment: .topTrailing) {
            ZStack {
                Circle().fill(rim.opacity(glow)).padding(-12)
                Circle().fill(Palette.deepTeal)
                Circle().stroke(rim, lineWidth: rimWidth)
                SatelliteIcon(size: 50)
            }
            .frame(width: 92, height: 92)
            .shadow(color: Palette.ink.opacity(0.35), radius: 0, x: 0, y: 4)
            Text(verbatim: "\(count)")
                .font(.rounded(17, .black).monospacedDigit())
                .foregroundStyle(Palette.paper)
                .frame(width: 32, height: 32)
                .background(Circle().fill(Palette.coral))
                .overlay(Circle().stroke(Palette.paper, lineWidth: 2))
                .offset(x: 4, y: -4)
        }
        .scaleEffect(scale)
        .opacity(enabled ? 1 : 0.5)
        .frame(width: 128, height: 128)
        .contentShape(Rectangle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: 10_000, perform: {}, onPressingChanged: { pressing in
            if pressing { driver.tapRelease() }
        })
        .accessibilityElement(children: .ignore)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(Text("Release satellite"))
        .accessibilityValue(Text("\(count) left"))
        .accessibilityAction { driver.tapRelease() }
        .accessibilityIdentifier("flight-release")
    }

    private var rimColor: Color {
        switch band {
        case .outside: return Palette.paper
        case .inside: return Palette.mustard
        case .perfect: return Palette.gold
        }
    }
}

struct PauseCard: View {
    let onResume: () -> Void
    let onAbort: () -> Void

    var body: some View {
        ZStack {
            Palette.night.opacity(0.55)
                .ignoresSafeArea()
            VStack(spacing: 18) {
                Text("Paused")
                    .font(.rounded(32, .black))
                    .foregroundStyle(Palette.ink)
                    .accessibilityIdentifier("pause-title")
                Button {
                    Feedback.shared.play(.button)
                    onResume()
                } label: {
                    Text("Resume")
                }
                .buttonStyle(PillButtonStyle(fill: Palette.deepTeal))
                .accessibilityIdentifier("pause-resume")
                Button {
                    Feedback.shared.play(.button)
                    onAbort()
                } label: {
                    Text("Abort flight")
                        .font(.rounded(19, .bold))
                        .foregroundStyle(Palette.coral)
                        .frame(maxWidth: .infinity, minHeight: 48)
                }
                .accessibilityIdentifier("pause-abort")
                Text("An aborted flight pays nothing.")
                    .font(.rounded(14, .medium))
                    .foregroundStyle(Palette.ink.opacity(0.65))
                    .multilineTextAlignment(.center)
            }
            .padding(26)
            .background(RoundedRectangle(cornerRadius: 28).fill(Palette.cream))
            .padding(.horizontal, 32)
        }
    }
}
