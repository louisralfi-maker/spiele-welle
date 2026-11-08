import Foundation

/// The 15 orbit rings around the planet. A ring is a band `altitude ± halfWidth`; a satellite released inside it is
/// delivered, rated by how close to the centre line it left the rocket.
enum Rings {
    static let altitudes: [Double] = [20, 35, 55, 80, 110, 150, 200, 260, 330, 410, 500, 600, 720, 860, 1000]

    static var count: Int { altitudes.count }

    /// Half the band height in km. Tuned (tools/tune.py) so the starter and the maxed rocket spend 0.59 to 2.53 s inside
    /// every band they cross at 0.5 km/s or more (target 0.5 to 3.0 s): 3.2 km at ring 1, 4.8 at ring 5, 20.8 at ring 15.
    static func halfWidth(_ ring: Int) -> Double {
        2.8 + 0.018 * altitudes[ring]
    }

    /// Base pay of a delivery into `ring` (0-based): round(5 × 1.33^k), 5 … 271 coins.
    static func basePay(_ ring: Int) -> Int {
        Int((5.0 * pow(1.33, Double(ring))).rounded())
    }

    static func bottom(_ ring: Int) -> Double { altitudes[ring] - halfWidth(ring) }
    static func top(_ ring: Int) -> Double { altitudes[ring] + halfWidth(ring) }

    /// The ring whose band holds `altitude`, with the release rating there; `nil` and `.lost` outside every band.
    static func release(at altitude: Double, guidance: Int) -> (ring: Int?, rating: ReleaseRating) {
        for ring in 0..<count {
            let distance = abs(altitude - altitudes[ring]) / halfWidth(ring)
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
