/// The seeded random stream (DESIGN.md "Tech plan": SplitMix64). Every random choice in the game draws from one of
/// these, so the same seed always gives the same realm, the same night and the same placeholder scene.
struct SeededRandom: RandomNumberGenerator, Sendable, Equatable {
    /// The golden-ratio increment of SplitMix64.
    static let increment: UInt64 = 0x9E37_79B9_7F4A_7C15

    /// The internal counter; advances by `increment` on every draw.
    private(set) var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    /// The SplitMix64 finaliser: a strong, stateless mix of 64 bits. Also used as a hash for value noise.
    static func mix(_ value: UInt64) -> UInt64 {
        var z = value
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }

    /// A stateless hash of a seed and a lattice index (value noise, per-light flicker).
    static func hash(_ seed: UInt64, _ index: Int64) -> UInt64 {
        let lattice = UInt64(bitPattern: index) &* increment
        return mix(seed ^ mix(lattice &+ 0x632B_E59B_D9B4_E019))
    }

    /// The next 64 random bits.
    mutating func next() -> UInt64 {
        state = state &+ SeededRandom.increment
        return SeededRandom.mix(state)
    }

    /// A uniform double in 0 ..< 1 (53 bits of precision).
    mutating func nextDouble() -> Double {
        let bits = next() >> 11
        return Double(bits) * 0x1.0p-53
    }

    /// A uniform integer in `range` (both ends included). The tiny modulo bias is irrelevant for game choices.
    mutating func int(in range: ClosedRange<Int>) -> Int {
        let width = UInt64(bitPattern: Int64(range.upperBound &- range.lowerBound))
        let span = width &+ 1
        if span == 0 {
            return Int(truncatingIfNeeded: next())
        }
        let offset = Int(truncatingIfNeeded: next() % span)
        return range.lowerBound &+ offset
    }

    /// A uniform double in `range`.
    mutating func double(in range: ClosedRange<Double>) -> Double {
        let unit = nextDouble()
        return range.lowerBound + (range.upperBound - range.lowerBound) * unit
    }
}
