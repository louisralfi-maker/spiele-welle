# Lanternhold: the art director's review of look 2 (14.11.2026)

Material: TestFlight build 86, round `tf-lh-1` (ALL PASSED), 30 screenshots made upright from
`ci-out/tf-lh-1/03-ui` and `04-ui-de`, and Fable's stage-8 previews in `ci-out/hall`. The yardstick is the craft of
Kingdom Two Crowns, Yes, Your Grace, Alto's Odyssey, Ori and Children of Morta, never their look (DESIGN.md "Not a
copy"). Screenshot names below drop the `-en.png` ending; `de` marks a German capture.

## 1. Verdict

1. The single sprites are good (the gatehouse, the valley at dusk, the lord, the parchment interface). The world they make up is not.
2. Louis is right. The strip runs gorge, cut-away hall, village church, kitchen and a second castle. The keep is painted four times (`keepTop`, `backTop`, `farCastle`, `farCastleBack`), so the castle never reads as one building.
3. Depth is faked with flat panels. Rock slabs stand on the walk line, the mid planes end in hard vertical seams, and fog has square edges. Each one breaks the illusion.
4. Inside the walls you see open sky and a low rock band, so the castle does not sit in a cleft. The Weltmauer is barely taller than the keep, so it reads as a backdrop, not as a wall of Everests.
5. The fix is a rebuild of the composition, not a repaint: one castle, exteriors only, the hall as its own stage, touch the world, and seamless edges. Most of the art can stay.

## 2. The world plan

All x are world game px (`WorldLayout`). The view is 437 x 180 on the runner's iPhone 17 Pro (s = 6). The
simulation's positions stay as they are (spawn 40, beacon 470, lines 640, 940 and 1300, barracks 1480, smithy 1550,
lodge 1640, town plots, river), so the tuning (T1 to T8) still holds. Only the castle's art, the rooms and the
backdrops change.

### 2.1 The places along the strip

| x | Place | What the player sees |
|---|---|---|
| 0 to 260 | The darkness bank | A soft wall of black-blue fog on three planes with eye glints; the spawn is at 40. The camera clamps at 0, so the screen's left edge always lies inside the fog. The world ends in darkness, not at a wall. |
| 260 to 470 | The dead moor | Shadow land: dead firs on the near plane, the shadow forest on the mid plane, mist, the oldest ruins. The Weltmauer on the far plane sinks into the fog toward the left. |
| 470 | The beacon crag | The ruined Great Beacon on a low crag: the only tall shape in the shadow land and the chapter's goal. |
| 470 to 1240 | The Throat | The outer line at 640, the middle line at 940, the old walls' ruins. The cleft's far wall (mid plane) climbs in three steps from 720 to 1240, each step darker and taller, until it fills the sky behind the gatehouse. Nothing stands across the walk line. |
| 1240 to 1480 | The front gate | The gatehouse (line 1, its wall at 1300) between its two round towers. The towers' outer flanks melt into the cleft rock on the mid plane: masonry growing out of granite, with no slab before them. |
| 1480 to 1700 | The outer bailey | The barracks (1480), the smithy (1550) and the builders' lodge (1640), as lean-tos against the curtain wall in the castle's granite and slate. No half-timbering here: that belongs to the town. |
| 1700 to 1960 | The keep's forebuilding | A stone stair and porch with the hall door at **1830** (the `touch-door-hall` target), two torches and a guard. The keep rises behind it (see 2.4). |
| 1960 to 2120 | The chapel of the Flame | A closed tower in the curtain wall: three lancet windows lit from inside, the Flame's brazier at its door. The story keeps "the chapel" (34 strings in `Story.xcstrings` name it). It is now castle masonry, not a village church with a blue roof. |
| 2120 to 2230 | The kitchen | A bakehouse lean-to against the curtain: a chimney with smoke and the oven's glow through a hatch. Tamsin stands at its door. |
| 2230 to 2430 | The back gate | A postern: one squat tower and a gate passage at 2330, lower and plainer than the front. It is the castle's back, not a second facade. Lanterns and flower boxes make it friendly. |
| 2430 to 3680 | The town | The plots as today, plus a back row of roofs (2.3). |
| 3680 to 3900 | The river | As today: the stumps of the old bridge, reeds, and the far shore beyond. |

A **curtain wall** about 64 px high, with a wall walk and crenellations, runs on the world plane at z −5 from 1480 to
2230, behind every castle building. It ties them into one fortress. Its foot is the bailey's cobble lane.

### 2.2 Sprites: stay, go, paint

**Stay** (already at the bar or close to it):

- `castleFront` and its tier sprites: the gatehouse is the best building in the game.
- The valley vista, the clouds, the dusk skies.
- The town's houses, market and tavern, and the trees.
- The lane tiles.
- The lord, the court and the townsfolk.
- The old walls `oldWall1` to `oldWall3`.
- `shadowForest`.
- The warden statue (fix its bowl, punch list M5).
- `weltmauer`, but only over the shadow land and the Throat.
- The stage-8 hall: `greatHall`, `hallPillarNear`, `hallFire`, and the six tap marks.

**Go:**

- The far castle in every form: `farCastlePane`, `farCastleGlow`, `farCleftGlow`, `farCleftGlowBack`, `weltmauerPatch`, `farCastle2/3`, `farCastleBack2/3`, their `Build` and `Glow` variants, and look 1's `keepFar`.
- The extra keep copies: `keepTop*` over the gatehouse and `backTop*` behind the back gate.
- The cut-aways in the world: `hallInterior` and the hall front, the chapel front and interior, the kitchen front and interior. Remove the `CastleRooms` wall fades with them.
- `backGate` as a full two-tower facade.
- The world-plane slabs on the walk line: `cleftFlank`, `cleftFlankB`, `cleftThroat`.
- The near-plane `gorgeCrags` and the mid-plane `gorgeRock` at the Throat's mouth: they make the wall the lord walks into.

**Paint** (new, in look 2's palette; one piece at a time through review):

| id (proposal) | size | plane | what |
|---|---|---|---|
| `keepT1`, `keepT2`, `keepT3`, `keepT2Build`, `keepT3Build` | 200 x 175 | mistBand | The one keep. Its foot fades into mist. Lit windows go on a glow mask. |
| `curtainA…C`, `curtainStair`, `curtainTower` | 64 x 72 | world | The curtain wall in 3 variants, the stair to the wall walk, and a wall tower. |
| `forebuilding` | 120 x 92 | world | The porch, the stair and the hall door, in 2 frames: closed and open. |
| `chapelTower` | 110 x 130 | world | The chapel of the Flame as part of the wall. |
| `bakehouse` | 100 x 60 | world | The kitchen lean-to with its oven hatch. |
| `posternT1…T3` | 150 x 110 | world | The back gate per tier. |
| `cleftWallA…C` | 256 x 200 | mid | The cleft's far wall at full height: dark granite, a jagged slit of sky in its top 20 rows, thin threads of water, a cold shaft of light. |
| `throatStepA…C` | about 220 x 120 to 190 | mid | The Throat's far wall, in three steps that fall to the west and grow paler with distance. |
| `gateArchFg` | 64 x 180 | foreground | The gate passage's dark arch, drawn in front of the lord while he passes through either gate. |
| `bankSheetA…C` | 256 x 180 | fogA, world, fogB | The darkness bank. Its edges feather into 48 px of dithered gradient. No sheet may end in a straight line. |
| `beaconRuin` (repaint) | as today | world | Moonlight rim, inner values, the cold bowl. |
| `townRoofsA…D` | 120 x 60 | near | A back row of roofs, a few chimneys and one spire, at 70 % value. |

### 2.3 The parallax planes

The engine keeps its ten planes and their factors (`Plane.parallax`). Only what lies on them changes.

| # | plane | factor | shadow land and Throat | castle (1240 to 2430) | valley |
|---|---|---|---|---|---|
| 1 | sky | 0 | gradient, moon, stars | only in the slit of sky | gradient, sun |
| 2 | clouds | 0.05 | high bands | none | high bands |
| 3 | far | 0.2 | `weltmauer`, which sinks into the fog toward 0; a cloud deck across it at half height, with the peaks cut by the top of the screen | hidden by the cleft wall | valley vista |
| 4 | mid | 0.5 | `shadowForest`, then `throatStep` A, B and C from 720 | `cleftWall`, full height | hills, windmill |
| 5 | mistBand | 0.62 | mist | **the keep** with mist at its foot | mist |
| 6 | near | 0.75 | dead firs west of 470 | none | trees, `townRoofs` behind the plots |
| 7 | fogA | 0.9 | bank sheets, night fog | thin night mist | morning mist |
| 8 | world | 1.0 | lines, ruins, the beacon | the gatehouse, curtain, buildings, postern | houses, plots |
| 9 | fogB | 1.15 | bank sheets, ground wisps | ground wisps | none |
| 10 | foreground | 1.3 | ferns, dead stems | `gateArchFg` only while passing | meadow, reeds |

Rules:

- Every backdrop piece ends behind something else or fades out in a feathered edge. Nothing ends in a straight vertical line on screen.
- A set border sits behind a gate's masonry (as `WorldLayout.border` already intends).
- Values step down toward the back: the world plane holds the strongest contrast, and each plane further back gets paler and cooler.

### 2.4 The castle as one building, growing by tiers

The keep is the castle's spine, and there is exactly one of it. It stands on the **mistBand plane (0.62)**, behind the
curtain wall, and is centred over the hall door when the camera is centred there:

`plane x (left edge) = view/2 + 0.62 × (1830 − view/2) − 100` (= 1118 for the 437-column view).

The parallax alone makes it behave like a real tower inside the walls. It enters at the right edge as the lord walks
through the front gate (camera centre about 1320). It stands centred over the forebuilding at 1830. It leaves at the
left edge as he walks out of the back gate (camera centre about 2340). From the Throat it is hidden and from the town
it is gone, so no copy is ever needed. Mist at its foot hides where it meets the ground.

| tier | gatehouse (`CastleGrowth`) | keep (top above the ground line) | curtain | postern |
|---|---|---|---|---|
| 1 | the gate | 3 storeys, plain hip roof, top at y 120; two lit windows at night | plain crenels | one low tower, top 80 |
| 2 | the iron gate (portcullis, machicolations) | +1 storey, the house banner, top at y 140 | hoardings and two wall braziers | its tower gains a roof and a lantern |
| 3 | the great gate (barbican, corner turrets) | a crowned top with four turrets, the great banner to y 165 | a second wall tower, banners | the tower crowned, a flag |

- While the builders work, the next tier stands under scaffolding (the existing `Build` idea), on the keep as well as the gate.
- Each tier must change the silhouette, not only the details. It has to read at phone size from the front gate's framing: the keep's corner shows at the right edge there (punch list H3).
- Keep every top at or below y 150 except the banner: the realm strip lies over rows 10 to 28 (punch list H5).

### 2.5 How the Throat ends

- **West end (the shadow land):** from 720 westward the cleft's far wall steps down three times and pales into the mist band. From 470 there is no rock wall at all, only the moor, dead firs and ruins.
  - The darkness bank at 0 to 260 is three planes of feathered fog sheets with eye glints, its value falling to `night0` at the screen's left edge.
  - The bank moves at night (DESIGN.md "Polish after round 2"), and the sheets move with it as one soft volume.
  - The Weltmauer on the far plane disappears into the bank: the world ends in shadow.
- **No castle behind it.** The shadow land shows the Weltmauer and fog only. The castle is behind the player's back, to the right, never in the background.
- **East end (at the castle):** no slab stands on the walk line. The cleft wall behind rises out of the screen's top. The gatehouse's flanks grow into it, with the masonry painted onto rock at the towers' outer edges in the gatehouse sprite.

### 2.6 The hall as its own scene

- **In:** tap the hall door at 1830 (or walk into it).
  - The lord walks to it and the door opens (2 frames, a creak).
  - The screen goes through dark in 0.35 s (Reduce Motion: a cut). He stands inside at hall x 68, and the door closes behind him.
  - The clock keeps running in the hall and stops only for the audience (as today).
- **Out:** tap the inner door, or walk past hall x 40. The same fade plays in reverse, and he stands at 1830 facing right.
  - At the horn the hall's petitioners leave and a slip at the door says "The horn". The lord stays where he is: the player decides.
- **The realm strip** shows a hall marker on the castle. A tap on any point outside sends the lord out through the door and on to that point.
- **The stage-8 art** is the hall: SPRITES.md "The great hall as a stage" holds the places, anchors and layers.
  - Light is the realm's state there: the hearth pool follows the hearth's strength, and the bench candles burn while someone waits.
- **The windows** must show the night sky and the `weltmauer` on a plane at 0.3. By day they need light shafts: soft diagonal beams that fall on the nave floor (punch list H10).

### 2.7 The camera

The scale stays an integer per device (`PixelScale`). There is no fractional zoom in the world.

| place | framing |
|---|---|
| default (walking) | follow as today, plus 32 px of lead in the walking direction, eased in over 0.5 s once he walks |
| beacon 470, front gate 1360, hall door 1830, back gate 2330 | **set pieces:** within ±70 px of the anchor, the camera's goal is `anchor + (lord − anchor) × 0.3`, so the building stands centred and composed while the lord moves within it |
| front at night, creatures on screen | lead 60 px to the left, toward the danger |
| river end | clamp, as today |
| hall, walking | one scale step above the world's (s 7 on the 17 Pro: 375 x 172, anchored at the bottom; only the roof's top 29 rows fall away). The lord stands 70 pt tall instead of 60. Camera x from 0 to 225. |
| hall, audience | s 8, left edge at hall x 232, top at row 50 (SPRITES.md). The move takes 0.6 s, eased (Reduce Motion: a cut). |

Reduce Motion: the set-piece easing and the lead become instant (no spring), as the follow already does.

### 2.8 The transitions

1. **Moor to Throat:** the cleft's far wall rises step by step behind the lines, and the air grows colder.
2. **Through the front gate (1337 to 1383):**
   - `gateArchFg` frames the lord for the passage's 46 px.
   - Inside, warm torchlight on cobbles replaces the cold scree light.
   - The wind ambience ducks under the bailey's sounds.
3. **Bailey to hall:** as 2.6.
4. **Through the back gate (2330):**
   - The cleft wall ends behind the postern tower's silhouette, and the valley set begins behind the same masonry (`WorldLayout.border`).
   - The ambient ramp turns warm over 2330 to 2530: the reveal of the valley.
   - The lane changes from cobble to packed earth under the gate, never in the open.
5. **Town to river:** meadow, reeds, the bank (as today).
6. **Stage changes** (world and hall) never cut the sound: the fire and the wind cross-fade.

## 3. The punch list

Lanes: **world**, **hall scene**, **controls**, **interface**, **sound**, **story**. The screenshots are in
`ci-out/tf-lh-1/03-ui` (English) and `04-ui-de` (German), and the previews in `ci-out/hall`.

### Blocker

| # | screenshot | what is wrong, and why it misses the bar | exact fix | lane |
|---|---|---|---|---|
| B1 | `79-look2-hall-court`, `118-polish-circlet-button`, `56-chapel-open`, `57-kitchen-open`, `91-lord-entry` | The castle is a row of open doll's-house rooms (the hall a low box at 60 % of the screen's height), next to closed exteriors. The games on the bar never mix cut-aways and facades in one strip: it breaks the space and makes the "castle" a set of shelves. | Exteriors only (2.1, 2.2). Hall as a stage (2.6). Chapel and kitchen become closed castle buildings. Remove the `CastleRooms` front-wall fades. | world |
| B2 | `70-look2-shadow-night`, `84-look2-tier3-far` (far castle in the cleft seen from the shadow land); `74-look2-town-dusk`, `75-look2-town-noon`, `113-polish-square-dusk` (a pale castle in a hard-edged rectangle above the town); `57-kitchen-open`, `83-look2-tier3b-back` (the back gate as a second full castle) | The castle exists four times: gatehouse, far castle, far back castle, back-gate facade (plus the `keepTop` copy). The player cannot build a mental map. The far views are also spatially wrong: the castle is beside the player, not behind him. | One castle (2.4). Delete every far-castle sprite and emitter. The keep on mistBand is the only keep. The back gate becomes a low postern. | world |
| B3 | `79`, `118`, `56`, `57`, `55-talk`, `105-polish-ruins-dusk` | The 88 pt red seal at the bottom right, with its caption slip ("Audience (4)", "Tamsin", "Build: Trap"). Louis calls it cringe. It is the biggest, reddest thing on screen, it covers the world's right quarter, and it makes the world a menu. | DESIGN.md "Controls 2: touch the world", built as written: the marks, the slip above the thing, the priority rules, the 44 pt areas, the accessibility elements and the identifiers. Delete `action-button`. | controls |
| B4 | `70-look2-shadow-night` (fog cut at x≈540 of the screen), `85-look2-storm-night` (fog bank starts in a vertical line at x≈870), `40-hud` (fog ends at x≈290), `84-look2-tier3-far` (a dithered vertical column at x≈440 to 500) | Fog and the darkness bank end in straight vertical lines. Fog is the world's signature, and a square fog edge reads as a rendering bug at a glance. | Every fog sprite and bank sheet gets a 48 px feathered, dithered edge on all four sides (`bankSheet`). Repeat sheets overlap by at least 64 px. Add a unit test in `FrameBuilderTests` that no fog instance's edge column falls inside the view without a neighbour or a feather. | world |
| B5 | `79-look2-hall-court`, `80-look2-audience` (en and de), `118-polish-circlet-button` | At the hall's framing the top left shows a flat beige rectangle with dead branches. It ends in a hard vertical seam at about game x 87: a gorge-set mid piece seen from the castle. It sits on the most-seen screen of the game. | The castle zone shows `cleftWall` on mid, full height. Gorge-set pieces end west of the castle view or behind the gatehouse. Check every set border from camera centre 1200 to 2500 in 20 px steps in a runner screenshot sweep. | world |
| B6 | `70-look2-shadow-night`, `85-look2-storm-night`, `77-look2-throat-dawn`, `40-hud`, `105-polish-ruins-dusk` | The Throat is closed at both ends by walls facing the camera. In the west, `gorgeRock` and `gorgeCrags` form a cliff across the view. In the east, `cleftFlank`, `cleftFlankB` and `cleftThroat` stand as tan or black slabs on the walk line, and the lord passes in front of a flat card (`40-hud`, x 570 to 690). Louis: "dass man an die Schlucht-Mauer-Verblockung läuft". | 2.5: the Throat's wall steps down to the west into mist, and nothing stands on the walk line. The gatehouse grows into the rock behind it. | world |

### High

| # | screenshot | what is wrong | exact fix | lane |
|---|---|---|---|---|
| H1 | `56-chapel-open`, `57-kitchen-open`, `79-look2-hall-court`, `55-talk` | Inside the walls you see open sky, white clouds and the far Weltmauer above a low rock band whose top runs nearly straight. The castle stands in a valley, not wedged into a cleft wall to wall. | `cleftWall` on mid, full height, with only a slit of sky; a cold shaft of light by day and the moon's sliver at night. | world |
| H2 | `72-look2-castle-dusk`, `82-look2-tier3-gate` | The gatehouse stands free in front of dark trees and forest. Nothing holds it in the cleft, so it looks like a castle in a wood. | The flanks melt into the cleft rock (2.5). The mid plane behind it is `throatStepC`/`cleftWall`, not forest. Moonlight rims the rock edges. | world |
| H3 | `72-look2-castle-dusk` against `82-look2-tier3-gate` | Tier 1 and tier 3 are nearly the same picture from the gate. Growth is the reward for the money, and it is invisible. | 2.4: each tier changes the silhouette (keep storeys, turrets, banner, barbican), and the keep's corner shows at the right edge in the front gate's framing. Add a runner shot per tier at the front gate, at the hall door and at the back gate. | world |
| H4 | `80-look2-audience`, `80-look2-audience-de`, `52-petition-de` | The audience card covers the middle 45 % of the screen, the hall included. The petitioner, the lord and the hearth vanish while the decision is made, so the decision has no stage. | The hall stage's audience framing (s 8) plus the stage-8 card layout from preview `06`: the letter in the upper left, the choices as plaques along the floor band. It must never cover the throne, the petitioner or the hearth. Test the longest German request in it (about 300 characters at 364 pt width). | hall scene, interface |
| H5 | every world shot, e.g. `82-look2-tier3-gate`, `83-look2-tier3b-back` | The realm strip (470 pt wide, 44 pt high) sits over the castle's crowns. Its markers are white rectangles that do not say "tower", "keep" or "house". | 300 pt wide, 28 pt high, a map cut in ink. Markers drawn as the map's own glyphs (line, gatehouse, keep, roofs, river). At 60 % opacity while nothing calls; full opacity with a wax-red tag when something does. Keep the world's important tops below row 28 (2.4). | interface |
| H6 | `79-look2-hall-court`, `56-chapel-open`, `118-polish-circlet-button` | The Weltmauer's peaks all fit inside the frame, at about the keep's height. A "line of Everests" that ends below the screen's top is just a backdrop painting. | The peaks are cut by the screen's top, with a cloud deck across at half height, over the shadow land and the Throat only. In the castle the cleft wall hides it, and in the valley it is not seen. | world |
| H7 | `83-look2-tier3b-back` | At the back gate the cobble lane ends in a hard vertical seam on open ground (screen x≈880), and the mid ridge stops in a straight line behind the gate (x≈340), with sky next to it. | The lane changes under the postern's passage. The cleft wall ends behind the postern tower. The valley set starts behind the same masonry (2.8, item 4). | world |
| H8 | `91-lord-entry` | There is no title screen (DESIGN.md Screens 1 is open). The first picture of the game is a card over a dim cut-away hall: no promise, no hero shot. | Build Screens 1 (`docs/UI-look.md`): the engine's own scene with the front gate at dusk (the set-piece framing), the lord's lantern, "Lanternhold" in IM Fell, and Continue or Chapter 1 as plaques. The name entry follows it as the page of the family book over the same scene. | interface |
| H9 | preview `02-hall-wide-night` | At the world's scale the 30 px people are 15 % of a 201-row hall. Walking through it, the lord is a speck under a roof. | The hall's walking framing at s 7 (2.7). The audience at s 8 as specced. | hall scene |
| H10 | previews `02-hall-wide-night`, `01-audience-old-above-new` | The windows are flat blue panes. The walls are one even grey brick from floor to roof. The light is even and the upper hall is as bright as the floor. Not yet at the bar of the genre's interiors. | Windows: the `weltmauer` and the night sky behind them at 0.3. By day, light shafts fall onto the nave floor. Fade the upper wall into the roof's dark (a vertical value ramp in the hall's ambient). Plaster and wash patches break up the brick. The hearth's warm light lies on the flags in a long pool. | hall scene |

### Medium

| # | screenshot | what is wrong | exact fix | lane |
|---|---|---|---|---|
| M1 | `77-look2-throat-dawn`, `105-polish-ruins-dusk` | Fog is built from three or four flat value bands with stepped tops, like a contour map. | 6 to 8 steps with ordered dither between them, and a soft top edge that drifts slowly (frozen under Reduce Motion). | world |
| M2 | `70-look2-shadow-night`, `85-look2-storm-night` | The beacon ruin is a flat black rectangle with a handle. It is the chapter's goal and has no form. | Repaint `beaconRuin` with a moonlight rim on its right, inner values, broken masonry and the cold bowl, so the goal reads at night. | world |
| M3 | `70-look2-shadow-night`, `77-look2-throat-dawn`, `85-look2-storm-night` | Six archers stand shoulder to shoulder on a 40 px wall, a picket fence of heads. | At most 3 archers drawn per wall walk, 10 px apart. The rest are implied by arrows. | world |
| M4 | `74-look2-town-dusk`, `75-look2-town-noon`, `113-polish-square-dusk` | The town is one row of houses on a line, with lollipop trees between them. No depth, no sense of a town. | `townRoofs` on the near plane (a back row at 70 % value with chimney smoke), one spire, and lights in the back row at night. | world |
| M5 | `77-look2-throat-dawn`, `105-polish-ruins-dusk`, `40-hud` | The warden statue's fire floats in front of its chest: there is no bowl to be seen. | Paint the bowl in the statue's hands, with the fire seated in it and a rim of firelight on the stone under it. | world |
| M6 | `40-hud`, `41-build-card` | Four identical small blue banner posts at the gate read as clutter and say nothing. | With touch the world, an open plot shows `tapBuild` only while it offers something, and the banner posts go. | controls, world |
| M7 | `41-build-card`, `41-build-card-de` | The header's "60" next to the site's name reads as a price (it is the treasury). The chevron "›" has no meaning you can guess. | Label it "Treasury 60" in the soft ink, or drop it (the ledger slip shows it). Replace the chevron with "Next site" plus a tag, or remove it. | interface |
| M8 | `91-lord-entry` | The two portraits (lord, lady) are the same face, and the choice looks unfinished. | Two distinct portraits, the lady's own (hair, jaw, circlet worn differently), at the court portraits' bar. | interface |
| M9 | `55-talk` | The talk bubble covers the speaker's building and a slip with her name sits apart, beside the button. | Bubble above the speaker's head, 300 pt at most, its tail on her. Drop the separate name slip (the bubble's head names her). | interface |
| M10 | `49-pause-en` | "Restart chapter" is a full-width button at the same weight as Resume. | Move it under a "Chapter" row as a quiet text button with its confirmation (DESIGN.md Screens 8), below the switches. | interface |
| M11 | preview `04-tap-marks-at-the-front` | At night the parchment marks are the brightest pixels on screen, brighter than the fires. They break the dark that is the game's mood. | At night the marks draw at 75 % value with a warm tint, at most 4 marks in view at once (nearest first). A townsman's mark shows only while he has a new line. | controls |
| M12 | all | Places have no sound of their own in what the screenshots show. The stage changes need it to feel like entering. | Ambience beds per zone (wind and fog in the Throat, bailey forge and voices, hall fire and room tone, valley birds and river), cross-fading over 120 px. A door creak and latch at the hall. No music, ever. | sound |
| M13 | all | Accessibility for the new controls is still to be built. | Controls 2's accessibility list as written: elements per thing, labels with the act first, "Walk left" and "Walk right" custom actions, and the order. Reduce Motion cuts the stage fade, the audience move and the set-piece easing. | controls |
| M14 | `de` set | The German text fits everywhere today (report, audience, build card, petition). The new slips and the hall letter are new places where it can break. | Test the slips' longest German lines ("Die Mauer ausbessern, 12" style) and the longest petition in the 364 pt letter, in round screenshots `<nn>-touch-hall-de` and `<nn>-touch-front-de`. | interface |

### Low

| # | screenshot | what is wrong | exact fix | lane |
|---|---|---|---|---|
| L1 | all world shots | The wax-red pause seal is the second-reddest thing on screen and competes with the fires. | An ink seal on parchment, or a darker wax. 44 pt in a 60 pt area as today. | interface |
| L2 | `70-look2-shadow-night` | Creatures at a distance read as red line smears. | A stronger ash edge and a cool rim at distance (DESIGN.md decision 09.11.). Check in a night shot at the outer line. | world |
| L3 | `75-look2-town-noon` | The 26 rows under the lane are a flat dark band in the valley. | A few stones, roots and a meadow edge in the band's top 8 rows, valley set only. | world |
| L4 | `76-look2-river-golden` | The river end works but closes with nothing. | One far-shore lantern and a moored skiff on the far bank (scenery only, no boats to use). | world |
| L5 | none | Japanese and Chinese have never been seen. | Add a ja and a zh-Hans screenshot pass of the cards and the slips. | interface |
| L6 | (story) | The chapel and the kitchen stay in the story but become exteriors. A few court lines speak of "inside" them. | Check `Resources/Court/lines.json` and `Story.xcstrings` for lines that assume a visible interior. Re-home Hesper's hall lines to the hearth (already in the stage-8 places). | story |

## 4. What already meets the bar: keep it

- **The gatehouse front** (`72-look2-castle-dusk`): mass, portcullis, warm torch pools, banners. It is the hero, and it keeps that place.
- **The valley at dusk and noon** (`74`, `75`, `113`): the cloud bands, the dithered sky, the painted vista, the warm windows with fireflies. It is store-screenshot quality as it is.
- **The light system:** warm pools against cold night, light as game state, the lantern's glow on the lord.
- **The interface's paper language** (`45-report`, `80-look2-audience`, `41-build-card`): the ledger slip HUD, the chronicle page, IM Fell with Baskerville figures, two surfaces. The dawn report is the best screen in the game. The German fits.
- **The stage-8 great hall:** the door bay, the dais under the cloth of estate, the great hearth, the near pillars. It needs light and framing (H9, H10), not a repaint.
- **The tap marks' style:** small, calm, ink on parchment, no bobbing.
- **Fog as an idea** (the bank creeping up the Throat at night). Only its edges and banding fail.
- **The old walls' ruins and the warden statue** as the Throat's memory of older lords.
- **No music.** The rule stays.

## 5. Order for the build lane

1. B4, B5 and B6 (edges and slabs): cheap, and they remove the "broken" look at once.
2. B1, B2, H1 to H3 and H7: one castle, exteriors, the cleft wall. The art and the layout move together, place by place, with a runner sweep per place.
3. B3 and M11 to M13: touch the world.
4. 2.6, H4, H9 and H10: the hall stage and the audience in it.
5. H5, H8 and the interface mediums.
6. M1 to M5, then the lows.

Every step ends with a runner round and a screenshot sweep of camera centres 0 to 3900 in 200 px steps, at noon,
dusk and night, judged against this document.
