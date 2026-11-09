import Foundation

/// Visual-only particles derived from a frame (no game rules, DESIGN.md "Feel": embers rising, the darkness bank's
/// soot motes): embers drift up from every fire in the frame's light list, soot motes leak out of the darkness bank's
/// edge. Positions snap to whole game pixels. Deterministic for a frame and an animation time, so screenshots taken
/// with `-GWFlickerTime` are exact.
enum Particles {
    /// Embers per fire.
    static func emberCount(_ kind: LightKind) -> Int {
        switch kind {
        case .brazier: return 11
        case .fireTower: return 15
        case .firepot: return 8
        case .hearth: return 7
        case .torch: return 3
        case .beacon: return 24
        default: return 0
        }
    }

    /// Additive 1-pixel embers for the emissive pass (target pixels of each fire's plane; seeded by the fire's place
    /// on its plane, so they keep their paths while the camera moves).
    static func embers(_ frame: FrameDesc, time: Double, reduceMotion: Bool, white: AtlasCell) -> [SpriteQuad] {
        let speed = reduceMotion ? Flicker.reducedRateScale : 1.0
        let texel = white.texels(flipped: false)
        let width = Double(frame.targetWidth)
        let height = Double(frame.targetHeight)
        let hot = SIMD3<Float>(1.0, 0.86, 0.46)
        let cool = SIMD3<Float>(0.95, 0.30, 0.10)
        var list: [SpriteQuad] = []
        for light in frame.lights {
            let count = emberCount(light.kind)
            let strength = Double(light.circle.w)
            guard count > 0, strength > 0.2 else { continue }
            let cx = Double(light.circle.x)
            let cy = Double(light.circle.y)
            let anchor = Int64((cx + Double(frame.layer(light.plane).offset.whole)).rounded())
            let small = light.kind == .torch
            for index in 0..<count {
                let seed = UInt64(bitPattern: anchor &* 977 &+ Int64(index) &* 131 &+ 7)
                let life = 1.5 + 1.7 * unit(seed, 1)
                let cycle = (time * speed + unit(seed, 2) * life) / life
                let age = cycle - cycle.rounded(.down)
                let rise = (small ? 12.0 : 22.0) + 24 * unit(seed, 3)
                let wave = sin((age * (1 + unit(seed, 4)) + unit(seed, 5)) * 2 * Double.pi)
                let spread = small ? 3.0 : 7.0
                let drift = age * 6 * (unit(seed, 7) - 0.35)
                let x = cx + (unit(seed, 6) - 0.5) * spread + wave * (0.8 + 2.4 * age) + drift
                let y = cy - 3 - age * rise
                let fade = pow(1 - age, 1.5) * (0.7 + 0.6 * unit(seed, 8)) * min(1, strength)
                guard fade > 0.05 else { continue }
                let px = x.rounded(.down)
                let py = y.rounded(.down)
                guard px >= 0, py >= 0, px < width, py < height else { continue }
                let color = hot + (cool - hot) * Float(age)
                let gain = Float(fade) * 1.7
                let tint = SIMD4<Float>(color.x * gain, color.y * gain, color.z * gain, 1)
                list.append(SpriteQuad(rect: SIMD4<Float>(Float(px), Float(py), 1, 1), texel: texel, tint: tint))
            }
        }
        return list
    }

    /// Soot motes leaking out of the darkness bank's edge, for the world plane (premultiplied over).
    static func motes(_ frame: FrameDesc, time: Double, reduceMotion: Bool, white: AtlasCell) -> [SpriteQuad] {
        let edge = Double(frame.bankEdge)
        let width = Double(frame.targetWidth)
        guard edge > -40, edge < width + 40 else { return [] }
        let whole = Double(frame.layer(.world).offset.whole)
        let speed = reduceMotion ? Flicker.reducedRateScale : 1.0
        let texel = white.texels(flipped: false)
        let ground = Double(frame.groundRow)
        let anchor = Int64((edge + whole).rounded(.down) / 8)
        var list: [SpriteQuad] = []
        for index in 0..<30 {
            let seed = UInt64(bitPattern: anchor &* 613 &+ Int64(index) &* 389 &+ 11)
            let life = 3.0 + 3.5 * unit(seed, 1)
            let cycle = (time * speed + unit(seed, 2) * life) / life
            let age = cycle - cycle.rounded(.down)
            let x = edge - 36 * unit(seed, 3) + age * (8 + 14 * unit(seed, 4))
                + sin((age + unit(seed, 5)) * 2 * Double.pi) * 2
            let y = ground - 3 - unit(seed, 6) * 130 - age * (5 + 12 * unit(seed, 7))
            let px = x.rounded(.down)
            let py = y.rounded(.down)
            guard px >= 0, py >= 0, px < width, py < ground else { continue }
            let alpha = Float(sin(age * Double.pi)) * 0.9
            guard alpha > 0.05 else { continue }
            let big = unit(seed, 8) > 0.8
            let tint = SIMD4<Float>(0.06, 0.04, 0.09, alpha)
            let rect = SIMD4<Float>(Float(px), Float(py), big ? 2 : 1, 1)
            if big {
                // A 2-pixel mote stretches the white texel; the cell is 1 texel, so read stays inside it.
                list.append(SpriteQuad(rect: rect, texel: SIMD4<Float>(texel.x, texel.y, texel.x + 0.99, texel.w),
                                       tint: tint))
            } else {
                list.append(SpriteQuad(rect: rect, texel: texel, tint: tint))
            }
        }
        return list
    }

    /// A uniform value 0 ..< 1 for a seed and a key.
    static func unit(_ seed: UInt64, _ key: Int64) -> Double {
        Double(SeededRandom.hash(seed, key) >> 11) * 0x1.0p-53
    }
}
