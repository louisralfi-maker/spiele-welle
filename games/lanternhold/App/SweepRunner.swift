import Foundation
import SwiftUI

/// The screen tests' sweep in one launch (the speed kit, 14.11.2026; the test side is `UITests/SweepKit.swift`). A UI
/// test hands the app a list of shots at one launch, each a name and the `-GW` arguments a launch of its own would
/// carry. The app then sets up shot after shot in its own process exactly as a fresh launch with those arguments would:
/// `RootView` and with it `DebugArgs`, the model (save read, `-GWReset` honoured, the realm played headless), the
/// clock, the Metal view and its renderer are made anew for every shot (`.id`), nothing is handed from one shot to the
/// next. A test-only accessibility element without a picture (`gw-sweep`, value `"<index> <name>"`, then `"done"`)
/// says which shot stands; the scene's own `world-scene` value says "ready" as in every launch. The test takes its
/// screenshot and asks for the next shot with a Darwin notification (`gw.sweep.next.<index>`); a tap on the element
/// does the same. Without the environment value `GW_SWEEP` (every normal launch and every other test) nothing here
/// runs, and in a Release build never.
struct SweepPlan: Sendable, Equatable {
    struct Shot: Sendable, Equatable, Codable {
        var name: String
        /// The arguments by key without the dash (`"GWTimeOfDay": "0.95"`), as `DebugArgs(values:)` reads them.
        var values: [String: String]
    }

    var shots: [Shot]

    /// The launch environment key: base64 of the JSON list of shots.
    static let environmentKey = "GW_SWEEP"

    /// The Darwin notification that asks for the shot after `index`.
    static func nextName(after index: Int) -> String { "gw.sweep.next.\(index)" }

    /// The index in a `nextName(after:)` name.
    static func index(inNextName name: String) -> Int? {
        let prefix = "gw.sweep.next."
        guard name.hasPrefix(prefix) else { return nil }
        return Int(name.dropFirst(prefix.count))
    }

    /// The plan the environment carries; nil without one (or with a broken one), and always in a Release build.
    static func from(environment: [String: String]) -> SweepPlan? {
        #if DEBUG
        guard let text = environment[environmentKey], let data = Data(base64Encoded: text),
              let shots = try? JSONDecoder().decode([Shot].self, from: data), !shots.isEmpty else { return nil }
        return SweepPlan(shots: shots)
        #else
        return nil
        #endif
    }

    /// What `DebugArgs.fromProcess()` reads in a launch with this shot's arguments: the known keys only.
    func args(at index: Int) -> DebugArgs {
        let known = Set(DebugArgs.keys)
        return DebugArgs(values: shots[index].values.filter { known.contains($0.key) })
    }

    /// The marker's value: the shot standing now, or "done" after the last.
    func marker(at index: Int) -> String {
        index < shots.count ? "\(index) \(shots[index].name)" : "done"
    }
}

/// The arguments `RootView` reads while a sweep runs (nil otherwise: it reads the process's own).
enum SweepRunner {
    nonisolated(unsafe) static var current: DebugArgs?
}

/// The running sweep of this process: which shot stands, and the step to the next.
@MainActor
@Observable
final class SweepSession {
    let plan: SweepPlan
    private(set) var index = 0

    /// The process's sweep, made once on first use; nil when the launch carries none.
    static let shared: SweepSession? = SweepPlan.from(environment: ProcessInfo.processInfo.environment)
        .map { SweepSession(plan: $0) }

    var isRunning: Bool { index < plan.shots.count }
    var marker: String { plan.marker(at: index) }

    private init(plan: SweepPlan) {
        self.plan = plan
        SweepRunner.current = plan.args(at: 0)
        listen(after: 0)
    }

    /// The test took shot `from`: the next one is set up (a late or doubled request changes nothing).
    func advance(from shot: Int) {
        guard shot == index, isRunning else { return }
        stopListening(after: shot)
        index += 1
        if isRunning {
            SweepRunner.current = plan.args(at: index)
            listen(after: index)
        }
    }

    private var observer: UnsafeRawPointer { UnsafeRawPointer(Unmanaged.passUnretained(self).toOpaque()) }

    private func listen(after shot: Int) {
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), observer, sweepHeard,
                                        SweepPlan.nextName(after: shot) as CFString, nil, .deliverImmediately)
    }

    private func stopListening(after shot: Int) {
        CFNotificationCenterRemoveObserver(CFNotificationCenterGetDarwinNotifyCenter(), observer,
                                           CFNotificationName(SweepPlan.nextName(after: shot) as CFString), nil)
    }
}

/// The Darwin notification's callback (a C function: no captures).
private func sweepHeard(_ center: CFNotificationCenter?, _ observer: UnsafeMutableRawPointer?,
                        _ name: CFNotificationName?, _ object: UnsafeRawPointer?, _ info: CFDictionary?) {
    guard let raw = name?.rawValue, let shot = SweepPlan.index(inNextName: raw as String) else { return }
    Task { @MainActor in
        SweepSession.shared?.advance(from: shot)
    }
}

/// The app's root inside a sweep: the content made anew for every shot, with the test's marker over it (no pixels:
/// a one-point clear text). Outside a sweep it is the content alone.
struct SweepHost<Content: View>: View {
    private let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        if let session = SweepSession.shared {
            Group {
                if session.isRunning {
                    content().id(session.index)
                } else {
                    Color.black.ignoresSafeArea()
                }
            }
            .overlay(alignment: .topLeading) {
                Text(verbatim: " ")
                    .font(.system(size: 1))
                    .foregroundStyle(Color.clear)
                    .frame(width: 1, height: 1)
                    .contentShape(Rectangle())
                    .onTapGesture { session.advance(from: session.index) }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Text(verbatim: "sweep"))
                    .accessibilityValue(Text(verbatim: session.marker))
                    .accessibilityIdentifier("gw-sweep")
                    .accessibilityAddTraits(.isButton)
            }
        } else {
            content()
        }
    }
}
