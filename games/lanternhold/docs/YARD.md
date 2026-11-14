# Lanternhold: the drill yard (14.11.2026, 16:04)

The director wrote this from Louis' words of 14.11.2026. He left the decision and the whole plan to the director. The
numbers are starting values: the lanes tune them by values only.

## Louis' words (14.11.2026)

"Wär nicht so eine Kaserne weiter drin oder so an der Mauer bisschen drin gut, wo die Soldaten dann hingehen,
trainieren, und man die da auch upgraden kann oder Feuerpfeile oder besseren Bogen etc. reinmacht. Du entscheidest, ob
es gut ist, und planst es komplett aus."

## The director's decision: yes, for build 3

For it:

- **The soldiers get a day.** Today they stand on the wall or wait unseen. With the yard the castle is alive by day.
- **Gold gets a use that is seen every night.** This is "immer wohlhabender" (REALM.md section 2) for the garrison:
  farmers with bows at first, the house's own company at the end.
- **Losses get weight.** A trained soldier with a name is worth more than a recruit, so the player stands with him
  (REALM.md section 3, "being there counts").
- **Nothing must move.** The barracks already stands in the courtyard at the wall.

The risks, and the rule that answers each:

| risk | rule |
|---|---|
| an upgrade menu | every step is a building or a thing in the yard, bought by touch; there is no list and no card |
| the night gets too easy | few steps, small values, bots never buy, target T16 (section 8) |
| too deep ("jetzt nicht so tief") | two kinds of soldier, one state (recruit or trained), three stages, two works |
| a copy | section 9 |

## 1. The place

- In the courtyard, against the inner face of the castle wall, right behind the gatehouse: where the barracks stands
  today. Louis: "an der Mauer, bisschen drin".
- The stair to the wall walk starts at the yard. At dusk the soldiers go up in file, and the player sees it.
- It needs about 110 px of open ground in front of the bunkhouse. The straw butts stand against the wall's inner
  face, so the arrows fly along the screen and are read at a glance.
- It is part of the castle: it never burns in a broken night (REALM.md section 4).

## 2. Three stages

Built by the builders like every building. A touch shows the price as coins, and the lord counts them out
(`docs/PAY.md`; TOWN.md section 3, "By touch").

| stage | price, from | what stands | the trained soldier's look | what it brings |
|---|---|---|---|---|
| 1 the barracks | stands on day 1 | a bunkhouse, the muster board, a bench, one straw butt | (nobody is trained) | recruiting, as today |
| 2 the drill yard | 70, day 4 | a fenced yard of sand, three butts, four pells, an arms rack | the company: padded jack, kettle hat | training; the two works of section 4 |
| 3 the armoury | 190, day 9, needs the smithy | a stone armoury with the house's banner; a second floor on the bunkhouse | the house guard: mail, a tabard with the lantern, longbow or bill | better arms; training in two days |

- A recruit wears the levy's look at every stage: wool, a leather cap, a short bow or a spear and a round shield. It is
  today's soldier.
- The look is the wealth arc for the garrison. Faces and backs stay as life made them (BARS.md section 3).

## 3. Training

- **Recruit and trained.** With the drill yard every soldier drills by day. After three days of drill a recruit is
  trained (two days once the armoury stands). A day counts when he drilled between 09:00 and 16:00; a man sworn in
  after noon starts the next day.
- **A recruit is today's soldier in every number.** He stands his post from the moment he is sworn in, also at night.
- **Trained:**

  | | recruit (today) | trained | trained, with the armoury |
  |---|---|---|---|
  | archer | a shot every 1.4 s, range 150 | a shot every 1.25 s | and the longbow: range 165 |
  | guard | 30 HP, 6 damage per s | 36 HP | and the bill: 7.5 damage per s |

- **Under the lord's eye.** When the lord stands at the yard's fence for about three seconds while they drill, Brannock
  calls them to order, they drill harder, and the day counts double for everyone. Once a day. No prompt and no
  button: they straighten when he comes. It is "being there counts" by day, and never a duty.
- **The moment.** On the morning a recruit is trained Brannock hands him the company's coat at the muster board, with
  one line and his name. The dawn report lists it ("Trained: Wat, Ilse.").
- **Seen.** Recruits miss the butt more often and stand a little crooked; trained soldiers hit and stand straight.
- **Loss.** A fallen trained soldier is named as one in the dawn report. The cost in happiness stays 3.

## 4. The two works

From the drill yard on, two empty places stand in the yard: an empty tripod by the butts and an empty rack by the
pells. A touch shows the price, and the lord counts it out (`docs/PAY.md`). Bram makes the work at the smithy (at his
own forge in the courtyard if no smithy stands) and brings it over on a handcart at the next dawn; from that dusk it
is in use. Both works count for every soldier, recruit or trained.

| work | price | in the yard | at night | effect |
|---|---|---|---|---|
| the pitch kettle (Pechkessel) | 40 | a kettle over a small fire by the butts | a small pitch pot glows at every archer's post; they dip the arrow before they loose | every third arrow is a fire arrow (today every fourth) |
| the pavises (Setzschilde) | 45 | a rack of tall standing shields, the lantern painted on each | the guards plant them in the breach and hold behind them | guards holding a breach take 15 % less harm |

- "Feuerpfeile" is the kettle. "Besserer Bogen" is the armoury's longbow. More light means more creatures the archers
  can see: the kettle is the game's third pillar ("light is life") as a purchase.
- Both are props in the world. Neither needs a new soldier sprite.

## 5. The soldiers' day (picture only)

- **Dawn:** they come down from the wall, tired, and go into the bunkhouse. Smoke from its chimney. One sentry stays
  on the gate, so the wall is never bare.
- **09:00 to 16:00, with the drill yard:** the drill. Archers at the butts (the arrows fly and stick), guards in pairs
  at the pells, Brannock walking the line. Without the drill yard they sit on the bench, string bows and play dice.
- **Children at the fence** copy the drill with sticks (BARS.md section 3: cheerful children). Brannock lets them.
- **16:00:** they eat at the bench.
- **18:00, when the lamplighter walks:** they arm at the rack and climb to their posts in file. Everyone stands
  before the horn. With the lamplighter this is the evening's second clock; there is none on the HUD.
- Reduce Motion: no change is needed; nothing here flashes or shakes.

## 6. Recruiting by touch

- The muster board hangs by the bunkhouse door. Two badges are painted on it: a bow and a shield.
- A touch on a badge shows its price as coins (10 and 14, today's prices), and the lord counts them out to Brannock
  (`docs/PAY.md`).
- A townsman with a name walks in from the town (he runs at night). Brannock swears him in at the board, his hand on
  the house's lantern; the `seal` sound. He is a soldier at once, as today.
- This takes the place of the recruit card after build 2's join. Until then recruiting stays as the stage lane has it.

## 7. Words (English and German, in build 3's batch)

- Names: the barracks (Kaserne), the drill yard (Übungshof), the armoury (Zeughaus), the pitch kettle (Pechkessel),
  the pavises (Setzschilde), recruit (Rekrut), trained (ausgebildet).
- Brannock runs the drill. He is the gruff veteran of STORY.md and speaks to the lord as HOUSE.md section 7 says.
  Starting lines; the story editor may better them:

  | when | English | German |
  |---|---|---|
  | day 4, at the audience (the yard can be built without it) | "Give me a yard and three days, lord, and I'll give you soldiers. Today I have farmers holding bows." | „Gebt mir einen Hof und drei Tage, Herr, dann gebe ich Euch Soldaten. Heute habe ich Bauern mit Bögen." |
  | the lord at the fence | "The lord is watching. Again!" | „Der Herr sieht zu. Noch mal!" |
  | a recruit is trained | "{name}. You'll do." | „{name}. Du taugst." |
  | the armoury stands | "Mail. I never thought I'd see this hold in mail." | „Kettenhemden. Ich hätte nie gedacht, diese Burg in Kettenhemden zu sehen." |

- The old sergeant is the jailer of build 3 (HOUSE.md section 10): he does not run the drill.

## 8. Bots and targets

- The reference bots never build the yard and never buy a work. So nobody is trained, and T1 to T8 and T12 to T15
  hold line for line.
- A new "yard" bot gives the reference's orders and, as gold allows, the drill yard, the kettle, the pavises and the
  armoury, in that order.
- **T16:** over nights 8 to 14 the yard bot loses 20 to 35 % fewer soldiers than the reference, and 15 to 25 % fewer
  creatures reach the gatehouse. It never wins a night the reference loses clearly. A bot that buys the yard in place
  of walls does worse than the reference. Night 20 is still decided by the beacon: T6 stays in its band, or the lane
  reports before and after.
- With presence (REALM.md section 3) and the smithy on top, no night from 15 on may become a walk: the lane checks the
  three together.
- State: the yard's stage, two flags for the works, the days drilled per soldier. The save format takes them with a
  default, so older saves load.
- A unit test for every value.

## 9. Not a copy, and what it touches

- **Not a copy** (DESIGN.md "Not a copy"): nothing in the yard is picked up to set a job, and no coin is dropped
  anywhere. A recruit is a named citizen sworn in by the captain; a work is paid from the purse and made by Bram. No
  mounts, ever. The yard's look is our own: the inner face of our wall, our people, the house's lantern.
- **The smithy** stays what it is: arrowheads, archer damage +25 % and +50 %. The armoury needs its first tier.
- **The fletcher** (TOWN.md section 4): his pitch arrows are seen at the yard, a second small pot by the kettle.
- **Petitions:** with the drill yard, the two archers of `truce_drill` and the guard of `old_sergeant` arrive
  trained. A small thing: only if it stays one line of code.
- **The forward post** (REALM.md section 5, the ruined watchtower): the longbow reaches further from there too.

## 10. Builds and lanes

- **Build 2 (Monday 16.11.2026):** nothing of this. The barracks and recruiting stay as they are.
- **Build 3:** all of it. If time is short, in this order: the drill yard with training and the kettle; the pavises;
  the armoury.
- **Core:** a second round of the front lane (branch `claude/lh-front`), after its present steps: the stage, the
  flags, training, the yard bot, T16.
- **Picture:** the world lane's second round (the three stages, the two works empty and full, the pitch pots at the
  posts, the pavises in the breach) and the people lane's second round (archer and guard in three looks; today's
  soldier is the levy).
- **Words:** with build 3's text batch (HOUSE.md), then the six other languages in their second pass.
- **The day round and the touch** are hooked at build 3's join, in the rebuilt castle.
- **Gates.** The usual critics. The player critic judges on screenshots at phone size: does the yard read as drill and
  never as a shop; is a trained soldier told from a recruit; is every purchase understood without a word.

## 11. Later, not in chapter 1

Crossbows, a second company, the walled city's garrison. They wait for the endless mode and chapter 2.
