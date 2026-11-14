# Front lane (branch `claude/lh-front`)

The night and the dark side, in Core (docs/REALM.md sections 3 to 5). One heading per step: what exists, the hooks
into existing files (so the join can apply them again on the rebuilt game), the rounds, what is open and what waits for
the join.

## front-1: being there counts (14.11.2026)

Louis, 14.11.: "Dabei sein zählt: wo der Burgherr steht, kämpfen seine Leute besser und halten länger. Kein Kampfmenü,
man rennt dorthin, wo es brennt." Spec: REALM.md section 3.

### What exists (all new files of this lane)

- `Core/Front/FrontTuning.swift`: every number of the rule in one place, carried as `Balance.front` (presence radius 90,
  speed ×1.15, harm ×0.8; relight reach 20 px, one in 4 s; touch 6 px, throw 60 px, shaken 8 s, grace 1.5 s; the
  present bot's values; the dawn report's thresholds).
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
  (along the ground, as the old rally) loose and strike ×1.15 as fast (their cooldowns; the guards' blows) and take
  ×0.8 of the harm (in the breach and in passing). It replaces the old rally while the rule is on: the rally (DESIGN.md
  "The king at night": 80 px, ×1.25) is the same idea without the harm, and two bonuses for one thing would stack to
  ×1.44. The engines are crewed by castle staff and get nothing.
- **Braziers.** A dead brazier within 20 px of him catches from his lantern, free, at most one in 4 s; the existing
  `SimEvent.brazierLit(plot:)` fires, so the lantern sound already plays. By day nothing (braziers burn all day).
- **The old Light action** (`Sim.light`, `KingAction.light`, the old screen's button) still works and is marked as
  going. The reference bot lights with it: it must stay in Core for T1 to T8 (or they must be measured again); only the
  player's button goes.
- **Patching** is `Sim.patch` as it was. New form: `FrontNight.wallHere` (the standing wall in his reach),
  `patchOffer` (price, ready, affordable, strength) and `patch(plot:)`, which patches only the wall he stands at.
- **He cannot die.** A creature on the ground that comes within 6 px of him (or would walk through him in this step)
  with nothing between them (a standing wall's face, the guard line, the hearth: as the battle stops creatures) throws
  him 60 px toward the castle at once, breaks off an old-screen Light, and shakes him for 8 s: no presence. For 1.5 s
  after a throw no creature throws him again (they pass him). Crows never throw. The lantern's radius is not touched
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
| `Core/Battle.swift` `hurtGuards` | the holders' loop | `aura`, `share = aura.harm(at: soldier.x)`; `left * share`, `max(0, room) / share` | the guards' harm share |
| `Core/Battle.swift` `stepSoldiers` | `let kingX = s.king.x` and the archers' rally | `let aura = LordAura(...)`; `rally = aura.speed(at: soldier.x)` | presence or the old rally |
| `Core/Battle.swift` `contactDamage` | before the soldier loop; the hp loss | `let aura = LordAura(...)`; `* aura.harm(at: s1)` | harm in passing |
| `tools/simtune/run.sh` | `SRC` | the three files `Core/Front/FrontTuning.swift FrontState.swift FrontNight.swift` | simtune compiles the core |

Under the old rules every hook computes exactly the old numbers (`x * 1.0`, `x / 1.0` and the rally's own expression),
so T1 to T8 are the same line for line (see the rounds).

### For the join: what the screen shows and which touch calls what

- **Turn the rule on** for the player's realm: `FrontNight.adopt(&start)` and `FrontNight.adopt(&snapshot)` in
  `SimDriver.init`, and `FrontNight.adopt(&state)` in `SimDriver.restart`. A loaded old save gets it there too. The
  bots (`-GWAutoplay play` included) may stay without it.
- **Every frame** read `FrontNight.picture(state, balance:)`:
  - `underPresence` (soldier ids): those people straighten and shout, a warm rim on them (REALM.md section 3). No
    circle, no number, no HUD. Reduce Motion: the rim without the straightening bob.
  - `lastThrow` (a new `at`): slide the lord from `fromX` to `toX` over about 0.3 s (ease out), a dust puff, a heavy
    haptic and a dull thud (the wallHit sound, low rate). Reduce Motion: no slide, a short cross-fade.
  - `shakenLeft`, `shakenShare`: he stoops and the lantern sways while shaken; he straightens when it ends. The
    lantern's radius stays (it is the stage lane's).
  - `lastRelight` (a new `at`): a spark from his lantern to the brazier, the brazier flares. The sound comes from
    `SimEvent.brazierLit` already.
  - `patch` (`FrontPatchOffer`): coins over the damaged wall where he stands; a touch on that wall raises the price, a
    second touch calls `FrontNight.patch(&state, plot: offer.plot, balance:, events:)` (add a one-line wrapper on
    `SimDriver`). Not `ready`: the coins shake; not `affordable`: dull coins and the refuse sound.
- **No Light button and no prompt.** Walking past a dead brazier relights it.
- **Events.** Nothing new in `SimEvent` (its switch in `Feedback.cue` is exhaustive and other lanes edit it): diff the
  `at` stamps, or add `.lordThrown(fromX:toX:)` and `.lordSteadied` at the join with their `Feedback` rows.
- **The dawn report:** `FrontText.lines(report)` gives up to three short lines (where he stood, braziers relit, throws);
  put them in the night half after the fallen. The card has no field for them yet (`ReportCard` is the rebuild's).
- **Strings:** `Resources/Front.xcstrings`, English and German; the six other languages follow in the i18n pass (4 keys,
  2 of them plural).

### Tuning and T13

(filled in below from the rounds)

### Rounds

(filled in below)

### Open, and waiting for the join

(filled in below)
