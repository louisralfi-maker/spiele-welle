# Front lane (branch `claude/lh-front`)

The night and the dark side, in Core (docs/REALM.md sections 3 to 5). One heading per step: what exists, the hooks
into existing files (so the join can apply them again on the rebuilt game), the rounds, what is open and what waits for
the join.

## front-1: being there counts (14.11.2026)

Louis, 14.11.: "Dabei sein zählt: wo der Burgherr steht, kämpfen seine Leute besser und halten länger. Kein Kampfmenü,
man rennt dorthin, wo es brennt." Spec: REALM.md section 3.

### What exists (all new files of this lane)

- `Core/Front/FrontTuning.swift`: every number of the rule in one place, carried as `Balance.front` (presence radius 90,
  speed ×1.25, harm ×0.5; a wall's braziers catch while he stands on it, elsewhere within 24 px in passing, one in 4 s
  (fix round 1); touch 6 px, throw 60 px, shaken 8 s, grace 1.5 s; the present bot's values; the dawn report's
  thresholds). Tuned on the runner from the spec's starting values (below).
- `Core/Front/FrontState.swift`: the saved state (`FrontState`: shaken, grace and relight timers, the last throw and
  the last relight as stamps for the picture, tonight's tally), the report's front half (`FrontNightReport`) and its
  lines (`FrontLine`). Every field decodes with a default; a bad plot or an unknown creature kind is dropped on load.
- `Core/Front/FrontNight.swift`:
  - `LordAura`: what the battle asks for every archer and guard. Without the rule it is exactly the old rally (80 px,
    ×1.25, full harm), so a realm without `GameState.front` plays as before. With the rule it is his presence.
  - `FrontNight.step`: timers, relighting by passing, the throw-back, the night's tally.
  - `FrontNight.dawn`: the tally into `DawnReport.front`, then a fresh night.
  - `FrontNight.adopt`: turns the rule on for a realm.
  - For the picture: `underPresence`, `picture` (one struct per frame), `wallHere`, `patchOffer`, `patch(plot:)`.
- `Core/Front/PresentBot.swift`: the "present" bot of T13 and its night tally (moves, trips, run seconds, a log).
- `Core/Front/FrontTuningRun.swift`: T13 (`FrontMetrics`, `FrontTuningRun.measure`): every night 3 to 14 of seeds 1 to
  10, played twice from the reference bot's eve.
- `Core/Front/FrontText.swift` and `Resources/Front.xcstrings`: the report's four front lines, English and German.
- `Tests/FrontPresenceTests.swift` (the rule, the save, the text), `Tests/FrontTuningTests.swift` (T13, the chore
  guard).
- `tools/frontsweep/` (`sh bash tools/frontsweep/run.sh [probe] [variants]`): T13, the budgets probe and the rule's
  variants with -O on the runner.

### The rule as built

- **Presence.** At night (dusk, night, first light), unless he is shaken, archers and guards within 90 px of the lord
  (along the ground, as the old rally) loose and strike ×1.25 as fast (their cooldowns; the guards' blows) and take
  ×0.5 of the harm (in the breach and in passing): a quarter faster, twice as long. It replaces the old rally while the rule is on: the rally (DESIGN.md
  "The king at night": 80 px, ×1.25) is the same idea without the harm, and two bonuses for one thing would stack. The
  engines are crewed by castle staff and get nothing.
- **Braziers** (since fix round 1, a rule by belonging). While he stands on a standing wall (between its face and its
  back, the gatehouse's passage included: `FrontNight.wallUnder`), the dead braziers of that wall's line
  (`Realm.lines[i].braziers`) catch from his lantern: his wall's fires burn, wherever the world draws them. Elsewhere a
  dead brazier within 24 px catches as he passes (the spec: about 20). Free, at most one in 4 s, the nearest first; the
  existing `SimEvent.brazierLit(plot:)` fires, so the lantern sound already plays. A wall in rubble is no wall. By day
  nothing (braziers burn all day). Round lh-f1-5 used a reach of 48 px instead, which fitted only today's brazier
  positions (the critic: 40 px lost the whole effect).
- **The old Light action** (`Sim.light`, `KingAction.light`, the old screen's button) still works and is marked as
  going. The reference bot lights with it: it must stay in Core for T1 to T8 (or they must be measured again); only the
  player's button goes.
- **Patching** is `Sim.patch` as it was. New form: `FrontNight.wallHere` (the standing wall in his reach),
  `patchOffer` (price, ready, affordable, strength) and `patch(plot:)`, which patches only the wall he stands at.
- **He cannot die.** A creature on the ground that comes within 6 px of him (or would walk through him in this step)
  with nothing between them (a standing wall's face, the guard line, the hearth: as the battle stops creatures) throws
  him 60 px toward the castle at once, breaks off an old-screen Light, and shakes him for 8 s: no presence. For 1.5 s
  after a throw no creature throws him again (they pass him). Crows never throw. Up on a standing wall (between its
  face and its back, the gatehouse's passage included) nothing reaches him, also not the shadehounds that leap a
  palisade (round lh-f1-1: standing behind a palisade, the bot was bowled over up to 14 times a night). The lantern's radius is not touched
  (the stage lane's "Raise the lantern" owns it). Relighting still works while shaken (his lantern burns).
- **Deterministic:** the rule draws nothing from the random stream.

### Hooks into existing files (apply them again at the join)

| File | Place | Hook | Why |
|---|---|---|---|
| `Core/Balance.swift` | after `creatureHarmScale` | `var front = FrontTuning()` | the rule's numbers travel with every balance (tests, sweeps) |
| `Core/GameState.swift` | after `var defeated` | `var front: FrontState?` | the saved rule; nil = the old rules (bots, old saves) |
| `Core/DawnReport.swift` | after `housesFull` | `var front: FrontNightReport?` | the report's front half |
| `Core/Sim.swift` `step` | right after `stepKing(...)` | `FrontNight.step(&s, dt: dt, balance: balance, events: &events)` | timers, relight, throw, tally |
| `Core/Sim.swift` `dawn` | right after `s.lastReport = report` | `FrontNight.dawn(&s)` | the tally into the report |
| `Core/Sim.swift` | doc comments of `KingAction.light`, `Sim.light` | "going at the join" | marks the old action |
| `Core/Battle.swift` `stepCreatures` | the guards' strike at the front contact | `let aura = LordAura(s, balance: balance)`; `rally = aura.speed(at: soldier.x)` | presence or the old rally |
| `Core/Battle.swift` `hurtGuards` | the holders' loop | `aura`, `share = aura.harm(at: soldier.x)`; `left * share`, `max(0, room) / share`; `hpBefore`, `raw` and, after `s.soldiers[index] = soldier`, `FrontNight.withheld(&s, raw:, taken:, hp:, maxHP:)` | the guards' harm share; the harm presence kept off (fix round 1) |
| `Core/Battle.swift` `stepSoldiers` | `let kingX = s.king.x` and the archers' rally | `let aura = LordAura(...)`; `rally = aura.speed(at: soldier.x)` | presence or the old rally |
| `Core/Battle.swift` `contactDamage` | before the soldier loop; the hp loss | `let aura = LordAura(...)`; `raw = harm * creatureHarmScale`, `hp -= raw * aura.harm(at: s1)`, then `FrontNight.withheld(...)` | harm in passing; the harm kept off (fix round 1) |
| `tools/simtune/run.sh` | `SRC` | the three files `Core/Front/FrontTuning.swift FrontState.swift FrontNight.swift` | simtune compiles the core |

Under the old rules every hook computes exactly the old numbers (`x * 1.0`, `x / 1.0` and the rally's own expression),
and `FrontNight.withheld` does nothing without `GameState.front`, so T1 to T8 are the same line for line (see the
rounds).

### For the join: what the screen shows and which touch calls what

- **Turn the rule on** for the player's realm: `FrontNight.adopt(&start)` and `FrontNight.adopt(&snapshot)` in
  `SimDriver.init`, and `FrontNight.adopt(&state)` in `SimDriver.restart`. A loaded old save gets it there too. The
  bots (`-GWAutoplay play` included) may stay without it. With the rule on, the old rally is gone by day too (it worked
  at any hour; presence is a thing of the night), on purpose.
- **Every frame** read `FrontNight.picture(state, balance:)`:
  - `underPresence` (soldier ids): those people straighten and shout, a warm rim on them (REALM.md section 3). No
    circle, no number, no HUD. Reduce Motion: the rim without the straightening bob.
  - `lastThrow` (a new `at`): slide the lord from `fromX` to `toX` over about 0.3 s (ease out), a dust puff, a heavy
    haptic and a dull thud (the wallHit sound, low rate). Reduce Motion: no slide, a short cross-fade.
  - `shakenLeft`, `shakenShare`: he stoops and the lantern sways while shaken; he straightens when it ends. The
    lantern's radius stays (it is the stage lane's).
  - `lastRelight` (a new `at`): a spark leaves his lantern and the brazier flares; on his wall it crosses the parapet
    to the wall's own fire (at the gatehouse up to about 165 px), in passing it is a short hop. The sound comes from
    `SimEvent.brazierLit` already. This is how the player learns the rule: stand on the wall and its fires catch.
  - `patch` (`FrontPatchOffer`): the damaged wall where he stands is paid by **the count** (PAY.md, the director's note
    of 16:16): a touch on that wall's face opens the count, and when the last coin lands the count calls
    `FrontNight.patch(&state, plot: offer.plot, balance:, events:)` once (add a one-line wrapper on `SimDriver`). Core
    gives the count only `price` and the order; no pay picture of this lane's own. Not `ready`: the board shakes; not
    `affordable`: the refuse sound.
  - **Touch overlap.** The stage lane's "Raise the lantern" is a hold on the lord (0.35 s or longer), and the lord stands
    on exactly the wall a touch patches. A hold that starts on the lord raises the lantern and never patches; a tap on
    the wall's face away from the lord (or a tap on the lord shorter than the hold) opens the count.
  - **The stamps after a load.** `lastThrow` and `lastRelight` are saved. After loading a save (and after a restart)
    the screen takes the stored `at` values as already seen, so it never replays the last throw or spark.
- **No Light button and no prompt.** Standing on a wall keeps its braziers burning; walking past a dead brazier
  relights it.
- **Events.** Nothing new in `SimEvent` (its switch in `Feedback.cue` is exhaustive and other lanes edit it): diff the
  `at` stamps, or add `.lordThrown(fromX:toX:)` and `.lordSteadied` at the join with their `Feedback` rows.
- **The dawn report:** `FrontText.lines(report)` gives up to three short lines (where he stood, braziers caught,
  throws); put them in the night half after the fallen. The card has no field for them yet (`ReportCard` is the
  rebuild's). "There" comes only on a night his presence kept off at least one soldier's life of harm (fix round 1).
- **Strings:** `Resources/Front.xcstrings`, English and German; the six other languages follow in the i18n pass (4 keys,
  2 of them plural).

### Tuning and T13 (as of round lh-f1-5; the fix round's numbers are under "front-1, fix round 1")

**The measure.** Every night 3 to 14 of seeds 1 to 10 is played twice from the reference bot's eve (the morning before
it, the realm and the bot as they were): once by the reference bot under the old rules, once by the present bot under
the rule. The present bot is the reference by day, so the days are the same and only the night differs. The reference
loses almost nobody at the game's own budget (15 defenders over those 120 nights), so the nights are also played at
1.5 and 2 times the budget (a realm caught short); the band counts the losses of all three together. The reference
loses no night at up to three times the budget, so "presence never wins a night the reference loses clearly" is also
asked at six times (`FrontTuningRun.defaultFallStresses`), where it falls in about a third of the nights and in a few
clearly (20 s or more before first light).

**T1 to T8** do not move: the reference bots play without `GameState.front`, and every hook computes the old numbers
under the old rules. The tuning report of round lh-f1-1 is the same as that of round lh-snd-2 (the base code) line for
line (`diff` empty, 80 lines each); `FrontPresenceTests.testTheReferenceBotIgnoresTheRulesNumbers` proves the reference
ignores the rule's numbers.

**What the spec's starting values did** (round lh-f1-2, budgets x1, x1.5, x2; present lost / reference lost):

| variant | present / reference | fewer |
|---|---|---|
| spec: r90, x1.15, x0.8, relight 20 px, bot behind the wall | 325 / 217 | −50 % |
| the old rally's numbers (r80, x1.25, harm 1) in the present bot's hands | 303 / 217 | −40 % |
| no presence at all | 348 / 217 | −60 % |
| relight 24 px from the wall's front edge | 288 / 217 | −33 % |

Even with the rally's own numbers the present bot lost 40 % more: the light. The reference relights every snuffed
brazier with the old Light action, where nothing can touch it (10 and more a night on nights 13 and 14); under the rule
a brazier 45 px in front of the wall sits in the crowd that throws the lord back, so the present bot relit fewer than
one a night and the walls went blind.

**The light** (round lh-f1-3, at the spec's presence numbers; how far the bot fetches a brazier and how careful it is
changed nothing at reach 48):

| relight reach (bot on the wall's front edge) | present / reference | fewer |
|---|---|---|
| 20 px | 317 / 217 | −46 % |
| 24 px | 269 / 217 | −24 % |
| 36 px | 269 / 217 | −24 % |
| 48 px (both braziers of the wall) | 213 / 217 | +2 % |

**The presence numbers** at reach 48 (rounds lh-f1-3 and lh-f1-4; how many fewer defenders the present bot lost than
the reference, budgets x1, x1.5, x2 pooled; T13's band is 25 to 40 %):

| speed \ harm | 0.5 | 0.55 | 0.6 | 0.65 | 0.7 | 0.8 | 0.9 | 1.0 |
|---|---|---|---|---|---|---|---|---|
| 1.0 | | | 3 % | | −7 % | −22 % | −26 % | −36 % |
| 1.1 | | | 15 % | | 5 % | −3 % | −8 % | −12 % |
| 1.15 (spec) | | | 21 % | | 9 % | 2 % | −3 % | −10 % |
| 1.2 | 36 % | 29 % | 23 % | 15 % | 14 % | 2 % | 1 % | −9 % |
| 1.25 | **34 %** | 30 % | 28 % | 20 % | 17 % | 13 % | 6 % | −2 % |
| 1.3 | 29 % | 24 % | 24 % | 21 % | 17 % | | | |
| 1.35 | 35 % | 30 % | 27 % | 22 % | 20 % | | | |

The grid is not smooth (a lost wall more or less in a few nights moves it by several points), so the choice sits where
its neighbours pass too. The radius hardly matters between 60 and 120 (31 to 34 %: a wall's archers and its tower stand
within 50 px of its front edge). Relighting at most one brazier in 2 s gives 26 %, in 6 s 23 %; a reach of 40 px 4 %,
of 56 px the same as 48. The bot standing 14 px behind the face (where the reference stands) 20 %. The shaken spell's
length (4, 8, 12 s) hardly matters to the bot, which is thrown about once in ten nights. Fetching dead braziers
anywhere instead of near its place, or never joining the guards, changes nothing in the band.

**Chosen: radius 90, speed ×1.25, harm ×0.5, relight reach 48, the bot on the wall's front edge.** As fast as the old
rally it replaces, and half the harm: near the lord his people shoot a quarter faster and hold twice as long. Harm ×0.6
reached the band at its lower edge (28 %, round lh-f1-4) with its neighbours outside it; ×0.5 sits in the middle and
every neighbour passes (29 to 36 %), which T13 needs when it is measured again on the joined game.

**T13 (round lh-f1-5): PASS.** The present bot lost 144 defenders, the reference 217: **34 % fewer** (x1: 7/15, x1.5:
43/64, x2: 94/138). The reference lost 5 nights clearly (all at six times the budget: seeds 2 and 4 night 13, 5 and 7
night 14, 9 night 12, each 20 to 24 s before first light); the present bot lost all 5 too (21 to 23 s before). Presence
matters where a night is close and fades where it is lost anyway: 13 % fewer at three times the budget, 6, 3 and 2 % at
four, five and six times. Whole runs from day 1 at the game's own nights: seeds 1 to 3 lost 0, 1, 2 defenders on nights
3 to 14 with the reference and 0, 1, 0 with the present bot; neither fell.

**What the present bot does in a night** (the chore guard, the same at harm ×0.6 and ×0.5): at dusk it runs from
the throne to the front wall (about 12 s) and stands on its front edge. From there its lantern keeps the two braziers in
front of that wall burning (it relights one to four a night as the crows snuff them) and its presence lies on the
wall's and the tower's archers (96 to 99 % of the fighting covered). It patches about once in ten nights, fetches a
brazier further away about once in ten nights and is thrown back about once in ten. When the wall falls it steps back
to the next one, and when that falls to the hearth. At the game's own budget 101 of 120 nights take that single move to
the wall, 9 take two and 10 take three; at twice the budget 87, 28 and 5. One or two good moves carry the night;
nothing has it sprint between walls.

### Rounds

| Round | Commit | Steps | Result |
|---|---|---|---|
| lh-f1-1 | 1537e18 | build; unit Front, Save, Battle, Tuning; sweep | the rule's tests and T1 to T8 passed (tuning report identical to lh-snd-2's); T13 failed (−48 %), the bot's night test had no fighting on night 9; the sweep did not compile (simtune's file list was already short of AmbientRampLook2 and Lord) |
| lh-f1-2 | 67a4672 | build; unit FrontPresenceTests; sweep | ALL PASSED; the on-the-wall rule ended the palisade throws; the first variants (table above) |
| lh-f1-3 | 1c8c5ec | sweep | ALL PASSED; the light and the presence grids (tables above) |
| lh-f1-4 | 5e97d4e | build, unit, ui, ui-de, release; sweep | ALL PASSED (434 unit tests); T13 28 % at harm ×0.6; T1 to T8 identical to lh-snd-2; the fine grid |
| lh-f1-5 | 85112db | build, unit, ui, ui-de, release; sweep | **ALL PASSED** (434 unit tests, UI in English and German, Release); T13 34 % at harm ×0.5; T1 to T8 identical to lh-snd-2 line for line |

### Open, and waiting for the join

- **The picture and the touch** (all of "For the join" above): the rebuilt gorge and hall, the rim and the shouts, the
  throw's slide, the spark, the coins over the wall. Core is ready for them.
- **Turning the rule on** for the player's realm (`FrontNight.adopt` in `SimDriver`): left to the join on purpose, so the
  old screen keeps playing as it did (no Light button that would rarely appear, no lord jumping 60 px without a slide).
- **`SimEvent` cases** for the throw and the steadying, if the join wants them in `Feedback` (now: diff the stamps).
- **The six other languages** of Front.xcstrings (4 keys, 2 of them plural) in the i18n pass.
- **`tools/simtune`** does not compile on the base either (its file list lacks `AmbientRampLook2.swift` and `Lord.swift`);
  this lane only added its own three files to the list. `tools/frontsweep` shows the fix (the extra file and a stand-in
  for `LordIdentity`).
- **At overwhelming nights** (four to six times the budget, outside T13) the present bot falls in 5 or 6 nights a
  budget that the reference holds (and holds none it loses): the reference relights every brazier of every line with the
  old Light action, untouchable, while the present bot leaves the braziers of the lines behind it to the crows. Fetching
  braziers anywhere brings it to 3, and to 2 nights held that the reference lost. Not a target; worth a look when the
  hearth (section 4) makes such nights matter.
- **The game's own budget is easy for both bots** (15 and 7 defenders lost over 120 nights): T13's band lives on the
  bigger budgets. A human player's realm is weaker than the reference bot's, so the player meets those nights.
- **On the device** (REALM.md section 6): whether standing at the front wall all night feels like being there or like
  waiting. The rule rewards one or two moves; the hearth (section 4) and the beacons (section 5) bring the reasons to
  move in later steps of this lane.

## front-1, fix round 1 (14.11.2026, evening)

The critic's verdict: /Users/enaayla/Desktop/Spiele-Welle/.claude/worktrees/game2-planning-354541/ci-out/director/front-1-presence-critic1.md
(one blocker, four highs). Rounds by the director's notes of 14.11. 18:46 and 19:35: no `ui`, `ui-de` or `release`;
no UI class changed, so the gate is `build unit`, with the sweep as an `sh` step in the same round.

### The blocker: the house canon

`Resources/Front.xcstrings`, `front.report.relit`: "One brazier caught from your lantern." / "%lld braziers caught from
your lantern."; German "Eine Feuerschale fing an Eurer Laterne Feuer." / "%lld Feuerschalen fingen an Eurer Laterne
Feuer." The comment no longer names a lamplighter (HOUSE.md section 1: the lord never was one). `front.report.there` is
now "You stood where it burned. Your people held longer." (German unchanged).

### High 1: the braziers by belonging

- **The rule.** While the lord stands on a standing wall (`FrontNight.wallUnder`, between its face and its back), the
  dead braziers of that wall's line catch from his lantern, one in 4 s, the nearest first. Elsewhere a dead brazier
  within 24 px catches as he passes (`relightReach` 24, the spec's "about 20"). `FrontNight.catches(s, plot:, at:,
  tuning:)` answers both. `relightOwnWall` turns the first half off for the sweep.
- **No px cliff any more** (round lh-f1f1-2, the standard bot): wall + passing 16 px 32 %, 24 px 32 %, 32 px 33 %.
  Passing alone at 24 px gives 4 % (the old cliff), passing alone at 48 px (round lh-f1-5's rule) 34 %. The rule no
  longer depends on where the world draws the braziers, and the player can read it: his wall's fires burn.
- **A spot dependency found instead, and fixed by values.** With the rule by belonging, where the bot stands on the
  wall moved T13: the front edge (1 px, round lh-f1-5's spot) is an outlier, every deeper spot behaves alike. The grid
  (round lh-f1f1-4, fewer losses pooled over x1, x1.5, x2; per budget in brackets):

| harm \ spot | 1 px | 5 px | 10 px | 14 px | 19 px |
|---|---|---|---|---|---|
| 0.5 | 32 % (53/30/30) | 47 % (73/58/38) | 47 % (73/59/38) | 45 % (73/58/36) | 42 % (73/53/34) |
| 0.55 | 29 % | 43 % | 43 % | 42 % | 39 % |
| 0.6 | 26 % | 40 % | 41 % | 39 % | 38 % |
| **0.65** | 18 % | **31 %** | **33 %** | **32 %** | **30 %** |
| 0.7 | 15 % | 24 % | 25 % | 24 % | 23 % |
| 0.75 | 12 % | 19 % | 21 % | 19 % | 18 % |

  **Chosen: harm ×0.65 and the bot on the wall walk, 10 px behind the face** (within every wall; a palisade is 20 px).
  T13 is 30 to 33 % wherever on the wall the lord stands from 5 to 19 px, which is what a human player does; only
  standing on the very front edge gives less. Speed stays ×1.25, radius 90. Near the lord his people shoot a quarter
  faster and take a third less harm, closer to the spec's 20 % than round lh-f1-5's half.

### High 2: the parked night and the hard nights

- **The bot goes back for rear braziers** (`botRearBraziers`, `botQuietReach` 200, `botMaxRearTrips` 3): when the
  front is quiet (no creature on the ground within 200 px in front of its place or behind it, none at a wall or the
  guards) it walks back to the nearest spot a dead brazier of a rear line catches from (on that line's wall, or 23 px
  from the brazier in passing), waits there up to one relight for the second brazier of the line, and returns. It
  happens almost never: 0 nights at x1 and x1.5, 2 of 120 at x2, 6 at x6 (round lh-f1f1-1). While creatures come the
  front is not quiet, and when they stop, the rear braziers still burn (the crows go for the leftmost burning brazier,
  and the lord keeps relighting the front pair). "Rear trips whenever the way is safe" (`botRearOnlyWhenQuiet` off) and
  "fetch anywhere" change nothing in T13 either (32 %, round lh-f1f1-2); on the falls ladder they hold 2 more nights the
  reference lost and fall in 3 fewer the reference held (12 instead of 15 over x3 to x6). Kept as built, off the
  critical path.
- **Reported lines now in the T13 report** (`FrontMetrics.report`): T13 per budget in its first line; "present fell
  where the reference held / held where it fell" per budget; how often the dawn report's presence line shows; rear
  trips and lives kept in the bot table. The sweep asks the falls ladder at x3 to x6 (`ladder`).
- **The hard nights under the rule** (`FrontHardNights`, `FrontTuningRun.hardSeed`; all twenty seeds in the sweep, one
  seed as a unit test): T6 and T7 played from the reference bot's own eves, once by the reference under the old rules,
  once by the present bot under the rule (numbers below, "Rounds").
- **Night 20 without the beacon's last stage, diagnosed** (round lh-f1f1-2/3, the sweep's `night20`; held of 20):

| who | held | why |
|---|---|---|
| reference, old rules | 10 | margins F0 to F14: close |
| reference under the rule (keeps its Light action) | 6 | thrown back 19 times a night as it walks into the creatures to light braziers |
| present bot | 2 | its walls fall a few seconds earlier and the creatures reach the hearth 5 to 10 s earlier (F6 to F16) |
| present bot, no presence at all | 2 | presence changes nothing on this night |
| present bot, presence harm 1 | 2 | |
| present bot, relight every 1 s | 3 | |
| present bot, last stand 20, 46, 90 or 150 px in front of the hearth | 2 | thrown 2 to 3 times; nothing gained |
| present bot, never thrown (and its safety checks off) | 5 | it then fetches braziers anywhere |

  With the beacon every variant holds 20 of 20 and slays the King in 20. So: the rule makes night 20 without the
  beacon's last stage much harder (the beacon is the designed way through), because the lord can no longer walk
  untouchable into the crowd to keep every brazier lit. Presence is not the cause. **For the director and the join:**
  T6's "without" band (30 to 60 %) is the reference bot's and holds; a player under the rule meets 10 to 30 %. Worth a
  look when the hearth (REALM.md section 4: a hearth that burns low) and the beacons (section 5) change the night's
  end, and when T6 is measured on the joined game with the rule on.

### High 3: the "there" line earns its place

- `FrontNightStats.withheldLives` / `FrontNightReport.withheldLives`: the harm presence kept off, each blow over the
  full strength of the soldier it was meant for (no more than he had left), via `FrontNight.withheld(&s, raw:, taken:,
  hp:, maxHP:)` from the two harm hooks in `Battle` (new hooks, table below).
- "There" shows only after 10 s of fighting, with presence over at least 60 % of it **and** at least one soldier's life
  kept (`reportThereLives` 1.0); otherwise no line. "Away" as before.
- How often (round lh-f1f1-1, at harm ×0.5): at x1 "there" on 6 of 31 nights with fighting (was nearly all), x1.5 13 of
  51, x2 23 of 59. At harm ×0.65 less is kept per blow, so it shows still more rarely (final numbers under "Rounds").

### Smaller things

- `LordAura` clamps the harm share at `FrontTuning.leastHarmShare` 0.05 (no division by nothing in `hurtGuards`).
- The lane notes (front-1 above): the patch is paid by the count (PAY.md); the touch overlap (a hold on the lord
  raises the lantern, a tap on the wall's face opens the count); the saved stamps count as seen after a load; with the
  rule on the old rally is gone by day too.

### New hooks of this round (apply them again at the join)

| File | Place | Hook | Why |
|---|---|---|---|
| `Core/Battle.swift` `hurtGuards` | the holders' loop | `let hpBefore = soldier.hp`, `var raw = left`, in the retreat branch `raw = max(0, room) / share`; after `s.soldiers[index] = soldier`: `FrontNight.withheld(&s, raw: raw, taken: hpBefore - soldier.hp, hp: hpBefore, maxHP: soldier.maxHP)` | the harm presence kept off |
| `Core/Battle.swift` `contactDamage` | the hp loss | `let raw = harm * balance.creatureHarmScale`, `hpBefore`, `maxHP`; `hp -= raw * aura.harm(at: s1)`; `FrontNight.withheld(&s, raw:, taken: raw * aura.harm(at: s1), hp: hpBefore, maxHP: maxHP)` | the same in passing |

Both do nothing without `GameState.front`, and `raw * share` is the old product to the bit, so T1 to T8 stay line for
line (proved below).

### New values (all in `FrontTuning`)

`relightOwnWall` true, `relightReach` 24 (was 48), `presenceHarm` 0.65 (was 0.5), `leastHarmShare` 0.05,
`botBehindWall` 10 (was 1), `botLastStand` 1, `botRearBraziers` true, `botQuietReach` 200, `botRearOnlyWhenQuiet`
true, `botMaxRearTrips` 3, `reportThereLives` 1.0.
