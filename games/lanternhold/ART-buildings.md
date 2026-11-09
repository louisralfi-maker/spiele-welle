# Lanternhold: art of the buildings, overlays and projectiles (M2b art lane, 09.11.2026)

The building, overlay and projectile sprites of `SPRITES.md`, painted as real pixel art to the contract: one row of
frames per PNG, 8-bit RGBA, binary alpha, palette colours only, albedo in even daylight (no baked light, no glow), dark
glass where windows are, everything that glows left to the engine (window glass masks, flame sprites, glow strips).
`tools/build-art-buildings.sh` rebuilds every sprite of this lane (names below, or all); `ART.md` keeps the pipeline,
the palette and the lessons this builds on.

## Credits

Recraft (`bash tools/recraft.sh`, `recraftv4_1`, 35 credits per image), budget 150 for this lane: **601 before, 496
after my three sheets: 105 spent** (the balance read 391 at the end; the actors lane spent the other 105 in between).
The raws are `build/recraft/lh/bld/<sheet>-1.png` (git-ignored), the prompts in `build/recraft/lh/bld/prompts.txt` and
below.

| Sheet | Balance before | after |
|---|---|---|
| `beacon-a` (the Great Beacon, a bastion, a watchtower) | 601 | 566 |
| `court-a` (barracks, smithy, master smithy, lodge, big lodge) | 566 | 531 |
| `town-a` (big house, market, tavern) | 531 | 496 |

## Method

- Grids for everything up to about 46 px and wherever pixels must sit exactly (the gate overlays, the wall frames):
  `tools/grids/buildings/<id>.txt`, built with `pixelart.py grid`. The grids were drawn with throwaway helpers (a
  masonry painter in the stoneWall's block language, plank, strap and log brushes) and then tuned by eye; the grid
  files are the source.
- Recraft sheets for the big ones: `beacon-a` (the beacon, the bastion, the watchtower), `court-a` (the five courtyard
  buildings) and `town-a` (big house, market, tavern). Only `town-a` converted well enough to keep pixels (the roofs of
  the big house and the tavern); the others gave the designs, which are hand-set as grids (why: see the courtyard note
  below; the beacon's and the bastion's bricks were 4 to 6 px in the paintings and turned to noise).
- Every two- and three-frame sprite keeps frame 0 where SPRITES.md says the old one-frame PNG stays: `palisade`,
  `stoneWall` and `ballista` frame 0 are byte for byte the milestone 1 pixels, so the M1b shots do not change.

## Sprites

### Walls, rubble, scaffold

| id | size x frames | method | notes |
|---|---|---|---|
| `palisade` | 20x34 x 2 | grid `tools/grids/palisade.txt` | frame 1: one stake snapped above the beam (raw pale wood at the break), a point split off, a plank piece torn out (see-through), a split, the foot charred with ash-grey flecks, a burst lashing |
| `stoneWall` | 36x52 x 2 | grid `buildings/stoneWall.txt` (frame 0 = the milestone 1 conversion) | frame 1: the right merlon shattered to a ragged stump, a chip off the left merlon, a branching crack down four courses, two face stones knocked out, soot up the left side, two chips at the foot |
| `bastion` | 44x64 x 2 | grid `buildings/bastion.txt` (design from `beacon-a`'s middle piece) | dressed ashlar in the stoneWall's colours, three merlons on a crown band, stepped corbels with dark machicolation holes, a talus over the lowest 22 rows, a central arrow slit, a teal banner with a gold lantern; frame 1: the right merlon and crown corner broken off, a crack past the slit, two blocks knocked out, soot at the right foot, the banner torn short |
| `rubbleWood` | 24x10 | grid | a fallen palisade: a stake lying with its point left, a second across it, raw splinters |
| `rubbleStone` | 40x14 | grid | tilted blocks in a lumpy heap, a broken merlon on top, cracked blocks, chips |
| `scaffold` | 24x40 | grid | seamless at 24 px (poles every 12 px; ledgers, plank decks and the braces wrap): two decks, alternating braces, lashings, footing stones |

### Gate overlays

| id | size x frames | method | notes |
|---|---|---|---|
| `gateWood` | 46x60 x 3 | grid | tier 1: oak leaves of vertical planks, two iron straps, ring handles (the portcullis stays up in the arch); damaged: two plank pieces torn out with raw splinters, a strap hanging loose, a split, the foot charred and burnt through; open: the leaves swung in against the passage walls |
| `gateIron` | 46x60 x 3 | grid | tier 2: iron-banded leaves behind the lowered portcullis, continuing the painted bars to pointed teeth; damaged: two bars bowed far apart round a hole broken through the leaves, crossbars burst, a bar's foot torn away, scorch; open: only the teeth show under the arch, banded leaves swung in |
| `gateGreat` | 46x60 x 3 | grid | tier 3: steel-plated leaves behind a heavy portcullis (three-pixel bars, gold bosses, gold-capped teeth) with the realm's crest on its centre crossing; damaged: a plate staved in with bent bars round it, a plate torn away (oak beneath), the crest cracked and chipped, a tooth snapped, scorch; open: heavy gold-capped teeth under the arch, plated leaves with gold rivets swung in |
| `gateBroken` | 46x20 | grid | a broken leaf lying tilted, a beam across the front, a bent piece of the portcullis with its teeth, splinters |

### Towers and engines

| id | size x frames | method | notes |
|---|---|---|---|
| `archerTower` | 20x48 | grid | tier 1: a timber frame tower (splayed legs, braces, a ladder, a deck with a plank parapet) |
| `watchtower` | 24x64 | grid (design from `beacon-a`'s right piece) | tier 2: a slender stone tower, merlons on corbels, an arrow slit, a barred window, an oak door, a teal pennant |
| `fireTower` | 14x40 | grid | tier 2 of the brazier: a stone column on a stepped plinth with an iron fire basket of coals |
| `ballista` | 28x16 x 2 | grid `tools/grids/ballista.txt` | aimed left; frame 0 loaded (the milestone 1 pixels), frame 1 loosed: no bolt, arms sprung forward, the string straight between the tips |
| `catapult` | 32x24 x 3 | grid | a mangonel throwing left: the stop beam end-on on a braced upright, a torsion skein, a rear post and winch; rest (a firepot with a rag wick in the cup), wind (the arm hauled down by the taut rope), throw (the arm against the padded stop, the cup empty) |
| `stakePit` | 24x8 x 2 | grid | armed: three sharpened stakes leaning toward the Gloom; sprung: splintered stubs with soot, the points lying on the rim |

### The Great Beacon

| id | size x frames | method | notes |
|---|---|---|---|
| `beaconBase` | 64x130 | grid (design from `beacon-a`'s left piece) over the ruin's shell (compose) | new pale courses rebuilt to a third of the tower (top course at y 58) inside the ruin's broken shell, which stands behind them (`beaconRuin.png` without its fire cage, broken top at y 104-108); an unfinished top, tall shear legs (apex at y 117) lifting a block high, cut blocks stacked beside it |
| `beaconTower` | 64x130 | grid | the tower risen above the ruin (its unfinished top course at y 105, the scaffold to y 115, the hoist to y 121): a scaffold deck round its top, a hoist with a block on its rope, three iron bands, three slits |
| `greatBeacon` | 64x130 | grid | the full tower in the ruin's pale stone with a parapet on corbels, two teal banners, and the huge iron bowl (51 px across) on four curved ribs; the bowl's iron one value step darker since the fix stage (it washed out pale under the beacon's own light) |
| `beaconFire` | 48x32 x 4 | grid (fire ramp only) | glow strip, the chapter's climax: a bed of fire across the whole bowl mouth with an ember coal row on it, nine tongues with white cores that trade heights (the tallest 27 rows above the mouth), wisps above the tips, sparks (fix stage: was 24x20 x 3, a campfire in half the bowl) |

### Courtyard (castle palette)

| id | size x frames | method | notes |
|---|---|---|---|
| `barracks` | 64x48 | grid (design from `court-a`) | a stone ground floor, a dark timber upper storey with four windows, teal slate, an arched door under a teal banner, two wall lanterns, spear racks and round shields |
| `smithy` | 60x48 | grid (design from `court-a`) | a forge: an open front between stone piers, a hood over a hearth of coals, an anvil, tools, a shingle gable with a chimney, a hammer sign, a lean-to with a grindstone and a barrel |
| `masterSmithy` | 60x56 | grid (design from `court-a`) | the forge grown: a teal slate gable with a loft window, two chimneys, a bigger hearth, bellows, a quench barrel, a banner, a stone annex with iron bars |
| `lodge` | 56x44 | grid (design from `court-a`) | a timber workshop on a stone base, its doors open, a shingle roof, logs, a ladder, a wheelbarrow, a saw sign |
| `bigLodge` | 64x52 | grid (design from `court-a`) | two storeys (stone and timber), teal slate, a crane hoist with a block on its rope, stone blocks and planks |

### Town (the cottages' palette), plot marker, projectiles

| id | size x frames | method | notes |
|---|---|---|---|
| `bigHouse` | 72x56 | Recraft `town-a` (left) for the roof and chimneys + hand-set storeys | two storeys in the cottages' half-timbering: a jettied upper storey with two windows between braced bays, a ground floor with two windows over flower boxes, an oak door, a stone plinth; a tile roof with a hand-drawn dormer and two chimneys |
| `market` | 90x40 | grid (layout from `town-a`, middle) | three stalls under raspberry, teal and ochre striped awnings with scalloped valances, counters piled with produce, cloth and pots, crates and barrels |
| `tavern` | 90x56 | Recraft `town-a` (right) for the roof with its gable + hand-set storeys | a half-timbered upper storey with three windows, a grey stone ground floor with an arched door, a wall lantern and two wide windows, a bench, barrels, a sign with a gold tankard on an iron bracket |
| `plotMarker` | 12x22 | grid | a tall pale staff with the realm's teal pennant (lit top edge, gold lantern, forked tail), two stakes with a rope, a little soil heap (M2b review: was 10x16 with a small flag) |
| `arrow` | 7x5 x 3 | grid | pointing right (mirrored when flying left): rising, flat, falling; pale fletching, an iron tip |
| `fireArrow` | 7x5 x 3 | grid | as `arrow` with a pitch rag bound behind the head |
| `bolt` | 11x5 x 3 | grid | pointing right: a thick shaft, an iron head, wooden fins |
| `firepot` | 5x5 x 2 | grid | a clay pot with a rag wick, upright and turned a quarter |

The tiers read at a glance: the palisade (20x34, brown stakes) < the stone wall (36x52, two merlons) < the bastion
(44x64: crown on corbels, three merlons, talus, banner).

The towers: an open timber frame (20x48) < a stone tower with merlons and a pennant (24x64); the brazier's iron tripod
(10x14) < the fire tower's stone column (14x40).

The courtyard: smithy (shingles, one chimney, a lean-to) < master smithy (teal slate, two chimneys, a stone annex,
taller); lodge (one timber storey, shingles) < big lodge (two storeys, slate, a crane).

Why the courtyard is hand-set: `court-a` came with a strong violet cast (the timber is a dark purple that maps to
night1, the wood to grey stone) and with details far below a game pixel at the 8x downscale (spears, shield rims,
tools). Converted with colour zones it stayed mush (`build/recraft/lh/bld/parts/barracks-b.png`), so the buildings are
drawn with the masonry, slate, plank, window, door and banner brushes of this lane, following the painting's layout.

The town: the cottages (64x46, one storey) < the big house (72x56, two storeys, two chimneys, a dormer); the market
and the tavern read by their awnings and their sign.

The beacon: the overgrown ruin with its empty cage (masonry to y 108) < new pale courses inside the ruin's shell under
shear legs that rise above it (y 117) < the tower in its scaffold above the ruin (masonry y 105, scaffold y 115) <
the finished tower with banners and the bowl (y 127). All four share the ruin's footprint, ground line and pale stone,
and the silhouette only grows (fix stage: stages 1 and 2 stood lower than the ruin they replace).

The gates: plain oak doors < the same behind an iron grid < steel plates behind a heavy gold-studded grid with the
crest.

### The gate overlays fitted to castleFront.png

Measured on `castleFront.png`: the gateway's dark passage is x 97-141 (world 1337-1381) from row 154 (the arch's crown)
to row 233 (the threshold), row 234 is the front's ink base line, row 235 is empty. The painted portcullis hangs raised
in the arch, its last row at row 176: verticals at x 98, 105, 112, 118-119, 125, 132, 139 (stoneMid with night1
shadows), two-row crossbars at rows 163-164 and 170-171. The passage below row 176 is night0 between night1 reveals
(x 97-101 and 136-141); x 142 is the right jamb's lit edge.

- An overlay frame is placed with its bottom on the ground line at world x 1337 (castleFront x 97), so overlay column c,
  row r is castleFront pixel (97 + c, 176 + r). Rows 58-59 (the ink line and the empty row) stay clear.
- Only passage pixels (night0, night1 in castleFront) are painted; the arch, the jambs and the torch brackets are never
  covered, so the overlay fits whatever frame is shown.
- The leaves fill x 102-135 (cols 5-38) and meet at cols 21/22, the arch's axis; the lowered portcullis (iron and great
  gates) continues the painted bars exactly: verticals at cols 1, 8, 15, 21, 28, 35, 42, crossbars every 7 rows from
  row 1 (castle rows 177, 184, ...), teeth at rows 54-57. Open frames: the leaves lie over the reveals (cols 0-4 and
  39-44), the passage between them stays the front's; the iron and great gates show the raised portcullis' teeth in
  rows 0-2.
- `gateBroken` is placed the same way (bottom on the ground line, x 1337) over the open passage.

## Anchors for the engine (sprite pixels; dx from the left edge, dy up from the bottom row, as layout_m1b.py)

Archer posts, flames and window glass. Masks are tight to the panes: the mock (and the engine's glass masks) glow every
night0, night1 and ink pixel inside a mask, so a mask over an outline would glow too.

| sprite | what | where |
|---|---|---|
| `archerTower` | archers' feet | y 42 (on the deck), foot centres at x 5 and 14 |
| `watchtower` | archers' feet | y 52 (the parapet walk), foot centres at x 4, 10, 15, 20 (the merlons reach y 56) |
| `watchtower` | window glass | mask (dx 10, dy 24, w 4, h 6): the barred window; the arrow slit as a second mask (dx 11, dy 36, w 2, h 7) |
| `fireTower` | flame | `brazierFlame` at (dx 3, dy 37) over the coals; its brazier light from (cx 7, y 41) |
| `catapult` | firepot | in the cup with its bottom-left at (dx 27, dy 17) on frame 0 and (dx 27, dy 13) on frame 1; it leaves from the cup at about (dx 14, dy 21) on frame 2 |
| `ballista` | bolt | the bolt leaves from the stock's front at (dx 0, dy 10), flying left |
| `greatBeacon` | fire | `beaconFire` (48x32 x 4, fix stage) at (dx 8, dy 125): its bottom row, the coal row, lies on the bowl's dark mouth (night0, x 9-54 at row 4), its tongues across the whole mouth; that mouth as a glass mask (dx 9, dy 125, w 46, h 1) still glows as an ember line; the scenes light it with the finale's beacon light (`beacon` kind, x 470, y 130, r 840, 0.45) |
| `barracks` | window glass | (dx 8, dy 26, w 4, h 4), (21, 26, 4, 4), (39, 26, 4, 4), (52, 26, 4, 4); the wall lanterns' glass (23, 14, 1, 2) and (41, 14, 1, 2) |
| `smithy` | forge fire | `brazierFlame` at (dx 15, dy 13) on the coals (row 33, x 14-24); a small brazier-kind light from (cx 19, y 16) |
| `masterSmithy` | forge fire | `hearthFire` at (dx 13, dy 13) on the coals (row 41, x 15-27); light from (cx 21, y 16) |
| `masterSmithy` | window glass | loft (20, 41, 4, 4), annex (47, 16, 4, 4) |
| `lodge` | window glass | (11, 11, 4, 4); optional: the open doorway's dark inside (22, 1, 12, 15) as a dim warm glow |
| `bigLodge` | window glass | (9, 26, 3, 4), (22, 26, 3, 4), (35, 26, 3, 4), (47, 26, 3, 4); optional doorway (22, 0, 14, 16) |
| `smithy` | vent | the gable vent (20, 36, 3, 2) can glow faintly with the forge |
| `bigHouse` | window glass | upper (26, 24, 5, 5), (41, 24, 5, 5); ground (16, 9, 5, 5), (50, 9, 5, 5); the dormer (35, 40, 3, 2) |
| `tavern` | window glass | upper (11, 25, 5, 5), (41, 25, 5, 5), (69, 25, 5, 5); ground (15, 9, 8, 5), (56, 9, 8, 5); the wall lantern by the door (32, 10, 1, 2) |
| `greatBeacon` | slit glass | masks (dx 23, dy 55, w 2, h 9) and (dx 38, dy 33, w 2, h 8) |

## Sheets and prompts

All three end with the shared finish of ART.md ("Crisp detailed 16-bit pixel art, side view, clean hard pixel edges,
no anti-aliasing, limited palette, rich pixel texture and form, evenly lit neutral daylight colours with gentle form
shading, no cast shadows, no glow, no fire, no smoke, no night, no fog, no sky, isolated on a flat solid pure magenta
#FF00FF background, no text, no border."), size 2:1.

1. `beacon-a`: "three separate defensive structures in one row … strict orthographic front elevation … Left: the Great
   Beacon, a tall mighty round stone tower about twice as tall as wide, shaded as a cylinder, fitted grey-violet ashlar
   blocks, a wider battered base, two narrow arrow slits, two iron bands, and at its top a projecting corbelled stone
   ring carrying a huge wide black iron fire bowl, much wider than the tower, held by curved iron ribs … two long
   teal-blue banners with a small gold lantern emblem … Middle: a massive stone bastion … a sloped battered base, a
   crenellated top with wide merlons standing out on a row of stone corbels, two narrow arrow slits, a short teal-blue
   banner. Right: a tall slender square watchtower … a lower half of grey-violet stone blocks, a dark timber upper storey
   with a lookout platform behind a plank parapet, a small pointed roof of dark wooden shingles, a teal-blue pennant …"
   Used as designs: the bowl on ribs over a corbel ring and the banners (greatBeacon), the crown on corbels and the talus
   (bastion), the stone tower with a pennant (watchtower). Its bricks were 4 to 6 px after the downscale (noise), the
   bastion came in three-quarter view with a shaded right face.
2. `court-a`: "five separate medieval castle courtyard buildings … three in the top row and two in the bottom row …
   strict orthographic front elevation … 1, a soldiers' barracks … a long two-storey hall of rough grey-violet stone
   blocks, a dark timber upper storey with small dark windows, a steep teal-blue slate roof, a wide arched wooden door, a
   rack of spears and round wooden shields beside it, a teal-blue banner with a small gold lantern emblem; 2, a small
   blacksmith's forge … an open front under a timber lean-to roof of dark wooden shingles showing a cold dark forge hearth
   and an iron anvil on a stump, one stone chimney; 3, a large master smithy, the same forge grown taller and grander: two
   stone chimneys, a teal-blue slate roof, a big leather bellows, a quenching barrel, iron tools hanging on the wall … 4,
   a builders' lodge … a timber-framed workshop on a low stone base … a wooden plank roof, a big open door, stacked logs,
   a ladder and a wheelbarrow beside it; 5, a big builders' lodge, the same lodge grown larger with a second timber
   storey and a teal-blue slate roof, a wooden crane hoist with a rope and a hook on its gable, stacks of cut stone blocks
   and planks …" Every building used as a design; its violet cast (the timber maps to night1) and the sub-pixel detail
   (spears, shield rims, tools) did not survive a conversion, even with colour zones.
3. `town-a`: "three separate medieval village buildings … Left: a big two-storey timber-framed town house … the upper
   storey jutting out a little over the ground floor, a steep red-brown clay tile roof with a small dormer and two stone
   chimneys … two window boxes with red flowers. Middle: a village market … three wooden market stalls side by side under
   striped cloth awnings (red and cream, teal-blue and cream, ochre and cream), their counters piled with wares … wooden
   crates and barrels stacked in front, no people. Right: a cosy village tavern … a grey stone ground floor with an arched
   wooden door and two wide dark windows, a timber-framed cream plaster upper storey with small windows, a steep red-brown
   tile roof with a chimney, a wooden sign showing a golden tankard hanging from an iron bracket above the door, a wooden
   bench and two barrels by the door …" Its colours sat close to the palette: the roofs of the big house and the tavern
   are kept as converted (`convert --flood`, town palette), the storeys and the market are hand-set after it.

## Context scenes (`tools/scenemock/scene_buildings.py`, `run_buildings.sh`)

`scene_buildings.py` runs `mock.py` once per scene with the extras hook (`extras=<json>`, `actors=off`, `king=<x>`); a
scene names the layout props it replaces (`drop`), and the file removes them by wrapping `layout_m1b.instances()` before
`mock.py` imports the module (the hook adds props but cannot remove any; neither `mock.py` nor `layout_m1b.py` is
touched). The look is run_m1b.sh's plus the renderer's cap on reflected firelight (`litCap=1.6 litNeutral=0.35`, as
run_actors.sh). Each render takes about 2 s; `run_buildings.sh` renders them one at a time with the heat rule. Output:
`build/recraft/lh/preview/bld-<name>.png` (437x201, upscaled x3, git-ignored).

| shot | focus, tod | shows |
|---|---|---|
| `line-night` | 930, 0.95 | the middle line at night: the stone wall with two archers, a fire tower in the second brazier's slot and the brazier, the archer tower with two archers on its deck, the catapult after a throw (lit by the king's lantern), the stake pit, soot creatures at the trap and in the dark, fire arrows in flight and one burning on the ground, arrows, a firepot in the air |
| `line-day` | 930, 0.5 | the same line by day, upgraded: the bastion in two scaffold tiles with a builder hammering on the upper deck and one carrying in, the watchtower with two archers on its parapet, the fire tower, the brazier, the catapult loaded, the stake pit armed |
| `gate-wood`, `gate-iron`, `gate-great` | 1360, 0.95 | the castle gate at night with each tier closed (lit by the gateway's lantern), archers on the wall walk |
| `gate-broken` | 1360, 0.95 | the gate destroyed: gateBroken lit by a fire arrow burning on it, soot creatures pouring through the breach |
| `gate-iron-damaged` | 1360, 0.95 | the iron gate's damaged frame: the burst hole and the bowed bars |
| `gate-great-open-day` | 1360, 0.5 | the great gate open by day: the plated leaves swung in, the raised portcullis' gold-capped teeth |
| `beacon-night` | 470, 0.97 | the Great Beacon lit: the 48x32 blaze across the whole bowl, the bowl's mouth glowing, the finale's beacon light (fix stage), the warden statue behind |
| `beacon-finale` | 560, 0.97 | fix stage: night 20 with the beacon lit: the Lightless King and his creatures lit in its reach (his aura fails there), the gloomweaver dark in its own bubble, archers on the tower at 662 loosing at him, a guard and the king with his lantern behind the palisade |
| `beacon-day` | 470, 0.5 | a lineup by day: the ruin with the plot marker of the unlocked site, beaconBase, beaconTower, greatBeacon (the silhouette grows at every step) |
| `courtyard-dusk` | 1600, 0.77 | barracks (a guardsman at the door), smithy with its forge burning, the well, the lodge with a builder |
| `courtyard-grown` | 1600, 0.77 | the same with masterSmithy (hearthFire in the forge) and bigLodge |
| `town-golden`, `town-night` | 3000, 0.75 / 0.95 | the grown town: bigHouse in plot 2932 between the cottages, the well, citizens; at night its windows and dormer glow |
| `market-golden`, `market-night` | 3270, 0.75 / 0.95 | the cottage of plot 3122, the market (plot 3245) and the tavern (plot 3365); at night the tavern's windows and its door lantern |

## Notes for the lead

- Done in the fix stage: `build-art.sh` runs this lane's script (and the actors') after the scene sprites, and
  `stoneWall`, `palisade` and `ballista` belong to this lane only. `build-art-buildings.sh` rebuilds all 33 sprites of
  this lane byte for byte (checked), and the M1b mocks with the palisade, stone wall and ballista on screen are byte
  for byte the same with the two-frame strips (front 760 at night, approach 1100 and outer line 640 by day, rendered
  against the old one-frame files).
- The extras hook cannot remove a layout prop; `scene_buildings.py` works round it (see "Context scenes"). A `drop`
  option in the hook would make that unnecessary.
- Facing: the ballista and the catapult aim left as drawn (the Gloom is always left); the projectiles point right like
  the actors and need mirroring when they fly left.
- Placement: walls at their left face as `Realm.wallX`; the bastion (44 px) is best placed 4 px left of the stone wall's
  face (936) so both share a centre; it then reaches into the tower slot at 978, so with a bastion standing the tower
  shows best at x 981 or more (the archer tower at 968 overlaps a stone wall's back by 8 px and reads as built against
  it). The scaffold tiles every 24 px from the build's left edge (two tiles over a stone wall or a bastion).
- The archers on towers and walls draw in front of the parapets (actors draw after props), so the parapets never hide
  their legs; the posts above are where their feet go.
- Fix stage, for SPRITES.md and the code lane: `beaconFire` is 48x32 with 4 frames now (the review: "widen the
  contract to about 48x32 with 4 frames"). It goes at the great beacon's (dx 8, dy 125), its bottom row on the bowl's
  mouth: on the planning branch `EntityFrames` places it at `beaconLeft + 20, y: 123`, which becomes `beaconLeft + 8,
  y: 125`; `SpriteID.beaconFire` 24x20 becomes 48x32 and its frame count 3 becomes 4 (the placeholder follows the
  size). Until then the atlas crops the strip around its bottom centre (no crash, a wrong picture). The scenes light
  the beacon with the finale's `beacon` light (fireWhite, r 840, 0.45), as the game's 600 px beacon light is fireWhite
  too; the darker bowl keeps it iron under that light.
- `tools/__pycache__/` and `tools/scenemock/__pycache__/` are untracked byproducts of the python tools; `__pycache__/`
  could go into `.gitignore`.

## Lessons

- A painting's violet cast decides whether a conversion is usable: `town-a` (warm, near the palette) converted almost
  clean, `court-a` (timber painted dark purple) did not, even with colour zones; then the painting is a layout reference
  and the brushes do the pixels.
- Thin parts (poles, ropes, stakes, the catapult's arm) lose their colour to an inner outline; an outline outside the
  shape (`outline_out` in the scratch helpers) keeps a 1-2 px pole wooden.
- Fit an overlay to the painted pixels, not to a box: deriving the mask from the front's passage pixels made every gate
  frame fit, and continuing the painted portcullis bar for bar made the lowered grid read as one with the arch.
- A big glowing light right at an iron bowl turns it white in the mock; light from above the flames keeps the bowl
  dark iron with a firelit rim.

## Open points

- beaconFire size: painted at 48x32 x 4; SPRITES.md and the code lane still say 24x20 x 3 (notes for the lead).
- The courtyard buildings, the market and the storeys of the big house and the tavern are hand-set after the paintings;
  they are crisp and consistent with the bastion and the towers, but a later pass could add more surface texture (moss,
  weathering, timber grain) to match the painted cottages.
- No window-glass masks or lights for these sprites exist in the Swift scene yet: the anchor table is what M2b needs.
- The bastion and the watchtower are front elevations in the stone wall's colours; they share the castle front's stone
  only in hue, not its painted texture.

## Fix stage (09.11.2026, after the art review)

No Recraft images (credits **391 before, 391 after**). The review's high finding on this lane and its medium one:

| Finding | Fix | Build step |
|---|---|---|
| the beacon's fire read as a campfire (24x20 in a 51 px bowl, no bigger than the statue's bowl fire) | `beaconFire` 48x32 x 4: the blaze across the whole mouth, white cores trading heights, wisps and sparks; `greatBeacon`'s bowl one value darker; `bld-beacon-night` with the finale's beacon light and a new `bld-beacon-finale` | grids `beaconFire.txt`, `greatBeacon.txt` |
| beaconBase and beaconTower stood lower than the ruin they replace (masonry 60 and 84 px against the ruin's 104-108) | stage 1 keeps the ruin's shell behind its new courses and lifts its shear legs to y 117; stage 2's masonry reaches y 105, its scaffold 115 | `beaconBase` composed over `beaconRuin.png` (no cage), `beaconTower.txt` raised by 20 rows |

`mock.py`'s extras hook gained an opt-in frame for emitter sprites (`["sprite", id, dx, dy, colour, fades, frame,
frames]`), so a scene can draw a strip whose size SPRITES.md does not list yet; the M1b shots render byte for byte as
before (front 760 at night checked against the old mock).

### Lessons

- A fire must be compared with the other fires in the same frame: next to the statue's bowl fire, a beacon twice its
  width but only as tall read as the same campfire; the climax needs the whole bowl mouth and twice the height.
- A stage of a building should never be lower than the stage before it: Louis reads strength from pictures, and a
  rebuilt site that shrinks reads as a step back even when it is new stone.
- An iron bowl right under a strong light reads pale in a 2D light model (no self-shadow): give dark metal one value
  step less albedo than it would need by day.

## M2b review (09.11.2026)

No Recraft images. Rebuilt through `build-art-buildings.sh` and `build-art.sh castleFront`; every other PNG rebuilds
byte for byte (both lanes run whole, and `build-art.sh castleShadow` after the layout's z change).

| Finding | Fix |
|---|---|
| the finale's tower blew out to near-white lavender under its own pool | `greatBeacon` p/l/s one value step darker (stoneLight/stone/stoneMid); the engine adds a warm scene-only light at the bowl (x 470, y 140, r 90) while it burns and the pool itself is warm amber |
| the damaged palisade barely differed at phone scale | frame 1: the second and the fourth stake snapped above the beam with raw pale breaks, a see-through hole through the planks between the beams with pale broken edges |
| gateBroken's bottom row drew a dotted line across the gateway's grass | row 19 holds three splinters only |
| the plot markers (10x16) were too small to find day 1's first build | `plotMarker` 12x22: a tall pale staff, a bigger teal pennant with the gold lantern, the stakes and rope (SPRITES.md amended); the engine bobs it a pixel |
| the towers' 1 px stonePale edge read as white drainpipes, the shafts showed no stonework | `castleFront`: the right edge column stoneLight, both edge lines broken at the courses, faint course joints in a running bond every 7 rows across the shaft (a post step on `cf-tower-l` before the cylinder shading) |

Engine anchors changed: archers stand on the walks (stone wall dy 42 with posts at 5, 18 and 31; bastion dy 57;
palisade dy 25, the upper beam), line 1's archers on fixed slots clear of the brazier niches (`EntityFrames.lineOnePosts`).
