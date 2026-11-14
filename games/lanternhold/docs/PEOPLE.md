# Lanternhold: the people (who lives here and who visits)

Written by the people lane on 14.11.2026 after Louis' wish of that day: "Was auch verdammt cool wäre, wenn die Bauern
und die Leute, die arbeiten, schon richtig verbraucht sind, vom Leben geprägt. Natürlich ist unser Königreich besser,
da sind alle fast gleich, weil wir nie so viel Geld hatten. Alle sind vom Leben geprägt, dann ist es halt cool, wenn
es lebensfrohe Kinder gibt oder abgehobene reiche Adelige. Das bringt Charakterwechsel mit rein." The rule is the
people bar (`docs/BARS.md` section 3, the director's `artbar.md` section 3). STORY.md stays the source for the world,
the houses and the named figures; this page adds the town's faces and draws from STORY.md where it already has them.
The sprites' tables are `docs/SPRITES-people.md`; the code that puts them in the world is `Core/PeopleCast.swift`.

## 1. The three kinds, at a glance

A player must tell at one glance, at phone size, who has carried what. The difference is **posture, pace, cloth and
one tell**, never another style: every figure is on the same grid, in the same palette, with look 2's outline (ink
only on the shadow side and the ground contact), lit from the upper left, with a lit column left and a shade column
right on every part.

| | posture | pace | cloth (palette names) | face and hands |
|---|---|---|---|---|
| **Working people** | bent somewhere: the shoulders forward, a stoop, a hitch | heavy, short steps, slower than the lord | undyed wool (`plasterDim`, `plaster`, `parchment`), earth (`soil` ramp, `wood` ramp, `straw`), soot (`stone` ramp, `rock` ramp), patched in another tone of the same family; the one faded house colour is `waterDeep` over `roofDeep` | weathered: more `tileLight` than `dawnRose`, grey hair early (`stoneLight`, `stonePale`) |
| **Children** | upright, a big head on a small body | quick: they run (5 px a frame), skip, never walk | the lightest cloth in town, clean; the town's **one warm clean accent is theirs alone: `crimsonLight`** (a kerchief, a ribbon, a cap) | clean faces, bright hair (`strawLight`) |
| **Nobles of the inner lands** | upright as a post, the chin lifted, looking over people | slow, measured, gliding | the only saturated cloth and the only gold thread in the game: `crimson`/`crimsonDeep` with `gold` (Oxmoor), `plum` ramp with `gold`, lace in `parchment`/`foam`; polished boots (`woodDark` with a `woodLight` shine) | pale (`dawnRose`, hardly any shade), gloves in `parchment` |

Lanternhold is poor and even: nobody in town is finer than a neighbour, the house included (the lord's cloak is mended).
The nobles' footman is a working man, but from the rich side: clean white stockings that have never seen mud.

## 2. The working people of Lanternhold (twelve)

Each with one mark that tells a life. Worn, never wretched: they straighten when the lord passes because they choose
to (the farmers do it in the game). Eight have their own body now (three of them repainted townsfolk); Ilse and Master
Edwy wear the two petitioner bodies, brought into the town's even cloth; the builder and the gate guard keep their
bodies until a repaint adds their mark.

| # | who | age | trade | the mark | body |
|---|---|---|---|---|---|
| 1 | **Mother Corra** | 58 | candle-dipper at the chandlery (Tallowford still smells of wax), a guard's widow | her dead husband's guard cloak, the house teal faded to grey-blue, cut down to a shawl | `citizen` (repainted) |
| 2 | **Dun Rook** | 41 | porter at the ford, carries sacks across the Wend | the near hand and forearm bound in a grey rag: the ferry rope burnt it to the bone one winter | `citizenB` (repainted) |
| 3 | **Aldo Fenn** | 60 | ploughman of the near field; the farmer who comes to the throne | the near eye lost to the Gloom on a night of the Count thirty years ago: a leather patch, its strap across the bald crown | `citizenC` (repainted) |
| 4 | **Old Hemmet** | 71 | miller at the Wend's weir, one of the Returned (STORY.md: "The washing was still on the line") | sixty years of sacks: bent nearly double, the hump of his back above his head; flour in every crease | `elder` (new) |
| 5 | **Wenna Brisk** | 52 | washerwoman at the well (STORY.md: the Brisk family at the well) | forearms raw red to the elbow from forty years of lye and cold water | `washerwoman` (new) |
| 6 | **Brede Hask** | 37 | carries timber and stone for the walls and the beacon road | the limp: a block slipped and crushed his near foot; it is bound in rags instead of a boot | `labourer` (new) |
| 7 | **Gorm Ashby** | 48 | cottar on the near field, with the hoe | the stoop from the hoe: thirty summers over the rows set his shoulders forward and his head low; grey at the temples | `farmerHoe` (new) |
| 8 | **Hedda Ashby** | 33 | reaper, Gorm's widowed sister, with the scythe | her hair went white in one night, the night her husband's lantern did not come back at the Count | `farmerScythe` (new) |
| 9 | **Ilse Marrow** | 24 | boils tallow at the chandlery | young, and her hands already scarred by the vats | `petitionerD` (recoloured from a rose shawl and a lavender dress to an undyed shawl and a soot-grey dress; the hands' mark waits for a repaint) |
| 10 | **Master Edwy Tallow** | 50 | the chandler, the richest man in town, which means his coat has two patches instead of five | a leather apron spattered with tallow from the dipping frames that never comes off | `petitionerE` (repainted: before, velvet, fur and a gold chain made him the one body in town finer than his neighbours) |
| 11 | **Tobin Lathe** | 44 | builder for the house | three fingers on the hammer hand; the other two went under a falling stone | `builder` (repaint open) |
| 12 | **Osk Barrow** | 52 | gate guard, thirty winters on the wall | a scar from brow to jaw, the shield shoulder that no longer lifts above the ear | `guardsman` (repaint open) |

### How each is drawn (the eight with a body)

**Mother Corra** (`citizen`, 12x26). *Silhouette:* a rounded back under a shawl, the head carried a pixel forward and
low, a basket bulging at the front of the hip. *Posture:* stooped at the shoulders. *Pace:* short steps, the
townsfolk's speed. *Cloth:* an undyed headscarf (`parchment`, `plaster`, `plasterDim`) with a grey wisp at the temple
(`stoneLight`); the shawl in the faded house teal (`waterDeep`, shade `roofDeep`); an earth-brown dress (`soilLight`,
`soil`, `soilDark`) with a darned patch at the back of the skirt (`wood`); a grey-cream apron (`plaster`,
`plasterDim`); a wicker basket (`woodLight`, `wood`, `woodDark`) with the white tips of tallow candles (`parchment`).
*Tell:* the teal shawl, the only house colour on a townsperson, and faded.

**Dun Rook** (`citizenB`, 12x26). *Silhouette:* a tall man bowed under a burlap sack on his far shoulder. *Posture:*
the head a pixel forward under the load. *Pace:* the townsfolk's, the near arm swinging. *Cloth:* short dark curls
and a dark beard (`soilDark`) going grey at the temple and the chin (`stoneLight`); dark skin (`woodLight`,
`soilLight`); a soot-grey tunic (`stone`, `stoneMid`, `stoneDark`) with a brown patch over the belly (`wood`), a rope
belt (`straw`); soil-brown trousers; boots worn through at the toe (`soilLight` at the toe). *Tell:* the near forearm
and hand in a pale rag (`stonePale`, `stoneLight`), swinging with every step.

**Aldo Fenn** (`citizenC`, 12x26). *Silhouette:* short and thick-set, empty-handed, the only one who carries nothing.
*Posture:* a little forward. *Pace:* short heavy steps, the arms swinging. *Cloth:* a bald crown, a grey fringe and a
short grey beard (`stoneLight`); an undyed shirt (`parchment`, `plaster`, `plasterDim`) under an old brown vest
(`woodLight`, `wood`, `woodDark`), a belt with a buckle (`soilDark`, `soilLight`), breeches patched at both knees
(`straw` patches on `soil`). *Tell:* the eye patch (`woodDark`, 2 px over the eye) and its strap across the crown.
On the bench he sits with a hand on each knee.

**Old Hemmet** (`elder`, 12x26). *Silhouette:* the lowest grown-up in town: a hump of smock with the head hanging
below its top, a stick ahead of him. *Posture:* bent nearly double, the far hand resting at the small of his back.
*Pace:* a shuffle, half the townsfolk's speed, the feet a hand apart (2 px a frame), the body rocking down on each
contact, the stick planted ahead and drawn after. *Cloth:* an old brown wool cape over the hump (`woodLight` on its
lit top, `wood`, `woodDark`), under it a long smock of undyed wool gone grey-pale with flour (`plaster`, `plasterDim`,
`soilLight`), a rope belt (`straw`), dark breeches, clogs; a white fringe and beard (`stonePale`): the pale head stands
out against the dark hump. *Tell:* the bend.

**Wenna Brisk** (`washerwoman`, 12x26). *Silhouette:* broad and heavy, leaning back against a big basket of wet linen
on her near hip, the skirt kilted up to show bare shins and clogs. *Pace:* a heavy rolling step, the stance wide on the
contact. *Cloth:* a damp undyed headscarf knotted at the nape, its ends sticking out behind; an earth-brown bodice; a
soot-grey skirt (`rockLight`, `rock`, `rockDark`) over a grey apron; the linen heaped white (`parchment`, `foam`).
*Tell:* the forearms bare to the elbow and raw red (`tileLight`, `tile`). At the well she wrings a sheet between her
two red fists (frames 6-7).

**Brede Hask** (`labourer`, 12x26). *Silhouette:* broad shoulders under a long pale beam of fresh timber that sticks
out before and behind him. *Posture:* the weight kept off the bad foot. *Pace:* the limp, uneven on purpose (see
SPRITES-people.md): a short step onto the bad foot, the dip while the good leg swings through, the long step of the
good leg, the bad leg dragged through stiff. Four fifths of the townsfolk's speed. *Cloth:* a shaved head with a sweat
rag round the brow (`plasterDim`), a stubbled jaw (`stone`), a sleeveless dark leather jerkin (`woodDark`, `soilDark`,
lit `wood`), bare arms, rock-grey breeches (`rockLight`, `rock`, `rockDark`). *Tell:* the near foot bound in pale rags
(`stonePale`, `stoneLight`) instead of a boot, and the limp.

**Gorm Ashby** (`farmerHoe`, 12x26). *Silhouette:* long and lean under a wide straw hat with a torn front flap, a hoe
on his shoulder (a pale handle, a dark iron blade behind his head). *Posture:* the stoop; upright only in frames 8-9.
*Pace:* the townsfolk's. *Cloth:* the hat (`strawLight`, `straw`, the brim's underside `plasterDim`); grey at the
temple and grey stubble (`stoneLight`, `stone`); an earth smock (`woodLight` lit, `soilLight`, `soil`) darned at the
back (`plasterDim`), a rope belt, breeches, shins wrapped in rag (`plaster`, `plasterDim`), clogs. *Tell:* the stoop,
and the moment he straightens his back with a hand on it and lifts his face.

**Hedda Ashby** (`farmerScythe`, 12x26). *Silhouette:* upright and wiry in a long skirt, a scythe on her shoulder
with its long curved blade hanging behind her head. *Pace:* the townsfolk's. *Cloth:* a brown kerchief (`soilLight`,
`soil`), an undyed blouse with the sleeves rolled, a laced earth bodice (`soil`, `soilDark`), a long skirt a step
lighter (`woodLight` lit, `soilLight`, `soil`) with an undyed apron, clogs. *Tell:* white hair (`stonePale`) framing a young face and a white plait (`foam`, `stonePale`)
down her back. Home at evening with a sheaf before her (`strawLight`, `straw`, a `wood` band).

## 3. The children (three)

Quick where everyone else is slow, and the one warm clean colour in town. In the game they are out at the market
square while the town is content (the interface bar: the town shows happiness, there is no number for it): none below
30 happiness, Fen from 30, Pim from 35, Wren from 50. All three: 10x18, run 0-3, fidget 4-5, skip 6-9.

**Pim Brisk** (`childA`), 7, Wenna's youngest. *Silhouette:* a mop of straw hair, a brother's linen tunic far too big
(the sleeves over his hands, the hem to his knees), bare feet, a stick held high for a sword. *Cloth:* `strawLight`,
`straw` hair; the tunic `plaster` lit, `plasterDim`, `soilLight` in the shade (a value below his hair, so his face
reads between them). *Tell:* the red kerchief at his neck (`crimsonLight`,
`crimson`). *Pace:* he only runs.

**Wren Ashby** (`childB`), 9, Gorm's daughter. *Silhouette:* dark hair in plaits that fly out behind when she runs and
up when she skips, a smock dress widening at the hem. *Cloth:* `woodDark`, `wood` hair; the smock `parchment`,
`plaster`, `plasterDim` under a `soilLight` pinafore; bare shins, small clogs. *Tell:* the red ribbons at the plaits'
ends. *Pace:* she skips every second lap. *Fidget:* hands behind her back, rocking from the heels onto the toes.

**Fen** (`childC`), 11, the lamp-runner (STORY.md: "the lamp-runner child"). *Silhouette:* a head taller than the little
ones, a red cap, a short pole over his shoulder with a small lantern hanging from it behind his head: a copy of the
lord's (unlit by day). *Cloth:* the cap `crimsonLight`, `crimson`; dark curls; a handed-down leather jerkin belted twice
round (`strawLight` lit, `woodLight`, `wood`, belt `soilDark`), brown breeches, bare shins, clogs. *Tell:* the little
lantern. In the game he trails after the lord through the town (26 px on the castle side: behind him going out, ahead
of him going home) and waits at the town's edge when the lord leaves it. The child petitioner walks in his body.

## 4. The nobles of the inner lands (a kind: two bodies and a footman)

They live safe behind the Wall, in Goldenacre (House Oxmoor, the grain plain) and Stillmere (House Calder, the lake
towns), and have never seen the dark. Upright, slow, clean, overdressed; a footman carries what they will not; they hold
a cloth to the nose and look past people. Never monsters: people who have never seen the dark. Of the houses' faces
already in the game, Steward Lorenz Pell (Oxmoor) and Auditor Ebba Calder (Stillmere) are of this world; Hild Varn
(the hill friends), Ansel Quay (the poor coast) and Dame Orla Lorn (old, proud and poor) are not. All three bodies:
14x30, walk 0-3, idle 4-5, talk 6-7 (the guests' contract).

**The lord of the inner lands** (`nobleLord`): Ser Aubrey Oxmoor of Goldenacre, Lady Petra's cousin, the hunting noble
of `noble_hunt` (STORY.md section 5), and the body of the `noble` petitioner (also `statue_market`). *Silhouette:* the
tallest figure in town but the lord: a tall crimson hat with a white plume, a long coat flaring at the knee, a cane.
*Posture:* upright as a post, the chin up, the far hand on the hip with the elbow out. *Pace:* short measured steps, the
cane swung and set down. *Cloth:* the hat `crimson`, `crimsonDeep`, a `gold` band, the plume `foam`, `parchment`; dark
curls to the collar, a waxed moustache and a pointed beard (`woodDark`); a lace collar; the coat `crimsonLight` lit,
`crimson`, `crimsonDeep` with `gold` braid down its front, a `gold` buckle and hem; the sleeves darker with `gold`
cuffs and `parchment` gloves; polished boots; the cane `woodDark` with a `gold` knob. *Talk:* a gloved hand turned up
in a languid gesture.

**The lady of the inner lands** (`nobleLady`): Oxmoor's kin from Goldenacre or a syndic's lady of Stillmere, come to
"see the Wall once". *Silhouette:* the most foreign shape in the valley: a tall hennin tilted back with a veil falling
from its tip, a gown spreading to a train that drags behind her. *Posture:* upright, gliding. *Pace:* a glide: the
gown's front steps out a pixel and the tip of a shoe shows on each contact. *Cloth:* the hennin `plumLight`, `plum`,
`plumDeep` with a `gold` band, the veil `parchment`, `foam`; a pale face; a lace collar; the gown `plumLight`, `plum`,
`plumDeep` with one deep fold down the front, a `gold` girdle and hem; wide outer sleeves hanging open from the elbow,
lined in `plumLight`. *Tell:* the lace cloth she holds to her nose wherever she goes in the valley (walk and idle);
talking she lowers it and turns her hand out as if waving a smell away.

**The footman** (`footman`) in Oxmoor's livery, a step behind every noble. *Silhouette:* stiff, square, a chest held
level in both arms. *Cloth:* a flat crimson cap, neat brown hair, clean-shaven; a crimson tabard with the gold sheaf of
Goldenacre on the chest over a linen shirt; crimson breeches; **white stockings** (`foam` lit, `stonePale`); black shoes
with `gold` buckles; an iron-bound chest (`woodLight`, `wood`, bands `stoneMid`, a `gold` lock). *Talk:* he sets the chest
down and holds out a purse: a noble never pays himself (TOWN.md section 6), the footman does.

## 5. Where they are in the game (look 2)

- **The walkers** (`EntityFrames.townsfolk`, how many follows the taxpayers): Mother Corra, Old Hemmet, Brede, Dun,
  Aldo in turn, each at the pace and step their body was drawn for (Hemmet at half speed and 2 px a frame, Brede at four
  fifths). Look 1 keeps its three townsfolk.
- **The fields** (`PeopleCast.fieldWorkers`): on every built field, Gorm with the hoe and Hedda with the scythe beside
  him (on the second field when it stands). Out from the nearest house at 06:12 with their tools on the shoulder; at
  work by day, eight strokes and then the pause that straightens the back; when the lord comes within 36 px they
  straighten and turn to him; home from 17:24 with a sack and a sheaf, gone before the horn.
- **The well** (`PeopleCast.washer`): Wenna wringing linen, then a breath, all day.
- **The square** (`PeopleCast.children`): the children by happiness, laps round the well, Wren skipping every second
  lap, a fidget at each end. Fen at the lord's heels while the lord is in the town.
- **The great hall**: the farmer (Aldo), the widow and the farmwife (Corra) and the refugee (Dun) wait seated on the
  benches as before; the child petitioner is Fen, the noble petitioner Ser Aubrey; neither sits on a bench.
- **Not placed yet**: the lady and the footman. They wait for the hall's spot where a noble stands apart with a footman
  (the stage lane) and for the footman paying at the town's doors (the town lane).

## 6. In words too

The bar asks the same change of character in the lines (English and German). For the writers:

- **Working people** speak short and dry. "Field's in. Mostly." / "Das Feld ist drin. Größtenteils." — "Rope did it.
  Rope's fine." / "Das Seil war's. Dem Seil geht's gut."
- **Children** ask. "Is the dark cold? Does it have feet?" / "Ist die Düsternis kalt? Hat sie Füße?" — "Can I carry
  the lantern? Just to the gate?" / "Darf ich die Laterne tragen? Nur bis zum Tor?"
- **Nobles** speak in long polite sentences that say little. "One had so hoped the valley would be less… damp, though
  one is of course delighted to have come all this way." / "Man hatte so gehofft, das Tal wäre weniger … feucht, wobei
  man natürlich entzückt ist, den weiten Weg auf sich genommen zu haben."
