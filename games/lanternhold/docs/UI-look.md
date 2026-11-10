# Lanternhold: the interface in the map's style

Louis loved the realm map (`docs/karte.html`) and asked for the whole interface in its hand (10.11.2026). Everything
the player reads is a piece of paper from the lord's writing desk: a slip of the steward's ledger, a strip cut from the
map, a letter, a page of the house chronicle, a page of the family book. It is this game's own interface; no other
game's screens were copied. The code is `UI/Theme.swift` (the shared pieces) and the views beside it.

## Style guide

### Two surfaces

- **Parchment** is everything inside the world: what a person of the valley could hold. Warm paper, darker toward the
  lower right corner, cut nearly square (2 pt), an ink rule at the edge.
- **The desk** is everything outside the world: the pause sheet and the defeat card. Dark wood, a bone line at the
  edge, a faint gold rule inside, words in bone and gold.
- Plain fills, gradients and strokes only. No materials and no blur over the running scene (DESIGN.md "Tech plan").

### Palette (from the map; hex)

| Name | Hex | Use |
| --- | --- | --- |
| desk, desk2 | `1D1712`, `2A2119` | the desk under the papers |
| bone, boneDim | `E4D6B4`, `B3A27F` | words and rules on the desk |
| parchment, parchmentMid, parchmentDeep | `ECDCB1`, `DCC690`, `CDB47C` | the paper, light to shaded |
| plaque | `F4E9CB` | the lighter slip a choice stands on |
| ink, inkSoft | `38281A`, `58432B` | words; quieter words and asides (the map's soft ink a shade darker, for small text on a phone) |
| rule | `5D4526` | frames and rules on parchment |
| rubric, rubricHi, rubricDeep | `8C3423`, `B9503A`, `63200F` | headings, the wax of seals and main buttons, warnings |
| rubricOnDesk | `E58A6E` | wax red where it must read on the dark desk |
| sealWords | `F6E8C6` | words pressed into wax |
| gold, goldHi | `D19A2C`, `F4C85A` | coins, gilt, headings on the desk |
| teal | `1F5C5E` | House Lantern: Odile's hand, what is marked or in force, the lord's mark on the strip |
| meadow, stone, fireOrange, dawnRose | `8F9A58`, `9C8E78`, `E8822A`, `D9967E` | the strip of map, the dawn wash |

Contrast: ink on parchment 10:1 at the light corner and 7:1 at the shaded one, soft ink 4.6:1 or more, bone on the
desk 12:1, seal words on wax 6.6:1.

### Type

- **IM Fell English** (Igino Marini, SIL Open Font License 1.1), three cuts bundled in `Resources/Fonts` with the
  licence beside them (`IMFell-OFL.txt`) and registered in `Info.plist` (`UIAppFonts`; `project.yml` names the file):
  - roman (`IMFeENrm28P.ttf`) for running text,
  - italic (`IMFeENit28P.ttf`) for asides, what somebody says and a hand writing,
  - small capitals (`IMFeENsc28P.ttf`) for headings, names and the words on a button. The face has no bold; where the
    first look asked for bold it now gets small capitals.
- **Figures** are set in Baskerville SemiBold (on every iPhone): IM Fell's old-style 1 reads as a capital I, and a
  ledger must be read at a glance. `Text(inked:)` puts the digits of any line ("Day 1 dawns") into that face.
- **Sizes** are one point over the system's text styles (the face has a small x-height) and scale with Dynamic Type.
  Only the HUD is fixed, since its room beside the strip is fixed.
- **Japanese** is set in Hiragino Mincho (W3, W6 for headings), **Simplified Chinese** in the system's serif. Both
  keep the frames, the colours and the figures; neither has an italic, so asides are told by colour.
- A missing face falls back to the system's serif; nothing depends on the font to work.

### Frames and rules

- **Sheet** (`ParchmentBackground`): the edge rule plus a second rule 5 pt inside whose four lines run 3 pt past each
  other at the corners, as on the map's border. Letters, the chronicle, the family book, the builders' ledger.
- **Slip** (`SlipBackground`): the paper inside one rule. The HUD's ledger, captions, a word from the court; Odile's
  note has the rule in teal.
- **Plaque** (`PlaqueBackground`): a lighter slip with a rule and a hairline inside. Whatever can be chosen stands on
  one. Marked (Odile's favourite, the tax in force, the chosen form of address): a 2 pt teal rule. Not available: the
  plaque fades and says why in wax red.
- **Rules:** a thin ink rule (`InkRule`) under a heading; a rule with a small wax-red lozenge (`FlourishRule`) where a
  page pauses; dotted leaders (`Leader`) from a ledger's entry to its figure.
- Pictures (portraits, building thumbnails) sit in an ink frame with a gold hairline inside, square-cornered, the
  pixel art at whole device pixels.

### Buttons

- **Main button** (Continue, Resume, Begin, a second chance): a plaque of wax red, the words pressed in small capitals
  in the paper's colour, 52 pt high or more.
- **Quiet button** (Cancel, Replay the day, Leave): an inked plaque; on the desk dark wood with a bone rule. A
  destructive one (Restart chapter) has wax-red words and rule.
- **Wax seal** (`WaxSeal`): round, lit from the upper left. Pause (44 pt in a 60 pt area), the action button (88 pt in
  a 128 pt area) and the knobs of the pause sheet's switches. The wax has set grey when what it offers cannot be done.
- Every touch target is 44 pt or more; pressing darkens the plaque, nothing moves.

### Icons, drawn in the same ink

- **Gold:** a coin of gold leaf inside an ink line, a second ring struck in it (never a currency symbol).
- **Happiness:** a face with five states (joyful, content, calm, sullen, angry): a wash of colour from meadow green to
  wax red inside an ink line, the features in ink, brows only when angry. The state is told by the mouth, not by the
  colour alone.
- **People:** two figures in ink, head and shoulders, one a step behind the other.
- The action button's and the effect chips' symbols stay SF Symbols in ink or seal colour for now (the crown is being
  replaced by the circlet in the polish lane).

### Motion

- Unchanged from the first look, and all of it off with Reduce Motion: the numbers roll, the face hops once, cards
  fade and rise a few points, the seal's ring fills back through a cooldown.
- Nothing new moves: no paper curl, no ink bleeding, no flicker. Paper lies still.

## The screens

- **HUD:** top right one slip of the steward's ledger: "Day 3" as a rubric in small capitals with the hour in figures,
  a rule, then coin, face and people with their numbers. Top left the pause seal. Bottom right the lord's seal with
  the action's symbol, its caption on a slip above. The horn at 19:00 is a dark ribbon lettered in gold.
- **Realm strip:** a strip cut from the map: parchment in an ink rule with a scale along its foot; the gorge a wash of
  ink, the Great Beacon in gold, walls by state (ink, wax red, a red cross for rubble, gold while built, dashed for an
  open site), the castle's towers, the town's red roofs on green, the river in teal, the lord's teal mark, creatures
  as embers at night, a wax-red tag with the petitioners waiting.
- **Audience:** a letter laid before the lord. The portrait in an inked frame, the name in small capitals, the role as
  a rubric, the request in roman; the choices side by side as plaques with what they cost or bring; Odile's counsel
  as a teal-ruled slip in her italic hand, her favourite plaque marked in teal; after the choice the lord's word, the
  reaction in italic and the wax-red button to the next petitioner.
- **Build, recruit and tax cards:** a page of the builders' ledger: the title in small capitals over a rule, the
  treasury as coin and figure, each option a plaque with its thumbnail in an ink frame, price and time in figures.
- **Talk bubble:** a slip with the speaker's name as a rubric.
- **Dawn report:** a page of the house chronicle: a small sun rising over the horizon, "Day 4 dawns" as a rubric over
  a wash of dawn, sections headed in small capitals over a rule, each entry led by dots to its figure, the fallen by
  name, the treasury under a closing rule; the banners (no losses, the wall fell, the Lightless King) as ribbons.
- **Name entry:** a page of the family book: the question in small capitals, the name written in italic on a ruled
  line that turns teal while writing, Lord and Lady as two plaques with their portraits.
- **Pause sheet and defeat card:** on the desk. Headings in gold small capitals over a flourish, the switches as slots
  with a wax-seal knob, Resume in wax red, the chapter's restart in wax-red words.
- **Title:** the code has no title screen yet (DESIGN.md "Screens" 1). When it comes: the game's name in small
  capitals in gold over the castle at dusk, the entries as plaques, Continue in wax red.

## Kept

- Every accessibility identifier, VoiceOver label, value and trait; the UI tests are unchanged.
- The model's state machine, the overlay dims and the frame-rate rules for overlays (20 fps under screens, 60 fps
  under cards, 30 fps when the phone is hot).
- No string was added or changed; the catalogs are untouched.
- The first look's names in `Theme` (`GoldButtonStyle`, `Theme.rounded`, `Theme.night0`, `CornerGem` and the like) so
  the other lanes' code compiles unchanged after a merge.
