import SwiftUI

/// A colour as three numbers, so the sky can blend between stops.
struct RGB: Sendable, Equatable {
    var r: Double
    var g: Double
    var b: Double

    init(hex: UInt32) {
        r = Double((hex >> 16) & 0xFF) / 255.0
        g = Double((hex >> 8) & 0xFF) / 255.0
        b = Double(hex & 0xFF) / 255.0
    }

    init(r: Double, g: Double, b: Double) {
        self.r = r
        self.g = g
        self.b = b
    }

    func mix(_ other: RGB, _ t: Double) -> RGB {
        let k = min(1, max(0, t))
        return RGB(r: r + (other.r - r) * k, g: g + (other.g - g) * k, b: b + (other.b - b) * k)
    }

    var color: Color { Color(.sRGB, red: r, green: g, blue: b, opacity: 1) }

    func color(_ opacity: Double) -> Color { Color(.sRGB, red: r, green: g, blue: b, opacity: opacity) }
}

/// The mid-century space-age poster palette (DESIGN.md "Look").
enum Palette {
    static let creamRGB = RGB(hex: 0xF4E9D8)
    static let skyTealRGB = RGB(hex: 0x7FB7B2)
    static let deepTealRGB = RGB(hex: 0x2E6E73)
    static let navyRGB = RGB(hex: 0x14213D)
    static let nightRGB = RGB(hex: 0x0B1020)
    static let coralRGB = RGB(hex: 0xEE6C4D)
    static let mustardRGB = RGB(hex: 0xF2B544)
    static let paperRGB = RGB(hex: 0xFFF8EC)
    static let inkRGB = RGB(hex: 0x1D2433)

    static let cream = creamRGB.color
    static let skyTeal = skyTealRGB.color
    static let deepTeal = deepTealRGB.color
    static let navy = navyRGB.color
    static let night = nightRGB.color
    static let coral = coralRGB.color
    static let mustard = mustardRGB.color
    static let paper = paperRGB.color
    static let ink = inkRGB.color
    /// A darker teal for the ground and the planet.
    static let groundRGB = RGB(hex: 0x24575B)
    static let gold = RGB(hex: 0xFFD36B).color

    /// Sky colour at an altitude in km: cream and teal at the ground, deep teal around 30 km, navy at 100 km, night above
    /// 300 km.
    static func sky(at altitude: Double) -> RGB {
        let stops: [(Double, RGB)] = [
            (0, creamRGB),
            (4, creamRGB.mix(skyTealRGB, 0.55)),
            (12, skyTealRGB),
            (30, deepTealRGB),
            (100, navyRGB),
            (300, nightRGB),
        ]
        if altitude <= stops[0].0 { return stops[0].1 }
        for index in 1..<stops.count where altitude <= stops[index].0 {
            let low = stops[index - 1]
            let high = stops[index]
            let t = (altitude - low.0) / (high.0 - low.0)
            return low.1.mix(high.1, t)
        }
        return nightRGB
    }
}

extension Font {
    /// SF Rounded, the game's type.
    static func rounded(_ size: CGFloat, _ weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}
