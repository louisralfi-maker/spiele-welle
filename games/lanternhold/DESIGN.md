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

## Louis' decisions (09.11.2026, evening): the world, the story and the look

Louis compared the screenshots with the genre's best (he named Kingdom New Lands and Kingdom Two Crowns): the depth of
trees and bushes was missing, and the look should be darker and more serious, "düster und gemütlich", at the level of a
big studio. He then reshaped the world and the story. He was interviewed with pictures: a before/after mock with depth
and four target pictures, `docs/mood/look2-1-weltmauer.jpg` to `look2-4-farbe.jpg` (Recraft concepts, not game art).

- **The world: the Weltmauer.** At the edge of the continent runs a mountain wall "like a line of Mount Everests", far
  above the clouds, that nobody can climb. It has one single cleft that leads to the other side. Lanternhold is wedged
  into that cleft, wall to wall, and defends it.
  - Before the castle (left, x 0 to 1240) lies the **shadow land**, open and dark: dark fir forests, fog, a dead moor,
    ruins of older defence lines, weathered statues of past lords. It is no longer a narrow gorge with rock walls along
    its length; the Weltmauer's cliffs rise at the cleft's mouth, around the castle.
  - Behind the castle (right) lies our land: the valley, the town and the river. Dark firs grow on the mountain slopes
    and deciduous trees (linden, poplars, orchards) in the town, so the contrast stays strong.
  - The player reads at a glance where the monsters come from: dark and foggy on the left, warm and bright on the
    right, the Weltmauer filling the sky behind the castle.
- **The story: House Lantern.** For a thousand years House Lantern has held the cleft, generation after generation.
  Nobody knows what the shadows are; everybody fears them. Behind the wall lies a huge continent with other families,
  lands, small towns and castles.
  - The name is Louis' choice: **House Lantern** in English, **Haus Lantern** in German and the same word in every
    language. Like Lanternhold, the name "Lantern" is never translated.
  - **The player is the Burgherr**, the lord of Lanternhold, not a king: a narrow gold circlet instead of a crown. The
    other lands have their own rulers.
  - **The other families are mixed:** some are allies, some envy the house, some think the shadows are a myth and want
    to stop paying. They come as envoys, merchants and petitioners to the audiences.
  - **The mystery opens piece by piece:** every chapter reveals a little more; the end of chapter 1 gives the first
    big hint.
- **The look: "farbig-düster"** (target picture 4): deep blue nights, warm orange fire, dark green forests; muted and
  serious, but with colour that carries on a phone screen. More dusk and night, mist and haze, warm windows and
  lanterns against the cold dark.
  - Depth: trees in rows behind the play plane, each farther row paler; dark plants in front that pass faster; a calm,
    hazy backdrop with the strongest contrast in the play plane; a lane under the feet instead of the soil cross-section;
    water reflections only where the world has water.
  - Movement: grass and trees in the wind, sparks, fireflies, chimney smoke.
- **The shadow creatures: lost people.** Gaunt, far too long figures of smoke that were once people: hollow glowing
  eyes, torn clothes, broken lanterns, ember cracks. Much creepier, each type with its own character.
- **The bar:** a big studio's game. Backdrops are painted (Recraft concepts converted to the palette and finished by
  hand), not built from code, and every scene is judged against the target pictures.

How it goes on (the lead, 09.11. evening):

- The look and world pass runs in its own lane `claude/lh-look2`: the direction first (palette, light, mocks), then
  the world art (Weltmauer, shadow land, valley, depth), then the creatures, each with review, refute and fix. The
  engine port follows after the M3 merge.
- The M4 art lane was stopped after step 2's well (87b10bf) to free its place. It resumes under the new look; the
  brook, the footbridge, the barn, the festival tent and the town's other changes are still to paint.
- The story pass after the M3 merge rewrites the content (DESIGN.md "M3 in detail", `Resources/Story.xcstrings`):
  king to lord, the families in the audiences, chapter 1's new premise and the first big hint in the endings.
- Chapter 1's premise in the new frame (decided for Louis): the Great Beacon at the cleft's mouth has gone dark; Lord
  Aldric rode into the shadow land to rekindle it and never returned. The lordship falls to the last of the house that
  carried the light into the Cleft: Aldric's cousin, raised as the heir of the guardian house; the circlet fits. Seren, the
  Lightless King and the endings stay as in "Story"; the story pass renames the endings from crowns to lanterns.
- Kept apart from other wall stories: a natural mountain range, a family and its people, light against shadow; never a
  built wall of ice or a sworn order.

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
| 09.11. | **Creatures smoulder in the dark, and the beacon blazes.** Unlit, a creature is an opaque dark body with a glowing ash edge, a crack network and a cool moonlight rim on its screen-right side (`Renderer.rimmed`); its eyes are no longer the main read. The Lightless King shows a cold teal silhouette inside his aura. The Great Beacon's fire is a 48x32 blaze across the whole bowl (SPRITES.md amended). The king's lantern glass burns dim by day. | The art review of the entity art found black blobs with two eye dots (the look "Not a copy" forbids), a finale boss that read as two teal dots, and a campfire as the chapter's climax. |

## Not a copy

The research (`docs/research-market-art.md`) lists what makes Kingdom, Yes, Your Grace and Reigns recognisable. We never
use their names, characters, art, music, levels or look. In particular:

| Never | Instead |
|---|---|
| A ruler on a horse or any mount; mounts bought with gems | The lord walks, carrying the guardian house's lantern on a hooked staff |
| Coins carried in a pouch and dropped at build sites, the coin drop as the only input | Gold in a treasury from taxes; a build card with prices at each plot |
| Vagrants in the wild recruited with coins, tools that set a job | Citizens are born in the town when people are happy; soldiers are recruited at the barracks |
| Masked enemies from portals that steal coins and the crown; losing the crown ends the run | The Gloom is a creeping wall of black fog with soot creatures; they want the hearth fire, never the king |
| Enemies from both sides | One front only, on the left; the Weltmauer closes everything else |
| A water reflection strip along the bottom, the island campaign, boats | The Weltmauer and its single cleft, a castle cut-away, the town's lit windows; reflections only where the world has water |
| The Kingdom palette, its silhouette-heavy single band | Our own palette (see "Look"), interiors, vertical cliffs, light pools as readable game state |
| King Eryk, a queen and three daughters, a succession or forced-marriage story, Slavic folklore monsters | The heir of the guardian house that has kept the light a thousand years; the old lord lost in the Gloom; original court and creatures |
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
- Unlit creatures smoulder in the dark (an opaque dark body with its ember edge, cracks and a cool moonlight rim; the
  09.11. decision), move at full speed, and archers cannot see them. Catapults lob firepots at the densest group, lit or
  not, and light it up.
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
| The Lightless King (boss) | night 20 | 700 | 24 in his own darkness / 12 in the Great Beacon's light | 150 per s, to the hearth too; 80 px darkness aura | 64 px | leaves at 20:20 ± 0:05 (4 s ± 1 s after nightfall since the M3 join; 20:50 ± 0:40 before, see "M3 join") and marches on the hearth; calls 6 sootlings every 15 s; can be hurt only inside the lit beacon's light, where his aura fails, he counts as lit and slows to his lit speed (see "The finale"); tuned from 2400 HP, 12 / 9 px/s and 40 per s |

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
  today's petitions, for example "Tamsin says Marek's arrows bend in the rain"). About 60 lines in 1.0 (118 since M3
  step 2), chosen by day and flags.
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
- 1.0 needs at least 80 petitions: 20 story, 45 random (town, front, guests, comic), 15 for endless only. M3 step 2
  wrote 83: 18 story, 50 random, 15 endless only ("M3 in detail: the audience's content").
- The full schema, the queue's rules, the speakers, the world change ids and the night modifiers: "M3 in detail".
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

### Chapter 1: The Dark Beacon (20 nights)

The Great Beacon at the mouth of the gorge has gone dark, and since then the Gloom comes every night. Lord Aldric rode
into it to rekindle the beacon and never returned. The circlet passed to his cousin, the heir by right of the guardian
house, raised in the castle and known to everyone (docs/HOUSE.md sections 1 and 7). The circlet fits.

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
- Nights scale with `B(n) = 16 + 9 n + 0.5 (n − 20)²` beyond night 20 (tuned from 0.15 to 0.4 in M2a, to 0.5 in the M3
  join); random events (an eclipse with a double wave,
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

## Controls: touch the world (built in step stage-2, 15.11.2026; the action button is gone)

Louis on 10.11.: the button at the right is "cringe"; in the games he names you touch the people and the things
themselves; the interface matters as much as the picture. The art lane proposed this on 10.11. ("Controls 2"); the
stage lane built it on 15.11. (DESIGN.md "The hall stage and touch the world", step stage-2) and it replaces the old
"Controls" with the walk pad and the action button. The marks are painted (SPRITES.md "The marks of 'touch the
world'", previews in `ci-out/hall`). Code: `Core/TouchWorld.swift` (the rules), `Core/TouchThings.swift` (what offers
something), `Core/TouchMarks.swift` (the framing, the marks), `App/GameModel+Touch.swift` (the errands),
`UI/TouchLayer.swift` (the finger, the elements, the slips).

**The rule:** the lord goes where the finger points. Touch a thing and he walks to it and does what it offers.
Touch the ground and he walks there. Drag and he walks as before.

| The tap lands on | The lord | Then |
|---|---|---|
| someone with a word: a member of the court or a guest (`tapTalk`, marked only while he has something new to say: a word about today's petitions he has not told yet), the Stranger at the gate | walks to an arm's length (12 px) and faces them | the talk bubble opens over the speaker's head (M9) |
| a bench in the hall with people waiting (`tapTalk` over the first in line) | walks to the first in line | he speaks one short line of the waiting in a bubble (`touch.bench.*`) |
| the empty throne, when an audience can be held (`tapThrone`) | walks up the steps and sits | the camera moves to the audience framing, the first in line rises and walks up; the card opens when he has stopped |
| an open plot, a building that can grow, rubble (`tapBuild`, only while its card offers something: M6) | walks to it | the build card |
| a damaged wall at night (`tapRepair`, its price in the slip) | walks to it | the slip stays over the wall with the price; a **second touch pays** (the director's note of 14.11. 14:35); refused while the gold or the cooldown says no |
| the barracks (`tapRecruit`) | walks to it | the recruit card |
| a cold brazier at night (`tapLight`) | walks to it | he lights it |
| the hall's door, from either side (`tapDoor`, the seventh mark; in the world where the facade paints it, `HallDoor`) | walks to it | the stage changes (the world, the great hall) |
| the tax lectern in the hall (no mark; until the town lane's taxes on foot) | walks to it | the tax card |
| the ground, or a thing that offers nothing now | walks to that x (in the hall inside the floor, short of the way out) | stands |
| the lord himself | raises the lantern: the lantern moment (stage-3-interface, HUD.md section 2; his body wins over a site he stands on) | any other touch lowers it |
| the realm strip | runs there, as before | |

- **The action starts when he arrives** (within 6 px of the thing's standing place). If he already stands there it
  starts at once. A thing that walks (the court) is followed.
- **The pace:** he walks; a place more than 480 px away, or any place at night, he hurries (68 px/s, about 1.9 times
  his walk; the director's note 3 of 14.11.); a second tap on the thing he walks to makes him run (80). The reference
  bots keep their own pace (they never touch the world).
- **While he walks to it** a slip above the thing's mark says what he is about to do and what it costs ("Repair the
  wall" and the coin with 10, a site's or the barracks' cheapest price; its figure red while the treasury cannot
  pay). A tap anywhere else, or a drag, calls him
  off.
- **Tap or drag:** a touch that never moves more than 10 pt is a tap, however long it lasts. Past 10 pt it is a drag
  anywhere on the screen: he walks toward the drag, runs past 40 pt, stops when the finger lifts.
- **Pressed:** with the finger down on a thing its mark shows the pressed frame and its pool brightens (1.4 times).
  On the lift the light haptic ticks (`touched`) and he sets off. If the finger slides off, the mark goes back to idle.
- **Raise the lantern** (the director's note 3): at night a press and hold on the lord (0.35 s) lifts the house's
  lantern over his head (the pole lifted high: the command frames; a flare on the glass and a ring of light at the
  growing light's edge for its first 0.45 s, fix round 1): its light grows to 96 px for 3 s and every creature it lights flinches (stops and backs away
  for 1.2 s; a boss only stops, for 0.6 s); then the flame gutters (24 px for 8 s); it is ready again 30 s after the
  raise, and a small flame over the lantern's glass shows it. A medium haptic and the fire's sound pitched up. By day a
  hold does nothing. `Core/LanternRaise.swift`; the bots never raise it, so T1 to T8 hold step for step.
- **The flame shows the danger** (the director's note 5, picture only): as the next wave nears (its last 12 s) the
  lantern's light burns lower and flutters, and it stays so while creatures are on the field; it steadies when the
  wave is spent. Reduce Motion: the light reddens instead of fluttering.

**What wins a touch**, in this order:

1. The interface: an open card, the pause seal, the ledger, the realm strip, the talk bubble. While a card is open
   the world takes no taps and shows no marks.
2. A thing that offers something now. Its touch area is its sprite and its mark together, grown to at least
   **44x44 pt** (22x22 game px at the world's scale on the 17 Pro, 19 at the hall's walking scale, 17 in the audience
   framing), centred on its standing place, from 6 px below the walk line up to the mark's top.
3. Where two areas overlap, the thing whose centre x is nearer to the finger wins. Within 4 px of a tie: the one
   who has the word, then a waiting petitioner (a bench), the court, a townsman, the throne, the door, the barracks,
   the lectern, a brazier, a plot, a wall. A person standing before a wall or a building takes his area out of theirs.
4. Everything else is ground.

- **A bench is one target.** The seated sit 11 px apart, too close for a finger.
- **The marks:** over every thing in view that offers something, at most four, the nearest to the lord first (the
  errand's thing always among them); at most two of them over building sites, and a site's only while the treasury
  can pay something on its card (the first sweep: four hammers in a row at the gate read as the banner posts they
  replaced); of a row of damaged walls only the nearest carries one; of sites or cold braziers closer than 40 px
  only the nearest (fix round 1); a tag that would overlap a nearer one gives way; a door's mark rests while he stands
  within 40 px of it (he just came through it); no mark while its thing's centre is within 30 px of the screen's edge
  (fix round 1). **One height band** (fix round 1): over a building, a wall, a brazier or the barracks the tip stands
  at most 30 px over the walk line, at the door, never at the crown. An empty plot shows its **footing** (two stakes,
  a cord, a chalk line) while its mark shows. The barracks are marked only while a recruit can be paid. Drawn unlit;
  at night at three quarters of their value and warmed (M11). A pool of warm light (radius 20, 0.7) at the thing's
  feet, a scene light that only shows after dusk, and the **gold rim** one pixel outside the marked thing's outline
  at its left, right and top (fix round 1; brighter while pressed). Nothing bobs or blinks. The old speech marks and
  the throne's pulsing mark are gone in the game.
- **First minute:** one slip, once (a new realm's first day, 10 s or until the first touch): "Touch what the lord
  shall do." (`touch.first`, with the lord's form). The first mark is the lesson.

**Accessibility**

- Every thing that offers something and is in view has an accessibility element at its touch area (a button),
  placed again four times a second, gone under a card. The elements take no finger (the touch layer under them does).
- **Labels** name the act first: "Talk to Tamsin", "Sit on the throne", "Build: Brazier", "Upgrade: Tower",
  "Repair the wall", "Recruit", "Light the brazier", "Enter the great hall", "Leave the great hall". The value
  carries the price ("10 gold").
- **Identifiers:** `touch-talk-<speaker>`, `touch-bench-<n>`, `touch-throne`, `touch-plot-<index>`,
  `touch-wall-<index>`, `touch-recruit-barracks`, `touch-brazier-<index>`, `touch-door-hall`, `touch-lectern`; the
  slip `touch-slip`, the first slip `touch-first-slip`.
- **Order:** the HUD first, then the things from left to right, then the scene. Activating an element is the tap;
  VoiceOver hears the arrival where nothing else speaks ("At the wall. Touch it again to repair it.", "At the brazier.
  Lighting it.").
- **`world-scene`'s custom actions:** "Walk left" and "Walk right" (one screen each) and "Raise the lantern".
- With Reduce Motion the move into the audience framing and the fade between the stages are cuts.

**What the UI tests use:** the identifiers (present only while the offer exists and the thing is in view);
`world-scene`'s value carries `stage:world|hall`, `lx:<x>` (the lord's x on the stage that shows; `lord:` already
names Burgherr or Burgherrin) and `errand:<identifier>|none`; `-GWStage hall`; `-GWTouchHint YES` holds the first slip
for its picture. `UITests/TouchSupport.swift` taps an element's coordinates.

- HUD: pause top left (44 pt in a 60 pt area); gold, happiness and the day and clock top right (stage-3 takes them
  off the walked world: docs/HUD.md).
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

Sound effects and haptics only. Never music, also no melodic jingles: signals only. The first plan is below; what
the game plays is in "Sound and haptics" (synthesised WAV files and `SoundDirector`).

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

## Sound and haptics

Louis: no music, ever; sound effects and haptics only; a rain sound is allowed. The mood is "düster und gemütlich":
warm, soft, a little lo-fi but clean, nothing harsh or cartoonish, no melody longer than a horn call. The table under
"Feel" was the first plan; this section is what the game does (sound lane, 14.11.2026).

### The files (`Resources/Sound/`, 26 files, 2.48 MB)

Mono 16-bit WAV at 22.05 kHz, synthesised in pure Python by `tools/soundsynth.py` (no numpy, no PIL; noise, one-pole
and biquad filters, decaying partials, formant voices, a small Schroeder reverb). The loops are made a little longer
than they play and their tail is crossfaded onto their head, so the last sample runs into the first without a click.

| File | What it is | Played for |
|---|---|---|
| `amb_day` (loop, 10 s) | wind in the gorge: band-passed noise wandering 320 to 720 Hz, gusts, a low body | the day outside |
| `amb_night` (loop, 10 s) | lower wind, two far breathy moans of the lost (formants, no words), a soft 55 Hz drone | the night outside |
| `amb_rain` (loop, 6 s) | soft hiss, rain on roofs, drops | while `Weather` says it rains |
| `amb_fire` (loop, 6 s) | a low roar, hiss, crackles and pops | near braziers, fire towers, torches, the lit beacon |
| `amb_hall` (loop, 8 s) | the hearth, six people murmuring (muffled until no word is left), steps on stone, stone reverb | the great hall |
| `coin` / `coins` | two clinks / a pouch and seven coins | gold won, the tax set / gold paid, the dawn's taxes |
| `build_start` / `build_done` | three hammer taps / two solid knocks and a low settle | a build ordered, a wall patched / a build done |
| `lantern` | a strike and a soft flame | a brazier lit; the beacon (slower); creatures at the hearth |
| `horn` | a low horn, two long tones of the same pitch | the horn at 19:00; the defeat (slower, lower) |
| `bell` | a small chapel bell, struck twice | first light; the Lightless King's aura breaking (higher) |
| `bow` / `arrow_hit` | twang and air / a thunk | a volley, fire arrows / an arrow or bolt hitting, a shot glancing off the King |
| `creature_hit` / `dissolve` | a short breath / a sad breathy sigh fading into soot | a creature hurt / dissolving; the King's fall (slower) |
| `wall_hit` / `wall_break` | stone thud and crunch / rumble, crash and debris | a wall or palisade hit, the giant's step, a soldier falling / a wall breaking |
| `gate` | creak on old hinges, the thud, the latch | the gate shutting at nightfall (20:00) |
| `engine` | a heavy wooden thunk with a creak | the ballista, the catapult |
| `step_1`, `step_2` | soft scuffs | the lord's steps (alternating) |
| `parchment` | a crinkly unroll | an audience opening, the next petitioner |
| `tap` / `seal` / `decline` | soft wood / a wax seal pressed / two dull low knocks | a card opened or closed, talking / a choice made, a recruit sworn in / refused |

Rebuild: `python3 games/lanternhold/tools/soundsynth.py` (all) or with names (`... bow coin`); `--list` names them. A
fixed seed per sound and the script's own random generator write the same bytes every run (checked: two runs, the same
`MANIFEST.txt`, which lists every file's size and sha256). The whole set takes about half a minute of CPU on the old
Mac; the script reads `tools/smcread` between sounds and waits below 75 °C once the CPU passes 80 °C.

### In the app

- `Core/SoundCues.swift` (plain values): `SoundID` (the files, each with a minimum interval, a voice count and
  whether its pitch varies by a few per cent), `FeedbackCue.sound` (file, volume, rate) and `.haptic`,
  `SoundThrottle`, `SoundPlace`, `AmbienceMix`, `SoundWatch`.
- The cues come from three places, never from the HUD's buttons or the screen's layout:
  - the simulation's events (`FeedbackThinner.cue(for:)`, as before: volleys, the horn, first light, a wall
    breaking, builds, the dawn ...);
  - `SoundWatch`, which compares the realm's state from frame to frame: gold won (`coin`) or paid (`paid`), a wall
    losing HP (`wallHit`, at the wall's plot), a creature losing HP (`creatureHit`, and `arrowHit` when an archer or
    a ballista hit it), the clock crossing 20:00 (`gate`), the lord walking (`step` every 18 px, 27 px running; none
    under a card, none for a jump);
  - the model's own actions: `audienceOpened` (parchment) and `choiceMade` (wax seal) in `GameModel+Court`, the
    cards' taps and refusals as before.
- `FeedbackThinner` thins them all (positional cues only within hearing of the lord, a gap per cue, at most four a
  frame, the big moments first; a single coin is dropped when the dawn's coins sound in the same frame).
- `App/SoundDirector.swift` is the real `FeedbackHub`: an `.ambient` audio session (the player's own music keeps
  playing; the silent switch silences the game), a pool of `AVAudioPlayer`s per sound (1 to 3 voices, the oldest is
  cut), a throttle per sound in real time (`SoundID.minimumInterval`: the horn at most every 2.5 s, a bow every 0.1 s),
  and the five loops crossfaded toward the frame's `AmbienceMix` over about 1.2 s.
- The simulation stays deterministic: it never reads sound state, and `SoundTests` runs a night twice, with and
  without a hub, to the same state.

### The mix

`AmbienceMix.target(hour:rain:place:fire:ducked:)`, every frame from `GameModel.advanceGame`:

- day wind × (1 − night), night × night; night is 0 by day, 1 from 20:00 to 05:00, ramped over the dusk (19 to 20)
  and first light (5 to 6);
- rain × the weather's rain (the drawn frame's `WeatherSample.rain`, so it follows `Weather` and `-GWRain`);
- open air by place: outside 1, the castle's other rooms 0.55, the great hall 0.15 (the rain on the hall's roof
  stays at 0.3); the hall loop: hall 1, the other rooms 0.2, outside 0;
- fire: the nearest brazier or fire tower (0.8 / 1, softer by day), torch (0.3) or the lit beacon, full within 15 px,
  gone 165 px away (the beacon 275); a third of it in the hall, whose loop has its own hearth;
- everything at half under a whole screen (the pause sheet, the dawn report, the defeat card).
- The place: `GameModel.soundPlace(_:)` answers by the lord's room (`WorldLayout.rooms`) and `.hall` during an
  audience at the throne. When the great hall becomes its own full-screen scene, that scene answers `.hall` there;
  nothing else changes.
- Loop volumes at full strength: day 0.5, night 0.6, rain 0.5, fire 0.55, hall 0.6. One-shot volumes are in
  `FeedbackCue.sound` (steps 0.3, taps 0.55, the horn 0.85, a wall breaking 0.95).

### Haptics

`UIImpactFeedbackGenerator` and `UINotificationFeedbackGenerator`, behind the haptics switch: a build done light; a
coin soft (at most every 0.25 s); a wall hit medium (every 0.3 s); a wall breaking or creatures at the hearth heavy
(every 0.6 s); the horn (night begins) rigid; the dawn survived (`taxesCounted`) success; the defeat error.

### Settings and tests

- The pause sheet's existing "Sound" and "Haptics" switches (`pause-sound`, `pause-haptics`, saved in
  `SaveSettings`) set the hub's `soundOn` and `hapticsOn`; turning sound off stops every loop at once.
- `RootView` installs the director only for the game scene and only when `SoundDirector.allowed`: never in the unit
  tests' host (`XCTestConfigurationFilePath`), in a launch with any `-GW` argument (every UI test) only with
  `-GWSound YES`, in a plain launch always (`-GWSound NO` silences it).
- `Tests/SoundTests.swift`: the cue-to-sound and haptic mapping (every one-shot is played by some cue), the throttle,
  the thinner with the watch's cues, `SoundWatch` (gold, walls, creatures, the gate, steps, jumps, resets), the mix
  (day, dusk, night, rain, the hall, ducking, fire, the crossfade), the launch rule, and every file in the app as mono
  16-bit 22.05 kHz WAV under 3.2 MB together.
- Rounds: `lh-snd-1` ALL PASSED on 72b7a99 (build, unit with 411 tests and the 12 of `SoundTests`, ui, ui-de,
  release; T1 to T8 and night 20's step check unmoved). The commits after it harden three of the new tests (no
  tuple key paths, a tolerant throttle count, a fire check clear of the middle line's torches) and write this
  section; `lh-snd-2` (build, unit) ALL PASSED on 9e5ba1f.
- Open: Louis has not heard the sounds yet (TestFlight); volumes are first guesses. Happiness up and down have no
  sound (Louis' list did not ask for one). Positional cues are heard at one volume within their hearing range, not
  fainter with distance.

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
8. **Pause sheet:** resume, by day "Sound the horn" (after a confirmation the day plays on to dusk at once; M2b review),
   settings, back to the title. **Settings:** sound, haptics, reset (with confirmation).

Navigation is a state machine in the model, no NavigationStack.

### The interface in the map's style (10.11.2026)

Louis loved the realm map (`docs/karte.html`) and asked for the game's interface in the same hand. Branch
`claude/lh-ui` from f9751d1. The style guide and the screens one by one are in `docs/UI-look.md`; this section records
the decisions.

**Decisions**

- **Paper from the lord's desk.** Every piece of the interface is a thing of the world: the HUD a slip of the
  steward's ledger, the realm strip a strip cut from the map, a petition a letter, the dawn report a page of the house
  chronicle, the name entry a page of the family book, the build cards pages of the builders' ledger. It is this
  game's own interface, drawn from its own map.
- **Two surfaces.** Parchment for what is inside the world, the dark desk for what is outside it (the pause sheet,
  the defeat card). So a glance tells a letter from a menu.
- **Palette:** the map's (desk, bone, parchment, ink, rule, wax-red rubric, gold, House Lantern's teal). Teal always
  means the house or "marked, in force"; wax red means a heading, the main button, or a warning; gold means coin or
  gilt. The soft ink is a shade darker than the map's (`58432B`), so that footnotes hold 4.6:1 on the shaded corner
  of a sheet.
- **Type:** IM Fell English (SIL OFL 1.1), three cuts in `Resources/Fonts` with `IMFell-OFL.txt`, registered through
  a small `Info.plist` (`UIAppFonts`) that `project.yml` merges into the generated one; `Theme` registers them a
  second time at first use if the plist ever fails. The face has no bold: bold became small capitals.
- **Figures in Baskerville SemiBold.** IM Fell's old-style 1 reads as a capital I ("Day I"). Every number, and every
  digit inside a sentence (`Text(inked:)`), is set in Baskerville's lining figures, which every iPhone has.
- **Japanese and Simplified Chinese** fall back to Hiragino Mincho and the system's serif; frames, colours and
  figures are the same. Not yet seen in a screenshot.
- **Buttons:** the main one a plaque of wax red (52 pt), the quiet one an inked plaque, round wax seals for pause, the
  action button and the switches. Pressing darkens; nothing moves.
- **Icons** for gold, happiness and people are drawn in ink with a wash of colour; the face still tells its five
  states by the mouth.
- **Motion:** nothing was added. What moved before (rolling numbers, the face's hop, a card's fade) still stops with
  Reduce Motion.
- **Square corners.** Paper is cut, so sheets, slips, plaques and picture frames have 2 pt corners instead of the
  first look's rounded cards.

**Kept**

- Behaviour, the model's state machine, the overlay dims, the frame-rate rules for overlays (20 fps under screens,
  60 fps under cards, 30 fps when hot), plain fills and strokes only.
- Every accessibility identifier, label, value and trait; the UI tests are unchanged. Touch targets of 44 pt, choices
  and main buttons 52 pt.
- The string catalogs: no key added, changed or removed.
- The first look's names in `Theme` (`GoldButtonStyle`, `QuietButtonStyle`, `Theme.rounded`, `night0`, `moon`,
  `stoneLight`, `woodDark`, `CornerGem` and the rest) with the new look behind them, so the polish and art lanes'
  code compiles after a merge without a change.

**Left for the other lanes**

- The crown symbol on the audience button and the HUD (`crown.fill` in `ActionButton` and on "End the audience") is
  untouched: `claude/lh-polish` swaps it for the circlet that `claude/lh-look2-fable` draws.
- The fog, the castle tiers and the props.

**After round `lh-ui-1`: IM Fell's lines stand taller**

IM Fell's lines are about a quarter taller than the system face's, and the first restyle added rules and padding, so
four things no longer fit their sheets in the round's pictures. All four were tightened, none by shrinking type:

- **Taxes card:** the fourth rate (the locked war tax) was cut. The card's rows keep 52 pt (4 pt inside instead of 6,
  1 pt between a row's two lines), the sheet 10 pt above and below. Round `lh-ui-2` showed the German war tax still
  breaking into a third line beside "Ab Tag 8" (8 pt short), which pushed the row's foot under the edge: the tax
  card is 512 pt wide instead of 480.
- **Dawn report:** the finale's last row (People) lay under the footer's rule, the sample's last unlock line on it.
  The columns' rows stand 5 pt apart, a row's detail directly under it, the banner and the header are 3 to 6 pt
  lower.
- **Petition, German:** the request's third line was cut. The card starts 74 pt down (the ledger slip ends at 67)
  and its paddings are 1 to 2 pt smaller.
- **Pause sheet, English:** "Sound the horn" broke under its moon. It is one line, scaled down to 75 % at most.

Also: the count in "Next petitioner (1)" is set in the figure face (`Text(inked:)`), and `PeopleShape` and
`PeopleIcon` moved below `GoldAmount` in `Theme.swift`, because `claude/lh-polish` adds its circlet after `CoinStack`
where they stood. This section stands at the end of "Screens" for the same reason (that lane writes before "Risks").
A trial merge (`git merge-tree`) of `claude/lh-polish` and of `claude/lh-look2-fable` into this branch is clean.

**Rounds** (each on the runner: `build unit ui ui-de release`; times in UTC, 10.11.2026)

- `lh-ui-1` on 5f7f7d3: ALL PASSED (build 14:19, unit 14:27, ui 14:48, ui-de 15:07, release 15:12). Its pictures
  showed the four sheets above.
- `lh-ui-2` on 7f6a5f6: ALL PASSED (15:49, 15:56, 16:18, 16:37, 16:45). Its pictures showed the German war tax.
- `lh-ui-3` on 903eee8: FAILED 1. The English `ui` step failed once in `testFirstDay`
  (`FirstDayUITests.swift:147`, "Continue closes the report"): the tap on `report-continue` was sent and the report
  stayed for the six seconds the test waits. Build, unit, the German `ui-de` and release passed (17:02, 17:09,
  17:47, 17:53).
- `lh-ui-4` on 903eee8, the same commit again: ALL PASSED (build 18:22, unit 18:30, ui 18:51, ui-de 19:09,
  release 19:15). Nothing was changed between the two rounds, the test included.

**Open**

- The title screen (Screens 1) does not exist in the code yet; `docs/UI-look.md` says how it should look.
- Story panels (Screens 6) likewise.
- A Japanese and a Chinese screenshot round.
- The Continue tap that was lost once in round `lh-ui-3` (one of eight runs of `testFirstDay` across the four
  rounds, four English and four German). No cause was found: the restyle leaves `continueReport()`, the overlay
  switch and the button's identifier as they were, and the report's picture is the same as in the passing rounds.

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
  `Story.xcstrings`, `PrivacyInfo.xcprivacy`, `Fonts/` (IM Fell English with its OFL; "The interface in the map's
  style").
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
| `-GWScreen title\|audience\|report\|defeat\|story\|finale\|petition` | open that screen with sample data (M2b part 2: `report`, a night with a lost wall, a fallen archer and an unlock; `finale`, night 20's report with the Lightless King slain; `defeat`, the hearth out on the night the other arguments reach, at 02:30 when they reach a day; M3: `petition`, the herald of the Lightless King before the throne on day 17 at the golden hour, the Stranger let in and revealed) |
| `-GWClock <h>` | tests (M3): the start state's clock set to that hour of the same day (6 to 19) without anyone playing on, so today's petitioners still wait (`-GWHour` lets the reference bot play, and it hears them) |
| `-GWTimeScale <x>` | tests only: the game's simulation runs x times as fast (0.25 to 20; the driver's quarter-second catch-up cap stays) |
| `-GWHour <h>` | after the start (a day, a night, the save or a new realm, then the demo build) the reference bot plays on headless until the clock next shows h; a dawn on the way renews the snapshot (`-GWNight 12 -GWBuild demo -GWHour 5.83 -GWFreezeTime YES` holds first light's front at the outer wall) |
| `-GWSeed <n>` | seed of the random stream |
| `-GWVirtualHeight 180\|135`, `-GWScaleOverride <s>` | pixel scale experiments |
| `-GWLightStyle smooth\|banded\|dithered` | light falloff style |
| `-GWActorMode smooth\|snapped` | how actors are placed |
| `-GWEffects all\|nobloom\|nofog\|minimal` | effect level |
| `-GWShowLowRes YES`, `-GWShowBuffer light\|emissive\|bloom\|fog` | debug views of the buffers |
| `-GWDebugLights YES` | light radius rings and ids |
| `-GWStats YES` | CPU and GPU ms, fps, thermal state, s |
| `-GWReduceMotion YES` | Reduce Motion without the system setting |
| `-GWSkipOnboarding YES` | no hints (accepted since M2b part 2, so the tests already pass it; the onboarding comes in M7) |
| `-GWLook 1\|2` | the look: 2 is the default since the look 2 port; 1 is the first look, kept for the shots and hashes that pin it |
| `-GWCastle 1\|1b\|2\|2b\|3\|3b` | look 2: fixes the castle's tier as drawn (b: under scaffold); without it the castle stands as the realm built it (it grows with its gatehouse, "Polish after round 2") |
| `-GWBuild raise` | the demo realm, and by day the great gate 45 % built with a builder at it: the castle's third tier under scaffolding. Use it with `-GWClock` (the hour set, not played: the builders would finish the gate in under four hours) |
| `-GWWeather auto\|clear\|breeze\|gusty\|storm` | look 2: the weather; auto is the run's seed and day, the others hold one kind |
| `-GWWind <0...1>`, `-GWRain <0...1>`, `-GWWetness <0...1>` | look 2: hold the steady wind (negative: from the valley), the rain or the wet ground |
| `-GWGloomFog off\|<0...1>` | look 2: the fog out of the Gloom; without it tonight's (the night's number and the fog modifier), a number holds how hard it comes (0 the first night's, 1 a late fog night's), `off` leaves it out |
| `-GWHouses all\|varn,brine,oxmoor,calder,lorn` | shots: these houses stand with the lord and the banners are hung, so theirs hang in the great hall ("Polish after round 2", point 5) |
| `-GWLord lord\|lady`, `-GWLordName <name>` | the lord pass: Burgherr or Burgherrin and the lord's name (cleaned like a typed one) without the name entry; the other half is the standard lord's (Robin, Burgherr) |
| `-GWSound YES\|NO` | sound and haptics on or off in this launch; without it a launch with any `-GW` argument (the UI tests) is silent and a plain launch plays ("Sound and haptics") |

## Accessibility identifiers

`title-continue`, `title-chapter`, `title-endless`, `settings-open`, `world-root`, `world-scene` (its value carries
`frame:<n>` and `ready` once frames are stable after a freeze; in the game also `day:<n> hour:<h.hh>`, the
simulation's clock), `hud-gold`, `hud-happiness`, `hud-clock`, `hud-pause`,
`realm-strip`, `action-button`, `build-card`, `build-option-<id>`, `audience-root`, `audience-choice-<n>`,
`audience-counsel`, `audience-leave`, `tax-<rate>`, `report-root`, `report-continue`, `report-ad-double`,
`report-fallen`, `merchant-gift`, `defeat-root`, `defeat-second-chance`, `defeat-replay`, `story-next`, `story-skip`,
`pause-resume`, `pause-title`. Since M2b part 2 also: `hud-people`, `horn-banner`, `build-card-close`, `build-card-prev`,
`build-card-next` (the build card's arrows to the other plots in reach), `recruit-card`, `recruit-archer`,
`recruit-guardsman`, `recruit-card-close`, `tax-card`, `tax-card-close`, `report-king-banner` (night 20),
`report-banner`, `pause-sheet`, `pause-sound`, `pause-haptics`, `pause-restart`, `pause-restart-confirm`,
`pause-restart-cancel`, since the M2b review `pause-horn`, `pause-horn-confirm`, `pause-horn-cancel`; `world-scene`'s
value adds `kx:<x>` (the king's world x) and, while first light's front is on screen, `dawn:<share>`; since the M2b
review also `aim:<n>` (archers drawing or loosing in the frame). Since M3 step 3 also: `audience-next`,
`audience-reaction`, `audience-counsel-line`, `talk-bubble`, `report-unheard`; `realm-strip`'s value names the
petitioners waiting. Since the lord pass also: `lord-entry-root`, `lord-name-field`, `lord-form-lord`,
`lord-form-lady`, `lord-confirm`, `audience-text`, `audience-remembered`; `world-scene`'s value adds `lord:<form>`.
Since stage-3-interface (15.11.2026, HUD.md): `hud-gold`, `hud-happiness`, `hud-people`, `hud-clock` and `hud-pause`
(the gear) exist only in the lantern moment (`lantern-moment`, opened by a touch on the lord, `touch-lord`); `realm-strip`
only there and while a call brings it up; `build-card-prev` and `build-card-next` are gone; `world-scene`'s value adds
`gold:<n>` and `hud:none|notes|strip|moment`.
Debug only: `debug-king-x`, `debug-camera-x` (values for the jitter test).

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
6. Over seeds 1 to 20 (since the M3 join; ten seeds before), night 20 with the beacon is won by the reference bot in at
   least 80 % and the Lightless King is slain in at least 60 % (his kill times are reported: about 25 to 70 s after he
   leaves the Gloom); without the beacon 30 to 60 % hold. "Without" is the same realm on the eve of night 20 with the
   beacon's last stage taken away, so the two runs differ only by the beacon. A whole run of a bot that never builds
   the beacon (its gold goes into the rest of the order) is reported beside it for the first ten seeds, not asserted.
   Margins are reported per seed: the seconds of the beacon's light the King had left where he fell (his walk to its
   edge plus the walls in his way, `Battle.kingLightLeft`), and without the beacon the seconds before first light at
   which the realm fell or the hearth's lowest strength where it held.
   The bands are shares of 20 seeds, so a single draw no longer decides them (`tools/simtune finale` sweeps the
   finale's numbers over the same 20 seeds).
7. In endless, the reference bot falls between night 35 and 60 in at least 80 % of 20 endless seeds (the realms of
   seeds 1 to 20 at dawn 21, played on; three seeds before the M3 join, all three in the band).
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
  King's leaving at 10 s after nightfall stays provisional until then. (The M3 join measures T7 over 20 seeds, raises
  the endless growth to 0.5 and moves the King to 4 ± 1 s.)
- With these bots the King always falls at the middle line, never at the outer line (its palisade falls in seconds).
- The realm's world numbers (`Realm.worldWidth` 3900, `walkEnd` 3760, the town plots 100 px right) landed together
  with the M1b world (merge of `lh-m1b-port`, 09.11.). `Tests/RealmWorldTests` pins every copy in `Realm` to
  `WorldLayout`: width, walk end, spawn, beacon, hearth, throne, the lines' walls, towers, engines and traps, and the town
  plots' centres.
- The braziers are not 5 px off: `WorldLayout.lines` gives a brazier's left edge (1250, 1274, 891, 915, 591, 612, where
  its 10 px sprite stands), `Realm` its centre and light (1255, 1279, 896, 920, 596, 617). The test pins that too.

### UI (screenshots `<nn>-<what>-<lang>`, English and German)

1. `testLightProbe` (milestone 1): the scenes and times of "Milestone 1" plus the pixel-grid check on the test pattern.
2. `testFirstDay` (`UITests/FirstDayUITests.swift`, M2b part 2): `-GWReset YES -GWSkipOnboarding YES -GWTimeScale 4
   -GWCameraX 1150`; the HUD (`40-hud`), a drag walks the king, a tap on the realm strip runs him to line 1's braziers,
   the hammer opens the build card (`41-build-card`) and a brazier is ordered (gold 60 to 48), the barracks
   (`42-recruit`), the tax lectern (`43-taxes`), the horn (`44-horn`, when caught), the night, the dawn report
   (`45-report`) and Continue; every button checked for 44 pt. With the onboarding (M7) a second run keeps it on;
   the audience joins in M3. `testScreens`: `-GWScreen report` (`46-report-sample`), `-GWScreen finale`
   (`47-report-finale`), `-GWScreen defeat` on night 3 at 02:30 (`48-defeat`) and its replay, the pause sheet
   (`49-pause`) and the restart's confirmation (`50-restart`).
3. `testMidChapter` (`UITests/MidChapterUITests.swift`, M2b): `-GWNight 12 -GWBuild demo -GWAutoplay play`, shots at
   about 21:30, 23:00 and 01:00 (`30-mid-2130`, `31-mid-2300`, `32-mid-0100`), then `-GWDay 12 -GWBuild demo
   -GWCameraX 600` for the same realm by day with the builders at work (`33-mid-day`); the clock is read from the
   scene's value (`hour:`). `testFinale` (English): `-GWNight 20 -GWAutoplay play`, the beacon lit and the Lightless
   King in its light (`34-finale-2300`, `35-finale-0000`; the windows are 23:00 to 23:30 and 00:00 to 00:30 since the
   M3 fix). Since M2b part 2 the night ends on its dawn report
   (`36-mid-report`), first light is held still as its front passes the outer wall (`37-mid-firstlight`:
   `-GWNight 12 -GWBuild demo -GWHour 5.83 -GWFreezeTime YES -GWAutoplay play`), and the finale ends on its report with
   the King's banner (`38-finale-report`). Since the M2b review the gatehouse at 22:00 with the demo's iron gate closed
   (`39-mid-gate-2200`: `-GWNight 12 -GWBuild demo -GWHour 22 -GWFreezeTime YES -GWCameraX 1360 -GWAutoplay play`), and
   the liveliest frame also counts archers drawing or loosing (`aim:`).
4. `testAudience` (`UITests/AudienceUITests.swift`, M3 step 3, English and German): day 3 (seed 2, `-GWClock 10`)
   walked through the castle: the courtyard with Brannock, Bram, Marek and his cart, Pip (`58-courtyard-court`), the
   great hall shut from the courtyard (`60-hall-front`), open inside with Odile and three petitioners at the benches
   (`51-hall-court`), the kitchen opened (`57-kitchen-open`) and a line from Tamsin in a bubble (`55-talk`), the chapel
   opened (`56-chapel-open`); day 2 on the throne: Brannock's story petition with his portrait (`52-petition`), Odile's
   counsel (`53-counsel`), the reaction (`54-reaction`), the next petitioner's composed portrait
   (`52b-petition-townsfolk`), standing up; `-GWScreen petition` (`59-petition-herald`); Reduce Motion opens the card
   without the walk. Every button checked for 44 pt. M7 adds the other six languages.
5. `testFilmstrip` (English): a frame every 1.2 s through a dusk and a night, for the fun check.
6. `testTheLordIsNamed` (`UITests/LordUITests.swift`, the lord pass, English and German): a new realm without any
   shortcut opens the name entry (`91-lord-entry`); the Burgherrin is picked and a name typed, digits and signs are
   not kept (`92-lord-entry-typed`); the Burgherrin stands in the hall (`93-lady-hall`), sits on the throne for day
   1's farmer (`94-lady-sitting`) and reads her name on his card (`95-lady-first-petition`, `96-lady-counsel`,
   `97-lady-reaction`); the next launch asks nothing and the save kept the Burgherrin; then the Burgherr seated before
   Brannock on day 2 (`98-lord-seated`). Every target checked for 44 pt.

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
| `23-castle-noon` / `24-approach-noon` | `-GWCameraX 1360` / `1100` at 0.5 (scene polish 2: the castle's cast shadow by day, the throat rock against the far wall; mocks `m1b-castle-day`, `m1b-approach-day`) |
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
| `-GWAutoplay play` shows no debug readouts (they stay for `walk` and `-GWStats`) and no action button (the bot acts itself). | The mid-chapter shots must work as store screenshots; in round `lh-m2b-a2` the button covered the finale. |
| At night in front of the castle the game's camera aims 60 px left of the king, toward the Gloom (eased in through the dusk, out through first light, faded out as he walks into the castle front). | The fight comes from the left: centred on the king behind the outer wall, the view showed 64 px of the fog and an empty right half (rounds `lh-m2b-a1` and `a2`); the probe's camera is unchanged. |
| The Great Beacon's pool shines at 0.32 in the picture (`Look.intensityScale`); its radius and reach stay the simulation's. | At full strength the radius-840 pool blew the front out to white (round `lh-m2b-a2`: the Lightless King and the archers near-white). |
| The demo's one fire tower stands in front of the outer wall. | It lights the approach (from x 545), creatures slow to their lit speed in it and the outer line's archers shoot in view; without it the creatures stayed dark until the braziers and died there in seconds (round `lh-m2b-a1`: the shots caught the wall between waves). |
| The mid-chapter shots keep the liveliest frame of a window after each time (half an in-game hour for 21:30, a whole one for 23:00 and 01:00), by the scene value's `seen:` (creature bodies in the frame) and `shots:` (projectiles in flight). | The demo realm wipes each wave out within seconds of its reaching the light, so a fixed moment mostly shows the lull between waves (round `lh-m2b-a2`: one to three creatures in view). |

**Runner rounds (M2b part 1)**

- `lh-m2b-a1` (build, unit, `testMidChapter`): all passed on the first build. `FrameBudgetTests`: with 40 creatures
  alive across the front of the manned demo realm, at most 161 sprite instances and 15 lights on four screens and
  seven camera positions (targets: under 300 and 40); a whole live night 12 at most 101 instances and 17 lights (23
  creatures at once). The shots caught the outer wall between waves.
- `lh-m2b-a2` (build, unit, `testMidChapter`, `testFinale`): all passed; the outer line's fire tower lit the approach
  and arrows with trails read, but a fixed moment still showed one to three creatures, and the finale blew out to
  white under the beacon.
- `lh-m2b-a3` (build, unit, ui, ui-de, release): all passed. The liveliest-moment shots: 23:43 (5 creatures in view, 5
  projectiles), 01:45 (8 and 5: an ash brute in the fire tower's light, sootlings as ember eyes and cracks in the
  fog, a firepot and arrows in flight), the finale at 22:32 and 23:49 (13 and 15 creatures: the Lightless King in the
  beacon's light among burning summoned sootlings, a gloomweaver's darkness, archers shooting at him). The light probe
  shots and the jitter check (spread 0 device px) unchanged. The arrows' 8 px trails still read as no motion at
  phone size.
- `lh-m2b-a4` (build, unit, ui, ui-de, release) on `ed01760`: all passed (219 unit tests, the six UI tests in English
  and German, the Release build). Brighter arrow shafts, 12 px trails and softer fire-arrow landings: at 01:46 two
  arrows with their trails, a firepot and the brute in the fire tower's light read at a glance; the finale's 23:45
  shot has 17 creatures in view with arrows flying at the Lightless King. The frame budget unchanged (161 instances,
  15 lights with 40 creatures; a live night 12 at most 107 and 17).

**Open points (M2b part 1)**

- The darkness bank swallows the beacon's battle light, but the light pass has no clip: the pool still brightens the
  fog a little left of the bank's edge (night 20 only). A clip at the bank edge in the light shader would make the
  picture match the rule exactly.
- `FrameBuilderTests` is frozen, so the probe's king still walks on frames 2 to 5 of the new ten-frame strip (the
  game uses 0 to 5); his idle moved to 6 and 7, which the test does not pin.
- With the demo realm each wave dies within seconds of reaching the light, so the night reads as bursts; the night
  shots show the liveliest moment of a window, not the moment itself. Whether night 12 of a played realm needs more
  pressure is a tuning question for M5 (the waves' spread, the burn in light).
- Line 1's tower archers stand on the wall walk's ends, not on the towers' crowns (y 132 to 172 lies at the top edge
  of a 175-row screen).
- Glow strips are drawn as actors (over at full brightness) rather than additively in the emissive pass: they do not
  feed the bloom. If the art lane wants the ember eyes to bloom, a low-res copy in the emissive pass (under the body)
  could add it.
- No screen shake, sound or haptics yet (M6): the events reach `GameModel.advanceGame` and `BattleEffects`, where
  the feedback hub will hook in.

**Notes for the UI step (M2b part 2)**

- `GameModel` is the place: `driver` (`SimDriver`: `state`, `balance`, `bot`) is private(set); add the actions the
  cards need there (an order through `Build.order(&driver.state, …)`, recruiting through `Build.recruit`, the tax
  through `Economy.setTax`) and publish gold, happiness and people in `refreshHUD` (every 6 steps) like `day` and
  `clockText`. `isPaused` stops the simulation while a card or the pause sheet is open; the events of each frame
  (`.dawn` for the report, `.defeat` for the defeat card, `.horn`, `.beaconLit`, `.kingSlain`) arrive in
  `advanceGame`, where the dawn save already happens.
- The world-scene value carries `day:`, `hour:`, `alive:`, `seen:` and `shots:` for UI tests; `-GWNight`, `-GWDay`,
  `-GWBuild demo`, `-GWGold`, `-GWHappiness` and `-GWReset` reach any state; `-GWAutoplay play` hides the action
  button.
- The HUD must keep the night clear: in the shots only the clock badge (top right) sits over the picture.

### M2b part 2 in detail: the UI (09.11.2026)

Day 1 to dawn is playable with the whole HUD on top of part 1's engine: walk, build, recruit, set the taxes, live
through the night, read the dawn report; fall and get up again. Everything goes through `GameModel`, whose screen
state machine (`overlay`) pauses the simulation under every card and screen.

**What was built**

- **The action button** (`Core/KingTargets.swift`): what is in front of the king, the nearest in reach
  (`Balance.kingReach`, 40 px). By day a plot's build card (hammer), the barracks' recruit card (coins), the throne's
  tax lectern (crown); from the horn to dawn light (flame) and patch (`Sim.kingAction`), and the barracks still
  recruit. A caption above the button names it ("Brazier", "Recruit", "Taxes", "Light", "Patch 10").
- **The cards** (`Core/BuildCard.swift`, `UI/BuildCardView.swift`): parchment cards above their place with a pointer
  down to it. The build card shows each option the simulation offers (`Build.options`) with the thing's own pixel art
  from the atlas (`UI/SpriteThumbnail.swift`, the art lane's PNGs once merged), price, the time today's builders need
  (their number and the happy pace) and its effect in a few words from `Balance`; greyed with the missing gold, locked
  with its day; arrows step to the other plots in reach; an order goes through `Build.order` and closes the card. The
  barracks' card recruits archers and guards (it stays open for the next one; greyed without gold, closed when nobody
  pays taxes any more); the tax lectern shows each rate's share, its happiness at dawn and the taxes it would bring at
  the next dawn, the war tax locked until day 8.
- **The HUD** (`UI/HUDView.swift`, `UI/RealmStripView.swift`): pause top left (44 pt in a 60 pt area), the realm strip
  centred at the top, the day and clock top right with gold (a coin), the happiness face (five moods, a hop when it
  changes) and the people under it; the numbers roll when they change. The strip (`Core/RealmStrip.swift`, drawn with
  a Canvas): the gorge with the darkness bank, the beacon by stage and fire, the three walls by state (standing,
  damaged, rubble, being built, open), the castle's towers, the town's roofs, the river, a frame for what is on
  screen, the king's crown mark, where he walks to, and at night the creatures as embers; a tap walks the king there at
  a run (`SimDriver.travelTarget`), any drag cancels it.
- **The day and the night**: the horn banner at 19:00 (3.6 s), first light's sweep (`Core/DawnSweep.swift`: a slanted
  wall of warm light at the simulation's sweep front with a glow behind it; the creatures it takes dissolve in puffs of
  soot like killed ones, as do those the Gloom takes back when the Lightless King falls), the dawn report
  (`Core/ReportCard.swift`, `UI/ReportCardView.swift`: the night, the realm, what opens today, the treasury; banners
  for the King slain or withdrawn on night 20, a second chance, no losses), the defeat card (`UI/DefeatCardView.swift`:
  the town's windows going dark one by one; the second chance and "Replay the day"), the pause sheet (resume, the sound
  and haptics switches kept in the save, restarting the chapter after a confirmation).
- **Feel** (`Core/Feedback.swift`, `App/FeedbackHub.swift`): the `FeedbackHub` protocol with a silent hub until M6;
  `FeedbackThinner` turns each frame's events into cues: positional ones (volleys, fire arrows, engines, dissolving
  creatures, glancing blows, the giant's steps) only within about a screen of the king and each at most every 0.12 to
  0.4 s, at most four cues a frame, the big moments first. `ScreenShake`: a breaking wall (3 game px at the king's
  feet, fading to nothing 650 px away) and the Ash Giant's stomp (1.6) sway the camera for 0.45 s; never with Reduce
  Motion.
- **Debug arguments**: `-GWTimeScale`, `-GWHour`, `-GWScreen report|finale|defeat`, `-GWSkipOnboarding` (see the
  table); the scene value adds `kx:` and `dawn:`.
- **Files**: `Core/KingTargets.swift`, `Core/BuildCard.swift` (with `RecruitCard`, `TaxCard`), `Core/ReportCard.swift`,
  `Core/RealmStrip.swift`, `Core/Feedback.swift` (with `ScreenShake`), `Core/DawnSweep.swift`; `App/FeedbackHub.swift`,
  `App/GameModel.swift` (the screen state machine), `App/DebugArgs.swift`, `App/GameStart.swift`; `UI/Theme.swift`
  (palette, cards, coin, face, buttons, `CardScroll`), `UI/Texts.swift`, `UI/HUDView.swift`, `UI/RealmStripView.swift`,
  `UI/BuildCardView.swift` (with the barracks and the tax lectern), `UI/ReportCardView.swift`, `UI/DefeatCardView.swift`
  (with the pause sheet), `UI/OverlayView.swift`, `UI/SpriteThumbnail.swift`; `Core/SimDriver.swift` gained the
  strip's walk, the second chance, replay and restart. Tests: `CardModelTests`, `ReportCardTests` (with
  `RealmStripTests`), `FeelTests`, `ScreenFlowTests` (`DriverMovesTests`, `GameScreensTests`), `UITests/FirstDayUITests`.

**Decisions taken (M2b part 2)**

| Decision | Why |
|---|---|
| A plot counts where it is drawn (its marker, its scaffolding), not at its rule x; the nearest target in reach wins, and the build card's arrows step to the other plots in reach. | Line 1 packs the trap, both braziers and the tower within 70 px (1220 to 1290): the nearest alone would leave brazier B a 17 px window. The caption over the button says which plot the hammer means. |
| A locked plot still shows the hammer; its card names the day it opens. No hammer from the horn to dawn; the barracks recruit at night too. | The task asks for "locked with the unlock day", and walking past line 2 on day 1 teaches the plan of the chapter. Builders work by day only, so a night order would only wait; recruiting at night posts the archer at once (`Build.recruit`). |
| The build card closes after an order; the barracks' and the tax lectern's cards stay open. | One order per plot is all a plot takes; several recruits in a row and comparing rates are common. |
| The HUD keeps the strip truly centred and puts gold, happiness and people under the clock. | Side by side with the clock the right group took 320 pt and left the strip under 100 pt on a 17 Pro. |
| While the reference bot plays (`-GWAutoplay play`) only the clock and the screens show, no horn banner. | The mid-chapter shots stay store shots. |
| The dawn and the defeat stop the world in the very step that brings them. | Up to 15 steps run per frame; without the stop the report opened a few in-game minutes past 06:00. |
| The second chance is granted at once until the rewarded video arrives (M7), once per five nights (ten in endless) by `AdPacing.lastSecondChanceNight`, which the save now keeps with the settings. | The defeat card works end to end today and the pacing rule is already in place. |
| The app coming back from the background opens the pause sheet. | A player returning mid-night should not find the battle running. |
| The shake moves the camera sideways only. | The renderer anchors the ground line; an up-down shake would need a renderer hook, and sideways reads as the thud. |
| First light's lights are `.moon`-kind world lights (steady, no embers), never battle lights. | They are a picture of the sweep the simulation already does. |
| Restarting the chapter takes a new seed made from the old one; the Chronicle stays. | A restart should not replay the same names and nights. |
| Cards hug their content and scroll only when the screen is too short (`HuggingHeight` around a `ScrollView`, the indicator flashing once); a card's background is drawn before its height limit. | A `.frame(maxHeight:)` takes all the height it is offered, so a background drawn after it filled the screen with short content centred in it (rounds `lh-m2b-b1` and `b2`). |
| The cards' close button floats in the corner; the build and barracks cards show the treasury beside their title; a locked tax rate says so in its price column. | The header loses the close button's 44 pt row, the tax lectern's four rates fit on a 17 Pro, and the gold stays in view where a card covers the HUD's. |
| The no-losses ribbon stands in the report's night column; only the King's banner and a second chance cross the card. | On night 20 two ribbons pushed the people below the fold. |
| The build and recruit options show the thing's own pixel art, cut from the renderer's atlas (whole device pixels per art pixel, never smoothed). | The card reads at a glance, and the art lane's PNGs appear there by themselves once merged. |

**Runner rounds (M2b part 2)**

- `lh-m2b-b1` (build, unit, ui FirstDay and MidChapter, ui-de FirstDay) on `613ca59`: the build passed first time.
  `testFirstDay` passed in English (130 s) and German (102 s): the drag, the strip's walk, the build card and the
  order (60 to 48 gold), the barracks, the tax lectern, the horn caught at 19:06, the night, the report of night 1 (25
  creatures stopped, no losses, 49 gold of taxes). `testMidChapter` and `testFinale` passed and ended on their reports;
  the finale's came from the live night: the Lightless King slain, 80 creatures stopped, one guard fallen. Failed: two
  unit tests (`-GWHour`'s run to 06:00 stopped a hair short of the dawn report; the dawn step overshoots 06:00) and
  `testScreens`' clock check (06:15 after the replay). The shots showed the HUD centred on the screen when no action
  button stretched it (fixed before the round came back), the night cards stretched to full height, the tax card
  scrolling (German rows on three lines), the finale's report hiding the people under two ribbons, first light blowing
  the archers out to white.
- `lh-m2b-b2` (build, unit, ui, ui-de, release) on `e3060c8`: ALL PASSED (253 unit test lines passed, every UI test in
  English and German, the light probe and the jitter check unchanged). The HUD sits at the top, the build card shows
  the brazier's own pixel art and hugs its option, the finale's report shows the people again with the no-losses
  ribbon in the night column, the defeat card's town reads with its windows going out. Still to fix: the night cards
  and the report filled the whole height (a `.frame(maxHeight:)` takes all the height offered, and their backgrounds
  were drawn after it), and the tax card still scrolled to its war tax (the close button's 44 pt row and a lock line).
- `lh-m2b-b3` (build, unit, ui, ui-de, release) on `3cb8482`: ALL PASSED. Every card hugs its content (the defeat
  card and the pause sheet centred at their own height), the tax lectern shows its four rates in English and German
  with the war tax locked "Ab Tag 8" in its price column, the build and barracks cards show the treasury; no German
  text clips in any shot, every checked target is at least 44 pt.
- `lh-m2b-b4` (build, unit, ui, ui-de, release) on `9aed974`: ALL PASSED, the final round of this step: 253 unit tests
  (34 new), every UI test in English and German (`testFirstDay` 104 and 109 s, `testScreens` 47 and 50 s,
  `testMidChapter` with its report and first light, `testFinale` with the King's report, the light probe and the jitter
  check unchanged), the Release build; no compiler warning from the game's code. The defeat card's windows now go out
  from the Gloom's side.

**Open points (M2b part 2)**

- The audience and talking (M3), the onboarding (M7), the ads with the report's double taxes, the merchant's gift and
  the real second chance (M7), sound and haptics in the hub (M6).
- The scene's VoiceOver summary ("Day 4, 2 pm. Front: walls 80 %.") is not built; the scene value is still the test
  string.
- The HUD's sizes are fixed (Dynamic Type grows the cards, which scroll).
- A long walk through the strip takes its time (town to front about 30 s at a run); DESIGN keeps the walk.
- First light's front is a soft glow in a still shot (`37-mid-firstlight`); the king and the archers near the outer
  line's fire tower stay very bright from the lantern and the fire tower themselves (the renderer's lights, not the
  sweep).
- Reduce Motion is covered by code (no shake, no hop, no rolling numbers, no card transitions; since the M2b review it
  follows the system setting while the game runs); `FeelTests` checks only the shake, and no UI run uses
  `-GWReduceMotion` yet.

**Notes for the next steps**

- M3's audience plugs into `KingTarget.throne` (today it opens the tax lectern; with petitioners waiting the throne
  should open the audience and the lectern keep its own place beside it); talking adds a `KingTarget` for a court
  member. New cards use `AnchoredCard`, `CardChrome`, `OptionRow` (52 pt rows, an optional sprite) and `CardScroll`.
- M6 gives `FeedbackHub` its real implementation (Comet Cargo's `CueSynth` and `HapticHub`) and sets
  `GameModel.feedback`; every cue already arrives thinned (`FeedbackCue`), and `SaveSettings` holds the switches.
- M7: the rewarded video goes in front of `GameModel.takeSecondChance()` (the pacing is already
  `AdPacing.lastSecondChanceNight`); the report's double taxes and Marek's gift join `ReportCardView`'s footer; the
  onboarding reads `-GWSkipOnboarding`.
- The art lane's PNGs appear on the build and barracks cards by themselves (`SpriteImages` cuts the shared atlas).

### M2b review (09.11.2026): the fix stage

The review of round `lh-join-1` (code and player lenses, every blocker and high finding checked by a separate agent)
found the night too quiet, the archers standing on air, the finale's beacon blown out and the HUD cut by every card.
This stage fixed all five confirmed high findings, the cheap medium ones and the quick, visible low ones.

**What changed**

- **Archers stand on the walks** (`EntityFrames.lineLayout`): the stone wall's crenel floor (dy 42, posts at 5, 18 and
  31), the bastion's walk (dy 57), the palisade's upper beam (dy 25, the stake points behind them); the probe's
  stone-wall archers too. Actors draw after props, so merlons stand behind their legs as on the gatehouse.
- **Line 1's posts** are fixed slots on the painted walk, filled in order (`lineOnePosts`: the middle of the three
  stretches, then a second and a third archer in each), never in the brazier niches (1324 to 1350 and 1369 to 1396,
  `EntityFramesTests`); with the line-1 engine its stretch is left out. Line 1's two torches burn at the walk's ends
  (1306 and 1412, y 126) and have no torch posts on the facade.
- **Schüsse fliegen** (pillar 1): arrows are drawn on an arc peaking about 30 px (picture only, 0 at both ends: every
  arrow still lands where the simulation lands it) with 18 px trails; the loose pose holds 0.3 s and the draw 0.6 s,
  and an archer shows idle while nothing is in reach. The scene value counts archers drawing or loosing (`aim:`), and
  the night shots keep the frame with the most creatures, arrows in flight and shooting archers. The battle itself is
  unchanged: a staggered first shot, slower arrows (220 px/s) and wider-spread summons were tried in three rounds; they
  kept T1 to T8 but broke night 20's step check (see the decisions and the open points).
- **Creatures**: their ash crusts one value step darker (sootling, sootlingB, shadehound, ash brute); bodies drawn left
  to right with a shade by id (0.85 to 1), a light cap of 1.2 (the world 1.6) and, unlit, a 0.9 moonlight rim
  (`ActorQuad.flags` y: rim, w: cap); the gloom bubble is a cold, soft-edged void behind the walls (z 0).
- **The finale's beacon**: its pool warm amber (1.0, 0.80, 0.50), a scene-only warm light at the bowl (x 470, y 140, r
  90) while it burns, its tower's stone one value step darker; fire-arrow pools fireGold.
- **Scene**: the castle's shadows at z 0 (after the courtyard's buildings), the mist at the castle's foot at z 2
  (after the gate in the gateway), the foreground rocks at y -34 (2 px above the ground at most), the gorge keep's glass
  smaller and dimmed in the haze (no pair of eyes); the dusk fog violet with half the haze, the cool bounce held through
  the horn (`Look.bounceDusk` 2.2); empty plots' markers are taller (12x22, a pale staff with a bigger pennant;
  SPRITES.md amended) and bob a pixel (not with Reduce Motion); the king's glow strip
  only from the dusk, his drawn lantern pool on the painted glass (the battle's stays where the simulation holds it).
- **Sound the horn by day** (the review's medium finding on day 1's idle minutes): the pause sheet's second button by
  day; after a confirmation the realm plays on headless to 18:59 (`SimDriver.callTheNight`, the day's 1 s steps) and the
  horn sounds a moment later (`ScreenFlowTests`).
- **HUD and cards**: the clock, the numbers and the strip hide under every card and screen (the pause button under
  the screens); the tax card shows the treasury; the action button is greyed with the missing gold, a cooldown ring or
  while he lights (`KingTargetHold`), and its caption says Build, Upgrade or Rebuild; on the restart's confirmation
  Cancel is gold and Restart quiet with ember; the defeat card shows the town's own cottages at night (cut from the
  atlas), their glass going out one by one.
- **Words**: a woman archer is "Bogenschützin" (`Names.female`, key `fallen.archer.female`); plurals for "left the
  realm" and "taxpayers"; "Houses full: build a house" when the houses cut a dawn's growth (`DawnReport.housesFull`,
  optional); card effects in player words; the sample report on day 8 (it had lost the middle line the day before it
  opened).
- **Saves and engine**: `SaveSettings` and `AdPacing` decode every field with a default; `GameModel` takes its
  `SaveStore` (the tests use a temporary one); a restart starts fresh ad pacing; one `GameModel` per run (made by
  `RootView`); Reduce Motion is followed while the game runs; 20 fps under the pause sheet, the report and the defeat
  card; the filtered scene is cached; the actor shader skips the planes behind an opaque actor.
- **Art** (through the art tools; every other PNG rebuilds byte for byte): the creatures' crusts and the Great Beacon
  as above; the king's cloak roofDeep with banner teal only on its lit folds; the Ash Giant's crown stakes 2 px shorter
  (no longer cut by the frame edge); the damaged palisade with two snapped stakes and a hole through the planks;
  gateBroken's dotted bottom row broken into splinters; the castle towers' edge lines one step softer with course
  joints across their shafts. The probe draws its creatures by the game's rule (no eye dots) and its second
  townsperson is citizenB.

**Decisions taken (M2b review)**

| Decision | Why |
|---|---|
| The higher arrow arc is drawn, not simulated. | The hit must stay where the simulation puts it (one truth for what is seen and what is hit). |
| The battle keeps M2a's archers, arrow speed and summons; the review's staggered volleys and slower arrows stay open for a tuning pass. | Three rounds tried them. `lh-rev-f1` (a waiting archer's first shot 0.15 s × id mod 6 late, arrows 220 px/s, summons 11 px apart with a hash jitter): T1 to T8 held, but the headless 0.1 s step rounded every delay up and night 20 without the beacon drifted past the step check (seed 2: the gatehouse fell at 85.1 against 80.6 s). `lh-rev-f2` (a free-running beat per archer): no rounding, but waiting up to a whole reload weakened the archers (the King slain in 5 of 10, T6 needs 6; an endless realm fell on night 23, T7 needs 35). `lh-rev-f3` (the first-shot delay 0.12 s × id mod 6 with half a step counted as spent, a fixed summon pattern): T1 to T8 held and seeds 2 and 3 agreed within a second, but seed 1 without the beacon diverged in the courtyard after the gatehouse fell (the hearth reached at 107.2 against 92.9 s; the realm held at 1/60 s and fell at 0.1 s). The final round needed a known-good battle, so the simulation went back to M2a's; the picture keeps the higher arcs, the longer trails and poses. |
| Line 1's posts are a fixed list, not an even spread. | Spread over the walk, two archers stood in the niche fires from the horn to dawn on the hero view of the castle. The list keeps every count clear of the niches and the engine. |
| Line 1's torches moved to the walk's ends instead of keeping posts on the facade. | DESIGN says the torches light the archers on the walk; at the gate's height they lit the facade below it and cluttered the symmetric front. No creature or crow ever stood in either light, so the battle is the same. |
| The picture's lantern pool sits on the painted glass; the battle's lantern stays at x + 9, y 16. | Moving the battle light would change what is lit (a tuning change for a 3 px difference); the drawn pool now matches the lantern the player sees. |
| The Ash Giant takes 4 px per walk frame (was 6) and the king 4 (was 7, SPRITES.md amended). | Their planted feet barely move in their strips, so the shorter step slides them less; the giant's true fix is a new leg pose (open point). |
| "Sound the horn" by day sits in the pause sheet beside Resume, after a confirmation; the day plays on headless to 18:59 (the builders finish what they can) and the horn sounds a moment later. | Day 1's 60 gold were spent by 07:30 and two minutes of the day had nothing left; the pause sheet is reachable from anywhere (the lectern card was full, and at the gate the hammer takes the button). It stays after M3, whose audience fills only part of the day. The onboarding (M7) shows it only after day 1's orders. |

**Runner rounds (M2b review)**

- `lh-rev-f1` (build, unit, ui, ui-de, release) on `9652b50`: build, ui, ui-de and release passed; unit failed only
  `SimTests.testTheHeadlessStepKeepsNightTwentysOutcome` (night 20 without the beacon, seeds 1 and 2: the realm fell
  at 03:53 against 04:09, the gatehouse at 85.1 against 80.6 s between the 1/60 s and the 0.1 s step). TuningTests T1
  to T8 passed. The shots: three arrows on their arcs with trails at 01:47, the archers on the stone wall's walk, the
  gatehouse at 22:00 with its two archers between the niche fires and the torches at the walk's ends, the cards and
  screens without HUD fragments, "Edda, Bogenschützin", the defeat card's cottages. The finale's shots kept frames with
  one arrow (the score counted crowds twice); the 23:00 window ran past midnight to its timeout (fixed).
- `lh-rev-f2` (build, unit) on `241a31d`: build passed; unit failed T6 (the King slain 5 of 10), T7 (an endless realm
  fell on night 23) and the step check (seed 1 without the beacon: the hearth reached at 99.7 against 108.6 s, the
  walls alike): the free-running beat made the archers too slow to their first shot. Every new test passed (the horn,
  the relaunch, the night button's holds, line 1's posts, the markers).
- `lh-rev-f3` (build, unit, ui, ui-de, release) on `944da3f`: build, ui, ui-de and release passed, T1 to T8 passed;
  unit failed only the step check (seed 1 without the beacon: the hearth reached at 107.2 against 92.9 s, the realm held
  at 1/60 s and fell at 0.1 s, the walls within a second).
- `lh-rev-f4` (build, unit, ui, ui-de, release) on `1f1410f` with M2a's battle restored: ALL PASSED (the step check and
  T1 to T8 as in M2a, every new unit test, every UI test in English and German, the Release build). The shots: a
  volley of arrows on its arc with trails at 23:43 (5 in flight, 5 archers drawing or loosing) and arrows into the ash
  brute at 01:45 (5 and 5); the brute and the sootlings dark ash in firelight, the unlit hound with its moonlight rim;
  the finale's beacon tower stone under a warm blaze, the gloomweavers' cold voids behind the palisade, arrows at the
  Lightless King at 23:55 (2 in flight; at 22:30 he is not yet in reach, see the open points); the gatehouse at 22:00
  with two archers between the niche fires; the taller plot markers at the gatehouse's foot; the cards and screens
  without HUD fragments; the pause sheet's "Sound the horn" beside Resume; the defeat card's cottages.

**Open points (M2b review)**

- The Ash Giant still slides a little (its walk keys keep the planted feet in place); a second leg key pose would fix
  it.
- "Sound the horn" by day is a product change: Louis should see it once (the pause sheet's second button by day).
- **The review's staggered volleys and slower arrows** (its high finding 3, parts a and c) are not in the simulation:
  every variant kept T1 to T8 but moved night 20's step check without the beacon past its limits (see the decisions).
  They need a tuning pass with `tools/simtune`, which runs the step check for every variant: for example arrows at 260
  or 220 px/s alone, the 0.12 s half-step stagger alone, and a step check that compares the courtyard phase after the
  gatehouse falls with a wider window (the 19 of 58 variants that already failed it in M2a fail there too).
- The Lightless King's summons still leave 5 px apart (the fixed 11 px pattern of round f3 was part of the step-check
  trouble); the picture separates the crowd by drawing it left to right with a shade by id.
- The finale's shots: at 22:30 the Lightless King has not reached the archers' reach yet, so `34-finale-2230` shows no
  arrow; windows from 23:00 to 00:30, when the archers turn on him, would show the arrows the review asked for.

### M3 in detail: the petition engine and the court's state (step 1, 09.11.2026)

Step 1 of M3 builds the audience's rules as pure, deterministic code with tests. The audience card, talking and the
court on screen come in the UI step; step 3 draws the castle's world changes, M4 the town's.

**What was built**

- **Petition data** (`Core/PetitionData.swift`): `Petition`, `PetitionChoice`, `PetitionEffect`, `PetitionChance`,
  `PetitionCatalog`. The files are `Resources/Petitions/petitions-<group>.json`, each `{"petitions": [ … ]}`. The loader
  decodes every petition on its own: in the app a broken petition costs only itself (a Debug build prints the problem),
  and `PetitionDataTests` fails on any problem. `PetitionCatalog.standard` is the app bundle's set; without a bundle (a
  command-line run started in the game's folder) it reads `Resources/Petitions`.
- **The engine** (`Core/PetitionEngine.swift`): `prepare` draws today's queue, `hear` applies a choice, `horn` sends the
  waiting home, `dawn` spends the night modifiers and prunes the history, `blocker` says why a choice is greyed,
  `waiting` lists today's petitioners with their petitions, `botChoice` and `holdAudience` are the reference bot's.
- **The court's state** (`Core/PetitionCourtState.swift`): `GameState.court: CourtState?` holds today's queue
  (`Petitioner`: the petition, why it came, its look), the history of shown petitions (`HeardPetition`, the last ten
  days), every petition ever heard, the count heard, the follow-ups, the world changes, the night modifiers, what
  petitions unlocked and the builders they added. The story's own state lives in `GameState.flags`.
- **Night modifiers** (`Core/PetitionNight.swift`): `NightModifier` parses the ids, `NightPlanModifiers` folds tonight's
  and is read by `Battle.planNight` and `Battle.bankEdge`.
- **The court** (`Core/CourtSpeakers.swift`, `CourtLayout.swift`, `CourtLines.swift`, `CourtWorld.swift`,
  `CourtText.swift`, `CourtValidator.swift`): every speaker with body and portrait, the court's places, the court's talk,
  the world change registry, the story text lookup (`StoryText`), the content validator.
- **Sprites**: every M3 id of SPRITES.md is a `SpriteID` with its size and frames, with readable placeholders
  (`Render/PlaceholderCourt.swift`): the court and guests with walk, idle and talk frames and their glow strips, the
  petitioner bodies, the story portraits and the portrait parts drawn in the swap ramps, the rooms and the props.
  `Render/PortraitComposer.swift` composes a townsfolk portrait from the parts and the target ramps (from the atlas, so
  the art lane's PNGs show by themselves). The atlas stays one page.
- **Hooks in existing files** (a few lines each): `Sim` (`PetitionEngine.horn` at the horn, `.dawn` at dawn), `Battle`
  (`composition` takes a budget scale; `planNight` and `bankEdge` read tonight's modifiers), `GameState` (`court`,
  `lodgeBuilders`, `builderCapacity` with the petitions' builders, `isUnlocked` with early unlocks), `Build.order`,
  `BuildCard`, `RealmStrip` and `Autoplay` ask `isUnlocked`, `Autoplay.hearsPetitions`, `SimDriver` draws each day's
  petitioners, `PlaceholderArt` asks `PlaceholderCourt`.
- **Content**: five sample petitions (`petitions-samples.json`: the day-1 tutorial `first_plough`, `well_repair` and its
  follow-up `well_dispute` with a chance, `crow_rags` with a night modifier, `old_sergeant` with a guard), eleven court
  lines (`Resources/Court/lines.json`) and `Resources/Story.xcstrings` in English and German with every speaker's name
  and role. The content step writes the rest (step 2 replaced the samples with the full content, see the next
  section).
- **Tests** (new files): `PetitionTests`, `PetitionNightTests`, `PetitionDataTests` (its attachment
  `petition-validator` lists every problem), `CourtTests`, and `CourtSheetTests`, which attaches `m3-sprites`: every
  M3 sprite as the atlas draws it (the placeholders until the art lane's PNGs land), composed portraits of every
  townsfolk archetype included.

**The petition schema**

| Field | Type | Rule |
|---|---|---|
| `id` | string | unique; lowercase letters, digits and `_` |
| `speaker` | string | a speaker id (see "Speakers") |
| `kind` | `story`, `random`, `endless` | story: on its days in the chapter until heard; random: by weight in the chapter and in endless; endless: by weight in endless only |
| `chapter` | int, optional | 1 (left out: 1) |
| `days` | `[day]` or `[from, to]`, optional | both included; left out: any day. A story petition needs it, or a `schedule` that leads to it |
| `weight` | number, optional | the random draw's weight (left out: 1); 0: only as a follow-up |
| `requires`, `forbids` | flag lists, optional | every required flag set and no forbidden one |
| `happinessRange` | `[low, high]`, optional | within 0 to 100, both included; checked for random draws and story days |
| `text` | key | the request: at most 240 English characters |
| `hint` | key, optional | Odile's one-line counsel (the Counsel button): at most 140 |
| `counsel` | int, optional | the index (from 0) of the choice Odile's counsel favours (usually right, not always); the reference bot takes it when it can |
| `choices` | 2 or 3 | each `{"label": key, effects…, "reaction": key}`: label at most 40, reaction at most 140; at least one choice costs neither gold nor people, so a poor realm can always answer |

| Effect (in a choice or a chance's side) | Rule |
|---|---|
| `gold` | added. A cost must be affordable, else the choice is greyed (`ChoiceBlock.gold`); gold never drops below 0 (a chance's side is not checked in advance) |
| `happiness` | added, kept within 0 to 100; at most ±10 per effect |
| `citizens` | +n new people move in (also beyond the houses' room: growth waits for room); −n people leave, taxpayers first (needs n taxpayers) |
| `archers`, `guards` | +n new people arrive as soldiers of that kind (like the volunteer at dawn, names from the seeded stream); −n soldiers of that kind lay down their arms and go back to the town as taxpayers, the last recruited first (needs n of them) |
| `builders` | castle staff beyond the lodge (`CourtState.extraBuilders`: a new lodge keeps them); the castle keeps at least one |
| `flags` | `name` sets a flag, `-name` clears it |
| `world` | a registered change id (see "World changes"); `-id` takes it away again |
| `schedule` | `[{"id": …, "inDays": n}]`, n at least 1: that petition comes on that day if its `requires` and `forbids` still hold (its `days`, `weight`, `happinessRange` and the five-day rule do not count); one that cannot come is dropped |
| `unlock` | `warTax`; `blessing` (the chapel's blessing, +1 happiness every dawn), `-blessing` lifts it; `line2`, `line3`, `beacon` open those plots before their day |
| `night` | modifier ids for the coming night (see "Night modifiers") |
| `chance` | `{"p": 0 < p < 1, "then": {…}, "else": {…}}`: rolled with the simulation's seeded stream when chosen; the side's `reaction` replaces the choice's |
| `reaction` | the text after the choice |

`CourtValidator` checks every file against this schema (an unknown key, a typo the decoder would skip, is a problem),
every reference (speaker, follow-up, world id, unlock, night modifier), every text key in English and German and the
English limits; `PetitionDataTests` runs it over the bundle's files and the source `Story.xcstrings`.

**The rules of the queue** (`PetitionEngine.prepare`, called from 06:00 to the horn)

- Day 1 brings one petitioner (the tutorial in the chapter), every other day 2 to 4: story petitions on their days
  first, follow-ups due today next, then random ones drawn by weight among the eligible until the day's number is
  reached. Story petitions and follow-ups are never dropped, even past 4; when too few are eligible the day has fewer.
- Eligible random petitions: kind `random` (and `endless` only in endless), weight above 0, chapter 1, on their days,
  their flags and happiness range allowing, and not shown in the last five days (a petition shown on day d, heard or
  sent home, may come again from day d + 5).
- A story petition comes on each day of its range until it is heard (so `[4, 5]` gives a second chance), never in
  endless. A new realm in endless therefore hears random petitions only.
- The draw uses its own stream made from the seed and the day (`queueSeed`), so the queue never moves the simulation's
  random stream: the same seed gives the same queue, and adding content does not reshuffle the nights. Each
  petitioner's look (31 bits from the seed, the day and the petition) chooses a townsfolk's portrait and name.
- The queue is drawn once a day and lives in the save; the dawn snapshot holds it.
- At the horn the petitioners still waiting go home unheard (`PetitionEngine.horn`): each costs 1 happiness at dawn
  (`Balance.happinessPerUnheard`), shown in the dawn report's realm column ("Petitioners unheard −n"), and counts as
  shown for the five-day rule.

**Night modifiers** (a choice's `night`, for the night after the day it was heard; spent at dawn)

| Id | What the battle does |
|---|---|
| `crows-n`, `hounds-n`, `brutes-n`, `weavers-n`, `sootlings-n` (n 1 to 9) | `planNight` takes n creatures of that kind out of tonight's plan (never fewer than none) |
| `wave-Ppct`, `wave+Ppct` (P 1 to 50) | tonight's budget P % smaller or bigger, every kind in its share; several add up, at most ±50 % |
| `fog` | the darkness bank comes 60 px further tonight (`bankEdge`; its edge at most 660), so the lights inside it shrink to 0.6 of their radius |

Without a modifier the night is planned exactly as before (the same random draws), so T1 to T8 move only by what
petitions change.

**World changes** (`CourtWorld.registry`; the content step adds ids there with a line here)

| Id | Where | Drawn in | What |
|---|---|---|---|
| `castle.statue` | courtyard, x 1680 | M3 step 3 | a stone statue of Saint Taper with his lantern (`statue`) |
| `castle.guards.wall` | castle front, x 1340 | M3 step 3 | two guards posted on the wall walk by day |
| `castle.banners.new` | great hall | M3 step 3 | the hall's banners renewed, bright teal with gold lanterns |
| `castle.hall.tapestry` | great hall | M3 step 3 | a tapestry of the old king Aldric |
| `castle.chapel.bell.missing` | chapel | M3 step 3 | the chapel's bell gone from its gable |
| `castle.chapel.candles` | chapel | M3 step 3 | votive candles before the altar |
| `castle.keep.window.dark` | keep | M3 step 3 | one keep window dark at night |
| `castle.courtyard.stall` | courtyard, x 1486 | M3 step 3 | Marek's cart stays every day |
| `castle.seren.lantern` | great hall, x 1950 | M3 step 3 | Seren's grey lantern hangs in the far corner |
| `town.well.repaired` | market, x 3022 | M4 | the well rebuilt: roof, rope, bucket |
| `town.bridge.mended` | x 3430 | M4 | a footbridge over the brook |
| `town.festival.tent` | market square | M4 | a striped festival tent |
| `town.statue` | market square | M4 | a statue |
| `town.barn.burnt` | first field | M4 | the barn burnt black |
| `town.market.stall` | market | M4 | an extra stall |
| `town.lanterns.extra` | lanes | M4 | more lanterns at night |
| `town.window.dark` | a cottage | M4 | a dark window: a family left |
| `town.garden` | first house | M4 | flower boxes and a vegetable garden |
| `town.scarecrow` | far field | M4 | a scarecrow |

**Speakers** (`Speakers`): the court `odile`, `brannock`, `pip`, `hesper`, `tamsin`, `bram`, `marek`, `seren` and the
guests `serLudo`, `bard`, `envoy`, `herald` have their own bodies (8 frames: walk 0-3, idle 4-5, talk 6-7) and
portraits; Seren is "The Stranger" (`speaker.stranger.name`) with the hooded portrait until day 15 or the flag
`seren_revealed`. Townsfolk archetypes walk in a townsfolk body and get a composed portrait chosen from their look:

| Archetype | Body | Portrait (clothes; faces; beards; hair; hats) |
|---|---|---|
| `farmer` (man) | `citizenC` | smock, tunic; old, square, long, round; full, long, stubble, short; short, tousled, bald; straw hat, wool cap, none |
| `farmwife` | `citizen` | dress with apron, smock; round, long, old, young; –; bun, braids, long; headscarf, straw hat, none |
| `townswoman` | `petitionerD` | dress with apron; round, long, young; –; long, bun, braids, curly; headscarf, none, flower wreath |
| `townsman` | `petitionerE` | tunic, fine coat; round, long, square, young; none, stubble, short, moustache; short, curly, tousled; none, wool cap, feather cap |
| `merchant` | `petitionerE` | fine coat; round, long, square; short, full, moustache; short, curly, bald; feather cap, none |
| `soldier` | `guardsman` | mail and surcoat (teal); square, long, old; stubble, short, full, moustache; short, bald; helm, none |
| `builder` | `builder` | leather apron; round, square; stubble, full, short; short, tousled, bald; wool cap, none |
| `widow` | `citizen` | dress with apron, robe; old; –; bun, long (grey); headscarf, hood |
| `child` (girl or boy) | `citizen` (no child body yet) | smock, tunic; child; –; child's mop, braids; none, flower wreath or wool cap |
| `noble` (man) | `petitionerE` | fine coat, robe; long, round, square; none, short, moustache; curly, short, long; feather cap, none |
| `refugee` (woman or man) | `citizenB` | rags; long, old, young, round; stubble or none; long, braids or tousled, short; hood, headscarf, none |

Every archetype also chooses its skin, hair and cloth target ramps (SPRITES.md). A townsfolk petitioner's name comes from
`Speakers.womensNames` or `mensNames` by the look (names are never translated).

**The court's places** (`CourtLayout.figures(day:hour:flags:queue:catalog:)`, pure)

| Who | By day (06:00 to the horn) | At night |
|---|---|---|
| Odile | beside the throne at 1856, stepping to the tax lectern (1846) | by the hearth, 1860 |
| Brannock | between 1428 (the gatehouse's back) and 1470 | at the gate, 1424 |
| Pip | wandering 1612, 1690 (courtyard), 1770, 1700 (hall) | by the hearth, 1916 |
| Mother Hesper | the chapel's altar 2058 and pews 2012 (step 3: the art lane's spots; first 2052 and 2010) | tending the hearth, 1900 |
| Tamsin | the kitchen's table 2158 and the oven-hearth under the chimney 2208, both facing right (step 3; first 2146 and 2196) | the kitchen, 2170 |
| Bram | the smithy, 1566 to 1588 | the smithy, 1580 |
| Marek | by his cart (1486) at 1542 on his days: every third day and any day he brings a petition | gone |
| Seren | at the front gate (1352) the day her petition waits; from `stranger_in` the hall's far corner (1950); gone after `seren_handed_over` | the corner |
| Guests | standing in the hall (1706, 1754, …) while their petition waits | gone |
| Townsfolk petitioners | at the benches' four places 1788, 1772, 1740, 1724 (the next one nearest the throne), more standing behind | gone (sent home at the horn) |

Rounds walk at 16 px/s (Pip 22) with a walk frame every 7 px and a breath every 0.8 s, offset so the court never moves
in step. Court members who petition stay at their round; the audience calls them up. `CourtLayout.props` gives the two
benches (1712, 1760), the tax lectern (1834), Marek's cart on his days and the statue once `castle.statue` shows.

**Court lines** (`Resources/Court/lines.json`, `{"lines": [ … ]}`): `id` (lowercase), `speaker` (a court member or a
guest), `days` (optional `[from, to]`), `requires`, `forbids`, `weight` (optional, above 0), `text` (a key, at most 120
English characters), `about` (optional petition id: a hint, said only while that petition waits today). The lines a
speaker may say today come in a fixed order: hints about today's waiting petitions first, then the rest, each group in a
weighted order drawn from the seed, the day and the speaker; talking again goes on through the list
(`CourtLineBook.line(for:state:nth:)`). `hasHint` puts the speech mark over a court member with a hint.

**Story.xcstrings keys**: `petition.<id>.text`, `.hint`, `.c1` … `.c3` (labels), `.r1` … `.r3` (reactions), `.r1a` and
`.r1b` (a chance's then and else); `line.<id>`; `speaker.<id>.name` and `.role`, `speaker.stranger.name`. Manual keys with
English and German values (`extractionState` manual); `StoryText.string` reads them.

**Decisions taken (M3 step 1)**

| Decision | Why |
|---|---|
| The drivers draw the queue (`SimDriver` after every step, the bot before it acts), not `Sim` itself; `Sim` only sends the waiting home at the horn and spends the night's modifiers at dawn. | The simulation stays free of the catalogue, and every test that steps `Sim` without a court plays exactly as before (no unheard petitioners); every path the game takes (new realm, save, `-GWDay`, replay, restart, second chance) goes through a driver. |
| The queue has its own stream from the seed and the day; only `chance` rolls `GameState.rng`. | The same seed gives the same queue, and adding or reordering petitions never reshuffles the nights the tuning measured. |
| `hint` is Odile's counsel line and `counsel` the index of the choice she favours. | DESIGN's example already had `hint`; the bot needs the choice, the card needs the line. Hints from the rest of the court about today's petitions are court lines with `about`. |
| Unheard petitioners cost 1 happiness each at dawn and count as shown. | The rule stood in "Happiness" and in `Economy` already; the report's realm column already names the reason. |
| `archers` and `guards` add new people as soldiers; taking them sends soldiers home as taxpayers. | The volunteer at dawn sets the pattern; a petition that wants a man to leave the realm adds `citizens: -1`. |
| `unlock` opens `warTax`, the chapel's `blessing` (`-blessing` lifts it) and the plots of `line2`, `line3`, `beacon` early; the days in `Realm` stay. | No build is locked by anything but a plot's day; an unheard story petition must never lock the chapter (the war tax still unlocks at dawn 8 and the beacon on day 11 by themselves, see the open points). |
| Night modifiers are a small set: fewer of a kind, a smaller or bigger budget, fog. | Each is honoured by code that already exists (the plan and the bank edge), and each is visible in the battle. |
| The bot hears every petitioner first thing each day, wherever the king stands. | The tuning bot needs no walk to the throne; the live bot (`-GWAutoplay play`) is for night shots. |
| Seren waits at the front gate on the day of her petition. | "At dusk a stranger asks to be let in": she stands outside until she is. |
| Petition files are `petitions-<group>.json`; the lines file is `lines.json`. | An Xcode group copies resources flat into the bundle: the prefix finds the petition files and keeps the names apart from every other resource. |
| Frame 0 of beard, hair and hat holds one texel of alpha 1 in the placeholders. | The contract leaves it empty and the composer skips it, but `AtlasTests` wants no empty placeholder frame. |

**Notes for the content step**

- The reference bot hears every petition (Odile's counsel when it can pay, else the cheapest), so counsel choices move
  T1 to T8. Keep each day's net small: the counsel choices' happiness over days 1 to 7 below +5 in all (T4's high-tax
  realm reaches 25 by dawn 8 without petitions; the bar is below 30), gold close to nothing over the chapter (T3's
  beacon by day 18 had one day of margin), no night modifiers in counsel choices on days 19 and 20 (T6), and endless
  petitions move T7. If a target fails, change petition values, never `Balance`, and write it here.
- The tutorial (day 1) counsel choice must change neither gold nor the night: `AutoplayTests` pins the first
  morning's gold and `SimTests` night 1's creatures.
- Story beats: day 4's stranger is a story petition by `seren` (she waits at the gate) whose yes sets `stranger_in`;
  the war tax still unlocks by itself at dawn 8 (`Realm.warTaxDay`) and the beacon site on day 11 (`Realm.plots`): when
  Brannock's and Odile's petitions take them over, remove those automatic unlocks in the same step (step 2 kept them,
  see its decisions).
- Run `PetitionDataTests` (the validator) after every batch; its attachment `petition-validator` lists every problem.

**Notes for the UI step**

- The audience: `PetitionEngine.waiting(state, catalog: .standard)` gives today's petitioners in order with their
  petitions; `Speakers.speaker(id)` the body, portrait sprite (`portraitFrame` for Seren) or the composed portrait
  (`Speakers.recipe(id, look:)` and `PortraitComposer.compose(recipe, atlas:)`); `StoryText.name` and `.role` the card's
  header; `PetitionEngine.blocker(choice, state)` greys a choice with its reason; `PetitionEngine.hear(&state, choice:,
  at:, catalog:, balance:)` returns the `PetitionOutcome` (reaction key and every change, for the HUD's numbers). The
  clock stands still while the card is open (`GameModel.isPaused`).
- The hall: `CourtLayout.figures(state, catalog:)` places the court, the guests and the petitioners (sprite, frame,
  facing, room); `CourtLayout.props(state, catalog:)` the benches, the lectern, the cart and the statue;
  `CourtLayout.audienceSpot` (1800) is where the heard petitioner stands before the throne.
- Talking: a `KingTarget` for the court member in reach, `CourtLineBook.standard.line(for:state:nth:)` for the line,
  `hasHint` for the speech mark (`speakerMark`). The throne opens the audience while petitioners wait; the tax lectern
  keeps its own place (1834).

**Open points**

- `tools/simtune/run.sh` compiles a fixed list of Core files; since the bot hears petitions it needs
  `Core/Petition*.swift` added to its list (this step must not edit `tools/`). With them it reads `Resources/Petitions`
  from the game's folder and measures with the petitions, as `TuningTests` does.
- `tools/tune.py` mirrors the economy without petitions.
- There is no child body in the sprite contract: a child petitioner walks as `citizen`.
- The Chronicle does not count petitions heard yet (`CourtState.heardCount` holds the realm's count).
- A line unlocked early by a petition is still named in the dawn report on its normal day.

**Tuning with petitions** (round `lh-m3-a1`: the five samples, every reference bot hearing every petitioner with the
fixed policy; the realm that builds nothing hears none)

| Target | Measured with the samples (M2a without petitions) | Target value |
|---|---|---|
| 1 | nights 1 to 10 held in 3 of 3 seeds, hearth never touched, 0 soldiers lost (the same) | hearth untouched, at most 3 lost |
| 2 | falls on night 3 (3 of 3, the same) | night 2 or 3 |
| 3 | beacon finished on days 16, 16, 16 (17); with low tax not by day 20 | by day 18; low tax cannot |
| 4 | high tax: 28 at dawn 8 (25: the tutorial's +1 and the well's +2); low tax: lowest 84 over dawns 8 to 20 (92) | below 30; above 70 |
| 5 | first dawn taxes 49 buy 3 builds; 12 buildings by day 10 (11) | 2 to 3; 8 to 12 |
| 6 | with the beacon won 10 of 10, the King slain 10 of 10, 58 to 69 s after he left the Gloom, 8 to 22 s of light left; without 4 of 10 (5) | at least 8 won and 6 slain; 3 to 6 |
| 7 | endless falls on nights 46, 52, 41 (56, 45, 42) | 35 to 60 |
| 8 | last wave 79.9 s after nightfall; night 3 (37 creatures): 41 sim entities, 11 battle lights | by 84 s; under 300 and 40 |

Every target holds without a change to `Balance` or to the samples. Margins to watch: T5 now sits on its upper edge
(happiness 80, and with it the builders' 20 %, comes one dawn earlier with the samples' +3), and T4's high-tax realm
keeps 2 points. More generous counsel choices break T5 first: the content step should either keep the counsel
austere or ask the lead to widen T5 (a petition-rich realm builds faster by design).

**Runner rounds (M3 step 1)**

- `lh-m3-a1` (build, unit) on `840dccd`: ALL PASSED on the first build (293 unit test lines, every new test; the
  validator found no problem with the bundle's files against the source `Story.xcstrings`; T1 to T8 as above).
- `lh-m3-a2` (build, unit, ui) on `4d03999`: ALL PASSED (294 unit test lines, every UI test in English; T1 to T8
  unchanged). `m3-sprites` shows every placeholder readable: each court member and guest by colour and outline (Odile's
  plum robe and bun, Brannock's teal surcoat, Pip's bell cap, Hesper's staff flame, Tamsin's apron, Bram's hammer,
  Marek's hat and green coat, Seren's hood and grey lantern, Ser Ludo's helmet, the herald's banner), the story
  portraits, varied composed portraits for every archetype, the rooms and the props. In `45-report` the first day's
  dawn report names "Petitioners unheard −1": the UI test never sat on the throne, so the tutorial's farmer went home
  at the horn. The light probe, the mid-chapter, finale and first-day shots are unchanged (nothing of the court is drawn
  yet).
- `lh-m3-a3` (build, unit, ui) on `0dee55b` (the per-step checks copy nothing while nothing changes): ALL PASSED,
  the final round of this step: 294 unit tests, every UI test in English, T1 to T8 as above, the validator without a
  problem; no compiler warning from the game's code.

### M3 in detail: the audience's content (step 2, 09.11.2026)

Step 2 wrote what the audience says: chapter 1's story, the random petitions of the town, the front, the court and the
guests, the endless-only petitions, Odile's counsel for every petition, a reaction for every choice and the court's
talk, all in English and German (the other six languages come in M7).

**What was written**

- **83 petitions** in six files: `petitions-story.json` (18 story petitions, follow-ups included), `petitions-town.json`
  (21), `petitions-front.json` (10), `petitions-court.json` (12, petitions by court members), `petitions-guests.json` (7:
  Ser Ludo, the bard, the envoy) and `petitions-endless.json` (15). By kind: 18 story, 50 random, 15 endless only. The
  five samples live on in them (`first_plough` in story with its flag `plough_blessed`; `well_repair` and `well_dispute`
  in town; `crow_rags` and `old_sergeant` in front, now once per realm); `petitions-samples.json` is gone.
- **118 court lines** (`Resources/Court/lines.json`): Odile 15, Brannock 19, Pip 19, Hesper 14, Tamsin 17, Bram 8,
  Marek 8, Seren 8, Ser Ludo 3, the envoy 3, the bard 2, the herald 2. 29 are hints (`about`), Tamsin's the most; 13
  echo a choice the king made (Gerald in his jar, the scarecrow with Brannock's face, verse nine, the dark keep window).
- **Story.xcstrings**: 734 petition and line keys beside the 33 speaker keys, English and German; about 11,900 English
  and 11,600 German words (German runs 13 % longer in characters). Voices: Odile dry and sarcastic ("my lord"), Brannock
  gruff ("lord"), Pip jokes ("Your Wickship", German "Eure Dochtheit"), Mother Hesper calm and ominous, Tamsin
  gossip with hints, Bram in few words, Marek sly ("Your Radiance", "Eure Strahlkraft"), Seren quiet ("Lantern", after day 15 "lord"), the
  herald cold ("heir of the thief"). German addresses the lord with "Ihr" and "Euch".
- The files were generated from authoring modules with a checker that mirrors `CourtValidator` (in this step's scratch
  space; `tools/` was not this lane's to edit). The JSON files and Story.xcstrings are the source from now on: edit them
  directly, and `PetitionDataTests` checks every change.

**The story of chapter 1** (story petitions come on each day of their range until heard; the counsel in bold)

| Days | Petition | Speaker | The choices |
|---|---|---|---|
| 1 | `first_plough` | farmer | **bless the plough** (+1, `plough_blessed`) / kings bless no tools (−1); Odile's counsel explains the card |
| 2–3 | `tower_request` | Brannock | **promise the tower** (`tower_promised`) / light first (`light_first`); the building tutorial's end |
| 4–5 | `stranger_gate` | Seren, hooded, at the front gate | **open** (`stranger_in`, `castle.seren.lantern`) / keep it shut (`stranger_turned_away`) |
| 6–7 | `marek_arrows` | Marek | **buy, 15 gold** (`cheap_arrows`, `bad_arrows` next day) / Bram makes our arrows / let Bram test one (70 %: +10, `marek_caught`; else bought). Odile is wrong here; Tamsin's and Bram's hints know better |
| +1 | `bad_arrows` | Bram | **reforge, 5 gold** (`arrows_reforged`) / shoot them anyway (`wave+15pct`) / send them back (50 %: +15, `marek_caught`; else −1) |
| 8–9 | `war_tax` | Brannock | **promise the war tax** (`war_tax_promised`) / bleed the guilds once (+40, −4, `guilds_levied`) / the town pays enough (+2, `war_tax_refused`) |
| 10 | `hesper_giant` | Mother Hesper | **a vigil alone** / call the town to the chapel (−10, +3, `castle.chapel.candles`) / do not frighten them (−1): the Ash Giant's night |
| 11–12 | `beacon_plans` | Odile | **build it** (`beacon_vowed`) / show the town the plans (+2) / the walls first; every choice `unlock`s the beacon. She reads that its light breaks any darkness of the Gloom |
| 13–14 | `refugees_gate` | refugee | let all six in (+6 people, `refugees_in`) / only the children and the old (+3, −2, `refugees_some`), both bring `ash_cough` in 3 days / **turn them away** (−3, `refugees_turned_away`). Odile's coldest counsel; Pip and Tamsin say otherwise |
| +3 | `ash_cough` | farmwife | **pay the herb-wife** (−15, +1) / send the sick away (−2 people, −2) / it will pass (50 %: −4, −1 person, `town.window.dark`); skipped when `herbs_grown` (the widow's herb garden) |
| 15–16 | `seren_reveal` (needs `stranger_in`) | Seren | **then we bring him home** / tell the town (50 %: +4 or −4) / why only now; all set `seren_revealed`. She kept the Great Beacon, rode with Aldric, and the Gloom made him the Lightless King: only the beacon's light can hurt him |
| 15–16 | `seren_at_gate` (without `stranger_in`) | Seren, at the gate | **open this time** (`stranger_in`, the lantern) / say the rest from there (`seren_outside`); both set `seren_revealed` and tell the same truth |
| 17 | `herald_demand` (needs `stranger_in`) | the herald | hand her over (+2, `seren_handed_over`, `truce`, the lantern taken down, `wave-50pct`) / **she stays** (−2, `wave+15pct`, `herald_refused`) / let him come and try (+3, `wave+25pct`, `herald_mocked`) |
| 17 | `herald_alone` (without `stranger_in`) | the herald | pay 60 gold of tribute (`truce`, `tribute_paid`, `wave-50pct`) / **not a coin** (−1, `herald_refused`) |
| +1 | `truce_drill` (needs `truce`) | Brannock | drill the young (−20, +2 archers) / **let the town rest** (+2); both `wave-50pct` |
| +2 | `truce_end` (needs `truce`) | Mother Hesper | **light a candle for what we paid** (`castle.chapel.candles`) / no regrets; both `wave-50pct` |
| 19 | `pip_farewell` | Pip | **tell the joke** (+2, `pip_joke_told`) / save it for after (`pip_joke_saved`) |
| 20 | `last_stand` | Brannock | the last morning's word to the men: **"We hold until dawn"** / "We bring Lord Aldric home" / "I am afraid too. I stay." (`speech_dawn`, `speech_aldric`, `speech_honest`; nothing else) |

The herald's "three nights" are the handover's night and the nights of its two follow-ups (17, 18, 19), never night 20.

**Follow-up chains**: `marek_arrows` (buy, or a test that lands the bad lot) → `bad_arrows` +1 day; `refugees_gate`
(all, or the children and the old) → `ash_cough` +3 (dropped with `herbs_grown`); `herald_demand` or `herald_alone`
(the bargain) → `truce_drill` +1 and `truce_end` +2; `well_repair` (refused) → `well_dispute` +3; `ludo_arrives` (dared
to slay the Gloom) → `ludo_returns` +2; `bard_song` (no ballad) → `bard_satire` +4. Petitions that need an earlier
choice: `plough_harvest` (`plough_blessed`), `seren_watch` (`stranger_in`, days 6 to 14), `ludo_tourney`
(`ludo_stays`), `envoy_tide` (`envoy_met`).

**The flags the story uses**

| Flag | Set by | Read by |
|---|---|---|
| `stranger_in` | `stranger_gate`, `seren_at_gate` (open) | `CourtLayout` (Seren in the hall's corner), `seren_reveal`, `herald_demand`, `seren_watch`, Seren's and the court's lines |
| `stranger_turned_away` | `stranger_gate` (shut) | Pip's line |
| `seren_revealed` | `seren_reveal`, `seren_at_gate` | `Speakers` (her name and face before day 15), lines |
| `seren_handed_over` | `herald_demand` (hand over) | `CourtLayout` (she is gone), the endings (no Bright Crown), lines |
| `truce`, `tribute_paid` | the herald's bargain | `truce_drill`, `truce_end` |
| `herald_refused`, `herald_mocked` | the herald refused | Brannock's and Pip's lines |
| `cheap_arrows`, `marek_caught`, `arrows_reforged`, `arrows_refused` | Marek's arrows | `bad_arrows`, lines |
| `war_tax_promised`, `guilds_levied`, `war_tax_refused` | `war_tax` | Odile's lines |
| `beacon_vowed`, `beacon_shown`, `beacon_doubted` | `beacon_plans` | the beacon lines of Odile, Pip, Hesper and Bram |
| `refugees_in`, `refugees_some`, `refugees_turned_away` | `refugees_gate` | Odile's line; free for the endings |
| `vow_aldric`, `aldric_known`, `seren_doubted`, `seren_outside` | the reveal | free for the endings |
| `pip_joke_told`, `pip_joke_saved`, `speech_dawn`, `speech_aldric`, `speech_honest` | days 19 and 20 | Pip's line; free for the ending scenes (Pip may tell the saved joke) |
| `plough_blessed`, `herbs_grown`, `ludo_stays`, `ludo_dared`, `envoy_met` | random petitions | the petitions above |

Every random petition sets a flag of its own in each choice and forbids it, so it comes once per realm
(`well_fixed`, `bridge_done`, `goat_judged`, ...); three come back after five days while their problem stays unsolved
(`well_repair`, `footbridge`, `lantern_lanes` when refused). Many flags only record a choice (`gerald_kept`,
`scarecrow_brannock`, `ballad`, `bell_melted`, ...) and let the court's lines answer it.

**The random petitions**

- Town (21): the well and its quarrel, the blessed plough's harvest, a goat in the chapel, a wedding (happiness 55 and
  up), the footbridge, a market statue (50 and up), a barn set alight by our own fire arrow, lanterns for the lanes, a
  family leaving (45 and below), the widow's garden, the children's Brannock scarecrow, a ribbon merchant's stall, an
  alehouse brawl, the miller's hoard (60 and below), amulets of the Flame, a hungry thief, the hunting rights, a
  whispering cellar, the masons' courtyard statue, a border family (from day 21: endless, or a new realm's later days).
- Front (10): the crow rags, the old sergeant, a deserter, a scout's pitch, the archers' pay, a child who wants to be an
  archer (a lamp-runner, German "Lampenkind"), the tar pits, guards on the wall walk, Gerald the sootling in a pickle
  jar, the widow's penny.
- Court (12): Bram's chapel bell, Tamsin's oven, Hesper's offering bowl (the chapel's blessing), Pip's Minister of Jokes,
  Odile's eighteen missing gold, Marek's spyglass, relic (Saint Taper's "fingerbone") and cart, the old banners, the
  widow's tapestry of Aldric, the dark keep window, Seren's night on the wall.
- Guests (7): Ser Ludo (arrives days 3 to 12, his great lantern, his tournament), the bard (a ballad, then a satire),
  the envoy from the coast (the black tide climbing to the lighthouse: chapter 2's teaser; archers for silver, then a
  promise for salt fish).
- When they come: day 1 brings the tutorial only, day 2 the tower and the well (the only random petition open then); 7
  random petitions are open on day 3, 18 on day 5, 37 on day 8 and about 45 from day 11. 37 random petitions also come
  in endless (day 21 on), unless heard already.
- Endless only (15): the eclipse omen, the Feast of the Long Watch, a plague of crows, a tired veteran, Odile's
  Chronicle, a child asking about the stars, Marek's fire oil, the mill wheel, the walking fence, the tired town (45 and
  below), the scouts' warning, pilgrims, frost in the mortar, Pip's Night of Lanterns, Ser Ludo's dragon tooth. Twelve
  can come again (the five-day rule spaces them), three come once; an endless realm hears about two to three a day.

**Counsel**: Odile is usually right and always in character, but not always right: she counsels buying Marek's arrows
(Tamsin and Bram know better), sending the refugees on to the coast, flat bread over a new oven, keeping the gold
instead of the chapel's blessing, and declining Marek's spyglass, which is honest four times in five. She is warm
where it is cheap (the widow's penny, the thief's bread, the harvest feast, the tapestry) and thrifty everywhere else.

**World changes, night modifiers, unlocks**: every registered world id is used. Castle: `castle.statue`
(`castle_statue`), `castle.guards.wall` (`guards_on_wall`), `castle.banners.new` (`banners_new`), `castle.hall.tapestry`
(`tapestry_aldric`), `castle.chapel.bell.missing` (`bell_for_arrows`), `castle.chapel.candles` (`hesper_giant`,
`truce_end`), `castle.keep.window.dark` (`keep_window`), `castle.courtyard.stall` (`marek_stall`),
`castle.seren.lantern` (`stranger_gate`, `seren_at_gate`; taken down by the handover). Town: `town.well.repaired`,
`town.bridge.mended`, `town.festival.tent` (the wedding, the harvest feast, the tournament, the Long Watch feast),
`town.statue`, `town.barn.burnt`, `town.market.stall`, `town.lanterns.extra`, `town.window.dark` (a family leaves, the
cough takes old Hemmet), `town.garden`, `town.scarecrow`. Night modifiers: `crows-2`, `crows-4`, `hounds-2`, `hounds-3`,
`brutes-2`, `sootlings-5`, `sootlings-6`, `fog`, `wave-10pct`, `wave-25pct`, `wave-50pct` (the truce), `wave+15pct`,
`wave+20pct`, `wave+30pct`. Unlocks: `warTax` (`war_tax`) and `beacon` (`beacon_plans`) beside the dawns that open them
anyway, `blessing` (`hesper_bowl`, 30 gold), `-blessing` (the bell melted down).

**Decisions taken (content step)**

| Decision | Why |
|---|---|
| The war tax still unlocks at dawn 8 and the beacon site on day 11; Brannock's and Odile's petitions `unlock` them too, which changes nothing beside those dawns. | An unheard or refused story petition must never lock the chapter. The texts are written for it: "The old law now allows a war tax"; "I took the liberty of having the site cleared this morning". |
| Odile counsels sending the refugees on. | The reference bot follows her, and people who join late in the chapter made its eve of night 20 stronger than measured (rounds `lh-m3-c1` and `c2`). It is her one hard moment where she is plainly not right, and Pip's and Tamsin's lines answer it; the half measure stays a choice. |
| Refusing the herald costs a harder night 17 (`wave+15pct`, mocking him `wave+25pct`). | His threat ("refuse, and he comes himself") gets teeth, so the bargain's three quiet nights weigh against a real price; it also tempers the reference bot's eve after round `c2`. |
| No counsel choice rolls a chance, and counsel night modifiers come only on days 4 to 14. | A chance rolls the simulation's random stream and would reshuffle the nights T1, T6 and T7 measure; the late nights and the finale stay as the battle was tuned. |
| Late in the chapter the reference bot gains no townsfolk and no gold gifts: Odile pays for the thief's bread, keeps the hunting rights common and picks the harvest feast; the border family comes after the chapter. | Round `lh-m3-c1`: with them the eve of night 20 was so strong that the realm without the beacon held the finale in 9 of 10 seeds (T6 wants 3 to 6). |
| Counsel stays thrifty in days 1 to 10; feel-good petitions with a price open on day 8. | T4's high-tax realm had 2 points of margin and T1 needs the middle line's stone wall before the brutes of night 7. |
| Random petitions come once per realm unless their problem stays unsolved. | 50 random petitions for about 45 random places in a chapter: nobody asks twice. Endless has repeatable petitions of its own. |
| The herald's three quiet nights are his own night plus two follow-ups with `wave-50pct` in every choice. | A night modifier lasts one night; follow-ups reach the next ones, and night 20 stays the finale. |
| Refugee and child petitioners speak as "we" or without words that give a gender. | Their portraits and names are drawn as a woman or a man, a girl or a boy. |
| Seren's name is never spoken by the court before the reveal. | The card calls her "The Stranger" until day 15 or `seren_revealed`; the lines say "our guest". |

**Notes for the UI step**

- Who shows which portrait: court members petition with their own portraits (Brannock: `tower_request`, `war_tax`,
  `guards_on_wall`, `truce_drill`, `last_stand`; Odile: `beacon_plans`, `odile_ledger`, `banners_new`, `chronicle`;
  Hesper: `hesper_giant`, `hesper_bowl`, `keep_window`, `truce_end`, `eclipse_omen`; Pip: `pip_minister`,
  `pip_farewell`, `lantern_night`; Tamsin: `tamsin_oven`; Bram: `bad_arrows`, `bell_for_arrows`; Marek: `marek_arrows`,
  `marek_spyglass`, `marek_relic`, `marek_stall`, `marek_oil`; Seren: `stranger_gate` and `seren_watch` hooded,
  `seren_reveal` and `seren_at_gate` revealed). Guests: Ser Ludo (`ludo_arrives`, `ludo_returns`, `ludo_tourney`,
  `ludo_old`), the bard (`bard_song`, `bard_satire`), the envoy (`envoy_coast`, `envoy_tide`), the herald
  (`herald_demand`, `herald_alone`). Everyone else is townsfolk with a composed portrait and a name from the lists.
- Seren waits at the front gate for `stranger_gate` and `seren_at_gate`; the herald stands in the hall.
- The castle's world ids to draw in M3 step 3 are the nine above; the town's ten come in M4.
- The longest request is 217 characters in English and 267 in German (`ludo_old`); labels at most 35 and 40, reactions
  131 and 154, court lines 105 and 129 (the cards scroll; check the German audience screenshot).
- Each court member has a day-1 line (except Marek, who is away on day 1, and Seren).

**Tuning with the content** (the reference bot hears every petitioner with Odile's counsel when it can, else the
cheapest choice)

Measured first with an economy mirror (tools/tune.py's economy with the queue, the bot's policy and every economic
effect ported; no battle). It reproduces the runner's numbers for no petitions and for the five samples exactly (T4 25
and 28, T5 11 and 12) and finishes the beacon one day earlier than the runner. With the content: T4's high-tax realm at
dawn 8 is 27 (28 with the samples); the build order stands where the samples had it at dawn 7 in 9 of 10 seeds (the
middle line's stone wall before night 7); T5 11 buildings by day 10 on seed 1 (12 with the samples); the beacon on the
mirror's day 15 or 16; the eve of night 20 one build step short of the samples' (step 34 against 35, 20 buildings, 32
people, 12 archers). Endless counsel moves no soldiers and no nights; it spends about 350 gold over 40 nights that the
endless bot cannot use (over 4,000 in its treasury) and adds the border family's two people. The mirror cannot see the
battle: round `lh-m3-c1` showed that gifts of people and gold late in the chapter, and counsel night modifiers on the
late nights, made the eve of night 20 much stronger than measured (see the decisions).

**Runner rounds (M3 step 2)**

- `lh-m3-c1` (build, unit) on `4a3e0ce`, the content as first written: build passed; T1 to T5 and T8 passed (T3 days
  16, 16, 16; T4 27, low tax 79; T5 49 gold buy 3, 11 buildings by day 10) and the validator found no problem. Failed:
  T6 (without the beacon 9 of 10 held; the outer line had a stone wall in 8 eves), T7 (falls on nights 40, never, 38)
  and night 20's step check (seed 2 reached the hearth at 104 against 114 s, around first light).
- `lh-m3-c2` on `26a0652` (no late townsfolk or gold gifts in the bot's path, counsel night modifiers only to day 14,
  thriftier endless counsel): the same passes; T6 7 of 10 without the beacon (margins H54, H100, H100, F0, F4, H100,
  H57, F5, H100, H100), T7 50, never, 49, and seed 1's step check reached the hearth in one of its two runs only, 5 s
  before first light. Seed 1's eve equals the samples' round `lh-m3-a3` (19 buildings, 29 people, 11 archers), which
  held 4 of 10.
- `lh-m3-c3` on `a0910d2` (Odile sends the refugees on; refusing the herald costs a harder night 17): build passed, 292
  unit tests passed and 2 failed. Passed: T1 to T5 and T8 (T3 days 17, 16, 17; T4 27, low tax 83; T5 49 gold buy 3, 11
  buildings), night 20's step check, every petition, court and data test, the validator without a problem. Failed: T6
  (with the beacon 10 of 10 won and the King slain in 10 of 10, 58 to 65 s after he left, with 12 to 22 s of light left;
  without it 9 of 10 held, margins H92, H36, H100, H100, H89, H100, H100, H96, F1, H62) and T7 (falls on nights 45, 65,
  51: seed 2 five nights past 60).

**Why T6 and T7 stay out of their bands** (the lead to decide)

- The eve's economy is not the cause. In round `c3` seed 1's eve is weaker than the samples' (8 archers against 11,
  the beacon a day later), and that realm held night 20 without the beacon, where the samples' realm fell.
- The deciding draw is the Lightless King's departure, 10 s ± 8 s after nightfall, rolled from the simulation's stream
  when night 20 is planned: without the beacon the realm falls when he reaches the hearth before first light (108 s),
  which happens about 95 to 100 s after he leaves. His mean departure was 8.2 s in the samples' round (4 of 10 held)
  and 12.9, 10.4 and 10.3 s in rounds `c1` to `c3` (9, 7 and 9 held); the gatehouse fell about 82 s after he left in
  both. Whatever the reference bot hears moves the simulation's stream (soldiers' names, the night plans of modified
  nights), so every change of content redraws all ten departures, and the counsel path cannot steer them without a
  night modifier on day 20, which T6 rules out. T7 is the same kind of draw (whether an endless realm ever loses its
  gatehouse): seed 2 stood past the cap in `c1` and `c2` and fell on night 65 in `c3`.
- Proposal: count T6's "without" band and T7 over more seeds (`TuningRun.measure` takes `seedsT6`, and tools/simtune
  already runs 20), or widen the bands now that the audience moves the stream every day. Retuning the finale (the
  King's departure and its jitter, first light) is core balance, which this step did not touch.

**Open points**

- T6's "without" count and T7 are out of band (above); everything else passes. (Resolved in "M3 join": 20 seeds as
  shares, the King at 4 ± 1 s, the endless growth 0.5.)
- An endless realm hears about two to three petitioners a day: twelve repeatable endless petitions and the five-day
  rule. A few more repeatable ones would fill four.
- The war tax and the beacon site still open by themselves at dawn 8 and on day 11; the petitions' unlocks change
  nothing beside them.
- No child body yet: child petitioners walk as `citizen`.
- The endings (M5) read `seren_handed_over`; the other story flags above are free for their scenes.
- The other six languages come in M7. The longest German request (`ludo_old`, 267 characters) wants the UI step's
  audience screenshot.
- The content's generator stays outside the repo (`tools/` was not this lane's): edit the JSON files and
  Story.xcstrings directly; `PetitionDataTests` checks them.
- `tools/simtune/run.sh` still lacks `Core/Petition*.swift` (step 1's open point).

### M3 in detail: the audience on screen, the court alive, the rooms cut away (step 3, 09.11.2026)

Step 3 puts the audience, the court and the castle's rooms on screen on top of steps 1 and 2: the throne opens the
audience, a petitioner after the other walks up to a parchment card over the hall, the court walks its rounds and
talks, the great hall, the chapel and the kitchen open when the king steps in, and the castle shows what petitions
changed. The simulation is untouched: the reference bot hears petitions exactly as in step 2, so T1 to T8 measure the
same numbers.

**What was built**

- **The throne** (`KingTarget.throne`): while petitioners wait in the hall the crown (caption "Audience (n)") opens the
  audience; with nobody waiting it still opens the tax card. The **tax lectern** is its own target
  (`KingTarget.lectern`, the book; `KingTargets.lecternX` 1840, the `taxLectern` prop at 1834). A court member counts
  6 px farther than he stands (`KingTargets.talkBias`), so the lectern, the throne or a plot beside him wins a close
  call.
- **The audience** (`Core/Audience.swift`, `App/GameModel+Court.swift`, `UI/AudienceCardView.swift`): the clock stops
  (`Overlay.audience`), the king sits on the throne (his x set to 1824, facing the petitioner) and the camera settles on
  him under the card. `AudienceRules.hall` is today's queue in its order without the Stranger at the gate. The first
  petitioner walks from where he waits (townsfolk at the benches, guests where they stand, a court member from his
  round, by the hall's door when that is elsewhere) to the audience spot (1800) in 0.5 to 1.4 s; the card opens when he
  arrives (at once with Reduce Motion). Hearing a choice goes through `PetitionEngine.hear` (position in the queue), the
  HUD's numbers roll, the card shows the king's word, the reaction and what changed (gold, happiness, people, soldiers,
  builders, tonight's attack, what was opened), and "Next petitioner (n)" lets the next one walk up while the heard
  townsfolk or guest walks out by the hall's door and fades (`CourtLeaver`); a court member walks back to his round.
  "Stand up" ends the audience at any time; whoever was not heard keeps waiting until the horn. The pause sheet ends it
  too.
- **The card** stands between the HUD and the figures (`GameModel.figureTop`, from the frame's pixel scale), as wide as
  the screen allows (780 pt at most), its pointer down to the speaker (`GameModel.stageAnchor`), so the hall, the king
  and the petitioner stay in view below it. The portrait (`UI/PortraitTile.swift`: 48x48 at whole device pixels per art
  pixel, 4 on a 3x screen, on a framed dusk tile): story characters and guests their own (Seren hooded until day 15 or
  `seren_revealed`), townsfolk a portrait composed from the contract's parts with the swap ramps by the petitioner's
  look (`PortraitComposer.compose(recipe, atlas:)`, cached per recipe). The name and the role (the unnamed guests show
  their role as the name), the request; the choices as 2 or 3 tiles side by side (52 pt and more) with what they cost or
  bring (`EffectChips`: a coin, the face, people, archers, guards, builders, a moon for tonight's attack, a die where a
  chance decides part of it, "No cost"), greyed with the reason (`ChoiceBlock`: gold missing, taxpayers, archers,
  guards, the castle's last builder). The text scrolls when the screen is too short (German, Dynamic Type); the choices
  stay in view. **Counsel** (Odile's mini portrait) shows her line in a small parchment note at the top of the screen,
  where the realm strip rests during the audience, and puts her seal on the choice she favours.
- **The Stranger at the gate** (`KingTarget.stranger`, `AudiencePlace.gate`): on the days her petition waits and she
  is not let in, Seren stands in the castle's front gateway (1352); the speech bubble there opens the same card with
  her hooded portrait ("The Stranger"). Let in, she walks in through the gate and takes her corner of the hall; turned
  away, she walks back into the gorge. She waits all day, not only at dusk (see the decisions).
- **Talking** (`KingTarget.talk`, `Core/CourtTalk.swift`, `UI/TalkBubbleView.swift`): by day, within 28 px of a court
  member or guest who has a line today, the speech bubble (caption: his name) opens his next line of today
  (`CourtLineBook.line(for:state:nth:)` with `TalkLog`, not saved) in a parchment bubble over his head, following him on
  screen; he stops, turns to the king and gestures with his talk frames. A tap on the bubble closes it, so do walking
  52 px away, a card and the horn. The **speech mark** (`speakerMark`, drawn at full brightness so it reads at night,
  frame 1 pulsing every 0.6 s, still with Reduce Motion) stands over a member with a hint about one of today's
  petitions until the king has talked to him today.
- **The court drawn** (`Core/CourtFrames.swift`): every figure of `CourtLayout.figures` as an actor before the king
  (he stays in front), its glow strip over it (Hesper's flame, Seren's lantern, the herald's eyes; dimmed by day like
  the king's glass), breathing on the animation clock (so the court lives while the audience stops the simulation),
  walking its round, talking with talk frames. `CourtMotion` smooths where they stand: a member walks back to his round
  at 42 px/s after an audience or a talk, a jump farther than 240 px (Seren let in) is taken at once, and Reduce Motion
  takes every change at once. Today's petitioners wait at the benches; guests stand in the hall; Marek and his cart on
  his days. Figures inside a shut room do not show; they fade in with it.
- **The rooms cut away** (`Core/CastleRooms.swift`): `RoomFades` opens the great hall, the chapel and the kitchen
  while the king stands inside (`WorldLayout.rooms`) and shuts them when he leaves, over 0.25 s of real time (at once
  with Reduce Motion). The hall's front (`hallFront`, z 2 over the throne, hearth, candles, benches and lectern) and
  the scene's chapel and kitchen fronts fade; a front that is gone is not drawn at all, so it never clears the glow of
  the interior behind it. `chapelInterior` and `kitchenInterior` are drawn behind their fronts while open. The art
  lane's anchors (ART-court.md): the fronts' window glass masks (the chapel's four lancets at their real panes, not the
  probe's window sprites; the kitchen's eight panes; the hall's three windows, its two lanterns and the light under its
  door), the Flame in its bowl, the altar candles, stands and sconces, the sanctuary lamp, the oven-hearth's fire and
  the table candle, with their lights. A shut room's warm light is out: the hearth's glow and its light (visual only;
  the battle keeps its light) and the hall's candles show only while the hall is open, so no pool paints the outer
  wall. The light probe (`-GWScene probe`) keeps the M1b scene with the hall cut away.
- **World changes in the castle** (each drawn while its id shows): `castle.statue` (the statue at 1680),
  `castle.courtyard.stall` (Marek's cart every day, its lantern lit at dusk), `castle.guards.wall` (two guards on the
  wall walk by day, 1324 and 1396), `castle.banners.new` (five renewed banners over the hall's own), `castle.hall.tapestry`
  (Aldric on the back wall, 1764), `castle.seren.lantern` (her grey lantern on the hall's far wall with a cold light),
  `castle.chapel.candles` (votive candles before the altar step, lit), `castle.chapel.bell.missing` (the belfry's
  louvres where the bell hung, the rope left hanging), `castle.keep.window.dark` (one keep window unlit on the castle
  front's keep, the far keep and the keep above the valley). The five without a contract sprite are procedural
  (`hallBanner`, `tapestry`, `serenLantern`, `votiveCandles`, `bellGone`, `Render/PlaceholderCastle.swift`).
- **The realm strip** marks the petitioners waiting for the throne (a parchment bubble with their number over the
  hall, above the bar) and the Stranger at the gate (her grey lantern); its VoiceOver value names the count. It rests
  during the audience.
- **The dawn report** names who went home unheard at the last horn ("Sent home unheard": "Agnes (Farmer's wife),
  Brannock"), from the court's history and the same looks (`UnheardPetitioners`), beside the happiness reason.
- **Placeholders** (`Render/PlaceholderCourt.swift`): the rooms' stand-ins now sit inside their rooms' outlines
  (measured from `hallInterior`, `chapel` and `kitchen`) with their windows, altar, oven and candles at the art lane's
  anchors, so the screenshots before the art lane's merge show the glow where the art will have it.
- **Debug arguments**: `-GWScreen petition` and `-GWClock` (see the table). **Hooks in existing files**: `GameModel`
  (the court's state, `withDriver`, the throne, lectern, talk and gate actions, the camera settling under a card, the
  court's frame and clock), `KingTargets`, `RealmStrip`, `CourtLayout` (Hesper's and Tamsin's stops), `FrameDesc` (the
  five procedural ids), `PlaceholderArt`, `GameStart`, `DebugArgs`, `HUDView`, `OverlayView`, `GameView`,
  `RealmStripView`, `ReportCardView`.

**Decisions taken (M3 step 3)**

| Decision | Why |
|---|---|
| The audience card stands above the figures, between the HUD and their heads, with a pointer down to the speaker; not in the lower half. | In the lower half it hid the petitioner, the king and the benches, the story moment itself. Above them the hall stays in view and the HUD's numbers roll in their place after a choice. |
| Odile's counsel is a small note at the top of the screen, where the strip rests during the audience. | Under the request it pushed the choices out of the card on a 17 Pro (round `lh-m3-b1`: the line was scrolled away). The top is empty during the audience: no travel is possible then. |
| The throne without petitioners still opens the tax card; the lectern is its own target beside it. | The crown never does nothing, M2b's players find the taxes where they were, and the lectern serves while petitioners wait. |
| A court member yields a close call to a place beside him (6 px). | Odile steps to the lectern now and then: without the bias the lectern's book and her bubble swapped under the king's feet. |
| The Stranger waits at the gate all day (days 4 and 5), with the same card. | A dusk-only window would last 3 in-game hours (36 s) and is easy to miss; she stands in the gateway, the strip shows her lantern, and the horn still sends her away. |
| Talking does not stop the clock and is a bubble, not a card; by day only. | A line is a moment in passing; at night the court keeps the hearth and the king the walls (and the night's action button stays light and patch). |
| The speech mark shows a hint about today's petitions until the king heard the member today. | "Something new to say" that a player can act on; gossip without a hint does not nag. |
| The audience's walk, the rooms' fades, the leavers and the court's breathing run on real time while the simulation stops. | The audience pauses the clock, but the hall must not freeze into a still picture. |
| A court member who petitions comes in by the hall's door when his round is elsewhere. | Brannock's round is in the courtyard: crossing it in a second would be a sprint; the door is off screen from the throne. |
| Figures inside a shut room are not drawn, and the room's warm light is out. | The art lane's note: a wall hides them; a hearth pool on the outer wall read as a fire outside. |
| The five castle world changes without a contract sprite are procedural sprites. | SPRITES.md "M3" has no sprite for them and the art lane did not paint them; the lead can hand them over (their ids, sizes and places are above). |

**Tests (M3 step 3)**

- New unit tests (24, all passing): `AudienceTests` (the throne hears the hall and the Stranger waits at the gate, the
  walk up and the card on arrival, the card's choices with their costs and reasons, hearing through the session and
  who went home unheard, the leavers), `AudienceFlowTests` (the crown, a choice heard, standing up with the rest
  waiting, the lectern's taxes, the pause, Reduce Motion, the Stranger at the gate, talking, `-GWScreen petition`),
  `CastleRoomsTests` (a front fades in a quarter second and swaps at once with Reduce Motion, the shut hall hides its
  court and the open hall shows it, the chapel and the kitchen open with their interiors lit, the court walks, talks
  and carries its marks, the castle's world changes, a crowded castle frame within the budget), `PortraitCardTests`
  and `TalkTests`. `ScreenFlowTests` and `FirstDayUITests` follow the throne's new split (the crown opens the
  audience while petitioners wait; the taxes at the lectern).
- UI test 4 `testAudience` (`UITests/AudienceUITests.swift`, English and German): the court in the courtyard (58), the
  hall's front from the courtyard (60), the hall with the court and three petitioners (51), the kitchen opened (57),
  a line from Tamsin (55), the chapel opened (56), the audience: Brannock's card (52), Odile's counsel (53), the
  reaction (54), the next petitioner, a townswoman with her composed portrait (52b), standing up; the herald's sample
  (59); night 3 in the hall and the chapel (51b, 56b, for the look); Reduce Motion (the card within 1.5 s). Every
  button it taps is checked for 44 pt.

**Runner rounds (M3 step 3)**

- `lh-m3-b1` (build, unit, ui with `AudienceUITests` and `FirstDayUITests`, ui-de with `AudienceUITests`, release) on
  `b7b3424`, the first draft: build passed on the first try; ui, ui-de and release passed. Unit failed the walk-up
  test (`CourtFrames.key` gave a court member the petition's key and a townsfolk petitioner his own, so the walker
  was drawn twice: `"p:tower"` against `"brannock"`) and T6 and T7 as in round `lh-m3-c3`. Its screenshots showed
  Odile's line scrolled out of the card, the strip's petitioner bubble under the king's mark, the king covering a
  bench and the herald's sample dim at 06:00.
- `lh-m3-b2` (build, unit, ui and ui-de with both tests) on `b9b3366` (the walker's key, the counsel note at the top,
  the strip's bubble above the bar, seed 2 and the lectern for 51, the herald at 17:48, the placeholders at the art
  lane's anchors): build, ui and ui-de passed; unit failed only T6 and T7, the same numbers.
- `lh-m3-b3` (build, unit, ui, ui-de, release, every UI test) on `381da66`: build passed without a compiler warning;
  316 unit tests passed and 2 failed, T6 and T7 exactly as in round `c3` (T6 with the beacon 10 of 10 won and the
  King slain in 10 of 10 after 58 to 65 s; without it 9 of 10 held, margins H92, H36, H100, H100, H89, H100, H100,
  H96, F1, H62; T7 falls on nights 45, 65, 51); every step-3 test passed; ui 9 of 9 and ui-de 9 of 9 passed
  (`testAudience` 140 s); release passed. German fits on every card, bubble and caption of the shots 51 to 60.

**Open points and notes for the lead**

- T6 and T7 still fail exactly as in round `lh-m3-c3` (the content step's open point, unchanged by this step: the
  same numbers in rounds `lh-m3-b1` to `b3`). They wait for the lead's decision on the bands or the seeds. (Decided
  and resolved in "M3 join".)
- The art lane's room PNGs (`hallFront`, `chapelInterior`, `kitchenInterior`, the touched-up `chapel` and `kitchen`)
  are on `claude/lh-m3-art`; the anchors here are theirs. The bell overlay (`bellGone`) is painted in the colours of
  their `chapelInterior` behind the bell; if they repaint the belfry it must follow.
- The seated king (the art lane's `kingSeated` proposal) and sit frames for the benches are not in the contract: the
  king stands at the throne during the audience and the petitioners stand at the benches.
- The cart's lantern mask, the hall's glass masks and the room fires use the art lane's anchors; on this branch's
  placeholders they now match too.
- Reduce Motion: no walks, no fades (the fronts swap), no card transitions; the speech mark holds still.

### M3 join (09.11.2026): the art, the M2b review's fixes and the finale's draw

The join brought M3's three lanes and the planning branch together on `claude/lh-m3`: M3's code (steps 1 to 3), M3's art
(`claude/lh-m3-art` after its review and fix stage) and `claude/game2-planning-354541` (the M2b review's fix stage with
M2a's battle restored, round `lh-rev-f4`, and Louis' decisions of 09.11. evening).

**The merge**

- `claude/lh-m3-art` merged cleanly (tools, Resources/Art, ART-court.md). Hesper's moved flame needs nothing in the
  code: the glow strip draws over the body, and no light sits at her flame.
- `claude/game2-planning-354541` conflicted in five files, resolved so both sides stay:
  - `GameModel`: M3's court state beside the review's save store, holds, build verbs, the horn by day and the cached
    filtered scene. The cache now also keys on the rooms' fades and the dark keep window
    (`CastleRooms.SceneKey`), so `CastleRooms.scene` runs only when a room fades or the keep window changes, not 60
    times a second.
  - `FrameDesc`: M3's sprites beside the review's 18x6 streak.
  - `HUDView`: M3's throne, talk and Stranger labels in the review's `(target, hold)` form.
  - `Localizable.xcstrings`: merged key by key (33 M3 keys, 13 review keys, 2 review renames, no key changed on both
    sides).
  - DESIGN.md: both sides' sections in order (the M2b review before M3's three steps).
- Clashes in meaning, fixed in the merge:
  - `KingTargets.hold` (new on the review side) covers M3's lectern, talk and Stranger targets.
  - The review hides the HUD under every card and screen, drops the pause button under the screens and draws the
    world at 20 fps under them, all keyed on "not a card". M3's audience is neither: its card stands below the HUD,
    whose numbers roll there after a choice, the pause sheet ends the audience, and the hall lives on under the card.
    `Overlay.isScreen` (the dawn report, the defeat card, the pause sheet) now decides the pause button and the 20
    fps; the HUD's clock and numbers stay during the audience (the strip still rests for Odile's counsel).
  - The review made the gorge keep's glass smaller (its right pane at dx 65); the dark keep window
    (`castle.keep.window.dark`) now darkens it there too.
  - `AudienceFlowTests` use a temporary save store, as the review's `GameScreensTests` do.
  - "Sound the horn" by day plays the day on headless to 18:59; petitioners still waiting go home unheard at the horn
    as on any day.
- `tools/simtune/run.sh` compiles M3's core: the petitions the reference bot hears (`Core/Petition*.swift`) and, since
  the review's line-1 torches read `WorldLayout`, `WorldLayout`, `Camera` and `PixelScale`. Started in the game's
  folder, it reads `Resources/Petitions`. `run.sh finale` sweeps the Lightless King's departure, its jitter and his
  walk in the dark on night 20 over seeds 1 to 20 (`SimTune.finale`).

**T6 and T7 over 20 seeds** (the lead's decision on step 2's open point)

Both targets now count 20 seeds and state their bands as shares (`TuningMetrics.targetSeeds`; "Tuning targets" 6 and
7): T6 with the beacon won in at least 80 % and the King slain in at least 60 %, without it 30 to 60 % held; T7 at
least 80 % of 20 endless seeds falling between nights 35 and 60. Measured on the merged code (round `lh-m3-j1`, the
same numbers as `lh-m3-b3` on seeds 1 to 10):

- T6 with the beacon: won 20 of 20, the King slain 20 of 20, 58 to 65 s after he left, with 12 to 22 s of light left.
- T6 without: **18 of 20 held (90 %)**; only seeds 9 (F1) and 15 (F7) fell. The draw decided it: with the King leaving
  at the earliest second of 10 ± 8 (2 s) 6 of 20 held, at the latest (18 s) all 20, and 14 of 20 seeds flipped
  between the two. The finale was too easy without the beacon, and the beacon has to matter.
- T7: falls on nights 45, 65, 51, 0, 0, 39, 46, 0, 49, 61, 66, 47, 46, 62, 50, 51, 49, 44, 47, 46: **13 of 20 in the
  band**, three realms still standing at the cap and four falling at 61 to 66, the median fall 49.

The sweep (`tools/simtune/run.sh finale`, rounds `lh-m3-j1` and `j2`; nights 1 to 19 do not depend on the King, so
each seed's eve is played once and every variant plays night 20 from it): held without the beacon, of 20 (with the
beacon every variant won 20 of 20 and slew the King in all 20, 56 to 65 s after he left).

| Departure | ± 0 | ± 1 | ± 2 |
|---|---|---|---|
| 10 s | 14 | 15 | 18 (± 3: 17, ± 4: 18, ± 8: 18) |
| 8 s | | 13 | 14 |
| 7 s | 13 | 12 | 13 |
| 6 s | 10 | 10 | 10 |
| 5 s | 8 | 8 | 10 |
| 4 s | 12 | **10** | 9 |
| 3 s | 6 | 8 | 9 |

His walk in the dark at 10 s: 25 px/s held 13 (± 1) and 11 (± 2), 26 px/s 5 and 5, 27 px/s 0 and 2, 28 px/s 0. Night
20's step check (seeds 1 to 3) passed at 10 ± 8, 7 ± 1, 4 ± 1, 3 ± 0 and 3 ± 2; it failed at 6 s and 5 s with every
jitter (seed 1 without the beacon: the hearth reached 4 s apart between the step sizes, 108.8 against 104.7 s, the
courtyard phase after the gatehouse falls, as in M2a's sweep), at 4 ± 0, 4 ± 2 and 3 ± 1, and at 25 px/s.

**Decision: the King leaves at 4 ± 1 s (20:20 ± 0:05; `Balance.kingSecond` 4, `kingJitter` 1).**

- The jitter narrowed from ± 8 to ± 1 s and the departure 6 s earlier: without the beacon **10 of 20 hold (50 %)**,
  the middle of the band; with it 20 of 20 won and the King slain in all 20, 59 to 64 s after he left, with 11 to 22 s
  of light left; the step check passes. Margins without the beacon: H98, H1, H100, F1, F5, F0, H100, F2, F5, F1, H100,
  H100, H97, H26, F3, F9, F3, F14, H100, H100.
- The outcome now hangs on the realm, not the draw: over the whole ± 1 window 6 (leaving at 3 s) to 8 (at 5 s) of 20
  hold, against 6 to 20 over 10 ± 8. The seeds that still flip inside the window are the realms that fall or hold
  within a few seconds of first light (F0 to F5, H1), where any change of the night moves them.
- Why not less: 7 ± 1 s, the smallest shift into the band, lands on its upper edge (12 of 20 = 60 %) only through its
  draws (± 0 and ± 2 hold 13, out of the band), so any content change would push it out; 6 s and 5 s lie inside the
  band with every jitter but fail the step check. 4 ± 1 s is the smallest shift inside the band with every jitter that
  passes the step check.
- Not his walk: one pixel per second moves the share by 6 to 8 seeds (25 px/s 11 or 13, 26 px/s 5), and 25 px/s
  fails the step check. Not first light: it times every night, so T1 to T8 would all move.

**T7: tuned, not widened.** At 4 ± 1 s and the old endless growth (0.4) T7 falls on 46, 65, 43, 47, 0, 34, 58, 51, 49,
61, 59, 57, 34, 46, 50, 49, 47, 47, 51, 50: 15 of 20 in the band (75 %). Over all 14 finale variants of round `j2`
(each reshuffles the realms at dawn 21) T7 kept 12 to 15 of 20 in the band, every variant with one to three realms
still standing at the cap, most with falls at 61 to 66, the median fall 49 to 51: a tail of realms that never lose
their gatehouse, which is systematic, not noise. The endless growth over the same 14 variants:

| `endlessQuadratic` | In the band, of 20 | Variants failing T7 | Standing at the cap | Median fall |
|---|---|---|---|---|
| 0.4 | 12 to 15 (mean 13.6) | 14 of 14 | 1 to 3 (mean 2.1) | 49 to 51 |
| 0.45 | 15 to 18 (16.4) | 3 | 2 to 4 (2.7) | 45 to 47 |
| **0.5** | 16 to 19 (17.7) | 0 | 0 to 3 (1.4) | 45 to 48 |
| 0.55 | 17 to 20 (18.6) | 0 | 0 to 3 (1.4) | 44 to 47 |

**Decision: `endlessQuadratic` 0.4 → 0.5**, the smallest growth that keeps T7 in its band for every finale variant
measured (the story pass after the merge will reshuffle the realms at dawn 21 again). With 4 ± 1 s: falls on 46, 46,
48, 43, 55, 37, 52, 50, 39, 53, 53, 49, 38, 49, 38, 0, 63, 44, 45, 0: **17 of 20 in the band (85 %)**, the median fall
48. It changes only the nights after 20, so T1 to T6 and T8 do not move.

**Runner rounds (M3 join)**

- `lh-m3-j1` (build, unit, ui, ui-de, release, `sh bash tools/simtune/run.sh finale`) on `8467449`, the merged branch
  with T6 and T7 over 20 seeds: build passed without a compiler warning from the game's code; unit failed only T6
  (without the beacon 18 of 20 held) and T7 (13 of 20 in the band), every other test passed (the step check, T1 to T5
  and T8 as in `lh-m3-b3`); ui, ui-de and release passed; simtune compiled the core in 78 s and swept 31 variants in
  65 s. The audience's shots show the HUD's clock and numbers above the card and the art lane's court and portraits.
- `lh-m3-j2` (`sh bash tools/simtune/run.sh finale`) on `3a44971`: the departures 7 to 3 s with ± 1, ± 0 and ± 2 and T7
  with each endless growth (the tables above), 560 s.
- `lh-m3-j3` (build, unit, ui, ui-de, release) on `98ac27e` with 4 ± 1 s and 0.5: **ALL PASSED**. 323 unit tests,
  exactly the sweep's numbers: T6 with the beacon 20 of 20 won and the King slain in 20, 59 to 64 s after he left,
  with 11 to 22 s of light left; without it 10 of 20 held, the falls at 03:52 to 05:00; T7 17 of 20 in the band; T1
  to T5 and T8 unchanged; night 20's step check passed. `TuningTests` takes 294 s with 20 seeds and 20 endless seeds
  (90 s before), the unit step 8 minutes. ui 9 of 9 and ui-de 9 of 9 passed; release passed. In `34-finale-2230`
  arrows now fly at the King (3 in flight, 2 archers drawing), since he leaves 30 minutes earlier.

**Open points (M3 join)**

- Reported, not a target: a bot that never builds the beacon and spends that gold on the rest of its order still holds
  night 20 in 10 of 10 (the first ten seeds). The beacon decides the ending and, against the same realm without its
  last stage, survival in half the seeds; a realm built for defence instead holds ("The finale").
- The story pass after the merge (king to lord, the families in the audiences) rewrites the content, and every content
  change redraws night 20 and the realms at dawn 21: run `tools/simtune/run.sh finale` again. T6 sits in the middle
  of its band (10 of 20), T7 at 17 of 20.
- Night 20's step check stays fragile near first light: at 6 s and 5 s it failed on seed 1 (the courtyard after the
  gatehouse falls, 4 s apart between the step sizes), as 19 of M2a's 58 variants did.
- Two endless realms of 20 still stand at night 70 (the gatehouse never falls); more growth (0.55) or brutes in the
  endless mix would take them, at the cost of moving the median fall earlier.
- "Sound the horn" by day sends the petitioners still waiting home unheard at the horn (one happiness each at dawn).
  Resolved in the M3 fix stage: its confirmation says so.

### M3 fix stage (10.11.2026): after the review of the join

The review of the join (a code lens and a player lens, then a refuter) left two confirmed findings and a list of
optional ones. This stage fixes the two and the cheap, clearly right part of the list. One rule held throughout: the
reference bot's path stays bit for bit what round `lh-m3-j3` measured, so no petition's id, kind, day, weight,
condition or counsel changed and no choice the bot takes changed what it does to the simulation.

**U1: a story decision leaves something you can see** (`Core/Remembered.swift`)

- Every story choice now shows what it leaves behind. A choice that only sets a flag used to read "No cost" and then
  nothing ever happened on screen. Its tile now says "Will be remembered" (or what it gives, "Next brazier free"),
  and the reaction card's change row names the trace in one line (`remember.<flag>` in `Story.xcstrings`, 16 flags,
  at most 56 characters in German).
- The court answers. `Resources/Court/lines.json` marks a line as an answer (`"answer": true`: it needs `requires`
  and `days`); answers come after Odile's hints and before the everyday lines, and they raise the speech mark, so
  the day after a decision someone in the hall has a word on it. 10 new answer lines, 3 existing ones marked.
- One decision has a real effect: "light first" on day 2 (`tower_request` c2) sets `brazier_gift`, and the next
  brazier ordered costs nothing (`Build.options` shows price 0, `Build.order` takes the flag). The bot never takes
  that choice, so the tuning is untouched.
- The finale's dawn report quotes the speech the player chose on night 20's eve (`ReportCard.make(_:flags:)`).
- Deferred to the story pass's retune, because they change what the bot's own choices do: a discount for the
  promised tower, an effect for `hesper_giant` c1 and the last stand's bonuses.

**U2: the audience is where the player looks for it** (`KingTargets`, `CourtLayout`)

- While petitioners wait in the hall the throne owns the whole dais (x 1792 to 1870): the button says "Audience (n)"
  anywhere between the benches and the hearth, whoever stands there. The tax lectern moved beyond the hearth (left
  edge 1908), Odile stands a step off the throne and walks to the lectern's near side (1848 and 1894), Pip keeps the
  hearth at night.
- A gold mark hangs over the throne while the hall's queue is not empty (a lit frame under Reduce Motion).

**The smaller fixes**

- C1: the bot hears from the catalogue its driver was given, the tuning report counts the petitioners the bot heard
  and fails on 0 ("Court"), and simtune stops before any run when the petitions did not load. A tuning run with an
  empty court can no longer pass for a real one.
- C2: the horn's confirmation names who still waits ("3 petitioners still wait. They go home unheard.").
- C3: the pause leaves the audience the way the Leave button does (`GameModel.leaveAudience`), so a petitioner
  already heard walks out instead of vanishing.
- C4: replaying the day and the second chance start the court afresh (`restartView`: the bubble, the talk log, the
  leavers, the audience).
- C5: the validator reports required flags that no choice sets, and German lengths per kind of text.
- C6: the far keeps' dark pane has a name in `SceneLayout`; the test checks both far keeps lose exactly that pane.
- C7, C8: the second court line's precondition is asserted; an audience opened at 18:54 holds the clock and the horn
  then counts the unheard.
- U3, U5: the audience's button says "Leave"; the night chips are spelled out ("Tonight −50%").
- U9: German choices where the lord pays or buys are infinitives ("Das Fernrohr kaufen"), 11 labels; the well's
  second reaction reads as German; "Eure" is capitalised.
- M2b's open point: the finale's shots are taken from 23:00 to 23:30 and 00:00 to 00:30 (`34-finale-2300`,
  `35-finale-0000`).

**Left open, and why**

- U4, about 14 choices that are strictly worse than their neighbour: each needs a new reaction text and a judgement
  of the story; changing the counsel's side moves the bot. For the story pass.
- U10, king to lord in the texts: the story pass.
- U3, U6, U7 (the lord never sits; a townsfolk portrait that does not match its figure; the chapel's cut-away): art.
- U8, the speech mark's size: it is 7x7 real art and already glows; a bigger one is a new sprite.
- C8's wider seeds for `testTheHeadlessStepKeepsNightTwentysOutcome`: the step check is known to be fragile near
  first light (above); more seeds would fail on that, not on a fault. C8's play-on-from-a-save test with the bot:
  not cheap (a second 20-night run in the unit step).
- The gold blow-out beside the Lightless King's lantern and the archers' volleys in step: both need the renderer's
  light sum or the battle's timing changed against pictures and the tuning; not cheap.
- Random and endless choices that only set a flag still read "No cost"; U1 covered the story's.

**Rounds**

- `lh-m3-f1` on 62ac439 (U1, U2, C5, C7, U3, U5): ALL PASSED. Its finale report showed the speech quote as a row of
  its own pushing the realm's People row out of the card.
- `lh-m3-f2` on cfe83a9 (all fixes): ALL PASSED. 336 unit tests; T1 to T8 line for line what `lh-m3-j3` measured (T6
  with the beacon 20 of 20 won and slain, without it 10 of 20 held; T7 17 of 20); Court: the bot heard 1068
  petitioners; the validator reports nothing; both finale shots show the Lightless King in the archers' reach with
  arrows in the air (23:12 and 00:31).
- `lh-m3-f3` on dcf0e13 (the quote beside the report's title): ALL PASSED (build, unit 336, ui, ui-de, release), the
  tuning report identical to f2's. The People row is back in English and German; the German quote takes two lines.

### Look 2 port (10.11.2026): look 2 and the weather in the game

The look-2 lane painted a new world and a mock of it (ART-look2.md, `tools/scenemock/layout_look2.py`); the plan lane
wrote how to bring it into the game (docs/PORT-look2.md). This stage does that. One rule held throughout: the
simulation is tuned, so the port is drawing only. No number of the battle, the economy or the court changed; T1 to T8
read line for line what `lh-m3-f2` measured in every round below.

**What is in the game**

- The contract: ART-look2.md's world ids, `darknessBankGlow` and the castle's tier ids are in `SpriteID`, SPRITES.md
  and the atlas, drawn from their PNGs (`AtlasTests.testLook2ArtIsBundled`). The lord's new ids (`lady`, `ladyGlow`,
  `kingSeated`, `ladySeated`, `portraitLady`, the seated citizens) belong to another lane and are not registered here.
- The switch: `-GWLook 1|2` (`LookVersion`, `FrameOptions.look`). Look 1 is pinned by golden hashes
  (`LookGoldenTests`: FNV-1a 64 over six look-1 scenes, recorded in round `lh-l2-0d` before the port touched the
  renderer and equal in every round since).
- Step 3: look 2 is the game's default (`LookVersion.standard = .two`, commit 8b06671). Look 1 stays behind
  `-GWLook 1` for what pins it: the golden hashes, the probe and light lab shots and the film strip
  (`LightProbeUITests`) and the test pattern (`ProbeUITests`). Every other UI test now plays in look 2 with the
  weather of its seed and day.
- Look 2's light: its own ramp (`Core/AmbientRampLook2.swift`: the long dusk, the navy night, air, vignette, the navy
  lift, the cloud light), value compression, the night tint, haze by plane, fire and window pools that push the cold
  out, ledges that catch the sky, the cut-away rooms' warm fill.
- Look 2's planes: sky, clouds, far, mid, the mist band, near, fog A, world, fog B, foreground (ten; look 1 keeps its
  eight). The scene of `layout_look2.py`: the Weltmauer with the far castle's glow, the shadow land's firs and dead
  trees, the Throat (gorge rock, crags, the warden statue with its bowl fire, the cleft's flanks), the lane by region
  (moor, scree, cobbles, earth), the valley's trees and vista, the foreground strips, chimney smoke.
- The creatures: look 2's frames and strides; the gloomweaver's violet lantern and the Ash Giant's ember heart as
  render lights (never the battle's), the heart flaring on the stomp frame; soot and hit dust inside the particle
  budget, none with Reduce Motion; the Lightless King's aura; a cold light keeps its colour to the rim.
- The darkness bank: the painted bank and edge, its glow over the body tiles.
- Fireflies in the valley (PORT 2.6): four patches of `d2Fireflies` as glow, each twice (the second mirrored), the
  two blinking against each other and drifting in whole pixels; from 18:30 to 21:00 with half an hour's fade each
  way, none in rain, none in a steady wind above 0.6, none in look 1. With Reduce Motion they stand and breathe.
  They are no lights (the 64 are for fires).
- The castle's tiers as drawn (`CastleStage`, `-GWCastle 1|1b|2|2b|3|3b`): the keep's top, the back rise, the far
  castle's overlays and the slot's glow at tiers 2 and 3, the drum-tower front at tier 3, the scaffold states. No
  play raised a tier in the port; since the polish after round 2 the gatehouse does (see there).
- The weather (below).

**Decisions**

1. Look 2 has its own shader functions (`lh2_*`) and its own uniforms (`Look2Uniforms`, stride 288, fragment buffer
   2) beside look 1's. PORT-look2.md wanted one `LookValues` struct for both; two code paths keep look 1 bit for bit
   and make its removal a deletion.
2. `FrameDesc.look`, `rooms`, `rain` and `wetness` are defaulted vars that only `FrameBuilder` sets, so every frame
   built without them is the frame it was. `FrameOptions.look` defaults to `.one` (the unit tests' frames keep the
   picture they were written for); the app's default is `LookVersion.standard`, look 2 since step 3.
3. Rooms: at most two rectangles per frame (the hall, the chapel or kitchen beside it).
4. The sky is two stops, the backdrop's lights keep the engine's rule; the fog region is per column.
5. PORT's rounds L2-0 to L2-8 were bundled into fewer runner rounds (a round costs 16 to 50 minutes).
6. The creatures' lights are frame lights built in `EntityFrames` for the picture; `LightField` and the battle never
   see them.
7. The castle's tier is an argument, not state: `GameState` has no tier, and the save stays as it is. (Since the
   polish after round 2 the tier is read from the gatehouse's plot; still no new state.)
8. Departures from the mock: the bank is opaque in the game (the mock's is translucent), so the shadow land by night
   is the bank west of its edge and the shadow-land shot stands at x 570, where the creatures have left it.
9. The scene's accessibility value carries `lit:` beside `seen:` (creature bodies in the frame that the battle's
   light field lights). Inside the bank a creature is a rim and two eyes, so a shot of "the new creatures" has to
   wait for them in the firelight: `Look2UITests.testLookTwoNight` takes the moment between 21:00 and 01:00 with the
   most of them (lit × 3, shots × 2, seen, aiming archers). The value is read only by UI tests.

**The weather** (`Core/Weather.swift`, `Tests/WeatherTests.swift`)

- A pure function of the run's seed, the day, the hour and the animation time. Only `FrameBuilder` reads it, and only
  in look 2 (`FrameOptions.weather`, `WeatherSample.clear` by default: clear air and look 1 are the frames they
  were). `GameModel` samples it for the frame with `GameState.seed`, `day` and `hour`; nothing of `Core/Sim*`, the
  battle or the court takes it.
- A day runs from its dawn at 06:00 to the next. Its wind class is drawn from the seed and the day: calm 30 %, breeze
  40 %, gusty 24 %, storm 6 % (base 0.08, 0.35, 0.55, 0.85; gusts 0.04, 0.12, 0.35, 0.15). Days 1 and 2 are a dry
  breeze, no storm comes before day 4 and never two in a row. The wind blows toward the valley on 70 % of the days.
  Two days' winds blend over the day's first game hour.
- Gusts are value noise over time (4 s per lattice point) that travels with the wind (500 px per second's lead); a
  gusty day shapes them into calm spells and sudden gusts.
- Rain: every storm brings it, a quarter of the other days after day 2 do. It starts at a drawn hour, lasts 3 to 9
  game hours (a storm 6 to 12) at strength 0.4 to 0.8 (a storm 1) and fades in and out over 20 s of play. The cloud
  gathers a game hour before and clears a game hour after. Stone and lane are wet after half a game hour of rain and
  dry over two; the ruts fill over one and drain over six (`puddles`, for the puddle sprites to come).
- The light under it (`Weather.apply`): ambient × (1 − 0.22 r), saturation × (1 − 0.12 r), warmth × (1 − 0.6 c),
  vignette + 0.04 r, fog + 0.15 r, haze + 0.18 r, the sky toward grey, no stars under full cloud; the moon's and the
  sun's disc × (1 − 0.8 c), sun shadows × (1 − c). The torch strength stays: fires burn as they do.
- Rain is instances, no pass: `rainStreak` on the near plane (110 at full rain, 150 px/s, alpha 0.30), the world
  plane (70, 220 px/s, 0.40; under the bank's tiles, so the dark hides it) and the foreground (28, 320 px/s, 0.45),
  slanted by the steady wind (straight under 0.2, then two steeper frames, mirrored for a wind from the valley), and
  up to 24 `rainSplash` on the lane. The counts go by the root of the rain's strength (`FrameBuilder.rainCount`: a
  rain of 0.5 has 0.7 of the streaks; in round `lh-l2-3a` a count in proportion left a rain of 0.6 a few stray
  lines on a phone). Each is a pure function of its index and the time; the columns belong to the
  plane's picture, so the rain stays in the world when the camera moves. PORT's speeds are kept in proportion but
  lower (it asked 260 to 520 px/s; at a 201 px target those read as noise).
- Wet ground is the composite's work (`Look2Uniforms.weather` = rain, wetness): the lane's sky light up by a quarter
  of the wetness, ledges 2.5 times as bright when soaked, the lane's top three rows throwing firelight back column
  by column. All of it is × 1 or + 0 at wetness 0.
- Fire: open flames (torch, brazier, fire tower, fire arrow, firepot, beacon) burn 12 % lower at full rain and
  flicker 1.6 times as wide; lanterns, hearths, windows and candles are sheltered. A wisp of steam (the smoke's lower
  rows, pale) stands over the large fires. This is the frame's light only; the battle's light is untouched.
- Wind you can see: the trees and the foreground's plants are drawn as six bands of their rows, the crown shifted by
  whole pixels (a swing of 1 px in a breeze, a lean of 1 and a swing of 2 in a storm, each tree at its own phase),
  the trunk standing (`SpriteInstance.source`, `FrameBuilder.sheared`); chimney smoke leans up to 12 px in ten
  bands; the fog and the mist band travel with the wind (half speed in a calm, about 2.5 times in a storm, toward the
  shadow land when the wind turns). The glow's occluder stays the whole sprite.
- Reduce Motion: no streaks, no splashes, no sway, no gusts, the fog stands; the darker air, the wet sheen and the
  steam stay.
- Arguments: `-GWWeather auto|clear|breeze|gusty|storm`, `-GWWind`, `-GWRain`, `-GWWetness` (table above). The
  probe has no run and shows weather only when asked. Look 2's parity shots pin `-GWWeather clear`.
- Budget: the weather adds no pass and no texture read.

**What is left of PORT-look2.md**

- Art the weather waits for: `castleFlag` (banners in the wind), `lanePuddleA` to `C`, painted `rainStreak` and
  `rainSplash`, second frames of the foreground strips. Sound hooks for rain and wind (no music, ever). The weather
  view of `-GWShowBuffer`.
- The effects of section 2 not built: light shafts (2.1), bloom outside the emitter (2.2), the fog's second copy
  (2.4), `d2Sparks` over the fires (2.5; the embers of look 1 still rise), the creatures' fade out of the bank (2.9),
  foot puffs, the particles' wind drift.
- The upgrade logic for the castle's tiers; L2-9's cleanup (deleting look 1 and the switch, the reads view, the
  thermal ladder, a device check on an A12).

**Rounds** (each on the runner; `build unit ui ui-de`, the UI steps filtered to `Look2UITests` where named)

- `lh-l2-0a` on c353fd8 (the contract): ALL PASSED, 337 unit tests.
- `lh-l2-0b` on 5c99cbf and `lh-l2-0c` on aad5a91 (the switch, look 2's ramp): FAILED at the build (a missing
  parameter of `AmbientRamp.sample`, then missing fields of `AmbientSample`); fixed in aad5a91 and 17380b8.
- `lh-l2-0d` on 17380b8: ALL PASSED; look 1's six golden hashes recorded from it (631cda1).
- `lh-l2-1a` on 631cda1 (renderer, scene and frame of look 2): FAILED one unit assertion (look 1's far keep counted
  wrongly by the new scene test); fixed in 2a79e68.
- `lh-l2-1b` on 2a79e68: ALL PASSED, 343 unit tests, `Look2UITests` in English and German.
- `lh-l2-2a` on 2382254 (the creatures, the bank's glow, the castle's tiers): ALL PASSED, 346 unit tests; the most
  a look-2 frame took was 98 instances and 16 lights (budget 1,500 and 64).
- `lh-l2-3a` on de525ee (the weather): ALL PASSED, 358 unit tests, `Look2UITests` in English and German; T1 to T8
  line for line as before, the bot heard 1068 petitioners; a storm's frame takes at most 326 instances; over the
  seeds measured the days are calm 0.30, breeze 0.40, gusty 0.25, storm 0.055, rain on 0.29 of them, the wind
  toward the valley on 0.70.
- `lh-l2-4a` on 8b06671 (step 3, the fireflies, the rain's count, `lit:`): FAILED at the build (`sin` without
  Foundation in `FrameBuilder`); fixed in 1efc58b.
- `lh-l2-4b` on 1efc58b, the parity round with look 2 as the default: ALL PASSED (build, unit 359, every UI test in
  English and German, release). The tuning report is identical to `lh-l2-3a`'s (T1 to T8, night 20's steps), the bot
  heard 1068 petitioners, look 1's hashes hold. The live night shot (`78-look2-night-live`) was taken at 23:55 with 8
  creatures in the frame, 4 (German run: 5) of them in the firelight, 4 shots in the air.
  Seen in its pictures and left open: rain over the bright dusk valley is faint (`87-look2-rain-town-dusk`; the
  code-painted streaks are as pale as the haze behind them, the painted `rainStreak` should carry a darker tail);
  the fireflies are a few faint specks at phone size; between the Weltmauer's east end and the valley's mountains
  the dusk sky shows as an orange wedge (`74-look2-town-dusk`), which is the layout's, for the art lane to judge.

### The lord pass and the story pass (10.11.2026)

Louis' decisions of 09.11. (STORY.md): the player is the Burgherr or the Burgherrin of House Lantern, named by the
player, with a circlet and no crown; the lord sits during an audience; the houses come to the hall. Both passes were
made on `claude/lh-storypass` after merging `claude/lh-story` (STORY.md) and `claude/lh-look2-fable` (the look-2 art).

**The lord (code).**

- `LordIdentity` (`Core/Lord.swift`): a name and `LordForm` (`lord`, `lady`), stored in the save as `GameState.lord`.
  A save from before the pass has none and reads as the standard lord (Robin, Burgherr). The name never leaves the
  device: no network call, no analytics, no ad request carries it.
- The name: letters of any script, single spaces, hyphens, apostrophes and full stops; no digits, signs, emoji or line
  breaks (so a name can never carry a brace of the placeholders); trimmed, 16 characters at most
  (`LordIdentity.nameLimit`). An empty field gives "Robin", which the field shows as its prompt.
- The name entry (`UI/LordEntryView.swift`, overlay `.lordEntry`): a new realm asks once, on day 1 before its first
  dawn, when no lord is chosen (`LordEntry.asks`). Burgherr is marked at first; "Begin" stores the lord in the realm
  and its dawn snapshot and writes the save. A restart from the pause sheet asks again and starts from the old realm's
  lord. The debug arguments that skip the onboarding, name the lord, let the bot play or open a sample screen never
  ask, so every older test starts as before.
- The placeholders of the story texts (`LordText`), the same in English and German: `{lord}` is the name, `{a|b}`
  reads `a` for the Burgherr and `b` for the Burgherrin. Nothing nests. `StoryText.string(key, lord:)` resolves them;
  every card, bubble, remembered line and report quote goes through it.
- The validator counts the longest reading (every name 16 characters, every choice its longer half) against the text
  limits and reports any brace group that is neither form.
- Sprites: `king` or `lady` with their glow strips, `kingSeated` or `ladySeated`, and the two portraits, picked by the
  form (SPRITES.md "The lord pass"). The ids keep the word king; no player reads them.
- The throne: during an audience before the throne the lord sits on it (sit-down frames 0 and 1 over 0.4 s, then the
  breath 2 and 3; Reduce Motion: seated at once), mirrored to face the petitioner. The throne's drawn middle is x 1837
  (`WorldLayout.throneX`, the middle of the painted dais), 13 px right of `Realm.throneX`, which the simulation keeps.
  Odile stands 21 px to the throne's right and never covers the seated lord.
- The benches: waiting townsfolk whose body is `citizen`, `citizenB` or `citizenC` sit (two to a bench, the next one
  nearest the throne; a nod now and then, never in step with the neighbour); other bodies and guests stand; whoever is
  called stands up and walks.
- Debug arguments `-GWLord lord|lady` and `-GWLordName <name>`; the scene's status carries `lord:<form>`; identifiers
  `lord-entry-root`, `lord-name-field`, `lord-form-lord`, `lord-form-lady`, `lord-confirm`, `audience-text`,
  `audience-remembered`.

**The story (texts), STORY.md section 9.**

- 9.1, words: 207 texts changed in English and German. No king, crown, Majesty or Majestät is left for the player; the
  search leaves only the Lightless King, the Stays and the sea cliffs. Forms of address, by speaker:

  | Speaker | English | German |
  |---|---|---|
  | townsfolk, the bard | `my {lord\|lady}` | `{Burgherr\|Burgherrin}` |
  | soldiers, Bram | `my {lord\|lady}` | `{Herr\|Herrin}` |
  | Odile, Tamsin | `my {lord\|lady}` | `{mein Herr\|meine Herrin}` |
  | Brannock | `{lord\|my lady}` | `{Herr\|Herrin}` |
  | Hesper | heir of the house | `{Erbe\|Erbin} des Hauses` |
  | Ludo | `good my {lord\|lady}` | `{edler Herr\|edle Herrin}` |
  | Seren | Lantern; lord after day 15 | Lantern; Herr |
  | Marek, Pip | Your Radiance, Your Wickship | Eure Strahlkraft, Eure Dochtheit |
  | envoys and the houses' faces | `{Lord\|Lady} Lantern` | `{Lord\|Lady} Lantern`; Hild `{Burgherr\|Burgherrin}` |
  | Dame Orla | heir of Taper | `Tapers {Erbe\|Erbin}` |

  German uses "Ihr" and "Euch" throughout. "Lantern" and the names of people, houses and towns are never translated.
  Glossary: the Throat, der Schlund; the circlet, der Stirnreif; the Count, die Zählung; the Returned, die
  Heimgekehrten; the Cleft, der Spalt; the Lamp Tithe, der Lichtzehnt; the Great Beacon, das Große Leuchtfeuer; the
  Dark Year, das Dunkle Jahr; Lady Oriel, Burgherrin Oriel; Lord Aldric, Burgherr Aldric; Saint Taper, Sankt Taper
  or der heilige Taper (one saint, one German name). No creature is called a child in either language.
- 9.2, the rewritten petitions and lines, as listed there: the premise (the heir of the guardian house, HOUSE.md),
  `first_plough`, `stranger_gate`, the six from Beaconfoot, `child_question`, `hesper_giant`, `beacon_plans`,
  `banners_new`, the statues of Saint Taper, Lord Aldric's texts, `haunted_cellar` (a Returned and a blue
  door), `scout_report`, `eclipse_omen`, `captured_sootling`, `herald_alone`, Seren's two, `last_stand`, `bard_song`,
  `chronicle`, `keep_window`, `widow_pension`, and the lines. No effect changed. One flag changed its name:
  `captured_sootling`'s third choice lets the sootling go at the Throat gate, so it sets `gerald_freed` (was
  `gerald_kept`), and Brannock's line asks for it. The bard is Finch and the envoy Ansel Quay, Envoy of House Brine
  (both now have a `nameKey`; the herald is the one guest without a name).
- 9.3, the houses' six audiences in `petitions-story.json` (chapter 1, the first choice Odile's counsel):

  | id | Speaker | Days | Flags by choice |
  |---|---|---|---|
  | `varn_levy` | Hild Varn | 3 to 4 | `varn_with` / `varn_stung` / `varn_with` |
  | `oxmoor_gift` | Lorenz Pell | 5 to 6 | `oxmoor_lamp` / 30 gold, `oxmoor_debt`, `oxmoor_with` / `oxmoor_refused` |
  | `calder_audit` | Ebba Calder | 12 to 13 | `calder_with` / `calder_coddled` / `calder_refused` |
  | `lorn_visit` | Dame Orla Lorn | 14 to 15 | `lorn_with`, `lorn_heard` / `lorn_with`, `stubs_known` / `lorn_dismissed` |
  | `tithe_letters` | Odile | 16 | `banners_hung` and the world change `castle.hall.banners.houses` / `holds_alone` |
  | `varn_ride` | Hild Varn | 18, needs `varn_with` | `vow_aldric` / `hild_stays` / `hild_rode` |

  Only `oxmoor_gift`'s signature moves a number (30 gold now, the debt remembered). Every other choice leaves one
  remembered line (15 new flags in `Remembered.flags`, each with its `remember.<flag>` text), so the trace test
  holds. `oxmoor_with`, `lorn_with` and `brine_with` (set beside `coast_promise` in `envoy_tide`) only record which
  houses stand with House Lantern. `vow_aldric`'s remembered line is neutral ("Your word is given: Aldric comes
  home."), since Hild's first choice and `last_stand` both set it. An unheard house petition sets nothing and locks
  nothing. The world change is registered and not drawn yet.
- The six come on top of the day's petitioners (`"onTop": true`, `Petition.onTop`): a day draws its two to four as
  before and the house's audience is one more, heard among the story petitions. Reason: counted against the day's
  number they took the place of about five random petitioners in a chapter, and round `lh-sp-2` measured what that
  did to the tuned chapter (T6 without the beacon held 3 of 20 for a band of 30 to 60 %, night 20's step check off).
  On top, with Odile's counsel setting flags only, the reference bot's chapter is the tuned one again
  (`testAStoryPetitionOnTopLeavesTheOthersAsDrawn`, `testTheHousesAudiencesComeOnTopAndTheirCounselMovesNothing`).
- The four faces (`Speakers.guests`): Hild Varn, Lorenz Pell, Ebba Calder and Dame Orla Lorn are guests with a name
  and a role line, an archetype body (`guardsman`, `petitionerE`, `petitionerD`, `citizen`) and a composed portrait
  with one option per part, so each has one face in every realm. They stand in the hall while their petition waits
  and can be spoken to on those days. Their own sprites, the houses' sashes and the banners are the art lane's.
- Fourteen court lines (`lines.json`): `brannock_pole`, `bram_lanterns`, `hesper_west`, `tamsin_mother`,
  `seren_kitchen` (needs `stranger_in`), `calder_statues`, `bard_returned`, `pip_pages` (an answer to `stubs_known`),
  `odile_door`, `envoy_lanterns`, `orla_cleft`, `marek_letters`, `hild_father`, `tamsin_place` (day 19).
- 9.4: the new counsel choices move no gold, no people and no night and roll no chance; no gift comes late on the
  counsel path; every petition has a choice that costs nothing.

**Left open, outside this pass.** The SF Symbol `crown.fill` on the audience card and the HUD's action button; the
giant in `hesper_giant` and its lines, and `wedding_feast`, against STORY.md's rule 12; internal names with "king"
(`scarecrow_king`, sprite ids, `Core/KingTargets.swift`); "Tanz" in the German `watch_feast`; the later petitions
`quay_lanterns`, `pell_returns`, `hemmet_sentence`, `finch_list`; what STORY.md 9.2 leaves to the lead in this file
(the chapter's title, the premise, the prologue, the endings' names, chapters 2 and 3).

**Rounds.**

- `lh-sp-1` on 59652fe (the lord pass; build, unit, ui, ui-de): the build, the name entry, the seated lord and the
  benches held. Two failures waited for the texts: `testTheStoryTextsTakeTheLord` (unit) and the typed name on day
  1's card (ui, `LordUITests`).
- `lh-sp-2` on b6b3773 (all texts, the houses counted against the day's number): build, ui and ui-de passed, the
  validator reports nothing. Unit failed twice in the tuning: T6 without the beacon held 3 of 20, and night 20's
  headless step check was off for seed 2. Fixed by `onTop`, no number of the balance touched.
- `lh-sp-3` on 11a9729: ALL PASSED (build, unit with 351 tests, ui, ui-de). T1 to T8 and the reference bot's nights
  are line for line what `lh-sp-1` measured before any text changed; the one line that differs is the Court's: the
  bot heard 1188 petitioners (1068 and the six houses in each of 20 runs). Screenshots 70 to 77 in English and
  German: the name entry, the Burgherrin in the hall and on the throne, day 1's rewritten petition with her name in
  Odile's counsel, the Burgherr seated before Brannock.

### Round 2 joined (10.11.2026)

The join brought round 2's four lanes, all built from 9d34f9a, together on `claude/game2-planning-354541`:
`claude/lh-port` (6fdd242: look 2 as the default, the weather, the castle's tiers as drawn, the world and creature
sprite ids; round `lh-l2-4b`), `claude/lh-storypass` (c7f6cfa: the lord pass and the story pass; round `lh-sp-3`),
`claude/lh-look2-fable` (72293ae: the newer art, ART-look2.md section 18) and `claude/lh-quests` (b225ffd: docs only,
docs/QUESTS.md and docs/karte.html).

**The merge**

- `claude/lh-port` merged cleanly (9983934).
- `claude/lh-storypass` conflicted in five files, resolved so both sides stay (e08f2c3):
  - `Core/FrameDesc.swift`: the port's rain and look-2 world ids first, then the lord pass's ids (the lady, the seated
    lords, `portraitLady`, the seated townsfolk); both groups in `size`.
  - `App/DebugArgs.swift`: the port's `-GWLook`, `-GWCastle`, `-GWWeather`, `-GWWind`, `-GWRain`, `-GWWetness` beside
    the lord pass's `-GWLord` and `-GWLordName`.
  - `App/GameModel.swift`: the debug value carries `lit:` (port) and `lord:` (lord pass).
  - SPRITES.md: the port's sections, then the lord pass's, then the art pass's proposals.
  - DESIGN.md: one arguments table and both lanes' sections in order.
- `claude/lh-look2-fable` conflicted in SPRITES.md only (787ce14): the port's and the lord pass's sections stay, the
  art pass's two new proposal sections follow the proposals' head. `claude/lh-quests` merged cleanly (429404e).
- Clashes in meaning, fixed after the merges:
  - Both lanes numbered their screenshots 70 to 77. The port keeps 70 to 90; the lord pass's are 91 to 98
    (`91-lord-entry` to `98-lord-seated`; `UITests/LordUITests.swift`, 398c255). Where the lord pass's rounds above
    speak of 70 to 77, these are meant.
  - Look 1's golden hashes (see below).
- The atlas holds all of it: 286 sprite ids, 1669 px high at 2048 px wide (`AtlasLayout.maxSide` 2048).

**Wired from the newer art** (6f8e1a0, look 2 only; SPRITES.md carries the status)

- The town's lit rooms: `houseLit`, `houseBLit`, `houseCLit`, `bigHouseLit`, `tavernLit`. `EntityFrames.litRooms`
  gives a look-2 house its room sprite as an emissive part in place of the glass masks, so the windows show the
  painted room at dusk and by night. An emissive part can now follow its prop's mirroring (`EmissivePart.mirrors`),
  which the mirrored cottages need. `testTheTownAtNightOfLookTwo` holds it.
- Two more paintings of every town tree: `lindenB`, `lindenC`, `poplarB`, `poplarC`, `appleTreeB`, `appleTreeC`,
  `willowB`, `willowC`, planted in look 2's town in place of repeats (`SceneLayoutLook2`), swaying like the others.
- The repainted sprites (the M3 court, the defences, the gates, the towers, the dais in light oak) need no code: a
  PNG of the same name wins.

**Look 1's golden hashes.** Both looks draw from one atlas and one world layout, so the repainted sprites and the lord
on the moved throne (`WorldLayout.throneX` 1824 to 1837) reach look 1 too. Of the six pinned scenes the three town
scenes (`square-morning`, `town-noon`, `river-golden`) keep the hashes of round `lh-l2-0d`: look 1's drawing is
untouched. `front-night`, `castle-night` and `court-dusk` show the repainted defences, gates and towers and the hall
with the seated lord; their upper bands' sums are the old ones, and the court's picture differs from the port's in
3600 px, all on the dais. Their hashes were recorded again from round `lh-j2-1` (4b74250, `Tests/LookGoldenTests`)
and are asserted from there on. The golden test lived in the port lane only, so the lord pass's change to look 1's
court was never hashed on its own.

**Left open**

- `hayCart`, `barrels` and `noticeBoard` are painted and bundled but not registered: nothing says yet where they
  stand. `willowB` is registered and bundled but not planted (the river bank has two willows; SPRITES.md proposes a
  young third between them, at world 3738).
- The lit rooms do not flicker with their hearths, and the chapel, the kitchen and the hall's front have no lit-room
  sprite. The static scene's cottages keep their glass masks.
- Seen in the dusk shots of the town (`74`, `87`), and already in the port's round `lh-l2-4b`: a brown wedge between
  two far mountain layers under the cloud band. It is the port's or the art's to look at.
- What the lanes left open themselves stands as written in their sections above.
- The first three points are closed in "Polish after round 2" (the props stand, the young willow is planted, the
  rooms flicker, the wedge is closed); the chapel, the kitchen and the hall's front still have no lit-room sprite.

**Rounds.**

- `lh-j2-1` on e0e5ea7: ALL PASSED (build, unit with 375 tests, ui, ui-de, release; 10:49 to 11:58 UTC). T1 to T8
  give the lanes' numbers (T6 with the beacon 20 of 20, without 10 held; T7 17 of 20 in the band; T8 79.9 s), the
  Court line is the story pass's (1188 petitioners), the tuning report is `lh-sp-3`'s line for line, and night 20's
  step check is identical to both lanes'. Look 2's budgets: most instances 98, most lights 16, 322 instances in a
  storm. Look 1's three town hashes held; the other three were printed, not yet asserted. Screenshots in English
  and German: the name entry with a typed name (`92`), the Burgherrin seated for day 1's farmer (`94`), the Burgherr
  seated before Brannock (`98`), the town at dusk with its lit rooms (`74`) and in the rain (`87`).
- `lh-j2-2` on 4b74250 (the three hashes recorded; build and unit only, since nothing but the test's table changed):
  ALL PASSED, 375 tests. All six of look 1's hashes are asserted and hold; the tuning report and night 20's step
  check are `lh-j2-1`'s byte for byte.

### Polish after round 2 (10.11.2026)

Branch `claude/lh-polish`, made from the planning branch at f9751d1. Look 2 only: look 1's frames are the frames
they were (its six golden hashes hold the proof). Nothing here adds state: `GameState`, the save and the tuned
simulation are untouched.

**1. The Gloom's fog** (`Core/GloomFog.swift`, `FrameBuilder.gloomStrips`, `gloomSlices`, `gloomWisps`,
`gloomEyeTiles`, `gloomEyes`; rules fbddd2e, stage 7's paintings 3473d99 wired after it)

- From dusk a cold fog bank creeps out of the darkness bank and up the Throat; at first light (5:00 to 6:00) it
  pulls back into the shadow land. It is a picture only: `FrameBuilder` and `EntityFrames` read it, the simulation
  never does (the battle's light field, the bank's edge and every creature's path are what they were).
- One number drives it, the night's hardness (0 to 1): `(min(night, 20) - 1) / 19 × 0.7`, plus 0.3 under the M3
  night modifier `fog`. The harder the night, the earlier, further and thicker:

  | | first night | night 12 | hardest |
  |---|---|---|---|
  | starts to creep | 19:15 | 18:51 | 18:15 |
  | stands whole | 20:30 | 20:18 | 20:00 |
  | reach past the bank's edge | 150 px | 251 px | 400 px |
  | thickest cover | 0.5 | 0.66 | 0.9 |
  | pairs of eyes | 5 | 9 | 14 |

  The front never passes x 1180: the castle's front keeps its own mist.
- Drawn with stage 7's paintings (SPRITES.md "The Gloom's fog"), all at the lane's own parallax, each a body that
  repeats (frame 0) behind a leading face (frame 1) that ends at the strip's front:

  | strip | plane | height | its front, of the fog's way past the edge | breath |
  |---|---|---|---|---|
  | `gloomFogBack`, the fog bank | fog A, behind the actors | 120 px | 0.43 (64 px on the first night, 172 on the hardest) | 3 px in 9 s |
  | `gloomFogMid`, the veil | fog B, before them | 64 px | 0.7 (105 to 280 px) | 6 px in 7 s |
  | `gloomFogFront`, the creeping fog | fog B, 8 px under the ground line | 30 px | 1 (150 to 400 px) | 10 px in 5 s |

  The tall bank stays near the darkness, the low fog leads; on the first night the three fronts stand where the art
  lane laid them. They are drawn in slices of 16 px with the alpha `presence × paintCover` (0.825 on the first
  night, 1 on the hardest) less the fire's hole at the slice's place. The paintings carry the night's own colours:
  the lift the shader gives the hour's fog (`Look2.fogBrightness`, up to × 2.6) is taken out of their tint, and
  inside the bank the shader darkens them with the bank's ambient.
- While the fog bank stands (`presence`: it fades in over the first quarter of the fog's way and out at the end of
  first light), the bank's old wall of night (`darknessBank`, `darknessEdge`) and its glow are faded out against
  it: the fog bank stands in their place and the gorge shows above it. By day the bank rests as it did.
- Shreds (`gloomWisp`, six frames once in 4 s) tear off the creeping fog's nose, one every three to four seconds,
  and drift ahead 6 px/s and up 1 px/s.
- The fires of the lines cut holes: every light that counts in battle (brazier, fire tower, beacon, torch by its
  hour's strength) takes up to 0.85 of the fog away in the inner half of its pool, none a little past its rim
  (`GloomFog.clearing`, `hole`; at most 130 px wide). Windows, candles and the moon cut none.
- Cold eyes: in the bank's heart the painted pairs (`gloomFogEyes`, glow only, 64 px tiles laid leftward from 32 px
  behind the edge, stepping through their four frames); between the bank and the middle of the fog single pairs
  (`eyeGlints` as glow, a little over white so the bloom catches them) open, look, blink once, close and open
  elsewhere. Both are added before the lane's props, so a wall hides the eyes behind it, and both dim in a fire's
  hole.
- The creatures step out of it: an unlit creature's body is unseen 150 px behind the bank's edge and whole from
  56 px behind it (`bodyAlpha`), so it forms inside the dark and nothing fights half seen at the outer wall. By day,
  with no fog, the bank hides no more than it did.
- Reduce Motion: the fronts stand (no breath), no shred tears off, the painted eyes hold one frame, every second
  roaming pair stands open where it is, none blinks.
- `-GWGloomFog off|<0...1>` for shots. `Tests/GloomFogTests.swift` holds the rules, the frame's budgets and that
  the simulation's state is the same with and without it.

**2. The old walls and the tiers' anchors** (stage 7 of the art, 6115c72; wired in 9bffdd5)

- The older wall's ruins stand in the Throat as scene props, always drawn: `oldWall3` at the outer line (x 612),
  `oldWall2` at the middle line (x 912), both 8 px into the ground at z -2, and `oldWall1` (84 × 60) at x 1150 before
  the gatehouse. An empty plot of line 2 or 3 so shows what the tier will be built into.
- A built tier of line 2 or 3 stands in its anchor (`EntityFrames.wallAnchor`: `palisadeAnchor`, `stoneWallAnchor`,
  `bastionAnchor`, 128 × 108, at the ruin's place, z -1, behind the tier). The anchor stays under an upgrade's
  scaffold and when the tier lies as rubble; the first build's scaffold stands before the bare ruin.
- Until the art landed a ruin painted in code stood there (fb2897c); it is retired (id, size, painter, tests).

**3. The castle grows** (`Core/CastleGrowth.swift`, `GameModel.growCastle`; 84ee833)

- The castle's tier follows its gatehouse: the gate is tier 1, the iron gate tier 2, the great gate tier 3
  (`CastleStage.grown`). While the builders raise the gatehouse by day the next tier stands under scaffolding (the
  keep's top, the back rise and the far castle in their building states), and whole when they are done. A fallen
  gate keeps the tier; rebuilding it is no growth.
- Cost, time and effect are the gatehouse's own, which the economy was tuned with: the iron gate 90 gold and the
  great gate 180 gold (25 s and 40 s for two builders), strength 4 000 / 7 000 / 11 000, archer posts 4 / 6 / 8. So the
  effect is modest and already in T1 to T8; the build card now says what the order does ("The castle grows ·
  strength 7000 · 6 archer posts", German "Die Burg wächst · Stärke … · … Schützenposten"; the other six languages
  come with M7's pass).
- No state: the stage is read from the gate's plot each time the play changes it, and the scene is laid out again
  when it differs. `-GWCastle` still fixes the stage for shots; `-GWBuild raise` shows the third tier under way.
- A separate keep upgrade with its own price was weighed and left out: a second sink beside the gatehouse would
  move the gold curve the tuning stands on.

**4. The polish list** (5f721da, c2b2dd3)

- The square: `noticeBoard` (x 2990) and `hayCart` (x 3040) stand on the market square behind the actors, the
  `barrels` beside the tavern (28 px left of it, with the tavern, so a realm without one has none).
- `willowB` is planted between the two willows at the river.
- The lit rooms flicker: at 0.4 of a fire's flicker and 0.35 of its pace, every house with its own seed; with
  Reduce Motion as faint and slow as the fires' reduced flicker.
- The audience button and the audience card carry the lord's circlet in place of the crown symbol: the painted
  icon of stage 7 (9a143fe; `circletIcon` in gold at 48x32 pt on the audience button, `circletIconInk` at 24x16 pt
  in the button's ink on "End the audience"), two sprites of 24x16 through the atlas (`CircletIcon` in
  `UI/Theme.swift`).
- Rain over a bright scene: a pale streak before a day sky was lost, so the brighter the air, the darker the rain
  falls (slate by day, a little denser; pale as painted from dusk on). Alpha stays under 0.5.
- Fireflies at phone size: each fly is drawn over white (the bloom gives it a halo) and four more times one pixel
  off at 0.28: a bright dot in a soft cross.
- The brown wedge of the town's dusk shots: the far wall falls from 139 to 12 px between far x 658 and 694 and the
  valley vista's slope only reached that height at 732, so a wedge of horizon sky stood open under the cloud deck.
  Both vistas stand 64 px further left (556 and 1004): the wall ends behind the fir slopes.

**5. The houses' faces and banners** (stage 7 of the art, 8822299)

- The four houses' faces are guests like the envoy from the coast, each with a painted body (14 × 30, walk 0 to 3,
  idle 4 to 5, talk 6 to 7) and a story portrait: `hildVarn`, `lorenzPell`, `ebbaCalder`, `orlaLorn` (Dame Orla
  with her great-grandchild in her frame) and `portraitHildVarn` and so on. Their stand-ins (the archetype bodies
  and one composed face each) are gone. They wait standing, as every guest does. Brine's face stays the envoy.
- The houses' banners (`bannerBrine`, `bannerCalder`, `bannerVarn`, `bannerLorn`, `bannerOxmoor`, 20 × 41) hang in
  the great hall over the realm's painted banners, left to right in that order, Varn's over the throne
  (`CourtFrames.houseBanners`: x 1744, 1783, 1821, 1858, 1895, y 25, z -1: over the interior, behind the throne and
  the court). A house's banner hangs once the lord had the banners hung (`tithe_letters` on day 16 sets the world
  change `castle.hall.banners.houses`) and while the house stands with him (`varn_with`, `brine_with`,
  `oxmoor_with`, `calder_with`, `lorn_with`). At such a place the realm's renewed banner (`castle.banners.new`) is
  left out. No state: both are read from the flags and the world changes the story already keeps.
- `-GWHouses` sets the flags and the world change for shots.

**Tests.** `Tests/GloomFogTests.swift` and `Tests/PolishTests.swift` (the fog's rules, the ruins and anchors, the
castle's stage through play and through the arguments, the props, the flicker, the rain's shade, the fireflies, the
vistas, the houses' faces, their placeholders and `-GWHouses`), `Tests/CastleRoomsTests.swift` (the houses'
banners in the open hall). UI: `UITests/PolishUITests.swift`, `testPolish`, `testPolishCirclet` and
`testPolishHouses`, English and German; `testPolish`'s shots are held still:

| Shot | What |
|---|---|
| `100-polish-fog-dusk` | day 12 at 19:48, the fog creeping out of the bank |
| `101-polish-fog-night` | night 12 at 23:20, the bank up the Throat, the creatures stepping out |
| `102-polish-fog-hard-night` | the same with `-GWGloomFog 1` |
| `103-polish-fog-dawn` | 5:30, pulling back |
| `104-polish-fog-reduce-motion` | 101 with Reduce Motion |
| `105-polish-ruins-dusk`, `106-polish-ruins-noon` | a new realm: the ruins on the middle and the outer line |
| `107-polish-ruin-and-wall-day7` | the reference bot's realm on day 7 |
| `108-polish-walls-dusk`, `109-polish-walls-noon` | the demo realm's stone walls in their anchors |
| `110-polish-castle-tier1-dusk` | a new realm's castle (tier 2 is `72`, tier 3 `82`) |
| `111-polish-castle-raise-noon`, `112-polish-castle-raise-back` | `-GWBuild raise`: tier 3 under scaffolding, from the Throat and from the valley |
| `113-polish-square-dusk`, `114-polish-square-noon` | the market square with its props; fireflies at dusk |
| `115-polish-rain-town-noon`, `116-polish-rain-square-dusk`, `117-polish-rain-river-day` | rain over bright scenes |
| `118-polish-circlet-button` | the circlet on the audience button |
| `119-polish-banners-all`, `120-polish-banners-two` | the great hall on day 12 with the five houses' banners, and with Varn's and Lorn's |
| `121-polish-envoy-hall`, `122-polish-envoy-audience` | day 3: Hild Varn waits in the hall, then her audience card |

**Rounds.**

- `lh-po-1` on fe84b61 (the fog, the walls, the tiers and the list, before the houses and the painted circlet):
  FAILED: 1. Build, ui, ui-de and release passed; unit ran 394 tests and one failed, a mistake of the test's own:
  `testTheSquaresPropsAndTheYoungWillow` took the first `.well`, and look 2's world has two (the castle
  courtyard's at x 1600, the square's at 3013). It now takes the one inside `WorldLayout.marketSquare`. T1 to T8,
  the tuning report and night 20's step check were already `lh-j2-1`'s.
- `lh-po-2` on e8ece32 (everything above, the houses' faces and banners and the painted circlet included): ALL
  PASSED (build, unit with 399 tests, ui, ui-de, release; 16:59 to 18:01 UTC). No warnings from the code.
  - The simulation did not move: T1 to T8 pass with the joined round's numbers (T1 hearth 100, no losses; T2 nights
    [3, 3, 3]; T3 days [17, 16, 17]; T4 27 and 83; T5 3 builds, 11 buildings by day 10; T6 with the beacon 20 of 20,
    the King slain 20, without 10 held; T7 17 of 20 in the band; T8 79.9 s, 39 sim entities, 11 battle lights), and
    the tuning report and night 20's step check are `lh-j2-1`'s byte for byte. The castle's tier follows the
    gatehouse, whose price and strength the tuning already held.
  - Budgets: the frame budget's most is 161 instances and 15 lights (at the bank: 161 with the fog, 78 without);
    night 12 live 107 instances, 17 lights, 23 creatures at once; look 2's scenes 99 instances and 16 lights, 322
    instances in a storm; 20 nights of the reference bot in 2.6 s (Debug).
  - The atlas is 2048 x 1788 of at most 2048 x 2048: about 260 rows are left, so the next large sprites need a
    second page or smaller cells.
  - Screenshots, English and German (`100` to `117` are byte for byte `lh-po-1`'s, so the stills hold still):
    - the fog (`100` to `104`): the bank stands dark up the Throat with pairs of cold eyes and a siege tower in
      it, the creeping fog runs pale along the ground, three creatures stand at the stake pit in the firelight
      just outside the bank (`101`); it pulls back at dawn (`103`) and stands still with Reduce Motion (`104`).
      The creatures are small at this zoom, and the pale fog ends in a straight edge where a rock spire stands
      in front of it;
    - the old walls (`105` to `109`): a new realm's crumbled ruins between the rock spires, the reference bot's
      realm with a ruin on one line and a gate on the other (`107`), the demo realm's stone walls set into the
      spires with the archers on them (`108`, `109`). In `105` to `107` the right-hand ruin stands partly
      behind the build button;
    - the castle (`110` to `112`): the first tier at dusk with its braziers, then the third tier going up, with
      scaffolding over the gate and the right-hand tower, from the Throat and from the valley;
    - the market square (`113`, `114`): the notice board, the well and the hay cart under the oak, lamps and
      fireflies at dusk; the cart is a dark shape at dusk and clear at noon. The tavern's barrels are outside
      this frame;
    - the rain (`115` to `117`): grey streaks over the town and over the river meadows by day; at dusk (`116`)
      the streaks are faint;
    - the circlet (`118`): the painted gold band with its blue stone on the audience button;
    - the houses (`119` to `122`): five banners of five houses under the hall's beams, then Varn's and Lorn's
      between the realm's own; Hild Varn waits at the hall's door on day 3, and her card shows her own portrait.
      "Tochter des Hauses Varn" and the three answers fit in German.

<!-- BEGIN world lane: World rebuild (14.11.2026) -->
### World rebuild (14.11.2026)

The world lane of the rebuild after TestFlight build 86 (docs/REVIEW-look-2.md: the world plan in section 2, the
punch list in section 3). Branch `claude/lh-world`. The simulation's positions and the tuning targets T1 to T8 are
untouched; only the backdrops, the fog and the castle's outer art change. The stage lane (the great hall as its own
stage, Controls 2, the interface) runs beside it on `claude/lh-stage`.

#### Step world-1: the rock and the fog (B4, B5, B6, H2, H6, M1; world plan 2.3 and 2.5)

The rhythm: open and cold over the moor, enclosed and towering in the Throat and the castle (a later step opens the
warm valley beyond the back gate).

- **The darkness bank** (0 to 260 by day, up to the bank's edge at night): three sheets of soft fog at the lane's own
  parallax, `bankSheetA` on fog A (tall, its core above every screen's top), `bankSheetB` on the world plane after
  its props (it hides what stands in the bank) and `bankSheetC` on fog B (a low roll before the creatures). They are
  laid every 100 px westward from the bank's edge (`FrameBuilder.bankSheets`, `bankSheetTiles`), so each sheet's
  face lies in the core of the sheet east of it and only the first face shows; the faces breathe against each other
  (none with Reduce Motion) and move with the bank's edge as one volume. Painted in the night's colours, so on the
  fog planes the shader's lift is taken out of their tint; the bank's eye glints (`darknessBankGlow`) stay. The old
  wall of night (`darknessBank`, `darknessEdge`) is look 1's. The world ends in darkness, never at a wall: the
  camera clamps at 0, so the screen's left edge always lies in the bank.
- **The dead moor** (260 to 470): open sky, the firs and dead trees on the near plane, the shadow forest, the mist.
  The Weltmauer stands 30 px higher (`look2WallRise`): over the shadow land and the Throat its peaks are cut by the
  screen's top (H6), and a deck of far clouds lies across it at half the screen's height (rows 40 to 90 on the
  runner's phone; the valley's cloud at far x 640 stays). Its first 320 columns sink into a bank of painted mist
  toward the west (`cleftart.py mistleft`). The far castle in its first slot is gone (`cleftart.py noslot`): the
  castle stands behind the player's back, never in the background (2.5).
- **The Throat**: every slab and card on or before the walk line is gone (`cleftFlank`, `cleftFlankB`,
  `cleftThroat`, `gorgeCrags`, `gorgeRock`; their files in `tools/retired-art`, `gorgeRock.png` still the old walls'
  granite). The cleft's far wall climbs in three steps on the mid plane (`look2Rock`): `throatStepA` (mid 360, at
  most 88 rows, far and pale, its west talus paling into the mist), `throatStepB` (mid 450, darker and taller, the
  warden statue's niche) and `throatStepC` (mid 600, the cleft's granite, top-anchored, a crag that falls to the lane
  at its west end, then the full height behind the gatehouse). The mid column at the screen's centre with the camera
  centred on world x is `109.25 + x / 2` (720 → 469, 1240 → 729, 2330 → 1274).
- **The cleft wall** (`cleftWallA` to `C`, mid 824 to 1528, top-anchored, full height): one painting with step C,
  cut in four, behind the whole castle (H1). A jagged slit of sky in its top 24 rows; buttresses and chimneys lit
  from the upper left with cast shadows, short ledges, snow in patches on the high ones, the slit's cold slate light
  on the face's top dithering into the warm granite, three threads of water with wet streaks and spray; C steps down
  to the valley floor behind the back gate. A cold shaft of light falls through the slit by day (`cleftShaft`, drawn
  white at the sun's strength through `Prop.sunShaft`, less under cloud). At night the moon stands in the slit
  (`FrameBuilder.cleftShare` moves it up to row 3 while the camera is in the cleft; the sun's disc stands behind the
  rock). The castle's warm light grazes the wall over the roofs at dusk and night: five backdrop lanterns on the mid
  plane behind the forge, the hall door, the chapel, the kitchen and the back gate.
- **Inside the walls the far plane is gone**: in look 2 every far-plane prop is drawn at `1 − cleftShare(focus)`
  (0 from camera centre 1380 to 2300; it fades while the gatehouse and the steps cover it and comes back as the
  back gate opens the valley). The slit shows the sky, its clouds and the moon only.
- **The gatehouse grows out of the rock** (H2): `gateRockL` and `gateRockR`, granite plinths in front of each
  tower's outer foot, highest right at the outer edge (world 1249 and 1470) and falling under the tower in a ragged
  stair (`look2GateRock`; tier 3's drums stand 11 and 12 px further out). The mid plane behind the gatehouse is rock.
  The front's cast shadows onto the retired rock beside the east tower (`castleShadow`, `castleShadowLong`) are left
  out in look 2 (they darkened the cleft wall far behind as a vertical band); the ground's and the gatehouse's own
  shadows stay.
- **Fog without square edges** (B4, M1): the hour's three banks (`d2FogBank`, `d2MistBand`, `d2FogLow`,
  `tools/fogart.py`) are tiles with a 48 px dithered feather at each end, laid every `width − 64` px
  (`FrameBuilder.fogOverlap`), their feathers complementary inside the overlap; the density thins upward under a
  soft rolling top in eight alpha steps with ordered dither, and stands still under Reduce Motion. The Gloom's strips
  (`gloomFogBack`, `gloomFogMid`, `gloomFogFront`) are repainted the same way (stage 7 painted flat bands with
  stepped tops: the review's "contour map"), same ids, sizes and frames; they are cut into 8 or 4 px pieces where a
  fire's hole changes the cover steeply (`FrameBuilder.gloomSubSlices`), so the fog thins toward a fire in small
  steps instead of 16 px columns.
- **Set borders** (B5): the valley's tree belt (`d2TreeBelt`, mid 1400 and 1920) stands at z 2 behind the cleft wall's
  last crags, so its west end is hidden by the rock where the cleft opens to the valley.
- **Look 2's backdrop lights** reach the mid plane at 0.5 of their strength (0.3 before; `Shaders.metal`
  `lh2_base`): the warden statue's bowl fire and the castle's lanterns on the cleft wall.
- **The art** is pure python and rebuilds byte for byte (`tools/build-art-world.sh`): `tools/rockfield.py` paints
  granite as a lit height field (buttresses with lit west and shaded east bevels, chimneys, ledges and overhangs,
  joints, cast shadows marched toward the light, a cavity term, less light deeper in the cleft), `tools/cleftart.py`
  cuts the cleft and the steps and the gate's rock from it, `tools/fogart.py` paints the fog, the bank and the Gloom's
  strips. The rock is painted in clean clusters without dither (Louis' art bar); only the fog's alpha is dithered.
  ART-look2.md section 22 has the notes, SPRITES.md "The rock and the fog" the ids.
- **Tests**: `FrameBuilderTests.testNoFogEdgeEndsInTheViewWithoutAFeatherOrANeighbour` (B4: every fog sprite's art
  feathers out, the hour's tiles overlap complementarily, and from the bank to the river at three hours, with and
  without the Gloom's fog, no fog instance's edge column stands in the view without a feather or a neighbour);
  `testNoBackdropEndsInASeamFromTheThroatToTheValley` (B5: camera centres 1200 to 2500 in 20 px steps, every end
  column of a backdrop piece inside the view is covered by a piece in front or clear; inside the walls no far plane
  and the cleft wall at the screen's centre); `GloomFogTests.testTheFogThinsTowardAFireInSmallSteps`; the layout
  checks in `Look2FrameTests`. The UI sweep `WorldSweepUITests` (English only; the pictures carry no text) shoots
  camera centres 0 to 2600 in 200 px steps at noon (`-GWDay 12 -GWHour 12`), dusk (`-GWHour 19.2`) and night
  (`-GWNight 12 -GWHour 23.33`), plus the bank and the Throat on a hard fog night and twice with Reduce Motion:
  `w-<centre>-<noon|dusk|night|fog|fog-rm>-en`. `-GWTimeOfDay` drives only the probe and the light lab; the game's
  clock follows the realm.
- **Rounds:** lh-w1-1 (the paused agent's snapshot) to lh-w1-4 (build, unit, sweep) ALL PASSED; lh-w1-5 on 7926e8d and
  lh-w1-6 on 9e9cda9 (build, unit, ui, ui-de, release) ALL PASSED.
- **Open after world-1:** the castle's buildings, the keep, the curtain wall and the postern (B1, B2, H3, H7) are the
  next steps; until then the cut-away rooms and the two-tower back gate still stand before the new cleft wall. The
  Throat's step B reaches almost the screen's top around the warden statue (its niche needs the height), so the
  three steps read as low, high, full rather than three even steps. The bank by day is the night's black smoke, as
  the wall of night was. The darkness bank's own eye glints (`darknessBankGlow`) lie in two rows.
- **For the later steps (director's notes, 14.11.):** the gorge beyond the gate is 1240 px (gate front 1240 to the
  world's west end at 0; the bank covers 0 to 260 by day and its edge stands near 500 on night 12). The bank and the
  Gloom's fog are drawn from the bank's edge alone (`bankEdgeX`, a value Core can move), nothing of the fog line is
  baked into the gorge's art (the Weltmauer's painted mist is far-plane haze, not the Gloom). Free ground for the four
  beacon sites (REALM.md 5), as fractions of the gorge measured west from the gate: 0.55 (x ~560, between the beacon
  crag and the outer line's trap), 0.69 (x ~380, the dead moor), 0.80 (x ~250, the moor's west end at today's day
  edge of the bank) and 0.91 (x ~110, inside today's bank, freed when the fog line moves out). The moor's backdrops
  (firs, forest, the Weltmauer and its mist, the cloud deck) go on to x 0 without a wall.

#### Step world-1, fix round 1 (the critic's 6 of 10, the director's five corrections)

The critic (`ci-out/director/world-1-rock-fog-critic1.md`) did not pass round lh-w1-6: two blockers (the day bank a
black wall, the cloud deck's ruler-straight underside) and six highs; the director added five corrections (the far
wall's snow as speckle, the fog's mesh at phone size, the slit as autumn leaves, the warm crags in another palette,
the muddy wall behind the gatehouse). Where they differ the director's note wins: step B's height stays.

- **The darkness bank** (`Core/DarknessBankLook.swift`, `FrameBuilder.bankSheetTiles`, `bankEyes`, `bankEndTile`):
  the sheets are painted in a light cool ramp of values and tinted by the hour (`bankTint`, by `Look.nightness`): by
  day a translucent grey-violet veil (A at 0.62 alpha, so the moor shows through it; B darker at 0.84; C the darkest
  at 0.96), at night navy (A with a moonlit crest). Their crests step down the screen: A's near the top, B's at
  about half the screen, C's around the ground line. Each sheet is a face frame and body tiles every 192 px westward
  with complementary dithered feathers, so every pixel is held by one tile (translucent overlapping copies stacked
  into stripes). Pure dark only where the world ends: `bankEnd` on fog B at world 0, drawn black. The eyes
  (`bankEyePairs`): five slots 128 px apart behind the edge, each a pair (`darknessBankGlow`, now 9x3 x 4: near and
  far, open and half shut) that opens at a jittered place and height, blinks, shuts and opens elsewhere; at most four
  on a screen, never in rows; fainter by day; three still with Reduce Motion; with or without the Gloom's fog. The
  old 64 px glow tiles are gone, and so are the Gloom's painted eye tiles of the bank's heart (`gloomFogEyes`): with
  the sheet on the lane lower they stood above it in rows (round lh-w1f1-3); the Gloom's own roaming eyes stay.
- **The cloud deck**: one painted `cloudDeck` (far x −100, y 22) instead of the deck's three clouds: lumpy masses
  shaded from their top contour (a lit rim, broad where the contour faces the light), the front lobes' lit arcs, an
  underside of lobes and rags, and flat wisps of mist feathering 48 px into the wall's haze.
- **The Weltmauer**: no snow in its gullies below the snow line (it read as an icicle curtain); the snow is the caps
  with a clean hem, no patch under 6 px.
- **The cleft wall**: chiselled slabs, fewer and deeper chimneys, two long stepped ledges with snow drifts on the high
  one; the sky only in two wedges (over the gatehouse, over the bailey); inside the walls the high clouds of the
  clouds plane fade with the far plane (they read as autumn leaves in the wedges at dusk), so a wedge shows the
  sky's gradient, the stars and the moon; at night the moon stands low in the second wedge, its top 22 rows under
  the screen's top (`cleftWallA`'s emitter, `SceneLayout.Glow.moon`; the sky's moon fades with `cleftShare`);
  falling water (`cleftWater`, 5x132 x 4 frames at 6 a second, in strands that splash on two ledges and go on a pixel
  aside, `FrameBuilder.cleftWater`, still with Reduce Motion); the shaft at the sun's
  full strength (`look2ShaftShare` 1) with dust motes; a backdrop light behind the gatehouse's top (`throatStepC`).
- **The gate's rock**: shoulders of bedrock (`gateRockL` 108x80 at front − 54, `gateRockR` 64x70 at front + 196) with
  the tower's ashlar stepping into their ledges, cool grey in the shade (the `footing` ramp) and a lit edge two
  pixels deep on the slopes that face the light only.
- **The old walls**: the granite masses of lines 2 and 3 cut to footings of at most 36 rows (the horn on the Gloom's
  side 16) in cool granite; the anchors' toothing stops at that height. The lit edge of all the rock (`rockfield`
  `lit_rim`) lies only on the faces that look up or west, two pixels deep on slopes. The masonry of Lady Oriel's walls is as it was.
- **Fog**: sixteen alpha steps in the hour's fog and the Gloom's strips, the strips' colour in clean clusters.
- **Tests**: `WorldRebuildFixTests` (the bank's tint by the hour and its tiling, the world's end, the eyes, the deck's
  underside from the atlas, the moon in the wedge, the falling water); the B4 test knows the bank's face frames, its
  body tiles' complementary overlap and `bankEnd`; Look2FrameTests and GloomFogTests look for the eyes over a few
  seconds (they open and shut). The sweep adds `w-0600|1000-fog-a|b` and `-fog-rm-a|b` (flicker times 2.5 and 9.5):
  the fog moves between a and b, and stands still with Reduce Motion.
- **The atlas**: 2048 wide, about 1830 rows of 2048 used after this round (1757 before).
- **Rounds:** lh-w1f1-1 on ce5f433 (the bank and the deck; build, unit filters, sweep) ALL PASSED; lh-w1f1-2 on d2483f5
  failed one atlas test (the 3 px wide `cleftWater` placeholder drew nothing; it takes the glow stand-in now);
  lh-w1f1-3 on 9f91703 and lh-w1f1-4 on 12ee227 (build, unit, ui, ui-de, release) ALL PASSED. The drift proof of
  lh-w1f1-4: in the fog band at camera 1000, 49 % of the pixels change between the frames 7 s apart, none with Reduce
  Motion (fires keep their calm Reduce-Motion flicker, as everywhere).
- **Open after fix round 1:** the soot crows and other creatures inside the bank show their glow (an EntityFrames
  matter, not the bank's art); at night the HUD strip covers the screen's top centre, so the moon stands low in its
  wedge to be seen under it; the cleft's ledge drifts and threads of water are the brightest marks on the wall at
  night; step B keeps its height (the director).
#### Step world-1, fix round 2 (the critic's 6.5 of 10, look 2; 15.11.2026)

The critic (`ci-out/director/world-1-rock-fog-critic2.md`) did not pass round lh-w1f1-4: two blockers (the cleft
wall's water threads read as poles and street lamps; its ledges and cracks as ruler lines, a grid of flat polygons)
and six highs. Art notes: ART-look2.md 22.7; ids: SPRITES.md "The rock and the fog".

- **The speed kit** (the director's note of 22:36): `App/SweepRunner.swift`, `UITests/SweepKit.swift`,
  `Tests/SweepPlanTests.swift` (cherry-picked from claude/lh-speed) and `WorldSweepUITests` as `SweepKit` calls (the
  director's patch); the sweep of 59 shots runs in about 5 minutes on the runner.
- **The cleft wall** (`tools/cleftart.py`, `tools/rockfield.py`, all opt-in so the other rock keeps its look): no
  bands; lens-shaped ledges scattered over the face (`pods`, `Massif.spots` with a lean), creased facets on a warped,
  staggered, sheared grid (`Massif.crease`, `facet_seed`, `facet2`) with broken, tapering cracks, a swell on every
  face (`face_relief`), the slit's cold light on whole facets (`Field.fsy`), snow drifts of their own sizes on half the
  high ledges, no lit rim along the screen's top row (`Field.at` lets row 0 go on upward), the lit edge in broken
  pieces (`paint(rim_broken:)`), the wall's end a broken crag ridge (`end_points`), C a value darker in the Throat
  (`cleft_gain`). The ruler check: `WorldRebuildFix2Tests.testTheCleftWallHasNoRulerLines` (no horizontal line over
  52 px, the critic's 240 px, joining aligned pieces as the eye does).
- **The water**: two threads (`THREADS`, `FrameBuilder.cleftThreads` (893, 26) and (1258, 30)), each from a notch
  with a wet stain, in an S over two ledges of its own into spray on a third; `cleftWater` is 14x54 in 12 frames (six
  per thread, `cleftWaterFrames`, frame = thread × 6 + step), at about two thirds of the old white; the ledges stop
  short of its column (`Massif.cuts`).
- **The steps**: the tor (`throatStepB`) climbs in broken crag steps to a shoulder at 70 % of the screen and rises
  only behind the warden statue (its stepped backing must stand in rock); C stands at full height. **The gate
  rocks**: shoulders with three tongues over each tower's outer edge and ashlar on the notches, no outline, no spire.
- **The night bank** (`Core/DarknessBankLook.swift`): the sheets apart in value at night (A 0.62/0.72/1.16 at 0.7
  alpha, B 0.5/0.56/0.9, C 0.3/0.34/0.62), the eyes on one period (`bankEyePeriod` 7 s) with the slots a fifth
  apart (at most one slot shut at a time: two or three pairs on every night frame), above the low roll (near 26 to
  56 rows, far 46 to 128); `bankEnd` occludes the glow inside the world's end (`FrameBuilder.build`).
- **Dusk in the cleft** (`FrameBuilder.cleftDuskShare`, `wedgeMoonShare`): no wedge moon until the night's moon is
  up, no stars, the sky's top 0.7 of the way to the horizon's colour inside the walls at dusk. **The warm graze**
  (`cleftGraze`, `FrameBuilder.cleftGraze`): three frames (west end, middle, east end) of glow in `fireOrange` ×
  torches × 0.8, placed by the world's x behind the castle's own buildings only (world 1490 to 2330; rounds lh-w1f2-4
  showed a span placed by the mid plane's x lying on the open rock of the Throat at dawn and of the cleft's mouth as
  bands of haze with a hard edge). A light inside the world's end fades with the end's own
  cover (the lord's lantern lit the black fog as a warm half disc; the glow occluder alone did not hide it). **The moon** stands 36 rows under the screen's top (`look2SlitMoonTop`; the HUD's stat panel ends at row 33).
- **The Weltmauer and the deck**: arêtes and buttress masses (`cleftart.py ridges`), the slot patch without dotted
  columns, no high clouds in the peak gaps (`SceneLayout.dropsInLook2` drops look 1's sky clouds; look 2's clouds-plane
  deck is gone), `cloudDeck` 720x100 with towers and a horizontal veil.
- **The cobbles** end stone by stone over the tile at world 2432 (`laneCobbleEnd`, `look2CobbleEnd`). **The soot
  flakes** of the brutes are pale and half seen by day (`EntityFrames`, two lines).
- **Tests**: `WorldRebuildFix2Tests` (ruler lines, at most two threads per screen, the moon under the HUD at every
  camera at dusk and night, dusk in the cleft unlike night, the warm graze, two or three eye pairs at every moment,
  the world's end hides the glow); `Look2FrameTests.testTheLaneByRegion` knows `laneCobbleEnd`.
- **The art lock**: several lanes' shells whose command lines name a python art script (a heredoc in the same
  command) match the lock's own check for image jobs, so the lock waits its full 20 minutes for a shell that is only
  waiting for the lock. This round built its last sprites with `careful.sh` in the scratchpad (one at a time, only
  while no python3 or sips process runs and the CPU is under 70 °C).
#### Step world-2: one castle, exteriors only (B1, B2, H3, H7, L6; world plan 2.1, 2.2, 2.4 and 2.8; 15.11.2026)

Louis on build 86: the strip "throne hall, then church, then houses, then a castle again" looks bad and strange. The
castle is now one fortress seen from outside, tied together by its curtain wall, with one keep rising behind it.
Art: `tools/keepart.py` (ART-look2.md section 23); layout: `Core/SceneLayoutCastle.swift`; ids: SPRITES.md "One castle".

- **One castle (B2):** the far castle is gone in every form (`farCastlePane`, `farCastleGlow`, `farCleftGlow`,
  `farCleftGlowBack`, `weltmauerPatch`, `farCastle2/3`, `farCastleBack2/3` with their `Build` and `Glow` states) and
  so are the keep's copies (`keepTop2/3`, `backTop2/3` and their building states); their files lie in
  `tools/retired-art`. The Weltmauer's second slot is filled like the first (`cleftart.py noslot2`), so the valley sees
  a whole wall, and the patch's vertical edge at camera 2400 (world-1's open blocker 4) is gone with it. Look 2 leaves
  out look 1's castle inside the walls (`SceneLayout.look1Castle`: `keepTop`, `castleBackGate`, `hallInterior`, the
  throne, the hearth and the candles, the chapel's and the kitchen's fronts, the courtyard's wall tiles); look 1 keeps
  its scene for the probe.
- **The keep (2.4, H3):** `keepT1`, `keepT2`, `keepT3`, `keepT2Build`, `keepT3Build` (200x175) on the mistBand plane,
  left edge `view / 2 + 0.62 × (1830 − view / 2) − 100` = 1118 (`castleKeepX`), drawn into the near plane's picture
  (`movesWith: .mistBand`: the near plane's light and haze; the mist band's own picture is fog). It enters at the right
  edge as the lord walks through the front gate (its corner tower shows at camera 1360), stands centred over the hall
  door at 1830 and leaves at the left edge at the back gate. A Norman great tower: four bays between pilaster
  buttresses, corner towers that stand forward (quoins, slits, a crown on machicolations; the left one throws its
  shadow on the main block), twin round-headed windows, a hip roof of teal slate behind the parapet and a chimney.
  Tier 1: three storeys, the roof's ridge at y 120, two lit windows; tier 2: a storey more (four windows, three lit), the
  house banner on the ridge (to y 156); tier 3: round bartizans with conical caps on the corner towers and two smaller
  ones behind (four turrets, standing on the machicolations so their finials stay under y 150), the realm's banners in
  the outer bays from tier 2, the great banner to y 170. Every top but the banner stays at or under y 150. The building
  states: tier 2's storey half laid in ragged courses under scaffolding with a crane, the roof off; tier 3's cones as
  timber frames in scaffolds. Its foot stands behind the curtain wall and the forebuilding; a bank of the evening mist
  (`castleMist`, near picture) lies over it at dusk and night. The chimney smokes (`FrameBuilder.castleSmoke`), none
  while tier 2's roof is off. A world change darkens one of its windows (`castle.keep.window.dark`). Its glass glows
  at 0.72 of the world's (`FrameBuilder.keepGlass`: it stands back).
- **Exteriors only (B1, 2.1):** the curtain wall (`curtainA` to `C`, 64x74, wall walk at 64, corbel table, merlons,
  putlog holes; a blocked older arch, a buttress, ivy) runs on the world plane at z −5 from 1474 to 2242 behind every
  castle building, with a wall tower (`curtainTower`) at 1680 and the stair to the wall walk (`curtainStair`) at 1724;
  tier 2 adds timber hoardings (`curtainHoard`, where the curtain shows: 1538, 1602, 2060) and two braziers on the
  wall walk, tier 3 a second tower at 1584 and the realm's banners (`castleBanner`). The bailey's lean-tos are repainted in granite and slate (`barracks`, `smithy`,
  `masterSmithy`, `lodge`, `bigLodge`: same sizes, glass masks and forge fires as `EntityFrames.courtyard` expects).
  The forebuilding (`forebuilding`, 120x96, 2 frames) at 1770 to 1890: a gabled porch with a voussoired round portal,
  the hall door at 1830 (frame 0 shut, frame 1 open), two torches, the house's lantern on a plaque, the lord's chamber
  window in the gable (a mask: its candle). The chapel of the Flame (`chapelTower`, 110x132, frame 0 the bell, frame 1
  the empty belfry after `castle.chapel.bell.missing`) at 1950: a closed tower in the wall, three lancets lit from
  inside, a pyramid cap with the Flame's gold finial, the Flame's brazier at its door. The bakehouse (`bakehouse`,
  100x62) at 2120: a slate-roofed lean-to with the oven's domed hatch glowing all day (`bakeHatchGlow`), a lit window
  at night, a smoking chimney, flour sacks and a peel. The postern (`posternT1` to `T3`, 176x112) at 2230: the curtain's
  end, the passage at 2320 to 2340 under a slate pent roof, lanterns either side, a squat tower with a flower box, ivy
  and a bench; tier 2 roofs the tower and hangs a great lantern over the passage, tier 3 crowns it with machicolations
  and a flag. The cut-away rooms and `CastleRooms`' wall fades are gone: `RoomFades` keeps its shape for the court's
  code with every room shut (nothing of the hall's or the chapel's insides shows in the world: not the hearth's fire and
  pool, the hall's banners, tapestry and Seren's lantern, the throne's mark, the chapel's candles or the procedural
  empty belfry) while `visibility` stays 1, so the court and the audience stand where they stood (in front of the
  forebuilding until the stage lane moves them into the hall stage).
- **The hall door (the promise of the hall):** it opens while the lord stands within 18 px of 1830
  (`CastleRooms.doorOpen`; `CastleRooms.scene` swaps the frame): the open frame shows the hall's warm light
  (`hallDoorGlow`, dim by day, full at dusk and night, a pillar and a banner dark against it), and at dusk and night a
  warm wedge of light lies on the cobbles before it (`hallDoorWedge`, under the ground line, eight smooth steps of
  alpha: light, not art) with a lantern-warm pool; the hall's light is gold to ember, never white, so the lord in the
  doorway stays a figure against it (round lh-w2-2 washed him out); shut, a thin line of light under the door at night (a mask on the sill's gap). The stage lane makes
  1830 the `touch-door-hall` target and the hall stage's entrance; it can drive the frame through `CastleRooms`.
- **The transitions (2.8):** the gate passage's shade (`gateArchFg`, 64x120, frame 0 the gatehouse's gateway, frame 1
  the postern's; foreground, moving with the world plane) frames the lord while he passes through either gate (1337 to
  1383, 2320 to 2340; full inside, fading over 12 px outside, `CastleRooms.archTenths`): night0 in stepped alpha in a
  band along the inside of the opening's jambs and arch and a soft shadow on the floor, nothing over the masonry
  outside (round lh-w2-1 drew a full black arch 180 rows high: it read as a bar across the screen); a torch post inside the front gate puts warm light on the bailey's cobbles; the
  lane changes under the gates, stone by stone (`laneScreeCobble` under the gateway at 1344 to 1408, `laneCobbleEnd`
  under the postern at 2304 to 2368; `SceneLayout.look2CobbleStart`, `look2CobbleEnd`); the picture's grade warms by
  0.07 over 2330 to 2530 (`SceneLayout.valleyWarmth`), the reveal of the valley.
- **Story (L6):** the chapel and the kitchen stay in the story, seen from outside. Tamsin greets the lord at her
  kitchen door (`line.tamsin_first`) and Hesper's Flame burns in this house, not this hall (`line.hesper_first`), in
  English and German (the six other languages at the store pass, the director's note of 19:19). No petition assumes a
  visible interior.
- **World-1's open blockers (critic, look 3):** the warm graze's band at the wall's foot is gone (`cleftGraze` retired):
  the castle's fires warm the cleft wall only as the backdrop pools over the roofs; the curtain wall now hides the
  wall's foot between the buildings; the two wedges of sky are at most 12 % of the screen wide and about a quarter deep,
  their edges broken crag profiles in runs of 2 to 6 px with no lit rim (`cleftart.py wedge_profile`, `slit_rim`), the
  moon 34 rows under the screen's top on the bailey wedge's floor; the far plane's seam at camera 2400 was the
  Weltmauer's own last column (its tail ran to the canvas's edge): the tail comes down as a broken ridge before the
  canvas ends (`cleftart.py wmtail`, last in the recipe).
- **The cleft at night (world-1's high 6):** the cleft's granite (`throatStepC`, `cleftWallA` to `C`) takes its
  albedo at `1 − 0.4 × nightness` (`SceneLayout.look2CleftNightDim`, `FrameBuilder.addProp`), so the moonlit wall no
  longer outshines the castle; by day it is as it was.
- **The atlas:** a second page (two pages of 2048 rows stacked in one texture 2048 wide; `AtlasLayout.pages`, the
  director's note of 19:35).
- **Tests:** `WorldRebuild2Tests` (the keep over the hall door, its corner from the front gate, gone from the back
  gate; one castle at every camera and stage; each tier climbs and tops stay under y 150 but the banner; the curtain
  without gaps behind every building; the chimneys' smoke; the warmth through the postern), `CastleRoomsTests` (no
  room fades; the hall door's frames, light, wedge and line; the gate arch, the chapel's bell and the keep's dark
  window; the closed castle's frame budget), `Look2FrameTests.testTheCastleTiers` and `testTheLaneByRegion`,
  `WorldRebuildFix2Tests.testTheWedgesEdgesAreBrokenCrags` (no even diagonal slope over 16 columns, width and depth)
  and `testTheCastleWarmsTheWallInPoolsNotABand`, the seam check run on to camera 2600 at noon and dusk. The sweep
  (`WorldSweepUITests`) runs to 3900 and adds the castle's set pieces (1360, 1830, 2330 at noon, dusk and night) and
  one shot per stage (`-GWCastle 1, 1b, 2, 2b, 3, 3b`) at the three set pieces at dusk (`t-<stage>-<centre>`).
- **The art tool:** `tools/scenemock/castle_preview.py` composites the castle's pieces at the real framing in about a
  second (flat albedo, by day or a navy night with lit glass), for the art between runner rounds.
- **Rounds** (the director's notes of 18:46 and 19:35: `build unit "ui …"`, English only): lh-w2-1 on 0b73d5f (the
  sweep) ALL PASSED; lh-w2-2 on 07c8ea1 failed one unit check (look 1's castle and court hashes after the lean-tos'
  repaint, recorded again; tier 3's turrets over y 150); lh-w2-3 on 595f02c (the sweep and `Look2UITests`) ALL
  PASSED; lh-w2-4 on ffa4c99, the gate (build, unit, ui WorldSweepUITests and Look2UITests): ALL PASSED.
- **The atlas after its second page:** about 1945 rows of the 4096 hold this lane's sprites (a shelf-packer estimate
  from `SpriteID`'s sizes); with the stage lane's hall stage about 2090, so the join needs the second page and keeps
  about 2000 rows free.
- **Open after world-2:** world-1's highs 1 to 5 and 7 (the water's dotted strands, the snow ledges, the crack under a
  lit ledge in the Throat, the gate rock's lit diagonal and the towers' straight tops, the soot specks by day, the
  steps' climb); the cleft wall's descending end lies behind the first house rather than behind the postern tower
  (no seam: the valley set begins beyond it); the court, its benches, its lectern and Marek's cart stand in front of
  the forebuilding until the stage lane moves them into the hall stage; the camera's set pieces (2.7) are a later
  step.
#### Step world-2, fix round 1 (the critic's 6.5 of 10, look 1; 15.11.2026)

The independent critic did not pass world-2: two blockers (the keep under the gatehouse's bar, the open hall door a
burning doorway) and ten highs. Art: `tools/keepfix.py` (ART-look2.md section 24); layout: `Core/SceneLayoutCastle.swift`,
`Core/CastleRooms.swift`; ids: SPRITES.md "One castle". Rounds by the director's notes of 14.11. 18:46 and 19:35.

- **The keep (blocker 1):** repainted at 260x175 (the old 200-px keep at its cols 60 to 259; `castleKeepX` 1058 =
  `view / 2 + 0.62 × (1830 − view / 2) − 160`, its main block still centred over the hall door, `castleKeepMiddle`). Its
  stone is the mistBand's: the mist greys over the slate darks, a step paler and cooler than the curtain's, on a ramp
  from a dark foot to a lit crown in two values of block; round corner towers modelled as drums; two broad pilasters in
  place of four (no grid); string courses, corbel tables and machicolations with their shadows; deep window reveals; a
  round stair turret and its stair hall on the west. Light of its own: a brazier on the wall walk (`brazierFlame`, its
  light `keepFireGlow` at dusk and night; none among the builders), a 2 px bloom round every lit twin window
  (`keepPaneHalo`; a dark window loses it), a warm rim on its west edges at the golden hour and dusk (`keepRim…`, by
  `FrameBuilder.keepRimShare`: the hour's warmth, gone once the moon is up). Mist at its foot: `keepMist` (320x22, fog A picture,
  moving with the mist band, y 60, the hour's fog colour at 3.4 of the hour's mist; `FrameBuilder.addProp` tints a mist
  bank on a fog plane like the fog's tiles), its billows over the curtain's crenels at dawn, dusk and night (round
  lh-w2f1-1 had it in the near picture, where the night's ambient made it vanish). A fifth pane, the stair hall's small window (53,70,3,7), lights at night at every tier.
- **The hall door (blocker 2):** the open frame shows a view into the lit hall (`hallDoorGlow`, 20x32: flagstones
  receding to a warm far wall, the hearth's glow its brightest point high in the middle, dark jambs, beams, the pillar
  and the banner dark against it). The door's own light is a flat pool at the steps' foot (y −4, squash 2.6), so the
  lord in the doorway stays a dark figure. The wedge (`hallDoorWedge`, 60x19) runs from the threshold over the steps
  and 12 rows out on the cobbles, from the door's 18 px to 2.5 times it, smooth alpha never over 0.5.
- **Tier growth from the front gate (high 1):** `-GWCastle` sets the gate's tier too (`GameStart.applyCastle`,
  App/GameStartCastle.swift: tier 1 the gate, 2 the iron gate, 3 the great gate; a building state the tier before it;
  at night the archers take that gate's posts), and the keep's stair turret stands about 60 px further into the front
  gate's framing (turret at screen x 365 to 395 at camera 1360) with its tiers: crenels, a taller turret with the
  house's flag, a cone.
- **Light pools (high 2):** a scene light can shape its pool (`LightSource.squash`, `SceneLayout.Light.squash`, `color`,
  `intensity`; FrameBuilder hands it to the light pass; the battle's field never reads it). The castle's braziers
  (`castleFireLights`) light a flat pool on their ground, a tall cone up the wall over the flame and a small core, in
  fire-gold, the pool 34 px (was 56); the forebuilding's two torches light one flat band; the postern's lanterns and the
  bakehouse's oven flatter pools.
- **Smoke (high 3):** puffs (`smokePuff`, `Core/CastleSmoke.swift`): seven a chimney, 3 to 5 px, rising 36 rows in 7 s
  with the wind's drift, a pale value; from the dusk each puff also catches the moon (the same sprite in the emissive
  pass, `CastleSmoke.moonGlow`), and over the bakehouse the oven's glow lights them from below over their first 16
  rows (`fireGlow`), so they stand a value over the night's rock (round lh-w2f1-2: as albedo alone they sank into it);
  still with Reduce Motion. The keep's chimney at tiers 2 and 3 stands low on the roof's right slope (its mouth at y
  136), so its smoke rises under the HUD's realm strip, which hid most of it (round lh-w2f1-3).
- **The postern's passage (high 4):** the jambs' faces and the vault in shadow, receding cobbles, a far opening with the
  valley's daylight, lantern-warm at night (`posternFarGlow`).
- **The forebuilding (high 5):** a slate roof sloping back to its ridge, a dormer with a thick coping (the lord's
  chamber), quoins and no pilasters or entablature, three steps and a threshold between low parapets (the door's sill
  at row 7: `castleDoorGap`, `castleDoorGlow`).
- **The curtain's blind arch (high 6):** `curtainB`'s blocked arch is a recess a value darker with the intrados's shadow,
  lit only on its left haunch.
- **The gates' frame (high 7):** `gateArchFg` is the near jamb of each passage (16x116, 2 frames, foreground, moving
  with the world plane, its lit edge at the opening's east edge, `CastleRooms.jambInset`): an opaque pier of 12 px of
  the gate's coursed stone beside the opening, from 6 rows under the lane to the passage's springing, its top cut as the arch
  begins, with a warm lit edge, only while the lord passes (`archTenths`). Round lh-w2f1-1 drew it up over the screen's
  top (a pole across the gatehouse), round lh-w2f1-2 see-through over the opening (a ghost).
- **The building states (high 8):** heavy scaffolding, a crane whose jib stands over the roof line (tier 2), timber
  cones in light wood with two-px rafters (tier 3).
- **The moon (high 10):** inside the walls it stands on the sky, still on the screen (`FrameBuilder.wedgeMoon`: column
  106, 34 rows under the top, under the HUD, clear of the gatehouse's tower), laid into the emissive pass before the mid plane's rock, so the cleft wall
  hides it but where a wedge of sky passes over it (the Throat's wedge, camera about 1600, the keep far to its right);
  its emitter on `cleftWallA` is gone.
- **Story (L6, high 9):** `WorldStoryUITests` shows both rewritten lines in game on the first day (`92-l6-hesper-en`,
  `92-l6-tamsin-en`). German frames: none before the store pass (the director's note of 14.11. 19:35: no German screen
  is looked at before it). The 63 strings of Story.xcstrings that name the hall, the chapel or the kitchen were re-read
  against the outside-only world: they tell of things that happen inside (the goat in the chapel, the candles before
  the altar, the kitchen cat), which the story keeps, and none asks the player to see an interior from the world; the
  hall's are seen in the hall stage. Store-pass item (dated 15.11.2026): `line.hesper_first` and `line.tamsin_first` in
  fr, es, it, pt-BR, ja and zh-Hans still say "hall" and "back in my kitchen".
- **Tests:** `WorldRebuild2FixTests` (the keep's light and its dark window's bloom, the mist over the curtain at night
  and none at noon, the wedge's widths and alpha, the shaped fire pools reaching the light pass, the puffs and their
  stillness under Reduce Motion, the moon at one column at every camera and clear of the keep where it shows,
  `-GWCastle` and the gate); `WorldRebuild2Tests`, `Look2FrameTests.testTheCastleTiers` and `CastleRoomsTests` follow the
  new anchors.
- **Rounds** (the director's notes of 18:46 and 19:35: `build unit "ui …"`, English only; the gate's UI classes
  WorldSweepUITests, Look2UITests and WorldStoryUITests): lh-w2f1-1 on be97c3c (build and UI passed; three unit checks:
  the puff's placeholder, the wedge's faint last row, the glow-band test counting the rock's occluders), lh-w2f1-2 on
  baa209c (one unit check: the keep's mist on fog A before the bank's tiles), lh-w2f1-3 on eb4ecb9 ALL PASSED, lh-w2f1-4
  on 886a717, the gate: ALL PASSED. Its upright sweep: `ci-out/lh-w2f1-4/sweep-upright`; the scenemock previews of the
  keep beside the gatehouse at 1360 and 1830: `ci-out/lh-w2f1-previews`.
- **Open after the fix round:** the lord's own lantern (the lord lane's) still lays its round pool over the chapel's
  brazier when he stands at the chapel's door; the moon shows only where the Throat's wedge passes its column (camera
  about 1570 to 1650), by the nature of a still moon behind a moving slit; world-1's highs 1 to 5 and 7 (the water reads
  as a chain behind the keep, among them); the six other languages of the two story lines (the store pass).
#### Step world-2, fix round 2 (the critic's 7 of 10, look 2; 15.11.2026)

The critic's second look did not pass world-2: two blockers (the gates' foreground piers) and nine highs. The director's
note of 15.11. 07:47 set the order and replaced his list of 07:42. Art: `tools/keepfix.py`, `tools/keepart.py`
(ART-look2.md section 25); layout and picture values: `Core/CastleLook.swift` (new), `Core/SceneLayoutCastle.swift`,
`Core/CastleRooms.swift`, `Core/CastleSmoke.swift`; the light pass's cut: `LightClip`.

- **Both piers are gone (blockers 1 and 2):** no foreground frame stands at either gate. `CastleRooms.scene` places no
  `gateArchFg` (its sprite stays in the atlas, placed nowhere; `archTenths`, `archFade` and `jambInset` are gone).
  Build 3 may bring a frame back only as REVIEW-look-2.md 2.8 describes it, after a scenemock preview.
- **The keep's mist at night (high 1):** `SceneLayout.castleMistTint`: by day and at dusk the hour's fog colour as
  before; as the evening's warmth goes (`castleMistNightShare`: nightness × the cold of the grade) it turns 85 % of the
  way to a hair-cool night grey and loses 72 % of its value, one step over the keep's foot (the shader lifts fog by about
  1.5 at night: the fog colour itself was the brightest cool value on the screen). The bank (`keepMist`, 320x32) rises 4
  to 6 rows over the merlon tops and feathers out over 10 rows, its alpha in sixteenths with a 4x4 ordered dither
  between neighbouring levels only (round lh-w2f2-1 dithered each pixel on or off: a screen-door checker over the keep
  at dusk and over the rock at the bank's ends). The bright blue line under the
  merlons was a clear row in the curtain's sprites (and the postern's wall) over the corbel table, through which the
  mist showed: closed.
- **The keep at noon (high 2):** the sun from the left (the towers' east flanks a step deeper, the west tower's broad
  shadow over the block's first bay), caps and courses at the lit stone's value, the mirror broken (a shuttered window on
  the west tower and in the upper storey, the east tower's second string course, a drainage stain under the chimney).
  The "bare flagpole on the tier-1 stair turret" is no part of the keep: it is the cleft's first water thread
  (`FrameBuilder.cleftThreads`, mid x 893) seen over the turret's merlons at camera 1830; the threads now draw at 60 %
  (`cleftWaterAlpha`), the cleft's shaft of light at 40 % (`look2ShaftShare`, the director's item 7: behind the keep
  it read as a beam from the sky).
- **The hall door by day (high 7):** the open door's view takes a candle-amber share all day (`CastleRooms.doorGlowDay`,
  0.70, 0.46, 0.20) and the rest of `doorGlowColor` with the torches, so the night is as before; the room behind the
  open door is `night0` in the forebuilding's frame 1, so the warm view does not mix with the recess's navy.
- **The buttress (high 6)** is gone from curtainC: darkened with a shadowed flank and a cast shadow it read as a slot
  in the scenemock preview. **The chapel brazier's cone (high 5)** is a torch's light (`castleFireLights`): none at
  noon, full from the dusk.
- **Lit windows (the director's item 6):** `SceneLayout.castleAmberGlass` (the keep, the forebuilding's dormer and
  door line, the chapel, the postern, the bakehouse, the gatehouse's slits) take `castleAmberTint` (0.86, 0.80, 0.70) on
  the glass colour, so the core stays under the clip and reads amber; the chapel's lancets at the keep's share (0.72)
  and their pools at 0.5. The bloom stays.
- **Smoke (high 4):** twelve puffs a chimney that grow from 3 to 7 px (five frames), lean 9 px on a diagonal in still
  air (more with the wind), vary in spacing and alpha and overlap into one plume over 38 rows; still with Reduce Motion.
- **Light washes (high 3), this lane's lights:** a scene light may carry a `LightClip` (world x and heights;
  `FrameBuilder` turns it into the plane's target pixels, `FrameLight.clip`, `LightQuad.clip`; both pool shaders clamp
  their quad to it; the battle's field never reads it). The forebuilding's torch band ends under its eave (row 48) and
  between its corners (`castleForebuildingClip`); the postern's two lanterns are one band under the porch roof
  (`castlePosternClip`, and the tier-2 great lantern with it); the bakehouse hatch's wash is low and flat and cut at the
  lean-to's west jamb (`castleBakehouseClip`). The lord's lantern is the stage lane's.
- **The valley's warmth (high 9):** `SceneLayout.valleyWarmed`: over 2330 to 2530 the ambient's colour × (1.18, 1,
  0.78) and the fog's × (1.2, 0.98, 0.76), by the valley's share times 0.45 + 0.55 × nightness (about half at noon, all
  of it from the dusk), with the grade's warmth (`valleyWarmthGain` 0.12, was 0.07); and the valley lets go of part of
  the night's cold pull (`Look.colorise`, which turns every unlit thing toward one violet band): 45 % while the evening is
  warm, 25 % at night (`SceneLayout.valleyColdCut`, read by `Look2.uniforms`; round lh-w2f2-1 showed the warm ambient
  barely on the lane while the pull was whole). The cleft wall's end is not one
  layout value (cleftWallC's art and the wall's pieces): it goes onto build 3's list.
- **The hall door's one named value (the director's notes of 07:30 and 07:47):** `SceneLayout.castleHallDoorX`
  (1830). `castleForebuildingX` is `castleHallDoorX − 60` (the painted door's middle at the sprite's col 60),
  `CastleRooms.doorOpen` and the keep's place (`castleKeepX`) read it; nothing else holds the door's x as a number. The
  stage lane's `HallDoor.paintedX` reads it at the join.
- **Deferred by the director (07:47):** high 8 (tier 2 from the front gate: the ledger panel leaves the walked world in
  stage-3-interface, then the turret's flag shows), the moon's notch (build 3), German L6 frames (the store pass).
- **Tests:** `CastleRoomsTests.testNoGateFrameTheBellAndTheKeepsWindow` (no gate frame and no castle stone in the
  foreground wherever the lord stands), `WorldRebuild2FixTests` (the puffs grow from the smallest to the largest frame
  and lean in still air), `WorldRebuild2Tests.testThePictureWarmsThroughThePostern` (the valley's ambient and fog a warm
  step at dusk, nothing changed inside the walls), `RendererTests` (`LightQuad`'s stride 48).
- **Rounds** (the director's note of 07:47: one round, build, unit, ui with the lane's classes, English only):
  lh-w2f2-1 on 497d796 ALL PASSED (its sweep showed the mist's on-or-off dither as a checker at dusk and the valley's
  warm step too weak); lh-w2f2-2 on 65c899e, the gate (build, unit, ui WorldSweepUITests, Look2UITests,
  WorldStoryUITests): ALL PASSED. Its upright sweep: `ci-out/lh-w2f2-2/sweep-upright`.
- **Open after fix round 2:** the cleft wall's end still runs about two screens into the town (not one layout value:
  build 3); the lord's own lantern (the stage lane's) still lays a round pool on the walls; the bakehouse hatch's pool
  is flat and cut at the jamb but still an oval on the cobbles; the gatehouse's slits are amber at their rim and pale at
  their 1 px core under the bloom; high 8 and the moon's notch (deferred by the director); world-1's highs 2 to 5 and 7;
  the six other languages of the two story lines (the store pass).
#### Step world-3: the camera, the mediums and the whole-world pass (2.7, M2 to M5, L2 to L4; 15.11.2026)

The director's order of 15.11. 09:19 and 09:23: the whole-world pass's noon items first, then the camera, then M2, M4,
M3, then M5 and the lows. Art: `tools/w3art.py` (ART-look2.md section 26); layout: `Core/SceneLayoutWorld3.swift`,
`Core/CameraFraming.swift`; ids: SPRITES.md "World-3".

- **The camera (2.7):** `CameraFraming` gives the goal and `Camera.frame` follows it (GameModel's three camera calls
  hand it the realm). Walking: 32 px of lead in the walking direction, eased in over 0.5 s (critically damped, so it
  starts and stops without a jolt); it holds on his facing when he stops (a stop never slides the picture back) and a
  jump clears it. Set pieces at the beacon (470), the front gate (1360), the hall door (`castleHallDoorX`, 1830) and
  the back gate (2330): within ±70 px the goal is `anchor + (lord − anchor) × 0.3`, beyond it the set piece lets go
  over 130 px (a smoothstep), so the goal never jumps and the camera never runs faster than about 2.3 times the lord.
  At night in front of the castle (`nightFront`: the hour's night share times the old front fade) and only while
  creatures are on screen (or 30 px left of it), the camera leads 60 px to the left, toward the danger, eased in over
  about a second; it replaces the lead and the set piece. The river end and the bank clamp as before. Reduce Motion:
  the leads and the set pieces are instant. The goal's change per step is fed forward, so a steady walk keeps the lord
  steady on screen (the jitter tests hold). The sweep's stills stand composed: a lord who never walked has no lead, so
  `w-1360`, `w-1830` and `w-2330` frame their buildings as before, and `w-0400`, `w-1400`, `w-1800` and `w-2400` show
  the set piece's pull (camera centres 449, 1372, 1821 and 2351).
- **The whole-world pass, the director's point 1:**
  - a. The cleft wall behind the castle takes one step of haze by day (`SceneLayout.castleCliffHaze`, 0.17 of the mid
    plane's haze inside the walls, none at dusk and night), so the curtain's silhouette reads against it.
  - b. **The lord's lantern box was no LightClip** (the lantern has none): look 2's pools stepped 45 % at the lit
    threshold (`lh_light_level`'s smooth style, so the edge the creatures respect reads), and on walls the ring's flanks
    stood as hard vertical edges (beside the gate, at the bakehouse's corner, at the chapel). Look 2 draws that edge as a
    dithered shoulder over a band now (`Render/Shaders.metal` `lh2_light_level`); the value still drops there.
  - c. The bakehouse oven: no oval. Its pool lights the dome above the ground only (a small round glow at the hatch,
    clip from 3 rows under the ground line), and a wedge of warm light (`bakeHatchWedge`) runs from the sill down the
    dome's foot and 10 rows out on the lane, strongest at the wall's foot (dusk and night).
  - d. Smoke you can see: every puff has a light of its own (`CastleSmoke.glow`): a pale sky light by day, the sky's low
    warm colour in the evening, the moon at night, and the chimney's fire under its lowest three or four puffs (the
    keep's hearth fainter than the bakehouse's oven); a little denser (alpha 0.62).
  - e. The hall door's wash: its cut at the eave's shadow line (row 50), and every cut pool feathers over its last 3
    rows and columns (`lh2_clip_feather`); with the soft lit edge the round outline is gone.
  - f. Fire by day: an open fire's pool (braziers, fire towers, firepots: the gate rock's fires, the oven, the chapel's
    and the castle's braziers) falls to 0.22 at noon and is whole from the dusk (`look2FireDayShare`); the flames show
    all day, the torches still go out.
  - g. The gatehouse's crowns and corbel band at the keep's values: their gaps a slate dark and mid instead of glass
    black (`w3art.py gate_lift`; the slits' glass and the braziers' niches stay).
  - h. The valley one more warm step at dusk (`valleyAmbientWarm` 1.32, 1.02, 0.68; `valleyFogWarm` 1.36, 1, 0.64; the
    cold pull 70 % let go while the evening is warm, 30 % at night).
  - i. The mediums: the chapel's bell bronze in shadow; the tier-3 postern keeps tier 2's roof under its crown and flag;
    the gate slits a step lower (`castleGlassShare` 0.8). The curtain's lone merlon stub at the postern (world 2239) is
    open: it is the curtain's last tile ending over the postern's lower wall, and moving the tiles breaks the merlons'
    rhythm; build 3.
- **M2:** the beacon ruin's crown is a cold iron bowl (the cage read as a handle), and every beacon stage catches the
  moon on its right and upper edges (`beaconRuinRim` to `greatBeaconRim`, by the moon's height).
- **M3:** at most three archers drawn per wall walk or tower, 10 px apart (look 2, `EntityFrames.archersDrawnPerWalk`);
  the others shoot from their posts, implied by their arrows.
- **M4:** the town's back row on the near plane at 70 % value (`townRoofsA` to `D`): overlapping town houses, one
  church spire behind the square, dormers, a few lit panes at night, a smoking chimney per sprite, gardens at their foot.
- **M5:** the warden statue's bowl, its fire seated in it (look 2's emitter at dy 156).
- **L3:** the valley lane's verge (`valleyVerge`, world 2400 to 3680). **L4:** a far-shore lantern and a moored skiff
  (on the near plane at the river end's clamped view: on the mid plane the low mist band at its foot swallowed them). **L2:** in look 2 an unlit creature's ash body is a step lighter (0.3 of its albedo at
  full night, 0.2 before; `EntityFrames.unlitValueLook2`), so far from the fires it reads as a body with its cool rim,
  not as its red glow strip alone.
- **Tests:** `CameraFramingTests` (the lead's ease and direction, the lead held on a stop and cleared by a jump, the
  set pieces' composition, a goal that never jumps, a walk through the front gate, the danger lead only with creatures
  on screen at night at the front, Reduce Motion, the world's ends); `WorldThreeTests` (the oven's wedge, fire by day,
  smoke at every hour, at most three archers per walk, the back row and its night, the beacon's moon, the statue's
  bowl, the verge and the river end, the cliff's haze, the cuts, the creatures' bodies, the gateway's torches, the
  slits). `LookGoldenTests`: look 1's front and castle recorded again from lh-w3-1 (the statue's bowl and the
  gatehouse's crowns are sprites both looks draw); `Look2FrameTests` compares look 2's bodies without the archers.
- **The whole-world pass (rounds lh-w3-1 and lh-w3-2, 130 frames each, upright in `ci-out/lh-w3-<n>/sweep-upright`):
  every frame of the sweep (0 to 3900 at noon, dusk and night, the fog and its Reduce Motion frames, the storm, rain
  and the tier shots) looked at as a player and as an art director. Fixed from what the frames showed:**
  - `w-3000-noon`: the church's spire stood behind the near plane's linden; its tower now stands in the gap between
    the poplars and the linden (near 2197).
  - `w-3000-night`, `w-2600-dusk`: the back row's plaster stood pale over the front houses at night (the near plane's
    night haze), its panes were cream dots: it darkens by 0.45 at night (`look2TownRowNightDim`), its panes are amber
    at 0.6 (`look2TownRowGlass`).
  - `w-3900-dusk`, `w-3800-dusk`: the far shore's lantern stood cut by the screen's edge, and on the mid plane the low
    mist band at its foot swallowed the skiff: both on the near plane, framed between and beside the old bridge's
    stumps, the lantern amber.
  - `w-0400-night`, `w-0600-night`: the beacon tower read as a dark block with a thin outline: the moon now washes its
    face toward the east, one level per painted stone, so its steps lie in the joints (lh-w3-2's wash began with a
    seam, lh-w3-3's dither read as a screen door).
  - `w-0600-night`, `85-look2-storm-night`: a tower's archer stood at the shoulder of the wall's last one: a line's wall
    and tower keep 10 px between their archers.
  - `72-look2-castle-dusk`, `w-1360-night`, `w-1400-night`: the gateway's torches threw round olive-green halos on the
    blue stone: in look 2 a warmer amber, a flatter pool, a little weaker (`look2GateTorches`).
- **Rounds** (the director's notes of 14.11. 18:46 and 19:35 and 15.11. 09:19: `build unit "ui …"` with the lane's
  classes WorldSweepUITests, Look2UITests and WorldStoryUITests; English only, no ui-de, no release): lh-w3-1 on b3fcfa1
  (build and UI passed; unit: look 1's two hashes, the wedge's dy, the look-2 body count), lh-w3-2 on 603f70a ALL
  PASSED, lh-w3-3 on edd0976 ALL PASSED, lh-w3-4 on 57f479f, the gate: ALL PASSED. Its upright sweep:
  `ci-out/lh-w3-4/sweep-upright`.
- **Named, not fixed here:**
  - **The lord's lantern box** (`w-1400-night` x 1045 to 1230, `w-2200-dusk` x 640 to 840, `85`): no `LightClip` (the
    lantern has none). Its pool in the picture is the battle's lantern light (`Core/EntityFrames.swift` `layer`, moved
    onto the painted glass; radius from `Balance`), drawn with `lh_hot`'s gain and capped (`Render/Shaders.metal`
    `lh2_base`), so its middle is a flat bright plateau about 40 px across whose falloff ends within a few pixels;
    where that edge meets the architecture's dark verticals (the gate's jamb, a tower's shadowed flank, the bakehouse's
    corner, the eave) the wall between reads as a lit box. World-3's soft lit edge (`lh2_light_level`) took away the
    ring's own 45 % step; the rest is the lord's light, the stage lane's: proposal for the join, a picture-only spill
    under the lantern (a second, wide, faint pool, e.g. twice the radius at a quarter of the strength, a scene light
    that never reaches the battle), so the light falls off across the wall and onto the next stone.
  - The cleft wall's end runs about 1.5 screens into the town (`w-2330-noon`, `w-2400-noon`; not one layout value:
    build 3). The curtain's merlon stub at the postern (`w-2200-noon`, world 2239; build 3).
  - In the darkness bank the creatures still read mostly as their glow strips (`w-0200-night`, `w-0400-night`): the
    bank's fog covers their bodies; L2's lighter body shows outside it.
  - The back row repeats two of its sprites mirrored (A at near 2567, B at 2687) behind the second field; at 70 %
    value behind the trees it reads as more of the town, a third painting is build 3.
<!-- END world lane: World rebuild (14.11.2026) -->
### The hall stage and touch the world (14.11.2026)

The stage lane of the rebuild after TestFlight build 86 (docs/REVIEW-look-2.md; the world lane rebuilds the outdoor
world in its own branch). Each step has its own heading below.

#### Step stage-1: the great hall as its own stage

The hall is a stage of its own, not a cut-away in the strip (REVIEW-look-2.md 2.6, the hall rows of 2.7, H4, H9,
H10). The files: `Core/HallStage.swift` (the stage, the lord's walk in the hall, the change of stage, the framing),
`Core/HallLayout.swift` (the hall's places, lights and windows in hall px), `Core/HallCourt.swift` (who is in the
hall and where, the audience moved onto the stage, the hall's targets, the hall answering its lord),
`Core/HallFrames.swift` (the hall's frame), `Core/HallWorld.swift` (the world's side: the door target, the old slot
shut, who no longer stands in the world), `App/GameModel+Hall.swift` (the state machine), `UI/HallStageViews.swift`
(the veil, the horn's slip) and the audience card's hall layout in `UI/AudienceCardView.swift`. `CastleRooms.swift`
and `WorldLayout` are not touched: the hall's old world slot (x 1700 to 1960) is passed to `RoomFades` as nowhere
(`HallRules.roomsX`), so its cut-away never opens in the world, and the old places stay unused there.

- **In:** at the hall's door at world x 1830 (the world lane paints the forebuilding and its door there). Until "touch
  the world" the action button offers it within 22 px (`KingTarget.hallDoor`, captions "The great hall" and "Leave
  the hall", a door glyph); `GameModel.enterHall()` is the hook the next step's tap target `touch-door-hall` calls.
  The lord walks to the door (the simulation's travel), the door opens (`door_creak`, 0.22 s), the screen goes
  through dark in 0.35 s (0.16 to black, 0.03 held, 0.16 back; `StageChange`), and at full dark he stands inside at
  hall x 68 while the door shuts behind him (`door_latch`, a soft haptic). Reduce Motion: a cut, no veil.
- **Out:** the inner door (the action button within 20 px of x 68), walking left past hall x 40, or a tap on the
  realm strip, which sends him out by the door and on to that point. The same change in reverse; outside he stands
  at 1830 facing right, the world's camera cut to him. A real drag calls off a walk to a door.
- **The clock runs in the hall:** the realm's king stands at the door (1830) in the simulation, which never reads
  the stage; only the audience (and the cards) stop it. The drag walks the lord in the hall (walk 36, run 80 px/s).
- **The horn:** inside, the waiting go home by the door (whoever leaves the hall's list walks out to x 68 and fades;
  whoever joins later walks in from it) and a slip at the door says "The horn" until he goes out or the day comes.
  The lord stays where he is.
- **Launch:** `-GWStage world|hall` and `-GWHallX <x>`. Without `-GWStage` a lord standing in the hall's old slot
  starts inside before his throne (`HallLayout.firstMorningX`, 412, clear of Odile): a new realm's first morning, the tests' old
  `-GWCameraX 1824` and a dawn at the hall's door; never under the reference bot. `-GWScreen petition` opens its
  audience in the hall; `-GWPetition <id>` puts another petition there (the longest letters).
- **World-scene's value** carries `stage:world|hall` and inside `hx:<x>` (the lord's hall x); `kx:` stays the
  simulation's.
- **Sound:** `GameModel.soundPlace` reports `.hall` on the stage (`SoundPlace.of(stage:worldX:)`; outside the old
  slot is the bailey). Once the door opens the place is already the stage he goes to, so through the dark the wind
  falls away and the hall's fire and room tone come up over the director's 1.2 s crossfade: the ear arrives before
  the eye. `tools/soundsynth.py door_creak door_latch` makes the two files (pure Python, 79 KB together).
- **The court lives in the hall** (`HallCourt.specs`, SPRITES.md "The great hall as a stage"): Odile at x 397
  between the throne and the nave, turning now and then to the throne (she keeps 12 px from her lectern at 385);
  Mother Hesper at the hearth (497, 485); Pip at the foot of the steps while his round is in the hall; the Stranger
  in the far corner once let in; two guards at the door facing it and by day a third under the arms; today's
  townsfolk on the benches' six seats (first in line nearest the throne, seated where their body has a seated strip),
  guests and the rest standing on the wall line. Court members who petition from outside come in from the door's
  side when called and go out by the door afterwards.
- **The camera:** walking, one scale step above the world's (s 7 on the iPhone 17 Pro: 375 x 172, bottom-anchored,
  camera x 0 to 225, following the lord); the audience, s 8 with the left edge at hall x 232 (the throne at 56 % of
  the width) and the top at row 50, the move eased over 0.6 s through fractional scales (`FrameDesc.zoom`, read by
  the composite; Reduce Motion: a cut). The targets keep the walking size while the move runs.
- **The audience card in the hall (H4):** the letter in the upper left (portrait, name and role, Odile's counsel
  button, the request), from the safe area's left edge to
  Odile's left edge (`HallLayout.letterEdgeX`, 386: 344 pt on the 17 Pro) and from the top to above the
  petitioner's head (the longest German request, the bard's 304 characters, fits in six lines without scrolling);
  Odile's line, once read, on a teal slip of its own at the top between the letter and the ledger, over where she
  stands beside the throne; the choices and Leave as plaques along the floor band below the walk line (a smaller hand
  and two lines at most, so they stay under the petitioner's feet); after a choice what changed and the way on along
  the floor. The letter scrolls only if a request ever outgrows it. The pause seal
  rests during the hall's audience (the letter lies where it sits; Leave ends the audience). The gate's audience in
  the world keeps the old card.
- **The hall big and alive (H9, H10):** the windows show the hour's sky with its stars and the Weltmauer on the far
  plane at parallax 0.3; by day soft shafts fall from the two tall windows (in the morning down to the left, in the
  afternoon down to the right, none round noon, clouds and rain take them) with dust drifting in them (frozen under
  Reduce Motion) and a pool of light where they land; the upper wall fades into the roof's dark (an interior ramp on
  the ambient, `InteriorLight`: the hall's ambient is 58 % of the open air's by day, 82 % at night, warmed by the
  stone; at night 45 % of it is a dim warm fill of the hearth and candles and the blue pull is 0.6; the floor gets
  no sky lift and no moon); plaster and wash patches over the brick (`hallWash`); the near arcade's pillars at
  parallax 1.25 in front, lit only faintly by what stands behind them, fading to 32 % while the lord stands behind
  one (`HallFrames.pillarSeen`), so they pass over him as he walks and never hide him where he stops. Light is the realm's state: the hearth's fire and its glow follow the
  hearth's strength (the small fire below a third), with a long warm pool on the flags; a bench's candle stands burn
  while someone waits on it; the chandeliers burn by day; the door's torches from the dusk; the one who has the word
  stands in a warm pool.
- **The hall answers its lord:** for 1.4 s after he came in by the door the two door guards stand straight (no
  breath, a pixel taller); for 2.6 s the waiting turn their heads to him; whom he passes within 20 px looks at him,
  and a seated petitioner he passes within 9 px bows his head (the nod frame).
- **From the director's notes (14.11.):** the hearth shows three strengths by the hearth's value (docs/REALM.md:
  bright from two thirds, low from one third, embers below; `HallFrames.hearthState`), and flares when the
  lamplighter's pole takes fire (`GameModel.flareHearth()`, 0.6 brighter, gone in 0.8 s). A noble guest never sits on
  the benches: the first noble waiting stands apart between the window bays (`HallLayout.nobleSpot` 236, a footman's
  anchor at 249). Anchors kept for later builds, nothing drawn there yet: the tax collector's post by the door (124),
  the stair to the lord's chamber (foot at 16, the door on the gallery at 30, row 80, a candle in the window behind
  the gallery at 67, row 72), the table by the hearth (eight places on the dais, 444 to 528) and the lamplighter's
  place at the hearth (518); the walk line from the hearth to the door carries no furniture. Not done here: the
  hall's three states of furnishing (the painted hall is the rich one), the chamber's door and the table drawn, the
  hearth taking a touch (stage-2's touch system); the tax lectern still opens the old tax card through the action
  button until the town lane's taxes on foot and the ledger replace it.
- **The interface art kit** of `claude/lh-hudart` (director's note 14.11. 20:00) is taken as it is: its ten strips in
  `Resources/Art/hud*.png` and `tools/hudart.py` (cherry-picked 479a4c9 and 0b687b5); nothing wires them yet (no
  `SpriteID`, so the atlas does not take them): stage-3-interface does.
- **Targets in the hall** (`HallTargets`, until touch the world): the inner door; while petitioners wait the
  throne anywhere on the floor before and on the dais (326 to 470, the lectern beside it included: the lectern
  becomes the ledger's furniture when the town lane's taxes on foot land); else the nearest of throne, lectern and
  the court in talking reach.
- **Tests:** `HallStageTests` (the change's timing and the cut, in and out by the door and past it, the strip's walk
  out and on, the framings at s 7 and s 8, the eased move, the letter's room, the court's places, the world's door
  target, the hall's targets, the frame and its light, the hearth's pool, the horn, the hall answering its lord, the
  sound's place, the arguments); `AudienceFlowTests`, `ScreenFlowTests` and `LordTests` hold their audiences in the
  hall. UI: `HallUITests` (130 to 142: the door, in, the walk, the audience, the counsel, the reaction, the stills by
  day, afternoon, dusk and night, the longest German letter, the horn, Reduce Motion); `AudienceUITests` and
  `FirstDayUITests` reach the hall by its door.
- **Rounds** (the gate by the director's note of 14.11. 18:46): `lh-s1-1` build failed (the private driver changed
  directly); `lh-s1-2` one unit test (the strip tap from inside); `lh-s1-3`, `lh-s1-4` and `lh-s1-5` full rounds ALL
  PASSED (61e871a, 01a6f3c, 1f87a09); `lh-s1-6` full on c3ba12b failed: `AudienceFlowTests.testThePetitionSample`
  (the first standing guest's walk from the door bay took 2 s, the test waits 1.8 s: fixed), `FirstDayUITests` (a
  drag that stopped beside the lectern opened the tax card: the throne owns the dais while people wait) and
  `LordUITests`' typing check (a typed "!" kept; code this step did not touch, green before and after); `lh-s1-7`
  build, unit, ui Hall, Audience and Polish ALL PASSED on 1a29a3b; **`lh-s1-8` build, unit, ui Hall, FirstDay,
  Audience and Lord ALL PASSED on d5b03d4** (the gate).

#### Step stage-1, fix round 1: after the art director's first look

The independent art director scored the step 6 of 10 (`ci-out/director/stage-1-hall-critic1.md`: three blockers, nine
highs); the director's note of 14.11. 22:17 added corrections 1 to 3 (the near pillar, the lord on the throne, the
lantern over the teal cloth). What changed (new logic in `Core/HallLight.swift`):

- **No void at the ends:** both framings and the eased move between them keep the camera inside the painted hall
  (`HallLayout.shownLeft` 10 to `shownRight` 590, `HallFraming.clamped`; a view wider than that is centred). The
  hearth's pool on the flags falls off before the end wall (centre 498, radius 90).
- **The wash** is redrawn as ragged limewash stains (tools/hallstage.py `wash`): a noisy outline with a dithered
  feather, each pixel one step warmer than the stone under it, so the ashlar reads through; the two patches beside the
  throne's sconce moved up to the dais end above the arms and to the gallery's wall.
- **One near pillar** (`hallPillarNear` redrawn 30 px wide, at hall x 150): never two in the walking framing, none in
  the audience. The composite gives it 0.8 of the hall's ambient, a rim of light on its edges (the window's cool light
  by day, the torches' warm and the moon's cool light at night) and, instead of the alpha fade, a window in a 4x4
  ordered dither round the lord's body (half sizes 12 x 24, open inside 55 %) that opens only while he stands behind
  the shaft and grows as he moves behind it (`HallLight.holeOpening`; `InteriorLight.pillarHole`, `rimLeft`,
  `rimRight`, `pillarAmbient`; `Look2Uniforms.hallHole`, `hallRimL`, `hallRimR`).
- **Soft light:** inside the hall the renderer draws every pool with light style 3, a smooth falloff to nothing
  without the lit edge's step (no hard discs, no bars). The bench stands' candles are round 20 px pools just below
  their flames (centred there, the two stands' light ran along the wainscot's pale cap as one bar) and burn whenever
  anyone waits at a bench (`HallCourt.occupiedBenches`: on it or within 40 px). On cool cloth (the teal banners, the
  cloth of estate) the composite lets warm light warm the luminance instead of cutting the blue, so no candle or
  lantern turns the teal olive green.
- **The hearth by day** shrinks by 35 % and loses half its strength in full daylight (`HallLight.hearthDay…`); at
  night it is as before.
- **The night:** the moon through the windows (pale `hallShaft`s, a cool pool where they land, a cool fill round each
  window) and the door torches' pool on the flags.
- **The throne:** the lantern indoors is a warm white (1.0, 0.82, 0.58) at 0.25 + 0.55 × night of its strength (at the
  open air's its centre burned white on the wainscot), low and flat at his lap on the throne, so the
  cloth of estate keeps its blue; the lectern's candle burns and keys the lord in his chair (a low, flat pool of 28 px
  on the chair's seat, so it does not climb the cloth behind him).
- **The banners:** the realm's banner hangs at every second place (137, 253, 368); at the other two a wall sconce burns
  (`HallLayout.wallSconces`, painted into `greatHall`), out while a house's banner covers its place.
- **The waiting:** the bench by the door fills first (seats 192, 184, 176, then 308, 300, 292), so the waiting are
  clear of the action button when the lord comes in and the greeting shows; who cannot sit (no seated strip: the
  soldier, the merchant, the townswoman, the builder) stands beside a bench (`HallLayout.besideBenches` 218, then 262
  by the second bench) instead of before an empty seat, never between the door and the first bench where the near
  pillar sweeps the wall; the first standing guest waits at 272; the petitioner called hurries at 110 px/s.
- **The plaques:** one height per row (the tallest's), words top-aligned; Odile's seal sits on the plaque's corner
  and never takes the words' width.
- **Proof screenshots** (`HallUITests.proofs`): 131a the dark half way (`-GWStageSlow 10`), 131b the greeting and 131c
  the room settled again, 143 out past the door standing at 1830, 144a and 144b the hearth low and as embers at night
  (`-GWHearth`), 145 Reduce Motion (a cut, the dust held still).
- **New launch arguments:** `-GWHearth <0…1>` (the hearth's strength at the start) and `-GWStageSlow <factor>` (the
  change of stage runs that many times slower).
- **Tests:** `HallStageTests` (the painted range, the pillar's window and rims, the light after the look, who cannot
  sit, the arguments); `RendererTests` (the look-2 uniforms' stride, 336); `LordTests` (the seated farmer among the
  stage's figures: the bench by the door is out of the throne's framing).
- **Rounds** (the gate by the director's notes of 14.11. 18:46 and 19:35, one round, English): `lh-s1f1-1` (build,
  the hall's unit classes, ui Hall) failed one assertion (the night frame now has the moon's shafts); `lh-s1f1-2`
  (build, unit, ui Hall, FirstDay, Audience, Lord) failed two unit tests (the uniforms' stride, the farmer out of
  frame), the UI classes passed; **`lh-s1f1-3` build, unit, ui Hall, FirstDay, Audience and Lord ALL PASSED on
  704cc29.** The atlas gains no rows (the narrower pillar shares the hall's shelf; `hallWash` keeps its size).

#### Step stage-1, fix round 2: after the art director's second look

The independent art director scored fix round 1 7 of 10 (`ci-out/director/stage-1-hall-critic2.md`: one blocker, eight
highs). What changed (new values in `Core/HallLight.swift` and `HallCourt`):

- **The lantern (the blocker):** walking, the lord's lantern indoors is one round pool on its head (radius 44,
  `HallLight.lanternRadius`) over the stone, the wainscot and the floor alike, and an ellipse 42 x 8 px on the carpet
  under it (`lanternFloor`). Round 1's lit box came from two things: its pool was flattened (squash 1.25, so it
  spanned the wainscot only) and so strong that the light's cap held it flat over the whole panel, dropping at the cap
  rail. Now it reaches the cap only in a small heart round the lantern (0.18 + 0.37 × night) and falls off evenly; inside
  the hall the lantern's pools keep their warm white to the rim (the renderer's ember rim read red on the carpet). On
  the throne the low pool at his lap is as before.
- **Teal cloth swallows warm light** (the composite, inside only): on cool albedo (blue minus red over 0.10) warm light
  becomes a dim neutral touch (0.3) and displaces little of the ambient, so the lantern leaves no cyan halo round the
  lord's head on the cloth of estate (round 1 brightened its luminance) and no olive green (before round 1); grey stone
  takes warm light whole.
- **The near pillar:** `hallPillarNear` repainted evenly lit (both edges darker, the drums' joints in `stoneDark` with
  a lit lip, no baked key); the composite lays a soft band 4 px wide on its key side (`InteriorLight.pillarBand`,
  `hallRimR.a`: the tall window's light on the right by day, the door torches' on the left from the dusk, strength 2.6),
  keeps the thin rims, darkens the whole pier toward the roof (to 0.6) and gives it 0.9 of the hall's ambient. It stays
  at hall x 150: at the entry it already stands at 34 % of the screen (a third); the door bay is its own bay under the
  gallery, so the pier marks it.
- **Everyone waiting sits:** every townsperson takes a seat (six, 11 px apart now), with a seated strip where the body
  has one, otherwise the standing body 5 px lower (`HallCourt.sunk`) with its rows below the wall line cut off
  (`ActorInstance.cropBottom`); the stage draws both benches again as actors after the wall line and before the walk
  line, so the bench's seat and legs stand over who sits. Beyond six, one stands at the first bench's end (218), the
  rest by the door bay.
- **The hall answers its lord:** the door's guards come to attention when he comes in (0.12 to 2.2 s: 2 px taller,
  still, and a glint on the spear's head for 0.8 s); the waiting rise half way (3 px) and turn to him for 3 s; whom he
  passes within 24 px looks at him (Odile and Pip too), the nearest bows (the seated strip's nod, or a pixel lower).
  Proof: `132b-hall-pass-bench` (the lord at the first bench's end: two turn to him, the third still looks to the
  throne).
- **The dais** is a raised platform at the back (`greatHall` repainted): its top from the back wall to the walk line,
  its 9 px front face standing on the walk line, the steps' treads and risers likewise; below the walk line the nave's
  flags run on under its whole length (the treads painted down to the hall's bottom made a seam to the screen's edge).
  The runner ends at the foot of the steps; a rug lies on the dais before the throne.
- **The audience framing:** the day's shafts from windows under the letter fade with the move (`HallLight.shaftShare`;
  their beams seemed to fall out of the letter's lower edge); their pools on the floor stay.
- **The first morning at the throne:** on the hall stage the throne's caption ("Audience (n)") stands left of the
  button, low over the floor, instead of over the hearth's fire. The camera cannot move the fire out from under the
  button: it stands at the hall's end wall there (left 215.4 of 590 − 374.6); 40 px further would show the void past
  the hall again (round 1's blocker). Stage-2 removes the button.
- **German on the floor band** (no German round, by the director's note of 14.11. 19:35): the plaques' words keep their
  two lines at most, and now their cost line and their reason keep to one line each (shrinking to 0.75), so the row
  cannot grow toward the petitioner's feet.
- **Smaller notes:** the lectern's key higher and nearer the chair (on the lord's face; teal cloth no longer takes a
  halo from it); the chandeliers 10 px lower (out from behind the realm strip); the hearth's wall light follows its
  strength more closely (0.2 + 0.8 × strength), so over embers the firebox's frame dims.
- **Tests:** `HallStageTests` (everyone sits, the benches over them, the crop; the lantern's two pools, the pillar's
  band by day and night, the shafts under the letter; the guards at attention, the glint, the waiting half risen);
  `HallRenderTests` renders the hall's stills off screen (`hall-r-*` in the unit step's results: the lantern at night,
  the pillar by day and at night, the benches, the greeting and the room settled, the passing look, the first morning
  at the throne, the hearth at night over the dais, the audience framing), so a look round needs no simulator.
- **Rounds** (the gate by the director's notes, one round, English): `lh-s1f2-1` to `lh-s1f2-3` (build and the hall's
  unit classes, the off-screen renders judged after each: the lantern too faint after the second, right after the
  third) ALL PASSED; **`lh-s1f2-4` build, unit, ui Hall, FirstDay, Audience and Lord ALL PASSED on bb0c4a0.** No sprite
  changed its size, so the atlas gains no rows; no new player-facing strings.

#### Step stage-2: touch the world

The action button and its caption are gone (B3); the lord goes where the finger points. The rules, as built, are the
section "Controls: touch the world" above, which replaces the old "Controls" and "Controls 2". The files:
`Core/TouchWorld.swift` (a thing, its touch area of at least 44 x 44 pt, the nearer centre, the tie by rank, a person
before a wall, a tap of 10 pt or less, at most four marks, the night's tint, the pace), `Core/TouchThings.swift` (what
offers something in the world and in the hall now), `Core/TouchMarks.swift` (how a stage lies on the screen; the marks
as unlit actors and their pools), `Core/LanternRaise.swift` (raise the lantern, the flame that shows the danger),
`App/GameModel+Touch.swift` (the finger, the errands, the slips, the elements), `UI/TouchLayer.swift` (the touch layer
over the whole screen, the elements, the slip above the thing, the first slip). Small marked hooks in shared files:
`GameModel` (the state block, the step, the frame, `perform(_:)` split out of `performAction`, the scene value),
`SimDriver.travel(to:speed:)`, `HallWalker.walk(to:speed:)`, `KingTarget.bench`, `SpriteID.tapDoor`, `FeedbackCue
.touched` and `.lanternRaised`, `RealmKing.lanternSince`/`.raises` and `Creature.flinch`/`.flinchRaise` (optional,
older saves load), one line each in `Sim.stepKing` and `Battle` (the lantern's radius, the flinch), `EntityFrames` (the
plot markers no longer drawn, M6).

- **B3, the button:** `ActionArea` and the game's action button are deleted (the light probe keeps its brazier
  button as `probe-action`); the whole screen takes the finger (`TouchLayer` instead of the walk pad on the left 45 %).
  `GameModel.target` and `performAction()` stay as the model's "what is in reach" for the unit tests; an errand that
  arrives calls `perform(_:)` with the thing's own act.
- **M6:** the four blue banner posts (the plot markers) are gone; an open plot shows `tapBuild` only while its card
  offers something the treasury can pay, at most two sites marked at once.
- **M9:** the bubble stands over the speaker's head (300 pt at most, its tail on him) and names him; the separate name
  slip went with the button. A bench's first in line speaks his line from his seat (`TalkBubble.nameText`).
- **M11:** at night the marks draw at three quarters of their value, warmed; at most four in view, the nearest first; a
  member of the court or a guest carries a mark only while he has something new to say (`CourtTalk.marks`: a word
  about today's petitions, not yet heard today); the rest still answer a touch.
- **M13:** the elements, labels, identifiers, order and the scene's custom actions as listed in "Controls"; the
  scene's value adds `lx:` and `errand:`.
- **M14:** German: the slips' longest lines ("Wiederaufbau: Großes Leuchtfeuer", "Den großen Saal verlassen", "Die
  Mauer ausbessern" with its coin) are one line under 260 pt; build 2 is English only by the director's note of
  14.11. 19:35, so no German round ran.
- **The director's ideas for stage-2:** the lord hurries (far ways, the night), raise the lantern (a hold on the lord
  at night), the flame shows the danger (picture only). The tap on the lord stays free for stage-3's lantern moment.
- **The stage-1 critic's four highs:** the near pillar's key band 6 px wide, soft both ways, on the pier's lower part
  only (a height ramp; the rims too); the inner door stands open for 0.45 s after he came in and while he goes out
  (the leaf, the bailey's dark, a sliver of cold light; no new sprite; proof `131d-hall-door-open` with the change ten
  times slower); Odile's counsel on its teal slip just under the letter at the left, short of the petitioner (at the
  top it hid the canopy; under the request the long letters cut it off, round lh-s2-2's 134; in the letter's head it
  pushed the name out, round lh-s2-5's 134); while an audience runs whoever stands within 28 px of the petitioner's place steps
  out toward the nave (`HallCourt.clearingTheFloor`; Pip at the foot of the steps was the one).
- **Strings** (English and German, the director's note of 14.11. 19:19): Story.xcstrings `touch.first`,
  `touch.bench.wait|sit|far`; Localizable "Sit on the throne", "Repair the wall", "%lld gold", the two arrivals, "Walk
  left", "Walk right", "Raise the lantern".
- **Tests:** `TouchWorldTests` (the areas at every scale, the nearer centre, the tie, a person before a wall, a bench as
  one target, a tap, the marks, the night's tint, the pace, the floor cleared, what the world offers by day and at
  night, and the errands through the model: a site's card on arrival, the ground and a drag, a second tap runs, the
  hall's door both ways, the bench and the throne, the scene value, the marks and the elements);
  `LanternRaiseTests` (the timing, only at night and when ready, the farther light, the flinch once per raise, the
  danger, the save, the reference bot never raises it); `EntityFramesTests.testNoPlotMarkersStand`. UI: every flow
  that used the action button touches the world (`FirstDayUITests`, `AudienceUITests`, `HallUITests`,
  `Look2UITests`, `PolishUITests`, `LordUITests`); `TouchUITests` 150 to 157 (`150-touch-front`, `151-touch-front-walk`,
  `152-touch-front-night`, `153-touch-wall-price`, `154-touch-hall`, `155-touch-hall-bench`, `156-touch-hall-walk`,
  `157-touch-first`, `158-touch-lantern-raised`); `HallUITests` adds `131d-hall-door-open`.
- **The atlas:** 2048 x 1925 of 2048 rows, measured (`TouchWorldTests.testTheAtlasStillFitsOnePage`, the attachment
  `atlas-rows`); `tapDoor` is its only new sprite.
- **Rounds** (the gate by the director's notes of 14.11. 18:46 and 19:35, English only): `lh-s2-1` build and unit
  passed, `TouchUITests` failed (the throne out of view after the walk to the bench); `lh-s2-2` build, unit and
  `HallUITests` passed, `TouchUITests` failed the same way; `lh-s2-3` (b3c458e) build, unit and five of seven UI
  classes passed (Hall, Audience, Look2, Polish, Lord), `FirstDayUITests` and `TouchUITests` failed in the tests
  themselves (the throne out of view from the door; an element read while the camera followed the lord lay off by the
  tap); `lh-s2-4` build, unit, ui Touch and FirstDay ALL PASSED on 7f0069c; **`lh-s2-5` build, unit and ui Touch,
  Hall, FirstDay, Audience, Look2, Polish and Lord ALL PASSED on 8f7cdb0** (the gate; the door's mark rests at the
  door); after its sweep Odile's counsel moved under the letter: `lh-s2-6` build, ui Hall, Audience and Lord ALL
  PASSED on 6c34ef0 (the slip stood on the plaques), `lh-s2-7` the same on f54ab50 (the letter keeps its own
  height).

#### Step stage-2, fix round 1: after the art director's first look

The critic's look 1 (6.5 of 10, `ci-out/director/stage-2-touch-critic1.md`): two blockers, nine highs. The new pure
parts are in `Core/TouchCraft.swift` (`HallDoor`, the band, the edges, the groups, `TouchFooting`, `TouchRims`,
`LanternFlare`), the model's side in `App/GameModel+Touch.swift`, the tests in `Tests/TouchCraftTests.swift`. Small
marked hooks in shared files: `EmissiveInstance.Kind.rim` (FrameDesc), its quad in `Renderer` and its mode in
`Shaders.metal`, `EntityGlow.kind` and its grown quad (EntityFrames), three launch arguments (DebugArgs, GameStart),
`door:` in the scene's value (GameModel).

- **Blocker 1, the hall door:** the target `touch-door-hall`, its mark, his standing place and where he comes out
  stood at a fixed x 1830, over the hall front's middle window; the painted door is at 1747. `HallLayout.worldDoorX`
  now reads the facade's own anchor (`HallDoor.paintedX`: the middle of the line of light under its door,
  `CastleRooms.hallFrontMasks`), so all four follow the door. **At the join** the world lane's forebuilding brings
  its door at `SceneLayout.castleHallDoorX` (1830): `HallDoor.paintedX` then reads that (one line), and the join's
  gate is 130 and 143 showing the mark over the door and the lord in the doorway. The tests stand at the door
  wherever it is (`-GWCameraX hallDoor`, `hallDoor+80`), and 143 checks `kx` against the scene's `door:`.
- **Blocker 2, the night in pictures:** the night of seed 2 had no damaged wall. `-GWDamage <plot>` (45 % of its
  strength) and `-GWSnuff <plot>` (a cold brazier) force it: night 3 with the gate damaged and the brazier before it
  cold beside its lit twin: `152-touch-front-night` (the light's and the repair's marks at three quarters, warm, next
  to real fire), `153c-touch-light` (the slip over the cold brazier while he hurries), `153-touch-wall-price` (he waits
  at the gate under its price), `153b-touch-wall-paid` (the second touch paid), `153a-touch-wall-short` (no gold: the
  price red).
- **High 1, marks without a ground:** an empty plot shows its **footing** while its mark shows: two stakes 4 px high
  at its ends, a cord between their tops sagging a pixel, a chalk line on the lane (lit, part of the world, behind
  every figure; its width is what its first building would cover, 8 to 24 px each way). **One height band:** over a
  building, a wall, a brazier or the barracks the mark's tip stands at most 30 px over the walk line (its top at 48),
  at the building's door, never at its crown; the building still answers a touch up to its top. People keep their
  mark over the head (33), the door over its arch (43).
- **High 2, the rim:** the gold rim on the marked thing, as SPRITES.md asks: one pixel outside the sprite's outline at
  its left, right and top, unlit, added in the emissive pass (`EmissiveInstance.Kind.rim`, the shader reads the
  sprite's alpha), at 0.62 of `gold` and 1.15 while the finger is down, at night warmed and at three quarters like the
  marks. In the world on the entity props of a marked plot, wall, brazier or the barracks and round a marked person;
  in the hall round a person with a word, the bench whose first in line is marked, and the throne. The door has
  none (it is part of the facade). The marks' corners and outline are the parchment tag's look: not touched, by the
  director's note of 15.11. 01:09 (the night glass reskin comes in one place).
- **High 3, cut marks:** a mark shows only while its thing's centre lies 30 px inside the view (the errand's too).
- **High 4, missing pictures:** `159-touch-pressed` (`-GWPressed nearest` holds the nearest mark pressed: a finger
  held down cannot be photographed by the UI test), `156-touch-hall-walk` taken again in its own launch (from the
  second bench, 0.7 s after the touch, before the card; then the test waits the card's fade out).
- **High 5, the barracks:** marked only while a recruit can be paid (`RecruitCard`); its slip names the cheapest.
- **High 6, "Next petitioner":** an inked plaque with teal words and rule (`TealPlaqueButtonStyle`) instead of the
  wax red in the old button's corner.
- **High 7, raise the lantern:** he lifts the pole high (the strip's command frames 8 and 9, held while it is
  raised and he stands; the light on the lifted glass), the light at 2.2 times falling to 1.6, a flare on the glass
  and a one-pixel ring of warm light at the growing light's edge for the first 0.45 s (none with Reduce Motion);
  `158-touch-lantern-raised` right after the lift, `158b-touch-lantern-held` a second later. The street lanterns no
  longer brighten with his (only the lantern on his glass does).
- **High 8, the slip and the pair of hammers:** a site's slip names its cheapest price with the coin (none for a
  gift); of sites (and cold braziers) closer than 40 px only the nearest carries a mark.
- **High 9, German:** answered by the director's note of 14.11. 19:35 (build 2 is English only; no German round).
- **After the first sweep (lh-s2f1-1):** the touched site's mark came back beside its group's (151: two hammers
  again): the errand's thing now takes its group's place (`TouchRules.withErrand`); an empty site's mark hangs just
  over its cord (tip 7 px); the gate's rim follows the gate as drawn (`rimX`); a wall carries no mark while its repair
  cools down (after the second touch paid, the mark stayed and read as unpaid); the ring became a soft front of three
  pixels above the walk line (a thin circle through the lane read as a radius gizmo). **After the gate's sweep
  (lh-s2f1-2):** a building's rim is a part of its prop (`EmissivePart.rim`, drawn by `FrameBuilder` as the prop is),
  so what stands in front of it hides it (58: the barracks' rim ran over Marek's cart).
- **The atlas:** 2048 x 1925 of 2048 rows, unchanged (no sprite drawn).
- **Rounds** (the gate by the director's notes of 14.11. 18:46 and 19:35, English only): `lh-s2f1-1` (ea8928d) build,
  the touch, hall, audience, entity and lantern unit classes and ui Hall passed, ui Touch failed in the test (the
  cold brazier's slip was gone before the test looked: he stood 55 px from it); **`lh-s2f1-2` (ce5c47c) build, unit
  and ui Touch, Hall, FirstDay, Audience, Look2, Polish and Lord ALL PASSED**; **`lh-s2f1-3` (5eae2f3, the rim as a
  part of its prop) the same, ALL PASSED** (the gate; sweep `ci-out/lh-s2f1-3-upright`).
- **Still open:** the true arm-up pose (the lantern over his head) needs two new frames for each form and its glow
  strip (art, atlas rows): the command frames lift the glass two rows only, so the raise reads through its light,
  flare and ring more than through the pose. The marks' parchment look waits for the night glass. German is not
  looked at before the store pass.

#### Step stage-3-interface: nothing stands on the walked world, night glass, the places' sound (15.11.2026)

The brief's items (docs/REVIEW-look-2.md H5, H8, M7, M8, M10, M12, L1, L5) as the director's notes of 14.11. and
15.11. changed them: HUD.md (nothing on the walked world, the lantern moment), TITLE.md section 4 (night glass, no
parchment anywhere), the stage-2 critic's second look (its five highs), build 2 English only (L5 waits for the store
pass), the title is not this lane's (TITLE.md sections 1 to 3: one agent wires it after the join). New files:
`Core/LanternMoment.swift` (`HUDKit`: the kit's pieces on the grid; `PurseTicker`; `ChangeNotes`; `LordNotes`;
`StripCall`; `HUDKitActors`), `Core/RealmMapPixels.swift` (the realm strip's pixels), `App/GameModel+Lantern.swift`,
`UI/LanternMomentView.swift`, `tools/markart.py`, `Tests/LanternMomentTests.swift`. Small marked blocks in shared
files: `GameModel` (the state, `setOverlay` keeps the moment's pause, the background raises the lantern, `gold:` and
`hud:` in the scene's value, the ambience's x), `SpriteID` (the kit's seven ids), `PlaceholderPolish`, the catalog.

- **Nothing on the walked world (HUD.md sections 1, 5):** the ledger slip, the pause seal (L1) and the standing realm
  strip are gone. A screenshot of the lord walking shows no interface (`40-walk-no-hud`).
- **The lantern moment (section 2):** a tap on the lord (his body, below where the marks hang; he wins over a thing
  he stands on unless the finger is nearer the thing, it is a person, or he waits there to pay) raises the lantern:
  the simulation stops, the world dims by 30 %, he holds the pole high and his glass burns brighter; above him on the
  world's grid, unlit, the kit's coin and gold, the hood face of the mood, the people and their count, and 2 px under
  them the dawn sign and the day (the day line's bottom 8 px over his head); the realm strip at the top (a tap walks
  him there and lowers the lantern; from the hall he goes out by the door); the gear (44 pt) in the top right opens
  the pause sheet; any other touch lowers it; both answer at once. The app going to the background raises it by
  itself (the pause sheet only where no frame was drawn yet). VoiceOver: the lord is the element `touch-lord` ("Mira,
  day 12, 93 gold, the town is glad, 28 people", "Double tap to pause"); in the moment the figures are elements
  (`hud-gold`, `hud-happiness` with the mood in words, `hud-people`, `hud-clock` "Day 12, 10:24"). The ambience ducks
  as under a screen. Works on the world and in the hall.
- **What comes by itself (section 3):** while the treasury changes, the coin and the figure stand 6 px over his head
  and tick a coin at a time (at most 30 ticks of 0.035 s for a change, evenly), and go 2 s after the last coin; a
  change made under a card ticks once the world shows again (the order on the build card ticks down after it closes,
  `161-purse-at-lord`). A change of the mood or the people shows its sign and an arrow for 2 s on the same row. A call
  (petitioners waiting while he is outside the hall, the Stranger at the gate, a wall below half at night) brings the
  strip for 6 s when it begins or grows and again every 45 s while it stands (round lh-s3-3: once a game hour, 12 s,
  kept it up half the time); answered, it goes at once. The
  breathing of the lantern before the horn (section 4) is the first item of the cut order and not built.
- **The realm strip (H5):** 300 x 50 pt (the map 150 x 14 game px at 2 pt, the call's tag above it), a map cut in
  pixels on night glass with the map's own glyphs (`RealmMapPixels`, ART-look2.md 21.8). It never stands, so the 60 %
  state of H5 (a standing strip while nothing calls) has no place left: it shows whole whenever it shows.
- **Night glass (TITLE.md section 4; ci-out/director/night-glass.md):** the three commits of `claude/lh-glass` are
  taken (2f0d556, adadad5, 62c17fd; `UI/NightGlass.swift` built at once, round lh-s3-1), and the wiring note is done:
  the paper's tokens hold the glass's colours, the sheet, slip, desk and plaque backgrounds are the pane and the
  plaques, the main and quiet buttons the glass styles, the rules haze and the gold lozenge; the portraits and the
  thumbnails sit in the brass line; the talk bubble, the horn's slip, the errand's slip and the cards' pointers carry
  the pixel tail; the dawn report's wash is gone, its sun and ribbons are glass; the pause sheet's switches are the
  pixel slot; Odile's slips lose the teal bar, names are lantern gold and roles mist. The cards' coin, face and people
  are the kit's pixel ones (`KitIcon`). A short price is `Theme.short` (ember). Layout, sizes and words are unchanged.
- **M7, the build card:** the header's figure says "Treasury" in the quiet italic beside it; the arrows to the other
  sites are gone (the player touches the site he means; `GameModel.showPlot` stays for the tests).
- **M8, the Burgherrin's own portrait:** SPRITES.md "The marks as signs, the interface kit, the lady's portrait".
- **M10, the pause sheet:** "Restart chapter" stands under a quiet "Chapter" row below the switches as words alone
  (44 pt), its confirmation as before.
- **M12, the places' sound:** four beds synthesised in `tools/soundsynth.py` (`amb_throat` 7 s: the hollow wind, the
  fog's hiss, a howl in the rock, pebbles and a drip; `amb_bailey` 7 s: the anvil in short runs, the bellows, three
  voices, a sheltered wind; `amb_valley` 6 s: small birds, never a tune, leaves; `amb_river` 5 s: the water's body,
  its babble, bubbles). `AmbienceMix.target(..., x:)` crossfades them over 120 px along the strip (the Throat to the
  bailey at the front gate's passage, 1360; the bailey to the valley at the postern, 2330; the river from 3560 to
  3680); the bailey's forge and the valley's birds sleep at night; the open wind falls back inside the walls (to 60 %)
  and in the valley (to 50 %); in the hall only the hall. The hall's door creak and latch were already in (stage-1).
  The sounds are 3.8 MB now (the test's budget 4 MB).
- **The stage-2 critic's second look (first jobs):** the marks are signs alone (bone with an ink edge; frame 1 lantern
  gold); a slip that names a thing takes its mark's place (the errand's slip, and inside the horn's slip at the door);
  on Marek's days the barracks' sign hangs at the edge the cart leaves free (x 1540) and the barracks carry no rim; a
  site's sign stands over the heads (tip 22 px); by day three marks at most, and two building marks never closer than
  120 px; the rim at 0.5 of `gold` by day; the raised lantern's ring is gone, the lift throws four sparks. The door's
  sign is an arched double door with one seam and its ring (round lh-s3-3's 155: two seams read as a pause sign).
- **After the gate round lh-s3-4** (build, all unit tests, ui Hall, Audience, Lord, Polish, Look2 and TouchUITests'
  stage-2 flow passed; FirstDay and the moment in the hall failed): the camera eases on after the lord stops, so a touch
  read from his element a moment earlier fell on the site he stood on and opened its card; the scene's value carries
  `cam:` and the tests wait for it; the lord's body wins within 7 px and over a bench (furniture), never over a person
  standing there or a wall he waits at to pay. The lady's portrait has a gold drop at her ear lobe (hand-finished).
- **Rounds** (the gate by the director's notes of 14.11. 18:46 and 19:35: one round, English, no `ui-de`, no
  `release`): `lh-s3-1` build (the night glass file of 62c17fd builds); `lh-s3-2` build and the touched unit classes
  (two of the new tests: the purse's stride, the call's strip in the hud value); `lh-s3-3` build, unit, ui FirstDay and
  Touch (FirstDay: the call's strip stood half the time, the report's Continue filled half the card); `lh-s3-4` and
  `lh-s3-5` the gate's classes (all unit tests and five UI classes passed; FirstDay's touch on the lord on his site,
  the moment in the hall and at dusk); `lh-s3-6` the model test of that touch (passed: the camera had eased on);
  `lh-s3-7` ui FirstDay, Touch, Audience (the touch fixed; the day ran out at four times as fast); **`lh-s3-8` build,
  unit and ui Touch, FirstDay, Hall, Audience, Lord, Polish and Look2 ALL PASSED on 35b9c8b** (the gate; sweep
  `ci-out/lh-s3-8-upright`). The atlas: 2048 x 1925 of 2048 rows, unchanged (the kit fills gaps of the page).
- **Open:** the title (TITLE.md, not this lane's); ja and zh-Hans (the store pass); the count (PAY.md: the second touch
  still pays); the lantern's breathing before the horn (HUD.md section 4, first in the cut order); the strip covers the
  castle's crowns while it shows (the world lane's tops, H5's second half); the Burgherrin reads young and distinct
  from the Burgherr but could be softer still (a lip colour, a lighter cheek).
- **After round lh-s3-3's sweep:** the glass plaque's skins lie behind its words (as ZStack siblings the resizable
  skins took all the room: the report's Continue filled half the card); the strip's Throat carries low crags in haze
  rising into the cleft's walls toward the gate and the beacon's crag (that half of the map was an empty line).
- **H8, the title:** not built here: the director's note of 15.11. 01:09 gives the title, the loading lantern and the
  launch image to one agent after the join (TITLE.md). The name entry is on night glass.
- **L5 (ja and zh-Hans):** not run: build 2 is English only (the director's notes of 14.11. 19:19 and 19:35). New
  strings in English and German: "Double tap to go on", "Double tap to pause", "%@, day %lld, %lld gold, %@, %lld
  people", the four moods in words ("the town is glad", "even", "grim", "in unrest"), "Chapter".
- **Tests:** `LanternMomentTests` (the row and the day line on the grid, the face's bands, the purse's ticks and
  linger, the notes, the strip's call, the strip's pixels, and through the model: a tap on the lord stills the world
  and any touch runs it on, the gear and the background, the gold over the lord in the frame, the lord's element);
  `TouchCraftTests` (three by day and the 120 px spacing, the quieter rim, a hidden mark, the cart's barracks, the
  sparks; a site's sign at 22 px); `SoundTests` (the places' beds and the crossfade). UI: `FirstDayUITests` (40
  without a HUD, 160 the lantern moment, 161 the purse at the lord, the strip from the moment, the gear to the pause
  sheet), `TouchUITests.testTheLanternMoment` (167 the call's strip, 162 to 166 the moment by day, with the pause
  sheet, at dusk, at night and in the hall), `HallUITests` and `AudienceUITests` use the strip from the moment.

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
