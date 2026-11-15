# POLISH.md: the small things that lift the whole game

Louis, 15.11.2026: "was für kleinigkeiten kann noch das ganze game qualitativ spieltechnisch optisch nochmal auf
ein anderes level heben. Wir haben doch eigentlich auch eine engine gemacht wo die bäume zum wackeln bringt also
wind … ich finde wir können optisch noch mehr rausholen".

This is a plan, not an order to a lane. Build 2 stays closed (VERDICT.md's scope rule). The passes below start
after build 2 is out and after the review with Louis; that review may change their order.

## 1. The finding

The engine already knows the weather: `Core/Weather.swift` gives every day a wind class (calm, breeze, gusty,
storm), a direction, gusts and rain. Checked in `claude/lh-world` on 15.11.2026, the wind and the weather do this
today:

- the trees' crowns and the plants of the near, world and foreground planes sway (`FrameBuilder.swayLean`,
  `Weather.swayOffset`: bands of rows shifted by whole pixels; off under Reduce Motion);
- the chimney smoke drifts (`CastleSmoke`);
- the rain falls in three slants, the ground gets wet, puddles fill over an hour and drain over six (`Weather`).

It does not do this: the windmill is one still sprite, the houses' banners hang only inside the great hall, and no
flag, fire, cloth, grass, water or sound answers the wind. **The rebuilt castle is stone, and the player spends most
of his time there: where he stands, nothing answers the wind.** The same holds for the light and for the lord
himself. The rule for all three passes:

> Everything on screen answers one of three forces: the wind, the light, or the lord.

A still picture with a walking figure becomes a place. None of it is a new mechanic, a new screen or a new word.

## 2. Pass 1: the wind, seen and heard (first, because the engine is there)

Every item reads the day's wind sample that the trees read; calm days stay calm on purpose, so a storm is felt.

1. **Flags and banners** on the keep, the towers and the hall: limp when calm, flying in a breeze, snapping in
   gusts, toward the wind's direction. Three or four frames each.
2. **Fire leans:** torches, braziers, the statue's bowl and the lord's lantern flame lean and gutter with the gusts;
   their light pools flicker with them (one value, not a new light).
3. **The lord's cloak and the lantern on its pole:** the cloak trails against the wind when he walks into it and
   settles when he stops; the lantern swings twice and comes to rest.
4. **The windmill's sails** turn at the wind's speed and stand on a calm day (the sprite is there, still: the
   cheapest big gain of the pass). A **weather vane** on the bell tower.
5. **Leaves, chaff and dust** cross the yard and the lane in gusts (five to nine pixels' worth, never a curtain).
6. **Grass tufts, reeds at the landing, washing on a line** in the town, the market's awnings.
7. **The puddles hold light:** the rain's slants and the puddles exist; after rain the puddles on the lane mirror
   the windows' and the lantern's light, and a gust ruffles them.
8. **Sound:** the wind bed swells with the gust value; a banner snaps; shutters rattle in a storm. No music.
9. Reduce Motion: everything stands, as the trees do today.

### The two rains (Louis' idea, 15.11.2026)

Louis: "Cool wäre auch wenns auf der stadt seite normal regnet wenn es regnet und auf der schatten seite regnet es
keine ahnung schwarz oder asche oder hast du eine bessere idee?" The director's answer: **ash, and the light decides
which of the two falls.**

- **Where the light reaches** (the valley, the town, the castle): the rain as it is, fast streaks, wet stone,
  puddles. Near a lantern the drops glint warm.
- **Where it does not** (west of the outermost wall, toward the darkness bank): no water. Cold ash falls, slow and
  few, drifting with the wind; the ground there stays dry and grey. Fast streaks here, slow flakes there: the
  difference reads at once, by day and at night.
- **In the Throat** the one turns into the other over a few steps: fewer drops, darker, slower.
- **The lord's lantern:** a flake that falls into its light glows like an ember for a moment and is gone. He walks
  out there in a small circle of sparks. (The rule of section 1: it answers the light and the lord.)
- **The wind carries it:** on a day with the wind from the shadow land a few flakes come over the first wall into
  the bailey. Nothing happens by it; the player sees the dark come nearer.
- **A lit beacon** (build 3) is light that reaches: round it the rain is water again. The player sees by the weather
  how far his house's light goes.
- Not black rain: dark streaks do not read against a night picture, and by day they read as a fault.
- Cost: one flake sprite in three sizes, the rain's own emitter with another speed, one test of the light's reach
  per column. No rule in Core changes. Reduce Motion: the ash follows what the rain does under it today.
- Open for later, not decided: whether the ash is also a sign (more of it before a hard night).

## 3. Pass 2: the world answers the lord (feel)

1. **People notice him:** heads turn, a cap comes off, a bow from the old, children run beside him for a few steps.
   Nobles nod late (PEOPLE.md's three classes, shown by how they greet).
2. **Animals:** pigeons go up when he crosses the yard, crows leave the beacon ruin when he comes near, a cat on the
   wall walk, hens that scatter, a dog that follows him to the gate and no further.
3. **Footsteps by ground:** stone, timber (the landing, the bridge), grass, the hall's floor. A haptic tick only on
   timber.
4. **Doors:** the knock sounds by door (plank, iron-bound, the hall's), a crack of light opens before the person does.
5. **Coins:** each coin its own arc and a clink that rises through a toss; the purse at his belt swells (the full
   count is PAY.md).
6. **The horn changes the picture within two seconds:** birds up, shutters close window by window, people run home,
   the archers take the wall. The player should feel that he did that.
7. **Dawn after a held night:** a cock crows, doors open one by one, someone cheers at the gate. The relief beat
   that makes the night worth it.
8. **Weight at the wall:** a short hit-stop and a two-pixel shake when a wall is breached; dust falls from the
   crenels when a creature strikes it.

## 4. Pass 3: light and depth (the picture's finish)

1. **Windows light one by one at dusk** and go dark one by one late at night; a few flicker (TITLE.md's flicker).
2. **The lord's lantern warms the faces** he passes; people at night carry their own small lights.
3. **The eternal light** is seen from everywhere: a slow breath on the keep, a streak of it on the river.
4. **Water:** the river and the puddles mirror the near plane, broken by ripples; the moon's streak at night.
5. **Small lights:** fireflies in the meadow at dusk, moths round the lamp posts, the smith's sparks, stars that
   twinkle, a rare falling star.
6. **Morning mist** in the valley that burns off by eight; **lightning** in a storm that shows the whole castle for
   one frame.
7. **A foreground plane:** now and then a post, a branch, a banner or a cart's corner passes dark in front of the
   camera. Nothing gives a side view more depth for so little.
8. **Inside the hall:** dust in the window's light shafts, the hearth's flicker on the walls and on the people.
9. **Weather grading:** a storm day is colder and flatter, the evening after rain is the warmest of the week.

## 5. The bar: the two games Louis named (15.11.2026)

Louis: "schau dir mal Kingdom Two Crowns an und Yes, Your Grace Snowfall. Die games sehen so gut aus, denkst du wir
bekommen es so hin oder noch besser?" Seen: three store pictures of the first, four of the second (Steam). We take
their craft, never their look (DESIGN.md "Not a copy"; research-rendering.md's look-alike warning).

**What makes Kingdom Two Crowns look good**

- A calm picture: dark values, a muted palette, and two or three strong colours per screen (a red moon, a blue sail).
- Much room: the play is a thin band, the sky and the trees above it are tall, the figures are tiny.
- Depth by many planes of trees with haze between them.
- The lower third of the screen is water that mirrors the whole world, broken by sparkle lines. It doubles every
  light. **This is that game's signature; we do not take it.**
- Nothing stands on the picture. Rain, mist and shafts of light are fine and thin.
- Small figures that move very well.

**What makes Yes, Your Grace: Snowfall look good**

- Its rooms are built in 3D with real light: shafts through the windows, shadows that fall across floor and stone,
  blue haze between the trunks. We have a 2D engine; this technique is not ours.
- Warm light against cold air in every outdoor picture (a camp fire in a blue forest).
- Dark shapes in front of the camera (grass, a tent's edge, branches at the top) frame every picture.
- The camera is close: the figures stand a quarter of the screen high, so clothes and faces read.
- Portraits painted at high resolution.

**Where we stand (honest)**

- Our own critics give the world 6 of 10 and the interface 6.5 of 10 today. We are not at that bar yet.
- We have what the first game has not: light per pixel from every lantern and fire, wet ground, a weather engine.
  We have the clean picture since stage-3.
- We lack: the calm palette (too many things and colours per screen), frames per figure (an archer has five), a
  mirror for our lights, dark shapes in front, and the years of small fixes a studio has put in.
- The largest gap is motion, not the still picture. Stiff figures are where a game shows how it was made.

**What we take from it, in our own way**

1. **Our mirror is wet stone, not a river under the world:** after rain and at the landing the yard, the lane and the
   puddles hold the lanterns', the windows' and the eternal light's glow (pass 3, item 4). The river mirrors only at
   the valley's end, where it is.
2. **A palette rule per scene:** at night one cold ground colour and at most three warm lights in view; by day one
   accent per screen. The critic's squint test: with the eyes half shut the lord, the next thing to touch and the
   light must still read (a rule for every pass, not a pass of its own).
3. **Warm against cold everywhere:** our lights are warm, so the night's air, the gorge and the Gloom go colder.
4. **Frame the picture:** pass 3, item 7 moves up to its first place.
5. **The hall is our close shot:** the hall stage already shows big figures; faces, cloth and the hearth's light are
   judged there at Hild Varn's portrait's bar.
6. **Pass 4 below.**

**Can we get there?** In the still picture, yes: with passes 1 to 4 the game stands beside the first one without
looking like it. In motion it takes pass 4 and is the hardest part. Better than both in one thing is a fair aim: the
light. The game is about a light in the dark, and neither of the two makes light the picture's subject.

## 6. Pass 4: the figures move well

1. **The lord:** a walk of eight frames with the cloak's own motion, a turn, a breath when he stands, the pole's
   swing. He is on screen all the time; he gets the most frames.
2. **The people:** each of the three classes its own walk (PEOPLE.md). The named ones get a temper of their own
   (section 8); the rest get two idle habits per trade (the smith wipes his hands, the baker dusts flour off).
3. **The creatures:** a gait of their own per kind, a flinch from light, a dissolve that reads at phone size, all at
   the Ash Giant's bar (section 7).
4. **Follow-through:** nothing stops in one frame. Doors swing past their rest, signs sway after a touch, a tossed
   coin bounces once.
5. **The archers:** draw, hold, loose. Soldiers stay plain on purpose (section 8); this item is cut first.
6. Proof is by short clips from the runner, not by stills; the critic judges at full speed and at a quarter.

## 7. The creatures: the Ash Giant is the bar (Louis, 15.11.2026)

Louis: "die schatten monster was am besten gelungensten aussieht ist dieser schatten riese aber die neue version von
dir der sieht geisteskrank aus der komische ritter kackt rein." The giant is praised. The director reads "the odd
knight" as the Lightless King: he is the only creature that stands upright like an armed man, in a mantle with a
pole. If Louis means another one, the rule below judges that one the same way.

**Why the giant works** (`tools/creatures/ashGiant.py`, 110 px high, seven frames; strips seen on 15.11.)

- Its outline is not a man's: stooped under a cloak like a sail, the head lower than the shoulders, the arms almost
  to the ground.
- It has one light that tells what it was: the chest is a broken lantern with an ember heart between the ribs. It is
  the only warm spot on the figure, so the eye goes there.
- It has weight: planted feet, a stomp, dust.

**Why the king fails** (`lightlessKing.py`, 64 px high, seven frames). The idea is right: a void for a face, thorns
for a crown, a snuffer on a long pole, the tool that puts lights out. The figure is not:

- he stands upright and even, so he reads as a man in a cloak with a staff;
- he is little more than half the giant's height, and he is the boss of the last night;
- he has no light that reads at phone size (a cold ring round the cowl);
- his walk is a man's walk.

**The giant's rule, for every creature**

1. No man's outline: in plain black at phone size nobody takes it for a person in a costume.
2. One light of its own that tells what it was (the giant's lantern chest, the gloomweaver's dead violet lantern).
3. Its weight is decided and shown: it stomps, it scuttles, or it has none at all.
4. It answers the light: a flinch, and a death that reads (pass 4, item 3).

**The king, redrawn** (after build 2; the idea stays, the figure goes)

- **Tall and thin as a burnt wick:** taller than the giant and a third as wide, the tallest thing before the walls.
- **Bent like a hook, and he does not walk:** no feet show. He drifts, the cowl leaning out over what he looks at.
  The train is three times his length and crawls after him; the ground under it goes dark.
- **His light is a stolen one:** in the snuffer's bell one small warm flame is caught, the only warm thing on him.
  The bell is drawn big enough to read on a phone.
- **The lights he took:** dead lanterns hang inside the open mantle. An arrow that strikes knocks one loose; it
  breaks, and its light flies home to the castle as a spark. The player sees the fight go his way without a bar
  (picture only, read from his hit points).
- **He bends light:** the pools of light near him lean toward the cowl and thin out (picture only).
- **He is announced:** before he comes out of the bank, the torches on the outermost wall gutter one after another
  (pass 1's leaning fire).
- No rule in Core changes: night 20, his hit points, his harm and the dark ending stay as they are (REALM.md).

**The others:** the step opens with one sheet of all seven kinds in plain black, judged by the rule. The Ash Brute
(44 px) is next in line: in its strip it reads as a hunched lump with no light of its own.

**Cost:** a new rig in `tools/creatures/` and its strips. The bigger king does not fit on the atlas as it stands
(2048 x 1925 of 2048 rows used at stage-3), so pass 4 opens by making room for frames; how is the lane's choice.

## 8. A character of their own: the named people (Louis, 15.11.2026)

Louis: "Was uns auch fehlt ist das manche charakter nen eigenen charakter haben manche kinder sind aufgedreht manche
nicht manche dumm manche schlau. Oder alte menschen humpeln mit geh stock dicke dünne". And right after: "Aber eher
bei wichtigen charakter die soldaten können schon basic aussehen."

**What is there** (PEOPLE.md of the people lane; it comes with build 2, Louis has not seen it): the working people
with a name and a mark each, and three children. Old Hemmet walks bent double on a stick at half the others' pace.
Brede Hask limps on a foot bound in rags. Wenna Brisk is broad and heavy, Gorm Ashby long and lean. Nib, Wren and
Fen run and skip.

**What is missing:** they differ in how they look, not in how they are. All three children are quick; nobody is
slow or sharp, shy or loud. A person's character is what he does when the lord passes, when the horn sounds, and
when nothing happens.

**The rule:** every named person gets a temper: two words, set by hand, the same every day. Never a text and never
a number. The player learns it by watching; after a week he knows them without having read a name, and then the
night is about people he knows. The temper shows in five places:

1. **Pace and path:** straight or wandering, running or dawdling, with or without a rest on the way.
2. **When nothing happens:** two idle habits of their own (pass 4, item 2).
3. **How they greet the lord** (pass 2, item 1).
4. **What they do at the horn** (pass 2, item 6).
5. **How they stand before the throne:** the same person in the hall's close shot.

**The children**

- **Nib (7), wild:** never still. He runs ahead of the lord and back, jumps into every puddle, chases the hens; the
  stick is a sword. At the horn somebody has to drag him home.
- **Wren (9), clever:** she watches before she joins. At dusk she walks behind the lamplighter and plays his trade
  with a stick; when the lord tosses coins she counts along on her fingers. At the horn she is the first to look up,
  and she takes Nib by the hand.
- **Fen (11), quiet:** the lamp-runner. He walks at the lord's heel without a word (this is built), and stands
  looking up at the Eternal Light when he thinks nobody sees.
- **A fourth child, the dreamer** (new, comes as the town grows): the smallest, slow and happy. He stands and stares
  at a butterfly, a puddle, the windmill; he follows the others a few steps late; at the horn he is the last one
  out, and somebody comes back for him. Never the butt of a joke: the town looks after him.

**The old**

- **Old Hemmet:** the stick and the shuffle are drawn. New: he rests on the well's rim halfway; his bow takes so
  long that the lord has passed before it is done; at the horn he sets out first, because he needs the longest.
- **Mother Corra:** stops to talk with everyone she meets and is the last grown-up off the lane.

**Stout and thin**

- Lanternhold is poor (PEOPLE.md: "poor and even"), so thin is the town's body today.
- **Bodies show the realm's wealth:** PEOPLE.md section 7 changes each one's cloth by stage; the body follows.
  Master Edwy, the richest man in town, is the first to grow a belly under his apron. One of the two noble bodies
  of the inner lands is stout from the first day: the rich side looks fed.
- The test: in plain black at phone size every named person is told from every other by outline alone (height,
  width, posture).

**The soldiers stay plain** (Louis): the archers and the garrison share one body and one walk, on purpose. A uniform
reads as "the wall", and plain soldiers make the named ones stand out. Only the named are exceptions: Osk Barrow at
the gate, and Old Kell in build 3.

**Cost and order:** behaviour in the town's life (no balance rule changes), two or three short strips per person,
one new child body. The children first (the liveliest, and small bodies are cheap), then the old, then the rest by
how often the lord meets them. The step's first delivery is a column "temper" in PEOPLE.md's table.

## 9. Order and cost

- Each pass is one lane step with its critic, about half a day, on the sweep that the world lane already has
  (the wind needs sweep frames on a calm, a breezy and a storm day). Pass 4 is art work and takes about two days:
  one for the motion, one for the king's redraw (section 7) and the named people's tempers (section 8).
- Pass 1 first: most of it is art strips and one existing number. Then pass 2 (it carries the feel that Louis asks
  for with "deeds in the world"), then pass 3, then pass 4; the review with Louis may put pass 4 first.
- They run beside build 3's mechanics, not instead of them, and never touch a rule in Core.
- Cut order inside a pass is the list's order from the bottom up.
