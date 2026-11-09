import CoreGraphics
import Foundation
import ImageIO
import Metal

/// One 8-bit sRGB colour with straight alpha.
struct RGBA: Sendable, Equatable, Hashable {
    var r: UInt8
    var g: UInt8
    var b: UInt8
    var a: UInt8

    init(r: UInt8, g: UInt8, b: UInt8, a: UInt8 = 255) {
        self.r = r
        self.g = g
        self.b = b
        self.a = a
    }

    /// A colour from 0xRRGGBB.
    init(_ hex: UInt32, alpha: UInt8 = 255) {
        r = UInt8((hex >> 16) & 0xFF)
        g = UInt8((hex >> 8) & 0xFF)
        b = UInt8(hex & 0xFF)
        a = alpha
    }

    static let clear = RGBA(r: 0, g: 0, b: 0, a: 0)

    /// The same colour with another alpha.
    func alpha(_ value: UInt8) -> RGBA {
        RGBA(r: r, g: g, b: b, a: value)
    }

    /// Blended toward `other` by `t` (0 keeps self, 1 gives other); alpha from self.
    func mixed(_ other: RGBA, _ t: Double) -> RGBA {
        let k = min(1, max(0, t))
        func m(_ x: UInt8, _ y: UInt8) -> UInt8 {
            let value = Double(x) + (Double(y) - Double(x)) * k
            return UInt8(min(255, max(0, value.rounded())))
        }
        return RGBA(r: m(r, other.r), g: m(g, other.g), b: m(b, other.b), a: a)
    }
}

/// An 8-bit RGBA image, rows top to bottom; one texel is one game pixel.
struct PixelImage: Sendable, Equatable {
    let width: Int
    let height: Int
    private(set) var bytes: [UInt8]

    init(width: Int, height: Int, fill: RGBA = .clear) {
        let w = max(0, width)
        let h = max(0, height)
        self.width = w
        self.height = h
        if fill == .clear {
            bytes = [UInt8](repeating: 0, count: w * h * 4)
        } else {
            var pattern = [UInt8](repeating: 0, count: w * h * 4)
            var index = 0
            while index < pattern.count {
                pattern[index] = fill.r
                pattern[index + 1] = fill.g
                pattern[index + 2] = fill.b
                pattern[index + 3] = fill.a
                index += 4
            }
            bytes = pattern
        }
    }

    /// An image from RGBA bytes (`width × height × 4`), or nil when the count does not fit.
    init?(width: Int, height: Int, bytes: [UInt8]) {
        guard width >= 0, height >= 0, bytes.count == width * height * 4 else { return nil }
        self.width = width
        self.height = height
        self.bytes = bytes
    }

    func contains(_ x: Int, _ y: Int) -> Bool {
        x >= 0 && y >= 0 && x < width && y < height
    }

    /// The texel at (x, y); clear outside the image. Writes outside are ignored.
    subscript(x: Int, y: Int) -> RGBA {
        get {
            guard contains(x, y) else { return .clear }
            let i = (y * width + x) * 4
            return RGBA(r: bytes[i], g: bytes[i + 1], b: bytes[i + 2], a: bytes[i + 3])
        }
        set {
            guard contains(x, y) else { return }
            let i = (y * width + x) * 4
            bytes[i] = newValue.r
            bytes[i + 1] = newValue.g
            bytes[i + 2] = newValue.b
            bytes[i + 3] = newValue.a
        }
    }

    /// A `w × h` piece starting at (x, y); parts outside the image are clear.
    func cropped(x: Int, y: Int, width w: Int, height h: Int) -> PixelImage {
        var out = PixelImage(width: w, height: h)
        for row in 0..<max(0, h) {
            for column in 0..<max(0, w) {
                out[column, row] = self[x + column, y + row]
            }
        }
        return out
    }

    /// Copies `other` into this image with its top-left corner at (x, y), texel for texel (no blending).
    mutating func copy(_ other: PixelImage, x: Int, y: Int) {
        for row in 0..<other.height {
            for column in 0..<other.width {
                self[x + column, y + row] = other[column, row]
            }
        }
    }

    /// The image mirrored left to right.
    func flippedHorizontally() -> PixelImage {
        var out = PixelImage(width: width, height: height)
        for row in 0..<height {
            for column in 0..<width {
                out[width - 1 - column, row] = self[column, row]
            }
        }
        return out
    }

    /// True when every texel is fully transparent.
    var isEmpty: Bool {
        var index = 3
        while index < bytes.count {
            if bytes[index] != 0 { return false }
            index += 4
        }
        return true
    }
}

/// Decodes PNG files pixel for pixel: no colour matching, no gamma, straight alpha (DESIGN.md "Art pipeline": lossless
/// PNG, 1 texel = 1 game pixel, binary alpha). The raw decoded bytes are read when the layout is plain 8-bit RGB(A);
/// any other layout is drawn into a bitmap of the image's own colour space, which is an identity transform.
enum PNGDecoder {
    static func decode(data: Data) -> PixelImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            return nil
        }
        return pixels(of: image)
    }

    static func load(url: URL) -> PixelImage? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return decode(data: data)
    }

    static func pixels(of image: CGImage) -> PixelImage? {
        let width = image.width
        let height = image.height
        guard width > 0, height > 0, width <= 4096, height <= 4096 else { return nil }
        if let raw = rawPixels(of: image) { return raw }
        return drawnPixels(of: image)
    }

    /// The decoded bytes as they are, for 8-bit RGB layouts (RGBA, ARGB, BGRA, RGBX, RGB).
    private static func rawPixels(of image: CGImage) -> PixelImage? {
        guard image.bitsPerComponent == 8, let space = image.colorSpace, space.model == .rgb else { return nil }
        guard let data = image.dataProvider?.data else { return nil }
        let bitsPerPixel = image.bitsPerPixel
        guard bitsPerPixel == 32 || bitsPerPixel == 24 else { return nil }
        let alpha = image.alphaInfo
        let order = image.byteOrderInfo
        let little = order == .order32Little
        guard order == .orderDefault || order == .order32Big || (little && bitsPerPixel == 32) else { return nil }

        // Byte positions of r, g, b and alpha (nil: opaque) inside one pixel, in memory order.
        var red = 0
        var green = 1
        var blue = 2
        var alphaIndex: Int?
        var premultiplied = false
        if bitsPerPixel == 24 {
            guard alpha == .none else { return nil }
        } else if alpha == .last || alpha == .premultipliedLast || alpha == .noneSkipLast {
            alphaIndex = alpha == .noneSkipLast ? nil : 3
            premultiplied = alpha == .premultipliedLast
        } else if alpha == .first || alpha == .premultipliedFirst || alpha == .noneSkipFirst {
            red = 1
            green = 2
            blue = 3
            alphaIndex = alpha == .noneSkipFirst ? nil : 0
            premultiplied = alpha == .premultipliedFirst
        } else {
            return nil
        }
        if little {
            // A 32-bit little-endian word stores its bytes reversed.
            red = 3 - red
            green = 3 - green
            blue = 3 - blue
            if let index = alphaIndex { alphaIndex = 3 - index }
        }

        let width = image.width
        let height = image.height
        let rowBytes = image.bytesPerRow
        let pixelBytes = bitsPerPixel / 8
        let length = CFDataGetLength(data)
        guard rowBytes >= width * pixelBytes, length >= rowBytes * (height - 1) + width * pixelBytes,
              let base = CFDataGetBytePtr(data) else {
            return nil
        }
        var bytes = [UInt8](repeating: 0, count: width * height * 4)
        for y in 0..<height {
            for x in 0..<width {
                let source = y * rowBytes + x * pixelBytes
                let target = (y * width + x) * 4
                var r = base[source + red]
                var g = base[source + green]
                var b = base[source + blue]
                let a: UInt8 = alphaIndex.map { base[source + $0] } ?? 255
                if premultiplied && a > 0 && a < 255 {
                    r = unpremultiply(r, a)
                    g = unpremultiply(g, a)
                    b = unpremultiply(b, a)
                }
                bytes[target] = r
                bytes[target + 1] = g
                bytes[target + 2] = b
                bytes[target + 3] = a
            }
        }
        return PixelImage(width: width, height: height, bytes: bytes)
    }

    /// Draws the image 1:1 into an RGBA bitmap of its own colour space (no conversion) and un-premultiplies.
    private static func drawnPixels(of image: CGImage) -> PixelImage? {
        let width = image.width
        let height = image.height
        let fallback = CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()
        var space = fallback
        if let own = image.colorSpace, own.model == .rgb {
            space = own
        }
        let info = CGImageAlphaInfo.premultipliedLast.rawValue | CGImageByteOrderInfo.order32Big.rawValue
        var context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8,
                                bytesPerRow: width * 4, space: space, bitmapInfo: info)
        if context == nil {
            context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8,
                                bytesPerRow: width * 4, space: fallback, bitmapInfo: info)
        }
        guard let context else { return nil }
        context.setBlendMode(.copy)
        context.interpolationQuality = .none
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        guard let data = context.data else { return nil }
        let pointer = data.bindMemory(to: UInt8.self, capacity: width * height * 4)
        var bytes = [UInt8](repeating: 0, count: width * height * 4)
        for index in 0..<(width * height) {
            let i = index * 4
            let a = pointer[i + 3]
            var r = pointer[i]
            var g = pointer[i + 1]
            var b = pointer[i + 2]
            if a > 0 && a < 255 {
                r = unpremultiply(r, a)
                g = unpremultiply(g, a)
                b = unpremultiply(b, a)
            }
            bytes[i] = r
            bytes[i + 1] = g
            bytes[i + 2] = b
            bytes[i + 3] = a
        }
        return PixelImage(width: width, height: height, bytes: bytes)
    }

    private static func unpremultiply(_ value: UInt8, _ alpha: UInt8) -> UInt8 {
        let scaled = (Int(value) * 255 + Int(alpha) / 2) / Int(alpha)
        return UInt8(min(255, scaled))
    }
}

/// Where one atlas cell sits, in texels.
struct AtlasCell: Sendable, Equatable {
    let x: Int
    let y: Int
    let width: Int
    let height: Int

    /// The cell as `u0, v0, u1, v1` texel coordinates for the shaders (u0 > u1 when mirrored).
    func texels(flipped: Bool) -> SIMD4<Float> {
        let left = Float(x)
        let right = Float(x + width)
        let top = Float(y)
        let bottom = Float(y + height)
        return flipped ? SIMD4<Float>(right, top, left, bottom) : SIMD4<Float>(left, top, right, bottom)
    }
}

/// Whether a sprite came from `Resources/Art` or from the procedural placeholder.
enum AtlasSource: String, Sendable, Equatable {
    case png, placeholder
}

/// The one atlas page of milestone 1 (DESIGN.md "Art pipeline": at most 2048², cells padded by 2 px, nearest
/// sampling): every frame of every `SpriteID` at exactly `SpriteID.size`, plus one white texel for particles.
struct AtlasLayout: Sendable {
    static let padding = 2
    static let maxSide = 2048

    let width: Int
    let height: Int
    let image: PixelImage
    let cells: [SpriteID: [AtlasCell]]
    let white: AtlasCell
    let sources: [SpriteID: AtlasSource]

    /// The cell of a sprite's frame (frames wrap around; an unknown sprite gives the white texel).
    func cell(_ sprite: SpriteID, frame: Int) -> AtlasCell {
        guard let frames = cells[sprite], !frames.isEmpty else { return white }
        let count = frames.count
        return frames[((frame % count) + count) % count]
    }

    /// Built once per process from the app bundle.
    static let shared: AtlasLayout = AtlasBuilder.build(bundle: .main)
}

/// Builds the atlas: for each sprite the PNG `Resources/Art/<rawValue>.png` when the bundle has one, else the
/// procedural placeholder; then a shelf packer places every frame with 2 px of clear padding.
enum AtlasBuilder {
    private enum Key: Hashable {
        case sprite(SpriteID, Int)
        case white
    }

    static func build(bundle: Bundle) -> AtlasLayout {
        var items: [(key: Key, image: PixelImage)] = []
        var sources: [SpriteID: AtlasSource] = [:]
        for sprite in SpriteID.allCases {
            let loaded = frames(for: sprite, bundle: bundle)
            sources[sprite] = loaded.source
            for (index, frame) in loaded.frames.enumerated() {
                items.append((key: .sprite(sprite, index), image: frame))
            }
        }
        items.append((key: .white, image: PixelImage(width: 1, height: 1, fill: RGBA(0xFFFFFF))))

        let sizes = items.map { PixelSize(width: $0.image.width, height: $0.image.height) }
        var packed = pack(sizes, width: 1024)
        var atlasWidth = 1024
        if packed == nil || (packed?.height ?? 0) > AtlasLayout.maxSide {
            atlasWidth = AtlasLayout.maxSide
            packed = pack(sizes, width: atlasWidth)
        }
        let placement = packed ?? (origins: Array(repeating: (x: 0, y: 0), count: sizes.count), height: 1)
        let atlasHeight = min(AtlasLayout.maxSide, max(1, placement.height))

        var image = PixelImage(width: atlasWidth, height: atlasHeight)
        var cells: [SpriteID: [AtlasCell]] = [:]
        var white = AtlasCell(x: 0, y: 0, width: 1, height: 1)
        for (index, item) in items.enumerated() {
            let origin = placement.origins[index]
            image.copy(item.image, x: origin.x, y: origin.y)
            let cell = AtlasCell(x: origin.x, y: origin.y, width: item.image.width, height: item.image.height)
            switch item.key {
            case let .sprite(sprite, _):
                cells[sprite, default: []].append(cell)
            case .white:
                white = cell
            }
        }
        return AtlasLayout(width: atlasWidth, height: atlasHeight, image: image, cells: cells, white: white,
                           sources: sources)
    }

    /// A sprite's frames at exactly its size, from its PNG when there is one.
    static func frames(for sprite: SpriteID, bundle: Bundle) -> (frames: [PixelImage], source: AtlasSource) {
        if let url = artURL(for: sprite, bundle: bundle), let image = PNGDecoder.load(url: url) {
            let frames = splitFrames(image, size: sprite.size, count: sprite.frameCount)
            if !frames.isEmpty && !frames.allSatisfy(\.isEmpty) {
                return (frames, .png)
            }
        }
        return (PlaceholderArt.frames(for: sprite), .placeholder)
    }

    /// `Art/<name>.png` in the bundle (a folder reference keeps the folder; a group copies the file to the top).
    static func artURL(for sprite: SpriteID, bundle: Bundle) -> URL? {
        if let url = bundle.url(forResource: sprite.rawValue, withExtension: "png", subdirectory: "Art") {
            return url
        }
        return bundle.url(forResource: sprite.rawValue, withExtension: "png")
    }

    /// Cuts a PNG into `count` frames of `size`: a horizontal strip (`count × width` wide), a vertical strip, or one
    /// frame used for all. A horizontal strip with fewer frames repeats its last frame (M2b: the one-frame palisade,
    /// stone wall and ballista until their damaged and loosed frames land), one with more keeps the first `count`.
    /// Any other size is cropped or padded around its bottom centre, where sprites stand.
    static func splitFrames(_ image: PixelImage, size: PixelSize, count: Int) -> [PixelImage] {
        let n = max(1, count)
        let w = size.width
        let h = size.height
        if n > 1 && w > 0 && image.height == h && image.width >= w * 2 && image.width % w == 0 {
            let available = image.width / w
            return (0..<n).map { image.cropped(x: min($0, available - 1) * w, y: 0, width: w, height: h) }
        }
        if n > 1 && image.width == w * n && image.height == h {
            return (0..<n).map { image.cropped(x: $0 * w, y: 0, width: w, height: h) }
        }
        if n > 1 && image.width == w && image.height == h * n {
            return (0..<n).map { image.cropped(x: 0, y: $0 * h, width: w, height: h) }
        }
        let single: PixelImage
        if image.width == w && image.height == h {
            single = image
        } else {
            let x = (image.width - w) / 2
            let y = image.height - h
            single = image.cropped(x: x, y: y, width: w, height: h)
        }
        return Array(repeating: single, count: n)
    }

    /// Shelf packing, tallest first. Each cell's origin leaves `padding` clear texels on every side.
    static func pack(_ sizes: [PixelSize], width: Int) -> (origins: [(x: Int, y: Int)], height: Int)? {
        let pad = AtlasLayout.padding
        let order = sizes.indices.sorted { a, b in
            if sizes[a].height != sizes[b].height { return sizes[a].height > sizes[b].height }
            if sizes[a].width != sizes[b].width { return sizes[a].width > sizes[b].width }
            return a < b
        }
        var origins: [(x: Int, y: Int)] = Array(repeating: (x: 0, y: 0), count: sizes.count)
        var x = 0
        var y = 0
        var rowHeight = 0
        for index in order {
            let w = sizes[index].width + 2 * pad
            let h = sizes[index].height + 2 * pad
            if w > width { return nil }
            if x + w > width {
                y += rowHeight
                x = 0
                rowHeight = 0
            }
            origins[index] = (x: x + pad, y: y + pad)
            x += w
            rowHeight = max(rowHeight, h)
        }
        return (origins, y + rowHeight)
    }
}

/// The atlas page on the GPU: a private `rgba8Unorm` texture filled by a blit from a shared buffer with rows aligned to
/// 256 bytes (safe in the Simulator).
final class AtlasTexture: @unchecked Sendable {
    let layout: AtlasLayout
    let texture: any MTLTexture

    init?(layout: AtlasLayout, context: MetalContext) {
        let width = layout.width
        let height = layout.height
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm, width: width,
                                                                  height: height, mipmapped: false)
        descriptor.usage = [.shaderRead]
        descriptor.storageMode = .private
        guard let texture = context.device.makeTexture(descriptor: descriptor) else { return nil }

        let rowBytes = width * 4
        let alignedRow = (rowBytes + 255) / 256 * 256
        var staging = [UInt8](repeating: 0, count: alignedRow * height)
        let source = layout.image.bytes
        for row in 0..<height {
            let from = row * rowBytes
            let to = row * alignedRow
            staging.replaceSubrange(to..<(to + rowBytes), with: source[from..<(from + rowBytes)])
        }
        guard let buffer = context.device.makeBuffer(bytes: staging, length: staging.count,
                                                     options: .storageModeShared),
              let commands = context.queue.makeCommandBuffer(),
              let blit = commands.makeBlitCommandEncoder() else {
            return nil
        }
        blit.copy(from: buffer, sourceOffset: 0, sourceBytesPerRow: alignedRow, sourceBytesPerImage: staging.count,
                  sourceSize: MTLSize(width: width, height: height, depth: 1), to: texture, destinationSlice: 0,
                  destinationLevel: 0, destinationOrigin: MTLOrigin(x: 0, y: 0, z: 0))
        blit.endEncoding()
        commands.commit()
        commands.waitUntilCompleted()
        guard commands.status == .completed else { return nil }
        self.layout = layout
        self.texture = texture
    }

    /// The shared page, uploaded once per process.
    @MainActor
    static func shared(context: MetalContext) -> AtlasTexture? {
        if let cached = cache { return cached }
        let made = AtlasTexture(layout: AtlasLayout.shared, context: context)
        cache = made
        return made
    }

    @MainActor private static var cache: AtlasTexture?
}
