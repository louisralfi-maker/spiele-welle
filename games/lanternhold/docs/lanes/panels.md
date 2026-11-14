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
- `lh-pn1f1-2` (cc4df38): the full round (build, unit, ui, ui-de, release). Result below.
- `lh-pn1f1-3` (2f705df, pictures and painter only since cc4df38): build, unit SlidesTests and SlidesPaletteTests, ui and
  ui-de SlidesUITests. Result below.

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
