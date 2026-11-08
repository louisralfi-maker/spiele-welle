# Comet Cargo: design

Launch a cargo rocket, drop each stage at the right moment, and release every satellite exactly inside a glowing orbit
ring. Higher rings pay more, but satellites still aboard when the rocket stalls are lost.

## Louis' decisions (08.11.2026)

- Genre wish: Louis liked Space Frontier 1 and 2. This is NOT a copy of them. Never use their name, look, circular timing
  dial, astronauts boarding in a line, colonies, galaxy map, evolving rocket skins or their ad hooks (cargo rescue,
  astronaut rescue). Our twist is the cargo: satellites released into orbit rings, plus a ring network around one planet.
- Look: mid-century space-age poster (see "Look").
- Cargo still aboard at apex is lost (press your luck).
- Scope of 1.0: one planet with 15 rings. Moon and other worlds come later as updates.
- Name: Comet Cargo. Bundle id `com.louisherwick.cometcargo`.

## Pillars

1. Two timing skills interleaved in one short flight: stage drops (tank gauge) and satellite releases (ring crossings).
2. Press your luck: release now for sure money, or carry the cargo higher for more.
3. Visible progress: the rings around the planet fill with your satellites; upgrades make the rocket bigger and faster.
4. Fun in the first 10 seconds. A flight lasts 20 to 90 s. One hand, portrait.

## Look (held to the end)

Mid-century space-age poster: warm cream and teal sky at the launch site, deep navy space with soft stars, coral and
mustard accents, rounded retro rockets with fins and portholes, a light paper grain. Never a real agency, flag, logo or
real rocket. Version 0.1 draws everything procedurally with Canvas in this palette; Recraft paintings come in the art step.

| Token | Hex | Use |
|---|---|---|
| cream | #F4E9D8 | sky at the ground, cards |
| skyTeal | #7FB7B2 | lower sky |
| deepTeal | #2E6E73 | upper sky, buttons |
| navy | #14213D | space |
| night | #0B1020 | deep space, text on cream |
| coral | #EE6C4D | rocket accents, launch button, danger |
| mustard | #F2B544 | rings, perfect, coins |
| paper | #FFF8EC | text on dark |
| ink | #1D2433 | text on light |

Type: SF Rounded (`.rounded` design), heavy weights for numbers, `monospacedDigit()` on counters.

## Controls (portrait, one hand)

- Hangar: the big "Launch" button.
- On the pad: tap anywhere to ignite (no countdown).
- In flight:
  - tap anywhere outside the buttons: drop the current stage, the next one ignites at once. On the last stage the tap does
    nothing except a small shake of the gauge;
  - the release button (bottom right, a circle of at least 88 pt with a satellite icon and the count left): release one
    satellite now;
  - pause button (top left, 44 pt): pause sheet with "Resume" and "Abort flight" (back to the hangar, no pay).
- Going to the background during a flight pauses it.

## Flight model (Core, deterministic)

- `FlightSim` is a value type with a fixed step `dt = 1/120 s`. Inputs (`.ignite`, `.dropStage`, `.release`) are queued
  and applied at the next tick. The same rocket and the same input ticks always give the same flight (unit-tested).
- State: altitude `h` (km), speed `v` (km/s), time, phase (`pad`, `burning`, `spent`, `coasting`, `ended`), attached
  stages, fuel of the burning stage, satellites aboard, events (stage ratings, deliveries, losses).
- Mass model: `a = thrust / mass - g` while a stage burns; `mass` = dry plus remaining fuel of all attached stages plus
  `satellites × satelliteMass`. Fuel burns linearly over the stage's burn time. Upper stages are smaller (each about 60 %
  of the mass of the one below). Dropping a stage removes its mass, so the next stage pushes harder: that kick must be felt.
- `spent`: the burning stage is empty but still attached (not the last stage): no thrust, dead weight, `a = -g`. The
  gauge blinks. The player can still drop it.
- After the last stage burns out: `coasting` until `v <= 0`, which is the apex. Then `ended`; satellites still aboard are
  lost.
- Gravity `g` is a constant. No drag needed; add a light one only if the tuning targets need it.

### Stage drop rating (fraction `f` of fuel left in the dropped stage)

| Rating | When | Effect |
|---|---|---|
| Perfect | `f <= 0.05`, or up to 0.20 s after burnout | instant kick +6 % of `v` |
| Great | `0.05 < f <= 0.12` | kick +3 % of `v` |
| Good | `0.12 < f <= 0.30` | none |
| Early | `f > 0.30` | none (the fuel left is wasted) |
| Late | more than 0.20 s after burnout | none |

Guidance widens the Perfect and Great windows by 10 % per level (relative; max level 5 = +50 %).

### Rings

- 15 rings at 20, 35, 55, 80, 110, 150, 200, 260, 330, 410, 500, 600, 720, 860, 1000 km.
- Each ring is a band `h ± w(h)`. Choose `w(h)` so the tuning targets below hold (a ring crossing must stay fair at every
  speed the rocket reaches).
- Release rating by `d = |h - ring| / w` at the release tick: Perfect `d <= 0.25` (pay ×2), Great `d <= 0.6` (×1.5),
  Good `d <= 1.0` (×1). Outside every band: Lost (pay 0). Guidance widens Perfect and Great by 10 % per level.
- A released satellite leaves the rocket either way, so its mass is gone (dumping one outside a ring is a legal trick).
- Base pay of ring `k` (0-based): `round(5 × 1.33^k)` coins (5 … 270).
- Ring network: each ring has 5 slots. Every delivery fills a slot. The 5th delivery completes the ring once: bonus
  `10 × base pay`, and the ring turns gold. Deliveries beyond 5 still pay normally.

### Tuning targets (each one a unit test in `Tests/TuningTests.swift`)

1. Starter rocket (2 stages, 2 satellites aboard the whole flight, every upgrade level 0), Perfect drops: apex 105 to
   135 km, ignition to apex 18 to 35 s.
2. Maxed rocket (5 stages, 6 satellites aboard, engines 10, tanks 10, guidance 5), Perfect drops: apex at least 1050 km,
   ignition to apex at most 95 s.
3. For both rockets: every ring the rocket crosses with `v >= 0.5 km/s` is crossed in 0.5 to 3.0 s (time inside the band).
4. Dropping every stage Early (`f = 0.5`) gives an apex at least 15 % lower than Perfect; dropping every stage 1 s after
   burnout gives at least 5 % lower.
5. For the starter rocket, each single engine or tank level adds 3 to 12 % apex over the level before.
6. Economy bot (Perfect drops; releases each satellite at the center of a ring, keeping one for the highest ring it can
   still reach by its own apex estimate; buys the upgrade with the best apex gain per coin after each flight): its first
   delivery into ring 15 comes after 90 to 180 flights.

## Economy and upgrades

| Track | Levels | Effect per level | Price of level L → L+1 (start, tune to target 6) |
|---|---|---|---|
| Engines | 0 … 10 | thrust ×(1 + 0.1 L) | round(20 × 1.42^L) |
| Tanks | 0 … 10 | fuel and burn time ×(1 + 0.08 L) | round(20 × 1.42^L) |
| Stages | 2 … 5 | one more, smaller upper stage | 150, 900, 4000 |
| Cargo bay | 2 … 6 satellites | one more satellite (heavier) | 60, 300, 1200, 4000 |
| Guidance | 0 … 5 | timing windows +10 % | round(50 × 1.8^L) |

Coins come only from deliveries and ring bonuses. Show prices and coins with a coin icon, never a currency symbol.

## Screens

1. **Hangar** (home):
   - top bar: coins (left), settings gear (right);
   - the network: the planet with its 15 rings, drawn as concentric circles (radius on a log scale so all fit), delivered
     satellites as small dots orbiting slowly (up to 5 per ring), rings above the best apex dim and dashed, completed
     rings gold; best altitude below it;
   - five upgrade rows: icon (SF Symbols for now), name, level pips, effect text, buy button with price (disabled when too
     expensive or maxed);
   - the big coral "Launch" button at the bottom.
2. **Flight**: the scene (Canvas) plus the HUD.
   - Sky gradient by altitude (cream and teal at the ground, deep teal around 30 km, navy at 100 km, night with stars above
     300 km), clouds between 3 and 15 km, stars fading in above 60 km with slow parallax, the ground at the bottom whose
     horizon curves more and more with altitude (the planet's curvature).
   - The rocket sits at about 60 % of the screen height; the world scrolls. The camera shows a vertical span of
     `max(25 km, v × 3 s)` (smoothed), so a ring is visible about two seconds before the rocket reaches it.
   - Rings: horizontal glowing mustard lines across the screen with a faint band for `± w` and a brighter center line; a
     label at the left with ring number, altitude and pay; satellites already delivered there drift along the line.
   - Lines for "Best" and "Last" apex (thin, dashed).
   - Dropped stages tumble away and fall off screen; released satellites pop out sideways, unfold their panels and glide
     onto the ring line; a lost satellite tumbles away dimmed.
   - Rating pop-ups near the rocket ("PERFECT +24").
   - HUD: altitude (top center), coins of this flight (top right), pause (top left), the tank gauge of the burning stage on
     the left edge (about 40 % of the screen height) with its zones marked (Perfect at the bottom in mustard, Great, Good)
     and blinking red when empty, stage pips below it, the release button bottom right, "Tap to launch" on the pad.
3. **Results**: each delivery (ring, rating, pay), the stage ratings in a small row, lost satellites, the total rolling
   up, "New best altitude" and "Ring complete" badges, the "Collect" button back to the hangar. A short pause (about 1.2 s)
   at the apex comes before the results.
4. **Settings** (sheet): sound on/off, haptics on/off, reset progress (with a confirmation).

Navigation is a small state machine in the model (hangar → flight → results → hangar); no NavigationStack.

## Feel (version 0.1)

`Audio/Feedback.swift` is the one hub every action goes through: `Feedback.shared.play(.ignite / .stageDrop(rating) /
.release(rating) / .lost / .coin / .ringComplete / .button)`. Version 0.1 plays haptics only (UIKit feedback
generators) and respects the haptics setting; synthesized sounds come in the juice step. Reduce Motion: no shake, no
flashes, calm end states.

## Code layout (`games/comet-cargo/`)

- `project.yml`: name `CometCargo`, portrait only, iPhone only, iOS 17. Pattern: `games/hello/project.yml`.
- `App/`: `CometCargoApp.swift`, `GameModel.swift` (`@MainActor @Observable`, owns the save, the screen and the flight
  driver), `DebugArgs.swift`, `SaveStore.swift` (JSON in Application Support, written after changes and on background).
- `Core/` (plain Swift, no UIKit or SwiftUI, every type `Sendable`): `FlightSim.swift`, `Rocket.swift` (config from
  upgrade levels), `Rings.swift`, `Ratings.swift`, `Economy.swift`, `SaveGame.swift` (Codable, `version`, new fields
  optional), `Autopilot.swift`.
- `UI/`: `HangarView.swift`, `NetworkView.swift`, `FlightView.swift`, `FlightScene.swift` (Canvas drawing),
  `ResultsView.swift`, `SettingsView.swift`, `Palette.swift`, `Components.swift`.
- `Audio/Feedback.swift`.
- `Resources/Localizable.xcstrings`: English source plus German for 0.1; the other six languages come in step 8. Every UI
  string is English in code (`Text("Launch")`, `String(localized:)`).
- `Tests/`: `FlightSimTests`, `TuningTests`, `EconomyTests`, `SaveGameTests`.
- `UITests/`: `FlightUITests`.

The flight runs on a display-link driver in the model: it steps the sim at the fixed rate with an accumulator, the views
read its state. Rendering never mutates state.

## Debug launch arguments

| Argument | Effect |
|---|---|
| `-GWReset YES` | start from a fresh save |
| `-GWAutoplay YES` | the autopilot plays every flight: ignites, drops each stage Perfect, releases at ring centers |
| `-GWCoins <n>` | set the coins |
| `-GWUpgrades mid` / `max` | set upgrade levels (mid = engines 5, tanks 5, 4 stages, 4 satellites, guidance 2) |
| `-GWNetwork demo` | fill the rings with sample deliveries and a best apex of 420 km |
| `-GWScreen results` | open the results screen with a fixed sample flight |

## Accessibility identifiers

`hangar-launch`, `hangar-coins`, `hangar-best`, `upgrade-<track>-buy` (tracks: engines, tanks, stages, cargo, guidance),
`settings-open`, `flight-root`, `flight-release`, `flight-pause`, `flight-altitude`, `results-root`, `results-total`,
`results-collect`. Every button has a VoiceOver label.

## UI smoke test (`UITests/FlightUITests.swift`)

Screenshots are `XCTAttachment(screenshot:)` with `lifetime = .keepAlways`, named `<nn>-<what>-<lang>` where `<lang>` is
`ProcessInfo.processInfo.environment["GW_LANG"] ?? "en"`.

1. `testFirstFlight`: `-GWReset YES -GWAutoplay YES`; shot `01-hangar`; tap `hangar-launch`; shots `02-liftoff` after
   about 1.5 s and `03-climb` after about 6 s; wait for `results-root` (up to 120 s); shot `04-results`; tap
   `results-collect`; the hangar's coins are no longer 0.
2. `testMidGame`: `-GWReset YES -GWCoins 5000 -GWUpgrades mid -GWNetwork demo -GWAutoplay YES`; shot `05-hangar-mid`;
   launch; shot `06-space` after about 20 s; wait for the results.

## Later steps (not in 0.1)

Recraft art and app icon, synthesized sounds, onboarding hand, ads (rewarded "Double it" on the results, "Free booster"
in the hangar; interstitial after results, paced), the other six languages, a date-seeded daily launch, store assets.
