import XCTest
@testable import Lanternhold

/// World rebuild, step world-3 (docs/REVIEW-look-2.md 2.7, `CameraFraming`): the walking lead, the set pieces, the
/// lead toward the danger at night, and Reduce Motion.
final class CameraFramingTests: XCTestCase {
    private let dt = 1.0 / 60.0
    private let view = 437.0

    /// The lord walks at `velocity` from `start` for `seconds` while the camera frames him; returns the camera and the
    /// lord's x.
    private func walk(from start: Double, velocity: Double, seconds: Double, camera given: Camera? = nil,
                      danger: Double = 0, reduceMotion: Bool = false) -> (camera: Camera, lordX: Double) {
        var camera = given ?? Camera(focusX: start, viewWidth: view)
        var lord = KingState(x: start, facing: velocity < 0 ? -1 : 1, velocity: velocity)
        for _ in 0..<Int((seconds / dt).rounded()) {
            lord.step(dt: dt)
            camera.frame(CameraFraming.Input(lordX: lord.x, velocity: lord.velocity, facing: lord.facing,
                                             danger: danger), dt: dt, reduceMotion: reduceMotion)
        }
        return (camera, lord.x)
    }

    func testTheLeadEasesInOverHalfASecondInTheWalkingDirection() {
        // In the open Throat (no set piece between 700 and 1100).
        var camera = Camera(focusX: 760, viewWidth: view)
        var lord = KingState(x: 760, facing: 1, velocity: KingState.walkSpeed)
        var leads: [Double] = []
        for _ in 0..<60 {
            lord.step(dt: dt)
            camera.frame(CameraFraming.Input(lordX: lord.x, velocity: lord.velocity, facing: 1, danger: 0), dt: dt)
            leads.append(camera.lead)
        }
        XCTAssertLessThan(leads[5], CameraFraming.walkLead * 0.4, "eased, not a jump")
        XCTAssertGreaterThan(leads[29], CameraFraming.walkLead * 0.9, "nearly in after half a second")
        XCTAssertEqual(leads[59], CameraFraming.walkLead, accuracy: 0.5)
        for (a, b) in zip(leads, leads.dropFirst()) {
            XCTAssertGreaterThanOrEqual(b, a - 1e-9, "the lead never overshoots back")
            XCTAssertLessThanOrEqual(b, CameraFraming.walkLead + 1e-6)
        }
        // After two seconds of a steady walk he stands the lead behind the screen's centre, steady.
        let settled = walk(from: 700, velocity: KingState.walkSpeed, seconds: 2.5)
        XCTAssertEqual(settled.camera.focusX - settled.lordX, CameraFraming.walkLead, accuracy: 0.5)
        let left = walk(from: 1100, velocity: -KingState.walkSpeed, seconds: 2.5)
        XCTAssertEqual(left.camera.focusX - left.lordX, -CameraFraming.walkLead, accuracy: 0.5, "walking left")
    }

    func testTheLeadStaysWhenHeStopsAndIsClearedByAJump() {
        let walked = walk(from: 760, velocity: KingState.walkSpeed, seconds: 2)
        var camera = walked.camera
        for _ in 0..<180 {
            camera.frame(CameraFraming.Input(lordX: walked.lordX, velocity: 0, facing: 1, danger: 0), dt: dt)
        }
        XCTAssertEqual(camera.focusX - walked.lordX, CameraFraming.walkLead, accuracy: 0.5,
                       "a stop never slides the picture back")
        camera.reframe(CameraFraming.Input(lordX: 900, velocity: 0, facing: 1, danger: 0))
        XCTAssertEqual(camera.lead, 0)
        XCTAssertEqual(camera.focusX, 900, accuracy: 1e-9)
        // A lord who never walked stands at the centre (the sweep's stills).
        var still = Camera(focusX: 900, viewWidth: view)
        for _ in 0..<120 {
            still.frame(CameraFraming.Input(lordX: 900, velocity: 0, facing: -1, danger: 0), dt: dt)
        }
        XCTAssertEqual(still.focusX, 900, accuracy: 1e-6)
    }

    func testTheSetPiecesComposeTheirBuilding() {
        XCTAssertEqual(CameraFraming.setPieces, [470, 1360, 1830, 2330])
        for anchor in CameraFraming.setPieces {
            for offset in stride(from: -70.0, through: 70.0, by: 14) {
                let lordX = anchor + offset
                var camera = Camera(focusX: lordX, viewWidth: view)
                for _ in 0..<240 {
                    camera.frame(CameraFraming.Input(lordX: lordX, velocity: 0, facing: 1, danger: 0), dt: dt)
                }
                XCTAssertEqual(camera.focusX, anchor + offset * 0.3, accuracy: 0.5, "set piece \(anchor), \(offset)")
                // With the lead in: the set piece still holds it.
                XCTAssertEqual(CameraFraming.goal(lordX: lordX, lead: 32, danger: 0), anchor + offset * 0.3,
                               accuracy: 1e-9)
            }
            XCTAssertEqual(CameraFraming.goal(lordX: anchor + 250, lead: 32, danger: 0), anchor + 282,
                           accuracy: 1e-9, "beyond the release only the lead")
        }
        XCTAssertNil(CameraFraming.setPiece(lordX: 900), "the open Throat has none")
        XCTAssertNil(CameraFraming.setPiece(lordX: 3000), "the town has none")
    }

    func testTheGoalNeverJumps() {
        for lead in [-32.0, 0, 32] {
            for danger in [0.0, 0.5, 1] {
                var x = 0.0
                var last = CameraFraming.goal(lordX: x, lead: lead, danger: danger)
                while x < WorldLayout.walkEnd {
                    x += 0.5
                    let next = CameraFraming.goal(lordX: x, lead: lead, danger: danger)
                    XCTAssertLessThan(abs(next - last), 0.5 * 2.6, "at \(x), lead \(lead), danger \(danger)")
                    last = next
                }
            }
        }
    }

    func testWalkingThroughTheFrontGateKeepsTheLordOnScreenAndTheCameraSmooth() {
        var camera = Camera(focusX: 1050, viewWidth: view)
        var lord = KingState(x: 1050, facing: 1, velocity: KingState.walkSpeed)
        var lastX = camera.x
        var fastest = 0.0
        for frame in 0..<(60 * 20) {
            lord.step(dt: dt)
            camera.frame(CameraFraming.Input(lordX: lord.x, velocity: lord.velocity, facing: 1, danger: 0), dt: dt)
            // (the first second is the lead's own half-second ease)
            if frame >= 60 { fastest = max(fastest, abs(camera.x - lastX) / dt) }
            lastX = camera.x
            XCTAssertLessThan(abs(lord.x - camera.focusX), view / 2 - 60, "he stays well inside the screen")
        }
        XCTAssertLessThan(fastest, KingState.walkSpeed * 2.6, "the camera never races")
        XCTAssertGreaterThan(lord.x, 1700)
    }

    func testTheCameraLeadsTowardTheDangerAtNightWhileCreaturesAreOnScreen() {
        var s = GameState.newRealm(seed: 6)
        s.king.x = 900
        s.hour = 22
        let camera = Camera(focusX: 900, viewWidth: view)
        XCTAssertEqual(CameraFraming.input(s, camera: camera).danger, 0, "no creature on screen: no danger lead")
        s.creatures = [Creature(id: 1, kind: .sootling, x: 760, hp: 10, maxHP: 10)]
        XCTAssertEqual(CameraFraming.input(s, camera: camera).danger, 1)
        // Eased in: about a second to most of the way, settled at 60 px to the left.
        var framed = camera
        var shares: [Double] = []
        for _ in 0..<240 {
            framed.frame(CameraFraming.input(s, camera: framed), dt: dt)
            shares.append(framed.danger)
        }
        XCTAssertLessThan(shares[6], 0.2, "eased, not a jump")
        XCTAssertGreaterThan(shares[89], 0.9)
        XCTAssertEqual(framed.focusX, 900 - CameraFraming.dangerLead, accuracy: 0.5)
        // A creature far off screen does not count; by day there is no danger lead; inside the castle none either.
        s.creatures = [Creature(id: 2, kind: .sootling, x: 300, hp: 10, maxHP: 10)]
        XCTAssertEqual(CameraFraming.input(s, camera: camera).danger, 0)
        s.creatures = [Creature(id: 3, kind: .sootling, x: 760, hp: 10, maxHP: 10)]
        s.hour = 12
        XCTAssertEqual(CameraFraming.input(s, camera: camera).danger, 0)
        s.hour = 22
        s.king.x = 1824
        let inside = Camera(focusX: 1824, viewWidth: view)
        s.creatures = [Creature(id: 4, kind: .sootling, x: 1700, hp: 10, maxHP: 10)]
        XCTAssertEqual(CameraFraming.input(s, camera: inside).danger, 0)
        // The danger lead replaces the set piece at the front gate's edge.
        XCTAssertEqual(CameraFraming.goal(lordX: 1290, lead: 32, danger: 1), 1290 - 60, accuracy: 1e-9)
    }

    func testReduceMotionMakesTheLeadAndTheSetPiecesInstant() {
        var camera = Camera(focusX: 760, viewWidth: view)
        camera.frame(CameraFraming.Input(lordX: 761, velocity: KingState.walkSpeed, facing: 1, danger: 0), dt: dt,
                     reduceMotion: true)
        XCTAssertEqual(camera.lead, CameraFraming.walkLead, "no ease")
        XCTAssertEqual(camera.focusX, 761 + CameraFraming.walkLead, accuracy: 1e-9)
        camera.frame(CameraFraming.Input(lordX: 1380, velocity: KingState.walkSpeed, facing: 1, danger: 0), dt: dt,
                     reduceMotion: true)
        XCTAssertEqual(camera.focusX, 1360 + 20 * 0.3, accuracy: 1e-9, "the set piece at once")
        camera.frame(CameraFraming.Input(lordX: 900, velocity: 0, facing: 1, danger: 1), dt: dt, reduceMotion: true)
        XCTAssertEqual(camera.danger, 1)
        XCTAssertEqual(camera.focusX, 900 - CameraFraming.dangerLead, accuracy: 1e-9)
    }

    func testTheWorldEndsStillClampTheFraming() {
        let river = walk(from: 3600, velocity: KingState.runSpeed, seconds: 6)
        XCTAssertEqual(river.camera.x, river.camera.maxLeft, accuracy: 1e-6, "the river end clamps")
        let bank = walk(from: 300, velocity: -KingState.runSpeed, seconds: 6)
        XCTAssertEqual(bank.camera.x, 0, accuracy: 1e-6, "the bank end clamps")
    }
}
