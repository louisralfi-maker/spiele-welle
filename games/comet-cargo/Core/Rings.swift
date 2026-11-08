import Foundation

/// The 15 orbit rings around the planet. A ring is a band `altitude ± halfWidth`; a satellite released inside it is
/// delivered, rated by how close to the centre line it left the rocket.
enum Rings {
    static let altitudes: [Double] = [20, 35, 55, 80, 110, 150, 200, 260, 330, 410, 500, 600, 720, 860, 1000]

    static var count: Int { altitudes.count }

    /// A fast rocket's band spans this many seconds of flight on each side of the centre line, so every crossing lasts
    /// about 0.9 s however fast the rocket is (tools/tune.py: 0.88 to 2.53 s for the starter and the maxed rocket).
    static let bandSeconds = 0.45
    /// No band reaches past this share of the gap to its nearest neighbour (or to the ground), so bands never touch.
    static let maxGapShare = 0.45

    /// Half the band height at low speed, in km: 3.2 at ring 1, 4.8 at ring 5, 20.8 at ring 15.
    static func baseHalfWidth(_ ring: Int) -> Double {
        2.8 + 0.018 * altitudes[ring]
    }

    /// The widest a band may get: 45 % of the gap to the nearest neighbour ring (ring 1 also counts the ground).
    static func maxHalfWidth(_ ring: Int) -> Double {
        let below = ring == 0 ? altitudes[0] : altitudes[ring] - altitudes[ring - 1]
        let above = ring == count - 1 ? below : altitudes[ring + 1] - altitudes[ring]
        return maxGapShare * min(below, above)
    }

    /// Half the band height in km for a rocket at `speed` km/s: the low-speed width, or `bandSeconds` of flight when
    /// that is wider, never past `maxHalfWidth`.
    static func halfWidth(_ ring: Int, speed: Double = 0) -> Double {
        let moving = max(0, speed) * bandSeconds
        return min(maxHalfWidth(ring), max(baseHalfWidth(ring), moving))
    }

    /// Base pay of a delivery into `ring` (0-based): round(5 × 1.33^k), 5 … 271 coins.
    static func basePay(_ ring: Int) -> Int {
        Int((5.0 * pow(1.33, Double(ring))).rounded())
    }

    static func bottom(_ ring: Int, speed: Double = 0) -> Double { altitudes[ring] - halfWidth(ring, speed: speed) }
    static func top(_ ring: Int, speed: Double = 0) -> Double { altitudes[ring] + halfWidth(ring, speed: speed) }

    /// The ring whose band holds `altitude` for a rocket at `speed`, with the release rating there; `nil` and `.lost`
    /// outside every band.
    static func release(at altitude: Double, speed: Double = 0, guidance: Int) -> (ring: Int?, rating: ReleaseRating) {
        for ring in 0..<count {
            let distance = abs(altitude - altitudes[ring]) / halfWidth(ring, speed: speed)
            if distance <= 1.0 {
                return (ring, Ratings.release(distance: distance, guidance: guidance))
            }
        }
        return (nil, .lost)
    }

    /// The highest ring whose centre lies below `altitude`, or nil.
    static func highestBelow(_ altitude: Double) -> Int? {
        var found: Int?
        for ring in 0..<count where altitudes[ring] < altitude {
            found = ring
        }
        return found
    }
}
