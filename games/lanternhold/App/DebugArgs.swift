import Foundation

/// Launch arguments that let UI tests and screenshots reach any state (DESIGN.md "Debug launch arguments"). Milestone 1
/// round 1 reads only the scene and the pixel scale experiments.
struct DebugArgs: Sendable, Equatable {
    /// "world" (default), "lightlab" or "testpattern".
    var scene = "world"
    /// Target game-pixel rows of the scale rule (180 by default, 135 for the chunkier look).
    var virtualHeight = 180
    /// Forces device pixels per game pixel.
    var scaleOverride: Int?

    static func fromProcess() -> DebugArgs {
        let defaults = UserDefaults.standard
        var args = DebugArgs()
        if let scene = defaults.string(forKey: "GWScene"), !scene.isEmpty {
            args.scene = scene
        }
        let virtualHeight = defaults.integer(forKey: "GWVirtualHeight")
        if virtualHeight > 0 {
            args.virtualHeight = virtualHeight
        }
        let scaleOverride = defaults.integer(forKey: "GWScaleOverride")
        if scaleOverride > 0 {
            args.scaleOverride = scaleOverride
        }
        return args
    }
}
