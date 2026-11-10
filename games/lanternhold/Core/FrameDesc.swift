/// A sprite's size in game pixels.
struct PixelSize: Sendable, Equatable {
    let width: Int
    let height: Int
}

/// Every sprite of the world (milestone M1b). The painted ones come from `Resources/Art/<name>.png` at exactly `size`;
/// the procedural placeholder atlas draws a stand-in for any PNG that is missing, one cell per id and frame, so quads
/// never stretch texels (long things such as the ground, the gorge wall, the valley panoramas and walls are tiled).
enum SpriteID: String, Sendable, CaseIterable, Equatable {
    // Sky (emissive)
    case moon, sun, starField
    // Clouds plane (parallax 0.05)
    case cloudA, cloudB, cloudC
    // Far plane
    case farMountain, valleyFarA, valleyFarB, valleyFarC
    // Mid plane: the gorge's far wall, the warden statue, the gorge mouth; the valley's hills, windmill and far shore
    case gorgeWallA, gorgeWallB, gorgeWallC, gorgeWallHigh, wardenStatue, gorgeMouth
    case valleyMidA, valleyMidB, valleyMidC, windmill, riverFarBank, keepFar
    // Fog planes
    case fogStrip
    // World plane
    case ground, groundB, groundC, groundD, darknessBank, darknessEdge
    case beaconRuin, palisade, stoneWall, torchPost, brazier, ballista
    case cliffFlank, cliffFlankB, throatRock, castleKeep, keepTop, castleFront, castleWall, hallInterior, throne, hearth, candleStand, chapel, kitchen
    case castleBackGate, house, houseB, houseC, lanternPost, field, well, riverEnd
    // Scene polish 2: the castle's baked cast shadows (day and the long dusk shadow) and the mist at its foot
    case castleShadow, castleShadowLong, groundShadow, groundShadowLong, gateShadow, gateShadowLong, castleMist
    // Emissive parts
    case flame, brazierFlame, hearthFire, candleFlame, windowGlow, lanternGlass, eyeGlints
    // Actors
    case king, sootling, shadehound, archer, citizen
    // Foreground plane
    case fgRockA, fgRockB, fgRockC, fgOverhangA, fgOverhangB
    // M2b (SPRITES.md): the people of the realm
    case kingGlow, citizenB, citizenC, guardsman, builder
    // The creatures of the Gloom and their glow strips
    case sootlingB, sootCrow, ashBrute, gloomweaver, ashGiant, lightlessKing
    case sootlingGlow, sootlingBGlow, shadehoundGlow, sootCrowGlow, ashBruteGlow, gloomweaverGlow, ashGiantGlow,
         lightlessKingGlow
    // Buildings, overlays and the beacon
    case bastion, rubbleWood, rubbleStone, scaffold, gateWood, gateIron, gateGreat, gateBroken
    case archerTower, watchtower, fireTower, catapult, stakePit
    case beaconBase, beaconTower, greatBeacon, beaconFire
    case barracks, smithy, masterSmithy, lodge, bigLodge, bigHouse, market, tavern, plotMarker
    // Projectiles
    case arrow, fireArrow, bolt, firepot
    // Effects (procedural only, not in the art contract): sparks, soot shards, the darkness of the Lightless King's
    // aura and the gloomweavers' bubbles, arrow trails
    case spark, shard, gloomBubble, streak
    // M3 (SPRITES.md "M3"): the court and the guests (walk 0-3, idle 4-5, talk 6-7), two petitioner bodies (walk
    // 0-3, idle 4-5) and three glow strips
    case odile, brannock, pip, hesper, tamsin, bram, marek, seren, serLudo, bard, envoy, herald
    case petitionerD, petitionerE
    case hesperGlow, serenGlow, heraldGlow
    // The audience card's portraits (48x48): story and guest portraits, and the composed portrait's parts
    case portraitOdile, portraitBrannock, portraitPip, portraitHesper, portraitTamsin, portraitBram, portraitMarek,
         portraitSeren, portraitSerLudo, portraitBard, portraitEnvoy, portraitHerald, portraitKing
    case portraitClothes, portraitFace, portraitBeard, portraitHair, portraitHat
    // The castle's rooms (cut-away) and the court's props
    case hallFront, chapelInterior, kitchenInterior
    case bench, taxLectern, marekCart, statue, speakerMark
    // M3 step 3: the castle's world changes that have no sprite in the art contract (procedural only, like the
    // effects): the hall's renewed banners, the tapestry of Aldric, Seren's grey lantern, the votive candles before
    // the chapel's altar, the empty belfry where the bell hung
    case hallBanner, tapestry, serenLantern, votiveCandles, bellGone
    // Look 2's weather (docs/PORT-look2.md 3): the rain's streaks (nine frames: three depths by three slants) and
    // the splash on the lane (three frames), painted in code until the art lane brings them
    case rainStreak, rainSplash
    // Look 2 (SPRITES.md "Look 2: the world", ART-look2.md 13.1). Far plane: the Weltmauer with the far castle in its
    // slot, the patch that hides the baked castle from the valley, and the slot's lights
    case weltmauer, weltmauerPatch, farCastleGlow, farCastlePane, farCleftGlow, farCleftGlowBack
    // Far and mid: the fir belt, the shadow land's forest, the Throat's rock, the cleft's faces, the valley
    case d2FirBeltFar, shadowForest, gorgeRock, cleftFace, cleftFaceEnd, valleyVista, d2TreeBelt
    // Near plane (0.75): the Throat's crags and the trees of both lands
    case gorgeCrags, firA, firB, firC, firD, deadTreeA, deadTreeB, linden, poplar, appleTree, willow
    // World plane: the cleft's flanks at the castle, bushes, the lane's end and the four lanes (variants A to D)
    case cleftFlank, cleftFlankB, cleftThroat, d2BushA, d2BushB, d2LaneEnd
    case laneMoorA, laneMoorB, laneMoorC, laneMoorD, laneScreeA, laneScreeB, laneScreeC, laneScreeD
    case laneCobbleA, laneCobbleB, laneCobbleC, laneCobbleD, laneEarthA, laneEarthB, laneEarthC, laneEarthD
    // Foreground plane
    case d2FgFerns, d2FgMeadow, d2FgReeds
    // White alpha masks the engine colours (fog banks, the mist band, chimney smoke) and additive effects
    case d2FogBank, d2MistBand, d2FogLow, d2Smoke, d2Fireflies, d2Sparks
    // The darkness bank's emissive strip (4 frames, ART-look2.md 11.5)
    case darknessBankGlow
    // The castle's tiers 2 and 3 and their building states (SPRITES.md "The castle grows"; drawing only)
    case keepTop2, keepTop2Build, keepTop3, keepTop3Build, castleFront3, castleFront3Build, castleFrontScaffold
    case backTop2, backTop2Build, backTop3, backTop3Build
    case farCastle2, farCastle2Build, farCastle3, farCastle3Build
    case farCastleBack2, farCastleBack2Build, farCastleBack3, farCastleBack3Build
    case farCastle2Glow, farCastle3Glow, farCastleBack2Glow, farCastleBack3Glow
    case farCleftGlow2, farCleftGlow2Build, farCleftGlow3, farCleftGlow3Build
    case farCleftGlowBack2, farCleftGlowBack2Build, farCleftGlowBack3, farCleftGlowBack3Build
    // The lord pass (SPRITES.md "The lord pass"): the Burgherrin (the Burgherr's frames) and her glow strip, the lord
    // seated on the throne (sit down 0-1, seated idle 2-3) with the glow strips, her portrait, and the three
    // townsfolk seated on a petitioners' bench (seated 0, a nod 1)
    case lady, ladyGlow, kingSeated, kingSeatedGlow, ladySeated, ladySeatedGlow, portraitLady
    case citizenSeated, citizenBSeated, citizenCSeated
    // Round 2 joined (SPRITES.md "The town at night", "Two more paintings of every town tree"; look 2 only): a
    // house's lit rooms, an emissive sprite of the house's size drawn over it at night in place of its glass masks,
    // and the second and third painting of each town tree on the first one's canvas
    case houseLit, houseBLit, houseCLit, bigHouseLit, tavernLit
    case lindenB, lindenC, poplarB, poplarC, appleTreeB, appleTreeC, willowB, willowC

    /// Size of one frame in game pixels: the painted sprites' PNG sizes (ART.md), the procedural ones as DESIGN.md
    /// "Pixel scale" (king 30, palisade 34, stone wall 52, castle front 236, cliffs above the screen).
    var size: PixelSize {
        switch self {
        case .moon: return PixelSize(width: 14, height: 14)
        case .sun: return PixelSize(width: 18, height: 18)
        case .starField: return PixelSize(width: 128, height: 64)
        case .cloudA: return PixelSize(width: 280, height: 40)
        case .cloudB: return PixelSize(width: 240, height: 42)
        case .cloudC: return PixelSize(width: 286, height: 36)
        case .farMountain: return PixelSize(width: 160, height: 70)
        case .valleyFarA: return PixelSize(width: 192, height: 90)
        case .valleyFarB: return PixelSize(width: 192, height: 90)
        case .valleyFarC: return PixelSize(width: 192, height: 90)
        case .gorgeWallA: return PixelSize(width: 192, height: 190)
        case .gorgeWallB: return PixelSize(width: 192, height: 190)
        case .gorgeWallC: return PixelSize(width: 192, height: 190)
        case .gorgeWallHigh: return PixelSize(width: 192, height: 240)
        case .wardenStatue: return PixelSize(width: 96, height: 200)
        case .gorgeMouth: return PixelSize(width: 120, height: 230)
        case .valleyMidA: return PixelSize(width: 192, height: 110)
        case .valleyMidB: return PixelSize(width: 192, height: 110)
        case .valleyMidC: return PixelSize(width: 192, height: 110)
        case .windmill: return PixelSize(width: 40, height: 60)
        case .riverFarBank: return PixelSize(width: 240, height: 30)
        case .keepFar: return PixelSize(width: 98, height: 237)
        case .fogStrip: return PixelSize(width: 128, height: 24)
        case .ground, .groundB, .groundC, .groundD: return PixelSize(width: 64, height: 26)
        case .darknessBank: return PixelSize(width: 64, height: 236)
        case .darknessEdge: return PixelSize(width: 32, height: 236)
        case .beaconRuin: return PixelSize(width: 64, height: 130)
        case .palisade: return PixelSize(width: 20, height: 34)
        case .stoneWall: return PixelSize(width: 36, height: 52)
        case .torchPost: return PixelSize(width: 4, height: 14)
        case .brazier: return PixelSize(width: 10, height: 14)
        case .ballista: return PixelSize(width: 28, height: 16)
        case .cliffFlank, .cliffFlankB: return PixelSize(width: 80, height: 240)
        case .throatRock: return PixelSize(width: 192, height: 240)
        case .castleKeep: return PixelSize(width: 150, height: 250)
        case .keepTop: return PixelSize(width: 150, height: 130)
        case .castleFront: return PixelSize(width: 240, height: 236)
        case .castleWall: return PixelSize(width: 40, height: 90)
        case .hallInterior: return PixelSize(width: 260, height: 90)
        case .throne: return PixelSize(width: 14, height: 24)
        case .hearth: return PixelSize(width: 26, height: 20)
        case .candleStand: return PixelSize(width: 4, height: 16)
        case .chapel: return PixelSize(width: 160, height: 96)
        case .kitchen: return PixelSize(width: 120, height: 80)
        case .castleBackGate: return PixelSize(width: 200, height: 200)
        case .house, .houseB, .houseC: return PixelSize(width: 64, height: 46)
        case .lanternPost: return PixelSize(width: 6, height: 24)
        case .field: return PixelSize(width: 80, height: 8)
        case .well: return PixelSize(width: 18, height: 20)
        case .riverEnd: return PixelSize(width: 220, height: 64)
        case .castleShadow: return PixelSize(width: 13, height: 171)
        case .castleShadowLong: return PixelSize(width: 90, height: 172)
        case .groundShadow: return PixelSize(width: 240, height: 6)
        case .groundShadowLong: return PixelSize(width: 80, height: 3)
        case .gateShadow: return PixelSize(width: 9, height: 126)
        case .gateShadowLong: return PixelSize(width: 21, height: 153)
        case .castleMist: return PixelSize(width: 300, height: 34)
        case .flame: return PixelSize(width: 4, height: 5)
        case .brazierFlame: return PixelSize(width: 8, height: 7)
        case .hearthFire: return PixelSize(width: 16, height: 10)
        case .candleFlame: return PixelSize(width: 2, height: 3)
        case .windowGlow: return PixelSize(width: 6, height: 8)
        case .lanternGlass: return PixelSize(width: 4, height: 4)
        case .eyeGlints: return PixelSize(width: 5, height: 1)
        case .king: return PixelSize(width: 16, height: 30)
        case .sootling: return PixelSize(width: 14, height: 14)
        case .shadehound: return PixelSize(width: 22, height: 14)
        case .archer: return PixelSize(width: 12, height: 28)
        case .citizen: return PixelSize(width: 12, height: 26)
        case .fgRockA: return PixelSize(width: 96, height: 36)
        case .fgRockB: return PixelSize(width: 96, height: 36)
        case .fgRockC: return PixelSize(width: 96, height: 36)
        case .fgOverhangA: return PixelSize(width: 128, height: 48)
        case .fgOverhangB: return PixelSize(width: 128, height: 48)
        case .kingGlow: return PixelSize(width: 16, height: 30)
        case .citizenB, .citizenC: return PixelSize(width: 12, height: 26)
        case .guardsman: return PixelSize(width: 14, height: 28)
        case .builder: return PixelSize(width: 12, height: 24)
        case .sootlingB, .sootlingGlow, .sootlingBGlow: return PixelSize(width: 14, height: 14)
        case .shadehoundGlow: return PixelSize(width: 22, height: 14)
        case .sootCrow, .sootCrowGlow: return PixelSize(width: 12, height: 10)
        case .ashBrute, .ashBruteGlow: return PixelSize(width: 44, height: 44)
        case .gloomweaver, .gloomweaverGlow: return PixelSize(width: 30, height: 30)
        case .ashGiant, .ashGiantGlow: return PixelSize(width: 110, height: 110)
        case .lightlessKing, .lightlessKingGlow: return PixelSize(width: 64, height: 64)
        case .bastion: return PixelSize(width: 44, height: 64)
        case .rubbleWood: return PixelSize(width: 24, height: 10)
        case .rubbleStone: return PixelSize(width: 40, height: 14)
        case .scaffold: return PixelSize(width: 24, height: 40)
        case .gateWood, .gateIron, .gateGreat: return PixelSize(width: 46, height: 60)
        case .gateBroken: return PixelSize(width: 46, height: 20)
        case .archerTower: return PixelSize(width: 20, height: 48)
        case .watchtower: return PixelSize(width: 24, height: 64)
        case .fireTower: return PixelSize(width: 14, height: 40)
        case .catapult: return PixelSize(width: 32, height: 24)
        case .stakePit: return PixelSize(width: 24, height: 8)
        case .beaconBase, .beaconTower, .greatBeacon: return PixelSize(width: 64, height: 130)
        case .beaconFire: return PixelSize(width: 48, height: 32)
        case .barracks: return PixelSize(width: 64, height: 48)
        case .smithy: return PixelSize(width: 60, height: 48)
        case .masterSmithy: return PixelSize(width: 60, height: 56)
        case .lodge: return PixelSize(width: 56, height: 44)
        case .bigLodge: return PixelSize(width: 64, height: 52)
        case .bigHouse: return PixelSize(width: 72, height: 56)
        case .market: return PixelSize(width: 90, height: 40)
        case .tavern: return PixelSize(width: 90, height: 56)
        case .plotMarker: return PixelSize(width: 12, height: 22)
        case .arrow, .fireArrow: return PixelSize(width: 7, height: 5)
        case .bolt: return PixelSize(width: 11, height: 5)
        case .firepot: return PixelSize(width: 5, height: 5)
        case .spark: return PixelSize(width: 5, height: 5)
        case .shard: return PixelSize(width: 4, height: 4)
        case .gloomBubble: return PixelSize(width: 96, height: 64)
        case .streak: return PixelSize(width: 18, height: 6)
        case .odile, .hesper, .marek, .seren, .envoy, .herald, .hesperGlow, .serenGlow, .heraldGlow:
            return PixelSize(width: 14, height: 30)
        case .brannock, .bram, .serLudo: return PixelSize(width: 16, height: 30)
        case .pip: return PixelSize(width: 12, height: 22)
        case .tamsin: return PixelSize(width: 14, height: 28)
        case .bard: return PixelSize(width: 12, height: 28)
        case .petitionerD, .petitionerE: return PixelSize(width: 12, height: 26)
        case .portraitOdile, .portraitBrannock, .portraitPip, .portraitHesper, .portraitTamsin, .portraitBram,
             .portraitMarek, .portraitSeren, .portraitSerLudo, .portraitBard, .portraitEnvoy, .portraitHerald,
             .portraitKing, .portraitClothes, .portraitFace, .portraitBeard, .portraitHair, .portraitHat:
            return PixelSize(width: 48, height: 48)
        case .hallFront: return PixelSize(width: 260, height: 90)
        case .chapelInterior: return PixelSize(width: 160, height: 96)
        case .kitchenInterior: return PixelSize(width: 120, height: 80)
        case .bench: return PixelSize(width: 32, height: 10)
        case .taxLectern: return PixelSize(width: 12, height: 20)
        case .marekCart: return PixelSize(width: 48, height: 30)
        case .statue: return PixelSize(width: 20, height: 40)
        case .speakerMark: return PixelSize(width: 7, height: 7)
        case .hallBanner: return PixelSize(width: 18, height: 37)
        case .tapestry: return PixelSize(width: 18, height: 22)
        case .serenLantern: return PixelSize(width: 7, height: 16)
        case .votiveCandles: return PixelSize(width: 14, height: 6)
        case .bellGone: return PixelSize(width: 7, height: 8)
        case .rainStreak: return PixelSize(width: 7, height: 11)
        case .rainSplash: return PixelSize(width: 5, height: 3)
        case .weltmauer: return PixelSize(width: 888, height: 190)
        case .weltmauerPatch: return PixelSize(width: 52, height: 190)
        case .farCastleGlow, .farCastlePane: return PixelSize(width: 40, height: 46)
        case .farCleftGlow, .farCleftGlow2, .farCleftGlow2Build, .farCleftGlow3, .farCleftGlow3Build:
            return PixelSize(width: 44, height: 72)
        case .farCleftGlowBack, .farCleftGlowBack2, .farCleftGlowBack2Build, .farCleftGlowBack3,
             .farCleftGlowBack3Build:
            return PixelSize(width: 44, height: 68)
        case .d2FirBeltFar: return PixelSize(width: 520, height: 40)
        case .shadowForest: return PixelSize(width: 224, height: 104)
        case .gorgeRock: return PixelSize(width: 448, height: 211)
        case .cleftFace: return PixelSize(width: 448, height: 218)
        case .cleftFaceEnd: return PixelSize(width: 240, height: 218)
        case .valleyVista: return PixelSize(width: 448, height: 160)
        case .d2TreeBelt: return PixelSize(width: 520, height: 58)
        case .gorgeCrags: return PixelSize(width: 160, height: 200)
        case .firA: return PixelSize(width: 29, height: 130)
        case .firB: return PixelSize(width: 30, height: 118)
        case .firC: return PixelSize(width: 34, height: 106)
        case .firD: return PixelSize(width: 27, height: 84)
        case .deadTreeA: return PixelSize(width: 17, height: 72)
        case .deadTreeB: return PixelSize(width: 17, height: 70)
        case .linden: return PixelSize(width: 52, height: 92)
        case .poplar: return PixelSize(width: 14, height: 116)
        case .appleTree: return PixelSize(width: 42, height: 48)
        case .willow: return PixelSize(width: 52, height: 68)
        case .cleftFlank, .cleftFlankB: return PixelSize(width: 80, height: 240)
        case .cleftThroat: return PixelSize(width: 192, height: 240)
        case .d2BushA: return PixelSize(width: 30, height: 15)
        case .d2BushB: return PixelSize(width: 22, height: 12)
        case .d2LaneEnd: return PixelSize(width: 48, height: 30)
        case .laneMoorA, .laneMoorB, .laneMoorC, .laneMoorD, .laneScreeA, .laneScreeB, .laneScreeC, .laneScreeD,
             .laneCobbleA, .laneCobbleB, .laneCobbleC, .laneCobbleD, .laneEarthA, .laneEarthB, .laneEarthC,
             .laneEarthD:
            return PixelSize(width: 64, height: 26)
        case .d2FgFerns: return PixelSize(width: 480, height: 64)
        case .d2FgMeadow: return PixelSize(width: 480, height: 58)
        case .d2FgReeds: return PixelSize(width: 160, height: 40)
        case .d2FogBank: return PixelSize(width: 384, height: 40)
        case .d2MistBand: return PixelSize(width: 448, height: 60)
        case .d2FogLow: return PixelSize(width: 320, height: 24)
        case .d2Smoke: return PixelSize(width: 26, height: 50)
        case .d2Fireflies: return PixelSize(width: 96, height: 30)
        case .d2Sparks: return PixelSize(width: 14, height: 24)
        case .darknessBankGlow: return PixelSize(width: 64, height: 236)
        case .keepTop2, .keepTop2Build, .keepTop3, .keepTop3Build: return PixelSize(width: 150, height: 140)
        case .castleFront3, .castleFront3Build: return PixelSize(width: 268, height: 236)
        case .castleFrontScaffold: return PixelSize(width: 240, height: 236)
        case .backTop2, .backTop2Build, .backTop3, .backTop3Build: return PixelSize(width: 100, height: 140)
        case .farCastle2, .farCastle2Build, .farCastle3, .farCastle3Build, .farCastleBack2, .farCastleBack2Build,
             .farCastleBack3, .farCastleBack3Build, .farCastle2Glow, .farCastle3Glow, .farCastleBack2Glow,
             .farCastleBack3Glow:
            return PixelSize(width: 48, height: 48)
        case .lady, .ladyGlow, .kingSeated, .kingSeatedGlow, .ladySeated, .ladySeatedGlow:
            return PixelSize(width: 16, height: 30)
        case .portraitLady: return PixelSize(width: 48, height: 48)
        case .citizenSeated, .citizenBSeated, .citizenCSeated: return PixelSize(width: 12, height: 22)
        case .houseLit, .houseBLit, .houseCLit: return PixelSize(width: 64, height: 46)
        case .bigHouseLit: return PixelSize(width: 72, height: 56)
        case .tavernLit: return PixelSize(width: 90, height: 56)
        case .lindenB, .lindenC: return PixelSize(width: 52, height: 92)
        case .poplarB, .poplarC: return PixelSize(width: 14, height: 116)
        case .appleTreeB, .appleTreeC: return PixelSize(width: 42, height: 48)
        case .willowB, .willowC: return PixelSize(width: 52, height: 68)
        }
    }

    /// The court and the guests of M3 and their glow strips: 8 frames each (walk 0 ... 3, idle 4 ... 5, talk 6 ... 7).
    var isCourtBody: Bool {
        switch self {
        case .odile, .brannock, .pip, .hesper, .tamsin, .bram, .marek, .seren, .serLudo, .bard, .envoy, .herald,
             .hesperGlow, .serenGlow, .heraldGlow:
            return true
        default:
            return false
        }
    }

    /// The composed portrait's parts whose frame 0 means "none" (SPRITES.md "M3": frame 0 of beard, hair and hat is
    /// empty); the composer skips that frame.
    var hasEmptyFirstFrame: Bool {
        self == .portraitBeard || self == .portraitHair || self == .portraitHat
    }

    /// Frames in the atlas, one row left to right (SPRITES.md): the king walk 0 ... 5, idle 6 ... 7, command 8 ... 9;
    /// townsfolk walk 0 ... 3, idle 4 ... 5; the archer idle 0 ... 1, draw 2 ... 3, loose 4; the guardsman idle 0 ... 1,
    /// walk 2 ... 5, strike 6 ... 8; the builder walk 0 ... 3, hammer 4 ... 5; creatures walk 0 ... 3 and attack from 4
    /// (the crow flies 0 ... 2 and perches 3, the gloomweaver floats 0 ... 3); a glow strip has its body's frames;
    /// walls whole 0 and damaged 1; gates closed 0, closed damaged 1, open 2; projectiles rising 0, flat 1, falling 2.
    var frameCount: Int {
        if isCourtBody { return 8 }
        switch self {
        case .petitionerD, .petitionerE: return 6
        case .portraitSeren, .speakerMark: return 2
        case .portraitClothes, .portraitHair, .portraitHat: return 8
        case .portraitFace, .portraitBeard: return 6
        case .king, .kingGlow, .lady, .ladyGlow: return 10
        case .kingSeated, .kingSeatedGlow, .ladySeated, .ladySeatedGlow: return 4
        case .citizenSeated, .citizenBSeated, .citizenCSeated: return 2
        case .guardsman: return 9
        case .ashBrute, .ashBruteGlow, .ashGiant, .ashGiantGlow, .lightlessKing, .lightlessKingGlow: return 7
        case .sootling, .sootlingB, .sootlingGlow, .sootlingBGlow, .shadehound, .shadehoundGlow: return 6
        case .citizen, .citizenB, .citizenC, .builder: return 6
        case .archer: return 5
        case .sootCrow, .sootCrowGlow, .gloomweaver, .gloomweaverGlow: return 4
        case .beaconFire, .darknessBankGlow: return 4
        case .gateWood, .gateIron, .gateGreat, .catapult: return 3
        case .arrow, .fireArrow, .bolt, .spark, .streak, .rainSplash: return 3
        case .rainStreak: return 9
        case .palisade, .stoneWall, .bastion, .ballista, .stakePit, .firepot, .shard: return 2
        default: return 1
        }
    }
}

/// Light falloff style (`-GWLightStyle`).
enum LightStyle: String, Sendable, CaseIterable, Equatable {
    case smooth, banded, dithered
}

/// Effect level (`-GWEffects`).
enum EffectLevel: String, Sendable, CaseIterable, Equatable {
    case all, nobloom, nofog, minimal

    var bloom: Bool { self == .all || self == .nofog }
    var fog: Bool { self == .all || self == .nobloom }
}

/// How a frame is built: the light lab and debug arguments of DESIGN.md "Debug launch arguments".
struct FrameOptions: Sendable, Equatable {
    var lightStyle: LightStyle = .smooth
    var effects: EffectLevel = .all
    var actorMode: ActorMode = .smooth
    var reduceMotion = false
    /// Target game rows of the scale rule (180, or 135 for the chunkier look).
    var virtualHeight = 180
    /// Forces device pixels per game pixel.
    var scaleOverride: Int?
    /// Fixes the flicker and idle animation time (`-GWFlickerTime`); nil uses the clock's elapsed time.
    var flickerTime: Double?
    /// Light radius rings and ids (`-GWDebugLights`).
    var debugLights = false
    /// The look (`-GWLook 1|2`). The options' own default is look 1, so the tests that build frames without the
    /// app's arguments keep the picture they were written for; the app's default is `LookVersion.standard`.
    var look: LookVersion = .one
    /// Look 2's weather at this moment (`Weather.sample`); look 1 never reads it. Clear by default, so a frame
    /// built without the game's weather is the frame it was.
    var weather: WeatherSample = .clear
    /// Look 2: tonight's fog out of the Gloom (`GloomFog`, "Polish after round 2"); look 1 never reads it. None by
    /// default, so a frame built without the game's night is the frame it was.
    var gloom: GloomFog? = nil

    /// The pixel scale these options give on a screen.
    func pixelScale(physicalWidth: Int, physicalHeight: Int) -> PixelScale {
        PixelScale(physicalWidth: physicalWidth, physicalHeight: physicalHeight,
                   virtualHeight: virtualHeight, override: scaleOverride)
    }
}

/// One textured quad of a plane, in render-target pixels of that plane (origin top-left, whole pixels). Shaped like
/// `QuadInstance`: the renderer turns `sprite` and `frame` into the atlas `uv`.
struct SpriteInstance: Sendable, Equatable {
    var sprite: SpriteID
    var frame: Int
    /// x, y, width, height in target pixels.
    var rect: SIMD4<Float>
    /// Multiplied with the texel: shade in rgb (1 = as drawn), alpha in a.
    var tint: SIMD4<Float>
    /// Mirrored horizontally.
    var flipped: Bool
    /// The part of the sprite's cell to draw (x, y, width, height in texels from its top-left); nil draws all of
    /// it. The wind's sway draws a tree as bands of rows, each shifted by whole pixels.
    var source: SIMD4<Float>? = nil
}

/// One actor quad (king, people, creatures, eye glints), in **device** pixels of the drawable (origin top-left). Its
/// texels are still s × s blocks; the renderer lights it from the light buffer at its position.
struct ActorInstance: Sendable, Equatable {
    var sprite: SpriteID
    var frame: Int
    /// x, y, width, height in device pixels.
    var rect: SIMD4<Float>
    var tint: SIMD4<Float>
    var flipped: Bool
    /// Drawn after lighting at full strength (eye glints).
    var isEmissive: Bool
    /// The gameplay light field lights this actor (0.12 or more).
    var isLit: Bool
    /// The most point light it reflects (0: the world's cap, `kLitCap`; creatures less, M2b review).
    var lightCap: Float = 0
    /// The strength of a moonlight rim on its screen-right edge (unlit creatures at night; 0: none, or the king's).
    var moonRim: Float = 0
}

/// One quad of the emissive pass (flames, window glass, lantern glass, stars, sun, moon), added after lighting; it
/// feeds the bloom. The pass draws its quads in order with premultiplied-over blending: `glow` adds its light,
/// `glass` lights the dark window glass of its sprite (palette night0, night1, ink) inside `source`, and `occluder`
/// clears the glow under the opaque pixels of a sprite drawn later on the mid, world or foreground plane, so a light
/// never shines through what stands in front of it (ART.md "Renderer additions").
struct EmissiveInstance: Sendable, Equatable {
    enum Kind: Sendable, Equatable {
        case glow, glass, occluder
    }

    var sprite: SpriteID
    /// The plane whose offset the rect uses.
    var plane: Plane
    /// x, y, width, height in target pixels of that plane.
    var rect: SIMD4<Float>
    /// rgb × intensity, alpha in a (glow); the glow colour of the glass (glass); unused (occluder).
    var color: SIMD4<Float>
    var kind: Kind
    /// The part of the sprite the quad shows: x, y from its top-left, width, height in sprite pixels (unflipped).
    var source: SIMD4<Float>
    /// Mirrored horizontally, with its prop.
    var flipped: Bool
    /// The atlas frame of the sprite (M2b: the beacon's fire flickers through its frames; glass and occluders follow
    /// their prop's frame).
    var frame: Int

    init(sprite: SpriteID, plane: Plane, rect: SIMD4<Float>, color: SIMD4<Float>, kind: Kind = .glow,
         source: SIMD4<Float>? = nil, flipped: Bool = false, frame: Int = 0) {
        self.sprite = sprite
        self.plane = plane
        self.rect = rect
        self.color = color
        self.kind = kind
        let size = sprite.size
        self.source = source ?? SIMD4<Float>(0, 0, Float(size.width), Float(size.height))
        self.flipped = flipped
        self.frame = frame
    }
}

/// One light of the light pass, shaped like `LightInstance`: `circle` = centre x, centre y, radius (target pixels of
/// its plane), intensity; `color` = r, g, b, 0. `ellipseY` is the vertical squash of the pool (`LightField`). A light
/// of the mid plane (the warden statue's bowl fire) moves with the mid plane.
struct FrameLight: Sendable, Equatable {
    var circle: SIMD4<Float>
    var color: SIMD4<Float>
    var ellipseY: Float
    var kind: LightKind
    var plane: Plane = .world
}

/// One fog plane: colour, density, how much point light it catches, and its drift in game pixels.
struct FogLayer: Sendable, Equatable {
    var plane: Plane
    var color: SIMD3<Float>
    var density: Float
    var lightShare: Float
    var drift: Float
}

/// One plane's camera offset and quads.
struct PlaneLayer: Sendable, Equatable {
    var offset: PlaneOffset
    var sprites: [SpriteInstance]

    var plane: Plane { offset.plane }
}

/// Instance counts (DESIGN.md "Performance budget": design 300 sprite instances, 16 to 40 lights).
struct FrameCounts: Sendable, Equatable {
    var sprites: Int
    var actors: Int
    var emissives: Int
    var lights: Int

    /// Every quad of the frame: plane sprites, actors and emissives.
    var instances: Int { sprites + actors + emissives }
}

/// Everything the renderer needs for one frame, built by `FrameBuilder` from the scene, clock and camera. Immutable and
/// `Equatable`: the same inputs give an equal frame.
struct FrameDesc: Sendable, Equatable {
    /// Device pixels per game pixel.
    let scale: Int
    let physicalWidth: Int
    let physicalHeight: Int
    /// Low-resolution target size (one spare column).
    let targetWidth: Int
    let targetHeight: Int
    /// Target row of the ground line; device y of the ground line.
    let groundRow: Int
    let groundDeviceY: Int

    let hour: Double
    let phase: DayPhase
    /// World x at the left screen edge.
    let cameraX: Double
    let kingX: Double
    /// The king's anchor on screen in device pixels (`debug-king-x`).
    let kingScreenX: Int

    /// Every plane, back to front (`Plane.allCases` order).
    let planes: [PlaneLayer]
    let actors: [ActorInstance]
    let lights: [FrameLight]
    let emissives: [EmissiveInstance]
    /// Fog planes (empty with `nofog` and `minimal`).
    let fog: [FogLayer]

    /// The day's ambient look at this hour.
    let ambient: AmbientSample
    let skyTop: SIMD3<Float>
    let skyBottom: SIMD3<Float>
    let starAlpha: Float
    /// The darkness bank's right edge in target pixels of the world plane (negative when off screen to the left).
    let bankEdge: Float
    /// Ambient multiplier inside the bank.
    let bankAmbientScale: Float

    let lightStyle: LightStyle
    /// Bands of the `banded` style.
    let lightBands: Int
    let bloom: Bool
    let debugLights: Bool
    let counts: FrameCounts
    /// The look the renderer composites this frame with (DESIGN.md "Look 2 port"); `FrameBuilder` sets it from
    /// `FrameOptions.look`.
    var look: LookVersion = .one
    /// Look 2: the cut-away rooms on screen (the hall's interior, the smithy's forge), at most two, each as x0, y0,
    /// x1, y1 in world target pixels. Inside them the ambient is the room's warm fill and the night's pull lets go.
    var rooms: [SIMD4<Float>] = []
    /// Look 2: the rain (0 ... 1) and how wet stone and lane are (0 ... 1), for the composite's wet sheen.
    var rain: Float = 0
    var wetness: Float = 0

    /// The layer of one plane.
    func layer(_ plane: Plane) -> PlaneLayer {
        planes[plane.rawValue]
    }
}
