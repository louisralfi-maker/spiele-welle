import XCTest
@testable import Lanternhold

/// Camera maths (DESIGN.md "Tech plan", docs/research-rendering.md 3.2): plane offsets, clamping, and the walking king
/// held steady on screen.
final class CameraTests: XCTestCase {
    private let dt = 1.0 / 60.0

    func testParallaxFactors() {
        let factors = Plane.allCases.map(\.parallax)
        XCTAssertEqual(factors, [0, 0.05, 0.2, 0.5, 0.62, 0.75, 0.9, 1.0, 1.15, 1.3])
        XCTAssertEqual(Plane.allCases.map(\.rawValue), Array(0..<10), "back to front")
    }

    func testPlaneOffsetsAtTheFrontShot() {
        // -GWCameraX 760 on the iPhone 17 Pro (437 columns): the left edge is 541.5.
        let camera = Camera(focusX: 760, viewWidth: 437)
        XCTAssertEqual(camera.x, 541.5)
        let expected: [(Plane, Int, Int)] = [
            (.sky, 0, 0), (.clouds, 27, 0), (.far, 108, 2), (.mid, 270, 5), (.fogA, 487, 2), (.world, 541, 3),
            (.fogB, 622, 4), (.foreground, 703, 6),
        ]
        for (plane, whole, shift) in expected {
            let offset = camera.offset(for: plane, scale: 6)
            XCTAssertEqual(offset.whole, whole, "\(plane) n")
            XCTAssertEqual(offset.deviceShift, shift, "\(plane) shift")
            XCTAssertEqual(offset.offset, 541.5 * plane.parallax, accuracy: 1e-9, "\(plane) o")
        }
    }

    func testPlaneOffsetRuleEverywhere() {
        for scale in [4, 6, 7, 8] {
            var focus = 0.0
            while focus <= WorldLayout.width {
                let camera = Camera(focusX: focus, viewWidth: 409.7)
                for plane in Plane.allCases {
                    let offset = camera.offset(for: plane, scale: scale)
                    let o = camera.x * plane.parallax
                    XCTAssertEqual(offset.whole, Int(o.rounded(.down)))
                    XCTAssertGreaterThanOrEqual(offset.fraction, 0)
                    XCTAssertLessThan(offset.fraction, 1)
                    XCTAssertEqual(Double(offset.whole) + offset.fraction, o, accuracy: 1e-9)
                    XCTAssertGreaterThanOrEqual(offset.deviceShift, 0)
                    XCTAssertLessThanOrEqual(offset.deviceShift, scale, "the spare column covers a shift of s")
                    XCTAssertLessThanOrEqual(abs(Double(offset.deviceShift) - offset.fraction * Double(scale)), 0.5)
                }
                XCTAssertEqual(camera.offsets(scale: scale).map(\.plane), Plane.allCases)
                focus += 37.3
            }
        }
    }

    func testClampingToTheWorld() {
        XCTAssertEqual(Camera(focusX: 0, viewWidth: 437).x, 0)
        XCTAssertEqual(Camera(focusX: 100, viewWidth: 437).x, 0, "the view never shows left of the world")
        XCTAssertEqual(Camera(focusX: 5000, viewWidth: 437).x, 3900 - 437)
        XCTAssertEqual(Camera(focusX: 3700, viewWidth: 437).maxLeft, 3463)
        XCTAssertEqual(Camera(focusX: 900, viewWidth: 5000).x, 0, "a world narrower than the view stays at 0")
        XCTAssertEqual(Camera(focusX: 1830, viewWidth: 437).focusX, 1830, accuracy: 1e-9)

        var camera = Camera(focusX: 3500, viewWidth: 437)
        var king = KingState(x: 3500, facing: 1, velocity: KingState.runSpeed)
        for _ in 0..<(60 * 10) {
            king.step(dt: dt)
            camera.follow(targetX: king.x, targetVelocity: king.velocity, dt: dt)
            XCTAssertLessThanOrEqual(camera.x, camera.maxLeft + 1e-9)
            XCTAssertGreaterThanOrEqual(camera.x, 0)
        }
        XCTAssertEqual(king.x, WorldLayout.walkEnd, "the king stops on the river bank")
        XCTAssertEqual(camera.x, camera.maxLeft, accuracy: 1e-6)
    }

    func testFollowSettlesOnAStandingKing() {
        var camera = Camera(focusX: 800, viewWidth: 437)
        let king = KingState(x: 1000)
        for _ in 0..<(60 * 3) {
            camera.follow(targetX: king.x, targetVelocity: 0, dt: dt)
        }
        XCTAssertEqual(camera.focusX, 1000, accuracy: 0.5)
        XCTAssertEqual(camera.velocity, 0, accuracy: 1)
    }

    func testReduceMotionHasNoLag() {
        var camera = Camera(focusX: 800, viewWidth: 437)
        camera.follow(targetX: 1000, targetVelocity: 36, dt: dt, reduceMotion: true)
        XCTAssertEqual(camera.focusX, 1000, accuracy: 1e-9)
        camera.jump(toFocus: 2000)
        XCTAssertEqual(camera.focusX, 2000, accuracy: 1e-9)
        XCTAssertEqual(camera.velocity, 0)
    }

    func testKingOnScreenJitterAtMostOneDevicePixel() {
        // iPhone 17 Pro (s = 6) and 17 Pro Max (s = 7); walk and run; both directions.
        let screens: [(Int, Int)] = [(2622, 1206), (2868, 1320)]
        for (width, height) in screens {
            let pixelScale = PixelScale(physicalWidth: width, physicalHeight: height)
            for speed in [KingState.walkSpeed, KingState.runSpeed] {
                for direction in [1.0, -1.0] {
                    let start = direction > 0 ? 800.0 : 2600.0
                    let label = "s \(pixelScale.scale), \(speed) px/s, direction \(direction)"
                    let run = walk(pixelScale: pixelScale, start: start, velocity: speed * direction, mode: .smooth)
                    XCTAssertLessThanOrEqual(run.spread, 1, "\(label): steady on screen")
                    XCTAssertLessThanOrEqual(run.largestStep, 1, "\(label): no frame-to-frame jump")
                    XCTAssertLessThanOrEqual(run.largestError, 1.0 + 1e-9, "\(label): within a pixel of exact")
                    XCTAssertLessThan(run.largestOffCentre, 1, "\(label): the camera keeps him centred")
                }
            }
        }
    }

    func testSnappedActorsShowTheJitterSmoothRemoves() {
        let pixelScale = PixelScale(physicalWidth: 2622, physicalHeight: 1206)
        let run = walk(pixelScale: pixelScale, start: 800, velocity: KingState.walkSpeed, mode: .snapped)
        XCTAssertGreaterThanOrEqual(run.spread, 2, "snapped actors shiver by up to a game pixel")
    }

    func testDeviceXPlacesActorsWithTheWorldPlane() {
        let camera = Camera(focusX: 760, viewWidth: 437)
        // World x 600 on a world plane drawn at n = 541 and shifted left by 3 device pixels.
        XCTAssertEqual(camera.deviceX(worldX: 600, scale: 6, mode: .smooth), (600 - 541) * 6 - 3)
        XCTAssertEqual(camera.deviceX(worldX: 600.4, scale: 6, mode: .smooth), Int((59.4 * 6).rounded()) - 3)
        XCTAssertEqual(camera.deviceX(worldX: 600.4, scale: 6, mode: .snapped), (600 - 541) * 6 - 3)
        XCTAssertEqual(camera.kingScreenX(kingX: 760, scale: 6), 1311, "centre of 2622 device pixels")
        XCTAssertEqual(Camera.groundDeviceY(physicalHeight: 1206, scale: 6), 1206 - 26 * 6)
        XCTAssertEqual(Camera.groundRow(targetHeight: 201), 175)
    }

    // MARK: - Helpers

    private struct WalkResult {
        var spread: Int
        var largestStep: Int
        var largestError: Double
        var largestOffCentre: Double
    }

    /// The king walks from rest at `velocity` while the camera follows: 2 s to get going (the start lag), then 10 s
    /// measured at 60 fps.
    private func walk(pixelScale: PixelScale, start: Double, velocity: Double, mode: ActorMode) -> WalkResult {
        let scale = pixelScale.scale
        var camera = Camera(focusX: start, pixelScale: pixelScale)
        var king = KingState(x: start, facing: velocity > 0 ? 1 : -1, velocity: velocity)
        let settleFrames = 2 * 60
        let measuredFrames = 10 * 60
        var positions: [Int] = []
        var largestStep = 0
        var largestError = 0.0
        var largestOffCentre = 0.0
        for frame in 0..<(settleFrames + measuredFrames) {
            king.step(dt: dt)
            camera.follow(targetX: king.x, targetVelocity: king.velocity, dt: dt)
            guard frame >= settleFrames else { continue }
            let onScreen = camera.kingScreenX(kingX: king.x, scale: scale, mode: mode)
            let exact = (king.x - camera.x) * Double(scale)
            largestError = max(largestError, abs(Double(onScreen) - exact))
            largestOffCentre = max(largestOffCentre, abs(king.x - camera.focusX))
            if let last = positions.last {
                largestStep = max(largestStep, abs(onScreen - last))
            }
            positions.append(onScreen)
        }
        let spread = (positions.max() ?? 0) - (positions.min() ?? 0)
        return WalkResult(spread: spread, largestStep: largestStep, largestError: largestError,
                          largestOffCentre: largestOffCentre)
    }
}
