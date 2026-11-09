import Foundation
import XCTest
@testable import Lanternhold

/// The audience card's portraits (M3 step 3): story characters and guests show their own (Seren hooded until day 15 or
/// `seren_revealed`), townsfolk a portrait composed from the contract's parts by the petitioner's look, its swap ramps
/// replaced colour for colour by the look's target ramps, cut from the atlas (the art lane's PNGs once they land), 48x48.
final class PortraitCardTests: XCTestCase {
    func testStoryCharactersShowTheirOwnPortraitAndTownsfolkAComposedOne() {
        XCTAssertEqual(AudienceCard.portrait(speaker: "odile", look: 3, day: 2, flags: []), .own(.portraitOdile, frame: 0))
        XCTAssertEqual(AudienceCard.portrait(speaker: "seren", look: 3, day: 4, flags: []),
                       .own(.portraitSeren, frame: 0), "hooded at the gate")
        XCTAssertEqual(AudienceCard.portrait(speaker: "seren", look: 3, day: 15, flags: []),
                       .own(.portraitSeren, frame: 1), "revealed on day 15")
        XCTAssertEqual(AudienceCard.portrait(speaker: "seren", look: 3, day: 9, flags: [Speakers.serenRevealedFlag]),
                       .own(.portraitSeren, frame: 1), "or once the flag is set")
        XCTAssertEqual(AudienceCard.portrait(speaker: "herald", look: 3, day: 17, flags: []),
                       .own(.portraitHerald, frame: 0))
        XCTAssertEqual(AudienceCard.portrait(speaker: "serLudo", look: 3, day: 5, flags: []),
                       .own(.portraitSerLudo, frame: 0))
        for speaker in Speakers.townsfolk {
            for look in [0, 7, 12_345, 1 << 30] {
                guard case .composed(let recipe) = AudienceCard.portrait(speaker: speaker.id, look: look, day: 5,
                                                                         flags: []) else {
                    XCTFail("\(speaker.id) gets a composed portrait")
                    continue
                }
                XCTAssertEqual(recipe, Speakers.recipe(speaker.id, look: look), "\(speaker.id): seeded by the look")
            }
        }
    }

    func testTheComposedPortraitWearsItsTargetRampsFromTheAtlas() {
        let ramps: [(swap: [UInt32], target: (PortraitRecipe) -> [UInt32])] = [
            (PortraitRamps.skin, { $0.skin.ramp }), (PortraitRamps.hair, { $0.hairColor.ramp }),
            (PortraitRamps.cloth, { $0.cloth.ramp }),
        ]
        var differentFaces = Set<String>()
        for speaker in Speakers.townsfolk {
            for look in 0..<6 {
                guard let recipe = Speakers.recipe(speaker.id, look: look) else { continue }
                let image = PortraitComposer.compose(recipe, atlas: .shared)
                XCTAssertEqual(image.width, 48)
                XCTAssertEqual(image.height, 48)
                XCTAssertFalse(image.isEmpty, "\(speaker.id) \(look)")
                var colours = Set<RGBA>()
                for y in 0..<image.height {
                    for x in 0..<image.width where image[x, y].a > 0 { colours.insert(image[x, y].alpha(255)) }
                }
                for ramp in ramps where ramp.target(recipe) != ramp.swap {
                    for hex in ramp.swap {
                        XCTAssertFalse(colours.contains(RGBA(hex)),
                                       "\(speaker.id) \(look): swap colour \(String(hex, radix: 16)) replaced")
                    }
                }
                XCTAssertFalse(colours.isDisjoint(with: recipe.skin.ramp.map { RGBA($0) }),
                               "\(speaker.id) \(look): the skin of its look")
                differentFaces.insert(colours.sorted { $0.r == $1.r ? $0.g < $1.g : $0.r < $1.r }.description)
            }
        }
        XCTAssertGreaterThan(differentFaces.count, 20, "petitioners look different")
    }

    @MainActor
    func testTheCardTileGetsThePortraitImage() throws {
        let recipe = try XCTUnwrap(Speakers.recipe("farmer", look: 42))
        let composed = try XCTUnwrap(PortraitImages.image(.composed(recipe)))
        XCTAssertEqual(composed.width, 48)
        XCTAssertEqual(composed.height, 48)
        XCTAssertTrue(PortraitImages.image(.composed(recipe)) === composed, "cached")
        let own = try XCTUnwrap(PortraitImages.image(.own(.portraitSeren, frame: 1)))
        XCTAssertEqual(own.width, 48)
    }
}
