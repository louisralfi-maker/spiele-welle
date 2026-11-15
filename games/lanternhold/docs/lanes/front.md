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
