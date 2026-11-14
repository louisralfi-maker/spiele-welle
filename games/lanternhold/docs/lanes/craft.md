# Lanternhold: the craft lane (travelling craftsmen)

Louis' wish of 14.11.2026: "Fremde Handwerker, die im Thronsaal aufkreuzen und ihre Tätigkeiten anbieten." The spec is
docs/TOWN.md section 4 (build 3). This lane works on branch `claude/lh-craft`, cut from the integration branch (build 86
plus sound), next to the rebuild lanes. Everything of its own lives in new files; existing files carry one-line hooks,
listed below so the join can apply them again to the rebuilt game.

## Step craft-1: the travelling craftsmen (14.11.2026)

### What exists

- **The book** `Resources/Craftsmen/craftsmen.json` (own folder: the petition loader reads only `petitions-*.json`, and
  `PetitionDataTests` wants nothing else in `Resources/Petitions`): the rules (first day 4, a visit every 3 days, back
  once 4 days after "not now") and ten craftsmen, each with work, effect, amount, price, days, pride, first day,
  needs, place, x, Odile's counsel, hall body and portrait parts. `Core/Craft/CraftBook.swift` loads it
  (`CraftBook.standard`) and makes from it the offers (as `Petition` values, weight 0, never drawn) and the speakers
  (guests with a townsfolk body and a composed portrait of fixed parts).
- **The words** `Resources/Craftsmen.xcstrings`, English and German: per craftsman `craft.<id>.name`, `.role`,
  `.text` (the offer), `.again` (the offer when he comes back), `.hint` (Odile), `.c1` (commission), `.r1` `.r2` `.r3`
  (the reactions to commission, not now, no thank you); shared `craft.choice.later` ("Not now") and `craft.choice.no`
  ("No, thank you"). 92 keys, all within the audience card's limits (`CraftTests`). The six other languages follow in
  the i18n pass after the join.
- **The visits** `Core/Craft/CraftVisits.swift` (`CraftState` in the save as `GameState.craft`):
  - From day 4 a visit is due every third day (4, 7, 10, ...). It waits for a free day (no story petition in today's
    queue except the houses' audiences on top) until the next one is due; then one craftsman joins the audience after
    the day's petitioners. Who: drawn with his own seeded stream (seed and day) among those not yet met whose first
    day has come and whose needs stand (the glazier needs a brazier or a fire tower). One craftsman a day at most.
  - "Not now" brings him back once, 4 days later or on the next free day; back once he offers only commission or
    "no, thank you". "No" sends him on for good.
  - Not heard by the horn: on his first visit it counts as "not now", on his return as "no". An unheard craftsman
    costs no happiness (he is a trader, not a subject) and never shows in the dawn report's unheard list.
  - The commission pays at once (the offer's gold, greyed with the reason when short); the work stands from the dawn
    `days` later (1 or 2), without the castle's builders.
  - Bots never commission: the reference bot's audience passes a craftsman by. A realm the craftsmen visit plays
    exactly as one they never visit (`CraftTests.testARunWithoutCommissionsIsTodaysRun`, 14 nights, three seeds,
    normal and high tax, every night's outcome and the final realm equal).
  - Only realms the player plays meet craftsmen: `CraftVisits.begin` (in `GameStart.realm` and `SimDriver.restart`)
    starts them; nil is a realm without craftsmen (every bot's, every test's, every save from before build 3 until it
    loads through `GameStart`).
- **The works** `Core/Craft/CraftWorks.swift`: every effect behind its flag (the work standing), read through
  `CraftWorks.balance` (values of the balance), `CraftWorks.houseCoins` (the statue) and `CraftWorks.dawn` (works
  stand; the portrait's happiness once). `CraftWorks.standing` and `CraftWorks.townWorks` are for the world and the
  town lane's standing.
- **The screen**: nothing new. The offer is an audience card like any other (portrait, name and trade, the two lines,
  the price on the commission, Odile's counsel, the reaction). `-GWScreen craft` opens one (`Core/Craft/CraftSample.swift`,
  `App/GameModel+Craft.swift`): `-GWCraft <id>` picks the craftsman (default `mason`), `-GWCraftAgain YES` his return.

### The ten craftsmen

| id | craftsman, from | work, seen where | effect (behind its flag) | gold | days | first day | pride |
|---|---|---|---|---|---|---|---|
| mason | Dagmar Flint, stonemason, Highcairn | a statue of the lord, pole raised, on the market square | each house pays 1 coin more at dawn while happiness is 60 or more | 90 | 2 | 6 | yes |
| painter | Severin Quell, portrait painter, Stillmere | the lord's portrait in the great hall, the first of a gallery | +3 happiness once, when it is hung | 45 | 1 | 5 | yes |
| founder | Benedek Rook, bell-founder, Greybell | a bell in the gate tower, rung at dusk and when a wall falls | soldiers on the ground move 10 % faster | 75 | 2 | 6 | yes |
| glazier | Merle Tidewell, glazier, Saltgate | glass hoods on every brazier and fire tower | their light reaches 5 % further | 50 | 1 | 4 (needs a brazier or fire tower) | |
| limeburner | Cuno Marl, limeburner, Kilnhollow | tubs of mortar with trowels along the wall walks | every patch mends 30 % of the wall instead of 25 % | 35 | 1 | 4 | |
| weaver | Tekla Morrow, banner weaver, Wendmouth | long teal banners with the gold lantern on the walls | a holding guard steps back at 25 % of his strength instead of 30 % | 50 | 1 | 4 | |
| wheelwright | Joost Felloe, wheelwright, Brackwater | two teal handcarts at the lodge, the builders push them | builders walk 10 % faster | 40 | 1 | 4 | |
| lampmaker | Ivar Glimm, lamp-maker, once of Tallowford | twelve lanterns on posts from the back gate to the town | the unrest line sits at 12 instead of 15 (the grumbling line at 27) | 60 | 2 | 5 | |
| fletcher | Renske Fallow, fletcher, the Seven Hills | a rack of pitch-black arrows by the barracks | a fire arrow's fire burns 3.5 s instead of 2.5 s | 45 | 1 | 4 | |
| ironwright | Ottilie Brand, ironwright, Goldenacre | iron bands on the gate, the lantern gilt where they cross | the gatehouse has 5 % more strength | 70 | 2 | 6 | |

The one line each player remembers (in the offer): the mason's four lords and one very proud ram; the painter's
crowns in Stillmere ("you'd rather hold the pole"); "a bell is a lantern for the ears"; "glass makes no light, it only
refuses to waste it"; "walls are mostly patience, with a little lime"; "whoever can see the colours stands a breath
longer"; "a good wheel is a road you bring along"; "people forgive a lot on a lit road"; "no, I've never met Ser
Ludo; nobody at home has"; "in Goldenacre we gild everything, gates included".

Changed from the director's list, and why: the fountain (+1 happiness a dawn is the tavern's whole effect, far over
5 %) and the clockmaker (a sundial is interface, not an effect; the stage lanes read the hour in the world) went; the
limeburner (the king's own Patch) and the ironwright (the gate) came. The bell's "first volley sooner" had nothing to
move (archers start the night ready), so the bell moves the soldiers on the ground. The works of pride are the
statue, the portrait and the bell.

### The hooks (apply again at the join)

| file | place | hook | why |
|---|---|---|---|
| Core/GameState.swift | after `var court` | `var craft: CraftState?` | the craftsmen in the save (Optional, old saves load) |
| Core/PetitionData.swift | `PetitionCatalog.petition(_:)` | an unknown id with the `craft_` prefix asks `CraftBook.standard.offer(id)` | the card, the hall, the queue find the offer in any catalogue; `PetitionCatalog.standard` and its list stay the files' |
| Core/PetitionEngine.swift | `prepare`, after the guard | `defer { CraftVisits.arrive(&s, catalog: catalog) }` | a craftsman joins once the day's petitioners are drawn |
| Core/PetitionEngine.swift | `horn`, first line | `CraftVisits.horn(&s)` | a waiting craftsman leaves first, costs no happiness |
| Core/PetitionEngine.swift | `dawn`, first line | `CraftWorks.dawn(&s)` | works stand at their dawn |
| Core/PetitionEngine.swift | `hear`, after `apply` | `CraftVisits.heard(&s, petition: petition.id, choice: choice)` | the answer is noted (order, return) |
| Core/PetitionEngine.swift | `holdAudience`, the loop | `where !CraftVisits.isOffer(...)` | bots never commission |
| Core/Sim.swift | `step`, after the guard | `let balance = CraftWorks.balance(balance, for: s)` | the standing works' values for the whole step |
| Core/Sim.swift | `patch`, first line | the same | the mortar (the king's patch runs outside the step) |
| Core/Economy.swift | `taxes`, `taxPart` | `+ CraftWorks.houseCoins(state, happiness:, balance:)` | the statue |
| Core/CourtText.swift | both `localizedString` calls | `table: CraftText.table(for: key, fallback: table)` | craft keys read from Craftsmen.xcstrings |
| Core/CourtSpeakers.swift | `Speakers.speaker(_:)`, `isKnown` | an unknown `craft_` id asks `CraftBook.standard.speaker(id)` | the card's name, portrait and the hall's figure |
| Core/SimDriver.swift | `restart(seed:)` | `CraftVisits.begin(&state)` | a restarted chapter meets craftsmen |
| App/GameStart.swift | `realm`, before `return` | `CraftVisits.begin(&state); CraftVisits.begin(&dawn)` | the player's realm meets craftsmen (bots' never) |
| App/DebugArgs.swift | `Screen` | `case craft` | `-GWScreen craft` |
| App/GameModel.swift | `applyScreen` | `case .craft?: openCraftSample()` | the sample |

### Rounds

(filled in below as they run)

### What is open, and what waits for the join

- **Art (no new art in this step).** The art list below; until then the craftsmen stand in the hall in townsfolk bodies
  and the works are not drawn.
- **The world shows the works** (the rebuild's world and stage lanes): `CraftWorks.standing(s)` lists the craftsmen
  whose works stand; the art list gives each its place. The picture's lights should take `CraftWorks.balance` too
  (today `EntityFrames` asks `Battle.lightSources` with the driver's balance, so the glass's 5 % shows only in the
  simulation's light field).
- **A finished work is told** in the dawn report (one line: "The statue stands on the market.") and seen; the portrait's
  +3 comes after the report today. Interface rule: words only on a card, so the dawn report's card is the place.
- **The town lane:** the standing counts `CraftWorks.townWorks(s)` (the statue and the road lanterns); with taxes on
  foot the statue's coin becomes one coin more in each toss of a content household.
- **Court talk** about the works (Pip on the statue, Brannock on the bell) would make them felt; not in this step.
- **Six languages** after the join, from Craftsmen.xcstrings.

### The art list for the join

Each craftsman's sprite starts from an existing body (townsfolk layout: walk 0-3, idle 4-5) and gets his trade's
silhouette; the portrait is composed today and may get its own 48x48 frame.

| craftsman | start from | what makes him or her |
|---|---|---|
| Dagmar Flint (mason) | `citizen` | old woman, headscarf, leather apron, a mallet and chisel at the belt, stone dust on the sleeves |
| Severin Quell (painter) | `petitionerE` | lean, plum coat, feather cap, moustache, a rolled canvas under the arm |
| Benedek Rook (bell-founder) | `builder` | broad, bald, full beard, leather apron, a small hand bell on a cord |
| Merle Tidewell (glazier) | `petitionerD` | young, red braids, teal tunic, a crate of panes on her back, a blowpipe |
| Cuno Marl (limeburner) | `citizenC` | round, wool cap, smock white with lime, a trowel and a sack |
| Tekla Morrow (weaver) | `petitionerD` | tall, headscarf, blue dress with apron, a bolt of teal cloth on the shoulder |
| Joost Felloe (wheelwright) | `builder` | stocky, wool cap, short beard, a spoked wheel rolled at his side |
| Ivar Glimm (lamp-maker) | `petitionerE` | hooded, teal tunic, a pole hung with three small lanterns (unlit by day) |
| Renske Fallow (fletcher) | `citizen` | young, curly hair, a cap with a long feather, a quiver of black-tipped arrows |
| Ottilie Brand (ironwright) | `citizen` | square-faced, hair in a bun, leather apron, an iron band over the shoulder, a gilder's book |

| work | where in the rebuilt world | how it shows |
|---|---|---|
| the statue (mason) | the town's market square, away from the saint's statue (`town.statue`) and the well, facing the castle | a stone lord with the hooked pole raised; lit by a lamp at night |
| the portrait (painter) | the great hall's wall beside the throne, the first frame of a row of empty frames (the gallery to come) | a framed portrait of the chosen lord or lady (two frames: Burgherr, Burgherrin) |
| the bell (founder) | the gate tower over the gatehouse | a bronze bell in an open belfry; it swings at dusk (the horn's partner, a sound) and when a wall falls |
| the glass (glazier) | every brazier and fire tower in the Throat | glass hoods on the bowls; a clearer flame and a glint by day |
| the mortar (limeburner) | the wall walks of the three lines and the gatehouse | tubs with trowels standing in them; a patch shows fresh pale mortar |
| the banners (weaver) | the gatehouse and the line walls, on the castle side | long teal banners with the gold lantern that move in the wind |
| the handcarts (wheelwright) | the builders' lodge; the builders push them to the jobs | two small teal carts with stone |
| the road lanterns (lamp-maker) | posts along the road from the castle's back gate to the town (like `town.lanterns.extra`, but the road) | twelve lantern posts, lit at dusk with the town's windows |
| the pitch arrows (fletcher) | a rack by the barracks | black-tipped arrows; a fire arrow's fire stays a second longer |
| the gate bands (ironwright) | the gatehouse's gate (every tier) | iron bands across the gate, a small gilt lantern where they cross |
