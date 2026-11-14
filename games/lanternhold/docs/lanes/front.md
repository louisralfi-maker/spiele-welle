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
