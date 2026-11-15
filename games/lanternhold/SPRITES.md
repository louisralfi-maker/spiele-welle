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
| `darknessBankGlow` | 9x3 | 4 | the darkness bank's eyes; since the world rebuild's fix round 1 one pair in four frames, placed by `FrameBuilder.bankEyePairs` (see "The rock and the fog"). It was a 64x236 strip of eyes and embers over each `darknessBank` tile |

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
| `gorgeRock` | 448x211 | mid | the Throat's granite face before the castle (retired by the world rebuild: `tools/retired-art`, the old walls' granite) |
| `cleftFace`, `cleftFaceEnd` | 448x218, 240x218 | mid | the cleft's inner face behind the castle and its end toward the valley (retired by the world rebuild) |
| `d2TreeBelt` | 520x58 | mid | the tree belt along the valley floor |
| `gorgeCrags` | 160x200 | near | five crags before the face's edge (retired by the world rebuild) |
| `firA`, `firB`, `firC`, `firD` | 29x130, 30x118, 34x106, 27x84 | near | the shadow land's firs |
| `deadTreeA`, `deadTreeB` | 17x72, 17x70 | near | bare trees |
| `linden`, `poplar`, `appleTree`, `willow` | 52x92, 14x116, 42x48, 52x68 | near | the town's trees |
| `cleftFlank`, `cleftFlankB`, `cleftThroat` | 80x240, 80x240, 192x240 | world | the cleft's rock at the castle, in the shapes and places of `cliffFlank`, `cliffFlankB` and `throatRock` (retired by the world rebuild: nothing stands on the walk line) |
| `d2BushA`, `d2BushB` | 30x15, 22x12 | world, z -3 | bushes behind the actors |
| `d2LaneEnd` | 48x30 | world | the grassy bank where the lane ends at the river |
| `laneMoorA…D`, `laneScreeA…D`, `laneCobbleA…D`, `laneEarthA…D` | 64x26 each | world | the lane's tiles: moor from x -64, scree from 448, cobble from 1240, earth from 2430; the variant by a hash of the tile index |
| `d2FgFerns`, `d2FgMeadow`, `d2FgReeds` | 480x64, 480x58, 160x40 | foreground | the shadow land's ferns, the valley's meadow, the river's reeds |
| `d2FogBank`, `d2MistBand`, `d2FogLow` | 384x40, 448x60, 320x24 | fog A, mist band, fog B | the three fog banks, alpha masks (repainted by the world rebuild: feathered tiles that overlap by 64 px) |
| `d2Smoke` | 26x50 | world | chimney smoke, an alpha mask |
| `d2Fireflies`, `d2Sparks` | 96x30, 14x24 | world, additive | fireflies in the valley at dusk; a brazier's sparks |

## The castle grows (ART-look2.md section 15; in `SpriteID` since the contract step; drawing only, the upgrade logic is a later lane)

**World-2 (15.11.2026): only `castleFront3`, `castleFront3Build` and `castleFrontScaffold` of this table are still in
the game.** The keep's copies (`keepTop2/3`, `backTop2/3`) and the far castles with their glows are retired
(`tools/retired-art`); the castle grows as one building in "One castle" below.

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
| `gloomFogEyes` | 64x72 | 4 | (not drawn since the world rebuild's fix round 1: with the bank's sheet lower its pairs stood above it in rows 64 px apart; the bank's own eyes stand in the fog instead) the cold eyes in the bank's heart, an **emissive** only (like `darknessBankGlow`): nine pairs, each shut in one frame. y 0, on the 64 px tiles the bank's glow uses today (tile k's right end at E - 32 - 64k), frame `(k + Int(time * 1.5)) % 4`, strength 1. Drawn after the back strip, before the creatures |
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

### The circlet icon (look 2, stage 7; ART-look2.md section 19.4)

**Proposal for the code lane** (claude/lh-polish): `tools/iconart.py` (the court lane of `tools/build-art.sh`), no
Swift names it yet. Interface art, not world art: no plane, no light, no anchor. It stands where the drawn
`CircletIcon` stands, centred.

| id | files | art size | frames | for |
|---|---|---|---|---|
| `circletIcon` | `circletIcon.png` (24x16), `circletIcon@2x.png` (48x32), `circletIcon@3x.png` (72x48) | 24x16 | 1 | gold, for dark grounds: the HUD's action button (the `.throne` glyph) |
| `circletIconInk` | `circletIconInk.png`, `circletIconInk@2x.png`, `circletIconInk@3x.png` (the same sizes) | 24x16 | 1 | ink alone, the stone cut out: the gold "End the audience" button of the audience card |

- **Sizes:** the 2x and 3x files are the 1x file with every art pixel a square of 2x2 and 3x3. The circlet fills
  all 24 columns and rows 2 to 13 of 16, so the image's frame is the layout box.
- **Where:** `CircletIcon(size: 46)` in `UI/HUDView.swift` becomes `circletIcon` at **48x32 pt** (2 pt per art
  pixel, the world's pixel size on the phone); `CircletIcon(size: 24)` in `UI/AudienceCardView.swift` becomes
  `circletIconInk` at **24x16 pt** (1 pt per art pixel). If either should be bigger, the next size is the next whole
  multiple (72x48 pt, 48x32 pt), never one between: a part pixel blurs or drops rows.
- **How**, two ways, the code lane's choice:
  - the three files lie loose in the bundle, so `UIImage(named: "circletIcon")` takes the file for the screen and
    gives a 24x16 pt image with hard edges; the card draws it as it is, the HUD with
    `.resizable().interpolation(.none).frame(width: 48, height: 32)`;
  - or as a `SpriteID` through `SpriteImages.image(_:frame:)`, as `PortraitTile` draws the portraits. That reads
    the 1x file alone; the `@2x` and `@3x` files may then stay out of the bundle.
- **States:** the held button's `.opacity(0.45)` and `.saturation(0.2)` work on the image as on the shape.
  `iconColor` no longer tints the throne glyph, the icon has its own colours. `circletIconInk` is one colour, so
  `.renderingMode(.template)` gives it any tint.
- `CircletShape` and `CircletIcon` in `UI/Theme.swift` fall away.
- The gold icon uses `fireGold` and `fireWhite` (the lit rim, one glint). It is never drawn in the lit world, so
  the rule that albedo keeps off the fire ramp does not touch it.
- **Wired** (claude/lh-polish): both are `SpriteID`s (`circletIcon`, `circletIconInk`, 24x16, one frame) and come
  through the atlas and `SpriteImages.image(_:frame:)`. `CircletIcon(scale: 2)` in `UI/HUDView.swift` draws the gold
  one at 48x32 pt without a tint; `CircletIcon(ink: true)` in `UI/AudienceCardView.swift` draws the ink one at
  24x16 pt as a template in the button's ink. `CircletShape` is gone. The `@2x` and `@3x` files lie unused in the
  bundle.

### The great hall as a stage (look 2, stage 8; ART-look2.md section 20)

**Proposals for the code lane**: the PNGs lie in `Resources/Art`, `tools/build-art.sh` rebuilds them
(`tools/hallart.py`, the court lane), no Swift names them yet. Louis on 10.11.: the throne room "much bigger", the
picture at the craft of the great pixel-art kingdoms. `hallInterior` (260x90) and every id above stay as they are.

| id | size | frames | notes |
|---|---|---|---|
| `greatHall` | 600x201 | 1 | the whole hall, 2.3 times as wide and 2.2 times as tall as `hallInterior`. Albedo, opaque but for the window lights (transparent: the night and the Weltmauer show through). It fills the view's height: 175 rows above the floor line, 26 below, like the world. The realm's banner at every second banner place (137, 253, 368), a two-candle wall sconce at the other two (220 and 336, row 100; fix round 1 of stage-1). The camera shows x 10 to 590 only (the end strips are never seen). Fix round 2: the dais is a raised platform at the back (its top rows 154 to 165, its 9 px front face rows 166 to 174 standing on the walk line; the steps' treads and risers likewise), the nave's flags run on below the walk line under its whole length; the runner ends at the foot of the steps with a gold fringe, a rug lies on the dais before the throne (x 380 to 439, rows 158 to 164); the chandeliers hang 10 px lower (wheel at row 53) |
| `hallPillarNear` | 30x201 | 1 | a pier of the near arcade: a round shaft of drums (14 px), a capital with its abacus, the springers of two arches, a moulded base on a plinth (fix round 1 of stage-1: two thirds of the old 46 px). Fix round 2: evenly lit (darker edges both sides, no baked key), the drums' joints in `stoneDark` with a lit lip under each; the engine lays the key light on it. Drawn in front of everything at parallax 1.25 in the hall's shade (0.9 of its ambient), with a soft band of light 4 px wide on its key side (the window's by day, the torches' at night), thin rims on its edges, a ramp darker toward the roof and a dithered window where the lord stands behind it (the composite, `InteriorLight`); one only, at hall x 150 |
| `hallFire` | 204x28 | 6 of 34x28 | the great hearth's fire, emissive, on the fire ramp. Bottom row on hall row 145, centred on x 532. About 8 frames a second |

**The hall's parts** (hall px, x from the hall's left edge, rows from its top; a thing "stands on row r" when its
lowest row is r − 1):

| what | where |
|---|---|
| floor line of the nave (the walk line, on the long carpet) | row 175, x 14 to 363 (the runner ends at 363 with a gold fringe; below row 175 the nave's flags run on to x 589 under the dais, fix round 2) |
| wall line of the nave (benches, guards, the waiting) | row 169 |
| the door (leads out) | opening x 49 to 87, from row 110; a torch each side (x 38 and 98) |
| the gallery over the door | x 14 to 122, its rail rows 80 to 95; a window behind it |
| benches (`bench`, 32x10) | centred on x 184 and 300, under the two tall windows; three seats each (centre − 11, centre, centre + 11 since fix round 2), the seated townsfolk on row 169. Fix round 2: everyone waiting sits, behind the bench's front: the engine draws the benches again as actors over who sits (after the wall line, before the walk line); a body without a seated strip stands 5 px lower with its rows below the wall line cut off (`ActorInstance.cropBottom`) |
| candle stands (painted in) | x 160, 208, 276, 324: one each side of a bench |
| dais steps | x 364 to 375: three treads of 4 px, 3 px high each, from the back wall to the walk line, each with its riser on the walk line (fix round 2) |
| the dais | x 376 to 589, raised 9 px: its floor line is row 166; its front face rows 166 to 174 on the walk line (fix round 2: no longer down to the hall's bottom) |
| the throne (`throne`, 14x24) | centred on x 416, on row 166, under the cloth of estate (x 398 to 434); the seated lord faces left, down the hall |
| court places (row 166) | the tax lectern x 385, Odile x 397 (between lord and nave), Brannock x 441 (under the arms), Hesper x 497 (at the hearth); Pip x 350 at the foot of the steps, on row 171 (the petitioner passes in front of him) |
| the petitioner's walk | in by the door, along row 175, stops at x 338; the one after him rises from his bench |
| guards | x 37 and 100, row 169, facing the door |
| the hearth | x 492 to 572, the hood up to the roof; the firebox x 508 to 556 |
| banner places | left edges x 137, 211, 253, 327, 368, top row 62: the realm's teal banner is painted there in the houses' outline (20x41), so a house's banner drawn at the same place covers it whole |
| windows (transparent lights) | two tall ones x 169 to 199 and x 285 to 315, rows 58 to 130; one over the gallery; a round one over the throne (centre 416, 45); two slits beside the hearth |

**Fire and light anchors** (`python3 tools/hallart.py anchors greatHall` prints them all): the hearth fire (532, 145)
with its light at (532, 128), radius 120; two chandeliers of six candles, light at (184, 49) and (300, 49) since fix
round 2, radius 64; four stands of three candles, light at (x, 141), radius 26; the door torches (38, 116) and (98, 116), radius 34;
four candles on the mantel, two under the arms (456, 123), two on the gallery's newels.

**The light is the state of the realm**, not decoration:

- the hearth's pool grows with the hearth's strength (radius about 60 + 60 × strength; below a third the small
  `hearthFire` burns instead of `hallFire`);
- a stand burns beside a bench while someone waits on it; an empty hall has dark stands;
- the chandeliers burn while the court sits (the audience hours), and go out for the night;
- the door torches burn from dusk; the lord carries his lantern as everywhere.

**Layers**, back to front: the night sky and `weltmauer` (parallax about 0.3, seen through the window lights) ·
`greatHall` · the houses' banners · the wall line (benches, the seated, guards) · the dais' props (throne, lectern) ·
actors by their floor row · flames and glow strips · `hallPillarNear` · the interface.

- The near pillars stand over the wall shafts at x 126 and 242 when the camera is centred on them: a pillar of hall
  x `p` is drawn at screen centre + (`p` − camera centre) × 1.25, with `p` = 161 and 254. In the audience framing
  both are off the screen's left edge, so nothing ever stands before the throne.

**The hall is a stage of its own.** The world's slot (x 1700 to 1960) is too small for it. The lord taps the hall's
door in the world, walks to it, the screen fades through dark (Reduce Motion: a cut) and he stands inside at the
door. The door inside leads back.

- **Walking in the hall:** the world's scale (6 device px per game px, a view of 437x201); the camera follows the
  lord and stops at the hall's ends (camera x 0 to 163).
- **The audience framing** (the lord sits): 8 device px per game px, a view of 328x151 with its left edge at hall
  x 232 and its top at row 50. The hall fills the screen from the bench window to the hearth, the characters stand
  80 pt tall instead of 60. The move in takes about 0.6 s, eased (Reduce Motion: a cut).
- **The audience card over it** (a proposal, since today's card fills the lower half and would cover the stage): the
  letter (portrait, name, role, request, Odile's slip) lies in the upper left over the wall and the window, about
  364x226 pt; the choices lie as plaques along the floor band below the walk line. Petitioner, lord and hearth stay
  in sight.

**Texture space.** The atlas page stands at 2048x1788: 260 free rows. The hall (201 rows and its padding) would just
fit and close the page for good. So the hall's three sprites and the tap marks below go on a **second page of
1024x256** (DESIGN.md's budget allows two pages): `greatHall` at (0, 0), `hallPillarNear` beside it, `hallFire`
and the marks in the 376 columns that remain. It costs 1 MB as RGBA and leaves page 1 its rows for the world.

**Open, for the lead:** whether the world still shows the small cut-away (`hallInterior`) from the street once the
stage exists, or the hall's closed front.

### The marks of "touch the world" (look 2, stage 8; ART-look2.md section 20)

**Proposals for the code lane**: `tools/hallart.py` (the court lane of `tools/build-art.sh`), no Swift names them
yet. They replace the action button (DESIGN.md "Controls 2: touch the world"). A mark is a small parchment tag in
the interface's ink and gold (docs/UI-look.md) that floats above a thing the lord can touch.

| id | size | frames | above |
|---|---|---|---|
| `tapTalk` | 30x18 | 2 of 15x18 | a speech bubble: a petitioner who waits, a member of the court or a townsman with a word |
| `tapThrone` | 30x18 | 2 of 15x18 | the circlet: the empty throne, when an audience can be held |
| `tapBuild` | 30x18 | 2 of 15x18 | a hammer: an open plot, a building that can grow |
| `tapRepair` | 30x18 | 2 of 15x18 | a wall with a wax-red crack: a damaged wall or building |
| `tapRecruit` | 30x18 | 2 of 15x18 | a head and shoulders with a plus: where the lord can recruit |
| `tapLight` | 30x18 | 2 of 15x18 | a flame: a cold brazier |
| `tapDoor` | 30x18 | 2 of 15x18 | an arched door of planks with its gold ring: the great hall's door in the world and its inner door (stage lane, step stage-2, 15.11.2026) |

- **Frames:** 0 idle (parchment in a gold rim), 1 pressed (the plaque a step darker, the rim dull). Pressing
  darkens the plaque, nothing moves, as on every button of the interface. No bobbing, no pulse.
- **Place:** the tip of the tag's pointer (frame x 7, row 17) stands 3 px above the thing's top row, over the x
  where the lord will stand. On a bench it stands over the first in line.
- **Drawn unlit**, like the flames: it is a piece of the interface in the world and must read in the dark. It keeps
  whole pixels: 30x36 pt at the world's scale, 40x48 pt in the audience framing.
- **The highlight on the thing itself needs no sprite:**
  - a **rim** of one pixel outside the sprite's outline at its left, right and top (not below), in `gold`, unlit;
    the engine takes it from the sprite's alpha;
  - a **pool**: a point light 5 px above the floor line at the thing's feet, radius 20, `fireGold`, strength 0.7,
    and 1.4 times that while the finger is down on it. The one who has the word in an audience keeps a pool of
    radius 30.
- **When:** rim and pool on every thing in view that offers something now. At most four marks in view, the nearest
  to the lord first; of a row of damaged walls only the nearest carries the mark, the others keep their rim.
- **The touch area** is the thing and its mark together, at least 44x44 pt (DESIGN.md "Controls 2").
- **Texture space:** the seven strips (210x18 together) lie on the hall's page (`tapDoor` in a shelf that had room).
- **In the game (step stage-2):** drawn as emissive actors after every figure; at night their tint is
  (0.78, 0.69, 0.53) of the drawing (M11); at most four in view. The pool is a `window` light (it fades in at dusk);
  in the hall it burns at 0.4 by day. **The rim** (fix round 1 of step stage-2, 15.11.2026): built as specced, by the
  engine from the sprite's alpha (`EmissiveInstance.Kind.rim`: the quad is the cell grown by one texel left, right
  and up; the shader lights the clear texels beside the outline, never the sprite; a building's is a part of its prop,
  `EmissivePart.rim`, so what stands before it hides it), added in the emissive pass at
  0.62 of `gold`, 1.15 while pressed, warmed and at three quarters at night like the marks. Over a marked plot's,
  wall's, brazier's or the barracks' entity props, round a marked person, round a marked bench and the throne in the
  hall; not on the hall's door (it is part of the facade). Its mark keeps to one band over buildings (the tip at most
  30 px over the walk line).
- **The footing of an empty plot (fix round 1, no sprite):** while an empty plot's mark shows, two stakes (1 x 4 px,
  wood) at the ends of what its first building would cover, a cord between their tops (sagging a pixel over the middle
  half) and a chalk line on the lane's top row (two on, one off), drawn lit from the `hallMote` texel behind every
  figure, so the hammer has a ground under it. The atlas gains nothing.
- **The open inner door (step stage-2, no sprite):** for 0.45 s after he came in by the inner door and while he goes
  out through it, the hall draws the left leaf swung in (a 3 px strip of oak against the jamb) and the gap beyond it
  (15 x 45 px of the bailey's dark, hall rows 124 to 169) with a 2 px sliver of cold light at its edge (the day's, the
  moon's at night), all from the `hallMote` texel, so the atlas gains nothing.
- **Open, for the lead:** the tax lectern has no mark of its own. Odile stands at it, so her `tapTalk` can lead to
  the tithe; a seventh mark with a coin is a quarter of an hour of art if wanted.

<!-- BEGIN world lane: world rebuild, step world-1 -->
## The rock and the fog (world rebuild, step world-1, 14.11.2026; ART-look2.md section 22)

In `SpriteID` (look 2 only). Painted by `tools/cleftart.py` on `tools/rockfield.py` (the granite as a lit height
field) and by `tools/fogart.py`; `tools/build-art-world.sh` rebuilds them byte for byte. Light from the upper left.

| id | size | plane | where (x in the plane's own px) | notes |
|---|---|---|---|---|
| `throatStepA` | 224x104 | mid, ground, y -4 | 360 | the Throat's far wall where it begins: low (88 rows at most), far and pale (`far` ramp), its west talus paling into the mist |
| `throatStepB` | 224x176 | mid, ground, y -4 | 450 | the tor, darker and taller (`stone` ramp): fix round 2: its west side climbs in broken crag steps to a shoulder at 70 % of the screen (104 rows over the ground line); only behind the warden statue (its niche at x 568) does it rise to hold the statue's stepped backing; its east end sinks under C |
| `throatStepC` | 224x200 | mid, top-anchored | 600 | the third step, the cleft's own granite: a crag falls to the lane at its west end, then it stands at full height (fix round 2: no lower shoulder) behind the gatehouse, a value darker in the Throat (`cleft_gain`) |
| `cleftWallA`, `cleftWallB`, `cleftWallC` | 256x200, 256x200, 192x200 | mid, top-anchored | 824, 1080, 1336 | the cleft's far wall behind the whole castle, with C one painting cut in four (no join shows). Fix round 1: the rock stands to the screen's top except in two wedges of sky (over the gatehouse at mid 792, over the bailey at mid 1010, where `cleftWallA`'s emitter puts the moon at night, its top 22 rows down); buttresses (a third of their boundaries deep chimneys), chiselled slabs that turn toward the light or away from it, two long ledges that step at each buttress (a lit shelf over an undershadow) with snow drifts on the high one, the slit's cold slate light on the face's top; the beds of three threads of water at 902, 1131 and 1268 (a crack, a wet streak, spray on a ledge); C steps down to the valley floor by 1528 |
| `cleftShaft` | 64x200 | mid, top-anchored, z 4 | 1104 | `#FFFFFF` alpha mask in twelve levels (fix round 1: stronger, at the sun's full strength) with fourteen dust motes: the cold shaft of light through the slit, drawn at the sun's strength (`Prop.sunShaft`) |
| `cleftWater` | 14x54, 12 frames | mid, after the mid props | notch at 893 (row 26) and 1258 (row 30), frame x = notch − 5 | fix round 2: the two threads of falling water, frames 0-5 the first, 6-11 the second: mist with a mistLight head per strand and mistDark on the shade side, one then two pixels wide, in an S over two ledges of its own into spray on a third, strands of 4-5 rows scrolling 3 rows a frame over an 18-row pattern; 6 a second, frame 0 with Reduce Motion |
| `gateRockL`, `gateRockR` | 108x80, 64x70 | world, z 1 | castle front − 54, + 196 (tier 3: 11 and 12 px further out) | fix round 2: shoulders of bedrock with three tongues that climb over each tower's outer edge (the highest to half the shaft), a course of the tower's ashlar on each notch, creased faces, the lit edge in broken pieces (no outline); the east one a low shoulder toward the bailey, no spire |
| `bankSheetA`, `bankSheetB`, `bankSheetC` | 256x208, 256x124, 256x56, 2 frames each | fog A, world, fog B | the face (frame 1) with its right end at the bank's edge plus the sheet's reach, body tiles (frame 0) every 192 px westward (`FrameBuilder.bankSheetTiles`) | fix round 1: painted in a light cool ramp of values, tinted by the hour (`FrameBuilder.bankTint`: grey-violet and translucent by day, navy at night). The body periodic over 192 px with complementary dithered feathers at both ends (each pixel held by one tile), the face leaning back toward the top and torn into wisps; each crest a lit shell, the body in six value steps in clean clusters, the alpha in sixteen dithered steps. A's crest near the screen's top, B's at about half the screen, C a low roll at the foot |
| `bankEnd` | 96x208 | fog B | world 0 | fix round 1: where the world ends the dark is whole: night0, opaque for 20 columns, thinning out by column 92 in sixteen dithered steps; drawn black |
| `darknessBankGlow` | 9x3, 4 frames | world (emissive) | `FrameBuilder.bankEyePairs` | fix round 1 (it was a 64x236 strip of eyes in rows): one pair of the bank's eyes: 0 near and open (two lit diamonds 6 px apart), 1 near and half shut, 2 far and open (two points 4 px apart), 3 far and half shut. Five slots 128 px apart behind the bank's edge, each opening at a place and height of its own, blinking, shutting and opening elsewhere; at most four on a screen; three still with Reduce Motion |
| `cloudDeck` | 720x100 | far, y 22 | far x −100 | the cloud deck over the Weltmauer (its billows stand on row 50, 72 rows over the ground line): fix round 2: towers of big billows 8 to 22 rows higher where the deck's mass swells, the front lobes at heights of their own (no scallop row), the veil under it a horizontal fade that follows the underside's lobes (no drips) |

The far castle in the Weltmauer's first slot is gone (`cleftart.py noslot`), and the Weltmauer's first 320 columns
sink into a bank of painted mist toward the west (`cleftart.py mistleft`). Fix round 1: below its snow line no snow hangs in the
gullies or couloirs any more (`worldart.py regrade`, `clean_snow`: no patch under 6 px); the snow is the caps on the
massifs' upper faces with a clean hem. The old walls' granite (`oldWall2`, `oldWall3`) is cut to broken footings of
at most 36 rows (the horn west of the wall 16) in the cleft's granite with cool grey shade (`throatart.py footing_rock`), and the anchors' toothing
stops at the footing's height.
Fix round 2 adds:

| id | size | plane | where | notes |
|---|---|---|---|---|
| ~~`cleftGraze`~~ | | | | retired by world-2 (the critic's look 3: it read as pale lilac drips); the backdrop pools of the cleft wall stay |
| `laneCobbleEnd` | 64x26 | world, lane tile | world 2304 (world-2: under the postern's passage; 2432 before) | where the castle's cobbles give way to the valley's earth lane: `laneEarthA` with `laneCobbleB`'s stones laid over it, thinning stone by stone over 48 px (`tools/lanejoin.py`) |

The Weltmauer's slot patch has wandering edges (no dithered blend column), and the wall is cut into buttresses by
arêtes with lit west and shaded east flanks (`cleftart.py ridges`, between `noslot` and `mistleft`). Look 1's high
clouds (`cloudA`, `cloudB`, `cloudC` on the sky plane) and look 2's high deck on the clouds plane are gone from look 2.
<!-- END world lane: world rebuild, step world-1 -->

<!-- BEGIN world lane: world rebuild, step world-2 -->
## One castle (world rebuild, step world-2, 15.11.2026; ART-look2.md section 23)

In `SpriteID` (look 2 only). Painted by `tools/keepart.py` (hand-placed vocabulary in the gatehouse's language: coursed
ashlar with soft joints, quoins, lit left edges and cast shadows from the upper left, crenels with lit caps under an ink
edge, corbel tables, teal slate, glass in `night1` for the layout's masks); `laneScreeCobble` by `tools/lanejoin.py`;
`tools/build-art-world.sh` rebuilds them byte for byte, the bailey's lean-tos `tools/build-art-buildings.sh`. Placed by
`Core/SceneLayoutCastle.swift`; masks are (dx, dy from the sprite's bottom, w, h).

| id | size | plane | where (plane x) | notes |
|---|---|---|---|---|
| `keepT1`, `keepT2`, `keepT3` | 260x175 (fix round 1, `tools/keepfix.py`; was 200) | near picture, moving with the mist band (0.62), z 5 | 1058 (its main block's middle, col 160, over the hall door at 1830) | the one keep per tier, in the mistBand's own stone (slate darks under mist greys: a step paler and cooler than the curtain) on a ramp from a dark foot to a lit crown; round corner towers (cols 64 to 97, 222 to 255) modelled as drums; the main block (98 to 221) between two broad pilasters; a round stair turret (15 to 45) and its stair hall (45 to 64) on the west, the corner the front gate sees. Tier 1: ridge at y 120, the turret's crenels at y 131; masks (139,80,7,10), (170,80,7,10), (53,70,3,7) (the stair hall's window); tiers 2 and 3 a storey more, masks + (108,100,7,10), (170,100,7,10), (201,100,7,10) (the fourth twin window at (139,100) stays dark: no grid of lit rows), the realm's banners in the outer bays, the house banner on the ridge (tier 2 to y 156; tier 3 the great banner to y 170); tier 2 raises the turret (crenels at y 147) and flies the house's flag from it; tier 3 puts slate cones on the towers and the turret (finials at y 148). A brazier on the wall walk at col 129 (its `brazierFlame` at (125, wall + 7) and `keepFireGlow` at (111, wall − 1); the wall walk at y 98 or 118). Chimney smoke at x + 187.5, y 122 (tier 1) or, low on the right slope so it rises under the HUD's realm strip, x + 202.5, y 136 (tiers 2 and 3) |
| `keepT2Build`, `keepT3Build` | 260x175 | the same | the same | tier 2's storey half laid under heavy scaffolding (standards two px wide, ledgers in light wood) with a crane whose jib stands over the roof line (to y 146), the roof off (tier 1's panes, no smoke, no brazier); tier 3's cones as heavy timber frames in light wood on the towers and the turret (tier 2's panes, no brazier) |
| `keepRimT1`, `keepRimT2`, `keepRimT3`, `keepRimT2Build`, `keepRimT3Build` | 260x175 | near picture, emissive | the keep + (0, 0) | the keep's warm rim at dusk: fire-orange on every edge of its silhouette that faces west (a px inside at half strength) and faintly on the caps; shown by the hour's warmth until the moon is up (`FrameBuilder.keepRimShare`) |
| `keepPaneHalo` | 11x14 | near picture, emissive | each lit twin window − (2, 2) | the soft warm bloom round a lit window, 2 px out onto the stone, at dusk and night; a dark window loses it |
| `keepFireGlow` | 36x24 | near picture, emissive | keep + (111, wall − 1) | the keep's brazier's light on its merlons, its wall walk and the roof's foot, at dusk and night |
| `keepMist` | 320x32 | fog A picture (in front of the keep, behind the world plane), moving with the mist band, z 6, y 60 | keep − 30 | the mist bank at the keep's foot (fix round 2): one volume that rises 4 to 6 rows over the curtain's merlon tops and feathers out over 10 rows of ordered dither, both ends dithered away over 56 px; white, tinted by the hour's fog colour at 3.4 of the hour's mist strength (dawn, dusk), at night a dim desaturated grey (`SceneLayout.castleMistTint`) |
| `smokePuff` | 8x8, 5 frames | the chimney's plane (and the emissive pass from the dusk) | `CastleSmoke` | a puff of smoke at five sizes (3 to 7 px, fix round 2), white; the keep's and the bakehouse's chimneys send twelve at a time that grow as they rise 38 rows, lean on a diagonal and overlap into one plume; from the dusk each catches the moon, and over the bakehouse the oven's glow from below (the same sprite as a glow) |
| `curtainA`, `curtainB`, `curtainC` | 64x74 | world, z −5 | 1474 + 64 k, k 0 to 11 (A C B A C A B C A B A C) | the curtain wall: wall walk at 64, corbel table, merlons, putlog holes; A a slit and ivy, B an older arch blocked with rubble (fix round 1: the infill a value darker in a recess with the intrados's shadow, the voussoirs lit only on the left haunch, no pale outline), C a drain's spout, its stain and ivy (fix round 2: the buttress is gone; the row over the corbels, clear before, is the walk's shadow) |
| `curtainTower` | 44x104 | world, z −4 | 1680 (tier 3 also 1584, mirrored) | a wall tower: lit left face, slits, a crown on machicolations |
| `curtainStair` | 52x66 | world, z −3 | 1724 | the stair to the wall walk, rising leftward, a store's mouth under it |
| `curtainHoard` | 64x22 | world, z −4, y 54 | 1538, 1602, 2060 (tier 2 and 3) | a timber hoarding on the wall walk under a slate pent roof, drop slots |
| `castleBanner` | 12x30 | world, z −4, y 28 | 1500, 1906, 2084 (tier 3) | the realm's banner hung from the parapet |
| `forebuilding` | 120x96, 2 frames | world, z −2 | 1770 | the keep's porch (fix round 1, `tools/keepfix.py`): a slate roof sloping back to its ridge at y 80, a stone dormer with a thick coping for the lord's chamber, quoined corners, the hall door at col 59.5 (world 1830) in a round portal raised on three steps and a threshold between low parapets: frame 0 shut (mask (52,7,16,1): the light under the door), frame 1 open (the view into the hall: `hallDoorGlow` at (50,7)). Torch flames at (36,30) and (81,30), their light one flat band; the lord's chamber window (57,64,5,10) |
| `hallDoorGlow` | 20x32 | world, emissive | forebuilding + (50, 7), open door only | the view into the lit hall: the leaves and jambs dark, the ceiling's beams dim, flagstones receding to the far wall, the hearth's glow on it the brightest point high in the middle; the pillar and the banner inside left clear; dim by day, full at dusk and night |
| `hallDoorWedge` | 60x19 | world, emissive | forebuilding + (30, −12), open door only, dusk and night | the door's wedge of warm light from the threshold over the steps and 12 rows out on the cobbles, the door's width (18 px) to 2.5 times it, alpha in sixteen smooth steps, at most 0.5 (the stones show through) |
| `chapelTower` | 110x132, 2 frames | world, z −2 | 1950 | the chapel of the Flame as a closed tower in the wall: frame 0 the bell in the belfry, frame 1 empty (`castle.chapel.bell.missing`); masks (42,54,5,24), (55,54,5,24), (68,54,5,24): three lancets lit from inside; the Flame's `brazier` at x + 31 |
| `bakehouse` | 100x62 | world, z −2 | 2120 | the kitchen's lean-to: rubble walls, a hipped slate roof, the oven's domed hatch (`bakeHatchGlow` at (15,7), all day), a window mask (63,23,5,5), chimney smoke at x + 75, y 61 |
| `bakeHatchGlow` | 6x6 | world, emissive | bakehouse + (15, 7) | the oven's fire through the hatch |
| `posternT1`, `posternT2`, `posternT3` | 176x112 | world, z 0 | 2230 | the back gate per tier (a building tier shows the one before): the curtain's end, the passage at cols 90 to 110 (world 2320 to 2340) under a slate pent roof (fix round 1, `tools/keepfix.py`: its depth: the jambs' inner faces and the vault in shadow, cobbles that recede to a far opening of the valley's daylight at cols 95 to 104, rows 4 to 18), lanterns at (81,30) and (116,30), a squat tower with a window mask (150,26,5,8), a flower box, ivy and a bench; tier 2 roofs the tower and hangs a great lantern at (99,42); tier 3 crowns it with machicolations and a flag |
| `posternFarGlow` | 10x16 | world, emissive | postern + (95, 4) | the passage's far end lantern-warm at night |
| `gateArchFg` | 16x116, 2 frames | none (fix round 2) | placed nowhere | fix round 1's near jamb of each gate passage (an opaque pier of dark coursed stone beside the opening); the critic's look 2 found it a stray pier in front of the gatehouse and a tombstone in the postern's road, so fix round 2 placed it nowhere. Build 3 may bring a frame back only as REVIEW-look-2.md 2.8 describes it, after a scenemock preview |
| `laneScreeCobble` | 64x26 | world, lane tile | world 1344 (under the gatehouse's gateway) | the Throat's scree giving way to the castle's cobbles stone by stone (`laneCobbleEnd`'s join, mirrored) |

Repainted in place (same sizes, masks and anchors as `EntityFrames.courtyard`): `barracks` (64x48), `smithy` (60x48),
`masterSmithy` (60x56), `lodge` (56x44), `bigLodge` (64x52), as lean-tos of granite and slate against the curtain: the
barracks with shields, a spear rack and loopholes either side of its door; the smithy an open forge bay (a stone hearth
under a hood and a chimney, bellows, tongs) beside a stone room, an anvil and a quench barrel; the master smithy with a
loft over the forge; the lodges with stacked timber and a ladder, the big one with a hoist.

Retired into `tools/retired-art`: `weltmauerPatch`, `farCastlePane`, `farCastleGlow`, `farCleftGlow`, `farCleftGlowBack`,
`farCastle2/3`, `farCastleBack2/3` and their `Build` and `Glow` states, `farCleftGlow2/3…`, `farCleftGlowBack2/3…`,
`keepTop2/3`, `backTop2/3` and their building states, `cleftGraze`. Look 2 no longer draws `keepTop`, `castleBackGate`,
`hallInterior`, `hallFront`, `chapel`, `chapelInterior`, `kitchen`, `kitchenInterior`, `castleWall`, `throne`, `hearth`
or `candleStand` (look 1 keeps them).
<!-- END world lane: world rebuild, step world-2 -->
### The marks as signs, the interface kit, the lady's portrait (stage lane, step stage-3-interface, 15.11.2026)

- **The seven marks are signs alone** (the director's note of 15.11. 07:30, HUD.md rule 2): `tools/markart.py` (pure
  Python on hudart.py's edge and pixelart.py's palette) redraws `tapTalk`, `tapThrone`, `tapBuild`, `tapRepair`,
  `tapRecruit`, `tapLight` and `tapDoor` at their old sizes (30x18, two frames of 15x18), so no code moved: a 9x9 sign
  in bone (`parchment`, shade `plaster`, accents `gold`, `fireGold`, `tile`) inside a one-pixel `ink` edge, its 11x11
  cell centred over frame x 7 with its bottom on row 17, where the tag's tip was. No plate, no parchment. Frame 1
  (pressed) turns the bone to lantern gold (`fireGold`, shade `gold`). The signs: a speech bubble with three dots, the
  circlet, a claw hammer, four stones with a red crack, a head and shoulders with a gold plus, a flame, an arched door
  of planks with its ring. `tools/hallart.py`'s tags (the `TAG` plate) are no longer used for them.
- **The interface kit** (`claude/lh-hudart`, tools/hudart.py; ci-out/director/hud-kit.md) is in `SpriteID` now:
  `hudFigures` 7x9 x 12 (0 to 9, plus, minus), `hudArrow` 8x9 x 2 (up, down), `hudCoin` 9x9, `hudFace` 9x9 x 4 (glad,
  even, grim, unrest), `hudPeople` 13x9, `hudGear` 10x10, `hudDawn` 11x9. The board's pieces (`hudCoinTen`,
  `hudHollow`, `hudHollowTen`) stay unregistered until the count (PAY.md) is built. Drawn unlit: in the world as
  emissive actors (the gold and the notes above the walking lord), in SwiftUI cut from the atlas (the lantern moment,
  the cards' coin, face and people, the gear, the realm strip's figures).
- **`portraitLady`** is her own portrait (the review's M8; redrawn in fix round 1 after the critic's blocker: she
  was still the Burgherr with darker hair). `tools/portraitstory.py` builds her scene on the template turned right and
  evaluates it mirrored, so she turns three-quarters to the left with her face in the hearth's light from the left (the
  stamps mirrored with it, no hearth rim on the skin): a narrower soft face, a small nose; deep brown hair
  (`soilDark`, `woodDark`, `wood`, `woodLight`) swept over the ear into a crown braid and a plait from the nape over
  the far shoulder in front; a deep wine gown (`plumDeep`, `crimsonDeep`, `crimson`, hand colours) with a linen
  neckline and a gold pendant. The render is a draft; `tools/grids/court/portraits/portraitLady.txt` is finished by
  hand (the crown braid's herringbone, the circlet as one gold line resting on the braid with a `crimsonLight` stone,
  the forehead without a band, the closed mouth with a `dusk` lower lip, only the ear lobe with a gold drop) and built
  by actorart.py. The name entry sets her on a teal ground (`TileGround.teal`).
- **The cards' pixel glyphs** (fix round 1) are not sprites: `UI/PixelGlyphs.swift` builds them from text grids at run
  time on the 2 pt grid (20 glyphs, one colour each), with the tiles' dithered grounds and the gear's glass disc; they
  take no atlas row.
- **The atlas:** the kit's 30 frames take about 180 x 10 texels; the round's `atlas-rows` attachment gives the count.

### The hall stage's light and wear (stage lane, 14.11.2026; DESIGN.md "The hall stage and touch the world")

Registered in `SpriteID` with the stage-8 hall (`greatHall`, `hallPillarNear`, `hallFire`, the six marks); made by
`python3 -I -B tools/hallstage.py` (pure Python, palette names only, the same bytes on every run). They only add
light and wear to tools/hallart.py's hall.

| id | size | frames | notes |
|---|---|---|---|
| `hallShaft` | 83x120 | 1 | the light of one tall window's two lights falling onto the nave floor, slanting down to the right (the afternoon; mirrored for the morning). White, its alpha the beam's strength in ordered-dither steps: drawn as an emissive glow in the daylight's colour from hall row 72 (the lancets' spring), its left edge on the window's (x 169 and 285) |
| `hallMote` | 1x1 | 1 | one speck of dust, drawn emissive inside a shaft (11 per shaft, drifting down slowly, frozen under Reduce Motion) |
| `hallWash` | 512x44 | 8 of 64x44 | limewash stains, each cut for its own place on the hall's ashlar (never over a banner, a window, a shaft, the wainscot or the flags): frame `n` at `HallLayout.washPatches[n]` (top-left in hall px); a ragged outline (a noisy ellipse, no straight run longer than three or four pixels) with an ordered-dither feather of one to two pixels; each pixel one step warmer than the stone under it and at most one step lighter (the blocks, highlights and joints read through), a few small islands of thicker plaster with a one-pixel shadow (fix round 1 of stage-1: the old patches covered whole blocks and read as square light blocks) |

- Layers: the patches on the world plane right over `greatHall`; the shafts and the motes in the emissive pass over
  the world plane (benches and props in a shaft catch its light); the figures and the near pillars stay in front.
- The atlas page: the hall's sprites take it from about 1730 to about 1850 rows of 2048 (one page still; about 200
  rows are left for the world lane's new pieces before the second page SPRITES.md "The great hall as a stage"
  proposes is needed).

## World-3 (world rebuild, step world-3, 15.11.2026; ART-look2.md section 26)

In `SpriteID` (look 2 only). Painted by `tools/w3art.py` (pure python, palette colours, hashes of the position;
`tools/build-art-world.sh` rebuilds them byte for byte; its passes over existing sprites read their untouched sources
from `tools/w3src`). Placed by `Core/SceneLayoutWorld3.swift`, the bakehouse's wedge by `Core/SceneLayoutCastle.swift`,
the beacon stages' rims by `EntityFrames.beacon`. Masks are (dx, dy from the sprite's bottom, w, h).

| id | size | plane | where (plane x) | notes |
|---|---|---|---|---|
| `bakeHatchWedge` | 30x14 | world, emissive | bakehouse + (3, −10), dusk and night | the oven's wedge of light (the critic's high 1 of world-2 look 3): its top 4 rows on the oven dome's foot under the hatch, its 10 lower rows on the lane; the hatch's width at the top, four times it at the foot, strongest at the wall's foot, fading toward the viewer; alpha in sixteenths; gold, orange, ember |
| `beaconRuinRim`, `beaconBaseRim`, `beaconTowerRim`, `greatBeaconRim` | 64x130 | world, emissive (the moon's colour) | each stage + (0, 0) | the moon's rim (M2): 0.85 on every right edge inside the ink outline, 0.38 the next pixel, 0.62 on top edges, a faint wash on the east half's pale stones; by the moon's height (`FrameBuilder.wedgeMoonShare`), so none by day and at the dusk |
| `townRoofsA`, `townRoofsB`, `townRoofsD` | 120x72 | near, z −2, shade 0.72 | 1930 (A), 2080 (B), 2387 (D), 2567 (A mirrored), 2687 (B mirrored) | the town's back row (M4): tall narrow town houses that overlap (half-timbering, gables to the lane, hipped long roofs in tile, slate and thatch, dormers, small panes in `night1`), a field-stone garden wall with a hedge at their foot that crumbles at the sprite's ends; masks: A (34,24,3,4), (20,30,3,4), (13,51,3,3), (84,22,3,4), (101,18,3,4); B (39,22,3,4), (15,14,3,4), (81,54,3,3), (110,26,3,4); D (58,36,3,4), (53,56,3,3), (34,28,3,4), (106,22,3,4) (a few lit, never a grid; `w3art.py masks` lists every pane); a smoking chimney at A (110.5, 71), B (110.5, 63), D (34.5, 65) |
| `townRoofsC` | 120x96 | near, z −2, shade 0.72 | 2197 (its tower between the poplars and the linden, behind the square) | the church: a stone tower 20 wide to y 52 with a louvred belfry, a lancet (mask (51,16,2,9)) and a door, a slate spire with a lucarne to y 94 and a gold finial; two houses beside it; masks (26,26,3,4), (72,28,3,4), (104,28,3,4), (90,50,3,2); chimney (104.5, 67) |
| `riverFarLantern` | 12x26 | near, z 2 | 2985 (the far shore right of the old bridge's second stump, at the river end's clamped view) | a weathered post with an arm and a small iron lantern (mask (8,14,3,4), amber at 0.8) (L4) |
| `riverSkiff` | 34x10 | near, z 2, y −2 | 2929 (on the water between the stumps; on the mid plane the low mist band swallowed it) | a tarred skiff moored on the far bank, a lit sheer strake, an oar across, its painter to a stake (L4) |
| `valleyVerge` | 64x10 | world, z −8, y −14 | 2400 + 64 k, k 0 to 19, every other mirrored | where the earth track meets the grass under it (L3): tufts of the meadow's edge growing up into the track, stones bedded in the earth, roots; its lowest rows fade into the band |

Repainted in place (same sizes and anchors): `beaconRuin` (the cage over the broken top is the Great Beacon's cold iron
bowl, cracked, with grey ash and a charred log end, on a stub of its stem), `wardenStatue` (M5: a stone basin in its
hands with a warm lip and a shadow under it on the robe; look 2's fire emitter one row higher, dy 156), `castleFront`,
`castleFront3`, `castleFront3Build` (the crenels' and the corbel band's `night0` and `night1` a slate dark and mid, as
the keep's, outside the slits' masks and the braziers' niches), `chapelTower` (the bell bronze in shadow), `posternT3`
(tier 2's slate roof raised on the crown's machicolations, a flag on its point).
<!-- END world lane: world rebuild, step world-3 -->

## World-3, fix round 1 (15.11.2026; ART-look2.md section 27)

In `SpriteID` (look 2 only). Painted by `tools/w3f1art.py` (pure python, palette colours, hashes of the position;
`tools/build-art-world.sh` rebuilds them byte for byte; the beacon's stages read their untouched sources from
`tools/w3src`). Placed by `Core/SceneLayoutWorld3.swift`; the far lantern's reflection by
`FrameBuilder.riverLanternStreak`.

| id | size | plane | where (plane x) | notes |
|---|---|---|---|---|
| `riverLanding` | 72x20 | world, z 4, y −16 | 3708 (the bank's end to the old bridge's first stump, 3779) | a short timber landing (blocker 2): a stone footing on the bank, the deck at the lane's height (its row 4 is y −1: lit plank tops, the side with its joints, the shadow under it), a beam, four posts into the water (dark and fading under the waterline, a pale ripple either side), a bollard with the painter's turns at its end |
| `riverSkiffMoored` | 34x9 | world, z 5, y −12 | 3722 (alongside the landing, in front of its posts) | the skiff tied at the landing: its sheer curving up to the stem and the stern, a lit sheer strake, a clinker strake, the tarred bottom strake, an oar's loom over the gunwale; under the waterline (row 6) dark and fading |
| `riverSkiffRim` | 34x9 | world, emissive (the moon's colour) | skiff + (0, 0) | the moon on the gunwale's top (high 8), by the moon's height (`SceneLayout.look2MoonRims`) |
| `riverLanternHalo` | 22x22 | near, emissive (window glow) | far lantern + (−1, 0), dusk and night | a warm round halo falling off from the glass and the little pool on the bank at the post's foot (high 8) |
| `riverLanternStreak` | 9x24 | near, emissive (window glow), drawn after the world plane | under the far lantern, from the water's far edge (y −6) down | its broken reflection on the water: horizontal dashes, widest near the shore, thinning and parting downward |
| `throatButtress` | 96x132 | near, z −1 | 852 (behind world about 1100 seen from 1000 to 1200) | a buttress of the Throat's granite with pinnacles and a scree fan spilling right (high 9), on a cool ramp (`nightDeep`, `stoneDark`, `stoneMid`, `stone`, `mistDark`, `rockLight`), a step darker than the mid plane's cliff |
| `valleyVergeB` | 64x10 | world, z −8, y −14 | the odd tiles of the verge (2464 + 128 k) | a second painting of the verge (high 10): the tiles run A B A' B' |

Repainted in place (same sizes and anchors): `beaconRuin` (no stem: a squat cold iron bowl seated low in the broken top,
a crack in its rim), `beaconTower` (the builders' crane, posts, ledger and braces gone; the squat bowl in the crenels;
the door kept), `greatBeacon` (the bowl in three steps of iron with a lit side, its rim an ellipse with the mouth dark
and ash at its back, two curved hoops; the slits with a dark reveal), `beaconRuinRim` to `greatBeaconRim` (the moon a
2 to 3 px band of lit stone faces on the right, broken by joints and missing stones, a faint wash; no outline on the
left or the top), `valleyVerge` (stones of three sizes at gaps of two to five times, some sunk in the grass),
`bakehouse` (the oven's dome a value step down: at noon it read as a pale grey ring round the hatch). No
longer placed: `riverSkiff` (the skiff moved to the landing).
<!-- END world lane: world-3, fix round 1 -->

## World-3, fix round 2 (15.11.2026; ART-look2.md section 28)

In `SpriteID` (look 2 only). Painted by `tools/w3f2art.py` (pure python, palette colours, hashes of the position;
`tools/build-art-world.sh` rebuilds them byte for byte; its passes over sprites of the earlier passes read their sources
from `tools/w3f2src`). The postern's night view is placed by `look2CastleExteriors`, the ground fog by
`FrameBuilder` with the Gloom's strips (`GloomFog.groundStrip`).

| id | size | plane | where (plane x) | notes |
|---|---|---|---|---|
| `posternNightView` | 10x14 | world, z 1, y 4 | postern + 95 (over the passage's painted far view, cols 95-104, rows 4-17) | the valley at night (high 4): a deep blue sky, the far hills a step darker, a faint meadow, the lane's end; drawn by the night's moon (`SceneLayout.posternNightShare`), none by day or in the warm evening |
| `gloomGroundFog` | 2 frames of 160x28 | fog A, y −6 | the Gloom's front × 0.9, tiled back to the screen's left | the hard night's ground fog (high 8): a cold low mist (`far`, `mistDark`, `mist` crests), densest at the ground, rising 16 to 22 rows in soft billows; frame 0 repeats, frame 1 is the leading face; alpha × `GloomFog.midVeil`, tint × (0.92, 1, 1.14) |

Repainted in place: `throatButtress` (96x132: the Throat's own warm granite, its shade `rockDeep`, no lit rim; the left
slope in three lit ledges, a broad crest leaning right, a scree apron along the foot rising into skirts at both ends),
`beaconTower` (the crown broken: a chipped merlon, a stub, the right corner fallen 16 rows in steps by the courses,
fallen blocks at the foot; the 2-row gap under the old parapet closed; the cold bowl with a rim a value over its body, a
cold right lip and a grey ash crown), `beaconRuinRim` to `greatBeaconRim` (the moon's band broken at every second course,
a wash that lifts the faces at night, on the tower stage the bowl's lip and ash), `castleFront`, `castleFront3`,
`castleFront3Build` (the slits a 2 px glass core in a dark reveal), `watchtower` (the shuttered window a plain arrow
loop), `cloudA` to `cloudC` (the undersides' checker teeth out, irregular lobes, a darker belly), `darknessBankGlow`
(the near eyes open as almonds, not crosses), `oldWall1` (the stepped blocks rounded into rubble, heaps at the foot),
`valleyVerge`, `valleyVergeB` (gaps of 3 to 17 px, never one rhythm). Resized: `riverSkiffMoored` and `riverSkiffRim`
40x12 (a hull with both gunwales, the bow raised, in the open water right of the first stump at 3781, y −15),
`riverLanternStreak` 7x26 (a broken amber streak 3 to 4 px wide fading down); `riverLanternHalo` fainter, in fire
orange.
<!-- END world lane: world-3, fix round 2 -->
