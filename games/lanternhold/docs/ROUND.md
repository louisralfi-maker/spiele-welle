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
| settle | 1.2 s | - | camera (as now), ambience, ducks returning |

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
   end: Brannock and the horn (days 1-3, 09:00-17:30), the dusk played in 4.0 s.
   The director's calls after step E1 (22.11.): the called dusk eases out (it runs fast through the afternoon and slow
   into the horn, so the sky answers the touch within a second); under Reduce Motion the 4.0 s stay, since it is time
   passing, shown by the world, with no shake and no flare; the 4.0 s hold from any hour (no cap on the pace); the
   offer is a standing offer, so Brannock keeps his mark until the night is called.
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
- The director's calls after step D1 (23.11.), the newer word where they differ from the lines above and from the
  tables below:
  1. A blow (`hit`, `manHit`) is heard one screen far (440 px, was 240). Beyond its hearing a cue gives only its
     faded sound: no haptic and no answer duck.
  2. Kills do not chain. The chain is for coins only (the count to +12, taxes to +7), with pitched files, because
     the player's `rate` stretches time and keeps the pitch. For the same reason every lower or higher variant a
     table names by a rate is rendered as its own small file and played at rate 1 (D2); `bell` and `gate` play as
     made.
  3. `cardOpened` / `cardClosed` do not go quiet: they are an alias of the pane cues (the same sound, hand and
     one touch, one tick). Of a card cue and a pane cue within 0.25 s only the first plays, the other is dropped
     whole. So a deed whose overlay does not change (a talk bubble, an errand, a slide turned) keeps its answer
     until each caller has a cue of its own.
  4. The budget is 5,000,000 bytes over every wav in `Resources/Sound`, every file counted, until D3 has re-made
     the beds; then back toward 4 MB.
  5. The bed is the quietest thing by numbers: the beds that play together sum to at most -24 dBFS undecked, and
     every step 1 cue sits at least 3 dB over that sum (D2, by the volume numbers only; the title's beds are
     C2's).
  6. The battle duck answers heard blows within 300 px, with a memory of 1.2 s, not creature positions.
  7. `man_fall` plays at rate 1; the 0.7 in its row is the step 3 duck.
  8. The step's sync with the contact frames waits for A1b (it needs a contact phase from lane A); the ad offer's
     press (F21) is looked at after C1 is joined.

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

### The director's calls after steps E1b, B2, A1b, D2 and C1 (23.11.)

The newer word where it differs from the four laws above. Each group names its law. Nothing here has been seen or
heard on a phone yet.

Law 1 (motion), after A1b and C1:

1. At the stop, the 2 px foot slide (A1b F8), the camera's landing step after the brake and after short taps (F2/P3)
   and the legs on very short stops (P1) are accepted until a phone shows them. A braking cap for the camera and the
   test's tolerance at the agreed number are riders for A7. The world's end (`Realm.walkEnd`) stops a drag dead: A7.
2. An errand that starts at once (`stopWalking()` within 6 px of the thing) stops him dead from pace (P5): lane
   B's, a rider in B1's part 0, else B4.
3. A plaque's fill runs linear, 0.15 s in and 0.10 s back (law 2's 0.12 s is gone), and it holds the pressed look
   0.15 s after touch-down even on an early lift, so a quick tap shows the whole fill once.
4. A swap inside a pane is sequential: the old face goes in 0.15 s, the pane cuts its size while it is empty, the new
   face comes in 0.25 s. Never two faces at once. Cross-fades left inside panes are mended in C3.
5. The runner's frames stand 0.13 to 0.30 s apart and cannot catch a 0.10 s close. Such a close is proven by the code
   and `MotionTests`, and checked on a phone.

Law 2 (touch and panes), after B2 and C1:

6. The count: the numbers stand in PAY.md's table and its rule 4 (B2). A ground tap away keeps the 2.0 s wait and
   gives no warning (B2 F3). The guard after the seal stays 0.6 s (F7). The warning tick's weight (0.5 against the
   home tick's 0.3) and a person beside the lord at an open board losing to his body are phone checks.
7. Panes (C1): one dim at 0.40 that never closes a pane; the audience keeps its 0.08 veil, which takes taps in
   silence. A tap beside a pane makes the main plaque's line glint for 0.25 s with a tick (`bubbleClose` as a
   stand-in until lane D gives it its own). The pane cues play on the change of the pane shown; one pane straight to
   another plays one `paneOpen`. A pane that stands at the first frame gets no come and no cue: C2.
8. The Dynamic Island's band in landscape takes no touch; that is the system's, not the game's.
9. Lane B's plaques use the Glass styles with no cue of their own (C1-7): into the briefs of B3 and B4.

Law 3 (the thread), after E1b:

10. The called dusk keeps its cubic ease (it is a time-lapse). The walkers' 58 px a frame in its first frames (F2) is
    a phone check; a quadratic ease is one line in `Dusk.ease`. The dusk's frame time is clamped to 1/20 s in the
    small step "one step path for the dusk", after E2.
11. "Then the King comes." stays. Hesper's line on the far goal may come again, unmarked, on days 2 and 3. Her day-1
    mark against the hall's four-mark cap is checked in the joined film round and on a phone. New words are English
    only until the store pass.
12. The end of the `LANE-E: E1b` block in `UI/HUDView.swift` sits between the `Text` and its two modifiers; B1's
    part 6 moves the comment.

Law 4 (answers and sounds), after D2:

13. D2's numbers stand where they differ from the text above: the ground tap 0.55 (was 0.4); pane close and bubble
    close 0.55 from `tap_low`; the board set `knock_low` 0.42; `lanternUp` 0.42 (the brief said 0.55); `lampLit` 0.5
    (the brief said 0.35); the beds' ceiling -24.5 dBFS (was -24); the tax coins climb a semitone a coin up to +7 and
    fall back after 1.5 s, their hand 0.3 to 0.7 (was 0.35 to 1); the toll at most one per 0.9 s, the verdict's gap
    1.0 s, the heavy hand only with the first.
14. The card pair answers as the pane pair, and of a card cue and a pane cue within 0.25 s only the first answers.
    The sound folder's budget is 5,000,000 bytes (4,205,440 in 63 files).
15. `buildDone` and `buildStood` are placed (hearing 900 px, the plot's x). A2 plays `buildStood` at its swap and
    takes the thinner's `buildDone` out in the same commit.
16. For a later step of lane D: the 13 old rates (L7; the defeat horn's 0.8 and the broken aura's bell 1.5 were
    probably meant as pitches), a test of the latch path (L2), the trim computed anew per loop (L3), the glint's own
    sound, and whether `paneClose` within 0.25 s after a `plaquePress` stays silent ("one touch, one tick"; decided
    after the phone check of C1's F6). For C2: the title's beds sum to about -20.2 dBFS against the game's air under
    -24.5, a dip of about 4 dB at the hand-over.

17. **After the join (law 1 and law 4).** The follow's stiffness is written once, in `Motion.followOmega` (6.0);
    `Camera.followOmega` reads it. Steps A1b and C1 each closed step 0a's leftover from their own side, and the join
    did not compile (round lh-rnd-16, mended in 14034f3c). A leftover names one owner. A tap beside a pane takes the
    bubble close's level, whatever lane D sets; no test of lane C pins a number of lane D.

18. **After step E2 (law 3, the dawn card).** The card's wait is law 3's 0.6 s after the gate stands open, on the
    model's clock (`dawnCardDelay`); it is not the settle tempo's 1.2 s, and law 1's table no longer lists it
    there. A continued launch brings no dawn card, no verdict cue and no ads' gate: the save is always the dawn
    snapshot, so "after a dawn save" would mean every launch (step E2b takes E2's replay out). The line forward
    keeps its order: an unlock first, then Brannock's first-night line, then the full houses; the hounds' line
    does not reach the card while the middle line unlocks on day 3, and that is accepted. The tolls have one
    owner, lane D's `DawnVerdict`; the model reads its delays (E2b). Brannock's line on the card carries the
    horn's glyph or none, never the warning triangle (E2b). A brief names the narrow case exactly, or what must
    not happen.

19. **After step A2 (thing 4, a building's finish).** A2's timing stands: the old picture for 0.12 s, the swap under
    the dust, the new sprite 1 px high settling at quick, one answer (`buildStood`) at the swap for the standing
    nearest the lord, none within 0.4 s of the last. The settle's 0.15 s and the Reduce Motion fade's 0.15 s count as
    quick's in: the new building enters. Puffs and motes instead of the `wallDust` shards stand. The dust's look does
    not: an even row of equal, nearly white puffs reads as a string of pearls; step A2b makes it uneven clumps, a
    burst and two ground tones (at least 70 % of the foot covered at the swap, at most 12 pieces a work). A pin on
    cover is no pin on a look: the director looks at the sheet before a look counts as done. The dead site lantern
    that fades over the new building goes to lane B's B3; the day gate's jolt on an unchanged frame, the dust's share
    of the frame's particles and the keep's dust on a film go to A3; a chimney's plume born full-length is backlog;
    lane D's stale comments beside the thinner go to D3.

20. **After step B1 (thing 2, the lantern moment).** The instrument stands: one driver (`LanternVeil.light`) for the
    dim, the block (three alpha steps), the strip, banner, gear and numbers, and the lord's arm (frame 8 for 0.05 s,
    then 9); `lanternUp` at the raise and `lanternDown` once on every way down; the marks stay under the lantern; an
    errand survives the moment. The gate's two mends are accepted (the block's share rounds to the nearest third; a
    card opened from the moment lets both layers leave together in 0.10 s). Part 0's cause is accepted: the empty
    board's 5.0 s runs out on a slow runner before the test's tap lands. Open, and where it goes:
    the hall still runs the moment on two drivers (pose and block at once) and goes into B3 as a bounded part, with
    `// LANE-B` blocks in lane A's `Core/HallFrames.swift` and one line in `App/GameModel+Hall.swift`, nothing else in
    the hall, so thing 2 is whole in the next build; the word slip that replaces a mark in one frame under the
    lantern, and a kept errand's slip, go to B3 (it removes the slips); the lantern's glow and lift follow the light
    (B3); the two tests that branch on what they should assert (B3); the call strip's own 0.3 s against the moment's
    strip and the stop within 6 px go to B4; GameView's body re-evaluating per ramp frame is backlog; the stipple
    third against a wash, the walking lord's arm dropping in one frame and both sounds are phone checks; the 0.2 s of
    bare world between the moment leaving and the pause pane is checked at C2's verification. The shared test helper
    `launchAtTheBoard` was left racing the same 5.0 s; the director mended it in the join (no wait for a still lord,
    the count's own word that he stands, a second board on a slow runner, never under the freeze `back`, which holds
    a let-go board for good).

21. **After step C2 (thing 8, the first five seconds).** Verified GREEN at 7dad35c3 (round lh-rc-19 on it: build,
    `TitleStepInTests`, `PaneFamilyTests`, `MotionTests`, Title + FilmOpening, FirstDay; the whole unit suite ran on
    fb95223e in lh-rc-18, the join round runs it on the merged head). The sheets `C2/m01-c-gate.png` and
    `C2/m01-a.png` looked at: title, stepped mask on black, the hall dim from black, the hall whole, then the name
    card; no frame holds the title and the hall together. The calls: (1) C2 is accepted and joined as it stands; the
    seam of the two roots is closed in its shape (one timeline `StepIn`, no cross-fade). (2) The one tagged block in
    lane B's `UI/GameView.swift` (`lhApplyWorldStill`, written only when the value flips) is accepted; lane B leaves
    it. (3) `lanternUp` sits 0.5 dB under the title's beds: law 4 holds, the mend is lane D's (D3: at the title's
    touch `lanternUp` stands at least 3 dB over the beds through the duck rule, never a louder cue). (4) Under
    Reduce Motion the hall rises from black in 0.25 s and the title closes in 0.45 s: a named exception, a whole
    screen coming from black takes the normal tempo. (5) Leaving the app at the title and coming back raises nothing
    (the root lowers the lantern moment and resumes), but on the join with B1 the hall's own scene-phase handler
    still raises the moment under the title, so `lanternUp` and `lanternDown` sound at the title: B3 closes it
    (while `lhWorldStill` holds, the hall's handler raises nothing; the root's lowering stays as a net; a check).
    (6) Three look faults the director saw on the sheets, and five small things, go into the follow-up step C2b
    (lane C, from 7dad35c3): the reveal begins with a cut from the wait's soft glow (about 92 x 64 game px) to a hard
    window of 116 x 82 (P3); the mask's end radius 340 is far past the 281 that covers the 17 Pro's window, so the
    swell's settle and half the close run off the screen (P4); the hall is mounted in the same moment the reveal
    starts, a gap of 1.2 s inside the swell (P5); the name card shows on the film about 1 s after the hall is whole
    although the probe says 0.25 s (to prove with a mark on the card's first drawn frame); the mask's rows rebuilt
    per frame (L5), `StepIn.hallWarmSeconds` unnamed (L6), a line outside the tagged block in
    `UITests/FilmOpeningUITests.swift:46` (L7), `panesOpen` and `takesTouches` without a caller (L2), a kept tap
    during the reveal with no answer until its end (P6). (7) The Lord, Ads and Slides UI classes did not run since
    C2: the join round runs them. (8) Phone checks: every sound of the opening, the hand, the reveal's feel, the
    0.10 s of the flame alone (P7), whether the masked close hitches (0.44 s lost on the runner), the name card's
    wait, leaving at the title and coming back, the gear-to-pause gap (first build of the sheet 139 ms; if it shows,
    C3 builds the sheet once, hidden, while the title stands).

22. **After step E2b (the dawn card's loose ends).** Verified GREEN at 948d8699 (round lh-re-14 on it: build, the
    whole unit suite, FilmNight + FirstDay); three files, all lane E's, no block in another lane's file. The calls:
    a continued launch brings no dawn card, no dawn cue and no ads' gate (`resumeDawnCardAtLaunch` is gone; law 3
    says so now); the tolls have one owner (the model plays lane D's `DawnVerdict.cues(fallen:)`,
    `GameModel.dawnTollGap` is gone); Brannock's line carries no glyph, because the glyph set has no horn (the
    still `E2b/p7-giant-line.png` looked at: the warning triangle is gone, the line is whole above the footer's rule
    at the 17 Pro and at the mini). Accepted as it stands. Riders: a pin that Brannock's line has no glyph and the
    comment at `App/GameModel.swift:357` go to E3; `DawnVerdict.cue(fallen:)` has no caller in the app any more,
    lane D keeps or drops it in D3. Phone check: a real cold launch of a saved realm (the title, then the day with
    no card and no interstitial).

23. **After step A2b (the standing's dust reads as dust).** Verified GREEN at ab486753 (round lh-ra-19; the gate
    mended the tone, the thinning and the gaps). The director looked at both sheets: at the wall the row of white
    balls is three to four uneven grey lumps, dark under light, with a ragged top, which hold together and climb as
    they thin; it reads as dust. At the house the dust is a grey-taupe band along the foot, told apart from the lit
    plaster but quiet at whole-scene size. The director's calls:
    - The town's dust stays as it is; the tone rule (no channel above the lit plaster) stays. The standing is marked
      by the sound, the settle and the echo; the dust is the small part. A phone decides: if it is too little there,
      the town's dust gets a higher alpha in step A3 (which shares the effect budget), nothing else.
    - The big house changing its shape above the dust in one frame is by design.
    - Works over 72 px (field 66 %, market and tavern 59 % cover, the open part at the corners) are accepted for now;
      step A3 films one 90 px work, and if its corners read bare the piece cap for works over 72 px goes up there.
    - Puffs touching side by side on wide works and a stacked puff up to 5 px higher: accepted (the picture, not the
      brief's wording, is the measure).
    - Left: a pin that the puffs form 3 to 5 groups (low); the burst's first 0.12 s at real speed and the keep's
      dust (phone).

24. **After step C2b (the reveal reads as one swell).** Verified GREEN at a1e0f181 (round lh-rc-22; the gate moved
    the swell's start to 82, the glow's opaque reach, and made the Debug probe mark a presented frame). The director
    looked at both sheets: the wait's glow, then a window of the glow's own size, then 135, then 206 with dark
    corners, the last corner sliver, whole. It is one swell with its settle on the screen and no hitch (the reveal
    lost 0.000 s, longest 0.012 s without the burst; C2 was 2.665 / 2.162). On the handover still the ring lies soft
    over the night and the picture shows only under the glow's solid part. The swell's end is computed from the view
    (281 on the 17 Pro and the mini, 252 at 667 pt); a touch during the swell finishes it in 0.25 s. The director's
    calls:
    - The 0.15 s in which the glow goes out by opacity over the picture (F6) is the brief's own form and stands:
      opacity at quick is law 1's allowed fade, and no scaled pixel art is in it.
    - The name card's time (F1): the app's frames hold the law (0.30 to 0.33 s from the whole hall to the card's
      first presented frame); the runner's film shows 0.55 to 0.6 s. A phone decides. If it is late there, step C3
      draws the warm card visibly for one frame under the black cover.
    - The breath's one stall of about 0.4 s while the title's 21 PNGs decode on the main actor (F3): a phone decides;
      if the flame is seen to freeze, the decode moves off the main actor in step C3.
    - A touch late in the swell answered only in the corners (F4) and the close's lost time under a screenshot burst
      (F5): phone checks, nothing to build.
    - Left: the 0.15 s handover and the settle's ease are not on moving film (the runner's frames stand 0.24 s
      apart); the 2.0 s ceiling path is unit-pinned only; the unseen card pre-build is checked only on the runner.

25. **After step B3 (no words on the walk; one presence).** Verified GREEN at 7a6794c3 (round lh-rb-19 ALL PASSED on
    the gate's head; the lane's full UI classes ran on the builder's 5076d0fa in lh-rb-17 and lh-rb-18). Joined
    locally as a4b55979; rounds lh-rnd-28, 29 and 30 test the join. What the director saw on the sheets: the audit's
    walk carries the plate "Talk to Tamsin" over the roofs in every frame; B3's walk carries no word, and Tamsin's
    own mark stands over her, pressed, until he arrives. On the day-3 walk no mark blinks. The purse figure comes and
    goes translucent. Saul's bubble carries his offer with "Take him on" in italic under it. Thing 3 is done as far
    as a runner can show.
    - The director's call on Saul's deed line: a tap on his bubble while the deed waits does the deed (it says the
      second touch in words, so it is also a place to touch). Step B3b.
    - Lane D's table row for `bubbleClose` (`Core/Feedback.swift:17`) names the wrong place: the cue is played once
      from `stepPresence`, so also beside `paneOpen` when a card closes a bubble, at the horn and at dawn. Step D3
      corrects the row and listens whether the two stack (the 0.25 s drop rule).
    - The 0.5 s under the title before `lhWorldStill` is true (L1): step C3 gives the root a title signal.
    - The hall's rim emissives stay at full colour for the 0.10 s a mark takes to go (L4/P9): lane A's `HallFrames`,
      a rider for step A4.
    - Into B3b with the deed: the deed line reading `touch` unobserved (L3). Riders for step B4, so that B3b stays
      a focused step: a slip that can start during a turn or a brief stop (L2/P6); the staying mark's step from
      pressed to plain in one frame at arrival (P7); the same speaker's next line swapping text and plate in one
      frame (P8); the dead `ErrandSlip` fields and the per-frame arrays (L5); two purse figures overlapping while the
      lantern moves during a tick (P5).
    - Not on film (P4): a five-thing swap of the marks, a mood arrow's coming, a Reduce Motion burst, the bubble's
      rise (runner frames stand 0.29 s apart, the rise takes 0.15 s). Unit-pinned; a phone decides.
    - Phone checks: the bubble rising, not popping; the marks on a walk past many things; the arrows; the teaching
      slips leaving when the lord starts; leaving at the title with a saved realm and coming back (no lantern sound);
      the moment a talk errand arrives (mark out, bubble in; P3); the walking row's glide with two groups.
    - The lesson: a change that makes things start at alpha 0 can empty another test's proof (the gate's M2 in
      `Tests/PaySignTests.swift`: an absence test that could no longer fail). The unit suite on the join catches
      failures, not emptied proofs; a reviewer has to look for them.

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
   **A1b The walk's loose ends** (added 23.11. after A1's reviews; the director's calls). The stop closes the
   stride (the landing step draws the standing pose, no wide stride directly before it); a drag and the hall's
   walker start, change pace and brake like a tap walk; the camera eases onto a standing goal (its step never
   grows, never reverses, never falls from a visible speed to nothing in one step); the hall's lord and the wall
   guards on the one breath; FigureMotion uses Motion's curve and tempos. Lane A also owns `Core/FigureMotion.swift`,
   `Core/Camera.swift` (the follow) and `Core/HallFrames.swift` from here on. Under Reduce Motion the figures keep
   the walk, the ramp, the brake and the breath; a turn is stop, flip, 0.07 s hold, ramp.
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
