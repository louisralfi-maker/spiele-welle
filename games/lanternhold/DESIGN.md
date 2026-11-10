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
  nobody counted on, the castle's lamplighter, Aldric's young cousin; the circlet is a little too big. Seren, the
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
| A ruler on a horse or any mount; mounts bought with gems | The king walks, carrying his old lamplighter's lantern on a hooked pole |
| Coins carried in a pouch and dropped at build sites, the coin drop as the only input | Gold in a treasury from taxes; a build card with prices at each plot |
| Vagrants in the wild recruited with coins, tools that set a job | Citizens are born in the town when people are happy; soldiers are recruited at the barracks |
| Masked enemies from portals that steal coins and the crown; losing the crown ends the run | The Gloom is a creeping wall of black fog with soot creatures; they want the hearth fire, never the king |
| Enemies from both sides | One front only, on the left; the Weltmauer closes everything else |
| A water reflection strip along the bottom, the island campaign, boats | The Weltmauer and its single cleft, a castle cut-away, the town's lit windows; reflections only where the world has water |
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
petitioners waiting. Debug only: `debug-king-x`, `debug-camera-x` (values for the jitter test).

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
| `castle.statue` | courtyard, x 1680 | M3 step 3 | a stone statue of the lamplighter king with his lantern (`statue`) |
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
  and 11,600 German words (German runs 13 % longer in characters). Voices: Odile dry and sarcastic ("my king"), Brannock
  gruff ("Majesty"), Pip jokes ("Your Wickship", German "Eure Dochtheit"), Mother Hesper calm and ominous, Tamsin
  gossip with hints, Bram in few words, Marek sly ("Your Radiance", "Eure Strahlkraft"), Seren quiet ("king"), the
  herald cold ("lamplighter"). German addresses the king with "Ihr" and "Euch".
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
| 20 | `last_stand` | Brannock | the last morning's word to the men: **"We hold until dawn"** / "We bring our old king home" / "I was never meant to be king" (`speech_dawn`, `speech_aldric`, `speech_honest`; nothing else) |

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
