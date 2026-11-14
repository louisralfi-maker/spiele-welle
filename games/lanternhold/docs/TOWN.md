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
   treasury, the growing town and the craftsmen. (14:45: the collector moves into build 2, section 2.)

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

## 2. The collector (build 2) and the treasury (build 3)

**Changed 14.11.2026 14:45.** Louis: "Wir können auch direkt 'nen Steuereintreiber einstellen. Aber wir können trotzdem
auch nochmal extra eintreiben. Morgens geht der Steuereintreiber los, bringt es zurück." So:

- The collector needs no treasury and can be hired **from the first day**. He offers himself at the first audience,
  as the craftsmen do: one coin in eight. He comes into build 2.
- At dawn he sets out from the hall door with his strongbox on a handcart, walks every door and is back by noon. The
  player sees him go and come back; the gold arrives when he does.
- **The lord can still collect himself.** A house he reaches before the collector pays him in full. The knock
  (demanding more) stays his own deed, also at a house the collector has already been to.
- A touch on the collector at his post by the hall door sends him away or takes him on again, from the next morning.
- Walking the town is therefore a choice and never a duty: it saves the wage and it is the only way to demand more.

What follows is the first plan; where it differs, the lines above win.


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
- **The row behind** ("die Gebäude hinten"; Louis confirmed on 14.11. that he means the town's houses, which the
  player builds up): the town's backdrop row has three looks that follow the standing: hamlet,
  village, town (more roofs, a spire, more smoke, more lit windows at night). Picture only.
- **The fields grow too** (Louis, 14.11.: "Bauern sind ja auch noch extrem wichtig"): two more field plots beyond the
  last house (four fields in all; a new field about 35), and every field has a second tier, the farmstead (a barn, a
  haystack, an ox: 8 gold instead of 5; about 45). A farmstead counts for the standing like a house tier; the lane
  sets the standing's scale again so that T12 holds.
- **Farmers are seen:** out at first light, at work by day (hoe, scythe, sacks), home before the horn. No food and no
  rationing: a field is income and life, never a thing to manage (Louis, 08.11.).
- **By touch:** a touch on a building shows its price as coins; holding or tapping counts them out, coin by coin
  (`docs/PAY.md`, 14.11. 16:13: the count).
- **Target T12 (new):** a player who grows the town fully by night 14 earns 25 to 35 % more taxes than one who does not,
  and still cannot skip the defence. Bots that do not grow the town give today's numbers.

## 4. Travelling craftsmen (build 3)

The craft lane's list and numbers (step craft-1, 14.11.2026; the code, the hooks and the art list are in
docs/lanes/craft.md). The director's starting list stands below the final one.

- **When.** From day 4 a visit is due every third day (days 4, 7, 10, ...). It waits for a free day, one with no story
  petition in the queue except the houses' audiences that come on top, until the next one is due. Then one travelling
  craftsman joins the audience after the petitioners, drawn with his own seeded stream among those not yet met whose
  first day has come (and whose needs stand: the glazier comes once a brazier or fire tower stands). One a day at most.
  A chapter meets about five (days 5, 7, 12, 14 and 16 when the story is heard on its first days; a "not now"
  return takes a free day of its own); who comes depends on the realm's seed, and the rest come in the Long Watch.
- **The offer** is an audience card: his portrait, name and trade, two lines in his voice (what the work is and what it
  does), the price on the commission, Odile's counsel. Answers: **commission it** (the gold is paid at once; the work
  stands from the dawn one or two days later; the castle's builders are not needed), **not now** (he comes back once,
  four days later or on the next free day, and then offers only commission or no), **no, thank you** (he is gone).
- **Unheard by the horn:** on his first visit it counts as "not now", on his return as "no". A craftsman left waiting
  costs no happiness; he is a trader, not a subject.
- **The save** keeps who came, the answers and the works (`GameState.craft`).
- **Bots never commission.** The reference bot's audience passes him by, and a realm the craftsmen visit plays line for
  line as one they never visit (a unit test, 14 nights, three seeds, normal and high tax). T1 to T8 do not move.
- **Effects.** Each lives in Core behind its flag (the work standing) with a unit test; each is measured with the
  reference bots against the same realm without it (14 nights, two seeds) and moves its system by at most about 5 %
  (round lh-c1-2: the statue +4.4 % taxes while it stands, the road lanterns +2.6 % taxes for the high-tax bot, the
  portrait +2.6 % happiness; the night's works move the reference bot's comfortable nights by nothing measurable).

  | craftsman (from) | work, seen where | effect | gold | days | first day | pride |
  |---|---|---|---|---|---|---|
  | Dagmar Flint, stonemason (Highcairn) | a statue of the lord, pole raised, on the market square | each house pays 1 coin more at dawn while happiness is 60 or more | 90 | 2 | 6 | yes |
  | Severin Quell, portrait painter (Stillmere) | the lord's portrait in the great hall, the first of a gallery | +3 happiness once, when it is hung | 45 | 1 | 5 | yes |
  | Benedek Rook, bell-founder (Greybell) | a bell in the gate tower, rung at dusk and in a fight | the lord's rally (soldiers near the lord shoot and strike a quarter harder) reaches 10 % further | 75 | 2 | 6 | yes |
  | Merle Tidewell, glazier (Saltgate) | glass hoods on every brazier and fire tower | their light reaches 5 % further | 50 | 1 | 4, once a brazier or fire tower stands | |
  | Cuno Marl, limeburner (Kilnhollow) | tubs of mortar with trowels on the wall walks | every patch mends 30 % of the wall instead of 25 % | 35 | 1 | 4 | |
  | Tekla Morrow, banner weaver (Wendmouth) | long teal banners with the gold lantern on the walls | a holding guard steps back at 25 % of his strength instead of 30 % | 50 | 1 | 4 | |
  | Joost Felloe, wheelwright (Brackwater) | two teal handcarts at the lodge | builders walk 10 % faster (the collector too, once he walks) | 40 | 1 | 4 | |
  | Ivar Glimm, lamp-maker (once of Tallowford) | twelve lanterns on posts from the back gate to the town | the unrest line sits at 12 instead of 15 | 60 | 2 | 5 | |
  | Renske Fallow, fletcher (the Seven Hills) | a rack of pitch-black arrows by the barracks | a fire arrow's fire burns 3.5 s instead of 2.5 s | 45 | 1 | 4 | |
  | Ottilie Brand, ironwright (Goldenacre) | iron bands on the gate, the lantern gilt where they cross | the gatehouse has 5 % more strength | 70 | 2 | 6 | |

- **Works in the town** (the statue, the road lanterns) count for the town's standing (section 3).
- **What changed from the director's list:** the fountain went (+1 happiness each dawn is the tavern's whole effect and
  moves happiness far more than 5 %); the clockmaker went (reading the hour in the world is the stage lanes'
  interface, not a work's effect); the limeburner (the king's own Patch) and the ironwright (the gate) came; the
  bell carries the lord's rally further (the archers already start each night ready, so a sooner first volley had nothing
  to move, and faster soldiers let more of them fall on hard nights); the glass is 5 %, not 8 %.
- The director's starting list:

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

- Original names and faces in the voice of STORY.md; each has one line a player remembers. English and German in
  `Resources/Craftsmen.xcstrings`; the six other languages after the join.

## 5. What this asks of the other lanes

- **Stage:** no polish for the tax card. The interface rule for stage-3 is in the director's notes.
- **World:** each house keeps a door anchor in the layout data; the town's backdrop row stays its own sheet.
- **Ads:** "Double taxes" as a flag for the day.
- **Join:** the screen side of section 1 is re-hooked to the rebuilt town and to stage-2's touch.

## 6. The people (Louis, 14.11.2026, 14:20)

"Die Bauern und die Leute, die arbeiten, schon richtig verbraucht, vom Leben geprägt … lebensfrohe Kinder … abgehobene
reiche Adelige. Das bringt Charakterwechsel mit rein." The rule is `docs/BARS.md` section 3; the cast and its sprites
are the people lane's work (`docs/PEOPLE.md`, branch `claude/lh-people`).

- The households in the doorways are these worn working people. At 60 happiness and more it is sometimes the
  household's child who runs out with the coins.
- The farmer does not toss: he leaves his hoe, comes to the fence and counts his coins out of a knotted cloth into the
  lord's hand.
- A noble guest never pays himself: his footman does.

## 7. The lamplighter (Louis, 14.11.2026 14:45)

"Abends wär noch einer cool, der wie im alten Prag mit diesen langen Kerzen die Straßenlaternen anmacht."

- The town has a lamplighter with a name: a townsman and a figure of his own. (Changed 14.11. 15:05: the lord's house
  never were lamplighters, `docs/HOUSE.md` section 1.) Each evening he lights his pole at the hearth in the hall and
  carries the house's light out into the street. The people lane draws and names the figure.
- One hour before the horn (18:00) the lamplighter leaves the castle gate with a long lighting pole and lights the
  street lanterns one by one down the road; the last one burns as the horn sounds. Each gives a small warm pool.
- At first light the same walk back, putting them out with the snuffer on the pole.
- This is the evening's clock: when the lamplighter walks, the day is ending. No clock on the HUD.
- The town starts with about four lanterns. The lamp-maker's work (section 4) adds more, out to the fields.
- In unrest (happiness below 15) nobody lights them: the street stays dark.
- Picture only. One small rule is kept for build 3 if it stays one value: in a broken night (REALM.md section 4) a
  town with its lanterns lit loses one house fewer.
- **Lit at the Eternal Light** (Louis, 14.11. 15:19: "wenn der das immer bei dem ewigen Licht anzündet und dann
  losläuft"). The Flame in the hall's hearth is the Eternal Light (`docs/HOUSE.md` section 1). Every dusk the
  lamplighter comes into the hall, lights his pole at it and walks out through the gate into the town: the player sees
  it each evening. So every street lantern burns a piece of the Eternal Light. Picture only: the lanterns burn as the
  hearth does (bright, low, embers; REALM.md section 4), and with the hearth out there is nothing to light them with.
