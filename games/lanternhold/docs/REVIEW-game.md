# Lanternhold: the top-game review (09.11.2026)

Written the way a lead designer and producer of a top studio would write it: what the game is today, what stands
between it and the best of its genre, and in which order to close that gap. Louis judges looks first and holds the
game to the bar of the genre's best; this review does the same.

**What it is based on.** DESIGN.md in full (at `8467449`, M3 merged), STORY.md (`claude/lh-story` at `868c117`),
ART-look2.md (`claude/lh-look2-fable` at `7d6e6d2`), the core and UI code where a claim needed checking
(`Core/Balance.swift`, `Core/Feedback.swift`, `Core/KingTargets.swift`, `Core/Autoplay.swift`, `Core/Names.swift`, the
cards in `UI/`), the runner screenshots of rounds lh-rev-f4 and lh-m3-b3, and the look-2 mocks and creature sheets.

**What it is not based on.** Nobody has held this game in his hands. Every judgement of fun below comes from the
design, the simulation's numbers, a reference bot and still frames. There is no sound yet, and no frame was seen in
motion. Section 6 names this as the first risk. Where this review says "feels", read "will very likely feel".

---

## 1. The game in one paragraph, and what is already strong

**A player after ten minutes (two days and two nights):** "I am the young lord of a castle wedged into the only gap of
a mountain wall. By day I walk through it with a lantern on a pole: I tell builders where to put a palisade, a brazier,
a stake pit, I hire archers, and I sit on the throne while my people bring me their quarrels and I decide. At dusk a
horn sounds and everyone runs to the walls. Then things come out of the dark, and here is the trick: my archers can
only hit what stands in firelight. So I am really building light, not walls. At dawn a bell rings, the things burn
away, the taxes are counted and it starts again. It looks lovely at night. But so far I mostly watched the night:
nobody of mine has died, both nights were over in a few bursts, and on the first day I had spent my gold after a
minute and a half and stood around."

That last sentence is the review in short. The frame is right; the middle is still soft.

**What is already strong (and earns the word).**

| Strength | Why it counts |
|---|---|
| **Light is the rule, not the decoration.** Creatures can only be targeted inside a pool of light; crows snuff braziers; the Lightless King can only be hurt in the beacon's light. | It is the one mechanic that is truly Lanternhold's own, it reads in a single screenshot, and it ties the look, the story (House Lantern) and the play into one idea. Few games in the genre have a rule this clear. |
| **One walk, two lives.** The front, the castle with its cut-away rooms, the town and the river are one strip without a loading screen; the same lord fights at night and judges by day. | The contrast "cold front, warm hall" is the game's feeling, and it is built, not planned. |
| **The audience card.** Portrait, name, role, a short request, two or three tiles with effect chips, Odile's counsel. | Clean and readable in German at phone size (lh-m3-b3, shots 52 to 54). The engine behind it (flags, follow-ups, world changes, night modifiers, chance) is deeper than the content yet uses. |
| **A simulation with measured targets.** A deterministic core, a reference bot, eight tuning targets with bands, a step check. | Very few small games can say "a realm that builds nothing falls on night 3, measured". It makes every change in section 2 testable instead of a matter of taste. |
| **The look-2 night.** Two temperatures, fog banks behind the play plane, creatures as lost people with one cold eye (mock `look2-direction/1-front-night`, creature sheet `8-battle-night-close`). | The first frames that could hang next to the genre's best. The redesigned creatures are a real step: the old ones were ember-cracked lumps, the new ones are people-shapes, and that carries the mystery without a word. |
| **Ad rules written before the ads.** No interstitial before day 4, never at night or at the throne, six minutes apart. | Restraint is decided, not hoped for. |

**What is not strong yet (said once, plainly).**

- **The look that ships today is look 1.** The engine's daylight (shot 52: blue sky, a rock of stacked bricks, bright
  grass) is cheerful and flat, and far from the mocks. The strong frames are mocks from a Python renderer. Until the
  port lands, the game Louis would hold does not look like the pictures he approved.
- **The night is watched, not played.** The lord has a 40 px lantern, a rally bonus, Patch and Light. The design says
  itself: "Little tactics are needed". The reference bot loses no soldier in nights 1 to 10, and each wave "dies
  within seconds of reaching the light". A night without fear makes a dawn without relief.
- **The day has holes.** Day 1's gold is gone by 07:30 and about two real minutes are empty. The way out ("Sound the
  horn") is hidden in the pause sheet behind a confirmation.
- **Many choices weigh nothing on the card.** In shot 52 both tiles read "Kostet nichts". The weight may come later
  through a flag, but the player cannot see it, so the choice feels free.
- **The dawn report says "Heute Nacht ist niemand gefallen" every morning.** A ribbon that always flies is wallpaper.
- **There is nothing to want between dawns** except the next unlock; the Chronicle is a page of records.
- **Silence.** No sound, no haptics until M6. Half of what makes a battle feel like a battle is missing, and every
  fun check so far has judged a mute game.

---

## 2. The twelve most valuable changes, ranked by impact per cost

Costs: **S** up to two days of one lane, **M** about a week, **L** two weeks or more. "Plan" says where the change
belongs: M4 (town), M5 (chapter 1 and endless), M6 (art, juice, sound), M7 (store), or after 1.0.

**Change zero, not counted because it is already decided: port look 2 into the engine before any more art is made.**
It is the largest single step toward a top game (L), and it is under way in its own lanes. The order matters: no M4
town art in look 1, and every fun check from now on should run on look-2 frames, because Louis judges looks first and
the mocks have set his expectation. ART-look2 section 12 is right about what is still missing (one big shape per
region, the Weltmauer on screen, rock that is not bricks); nothing to add here.

### Overview

| # | Change | Area | Cost | Plan |
|---|---|---|---|---|
| 1 | Nights with stakes: people can fall, waves overlap, one breach beat per night | core loop | S | simtune now, locked in M5 |
| 2 | A first pass of sound and haptics now, not in M6 | juice and feedback | S | M4 |
| 3 | Clean ends and a reason to come back: tomorrow's line, two-tap resume | retention | S | M5 |
| 4 | Ads that feel fair: Marek only, no "double taxes", tuning proven without ads | ads | S | rules now, built in M7 |
| 5 | The raised lantern: the lord's own verb at night | core loop | M | first week of M5 |
| 6 | Choices that show their weight | audiences | M | story pass and M4 |
| 7 | The first ten minutes: start at dusk, the horn on the screen, no idle day | first ten minutes | M | horn in M4, the eve in M5, hints in M7 |
| 8 | The walk pays: nothing longer than twelve seconds without something to see or do | the walk | S to M | M4 |
| 9 | Something to want: the chapter line, the Count, deeds | goals and progression | M | M5, deeds in M6 |
| 10 | Twenty nights with a first on each, and a beacon that decides | pacing | M | M5 |
| 11 | Accessibility as a feature, started early | accessibility | M | text sizes in M4, the rest in M7 |
| 12 | The Long Watch as its own game: a steady curve, events, boons | endless | L | curve and three events in M5, boons after 1.0 |

### 1. Nights with stakes

- **What.** Retune the nights so that the player's people are in real danger from night 3 on: soldiers can fall, at
  least one wall is fought over, and the fight lasts instead of arriving in bursts.
- **Why.** Today the reference bot loses nobody in ten nights and the hearth is never touched (T1). That reads as
  "balanced", but for a player it means nights 1 to 10 cannot go wrong. Relief at dawn is the emotional payout of the
  whole loop, and relief needs fear first. It also makes the dawn report's ribbon, the happiness bonus for a night
  without losses and the names of the soldiers mean something.
- **How.** No new system; three tuning moves in `tools/simtune`:
  1. *Overlap.* Shorten the gap between waves and stretch each wave's spawn window, so the second wave reaches the
     light while the first still stands. Same budget `B(n)`, different shape.
  2. *One breach beat per night from night 3.* One wave per night is composed to reach a wall (hounds ahead of the
     archers' range, or a brute behind a screen of sootlings), so every night has a moment when the player looks at a
     wall's health.
  3. *A new target, T9:* over 20 seeds the reference bot loses 1 to 4 soldiers in nights 3 to 10 in total, a wall
     drops below half in at least three of those eight nights, the hearth is still never touched, and every night's
     fighting (first creature lit to last creature dead) covers at least 45 of the night's 108 seconds.
  T1 changes from "0 soldiers lost" to "held, hearth untouched". The staggered volleys that broke the step check stay
  out; the overlap comes from the spawn side, which is already seeded.
- **Cost.** S (numbers and one test; two or three simtune sweeps).
- **Risk.** T2 to T5 move with it (a soldier lost costs 3 happiness, so T4's tax numbers shift). A harder early game
  can lose a new player; the first two nights stay as gentle as they are.
- **Plan.** Start in simtune now, in the tuning lane; lock the numbers in M5 together with change 5.

### 2. A first pass of sound and haptics now

- **What.** Twelve cues through the existing `FeedbackHub` in M4 instead of all of them in M6: horn, first light,
  volley, fire arrow, creature dissolves, wall hit, wall breaks, soldier falls, build done, the choice stamp, coins at
  dawn, brazier lit; plus two ambience beds (night wind, hearth fire).
- **Why.** A battle without sound is a diagram. Louis will judge the first build on his phone with the sound on, and
  a mute build will feel cheaper than it is. It also changes design decisions: with a horn and a bell the day and
  night rhythm is felt, not read off a clock.
- **How.** `CueSynth` and `HapticHub` come from Comet Cargo; the cue enum and the thinner exist (`Core/Feedback.swift`
  has 28 cases with priorities and minimum gaps). Synthesize rough versions, wire the hub, leave the mix for M6. No
  music, as decided: the horn's two tones and the bell's partials are signals, kept under three notes each.
- **Cost.** S.
- **Risk.** Rough sound can annoy more than silence; keep the pass quiet and sparse, with a mute switch in the pause
  sheet from day one.
- **Plan.** M4. The full list (section 4) stays M6.

### 3. Clean ends and a reason to come back

- **What.** Every dawn is a good place to stop and a reason to return, with no timer, no streak, no daily reward and
  no notification.
- **Why.** A day and a night take about five minutes and the game saves at every dawn: the session shape is already
  right for a phone. What is missing is the pull into the next one. A top game earns the return with curiosity, not
  with punishment for staying away.
- **How.**
  - *Tomorrow's line.* The dawn report ends with one line about the coming day, taken from what the petition engine
    already knows is scheduled: "A rider in Varn's colours was seen at the bridge." "Brannock wants a word about the
    outer line." "The crows were loud in the Throat." One line, never a list, never a number.
  - *Two-tap resume.* The app opens on the lord at dawn with a three-line card: the last night in one sentence,
    today's line, "Continue". No menu in between.
  - *The game says goodbye well.* Leaving at dawn costs nothing and nothing happens while away. This is written into
    the store text as a promise ("No timers. Your realm waits for you.").
  - *Not built:* push notifications, daily rewards, streaks, limited-time events, energy. If a notification is ever
    wanted, it is opt-in and after 1.0.
- **Cost.** S (one report row, one resume card, text in eight languages).
- **Risk.** The line must never spoil a story beat; story days get authored lines.
- **Plan.** M5, with the chapter.

### 4. Ads that feel fair

- **What.** Tighten the rewarded offers so the game is provably complete without ads, and keep the interstitial rules
  as written, with four additions.
- **Why.** The planned rules are already restrained. The weak point is "Double taxes" in the dawn report at most every
  second dawn: that is up to half again of the realm's income for a tap. Either the game is tuned with it (then a
  player who never watches plays a harder game, which is the dark pattern we do not want) or without it (then it
  breaks the tuning the tests protect). A button on a report is also the least charming place for an offer.
- **How.**
  - *Drop "Double taxes".* Keep **Marek's cart** (it stands in the world at the back gate, the player walks to it: an
    offer with a face) and the **Second chance**.
  - *Marek offers one of three things, small against the realm's income:* gold (+40 % of that dawn's taxes, at least
    15, as planned), a free repair of the weakest wall, or lamp oil for the night (one more lantern charge, change
    5). He comes every third dawn as planned, and never on a story dawn.
  - *The rule the tests enforce:* T1 to T9 hold with zero ads watched. An ad may make a night easier; it never makes
    a night possible.
  - *Interstitials, additions:* none in the first session after install, whatever the day; none on the dawn after a
    defeat or after a boss night; the ad opens only after the report card has fully left the screen, so no ad lands
    under a finger that was aiming at "Continue"; in endless at most one per ten real minutes.
  - *The consent forms* (UMP, then ATT as in Piston Empire) appear on the first dawn where an ad could be offered,
    never at launch and never in the first three minutes. The ad SDK starts only then.
- **Cost.** S (rules now; the building is M7 as planned).
- **Risk.** Less ad income per player than the three-offer plan. That is the right trade for a game that should carry
  reviews like "fair" and for two accounts that Piston Empire shares.
- **Plan.** Decide the rules now so M5's tuning does not count on gold that will not exist; build in M7.

### 5. The raised lantern

- **What.** One verb for the lord at night that only he has: **hold to raise the lantern.** The pool around him grows
  from 40 px to 90 px for up to four seconds; creatures caught in it flinch (the arm over the face that ART-look2
  already asks for) and can be shot. The lamp then needs twelve seconds to burn back up, shown as the flame on the
  pole growing again.
- **Why.** The night belongs to the archers today; the lord is a camera with a repair button. Light is the game's rule
  and its name, and the player holds a lantern, yet his own light does almost nothing. With this verb the player's
  position at night becomes a decision (which line, which gap, which snuffed brazier) and every wave has a moment
  that was *his*. It is also the picture for the icon and the first screenshot: the lord with the lantern held high
  and the things recoiling.
- **How.**
  - Input: press and hold anywhere while the lord stands; a toggle instead of a hold in the accessibility settings.
    Walking lowers the lantern.
  - Rules in `Balance`: `raiseRadius 90`, `raiseSeconds 4`, `raiseRecharge 12`, flinch 0.6 s once per creature per
    raise. Bosses do not flinch. The Lightless King's aura swallows the raised light until the beacon burns.
  - The crows already give it a job: a snuffed brazier leaves a dark gap, the lord stands in it and holds the line
    until he relights it.
  - Size of the effect: worth one wall or one or two soldiers a night for a good player, never the realm. The
    reference bot uses it with a simple rule (raise when three or more unlit creatures are within 90 px), and T1 to
    T9 are tuned with the bot using it. Days still decide; hands now matter.
- **Cost.** M (sim rule, bot, input, the light pool's animation, one sprite pose, tuning).
- **Risk.** It moves every tuning target, so it must come before the chapter's tuning is locked, not after. If it is
  too strong the walls stop mattering; the recharge is the dial.
- **Plan.** First week of M5, prototype before anything else in M5, together with change 1.

### 6. Choices that show their weight

- **What.** Rules for every petition so that no choice feels free, and so that the realm visibly remembers.
- **Why.** The engine is rich (flags, follow-ups, world changes, night modifiers, chance, five houses), and STORY
  gives the court wants and secrets. But the card often shows two tiles that cost nothing, and Odile's seal on the
  "right" tile lets the player stop thinking. Depth that the player cannot see is not depth to him.
- **How.** Six rules for the story pass and the validator (`Core/CourtValidator.swift` can check the first three):
  1. *No petition with two free tiles.* Every tile carries at least one chip. If the effect is delayed, the chip is a
     new one: a small quill, "The clerk writes it down", which promises that this comes back.
  2. *One in three petitions changes the picture within a day:* a thing built, moved, lit or gone in the castle or
     town (nine castle changes exist, ten town changes come in M4). The petitioner stands next to it the next morning.
  3. *Arcs of three:* at least twelve petitioners come three times (ask, consequence, return), and the third visit
     names what the player chose.
  4. *Petitioners read the realm.* Ten lines that open only on a state: a wall lost last night, the war tax, a third
     night without losses, rain (section 5). Cheap, and it makes the court feel awake.
  5. *Counsel has a voice, not a key.* Odile's seal stays, but her note says why in her own interest ("The ledger
     would thank you"), and from day 8 Brannock may counsel the other tile on military petitions. Two advisers who
     disagree are a decision; one adviser who is always right is a hint system. STORY's limit stands: no chance rolls
     on a counselled tile.
  6. *The houses hang in the hall from day 1.* Five banner hooks behind the throne; a banner goes up when a house
     stands with the lord and comes down when it turns away. STORY plans the banners for night 20; showing the empty
     hooks from the start turns five flags into a goal.
- **Cost.** M (writing, a chip, five hooks, validator rules).
- **Risk.** Text volume grows again, in eight languages. Hold the 240-character limit and add arcs by rewriting
  existing random petitions, not by adding fifty new ones.
- **Plan.** With the story pass (rules 1, 3, 5), M4 (rule 2, with the town's world changes), M5 (rules 4 and 6).

### 7. The first ten minutes

- **What.** The game opens at dusk on the eve of day 1 with a short first night; the horn becomes a button on the
  screen; the first day never leaves the player idle.
- **Why.** Today the first ten minutes begin with the weakest part (a day with 60 gold and two empty minutes) and
  reach the strongest part (night, light, creatures) after two and a half minutes of walking and reading. The genre's
  best open on their picture. Lanternhold's picture is the lord with a lantern at a gate while the light goes.
- **How.**
  - *The eve (night 0).* Outside the economy and the count: no taxes, no happiness change, it cannot be lost, and
    nights 1 to 20 keep their numbers and tests. About forty-five seconds, six sootlings, a fixed wave list; the
    clock waits for the player's first light and ends the night when the last creature is ash. Section 3 gives the
    beats.
  - *The horn on the screen.* Tapping the clock opens one button: "Sound the horn". It is there from the moment no
    build is in progress and no petitioner waits, on every day. No bonus for using it, no confirmation after the
    first time. The pause sheet keeps its copy.
  - *Day 1 without a hole.* Day 1 offers the horn as its fourth hint at the moment the gold runs out. That is cheaper
    than more starting gold and keeps T5.
- **Cost.** M (a scripted eve in the driver, the clock button, the hint chain; the hints themselves are M7).
- **Risk.** A scripted night next to a seeded simulation is a second path through the code; keep it a normal night
  with a fixed tiny wave list and the hearth out of reach, not a separate mode.
- **Plan.** The horn button in M4 (it helps every test player at once). The eve in M5. The hints in M7 as planned.

### 8. The walk pays

- **What.** A rule for the strip: the player never walks more than twelve seconds without something to see, hear or
  do, and never walks a long way twice in a day because the game sent him.
- **Why.** Town to front is about thirty seconds at a run, and DESIGN lists it as an open point. "One walk" is a
  pillar, so the walk has to be a pleasure. In the genre's best the walk is where the player looks at what he built.
- **How.**
  - *Things come to the lord.* A petitioner who waits past noon sends the herald to fetch him; a finished building
    sends a builder who waves. Urgent things never wait at the far end of the strip.
  - *The realm strip is the fast road.* A tap on it runs the lord there by himself (it does today); add a light pulse
    on the strip wherever something waits, so the player sees at a glance where the day is.
  - *The lord hurries at dusk.* From the horn to nightfall he runs at 100 px/s instead of 80. Nobody should lose the
    first wave because he was in the town.
  - *Fill the road.* The 118 court lines and the talk bubbles are there; place twenty overheard one-liners along the
    way so that each stretch of the strip has a voice by day (the smith, the well, the gate guard, children in the
    square). With look 2: chimney smoke, fireflies, the far castle's windows.
  - *The Round.* STORY's custom of lighting every lamp at dusk becomes a small habit: lamps the lord passes between
    18:00 and the horn light at his touch, with a soft tick. No reward but the picture. It teaches the valley's
    warmth against the front's cold without a word.
- **Cost.** S to M.
- **Risk.** Low. Do not add pickups or coins on the road: that is another game's signature ("Not a copy").
- **Plan.** M4, since the town is the longest part of the strip.

### 9. Something to want

- **What.** Three layers of goals: one line for now, one ritual per dawn, one book for the long run.
- **Why.** Between "survive tonight" and "night 20" the player has no named goal. Unlock days (3, 8, 11) exist but
  nobody tells him. A top game always answers "what am I working toward?" within one glance.
- **How.**
  - *The chapter line.* One short line under the clock, authored per stretch of the chapter: "Hold until the middle
    line opens: 2 nights." "Raise the beacon before the twentieth night." It changes about eight times in chapter 1.
  - *The Count.* STORY's custom made visible: at dawn, before the report, the camera rests two seconds on the row of
    numbered lanterns at the gatehouse, one per soldier. A fallen soldier's hook is empty. The report already names
    the fallen (`Core/Names.swift`); the Count puts the picture before the words. It costs one sprite strip and gives
    the losses of change 1 a face.
  - *Deeds in the Chronicle.* Twenty-four deeds (a night without a wall touched; a realm at 80 happiness; all five
    banners; the King slain; each ending). Each one unlocks something to *see*, never power: a banner colour for the
    hall, a shape for the lord's lantern, a carved stone on the road of statues. Game Center is not needed.
- **Cost.** M.
- **Risk.** Deeds are the first thing to slip; the line and the Count are small and carry most of the value.
- **Plan.** The line and the Count in M5; the deeds in M6, or after 1.0 if time is short.

### 10. Twenty nights with a first on each, and a beacon that decides

- **What.** A pacing table for chapter 1 in which every night brings one thing the player has not seen, and a finale
  in which the beacon is the difference between holding and falling.
- **Why.** New creatures arrive on nights 1, 3, 5, 7 and 12, lines open on days 3, 8 and 11, bosses come on nights 10
  and 20. Nights 13 to 19 have nothing new but more of everything: that is where players leave. And the finale's
  promise is hollow today: without the beacon the bot holds night 20 in nine of ten runs (T6 wants three to six).
- **How.**
  - *A first per night.* Fill the gaps with what exists: the petition engine's night modifiers as authored nights
    (13: a still night with thick fog, the fog bank stands closer; 14: crows only in the first wave, every brazier
    is tested; 16: the first two weavers at once; 17: the Returned stand at the edge of the light and do not attack,
    the archers hold their fire; 18: a short night, half the budget, the calm before; 19: the Gloom's bank moves up
    to the outer line). No new creature art.
  - *The beacon decides.* Keep the band (without the beacon 30 to 60 % of realms hold). Reach it without a new
    system: unlit, the King snuffs every brazier within his aura as he walks, and his escort's share of the budget
    rises until the band holds. Brannock says on day 11, in one line, that nothing but the beacon's light will touch
    him, so the player knows the goal nine days ahead.
  - *Two breathers.* The dawn after night 10 and the dawn before night 20 are story dawns with no interstitial (as
    planned) and a shorter queue.
- **Cost.** M (authoring and tuning; no new systems).
- **Risk.** The authored nights must pass through the same seeded path, or the step check breaks again.
- **Plan.** M5.

### 11. Accessibility as a feature, started early

- **What.** A short, real list, with the parts that touch layout done before the six new languages arrive.
- **Why.** The plan is good on paper (44 pt targets, VoiceOver, Dynamic Type on cards, Reduce Motion) but three parts
  are not built: the scene's VoiceOver summary, text sizes on the HUD, and a UI run with Reduce Motion. Look 2 adds
  new demands: a darker game with one-pixel eyes must still be readable in sunlight on a small phone.
- **How.**
  - *Text size.* Three sizes for cards and HUD in the game's own settings, following Dynamic Type by default. Do it
    in M4, because German and Japanese lengths decide the card layout.
  - *Brightness of the night.* A slider "Night brightness" (0.85 to 1.25 on the ambient, never on the light pools),
    so the rule "dark means untargetable" stays readable on any screen.
  - *Hold-free play.* The raised lantern as a toggle; walking by taps on the realm strip is already possible.
  - *A calm option.* "Gentle nights": the night's budget × 0.8, chosen at the start or any dawn, marked in the
    Chronicle, no shame text.
  - *Every sound has a picture.* The horn and the bell come with a banner at the screen's edge; a snuffed brazier
    with a mark on the realm strip.
  - *Flashes.* The beacon lighting, death bursts and first light never exceed three flashes a second, and soften
    with Reduce Motion (which also stops wind, rain streaks and fog drift; section 5).
  - *VoiceOver.* The scene summary with walk actions as planned, and the dawn report read as one paragraph.
  - *A UI run* with Reduce Motion and the largest text size in the runner round, with screenshots in German.
- **Cost.** M in total; the text sizes alone are S.
- **Risk.** Low. The brightness slider must not become a way to see unlit creatures better than intended: it lifts
  the ambient, not the creatures' value.
- **Plan.** Text sizes in M4; everything else in M7 with the store work.

### 12. The Long Watch as its own game

- **What.** Endless mode with a curve that always ends, events that change a night, and a choice between cycles.
- **Why.** Endless is where an ads-only game earns its keep after the chapter, and today it is the chapter's rules
  with a steeper formula: the planned events are not built, the realm hears two or three petitioners a day, and T7
  shows runs that either fall around night 50 or hold past night 70 depending on one gatehouse.
- **How.**
  - *A steady curve (1.0).* A run must end between nights 35 and 60 for the reference bot on at least 80 % of seeds,
    as the new T7 says. The dial is not more budget but pressure the walls cannot out-scale: from night 30 one siege
    kind per wave that only the lord's light or an engine stops.
  - *Three events (1.0),* each announced at dawn so the day can prepare: the eclipse (a double wave, and the night
    starts an hour early), the plague of crows (every brazier is attacked once), the festival (no attack; a day of
    petitions and a happiness gift). One event every fifth night.
  - *Boons (after 1.0).* Every tenth dawn the court offers one of three decrees for the rest of the run ("Oil from
    Brine: braziers cannot be snuffed in the first wave"). This is what makes the tenth run differ from the first.
  - *Records worth showing.* The Chronicle keeps nights held and the realm's last picture; a share card with the
    castle at its last dawn. No leaderboard pressure, no weekly seed with a deadline.
- **Cost.** L in full; the curve and three events are M.
- **Risk.** Scope. Endless can swallow the two weeks the chapter needs.
- **Plan.** Curve and three events in M5; boons and the share card after 1.0. See the cut list in section 6.

---

## 3. The onboarding (M7): the first three minutes, beat by beat

**Rules.** One hint at a time. A hint is at most nine words (German: 60 characters) and comes from Odile as a speech
bubble at her sprite, with Comet Cargo's tapping hand on the thing to touch; never a banner, never a modal, never a
pause except in the first audience. Each hint ends with the player's first success and never returns. If the player
does nothing for six seconds the hand shows again. No consent form, no ad, no rating prompt and no settings in these
three minutes. `-GWSkipOnboarding YES` and a "Hints" switch turn it all off; a second realm and endless start without.

| Time | What the player sees | What he does | What it teaches | Words on screen |
|---|---|---|---|---|
| 0:00 | Black. Two figures with unlit lanterns, a man and a woman. | Taps one. Its lantern catches; a soft tick in the hand. | The choice of Burgherr or Burgherrin, made as a picture. | none |
| 0:06 | The prologue: four panels, one line each, four seconds a panel, a tap goes on. | Watches or taps through. | Where he is: the wall, the cleft, the house that keeps the light. | four lines |
| 0:22 | Dusk, just before the horn (on the eve the clock waits for the player). The lord stands under the gatehouse; the valley's windows glow behind him, the Throat is dark ahead. Odile beside him. | Nothing yet. Two seconds to look. | The picture of the game. | none |
| 0:25 | The hand drags from the lord toward the dark brazier outside the gate. | Drags to walk about 60 px. | Walking. | "Walk with me, my lord." |
| 0:35 | A ring pulses on the cold brazier. | Taps it. Fire, a pool of light with an edge, sparks. | Light is something he makes. | "Light it." |
| 0:42 | The horn: two long tones. The sky sinks to blue in twelve seconds; three archers climb the wall. | Watches. Can walk. | Dusk means the night comes. | "The horn. To the walls." |
| 0:55 | Three sootlings crawl out of the dark. In the dark the archers do not shoot. At the pool's edge the creatures flinch; arrows fly; they fall to ash, the eye goes out last. | Watches. | The rule: only what stands in light can be hit. | Brannock: "They only die in the light." |
| 1:10 | A gust of soot from the Throat snuffs the brazier. Dark. The archers lower their bows; three more sootlings come on. | Taps the brazier again (the hand shows after two seconds). | Light can be lost, and his hands bring it back. | "Light it again!" |
| 1:22 | One sootling slips past the pool toward the gate. | Holds a finger down: the lantern goes up, the creature recoils, an arrow finds it. (With change 5; without it this beat is cut.) | The lord's own verb. | "Raise your lantern. Hold." |
| 1:35 | Quiet. A second of silence, then the bell: first light sweeps across the strip, the ash blows away, the valley turns gold. Three seconds with no card. | Watches. | Dawn is the reward. | none |
| 1:42 | The Count: the camera rests on three numbered lanterns at the gate, all lit. Then a short report: creatures stopped, nobody fell, "Day 1 begins". The Chronicle opens with a name already written in. | Taps "Continue" (or types his own name first). | Nights are counted; people have numbers. | the short report |
| 1:55 | Day 1, 06:00, 60 gold. A plot marker pulses in front of the gatehouse. | Taps it; the build card opens with the stake pit lit. Taps "Build". Two builders walk out and hammer. | Building costs gold and takes people and time. | "Brannock wants stakes before the gate." |
| 2:15 | The next plot pulses. | Builds a second brazier. | More light, more reach. | none |
| 2:25 | The realm strip at the top pulses at the throne. | Taps it. The lord runs there by himself; the hall's wall fades away as he enters. | The strip is the fast road; the castle is one place. | "The hall is waiting." |
| 2:40 | He sits. The first petitioner walks up; the parchment card opens. | Reads three lines, taps one of two tiles. A stamp; the chips fly to the HUD. | His word changes numbers and people. | the petition |
| 2:55 | The petitioner bows and leaves. "Next petitioner (1)" and "Stand up". | Either. | He is in charge of his day. | none |

**After minute three, one new thing per day, each at the moment it is needed:**

- Day 1, when the gold runs out: the clock pulses, "Sound the horn" (change 7).
- Night 1: nothing new. He does alone what the eve showed him.
- Dawn of day 2: the first taxes, and the tax rate (one tap, three choices; the war tax is not shown before day 8).
- Day 2: recruiting at the barracks, when the first petition about soldiers comes.
- Day 3: the middle line opens; the chapter line (change 9) says so.
- Night 3: the first hound, and with it the first breach beat (change 1): Patch.
- Day 4 at the earliest: Marek's cart, and before it the consent form.

**What is left out on purpose:** the happiness formula (the chips teach it), traps and engines (their plots explain
themselves when they unlock), the endings, the Chronicle.

**The test.** A UI test plays these beats in under 180 seconds in English and German and saves one screenshot per
beat; an agent reads the German shots for clipping. If a beat needs a second sentence to be understood, the beat is
wrong, not the text.

---

## 4. The juice list (M6): every feedback moment

**Rules for the whole list.**
- No music. Two signals carry the day: the horn (dusk) and the bell (dawn), each at most three notes.
- Sound effects are synthesized (`CueSynth`); positional cues pan and fade by the distance to the screen's centre.
- Haptics use the system's vocabulary (light, medium, heavy, rigid, soft, selection, success, warning, error) and a
  few continuous patterns. At most three haptic events a second; battle haptics only fire when the source is on
  screen; the thinner's priorities (`Core/Feedback.swift`) decide who wins.
- Screen shake is sideways only, at most 3 px, and off with Reduce Motion. No full-screen white flash anywhere.
- "Cue" names the case in `Core/Feedback.swift`; **new** means the sim event exists or is needed but has no cue yet.

### Night and battle

| Moment | Cue | Visual | Sound effect | Haptic |
|---|---|---|---|---|
| Night falls (20:00) | new (`nightfall`) | the vignette closes a step; windows in the town light one by one; the fog bank starts to drift toward the castle | the wind drops out for 1.5 s, then the night bed (low wind, far wood creak) | none |
| The Gloom's bank moves up | new | the bank slides forward; cold eyes blink on inside it; the firs bend in a gust | a long dry breath, low | soft, once |
| A creature enters light | new | the flinch frame (arm over the face); its torn detail shows; a 1 px cold rim | a short dry hiss | none |
| Archer volley | `volley` | bows snap; arrows on arcs with 2 px trails | three to five soft twangs, slightly apart | light, only if the lord is within 120 px |
| Fire arrow | `fireArrow` | an ember trail, sparks at the hit, a 0.3 s small pool where it lands | a twang with a whoosh; a small crackle on the hit | light |
| Ballista | `ballista` | the frame recoils 1 px; a bolt with a line of dust | a wooden thunk and a ratchet | rigid |
| Catapult | `catapult` | the arm swings; the stone's shadow runs along the lane; dust at the hit | a creak, a release, a late heavy thud | medium at the hit |
| Stake pit takes a creature | new | the stakes jolt; a puff of ash | a dry crack | light |
| Creature dissolves | `creatureDissolved` | three frames to ash; the eye stays one beat as a single pixel and goes out last; ash drifts with the wind | a soft breath out, a faint ember tick | none (too many) |
| Brute or weaver dissolves | `creatureDissolved`, heavy | a larger ash fall; the dead lantern drops and rolls 4 px | the breath lower and longer; a tin clink for the lantern | medium |
| An arrow glances off (unlit or the King's aura) | `glancedOff` | a cold spark; the arrow spins away | a dull tick, no ring | none |
| Wall hit | new (thinned hard) | the wall jolts 1 px; two splinters or stone chips; the health bar shows for 2 s | a wood knock or a stone thud, pitch by material | light, at most one a second |
| Wall below a third | new | cracks appear; a red-warm pulse on the realm strip at that line | a strained creak | warning, once |
| Wall breaks | `wallBroken` | beams fall, dust rolls, shake 3 px for 0.45 s | a crash with a long tail of falling wood | heavy |
| Soldier falls | `soldierFell` | he drops; his lantern on the wall goes out; his hook's number floats up and fades | a short cry cut off; the lantern's tin clink | medium, then 0.3 s with no other haptic |
| Brazier snuffed | new (`brazierSnuffed`) | the pool collapses inward in 0.2 s; a ring of smoke; a dark mark on the realm strip | a wet hiss; the fire bed loses a voice | rigid |
| The lord lights a brazier | `brazierLit` | the flame jumps high once, the pool opens outward with its edge, sparks | a whump and a crackle | medium |
| The lord patches a wall | `patched` | two planks slam on; the bar jumps | two hammer blows | two light taps |
| Patch refused (no gold, cooldown) | `refused` | the button shakes 2 px; the missing gold blinks | a dull knock | error |
| The lantern raised (change 5) | new | the lord lifts the pole; the pool swells to 90 px; creatures inside recoil | the flame roars up softly | a continuous swell while held |
| The lantern spent | new | the flame shrinks to a point; the pool falls back | a small gutter | soft |
| Rally (soldiers near the lord) | none needed | a faint warm rim on soldiers within 80 px | none | none |
| Giant's step | `stomp` | shake 1.6 px; dust from the lane; lanterns on the walls swing | a deep thud felt more than heard | heavy, one per step |
| The hearth is hit | `hearthHit` | the hall's fire dips; the whole castle's warm light drops a step for 0.5 s | a low boom; the fire bed thins | heavy, twice |
| The Gloom recedes (last wave dead) | new (`gloomRecedes`) | the bank pulls back; the eyes go out together | the breath, reversed | none |

### The finale

| Moment | Cue | Visual | Sound effect | Haptic |
|---|---|---|---|---|
| The beacon lights | `beaconLit` | a column of warm light climbs the tower over 1.5 s; the pool rolls out across the whole front; every creature flinches at once | a deep whoosh that rises; a single bell partial on top | a continuous ramp of 1.5 s ending in heavy |
| The King's aura breaks | `kingAuraBroken` | his cold crescent cracks; the teal of his rags shows for the first time | glass under cloth, low | rigid, then medium |
| The King's aura closes | new (`kingAuraClosed`) | the dark folds back over him; nearby flames lean away | a muffled thump | soft |
| The King is slain | `kingSlain` | he does not burst: the mantle sinks, the crown falls and rolls, the two lanterns at his belt light for a second, then ash; all fog stills | every sound stops for one second; then wind | one heavy, then nothing for two seconds |
| Night 20 dawns | `firstLight`, long | the longest first light of the game; banners in the hall catch it | the bell, three partials, the only time it rings three | success |

### Dusk and dawn

| Moment | Cue | Visual | Sound effect | Haptic |
|---|---|---|---|---|
| The horn (19:00) | `horn` | a banner slides in at the screen's edge; citizens hurry home; archers climb; shutters close | two long tones from the gatehouse, panned to it | a slow rumble of 1.2 s |
| The Round (18:00 to the horn, change 8) | new | each lamp the lord passes lights with a small pool | a soft tick, rising in pitch along the row | selection |
| First light (05:00) | `firstLight` | a warm edge sweeps from the valley to the Throat in 2 s; creatures in the open burn off; three seconds without a card | bell partials, then the first birds | a soft swell |
| The Count (change 9) | new | the lantern row; an empty hook where someone fell | each lit lantern a quiet tick; an empty hook is silence | one soft tap per empty hook |
| Taxes counted | `taxesCounted` | coins run into the treasury number; the number ticks up | coins on wood, speed by the amount | light ticks, at most eight |
| Happiness up or down | `happinessUp`, `happinessDown` | the face on the HUD changes; an arrow chip | a warm two-note murmur; a low murmur | light; soft |
| A citizen is born or arrives | new | a small figure walks in at the river end; +1 floats at the people count | none (the report line is enough) | none |
| Tomorrow's line (change 3) | none | the line fades in last, in italics | a page turn | none |

### Day, building and the court

| Moment | Cue | Visual | Sound effect | Haptic |
|---|---|---|---|---|
| A card opens or closes | `cardOpened`, `cardClosed` | the parchment unrolls 0.2 s, rolls away 0.15 s | paper | none |
| Build ordered | `buildOrdered` | the plot's outline fills in as a ghost; builders turn and walk | a stamp on wood; coins | light |
| Building under way | none | hammer swings, dust, the frame grows in three stages | hammer taps in an uneven rhythm, only on screen | none |
| Build done | `buildDone` | the last stage drops in with a 1 px bounce; a ring of dust; the builder wipes his brow | a full wooden knock and a short flourish of two taps | medium |
| A line unlocks (days 3, 8, 11) | new | the camera glides to the new plots; markers rise from the ground | Brannock's whistle, two notes | success |
| Recruited | `recruited` | a citizen takes a bow or shield at the barracks, his clothes change, he salutes; a new lantern is hung on the row | leather and a buckle | light |
| Tax rate set | `taxSet` | the seal presses on the tax roll; the face on the HUD looks at it | a seal stamp | rigid |
| The lord sits on the throne | new | he sits; the hall's edges darken slightly; the queue forms at the door | cloth, the hearth louder | soft |
| A petitioner walks up | none | footsteps, a bow or a curtsy by role | steps by floor (stone in the hall) | none |
| A choice is made | new (the stamp) | the tile presses in, a wax seal lands on the card, chips fly to the HUD numbers | a stamp on parchment | medium |
| "The clerk writes it down" (change 6) | new | a quill chip stays on the card for a second | a quill scratch | none |
| Counsel opened | none | Odile leans in; her note slides onto the card | a low "hm" as a synthesized formant, no speech | selection |
| A banner goes up or comes down (change 6) | new | the cloth unrolls on its hook, or is taken down by a servant | cloth snap; or a slow rustle | light; soft |
| A world change appears | new | the next morning the camera passes it once on the lord's way; the petitioner stands beside it | by the thing: water for the well, a saw for the bridge | none |
| A room cuts away | none | the wall fades in 0.25 s; the room's own light takes over | the room's bed fades in: hearth, chapel hush, kitchen pots | none |
| Talking to someone | none | the speech bubble pops with a 1 px bounce | a short voice blip per speaker, pitched by person | selection |
| Footsteps | existing plan | dust puffs on earth, none on stone; mist puffs in the Throat | by zone: earth, cobble, wood, stone | none |
| Marek's cart is there | new | the cart at the back gate, a lantern on it, Marek waves when the lord is near | a small bell on the cart, once | none |
| A reward is granted | new | the gift is carried off the cart into the world (coins to the treasury, planks to the wall, an oil flask to the pole) | by the gift | success |

### Defeat, endings, and the edges

| Moment | Cue | Visual | Sound effect | Haptic |
|---|---|---|---|---|
| Defeat | `defeat` | the hearth goes out; the town's windows go dark one by one (built); the card comes late, after three seconds | the fire bed dies; wind only | one heavy, then silence |
| Second chance taken | new | the hearth flares; a ring of light throws the creatures out of the castle | a roar of flame; the bell once | a ramp to heavy |
| An ending panel | none | each panel fades in from dark; the lantern over the far gate is the last thing lit | wind; one bell partial at the last panel | soft at the last panel |
| A deed is written (change 9) | new | a line writes itself into the Chronicle's margin | a quill; a seal | success |
| Returning to the game | none | the lord's lantern lights first, then the scene fades up around it | the bed fades in over 1 s | none |

**Always there (ambience).** By region and hour: the Throat (low wind, rock ticks, nothing alive), the walls (flags,
fire), the courtyard (smithy, well), the hall (hearth), the town (murmur by day, dogs and a door at night), the river
(water, reeds). The weather of section 5 lies over these.

---

## 5. Weather (Louis' wish)

**The wish.** Wind that changes from day to day, so trees and leaves sway more or less; rain on some days and nights.

### What it adds to the feel

- **The world has days, not one day twenty times.** Chapter 1 shows the same strip for twenty days and nights. Weather
  is the cheapest way to make day 7 look and sound different from day 6.
- **It is the "gemütlich" half of "düster und gemütlich".** Rain on the hall's roof with the hearth burning, seen
  through the cut-away wall, is the coziest picture this game can make. Rain at night at the front, with the fires
  hissing and the fog low, is the gloomiest. One system serves both poles of the look.
- **It makes the light look better.** Rain streaks and wind-blown sparks are only visible where there is light, so
  every pool gains texture and the dark stays dark.
- **It gives the court something to say.** One line at the first rain, a few state lines (change 6, rule 4), and a
  word in the dawn report.
- **It is a store picture.** The town at night in the rain, windows lit, belongs among the screenshots.

### The rules

1. **Seeded per day.** The weather of a day is a pure function of the realm's seed and the day's number,
   `Weather.of(seed, day)`, with its own random stream. It reads nothing from the simulation and writes nothing to it.
   The same realm has the same weather on the same day, also after "Replay the day" and after loading. Nothing is
   saved.
2. **No effect on play in 1.0.** Light radii, braziers, targeting, speeds, builders, taxes and happiness do not know
   the weather. The step check and the tuning targets give the same numbers with weather on or off; a test proves it.
3. **The fiction says so, once.** Rain that looks as if it should put out a fire invites the wrong guess. At the first
   rain Odile says one line ("Rain never put out a lamp of ours."), the braziers hiss and steam but burn, and nothing
   on the HUD moves.
4. **What a day's weather holds.**

   | Value | Range | Share |
   |---|---|---|
   | Wind | calm, breeze, wind, strong | about 25 / 40 / 25 / 10 % |
   | Wind direction | from the Throat toward the valley, or back | 70 / 30 % |
   | Rain | none, drizzle, rain | about 75 / 15 / 10 % of days |
   | Rain window | a start hour and a length of 4 to 14 hours | so rain can fall by day, at night or across dusk |
   | Mist | the fog banks' strength ± 15 % | every day a little different |

   Limits: day 1 and the eve are dry with a breeze (the first impression and the tutorial stay clear); never more
   than two rain days in a row; at most one "strong" wind in three days.
5. **Story nights are authored, not rolled.** Night 10 (the Ash Giant): strong wind from the Throat, dry. Night 20:
   still and dry until the King leaves the Gloom, then the wind rises; when the beacon lights, the wind drops. Each
   ending has its own weather. These are fixed in the same function, so they stay deterministic.
6. **The dawn report names the day** with a small icon and two or three words ("Wind from the Throat", "Rain by
   evening"). It is a mood line, not a forecast to plan around.

### What moves (wind)

| Thing | Calm | Breeze | Wind | Strong |
|---|---|---|---|---|
| Near trees (crown top, whole pixels) | 0 px | ± 1 px, 4 s | ± 1 px, 3 s, gusts to 2 | ± 2 px, 2.5 s |
| Foreground grass, ferns, reeds | still | 2 frames, slow | 2 frames, fast | fast, leaning with the wind |
| Banners and flags | hang | slow wave | wave | snap |
| Chimney smoke, brazier smoke | straight up | leans 15° | leans 35° | leans 55°, torn |
| Sparks and embers | rise | drift a little | drift | fly low and far |
| Fog banks' drift | × 0.5 | × 1 | × 1.5 | × 2 |
| Cloud deck | 0.5 px/s | 1 px/s | 2 px/s | 3 px/s |
| Leaves (valley) and ash motes (Throat) | none | a few | some | many |
| The lord's lantern on its pole | still | swings 1 px | swings 1 px, faster | swings 2 px |
| Flames | upright | lean 1 px | lean 1 px, flicker a little more | lean 2 px (the light radius does not change) |

Nothing moves on the far plane but clouds, as ART-look2 rules. A gust (two seconds of the next level up) runs through
the firs when the Gloom's bank moves: the forest bends before a wave comes.

### What rain does

- **Two layers of streaks:** thin far streaks behind the play plane, and near streaks in front at no more than 35 %
  alpha, leaning with the wind. Drizzle is the far layer only. Streaks are brightest inside light pools and nearly
  invisible in the dark.
- **On the ground:** 2 px splashes on the lane, a wet tint (the lane and roofs one value step darker, with a slightly
  stronger warm sheen under lights). No mirror strip and no reflected scene along the bottom: that is another game's
  picture ("Not a copy").
- **People:** citizens walk faster and fewer stand in the square; the tavern's windows are brighter; archers on the
  walls pull up their hoods (one extra frame per kind, or nothing in 1.0).
- **Fires:** steam puffs and a hiss on braziers; the hearth is untouched.
- **Rooms:** inside a cut-away room no rain falls; the sound changes to rain on a roof.
- **Sound:** a rain bed of filtered noise in three places (open, under a roof, on the walls), fading over two
  seconds; gusts as slow swells in the wind bed; distant thunder as a low roll at most twice a night, without any
  flash. No haptics for weather.

### Limits and tests

- **Readability first.** Rain is never drawn over a card; creatures keep their contrast against the fog bank (check
  the sootling's eye at 14 px in rain against fog at 0.45); night rain does not darken light pools.
- **Reduce Motion:** no sway, no drift; rain becomes the wet tint, the splashes at a quarter rate and the sound.
- **Speed:** at most 300 streaks as instanced quads, half of that in Low Power Mode and on the oldest supported
  phone; the frame budget on an A12 is still unmeasured (DESIGN's open point), so rain ships with a measured number
  or with the cap halved.
- **Tests:** `WeatherTests` (pure and repeatable; over 1000 days the shares above, no rain on day 1, never three rain
  days in a row, the authored nights), and one sim test that the state hash after ten days is identical with weather
  on and off.

### Cost and place in the plan

- **Wind: S.** It is already on the port's list (ART-look2 12.4). It lands with the look-2 port; the per-day level
  is one small function on top.
- **Rain: M** (particles, the wet tint, the sound bed, the hooded frames optional). M6.
- **After 1.0, as endless events only:** weather with rules (a fog night that shrinks every pool, a storm in which
  fire arrows fall short, rain that helps the fields). Never in chapter 1 without a full tuning pass.

---

## 6. Risks, and what to cut first

### The first risk: nobody has played it

Every fun judgement so far comes from a bot, a simulation and still pictures. Bots do not get bored and do not feel
relief. **Before M5's tuning is locked, Louis should hold a build for ten minutes** (TestFlight, internal, as soon as
signing works on the runner), with the first sound pass in it (change 2) and look 2 in the engine. One evening of his
thumbs will re-rank this list more reliably than another review. Until then, treat the order in section 2 as a
well-founded guess.

### Apple guideline 4.3 and originality

- **Where the game stands.** A side-view pixel realm defended at night, with a lord walking it, sits in the same
  family as Kingdom; a throne with petitioners sits near Yes, Your Grace and Reigns. DESIGN's "Not a copy" table and
  STORY's rules keep the mechanics apart (no mount, no coin drop, no vagrants, one front, tap tiles, one meter), and
  the combination plus the light rule is Lanternhold's own. On mechanics the risk is low.
- **Where the real risk is: the thumbnail.** At the size of a store screenshot, "small crowned figure, side view,
  torches, night, pixel art" reads as Kingdom to anyone who knows it. Reviewers and players judge the picture first.
  What keeps it apart: the lantern on its hooked pole in the icon and in every shot; the Weltmauer and the cleft as
  the one big shape (ART-look2 12.2); the first screenshot showing the light rule (creatures recoiling at a pool's
  edge), the second the hall cut open with a parchment card; no water mirror along the bottom, ever; the lord's small
  tilted circlet instead of a tall crown.
- **The spam side of 4.3** (many similar apps from one account) is not touched: Lanternhold shares nothing visible
  with Piston Empire or Comet Cargo. Keep it that way in the store text and the icon style.
- **The name.** Before any store asset is made, search the App Store and the trademark registers for "Lanternhold";
  a clash found in M7 costs the icon, the screenshots and eight store texts.
- **Art made with a generator.** Recraft concepts are finished by hand and composed from the game's own sprites,
  which is the right rule. The risk is inconsistency between hands and stages, not rejection; ART-look2's value
  targets are the guard. Keep the raw concepts out of the repository and out of the store.
- **The creatures and the age rating.** Two of the eight were children (the sootlings), and they are shot with
  arrows. It is drawn without blood and fits the story, and it is strong. But it must be answered honestly in the
  age-rating form (horror and fear themes), and those answers are legal statements in Louis' name. Decide with him
  before M7 whether "a child" stays in the art bible only or is ever said in the game, and what rating he accepts.
  The planned `maxAdContentRating = .general` stays whatever the game's own rating is.

### AdMob quality

- **Low-value content** is not a danger for a game with this much content; DESIGN is right about that.
- **Accidental clicks are.** An interstitial that appears where a finger is about to tap is the classic way to lose
  an account. Change 4's rule (the ad opens only after the report card has left the screen) and the six-minute gap
  cover it; add a test that no ad can be requested while any card is on screen.
- **Rewarded ads** must name the reward before the tap and deliver it every time, also when the ad fails to load (then
  Marek gives a smaller gift for free and says so). A reward that is promised and not given is a policy matter and a
  one-star review.
- **Consent.** UMP with the published European message, then ATT, as in Piston Empire, moved to the first ad dawn.
  `NSPrivacyTracking` stays false. Test ad units in Debug only; no real ad on the runner or in a screenshot.
- **Children.** The game is not made for children and must not enter the Kids category. Say so in the AdMob app
  settings.

### Scope

What is still ahead of 1.0: the story pass over 83 petitions and 118 lines (the Burgherr, the houses, the new names),
the look-2 port and its world art, a second lord (Burgherrin: sprite sheet, glow, portrait, seated pose), M4's town
with ten world changes, M5's chapter and endless with red tuning tests (T6, T7), M6's sound and juice, M7's
onboarding, ads, six more languages, store shots and the submission. DESIGN's estimate of three to four weeks was
made before look 2, the new story and this list. **An honest estimate with changes 1 to 11 is six to eight weeks**
at the current pace of two to three lanes. That is acceptable for the game the wave is meant to be judged by, but it
has to be said to Louis in those words.

Three scope traps to watch:
- **Text.** Every petition added is written once and translated seven times. Change 6 must rewrite, not add.
- **Two looks.** As long as look 1 art is still being made or fixed anywhere, work is being thrown away.
- **Red tests.** T6 and T7 fail today. A chapter and an endless mode built on top of failing targets get tuned
  twice. Settle them (changes 1, 5, 10 and 12 all touch them) in one tuning pass at the start of M5.

### What to cut first if time runs short

In this order; each line is cut before the next one is touched.

1. **Boons, the share card and deeds with unlocks** (changes 12 and 9): after 1.0. The chapter line and the Count
   stay.
2. **Rain.** Wind stays (it comes with the port); rain becomes the first update's headline, which is a good one.
3. **Endless events beyond one.** The Long Watch ships with the steady curve, the festival and records.
4. **Four of the ten town world changes.** Keep the six that belong to story petitions.
5. **The authored nights 13 to 19** shrink from six to three (fog night, the Returned, the calm before).
6. **Marek's three gifts** shrink to gold only.
7. **The eve.** The game starts on day 1 as today, with the horn button and the hint chain; the light rule is taught
   on night 1 instead.
8. **Endless mode itself:** the last and largest cut. The chapter's ending says the Long Watch opens with the next
   update. It saves the T7 tuning and one of the two modes to test, and it costs the mode that keeps players (and ads)
   after the chapter, so only if the alternative is a weak chapter.

**Only Louis can cut these, so ask him rather than decide:** the Burgherrin (a second lord's art), and shipping 1.0
in English and German with the six other languages two weeks later.

**Never cut:** nights with stakes (1), the first sound pass and the M6 mix (2), the look-2 port, the onboarding, text
sizes and Reduce Motion, the ad rules, and Louis' ten minutes with a build. A game that looks like the mocks, sounds
right and has one night the player fears is a top game with a short feature list. The reverse is not.
