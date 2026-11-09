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
  creature: an ember rim on the silhouette's top contour, one connected crack network and the eyes, which are not the
  main read (ART-actors.md "Glow strip rules"). The body must read in daylight and in firelight.

## Actors

| id | size | frames | frame use |
|---|---|---|---|
| `king` | 16x30 | 10 | walk 0-5 (one frame per 7 game px), idle 6-7, command 8-9 (lifts the lantern to give an order) |
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
`ashGiantGlow`, `lightlessKingGlow`. Ember eyes and cracks in the fire ramp; the gloomweaver's eyes and orb are cold
violet and the Lightless King's are a cold pale teal (add tagged `emissive` palette entries for these if needed, and
check that `build-art.sh` still rebuilds every committed sprite byte for byte).

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
| `plotMarker` | 10x16 | 1 | stakes and a small banner on an empty, unlocked plot by day |

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
