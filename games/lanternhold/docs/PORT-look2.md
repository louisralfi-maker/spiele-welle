# Lanternhold: porting look 2 and weather into the game

Written on 09.11.2026 against `claude/lh-m3` at 8467449 (the Swift side) and `claude/lh-look2-fable` at 7d6e6d2
(the look: `ART-look2.md`, `tools/scenemock/mock.py look=2`, `core.KEYS2`, `layout_look2.py`), with `STORY.md`
section 2 for the Throat. This is a plan. No Swift is changed by it.

One rule governs the port: **the mock is the reference.** Every number below is the mock's number. Where the game
and the mock disagree after the port, the game is wrong, unless a round's notes say why.

Contents: 0 decisions, 1 changes file by file, 2 effects and their cost, 3 weather, 4 performance budget, 5 order
of work as runner rounds, 6 risks and the cut order.

## 0. What stays, and the four decisions of this plan

Stays as it is:

- One native-resolution pass (composite plus actors). Every plane is a low-resolution target read at exact texels.
- The Simulator's Apple2 subset: one colour attachment per pass, no programmable blending, no sRGB targets.
- `FrameBuilder` stays pure and deterministic. The renderer draws what a `FrameDesc` says and nothing else.
- Light gain 3.0, hot knee 0.95, glow add 0.06, bloom 0.75 with threshold 0.34 and knee 0.5, smooth pools with the
  edge band, unlit value 0.2, the glass test on night0, night1 and ink.
- Ids, sizes, frame counts, anchors and strides of every sprite that exists today.
- Every gameplay x of `WorldLayout` (spawn 40, beacon 470, lines at 1300, 940, 640, wall walk 124). The tuning
  tests T1 to T8 must pass unchanged in every round.

Decisions:

1. **A switch first, then the replacement.** `LookVersion { one, two }` in `FrameOptions`, set by `-GWLook 1|2`.
   Default 1 until the parity round (L2-6) passes, then default 2; look 1's values are deleted in the last round.
   While both exist, one build shoots both, and look 1 must stay pixel for pixel what it is (5, round L2-0).
2. **Ten planes for the fill cost of eight.** Look 2 adds the near plane (0.75) and the mist band (0.62). The three
   fog planes never leave a band of rows at the ground, so they become **strip targets** of 64 rows instead of full
   targets (1.3). Ten planes then fill fewer low-resolution pixels than eight do today.
3. **Weather is pure Core data and never touches the simulation.** `Weather.sample(seed:day:hour:)` returns a value
   type. `FrameBuilder`, `Particles` and the sound hub read it; `Simulation`, `LightField` and the tuning tests
   never do. A night plays the same in a storm as in calm air.
4. **GPU cost gets a number the runner can check.** The runner cannot measure milliseconds. So the composite gets
   a debug view that outputs the count of texture reads per native pixel, and a test bounds its mean (4.3).

## 1. The changes, file by file

Paths are under `games/lanternhold/`. "Mock:" names the function in `tools/scenemock/mock.py` that the Swift or
Metal code must match.

### 1.1 `Core/AmbientRamp.swift`: the light ramp's ten keys

- `AmbientSample` gains five fields: `air: SIMD3<Float>` (the haze colour of the hour), `vignette: Float`,
  `black: Float` (weight of the navy lift), `cloudColor: SIMD3<Float>` (sun side of the clouds) and
  `skyMid: SIMD3<Float>`. Every old field keeps its meaning.
- `AmbientRamp.keys(for: LookVersion)`. Look 1 returns today's eight keys with the new fields filled so that it
  renders as before: `air = fogColor`, `vignette = 0.14 + 0.26 × nightness`, `black = 0`, `cloudColor` = the
  ambient colour, `skyMid` = the mean of top and bottom.
- Look 2's ten keys are `core.KEYS2`. The scalar columns:

| key | hour | ambient I | fog D | haze | stars | sun | moon | torch | warmth | sat | vig | black |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| pre-dawn | 4.6 | 0.15 | 0.50 | 0.45 | 0.3 | -0.30 | 0.30 | 1.0 | -0.25 | 0.80 | 0.34 | 1.0 |
| dawn | 5.9 | 0.40 | 0.55 | 0.60 | 0.1 | 0.02 | 0.05 | 0.7 | 0.18 | 0.88 | 0.26 | 0.5 |
| morning | 7.4 | 0.74 | 0.28 | 0.45 | 0 | 0.30 | -0.2 | 0.1 | 0.08 | 0.92 | 0.18 | 0.2 |
| noon | 12.0 | 0.92 | 0.10 | 0.32 | 0 | 1.00 | -0.6 | 0.0 | 0.00 | 0.96 | 0.16 | 0.2 |
| afternoon | 16.2 | 0.84 | 0.14 | 0.38 | 0 | 0.50 | -0.4 | 0.0 | 0.14 | 0.96 | 0.18 | 0.2 |
| golden | 17.8 | 0.66 | 0.28 | 0.55 | 0 | 0.14 | -0.1 | 0.2 | 0.32 | 1.00 | 0.22 | 0.3 |
| sunset | 18.8 | 0.44 | 0.32 | 0.45 | 0.05 | -0.02 | 0.00 | 0.6 | 0.32 | 1.02 | 0.28 | 0.5 |
| dusk | 19.5 | 0.30 | 0.38 | 0.42 | 0.2 | -0.15 | 0.15 | 1.0 | 0.08 | 0.95 | 0.30 | 0.8 |
| blue hour | 20.3 | 0.18 | 0.42 | 0.40 | 0.25 | -0.40 | 0.40 | 1.0 | -0.22 | 0.86 | 0.34 | 1.0 |
| night | 21.4 | 0.14 | 0.45 | 0.40 | 0.3 | -0.60 | 0.60 | 1.0 | -0.30 | 0.82 | 0.34 | 1.0 |

- The six colours per key (sky top, sky bottom, ambient, fog, air, cloud) are **not typed by hand**. A new small
  script `tools/scenemock/swift_keys.py` prints the Swift literal from `core.KEYS2` and a JSON fixture;
  `AmbientRampTests.testLookTwoKeysMatchTheMock` compares the table with the fixture. Two anchors to check the
  copy by eye: night's ambient is (0.36, 0.45, 0.88) at 0.14 and its air (0.25, 0.31, 0.60); golden's sky bottom is
  (0.96, 0.64, 0.38) and its cloud colour (1.15, 0.84, 0.55).
- Interpolation stays smoothstep between neighbours, wrapping over midnight.
- `skyMid`: the mock has two sky stops and its dusk shows a mauve band (an open point of `ART-look2.md`). The port
  adds a third stop. `lh_sky` blends top to mid over the upper 55 % of the sky rows and mid to bottom below. The
  art lane gives the dusk and sunset values; every other key uses the mean, which reproduces the mock exactly.
- Against the clock (12 s per hour): the horn at 19:00 falls between sunset and dusk, the waves from 21:15 are in
  deep night, first light is 05:00. `DayClock` is not touched.

### 1.2 `Render/RenderTypes.swift`: value compression and the look's numbers

- `Look` is a namespace of constants today. It becomes `struct LookValues` with two instances: `.one` (today's
  numbers, untouched) and `.two` (the mock's `LOOK2` dict). Its functions (`nightness`, `worldAmbient`,
  `ambientLevel`, `farAmbient`, `midAmbient`, `farHazeColor`, `midHazeColor`, `midHaze`, `foregroundAmbient`,
  `vignette`, `fogBrightness`, `bounceStrength`, `bandStrength`, `saturation`, `intensityScale`) become methods.
- Look 2's values, with look 1's in brackets where one exists:

| value | look 2 | value | look 2 |
|---|---|---|---|
| ambientLift | 0.30 (0.55) | colorise | 0.72 (0.6) |
| farShare | 0.85 (0.9) | midShare | 0.72 (0.7) |
| nearShare | 1.05 (new) | midLightShare | 0.30 (0.32) |
| nearLightShare | 0.5 (new) | farHaze | 0.40 (0.34) |
| farHazeShare | 0.55 (0.62) | midHaze day / night | 0.14 / 0.36 (0.2 / 0.36) |
| midHazeShare | 0.25 (0.26) | nearHaze day / night / share | 0.06 / 0.20 / 0.06 (new) |
| midAir / nearAir | 0.86 / 0.62 (new) | farHazeCool | 0.6 (0.75) |
| mist | 0.25 (0.22) | fogScale | 1.2 (new) |
| fogBrightMax | 2.6 (2.4) | fogGoal | 0.65 (new) |
| fogGlow | 0.35 (0.7) | fogMBright | 1.8 (new) |
| foregroundLight | 0.55 (0.75) | foreground ambient day / night | 0.55 / 0.45 (0.9 / 0.43) |
| bloomLightShare | 0.10 (0.16) | litCap | 1.0 (1.6) |
| bounce | 0.3 (0.5) | band / height / white | 0.2 / 40 / 0.3 (0.45 / 48 / 0.4) |
| rim (lord) | 0.6 (0.5) | creatureRim / peopleRim | 0.6 / 0.35 (new) |
| window radius / intensity | ×1.25 / 0.5 (×1 / 0.4) | glassGain | 1.3 (0.9) |
| fire intensity | ×1.15 (new) | cloud sun / fill / haze / moon | 1.0 / 1.5 / 0.3 / 0.7 |
| blackRange | 0.22 (new) | groundSky day / night | 1.0 / 1.2 (new) |
| moonTrack | 0.18 (new) | moonKey / moonLo | 0.30 / 0.26 (new) |
| ledge / ledgeSky | 1.4 / 0.15 (new) | interior | 0.30 (new) |
| vignetteX | 0.6 (0.82) | fireCold | 0.7 (new) |
| castleMist | 0.35 (new) | smoke | 0.55 (new) |
| midGlass | 0.45 (same) | bloom sky share | 0.55 (same) |

- New colour constants beside `aerialLavender`: `nightTint2 (0.72, 0.95, 1.85)`, `navy (0.030, 0.040, 0.095)`
  (`#080A18`), `ember #D9481F`, `emberDim #8C2A12`, `moonRim2 (0.62, 0.70, 0.95)`, `moonColor (0.55, 0.60, 0.92)`,
  `interior #B07850`. Light colours of look 2: torch `#FF9442`, lantern `#FFA34D`, candle `#FFAD57`, fire arrow
  `#FFB35C`, window `#FFA852`; braziers and the hearth keep `fireOrange`.
- The derived values, computed once per frame on the CPU in `Renderer.compositeUniforms` (mock names in brackets):
  - `level = lift + (1 − lift) · min(1, ambientIntensity)` (`lvl`); `ambientWorld = ambientColor / peak · level`.
  - `night = smoothstep((0.75 − ambientIntensity) / 0.5)`; `kcol = colorise · night`.
  - `warm0 = clamp(warmth / 0.45)`. Far ambient = desaturate(ambientWorld · farShare, 0.7 · warm0); mid ambient =
    desaturate(ambientWorld · midShare, 0.3 · warm0); near ambient = ambientWorld · nearShare.
  - Haze colours: far = mix(air, lavender, farHazeCool · warm0); mid = air · 0.86; near = air · 0.62.
  - Haze amounts: far = farHaze + haze · farHazeShare; mid = midHazeDay + (midHazeNight − midHazeDay) · night +
    haze · midHazeShare; near the same with its three values. The low mist adds `low · mist · (0.4 + fogDensity)`
    on far and half of that on mid and near, with `low = smoothstep((y − (ground − 70)) / 70)`.
  - Fog brightness = min(fogBrightMax, max(1, fogGoal / luma(fogColor))).
  - Foreground ambient = 0.55 to 0.45 by `night`; bounce = bounce · min(1, day · bounceDusk);
    `moonUp = clamp(moonHeight / 0.6)`.
- `LightQuad` keeps its stride. `color.w` is the vertical squash today (`lh_pool_fragment` multiplies dy by it).
  Look 2 squashes every pool by 1.25, so the squash moves into `LightPassUniforms.style.z`, and `color.w` becomes
  the **fire flag**: 1 = the colour falls to ember with distance, 0 = windows and all cold lights.
- `Renderer.rimmed` becomes `[SpriteID: RimKind]`: the lord (0.6, sky rim), the creatures (0.6, `moonRim2`, only
  where unlit), the people `archer`, `guardsman`, `builder`, `citizen`, `citizenB`, `citizenC` (0.35, sky rim).

### 1.3 Planes and targets: `Core/FrameDesc.swift`, `Render/Renderer.swift`

- `Plane` gains `mistBand` (0.62) and `near` (0.75). Order back to front: sky 0, clouds 0.05, far 0.2, mid 0.5,
  mistBand 0.62, near 0.75, fogA 0.9, world 1.0, fogB 1.15, foreground 1.3. `Camera` takes the factor from the
  plane and needs no change. `WorldLayout.border(plane)` gets the two new cases.
- `RenderTargets`: `near` is a full target ((W+1) × H, `rgba8Unorm`). `mistBand`, `fogA` and `fogB` become
  **strips** of (W+1) × 64 rows. Their painted banks are 60, 40 and 24 rows tall and sit at fixed rows (bottoms at
  ground + 2, ground + 4, ground + 14); the camera never moves vertically. `PlaneLayer` gains
  `rows: Range<Int>`; the renderer sets the strip's viewport from it, and the composite reads a strip only inside
  its rows (a row test, then one texel read).
- In look 1 the fog planes stay full targets until look 1 is deleted, because its fog strip sits at other rows.
  Simplest: the strip code path takes `rows = 0..<H` for look 1.
- Pass count in look 2: 10 plane passes (8 today) + light + emissive + 3 bloom + 1 native = 16 (14 today), plus
  one weather pass on rain days (3.4). Still far below the 30 draw calls of the budget: one call per pass.
- `Renderer.fill`: both new planes use the same `quad(...)` path. `reducedEffects` drops fog A today; in look 2 it
  drops the **mist band** and the second fog A copy instead (the bank behind the world carries the look) and
  halves the particle counts.

### 1.4 `Render/Shaders.metal`, function by function

All new maths is gated by `u.look2 > 0.5` only where the formula differs in kind; where look 1 and look 2 differ
only in numbers, the numbers come from the uniforms and the code is shared.

- **Constants.** `kNightTint` leaves the shader and becomes `u.nightTint.rgb` (look 1 sends (1.03, 0.86, 1.66),
  look 2 (0.72, 0.95, 1.85)); `kLitCap` becomes a uniform (1.6 and 1.0); `kMoonRim` a uniform. `kLitNeutral 0.35`,
  `kLitCool 0.6`, `kShadeLo 0.2`, `kShadeHi 0.5` stay. `lh_is_glass` is untouched.
- **`lh_sky`.** Three stops (`skyTop`, `skyMid`, `skyBottom`), still 16 dithered bands.
- **`lh_clouds`.** Mock: clouds. `lit = albedo · (cloudColor · cloudSun · Lw + skyTop · cloudFill · (1 − Lw) +
  moonColor · cloudMoon · moonUp)` with `Lw = clamp((luma − 0.6) / 0.3)`; then toward `skyBottom` by 0.3. New
  inputs: `u.cloud.rgb` now carries the key's cloud colour (today it is derived), `u.cloud.w` = cloudMoon · moonUp.
- **`lh_cold` (value compression and night tint).** Mock: `cold2`. `a = rgb · ambient`; pull toward
  `luma(a) · nightTint` by `kcol · (1 − sun · day · duskSun) · kmul`. The new parameter `kmul` is 1 everywhere but
  in a lit room (below).
- **`lh_base`**, back to front. New and changed steps:
  1. Far: ambient far, haze toward the far haze colour by the far amount plus the low mist. Unchanged in form.
  2. Mid: as today, plus the **moon key**: `mk = moonKey · moonUp · night · smoothstep((luma − 0.26) / 0.12)`;
     add `albedo · moonColor · mk`. Plus the ledge light (step 7).
  3. **Mist band** (new, strip): `lh_fog_lit` with gain `fogBrightness · 1.8` and glow share 0.4.
  4. **Near plane** (new): `ambientNear · (1 − fireCold · min(1, peak(L) · nearLight · 1.5))`; `lit = cold(n,
     ambient) + reflectance · L · 0.5 + moon key`; haze toward the near haze colour by the near amount; ledge.
  5. Fog A (strip): `lh_fog_lit`, glow share 0.6.
  6. World: **cold displacement** `fk = 1 − 0.7 · min(1, peak(L) · 1.5)` scales the ambient before `lh_cold`;
     **room rects**: inside a rect the ambient becomes `mix(ambientWorld, interior, iv)` and `kmul = 1 − iv ·
     torch`, with `interior = mix(ambientWorld · 0.8, #B07850 / peak · (lift + (1 − lift) · 0.30), torch)`
     computed on the CPU; **the lane's sky light**: rows ground ≤ y < ground + 8 multiply the ambient by `groundSky`
     (1.0 by day to 1.2 at night); **moon track**: rows ground ≤ y < ground + 7 add `albedo · moonColor · 0.18 ·
     moonUp · night`.
  7. **Ledge light** (mid, near, world; not actors, not the lane rows): `e` = 1 for a silhouette's top pixel
     (the texel above on the same plane is empty), 0.5 for the row below it; ambient × (1 + 0.4 · e) + skyBottom ·
     0.15 · e. To keep the read count down it is evaluated **only for the plane that wins the pixel**: two more
     reads (y − 1, y − 2) on one plane, not on three.
- **`lh_fog_lit`** (new; replaces the inline fog code). Mock: `fog_lit`. `f = fog · gain`; if the light's peak
  `pk > 0`: `wl = min(1, 1.2 · pk)`; `f = mix(f, luma(f) · L / pk, wl)` (the fog takes the fire's hue instead of
  adding white); result `c · (1 − a) + f + L · glowK · fogGlow · a`. Glow shares: mist band 0.4, bank 0.6, low
  mist 0.8.
- **`lh_top`.** Fog B through `lh_fog_lit` (0.8); foreground `cold(f, ambientWorld · fgAmbient) + f · L · 0.55`;
  bloom × 0.75; then `lh_grade`.
- **`lh_grade`.** Mock: `top`'s grade.
  - `warm = clamp(peak(L) · 1.5)`; `warmS = warm · (1 − smoothstep((fogAlpha − 0.3) / 0.2))`; saturation
    `s2 = sat + (max(sat, 1.08) − sat) · warmS`.
  - Tint: warm side (1 + 0.10 w, 1 + 0.02 w, 1 − 0.12 w), cold side (1 + 0.20 w, 1 + 0.05 w, 1 − 0.15 w) with the
    key's negative warmth, blended out by `warm`.
  - **Navy lift**: `kb = black · (1 − min(1, luma / 0.22))²`; `c += navy · kb`. Black pixels become `#080A18`.
  - Shoulder above 0.82, unchanged.
  - **Vignette**: `1 − vig · smoothstep((length(float2(u · 0.6, v)) − 0.42) / 0.83)`, `vig` from the key.
- **`lh_pool_fragment` (fire and window pools).** Distance `d = length(dx, dy · 1.25) / r` (squash from
  `style.z`). Level as today for the smooth style: `t = (1 − d)²`, below the edge 0.12 × 0.55. For lights with
  the fire flag the colour falls off: `k1 = smoothstep((d − 0.3) / 0.45)` toward ember, `k2 = smoothstep((d −
  0.75) / 0.25)` toward emberDim. Windows keep one colour. Backdrop lights (negative intensity) unchanged.
- **`lh_actor_fragment`.** Rim: mix toward the rim tone by `ra · (1 − min(1, peak(L) · 1.5))` on screen-right edge
  pixels; the tone and strength come from the instance (`ActorQuad.flags.z` = rim kind). Opaque actors still skip
  `lh_base`. On rain days one more read of the weather target (3.4).
- **Bloom.** `lh_bloom_prefilter_fragment`: light share 0.10. The composite adds bloom only outside emitters:
  `bloom · (1 − min(1, peak(emissive) · 2))`, using the emissive texel it has read already.
- **Debug views.** `-GWShowBuffer` gains `near`, `mist`, `weather` and `reads` (4.3).

### 1.5 `Render/ShaderTypes.swift` and the Metal twin: `CompositeUniforms`

Today: 25 `SIMD4` fields. The free scalars are used first, then fields are appended; nothing moves.

- Free slots taken: `cloud.w` = cloudMoon · moonUp; `grade.w` = vignetteX; `fog.w` = mist-band gain;
  `haze.w` = fireCold; `ambientMid.w` = the moon key's weight on mid and near; `farHaze.w`, `midHaze.w` = the low
  mist's share for that plane; `polish.x` = `look2`; `bounceColor.w` = litCap; `bank.zw` = the bank's fog
  swallow start and width (2.9); `backdropLight.w` stays free.
- Appended, 14 fields: `skyMid` (rgb, blend row), `ambientNear` (rgb, nearLightShare), `nearHaze` (rgb, amount),
  `nightTint` (rgb, kcol), `navy` (rgb · black, blackRange), `moon` (moonColor · moonUp · night, moonKey), `lane`
  (groundSky, moonTrack · moonUp · night, ground row, lane rows), `ledge` (ledge − 1, ledgeSky, moonLo, 0),
  `interior` (rgb, iv), `room0`, `room1` (rects in world-plane target pixels; zero size = none), `strips` (first
  row of mistBand, fogA, fogB; height), `weather` (wetness, rain, puddle level, wind), `weather2` (rain colour).
- 39 fields = 624 bytes, still sent with `setBytes`. `RendererTests.testStructStridesMatchTheShaders` gets the new
  count; write the Swift and the Metal struct in one commit, in the same order.
- `LightPassUniforms.style.z` = squash; `.w` free. `BloomUniforms.backdrop.w` = fire share, if 2.2 needs it.

### 1.6 `Core/FrameBuilder.swift`

- `build(...)` takes the look from `options` and a `WeatherSample` (3). Order of the new work inside it:
  ambient sample → weather applied to the sample (3.3) → planes → lights → particles.
- **Fog banks** (`fogLayers`, `fogTiles`). Three layers instead of two, from three painted sprites that tile
  seamlessly and are never flipped:

| plane | sprite | size | bottom row | alpha |
|---|---|---|---|---|
| mistBand 0.62 | `mistBand` | 448 × 60 | ground + 2 | fogD × 1.0 × region |
| fogA 0.9 | `fogBank` | 384 × 40 | ground + 4 | fogD × 0.9 × 1.2 × region |
| fogB 1.15 | `fogLow` | 320 × 24 | ground + 14 | fogD × 0.6 × 1.2 × region |

  Region share by world x (mock: `fog_region`): 1.0 for x < 1120, falling linearly to 0.7 at 1320, 0.7 to 2430,
  0.45 in the valley. The share is applied per tile quad as its alpha (tiles are cut at the two knees, so no
  per-pixel work). The castle-foot mist is the bank at × 0.35 (`castleMist`).
- **Drift**: base speeds mistBand 3, fogA 5, fogB 8 px/s (today 3 and 5), whole game pixels, times the wind
  factor of 3.2; a second fog A copy at half alpha drifting the other way (2.4). Reduce Motion: no drift at all
  (today it is slowed to 0.35; `ART-look2.md` 12.4 says none).
- **Near plane.** A new entry list `near` in the scene's cycle (1.7). Props on it take `fade`, `shade`, `mist`
  like mid props. Trees are emitted as two or three slices when the wind moves them (2.3).
- **Lanes** (`groundTiles`). Look 2 picks the lane by world x: `laneMoor` (−64 to 440), `laneScree` (440 to
  1240, new, see 1.7), `laneCobble` (1240 to 2430), `laneEarth` (2430 to the end), variant A to D by the mock's
  hash: `hv = (k · 0x9E3779B1) & 0xFFFFFFFF; hv ^= hv >> 15; variant = (hv >> 3) & 3` with k the tile index.
  Keep the hash bit for bit, so the mock's and the game's lanes are the same picture.
- **Lights** (`frameLights`). Fires × 1.15; windows radius × 1.25 and intensity 0.5; fire flag set for brazier,
  fire tower, firepot, fire arrow, hearth, torch, candle, lantern and beacon; not for windows, the gloomweaver or
  the Ash Giant's heart (its own ember colour). Glass gain 1.3, mid-plane glass 0.45.
- **Bank** (`bankTiles`). After each body tile one emissive `darknessBankGlow` frame:
  `(tileIndex + Int(time · 1.5)) % 4`; Reduce Motion holds `tileIndex % 4`.
- **Bright haze band**: strength 0.2, height 40, white 0.3 (numbers only).
- **Chimney smoke, sparks, fireflies, soot, puffs**: built by `Particles` (1.9) from the frame's time and wind.
- **Room rects**: for each visible cut-away room, a rect in world-plane target pixels. Hall: sprite x 24 to 236,
  rows 0 to 77; smithy: x 10 to 34, rows 0 to 31 (rows from the sprite's top). At most two are on screen;
  `FrameDesc.rooms` holds up to two.
- `FrameDesc` gains: `look`, `weather`, `rooms`, `near` is in `planes`, `wind` (the frame's signed wind at the
  screen centre), `wetness`, `rainInstances` (3.4).

### 1.7 The layout of the Throat: `Core/WorldLayout.swift`, `Core/SceneLayout.swift`, `tools/scenemock`

The rule (`ART-look2.md` 12.3 and `STORY.md` section 2): bare rock from the castle out to x 700, the mouth from
700 to 520, the open shadow land from 520 to 0. In the Throat: black granite walls, a floor of scree and old cart
ruts, no tree, no grass, no moss. The three battle lines, the ruined beacon tower and the warden cut into the
wall stand on rock. From the castle wall one sees stone and one narrow upright slit of grey-violet fog. The
shadow land's layers (fir ridge, forest edge in mist, moor track, ruins, statues) begin at the mouth.

- **No gameplay x moves.** `spawnX 40`, `beaconX 470`, lines at 1300, 940, 640, `castleFrontX 1240`. Only what
  is drawn changes. `Zone` gets new picture zones for the layout and the fog, kept apart from the gameplay zones:
  `shadowLand 0–520`, `mouth 520–700`, `throat 700–1300`. `worldRegion(x:)` keeps its three regions; `gorge` now
  ends at the mouth for the art, and the shadow land is a fourth region `shadowLand` for the region filter.
- **The mock comes first.** `layout_look2.py` is stage 1 (trees all the way to the castle). The art lane writes
  stage 2 (section 13.2 of `ART-look2.md`, not written on 7d6e6d2). The Swift layout is then a transcription, and
  `FrameBuilderTests.testSceneMatchesTheLayout` is fed by `swift_fixture.py` printing `layout_look2.instances()`
  as it prints `layout_m1b` today. The port does not invent positions.
- What stage 2 must say, so the Swift side can be prepared now:
  - **Lane**: `laneScree` A to D (64 px tiles, scree with two cart ruts) from 440 to 1240; `laneMoor` west of
    440. The rock apron runs to 440, not 520, so the beacon site (470) and line 3 (640) stand on rock as the
    story says; the walls end at 520.
  - **Mid plane** (0.5): the Throat's walls. `throatRock` and `gorgeWallHigh` (both 192 × 240, exist) and the
    repainted `gorgeWallA/B/C` cover the mid plane from the castle to the mouth without a gap; `gorgeMouth`
    (120 × 230) frames the slit. Seen from the wall walk at x 1300 the mid plane must be opaque up to the sky
    except for the slit: check in the mock with the camera at 1300 and at 940.
  - **Near plane** (0.75) in the Throat: no trees. Low rock spurs and fallen blocks only (one new sprite family,
    at most 40 px tall), or nothing. The near firs and dead trees of stage 1 stay only where their world x is
    below 520 (stage 1 lists them from 30 to 1150).
  - **World plane**: the bushes on z −3 east of 520 leave. The ruined beacon tower and the lines' works stay.
  - **Foreground** (1.3): `d2FgFerns` at 900 leaves; the one at 420 moves west so that it never covers rock
    (at 1.3 a strip at plane x 420 shows at world x of about 370); `fgRock` may stand in the Throat.
    `fgOverhang*` stays dropped.
  - **Fog**: region share 1.0 in the Throat already (x < 1120). The mist band is what fills the slit.
  - **Far plane** (0.2): the Weltmauer painting with the far castle (`tools/worldart.py`, planned), in tiles of
    at most 256 px width so the atlas packs (4.4).
- **Open conflict to settle before round L2-4** (for the lead, not for the port agent): `STORY.md` keeps the
  warden statue, cut into the Throat's own wall; `ART-look2.md` 12.3 takes `wardenStatue` (mid x 430) and
  `keepFar` (mid x 641) off the shadow land's mid plane. Both hold if the statue **moves into the Throat wall**
  (mid-plane x of about 520, which is world x 820, between lines 2 and 3) and keeps its bowl fire as the backdrop
  light; `keepFar` goes, replaced by the far castle on the far plane. The plan assumes this.
- Valley and castle: stage 1 as it is. Near trees by world x (valley 2452 to 3610, willows 3684 and 3790),
  placed with `at(p, X) = viewW / 2 + p · (X − viewW / 2)`; `d2FgMeadow`, `d2FgReeds`, `d2LaneEnd` at 3676;
  `fgRock` east of 2900 leaves; chimney smoke over the cottages at 2480, 2800 (flipped) and 3090; the high cloud
  deck (cloudB x 60 y 152, cloudC x 330 y 160 flipped, cloudA x 600 y 154).
- `SceneLayout.Cycle` gets `near` and `mistBand` entry lists. `SceneFilter` and `PlaceholderScene` learn the two
  planes (the light lab and the probe scene keep rendering with empty lists).

### 1.8 New sprite ids and frames: `Core/FrameDesc.swift`, `Core/EntityFrames.swift`

New `SpriteID` cases (sizes from the look-2 branch; stand-in widths where the art is not final):

| id | size | frames | plane |
|---|---|---|---|
| `mistBand`, `fogBank`, `fogLow` | 448 × 60, 384 × 40, 320 × 24 | 1 | fog strips |
| `darknessBankGlow` | 64 × 236 | 4 | emissive over the bank |
| `laneMoorA…D`, `laneCobbleA…D`, `laneEarthA…D`, `laneScreeA…D` | 64 wide | 1 | world |
| `d2FirA…D`, `d2DeadTree` | 59, 49, 37, 67, 60 wide; 60 to 130 tall | 1 | near |
| `d2Linden`, `d2Poplar`, `d2OrchardA…C`, `d2Willow` | 84, 24, 40 / 34 / 46, 70 wide | 1 | near |
| `d2BushA`, `d2BushB` | 30, 22 wide | 1 | world z −3 |
| `d2FgFerns`, `d2FgMeadow`, `d2FgReeds` | strips | 2 (wind) | foreground |
| `d2LaneEnd` | as painted | 1 | world |
| `d2Smoke` | puff | 1 | world |
| `d2Sparks` | 1 px quads, no texels | – | emissive |
| `weltmauerA…`, `weltmauerGlow` | tiles ≤ 256 wide; glow as small window sprites | 1 | far, emissive |
| `lightShaft` | 64 × 128 | 1 | far, additive |
| `castleFlag` | 14 × 10 | 4 | world (3.2) |
| `rainSplash`, `lanePuddleA…C` | 5 × 3; 12 to 24 × 3 to 4 | 3; 1 | world, weather (3.4) |

Creatures and the bank (`ART-look2.md` 11.4, 11.5). The sprites load unchanged: ids, sizes, frame counts, facing
right, bottom-centre anchors, walk 0 to 3, attack 4 to 5 or 4 to 6, crow 0 to 2 and 3, weaver 0 to 3.

- `walkStride`: stays 3 (sootling), 6 (shadehound), 4 (ash brute), 4 (ash giant), 5 (Lightless King), default 4.
  The new walk cycles were drawn for these strides. `EntityFramesTests` pins them.
- **Glow strips hold cold pixels now.** `glows(...)`: add them as they are: no warm tint, no torch strength; the
  eyes stay by day. `unlitValue 0.2` and the moon rim stay; `creatureShade` stays within 0.9 to 1.0.
- **Light positions** (from the bottom-centre anchor, mirrored when the creature faces left):
  - gloomweaver: violet light at the lantern core, 9 px right, 9 px up;
  - Lightless King: the sprite fills 64 px, so anything over his head goes 2 px higher; the aura's centre is 4 px
    left and 52 px up (`kingGlass` and `auras` follow);
  - Ash Giant: a new heart light 5 px right and 68 px up, emitter radius 7, ember colour, pool radius about 20
    px, brightest on frame 5. It is a render light only and must not enter `LightField` (6).
- **Hit frames**: the giant's stomp, the brute's slam (fist 17 px right of the anchor) and the sootling's and the
  hound's attacks land on frame 5. Only the **visible** part moves to frame 5: the screen kick, the dust, the
  cue. The simulation's damage time is not touched in this port (it would move T1 to T8); see 6.
- **Soot**: the brute, the giant and the King shed one dark pixel a few times a second from the top contour,
  drifting with the wind (left in calm air). Inside `maxEffectParticles 24`.
- **Darkness bank**: `darknessBank.png` and `darknessEdge.png` keep their sizes and load without Swift changes;
  the glow strip is the one new id (1.6).
- **Far castle's window glow**: `weltmauerGlow` sprites as emissives on the far plane, alpha by `torchStrength`;
  once the Great Beacon burns, a 3 × 4 px emissive at the far keep's top (it blooms through the sky share).

### 1.9 `Render/Particles.swift`

- `embers`: colour from ember `#D9481F` cooling to emberDim; sideways drift from the wind; total cap 160.
- New pure functions, all deterministic for (frame, time, wind): `sparks`, `fireflies`, `smoke`, `groundPuffs`,
  `ashMotes` (the bank's cold motes replace today's 30 soot `motes` in look 2), `rain` and `splashes` (3.4).
  Each returns instances; none keeps state. Reduce Motion rules in 2 and 3.5.

### 1.10 `Render/Atlas.swift`

- No change to the packer for rounds L2-0 to L2-5. The far painting is cut in tiles so no sprite is wider than
  256 px besides the strips that exist. When page one would pass 85 % (4.4), `AtlasBuilder` gets a second page
  for the backdrop sprites (sky, clouds, far, mid, fog): those planes are drawn in their own passes, so binding
  another page costs no draw call. `AtlasTests` then assert at most two pages and one page per plane pass.

### 1.11 `App/DebugArgs.swift`

New launch arguments: `-GWLook 1|2`, `-GWWeather auto|clear|breeze|gusty|storm`, `-GWWind <−1…1>`,
`-GWRain <0…1>`, `-GWWetness <0…1>`, and `-GWShowBuffer near|mist|weather|reads`. `DebugArgsTests` cover each.

### 1.12 The merge

`claude/lh-look2-fable` branched before M3's art. Its diff against 8467449 changes 160 PNGs, adds the bank
files, and seems to delete M3's files (`bard.png`, `hesper.png`, `chapelInterior.png`, …) only because it never
had them. Merge it into the port branch with M3 as the base: take the look branch's version of every PNG both
sides have, keep every file only M3 has, keep M3's Swift. Check after the merge: `git diff --diff-filter=D --name-only
8467449 -- games/lanternhold/Resources/Art` must print nothing. `mock.py look=1` still renders byte for byte.

## 2. The effects: what each gives and what it costs

Cost is counted in four currencies. **Passes** (each is one draw call). **Fill**: low-resolution pixels drawn,
against a full target of about 79,000 (438 × 180 at the reference size). **Reads**: texture reads per native
pixel in the composite, the dominant GPU cost (4.3). **Instances**: against the budget of 1,500.

| # | effect | gives | passes | fill | reads | instances |
|---|---|---|---|---|---|---|
| 2.1 | light shafts | the cleft becomes the place the eye goes at dawn and golden hour | 0 | ≤ 24k | 0 | 3 |
| 2.2 | bloom on fire | fires glow past their sprite; the lit core stays crisp | 0 | 0 | 0 | 0 |
| 2.3 | wind sway in the near trees | the world breathes; depth by motion | 0 | 0 | 0 | +2 per tree, ≤ 30 |
| 2.4 | fog drifting in layers | air with depth; the Gloom creeps toward the castle | 0 | +14k | 0 | ≤ 8 |
| 2.5 | sparks | fires are alive; hits on braziers read | 0 | < 100 px | 0 | ≤ 60 |
| 2.6 | fireflies | the valley is worth defending; dusk has its own minute | 0 | < 20 px | 0 | ≤ 12 |
| 2.7 | chimney smoke | the town lives; shows the wind | 0 | ≈ 1k | 0 | ≤ 16 |
| 2.8 | embers | exists; gets look 2's colour and the wind | 0 | < 200 px | 0 | ≤ 160 |
| 2.9 | the fog swallows figures | creatures come out of the Gloom, not from the screen edge | 0 | 0 | 0 | 0 |
| 2.10 | bank eyes, far windows, cloud drift, foot puffs, soot | detail that pays the second look | 0 | ≤ 120k emissive, mostly empty | 0 | ≤ 40 |

No effect adds a pass or a read. That is the design rule for this section: effects are instances in passes that
exist.

**2.1 Light shafts through the cleft.** Two or three additive quads from one soft wedge texture (`lightShaft`,
64 × 128), anchored at the cleft's top on the far plane and drawn at the end of the far pass with the additive
pipeline the sky emissives use. Being in the far target, they take the far haze for free. Alpha = the low-sun
weight: `smoothstep` of the sun height between −0.02 and 0.14, falling again above 0.5 (dawn, morning, golden);
tint = the key's cloud colour; breathing ± 15 % at 0.05 Hz. Off at night, off in rain. Reduce Motion: no
breathing. Cost: three quads over at most a third of the far target.

**2.2 Bloom on fire.** The mock's proposal is a quarter-size emissive blur. The game has the half-resolution
chain already (prefilter, H, V), so no new pass: the fires' emissive pixels feed the prefilter as today, the light
share drops to 0.10, and the composite adds bloom only **outside the emitter**, `bloom · (1 − min(1,
peak(emissive) · 2))`, from the emissive texel it has read anyway. The fire's own pixels stay sharp, the halo
sits around them. If fires need more halo than windows, `BloomUniforms.backdrop.w` carries a fire share and the
emissive pass writes fires at × 1.35. Cost: none.

**2.3 Wind sway.** A near tree or a foreground plant is emitted as two or three horizontal slices of the same
sprite (crown, middle, trunk: split rows fixed per sprite id in a small table). Upper slices are moved by whole
pixels: `offset = round(lean + amp · sin(t · ω + phase))`, with `phase` from the tree's world x, `ω` a period of
3 to 4 s, and `amp`, `lean` from the wind (3.2): calm air gives the art rule's ± 1 px at the crown only. Whole
pixels, so a slice never shows a half texel. Foreground grass and ferns swap between their two frames instead.
Nothing sways on the far and mid planes. Reduce Motion: one slice, no offset. Cost: at most 14 trees on screen,
+28 instances.

**2.4 Fog in layers.** Three painted banks on three planes with three speeds (3, 5, 8 px/s, times the wind
factor), plus a second copy of the fog A bank at half alpha moving the other way, offset by half its width, so
the bank's shapes pass through each other and never read as one sliding picture. At night the drift is toward
the castle (the Gloom leans in); at noon the fog stands. Cost: the second copy's fill inside the 64-row strip.
Reduce Motion: no drift, the second copy stays.

**2.5 Sparks.** From `d2Sparks`' rule: 3 to 6 one-pixel additive quads per open fire, rising 8 to 14 px over
0.6 s, fireGold falling to ember, leaning with the wind. Built like `Particles.embers`: a pure function of
(light id, time), so a screenshot at a fixed `-GWFlickerTime` is the same every run. A burst of 8 when a fire
arrow lands or a brazier is lit (from the `SimEvent`, not from state). Reduce Motion: a third of the count at
0.35 speed, no bursts.

**2.6 Fireflies.** 8 to 12 emissive fireGold dots in the valley (x > 2430), hours 18.5 to 21, drifting on slow
Lissajous paths 6 to 30 px above the lane, blinking with a 2 to 3 s period. No light quads (the 64-light cap is
for fires); the bloom's sky share gives them their glow. None in rain, none when the wind is above 0.6, none
once the first wave is out. Reduce Motion: they stand still and fade in and out.

**2.7 Chimney smoke.** Per chimney three or four soft puffs of `d2Smoke` on the world plane at alpha 0.55,
rising 40 px and fading; the column leans up to 12 px with the wind and tears in gusts. Lit by the ambient only
(grey by day, navy at night). Reduce Motion: the puffs stand as a still column.

**2.8 Embers.** As today, with look 2's ember colours and the wind's drift; counts per light kind unchanged
(brazier 11, fire tower 15, firepot 8, fire arrow 4, hearth 7, torch 3, beacon 24), capped at 160 on screen by
distance from the screen centre.

**2.9 The fog swallows figures.** A creature's alpha = `clamp((x − bankEdge) / 60)`: it fades in over 60 px as it
leaves the bank. Actors are drawn in the native pass after fog A, so "behind the fog" is done in
`lh_actor_fragment`: below alpha 0.6 the actor's colour is pulled toward the fog colour by `(0.6 − a) / 0.6`. No
read, no pass. The simulation does not know: a faded creature can be shot as before, and the archers' target
choice does not change. If players find that unfair, shorten the fade to 30 px.

**2.10 The small ones.** Bank eyes (1.6): up to 8 emissive quads of 64 × 236, almost all transparent. Far
windows and the far beacon (1.8). Cloud drift: the cloud plane's props move 1 px/s times the wind factor inside
`FrameBuilder`, no new plane. Foot puffs: 4 px puffs of the mist colour for 0.4 s at alpha 0.3 under walking
feet where the low mist stands, at most 12. Soot from the brute, the giant and the King (1.8).

## 3. The weather system (Louis' wish)

### 3.1 The model: `Core/Weather.swift` (new, pure)

```swift
enum WindClass: Int, Sendable { case calm, breeze, gusty, storm }

struct DayWeather: Sendable, Equatable {       // one per day, from the run's seed and the day number
    var windClass: WindClass
    var direction: Float                        // +1 from the shadow land toward the valley, −1 the other way
    var base: Float                             // mean wind 0…1
    var gust: Float                             // gust amplitude 0…1
    var rainStart: Double?                      // absolute game hours (day · 24 + hour); nil = dry
    var rainLength: Double
    var rainStrength: Float
}

struct WeatherSample: Sendable, Equatable {    // what a frame reads
    var wind: Float                             // signed, −1…1, at the screen centre, with gusts
    var windClass: WindClass
    var rain: Float                             // 0…1, with ramps
    var cover: Float                            // cloud cover 0…1 (leads the rain by one game hour)
    var wetness: Float                          // 0…1, stone and lane
    var puddles: Float                          // 0…1, level in the ruts
}

enum Weather {
    static func day(seed: UInt64, day: Int) -> DayWeather
    static func sample(seed: UInt64, day: Int, hour: Double, time: Double,
                       override: WeatherOverride?) -> WeatherSample
    static func wind(at worldX: Double, _ s: WeatherSample, time: Double) -> Float   // gusts travel
    static func apply(_ s: WeatherSample, to ambient: AmbientSample) -> AmbientSample
}
```

- **Seeding.** `h = SeededRandom.hash(seed ^ 0x57454154484552, Int64(day))` (the salt is "WEATHER" in ASCII, so
  the weather never shares a stream with the waves), then `SeededRandom.mix` for each further field. No state,
  no generator object: the same run seed and day give the same weather on every device and in every test.
- **Wind class per day**: calm 30 %, breeze 40 %, gusty 24 %, storm 6 %. Rules: days 1 and 2 are a dry breeze
  (the first minute, the onboarding and the store pictures stay the same); no storm before day 4; never two
  storms in a row (the second becomes gusty). Direction: 70 % from the shadow land toward the valley.

| class | base | gust | trees | grass frames | flag | smoke lean | fog and cloud factor |
|---|---|---|---|---|---|---|---|
| calm | 0.08 | 0.04 | ± 1 px, crown only | 0.4 Hz | hangs (frame 0) | 0 to 2 px | 0.5 |
| breeze | 0.35 | 0.12 | ± 1 px, crown and middle | 1 Hz | 4 fps | 4 px | 1.0 |
| gusty | 0.55 | 0.35 | ± 1 px, lean 1 px in gusts | 2 Hz | 7 fps | 8 px | 1.6 |
| storm | 0.85 | 0.15 | ± 2 px, lean 1 to 2 px | 4 Hz | 10 fps | 12 px, torn | 2.4 |

- **Rain.** 25 % of the days that are not storms have one rain window; a storm always has one. Start anywhere in
  the 24 hours, so rain falls by day and by night; length 3 to 9 game hours (storm 6 to 12); strength 0.4 to 0.8
  (storm 1.0). Ramps of 20 s in and out. The window is stored in absolute hours and `sample` looks at yesterday's
  and today's window, so a night's rain runs across the change of the day.
- **Gusts.** `wind = direction · (base + gust · g(time))` with `g` = smooth value noise of (hash, time / 4 s),
  shaped by `smoothstep(0.55, 0.8, ·)` for the gusty class. Gusts travel: `wind(at: x)` evaluates `g` at
  `time − direction · x / 500`, so a gust runs across the trees at 500 px/s in the wind's direction and the
  screen never sways as one block. Around the change of the day, the two days' base and direction are blended
  over one game hour.
- **Wetness and puddles** are closed forms of the rain windows, not accumulators: wetness rises over half a game
  hour of rain and dries over two; puddles fill over one hour and drain over six. So any day and hour can be
  opened from a launch argument and looks as it would in play.
- **Time.** `time` is the render clock that drives the flicker (`-GWFlickerTime` fixes it). One accumulator is
  needed and lives beside that clock, not in the frame builder: `windTravel` (the integral of the wind), which
  the fog, the clouds and the smoke use as their phase so that a gust speeds them up without a jump. With a
  fixed flicker time it is `time · base · direction`, so screenshots are stable.
- **Override**: `-GWWeather`, `-GWWind`, `-GWRain`, `-GWWetness` (1.11) set a `WeatherOverride` in `FrameOptions`.
- `GameModel` asks `Weather.sample(seed: state.seed, day: state.day, hour:, time:)` once per frame and hands it
  to `FrameBuilder.build`. Nothing else in the app stores weather; a saved game needs no new field.

### 3.2 What the wind drives

One signed number per world x and frame. Everything that moves in air reads it; nothing has its own wind.

- **Near trees and foreground plants**: slices (2.3) with the class's amplitude and lean, phase per tree.
- **Grass, ferns, reeds**: the two frames swap at the class's rate, phase by tile; in a gust all lean frames.
- **Banners**: the hall's banners are indoors and hang still. Outside, a new `castleFlag` (14 × 10, 4 frames)
  on the keep and the gatehouse: frame 0 hangs, 1 to 3 flutter at the class's rate, flipped by the direction.
- **Chimney smoke and steam**: lean by the class, drift with `windTravel`, torn (shorter life) in a storm.
- **Fog**: velocity per layer = base speed · (0.6 · night · toward the castle + factor · wind); at a calm noon
  it stands, at night it leans in, in wind it runs with the wind. Clouds: 1 px/s · factor.
- **Particles**: embers, sparks, soot, ash motes and foot puffs drift sideways by `wind · 10 px/s · age`; the
  fireflies stay home above 0.6.
- **Rain**: the streaks' slope is `0.45 · wind` px sideways per px of fall.
- **Not driven**: the darkness bank's position, arrows, anything the simulation owns.

### 3.3 Rain: darker air

`Weather.apply` changes the ambient sample before anything is drawn (`r` = rain, `c` = cover):

- ambient intensity × (1 − 0.22 r); saturation × (1 − 0.12 r); warmth × (1 − 0.6 c); vignette + 0.04 r;
- fog density + 0.15 r; haze + 0.18 r (the far planes sink into grey, which is what sells rain at a distance);
- sky top and bottom toward their own grey by 0.5 c and × (1 − 0.15 c); cloud colour × (1 − 0.35 c);
- stars × (1 − c); moon key, moon track and cloud moonlight × (1 − 0.8 c); sun shadows × (1 − c); shafts off.
- `torchStrength` is not touched: the night's fires are the same fires.
- Floor: a rainy night's frame mean must stay at or above 0.17 (dry target 0.20 to 0.23). A test holds it (3.7).

### 3.4 Rain: streaks in three depths, splashes, sheen, puddles

- **One new low-resolution target**, `weather` ((W+1) × H, `rgba8Unorm`), drawn in **one additive pass only
  while it rains or puddles stand**, read once by the composite. Its channels are coverages:
  R = back streaks, G = middle streaks, B = front streaks, A = puddles.

| depth | channel | parallax | streak | fall | count at rain 1 | where the composite adds it |
|---|---|---|---|---|---|---|
| back | R | 0.75 | 1 × 4 px, 0.35 | 150 px/s | 110 | before the world plane: × (1 − world alpha) |
| middle | G | 1.0 | 1 × 7 px, 0.5 | 220 px/s | 70 | after the world, before fog B |
| front | B | 1.3 | 2 × 11 px, 0.6 | 320 px/s | 28 | after the foreground, before the grade; also over actors |

  Counts scale with `rain` and with the target's width. Each streak is a pure function of (index, time): x from
  a hash, y = `(time · fall + phase) mod (H + length)`, x shifted by its depth's parallax so the three depths
  slide against each other when the lord walks. Whole game pixels.
- **Colour**: `rainColor = mix(skyBottom, ambientWorld, 0.5) · 0.9 + L · 0.6`. The streaks take the light
  buffer: by day they are grey lines against the sky, at night they are nearly invisible in the dark and
  **light up gold in every fire's pool**. That is the picture of the rain night, and it keeps the battlefield
  readable where there is no light.
- **Splashes**: `rainSplash` (5 × 3, three frames over 0.18 s) on the lane's top row and on the wall walk, at
  most 40 at rain 1, positions from a hash of (index, `floor(time / 0.18)`), on the world plane, lit as the
  world is.
- **Wet sheen on stone and lane** (`w` = wetness), all in the composite, no read added:
  - the ledge light × (1 + 1.5 w): wet tops of walls, roofs and rocks catch the sky;
  - the lane's top 3 rows add `L · 0.5 w · (0.6 + 0.4 · hash(column))`: the fires glint on the wet lane, broken
    per column so it reads as wet stone;
  - the lane's sky light + 0.25 w; the world's and the near plane's ambient × (1 − 0.12 w): wet stone is darker.
  - **No mirrored image, anywhere.** DESIGN's "Not a copy" rules out a reflection strip along the bottom; the
    sheen is highlights on the top rows only, and puddles are flat sheets of sky colour.
- **Puddles in the lane's ruts**: `lanePuddleA…C` at fixed spots from a hash of the lane tile index (one tile in
  three on scree and earth, one in six on cobble, one in two on the moor track), drawn into the A channel. On the
  lane rows: `c = mix(c, skyBottom · 0.55 + L · 0.7, A · puddles · 0.85)`. While it rains the puddle pixels
  flicker by ± 0.15 from a hash of (x, `floor(time · 8)`). Puddles stay for hours after the rain: the morning
  after a night battle shows them, which is the cheapest storytelling in this plan.
- **Fires that hiss**: open fires (brazier, firepot, fire tower, outdoor torch, beacon; not the hearth, the
  windows, candles or lanterns): drawn intensity × (1 − 0.12 r), flicker amplitude × (1 + 0.6 r), sparks halved,
  a steam puff (`d2Smoke` at alpha 0.3, 12 px, 0.5 s) every 0.4 to 0.9 s, and the `fireHiss` cue. This is in
  `frameLights` only. **`LightField`, the gameplay light, is not touched**: a brazier holds the dark in rain as
  it does in dry air.
- **No lightning.** A flash would light the battlefield and is a flashing-light risk. Storms get far thunder as
  sound only.

### 3.5 Reduce Motion, and the thermal cut

`ART-look2.md` 12.4: no drift, no wind, no breathing; fades stay.

- Wind: no sway, no lean, grass on frame 0, flags hold frame 0 (calm) or 1, fog and clouds stand, the smoke
  stands as a column that leans by the class.
- Rain: **no streaks, no splashes, no puddle flicker.** Rain shows as darker air, more haze, the sheen, the
  puddles, standing steam at the fires, and sound. Fading in and out stays.
- Flicker keeps today's rule (amplitude × 0.25, rate × 0.35).
- Thermal `.serious` and `-GWEffects minimal`: the weather pass and the mist band are dropped; rain then shows
  as it does under Reduce Motion.

### 3.6 Sound hooks (sound effects only; there is no music)

- Beds are not events, so `Core/Feedback.swift` gains `struct AmbienceState { rain, wind: Float; windClass }`
  from `Weather.ambience(_:)`, and `App/FeedbackHub.swift` gains `setAmbience(_:)`, called once per frame, which
  fades two looped beds over 1.5 s: `rainBed` (gain = rain) and `windBed` (gain = |wind|).
- One-shots as new `FeedbackCue` cases, all ranked below every gameplay cue so `maxPerFrame 4` drops them
  first: `gust` (at a gust's onset, from the same noise the trees use), `fireHiss` (positional, at the nearest
  open fire on screen, at most one per 1.5 s), `thunderFar` (storm only, every 20 to 50 s), `drip` (sparse, for
  one game hour after the rain).
- No haptics for weather: a storm must not buzz the phone for a minute.
- The port adds the hooks; they stay silent until the sound lane delivers files. A rain bed is a sound effect,
  not music. If Louis counts a loop as music, the fallback is a `rainPatter` one-shot every 0.7 to 1.4 s.
- No new strings: the weather has no label in the HUD. Whether the dawn report should name the weather is a
  product question for the lead.

### 3.7 How tests and screenshots cover it

Unit, `WeatherTests` (pure, fast):

- same seed and day give the same weather; another day gives another;
- shares over 1,000 days: calm 26 to 34 %, breeze 36 to 44 %, gusty 20 to 28 %, storm 3 to 9 %, rain on 25 to
  40 % of days; days 1 and 2 dry breeze; no storm before day 4; never two storms in a row;
- continuity: over a whole day and across the change of the day, wind moves at most 0.05 per 1/60 s and rain at
  most 0.01;
- wetness rises in rain and falls after, puddles outlast it, both carry over the change of the day;
- `testReduceMotionStillsTheFrame`: two frames 1.7 s apart have the same sway offsets and fog positions and no
  rain instances;
- `testRainIsDeterministic`: the same (seed, day, hour, time) gives the same instances;
- `testTheSimulationNeverSeesTheWeather`: night 12 of seed 1 run once forced clear and once forced storm ends
  in equal `GameState`s; and an `sh` step of the round greps that no simulation file names `Weather`.

Budget, `FrameBudgetTests`: a storm night with forty creatures stays inside 1,500 instances and the pass count.

GPU, offscreen with read-back (`OffscreenRenderTests`):

- `testADryFrameIsUnchangedByTheWeatherCode`: rain 0, wind 0, wetness 0 gives the pixels of the frame built
  without weather;
- `testRainDarkensTheFrameAndKeepsTheFloor`: mean 8 to 25 % lower than dry, night mean at least 0.17;
- `testTheWetLaneGlintsAtAFire`: the lane's top rows inside a brazier's pool are at least 10 % brighter wet than
  dry, and unchanged 200 px away;
- `testStreaksCatchFirelight`: the weather's share is larger inside a pool than outside;
- `testPuddlesShowNoImage`: the colour across one puddle varies less than a small bound (no reflection);
- `testReadsStayInsideTheBudgetInRain` (4.3).

Screenshots, `WeatherUITests`, English and German, all with `-GWSeed 1 -GWFreezeTime YES -GWFlickerTime 3`:

| name | arguments | shows |
|---|---|---|
| `60-wind-calm-<lang>` | `-GWWeather clear -GWHour 12 -GWCameraX 2800` | the still town |
| `61-wind-gusty-<lang>` | `-GWWeather gusty`, same camera | leaning trees, smoke, flags |
| `62-storm-dusk-<lang>` | `-GWWeather storm -GWHour 19.2 -GWCameraX 900` | the Throat in a storm |
| `63-rain-night-battle-<lang>` | `-GWNight 12 -GWAutoplay YES -GWWeather storm` | streaks gold in the fires |
| `64-rain-golden-river-<lang>` | `-GWRain 0.6 -GWHour 17.9 -GWCameraX 3720` | sheen and puddles in warm light |
| `65-after-rain-<lang>` | `-GWRain 0 -GWWetness 0.6 -GWHour 7.4` | puddles, no rain |
| `66-rain-reduce-motion-<lang>` | as 63 with `-GWReduceMotion YES` | rain without streaks |
| `67-weather-buffer-<lang>` | as 63 with `-GWShowBuffer weather` | the three depths |

Two more captures of 62 at flicker times 3.0 and 3.5 must differ; of 66 they must not, apart from the flicker.
`LightProbeUITests.testFilmstrip` gets a second strip: the ten hours in rain.

## 4. The performance budget

### 4.1 Devices and frame time

The deployment target is iOS 17, so the slowest chips are the A12 phones. Sizes by the scale rule
`s = max(2, floor(H / 180))`, target `(ceil(W / s) + 1) × ceil(H / s)`:

| phone | chip | native pixels | s | low-res target |
|---|---|---|---|---|
| iPhone SE 2, SE 3 | A13, A15 | 1334 × 750 = 1.00 M | 4 | 335 × 188 = 63k |
| iPhone XR, 11 | A12, A13 | 1792 × 828 = 1.48 M | 4 | 449 × 207 = 93k |
| iPhone XS, 11 Pro | A12, A13 | 2436 × 1125 = 2.74 M | 6 | 407 × 188 = 77k |
| iPhone XS Max, 11 Pro Max | A12, A13 | 2688 × 1242 = 3.34 M | 6 | 449 × 207 = 93k |
| iPhone 17 Pro (reference) | A19 Pro | 2622 × 1206 = 3.16 M | 6 | 438 × 201 = 88k |
| iPhone 17 Pro Max | A19 Pro | 2868 × 1320 = 3.79 M | 7 | 411 × 189 = 78k |

**The worst case is the XS Max: an A12 with 3.34 M native pixels.** The low-resolution work is the same small
size on every phone; the native pass is what scales.

DESIGN's budget stays as it is: 60 fps (16.7 ms), CPU at most 4 ms, GPU at most 6 ms on an A12. How look 2
spends it (budgets, to be measured on a device; the runner cannot measure time):

| part | budget on an A12 | what it is |
|---|---|---|
| CPU: `FrameBuilder.build` with weather and particles | 1.8 ms | pure code, about 900 instances at worst |
| CPU: `Renderer.fill` and encoding 16 or 17 passes | 1.5 ms | buffer writes, no allocation per frame |
| CPU: headroom | 0.7 ms | |
| GPU: all low-resolution passes | 1.0 ms | about 1 M pixels of plain textured fill and blend |
| GPU: the native composite | 4.0 ms | 3.34 M pixels × the reads of 4.3 |
| GPU: actors and headroom | 1.0 ms | |

### 4.2 Passes, fill and overdraw

Full-screen equivalents of low-resolution fill (DESIGN: at most 12):

| | today | look 2 dry | look 2 in rain |
|---|---|---|---|
| full plane targets | 8 | 7 (sky, clouds, far, mid, near, world, foreground) | 7 |
| fog strips (64 of about 180 rows) | – | 3 × 0.36 = 1.07 | 1.07 |
| light, emissive | 2 | 2 | 2 |
| bloom (3 at half size) | 0.75 | 0.75 | 0.75 |
| weather | – | – | 1 |
| **sum** | **10.75** | **10.82** | **11.82** |

Reserve if it is needed: look 2's foreground only holds strips at the bottom of the screen, so it can become a
strip of 64 rows as well (−0.64).

Limits, all computed from the `FrameDesc` on the CPU, so the runner can test them
(`FrameBudgetTests.testFillAndOverdrawStayInsideTheBudget`, over the six mock scenes, a storm night and the
finale):

- passes: at most 17; draw calls: at most 30 (one per pass plus the HUD);
- instances: at most 1,500 (expected worst: about 900 in a storm night with forty creatures);
- overdraw per plane target (sum of clipped quad areas over the target's area): mean at most 2.5, no target above
  4. The near plane with overlapping firs and the world plane with tiles, props and shadows are the ones to watch;
- sum of drawn low-resolution pixels over all plane passes: at most 2.5 M at the reference size;
- light pass: the sum of the pools' areas at most 8 targets' worth; lights at most 64. The windows' larger radius
  (8 to 10 px) adds almost nothing; the Ash Giant's heart and the gloomweaver's lantern count as lights;
- native pass: overdraw 1 for the composite, actors on top (at most 15 % of the screen).

### 4.3 Reads per native pixel: the number that stands in for GPU time

Today the composite reads about 11 textures per pixel (eight planes, light, emissive, bloom). Done naively look 2
would read 16 (mist band, near, two for the ledge, weather): about 45 % more work on 3.34 M pixels. Four rules
bring it back:

1. **Strips**: mist band, fog A and fog B are read only inside their rows (36 % of the rows).
2. **Front to back**: `lh_base` first reads the world texel. Where it is opaque (the ground rows, the castle,
   houses, walls) nothing behind it is read: sky, clouds, far, mid, mist band, near and fog A are skipped. The
   same test on the near, mid and far texel skips what is behind those.
3. **Ledge on the winning plane only** (1.4), and not on the lane rows or under an actor.
4. **Weather only when it rains** (a uniform branch, free when dry).

Budget: **mean at most 12.0 reads dry and 13.0 in rain, no pixel above 17.** The debug view
`-GWShowBuffer reads` makes the shader return its own read counter as a grey value (count / 32);
`OffscreenRenderTests.testReadsStayInsideTheBudget` renders the six mock scenes, a night battle and a storm
night offscreen, reads back and checks mean and maximum. The counter is exact and deterministic, so this is a
performance test the runner can run. It does not replace the device check (below): it keeps a later change from
doubling the cost unseen.

Branches on a texel's alpha are cheap on Apple's GPUs and coherent across large screen areas here (ground,
walls, sky), so rule 2 is a real saving and not only a count.

### 4.4 The atlas limit of 2048

- Today: 166 PNGs with 1,480,925 texels of art, 35 % of one 2048 × 2048 page before padding (2 px), shelf waste
  and the procedural placeholders. The packer tries width 1024 first and goes to 2048 when the height passes
  2048; `AtlasTests` assert one page and both sides at most 2048.
- What look 2 and the weather add (estimates from the look branch's sizes and stand-ins):

| group | texels |
|---|---|
| fog banks (448 × 60, 384 × 40, 320 × 24) | 50k |
| `darknessBankGlow` (4 × 64 × 236) | 60k |
| near trees and bushes (13 sprites) | 65k |
| lanes (16 tiles of 64 px) | 40k |
| foreground strips with two frames each | 65k |
| Weltmauer far painting in tiles, far castle, window glow | 220k |
| the Throat's rock (repainted walls, spurs) | 60k net |
| shaft, smoke, flag, splash, puddles | 12k |
| **sum** | **about 570k** |

- After the port: about 2.05 M texels of art, 49 % of the page raw, about 60 % with padding and shelf waste.
  One page holds.
- Rules: no sprite or strip wider than 1024 (the widest today is the Ash Giant's 770); backdrop paintings are
  cut into tiles of at most 256 px; an animation is a strip of frames, never a sheet.
  `AtlasTests.testThePageHasHeadroom` asserts the used area is at most 85 % of the page.
- If it passes 85 %: a second page of 2048 × 1024 for the backdrop planes (1.10). DESIGN allows two pages.
- Memory: one page is 16 MB, the second 8 MB; all targets together about 5 MB at the largest size (eight full
  `rgba8Unorm` targets of 372 KB, three strips, light and emissive in `rgba16Float`, two bloom targets). 21 MB
  with one page, 29 MB with two; the limit is 40 MB.

### 4.5 The thermal ladder and the device check

- `.serious` or `-GWEffects minimal`: bloom off, mist band off, the second fog copy off, the weather pass off,
  particles halved, ledge light off. `.critical`: 30 fps as today.
- Before the store: a TestFlight build with `-GWStats YES` on one A12 phone (XR or XS) and one current iPhone.
  Scenes: a storm night with forty creatures, the golden river, the finale. Accept at GPU ≤ 6 ms and CPU ≤ 4 ms
  on the A12. If Louis has no A12 phone at hand, the read budget of 4.3 and the cut order of 6.2 are the
  safeguard, and the plan says so in the round's notes.

## 5. The order of work, as runner rounds

Every round is one call, run in the background:
`scripts/ci/remote-check.sh lanternhold lh-l2-<n><letter> <outdir> build unit ui ui-de release` (labels are
single use; a full round takes 13 to 17 minutes). Rules for every round:

- T1 to T8 and the existing UI tests pass. Until L2-6 the existing shots are taken with `-GWLook 1` and must not
  change; every existing UI test passes `-GWWeather clear` from L2-7 on, so its pictures stay stable.
- New shots in English and German, named `<nn>-<what>-<lang>`; EXIF orientation 8 stripped before use.
- A round is done at `ALL PASSED` **and** after an agent has looked at its shots beside the mock's pictures.
- Commit after every finished step; the round's result and its open points go into `DESIGN.md` as today.

| round | work | tests added or changed | screenshots |
|---|---|---|---|
| **L2-0** base and switch | `LookVersion`, `-GWLook`; `LookValues` (1.2); shader constants to uniforms; the appended uniform fields; strip code path with full rows; then the art merge (1.12) | golden hashes of six look-1 scenes recorded **before** the refactor and equal after it; strides; `DebugArgsTests`; after the merge: no M3 file deleted | the first-day set, unchanged |
| **L2-1** ramp and grade | ten keys, `skyMid`, air, cloud colour (1.1); lift 0.30 and colorise 0.72; night tint; navy lift; vignette; the warm-light saturation (1.4 `lh_grade`) | keys match the mock's fixture; a black pixel at night is `#080A18` ± 1; vignette follows the key; `LightProbeUITests.testFilmstrip` with ten hours | `70-l2-strip-front`, `71-l2-strip-town`: ten hours each, look 1 and look 2 |
| **L2-2** planes and fog | near plane; mist band and fog strips; the three banks, region share, drift; lanes by the mock's hash; castle and valley layout (stage 1, east of 1300); foreground strips; near and mid haze | scene matches `layout_look2` east of the castle; fog region share at 1000, 1220, 2000, 3000; strips drawn and read only in their rows; near parallax; fill and overdraw (4.2) | the five day and dusk scenes of the mock (castle-dusk 1360, court-dusk 1700, square-dusk 3040, town-noon 2800, river-golden 3720); `-GWShowBuffer near`, `mist`, `fog` |
| **L2-3** light | pool squash and fire fall-off; windows; glass gain; cold displacement; fog hue; moon key; lane sky light and moon track; ledge; room rects; foreground ambient; rims; bloom outside emitters | fire pool falls to ember, window pool keeps its colour; stone in a pool is less blue; fog in a pool takes the fire's hue; only a silhouette's top two rows get the ledge; the hall is warm with torches; people have a rim; the three existing light tests updated | front-night (900 at 22:48); the hall at dusk; light lab; `-GWShowBuffer light` |
| **L2-4** the Throat and the creatures | needs the mock's stage 2 and the far painting (1.7); `laneScree`; walls, slit, far castle and its glow; bank glow; creature notes (1.8) | scene matches stage 2 everywhere; no tree, bush or fern between world x 520 and 1240; strides pinned; weaver and heart light offsets; the heart light is not in `LightField`; bank glow frames and Reduce Motion; T1 to T8 untouched | from the wall walk at 1300 toward the slit; lines 2 and 3; the beacon site; the mouth at 600; the shadow land at 200; the creatures at night; the bank's edge |
| **L2-5** effects | section 2, with still air | particles deterministic for (frame, time); counts capped; Reduce Motion stills them; shafts only with a low sun; a faded creature is still a target | dawn shafts in the cleft; fireflies at dusk; town smoke; a brazier close up; pairs 0.5 s apart |
| **L2-6** parity gate | no new feature. Fix what differs. Then default look 2 | new `tools/scenemock/region_stats.py` prints mean value and hue per region of the six mock scenes; the offscreen render must be within 0.02 in value and 8° in hue (where saturation is above 0.15); the night's value targets of `ART-look2.md` (frame mean 0.20 to 0.23, at most 10 % below 0.08, fog cores 0.45 to 0.60, near fir bodies 0.07 to 0.10, lane 0.13 to 0.22, foreground 0.05 to 0.07) | the six scenes beside the mock's PNGs; then the two review lenses (code, player) and the refuter, as the work method says |
| **L2-7** wind | `Core/Weather.swift` (3.1); `windTravel`; everything of 3.2; `castleFlag` | `WeatherTests` (3.7) without the rain cases; the simulation never sees the weather | 60, 61, 62 |
| **L2-8** rain | weather target and pass; streaks, splashes; sheen; puddles; darker air; hissing fires; sound hooks; Reduce Motion | the rain cases of 3.7, unit and GPU | 63 to 67; the rain filmstrip |
| **L2-9** budget and cleanup | reads view and test (4.3); atlas headroom; thermal ladder; look 1 and `-GWLook` deleted; DESIGN.md's planes, budget and launch arguments updated | reads, fill, overdraw, instances, atlas; the whole suite | the full first-day, mid-chapter, finale and audience sets in look 2 |

Notes on the order:

- L2-0 to L2-3 need no art of the shadow land, so they do not wait for the art lane. L2-4 does: it starts when
  `layout_look2.py` holds stage 2. If stage 2 is late, L2-5 and L2-7 move ahead of it.
- `Core/Weather.swift` and `WeatherTests` are pure and touch no file of the renderer, so a second agent can write
  them while the first is in L2-1 to L2-3. More than two lanes do not help: every other step edits
  `Shaders.metal`, `Renderer.swift` or `FrameBuilder.swift`.
- Honest time: ten rounds with two to four runner trips each are 25 to 35 trips, seven to nine hours of runner
  time alone. With two lanes this is two to three working days, if the art lane's stage 2 arrives during the
  first.

## 6. Risks, and what to leave out first

### 6.1 Risks

| # | risk | what happens | guard |
|---|---|---|---|
| 1 | the Swift and Metal uniform structs drift apart | a wrong frame with no error | fields only appended, both structs in one commit, the stride test, and a test that renders the last appended field as a colour and reads it back |
| 2 | the native pass is too slow on an A12 | under 60 fps on the XS Max | the read budget and its test (4.3), the device check (4.5), the cut order (6.2) |
| 3 | the art is still moving: section 13.2 is unwritten, stage 2 of the layout does not exist, the far painting is planned, the look branch is ahead of origin | the port transcribes a layout that changes again | L2-0 to L2-3 need none of it; L2-4 starts from the mock's stage 2 only; positions are never invented in Swift |
| 4 | the warden statue and `keepFar`: `STORY.md` and `ART-look2.md` 12.3 disagree | rework in L2-4 | the lead settles it before L2-4; this plan assumes the statue moves into the Throat's wall |
| 5 | the merge of the look branch drops M3's art | missing sprites, placeholders in the game | 1.12's check after the merge |
| 6 | look 1 changes during the refactor | no reference left to compare with | golden hashes in L2-0 |
| 7 | hit frames: the art lands hits on frame 5, the simulation deals damage when it does today | moving the damage would shift T1 to T8 | the port moves only kick, dust and cue; if the gap shows, it is a tuning task of its own with its own T run |
| 8 | weather leaks into gameplay (the hissing fires, the heart light, the faded creatures) | nights play differently in rain; tuning tests flake | weather is read only by the frame builder; the equal-state test and the grep step (3.7) |
| 9 | readability at night: navy blacks, less lift, rain on top | the player loses creatures in the dark | the value targets, the rain floor of 0.17, unlit value 0.2 and the moon rim kept; the player lens in L2-6 and L2-8 looks for exactly this |
| 10 | strips on other screen shapes | fog cut off at a strip's edge on the SE or the Pro Max | the strip's first row comes from the ground row; a test renders at three sizes through `-GWVirtualHeight` and `-GWScaleOverride` |
| 11 | the ledge light at seams | bright lines where the target ends or where a fade begins | clamp at row 0; alpha threshold 0.5 for "empty"; no ledge on fog, actors or the lane rows |
| 12 | the atlas fills when the final art is larger than the stand-ins | the build fails, or a second page appears unplanned | the 85 % test; the second page is designed (1.10) |
| 13 | existing screenshots become random | UI tests flake by the day's weather | every existing UI test forces clear weather; days 1 and 2 are dry by rule |
| 14 | flashing | discomfort; a rejection risk | no lightning; the puddles' flicker is ± 0.15 at 8 Hz on a few pixels and drops to 4 Hz if a reviewer sees it as flashing; none under Reduce Motion |
| 15 | rain under Reduce Motion has no drops | "is it raining?" | sheen, puddles, haze and sound carry it; accepted |
| 16 | a rain or wind loop counted as music | against Louis' rule | the one-shot fallback (3.6); the lead asks him |
| 17 | Simulator and device differ (half-float targets, branch cost) | a pass on the runner, a wrong picture on the phone | the device check; the read counter is compiled in only for the debug view |

### 6.2 What to leave out first if the frame time is tight

In this order. Each step is one switch in `LookValues` or `RenderSettings`, so a cut is a line, not a rewrite.
The first five are barely seen; from the sixth on the picture loses something.

1. The ledge light's second row (one read less on most pixels).
2. The second, counter-moving copy of fog A.
3. The rain's back depth (the middle and the front carry the rain), then the splashes.
4. The light shafts.
5. The moon key on the mid and near plane (arithmetic only).
6. The whole ledge light on mid and near; keep it on the world plane, where the wet sheen needs it.
7. The foreground as a strip target and the clouds drawn into the sky target (saves fill, no loss in the picture,
   but work).
8. On A12 phones only, as a fixed tier at launch: no mist band, no weather pass (rain as under Reduce Motion),
   no ledge. This is the thermal ladder's `.serious` step made permanent for the oldest chip.
9. Bloom on A12 phones.

Never cut, because they are the look: the near plane, the fog bank behind the world, the ten keys with their
air, the value compression and the night tint, the navy lift, the fires' fall to ember, the cold displacement.
If those do not fit, the answer is not a thinner look 2 but rule 2 of 4.3 done more strictly.
