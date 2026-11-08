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
    satellite now. Its touch area is a 128 pt square, also while it is disabled, so a near miss never drops a stage;
  - pause button (top left, 44 pt circle in a 60 pt touch area): pause sheet with "Resume" and "Abort flight" (back to
    the hangar, no pay).
- Ignite, drop and release fire when the finger touches down, not when it lifts, so how long the finger rests never
  shifts a rating. Two drop taps in the same sim tick drop only one stage.
- VoiceOver: the scene is a button ("Launch" on the pad, then "Drop stage") with an action; the release button has one too.
- Going to the background during a flight pauses it. A flight that already reached its apex is settled at once.

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
- A rocket that is never dropped also ends: when it falls back (`v <= 0`) while a spent stage is still attached, the
  flight is over; the stages above it were never used. The results show "Stages never dropped" for them.
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
- Each ring is a band `h ± w`. `w = min(cap, max(2.8 + 0.018 h, 0.45 s × v))` with the rocket's speed `v` at that
  moment: slow rockets get the base width, a fast rocket's band spans 0.45 s of flight on each side of the centre line, so
  every crossing lasts about 0.9 s at any speed (Perfect about ±0.11 s). `cap` is 45 % of the gap to the nearest ring (or
  the ground), so bands never touch. The scene draws the band at the current speed, so on screen a fast rocket's band
  keeps the same height (the camera shows 3 s of flight).
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
3. For both rockets: every ring the rocket crosses with `v >= 0.5 km/s` is crossed in 0.8 to 3.0 s (time inside the band).
4. Dropping every stage Early (`f = 0.5`) gives an apex at least 15 % lower than Perfect; dropping every stage 1 s after
   burnout gives at least 5 % lower.
5. For the starter rocket, each single engine or tank level adds 3 to 12 % apex over the level before.
6. Economy bot (Perfect drops; releases each satellite at the center of a ring, keeping one for the highest ring it can
   still reach by its own apex estimate; buys the upgrade with the best apex gain per coin after each flight): its first
   delivery into ring 15 comes after 90 to 180 flights.

## Economy and upgrades

| Track | Levels | Effect per level | Price of level L → L+1 (start, tune to target 6) |
|---|---|---|---|
| Engines | 0 … 10 | thrust ×(1 + 0.1 L) | round(20 × 1.42^L); level 0 → 1 costs 30, so the first flight buys one |
| Tanks | 0 … 10 | fuel and burn time ×(1 + 0.08 L) | round(20 × 1.42^L); level 0 → 1 costs 30 |
| Stages | 2 … 5 | one more, smaller upper stage | 150, 900, 4000 |
| Cargo bay | 2 … 6 satellites | one more satellite (heavier) | 60, 300, 1200, 4000 |
| Guidance | 0 … 5 | timing windows +10 % | round(50 × 1.8^L) |

Coins come only from deliveries and ring bonuses. Show prices and coins with a coin icon, never a currency symbol.

## Screens

1. **Hangar** (home):
   - top bar: coins (left), settings gear (right);
   - the network: the planet with its 15 rings, drawn as concentric circles (radius on a log scale so all fit), delivered
     satellites as small dots orbiting slowly (up to 5 per ring), rings above the best apex faint, the next ring to reach
     dashed in mustard, completed rings gold; below it the best altitude and "Next: Ring n · h km" with its pay;
   - five upgrade rows: icon (SF Symbols for now), name, level pips, effect text, buy button with price (disabled when too
     expensive or maxed);
   - the big coral "Launch" button in a bar below the rows (never on top of them); on the 874 pt iPhone 17 Pro all five
     rows fit above it, smaller screens scroll.
2. **Flight**: the scene (Canvas) plus the HUD.
   - Sky gradient by altitude (cream and teal at the ground, deep teal around 30 km, navy at 100 km, night with stars above
     300 km), painted clouds between 3 and 15 km (six different silhouettes, every second round mirrored, each its own
     height), stars fading in above 60 km with slow parallax, the ground at the bottom whose horizon curves more and more
     with altitude (the planet's curvature); from about 6 km up the planet's disc carries a painted surface (seas, cloud
     bands, a few islands; a seamless tile, squashed by the grazing view and finer the higher the rocket gets) under a
     navy veil and a pale haze at the limb. The launch smoke stays above the ground and billows sideways along the pad.
   - The rocket's reference point is the cargo hatch, the base of the nose (the top of the top stage): its altitude is the
     one a release counts. It sits at 60 % of the screen height and never moves when lower stages drop; the stages hang
     below it. Mustard ticks mark it on both sides. The world scrolls. The camera shows a vertical span of
     `max(25 km, v × 3 s)` (smoothed), so a ring is visible about two seconds before the rocket reaches it.
   - Rings: horizontal glowing mustard lines across the screen with a faint band for `± w`, a brighter Perfect strip with
     thin paper edges (as wide as the real Perfect window) and a brighter center line; a label at the left with ring
     number, altitude and pay, drawn above the released satellites so they never hide it (above the line, or below it
     while above would put it under the HUD's top bar; as wide as its title needs; dimmed while a rating pop-up covers
     it); satellites already delivered
     there drift along the line (including this flight's, once
     they arrive; a ring completed in flight turns gold).
   - While the rocket carries satellites and is inside a band: the band, its label plate and its center line light up, the
     hatch ticks grow, and the release button gets a mustard rim and pulses; while a release would be Perfect, the center
     line glows and the rim and ticks turn gold. Reduce Motion: colour only, no pulse.
   - Lines for "Best" and "Last" apex (thin, dashed), and the predicted apex "Apex ≈ h km" in coral, `h + v² / 2g`: it
     rises live while a stage burns and is exact while coasting; then rings above it dim (out of reach). Its plate never
     goes up under the HUD's top bar (FlightView measures the bar's bottom and passes it in `SceneState.hudBottom`); the
     line itself stays at the apex.
   - Dropped stages look like the stage they were (stripe, nozzle, fins on the bottom stage), fall away and tumble (no
     tumbling with Reduce Motion), with a puff of smoke at the separation; released satellites pop out sideways at the
     hatch, unfold their panels and glide onto the ring line; a lost satellite tumbles away dimmed.
   - Rating pop-ups above the rocket ("PERFECT +24"), drawn for 1.4 s while they rise; a new one starts at least 32 pt
     clear of every pop-up still on screen, risen ones included (`SceneEffect.popupLift`), so two never overlap.
   - Drop cue next to the rocket: a slim fuel bar with the same zones beside the bottom stage; in the Perfect window the
     stage's stripe flashes mustard and a "Drop!" tag appears (alternating coral once the stage is burnt out).
   - Once the cargo is gone and the last stage coasts, nothing can change any more: the flight runs 3× faster (a "≫" next
     to the speed) and the apex pause shortens to 0.6 s.
   - HUD: altitude and speed on a dark capsule (top center), coins of this flight (top right), pause (top left), the tank
     gauge of the burning stage on the left edge (about 40 % of the screen height): a warm orange fuel column that drains,
     the zones along its edges and as a ruler on the right (Perfect at the bottom in mustard, Great in teal, Good in
     paper); in the Perfect window it glows and pulses; when empty it blinks mustard and coral through the grace time,
     then coral; on the last stage the zones disappear. Stage pips below it, the release button bottom right (with the
     painted satellite), "Tap to launch" on the pad in the empty sky above the rocket (at 36 % of the height, centred,
     at most the screen width minus 130 pt so it never reaches the gauge; a long translation shrinks to as little as 60 %
     on one line).
3. **Results**: each delivery (ring, rating, pay), the stage ratings in a small row ("Stages never dropped" when some
   stayed unused), lost satellites, the total rolling up, "New best altitude" and "Ring complete" badges; below the card
   the ring progress of each ring delivered to ("Ring 4" with five slots, the new ones in mustard, gold plus the bonus when
   the flight completed it) and the next upgrade with a progress bar; the "Collect" button back to the hangar (it arms
   after 0.6 s, so a late flight tap cannot skip the report). A short pause (about 1.2 s) at the apex comes before the
   results.
4. **Settings** (sheet): sound on/off, haptics on/off, reset progress (with a confirmation).

Navigation is a small state machine in the model (hangar → flight → results → hangar); no NavigationStack.

## Feel (version 0.3)

### One hub

`Audio/Feedback.swift` is the one hub every moment goes through: `Feedback.shared.play(.ignite / .stageDrop(rating) /
.release(rating) / .lost / .coin / .coinTick / .ringComplete / .newBest / .button / .refused)`. Each `FeedbackCue` names
its sound (`SoundCue`) and its vibration (`HapticPattern`); the hub plays both. The stack is adapted from the starter
kit (Piston Empire's feedback stack, without its engine voice):

- `AudioHub`: one `AVAudioEngine`, six player nodes taking turns (cues overlap), session `.ambient` with
  `.mixWithOthers` (the ring/silent switch mutes the game; the player's own music keeps playing). Every cue is made at a
  fixed 44.1 kHz mono format and the mixer converts it, so a route change never changes a pitch. The session comes up and
  every cue is synthesised in the background at launch (`.task` on the root view). Behind the Sound switch.
- `CueSynth`: the cues, rendered in code into samples (fixed-seed noise, biquad filters, struck partials), each normalised
  to its `peak`. No audio files, never music.
- `HapticHub` and `HapticScore`: authored Core Haptics patterns as plain data (`playsHapticsOnly`, so they play on silent
  like the system's haptics and never touch the audio session). The engine stays warm during a flight
  (`flightBegan` / `flightEnded`). Behind the Haptics switch. A device without a Taptic Engine is a silent no-op.

| Moment | Sound | Vibration |
|---|---|---|
| Ignition | short low rumble burst: low-passed noise and a falling 78 → 44 Hz sine through a soft clipper, a gritty mid band, 30 ms swell, gone in about a second | hard kick and a 0.6 s rumble that swells and fades |
| Stage drop | mechanical clunk (pitch-dropping thunk, metal click, housing ring) and 50 ms later the pop of the separation (a burst of band-passed air) | heavy tap and a crisp one |
| Perfect drop | the same, brighter click and ring, plus a two-note chime (G6, D7) | harder tap, the pop, a bright tick |
| Early or Late drop | the plain clunk | one soft tap |
| Release | latch click and a soft whoosh (band-passed noise sweeping 600 → 2100 → 1400 Hz) | crisp tap and a faint breath |
| Perfect release | the same with a chime (E6, B6) | crisp tap and two bright ticks |
| Lost satellite | soft falling blip (880 → 330 Hz) and a smaller echo | three taps falling away |
| Total rolling up | a light glassy tick per change, at most every 65 ms | one light crisp tap per tick |
| Coins (buy, Collect) | two coins meeting | two light taps |
| Ring complete | two struck bells 90 ms apart (1568 Hz, then 2093 Hz, each with inharmonic partials at × 2.76 and × 5.4) and a faint sheen: a signal, no melody | two bright taps and a short swell |
| New best altitude | shimmer: thirty tiny high pings rising and thinning out over bright air | ten fine ticks |
| Button | soft tap | soft tap |
| Drop tap on the last stage | dull thunk | dull bump |

### Juice

- A tiny screen shake: 4 pt over 0.45 s on ignition, 3 pt over 0.25 s on each stage drop, decaying; the scene zooms in by
  just enough that the shake never shows its edges. None under Reduce Motion. The shake is the only jolt (the scene
  itself no longer shifts on a drop).
- Rating pop-ups grow in from 1.35× to their size over 0.15 s as they rise and fade (`FlightScene`).
- Results beats: the badges spring in (0.15 s), "New best altitude" shimmers once with its sound (0.35 s), the total
  rolls up with ticks (0.45 to 1.55 s; after a new best from 1.05 to 2.15 s, once the shimmer's ten haptic ticks are
  through, so the ticks never pile up), Collect arms (0.6 s), and a ring completed this flight turns gold with a short
  gold burst (a spreading ring, rays, sparks; 0.9 s) and the ring chime (1.7 s, or 2.2 s after a new best: always after
  the roll-up's last tick; `ResultsView.rollStart` and `ringBeat`). Big effects stay rare: the burst only for
  a completed ring, the shimmer only for a new best.
- Reduce Motion: no shake, no pulses, no shimmer, no burst, the total at once without ticks; the results play only the
  ring chime (or the new-best sound) once.

### First-flight hints

No text walls: a tapping hand (a pointing hand pressing down, with a mustard ring spreading from the fingertip) and at
most two words. Each hint shows at most once per flight and one at a time, ends at the player's first success with it,
and stops for good after three settled flights (`SaveGame.hintFlights`). The save remembers `hintLaunchDone`,
`hintDropDone` and `hintReleaseDone` (new in 0.3; older saves decode them as false, a player with three or more flights
never sees them).

| Hint | When | What | Success |
|---|---|---|---|
| `hint-launch` | on the pad | the hand taps the corner of "Tap to launch" | the ignition |
| `hint-drop` | the tick the first stage's fuel first enters the Perfect zone, until the drop or until a drop would be Late | the sim runs at 0.35×, a pulsing "Tap now!" and the hand over the scene | a Perfect or Great drop |
| `hint-release` | the tick the rocket first enters a ring band with a satellite aboard, until the release or the end of the band | the sim runs at 0.35×, the hand taps the release button | a delivery into a ring |

The slow motion lives in the flight driver (`timeScale`): the sim keeps its fixed tick; hints start and end on the exact
tick after the step that meets their condition, and the time still owed to the sim in that frame is re-expressed at the
new speed. Hints are off with `-GWAutoplay YES` and with `-GWSkipOnboarding YES` (UI tests that play by hand).

### Tests

- Unit: `FeelTests` (every cue short, finite, deterministic, at its peak, click-free; every vibration a valid pattern;
  the cue mapping; the shake stays tiny and covered by its zoom; the hint hand; the roll-up; the results beats never
  pile up and the ring chime is two strikes), `FlightDriverTests` (launch
  hint learned at ignition; the drop hint starts on the exact tick and runs at 0.35×; a missed drop hint leaves and stays
  pending; the release hint; never with the autopilot), `SaveGameTests` (hint flags, three-flight limit, old saves).
- UI: `testManualControls` passes `-GWSkipOnboarding YES`. `testFirstFlightHints` (`-GWReset YES`, no autopilot): the
  launch hint shows (shot `09-hint-launch`), tap to launch, wait for `hint-drop` (shot `10-hint-drop`), tap, the hint
  leaves; wait for `hint-release` (shot `11-hint-release`), tap `flight-release`, the hint leaves; the results list one
  stage drop and at least one delivery row. `testResultsRingBurst` (`-GWScreen results`, the sample with a new best and
  a completed ring): shot `12-results-ring` 2.5 s in, while the gold burst plays.

## Ads (version 0.4)

Ads only, no purchases. The code is Piston Empire's proven ad code (`Ads/`), the same packages and versions
(GoogleMobileAds from 13.11.0, GoogleUserMessagingPlatform from 3.1.0, pinned in `Package.resolved`).

- **Ids:** AdMob app id in the build setting `GAD_APPLICATION_IDENTIFIER` (project.yml, read by
  `Resources/LaunchInfo.plist`, which also carries Google's SKAdNetwork list). Unit ids in `Ads/AdConfig.swift`. Debug
  builds always use Google's test units; release builds run ads only with the real ids.
- **Launch:** `AdConsent.runOnce()` from the first screen's task: Google's consent form (UMP, EEA and UK only), then
  Apple's tracking question (only if never answered), then the SDK starts (`maxAdContentRating = .general`) and preloads
  one rewarded and one interstitial ad (retries 4 s … 5 min after a failure). Nothing waits for it: the hangar is usable
  at once. A flight in progress pauses on its own while the tracking question is up (the app is inactive); the consent
  form does not make the app inactive, so a flight already running is paused when it comes up
  (`AdConsent.isPresentingForm`, `GameModel.pauseFlightForOverlay`) and the pause card resumes it afterwards.
- **Rewarded, "Double it":** the one rewarded offer. On the flight report, above Collect, with "Plays a short video ad"
  visible under it, armed with Collect (0.6 s) and never sooner than 0.6 s after it appeared (an ad that loads during
  the report cannot catch a thumb on its way to Collect), only for a booked flight that earned coins, once per flight,
  only while an ad is loaded. The buttons sit on an opaque night bar; the report fades out above it. The coins are added only in
  the SDK's reward callback (`GameModel.grantDouble`), and the save is written at once; once the ad has closed the total
  rolls on from the number on screen to twice the flight's coins, a "×2" tag shows by "Total" and a coin sound plays. The
  offer is used up when the video really starts: a video closed early changes nothing and the button is gone; an
  expired ad or one that fails to present leaves the offer standing, and the button comes back once a fresh ad has
  loaded.
- **Interstitial:** only when the player taps Collect on the flight report (`AdPacing`, pure rules over a monotonic clock):
  none before 3 minutes of play in the session (foreground time), none in the player's first three flights ever (the
  4th report is the first that may), then at most one every 210 s, none while a first-flight hint is still taught, none
  over a sheet, none on a report where "Double it" played its video (`AdMoment.rewardedThisReport`), none within 60 s
  after a rewarded ad closed. Time with an ad on screen does not count as play. An expired interstitial (loaded over an
  hour ago) is reloaded without using up the 210 s slot.
- **Settings:** "Privacy policy" (`settings-policy`, always shown, App Review 5.1.1(i)) opens
  `AdConfig.privacyPolicyURL` in Safari; "Privacy choices" (`settings-privacy`) shows under it when UMP says privacy
  options are required; it opens Google's privacy options form. The sheet scrolls when the medium detent is too short.
- **Privacy:** `Resources/PrivacyInfo.xcprivacy` as Piston Empire: `NSPrivacyTracking` false, no tracking domains, no
  collected data of our own (Google's SDKs ship their own manifests); reasons for UserDefaults (CA92.1) and the system
  boot time (35F9.1, the pacing clock). `NSUserTrackingUsageDescription` in all 8 languages in
  `Resources/InfoPlist.xcstrings`.
- **Tests:** `AdPacingTests` (every pacing rule with the clock and counters injected, the rewarded report and ad time
  included; Double it in the model: offered only after a paid flight, doubles once, saves, Collect ends it, no ad no
  reward and the offer stands). UI: every test passes `-GWNoAds YES`
  except `testDoubleReward`, which uses `-GWFakeAds YES`.

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
- `Ads/`: `AdConfig.swift` (ids, `AdPolicy`), `AdConsent.swift` (UMP form, tracking question), `AdManager.swift` (SDK,
  rewarded, interstitial), `AdPacing.swift` (the interstitial's rules).
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
| `-GWNoAds YES` | no ads at all: no SDK start, no consent form, no tracking question (every UI test but one) |
| `-GWFakeAds YES` | debug builds: no SDK; a rewarded ad is always loaded and grants at once (tests, screenshots) |
| `-GWAdsNoFill YES` | debug builds: every ad load fails, as offline |
| `-GWConsentEEA YES` | debug builds: the consent form as a player in the EU sees it |

## Accessibility identifiers

`hangar-launch`, `hangar-coins`, `hangar-best`, `upgrade-<track>-buy` (tracks: engines, tanks, stages, cargo, guidance),
`settings-open`, `flight-root`, `flight-scene`, `flight-release`, `flight-pause`, `flight-altitude`, `pause-title`,
`pause-resume`, `pause-abort`, `results-root`, `results-total`, `results-collect`, `results-delivery`, `results-lost`,
`results-drop`, `results-unused`, `results-network`, `results-double`, `settings-policy`, `settings-privacy`. Every button has a VoiceOver label.

## UI smoke test (`UITests/FlightUITests.swift`)

Screenshots are `XCTAttachment(screenshot:)` with `lifetime = .keepAlways`, named `<nn>-<what>-<lang>` where `<lang>` is
`ProcessInfo.processInfo.environment["GW_LANG"] ?? "en"`.

1. `testFirstFlight`: `-GWReset YES -GWAutoplay YES`; shot `01-hangar`; tap `hangar-launch`; shots `02-liftoff` after
   about 1.5 s and `03-climb` after about 6 s; wait for `results-root` (up to 120 s); shot `04-results` after 2.4 s (the
   roll-up is over); tap
   `results-collect`; the hangar's coins are no longer 0.
2. `testMidGame`: `-GWReset YES -GWCoins 5000 -GWUpgrades mid -GWNetwork demo -GWAutoplay YES`; shot `05-hangar-mid`;
   launch; shot `06-space` after about 20 s; wait for the results.
3. `testManualControls`: `-GWReset YES -GWUpgrades mid`, no autopilot; tap the screen (ignite), wait for the altitude,
   tap `flight-release`, tap the screen (drop), shot `07-manual`; pause (the altitude stands still), resume; wait for the
   results, shot `08-manual-results`; exactly one `results-drop` and at least one `results-delivery`.
4. `testFirstFlightHints` and `testResultsRingBurst`: see "Feel", "Tests" (shots 09 to 12).
5. `testDoubleReward`: `-GWReset YES -GWAutoplay YES -GWFakeAds YES -GWSkipOnboarding YES`; fly; after 2.4 s shot
   `13a-double-offer` (Double it, its "Plays a short video ad" line and Collect, in every language); tap `results-double`;
   the total (digits of `results-total`'s label) doubles and the button goes away; shot `13-double`; Collect; the
   hangar's coins equal the doubled total.
6. `testFilmstrip` (English only, skipped when `GW_LANG` is not `en`): `-GWReset YES -GWUpgrades mid -GWAutoplay YES`; a screenshot about every 1.2 s from
   launch to the results, named `film-<nn>`, for the fun check.

## Later steps (not in 0.1)

Recraft art and app icon, synthesized sounds, onboarding hand, ads (done in 0.4: "Double it" and the paced
interstitial; Louis decided against a "Free booster"), the other six languages, a date-seeded daily launch, store
assets.
