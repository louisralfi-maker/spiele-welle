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

## 5. Order and cost

- Each pass is one lane step with its critic, about half a day, on the sweep that the world lane already has
  (the wind needs sweep frames on a calm, a breezy and a storm day).
- Pass 1 first: most of it is art strips and one existing number. Then pass 2 (it carries the feel that Louis asks
  for with "deeds in the world"), then pass 3.
- They run beside build 3's mechanics, not instead of them, and never touch a rule in Core.
- Cut order inside a pass is the list's order from the bottom up.
