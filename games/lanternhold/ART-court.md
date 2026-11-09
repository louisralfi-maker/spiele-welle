# Lanternhold: the court and the guests (M3 art lane, step 1, 09.11.2026)

Every actor of SPRITES.md "M3, Court and guests" is real pixel art now: 14 sprites and 3 glow strips in
`Resources/Art/`, each exactly its contract size (one row of frames, frame width × frames by height), 8-bit RGBA,
binary alpha, colours from `tools/palette.txt` only. Everything faces right, the feet stand on the bottom row in every
frame, and the figure stands on the frame's bottom centre (within the existing cast's 1 px). They are drawn in the
style of the M2b cast (ART-actors.md): hand-set part grids, a 1 px ink outline, two or three tones per material, one
ink pixel for an eye, the head in profile on a three-quarter body.

Each one reads at device scale by silhouette and colour, distinct from the others and from the townsfolk, soldiers and
creatures (see `court-lineup-day-x6.png` below): a tall dark column with a grey bun (Odile), a broad bald man in teal
and steel (Brannock), a small jester's two horns (Pip), a cream hood with a staff and flame (Hesper), a round woman in
a teal kerchief and white apron (Tamsin), a bald black beard with a hammer and bare arms (Bram), a wide hat with a rose
feather over a long green coat (Marek), a blue-grey hood with a pale lantern (Seren), a bucket helm on a skinny knight
(Ser Ludo), a red cap with a white feather and a lute (the bard), a sea-blue coat with a scroll case (the envoy), an ash
figure with a spiked circlet and a black banner (the herald), a blond braid with a rose shawl and a basket
(petitionerD), a chestnut coat with a fur collar and a red cap (petitionerE).

## Credits

Recraft: **391 before, 391 after: 0 spent** (budget 300). No key poses were needed: at 22 to 30 px a painted figure
falls apart into specks (ART-actors.md), and every silhouette here came out clear as a hand-set grid. The credits stay
for the portraits (step 2), where a 48x48 head needs a painting.

## Pipeline

| File | What it does |
|---|---|
| `tools/grids/court/<id>.txt` | the part grids, one per sprite, in `actorart.py`'s spec format (ART-actors.md "Pipeline"); the header comment of each says who it is and what every frame shows |
| `tools/build-art-court.sh [name …]` | the third lane script: rebuilds the 14 sprites and their glow strips with `actorart.py build`, one at a time with the heat rule; `--list` names them for `build-art.sh` |
| `tools/build-art.sh` | runs the court lane after the buildings and actors lanes (group name `court`, or one sprite by its name) |
| `tools/grids/court/proposals/kingSeated.txt` | a proposal, not a contract sprite (see "Deviations"): built only into `build/recraft/lh/court/proposals/` by `run_court.sh` |
| `tools/scenemock/scene_court.py`, `run_court.sh` | the context scenes (below); `zoom.py` cuts a box of a mock and scales it to device scale (6 device px per game px) |

**Reproducible:** a full `build-art.sh` run in a scratch copy of the tree with `Resources/Art` emptied (the Recraft raws
copied from `lh-art2`'s `build/recraft/lh/`) rebuilt all 140 PNGs byte for byte (123 old ones and the 17 new ones); no
file missing, no extra file. The only warnings are the old ones of `ashGiant` and `lightlessKing` (pixels of a part
outside the frame, clipped as before). A court-lane run takes about 15 s; the CPU stayed between 38 and 45 °C.

No palette change: the three swap ramps of the contract come with the composed portraits (step 2). `pixelart.py`'s
`Palette` skips only `emissive` entries, so step 2 must make it skip `swap` entries too before adding them, or a
conversion without `--only` could pick a swap colour.

## Sprites

| id | size × frames | frame use | look |
|---|---|---|---|
| `odile` | 14x30 × 8 | walk 0-3 (a measured step, the hem swinging, the shoes peeking out in turn), idle 4-5 (a breath), talk 6-7 (the elbow keeps the ledger clamped while the forearm comes up with one dry finger lifted; then palm up) | tall and thin; grey hair pulled into a high bun (a knot on the crown with a notch at the nape), a long nose; a dark plum robe (aubergine: rockDeep with violet night2 folds, see "Deviations") open over a rose facing down the front, rose hem and cuffs; the silver chain of office from the nape over the shoulder to a gold seal on the chest; the red-brown ledger with its parchment fore-edge and gold clasp under her near arm |
| `brannock` | 16x30 × 8 | walk 0-3 (a heavy stride, the arms swinging, the scabbard bobbing), idle 4-5 (his hand on the pommel, a breath), talk 6-7 (a mailed fist raised; the open hand thrust forward) | broad and bald (the guards wear helms; the king wears a crown and a white beard), a grey fringe, a short square iron-grey beard, a scar through the eye; steel pauldrons and mail under the teal surcoat with the gold lantern; a heavy belt, the sword's hilt forward at the belt and its scabbard slanting back behind his legs; mail chausses, boots |
| `pip` | 12x22 × 8 | walk 0-3 (a bouncy skip, the bells swinging), idle 4-5 (rocking), talk 6-7 (juggling: three balls, gold, white and teal, fly in an arc over his cap between his raised hands, two beats of the toss) | small: his cap tops out at row 3 (19 px tall) so the balls fit in the frame; a two-horned cap (the back horn teal, the front horn rose-red) with a gold bell on each drooping tip; a rosy cheek, a parchment ruff, a motley tunic split teal and red with a dagged hem, the hose the other way round, pointed shoes |
| `hesper` | 14x30 × 8 | walk 0-3 (slow, the staff kept ahead), idle 4-5 (a breath; the flame flickers through four shapes), talk 6-7 (the staff lifted and the flame flaring up; then lowered, her free hand on her heart) | an old woman with dark skin and white brows in a deep cream hood, a short cream cape edged in gold with the gold flame of her order, a gold stole down the cream robe, a gold hem; a tall wooden staff held out in front with a small iron cup at the top; `hesperGlow` is the flame (fireWhite core, fireGold, fireOrange tips) over strawLight, gold and straw albedo |
| `tamsin` | 14x28 × 8 | walk 0-3 (a rolling waddle), idle 4-5 (a breath), talk 6-7 (the ladle wagged up beside her face; then pointed forward like a finger) | round and rosy: a teal kerchief knotted at the back over an auburn curl, a rosy cheek; a red-brown dress with rolled sleeves over bare forearms, a white apron with a bib tied at the waist; a long wooden ladle with an iron bowl hanging from her fist |
| `bram` | 16x30 × 8 | walk 0-3 (heavy steps, the free arm swinging), idle 4-5 (a slow breath), talk 6-7 (few words: he swings the hammer down and points with it; then holds it low before him) | huge, bald, a short black beard, soot on his brow and cheek; bare arms like hams with soot to the elbows (the near arm bent, the fist on the hammer's handle at his chest); a dark shirt under a long leather apron with a bib; the smith's hammer over his near shoulder, its iron head behind his neck (never before the face, ART-actors.md lessons) |
| `marek` | 14x30 × 8 | walk 0-3 (a jaunty step, the coat tails swinging), idle 4-5 (thumb in his strap), talk 6-7 (he tips his hat; then turns an open palm up with a ring glinting: a bargain) | a wide floppy dark hat with a long rose feather sweeping back, a sly face (medium brown skin) with a curled black moustache; a long green coat to the shins with gold buttons and trim; a leather satchel with a gold buckle on a strap across the chest, riding on his back hip; gold rings |
| `seren` | 14x30 × 8 | walk 0-3 (a quiet glide, the lantern swaying on its chain), idle 4-5 (still, the lantern sways), talk 6-7 (the lantern lifted to the hood; then lowered, her free hand opening) | tall in a long hooded cloak of cool blue-grey (the far ramp, so she parts from the hall's violet stone) with a tattered hem and a pale clasp at the throat; the face stays in the hood's shadow (only a pale chin); a small iron lantern held low in front, clear of the cloak; `serenGlow` is its cold light: foam glass, the frame lit moon blue |
| `serLudo` | 16x30 × 8 | walk 0-3 (a proud march: contact, a high step on each leg, the helm wobbling), idle 4-5 (chest out, a breath), talk 6-7 (he lifts the visor and two earnest eyes peer out; then thrusts his sword up beside the helm) | comic: a great bucket helm far too big for him, dented on top, its breathing slits dark, sitting on his shoulders; a long rose plume drooping wilted down its back; a skinny frame in a yellow surcoat with a red chevron, baggy mail on thin legs, big boots; a battered red heater shield with a yellow bend and a dent, a small sword at the hip |
| `bard` | 12x28 × 8 | walk 0-3 (a light step, the lute bobbing), idle 4-5 (fingers on the strings), talk 6-7 (strumming, the hand up and down, singing with an open mouth) | a floppy red cap with a long white feather, ginger curls, a spring-green doublet with cream puffed sleeves and a gold sash, dark hose; a round-bellied lute across his front, sound hole, the neck rising forward |
| `envoy` | 14x30 × 8 | walk 0-3 (an upright, measured step), idle 4-5 (hands folded), talk 6-7 (holds out a sealed scroll; then opens his palm) | dark skin and a close black beard, a sea-blue round cap with a silver brooch, a long sea-blue coat with a white collar and silver buttons, grey hose; a leather scroll case with gold caps slung along his back, its cap showing over the shoulder (a teaser for chapter 2's coast) |
| `herald` | 14x30 × 8 | walk 0-3 (a stiff, deliberate step), idle 4-5 (utterly still but for a breath), talk 6-7 (the banner thrust up; then the bony free hand raised, pointing) | a gaunt figure the colour of ash: a black iron circlet with three spikes (the Lightless King's crown in small), hollow eye sockets, a black mantle over ragged ash-grey robes, a tall black pole before him with a tattered black banner on its crossbar, the King's sign on it (a small cracked crown); `heraldGlow` as `lightlessKingGlow`: tealGlow eyes, a tealDim rim on the top contour (`rim tealDim tealGlow`: tealGlow on the spikes and the pole's point), the crown on the banner and its torn edge tealDim |
| `petitionerD` | 12x26 × 6 | walk 0-3 (a light quick step, the braid swinging), idle 4-5 (a breath, the basket held close) | a young townswoman, bare-headed with a long blond braid, a rose shawl, a lavender dress, a basket of bread and flowers in both hands (the townswoman `citizen` wears a cream headscarf, a red-brown dress and carries her basket on one arm) |
| `petitionerE` | 12x26 × 6 | walk 0-3 (a self-important waddle), idle 4-5 (a breath, thumb in his belt) | a well-off townsman, portly, a neat grey beard, a red velvet cap with a gold brooch, a fine chestnut coat to the knees with a pale fur collar, gold buttons and chain, buckled shoes |

Glow strips: `hesperGlow`, `serenGlow`, `heraldGlow` (body size and frames). The body pixel under a glow pixel is a
pale or warm albedo (strawLight under the flame, stonePale under the lantern glass, night0 under the herald's eyes),
so by day a dimmed glow still reads as flame, glass and eyes.

### Glow positions (from the anchor: dx right, dy up from the bottom row; facing right)

| sprite | position | notes |
|---|---|---|
| hesper | flame (+5.5, 27.5) in every frame (27 in talk 6, the staff lifted) | 4 to 7 glow pixels; a small light (candle-sized) would sit there |
| seren | lantern glass (+3, 10) in frames 0, 2, 4, 7; (+4, 9) swaying in 1, 3 and (+4, 10) in 5; (+3, 21) raised in talk 6 | 17 glow pixels: a cold light, if the engine gives her one, would be grey-white, not firelight |
| herald | eyes (-0.5, 21) and (+1.5, 21); 20 in the bob frames 1, 3, 5 | the rim follows the top contour (circlet spikes, pole point, crossbar) |
| kingSeated (proposal) | lantern glass (+5.5, 22.5), as the standing king's idle frames | crown glint as the king's |

## Context scenes (`tools/scenemock/scene_court.py`, `run_court.sh`)

Each renders `build/recraft/lh/preview/court-<scene>.png` (437x201 upscaled x3, with the look values of `run_actors.sh`)
and a device-scale crop of the court, `court-<scene>-x6.png` (6 device px per game px, as the iPhone 17 Pro shows the
game). About 3 s each; the CPU stayed below 45 °C. The M3 strips are not in `mock.py`'s contract table (SPRITES.md's M3
table has no frame column), so every court extra names its frame count. The seated king, a proposal, comes from a mock
root of symlinks (`build/recraft/lh/court/mockroot/`: the game's Core, Render, SPRITES.md and every Resources/Art PNG,
plus the proposals); nothing is written into Resources/Art.

| scene | what it shows |
|---|---|
| `hall-day` (focus 1820, noon) | the great hall: the king on the throne (the seated proposal, turned to the petitioners), Odile at his side, the waiting petitioners and townsfolk at the benches' place (x 1738-1792: citizenC, citizen, petitionerE, citizenB, petitionerD; no bench sprite yet), Pip juggling between them and the throne |
| `hall-night` (focus 1800, tod 0.95) | Seren in the hall's left corner with her cold lantern, Odile with the ledger by the throne, Mother Hesper at the hearth with her staff's flame |
| `hall-herald` (focus 1810, dusk) | the herald of the Lightless King before the throne, banner up; the king seated, Odile, Brannock, a guard |
| `courtyard-day` (focus 1590, noon) | Brannock before the barracks (fist raised), Bram at the smithy's forge, Tamsin at the well with her ladle up, the king, Marek by the lodge offering a bargain |
| `courtyard-guests` (focus 1590, afternoon) | Ser Ludo marching in past the barracks and a guard, the bard playing at the well, the king, the envoy holding out his scroll |
| `lineup-day` (focus 1830, noon) | every court member, guest and petitioner body in a row across the hall, the king first for scale |
| `lineup-night` (tod 0.95) | the same row at night: the hearth, the candles, the king's lantern, Hesper's flame, Seren's lantern, the herald's eyes and rim |

Day and night sheets of every sprite (`actorart.py sheet <id> --frames 8`): `build/recraft/lh/preview/court/sheets/`.

## Deviations and notes for the lead

1. **The king seated.** SPRITES.md has no seated pose, but the audience starts when the king sits on the throne. The
   lane painted a proposal, `kingSeated` (16x30, 2 frames: seated, a breath), from the king's own crown, head, cloak,
   tunic and lantern pole with the thighs forward on the throne's cushion (y 8) and the shins to the floor
   (`tools/grids/court/proposals/kingSeated.txt`, built only for the mocks). If the lead takes it into the contract,
   `build-art-court.sh` builds it into Resources/Art with one line.
2. **Sitting on the benches.** The petitioner bodies (and the townsfolk) have no sit frame, so the mocks show them
   standing at the benches' place. A sit frame (a 7th frame, the body on a bench 8 px high) would let them wait seated;
   until then they can wait standing in a queue.
3. **Odile's plum.** The palette has no plum and this lane may add only the swap ramps. Her robe is an aubergine
   (rockDeep with night2 folds and a stoneMid lit fold) open over a rose (dusk) facing, hem and cuffs, which reads as a
   dark wine-plum robe. For a truer plum the lead could add a plum albedo ramp (the cloth swap target's #3A1A36,
   #5E2E58, #8A4E80 would fit).
4. **Pip's red** is the rose `dusk` with `tile` shadows (`tile` alone read brown beside the teal).
5. **Seren's cold light** uses albedo colours as glow (foam glass, a moon-blue frame): every emissive entry is warm,
   teal or violet. The engine draws a glow pixel as its own colour, so this works; a tagged cold emissive entry would
   need the lead's palette decision.
6. **Pip is 19 px tall** in a 22 px frame (his cap tops out at row 3) so that the juggled balls fly over his cap inside
   the frame in talk 6-7.
7. **mock.py and actorart.py sheet** read frame counts from SPRITES.md's tables; the M3 table has a "who" column
   instead of frames, so both need the count passed (`frames` in the extras, `--frames` for the sheet). A frame column
   in the M3 table would make them work unaided.
8. The code lane needs the `SpriteID` cases and frame counts (court 8, petitioners 6, the glow strips), and the glow
   anchors above (Hesper's flame and Seren's lantern as small light sources if wanted).

## Lessons

- A prop held at face height becomes part of the face: Tamsin's ladle bowl in front of her nose read as a grey beak;
  carried by the hip it reads as a ladle. The same as the builder's mallet in ART-actors.md.
- A 2-px dark mouth under a nose reads as a moustache; a smile at this size is one warm pixel or none.
- A big white apron on a round body reads as a penguin: a cream apron narrower than the dress, tied at the waist, keeps
  the dress around it.
- An arm drawn as a filled mass reads as a second face (Bram); a bent arm needs the gap between upper arm and forearm
  to show the body behind.
- A prop that lies inside the silhouette loses its outline: Seren's lantern only read once it hung clear of the cloak.
- Grey hair plus a grey beard plus teal cloth made Brannock a second king; bald with an iron-grey beard he is himself.
- A hood's gold edge beside a dark face reads as a mask edge; white brows and a plain cream hood show the face.
- A frame-height juggle needs headroom: the figure, not the balls, gives way.

## Open points

- Step 2: the story portraits and the composed portrait parts on one head template, with the swap ramps in
  `palette.txt` (and `pixelart.py` taught to skip `swap` entries).
- Later steps: the rooms (`hallFront`, `chapelInterior`, `kitchenInterior`) and the props (`bench`, `taxLectern`,
  `marekCart`, `statue`, `speakerMark`); the hall mocks then get the benches, Marek his cart.
- The lead's decisions on the seated king, sit frames, a plum ramp and a cold glow colour (above).
- The faces stay one eye pixel, as the M2b cast; the audience card's portraits carry the expressions.
