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
| **Children** | upright, a big head on a small body | quick: they run (5 px a frame), skip, never walk | the lightest cloth in town, clean, **a value step above any grown-up's** (linen lit in `foam`, `parchment` mid, `plaster` shade); the town's **one warm clean accent is theirs alone: `crimsonLight`** with `crimson`, and big enough to see at phone size (Nib's whole kerchief and a patch, Wren's pinafore, Fen's cap) | clean faces, bright hair (`strawLight`) |
| **Nobles of the inner lands** | upright as a post, the chin lifted, looking over people | slow, measured, gliding | the only saturated cloth and the only gold thread in the game: Oxmoor's deep `crimson`/`crimsonDeep` lit with `dusk` (never the children's `crimsonLight`) with `gold`, the `plum` ramp with `gold`, lace in `parchment`/`foam`; polished boots (`woodDark` with a `woodLight` shine) | pale (`dawnRose`, hardly any shade), gloves in `parchment` |

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
| 3 | **Ned Furrow** | 60 | ploughman of the near field; the farmer who comes to the throne (renamed in fix round 1: "Aldo Fenn" stood too near Lord Aldric and the child Fen; and in people-2: the earlier surname was a famous pirate's) | the near eye lost to the Gloom on a night of the Count thirty years ago: a leather patch, its strap across the bald crown | `citizenC` (repainted) |
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
belt (`straw`); soil-brown trousers; boots worn through at the toe (`soilLight` at the toe). *Tell:* the whole near forearm
and hand bound in a pale linen rag two pixels wide (`parchment` lit, `plaster`, `plasterDim` at the hand), swinging in
front of the dark tunic with every step: the brightest thing on him.

**Ned Furrow** (`citizenC`, 12x26). *Silhouette:* short and thick-set, empty-handed, the only one who carries nothing.
*Posture:* a little forward. *Pace:* short heavy steps, the arms swinging. *Cloth:* a bald crown, a grey fringe and a
short grey beard (`stoneLight`); an undyed shirt (`parchment`, `plaster`, `plasterDim`) under an old brown vest
(`woodLight`, `wood`, `woodDark`), a belt with a buckle (`soilDark`, `soilLight`), breeches patched at both knees
(`straw` patches on `soil`). *Tell:* the eye patch (`woodDark`, 2 px over the eye) and its strap across the crown.
On the bench he sits with a hand on each knee.

**Old Hemmet** (`elder`, 12x26). *Silhouette:* the lowest grown-up in town: a hump of smock with the head hanging
below its top, a stick ahead of him. *Posture:* bent nearly double, the far hand resting at the small of his back.
*Pace:* a shuffle, half the townsfolk's speed, the feet a hand apart (2.5 px a frame), the body rocking down on each
contact, the stick planted ahead and drawn after. *Cloth:* an old brown wool cape over the hump (`woodLight` on its
lit top, `wood`, `woodDark`), under it a long smock of undyed wool gone grey-pale with flour (`plaster`, `plasterDim`,
`soilLight`), a rope belt (`straw`), dark breeches, clogs; a white fringe and beard (`stonePale`): the pale head stands
out against the dark hump. *Tell:* the bend.

**Wenna Brisk** (`washerwoman`, 12x26). *Silhouette:* broad and heavy, leaning back against a big basket of wet linen
on her near hip under her arm, the skirt kilted up to show bare shins and clogs. *Pace:* a heavy rolling step, the
stance wide on the contact. *Cloth:* a damp undyed headscarf knotted at the nape, its ends sticking out behind; an
earth-brown bodice; a soot-grey skirt (`rockLight`, `rock`, `rockDark`) with a brown patch over a grey apron; the
linen heaped white (`parchment`, `foam`); bare shins weathered (`dawnRose`, `tileLight`), not red. *Tell:* the sleeves
rolled to the elbow and the forearms raw red (`tileLight`, `tile`): the near elbow bent and the forearm laid across the
wet linen (2 rows of 4 px, white linen above and below it). At the well, on its far side from the notice board, she
wrings a sheet: held level across her chest between her two red fists, twisted, its light and shade banding moving on
a pixel between the two frames, a drop falling (frames 6-7).

**Brede Hask** (`labourer`, 12x26). *Silhouette:* broad shoulders under a long beam of weathered timber on his far
shoulder (`woodLight` lit, `wood`, the cut ends `strawLight`: pale fresh wood read as a brass horn at phone size),
angled with its back end high above his brow, running behind his head and lying on his shoulder in front, his near
hand up on top of it. *Posture:* the weight kept off the bad foot. *Pace:* the limp, uneven on purpose (see
SPRITES-people.md): a short step onto the bad foot, the dip while the good leg swings through, the long step of the
good leg, the bad leg dragged through stiff. Four fifths of the townsfolk's speed. *Cloth:* a shaved head with a sweat
rag round the brow (`plasterDim`), a stubbled jaw (`stone`), a sleeveless dark leather jerkin (`woodDark`, `soilDark`,
lit `wood`), bare arms, rock-grey breeches (`rockLight`, `rock`, `rockDark`). *Tell:* the near foot bound in pale rags
(`stonePale`, its shadow side `stone`) instead of a boot, and the limp.

**Gorm Ashby** (`farmerHoe`, 12x26). *Silhouette:* long and lean under a wide straw hat with a torn front flap, a hoe
on his shoulder (a pale handle, a thin iron blade seen edge-on behind his head with its lit edge, `stoneMid` and
`stoneLight`: never a block). *Posture:* the stoop; upright only in frames 8-9.
*Pace:* the townsfolk's. *Cloth:* the hat (`strawLight`, `straw`, the brim's underside `plasterDim`); grey at the
temple and grey stubble (`stoneLight`, `stone`); an earth smock (`woodLight` lit, `soilLight`, `soil`) darned at the
back (`plasterDim`), a rope belt, breeches, shins wrapped in rag (`plaster`, `plasterDim`), clogs. *Tell:* the stoop,
and the moment he straightens his back with a hand on it and lifts his face.

**Hedda Ashby** (`farmerScythe`, 12x26). *Silhouette:* upright and wiry in a long skirt, bareheaded, a scythe on
her shoulder with its long curved blade hanging behind her head. *Pace:* the townsfolk's. *Cloth:* an undyed blouse
with the sleeves rolled under a laced earth bodice that covers her back (`soilLight` lit, `soil`, `soilDark`), a long
skirt a step lighter (`woodLight` lit, `soilLight`, `soil`) with a patch and an undyed apron, clogs. *Tell:* white
hair, bare: the crown lit in `foam`, `stonePale`, the fringe over the brow in `stoneLight`, framing a young face, and a
white plait (`foam`, `stonePale`) down the lit column of her brown bodice. *The mow:* the snath (pale ash,
`strawLight` with a `woodDark` shadow line) across her body; swung back with the blade's curve along the ground
behind her heels, swung through with it cutting before her feet, the upper body turning a pixel each way, the apron
hanging straight so the snath is the only slanting line. Leaning on the scythe, its blade curves over her head. Home
at evening with a sheaf before her (`strawLight`, `straw`, a `wood` band).

### Three more who will be seen (named now, drawn in people-2 and for build 3)

The director's notes of 14.11. (14:45, 15:03, 15:19, 15:44) add three working people. They are in the cast with a name,
a mark and a silhouette; their sheets are the first work of people-2 (see "What waits" in docs/lanes/people.md).

| # | who | age | trade | the mark | silhouette and tell |
|---|---|---|---|---|---|
| 13 | **Saul Tolliver** (renamed by the director: the earlier surnames echoed a film creature and a common plant; a tolliver takes the toll) | 56 | the collector (TOWN.md section 2): hired at the first audience, out from his post at dawn with the strongbox on a handcart, every door at a cart's pace, back in the early afternoon | his left arm, lost on the wall the winter the old lord died; the empty sleeve pinned across his chest. The town trusts him because he has never kept a coin that was not his | a stout man leaning into a two-wheeled handcart, pushing it one-handed with a leather strap over his shoulder to the shafts; the iron-bound strongbox on the cart (`woodLight`, `wood`, bands `stoneMid`, a plain iron lock: no gold, it is the town's box). Cloth: a long grey-brown coat patched at the elbow (`rock` ramp), a rolled wool cap pulled down to the brow (`soil`, the rolled edge `soilLight`), boots. Frames: the cart walk (a wider frame for the cart), the idle at his post by the hall door with his hand on the box, the coin take at a door (the hand out, the coin dropped through the slot, a nod) |
| 14 | **Silas Moth** ("Moth") | 63 | the lamplighter (TOWN.md section 7, HOUSE.md section 1): a townsman, never of the house; each dusk he lights his pole at the Eternal Light in the hall's hearth and carries the house's light out into the street. He knows every window and who is awake at midnight: the lord's ear in the town | a burn on the side of his neck under the ear from a lantern that burst in his hands thirty years ago; he still flinches at a spitting wick | tall and thin as his pole, stooped from forty years of reaching up (the head and shoulders a pixel forward, a rounded upper back), a long dark coat to the shins, narrow at the shoulders and flaring to a hem that swings with his stride, gathered at the waist by a cord (`stone` ramp), a soot-blackened thumb and forefinger, a soft felt hat whose brim droops front and back (`soil`); the long lighting pole, longer than he is tall, with a small brass wick holder and a snuffer bell at its tip (`stoneLight`, `straw`): it must never be mistaken for the lord's hooked lantern staff, which carries a lantern. Frames: the walk with the pole on his shoulder (the tip burning at dusk: a glow strip), reaching up to light, reaching up to snuff, and the hearth set (the pole's tip held into the Flame, a small bow of the head to it, the turn to go) |
| 15 | **Old Kell** (Amory Kell) | 62 | the jailer of build 3 (HOUSE.md section 10): the old sergeant of the petition `old_sergeant`, who held the old lord's gate for twenty winters, if the lord took him in; otherwise a soldier of the garrison stands there | his knees: "My knees are done, my arm is not." He stands stiff-legged and leans on his spear like a stick | square and solid at the head of the dungeon stair, the legs braced apart and straight, an old dented kettle hat, a faded house-teal surcoat over mail gone brown at the edges, the spear upright as a staff in one hand and a lit lamp hanging from the other (lit: someone below wants a word). Frames: the stand with the lamp, a nod, sitting by the gate when nobody is below |

## 3. The children (three)

Quick where everyone else is slow, and the one warm clean colour in town: each child wears the cleanest, lightest cloth
in the valley (a value step above any grown-up's) and enough red to be seen at phone size on the well's stones. In the game they are out at the market
square while the town is content (the interface bar: the town shows happiness, there is no number for it): from 45 happiness Nib and Wren, from 80 Fen too (people-2, `TownLife.children`). Nib and Wren: 12x18, run 0-3, fidget
4-5, skip 6-9, the stick fight 10-11; Fen: 10x18, run 0-3, fidget 4-5, skip 6-9.

**Nib Brisk** (`childA`), 7, Wenna's youngest (renamed in fix round 1: "Pim" stood too near Pip the fool).
*Silhouette:* a mop of straw hair, a brother's linen tunic far too big (the sleeves over his hands, the hem to his
knees), bare feet, a stick held high for a sword. *Cloth:* `strawLight`, `straw` hair; the tunic washed white by his
mother at the well (`foam` lit, `parchment`, `plaster`). *Tell:* the red kerchief round his neck, knotted at the nape, its two
ends flying out behind him when he runs (`crimsonLight`, `crimson`; people-2, after the critic: no red on the throat or
the belly, where it read as a wound at phone size, so the patch is gone). *Pace:* he only runs.

**Wren Ashby** (`childB`), 9, Gorm's daughter. *Silhouette:* dark hair in plaits that fly out behind when she runs and
up when she skips, a smock dress widening at the hem. *Cloth:* `woodDark`, `wood` hair; a clean linen smock (`foam`,
`parchment`, `plaster`) under a red pinafore (`crimsonLight`, `crimson`), the biggest patch of the children's red in
town; bare shins, small clogs. *Tell:* the red pinafore, and red ribbons at the plaits' ends. *Pace:* she skips every second lap. *Fidget:* hands behind her back, rocking from the heels onto the toes.

**Fen** (`childC`), 11, the lamp-runner (STORY.md: "the lamp-runner child"). *Silhouette:* a head taller than the little
ones, a red cap, a short pole over his shoulder with a small lantern hanging from it behind his head: a copy of the
lord's (unlit by day). *Cloth:* the cap `crimsonLight`, `crimson`; dark curls; a handed-down leather jerkin, oiled clean
and a step lighter than any grown-up's leather (`strawLight` lit, `straw`, `woodLight`), belted twice round (`soilDark`)
over a linen shirt whose collar shows (`foam`, `parchment`), brown breeches, bare shins, clogs. *Tell:* the little
lantern. In the game he runs after the lord at his heels while the lord is near the children's game, stops when the lord walks
on and runs back to it (people-2, `TownLife.trailing`). The child petitioner walks in his body.

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
in a languid gesture. In Oxmoor's crimson the lit tone is `dusk`: the bright warm red belongs to the children.

**The lady of the inner lands** (`nobleLady`): Oxmoor's kin from Goldenacre or a syndic's lady of Stillmere, come to
"see the Wall once". *Silhouette:* the most foreign shape in the valley: a tall hennin tilted back with a veil falling
from its tip, a gown spreading to a train that drags behind her. *Posture:* upright, gliding. *Pace:* a glide: the
gown's front steps out a pixel and the tip of a shoe shows on each contact. *Cloth:* the hennin `plumLight`, `plum`,
`plumDeep` with a `gold` band, the veil `parchment`, `foam`; a pale face; a lace collar; the gown `plumLight`, `plum`,
`plumDeep` with one deep fold down the front, a `gold` girdle and hem; wide outer sleeves hanging open from the elbow,
lined in `plumLight`. *Tell:* the lace cloth: walking she carries it at her chest in her gloved hand; standing she presses it to her
nose and mouth, the glove and the lace inside the outline of her face (nothing sticks out of the face: a point there
reads as a beak at phone size); talking she lowers it and turns her hand out as if waving a smell away.

**The nobles turn with the realm** (REALM.md section 2). In the hamlet and the village they look past us and leave
quickly: they walk, idle with the cloth at the nose and talk, and never bow. In the town they come to court us, bring
gifts and ask favours: a noble who has just come before the lord bows once (frames 8-9: the gloved hand laid on the
chest for half a second, the head inclined for most of a second, upright again), then talks
(`PeopleCast.bowFrame`). The footman never bows; he pays.

**The footman** (`footman`) in Oxmoor's livery, a step behind every noble. *Silhouette:* stiff, square, a chest held
level in both arms. *Cloth:* a flat crimson cap, neat brown hair, clean-shaven; a crimson tabard with the gold sheaf of
Goldenacre on the chest over a linen shirt; crimson breeches; **white stockings** (`foam` lit, `stonePale`); black shoes
with `gold` buckles; an iron-bound chest (`woodLight`, `wood`, bands `stoneMid`, a `gold` lock). *Talk:* he sets the chest
down and holds out a purse: a noble never pays himself (TOWN.md section 6), the footman does.

## 5. Where they are in the game (look 2; people-2, `TownHouseholds`, `TownLife`, `TownLamps`)

The town lives by its people: the same people every day, in their own houses, at their own work, so that a player
comes to know them. Picture only (no rule of the simulation changes).

**Who lives where** (`TownHouseholds.households`; a house's people are out only while it stands, a big house adds its
upper floor's lodger):

| house | household |
|---|---|
| 1, at the castle end | Mother Corra (to the market with her candles), Ned Furrow (out to the far field), Brede Hask (timber to the castle's gate); in a big house also Ilse Marrow (to the well) |
| 3, by the near field | the Ashbys: Gorm (the hoe), Hedda (the scythe), Wren |
| 4, by the well | the Brisks: Wenna (the well), Nib; Dun Rook lodges with them (sacks from the ford); in a big house also Master Edwy Tallow (to the tavern) |
| 5, by the square | Moth's: Silas Moth the lamplighter, Fen (his grandson, the lamp-runner), Old Hemmet (the bench before the door) |
| the castle | Saul Tolliver the collector lodges in the castle; his post is by the town gate (fix round 1) |

**The day:**

- **The farmers** (`TownLife.farmers`): Gorm and Hedda on the first built field, out from their door at first light
  (05:30) with the tools on the shoulder, eight strokes and the pause that straightens the back, home with a sack and a
  sheaf at a tired pace (seven tenths of their walk), in before the horn (by 18:51; from a far field they leave
  earlier).
- **Wenna** (`TownLife.washer`): to the well at 06:18 with her basket, wringing linen on its far side all day; home at
  18:09, and at the horn in her doorway calling the children in (the cupped hand, the beckoning arm), then in.
- **Old Hemmet** (`TownLife.bench`): on the bench before house 5 from 07:24 to 17:36, facing the square; now and then
  his chin sinks in a doze.
- **The passers-by** (`TownLife.walkers`, as many as the taxpayers allow): out from 07:00, each from beside their door
  to their place and back with a pause at both ends; from 18:30 home from wherever they are (earlier from a far
  place, so everyone is in before the horn).
- **The lord passes:** whoever stands still turns to him: the farmers straighten, Wenna straightens from the linen,
  Hemmet inclines his head, a passer-by pausing at an end faces him, the collector at his post turns. Below 30
  happiness they turn their back instead (the farmers work on). The footman never greets anyone.
- **The children** (`TownLife.children`): out from 08:00 while the town is content: none below 45 happiness, Nib and
  Wren from 45, Fen too from 80. They run out from their doors to their game before the Brisks' door, clear of Wenna
  at the well: across and back (Wren skipping the way back), then they meet in the middle and fight with sticks (one
  swings while the other winds up), part and begin again; Fen runs wider laps. One of them (Fen when he is out, else
  Nib) runs after the lord at his heels while he is near the play, stops when he walks on and runs back to the game;
  Wren waits for Nib meanwhile. At the horn they run home, each to its own door, all in by 19:45. Never out at night.
- **The noble's coach** (`TownLife.coachSpan`, `TownLife.footman`): on a day when a noble guest of the petition data is
  due (the noble petitioner, Steward Lorenz Pell of Oxmoor, Auditor Ebba Calder of Stillmere; in today's queue or heard
  today), the coach stands at the town's gate (on this branch the castle's back gate, facing it) from 06:00 to the dusk,
  the footman beside it on the town's side looking past everyone. The town gives it a wide berth (fix round 1): from
  30 px short of the coach to 30 px past the footman. Who has no business there (Brede on his way to the gate) stops
  at the berth's edge and stands looking at the coach a while; who must pass it on the one road (the builders, the
  collector, the lamplighter) steps out to the near side of the road, 4 px lower, and passes in front of the coach's
  people, never through the footman.
- **The collector** (`TownLife.collector`, on the days he walks): out from his post just inside the castle's town
  gate at the dawn, pushing the strongbox from door to door at a one-armed man's cart pace (18 px/s; the hand out, the
  coin through the slot, a nod), at the farthest door about 10:20, back at his post about 14:10, there until the horn.
  The director ruled (15.11. 03:39): he stays as built, the morning's figure as the lamplighter is the evening's (they
  never share the road); at the join the town lane moves `Town.collectorPost` from the hall door to just inside the
  castle's town gate (`TownLife.collectorPost`) and takes his hours (docs/lanes/people.md, "The director's fix pass").
- **The lamplighter** (`TownLamps`): each dusk Silas Moth comes into the hall by its chapel door, holds his
  pole's wick into the Eternal Light in the hearth in the late afternoon's warm light, bows his head to it, turns and
  carries the flame out through the castle's gate on his shoulder; when the light turns gold he lights the street
  lanterns one by one down the road with the pole raised (each with a small flare and a warm pool), the last one as the
  horn sounds, and goes home to his door. At first light (05:00) he walks back from his door putting them out with the
  snuffer, and goes in at the castle's gate. **The rule of the dusk** (the director, 15.11. 03:39; `TownLamps.plan`,
  data for any anchors, held by `TownLifeTests.testTheLamplightersEveningKeepsTheDirectorsRuleForAnyTown`): no street
  lantern takes the flame before 17:00, the last as the horn sounds; he takes the Flame between 16:00 and 16:30, never
  before 15:30; the lighting round at an old man's heavy step (16 px/s), the way from the hearth to the first post with
  the lit pole on his shoulder at up to the lord's pace (36 px/s), home after the last at the same. Counted back from
  the horn; what does not fit is cut in this order: the far posts (he lights by hand only the posts from the castle's
  side that the time from 17:00 to the horn allows), then the hearth beat earlier (to 15:30 at the earliest). The posts
  he does not reach stay dark in build 2. With this branch's anchors he reaches one post (house 1's; the second would
  need the Flame at 15:14): in the hall about 15:54, the Flame at 16:30, the shouldered walk at about 26 px/s, the
  lantern at the horn, home about 20:26; the morning's snuff about 06:22, in at the castle's gate about 07:39. The town
  lane sets its posts inside his reach at the join (docs/lanes/people.md). Build 3: the lit street grows with the realm
  (hamlet 3 posts, village 5, town 7), and from the village on Fen runs a taper from Silas' pole to the far posts; the
  street's lamps are the wealth arc at night. In unrest (below 15 happiness) nobody lights them; with the hearth out
  there is nothing to light them with; they burn as the hearth does (bright, low, embers).
- **Reduce Motion:** nobody is removed; breaths and fidgets hold one frame, the sticks stay raised, the linen is wrung
  at half the rate, no lantern flares.
- **The great hall**: the farmer (Ned), the widow and the farmwife (Corra) and the refugee (Dun) wait seated on the
  benches as before; the child petitioner is Fen, the noble petitioner Ser Aubrey; neither sits on a bench. Old Hemmet
  has a seated strip now (`elderSeated`, the townsfolk's seated contract) and could wait on a bench too.
- **Not placed yet**: the lady of the inner lands (the hall's spot where a noble stands apart with a footman, the stage
  lane; the coach's day brings the footman to the town's gate already).

## 6. In words too

The bar asks the same change of character in the lines (English and German). For the writers:

- **Working people** speak short and dry. "Field's in. Mostly." / "Das Feld ist drin. Größtenteils." — "Rope did it.
  Rope's fine." / "Das Seil war's. Dem Seil geht's gut."
- **Children** ask. "Is the dark cold? Does it have feet?" / "Ist die Düsternis kalt? Hat sie Füße?" — "Can I carry
  the lantern? Just to the gate?" / "Darf ich die Laterne tragen? Nur bis zum Tor?"
- **Nobles** speak in long polite sentences that say little. "One had so hoped the valley would be less… damp, though
  one is of course delighted to have come all this way." / "Man hatte so gehofft, das Tal wäre weniger … feucht, wobei
  man natürlich entzückt ist, den weiten Weg auf sich genommen zu haben."

## 7. The realm grows richer: what each one wears at each stage

Louis, 14.11.2026: "Wir machen unsere Burg, Königreich, Stadt, Land immer wohlhabender." The realm's three stages
(REALM.md section 2: hamlet at standing 0 to 2, village 3 to 6, town 7 to 10) change everyone's cloth alike: patched and
faded in the hamlet, mended and whole in the village (every patch gone, the undyed wool washed a value step lighter),
good wool with a little colour in the town. **Wealth changes the
cloth, never the people:** face, back, hands, posture, walk and the mark stay as life made them. In the sprites a state
is the same body with only cloth pixels recoloured (`tools/peoplestates.py`, the `#@state` lines in each grid; the
alpha of every frame is the body's, which a unit test checks). The town's dyes are muted and local (madder red, fir
and moss green, indigo, the house's blue, wine): never the nobles' saturated crimson, plum and gold, and never the
children's bright red.

| who | hamlet (as drawn) | village: mended and whole | town: good wool, a little colour |
|---|---|---|---|
| Mother Corra | an earth-brown dress with a darn at the back, a grey-cream apron, the faded teal shawl | the darn worked in, the dress washed a step lighter, the apron fresh | a madder-red dress, a fresh apron; the shawl stays her husband's, faded (her mark) |
| Dun Rook | a soot-grey tunic with a brown patch over the belly, boots worn through at the toes | the patch and the toes mended, the tunic washed a step lighter | a tunic of fir-green wool; the rag on his arm stays |
| Ned Furrow | an old brown vest, breeches patched at both knees | the knees mended, the vest oiled a step lighter | a vest of the house's blue over a clean shirt |
| Old Hemmet | an old brown cape with a patch, the smock pale with flour | the patch mended, the cape brushed a step lighter | a cape of wine-red wool; the smock stays a miller's |
| Wenna Brisk | a rock-grey skirt with a brown patch, a grey apron | the patch mended, the skirt washed a step lighter | an indigo skirt, a fresh apron; her raw arms stay |
| Brede Hask | a leather jerkin with a patch, rock-grey breeches, a grey sweat rag | the jerkin mended, the breeches washed a step lighter | breeches of fir-green wool, a clean brow rag; the rags on his foot stay |
| Gorm Ashby | an earth smock darned pale at the back, rags round the shins | the darn worked in, the smock washed a step lighter | a smock of moss-green wool, brown wool hose for the rags |
| Hedda Ashby | an earth-brown skirt with a patch, an undyed apron | the patch mended, the skirt washed a step lighter | a madder-red skirt, a fresh apron; the white hair stays |
| Nib Brisk | the washed linen tunic, the red kerchief and patch | as in the hamlet | the tunic dyed a pale blue; the red stays his |
| Wren Ashby | a linen smock under the red pinafore | as in the hamlet | a primrose smock under the red pinafore |
| Fen | the oiled jerkin, soil-brown breeches | as in the hamlet | breeches and belts of the house's blue |
| the seated three (Corra, Dun, Ned on the hall's benches) | as their standing bodies | as their standing bodies | as their standing bodies |

- The children have no village state: they were the bright thing already, and the atlas keeps the room.
- The nobles never change their cloth: the realm changes how they treat it (section 4, the bow).
- Ilse Marrow and Master Edwy (the petitioner bodies), Tobin Lathe and Osk Barrow (the builder and the guard) get their
  states with their repaint in people-2; the collector, the lamplighter and the jailer are drawn with theirs.
- The lord's own cloak goes from mended to good with the same stages (the director, 14:35); it is a repaint of the
  lord's sheet and waits for people-2 (docs/lanes/people.md).
- In the game: `PeopleCast.ClothState(standing:)`, `PeopleCast.dressed(_:_:)`; until the join passes the town's
  standing, everyone wears the hamlet's cloth (`-GWCloth village|town` shows the others for screenshots).

### The lord's own cloak (people-2 fix round 1; the director's note of 14.11. 14:35)

The lord is the heir of an old guardian house in a poor realm: dignity, and a mended cloak. In the **hamlet** and the
**village** the house's teal is faded to the town's old house colour (`waterDeep`), a patch of paler wool sits on the
back below the belt and a darned tear lower down (`kingMended`, `ladyMended` and their seated forms); in the **town**
the cloak is good and whole (the lord's sheets as painted). Only cloak pixels change; face, circlet, tunic, lantern and
bearing stay (`LordCloak`, docs/SPRITES-people.md "The lord's cloak").

## 8. The court's ties (people-2 fix round 1; the director's note of 14.11. 15:03, docs/HOUSE.md section 2)

The court is the lord's family and has ties among each other. Each member has one more idle of two frames that is
played toward another person (`CourtTies`, docs/SPRITES-people.md "The court's ties"): a nod, then the thread. The
hall decides at the join who turns to whom (the stage lane's rebuilt court); the objects are the HOUSE.md section 7
gifts and threads:

| member | the nod | the thread (frame 1) | toward whom, for example |
|---|---|---|---|
| Odile | a nod | holds out the ledger on her palm | the lord at the lectern; Marek (the feud over the books) |
| Brannock | a curt nod | holds out the iron key of the wall stair | the guard at the gate; the lord at dusk |
| Pip | a bob of the head | holds out a juggling ball | Tamsin in the kitchen; the herald (to make him look) |
| Mother Hesper | a nod | holds the nod with her hand on her heart | the lamplighter at the Flame (HOUSE.md section 6) |
| Tamsin | a nod | holds out a bowl of supper | Pip; the lord, however late |
| Bram | a nod | holds out the mended clasp between finger and thumb | the lord's chamber door (he says nothing) |
| Marek | a merchant's nod | the first orange of winter on his palm | Odile (a sample); the lord |
| Seren | a cool nod | a coin of her house's debt on her open hand | Hesper (two keepers, two fires: Hesper looks away) |
