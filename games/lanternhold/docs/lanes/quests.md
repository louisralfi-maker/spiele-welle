# Lanternhold: the quests lane (the Lantern Table)

Branch `claude/lh-q`, cut from the integration branch (build 86 plus sound, `d3ed497`). The spec is
`docs/QUESTS.md`; Louis decided the full table of thirteen at launch, a lost lantern leaves its hook empty for the
chapter, the map opens only at the table. This file records what each step built, the hooks into existing files (so
the join can apply them again), the runner rounds and what waits.

## quests-1: the engine (QUESTS.md 7.2, round `lh-q-1`)

### What exists

All new files, in folders of the lane's own:

- `Core/Table/ErrandData.swift`: the data format and its loader. `Errand` (a sending: number, place, days,
  conditions `requires` / `requiresAny` / `forbids` / `heard` / `world` / `unlocked`, a fixed `lantern`, `offered`,
  orders, `atReturn`, `lostReport`), `ErrandOrder` (label, `seal`, `nights`, `nightsWith`, `cost` (gold and flags),
  `lend` (archers, guards, builders, citizens), `goes` (named people), `risk`, `late`, order `requires` / `forbids`,
  `report`, `altReport`, `atReturn`, `atLoss`), `RiskTier` (no chip, "Dark road", "Few come back"), `TableReport`
  and `ReportChoice` (a petition-style choice plus `instead` for the days its night cannot apply), `TablePlace`,
  `ErrandCatalog` (loads `errands-*.json` from the bundle or `Resources/Errands`, sorted by id, `.standard`),
  `TableWorld` (the table's own world ids `table.west.1`, `table.west.2`, `table.span`, `castle.chapel.bell.first`).
- `Core/Table/TableState.swift`: `TableState` (the rail of `RoadLantern`s 38, 39, 40 and the reserved 41; the
  parties out as `Sending`; `sent`; waiting reports; reports read; the last dawn's rows `TableDawn` /
  `LanternReturn`). Every type decodes its fields with defaults, so a later field keeps saves readable.
- `Core/Table/ErrandEngine.swift`: the rules. Offers (the cloth comes off on day 2; days, conditions, sent once),
  `blockers` (every missing chip: no lantern, gold, archers, guards, taxpayers for bearers, the last builder, a named
  person away, an order's flag; alone: not offered, closed hours outside 06:00 to 18:00, a waiting report),
  `sealHolds` (QUESTS.md 4.3: risk 0, at most two soldiers, never away on nights 7, 10, 17 to 20, sealed parties
  never more than two soldiers out on a night), `send` (lowest free road lantern, cost, lend the newest recruits,
  roll once from `errandSeed(seed, errand, order)` and keep the result), `callBack` (exact undo while the clock has
  not moved since the sending), `dawn` (returns), `read` (a waiting report by day), `effect` (a report's night only
  on days 4 to 14, else `instead`), `counsel` (withheld after day 14 when it gives people or gold). The engine never
  draws from `GameState.rng`: soldiers a report or a return brings are named from the table's own stream
  (`nameSeed`), checked by a test.
- `Core/Table/ErrandValidator.swift`: schema (unknown keys), references, the seal's rules (incl. "the seal can never
  hold" for a window whose every day crosses a blocked night), the chips' risk bands, report rules (no chance,
  schedule or unlock; a night only with `instead`; one free choice; the lost lantern's two free choices), every text
  key in English and German within QUESTS.md 5.5's limits (placeholders at their longest, `{lord}` and `{a|b}`).
- `Core/Table/QuestText.swift`: the texts of `Resources/Quests.xcstrings` (`string`, `text` with `{lantern}`,
  `{n}`, `{total}`, `{who}`, `{place}` and the lord's forms, `count` for "1 night" / "3 nights").
- `Resources/Errands/errands-ch1.json`: the rail, the eleven carved places, sendings 1 (`oil_round`), 5
  (`highcairn_count`, two orders) and 11 (`beacon_statues`, the stair sealed, the lamp room "Few come back" 0.25),
  their five reports and `lantern_lost` (Brannock, two free choices).
- `Resources/Quests.xcstrings`: 101 strings in English and German: the screen's words, the eleven place names, the
  three sendings' slips and orders, the six reports with their choices and reactions.
- `App/GameModel+Table.swift`: `openTable` (stops the clock, uncovers), `closeTable`, `sendErrand`,
  `callBackErrand`, `readTableReport`, `playTableToDawn` (debug: the reference bot to the next dawn).
- `UI/Table/TableListView.swift`: the plain list behind `-GWScreen table` (`TableDebugLayer` over `GameView`):
  left the hook rail and the parties on the road with "Call back", right the waiting report (reports first) or
  today's slips with their order tiles and chips (nights, gold, people, who goes, the seal, the risk; a missing one
  red), "Play to the next dawn" (debug), "Back". Tiles 52 pt, every button 44 pt or more.

Content decisions inside the spec, for the story lane and the critic to see:

- Report choices with a night (`oil_round` c2 "Keep it for the wall", `beacon_statues*` c1 "Tell the wall") carry an
  `instead` because reports wait and can be read on any day: outside days 4 to 14 the oil makes the next brazier free
  (`brazier_gift`, the existing flag) and the warning gives +1 happiness (as QUESTS.md wrote for after day 14).
- `highcairn_rounded`'s counsel is choice 2 ("Send the true count after it"); QUESTS.md names none.
- The lamp-room report's second choice is "Tell the hall about the light" (+1 happiness, `statues_told`), with a
  reaction that shows Mother Hesper's hearth leaning west (STORY.md). The light on the moor is the story lane's to
  confirm (QUESTS.md 7.5).
- The lost-lantern report says "Lantern {lantern} did not come home" in digits, not "Forty".
- A sending's slip has two hook keys (`errand.<id>.hook1`, `.hook2`) instead of one key with a line break, so each
  line has its own limit (60 / 80).
- Reports are not petitions in `Resources/Petitions` with a new `kind` (QUESTS.md 4.1 proposed that): they live in
  the table file and reuse `PetitionEffect`, so `PetitionData.swift`, the audience queue and `Story.xcstrings` stay
  untouched. Round 2's card can show a `TableReport` with the audience card's parts.

### Hooks into existing files (apply again at the join)

| File | Place | Why |
| --- | --- | --- |
| `Core/GameState.swift` | `var table: TableState?` after `var lord` | the table in the realm and the save; optional, so old saves and bots read nil |
| `Core/Sim.swift` | `ErrandEngine.dawn(&s, balance: balance)` right after `Battle.endNight` in `dawn` | parties come home before the economy, the dawn report and the save |
| `App/DebugArgs.swift` | `table` in `enum Screen` (and its doc line) | `-GWScreen table` |
| `App/LanternholdApp.swift` | `.overlay { TableDebugLayer(model: model) }` on `GameView(model:)` in `RootView` | the plain list; shows nothing without `-GWScreen table`; round 2 replaces it with `Overlay.table` |
| `Core/CourtLines.swift` | first line of `CourtLineBook.lines(for:state:)`: `if state.table?.isAway(speaker) == true { return [] }` | whoever carries a lantern says nothing at court (Pip on sending 1; QUESTS.md 2.2) |

No other existing file changed. `PetitionData.swift`, `PetitionEngine.swift`, `CourtWorld.swift`, `Remembered.swift`,
`DESIGN.md`, `Localizable.xcstrings` and `Story.xcstrings` are untouched.

### Tests

- `Tests/Table/TableNeutralityTests.swift`: with the table's files loaded, the table uncovered on day 2 and every slip
  read (offers, blockers, seal) at every step of every day, nobody sent: seed 1's twenty nights read line for line
  the tuning report of rounds `lh-snd-1` / `lh-snd-2` (frozen in the test), every dawn's realm equals the run
  without the table (seeds 1 to 4), and `TuningRun` itself still walks that line.
- `Tests/Table/ErrandEngineTests.swift`: the cloth and the offers by day and flag; lowest lantern, people (the
  newest recruits), gold; at most three lanterns, 41 reserved; every missing chip; the seal's days (5, 8, 11 for
  sending 5) and the two-soldier rule; the roll (about a quarter of 800 seeds, never on a chipless order, the
  realm's stream untouched, call back cannot reroll, a reload keeps it); call back is an exact undo; Pip home at
  dawn 3 through `Sim`, his report waits past the horn and is no petitioner; soldiers back at their dawn; reports
  read first; reading Pip's report lights the lanes; nights only on days 4 to 14; the counsel's limits; the true
  count's two archers named from the table's stream; the rounded count and the truth sent after it; the lamp room's
  two scratches; a lost lantern (hook empty for the chapter, window dark, −2, the scout gone, nothing seen, both
  choices free, one sending fewer); late returns, `nightsWith`, `altReport`, bearers and builders.
- `Tests/Table/TableSaveTests.swift`: no `table` key for a realm that never touched it; the frozen version 1 save
  has none; parties out, a roll and a waiting report come back byte for byte and the next dawn plays the same; an
  older table without newer fields loads.
- `Tests/Table/ErrandDataTests.swift`: the bundle's file loads clean and equals the source folder; the validator
  finds nothing; every key compiled in English and German; placeholders; sendings 1, 5, 11 as QUESTS.md writes
  them; the validator catches 30 usual mistakes; a broken entry costs only itself.
- `UITests/TableUITests.swift` (`testTheTableSendsPipAndReadsHisReport`, English and German): `-GWDay 2 -GWClock 9
  -GWScreen table`; Pip sent (lantern 38 out), called back, sent again; "Play to the next dawn"; his report on day 3
  names lantern 38; its first choice lights the lanes and lantern 38 hangs again; "Back" closes. Shots
  `40-table-list`, `41-table-sent`, `42-table-report`, `43-table-reaction`.

### Rounds

- `lh-q1-1` (build, unit over the table's tests plus `SaveGameTests` and `DebugArgsTests`, ui and ui-de
  `TableUITests`): running.

### Open, and what waits for the join or round 2

- Pip says no court line while he is out (hook in `CourtLineBook.lines(for:state:)`); his figure still stands in the
  hall: the court's figures belong to the stage lane's rewritten hall, so hiding him (`TableState.isAway`) waits for
  the join.
- The dawn report's row ("Lanterns home: 38 (Tallowford)") is data: `ErrandEngine.dawnRows(s, day:)` reads
  `TableState.dawn` (the day it belongs to, each
  lantern's outcome, names, the −2 for a loss); the report screen's row is round 2. The −2 of a lost lantern is
  applied before the economy, so the dawn report's happiness change list does not name it; the row will.
- `Overlay.table`, the chapel's table and rail, `KingTarget.table`, the strip's pip, the party leaving and coming
  home, Reduce Motion, placeholder art: round 2.
- Sendings 2 to 4, 6 to 10, 12, 13, the sender and greedy bots, T10 and T11: round 3. Six more languages: round 4.
- Soldiers recruited at the barracks while riders are out may get a rider's name (the barracks do not know the
  road); cosmetic, for round 3.
