# Lanternhold: the court and the guests (M3 art lane, step 1, 09.11.2026)

Every actor of SPRITES.md "M3, Court and guests" is real pixel art now: 14 sprites and 3 glow strips in
`Resources/Art/`, each exactly its contract size (one row of frames, frame width × frames by height), 8-bit RGBA,
binary alpha, colours from `tools/palette.txt` only. Everything faces right, the feet stand on the bottom row in every
frame, and the figure stands on the frame's bottom centre (within the existing cast's 1 px). They are drawn in the
style of the M2b cast (ART-actors.md): hand-set part grids, a 1 px ink outline, two or three tones per material, one
ink pixel for an eye, the head in profile on a three-quarter body.

Each one reads at device scale by silhouette and colour, distinct from the others and from the townsfolk, soldiers and
creatures (see `court-lineup-day-x6.png` below): a tall dark column with a grey bun (Odile), a broad bald man in teal
and steel (Brannock), a small jester's two horns (Pip), an old dark face under a gold-ochre hooded mantle with a little
flame at her chin (Hesper, since the fix stage), a round woman with auburn hair under a teal kerchief and a white apron
(Tamsin), a bald black beard with a hammer and bare arms (Bram), a wide hat with a rose feather over a long green coat
(Marek), a blue-grey hood with a pale lantern (Seren), a bucket helm on a skinny knight (Ser Ludo), a rose cap over
ginger-gold curls and a lute (the bard), a sea-blue coat with a scroll case (the envoy), an ash figure with a spiked
circlet and a black banner (the herald), a blond braid with a rose shawl and a basket (petitionerD), a red velvet cap
over a fur-trimmed teal gown with a gold chain (petitionerE, since the fix stage).

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
| `hesper` | 14x30 × 8 | walk 0-3 (slow, the staff carried before her, the body bobbing a pixel), idle 4-5 (a breath; the flame flickers through four shapes), talk 6-7 (the staff lifted 2 px off the ground and the flame flaring up tall beside her face, the head drawn back a pixel; then lowered, her free hand on her heart) | fix stage: an old woman, a little stooped, the dark face 4-5 px wide (a rockLight cheek on soilLight, one eye, the nose) with white hair at the crown and the temple; a broad gold-ochre mantle of her order (straw, strawLight, a gold edge, woodLight shade) over both shoulders and down her back to the hem, its rounded hood pushed back with its inside dark beside the face; the cream robe only in front, a gold hem; a short crook staff in her near hand, its iron cup at her chest with the flame before her chin; `hesperGlow` is the flame (fireWhite core, fireGold, fireOrange) over strawLight, gold and straw albedo, 7 glow pixels (10 in talk 6) |
| `tamsin` | 14x28 × 8 | walk 0-3 (a rolling waddle), idle 4-5 (a breath), talk 6-7 (fix stage: the ladle kept low while she wags a finger of her free hand before her chest; then the ladle pointed forward like a finger) | round and rosy: a teal kerchief with a fold across it, knotted behind the head with two short tails sticking out, her auburn hair showing at the forehead, the temple and the nape; a rosy cheek; a red-brown dress with rolled sleeves over bare forearms, a white apron with a bib tied at the waist; a long wooden ladle with an iron bowl hanging from her fist |
| `bram` | 16x30 × 8 | walk 0-3 (heavy steps, the free arm swinging), idle 4-5 (a slow breath), talk 6-7 (few words: he swings the hammer down and points with it; then holds it low before him) | huge, bald, a short black beard, soot on his brow and cheek; bare arms like hams with soot to the elbows (the near arm bent, the fist on the hammer's handle at his chest); a dark shirt under a long leather apron with a bib; the smith's hammer over his near shoulder, its iron head behind his neck (never before the face, ART-actors.md lessons) |
| `marek` | 14x30 × 8 | walk 0-3 (a jaunty step, the coat tails swinging), idle 4-5 (thumb in his strap), talk 6-7 (he tips his hat; then turns an open palm up with a ring glinting: a bargain) | a wide floppy dark hat with a long rose feather sweeping back, a sly face (medium brown skin) with a curled black moustache; a long green coat to the shins with gold buttons and trim; a leather satchel with a gold buckle on a strap across the chest, riding on his back hip; gold rings |
| `seren` | 14x30 × 8 | walk 0-3 (a quiet glide, the lantern swaying on its chain), idle 4-5 (still, the lantern sways), talk 6-7 (the lantern lifted to the hood; then lowered, her free hand opening) | tall in a long hooded cloak of cool blue-grey (the far ramp, so she parts from the hall's violet stone) with a tattered hem and a pale clasp at the throat; the face stays in the hood's shadow (only a pale chin); a small iron lantern held low in front, clear of the cloak; `serenGlow` is its cold light: foam glass, the frame lit moon blue |
| `serLudo` | 16x30 × 8 | walk 0-3 (a proud march: contact, a high step on each leg, the helm wobbling), idle 4-5 (chest out, a breath), talk 6-7 (he lifts the visor and two earnest eyes peer out; then thrusts his sword up beside the helm) | comic: a great bucket helm far too big for him, dented on top, its breathing slits dark, sitting on his shoulders; a long rose plume drooping wilted down its back; a skinny frame in a yellow surcoat with a red chevron, baggy mail on thin legs, big boots; a battered red heater shield with a yellow bend and a dent, a small sword at the hip |
| `bard` | 12x28 × 8 | walk 0-3 (a light step, the lute bobbing), idle 4-5 (fingers on the strings), talk 6-7 (strumming, the hand up and down, singing with an open mouth) | a floppy rose-red cap (dusk over tile) with a long white feather, ginger-gold curls (straw and woodLight, as his portrait), a spring-green doublet with cream puffed sleeves and a gold sash, dark hose; a round-bellied lute across his front, sound hole, the neck angled forward at chest height (rows 11-13) with the fretting hand on it |
| `envoy` | 14x30 × 8 | walk 0-3 (an upright, measured step), idle 4-5 (hands folded), talk 6-7 (holds out a sealed scroll; then opens his palm) | dark skin and a close black beard, a sea-blue round cap with a silver brooch, a long sea-blue coat with a white collar and silver buttons, grey hose; a leather scroll case with gold caps slung along his back, its cap showing over the shoulder (a teaser for chapter 2's coast) |
| `herald` | 14x30 × 8 | walk 0-3 (a stiff, deliberate step), idle 4-5 (utterly still but for a breath), talk 6-7 (the banner thrust up; then the bony free hand raised, pointing) | a gaunt figure the colour of ash: a black iron circlet with three spikes (the Lightless King's crown in small), hollow eye sockets, a black mantle over ragged ash-grey robes, a tall black pole before him with a tattered black banner on its crossbar, the King's sign on it (a small cracked crown); `heraldGlow` as `lightlessKingGlow`: tealGlow eyes, a tealDim rim on the top contour (`rim tealDim tealGlow`: tealGlow on the spikes and the pole's point), the crown on the banner and its torn edge tealDim |
| `petitionerD` | 12x26 × 6 | walk 0-3 (a light quick step, the braid swinging), idle 4-5 (a breath, the basket held close) | a young townswoman, bare-headed with a long blond braid, a rose shawl, a lavender dress, a basket of bread and flowers in both hands (the townswoman `citizen` wears a cream headscarf, a red-brown dress and carries her basket on one arm) |
| `petitionerE` | 12x26 × 6 | walk 0-3 (a self-important waddle), idle 4-5 (a breath, his hand at his belt) | a well-off townsman, portly, a neat grey beard; fix stage: a brimless soft cap of red velvet (dusk over tile) drooping over the back of his head with a gold brooch, a teal gown to the knees with wide sleeves and pale fur at the collar, the cuffs and the hem, a gold chain over the shoulders, the belt low at the hip, buckled shoes |

Glow strips: `hesperGlow`, `serenGlow`, `heraldGlow` (body size and frames). The body pixel under a glow pixel is a
pale or warm albedo (strawLight under the flame, stonePale under the lantern glass, night0 under the herald's eyes),
so by day a dimmed glow still reads as flame, glass and eyes.

### Glow positions (from the anchor: dx right, dy up from the bottom row; facing right)

| sprite | position | notes |
|---|---|---|
| hesper | fix stage: flame (+5.5, 19) in frames 0, 2, 4, 7; (+5.5, 18) in the bob frames 1, 3, 5; (+5.5, 22) in talk 6 (the staff lifted, the flame tall) | 7 glow pixels (10 in talk 6) before her chin, was (+5.5, 27.5) on a pole above her head; a small light (candle-sized) would sit there and light her face |
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

- Step 2 (the portraits and the composed parts): done, see "Step 2: the portraits" below (the swap ramps are in
  `palette.txt`, and `pixelart.py` skips `swap` entries unless `--allow-swap`).
- Later steps: the rooms (`hallFront`, `chapelInterior`, `kitchenInterior`) and the props (`bench`, `taxLectern`,
  `marekCart`, `statue`, `speakerMark`); the hall mocks then get the benches, Marek his cart. Done in step 3 (below).
- The lead's decisions on the seated king, sit frames, a plum ramp and a cold glow colour (above).
- The faces stay one eye pixel, as the M2b cast; the audience card's portraits carry the expressions.

# Step 2: the portraits (09.11.2026)

Every portrait id of SPRITES.md "M3", "Portraits" is real pixel art now: the 13 story and guest portraits (14 frames:
`portraitSeren` hooded 0, revealed 1) and the 5 composed portrait parts (36 frames), each 48x48 per frame in one
horizontal strip, 8-bit RGBA, binary alpha, palette colours only. Frame 0 of `portraitBeard`, `portraitHair` and
`portraitHat` is empty, as the contract says. The story portraits use no swap colour and no emissive colour; the parts
use the three swap ramps for skin, hair and cloth and fixed colours for the rest (ink, the eyes, metal, straw, leather,
linen, fur, gold, leaves and flowers).

Every bust is turned three-quarters to the right and lit warmly from the left (the hall's hearth side): the light
falls from the upper left front, the far cheek turns into shadow, and the outermost left pixel of every row of the
silhouette catches the hearth (two steps up the material's own ramp, so the rim swaps with the colours of a composed
petitioner). On the audience card's dusk tile (UI/SpriteThumbnail.swift's gradient) at 3 device px per art pixel each
story character reads at a glance: Odile's beak of a nose, grey bun and chain of office; Brannock's scar, bald head and
square grey beard in steel and teal; Pip's two-horned cap and grin; Mother Hesper's dark calm face in the cream hood;
Tamsin's teal kerchief, rosy cheeks and smile; Bram's soot, black beard and the hammer over his shoulder; Marek's wide
hat, rose feather and curled moustache; Seren's face lost in the hood, then pale and haunted under ash-silver hair; Ser
Ludo's bucket helm with two earnest eyes in the visor; the bard's ginger curls, beret and wink; the envoy's sea-blue
cap and coat; the herald's spiked iron circlet and cold teal eyes before a tattered banner; the old lamplighter king
under a crown a size too big.

## Credits (step 2)

Recraft: **391 before, 356 after: 35 spent** (one image; the lane's budget was 300). The sheet was a test of the
expected route, "Recraft painted portraits converted with pixelart.py and hand-fixed", and became a design reference
only:

- `p1` (1:1, `recraftv4_1`, `build/recraft/lh/court/portraits/p1-1.png`, git-ignored): "Four separate
  head-and-shoulders portraits of medieval fantasy characters in a 2x2 grid with wide gaps, same scale and framing,
  each face turned three-quarters to the right, warm firelight from the left, cool shadows on the right. Top left:
  elderly thin chancellor woman, long sharp nose, one eyebrow raised dryly, thin lips, grey hair in a high bun, plum
  robe, rose collar, silver chain with gold seal. Top right: gruff broad old guard captain, bald with grey fringe,
  short square grey beard, scar through one eye, steel pauldrons, mail, teal surcoat with gold lantern emblem. Bottom
  left: small cheeky jester, wide grin, rosy cheeks, two-horned cap teal and crimson with gold bells, cream ruff, teal
  and crimson motley. Bottom right: serene old priestess, dark brown skin, white eyebrows, calm smile, deep cream hood,
  cream cape edged in gold with a gold flame emblem. Pixel art, clean hard edges, no anti-aliasing, limited palette,
  simple cel shading, dark outlines, flat solid magenta #FF00FF background, no text, no border." (1028 characters,
  accepted.)
- Converted to 48x48 (`convert --fit contain --outline ink`, full palette), the test showed why the route does not
  carry: the plum robe and the crimson motley lay inside the key distance of the hot-pink background and vanished; at a
  10x downscale the faces fell apart into blotches (the eyes into specks, Odile's nose into a spike, Hesper's closed
  eyes into mud); the cartoon outlines became heavy ink masses; the four portraits differ in scale and turn; and the
  composed parts must share one template pixel for pixel, which no painting gives. Brannock converted well, and the
  sheet's designs (his scar and pauldrons, Hesper's hood, Odile's long nose and dry brow) went into the rendered
  portraits. The other 356 credits stay for the next lanes.

## Pipeline (step 2)

| File | What it does |
|---|---|
| `tools/portraitart.py` | the renderer and the commands: `build <id>` renders one sprite id into Resources/Art (or `--out`), `list` names the 18 ids, `sheet story\|composed\|parts\|archetypes\|card` makes the contact sheets below. Signed-distance primitives (ellipsoids, capsules, round cones, boxes, tori, chains) are ray-marched in an orthographic view at one unit per pixel, 2x2 rays per pixel for coverage (a pixel is drawn when half of them hit), the normal from the field, Lambert with a little wrap and ambient occlusion; the light is cut into the material's palette ramp (2 to 5 colours) after an optional texture (hair strands fanning from a whorl, folds, ring mail, fur, curls); lone pixels are tidied; then the outline (ink, or over a face the material's darkest tone), the hearth rim and the hand-set stamps. Pure python, deterministic |
| `tools/portraitkit.py` | the head template and the composed parts: the six faces, seven hair styles, five beards, seven hats, eight garments, the feature stamps (eyes, brows, mouths, the ear, the nose's lit bridge, age lines) and the garments' hand-set necklines |
| `tools/portraitstory.py` | the 13 story portraits, each one scene of the template's head with the character's own hair, hat, clothes and props in the court's colours (step 1's sprites), then depth edges (where a part lies in front of another, the pixel behind it takes a darker step: the contact line the composed parts draw with their outlines), the outline, the rim and the stamps. Since the fix stage it renders drafts only (`portraitart.py build <story id> --out DIR`): the story portraits are frozen grids (below) |
| `tools/grids/court/portraits/<id>.txt` | fix stage: the 13 story portraits (14 frames) frozen from the render by `portraitart.py freeze` as actorart.py specs (one 48x48 grid per frame, the fixed legend `FREEZE_LETTERS`, no outline directive: the outline is in the pixels) and hand-finished there; `actorart.py build` writes the PNG, so these no longer depend on float maths |
| `tools/build-art-court.sh` | builds the 5 composed parts with `portraitart.py` (4 s pause after each) and the 13 story portraits from their frozen grids with `actorart.py`, after the 14 court sprites (one at a time, the heat wait at 80 °C); `build-art.sh` runs the lane whole |

A sprite renders in 3 to 15 s (a part strip with its face union up to about 20 s); the lane's 18 portraits take about
4 minutes with the pauses. The renders are float maths, so the byte-for-byte rebuild is checked on this Mac (python 3
of macOS); another machine could differ in a pixel at a threshold.

**Reproducible:** one `build-art.sh` call in a scratch copy of the committed tree (`git archive` of the lane's head)
with `Resources/Art` emptied and the Recraft raws copied from `build/recraft/lh/` rebuilt all 158 PNGs byte for byte
(140 earlier ones and the 18 portrait ids); no file missing, no extra file, in 6 min 47 s without a heat wait (the CPU
stayed under 80 °C). The only warnings are the old ones of `ashGiant` and `lightlessKing`. Two separate lane runs of the
18 portraits also wrote the same bytes.

### The head template (world pixels: x right, y down, 48x48)

| Landmark | Where |
|---|---|
| head frame | centre (23, 21.5), turned 34 degrees to the right, 1.15 px per unit; the far half (local x > 0) foreshortened to 0.78, as a portraitist cheats a three-quarter view, so the far eye sits at the contour and a long nose can break it |
| cranium | top at y 5-6 (bald), the back of the skull at x 10-11; shared by every face, so hair, hats and beards fit them all |
| eyes | near eye centred at (25, 19), far eye at (31, 19); the brows 3 rows above; the child's eyes at y 22 |
| nose, mouth, chin | nose tip (31, 25); mouth (30, 28), the long face's (29, 29); chin (29, 32), the long face's (28, 33); the child's mouth (29, 29), chin (28, 31) |
| ear | its landmark at (13, 21): a hand-set ear (lit helix, dark bowl, lobe) over the rendered one |
| neck | cut at y 36 in the composed face (its front meets the garments' necklines); a darker material under the jaw |
| shoulders | the bust's top runs from the neck's sides at y 34-36 out to the shoulders at y 40-42; the chest fills the bottom rows, the near (left) shoulder broader |

### The composed parts (frames as PortraitPart in the code lane's CourtSpeakers.swift)

| id | frames |
|---|---|
| `portraitClothes` | 0 smock (a gathered neckline, a cord bow), 1 dress with apron (a square neckline over a linen chemise, the white bib on straps), 2 tunic (a V-neck with the chest's skin and crossed laces), 3 fine coat (a pale fur collar round the neck and down the lapel, a white shirt, gold buttons), 4 leather apron (a long leather bib on straps with rivets over the sleeved shirt), 5 mail and surcoat (ring mail on the shoulders and a mail collar, the surcoat with the realm's gold lantern), 6 robe (a thick rolled collar, a trimmed front opening), 7 rags (a torn neckline, two stitched patches, a rope) |
| `portraitFace` | fix stage, the variants exaggerated: 0 round (the jaw 2 px wider, a short chin, a button nose lit only at its lower bridge), 1 long (a narrow face, the chin 3 px longer, a longer and narrower nose, a hollow under the cheekbone), 2 square (the jaw corners 2 px wider over a flat chin, heavy brows), 3 old and wrinkled (jowls, lidded eyes, brow lines, crow's feet, folds by the nose and mouth; as before), 4 young (a smooth narrow jaw, a nose a pixel smaller, a larger eye with a catchlight), 5 child (the shared cranium over a small round lower face: eyes, nose and mouth lower and smaller, a thin neck; as before); every adult face but the old one softened: the nose a pixel less prominent with a shorter shadow under the tip, a 1 px lash flicking up from the near eye's outer corner, softer mouths with a lit lower lip, so a face reads as a woman's under women's hair and as a man's through a beard or stubble; brows are in the hair ramp, so they take the hair's colour |
| `portraitBeard` | 0 none, 1 stubble (a sparse random grain of the hair ramp, no outline), 2 short and 3 full (fix stage: the top runs on the screen diagonally from the sideburn at x 15, y 22 down along the jaw to the mouth corner at x 27, y 28, ragged, the cheek above it in skin; the full beard a pixel higher and bushier; no outline where the beard lies over a face, a broken hair2/hair3 edge there instead, one edge pixel in four dropped; hair4 strands on its lit left side; a hand-set moustache over the upper lip at rows 26-27, lit on the left, its ends drooping at the mouth corners, the lower lip lit in skin3/skin4 below it and the skin under the lip, the chin beard from row 30, so every face gets the same mouth inside a beard), 4 long (the full beard with a pointed fall onto the chest; the same top line and mouth), 5 moustache (a walrus moustache under the nose); beards are built on the widest adult jaw so they cover every adult face (on the round face the short beard hangs a little below the chin) |
| `portraitHair` | 0 bald, 1 short (a fringe of locks), 2 long (to the shoulders, a strand behind the far cheek), 3 bun (pulled back, the bun high at the back), 4 curly, 5 braids (two braids with ties in the cloth ramp, so they take the clothes' colour), 6 tousled, 7 child's mop (a bowl cut with a fringe to the brows) |
| `portraitHat` | 0 none, 1 straw hat (tipped forward so the brim's top shows, a band in the cloth ramp), 2 headscarf (knotted at the nape with tails), 3 cap with feather (fix stage: a soft cap whose crown covers the top of the skull, 4-5 px tall, and droops to the back, a turned-up brim at the front, the white plume rising from the side band at the back and sweeping back; clipped against the faces as before), 4 hood (to the shoulders, its inside dark around the face), 5 wool cap (a turned-up cuff, a top knot), 6 helm (steel with a ridge, a rim and a nasal on the nose), 7 flower wreath (leaves and rose, gold and white flowers) |

How they fit: every part is rendered on the same head frame, and everything that lies behind any face (a hood's
inside, the back of a brim, hair behind the neck) is clipped against the union of all six faces, so no part paints over
a face it might be drawn on; small islands the clip leaves are dropped. The garments' neck openings meet the face's cut
neck at y 36; their collars lie below it, in front of where the neck would go on.

The child has the shared cranium with a smaller, lower face, so the shared hair (braids), the wool cap and the wreath
fit it too (they look a little big on a child, which reads as a child); the child's mop is made for it.

### The story portraits

| id | who, as the portrait shows them (colours from step 1's sprites) |
|---|---|
| `portraitOdile` | fix stage: the long face with the jaw narrowed and the cheek hollow, a hand-set thin wedge of a nose breaking the profile (2 px tall at the tip, 3-4 px beyond the cheek, hooked a little down, one shadow row under the tip, no highlight, no nostril), the near eye half-lidded under a level brow, the far brow arched, a thin mouth with its far corner up and a lit lower lip; grey hair pulled up into a high bun with a pin; the aubergine robe (night2, rockDeep, stoneMid) with a standing collar lined in rose, open down the front over the rose facing (dusk over tile), the silver chain of office with its gold seal on it |
| `portraitBrannock` | fix stage: a narrower, longer head than Bram's, bald with a grey fringe round the back and a small highlight, heavy frowning brows, a hooked nose breaking the profile, a clear scar (a pale seam with a dark edge) from the brow through the near eye to the cheek, a short square iron-grey beard; pauldrons of three steel plates a side with lit top edges and dark seams (the far side in shade), mail below and at the throat, the teal surcoat with the gold lantern |
| `portraitPip` | the young face with a wide grin (teeth), a rosy cheek, wide eyes and raised brows; the two-horned cap (the back horn teal, the front rose-red; fix stage: its dome dusk over tile, no longer the face's dawnRose) with a gold band and a gold bell on each drooping tip; fix stage: a pleated ruff right round the neck under the chin (17 px wide, 4 rows, parchment and plasterDim pleats by column, a scalloped hem), the motley split teal and rose-red closed below it |
| `portraitHesper` | fix stage: the old face with dark skin (woodDark, soil, soilLight, rockLight), white hair at the forehead and temple, white brows and eyes closed in a gentle smile; the gold-ochre mantle of her sprite with a smaller hood pushed back off the forehead (its inside in shadow along the gold-trimmed opening, three gathered folds behind the neck), the mantle over the shoulders, the cream robe in a V between gold-trimmed edges |
| `portraitTamsin` | the round face with rosy cheeks and a broad smile; fix stage: the teal kerchief over the crown with two folds, its edge above the ear and the nape, her auburn curls at the forehead, the temple and the nape below it, the knot well behind the head with two short tails sticking out; the red-brown dress with the white apron's bib |
| `portraitBram` | fix stage: a broad flat bald skull on a thick neck, small eyes under flat heavy brows (few words), a short black beard, one soft wipe of soot across the brow and one smudge on the near cheek (grey at the core, the skin's shade at the edge); broad shoulders in a dark shirt under the leather apron's straps and bib; the hammer's handle over his near shoulder, its iron head behind his neck |
| `portraitMarek` | the long face with medium brown skin, a curled black moustache, one brow up and a sly squint; the wide floppy dark hat with a gold band and a long rose feather sweeping back; the green coat with gold trim, the satchel's leather strap with its gold buckle |
| `portraitSeren` | frame 0: the deep blue-grey hood (night1, farDeep, far) with the face in its shadow, only a pale chin and two faint glints, the pale clasp at her throat; fix stage: three folds in the hood (from the crown down the back, down the middle, along the opening); frame 1: the hood thrown back into a thick fold (two creases), a pale haunted face (shadows under and over the eyes, a thin mouth) and long ash-silver hair, the same cloak |
| `portraitSerLudo` | the bucket helm far too big for him, dented at the top, its visor lifted so two earnest eyes peer out of the dark slot, a light band over it, breathing holes and rivets; the wilted rose plume drooping down its back; the yellow surcoat with a red chevron over baggy mail |
| `portraitBard` | the young face, singing with a wink; fix stage: ginger-gold curls (wood, woodLight, straw: one hair colour with his sprite), a soft rose-red beret (dusk over tile) drooping over the back of his head with its crown puffed over a darker band and a white feather set into the band; the spring-green doublet with a standing collar and buttons, slashed cream puffs on the shoulders with the green in the slashes, the gold sash |
| `portraitEnvoy` | the long face with dark skin and a close black beard; the sea-blue round cap with a silver brooch; the sea-blue coat with silver buttons; the scroll case's gold cap over his near shoulder |
| `portraitHerald` | the gaunt long face, ash-grey, hollow cheeks, eyes sunk in black sockets with cold teal pupils (daySky and roofLight: albedo, the portrait has no glow strip); the black iron circlet with three spikes; the black mantle with a high collar over ragged ash robes; behind his near shoulder the black pole with a tattered banner and the King's small cracked crown |
| `portraitKing` | the round old face with kind lidded eyes, white hair and a full white beard; the gold crown a size too big, tilted, with a teal stone; the realm's teal cloak with a gold clasp over the red-brown tunic |

## Contact sheets (step 2, git-ignored, `build/recraft/lh/preview/court/portraits/`)

| sheet | what it shows |
|---|---|
| `story-x3.png` | all 14 story portrait frames on the card's framed dusk tile at 3 device px per art pixel (the card's scale) |
| `story-x6.png` | the same at 6 px per art pixel, for the details |
| `composed-30-x3.png` | 30 random composed petitioners (seed 1): each a random clothes, face, beard (none for women), hair and hat with random target ramps for skin, hair and cloth from SPRITES.md, composed exactly as the code lane's `PortraitComposer` (the parts in order, the "none" frames skipped, each swap ramp mapped colour for colour) |
| `parts-x3.png` | every part frame on the template: each face with each beard (and short hair), each hair on the round and the child face, each hat over short and long hair, each garment under the square face |
| `archetypes-x3.png` | four draws of each townsfolk archetype of the code lane's speaker registry (farmer, farmwife, townswoman, townsman, merchant, soldier, builder, widow, child, noble, refugee) |
| `card-x3.png` | a rough audience card (parchment, the framed tile, ink bars for the text and choices) with Odile, a composed widow and the herald: the portraits' contrast on the card |

## Notes for the lead and the code lane (step 2)

1. **The method.** The portraits are rendered from forms and hand-finished, not converted from Recraft paintings (see
   the credits): a 10x downscale of a painting does not survive in a face of 48 px, and only a shared rendered
   template lets the composed parts fit each other pixel for pixel and the story portraits share their scale and
   style.
2. **No new palette colours** but the three swap ramps. Skin in the story portraits uses the court's colours
   (dawnRose over tileLight for rosy skin, soil and soilLight for Hesper and the envoy, wood and woodLight for Marek,
   the stone ramp for the herald and for Seren's pale face). (Fix stage: see "Fix stage", the skin ramp proposal.) The step from dawnRose (L 75) to tileLight (L 52) is wide
   for a face; a mid tone between them would soften the faces if the lead adds one (for example the light skin target
   #DE9E78).
3. **The herald's eyes** are daySky and roofLight albedo (the portraits have no glow strips); `tealGlow` would be
   brighter if the card may use an emissive colour.
4. **Seren's portrait frames** follow `Speakers.portraitFrame` (hooded 0 before day 15, revealed 1 after).
5. **The parts' outlines** are drawn per part: around the outer silhouette in ink, over a face in the part's darkest
   tone (a hairline or a beard's edge is dark hair, not an ink line). The composer must draw the layers in the
   contract's order with "over" for opaque texels, as `PortraitComposer.over` does.
6. **The code lane's archetypes** compose well (`archetypes-x3.png`). A child with braids or a wool cap wears them a
   little big, which reads as a child; beards are never drawn on a child.
7. **The atlas** grows by 50 frames of 48x48 (115,200 texels) with the portraits.

## Lessons (step 2)

- A three-quarter head rendered truthfully leaves 3-4 px of far cheek beyond the far eye, and the nose never breaks the
  contour; foreshortening the far half (what a portraitist does by eye) makes the turn read at 48 px.
- A light from the side the face turns away from leaves the mouth in the shadow band: mouths need a frontal key light
  and a lit lower lip, or dark-on-dark they vanish.
- A jaw built as one ellipsoid hangs down to the collar and hides the neck; mandible strokes from the jaw's angles to
  the chin give the jaw line and a shadowed neck below it.
- Beards read as masks when their top is a straight line under the eyes: the line must run from the sideburn down
  under the cheekbone, ragged, and the lips must stay free.
- In a single-material test (distance to an inner shell) the hood's outside counted as its inside and made a bullseye;
  the inside is where the solid's cut lies within the outer volume.
- A rim of light on the left silhouette, two steps up the material's own ramp, separates dark hats, hoods and armour
  from the dusk tile and still swaps with the petitioners' colours.
- The parts fit only because every one is clipped against the union of all faces: a hood's inside, the back of a brim,
  hair behind the neck never paint over a face they might be drawn on.

## Open points (step 2)

- The story portraits share one framing; the endings and the prologue may want the king in other moods (a second
  frame) later.
- The faces keep the template's eye and mouth stamps; more expressions (anger, fear, tears) would be new stamps if the
  petitions need them.
- The rebuild is float maths: byte for byte on this Mac (checked, see "Reproducible"), possibly a pixel off on
  another machine; if that ever matters, the portraits can be frozen as text grids (`actorart.py dump`).

# Step 3: the castle's rooms and the court's props (09.11.2026)

Every room and prop id of SPRITES.md "M3" ("The castle's rooms", "Props for the court") is real pixel art now: the
great hall's front, the chapel of the Flame and the castle kitchen inside, the petitioners' bench, the tax lectern,
Marek's cart, the statue of the lamplighter king and the speech mark; 8-bit RGBA, binary alpha, palette colours only,
albedo in even daylight (no glow, no baked night, no light pools: the renderer lights the rooms). Each interior and its
front share one silhouette pixel for pixel (checked with `roomart.py silhouette`): `hallFront` is painted inside
`hallInterior`'s opaque pixels, `chapelInterior` inside `chapel`'s, `kitchenInterior` inside `kitchen`'s, so a front
that fades out never changes the room's outline. The chapel's and the kitchen's fronts keep their silhouettes; where
the interiors needed it they were touched up in albedo (below).

## Credits (step 3)

Recraft: **356 before, 356 after: 0 spent** (`bash tools/recraft.sh me` before and after; the task text's 391 was
the balance before step 2). The lane has spent 35 of its 300 in all. No painting was needed: the rooms must match their
fronts' silhouettes and the engine's anchors to the pixel, and their life is in details of 3 to 12 px, which a
downscaled painting turns to mush (ART-buildings.md: `court-a`; step 2: `p1`).

## Method and pipeline (step 3)

The rooms and props are painted in code, as the buildings lane hand-set its courtyard: a small deterministic palette
painter with material brushes for the large surfaces and hand-set stamps for the small things.

| File | What it does |
|---|---|
| `tools/roomart.py` | the painter: a canvas of palette names with an optional clip (a front's silhouette), shapes (rects, lines, polygons, ellipses, two-centred pointed and round arches), brushes (`ashlar` dressed courses with lit tops, joints and crevices; `planks`; `beam`; `post`; `slate`; `plaster`; `flagstones` and `floorboards` in perspective), stamps from text grids, and the commands `build <id> [--out DIR]`, `list`, `silhouette <a.png> <b.png>` (exit 1 when the opaque pixels differ) and `anchors <id>`. Integer hashing only (no random module, no trigonometry in the pixels), so a rebuild writes the same bytes |
| `tools/roomscenes.py` | one paint function per sprite (`hallFront`, `chapelInterior`, `kitchenInterior`, `bench`, `taxLectern`, `marekCart`, `statue`, `speakerMark`); each records its anchors (window glass masks, flames, lights, where the court stands) in the engine's convention, which `roomart.py anchors <id>` prints and the mocks read |
| `tools/grids/court/rooms/hall.txt`, `chapel.txt`, `kitchen.txt`, `cart.txt`, `props.txt` | the stamps: the banner's lantern emblem, wall lanterns, the notice board, the crest, logs, the chopping block, potted bays, pigeons; the frieze, capitals, the bell, stained-glass motifs, the saint's hood and rays, the altar, the Flame's bowl, candlesticks, candle stands, sconces, the vase, the sanctuary lamp, the pew; herbs, garlic, the ham, pots, plates, crocks, the jug, loaves, the cheese, the board and knife, apples, the table candle, the barrel, sacks, the cat and its stool, the broom, the cauldron, the peel, the sill pots, sausages, the utensil rack, the mouse hole; the cart's wares; the bench, the lectern, the speech mark and the statue's plinth |
| `tools/build-art-court.sh` | builds the eight ids with `roomart.py build` after step 1's sprites and step 2's portraits (`build-art.sh` runs the lane after the scene sprites, the buildings and the actors: `hallFront` reads `hallInterior.png`, the interiors read their fronts, the statue and the saint read `king.png`) |
| `tools/build-art.sh` | the `chapel` and `kitchen` steps gained a `post` line each (the touch-ups below); the conversions are unchanged |
| `tools/scenemock/scene_castle.py`, `run_castle.sh` | the context scenes (below), reusing scene_court.py's actors and mock root |

**Reproducible:** one `build-art.sh` call in a scratch copy of the committed tree (`git archive` of the lane's head)
with `Resources/Art` emptied and the Recraft raws copied from `build/recraft/lh/`: see "Rebuild check" at the end of
this step.

## Sprites (step 3)

| id | size | look |
|---|---|---|
| `hallFront` | 260x90 | the great hall's outer wall from the courtyard, inside `hallInterior`'s silhouette: its end walls, stacks and caps are the interior's own pixels (only the middle fades); a teal slate roof with ridge tiles and iron cresting on the interior's beam ends, a stone cornice on a corbel table, dressed stone courses; the main door (left, toward the courtyard) in a pointed arch of voussoirs on quoined jambs with oak leaves, iron straps, studs and ring handles, the realm's crest above, iron wall lanterns either side, potted bays at its foot; a notice board of decrees and petitions; three tall two-light windows with dark glass in lead cames (stoneDark, so the cames stay dark when the glass glows) and stone mullions; the two banners of the realm (deep teal, gold lantern, gold hem) hung on buttresses; the hearth's firewood stacked under a lean-to with a chopping block and an axe; ivy from the corner; pigeons on the cornice; moss at the plinth |
| `chapelInterior` | 160x96 | the chapel of the Flame inside, in `chapel`'s silhouette: a starry vault in the realm's teal with gold stars over timber ribs and a carved wall plate, a king-post truss in the chancel's gable; the belfry with its bronze bell, louvres and the spire's rafters, the bell rope with its striped grip down into the nave; cream lime-plaster walls under a red frieze of gold flames, an oak wainscot; two stone shafts with candle sconces; the four lancets at the front's lancets in stained glass (border quarries in teal and gold, a flame, a lantern, a star, a flame); the lamplighter saint as a painted relief in a starry niche (the old lamplighter in the cream and gold robe of the Flame's order, hooded, white-bearded, his lantern raised on its hooked pole, gilded rays; fix stage: a half-figure ending at row 63 over a carved plinth, rows 64-72 with a scroll of little flames and its plain base down to the altar, so the Flame burns before the plinth at his feet); the altar on the chancel step with its cream and gold frontal and the Flame's emblem, the Flame's gold-rimmed stone bowl, two gold candlesticks, two iron candle stands, a vase of lilies and roses; a sanctuary lamp with red glass on its chain; five pews facing the altar; flagstones and a red runner up the nave |
| `kitchenInterior` | 120x80 | the castle kitchen inside, in `kitchen`'s silhouette: the chimney stack as outside (the front's pixels), the room open to the rafters (ridge beam, purlin, hip rafters, the tie beam), the stone flue rising from the hearth into the stack with sausages smoking beside it; whitewashed walls between the timbers over a stone plinth; the two windows at the front's windows with daylight panes, cross bars and herb pots on the sills; herbs, garlic braids and a ham from the tie beam; copper pots and a pan on a rail; a shelf of plates, crocks and a jug; the oven-hearth under the flue: a stone hood, an oak mantel with a crock and a jug, stone jambs, a sooty fireback, the crane with the cauldron over the logs, a bread peel; the table with two loaves, a cheese, a board and knife, apples and a candle; a barrel, two flour sacks, a broom, a utensil rack; the ginger and white cat asleep on its stool by the fire; a mouse hole |
| `bench` | 32x10 | a petitioners' bench: an oak plank seat with a teal cushion and gold tassels on turned legs with a stretcher |
| `taxLectern` | 12x20 | the realm's ledger open on an oak desk (text lines, a red ribbon), a quill, a little stack of the day's coins on the post, a turned post on a base |
| `marekCart` | 48x30 | Marek's cart: a striped awning in rose and cream with a scalloped valance on two poles, a barrel, a crate with a rolled rug, bolts of cloth in teal, green and red, jugs, a lantern on the pole, his sign of a gold coin on the plank bed, two spoked wheels, the shafts resting on the ground |
| `statue` | 20x40 | the lamplighter king with his lantern raised: the king's command frame (`king` frame 8) carved colour for colour in pale stone (cloak, tunic, beard, crown and pole stay apart), the lantern's glass gilded, on a plinth with a cornice and a bronze plaque, moss at its foot |
| `speakerMark` | 7x7 x 2 | a parchment speech bubble with a red "!" and its tail down to the speaker; frame 1 (the pulse) lit gold |

### The fronts touched up (`build-art.sh`, albedo only, silhouettes unchanged)

- `chapel`: the gable end's painted night shade lifted one value step (night1, stoneMid, stoneDark, night0 each one
  step lighter in four rects round lancet 4, whose glass and frame stay dark); a small oak door with a stone lintel,
  iron straps and rings under lancet 4, where the painting left dark mud. Before, the right third of the chapel read as
  night by day and jumped from dark to bright when the front faded into the interior.
- `kitchen`: the same one-step lift on the ground floor's right corner (x 93-112, rows 57-79) and the stack's top; the
  roof's far hip and the stack's shaded half are kept.

## Anchors for the engine (sprite pixels; dx from the left edge, dy up from the bottom row, as ART-buildings.md)

Masks are tight to the panes (the engine glows every night0, night1 and ink pixel inside a mask). Lights are given as
(kind, cx, y, radius) in sprite pixels; add the room's world x (hall 1700, chapel 1960, kitchen 2120, cart 1486).

| sprite | what | where |
|---|---|---|
| `hallFront` | window glass | masks (dx 92, dy 18, w 9, h 32), (135, 18, 9, 32), (181, 18, 9, 32): the three windows' lights (mullions and cames stay dark); a window light (window, 8) at (cx 96, y 34), (139, 34), (185, 34) |
| `hallFront` | wall lanterns | glass masks (dx 26, dy 34, w 3, h 3) and (65, 34, 3, 3); lights (lantern, 24) at (cx 27, y 35) and (66, 35) |
| `hallFront` | door | the threshold gap under the leaves as a mask (dx 38, dy 8, w 18, h 1): warm light under the door at night |
| `chapel` (front) | lancet glass | masks (dx 24, dy 19, w 10, h 24), (60, 19, 10, 24), (95, 19, 10, 24), (129, 20, 9, 23) over the painted panes; the layout's `windowGlow` sprites at (dx 18, 54, 89, 125; dy 28) sit half on each lancet's left frame |
| `chapelInterior` | the Flame | `brazierFlame` at (dx 112, dy 23), its bottom row on the gold rim of the stone bowl on the altar; its light (brazier, 54) at (cx 116, y 26); fix stage: unchanged, it now burns before the saint relief's carved plinth (rows 64-72), no longer over his robe |
| `chapelInterior` | candles | `candleFlame` at (dx 108, dy 26) and (124, 26) on the altar candlesticks, lights (candle, 12) at (108, 27) and (124, 27); at (dx 99, dy 17) and (133, 17) on the candle stands, lights (candle, 12) at (99, 18) and (133, 18); at (dx 43, dy 38) and (76, 38) on the shafts' sconces, lights (candle, 14) at (43, 39) and (76, 39) |
| `chapelInterior` | sanctuary lamp | its red glass as a mask (dx 142, dy 39, w 2, h 2), a light (lantern, 22) at (cx 142, y 39) |
| `chapelInterior` | lancets | no masks: the stained glass is coloured albedo (it shows by day; at night it is dark, lit by the candles and the Flame) |
| `kitchen` (front) | window glass | four panes each: (dx 30, dy 36, w 3, h 3), (34, 36, 4, 3), (29, 32, 4, 3), (34, 32, 4, 3) and (83, 36, 4, 3), (88, 36, 4, 3), (83, 32, 4, 3), (88, 32, 4, 3) |
| `kitchenInterior` | the hearth fire | `hearthFire` at (dx 95, dy 5) on the logs between the jambs (the opening is 16 px wide); its light (hearth, 62) at (cx 103, y 9) |
| `kitchenInterior` | table candle | `candleFlame` at (dx 46, dy 18), a light (candle, 14) at (cx 47, y 19) |
| `kitchenInterior` | windows | no masks: the panes are daylight albedo (daySky with a foam glint), which the night ambient turns to moonlit glass |
| `marekCart` | lantern | glass mask (dx 37, dy 20, w 1, h 2), a light (lantern, 20) at (cx 37, y 20) |
| `bench`, `taxLectern`, `statue`, `speakerMark` | none | the bench seats two at dx 12 and 28 (the code lane's seats 1724, 1740 and 1772, 1788 at benches 1712 and 1760); the speech mark's tail is at its bottom left (dx 1-2): draw its bottom row about 2 px over the speaker's head |

### Where the court stands in the new rooms (dx in the sprite, facing +1 right)

| who | spot | world x | the code lane's number |
|---|---|---|---|
| Mother Hesper | at the altar, facing it (right) | 2058 (dx 98) | 2052: keep or move 6 px |
| Mother Hesper | by the pews, facing left | 2012 (dx 52) | 2010 |
| Tamsin | at the table (it stands at dx 20-56), facing right | 2158 (dx 38) | 2146 (then "the oven") |
| Tamsin | at the hearth (dx 94-112, under the chimney on the right), facing right | 2208 (dx 88) | 2196 (then "the table") |

The kitchen's hearth stands under the front's chimney (right), so Tamsin's two stops swap sides against the code lane's
first guess. The cat is painted into `kitchenInterior` (on its stool at dx 80-91, by the fire): static.

## Context scenes (step 3, `tools/scenemock/scene_castle.py`, `run_castle.sh`)

Each renders `build/recraft/lh/preview/castle-<scene>.png` (437x201 upscaled x3, the look of `run_actors.sh`) and a
device-scale crop of the room, `castle-<scene>-x6.png` (6 device px per game px). The rooms' emitters and lights come
from their recorded anchors. A closed scene draws the front over the interior and drops the interior's furniture and
lights (a wall hides them); an open scene draws the interior and the court. The courtyard is placed as the engine
draws it (DESIGN.md "M2b part 1": barracks 1481, smithy 1546, the layout's well, the lodge centred at 1648), so the
statue at 1680 stands free before the hall. About 4-7 s each; the CPU stayed under 50 °C.

| scene | focus, tod | shows |
|---|---|---|
| `hall-closed-day` | 1716, noon | the hall's front from the courtyard beside the lodge, the king walking up to it, Pip juggling |
| `hall-closed-night` | 1716, 0.95 | the same at night: the three windows glowing with their cames, the lanterns lighting the door, light under the door |
| `hall-open-day` | 1820, noon | the hall open: the benches and the tax lectern, the waiting petitioners, Pip juggling, the king seated (step 1's proposal), Odile at the lectern with the speech mark (frame 1) |
| `hall-open-night` | 1830, 0.95 | Seren in the far corner with her lantern, Odile, Hesper and Pip at the hearth, the speech mark (frame 0) over Odile |
| `chapel-open-day` | 2040, noon | the chapel open with Mother Hesper at the altar and the king in the nave; the hall's front closed on the left, the kitchen's front (touched up) on the right |
| `chapel-open-night` | 2040, 0.95 | the Flame, the altar candles, the stands and the sconces light the chapel warmly; the stained glass dark |
| `kitchen-open-day` | 2170, noon | the kitchen open with Tamsin at the table, the cat asleep on its stool by the fire, the king at the door; the chapel's front (touched up) on the left |
| `kitchen-open-night` | 2170, 0.95 | the hearth fire and the table candle; the windows moonlit |
| `courtyard-day` | 1600, noon | Marek's cart at 1486 with Marek, Bram, the king, Brannock, the statue at 1680 before the hall's closed front |
| `courtyard-night` | 1600, 0.95 | the same at night: the forge, the barracks' and the hall's lights, the cart's lantern |

## Notes for the lead and the code lane (step 3)

1. **Closed rooms hide what is inside.** While a front shows, the room's furniture (`throne`, `hearth`, the candle
   stands, the benches, the lectern) and its figures must be hidden or drawn before the front (actors draw after
   props), and the room's lights (the hearth's 70, the candles) should be off or very dim: through `hallFront` the
   hearth's light would paint a warm pool on the outer wall. The mocks drop them.
2. **The chapel's lancets** sit at the front's real lancets (glass x 24-33, 60-69, 95-104, 129-137), not at the
   `windowGlow` offsets SPRITES.md names (dx 18, 54, 89, 125, dy 28): those place a 6x8 glow half on each lancet's
   frame. The front's masks are in the anchor table; the interior's stained glass needs none.
3. **The fronts changed in albedo:** `chapel.png` (the gable's night shade lifted, a door) and `kitchen.png` (the
   ground floor's corner lifted). Their silhouettes and window glass are unchanged; the M1b shots of the chapel and the
   kitchen will look lighter on their right sides.
4. **Tamsin's stops** swap sides (the hearth is under the chimney on the right): table 2158, hearth 2208, both facing
   right. Hesper's 2052 and 2010 fit (2058 and 2012 are the exact spots).
5. **The speech mark** is a 14x7 strip of 2 frames. Lit by the night ambient it goes dark; drawn at full brightness
   (as UI) it stays readable at night.
6. **Dependencies:** `hallFront` copies the interior's end walls; `kitchenInterior` copies the front's stack; the
   statue and the saint use `king.png`. `build-art.sh` builds them in that order.
7. **World changes** of DESIGN.md's registry marked "M3 step 3" are not in SPRITES.md's M3 list and not painted: the
   votive candles (`castle.chapel.candles`: room before the altar step at chapel dx 104-118), the missing bell
   (`castle.chapel.bell.missing`: the bell is in `chapelInterior` at dx 24-32, rows 17-26, and the front's belfry
   openings at x 19-26 and 32-36, rows 18-27; two small overlays would take it out), the renewed banners and the
   tapestry (`hallInterior`), Seren's lantern, the guards on the wall walk and the dark keep window.

## Lessons (step 3)

- Painting an interior inside its front's opaque pixels gives the pixel-for-pixel silhouette for free; a converted
  painting would need its outline rebuilt by hand.
- A two-centred pointed arch: each arc is centred on the springing line and passes through its own springing point
  (radius 0.5 w, a semicircle, to w, equilateral); centring the arcs on the opposite points made spikes.
- A monochrome relief of a 16x30 figure in a 15 px niche reads as a ghost; painted (as medieval reliefs were) on a
  dark starry field it reads at once.
- Recolouring a sprite by lightness merges parts of the same value (cloak and tunic); a colour-for-colour map keeps
  them apart.
- A glyph in the border's colour joins the border: the speech mark's ink "!" read as an "H"; a red "!" on parchment
  reads.
- Firewood reads as logs only with bark rings and dark gaps between rounds of different sizes; even bright faces in
  a grid read as coins.
- Notes with dark text in two blocks read as a face; light text lines at odd heights read as notes.
- Window panes seen from inside read best as daylight albedo (daySky with a foam glint): bright by day, moonlit at
  night under the ambient; dark panes looked like night at noon.
- A big room needs warm light in more than one place at night: candle sconces on the chapel's shafts keep the nave
  from going black while the altar glows.

## Open points (step 3)

- The cat is part of `kitchenInterior` (static); a cat that wakes, stretches or follows Tamsin would need its own
  sprite.
- No sit frames: petitioners stand before the benches (step 1, deviation 2).
- The interiors' windows do not glow; a faint dusk glow from inside would need an emissive strip (coloured stained
  glass cannot glow through a mask).
- The kitchen front's far roof hip and the stack's shaded half keep the painting's shade.
- The step 3 world changes (note 7).

## Rebuild check (step 3)

One `build-art.sh` call in a scratch copy of the committed tree (`git archive` of 69b4dc2, the lane's head with every
step 3 sprite) with `Resources/Art` emptied and the Recraft raws copied from `build/recraft/lh/` rebuilt all **166
PNGs byte for byte** (the 158 of steps 1 and 2 and the earlier lanes, the touched-up `chapel` and `kitchen` among
them, and the 8 new ids); no file missing, no extra file, in 6 min 57 s without a heat wait (the CPU stayed under
55 °C). The only warnings are the old ones of `ashGiant` and `lightlessKing`. The anchor fixes after it (four candle
lights and the sanctuary lamp's mask, see the table) change no pixel.

# Fix stage (09.11.2026, after the M3 art review)

Both confirmed high findings are fixed, and so are eight of the nine medium findings. The ninth, the story portraits'
rosy skin, needs a palette change, which is the lead's decision; its proposal and a preview are under "Notes". No
Recraft image was made. The tables above (steps 1 to 3) now describe the fixed state, marked "fix stage".

## Credits (fix stage)

Recraft: **251 before, 251 after: 0 spent** (`bash tools/recraft.sh me` during this stage and again at its end), so
the lane has still spent 35 of its 300. After step 3 the balance stood at 356. The 105 credits spent since then came
from another worktree: game2-planning-354541's `build/recraft/log.jsonl` has a generation at 19:10. This lane spent
none of them: this worktree's log shows no call since step 2's sheet at 15:16. There were no prompts.

## The findings and their fixes

| finding | fix |
|---|---|
| [high] `hesper`, `hesperGlow`, `portraitHesper`: an all-cream hooded robe with a 3x4 px face smudge, a faceless cream ghost; the flame on a pole above the head; talk 6 could not lift the staff; with the white hood and the raised flame, an image to avoid in the night hall | `grids/court/hesper.txt` redrawn. A broad gold-ochre mantle (straw, strawLight, a gold front edge, woodLight shade) lies over both shoulders and falls down the back to the hem. Its rounded hood is pushed back, with its inside dark beside the face. The face is 4-5 px wide: a rockLight cheek on soilLight, one eye and the nose, with white hair at the crown and the temple. She is a little stooped. The cream robe shows only in front, with a gold hem. The flame burns in the iron cup of a short crook staff held at the chest, before her chin at (+5.5, 19) (18 in the bob frames). In talk 6 she lifts the staff 2 px off the ground, the flame flares up tall to (+5.5, 22) and her head draws back a pixel. `hesperGlow` follows: 7 glow pixels, 10 in talk 6. The portrait (a frozen grid) gets the same mantle, one value step deeper so it reads as cloth and not as blond hair, and a smaller hood pushed back. The hood has a gold trim, its inside is shown in shadow along the opening, and three folds gather behind the neck. White hair shows at the forehead, and the cream robe sits in a V |
| [high] `portraitBeard` frames 2 and 3: a straight hair1 top across the cheek and over the whole mouth, a bandana or a balaclava on dark hair | `portraitkit.py` `beard_fn`. The top now runs diagonally on the screen, from the sideburn (x 15, y 22) down along the jaw to the mouth corner (x 27, y 28). It is ragged, and the cheek above it stays skin. The full beard sits a pixel higher. The mouth is left open for the hand-set `BEARD_MOUTH`: a moustache over the upper lip (rows 26-27, lit on the left, its ends drooping), the lower lip lit in skin3/skin4 below it, the skin under the lip, and the chin beard from row 30. Where the beard lies over a face it gets no outline; `beard_edge` gives it a broken hair2/hair3 edge instead, dropping one edge pixel in four. Hair4 strands run on its lit side. The long beard (frame 4) shares the code and gets the same top and mouth. Checked with black and dark-brown hair on deep, brown, medium and light skin (`archetypes-x3`, scratch sheets) |
| [medium] `portraitOdile`: a pig's snout of a nose on the round face, a kindly grandmother, the rose facing missing | Built on the long face, with the jaw narrowed and the cheek hollow. The nose is now a hand-set thin wedge: 2 px tall at the tip, 3-4 px beyond the cheek, hooked a little down, with one shadow row under the tip, no highlight and no nostril. The near eye is half-lidded under a level brow and the far brow is arched. The mouth is thin with one corner up. A rose facing (dusk over tile) shows in the robe's front opening under the chain and seal, and the standing collar is lined in rose |
| [medium] the story portraits' rosy skin (dawnRose to tileLight with no mid tone) | Not changed: this needs new palette colours, which is the lead's decision. See "Notes", 1. Odile's crow's-feet dots, which read as speckles, are gone |
| [medium] the story portraits' lumps | The 13 story portraits (14 frames) are frozen as text grids (`portraitart.py freeze`) and hand-finished there. **Brannock**: a narrower, longer head (his own cranium and the long face), a hooked nose breaking the profile, a clear pale scar with a dark edge, and the dome's highlight cut down. His pauldrons are three plates a side with lit top edges and dark seams (the far side in shade), with mail below; the ring-mail speckle is gone. **Bram**: a broad flat skull, a thick neck, small eyes, one soot wipe across the brow and one smudge on the cheek, each grey at the core with the skin's shade at the edge. **Pip**: a pleated ruff right round the neck under the chin (17 px by 4 rows, parchment and plasterDim pleats by column, a scalloped hem), with his motley closed below it instead of the long bare neck. His cap's dome is now dusk over tile; its dawnRose matched his face (not in the findings, fixed on the way). **Hesper**: above. **Seren**: three folds in the hood, and two creases in the fold of the revealed frame. **Tamsin** and **the bard**: below |
| [medium] `portraitFace`: near-clone variants with one heavy eye stamp; women read as men | Round: the jaw 2 px wider, a short chin, a button nose lit only at its lower bridge. Long: the chin 3 px longer and a longer, narrower nose. Square: the jaw corners wider over a flat chin. Young: a smaller nose, a larger eye with a catchlight, a smooth narrow jaw. Every adult face except the old one is softened: the nose is a pixel less prominent with a shorter shadow under the tip, a 1 px lash flicks up from the near eye's outer corner, and the mouth is softer with a lit lower lip. Old and child are unchanged. `portraitHair` is re-clipped against the new faces' union |
| [medium] `portraitHat` frame 3: a flat band with a feather at the forehead | A soft cap whose crown covers the top of the skull, 4-5 px tall, drooping to the back, with a turned-up brim at the front. The plume rises from the side band at the back and sweeps back. It is clipped against the faces as before. Checked over bald, short, curly and long hair and with beards |
| [medium] `bard`, `portraitBard`: cap and hair one brown mass, sprite and portrait hair apart, a sausage beret, ball sleeves, the lute's neck before his nose | One hair colour in both, ginger-gold: straw and woodLight in the sprite, wood, woodLight and straw in the portrait. The cap is rose-red (dusk over tile) in both. In the portrait, a soft beret droops over the back of his head, its crown puffed over a darker band with the feather set into the band. The puffs are slashed, with the doublet's green in the slashes and a fold beside each. A standing collar sits on a closed doublet with buttons. In the sprite, the lute's neck angles forward at chest height (rows 11-13) with the fretting hand on it |
| [medium] `tamsin`, `portraitTamsin`: teal hair; the ladle's bowl beside the face in talk 6 | Auburn hair shows at the forehead, the temple and the nape below the kerchief. The knot sits behind the head with two short tails sticking out, and a fold runs across the kerchief. In the portrait the knot and tails stand well behind the head, with curls at the forehead, the temple and the nape and two folds in the kerchief. In talk 6 the ladle stays low and she wags a finger of her free hand before her chest |
| [medium] `petitionerE`: a 1940s detective in a fedora and a trench coat | A brimless soft cap of red velvet (dusk over tile) drooping over the back of his head, with the gold brooch and no band. A teal gown with wide sleeves and pale fur at the collar, the cuffs and the hem. A gold chain over the shoulders, the belt low at the hip, no button row |
| [medium] `chapelInterior`: the Flame burned on the saint relief's robe (a burning figure), and the relief vanished behind the glow | The relief is now a half-figure (hood, face, beard, the lantern raised) ending at row 63, above a carved plinth: rows 64-72, with a scroll of little flames (stamp `plinthCarving`) and its plain base down to the altar. The Flame burns in front of the plinth at his feet. The anchor is unchanged (dx 112, dy 23) |

## Pipeline (fix stage)

| File | What changed |
|---|---|
| `tools/portraitart.py` | `freeze <id> <out.txt> [--from PNG]` writes a story portrait as an actorart.py spec, using the fixed legend `FREEZE_LETTERS` (one letter per palette colour) |
| `tools/grids/court/portraits/<id>.txt` | the 13 frozen, hand-finished story portraits; Marek, Ser Ludo, the envoy, the herald and the king are frozen unchanged (byte for byte as before) |
| `tools/build-art-court.sh` | story portraits from their grids (actorart.py), composed parts with portraitart.py |
| `tools/portraitstory.py` | draft renders of the new Odile, Hesper, Brannock, Bram, Tamsin and bard forms (the hand-set nose and scar stamps included); the hand finish itself lives in the grids |
| `tools/portraitkit.py` | the face kinds, `EYES` (lash, the young eye), `MOUTHS` (`soft`), the nose's lit bridge (`nose_line(start=)`), `beard_fn`, `BEARD_MOUTH`, `beard_edge`, the feathered cap |
| `tools/grids/court/{hesper,bard,tamsin,petitionerE}.txt` | the four sprites |
| `tools/roomscenes.py`, `grids/court/rooms/chapel.txt` | the half-figure relief and its plinth |
| `tools/scenemock/scene_court.py` | `hesper_flame` lights the mocks at the new flame (dy 19, 18 in the bob frames, 22 in talk 6) |

## Context scenes and sheets (fix stage, git-ignored)

Every court and castle scene was re-rendered (`run_court.sh`, `run_castle.sh`: `build/recraft/lh/preview/court-*.png`,
`castle-*.png` and their `-x6` crops). The portrait sheets were re-rendered in `build/recraft/lh/preview/court/portraits/`
(`story-x3`, `story-x6`, `composed-30-x3`, `parts-x3`, `archetypes-x3`, `card-x3`). New sheets there are
`fix-story-before-after-x3.png` (the eight changed story portraits, before above, after below),
`fix-archetypes-before-x3.png` (the old archetypes, to set beside `archetypes-x3`) and `skin-ramp-proposal-x4.png`. The
sprite sheets `sheet-hesper`, `sheet-bard`, `sheet-tamsin` and `sheet-petitionerE` are in
`build/recraft/lh/preview/court/sheets/`, with the old ones in `sheets/before-fix/`.

## Rebuild check (fix stage)

One `build-art.sh` call rebuilt all **166 PNGs byte for byte**. It ran in a scratch copy of the committed tree
(`git archive` of b2e19b8, the head with every fix except the last Hesper portrait tweak), with `Resources/Art` emptied
and the Recraft raws copied from `build/recraft/lh/`. No file was missing and none extra, in 4 min 44 s without a heat
wait. It is faster than before because the story portraits no longer render. The only warnings are the old ones of
`ashGiant` and `lightlessKing`. After the check, only `portraitHesper`'s grid changed (the mantle one value step deeper).
It is built from its grid by actorart.py, and two builds wrote the same bytes.

## Notes for the lead and the code lane (fix stage)

1. **The skin ramp (lead).** Proposal: four albedo colours, not tagged `swap`, for example `fleshDeep #7A4632`,
   `flesh #B2704E`, `fleshLight #DE9E78` and `fleshPale #F8CCA8` (SPRITES.md's light target), each with a letter in
   `FREEZE_LETTERS`.
   - The switch: in the seven rosy story grids (Odile, Brannock, Pip, Tamsin, Bram, the bard, the king), map tile,
     tileLight and dawnRose to fleshDeep, flesh and fleshLight on the skin pixels only. The draft render's skin and
     neck materials mark which pixels are skin; the preview script did exactly this.
   - The same colours appear in their cloth, caps and motley, so a legend swap would recolour those too.
   - dawnRose stays for the 1 px sprite faces.
   - The preview `build/recraft/lh/preview/court/portraits/skin-ramp-proposal-x4.png` shows each face before and after.
     The faces lose the speckled sunburn and match the composed petitioners. They also all turn a warm tan, so Tamsin
     and Pip would keep their rosiness only in their cheeks.
2. **Hesper's flame anchor moved:** (+5.5, 19) in frames 0, 2, 4 and 7, (+5.5, 18) in 1, 3 and 5, (+5.5, 22) in talk 6;
   mirror dx when she faces left. If she gets a light, a candle-sized one there lights her face. Her body stands about
   1.5 px left of the frame centre with the staff on the right, as before.
3. **The chapel's Flame anchor is unchanged** (dx 112, dy 23, its light at (116, 26)); only the relief behind it
   changed.
4. **The composed parts changed in pixels, not in contract.** `portraitFace`, `portraitBeard`, `portraitHair` and
   `portraitHat` keep their frames and order. Beard frames 2-4 now carry skin colours (skin2 to skin4: the lower lip and
   the skin under it). `PortraitComposer.compose` swaps every layer with every ramp, so the lip takes the petitioner's
   skin. On the round face the short beard hangs a little below the chin, because the beards cover the union of the
   jaws, which now includes the long face's longer chin.
5. **The story portraits are frozen.** A later change goes into the grids, or into a fresh draft
   (`portraitart.py build <id> --out DIR`, then `freeze`) that must be hand-finished again.
6. **Deviations from the review's numbers.**
   - Hesper's flame burns at (+5.5, 19), not (+5, 22). In 14 px a flame at row 7 touches her nose, and the lane's
     lesson holds: a prop at face height becomes part of the face. Before the mouth it read as a pipe; before the chin it
     reads as a lamp. It reaches (+5.5, 22) in talk 6, with the head drawn back.
   - Her crook is a short staff that carries the cup at its top, not a hook. A hooked pole carrying a light is the king's
     signature (DESIGN.md "Not a copy": our own signatures), and a 1 px hook beside the cup read as a smudge.
   - The long beard got the beard fix too. Pip's cap dome changed as well.

## Lessons (fix stage)

- A hood in the colour of blond hair reads as long golden hair at 48 px. One value step deeper, with a bright trim and
  its inside dark at the opening, it reads as cloth.
- Long parallel fold lines on a hood read as strands of hair; short gathered creases at the nape read as cloth. Dotted
  highlights along a crease read as stitches.
- Pleats that alternate by row make a checkerboard; pleats run in columns.
- A beard over the mouth needs its own mouth. The faces' mouths differ by a row, so the beard layer carries the
  moustache and the lit lip, in skin swap colours that the composer maps.
- In a 14 px sprite a flame before the face needs a column of outline between it and the nose. At the mouth it reads as
  a pipe, at the chin as a lamp that lights the face.
- A white pointed hood with a raised flame is an image to avoid at any size. Colour (a gold mantle), a hood that shows
  the face and a flame carried low take it apart.
- A cap reads as a cap only when its crown covers the skull. A band with a feather on the forehead reads as a headband.
- A frozen grid ends the float-maths caveat, and the lane's rebuild got faster.

## Open points (fix stage)

- The skin ramp: the lead's decision (note 1).
- The short beard below the round face's chin (note 4). Beards per face group would fit tighter but need more frames in
  the contract.
- Pip's ruff is a flat band. A rounder ruff with a ruffled outline would take a few more hand-set pixels.
- The bard's lute neck in the sprite is short (2-3 px) now that it no longer rises.
- Hesper's sprite mantle (straw, strawLight) is a step lighter than her portrait's, as the portrait is lit by the hearth
  with its far side in shade.
