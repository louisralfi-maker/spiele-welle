# The people lane (branch claude/lh-people)

Louis, 14.11.2026: "Was auch verdammt cool wäre, wenn die Bauern und die Leute, die arbeiten, schon richtig verbraucht
sind, vom Leben geprägt … dann ist es halt cool, wenn es lebensfrohe Kinder gibt oder abgehobene reiche Adelige. Das
bringt Charakterwechsel mit rein." The rule: `docs/BARS.md` section 3. Who is who: `docs/PEOPLE.md`. The sprites:
`docs/SPRITES-people.md`. The code: `Core/PeopleCast.swift`.

## people-1: the cast

### What exists

- `docs/PEOPLE.md`: twelve working people (eight with a body of their own now, four on bodies the game has, each with
  the mark its repaint must add), three children, the nobles of the inner lands as a kind (Ser Aubrey Oxmoor's body, a
  lady's body, their footman), fitted to STORY.md's houses and guests; how each is drawn (silhouette, posture, pace,
  cloth by palette name, the tell); where they are in the game; their voices in English and German.
- Art, all hand-set part grids through `tools/actorart.py` (no generated picture anywhere):
  - repainted at their sizes and frames: `citizen` (Mother Corra), `citizenB` (Dun Rook), `citizenC` (Ned Furrow) and
    their seated forms `citizenSeated`, `citizenBSeated`, `citizenCSeated` (`tools/grids/actors/`);
  - new at the citizen contract: `elder` (Old Hemmet, the shuffle), `washerwoman` (Wenna Brisk, with wring frames),
    `labourer` (Brede Hask, the limp), `farmerHoe` (Gorm Ashby) and `farmerScythe` (Hedda Ashby), each farmer with work,
    straighten and carry frames (`tools/grids/people/`);
  - three children `childA` (Nib), `childB` (Wren), `childC` (Fen) at 10x18: run, fidget, skip;
  - at the guests' contract: `nobleLord`, `nobleLady`, `footman`.
  - `tools/build-art-people.sh` rebuilds all of them byte for byte; `tools/peoplesheet.py` draws the proof sheets.
- Code: `Core/PeopleCast.swift` (the bodies' sizes and frames, the walkers' bodies, pace and step, the farmers at work,
  Wenna at the well, the children at the square by happiness, Fen at the lord's heels), `Render/PlaceholderCast.swift`
  (stand-ins), `Tests/PeopleCastTests.swift`, `UITests/PeopleUITests.swift` (shots 130-133).

### The hooks in existing files (apply them again at the join)

| file | place | the hook | why |
|---|---|---|---|
| `Core/FrameDesc.swift` | `enum SpriteID`, after `case circletIcon, circletIconInk` | one `case elder, washerwoman, labourer, farmerHoe, farmerScythe, childA, childB, childC, nobleLord, nobleLady, footman` line with its comment | the ids (the PNG names) |
| `Core/FrameDesc.swift` | `var size`, the switch's last case | `case .elder, … .footman: return PeopleCast.size(of: self)` | sizes live in PeopleCast |
| `Core/FrameDesc.swift` | `var frameCount`, after `case .citizen, .citizenB, .citizenC, .builder: return 6` | `case .elder, … .footman: return PeopleCast.frameCount(of: self)` | frame counts live in PeopleCast |
| `Core/EntityFrames.swift` | `actors(…)`, the `if isDay { townsfolk(…) }` block | `townsfolk(s, time: time, look: look)`; then `if look == .two { PeopleCast.townLife(s, time: time) { … add(…) } }` | the cast out in the town, look 2 only |
| `Core/EntityFrames.swift` | `townsfolk(…)` | a `look: LookVersion = .one` parameter; `let sprites = look == .two ? PeopleCast.townWalkers : [.citizen, .citizenB, .citizenC]`; `speed × PeopleCast.pace(sprite)`; the walk frame `PeopleCast.walkFrame(sprite, x: x)` | the walkers' bodies, each at its pace and painted step (identical for the three townsfolk, so look 1 is untouched) |
| `Render/Renderer.swift` | `static let people` | `Set([SpriteID.archer, …, .citizenC] + PeopleCast.bodies)` | the people's sky rim in look 2 |
| `Render/PlaceholderArt.swift` | `frames(for:)`, the default chain's end | `if frames.isEmpty { frames = PlaceholderCast.frames(for: sprite) }` | stand-ins when a PNG is missing |
| `tools/grids/court/petitionerE.txt`, `petitionerD.txt` (and their PNGs) | the grids (built by `build-art-court.sh`) | petitionerE repainted (Master Edwy: felt cap, brown gown, leather apron with tallow drips, no velvet, fur or gold); petitionerD recoloured (undyed shawl, soot-grey dress, bread only) | nobody in town finer than a neighbour |
| `Core/CourtSpeakers.swift` | `Speakers.townsfolk` | `folk("child", .childC, …)` (was `.citizen`), `folk("noble", .nobleLord, …)` (was `.petitionerE`), and the comment above | the child petitioner walks as Fen, the noble as Ser Aubrey's kind; neither sits on the benches |

| `Tests/LookGoldenTests.swift` | `golden`, and the comment above it | `square-morning` 48f861adaf7d4de4 (was c0ba9a8be11ba03e), `town-noon` 72f6c186577a8bc6 (was e0e4b0352af35485), recorded from round lh-p1-2 | look 1 walks the repainted townsfolk; its drawing is unchanged. At the join: if the rebuilt town changes these scenes anyway, record them again from the join's round |

The rebuild lanes rewrite `EntityFrames` and the town: at the join, wherever the rebuilt town draws its walkers by day,
call `PeopleCast.townLife` once and take the walkers' bodies, pace and step from `PeopleCast` (`townWalkers`,
`pace`, `walkFrame`). Everything else of the lane is in its own files.

### Rounds

- **lh-p1-1** (9d30f44; build, unit, ui PeopleUITests): the test build failed: `Renderer.people` is main-actor
  isolated and the new contract test read it from a nonisolated test. Fixed (its own `@MainActor` test).
- **lh-p1-2** (289e3d0; build, unit, ui PeopleUITests): build passed; unit failed only in `LookGoldenTests`, the two
  town scenes of look 1 (square-morning, town-noon), as expected from the repainted townsfolk (all eight
  `PeopleCastTests` passed); the UI filter was named wrong (it is `LanternholdUITests/PeopleUITests`). The two hashes
  were recorded again (b452f81).
- **lh-p1-3** (b452f81; build, unit, ui, ui-de, release): **ALL PASSED** (build 16:21, unit 16:29, ui 16:55,
  ui-de 17:18, release 17:25 runner time). The shots 130-133 in English and German, upright copies in the worktree's
  `ci-out/people/shots/`: the square at 10:29 (Wenna wringing at the well, the children, Fen behind the lord), Gorm at
  his hoe on the near field at 09:29 with Corra and Hemmet walking by the house, Gorm straightened and turned to the
  lord passing the field, the square at 15:11 with Corra walking.

### Proof (ci-out/people in the worktree, git-ignored)

- `lineup-day.png`, `lineup-dusk.png` (6x, nearest neighbour) and `lineup-phone.png` (3x): left to right the lord, a
  guard, the footman beside him, the lord and the lady of the inner lands, Fen facing Old Hemmet, Nib facing Wenna,
  Wren, Gorm, Hedda, Brede, Mother Corra, Dun, Ned, Master Edwy, Ilse; standing on the valley's earth lane before
  the town's houses. The light is an approximation of the renderer's (albedo times the hour's ambient, a warm pool
  round the lord at dusk).
- `strips/`: one strip per walk and per work (the frames in a row, under them the footprints advanced by the stride).
- `zoom/`: every sheet at 800 %.

### Open, and what waits for the join

- `nobleLady` and `footman` are drawn and registered but not placed: they wait for the hall's spot where a noble
  stands apart with a footman (the stage lane, its notes 14:20) and for the footman paying at the doors (TOWN.md 6).
- The town lane builds its poses (the household in the doorway, the farmer counting coins from a knotted cloth into the
  lord's hand, the child running out with the coins) on these bodies: fetch this branch.
- Two of the twelve still wear their old bodies, `builder` and `guardsman` (and the archer), and Ilse's scarred hands
  are not drawn yet; PEOPLE.md gives each its mark for the repaint.
- The six other languages: no strings in this step.
- Judged at phone size in the running game: the groups read (the farmer's hat and hoe, the children's size and red,
  the lord), but the square is the town's busiest spot: Wenna at the well, three children lapping it and Fen at the
  lord's heels crowd round the well when the lord stands there (shot 133). If the rebuilt square has more room, move
  Wenna a few px off the notice board and widen the children's laps.
- The art is simple, hand-set and of one vocabulary with the base game's townsfolk; it is not yet at the level of the
  best sprites in the game. The washerwoman's wring and Hedda's mow are the weakest poses at 400 %.

## people-1, fix round 1 (the critic's look 1: six highs, no blocker)

### What changed

- **H1, the children are the bright thing:** Nib's (was Pim) tunic washed white (`foam`, `parchment`, `plaster`: a
  value step above any grown-up's cloth) with the whole red kerchief and a red patch; Wren's red pinafore over a clean
  linen smock; Fen's jerkin oiled a step lighter over a linen collar. `crimsonLight` is the children's alone: the
  nobles' and the footman's lit crimson is `dusk` now.
- **H2, the marks:** Wenna's bare red elbow and forearm laid across the linen of the basket on her hip (her shins
  weathered, not red); Dun's whole near forearm and hand in a 2 px linen rag; Hedda bareheaded, her white crown,
  fringe and plait on a brown bodice.
- **H3, the silhouettes:** Brede's beam angled on the far shoulder, back end high, near hand up under it; the lady's
  cloth at her chest in the walk and pressed inside her face's outline in the idle; Gorm's hoe a thin edge-on blade
  with a lit edge in every pose.
- **H4, the work poses:** the mow with the snath across Hedda's body, back swing (blade behind the heels) and
  through swing (blade before the feet), the upper body a pixel each way, the apron straight (`skirtWork`); the
  upright scythe's blade curved over her head; the wring a twisted sheet held level between two red fists, its
  banding moving on a pixel, a drop falling.
- **H5, the names:** Pim is Nib Brisk, Aldo Fenn is Ned (surname since changed, now Furrow; checked against STORY.md, the docs and the
  petitions: no Nib or Ned anywhere; Odo was close to Odile, Wat is a recruit name in YARD.md).
- **H6, the director's notes:**
  - cloth states for the eight working bodies and the three seated forms (village and town) and the three children
    (town), cloth pixels only (`tools/peoplestates.py`, `#@state` lines in the grids; PEOPLE.md section 7 says what
    each wears at each stage; SPRITES-people.md "Cloth states"); the six-figure line-up in all states;
  - the nobles' bow (frames 8-9 of `nobleLord` and `nobleLady`), played only when the realm is a town
    (`PeopleCast.bowFrame`; PEOPLE.md section 4);
  - the collector (Saul, now Tolliver), the lamplighter (Silas Moth) and the jailer (Old Kell) in PEOPLE.md with name, mark,
    silhouette and frames. Their sheets open people-2 (see "What waits").
- **Smaller things of the critic:** Wenna on the well's far side from the notice board, facing it; the children's laps
  120 px with their centres spread; Gorm and Hedda side by side on the first field (shot 131 frames both);
  `DayClock.secondsPerHour` instead of a copy; Brede's rag foot a step darker on its shadow side; Ned's bald crown
  shaded weathered brown instead of salmon.
- **Code:** `PeopleCast.ClothState` (from the standing), `wardrobe`, `dressed`, `body(dressedAs:)`, `dressedBodies`,
  `launchCloth` (`-GWCloth village|town`, read once in PeopleCast so DebugArgs stays untouched), `townLife(cloth:)`,
  the walkers dressed, `pace` and `stride` through the body; tests for the states (alpha frame by frame), the bow and
  the unclamped atlas height; UI shots 134-135 (the square and the field in the town's cloth).

### New hooks in existing files (add to the table above at the join)

| file | place | the hook | why |
|---|---|---|---|
| `Core/FrameDesc.swift` | `enum SpriteID`, after the cast's case line | two `case` lines with the 25 state ids and their comment | the ids (the PNG names) |
| `Core/FrameDesc.swift` | `var size`, after the cast's case | `case .citizenVillage, … .childCTown: return PeopleCast.size(of: self)` | the switch is exhaustive; PeopleCast answers with the body's size |
| `Core/FrameDesc.swift` | `var frameCount`, after `if isCourtBody { return 8 }` | `if let body = PeopleCast.body(dressedAs: self) { return body.frameCount }` | a state has its body's frames |
| `Render/Renderer.swift` | `static let people` | `+ PeopleCast.bodies + PeopleCast.dressedBodies` | the people's rim for the states |

No new hook in `EntityFrames`: `PeopleCast.townWalkers` and `townLife` dress themselves from `launchCloth`.
**At the join:** pass the realm's stage: `PeopleCast.townLife(s, time: time, cloth: PeopleCast.ClothState(standing:
<the town's standing>))`, and dress the walkers the same way (`PeopleCast.dressed(body, state)` in place of
`townWalkers`' launch value); the hall's seated petitioners (`CourtLayout.seatedStrip`) take
`PeopleCast.dressed(.citizenSeated, state)` and its kin; a noble who comes before the lord plays
`PeopleCast.bowFrame(sprite, state:, sinceArrival:)` before the talk.

### Rounds (fix round 1)

- **lh-p1f1-1** (b5a4a91; build, unit): build passed; unit failed in two places, both expected or mine: every
  `SpriteID` needs a non-empty stand-in (`AtlasTests.testEveryPlaceholderDrawsSomethingAtItsSize`: the 25 states had
  none), and look 1's two town scenes changed (Dun's rag and Ned's crown walk there). All ten `PeopleCastTests`
  passed, the new state, bow and atlas tests among them. Fixed: a state stands in as its body; the two hashes
  recorded again (5427d45).
- **lh-p1f1-2** (5427d45; build, unit, ui, ui-de, release): build, ui, ui-de and release passed; unit failed only in
  the stand-ins of the townsfolk's states (their stand-ins live in PlaceholderArt's own chain, not in PlaceholderCast);
  the goldens passed. Fixed (f5983d6). Shots 130-135: the children read on the well's stones (Nib white with red,
  Wren's red pinafore, Fen's cap), Wenna wrings on the well's far side, both farmers in 131, the town's cloth in the
  running game in 134-135 (Gorm green, Hedda and Corra madder, Wenna indigo, Fen's blue breeches).
- **lh-p1f1-3** (f5983d6; build, unit, ui, ui-de, release): **ALL PASSED** (build 21:33, unit 21:40 with 421
  tests, ui 22:04, ui-de 22:27, release 22:33 runner time). The atlas: 2048 wide, **1850 of 2048 rows used**
  (`atlas-rows.txt`): the join has about 200 rows; if it needs more, the 11 village strips go first.
- After it, art only: Brede's beam a pixel lower and in weathered brown timber (003cb84, b47168d; same size and frames,
  not in look 1, no test reads it). **lh-p1f1-4** (a6fa830; build, unit, ui PeopleUITests): **ALL PASSED** (build
  22:47, unit 22:55, ui 22:57): the head confirmed, the final shots 130-135. Upright copies in the worktree's
  `ci-out/people/shots-fix1-final/` (and of lh-p1f1-3 in `shots-fix1/`); the proof sheets in `ci-out/people/`
  (`lineup-day`, `lineup-dusk`, `lineup-phone`, `lineup-states`, `lineup-states-2`, `lineup-states-phone`,
  `fix1/strips/`, `fix1/*.png` at 800 %).

### What waits (people-2 and the join)

- **The collector's and the lamplighter's sheets** (PEOPLE.md section 2, "Three more"): the first work of people-2
  with their rounds (the director's 14:45 note puts the rounds there; the figures are named and specified now). The
  collector needs a wider frame for the handcart; the lamplighter a glow strip for the pole's tip. Director: please
  confirm that the sheets open people-2.
- **The court's ties** (15:03): one idle per court member that can be played toward another person (a nod, a turned
  shoulder, something handed over). The court sheets are existing files that the stage lane's hall may repaint; people-2.
- **The lord's cloak in two states** (14:35) and the lord as the heir of the guardian house with a circlet that fits
  (15:03): a repaint of `king`/`lady` and their seated forms (existing sheets, `kingGlow` anchors): people-2, after the
  director says which lane owns the lord's sheet now.
- The jailer (Old Kell), the first widow, the brother with the bow, the straw lord, the tally-board pose, the lantern
  moment and the soldier looks: build 3, people-2 (the director's notes 15:44 to 18:26).
- A running-game shot of a noble in the hall: the hall is being rebuilt by the stage lane; the noble petitioner walks
  as Ser Aubrey there today but no UI test reaches him without driving an audience. At the join.
- The look-1 golden hashes were recorded again (Dun's rag and Ned's crown are in look 1's town); record again at the
  join if the rebuilt town changes those scenes.

## people-2: the town lives by its people

Picture only: no rule of the simulation changes; T1 to T8 and every simulation test untouched (nothing under
`Sim`, `Economy`, `Battle`, `Balance` or `GameState` was edited). Rounds by the director's notes of 14.11. 18:46 and
19:35 (short rounds, English only: no `ui-de`, no `release`; the round guard of 10f5539 is on this branch now, the
critic's H4).

### What exists

- **`Core/TownHouseholds.swift`, who lives where** (data only). Four households, nobody twice: house 1 (Mother Corra,
  Ned Furrow, Brede Hask; Ilse Marrow in a big house), house 3 the Ashbys (Gorm, Hedda, Wren), house 4 the Brisks
  (Wenna, Nib, Dun Rook lodging; Master Edwy Tallow in a big house), house 5 Moth's (Silas Moth the lamplighter, Fen his
  grandson, Old Hemmet); the collector Saul Tolliver lodges by the hall door. A household is out only while its house
  stands. Each passer-by has a place (the well, the market, the tavern, the ford, the castle's gate, the far field).
  Anchors as data: the doors (the plot's centre, as the town lane's `Town.doorX`), the places, the bench, the town's
  gate (`townGateX`, on this branch before the castle's back gate).
- **`Core/TownLife.swift`, the day** (pure functions of the state, the hour and the picture's time): the farmers on the
  first built field (out at first light 05:30, eight strokes and the pause that straightens the back, home at a tired
  pace, in by 18:51); Wenna at the well and at the horn in her doorway calling the children in; Old Hemmet on the bench
  (07:24-17:36, a doze now and then); the passers-by (as many as the taxpayers allow; out from 07:00, home from 18:30
  from wherever they are); the children (none below 45 happiness, Nib and Wren from 45, Fen too from 80; out from 08:00,
  laps, Wren's skip, the stick fight, Fen's wider laps, one trailing the lord a few steps and falling back, home at the
  horn each to its own door, all in by 19:40, never at night); the noble's coach and the footman on a day a noble guest
  is due (the court's queue or today's heard petitions: speakers `noble`, `lorenzPell`, `ebbaCalder`), the townsfolk
  30 px wide of it; the collector's round (out at the dawn, a stop at every door, the farthest by 09:00, back by noon,
  at his post until the horn). Whoever stands still turns to the lord within 36 px (they straighten or nod), below 30
  happiness turns away; nobody inside a castle room with a front unless the lord is in it. Reduce Motion: nobody is
  removed, breaths and fidgets hold a frame, the sticks stay raised, the wring at half rate.
- **`Core/TownLamps.swift`, the lamplighter and the street lanterns**: the evening round (in at the hall's chapel door,
  the wick into the Eternal Light, the bow, out through the castle's gate, the four lanterns one by one, the last as the
  horn sounds, home), the morning round from 05:00 (snuffing back toward the castle), counted back from the horn from
  the anchors and his pace (in the hall at 14:38, the lanterns lit at 16:55, 17:55, 18:20 and 19:00, snuffed at 05:13,
  05:51, 06:15 and 07:13, in at the castle's gate by 07:53). Each lantern's share (a flare as it takes the flame, none with Reduce Motion), times the hearth's glow
  (bright 1, low about 0.7, embers about 0.45, out: dark); dark in unrest (below 15). The glass glow and the pool are
  drawn here (`TownLamps.light`), the pole's small flame as a glow strip and a little candle light at dusk.
- **Art** (hand-set part grids through `tools/actorart.py`, `tools/build-art-people.sh` rebuilds them; proofs in the
  worktree's `ci-out/people/p2/`): `lamplighter` + `lamplighterGlow` (36x30, 12 frames; the poles are clean lines
  between hand-picked points, written into the grid by `tools/lamplighterpoles.py`), `collector` (34x24, 8), `coach`
  (60x34, a prop, laid out by `tools/coachgrid.py`, drawn mirrored to face the gate), `elderSeated` and its two cloth
  states (12x22, 2), Wenna's call frames 8-9, Nib and Wren 12 wide with the stick fight 10-11, Nib's kerchief knotted
  at the nape with its ends flying (the critic's H2: no red on the throat or belly any more), the noble lord's cane
  kept in the talk and the bow.
- **Names** (the critic's H1 and a smaller note): Ned is Ned Furrow, Saul is Saul Tolliver (the director's names of 15.11.; both checked
  against STORY.md, the docs, both string catalogs and the petitions of the planning branch: no hit).
- **Tests**: `Tests/TownLifeTests.swift` (15 tests: the households, the farmers' day, the greeting and the turning away,
  Wenna's call, the children's rules, game and trailing, the coach and the berth, the collector's round, the lantern
  times and shares, the hearth leg and the glow strip, look 1's lanterns, Reduce Motion, the figure count, the shots'
  moments); `Tests/PeopleCastTests.swift` brought to the new contract.
- **UI**: `UITests/TownLifeUITests.swift`, shots 70-fields-morning, 71-square-noon, 72-children, 73-dusk-home,
  74-noble-coach, 75-lamplighter-dusk, 76-collector-morning (the director's 14:45 note) and 77-lamplighter-hearth (the
  15:19 note), English only (the 19:35 note: German is not looked at before the store pass).

### The hooks in existing files (people-2; apply them again at the join)

| file | place | the hook | why |
|---|---|---|---|
| `Core/FrameDesc.swift` | `enum SpriteID`, after the cloth states' case lines | `case lamplighter, lamplighterGlow, collector, coach, elderSeated, elderSeatedVillage, elderSeatedTown` with its comment | the ids (the PNG names) |
| `Core/FrameDesc.swift` | `var size`, after the cloth states' case | `case .lamplighter, … .elderSeatedTown: return PeopleCast.size(of: self)` | the switch is exhaustive |
| `Core/FrameDesc.swift` | `var frameCount`, after the cast's case | `case .lamplighter, .lamplighterGlow, .collector, .coach, .elderSeated: return PeopleCast.frameCount(of: self)` | frame counts live in PeopleCast |
| `Core/EntityFrames.swift` | `actors(…)`, where people-1 called `townsfolk` and `townLife` | `if look == .two { PeopleCast.townLife(s, time:, context: TownLife.Context(reduceMotion:, hearth:)) { add($0.sprite, frame: $0.frame, x: $0.x, y: 0, flipped: $0.flipped, emissive: $0.emissive) } } else if isDay { townsfolk(…) }` (replaces people-1's two calls; look 2 now draws the town at every hour, the lamplighter and the run home are at dusk) | the town's day in look 2 |
| `Core/EntityFrames.swift` | `layer(…)`, after `town(s, look:, props:)` | `let townDay = TownLife.Context(reduceMotion:, hearth:)`; `if options.look == .two { TownLife.props(s, context: townDay, props: &props) }` | the bench and the coach |
| `Core/EntityFrames.swift` | `layer(…)`, after `var lights = SceneFilter.sceneLights(scene)` | `TownLamps.light(s, look:, context: townDay, torch: ambient.torchStrength, animTime:, glows: &layer.glows, lights: &lights)` | the lanterns' glass and pools, the pole's flame |
| `Core/SceneFilter.swift` | `gameScene`, before the hearth's strip | `if TownLamps.isStreetLantern(prop) { strip emissive and lights; keep the post }` | the street lanterns burn as the lamplighter lit them (look 1 gets them back at full share, as before) |
| `Render/PlaceholderCast.swift` | `frames(for:)` | a case for the five new bodies (the townsfolk's figure on the frame's canvas; the coach a plain block) | every SpriteID needs a stand-in |

People-1's hooks stay as listed above, except `EntityFrames.townsfolk`'s look-2 branch, which look 2 no longer calls
(`PeopleCast.townWalkers` is kept for it). `Renderer.people` takes the new bodies through `PeopleCast.bodies`.

### For the join: how each behaviour hooks to the rebuilt town

- **One call per frame.** Wherever the rebuilt town draws its people (look 2, every hour), call
  `PeopleCast.townLife(s, time:, context:) { figure in … }` once and draw each figure (`emissive` for the lamplighter's
  glow strip); add `TownLife.props` to the town's props and `TownLamps.light` to its lights and glows.
- **The context**: `TownLife.Context(cloth: PeopleCast.ClothState(standing: <the town's standing>), reduceMotion:,
  hearth: <front-2's hearth level 0 … 1; out is 0>, collectorOut: Town.collectorWalksToday(s), nobleDue: nil)`.
  Until then the launch arguments stand in: `-GWCloth`, `-GWCollector YES`, `-GWCoach YES`.
- **Anchors to replace** (all in `TownHouseholds` and `TownLamps`, data only): the house doors (`door(plot:)`, from the
  rebuilt houses' door anchors), the passers-by's places (`spot`), the bench (`benchLeft`, `benchSeat`), the town's
  gate (`townGateX`: where the road from the inner lands meets the town), the street lanterns (`posts`, `glassDX`,
  `glassDY`, `lightDX`, `lightY`, `lightRadius`: the world lane keeps about four posts with an unlit and a lit state
  as anchors; `TownLamps.share(i, …)` says how lit post `i` is), the hall door and the hearth stand (`hallDoor`,
  `hearthStand`), the castle's gate (`gate`), the play's centre (`TownLife.playCentre`, clear of the well by 30 px or
  more). The lamplighter's times follow from them by themselves.
- **The lanterns' sprite state**: where the rebuilt posts have an unlit and a lit sprite, take the lit one while
  `TownLamps.share(i, …) > 0` and drop `SceneFilter`'s strip; keep `TownLamps.light` for the glow and the pool.
- **The collector**: the town lane's sim holds where he is (`Town.collectorX`: an even pace, post at 06:00, the turn at
  09:00, back at 12:00). The picture follows the same hours and stops 1.5 s at each door on the way out (it leads the
  sim by up to 6 s between the stops). Either make the sim stop at the doors too (`TownLife.doorStop`) or draw the
  picture at `Town.collectorX` and play the take frames while he passes a door. His post is the town lane's
  `Town.collectorPost` (`Realm.hallX`); a touch on him there is the town lane's.
- **The lord passes**: `TownLife.greeting` reads only the lord's x and the happiness; the town lane's toss at the doors
  is its own picture (TOWN.md section 1) and does not collide with it.
- **The rooms**: `TownLife.isSeen` hides a figure inside the hall, chapel or kitchen while the lord is not in that room
  (a hard cut, no fade). The stage lane's rebuilt hall may give its own rule; the lamplighter at the hearth then follows
  it (or takes the `RoomFades` alpha as the court's figures do).

### The hall side of a noble's day (waits for the join)

- The noble guest walks from the coach to the hall: when the petitioner whose speaker is in `TownLife.nobleSpeakers` is
  called, he comes in at the hall's door with the footman a step behind (`PEOPLE.md` section 4); while they are in the
  hall, `TownLife.footman` should return nil (one footman body): pass a `footmanWithGuest` flag in the context.
- In the realm's third stage the noble bows on arriving (`PeopleCast.bowFrame`), then talks; in the hamlet and the
  village he does not.
- The footman stands apart in the hall's spot for a noble's servant (the stage lane, its notes 14:20), the chest held
  level; he pays (`footman` frames 6-7) when the noble grants or buys something.
- When the audience is over they walk back out; the coach stays until the dusk (`TownLife.coachHours`), or leaves at the
  audience's end if the stage lane prefers: then `coachSpan` takes the end time.
- The lady (`nobleLady`) comes in the coach on the days of `calder_audit` (Ebba Calder) or as the hunting noble's kin;
  her hall spot is the stage lane's.

### Rounds

- **lh-p2-1** (2525c3e; build, unit, ui TownLifeUITests PeopleUITests): build passed (the new files compiled at the
  first try), both UI classes passed (shots 70-77 and 130-135); unit failed in two places: look 1's `square-morning`
  golden moved (the street lanterns' glass is drawn by `TownLamps` with its own flicker seeds, and at 08:00 the
  morning still lights it a little; recorded again: 6cdcda6decd89f7d, was c7130032235b207b; `town-noon` and the others
  held), and my own test looked for every child running home from 19:00 although they leave a few seconds apart. The
  shots showed one real fault: Dun and Corra still walked home from the ford and the market at dusk (shot 73), so a
  passer-by now turns home early enough from a far place to be in before the horn (`TownLife.inHour`), with a test.
  Shot 73 moved so the lord stands beside Wenna's door, not on it; the children run home at 40 px/s. The atlas: **1880
  of 2048 rows** (people-1 left 1850): after the join about 1990; the eleven village strips go first if it needs room.
- **lh-p2-2** (11827b8; build, unit, ui TownLifeUITests PeopleUITests): **ALL PASSED** (build 00:29, unit 00:35 with
  every unit test of the branch, ui 00:38 runner time). The gate by the director's note of 14.11. 19:35 (one round,
  English only). Upright copies of the shots 70-77 in the worktree's `ci-out/people/p2/shots-final/` (of lh-p2-1 in
  `shots-1/`); the proofs in `ci-out/people/p2/` (`lamplighter.png` and `childA.png` at 800 %, `lamp-crop.png`,
  `kids-fight.png`, `lineup-p2.png`, `noble-cane.png`, the street crops `71-crop.png`, `72-crop.png`,
  `73-crop-final.png`, the band sheets `bands-a.png`, `bands-b.png`).
- Judged as a player at phone size: the coach with the footman beside Brede reads at once (the only saturated thing
  in the valley); the lamplighter reaching his pole to the last lantern as it flares (75) and holding the wick into the
  hearth (77) read; the collector at the Ashbys' door with his cart (76) reads; the stick fight before the Brisks' door
  with Fen at the lord's heels (72) reads; at dusk (73) the lanterns' warm pools and the children at their doors read,
  the figures are dim in the dusk light. In the demo realm the court has a noble due on day 12, so the coach stands in
  every shot of that day (the real rule, not the launch argument). In 71 the demo's build at house 5 puts its builders
  beside Hemmet's bench.

### Open, and what waits for the join

- **The court's ties** (15:03) and **the lord's cloak in two states** (14:35, 15:03): not in this step. Both are
  repaints of existing sheets (the court bodies, `king`/`lady` and their seated forms with their glow anchors) that the
  stage lane's hall rebuild touches; the director has not said which lane owns the lord's sheet.
- The lamplighter, the collector and the coach have no cloth states (the atlas keeps its room); the town's cloth
  reaches the lamplighter and the collector at the join if wanted.
- The coach has no lit lantern at night (it is gone by the dusk).
- Old Hemmet could wait on the hall's benches now (`elderSeated`); `CourtLayout.seatedStrip` is not extended (no
  petitioner walks in his body).
- The square's play is in front of house 4; if the rebuilt square has more room, move `TownLife.playCentre`.
- Saul Tolliver is pushed at the town lane's even pace (about 47 px/s out, 40 back: faster than the lord's walk). If
  the town lane can start him earlier or give him till 09:30, he walks at a cart's pace; the picture follows the hours.
- The lamplighter is in the hall at about 14:40 and walks for four hours of the clock: the castle-to-town walk at a
  walking pace cannot fit TOWN.md's "out of the gate at 18:00, the last lantern at the horn". The horn is kept (the
  last lantern lights as it sounds); the start follows from the anchors.
- Smaller keep items of the people-1 critic not done: Dun's face, Wenna's forearm pixel, Lorenz Pell's lit crimson (a
  court sheet), the close names Mother Corra / Mother Hesper.
- The six other languages: no strings in this step.

## people-2, fix round 1 (the critic's look 1: five highs, no blocker)

The critic's verdict: `ci-out/director/people-2-life-critic1.md` on the planning branch (7/10). Rounds by the
director's notes of 14.11. 18:46 and 19:35 (short rounds, English only, one gate round; no `ui-de`, no `release`).
Picture only: nothing under `Sim`, `Economy`, `Battle`, `Balance` or `GameState` changed; T1 to T8 untouched.

### What changed, finding by finding

- **Merge safety first (not a finding, found on the way):** the town lane has a `struct TownDay` (its day's ledger,
  `Core/Town/TownLedger.swift` on `claude/lh-town`); this lane's `enum TownDay` would not compile beside it. Renamed to
  **`TownLife`** (`Core/TownLife.swift`, `Tests/TownLifeTests.swift`); every note above that says `TownDay` means
  `TownLife`. `TownLife`, `LordCloak` and `CourtTies` are free on every lane branch (checked).
- **H1, the berth.** The berth now runs from 30 px short of the coach to 30 px past its footman
  (`TownLife.berthZone`). A passer-by stops at its edge and stands looking at the coach 4 s longer than at an ordinary
  end of the way (`Route.lookAt`, `coachStare`); Brede stops 30 px from the footman, turned to the coach. Whoever must
  pass on the one road (the collector, the lamplighter, and the builders through a hook in `EntityFrames.actors`)
  steps out to the near side of the road, 4 px lower, over the first 10 px inside the zone (`TownLife.lane`,
  `PeopleCast.Figure.y`), and passes in front of the footman, never through him. Shot 74 at 10:18: Brede at the
  berth's edge looking at the coach, a clear gap to the footman, no builder in the zone.
- **H2, the heavy steps.** The lamplighter walks at 16 px/s (a farmer's pace; it was 32). The collector pushes his
  cart at 18 px/s (it was about 47 out and 40 back), and a round of every door at that pace starts from a post just
  inside the castle's town gate (`TownLife.collectorPost = WorldLayout.backGateX - 40`): the farthest door about
  10:20, back about 14:10 (`TownLife.collectorHours`, from the pace and the doors). The hours wait for the director
  (below).
- **H3, the lamplighter repainted by hand** (`tools/lamplighterpoles.py` holds the hand-set parts; the grid is written
  from it): the stoop (head and shoulders forward of the hips, a rounded lit upper back), the coat narrow at the
  shoulders and flaring to the hem, a cord at the waist where the silhouette steps in and the cloth creases, the fold
  running on down the skirt, the hem swinging out on the walk's contacts and hanging straight on the passing frames
  (where the body rises a pixel and the legs lengthen under it: the old passing frames left a hole under the coat);
  the burn on the side of the neck under the ear, two pixels behind the jaw; a soft felt hat lit on the crown, its
  brim drooping two pixels over the brow; snuffing with the pole steeper and higher, ending in a bell turned mouth
  down above the lantern's cap (8) and over it (9). The flame anchors follow (walk -12.5, idle 7.5). The collector
  wears a rolled wool cap instead of a second crowned hat, and his head and shoulders bob a pixel on the passing steps
  (the smaller note). At his new hours the lamplighter's hearth moment fell where Odile stands at her lectern on the
  hearth's right (round lh-p2f1-1, shot 77: they merged), so he now takes the Flame from the hearth's left, facing it
  (`TownLamps.hearthStand = WorldLayout.hearthX - 4`).
- **H4, the director's 14:35 and 15:03 items.** The notes are written to this lane (`notes-people.md`), and a note
  wins over the brief, so this lane owns them; no other lane branch touches `king`, `lady`, their seated forms or the
  court's sheets (checked on every `claude/lh-*` branch; only the town lane adds `kingKnock`/`ladyKnock`).
  - The lord's cloak in two states (`Core/LordCloak.swift`, `tools/lordcloak.py`, grids `kingMended`, `ladyMended`,
    `kingSeatedMended`, `ladySeatedMended`): mended in the hamlet and the village (the teal faded to the town's old
    house colour `waterDeep`, a paler patch on the back, a darned tear), good in the town (the sheets as painted).
    Only cloak pixels change (a test holds alpha and the share); no glow strip of their own. The renderer paints the
    lord's actor from the mended texels in look 2 (`Renderer.quad`), so the frame's actor stays `king`/`lady`.
  - The court's ties (`Core/CourtTies.swift`, `tools/courtties.py`, grids `<member>Tie`): one idle of two frames per
    court member, played toward another person: a nod, then the thread (Odile's ledger, Brannock's key, Pip's ball,
    Hesper's hand on her heart, Tamsin's bowl, Bram's mended clasp, Marek's orange, Seren's coin). Separate sheets of
    the members' own size; Hesper's and Seren's carry glow strips (`hesperTieGlow`, `serenTieGlow`). PEOPLE.md section
    8 says who turns to whom.
- **H5, the shots.** 73-dusk-home is the walk home at 18:00: Gorm with the sack and Hedda with the sheaf at a tired
  pace on either side of the lord, the children still at play, the evening light readable. The horn is 78-horn-call
  (the old 73). 79-sullen-town: 25 happiness, the lord between the two farmers, who work on with their backs to him
  (Wenna below 30 now wrings on with her back turned too). The ordinary day's shots keep the coach away
  (`-GWCoach NO`; the demo realm has a noble due on day 12), 74 brings it (`-GWCoach YES`).
- **Smaller notes done:** the children's stick is three pixels raised and thrust alike; Old Hemmet's stick knob rises
  between his cape and his beard and the cape beside the beard is a shade darker; the figure-count test is named for
  what it counts (`testTheTownsFigureCountStaysSmallWithEveryoneOut`; the frame time is measured at the join).

### The hours: the director's ruling, asked (H2)

One game hour is 12 s, the town's distances are long, and the critic asks for a heavy step and for the director to
set the hours rather than bend the walk. The code keeps every time as data that follows from the anchors and the pace
(one constant each), so a ruling is a one-line change.

- **The lamplighter** (16 px/s; the hearth to the last lantern is about 1300 px, the first to the last lantern 600 px:
  3.2 h of the clock at any heavy step). Built now, the critic's fix "start him earlier": the last lantern at the
  horn as TOWN.md says, so he is in the hall about 10:50, at the Flame about 11:20, the lanterns at 15:20, 17:10,
  17:50, 19:00; mornings 05:00 to 10:15. Bent: "every dusk he comes into the hall" becomes "every day before noon".
  The alternative: he takes the Flame about 15:30, leaves the castle's gate at 18:00 (TOWN.md's hour) and lights the
  lanterns from 19:05 into the night (the last about 22:45), each flare seen against the dark; bent: the last no longer
  burns as the horn sounds, and he is out in the town at night (the Gloom does not reach it). One constant
  (`TownLamps.eveningStart` counted from a gate hour instead of the horn).
- **The collector** (18 px/s). From the town lane's post by the hall door (`Town.collectorPost = Realm.hallX`), every
  door and back takes about 13.5 h: no fit before the horn. Built now: his post by the castle's town gate, out at the
  dawn, the farthest door about 10:20, back about 14:10, the gold arriving then. The town lane's sim follows at the
  join with `Town.collectorPost` and `TownRules.collectorTurnHour`/`collectorBackHour` (values only; the reference
  bots collect at dawn, so T1 to T8 hold). The alternative: keep the hall door, set out at first light (05:00), the
  farthest door about noon, back about 18:45, the gold arriving near the horn.

### New hooks in existing files (fix round 1; apply them again at the join)

| file | place | the hook | why |
|---|---|---|---|
| `Core/FrameDesc.swift` | `enum SpriteID`, after people-2's case line | `case kingMended, ladyMended, kingSeatedMended, ladySeatedMended` and `case odileTie, brannockTie, pipTie, hesperTie, hesperTieGlow, tamsinTie, bramTie, marekTie, serenTie, serenTieGlow` with their comment | the ids |
| `Core/FrameDesc.swift` | `var size`, after people-2's case | `case .kingMended, …: return PeopleCast.size(of: self)` and `case .odileTie, …, .serenTieGlow: return CourtTies.size(of: self)` | the switch is exhaustive |
| `Core/FrameDesc.swift` | `var frameCount`, after people-2's case | `case .odileTie, …, .serenTieGlow: return CourtTies.frameCount` (the mended sheets take their body's count through `PeopleCast.body(dressedAs:)`, which the switch asks first) | two frames per tie |
| `Core/EntityFrames.swift` | `actors(…)`, people-2's look-2 call | `add($0.sprite, …, y: $0.y, …)` instead of `y: 0` | the near side of the road |
| `Core/EntityFrames.swift` | `actors(…)`, before the builders' loop and in its `add(.builder, …)` | `let berth = look == .two ? TownLife.berthZone(s) : nil` and `y: TownLife.lane(at: x, berth)` | the builders keep the berth |
| `Render/Renderer.swift` | `static func quad(_:layout:look:)`, its first line | `let painted = look == .two ? LordCloak.dressed(actor.sprite, PeopleCast.launchCloth) : actor.sprite` and `layout.cell(painted, frame:)` | look 2 paints the lord's actor from the mended twin's texels; the actor stays the lord's (round lh-p2f1-2: a pass over the actor list broke `LordEntryTests`, which look for `.lady` and `.ladySeated` in the frame) |
| `Render/PlaceholderCast.swift` | `frames(for:)`, after the cloth states' line | `if let member = CourtTies.member(of: sprite) { return Array(PlaceholderArt.frames(for: member).prefix(CourtTies.frameCount)) }` | every SpriteID needs a stand-in |

In this lane's own files: `PeopleCast.body(dressedAs:)` also answers for the mended sheets (`LordCloak.body(of:)`), so
their size, frame count and stand-ins follow the lord's; `PeopleCast.Figure` has `y`.

### For the join

- **The rename:** `TownDay` (this lane) is `TownLife`; the town lane's `TownDay` stays theirs.
- **The berth** on the rebuilt road: `TownLife.berthZone` reads the coach's span (`TownHouseholds.townGateX`) and
  `footmanGap`; re-apply the builders' two lines wherever the rebuilt town draws its builders (or any other walker of
  the realm that passes the gate), and pass `TownLife.lane` as the actor's y.
- **The lord's cloak:** `Renderer.quad` reads the stage from `PeopleCast.launchCloth`; at the join pass the realm's
  stage instead (`PeopleCast.ClothState(standing: <the town's standing>)`, e.g. through the frame options). The town
  lane's `kingKnock` and `ladyKnock` need a mended twin each (`tools/lordcloak.py` writes one from their grid in a
  minute, and `LordCloak.mended` takes the pair) or the knock is drawn in the good cloak until then.
- **The court's ties:** the rebuilt hall draws `CourtTies.sheet(for: member)` with `CourtTies.frame(since:reduceMotion:)`
  while two tied members face each other (or a member faces the lord or the lamplighter, PEOPLE.md section 8), mirrored
  toward the other, and Hesper's and Seren's glow strips (`CourtTies.glows`) where their own glow strips are drawn.
- **The hearth anchor:** the lamplighter stands at `TownLamps.hearthStand` (the hearth's left, facing it); the rebuilt
  hall's anchor replaces it, and his times follow by themselves.
- **The collector's post and hours** and **the lamplighter's hours**: the director's ruling above.

### Rounds (fix round 1)

- **lh-p2f1-1** (ec8d8ec; build, unit TownLifeTests PeopleCastTests, ui TownLifeUITests): **ALL PASSED** (build 01:22,
  unit 01:23, ui 01:25 runner time). The shots showed 74 with Brede at the berth's edge and a clear gap to the
  footman, 73 the walk home with the harvest, 79 the sullen farmers; and one real fault: at the lamplighter's new hour
  Odile stands at her lectern on the hearth's right, and the two merged in 77, so he now takes the Flame from the
  hearth's left.
- **lh-p2f1-2** (6c9bdea; build, unit, ui TownLifeUITests PeopleUITests): build and both UI classes passed; unit
  failed in three `LordEntryTests`: the pass over look 2's actors renamed the lord's actor, and those tests look for
  `.lady` and `.ladySeated` in the frame. The dressing moved into `Renderer.quad` (the texels only). The atlas: **1890
  of 2048 rows** (people-2 left 1880; after the join about 2000; the eleven village strips go first if it needs room).
- **lh-p2f1-3** (9a34df0; build, unit, ui TownLifeUITests PeopleUITests): **ALL PASSED** (build 02:13, unit 02:22 with
  every unit test of the branch, ui 02:27 runner time). The gate by the director's note of 14.11. 19:35 (one round,
  English only, no `ui-de`, no `release`). Upright copies of shots 70-79 in the worktree's
  `ci-out/people/p2f1/shots-final/`; the proofs in `ci-out/people/p2f1/proofs/` (the lamplighter at 800 %, the
  lamplighter and the collector beside the townsfolk, the two cloaks side by side, the court's ties, a crop of 74).

### Open, and what waits

- The director's ruling on the hours (above).
- Smaller notes not done: Nib's white tunic on the cream plaster in 72 (the play stays before the Brisks' door); a
  hitching rail or a horse's nose for the coach; one short walk of the lord in the UI test with three stills (the
  shots set the camera per still, and `-GWFreezeTime` holds the clock, so the greeting and the trailing are proven in
  unit tests and shown in still poses); the demo's builders by Hemmet's bench in 71 (the demo raises house 5; the
  bench stands before Moth's house where Hemmet lives).
- The lamplighter at the hearth and Odile: the court's round is the same each day from the dawn, so at these hours she
  stands at her lectern on the hearth's right every day while he holds the wick into the Flame from its left. If the
  director moves his hours, the phase moves with them (she also stops by the throne, 8 px from his stand); the rebuilt
  hall's anchor settles it.
- The six other languages: no new strings in this round.

## The director's fix pass (15.11.2026, his note of 03:39)

The lane's two steps passed their critics at 8 of 10; the director looked at the pictures himself and ruled on what was
still open (`ci-out/director/notes-people.md` on the planning branch, the note of 15.11. 03:39). Picture only, as
before: nothing under `Sim`, `Economy`, `Battle`, `Balance` or `GameState` changed.

### What changed, point by point

1. **The lamplighter's dusk, a rule in data** (`TownLamps.plan(for:)`, `TownLamps.Anchors`; held for today's anchors and
   for longer and shorter towns by `TownLifeTests.testTheLamplightersEveningKeepsTheDirectorsRuleForAnyTown`): no
   street lantern takes the flame before 17:00 and the last takes it as the horn sounds; he takes the Flame between
   16:00 and 16:30 and never before 15:30; the round between the posts at the heavy step (16 px/s); the way from the
   hearth to the first post with the lit pole on the shoulder at up to the lord's pace (36 px/s, slower when the hour
   allows; if even 16 px/s leaves time, he waits at the first post with the lit pole, idle frames); home after the
   last post at up to 36 px/s. Counted back from the horn; what does not fit is cut in the note's order: (a) the far
   posts (as many from the castle's side as the time from 17:00 to the horn allows), (b) the hearth beat earlier, to
   15:30 at the earliest; if he still cannot reach the first post, one more far post goes. The posts he does not reach
   stay dark (`share` 0) in look 2; look 1's lanterns are as before.
   - **With this branch's anchors he reaches one post** (house 1's, at 2548): the second (2868) would need the Flame
     at 15:14. In the hall about 15:54, the Flame at 16:30, the shouldered walk at about 26 px/s, the lantern at 19:00
     with the horn, home about 20:26; the morning's snuff about 06:22, in at the castle's gate about 07:39.
   - **The reach for the join** (the town lane sets its posts inside it): with the Flame at 15:30 at the earliest and
     `d` px from the hearth stand to where he stands at the first post, the round from the first post to the last
     must fit `min(24, 37.5 - d / 36)` seconds, each further post costing `gap / 16 + 2` s. Today `d` is 670 px, so
     three posts need the first and the third within about 238 px of each other, four within about 206 px; with the
     Flame inside 16:00-16:30 it is about 142 px for three and 110 px for four. Moving the first post nearer the
     castle's gate gives the round more time (1 s for every 36 px). His door should stand near the last post, or he
     walks home after the horn (today until about 20:26).
   - PEOPLE.md says "dusk" everywhere and carries the rule. The shots: 75 is now `75-lamplighter-gold` (him lighting
     the lantern as it takes the flame, camera 2560; the only lighting today is at the horn, in the sunset's light,
     19:00 lies between the `sunset` key at 18.8 and `dusk` at 19.5), 77 at 16:625 (the bow to the Flame in the late
     afternoon's light), 78 at the horn with camera 2738 (Silas at the lantern he has just lit, Wenna calling from her
     doorway, the children running home). The old 75 (the far post at 3080) no longer shows him.
   - Build 3 (not here): the lit street grows with the realm (hamlet 3 posts, village 5, town 7); from the village on
     Fen runs a taper from Silas' pole to the far posts.
2. **The collector stays as built.** **At the join the town lane moves `Town.collectorPost` from the hall door
   (`Realm.hallX`) to just inside the castle's town gate** (`TownLife.collectorPost = WorldLayout.backGateX - 40`) and
   takes `TownLife.collectorHours` (the farthest door about 10:20, back about 14:10) into
   `TownRules.collectorTurnHour`/`collectorBackHour`. He is the morning's figure and the lamplighter the evening's;
   they never share the road.
3. **Names:** Ned Furrow and Saul Tolliver in the docs, the comments and `TownHouseholds.collectorName`; no old name
   is left anywhere in the game folder (grep).
4. **Nib** (`childA`, both cloth states): the red kerchief tied round the back of the neck, its knot and ends a small
   clean triangle on the chest, the throat under the chin white; the flying ends behind him are gone; no red on the
   belly; a small square grey patch (`stoneLight`) with a dark seam (`stone`) at the knee; the tunic `foam` with a cool
   shade (`mistLight`) instead of cream, so it stands off the houses' plaster. `crimsonLight` stays the children's
   alone (Lorenz Pell's is `dusk` now, point 7).
5. **The square:** no child comes within 14 px of Wenna's outline at the well, the trailing child included
   (`TownLife.wennaGap`, `clearOfWenna`: the trail stops short of her wherever the lord stands; tested with the lord at
   nine places). Shots 130 and 134 retaken in the gate round.
6. **The lamplighter's burn:** two pixels of dark skin (`tileLight`) on his temple under the hat's brim, beside the grey
   hair; the pink (`dusk`) at the mouth line is gone from both heads.
7. **The smaller list:** `lorenzPell` and `portraitLorenzPell` take `dusk` for their lit crimson; Brede's near hand
   sits on the beam behind its front end, so both ends show; one lit pixel (`straw`) on Dun's cheekbone (standing,
   seated, all states; Dun walks in look 1's town, so the look-1 goldens may move); the mended cloak faded one step
   further (`far` lit, `moon` highlight, past `waterDeep`) and its patch grey wool with a shade and a brown stitch; the
   shouldered pole rides a pixel up with the body on the walk's passing frames (its flame anchor `poleTip` follows:
   -11.5 on frames 1 and 3); the noble lord's cane stays leaning at his coat's front through idle, talk and bow.

Not done here (the note's point 8 and its "left for the join" list are not this pass): a separate raised-pole walk for
the round between the posts (the note says "pole raised"; the walk frames carry the pole on the shoulder, and new
frames would cost atlas rows), so he walks the round in the same walk frames, at the heavy step.
