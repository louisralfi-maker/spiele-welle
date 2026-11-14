# Lanternhold: taxes on foot, the growing town, the craftsmen (14.11.2026)

The director wrote this from Louis' words of 14.11.2026 and his answers in the interview that followed. It replaces
DESIGN.md "Taxes" for the player's side. The numbers are starting values: the lanes tune them by values only.

## Louis' words (14.11.2026)

- "Das mit den Steuern, dass es ein Menü mit Knöpfen dafür gibt, soll weg. Wär krass, wenn man am Anfang selber zu den
  Dorfbewohnern geht und die dir Geld hinschmeißen, also die Steuern. Später hat man eine Schatzkammer und kann einen
  Steuereintreiber einstellen."
- "Die Gebäude hinten auch ausbauen … mehr Steuern, wenn die Stadt generell ausgebauter ist."
- "Fremde Handwerker, die im Thronsaal aufkreuzen und ihre Tätigkeiten anbieten."
- "Fenster statt Zahlen: okay, gute Idee."
- "Will das UI ziemlich minimal, aufgeräumt haben wie bei Kingdom Two Crowns, dass die Steuerung und alles
  selbsterklärend ist." (The bar for craft only; never that game's look or its coin pouch. DESIGN.md "Not a copy".)
- "Pixel-Look, aber es sollte wie ein Triple-A-Game aussehen, dass man gar nicht sieht, dass es von einer KI gemacht
  wurde."

## Decisions (Louis, by interview)

1. **Demanding more happens at the house.** "Wenn man nachfordert und auf die Tür drückt, klopft der König dran."
2. **Craftsmen offer works that are beautiful and useful:** every work is seen in the world and does one small thing.
3. **Build 2 (Monday 16.11.2026)** has the taxes on foot and no tax menu. **Build 3** (some days later) has the
   treasury with the collector, the growing town and the craftsmen.

## 1. Taxes on foot (build 2)

- **What is owed.** At every dawn Core works out the day's taxes exactly as today at the Normal rate. The sum is split
  over the places that pay: each house by its taxpayers (largest remainder, so the parts add up), each field its 5,
  the market its bonus.
- **Collecting.** By day, when the lord comes within about 28 px of a door whose household still owes, the household
  tosses him its coins. No tap, no button, no prompt.
- **The sign.** A household that owes stands in its doorway with a pouch from dawn until it has paid (the farmer at the
  fence, the stall keeper at the market). There is no mark on the HUD.
- **Left alone.** What the lord has not collected by the horn, the people keep. Each house left alone gives +1
  happiness at the next dawn (at most +3, the old Low tax's gain).
- **The knock (demanding more).** A touch on the door of a house that has paid today: the lord walks up and knocks three
  times. The household hands over 40 % more with bowed heads, happiness falls by 2 at once, the shutters close, the
  window stays dark that night and nobody waves the next day. Once per house and day. Every house knocked once is
  about the old High tax in gold and in mood.
- **The war levy.** From story day 8 a second knock on the same day is possible: every house knocked twice is about the
  old War tax.
- **Unrest** (happiness below 15): the doors stay shut that day and nobody pays, as today.
- **The interface.** The tax card at the throne and its buttons go. The lectern stays as furniture; the ledger lies on
  it later.
- **Ads.** "Double taxes" becomes a flag for the day: every toss of that day counts twice.
- **Bots and targets.** The reference bots collect everything at dawn; a bot that set High knocks at every house. T1 to
  T8 hold. If a number must move, it is tuned by values only and reported with before and after.
- **The picture.** Three to seven coins fly in an arc and land with a coin sound and a light tap in the hand; gold rises
  as they land. At 60 happiness and more the household waves; below 30 it throws the coins at his feet and turns away.
  Reduce Motion: the coins fade in at the lord.
- **The first morning** (onboarding lane, after the join): one townsman walks into the courtyard, tosses the lord his
  coins and walks home to the town. That is the whole tutorial for taxes.

### The numbers in Core (town-1, 14.11.2026)

`Core/Town/` holds the rules (`Town`), the ledger (`TownState` in `GameState.town`, saved), the numbers (`TownRules`,
`Balance.town`) and the words (`TownText`, `Resources/Town.xcstrings`). `tools/tune.py` mirrors them.

- **What is owed.** Every dawn works out the day's taxes as before at the one rate the lectern called Normal:
  `round(taxpayers × 5 × mood) + 5 a field + 15 % of the tax part for the market` (`Economy.taxes`), at the happiness
  before the dawn's change. The taxpayers are spread over the houses by their room (cottage 4, big house 8), largest
  remainder; the tax part is split over the houses by those taxpayers, largest remainder, ties to the earlier house
  from left to right; each field owes its 5, the market its share. The parts always add up to the day's taxes. A new
  realm's first dawn (day 2, 9 taxpayers at 60 happiness): 3, 2, 2, 2 taxpayers owe 16, 11, 11, 11 gold. Day 1 owes
  nothing: the realm starts with its 60 gold, and the first coins wait on the morning of day 2.
- **Collecting.** By day (from the dawn to the horn) a household tosses its whole part when the lord passes within
  28 px of its door (`collectReach`; the whole way of a step is checked). The door is the plot's centre until the
  rebuilt town brings its door anchors. Gold rises at once; the dawn itself puts nothing into the purse.
- **Left alone.** At the horn every part nobody came for stays with the people. Each house that owed, was left alone
  and had its door open (no unrest) brings +1 happiness at the next dawn, at most +3 for all of them ("Houses left
  alone" in the report's reasons). A field or the market left alone keeps its gold too but brings no happiness.
- **The knock.** Only at a house that has paid today, by day, doors open: the household hands over 40 % of its part
  more (rounded, at least 1 coin), happiness falls by 2 at once. Once per house and day. Every house knocked once:
  the old High tax within 4 % in gold (+40 % of the tax part; the market's share does not grow), −8 against −7 in mood.
- **The war levy.** From story day 8 (the old war tax's unlock, which a petition can also grant) a second knock at
  the same door the same day: 40 % again, −1 happiness. Every house knocked twice: the old War tax within 4 % in gold,
  −12 against −10 in mood. Never a third knock.
- **Unrest.** Below 15 at the dawn nobody owes that day (every part 0, the doors shut). Below 15 by day (a knock, a
  petition) the doors shut until it lifts: no toss, no knock; at a horn in unrest nobody counts as left alone.
- **Double taxes.** `Town.grantDoubleTaxes(&state)` (the ads lane's reward): from then until the next dawn every toss
  and every knock counts twice; once a day; refused before the first dawn and after the horn.
- **The picture's numbers** (for town-2): the household waves from 60 happiness, throws the coins at the lord's feet
  below 30; one coin in the air for every 4 gold, at least 3 and at most 7 (`Town.coins`).
- **The dawn report** (`DawnReport.town`, `TownText.reportLines`): what reached the purse yesterday, what the people
  kept, how many houses were left alone, at whose door the lord knocked (and twice), "double taxes", or in unrest
  only that every door stayed shut. The households are named by their trade: chandler, oil-presser, cooper, weaver
  (houses 1, 3, 4, 5). `DawnReport.taxes` is what the town owes today.
- **The rate.** No rate is left in the economy: the old rates and their happiness are gone from `Balance`, and the
  lectern's rate (`GameState.tax`) changes nothing until town-2 takes the card away. The bots name their habit by the
  old rate (`TownHabit`): normal collects everything at dawn; low leaves the two houses that owe least alone
  (`lowHabitSpares`: the old Low's gold, 1334 against 1372 over 20 days in the mirror, +2 happiness a day against +3;
  three houses would leave it under half and undefended); high knocks once at every house; war twice.
- **The targets.** The reference bots collect everything at dawn and play the game of before line for line (T1, T2,
  T3 with normal tax, T5 to T8: `TownNeutralityTests`). T3 with low tax and T4 moved by the bots' new habits only:
  see the lane notes (`docs/lanes/town.md`) for the numbers before and after.

## 2. The treasury and the collector (build 3)

- **Treasury:** built once at the castle (about 90 gold, from day 5). Gold is seen there: chests and piles that grow
  with the purse.
- **Collector:** hired at the treasury. Every morning he walks the town with a strongbox on a handcart, the households
  pay him the normal tax, and he is back by noon. His wage is one coin in eight of what he brings (at least 2 a day).
- He never knocks: demanding more stays the lord's own deed. A house the lord reaches first pays the lord, and at 60
  happiness and more it adds one coin "for the lantern". In unrest he comes back empty.
- He is a person with a name, in the voice of STORY.md.

## 3. The town grows (build 3)

- **Houses in three tiers** on the four house plots: cottage (room for 4), house (8), townhouse (12, new, about 110).
  A second tier for the market (a market hall, +25 % instead of +15 %) and the tavern (an inn, +2 happiness).
- **Standing, 0 to 10:** one point for every house tier above the first, for the second tier of market and tavern, for
  every craftsman's work that stands in the town and for the well and the bridge. Each point adds 3 % to the tax part.
- **The row behind** ("die Gebäude hinten"): the town's backdrop row has three looks that follow the standing: hamlet,
  village, town (more roofs, a spire, more smoke, more lit windows at night). Picture only.
- **By touch:** a touch on a building shows its price as coins over the door; a second touch pays.
- **Target T12 (new):** a player who grows the town fully by night 14 earns 25 to 35 % more taxes than one who does not,
  and still cannot skip the defence. Bots that do not grow the town give today's numbers.

## 4. Travelling craftsmen (build 3)

- From day 4, about every third day and never on a story day, one travelling craftsman joins the audience after the
  petitioners. He offers one work in two lines: what it is, what it costs, what it does.
- Answers: commission it (the gold is paid at once; the work stands one or two days later), "not now" (he comes back
  once, some days later), or send him on.
- **Ten craftsmen for chapter 1.** Every work is seen in the world and has one small effect; no effect moves a system
  by more than about 5 %. Three are works of pride.
- The director's starting list (the lane may better it):

  | craftsman | work, seen where | effect |
  |---|---|---|
  | stonemason | a statue of the lord on the market | each house tosses one coin more while happiness is 60 or more |
  | portrait painter | the lord's portrait in the hall, the first of the ancestors' gallery | +3 happiness once |
  | fountain builder | a fountain on the square | +1 happiness per dawn |
  | bell-founder | a bell in the gate tower, rung at dusk | the watch stands ready sooner: the first volley comes earlier |
  | glazier | glass on the braziers and lanterns | light radius +8 % |
  | clockmaker | a sundial in the courtyard | the hours to the horn are read in the world (no clock on the HUD) |
  | banner weaver | long banners on the wall | guards hold a little longer |
  | wheelwright | new carts | builders (and the collector) are 10 % faster |
  | lamp-maker | street lanterns out to the town | fewer grumblers: the unrest line sits a little lower |
  | fletcher | pitch arrows | fire arrows burn one second longer |

- Original names and faces in the voice of STORY.md; each has one line a player remembers. English and German.
- Bots never commission, so T1 to T8 do not change; every effect has a unit test.

## 5. What this asks of the other lanes

- **Stage:** no polish for the tax card. The interface rule for stage-3 is in the director's notes.
- **World:** each house keeps a door anchor in the layout data; the town's backdrop row stays its own sheet.
- **Ads:** "Double taxes" as a flag for the day.
- **Join:** the screen side of section 1 is re-hooked to the rebuilt town and to stage-2's touch.
