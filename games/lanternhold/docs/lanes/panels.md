# Lanternhold: the panels lane

Version 1's story pictures: the house's lantern slides. Branch `claude/lh-panels`, worktree `.claude/worktrees/lh-panels`,
cut from the integration branch (build 86 plus sound). Everything here waits for the join with the rebuilt game; the
hooks below say exactly what to apply again there.

## Step panels-1: the slide stage and the prologue (14.11.2026)

### What exists

**LANTERN SLIDES** (the director's idea). Each panel is a painted glass slide thrown on the dark by a lantern: a dark
room, the lit gate with a warm vignette that breathes very slightly (period 5.5 s), soft dust drifting in the beam, the
picture a little brighter at its centre. A tap pushes the old glass out sideways through the gate (the carrier's dark bar
passes between the two glasses) while the next slides in and settles on a soft spring, with a soft click (the existing
`cardClosed` cue: the `tap` effect at 0.85). The words sit under the picture in the house's roman (IM Fell, title3, bone
on the dark), two short lines at most, and fade in a moment after the glass. Four small lozenges under the words count
the slides (the one showing in gold) and a small gold chevron breathes once the words are in. A small "Skip" waits in
the top right corner (44 pt). The last slide of the prologue carries a paper label on its mount: the lord's name as Odile
wrote it into the family book ("Mira, Lady Lantern" / "Burgherrin Annegret"). Reduce Motion: cross-fades, no breathing,
still dust, a still chevron. The world beneath stands still (the simulation does not step) and draws at 20 fps.

- `UI/Slides/SlideShow.swift`: the data. `SlideShow` (id, slides, skippable), `Slide` (picture, text key, label key,
  string table, timing), `SlidePicture` (`.fixed` or `.byLord(lord:lady:)`), `SlideTiming` (hold before a tap counts,
  text delay, settle), `SlideShow.prologue`, `SlideShow.named(_:)`; `SlideText` (the words with `{lord}` and `{a|b}`
  resolved by `LordText`, a picture's URL); `SlideArgs` (`-GWSlides`, `-GWPrologue`). The endings and story beats are
  more `SlideShow` values: their keys may live in Story.xcstrings (a slide names its `table`).
- `UI/Slides/SlideStage.swift`: `SlideStage`, the state (`present`, `next` with the hold, `skip`, `onFinish` once), and
  `SlidePictures` (the pictures read once).
- `UI/Slides/SlideStageView.swift`: `SlideStageHost` (over the world; opens `-GWSlides` on appear) and `SlideStageView`
  with its pieces (`SlideLayout`: the picture at a whole number of device pixels per painted pixel where that keeps 85 %
  of the size, `SlideBeam`, `SlideGlass`, `SlideLight`, `SlideDust`, `SlideGateMask`, `SlideLabel`, `SlideProgress`).
- `UI/Slides/GameModel+Slides.swift`: `presentSlides(_:then:)` (pauses the realm, resumes it after unless a card or screen
  is still open), `presentPrologueAfterEntry()`, `openSlidesFromLaunch()`, `turnSlide()`, `skipSlides()`.
- `Resources/Slides/`: `slidePrologue1.png` to `slidePrologue3.png`, `slidePrologue4Lord.png`, `slidePrologue4Lady.png`,
  320 x 160 each.
- `Resources/Panels.xcstrings`: this lane's catalog, English and German (written by `tools/slides/panels_catalog.py`).
- `tools/slides/`: the painter (pure python, deterministic; one slide per run through the art lock:
  `bash <artlock.sh> python3 -I tools/slides/slideart.py slidePrologue1 --preview <dir>`); since fix round 1 one module
  per slide and a palette check (see "Fix round 1").
- `Tests/SlidesTests.swift`, `UITests/SlidesUITests.swift`.

**The texts.** STORY.md section 8's four texts, unchanged; Story.xcstrings had none of them, so they are in
Panels.xcstrings (`slides.prologue.1` to `.4`, the two lines split by a line break), with the German written to STORY.md's
fixed names (die Weltmauer is not named; Haus Lantern, das Große Leuchtfeuer, Burgherr Aldric, der Stirnreif). New
strings, none in STORY.md: `slides.prologue.4.label` (the name on the last slide, Louis' decision 3: "the prologue's last
panel" shows the name), `slides.skip`, `slides.next` and `slides.begin` (VoiceOver hints), `slides.position` (VoiceOver
value). German slide 4 turns on the form: "an {den Letzten|die Letzte} seines Blutes", "{An den, der|An die, die} die
Lampen anzündet".

**The pictures**: the first paintings of this step are gone. Fix round 1 below repainted all five (the critic's look 1
found them not palette art, and slide 4 drew the lord origin Louis struck out on 14.11. at 14:58). What the pictures
show now is under "Fix round 1".

### The hooks (apply again at the join)

| File | Place | What and why |
| --- | --- | --- |
| `App/GameModel.swift` | the stored properties, after `overlay` | `let slides = SlideStage()`: the stage's state lives with the model (an extension cannot store it) |
| `App/GameModel+Lord.swift` | `confirmLord`, after `setOverlay(nil)` | `presentPrologueAfterEntry()`: day 1 begins after the prologue |
| `UI/GameView.swift` | the body's ZStack, inside `if model.kind == .world`, after `OverlayView` | `SlideStageHost(model: model)`: the stage over everything |
| `UI/GameView.swift` | `WorldSceneCoordinator.draw`, the `screen` flag | `|| model.slides.isShowing`: the covered world draws at the screens' 20 fps |

If the rebuild moves the name page or the start of day 1, the hook goes where day 1 begins after the lord is named. The
rule for when the prologue plays (`SlideArgs.prologueFollowsEntry`): `-GWPrologue YES|NO` decides; without it a plain
launch plays it and a launch with other `-GW` arguments does not, so every UI test from before the slides starts as it
did. DESIGN.md "Debug launch arguments" gets at the join: `-GWSlides prologue` (opens the prologue directly over what the
other arguments made; the lord is `-GWLord`'s and `-GWLordName`'s) and `-GWPrologue YES|NO`. Accessibility identifiers:
`story-root`, `story-next` (the slide: label the words, value "Slide n of 4", a tap turns it), `story-skip` (the two last
were already planned in DESIGN.md).

### Rounds

- `lh-pn1-1` (402cc99): build, unit SlidesTests and LordEntryTests, ui and ui-de SlidesUITests. Build, ui and ui-de
  passed; unit failed once: `slides.position` used `{n}` and `{count}`, which `LordText` reads as broken placeholders.
  Fixed (a `%1$d of %2$d` format). Judged on the screenshots and fixed after it: the centre light (screen blend 0.17)
  lifted the pictures' darks, now 0.09; German slide 4's "An die, die die Lampen" now "An die, die abends die Lampen
  anzündet"; the last slide stays drawn while the stage fades out (it vanished first).
- `lh-pn1-2` (18a01fb): the full round (build, unit, ui, ui-de, release): ALL PASSED. Screenshots 61 to 69 in English
  and German; upright copies in `ci-out/upright/` of this worktree (git-ignored).

### My own verdict, and what is weakest

- The stage itself carries the idea: dark room, warm spill, breathing vignette, dust, the carrier's slide, the label on
  the last glass. German fits (slide 3's second line is the longest, still inside the stage's width).
- Slide 3 is the weakest picture: Aldric is small in the frame (39 x 30 px) and the twelve bearers read as dark shapes
  with lights; the story reads, the subject could be bigger.
- Slide 4: the half-length bodies are the portraits' chests carried down (simple shapes that sink into the dark), and
  Odile's folded paper is small; the faces, the slipped circlet and the soot read.
- Slide 1: the lower face of the wall is a calm, fairly flat band; the cloud banks are a little regular.
- The art lock: a shell command that mentions an `*art*.py` inside a multi-line heredoc stays in `pgrep`'s view and
  holds every other lane's lock holder back (it waits up to 20 minutes); run art-lock calls as single-line commands.

### Open, and what waits for the join

- The six other languages for Panels.xcstrings (one pass after the join).
- The endings (three slides each) and story beats: the stage takes them as data; their pictures are not painted yet.
- The rebuild rewrites the name page: the hook in `confirmLord` must follow wherever day 1 begins after the name.

## Step panels-1, fix round 1: the critic's look 1 answered (14.11.2026)

The critic (`ci-out/director/panels-1-prologue-critic1.md` on the planning branch) failed the step 4/10: the stage good,
the pictures not. Two blockers, four highs; all six are fixed here. The stage, the data model, the hooks and the tests the
critic named to keep are kept unchanged, except where a finding asked for a change (the skip's place).

### What changed

**Palette art (blocker 2).** Every slide is now 100 % palette colours, 29 to 42 colours each (the critic measured 754
to about 4000 before):
- `tools/slides/paint.py` gained the palette pass: `Canvas.finish(allowed, dither, protect, keep)` maps every pixel to
  the nearest palette colour (OKLab, from a per-slide subset so hues never jump families), dithers only where a slide
  asks (none does now), folds lone pixels into their cluster (never a light, an eye or a star), and `save` refuses any
  non-palette pixel. `step(colour, k)` lights a colour by stepping it along its palette ramp (`RAMPS`): the slides' light
  is palette steps with hard edges; the soft glow is the stage's `SlideLight`.
- `tools/slides/slidecheck.py` (through the art lock) fails on any non-palette pixel or a wrong size in
  `Resources/Slides`; `--swift` prints the palette for the unit test.
- `Tests/SlidesPaletteTests.swift` (new): every slide decodes (the app's own `PNGDecoder`, pixel for pixel) to palette
  colours only, opaque, 320 x 160, between 12 and 48 colours.

**The pictures, one module each** (`slideart.py` is now only the list and the writer; the old painter's slide code,
with the wick pole and the soot, is deleted):
1. `slide_wall.py`, slide 1 (high 1, the director's note of 14:35): a picture-book map from high over the Gloom's side
   at night. In front the smoke in rolling banks (darker toward us) with the game's own creatures in it as black shapes
   with the moon on their rim and their cold eye (`ashBrute`, `gloomweaver`, `sootling`, `shadehound` from
   Resources/Art), and smaller Gloom folk at the edge of the castle's light; across the middle the Worldwall in uneven
   massifs (a list of masses of different height and width, ridged spurs down both flanks, snow where it can lie), all
   lit by one moon out of the frame at the upper left; the cleft a real gap with sheer sides, the castle in it (about
   55 px with its lantern) with its gate toward the dark, the house's banner over the gate, windows awake and the
   lantern on the keep the brightest light; beyond the crest the inner lands as a dark plain full of warm lights to the
   horizon, a river catching the moon and the road of lanterns out of the cleft. Rendered as a voxel height field
   (column by column, near to far), lit in palette steps.
2. `slide_throat.py`, slide 2 (high 3): the Throat's walls are hand-placed rock masses (polygons listed in the file,
   far to near), each broken into flat facets turned to the light or away (a crack under and right of each facet, a lit
   edge over and left), the inner edges cold with the fog's light near the slit. No radial lines. The slit is the
   brightest cold thing; in it three of the Gloom's people (hand-set grids, 12 to 23 px) with one large eye each (2 x 2
   with a dim ring), two more eyes deeper in. Kept: the three lines with their braziers (smaller pools now), the
   battlement warm by its brazier in palette steps, House Lantern's banner.
3. `slide_ride.py`, slide 3 (high 2): Aldric on his dark bay, side on, riding left, about 56 px from hoof to head (a
   third of the picture), the house's teal cloak blown back, grey hair, his lantern raised on its pole; the lantern's
   pool on the road in hard steps; the twelve bearers trail back along the road toward the Throat, each a hooded figure
   with its lantern held high on a short pole and its own small pool, from 27 px down to 5 px; the Great Beacon (drawn
   for this slide, a tapering tower with the iron bowl) black against the full moon, the moon's rim on its edges; mist
   only in two thin bands in the far hollows; the moor dark with tufts placed one by one; three dead trees.
4. `slide_hall.py`, slide 4 (blocker 1, HOUSE.md section 1, the director's note of 15:03): the great hall before the
   hearth. In the middle the Flame in a big stone hearth (mantel, jambs, firebrick, logs, the fire in tongues). Before
   it, half length, the heir (the court's own portrait, the circlet as it sits, untouched) in the house's teal cloak over
   a red tunic, the cloak old and mended (an older cloth set in below the shoulder, stitched round), both hands at the
   ring of the house's gold lantern; Odile facing the heir, both hands under the lantern's foot, giving it up; the
   lantern between them (17 x 21, gold frame, panes of light) the brightest thing. The court close in a half ring that
   opens toward us (portraits carried down by area vote, nearer and larger at the ends): Brannock in mail and surcoat,
   Pip in motley, Hesper by the hearth in her robe, Bram in his scorched apron, Tamsin in a patched apron. All lit by the
   hearth in palette steps with a hard rim on the side toward the fire. No pole, no soot, no paper; the text key is
   unchanged (`docs/house-rewrite.json` brings the words). Two pictures, the Burgherr's and the Burgherrin's.
- `tools/slides/figure.py` (new): a sparse layer for figures (polygons, tapered limbs, grids, the ink outline, lighting
  in steps with a rim) and `downscale`, which carries a portrait to a smaller size by area vote, so every pixel stays a
  portrait colour.

**Skip (high 4).** "Skip" now stands in the dark at the bottom right, level with the lozenges (a preference
`SlideProgressMid` carries the lozenges' row to an overlay in the stage's coordinate space), so it never touches the glass
in any language; `SlidesUITests` checks that it sits below 68 % of the window's height.

### Hooks

Unchanged: the four hooks of step panels-1 (table above). Fix round 1 touched only this lane's own files.

### Rounds

- `lh-pn1f1-1` (f2ded7f): build, unit SlidesTests and SlidesPaletteTests, ui and ui-de SlidesUITests: ALL PASSED.
  Judged on its screenshots (upright copies in `ci-out/upright-f1-1/` of this worktree): Skip sits in the dark at the
  bottom right in English and German and touches nothing; after it slide 1's far lands lost their ruled bands, the
  one-pixel slivers in its smoke and the wide warm strips on the cleft's sides, its creatures got the moon's rim; slide
  3's horse its lower head and shading; slide 4 lit folds and Hesper's face a step up; the words keep to two lines.
- `lh-pn1f1-2` (cc4df38): the full round (build, unit, ui, ui-de, release): ALL PASSED.
- `lh-pn1f1-3` (2f705df, the last code-bearing commit; since cc4df38 only slide 1's picture and its painter changed):
  build, unit SlidesTests and SlidesPaletteTests, ui and ui-de SlidesUITests: ALL PASSED. Upright copies of its
  screenshots: `ci-out/upright-f1-3/` of this worktree (git-ignored). After it only these notes changed.

### My own verdict, and what is weakest

- All five pictures are palette art (29 to 42 colours each), with one subject each and one light direction; the stage
  is unchanged where the critic said keep.
- Slide 4 now tells the house's story: the heir of the guardian house, the circlet as it sits, the mended cloak, the
  lantern passing from Odile's hands, the court close around the hearth. Weakest: the court's faces are the portraits
  carried down by area vote, readable at phone size but plain at 400 %; their bodies are simple robes with a few marks of
  life (Bram's scorches, Tamsin's patch, Brannock's mail), and there is no child in the hall.
- Slide 1 hooks better (the dark and its creatures in front, the castle's light in the one gap, the lands' lights
  beyond), but its lower third, the smoke, is calm and dark, and the height-field mountains still show some regular
  ravine streaks on their lower faces.
- Slide 2's facets read as cut rock; a pixel artist may still see the cell pattern in the large near masses.
- Slide 3 reads at a glance; the horse is simple (a dark bay in two or three steps).
- The texts are unchanged (the critic: leave them): slide 4 still says "the one who lights the lamps" until
  `docs/house-rewrite.json` is applied in the text pass; German slide 3's second line is wider than the glass (STORY.md's
  words, for the rewrite pass).

### Open, and what waits for the join

- The six other languages for Panels.xcstrings (one pass after the join); the house-rewrite texts for slides 2 and 4.
- The endings (three slides each) and story beats: the stage takes them as data; their pictures are not painted yet.
- The rebuild rewrites the name page: the hook in `confirmLord` must follow wherever day 1 begins after the name.

## Step panels-2: the three endings and the chapter's end (14.11.2026)

### What exists

**The three endings as lantern slides** (STORY.md section 7 "The endings"), three slides each on the prologue's stage,
each ending in **its own light**, so a second ending feels different before a word is read. The stage's lamp is now
data (`SlideShow.lamp`, `SlideLamp`, `SlideLampLook`): the spill on the wall, the centre light on the glass, the
vignette, the dust and the room's own dark.
- **The Open Lantern** (`ending1`; the King slain, happiness 60 or more, Seren not handed over): `.dawn`, rose and gold,
  the widest and brightest spill.
  1. `slideOpen1`: from above at first light, the outer line's flags raked by the low sun from the right (east, where
     the castle is), every shadow long to the left; Aldric on his back under the black mantle, his face upright, grey,
     thin, eyes shut, the grey beard on his breast, the hood's dark lining round his hair; one thin hand out on the
     stone toward the iron crown (a heavy ring, seven tines, the sun on its right edges); the King's snuffer broken in
     two; the lord's lantern set down by his head, still burning; the Gloom's last fog lying off at the left.
  2. `slideOpen2Lord` / `slideOpen2Lady`: the court on the wall walk at sunrise, seen from behind, every one a
     silhouette of their own rimmed by the sun: Hesper tall and hooded beside Odile, Brannock broad with helmet and
     spear, Pip sitting on the parapet with the fool's drooping horns and bells, Tamsin with her hands on her hips
     beside Bram stooped with the hammer, a child on the merlon waving at the sun; the lord in the middle before the
     sun, the house's lantern raised on the hooked staff, the circlet a gold thread; long shadows toward us; Tallowford's
     roofs and two chimneys in the valley. The lady has her hair down her back.
  3. `slideOpen3`: west from the Throat's mouth, the sun just up behind us: the ruin on its hill (larger than ours, two
     towers torn to stumps, the keep a roofless shell, the curtain broken twice) glows rose and gold on its upper half
     above the valley still in blue shadow; our lantern cut over its gate is the brightest gold; fog drawing back past
     the firs; the road with its statues facing home going out toward the hill; Aldric leaning on the lord, small on
     the road, the lantern lit.
- **The Shuttered Lantern** (`ending2`; every other case): `.grey`, a cold, narrow, pale blue spill.
  1. `slideShut1`: the game's own Lightless King (the `lightlessKing` sprite, a walking frame, turned) walking left
     into the Gloom's fog at first light with the snuffer, the fog's edge already over his front; the smoke folk, gaunt
     and long, going with him with their cold eyes; the Throat's walls faint; the outer wall at the right with a
     brazier still smoking (the one warm thing) and two archers watching; rubble and arrows on the ground.
  2. `slideShut2`: on the wall in the grey morning: a grey lantern (drawn from its shapes at 1.7 times, never scaled
     pixels) on the frosted coping, its flame grey and cold, its pale pool on the frost; the coping running away from
     us; the Great Beacon far off in the fog; a raven further along the wall; an arrow left lying.
  3. `slideShut3`: Bram, seen from behind, a big bowed working man (the apron's straps crossed over his shirt, the
     sleeves rolled on bare forearms, grey hair thin on top, the brush in his hand) before the herald's banner on its
     rack: the left half still black with soot running down in streaks, the right half washed teal, and in gold thread
     our lantern beneath half a sun; water dripping into the tub, the banner in the puddle.
- **The Guttering Lantern** (`ending3`; happiness below 30): `.ember`, a low red spill that dips now and then like a
  drowning wick (`SlideLampLook.gutter`; steady under Reduce Motion).
  1. `slideGutter1`: Tallowford on a winter night under the cleft: the game's own houses (`bigHouse`, `house`,
     `houseB`, `houseC`, shaded for the night, snow on the roofs), only two with lit windows (their `Lit` sprites); a
     family pulling a handcart out of the picture to the right with a small lantern; a street lantern guttering; the
     castle in the gap with two dim windows; snow falling.
  2. `slideGutter2Lord` / `slideGutter2Lady`: the great hall at night, the hearth burned down to a bed of embers and one
     small flame; the lord alone in the high chair, seen from behind, the ember light along the chair's and the lord's
     edges toward the fire, the circlet a gold thread; the benches and the table empty; the lord's shadow long across
     the floor.
  3. `slideGutter3`: on the outer line among the rags of the night, Tamsin on her knees, a dark shape rimmed by the
     brazier's fire, holding the small coat in the house's teal up to the light; the coat is the only colour in the
     picture; snow.
- **The words** (Panels.xcstrings, English and German): slide 1 and 3 are STORY.md's, cut to two lines of at most 64
  characters in English (the unit test holds every line to 64 in English, 72 in German, so English never scales down).
  Slide 2 is composed: line 1 the leaning in one sentence, written for each ending's mood (nine keys
  `slides.<ending>.lean.<leaning>`); line 2 the houses (`slides.houses.some` with their names joined by the language's
  list format, `.all`, `.few`, `.alone`), or in the Shuttered Lantern with Seren handed over her lantern
  (`slides.seren.lantern`, STORY.md's extra sentence; the houses then stand only on the end card).
- **The rules** (`UI/Slides/ChapterEnding.swift`): `ChapterEnding.decide` is DESIGN.md's order (below 30 the
  Guttering, the King slain at 60 or more with Seren kept the Open, else the Shuttered; a finale saved by a second
  chance cannot be slain, so it is the Shuttered or the Guttering). `Leaning.read` scores STORY.md section 4's flags
  (open hand: `stranger_in`, `refugees_in`, `refugees_some`, `plough_blessed`, `coast_promise`, `coast_helped`,
  `cough_cured`; shut gate: `stranger_turned_away`, `refugees_turned_away`, `tribute_paid`, `sick_sent_away`,
  `seren_outside`, `seren_handed_over`, `herald_refused` without `herald_mocked`; honest lamp: `beacon_shown`,
  `town_vigil`, `blessing_asked`); the last stand's speech counts twice and decides a tie (`speech_aldric` open hand,
  `speech_dawn` shut gate, `speech_honest` honest lamp). `House`: the five houses, `<house>_with` (Varn, Brine,
  Oxmoor, Calder, Lorn), their banners `banner<Name>`. `RealmTale`: the ending, the leaning, the houses, banners hung,
  Seren handed over, nights held (`records.bestNight`), judgments (`court.heardCount`), the fallen
  (`records.fallenTotal`), the lord; it builds the show.
- **The chapter's end card** (`UI/Slides/ChapterEndView.swift`, docs/UI-look.md): after the last slide (or Skip) the
  glass slides away and a page of the house chronicle lies in the beam on the same dark stage, in the ending's light.
  The lord's name and "Chapter 1, The Dark Beacon" in italic, the ending's name as a rubric in small capitals over a
  flourish; a ledger with leaders (Nights held, Judgments spoken, Fallen on the walls, Your way: the leaning's name in
  House Lantern's teal); "Stood by you" with the houses' banners as the hall hangs them (the game's 20 x 41 sprites at
  one point per pixel) and their names, or "House Lantern alone"; "Hold the realm" as a quiet plaque and "Begin again"
  in wax red, 52 pt. The page fades and rises a few points (Reduce Motion: fades only). Identifiers `end-root`,
  `end-ending` (value: the ending's id), `end-nights`, `end-judgments`, `end-fallen`, `end-way`, `end-stood`,
  `end-begin`, `end-hold`.
- **What Core has of the endless mode** (asked by the brief): `GameMode.endless` exists and is tuned (T7 plays the
  chapter's end state on from night 21 with `endlessQuadratic`); the endless-only petitions (15) are drawn only in
  that mode; the save counts it on the `endlessContinued` track; the second chance waits ten nights there. Not built:
  the endless events (eclipse, festival, crows), a title entry "Endless", "New realm" in endless, and "in endless a
  fallen realm ends the run". So the card offers **"Hold the realm"**: it sets the realm's mode to endless now and in
  its last dawn (the SimDriver hook below), saves, and the day 21 goes on. "Begin again" is the pause sheet's
  "Restart chapter" path (a new realm, the Chronicle kept, the name entry asks again).
- **Launch arguments** (DESIGN.md "Debug launch arguments" gets them at the join): `-GWSlides ending1|ending2|ending3`
  plays that ending with a sample tale and then the end card (the Open Lantern with Varn's and Brine's banners and
  the open hand; the Shuttered Lantern with Seren handed over and the shut gate; the Guttering Lantern alone with the
  honest lamp); `-GWSlides end` shows the end card alone (the Open Lantern's sample).
- `tools/slides/ending_kit.py` (skies in uneven bands, clumpy clouds, people seen from behind with the sky between
  their arms and bodies, rims, fog, strata, long shadows), `slide_open.py`, `slide_shut.py`, `slide_gutter.py`, one
  slide per art-lock call: `bash <artlock.sh> python3 -I tools/slides/slideart.py slideOpen1 [--preview <dir>]
  [--preview-only]`.
- Tests: `Tests/EndingsTests.swift` (the order of the endings, the leaning, the three slides on their lights with
  their pictures, the middle slide's lines, every word in English and German within two lines, the tale of a realm,
  the finale's report through the ending to the end card and the Long Watch, Begin again, only the finale ends the
  chapter, each lamp its own light and the gutter's dips); `SlidesPaletteTests` now checks all sixteen pictures;
  `UITests/EndingsUITests.swift` (`testTheThreeEndings`: each ending tapped or skipped through, every slide and the
  end card saved, Hold the realm and Begin again; `testTheFinaleEndsTheChapter`: the finale's report, Continue, the
  ending, Skip, the card).

### The hooks (apply again at the join)

| File | Place | What and why |
| --- | --- | --- |
| `App/GameModel.swift` | `continueReport`, after `setOverlay(nil)` | `endChapterIfFinale(report)`: after night 20's dawn report a chapter realm plays its ending, then the end card |
| `App/GameModel.swift` | `init`, after the lord entry's check, before `refreshHUD()` | `resumeChapterEndAtLaunch()`: a realm saved at the finale's dawn that never chose (the app closed on the ending or the card) gets its ending again; plain launches only |
| `Core/SimDriver.swift` | after `setLord` | `mutating func holdTheRealm()`: `state.mode = .endless` and `dawnSnapshot.mode = .endless` (the snapshot is `private(set)`), so "Hold the realm" is saved at once |
| `UI/GameView.swift` | `WorldSceneCoordinator.draw`, the `screen` flag | `model.slides.isShowing` became `model.slides.coversWorld` (the end card covers the world too: 20 fps) |

Unchanged from panels-1: `let slides = SlideStage()` in `GameModel`, `presentPrologueAfterEntry()` in `confirmLord`,
`SlideStageHost(model: model)` in `GameView` (it now also shows the end card). If the rebuild moves the dawn report's
Continue, the first hook goes wherever night 20's report is closed.

### Rounds (by the director's notes of 14.11. 18:46 and 19:35: short rounds, the gate one round, English only)

- `lh-pn2-1` (387d031, code only, before the pictures): build PASSED; unit EndingsTests and SlidesTests: one failure,
  the picture test (the pictures were not in that commit yet); the other 16 tests passed.
- `lh-pn2-2` (2ae120d, the gate: build, all unit tests, ui EndingsUITests and SlidesUITests): **ALL PASSED**.
  Screenshots 71 to 86; upright copies in `ci-out/upright-pn2-2/` of this worktree (git-ignored). Judged on them and
  fixed after it (59aa8a9): the end card's first line now sets its figures in the ledger's face ("Chapter 1" read as
  "Chapter ı" in IM Fell's old-style figure); the lord at the low hearth stood dark on a dark wall (only a hooked outline
  showed), now the chair stands before the fire-lit stones and the head and shoulders read; the fog round the King
  calmer.
- `lh-pn2-3` (59aa8a9, the last code-bearing commit): build, unit EndingsTests, SlidesPaletteTests and SlidesTests,
  ui EndingsUITests: **ALL PASSED**. Upright copies in `ci-out/upright-pn2-3/` of this worktree (git-ignored): the
  card's "Chapter 1" now in the ledger's figures, the lord at the low hearth reads against the fire. After it only these
  notes changed.

### My own verdict, and what is weakest

- The flow is complete: night 20's report, Continue, the ending the realm earned on its own light, the end card with
  the realm's own numbers, Hold the realm (the Long Watch) or Begin again. The three lights differ at a glance: the
  Open Lantern's rose spill, the Shuttered Lantern's cold slate, the Guttering Lantern's near-black red that dips.
- The end card is clean and in the house's style (the chronicle's page, leaders, the houses' real banners, wax red).
- The pictures are palette art (13 to 25 colours), one subject and one light each, the people seen mostly from behind
  or in silhouette (no stiff frontal line-ups, faces only where they carry the line: Aldric's). They read at phone
  size. Against a strong pixel artist's bar they are plain: big flat areas, simple figures, few hand-placed details.
  Weakest, in order: `slideGutter1`'s cleft (a geometric V of flat rock above the game's houses), `slideShut2` (quiet to
  the point of empty: the fog in long flat bands, the raven tiny), `slideGutter3` (Tamsin is a dark hooded mass; her
  kerchief and face do not read, only the coat), `slideOpen1` (seen from above the figure can still read as standing
  for a moment; the floor is plain). Strongest: `slideOpen2` (the court's silhouettes at sunrise), `slideShut3` (Bram
  and the banner), `slideShut1` (the game's own King walking into the fog with the thinning folk).
- German is written for every key and held to 72 characters a line by the unit tests, but not looked at on screen (the
  director's note of 19:35); `EndingsUITests` runs in German with `GW_LANG=de` at the join.

### Open, and what waits for the join

- The six other languages for the new keys (one pass after the join).
- DESIGN.md "Debug launch arguments": `-GWSlides ending1|ending2|ending3|end`; DESIGN.md "Screens" 7 (chapter end) and
  "Endless" can point to this card and to "Hold the realm".
- Endless itself beyond the mode switch (events, a title entry, the run ending on a fall in endless) is not built; the
  straw crown (VERDICT.md section 2, build 3) can use the same stage, a fourth `ChapterEnding` and the same card.
- The words of the endings are STORY.md's, cut to two lines; `docs/house-rewrite.json` has no change for them. The
  speech line "I was never meant for this" (Story.xcstrings) changes to "I am afraid too. I stay." in the rewrite; the
  honest lamp's line on slide 2 does not quote it, so it holds either way.
