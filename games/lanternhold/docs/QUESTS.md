# Lanternhold: the Lantern Table (quests on the realm map)

Design, 10.11.2026. Louis asked for it in chat: the realm map (`docs/karte.html`, "Karte der Morgenlande")
should come into the game, with story quests one can do there. This file says how, concretely enough
to build. It changes no code and no other document.

Read with it: `STORY.md` (branch `claude/lh-story`), `docs/REVIEW-game.md` (`claude/lh-review`), the
houses' audiences and flags (`claude/lh-storypass`), look 2 (`claude/lh-port`), `DESIGN.md`.

Words used here: a **sending** is one quest (German: **Aussendung**). The game itself never says
"quest" or "mission". It counts lanterns: "Lantern 39 is out", "Lantern 39 is home".

## 1. The concept in five sentences

**The Lantern Table** (German: **Der Laternentisch**).

1. In the chapel's west bay stands a carved table of the Morninglands, and above it hang the road
   lanterns of the Count, each with its number on a hook.
2. To send someone out, the lord takes a lantern from its hook and gives it to the party: riders
   from the wall's own garrison, a scout, an envoy, or one of the court; whoever goes is missing from
   the castle until the lantern is home.
3. The party leaves through the gate where the player can see it go, its wooden token stands on the
   table for the nights it is away, and at a dawn it is counted back in and reports at the table with
   a card and a choice.
4. A lantern that does not come home leaves its hook empty for the rest of the chapter and one keep
   window dark, so the lord has one sending fewer from then on and sees why every time the chapel is
   crossed.
5. The table's western third is bare planed wood (Lord Edric the Shut had the west cut away in the
   Dark Year); what scouts see from the Great Beacon is scratched into it, and filling that bare wood
   is the road into chapters 2 and 3.

Why this is the game's own: the unit is not a roster of agents but a **numbered lantern from the
Count**, which `STORY.md` already has ("everyone who goes out past the gate carries a numbered
lantern"); the price is **bows missing from tonight's wall**, which ties the map to the night the
player already fears; and the result is **seen in the walked castle** (the empty hook, the dark
window, the riders at the gate), not only on a map screen.

## 2. How a sending works

### 2.1 The lanterns

- Chapter 1 has **three road lanterns**, numbers **38, 39 and 40**, on a rail of four hooks. So at
  most three sendings are out at once. (The wall's own lanterns, one per soldier, hang at the
  gatehouse, as review change 9 proposes. Road lanterns hang in the chapel, where `STORY.md` puts the
  empty hooks.)
- The fourth hook holds **lantern 41**. It goes out only once, on day 18, with Hild Varn
  (`varn_ride`, whose text already says "Lantern forty-one goes out through the gate at dusk"). See
  sending 13.
- A lantern that is lost is gone for the chapter: empty hook, `castle.keep.window.dark` set,
  happiness -2 at that dawn. Chapter 2 starts with the hooks that are left plus one new one.
- The numbers are data. Reports use a `{lantern}` placeholder written in digits ("Lantern 39"), so
  no number words need translating.

### 2.2 Who can be sent

| Who | What it costs to send them | Chapter 1 |
| --- | --- | --- |
| **Riders** (1 or 2 soldiers from the garrison) | `archers` or `guards` go down at once and come back at the return dawn; they do not stand on the wall those nights | the houses, the mill |
| **Scout** (1 or 2 archers on foot) | as riders; west only | Beaconfoot, the Great Beacon |
| **Envoy** (a named guest who is at court: Hild Varn, Ansel Quay, Finch, Ser Ludo) | no soldier; needs the guest's flag (`ludo_stays`, `envoy_met` and so on) | Saltgate, the mill, the beacon |
| **Court** (Pip, Marek) | their service is missing while away: no court line from Pip, no trade at Marek's cart | Tallowford, Goldenacre |
| **Builders, bearers** | `builders -1` or `citizens -n` until the return | the old bridge, Greybell |

Odile, Brannock, Hesper, Tamsin, Bram and Seren stay in chapter 1. Odile is the counsel and the
reference bot's policy; Brannock holds the wall ("That pole. No."). Sending them is a chapter 2
subject.

### 2.3 Where, how long, what it costs

- **Where:** eleven carved places (section 3.1). The table is not to scale: the valley has the middle
  third, the Morninglands the east, the bare wood the west.
- **How long:** counted in **nights away**. The party leaves when it is sent (any time from 06:00 to
  18:00) and returns at a dawn. The valley and the beacon take 1 night; Highcairn 2; Saltgate and
  Greybell 3; Stillmere 3 (to the first Calder post and back); Goldenacre 4. `karte.html` gives the
  ride in days one way; the table's number is the rule of the game, and the table says why in one
  line on its east edge: "Riders change horses at the lamp posts."
- **Costs,** shown as the audience card's effect chips before the lord sends:
  - one **lantern** (always);
  - **people** for the nights away (soldiers, a builder, bearers, or a court member's service);
  - **gold** for the road, 0 to 30;
  - the **nights** themselves: the hook is taken until the return.
- A sending needs a lantern on the hook, the gold, and the people. If one is missing the Send button
  is grey and the missing chip is red, as on the audience card.

### 2.4 Orders

Most sendings have one order ("Send"). Some have **two orders**, which are two ways to do the same
errand: what the party carries, or how far it dares to go. An order sets cost, nights and risk. The
player sees the risk before sending, as plain words on a chip:

| Chip | English / German | Chance the lantern is lost |
| --- | --- | --- |
| none | (no chip) | 0 |
| amber | "Dark road" / "Dunkler Weg" | 0.10 to 0.15 |
| red | "Few come back" / "Wenige kehren heim" | 0.25 to 0.30 |

### 2.5 The return

- **At dawn.** The dawn report gets one row: "Lanterns home: 39 (Highcairn)" or "Did not come home:
  40". Soldiers, builders and bearers are back in the realm's numbers at that same dawn, whether or
  not the lord reads the report.
- **At the table.** The returned party stands by the table with its lantern. The realm strip's table
  marker shows a dot. The lord walks there; the action button shows a scroll; the **report card**
  opens. It is the audience card with the speaker's portrait, a text of up to 240 characters, and
  **two or three choices on return** with effect chips. One choice is always free.
- **Reports wait.** A report is not a petitioner: it does not stand in the audience queue, does not
  expire at the horn and costs no happiness when unread. Reports are read first; the table shows new
  sendings only when no report waits.
- **A lost lantern** reports too: Brannock stands at the rail and says it in one line ("Forty did
  not come home."). The card has two choices, both free: leave the hook empty and say the names at
  the Flame (`mourning_kept`), or have Bram hang a blank lantern there so the hall does not see
  (`hook_hidden`; an honest-lamp realm loses that leaning's line in the finale).

### 2.6 What a sending brings

In this order of weight. Numbers are small on purpose (section 4.4).

1. **Story beats and hints.** Every report holds one thing seen, in the story's rule ("hints are
   things seen"): sixty statues where forty lords ruled, a grey lantern with hinges on the wrong
   side, chalk numbers on the beacon's west door.
2. **The houses' standing.** Each house has one new flag `<house>_road` ("one of ours has stood in
   their hall"). The finale's second panel names the roads; chapter 2 turns them into tithe, soldiers
   and doors, as `STORY.md` section 5 says.
3. **World changes** in the walked world and on the table: lanterns in Tallowford's lanes, the span
   on the old bridge, the first bell in the chapel, scratches on the bare wood.
4. **People and gold,** modest and early: the second half of Varn's levy, three keepers' people from
   the caves, a toll.
5. **The night:** a scout's warning thins one night's wave (existing `night` effect), days 4 to 14
   only.

### 2.7 Risks

- **The wall is thinner.** Lent soldiers are not on the wall. This is the main risk and it needs no
  dice.
- **The hook.** Three lanterns for thirteen sendings: every sending blocks another.
- **Loss.** Only on orders with a chip. On a loss the soldiers do not come back either.
- **Late.** Some "Dark road" orders come home one dawn late instead of being lost (stated per
  sending).
- **Never:** a sending cannot lock the chapter, cannot lose a named person except by the player's
  own order on a red chip, and nothing is fought on the map.

## 3. The sendings of chapter 1

### 3.1 The carved places

Names are the map's (`karte.html`). Proper names stay as they are in every language.

| Place | What it is | Nights | Kind |
| --- | --- | --- | --- |
| Lanternhold | home; the hook rail is drawn above it | | |
| Tallowford | the town under the castle (the walked town) | 1 | valley |
| The Old Bridge (Die alte Brücke) | stumps and a ford over the Wend | 2 | valley |
| The Windmill (Die Windmühle) | old Hemmet, one of the Returned | 1 | valley |
| Highcairn | House Varn, north | 2 | house |
| Saltgate | House Brine, the south coast | 3 | house |
| Greybell | House Lorn, east | 3 (2 with the span) | house |
| Stillmere | House Calder; riders go to its first post | 3 | house |
| Goldenacre | House Oxmoor, far south-east | 4 (3 with the span) | house |
| Beaconfoot | the keepers' village under the dark beacon | 1 | west |
| The Great Beacon (Das Große Leuchtfeuer) | the tower at the Throat's mouth | 1 | west |
| (bare wood) | the Moor Road, the dead moor, the shadow land | | chapters 2 and 3 |

As Louis decided, chapter 1 goes as far as the beacon tower and the view. Nobody is sent past it at
the table. The one lantern that passes it is Hild's, by her own asking (sending 13).

### 3.2 The list

"Seal" means Odile's counsel seal (section 4.3). Costs and numbers are first values for the tuning
pass. Hooks are the two lines on the table's slip; German follows the same lines.

**1. Oil for the Round / Öl für die Runde** (`oil_round`), valley, the table's first lesson
- Tallowford. Days 2 to 6. Pip with the handcart. 1 night. 5 gold. No risk. Seal.
- Hook: "The chandlers' row has pressed the first oil of the year. / Pip can have a cartload at the
  gate by dawn."
- Return (Pip): "Hang them in the lanes." world `town.lanterns.extra`, happiness +1 (counsel) or
  "Keep it for the wall." night `sootlings-2`.

**2. Herbs from the Mill / Kräuter von der Mühle** (`mill_herbs`), valley
- The Windmill. Days 6 to 12. One guard with Tamsin's basket. 1 night. No gold. No risk. Seal.
- Hook: "Old Hemmet grows grey sage against the ash cough behind the mill. / Tamsin has a basket and
  no legs to spare."
- Return (the guard): "Plant them by the kitchen." flags `herbs_grown` (the existing flag that keeps
  `ash_cough` away) and `hemmet_met`, world `town.garden` (counsel) or "Dry them for the wall's
  sick." `hemmet_met`, happiness +1.

**3. Planks on the Stumps / Planken auf die Stümpfe** (`ford_planks`), valley
- The Old Bridge. Days 9 to 14. One builder and one guard. 2 nights. 12 gold. No risk. No seal.
- Hook: "The ford over the Wend takes a cart every spring. / The old bridge's stumps still stand.
  They want planks."
- At the return dawn: flag `ford_bridged`; the table shows the span; Greybell and Goldenacre take one
  night less. Return (the builder): "Open it to all." happiness +2 or "Set a toll post." gold +15,
  happiness -1.

**4. Hemmet's Sentence / Hemmets Satz** (`hemmet_sentence`), valley, closes the mill's arc
- The Windmill. Days 10 to 16. Needs Finch at court (`bard_song` heard) and `hemmet_met`. Finch
  walks. 1 night. 4 gold. No risk. No seal.
- Hook: "Finch has eleven sentences of the Returned and wants the twelfth. / Hemmet at the mill has
  said one thing for forty years."
- Return (Finch): the sentence ("The washing was still on the line."), flag `sentence_hemmet`; "Sing
  it in the hall." happiness +2, `song_sung` or "Write it in the family book." `sentence_filed`.
- If the cough came (`refugees_in`, no `herbs_grown`) and Finch returns on day 17 or later, he finds
  the sails tied: flag `hemmet_gone`, world `town.window.dark`, and the card has one line less.

**5. The Count for Highcairn / Die Zählung für Highcairn** (`highcairn_count`), house, story
- Highcairn. Days 5 to 11, after `varn_levy` (days 3 to 4). Needs `varn_with`. One archer and one
  guard ride. 2 nights. 8 gold. No risk.
- Hook: "Hild Varn said it: the other half when the new lord has shown he can count. / Send
  Highcairn the Count. Lanterns out, lanterns home."
- Orders: "Carry the true count." (seal) or "Carry a rounded count." (flag `count_rounded`).
- Return (a rider, with Lord Harrow's answer), flag `varn_road`. True count: "Take the second half of
  the levy." archers +2 or "Leave the bows. Ask for Hild's word." `varn_vouch`, happiness +1.
  Rounded count: Harrow counted the lanterns on the saddles himself: "Take what he sends." archers +1
  or "Send the true count after it." gold -8, `-count_rounded`, `varn_vouch`.

**6. Marek's Cart to Goldenacre / Mareks Karren nach Goldenacre** (`goldenacre_cart`), house, story
- Goldenacre. Days 7 to 13, after `oxmoor_gift` (days 5 to 6), whatever the answer was. Marek goes;
  no trade at his cart meanwhile. 4 nights (3 with the span). No risk. No seal.
- Hook: "Marek carries Pell's letters east every month and reads them at the ford. / Send him with
  ours and he will read theirs."
- Orders: "Pay the loan back." gold -30, needs `oxmoor_debt`, clears it, sets `oxmoor_square`; or
  "Carry the lamp tithe list." gold -5.
- Return (Marek): flags `oxmoor_road` and `pell_read` (his warning on day 16 becomes certain). "Read
  Pell's letter aloud in the hall." happiness +1, `pell_shamed` or "Lock it in the family book."
  `pell_filed`.

**7. The Grey Lanterns / Die grauen Laternen** (`saltgate_grey`), house
- Saltgate. Days 10 to 15. Needs `envoy_met`. Ansel Quay rides home with one archer. 3 nights.
  10 gold for oil. "Dark road": 0.15 that they come home one dawn late; never lost. No seal.
- Hook: "Grey lanterns wash ashore at Saltgate, more with each tide. / Ansel Quay will show one of
  ours where."
- Return (the archer, with one grey lantern for Bram's shelf: hinges on the wrong side): flags
  `brine_road`, `grey_lantern`. "Promise the coast shelter behind the wall." `coast_promise`,
  `brine_with` (as `envoy_tide` choice 1) or "Promise nothing. Send oil money." gold -10,
  `coast_helped`.

**8. Proof for Stillmere / Beweis für Stillmere** (`stillmere_proof`), house, story
- Stillmere's first post. Days 13 to 15, after `calder_audit` (days 12 to 13). Needs `calder_with`
  or `calder_coddled`. One archer with Ebba Calder's sealed report. 3 nights. 6 gold. No risk. No
  seal.
- Hook: "Ebba Calder stood the night and wrote it down: sixty statues, forty lords. / Stillmere pays
  for proof in one of its own hands."
- Orders: "Send it as she wrote it." flag `statues_sixty` (the Chronicle names it) or "Strike the
  statues from it." gold +20 at the return, flag `statues_struck`.
- Return (the archer, with Stillmere's answer): flag `calder_road`. "Hang the answer in the hall."
  happiness +1 or "Burn it." `calder_answer_burnt`.

**9. The First Bell / Die erste Glocke** (`greybell_bell`), house, story, the chapter's late gamble
- Greybell. Days 15 to 16, after `lorn_visit` (days 14 to 15). Needs `lorn_heard`. One guard and two
  bearers (citizens -2 until the return). 3 nights (2 with the span), so home on day 17 to 19. No
  gold. No risk on the road; the risk is the wall. No seal: Odile says "After the twentieth night."
- Hook: "Greybell keeps the hall's first bell. Lord Edric sent it away because it rang by itself. /
  Dame Orla says it is time it came home."
- At the return dawn: world `castle.chapel.bell.first` (new id), flag `lorn_road`; Lorn's lamp-runner
  comes with it. Return: "Hang it. Let it ring." happiness +3, `bell_rings` or "Hang it and tie the
  clapper." `bell_tied`. What the bell does on night 20 is the story lane's to write.

**10. Smoke at Beaconfoot / Rauch bei Beaconfoot** (`beaconfoot_smoke`), west, story
- Beaconfoot. Days 8 to 11, before `refugees_gate` (days 13 to 14). 1 night. 4 gold for bread.
- Hook: "The watch saw smoke under the dark beacon, where the keepers' people lived. / Somebody is
  still cooking there."
- Orders: "Look from the road." one archer, no risk (seal); or "Go into the caves." two archers,
  "Dark road" 0.10.
- Return (the scout). From the road: a cold fire, tracks of six or seven, flag `beaconfoot_seen`;
  "Tell the gate to expect them." happiness +1 or "Say nothing yet." From the caves: three of the
  keepers' people; "Bring them inside the wall." citizens +3, `beaconfoot_found` or "Leave them
  bread. They will not come." gold -4, `beaconfoot_fed`.

**11. Count the Statues / Zählt die Statuen** (`beacon_statues`), west, story, the shadow land's first look
- The Great Beacon. Days 11 to 16, after `beacon_plans` (unlock `beacon`). One archer. 1 night. No
  gold.
- Hook: "From the beacon's stair one sees the Moor Road and the stone lords along it. / Nobody has
  counted them since the Dark Year."
- Orders: "Watch from the stair." no risk (seal) or "Climb to the lamp room." "Few come back" 0.25.
- At the return dawn: the first scratch on the bare wood (`table.west.1`: the road, sixty statues,
  one empty plinth), flag `statues_counted`. From the lamp room also `table.west.2` (the moor's edge
  and one low light; the story lane signs off what is seen). Return (the scout): "Tell the wall what
  moves on the road." night `brutes-2` (to day 14; after that happiness +1) or "Tell the hall what
  stands on the road." happiness +1, `statues_told`.

**12. Ludo's Number / Ludos Nummer** (`ludo_number`), west
- The Great Beacon. Days 12 to 15. Needs `ludo_stays` and `table.west.1`. 1 night. No gold. No seal.
- Hook: "Ser Ludo's knight rode west ten years ago under a numbered lantern. / The keepers chalked
  every number on the beacon's door."
- Orders: "Go with a scout." Ser Ludo and one archer, no risk; or "Go alone, as he asks." "Few come
  back" 0.25, and if he is home: flag `ludo_alone`, his one true deed.
- Return (Ser Ludo): his knight's number stands on the west door and is not struck through, flag
  `ludo_number`. "Knight him at the hearth." guards +1, `ludo_knighted` or "Give him the number to
  keep." happiness +1.

**13. Lantern Forty-One / Laterne einundvierzig** (`lantern_41`), west, story, the chapter's open end
- Past the Great Beacon. Day 18. Not offered at the table: it is `varn_ride` choice 3 (`hild_rode`),
  shown on the table. Hild Varn and two riders under lantern 41.
- Hook (the petition's own words): "Give me two riders and a numbered lantern. / I will ride out
  past the dark beacon tonight and find him."
- It does not come home in chapter 1. Its token stands on the bare wood at the table's west edge,
  hook 41 is empty in the finale's picture, and chapter 2 opens on that hook. No new effects.

### 3.3 How it sits on the day plan

| Days | `STORY.md` beat | What the table shows |
| --- | --- | --- |
| 2 | `tower_request` | the table is uncovered; 1 opens (Pip points at it in his court line) |
| 3 to 6 | `varn_levy`, `stranger_gate`, `oxmoor_gift` | 5, then 2 |
| 7 to 10 | first ash brutes, `war_tax`, `bard_song`, `envoy_coast`, the Ash Giant | 6, 10, 3, 4, 7 |
| 11 to 14 | `beacon_plans`, `calder_audit`, `refugees_gate` | 11, 12, 8 |
| 15 to 16 | `lorn_visit`, `seren_reveal`, `tithe_letters` | 9; each `<house>_road` flag is named when the banners are hung |
| 17 to 20 | the herald, `varn_ride`, the last stand | 13; nothing new opens, lanterns come home |

Days 9 to 15 offer eight sendings for three hooks. That is meant: it is the part of the chapter the
review calls soft, and the choice of which lantern goes where is its new question.

Kept for chapters 2 and 3 (not built now): walking the Moor Road, the dead moor, Saltgate's
lighthouse and its washed-up lanterns, Greybell's door, Stillmere's tithes "to the lord beyond",
sending Odile or Brannock.

## 4. Fit with the simulation

The rule that carries everything: **a realm that never touches the table plays exactly as it does
today.** The reference bot never touches it.

### 4.1 Data and engine

- `Resources/Errands/errands-ch1.json`, `Core/ErrandData.swift` (`Errand`, `ErrandOrder`),
  `Core/ErrandEngine.swift`. State: `GameState.table: TableState?`, optional, so old saves decode
  and `SaveGameTests`' frozen save stays green.
- **Reports are petitions.** `Resources/Petitions/petitions-table.json`, with a new `kind: "report"`
  that the audience queue never draws. Same struct, same card, same validator limits (text 240,
  choice 40, reaction 140), same keys in `Story.xcstrings` (`petition.<id>.*`). Their choices use
  only the existing effect types: `gold`, `happiness`, `citizens`, `archers`, `guards`, `flags`,
  `world`, `night`. Reports never use `chance`, `schedule` or `unlock` (validator).
- An errand, as data:

```json
{ "id": "highcairn_count", "place": "highcairn", "chapter": 1, "days": [5, 11],
  "requires": ["varn_with"], "speaker": "soldier",
  "orders": [
    { "seal": true,  "nights": 2, "cost": { "gold": -8 }, "lend": { "archers": 1, "guards": 1 },
      "risk": 0, "report": "highcairn_true" },
    { "seal": false, "nights": 2, "cost": { "gold": -8, "flags": ["count_rounded"] },
      "lend": { "archers": 1, "guards": 1 }, "risk": 0, "report": "highcairn_rounded" } ],
  "atReturn": { "flags": ["varn_road"] } }
```

- `cost` and `atReturn` are ordinary effect blocks. `lend` is taken at the sending and given back by
  the engine at the return dawn (not on a loss). The soldiers lent are the newest recruits, so who
  leaves the wall is fixed.
- Optional fields: `nightsWith` (`{"ford_bridged": 3}`), `late` (a "Dark road" order that comes one
  dawn late instead of being lost), `lostReport`, `altReport` with a condition (sending 4).
- Text keys: `errand.<id>.title`, `.hook`, `.o1`, `.o2`; `place.<id>.name`.

### 4.2 Deterministic and seeded

- The risk is rolled **when the lantern is sent**, from a stream of its own:
  `errandSeed(seed, errandId, orderIndex)`, built like `queueSeed(seed, day)`. The result (home day,
  home or lost) is stored in `TableState.out`, so a reload cannot reroll it.
- The engine never draws from `GameState.rng`. The nights of a seed are the same with or without
  lanterns out, except for the soldiers who are really missing.
- **Returns** run in the dawn step, after the night is accounted and before the dawn report is
  built and the game saves: give back what was lent, hang the lantern or mark the hook empty (then
  `castle.keep.window.dark`, happiness -2), apply `atReturn`, add the report to
  `TableState.reports`. No use of the petition queue's `schedule`, so the day's petitioners and
  `onTop` stay untouched.
- **Offers:** an errand is on the table when the day is in `days`, `requires` and `forbids` hold
  (the petitions' flag logic) and it has not been sent. An errand whose window closes is gone.
- Sendings are possible from 06:00 to 18:00. Nothing leaves or returns during a night.

### 4.3 The bots

- **Reference bot:** unchanged, never walks to the table. New test `TableNeutralityTests`: for the
  tuning seeds, the state at every dawn is equal with and without the errand files loaded, and the
  bot's path is bit for bit what round `lh-m3-j3` measured.
- **Sender bot** (new policy `sender` in `tools/simtune`): each day after the audience it reads the
  waiting reports with their counsel choice, then sends every offered order that carries **Odile's
  seal** and that it can pay, lowest id first.
- **Odile's seal** is the table's counsel. The validator and the engine hold it to the rules the
  counsel already has (`STORY.md` 9.4):
  - a sealed order has risk 0 and lends at most two soldiers;
  - sealed orders never have more than two soldiers out on the same night (the engine withholds the
    seal on the day it would);
  - its nights away never include night 7, 10 or 17 to 20;
  - its report's counsel choice changes the night only on days 4 to 14 and gives no people or gold
    after day 14.
  - Sealed in chapter 1: 1, 2, 5 (true count), 10 (from the road), 11 (from the stair).
- **Greedy bot** (policy `greedy`): sends whatever it can pay, red chips too, always the second
  order. It exists to prove that sending everything is not the best way to play.

### 4.4 The targets, and what to measure

| Target | Reference bot | Sender bot | Greedy bot |
| --- | --- | --- | --- |
| T1 nights 1 to 10, hearth untouched | as measured | must hold (sealed parties are out on nights 5, 6, 8, 9, 11 and 12 at most) | reported |
| T2 no-build realm falls night 2 to 3 | as measured (run it with the errand files loaded) | | |
| T3 beacon by day 18 | day 16 to 17 | within one day of the reference, never past 18 | reported |
| T4 high-tax realm under 30 | 27 | not above the reference | |
| T5 buildings by day 10 in 8 to 12 | 11 | in the band (the builder is lent from day 9, unsealed) | reported |
| T6 with beacon / without | 20 of 20 / 10 of 20 | 20 of 20 / inside 30 to 60 % | without beacon: at or below the reference |
| T7 | 17 of 20 | not below the reference's bar | reported |
| T8 last wave by 03:00, sprites, lights | as measured | at most 4 sprites more (a party at the gate); the table screen under 60 images | |
| **T10** the table is a trade (new) | | at dusk of day 20, median of 20 seeds against the reference: gold within 25, soldiers within 2, happiness within 3 | |
| **T11** the hook matters (new) | | all three lanterns out on at least 3 of the days 9 to 15 | at least 2 offered sendings stay unsent for want of a hook |

- If a target fails, change the sendings' values (cost, nights, the days window, a report's
  effects, the seal), never `Balance` and never an existing petition.
- First values to watch: the two archers of sending 5 and the three people of sending 10 are the
  only people the sealed path gives; both arrive by day 13.

### 4.5 What it touches in the game

- New: the errand files and engine, `TableState`, `Overlay.table`, `KingTarget.table`, one row in
  the dawn report, one marker on the realm strip, the validator's errand rules.
- Extended lists: `CourtWorld` (`castle.chapel.bell.first`, `table.west.1`, `table.west.2`,
  `table.span`), `Remembered` (the five `<house>_road` flags, `statues_sixty`, `bell_rings`,
  `ludo_knighted`, `hemmet_gone`).
- One new court line (Pip, day 2, points at the table). The rule of one court line a day holds.
- No existing petition's effects change. Sending 13 only reads `hild_rode` to draw token 41.

## 5. The interface

### 5.1 In the walked world

- **The table** stands in the chapel's west bay at about x 1980 (chapel 1960 to 2120; Seren's corner
  is 1950, the candles 2000, the pews 2012). The hall itself is full (lectern, throne and Odile lay
  within 16 px before fix U2). Check the spot against `Balance.kingReach` in round 2; if it crowds
  Seren's corner, the candles move to 2006 and the table to 1986.
- **The hook rail** hangs on the wall above it: four hooks, each with a lit lantern, no lantern
  (out), or a bare hook with a chalk stroke (lost).
- `KingTarget.table`. The action button shows a **lantern on a hook**, or a **scroll** when a report
  waits. The realm strip gets a lantern pip; a dot on it means a report waits or a sending opened
  today. Tapping the pip walks the lord there, as the other markers do.
- Day 1 the table is under a cloth. On day 2 Pip pulls it off (his court line) and sending 1 opens.
- **Leaving:** when the table closes, the party walks from the chapel to the gate with a lit
  lantern: the back gate for the valley and the houses, the castle front for Beaconfoot and the
  beacon. **Coming home:** at dawn the party stands at the table; the lantern is on its hook once
  the report is read.

### 5.2 The table screen (`Overlay.table`)

The clock stops, as for every card. No ad is ever shown on it. Sizes for the iPhone 17 Pro
(874 x 402 pt, 2 pt per game pixel):

- **Left, to look at:** the table top, 300 x 150 game px (600 x 300 pt). Places are carved pins;
  open sendings glow; parties out stand as tokens at their place with one pip per night left.
- **Right, to touch:** a parchment column 226 pt wide, all of it inside the right thumb's reach.
  - Top: the hook rail, 44 pt high: 38, 39, 40, 41 with their state, and the line "Lanterns on the
    hook: 2 of 3".
  - Middle: the slips, one row per open sending, each 52 pt high: title, nights, cost chips, the
    seal. The column scrolls when more than four are open.
  - A tapped slip opens: the two-line hook, who goes, the chips, and one or two **order tiles**
    (52 pt high or more), labelled with the order's words.
  - Bottom right: "Back" / "Zurück", 88 x 52 pt.
- **Sending with one thumb:** tap a slip, tap an order tile. That is all. The lantern leaves its
  hook, the token stands on the table, and the slip shows "Call back" / "Zurückrufen" until the
  screen is closed, which undoes it at no cost. There is no dragging and no confirm dialog.
- **Pins** on the table top can be tapped too (hit boxes 22 x 22 game px, which is 44 pt; pins stand
  at least 24 px apart), but nothing needs them.
- **Reports first:** when a report waits, the screen opens straight on the report card.
- On narrower phones the column keeps at least 170 pt and rows keep 52 pt; the table top scales with
  the game's own pixel scale.

### 5.3 How a return is announced

1. The dawn report's row: "Lanterns home: 39 (Highcairn)" or "Did not come home: 40".
2. The dot on the realm strip's lantern pip.
3. The party standing at the table with its lantern.
4. A hook's clink and a light haptic at dawn when a lantern is home; for a lost lantern no sound and
   one long haptic.

Nothing pops up during the day and nothing interrupts a night.

### 5.4 Reduce Motion

The screen opens at once. Tokens are placed, not slid. Lanterns and pins do not flicker. The party
does not walk out: it is gone when the screen closes, and the gate shows its closed frame. The dot
is still. A scratch on the bare wood is simply there at dawn.

### 5.5 Text and German lengths

| Text | English limit | German (a third more) |
| --- | --- | --- |
| sending title | 28 | 38 |
| hook, two lines | 60 each | 80 each |
| order label | 40 | 52, wraps to two lines in the tile |
| risk chip | 14 | 18 |
| report card | as petitions: 240, 40, 140 | as petitions; the card scrolls, labels do not |

| English | German |
| --- | --- |
| The Lantern Table | Der Laternentisch |
| Lanterns on the hook: 2 of 3 | Laternen am Haken: 2 von 3 |
| Lantern 39 is out | Laterne 39 ist draußen |
| Lantern 39 is home | Laterne 39 ist heim |
| Lantern 40 did not come home | Laterne 40 kam nicht heim |
| 2 nights | 2 Nächte |
| Send | Aussenden |
| Call back | Zurückrufen |
| No lantern on the hook | Keine Laterne am Haken |
| Report | Bericht |

The longest German strings to shoot in the `ui-de` round: "Mareks Karren nach Goldenacre", "Die
Zählung für Highcairn", "Wenige kehren heim", "Laterne 40 kam nicht heim", "Keine Laterne am
Haken". The lord is addressed with "Ihr" and "Euch"; "Lantern" in "Lanternhold" is never
translated.

## 6. The art it needs

Pixel art in look 2, drawn fresh. Sizes in game pixels. One atlas page `table`, 512 x 512 at most.
The table is **not** the HTML page: no parchment sheet, no compass rose, no lettering. It is carved
oak seen from above, the Wend inlaid in banner teal, the places as brass pins, and a western third
of bare planed wood with the plane's marks. Place names are drawn by the interface as text, so they
are not baked into the art.

| Asset | Size | Notes |
| --- | --- | --- |
| Table top | 300 x 150 | the valley in the middle third, the Morninglands east, bare wood west; one carved line on the east edge |
| West scratches | 2 overlays, 96 x 150 each | knife lines: the Moor Road with sixty statues and one empty plinth; the moor's edge and one low light |
| The span | 16 x 8 | overlay on the old bridge's stumps |
| Place pins | 11 places, 9 x 9, dull and glowing | house pins in the house's colour |
| Tokens | lantern 7 x 11 (2 frames), rider 12 x 10, walker 8 x 10, cart 14 x 9, bearers with the bell 16 x 10, night pip 3 x 3 | carved wooden pieces, not figures |
| Hook rail for the screen | 113 x 22 | four hooks; lantern lit 7 x 11, bare hook 5 x 6, chalk stroke 5 x 6; digits 3 x 5 |
| Seal and chips | seal 9 x 9, chip icons 7 x 7 | Odile's wax seal in teal; amber and red |
| Table in the chapel | 24 x 14, and 24 x 14 under its cloth | side view |
| Hook rail in the chapel | 26 x 10, lantern states 3 x 5 | lit, out, lost |
| Carried road lantern | 5 x 7 | an overlay on the existing walk frames of archer, guard, Pip, Finch, Ser Ludo |
| The first bell | 10 x 12 | `castle.chapel.bell.first`, at x 2040 |
| Realm strip pip | 7 x 7, with and without dot | |
| Action button icons | 22 x 22 | lantern on a hook; scroll |
| Place vignettes for the report card | 11, 32 x 16 | optional; the first thing to cut |

- **Report cards** reuse the audience card. No new portrait: reports are spoken by speakers the game
  has (soldier, builder, Pip, Marek, Finch, Ser Ludo, Brannock, Lorn's lamp-runner).
- **Sound** (no music): hook clink, flint and flame, the gate, a knife on wood, one bell stroke.
- Rounds 1 to 4 run on flat placeholders of exactly these sizes, so the art lane is not in the way.

## 7. The plan

### 7.1 Where it fits

**M5 (chapter 1), as its own lane `lh-q`,** after the story pass and the look 2 port are merged. Art
and sound land in M6. Not M4: M4 is the town, and the review's "nights with stakes" come before
anything new. The table answers the review's soft middle ("nothing to want between dawns"), and its
measurements belong next to M5's one tuning pass for T6 and T7.

### 7.2 Steps, each a runner round (build, unit, ui, ui-de, release)

| Round | What | Passes when |
| --- | --- | --- |
| `lh-q-1` | Engine: data, `ErrandEngine`, `TableState`, save, validator, `TableNeutralityTests`; sendings 1, 5 and 11 in English; a plain list screen | all green; the reference bot equals `lh-m3-j3` with the files loaded |
| `lh-q-2` | The table: `Overlay.table`, table and rail in the chapel, `KingTarget.table`, strip pip, dawn report row, leaving and coming home, Reduce Motion; placeholder art | the UI test sends Pip on day 2 and reads his report on day 3; shots `40-table`, `41-slip`, `42-report`, `43-hook-empty` in en and de |
| `lh-q-3` | Content: all thirteen in English and German; sender and greedy bots; T10 and T11; tuning by values | section 4.4's table holds |
| `lh-q-4` | Six more languages; the validator over all of them; the longest German strings; code and player reviews, refutation, fixes | no blocker or high finding left |
| `lh-q-5` (M6) | Art, sound, haptics; a fun check by a player agent on screenshots | the player agent finds the table, sends, and can say what it cost |

Honest effort: rounds 1 to 4 are five to seven working days of agent lanes; the art is one to two
days in M6. **Cut line:** the small table is sendings 1, 2, 5, 10, 11 and 13 on the same engine and
screen.

### 7.3 Risks

- **Scope and text.** Thirteen slips and sixteen report cards (one or two per sending, and one for
  a lost lantern), in eight languages. To hold the review's rule ("rewrite, not add"), the table
  takes over petitions that `STORY.md` 9.3 plans and that are then not written twice: 4 takes
  `hemmet_sentence` and `finch_list`, 6 takes `pell_returns` and Marek's warning, 7 takes
  `quay_lanterns`; 13 is `varn_ride` as written. Net new text: thirteen short slips and about
  twelve cards.
- **Balance.** Lent soldiers can break T1 and T6. Held by the seal's rules, three bots, and tuning
  by values only.
- **The crowded castle.** The chapel bay is the only free spot near the hall; if round 2 shows the
  targets collide, the fallback is the gatehouse at x 1380, under the wall's lantern row.
- **Finding it.** A player may never walk into the chapel. Held by the cloth coming off on day 2,
  the strip pip and the dawn report's row.
- **Apple guideline 4.3 and our own "Not a copy" rule.** See 7.4. The review already names the risk
  that a throne with petitioners sits near two known games; a map with missions must not add a
  third likeness.

### 7.4 How ours differs from the genre's known games, precisely

- **The court game Louis named (Yes, Your Grace).** There the ruler lends a few named agents to
  petitioners during the audience, time moves in weekly turns, and a kingdom map shows the lords
  whose armies must be won for a battle. Here: nothing is assigned in an audience, the table is a
  place in a castle the lord walks; the unit is a **numbered lantern on a hook**, not an agent, and
  anyone can carry it; the price is **bows missing from a night the player defends in real time**;
  a loss is a **bare hook and a dark window** seen in the castle for the rest of the chapter; the
  houses give standing, tithe and open doors, never armies for a battle, and never marriages or
  heirs; time is our dusk and dawn.
- **Kingdom.** No map, a monarch on a mount, coins. Here the lord never rides and never leaves the
  light; others go and are counted back.
- **Reigns.** Swipe cards and four meters. None here: slips are tapped, and the realm has no meter
  the table moves on its own.
- **Mission tables and expedition menus in general.** Those have heroes with stats and gear, a
  success percentage to optimise, loot, and timers that run while the app is closed. Here: no
  stats, no gear, no percentage shown (three plain words), no loot, and a sending counts the game's
  own nights only.
- **The picture.** A carved table with a planed-off west that scouts scratch back in, wooden
  tokens, lanterns on hooks. No parchment overworld, no fog of war, no hex or province borders, no
  icons or layout taken from any game. Every name comes from `STORY.md` and `karte.html`.
- **Store.** The table is on at most one store screenshot; the first three show the walked castle,
  the Round and the night.

### 7.5 For the story lane to confirm

Proposals made here that touch the lore, none of which contradicts `STORY.md` as read: Lord Edric
had the table's west planed away in the Dark Year; the beacon's keepers chalked on the west door the
number of every lantern that went west; the road lanterns carry 38 to 41; what the first bell does
on night 20; what is seen from the lamp room.

## 8. Open questions for Louis

At most three, each ready to ask in short German.

**1. How big is the table at launch?**
- A) Full: 13 sendings, about 1 to 1.5 weeks more.
- B) Small: 6 sendings, about 4 days.
- C) Later, as an update after launch.
- Recommendation: **A, built so that B is the fallback.** Rounds 1 and 2 are the same for both.
- "Wie groß soll der Laternentisch zum Start sein? A) Voll: 13 Aussendungen, etwa 1 bis 1,5 Wochen
  mehr. B) Klein: 6 Aussendungen, etwa 4 Tage. C) Erst als Update nach dem Start. Empfehlung: A,
  mit B als Rückfall."

**2. What happens when a lantern does not come home?**
- A) The hook stays empty for the whole chapter (as the story's Count says).
- B) A new lantern hangs there after 5 days.
- C) Nobody is ever lost; a party can only be late.
- Recommendation: **A.** A loss is possible only on a road the table marked as dangerous before the
  lord sent anyone.
- "Wenn eine Laterne nicht heimkommt: A) Der Haken bleibt das ganze Kapitel leer. B) Nach 5 Tagen
  hängt dort eine neue. C) Niemand geht je verloren, nur Verspätung. Empfehlung: A. Verluste gibt
  es nur auf Wegen, die vorher als gefährlich markiert sind."

**3. Where does the map open?**
- A) Only at the table in the castle; the lord walks there, as to the throne.
- B) Looking from anywhere with a tap on the strip's lantern; sending only at the table.
- C) Everything from anywhere.
- Recommendation: **A.** It is the game's rule that the lord walks to what matters, the walk from
  the throne is a few seconds, and it is the least to build. B is cheap to add later.
- "Wo öffnet man die Karte? A) Nur am Tisch im Schloss, man läuft hin wie zum Thron. B) Anschauen
  von überall, Aussenden nur am Tisch. C) Alles von überall. Empfehlung: A."
