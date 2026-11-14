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
  - repainted at their sizes and frames: `citizen` (Mother Corra), `citizenB` (Dun Rook), `citizenC` (Aldo Fenn) and
    their seated forms `citizenSeated`, `citizenBSeated`, `citizenCSeated` (`tools/grids/actors/`);
  - new at the citizen contract: `elder` (Old Hemmet, the shuffle), `washerwoman` (Wenna Brisk, with wring frames),
    `labourer` (Brede Hask, the limp), `farmerHoe` (Gorm Ashby) and `farmerScythe` (Hedda Ashby), each farmer with work,
    straighten and carry frames (`tools/grids/people/`);
  - three children `childA` (Pim), `childB` (Wren), `childC` (Fen) at 10x18: run, fidget, skip;
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
  guard, the footman beside him, the lord and the lady of the inner lands, Fen facing Old Hemmet, Pim facing Wenna,
  Wren, Gorm, Hedda, Brede, Mother Corra, Dun, Aldo, Master Edwy, Ilse; standing on the valley's earth lane before
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
