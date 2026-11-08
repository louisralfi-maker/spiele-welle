import SwiftUI

/// The flight screen: the Canvas scene, the HUD and the pause card. A tap anywhere outside the buttons ignites on the pad
/// and drops the current stage in flight.
struct FlightView: View {
    let driver: FlightDriver
    let model: GameModel

    var body: some View {
        ZStack {
            FlightSceneView(driver: driver)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture { driver.tapScene() }
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

/// The part that redraws every frame.
struct FlightSceneView: View {
    let driver: FlightDriver
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(driver: FlightDriver) {
        self.driver = driver
    }

    var body: some View {
        let state = driver.sceneState(reduceMotion: reduceMotion)
        Canvas { context, size in
            FlightScene.draw(&context, size: size, state: state)
        }
        .accessibilityHidden(true)
    }
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
            ZStack {
                VStack(spacing: 0) {
                    topBar(sim)
                    Spacer(minLength: 0)
                    if sim.phase == .pad && !driver.autoplay {
                        tapToLaunch
                            .padding(.bottom, geo.size.height * 0.12)
                    }
                    HStack {
                        Spacer()
                        ReleaseButton(count: sim.satellitesAboard, enabled: sim.isFlying && sim.satellitesAboard > 0) {
                            driver.tapRelease()
                        }
                    }
                    .padding(.trailing, 18)
                    .padding(.bottom, 18)
                }
                HStack {
                    TankGauge(
                        fraction: sim.phase == .pad ? 1 : sim.fuelFraction,
                        spent: sim.phase == .spent,
                        zones: Ratings.gaugeZones(guidance: sim.rocket.guidance),
                        clock: driver.clock,
                        refusedAge: driver.clock - driver.refusedAt,
                        stageCount: sim.stageCount,
                        stageIndex: sim.stageIndex,
                        reduceMotion: reduceMotion
                    )
                    .frame(height: geo.size.height * 0.4 + 60)
                    .padding(.leading, 14)
                    Spacer()
                }
                .allowsHitTesting(false)
            }
        }
    }

    private func topBar(_ sim: FlightSim) -> some View {
        ZStack {
            HStack {
                Button {
                    Feedback.shared.play(.button)
                    driver.pause()
                } label: {
                    Image(systemName: "pause.fill")
                        .font(.system(size: 18, weight: .heavy))
                        .foregroundStyle(Palette.paper)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(Palette.night.opacity(0.45)))
                }
                .accessibilityLabel(Text("Pause"))
                .accessibilityIdentifier("flight-pause")
                Spacer()
                CoinAmount(value: driver.flightCoins, size: 20, color: Palette.paper)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Palette.night.opacity(0.45)))
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Text("\(driver.flightCoins) coins"))
            }
            VStack(spacing: 0) {
                Text("\(Int(sim.altitude.rounded())) km")
                    .font(.rounded(34, .black).monospacedDigit())
                    .foregroundStyle(Palette.paper)
                    .shadow(color: Palette.ink.opacity(0.5), radius: 0, x: 0, y: 2)
                    .accessibilityIdentifier("flight-altitude")
                Text(verbatim: "\(max(0, sim.speed).formatted(.number.precision(.fractionLength(1)))) km/s")
                    .font(.rounded(13, .bold).monospacedDigit())
                    .foregroundStyle(Palette.paper.opacity(0.85))
                    .accessibilityHidden(true)
            }
            .allowsHitTesting(false)
        }
        .padding(.horizontal, 14)
        .padding(.top, 6)
    }

    private var tapToLaunch: some View {
        let pulse = reduceMotion ? 1 : 0.6 + 0.4 * abs(sin(driver.clock * 2.6))
        return Text("Tap to launch")
            .font(.rounded(28, .black))
            .foregroundStyle(Palette.ink)
            .padding(.horizontal, 22)
            .padding(.vertical, 12)
            .background(Capsule().fill(Palette.paper.opacity(0.85)))
            .opacity(pulse)
            .allowsHitTesting(false)
    }
}

/// The tank of the burning stage, with its timing zones: Perfect at the bottom in mustard, then Great and Good. Blinks red
/// when the stage is empty but still attached; shakes when a drop is refused on the last stage.
struct TankGauge: View {
    let fraction: Double
    let spent: Bool
    let zones: (perfect: Double, great: Double, good: Double)
    let clock: Double
    let refusedAge: Double
    let stageCount: Int
    let stageIndex: Int
    let reduceMotion: Bool

    var body: some View {
        VStack(spacing: 10) {
            Canvas { context, size in
                draw(context, size: size)
            }
            .frame(width: 36)
            VStack(spacing: 5) {
                ForEach(0..<stageCount, id: \.self) { index in
                    let stage = stageCount - 1 - index
                    Circle()
                        .fill(stage >= stageIndex ? Palette.paper : Palette.paper.opacity(0.15))
                        .overlay(Circle().stroke(stage == stageIndex ? Palette.mustard : Palette.ink.opacity(0.4), lineWidth: 2))
                        .frame(width: 11, height: 11)
                }
            }
        }
        .offset(x: shakeOffset)
        .accessibilityHidden(true)
    }

    private var shakeOffset: CGFloat {
        guard !reduceMotion, refusedAge >= 0, refusedAge < 0.35 else { return 0 }
        let decay = 1 - refusedAge / 0.35
        return CGFloat(sin(refusedAge * 70) * 7 * decay)
    }

    private func draw(_ context: GraphicsContext, size: CGSize) {
        let track = CGRect(x: 3, y: 3, width: size.width - 6, height: size.height - 6)
        let shape = Path(roundedRect: track, cornerRadius: track.width / 2)
        var blink = 0.0
        if spent {
            blink = reduceMotion ? 0.6 : 0.35 + 0.35 * (sin(clock * 14) > 0 ? 1 : 0)
        }
        context.fill(shape, with: .color(Palette.night.opacity(0.5)))
        if blink > 0 {
            context.fill(shape, with: .color(Palette.coral.opacity(blink)))
        }
        var inner = context
        inner.clip(to: shape)
        let bands: [(Double, Color)] = [
            (zones.good, Palette.paper.opacity(0.16)),
            (zones.great, Palette.mustard.opacity(0.45)),
            (zones.perfect, Palette.mustard.opacity(0.95)),
        ]
        for (top, color) in bands {
            let h = track.height * CGFloat(top)
            inner.fill(Path(CGRect(x: track.minX, y: track.maxY - h, width: track.width, height: h)), with: .color(color))
        }
        let level = track.height * CGFloat(min(1, max(0, fraction)))
        let fuel = CGRect(x: track.minX + 5, y: track.maxY - level, width: track.width - 10, height: level)
        inner.fill(Path(roundedRect: fuel, cornerRadius: 4), with: .color(Palette.cream.opacity(0.75)))
        if level > 1 {
            var edge = Path()
            edge.move(to: CGPoint(x: track.minX, y: track.maxY - level))
            edge.addLine(to: CGPoint(x: track.maxX, y: track.maxY - level))
            inner.stroke(edge, with: .color(Palette.paper), lineWidth: 2.5)
        }
        context.stroke(shape, with: .color(Palette.paper.opacity(0.9)), lineWidth: 2.5)
    }
}

/// The release button: a circle of 92 pt with a satellite and the number left.
struct ReleaseButton: View {
    let count: Int
    let enabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                ZStack {
                    Circle().fill(Palette.deepTeal)
                    Circle().stroke(Palette.paper, lineWidth: 3)
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
            .opacity(enabled ? 1 : 0.5)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .accessibilityLabel(Text("Release satellite"))
        .accessibilityValue(Text("\(count) left"))
        .accessibilityIdentifier("flight-release")
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
                Button {
                    Feedback.shared.play(.button)
                    onResume()
                } label: {
                    Text("Resume")
                }
                .buttonStyle(PillButtonStyle(fill: Palette.deepTeal))
                Button {
                    Feedback.shared.play(.button)
                    onAbort()
                } label: {
                    Text("Abort flight")
                        .font(.rounded(19, .bold))
                        .foregroundStyle(Palette.coral)
                        .frame(maxWidth: .infinity, minHeight: 48)
                }
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
