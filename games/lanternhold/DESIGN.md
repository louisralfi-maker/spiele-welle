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
    strip of sky with stars and the moon. It is one value step flatter than the near rock and its foot dissolves in a
    bright haze band by day (scene polish 2), so the gorge reads deep.
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
| 05:00 to 06:00 | First light (12 s) | Creatures still alive dissolve into soot as the light sweeps in from the right. |

## Economy

Three numbers on the HUD: **gold** (a coin icon, never a currency symbol), **happiness** (a face with five states plus
0 to 100) and **people** (citizens, of whom some are soldiers). Every value below is a start value; the tuning targets
decide the final numbers (`tools/tune.py` mirrors the Swift economy, as in Comet Cargo).

### Taxes

Set at the throne: **Low**, **Normal**, **High**, and from story day 8 **War tax**.

`taxes at dawn = round(taxpayers × 1.6 × rate × mood) + fields + market bonus`

- `taxpayers` = citizens − soldiers; `rate`: low 0.6, normal 1.0, high 1.4, war 1.8;
- `mood` = 0.6 + 0.8 × happiness / 100 (0.6 … 1.4);
- each field adds 5; the market adds 15 % of the tax part.

### Happiness (0 to 100, starts at 60)

Changes at dawn: low tax +3, normal 0, high −3, war −6; tavern +1; chapel +1; a night without losses +2; each fallen
soldier −3; each petitioner left unheard at the horn −1. Petitions add or take 1 to 10 at once.

| Happiness | Effect |
|---|---|
| 80 and up | +2 citizens per dawn while houses have room; children play in the lanes; builders 20 % faster |
| 60 to 79 | +1 citizen per dawn while houses have room; one free archer volunteers every third dawn at 70 and up |
| 30 to 59 | normal |
| 15 to 29 | no growth, taxes −20 % (in `mood` already), people grumble with crossed arms |
| below 15 | one citizen leaves per dawn; unrest: no taxes on that dawn; a protest sign on the market |

### Start of chapter 1

60 gold, 14 citizens in 4 houses (room for 16), 3 archers and 2 guards among them, 2 builders (castle staff, not
counted as citizens), happiness 60, normal tax.

### Prices and build times (start values; two builders)

| Thing | Gold | Time | Effect |
|---|---|---|---|
| Palisade (wall tier 1) | 20 | 8 s | 300 HP |
| Stone wall (tier 2) | 60 | 20 s | 800 HP |
| Bastion (tier 3) | 140 | 35 s | 1800 HP |
| Rubble rebuilt | half the tier price | half the time | a destroyed wall comes back at its tier |
| Archer tower / watchtower | 40 / 90 | 14 s / 22 s | 2 / 4 archer posts, range +15 % / +30 % |
| Brazier / fire tower | 12 / 40 | 4 s / 12 s | light radius 56 / 90, burns all night, needs no fuel |
| Ballista | 70 | 18 s | bolt 30 damage, pierces 3, every 3.5 s, range 240 |
| Catapult | 110 | 26 s | firepot 18 damage in 36 px, every 6 s, range 300; the fire lights radius 48 for 6 s |
| Stake pit | 15 | 6 s | 20 damage, 3 uses per night, re-armed at dawn |
| Archer / guard | 10 / 14 | at once, at the barracks | a taxpayer becomes a soldier |
| House / big house | 30 / 60 | 15 s / 20 s | room for 4 / 8 |
| Field | 25 | 10 s | +5 gold at dawn |
| Market | 80 | 25 s | +15 % taxes |
| Tavern | 50 | 18 s | +1 happiness per dawn |
| Builders' lodge | 60 / 120 | 20 s | 3 / 4 builders |
| Smithy | 60 / 150 | 20 s | archer damage +25 % / +50 % |
| Great Beacon | 150 / 250 / 400 | 30 / 40 / 60 s | three stages; the chapter's finale |

Builders work by day only and walk to the job. Walls damaged at night are repaired for free by builders the next day
(about 40 HP per builder per second). Destroyed walls must be rebuilt.

## The front by day: building

- Fixed plots, marked by stakes and a small banner. Standing at a plot shows the build card above it: one to three
  options with price and a one-line effect; unaffordable options are greyed with the missing gold.
- Ordering costs the gold at once; the builders walk out and build. A build in progress shows scaffolding.
- Upgrades use the same card at a built plot.
- The barracks (courtyard) recruit archers and guards. Archers take the free posts on walls and towers by themselves,
  front line first; guards stand behind the innermost standing wall.

## The night: battle

The battle runs by itself. The player watches, walks the walls and helps in small ways. Little tactics are needed: the
outcome comes from what was built and recruited by day.

### Light rules (`Core/LightField`)

- Sources: braziers (radius 56, fire tower 90), torches on every wall tier (radius 30), fire arrows where they land
  (22 for 2.5 s), catapult fires (48 for 6 s), the king's lantern (40), the hearth fire inside the great hall (70), the
  Great Beacon when lit (600, a sweeping cone). Castle and town windows light only the scene, not the battle.
- `illumination(x, y)` = the highest `(1 − d / r)²` of all sources, without flicker. A creature is **lit** at 0.12 or
  more. The rendered falloff draws a visible edge band exactly at that radius, so the player can read where the light
  ends.
- Lit creatures move at their lit speed, can be targeted by archers and ballistas, and the burning kinds lose health.
- Unlit creatures show only their eyes (two 1 px glints), move at full speed, and archers cannot see them. Catapults lob
  firepots at the densest group of eyes, lit or not, and light it up.
- The darkness bank advances at 20:00 to `x = 260 + 20 × night` (at most 600) over 20 s. Inside it, ambient light is
  ×0.4 and light radii ×0.6. It retreats at first light.

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
| The Lightless King (boss) | night 20 | 2400 | 12 / 9 | 40 per s; 80 px darkness aura | 64 px | calls 6 sootlings every 15 s |

- Night budget `B(n) = 16 + 9 n` points (sootling 1, hound 2, crow 2, weaver 6, brute 10), split into 3 waves on nights
  1 to 4, 4 waves on 5 to 14 and 5 waves on 15 to 20; the last wave leaves by 03:00. Boss nights add the boss.
- Creatures walk right along the ground and attack the first standing wall. A wall at 0 HP becomes rubble and is
  passable. Behind line 1 they enter the courtyard and head for the great hall.

### Defenders

- **Archers** on walls and towers: range 150, a shot every 1.4 s, 4 damage, lit targets only. Every fourth arrow is a
  fire arrow that lights its landing spot (radius 22, 2.5 s): the night is full of streaks and short pools of light.
- **Guards**: melee behind the innermost standing wall and at breaches; 30 HP, 6 damage per s; they step back below 30 %.
- **Ballista and catapult**: crewed by castle staff, fire by themselves.
- **Losses**: soldiers can fall (sootlings and hounds reach archers on a broken wall; guards fight in the breach). Every
  fallen soldier is named in the dawn report and costs 3 happiness. A night without losses gives +2 and a small banner
  in the report.

### The king at night

- The king cannot be harmed; creatures ignore him (they want the fire).
- His lantern lights radius 40, and soldiers within 80 px shoot and strike 25 % faster (rally).
- At a damaged wall the action button offers **Patch** (10 gold, +25 % of the wall's HP, then 8 s cooldown).
- At a snuffed brazier the action button offers **Light** (free, 1 s).

### Losing a night

- The hearth fire has 100 strength. Each creature that reaches it drains 10 per s; at 0 it goes out and the realm falls.
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
  - flanks of masonry grow into the rock on both sides;
  - it stands heavy on the ground (scene polish 2): by day it throws a shadow to the right onto the throat rock and the
    ground at its foot (light from the upper left), at dusk a long one across the throat rock, never at night; at dusk
    and night a bank of mist lies at the foot of its walls, behind the king.
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
| 11 | Odile finds the old plans of the Great Beacon. The beacon site unlocks (three stages, days 11 to 18). |
| 13 | Refugees from the Gloom's border at the gate: let them in (+6 citizens, a risk later) or turn them away. |
| 15 | The Stranger, Seren, reveals that Aldric lives: the Gloom made him the Lightless King. |
| 17 | A herald of the Lightless King comes to the audience: hand over Seren and the town is spared for three nights. |
| 19 | Last preparations. Pip's farewell joke. |
| 20 | The Lightless King attacks. If the beacon is finished, it is lit at 04:30 and the Gloom recedes; the boss falls at dawn. Without the beacon, the realm must simply survive until dawn. |

Endings by happiness and key choices: **The Bright Crown** (happiness 60 or more and Seren not handed over), **The Iron
Crown** (30 to 59, or Seren handed over), **The Ash Crown** (below 30). Each is a short scene of three panels; then the
realm goes on in endless mode.

### Endless: The Long Watch

- Unlocks after chapter 1. **Continue the realm** keeps the chapter's end state and goes on with night 21; **New realm**
  starts fresh from day 1 with random petitions only.
- Nights scale with `B(n) = 16 + 9 n + 0.15 (n − 20)²` beyond night 20; random events (an eclipse with a double wave,
  a festival, a plague of crows).
- Records: the highest night survived per mode.

### Later chapters (updates)

- **Chapter 2: The Black Tide** (coast): the sea rises each night and things climb the cliffs; at low tide by day the
  king salvages wrecks; a lighthouse beam (mood picture `docs/mood/ch2-coast.jpg`).
- **Chapter 3: The Thornwild** (long wall): a living thorn forest grows toward an ancient wall each night; by day the
  king cuts it back for timber (`docs/mood/ch3-long-wall.jpg`).

## Progression and saving

- Within a chapter: lines unlock, upgrades, the town grows, the story moves on.
- Between modes: the Chronicle (a page of records: nights, endings, fallen soldiers, petitions heard).
- `SaveGame` (Codable JSON, `version`, new fields optional): the chapter and mode, the last dawn snapshot of the whole
  `GameState`, flags, records, settings, ad pacing, hint flags. Written at every dawn and when the app goes to the
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
- **Warm light, cold shadow (scene polish 2):** by day and dusk the shadowed share of the albedo takes the sky's cool
  light instead of the warm sun (world and mid plane, not the figures), and at dusk the night's violet pull spares the
  sunlit share, so lit rock stays ochre while shadows turn violet. Cool albedo (teal cloth, slate) reflects firelight
  more neutrally, so it never glows mint or cyan. Cast shadows are baked from the layout (the castle front's, black at
  the sun's strength, the long dusk one beyond the day one); a mist bank at the castle's foot follows the torch
  strength. The king keeps a cool rim (sky by day, moon at night) on his screen-right edge, outshone by firelight.
- **Fog:** two drifting pixel-noise planes, one behind and one in front of the world; lit fog glows around braziers.
  By day and dusk a bright haze band lies over the far and mid planes' lowest 48 rows (half of it in the valley), so
  the far gorge wall's foot dissolves and the gorge reads deep.
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
brazier and a palisade at line 1 (hand on the action button), walk to the throne (the realm strip pulses), hear the
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
   happiness change and why, the ad buttons, **Continue**.
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
  rock lips at the top never hang below y 139. Scene polish 2: cool albedo reflects up to 60 % more neutrally, the
  shadowed albedo takes the sky's cool light by day and dusk, the night's violet pull spares the sunlit albedo at dusk,
  the haze band over the far and mid planes' lowest rows, actors lit like the world (cap, neutral share) and the king's
  cool rim.
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
  rule), `SeededRandom` (SplitMix64), `SaveGame`, `Autoplay`.
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
| `-GWReset YES` | fresh save |
| `-GWScene world\|lightlab\|testpattern` | the game world (default), the light lab, or the pixel-grid test pattern |
| `-GWDay <n>` / `-GWNight <n>` | start at that day's dawn / that night's dusk, with a scripted realm for that point |
| `-GWTimeOfDay <0…1>` | clock position (0 midnight, 0.25 dawn, 0.5 noon, 0.8 dusk) |
| `-GWFreezeTime YES` | the clock stands still (flicker keeps running unless `-GWFlickerTime <s>` fixes it) |
| `-GWCameraX <px>` | camera position; the king stands there |
| `-GWAutoplay walk\|play` | the king walks back and forth / a bot plays whole days (builds by a fixed order, hears petitions choosing the first option, walks the walls at night) |
| `-GWGold <n>` / `-GWHappiness <n>` | set the numbers |
| `-GWBuild demo` | every line built at tier 2 with towers, braziers and engines |
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
`frame:<n>` and `ready` once frames are stable after a freeze), `hud-gold`, `hud-happiness`, `hud-clock`, `hud-pause`,
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
6. Night 20 with the beacon is won by the reference bot in 8 of 10 seeds; without the beacon in 3 to 6 of 10.
7. In endless, the reference bot falls between night 35 and 60.
8. Each night's last wave leaves by 03:00; a night with 40 creatures keeps under 300 sprite instances and 40 lights.

### UI (screenshots `<nn>-<what>-<lang>`, English and German)

1. `testLightProbe` (milestone 1): the scenes and times of "Milestone 1" plus the pixel-grid check on the test pattern.
2. `testFirstDay`: `-GWReset YES`, onboarding on; walk, build, audience, night, report.
3. `testMidChapter`: `-GWDay 12 -GWBuild demo -GWAutoplay play`; a night at 23:00, the report.
4. `testAudience`: `-GWScreen audience` in every language (the longest petition) for clipping.
5. `testFilmstrip` (English): a frame every 1.2 s through a dusk and a night, for the fun check.

## Milestones (internal steps to 1.0)

Louis chose to build 1.0 straight away. These steps follow the work method in `CLAUDE.md`; each ends with a runner round
(build, unit, ui, ui-de, release), a commit, and the review lenses for the big ones.

| Step | Content | Louis sees |
|---|---|---|
| M1 Light and feel | renderer, pixel scale, parallax gorge, day and night, lights, fog, bloom, the walking king, placeholder art; the runner's Metal probe | screenshots: front at dusk and night, castle, throne room, town; 180 against 135 rows; three light styles |
| M1b World and castle (09.11.) | the castle that seals the gorge, the continuous gorge wall, the open valley and the river end; new Recraft art for all of it; backdrop regions per plane; an art-director review against the target pictures | the castle at night from the gorge, the valley town at golden hour |
| M2 Core loop | plots, builders, walls, towers, braziers, creatures, the automatic battle, the hearth, dawn report, saving | a whole day and night played by the bot |
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
| `23-castle-noon` / `24-approach-noon` | `-GWCameraX 1360` / `1100` at 0.5 (scene polish 2: the castle's cast shadow by day, the throat rock against the far wall; mocks `m1b-castle-day`, `m1b-approach-day`) |
| `film-01` … `film-08` | `-GWAutoplay walk` at dusk, at least 0.5 s apart (about 1.5 s on the runner: one screenshot and one read of the scene value per frame), with the king's screen x and the camera x from the `world-scene` value (`king:` and `cam:`) for the jitter check |

**Unit tests:** `DayClockTests`, `FlickerTests` (deterministic, bounded, Reduce Motion), `LightFieldTests`,
`CameraTests`, `ResolutionTests`, `FrameBuilderTests`, `MetalProbeTests`, `OffscreenRenderTests`.

**Done when:** the round passes, the screenshots show the warm-against-cold look with readable light pools and crisp
pixels, the jitter check passes, and Louis has seen the pictures and picked 180 or 135 rows and a light style.

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
