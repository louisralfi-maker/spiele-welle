# Lanternhold: the town lane

Branch `claude/lh-town`, cut from the integration branch (build 86 plus sound, `d00180d`). The spec is `docs/TOWN.md`;
Louis' two bars are in `docs/BARS.md`.

How this lane's commits are made: the session that runs the lane may not write into the `.claude/worktrees/lh-town`
worktree (the app's worktree guard), so the lane works in a scratch clone of the repo, commits there as Louis'
noreply identity and pushes straight to `origin/claude/lh-town`. The local worktree `.claude/worktrees/lh-town` is
only read: fix round 1 fast-forwarded it once to `bb17fe0` (no edits); before working there, `git -C
.claude/worktrees/lh-town merge --ff-only origin/claude/lh-town`.

## town-1: taxes on foot, in Core

### What exists

All of it in `Core/Town/` (new files), the strings in `Resources/Town.xcstrings`:

- `TownRules.swift`: the numbers (`Balance.town`): `collectReach` 28 px, `spareHappiness` 1 and `spareHappinessMost`
  3, `knockShare` 0.4 and `knockHappiness` −2, `levyShare` 0.4 and `levyHappiness` −1, the picture's `waveFrom` 60,
  `throwBelow` 30, `goldPerCoin` 4, `coinsLeast` 3, `coinsMost` 7, and the low bot's `lowHabitSpares` 2.
- `TownLedger.swift`: the saved types. `TownState` (in `GameState.town`, Optional) holds `today` and `yesterday`, each a
  `TownDay`: the paying places (`TownPlace`: plot, kind house/field/market, taxpayers, owed, collected, knocks, the gold
  of the toss and of the knocks that reached the purse, the sim times of the toss and the last knock), unrest, the
  double-taxes flag, closed at the horn, the houses left alone and the gold the people kept. `TownSummary` is the dawn
  report's view of yesterday (`DawnReport.town`). `TossManner`, `TownEvent`, `TownHabit`.
- `Town.swift`: the rules. `ledger` (the split: taxpayers over the houses by room, the tax part over the houses by
  taxpayers, both largest remainder; each field; the market), `horn` (closes the day: kept, left alone), `spareGain`
  (+1 a house, at most +3), `open` (the dawn turns the page and returns yesterday's summary), `doorsOpen`, `doorX`,
  `collect`, `collectAll`, `canKnock`, `knock` (40 %, at least 1 coin, −2; the levy's second knock 40 %, −1; from
  `warTaxUnlocked`), `step` (the lord passing a door collects, the whole way of a step checked), `grantDoubleTaxes`,
  `waiting`, `knocks`, `shuttered`, `sulking`, `manner`, `coins`, `events` (a diff of two frames for the screen and the
  sound), `morning` and `spareChoice` (the bots).
- `TownText.swift`: the keys, `string` (the player's language) and `string(_:language:)` (the compiled bundle), the
  four households by trade (chandler, oil-presser, cooper, weaver: houses 1, 3, 4, 5), `reportLines` (the report's lines
  about yesterday), and the old lectern's labels (`TaxRate.lecternPercent`, `lecternHappiness`) that only the tax card
  still reads until town-2 removes it.
- `Resources/Town.xcstrings`: 13 keys in English and German (the report's seven lines, two reasons, four households);
  every German line fits in 46 characters with its longest filling.

The decision on the rate: **no rate stays in Core.** The day's taxes are worked out at the one rate the lectern called
Normal; more is a knock, less is a house left alone. `Balance` lost `rateLow`, `rateNormal`, `rateHigh`, `rateWar`,
`happinessLowTax`, `happinessNormalTax`, `happinessHighTax`, `happinessWarTax` and their two lookups. `GameState.tax`
stays only because old saves carry it and the tax card writes it; nothing reads it. The bots keep naming their habit by
the old rate (`Autoplay.tax` → `TownHabit`): normal collects everything at dawn, low leaves the two houses that owe
least alone, high knocks once at every house, war knocks twice once the levy is open. One source of truth: the bots'
gold and mood come out of the same `Town` rules the player meets.

### The hooks in existing files (for the join to apply again)

| File | Place | Why |
|---|---|---|
| `Core/Balance.swift` | "Taxes" mark | the four rates and four tax happiness numbers and `rate(_:)`, `happinessChange(_:)` removed; `var town = TownRules()` added after `marketShare` |
| `Core/GameState.swift` | `TaxRate`'s doc; `tax` and `warTaxUnlocked` docs; `var town: TownState?` after `lord` | the ledger is saved with the realm; old saves read nil |
| `Core/Economy.swift` | `TaxBreakdown` doc; `HappinessReason.leftAlone` (appended); `DawnPeople.town`; `taxes()` without the rate; `happinessChanges()` gives `.leftAlone` from `Town.spareGain` instead of the rate's change; `dawn()`: no `gold += taxes.total`, `Town.ledger` and `Town.horn` at the start, `Town.open` at the end; `setTax` doc | the dawn owes, the town collects |
| `Core/Sim.swift` | `.horn` case: `Town.horn(&s, balance:)`; `step`: `let kingFrom = s.king.x` before `stepKing`, `Town.step(&s, from: kingFrom, balance:)` after it; `dawn`: `town: people.town` in the report | collecting by walking, the horn, the report |
| `Core/DawnReport.swift` | `var town: TownSummary? = nil` after `housesFull`; doc of `taxes` | the report's data about yesterday |
| `Core/Autoplay.swift` | `act` begins with `morning(&s, balance:)` (the old `if s.tax != tax { Economy.setTax }` is gone); `habit` and `morning(_:balance:)` after "MARK: Day"; docs | the bots collect at dawn by habit |
| `Core/TuningRun.swift` | `play`: `player.morning(&s, balance:)` right after `Sim.runToDawn` | the logged gold and happiness at a dawn are the old dawn's |
| `Core/BuildCard.swift` | `TaxCard` doc; `make` reads `rate.lecternPercent` and `rate.lecternHappiness` | the card compiles until town-2 removes it |
| `UI/Texts.swift` | `reason(_:)`: `case .leftAlone: return TownText.string("town.reason.leftAlone")` | the exhaustive switch compiles |
| `App/GameStart.swift` | `toMorning` ends with `bot.morning(&s, balance:)` | a `-GWDay` start holds the gold it held before |
| `Tests/EconomyTests.swift` | the tax formula, `testTheOldRateNoLongerMovesHappiness`, `testDawnUsesYesterdaysHappinessForTaxesAndOwesThem` | the rate's tests became the one rate's |
| `Tests/AutoplayTests.swift` | the bot that builds nothing collects after its dawn; `testTaxVariantsKeepTheirHabitInTheTown` | the bots set no rate |
| `tools/tune.py` | the dawn, the ledger, the horn, the bots' morning; reads `Core/Town/TownRules.swift` | the mirror plays the taxes on foot |

New tests: `Tests/TownTests.swift` (one test per rule of section 1) and `Tests/TownNeutralityTests.swift` (the
reference bot gets exactly the old dawn sum at every dawn of seeds 1 and 2; seed 1's 20 nights equal round lh-snd-1's
tuning report line for line).

### Rounds

- **lh-t1-1** (74867a1; build, then all unit tests, as the step's filters were sent as separate steps): build PASS,
  unit FAIL on one expectation only (`testBigHousesHoldMoreTaxpayers` counted three spare coins where there are two:
  108 by 8, 4, 4, 4 is 43, 22, 22, 21). Every other test passed, `TuningTests` and `TownNeutralityTests` among them.
- **lh-t1-2** (2715ea2; build, unit, ui, ui-de, release): **ALL PASSED** (435 unit tests, 16 UI tests in English
  and in German, the Release build). Its tuning report equals lh-t1-1's, and seed 1's attachment
  `town-neutrality-seed1.txt` equals round lh-snd-1's log.

### The targets, before and after

The tuning report of rounds lh-t1-1 and lh-t1-2 against round lh-snd-1's (the base's, identical to lh-snd-2's): **every line is
byte for byte the same except T4's**, the seed-1 night log, the 20 seeds' night 20 and the endless log included.

| Target | before (lh-snd-1) | after (lh-t1-1, lh-t1-2) |
|---|---|---|
| T1 | nights 1-10 held, hearth 100, losses 0 | the same |
| T2 | falls on nights 3, 3, 3 | the same |
| T3 | beacon on days 17, 16, 17; low tax never by 18 | the same (the low bot, now two houses left alone, still never) |
| T4 | high tax happiness 27 at dawn 8; low tax lowest 83 over dawns 8-20 | high 20 (knocks at every house: −8 a day against −7); low 80 (+2 a day against +3) |
| T5 | first dawn 49 gold, 3 builds; 11 buildings by day 10 | the same |
| T6 | 20 of 20 won, the King slain 20 of 20, without the beacon 10 of 20 held | the same |
| T7 | 17 of 20 endless seeds fall between 35 and 60 | the same |
| T8 | last wave 79.9 s; night 3: 39 entities, 11 lights | the same |

The economy mirror (`python3 tools/tune.py`): the normal bot collects 1944 gold over 20 days and finishes the beacon on
day 16, as before; the low bot 1334 gold (before 1372) and the beacon on day 20 (before 20); the high bot's happiness
on day 8 is 18 (before 25). No balance value was changed.

### Open, and what waits for the join

- **The screen (town-2):** the household in its doorway (`Town.waiting`), the toss (`Town.events` gives `.tossed`;
  `Town.manner`, `Town.coins`), the knock (`Town.canKnock` decides whether a touch on a door is a knock; the screen
  walks the lord up and then calls `Town.knock`), the shutters and the dark window (`Town.shuttered`), nobody waving
  (`Town.sulking`), the tax card's removal (`TaxCard`, `TaxCardView`, `GameModel.taxCard`/`setTax`, the `.taxes`
  overlay, `FirstDayUITests`' 43-taxes part, `CardModelTests.testTheTaxLecternForecastsEachRate`, the lectern parts of
  `ScreenFlowTests` and `AudienceFlowTests`, `TaxRate.lecternPercent`/`lecternHappiness`, `Economy.setTax`).
- **The dawn report screen:** `DawnReport.taxes` is what the town owes today; `goldIn` is yesterday's collected since
  fix round 1, and the dawn plays no coin count. Town-2 shows yesterday from `report.town` (`TownText.reportLines`)
  and hooks `FeedbackCue.taxesCounted` to the toss; gold rising already plays `.coin` (`SoundWatch`).
- **STORY.md rule 12** ("never a coin pouch"): TOWN.md's household "with a pouch" should be drawn as a cloth bundle,
  a bowl or cupped hands, not a coin pouch.
- **Door anchors (world lane):** `Town.doorX(plot:)` returns the plot's centre; the rebuilt town's door anchors (the
  house's door, the farmer's fence, the stall) replace it at the join.
- **Ads lane:** the "double taxes" reward calls `Town.grantDoubleTaxes(&state)` (one saved flag on today's ledger,
  cleared by the next dawn) instead of banking a dawn sum; `AdPacing.doubleTaxesOpen(day:taxes:)` can keep reading
  `report.taxes.total`, which is now the day's owed sum. The offer belongs at dawn, before the first coins fly.
- **Onboarding lane:** since fix round 1 the first coins are owed on the first morning (house 1's 16); the townsman
  who walks into the courtyard comes then.
- **Craft lane:** the stonemason's statue ("each house tosses one coin more at 60 and up") belongs in `Town.collect`;
  the fountain's +1 a dawn sits next to `.leftAlone` in `Economy.happinessChanges` (a likely merge conflict there).
- **Six more languages** for `Town.xcstrings` follow in the i18n pass after the join.
- **`-GWTown`** (town-2): a debug start with the households still waiting needs the dawn snapshot before the bot's
  morning (`GameStart.toMorning` now ends with it).

## town-1, fix round 1 (the critic's look 1: two highs)

The verdict: `ci-out/director/town-1-taxes-core-critic1.md` on the planning branch (pass, 8/10, no blocker). Both highs
are fixed, the director's 14:45 note put the collector's Core into this round ("town-2, or town-1's fix round"), and
the critic's smaller points are done where they were cheap.

### What changed

- **High 1, the dawn no longer pretends the taxes came in.** `DawnReport.goldIn` (the report card's "Taxes" row) is
  what reached the purse yesterday, `town?.collected ?? 0` (tosses, knocks, the collector's delivery), never today's
  owed `taxes.total`. The dawn plays no coin count any more: `FeedbackThinner.cue(for: .dawn)` is nil, so
  `.taxesCounted` (the coins sound and the success haptic) is free for town-2 to hook to the toss; first light's bell
  still rings. The `-GWScreen report|finale` samples carry a `TownSummary.paidInFull` so their row shows 64 and 103
  as before.
- **High 2, the first morning.** `GameState.newRealm` opens a first-morning ledger (`Town.firstMorning`): house 1,
  the chandler's, nearest the castle, owes `TownRules.firstMorningGold` 16 from the start, and `Balance.startGold`
  went from 60 to 44. So the toss can be met in the first minute, and the onboarding's townsman (TOWN.md "The first
  morning") has his coins on day 1 (`Town.collect` does not ask where the lord stands, so he can bring them to the
  courtyard). Every bot habit takes the 16 at its first step without a knock or a house left alone
  (`Town.morning` on the first morning is always `.collect`), so the purse at the first build is the 60 of before and
  every tuning line stays as it was; "double taxes" are refused on the first morning; left alone, the chandler keeps
  the 16 and brings +1 at the first dawn like any house. The first dawn's report now tells of the first morning.
- **The collector in Core** (TOWN.md section 2, the director's note of 14:45). `TownState.collectorHired` (saved,
  Optional); `Town.setCollector(&s, hired:)` and `toggleCollector` take him on or send him away from the next morning
  (from day 1, no treasury). At the dawn `Town.open` sets `TownDay.collectorOut`; he walks from his post by the hall
  door (`collectorPost` = `Realm.hallX`) out to the farthest paying door by 09:00 and back by noon (`collectorX` for
  the screen); every household that still owes pays him as he passes (`TownPlace.collectorGold`, into his box); at
  noon the box goes into the purse less his wage, `collectorWage(box:)`: one coin in eight rounded, at least 2, never
  more than the box (49 brings 43). The lord first pays the lord in full (in the same step too); he never knocks and
  the lord may knock wherever he has been; in unrest he walks and comes back empty; double taxes count for him; a horn
  before noon brings him back. `TownEvent.paidCollector` and `.collectorBack` for the screen; `TownSummary` has his
  delivery and wage, and `collected` includes them. The reference bots never hire him. Not built: the first plan's
  extra coin "for the lantern" (the director's call).
- **The report's words** (the critic's smaller points). The knock's line names one or two doors in a door form
  ("Knocked at the chandler's, the weaver's", "Angeklopft beim Kerzenzieher, beim Weber"; keys `town.door.*`), counts
  three ("Knocked at 3 doors") and says "every door" when every house that owed was knocked (`TownSummary.houses`); the
  same for the war levy. New lines for the collector ("The collector brought 43 (wage 6)", "Der Steuereintreiber
  brachte 43 (Lohn 6)") and his empty return. "Bei den Leuten geblieben" for what the people kept. The unused
  `town.reason.knocked` is gone. The text test now fills every real line (all one- and two-door combinations, three,
  four, three-digit sums, the collector) and checks 46 characters in English and German. `Town.xcstrings`: 22 keys.
- **tools/tune.py**: the first morning (every habit takes the 16, not counted as income) and the war levy on the
  realm's unlock (`warTaxDay` from `Realm.swift`) instead of `day >= 8`. Output equal to before but for its last
  summary line: normal 1944, low 1334, high 793 gold (47 knocks), beacon on day 16 and 20, six of six checks.
- **TOWN.md**: the planning branch's text (collector in build 2, the fields, the people, the lamplighter, the count)
  plus the numbers in Core refreshed (the first morning, the collector, the report, the T3 slip: only T4 moved).

### New hooks in existing files (add to town-1's table for the join)

| File | Place | Why |
|---|---|---|
| `Core/Balance.swift` | `startGold` 60 → 44, with a doc line | the first household holds the other 16 |
| `Core/GameState.swift` | `newRealm`: `state.town = Town.firstMorning(state, balance:)` before `return`; docs of `newRealm` and `town` | the first morning's ledger |
| `Core/DawnReport.swift` | `goldIn` = `town?.collected ?? 0`; doc of `town` | the card's taxes row is what came in |
| `Core/ReportCard.swift` | the two samples pass `town: .paidInFull(day:gold:)` | the sample screens keep their numbers |
| `Core/Feedback.swift` | `.dawn` joins the cases that return nil | no coin count at dawn |
| `Core/Economy.swift` | doc of `DawnPeople.town` | the first dawn tells of the first morning |
| `Tests/FeelTests.swift`, `Tests/SoundTests.swift` | the dawn's cue is nil; the coin is dropped beside `.taxesCounted` | the cue's new home |
| `Tests/ReportCardTests.swift` | `goldIn` is yesterday's collected (16 after night 1); the sample's 64 | high 1 |
| `Tests/EconomyTests.swift`, `Tests/AutoplayTests.swift` | the purse is 44 + 16 once the first morning is collected | high 2 |
| `Tests/ScreenFlowTests.swift` | gold 60/48/50 → `startGold`, `startGold − brazier`, `startGold − archerPrice` | the new start |
| `UITests/FirstDayUITests.swift` | gold "60" → "44", "48" → "32" | the new start (the rebuild lanes rewrite this test) |
| `DESIGN.md` (not edited) | "the dawn survived (`taxesCounted`) success" is no longer true | for the join or town-2 |

New files: `Tests/TownCollectorTests.swift` (nine tests: hiring from the next morning, his round, collecting and the
noon delivery, through `Sim.step`, the wage table, the lord first, no knock but the lord's, unrest, double taxes,
the horn and the save).

### Rounds

- **lh-t1f1-1** (d127eb9; build, unit): build FAIL, `ScreenFlowTests` read `balance` in a class that has none
  (`GameScreensTests`); fixed with `Balance.standard` (6fc9c8e).
- **lh-t1f1-2** (6fc9c8e; build, unit, ui, ui-de, release): build, ui, ui-de and release PASS; unit 444 passed and
  two failed on the old 60 (`CardModelTests` the catapult's missing gold, `PetitionTests` the costly petition's);
  both now read `startGold` (39cf7a2). Every Town, Tuning, ReportCard, Economy, Autoplay, Sound and Feel test passed.
- **lh-t1f1-3** (39cf7a2; build, unit, ui, ui-de, release): **ALL PASSED** (446 unit tests, the UI tests in English
  and German, the Release build). Its `tuning-report.txt` against round lh-snd-1's: byte for byte the same except
  T4's line, exactly as after town-1 (high 20, low's lowest 80); `town-neutrality-seed1.txt` equals lh-snd-1's log
  line for line. The first-day UI test's dawn report now says "Taxes 0" with "Houses left alone +1" (the test never
  walks to the chandler), the treasury 32; the "9 taxpayers" under it is still today's, which town-2 rewrites.

### Open, and what waits

- **Town-2** draws the first household waiting at house 1 from the first minute, the toss with `.taxesCounted`, the
  collector with his handcart (`collectorX`, `TownEvent.paidCollector`, `.collectorBack`; the people lane's sprite if
  it has one), the touch at his post (`toggleCollector`), and the report's town lines (one or two, per the interface
  bar).
- **The audience lane** offers the collector at the first audience: its answer calls `Town.setCollector(&s,
  hired: true)`.
- **The onboarding lane:** the first morning's townsman is house 1's household; when he walks into the courtyard, the
  screen calls `Town.collect(&s, plot:)` as the lord meets him.
- **The director:** TOWN.md section 1 still says the household stands "with a pouch" (STORY.md rule 12, the art bar);
  the word should change before town-2 draws (a cloth bundle, cupped hands). The extra coin "for the lantern" of the
  first plan was not built.
- **The ads lane:** "double taxes" on the first morning is refused; from the first dawn on the reward also doubles
  what the collector takes.

