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
- `tools/slides/paint.py` and `tools/slides/slideart.py`: the painter (pure python, deterministic; one slide per run
  through the art lock: `bash <artlock.sh> python3 -I tools/slides/slideart.py slidePrologue1 --preview <dir>`).
- `Tests/SlidesTests.swift`, `UITests/SlidesUITests.swift`.

**The texts.** STORY.md section 8's four texts, unchanged; Story.xcstrings had none of them, so they are in
Panels.xcstrings (`slides.prologue.1` to `.4`, the two lines split by a line break), with the German written to STORY.md's
fixed names (die Weltmauer is not named; Haus Lantern, das Große Leuchtfeuer, Burgherr Aldric, der Stirnreif). New
strings, none in STORY.md: `slides.prologue.4.label` (the name on the last slide, Louis' decision 3: "the prologue's last
panel" shows the name), `slides.skip`, `slides.next` and `slides.begin` (VoiceOver hints), `slides.position` (VoiceOver
value). German slide 4 turns on the form: "an {den Letzten|die Letzte} seines Blutes", "{An den, der|An die, die} die
Lampen anzündet".

**The pictures** (painted in the game's look: palette colours, flat value levels, the cold blue dark against the warm
fire, light pools with an edge, dither only in the sky's bands; Recraft had 41 credits, one image, so nothing was
generated):
1. The Worldwall at dusk, seen from the valley: the sun down behind the wall, a rampart of broken snow teeth against the
   afterglow, cloud banks across its middle; one black cleft through the whole wall, the afterglow showing at its top,
   the castle at its foot with lit windows and the house's lantern on the keep; mist, the valley's dark forested hills,
   the river, Tallowford's warm windows and lanterns lower right, a road of lanterns toward the cleft; firs framing left.
2. From the castle wall into the Throat: black rock walls in slabs and broken ledges converging on a narrow slit of
   grey-violet fog, three of the Gloom's people standing in it with one cold eye each and more eyes behind; the three
   lines across the Throat with their braziers' small warm pools; in front the battlement, cold on the left and warm by
   a brazier on the right; House Lantern's teal banner with the gold lantern at the frame's edge.
3. The Throat's mouth by moonlight: the Great Beacon dark on the left (the game's `greatBeacon`, cold), the moor, the
   road in from the right and turning away into the bright fog between two hooded statues facing home; Lord Aldric on
   his horse in a teal cloak, his lantern raised on its pole; twelve lantern bearers following him along the road, each
   a small warm light and pool; firs standing in the fog, near firs framing right.
4. The great hall, warm (the game's `hallInterior`, `hearth`, `throne`, the court's sprites, all lit by the fire): the
   hearth burning, the empty seat on the dais, Brannock, Hesper, Pip, Tamsin and Bram in a half ring; in front, half
   length, the new lord (the court's own portrait, the one the player chose on the name page) with the circlet slipped
   down over one eyebrow and soot on the near cheek, the lamplighter's wick pole held up beside, its little flame lit;
   Odile facing the lord, holding out a small strip of paper folded thick (for the circlet that is too big, STORY.md
   day 1). Two pictures: the Burgherr's and the Burgherrin's.

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

- `lh-pn1-1` (402cc99): build, unit SlidesTests and LordEntryTests, ui and ui-de SlidesUITests. Result: pending.

### Open, and what waits for the join

- The six other languages for Panels.xcstrings (one pass after the join).
- The endings (three slides each) and story beats: the stage takes them as data; their pictures are not painted yet.
- The rebuild rewrites the name page: the hook in `confirmLord` must follow wherever day 1 begins after the name.
