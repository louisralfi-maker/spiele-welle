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
  - repainted at their sizes and frames: `citizen` (Mother Corra), `citizenB` (Dun Rook), `citizenC` (Ned Thatch) and
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
- **H5, the names:** Pim is Nib Brisk, Aldo Fenn is Ned Thatch (checked against STORY.md, the docs and the petitions:
  no Nib, Ned or Thatch anywhere; Odo was close to Odile, Wat is a recruit name in YARD.md).
- **H6, the director's notes:**
  - cloth states for the eight working bodies and the three seated forms (village and town) and the three children
    (town), cloth pixels only (`tools/peoplestates.py`, `#@state` lines in the grids; PEOPLE.md section 7 says what
    each wears at each stage; SPRITES-people.md "Cloth states"); the six-figure line-up in all states;
  - the nobles' bow (frames 8-9 of `nobleLord` and `nobleLady`), played only when the realm is a town
    (`PeopleCast.bowFrame`; PEOPLE.md section 4);
  - the collector (Saul Wicket), the lamplighter (Silas Moth) and the jailer (Old Kell) in PEOPLE.md with name, mark,
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
  not in look 1, no test reads it). **lh-p1f1-4** (build, unit, ui PeopleUITests) confirms the head and gives the
  final shots: see the report.

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
