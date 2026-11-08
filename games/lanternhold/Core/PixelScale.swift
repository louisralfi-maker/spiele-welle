/// The integer pixel scale rule (DESIGN.md "Pixel scale"): `s = max(2, floor(H / virtualHeight))` device pixels per game
/// pixel, from the physical landscape size. The render target is `ceil(W / s) + 1` columns (one spare column for smooth
/// scrolling) by `ceil(H / s)` rows; the image is anchored at the bottom, so a partial top row is sky.
struct PixelScale: Sendable, Equatable {
    /// Device pixels per game pixel.
    let scale: Int
    /// The longer side in device pixels.
    let physicalWidth: Int
    /// The shorter side in device pixels.
    let physicalHeight: Int

    /// Either orientation may be passed: the longer side is the width.
    init(physicalWidth a: Int, physicalHeight b: Int, virtualHeight: Int = 180, override: Int? = nil) {
        physicalWidth = max(a, b)
        physicalHeight = min(a, b)
        if let override, override >= 1 {
            scale = override
        } else {
            scale = max(2, physicalHeight / max(1, virtualHeight))
        }
    }

    /// Game pixels across the screen (may be fractional).
    var visibleColumns: Double { Double(physicalWidth) / Double(scale) }
    /// Game pixels down the screen (may be fractional).
    var visibleRows: Double { Double(physicalHeight) / Double(scale) }
    /// Width of the low-resolution render target: every visible column plus one spare.
    var targetWidth: Int { (physicalWidth + scale - 1) / scale + 1 }
    /// Height of the low-resolution render target: every visible row, the partial top row included.
    var targetHeight: Int { (physicalHeight + scale - 1) / scale }
}
