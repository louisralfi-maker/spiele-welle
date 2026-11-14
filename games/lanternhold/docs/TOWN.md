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
- **The row behind** ("die Gebäude hinten"; Louis confirmed on 14.11. that he means the town's houses, which the
  player builds up): the town's backdrop row has three looks that follow the standing: hamlet,
  village, town (more roofs, a spire, more smoke, more lit windows at night). Picture only.
- **The fields grow too** (Louis, 14.11.: "Bauern sind ja auch noch extrem wichtig"): two more field plots beyond the
  last house (four fields in all; a new field about 35), and every field has a second tier, the farmstead (a barn, a
  haystack, an ox: 8 gold instead of 5; about 45). A farmstead counts for the standing like a house tier; the lane
  sets the standing's scale again so that T12 holds.
- **Farmers are seen:** out at first light, at work by day (hoe, scythe, sacks), home before the horn. No food and no
  rationing: a field is income and life, never a thing to manage (Louis, 08.11.).
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

## 6. The people (Louis, 14.11.2026, 14:20)

"Die Bauern und die Leute, die arbeiten, schon richtig verbraucht, vom Leben geprägt … lebensfrohe Kinder … abgehobene
reiche Adelige. Das bringt Charakterwechsel mit rein." The rule is `docs/BARS.md` section 3; the cast and its sprites
are the people lane's work (`docs/PEOPLE.md`, branch `claude/lh-people`).

- The households in the doorways are these worn working people. At 60 happiness and more it is sometimes the
  household's child who runs out with the coins.
- The farmer does not toss: he leaves his hoe, comes to the fence and counts his coins out of a knotted cloth into the
  lord's hand.
- A noble guest never pays himself: his footman does.
