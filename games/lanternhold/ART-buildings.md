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

The tiers read at a glance: the palisade (20x34, brown stakes) < the stone wall (36x52, two merlons) < the bastion
(44x64: crown on corbels, three merlons, talus, banner).

## Notes for the lead

- `build-art.sh` still has `stoneWall` as the milestone 1 conversion (one frame) in its list. Running it would write
  the one-frame file over the two-frame strip: `stoneWall` belongs to `build-art-buildings.sh` now and should leave
  `build-art.sh`'s list. `palisade` and `ballista` stay in `build-art.sh`: their grids hold both frames.
