# Lanternhold: sprite contract for the entities (M2b and the art lane)

This file is the contract between the code lane (M2b puts the game on screen) and the art lane (paints the PNGs). It
was set by the lead on 09.11.2026. Neither lane changes it on its own. A lane that needs a change writes the deviation
into its own notes (ART.md or DESIGN.md) and reports it, and the lead updates this file.

## Rules for every sprite here

- File: `games/lanternhold/Resources/Art/<id>.png`, where `<id>` is the `SpriteID` raw value below, spelled exactly.
  The atlas loads that PNG when it exists and otherwise draws the procedural placeholder (`AtlasBuilder.frames`), so a
  missing PNG never breaks the build.
- Format: 8-bit RGBA, binary alpha, one texel is one game pixel, colours from `tools/palette.txt` only (the albedo
  ramps for bodies; the `emissive` fire ramp only in the glow strips).
- Size: one row of frames, left to right, no gaps: the PNG is (width x frames) by height.
- Anchor: the bottom centre of every frame is the foot point (x on the ground line, or the wall walk for soldiers on
  a wall). Keep the feet on the bottom row in every frame, so the sprite does not bob unless the animation means it.
- Facing: every actor faces right in the PNG. The engine mirrors it when it walks or aims left.
- Light: albedo only, as for the scene (ART.md): no baked night, no glow and no light pools in the body. Everything
  that glows goes into a separate glow strip (`<id>Glow`) of the same size and frames. The engine draws the glow strip
  exactly over the body frame, each glow pixel as its own colour (it replaces the body pixel under it; it is not
  added), so the body pixel under a glow pixel only shows where the engine dims or hides the strip.
- Unlit creatures (amended by the lead on 09.11.2026 after the art review): at night outside every light the engine
  draws the body opaque at a very low value (`EntityFrames.unlitValue`, 0.2 at full night, never a translucent ghost),
  a cool moonlight rim on its screen-right edge pixels (`Renderer.rimmed`, the king's rim pass; firelight outshines
  it), and the glow strip over it. In light the whole body shows. So the glow strip alone must still read as the
  creature: a dim ember rim (`emberDim`) on the silhouette's top contour, `ember` only inside a few cracks, and one
  cold eye (`wraithWhite`, at most one `wraithDim` tear under it) low in a dark socket; never two eyes (ART-look2.md
  11.2, ART-actors.md "Glow strip rules"). The body must read in daylight and in firelight. The engine draws the cold
  pixels as they are: no warm tint, no torch strength, and not dimmed by day.

## Actors

| id | size | frames | frame use |
|---|---|---|---|
| `king` | 16x30 | 10 | walk 0-5 (one frame per 4 game px since the M2b review, was 7: his planted feet slid), idle 6-7, command 8-9 (lifts the lantern to give an order) |
| `kingGlow` | 16x30 | 10 | the lantern glass (and a glint on the crown) per frame; the engine dims it by day (half its colour) and burns it full at night |
| `citizen`, `citizenB`, `citizenC` | 12x26 | 6 each | walk 0-3, idle 4-5 (three different townsfolk) |
| `archer` | 12x28 | 5 | idle 0-1, draw 2-3, loose 4 |
| `guardsman` | 14x28 | 9 | idle 0-1, walk 2-5, strike 6-8 |
| `builder` | 12x24 | 6 | walk 0-3, hammer 4-5 |

## Creatures (and their glow strips, same size and frames)

| id | size | frames | frame use |
|---|---|---|---|
| `sootling`, `sootlingB` | 14x14 | 6 each | walk 0-3, attack 4-5 (two silhouettes; the engine alternates by creature id) |
| `shadehound` | 22x14 | 6 | run 0-3, attack 4-5 |
| `sootCrow` | 12x10 | 4 | fly 0-2, perch 3 |
| `ashBrute` | 44x44 | 7 | walk 0-3, attack 4-6 |
| `gloomweaver` | 30x30 | 4 | float 0-3 |
| `ashGiant` | 110x110 | 7 | walk 0-3, stomp 4-6 |
| `lightlessKing` | 64x64 | 7 | walk 0-3, attack 4-6 |

Glow strips: `sootlingGlow`, `sootlingBGlow`, `shadehoundGlow`, `sootCrowGlow`, `ashBruteGlow`, `gloomweaverGlow`,
`ashGiantGlow`, `lightlessKingGlow`. A dim ember rim and ember cracks in the fire ramp, one cold eye each
(`wraithWhite`, `wraithDim`); the gloomweaver's eye and lantern drip are cold violet; the Lightless King has no eye and
no ember, only `wraithDim` and `wraithGlow` (the crescent in his cowl, the thorns' tips). No palette entry was added;
`build-art.sh` rebuilds every strip byte for byte.

Look 2 keeps every id, size, frame count and anchor above. What the engine changes with look 2 (ART-look2.md 11.4):
the walk strides are 3, 6, 4, 4 and 5 px per frame (sootlings, shadehound, ash brute, ash giant, Lightless King); the
gloomweaver's light sits at its lantern's core (9 px right of the centre, 9 px up); the Lightless King's aura is
centred 4 px left of his centre and 52 px up, and things over his head sit 2 px higher; the ash giant's heart is a
small ember light (5 px right, 68 px up), brightest on frame 5, and its stomp's kick, dust and cue fall on frame 5 (the
damage time is untouched).

| id | size | frames | frame use |
|---|---|---|---|
| `darknessBankGlow` | 64x236 | 4 | the darkness bank's emissive strip (ART-look2.md 11.5): pairs of cold eyes and dim embers in the bank's body. One frame over each `darknessBank` tile, drawn as it is: frame (tile index + time x 1.5) mod 4, with Reduce Motion tile index mod 4 |

## Buildings (frame 0 whole, frame 1 damaged below 50 % HP, unless the table says otherwise)

| id | size | frames | notes |
|---|---|---|---|
| `palisade` | 20x34 | 2 | was 1 frame |
| `stoneWall` | 36x52 | 2 | was 1 frame |
| `bastion` | 44x64 | 2 | |
| `rubbleWood` | 24x10 | 1 | a fallen palisade |
| `rubbleStone` | 40x14 | 1 | a fallen stone wall or bastion |
| `scaffold` | 24x40 | 1 | over a build in progress; the engine tiles it over wide builds |
| `gateWood`, `gateIron`, `gateGreat` | 46x60 | 3 each | closed whole 0, closed damaged 1, open 2; overlays inside the castle front's gateway (x 1337-1383); fit the painted arch of `castleFront.png` exactly |
| `gateBroken` | 46x20 | 1 | splinters and bent bars at the foot of the gateway |
| `archerTower` | 20x48 | 1 | lines 2 and 3 only (line 1 mans the painted towers) |
| `watchtower` | 24x64 | 1 | tier 2 of the tower |
| `fireTower` | 14x40 | 1 | tier 2 of the brazier; its fire is the existing `brazierFlame` glow at the top |
| `ballista` | 28x16 | 2 | loaded 0, loosed 1 (was 1 frame) |
| `catapult` | 32x24 | 3 | rest 0, wind 1, throw 2 |
| `stakePit` | 24x8 | 2 | armed 0, sprung 1 |
| `beaconBase`, `beaconTower`, `greatBeacon` | 64x130 | 1 each | the three built stages after `beaconRuin`; the great beacon carries a huge iron bowl at the top |
| `beaconFire` | 48x32 | 4 | glow strip only (fire ramp), flicker frames: the blaze across the great beacon's whole bowl mouth, its bottom (coal) row on the mouth at (dx 8, dy 125) of `greatBeacon` (amended 09.11.: was 24x20 x 3, which read as a campfire) |
| `barracks` | 64x48 | 1 | courtyard, always there (castle palette) |
| `smithy`, `masterSmithy` | 60x48, 60x56 | 1 each | courtyard |
| `lodge`, `bigLodge` | 56x44, 64x52 | 1 each | courtyard |
| `bigHouse` | 72x56 | 1 | town (`house`, `houseB`, `houseC`, `field` exist) |
| `market` | 90x40 | 1 | town: stalls with awnings |
| `tavern` | 90x56 | 1 | town: two storeys and a sign |
| `plotMarker` | 12x22 | 1 | a tall pale staff with the realm's pennant, stakes and a rope on an empty, unlocked plot by day (M2b review: was 10x16, too small to find) |

## Projectiles

| id | size | frames | frame use |
|---|---|---|---|
| `arrow` | 7x5 | 3 | rising 0, flat 1, falling 2 |
| `fireArrow` | 7x5 | 3 | as `arrow`; the engine adds a small glow |
| `bolt` | 11x5 | 3 | as `arrow` |
| `firepot` | 5x5 | 2 | tumbling |

## Where things stand in the world (game px; ground line as in `tools/scenemock/layout_m1b.py`)

Walls (lines 1 to 3): x 1300 (the castle gate), 940, 640. Towers 978, 662 (line 1: the painted towers). Braziers
896 and 920, 596 and 617. Engines 990, 676. Stake pits 860, 560. Beacon 470. Barracks 1480, lodge 1640, hearth 1870,
keep 1990. Town plots 2512, 2680, 2832, 2932, 3122, 3245, 3365, 3540 (the centres of `WorldLayout.townPlots`;
`RealmWorldTests` pins `Realm` to the drawn world). The castle front spans 1240-1480, its wall walk is
`WorldLayout.wallWalkY` (124) and its gateway 1337-1383. Creatures come from the left (the Gloom) and walk right
towards the hearth. The engine's anchors for archer posts, flames, fire and window glass are in ART-buildings.md
("Anchors for the engine") and ART-actors.md ("Eye and lantern positions").

## M3: the court, the portraits, the castle's rooms (set by the lead on 09.11.2026)

The rules at the top of this file hold here too (ids are `SpriteID` raw values, horizontal strips, the foot at the
bottom centre, actors face right, albedo only, glow in `<id>Glow` strips, palette colours only).

### Court and guests (side view, like the king)

Every court member and guest has 8 frames: walk 0-3, idle 4-5 (a breath), talk 6-7 (a gesture while speaking).

| id | size | who (DESIGN.md "The castle") |
|---|---|---|
| `odile` | 14x30 | Odile, the chancellor: tall and thin, a dark plum robe, a silver chain of office, grey hair in a bun, a ledger under her arm; dry, sarcastic, loyal |
| `brannock` | 16x30 | Brannock, captain of the guard: broad, mail under a teal surcoat with the gold lantern, grey beard, a scar, a sword at the hip |
| `pip` | 12x22 | Pip, the fool: small, motley in teal and red, a hat with two bells; juggles in the talk frames |
| `hesper` | 14x30 | Mother Hesper, priestess of the Flame: cream and gold robe, hood, a staff with a small flame (`hesperGlow`: the flame) |
| `tamsin` | 14x28 | Tamsin, the cook: round and rosy, a white apron over a red-brown dress, a headscarf, a ladle |
| `bram` | 16x30 | Bram, the smith: huge arms, a leather apron, soot on his face, a hammer on his shoulder |
| `marek` | 14x30 | Marek, the travelling merchant: a wide hat with a feather, a long green coat, gold rings, a satchel |
| `seren` | 14x30 | Seren, the Stranger: a grey hooded cloak that hides the face, a grey lantern (`serenGlow`: its cold grey-white light) |
| `serLudo` | 16x30 | Ser Ludo, the wandering knight (comic): a helmet far too big with a drooping plume, a dented shield |
| `bard` | 12x28 | a wandering bard: a feathered cap, a lute |
| `envoy` | 14x30 | the envoy from the coast: sea-blue coat, a scroll case (a teaser for chapter 2) |
| `herald` | 14x30 | the Lightless King's herald: ashen grey, a tattered black banner, cold teal eyes (`heraldGlow`: the eyes and a cold rim, as `lightlessKingGlow`) |
| `petitionerD` | 12x26 | a petitioner body: a young townswoman with a shawl and a basket (walk 0-3, idle 4-5; 6 frames) |
| `petitionerE` | 12x26 | a petitioner body: a well-off townsman in a fine coat and cap (6 frames as above) |

Glow strips `hesperGlow`, `serenGlow`, `heraldGlow` have the body's size and frames.

### Portraits (the audience card; 48x48, transparent background, the card draws the frame and tile)

Story and guest portraits, one frame each unless noted, head and shoulders facing three-quarter right, lit warmly from
the left (the hall's hearth side), in the same scale and style as the composed parts below:
`portraitOdile`, `portraitBrannock`, `portraitPip`, `portraitHesper`, `portraitTamsin`, `portraitBram`,
`portraitMarek`, `portraitSeren` (2 frames: hooded 0, revealed 1 from day 15), `portraitSerLudo`, `portraitBard`,
`portraitEnvoy`, `portraitHerald`, `portraitKing` (the lamplighter king, for the prologue and the endings later).

Random petitioners get a composed portrait: layers of 48x48 strips drawn in this order on one head template (the same
head size, eye line and shoulder line in every part):

| id | frames | content (frame 0 of beard, hair and hat is empty) |
|---|---|---|
| `portraitClothes` | 8 | shoulders and chest in the bottom rows: smock, dress with apron, tunic, fine coat, leather apron, mail and surcoat, robe, rags |
| `portraitFace` | 6 | head and neck: round, long, square, old and wrinkled, young, child (smaller, lower) |
| `portraitBeard` | 6 | none, stubble, short, full, long, moustache |
| `portraitHair` | 8 | bald, short, long, bun, curly, braids, tousled, child's mop |
| `portraitHat` | 8 | none, straw hat, headscarf, cap with feather, hood, wool cap, helm, flower wreath |

Palette swaps. The art lane adds three swap ramps to `tools/palette.txt` with exactly these values, tagged `swap` so
no conversion picks them for other art. Faces use only the skin ramp for skin, hair and beards only the hair ramp,
clothes and the cloth parts of hats only the cloth ramp. Other colours (ink outlines, eyes, metal, straw) stay fixed.

| ramp | 1 (deep) | 2 | 3 | 4 (light) |
|---|---|---|---|---|
| `skin` (a warm medium skin) | #6B3A2A | #A0583E | #D08A62 | #F0BC94 |
| `hair` (a mid brown) | #2E1C16 | #4E3020 | #74482C | #9C6A40 |
| `cloth` (a mid ochre) | #5A3E1C | #8A6430 | #B88E48 | #E0BC72 |

The code maps each swap ramp, colour for colour, to a target ramp chosen per petitioner:

- skin:
  - pale: #8A5A48 #C08670 #E8B49A #FFE0C8
  - light: #7A4632 #B2704E #DE9E78 #F8CCA8
  - medium: the default
  - brown: #4A2818 #7A4428 #A8683E #CC9060
  - deep: #2C1810 #4E2C1C #704030 #966048
- hair:
  - black: #14101A #262030 #3A3244 #565066
  - dark brown: #24160F #3C2618 #583A24 #7A5434
  - mid brown: the default
  - blond: #6E5226 #A88440 #D8B864 #F4E098
  - red: #5A1E10 #8E3418 #C0562A #E08448
  - grey to white: #5E5A62 #8E8A92 #C0BCC2 #ECEAEE
- cloth:
  - teal: #16384A #2F6E8E #4F92AE #8CC4D6
  - red-brown: #4A1E18 #8E4A36 #B8664A #DE9474
  - green: #2E4630 #4A6B3A #6E9A4A #9DBF62
  - blue: #1E2A5A #34488E #5A72B8 #8EA6DC
  - ochre: the default
  - plum: #3A1A36 #5E2E58 #8A4E80 #B47EA8

A lane that wants other target ramps proposes them in its notes; the lead decides.

### The castle's rooms (cut-away)

| id | size | where | content |
|---|---|---|---|
| `hallFront` | 260x90 | x 1700, over `hallInterior` | the great hall's outer wall seen from the courtyard: stone, three tall windows with warm glass, the main door, two banners of the realm; its roof line and walls match `hallInterior` exactly |
| `chapelInterior` | 160x96 | x 1960, behind `chapel` | the chapel of the Flame: the eternal Flame in a stone bowl on the altar (fire anchor), pews, four lancet windows with stained glass at the existing `chapel` lancets (dx 18, 54, 89, 125, dy 28), candles, a carved relief of the lamplighter saint |
| `kitchenInterior` | 120x80 | x 2120, behind `kitchen` | the castle kitchen: a big oven-hearth (fire anchor), hanging pots and herbs, a table with bread, barrels, sacks, a cat on a stool; windows at the existing `kitchen` windows (dx 26, 79, dy 32) |

The existing `chapel` and `kitchen` sprites stay as the rooms' fronts; the art lane may repaint them (same size) so that
each interior's walls and roof line up with its front pixel for pixel. When the king steps inside a room its front
fades out (code lane), so the front's silhouette and the interior's must match.

### Props for the court

| id | size | frames | notes |
|---|---|---|---|
| `bench` | 32x10 | 1 | a petitioners' bench in the great hall |
| `taxLectern` | 12x20 | 1 | the tax lectern beside the throne (a book on a stand) |
| `marekCart` | 48x30 | 1 | Marek's cart in the courtyard on his days: goods, barrels, a striped awning |
| `statue` | 20x40 | 1 | a world change: a stone statue of the lamplighter king with his lantern, in the courtyard |
| `speakerMark` | 7x7 | 2 | a small speech mark over a court member who has something new to say (frame 1 pulses) |

## Look 2: the world (ART-look2.md 13.1, 14; in `SpriteID` since the look-2 port's contract step, 10.11.2026)

One frame each. Albedo, except: the fog banks, the mist band and the smoke are `#FFFFFF` alpha masks the engine
colours; sparks and fireflies are additive dots in the fire ramp; the far castle's glows and the slot's glows are
emissive strips. Where each stands is `tools/scenemock/layout_look2.py` (the mock is the reference) and
docs/PORT-look2.md 1.7. Look 1's sprites that look 2 no longer draws stay in the folder for `-GWLook 1`.

| id | size | plane | notes |
|---|---|---|---|
| `weltmauer` | 888x190 | far | the Weltmauer with the cleft cut twice (sprite x 324 from the shadow land, x 650 from the valley) and the far castle baked into each slot |
| `weltmauerPatch` | 52x190 | far | the unbroken wall over the second cleft until the camera is past the back gate |
| `farCastleGlow`, `farCastlePane` | 40x46 | far, emissive | the far castle's lit panes from the shadow land; its one pane from the town |
| `farCleftGlow`, `farCleftGlowBack` | 44x72, 44x68 | far, emissive | the slot's faint night light around each far castle |
| `d2FirBeltFar` | 520x40 | far | the low fir ridge at the wall's foot |
| `valleyVista` | 448x160 | far | the valley's three ranges of fir slopes |
| `shadowForest` | 224x104 | mid | the shadow land's forest edge (two copies join) |
| `gorgeRock` | 448x211 | mid | the Throat's granite face before the castle |
| `cleftFace`, `cleftFaceEnd` | 448x218, 240x218 | mid | the cleft's inner face behind the castle and its end toward the valley |
| `d2TreeBelt` | 520x58 | mid | the tree belt along the valley floor |
| `gorgeCrags` | 160x200 | near | five crags before the face's edge |
| `firA`, `firB`, `firC`, `firD` | 29x130, 30x118, 34x106, 27x84 | near | the shadow land's firs |
| `deadTreeA`, `deadTreeB` | 17x72, 17x70 | near | bare trees |
| `linden`, `poplar`, `appleTree`, `willow` | 52x92, 14x116, 42x48, 52x68 | near | the town's trees |
| `cleftFlank`, `cleftFlankB`, `cleftThroat` | 80x240, 80x240, 192x240 | world | the cleft's rock at the castle, in the shapes and places of `cliffFlank`, `cliffFlankB` and `throatRock` |
| `d2BushA`, `d2BushB` | 30x15, 22x12 | world, z -3 | bushes behind the actors |
| `d2LaneEnd` | 48x30 | world | the grassy bank where the lane ends at the river |
| `laneMoorA…D`, `laneScreeA…D`, `laneCobbleA…D`, `laneEarthA…D` | 64x26 each | world | the lane's tiles: moor from x -64, scree from 448, cobble from 1240, earth from 2430; the variant by a hash of the tile index |
| `d2FgFerns`, `d2FgMeadow`, `d2FgReeds` | 480x64, 480x58, 160x40 | foreground | the shadow land's ferns, the valley's meadow, the river's reeds |
| `d2FogBank`, `d2MistBand`, `d2FogLow` | 384x40, 448x60, 320x24 | fog A, mist band, fog B | the three fog banks, alpha masks |
| `d2Smoke` | 26x50 | world | chimney smoke, an alpha mask |
| `d2Fireflies`, `d2Sparks` | 96x30, 14x24 | world, additive | fireflies in the valley at dusk; a brazier's sparks |

## The castle grows (ART-look2.md section 15; in `SpriteID` since the contract step; drawing only, the upgrade logic is a later lane)

Three tiers. Tier 1 is today's castle, unchanged. Tiers 2 and 3 are sprites that stand with the existing ones; each
has a building state (`…Build`: timber scaffolds, ladders, a crane, half-laid courses) for the days the tier is under
construction. All are painted by `tools/castleart.py` (lane `castleTiers` of `build-art-world.sh`). F = 1240
(`castleFront`), K = 1286 (`keepTop`), B = 2230 (`castleBackGate`); y is px above the ground line; masks are
(dx, dy from the sprite's bottom, w, h) and light the `night1` panes like the layout's other window masks.

Up close the towers' crowns already reach the top of the view (y 172 of 178), so the castle cannot grow upward there.
It grows in what stands behind the wall walk (seen between the towers), in the mass of its towers, and, in full, in the
far view through the Weltmauer's slot.

| tier | from the Throat (the gate) | behind the back gate | far, from the shadow land | far, from the valley |
|---|---|---|---|---|
| 1 | `keepTop`, `castleFront` | nothing | baked in `weltmauer` | `farCastlePane` |
| 1, building | + `castleFrontScaffold` | | | |
| 2, building | `keepTop2Build` for `keepTop` | `backTop2Build` | `farCastle2Build` | `farCastleBack2Build` |
| 2 | `keepTop2` for `keepTop` | `backTop2` | `farCastle2` | `farCastleBack2` |
| 3, building | `keepTop3Build`, `castleFront3Build` for `castleFront` | `backTop3Build` | `farCastle3Build` | `farCastleBack3Build` |
| 3 | `keepTop3`, `castleFront3` for `castleFront` | `backTop3` | `farCastle3` | `farCastleBack3` |

| id | size | anchor | notes |
|---|---|---|---|
| `keepTop2` | 150x140 | (K, y 40), z −4, as `keepTop` | the keep one storey taller (its crown at y 164, was 144) with three lit windows under it, the flag, and a slim round tower at its left shoulder (crown at y 177). Masks (71,93,6,10), (120,94,5,9), (139,94,5,9), (23,109,2,7) |
| `keepTop2Build` | 150x140 | the same | the new storey half laid inside scaffolds, a crane hoisting a stone, the tower begun. No masks |
| `keepTop3` | 150x140 | the same | the second curtain wall (merlons at y 146, a corbel table under them, a banner) between two inner towers (crowns at y 177), the keep's crown and flag between them. Masks (71,93,6,10), (20,108,3,8), (122,108,3,8) |
| `keepTop3Build` | 150x140 | the same | tier 2's keep and tower stand; the wall half laid, the right inner tower half high in its scaffold with a crane. Masks (71,93,6,10), (23,109,2,7) |
| `castleFront3` | 268x236 | (F − 14, y 0), z 0 | `castleFront` with its two towers rebuilt as massive drums: shafts 60 px (were 43), crowns 72 px wide with deep machicolations, two string courses, battered plinths. The gatehouse, the gateway, the wall walk and the turrets are `castleFront`'s pixels, 14 px further right in the sprite: every emitter, light and hit box of `castleFront` keeps its world x (sprite dx + 14). The towers' slit masks move: (39,127,4,12), (39,93,4,12), (223,127,4,12), (223,93,4,12) replace `castleFront`'s four. The baked shadow of the left tower on the gatehouse still fits |
| `castleFront3Build` | 268x236 | the same | the left drum stands, the right one is half laid inside a scaffold with a crane (the sky shows over it). Masks (39,127,4,12), (39,93,4,12) |
| `castleFrontScaffold` | 240x236 | (F, y 0), drawn directly before `castleFront` (after the gate's leaves) | tier 1's building state and a spare for any gatehouse work: scaffold bays left and right of the gateway up to the wall walk, cut stones, a crane on the wall walk. Transparent elsewhere; it never covers the gateway (x 97 to 143) |
| `backTop2`, `backTop2Build`, `backTop3`, `backTop3Build` | 100x140 | (B + 50, y 40), z −4 (behind `castleBackGate`) | the same rise seen from the town above the back gate's curtain (visible between its towers, y 122 to 178). Masks: `backTop2` (22,94,5,9), (36,93,6,10), (52,94,5,9), (79,109,2,7); `backTop3` (46,93,6,10), (19,108,3,8), (77,108,3,8); `backTop3Build` (36,93,6,10), (79,109,2,7) |
| `farCastle2`, `farCastle2Build`, `farCastle3`, `farCastle3Build` | 48x48 | far plane: x = weltmauer x + 324 − 24, y = weltmauer y + 92 (the baked far castle's foot), drawn over `weltmauer` | the far castle grown, as a silhouette before the slot's light. The baked tier-1 castle lies inside it pixel for pixel, so the overlay only adds: the taller keep and its tower (2), the inner wall and two towers (3); the building states show lattices of poles and a crane's jib |
| `farCastleBack2`, `…2Build`, `…3`, `…3Build` | 48x48 | far plane: x = weltmauer x + 650 − 24, same y, drawn over `farCastlePane` with its fade | the same from the valley (mirrored) |
| `farCastle2Glow`, `farCastle3Glow`, `farCastleBack2Glow`, `farCastleBack3Glow` | 48x48 | at their far castle's place | the added lit panes (emitters like `farCastleGlow`, in addition to it). The building states have none |
| `farCleftGlow2`, `…2Build`, `…3`, `…3Build` | 44x72 | as `farCleftGlow` | the slot's night glow with that tier's castle cut out of it: it replaces `farCleftGlow` while the tier stands (otherwise the glow lies on the new towers) |
| `farCleftGlowBack2`, `…2Build`, `…3`, `…3Build` | 44x68 | as `farCleftGlowBack` | the same for the valley's view |

Notes for the code lane: tier 2 swaps one sprite at one anchor (`keepTop`); tier 3 swaps two and moves the front's
anchor 14 px left. The gatehouse's own tiers (gate, iron gate, great gate; DESIGN.md) can drive the castle's tier, or
the keep's upgrade can. The look-2 mock shows every state: `scene_look2.py … tier<1|2|3>[b]-<gate|back|far|farback>[-day]`.

## The weather (look 2 port, docs/PORT-look2.md 3; in `SpriteID` since 10.11.2026, painted in code until the art lane brings them)

| id | size | frames | plane | what |
|---|---|---|---|---|
| `rainStreak` | 7x11 | 9 | near, world, foreground | a streak of rain, pale blue-grey (`#C8D2E6`, the tail `#9CA8C2`). Frame = depth x 3 + slant. Depth 0 (behind the near trees) is 4 px long, depth 1 (over the lane) 7 px, depth 2 (before everything) 11 px and two pixels wide. Slant 0 falls straight, slant 1 runs 1, 2, 3 px to the right over its length (by depth), slant 2 runs 2, 3, 5 px; the engine mirrors it for a wind from the valley. Drawn at alpha 0.30, 0.40, 0.45. Each frame stands in the cell's top-left corner. |
| `rainSplash` | 5x3 | 3 | world | where a drop meets the lane: a dot, a small crown, two flecks flying apart. 0.3 s for the three frames. |

Still to come from the art lane, not in `SpriteID` yet (PORT-look2.md 3.3 and 3.4): `castleFlag` (the banners that fly
with the wind), `lanePuddleA` to `lanePuddleC` (the ruts' water after rain) and second frames for the foreground
strips `d2FgFerns`, `d2FgMeadow`, `d2FgReeds`. Until then the wind sways the trees, the foreground's plants and the
smoke as bands of their rows, and wet ground is the composite's sheen.

## The lord pass: the lady, both lords seated, the seated townsfolk (registered in `Core/FrameDesc.swift`)

Painted in the art pass of look 2 (ART-look2.md sections 15 and 16) and taken as painted by the lord pass (DESIGN.md
"The lord pass and the story pass"). `LordIdentity` (Core/Lord.swift) picks `king` or `lady` and their glow, seated
and portrait sprites by the player's choice of Burgherr or Burgherrin.

### The lady, and both lords seated

| id | size | frames | notes |
|---|---|---|---|
| `lady` | 16x30 | 10 | the Burgherrin: the same role, size, frames and anchors as `king` (walk 0-5, idle 6-7, command 8-9), a young woman with a dark plait, the same circlet, cloak and lantern pole. The player's choice of form swaps `king` for `lady` everywhere |
| `ladyGlow` | 16x30 | 10 | as `kingGlow`, pixel for pixel the same positions |
| `kingSeated` | 16x30 | 4 | the lord on the hall's `throne`: sit down 0-1 (standing up is 1, 0), seated idle 2-3 (a breath). Drawn like the walking sprite: centred on x, feet on the ground line; place it at the throne's centre (x 1837), over the throne. Seated he is drawn turned to the right like the walking sprite (his back at the throne's back, the thighs on the cushion, the shins before the seat's front, the hand on the lantern pole behind his knee; the throne's posts, arm rests and cushion show around him, so the `throne` must be drawn under him): mirror the frame to turn him to the speaker. The throne stands on the middle of the dais since the lord pass (centre x 1837, the prop's left edge 1830; ART-look2.md 16); the simulation's `Realm.throneX` (1824, where a new lord starts and the bot sends him) did not move |
| `kingSeatedGlow` | 16x30 | 4 | the lantern glass does not move in the four frames: the light at (+5.5, 22.5) from the frame's centre and the ground |
| `ladySeated`, `ladySeatedGlow` | 16x30 | 4 | the lady's, frame for frame the same |
| `portraitLady` | 48x48 | 1 | the lady's story portrait, the pair of `portraitKing` (which now shows the young lord) |

### The townsfolk seated on the hall's benches

| id | size | frames | notes |
|---|---|---|---|
| `citizenSeated`, `citizenBSeated`, `citizenCSeated` | 12x22 | 2 each | the three townsfolk waiting on a petitioners' `bench` (32x10): seated 0, a nod 1 (swap every few seconds, not a loop). The frame's bottom stands on the floor like the bench's; draw the bench first and the sitter over it (the cushion is the frame's rows 13 and 14). A bench seats two (the frames' left edges at bench x +2 and +18) or three (+0, +10, +20). They face the hall like the seated lord, the head in profile to the right: mirror the frame for a bench right of the throne. The walking townsfolk (`citizen…`, 12x26) keep standing where no bench is free |

In the game: the lord sits from the moment an audience opens before the throne (frames 0 and 1 over the first 0.4 s,
then the breath 2 and 3; with Reduce Motion the breath's first frame at once) and is mirrored to face the petitioner
on the audience spot. Townsfolk whose body is `citizen`, `citizenB` or `citizenC` wait seated on the benches (two to
a bench, the frames' centres at bench x +8 and +24), everyone else stands as before; whoever is called stands up and
walks.

## Proposals of the art pass (look 2, stage 4; ART-look2.md section 15)

Everything under this heading is a **proposal for the code lane**: the PNGs lie in Resources/Art and
`tools/build-art.sh` rebuilds them, but no Swift names them yet. Sizes, frames and anchors are what the art was painted
to; the code lane may take them as they are.

The lady, both lords seated and the seated townsfolk are registered since the lord pass: see "The lord pass" above.
The castle's tiers are registered since the look-2 port: see "The castle grows" above.

The archer, the guardsman, the builder and the three townsfolk were repainted at their sizes, frames and frame
meanings. Two anchors moved by a pixel: the archer's arrow lies on the frame's row 9 (was 10) and leaves at the right
edge (col 11); the guardsman's spear tip at the thrust (frame 7) stays at col 13, row 11.

### The town at night, the square's props (look 2, stage 6; ART-look2.md section 18)

The five lit-room sprites are **registered and drawn since the round 2 join** (10.11.2026): `EntityFrames.litRooms`
gives a town house its lit rooms in look 2, one emissive part of the house's size (`mirrors: true`, fading by day)
in place of its glass masks; look 1 keeps the masks. Since the polish after round 2 the rooms flicker softly: 0.4 of
a fire's flicker (± 6 %) at 0.35 of its pace, every house with its own seed (`EmissivePart.flickerAmount` and
`flickerPace`; with Reduce Motion ± 1.5 %).

`hayCart`, `barrels` and `noticeBoard` are **registered and placed since the polish after round 2** (10.11.2026;
look 2 only, world plane, z 1: behind the actors like the well, no collision). The notice board stands at world
2990 (left of the well, where the townsfolk stop at 3010), the hay cart at 3040 (right of the well, before house 5);
both are scene entries (`SceneLayoutLook2.swift`). The barrels stand with the tavern, 28 px left of its plot (3292,
in the gap between the market and the tavern; `EntityFrames.town`). A plain wooden mass stands in for each while its
PNG is missing (`PlaceholderPolish.woodStandIn`).

| id | size | frames | notes |
|---|---|---|---|
| `houseLit`, `houseBLit`, `houseCLit` | 64x46 | 1 | the cottage's lit rooms: an emissive sprite of the house's size, clear but for the window glass inside the house's masks. Each window shows a room (a wall that is brightest near its candle or hearth, a curtain, a shelf, a table, a cat on the sill; people are shapes left dark). Draw it over the house as `.sprite(<id>Lit, dx: 0, dy: 0, glow: .fireWhite, fades: true)` **in place of** the house's `.mask` emitters (with both, the glass doubles); mirror it with a mirrored house. The window lights (`li`) stay |
| `bigHouseLit` | 72x56 | 1 | the big house's five windows the same way (a standing figure under a hanging lamp, rose curtains, a table with a candle, the kitchen's banked fire, the dormer) |
| `tavernLit` | 90x56 | 1 | the tavern's: three guest rooms above (linen, a low fire, a guest at the window), the taproom below (two drinkers over a candle; a lamp, the innkeeper, the kegs), the door lantern's flame (the mask (32,10,1,2)), and one row of light on the step under the door (dx 36 to 43, dy 1): the only pixels outside the glass |
| `hayCart` | 40x24 | 1 | a two-wheeled hay cart at rest on its prop, the shafts to the left: a prop for the square or a lane (ground line at the frame's bottom, no collision) |
| `barrels` | 26x14 | 1 | two standing barrels (a pewter mug on the bigger one) and a third lying end on: beside the tavern or the market |
| `noticeBoard` | 20x26 | 1 | the lord's notice board: two oak posts, a board with four notices under a small slate roof in the realm's teal. A place for the day's news (a decree, a recruit call) if the code wants one |

### Two more paintings of every town tree (look 2, stage 6; ART-look2.md section 18)

**Registered and planted since the round 2 join** (10.11.2026; `SceneLayoutLook2.swift`, the planting below; the
young `willowB` stands between the two willows since the polish after round 2: near x 2832, behind world 3738,
z 1, before them). Each lies on its first painting's canvas with the trunk at the canvas centre and the foot on the
bottom row, so it takes the first painting's place at the same trunk x, flipped or not; a shorter tree has clear rows
on top. Near plane, 1 frame, no masks, no emitters; they sway as their first painting does (`willowB` and `willowC`
in their lower half). `tools/treeart.py` paints them.

| id | size | the tree stands in | notes |
|---|---|---|---|
| `lindenB` | 52x92 | rows 0 to 91, x 4 to 46 | a slim, tall linden: an egg-shaped crown on a thin trunk |
| `lindenC` | 52x92 | rows 20 to 91, x 0 to 51 | an old, broad linden with a low crown on a thick trunk, 72 px high (20 px lower than `linden`) |
| `poplarB` | 14x116 | rows 17 to 115 | a younger poplar, 99 px high and fuller in the belly |
| `poplarC` | 14x116 | rows 1 to 115 | a lean poplar with a notch in its flank, its tip bent to the right |
| `appleTreeB` | 42x48 | rows 3 to 47 | a flat, wide crown on two stems that wind round each other |
| `appleTreeC` | 42x48 | rows 0 to 47 | a round crown on a bent trunk, seven red apples in it |
| `willowB` | 52x68 | rows 14 to 67, x 5 to 47 | a young willow, 54 px high, its strands short of the ground |
| `willowC` | 52x68 | rows 0 to 67 | an old willow: a thick, bent trunk, the curtain down to the water |

A planting that never shows the same painting twice side by side (trunk world x; the flips stay as they are):
2466 `appleTree`, 2548 `appleTreeB`, 2624 `lindenC`, 2690 `appleTreeC`, 2741 `appleTree`, 2868 `poplar`,
2884 `poplarB`, 2992 `linden`, 3170 `poplarC`, 3186 `poplar`, 3300 `lindenB`, 3448 `appleTreeC`, 3523 `appleTreeB`,
3610 `lindenC`, 3684 `willow`, 3790 `willowC`, and a young `willowB` between them at 3738 if the river bank may
carry a third.

### The old walls in the Throat, the tiers' anchors (look 2, stage 7; ART-look2.md section 19.1)

**Registered and placed since the polish after round 2** (claude/lh-polish), as proposed here: the six ids are
`SpriteID` cases after the square's props; `oldWall2`, `oldWall3` and `oldWall1` are entries of `SceneLayout.look2`
(always drawn, also in game mode), a tier's anchor is drawn by `EntityFrames.wall` while `plot.item` is that tier
(`EntityFrames.wallAnchor`). Look 2 only. The PNGs lie in Resources/Art, `tools/build-art.sh` rebuilds them
(`tools/throatart.py`, in the world lane). All six are props of the **world plane**, one frame each, lit like any
building, without emitters. No existing id, size or frame count changed.

| id | size | frames | notes |
|---|---|---|---|
| `oldWall2`, `oldWall3` | 128x108 | 1 | the place of the middle line (line 2, `wallX` 940) and of the outer line (line 3, `wallX` 640) as it lies before anything is built: two masses of the Throat's granite (a horn on the Gloom's side, a pillar on the castle's) and the saddle between them, across it the broken courses of Lady Oriel's wall and the stub of its end tower, fallen blocks, the old footing in the track, scree. The wall's left edge is sprite x 28, the ground line 8 rows above the bottom: `props.add("oldWall<line>", x: wallLeft - 28, y: -8, z: -2)`. **Always drawn** (empty plot, job, tier, rubble): it is the place |
| `palisadeAnchor`, `stoneWallAnchor`, `bastionAnchor` | 128x108 | 1 | what the builders add with a tier: its footing across the track (the 8 rows under the ground line: a bank of earth with the stakes' butts; two courses of ashlar) and its end piece at the pillar (a return of three stakes lashed to the old stub; an end tower of ashlar toothed into the granite, 69 px high; the bastion's 81 px with a corbelled crown). Same canvas and origin: `x: wallLeft - 28, y: -8, z: -1`, over the old wall, behind the tower (z 0) and the tier (z 1). Drawn **while a tier of that kind stands at the line**: whole, damaged, as rubble, and under the scaffold of the upgrade that replaces it |
| `oldWall1` | 84x60 | 1 | what is left of Oriel's first line before the gatehouse: a stretch of broken wall, half a tower, blocks. Scenery, not a plot state (line 1's plot is the gate and is never empty): proposed at `x: 1150, y: -8, z: -1`, clear of the trap plot at 1220. The ground line is 8 rows above the bottom here too |

- The saddle between the two masses stays open above the walk on purpose: the watch on the wall keeps the mist
  behind it (that is what an archer reads against at night). Both end towers begin right of the last archer's place.
- A tower on the line's tower plot (z 0) stands before the end piece; a stone tier's end tower is higher than the
  timber towers and shows above them.
- The braziers, the traps and the engines keep their places; the horn stands behind the braziers' ground.

### The Gloom's fog (look 2, stage 7; ART-look2.md section 19.2)

**Proposals for the code lane** (claude/lh-polish): the PNGs lie in Resources/Art, `tools/build-art.sh` rebuilds them
(`tools/gloomart.py`, in the world lane), no Swift names them yet. `darknessBank`, `darknessEdge` and
`darknessBankGlow` are untouched and keep working. All five use world parallax; every anchor is the sprite's
bottom-left at the given y (0 = the ground line). E is `DarknessBank`'s edge.

| id | size | frames | notes |
|---|---|---|---|
| `gloomFogBack` | 192x120 | 2 | the bank: six rows of low rolls, pale crests, a heart that darkens to night toward the lane. Frame 0 repeats seamlessly, frame 1 is the leading face (its left column goes on from frame 0). y 0. Drawn **behind the world plane** (after fog layer A), at least behind every creature. Front at E + 64 |
| `gloomFogEyes` | 64x72 | 4 | the cold eyes in the bank's heart, an **emissive** only (like `darknessBankGlow`): nine pairs, each shut in one frame. y 0, on the 64 px tiles the bank's glow uses today (tile k's right end at E - 32 - 64k), frame `(k + Int(time * 1.5)) % 4`, strength 1. Drawn after the back strip, before the creatures |
| `gloomFogMid` | 160x64 | 2 | a thin veil **before the world plane** (creatures, walls), built like the bank. y 0. Front at E + 104 |
| `gloomFogFront` | 128x30 | 2 | the fog creeping along the lane, before the veil. y -8 (its lowest 8 rows lie under the ground line). Front at E + 136 |
| `gloomWisp` | 40x16 | 6 | a shred that tears off the front; the six frames are its life, frame 0 whole, frame 5 two flecks. Drawn with the front strip |

- **Laying a strip:** frame 1 at `x = front - width`, frame 0 at `front - 2 * width`, `front - 3 * width` ... to
  the screen's left edge. Face and tiles move together (the face does not slide against its body).
- **Drawing:** unlit. The paint is the fog's own night colour at flat alpha levels (no dither): plain alpha-over,
  not multiplied by the ambient. The light cuts holes: the strip's alpha and colour are scaled by
  `h = 1 - 0.9 * smoothstep((light - 0.06) / 0.5)`, light = the strongest channel of the light buffer at the pixel.
  A torch, a brazier or the lord's lantern then stands in a clear pool and the fog closes around it.
- **Motion:** the three fronts breathe against each other, e.g. back ±3 px in 9 s, veil ±6 px in 7 s, front ±10 px
  in 5 s, out of phase. A wisp is born every 3 to 5 s at the front strip's nose (x about E + 126, 6 to 30 px above
  the lane), drifts ahead at about 6 px/s and 1 px/s up, plays its six frames once in about 4 s and is gone.
- **Creatures** keep their spawn at the edge. They stand behind the veil and the creeping fog until E + 104 and
  E + 136, so they step out of the fog without any change to them.
- **When:** the strips fade in while the bank swells (19 to 20 h), lead the advance through the night and thin away
  at dawn. By day the bank rests as it does today.
- **The old wall:** while the fog is up, the opaque `darknessBank` and `darknessEdge` tiles should not be drawn (they
  are as high as the screen and would stand in the fog as a slab); by day they can rest as today. The fog is
  120 px high, not the screen's height: the gorge stays visible above it.
- **Wired** (claude/lh-polish, DESIGN.md "Polish after round 2", point 1): as proposed, with three changes. The
  fronts follow the night's hardness (`GloomFog`): the bank's at 0.43 of the fog's way past E, the veil's at 0.7,
  the creeping fog's at the whole way (64, 105 and 150 px on the first night, 172, 280 and 400 on the hardest). The
  holes are cut by rule, not from the light buffer: every fire that counts in battle takes up to 0.85 of the fog in
  16 px slices (`GloomFog.clearing`, `hole`). The single pairs of `eyeGlints` still roam the fog in front of the
  painted eyes.

### The house envoys (look 2, stage 7; ART-look2.md section 19.3)

**Proposals for the code lane** (claude/lh-polish): the PNGs lie in Resources/Art, `tools/build-art.sh` rebuilds them
(the court lane, `tools/build-art-court.sh`), no Swift names them yet. The bodies have the guests' size and frames
(`envoy`, `herald`): 14x30, 8 frames, walk 0-3, idle 4-5, talk 6-7, facing right, the feet on the bottom row, no
glow strip. The portraits are story portraits like `portraitEnvoy`: 48x48, one frame, fixed colours (no swap ramp,
no emissive), three-quarter right, lit from the left.

| id | size | frames | notes |
|---|---|---|---|
| `hildVarn` | 14x30 | 8 | Hild Varn of Cairnwatch, twenty: a brown braid with a green tie, a mail shirt under Varn's green surcoat with the cairn, a sword on the far hip. Idle: her hand on the pommel. Talk: her fist to her chest (6), she points ahead (7) |
| `lorenzPell` | 14x30 | 8 | Steward Lorenz Pell of Oxmoor: a red cap with a white feather, a black moustache, a ruff, a coat in Oxmoor's red with gold cuffs, sash and hem, a purse. Idle: the hands folded over the belly. Talk: he holds out the gilded lamp (6), then the paper to sign (7) |
| `ebbaCalder` | 14x30 | 8 | Auditor Ebba Calder of Blackwater: tall and narrow, black hair in a tight bun, a long blue-black coat with a white collar and silver buttons, a writing board and a white quill. Idle: the quill over the sheet. Talk: she writes (6), then points the quill at the lord (7) |
| `orlaLorn` | 14x30 | 8 | Dame Orla Lorn of Greybell, past eighty, **and her great-grandchild in the same frame**: she is bent, a white bun, a grey shawl, a robe in Lorn's plum, her hand on the child's shoulder; the child before her carries her tall stick. Talk: she points at the lord over the child's head (6), then nods (7) |
| `portraitHildVarn` | 48x48 | 1 | the brown hair drawn back, the braid over the near shoulder with its green tie, freckles, a mail collar, the green surcoat with the cairn |
| `portraitLorenzPell` | 48x48 | 1 | the red cap with its brooch and feather, black hair, a thin moustache, a smile, a pleated ruff, the red coat, a gold chain with a medal |
| `portraitEbbaCalder` | 48x48 | 1 | black hair in a knot, a white quill behind the ear, brown skin, a level look, a standing white collar, the blue-black coat with silver buttons |
| `portraitOrlaLorn` | 48x48 | 1 | white hair in a knot, a lined face, a small smile, a grey shawl, the plum robe with a silver bell at the throat |

- **Wiring** (`Core/CourtSpeakers.swift`): the four `house(…)` speakers become guests like the envoy, for example
  `Speaker(id: "hildVarn", role: .guest, body: .court(.hildVarn), portrait: .portraitHildVarn, nameKey: …, roleKey: …)`;
  the stand-in bodies (`guardsman`, `petitionerE`, `petitionerD`, `citizen`) and the composed styles fall away. The
  bodies need `FrameDesc` entries like the envoy's (8 frames of 14x30).
- Brine's face stays the existing `envoy` and `portraitEnvoy`.
- Orla's sprite is as wide as the others (14 px), so she and the child stand close; a child of its own that walks
  beside her is open.
- **Wired** (claude/lh-polish, DESIGN.md "Polish after round 2", point 5): as proposed. The four are guests with
  `.court` bodies and their own portraits (`Speakers.house`); the composed styles and the stand-in bodies are gone.
  They wait standing (a court body has no seated strip), so Dame Orla no longer takes a bench.

### The houses' banners (look 2, stage 7; ART-look2.md section 19.3)

**Proposals for the code lane** (claude/lh-polish): `tools/bannerart.py` (the court lane of `tools/build-art.sh`),
no Swift names them yet. Props of the **world plane**, one frame each, lit like the hall, without emitters.

| id | size | frames | arms |
|---|---|---|---|
| `bannerVarn` | 20x41 | 1 | a grey cairn on green |
| `bannerBrine` | 20x41 | 1 | a white wave on sea blue |
| `bannerOxmoor` | 20x41 | 1 | a golden sheaf on red |
| `bannerCalder` | 20x41 | 1 | three silver fish on black |
| `bannerLorn` | 20x41 | 1 | a grey bell on plum |

- **Places:** `hallInterior` (260x90, at world x 1700) has five banners of the realm painted between its columns. A
  house's banner hangs over one of them and hides it completely. The sprite's left edge is at hallInterior x
  **44, 83, 121, 158, 195**, its top at row 24, so the entry is
  `Entry(sprite: .banner<House>, x: 1700 + left, y: 25, z: -1)`: above the interior (z -2), behind the throne (z 1).
- **Which banner where** (proposal, left to right): Brine, Calder, Varn, Lorn, Oxmoor. Varn's hangs in the middle,
  over the throne.
- **When:** a banner is drawn while its house stands with the lord (the flags `varn_with`, `brine_with`,
  `oxmoor_with`, `calder_with`, `lorn_with`); otherwise the realm's painted banner shows at that place.
- `hallFront` (z 2) covers them like the rest of the interior; they hang inside the room's box, so the hall's
  light falls on them. No light of their own.
- **Wired** (claude/lh-polish, DESIGN.md "Polish after round 2", point 5): places, order and z as proposed
  (`CourtFrames.houseBanners`, `houseBannerY`), with one change to the "when": a house's banner hangs once the lord
  has had the banners hung (the world change `castle.hall.banners.houses`, which `tithe_letters` sets on day 16,
  STORY.md section 5) and the house stands with him (its `_with` flag). The realm's renewed banner (`hallBanner`,
  z 1) is left out at a place where a house's banner hangs. `-GWHouses` hangs them for shots.
