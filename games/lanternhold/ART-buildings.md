# Lanternhold: art of the buildings, overlays and projectiles (M2b art lane, 09.11.2026)

The building, overlay and projectile sprites of `SPRITES.md`, painted as real pixel art to the contract: one row of
frames per PNG, 8-bit RGBA, binary alpha, palette colours only, albedo in even daylight (no baked light, no glow), dark
glass where windows are, everything that glows left to the engine (window glass masks, flame sprites, glow strips).
`tools/build-art-buildings.sh` rebuilds every sprite of this lane (names below, or all); `ART.md` keeps the pipeline,
the palette and the lessons this builds on.

## Credits

Recraft (`bash tools/recraft.sh`, `recraftv4_1`, 35 credits per image), budget 150 for this lane:

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
- Recraft sheets plus `pixelart.py convert` for the big buildings (see the sprite table for each).
- Every two- and three-frame sprite keeps frame 0 where SPRITES.md says the old one-frame PNG stays: `palisade`,
  `stoneWall` and `ballista` frame 0 are byte for byte the milestone 1 pixels, so the M1b shots do not change.

## Sprites

| id | size x frames | method | notes |
|---|---|---|---|
| `palisade` | 20x34 x 2 | grid `tools/grids/palisade.txt` | frame 1: one stake snapped above the beam (raw pale wood at the break), a point split off, a plank piece torn out (see-through), a split, the foot charred with ash-grey flecks, a burst lashing |
| `stoneWall` | 36x52 x 2 | grid `buildings/stoneWall.txt` (frame 0 = the milestone 1 conversion) | frame 1: the right merlon shattered to a ragged stump, a chip off the left merlon, a branching crack down four courses, two face stones knocked out, soot up the left side, two chips at the foot |
| `bastion` | 44x64 x 2 | grid `buildings/bastion.txt` (design from `beacon-a`'s middle piece) | dressed ashlar in the stoneWall's colours, three merlons on a crown band, stepped corbels with dark machicolation holes, a talus over the lowest 22 rows, a central arrow slit, a teal banner with a gold lantern; frame 1: the right merlon and crown corner broken off, a crack past the slit, two blocks knocked out, soot at the right foot, the banner torn short |
| `rubbleWood` | 24x10 | grid | a fallen palisade: a stake lying with its point left, a second across it, raw splinters |
| `rubbleStone` | 40x14 | grid | tilted blocks in a lumpy heap, a broken merlon on top, cracked blocks, chips |
| `scaffold` | 24x40 | grid | seamless at 24 px (poles every 12 px; ledgers, plank decks and the braces wrap): two decks, alternating braces, lashings, footing stones |

| `gateWood` | 46x60 x 3 | grid | tier 1: oak leaves of vertical planks, two iron straps, ring handles (the portcullis stays up in the arch); damaged: two plank pieces torn out with raw splinters, a strap hanging loose, a split, the foot charred and burnt through; open: the leaves swung in against the passage walls |
| `gateIron` | 46x60 x 3 | grid | tier 2: iron-banded leaves behind the lowered portcullis, continuing the painted bars to pointed teeth; damaged: two bars bowed far apart round a hole broken through the leaves, crossbars burst, a bar's foot torn away, scorch; open: only the teeth show under the arch, banded leaves swung in |
| `gateGreat` | 46x60 x 3 | grid | tier 3: steel-plated leaves behind a heavy portcullis (three-pixel bars, gold bosses, gold-capped teeth) with the realm's crest on its centre crossing; damaged: a plate staved in with bent bars round it, a plate torn away (oak beneath), the crest cracked and chipped, a tooth snapped, scorch; open: heavy gold-capped teeth under the arch, plated leaves with gold rivets swung in |
| `gateBroken` | 46x20 | grid | a broken leaf lying tilted, a beam across the front, a bent piece of the portcullis with its teeth, splinters |

| `archerTower` | 20x48 | grid | tier 1: a timber frame tower (splayed legs, braces, a ladder, a deck with a plank parapet) |
| `watchtower` | 24x64 | grid (design from `beacon-a`'s right piece) | tier 2: a slender stone tower, merlons on corbels, an arrow slit, a barred window, an oak door, a teal pennant |
| `fireTower` | 14x40 | grid | tier 2 of the brazier: a stone column on a stepped plinth with an iron fire basket of coals |
| `ballista` | 28x16 x 2 | grid `tools/grids/ballista.txt` | aimed left; frame 0 loaded (the milestone 1 pixels), frame 1 loosed: no bolt, arms sprung forward, the string straight between the tips |
| `catapult` | 32x24 x 3 | grid | a mangonel throwing left: the stop beam end-on on a braced upright, a torsion skein, a rear post and winch; rest (a firepot with a rag wick in the cup), wind (the arm hauled down by the taut rope), throw (the arm against the padded stop, the cup empty) |
| `stakePit` | 24x8 x 2 | grid | armed: three sharpened stakes leaning toward the Gloom; sprung: splintered stubs with soot, the points lying on the rim |

The tiers read at a glance: the palisade (20x34, brown stakes) < the stone wall (36x52, two merlons) < the bastion
(44x64: crown on corbels, three merlons, talus, banner).

The towers: an open timber frame (20x48) < a stone tower with merlons and a pennant (24x64); the brazier's iron tripod
(10x14) < the fire tower's stone column (14x40).

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

Archer posts, flames and window glass:

| sprite | what | where |
|---|---|---|
| `archerTower` | archers' feet | y 42 (on the deck), foot centres at x 5 and 14 |
| `watchtower` | archers' feet | y 52 (the parapet walk), foot centres at x 4, 10, 15, 20 (the merlons reach y 56) |
| `watchtower` | window glass | mask (dx 10, dy 24, w 4, h 6): the barred window; the arrow slit as a second mask (dx 11, dy 36, w 2, h 7) |
| `fireTower` | flame | `brazierFlame` at (dx 3, dy 37) over the coals; its brazier light from (cx 7, y 41) |
| `catapult` | firepot | it leaves the cup at frame 2's cup position, about (dx 13, dy 21); in frames 0 and 1 the pot sits in the cup at (dx 27, dy 16) and (dx 27, dy 12) |
| `ballista` | bolt | the bolt leaves from the stock's front at (dx 0, dy 10), flying left |

## Notes for the lead

- `build-art.sh` still has `stoneWall` as the milestone 1 conversion (one frame) in its list. Running it would write
  the one-frame file over the two-frame strip: `stoneWall` belongs to `build-art-buildings.sh` now and should leave
  `build-art.sh`'s list. `palisade` and `ballista` stay in `build-art.sh`: their grids hold both frames.
