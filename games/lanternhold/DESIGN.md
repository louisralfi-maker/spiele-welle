# Lanternhold: design

You are the king of a castle that seals a mountain gorge. By day you build walls, towers and fires in front of the
castle, walk through your halls, talk with your people and judge their petitions from the throne, while the town behind
the castle lives its peaceful life. By night the Gloom storms the gorge: a living darkness whose creatures shrink from
light. Arrows, fire and walls hold them back until dawn. If they reach the hearth fire in the throne room, the realm falls.

Landscape, side view, pixel art. Lighting carries the mood: warm fire against a cold night.

## Louis' decisions (08.11.2026)

- **Genre wish:** Louis' own idea, inspired by Kingdom: New Lands / Two Crowns (side-view build and defend at night) and
  Yes, Your Grace (throne-room petitions). It is NOT a copy: we share genre and mechanics only. See "Not a copy".
- **Direction:** the gorge ("A") out of three directions (A gorge and Gloom, B coast and black tide, C long wall and
  thorn forest). B and C stay as later chapters. Louis' adjustments to A:
  - no fuel or oil distribution (he found it dull); light stays important in battle, but nothing is rationed;
  - the town on the right is normal, functioning and beautiful; the war happens only on the left, at night, and it is
    fierce: arrows and fire must fly; the goal is that nobody dies;
  - citizens pay taxes, and taxes finance everything;
  - petitions like Yes, Your Grace, with plus or minus happiness as their main outcome;
  - nights are not very tactical ("like Kingdom, it is only one side").
- **Town and fields in 1.0:** yes, small, with fixed plots.
- **Structure:** chapters plus endless. Chapter 1 tells a story over 20 nights with a finale; afterwards the realm goes
  on endlessly (record of nights). New chapters (coast, long wall) come as updates.
- **Controls:** left thumb drags to walk, a context action button on the right, a realm strip at the top to tap-travel.
- **Light:** warm fire against a cold blue night, golden dawns and dusks, fog and embers (mood picture
  `docs/mood/ch1-gorge.jpg`).
- **Pixel density:** like the mood picture; figures about 30 game pixels tall. Kingdom Two Crowns is a reference for
  craft quality only, never for its look. The light prototype shows 180 against 135 rows so Louis can pick the
  chunkiness on real screenshots.
- **Plan:** build the whole 1.0 directly, without a separate public test version. Internally it is built in milestones
  (see "Milestones"), and the first one is the light and feel foundation, checked on the runner with screenshots.
- **Ads:** rewarded videos the player chooses (a merchant's gift, double taxes, a second chance) and a rare interstitial
  at the dawn report (at most every 2 to 3 in-game days, never at night or at the throne, none in the first days).
- **Tone:** serious and dark, with humor from the people, like Yes, Your Grace.
- **Name:** Lanternhold (English: lantern + stronghold). The same name in every language. Bundle id
  `com.louisherwick.lanternhold`, slug `lanternhold`. Free on the App Store (US and DE search, 08.11.2026); no game of
  that name found on Steam, itch.io or the web. Recheck when the App Store record is created.

## Louis' decisions (09.11.2026)

- **Looks first:** "gib alles beim Aussehen, das sieht man ja am meisten" and "Game muss extrem schön werden". The art
  bar ("Look", "Art bar") applies to every milestone.
- **The castle seals the gorge.** In the first night mock the castle read as a low wall, and the town still stood under
  the gorge cliffs. Louis wants a mighty castle that visibly blocks the only way out of the gorge, with the town
  outside.
- **Delegation:** he offered short loading screens between the gorge, the castle and the town. Then he left that choice
  and every further product decision to Claude ("entscheide alles selber, dass es ein top game wird"). Those decisions
  are logged below. His go before a submission and the legal answers stay his.

## Decisions taken for Louis (log)

| Date | Decision | Why |
|---|---|---|
| 09.11. | **Walk through, no loading screens.** The gorge, the castle and the town stay one continuous strip. At the castle's back gate the backdrop opens from the gorge into the valley. Long ways go by the realm strip. | Players of the genre value an unbroken realm, and an uninterrupted ride is what Kingdom's players praise most. The night battle stays in view while the king walks back. Walking out of the dark gorge through the gate into the bright valley is itself the clearest proof that the castle seals the gorge. And there is nothing to load on any phone. |
| 09.11. | **The castle is the hero of the world.** A facade facing the camera fills the gorge's throat from cliff to cliff. Two round towers rise above the top of the screen, the gatehouse has a portcullis, and the flanks grow into the rock. The keep with the realm's banners stands above the walls and can be seen from the gorge and from the town. | Louis: "die Burg sieht nicht so mächtig aus". Size, silhouette and backdrop must tell at a glance where the king is. |
| 09.11. | **The town lies outside, in the open valley:** a wide sky, rolling hills, far mountains, a river and a windmill. On the right the world ends at a broad river with the stumps of an old bridge; this replaces the waterfall and the end cliff. | It gives the strongest contrast: the narrow, dark gorge of the war against the bright, open land that the castle protects. |
| 09.11. | **The gorge wall is one continuous rock face** with a jagged top and a narrow strip of sky, never a row of repeated pillars. Over its last 200 px before the castle it rises and closes in. | In the first mock, the repeated cliff pairs read as hourglass pillars. |
| 09.11. | **Target pictures:** `docs/mood/world-castle-night.jpg` and `docs/mood/world-valley-golden.jpg`. They are Recraft concepts for composition and mood, not game art. | They are the reference for the art agents and for the review lens. |
| 09.11. | **180 rows** (not 135), from the runner screenshots of round `lh-m1-0`. | The castle must tower over the king and the gorge must feel deep: 135 rows crop both, and the battle needs the wider view (about 437 instead of 328 columns). The king stays readable at 30 px. |
| 09.11. | **Smooth light** (not banded or dithered). | It looks the most premium at phone size: crisp pixel art under soft glowing light. Bands read as cheap rings, and dither adds grain that blurs small shapes. `banded` and `dithered` stay as debug styles. |

## Not a copy

The research (`docs/research-market-art.md`) lists what makes Kingdom, Yes, Your Grace and Reigns recognisable. We never
use their names, characters, art, music, levels or look. In particular:

| Never | Instead |
|---|---|
| A ruler on a horse or any mount; mounts bought with gems | The king walks, carrying his old lamplighter's lantern on a hooked pole |
| Coins carried in a pouch and dropped at build sites, the coin drop as the only input | Gold in a treasury from taxes; a build card with prices at each plot |
| Vagrants in the wild recruited with coins, tools that set a job | Citizens are born in the town when people are happy; soldiers are recruited at the barracks |
| Masked enemies from portals that steal coins and the crown; losing the crown ends the run | The Gloom is a creeping wall of black fog with soot creatures; they want the hearth fire, never the king |
| Enemies from both sides | One front only, on the left; the gorge's cliffs close everything else |
| A water reflection strip along the bottom, the island campaign, boats | The gorge: cliffs framing the top of the screen, a castle cut-away, the town's lit windows |
| The Kingdom palette, its silhouette-heavy single band | Our own palette (see "Look"), interiors, vertical cliffs, light pools as readable game state |
| King Eryk, a queen and three daughters, a succession or forced-marriage story, Slavic folklore monsters | A lamplighter crowned because nobody else wanted the crown; the old king lost in the Gloom; original court and creatures |
| Yes, Your Grace's throne-room layout or ledger UI | Petitioners walk into a side-view great hall; a parchment card with 2 or 3 tap choices |
| Reigns' left/right swipe cards, four meters, "you die, next king" | Tap choices, one happiness meter plus gold and people, the realm continues |

Our own signatures: the king's lantern; the hearth fire in the throne room as the heart of the realm; light pools that
show where creatures cannot go; fire arrows lighting the night; walking from the battle line into a warm castle and on
into a peaceful town.

## Pillars

1. **Two halves of one life.** A beautiful, peaceful town and court by day, a fierce war of fire and arrows at night.
   The contrast is the experience.
2. **Your word shapes the realm.** Every decision changes gold, happiness or people, and many change the world you walk
   through: a mended bridge, guards on the wall, a missing bell, a dark window.
3. **Light is life.** The Gloom shrinks from fire. Every torch, brazier and fire arrow is part of the defence, and the
   light pools are readable game state, not decoration.
4. **One walk.** Front, castle and town are one continuous side-view strip, walked by one king. No travel menus, no
   loading screens.
5. **Made for a phone.** A day and night take about 5 minutes; the game saves at every dawn; two thumbs in landscape.

## The world (chapter 1: the Gorge)

One horizontal strip. `x` grows to the right in game pixels; the ground line is `y = 0`.

| x (game px) | Zone | What is there |
|---|---|---|
| 0 to 400 | The Gloom's mouth | The darkness bank rests here by day (a wall of black fog, soot motes, eye glints). Spawn point at x 40. |
| 400 to 1300 | The front (gorge floor) | Beacon site at x 470 (chapter goal; the ruined beacon tower stands on it, the warden statue is carved into the far wall behind it). Outer line at x 640, middle line at x 940, each with a wall slot, a tower slot, two brazier slots in front of it, an engine slot behind it and a trap slot in front. |
| 1300 to 2430 | The castle | The castle front 1240 to 1480 seals the throat: the gatehouse 1300 to 1420 (the inner wall: line 1, always built; its gateway 1337 to 1383, the wall walk at 124 px) between two round towers (1240 to 1297 and 1422 to 1479), the throat rock rising behind its flanks on both sides, the keep centred behind the gatehouse. Courtyard 1420 to 1700 (barracks, smithy, well, builders' lodge; its wall runs from 1580), great hall 1700 to 1960 (throne and hearth fire), chapel of the Flame 1960 to 2120, kitchen 2120 to 2240, back gate 2230 to 2430 between two smaller towers, its passage at 2330. |
| 2430 to 3680 | The town (in the valley) | Eight plots (houses 2480, 2800, 2900 and 3090, fields 2600 to 2760 and 3460 to 3620, market 3200, tavern 3320), market square 2990 to 3070 with the well at 3022, lanes, lanterns. |
| 3680 to 3900 | The river | A broad river with the stumps of an old bridge closes the world on the right (ground tiles end at 3712, the king's walk at 3760 on the bank); the far shore, forest and mountains beyond. |

- Lines unlock over the chapter: line 1 at the start, the middle line on day 3, the outer line on day 8, the beacon site
  on day 11.
- **The gorge (0 to 1300):**
  - Behind the front stands one continuous rock face (mid plane) with a jagged top, dead trees on the rim and a narrow
    strip of sky with stars and the moon.
  - In front, dark rock and hanging roots frame the screen (foreground plane).
  - From x 1100 the gorge closes in: the back wall rises to the top of the screen and the foreground rock thickens, so
    the castle stands in the gorge's throat.
- **The castle (1300 to 2430)** seals the gorge (see "The castle"). Inside the walls the cliffs still rise behind the
  courtyard.
- **The valley (2430 to 3900):**
  - Past the back gate the cliffs fall away and the land opens: a wide sky, rolling hills, a windmill, a river and far
    mountains.
  - The town lies here, outside the gorge, under open sky.
  - The back of the castle and the gorge's last cliffs close the view on the left; above the back gate the keep shows
    as a solid slate keep in the notch of the gorge mouth, rock on both sides, its windows lit at night (drawn into the
    mid picture with the mid haze but moving like the far plane; it fades in as the king nears the gate, so it never
    floats above the courtyard and the hall, and fades out again before the river end).
- **Backdrop regions:** each parallax plane has a gorge set and a valley set. On each plane the border between them is
  placed so that it lines up with the back gate when the camera is centred there: far 641, mid 1274, world 2330 (plane
  x, `WorldLayout.border`). The sets do not clip; a piece belongs to a set by where it stands.
- **The placement** of every sprite is `tools/scenemock/layout_m1b.py` (the mocks are rendered from it), ported to
  `Core/SceneLayout.swift`; `FrameBuilderTests` checks the port instance for instance.
- The sun rises behind the town (right) and sets behind the Gloom (left): dawn pushes the night back to the left.

## Day and night

12 real seconds per in-game hour (a full day of 24 hours is 288 s). The clock pauses during an audience, the dawn
report, story scenes and the pause sheet.

| Time | Phase | What happens |
|---|---|---|
| 06:00 | Dawn report | Night results, taxes collected, happiness change; then the game saves. |
| 06:00 to 19:00 | Day (156 s) | Build, recruit, walk the castle, hold audience, grow the town. Petitioners wait in the great hall. |
| 19:00 | Horn | A low horn sounds; petitioners not heard leave; builders return; the Gloom stirs. |
| 19:00 to 20:00 | Dusk (12 s) | Torches and windows light up; the darkness bank swells. |
| 20:00 to 05:00 | Night (108 s) | The darkness bank advances; 3 to 5 waves attack; the battle runs by itself. |
| 05:00 to 06:00 | First light (12 s) | The hearth takes no more harm: the realm has held the night. Creatures still alive dissolve into soot as the light sweeps in from the right. |

## Economy

Three numbers on the HUD: **gold** (a coin icon, never a currency symbol), **happiness** (a face with five states plus
0 to 100) and **people** (citizens, of whom some are soldiers). The tuning targets decide the numbers; the values below
are the ones tuned in M2a (see "Tuning (M2a)"). `Core/Balance.swift` holds every number, and `tools/tune.py` mirrors the
Swift economy by reading it.

### Taxes

Set at the throne: **Low**, **Normal**, **High**, and from story day 8 **War tax**.

`taxes at dawn = round(taxpayers × 5 × rate × mood) + fields + market bonus` (tuned from 1.6)

- `taxpayers` = citizens − soldiers; `rate`: low 0.6, normal 1.0, high 1.4, war 1.8;
- `mood` = 0.6 + 0.8 × happiness / 100 (0.6 … 1.4);
- each field adds 5; the market adds 15 % of the tax part;
- the dawn uses the happiness from before its own change; unrest (below 15) takes that dawn's taxes.

### Happiness (0 to 100, starts at 60)

Changes at dawn: low tax +3, normal 0, high −7, war −10 (tuned from −3 and −6); tavern +1; the chapel's blessing +1 (the
chapel of the Flame is part of the castle and cannot be built; story or a petition grants the blessing from M3 on, and
until then it never applies, so T4 was tuned without it); a night without losses +2; each fallen soldier −3; each
petitioner left unheard at the horn −1. Petitions add or take 1 to 10 at once.

| Happiness | Effect |
|---|---|
| 80 and up | +2 citizens per dawn while houses have room; children play in the lanes; builders 20 % faster |
| 60 to 79 | +1 citizen per dawn while houses have room; one free archer volunteers every third dawn at 70 and up (a new person, when a house has room) |
| 30 to 59 | normal |
| 15 to 29 | no growth, taxes −20 % (in `mood` already), people grumble with crossed arms |
| below 15 | one citizen leaves per dawn; unrest: no taxes on that dawn; a protest sign on the market |

### Start of chapter 1

60 gold, 14 citizens in 4 houses (room for 16), 3 archers and 2 guards among them, 2 builders (castle staff, not
counted as citizens), happiness 60, normal tax. Line 1's wall is the gatehouse: the gate stands from the start (4000 HP,
4 archer posts).

### Prices and build times (tuned in M2a; the time is for two builders)

| Thing | Gold | Time | Effect |
|---|---|---|---|
| Palisade (wall tier 1) | 20 | 8 s | 300 HP, 2 archer posts |
| Stone wall (tier 2) | 60 | 20 s | 800 HP, 3 archer posts |
| Bastion (tier 3) | 140 | 35 s | 1800 HP, 4 archer posts |
| Gate / iron gate / great gate (line 1) | stands / 90 / 180 | – / 25 s / 40 s | 4000 / 7000 / 11000 HP, 4 / 6 / 8 archer posts; a fallen gatehouse is rebuilt for half of what it cost so far: gate 50 (15 s), iron gate 95 (27.5 s), great gate 185 (47.5 s) |
| Rubble rebuilt | half the tier price | half the time | a destroyed wall comes back at its tier (the gatehouse: see above) |
| Archer tower / watchtower | 40 / 90 | 14 s / 22 s | 2 / 4 archer posts, range +15 % / +30 % |
| Brazier / fire tower | 12 / 40 | 4 s / 12 s | light radius 56 / 90, burns all night, needs no fuel |
| Ballista | 70 | 18 s | bolt 30 damage, pierces 3, every 3.5 s, range 240 |
| Catapult | 110 | 26 s | firepot 18 damage in 36 px, every 6 s, range 300; the fire lights radius 48 for 6 s |
| Stake pit | 15 | 6 s | 20 damage, 3 uses per night, re-armed at dawn |
| Archer / guard | 10 / 14 | at once, at the barracks | a taxpayer becomes a soldier; archer 20 HP, guard 30 HP |
| House / big house | 30 / 60 | 15 s / 20 s | room for 4 / 8 |
| Field | 25 | 10 s | +5 gold at dawn |
| Market | 80 | 25 s | +15 % taxes |
| Tavern | 50 | 18 s | +1 happiness per dawn |
| Builders' lodge | 60 / 120 | 20 s | 3 / 4 builders |
| Smithy | 60 / 150 | 20 s | archer damage +25 % / +50 % |
| Great Beacon | 110 / 200 / 330 | 30 / 40 / 60 s | three stages; the chapter's finale (tuned from 150 / 250 / 400) |

Builders work by day only and walk to the job. Walls damaged at night are repaired for free by builders the next day
(40 HP per builder per second, repairs before orders). Destroyed walls must be rebuilt.

## The front by day: building

- Fixed plots, marked by stakes and a small banner. Standing at a plot shows the build card above it: one to three
  options with price and a one-line effect; unaffordable options are greyed with the missing gold.
- Ordering costs the gold at once; the builders walk out and build. A build in progress shows scaffolding.
- Upgrades use the same card at a built plot.
- The barracks (courtyard) recruit archers and guards. Archers take the free posts on walls and towers by themselves,
  front line first (the outer line's wall and tower, then the middle line, then the gatehouse); archers without a post
  wait in the keep. Guards wait behind the gatehouse.

## The night: battle

The battle runs by itself. The player watches, walks the walls and helps in small ways. Little tactics are needed: the
outcome comes from what was built and recruited by day.

### Light rules (`Core/LightField`)

- Sources: braziers (radius 56, fire tower 90), torches on every wall tier (radius 30, burning on the wall walk: their
  lit reach of about 20 px lights the archers and the wall's top, such as crows flying over it or a brute rearing at a
  palisade, but never the ground at the wall's foot; what hacks at a wall is seen only in a brazier's, a fire arrow's,
  a firepot's or the lantern's light), fire arrows where they land
  (22 for 2.5 s), catapult fires (48 for 6 s), the king's lantern (40), the hearth fire inside the great hall (70), the
  Great Beacon when lit (840, a steady pool, see "The finale"; it is lit on night 20 the moment the Lightless King
  leaves the Gloom, burns until dawn and stays dark in endless). Castle and town windows light only the scene, not the
  battle.
- `illumination(x, y)` = the highest `(1 − d / r)²` of all sources, without flicker. A creature is **lit** at 0.12 or
  more, asked at the middle of its body but at most 24 px up (a giant whose legs stand in the light is lit). The rendered
  falloff draws a visible edge band exactly at that radius, so the player can read where the light ends.
- Lit creatures move at their lit speed, can be targeted by archers and ballistas, and the burning kinds lose health.
- Unlit creatures show only their eyes (two 1 px glints), move at full speed, and archers cannot see them. Catapults lob
  firepots at the densest group of eyes, lit or not, and light it up.
- The darkness bank advances at 20:00 to `x = 260 + 20 × night` (at most 600) over 20 s. Inside it, ambient light is
  ×0.4 and light radii ×0.6. It retreats at first light. When the Great Beacon flares up the bank falls back to x 360
  over 1.5 s (part of the flare), and the bank swallows the beacon's battle light: nothing left of its edge is lit by
  the beacon.

### Creatures of the Gloom (chapter 1)

Original designs: soot and shadow that dissolve into black motes, never masks, never goblins.

| Kind | From night | HP | Speed unlit / lit (px/s) | Harm | Size | Notes |
|---|---|---|---|---|---|---|
| Sootling | 1 | 8 | 34 / 12 | 4 per s to walls and soldiers | 14 px | swarms; burns 2 HP/s in light |
| Shadehound | 3 | 18 | 72 / 26 | 7 per s | 20 px | fast; leaps palisades (tier 1 only) |
| Soot crow | 5 | 5 | 55, flying | snuffs a brazier after 2 s on it | 12 px | ignores walls; can be shot while lit |
| Ash brute | 7 | 120 | 14 / 8 | 20 per s to walls | 44 px | never slower than 8; does not burn |
| Gloomweaver | 12 | 40 | 22 / 12 | none | 30 px | carries a 50 px bubble of darkness that cancels light inside it |
| Ash Giant (boss) | night 10 | 1000 | 10 / 7 | 60 per s; stomp shakes the screen | 110 px | |
| The Lightless King (boss) | night 20 | 700 | 24 in his own darkness / 12 in the Great Beacon's light | 150 per s, to the hearth too; 80 px darkness aura | 64 px | leaves at 20:50 ± 0:40 (10 s ± 8 s after nightfall; provisional, see the Tuning) and marches on the hearth; calls 6 sootlings every 15 s; can be hurt only inside the lit beacon's light, where his aura fails, he counts as lit and slows to his lit speed (see "The finale"); tuned from 2400 HP, 12 / 9 px/s and 40 per s |

- Night budget `B(n) = 16 + 9 n` points (sootling 1, hound 2, crow 2, weaver 6, brute 10), split into 3 waves on nights
  1 to 4, 4 waves on 5 to 14 and 5 waves on 15 to 20; the last wave leaves by 03:00. Boss nights add the boss.
- Creatures walk right along the ground and attack the first standing wall. A wall at 0 HP becomes rubble and is
  passable. Behind line 1 they enter the courtyard and head for the great hall.
- The waves start leaving between 21:15 and 01:50 (15 to 70 s after nightfall; later waves bigger), each within 10 s,
  so the last has left by about 02:40 (80 s), before 03:00; the Ash Giant leaves at about 21:40 (20 s ± 8 s after
  nightfall). At 12 s per in-game hour, n seconds after nightfall is 20:00 plus n × 5 minutes.

### The finale (night 20)

- The Great Beacon is chapter 1's goal and the only weapon against the Lightless King. A finished beacon (all three
  stages) is lit the moment the King leaves the Gloom and burns until dawn. The beacon decides the ending, not
  survival: a realm that never builds it and spends the gold on defence holds night 20 too (reported beside T6, not a
  target), but only the beacon can bring the King down, and only that gives The Bright Crown.
- **Its light** is a steady pool (radius 840 around the beacon at x 470). Its lit reach of about 550 px covers the gorge
  floor from the darkness bank's edge (x 360) to just behind the middle line's engine (about x 1018): the outer and the
  middle line, not the gatehouse. The darkness bank swallows its battle light (nothing inside the fog is lit by it), so
  the King leaves his darkness exactly when he steps out of the fog. The renderer draws the pool with a visible edge
  band at that reach, so the player sees where the King can be hurt; a sweeping beam may sit on top as decoration but
  never defines the rule.
- **Inside it** the King's darkness fails: his aura cancels no light at points inside the beacon's reach (wherever he
  stands; outside the reach it still cancels light), he counts as lit, he slows to his lit speed (12 px/s, like every
  creature in light), and archers, fire arrows, ballistas, catapults, stake pits and the guards in a breach hurt him.
  Archers and ballistas aim at him first while he can be hurt, so the night fills with arrows flying at him. The
  beacon's light is light for every other creature in it too: sootlings burn in it as in any light. A gloomweaver's
  bubble cancels the beacon's light for the creatures inside it but does not shield the King: the beacon breaks his own
  darkness, not theirs.
- **Outside it**, or without a finished beacon, he stays inside his own darkness and nothing can harm him: arrows,
  bolts and firepots that strike him glance off (a spark and a dull sound), archers do not aim at him, and the guards
  strike the next creature in the breach instead.
- **Cues** (sim events for M2b's sound, haptics and effects): the beacon flares up (`beaconLit`) and the bank falls
  back; the King's aura visibly shatters as he steps into the light (`kingAuraBroken`) and closes again if he steps
  out (`kingAuraClosed`); blows on him outside the light glance off (`glancedOff`).
- **When the King falls**, the Gloom recedes at once: every creature dissolves, the waves still to come stay away, the
  night is won, and dawn breaks at once (the clock jumps to first light, 05:00: the bank retreats over the last hour's
  12 s and the dawn report follows at 06:00). The dawn report records that the King was slain. This is the true
  ending: Aldric is freed. A King who falls in the step the hearth goes out does not count: the realm fell first.
- If he walks out of the beacon's light alive, or there is no beacon, the realm must hold until first light (05:00); at
  dawn the King withdraws into the Gloom with the rest, and the night counts as held. The chance is then gone for good:
  he never returns (endless has no King), and the dawn report says so.
- The fight takes a while: with the beacon he falls about a minute after he leaves the Gloom, after many volleys, at
  the middle line, with several seconds of light still left (T6 reports the kill times and the seconds of light he had
  left).

### Defenders

- **Archers** on walls and towers: range 150, a shot every 1.4 s, 4 damage, lit targets only, 20 HP. Every fourth arrow
  is a fire arrow that lights its landing spot (radius 22, 2.5 s): the night is full of streaks and short pools of
  light. They aim at the lit creature closest to the castle; on night 20 at the Lightless King first, while he can be
  hurt. When their wall falls they climb down and walk to a free
  post (or the keep); creatures that catch them on the way strike them.
- **Guards**: they hold the breach nearest the front (the innermost rubble in front of the first standing wall) and
  block it; without a breach they wait behind the gatehouse. 30 HP, 6 damage per s; below 30 % a guard steps back
  behind the hearth while another guard still holds (the rest of the blow goes to the next guard). The last guard
  holding has no one to pass the blow to: he stands his ground and can fall in the breach. A guard who steps back is
  out of the fight, and creatures let him go; guards marching out to a new breach can still be struck on the way.
- **Ballista and catapult**: crewed by castle staff, fire by themselves.
- **Losses**: soldiers can fall (sootlings and hounds reach archers on a broken wall; the last guard in the breach). Every
  fallen soldier is named in the dawn report and costs 3 happiness. A night without losses gives +2 and a small banner
  in the report.

### The king at night

- The king cannot be harmed; creatures ignore him (they want the fire).
- His lantern lights radius 40, and soldiers within 80 px shoot and strike 25 % faster (rally).
- At a damaged wall the action button offers **Patch** (10 gold, +25 % of the wall's HP, then 8 s cooldown).
- At a snuffed brazier the action button offers **Light** (free, 1 s).

### Losing a night

- The hearth fire has 100 strength. Each creature that reaches it drains 10 per s, a boss by its harm; at 0 it goes out
  and the realm falls.
- The defeat card offers:
  - **Second chance** (rewarded video, once per five nights): the hearth flares up, every creature inside the castle
    burns away and dawn comes at once; walls stay as they are;
  - **Replay the day**: load that day's dawn save.
- In endless mode a fallen realm ends the run (record), with the second chance once per ten nights.

## The castle: walking, people, guests

- **From the gorge**, the castle is a facade facing the camera that fills the gorge's throat:
  - two round towers, shaded as cylinders, end on screen in corbelled, crenellated crowns (y 132 to 172; polish after
    the art review, they rose above the top of the screen before);
  - the gatehouse has a deep arched gate with an iron portcullis;
  - the crenellations carry archers, braziers and banners;
  - flanks of masonry grow into the rock on both sides.
- **The keep** stands behind the gatehouse. Its crown and flag rise above the gatehouse between the towers' crowns. From
  the approach and the front its upper storey (crown, banner, lit windows) stands on a rock plateau in the middle
  distance (a mid-plane view, hidden at the gate), and from the town in the gorge mouth's notch (see "The valley").
- **The portcullis** drops with a heavy clang at the horn and rises at dawn. The king passes at any time, because the
  guards lift it for him.
- **From the town**, the back gate between two smaller towers is the castle's friendly face: banners, lanterns and
  flower boxes.
- The castle is drawn as a side-view building. When the king steps inside a room, its front wall fades out over 0.25 s
  and shows the cut-away interior in warm candle and hearth light; when he leaves, the wall returns.
- Rooms, left to right: gatehouse (stairs to the wall walk), courtyard (barracks, smithy, well, builders' lodge), great
  hall (throne, hearth fire, benches where petitioners wait), chapel of the Flame, kitchen, back gate to the town.
- The court lives there and walks small routines:

| Character | Role | Voice |
|---|---|---|
| Odile, the chancellor | the advisor; one line of counsel per petition | dry, sarcastic, loyal |
| Brannock, captain of the guard | asks for the front's needs | gruff veteran |
| Pip, the fool | comments after some decisions | says uncomfortable truths as jokes |
| Mother Hesper, priestess of the Flame | keeps the hearth fire | calm, a little ominous |
| Tamsin, the cook | knows every rumour | gossip with hints |
| Bram, the smith | arrows and blades | few words |
| Marek, the travelling merchant | deals, some honest | sly and charming |
| The Stranger (Seren, name revealed on day 15) | came from the Gloom's edge with a grey lantern | quiet, mysterious |

- **Talking:** the action button on a court member shows one speech-bubble line (gossip, a joke, or a hint about
  today's petitions, for example "Tamsin says Marek's arrows bend in the rain"). About 60 lines in 1.0, chosen by day
  and flags.
- **Guests** come on some days: Marek's cart, a wandering knight (Ser Ludo, comic), a bard, an envoy from the coast (a
  teaser for chapter 2), refugees from the Gloom's border. They stand in the courtyard or the hall and most of them
  come to the audience.

## The throne: audiences and decisions

- Each morning 2 to 4 petitioners wait in the great hall (day 1: one, for the tutorial). Story characters arrive on
  their days.
- Sitting on the throne (action button) starts the audience and pauses the clock. One petitioner at a time walks up.
  The parchment card shows the portrait, name and role, the request (at most 240 characters in English) and 2 or 3
  choice buttons (at most 40 characters each) with their gold cost or gain. An unaffordable choice is greyed with the
  reason. A small **Counsel** button shows Odile's one-line view (usually right, not always).
- After a choice: a short reaction (at most 140 characters), the HUD numbers animate, and some choices change the world
  at once (a statue, a guard posted, a stall on the market).
- The king may stand up at any time; the others keep waiting until the horn.
- The taxes are set on a lectern next to the throne (four buttons), any time by day.

### Petition data (`Resources/Petitions/*.json`)

```json
{
  "id": "well_repair",
  "speaker": "farmer",
  "kind": "random",
  "chapter": 1,
  "days": [2, 20],
  "weight": 3,
  "requires": [], "forbids": ["well_fixed"],
  "happinessRange": [0, 100],
  "text": "petition.well_repair.text",
  "hint": "petition.well_repair.hint",
  "choices": [
    {"label": "petition.well_repair.c1", "gold": -20, "happiness": 4, "flags": ["well_fixed"],
     "world": ["town.well.repaired"], "reaction": "petition.well_repair.r1"},
    {"label": "petition.well_repair.c2", "happiness": -3, "reaction": "petition.well_repair.r2",
     "schedule": [{"id": "well_dispute", "inDays": 3}]}
  ]
}
```

- Effects: `gold`, `happiness`, `citizens`, `archers`, `guards`, `builders`, `flags` (set or clear with `-name`),
  `world` (visual changes by id), `schedule` (follow-up petitions in n days), `unlock` (a build or the war tax),
  `night` (a modifier for the next night, for example `crows-1`), `chance` (`{"p": 0.5, "then": {…}, "else": {…}}`,
  rolled with the seeded random stream when chosen).
- Random petitions are drawn by weight among the eligible ones, never the same one twice in five days.
- Text keys live in `Resources/Story.xcstrings` (manual keys, English source, all eight languages). A unit test checks
  every key in every language, every `schedule` id, every `world` id and every `speaker`.
- 1.0 needs at least 80 petitions: 20 story, 45 random (town, front, guests, comic), 15 for endless only.
- Random petitioners get composed portraits (face, hair, hat, beard and clothes parts with palette swaps); story
  characters have their own portraits.

## The town

- The town lies outside the gorge, in the open valley behind the castle (see "The world").
- Eight plots on the right, fixed: four for houses, two for fields, one market, one tavern. Big houses replace houses.
- Citizens walk between houses, fields and the market square; they wave at the king; children play when happiness is
  80 or more; grumblers stand with crossed arms below 30. At night the windows glow and the lanes have lanterns.
- The town is never attacked while the castle stands. If the realm falls, the defeat card shows the town's windows
  going dark one by one.
- Petitions change the town visibly: the well, a bridge over the brook, a festival tent, a statue, a burnt barn.

## Story

### Chapter 1: The Lamplighter King (20 nights)

The Great Beacon at the mouth of the gorge has gone dark, and since then the Gloom comes every night. King Aldric rode
into it to rekindle the beacon and never returned. The court needed a new king, and nobody wanted the crown, except the
castle's lamplighter, who was too slow to run away. The crown is a little too big.

| Day | Beat |
|---|---|
| 1 | Prologue (three short panels, skippable). Odile shows the new king around. First petition (tutorial), first easy night. |
| 2 | Brannock asks for a tower. The building tutorial ends. |
| 4 | At dusk a stranger with a grey lantern asks to be let in. Yes or no sets `stranger_in`. |
| 6 | Marek offers cheap arrows. Tamsin's gossip hints that they are bad. |
| 8 | Brannock asks for a war tax. It unlocks. |
| 10 | Boss night: the Ash Giant. |
| 11 | Odile finds the old plans of the Great Beacon. The beacon site unlocks (three stages, days 11 to 18). She reads from the plans that the beacon's light breaks any darkness of the Gloom. |
| 13 | Refugees from the Gloom's border at the gate: let them in (+6 citizens, a risk later) or turn them away. |
| 15 | The Stranger, Seren, reveals that Aldric lives: the Gloom made him the Lightless King. Only in the Great Beacon's light can he be hurt, so the walls must hold him inside it until he falls. |
| 17 | A herald of the Lightless King comes to the audience: hand over Seren and the town is spared for three nights. |
| 19 | Last preparations. Pip's farewell joke. |
| 20 | The Lightless King attacks. If the beacon is finished, it flares up the moment he leaves the Gloom; in its light his darkness fails and the defenders can bring him down. If he falls, the Gloom recedes at once, dawn breaks and Aldric is freed (the true ending). If he gets past the beacon's light, or the beacon was never finished, the realm must survive until dawn, when he withdraws into the Gloom for good. |

Endings by the finale, happiness and key choices, in this order:

1. **The Ash Crown**: happiness below 30, whatever happened on night 20.
2. **The Bright Crown**: the Lightless King slain on night 20, happiness 60 or more and Seren not handed over: Aldric
   is freed.
3. **The Iron Crown**: every other case: the realm held until dawn without slaying the King, or happiness 30 to 59,
   or Seren handed over. A night 20 lost and saved by a second chance also ends here (the King cannot have been slain:
   the realm fell first). A realm that only held until dawn gets at best The Iron Crown, and the chance is final: the
   King does not return.

Each is a short scene of three panels; then the realm goes on in endless mode.

### Endless: The Long Watch

- Unlocks after chapter 1. **Continue the realm** keeps the chapter's end state and goes on with night 21; **New realm**
  starts fresh from day 1 with random petitions only.
- Nights scale with `B(n) = 16 + 9 n + 0.4 (n − 20)²` beyond night 20 (tuned from 0.15); random events (an eclipse with a double wave,
  a festival, a plague of crows). The events are not built yet (M3 or later); T7 was tuned without them and must be
  measured again when they arrive.
- Records: the highest night survived per mode (chapter, endless continued, endless new), kept in the save's
  Chronicle, so starting a new realm keeps them; a night saved by a second chance does not count as survived.

### Later chapters (updates)

- **Chapter 2: The Black Tide** (coast): the sea rises each night and things climb the cliffs; at low tide by day the
  king salvages wrecks; a lighthouse beam (mood picture `docs/mood/ch2-coast.jpg`).
- **Chapter 3: The Thornwild** (long wall): a living thorn forest grows toward an ancient wall each night; by day the
  king cuts it back for timber (`docs/mood/ch3-long-wall.jpg`).

## Progression and saving

- Within a chapter: lines unlock, upgrades, the town grows, the story moves on.
- Between modes: the Chronicle (a page of records: nights, endings, fallen soldiers, petitions heard).
- `SaveGame` (Codable JSON, `version`, new fields optional): the chapter and mode, the last dawn snapshot of the whole
  `GameState` (with flags and the realm's own records), the Chronicle (records per mode, carried from save to save, so a
  new realm keeps them), settings, ad pacing, hint flags. A field added later to any saved type, nested ones included,
  must be optional or decoded with a default (synthesized decoding ignores property defaults); `SaveGameTests` decodes a
  frozen version 1 save every round. Loading checks the plots against the realm (missing ones are added as on day 1,
  extra plots or plot indices out of range make the file corrupt). Written at every dawn and when the app goes to the
  background (the dawn snapshot only). A relaunch resumes at the last dawn ("Continue: day 7, morning"). A corrupt file
  is kept as a backup and the game starts fresh (as in Comet Cargo).

## Controls (landscape, two thumbs)

- **Walk:** touch anywhere in the left 45 % of the screen and drag sideways. The king walks toward the drag; more than
  40 pt from the touch point he runs. Lifting the finger stops him. Walk 36, run 80 game px/s.
- **Action button:** bottom right, an 88 pt circle with a 128 pt touch area. Its icon names what is in front of the
  king: a hammer (build or upgrade), a speech bubble (talk), the crown (sit on the throne), a flame (light), a patch
  (repair), coins (recruit). Hidden when there is nothing to do.
- **Realm strip:** a thin bar at the top centre shows the whole world (front, castle, town) with markers: petitioners
  waiting, a damaged wall, creatures at night, the king. Tapping a point walks the king there; any drag cancels it.
- **HUD:** pause top left (44 pt in a 60 pt area); gold, happiness and the day and clock top right.
- Cards (build, audience, report) take taps only; every button is at least 44 pt high, choice buttons 52 pt.
- Both landscape orientations. The HUD respects the safe area; the scene renders under the sensor housing, but nothing
  important sits in the outer 30 game px.

## Look

### Art bar (Louis: "extrem schön")

- **Store-ready:** every screenshot must work as a store screenshot. That means a clear focal point and three depths
  (backdrop, world, foreground), separated by aerial perspective, value contrast and fog, with warm light against cold
  shadow.
- **Places read at a glance** by silhouette and backdrop:
  - the narrow gorge: rock walls and a strip of sky;
  - the castle: towers above the screen;
  - the valley: open sky and a far view.
- **Always something to see:** no stretch longer than one screen without a feature worth looking at, such as a carved
  statue, a ruin, a bridge, a shrine or a waterfall.
- **No visible repetition:** tiles come in at least three variants, and nothing repeats at a fixed rhythm.
- **Readable at night:** the castle, the king and the creatures keep a rim of moonlight or firelight.
- **Review:** each milestone ends with an art-director review of the runner screenshots against the target pictures in
  `docs/mood/`.

### Palette (start; the art step fixes 32 to 48 colours)

| Token | Hex | Use |
|---|---|---|
| night0 | #0E0B1E | deepest night sky, soot |
| night1 | #1C1838 | night sky, far cliffs at night |
| night2 | #2E2A5C | violet slate, night stone |
| moon | #8C98D0 | moonlit edges, mist |
| stoneDark | #3A3346 | castle shadows |
| stone | #6B6078 | castle walls by day |
| stoneLight | #A99CA8 | lit stone |
| wood | #7A4E2E | palisades, beams |
| fireWhite | #FFF2C2 | hottest flame, light core |
| fireGold | #FFC65A | torchlight |
| fireOrange | #FF8A2A | braziers, embers |
| ember | #D9481F | dying fire, sunset accents |
| dawnRose | #F2A6A0 | dawn sky |
| dusk | #C8587A | dusk sky band |
| daySky | #9CCBDD | noon sky |
| meadow | #6E9A4A | fields and grass by day |
| banner | #2F6E8E | the realm's colour: teal-blue banners (not red) |
| gold | #E8B84A | crown, coins |
| parchment | #F1E3C4 | cards |
| ink | #2A2230 | text on parchment |

Night is cold (indigo and violet, desaturated), fire is warm and saturated. By day the gorge is ochre stone and green
fields under a pale sky. The realm's colour is teal-blue.

### Lighting model

- **Ambient ramp:** about eight keyframes per day (pre-dawn, dawn, morning, noon, late afternoon, golden hour, dusk,
  night), interpolated smoothly. Each sets the sky's top and bottom colours, the ambient colour and strength, fog colour
  and density, star alpha, sun or moon height, torch strength (torches fade in at dusk) and a colour grade. Night
  ambient is blue and dim (about 0.12 to 0.2).
- **Point lights:** `LightSource { x, y, radius, color, intensity, kind, flickerSeed }`; falloff `(1 − d/r)²`, slightly
  elliptic so pools sit flat on the ground; deterministic flicker from `(seed, sim time)`: intensity ±15 %, radius in
  whole pixels, a slight colour shift. Style choice `smooth`, `banded` (3 to 5 bands) or `dithered` (4×4 Bayer in game
  pixels); the prototype shows all three. A light stands on a plane: world lights light the world, the fog, the
  foreground and a share of the mid plane; a backdrop light (the warden statue's bowl fire on the mid plane, M1b) moves
  with its plane and lights only the mid plane, so it never paints the rock overhangs in front of it. Only world lights
  count for the battle.
- **Emissive:** flames, window glass (the painted dark panes inside a rect glow), lantern glass, embers, creature eyes,
  stars. Added after lighting; they feed the bloom. A sprite drawn later on the mid, world or foreground plane hides the
  glow behind it. Windows dim when the house sleeps.
- **Fog:** two drifting pixel-noise planes, one behind and one in front of the world; lit fog glows around braziers.
- **Light shafts:** sun beams through the gorge and castle windows at dawn and dusk; moonbeams at night.
- **Bloom** on strong lights, then the time-of-day grade.
- **The darkness bank:** negative light plus soot motes and eye glints; it dims lights inside it.

### Pixel scale

- Integer scale `s = max(2, floor(physical landscape height / 180))`; visible rows `H / s` (180 to 207), visible
  columns `W / s` (334 to 448). The render target has one extra column for smooth scrolling. The image is anchored at
  the bottom: the ground line is exact, extra rows show more sky. No letterboxing. Size from `UIScreen.nativeBounds`
  with `contentScaleFactor = nativeScale`. Full table: `docs/research-rendering.md` section 3.
- iPhone 17 Pro (runner): s = 6, 437 x 201. iPhone 17 Pro Max: s = 7, 410 x 189.
- Gameplay lives in a 180-row band; rows above it are sky and decor. Gameplay is designed for 334 visible columns.
- Sizes: the king 30 px with crown, citizens 26, soldiers 28, sootling 14, hound 20, brute 44, giant 110; palisade
  34 px high, stone wall 52, bastion 70, the castle's main wall 90, towers up to 120. Cliffs rise above the screen.
- `-GWVirtualHeight 135` shows the chunkier choice for comparison (135 to 155 rows).

### Art pipeline

- **Backdrops, buildings, interiors, portraits:** Recraft (`bash tools/recraft.sh`, model `recraftv4_1`, prompted pixel
  art; mood picture A proves the model can do the look) painted on a flat key colour, then converted to true pixel art
  by a pure-python pipeline: key the background, downscale by blocks (dominant colour, median fallback), map to the
  shared palette, clean orphan pixels, keep alpha binary. One image at a time, each run under 20 s (this Mac's heat
  rule). Details: `docs/research-market-art.md` section 2.
- **Characters and creatures:** pixel grids written as text (one letter per palette index, frames separated), turned
  into atlas pages at launch. Villagers and random petitioners are composed from parts with palette swaps. The king
  and the main creatures get hand-tuned grids, optionally started from a Recraft reference run through the pipeline.
  Frames: idle 2 to 4, walk 4 to 6, attack 3 to 5, hurt 2, death (dissolve) 4 to 6; mirrored for the other direction.
- **Format:** lossless PNG in `Resources/Art` (pixel art must not be HEIC: lossy compression smears the pixels), atlas
  pages at most 2048², padded by 2 px, nearest sampling.
- **Emissive masks** come from the palette: the fire ramp, window glass and eye colours glow. No normal maps.
- `ART.md` records every prompt, credit spent, result and reject, as in Comet Cargo.

## Feel

Sound effects and haptics only, synthesized in code (Comet Cargo's `Feedback` hub, `CueSynth`, `HapticHub`). Never
music, also no melodic jingles: signals only.

| Moment | Sound | Haptic |
|---|---|---|
| Archer volley (near the king) | string twang and air whoosh, randomised per shot, thinned out with many archers | none |
| Fire arrow | whoosh and a small crackle at the landing | none |
| Ballista / catapult | heavy wooden thunk / creak and a dull whomp, then a fire crackle | light tap / medium tap when on screen |
| Wall hit / wall breaks | stone crunch / rumble and crash | none / heavy thud and a short rumble |
| Creature dissolves | soft hiss and a puff of soot | none |
| Horn at 19:00 | a low synthesized horn, two long tones of the same pitch | slow rumble |
| First light | struck bell partials, then birds-like chirps from filtered noise | one soft swell |
| Taxes counted | coins with ticks | light taps |
| Build ordered / done | hammer taps / a solid knock | light tap / crisp tap |
| Choice made | soft stamp on parchment | light tap |
| Happiness up / down | a bright two-tone signal / a low murmur | soft double tap / dull bump |
| Footsteps | stone, wood or gravel by zone | none |
| Ambience | wind in the gorge, fire crackle near flames, a murmur in the town by day | none |

- Juice: a small screen shake for a breaking wall, brute and giant steps; arrow trails; embers rising; creatures
  dissolving into motes; the happiness face reacts; at first light the light sweeps from right to left. Reduce Motion:
  no shake, flicker amplitude ×0.25 and slower, no camera lag.

## Onboarding (no text walls)

Day 1 is guided by Odile's one-liners and the tapping hand from Comet Cargo: drag to walk (hand on the left), build a
brazier and a stake pit in front of the gatehouse (line 1's wall stands from the start; hand on the action button), walk to the throne (the realm strip pulses), hear the
first petition, set the tax, the horn, the first night (only a few sootlings), the dawn report. Each hint ends with the
player's first success and never comes back. `-GWSkipOnboarding YES` turns it off.

## Ads (AdMob, no purchases)

- **Rewarded**, always optional, the reward named on the button:
  - **Merchant's gift:** Marek's cart stands at the back gate on every third dawn: a video gives +40 % of that dawn's
    taxes (at least 15 gold);
  - **Double taxes:** a button in the dawn report, at most every second dawn;
  - **Second chance:** on the defeat card, once per five nights (once per ten in endless).
- **Interstitial** only at the dawn report, after the report has been read (on "Continue"): at most every third in-game
  day and at least 6 real minutes after any ad; never before day 4, never on a story dawn, never right after a rewarded
  video, never at night, at the throne or in a story scene. Also at most once after a chapter ending.
- Code from Comet Cargo and Piston Empire (`docs/reuse.md`): UMP consent, then ATT, then ads; test ad units in Debug;
  `maxAdContentRating = .general`; privacy manifest with `NSPrivacyTracking` false.
- The content outweighs the ads by far (80 petitions, a story, seven creature kinds), which also keeps AdMob's
  low-value rule and Apple's 4.3 far away.

## Languages and text

- English source plus de, fr, es, it, pt-BR, ja, zh-Hans. UI strings in `Localizable.xcstrings` (English in code);
  petitions, story and court lines in `Story.xcstrings` with manual keys.
- Volume: about 9,000 to 10,000 English words. Budgets: a petition 240 characters, a choice 40, a reaction 140, a court
  line 90; German runs about 35 % longer, so every card scrolls when needed and is checked in German, Japanese and
  Chinese screenshots.
- Merge translations with the checked pending-JSON script (Piston Empire `catupd.py`, adapted for two tables).

## Accessibility

- 44 pt targets everywhere, choice buttons 52 pt. Text never clips.
- VoiceOver: every button labelled; the scene is one element whose value summarises the state ("Day 4, 2 pm. Front:
  walls 80 %. Two petitioners waiting."), with actions for walk left, walk right and the current action.
- Cards use Dynamic Type up to the accessibility sizes and scroll.
- Reduce Motion as in "Feel". Creatures are readable by silhouette and eyes, not by colour alone.

## Screens

1. **Title:** the castle at dusk, the king's lantern; **Continue** (day and time), **Chapter 1**, **Endless** (locked
   until chapter 1 ends), settings.
2. **World:** the scene plus the HUD (realm strip, gold, happiness, day and clock, pause, action button).
3. **Build card:** above the plot.
4. **Audience:** the hall in the background, the parchment card in the lower half.
5. **Dawn report:** the night (creatures stopped, walls lost, the fallen by name, a banner for no losses), taxes in,
   happiness change and why, the ad buttons, **Continue**. After night 20 a large banner says whether the Lightless King
   was slain (`DawnReport.kingSlain`) or withdrew into the Gloom for good.
6. **Story panels:** prologue, beats, endings (three panels each, tap to go on, skippable).
7. **Defeat card** and **chapter end**.
8. **Pause sheet:** resume, settings, back to the title. **Settings:** sound, haptics, reset (with confirmation).

Navigation is a state machine in the model, no NavigationStack.

## Tech plan

The research is in `docs/research-rendering.md` (sources, evidence labels, numbers). The decisions:

### Rendering: a small custom Metal renderer

- **Not SpriteKit** (an open iOS 26 frame-rate regression with no workaround, and `SKLightNode` caps 8 lights per
  sprite), **not SwiftUI Canvas** for the world (every layer filled at native resolution, no frame-pacing control,
  silent shader failures). Canvas stays as Plan B if Metal does not run in the runner's Simulator.
- An `MTKView` inside SwiftUI (`UIViewRepresentable`); SwiftUI draws the HUD and the cards on top. Keep the HUD plain:
  no glass materials or animated menus over the running scene (FB20808104); pause the scene under full-screen sheets.
- **Low-resolution passes**, each about (W + 1) x H game pixels, private storage, `rgba8Unorm` for planes and
  `rgba16Float` for light and bloom:
  - planes: sky (stars, moon and sun, fixed to the screen), clouds (0.05), far (parallax 0.2), mid (0.5), fog A (0.9),
    world (1.0), fog B (1.15), foreground (1.3); each plane is one instanced draw of textured quads from an atlas, at
    its own integer camera offset `floor(cameraX × p)`;
  - emissive target: glow, window glass (the sprite's dark glass pixels inside a rect) and occluders, drawn in the
    planes' order with premultiplied-over blending, so a sprite drawn later on the mid, world or foreground plane hides
    the glow behind it;
  - light accumulation: cleared to zero, additive instanced light quads, falloff style smooth, banded or dithered;
  - bloom: threshold, half resolution, two separable blur passes.
- **One composite pass at native resolution** (a full-screen triangle). Per device pixel it reads each plane with
  `texture.read` at `floor((p + shift_i) / s)`, where `shift_i = round(frac_i × s)` device pixels: exact s x s game
  pixels, no shimmer, motion resolved to 1/s of a game pixel. World = albedo × (ambient + light) + emissive; fog =
  fog colour × (ambient + k × light); far planes take the ambient ramp; clouds are lit by the sky (sunlit tops by the
  ambient light, shaded bellies by the sky's top colour); at warm hours the far and mid planes haze toward lavender and
  keep only part of the warm light (aerial perspective); then bloom and the grade. Polish after the art review:
  firelight reflects 35 % as from a neutral surface and is capped at 1.6 (no cyan halo on teal cloth, no blown walls)
  and fades to a quarter a few rows under the grass; bloom is read once per game pixel, so glows step in s x s blocks;
  rock lips at the top never hang below y 139.
- **Actors** (king, people, creatures, arrows) are quads drawn in the composite at device-pixel positions, their texels
  still s x s blocks, lit by reading the light buffer at their position. This keeps the walking king steady on screen.
  The prototype compares this with snapped actors (`-GWActorMode smooth|snapped`).
- **Simulator rules** (Apple's "Developing Metal apps that run in Simulator"): no programmable blending (separate passes
  only); constant buffers at most 64 KB with 256-byte aligned offsets (instances go in `device` buffers); no sRGB render
  targets (`bgra8Unorm` drawable, textures loaded with `.SRGB: false`, colour maths in sRGB space); avoid the exotic
  pixel formats; no MSAA, no memoryless textures; atlases at most 2048². No Metal 4 APIs: the classic
  `MTLRenderCommandEncoder` path runs on the A12 (Apple5) and in the Simulator.
- Shaders live in one `Render/Shaders.metal`, compiled at build time, so a syntax error fails the runner build.
- **Proven on the runner (08.11.2026, round `lh-probe-1`, iPhone 17 Pro, iOS 26.5, Xcode 26.6):** the Simulator's Metal
  device ("Apple iOS simulator GPU") works; it reports only the **Apple2 and Common1** families, so every feature must
  stay inside Apple2 (at most 4 colour attachments per pass, no tile shaders, no imageblocks, no raster order groups,
  no programmable blending). Offscreen readback is exact (clear, nearest 4x blocks, additive lights in `rgba16Float`),
  and XCUITest screenshots show `MTKView` content with every game pixel an exact s x s block at s = 6 (180 rows) and
  s = 8 (135 rows), colours unchanged. The Metal Toolchain was already installed; the guard step took 20 s.
- 60 fps cap (no `CADisableMinimumFrameDurationOnPhone`); the sim runs a fixed 60 Hz step with an accumulator and never
  assumes a frame rate. The render loop stays swappable (`MTKView` internal, `CADisplayLink`, `CAMetalDisplayLink`)
  because of iOS 26 pacing reports. `isPaused` in menus and the background.
- `ProcessInfo.thermalState`: `.serious` drops bloom and one fog plane; `.critical` runs at 30 fps.

### Performance budget (iPhone XS / XR, A12)

| Item | Budget |
|---|---|
| CPU per frame | at most 4 ms (target 2) |
| GPU per frame | at most 6 ms (expected 2 to 3) |
| Draw calls | at most 30 |
| Sprite instances | at most 1,500 (design 300) |
| Visible point lights | at most 64 (design 16 to 40) |
| Low-res passes | at most 12 full-screen equivalents of about 90k pixels |
| Native-resolution passes | exactly 1 |
| Atlases | 1 or 2 pages of at most 2048², loaded at launch |
| GPU memory | under 40 MB |

The runner cannot measure speed. A TestFlight build with the stats overlay (`-GWStats YES`, or a hidden three-finger
tap in Release) is checked on an A12 iPhone and a current one before the store.

### Code layout (`games/lanternhold/`)

- `project.yml`: name `Lanternhold`, iPhone only, landscape left and right, iOS 17, full screen. Pattern:
  `games/hello/project.yml`.
- `App/`: `LanternholdApp.swift`, `GameModel.swift` (`@MainActor @Observable`: the save, the screen state, the sim
  driver), `DebugArgs.swift`, `SaveStore.swift`.
- `Core/` (plain Swift, no UIKit, SwiftUI or Metal, every type `Sendable`): `GameState`, `Sim` (fixed step 1/60 s),
  `DayClock`, `Economy`, `Battle` (creatures, defenders, projectiles), `LightField`, `Build` (plots, prices, builders),
  `Petitions` (data model, eligibility, effects, chains), `Story`, `Camera` (planes, `n_i` and `f_i`, the resolution
  rule), `SeededRandom` (SplitMix64), `SaveGame`, `Autoplay`. From M2a also `Realm` (the plots and places), `Balance`
  (every tunable number), `DawnReport`, `Names` and `TuningRun` (the bot runs behind the tuning targets).
- `Render/` (Swift + `Shaders.metal`): `Renderer`, `FrameDesc` and `FrameBuilder` (pure Swift: state to sprites,
  lights, emissives, fog, ambient, plane offsets), `Atlas` (pixel-grid text and PNG pages), `Passes`, `RenderStats`.
  `Render` holds no game rules.
- `UI/`: `GameView` (the `MTKView` and the HUD), `HUD`, `RealmStrip`, `BuildCard`, `AudienceView`, `DawnReport`,
  `StoryPanels`, `TitleView`, `PauseSheet`, `SettingsView`, `Palette`, `Components`.
- `Audio/`: the feedback hub from Comet Cargo.
- `Ads/`: from Comet Cargo / Piston Empire.
- `Resources/`: `Art/` (PNG), `Sprites/` (pixel-grid text), `Petitions/` (JSON), `Localizable.xcstrings`,
  `Story.xcstrings`, `PrivacyInfo.xcprivacy`.
- `Tests/`, `UITests/`, `tools/` (`tune.py`, the art pipeline scripts).

### Runner

- `scripts/ci/run-check.sh` gets a guard before the build of a game that has `.metal` files:
  `xcodebuild -showComponent MetalToolchain`, and if it is missing `xcodebuild -downloadComponent MetalToolchain`
  (about 700 MB; runner-images #13014 is open). Comet Cargo has no `.metal` file, so its runs do not change. If the
  download keeps failing: compile the same source at runtime with `device.makeLibrary(source:)`, with a unit test that
  compiles it.
- Labels for this game start with `lh-`.
- In-process screenshots do not show Metal content: UI tests use `XCUIScreen` captures, and GPU checks render offscreen
  into a texture and read the pixels back.

## Debug launch arguments

| Argument | Effect |
|---|---|
| `-GWReset YES` | fresh save (the save file is removed; the game starts a new realm) |
| `-GWScene world\|probe\|lightlab\|testpattern` | the game (default: the simulation drawn into the M1b world), the M1b light probe (the scene as placed for the shots, no simulation; `LightProbeUITests` use it), the light lab, or the pixel-grid test pattern |
| `-GWDay <n>` / `-GWNight <n>` | the seeded headless reference bot (`Autoplay.reference`, headless steps) plays a new realm to that day's morning (06:00) / that night's 20:00 and hands it over; the save is not loaded |
| `-GWTimeOfDay <0…1>` | clock position (0 midnight, 0.25 dawn, 0.5 noon, 0.8 dusk) |
| `-GWFreezeTime YES` | the clock stands still (flicker keeps running unless `-GWFlickerTime <s>` fixes it) |
| `-GWCameraX <px>` | camera position; the king stands there |
| `-GWAutoplay walk\|play` | the king walks back and forth / the reference bot plays live (it sets the king's intent and orders by its build order before every step; at night it lights snuffed braziers, patches and stands behind the front wall); any drag ends it |
| `-GWGold <n>` / `-GWHappiness <n>` | set the numbers (happiness 0 to 100) |
| `-GWBuild demo` | a built-up realm for screenshots: the iron gate, stone walls on the middle and outer line, an archer tower on lines 1 and 3 and a watchtower on line 2, braziers and a fire tower in front of the outer wall (it lights the approach, so the fight shows in its light), a ballista (line 2) and a catapult (line 3), stake pits on every line, the beacon at stage 2, smithy and lodge (3 builders), two big houses, two cottages, both fields, market and tavern; 24 citizens, 14 archers, 4 guards, happiness at least 70. At night every archer stands on his post at once and no build is in progress; by day the third beacon stage and the outer line's watchtower are being built, the builders at work |
| `-GWScreen title\|audience\|report\|defeat\|story` | open that screen with sample data |
| `-GWSeed <n>` | seed of the random stream |
| `-GWVirtualHeight 180\|135`, `-GWScaleOverride <s>` | pixel scale experiments |
| `-GWLightStyle smooth\|banded\|dithered` | light falloff style |
| `-GWActorMode smooth\|snapped` | how actors are placed |
| `-GWEffects all\|nobloom\|nofog\|minimal` | effect level |
| `-GWShowLowRes YES`, `-GWShowBuffer light\|emissive\|bloom\|fog` | debug views of the buffers |
| `-GWDebugLights YES` | light radius rings and ids |
| `-GWStats YES` | CPU and GPU ms, fps, thermal state, s |
| `-GWReduceMotion YES` | Reduce Motion without the system setting |
| `-GWSkipOnboarding YES` | no hints |

## Accessibility identifiers

`title-continue`, `title-chapter`, `title-endless`, `settings-open`, `world-root`, `world-scene` (its value carries
`frame:<n>` and `ready` once frames are stable after a freeze; in the game also `day:<n> hour:<h.hh>`, the
simulation's clock), `hud-gold`, `hud-happiness`, `hud-clock`, `hud-pause`,
`realm-strip`, `action-button`, `build-card`, `build-option-<id>`, `audience-root`, `audience-choice-<n>`,
`audience-counsel`, `audience-leave`, `tax-<rate>`, `report-root`, `report-continue`, `report-ad-double`,
`report-fallen`, `merchant-gift`, `defeat-root`, `defeat-second-chance`, `defeat-replay`, `story-next`, `story-skip`,
`pause-resume`, `pause-title`. Debug only: `debug-king-x`, `debug-camera-x` (values for the jitter test).

## Tests

### Unit (seeded, deterministic)

`DayClockTests`, `EconomyTests` (taxes, happiness, growth), `BattleTests` (light rules, targeting only lit creatures,
walls to rubble, the hearth), `LightFieldTests`, `BuildTests`, `PetitionTests` (eligibility, effects, chains, chance
rolls), `PetitionDataTests` (every key in all eight languages, every id resolves, budgets of characters per language),
`StoryTests` (beats on their days, endings), `CameraTests` (plane offsets; the king's on-screen jitter at most 1 device
pixel while walking in smooth mode), `ResolutionTests` (the device table), `FrameBuilderTests` (budgets, sorting, the
same seed and time give the same hash), `SaveGameTests` (round trip, old saves, corrupt file), `FeelTests`,
`MetalProbeTests` (logs the device and its GPU families, **fails loudly** without a device),
`OffscreenRenderTests` (clear, one quad, one additive light into small targets, read back, threshold asserts).

### Tuning targets (each a unit test in `Tests/TuningTests.swift`, mirrored in `tools/tune.py`)

1. A bot with the reference build order and normal tax survives nights 1 to 10 with the hearth untouched and loses at
   most 3 soldiers in total.
2. A bot that builds nothing loses on night 2 or 3.
3. The reference bot finishes all three beacon stages by day 18 with normal tax; with low tax all the time it cannot.
4. High tax all the time drops happiness below 30 by day 8; low tax all the time keeps it above 70.
5. Day 1 taxes buy 2 to 3 builds; by day 10 the reference bot owns 8 to 12 buildings.
6. Night 20 with the beacon is won by the reference bot in at least 8 of 10 seeds and the Lightless King is slain in at
   least 6 of 10 (his kill times are reported: about 25 to 70 s after he leaves the Gloom); without the beacon it is won
   in 3 to 6 of 10. "Without" is the same realm on the eve of night 20 with the beacon's last stage taken away, so the
   two runs differ only by the beacon. A whole run of a bot that never builds the beacon (its gold goes into the rest of
   the order) is reported beside it, not asserted. Margins are reported per seed: the seconds of the beacon's light the
   King had left where he fell (his walk to its edge plus the walls in his way, `Battle.kingLightLeft`), and without
   the beacon the seconds before first light at which the realm fell or the hearth's lowest strength where it held;
   `tools/simtune` also counts seeds 1 to 20, so the bands are chosen with margin, not on a coin flip.
7. In endless, the reference bot falls between night 35 and 60.
8. Each night's last wave leaves by 03:00; a night with 40 creatures keeps under 300 sprite instances and 40 lights.
   `TuningTests` keeps the sim-side proxy (drawn sim entities and battle lights on the night nearest 40 creatures);
   M2b's `FrameBudgetTests` counts the real frames: 40 creatures alive across the front of the manned demo realm with
   arrows in flight and fires burning, on four screens and seven camera positions, and a whole live night 12 at the
   app's step, every sprite instance and every light counted, the scene's windows and candles included.

### Tuning (M2a)

Measured on the runner with the bots of `Core/Autoplay.swift`: the sweep of round `lh-fin-fix-1` (`tools/simtune`, -O)
and the unit tests of round `lh-fin-fix-2` on the same balance (Debug gives the same numbers). Petitions and the story
are not in yet (M3), so the bots hear none; the chapel's blessing never applies yet; the endless events are not built.
Each of these moves the targets, so they must be measured again when they arrive.

| Target | Measured | Target value |
|---|---|---|
| 1 | nights 1 to 10 held in 3 of 3 seeds, hearth never touched, 0 soldiers lost | hearth untouched, at most 3 lost |
| 2 | the realm that builds nothing falls on night 3 (3 of 3 seeds) | night 2 or 3 |
| 3 | beacon finished on days 17, 17, 17; with low tax not by day 20 | by day 18; low tax cannot |
| 4 | high tax: happiness 25 at dawn 8 (without the chapel's blessing; with it, +1 a dawn, it would be 32); low tax: lowest 92 over dawns 8 to 20 | below 30; above 70 |
| 5 | first dawn taxes 49 gold buy 3 builds; 11 buildings by day 10 | 2 to 3; 8 to 12 |
| 6 | with the beacon night 20 won in 10 of 10 seeds and the Lightless King slain in 10 of 10 (20 of 20 over seeds 1 to 20), 60 to 68 s after he left the Gloom (59 to 68 over 20 seeds), at x 849 to 926 (the middle line, its wall still standing), with 10 to 19 s of the beacon's light left (8 to 19 over 20 seeds); without (the same realm, the last stage taken away) won in 5 of 10 (11 of 20): held with the hearth at 41, 79, 85, 78, 100, fell 6, 2, 0, 0 and 14 s before first light. Reported, not a target: a bot that never builds the beacon and spends that gold on the rest of its order holds night 20 in 10 of 10 | at least 8 won and 6 slain; 3 to 6 |
| 7 | endless: falls on nights 56, 45, 42 (seeds 1 to 3; seeds 4 to 6, reported: 47, 48, 48) | 35 to 60 |
| 8 | last wave leaves 80 s after nightfall (03:00 is 84 s); night 3 (38 creatures): 42 drawn sim entities, 11 battle lights (a sim proxy until M2b's `FrameBuilder` budget test) | by 03:00; under 300 and 40 |

Changed from the start values: tax per taxpayer 1.6 → 5; high tax −3 → −7, war tax −6 → −10; Great Beacon 150 / 250 /
400 → 110 / 200 / 330, its radius 600 → 840 (its lit reach ends just behind the middle line's engine); the Lightless
King 2400 → 700 HP, 12 / 9 px/s and 40 per s → 24 px/s in his darkness and 12 in the beacon's light and 150 per s,
leaving 10 s after nightfall (20:50; provisional, see the open points); endless growth 0.15 → 0.4. New numbers: the
gatehouse (4000 / 7000 / 11000 HP), archer 20 HP, archer posts per wall tier, the bank falling back over 1.5 s.

Night 20 in round `lh-fin-fix-2` (10 seeds; the bot's realm on the eve: gate tier 1, a stone wall on the middle line, a
palisade on the outer line, all three beacon stages):

- With the beacon: the King leaves at 20:15 to 21:15, the beacon flares up and the bank falls back to x 360. He walks
  out of the fog into its light at about x 360, slows to 12 px/s, and the archers and the ballista turn on him; the
  sootlings burn on the gorge floor in front of the outer line. The outer wall falls at 23:30 to 00:30 (the middle wall
  never). He falls at the middle line at 01:25 to 02:30, 60 to 68 s after he left, with 10 to 19 s of light left; the
  Gloom recedes, 32 to 47 creatures dissolve, the waves still to come stay away and dawn breaks. 0 to 5 soldiers fall;
  the hearth is never reached.
- Without it: the outer wall falls at 22:25 to 23:30, the middle wall at 23:50 to 01:05, the gatehouse at 02:55 to
  04:10; the Gloom reaches the hearth at 03:35 to 05:20, and the realm falls in the five seeds where the King reaches
  the hearth before first light (03:49 to 04:59). 0 to 2 soldiers fall.

Margins in round `lh-fin-fix-1`'s sweep (each variant changes one or two numbers; the "without" side does not depend
on the King's HP or lit speed, so those rows were measured beside 600 HP):

- The King slain (with the beacon): at 12 px/s in the light, 450 to 700 HP slain 10 of 10 (20 of 20) with at least 8
  s of light left; 800 HP leaves 3 s (the step check fails on seed 3), 900 HP slain 8 of 10. His lit speed matters
  most: at 10 px/s and 700 HP 14 to 26 s are left but the kill takes 63 to 73 s; at 16 px/s 700 HP leaves 3 to 11 s;
  at 24 px/s (the old rule, no slowing) 600 HP is slain 8 of 10 and 700 HP 3 of 10. The radius moves only the light
  left: at 700 HP 760 gives 3 to 15 s, 800 gives 6 to 17, 840 gives 8 to 19 and 880 gives 10 to 22. Kill times: 500 HP
  52 to 60 s, 600 HP 55 to 64, 700 HP 59 to 68.
- Without the beacon, 5 of 10 (11 of 20) at the standard: the King leaving 6 or 8 s after nightfall gives 4 (8 and 9 of
  20), 12 s gives 7 and fails (13 of 20), 14 s 6; his jitter 6 or 10 s 6 and 5; his harm 120 or 135 gives 8 or 7 and
  fails, 165 gives 2 and fails, 180 gives 3; his dark speed 20 gives 10, 28 gives 0; harm × 0.9 gives 9 and fails, × 1.1
  gives 6; beacon prices 120 / 220 / 360 give 5. The falls cluster near first light by nature: with 150 harm the King
  drains the hearth in under a second, so the realm falls when he reaches it, and his arrival is what this band tunes.
  The margin is in the count over 20 seeds (11, the middle of 6 to 12), not in the single seeds.
- T7 (endless): at 600 HP seed 1 held past the cap (T7 failed); at 700 HP all six endless seeds fall (42 to 56). 450
  to 650 HP and many other variants leave one of six seeds standing. 700 HP was taken over 600 HP for this reason only;
  T6 alone accepts 450 to 700.

Rules fixed in M2a:

- The finale (decided for Louis on 09.11.2026, see "The finale (night 20)"): a finished beacon is lit when the Lightless
  King leaves the Gloom (no longer at 04:30, 6 s before first light, when it barely mattered: in round `lh-m2a-fix-2` a
  bot that never built it held night 20 in 10 of 10 seeds). Without the beacon the King marches on the hearth as before;
  from first light (05:00) the hearth takes no more harm. Bosses drain the hearth by their harm per second.
- After the review of round `lh-fin-3` (round `lh-fin-fix-1`): in the beacon's light the King slows to his lit speed
  (12 px/s) and the beacon's lit reach ends just behind the middle line's engine (radius 840), so the kill no longer
  races the middle wall: at 760 and 24 px/s the reach ended 25 px behind that wall, the King walked out of it 1.5 s
  after it fell, and 600 HP was the edge. The darkness bank swallows the beacon's battle light and falls back over
  1.5 s; the King's aura fails at points inside the reach wherever he stands; the guards strike the frontmost attacker
  they can hurt (the King outside the light no longer absorbs their blows), for the front creature's attack time; a
  King who falls in the step the hearth goes out does not win the night; dawn breaks at once when he falls.
- Contact damage (creatures striking soldiers they walk past) is harm × the seconds the two spend within 8 px of each
  other while the creature walks, worked out from both paths through the step (`Battle.contactTime`); a creature that
  reaches a wall, the guards or the hearth during a step strikes only for the rest of it. Whether a soldier is on the
  ground is decided at the start of the step; one who reaches his post or the guard line during it is struck only
  while he still walks. Until round `lh-fin-1` the distance was sampled once a step.
- The last guard holding a breach stands his ground and can fall there; guards who step back are let go.
- Builders walk home when their work is done and at the horn.
- The lit beacon lights only the finale (`beaconEndlessRadius` 0); endless relies on what was built.
- The reference bot: a fixed build order (`Autoplay.referenceOrder`, rubble rebuilds first, waits at a locked or
  unaffordable step); at most half the people become soldiers; it replaces one fallen soldier a day while happiness is 60
  or more, keeps its gold while saving for the beacon (no patches then), and at night lights snuffed braziers, patches
  walls under attack below half strength (at most 3 a night) and otherwise stands behind the front wall.
- Headless runs step 1 s by day and 0.1 s at night; `SimTests` checks night 7, night 20 without the beacon (wall falls,
  the hearth reached, the outcome, soldier losses until the gatehouse falls) and the finale with the beacon (the
  outcome, the King slain in both runs or neither and within 3 s, soldier losses) against the 1/60 s step for seeds 1
  to 3 (`TuningRun.nightTwentyStepCheck`, which `tools/simtune` runs for every variant). T1's losses and the night-20
  losses are measured at 0.1 s.

Open points:

- The beacon decides the ending, not survival (accepted here, the lead to confirm): a realm that never builds it holds
  night 20 in 10 of 10, and with the beacon the bot's hearth is never reached; the night's tension is whether the King
  falls before he leaves the light. If night 20 with the beacon should carry more danger, a night-20-only pressure (a
  bigger budget, the King's summons appearing ahead of him) would move T6 and needs a retune.
- The step check passes at the standard but fails for 19 of the 58 variants of round `lh-fin-fix-1`: without the
  beacon mostly on seed 1, where the gatehouse falls 3 to 5 s apart between the step sizes once the King leaves earlier,
  strikes harder or softer or walks at another speed (or seed 3's outcome flips); with the beacon at 800 to 900 HP or
  16 px/s, where he dies near the edge of the light. Retunes must keep running it.
- Soldier losses after the gatehouse falls stay chaotic between step sizes (round `lh-fin-2`, seed 3 without the beacon:
  0 fall at 1/60 s, 2 at 0.1 s); the test compares losses only until the gatehouse falls.
- T7 hangs on whether an endless realm ever loses its gatehouse: when it does not, it holds past night 70 with the
  hearth untouched. The finale's numbers were chosen on T6; T7 only decided 700 against 600 HP. A steadier endless
  measure (more seeds as the target, or endless growth that also adds brutes) belongs to the endless work in M3, and the
  King's leaving at 10 s after nightfall stays provisional until then.
- With these bots the King always falls at the middle line, never at the outer line (its palisade falls in seconds).
- The realm's world numbers (`Realm.worldWidth` 3900, `walkEnd` 3760, the town plots 100 px right) landed together
  with the M1b world (merge of `lh-m1b-port`, 09.11.). `Tests/RealmWorldTests` pins every copy in `Realm` to
  `WorldLayout`: width, walk end, spawn, beacon, hearth, throne, the lines' walls, towers, engines and traps, and the town
  plots' centres.
- The braziers are not 5 px off: `WorldLayout.lines` gives a brazier's left edge (1250, 1274, 891, 915, 591, 612, where
  its 10 px sprite stands), `Realm` its centre and light (1255, 1279, 896, 920, 596, 617). The test pins that too.

### UI (screenshots `<nn>-<what>-<lang>`, English and German)

1. `testLightProbe` (milestone 1): the scenes and times of "Milestone 1" plus the pixel-grid check on the test pattern.
2. `testFirstDay`: `-GWReset YES`, onboarding on; walk, build, audience, night, report.
3. `testMidChapter` (`UITests/MidChapterUITests.swift`, M2b): `-GWNight 12 -GWBuild demo -GWAutoplay play`, shots at
   about 21:30, 23:00 and 01:00 (`30-mid-2130`, `31-mid-2300`, `32-mid-0100`), then `-GWDay 12 -GWBuild demo
   -GWCameraX 600` for the same realm by day with the builders at work (`33-mid-day`); the clock is read from the
   scene's value (`hour:`). `testFinale` (English): `-GWNight 20 -GWAutoplay play`, the beacon lit and the Lightless
   King in its light (`34-finale-2230`, `35-finale-2345`). The report comes with the UI step.
4. `testAudience`: `-GWScreen audience` in every language (the longest petition) for clipping.
5. `testFilmstrip` (English): a frame every 1.2 s through a dusk and a night, for the fun check.

## Milestones (internal steps to 1.0)

Louis chose to build 1.0 straight away. These steps follow the work method in `CLAUDE.md`; each ends with a runner round
(build, unit, ui, ui-de, release), a commit, and the review lenses for the big ones.

| Step | Content | Louis sees |
|---|---|---|
| M1 Light and feel | renderer, pixel scale, parallax gorge, day and night, lights, fog, bloom, the walking king, placeholder art; the runner's Metal probe | screenshots: front at dusk and night, castle, throne room, town; 180 against 135 rows; three light styles |
| M1b World and castle (09.11.) | the castle that seals the gorge, the continuous gorge wall, the open valley and the river end; new Recraft art for all of it; backdrop regions per plane; an art-director review against the target pictures | the castle at night from the gorge, the valley town at golden hour |
| M2 Core loop | plots, builders, walls, towers, braziers, creatures, the automatic battle, the hearth, dawn report, saving (M2a: the simulation and its tuning; M2b part 1: the simulation on screen, see below; M2b part 2: the HUD and the cards) | a whole day and night played by the bot |
| M3 Castle and court | cut-away rooms, court characters, talking, audience, petitions from JSON, taxes, happiness | the audience in German |
| M4 Town | plots, houses, fields, market, tavern, citizens' life, growth | the town by day and night |
| M5 Chapter 1 and endless | 20 nights of story, all creatures and bosses, the beacon, endings, endless, 80 petitions | the story beats |
| M6 Art, juice, sound | Recraft backdrops through the pixel pipeline, sprite grids, portraits, sounds and haptics | the real look |
| M7 Store | onboarding, ads, eight languages, tests, store screenshots, then the submission with Louis' go | the store page |

Honest timing: M1 about a day; M2 to M4 about a week; M5 and M6 about a week; M7 about a week. 1.0 in about three to
four weeks, released some weeks after Comet Cargo.

### Milestone 1 in detail (the next build step)

**Goal:** prove on the runner that the custom renderer works in the Simulator and that the look carries the mood:
warm fire against a cold night, true pixel art, smooth scrolling.

**Runner probe first (the first round):** `MetalProbeTests`, `OffscreenRenderTests`, the test pattern with an in-test
pixel-grid check (every game pixel an exact s x s block), the time of the Metal Toolchain guard. If the device is
missing or the pattern fails, stop and switch to Plan B (Canvas with pre-made pixel light sprites, `.multiply` ambient
and `.plusLighter` lights).

**Scene (`-GWScene world`), placeholder art made in code (no image work on this Mac):**

- sky gradient with stars and moon; far mountains (0.2); gorge cliffs (0.5); fog A (0.9);
- world: gorge floor from the darkness bank to the town; a palisade and a stone wall with torches; two braziers; a
  ballista; the castle front (gatehouse, towers, 10 windows) with the great hall as a cut-away (throne, hearth fire,
  candles); four town houses with lanterns, a field, the well;
- actors: the king with his lantern (walk cycle of 4 frames, idle of 2); 6 creatures with glowing eyes waiting outside
  the light; 3 archers on the wall; two citizens by the well;
- fog B (1.15); foreground grass and posts (1.3);
- drag to walk with the camera following; the action button lights or snuffs the nearest brazier (dynamic light);
- the day clock (12 s per hour) and every debug argument of the light lab group.

**Light lab (`-GWScene lightlab`):** a grey wall and floor with a grid of lights in three radii and two colours, for
falloff, bands, dither, bloom and fog.

**Screenshots (iPhone 17 Pro, s = 6; a subset on 17 Pro Max, s = 7):**

| Shot | Arguments |
|---|---|
| `01-front-noon` | `-GWCameraX 760 -GWTimeOfDay 0.5 -GWFreezeTime YES` |
| `02-front-golden` | the same at 0.75 |
| `03-front-dusk` | 0.8 |
| `04-front-night` | 0.95 |
| `05-front-dawn` | 0.25 |
| `06-castle-night` | `-GWCameraX 1360` at 0.95 (the king in the gateway; mock `m1b-castle-night`) |
| `07-hall-night` | `-GWCameraX 1830` at 0.95 (the cut-away throne room) |
| `08-town-golden` / `09-town-night` | `-GWCameraX 2900` at 0.75 / 0.95 (mocks `m1b-valley-golden`, `m1b-valley-night`) |
| `10-lab-smooth` / `11-lab-banded` / `12-lab-dithered` | `-GWScene lightlab` with each style |
| `13-front-night-135` | shot 04 with `-GWVirtualHeight 135` |
| `14-buffer-light` | shot 04 with `-GWShowBuffer light` |
| `15-front-night-minimal` | shot 04 with `-GWEffects minimal` |
| `16-hud-de` | shot 04 in German with the HUD |
| `17-castle-dusk` | `-GWCameraX 1360` at 0.77 (mock `m1b-castle-dusk`) |
| `18-backgate-golden` | `-GWCameraX 2330` at 0.75 (mock `m1b-backgate-golden`) |
| `19-courtyard-dusk` | `-GWCameraX 1650` at 0.77 (mock `m1b-courtyard-dusk`; the valley at golden hour is shot 08) |
| `20-river-day` | `-GWCameraX 3720` at 0.5 (mock `m1b-river-day`) |
| `21-approach-night` | `-GWCameraX 1100` at 0.95 (mock `m1b-approach-night`) |
| `22-beacon-day` | `-GWCameraX 470` at 0.5 (mock `m1b-beacon-day`) |
| `film-01` … `film-08` | `-GWAutoplay walk` at dusk, at least 0.5 s apart (about 1.5 s on the runner: one screenshot and one read of the scene value per frame), with the king's screen x and the camera x from the `world-scene` value (`king:` and `cam:`) for the jitter check |

**Unit tests:** `DayClockTests`, `FlickerTests` (deterministic, bounded, Reduce Motion), `LightFieldTests`,
`CameraTests`, `ResolutionTests`, `FrameBuilderTests`, `MetalProbeTests`, `OffscreenRenderTests`.

**Done when:** the round passes, the screenshots show the warm-against-cold look with readable light pools and crisp
pixels, the jitter check passes, and Louis has seen the pictures and picked 180 or 135 rows and a light style.

### M2b part 1 in detail: the simulation on screen (engine side, 09.11.2026)

The tuned simulation of M2a plays in the real renderer: a night battle with flying arrows, fire and creatures that read
lit and unlit, in the M1b world. The cards, the full HUD, sound and haptics come with the UI step.

**What was built**

- **The driver** (`Core/SimDriver.swift`, used by `App/GameModel.swift`): `Sim.step` at 1/60 s on an accumulator
  (at most 0.25 s of real time at once, so a stall never fast-forwards the world); the day clock is the simulation's
  hour (one truth: the HUD clock, the ambient ramp and the frame all read `GameState.hour`). No step while a card or
  the pause sheet is open (`GameModel.isPaused`, for the UI), while the app is not active (`scenePhase`), while
  `-GWFreezeTime` holds the clock or after the realm fell; time that passes meanwhile is dropped, never caught up. The
  walk pad sets the simulation's own king intent, `GameState.king.velocity` (the one `Autoplay` sets): walk 36, run 80
  beyond 40 pt. `-GWAutoplay play` lets the reference bot act before every step; any drag ends it. At night the action
  button lights a snuffed brazier or patches a damaged wall (`Sim.kingAction`); the rest of the day's actions come
  with the cards. The camera follows the simulation's king step by step.
- **The scene filter** (`Core/SceneFilter.swift`): game mode keeps the M1b world but hides, by sprite id and x, every
  placeholder of something the simulation owns: the front's palisade (640), stone wall (940), their four torch posts,
  the ballista (676) and the two braziers (891, 915), the beacon ruin once a stage stands or is being raised, the four
  cottages and two fields on the town plots. The hearth keeps its sprite but loses its fire and light (the
  simulation's hearth burns by its strength); the scene's archers, creatures and citizens leave; the darkness bank
  stands at the simulation's edge. The castle front's own wall-walk braziers, gate torches and lantern stay scenery.
- **The entity frames** (`Core/EntityFrames.swift`, a hook of a few lines in `FrameBuilder.build(…, entities:)`):
  - buildings per plot by item and tier as world-plane props (lit like the world, hiding the glow behind them, under
    the darkness bank): walls whole or damaged (frame 1 below 50 % HP), rubble (`rubbleWood` for a palisade,
    `rubbleStone` otherwise), scaffolding tiled over every build in progress, a `plotMarker` on every empty unlocked
    plot by day;
  - line 1: the gate overlay in the castle front's gateway (x 1337): closed from the horn to dawn and while a
    creature is within 260 px, open by day, the damaged frame below half strength, `gateBroken` when it falls;
  - towers (lines 2 and 3), braziers and fire towers with their `brazierFlame` (flickering with the battle light's
    seed, gone while a crow has snuffed it), engines with their firing frames from the reload time (a ballista loosed
    for 0.6 s after a shot; a catapult throws for 0.5 s and winds for the last 1.4 s), stake pits armed or sprung, a
    torch post with a flame at every battle torch light (the simulation's wall-walk torches);
  - the beacon's stages on the ruin's footprint, `beaconFire` in the great beacon's bowl while it burns (brighter
    for 1.5 s as it flares up);
  - the courtyard in a row after the castle front: barracks (always), smithy (with its forge fire and a small
    scene light), the scene's well, the lodge; the town by plot state: the cottages exactly as the scene drew them,
    big houses, fields, market and tavern, with their window glass masks and window lights (scene-only);
  - actors in device pixels: townsfolk by day (visual only: between their houses and the well, the market, the
    fields and the tavern, about one for every two taxpayers, 2 to 9), builders walking and hammering, creatures,
    guards on the ground (in the breach striking while creatures press them, marching, waiting by the gate), archers
    on their posts (drawing in the last 0.45 s before a shot, loosing for 0.18 s after it, facing the most advanced lit
    creature in reach), projectiles, effect particles, the king last;
  - creatures by kind and action: walk 0 to 3 by the distance walked, attack from 4 by time; the crow flies and
    perches, the gloomweaver floats; the two sootlings alternate by creature id. Lit (`Creature.isLit`, the battle's
    truth): the body as painted plus its glow strip; unlit at night: the glow strip over the body at 0.2 of its value
    (scaled with the torch strength, so bodies show by day);
  - projectiles on the simulation's arcs (`Projectile.position`), frame by vertical speed (rising, flat, falling at a
    slope of ±0.3), mirrored when flying left, drawn emissive (arrows and bolts as pale, moonlit shafts, fire arrows
    and firepots burning) with a `streak` trail in the emissive pass that feeds the bloom; a fire arrow carries a
    flame at its head; where fire arrows and firepots land, flames burn as long as their light;
  - the Lightless King's aura: two mirrored `gloomBubble` halves (192 px, his 80 px aura) on the world plane while he
    is outside the beacon's light (a gloomweaver carries one too); `kingAuraBroken` bursts it into teal sparks and soot
    shards flying outward, `kingAuraClosed` draws them in again, `glancedOff` strikes a spark where a blow glances off
    him; creatures dissolve in a puff of soot and an ember, a falling wall throws dust. At most 24 effects and 24
    particles a frame (`Core/BattleEffects.swift`).
- **Lights:** the battle's lights come from `Battle.lightSources` (one truth for what is seen and what is lit): the
  wall-walk torches, braziers and fire towers, the glows of fire arrows and firepots, the king's lantern, the hearth
  and the lit beacon. The hearth's light shows its strength (intensity × 0.35 + 0.65 × strength; its radius stays the
  simulation's). Scene lights stay scene-only (`SceneFilter.sceneLights`). The Great Beacon's pool no longer flickers
  (`LightKind.beacon.flickers` is false), so the smooth light style's step at the lit threshold draws its edge band
  exactly at the battle's reach and holds still.
- **Sprites:** every id of `SPRITES.md` is a `SpriteID` with its size and frame count (the king's walk 0 to 5, idle 6
  to 7, command 8 to 9; townsfolk, archer, guardsman, builder, creatures and glow strips, buildings, overlays,
  projectiles), plus four procedural effect sprites (`spark`, `shard`, `gloomBubble`, `streak`). Readable procedural
  placeholders for all (`Render/PlaceholderCreatures.swift`, `PlaceholderPeople.swift`, `PlaceholderStructures.swift`),
  windows painted in the glass colours at the art lane's anchors. The atlas repeats the last frame of a strip that is
  shorter than its frame count (the one-frame palisade, stone wall and ballista until the art lane's land); the page
  is 1024 x 1494 with every placeholder (it stays one page under 2048²).
- **Debug arguments** (`App/GameStart.swift`): see "Debug launch arguments": `-GWScene probe`, `-GWDay`, `-GWNight`,
  `-GWBuild demo`, `-GWAutoplay play`, `-GWGold`, `-GWHappiness`, `-GWReset`, `-GWCameraX` in the game.
- **Saving** (`App/SaveStore.swift`): the dawn snapshot (the realm right after the dawn step) is written at every dawn
  and when the app goes to the background; launch resumes it; a corrupt file is kept as `save-corrupt-<seconds>.json`
  and the game starts fresh; the Chronicle carries from save to save; `-GWDay`, `-GWNight` and `-GWReset` do not load
  it.

**Decisions taken (M2b part 1)**

| Decision | Why |
|---|---|
| The game is the default scene; the M1b scene as data is `-GWScene probe`, and `LightProbeUITests` pass it. | Explicit: the light probe's shots stay comparable with the mocks and the art reviews, the game never guesses from other arguments. |
| Glow strips are drawn as emissive actor quads right after their body, in device pixels, not in the low-resolution emissive pass. | The emissive pass lies in whole game pixels under the actors: a strip there would be up to a game pixel off its body and hidden by the body's opaque pixels. "Additive" becomes "over at full brightness": the strip's pixels are the glow colours, which over a dark body looks the same. (A deviation from SPRITES.md's wording for the lead.) |
| Towers of lines 2 and 3 are drawn just behind their wall (overlapping it by 4 px, behind it) and the engine behind the tower; archers stand on the drawn posts; a projectile starts at the drawn shooter and the offset fades out over its flight. | The plots put the tower inside the stone wall's footprint (662 against 640 to 676), where a 48 px tower vanished behind a 52 px wall. The simulation's positions stay the truth: every arrow lands where the simulation lands it. Builders drift onto the drawn place in the last 60 px of their walk. |
| Line 1's archers stand along the painted wall walk (y 124, x 1306 to 1412), its tower archers at the walk's ends by the towers, its engine on the walk by the right tower (x 1404). | The round towers' crowns (y 132 to 172) sit at the top edge of a 175-row screen: an archer there would be cut off. The engine's plot (1440) lies behind the castle front's right tower. |
| The courtyard's row: barracks 1481 to 1545, smithy 1546 to 1606, the well (scene), the lodge centred at 1648. | The castle front ends at 1480 and the hall begins at 1700; DESIGN lists barracks, smithy, well, lodge. |
| Unlit creatures at night: body × 0.2, glow strip at full. | A dark silhouette with ember eyes reads as "in the dark" against the night ground and the fog; at alpha instead of value, crowds would punch holes into each other (actors do not blend). |
| `-GWBuild demo` drops leftover orders and posts every archer at night, and leaves two builds with the builders at work by day. | The night shots show the fight without scaffolding; the day shot shows the builders. |
| `-GWAutoplay play` shows no debug readouts (they stay for `walk` and `-GWStats`). | The mid-chapter shots must work as store screenshots. |

## Risks

| Risk | What we do |
|---|---|
| Metal in the runner's Simulator (resolved: it works, Apple2 features only) | Stay inside the Apple2 family; Plan B (Canvas with pixel light sprites) is no longer needed |
| GPU code written blind, wrong pixels are the only symptom | Build-time shader compile, readback tests, buffer debug views, only well-known techniques, Simulator subset |
| Real-device speed and iOS 26 frame pacing unmeasured | Low-res design with big headroom, stats overlay, a TestFlight check on an A12 phone, swappable render loop |
| Metal Toolchain missing on `macos-26` | The guard step; runtime compile as the fallback |
| Too close to Kingdom | "Not a copy" table; review lens for look-alikes before the store; our own palette and signatures |
| Scope: 1.0 is much bigger than Comet Cargo | Milestones with runner rounds; content in data files; the chapter structure lets 1.0 ship with one chapter |
| Text volume (about 10,000 words in eight languages) | Strict budgets per card, the checked merge script, German, Japanese and Chinese screenshot checks |
| AI pixel art not grid-true or inconsistent | The pipeline (blocks, palette, clean-up), characters as hand-tuned grids, review of every piece as a player |
| Budget (weekly limit shared with Piston Empire and Comet Cargo) | Check the usage before each workflow, sonnet for routine work, stop at 80 % |
| Only iOS 26 simulators on the runner, A12 phones run iOS 17 or 18 | Plain Metal and plain SwiftUI; the TestFlight check |
