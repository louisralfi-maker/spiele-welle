# Lanternhold: look 2, "farbig-düster" (the style bible)

The look and world pass of 09.11.2026 evening (DESIGN.md "Louis' decisions (09.11.2026, evening)"), stage 1 of 3: the
direction. Stage 2 paints the world art (the Weltmauer, the shadow land, the valley, depth), stage 3 the creatures. This
file is the rule book for both and for the engine port; every number in it is what the look mocks render
(`tools/scenemock/mock.py look=2`, "The mocks" below).

**The brief, in Louis' words and pictures.** The current look is too bright and cheerful and not at a big studio's
level. He wants it *düster und gemütlich*: gloomy and cozy, more serious, with the depth of the genre's best (trees in
rows behind the play plane, bushes in front). The colour target is `docs/mood/look2-4-farbe.jpg`: deep blue nights,
warm orange fire, dark green forests, muted but colourful. `look2-1-weltmauer.jpg` to `look2-3-stadt.jpg` give mood and
content (the Weltmauer with the castle in its single cleft; the shadow land of dark firs, fog, ruins, a statue and
creatures; the town at dusk with warm windows and chimney smoke). All four are Recraft concepts: match their mood,
depth, values and colour, never their drawing. "Not a copy" (DESIGN.md) holds: no water reflection strip along the
bottom, nothing of Kingdom's palette or silhouette band.

## 1. The look in six rules

1. **Two temperatures.** Everything unlit belongs to one deep blue (hue 220 to 235); everything lit by fire is warm
   orange to gold-white. Firelight is a pool with an edge (the creatures' rule), windows are warm rectangles with a
   pool under them. Nothing is neutral grey for long: darks lift toward navy, never to black.
2. **Values by plane.** The play plane carries the strongest contrast: the darkest darks (stone in shadow, creature
   bodies) right beside the brightest brights (fire). The backdrop is calm and hazy: at night it is *lighter* and bluer
   with distance (aerial perspective), by day paler. The foreground is the darkest plane and has almost no detail.
3. **Rows of depth.** Behind the play plane stand rows: far ridge, mid forest edge, near trees, each farther row paler
   and flatter, with a mist band between them. In front, dark plants pass faster. Under the feet a lane, not the
   soil's cross-section.
4. **Muted but colourful.** Large areas (grass, rock, plaster, roofs) are muted and a value step darker than before;
   saturation lives in fire, the realm's teal banners, gold, warm windows, a few flowers and the sky's afterglow.
5. **Long dusk, deep night.** The day leans to its ends: golden hour, sunset, dusk and a blue hour before the night.
   Night is deep blue with bright fog banks, a moon and few stars.
6. **Cozy against cold.** The shadow land (left) is cold, foggy and dark; the castle is cool stone with warm fires; the
   valley and town (right) carry the warmth: windows, lanterns, hearths, chimney smoke, fireflies at dusk.

## 2. Palette

`tools/palette.txt`, 70 colours (53 before; every old name kept, 42 values moved, 17 new). Painted art stays
**albedo**: evenly lit daylight colours; the engine adds dusk, night, firelight and fog. Each moved colour carries its
old value as `match=#…`: `pixelart.py convert` matches paintings against it by default, so every existing sprite keeps
exactly the palette indices its zones, fills and remaps were tuned on, and only its colours change (checked on the
full rebuild: all 123 sprites keep their index maps). New paintings convert with `--match new`.

**Fixed:** `night0 #0E0B1E`, `night1 #1C1838` and `ink #2A2230` are the window glass colours that `Shaders.metal`
(`lh_is_glass`) and `mock.py` (`GLASS`) light inside window masks. They stay until the engine port moves the glass
test (then `ink` may turn bluer, toward `#24223A`).

### 2.1 Ramps (albedo, dark to light)

| Ramp | Colours | Use |
|---|---|---|
| Night blues (new) | `nightDeep #0A1124` `nightBlue #121C3B` `nightSlate #1E2B52` `nightHaze #2F3F72` | the Gloom's soot and fog banks, deep shade under firs, the darks of shadow-land backdrops, foreground undergrowth |
| Night (tokens) | `night0 #0E0B1E` `night1 #1C1838` `night2 #262E5C` (was `#2E2A5C`) | window glass, outlines of dark things, the Lightless King's cloak |
| Fire (emissive, unchanged) | `ember #D9481F` `fireOrange #FF8A2A` `fireGold #FFC65A` `fireWhite #FFF2C2`, `emberDim #8C2A12` | flames, embers, fire arrows, glow strips; never albedo |
| Firs (new) | `fir0 #0E1B1D` `fir1 #15302C` `fir2 #213F37` `fir3 #30574A` `fir4 #47705A` | the shadow land's firs, the Weltmauer's forested slopes; dark greens toward blue; `fir4` only for lit needle tips |
| Deciduous | `leafDark #223428` `leaf #354E30` `meadow #4F6A3C` `leafLight #78904E` | linden, poplar, orchard, hedges, grass in the valley (all a step darker and less yellow) |
| Mist (new) | `mistDark #6A7393` `mist #98A1BB` `mistLight #C5CBD9` | fog banks painted into backdrops (the engine's ambient tints them: periwinkle at night, pearl by day) |
| Moor (new) | `moorDark #2A2922` `moor #4A4536` | the dead moor's peat and dead grass, the shadow land's lane |
| Castle stone | `stoneDark #2F303E` `stoneMid #464957` `stone #5E6170` `stoneLight #969AA2` `stonePale #BBBCBE` | the castle, walls, statues; cool slate, bluer than the old grey-violet |
| Weltmauer granite | `rockDeep #2D2A30` `rockDark #45403F` `rock #615950` `rockLight #84796B` `rockPale #A89C88` | the cliffs at the cleft (was the gorge's ochre sandstone); warm-neutral grey with umber, so sunset can still warm it |
| Earth | `soilDark #2B2421` `soil #463830` `soilLight #64513F` | lanes, banks, strata |
| Wood | `woodDark #3A261E` `wood #66422F` `woodLight #8A6340` | beams, gates, trunks (less orange) |
| Straw | `straw #A68A54` `strawLight #C4A872` | thatch, fields, hair |
| Skin | `dawnRose #E0A28C` (light) over `tileLight #9E5640` (shade) | faces and hands (less pink) |
| Plaster | `plasterDim #9C8C72` `plaster #C2B294` `parchment #DED2B8` | the town's walls: warm, a value step down from cream |
| Roofs | `tile #7A3F31` `tileLight #9E5640`; realm slate `roofDeep #1B3A4E` `roofLight #3E7790` | town tiles; the castle's and kitchen's teal slate |
| Realm | `banner #2B6584` `gold #E0AE48` `dusk #A04A60` | banners, the lord's circlet, awnings |
| Far | `farDeep #343D5E` `far #4E5A82` `moon #7E89B6` `farPale #A3ADC5` `foam #D4DCE2` | far mountains, snow, waterfall foam |
| Water | `waterDeep #3D6680` `daySky #86A6B6` `foam` | the river (reflections only where the world has water) |
| Creature light (new, emissive) | `wraithDim #34557A` `wraithGlow #7FB0D8` `wraithWhite #E4F2FF`; `violet…`, `teal…` unchanged | stage 3: the hollow cold eyes of the lost people against their ember cracks |

### 2.2 Screen targets (what a render should show, sampled from `look2-4-farbe.jpg`)

| Where (night) | Colour | Luma |
|---|---|---|
| sky, cloud bellies | `#303668` to `#4A4C81`, moonlit cloud tops `#7270AA` | 0.22 to 0.32 |
| far mountains | `#29336C` to `#353F7E` | 0.22 to 0.27 |
| mid forest edge | `#1B2857` to `#354087` | 0.16 to 0.27 |
| fog banks | `#535FBE` to `#8D95F4` (the brightest non-fire values) | 0.40 to 0.60 |
| near firs | `#0B1630` to `#122145` | 0.08 to 0.13 |
| castle stone in shadow | `#0F172F` to `#132041` | 0.09 to 0.12 |
| stone in firelight | `#62232D` to `#96322B` | 0.18 to 0.30 |
| fire | `#FFC65A` to `#FFF2C2` | 0.8 to 0.95 |
| lane | `#15223E` to `#192F4B`, path `#3C3852` | 0.13 to 0.22 |
| foreground | `#0B0B1F` | 0.05 |

By day the same structure holds one octave up: pale blue-grey air, muted greens (`#3E5A3A` to `#6E8A55` on screen at
noon), dark firs, warm plaster, a blue-grey sky (`#5780A8` to `#A8BDC7`), never cyan.

## 3. Value structure per plane

| Plane | Parallax | What it holds | Night | Day |
|---|---|---|---|---|
| sky | 0.05 | gradient (16 dithered bands), clouds, moon, a few stars | `#0D0F26` to `#3D4785` | `#5780A8` to `#A8BDC7` |
| far | 0.2 | the Weltmauer's distant ranges, far mountains, a low fir ridge | hazed 0.62 toward the air: lighter than the mid plane | hazed 0.58, pale |
| mid | 0.5 | the forest edge (shadow land), cliffs at the cleft, valley hills and tree belt, the keep seen from afar | haze 0.46: mid blue, 3 to 4 values | haze 0.28 |
| fogM | 0.62 | a mist band, 56 rows, dense at the ground, fading up | bright periwinkle, the backdrop's brightest | thin pearl |
| near | 0.75 | single trees in loose rows (firs and dead trees in the shadow land, linden, poplar, orchard and willow in the valley) | haze 0.41 toward a darker air: dark blue silhouettes, still lighter than the world's darks | haze 0.12 |
| fogA | 0.9 | the bank behind the play plane, 32 rows: creatures stand dark against it | bright | thin |
| world | 1.0 | the play plane: castle, buildings, actors, the lane | the full range: navy darks to fire | the full range |
| fogB | 1.15 | ground mist over the lane | low and soft | almost none |
| fg | 1.3 | dark plants: ferns and dead grass (shadow land), bushes, grass and flowers (valley), reeds (river) | 0.3 of the ambient: near black, navy | 0.55 of the ambient: dark green |

The fog's share by region: 1.0 in the shadow land, falling to 0.7 at the cleft and in the castle, 0.45 in the valley.

## 4. Light per hour

Eleven keyframes, blended with smoothstep (`core.KEYS2`, `ambient2`), wrapping from night to pre-dawn. Each sets the
sky's top and bottom, the ambient light (colour × strength), the fog (colour × density), the haze, the air (the colour
distance fades to), stars, torch strength, the grade (warmth, saturation), the vignette and the navy lift of the darks.

| Key | Hour | Sky top | Sky bottom | Ambient | Fog | Haze | Air | Stars | Torch | Warmth | Sat | Vignette | Black |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| pre-dawn | 4.6 | `#0F1229` | `#333866` | `#6675D1` × 0.15 | `#4C548F` × 0.50 | 0.45 | `#333D70` | 0.70 | 1.00 | -0.25 | 0.80 | 0.40 | 1.0 |
| dawn | 5.9 | `#424C85` | `#E09E8F` | `#E6B8B2` × 0.40 | `#A899A8` × 0.55 | 0.60 | `#A899AD` | 0.10 | 0.70 | 0.18 | 0.88 | 0.26 | 0.5 |
| morning | 7.4 | `#6185B2` | `#D1C7B8` | `#FFEBD6` × 0.74 | `#CCCCCC` × 0.28 | 0.45 | `#C2C7CC` | 0 | 0.10 | 0.08 | 0.92 | 0.18 | 0.2 |
| noon | 12.0 | `#5780A8` | `#A8BDC7` | `#F5F5F0` × 0.92 | `#BDC7D1` × 0.10 | 0.32 | `#ADBFCC` | 0 | 0 | 0 | 0.90 | 0.16 | 0.2 |
| afternoon | 16.2 | `#577AA8` | `#C7BDA8` | `#FFE6C7` × 0.84 | `#CCC2B2` × 0.14 | 0.38 | `#BDB8B2` | 0 | 0 | 0.14 | 0.94 | 0.18 | 0.2 |
| golden | 17.8 | `#4C578F` | `#F5A361` | `#FFB870` × 0.66 | `#E6A375` × 0.28 | 0.55 | `#D19E85` | 0 | 0.20 | 0.45 | 1.00 | 0.22 | 0.3 |
| sunset | 18.8 | `#292B66` | `#EB754C` | `#E69975` × 0.44 | `#85667A` × 0.32 | 0.45 | `#806680` | 0.10 | 0.60 | 0.32 | 1.02 | 0.28 | 0.5 |
| dusk | 19.5 | `#141A45` | `#9E5C6B` | `#8085D6` × 0.30 | `#525999` × 0.38 | 0.42 | `#4C548F` | 0.35 | 1.00 | 0.08 | 0.95 | 0.34 | 0.8 |
| blue hour | 20.3 | `#0F1436` | `#424F8F` | `#6680E6` × 0.18 | `#47549E` × 0.42 | 0.40 | `#38478A` | 0.60 | 1.00 | -0.22 | 0.86 | 0.40 | 1.0 |
| night | 21.4 | `#0D0F26` | `#3D4785` | `#5C73E0` × 0.14 | `#454F9E` × 0.45 | 0.40 | `#334080` | 0.70 | 1.00 | -0.30 | 0.82 | 0.42 | 1.0 |

Sun and moon heights follow the old ramp's arc (sun 1.0 at noon, -0.6 at night; moon 0.6 at night).

**Against the game clock** (12 s per hour): the day 06:00 to 19:00 runs morning, noon and afternoon with golden hour
from 17:00; the horn at 19:00 falls between sunset and dusk, so torches light while the afterglow still burns; the
waves (from 21:15) come in the deep night, after a blue hour of about 12 s; first light at 05:00 rises from pre-dawn
into a rose dawn with morning mist (fog 0.55).

**Warm pools.** Windows glow at 1.3 × the old glass strength, their light pool 1.6 × wider and 0.7 strong (was 0.4);
torches, braziers, lanterns, hearths and candles 1.15 × stronger against the darker ambient, and their light a step
deeper toward orange, so a pool reads as fire on stone, not white-gold: torch `#FFA84C` (was `fireGold`), lantern
`#FFB257`, candle `#FFB861`, fire arrow `#FFBD66` (was `fireWhite`); braziers and the hearth stay `fireOrange`. Glass on
the mid plane (the keep seen from afar) glows at 0.45: it stands in haze, and two full panes read as eyes.

**The grade.** Saturation from the key (warm light keeps at least 1.08); the cold grade pushes blue (the old one added
red, which made the night violet); the darks lift toward navy `#080A18` below luma 0.22 (× the key's black); a
highlight shoulder above 0.82; the vignette from radius 0.42 to 1.25 (× the key's strength, darker at night).

## 5. Depth per region

| Region | far (0.2) | mid (0.5) | near (0.75) | world (1.0) | fg (1.3) | Lane |
|---|---|---|---|---|---|---|
| **The shadow land** (x 0 to 1240) | the far mountains; a low fir ridge at the horizon | the forest's edge, two rows of firs at the foot of the sky, in mist; the warden statue and the keep on its shoulder rise above it (stage 2: ruins of older lines, weathered statues of past lords, the dead moor) | single firs (72 to 132 px) and dead trees in loose groups with gaps; the tallest away from the defence lines | the lines, braziers, creatures | ferns, dead grass, fallen branches, roots; tops at most 18 px above the ground, sparse at the lines | the moor track: peat with two ruts, a mossy verge, a dark bank |
| **The cleft and the castle** (1240 to 2430) | the Weltmauer filling the sky behind the castle (stage 2) | the cliffs of the cleft (granite), the keep's crown | none: the castle is the hero; inside the walls nothing between the cliffs and the courtyard | the castle front, courtyard, hall | none in the gate view; a little rubble by the courtyard at most | cobbles from the cleft through the castle |
| **The valley and the town** (2430 to 3680) | the inner ranges, snow on top | the hills, a tree belt with hedges along the valley floor, the windmill, the keep seen from the town; dark firs on the slopes (stage 2) | linden, poplar pairs, orchard trees in front of the fields, in a loose row behind the houses | houses, market, tavern, well, bushes behind the people | bushes, grass clumps, a few flowers, with gaps in front of the square | the earth lane: packed earth, ruts, a grass verge (a cobbled square is stage 2 art) |
| **The river end** (3680 to 3900) | the inner ranges | the far shore | two willows on the near bank | the bank, the bridge stumps | reeds and cattails | the lane ends at the bank |

Rows: in each region the far, mid and near rows never line up (different spacing per row), each farther row has one
value step less contrast and one step more haze, and no row repeats at a fixed rhythm on screen.

## 6. Rules for the art

- **Detail density by plane.** Far: big shapes, 2 or 3 values, no outline. Mid: 3 or 4 values, clusters of 3 px and
  more, no outline. Near: 4 values, a lit edge on the upper left, a readable silhouette (tiers of a fir, the crown's
  lobes), no outline. World: the full ramp, interior detail, a 1 px dark outline only on the shadow side and the ground
  contact (selective, never black: `ink`, `nightBlue` or the ramp's darkest). Foreground: 2 or 3 values, silhouette
  only.
- **Light direction.** From the upper left in every painting (the sun rises behind the town on the right but sets
  behind the shadow land; one rule keeps the set consistent); the engine adds warm light and cast shadows.
- **Dithering.** No dithered gradients inside sprites: the engine's smooth light does the gradients. Dither only as
  texture: the fog strips' 4x4 Bayer, at most 20 % noise in foliage clumps, the sky's 16 bands. Never a checker over a
  large flat area.
- **Texture.** Clusters of at least 2 px; no lone pixels (`pixelart.py post --clusters`); stone in courses, foliage in
  clumps with their own lit side, granite in strata.
- **Animation (engine, after the port).** Trees on the near plane sway ±1 px at the crown's top, 3 to 4 s period, a
  phase per tree; foreground grass and ferns in 2 frames; the fog bands drift (fogM 3, fogA 5, fogB 8 px/s); sparks
  rise from braziers and fire arrows (8 to 14 px, 0.6 s); fireflies in the valley at dusk (8 to 12 emissive
  `fireGold` dots wandering slowly); chimney smoke rises from every lived-in house (three puffs over 40 px, fading);
  embers drift in the battle. Nothing moves on the far plane but clouds.
- **Readable on a phone.** The lord keeps his cool moonlight rim (0.6) and his lantern; foreground plants stay low
  where he walks. Creatures read as dark silhouettes against the bright fog bands, with their ember edges and (stage 3)
  cold eyes; the fog band behind the play plane exists for this. Light pools keep their visible edge. The UI sits on
  top: the vignette darkens the corners, which carries the clock and the realm strip; keep bright backdrop features out
  of the top-right corner.
- **The creatures (stage 3; Louis: much creepier, more character).** Lost people of smoke: gaunt, far too long,
  stooped; hollow eyes of cold dead light (`wraith…`) instead of glowing dots; torn clothes, broken lanterns, ember
  cracks; each kind its own silhouette, gait and sound of movement (the sootling a crawling child-sized husk, the hound
  a thing on all fours that was a man, the brute a swollen giant in a tattered cloak, the weaver a robed figure with a
  dead lantern, the Lightless King a tall crowned shape whose face is a void). Unlit they are opaque navy-black bodies
  with an ember edge and a cold rim; in light their torn detail shows. Readable from 14 to 110 px.

## 7. Engine values (for the port; Swift stays untouched in this stage)

The renderer keeps its passes; look 2 changes these values and adds three things.

| Value | Today (`Look`, `AmbientRamp`) | Look 2 (`mock.py LOOK2`) |
|---|---|---|
| ambient lift | 0.55 | **0.30** (the night world at about a third of its albedo) |
| night tint (colourise) | (1.03, 0.86, 1.66) × 0.6 | **(0.72, 0.95, 1.85) × 0.72** (deep blue, not violet) |
| far / mid share of ambient | 0.9 / 0.7 | 0.85 / 0.72, **near 0.85** |
| far haze | 0.34 + haze × 0.62 toward the horizon | **0.40 + haze × 0.55 toward the hour's air** (lavender at warm hours, 0.6) |
| mid haze | day 0.2, night 0.36, + haze × 0.26 | day 0.2, night 0.36, + haze × 0.25, toward air × 0.86 |
| near haze (new plane) | – | day 0.08, night 0.36, + haze × 0.12, toward air × 0.78; point light share 0.5 |
| mist band fogM (new) | – | parallax 0.62, 56 rows, density fog × 1.5, brightness × 1.4 |
| fog bank behind the world | 24 rows | **32 rows**; fog × region share (1.0 shadow land, 0.7 castle, 0.45 valley) |
| foreground ambient | day 0.9, night 0.43 | **day 0.55, night 0.30**; light share 0.55 |
| lane sky light (new) | – | the lane's top 8 rows take × 1.1 (day) to × 1.4 (night) ambient: they face the sky |
| window light | radius 8, × 0.4 | radius × 1.6, × 0.7; glass × 1.3; mid-plane glass × 0.45 |
| fire lights | × 1; torch and lantern `fireGold`, fire arrow `fireWhite` | × 1.15; torch `#FFA84C`, lantern `#FFB257`, candle `#FFB861`, fire arrow `#FFBD66` |
| clouds | sun 1.1, fill 1.7, haze 0.25 | sun 1.0, fill 1.5, haze 0.3, **moonlight 0.35** at night |
| grade | warmth tint adds red when cold | the cold tint pushes blue (1 + 0.20 w, 1 + 0.05 w, 1 − 0.15 w); **navy lift** `#080A18` below luma 0.22; vignette per key 0.16 to 0.42 |
| bright haze band | 0.45 | 0.2 (the mist band does its work) |
| king's rim | 0.5 | 0.6 |
| ramp | 8 keys | the 11 keys of section 4 |

Unchanged: light gain 3.0, hot knee 0.95, the cap on reflected light (1.6, neutral 0.35, cool 0.6), the bounce (0.5,
dusk 2.2), bloom (0.75, threshold 0.34), smooth pools with their edge band.

New in the port: the near plane (an atlas plane between mid and world, lit like the mid plane plus a point-light
share), the mist band (a third fog strip), the per-hour air colour, vignette and navy lift in the ramp, the lane's sky
light, the region share of the fog. The glass test (`lh_is_glass`) keeps `night0`, `night1`, `ink`.

## 8. The mocks (stage 1)

- `tools/depthart.py <dir>` paints the depth stand-ins (firs, dead tree, fir belts, linden, poplars, orchard, willow,
  bushes, tree belt, fern, meadow and reed strips, lane tiles, smoke, sparks, fireflies) from the palette. Not game
  art: stage 2 replaces them.
- `tools/scenemock/layout_look2.py` places them and lists what look 2 drops from `layout_m1b.py` (the far gorge wall
  and the rock lips: the shadow land is open; the valley's foreground rocks).
- `tools/scenemock/scene_look2.py` holds the six direction scenes; `run_look2.sh` renders each in the old look (the
  committed art of `f35272a` with the renderer's values of today) and the new look (the rebuilt art, `look=2`), one at
  a time with the heat rule, into `build/recraft/lh/preview/look2/`, plus the two 2x3 contact sheets.
- The scenes: the front at night with the battle (focus 900, 22:48, as the runner's shots 31 and 32), the castle front
  at dusk (1360, 19:12), the courtyard and great hall at dusk (1700, 19:12), the town square at dusk (3040, 19:12), the
  town at noon (2800), the river end at golden hour (3720, 17:53). A render takes about 3 s (python 3.13); all twelve
  and both sheets about 90 s, the CPU stays under 70 °C.
- `mock.py look=1` (the default) still renders every old mock byte for byte (checked against `f35272a`'s mock.py on
  two frames); `art=`, `depth=` and `lut=` (preview a palette change on the old art) are new options.

**What the mocks show.** The night battle now reads like the colour target: deep blue, the open shadow land with fir
rows paling into fog, the statue and the keep as silhouettes above the mist, the fog bank behind the play plane
turning every creature into a dark shape with an ember edge, the fires and the lit wall the only warm values; the
foreground is the darkest band. The castle at dusk is cool slate between near-black granite under an afterglow sky,
its torches and braziers the focal warmth. The courtyard and hall: blue dusk outside, the hall's hearth and candles
warm inside. The town at dusk is the cozy end: warm windows and lanterns, trees in rows behind the houses, smoke, a
violet-blue valley under orange cloud rims. Noon is muted and serious (dark greens, rows of trees, a blue-grey sky)
instead of bright and cheerful; golden hour at the river is warm with lavender distance. The before set (`sheet-old`)
is the renderer of today: ochre rock, violet nights with every plane at one value, the soil cross-section.

## 9. Open after stage 1 (for stage 2 and the port)

- The shadow land's backdrop is still stand-ins: procedural fir rows over the old far mountains; the warden statue
  still stands in its niche cut from the gorge wall (now a rock pillar). Stage 2 paints the open shadow land (far
  forest horizon and the Weltmauer's foot, ruins of older lines, weathered statues, the dead moor) as Recraft
  concepts converted with `--match new`.
- The Weltmauer itself: the sky behind the castle needs the wall of peaks above the clouds; today the old gorge wall
  high pieces and throat rock carry the cleft in the new granite.
- The cliffs at the cleft read near-black at dusk: their painted form (granite strata) needs a lit top edge and one
  value step more inside; stage 2 repaints them in granite.
- The valley's mid art (hills with fields) is the old painting in new colours; it wants firs on the slopes, a hazier
  painted distance and fewer bright field patches.
- The town square wants cobbles and a few props (cart, barrels, a notice board); houses want lit interiors at night.
- The keep seen from the town still shows two big panes; one lit pane and a glimmer, as in the gorge, would end the
  "eyes".
- Depth stand-ins are symmetric and regular (cone firs, round crowns); stage 2's trees need irregular tiers, broken
  branches, wind-bent crowns, and 3 variants each.
- The cliffs behind the courtyard show the old strata painting at a large scale and read as a giant brick wall; the
  Weltmauer's inner face wants vertical granite, ledges and a few firs.
- At dusk the town's plaster takes a lavender-pink from blue ambient plus warm pools; a warmer, darker plaster (or a
  little less window pool on the walls) would keep it cream-warm. The lane at dusk is nearly black away from the
  lanterns.
- The night battle has no darkness bank in the mock (the game draws it); stage 3 should give the Gloom's bank the
  look-2 treatment (navy soot, drifting motes, cold eye glints) together with the creatures.
