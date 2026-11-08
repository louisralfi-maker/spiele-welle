import CoreGraphics
import Foundation
import ImageIO
import SwiftUI

/// The Recraft paintings ship as plain HEIC files in `Resources/Art` (copied flat into the app bundle; the asset catalog
/// holds only the app icon). Each file is decoded once, on first use, and kept for the life of the app, so the scene never
/// decodes per frame. A missing file is remembered as missing and returns nil: the caller then draws its procedural
/// fallback. The files are already sized for their drawn size (ART.md), so no downsampling happens here.
enum ArtAsset {
    /// The decoded picture, or nil when the bundle has no such file.
    static func cgImage(_ name: String) -> CGImage? {
        store.image(name)
    }

    /// The picture as a SwiftUI image for a GraphicsContext. `scale` is pixels per point of the file as drawn at its
    /// natural size; callers that draw it into a rect may pass 1.
    static func image(_ name: String, scale: CGFloat = 1) -> Image? {
        guard let cg = store.image(name) else { return nil }
        return Image(decorative: cg, scale: scale)
    }

    /// Width over height of the picture, 1 when it is missing.
    static func aspect(_ name: String) -> CGFloat {
        guard let cg = store.image(name), cg.height > 0 else { return 1 }
        return CGFloat(cg.width) / CGFloat(cg.height)
    }

    /// Decodes every painted piece now (call it off the main thread at launch), so no picture is decoded inside a frame
    /// the first time it comes into view.
    static func prewarm() {
        for name in ArtName.all {
            _ = store.image(name)
        }
    }

    static func decode(_ name: String) -> CGImage? {
        for ext in ["heic", "png"] {
            guard let url = Bundle.main.url(forResource: name, withExtension: ext),
                  let source = CGImageSourceCreateWithURL(url as CFURL, nil)
            else { continue }
            let options = [kCGImageSourceShouldCacheImmediately: true] as CFDictionary
            if let image = CGImageSourceCreateImageAtIndex(source, 0, options) {
                return image
            }
        }
        return nil
    }

    /// Decoded pictures by name, nil for a file that is not in the bundle. Guarded by a lock: the Canvas closures may
    /// run off the main thread.
    private final class Store: @unchecked Sendable {
        private let lock = NSLock()
        private var images: [String: CGImage?] = [:]

        func image(_ name: String) -> CGImage? {
            lock.lock()
            defer { lock.unlock() }
            if let hit = images[name] {
                return hit
            }
            let loaded = ArtAsset.decode(name)
            images[name] = .some(loaded)
            return loaded
        }
    }

    private static let store = Store()
}

/// The names of the painted pieces (files in `Resources/Art`).
enum ArtName {
    static let cloudCount = 6
    static let satelliteCount = 3
    static func cloud(_ index: Int) -> String { "cloud-\(index % cloudCount + 1)" }
    static func satellite(_ index: Int) -> String { "satellite-\(abs(index) % satelliteCount + 1)" }
    static let planet = "planet"
    static let launchSite = "launchsite"
    static let paper = "paper"
    static let planetSurface = "planet-surface"

    /// Every painted piece, for decoding them all once at launch.
    static var all: [String] {
        var names = [paper, launchSite, planet, planetSurface]
        names += (0..<cloudCount).map { ArtName.cloud($0) }
        names += (0..<satelliteCount).map { ArtName.satellite($0) }
        return names
    }
}
