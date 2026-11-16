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
    // b3-horde (build 3, lane 4 step A, POLISH.md 7): the third small body and its glow, the small ones' fall (three
    // frames per body) and its glow, the smoke thread over every small one (tools/creatures, `HordeLook`); step 3: the
    // fall's grey flakes, and the thread's three curls as three strips (`HordeLook.threadSprites`)
    case tumbler, tumblerGlow, sootFall, sootFallGlow, sootThread, sootFlake, sootThreadB, sootThreadC
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
    // Look 2 (SPRITES.md "Look 2: the world", ART-look2.md 13.1). Far plane: the Weltmauer (world-2: one castle, the
    // far castle in its slots, the patch and the slots' lights are gone)
    case weltmauer
    // Far and mid: the fir belt, the shadow land's forest, the valley (the world rebuild took the Throat's rock and
    // the cleft's faces out: they are the steps and the cleft wall below)
    case d2FirBeltFar, shadowForest, valleyVista, d2TreeBelt
    // Near plane (0.75): the trees of both lands
    case firA, firB, firC, firD, deadTreeA, deadTreeB, linden, poplar, appleTree, willow
    // World plane: bushes, the lane's end and the four lanes (variants A to D)
    case d2BushA, d2BushB, d2LaneEnd
    case laneMoorA, laneMoorB, laneMoorC, laneMoorD, laneScreeA, laneScreeB, laneScreeC, laneScreeD
    case laneCobbleA, laneCobbleB, laneCobbleC, laneCobbleD, laneEarthA, laneEarthB, laneEarthC, laneEarthD
    // Foreground plane
    case d2FgFerns, d2FgMeadow, d2FgReeds
    // White alpha masks the engine colours (fog banks, the mist band, chimney smoke) and additive effects
    case d2FogBank, d2MistBand, d2FogLow, d2Smoke, d2Fireflies, d2Sparks
    // The darkness bank's emissive strip (4 frames, ART-look2.md 11.5)
    case darknessBankGlow
    // The gatehouse's tier 3 and its building state, the scaffold before the front (SPRITES.md "The castle grows";
    // world-2: the keep's copies and the far castles are gone, the one keep is below)
    case castleFront3, castleFront3Build, castleFrontScaffold
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
    // Polish after round 2 (SPRITES.md "The town at night, the square's props"; look 2 only): the square's props
    case hayCart, barrels, noticeBoard
    // Stage 7 (SPRITES.md "The old walls in the Throat, the tiers' anchors"; look 2 only): what is left of the first
    // line before the gatehouse; the places of the middle and the outer line, Lady Oriel's broken wall in the
    // Throat's rock; the footing and the end piece that tie a tier into that rock (on the place's canvas)
    case oldWall1, oldWall2, oldWall3, palisadeAnchor, stoneWallAnchor, bastionAnchor
    // Stage 7 (SPRITES.md "The Gloom's fog"; look 2 only): the fog bank behind the play plane, the veil and the
    // creeping fog before it (two frames each: the body that repeats, the leading face), the shred that tears off
    // the front, the cold eyes in the bank's heart (an emissive)
    case gloomFogBack, gloomFogMid, gloomFogFront, gloomWisp, gloomFogEyes
    // World rebuild, step world-1 (SPRITES.md "The rock and the fog"; look 2 only): the Throat's far wall in three
    // steps, the cleft wall behind the castle and the cold shaft of light through its slit (mid plane), the granite
    // the gatehouse's towers grow out of (world plane), the darkness bank's three sheets (fog A, world, fog B)
    case throatStepA, throatStepB, throatStepC, cleftWallA, cleftWallB, cleftWallC, cleftShaft
    case gateRockL, gateRockR, bankSheetA, bankSheetB, bankSheetC
    // World rebuild, fix round 1 (SPRITES.md "The rock and the fog"): where the world ends the dark is whole (fog B,
    // drawn black), the deck of cloud across the Weltmauer with its ragged underside and veil of mist (far plane), and
    // a thread of falling water on the cleft wall (mid plane, four frames), the moor's oldest ruin (near plane)
    case bankEnd, cloudDeck, cleftWater, moorRuin
    // World rebuild, fix round 2: where the castle's cobbles give way to the valley's earth lane (tools/lanejoin.py)
    case laneCobbleEnd
    // World rebuild, step world-2 (SPRITES.md "One castle"; tools/keepart.py): the one keep per tier and its building
    // states (mistBand parallax), the curtain wall, its stair, tower, hoarding and banner, the forebuilding with the hall
    // door (closed, open) and the hall's light through it and on the cobbles, the chapel of the Flame (the bell, gone),
    // the bakehouse and its oven's glow, the postern per tier, the gate passage's arch in the foreground, and where the
    // Throat's scree gives way to the castle's cobbles under the gatehouse (tools/lanejoin.py)
    case keepT1, keepT2, keepT3, keepT2Build, keepT3Build
    case curtainA, curtainB, curtainC, curtainStair, curtainTower, curtainHoard, castleBanner
    case forebuilding, hallDoorGlow, hallDoorWedge, chapelTower, bakehouse, bakeHatchGlow
    case posternT1, posternT2, posternT3, gateArchFg, laneScreeCobble
    // World-2 fix round 1 (tools/keepfix.py): the mist bank at the keep's foot, the bloom around its lit windows, its
    // brazier's light, a puff of chimney smoke (three sizes), the postern's far end lit at night
    case keepMist, keepPaneHalo, keepFireGlow, smokePuff, posternFarGlow
    // ... and the keep's warm rim on its west edges at dusk, one per keep sprite
    case keepRimT1, keepRimT2, keepRimT3, keepRimT2Build, keepRimT3Build
    // World lane, step world-3 (tools/w3art.py, SPRITES.md "World-3"): the bakehouse oven's wedge of light, the moon's
    // rim on each beacon stage, the town's back row of roofs (near plane), the far shore's lantern and a moored skiff,
    // the valley lane's verge
    case bakeHatchWedge, beaconRuinRim, beaconBaseRim, beaconTowerRim, greatBeaconRim
    case townRoofsA, townRoofsB, townRoofsC, townRoofsD, riverFarLantern, riverSkiff, valleyVerge
    // World lane, world-3 fix round 1 (tools/w3f1art.py, SPRITES.md "World-3, fix round 1"): the river end's landing,
    // the skiff moored at it and the moon on its gunwale, the far lantern's halo and its reflection on the water, a
    // buttress in the Throat (near plane), a second painting of the valley's verge
    case riverLanding, riverSkiffMoored, riverSkiffRim, riverLanternHalo, riverLanternStreak, throatButtress, valleyVergeB
    // World lane, world-3 fix round 2 (tools/w3f2art.py, SPRITES.md "World-3, fix round 2"): the postern's far view
    // at night, the Gloom's ground fog (two frames: body, leading face)
    case posternNightView, gloomGroundFog
    // Stage 7 (SPRITES.md "The house envoys", "The houses' banners"): the four houses' faces as guests with a body
    // (walk 0-3, idle 4-5, talk 6-7) and a story portrait of their own, and the five houses' banners in the hall
    case hildVarn, lorenzPell, ebbaCalder, orlaLorn
    case portraitHildVarn, portraitLorenzPell, portraitEbbaCalder, portraitOrlaLorn
    case bannerVarn, bannerBrine, bannerOxmoor, bannerCalder, bannerLorn
    // Stage 7 (SPRITES.md "The circlet icon"): interface art, never in the world: the lord's circlet in gold (the
    // HUD's audience button) and in ink alone (the audience card's gold button)
    case circletIcon, circletIconInk
    // The town lane (town-2, docs/TOWN.md section 1, `TownSprites`): the households at their doors, the farmer, the
    // lord's knock, the coin, the houses' open door and closed shutters
    case townCorra, townDun, townBrede, townHemmet, townWenna, townGorm, townNib, kingKnock, ladyKnock, townCoin,
         townCottage, townBigHouse
    // The people lane (docs/PEOPLE.md, docs/SPRITES-people.md, `PeopleCast`): working people marked by life (Old
    // Hemmet, Wenna Brisk, Brede Hask, Gorm and Hedda Ashby at work), three children, the nobles of the inner lands
    case elder, washerwoman, labourer, farmerHoe, farmerScythe, childA, childB, childC, nobleLord, nobleLady, footman
    // The people lane's cloth states (docs/PEOPLE.md section 7, `PeopleCast.ClothState`): the same bodies in the
    // village's and the town's cloth (wealth changes the cloth, never the people)
    case citizenVillage, citizenBVillage, citizenCVillage, citizenSeatedVillage, citizenBSeatedVillage,
         citizenCSeatedVillage, elderVillage, washerwomanVillage, labourerVillage, farmerHoeVillage, farmerScytheVillage
    case citizenTown, citizenBTown, citizenCTown, citizenSeatedTown, citizenBSeatedTown, citizenCSeatedTown, elderTown,
         washerwomanTown, labourerTown, farmerHoeTown, farmerScytheTown, childATown, childBTown, childCTown
    // The people lane, people-2 (docs/PEOPLE.md section 5, `TownLife`, `TownLamps`): Silas Moth the lamplighter and his
    // pole's flame, Saul Tolliver the collector with his handcart, the noble's coach, Old Hemmet on the bench (and its
    // cloth states)
    case lamplighter, lamplighterGlow, collector, coach, elderSeated, elderSeatedVillage, elderSeatedTown
    // The people lane, people-2 fix round 1: the lord's mended cloak (`LordCloak`; the sheets as painted are the good
    // one) and the court's ties, one idle each played toward another person (`CourtTies`)
    case kingMended, ladyMended, kingSeatedMended, ladySeatedMended
    case odileTie, brannockTie, pipTie, hesperTie, hesperTieGlow, tamsinTie, bramTie, marekTie, serenTie, serenTieGlow
    // The hall stage (stage lane, 14.11.2026; SPRITES.md "The great hall as a stage", "The hall stage's light"): the
    // great hall, its near pillar and its fire, the six marks of touch the world (stage 8), the day's light shaft, a
    // dust mote and the plaster patches over the brick (tools/hallstage.py)
    case greatHall, hallPillarNear, hallFire, tapTalk, tapThrone, tapBuild, tapRepair, tapRecruit, tapLight
    case hallShaft, hallMote, hallWash
    // Touch the world (stage lane, step stage-2, 15.11.2026): the seventh mark, a door, over the great hall's door
    // in the world and its inner door (tools/hallart.py)
    case tapDoor
    // The interface kit (stage lane, stage-3-interface, 15.11.2026; HUD.md, tools/hudart.py, SPRITES.md "The interface
    // kit"): the lantern moment's row and day line, the gold at the lord, the cards' coin, face and people; drawn
    // unlit, never lit by the world
    case hudFigures, hudArrow, hudCoin, hudFace, hudPeople, hudGear, hudDawn

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
        // b3-horde
        case .tumbler, .tumblerGlow, .sootFall, .sootFallGlow: return PixelSize(width: 14, height: 14)
        case .sootThread, .sootThreadB, .sootThreadC: return PixelSize(width: 15, height: 18)
        case .sootFlake: return PixelSize(width: 3, height: 3)
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
        case .d2FirBeltFar: return PixelSize(width: 520, height: 40)
        case .shadowForest: return PixelSize(width: 224, height: 104)
        case .valleyVista: return PixelSize(width: 448, height: 160)
        case .d2TreeBelt: return PixelSize(width: 520, height: 58)
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
        case .d2BushA: return PixelSize(width: 30, height: 15)
        case .d2BushB: return PixelSize(width: 22, height: 12)
        case .d2LaneEnd: return PixelSize(width: 48, height: 30)
        case .laneMoorA, .laneMoorB, .laneMoorC, .laneMoorD, .laneScreeA, .laneScreeB, .laneScreeC, .laneScreeD,
             .laneCobbleA, .laneCobbleB, .laneCobbleC, .laneCobbleD, .laneEarthA, .laneEarthB, .laneEarthC,
             .laneEarthD, .laneCobbleEnd, .laneScreeCobble:
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
        // Fix round 1 of the world rebuild: one pair of the bank's eyes, near and far, open and half shut.
        case .darknessBankGlow: return PixelSize(width: 9, height: 3)
        case .castleFront3, .castleFront3Build: return PixelSize(width: 268, height: 236)
        case .castleFrontScaffold: return PixelSize(width: 240, height: 236)
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
        case .hayCart: return PixelSize(width: 40, height: 24)
        case .barrels: return PixelSize(width: 26, height: 14)
        case .noticeBoard: return PixelSize(width: 20, height: 26)
        case .oldWall1: return PixelSize(width: 84, height: 60)
        case .oldWall2, .oldWall3, .palisadeAnchor, .stoneWallAnchor, .bastionAnchor:
            return PixelSize(width: 128, height: 108)
        case .gloomFogBack: return PixelSize(width: 192, height: 120)
        case .gloomFogMid: return PixelSize(width: 160, height: 64)
        case .gloomFogFront: return PixelSize(width: 128, height: 30)
        case .gloomWisp: return PixelSize(width: 40, height: 16)
        case .gloomFogEyes: return PixelSize(width: 64, height: 72)
        // World rebuild, step world-1
        case .throatStepA: return PixelSize(width: 224, height: 104)
        case .throatStepB: return PixelSize(width: 224, height: 176)
        case .throatStepC: return PixelSize(width: 224, height: 200)
        case .cleftWallA, .cleftWallB: return PixelSize(width: 256, height: 200)
        case .cleftWallC: return PixelSize(width: 192, height: 200)
        case .cleftShaft: return PixelSize(width: 64, height: 200)
        case .gateRockL: return PixelSize(width: 108, height: 80)
        case .gateRockR: return PixelSize(width: 64, height: 70)
        case .bankSheetA: return PixelSize(width: 256, height: 208)
        case .bankSheetB: return PixelSize(width: 256, height: 124)
        case .bankSheetC: return PixelSize(width: 256, height: 56)
        case .bankEnd: return PixelSize(width: 96, height: 208)
        case .cloudDeck: return PixelSize(width: 720, height: 100)   // fix round 2: room for the towers
        case .cleftWater: return PixelSize(width: 14, height: 54)
        // World rebuild, step world-2 (tools/keepart.py).
        case .keepT1, .keepT2, .keepT3, .keepT2Build, .keepT3Build: return PixelSize(width: 260, height: 175)
        case .curtainA, .curtainB, .curtainC: return PixelSize(width: 64, height: 74)
        case .curtainStair: return PixelSize(width: 52, height: 66)
        case .curtainTower: return PixelSize(width: 44, height: 104)
        case .curtainHoard: return PixelSize(width: 64, height: 22)
        case .castleBanner: return PixelSize(width: 12, height: 30)
        case .forebuilding: return PixelSize(width: 120, height: 96)
        case .hallDoorGlow: return PixelSize(width: 20, height: 32)
        case .hallDoorWedge: return PixelSize(width: 60, height: 19)
        case .chapelTower: return PixelSize(width: 110, height: 132)
        case .bakehouse: return PixelSize(width: 100, height: 62)
        case .bakeHatchGlow: return PixelSize(width: 6, height: 6)
        case .posternT1, .posternT2, .posternT3: return PixelSize(width: 176, height: 112)
        case .gateArchFg: return PixelSize(width: 16, height: 116)
        // World-2 fix round 1 (tools/keepfix.py).
        case .keepMist: return PixelSize(width: 320, height: 32)      // fix round 2: rises over the merlons
        case .keepRimT1, .keepRimT2, .keepRimT3, .keepRimT2Build, .keepRimT3Build: return PixelSize(width: 260, height: 175)
        case .keepPaneHalo: return PixelSize(width: 11, height: 14)
        case .keepFireGlow: return PixelSize(width: 36, height: 24)
        case .smokePuff: return PixelSize(width: 8, height: 8)        // fix round 2: 3 to 7 px
        case .posternFarGlow: return PixelSize(width: 10, height: 16)
        // World-3 (tools/w3art.py).
        case .bakeHatchWedge: return PixelSize(width: 30, height: 14)
        case .beaconRuinRim, .beaconBaseRim, .beaconTowerRim, .greatBeaconRim: return PixelSize(width: 64, height: 130)
        case .townRoofsA, .townRoofsB, .townRoofsD: return PixelSize(width: 120, height: 72)
        case .townRoofsC: return PixelSize(width: 120, height: 96)
        case .riverFarLantern: return PixelSize(width: 12, height: 26)
        case .riverSkiff: return PixelSize(width: 34, height: 10)
        // World-3 fix round 1 (tools/w3f1art.py).
        case .riverLanding: return PixelSize(width: 72, height: 20)
        case .riverSkiffMoored, .riverSkiffRim: return PixelSize(width: 40, height: 12)   // world-3 fix round 2
        case .riverLanternHalo: return PixelSize(width: 22, height: 22)
        case .riverLanternStreak: return PixelSize(width: 7, height: 26)   // world-3 fix round 2
        // World-3 fix round 2 (tools/w3f2art.py).
        case .posternNightView: return PixelSize(width: 10, height: 14)
        case .gloomGroundFog: return PixelSize(width: 160, height: 28)
        case .throatButtress: return PixelSize(width: 96, height: 132)
        case .valleyVergeB: return PixelSize(width: 64, height: 10)
        case .valleyVerge: return PixelSize(width: 64, height: 10)
        case .moorRuin: return PixelSize(width: 50, height: 36)
        case .hildVarn, .lorenzPell, .ebbaCalder, .orlaLorn: return PixelSize(width: 14, height: 30)
        case .portraitHildVarn, .portraitLorenzPell, .portraitEbbaCalder, .portraitOrlaLorn:
            return PixelSize(width: 48, height: 48)
        case .bannerVarn, .bannerBrine, .bannerOxmoor, .bannerCalder, .bannerLorn:
            return PixelSize(width: 20, height: 41)
        case .circletIcon, .circletIconInk: return PixelSize(width: 24, height: 16)
        case .townCorra, .townDun, .townBrede, .townHemmet, .townWenna, .townGorm, .townNib, .kingKnock, .ladyKnock,
             .townCoin, .townCottage, .townBigHouse:
            return TownSprites.size(of: self)
        case .elder, .washerwoman, .labourer, .farmerHoe, .farmerScythe, .childA, .childB, .childC, .nobleLord,
             .nobleLady, .footman:
            return PeopleCast.size(of: self)
        case .citizenVillage, .citizenBVillage, .citizenCVillage, .citizenSeatedVillage, .citizenBSeatedVillage,
             .citizenCSeatedVillage, .elderVillage, .washerwomanVillage, .labourerVillage, .farmerHoeVillage,
             .farmerScytheVillage, .citizenTown, .citizenBTown, .citizenCTown, .citizenSeatedTown, .citizenBSeatedTown,
             .citizenCSeatedTown, .elderTown, .washerwomanTown, .labourerTown, .farmerHoeTown, .farmerScytheTown,
             .childATown, .childBTown, .childCTown:
            return PeopleCast.size(of: self)
        case .lamplighter, .lamplighterGlow, .collector, .coach, .elderSeated, .elderSeatedVillage, .elderSeatedTown:
            return PeopleCast.size(of: self)
        case .kingMended, .ladyMended, .kingSeatedMended, .ladySeatedMended:
            return PeopleCast.size(of: self)
        case .odileTie, .brannockTie, .pipTie, .hesperTie, .hesperTieGlow, .tamsinTie, .bramTie, .marekTie, .serenTie,
             .serenTieGlow:
            return CourtTies.size(of: self)
        // The hall stage (stage lane).
        case .greatHall: return PixelSize(width: 600, height: 201)
        case .hallPillarNear: return PixelSize(width: 30, height: 201)
        case .hallFire: return PixelSize(width: 34, height: 28)
        case .tapTalk, .tapThrone, .tapBuild, .tapRepair, .tapRecruit, .tapLight: return PixelSize(width: 15, height: 18)
        case .tapDoor: return PixelSize(width: 15, height: 18)
        case .hallShaft: return PixelSize(width: 83, height: 120)
        case .hallMote: return PixelSize(width: 1, height: 1)
        case .hallWash: return PixelSize(width: 64, height: 44)
        // The interface kit (stage lane, stage-3-interface).
        case .hudFigures: return PixelSize(width: 7, height: 9)
        case .hudArrow: return PixelSize(width: 8, height: 9)
        case .hudCoin, .hudFace: return PixelSize(width: 9, height: 9)
        case .hudPeople: return PixelSize(width: 13, height: 9)
        case .hudGear: return PixelSize(width: 10, height: 10)
        case .hudDawn: return PixelSize(width: 11, height: 9)
        }
    }

    /// The court and the guests of M3 and their glow strips: 8 frames each (walk 0 ... 3, idle 4 ... 5, talk 6 ... 7).
    var isCourtBody: Bool {
        switch self {
        case .odile, .brannock, .pip, .hesper, .tamsin, .bram, .marek, .seren, .serLudo, .bard, .envoy, .herald,
             .hesperGlow, .serenGlow, .heraldGlow, .hildVarn, .lorenzPell, .ebbaCalder, .orlaLorn:
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
        if let count = TownSprites.frameCount(of: self) { return count }
        if let body = PeopleCast.body(dressedAs: self) { return body.frameCount }
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
        // b3-horde: the tumbler rolls 0-3 and claws 4-6 (gather, claw, recover); the fall 0-2 crawler, 3-5 loper, 6-8
        // tumbler; the thread (length index × 9 + lean + 4) × 2 + sway, eight lengths, one strip per curl (one strip of
        // 432 frames, 6480 px wide, did not decode on the simulator; `HordeLook.threadFrame`); the flakes' three shapes
        case .tumbler, .tumblerGlow: return 7
        case .sootFall, .sootFallGlow: return 9
        case .sootThread, .sootThreadB, .sootThreadC: return 144
        case .sootFlake: return 3
        case .citizen, .citizenB, .citizenC, .builder: return 6
        case .elder, .washerwoman, .labourer, .farmerHoe, .farmerScythe, .childA, .childB, .childC, .nobleLord,
             .nobleLady, .footman:
            return PeopleCast.frameCount(of: self)
        case .lamplighter, .lamplighterGlow, .collector, .coach, .elderSeated:
            return PeopleCast.frameCount(of: self)
        case .odileTie, .brannockTie, .pipTie, .hesperTie, .hesperTieGlow, .tamsinTie, .bramTie, .marekTie, .serenTie,
             .serenTieGlow:
            return CourtTies.frameCount
        case .archer: return 5
        case .sootCrow, .sootCrowGlow, .gloomweaver, .gloomweaverGlow: return 4
        case .beaconFire, .darknessBankGlow, .gloomFogEyes: return 4
        case .gloomWisp: return 6
        case .gloomFogBack, .gloomFogMid, .gloomFogFront: return 2
        case .gloomGroundFog: return 2   // world-3 fix round 2: body, leading face
        case .bankSheetA, .bankSheetB, .bankSheetC: return 2
        case .cleftWater: return 12   // fix round 2: six frames per thread, the second thread's from frame 6
        case .forebuilding, .chapelTower: return 2   // world-2: the hall door closed and open; the bell, gone
        case .gateArchFg: return 2                   // world-2: unplaced since fix round 2 (build 3 may bring it back)
        case .smokePuff: return 5                    // world-2 fix round 2: five sizes, 3 to 7 px
        case .gateWood, .gateIron, .gateGreat, .catapult: return 3
        case .arrow, .fireArrow, .bolt, .spark, .streak, .rainSplash: return 3
        case .rainStreak: return 9
        case .palisade, .stoneWall, .bastion, .ballista, .stakePit, .firepot, .shard: return 2
        // The hall stage (stage lane): the great fire's six frames, idle and pressed marks, eight plaster patches.
        case .hallFire: return 6
        case .tapTalk, .tapThrone, .tapBuild, .tapRepair, .tapRecruit, .tapLight: return 2
        case .tapDoor: return 2
        case .hallWash: return 8
        // The interface kit: the figures 0-9, plus and minus; the arrows up and down; the face's four moods.
        case .hudFigures: return 12
        case .hudArrow: return 2
        case .hudFace: return 4
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
    /// The hall stage (stage lane, fix round 2 of step stage-1): game rows cut off the strip's bottom (a petitioner
    /// sitting behind a bench: the legs below the wall line); 0: the whole frame.
    var cropBottom: Int = 0
}

/// One quad of the emissive pass (flames, window glass, lantern glass, stars, sun, moon), added after lighting; it
/// feeds the bloom. The pass draws its quads in order with premultiplied-over blending: `glow` adds its light,
/// `glass` lights the dark window glass of its sprite (palette night0, night1, ink) inside `source`, and `occluder`
/// clears the glow under the opaque pixels of a sprite drawn later on the mid, world or foreground plane, so a light
/// never shines through what stands in front of it (ART.md "Renderer additions").
struct EmissiveInstance: Sendable, Equatable {
    enum Kind: Sendable, Equatable {
        case glow, glass, occluder
        // Touch the world, fix round 1 (stage lane): the gold rim one pixel outside the sprite's outline at its left,
        // right and top (SPRITES.md "The marks of 'touch the world'"); the quad is the sprite grown by that pixel.
        case rim
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
    /// World-2 fix round 2: the pool's cut in its plane's target pixels (min x, min y, max x, max y), nil for none.
    var clip: SIMD4<Float>?
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
    // The hall stage (stage lane, 14.11.2026; DESIGN.md "The hall stage and touch the world").
    /// Device pixels per game pixel as the composite reads them, when it is not `scale`: the hall's eased move into
    /// the audience framing (s 7 to s 8) passes through fractional values; nil everywhere else.
    var zoom: Double? = nil
    /// An interior's own light on the world plane and the figures (the great hall): the ambient replaces the
    /// world's (the far plane and the sky through the windows keep the hour's), the night's pull is scaled, and the
    /// upper wall fades into the roof's dark. nil outdoors.
    var interior: InteriorLight? = nil
    /// World-3 fix round 1: a hard fog night's extra haze on the mid plane (`GloomFog.midHaze`), 0 otherwise.
    var gloomHaze: Float = 0

    /// The layer of one plane.
    func layer(_ plane: Plane) -> PlaneLayer {
        planes[plane.rawValue]
    }
}

/// An interior's light (the hall stage, stage lane): what the composite of look 2 takes instead of the world's ambient
/// on the world plane and on the figures. The far plane and the sky (seen through the windows) keep the hour's light.
struct InteriorLight: Sendable, Equatable {
    /// The ambient light on the hall's albedo (rgb, at its level).
    var ambient: SIMD3<Float>
    /// The night's pull toward deep blue × this (1: as outdoors).
    var nightPull: Float
    /// The vertical value ramp: the ambient falls to `1 − rampStrength` toward the top of the target, from
    /// `rampEndRow` (target rows) upward over `InteriorLight.rampRows` rows; 0: none.
    var rampStrength: Float
    var rampEndRow: Float
    /// The near pillars (fix round 1 of step stage-1): the dithered window where the lord stands behind one (centre x,
    /// y in world target px, half width, half height; zero: none), the rims of light on their left and right edges,
    /// and the share of the hall's ambient they take.
    var pillarHole = SIMD4<Float>(repeating: 0)
    var rimLeft = SIMD3<Float>(repeating: 0)
    var rimRight = SIMD3<Float>(repeating: 0)
    var pillarAmbient: Float = 0.6
    /// Fix round 2: the soft band of light 4 px wide on the pillar's key side (> 0: the right edge in `rimRight`'s
    /// light, < 0: the left in `rimLeft`'s; its size the strength; 0: rims only).
    var pillarBand: Float = 0

    /// The rows over which the upper wall fades into the roof's dark.
    static let rampRows: Float = 95
}
