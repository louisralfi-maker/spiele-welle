# Lanternhold: look 2, "farbig-düster" (the style bible)

The look and world pass of 09.11.2026 evening (DESIGN.md "Louis' decisions (09.11.2026, evening)"), stage 1 of 3: the
direction. Stage 2 paints the world art (the Weltmauer, the shadow land, the valley, depth), stage 3 the creatures and
the lord. This file is the rule book for both and for the engine port; every number in it is what the look mocks
render (`tools/scenemock/mock.py look=2`, "The mocks" below). Stage 1 was revised the same night after a critic's
review (section 10, "Critic and fixes"); the sections below carry the revised values.

**The brief, in Louis' words and pictures.** The current look is too bright and cheerful and not at a big studio's
level. He wants it *düster und gemütlich*: gloomy and cozy, more serious, with the depth of the genre's best (trees in
rows behind the play plane, bushes in front). The colour target is `docs/mood/look2-4-farbe.jpg`: deep blue nights,
warm orange fire, dark green forests, muted but colourful. `look2-1-weltmauer.jpg` to `look2-3-stadt.jpg` give mood and
content (the Weltmauer with the castle in its single cleft; the shadow land of dark firs, fog, ruins, a statue and
creatures; the town at dusk with warm windows and chimney smoke). All four are Recraft concepts: match their mood,
depth, values and colour, never their drawing. "Not a copy" (DESIGN.md) holds: no water reflection strip along the
bottom, nothing of Kingdom's palette or silhouette band. And for the creatures, Louis on 09.11.: the shadow monsters
must become extremely creepy, with more character (section 6, "The creatures").

## 1. The look in six rules

1. **Two temperatures.** Everything unlit belongs to one deep blue (hue 220 to 235); everything lit by fire is warm
   orange to ember red. Firelight is a pool with an edge (the creatures' rule): its own colour at the core, ember red
   toward the rim, and inside it the fire displaces the cold. Windows are warm rectangles with a small pool under
   them. Nothing is neutral grey for long: darks lift toward navy, never to black.
2. **Values by plane.** The play plane carries the strongest contrast: the darkest darks (stone in shadow, creature
   bodies) right beside the brightest brights (fire). The backdrop is calm and hazy: at night it is *lighter* and bluer
   with distance (aerial perspective), by day paler. The foreground is the darkest plane and has almost no detail.
3. **Rows of depth.** Behind the play plane stand rows: far ridge, mid forest edge, near trees, each farther row paler
   and flatter, with a mist band between them. In front, dark plants pass faster, a few fronds rising over the lane.
   Under the feet a lane that catches the sky, not the soil's cross-section.
4. **Muted but colourful.** Large areas (grass, rock, plaster, roofs) are muted and a value step darker than before;
   saturation lives in fire, the realm's teal banners, gold, warm windows, a few flowers and the sky's afterglow.
5. **Long dusk, deep night.** The day leans to its ends: golden hour, sunset, dusk and a blue hour before the night.
   Night is deep blue with bright periwinkle fog banks, a moon over a high cloud deck and few stars.
6. **Cozy against cold.** The shadow land (left) is cold, foggy and dark; the castle is cool stone with warm fires; the
   valley and town (right) carry the warmth: windows, lanterns, hearths, the warm great hall, chimney smoke, fireflies
   at dusk.

## 2. Palette

`tools/palette.txt`, 71 colours (53 before; every old name kept, 42 values moved, 18 new). Painted art stays
**albedo**: evenly lit daylight colours; the engine adds dusk, night, firelight and fog. Each moved colour carries its
old value as `match=#…`: `pixelart.py convert` matches paintings against it by default, so every existing sprite keeps
exactly the palette indices its zones, fills and remaps were tuned on, and only its colours change (checked on both
rebuilds: 0 structural differences). New paintings convert with `--match new`; in the default mode an old painting
never lands on a look-2 colour unless an `--only` list names it.

**Fixed:** `night0 #0E0B1E`, `night1 #1C1838` and `ink #2A2230` are the window glass colours that `Shaders.metal`
(`lh_is_glass`) and `mock.py` (`GLASS`) light inside window masks. They stay until the engine port moves the glass
test (then `ink` may turn bluer, toward `#24223A`).

### 2.1 Ramps (albedo, dark to light)

| Ramp | Colours | Use |
|---|---|---|
| Night blues (new) | `nightDeep #0A1124` `nightBlue #121C3B` `nightSlate #1E2B52` `nightHaze #2F3F72` | the Gloom's soot and its bank, the creatures' bodies and rags (stage 3), outlines of dark things; **never in the albedo of ground, plants or rock** (the engine's night tint turns those blue; painted night blues are darkened twice) |
| Night (tokens) | `night0 #0E0B1E` `night1 #1C1838` `night2 #262E5C` (was `#2E2A5C`) | window glass, the Lightless King's cloak |
| Fire (emissive, unchanged) | `ember #D9481F` `fireOrange #FF8A2A` `fireGold #FFC65A` `fireWhite #FFF2C2`, `emberDim #8C2A12` | flames, embers, fire arrows, glow strips; never albedo |
| Firs (new) | `fir0 #0E1B1D` `fir1 #15302C` `fir2 #213F37` `fir3 #30574A` `fir4 #47705A` | the shadow land's firs, its foreground and lane bank, the Weltmauer's forested slopes; `fir3`/`fir4` for the lit upper left of each tier (the moon key catches them) |
| Deciduous | `leafDeep #17241B` (new, after the critic) `leafDark #223428` `leaf #354E30` `meadow #4F6A3C` `leafLight #78904E` | linden, poplar, orchard, hedges, grass in the valley; `leafDeep` the valley's undergrowth and lane bank |
| Mist (new) | `mistDark #6A7393` `mist #98A1BB` `mistLight #C5CBD9` | fog painted into backdrops (the engine's ambient tints it: periwinkle at night, pearl by day) |
| Moor (new) | `moorDark #2A2922` `moor #4A4536` | the dead moor's peat and dead grass, the shadow land's lane |
| Castle stone | `stoneDark #2F303E` `stoneMid #464957` `stone #5E6170` `stoneLight #969AA2` `stonePale #BBBCBE` | the castle, walls, statues; cool slate |
| Weltmauer granite | `rockDeep #39353D` `rockDark #544D4B` (both a step lighter after the critic) `rock #615950` `rockLight #84796B` `rockPale #A89C88` | the cliffs at the cleft; warm-neutral grey with umber, so sunset can still warm it |
| Earth | `soilDark #2B2421` `soil #463830` `soilLight #64513F` | lanes, banks, strata |
| Wood | `woodDark #3A261E` `wood #66422F` `woodLight #8A6340` | beams, gates, trunks |
| Straw | `straw #A68A54` `strawLight #C4A872` | thatch, fields, hair |
| Skin | `dawnRose #E0A28C` (light) over `tileLight #9E5640` (shade) | faces and hands |
| Plaster | `plasterDim #A0875F` `plaster #C8AE84` (yellower after the critic) `parchment #DED2B8` | the town's walls: warm sand-cream by day, so blue dusk light plus an amber pool stays off lilac |
| Roofs | `tile #7A3F31` `tileLight #9E5640`; realm slate `roofDeep #1B3A4E` `roofLight #3E7790` | town tiles; the castle's and kitchen's teal slate |
| Realm | `banner #2B6584` `gold #E0AE48` `dusk #A04A60` | banners, the lord's circlet, awnings |
| Far | `farDeep #343D5E` `far #4E5A82` `moon #7E89B6` `farPale #A3ADC5` `foam #D4DCE2` | far mountains, snow, waterfall foam |
| Water | `waterDeep #3D6680` `daySky #86A6B6` `foam` | the river (reflections only where the world has water) |
| Creature light (new, emissive) | `wraithDim #34557A` `wraithGlow #7FB0D8` `wraithWhite #E4F2FF`; `violet…`, `teal…` unchanged | stage 3: the one cold eye of a lost person (`wraithWhite`, at most 1 px of `wraithDim` around it; `wraithGlow` only for the Lightless King's crown points) |

### 2.2 Screen targets (what a render should show, sampled from `look2-4-farbe.jpg`)

| Where (night) | Colour | Luma | The mock after the critic |
|---|---|---|---|
| whole frame | mean, share below 0.08 | 0.22, 7 to 9 % | 0.21, 9 % |
| sky, cloud bellies | `#303668` to `#4A4C81`, moonlit cloud tops `#7270AA` | 0.22 to 0.32 | top rows 0.18 (the HUD sits there) |
| far mountains | `#29336C` to `#353F7E` | 0.22 to 0.27 | 0.21 |
| mid forest edge | `#1B2857` to `#354087` | 0.16 to 0.27 | in the mist band |
| fog banks | `#535FBE` to `#8D95F4` (the brightest non-fire values) | 0.40 to 0.60 | cores 0.50 to 0.54 |
| near firs | `#0B1630` to `#122145` | 0.08 to 0.13 | bodies 0.08 to 0.09, lit tiers to 0.22 |
| castle stone in shadow | `#0F172F` to `#132041` | 0.09 to 0.12 | – (the keep on the mid plane 0.13 to 0.17) |
| stone in firelight | `#62232D` to `#96322B` | 0.18 to 0.30 | `#59311F`, 0.19 to 0.23 |
| fire | `#FFC65A` to `#FFF2C2` | 0.8 to 0.95 | as painted |
| lane | `#15223E` to `#192F4B`, path `#3C3852` | 0.13 to 0.22 | 0.13 (median) |
| foreground | `#0B0B1F` | 0.05 | 0.05 |

By day the same structure holds one octave up: pale blue-grey air, muted greens (`#3E5A3A` to `#6E8A55` on screen at
noon; the mock: lit `#758B51`, mid `#617050`, shade `#344B35`), dark firs, warm plaster, a blue-grey sky (`#5780A8` to
`#A8BDC7`), never cyan. At golden hour the foliage stays olive (lit tops near hue 50, shade near 73), never khaki.

## 3. Value structure per plane

| Plane | Parallax | What it holds | Night | Day |
|---|---|---|---|---|
| sky | 0.05 | gradient (16 dithered bands), the old cloud bands plus a high cloud deck, moon, a few stars | `#1C2152` to `#4A549E`, cloud tops moonlit | `#5780A8` to `#A8BDC7` |
| far | 0.2 | the Weltmauer's distant ranges, far mountains, a low fir ridge | hazed 0.62 toward the air: lighter than the mid plane | hazed 0.58, pale |
| mid | 0.5 | the forest edge (shadow land), cliffs at the cleft, valley hills and tree belt, the keep seen from afar | haze 0.46: mid blue, 3 to 4 values; the moon key on lit albedo | haze 0.22 |
| fogM | 0.62 | the mist band `d2MistBand` (448x60): billows over a dense foot | bright periwinkle (× 1.8), the backdrop's brightest | thin pearl |
| near | 0.75 | single trees in loose rows (firs and dead trees in the shadow land, linden, poplar, orchard and willow in the valley) | haze 0.22 toward air × 0.62: dark blue silhouettes whose lit tiers catch the moon (bodies 0.08, tiers to 0.2) | haze 0.08 |
| fogA | 0.9 | the bank `d2FogBank` (384x40) behind the play plane: creatures stand dark against its dense core | bright | thin |
| world | 1.0 | the play plane: castle, buildings, actors, the lane | the full range: navy darks to fire; silhouette tops catch the sky (ledge light) | the full range |
| fogB | 1.15 | the low mist `d2FogLow` (320x24) over the lane | low and soft | almost none |
| fg | 1.3 | dark plants: ferns and dead grass (shadow land), bushes, grass and flowers (valley), reeds (river) | 0.45 of the ambient: near black, navy; fronds stand against the lit lane | 0.55 of the ambient: dark green |

The fog's share by region (per screen column): 1.0 in the shadow land, falling to 0.7 at the cleft and in the castle,
0.45 in the valley.

## 4. Light per hour

Ten keyframes (the first draft said eleven; there are ten), blended with smoothstep (`core.KEYS2`, `ambient2`),
wrapping from night to pre-dawn. Each sets the sky's top and bottom, the ambient light (colour × strength), the fog
(colour × density), the haze, the air (the colour distance fades to), stars, torch strength, the grade (warmth,
saturation), the vignette, the navy lift of the darks and, new after the critic, the light on the clouds' sunlit tops
(the low sun's own colour × strength; at night the moon lights them instead).

| Key | Hour | Sky top | Sky bottom | Ambient | Fog | Haze | Air | Stars | Torch | Warmth | Sat | Vignette | Black | Cloud tops |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| pre-dawn | 4.6 | `#1A1C42` | `#454C85` | `#6675D1` × 0.15 | `#5C66B2` × 0.50 | 0.45 | `#3D4A8A` | 0.30 | 1.00 | -0.25 | 0.80 | 0.34 | 1.0 | dim |
| dawn | 5.9 | `#424C85` | `#E09E8F` | `#E6B8B2` × 0.40 | `#A899A8` × 0.55 | 0.60 | `#A899AD` | 0.10 | 0.70 | 0.18 | 0.88 | 0.26 | 0.5 | `#F0AD94` |
| morning | 7.4 | `#6185B2` | `#D1C7B8` | `#FFEBD6` × 0.74 | `#CCCCCC` × 0.28 | 0.45 | `#C2C7CC` | 0.00 | 0.10 | 0.08 | 0.92 | 0.18 | 0.2 | `#D9CCBD` |
| noon | 12.0 | `#5780A8` | `#A8BDC7` | `#F5F5F0` × 0.92 | `#BDC7D1` × 0.10 | 0.32 | `#ADBFCC` | 0.00 | 0.00 | 0.00 | 0.96 | 0.16 | 0.2 | `#EBEBE6` |
| afternoon | 16.2 | `#577AA8` | `#C7BDA8` | `#FFE6C7` × 0.84 | `#CCC2B2` × 0.14 | 0.38 | `#BDB8B2` | 0.00 | 0.00 | 0.14 | 0.96 | 0.18 | 0.2 | `#E6CFB2` |
| golden | 17.8 | `#4C578F` | `#F5A361` | `#FFD1A3` × 0.66 | `#E6A375` × 0.28 | 0.55 | `#D19E85` | 0.00 | 0.20 | 0.32 | 1.00 | 0.22 | 0.3 | `#FFBA7A` × 1.15 |
| sunset | 18.8 | `#292B66` | `#EB754C` | `#EBA875` × 0.44 | `#85667A` × 0.32 | 0.45 | `#806680` | 0.05 | 0.60 | 0.32 | 1.02 | 0.28 | 0.5 | `#FF8C4B` × 1.40 |
| dusk | 19.5 | `#1C2154` | `#B0634F` | `#708FD1` × 0.30 | `#6169B2` × 0.38 | 0.42 | `#575E9E` | 0.20 | 1.00 | 0.08 | 0.95 | 0.30 | 0.8 | `#D97059` |
| blue hour | 20.3 | `#1C2454` | `#4F5CA8` | `#6680E6` × 0.18 | `#5C69C7` × 0.42 | 0.40 | `#4554A1` | 0.25 | 1.00 | -0.22 | 0.86 | 0.34 | 1.0 | 0 (the moon) |
| night | 21.4 | `#1C2152` | `#4A549E` | `#5C73E0` × 0.14 | `#5C66CC` × 0.45 | 0.40 | `#404F99` | 0.30 | 1.00 | -0.30 | 0.82 | 0.34 | 1.0 | 0 (the moon) |

Sun and moon heights follow the old ramp's arc (sun 1.0 at noon, -0.6 at night; moon 0.6 at night).

**Against the game clock** (12 s per hour): the day 06:00 to 19:00 runs morning, noon and afternoon with golden hour
from 17:00; the horn at 19:00 falls between sunset and dusk, so torches light while the afterglow still burns on the
cloud rims; the waves (from 21:15) come in the deep night, after a blue hour of about 12 s; first light at 05:00 rises
from pre-dawn into a rose dawn with morning mist (fog 0.55).

**Warm pools.** A fire's pool has its own colour only at the core (to 0.3 of its radius), falls off to `ember #D9481F`
by d 0.75 and to `emberDim #8C2A12` at the rim, so firelight on slate reads deep orange to red, as in the target, and
never tan or peach. Inside a pool the fire displaces the cold: the ambient a surface takes falls by 0.7 × saturate(1.5
× the light's peak), so a warm pool stays warm instead of mixing with the blue into pink. The light a surface reflects
is capped at 1.0 (was 1.6). Fire colours a step toward orange: torch `#FF9442`, lantern `#FFA34D`, candle `#FFAD57`,
fire arrow `#FFB35C`; braziers and the hearth `fireOrange`; all × 1.15 against the darker ambient. Windows glow at 1.3
× the old glass strength, their pool small (radius × 1.25) and amber (`#FFA852`, × 0.5), so it sits round the window
instead of tinting the whole wall. Glass on the mid plane (the keep seen from afar) glows at 0.45. Cut-away rooms (the
great hall, the smithy) take their own warm fill: `#B07850` at strength 0.30 (read like a key: colour by its peak ×
0.51), blended by the torch strength from 0.8 × the sky's ambient by day, without the night pull.

**Fog in light.** Inside a light the fog takes the light's hue instead of adding warm to its blue (that made fire in
the periwinkle banks pink-lilac): mix(fog, luma(fog) × light / peak, saturate(1.2 × peak)), plus a glow of light × 0.35
× the plane's share (mist band 0.4, bank 0.6, low mist 0.8). The glow in the mist runs from orange at the core to ember
at its edge; the bank around it stays periwinkle.

**The grade.** Saturation from the key (warm light keeps at least 1.08, except where the fog is denser than 0.3); the
cold grade pushes blue; the darks lift toward navy `#080A18` below luma 0.22 (× the key's black); a highlight shoulder
above 0.82; the vignette from radius 0.42 to 1.25 (× the key's strength, 0.16 by day to 0.34 at night), its horizontal
factor 0.6 (was 0.82), so the left edge, where the creatures enter, stays readable.

## 5. Depth per region

| Region | far (0.2) | mid (0.5) | near (0.75) | world (1.0) | fg (1.3) | Lane |
|---|---|---|---|---|---|---|
| **The shadow land** (x 0 to 1240) | the far mountains; a low fir ridge at the horizon | the forest's edge, two rows of firs at the foot of the sky, in mist; the warden statue and the keep on its shoulder rise above it (stage 2: ruins of older lines, weathered statues of past lords, the dead moor) | single irregular firs (72 to 132 px, broken tops, gaps) and dead trees in loose groups; the tallest away from the defence lines; the fir by the cleft's mouth stays low (from the castle front it would poke over the cliff) | the lines, braziers, creatures | ferns, dead grass, fallen branches, roots; a few fronds rise up to 18 px over the lane line, sparse at the lines | the moor track: a worn pale path with two ruts, a mossy verge, a bank in `fir0`/`moorDark` |
| **The cleft and the castle** (1240 to 2430) | the Weltmauer filling the sky behind the castle (stage 2) | the cliffs of the cleft (granite), the keep's crown | none: the castle is the hero | the castle front, courtyard, hall (a warm room) | none in the gate view (no ferns in front of the castle front); a little rubble by the courtyard at most | cobbles, mostly `stoneMid`, a bank in granite and soil |
| **The valley and the town** (2430 to 3680) | the inner ranges, snow on top | the hills, a tree belt with hedges along the valley floor, the windmill, the keep seen from the town; dark firs on the slopes (stage 2) | linden, poplar pairs, orchard rows of mixed kinds and sizes (34 and 68 px apart, never one rhythm), in a loose row behind the houses | houses, market, tavern, well, bushes behind the people | bushes, grass clumps (a few up to 14 px over the lane line), a few flowers, with gaps in front of the square | the earth lane: packed earth, ruts, a grass verge, a bank in `leafDeep` (a cobbled square is stage 2 art) |
| **The river end** (3680 to 3900) | the inner ranges | the far shore | two willows on the near bank | the bank (a lane-end bank over the river end's soil block), the bridge stumps | reeds and cattails, at most 16 px over the lane line, with gaps at the stumps | the lane rounds off into the bank |

Stage 2 changed the far and mid columns of this table (the Weltmauer, the gorge on the monster side, the cleft's
inner face, the valley's painted distance): the pieces and their places are in 13.2 to 13.4.

Rows: in each region the far, mid and near rows never line up (different spacing per row), each farther row has one
value step less contrast and one step more haze, and no row repeats at a fixed rhythm on screen. The sky carries a
high cloud deck over the old bands (three more bands at sky y 152 to 160): at night their tops catch the moon, at dusk
the low sun.

## 6. Rules for the art

- **Detail density by plane.** Far: big shapes, 2 or 3 values, no outline. Mid: 3 or 4 values, clusters of 3 px and
  more, no outline. Near: 4 values, a lit edge on the upper left (the moon key catches albedo above luma 0.26), a
  readable, irregular silhouette (uneven tiers of a fir, broken tops, gaps; the crown's lobes), no outline. World: the
  full ramp, interior detail, a 1 px dark outline only on the shadow side and the ground contact (selective, never
  black: `ink`, `nightBlue` or the ramp's darkest). Foreground: 2 or 3 values, silhouette only.
- **Light direction.** From the upper left in every painting; the engine adds warm light, cast shadows, the sky on
  silhouette tops (the ledge light) and the moon on lit albedo.
- **Albedo only.** No night colours painted into ground, plants or rock (the night blues belong to the Gloom and the
  creatures); each region has its own darks: `fir0`/`moorDark` in the shadow land, `rockDeep`/`soilDark` at the
  castle, `leafDeep` in the valley.
- **Dithering.** No dithered gradients inside sprites and no Bayer texture: the engine's smooth light does the
  gradients, and the fog banks are flat levels. Dither only in the sky's 16 bands. Never a checker over a large flat
  area.
- **Texture.** Clusters of at least 2 px (3 px on far and mid planes); no lone pixels (`pixelart.py post --clusters`,
  `depthart.declump`; the lane stand-ins now 0.1 to 0.2 %, were 7.6 to 18.4 %); stone in courses, foliage in clumps
  with their own lit side, granite in strata, fog in scalloped levels.
- **Animation (engine, after the port).** Trees on the near plane sway ±1 px at the crown's top, 3 to 4 s period, a
  phase per tree; foreground grass and ferns in 2 frames; the fog banks drift (fogM 3, fogA 5, fogB 8 px/s); sparks
  rise from braziers and fire arrows (8 to 14 px, 0.6 s); fireflies in the valley at dusk (8 to 12 emissive `fireGold`
  dots wandering slowly); chimney smoke rises from every lived-in house (three or four soft puffs over 40 px, drifting
  with the wind, fading); embers drift in the battle. Nothing moves on the far plane but clouds.
- **Readable on a phone.** The lord keeps his cool rim (0.6) and his lantern; archers, guards, builders and citizens
  keep a rim of 0.35 (they vanished against stone at dusk); unlit creatures keep the moon rim. Foreground plants stay
  low where the lord walks. Creatures read as dark silhouettes against the bright fog banks; the bank behind the play
  plane exists for this. Light pools keep their visible edge. The UI sits on top: the vignette darkens the corners,
  which carry the clock and the realm strip; keep bright backdrop features out of the top-right corner.

### 6.1 The creatures (stage 3): lost people, extremely creepy, each with character

Louis' words of 09.11.: the shadow monsters must become extremely creepy, with more character. DESIGN.md: lost people
of smoke, gaunt and far too long, hollow eyes, torn clothes, broken lanterns, ember cracks. They were people of this
land (lamplighters, wardens, soldiers, villagers who went into the shadow land), and the Gloom wears them. Each kind
keeps a trace of who it was (a hood, a lantern, a tabard in the house's teal gone grey, a watchman's pole); the traces
are the mystery shown piece by piece, so the player feels before he knows.

**The silhouette (the first read, at 14 to 110 px).**
- Upright kinds 1.8 to 2.5 times taller than wide; small heads, necks too long or none, shoulders hunched, arms past
  the knees, fingers a pixel longer than a person's. The crawlers and the hound are low but wrong in their joints.
- Asymmetry everywhere: one shoulder lower, the head 1 to 2 px off the axis, one arm longer or dragging.
- The outline breaks: rags, a broken lantern, a torn hood, 1 to 2 px smoke wisps trailing from shoulders and head
  against the walk; the feet smear into smoke on the bottom row.
- Never a mask, never a goblin, never horns or rows of teeth (Not a copy; the dread comes from what is still human).

**The face and the eye (the second read).**
- The face is a void: a 2x3 `nightDeep` socket in a `nightBlue` head, holding exactly one `wraithWhite` pixel, with at
  most 1 px of `wraithDim` beside it. Never two symmetric glowing dots (the black-blob-with-eyes look the art review
  rejected), and never warm (the enemy's light must not look like our fire).
- One cold pinpoint must read at 14 px against fog at 0.45 and against stone at 0.10.
- The stare: in animation the eye pixel holds its place a frame longer than the head moves.

**Body, cracks, light.**
- Bodies `nightDeep` and `nightBlue`, rags `nightSlate`, lit folds `nightHaze`. Unlit, the engine draws them at value
  0.2 (on screen 0.06 or less at night: the darkest thing on the play plane); in firelight their torn detail shows.
- Cracks in `emberDim #8C2A12` with only 1 or 2 px of `ember #D9481F` at the hottest points: smouldering, not burning.
  No `fireGold`, `fireOrange` or `fireWhite` on a living creature (those are ours); they flare only in the death burst.
- Their own light is cold: the eye; the weaver's dead lantern spills darkness; the Lightless King's thorn tips in
  `wraithGlow` with his teal rags.
- The moon rim (`(0.62, 0.70, 0.95)` × 0.6) runs down their right side: on a tall figure a thin cold line, the best read
  against dark firs. Judge it in the engine or in the mock (which now draws it).

**Motion and behaviour (frames and engine).**
- A wrong rhythm: hold 2 frames, snap in 1 (stop-start); never the smooth cycle of our people.
- Each kind its own gait and sound of movement (sound effects only): dragging, scraping, a dry whisper, ember crackle.
- They flinch from light: entering a pool, a creature throws an arm over its face for a frame, so light reads as the
  weapon it is (Pillar 3).
- Death: the body falls to ash in 3 frames, the eye lingers a beat as a lone pixel and goes out last.
- No clones: 3 head variants per small kind (hood, bare, wrapped) and a 1 px height jitter.
- Creepy, not gory: no blood, no wounds, no severed parts (a low age rating stays possible).

| Kind | Size | Who it was, what it does |
|---|---|---|
| Sootling | 14 px | a small stooped husk crawling on its knuckles, arms too long, the head hanging low and turning toward the light; scuttles in bursts, then freezes |
| Sootling B | 14 px | a stick-thin figure walking upright and stiff, the head lolling on a broken neck, arms to the ground |
| Shadehound | 20 px | a thing on all fours that was a man: arched spine, human hands for forefeet, the jaw hanging open, the hind legs bending the wrong way |
| Soot crow | 12 px | a crow of loose ash flakes whose wings come apart and re-form; one eye |
| Ash brute | 44 px | a swollen giant in a tattered cloak, a small head sunk between the shoulders, one long arm dragging a broken lamp-post |
| Gloomweaver | 30 px | a robed figure holding up a dead lantern whose empty cage spills its bubble of darkness; it floats, the hem frayed into smoke |
| Ash Giant | 110 px | a colossus of charred stone and timber, the remains of a beacon tower on its back; one cold eye high up |
| Lightless King | 64 px | a tall cowled shape, the face a void; no crown (11.2 rule 7): thorns grow from the cowl's rim |

**The Gloom's bank** (stage 3, with the creatures): navy soot (`nightDeep`, `nightBlue`) in the fog banks' stacked
levels, drifting motes, and cold eye pinpoints inside it, a few of which blink out.

### 6.2 The lord (stage 3)

Until the fix stage (section 14) the `king` sprite was the old king (white beard, tall crown); it is repainted now.
Since the 09.11. evening decision he is the young lamplighter lord, Aldric's cousin. The brief was: repaint `king` (16x30 × 10) and `kingGlow`: a young beardless face, hair in
`woodDark`/`wood`, a 2 px `gold` circlet tilted 1 px (a little too big), a 1 px `fireWhite` glint in `kingGlow`; keep
the hooked lantern pole and the teal cloak. Check at 30 px against fog at 0.45 and stone at 0.10 with his 0.6 rim. He is
the face of every store screenshot.

## 7. Engine values (for the port; Swift stays untouched in this stage)

The renderer keeps its passes; look 2 changes these values and adds the rows marked new.

| Value | Today (`Look`, `AmbientRamp`, `Shaders.metal`) | Look 2 (`mock.py LOOK2`) |
|---|---|---|
| ambient lift | 0.55 | 0.30 (the night world at about a third of its albedo) |
| night tint (colourise) | (1.03, 0.86, 1.66) × 0.6 | (0.72, 0.95, 1.85) × 0.72 (deep blue, not violet) |
| far / mid / near share of ambient | 0.9 / 0.7 / – | 0.85 / 0.72 / 1.05 |
| far haze | 0.34 + haze × 0.62 toward the horizon | 0.40 + haze × 0.55 toward the hour's air (lavender at warm hours, 0.6) |
| far haze clearing (new, fix stage) | – | the far haze × (1 − 0.5 × (1 − smoothstep(0, 64, screen row from the top))): half the haze at the top row, all of it from row 64 down (`farClear`, `farClearH`; 14.3) |
| far key (new, fix stage) | – | before the haze, far albedo with luma from 0.55 (full at 0.75) adds albedo × 0.5 × (moon (0.55, 0.60, 0.92) × moon height × night + the hour's cloud colour) (`farKey`, `farKeyLo`; 14.3) |
| mid haze | day 0.2, night 0.36, + haze × 0.26 | day 0.14, night 0.36, + haze × 0.25, toward air × 0.86 |
| near haze (new plane) | – | day 0.06, night 0.20, + haze × 0.06, toward air × 0.62; point light share 0.5 |
| moon key (new) | – | at night, near and mid albedo above luma 0.26 (smoothstep over 0.12) adds albedo × moon (0.55, 0.60, 0.92) × 0.30 × moon height |
| ledge light (new) | – | a silhouette's top pixel on the world, near and mid planes (its plane empty above; the next row at half) takes ambient × 1.4 + sky bottom × 0.15; not on figures; one more texel read |
| fog | the 24-row strip on two planes | three painted banks: `fogBank` 384x40 behind the world (0.9), `mistBand` 448x60 between mid and near (0.62), `fogLow` 320x24 over the lane (1.15); flat alpha levels, seamless, never flipped; density fog × 0.9 × 1.2, × 1.0, × 0.6 × 1.2, times the region share per column |
| fog brightness | fog × min(2.4, 0.45 / luma) | fog × min(2.6, 0.65 / luma); the mist band × 1.8 |
| fog in light | fog + light × glow | the fog takes the light's hue (see section 4), glow 0.35 × the plane's share; no warm saturation keep where fog alpha > 0.3 |
| fire pool colour (new) | one colour | the light's colour to d 0.3, ember `#D9481F` by d 0.75, emberDim `#8C2A12` at the rim (smoothstep); not for windows |
| fire displaces cold (new) | – | the ambient of a world pixel or a figure falls by 0.7 × saturate(1.5 × light peak) (near plane: × its 0.5 light share) |
| cap on reflected light (`kLitCap`) | 1.6 | 1.0 (neutral 0.35, cool 0.6 unchanged) |
| bloom of point light | 0.16 | 0.10 |
| bounce (sky light on shadowed albedo by day) | 0.5 | 0.3 (dusk factor 2.2 unchanged) |
| foreground ambient | day 0.9, night 0.43 | day 0.55, night 0.45; light share 0.55 |
| lane sky light (new) | – | the lane's top 8 rows take ambient × 1.0 (day) to 1.2 (night); at night the top 7 add albedo × moon × 0.18 × moon height (the moonlit track) |
| window light | radius 8, × 0.4, `#FFB861` | radius × 1.25, × 0.5, colour `#FFA852`; glass × 1.3; mid-plane glass × 0.45 |
| fire lights | × 1; torch and lantern `fireGold`, fire arrow `fireWhite` | × 1.15; torch `#FF9442`, lantern `#FFA34D`, candle `#FFAD57`, fire arrow `#FFB35C`; braziers and hearth `fireOrange` |
| cut-away rooms (new) | the sky's ambient | a room's rect (the hall: sprite x 24 to 236, rows 0 to 77; the smithy: x 10 to 34, rows 0 to 31) takes `#B07850` at strength 0.30 (× 0.51 after the lift) blended by the torch strength from 0.8 × the sky's ambient, without the night pull; a uniform list of rects per frame, or a per-sprite rect in the atlas |
| clouds | sun 1.1, fill 1.7, haze 0.25 | tops lit by each key's cloud colour (the low sun: sunset `#FF8C4B` × 1.4, dusk `#D97059`), fill 1.5, haze 0.3, moonlight 0.7 at night |
| grade | warmth tint adds red when cold | the cold tint pushes blue (1 + 0.20 w, 1 + 0.05 w, 1 − 0.15 w); navy lift `#080A18` below luma 0.22; vignette per key 0.16 to 0.34, horizontal factor 0.6 (was 0.82) |
| rims | the lord 0.5; unlit creatures `kMoonRim` (0.55, 0.60, 0.82) × `EntityFrames.unlitRim` 0.9 | the lord 0.6; unlit creatures (0.62, 0.70, 0.95) × 0.6; archers, guardsmen, builders and citizens 0.35 in the lord's tone (add them to `Renderer.rimmed`) |
| castle-foot mist bank | × 1 | × 0.35 (the fog banks carry the mist; at full strength it lit the lane lavender) |
| bright haze band | 0.45 | 0.2 (the mist band does its work) |
| ramp | 8 keys | the 10 keys of section 4, with air, vignette, black and cloud colour |

Unchanged: light gain 3.0, hot knee 0.95, bloom (0.75, threshold 0.34), smooth pools with their edge band, the unlit
creature value 0.2 (the mock now draws it as the engine).

New in the port: the near plane (an atlas plane between mid and world, lit like the mid plane plus a point-light
share), the three painted fog banks, the per-hour air and cloud colour, vignette and navy lift in the ramp, the lane's
sky light and moon track, the region share of the fog, the fire colour falloff in the light pass, the cold
displacement, the fog's hue in light, the moon key, the ledge light, the room rects, the people's rims, and from the
fix stage the far plane's haze clearing and key. The glass test
(`lh_is_glass`) keeps `night0`, `night1`, `ink`.

## 8. The mocks (stage 1)

- `tools/depthart.py <dir>` paints the depth stand-ins from the palette: four irregular firs (broken tops, a dead
  spike, uneven tiers, gaps, a lean), a dead tree, fir belts, linden, poplars, three orchard kinds, willow, bushes,
  tree belt, fern, meadow and reed strips, lane tiles, the lane-end bank, puff smoke, sparks, fireflies, and the three
  fog banks. Not game art: stage 2 replaces them. No lone pixels (`declump`), no dither.
- `tools/scenemock/layout_look2.py` places them, lists what look 2 drops from `layout_m1b.py` (the far gorge wall and
  the rock lips: the shadow land is open; the valley's foreground rocks), the high cloud deck and the room rects
  (`INTERIORS`).
- `tools/scenemock/scene_look2.py` holds the six direction scenes; `run_look2.sh` renders each in the old look (the
  committed art of `f35272a` with the renderer's values of today) and the new look (`look=2`), one at a time with the
  heat rule, into `build/recraft/lh/preview/look2/`, plus the two 2x3 contact sheets; `LOOKS=new run_look2.sh` renders
  the new look only (the old frames do not change).
- The scenes: the front at night with the battle (focus 900, 22:48, as the runner's shots 31 and 32), the castle front
  at dusk (1360, 19:12), the courtyard and great hall at dusk (1700, 19:12), the town square at dusk (3040, 19:12), the
  town at noon (2800), the river end at golden hour (3720, 17:53). A render takes about 2.5 s (python 3.13); the six
  new frames and both sheets about a minute, the CPU at most 69 °C.
- `mock.py look=1` (the default) still renders every old mock byte for byte (checked on the front and the castle
  frames after the critic's changes); `art=`, `depth=` and `lut=` (preview a palette change on the old art) stay.

**What the mocks show (after the critic).** The night battle sits on the colour target's values: deep blue (mean 0.21,
9 % below 0.08), a moonlit cloud deck, fir rows paling into billowing periwinkle banks, the statue and the keep as
silhouettes, every creature a dark shape against the bank's bright core; the fires and the lit tower are the only warm
values, deep orange on stone, an orange glow in the mist; the moonlit lane under the feet and ferns standing dark
against it. The castle at dusk: cool slate between dark granite under an afterglow with orange cloud rims, its torches
and braziers lighting the stone deep orange. The courtyard and hall: blue dusk outside, the great hall warm as a room
should be, its teal and red banners apart from the wall. The town at dusk: cool walls with small amber window pools,
lanterns, trees in rows, smoke, fireflies, orange cloud rims. Noon: muted but colourful (dark greens, rows of trees, a
blue-grey sky), a value step under the old look. Golden hour at the river: warm with lavender distance, the trees olive.

## 9. What stage 2 must do (the world art)

Every piece painted from Recraft concepts in this bible's palette (`--match new`), finished by hand, albedo only, in
each region's own darks, clusters of 2 to 3 px, no lone pixels, no dither; judged against the target pictures and by
re-rendering the six direction scenes (`LOOKS=new run_look2.sh`) after each piece.

1. **The Weltmauer.** The wall of peaks "like a line of Mount Everests" above the clouds behind the castle: a far piece
   that fills the sky's upper half at the cleft, snow-capped granite (`rock…`, `farPale`, `foam`), its foot dissolving
   into the mist band; the single cleft as a notch with the castle wedged in; seen from the shadow land (the outer face)
   and from the valley (the inner face).
2. **The cliffs at the cleft.** Repaint the throat rock, the flanks and the high wall in granite with vertical faces and
   ledges whose tops are lit (`rockLight`, `rockPale`, so the ledge light has an edge to catch) and a few firs on the
   ledges; at dusk they must reach luma 0.10 to 0.16 (now 0.096 to 0.098); behind the courtyard no more strata that
   read as a giant brick wall.
3. **The shadow land** (x 0 to 1240, open, no gorge walls). Far: the forest horizon and the Weltmauer's foot. Mid: two
   rows of firs in mist instead of the procedural belts; ruins of older defence lines; weathered statues of past lords
   instead of the warden's niche in a rock pillar; the dead moor. Near: three or more irregular firs and dead trees
   (broken tops, uneven tiers, gaps, wind; the lit upper left of each tier in `fir3`/`fir4`). It must read at a glance
   as the place the monsters come from.
4. **The valley.** Hills with dark firs on the slopes, a hazier painted distance, fewer bright field patches, the tree
   belt and the windmill; the keep seen from the town with one lit pane and a glimmer (two full panes read as eyes).
5. **The depth set** that replaces the stand-ins: near trees (linden, poplar, orchard, willow) in three variants each,
   irregular and wind-bent; bushes; foreground strips per region (ferns, dead grass and roots with a few fronds up to
   18 px over the lane line; the valley's meadow up to 14 px; reeds at most 16 px with gaps at the bridge stumps); lane
   tiles in three or more variants per region (the moor's pale worn path, the castle's cobbles, the earth lane, a
   cobbled market square) and the lane-end bank at the river.
6. **The fog banks** as engine sprites: `fogBank`, `mistBand` and `fogLow`, two or three variants each, stacked
   scalloped levels, no dither, the dense core where the creatures' bodies stand.
7. **The sky.** The high cloud deck (moonlit tops at night, sun-lit rims at dusk), a moon, few stars.
8. **The town.** The plaster as the palette now has it; lit interiors at night for the houses; cobbles and props on the
   square (cart, barrels, a notice board).
9. **The values to hit** (night unless said): frame mean 0.20 to 0.23 with at most 10 % below 0.08; sky with clouds 0.22
   to 0.31; far 0.22 to 0.27; fog cores 0.45 to 0.60; near fir bodies 0.07 to 0.10 with lit tiers 0.18 to 0.22; lane
   0.13 to 0.22; foreground 0.05 to 0.07; stone in firelight hue 5 to 20; cliffs at dusk 0.10 to 0.16; noon greens
   `#3E5A3A` to `#6E8A55`; golden foliage hue 50 or more.

**Stage 3** paints the creatures (section 6.1), the lord (6.2) and the Gloom's bank. **The port** (after the M3 merge)
carries section 7 into `Look`, `AmbientRamp`, `Shaders.metal` and `Renderer` and adds the new planes and sprites.

**Still open after stage 1** (what stage 2 closed and what stays open: 13.6).
- The dusk sky's middle band between navy and the orange afterglow is a dusky mauve (the gradient's two stops mix
  there); a third stop per key (`skyMid`) would turn it blue-grey. Left to the port (one more ramp colour).
- At dusk the town's plaster away from the windows is cool blue-grey and the edge of a window pool reads rose where its
  weak warm light meets the blue; stage 2's lit interiors and the room rects may carry more warmth into the facades.
- The castle at dusk keeps 28 % of its pixels below 0.08 (the dark granite frame); stage 2's lit ledges lift it.
- The night sky's top rows stay at 0.18 (the target's 0.29 comes from a bright cloud cover); the clock and the realm
  strip sit there, so the deck stays darker at the very top.
- Depth stand-ins and the old far and mid art are placeholders; every value above was set on them and should be checked
  again on stage 2's art.

## 10. Critic and fixes (09.11.2026, late evening)

A critic judged the first direction mocks against the target pictures and the measurements of each frame. Every finding
was checked against the frames and the targets (by eye and by measurement: luma, hue and saturation of the same regions
before and after); what held was applied, and the bible above carries the result. Measured on the six direction scenes
(game pixels; before = commit `311831c`, after = this revision).

| # | Finding | Verdict | What changed | Before → after |
|---|---|---|---|---|
| 1 | high: the night a full value step darker than the target; the cleft a flat void at dusk | holds | night, blue hour, dusk and pre-dawn keys lighter in sky, air and fog; stars 0.7 → 0.3 under a high cloud deck with moonlit tops (moonlight 0.35 → 0.7); fog brightness goal 0.45 → 0.65, cap 2.0 → 2.6, mist band × 1.8; painted banks; `rockDeep`, `rockDark` a step lighter; the ledge light. The fog density numbers differ from the critic's (`fogScale` 1.2 stays, but on painted banks with their own alpha) | night mean 0.158 → 0.207; below 0.08: 20 → 9 %; sky top rows 0.09 → 0.18; far mountains 0.16 → 0.21; fog cores → 0.50 to 0.54; castle at dusk below 0.08: 37 → 28 %; cliffs (median) 0.079 → 0.097 |
| 2 | high: firelight on stone tan or peach, the lane under the gate lavender | holds | cap 1.6 → 1.0, bloom of light 0.16 → 0.10, the fire pool's colour falloff to ember and emberDim, torch `#FFA84C` → `#FF9442` (a step toward the critic's `#FF8A3C`), lane sky light 1.4 → 1.2 at night and 1.0 by day, the cobble track mostly `stoneMid`; added: the fire displaces the cold (without it warm light on slate under blue ambient read salmon-pink) and the castle-foot mist bank × 0.35 (it was the lavender band) | night tower `#734D3C` (hue 19, sat 0.48) → `#59311F` (hue 18, sat 0.65, luma 0.19 to 0.23); torch pool on the gate wall at dusk → `#5F412F` (hue 22, sat 0.51); the lane at the gate 0.47 → 0.19 |
| 3 | high: fire in fog pink-lilac | holds | inside light the fog takes the light's hue; no warm saturation keep where fog alpha > 0.3; fog glow 0.7 → 0.35 (the recoloured glow was too big and bright at 0.7) | the glow by the brazier `#B898A7` (hue 330) → `#8B665C` (hue 12) |
| 4 | high: the near plane flat one-value cut-outs | holds | near haze at night 0.36 → 0.20, air × 0.78 → 0.62, share 0.85 → 1.05, haze share 0.12 → 0.06; the moon key on lit near and mid albedo; the firs repainted with uneven tiers and a stronger lit side | near firs 0.099 to 0.123 flat → bodies 0.08 to 0.09 with lit tiers to 0.22; at dusk the linden 0.21 against the hills behind 0.38 |
| 5 | medium: the creatures not yet creepy, enemy light the hue of ours | holds (and it is Louis' own wish) | section 6.1: bodies in night blues, smouldering `emberDim` cracks with 1 or 2 px of ember, one cold `wraithWhite` eye in a socket, never two dots, tall gaunt asymmetric silhouettes, rags and broken lanterns, a stop-start gait, a stare, a flinch from light, an eye that goes out last, a trace of who each one was; the mock draws the moon rim on unlit creatures (0.6: at 0.9 with the brighter tone the sootlings' jagged crests read as rows of white teeth) | stage 3 |
| 6 | medium: the bottom 10 to 13 % dead | holds | the lane and foreground painted in region darks (`fir0`, `rockDeep`/`soilDark`, new `leafDeep`), no night blues, no dithered gradients, no lone pixels; foreground ambient at night 0.30 → 0.45; the moonlit track (0.18); the moor track a pale worn path; fronds up to 18 px (valley 14) over the lane line; no ferns in front of the castle | night lane (median) 0.083 → 0.130; foreground 0.040 → 0.051; lone pixels in the lane tiles 7.6 to 18.4 % → 0.1 to 0.2 % |
| 7 | medium: the fog a flat stripe with grain | holds | `d2FogBank`, `d2MistBand`, `d2FogLow` painted at their own heights: five flat alpha levels stacked like a pixel-art cloud, billowing scalloped tops on a slow wave, thin places, a dense core at the foot; seamless, density by region per column | streaks gone; the bank's core behind the creatures 0.50 to 0.54 |
| 8 | medium: dusk loses the cozy half | holds in part | plaster `#C2B294` → `#C8AE84`, `plasterDim` → `#A0875F`; window pool × 0.7 → × 0.5, radius × 1.6 → × 1.25, colour amber `#FFA852`; cloud tops in each key's low-sun colour; dusk sky bottom `#B0644E`, dusk ambient `#708FD1` (less red) and, added, the sunset ambient less red too (their blend at 19:12 was the mauve); rooms take `#B07850` at 0.30. Not taken: warm plaster at dusk everywhere (hue 25 to 40): away from the windows the walls stay cool blue-grey at 19:12, the cozy-against-cold contrast of rule 6 that makes the windows glow | hall wall `#312E41` (hue 250) → `#2B1F1D` (hue 4), teal and red banners apart from it by hue; cloud rims `#75525B` → `#C6745F`; plaster `#544751` (hue 310, the critic's sample) → `#50506E` (hue 240) away from the windows |
| 9 | medium: greens grey by day, khaki at golden hour | holds in part | noon saturation 0.90 → 0.96 (not 1.0: Louis found the old look too bright and cheerful, and at 0.96 the greens already sit on the bible's noon target), day bounce 0.5 → 0.3, mid haze by day 0.20 → 0.14, golden ambient `#FFB870` → `#FFD1A3` (a step past the critic's `#FFC994`), warmth 0.45 → 0.32. Not taken: foliage hue 75 or more at golden hour (the lit tops of trees in low sun are olive-gold by nature; khaki is gone) | noon greens lit `#758B51`, mid `#617050`, shade `#344B35`; golden foliage hue 41 to 46 → 50 (lit) to 73 (shade) |
| 10 | medium: people without their own light vanish at dusk and night; the vignette darkens the creatures' side | holds | the mock draws rims for archers, guards, builders and citizens (0.35) and the moon rim for unlit creatures; `kMoonRim` → (0.62, 0.70, 0.95); vignette horizontal factor 0.82 → 0.6, night strength 0.42 → 0.34; the engine changes go to section 7 (no Swift in stage 1) | the guard by the gate reads with a cool edge (0.159 → 0.173) |
| 11 | medium: the lord is still the old king | holds | section 6.2: repaint `king` and `kingGlow` in stage 3 | stage 3 |
| 12 | low: the stand-ins look generated by code | holds | irregular firs (four variants), orchard rows of three kinds and sizes 34 and 68 px apart, smoke as soft puffs drifting with the wind, reeds at most 16 px over the lane line with gaps at the stumps, a lane-end bank over the river's soil block, the fir by the cleft's mouth swapped for a low one (no cone in the castle's dusk sky), stars 0.3 under the cloud deck | as listed |

Also fixed on the way: this bible counted eleven keyframes where the ramp has ten.

## 11. Stage 3: the creatures (09.11.2026)

All eight creatures and their glow strips are repainted as lost people, at SPRITES.md's ids, sizes and frame counts.
No Swift changed; no Recraft image was used (251 credits before and after): at 14 to 110 px a converted painting
loses exactly what makes these figures (thin limbs, eyes, a lantern), so every creature is drawn by a small painter.

### 11.1 How they are made

- `tools/rig.py` is the painter: a frame is a grid of palette names plus a glow grid; shaded capsules for limbs
  (`seg`), ellipses and polygons with cloth folds (`ell`, `poly`), two-bone limbs (`ik`, `leg`), hand-set stamps for
  heads, hands and lanterns, `tatter` for torn hems, `crack` for ember cracks, `grid` for a whole hand-set frame,
  and `finish`, which draws the 1 px `nightDeep` outline and the rim on the top contour. Light falls from the upper
  left, as on every sprite.
- `tools/creatures/<id>.py` holds one creature: its size and a `frame(k)` with a pose table. The four small ones are
  hand-set frames, one character a pixel; the four big ones are rigs.
- `tools/creatureart.py build <id>|all` writes the strip and the glow strip; `tools/build-art-actors.sh` calls it, so
  `tools/build-art.sh` rebuilds them (a full run changed only these PNGs). The old creature grids in
  `tools/grids/actors/` are look 1's sources and are no longer built.
- `tools/creaturesheet.py <out.png> [--ids …] [--scale 4] [--bands day,fog,dark]` draws every frame as the engine
  does: by day the albedo with the glow strip over it; unlit at value 0.2 with the moon rim on the screen-right edge
  and the glow strip, once against the blue fog and once against the dark.
- `tools/scenemock/run_creatures.sh` renders battle-night, battle-day, finale, giant (scene_actors.py) and front-night
  (scene_look2.py) in look 2 with the old and the new creatures. For this, `mock.py look=2` now draws an unlit
  creature as the engine does (value 0.2 instead of the mock's 0.12, plus the moon rim); look 1 is untouched.

### 11.2 Rules (and what changed against section 6 and the fix stage)

1. **Smoke flesh stays navy-black in any light.** The body ramp is `nightDeep, night0, nightBlue, nightSlate`
   (HUSK). Light does not turn a creature grey: it reveals what is left of the person, in other ramps: rags
   (`soilDark, moorDark, moor`), an ashen face and hands (`stoneDark, stoneMid, stone`), iron
   (`ink, stoneDark, stoneMid`), a mantle (`night0, night1, night2`). So by day and in torchlight you see a shirt, a
   face, a lantern; unlit you see a shape with eyes.
2. **One hollow cold eye that weeps** (changed in the fix stage, section 14; it is rule 6.1 again). One `wraithWhite`
   pixel, low and off the head's axis in a 2x3 `nightDeep` socket, and at most one `wraithDim` pixel under it. Never
   two: two close pale points on a round head read as the black-blob-with-eyes stock creature, and a pale face disc
   as a mask. The head is HUSK; light shows a torn hood edge and a dropped jaw, never a pale oval.
3. **Glow hierarchy.** The common folk carry `emberDim` on the top contour and `ember` only inside cracks. The
   gloomweaver's sign is violet (its dead lantern leaks it). The Lightless King is cold only (`wraithDim`,
   `wraithGlow`), has no eyes, and carries no ember: he is the one thing in the Gloom without any warmth. This
   replaces the fix stage's fireOrange spikes, fireGold eyes and the King's teal. Palette names and values are
   unchanged; nothing was added.
4. **No loose pixels.** The engine's moon rim lights every screen-right edge pixel of an unlit body, so a loose smoke
   pixel becomes a bright speck. Smoke and wear are torn, connected cloth edges; drifting soot is the engine's
   particle job.
5. **Planted contacts.** A foot, fist or pole on the ground moves back exactly `walkStride` px a walk frame and is
   then lifted and swung in one frame (three frames planted, one in the air; the other limb two frames later). The
   strides are the engine's: sootling 3, shadehound 6, ashBrute 4, ashGiant 4, lightlessKing 5.
6. **Attacks have an anticipation frame** that changes the silhouette (the claw above the head, the fist behind the
   hump, the knee at the belly, the pole over the crown), then the strike, then a held frame for the big three.
7. **Quiet hints only.** A watchman's pole and dead lantern, a shirt rag, a torn hood, a cage of ribs. No creature
   is a child or has a child's features (Louis, 09.11. 22:45). Nothing names who they were. The Lightless King
   wears no crown at all: a dead briar of thorns grows out of his cowl's rim, swept back (fix stage, section 14: a
   thorn crown on a hood over a void is another work's king), and he carries a candle snuffer on a pole instead of
   a sword: he puts lights out.

### 11.3 The eight

| id | who it was | silhouette and gait |
|---|---|---|
| `sootling` | someone small and stooped (not a child) | on all fours, low and long, a hump of a back, a hooded head hanging at the front; drags itself hand over hand; rears up to claw |
| `sootlingB` | someone thin and stooped (not a child) | upright, stooped, stick-thin, a hump behind the hooded head, one arm far too long and dragged; whips the arm forward |
| `shadehound` | a man | on hands and feet, elbows and knees too high, arched spine, a hump behind the shoulders, the head low on a long neck, the jaw hanging, hands for forefeet; bounds with all four off the ground in frame 2 |
| `sootCrow` | cloak scraps | a rag tail, a dark hooded head, one eye, a grey beak; perched it is a small hunched hood |
| `ashBrute` | a night watchman | a hump under a patched cloak, a small hooded head sunk in the shoulders, one trunk of an arm on its fist, his pole across the hump with the dead lantern swinging over his head |
| `gloomweaver` | a lantern bearer | a narrow robe bent forward, no feet, torn strips trailing, a limp hood, one weeping eye, thin arms holding out a dead lantern that drips violet |
| `ashGiant` | no one knows | bent double under a sail of a torn cloak, stilt legs, hands on the ground, a hooded skull lower than the shoulders, an ember heart in a cage of ribs |
| `lightlessKing` | (the mystery; not told) | the frame's full 64 px: mantle, train, shoulder cape, a cowl with a void ringed by a cold crescent, a swept-back briar of thorns from the cowl's rim, two dead lanterns at the belt, a snuffer pole taller than himself |

Frame use, exact poses and the eye and lantern positions are in ART-actors.md ("Sprites", "Glow strip rules", "Eye
and lantern positions").

### 11.4 Port notes (for the engine lane; nothing here is done in Swift)

- **Nothing must change for the sprites to load**: ids, sizes, frame counts, facing (right), anchors (bottom centre)
  and the frame meaning (walk 0-3, attack 4-5 or 4-6, crow fly 0-2 and perch 3, weaver float 0-3) are as before.
- **Strides** stay 3, 6, 4, 4, 5: the planted contacts are drawn for them. If a stride changes, the feet slide.
- **Glow strips** now hold cold pixels too. They must be added as they are (no warm tint, no torch strength). If
  the engine dims glow strips by day, keep the eyes: by day a creature's eyes are its face.
- **`unlitValue` 0.2 and the moon rim** suit the new bodies; the sheets and mocks are drawn with them. A lower value
  would lose the big silhouettes against the night; a rim on loose pixels is no longer an issue.
- **Body shade by id** (the non-boss tint): keep it small (0.9 to 1.0). The bodies are already near the palette's
  darkest values and the rags are what light shows.
- **Gloomweaver**: the engine's bob (`2 + sin`) moves the whole figure; the sprite itself only waves its strips and
  swings the lantern 1 px, so both together read as drifting. Its violet light should sit at the lantern core
  (9 px right of the anchor, 9 px up), not at the head.
- **Lightless King**: the sprite fills all 64 px in height (the thorns reach the top row). Anything placed over his
  head (health bar, aura centre) needs 2 px more. His aura centre fits the cowl: 4 px left of the anchor, 52 px up.
- **Ash Giant**: the stomp lands in frame 5 (the foot 12 px ahead of the walk contact, the body 5 px down): the
  screen shake and the damage belong on frame 5. The heart (5 px right of the anchor, 68 px up, radius 7) is the
  place for a light of ember colour, radius about 20 px, brightest on frame 5; today it has none.
- **Ash Brute**: the slam lands in frame 5 (fist at 17 px right of the anchor on the ground).
- **Sootling and hound attacks** land on frame 5.
- **Particles** (not drawn in the sprites): a little soot rising from brute, giant and King would complete "smoke
  figures"; one dark pixel a few times a second from the top contour, drifting left.
- **The darkness bank** (11.5) loads without Swift changes; its eyes need one new sprite id.
- **For the lead: SPRITES.md describes look 1's glow strips** (its lines 22 to 27 and 52 to 55; this lane may not
  edit that file). Look 2's strips hold one cold eye a creature, `emberDim` on the top contour, `ember` only inside
  cracks, violet for the gloomweaver and cold only for the Lightless King. Replacement text:
  - lines 22 to 27, the last two sentences: "So the glow strip alone must still read as the creature: a dim ember
    rim (`emberDim`) on the silhouette's top contour, `ember` only inside a few cracks, and one cold eye
    (`wraithWhite`, at most one `wraithDim` tear under it) low in a dark socket; never two eyes (ART-look2.md 11.2,
    ART-actors.md "Glow strip rules"). The body must read in daylight and in firelight. The engine draws the cold
    pixels as they are: no warm tint, no torch strength, and not dimmed by day."
  - lines 52 to 55, after the list of ids: "A dim ember rim and ember cracks in the fire ramp, one cold eye each
    (`wraithWhite`, `wraithDim`); the gloomweaver's eye and lantern drip are cold violet; the Lightless King has no
    eye and no ember, only `wraithDim` and `wraithGlow` (the crescent in his cowl, the thorns' tips). No palette
    entry was added; `build-art.sh` rebuilds every strip byte for byte."

### 11.5 The Gloom's darkness bank

`tools/bankart.py` (in `build-art-actors.sh` as `darknessBank`) writes three PNGs into Resources/Art:

- `darknessBank.png` 64x236: opaque navy soot (`nightDeep, night0, nightBlue, nightSlate`) in slow billows that lean
  toward the castle, repeating every 64 px, the top 36 rows thinning in an ordered dither, as the placeholder does.
- `darknessEdge.png` 32x236: the same soot thinning to the right with reaching fingers; its left column is solid
  below row 36, so it joins the body.
- `darknessBankGlow.png` 4 frames of 64x236: seven pairs of cold eyes at 5 to 104 px above the lane (the low ones
  `wraithGlow` with a tear, the high ones `wraithDim`), each shut in one frame, and ten motes of cold ash.

The first two have the sizes of `SpriteID.darknessBank` and `darknessEdge`, so the atlas takes them instead of the
procedural soot with no code change (removing the two files brings the old bank back). The glow strip has no sprite
id yet. Port: add `darknessBankGlow` (64x236 × 4) and draw one frame over each body tile as an emissive, the frame
`(tileIndex + Int(time * 1.5)) % 4`, so the eyes blink out of step from tile to tile; with Reduce Motion hold frame
`tileIndex % 4`. `run_creatures.sh bank` shows it in the mock (the night battle 60 px further left).

### 11.6 What the mocks show, and what is open

- At night the creatures are now dark people-shapes with pale eyes against the blue mist, where look 1 showed
  ember-cracked lumps. The giant and the King read from the far side of the screen; the brute reads as a hunched
  man with a lantern over his head.
- In firelight a sootling's head turns pale: the face is the first thing a torch shows. That is intended.
- Open: the small creatures have 14 px, so their rags are two or three pixels; the crow is the weakest read (a dark
  scrap with an eye). The giant's ribs are thin bars over the heart and read as a cage only from 3x. The
  gloomweaver is still more sad than frightening. None of this was seen in the running game: the walk cycles were
  judged as frames on a sheet, not in motion.

## 12. Direction check before stage 2 (09.11.2026, night)

The six look-2 scenes were rendered as stage 1 and the critic left them (`run_look2.sh`, copies in
`build/recraft/lh/look2/world/before/`) and held against the four target pictures. The light, the fog and the fire
are right. What still keeps the frames from a big studio's look is the world behind them.

### 12.1 What is wrong, scene by scene

| Scene | What a player sees | What is missing |
|---|---|---|
| front-night | fog, firelight and creatures work; behind them a statue's head with a fire bowl floats in the sky like a giant face, a ghost keep fills the right half, the firs are flat cones | no Weltmauer, no gorge, no sense of where one stands; the big shapes in the sky are props, not land |
| castle-dusk | the castle is good | the cliffs beside it are two black voids without form (value 0.097), the sky above is empty: no peaks, so the castle stands at a hill, not in a cleft of a world wall |
| court-dusk | the hall glows well | the rock behind the courtyard is giant bricks in strata: masonry, not a mountain |
| square-dusk | plaster, lanterns fine | the far keep is a ghost block as wide as three houses, the hills are flat lavender bands, no trees on any slope |
| town-noon | readable | cheerful: bright green hills with yellow field patches, lollipop trees; nothing of "düster", nothing of the wall the town lives behind |
| river-golden | acceptable | flat: a band of hills, no painted distance, no haze steps |

### 12.2 The seven faults (and the fix each gets in stage 2)

1. **No big shape.** Every target picture hangs on one huge form with a simple outline (the wall, the cleft, the
   fir front). The scenes are assembled from medium props of equal weight. Fix: each region gets one giant form on
   the far plane (the Weltmauer's outer face; its peaks over the castle; its inner face over the valley) and the
   props shrink under it.
2. **Value steps per plane are not held behind the play plane.** Far and mid were both about 0.24 at night, so
   the distance was one grey. Fix: far 0.22–0.27 and smooth, mid dark against it (the gorge 0.09–0.13, the fir front
   0.07–0.10 with lit tiers), fog between them as the light band. The eye reads dark–light–dark–light from front
   to back.
3. **Rock is drawn as bricks.** The old rock paintings stack rounded blocks in level courses. Granite walls break
   along vertical joints. Fix: new rock is painted in tall slabs and chimneys with vertical fractures, few ledges,
   a lit top edge; the stratum look is gone from the cleft, the gorge and the inner face.
4. **Trees are symbols.** Cones and balls of one size in even rows. Fix: painted trees in three or more variants
   per kind, heights from 60 to 130 px, leaning, broken, with gaps; rows never line up between planes.
5. **The far distance has no haze steps.** One flat band. Fix: each backdrop carries two or three ranges in itself,
   each a value step lighter and less saturated, the farthest almost the sky.
6. **Colour is evenly spread.** The targets hold large quiet fields of one cold colour and spend warm colour only
   in fire and windows. Fix: no yellow field patches in the valley, the greens two steps down (fir ramp on the
   slopes, leaf ramp only in the town's own trees), the only warm things on the far planes are window panes.
7. **Composition ignores the story.** The world wall, its single cleft and the castle wedged in it are the game's
   picture and they were not on screen anywhere. Fix: section 13.2 (the gorge and the view back).

### 12.3 Rule changes (the senior eye)

- **Section 5, shadow land.** Was: "open shadow land right up to the cleft". Now, after Louis' words of 21:55
  ("auf der Seite, wo die Monster kommen, nur Felsen … ziemlich düster, und wenn man bisschen rausgeht, sieht man
  halt den Wald und die Landschaft vom Schattenreich"): a gorge of bare rock from the castle out to x 700, its
  mouth from 700 to 520, the open land from 520 to 0. Reason: his words, and the picture is stronger; a palisade
  across a narrow gorge reads as a defence, a palisade in an open field does not.
- **Section 3, mid plane.** The mid plane may now be the darkest plane behind the play plane inside the gorge
  (0.09–0.13 at night instead of 0.16–0.22). Reason: rock walls in shadow with no sky are the "only rock, dark"
  Louis asks for; the fire pools of the middle line then own the frame.
- **Section 9, far and mid as Recraft paintings.** Kept for the Weltmauer, the gorge rock, the forest and the
  valley. The Weltmauer's cleft and the far castle are composed into the painting from the real castle sprites
  (`tools/worldart.py`), not painted, so the far castle is the real one small. Reason: a generator cannot be told
  where a slot sits to the pixel and never repeats a building.
- **The statue and the ghost keep leave the shadow land's mid plane** (`wardenStatue` at mid x 430, `keepFar` at
  mid x 641). The statues of past lords come back at human scale in the forest mid painting; the castle is seen in
  the cleft on the far plane. Reason: 12.1, front-night. (Fix stage, section 14: the warden statue comes back, cut
  into the Throat's wall at mid x 520; the ghost keep stays out.)

### 12.4 What the renderer could add (for the engine port; none of it is art)

| Effect | What it gives | Roughly how |
|---|---|---|
| Light shafts through the cleft | the one warm gesture of dawn and dusk: the low sun falls through the slot into the shadow land (dawn) or the valley (dusk) | two or three additive quads, a soft wedge texture 64x128, anchored at the cleft's top on the far plane, alpha by `sun` low-angle weight, slow 0.05 Hz breathing; off at night |
| Bloom on fire | braziers and the beacon glow into the fog instead of sitting on it | downsample the emissive buffer to quarter size, blur 2 passes, add at 0.35; cap so sprites keep their pixels (bloom only outside the emitter's own mask) |
| Wind in the trees | the forest lives, the firs bend before a wave comes | near-plane and fg sprites drawn in two or three horizontal slices, the upper slices offset by `round(sin(t*0.7 + x*0.02)) ` px (0, 1 or 2 px, whole pixels only); gusts raise the amplitude for 2 s when the Gloom's bank moves |
| Layered drifting fog | depth and dread: the banks move against each other | the three fog planes already exist; give each its own drift (fogM −2 px/s, fogA −5 px/s, fogB −9 px/s, toward the castle at night, still at noon) and a second copy of fogA at half alpha moving the other way |
| Fog that swallows figures | creatures come out of the fog instead of walking in from the edge | alpha of an enemy = clamp((x − bankEdge) / 60) inside the open land, drawn before fogA while under 0.6 |
| Far-castle windows and beacon | the view back tells the state of the house | the glow strips `farCastleGlow` (from the shadow land) and `farCastlePane` (from the town) as emissives on the far plane at night, each over the slot's own faint light (`farCleftGlow`, `farCleftGlowBack`, section 14.3); once the Great Beacon burns, its light in the slot seen from the town, with bloom (13.8, items 5 to 7) |
| Cloud deck drift | the peaks stand above weather | the cloud band over the castle on its own plane (0.12) at 1 px/s, wrapping |
| Ground mist kicked by feet | cheap life in the lane | 4 px puffs of the fog colour at each footfall in the moor, 0.4 s, alpha 0.3 |
| Embers and ash | fire has weight; the Gloom sheds | `d2Sparks` rising from braziers (already in the mock), cold ash motes drifting from the bank's edge |
| Reduce Motion | accessibility | no drift, no wind, no shafts breathing; fades stay |

## 13. Stage 2: the world art (09.11.2026, night)

Louis, 21:55: "Wär deswegen vielleicht krass, wenn man dann auf der Seite, wo die Monster kommen, nur Felsen sieht,
oder? Und es da ziemlich düster ist, und wenn man bisschen rausgeht, sieht man halt den Wald und die Landschaft vom
Schattenreich." That is the picture this stage builds: right outside the castle only rock and dark; further out the
forest and the land of the shadow realm; and from out there, looking back, the Weltmauer across the whole sky with one
slot in it and the castle small in the slot.

What a player now sees, walking from the spawn to the river (plates in `ci-out/look2-fable/world/`):

| Where (camera focus) | What is on screen |
|---|---|
| 0 to 500, the open land | the wall across the whole view above a cloud deck; the slot with the far castle, its windows lit at night; the fir forest with two lantern statues and a ruin; single firs and dead trees; moor track, ferns, fog |
| 500 to 700, the gorge's mouth | the rock rises in crags at the right, dead trees only; creatures come out of the fog toward the palisade and its braziers (`shadow-night`, the hero frame) |
| 700 to 1240, the gorge | only rock, out of sight upward, dark; fog and fire (`front-night`) |
| 1240 to 2430, the cleft and the castle | granite flanks with form beside the towers, the wall's peaks above the castle, the inner face behind courtyard and hall |
| 2430 to 3680, the valley | at the left the wall with the back of the castle in the slot and its one lit pane; the wall's shoulder sinks and three ranges of fir slopes in haze open to the right; linden, poplar pairs, apple trees behind the houses |
| 3680 to 3900, the river end | willows, reeds, the vista's far ranges |

### 13.1 Files

All in `Resources/Art/`, palette colours only, rebuilt byte for byte by `tools/build-art.sh world`
(`tools/build-art-world.sh`, the last group of `build-art.sh`: it cuts the cliffs from the old cliff sprites' shapes
and the far castle from `castleFront`, `keepTop` and `castleBackGate`, so it runs after the buildings). The paintings
are converted by `tools/pixelart.py --match new` with one ramp per piece and assembled by `tools/worldart.py`
(no randomness: hashes of the position). The world lane takes about 65 s on this Mac, the whole `build-art.sh` 3:24.

Albedo, with these exceptions (corrected in the fix stage): `d2FogBank`, `d2MistBand`, `d2FogLow` and `d2Smoke` are
`#FFFFFF` alpha masks (the engine gives them their colour, 13.8 item 12); `d2Sparks` and `d2Fireflies` are
emissive dots in the fire ramp; `farCastleGlow`, `farCastlePane`, `farCleftGlow` and `farCleftGlowBack` are glow
strips. The table below carries the fix stage's sizes (section 14).

**The sources are not in git.** The world lane reads the five paintings and their cut parts from
`build/recraft/lh/look2/world/` (git-ignored: `wall-1.png`, `gorge-1.png`, `forest-1.png`, `trees-1.png`,
`valley-1.png`, `parts/`). They exist in three places on this Mac: this lane's worktree
(`.claude/worktrees/lh-look2-fable`), the lead's worktree (`.claude/worktrees/game2-planning-354541`) and the main
checkout (`/Users/enaayla/Desktop/Spiele-Welle`), each under the same path. A later lane in a new worktree must
copy that folder before it runs a full `build-art.sh` or `build-art.sh world`; without it the world group fails
and no world PNG can be rebuilt. No credits are left to paint them again (13.7).

| Id | Size | Plane | From | How |
|---|---|---|---|---|
| `weltmauer` | 888x190 | far | `wall-1` | `worldart.py wall`: the painting (384 px wide) and its mirrored second cut (420 px) side by side and run on by 150 px; the last 212 columns sink by up to 104 px (the wall's shoulder toward the valley); fix stage: the ridge redrawn as seven massifs, the whole wall regraded to granite below a wandering snow line with couloirs (14.3); the cleft cut twice (sprite x 324: the view from the shadow land; x 650: the view from the valley), a sheer slot 40 px wide (as wide as the far castle), filled with four flat pale levels, a pillar at each lip; in each slot the far castle at 1/6 |
| `weltmauerPatch` | 52x190 | far | `weltmauer` | the unbroken wall at sprite x 624 to 676, cut before the second cleft: it hides the valley's view of the cleft until the camera is past the back gate |
| `farCastleGlow` | 40x46 | far, glow | `castleFront` + `keepTop` | the far castle's lights seen from the shadow land: six `fireGold` cells (the keep's pane, two tower slits, the right tower's lower slit, two watch fires on the wall walk), the real sprites' emitters divided by 6 |
| `farCastlePane` | 40x46 | far, glow | `castleBackGate` + `keepTop` | the one lit pane high in the keep seen from the town (one cell: two panes read as eyes) |
| `farCleftGlow`, `farCleftGlowBack` | 44x72, 44x68 | far, glow | `weltmauer` | the slot's light above and beside each far castle as an emissive mask (the slot's pale cells, the castle's cells left out): at night the slot glows faintly so the castle stands as a silhouette (14.3) |
| `gorgeRock` | 448x211 | mid | `gorge-1` | `worldart.py gorge`: the granite face, granite ramp only, a dark body with the slabs' upper and left edges lit and seven straight joints; its left edge broken (the mouth), its right 54 columns step down to the cleft face's height |
| `gorgeCrags` | 160x200 | near | `gorge-1` | `worldart.py gorge`, second output: five dark crags standing before the face's edge, so the mist band lies between the two depths of the mouth |
| `cleftFace` | 448x218 | mid | `gorge-1` | `worldart.py face`: the cleft's inner face behind the castle with a broken, lit top edge |
| `cleftFaceEnd` | 240x218 | mid | `gorge-1` | the face's end, stepping down into the valley |
| `cleftFlank`, `cleftFlankB` | 80x240 | world | `gorge-1` | `worldart.py retex`: the painting's granite inside the alpha of `cliffFlank` / `cliffFlankB` (same size, same place), lit top and left edges, dark right edge |
| `cleftThroat` | 192x240 | world | `gorge-1` | the same in `throatRock`'s shape |
| `shadowForest` | 224x104 | mid | `forest-1` | the forest edge: firs of many heights, two statues of lords with lanterns, a ruined wall, a tower stump, moor; crowns warmed onto the fir ramp; `worldart.py taper`: the left 72 px sink to the ground in fir-shaped teeth so two copies join |
| `valleyVista` | 448x160 | far | `valley-1` | three ranges of fir slopes, each a step paler; `worldart.py slope`: the left end cut to a rising slope (it stands before the wall's shoulder) |
| `firA`, `firB`, `firC`, `firD` | 29x130, 30x118, 34x106, 27x84 | near | `trees-1` | one tree each from the sheet, warmed onto the fir ramp (`--warm 28 --gain 1.25`), the trunk's foot kept dark; `worldart.py main` drops the neighbours' fragments |
| `deadTreeA`, `deadTreeB` | 17x72, 17x70 | near | `trees-1` | bare trees in the rock ramp |
| `linden`, `poplar`, `appleTree`, `willow` | 52x92, 14x116, 42x48, 52x68 | near | `trees-1` | the town's trees in the leaf ramp |
| `d2FgFerns`, `d2FgMeadow`, `d2FgReeds` | 480x64, 480x58, 160x40 | fg | `tools/depthart.py` | stage 1's stand-ins, now game art (they held against the targets; the names stay so the mocks and the port agree) |
| `d2BushA`, `d2BushB` | 30x15, 22x12 | world, z −3 | `depthart.py` | bushes behind the actors |
| `d2TreeBelt`, `d2FirBeltFar` | 520x58, 520x40 | mid, far | `depthart.py` | the tree belt along the valley floor; the low fir ridge at the wall's foot |
| `laneMoorA…D`, `laneCobbleA…D`, `laneEarthA…D` | 64x26 each | world | `depthart.py` | the lane tiles, variant by a hash of the tile index |
| `laneScreeA…D` | 64x26 each | world | `depthart.py` | fix stage, the Throat's ground: bare rock and scree in the granite ramp, two worn cart ruts, loose stones with a lit top on the near edge; no tuft, no moss |
| `d2LaneEnd` | 48x30 | world | `depthart.py` | the grassy bank where the lane ends at the river |
| `d2FogBank`, `d2MistBand`, `d2FogLow` | 384x40, 448x60, 320x24 | fogA, fogM, fogB | `depthart.py` | the three fog banks: `#FFFFFF` with five flat alpha levels, no colour of their own |
| `d2Smoke` | 26x50 | world | `depthart.py` | chimney smoke, a `#FFFFFF` alpha mask |
| `d2Fireflies`, `d2Sparks` | 96x30, 14x24 | world, emissive | `depthart.py` | fireflies (`fireGold`, `fireWhite`), brazier sparks (`fireGold`, `fireOrange`, `ember`) |

No SPRITES.md id, size or frame count changed; the old sprites look 2 no longer draws stay in the folder for look 1.
The port adds the ids above to SPRITES.md when it wires them (none of them is in SPRITES.md yet, the fix stage's
`gorgeCrags`, `laneScreeA…D`, `farCleftGlow` and `farCleftGlowBack` included). `wardenStatue` is look 1's sprite,
unchanged.

### 13.2 The gorge and the view back (the shadow land, x 0 to 1240)

Positions are plane x of the left edge and y of the bottom above the ground line, as in
`tools/scenemock/layout_look2.py` (`WORLD`, `DEPTH`), which the port reads. A plane's x at a screen column is
parallax x camera x + screen x; `at(p, X) = 218.5 + p (X − 218.5)` is the plane x behind world X when the camera is
centred on X.

| Plane | Piece | x | y | z | Notes |
|---|---|---|---|---|---|
| far 0.2 | `weltmauer` | −44 | −17 | −3 | its ridge 135 to 173 px above the ground line: it fills the sky's upper half in every view from 0 to the valley; the slot seen from the shadow land at far x 280, the far castle's foot 75 px above the ground (above the fog) |
| far | `farCastleGlow` | −44 + 324 − 20 = 260 | −17 + 92 = 75 | glow | additive, `fireGold`, strength by the torch curve (off by day) |
| far | `farCleftGlow` | −44 + 324 − 22 = 258 | 75 | glow | additive, the colour `cleft` (0.11, 0.13, 0.19), the same curve; drawn under `farCastleGlow` |
| far | cloud deck | `cloudA` −60 y 96, `cloudB` 322 y 104, `cloudC` 640 y 108 flipped | | 0 | before the wall: the peaks stand above the clouds; none before the two slots (far x 260 to 300 and 586 to 626) |
| far | `d2FirBeltFar` | −120, 400 | 2 | 2 | a low ridge of firs at the wall's foot |
| mid 0.5 | `shadowForest` | −128, and 96 flipped | −4 | 1 | the forest edge behind world 0 to about 420 |
| mid | `gorgeRock` | 345 | −10 | 3 | shade 1.0 (fix stage: the darkness is in the file's granite, not in a shade); seen from the palisade (focus 550 to 650) its broken edge rises behind world 520 to 700 (the mouth); from 700 on the rock leaves the frame at the top: no sky, no wall, no tree |
| mid | `wardenStatue` | 520 | −34 | 4 | fix stage: cut into the Throat's wall, shade 0.88, behind the lord at focus 917; its bowl burns all night: emitter `hearthFire` at sprite (40, 153) in `fireOrange`, a light at mid (568, 124), radius 70 |
| near 0.75 | `gorgeCrags` | 415 | −10 | 1 | shade 1.0; before the face's edge from focus 450 to 700; the mist band (fogM) lies between it and the face |
| fogM 0.62, fogA 0.9, fogB 1.15 | the three banks | as stage 1 | | | fog share 1.0 up to x 1120, then falling to 0.7 at the cleft |
| near 0.75 | `firB` 24, `firD` 62 f, `firC` 118, `firD` 190 f, `firA` 236, `deadTreeA` 300, `deadTreeB` 372 f, `deadTreeA` 436 f | world X of the trunk (`tree("near", name, X)`: plane x = at(0.75, X) − width / 2) | 0 | 0 | fix stage: firs only west of world 247 (a near tree taller than 75 px east of that covers the far castle somewhere between focus 150 and 470); from there to the beacon (470) dead trees only; in the Throat (470 to 1240): none |
| world | the lines; the lane `laneMoor` from −64 to 448, `laneScree` from 448 to 1240 | | | | the Throat's ground is scree with cart ruts |
| fg 1.3 | `d2FgFerns` | −414, 66 | −30 | 2 | ending at the beacon; none in the Throat |

**The Throat** (fix stage) is the stretch from the beacon (world 470) to the castle's front (1240): scree, granite,
fog and fire, and the warden statue in the wall. No tree, no fern, no grass, no moss.

Out of look 2 on the monster side (`dropped()` in `layout_look2.py`): `gorgeWallA/B/C`, `gorgeWallHigh`,
`gorgeMouth`, `keepFar`, `wardenStatue` at its old place (mid x 430; it is set again at 520) and the mid `cliffFlank`
on the mid plane, `farMountain` on the far plane, the `fgOverhang*` rock lips on the fg plane.

Why it works: the wall is the one giant shape (fault 1 of 12.2); the gorge is the darkest plane behind the play plane,
so the fog and the fire pools own the frame; the forest only shows once one walks out, which is the reward Louis
describes. The beacon ruin (438 to 500) covers the slot between focus 400 and 470; that is accepted (the ruin is the
place to light the beacon, the view back opens on both sides of it). From focus 500 on `gorgeCrags` covers it: at
the palisade one sees only rock.

### 13.3 The cleft and the castle (1240 to 2430)

| Plane | Piece | x | y | z | Notes |
|---|---|---|---|---|---|
| far | `weltmauer` | as above | | | its peaks stand between and above the towers; the second slot is covered here |
| far | `weltmauerPatch` | −44 + 650 − 26 = 580 | −17 | −2 | drawn at full alpha up to camera focus 2330, fading out to 2520 |
| far | `farCastlePane` (sprite and glow) | −44 + 650 − 20 = 586 | 75 | −1 | glow in `window`; fades in over the same span, so the lit pane never shines through the patch |
| far | `farCleftGlowBack` | 584 | 75 | glow | the colour `cleft`; an emitter of `farCastlePane` at dx −2, so it fades with it |
| mid | `cleftFace` | 740 | −95 | 2 | shade 0.42; top edge 123 px above the ground line, behind the courtyard and the hall; no strata, no bricks |
| mid | `cleftFaceEnd` | 1188 | −95 | 2 | steps down behind the back gate |
| world | `cleftFlankB` 1110 y −155 (shade 0.7), `cleftThroat` 1518 (0.7), `cleftFlank` 1187 (0.62), `cleftFlankB` 1453 flipped (0.62) | the old instances' places, z and shades (`SWAP` in `layout_look2.py`) | | | granite instead of `cliffFlankB`, `throatRock`, `cliffFlank` |
| world | lane `laneCobble` 1240 to 2430 | | | | |

No near trees and no fg plants here: the castle is the hero.

### 13.4 The valley and the river end (2430 to 3900)

| Plane | Piece | x | y | z | Notes |
|---|---|---|---|---|---|
| far | `weltmauer`'s shoulder | far x 632 to 844 | | | from the town the wall fills the left third of the sky and sinks; the slot with the back of the castle at far x 606 |
| far | `valleyVista` | 620, and 1068 flipped | −34 | 1 | before the wall's end; three ranges, the farthest almost the sky; no yellow fields, no windmill |
| mid | `d2TreeBelt` | 1400, 1920 | −2 | 3 | the valley floor |
| near | `appleTree` 2466, 2548 f, `linden` 2624, `appleTree` 2690 f, 2741, `poplar` 2868, 2884 f, `linden` 2992 f, `poplar` 3170, 3186 f, `linden` 3300, `appleTree` 3448, 3523 f, `linden` 3610 f, `willow` 3684, 3790 f | world X of the trunk | 0 | 0 | never one spacing; poplars in pairs; fix stage: between world 2386 and 2616 only apple trees (a poplar or a linden there covers the far castle between focus 2520 and 2700) |
| world, z −3 | `d2BushA` 2560, `d2BushB` 2884, `d2BushA` 3080 f, `d2BushB` 3190, `d2BushA` 3440 | world X of the middle | 0 | | behind the houses' fronts |
| world | lane `laneEarth` from 2430; `d2LaneEnd` at 3676, y −30, z 3 | | | | |
| fg | `d2FgMeadow` at at(1.3, 2600) − 240 and at(1.3, 3360) − 240, y −26; `d2FgReeds` at at(1.3, 3760) − 80, y −24 | | | | gaps in front of the square and at the bridge stumps |

Out of look 2 in the valley: `valleyFarA/B/C`, `valleyMidA/B/C`, `windmill`, the fg rocks past x 2900. Fog share 0.45.

### 13.5 Rule changes in this stage (the senior eye), each with its reason

- **The far castle is the real castle at 1/8, composed, not painted** (`mini_castle`): three far-ramp values
  (`farDeep`, `mistDark`, `moon`). Reason: the view back must show this house; a generator never repeats a building.
  (Fix stage: at 1/6, a dark silhouette with a lit left edge before a slot of light; 14.3.)
- **The far castle stands 75 px above the ground line.** Lower it sat in the fog and behind the fir ridge. Reason:
  the view back is the point of walking out.
- **The wall is one line of peaks of equal height, no summit** (the predecessor's `weltmauer-1`, a pyramid, is not
  used). Reason: a rampart of the world, not a mountain.
- **The wall ends in a sinking shoulder over the valley instead of running across all valley views.** Reason: the
  valley needs its own picture and depth (the vista); the wall stays as the thing the town lives behind, at the left.
  An open choice for Louis: `WALL_MORE` in `worldart.py` raised to about 400 puts the wall behind the whole town.
- **No tree on any cliff edge.** A tree there gives the cliff a scale, and a small one. This replaces "a few firs on
  the ledges" of section 9.2.
- **The cliffs beside the castle use the granite ramp without the soil darks, `--gamma 0.7`, and the inside of every
  shadowed slab is lifted one step** (`rockDark`; only cracks and slab edges stay `rockDeep`). Reason: section 9.2's
  0.10 to 0.16 at dusk; with the soil darks the flanks were black voids.
- **The gorge's rock may sit at 0.14** (12.3 said 0.09 to 0.13). Reason: at 0.13 and below the slab structure is lost
  and the wall reads as a black field; at 0.14 it reads as rock and is still the darkest plane.
- **Statues at human scale, in the forest painting.** The giant warden head and the ghost keep are gone (12.3).
- **The stand-ins of `depthart.py` are promoted to game art** (plants, lanes, fog, particles) instead of being
  repainted. Reason: they pass the targets in every scene; the five paintings went to the big shapes, where the
  frames failed. Section 9.5's "three variants each" holds for firs (four) and lanes (four); linden, poplar, apple
  tree and willow have one painting each and vary by flip and spacing. More variants are open. (Two more of each
  are painted in section 18.5.)
- **A fading sprite takes its glow along** (`mock.py`, look 2 only; look 1 renders byte for byte): the far pane's
  light fades in with the pane.

### 13.6 What was measured, and the open points of section 9

Luma of the 3x renders (`scene_look2.py`, look 2):

| Scene | Frame | Below 0.08 | Other |
|---|---|---|---|
| front-night (the gorge) | 0.184 (before stage 2: 0.206) | 9 % (10 %) | gorge rock 0.141; fog band 0.268 with cores about 0.37; lane track 0.138 |
| castle-dusk | 0.151 | 17 % (32 % with the first granite, 28 % after stage 1) | flanks 0.149 and 0.135, 8 and 9 % of them below 0.08; lane at the gate 0.184 `#2A2C46` |
| court-dusk | 0.175 | | the face behind the hall 0.193 |
| square-dusk | 0.266 | | lane track 0.154 `#242537`; plaster away from the windows `#4B4451`, 0.283 |

The table is stage 2's. The fix stage changed the gorge and the wall and measured those again: the gorge's face
0.162, its mouth with the crags 0.151 (14.2); the wall's snow and shaded rock at three hours (14.5). The frame means
of the four scenes were not measured again.

- **Cliffs at dusk (9.2, 9.9): closed.** 0.149 and 0.135, inside 0.10 to 0.16.
- **The lane at dusk: closed without a change.** 0.154 to 0.184, inside 0.13 to 0.22, navy, not lavender.
- **The plaster at dusk: measured and left.** It stays cool away from the windows (rule 6 of section 1: warm colour
  only where fire and windows are). The rose edge of a window pool is the light's falloff meeting the blue ambient;
  it is the renderer's to solve (a warmer, shorter falloff), not the albedo's.
- **The gorge's frame mean is 0.184, under section 9.9's 0.20 to 0.23.** Accepted: Louis asks for "ziemlich düster"
  there, and the share below 0.08 holds at 9 %. The open land and the valley keep 9.9's range.

**Still open after stage 2.**
- Section 9.8: lit interiors for the town's houses at night, cobbles and props on the square (cart, barrels, notice
  board). Not painted: no Recraft budget was left and they are buildings, not world.
- `cleftFace`'s top edge runs fairly level behind the hall; a few deeper notches would break it.
- The mirrored `shadowForest` copy: the seam at mid x 96 does not show, the second statue pair does if one looks for
  it. A second forest painting would end that.
- One painting each for linden, poplar, apple tree and willow (see 13.5). (Three each since section 18.5.)
- The wall behind the whole town or only at its left (13.5).
- `skyMid` (a third sky stop at dusk) and the night sky's top rows, as after stage 1.
- The six scenes were judged by the painter; a player's eye and Louis have not seen them.

**Open after the fix stage** (section 14 has the reasons).
- The lord is painted as a man only. Louis may choose a lady of the house (the Burgherrin) instead: a second `king`
  and `kingGlow` strip of the same size and frames is not painted, and the engine has no switch for it.
- The review's optional findings that were left: the statues and the ruin of `shadowForest` sit in the mist at
  night; the granite pieces' small details; the crow's wings, beak and tail and a more threatening gloomweaver; the
  split of `valleyVista` and the `skyMid` stop; flipped paintings, tree variants and relit clouds; the brute's
  chevrons and lantern, the giant's ribs and the bank's dither; the HUD corner's clouds.
- `wardenStatue` (look 1's sprite, unchanged) carries ivy; the Throat has no other plant.
- At night the wall's snow reaches 0.31, not the review's 0.45 (the ratio to the shaded rock is met).
- In `valley-golden` (focus 2560) `cleftFace` covers the far castle's left part; the castle is faint in the golden
  haze (0.49 against the slot's 0.72).

### 13.7 Recraft

`bash tools/recraft.sh gen <prefix> recraftv4_1 2:1 1 "<prompt>"`, 1536x768, 35 credits each, raws in
`build/recraft/lh/look2/world/` (git-ignored). The job's budget was six images. The first, `weltmauer-1.png`, was
made by the lane before this stage (251 → 216 credits): a pyramid of peaks, not used. This stage made five and
stopped at 41 credits; nothing is left to spend. The fix stage (section 14) made no image: 41 credits before and
after. The raws are not in git; where they lie and who must copy them: 13.1.

| # | File | Credits | Used for |
|---|---|---|---|
| 1 | `wall-1.png` | 216 → 181 | `weltmauer`, `weltmauerPatch` |
| 2 | `gorge-1.png` | 181 → 146 | `gorgeRock`, `cleftFace`, `cleftFaceEnd`, `cleftFlank`, `cleftFlankB`, `cleftThroat` |
| 3 | `forest-1.png` | 146 → 111 | `shadowForest` |
| 4 | `trees-1.png` | 111 → 76 | the four firs, two dead trees, linden, poplar, apple tree, willow |
| 5 | `valley-1.png` | 76 → 41 | `valleyVista` |

Prompts, as sent:

1. `wall-1`: "An impossibly high sheer mountain wall seen straight from the front, filling the whole image from the
   left edge to the right edge like a gigantic rampart of the world: one unbroken line of vertical grey granite cliffs
   and ice, the jagged sawtooth ridge stays at the same enormous height across the entire width, many sharp teeth and
   spires of similar height side by side, no dominant summit, no pyramid shape, no gentle slopes, no foothills. Snow
   and ice on the top quarter and in narrow vertical gullies, bare dark rock faces with long vertical cracks,
   buttresses and couloirs below, the base lost in pale mist. Cold slate blue-grey rock, deep blue shadows, pale snow,
   light from the upper left. Crisp detailed 16-bit pixel art, front view, clean hard pixel edges, large clear shapes,
   no trees, no buildings, no clouds, no night, no sun, the sky a flat solid pure magenta #FF00FF, no text, no
   border."
2. `gorge-1`: "A sheer vertical granite cliff wall seen straight from the front, a long horizontal stretch of it
   filling the image from the left edge to the right edge: tall narrow slabs, pillars and chimneys of solid rock split
   by long vertical cracks and deep dark fissures from bottom to top, a few small narrow ledges with a dead twisted
   bare tree or a tuft of dry grass, dark wet streaks, fallen boulders and scree along the bottom edge. The top edge
   of the cliff is jagged and broken, with a thin strip of sky above it. Natural mountain rock, not bricks, not
   masonry, no stacked blocks, no horizontal layers, no stairs, no cave. Warm-neutral grey granite with a little
   umber, dark shadows in the cracks, light from the upper left. Crisp detailed 16-bit pixel art, front view, clean
   hard pixel edges, large clear shapes, no buildings, no people, no night, no fog, the sky a flat solid pure magenta
   #FF00FF, no text, no border."
3. `forest-1`: "The edge of a dark primeval fir forest seen from the side as one long horizontal band from the left
   edge to the right edge, standing on a straight flat ground line along the bottom: very tall dark blue-green fir
   trees of very different heights crowded close together, their pointed tops forming an uneven jagged skyline,
   several dead bare grey trees and broken trunks between them, deep black shade between the trunks. In front of the
   trees, small against them: the ruin of an old low stone defensive wall with a gap, the stump of a broken round
   watchtower, two weathered grey stone statues of robed lords each holding a lantern, half sunk and leaning in dead
   brown moor grass, a few dark peat pools and rotting fence stakes. Dark fir green, cold grey stone, dull brown moor,
   light from the upper left. Crisp detailed 16-bit pixel art, side view, clean hard pixel edges, large clear shapes,
   no people, no animals, no fire, no glow, no night, no fog, the sky a flat solid pure magenta #FF00FF, no text, no
   border."
4. `trees-1`: "Sprite sheet of ten separate trees standing side by side in one single row on the same ground line,
   each tree whole from root to top, clearly apart from its neighbours with empty space between them, none touching:
   from left to right four tall dark blue-green fir trees of different heights and shapes (one very tall and narrow,
   one with a broken dead top, one leaning with sparse bare lower branches, one shorter and ragged), two dead bare
   grey trees with twisted branches, one broad old linden tree with a heavy round dark green crown, one slim tall
   poplar, one small gnarled apple tree, one weeping willow with hanging branches. Irregular natural shapes, dark
   muted greens, grey-brown trunks, light from the upper left, deep shade on the right side of each crown. Crisp
   detailed 16-bit pixel art, side view, clean hard pixel edges, no ground, no grass, no cast shadows, no people, no
   night, no fog, no sky, isolated on a flat solid pure magenta #FF00FF background, no text, no border."
5. `valley-1`: "A wide sombre mountain valley seen from the side as one long horizontal panorama from the left edge to
   the right edge, in three clear layers of depth: in front a long row of steep rounded hill slopes densely covered in
   dark fir forest, individual pointed fir tops along every ridge line, a few small dull green meadow clearings low
   down; behind it a second, higher range of forested ridges, paler and bluer in haze; behind that a third range of
   bare rocky mountains with a little snow, very pale blue-grey, almost lost in haze. Each layer clearly lighter than
   the one in front. Dark muted fir greens, blue-grey haze, no bright colours, no yellow fields, light from the upper
   left. Crisp detailed 16-bit pixel art, side view, clean hard pixel edges, large clear shapes, no houses, no roads,
   no people, no river, no clouds, no night, no sun, the sky a flat solid pure magenta #FF00FF, no text, no border."

The paintings' background came back as `#FC0CBC`; the converter keys on that value (never `--key auto`: it once took
the rock for the key).

### 13.8 Notes for the engine port (nothing here is done in Swift)

1. **Sprites.** Add the ids of 13.1 with their sizes, one frame each. `farCastleGlow` and `farCastlePane` are glow
   strips in the sense of SPRITES.md (same size as the far castle's 40x46 cell block, lit cells only);
   `farCleftGlow` and `farCleftGlowBack` are emissive strips of the slot's light (item 5).
2. **Planes.** Two more than look 1: `near` at parallax 0.75 (single trees) and `fogM` at 0.62 (the mist band). Order
   back to front: sky 0.05, far 0.2, mid 0.5, fogM 0.62, near 0.75, fogA 0.9, world 1.0, fogB 1.15, fg 1.3. Inside a
   plane by z as the tables give it. Take every position from `layout_look2.py` (`WORLD`, `DEPTH`, `LANES`,
   `fog_region`, `dropped`, `SWAP`); haze and ambient per plane as section 3 and 7.
3. **Look 2 leaves out** what `dropped()` lists and draws `cleftFlank`, `cleftFlankB`, `cleftThroat` where look 1
   draws `cliffFlank`, `cliffFlankB`, `throatRock` (same x, y, z, flip, shade). Look 1 stays as it is.
4. **Shades.** `cleftFace` and `cleftFaceEnd` are drawn at 0.42 of their plane's ambient (`sh`), `gorgeRock` and
   `gorgeCrags` at 1.0 (fix stage: their granite is dark in the file, so the lit slab edges keep their step),
   `wardenStatue` at 0.88, the world cliffs at 0.7 and 0.62 as before.
5. **The far castle's lights.** `farCastleGlow` at far (260, 75): additive in `fireGold`, strength = the torch curve
   (0 by day, 1 at night), no flicker larger than ±10 % at 2 Hz and no light radius (cells only; with bloom, 12.4, they
   glow into the slot). `farCastlePane` at far (586, 75): additive in `window`, the same curve. Under each, the
   slot's light: `farCleftGlow` at far (258, 75) and `farCleftGlowBack` at far (584, 75), additive, each pixel's own
   colour × (0.11, 0.13, 0.19) × the torch curve, no flicker; `farCleftGlowBack` fades with `farCastlePane`
   (item 6). By day the slot needs no emissive: its albedo is the palest on the wall.
6. **The cross-fade past the back gate.** `weltmauerPatch` alpha = 1 − smoothstep(2330, 2520, camera focus x);
   `farCastlePane` (sprite and glow) alpha = smoothstep(2330, 2520, focus). A glow's strength is multiplied by its
   sprite's alpha (the one line in `mock.py`). Reason for the patch: at parallax 0.2 the valley's slot would
   otherwise slide across the sky behind the castle's towers.
7. **The beacon in the far view.** The Great Beacon stands at world x 470 on the play plane, just before the gorge's
   mouth, so in the view from the shadow land it is the real sprite with its own light and needs nothing on the far
   plane. From the valley it lies beyond the castle: once it burns, the town sees its light through the slot. Port:
   an additive column in the slot above the far castle's back, far x 604 to 608, from y 110 (75 + 35, the castle's
   top) up to the ridge, `fireGold` at 0.5 at the bottom falling to 0 at the top, with the beacon's own flicker,
   faded with `farCastlePane` (item 6); with bloom (12.4) it glows on the slot's inner faces. Section 12.4's light
   shaft through the cleft takes the same anchor (far x 606) at night once the beacon burns. This is new against
   12.4, which put a light on the far keep's top: the beacon is not on the keep.
8. **Near trees in the wind** (12.4): draw each near tree in three horizontal slices (the foot third fixed, the middle
   offset 0 or 1 px, the top 0 to 2 px, whole pixels) by `round(a sin(0.7 t + 0.02 x))`; dead trees a = 1 at the top
   only; `willow` sways its lower half instead (the hanging branches), the trunk fixed. Reduce Motion: off.
9. **Fog** (12.4): `d2MistBand` drifts −2 px/s, `d2FogBank` −5 px/s, `d2FogLow` −9 px/s toward the castle at night,
   still at noon, a second `d2FogBank` at half alpha the other way; the share by world x is `fog_region` (1.0, 0.7,
   0.45). In the gorge the banks are the only light band behind the fire pools; keep their cores at 0.45 to 0.60 V.
10. **Particles.** `d2Sparks` over each lit brazier (the mock places one at x 602, y 22 in `shadow-night`),
    `d2Smoke` over the town's chimneys (`SMOKE`), `d2Fireflies` in the valley at dusk.
11. **Lanes.** `LANES`: `laneMoor` −64 to 448, `laneScree` 448 to 1240 (the Throat), `laneCobble` 1240 to 2430,
    `laneEarth` from 2430; variant A to D by a hash of the tile index (64 px tiles, 26 rows; the top rows lie on the
    ground line as in the mock).
12. **Blend and anchor of the masks and particles** (the numbers live in `mock.py` and `layout_look2.py`).
    - `d2FogBank` (fogA), `d2MistBand` (fogM), `d2FogLow` (fogB): tiled without a gap and never flipped; the bottom
      row 4, 2 and 14 px below the ground line; normal alpha blend in the hour's fog colour, alpha = the mask's
      alpha × the hour's fog density × the plane's share (0.9 × `fogScale`, `fogMShare`, 0.6 × `fogScale`) ×
      `fog_region(world x)`, capped at 1.
    - `d2Smoke`: centred over a cottage's chimney (house x + 49, or + 14 when the house is flipped; `SMOKE`), its
      bottom 46 px above the ground line; normal alpha blend, tint (0.74, 0.74, 0.76) × the world's ambient, alpha ×
      `LOOK['smoke']`; it hides nothing behind it from the light pass.
    - `d2Sparks`, `d2Fireflies`: additive, each pixel's colour × `fireGold`, anchor bottom left; sparks at full
      strength over a lit brazier (the mock: x 602, 22 px above the ground line in `shadow-night`), fireflies × the
      torch curve, 6 to 8 px above the ground line in the valley.
    - Glow strips on the far plane: anchor bottom left on the far castle's foot (far y 75), additive, hidden where a
      sprite drawn later in the far plane covers them (the patch).
13. **The far plane's haze clearing and key** (fix stage; section 7's two new rows, 14.3). Without them the wall's
    snow and shaded rock have one value at night and at dusk.
14. **Names: what the plan called a piece and what was delivered.**

    | Plan (sections 7, 9, 12) | Delivered id |
    |---|---|
    | `fogBank`, `mistBand`, `fogLow` | `d2FogBank`, `d2MistBand`, `d2FogLow` (one variant each) |
    | the Weltmauer with the cleft, from both sides | `weltmauer` (both slots in one sprite), `weltmauerPatch` |
    | the far castle, its windows | composed into `weltmauer`; `farCastleGlow`, `farCastlePane`, `farCleftGlow`, `farCleftGlowBack` |
    | the cliffs at the cleft (throat rock, flanks, high wall) | `cleftThroat`, `cleftFlank`, `cleftFlankB`, `cleftFace`, `cleftFaceEnd` |
    | the gorge's rock and mouth | `gorgeRock`, `gorgeCrags` |
    | the shadow land's forest, ruins and statues | `shadowForest`, `d2FirBeltFar`, `wardenStatue` (look 1's) |
    | near firs and dead trees | `firA` to `firD`, `deadTreeA`, `deadTreeB` |
    | the valley's hills and distance | `valleyVista`, `d2TreeBelt` |
    | linden, poplar, orchard, willow | `linden`, `poplar`, `appleTree`, `willow` (one each) |
    | bushes, foreground strips | `d2BushA`, `d2BushB`, `d2FgFerns`, `d2FgMeadow`, `d2FgReeds` |
    | lane tiles, lane end | `laneMoorA…D`, `laneScreeA…D`, `laneCobbleA…D`, `laneEarthA…D`, `d2LaneEnd` |
    | smoke, fireflies, sparks | `d2Smoke`, `d2Fireflies`, `d2Sparks` |
    | the Gloom's bank (11.5) | `darknessBank`, `darknessEdge`, `darknessBankGlow` |
    | cobbled market square, lit interiors, props; cloud deck and moon | not delivered (13.6); the clouds are look 1's `cloudA…C` |

15. **Texels.** The 55 world ids of 13.1 (with the fix stage's) are 871 098 texels: 21 % of one 2048² page.
    Counted with `darknessBankGlow` (256x236, four frames) and `wardenStatue` (96x200), which look 2 also draws:
    950 714. The fix stage added 44 816 (`gorgeCrags` 32 000, `laneScreeA…D` 6 656, `farCleftGlow` 3 168,
    `farCleftGlowBack` 2 992) and grew `weltmauerPatch` (7 220 → 9 880), `farCastleGlow` (900 → 1 840) and
    `farCastlePane` (1 050 → 1 840). Eleven pieces are wider than 256 px (`weltmauer` 888, `d2TreeBelt` and
    `d2FirBeltFar` 520, `d2FgFerns` and `d2FgMeadow` 480, `gorgeRock`, `cleftFace`, `valleyVista` and `d2MistBand`
    448, `d2FogBank` 384, `d2FogLow` 320); they fit a page whole. If the atlas needs tiles of at most 256 px, cut
    them at load (`weltmauer` in four); that is the lead's choice, the files stay whole.

### 13.9 The mock and the plates

`scene_look2.py` has three more scenes (the six of stage 1 are unchanged, `run_look2.sh` still renders those six):
`shadow-night` (focus 556, night: the gorge's mouth, eight creatures and two crows out of the fog, two braziers, the
lord with archer and guardsman at the palisade), `wall-dusk` (focus 250, dusk: the view back) and `valley-golden`
(the town at focus 2560 in the golden hour).

Plates for Louis in `ci-out/look2-fable/world/` of the lead's worktree (3x, PNG and JPEG):
`1-schattenland-nacht`, `2-weltmauer-daemmerung`, `3-tal-goldene-stunde`, then stage 1 above stage 2 for the six
scenes (`4-front-nacht-alt-neu`, `5-burg-daemmerung-alt-neu`, `6-hof-daemmerung-alt-neu`, `7-platz-daemmerung-alt-neu`,
`8-stadt-mittag-alt-neu`, `9-fluss-goldene-stunde-alt-neu`) and `10-uebersicht`, all nine frames of stage 2 on one
sheet. The fix stage rendered all of them again under the same names (the lower half of 4 to 9 is now the fixed
world), and the nine creature plates in `ci-out/look2-fable/creatures/`.

## 14. The fix stage (10.11.2026, night)

Two reviewers looked at stage 2 and stage 3 (the art and its code; the plates as a player), a third tried to refute
each finding. Eight findings held as high and are fixed here; of the optional ones the cheap and clearly right were
taken (14.6). No Swift, no SPRITES.md id, size or frame count and no palette name changed; one palette-free colour
was added to the mock (`cleft`). `tools/build-art.sh` rebuilds every committed PNG byte for byte (a full run,
3:25). No Recraft image was made (41 credits before and after).

### 14.1 The creatures and the lord

In sections 6.1, 6.2, 11.2 and 11.3 and in ART-actors.md (rows, glow rules, the measured eye and lantern positions):

- Every kind has one cold eye low in a dark socket. No pale face disc and never two eyes: two pale points on a
  round dark head are a stock creature, a pale oval is a mask.
- The small kinds are stooped husks with a hump and a torn hood; nothing of a child is left in them.
- The hound has a long low neck, a hump and hands for forefeet.
- The Lightless King wears no crown: a dead briar grows swept back out of the cowl's rim.
- `king` and `kingGlow` are the young beardless lord with a tilted gold circlet (the old bearded king is gone from
  every plate).
- From the optional findings: the crow's skull is dark (its pale head was the brightest thing in a wave); the
  giant's skull is dark with one eye.

### 14.2 The gorge and the Throat

Louis: only rock on the side the monsters come from, and dark. Stage 2's gorge was rock, but its face was a soft
grey painting drawn at shade 0.42, its mouth was one flat cut-out, and the ground under it was the moor with ferns.

- **`gorgeRock` is granite in the file** (`worldart.py gorge`): the granite ramp only, the body one step down, the
  slabs' upper and left edges lit (the moon stands upper left), seven straight joints that jog where a slab ends.
  It is drawn at shade 1.0, so the lit edges keep their step against the body. At night the face measures 0.162,
  the mouth with the crags 0.151. It cannot go lower through the art: the mid plane's night haze alone puts 0.10 to
  0.13 on a black pixel.
- **`gorgeCrags`** (160x200, near plane, x 415, y −10): five dark crags before the face's broken edge. The mist band
  lies between the two, so the mouth has depth. From focus 500 on they cover the far castle: at the palisade the
  view is rock.
- **The Throat** (world 470 to 1240): the lane is `laneScreeA…D` (bare rock, scree, two cart ruts, loose stones);
  no tree on the near plane, no fern in the foreground, no grass, no moss.
- **The warden statue** stands again, cut into the Throat's wall (mid x 520, y −34, shade 0.88), its bowl burning
  all night (`hearthFire`, a light of radius 70). It is the one made thing between the palisade and the castle and
  sits behind the lord at focus 917.

### 14.3 The Weltmauer, the slot and the far castle

Stage 2's wall was one blue-grey value with a row of equal teeth, and the castle in its slot could not be found.

- **Seven massifs** (`RIDGE`, `MASSIFS`, `reprofile`): the ridge is drawn again, each massif with a summit, a
  shoulder or second peak and a saddle (summits at rows 6 to 14, saddles at 30 to 36); the painting's teeth ride on
  it at 0.4 of their size. The height stays even: still a rampart, not a mountain.
- **Granite below a snow line** (`regrade`): above a wandering line (mean row 44) a massif's lit side is one snow
  cap, its shade side dark rock with shaded snow; below it the wall is the granite ramp, lit side `rock` and
  `rockLight`, shade side `rockDark` and `rockDeep`; snow runs down eight couloirs for at most 46 rows.
- **The slot** (`cut_cleft`): sheer, 40 px wide at the castle (as wide as the castle), narrowing by jogs to about 27
  toward the ridge, a horn on its left lip and a free pillar on its right; the right inner face lit, the left dark.
  Behind the castle it is filled with flat pale levels (`foam`, `mistLight`, `farPale`, `mist`, the last thinning
  into the sky). It is the lightest part of the wall at every hour.
- **The far castle at 1/6** (`far_castle`, `mini_castle`; was 1/8): 40x46 cells, a dark silhouette (`stoneDark`,
  paler faces `farDeep`) with a 1 px `moon` edge on the left. At true proportions it was a square block, because the
  keep filled the gap between the towers. So the keep is drawn smaller (0.6 of its size from the front, 0.46 from
  the back) and 152 px higher, its shaft running down behind the walls: it stands deeper in the cleft. The outline
  is tower, keep, tower. The lit pane sits one cell lower than in `keepTop` (off the merlons' row).
- **The lights.** `farCastleGlow`: six cells (the keep's pane, the left tower's slit, the right tower's two slits,
  two watch fires). `farCastlePane`: one cell. `farCleftGlow` (44x72) and `farCleftGlowBack` (44x68) are the slot's
  pale cells without the castle's, as emissives at night in the colour `cleft` (0.11, 0.13, 0.19) × the torch
  curve: a faint cold light in the slot, so the castle is a silhouette at night too.
- **Two renderer terms** (mock `LOOK2`; the port needs both, section 7). The far plane has no key light, and its
  haze colour is brighter than lit snow, so snow and shaded rock came out as one value.
  - `farClear` 0.5, `farClearH` 64: haze = far haze × (1 − 0.5 × (1 − smoothstep(row / 64))) + the low mist, row
    counted from the top of the 201-row screen. The wall's top stands clear, its feet stay in the mist.
  - `farKey` 0.5, `farKeyLo` 0.55: before the haze, lit += albedo × 0.5 × smoothstep((luma − 0.55) / 0.2) ×
    (moon (0.55, 0.60, 0.92) × moon height × night + the hour's cloud colour). Only pale albedo takes it (snow, the
    slot's light).
  Look 1 renders byte for byte as before (both default to 0).

### 14.4 The view kept free

- Far clouds: `cloudA` −60, `cloudB` 322, `cloudC` 640 flipped; none before far x 260 to 300 and 586 to 626.
- Sky clouds: `cloudB` from x 60 to 4, so the sky above the slot is clear.
- Near trees in the shadow land: firs only west of world 247, dead trees to the beacon.
- Valley: between world 2386 and 2616 only apple trees.

### 14.5 Measured

Luma of the 3x renders, the wall above the cloud deck (rows under 40) in `wall-dusk` at three hours:

| Hour | Snow | Shaded rock |
|---|---|---|
| night (tod 0.95) | 0.31 | 0.15 |
| dusk (0.8) | 0.50 | 0.24 |
| noon (0.5) | 0.83 | 0.39 |

The review asked for about 0.45 against 0.22 at night and 0.75 against 0.5 by day. The ratio of two to one is met at
every hour; the night level is lower, because a brighter wall lifted the night frame above section 9.9's range.

The castle reads as two towers and a keep with lit windows at dusk, at night and at noon (`wall-dusk`) and at the
far left of `square-dusk`.

### 14.6 The optional findings

Taken: the crow's and the giant's skulls (14.1); the sky cloud off the slot (14.4); the doc corrections (13.1's
"albedo only", the blend and anchor rules, the name table and the texel count in 13.8, the lord's open variant in
13.6, the SPRITES.md text for the lead in 11.4).

Left, each with its reason:

| Finding | Why it is left |
|---|---|
| The statues and the ruin of `shadowForest` vanish in the mist at night | lifting the forest covers the far castle's foot; they show by day and at dusk |
| Small details on the granite pieces | they pass their targets; a repaint needs a painting, and no credit is left |
| The crow's wings, beak and tail; a more threatening gloomweaver | 12x10 px leave two pixels a wing; both need a new design, not a fix, and should be judged in motion first |
| `valleyVista` split in two planes; a `skyMid` stop at dusk | the first needs a second painting; the second is one ramp colour and belongs to the port |
| Flipped paintings, more tree variants, relit clouds | needs paintings; the flips are placed where the light's side does not show (firs, far copies) |
| The brute's chevrons and lantern, the giant's ribs, the bank's dither | readable at 3x; each is a redesign of a rig, and the walk cycles have not been seen in motion |
| Bright clouds under the HUD's corner | the HUD is the engine's; move or dim the cloud once the HUD's rect is fixed |

### 14.7 For the lead

- The paintings' raws are outside git; 13.1 says where and who must copy them. They were copied into the lead's
  worktree and the main checkout (git-ignored there too) so they survive this worktree.
- SPRITES.md still describes look 1's glow strips; the replacement text is in 11.4.
- The new ids are not in SPRITES.md (13.1).
- `wardenStatue` carries ivy; say if the Throat's one plant should go (it means repainting look 1's sprite or a
  look-2 copy of it).

## 15. Stage 4: the art pass (10.11.2026, night)

The people and the houses brought to the level of the creatures and the world. Art only: no Swift, no project.yml, no
test changed. Every existing SPRITES.md id keeps its size, its frame count and its frame meanings; every new id is a
**proposal for the code lane** and stands under "Proposals of the art pass" in SPRITES.md with its size, frames and
anchors. `tools/build-art.sh` rebuilds every committed PNG byte for byte (a full run, about 6 minutes on this Mac; a
second run changes nothing). No Recraft image was made (41 credits before and after).

### 15.1 What was painted

| step | commit | ids | how |
|---|---|---|---|
| the lord | f830685 | `king`, `kingGlow`, `portraitKing` repainted; `lady`, `ladyGlow`, `kingSeated`, `kingSeatedGlow`, `ladySeated`, `ladySeatedGlow`, `portraitLady` new | part grids in `tools/grids/actors/` (actorart.py), the portraits as grids |
| the castle grows | f1b776c | tier 1 unchanged; `keepTop2`, `keepTop3`, `castleFront3`, `castleFrontScaffold`, `backTop2`, `backTop3`, `farCastle2`, `farCastle3`, `farCastleBack2`, `farCastleBack3`, each with its `…Build` state, their glows and the slot's cut-out glows, all new | `tools/castleart.py`, the lane `castleTiers` of `build-art-world.sh` |
| soldiers and townsfolk | 1c10bae | `archer`, `guardsman`, `builder`, `citizen`, `citizenB`, `citizenC` repainted; `citizenSeated`, `citizenBSeated`, `citizenCSeated` new | part grids (actorart.py); the seated ones `include` the standing ones' parts |
| the town | 69c0794 | `house`, `houseB`, `houseC`, `bigHouse`, `tavern`, `market`, `well` repainted | `tools/townart.py` |
| the defences | the commit after 69c0794 | `palisade`, `stoneWall`, `bastion`, `archerTower`, `watchtower`, `fireTower`, `beaconTower`, `greatBeacon` relit | their grids as before, then `townart.py relight` (the function `relit` in `build-art-buildings.sh`) |

**The lord and the lady.** The Burgherr is the young lamplighter of STORY.md: lanky, tousled hair, the circlet low on
the brow, a mantle and a cloak, the hooked lantern pole. The Burgherrin is the same role in the same frame: a young
woman with a dark plait, the same circlet, cloak and pole. Both are grown, lean figures (decision 6: nothing here has
a child's features). Seated they face the hall, the head in profile, one hand on the lantern pole that stands at the
throne's arm rest.

**The people.** The method of the lord: lean grown figures 12 px wide, look 2's selective outline (`outline ink
shade`: ink only right of and under the body), a lit column at the left and a shade column at the right of every
part, two-tone legs, walk cycles with contact and passing poses. The archer wears a leather hood and the house's
teal tabard and carries a quiver and a longbow; the guardsman a nasal helm, mail, the teal kite shield and a spear
taller than himself; the builder a cloth cap, a smock, a tool belt and a long mallet. The townswoman (`citizen`)
keeps her basket, the townsman (`citizenB`) his sack, the old farmer (`citizenC`) his straw hat and stick.

**The town.** One painter with one vocabulary (tile, slate and thatch roofs with courses and a lit slope, lime-washed
plaster with the eave's cast shadow, oak posts, beams and braces, shuttered windows over flower boxes, plank doors
with iron bands, field stone plinths, coursed grey stone, vines, wood piles, barrels) instead of the flat Recraft
conversions and hand-set grids. The three cottages differ in roof and shutters (red tile and teal; teal slate and
red; thatch with a dormer and green); the big house has two storeys, two chimneys and a dormer; the tavern a stone
ground floor, a jettied storey, a front gable and its tankard sign; the market three stalls whose awnings have a lit
top, a crease and a scalloped valance; the well a shingled roof, a windlass and a bucket.

**The defences.** Their M2b grids were evenly lit and outlined in ink all round, which set them apart from the
castle and the new town. They keep their grids, sizes, frames and silhouettes; a pass after the grid relights them:
per row and per material (the stone ramp, the wood ramp) the left quarter of the body is one step lighter, the right
third one step darker (joints and the darkest stones keep their value, so the courses still read), the ink outline at
the left and on top becomes a lit edge, the outline at the right and at the ground stays. Banners, iron, the fire
bowl and the arrow slits are untouched. `brazier`, `torchPost`, `beaconBase`, the gates, the engines and the rubble
are as they were (too small for the pass, or composed over the ruin).

### 15.2 Notes for the code lane

- **Nothing breaks if nothing is done:** every repainted id has its old size, frames and anchors. Two anchors moved
  by a pixel: the archer's arrow lies on the frame's row 9 (was 10) and leaves at col 11; the guardsman's spear tip at
  the thrust (frame 7) stays at col 13, row 11.
- **The window masks are unchanged.** The glass (`night1`) sits where the layout's masks light it: the cottages
  (11,8,5,6), (46,8,5,6), `houseC`'s dormer (27,33,3,2); `bigHouse` (26,24,5,5), (41,24,5,5), (16,9,5,5), (50,9,5,5),
  the dormer (35,40,3,2); `tavern` (11,25,5,5), (41,25,5,5), (69,25,5,5), (15,9,8,5), (56,9,8,5), the lantern
  (32,10,1,2). The glazing bars are `woodDark`, so they stay dark inside a lit window. The tavern's gable has a dark
  loft hatch (`night1`, cols 61-63, rows 17-19) that no mask lights: leave it dark.
- **The lady** swaps `king` for `lady` (and the glow, the seated strips, the portrait) everywhere; the lantern's
  anchors are the same pixel for pixel.
- **The seated lord** (`kingSeated`, 4 frames: sit down 0-1, idle 2-3) is drawn at the throne's centre over the
  `throne`; he covers most of the 14x24 throne, only its back posts and arms show. The hall interior's painted dais
  is centred about world x 1837, the throne at 1824: move the throne (and the seated lord) 13 px right, or accept the
  offset; the art was not changed for it.
- **The benches:** a `bench` seats two (the sitters' left edges at bench x +2 and +18) or three (+0, +10, +20); draw
  the bench first. The seated strips' frame 1 is a nod, to be shown now and then, not looped.
- **The castle's tiers:** the table in SPRITES.md is the contract (which sprite replaces which at which anchor,
  the masks, the far overlays and the slot's cut-out glows). Up close the castle cannot grow upward (the crowns reach
  y 172 of 178): it grows behind the wall walk, in the towers' mass, and fully in the far view.
- **Flipped houses:** the layout mirrors every second cottage. The painted light then comes from the right on those;
  at the cottages' size it does not read as a fault, but nothing larger (the big house, the tavern) should be flipped.
- **Sources kept, unused:** `grids/house-front.txt`, `grids/well.txt`, `grids/buildings/{bigHouse,market,tavern}.txt`
  and the cottage's Recraft box are the old sources; `build-art.sh` and `build-art-buildings.sh` name them in a
  comment and build from `townart.py` now.

### 15.3 Notes for the engine port

- Albedo only, as before: the houses carry no painted night. Their cast shadows (under eaves and jetties) are part
  of the albedo and are right for any light from above.
- In the mock the hall lights actors dimly (the room's ambient is applied to them without the hearth's and the
  chandeliers' light): the seated lord and the waiting townsfolk read darker there than they should in the engine.
- The spear's pale blade is faint against a pale day backdrop; the engine's rim light (12.4) would lift it.
- New mock scenes: `hall-audience`, `hall-audience-lady`, `hall-benches`, `line-night`, `market-dusk`,
  `tier<1|2|3>[b]-<gate|back|far|farback>[-day]` (`tools/scenemock/scene_look2.py`); `tools/artsheet.py` makes
  strip sheets on day, dusk and fire bands.

### 15.4 Open

- The castle's fronts (`hallFront`, `chapel`, `kitchen`) were looked at beside the new town and hold as they are;
  they were not repainted.
- The defences are relit, not repainted: the stone wall's blocks and the bastion's courses are the M2b drawing. A
  repaint with `townart.py`'s coursed stone would be the next step if they still look older than the castle in the
  game. `brazier`, `torchPost`, `beaconBase`, the gates, `ballista`, `catapult` and `stakePit` are untouched.
- The M3 court members are not repainted.
- The repainted walk cycles and the seated strips have not been seen in motion, only as strips and in still mocks.

## 16. The fixes after the art pass (10.11.2026, night)

### 16.1 The hands on the cliffs (review finding A7)

The granite painting `gorge-1.png` has four pale dry-grass tufts on two ledges. Cut into the cleft's pieces they
read as five-fingered hands. `worldart.py rockover <png> x0,y0,x1,y1 ...` paints rock over a box: every column takes
the colour of the cell above the box. `build-art-world.sh` runs it on the converted parts before the pieces are
assembled (the boxes stand in the script). Changed: `cleftFace`, `cleftFaceEnd`, `cleftFlankB`, `cleftThroat`,
`gorgeRock`. `cleftFlank` and `gorgeCrags` never had a tuft. The dark dead bush on `cleftFace` and `cleftFaceEnd`
stays: it is dark and reads as a shrub. (Painted out in section 18.3.) Plates 07, 08 and 10 of
`ci-out/look2-fable/art` are re-rendered; the
plates of `ci-out/look2-fable/world` still show the old cliffs.

### 16.2 The lord and the lady sit on the throne

Louis: the lord sits on the throne during audiences, and the sheet showed figures that seemed to stand beside it.
Three causes, three fixes:

- **The pose.** `kingSeated` and `ladySeated` were drawn from the front with straight shins and hid the throne
  whole. They are redrawn in the game's side view (`grids/actors/kingSeated.txt`, `ladySeated.txt`; 16x30, 4 frames,
  the frames' meaning and the lantern glass at cols 13-14, rows 6-7 unchanged, so the glow strips and the light
  anchor hold): the back at the throne's back with the cloak pressed narrow between, the thighs level on the
  cushion, the knees bent at the seat's edge, the shins and boots before the seat's front, the hand on the lantern
  pole that stands behind the knee against the seat. Frame 1 is half lowered with sloping thighs. The lady's kirtle
  lies over the lap and falls from the knee.
- **The throne.** `throne` (14x24) had an ink frame that was lost before the hall's dark dais. Its back posts are
  now gold (lit side) and straw, its lit edge wood, so the posts and finials stand behind the sitter's back and
  head. Size and id unchanged.
- **The place.** The hall's painted dais is centred on x 1837; the throne stood at x 1817 to 1831, before the
  dais's left end, with the dais's carpet beside it like a second seat. The mock scenes `hall-audience`,
  `hall-audience-lady` and `hall-benches` now stand the throne at x 1830 (centre 1837), the seated lord on it and
  Odile 20 px right of the centre (`THRONE_X`, `_throned` in `scene_look2.py`). **For the code lane:** move the
  throne and the seated lord 13 px right (centre 1837), as 15.2 already asks; at 1824 the game shows him beside
  the dais's middle.

Plates re-rendered: 02 (the strips composited on the throne, day and fire bands, at 6x like the first sheet), 04, 05,
06 and 14.

### 16.3 Open

- `hallFront`, `chapel` and `kitchen` are not repainted (15.4 stands); the hour went to 16.1 and 16.2. (Done in
  section 17.)
- The seated strips are judged as stills only. Seated, the lord is one of the darker figures of the hall: before the
  dais's dark wood he reads by the gold posts, the cushion and the lantern, less by his own colours. A lighter dais
  front in `hallInterior` would help more than any further change of the strip. (Done in section 18.3.)
- The hall's `taxLectern` and the M3 court's places beside the throne follow the throne's x in the code lane.

## 17. Stage 5: the castle's fronts (10.11.2026, night)

### 17.1 What was repainted

- **`chapel` (160x96) and `kitchen` (120x80):** painted anew by `tools/frontart.py repaint <id> <png>`, with
  `townart.py`'s vocabulary and palette names. `build-art.sh` still converts the Recraft painting first; that
  conversion now gives only the silhouette. Every opaque pixel is repainted, no transparent one is touched, so
  `roomart.py silhouette` reports the same silhouette as before (10565 and 7254 opaque pixels) and
  `chapelInterior` and `kitchenInterior` keep their outlines.
  - The chapel: coursed ashlar without ink joints, four two-stage buttresses with a lit face, a shaded side and a
    cast shadow on the wall, lancets with dressed jambs, hoods and pale sills, the gabled bay a step darker at the
    right with the Flame in gold over its lancet, a pointed oak door, the bell tower with a lit front and a shaded
    side, a slate spire and nave roof with a lit slope (`townart.roof`).
  - The kitchen: a rubble ground floor with an arched double door, barrels, a wood pile and herb pots, a jettied
    storey of plaster between oak posts with two shuttered windows over herb boxes, a hipped slate roof, the big
    stone stack lit from the left.
- **`hallFront` (260x90):** relit in `roomscenes.hall_front`, not redrawn. The wall's faces are lighter and mixed
  (stone and stoneLight), the joints, the corbels and the plinth carry stoneDark instead of ink, the cornice, the
  left end wall and both buttresses cast a shadow one step down the stone ramp, the right 14 columns and the
  roof's right 20 are a step darker, the buttresses have a lit left edge. The end walls (x 0-20 and 239-259) are
  still `hallInterior`'s own pixels.
- **`kitchenInterior`** changed only where it shows the front's stack (its box 70,0,104,8). `chapelInterior` and
  `hallInterior` did not change: their outer frames are their own masonry and do not clash.

### 17.2 The anchors kept (ART-court.md)

- Sizes, frame counts and silhouettes are unchanged.
- The chapel's lancet glass is night1 inside the four masks (x 24-33, 60-69, 95-104 on rows 53-76; x 129-137 on
  rows 53-75). Two saddle bars per lancet (rows 63 and 70) are stoneDark and stay dark in a lit window. The
  belfry's louvres use night1 and ink outside any mask, as before.
- The kitchen's panes are night1 at x 30-32, 34-36 and 84-86, 88-90 on rows 41-43 and 45-47, inside the eight
  masks; the bars are at x 33, x 87 and row 44.
- `hallFront`'s windows, wall lanterns and the door's threshold gap are painted by the same calls at the same
  places as before.

### 17.3 The world plates

`ci-out/look2-fable/world` 1 to 10 are re-rendered from today's art under the same names (PNG at 3x and JPEG):
the nine look-2 frames by `run_look2.sh` with `LOOKS=new` (one render at a time, about 20 s each, 72 °C at most),
plates 4 to 9 stacked on the unchanged old frames by `stack_png.py`, plate 10 by `sheet_look2.py` with `cols=3`.
They show the cliffs of 16.1 without the hands. `ci-out/look2-fable/art/20-burgfronten-alt-oben-neu-unten` shows
the three fronts old above new, beside the tavern and the big house.

### 17.4 Open

- The three fronts are judged on the day sheet only. No mock scene shows them at dusk beside the castle's tiers
  (the court scene shows the hall cut away), and they have not been seen with lit windows.
- The chapel keeps the old painting's stepped left outline; where the tower's foot meets the nave's west corner
  it reads as plain wall.
- `hallFront`'s lean-to, door, banners and stamps keep their ink outlines on all sides.
- The points of 15.4 on the defences, the M3 court members and motion stand. (The defences and the court are
  repainted in section 18; motion is still unseen.)

## 18. Stage 6: the court, the defences, the town at night, the trees (10.11.2026)

Art only, in five steps, each a commit. Ids, sizes, frame counts and anchors are as SPRITES.md and ART-court.md had
them; `tools/build-art.sh` rebuilds every committed PNG byte for byte (checked before each commit: the md5 over
`Resources/Art/*.png` and `git status` are the same before and after a full run). No Recraft credit was used.
Previews: `ci-out/look2-fable/art2` 01 to 17 (PNG at 3x and JPEG).

### 18.1 The M3 court (a95f5d3)

Odile, Brannock, Pip, Hesper, Tamsin, Bram, Marek, Seren, Ser Ludo, the bard, the envoy, the herald, `petitionerD`
and `petitionerE` are redrawn in their grids (`tools/grids/court/`) at the level of tonight's lord:

- lean bodies with the selective outline (ink at the right and at the ground, a lit left edge), a lit and a shade
  column on every cloth, faces of three tones;
- `grids/court/kit.txt` holds the lord's legs with neutral letters (`legs*` 9x13 for the 30 px figures, `short*`
  9x10 for the 26 px ones). A spec takes them with `include kit.txt` and names six colours, so every member walks
  the lord's cycle in its own cloth;
- Pip is a child of about 17 px in his old frame; the herald's rim light is set by hand (his tabard is paler than
  the rim rule's light);
- `hesperGlow` and `serenGlow` are byte for byte the old files, and the lantern and the candle stand where the glow
  expects them.

Plates 01 to 03 (old above new, and the new ones at dusk and by fire).

### 18.2 The defences (5554681)

`tools/defenceart.py repaint <sprite.png> <id>` runs in `build-art-buildings.sh` after a defence's grid is written.
The grid still gives the silhouette, the frames and the features; the tool paints the materials inside it:

- **stone:** coursed ashlar as on the town's stone (courses of 4 rows, stones of 6 to 8 px, lit top edges on the
  lit side only, soft shadowed beds instead of dark joint rows), shaded as a body (a round tower has a lit band left
  of the middle and turns two steps darker to the right; a flat wall has a lit left edge and a darker right
  quarter), a lit cap on every top edge, a cast shadow under a projecting crown, moss and damp at the foot;
- **timber:** the grid's members lit from the upper left, with grain, the ink between members softened;
- **iron:** fire baskets, the great bowl, the portcullis, fittings: lit left, a step darker right.

Slits, holes, soot, banners and glass stay as the grid sets them. In a damaged frame every pixel that differs from
frame 0 stays the grid's (cracks, knocked-out stones, pale breaks). The alpha of every pixel is the grid's.
Repainted: `palisade`, the stone wall, the bastion, the archer tower, the watchtower, the fire tower, the beacon's
three stages, the gates, `ballista`, `catapult`, `stakePit`, `brazier`, `torchPost`. Plates 04 to 07.

### 18.3 The dais and the bush (c57391e)

- **`hallInterior`:** `frontart.py repaint hallInterior` paints only the dais's wood (rows 68 to 80, x 112 to 145)
  as two low steps in light oak: treads in straw, risers in woodLight with a board joint every 7 px, a shadow line
  under each nosing, the right end a step darker. The carpet, the wall, the floor and the shadow at the foot stay.
  The seated lord now reads by his own colours (16.3's open point). Plate 08.
- **`cleftFace`, `cleftFaceEnd`:** the dark dead bush on the ledge and its trunk are painted over with rock
  (`worldart.py rockover`, two more boxes in `build-art-world.sh`). Plate 09.

### 18.4 The town at night and the square's props (d4037bd)

- **`houseLit`, `houseBLit`, `houseCLit`, `bigHouseLit`, `tavernLit`** (`townart.py lit`): one emissive sprite per
  house, the house's size, clear but for the window glass inside the house's masks (the tool stops if a pixel is
  not glass). Each window shows a room: a wall that is brightest near its candle or hearth, a curtain, a shelf, a
  table, a cat on a sill; people are shapes left dark. The tavern has three guest rooms, the taproom with two
  drinkers and the innkeeper before the kegs, the door lantern's flame and one row of light on the step.
- **`hayCart` 40x24, `barrels` 26x14, `noticeBoard` 20x26:** props for the square and the lanes.
- Plates 10 to 13. In the mock the lit sprites are drawn over unmirrored houses only (the mock does not mirror an
  emitter's sprite); the game must mirror them with the house.

### 18.5 Two more paintings of every town tree (b632add)

`tools/treeart.py build <id> … --out <Resources/Art>` paints `lindenB`, `lindenC` (52x92), `poplarB`, `poplarC`
(14x116), `appleTreeB`, `appleTreeC` (42x48), `willowB`, `willowC` (52x68) in the hand of the four `trees-1`
paintings and in their five greens and three barks:

- a crown is built of lobes painted back to front, each with a lit cap toward the upper left, a mid band and a
  dark underside, the silhouette scalloped and broken on the lit side; a trunk follows a path of widths, with a
  root flare and a shadow row at the foot; limbs show in the holes of the crown;
- `lindenB` is slim and tall, `lindenC` old, broad and only 72 px high; `poplarB` is younger and fuller (99 px),
  `poplarC` lean with a notch and a bent tip; `appleTreeB` has a flat crown on two winding stems, `appleTreeC` a
  round crown with seven apples (tile, set on the crown's darkest green only); `willowB` is young and short,
  `willowC` old with the curtain down to the water;
- every variant lies on its first painting's canvas with the trunk at the canvas centre and the foot on the bottom
  row, so the code swaps the id and nothing else. A shorter tree has clear rows on top.

The rule of 13.4 holds (between world 2386 and 2616 only apple trees). `lindenC` takes the first linden's place at
2624: it is 20 px lower and leaves more of the far castle free there. SPRITES.md carries a planting that never sets one painting beside itself.
Plates 14 (the twelve trees by day and at dusk, a citizen for scale) and 15 to 17 (town at noon, valley at golden
hour, the river end: the committed planting above, the proposed one below).

### 18.6 Notes for the code lanes

- Nothing in Swift names the new ids. The lit rooms, the props and the tree variants are proposals; SPRITES.md has
  the draw call and the places.
- `<id>Lit` replaces the house's `.mask` emitters (with both, the glass doubles); the window lights stay.
- The mock's layout (`layout_look2.py`) knows the new trees' widths but still plants the first paintings; the
  plates 15 to 17 were rendered with the proposed planting swapped in by a scratch script.

### 18.7 Open

- Nothing of this stage has been seen in motion or on the runner: the court's walk cycles, the trees' sway slices
  on the new crowns, the lit rooms' fade at dusk.
- The lit rooms are stills; a flicker of the hearth rooms would be the engine's work (a second glow value).
- `chapel`, `kitchen` and `hallFront` have no lit sprite (17.4's first point stands).
- The firs, the lanes and the plants of `depthart.py` keep their paintings; only the four town trees gained two.
- A third willow on the river bank (`willowB` at 3738) is a proposal, seen in plate 17 only.

## 19. Stage 7: the old walls, the fog, the envoys, the circlet (10.11.2026)

Louis' wishes of 09.11. and 10.11., art only. Every new id is a proposal for the code lane (claude/lh-polish);
SPRITES.md carries size, frames, anchor and the draw call. No existing id, size or frame count changed.
Plates in `ci-out/look2-fable/art3`.

### 19.1 The old walls and the anchors

The trouble before: a tier stood as a narrow block at the track's far edge, the mist to both sides of it and the
gorge's rock sliding behind it on the mid plane. It read as a thing one walks around. A piece on the mid plane would
slide against the wall, so everything new lies on the **world plane**, behind the tier.

- **The place** (`oldWall2`, `oldWall3`, 128x108, drawn always): the Throat's granite comes forward to the track in
  two masses, a horn on the Gloom's side and a pillar on the castle's, steep toward the light, in the gorge's own
  hand (`tools/throatart.py` takes the slabs from `gorgeRock.png` and sets the crags' edge rule: every top edge pale,
  the side toward the light a step up, two columns of the deep tone away from it; fissures part a mass into
  pillars). Between them lies the saddle the line stands in. Across it Lady Oriel's wall of the year 118: the
  curtain's broken courses, the stub of the end tower at the pillar (line 2: a doorway half filled with fallen
  stone), blocks, the old footing in the track with the breach where the track runs, a little scree. Old ashlar is
  the defences' ashlar a step paler, with moss in the beds.
- **The anchors** (`palisadeAnchor`, `stoneWallAnchor`, `bastionAnchor`, same canvas, drawn with their tier): the
  footing across the track's 8 rows (so the wall visibly crosses the whole track) and the end piece that ties the
  tier into the pillar: a return of stakes lashed to the old stub; an end tower of ashlar a step darker than the
  wall, toothed into the granite; the bastion's higher, with corbels. The palisade stands in the old stonework,
  the stone tiers swallow it: each upgrade rebuilds more of Oriel's wall.
- **Why the saddle is open:** the first try set a whole shoulder of rock behind the tier. It closed the gorge and
  swallowed the archers on the walk, who read against the mist at night. Now rock stands left and right of the walk
  and the air above the wall stays free; the end towers begin right of the last archer's place.
- `oldWall1` (84x60) is what is left of the first line before the gatehouse. Line 1's plot is the gate and never
  empty, so it is scenery, not a plot state.

Plates 01 and 02 (both plots unbuilt, dusk and night), 03 and 04 (a palisade on the outer line, a stone wall on the
middle line), 05 (a stone wall and a bastion at night), 06 (the six sprites). Scenes `throat-ruins-*`,
`throat-walls-*`, `throat-strong-*` in `scenemock/scene_look2.py`.
