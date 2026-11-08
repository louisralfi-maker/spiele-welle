import AVFoundation
import CoreHaptics
import UIKit

/// The one place the game vibrates: authored Core Haptics patterns (`HapticPattern`). Haptics only: the engine never
/// takes the audio session, so it cannot disturb the sound hub's, and it plays with the ring/silent switch on silent (as
/// the system's own haptics do). Everything is garnish: a missing Taptic Engine (the simulator), a stopped engine or an
/// unplayable pattern is a silent no-op, never an error on screen. Adapted from the starter kit.
@MainActor
final class HapticHub {
    static let shared = HapticHub()

    /// The haptics switch in Settings (set by `Feedback`).
    var isEnabled = true

    /// The device can vibrate in patterns.
    nonisolated static var supportsHaptics: Bool { CHHapticEngine.capabilitiesForHardware().supportsHaptics }

    private var engine: CHHapticEngine?
    private var running = false
    private var holds = 0
    private var patterns: [HapticPattern: CHHapticPattern] = [:]
    private var observers: [NSObjectProtocol] = []

    private init() {
        // The engine is stopped when the app leaves the screen and by an audio interruption: it starts again by itself at
        // the next pattern (`ready()`), so these only note that it is down.
        let center = NotificationCenter.default
        observers.append(center.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.shutDown() }
        })
        observers.append(center.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.running = false }
        })
    }

    /// Plays `pattern` now: nothing when the switch is off or the device cannot vibrate.
    func play(_ pattern: HapticPattern) {
        guard isEnabled, Self.supportsHaptics else { return }
        do {
            let engine = try ready()
            let player = try engine.makePlayer(with: try compiled(pattern))
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            // The engine was reset or stopped under us: it starts again at the next pattern.
            running = false
        }
    }

    /// A flight wants its vibrations on the beat: the engine stays warm while it runs (an idle engine shuts itself down to
    /// save power, and starting it again takes a few tens of milliseconds). Every `hold` is matched by a `release`.
    func hold() {
        holds += 1
        engine?.isAutoShutdownEnabled = false
        guard isEnabled, Self.supportsHaptics else { return }
        _ = try? ready()
    }

    func release() {
        holds = max(0, holds - 1)
        if holds == 0 { engine?.isAutoShutdownEnabled = true }
    }

    /// The engine, created on first use and started when it is down.
    private func ready() throws -> CHHapticEngine {
        let engine: CHHapticEngine
        if let existing = self.engine {
            engine = existing
        } else {
            engine = try CHHapticEngine()
            engine.playsHapticsOnly = true
            engine.isAutoShutdownEnabled = holds == 0
            engine.stoppedHandler = { [weak self] _ in
                Task { @MainActor in self?.running = false }
            }
            // The haptic server was reset (a media services reset): the engine has to be started again.
            engine.resetHandler = { [weak self] in
                Task { @MainActor in self?.running = false }
            }
            self.engine = engine
        }
        if !running {
            try engine.start()
            running = true
        }
        return engine
    }

    private func compiled(_ pattern: HapticPattern) throws -> CHHapticPattern {
        if let made = patterns[pattern] { return made }
        let made = try pattern.score.pattern()
        patterns[pattern] = made
        return made
    }

    private func shutDown() {
        guard running else { return }
        running = false
        engine?.stop(completionHandler: nil)
    }
}
