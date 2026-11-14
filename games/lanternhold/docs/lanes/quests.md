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
- The house's new origin (director's note 15:03, docs/HOUSE.md): no text of the lane calls the lord a lamplighter or
  talks down to the lord. Lord Varn's word in `report.highcairn_true.text` is "House Lantern still counts true" (it was
  "The lamplighter can count"), and the slip's first line no longer says "once we can count". Pip keeps "Your
  Wickship" (`report.oil_round.text`), which HOUSE.md allows. No text names the lord.
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

- `lh-q1-1` on `3ef9f22` (build, unit over the table's tests plus `SaveGameTests` and `DebugArgsTests`, ui and ui-de
  `TableUITests`): build passed with no warning from the lane's files; 47 of 48 unit tests passed (the neutrality
  test asked for the table at the dawn of day 2, which comes before the first look that day); the UI test failed
  only its first check (the list read the realm before `openTable` uncovered it and showed "hook:0"), the rest of
  the flow ran in English and German. The shots showed three more things to fix: the sent slip vanished ("nothing
  waits today" right after sending, where QUESTS.md 5.2 keeps it with "Call back"), the report card's second choice
  sat below the fold, and IM Fell's old-style 1 read as an I in "1 night". Fixed in `63f4a27`, together with the
  answer's chips under its reaction and "Next brazier free" instead of "Will be remembered" for the oil kept.
- `lh-q1-2` on `63f4a27` (build, unit, ui, ui-de, release): **ALL PASSED**. 447 unit tests (411 before the lane, 36
  new), no build warning from the lane's files; the tuning report is byte for byte the one of `lh-snd-2` (T1 to T8
  and the Court line unchanged); the table validator reports nothing over 101 keys; ui and ui-de passed every test,
  `TableUITests` in 38 s and 31 s; release passed. The shots `40-table-list` to `43-table-reaction` in English and
  German show the slip, the sent slip with "Call back", Pip's report with both choices and their chips above the
  fold, and the answer's reaction with "+1 happiness" and "Seen in the realm"; the German texts fit.
- `lh-q1-3` on `efbb403` (build, unit, ui, ui-de, release), after the house's new origin changed two texts:
  **ALL PASSED**. 447 unit tests, the tuning report identical to `lh-q1-2` (and so to `lh-snd-2`), the validator
  reports nothing, `TableUITests` passed in English (42 s) and German (37 s), every other UI test passed, release
  passed. Upright shots: `ci-out/upright/q1-3-*.jpg` in the lane's worktree (git-ignored).

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

## quests-1, fix round 1 (the critic's look 1: pass 8 of 10, no blocker, three highs)

### What changed

- **Lord Varn, never "Lord Harrow".** The game's own texts (`petition.varn_levy.text` / `.hint`) call Hild's father
  "Lord Varn" or "my father"; Harrow is a first name the player never meets. Fixed in
  `errand.highcairn_count.hook1`, `report.highcairn_true.text` and `report.highcairn_rounded.text` (en and de). The
  slip's first line now echoes the levy petition: "Lord Varn sends the other half once he has our Count." / "Lord
  Varn schickt die andere Hälfte, sobald er unsere Zählung hat."
- **The Count's reports agree with their choices** (data unchanged). The rounded report: "Then he said he would send
  one archer, not two." (DE "Dann sagte er, er werde einen Bogenschützen schicken, nicht zwei."), so the archer is
  not yet in the castle when choice 1 brings her and choice 2 sends the truth instead. The true report's r1: the two
  archers "ride in at the next dusk" (DE "in der nächsten Dämmerung"), no longer "at noon" from a gate two nights
  north.
- **A report the catalogue has no card for never holds the table.** `ErrandEngine.nextReport(table, catalog:)` is
  the oldest waiting report with a card; `blockers` answers `.reportWaits` only for such a report, `read` reads it
  by default (`at: nil`), the list shows it. `ErrandEngine.tidy(&s, catalog:)` drops waiting reports without a card
  (a saved table from a version whose report ids were renamed, or a sending whose report id is gone when it comes
  home): nothing is applied or recorded as read, a lantern that was `.back` hangs on its hook again, a lost one stays
  lost. `uncover` (the table screen's opening) calls it, so a saved table is tidied the moment the table opens; until
  then nothing reads such a report. A tidy table is left exactly as it was (no write), so the neutrality line is
  untouched. Not in `dawn`: `Sim.dawn`'s hook has no catalogue and stays as it was.
- **Smaller things from the same verdict:** EN `table.chip.night` "Fewer tonight"; DE `table.homeday` "Zurück am
  Morgen von Tag {n}"; DE `report.oil_round.r1` "In der Dämmerung leuchtet Tallowford bis zur letzten Tür."; DE
  `.r2` "Die Fässer kommen hinauf auf den Wehrgang."; DE `.r2b` "brennt mit dem Öl der Lichtzieher"; DE
  `report.highcairn_true.text` "zählt noch immer ehrlich"; DE `errand.beacon_statues.hook1` "... die steinernen
  Herren an der Straße" (as the English "on the road"). The debug list's reaction title drops a closing full stop.
- Left for the director: DE "Laterne 38 ist heim" (QUESTS.md's own glossary fixes it; the critic proposes "ist
  zurück" for the chip and the row, "ist heimgekehrt" for the report openings). The sent slip's repeat, hooks `.out`
  and `.back` looking alike, a hint on 41: round 2's real screen.

### Hooks

No new hook. `TableListView.swift` and `ErrandEngine.swift` are the lane's own files.

### Tests

- `TableSaveTests.testAReportTheCatalogueNoLongerKnowsDoesNotHoldTheTable`: a saved table with two unknown report ids
  (one on a `.back` lantern, one on a lost lantern) loads; nothing is read first, `read` answers nothing, a sending
  takes 39; the table's opening drops both, 38 hangs again, 40 stays lost, the rest of the realm is unchanged, a second
  tidy changes nothing; an unknown report before a known one: the known one holds the table and is read.
- `ErrandEngineTests.testAReportWithoutACardNeverHoldsTheTable`: a party whose report id has no card comes home,
  never holds the table, and its lantern hangs again when the table opens.


### Rounds

- `lh-q1f1-1` on `2723f37` (build, unit, ui, ui-de, release; sent at 17:32, before the director's note of 14.11.
  18:46 limited lanes to short rounds; it could not be cancelled, so it stands as the gate, a superset of rounds a, b
  and c): **ALL PASSED**. 449 unit tests (447 plus the two new ones), the tuning report and the neutrality line byte
  for byte those of `lh-q1-3`, the table validator reports nothing over 101 keys, no build warning from the lane's
  files, `TableUITests` passed in English (29 s) and German (35 s), every other UI test passed, release passed.
  Upright shots: `ci-out/upright/qf1-1-*.jpg` (the reaction's title without its full stop, "Zurück am Morgen von
  Tag 3", the new German oil reaction; all fit).
- From now on: short rounds only, by the director's note of 14.11. 18:46.

## quests-2: all thirteen sendings, and the numbers (QUESTS.md 3, 4.3, 4.4; rounds `lh-q2-*`)

### What exists

- **All thirteen sendings** in `Resources/Errands/errands-ch1.json`, English and German in `Resources/Quests.xcstrings`
  (204 keys, 103 new): slips (title, two hook lines), order labels, twenty report cards with their choices and
  reactions. New: 2 `mill_herbs`, 3 `ford_planks`, 4 `hemmet_sentence` (with `hemmet_gone` when the cough came and no
  herbs grew, home day 17 or later), 6 `goldenacre_cart` (`goldenacre_paid` / `goldenacre_list`), 7 `saltgate_grey`,
  8 `stillmere_proof` (`stillmere_written` / `stillmere_struck`), 9 `greybell_bell`, 10 `beaconfoot_smoke`
  (`beaconfoot_road` / `beaconfoot_caves`), 12 `ludo_number` (with its own lost report `ludo_lost`), 13 `lantern_41`.
  Each card carries one thing seen: Hemmet's empty washing line (and, if the cough took him, one shirt on it), Lady
  Oriel's mason's mark under the moss on the stumps, Hemmet saying his sentence again "as if I had got it wrong", Pell
  offering three houses "a share of our tithe once the door changes hands", the grey lanterns on the tideline with every
  hinge on the wrong side, the syndics' question "who carved the twenty?", the bell ringing once on the road with nobody
  near the rope, a pot still on the cold fire at Beaconfoot, the grandmother counting days in soot, Ludo's number 17 not
  struck through, his helmet on the west door's step facing home ("too big for the hook as well").
- **Sending 13** is not offered: `ErrandEngine.follow` puts Hild's party on lantern 41 at the first dawn of its days
  (19) once `hild_rode` is set (or when the table first opens after that), sent on day 18 at dusk as `varn_ride` says,
  nothing paid or lent, home day `ErrandEngine.neverHome`: it stays out on the Moor Road, a new place of kind `beyond`
  (the bare wood). `Errand.staysOut`, `TablePlaceKind.beyond`; Hild says no court line while she is out (the existing
  hook). The list shows "Gone past the beacon" (`table.beyond`) under her lantern.
- **The validator** covers all thirteen: followed sendings (never offered, a reserved lantern, one order that costs,
  lends, risks and brings nothing, no report), the bare wood (no nights, only a party that stays out), "the counsel can
  never apply" (a sealed order whose counsel gives people or gold but whose report is read after day 14), every lost
  report's choices free (also `ludo_lost`), and every title and hook of a sending shown but not offered.
- **The bots** (`Core/Table/TableBot.swift`): `TableBot.sender` reads each report with Odile's counsel (else a choice
  that neither costs nor gives people or gold) and sends every offered order whose seal holds today and that it can
  pay, lowest number first; `TableBot.greedy` reads for the most people, then gold, and sends whatever it can pay, red
  chips too, the second order first. Both ride on the reference bot, once a day after the audience, and keep the full
  days (T11), the sendings starved for a hook (T11) and a log.
- **The tuning** (`Core/Table/TableTuning.swift`, `Tests/Table/TableTuningTests.swift`): the reference (no table),
  sender and greedy bots over the twenty tuning seeds, run side by side on every core (`DispatchQueue.concurrentPerform`,
  each run a pure value); the cells of QUESTS.md 4.4: T1, T3, T4, T5, T6, T7 (sender endless to night 66), T8 (sim
  proxy) for the sender, T6 (without the beacon) for the greedy bot, T10 and the sender's T11; the rest reported.
  Attachment `table-tuning` (with night 20's diagnostics per seed). `Core/Table/TableTuningVariants.swift` keeps the
  tool that measured the round-2 variants (`TableVariant.make`, `TableTuning.variants`); no test calls it now.
- **T11 for the greedy bot is reported, not asserted (a finding for the director).** "At least 2 offered sendings
  stay unsent for want of a hook" held in no seed and no variant: rounds `lh-q2-1` and `lh-q2-2` measured the first
  windows, the tightened windows, two-day windows for 3, 4, 7, 11 and 12, four nights for Saltgate and Stillmere, a red
  chip on the caves: the median stayed 0 (at most 1 in a seed). A bot that sends everything at first chance gets
  nearly every slip out, because most sendings are one or two nights and every window is three days or more; a slip
  that waits for a hook gets the next one. What greed costs here is lanterns (14 of 20 greedy realms lose one on a red
  chip) and soldiers, not slips. Making the strict cell hold would take windows of one or two days, which a player who
  visits the table every second day would mostly miss; I did not ship that. The report also counts the slips that had
  to wait for a hook. Options for the director: accept the cell as reported; or read it as "at least 2 slips had to
  wait"; or ask for one-day windows on two late sendings.
- **The tuned values** (by values only; `Balance` and every petition untouched):
  - Odile's seal also on 3 `ford_planks`, 6 `goldenacre_cart` order 2 (the lamp tithe list) and 8 `stillmere_proof`
    order 1 (as she wrote it). With QUESTS.md's five seals alone the sender never had more than two lanterns out (a
    model of its calendar over every story-day draw: 0 full days; T11 asks for 3).
  - 11's stair takes two nights (two dusks of counting; the lamp room stays one, faster and deadly), 3's planks three
    nights (two to lay, one home). The sender's calendar is then the same in every seed: day 2 oil, day 5 the true
    count (nights 5 and 6), day 8 the mill and Beaconfoot's road, day 11 the planks, Marek and the stair (all three
    lanterns out on days 11, 12 and 13), day 13 Stillmere; Greybell (no seal) never.
  - Sending 1's counsel is now "Keep it for the wall" (on day 3 the next brazier is free), not the lanes (+1
    happiness): with the lanes the sender's high-tax realm would sit one point above the reference (T4 "not above").
    The lanes stay the warm choice for the player.
  - Ford planks: Odile counsels the toll (+15 gold, −1 happiness) while it pays (read by day 14), else the free choice.
  - Round 4: the planks go with a builder and a carter (one bearer), not a guard: the sealed path's soldiers away on
    nights 11 to 15 drop from eight soldier-nights to five (the stair's scout two, Stillmere's rider three).
  - Round 2 (after `lh-q2-1`): the middle of the chapter crowds. Windows 2 `mill_herbs` 6–10, 3 `ford_planks` 9–12,
    6 `goldenacre_cart` 8–12, 7 `saltgate_grey` 10–12, 10 `beaconfoot_smoke` 8–10, 11 `beacon_statues` 11–14,
    12 `ludo_number` 12–14 (QUESTS.md had 6–12, 9–14, 7–13, 10–15, 8–11, 11–16, 12–15); the caves take two nights. With
    the first windows a bot that sends everything got almost every slip out (T11 greedy: 0 unsent), so the hook did not
    bite. Odile's counsel on the true count is Hild's word, not Varn's two archers (QUESTS.md 4.4 named those archers
    the first value to watch; the variants showed they were not what weakened night 20, but the counsel path now gives
    no people at all, as STORY.md 9.4 asks). Beaconfoot's road report: Odile counsels "Say nothing yet" (no happiness;
    the lamp hung low at the Throat gate stays the player's warm choice), so the counsel path's happiness is +1 net
    (Hild's word +1, Stillmere's answer +1, the toll −1).
- **A sending creates nobody** (engine, round 3): `ErrandEngine.takeBedsBack`. Round `lh-q2-2`'s diagnostics showed
  the sender's realm a step ahead of the reference (one building more at dawn 20, the beacon a day earlier, four
  realms still standing at night 66 in endless, few patches left for night 20): every lending at a full town let the
  town grow into the empty beds (Economy's growth fills house room at the dawns the party is away), and the party
  came home on top. Now the people who moved into a party's beds make room again as far as the town is over its
  houses' room when the party comes home (`Sending.bedsBefore`, saved, −1 for older saves); in a town with room the
  growth stays.
- **Neutrality** (director's note 19:35, join rehearsal): the pinned line is one constant, `TableNeutralityLine.pinned`
  (`Tests/Table/TableNeutralityLine.swift`, how to re-pin in its comment); only `testTodaysLineIsUnchanged` reads it.
  The seed-1 check now compares the run with the table against the run without it, line for line and dawn for dawn.
- German report openings say "Laterne {lantern} ist zurück" (also the chip `table.home`), not "ist heim" and not "ist
  heimgekehrt" (that collides with "die Heimgekehrten", the Returned).

### Decided for the story lane (QUESTS.md 7.5)

1. **Lord Edric had the table's west planed away** in the Dark Year, the winter he cut the eleven leaves: confirmed.
   It fits Edric the Shut and asks nothing new of STORY.md.
2. **The keepers chalked every lantern that went west** on the beacon's west door, and struck a number through when
   its lantern came back east. A number not struck through never came home. Ludo's knight's number is 17 (the report
   says the number, never whose it is: his secret stays Pip's, HOUSE.md 8.4).
3. **Road lanterns 38 to 41:** the house numbers every lantern it owns in one Count. 1 to 37 hang at the gatehouse, one
   per post of the wall; 38 to 41 are the road lanterns left on the chapel's rail after Aldric's ride. No text needs
   more than the digits.
4. **What the first bell does on night 20** (if `bell_rings`): it rings once by itself at the moment the Lightless King
   leaves the Gloom, as it rang in the Dark Year when Edric sent it away: the hall hears that he has come before the
   wall sees him. With `bell_tied` it shivers against the rope and makes no sound. A sound and a line for the finale,
   no number: nothing changes in the battle. Not built here (the finale is not this lane's); recorded for the story
   and finale lanes.
5. **What is seen from the lamp room:** past the sixty statues, the moor's edge, and far out one low, steady light that
   never flickers and burned all night, in the direction the statues face from. Nobody names it. Mother Hesper's hearth
   leans west when she hears of it. Chapter 2 walks toward it (it is where the old seat lies, STORY.md option A); chapter
   1 never says so.

No new key touches the lord's origin: no text calls the lord a lamplighter or talks down; Pip's "Your Wickship", Marek's
"Your Radiance" and Ludo's "good my lord" are the forms the house rules keep.

### Hooks into existing files (apply again at the join)

| File | Place | Why |
| --- | --- | --- |
| `Core/Autoplay.swift` | `planDay`: the refill counts `s.archerCount + s.archersOnTheRoad` and `s.guardCount + s.guardsOnTheRoad` (target and comparison); `.recruitArchers` subtracts `s.archersOnTheRoad` from the free posts; `.recruitGuards` adds `s.guardsOnTheRoad` | the reference bot (and with it both table bots and `-GWAutoplay`) does not recruit in place of soldiers out with a road lantern; 0 without the table, so the reference realm is unchanged |

The other hooks of quests-1 stand as they were (`GameState.table`, `Sim.dawn`'s `ErrandEngine.dawn` call, which now
also follows sending 13 with the standard catalogue by default, `DebugArgs.Screen.table`, `RootView`'s debug layer,
`CourtLineBook.lines(for:state:)`). `PetitionData.swift`, `PetitionEngine.swift`, `CourtWorld.swift`, `Remembered.swift`,
`DESIGN.md`, `Localizable.xcstrings` and `Story.xcstrings` are untouched.

### Tests

- `Tests/Table/TableSendingsTests.swift`: the thirteen (numbers, places, seals, chips, costs, nights); every report
  brought home by something; sending by sending (the mill's herbs keep the cough away; the planks bridge the ford and
  shorten Greybell and Goldenacre; Hemmet's sentence or the sails tied; Marek pays the loan or carries the list, call
  back keeps the debt; Stillmere's honest and struck reports; the first bell and its bearers; Ludo with a scout or alone
  on red, his own lost report); lantern 41 follows Hild's ride and stays out; the risks of 2.7, one test each (lent
  soldiers never stand on the wall through two real nights and come home whole; three lanterns out block every other
  slip; only a chip loses a lantern, and its soldiers with it; Saltgate late, never lost; no sending locks a story
  petition, schedules, unlocks or rolls, and no named person is lost except on red); the validator's new rules; the
  two bots' policies.
- `Tests/Table/TableTuningTests.swift`: the 4.4 cells above, the bots used the table (the sender sent at least six,
  read its reports, lost nothing; the greedy bot sent more and lost lanterns on red), attachment `table-tuning`.
- `ErrandEngineTests`, `ErrandDataTests`, `TableNeutralityTests` updated for the new values (offers by day, the stair's
  seal days 11 to 15, the oil's counsel, the stair home after two dusks, twelve places).

### Rounds

- `lh-q2-1` on `7dfa0a5` (build, unit over the table's six test classes): build passed (no warning from the lane's
  files), 64 tests ran, 2 failed. The tuning took 81 s with the seeds side by side. T1, T3, T4, T5, T7, T8, T10 and the
  sender's T11 passed (T10: gold −8.5, soldiers 0, happiness −0.5 as medians; T11 sender: 3 full days in 19 of 20
  seeds, days 11, 12 and 13; T7: 18 of 20 in band). Failed: T6 sender (without the beacon held 3 of 20, the reference
  10) and T11 greedy (median 0 unsent for want of a hook). The validator reports nothing over 211 keys.
- `lh-q2-2` on `4c44f45` (build, unit all, ui `TableUITests`; the gate's shape): build passed, `TableUITests` passed
  (both tests, the day-11 one included), unit 474 passed, 4 failed: one stale assertion (`ErrandDataTests`, the stair's
  window), T6 sender (without the beacon held 4), T7 sender (13 of 20 in band: four realms still standing at night 66)
  and T11 greedy. The variants (`table-variants`, seven sets of values) moved T6 only within noise (3 to 8) and T11
  greedy not at all; the night-20 diagnostics showed the sender's realm a building ahead with few patches left, which
  led to the beds rule above. TuningTests' T1 to T8 passed unchanged.
- `lh-q2-3` on `d25391c` (build, unit all, ui `TableUITests`): build and `TableUITests` passed; unit 476 passed, 2
  failed: T6 sender (without the beacon held 3) and T7 sender (15 of 20 in band). With the beds rule the sender's
  beacon days equal the reference's ([17, 16, 17]) and T10 is closer (gold −16, soldiers 0, happiness +1). The greedy
  cell, now reported: median 0 unsent, 0 to 2 slips that waited for a hook.
- `lh-q2-4` on `fb7eb8e` (build, unit all, ui `TableUITests`; the gate by the director's notes of 14.11. 18:46 and
  19:35): **ALL PASSED**. 479 unit tests, no build warning from the lane's files, the table validator reports nothing
  over 211 keys, `TuningTests`' T1 to T8 unchanged, `TableUITests` passed both tests (Pip on days 2 and 3; day 11 with
  three lanterns out). The table's tuning (`table-tuning`): T1, T3 ([17, 16, 17] as the reference), T4 (27 = 27), T5
  (11), T6 (sender: won 20, King slain 19, without the beacon held 6; greedy without held 5, at or below the
  reference's 10), T7 (17 of 20 in band), T8, T10 (gold −6.5, soldiers 0, happiness −1.5) and the sender's T11 (3 full
  days in all 20 seeds) pass; the greedy T11 cell is reported (median 0).
  Upright shots: `ci-out/upright/q2-4-*.jpg` in the lane's worktree (git-ignored).

### Night 20 without the beacon is chaos-fragile (for the director and the critic)

The probes of round 4 (`table-variants`, the sender only): with only Pip's oil under the seal (5 gold, nobody off the
wall) the sender's realm held night 20 without the beacon in 5 of 20 seeds; with the oil and the true count 8; the
shipped values without the stair 8, without Stillmere 6; shipped 6. The reference holds 10. Night 20 without the
beacon ends within a few seconds of first light in most seeds (the tuning report's margins F0 to F14), so any change to
a realm, even five gold on day 2, redraws the seeds. The shipped values pass at 6, the band's floor; a later change
anywhere in the game can move the sender's cell out of the band by chance. Advice: judge this cell for table bots over
the probes (their mean, about 6.6 of 20, sits inside 30 to 60 %), or over more seeds, rather than over one draw. The
same holds for T7 (13, 15, 17 and 18 of 20 in band over the rounds with almost the same values).

### Open, and what waits for the join or later steps

- **T11 greedy** (reported, not asserted): the finding above, for the director to decide.
- `TableTuningVariantsTests` (about a minute per unit round) holds the probes for the critic's look; remove it once
  the values are final (the tool `TableVariant` / `TableTuning.variants` stays).
- `Remembered` and `CourtWorld` lists (QUESTS.md 4.5: the five `<house>_road` flags, `statues_sixty`, `bell_rings`,
  `ludo_knighted`, `hemmet_gone`; `castle.chapel.bell.first`, `table.west.*`, `table.span`), Pip's court line on day 2,
  the chapel's table and rail, Hild's token on the bare wood: the real table screen's step and the join.
- `tools/simtune` does not compile since quests-1 (its source list lacks `Core/Table` and what it needs): for the join.
- The first bell on night 20 is decided (above), not built: the finale's lane.
- Hemmet's sails tied (`hemmet_gone`) shows only when Finch is sent on day 16 after the refugees came and no herbs grew
  (home on day 17, the cough's day): narrow by the story's own clock.
- German: every key has German within its budget (unit-tested); not reviewed, by the director's note of 19:35. The six
  other languages after the join.


## quests-2, fix round 1 (the critic's look 1: no pass, 7 of 10; one blocker, two highs)

### What changed

- **Blocker, Ser Ludo is mourned and then comes back: fixed.** Sending 12's second order (alone, red chip) now has
  `"atLoss": {"flags": ["-ludo_stays", "ludo_gone"]}`, so `ludo_tourney` (it needs `ludo_stays`) and the court line
  `ludo_walls` can never come again. The engine also keeps him out by name: a lost lantern records the people who went
  in `TableState.gone` (saved, sorted, `[]` for older saves), and `TableState.isAbsent(who)` / `ErrandEngine.isAbsent`
  is true for whoever is away with a lantern or gone. That also stops what no flag guards: his court lines
  `ludo_goose` and `ludo_helmet`, and `ludo_old` in endless (it only forbids `ludo_old_met`).
- **High 1, people on the road petition in the hall: fixed.** The day's queue passes over a random or endless
  petition whose speaker is absent (`PetitionEngine.isDrawable`) and a follow-up whose speaker is absent (the
  follow-up loop of `PetitionEngine.draw`); court lines use the same check (the old `isAway` hook, now `isAbsent`). So
  `marek_stall`, `marek_relic` and `marek_spyglass` pass over the nights Marek's cart is out to Goldenacre,
  and `envoy_tide` / `envoy_coast` the nights Ansel Quay rides to Saltgate. Story petitions are never passed over
  (nothing locks a story petition); the validator keeps them off the road's days instead (below). Pip's oil round is
  one night: he is home by the next queue, so `pip_minister` can only meet him on the day he is sent, and that day is
  covered by the new blocker.
- **A petitioner is heard before he is sent off.** New `SendBlock.waits(who)`: an order whose named person speaks a
  petition in today's queue cannot leave ("Marek waits in the hall", `table.waits`, English and German, a red chip in
  place of "{who} goes"; limit 34 English, 44 German). `ErrandEngine.blockers` and `blocker` take
  `petitions: PetitionCatalog = .standard` for it.
- **The validator** (`ErrandValidator.presenceProblems`, run inside `problems`):
  - an order that can be lost (`lostChance > 0`) and names a person: that person must be a guest with a presence flag
    (`ErrandValidator.presence`: `serLudo` → `ludo_stays`, `envoy` → `envoy_met`, `hildVarn` → `varn_with`), the
    order's `atLoss` must clear it, and the person speaks no story petition. Pip, Marek and Finch can never go where a
    lantern can be lost;
  - nobody can be on the road (`awayDays`: the queues from the day after the window opens to its last day plus the
    longest road, one more when late; from the first day for a party that stays out) on a day one of his story
    petitions can come;
  - nobody who can be away over a dawn (two nights or more, or late) has a follow-up (the draw would skip it and it
    would be lost).
  The shipped table passes all three (asserted). Marek's cart is away on days 9 to 15, his story petition
  `marek_arrows` comes on days 6 and 7; Hild's lantern 41 from day 19, `varn_ride` on day 18.
- **High 2, T11 for the greedy bot: the critic's option (a), asserted.** "The bot that sends everything at first
  chance has all three road lanterns out on at least 2 of the days 9 to 15 (median), and loses a lantern on a red chip
  in at least half the seeds." It held in round `lh-q2-4` (full days 2 to 4 in seeds 1 to 5, a lantern lost in 14 of
  20). QUESTS.md's first cell (2 offered sendings unsent for want of a hook) and the slips that waited stay in the
  report. Why not option (b) (Stillmere four nights, Ludo's number closing on day 13): in the greedy logs of round
  `lh-q2-4` the bot sends the lamp room on day 11 or 12 (one night), Ludo on day 12 or 13 (one night) and Stillmere
  on day 13, and has one or two lanterns out on days 13 to 15 in every logged seed, so a fourth night for Stillmere
  and a shorter window for Ludo make no slip wait there; the sender never sends Ludo (no seal) and has its lanterns
  home by day 14. A real collision would take one- or two-day windows or several longer roads in the middle of the
  chapter, which a player who comes to the table every second day would mostly miss, and which moves T1, T6 and T10
  of the sender. QUESTS.md 4.4 is not edited; the director decides whether the spec's cell follows. This is the
  decision of this lane, for the director to overrule.
- **T10's tail** in the tuning report: for the two sender seeds furthest below the reference's happiness at dusk 20,
  what they sent and every night where the two realms differ (fallen, walls lost; happiness, archers, guards and
  buildings at that dawn).
- **Continuity** (the critic's smaller points): the stair's second hook reads "Nobody of ours has stood on that stair
  since the Dark Year." (Ebba Calder may have counted sixty already on days 12 and 13); its report's second reaction
  "The hall goes quiet when the scout says sixty. …" (true whether or not Ebba said it first); Hemmet's shirt "Through
  the winter the carters nod …" (the chapter is autumn). German written to match.
- `TableTuningVariantsTests` is removed (about 90 s per unit round); `TableVariant` and `TableTuning.variants` stay.
- `TableUITests.testTheMiddleOfTheChapterFillsTheHooks` sends the stair third if Marek stands in day 11's queue
  (his cart then shows "Marek waits in the hall" and stays), so the test does not depend on what the queue draws.

### Hooks (apply again at the join)

| File | Place | Why |
| --- | --- | --- |
| `Core/PetitionEngine.swift` | `isDrawable`: `if ErrandEngine.isAbsent(petition.speaker, s) { return false }` after the flags and happiness guard | nobody away with a lantern or lost on the road comes to the hall with a random or endless petition (QUESTS.md 2.2); false without a table |
| `Core/PetitionEngine.swift` | `draw`, the follow-up loop's guard: `!ErrandEngine.isAbsent(petition.speaker, s)` | the same for follow-ups |
| `Core/CourtLines.swift` | the quests-1 hook in `CourtLineBook.lines(for:state:)` now reads `if ErrandEngine.isAbsent(speaker, state) { return [] }` | court lines: away or lost |

Still for the join, not built here: the hall's figures. `CourtLayout.figures` walks Pip and (on his days) Marek
through the hall from their routines, whatever the table says; the stage lane rewrites the hall, so the join adds one
check there: skip a court figure when `ErrandEngine.isAbsent(id, state)`.

### Tests

- `TableSendingsTests.testLudoGoesWithAScoutOrAloneOnARedChip`: after the loss `gone == ["serLudo"]`, `ludo_stays`
  cleared, `ludo_gone` set, the tourney not drawable (and drawable for the Ludo who came home), and
  `assertAbsentFromTheHall` over days 14 to 40 in the chapter and in endless: every petition of his, with the flags bent
  to allow it, a clean history and scheduled as that day's follow-up, is neither drawable nor drawn, he has no court
  line; the same realm with him at court could draw something and hear a line.
- `testMarekOnTheRoadBringsNoPetitionAndAPetitionerIsNotSentOff` (court): Marek in day 11's queue blocks his cart
  (`.waits("marek")`, only today's queue), Pip in day 4's queue blocks the oil round; the cart out from day 11, Marek is
  absent from the hall on days 12 to 14 and his stall is drawable again on day 15.
- `testTheEnvoyOnTheRoadBringsNoPetition` (guest): Ansel Quay in the queue blocks Saltgate; on the road (home day 15)
  he is absent on days 13 and 14, and `envoy_tide` comes again on day 15.
- The validator test gains five cases (a court member on a red chip, a guest whose loss keeps his flag, a guest who
  can be lost and speaks a story petition, a road over a story petition's days, a two-night road for a speaker with a
  follow-up) and asserts the shipped table has no presence problem.
- `TableSaveTests`: a table written before `gone` existed loads with `gone == []`.
- `TableTuningTests.testT11TheHookMatters` asserts the greedy cell as restated.

### Rounds

- `lh-q2f1-1` on `57ce82b` (build, unit all, ui `TableUITests`; the gate by the director's notes of 14.11. 18:46 and
  19:35): **ALL PASSED** (build 7 min, unit 9 min, ui 2 min). Every table class green, the new tests included; the
  table validator reports nothing over 212 keys; `tuning-report.txt` and `table-neutral-seed1.txt` byte for byte the
  same as round `lh-q2-4` (the hooks are 0 without a table). The table's tuning: T1, T3 ([17, 16, 17]), T4 (27 = 27),
  T5 (11), T6 (sender won 20, King slain 19, without the beacon held 8, inside 30 to 60 %; greedy without held 2), T7
  (18 of 20 in band), T8, T10 (gold −3.5, soldiers −0.5, happiness −1.5), T11 sender (3 full days in all 20 seeds) and
  T11 greedy as restated (full days median 2.5, a lantern lost in 14 of 20) pass. Passing over the absent moved the
  sender's queue on Marek's days out (days 12 to 14) and redrew a few seeds: T6 without the beacon rose from 6 to 8,
  T7 from 17 to 18. Day 11's UI test took the cart path (Marek was not in that queue). Upright shots
  `ci-out/upright/q2f1-44-*.jpg` and `q2f1-45-*.jpg` (the stair's new hook on the slip).

### T10's tail, what broke in seeds 7 and 1 (for the director, before the values are frozen)

Both realms send the same eight (oil, the true count, the mill, Beaconfoot's road, the planks, Marek's list, the
stair, Stillmere). Up to night 12 they run within one archer of the reference. In seed 7 the sender's realm loses a
wall section on nights 13, 14 and 15 (the reference none), with Stillmere's rider (one archer) out on exactly those
nights; on night 15 four fall (the reference none), then 3, 4, 1, 4 and 5 on nights 16 to 20 (the reference 1, 1, 1,
0, 6). Happiness follows the dead: 86 at dawn 16 against 100, 44 at dawn 21 against 82; buildings stall at 13 until
night 17 (the reference 16, 18, 19) because the gold goes into new soldiers. Seed 1 is the same story one step
milder: four fall on night 15 (the reference one), happiness 65 at dawn 20 against 91. So the tail is the sealed
path's last soldier-nights, Stillmere's rider on nights 13 to 15 (its seal was added in quests-2 for the sender's
T11), meeting the chapter's first heavy nights. The medians pass; if the director wants the tail shorter, the first
value to try is Stillmere's order 1 without the seal or without the archer (a clerk on a mule), not `Balance`.

### Open, and what waits for the join or later steps

- QUESTS.md 4.4's T11 greedy cell still names "2 offered sendings unsent"; the lane asserts the restated cell (above).
  The director decides whether the spec follows.
- The hall's figures (Pip, Marek on his days) still walk while away: one `ErrandEngine.isAbsent` check in
  `CourtLayout.figures` at the join, after the stage lane's rewrite.
- No screenshot shows "{who} waits in the hall" or one of the twenty new cards yet (the round shoots Pip's card only):
  for the real table screen's step, together with the longest card (`goldenacre_paid`, 240 characters) and the lost
  card (`ludo_lost`).
- T6 without the beacon and T7 for the sender stay chaos-fragile (6, 8 and 17, 18 over the last two rounds); the
  critic's advice to judge them over 40 seeds or a mean is not built: the cells pass, and 40 seeds would not move a
  rate that sits near the band's floor. For the director with the rest of the tuning.
- `tools/simtune` (lacks `Core/Table`), the `Remembered` and `CourtWorld` lists, Pip's court line on day 2, the
  chapel's table: as before, for the join and the table screen's step.
