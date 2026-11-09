# Lanternhold: art (milestone 1, first real pixel art)

Every M1 prop and backdrop sprite is real pixel art now: 25 PNGs in `Resources/Art/`, one per `SpriteID`, each exactly
its `SpriteID.size`, 8-bit RGBA, binary alpha, one texel = one game pixel, all colours from the shared palette
`tools/palette.txt`. Actors, flames, glows, fog, sky, stars and the darkness bank stay procedural in this milestone.

The look: albedo only. Every piece is painted in even daylight colours with gentle form shading, no baked night, no
glow, no light pools and no cast shadows; windows, the hearth's firebox and the lantern glass are dark. The engine adds
dusk, night, firelight, fog and the emissive flames and window glow on top. Original look only: cool grey-violet
castle stone, ochre gorge rock, a teal-blue realm colour (banners, slate roofs), cream plaster and red-brown tiles in the
town; no water strip and nothing of Kingdom's palette.

## Credits

Recraft (`bash tools/recraft.sh`, model `recraftv4_1`, 35 credits per image): **1406 before, 1091 after: 315 spent**
on 9 generations (budget 400). No `rmbg`: every sheet was painted on a flat key colour and keyed locally.

## Pipeline

`tools/pixelart.py` is pure python 3 (zlib and struct, no PIL). One image per run, each run 0.5 s or less on this Mac
(the CPU stayed between 28 and 40 °C the whole time). Commands:

| Command | What it does |
|---|---|
| `boxes <sheet>` | keys the background and prints the bounding box of every painted piece |
| `cut <sheet> <out> --box …` | writes the raw crop of a sheet |
| `convert <in> <out> --size WxH …` | key to alpha (auto border colour, or `--flood` for background joined to the border only, so key-like paint inside stays), the key hue's anti-alias fringe removed within 2 px of the background, crop to content, block downscale to exactly WxH (dominant 4-bit colour bin per block, per-channel median when no bin has 35 %), Lab-nearest palette mapping (lightness weighted 1.3), orphan clean-up, binary alpha, then the optional steps below |
| `grid <grid.txt> <out>` | builds a sprite from a hand-set text grid (legend `X = paletteName`, `---`, one row per pixel row) |
| `preview <in> <out> [--night --light x,y,r]` | nearest-neighbour upscale; `--night` multiplies a cold ambient and adds warm point lights, roughly as the engine will |
| `info <in>` | size, colour type, opaque share, palette colours used, off-palette or semi-transparent pixels |

`convert` options: `--box` (cut a sheet piece), `--fit stretch|contain|cover`, `--only` / `--exclude` (palette subset
per piece), `--zone names@rect[@gain]` (map a rect with its own palette subset, e.g. wooden doors in a stone facade),
`--fill name:rect`, `--patch grid.txt@x,y` (hand-set overlay, `?` keeps a pixel), `--outline none|darken|name`,
`--outline-skip-bottom`, `--tile` (seamless horizontally: the piece is downscaled `overlap` columns wider, then a
minimum-error seam per row, found by dynamic programming, joins the continuation into the start), `--window dx,dy`
(stamps a dark 6x8 window recess at a scene window offset), `--sat --gain --gamma --warm` (colour nudges before
mapping). The fire ramp (`fireWhite`, `fireGold`, `fireOrange`, `ember`) is tagged `emissive` in the palette and never
used for painted albedo.

To rebuild everything (needs the raws in `build/recraft/lh/`, git-ignored): `bash games/lanternhold/tools/build-art.sh`
(or name single sprites). It converts one image at a time, pauses between them and waits below 70 °C if the CPU reaches
80 °C. A full run reproduces the committed files byte for byte. Previews go to `build/recraft/lh/preview/`.

### Palette (`tools/palette.txt`, 48 colours)

The 20 DESIGN.md tokens plus 28 albedo mid-tones: castle stone `stoneMid #544A60`, `stonePale #CDC2C6`; gorge rock
`rockDeep #3E3036` … `rockPale #CDAE78` (5); wood `woodDark #4A2E22`, `woodLight #A0703F`; straw `straw #C49A52`,
`strawLight #E0C07A`; teal slate `roofDeep #1F4660`, `roofLight #4F92AE`; town tiles `tile #8E4A36`, `tileLight #B8664A`;
greens `leafDark #2E4630`, `leaf #4A6B3A`, `leafLight #9DBF62`; earth `soilDark #3A2A26`, `soil #5E4434`,
`soilLight #876448`; plaster `plaster #D9C9A8`, `plasterDim #B4A284`; far mountains `farDeep #3C4468`, `far #5A6890`,
`farPale #B4C0D8`; water `waterDeep #5E8FB0`, `foam #E6F0F2`. Each piece maps onto a subset (far pieces use only the
five cool aerial blues, so distance reads by colour; see `build-art.sh` for every subset).

## Assets

| Sprite | Size | Source | Notes |
|---|---|---|---|
| `farMountain` | 160x70 | `s1-far-1` box 16,100,916,376 | stretched 1.4x taller (sharper peaks); five aerial blues, no outline |
| `farPeak` | 110x95 | `s1-far-1` box 972,40,1444,444 | snow cap in `foam`/`farPale` |
| `gorgeCliff` | 70x210 | `s2c-cliffs-1` left | broad layered ochre rock column, moss on ledges, `rockDeep` outline |
| `gorgeEndCliff` | 120x220 | `s2b-cliffs-1` right | craggy left edge, straight right edge (the world's end); 3 right columns filled |
| `waterfall` | 24x200 | `s2-cliffs-1` middle | the only piece used from the first cliff sheet |
| `gatehouse` | 120x100 | `s3-castle-1` piece 2 | wooden doors re-mapped with a wood zone; window recesses stamped at the scene's (18,62) and (96,62); teal banner with a gold lantern |
| `castleTower` | 32x120 | `s3-castle-1` piece 1 | squeezed to 0.63 width; teal cone roof |
| `castleWall` | 40x90 | `s3-castle-1` piece 3, left part | seamless (`--tile`), regular crenels hand-set (`grids/castleWall-crenels.txt`), window recess at the scene's (17,58) on every tile |
| `backGate` | 60x84 | `s3-castle-1` piece 4 | wood zone on the door |
| `chapel` | 160x96 | `s4-chapel-1` left | stretched 1.67x wider (reads as a long nave); four lancet windows, bell turret |
| `hallInterior` | 260x90 | `s5-hall-1` top | cut-away great hall: thick end walls, timber trusses, five teal banners, columns, dais with a teal runner at the throne's x, plank floor; `--warm 22` so the painting's violet cast maps wood to wood |
| `throne` | 14x24 | `grids/throne.txt` | hand-set from the converted Recraft throne (which came out muddy): wood frame, teal cushion, gold trim and finials |
| `hearth` | 26x20 | `grids/hearth.txt` | hand-set stone fireplace; firebox exactly x 5-20, rows 7-16 under the `hearthFire` sprite (dx 5, dy 3), logs inside |
| `kitchen` | 120x80 | `s6-town-1` piece 2 | stone ground floor, timber-framed plaster upper storey, teal slate roof, big chimney |
| `house` | 64x46 | `s7-defence-1` piece 5 | cottage repainted on the defence sheet (the first one was cramped and half in shade); roof zone in `tile`/`tileLight` |
| `valleyHill` | 150x46 | `s6-town-1` piece 6 | grassy hill with round trees; stretched 1.5x taller |
| `well` | 18x20 | `grids/well.txt` | hand-set (the converted well was muddy): shingle roof, crank, rope, bucket, stone ring |
| `lanternPost` | 6x24 | `grids/lanternPost.txt` | hand-set; dark glass exactly x 1-4, rows 2-5 under `lanternGlass` (dx 1, dy 18) |
| `field` | 80x8 | `grids/field.txt` | hand-set 16 px motif (wheat, cabbage, furrows) five times: seamless |
| `palisade` | 20x34 | `grids/palisade.txt` | hand-set from the Recraft palisade's design: five sharpened stakes, two lashed beams |
| `stoneWall` | 36x52 | `s7-defence-1` piece 2, left part | two merlons; edge and base tidied with `--fill` |
| `ballista` | 28x16 | `grids/ballista.txt` | hand-set (the painted one's thin lines vanished): siege crossbow on wheels, aimed left at the Gloom |
| `brazier` | 10x14 | `grids/brazier.txt` | hand-set iron bowl of dark coals on a tripod; the bowl top under `brazierFlame` (dx 1, dy 11) |
| `torchPost` | 4x14 | `grids/torchPost.txt` | hand-set; burnt iron cup in rows 0-1 under `flame` (dx 0, dy 12) |
| `ground` | 64x26 | `s7-defence-1` piece 6 | seamless tile: grass edge, packed earth with pebbles, stones along the bottom |

## Window glass in the art versus the scene

`PlaceholderScene` puts each `windowGlow` (6x8) at fixed offsets from the prop's bottom-left. The gatehouse and the
curtain wall got recesses stamped exactly there. The chapel, kitchen and cottage keep their painted windows, which sit
elsewhere; the glow should move onto them (the art agent may not edit `Core/`):

| Prop | Scene offsets now (dx, dy) | Painted glass (x range, rows from the top) | Suggested offsets (dx, dy) |
|---|---|---|---|
| chapel | (30,52) (77,52) (124,52) | lancets x 15-28, 50-65, 86-99, 121-134, rows 52-77 | (18,28) (54,28) (89,28) (125,28) |
| kitchen | (28,40) (86,40) | x 25-32 and 78-86, rows 41-47 | (26,32) (79,32) |
| house | (14,14) (44,14) | x 10-14 and 45-49, rows 32-37 | (9,7) (44,7) |
| gatehouse | (18,62) (96,62) | stamped | unchanged |
| castleWall | (17,58) | stamped | unchanged |

## Sheets and prompts

Every prompt ends with the shared finish: "Crisp detailed 16-bit pixel art, (side view,) clean hard pixel edges, no
anti-aliasing, limited palette, rich pixel texture and form, evenly lit neutral daylight colours with gentle form
shading, no cast shadows, no glow, (no fire, no smoke,) no night, no fog, no sky, isolated on a flat solid pure magenta
#FF00FF background, no text, no border." Recraft painted a hot pink (#EC1C9C … #FC1494) instead of pure magenta every
time; the auto key handles it.

1. `s1-far-1` (2:1), used: farMountain, farPeak. "Pixel art sprite sheet for a side-scrolling fantasy game: three
   separate distant landscape backdrop pieces with wide empty gaps between them. Top left: a broad rugged mountain range,
   wide and low, with several jagged rocky summits and ridges. Top right: one tall sharp alpine peak with a snow cap,
   about as wide as it is tall. Bottom row, full width: a long low rolling green valley hill, very wide and flat, with a
   few small round trees along its crest. Mountains in cool blue-grey distant rock colours (#5A6890, #3C4468, #8494B8)
   with pale snow (#E6F0F2); the hill in muted greens (#4A6B3A, #6E9A4A) with ochre earth. Every piece has a flat
   straight bottom edge." Reject: the hill (13:1, far too flat for 150x46; stretched it became teal blotches).
2. `s2-cliffs-1` (1:2), used: waterfall. "… three separate tall pieces of a mountain gorge … Left: a narrow towering
   rock cliff pillar, three times taller than wide, … stacked blocky rock strata … Middle: a thin tall waterfall ribbon …
   Right: a broad massive rock cliff wall …" Reject: both cliffs came out as brick pillars ("blocky strata" was read as
   masonry) in a salmon colour.
3. `s2b-cliffs-1` (2:3), used: gorgeEndCliff (right). "… two separate natural mountain crags … Left: a tall narrow
   towering natural rock crag, about three times taller than wide, wider at its base, … a ragged pointed summit. Right:
   a massive broad natural cliff, about twice as tall as wide, its left side a rugged stepped silhouette …, its right
   side a straight vertical edge … Natural organic rock only: no bricks, no masonry, no stone blocks, no columns. Muted
   warm ochre sandstone with grey-brown shadows (#A8845A, #826248, #CDAE78, #5C4640, #3E3036)." The left crag was the
   first gorgeCliff; rejected after a scene mock: repeated 16 times it read as a row of twisted cones.
4. `s2c-cliffs-1` (2:3), used: gorgeCliff (left). "… two separate massive natural rock cliff walls of a mountain gorge …
   Left: a towering massive cliff column about three times taller than wide, broad all the way up with only a slight
   taper, rugged irregular left and right edges with jutting ledges, notches and overhangs, a broken jagged top. Right:
   an even broader cliff wall … Both made of weathered natural rock with horizontal sedimentary layers, deep vertical
   fractures, boulders wedged in cracks, a few small dark green shrubs and moss on ledges. Natural organic rock only: no
   bricks, no masonry, no blocks, no pillars, no spirals, no twisting." Reject: the right wall (sawtooth ledges).
5. `s3-castle-1` (2:1), used: castleTower, gatehouse, castleWall, backGate. "Pixel art sprite sheet of medieval castle
   building pieces …, four separate pieces in one row … 1: a tall slender square castle tower, four times taller than
   wide, crenellated battlements, a pointed teal-blue slate cone roof, narrow arrow slits. 2: a wide gatehouse, a little
   wider than tall, a big central round-arched gateway closed by heavy wooden doors with iron bands, one small arched
   window high on each side, crenellated battlements along the top, a teal-blue banner with a small gold lantern emblem
   hanging beside the gate. 3: a plain section of castle curtain wall, about twice as tall as wide, crenellated top,
   ashlar stone courses, one small arched window, made to repeat seamlessly left to right. 4: a smaller back gate, a bit
   taller than wide, a round-arched wooden door and battlements. Cool grey-violet weathered stone (#6B6078, #A99CA8,
   #3A3346), dark brown wood (#7A4E2E), teal-blue roofs and banners (#2F6E8E). All windows dark and unlit."
6. `s4-chapel-1` (2:1), used: chapel. "… two medieval castle buildings … Left: a stone castle chapel, wider than tall
   (about five to three), a long nave with three tall narrow pointed-arch windows evenly spaced in a row, buttresses
   between them, a steep teal-blue slate roof, a small square bell turret with a pointed teal roof rising at one end, a
   modest arched wooden door. Right: a castle kitchen house …" Reject: the kitchen (half of it painted in deep shade;
   zone fixes left it patchy). Both came out square, not wide: the chapel is stretched.
7. `s5-hall-1` (2:1), used: hallInterior (throne and hearth only as references). "… Top, spanning the full width: the
   interior of a medieval castle great hall shown in cross-section like a dollhouse cut-away, a wide panel about three
   times wider than tall: thick cut stone walls at both ends, a timber roof with heavy wooden trusses and beams along the
   top, the back wall of grey-violet ashlar stone with stone columns, hanging teal-blue banners with a small gold lantern
   emblem, a raised wooden dais with a teal carpet in the middle, a stone chimney breast …, a wooden plank floor. Empty
   room: no people, no throne, no furniture, no fire, no candles. Bottom row …: left, a tall-backed carved wooden throne
   with teal cushions and gold trim, front view, empty; right, a stone fireplace with a raised hearth, a mantel shelf
   and a dark empty firebox holding two logs, no fire." (No chimney breast was painted.)
8. `s6-town-1` (2:1), used: kitchen, valleyHill (well and lantern post only as references). "… medieval village pieces
   …, six separate pieces … 1, a cosy timber-framed village cottage …; 2, a larger castle kitchen house, one and a half
   times wider than tall, rough grey stone ground floor with an arched wooden door, a timber-framed upper storey with
   cream plaster and two small square windows, a steep teal-blue slate roof, one big stone chimney. … 3, a round stone
   village well with a little wooden roof and a bucket; 4, a tall thin wooden lantern post with an iron lantern hanging
   from a hook at the top; 5, a long low strip of crop field …; 6, a long low rolling green hill, three times wider
   than tall, grassy, with a few round trees and bushes on its crest. … Every piece evenly lit with no darker shaded
   side." Rejects: the cottage (roof twice the wall height, shaded gable), the field (mush at 8 px), the well (muddy).
9. `s7-defence-1` (2:1), used: house, stoneWall, ground (palisade, ballista and brazier only as references). "… medieval
   defence and village pieces …, six separate pieces … 1, a short section of wooden palisade, taller than wide, five
   sharpened vertical log stakes bound with rope and a horizontal cross beam; 2, a section of thick stone defensive
   wall, a bit taller than wide, rough grey-violet blocks, a crenellated top; 3, a wooden siege ballista on a sturdy
   wheeled frame, wider than tall, its bow and bolt aimed to the left; 4, an empty iron fire brazier, a wide bowl of dark
   coals on three legs, no fire. Middle: 5, a cosy timber-framed village cottage, wider than tall, the cream plaster
   walls as tall as the roof, dark wooden beams, a steep red-brown clay tile roof, a wooden door in the middle and one
   small square window on each side, a small stone chimney, front view of the long side, evenly lit. Bottom, across the
   full width: 6, a long horizontal cross-section strip of the ground, about five times wider than tall, a thin top layer
   of short grass tufts and dirt, below it packed brown earth with embedded pebbles and grey stones." Lesson: its
   crimson roof sat within the key distance of the pink background; `--flood` keying fixed it.

## Lessons

- Recraft ignores requested aspect ratios inside a sheet; pieces come out near square. Stretch up to about 1.7x reads
  fine in pixel art (wide chapel, tall mountains); beyond that, crop (`--fit cover`) or paint again.
- Sprites of 20 px and less are better hand-set as grids (palette letters) than downscaled; the painting still gives the
  design. Thin lines (ballista, legs, rope) never survive a block downscale.
- Recraft paints everything with a violet cast: wood came out mauve and mapped to grey stone until `--warm` or a
  `--zone` with wood colours.
- Look at a composed scene mock, not only single pieces: the first cliff was fine alone and wrong as a repeated row.

## Open points

- The mid plane places gorge cliffs in pairs every 160 px (0.5 parallax), which shows as twin pillars with sky between
  rather than a closed gorge wall. Spacing of about 60 px or a second cliff variant would read as a continuous gorge.
- Window glow offsets for chapel, kitchen and house (table above).
- The mid-plane cliffs are as bright as the world plane in daylight albedo; depth separation relies on the engine's
  fog and the 0.85 shade.

# Milestone M1b: the gorge, the castle that seals it, the open valley (09.11.2026)

Louis on 09.11.: the game must be "extrem schön"; in the first mock the castle looked small and did not block the only
way out of the gorge, and the town stood under the cliffs. M1b adds 25 sprites for the new world (DESIGN.md "The world",
"The castle", decisions log) and the layout they are placed by. The old gorgeCliff, waterfall, gorgeEndCliff,
gatehouse, castleTower and backGate files stay; the M1b scene no longer uses them.

## M1b credits

Recraft (`recraftv4_1`, 35 per image): **1021 before, 706 after: 315 spent** on 9 generations (budget 450 for all of
M1b). The fg rocks, the overhangs and the river's bank, water and bridge piers are procedural (`tools/procart.py`); no
palette colours were added (the 48 cover the valley's greens and the castle).

## M1b pipeline additions

- `pixelart.py split <in> <A> <B> <C>`: cuts a seamless `--tile` panorama into equal tiles that join A-B-C-A.
- `pixelart.py compose <out> --size WxH --layer path@x,y[@flip][@box=…]`: stacks finished sprites (hero pieces built
  from parts of two paintings, a part moved inside a sprite).
- `convert --fill-holes NAME:rect`: paints only transparent pixels (a see-through gateway becomes a dark passage).
- `tools/procart.py fgrock|overhang|riverbase`: seeded silhouettes and the river base, exactly reproducible.
- Intermediate parts go to `build/recraft/lh/m1b/parts/`; the paintings are `build/recraft/lh/m1b/*-1.png`
  (git-ignored). `build-art.sh` rebuilds every M1b sprite (group names `gorgeWall`, `valleyFar`, `valleyMid` write
  their three tiles).

## M1b assets

| Sprite | Size | Plane | Source | Notes |
|---|---|---|---|---|
| `gorgeWallA`, `gorgeWallB`, `gorgeWallC` | 192x190 each | mid | `gorgewall-a` full width | one panorama at 576x190 (`--tile`, `--sat 1.5` so the moss maps to leaf), cut A-B-C; jagged top 105 to 190 px, dead trees, the rock-cut stair (B), the cave mouth (B/C), ledges with moss; no straw tones (ochre maps to rock) |
| `gorgeWallHigh` | 192x240 | mid (and world, see layout) | `rocks-a` left | the high rock at 180x240 composed over gorgeWallA's first 40 columns (bottom-aligned), so its left edge carries on from gorgeWallC; overhang at the top right |
| `wardenStatue` | 96x200 | mid | `statue-a` | robed, crowned, bearded king holding a lantern bowl before his chest; the bowl's hollow filled `night0` at x 37-59, rows 43-46 (the scene's fire: `hearthFire` at dx 40, dy 153) |
| `fgRockA`, `fgRockB`, `fgRockC` | 96x36 each | fg | `procart.py fgrock --style a/b/c` | rockDeep boulders over a soilDark band, a broken rockDark rim, ferns and grass in leafDark, roots (C); flat bottom, the profile falls to nothing at both ends |
| `fgOverhangA`, `fgOverhangB` | 128x48 each | fg | `procart.py overhang --style a/b` | flat top, ragged underside with two lobes, thin lips at the ends, hanging roots (soilDark, woodDark) and vines with leaves |
| `cliffFlank` | 80x240 | world | `rocks-a` middle | natural rock (columns 11-44) turning into fitted grey-violet masonry (columns 45-65) on the right; mirrored for the right side |
| `castleFront` | 240x236 | world | composed: towers from `castlefront-b` (left tower, 58x236, `--gain 1.1`, mirrored for the right), gatehouse from `castlefront-a` (132x156 at x 54, y 80, `--gain 0.86`, the painting's tower corners cleared) | towers 0-57 and 182-239 to the top edge, crenellated on corbels, six arrow slits each (x 29-34 / 205-210); gatehouse x 54-185, 156 px: wall walk at y 124 (merlon tops 127), two brazier niches (dark x 87-107 and 132-153, rows 91-105: `brazierFlame` at dx 93 / 138, dy 130), torch brackets (flame at dx 90 / 145, dy 61), gateway x 97-143, 83 px high (wider and taller than the 40x56 asked: the king and soldiers pass with room), raised portcullis in the arch, two teal banners with a gold lantern |
| `castleKeep` | 150x250 | world, behind the gatehouse | `keepgate-a` left | three-quarter view: square keep, four corner turrets with teal cones and pennants, a central slate roof, a long teal banner; the painting's shaded left face lifted with zones (albedo), dark windows (masks in the layout) |
| `castleBackGate` | 200x200 | world | `keepgate-a` right | two small towers with teal cones and pennants, banners, open wooden doors; the see-through gateway filled `night1` (`--fill-holes`), the keyed-out flower boxes refilled `tileLight`; lantern glass x 39-43 and 155-159 (dy 60), windows in the layout |
| `gorgeMouth` | 120x230 | mid | `rocks-a` right | a crag on the left stepping down into grassy slopes with trees and bushes (squeezed 0.64x: reads as a steep crag) |
| `valleyFarA`, `B`, `C` | 192x90 each | far | `valleyfar-a` box 210,280,1450,560 | one panorama (`--tile`): snowy pale ranges in `farDeep`/`far`/`moon`/`farPale`/`foam` (no green was needed); the layout raises them to y 55 so they show above the hills |
| `valleyMidA`, `B`, `C` | 192x110 each | mid | `valleymid-a` box 0,300,1536,545 | one panorama (`--tile`, `--warm 12` so the teal hill shadows map to green): rolling hills, a forest edge, hedged wheat fields, far farmhouses and the winding river; hill tops 69 to 110 px |
| `windmill` | 40x60 | mid | `props-a` top right | stone tower, wooden cap, four lattice sails (static) on a grassy knoll |
| `beaconRuin` | 64x130 | world | `props-a` top left | broken round tower with ivy and fallen stones; the painted fire cage floated above it and is set down into the broken top (compose) |
| `riverEnd` | 220x64 | world (y -26) | `procart.py riverbase` + `props-a` reeds | the bank level with the ground tile at its left edge (row 38), sloping to the water at row 50; water to the right edge with ripples and a darker dithered bottom; two bridge piers with broken arch springers reaching for each other; the painted reeds and cattails at the right end and by the bank |

## M1b paintings and prompts

All end with the shared finish of milestone 1 ("Crisp detailed 16-bit pixel art, side view, … isolated on a flat solid
pure magenta #FF00FF background, no text, no border."; the two valley panoramas say "no clouds" and drop the fire and
smoke clauses).

1. `castlefront-a` (1:1), used: the gatehouse. "the mighty front facade of a medieval fortress that seals a mountain
   pass, seen straight on, perfectly symmetric … two massive round stone towers … a tall wide gatehouse … two square
   stone brazier niches on its battlements, a deep round-arched gateway … a raised iron portcullis grid … iron torch
   brackets … two long teal-blue banners, each with a small gold lantern emblem …" Reject: its towers (squat, each 37 %
   of the width: the whole read as a toy fort).
2. `castlefront-b` (4:5), used: the towers. "the towering front of a huge medieval fortress that blocks a narrow
   mountain gorge … taller than wide … two tall slender round towers … each four times taller than wide … overhanging
   crenellated battlements on stone corbels and many narrow arrow slits …" Reject: its gatehouse (narrow and tall).
3. `gorgewall-a` (2:1), all used. "one long continuous natural sandstone cliff face, the far wall of a deep mountain
   gorge seen straight on, a wide panorama … filling the lower three quarters … jagged irregular skyline … gnarled dead
   trees and dangling roots along the rim … deep vertical fractures … one dark cave mouth … a narrow stair cut into the
   rock … Natural organic rock only: no bricks, no masonry, no blocks, no pillars, no columns, no repeated shapes …"
4. `rocks-a` (2:1), all used: gorgeWallHigh, cliffFlank, gorgeMouth. "three separate natural rock pieces of a deep
   mountain gorge … Left: a towering massive cliff wall … rising from a lower jagged shoulder on the left to an
   overhanging crag … Middle: a tall narrow rock buttress … natural rugged rock on its left side that gradually turns
   into rough fitted castle masonry of grey-violet stone blocks along its straight right edge … Right: the end of a
   gorge, a tall rocky crag on the left that falls away to the right in big steps and ledges into green grassy slopes …"
5. `statue-a` (1:2), used. "a colossal ancient statue of a robed king carved out of a sandstone cliff, front view …
   a simple crown and a long hooded robe … with both hands he holds a large round stone lantern bowl raised high in
   front of his chest, the hollow of the bowl empty and dark … weathered and eroded: deep cracks, chipped edges, moss
   and small ferns …"
6. `keepgate-a` (2:1), used: castleKeep, castleBackGate. "Left: a tall square castle keep, almost twice as tall as
   wide … four slender round corner turrets with pointed teal-blue slate cone roofs and small teal pennant flags … Right:
   a friendly castle back gate … two smaller round towers … a wide open round-arched gateway, its heavy wooden doors
   swung open … two iron lanterns with dark unlit glass … wooden flower boxes with red and yellow flowers …" The keep
   came in three-quarter view; the gateway was painted see-through.
7. `valleyfar-a` (2:1), used. "a long distant panorama of far-away mountains seen across a wide valley … a few broad
   snow-capped summits, long gentle ridges … two or three hazy layers … Soft aerial perspective, only cool hazy
   colours …" It came boat-shaped (the sides slant in); the box keeps the full-width band.
8. `valleymid-a` (2:1), used. "a long panorama of a wide green river valley in the middle distance … gently rolling
   green hills … patchwork fields of green and golden wheat divided by dark hedgerows; the dark edge of a forest of
   round trees … a winding pale blue river glinting between the lower hills …" Its dark bottom band was the most common
   border colour, so the key is given explicitly (`--key '#EC149C'`).
9. `props-a` (2:1), used: beaconRuin, windmill, the reeds. "Top left: a tall ruined stone beacon tower … an empty
   black iron fire cage basket standing on the broken top … Top right: a small round stone windmill … four big lattice
   sails … Bottom, spanning the full width: a long low side-view cross-section of a riverbank … two broken stone stumps
   of an old arched bridge standing in the water, tall reeds and cattails …" Reject: the river strip (its bank rose 50
   px above the water, which cannot sit below a ground line with 26 rows under it; the stumps read as boulders).

## M1b composition (`tools/scenemock/`)

- `layout_m1b.py` is the world as data, for the Swift port: planes and parallax, the backdrop borders (far 641, mid
  1274, world 2330 = the back gate's passage, fg 2964), tile cycles, every instance with plane, x, y, z, flip, shade,
  emitters (emissive sprites and window-glass masks) and lights. Gameplay positions are unchanged (beacon 470, lines
  640 and 940, gate 1300-1420); the town and the river moved 100 px right (world 3900 wide).
- `mock.py` is the renderer agent's pure-python composite with `layout=m1b`; `run_m1b.sh` renders the seven shots
  (`build/recraft/lh/preview/m1b-*.png`, 437x201 upscaled x3, about 3 s each).
- Decisions from the mocks:
  - The keep stands centred behind the gatehouse (x 1286), not behind the hall: from the gorge it fills the gap
    between the towers above the wall walk, which makes the front read as one fortress. It cannot also be seen from the
    town on the world plane (no camera shows both 1300 and 2400), so the same sprite stands on the mid plane at 1240:
    from the town it rises behind the hills at the left, beyond the back gate; the two copies are never on screen
    together.
  - The throat is one mass of rock on the world plane: gorgeWallHigh (mirrored on the left) stands behind each
    cliffFlank. A lone flank read as a giant tree trunk; with the high rock behind it the front sits between two cliffs
    that rise above the screen.
  - The warden statue stands 34 px low (plinth behind the ground strip) so the crown and the bowl fire stay on screen.
  - Far and mid valley sets start with a lead-in tile left of their border (the first tile's left edge is a straight
    cut); it is hidden behind the gorge mouth and the 200 px back gate at the back-gate view.

## M1b lessons

- Two paintings can make one hero piece: the best towers of one and the best gatehouse of the other, composed in palette
  space, with `--gain` to match their values. Near-square output makes this the only way to exact proportions.
- A side-view river cannot be painted as a bank above the water: water must lie below the ground line, and only 26
  rows exist there. Procedural base plus painted reeds solved it.
- A rock piece alone in front of a darker backdrop reads as a tree trunk; give it mass behind it.
- Big flat key-coloured holes inside a sprite (an open gateway) survive `--flood` keying as key colour and map to the
  nearest palette colour; key normally and refill with `--fill-holes`.

## M1b open points

- The castle front and back gate are front views and the keep a three-quarter view; side by side in the courtyard this
  is acceptable, but a later repaint of the keep in front view would be cleaner.
- The courtyard still shows only the old curtain wall and the well (barracks, smithy and lodge are later art).
- The statue is faint by day (carved rock in the same ochre as the wall); at night its bowl fire carries it.
- The engine needs: the `anchor: top` placement for the overhangs, window-glass masks from rects (or windowGlow sprites
  at the listed offsets), mid-plane lights (the statue's fire), and a world width of 3900.
