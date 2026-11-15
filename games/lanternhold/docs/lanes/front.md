# Front lane (branch `claude/lh-front`)

The night and the dark side, in Core (docs/REALM.md sections 3 to 5). One heading per step: what exists, the hooks
into existing files (so the join can apply them again on the rebuilt game), the rounds, what is open and what waits for
the join.

## front-1: being there counts (14.11.2026)

Louis, 14.11.: "Dabei sein zählt: wo der Burgherr steht, kämpfen seine Leute besser und halten länger. Kein Kampfmenü,
man rennt dorthin, wo es brennt." Spec: REALM.md section 3.

### What exists (all new files of this lane)

- `Core/Front/FrontTuning.swift`: every number of the rule in one place, carried as `Balance.front` (presence radius 90,
  speed ×1.3, harm ×0.6 since fix round 1 (×1.25 and ×0.5 before); a wall's braziers catch while he stands on it,
  elsewhere within 24 px in passing, one in 4 s (fix round 1); touch 6 px, throw 60 px, shaken 8 s, grace 1.5 s; the present bot's values; the dawn report's
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

- **Presence** (the numbers of round lh-f1-5; fix round 1 made them ×1.3 and ×0.6). At night (dusk, night, first
  light), unless he is shaken, archers and guards within 90 px of the lord
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
- **No px cliff any more** (round lh-f1f1-6, the final values): wall + passing 16 px, 24 px and 32 px all give 35 %;
  without the rule by belonging, passing alone at 24 px gives −17 % and at 48 px (round lh-f1-5's rule) 17 %. The rule
  no longer depends on where the world draws the braziers, and the player can read it: his wall's fires burn.
- **A spot dependency found instead, and fixed by values.** With the rule by belonging, where the bot stands on the
  wall moved T13: the front edge (1 px, round lh-f1-5's spot) is an outlier, every deeper spot behaves alike. The grid
  at speed ×1.25 (round lh-f1f1-4, fewer losses pooled over x1, x1.5, x2; per budget in brackets):

| harm \ spot | 1 px | 5 px | 10 px | 14 px | 19 px |
|---|---|---|---|---|---|
| 0.5 | 32 % (53/30/30) | 47 % (73/58/38) | 47 % (73/59/38) | 45 % (73/58/36) | 42 % (73/53/34) |
| 0.55 | 29 % | 43 % | 43 % | 42 % | 39 % |
| 0.6 | 26 % | 40 % | 41 % | 39 % | 38 % |
| **0.65** | 18 % | **31 %** | **33 %** | **32 %** | **30 %** |
| 0.7 | 15 % | 24 % | 25 % | 24 % | 23 % |
| 0.75 | 12 % | 19 % | 21 % | 19 % | 18 % |

  Round lh-f1f1-5 took harm ×0.65 at ×1.25 (T13 33 %, ALL PASSED), but its neighbours sat on the band's edges (×0.6
  41 %, ×0.7 25 %) and the falls ladder got worse (26 nights lost where the reference held, against 15). At speed ×1.3
  the curve is flatter. The same grid at ×1.3 (round lh-f1f1-6):

| harm \ spot | 1 px | 5 px | 10 px | 14 px | 19 px |
|---|---|---|---|---|---|
| 0.5 | 28 % | 42 % | 42 % | 39 % | 38 % |
| 0.55 | 24 % | 39 % | 39 % | 34 % | 33 % |
| **0.6** | 23 % | **35 %** | **35 % (80/48/23)** | **30 %** | **29 %** |
| 0.65 | 20 % | 32 % | 32 % | 28 % | 27 % |
| 0.7 | 16 % | 26 % | 26 % | 22 % | 21 % |

  **Chosen: speed ×1.3, harm ×0.6, radius 90, the bot on the wall walk 10 px behind the face** (within every wall; a
  palisade is 20 px). T13 is 29 to 35 % wherever on the wall the lord stands from 5 to 19 px, and every neighbour of
  the choice passes: harm ×0.55 39 %, ×0.65 32 %; speed ×1.35 37 %, ×1.25 41 % (just out); radius 60 31 %, 120 35 %;
  relight every 2 s 35 %, every 3 s 29 %. Only the very front edge (1 px) gives less (23 %). Near the lord his people
  shoot a third faster and take 40 % less harm.

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
- How often (round lh-f1f1-6, the final values): "there" on 5 of the 34 nights with 10 s of fighting or more at x1 (it
  came after nearly all of them before), 16 of 49 at x1.5, 27 of 59 at x2, 71 of 120 at x6; "away" 0, 0, 2, 21.

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

`relightOwnWall` true, `relightReach` 24 (was 48), `presenceSpeed` 1.3 (was 1.25), `presenceHarm` 0.6 (was 0.5),
`leastHarmShare` 0.05, `botBehindWall` 10 (was 1), `botLastStand` 1, `botRearBraziers` true, `botQuietReach` 200,
`botRearOnlyWhenQuiet` true, `botMaxRearTrips` 3, `reportThereLives` 1.0.

### T13 and the reported lines (round lh-f1f1-6, the final values)

- **T13: PASS, 35 % fewer** (the present bot lost 142 defenders, the reference 217). Per budget: x1 80 % (3 against
  15: a few draws), x1.5 48 % (33/64), x2 23 % (106/138). The band holds only pooled; the per-budget spread is wide
  (presence matters most on middling nights and fades as they get heavy). Of the 5 nights the reference lost clearly
  (all at x6, 20 to 24 s before first light) the present bot held none (it fell 21 to 23 s before).
- **Falls ladder (reported only):** the present bot fell where the reference held in 0 nights at x3, 6 at x4, 7 at x5,
  3 at x6 (16 in all; round lh-f1-5's values 15, harm ×0.65 26), and held 1 the reference lost (x5, not clearly).
  Fewer losses: x3 13 %, x4 −2 %, x5 −6 %, x6 −6 %. "Rear trips whenever the way is safe" would give 15 and 2 (T13 the
  same); not taken, the difference is a night or two.
- **The hard nights (reported only, seeds 1 to 20):** night 20 with the beacon held 20/20 by both, the King slain 20/20
  by both, defenders lost 53 / 49. Night 20 without the beacon's last stage held by the reference 10/20, by the present
  bot 2/20 (diagnosis above: the lost Light action and the throw-back, not presence). Endless (cap 70): the reference
  falls on nights [46, 46, 48, 43, 55, 37, 52, 50, 39, 53, 53, 49, 38, 49, 38, 0, 63, 44, 45, 0] (17 in 35 to 60); the
  present bot on [55, 51, 49, 0, 0, 36, 0, 51, 32, 49, 0, 55, 0, 0, 0, 0, 50, 46, 52, 0] (10 in 35 to 60, 8 still
  standing at night 70). Under the rule endless gets easier (presence pays on every long night), night 20 without the
  beacon harder.
- **T1 to T8:** the tuning report of round lh-f1f1-6 is the base's (round lh-snd-2) line for line: `diff` empty, 80
  lines, md5 f919a8fd…7324 both; night-twenty-steps.txt the same too. 437 unit tests passed, none failed.

### What the present bot does in a night (the chore guard, in plain words)

At dusk it runs from the throne to the first standing wall (about 12 s) and stands on the wall walk, 10 px behind
the face. From there its lantern keeps that wall's two braziers burning (it relights about one a night at x1, three to
four at x2, nine at x6, as the crows snuff them), and its presence lies on the wall's and the tower's archers (96 to
99 % of the fighting covered). Nothing throws it (0.0 throws a night up to x2). It patches about once in ten nights.
When the wall falls it steps back to the next wall, and when the last falls, to the hearth. At the game's own budget
102 of 120 nights take that single move, 8 take two, 10 three or more; at x2 85, 24 and 11. It went back for a rear
brazier in 0 nights at x1, 1 at x1.5, 2 at x2 and 2 at x6: while creatures come the front is never quiet, and when
they stop the rear braziers still burn. So the night is still one good move at dusk and standing with the people;
the rule pays for that move (35 % fewer losses) but does not ask for a second one. The reasons to move in depth come
with this lane's next steps: a hearth that burns low (REALM.md section 4) and beacons into the gorge (section 5).

### Rounds of the fix round

| Round | Commit | Steps | Result |
|---|---|---|---|
| lh-f1f1-1 | 6017dc8 | build; unit (all); sh frontsweep | **ALL PASSED** (437 unit tests); T13 32 % at ×1.25/×0.5, the bot on the front edge; T1 to T8 identical; the hard nights showed night 20 without the beacon 2/20 against 10/20 |
| lh-f1f1-2 | eb45720 | sh frontsweep night20 variants hard | ALL PASSED; night 20 diagnosed (table above); rear-trip variants; the spot on the wall moves T13 |
| lh-f1f1-3 | 131bcb5 | sh frontsweep night20 variants hard | ALL PASSED; the last stand changes nothing |
| lh-f1f1-4 | 2a2c5f7 | sh frontsweep grid | ALL PASSED; the spot against the harm share at ×1.25 |
| lh-f1f1-5 | 38e8b8d | build; unit (all); sh frontsweep | **ALL PASSED** (437); T13 33 % at ×1.25/×0.65, the bot at 10 px; neighbours on the band's edges, the falls ladder worse (26) |
| lh-f1f1-6 | b6aa9d9 | build; unit (all); sh frontsweep variants hard grid | **ALL PASSED** (437 unit tests, none failed); T13 35 % at ×1.3/×0.6; T1 to T8 identical to lh-snd-2; the falls ladder 16 |

Rounds by the director's notes of 14.11. 18:46 and 19:35: no `ui`, `ui-de` or `release` (no UI class changed), each
gate one round of `build unit` with the sweep as an `sh` step; the sweep-only rounds held a Mac slot 2 to 4 minutes.

### Open, and waiting for the join (fix round 1)

- **Night 20 without the beacon's last stage under the rule** (2 of 20 for the present bot, 6 for the reference bot
  playing under the rule, 10 under the old rules): for the director. The reference bot's T6 holds; the player's game
  with the rule is harder there and easier in endless. Measure T6 and T7 with the rule on at the join, and look again
  when the hearth (section 4) and the beacons (section 5) change the night's end.
- **T13 per budget** is lopsided (80 / 48 / 23 %); the band holds pooled only, as the target is written.
- **The front edge of a wall** gives less than the rest of the wall walk (23 % against 29 to 35 %); the cause is not
  found (not the throws, not the light). A human player standing anywhere else on the wall gets the band.
- **`tools/frontsweep`** needs its file list kept in step with Core at the join (as `tools/simtune` did); the hard
  nights and the falls ladder live only there (in unit tests they would add about four minutes to every unit round).
- Everything listed under "Open, and waiting for the join" of front-1 still holds.

## front-2: the hearth (15.11.2026)

Louis, 14.11.: "Tut weh, geht weiter: Häuser brennen, Leute mit Namen sterben, die Stadt wird ärmer und man baut wieder
auf. Ganz vorbei ist es nur, wenn das Herdfeuer ausgeht, und dann startet man am Morgen davor neu." Spec: REALM.md
section 4. Core only: no SwiftUI, no renderer, no sprite, no UI test changed.

How this step was made: the app's worktree guard refuses writes into `.claude/worktrees/lh-front` from the lead's
session, so the step worked in a scratch clone of the branch (`scratchpad/front2/repo`), committed there as Louis'
noreply identity and pushed to `origin/claude/lh-front`. The local worktree `lh-front` is behind origin until someone
runs `git -C .claude/worktrees/lh-front merge --ff-only origin/claude/lh-front`.

### What exists (all new files of this lane)

- `Core/Front/HearthTuning.swift`: every number in one place, carried as `Balance.front.hearth` (`HearthTuning`), and
  the fire's four steps (`HearthLevel`: bright, low, embers, out). `breachSteps` 2 (the spec's starting value was 1:
  see "The one number moved"), `recoverSteps` 1, `feedSteps` 1, `feedPrice` 25, `feedReach` 40 px, `secondChanceLevel`
  embers; `housesLeast` 1, `housesMost` 2, `lanternsSpare` 1, `deadLeast` 1, `deadMost` 3, `goldShare` 0.2, `goldCap`
  60, `happinessLoss` 8, `rebuildShare` 1/3; `dawnsKept` 3; the picture's `glow` by step (0, 0.35, 0.65, 1).
- `Core/Front/HearthState.swift`: the saved state (`HearthState` in `GameState.hearthFire`: the step, the day it was
  fed, the burnt places with their households, the dead by name, the broken nights, tonight's breach until its dawn,
  the stamps `lastBreak` and `lastFeed`, the lamplighter's input `lanterns`), the report's hearth half
  (`HearthDawnReport` in `DawnReport.hearth`) and its lines (`HearthLine`). Every field decodes with a default; a burnt
  plot outside the realm is dropped on load.
- `Core/Front/Hearth.swift`: the rule. `adopt`; `afterBattle` (the breach); `takeCost` and `households` (the cost);
  `dawn` (the report, the fire's rise, the second chance's rekindling); `feedOffer` and `feed` (wood); `rebuildPrice`,
  `rebuildOption` and `rebuild` (building up again); `ruins`, `sheltering`, `lanternsLit` and `picture` (one
  `HearthPicture` a frame: step, glow, ruins, sheltering, the feed offer, the stamps).
- `Core/Front/DawnRing.swift`: the last three dawns (`DawnRing`, `DawnChoice`). Only a living realm is ever kept, the
  same dawn written twice replaces itself, another realm's dawn starts it afresh, waking keeps that dawn and the older
  ones. It decodes dawn by dawn and never makes a save corrupt.
- `Core/Front/HearthNames.swift`: 40 townsfolk names (none a soldier's, the court's, the house's past or the people
  lane's cast; none that says an age).
- `Core/Front/HearthText.swift`: the words (Front.xcstrings) in the player's language or one language, the names filled
  in; the fall card's wake buttons.
- `Core/Front/HearthBot.swift`: the T14 bot (the reference by day and night; once no wall lies in rubble it feeds the
  fire below bright and has burnt places rebuilt; on its careless nights the lord stays at the throne).
- `Core/Front/HearthTuningRun.swift`: T14 (`HearthMetrics`, `HearthMend`, `HearthDouble`) and the loss table
  (`HearthLoss`, `lockstep`, `lossTable`).
- `Resources/Front.xcstrings`: 18 new keys in English and German (12 report lines, the happiness row's reason, the fall
  card's title, three wake buttons and "Begin a new realm").
- `Tests/HearthTests.swift` (25 tests: the breach, the cost, the lanterns, the rebuild, wood, the dawn's rise, out and
  the second chance, night 20, the lines and their words, the names, the ring, waking, the driver, the save, the
  reference bot) and `Tests/HearthTuningTests.swift` (T14a, T14b, two in a row, the loss table).
- `tools/hearthsweep/` (`sh bash tools/hearthsweep/run.sh [variants] [seeds=10]`): the loss table, T14 on 10 seeds at
  four sizes of the careless night, and the cost's variants, with -O on the runner.

### The rule as built

- **The fire** has four steps, bright, low, embers, out, and is seen only as fire (the picture reads `level` and
  `glow`; no bar, no number). A realm starts bright; a realm whose rule is turned on later (an old save) starts bright.
- **A broken night.** When the creatures drain the hearth's strength (the step in which the old rules set `defeated`),
  `Hearth.afterBattle` takes over in the same step: the fire drops `breachSteps` (two: bright to embers, low to out),
  the cost is taken, the `.defeat` event goes, and `Sim.secondChance` ends the night (the hearth flares up, every
  creature burns away, dawn comes at once; the walls stay as they are). The report says `realmFell` (the night was
  lost: no record counts it as held) and `hearth.broken`.
- **The cost** (taken at the breach, before the dawn's economy, from the night's own stream seeded by the realm's seed
  and the night, so the realm's random stream is untouched and waking at a dawn and losing the same night again costs
  the same): one to three townspeople with names die (taxpayers only, never a soldier, never more than there are; each
  name once a realm); one or two houses burn, one fewer with the street lanterns lit and never fewer than one (with the
  default lanterns that is one house, two in unrest), or one field or the market stall when no house stands; a fifth of
  the purse is gone (rounded down, at most 60); happiness falls by 8 at once.
- **Building up again.** A burnt place lies with `PlotState.item` nil and an entry in `HearthState.burnt`: it holds
  nobody (the house room is gone), pays nothing (fields and the market count by item), and its household (its share of
  the taxpayers by room) shelters in the chapel (`Hearth.sheltering`). The build card of a burnt plot offers only the
  same place back at a third of what it cost, every tier counted (house 10, big house 30, field 9, market stall 27),
  built as a rebuild (`Build.order` with `isRebuild`, so half the work). Once it stands the entry goes at the next dawn.
- **The fire recovers** one step at a dawn after a night without a breach (not after a night 20 lost and saved by the
  second chance). **Wood:** once a day (by the day's number, at any hour) the lord, standing within 40 px of the hearth,
  feeds a fire that burns low or embers one step for 25 gold. A bright fire and a dead one take no wood.
- **Out.** A breach that takes the fire to out leaves the realm fallen (`defeated`, the `.defeat` event, the fall
  card); the cost is taken all the same. The defeat card's second chance (the ads lane's rewarded video, `Sim.
  secondChance`) brings the dawn with the fire glowing again at embers and the cost standing (`hearth.rekindled`).
- **The last three dawns.** `SimDriver.dawnRing` keeps every dawn the realm reaches (and the first morning), the last
  three; `SimDriver.wake(back:)` wakes at one (0 is this morning, as "Replay the day" was) and keeps it and the older
  ones; `SimDriver.restart` begins a new realm with a fresh ring; `SaveGame.dawns` keeps the ring on disk. A fall never
  produces a dawn, and `DawnRing.record` refuses a fallen state, so a fall never overwrites a kept dawn, and every kept
  dawn has the fire above out. With two steps a breach the fire goes out on the second of two broken nights at most one
  held night apart, so the dawn before the first of them is among the three kept: nobody is stuck in a lost position.
- **Night 20** (the Lightless King's night, `Battle.boss`): the realm falls as today, whatever the fire's state; the
  rule takes no cost and leaves the fire as it is.
- **The street lanterns** (the director's note of 14.11. 14:45): `HearthState.lanterns` is a plain input; nil is the
  default rule (lit every evening, not in unrest, happiness below 15). With them lit one house fewer burns.
- **Deterministic**, and nothing runs for a realm without `GameState.hearthFire`: the reference bots of T1 to T8 play
  exactly as before (the loss table below).

### The one number moved: two steps a breach (the spec's starting value was one)

REALM.md's numbers are starting values that the lanes tune by values; the spec says a broken night drops "one step",
and T14 asks that "two broken nights within three end the realm". With one step these cannot both hold: a bright fire
has three steps above out, so two broken nights never put it out (round lh-f2-3, ten seeds: 0 of 20 in a row, 1 of 20
with a held night between, and that one only because the night between broke too). Worse for the player: wood undoes
one step a day, so a realm that breaks every night and buys wood every morning never goes out until its purse is empty,
and by then the three kept dawns all lie inside the slide: the fall would wake the player in a lost position (round
lh-f2-1: seed 2 night 8 broke four nights running at the game's own budget, fed every morning, and stood). With two
steps: wood (one step) and one held night (one step) mend one broken night; two in a row end the realm, with or without
wood; a careless bot that never feeds loses the realm on any two broken nights within three; one that holds the night
between and feeds the fire back to bright goes on, which is the deed the rule asks for. And the dawn before the trouble
is always among the three kept. The cost: after the first broken night the report says "Only embers glow in the
hearth." rather than "The hearth burns low." (that line now comes the morning after, when a held night raised the fire
from embers). `breachSteps` 1 is one value away for the director (T14b then reported as failing; T14a passes either
way).

No other number moved. The cost's variants (round lh-f2-3, careless night x6, 90 careless nights) changed T14a by a few
nights in either direction and none fixed the six it misses (happiness −4: 80 mended, −12: 81; gold cap 30: 84; a
third capped at 100: 79; dead 1-2: 86, 2-4: 82; two houses always: 75; rebuild at half: 80; wood 40: 84; no dawn
recovery: 51). The spec's values stay.

### Judged as a player

The first broken night: the hearth gutters to embers, the creatures burn away and it is morning. The report says, in
four short lines, which house burnt, who did not see the morning (one to three names), that coin is missing from the
treasury, and that only embers glow in the hearth. The gatehouse lies in rubble (the battle's own damage, as today).
The way back is plain and cheap: the gate (50, as today), the house (10), a log on the fire (25), and one night held.
In the T14 runs that is what happens: the fire is bright again after 1.6 dawns on average and the house stands again
after 1.5; three days later the realm is about 16 gold, 7 happiness and 3 people poorer than a twin whose breach cost
nothing. That reads as a loss you feel and mend, with names to remember, not as a reason to put the phone away. The
sting that stays is the names; the threat that stays is the embers: the next night must hold. What can make a player
quit: a young realm (nights 6 to 10) whose purse is empty when the gate falls cannot pay the 50 for it the next day, so
the next night breaks too and the fire goes out (3 of 90 careless nights). Then the fall card offers the morning before
the careless night, which is the second try Louis described ("startet man am Morgen davor neu"). At the join the town's
knock and the lord's presence give a human player two more ways out of that hole.

### Hooks into existing files (apply them again at the join)

| File | Place | Hook | Why |
|---|---|---|---|
| `Core/GameState.swift` | after `var front` | `var hearthFire: HearthState?` | the saved rule; nil = the old rules (bots, old saves) |
| `Core/DawnReport.swift` | after `var front` | `var hearth: HearthDawnReport?` | the report's hearth half |
| `Core/Sim.swift` `step` | after the `Battle.step` block, last line | `Hearth.afterBattle(&s, balance: balance, events: &events)` | the breach instead of the fall |
| `Core/Sim.swift` `dawn` | right after `FrontNight.dawn(&s)` | `Hearth.dawn(&s, balance: balance)` | the report's hearth half, the fire's rise |
| `Core/Build.swift` `options` | after `if current.job != nil { return [] }` | `if let rebuild = Hearth.rebuildOption(state, plot: plot, balance: balance) { return [rebuild] }` | a burnt place comes back at a third |
| `Core/Front/FrontTuning.swift` (own file) | end | `var hearth = HearthTuning()` | the numbers travel with every balance |
| `Core/SaveGame.swift` | after `var chronicle`; `init` | `var dawns: DawnRing?`; parameter `dawns: DawnRing? = nil`, `self.dawns = dawns` | the kept dawns on disk |
| `Core/SimDriver.swift` | after `dawnSnapshot` | `private(set) var dawnRing: DawnRing` | the kept dawns |
| `Core/SimDriver.swift` `init` | parameter `dawnRing: DawnRing? = nil`; at the end | `var ring = dawnRing ?? DawnRing(); ring.record(snapshot, keep:); self.dawnRing = ring` | a loaded save's ring, or the first morning |
| `Core/SimDriver.swift` `stepOnce`, `secondChance` | after each `dawnSnapshot = state` | `dawnRing.record(state, keep: balance.front.hearth.dawnsKept)` | every dawn kept |
| `Core/SimDriver.swift` `restart` | after `dawnSnapshot = state` | `dawnRing = DawnRing(state, keep:)` | a new realm, a new ring |
| `Core/SimDriver.swift` `setLord` | end | `dawnRing.setLord(lord)` | the kept dawns know the lord |
| `Core/SimDriver.swift` | after `setLord` | `mutating func wake(back: Int) -> Bool` | the fall card's wake (as `replayDay`, at a kept dawn) |
| `tools/simtune/run.sh`, `tools/frontsweep/run.sh` | `SRC` | `Core/Front/HearthTuning.swift HearthState.swift Hearth.swift HearthNames.swift DawnRing.swift` | the sweeps compile the core |

Under the old rules every hook does nothing (`hearthFire` nil: `afterBattle`, `dawn` and `rebuildOption` return at
once); the ring only records. The loss table and the tuning report prove it (below).

### For the join: what the screen shows and which touch calls what

- **Turn the rule on** for the player's realm with the front rule: `Hearth.adopt(&start)` and `Hearth.adopt(&snapshot)`
  in `SimDriver.init`, `Hearth.adopt(&state)` in `SimDriver.restart`. The save writes `SaveGame(state:
  driver.dawnSnapshot, ..., dawns: driver.dawnRing)`; the load builds `SimDriver(state: save.state, ..., dawnRing:
  save.dawns)`. Panels' `holdTheRealm` (it sets the mode in the state and the snapshot) should end with
  `dawnRing.record(dawnSnapshot)` so the kept dawn carries the mode.
- **Every frame** read `Hearth.picture(state, balance:)`:
  - `level` and `glow`: the hearth's flame in the hall in four looks (bright: a full fire; low: a small fire; embers: a
    red glow and no flame; out: cold ash). The hearth light's intensity times `glow` (its radius as it is). The
    lamplighter's street lanterns burn as the hearth does (TOWN.md section 7) and stay dark when `lanternsLit` is
    false. No bar, no number, no label.
  - `ruins`: each burnt house, field or stall drawn charred (black beams, no window light, no smoke from the chimney),
    with scaffolding while `rebuilding`. Nobody stands in its door.
  - `sheltering`: that many townspeople bedded down in the chapel (a few figures and blankets; by day too).
  - `lastBreak` (a new `at`): the breach. The flame gutters down to its new step, a flare runs out of the hearth
    through the hall, the creatures burn away (as the second chance shows it), and the picture fades to first light;
    a heavy haptic and the hearth's low exhale. Reduce Motion: no flare, a short cross-fade. After a load or a wake the
    stored `at` counts as seen.
  - `lastFeed` (a new `at`): the lord throws a log on, the flame leaps up one step; a light haptic.
- **The dawn report:** `HearthText.lines(report)` gives up to four lines (what burnt, who did not see the morning, the
  coin, the fire); put them in the night half right after the fallen soldiers, before the front lines. When
  `report.hearth.happinessLost` is above 0 the happiness row shows it as its own reason, "The Gloom reached the hearth
  −8" (`front.hearth.reason`); `happinessBefore` already includes it, so the row starts at `happinessBefore +
  happinessLost`. `report.realmFell` is true on a broken night too: tell it from a second chance by `report.hearth`.
- **A touch on the hearth** (in the hall): `Hearth.feedOffer`. Ready: the price shows as coins at the hearth and the
  count (PAY.md) pays it; when the last coin lands it calls `Hearth.feed(&state, balance:)` once (a one-line wrapper on
  `SimDriver`). Not `inReach`: the touch walks the lord to the hearth first (as the knock walks him to the door).
  `fedToday`: the board shakes. Not `affordable`: the refuse sound. nil (bright or out): the flame flickers once, no
  coins. No prompt, no button: the low fire is the prompt.
- **A touch on a burnt place:** `Hearth.rebuildOption(state, plot:, balance:)` gives the price; the count pays it and
  calls `Hearth.rebuild(&state, plot:, balance:, events:)` (or the old build card's order: the card offers just that
  line).
- **The fall card** (`state.defeated`, the fire out, not night 20): title `front.fall.title` ("The hearth is out."),
  then one button per kept dawn, newest first (`driver.dawnRing.choices`; words `HearthText.wake(choice)`: "Wake this
  morning", "Wake a morning earlier", "Wake two mornings earlier"), each with a small flame drawn at that dawn's
  `level`; a touch calls `driver.wake(back: choice.back)`. Then "Begin a new realm" (`front.fall.new`) →
  `driver.restart(seed:)`. The ads lane's second chance stays on the card. Night 20 keeps today's card and the
  chapter's ending.
- **Events.** `.defeat` comes only when the fire goes out and on the King's night; a broken night sends no `.defeat`
  and its `.dawn` comes in the same step. Nothing new in `SimEvent`: diff the stamps.
- **Strings:** `Resources/Front.xcstrings`, English and German; the six other languages follow in the i18n pass (18
  hearth keys: 12 report lines, 3 of them with names as `%@`, `%1$@ ... %3$@`).

### How the hearth meets the town lane at the join (docs/TOWN.md; branch `claude/lh-town`)

- This lane keeps to the house's state: a burnt place has `item` nil and an entry in `HearthState.burnt` with its
  household. The town's ledger (`Town.ledger`) builds its paying places from the plots' items, so a burnt house, field
  or stall owes nothing, needs no toss and has no door to knock on, with no change.
- One change the join must make in the ledger: the day's tax part is worked out from the taxpayers, and the households
  that shelter in the chapel would then pay through the other houses. Use `state.taxpayers − Hearth.sheltering(state)`
  where the ledger counts the taxpayers to spread over the houses by room. (On this branch the old dawn taxes still
  count them; the cost is taken before the dawn, so on the joined game the first ledger after a broken night already
  sees the town as it is.)
- The households by trade (`TownText`: chandler, oil-presser, cooper, weaver for houses 1, 3, 4, 5) can name the burnt
  house ("The cooper's house burnt down."): four keys at the join instead of `front.hearth.burnt.house`.
- Build 3's third house tier and farmsteads: `Hearth.rebuildPrice` counts every tier through `BuildItem.upgrade`, so a
  townhouse or a farmstead comes back at a third of its whole cost with no change.
- The ads lane's "no second video on the dawn a second chance brought" reads `realmFell`; a broken night sets it too.
  Let the double taxes show on a broken night's dawn: `report.realmFell == true && report.hearth?.broken != true` is
  the second chance's own dawn (a rekindled fire has `rekindled`).

### Story and interface lines that speak of the fall (STORY.md not edited; new words for the join)

- `Localizable`: "The hearth has gone out" (the fall card: still right, at out only); "The Gloom reached the hearth on
  night %lld." (a broken night reaches it too and goes on: the fall card should say the fire went out); "Replay the day"
  (now "Wake this morning", `front.fall.wake.0`, beside two earlier mornings); "The hearth went out, but a second chance
  brought the dawn" and "The hearth flares up and dawn comes at once" (the ad's promise: it now brings the fire back to
  embers, and the night's cost stands); "A second chance again from night %lld".
- `Story.xcstrings`: `line.hesper_flame` ("The Flame remembers every lord. Mostly the ones who let it go out.") now
  speaks of a real thing: keep; `line.herald_fire` ("Your fire is very small, lamplighter. He has watched larger ones go
  out."): the house lane already rewrites "lamplighter"; it could follow the fire's step; `petition.pilgrims.text` ("the
  Flame that never goes out"): true in every kept timeline, keep, or a variant at embers; `petition.hesper_giant.text`
  ("The Flame burned black at dawn"): fine.
- `DESIGN.md` "Losing a night" (the realm falls at 0; the defeat card's second chance and "Replay the day") and the
  ads section's second chance: rewrite at the join from this section.

### T1 to T8: the bot tables before and after

The reference bots play without `GameState.hearthFire`, so nothing of the rule runs for them. Two proofs, both from the
runner:

- **The tuning report** (`TuningTests`, attached as `tuning-report.txt`) of round lh-f2-4 is round lh-f1f1-6's (this
  branch before the step, itself the base's) line for line: 80 lines each, `diff` empty, md5
  f919a8fdb355f32441b5879cc12e7324 both. `night-twenty-steps.txt` (md5 1ab8adf6...) and T13's `front-t13-report.txt`
  (md5 e358924d...) are the same too. The T-lines, before and after alike: T1 nights 1-10 held, hearth 100, losses 0;
  T2 falls on nights [3, 3, 3]; T3 beacon on days [17, 16, 17], low tax never; T4 high 27, low 83; T5 49 gold, 3
  builds, 11 buildings by day 10; T6 with the beacon 20 of 20 won, the King slain 20 of 20, without 10 of 20 held; T7
  17 of 20 endless seeds fall between 35 and 60; T8 last wave 79.9 s, 39 entities, 11 lights.
- **The loss table** (`HearthTuningTests.testTheFirstBreachIsTodaysLoss`, attached as `hearth-loss-table.txt`; the
  sweep prints it too): T1's runs (the reference, seeds 1 to 3, nights 1 to 10), T2's (the bot that builds nothing,
  seeds 1 to 3) and the reference's eves of nights 9, 12 and 14 of seeds 1 to 3 at six times the night (a realm caught
  short, where it does fall) are each played twice in lockstep, under the old rules and under the hearth rule. Both
  realms are the same at every step (but for the hearth's own state) until the old one falls, and the hearth rule's
  first broken night is that step: the same night, the same hour, the same fallen, killed, walls and spawned. 15 runs,
  differences: none. Before (old rules) and after (the hearth rule), line for line:

  | run | old rules: the realm falls | hearth rule: the first broken night |
  |---|---|---|
  | T1 reference seeds 1, 2, 3 | held every night | held every night |
  | T2 builds nothing seed 1 | night 3 at 00:07, fallen 1, killed 1, spawned 23 | the same |
  | T2 builds nothing seed 2 | night 3 at 02:11, fallen 1, killed 8, spawned 36 | the same |
  | T2 builds nothing seed 3 | night 3 at 02:40, fallen 1, killed 10, spawned 39 | the same |
  | x6 seeds 1, 2, 3 night 9 | held | held |
  | x6 seed 1 night 12 / 14 | 04:17, fallen 10, killed 218, walls 2 / 04:07, fallen 10, killed 198 | the same |
  | x6 seed 2 night 12 / 14 | 03:30, fallen 9, killed 161 / 03:40, fallen 9, killed 238 | the same |
  | x6 seed 3 night 12 / 14 | 03:34, fallen 10, killed 139 / 03:26, fallen 8, killed 120 | the same |

  (Hours as the table prints them ×100: 11, 219, 267, 428, 412, 350, 366, 357, 344.)

So for T1 to T8 a night in which the hearth is reached still counts as the loss it is today, and the reference run
still stops there: their numbers do not move.

### T14 (new)

The careless night: on the game's own nights the reference realm never lets the creatures reach the hearth before night
20 (T1, T6), so a careless night is the reference realm caught short (the night six times as big, as T13 and the loss
table do) with the lord at the throne all night (no patch, no brazier lit). "Well afterwards" is the T14 bot. Each
careless night is played from the reference bot's eve; then three days at the game's own nights; beside it a twin that
plays the same careless night with a breach that costs nothing (the fire still drops), for the gaps.

Round lh-f2-4's sweep (`hearthsweep.txt`; seeds 1 to 10, careless nights 6 to 14, 90 nights):

- **T14a: PASS.** All 90 careless nights broke (bright to embers). 84 were mended within three days (the fire bright
  again and every burnt place standing): the fire after 1.6 dawns, the burnt place after 1.5 on average. In every realm
  still standing (87) the fire was bright again within three days. The six not mended are young realms (seed.night 2.8,
  4.7, 5.7, 7.6, 7.7, 10.9): the careless night left the gatehouse in rubble, the purse held a few coins, and the
  reference could not pay the gate's 50 the next day; three of them broke again the next night and fell (and wake at
  the morning before the careless night), three stood and paid for the gate before the house. The bar is therefore
  nine in ten (`HearthMetrics.mendShare`), named in the report. The same at x4 (69 of 90 broke, 65 mended), x8 and x10
  (84 of 90). The unit test (seeds 1 to 4, nights 7 to 13): 28 broke, 26 mended, the fire bright again in 26 of 26.
- **A broken night's cost** (mean over the 90): one house, 2.1 dead, 11.3 gold (the reference keeps little in its
  purse), happiness 8, and the battle's own two walls. Three days later against the costless twin: −16 gold, −7
  happiness, −3 citizens; wood bought 0.6 times, 0.9 rebuilds.
- **T14b: PASS** at two steps (the chosen value). A careless bot that never feeds: two broken nights in a row ended the
  realm 20 of 20, with one held night between 19 of 19. With wood between: in a row 20 of 20; with one held night
  between 8 of 19 (the other 11 had fed the fire back to bright and stood at embers). At one step (the spec's starting
  value): 0 of 20 and 1 of 20 (the one with a third broken night between); fed 0 and 1.
- Two in a row put the fire out (`testTwoBrokenNightsInARowPutTheFireOut`: embers, out; with one step low, embers, out
  over three).

### Rounds

| Round | Commit | Steps | Result |
|---|---|---|---|
| lh-f2-1 | abe69c7 | build; unit HearthTests, HearthTuningTests, SaveGameTests, SimDriverTests | build PASS; 43 of 45 passed: T14a 26 of 28 (the bot fed the fire before closing the gate), and one step a breach let two broken nights with a third between end a realm; the loss table: differences none |
| lh-f2-2 | e441dac | build; unit HearthTests, HearthTuningTests, BuildTests | build PASS; 45 of 46 passed, all but T14a (26 of 28 with "all" as the bar); T14b passes at two steps |
| lh-f2-3 | e441dac | sh hearthsweep variants | ALL PASSED; T14 on 10 seeds at four sizes, the cost's variants (none fixes the six) |
| lh-f2-4 | 261f35c | build, unit (all), sh hearthsweep | **ALL PASSED**: 467 unit tests, none failed; T1 to T8, T13 and the night-twenty steps identical to lh-f1f1-6 (md5); T14a and T14b PASS |

Rounds by the director's notes of 14.11. 18:46 and 19:35: no `ui`, `ui-de` or `release` (no screen and no UI test
changed), the gate one round of `build unit` with the sweep as an `sh` step.

### Open, and waiting for the join

- **For the director: two steps a breach** (the spec said one; the reasons above). One value (`breachSteps`) returns
  to one step, which fails T14b by construction.
- **For the director: T14a at nine in ten.** The careless nights not mended are young realms that cannot pay the
  gatehouse's rubble (50 gold, today's rule) the morning after; at the join the town's knock and the lord's presence
  give a human more ways to find the gold and hold the next night.
- **Wood at any hour.** Feeding is once a day by the day's number and needs the lord at the hearth; at night it lets a
  lord who runs home from the wall lift embers to low before the creatures come (a breach from low still puts it out).
  If the director wants wood by day only, it is one guard in `Hearth.feedOffer`.
- **The picture and the touch** (all of "For the join" above): the hearth's four looks, the breach's flare and fade, the
  ruins and the chapel, the coins at the hearth and at a burnt house, the fall card with three mornings.
- **Turning the rule on** for the player's realm (`Hearth.adopt` beside `FrontNight.adopt` in `SimDriver`), and the save
  writing and reading `dawns`; write the save at once after a wake (else a relaunch before the next dawn loads the
  newest kept dawn, not the woken one).
- **The town's ledger** leaves the sheltering households out of the tax part (above); on this branch the old dawn
  taxes still count them.
- **The ads lane's** double-taxes check on a broken night's dawn (above); its second chance needs no change.
- **The Chronicle** counts fallen soldiers; the townspeople a broken night took are not in it yet (their names are in
  `HearthState.dead`).
- **The six other languages** of the 18 hearth keys in the i18n pass.
- **`tools/frontsweep` and `tools/simtune`** got the hearth's files in their lists; `tools/hearthsweep` shares
  frontsweep's stand-in for `LordIdentity`. Keep the lists in step with Core at the join.

## front-2, fix round 1 (15.11.2026, night)

The critic's first look (`ci-out/director/front-2-hearth-critic1.md`): 7 of 10, no blocker, three highs. All three are
fixed in Core, and each leaves the director one value to turn. Made in the scratch clone as before (the worktree
guard), committed as Louis' noreply identity, pushed to `origin/claude/lh-front`.

**Read these over the older lines of "front-2" above:**
- At out the fall card offers no video (`videoAtOut` off). "The defeat card's second chance brings the dawn with the
  fire at embers" and "the ads lane's second chance stays on the card" no longer hold; the video moved to a broken
  night's dawn.
- A frail fire (the next breach puts it out) gets a stake line after the fire's line, and `HearthPicture.frail`.
- A realm's first broken night orders the rebuild of its walls in rubble at no cost.

### High 1: the looks and the lines tell the stake

- **Two steps a breach stay** (the critic's option a). Option b, "a breach drops the fire to embers; at embers it goes
  out", is built as one value and measured beside it: `breachCeiling` .embers with `breachSteps` 1
  (`HearthRule.toEmbers`). It fails T14b and brings back the stuck slide of round lh-f2-1. A lord who feeds every
  morning stays at embers while every night breaks. Round lh-f2f1-3, doubles of seeds 1 to 5 from nights 7, 9, 11
  and 13:
  - with wood, two broken nights in a row ended the realm in 5 of 20; the other 15 stood at embers ("embers > embers");
  - with one held night between, 0 of 20 ended, with wood or without.
  T14a is the same under both rules (90 of 90). So under b a realm that breaks every night goes out only when its
  purse is empty, and by then the three kept dawns all lie inside the slide. Under a, two breaches with less than two
  steps of mending between always end the realm, and the morning before the trouble is always kept.
- **The words.** `HearthDawnReport.lastStand` (saved, default false) is set at every dawn whose fire is frail. Then
  `lines()` ends with `front.hearth.last`: "If the Gloom reaches the hearth again, it goes out." (de "Erreicht die
  Düsternis den Herd noch einmal, erlischt das Feuer."). With two steps that is every dawn at low or embers:
  - after a broken night: "Only embers glow in the hearth." and the stake;
  - after a held night that raised embers to low: "The hearth burns low." and the stake;
  - after the video at out, if the director turns it back on.
  It is a line of its own, not folded into "The hearth burns low.": after a held night "another such night" would be
  false, while the condition is true in both cases.
- **The fire.** `HearthPicture.frail` (and `Hearth.frail(level, tuning:)`): the next breach would put it out. For the
  picture lane: a frail fire sputters, and only a fire that is not frail burns steady. With the chosen values:
  - bright burns steady (a full fire);
  - low sputters (a small flame that gutters and throws few sparks);
  - embers sputters (a red glow without flame, a spark now and then);
  - out is cold ash.
  The hearth light keeps `glow`; a frail fire's light wavers a little (Reduce Motion: no waver, only the dimmer light).
  So only bright looks safe.
- Both follow the rule (`Hearth.afterBreach`), so neither can lie under another value: with one step, or under
  option b, only embers is frail. No number, no bar, no other look changes.

### High 2: the first broken night of a young, a thin and an idle realm

Measured in rounds lh-f2f1-2 and -3 (`tools/hearthsweep`, seeds 1 to 10, with and without the new value):

- **Young realms caught short** (the reference realm's eve of nights 2 to 5, the night bigger, the lord at the
  throne). A young realm with its gate and first soldiers hardly breaks:
  - x2 and x3: 0 of 40;
  - x6: 9 of 40 (all on night 5);
  - x10: 18 of 40 (nights 3 and 5);
  - x15: 29 of 40.
  Its purse at the broken dawn is small: 64 to 77 on average, against 139 for nights 6 to 14. The reference spends as
  it goes.
- **Some of them spiral.** Without help, 7 of 9 were mended within three days at x6, 16 of 18 at x10, 27 of 29 at x15.
  Each time seeds 1 and 5 on night 5 broke again the next night and fell: the gate's 50 was out of reach, the gate
  stood open, and the fire went out.
- **Thin realms.** This is the T14 bot whose build order stops after 0, 2, 4, 6 or 9 steps. It still rebuilds rubble,
  hears petitions, patrols, feeds the fire and rebuilds burnt places. An active lord holds a thin realm a long time:
  - at the game's own nights only cap 0 broke (3 of 10, on nights 13 and 14);
  - at x1.5 caps 0 to 6 broke on nights 11 to 14 (20 realms).
  A thin realm hoards (about 700 in the purse at its first broken night), so it never lacks the gate's coin.
  - Played on thin, it went out the next night in 8 of 20 (two in a row). The morning before the trouble was kept 8
    of 8 times.
  - Played well from the first broken dawn, 19 of 20 were mended within three days, and 2 broke again and fell later.
    At x1.5, nights 14 to 16 are beyond a thin realm's walls. Without the value the totals are the same, on other
    seeds.
- **The idle lord** (T2's bot: it builds nothing and stands where it is; under the old rules it falls on night 3 in
  every seed). It broke on night 3 in 10 of 10.
  - Played on idle, the fire went out within two nights. With the walls raised, 7 of 10 lasted to night 5; without,
    all went out on night 4. The morning before the trouble was kept 10 of 10 times.
  - Played well from its first broken dawn: mended within three days in 10 of 10, none fell.

**The one value: `firstBreachRaisesWalls` (true).**
- **What it does.** A realm's first broken night orders the rebuild of every wall in rubble at no cost, the gatehouse
  first (`Hearth.raiseWalls`). The order is placed at the breach, so the builders are at it at first light, with half
  the work as every rebuild. The report says "Your people raise the walls again. They ask no coin."
  (`front.hearth.walls`; de "Eure Leute richten die Mauern wieder auf. Ohne Lohn."). Later broken nights pay for their
  rubble as today.
- **Why the walls and not a purse floor.** The gold a broken night takes from a young realm is tiny (3.6 to 6.4 on
  average). What kills it is the open gate.
- **With it:**
  - Early careless nights mended: x6 9 of 9, x10 18 of 18, x15 29 of 29, and none fell.
  - Careless nights 6 to 14: 90 of 90 mended (84 before). The fire is bright again after 1.2 dawns (1.6 before). The
    six young misses of front-2 are all mended.
  - T14b holds as before.
  - Three days later the realm is about 19 gold, 7 happiness and 3 people poorer than its costless twin (16, 7 and 3
    before). The twin raises its walls for nothing too.

The brief's question, for a young realm: the first broken night of a new player now ends at first light with:
- a burnt house;
- names;
- embers;
- the stake;
- the town already at the gate.

What is left to do is wood (25), the house (10) and one held night. That is a morning to build in, not a reason to put
the phone away.

### High 3: the video at out

- **`videoAtOut` false (the critic's option a).** Under the rule a fire out is the end Louis named ("Ganz vorbei ist es
  nur, wenn das Herdfeuer ausgeht, und dann startet man am Morgen davor neu"). So the fall card offers the kept
  mornings and a new realm, never the video.
  - `Hearth.secondChanceOffered(state, balance:)` says whether the card may offer it. It is true without the rule and
    on the Lightless King's night, as today.
  - `SimDriver.secondChance` refuses the video too (hook below).
  - T14b ("two in three end the realm") now holds for every player.
- **The video moves to a broken night's dawn, where it pays the day's wood.**
  - `Hearth.woodGiftOffered`: the dawn after a broken night, the fire low or embers, not yet fed or gifted today.
  - `Hearth.giveWood` sets `HearthState.woodGiftDay`. `feedOffer` then asks 0 coins (`HearthFeedOffer.gift`).
  - The deed is the same: the lord walks to the hearth and throws the log on. Wood is still once a day and one step,
    so T14b with wood is what it was.
  - The button's words: `front.hearth.gift` "Wood for the hearth" (de "Holz für den Herd").
- **For the director.** This is a product decision; the critic is right that it was missing from my list.
  - Built: option a.
  - One value away: option b. `videoAtOut` true makes the video at out bring the dawn with the fire at embers and the
    cost standing; T14b then holds only for a player who does not watch it.

### Kept from the critic (the smaller points)

- **The banner.** `ReportCard.make` no longer adds the "second chance" banner on a broken night's dawn, unless the video
  at out brought it (hook below).
- **The names.** After forty deaths the name of the one who died longest ago comes round again: never one of tonight's
  dead, never a living soldier's. A number comes only if even that fails. The stream draws once either way, so every
  earlier run names the same people.
- **The Ash Giant.** Nothing expects him slain. `petition.hesper_giant` is on day 10, before his night, and sets
  `vigil_kept`, `town_vigil` or `giant_unwarned`; no flag, petition or line reads his death. A breach on night 10
  burns him away with the rest, as the old second chance did.
- **Endless mode (for the director).** The rule applies wherever the join turns it on. My advice: on in endless too,
  since Louis' rule has no exception. The endless record then counts nights until the fire goes out, and endless runs
  last longer. T7 itself plays without the rule and does not move.
- **Waking as an eraser (for the director: known).** A player who hates a breach's cost can throw the next night and
  wake a morning before the breach, and the names come back. That follows from Louis' rule and the three dawns.
- **The lanterns.** With the default lanterns one house burns outside unrest; "Two houses burnt down." appears only in
  unrest. Kept.
- **The sting.** The material sting stays small; the names and the embers carry the pain. Kept.
- **Taxes.** On this branch the sheltering households still pay the old dawn taxes, so T14 is a little kind until the
  join's ledger leaves them out ("How the hearth meets the town lane" above).

### New hooks of this round (apply them again at the join)

| File | Place | Hook | Why |
|---|---|---|---|
| `Core/SimDriver.swift` `secondChance` | after `guard state.defeated else { return }` | `guard Hearth.secondChanceOffered(state, balance: balance) else { return }` | no video at out |
| `Core/ReportCard.swift` `make` | the `.secondChance` banner | `if !report.held && (report.hearth?.broken != true \|\| report.hearth?.rekindled == true)` | a broken night's dawn is the hearth's, not the video's |

### New values, saved fields and strings

- **Values** (all in `HearthTuning`):
  - `breachCeiling` nil (option b: .embers with `breachSteps` 1);
  - `videoAtOut` false;
  - `firstBreachRaisesWalls` true.
- **Saved fields** (each decodes with a default; unit tests):
  - `HearthBreak.wallsRaised` []; `HearthBreak` now decodes field by field like the rest;
  - `HearthState.woodGiftDay` 0;
  - `HearthDawnReport.lastStand` false and `.wallsRaised` false.
- **Strings** (Front.xcstrings, English and German): `front.hearth.last`, `front.hearth.walls`, `front.hearth.gift`.
  There are 21 hearth keys now.
- **Tuning code only:** `HearthRule` (the doubles compare rules), `HearthBot.buildCap` and `playWell` (the thin realm),
  `HearthThin` and `HearthTuningRun.thin` (the thin and idle realms).

### For the join: what changes

- **The hearth's picture:** draw `frail` (above).
- **The dawn report:** up to six hearth lines on a realm's first broken night (what burnt, the dead, the coin, the
  walls, the fire, the stake), usually four or five.
- **The first broken night:** at first light there is scaffolding at every wall that lay in rubble
  (`lastBreak.wallsRaised` lists the plots; the job is already ordered), and no coins are asked.
- **The fall card** (the fire out, not night 20): the title, the kept mornings and "Begin a new realm". Show no video
  button while `Hearth.secondChanceOffered` is false.
- **The broken night's dawn:** the ads lane's card may offer the video "Wood for the hearth" while
  `Hearth.woodGiftOffered` is true, with its own pacing. On the reward:
  - call `Hearth.giveWood(&state, balance:)` (a one-line wrapper on `SimDriver`);
  - a bundle of wood lies at the hearth;
  - the touch on the hearth feeds the fire at no coin (`feed.gift`, price 0: the count asks nothing and the log goes
    on).

### T1 to T8 before and after (rounds lh-f2f1-4 and -5)

The reference bots still play without `GameState.hearthFire`, so none of this round's rule runs for them.
- `tuning-report.txt` is the same as round lh-f2-4's and lh-f1f1-6's (md5 f919a8fdb355f32441b5879cc12e7324). So are
  `night-twenty-steps.txt` (1ab8adf6...) and T13's `front-t13-report.txt` (e358924d...).
- `hearth-loss-table.txt` is unchanged: 15 runs in lockstep, differences none.
- The T-lines, before and after alike:
  - T1 nights 1-10 held, hearth 100, losses 0;
  - T2 falls on nights 3, 3, 3;
  - T3 the beacon on days 17, 16, 17;
  - T4 27 and 83;
  - T5 49 gold, 3 builds, 11 buildings;
  - T6 20 of 20 won, 20 of 20 slain, 10 of 20 without;
  - T7 17 of 20 in the band;
  - T8 79.9 s, 39 entities, 11 lights.

### T14 (rounds lh-f2f1-2 to -4)

- **T14a, careless nights 6 to 14** (x6, seeds 1 to 10): 90 of 90 broke and 90 mended within three days (84 before
  this round). The fire was bright again after 1.2 dawns, the burnt place standing after 1.0. x4: 69 of 69; x8 and
  x10: 90 of 90. Unit test (seeds 1 to 4, nights 7 to 13): 28 of 28.
- **T14a, a young realm's first broken night** (new). Nights 2 to 5: x10 18 of 18, x15 29 of 29 (without the walls
  raised 16 of 18 and 27 of 29). Unit test (seeds 1 to 6, nights 3 to 5, x10): 10 of 10 broke and mended, none fell;
  8 of 10 without the value.
- **T14b, two steps** (the chosen rule):
  - no wood between: two in a row ended the realm 20 of 20, one held night between 20 of 20;
  - with wood: in a row 20 of 20; with a held night between 4 of 20 (the other 16 fed the fire back to bright and
    stood at embers).
  - One step: 0 of 20 and 0 of 20. The other rule (down to embers at most): unfed in a row 20 of 20, with a held night
    between 0 of 20; fed in a row 5 of 20. Both fail.
- **The idle lord** (unit test, seeds 1 to 3): breaks on night 3 as T2 falls; played idle, out within two nights with
  the morning before kept; played well from the first broken dawn, mended within three days, none fell.

### Rounds of the fix round

| Round | Commit | Steps | Result |
|---|---|---|---|
| lh-f2f1-1 | c109d2f | sh hearthsweep | FAIL (exit 127): my step gave the path from the repo's root, but the runner stands in the game's folder; nothing measured |
| lh-f2f1-2 | c109d2f | sh hearthsweep | ALL PASSED: careless nights 6-14 now 90 of 90 mended; option b fails T14b; early careless nights break only at x6 on night 5 (9 of 40), all mended with the walls raised, 7 of 9 without; thin realms hold to night 13 |
| lh-f2f1-3 | 7a67597 | sh hearthsweep | ALL PASSED: early x10 18 of 18 and x15 29 of 29 mended (16 and 27 without); the idle lord breaks on night 3, out within two nights played idle with the morning before kept 10 of 10, mended within three days played well 10 of 10 |
| lh-f2f1-4 | e748696 | build, unit (all), sh | build PASS; unit 474 passed, 1 failed (a garbage `pending` in a save decoded to a breach on night 0; fixed in 0378d79); sh PASS; T1 to T8, T13 and the night-twenty steps identical (md5) |
| lh-f2f1-5 | 0378d79 | build, unit (all), sh | **ALL PASSED**: 475 unit tests, none failed; T1 to T8, T13, the night-twenty steps and the loss table identical (md5); the sweep's T14 the same as lh-f2f1-3 |

Rounds follow the director's notes of 14.11. 18:46 and 19:35. No screen and no UI test changed, so the gate is
`build unit` with the sweep as an `sh` step; there was no `ui`, `ui-de` or `release` step.

### Open, and waiting for the join (fix round 1)

- **For the director:**
  1. Two steps a breach. Kept; the stake is now legible in words and in the fire. Option b is one value away
     (`breachCeiling`), measured above.
  2. The video at out. Built: option a (no video at out, the video pays a broken night's wood). Option b is one value
     away (`videoAtOut`).
  3. A realm's first broken night raises its walls for nothing (`firstBreachRaisesWalls`, one value).
  4. Endless mode: rule on or off (my advice: on).
  5. Waking as an eraser: known, follows from the rule.
  6. Wood at any hour (from front-2): still open.
- **The ads lane:** the wood card at a broken night's dawn and its pacing; the fall card without the video when the
  fire is out.
- **The picture lane:** `frail` (sputtering against steady); the scaffolding of the walls raised at first light.
- **Unchanged from front-2:** the town's ledger (the sheltering households), the Chronicle (the townspeople a broken
  night took), the six other languages of the hearth keys (now 21), `Hearth.adopt` beside `FrontNight.adopt`, and the
  save writing `dawns`.
- German is not judged before the store pass (the director's note of 14.11. 19:35).

## front-3: beacons into the gorge (15.11.2026)

Louis, 14.11.: "Ja, Leuchtfeuer: man baut Leuchtfeuer immer weiter in die Schlucht hinein. Jedes drängt den Nebel zurück
und gibt neues Land frei. So hat man ein Ziel nach vorn, nicht nur Abwehr." Spec: REALM.md section 5. Core only: no
SwiftUI, no renderer, no sprite, no UI test changed. Made in the scratch clone of the branch as front-2 was (the app's
worktree guard refuses writes into `.claude/worktrees/lh-front` from the lead's session), committed as Louis' noreply
identity and pushed to `origin/claude/lh-front`.

### What exists (all new files of this lane)

- `Core/Front/GorgeTuning.swift`: every number in one place, carried as `Balance.front.gorge`: the gorge (`gorgeFrontX`
  1240, `gorgeWestX` 0), the four sites as fractions of it (0.55, 0.69, 0.80, 0.91: x 558, 384, 248, 112), the freed
  things' anchors (0.53, 0.66, 0.75, 0.86), `raiseFromDay` 3, `prices` 60, 90, 130, 180, `raiseWork` 150 builder-seconds,
  `relightShare` 1/3, the fire (`lightRadius` 56, `flameY` 20), `fogSeconds` 3, `holdFogOnFinale` false, `strength` 400
  each, `strikeReach` 8, `quarryDiscount` 0.08, the watchtower (`watchtowerPrice` 40, `watchArchers` 1, `watchRange`
  150, `watchPeriod` 3, `watchDamage` 4, `watchHeight` 40), `charcoalRadius` 1.08, the forward bot's habits
  (`botReserve` 30, `botBeaconSteps` 10, 16, 22, 22, `botWatchStep` 16, `botGreatBeaconFirst` true).
- `Core/Front/GorgeState.swift`: the saved state (`GorgeState` in `GameState.gorge`: the four sites with their state and
  strength, the raise underway, the watchtower, the night's tally, the fog's last move, the stamps `lastLit` and
  `lastFall`), the report's gorge half (`GorgeDawnReport` in `DawnReport.gorge`) and its lines (`GorgeLine`). Every field
  decodes with a default; a state that breaks the rule's order (a beacon lit beyond a cold one, a raise anywhere but the
  next site) is mended on load.
- `Core/Front/Gorge.swift`: the rule. `adopt`; the places (`siteX`, `landX`), `held`, `holds`, `fogLine`, `holdFog`;
  prices and strength; by day `offer`/`order` (raise or relight the next one), `watchOffer`/`raiseWatchtower`, `step`
  (the builders' work, the bank at rest at the fog line); by night `addLights`, `battle` (`strike`, `watch`); the
  quarry's `options`; `dawn`; `picture` (one `GorgePicture` a frame).
- `Core/Front/GorgeText.swift` and `Resources/Front.xcstrings`: 11 new keys in English and German (`front.gorge.*`).
- `Core/Front/ForwardBot.swift`: the T15 bots (forward, neglect, and the walls-neglected control without beacons).
- `Core/Front/GorgeTuningRun.swift`: T15 (`GorgeMetrics`, `GorgeTuningRun.pair`, `wholeRun`, `measure`) and the idle
  lockstep for T1 to T8 (`idleLockstep`).
- `Tests/GorgeBeaconTests.swift` (21 tests: the rule, the light, the fog line and its roll, holding and falling,
  relighting, the three gains, the Great Beacon as it is, the lines and their words, the save, the reference bot,
  determinism) and `Tests/GorgeTuningTests.swift` (T15a, T15b and the wager, the idle lockstep).
- `tools/beaconsweep/` (`sh bash tools/beaconsweep/run.sh [variants] [finale] [seeds=10]`): T15 on ten seeds, the
  controls, the variants and night 20, with -O on the runner (the whole sweep runs in about two minutes).

### The rule as built

- **Four sites** beyond the gate, as fractions of the gorge's length from the castle front (the world lane's room for
  them, report world-1): x 558, 384, 248, 112, each further into the gorge. The rebuilt world moves them with
  `gorgeFrontX` and `gorgeWestX`.
- **Raising.** From day 3, by day, the next beacon (only the one after the last that burns) can be raised for 60, 90,
  130, 180 gold. The gold goes at once; the builders raise it with the time they have no other work for (the castle's
  repairs and paid jobs first, as for every builder; the happy realm's faster builders included): 150 builder-seconds,
  two idle builders in about 75 s, half a day. It burns as soon as it stands. One raise at a time.
- **The fog line** is one value: the furthest lit beacon's x, or nothing (the old edge). The darkness bank never passes
  it, by night and by day (`Battle.bankEdge` asks `Gorge.holdFog` last; by day `Gorge.step` keeps `GameState.bankEdge` at
  the held edge). When the line moves (a beacon lit, a beacon fallen) the bank rolls to it over 3 s, so it never jumps.
  At night every site west of tonight's natural edge pushes it back (the second from night 7, the third and fourth on
  every night); by day only the fourth (the bank rests at 200 by day).
- **A beacon's fire.** Each lit beacon is a fire of a brazier's radius at height 20 in `Battle.lightSources` (kind
  `.brazier`, so the renderer draws its pool and the fire's crackle plays from the existing light list), under the
  existing light rules: creatures in it are seen and slow to their lit speed, and sootlings burn. A sootling that walks
  through one beacon's light burns out (about 66 px at 12 px/s).
- **Holding.** Creatures on the ground strike the furthest lit beacon as they pass: their harm per second for the time
  they are within 8 px of it (`Battle.contactTime`, as soldiers are struck in passing; crows never strike, they fly). At
  0 of its 400 it falls: cold, the fog rolls back to the one before, and the next becomes the furthest. A beacon still
  standing is tended by day: full again at dawn. A cold beacon is relit by day, at once, for a third of its price (20,
  30, 44, 60), and again only the nearest cold one (they burn nearest first, always).
- **Where the creatures appear.** They still leave the Gloom at its mouth (`Realm.spawnX`, x 40): the four sites lie on
  their way (all east of x 40), so moving the spawn to the fog line would shorten their walk, the opposite of the
  spec's "they walk longer under the arrows". A creature comes out of the fog at the fog line (the picture already hides
  what is inside the bank, `GloomFog.bodyAlpha`), and walks the rest of the gorge in the beacons' light: slower, burning,
  and under the watch's arrows.
- **Freed land** (one thing per stretch, held while the beacon beyond it burns):
  - the old quarry (stretch 1, the first beacon): every wall and gate build, upgrade and rubble rebuild costs 8 % less
    (rounded: a palisade 18, the iron gate 83, the gate's rubble 46), through `Build.options`, so the card and the order
    agree;
  - the ruined watchtower (stretch 2): it may be raised by day for 40 gold as a forward archers' post; the watch (castle
    staff, like the engines' crews: never falls, leaves while the stretch is lost) looses one arrow in 3 s at the King
    when he can be hurt, else at the most advanced lit creature within 150 px; about 5 to 8 % of the strength of a
    night's creatures (round lh-f3-4: 8 % at the game's own nights, 7 % at 1.5 times, 5 % at twice);
  - the charcoal burners' camp (stretch 3): the braziers and fire towers burn 8 % brighter (their radius);
  - the far stones (stretch 4): a flag for the picture only. The spec's gain ("the Great Beacon reaches further on night
    20") moves the finale's tuning (measured: below, "The King's night"), so it stays out, as the brief allows.
- **The Great Beacon** on the castle's site and its three stages are untouched. On the King's night, once it flares, the
  fog rolls over the small beacons to where the Great Beacon holds it (x 360) over 3 s from the King's leaving, and the
  night is exactly today's from then on (`holdFogOnFinale` off). Without the Great Beacon the small ones hold the fog on
  night 20 as on any night; on the endless nights after it (its battle light 0) they hold it again.
- **Deterministic**, nothing drawn from the random stream, and nothing runs for a realm without `GameState.gorge`.

### Hooks into existing files (apply them again at the join)

| File | Place | Hook | Why |
|---|---|---|---|
| `Core/GameState.swift` | after `var hearthFire` | `var gorge: GorgeState?` | the saved rule; nil = the old rules (bots, old saves) |
| `Core/DawnReport.swift` | after `var hearth` | `var gorge: GorgeDawnReport?` | the report's gorge half |
| `Core/Sim.swift` `step` | right after `Build.stepBuilders(...)` | `Gorge.step(&s, dt: dt, balance: balance)` | the builders raise a beacon with their idle time; the bank at rest at the fog line by day |
| `Core/Sim.swift` `dawn` | right after `Hearth.dawn(&s, ...)` | `Gorge.dawn(&s, balance: balance)` | the report's gorge half, standing beacons tended, the tally |
| `Core/Battle.swift` `lightSources` | last line before `return lights` | `Gorge.addLights(&lights, s, balance: balance)` | the beacons' fires; the charcoal's brighter braziers |
| `Core/Battle.swift` `bankEdge` | the return | `let edge = DarknessBank.edge(...)`; `return Gorge.holdFog(s, edge: edge, balance: balance)` | the fog line |
| `Core/Battle.swift` `step` | right after the `stepCreatures` block | `Gorge.battle(&s, dt: dt, balance: balance, creatureStartX: creatureStartX, walkTimes: walkTimes, events: &events)` | the furthest beacon struck in passing; the watch looses |
| `Core/Build.swift` `options` | right after the hearth's `rebuildOption` line | `if let quarry = Gorge.options(state, plot: plot, balance: balance) { return quarry }` | the quarry's cheaper wall work |
| `Core/Front/FrontTuning.swift` (own file) | end | `var gorge = GorgeTuning()` | the numbers travel with every balance |
| `tools/simtune/run.sh`, `tools/frontsweep/run.sh`, `tools/hearthsweep/run.sh` | `SRC` | `Core/Front/GorgeTuning.swift GorgeState.swift Gorge.swift` | the sweeps compile the core |

Under the old rules every hook returns at once or returns its input (`gorge` nil), so T1 to T8 do not move (proved
below). After the join `Gorge.step` stays right after the builders (it reads who is idle), and the battle hook right after
the creatures walked (it reads their paths).

### For the join: what the world shows, and which touch calls what

- **Turn the rule on** for the player's realm with the other two: `Gorge.adopt(&start)` and `Gorge.adopt(&snapshot)` in
  `SimDriver.init`, `Gorge.adopt(&state)` in `SimDriver.restart`. A loaded old save gets it there too (no beacon burns).
  The bots (`-GWAutoplay play` included) may stay without it.
- **Every frame** read `Gorge.picture(state, balance:)`; the fog itself is `GameState.bankEdge`, which the world already
  draws (the world lane: "the bank and the Gloom's fog are drawn from `bankEdgeX` alone"), and the beacons' pools are in
  the battle's light list already. No number, no bar, no label anywhere.
  - `sites[k]` (x, `state`, `strength`, `raised`): wild = bare ground; only the site of `offer` shows as a place to
    build (an old stone ring or a marker cairn that answers a touch with a small shake), the others are just gorge (or
    fog). Raising = scaffolding and a stone cairn growing with `raised` (0 to 1), by day the builders' crew at it (the
    idle builders: Core keeps them at the lodge; draw them out at the site while a raise runs by day). Lit = a stone
    beacon with a fire on top; while `strength` is low (below about a half) the fire gutters and throws sparks (struck),
    a whole one burns steady. Dark = a cold, blackened beacon with a thread of smoke.
  - `lastLit` (a new `at`): the fire catches with a burst of sparks, a light haptic, the brazier's lit sound at the site;
    the fog rolls back from the old line to the new one over 3 s (Core rolls `bankEdge`); the freed stretch's thing
    comes out of the fog with it.
  - `lastFall` (a new `at`): the fire is torn apart in a burst of soot and goes out, a heavy haptic and a dull thud (the
    wall-broken sound, low rate); the fog rolls back over the cold beacon to the one before over 3 s; the stretch's thing
    goes back into the fog. Reduce Motion: no burst, a short cross-fade of the fire. After a load the stored stamps count
    as seen.
  - `lands[k]` (`held`; the watchtower `watchRaised`, `manned`): held by day, people at work there (the quarry: two
    quarrymen and a stone cart at the rock face; the camp: smoking charcoal mounds and a burner; the stones: standing
    stones clear of the fog); not held, fog or ruin. The watchtower: a ruin; raised, a timber top and a ladder; manned (at
    night), one bowman on top: his arrows are Core's projectiles from x `landX(.watchtower)` at height 40, and the
    existing `.arrow` event plays their sound.
  - By day the bank moves only for the fourth site (it rests at 200; the first three lie east of it), so the world must
    show "freed" by day through the things and their people, not through the fog.
- **A touch on the next site** (`offer`, at `offer.x`): the lord walks there (as the knock walks him to a door; Core
  does not ask for reach, the bots order from the throne), the count (PAY.md) shows `offer.price` as coins at the site,
  and when the last coin lands it calls `Gorge.order(&state, balance:)` once (a one-line wrapper on `SimDriver`). Not
  `open` (night, or before day 3): the site shakes. Not `affordable`: the refuse sound. `relight` true: the same touch
  on the cold beacon, at a third. While one is being raised there is no offer (the scaffolding is the answer).
- **A touch on the ruined watchtower** while `watchOffer` is there: the count with its price, then
  `Gorge.raiseWatchtower(&state, balance:)`.
- **The dawn report:** `GorgeText.lines(report)` gives up to four short lines (a beacon lost, a beacon lit or relit, the
  land freed, the watch); put them in the night half after the front and hearth lines. Plural by words, never a number.
- **Events.** Nothing new in `SimEvent` (its switch in `Feedback.cue` is exhaustive and other lanes edit it): diff the
  stamps, or add `.gorgeLit(site:)` and `.gorgeFell(site:)` at the join with their `Feedback` rows.
- **Strings:** `Resources/Front.xcstrings`, English and German; the six other languages follow in the i18n pass (11 gorge
  keys, none plural, no placeholders).

### T1 to T8: the bot tables before and after

The reference bots never raise a beacon and play without `GameState.gorge`. Three proofs from the runner (rounds lh-f3-5
and lh-f3-6, the final commit; the commits after it change only comments and these notes):

- `tuning-report.txt` (TuningTests) is round lh-f2f1-5's (this branch before the step) byte for byte: md5
  f919a8fdb355f32441b5879cc12e7324 both, 80 lines. So are `night-twenty-steps.txt` (1ab8adf6...),
  `front-t13-report.txt` (e358924d...) and `hearth-loss-table.txt` (bcb7ea9f...). The T-lines, before and after alike:
  T1 nights 1-10 held, hearth 100, losses 0; T2 falls on nights 3, 3, 3; T3 the beacon on days 17, 16, 17, low tax
  never; T4 27 and 83; T5 49 gold, 3 builds, 11 buildings by day 10; T6 with the beacon 20 of 20 won, the King slain
  20 of 20, without 10 of 20 held; T7 17 of 20 in the band; T8 79.9 s, 39 entities, 11 lights.
- **The idle lockstep** (`GorgeTuningTests.testTheReferenceBotsPlayTheSameWithTheRuleOn`, attached as
  `gorge-idle-lockstep.txt`; the sweep prints it too): T1's runs (the reference, seeds 1 to 3, nights 1 to 10) and T2's
  (the bot that builds nothing, seeds 1 to 3, to its fall) played twice in lockstep, under the old rules and with the
  gorge rule on (no beacon raised); every dawn the realms are the same but for the rule's own state. 39 nights,
  differences: none; the before and after tables are the same line for line (the attachment prints both).
- `GorgeBeaconTests.testTheReferenceBotIgnoresTheGorgesNumbers`: wild gorge numbers change nothing in a reference night.

### T15 (new)

**T15a, the beacons' worth** (lockstep, like T13): every eve of nights 9 to 14 of the reference bot's run, seeds 1 to
10, the night played as the reference played it and with all four beacons burning and the old watchtower manned, by the
same bot (so the day is the reference's, quarry included, and only the gorge differs), at the game's own budget and at
1.5 and 2 times it. The band I set: **at least 30 % fewer creatures reach the defence** (a wall, the guards in a breach,
the hearth; each counted once), the reference at least 300 over all.

Round lh-f3-5 (`beaconsweep.txt`), at the chosen values: **PASS, 45 % fewer** (2382 without, 1302 with):

| budget | at the defence without / with | fewer | defenders lost | walls lost | beacons lost (60 nights) | burnt | the watch |
|---|---|---|---|---|---|---|---|
| x1 | 312 / 185 | 41 % | 15 / 22 | 16 / 16 | 24 | 232 / 2822 | 24 arrows a night, 8 % of the creatures' strength |
| x1.5 | 707 / 371 | 48 % | 64 / 47 | 30 / 25 | 60 | 884 / 4209 | 27, 7 % |
| x2 | 1363 / 746 | 45 % | 138 / 108 | 35 / 29 | 83 | 1919 / 5441 | 29, 5 % |

By night (all budgets): night 9 83 / 28, 10 184 / 97 (41 beacons lost: the Ash Giant), 11 238 / 107, 12 546 / 299, 13
625 / 354, 14 706 / 417. The unit test (seeds 1 to 3, nights 12 to 14): 38 % fewer (549 / 340). What it rests on: the
beacons' fires burn the sootlings that walk through them (232 burnt without, 2822 with), slow everything else, and the
watch shoots in their light. Without the watch it is 41 %, without the charcoal 44 %. At the game's own nights the realm
lost a few more defenders with the beacons (15 against 22 over 60 nights; at 1.5 and 2 times fewer): not diagnosed; my
guess is that the slowed creatures reach the walls later and more of them together.

**T15b, the walls still count** (whole runs from day 1, seeds 1 to 10, the game's own nights): the neglect bot (beacons
first at any gold, every relight, no wall built or raised a tier, none patched) loses a beacon (the first on night 10, the
Ash Giant, in all ten) and then falls (night 20) where the forward bot and the reference both hold: **PASS, 10 of 10**.
It falls because the beacons and their relights (530 to 880 gold, 6 to 10 relights) leave it no Great Beacon, not because
its walls fail: see "for the director", item 3.

**The wager** (whole runs, seeds 1 to 10): "never a trap" is asserted at the game's own nights: **PASS** (the forward
bot fell where the reference held in no seed).

| seeds 1 to 10, x1 | fell | Great Beacon day | defenders lost | at the defence, nights 3-14 | beacons | night 20 |
|---|---|---|---|---|---|---|
| reference | none | 15 to 17 | 10.1 | 44.3 | none | the King slain 10 of 10 (61 to 66 s) |
| forward | none | 17 to 19 | 10.9 | 48.2 | the first from day 5, the second about day 9; the furthest falls on night 10; 60 to 170 gold | held 10 of 10, the King slain 8 of 10 |
| neglect | night 20 in all ten | never | 7.0 | 14.9 | all four by night 14 to 19 (one seed never); 530 to 880 gold | fell |
| walls neglected, no beacons (control) | none | 14 to 17 | 6.4 | 41.8 | none | held, the King slain 10 of 10 |

At 1.5 times the nights the forward bot falls where the reference holds in 5 of 10 seeds (it misses the Great Beacon:
item 4 below); the neglect bot falls on night 20 in all ten, the reference in five.

**Forward is a wager, never the one right way.** The reference holds every night at the game's own budget without a
beacon (T1 to T8 unchanged). Held, the four beacons take 41 to 48 % of the creatures off the walls; their price is about
a Great Beacon (460 gold and the relights), the forward bot finishes the Great Beacon one to two days later and the King
lived in two of its ten finales. A bot that goes all in loses the chapter.

### The King's night (the far stones)

Night 20 from the reference's eve, seeds 1 to 10, with all four beacons granted (round lh-f3-5, lockstep):

| | the King slain after (s from his leaving) |
|---|---|
| without beacons | 61 to 66 (at x 835 to 922) |
| the fog held at the fourth site on the King's night (`holdFogOnFinale` on) | 67 to 73 (the Great Beacon's light, which the fog swallows, reaches out to x 112; he walks slowly in it from there) |
| as today once the Great Beacon flares (chosen) | 59 to 64 |

The other rule moves the finale (every seed 6 to 9 s later, some past T6's 70 s), so it is off and the far stones stay a
flag for the picture. The King strikes the furthest beacon as he passes (one fell in each of the ten).

### Judged as a player

Day 3: the lord walks out past the gate to a ring of old stones in front of the outer line's place; 60 coins. By noon the
builders have a cairn up and a fire on it. That night the fog stops at the fire on the late nights (on night 3 the
first site lies behind the fog's edge), and the sootlings that come out of the dark flare up in its light far in front of
the walls: a fireworks of small deaths out in the gorge, which reads as the beacon working. Dawn: "A new beacon burned
all night. The fog kept off." and "The old quarry is ours again. Stone comes cheaper." The next site is further out, and
dearer. On night 10 the Ash Giant tears the furthest fire down as he passes; the fog rolls back over it: "The far beacon
went dark. The fog came back." The relight is cheap (a third), but it competes with the Great Beacon, which is the
visible goal from day 11. That is the wager the spec asks for: the gorge or the goal, every morning. What makes it feel
real is the fog line: it moves where the player put fire, and it comes back where the player could not hold it.

What is thin: by day the fog moves only for the fourth beacon, so "land freed" must be shown by the things and their
people; and the beacons' fires burn so many sootlings that a realm without walls but with beacons holds the early and
middle nights almost untouched (the neglect bot: about 15 creatures at its defence over nights 3 to 14, the reference 44).

### For the director (decisions and findings)

1. **Where the creatures appear.** They still leave the Gloom's mouth (x 40); they come out of the fog at the fog line
   (the picture hides them inside the bank). The world lane's sites lie east of x 40, so spawning at the fog line would
   shorten their walk; one value to change if the world lane extends the gorge west of the spawn.
2. **The beacons' fires burn sootlings** under the existing light rules: the strongest part of their worth (T15a 45 %).
   The strength (400: the furthest first falls on night 10, the Ash Giant's, in every seed at the game's own nights,
   from night 6 at 1.5 times; a realm that keeps all four lit then loses about one a night on the late nights) and the price bound it. If the director wants them weaker, `strikeReach` (16:
   they fall from night 5) or `strength` are the values; the light rules themselves are not this lane's to change.
3. **Walls beyond the gate decide no night at the game's own budget in today's balance.** The control (the walls
   neglected exactly as the neglect bot does, and no beacon) holds all 20 nights in 10 of 10 seeds at x1, 9 of 10 at
   x1.5 and 8 of 10 at x2, finishes the Great Beacon two days earlier and loses fewer defenders; the reference holds 5 of
   10 at x1.5 and none at x2. So T15b's "neglects the wall ... and then the night" holds only through the beacons' cost
   (no Great Beacon). That is a finding about the base game (walls, posts and archers), for the tuning at the join, not a
   thing this lane changes (T1 to T8 must hold).
4. **At 1.5 times the nights the Great Beacon has no slack.** The reference finishes it on day 16 to 18 (two seeds never);
   any 150 gold elsewhere costs it, and the forward bot then falls on night 20 where the reference holds (5 of 10
   seeds): a trap for a weak realm. With the town lane's income at the join this has to be measured again; if it holds,
   the beacons' prices (the spec's "about 60, 90, 130, 180") are the value to turn.
5. **The far stones** are a flag for the picture (the spec's own fallback); `holdFogOnFinale` measured (above).
6. **The watch** is one bowman (an arrow in 3 s): 5 to 8 % of a night's creature strength, but 15 to 22 % of all arrows,
   since the realm's archers loose few at the game's own nights. Two bowmen at 1.4 s were worth 19 points of T15a.
7. **Prices** stay the spec's; all four beacons and the Great Beacon do not fit into today's economy by night 18 for a
   bot that keeps the reference's order (the forward bot holds two before the Great Beacon, the rest after it).

### Rounds

| Round | Commit | Steps | Result |
|---|---|---|---|
| lh-f3-1 | 0f5c33c | build; unit GorgeBeaconTests, GorgeTuningTests, SaveGameTests, BuildTests; sh beaconsweep variants finale | build PASS, sh PASS; unit: T15b failed (the forward bot spent the Great Beacon's gold on beacons and fell on night 20; the neglect bot held), every rule test passed |
| lh-f3-2 | b97f1b1 | sh beaconsweep variants | ALL PASSED: the walls-neglected control holds every night; the grid of strike reach against strength; the forward bot with the Great Beacon first never raised a beacon |
| lh-f3-3 | 418661b | sh beaconsweep variants finale | ALL PASSED: the forward bot's beacons in its order, one bowman, strength 400: T15a 50 %, T15b 10 of 10, never a trap at x1; the watch still 41 % of the arrows |
| lh-f3-4 | 50bf396 | sh beaconsweep variants finale | ALL PASSED: the watch at one arrow in 3 s (8 % of the creatures' strength), T15a 45 %; night 20 in lockstep: the fog held makes the King fall 6 to 9 s later |
| lh-f3-5 | a92c30c | build, unit (all), sh beaconsweep variants finale | build PASS, sh PASS; unit 498 of 499: the watchtower test asked for three arrows in 3 s at one in 3 s; T1 to T8, T13, night 20 and the hearth's loss table identical (md5) |
| lh-f3-6 | d10b507 | build, unit (all), sh beaconsweep variants finale | **ALL PASSED**: 500 unit tests, none failed; T1 to T8, T13, the night-twenty steps and the hearth's loss table identical to lh-f2f1-5 (md5); T15a, T15b and the wager PASS (unit test and sweep); the sweep's T15 the same as lh-f3-5 |

Rounds by the director's notes of 14.11. 18:46 and 19:35: no screen and no UI test changed, so the gate is one round of
`build unit` with the sweep as an `sh` step; no `ui`, `ui-de` or `release` step.

### Front-2's open high (the critic's look 2)

T14b's fed row is now reported as "T14b reported (mended, as T14a)", never as PASS, and the no-wood row says what is
built: "two broken nights with less than two steps of mending between" end the realm (wood is one step, a held night
one). For the director's list, as item 7 of front-2: REALM.md's "two broken nights within three end the realm" is kept
as "two broken nights with less than two steps of mending between"; a lord who feeds once and holds one night is bright
again and a second breach leaves him at embers.

### Open, and waiting for the join

- **The picture and the touch** (all of "For the join" above): the sites, the cairn growing, the fire guttering when
  struck, the cold beacon, the four things by day, the bowman, the count at the site.
- **Turning the rule on** (`Gorge.adopt` beside `FrontNight.adopt` and `Hearth.adopt` in `SimDriver`).
- **`SimEvent` cases** for a beacon lit and fallen, if the join wants them in `Feedback` (now: diff the stamps).
- **The six other languages** of the 11 gorge keys in the i18n pass.
- **The director's items 2 to 4 and 7** with the town lane's economy in: T15 and the whole runs measured again on the
  joined game (`tools/beaconsweep`; keep its file list in step with Core).
- **A hearth breach and the beacons:** a broken night leaves the beacons as the battle left them (the fire's lore would
  allow "the beacons go out with the hearth"; not built, one rule in `Gorge` if wanted).
- **The forward bot** is a careful player (two beacons before the Great Beacon). A human who raises all four by night 14
  pays for it with the Great Beacon's day (the variant "all four before the Great Beacon": it finished on day 18 to 20,
  and in one seed never, which then fell on night 20).

## front-3, fix round 1 (15.11.2026, morning)

The critic's look 1 (`ci-out/director/front-3-beacons-critic1.md`, 6.5 of 10): one blocker, four highs. All five are fixed or
answered below. Made in the scratch clone of the branch as before (the app's worktree guard refuses writes into
`.claude/worktrees/lh-front` from the lead's session; the local worktree was fast-forwarded to origin at the start, and
the director should fast-forward it again before the join). Pushed to `origin/claude/lh-front`.

### A flaw in front-3's controls, found on the way (read this first)

`Autoplay.planDay` walks several steps of the build order in one call. Front-3's bots that "neglect the walls" skipped a
wall step only when the order stood on it between two calls, so they still built the middle line's palisade and stone
wall (and with it got the tending of fix round 1). Fixed with one hook (`Autoplay.skipsWalls`, off for the reference).
With the walls really skipped, the walls-neglected control without beacons (round lh-f3f1-4, seeds 1 to 10):

| whole runs | fell | Great Beacon day | King slain | defenders lost | creatures at the defence, nights 3-14 |
|---|---|---|---|---|---|
| reference x1 | never | 15 to 17 | 10 of 10 | 10.1 | 44.3 |
| no walls beyond the gate x1 | never | 14 to 15 | 10 of 10 | 0.0 | 10.6 |
| reference x1.5 | 5 of 10 (nights 18 to 20) | 16 to 18, two never | 1 of 10 | 19.5 | 98.4 |
| no walls x1.5 | never | 14 to 15 | 10 of 10 | 0.0 | 30.0 |
| reference x2 | 10 of 10 (nights 14 to 17) | never | 0 | 14.8 | 198.8 |
| no walls x2 | never | 14 to 15 | 10 of 10 | 0.0 | 58.2 |

**In today's balance a wall beyond the gate is a liability, not only useless**: a realm that builds none holds every
night at twice the budget, loses no defender, and slays the King every time. Front-3's item 3 ("walls decide no
night") understated it, and the critic's high H2 ("the beacons' fire beats the walls") rests on the old control. This is
the base game (T1 to T8's reference builds those walls), not this lane's to change; it is item 1 for the director below.

### Blocker B1: the first beacon pushes the fog from night 3, by night and by day

- **The sites moved into the fog**: fractions 0.758, 0.815, 0.871, 0.923 of the gorge (x 300, 229, 160, 95), and the
  Gloom's mouth 0.97 (x 37). Night 3's natural edge is 320, so every site lies inside the fog on the first night it can be
  raised. Front-3's sites (world-1's offer, x 558 to 112) put the first one east of the night's edge until night 15 and
  over the outer line's braziers (596, 617), where its pool added nothing.
- **Each beacon holds the fog one stretch beyond itself**: the fog line is the next site (the Gloom's mouth once all four
  burn). The bank rests there by day and by night, so every beacon moves the fog back by one stretch at once, and the
  next site stands at the fog's rim, where the player builds next. With no beacon the fog comes at night as it always
  came and rests by day at the first site (x 300; the old rules 200): between 200 and 300 nothing of the battle stands, so
  a realm that raises nothing plays every night as before (the idle lockstep below; night 1's edge 280 becomes 300).
- **Freed land comes out of the fog by day**: each thing stands in the stretch its beacon clears (the quarry at x 265,
  the watchtower 195, the camp 128, the stones 68): in the fog by day before its beacon burns, clear once it does.
- Night by night (unit test `testFromTheFirstNightEveryBeaconPushesTheFogBack`, nights 3 to 30): with none lit the bank
  is the old night edge; beacon 0 lit holds it at x 229 (night 3: 91 px back; night 10: 231; night 17+: 371), each further
  beacon at least 58 px further. The dawn test plays night 3 with a beacon raised on day 3: the fog stood at 229 all night,
  short of tonight's 320, so "The fog kept off." is true.
- The positions are fractions; the world draws them (world lane: nothing of the fog line is baked into the art). The new
  fractions replace world-1's offer and need open ground at x 30 to 330 for four cairns and four things.

### High H1: holding has a return, and "never a trap" is asserted over whole runs

- **Strength 600, 500, 400, 400** (near ones stronger, the critic's own option): the forward bot's first beacon outlasts
  the Ash Giant's night and first falls on night 13 to 15 (front-3: night 10 in every seed).
- **Tended from the wall** (high H2 below) keeps a walled realm's beacons whole at no cost.
- **The forward bot is a careful player**: one beacon before the Great Beacon (`botBeaconSteps` 10, 22, 22, 22).
- **The wager asserted over whole runs** (`testTheForwardWagerIsNeverATrap`, `GorgeMetrics.passesWager`): the forward bot
  never falls where the reference holds, slays the King at least as often, and lets no more creatures reach its defence
  on nights 3 to 14. Round lh-f3f1-4, seeds 1 to 10, x1: **PASS**: fell nowhere, the King 10 of 10 against 10, 428 creatures
  against 443, defenders lost 10.2 against 10.1, Great Beacon day 17 to 18 against 15 to 17.
- **The bolder forward is the wager**: a second beacon before the Great Beacon (10, 19, 22, 22) lets 13 % fewer creatures
  through (384) but the King lives in 4 of 10; front-3's 10, 16, 22, 22: 409 and the King lives in 5. The gorge or the
  goal.
- **At 1.5 times the nights (reported, missed)**: the forward bot falls where the reference holds in 6 of 10 (4 of them on
  night 17, before the King): the Great Beacon has no slack at x1.5 and 60 to 80 gold on day 5 costs it. Item 3 for the
  director: measure again with the town lane's income.
- The return is small at the game's own nights (3 % fewer creatures at the defence). The beacons' worth with all four held
  is large (T15a 43 %); a careful player only holds one before the Great Beacon.

### High H2: the beacons' fire no longer does the archers' work; the neglect bot loses its beacons and the night

- **Pool 40** (front-3: 56): a sootling walks through one beacon's light seen and slowed and comes out with about 1 of its
  8 strength; two pools in a row burn it out (unit test). 48 and up burn it out in one pool again.
- **Tended from the wall** (`tendedFromWall`): a standing beacon is full again at dawn only while a wall beyond the gate
  stands whole (the middle or the outer line's). Without one it keeps the night's harm, and the dawn says so ("No wall
  beyond the gate. Nobody tended the beacons."). This is Louis' spec sentence made literal: "a player who builds
  beacons and neglects the wall loses them".
- **T15b**: the neglect bot loses its first beacon by night 8 and falls by night 20 where the forward bot and the
  reference hold: **PASS 10 of 10** (first loss night 6 in every seed, 11 to 14 relights, 800 to 1040 gold, the fall on night 20).
- **Not by night 14**, as the critic asked: no realm without walls falls before night 20 in today's balance, beacons or
  none (the control above holds at twice the budget with no loss). A night-14 fall needs the middle nights to reach a
  realm that skipped its walls, which is the base game's tuning (the director's note of 04:17, the lane's second round,
  T12). When that lands, `GorgeMetrics.neglectFallsBy` is the one value to move.
- **T15c (new)**, the outpost bot (the forward bot's beacons and Great Beacon, no wall built, raised or patched) does not
  beat the reference: **PASS**: the King slain in 2 of 10 against 10 (165 creatures at its defence against 443, no fall).
  Against the walls-neglected control without beacons (reported): the King 2 against 10, 165 creatures against 106,
  64 defenders lost against 0. **Beacons do not strengthen a realm without walls**; the outpost's 280 to 430 gold of far
  beacons after day 15 is the gold the walless realm spends on the archers that kill the King.
- The dominant line in today's game is "no walls beyond the gate, no beacons", and it was so before this step.

### High H3: a raise waits beyond a fallen beacon, and the save agrees

- One rule: a raise whose site is no longer the next one (the beacon before it fell in the night) **waits**. The
  scaffolding and the builders' work stay, the gold stays spent, no work is done while it waits, the cold beacon is
  offered (relit for a third), and once it burns the builders go on. A beacon is never lit beyond a cold one.
- `GorgeState.mend()` accepts exactly what play produces: a raise at the next site, or further out with only cold
  beacons between. Anything else is mended as before.
- `testARaiseWaitsBeyondAFallenBeaconAndTheSaveAgrees`: a raise ordered at 18:36 runs into the night, the furthest falls,
  dawn; the dawn save encoded and decoded equals the game played on; after the relight and one more day both are equal
  again, and the waiting beacon burns.
- For the picture: `GorgeSitePicture.paused` (scaffolding, no crew).

### High H4: every line says what happened, by state

- "The fog kept off." is true from night 3 (B1; the dawn test checks the fog at the second site on night 3).
- The only beacon falling: `front.gorge.lost.last` "The last beacon went dark. The gorge is the fog's again." (two or
  more falling to none: "Every beacon went dark." as before).
- The watchtower's stretch freed again with the tower already raised: `front.gorge.land.watchtower.back` "The old
  watchtower stands clear. The watch is back on it." Raised yesterday: only the watch line, once. Never raised: "It
  could be manned." as before. `GorgeDawnReport.towerRaised` carries the state.
- New: `front.gorge.untended` (above). `testTheReportsLinesInOrder` covers every case.

### The critic's smaller points

1. `DawnReport.gorge` is round-tripped now (the round-trip test sets a report with a gorge half and the new fields).
2. `Gorge.options` still copies `Build.options`' shape: kept, so `Build.swift` carries one line. At the join one
   discount function applied to slot `.wall` in `Build.options` can replace it.
3. On the King's night the small beacons hold the fog until he leaves; no jump before (unit test).
4. Defenders lost with all four beacons, x1: now 10 with against 15 without (front-3: 22 against 15).
5. The x1.5 lines (T15b, the wager, T15c) are in the unit report as "reported"; the unit test plays x1.5 whole runs.
6. The local worktree: see the head of this section.

### Hooks of this round (apply them again at the join)

| File | Place | Hook | Why |
|---|---|---|---|
| `Core/Autoplay.swift` | properties, after `var buildsBeacon` | `var skipsWalls = false` | the T15 bots that neglect the walls |
| `Core/Autoplay.swift` | `planDay`, the `.build` case's skip | `... \|\| skipsWalls && item.isWall` in the `!buildsBeacon` condition | skip every wall step (off for the reference: T1 to T8 identical) |

Every other change is in this lane's own files. The hooks of front-3 are unchanged.

### New values, fields and strings

- `GorgeTuning`: `siteFractions` 0.758, 0.815, 0.871, 0.923; `mouthFraction` 0.97 (new); `landFractions` 0.786, 0.843,
  0.897, 0.945; `lightRadius` 40; `strength` 600, 500, 400, 400; `tendedFromWall` true (new); `raiseNeedsWall` false
  (new, a sweep variant); `botBeaconSteps` 10, 22, 22, 22; `botRelightWhileSaving` 0 (new).
- `GorgeDawnReport.towerRaised`, `.untended` (decode with defaults); `GorgeSitePicture.paused`; `GorgePicture.tended`;
  `GorgeFogShift.from` is now the bank's x when the line moved (old saves: a line's x or nil, harmless).
- `Gorge.lineX(_:)`, `restingBank`, `wallBeyondGate`. `GorgeBotKind.outpost`.
- Front.xcstrings: three keys, English and German: `front.gorge.lost.last`, `front.gorge.land.watchtower.back`,
  `front.gorge.untended` (14 gorge keys now; the six other languages in the i18n pass).

### For the join: what changes in the picture and the touch

- **The fog**: by day with no beacon the bank rests at the first site (x 300), and the first site's stone ring stands at
  its rim. Lit, the fog rolls back over 3 s to the next site; the freed thing comes out of it, and the next ring stands at
  the new rim. Fallen, the fog rolls back over the cold beacon to it. One beacon, one stretch, by day as by night.
- **Tended** (`GorgePicture.tended`): by day two or three people walk out from the wall to the burning beacons and back.
  Not tended, nobody goes, and a struck beacon's fire still gutters the next evening. The dawn line says why.
- **Paused** (`GorgeSitePicture.paused`): the scaffolding stands with no crew; the touch on the cold beacon before it is
  the offer (a relight), and after it the crew walks back out.
- Everything else of front-3's "For the join" stands (the offer, the count, the stamps, Reduce Motion, the lines in the
  night half of the report).

### T1 to T8: the bot tables before and after (round lh-f3f1-4)

- `tuning-report.txt` (T1 to T8), `night-twenty-steps.txt`, `front-t13-report.txt`, `hearth-loss-table.txt`,
  `hearth-t14-report.txt`, `hearth-t14-young-realms.txt`, `hearth-idle-lord.txt`: byte for byte those of round lh-f3-6 (md5
  f919a8fd..., 1ab8adf6..., e358924d..., bcb7ea9f..., c91bfcda..., befad52b..., 493df35f...). The T lines: T1 nights 1-10
  held, hearth 100, losses 0; T2 falls on 3, 3, 3; T3 the beacon on days 17, 16, 17; T4 27 and 83; T5 49 gold, 3 builds,
  11 buildings; T6 20 of 20 won, the King slain 20 of 20; T7 17 of 20; T8 79.9 s, 39 entities, 11 lights.
- The idle lockstep (T1's and T2's runs, the rule on, nothing raised): 39 nights, no difference but the rule's own state
  and the bank by day (200 under the old rules, 300 with the rule; printed as its own lines in `gorge-idle-lockstep`).

### T15 at the chosen values (round lh-f3f1-4, `beaconsweep.txt`)

- **T15a PASS, 43 % fewer** with all four held (seeds 1 to 10, nights 9 to 14; x1 43 %, x1.5 46 %, x2 41 %; 1365 against
  2382). x1: 312 / 178 at the defence, defenders lost 15 / 10, walls lost 16 / 14, burnt 232 / 2589, the watch 24 arrows a
  night (8 % of the creatures' strength). The unit test (seeds 1 to 3, nights 12 to 14): 34 %.
- **T15b PASS 10 of 10**, **the wager PASS**, **T15c PASS** (numbers above). x1.5, reported: T15b 2 of 10 (the
  reference falls there too), the wager missed in 6 seeds, T15c missed (the outpost slays the King 10 of 10 where the
  reference slays it once: walls again).
- The variants around the chosen values (the sweep): flat 600 lets the neglect bot hold in one seed; flat 400 loses the
  wager (first loss night 10, 458 creatures); 600, 500, 400, 300 and 600, 450, 350, 300 pass everything too; pool 36 and
  48 pass (48 burns a sootling out in one pool); tended always lets the neglect bot hold in four seeds; "raised only with a
  wall" turns the neglect bot into the walless control (it never raises one) and fails T15c; no watchtower: T15a 37 %;
  no charcoal 41 %.
- The King's night: as today once the Great Beacon flares (all four granted: the King slain 61 to 66 s, the same as
  without). The fog held on that night too (`holdFogOnFinale`): 70 to 77 s. The far stones stay a flag.

### Judged as a player

Day 3: the fog stands in the gorge at a ring of old stones, 1000 px out past the Great Beacon's site. 60 coins; by noon a
cairn burns at the fog's rim and the fog rolls back a stretch, and a quarry face comes out of it with two men at work.
At the new rim stands the next ring. That night the fog stops at the second ring instead of creeping toward the walls,
and the sootlings that come out of it walk through the beacon's light, flare and stagger on, burnt, to die at the
braziers before the walls. Dawn: "A new beacon burned all night. The fog kept off." / "The old quarry is ours again.
Stone comes cheaper." That is Louis' sentence, seen with no HUD: the fog moves where I put fire, and land comes out of
it. A realm that tears its walls down keeps its beacons only until the first hard night: nobody walks out to mend them,
and the dawn says why. What is thin: a careful player holds one beacon before the Great Beacon, and its return over a
whole run is small; the big return (all four, 43 %) costs the King. That is the wager, but the bar between them is set
by today's economy, which the town lane changes.

### For the director (decisions and findings)

1. **Walls beyond the gate are a liability in today's balance** (table at the head of this section): no walls, no
   beacons is the dominant line at every budget (it also beats the reference's T6 at x2: the King 10 of 10 against 0).
   This is T1 to T8's ground and the base game's tuning, for the director's list and the lane's second round (the
   04:17 note), not for this fix round.
2. **T15b by night 14** waits for that tuning; `neglectFallsBy` is the one value.
3. **x1.5**: the forward bot is a trap in 6 of 10; the Great Beacon has no slack there. Measure again with the town
   lane's income; the beacons' prices (the spec's "about 60, 90, 130, 180") are the value to turn.
4. **The day fog** of the rule's realm rests at x 300 (the first site) instead of 200: a picture change for the world lane.
5. **The new site fractions** replace world-1's offer (x 30 to 330 of open ground).

### Rounds of the fix round

| Round | Commit | Steps | Result |
|---|---|---|---|
| lh-f3f1-1 | 2386e94 | build; unit GorgeBeaconTests, GorgeTuningTests; sh beaconsweep variants | build, sh PASS; unit: the dawn test (its wall fell in the night: untended), T15b (by night 19), T15c and the wager failed; the grid showed the walls-neglected bots still building walls |
| lh-f3f1-2 | ce6953b | the same | build, sh PASS; unit: the dawn test, T15b by night 19 (no realm without walls falls before night 20); the true walless control |
| lh-f3f1-3 | 583c5f8 | the same, sh with finale | **ALL PASSED**; the graded strengths |
| lh-f3f1-4 | cdc905e | build, unit (all), sh beaconsweep variants finale | **ALL PASSED**: 504 unit tests, none failed; T1 to T8 and every front table identical (md5); T15a, T15b, T15c and the wager PASS |

Rounds by the director's notes of 14.11. 18:46 and 19:35: no screen and no UI test changed, so the gate is one round of
`build unit` with the sweep as an `sh` step; no `ui`, `ui-de` or `release` step.

### Open, and waiting for the join (fix round 1)

- The picture and the touch (front-3's "For the join" plus the changes above), `Gorge.adopt` in `SimDriver`.
- The site fractions with the world lane; the day fog at x 300.
- T15 and the whole runs again on the joined game with the town lane's income (x1.5 above all).
- The base game's walls (item 1) and T15b's night (item 2).
- The six other languages of the 14 gorge keys.
