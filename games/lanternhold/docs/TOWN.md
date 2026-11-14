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
- **The row behind** ("die Gebäude hinten"): the town's backdrop row has three looks that follow the standing: hamlet,
  village, town (more roofs, a spire, more smoke, more lit windows at night). Picture only.
- **By touch:** a touch on a building shows its price as coins over the door; a second touch pays.
- **Target T12 (new):** a player who grows the town fully by night 14 earns 25 to 35 % more taxes than one who does not,
  and still cannot skip the defence. Bots that do not grow the town give today's numbers.

## 4. Travelling craftsmen (build 3)

The craft lane's list and numbers (step craft-1 and its fix round 1, 14.11.2026; the code, the hooks and the art list
are in docs/lanes/craft.md). The director's starting list stands below the final one.

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
- **Effects.** Each lives in Core behind its flag (the work standing) with a unit test, and each moves its own number
  by about 4 %: at least 2 %, at most 6 % (a unit test; the 5 % rule is a ceiling, and nought would be a placebo).
  The statue, the road lanterns and the portrait are measured in the reference bots' runs (14 nights, two seeds,
  commissioned on the craftsman's first day, over the nights the work stands); every other work in a scene of play
  that isolates what it changes (`Tests/CraftMeasures.swift`), because the reference bot's comfortable nights hide a
  work of 4 %. Round lh-c1f1-3 (the same numbers as lh-c1f1-1 and -2):

  | work | its own number | moved |
  |---|---|---|
  | statue | taxes while it stands | +4.4 % |
  | road lanterns | taxes while they stand (high-tax bot) | +2.6 % |
  | portrait | happiness while it hangs | +2.6 % |
  | bell | soldier-seconds within the lord's rally on a walk of the walls | +4.1 % |
  | glass | ground the braziers light | +3.7 % |
  | mortar | wall strength one patch restores | +4.0 % |
  | banners | seconds a breach holds against a brute (two, three, four guards) | +4.1 % |
  | handcarts | seconds the builders need for three mornings' orders | −3.7 % |
  | pitch | what a fire arrow strikes for in a fight at the gate | +4.0 % |
  | gate bands | seconds the gate holds against four ash brutes | +4.0 % |

  No work costs the reference bot a night; on harder nights (few soldiers) no night work costs a night or lets more
  than two more soldiers fall.

  | craftsman (from) | work, seen where | effect | gold | days | first day | pride |
  |---|---|---|---|---|---|---|
  | Dagmar Flint, stonemason (Highcairn) | a statue of the lord, lantern staff raised, on the market square | each house pays 1 coin more at dawn while happiness is 60 or more | 90 | 2 | 6 | yes |
  | Severin Quell, master painter (a syndic family of Stillmere; the inner lands) | the lord's portrait in the great hall, the first of a gallery | +3 happiness once, when it is hung | 45 | 1 | 5 | yes |
  | Benedek Rook, bell-founder (Brazenmoor) | a bell in the gate tower, rung at dusk and in a fight | the lord's rally (soldiers near the lord shoot and strike a quarter harder) reaches 4 % further: 83 px instead of 80 | 75 | 2 | 6 | yes |
  | Merle Tidewell, glazier (Saltgate) | glass hoods on every brazier and fire tower | their light reaches 5 % further | 50 | 1 | 4, once a brazier or fire tower stands | |
  | Cuno Marl, limeburner (Kilnhollow) | tubs of mortar with trowels on the wall walks | every patch mends 26 % of the wall instead of 25 % | 35 | 1 | 4 | |
  | Tekla Morrow, banner weaver (Wendmouth) | long teal banners with the gold lantern on the walls | a holding guard steps back at 25 % of his strength instead of 30 % | 50 | 1 | 4 | |
  | Joost Felloe, wheelwright (Brackwater) | two teal handcarts at the lodge | builders walk 8 % faster (the collector too, once he walks) | 40 | 1 | 4 | |
  | Ivar Glimm, lamp-maker (a child of Tallowford come home) | the lamplighter's street lanterns carried on past the last house to the fields and the ford (about six more posts; the lamplighter lights them with the town's four) | the unrest line sits at 12 instead of 15 | 60 | 2 | 5 | |
  | Renske Fallow, fletcher (the Seven Hills) | a rack of pitch-black arrows by the barracks | a fire arrow strikes 4 % harder | 45 | 1 | 4 | |
  | Ottilie Brand, ironwright (Goldenacre) | iron bands on the gate, the lantern gilt where they cross | the gatehouse has 4 % more strength | 70 | 2 | 6 | |

- **Works in the town** (the statue, the road lanterns) count for the town's standing (section 3).
- **What changed from the director's list:** the fountain went (+1 happiness each dawn is the tavern's whole effect and
  moves happiness far more than 5 %); the clockmaker went (reading the hour in the world is the stage lanes'
  interface, not a work's effect); the limeburner (the king's own Patch) and the ironwright (the gate) came; the
  bell carries the lord's rally further (the archers already start each night ready, so a sooner first volley had nothing
  to move, and faster soldiers let more of them fall on hard nights); the glass is 5 %, not 8 %.
- **Fix round 1 (the critic's look 1):** every work now moves its own number by about 4 %, so the bell (83 px), the
  mortar (26 %), the handcarts (8 %) and the gate bands (4 %) were tuned down to it, and the pitch strikes harder
  instead of burning longer (a fire arrow lands where light already is, and lights do not add up, so a longer fire moved
  nothing). The painter is a master of the inner lands with long, polite sentences, and his offer follows the realm's
  stage: a hamlet hears that it is beneath him, a town that it is worth courting (happiness stands in for the town
  lane's standing until the join: below 70 a hamlet, from 80 a town). The bell-founder comes from Brazenmoor (Greybell's
  House Lorn keeps the hall's first bell, a story beat of its own). The lamp-maker carries the lamplighter's lanterns on
  to the fields and the ford (section 7). Every craftsman carries a mark of life or trade in his words: the mason's
  palms grey with dust, the founder's burnt forearms, the glazier's cough, the limeburner's knuckles cracked by lime,
  the weaver's dyed fingers, the wheelwright's nine fingers, the lamp-maker's blackened thumbs, the fletcher's pitch,
  the ironwright's hammer arm, the painter's scented cloth.
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
