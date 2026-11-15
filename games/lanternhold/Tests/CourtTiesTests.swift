import Foundation
import XCTest
@testable import Lanternhold

/// People-2's fix round 1 (the director's notes of 14.11. 14:35 and 15:03): the lord's own cloak in two states, mended in
/// the hamlet and the village and good in the town, with only cloak pixels changed (`LordCloak`); and the court's ties,
/// one idle of two frames per court member played toward another person (`CourtTies`).
final class CourtTiesTests: XCTestCase {
    private let layout = AtlasLayout.shared

    private func frames(_ sprite: SpriteID) -> [PixelImage] {
        (layout.cells[sprite] ?? []).map { layout.image.cropped(x: $0.x, y: $0.y, width: $0.width, height: $0.height) }
    }

    // MARK: - The lord's cloak

    func testTheLordsCloakIsMendedUntilTheTownAndOnlyTheCloakChanges() {
        XCTAssertEqual(LordCloak.mended.count, 4)
        for (body, twin) in LordCloak.mended {
            XCTAssertEqual(LordCloak.dressed(body, .hamlet), twin, "\(body): mended in the hamlet")
            XCTAssertEqual(LordCloak.dressed(body, .village), twin, "\(body): still mended in the village")
            XCTAssertEqual(LordCloak.dressed(body, .town), body, "\(body): the good cloak in the town")
            XCTAssertEqual(LordCloak.body(of: twin), body)
            XCTAssertEqual(twin.size, body.size, "\(twin) size")
            XCTAssertEqual(twin.frameCount, body.frameCount, "\(twin) frames")
            XCTAssertEqual(layout.sources[twin], .png, "\(twin) is drawn from its painting")
            let a = frames(twin)
            let b = frames(body)
            XCTAssertEqual(a.count, b.count)
            var recoloured = 0
            var opaque = 0
            for (mended, good) in zip(a, b) {
                for y in 0..<mended.height {
                    for x in 0..<mended.width {
                        XCTAssertEqual(mended[x, y].a > 0, good[x, y].a > 0, "\(twin) keeps the lord's shape at \(x),\(y)")
                        if good[x, y].a > 0 { opaque += 1 }
                        if mended[x, y] != good[x, y] { recoloured += 1 }
                    }
                }
            }
            XCTAssertGreaterThan(recoloured, 0, "\(twin) mends the cloak")
            XCTAssertLessThan(Double(recoloured), Double(opaque) * 0.35, "\(twin) changes the cloak, never the lord")
        }
        XCTAssertNil(LordCloak.body(of: .king))
        XCTAssertEqual(LordCloak.dressed(.citizen, .hamlet), .citizen, "nobody else wears the lord's cloak")
    }

    @MainActor
    func testLookTwoPaintsTheLordInHisCloakAndKeepsHimTheLord() {
        let rect = SIMD4<Float>(0, 0, 16, 30)
        let white = SIMD4<Float>(1, 1, 1, 1)
        func actor(_ sprite: SpriteID) -> ActorInstance {
            ActorInstance(sprite: sprite, frame: 2, rect: rect, tint: white, flipped: true, isEmissive: false,
                          isLit: true)
        }
        // Without -GWCloth the realm is a hamlet: look 2 paints the mended cloak; look 1 keeps the lord as he was.
        XCTAssertEqual(PeopleCast.launchCloth, .hamlet)
        for (body, twin) in LordCloak.mended {
            let look2 = Renderer.quad(actor(body), layout: layout, look: .two)
            XCTAssertEqual(look2.texel, layout.cell(twin, frame: 2).texels(flipped: true), "\(body) in the mended cloak")
            XCTAssertGreaterThan(look2.flags.z, 0, "\(body) keeps the lord's cool rim")
            let look1 = Renderer.quad(actor(body), layout: layout, look: .one)
            XCTAssertEqual(look1.texel, layout.cell(body, frame: 2).texels(flipped: true), "look 1 as it was")
        }
        let glow = Renderer.quad(actor(.kingGlow), layout: layout, look: .two)
        XCTAssertEqual(glow.texel, layout.cell(.kingGlow, frame: 2).texels(flipped: true), "the lantern's glow stays")
    }

    // MARK: - The court's ties

    func testEveryCourtMemberHasATieOfTwoFramesInItsOwnBody() {
        let court: [SpriteID] = [.odile, .brannock, .pip, .hesper, .tamsin, .bram, .marek, .seren]
        XCTAssertEqual(Set(CourtTies.sheets.keys), Set(court), "every court member")
        for member in court {
            guard let tie = CourtTies.sheet(for: member) else { XCTFail("\(member) has no tie"); continue }
            XCTAssertEqual(CourtTies.member(of: tie), member)
            XCTAssertEqual(tie.size, member.size, "\(tie) is drawn in \(member)'s body")
            XCTAssertEqual(tie.frameCount, 2)
            XCTAssertEqual(layout.sources[tie], .png, "\(tie) is drawn from its painting")
            let tieFrames = frames(tie)
            let own = frames(member)
            XCTAssertEqual(tieFrames.count, 2)
            XCTAssertNotEqual(tieFrames[0], tieFrames[1], "\(tie): the nod and the thread differ")
            for (index, frame) in tieFrames.enumerated() {
                XCTAssertFalse(own.contains(frame), "\(tie) frame \(index) is new, not one of \(member)'s own")
                let onGround = (0..<frame.width).contains { frame[$0, frame.height - 1].a > 0 }
                    || (0..<frame.width).contains { frame[$0, frame.height - 2].a > 0 }
                XCTAssertTrue(onGround, "\(tie) frame \(index) stands where \(member) stands")
            }
        }
        for (tie, glow) in CourtTies.glows {
            XCTAssertEqual(glow.size, tie.size)
            XCTAssertEqual(glow.frameCount, 2)
            XCTAssertEqual(layout.sources[glow], .png, "\(glow): the light the member carries")
        }
        XCTAssertEqual(CourtTies.all.count, 10)
    }

    func testATieNodsThenHoldsAndReduceMotionHoldsOnly() {
        XCTAssertEqual(CourtTies.frame(since: 0.1, reduceMotion: false), CourtTies.nodFrame)
        XCTAssertEqual(CourtTies.frame(since: CourtTies.nodSeconds + 0.1, reduceMotion: false), CourtTies.threadFrame)
        XCTAssertNil(CourtTies.frame(since: CourtTies.nodSeconds + CourtTies.holdSeconds + 0.01, reduceMotion: false),
                     "back to the member's own idle")
        XCTAssertEqual(CourtTies.frame(since: 0.1, reduceMotion: true), CourtTies.threadFrame, "no nod with Reduce Motion")
        XCTAssertNil(CourtTies.frame(since: -1, reduceMotion: false))
    }
}
