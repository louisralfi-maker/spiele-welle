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


## town-2: taxes on foot, on screen (14.11.2026)

The brief: TOWN.md section 1, "The sign", "The knock", "The interface", "The picture", for TestFlight build 2. Louis'
bars (`ci-out/director/artbar.md`): pixel art at triple-A level from hand-placed pixels; no prompt, no label, no HUD
mark; the world explains itself.

### What a player sees

- **The sign.** From the dawn until it has paid, each household stands before its open door with the day's coins in
  its cupped hands (the coin catches the light with each breath); the stall keeper at the market, the farmer at the
  field's edge with his knotted cloth. Nothing on the HUD. After the horn the doors are shut and nobody waits.
- **The toss.** The lord walks past (28 px, Core's rule): the household draws back and throws; three to seven coins fly
  in an arc into his hand one after the other. Each landing is heard (the coin sound and the soft tap) and the gold
  rises coin by coin as they land; the last coin plays `.taxesCounted` (the coins and the success haptic). From 60
  happiness the household waves (not the day after a knock), between 30 and 60 it nods and goes in, below 30 it flings
  the coins at the lord's feet (they lie a moment, then hop into his hand; never left on the ground) and turns its
  back. Then it steps back in and the door shuts. The farmer never tosses: he counts his coins out of the cloth in low
  hops. Reduce Motion: no arcs; each coin fades in at the lord's hand as it would have landed.
- **The knock.** A touch on the door of a house that has paid today: the lord walks up (the realm strip's travel), stands
  at the door's near side and knocks three times (his knock pose, three knock sounds with a rigid tap each); the door
  opens, the household steps into it, bows and holds the coins out; they hop into the lord's held-out hand (gold rises
  as they land); a deeper bow, it steps back, the door shuts, then the two shutters close (two dull knocks). The house's
  window stays dark that night (no lit room, no glass glow, no window light); the next dawn opens the shutters and
  nobody there waves that day. A touch on a door that owes walks him past it (he takes the toss); a touch on a door
  that is shut to him (knocked as often as allowed, unrest) gets one knock and nothing opens. By day only. He stops
  beside a household that still owes (18 px from its door), so its toss is seen; he knocks from 6 px, the fist on the
  door.
- **The child** (TOWN.md section 6): from 60 happiness, on one day in three for each house (`(day + plot) % 3 == 1`),
  Nib Brisk holds the coins up in the door instead of the grown-ups, runs out ten pixels toward the lord, throws them
  and skips home (`TownShow.byChild`, `childFigure`); her coins leave the hand 0.22 s later.
- **The first morning** (critic look 2 on town-1): the chandler's household, Mother Corra, waits in the courtyard before
  the hall door (`Town.firstMorningX`, 1690); the lord meets her as he steps out of the hall, she tosses her 16 coins
  and walks home to the town (right, fading after six seconds).
- **The tax card is gone**: the throne's crown shows only while petitioners wait; the lectern stands as furniture.
- **The dawn report's taxes row** shows what reached the purse yesterday and one line about yesterday (a knock, else
  what the people kept, else the collector; in unrest the shut doors); no longer today's taxpayers.

### What exists (new files)

- `Core/Town/TownSprites.swift`: the sprite contract (sizes, frames, the figure of each place, the lord's knock sprite).
- `Core/Town/TownShow.swift`: what the town shows at a moment, pure functions of the realm and its sim time
  (`TownPlace.tossedAt`, `knockedAt`): `scene` (houses with door open / shutters / dark, figures, coins, the lord's
  pose), `goldInFlight` and `heard` (the purse held back until the coins land), `cues` (knocks, shutters, counted),
  `spots` (the houses as `EntityFrames.town` draws them, their doors), `door(atX:y:)` (the touch box, 24 x 24 game px
  = 48 pt), `knockSpot`. Every timing is a constant at the top of the file.
- `Core/Town/TownFrames.swift`: `apply(&layer, ...)` after the court's: the overlays as props (z 0, ids from
  3 000 000, the house's shade and mirror), a knocked house darkened (its lit rooms, glass masks and window lights
  removed), the figures inserted before the lord, the coins after everyone, the lord's sprite swapped for his knock
  pose (and his glow strip dropped for that moment).
- `Core/Town/TownDebug.swift`: `-GWTown owed|paid|knock`.
- `App/GameModel+Town.swift`: `stepTown` (the walk to a door arrives, the knock happens through `Town.knock`, the cues
  play, the door marks follow the camera), `touchTown(at:in:)`, `knock(plot:)`, `townShownGold`, `refreshTownMarks`,
  `TownRun.status` (the UI tests' `town-status`).
- `UI/TownTapLayer.swift`: a clear full-screen layer under the walk pad and the HUD that hands taps to `touchTown`; the
  doors on screen as accessibility elements only (`town-door-<plot>`, "Knock at the chandler's door" / "beim
  Kerzenzieher anklopfen", value `knock` or `shut`, a VoiceOver action), and `town-status`.
- `Render/PlaceholderTown.swift`: stand-ins while a PNG is missing.
- `tools/taxart.py` and `tools/grids/town/`: the art (below). `tools/taxsound.py`: `Resources/Sound/knock.wav`.
- `Tests/TownShowTests.swift` (16 tests), `UITests/TownUITests.swift` (4 tests: the taxes on foot from the sign to
  the night, the first morning, the grown town with the big house, the stall and the farmer, Reduce Motion).
- Two keys in `Resources/Town.xcstrings` (English and German, VoiceOver only): `town.access.knock`, `town.access.door`.

### The art (Louis' art bar)

Every figure is a hand-set part grid on the people lane's bodies (copied verbatim from `claude/lh-people` 5427d45 into
`tools/grids/town/base/`; only the arms, the bow and the props are new), built by `tools/actorart.py` through
`bash <artlock> python3 -I -B tools/taxart.py build [names]`. One grid, palette colours only, look 2's selective
outline, light from the upper left. No generated image is involved.

| id | size | frames | who / what |
|---|---|---|---|
| `townCorra` | 12x26 | 15 | Mother Corra, house 1 (the chandler's): wait 0-1, wind 2, toss 3, follow 4, wave 5-6, fling 7, bow 8, deep bow 9, empty 10, walk 11-14 |
| `townDun` | 12x26 | 11 | Dun Rook, house 3 (the oil-presser's), the coins in his bound rag; frames 0-10 as Corra's |
| `townBrede` | 12x26 | 11 | Brede Hask, house 4 (the cooper's), bare heavy arms |
| `townHemmet` | 12x26 | 11 | Old Hemmet, house 5 (the weaver's), bent double, his stick leaning on him; a flick, a lifted hand, a nod |
| `townWenna` | 12x26 | 11 | Wenna Brisk at the market stall, the raw red forearms |
| `townGorm` | 12x26 | 4 | Gorm Ashby at the field: wait 0-1 with the knotted cloth, count 2-3 |
| `townNib` | 10x18 | 9 | Nib Brisk, the child: run out 0-3 with the coins, hold them up in the door 4, throw 5, skip home 6-8 |
| `kingKnock`, `ladyKnock` | 16x30 | 3 | the lord's knock: fist raised 0, knock 1, hand held out 2; the pole in the far hand behind him; the same anchor as `king`/`lady` |
| `townCoin` | 3x3 | 4 | a coin turning: face, three quarters, edge, three quarters |
| `townCottage` | 64x46 | 4 | over a cottage: the open door 0; the closed shutters of `house` 1, `houseB` 2, `houseC` 3 |
| `townBigHouse` | 72x56 | 2 | over the big house: the open door 0, the closed shutters 1 |

The overlays are cut from the houses' own paintings: the open door is the door leaf's rectangle (cottage cols 26-36,
rows 29-42; big house cols 30-40, rows 41-52) as a dark room with the leaf seen edge-on at the hinge side; the closed
shutters are each window's painted open leaves moved over its 7 px glass (the same pixels, a dark seam between them)
with plaster where they hung. The atlas gains 12 strips, 79 frames. No pouch anywhere (STORY.md rule 12, the art bar's
"never its coin pouch"): the households hold their coins in cupped hands, the farmer in a knotted cloth.

### The hooks in existing files (for the join to apply again)

| File | Place | Why |
|---|---|---|
| `App/GameModel.swift` | after `talkLog`: `townRun`, `townMarks`, `townStatus` | the screen's state |
| `App/GameModel.swift` | `advanceGame`: `watch.cues(TownShow.heard(...))`; `stepTown()` after `stepCourt` | the purse heard as the coins land; the knock and its cues |
| `App/GameModel.swift` | `frame()`: `TownFrames.apply(...)` after `noteCourtFrame` | the picture |
| `App/GameModel.swift` | `refreshHUD`: `gold = townShownGold(s, ...)` | gold rises coin by coin |
| `App/GameModel.swift` | `performAction`: `.throne` opens only the audience; `.lectern` does nothing | no tax card |
| `Core/KingTargets.swift` | `target()`: `consider(.throne, ...)` and `consider(.lectern, ...)` removed | the button never offers the tax card |
| `UI/GameView.swift` | `TownTapLayer(model:)` after `WorldSceneView`; `WalkPad`: `.simultaneousGesture(SpatialTapGesture ...)` | the touch on a door |
| `Core/FrameDesc.swift` | the `SpriteID` cases (end of the enum), `size` case, `frameCount` first line | the sprites |
| `Render/PlaceholderArt.swift` | `PlaceholderTown.frames` last in the fallback chain | stand-ins |
| `Render/Renderer.swift` | `rimmed` + `kingKnock`, `ladyKnock`; `people` + `TownSprites.figures` (the people lane edits the same line) | the rims |
| `Core/Feedback.swift` | `FeedbackCue.knock`, `.shutter` | the knock's and the shutters' sound |
| `Core/SoundCues.swift` | `SoundID.knock`; `minimumInterval`, `varies`, `sound` (`.knock`, `.shutter` on knock.wav), `haptic` (rigid, soft) | the same |
| `Resources/Sound/MANIFEST.txt` | the `knock` line (written by `tools/taxsound.py`) | the manifest |
| `App/DebugArgs.swift` | `GWTown` key, `town` field, its parse | `-GWTown` |
| `App/GameStart.swift` | `TownDebug.apply` before `applyNumbers` | `-GWTown` |
| `Core/ReportCard.swift` | `var town: TownSummary? = nil`, `make` passes `report.town` | the taxes row |
| `UI/ReportCardView.swift` | `taxDetail` asks `TownText.reportDetail` first | the taxes row |
| `Core/Town/Town.swift` (this lane's) | `firstMorningX`, `meetX`; `step` meets at `meetX` | the first morning in the courtyard |
| `Tests/TownTests.swift` | the first morning's toss in the courtyard | the same |
| `Tests/CardModelTests.swift`, `Tests/AudienceFlowTests.swift`, `Tests/ScreenFlowTests.swift`, `Tests/TalkTests.swift` | no throne target without petitioners; the lectern is furniture (Odile at her lectern talks) | no tax card |
| `UITests/FirstDayUITests.swift` | the lectern part (43-taxes) removed | no tax card |

### How the join re-hooks the door touch (the rebuilt town and the stage lane's touch)

1. **The rebuilt town's doors.** `TownShow.spots(_:)` is the one place that knows where a door is: it mirrors
   `EntityFrames.town` (the cottages tile, slate, thatch, tile; every second house mirrored; the door's middle column
   31 of a cottage, 35 of the big house). Replace its body with the world lane's door anchors from the layout data (a
   door x per house plot, the house sprite, its mirror) and point `Town.doorX(plot:)` at the same anchors (the fields'
   and the stall's anchors too). `TownFrames.apply` then draws the world lane's own sprite states instead of
   `townCottage`/`townBigHouse` (the world lane's brief: each house's window and shutters lit, dark, shuttered as
   sprite states; an open door state): keep `TownShow.House.doorOpen`, `.shutters`, `.dark` as the switches.
2. **The stage lane's touch.** Wherever the stage lane's input takes a tap on the walked world (before its own "any
   other touch" handling), call `model.touchTown(at: point, in: size)` first: it converts the point with the game's
   camera and pixel scale, asks `TownShow.door(atX:y:)` (a 24 x 24 game px box over the door, standing on the ground)
   and returns true when a door took the touch (the lord then walks there). Then drop `TownTapLayer`'s own tap gesture
   (keep its accessibility marks and `town-status`) and the `WalkPad` hook if the walk pad goes. Nothing else of the
   town reads the input.
3. **The gold above the lord** (HUD.md section 3): show `townShownGold(state, balance:)` instead of `state.gold`, so it
   ticks with each landing coin; `SoundWatch` already hears the shown purse.
4. **The stage lane's hall `openCard(.taxes, ...)` calls** go (the director's note of 19:35).
5. **Dead code to delete at the join** (kept here so the rebuild lanes' files merge with fewer conflicts): `TaxCard`
   (Core/BuildCard.swift), `TaxCardView` (UI/BuildCardView.swift), `Overlay.taxes`, `GameModel.taxCard`/`setTax`,
   `OverlayView`'s `.taxes` case, `KingTarget.lectern`, `HUDView`'s `.lectern` action and "Set the taxes",
   `TaxRate.lecternPercent`/`lecternHappiness`, `Economy.setTax` with `EconomyTests`' war-tax test,
   `CardModelTests.testTheTaxLecternForecastsEachRate`, `FeedbackCue.taxSet`.
6. **The people lane:** if its bodies change after 5427d45, copy them into `tools/grids/town/base/` again and rebuild
   (`taxart.py build`); the poses only add arms, a bow and props.

### Rounds (by the director's notes of 18:46 and 19:35: filtered rounds while working, one gate round)

- **lh-t2-1** (85a9f24; build, nine unit classes): build FAIL in the tests only (the renderer's rim sets read from a
  nonisolated autoclosure); the app compiled without a warning in the town's files.
- **lh-t2-2** (da9c246; the same): build PASS; unit FAIL on `AtlasTests.testLook2ArtIsBundled` (the PNGs were not
  committed yet) and the toss test's fixed 11 gold (house 3 owes 10 at 50 happiness); every other test passed.
- **lh-t2-3** (47d7a60; build, three unit classes, `ui TownUITests`): **ALL PASSED**. Its shots showed three faults,
  all fixed: the lord ran onto the door and hid the household's toss (he now stops 18 px off), his knocking fist met
  the door frame (he knocks from 6 px), the night shot was washed out by his own lantern (the test walks him to the
  well).
- **lh-t2-4** (a51ac31; build, all unit tests, `ui TownUITests FirstDayUITests`): unit FAIL in `ScreenFlowTests` and
  `TalkTests` (eight assertions on the lectern target, the tax card, the bare throne): changed to "the lectern is
  furniture"; both UI classes passed.
- **lh-t2-5** (aedac32; the same): unit FAIL 1 and `testTaxesOnFoot` FAIL 1, both from `-GWTown owed` working the
  ledger out again at the launch's happiness (the chandler owed 17): it now keeps the dawn's parts unless the paying
  places changed; every other UI test passed (the grown town, the first morning, Reduce Motion, the first day).
- **lh-t2-6** (b46ac8e; build, all unit tests, `ui TownUITests FirstDayUITests`): **ALL PASSED** (462 unit tests, 0
  failed; 6 UI tests). Its `tuning-report.txt` and `town-neutrality-seed1.txt` are byte for byte those of lh-t1f1-3:
  T1 to T8 did not move.

### Open, and what waits

- **The collector on screen** (the director's note of 14:45: the handcart leaving and coming back, the households
  paying him at the door, the touch at his post): not built in this step. Core has him (`collectorX`,
  `TownEvent.paidCollector`, `.collectorBack`); without the audience lane's offer nobody can hire him in build 2.
- **The town's wandering townsfolk** (`EntityFrames.townsfolk`, visual only) walk through a doorway while a household
  tosses or bows; the people lane's town life replaces them after the join.
- **The old HUD's action button** ("Upgrade: House" and the hammer) shows while the lord stands at a house plot and
  can cover the stall; the stage lane rebuilds the HUD (not restyled here).
- **German** is written for the two new keys and not looked at (the director's note of 19:35); the six other
  languages for `town.access.knock` and `town.access.door` come in the i18n pass.
- **The join**: the hook table and "How the join re-hooks the door touch" above; the dead tax-card code list.

## town-2, fix round 1 (the critic's look 1: four highs, no blocker)

The critic (ci-out/director/town-2-taxes-screen-critic1.md, 7/10) found the engineering sound and the step's purpose
half reached at phone size. All four highs are fixed; what the critic asked to keep is kept (the purse held back until
each coin lands, `TownShow` pure with its timings at the top, the 24 x 24 px door box, the hand-placed people, the
first morning, T1 to T8 and no new saved state).

### What changed

1. **The gold reads at phone size** (high 1).
   - `townCoin` is 4x4 now (5 frames: face, three quarters, edge, three quarters back, glint): a gold edge round a
     cream highlight, a warm brown shade and a dark rim on the shadow side (the game's selective outline), so it stands
     off pale plaster by its hue and its rim.
   - Every coin is an **emissive actor** (`TownFrames.add`: full colour in a doorway's shade, × 1.12) with a **glow of
     its own pixels** under it (`EntityGlow`, the fire's gold × 1.5 in flight, × 1.0 held, × 2.2 glinting), which the
     bloom spreads a little. Coins and the household figures stand on whole game pixels (the houses' grid), so the glow
     lies exactly under its coin and the figure's pixels meet the door's (they stood half a pixel off before).
   - **The waiting pose holds the palm out at the waist** (frames 0-1 of Corra, Dun, Brede, Hemmet, Wenna; the coin
     pixels left the grids) and the engine draws the coin on it (`TownShow.Scene.held`, `TownSprites.heldCoin`; the
     farmer's on his knotted cloth, Nib's over her raised fist). It **glints** (frame 4, × 1.4) for 0.16 s once every
     1.4 s, each house at its own moment; steady with Reduce Motion.
2. **The wanderers keep clear** (high 2). `TownFrames.clearWanderers`: any of the town's visual-only wanderers
   (`EntityFrames.townsfolk`, the citizens' bodies) within 32 px of a place where the taxes happen now
   (`TownShow.Scene.stages`: a household waiting, tossing, paying the collector, or a door knocked at until its
   shutters are shut) stops at 32 px on its own side, stands and turns to watch; from 20 px nearer it fades and within
   10 px it is gone, so it reappears on the far side without a jump. 32 px keeps it clear of the lord, who stops 18 px
   off a door to take a toss. Only in the town (`TownFrames.townWest`): the first morning's stage in the courtyard
   moves nobody, so the court's petitioners in townsfolk bodies are never touched. **Remove it** when the people
   lane's town life replaces the wanderers.
3. **The knock keeps the lantern in place** (high 3). `kingKnock`/`ladyKnock` are the walking sprite's standing frame
   6 with the pole and lantern exactly where that frame holds them; his free far hand comes out under the near arm,
   passes behind the pole and knocks at hip height (the town's doors are low), then is held out palm up for the coins
   (`TownShow.lordHand` dy 16: the coin lands over that palm). No part changes place between the walk, the pose and
   back. His glow strip is no longer dropped: `TownFrames` sets it to frame 6 (`KnockFrame.lantern`) and the pose's
   mirror, and moves the lantern's point light to the glass on the pose's side.
4. **The households pay the collector at their doors** (high 4). When his round reaches a door that owes
   (`Town.stepCollector` sets `tossedAt` and `collectorGold`), `TownShow.scene` plays the hand-over: the bow with the
   coins held out (frame 8), the coins hopping one after another into his strongbox (7 px ahead of him, 9 px up;
   first after 0.1 s, 0.08 s apart, 0.28 s each), the deeper bow (9), empty-handed (10), then in and the door shuts.
   No sound, no haptic, nothing held back from the purse (the gold comes with him at noon). A collector more than
   48 px off (a debug start, a long headless step) gets no coins across the street: the household only bows and goes
   in. The farmer counts his out of the cloth instead. Reduce Motion: the coins fade in at the strongbox.
   - **Exposed for people-2:** `TownShow.Scene.collector` (`CollectorMoment`: his x, his facing, `taking` while a
     household hands over), `TownShow.collectorBox` (where his strongbox must be), `TownShow.handTimes`.
   - **A stand-in** draws him until then: `TownFrames.drawsCollectorStandIn` (a townsman's body, `citizenB`, walking
     at `Scene.collector.x`, its step tied to the ground he covers). The director's note of 14:45 asked for exactly
     this while the people lane has no collector sheet.
   - `-GWTown collector`: every part owed, the collector out on today's round, the clock set to when he is 520 px
     (about 13 s) before the first door that owes.

### New hooks in existing files (add to town-2's table for the join)

None. Everything is in the lane's own files: `Core/Town/TownShow.swift`, `TownFrames.swift`, `TownSprites.swift`,
`TownDebug.swift`, `App/GameModel+Town.swift` (the status gains `hand:<plots>` before `held:`), `Render/PlaceholderTown.swift`
(the stand-in coin is 4x4), the grids and `tools/taxart.py` (`HELD` mirrors `TownSprites.heldCoin`), the tests.

### Rounds (by the director's notes of 18:46 and 19:35: one gate round, `build unit "ui TownUITests FirstDayUITests"`)

- **lh-t2f1-1** (0cd01a6): build FAIL, one error: `TownDebug.apply`'s switch did not name the collector start.
- **lh-t2f1-2** (e35a9fe): build PASS; unit FAIL 1 (the knock test read the first lantern light in the frame, a castle
  lantern at x 1360, not the lord's: the test now reads his); ui: all five TownUITests PASS (the collector too),
  `FirstDayUITests.testFirstDay` FAIL ("the crown did not open the audience"): the runner was slow that hour (the app
  took 42 s to launch, the unit tests 418 s against 296 s), and with `-GWTimeScale 4` the lord reached the throne after
  the horn, when no petitioner waits. Not this step's code; it passed again in the next round. Its shots were judged
  and led to two changes: the wanderers' filter keeps to the town, the collector shot waits 0.25 s.
- **lh-t2f1-3** (03f7cc7): **ALL PASSED**. 465 unit tests, 0 failed; 7 UI tests (FirstDayUITests 2, TownUITests 5).
  `tuning-report.txt` and `town-neutrality-seed1.txt` byte for byte those of lh-t1f1-3: T1 to T8 did not move.
  Upright shots: scratchpad `town/ci-out/upright-town-2f1/` (50 to 59, and the 800 % proof sheet).

### For the join

- **people-2 draws the collector:** read `TownShow.scene(...).collector` each frame (x, facing, `taking` for his
  "taking coins at a door" pose), put his strongbox at `collectorBox` ahead of him, then set
  `TownFrames.drawsCollectorStandIn = false` and delete the stand-in block in `TownFrames.apply`. If people-2 lets him
  stop at each door, change `Town.collectorReached` (Core) and nothing here; `collectorNear` (48 px) then only guards
  debug starts.
- **The people lane's town life** replaces `EntityFrames.townsfolk`: delete `TownFrames.clearWanderers` and its call,
  or point it at the new wanderers' sprites (`TownFrames.wanderers`) if they still walk past the doors.
- **The world lane's door anchors:** `Scene.stages` and the held coins follow `TownShow.standX`, so they move with the
  anchors (item 1 of "How the join re-hooks the door touch").
- **A knock's cost in the world** (the critic's smaller point): when the stage lane's "number next to the thing"
  arrives, show the −2 happiness as a short falling mark at the knocked house, not in a corner.
- **VoiceOver** (smaller point, not changed): the doors' `accessibilityValue` "knock"/"shut" is English in every
  language (the UI test reads it); at the i18n pass make it a key or drop it (the label already says it).


## town-3: the treasury, the collector and the growing town, in Core (15.11.2026)

The brief: TOWN.md sections 2 and 3 for TestFlight build 3, Core only (no screen work): the treasury, the collector's
morning round as simulated time, the third house tier, the second tier of market and tavern, the farmsteads and the
far fields (the director's note of 14:20), the town's standing and its 3 % a point, the realm's three stages and the
dawn one is reached (the note of 14:35), the backdrop row's look as a value, T12 with a bot that grows the town and a
neutrality test, the mirror, the words in English and German. The numbers chosen are in TOWN.md, "The numbers in Core
(town-3)" under sections 2 and 3.

### What exists (new files)

- `Core/Town/TownGrowth.swift`: `RealmStage` (hamlet, village, town; saved) and `TownGrowth`: the far fields' and the
  treasury's plots (keys, places, the day they open, `townPlots`, `newPlots`), what each tier gives (`room`,
  `fieldGold`, `marketShare`, `tavernHappiness`), the standing (`points`, `works` for the craft lane, `standing`,
  `taxFactor`), the stages (`stage`, `look` for the scene, `stageDay`, `dawn`), the stand-in sprites until the art, the
  treasury (`treasuryBuilt`, `treasuryPiles`).
- `Core/Town/TownGrowthTuning.swift`: the three T12 bots' orders (`farFieldSteps`, `growthSteps`, `oldTownSteps`,
  `growerOrder`, `oldTownOrder`, `skipsDefenceOrder`, `Autoplay.order(for:)`, `Autoplay.town(_:)`),
  `TownGrowthMetrics` (the per-seed numbers, the pass rule, the report) and `TownGrowthTuning.measure`.
- `Core/Town/TownGrowthText.swift`: `CollectorWords` (his ten lines), `TownText.growthKeys`, `itemName`, `effect`,
  `stageLine`, `collectorName`, `collector(_:)`; `Town.collectorWords(day)` picks his line when he is home.
- `Tests/TownGrowthTests.swift` (10 tests: the tiers on the old plots and cards, the far fields and the treasury from day
  5, what the tiers pay and the 3 % a point, a grown town's ledger adds up (300 seeded realms), the stages and the dawn
  that reaches one, a realm that never grows writes nothing, the treasury's piles, the save (and a save from before
  town-3), the economy of before bit for bit (400 seeded realms), the words in English and German and their lengths).
- `Tests/TownGrowthTuningTests.swift` (5 tests: T12's band, the grower holds and the skipper falls, the grown town is a
  village by night 14, the bots that do not grow give today's numbers, the orders).
- 24 keys in `Resources/Town.xcstrings` (48 in all), English and German: the five build options' names and effects,
  the treasury's plot, the two stage lines, the collector's name and his ten lines.

### What changed in this lane's own files

- `Town.swift`: the paying places know the new tiers and the far fields; a field's part is its tier's gold; the dawn
  asks `TownGrowth.dawn` and the summary carries `stageReached`. **The collector's round in sim time** (the critic's
  high 3 on town-2, and the people-2 critic's "heavy step"): his post just inside the castle's town gate
  (`WorldLayout.backGateX` − 40), his pace 18 px/s, a 1.5 s stop at each door that pays him, 20 px short of the door
  (round lh-t3-1's shot: stopped on the door's x, town-2's stand-in hid the household), the houses and the stall only
  (the farmers pay the lord in person), home when he is home (about 14:01 with four cottages, 15:17 with the stall),
  `collectorRound`, `collectorSchedule`, `collectorLeg`, `collectorHeading`, `collectorReached` (saved: a door passed
  while shut does not pay later). `collectorTurnHour` and `collectorBackHour` are gone from `TownRules`;
  `collectorPace`, `collectorStop`, `collectorStandOff` and the growing town's and the treasury's values came
  (`standingTaxShare` 1.5 %, set again for T12: at TOWN.md's 3 % the grower was 39.6 % ahead, round lh-t3-1).
- `TownLedger.swift`: `TownState.stage`, `stageDay`; `TownDay.collectorReached`; `TownSummary.stageReached` (all
  Optional: older saves load).
- `TownShow.swift`: a townhouse's door is the big house's; the collector faces by `Town.collectorHeading`.
- `TownDebug.swift`: `-GWTown collector` puts him 234 px (13 s at his pace, never behind his post) before the first door.
- `TownText.swift`: `keys` takes the growth keys.
- `tools/tune.py`: the new tiers, the far fields, the standing, the inn and the market hall; the grower and the old town
  read from `TownGrowthTuning.swift`; T12 among its checks (7 of 7 pass; the reference bots' numbers unchanged).
- Tests: `TownCollectorTests` rewritten for the round in sim time (12 tests: the farmers pay only the lord, a door passed
  while shut, his words), `TownShowTests` (the hand-over at the first door of his round, he stands at the door),
  `UITests/TownUITests.swift` (the collector shot's note: he stands at her door now).

### The hooks in existing files (for the join to apply again)

| File | Place | Why |
|---|---|---|
| `Core/Realm.swift` | `SlotKind`: `case treasury`; `BuildItem`: `case townhouse, marketHall, inn, farmstead, treasury` at the end, `index` 25 to 29, `slot`, `tier` (townhouse 3, the others 2, treasury 1), `upgrade` (bigHouse → townhouse, market → marketHall, tavern → inn, field → farmstead); `makePlots`: the far fields and the treasury added last | the tiers grow on the old plots through the same card; the new plots keep every older id |
| `Core/Balance.swift` | `defaultItems`: five rows at the end (townhouse 110/25, marketHall 120/28, inn 90/22, farmstead 45/14, treasury 90/24) | the prices follow `BuildItem`'s order |
| `Core/GameState.swift` | `houseRoom`: `room += TownGrowth.room(plot.item, balance:)` | a townhouse holds 12 |
| `Core/Economy.swift` | `taxes`: `raw = ... * mood * TownGrowth.taxFactor(state, balance:)`, `fields = TownGrowth.fieldGold(state, balance:)`, the market by `TownGrowth.marketShare`; `happinessChanges`: the tavern's change by `TownGrowth.tavernHappiness` | the standing, the farmstead, the market hall, the inn (a town that never grows computes the old sums bit for bit) |
| `Core/Autoplay.swift` | `Plan`: `case grower, oldTown, skipsDefence`; `act`: `guard plan != .buildsNothing`; `habit`: `plan == .buildsNothing ? .collect : TownHabit(tax)`; `planDay`: `let order = Autoplay.order(for: plan)` | T12's bots |
| `Core/EntityFrames.swift` | `town`: `.bigHouse?, .townhouse?`, `.field?, .farmstead?`, `.market?, .marketHall?`, `.tavern?, .inn?`; `townSprite` the same; `markers`: `if TownGrowth.newPlots.contains(index) { continue }` | stand-ins until the art; nothing of the new plots drawn before the join (and look 1's "river-golden" hash keeps its far fields away) |
| `UI/Texts.swift` | `itemName`, `effect`: the five new cases → `TownText.itemName`, `TownText.effect`; `slotName`: `.treasury` → `TownText.string("town.slot.treasury")` | the exhaustive switches compile; the words are in Town.xcstrings |
| `UI/SpriteThumbnail.swift` | `sprite(for:)`: the five new cases → `TownGrowth.standInSprite` | the build card's thumbnails until the art |
| `Tests/BuildTests.swift` | `Realm.plots.count` 29 → 32 | the new plots |

### What the join needs (art and screens)

1. **The treasury's place in the rebuilt castle.** The world lane's bay near the hall's door: set `TownGrowth.treasuryX`
   to it. Sprite states: the empty bay (with its plot marker: take the treasury out of `TownGrowth.newPlots`), the
   scaffold, the treasury with 0 to 6 chests and piles, `TownGrowth.treasuryPiles(gold: shownGold, built:, rules:)`
   each frame (pass `GameModel.townShownGold`, so the piles grow as coins land and shrink as the count pays).
2. **The collector's sprites.** The people lane's Saul Bracken (`collector`, 34x24, 8 frames) driven by
   `Town.collectorLeg(day, hour:, rules:)`: `.out` the cart walk, `.atDoor` the take (frames 6 and 7 over the 1.5 s
   stop, 20 px short of the door: the cart ahead of him reaches toward the household; town-2's hand-over coins already
   fly to `TownShow.collectorBox`, set it to the cart's slot), `.back` the walk turned home, `.home` the
   idle at his post until the horn. Replace town-2's stand-in (`TownFrames.drawsCollectorStandIn = false`) and the
   people lane's own clock (`TownLife.collectorHours`, `collectorPace`, `doorStop`) with `Town.collectorSchedule`; one
   anchor for his post from the world lane for both (`Town.collectorPost` and `TownLife.collectorPost` are both 2290
   now). His words: `town.collector.offer` with "Take him on" (→ `Town.setCollector(&s, hired: true)`) and "Not now"
   for the audience lane's first-audience offer; a speech line at his post after a touch (`hired`, `dismissed`,
   `rehired`), when he is home (`Town.collectorWords(day)`), and `farmers` the first time he passes a waiting farmer.
3. **The house tiers.** A townhouse painting (with lit rooms, a door anchor, the shutter states of town-2's
   `TownShow.House`), a market hall, an inn, a farmstead at each field (a barn, a haystack, an ox), the two far fields
   with their fences (`Town.doorX` for them is the plot's x until the anchors come; take them out of
   `TownGrowth.newPlots` and add them to the world's town drawing). Until then `EntityFrames` draws the townhouse as
   the big house, the hall as the market, the inn as the tavern, the farmstead as the field.
4. **The three backdrop looks.** The town's backdrop row in three states (hamlet, village, town: more roofs, a spire,
   more smoke, more lit windows at night) chosen by `TownGrowth.look(state)`; the roads and roofs of REALM.md section 2
   by the same value; the people lane's `PeopleCast.ClothState` from it (its `ClothState(standing:)`), the craft lane's
   `CraftStage.of` from it. On the dawn `report.town?.stageReached` is set: the bell, the people in their doors, and
   the report card's one line `TownText.stageLine(report.town)`.
5. **The price shown as coins over a door** (PAY.md, the count): a touch on a house, a field, the stall, the tavern or
   the treasury's bay shows the next tier's price (`Build.options(state, plot:)`) as coins over its door anchor;
   holding or tapping counts them out; the last coin gives the one order (`Build.order`). The effect lines
   (`TownText.effect`) are for whatever card or plaque the stage lane keeps.
6. **The craft lane's works**: `TownGrowth.works(s)` returns `CraftWorks.townWorks(s)` (one point each).
7. **The farmers seen at work** on every built field, the far fields too (the people lane's `TownLife.farmers`).
8. **Six more languages** for the 24 new keys in the i18n pass.

### Rounds (by the director's notes of 18:46 and 19:35: filtered rounds while working, one gate round)

How the lane worked: as in town-1 and town-2, in a scratch clone (the app's worktree guard refuses writes into
`.claude/worktrees/lh-town`), committing as Louis' noreply identity and pushing to `origin/claude/lh-town`.

- **lh-t3-1** (80e5f25; build, eleven unit classes, `ui TownUITests`): build PASS, ui PASS (all five TownUITests, the
  collector's with his new round). Unit FAIL on three things: `SaveGameTests`' "more plots than the realm" sample had
  30 plots, fewer than the realm's 32 now (the sample now exceeds the realm); T12 at TOWN.md's 3 % a point was +39.6 %
  (seeds +34.5, +43.0, +41.2 %), over the band (the standing went to 1.5 %); the skipper held night 14 on every seed (it
  is played to night 20 now). Its collector shot (59) showed the stand-in stopped on the door's x, hiding the household
  (he stops 20 px short now).
- **lh-t3-2** (aae6ced; build, `TownGrowthTests TownGrowthTuningTests SaveGameTests TownCollectorTests`): **ALL
  PASSED**. T12 PASS at +28.0 %.
- **lh-t3-3** (c36e60d; build, all unit tests, `ui TownUITests FirstDayUITests`): **ALL PASSED**. 483 unit test cases,
  0 failed; 7 UI tests. `tuning-report.txt` and `town-neutrality-seed1.txt` are byte for byte those of lh-t2f1-3: T1 to
  T8 did not move. `t12-report.txt`:
  - T12 PASS: the grower +28.0 % over the old town at the dawn after night 14 (seeds 1 to 3: +22.8, +32.4, +28.8 %;
    210, 237, 219 against 171, 179, 170), over the reference bot +51 to +61 %; over the 14 dawns together +11 to +13 %.
  - The grower held every night (fallen 1, 1, 0); standing 5, 7, 5 by night 14: a village on dawn 14 on every seed,
    a town on dawn 15 on seed 2.
  - **The skipper fell on night 20 on every seed, and its hearth was untouched (100) on every night before, with
    nobody fallen by night 14.** The first line and the gatehouse alone hold nights 1 to 19 for a bot that never built
    the middle line; only the Lightless King (no beacon) ends it. "Cannot skip the defence" holds at the chapter's end,
    not before: that is the night's difficulty (the front lane's presence, beacons and hearth change it), reported
    for the director, not tuned here.
  - Upright shots (sips bmp → jpeg through the art lock): scratchpad `town/ci-out/upright-town-3/`
    (`59-collector-standoff-en.jpg` and its crops `-crop`, `-door`; `59-collector-lh-t3-1-before-en.jpg` and
    `59-collector-before-crop.jpg`, the stand-in on the door's x).

### Open, and what waits

- **Critic look 2 on town-2, highs 1 and 2** (the knock's hand-over hidden behind the lord; the coins landing in the
  lantern's light) are screen work and not done in this Core step. High 3's Core half is done (he stops at each door
  that pays him, 20 px short of it); its picture half (a strongbox on the stand-in, or Saul's sprite) is the join's.
- **The stand-in collector** (town-2's `citizenB`) is dim against the house's plaster; Saul Bracken's sprite with his
  handcart replaces it at the join.
- **The skipper finding** above, for the director.
- **German** is written for the 24 new keys (the unit tests check presence, braces and lengths); not looked at on
  screen (the director's note of 19:35). The six other languages: the i18n pass.

### Decisions for the director (the lane's choices, each one value or one line to change)

- **The collector is not "back by noon".** At the people lane's heavy pace (18 px/s, the critic's bound) the round is
  home at about 14:01 (four cottages) or 15:17 (with the stall); "noon" would need about 30 px/s. And **the farmers
  pay only the lord** (TOWN.md section 6's farmer counts into the lord's hand): a farmer still waits at the fence after
  the collector has passed, a reason to walk out even with him. One value (`collectorPace`) and one line
  (`collectorRound`'s filter) change it.
- **T12 compares with the old town, not with the reference bot**, and "fully grown by night 14" is not reachable for a
  bot that also builds its walls (standing 6 by night 14, all 10 a few days later): TOWN.md section 3's numbers.
- **The standing counts only what is new** (not the big house, the first market and tavern, the well, the bridge), so
  that every bot that does not grow plays today's game line for line.
- **One price for a field everywhere** (25), not "about 35" for the far fields; the treasury shows the gold and does
  nothing else.

## town-3, fix round 1 (the critic's look 1: two highs, no blocker; 15.11.2026)

The critic (`ci-out/director/town-3-growth-core-critic1.md`, pass 8 of 10) found no blocker and two highs: no switch
kept build 3 out of Monday's build 2, and T12's "cannot skip the defence" was only half shown. Both are fixed; three of
the critic's small things too.

### What changed

- **Build 3's switch, `TownRules.growthOpen`, off by default (high 1).** While it is off:
  - `Build.options` offers no new tier: a big house, the market, the tavern and a field have no next tier, as in
    build 86 (`TownGrowth.offers(item, balance:)`);
  - the far fields and the treasury's plot offer nothing (`TownGrowth.isOpen(plot:balance:)`), so `KingTargets.hasCard`
    is false there, the action button never offers them, the build card never opens on them, and `Build.order`
    answers `.notOffered` (they were already unmarked: `EntityFrames.markers` leaves `TownGrowth.newPlots` out);
  - the standing is 0 whatever stands (`TownGrowth.standing`), so the tax part, the stage, the bell and the backdrop's
    look are those of before.
  - **Build 2 runs with `growthOpen` false; the join's build 3 art lane turns it on** (`var growthOpen = true` in
    `TownRules`) once the tiers, the far fields and the treasury are drawn. T12, `TownGrowthTests` and T12's
    neutrality test play with it on (`TownGrowth.opened(balance)`); every other test, the tuning report and the app
    play with it off.
  - Why `Build.options` and not `GameState.isUnlocked`: `isUnlocked(plot:)` has no balance, and every way to see, open
    or order a plot already goes through `Build.options` (the card, `KingTargets.hasCard` for the action button,
    `Build.order`, the bots). A switch in `isUnlocked` would need a new parameter at every caller, in files the rebuild
    lanes are rewriting. The effect is the same: nothing of town-3's growth can be seen, offered or paid for.
- **T12 shows where the skipper's fall comes from (high 2).** A fourth bot, T6's **walls without the beacon**
  (`Autoplay.reference(buildsBeacon: false)`: every defence of the reference order, never the beacon), plays the same
  seeds to night 20. T12 now also asks that it held the night the skipper fell, on every seed
  (`TownGrowthMetrics.wallsHoldTheSkippersNight`, in `passes` and asserted per seed in
  `testT12TheGrowerHoldsAndTheSkipperFallsForTheDefenceItSkipped`). The report adds the skipper's first night with its
  hearth struck (below 100: `skipperFirstStruck`) and the walls' fall night (`noBeaconFellOn`). "By night 20" stays
  as it was: whether T12 asks for more is the director's (see Open).
- **Small things from the critic's list:**
  - `Town.collectorTurn(day, rules:)` takes the balance's rules (the collector's heading and `-GWTown collector` pass
    them), so a tuned stand-off cannot make his heading differ from his schedule; `collectorWords` asks only which
    doors are on his round (`standOff: 0`).
  - The bell rings once per stage: `TownState.stageBest` (Optional, saved) keeps the highest stage ever reached, and
    `TownGrowth.dawn` announces a stage only above it. A town that burns back to a village and grows again is not
    announced twice (`TownGrowth.bestStage`).
  - `tools/tune.py`'s docstring says the mirror plays the growth as if the switch were on.
- **Tests:** `TownGrowthTests.testBuildTwoShipsWithTheGrowingTownShut` (no new tier on any card, the card's options,
  `hasCard`, the action button's plots near the far fields and the treasury, `Build.order`, the gold untouched, the
  standing 0 and no stage written for a fully grown town; the same plots and tiers offered with the switch on); the
  stage test grows back after the fire without a second bell; the save test drops `stageBest` for the old save.

### New hooks in existing files (add to town-3's table for the join)

| File | Place | Why |
|---|---|---|
| `Core/Build.swift` | `options`: after `if current.job != nil { return [] }`, `guard TownGrowth.isOpen(plot: plot, balance: balance) else { return [] }`; the upgrade line `if let next = item.upgrade, TownGrowth.offers(next, balance: balance) {` | build 3's switch: off in build 2 |

`Core/Town/*` (`TownRules.growthOpen`, `TownGrowth`'s switch helpers and `bestStage`, `TownLedger`'s `stageBest`,
`Town.collectorTurn(_:rules:)`) and the tests are this lane's own files.

### For the join

- **Build 2 takes this branch's tip** (with `growthOpen` false). It carries the collector's round in sim time (80e5f25,
  which build 2 needs since the director's note of 14:45) and town-3's Core with the growth shut: no card offers a
  townhouse, a market hall, an inn, a farmstead, a far field or the treasury, and nothing pays for a picture that is
  not there. Take the hooks of town-1, town-2, town-3 and this table; town-3's `EntityFrames`, `Texts` and
  `SpriteThumbnail` hooks stay (they only compile the new cases; nothing reaches them while the switch is off).
- **The build 3 art lane** turns the switch on in `TownRules` when it brings the art of "What the join needs" (town-3,
  points 1 to 7), takes the treasury and the far fields out of `TownGrowth.newPlots` as their markers come, and runs
  `TownGrowthTuningTests` (T12), whose numbers do not depend on the switch's default.
- The stand-in collector (town-2's `citizenB`) is still what build 2 draws until the people lane's Saul Bracken is
  joined; the critic's note: the join must not ship the stand-in.

### Rounds (by the director's notes of 18:46 and 19:35: one gate round, `build unit "ui TownUITests FirstDayUITests"`)

- **lh-t3f1-1** (b9fa609): **ALL PASSED**. Build PASS; 484 unit test cases, 0 failed (483 and the new switch test);
  7 UI tests (TownUITests, FirstDayUITests). `tuning-report.txt` and `town-neutrality-seed1.txt` are byte for byte
  those of lh-t3-3 (cmp): with the switch off T1 to T8 and the neutral seed did not move. `t12-report.txt`: T12 PASS,
  +28.0 % (+22.8, +32.4, +28.8 %), the same as lh-t3-3; the skipper fell on night 20 on every seed and **its hearth was
  first struck on night 20** on every seed (untouched on nights 1 to 19); **every defence without the beacon held
  night 20 on every seed** (`noBeaconFellOn` [0, 0, 0]).
- No screen changed in this round, so no pictures (the collector's shot is town-3's, unchanged).

### Open, and what waits

- **For the director (the critic's high 2, its director half):** the first line and the gatehouse alone hold nights
  1 to 19 untouched for a realm that grows the town instead of the middle line; only the Lightless King ends it on
  night 20. T12 now shows that the fall comes from the missing defence (the walls without the beacon hold that night),
  but not that skipping costs anything earlier. Route to the front lane (T13, T14: presence, the hearth, the nights'
  difficulty), and decide whether T12 keeps "by night 20" or asks for an earlier fall once the front lane's nights
  are in.
- **The critic's other small things**, left for their owners: the farmstead's effect line says "+8 gold every dawn"
  as the field's did, though a field's gold comes only when the lord stands at the fence ("+8 gold a day, at the
  fence": the text and stage pass); "Lanternhold is a village now." follows REALM.md while STORY.md calls the town
  Tallowford (the director's call); Saul's one arm needs a one-handled pull cart (the people lane's sprite); "back by
  noon" needs about 30 px/s (the director's call, one value).
- Unchanged from town-3: the town-2 critic's look-2 highs 1 and 2 (screen work), the dim stand-in collector, German
  not looked at on screen, the six other languages in the i18n pass.
