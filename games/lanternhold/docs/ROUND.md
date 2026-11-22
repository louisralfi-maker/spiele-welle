# Lanternhold: the make-it-round pass (ROUND.md)

Filed 22.11.2026 by the director. Louis played build 396 and said the game still feels raw, like a prototype: not
smooth, the systems do not mesh. He chose to stop new content until what exists feels like a finished game. This file
is the audit's backlog as the critics and the refuter left it: the ten things, the four laws, the fix lanes, the two
waves, what is left on purpose, what was refuted, and the questions for Louis.

**The four laws bind every later step, new content included.**

The material behind it (the critics' files, the feedback inventory, the flow map and 68 film sheets) lies outside git
on the director's desk, `ci-out/director/polish/audit/`; paths that begin with `polish/` point there.

---

AUDIT | 5 blockers and 22 highs hold | scores motion 4, handling 4.5, run 4, feel 4

# Lanternhold polish audit: the backlog (build 429 = be33de3c; code read at lh-round 6c173054/73203d77)

Of 28 blockers and highs, 21 hold as written, 6 hold in a smaller form (M7, H1, R2, R6, F6, F8), and 1 is refuted
(H3). Material: `polish/audit/` (critic-motion, -handling, -run, -feel, refute, inventory, flow, capture). Sheets are
`polish/audit/film/<id>.png`. Code paths are relative to `lh-round/games/lanternhold`. Ids: M = motion, H = handling,
R = run, F = feel. Cost: S = one step (one build, one review, one filtered round); M = two steps.

The seam in one line: every system is finished inside, and every hand-over between them is a one-frame cut, a
silent beat or a word on glass.

## THE TEN THINGS THAT MAKE IT FEEL LIKE A PROTOTYPE (effect per cost, best first)

**1. The figures snap.** (M1 blocker, M6; lane A step A1)
- Feels: the lord slides off at full pace, stops dead and flips in one frame; standing, he pants twice a second, out
  of time with everyone. A cursor, not a man. Seen every second of play (m02-a, m03, m06).
- Fix: start 0 to pace in 0.12 s, brake over the last 4 px, idle held 0.25 s, turn after a 0.07 s hold, pace changes
  over 0.25 s, in the player's travel path only (`Core/SimDriver.swift:126-133`, never `Sim.stepKing`, so bots and
  tuning stay). One breath for every person: 1.15 s / 0.85 s, phase id x 0.37 s; idle builders fidget. On leaving
  the hall he faces the way he came; on day 1, west (R2's cheap half).
- Cost: M.

**2. The lantern moment is three parts, silent, blind and forgetful.** (M3 = H6 = F7, H1 smaller, refuter's missed 1
and 3; B1)
- Feels: numbers flash on before the frame-work (m04-a 02); closing gives the hand nothing; under the lantern every
  mark is hidden, so a closing tap can start a deed the player could not see (m04-c); raising it mid-errand drops the
  errand but not the walk, and he arrives doing nothing.
- Fix: one driver, `veil.light`, for the dim, the Metal block (3 alpha steps) and the SwiftUI layer; pose frame 8 for
  0.05 s, then 9. New `lantern_up` / `lantern_down`. Show the marks under the lantern (drop `lanternMoment == nil`
  from `currentMarks`, `App/GameModel+Touch.swift:879`); the decided deed stays. Keep the errand across the moment
  (`App/GameModel+Lantern.swift:51`; the count is still cut, PAY.md 4). The test helper's lowering tap at (0.08, 0.9)
  goes to an empty spot.
- Cost: S.

**3. Signs pop, and words ride over the walk.** (M2 blocker, H4, F8 smaller, H13; B3)
- Feels: "Talk to Tamsin" on a glass plate rides over the roofs (m03-a 03-15); the bubble, the purse figure, the
  mood arrows and the marks blink on and off, the marks even while he walks; the bubble closes in silence.
- Fix: drop the errand slip (move Saul's hire words into his bubble first); the target's mark holds its pressed
  frame and pool x 1.4 until he arrives. Everything that stays on the world follows one presence rule (quick in with a
  2 px rise, quick out, 12 px hysteresis for the nearest four marks). The bubble close plays the existing pane close.
- Cost: S + M.

**4. A building stands in one frame.** (M4 = F4; A2 picture, D2 sound)
- Feels: the payoff of the count, the best deed in the game, is a sprite swap with a light tick, quieter than the
  seal before it (m05-c 15-16, m11-c-crop 10-16).
- Fix: scaffold 0.12 s more, the existing `wallDust` at the plot's width, swap at the dust's peak, 1 px settle;
  a second dust at the keep if its stage changed. `build_done` re-made with a 70 Hz body and a gravel tail; haptic
  success, then light 0.12 s later; beds x 0.7 for 0.7 s.
- Cost: M.

**5. The night has no weight where the blow lands.** (F1 blocker without its kill part, M11 contact, F5; A3, D1)
- Feels: an arrow or a blade strikes and nothing shows on the body; hits sit 2 to 5 dB under the night bed; every cue
  is full volume inside its radius and nothing outside it, never panned. A man who falls is a pitched-up wall knock
  and blinks out.
- Fix: a 1-frame flat warm flash plus 1 frame at 50 % and 1 px knockback on every hp drop (men: cold grey); a
  fallen man sinks 3 px and fades over 0.45 s. Hits 0.8 / 0.7 / 0.85, fall-off max(0.35, 1 - d/hearing), pan
  +-0.7, battle duck x 0.6; `man_fall` with a heavy haptic.
- Cost: M.

**6. Day 1 runs dry and the end of the day hides in a menu.** (R1 blocker, R2 smaller; E1)
- Feels: by about 11:00 the gold is spent, every mark goes out, and 85-90 s of empty day follow; the only way out is
  four touches deep in the pause sheet, and it cuts the sky from noon to 18:59.
- Fix: on days 1-3, 09:00-17:30, when nothing can be bought and no order is open, Brannock's talk mark returns: "Nothing
  more to build today. Say the word and I sound the horn." A second touch calls the night. `callTheNight` plays the
  dusk in 4.0 s (at most x 30) instead of skipping it. Odile's day-1 line gains "Then go to Brannock: the gate wants
  fire before dark."
- Cost: M.

**7. A near tap at the board throws the count away.** (H2; B2)
- Feels: fast thumb taps drift 4-6 pt toward the lord; the lord wins the tap, the lantern moment opens and every coin
  flies home. Paying coin by coin, the thing that must feel good, punishes the player (m05-e-crop 03-08).
- Fix: while a count is open and 0.6 s after its seal the lord takes no tap; the board's touch area reaches past the
  lord (`countStandGap + 10` px, `App/GameModel+Pay.swift:388-395`).
- Cost: S.

**8. The first five seconds are silent and end in a double exposure.** (F2, M8, M9; C2)
- Feels: every launch opens in silence; 3.5 s of a still flame (hung?); the touch then crosses the night castle, the
  bright hall and the name card at 40 % each (m01-a, m01-c 11).
- Fix: throat and fire beds fade in under the title over 1.5 s, `lantern.wav` on the first step, `lantern_up` on the
  touch. The flame breathes while waiting; the reveal is 1.6 s ease-in-out with a stepped pixel edge. The step in goes
  through the lantern: the mask closes on the flame (0.45 s), black, the hall rises (0.6 s), the name card 0.25 s
  later.
- Cost: S.

**9. The panes are not one family.** (H5, H10, M14, M15, F15, H14; C1, C3)
- Feels: the report's plaques fill amber and tick; the hall's choices, Counsel and Leave are dead glass; the answer
  cuts to the reaction; seven dim values; a 0.97 scale makes the pixel border crawl; report and pause open silently;
  Haptics off does not silence the plaques; Marek's card alone closes on a tap beside it.
- Fix: one pane rule (see the law): 0.25 s in with a 2 px rise, 0.15 s out, one dim, one sound pair, every button a
  `GlassPlaqueStyle` with the Haptics switch passed down; the answer swaps by a fade.
- Cost: S + S.

**10. Dawn: a cut gate, a card over it, no voice, and a plan that looks back.** (M7 smaller, F6 smaller, R3; A5, E2)
- Feels: the gate is open in one frame and the report covers it 0.33 s later in silence; a held night and a lost one
  sound the same; "Taxes 16" is yesterday's gold beside today's doors, and nothing says what today is for.
- Fix: the portcullis slides up (about 0.8 s); the card comes 0.6 s after the gate stands open, with the verdict's
  sound as it lands (bell, or a toll per fallen man); the row becomes "Owed today" with the doors, plus one forward
  line from what Core knows (an unlock, the first night of a new kind quoting Brannock, houses full).
- Cost: S + M.

Next in line, not in the ten: the beds are 6-10 s loops with events baked in (F3, D3); soldiers are invisible by day
(R4, A6); night 1 has no dread (R5 picture parts, E3, B5).

## THE FOUR LAWS

Where two laws touch, the numbers below are the agreed ones. Reduce Motion (RM) is given per rule.

### 1. Motion vocabulary

| token | in | out | use |
|---|---|---|---|
| quick | 0.15 s | 0.10 s | touch answers, the lantern moment, marks, the bubble, the purse figure, pressed states |
| normal | 0.25 s | 0.15 s | panes and cards, the hall's dark and bright halves, swaps inside a pane |
| slow | 0.6 s | - | stage beats: a building standing, the title closing on the flame, the hall rising, the end card |
| settle | 1.2 s | - | camera (as now), ambience, ducks returning, the dawn card's wait |

- Curves: ease-out cubic (0, 0, 0.58, 1) for what enters or answers; ease-in (0.42, 0, 1, 1) for what leaves; a
  critically damped spring for what follows. Linear only for flicker, the time of day, and the lantern veil (HUD.md
  0.15 s / 0.10 s, its tests stay).
- One event, one driver: every layer of it reads the same progress value.
- Entering: from its source (head, lord, door, scaffold), at most 2 game px of travel in whole px (2, 1, 0). Never a
  non-integer scale of pixel art. Never a blend of two pixel sprites: hide a swap under dust.
- Figures: start 0.12 s; brake over 4 px; idle hold 0.25 s; turn hold 0.07 s; pace change 0.25 s; stride = painted
  foot travel (4 px lord and court; archers step every 5 px with a 1 px bob). Idle 1.15 s / 0.85 s, phase id x 0.37 s.
- Blow: wind-up 0.18 s, strike 0.05 s, follow-through 0.12 s. Contact: the struck figure 1 px back and its frame held
  0.05 s, then home; at most once per figure per 0.15 s. A death or exit takes at least 0.4 s.
- RM: opacity only, at quick; no travel, scale, shake or flare; figures keep their holds; idle holds frame A; the
  camera sits on the lord; effects show fewer particles. Sound and haptics never change under RM.

### 2. Grammar of touch and panes

- Ground, tap: he walks; a ring of lantern light at the spot (gold 0xFFC65A, 5 to 9 px in 3 frames, alpha 0.5 to 0
  over 0.3 s; RM: a still 3 px dot for 0.2 s). Touch tick at volume 0.4.
- Drag: as decided (walks on the world; pans under the lantern; in the hall lowers and walks). See question 1.
- Person, tap: he walks, she turns, the bubble opens. Bubble, tap: next line, or close.
- Thing to buy, tap: the board. Board tap: one coin; hold: a stream; 2.0 s untouched: coins home (PAY.md; 3.0 s with
  a warning at 2.0 s is the director's call). While a board is open and 0.6 s after its seal the lord takes no tap.
- Lord, tap: the lantern moment. Lord, hold at night: the flame grows over the 0.35 s charge; during the cooldown it
  gutters and nothing opens on lift.
- Under the lantern: the marks stay visible; a tap on a thing lowers and does the deed (decided); a tap on empty world
  only lowers; the strip snaps to the nearest place or call within 6 strip px and sends him as an errand; the banner
  gives its reason; the gear opens the pause. The errand survives the moment; only a count is cut.
- Panes: come at normal in (0.25 s ease-out, 2 game px rise, no scale); go at normal out (0.15 s ease-in). A pane that
  holds the world has one dim of 0.40, which fades with it and never closes it; a tap on the dim glints the main
  plaque's brass line for 0.25 s. The hall audience keeps its 0.08 veil. Word panes (bubble, mood slip) have no dim
  and close by a tap on themselves, by walking away, or under any card. Swaps inside a pane: 0.15 s out, 0.25 s in.
- Every button: `GlassPlaqueStyle` (amber sweep 0.12 s, selection haptic through the Haptics switch). Main buttons
  at least 52 pt, others at least 44 pt, no `.plain` button anywhere.
- No word, number or plate on the walked world. The two teaching lines (first touch, lord hint) show only while he
  stands, with the presence rule.

### 3. The thread of the run

1. Every system hands over to the next in the world, at the moment it happens, where the lord stands.
2. At every moment one thing in view says "next" (the mark of the day: drawn first, pool x 1.4); one person with an
   unheard line says "why".
3. Never more than 20 s of real time without a deed or a coming threat. When the day is done, the world offers its
   end: Brannock and the horn (days 1-3, 09:00-17:30), the dusk played in 4.0 s (RM: a 0.6 s cross-fade).
4. What is bought appears at once (dust, settle; a recruit at the head of the file at +0.8 s after the seal) and acts
   in plain sight the first night.
5. Every night leaves a trace the next day: rubble, a gap in the file, the hearth's row in wax red.
6. The dawn card is the only place the plan is said in words: what happened, what is owed, one goal for today. It
   comes 0.6 s after the gate stands open.
7. Time is told by the world: the sky, Silas, the lord's lantern breathing from 18:00 (period 3 s to 0.8 s by 19:00,
   10 % toward red), the horn. Never by a figure.

### 4. The ladder of answers, and the sounds

Every deed answers at once for ear, hand and eye, at its size and never larger. The bed is always the quietest thing.

| step | deeds | sound | hand | eye |
|---|---|---|---|---|
| 1 touch | ground tap, a step, lantern up/down, board set, bubble close, pane come/go, plaque press | 0.05-0.3 s, -24 to -20 dBFS, at least 3 dB over the bed, +-4 % pitch | light or soft 0.3-0.5; none for steps, bubble close, lantern down | 1-3 frames, at most 2 px |
| 2 deed done | a coin (count or taxes), a talk line, a hit, a kill near the lord, a lamp lit, a drill hit | 0.15-0.45 s, -20 to -16; a chain climbs +1 semitone per repeat (count to +12, taxes and kills to +7), reset after 1.5 s | soft growing 0.35 to 1 in a chain; medium for a wall blow (at most every 0.3 s) | 1-frame flash, 1 px knockback, 4-6 flakes |
| 3 small triumph or loss | seal, a building stands, a wall below half, a man falls, the dawn verdict, an answer's mood | 0.5-1.4 s, -16 to -13, a low body plus a bright top, never randomised | heavy (seal, fall) or success (built, held night), medium (cracked) | dust 0.6-1.1 s with the swap at its peak, 1 px settle |
| 4 the realm turns | horn, breach, defeat, beacon | 1.5-3 s, -12 to -10 | heavy, then heavy again after 0.12 s (horn rigid, defeat error) | shake 2-3 px 0.45 s (none under RM) |

- One duck rule in `AmbienceMix` (`Core/SoundCues.swift:244`): the deepest active duck wins, never a product.
  Lantern moment and screens x 0.5 (exists); battle within 300 px of the lord x 0.6; step 3 x 0.7 for 0.7 s; step 4
  x 0.25, back over 2 s from 1.5 s; the horn x 0.3 from 0.6 s before it.
- Space: positional cues at volume x max(0.35, 1 - d / hearing), pan clamp((x - lordX) / 320, -0.7, 0.7).
  Beyond hearing a cue does not cut: it falls from 0.35 to nothing over a further half of the hearing distance (the
  director's call on step 0b's M3, 22.11.; built in D1).
- One touch, one tick (the director's call, 22.11.; built in D1): a pane cue within 0.25 s after a plaque press plays
  its sound and no haptic. `paneOpen` / `paneClose` (played from `OverlayView` on the overlay's change, C1) replace
  `cardOpened` / `cardClosed`, which go quiet in the hub, so no call site in another lane's file changes.
- No event baked into a loop; silence on purpose only before the horn, after a breach and on the defeat card.
- Pane pair (law 2 meets law 4): pane come = `tap.wav` 0.55 at the start of the 0.25 s; pane go = `tap.wav` 0.45,
  rate 0.85; bubble close = `tap.wav` 0.3, rate 0.85. Lantern: `lantern_up` 0.55 and soft 0.5 at the touch, under the
  0.15 s ramp; `lantern_down` 0.4 at the start of the 0.10 s ramp. The night raise keeps `lantern.wav` rate 1.3.

Sounds, all made like today (pure Python in `tools/soundsynth.py` or a lane file that imports it, mono, fixed seed,
MANIFEST sha, through `artlock.sh`, budget 4 MB):

| sound | new / re-use | where |
|---|---|---|
| `lantern_up` (glass knock 2.6 kHz + flame swell rising 5 %, 0.30 s), `lantern_down` (lowpass 900 to 300 Hz, 0.20 s) | new | lantern moment, title touch |
| `build_done` (two knocks + 70 Hz body + gravel tail, 1.1 s) | re-make | a building or tier stands |
| `man_fall` (90 Hz thud + mail chink, 0.45 s), `grunt_1..2` (0.12 s, wordless) | new | a man falls / is hit |
| `toll` (bell at rate 0.55, damped, 1.4 s tail) | new | dawn card, once per fallen, at most 3 |
| `wall_crack` (3 kHz split + grit, 0.5 s), `wall_break` (+ 55 Hz sub thud) | new / re-make | wall below half / breach |
| `amb_*` without events; `anvil_1..3`, `chirp_1..6`, `folk_1..3`, `murmur_1..3`, `pebble_1..2`, `drip_1`, `lost_1..3` | re-render / split | the beds plus a scatter player (anvil 3-9 s, birds 1.5-5 s, lost 12-25 s, pebble/drip 6-14 s, murmur 4-10 s) |
| `crowd_up` / `crowd_down` (0.6 s), `straw_thud` (0.1 s) | new | an answer's mood; the drill |
| `bell` 0.5 r 0.9; `gate` 0.6 r 1.05; `lantern` 0.35 r 1.45; `knock` 0.4 r 0.62; `coin_p01..07` | re-use | held night; dawn gate; Silas's lamp; board set; tax coins |

## THE FIX LANES

Five lanes in their own worktrees, one owner per file. A file another lane needs gets a block tagged
`// LANE-<x>: <step>` that the owner leaves alone, or the other lane waits for the owner's step to merge. No wave A
step changes saved state; `Build2SaveTests`, `Build86SaveTests`, `OldSaveTests` and `SaveGameTests` run in every round
(there is no fixture for 396 or 429; add one before any step that touches `GameState`). Rounds stay short and
filtered: the step's tests plus the one film class of its moment (FilmOpening m01-m04, FilmDeals m05/m06/m07/m11,
FilmNight m08/m09/m10/m12), re-shot and compared with the sheet named.

### Step 0: the shared foundation (two builders in parallel, about half a day, before the fan-out)

- **0a Motion** (owner afterwards: the director). New `Core/Motion.swift`: the four tokens, the three curves, a
  `Presence` stepper (alpha toward 0 or 1 at a token, whole-px rise 2/1/0, RM switch from one place), and
  `UI/MotionStyle.swift`: SwiftUI animations from the tokens and an `.lhPane()` modifier (law 2's come and go). Proof:
  new `MotionTests` (curve ends, `Presence` whole at 0.15 s +-1 frame, no rise under RM). No film changes.
- **0b The cue contract and the mix** (lane D's files). New `FeedbackCue` cases, each mapped at once to an existing
  sound as a stand-in: `lanternUp`, `lanternDown`, `paneOpen`, `paneClose`, `bubbleClose`, `plaquePress`,
  `buildStood`, `hit(x)`, `manHit(x)`, `manFell`, `dawnVerdict(outcome)`, `dawnGate`, `boardSet`; a title-beds start
  and stop on `SoundDirector`; `play(_:at:)` with fall-off and pan (`App/SoundDirector.swift:69-82` sets no pan today);
  the one duck rule; a chain helper generalised from the count's coin. Other lanes only call these cues; lane D later
  swaps the files behind them. Proof: `SoundTests`, new `AmbienceMix` duck test (deepest wins), a pan unit test.

### Lane A: figures and the world's beats (the Metal picture)

Owns: `Core/SimDriver.swift`, `Core/Sim.swift` (facing only), `Core/EntityFrames.swift`, `Core/CourtFrames.swift`,
`Core/CourtLayout.swift`, `Core/HallStage.swift`, `App/GameModel+Hall.swift`, `Core/BattleEffects.swift`,
`Core/HordeLook.swift`, `Core/YardLook.swift`, `Core/CastleGrowth.swift`, `Core/FrameDesc.swift`, `Render/*`.
Shared: `SimDriver.callTheNight` (`:164-181`) is a `LANE-E` block.

1. **A1 The walk and the breath** (M1, M6, R2 facing). Ramp, brake, holds, pace change; one breath; builders' fidget;
   facing on hall exit (`App/GameModel+Hall.swift:80`). Proof: m02-a, m02-b (the first frame after a tap shows walk
   frame 0 short of full pace; the stop shows the held idle), m01-h (west on exit); `SmoothWalkTests`,
   `SimDriverTests` (brake ends exactly on target, no overshoot), `AutoplayTests` and `TuningTests` unchanged,
   `RendererTests`/`EntityFramesTests` kingFrame by time updated.
2. **A2 It stands** (M4 = F4 picture). Dust, swap at the peak, 1 px settle, keep's dust, 1 px jolt on damaged and
   rubble; cap 24 to 32. Proof: m05-c 15-22 (dust and settle), m11-c-crop 10-16; `RendererTests` (finished sprite
   0.12 s after `buildDone`), RM still.
3. **A3 Hits land** (F1, F5, M11 picture). `BattleEffects` already watches the horde each frame
   (`Core/BattleEffects.swift:85-110`): add an hp watch and a `.hit` kind. The flash is a new tint mode in the
   emissive pass (`Render/Shaders.metal:183-222`; the night does not darken it, so an unlit creature still flashes);
   1 px knockback; cold grey for men; the fallen man's ghost from his last x; wall plot 1 px on `wallHit`; uneven
   strike holds; a burn spark every 0.5 s on burning lit creatures (R5.4). The small one's fall keeps its timings.
   Proof: `HordeUITests` 220-237 stills (`-GWHorde`) show a flash frame; `FrameBudgetTests` with 35 creatures; a
   seeded late-night film burst with a hit and a fall (new test work; night 1 has `shots:0`).
4. **A4 The hall door** (M5). Into the doorway 6 px with a 0.12 s fade; dark 0.15 s ease-in, hold 0.1 s, bright
   0.25 s ease-out (0.72 s in all); out 8 px walking, then the A1 stop. Proof: m06-a 08-11; `HallStageTests`,
   `HallUITests` 131a at `-GWStageSlow`.
5. **A5 The dawn gate** (M7 smaller). The closed frame slides up 1 px per 0.04 s clipped to the arch, reverse at
   dusk; publish `gateOpenAt` for E2. RM: a 0.25 s fade. Proof: m10-a 20-22.
6. **A6 The soldiers' day** (R4, R6 gap, M10 recruit). Reserves at the bench by the bunkhouse (YARD.md 5), drawing
   only (sim stays at `keepX`), archers left of guards 9 px apart; a recruit fades in at the barracks door (0.3 s) and
   walks to the file; a fallen man's place stays empty that day. Proof: m11-c-crop, m11-d (a man appears);
   `YardUITests`; save tests.
7. **A7 Feet and edges** (M12, M13, M16 court jump). Court stride 4 px; archers step by distance with a bob; a court
   figure more than 240 px off fades out and in. Proof: an 8-frame native crop of Tamsin's foot (m03); m08 archers.

### Lane B: the hand (touch, lantern, count, signs on the world)

Owns: `App/GameModel+Touch.swift`, `App/GameModel+Lantern.swift`, `App/GameModel+Pay.swift`,
`App/GameModel+Collector.swift`, `Core/Town/CollectorTouch.swift`, `Core/LanternMoment.swift`, `Core/LanternRaise.swift`,
`Core/TouchMarks.swift`, `Core/TouchWorld.swift`, `Core/RealmStrip.swift`, `UI/GameView.swift`, `UI/TouchLayer.swift`,
`UI/TalkBubbleView.swift`, `UI/LanternMomentView.swift`, `UI/RealmStripView.swift`, `UI/MoodBannerView.swift`,
`UI/HUDView.swift`, `UITests/TouchSupport.swift` and the film helpers' lowering tap. Shared: `StripCall.size`
(`Core/LanternMoment.swift:276-310`) gets a `LANE-E` block after B1; `closeTalk` (`App/GameModel+Court.swift:334`,
lane E) gets a one-line `LANE-B` block for the bubble close cue.

1. **B1 One lantern instrument** (thing 2). Proof: m04-a 02 (all layers at one alpha), m04-c (marks visible under the
   lantern; the lowering tap lands on empty ground); `LanternMomentTests` (one driver), `LookAroundUITests` 254 (the
   deed stays), new unit (the errand survives raise, lower and background), `LordUITests`.
2. **B2 The count keeps the hand** (H2). Proof: new unit (a tap 6 px from the lord's middle with the board open sets
   a coin), `CountUITests` 175, `PayCountTests`; m05-e-crop re-shot with taps drifting toward the lord.
3. **B3 No words on the walk; one presence** (M2, H4, F8 close). Proof: m03-a 02-16 (no slip; the bubble rises over at
   least 2 frames), m02-a (marks do not blink while he walks), m06-b 12-14, m07-b-crop 30 (the purse figure fades);
   `TouchWorldTests` (12 px hysteresis), `TalkTests`, `CollectorTouchTests`; UI tests that read `touch-slip` changed.
4. **B4 Answers at the spot** (H11, H7, H12, H6's cues for strip, banner and gear, M17). The ring; strip snap as an
   errand; the gear and banner as plaques with the selection haptic; the night hold's charge and gutter; the world
   behind a screen stops (`UI/GameView.swift:165`). Proof: m02-a (ring), m06-g (a strip tap on the petitioner's tag
   enters the hall), m04-d (the flame grows during the hold); strip tests 166b/166c, `LordUITests`.
5. **B5 The evening lantern and the lost tap** (R5.3 = HUD.md 4, H14 stage tap). The lord's glow breathes from 18:00;
   a tap during a stage change runs when it ends. Proof: m08-a/b (the glow's period shortens before the horn);
   `LanternRaiseTests`.

### Lane C: panes and the title (SwiftUI)

Owns: `UI/OverlayView.swift`, `UI/NightGlass.swift`, `UI/TouchPlaques.swift`, `UI/Theme.swift`,
`UI/AudienceCardView.swift`, `UI/DefeatCardView.swift`, `UI/LordEntryView.swift`, `UI/HallStageViews.swift`,
`UI/BuildCardView.swift`, `UI/TitleView.swift`, `App/LanternholdApp.swift`, `Ads/AdViews.swift`,
`Core/Town/TownShow.swift`. Pane cues are played from `OverlayView` on the overlay's change, so `App/GameModel.swift`
stays lane E's.

1. **C1 One pane family** (H10, M15, H5 press state, F15, H14 glint, M16 confirms). `.lhPane()` on every card; dim
   0.40; pane cues; all `.plain` buttons in the owned files to `GlassPlaqueStyle`; the Haptics switch through an
   environment value (`UI/NightGlass.swift:434`); Marek's card stops closing on a beside tap. Proof: m06-b 20/24
   (amber under the finger), m10-a 22 (no scale crawl on the border), m12-b; `ScreenFlowTests`, `AudienceUITests`;
   a still pair with Haptics off.
2. **C2 The first five seconds** (F2, M8, M9). Proof: m01-a (the flame breathes; the reveal edge is stepped), m01-c
   (frame 11 shows the flame closing or black, never three pictures); `TitleUITests` (`title-root` and `lordEntry`
   later).
3. **C3 The answer lands** (M14, H5 swap). Chosen plaque holds amber 0.15 s, others fade 0.15 s, the reaction fades in
   0.25 s after 0.08 s, plate height fixed. Proof: m06-d; `AudienceUITests` (`audience-reaction` wait + 0.35 s).
4. **C4 Marek's gift as coins** (H13). The slip goes; coins arc from the cart on the town's arc. Proof: m12-b/c;
   `AdsUITests`.

### Lane D: sound (the ear and the hand's weight)

Owns: `tools/soundsynth.py` (plus a new `tools/polishsound.py` that imports it), `Resources/Sound/*` with
`MANIFEST.txt`, `Core/SoundCues.swift`, `Core/Feedback.swift`, `App/SoundDirector.swift`, `App/FeedbackHub.swift`,
`Core/WindSound.swift`, `Tests/SoundTests.swift`. Step 0b is this lane's first step.

1. **D1 The night's weight** (F1 mix, F5 sound, F11 crack, F10 sound half). Hit volumes, fall-off and pan on every
   positional cue, battle duck, `man_fall` + heavy + x 0.7, grunt (at most every 0.5 s), `wall_crack` + medium,
   `wall_break` re-made with the second heavy and the step-4 duck. Proof: `SoundTests`, `FeelTests`, duck test; the
   loudness table of inventory.md re-measured (hits at least 3 dB over the night bed).
2. **D2 Deeds at their size** (F4 sound, F6 sounds, F12, F16, F17, F18, F21, F9 sync, F7 files). `build_done` with
   success + light; `toll`; `gate` at dawn; tax coins climb (+7 cap, reset 1.5 s, soft 0.3 to 0.7); board set;
   Silas's lamp; door creak 1.0 with the bed switch at the latch; ad press; steps on the contact frames at 0.5;
   `lantern_up` / `lantern_down` behind the 0b cues. Proof: `SoundTests` (MANIFEST, budget), `TownShowTests`.
3. **D3 Beds without baked events** (F3, F20). Re-render, split, scatter player, ducked with the beds; wire or drop
   `banner_snap` / `shutter_rattle`. Proof: MANIFEST sha, budget, `AmbienceMix` tests, `WindSoundTests`.
4. **D4 The day's small voices** (F14, F13, F19 if budget allows). `crowd_up` / `crowd_down` 0.15 s after a choice's
   seal; drill bow, `straw_thud`, pell knock; the bright tier at 44.1 kHz. Proof: `SoundTests`, `YardUITests` cue log.

### Lane E: the thread of the day

Owns: `App/GameModel.swift`, `App/GameModel+Court.swift`, `App/GameModel+Town.swift`, `Core/CourtTalk.swift`,
`Core/CourtLines.swift`, `Resources/Court/lines.json`, `Resources/Story.xcstrings`, `Resources/Localizable.xcstrings`,
`UI/ReportCardView.swift`, `Core/DawnReport.swift`, `Core/ReportCard.swift`, `Core/TouchThings.swift`,
`Core/CameraFraming.swift`, `Core/TownLamps.swift`, `Core/TownLife.swift`, `Core/Front/YardTuning.swift`,
`Core/Balance.swift` and `Core/Battle.swift` (only if the director takes R5's timing). Tagged blocks:
`SimDriver.callTheNight` (lane A), `StripCall.size` (lane B, after B1).

1. **E1 The end of an empty day** (R1, R2 line). Brannock's offer as a line with a condition (unheard, so marked) and
   a second touch that calls the night; the 4.0 s dusk in the `LANE-E` block; the pause button routed the same; Odile's
   second sentence. Proof: a new film burst on day 1 at 11:00 with 9 gold (Brannock marked, the sky ramps, the horn),
   `FirstDayUITests`, `callTheNight` unit tests pinning the same end state; nothing saved (the offer is derived).
2. **E2 The dawn card** (R3, M7/R3/F6 timing, F6 verdict). The card 0.6 s after `gateOpenAt` (until A5 lands: 0.6 s
   after `.dawn`), input closed meanwhile; `dawnVerdict` as it lands; "Owed today" with doors, yesterday in the detail;
   one forward line. Proof: m10-a 20-22 (the gate seen open before the card), stills 45-report-en and
   46-report-sample-en; `ReportCardTests`, report UI tests.
3. **E3 Night 1's sighting** (R5.2). Danger lead 60 to 140 px for 2.0 s at the first lit creature, the flame-lowering
   cue with it. Proof: m09-a (the first creatures in the middle third of the view); `CameraFramingTests`.
4. **E4 Traces and the yard's voice** (R6 cheap, R9, R11). Hearth strip call and the wax-red report row; YARD.md 7's
   lines; `fenceReach` 8 to 20 with the drill's next loose 0.2 s early; the archer half marked only with a free post.
   Proof: `YardUITests`, `ReportCardTests`, `TouchWorldTests`; m11-e/f.
5. **E5 The evening's sign** (R12). Silas starts at the courtyard lamps at 18:00; the set-piece pull takes the first
   lamp when the lord is within 400 px. Proof: m08-a-crop.

## WAVE A (about two days, four builders; the next TestFlight build)

| builder | day 1 | day 2 |
|---|---|---|
| 1 | 0a Motion, then C1 one pane family | E1 the end of an empty day (in lane E's worktree) |
| 2 | 0b cue contract and mix | D1 the night's weight, D2 deeds at their size |
| 3 | A1 the walk and the breath (adopts 0a's tokens when they land) | A2 it stands |
| 4 | B1 one lantern instrument, B2 the count keeps the hand | B3 no words on the walk; one presence |

This covers things 1 to 7 and most of 9 (C3 waits), the sound halves of 4 and 5, and the dawn gate's sound. Thing 8
(the title) leads wave B; a fifth builder, if the Mac allows, takes C2 in wave A. Merge order: 0a and 0b, then A1, B1, B2, C1,
then the rest; one joined round (the three film classes) before the TestFlight build.

## WAVE B (in this order)

C2 the first five seconds; E2 the dawn card (with A5 the gate); A3 hits land; D3 beds; A4 the hall door; B4 answers at
the spot; C3 the answer lands; A6 the soldiers' day (then E4's gap); E3 night 1's sighting with B5; E4; D4; A7; C4; E5.

## LEFT ON PURPOSE

- R7 the reach light at a purchase (M): wait for the re-shot film; A2's dust and A6's recruit may be enough.
- R2's day-1 mark filter and the chandler's mark: a new tutorial rule; judge on the re-shot first day after A1 + E1.
- M10's slower small-one fall: the feel lens keeps its tuned timings; only the recruit and the fallen man change.
- F10's 0.10 s realm hold at a breach: it touches the step clock; the sound and the second haptic are enough now.
- F9's surface sets, F19 if the budget is tight, F20 deletion (only if not wired), M16's leftover small cuts not
  listed above.
- Director's calls, not polish: H9 count wait 3.0 s with a 2.0 s warning (a PAY.md number); R5's first-wave timing
  (moves T1-T8); R8 collector pace 18 to 45 and Odile's taxes line; R6 switching on the hearth rule (balance and save
  content; it reads as a new system, so leave it off now).

## DROPPED (refuted)

- H3 "every drag looks": the walking drag and the lantern pan are decided (notes-b3 27-29, 16.11. 22:08); see question 1.
- H1's "a tap under the lantern only lowers": the deed is decided (no dead tap); only the hidden marks were fixed.
- F1's kill effect: kills already fall to soot (1.4 s) or dissolve (0.8 s); the film's smear is an unlit fall.
- F6's "dawn is silent": the first-light bell rings at 05:00; only the gate and the card are silent.
- F8's "the bubble opens in silence": it opens with tap 0.55; only the close is silent.
- M7's wider dawn glow: the scene already brightens over about 14 s; only the gate and the card's time hold.
- M2's fading errand slip (the slip is dropped, H4); M3's ease-out (the veil stays linear); H6's reuse of
  `lantern.wav` (F7's own sounds win); M4's sprite cross-fade (F4's swap under dust wins); R4's file "before the
  barracks" (YARD.md 5's bench wins).

## QUESTIONS FOR LOUIS

1. **The drag.** Today a drag walks the lord; with the lantern up a drag looks around. The same finger moves the
   picture in opposite directions. a) keep it; b) a drag always looks around, walking only by tap; c) a drag walks,
   and a two-finger drag looks.
2. **Voices.** People speak in bubbles with a soft tap. a) keep the tap only; b) one short wordless hum per person,
   never syllables; c) wordless sounds only for crowds and soldiers (cheers, a grunt on a hit, an "aye" from a recruit).
3. **The end of an empty day.** When nothing is left to buy: a) Brannock offers the horn, a second touch calls the
   night, the dusk plays in 4 s (the plan, E1); b) the day itself runs faster once nothing is left; c) both.
4. **The far goal.** Nothing says there are 20 nights until day 11. a) the horn ribbon says "Night 3 of 20"; b)
   Hesper says it once on days 1-3 ("Twenty nights, the old songs say, and then the King comes"); c) both; d) keep it
   hidden.


## LOUIS' ANSWERS (22.11.2026, 21:03; interviewed, he took the director's pick four times)

1. **The drag stays as it is.** A drag walks the lord; with the lantern up a drag looks around. (B4 builds on this.)
2. **Voices: wordless sounds for crowds and soldiers only** (cheers, a grunt on a hit, an "aye" from a recruit). No
   speech, no hum per person. If a sound reads as artificial it is taken out again. (D1's grunts and D4 may go ahead.)
3. **The end of an empty day: Brannock offers the horn.** When the day's work is done he waits at the horn; a touch
   calls the night and the dusk plays in 4 s. The day does not run faster by itself. (E1 as written.)
4. **The far goal is said twice:** Mother Hesper says it once in the first days, and the horn's ribbon reads
   "Night 3 of 20". (Lane E; the ribbon is a pane, so the rule against words on the walked world holds.)
