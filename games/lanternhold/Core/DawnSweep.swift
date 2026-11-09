/// First light (DESIGN.md "Day and night": from 05:00 the light sweeps in from the right and the creatures still alive
/// dissolve into soot; "Feel": at first light the light sweeps from right to left; M2b part 2). Its front is where the
/// simulation dissolves creatures (`Battle`'s sweep: `Realm.worldWidth × (6 − hour)`), drawn as a slanted wall of warm
/// light, its foot ahead and its top trailing like low sun, with a softer glow behind where the light has passed.
/// Visual only: the lights stand on the world plane but are not battle lights.
enum DawnSweep {
    /// Warm dawn colours (sRGB): the front's core and the glow behind it.
    static let frontColor = SIMD3<Float>(1.0, 0.86, 0.62)
    static let glowColor = GamePalette.dawnRose

    /// The front of the light in world game pixels, nil outside first light (05:00 to 06:00).
    static func frontX(hour: Double) -> Double? {
        guard DayClock.phase(at: hour) == .firstLight else { return nil }
        return Realm.worldWidth * (6 - DayClock.wrap(hour))
    }

    /// The sweep's lights at `hour` (none outside first light). They fade in over the first 4 % of the sweep and out
    /// over its last 6 %, so first light neither pops on nor off.
    static func lights(hour: Double) -> [LightSource] {
        guard let x = frontX(hour: hour) else { return [] }
        let into = DayClock.wrap(hour) - 5
        let fade = min(1, max(0, min(into / 0.04, (1 - into) / 0.06)))
        guard fade > 0.01 else { return [] }
        let front: [(dx: Double, y: Double, radius: Double, intensity: Double)] = [
            (0, 10, 70, 1.0),
            (22, 60, 84, 0.85),
            (46, 116, 96, 0.7),
            (150, 40, 150, 0.4),
        ]
        return front.enumerated().map { index, part in
            LightSource(kind: .moon, x: x + part.dx, y: part.y, radius: part.radius,
                        color: index == front.count - 1 ? glowColor : frontColor,
                        intensity: part.intensity * fade, flickerSeed: 0x4441_574E &+ UInt64(index))
        }
    }

    /// The front's place on a screen whose left edge is at world x `cameraX` and `viewWidth` game px wide, as a share
    /// of its width (0 left, 1 right); nil outside first light or when the front is off screen.
    static func screenFraction(hour: Double, cameraX: Double, viewWidth: Double) -> Double? {
        guard let x = frontX(hour: hour), viewWidth > 0 else { return nil }
        let share = (x - cameraX) / viewWidth
        return share >= 0 && share <= 1 ? share : nil
    }
}
