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
keeps a trace of who it was (a hood, a lantern, a tabard in the house's teal gone grey, a child's size); the traces
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
- Their own light is cold: the eye; the weaver's dead lantern spills darkness; the Lightless King's crown points in
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
| Sootling | 14 px | a child-sized husk crawling on its knuckles, arms too long, the head hanging low and turning toward the light; scuttles in bursts, then freezes |
| Sootling B | 14 px | a stick-thin figure walking upright and stiff, the head lolling on a broken neck, arms to the ground |
| Shadehound | 20 px | a thing on all fours that was a man: arched spine, human hands for forefeet, the jaw hanging open, the hind legs bending the wrong way |
| Soot crow | 12 px | a crow of loose ash flakes whose wings come apart and re-form; one eye |
| Ash brute | 44 px | a swollen giant in a tattered cloak, a small head sunk between the shoulders, one long arm dragging a broken lamp-post |
| Gloomweaver | 30 px | a robed figure holding up a dead lantern whose empty cage spills its bubble of darkness; it floats, the hem frayed into smoke |
| Ash Giant | 110 px | a colossus of charred stone and timber, the remains of a beacon tower on its back; one cold eye high up |
| Lightless King | 64 px | a tall crowned shape in the house's teal rags, the face a void with one cold point; his broken crown may echo the lord's circlet (a hint for the story pass to decide) |

**The Gloom's bank** (stage 3, with the creatures): navy soot (`nightDeep`, `nightBlue`) in the fog banks' stacked
levels, drifting motes, and cold eye pinpoints inside it, a few of which blink out.

### 6.2 The lord (stage 3)

The `king` sprite is still the old king (white beard, tall crown). Since the 09.11. evening decision he is the young
lamplighter lord, Aldric's cousin. Repaint `king` (16x30 × 10) and `kingGlow`: a young beardless face, hair in
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
displacement, the fog's hue in light, the moon key, the ledge light, the room rects, the people's rims. The glass test
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

**Still open after stage 1.**
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
2. **Hollow cold eyes that weep.** One `wraithWhite` pixel an eye and a `wraithGlow` or `wraithDim` pixel under it.
   Two eyes wherever the head is wide enough: two close pale points read as a face, one as a lamp. The crow has one.
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
7. **Quiet hints only.** A watchman's pole and dead lantern, a shirt rag, a child's smock, a cage of ribs. Nothing
   names who they were. The Lightless King wears a crown of uneven iron thorns, not the Burgherr's circlet, and
   carries a candle snuffer on a pole instead of a sword: he puts lights out.

### 11.3 The eight

| id | who it was | silhouette and gait |
|---|---|---|
| `sootling` | a child | on all fours, low and long, the pale head too big and hanging; drags itself hand over hand; rears up to claw |
| `sootlingB` | a child | upright, stooped, stick-thin, one arm far too long and dragged; whips the arm forward |
| `shadehound` | a man | on hands and feet, elbows and knees too high, arched spine, the head low on a long neck, the jaw unhinged; bounds with all four off the ground in frame 2 |
| `sootCrow` | cloak scraps | a rag tail, a skull face, one eye; perched it is a small hunched hood |
| `ashBrute` | a night watchman | a hump under a patched cloak, a small skull head sunk in the shoulders, one trunk of an arm on its fist, his pole across the hump with the dead lantern swinging over his head |
| `gloomweaver` | a lantern bearer | a narrow robe bent forward, no feet, torn strips trailing, a limp hood, two weeping eyes, thin arms holding out a dead lantern that drips violet |
| `ashGiant` | no one knows | bent double under a sail of a torn cloak, stilt legs, hands on the ground, a hooded skull lower than the shoulders, an ember heart in a cage of ribs |
| `lightlessKing` | (the mystery; not told) | the frame's full 64 px: mantle, train, shoulder cape, a cowl with a void ringed by a cold crescent, a thorn crown, two dead lanterns at the belt, a snuffer pole taller than himself |

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
- **Lightless King**: the sprite fills all 64 px in height (the crown reaches the top row). Anything placed over his
  head (health bar, aura centre) needs 2 px more. His aura centre fits the cowl: 4 px left of the anchor, 52 px up.
- **Ash Giant**: the stomp lands in frame 5 (the foot 12 px ahead of the walk contact, the body 5 px down): the
  screen shake and the damage belong on frame 5. The heart (5 px right of the anchor, 68 px up, radius 7) is the
  place for a light of ember colour, radius about 20 px, brightest on frame 5; today it has none.
- **Ash Brute**: the slam lands in frame 5 (fist at 17 px right of the anchor on the ground).
- **Sootling and hound attacks** land on frame 5.
- **Particles** (not drawn in the sprites): a little soot rising from brute, giant and King would complete "smoke
  figures"; one dark pixel a few times a second from the top contour, drifting left.
- **The darkness bank** (11.5) loads without Swift changes; its eyes need one new sprite id.

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
  the cleft on the far plane. Reason: 12.1, front-night.

### 12.4 What the renderer could add (for the engine port; none of it is art)

| Effect | What it gives | Roughly how |
|---|---|---|
| Light shafts through the cleft | the one warm gesture of dawn and dusk: the low sun falls through the slot into the shadow land (dawn) or the valley (dusk) | two or three additive quads, a soft wedge texture 64x128, anchored at the cleft's top on the far plane, alpha by `sun` low-angle weight, slow 0.05 Hz breathing; off at night |
| Bloom on fire | braziers and the beacon glow into the fog instead of sitting on it | downsample the emissive buffer to quarter size, blur 2 passes, add at 0.35; cap so sprites keep their pixels (bloom only outside the emitter's own mask) |
| Wind in the trees | the forest lives, the firs bend before a wave comes | near-plane and fg sprites drawn in two or three horizontal slices, the upper slices offset by `round(sin(t*0.7 + x*0.02)) ` px (0, 1 or 2 px, whole pixels only); gusts raise the amplitude for 2 s when the Gloom's bank moves |
| Layered drifting fog | depth and dread: the banks move against each other | the three fog planes already exist; give each its own drift (fogM −2 px/s, fogA −5 px/s, fogB −9 px/s, toward the castle at night, still at noon) and a second copy of fogA at half alpha moving the other way |
| Fog that swallows figures | creatures come out of the fog instead of walking in from the edge | alpha of an enemy = clamp((x − bankEdge) / 60) inside the open land, drawn before fogA while under 0.6 |
| Far-castle windows and beacon | the view back tells the state of the house | `weltmauerGlow` strip as an emissive on the far plane at night; one more 3x4 px emissive at the far castle's keep top once the Great Beacon burns, with bloom |
| Cloud deck drift | the peaks stand above weather | the cloud band over the castle on its own plane (0.12) at 1 px/s, wrapping |
| Ground mist kicked by feet | cheap life in the lane | 4 px puffs of the fog colour at each footfall in the moor, 0.4 s, alpha 0.3 |
| Embers and ash | fire has weight; the Gloom sheds | `d2Sparks` rising from braziers (already in the mock), cold ash motes drifting from the bank's edge |
| Reduce Motion | accessibility | no drift, no wind, no shafts breathing; fades stay |
