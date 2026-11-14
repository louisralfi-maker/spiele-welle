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
| founder | Benedek Rook, bell-founder, Greybell | a bell in the gate tower, rung at dusk and in a fight | the lord's rally (soldiers near the lord shoot and strike a quarter harder) reaches 10 % further: 88 px instead of 80 | 75 | 2 | 6 | yes |
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
move (archers start the night ready); the lane's first answer, soldiers on the ground 10 % faster, let more soldiers
fall on hard nights (round lh-c1-4: 11 against 4 over two seeds), so the bell now carries the lord's rally further. The works of pride are the
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
| Core/Audience.swift | `AudienceCard.make`, the `textKey:` argument | `CraftText.spoken(petition.text, state: state)` | fix round 1: the painter's offer follows the realm's stage; every other key passes unchanged |
| Core/Balance.swift | after `fireArrowSeconds` | `var fireArrowStrike = 1.0` | fix round 1: the pitch (a fire arrow's strike against an arrow's; 1 keeps every run as it was) |
| Core/Battle.swift | `stepSoldiers`, `.posted`, after `let fire = ...` | `let shot = fire ? damage * balance.fireArrowStrike : damage`, then `damage: shot` in the projectile and `incoming += shot` | fix round 1: the pitch |

### Rounds

- **lh-c1-1** (75c1009: build, the unit tests the hooks touch, CraftUITests en and de): build, both UI runs PASS; unit
  FAIL on one number: the statue, commissioned on day 1 and free, moved taxes by 6.4 % over 14 nights. Every other
  craft test passed, the neutrality test among them, and every petition, audience, save, start, court, economy and
  autoplay test. The shots showed two faults, fixed in 5948f07: the mason's portrait read as a bald man in a leather
  cap (headscarf and shirt in a cloth tone next to the skin: now a grey bun and a blue dress; the wheelwright's and the
  ironwright's shirts likewise), and six reactions promised the work tonight while it stands from the next dawn.
- **lh-c1-2** (668b9a3: build, CraftTests) ALL PASSED. The effect sizes, each work commissioned on the first day its
  craftsman can come (price left out), against the same realm without it, reference bot, seeds 1 and 2, 14 nights,
  over the nights it stands (over the whole run):

  | work | its system | moved |
  |---|---|---|
  | statue | taxes | +4.4 % (+2.9 %) |
  | road lanterns (high-tax bot) | taxes | +2.6 % (+1.2 %) |
  | portrait | happiness | +2.6 % (+2.1 %) |
  | handcarts | buildings | 0 |
  | bell (then: soldiers faster), glass, mortar, banners, pitch, gate bands | creatures stopped | 0 to -0.2 % |

  No work cost a night. The night's works move nothing measurable in these runs because the reference bot holds
  nights 5 to 14 with the hearth untouched; their mechanism is tested directly (`testTheBalanceWorksChangeTheirOneValue`,
  `testTheMortarMakesEveryPatchMendMore`, `testTheRoadLanternsHoldUnrestOffAtDawnThroughTheSimulation`).
- **lh-c1-3** (13698f2, full) ALL PASSED (its wait timed out here; the result was fetched later).
- **lh-c1-4** (e7cf669, full: build, unit, ui, ui-de, release) ALL PASSED: every unit test of the game (T1 to T8
  unchanged), every UI test in English and German, the Release build. Its new report of harder nights (a bot that keeps
  four in five people at work, so few soldiers) found a fault: with the bell's first effect (soldiers on the ground
  10 % faster) 11 soldiers fell against 4. The bell now carries the lord's rally 10 % further (322b6f7), and a guard
  in the test fails any work that lets more than two more soldiers fall, or costs a night, on those hard nights. Its
  shots of all ten cards showed four faces that did not read at phone size (the limeburner, the weaver and the lamp-maker
  monotone under a cap or hood of their clothes' colour, the ironwright a man's face): fixed.
- **lh-c1-5** (322b6f7: build, CraftTests, every card in English) ALL PASSED. On hard nights the bell now moves nothing
  measurable (fallen 4/4, walls 7/7); the glass saves soldiers and walls (fallen 2 against 4, walls lost 4 against 7);
  the rest show nothing. The four faces read.
- **lh-c1-6** (4c1267e, full: build, unit, ui, ui-de, release) **ALL PASSED** on the step's final code: every unit test
  (T1 to T8 unchanged, the neutrality test, the effect sizes and the hard-night guard), every UI test in English and
  German with CraftUITests' 15 shots per language, the Release build. Upright copies of every craft shot of this round:
  `ci-out/upright-craft-1/` in the lane's worktree (60-craft-offer, 60b-craft-counsel, 60c-craft-again,
  60d-craft-longest, 61-craft-commissioned, 62-craft-<id> for all ten, each in en and de).

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
- **Faces:** the composed portraits read, but the limeburner and the lamp-maker are both fair young men; each craftsman
  gets his own portrait with the art list.
- **Evidence for the small night works:** the mortar, the banners, the pitch and the gate bands move nothing measurable
  even on the hard nights of the test (the walls that fall there are not patched in time, the guards rarely hold); a
  measurement on night 20 without the beacon (T6's hard night) would show them, at the cost of nineteen nights a run.

### The art list for the join

Each craftsman's sprite starts from an existing body (townsfolk layout: walk 0-3, idle 4-5) and gets his trade's
silhouette; the portrait is composed today and may get its own 48x48 frame.

| craftsman | start from | what makes him or her |
|---|---|---|
| Dagmar Flint (mason) | `citizen` | old woman, long grey hair tied back, leather apron, a mallet and chisel at the belt, palms and sleeves grey with stone dust |
| Severin Quell (painter) | `petitionerE` | a noble of the inner lands (BARS.md section 3): upright, slow, clean, the only saturated plum and gold thread among the craftsmen, feather cap, moustache, a scented cloth at the nose; a servant boy carries his easel and paint box (he carries nothing himself) |
| Benedek Rook (bell-founder) | `builder` | broad, bald, full beard, leather apron, forearms shiny with old burns, a small hand bell on a cord; leans in to hear (half deaf, as founders are) |
| Merle Tidewell (glazier) | `petitionerD` | young, red braids, teal tunic, a crate of panes on her back, a blowpipe; a hand to the mouth (the glazier's cough) |
| Cuno Marl (limeburner) | `citizenC` | round, wool cap, smock white with lime, bare hands with knuckles cracked white, a trowel and a sack |
| Tekla Morrow (weaver) | `petitionerD` | tall, headscarf, blue dress with apron, a bolt of teal cloth on the shoulder, fingers dyed teal |
| Joost Felloe (wheelwright) | `builder` | stocky, wool cap, short beard, a spoked wheel rolled at his side, nine fingers |
| Ivar Glimm (lamp-maker) | `petitionerE` | older, grey short beard, a hood, a pole hung with three small lanterns (unlit by day), thumbs black from wicks; a child of Tallowford come home |
| Renske Fallow (fletcher) | `citizen` | young, curly hair, a cap with a long feather, a quiver of black-tipped arrows, fingers black with pitch |
| Ottilie Brand (ironwright) | `citizen` | square-faced, hair in a bun, leather apron, an iron band over the shoulder, a gilder's book, the right arm much thicker than the left |

| work | where in the rebuilt world | how it shows |
|---|---|---|
| the statue (mason) | the town's market square, away from the saint's statue (`town.statue`) and the well, facing the castle | a stone lord with the lantern on its hooked staff raised; lit by a lamp at night |
| the portrait (painter) | the great hall's wall beside the throne, the first frame of a row of empty frames (the gallery to come) | a framed portrait of the chosen lord or lady (two frames: Burgherr, Burgherrin) |
| the bell (founder) | the gate tower over the gatehouse | a bronze bell in an open belfry; it swings at dusk (the horn's partner, a sound) and when a wall falls (not House Lorn's old bell, which is a story beat of its own) |
| the glass (glazier) | every brazier and fire tower in the Throat | glass hoods on the bowls; a clearer flame and a glint by day |
| the mortar (limeburner) | the wall walks of the three lines and the gatehouse | tubs with trowels standing in them; a patch shows fresh pale mortar |
| the banners (weaver) | the gatehouse and the line walls, on the castle side | long teal banners with the gold lantern that move in the wind |
| the handcarts (wheelwright) | the builders' lodge; the builders push them to the jobs | two small teal carts with stone |
| the road lanterns (lamp-maker) | the town's street lanterns (TOWN.md section 7: about four, lit by the lamplighter) carried on past the last house to the fields and the ford | about six more lantern posts; the lamplighter's evening walk goes on to the ford and back, and the last post burns at the horn |
| the pitch arrows (fletcher) | a rack by the barracks | black-tipped arrows; a fire arrow's strike flares a little brighter |
| the gate bands (ironwright) | the gatehouse's gate (every tier) | iron bands across the gate, a small gilt lantern where they cross |

## Step craft-1, fix round 1: every work felt, every craftsman a person (14.11.2026)

The independent critic's look 1 (`ci-out/director/craft-1-craftsmen-critic1.md` on the planning branch: 7/10, no
blocker, five highs). All five highs are fixed; the smaller findings too, except those it marked for the join.

### What changed

- **Every work moves its own number by about 4 %** (high 1). The 5 % rule is a ceiling; nought is a placebo. A whole run
  of the reference bot hides a work of 4 % (its nights are comfortable), so the seven works that act by night or on
  the builders are measured in a scene of play that isolates what they change, `Tests/CraftMeasures.swift`, played by
  the real simulation through the lane's hooks:

  | work | scene | its own number | amount (was) | moved |
  |---|---|---|---|---|
  | handcarts | three mornings' orders (middle line, gate, castle, town) from a fresh realm on day 4 | seconds until every job stands | builders 8 % faster (10 %) | −3.7 % |
  | bell | the lord walks from the courtyard to the outer line and back by night, archers on all three lines | soldier-seconds within the rally | reach +4 %, 83 px (+10 %) | +4.1 % |
  | glass | both braziers of the gate and the middle line | ground lit at a sootling's height | +5 % (+5 %) | +3.7 % |
  | mortar | the lord patches the gate at a quarter | wall strength one patch restores | 26 % (30 %) | +4.0 % |
  | banners | an ash brute at a breach held by two, three and four guards | seconds the breach holds | steps back at 25 % (25 %) | +4.1 % |
  | pitch | a fight at the gate, braziers lit, 24 sootlings and 4 hounds | what a fire arrow strikes for | strikes 4 % harder (fire +1 s) | +4.0 % |
  | gate bands | four ash brutes at the gate, no soldiers | seconds the gate holds | +4 % (+5 %) | +4.0 % |

  The statue (+4.4 % taxes), the road lanterns (+2.6 % taxes, high-tax bot) and the portrait (+2.6 % happiness) stay
  measured in the bots' runs. `CraftTests.testNoWorkMovesItsSystemMoreThanAboutFivePercent` asserts 2 % to 6 % for all
  ten, that no work costs the reference bot a night, and the hard-night guard (no night work costs a night or lets more
  than two more soldiers fall). `testEachWorksSceneAtOtherAmounts` reports each scene at amounts around the book's.
- **The pitch strikes harder instead of burning longer.** Round lh-c1f1-1 measured why the longer fire moved nothing: a
  fire arrow lands on the front-most lit creature, so its fire lies where light already is, and lights do not add up
  (in a fight before the gate lit only by the lord's lantern, of 44 points of burning under fire-arrow fire 0.3 lay
  where no other light reached, with or without the pitch). Its strike is real damage: `Balance.fireArrowStrike`
  (1 without the work) through one hook in `Battle.stepSoldiers`.
- **The painter is a master of the inner lands** (high 2): Severin Quell of a Stillmere syndic family, long polite
  sentences that say little, a scented cloth; his first offer follows the realm's stage (`craftsmen.json`
  `stageLines`, `CraftText.spoken`, the hook in `AudienceCard.make`): `craft.painter.text_hamlet` (beneath him),
  `craft.painter.text` (a village), `craft.painter.text_town` (a client worth having). `CraftStage.of` reads happiness
  until the town lane's standing joins (below 70 a hamlet, from 80 a town; `testThePainterSpeaksToTheRealmsStage`).
  `-GWCraftStage hamlet|village|town` sets the sample realm's stage.
- **A mark of life in every craftsman's words** (high 2), in `r1` or `text`: the mason's palms grey with dust, the
  painter's scented cloth, the founder's burnt forearms (and his half-deaf "not now"), the glazier's cough, the
  limeburner's cracked knuckles, the weaver's dyed fingers, the wheelwright's nine fingers, the lamp-maker's blackened
  thumbs, the fletcher's pitch, the ironwright's hammer arm.
- **No template** (high 3): every "not now" has its own shape (a chalk mark, polite nothing, a hand to the ear, a
  question, silence, an aphorism, a wheel that agrees, a mother's house, a feather, a bargain); no return line opens
  with "Back" and no two share an opener; no commission reaction opens with "By/From tomorrow".
- **The lamp-maker** (high 4) carries the lamplighter's street lanterns on past the last house to the fields and the
  ford (TOWN.md section 7); "Home again" stays, and his mother now asks why the fields are dark.
- **Canon** (high 5): the painter's return speaks of the light in the hall, never down to the heir; the bell-founder
  comes from Brazenmoor (an original foundry town), so House Lorn of Greybell keeps the hall's first bell and its beat;
  the Lorn petition does not mention him.
- **Smaller findings:** the lamp-maker's face is older with a grey short beard (no longer the limeburner's twin); the
  mason's grey bun became long grey hair (the bun read as a cap); Odile's fletcher counsel is dry ("Brannock will be
  unbearable about it for a week"); "pole" became "lantern staff" (German "Laternenstab"); Stillmere paints syndics in
  chains of office.

### Hooks added in this round (also in the hook table above)

- `Core/Audience.swift`, `AudienceCard.make`: `textKey: CraftText.spoken(petition.text, state: state)`.
- `Core/Balance.swift`: `var fireArrowStrike = 1.0` after `fireArrowSeconds`.
- `Core/Battle.swift`, `stepSoldiers`: `let shot = fire ? damage * balance.fireArrowStrike : damage`, used for the
  projectile's damage and `incoming`. With 1 the product is the same number, so every run stays line for line (the
  neutrality test).

### Rounds

- **lh-c1f1-1** (8a69132: build, CraftTests): build PASS; unit FAIL on one number: the pitch, then half a second more
  fire, moved fire-arrow damage counted with its fire by 8.1 %, and the same scene showed that the fire lay where light
  already was (see above), so the pitch became a harder strike. Every other work
  landed where the scenes predicted (handcarts 3.7 %, bell 4.1 %, glass 3.7 %, mortar 4.0 %, banners 4.1 %, gate
  4.0 %); the neutrality test, the save, the visits and the words passed; the hard nights held 28/28 for every work.
