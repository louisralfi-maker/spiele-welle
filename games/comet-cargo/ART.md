# Comet Cargo: art (version 0.3, repainted after the 0.3 review)

Painted with Recraft through `bash tools/recraft.sh` (API, model `recraftv4_1`, 35 credits per image). No custom style:
each prompt carries the look itself (mid-century space-age poster, flat gouache shapes, light paper grain, the DESIGN.md
palette hex values, "no text, no logo"). Raw downloads stay in `build/recraft/cc/` (git-ignored).

Note for this Mac: python's `urllib` in `recraft.sh` fails the TLS check (no local CA bundle) and loses the picture after
the credits are spent. Run it as `SSL_CERT_FILE=/etc/ssl/cert.pem bash tools/recraft.sh ...`.

## Credits

2036 before, 1721 after: 315 spent. 70 of them were lost on the first icon call (the TLS failure above: generated and
paid, never downloaded). Pictures used: 7 generations (icon 2 candidates, clouds sheet, satellites sheet, planet,
landscape, paper). No `rmbg` was needed: every sheet was painted on a flat background and keyed locally.

Review polish: 1721 before, 1511 after: 210 spent on three calls of two candidates each (clouds `clouds-b`, planet
surface `surface-a`, icon `icon-b`). Raw files in `build/recraft/cc/v2/`.

## Assets

| File | Pixels | Where it is drawn | Drawn size (pt) |
|---|---|---|---|
| `Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png` | 1024 x 1024, RGB, no alpha | app icon | system |
| `Resources/Art/cloud-1` … `cloud-6.heic` | 1 stratus 502 x 83, 2 two-puff 273 x 154, 3 lenticular 477 x 148, 4 tower 402 x 300, 5 wide cumulus 466 x 201, 6 three puffs 393 x 88; alpha; each at the sheet's full resolution | flight sky, 3 to 15 km (`FlightScene.drawPaintedCloud`), replacing the procedural clouds; per-shape width factor 1.3 / 0.7 / 1.15 / 0.85 / 1.15 / 1.0, height 85…115 % by index, every second round of six mirrored | 1.25 x the procedural width x the factor: 55…190 wide (the stratus at most 570 px at 3x from 502 px, soft by nature; the rest at or under 1.1x) |
| `Resources/Art/launchsite.heic` | 1320 x 275, alpha (re-exported from the 1536 px keyed strip) | behind the pad on the ground line, fixed to the ground, fades out over 0 to 8 km (`FlightScene.drawLaunchSite`), 92 % opacity | screen width x about 84 (402 pt screen = 1206 px; 1320 px covers the 440 pt Pro Max) |
| `Resources/Art/planet-surface.heic` | 1024 x 1024, RGB, opaque, seamless | the flight horizon disc from about 6 km up (`FlightScene.drawPlanetSurface`): tiled at 341 pt x zoom 1.5 → 0.6 by altitude, squashed vertically to 0.32 … 0.62, 85 % opacity, drifting 5 pt/s (still under Reduce Motion), under a navy veil and a pale limb haze; replaces the dashed cream bands (kept as the fallback) | tile 512 … 205 pt wide |
| `Resources/Art/planet.heic` | 240 x 240, alpha | centre of the hangar ring network (`NetworkDrawing.drawPaintedPlanet`); the disc is 92.6 % of the square, the rest is the soft rim | disc radius 0.21 x the network radius (about 25…30), picture about 54…65 |
| `Resources/Art/satellite-1` … `satellite-3.heic` | 120 x 76…79, alpha | satellites on the ring lines (one design per ring, `ring % 3`), released satellites popping out, gliding and lost (`FlightScene.drawSatellite`) | 1.36 x the procedural size: 24.5 wide on the lines, 35 while popping out |
| `Resources/Art/paper.heic` | 512 x 512, grey, opaque | tiled over the whole sky in overlay mode at 0.6 opacity, fixed to the screen (`FlightScene.drawPaperGrain`) | 256 pt tiles |

All files are plain HEIC (`sips -s format heic -s formatOptions 85`); alpha checked after conversion with a round trip back
to PNG (corners 0, bodies 255). `UI/ArtAsset.swift` decodes each file once (`kCGImageSourceShouldCacheImmediately`),
remembers missing files, and hands out `Image(decorative:scale:)` values of the cached CGImage, so nothing is decoded per
frame. Every painted piece has its procedural fallback when its file is missing.

Kept procedural on purpose: the rocket, rings, HUD, stars, the curved horizon's geometry in flight (the painted planet
blown up to the horizon's huge radius would be soft and its bands would look wrong; the disc is filled with the seamless
`planet-surface` tile instead, which stays sharp at any radius), the hangar's delivered-satellite dots (6 pt, too small
for a picture), and the screen-wide dot grain `PaperGrain` (owned by the HUD side). The release button and the results
rows now draw the painted satellite 1 (`SatelliteIcon`, procedural fallback). Every painting is decoded once at launch in
the background (`ArtAsset.prewarm`), so none decodes inside a flight frame.

Reduce Motion: the art adds no motion. Clouds drift sideways only without Reduce Motion (as before) and otherwise move
only with the camera; the landscape is fixed to the ground; the paper is fixed to the screen; the satellites use the
existing motion (the unfold becomes the picture widening from 35 % to full width).

## Pipeline (scratchpad tools, pure python, no PIL)

- `key.py project` (clouds on flat teal): alpha by projection onto the cream-minus-teal direction, background unmixed from
  the soft edge, pieces cut by alpha projection gaps.
- `key.py flood` (satellites on cream, planet on navy, landscape on cream): background = pixels joined to the border
  within a colour distance (soft edge between `lo` and `hi`), so light paint inside an outline stays opaque.
- Planet: square crop centred on the disc (centre 515,508, disc radius about 398 of 1024), 860 px, then 240 px.
- Landscape: rows 378 to 697 of the 1536 x 768 picture (the dark ground band below is cut, the game's ground covers the
  seam), then 1320 px wide (880 px before the review).
- Clouds (`cloudcut.py`, review): the 1536 x 768 sheet keyed by projection on cream minus teal (`(t - 0.06) / 0.72`, so
  the beige shading stays opaque), the background unmixed from the soft edge, each cloud cut by a fixed box and trimmed
  to its alpha (the rows of the sheet overlap, so the projection cutter would have merged them), kept at full size.
- Planet surface (`surface.py`, review): the 1024 px tile made seamless with the offset crossfade (the picture wrapped in
  x but not in y), toned toward the palette (saturation x 0.7, a little warmer: +14 red, -4 green, -6 blue).
- Paper: 512 px crop, luminance only, made seamless with an offset crossfade, contrast normalised to grey 128 ± 14,
  clamped to 72…184 so the specks stay soft.
- Resizing with sips one picture at a time; CPU stayed at 29 to 41 °C.

## Prompts

- Icon (`icon-a`, 1:1, n 2): "Mid-century space-age travel poster painting for a square app icon. One big rounded retro
  cargo rocket, cream body with a coral red nose cone, coral fins and one round porthole, flying diagonally up to the upper
  right, filling most of the square. Beside the rocket a small mustard yellow satellite with two teal solar panels pops out
  of the rocket's side onto a wide glowing mustard yellow orbit ring that arcs across the whole picture. Background: a
  smooth poster sky from teal at the bottom to deep navy at the top with a few soft cream stars, a curved teal planet edge
  at the bottom. Bold simple rounded shapes, flat gouache colours with soft shading and a light paper grain, palette cream
  F4E9D8, teal 2E6E73, navy 14213D, coral EE6C4D, mustard F2B544. No text, no letters, no numbers, no logo, no flag, no
  border, no frame."
- Clouds, review (`clouds-b`, 2:1, n 2, used: `clouds-b-2`): "A sprite sheet of 6 clearly different retro poster clouds,
  3 columns and 2 rows, wide empty gaps between them, on a completely flat solid deep teal 2E6E73 background, no gradient.
  1: a long thin flat stratus streak, six times wider than tall. 2: a tall towering cumulus, taller than wide, flat base.
  3: a small round two-puff cloud. 4: a wide five-bump cumulus, biggest bump on the left. 5: a smooth lens-shaped
  lenticular cloud. 6: three small separate puffs on one base line. Creamy off-white FFF8EC with a soft cream F4E9D8
  underside, flat gouache, no outlines, light paper grain, mid-century space-age travel poster. No text, no sun, no
  birds."
- Planet surface, review (`surface-a`, 1:1, n 2, used: `surface-a-1`): "Seamless tileable square texture of a retro
  planet surface seen from orbit, flat gouache mid-century space-age travel poster style: teal 7FB7B2 and deep teal 2E6E73
  oceans, soft cream F4E9D8 swirling cloud bands running horizontally, a few small mustard F2B544 islands, light paper
  grain, evenly lit, no horizon, no curvature, no shadows, no text."
- Icon, review (`icon-b`, 1:1, n 2, used: `icon-b-2`): the `icon-a` prompt with "a mustard yellow satellite with two teal
  solar panels, clearly visible, about a fifth of the icon width", "a smooth poster sky from muted teal 2E6E73 at the
  bottom to deep navy 14213D at the top", "a curved muted teal 7FB7B2 and 2E6E73 planet edge at the bottom, no bright
  cyan, no saturated blue" and "full bleed to the edges".
- Clouds, first sheet (`clouds-a`, 4:3, replaced in the review): "A sprite sheet of exactly 6 separate retro poster clouds arranged in a neat grid of 3 columns
  and 2 rows with wide empty gaps between them, on a completely flat plain solid deep teal background, colour 2E6E73, no
  gradient. Each cloud is a wide, low, puffy cumulus with a flat bottom and three or four soft rounded bumps on top, creamy
  off-white FFF8EC with a soft warm cream shadow F4E9D8 along the bottom edge, in the style of a mid-century space-age
  travel poster: flat gouache shapes, soft clean edges, a light paper grain, no outlines. Every cloud has a different
  silhouette, all about the same size, each about twice as wide as tall. Nothing else in the picture: no text, no birds,
  no sun, no stars." (The model painted 3 rows of 2; all six used.)
- Satellites (`sats-a`, 4:3): "A sprite sheet of exactly 6 separate small retro satellites arranged in a neat grid of 3
  columns and 2 rows with wide empty gaps between them, on a completely flat plain solid pale cream background, colour
  F4E9D8, no gradient, no shadows on the background. Each satellite is seen straight from the front, symmetric and
  compact, with a bold simple silhouette that reads at a tiny size: a rounded mustard yellow F2B544 body (a ball, a drum
  or a box), two flat deep teal 2E6E73 solar panel wings on short arms left and right, a thin antenna with a small coral
  EE6C4D tip on top. Mid-century space-age travel poster style: flat gouache shapes with soft shading, a thin dark navy
  outline, light paper grain. Every satellite a slightly different design, all the same size. Nothing else: no text, no
  stars, no planet, no rocket."
- Planet (`planet-a`, 1:1): "A single round retro planet, centred, filling about 80 percent of the square, on a completely
  flat plain solid deep navy background, colour 14213D, no gradient. The planet: teal 7FB7B2 and deep teal 2E6E73 oceans,
  soft cream F4E9D8 swirling cloud bands, a few small mustard F2B544 continents, soft shading with light from the upper
  left and a darker teal night side at the lower right, a thin soft pale teal atmosphere glow at its rim. Mid-century
  space-age travel poster style: flat gouache shapes, soft clean edges, a light paper grain, no outline. No rings around
  the planet, no moons, no stars, no text."
- Landscape (`land-a`, 2:1): "A wide, low painted landscape strip along the bottom 30 percent of the picture; the upper 70
  percent is a completely flat plain solid pale cream sky, colour F4E9D8, empty, no clouds, no sun, no gradient. The
  landscape: soft flat-topped desert mesas and rounded hills in three calm layers, the far ones pale teal 7FB7B2, the
  nearer ones deep teal 2E6E73, a few warm coral EE6C4D and cream accents on the slopes, and far away on the left a tiny
  distant control tower and two small round fuel tanks, very small. The very bottom is a flat band of dark teal ground
  24575B across the full width. Mid-century space-age travel poster, flat gouache shapes, soft edges, light paper grain,
  calm and simple. No rocket, no launch pad, no people, no vehicles, no text, no flag, no logo."
- Paper (`paper-a`, 1:1): "Flat scan of the blank paper of a mid-century screen-printed travel poster: an even warm cream
  paper surface filling the whole square, with very fine paper fibre grain, a faint mottled ink speckle and a subtle
  uneven print texture, evenly lit, uniform from edge to edge, no vignette. Nothing else: no objects, no shapes, no text,
  no folds, no creases, no stains, no border."

## Picked and rejected

- Icon: picked `icon-a-2` (clean white rocket, thin mustard ring, satellite upper left, navy and cyan sky). Rejected
  `icon-a-1`: rough brushwork, pink instead of coral, the satellite small and dark, muddy at 60 px. Both candidates paint a
  rounded-square frame with grey corners; the grey stays within about 50 px of each corner, inside the area iOS masks
  (corner radius about 229 px at 1024), so nothing shows. The blue is a little more saturated than the game's navy.
- Satellites: picked sheet cells 2 (drum with rims), 3 (capsule with a belt), 4 (ball with a porthole). Rejected cell 1
  (ball with an odd arch hatch), 5 and 6 (plain boxes, too close to 2 and 3). The watercolour fill leaves thin paper-white
  gaps inside the outlines; kept, they read as highlights on dark sky.
- Clouds (review): replaced. The first sheet's six clouds were close cousins of one three-bump template and read as
  stamped copies in the game. Picked `clouds-b-2` (all six clearly different, clean edges, warm beige shading that keys
  opaque). Rejected `clouds-b-1`: its tower and wide cumulus grew into one shape, and its cool blue-grey shading sat
  less well on the cream sky.
- Planet surface (review): picked `surface-a-1` (horizontal cloud bands, deep and light seas, small mustard islands: reads
  as a planet from orbit). Rejected `surface-a-2`: only wavy water stripes, no islands, read as a sea, not a planet.
- Icon (review): picked `icon-b-2` (bold glowing mustard ring around the rocket, the satellite bigger and clear at 60 px,
  navy to teal-blue sky, about #087697 at mid height: darker than the old cyan #1FA6B8, still a little bluer than the
  palette's #2E6E73; the planet edge is a light teal-blue). Full bleed: the edges carry the painting, no frame. Rejected `icon-b-1`: pink fins and
  nose, a pale planet, the ring thin. Only the outermost corner pixels of `icon-b-2` are dark, inside the area iOS masks.
- Planet, landscape, paper: first picture used. The landscape is right-heavy (the tallest mesas on the right); its coral
  slopes sit low behind the flame and smoke, checked on a mock over the 0.2 liftoff screenshot.
- Planet as the flight horizon: not used (see "Kept procedural").
