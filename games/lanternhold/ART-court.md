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
| `tools/portraitstory.py` | the 13 story portraits, each one scene of the template's head with the character's own hair, hat, clothes and props in the court's colours (step 1's sprites), then depth edges (where a part lies in front of another, the pixel behind it takes a darker step: the contact line the composed parts draw with their outlines), the outline, the rim and the stamps |
| `tools/build-art-court.sh` | builds the 18 portrait ids after the 14 court sprites (one at a time, 4 s pause after each portrait, the heat wait at 80 °C); `build-art.sh` runs the lane whole |

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
| `portraitFace` | 0 round (full cheeks, a soft jaw), 1 long (a narrow face, a longer chin and nose, a hollow under the cheekbone), 2 square (a broad jaw and chin, heavy brows), 3 old and wrinkled (jowls, lidded eyes, brow lines, crow's feet, folds by the nose and mouth), 4 young (smooth, wide bright eyes, a smaller nose), 5 child (the shared cranium over a small round lower face: eyes, nose and mouth lower and smaller, a thin neck); brows are in the hair ramp, so they take the hair's colour |
| `portraitBeard` | 0 none, 1 stubble (a sparse random grain of the hair ramp, no outline), 2 short (on the jaw, the top line from the sideburn under the cheekbone, the lips free), 3 full (bushier, a little higher on the cheek), 4 long (full with a pointed fall onto the chest), 5 moustache (a walrus moustache under the nose); beards are built on the widest adult jaw so they cover every adult face |
| `portraitHair` | 0 bald, 1 short (a fringe of locks), 2 long (to the shoulders, a strand behind the far cheek), 3 bun (pulled back, the bun high at the back), 4 curly, 5 braids (two braids with ties in the cloth ramp, so they take the clothes' colour), 6 tousled, 7 child's mop (a bowl cut with a fringe to the brows) |
| `portraitHat` | 0 none, 1 straw hat (tipped forward so the brim's top shows, a band in the cloth ramp), 2 headscarf (knotted at the nape with tails), 3 cap with feather (a soft cap pulled to one side, a turned-up brim, a white plume sweeping back), 4 hood (to the shoulders, its inside dark around the face), 5 wool cap (a turned-up cuff, a top knot), 6 helm (steel with a ridge, a rim and a nasal on the nose), 7 flower wreath (leaves and rose, gold and white flowers) |

How they fit: every part is rendered on the same head frame, and everything that lies behind any face (a hood's
inside, the back of a brim, hair behind the neck) is clipped against the union of all six faces, so no part paints over
a face it might be drawn on; small islands the clip leaves are dropped. The garments' neck openings meet the face's cut
neck at y 36; their collars lie below it, in front of where the neck would go on.

The child has the shared cranium with a smaller, lower face, so the shared hair (braids), the wool cap and the wreath
fit it too (they look a little big on a child, which reads as a child); the child's mop is made for it.

### The story portraits

| id | who, as the portrait shows them (colours from step 1's sprites) |
|---|---|
| `portraitOdile` | the long face with a long beak of a nose breaking the profile, a dry lidded look with the far brow arched, a thin wry mouth, crow's feet; grey hair pulled up into a high bun with a pin; the aubergine robe (night2, rockDeep, stoneMid) with a standing collar over a rose facing, the silver chain of office with its gold seal |
| `portraitBrannock` | the square face, bald with a grey fringe round the back, heavy frowning brows, a pale scar through the near eye from brow to cheek, a short square iron-grey beard; steel pauldrons and ring mail, the teal surcoat with the gold lantern |
| `portraitPip` | the young face with a wide grin (teeth), a rosy cheek, wide eyes and raised brows; the two-horned cap (the back horn teal, the front rose-red) with a gold band and a gold bell on each drooping tip; the parchment ruff; the motley split teal and rose-red |
| `portraitHesper` | the old face with dark skin (woodDark, soil, soilLight, rockLight), white brows and eyes closed in a gentle smile; the deep cream hood with a gold rim round the face, the cream cape with the gold stole and the gold flame of her order |
| `portraitTamsin` | the round face with rosy cheeks and a broad smile; the teal kerchief knotted at the back with two tails, an auburn curl peeking out; the red-brown dress with the white apron's bib |
| `portraitBram` | the square face, bald, a short black beard, soot on the brow and cheek, flat heavy brows (few words); broad shoulders in a dark shirt under the leather apron's straps and bib; the hammer's handle over his near shoulder, its iron head behind his neck |
| `portraitMarek` | the long face with medium brown skin, a curled black moustache, one brow up and a sly squint; the wide floppy dark hat with a gold band and a long rose feather sweeping back; the green coat with gold trim, the satchel's leather strap with its gold buckle |
| `portraitSeren` | frame 0: the deep blue-grey hood (night1, farDeep, far) with the face in its shadow, only a pale chin and two faint glints, the pale clasp at her throat; frame 1: the hood thrown back into a thick fold, a pale haunted face (shadows under and over the eyes, a thin mouth) and long ash-silver hair, the same cloak |
| `portraitSerLudo` | the bucket helm far too big for him, dented at the top, its visor lifted so two earnest eyes peer out of the dark slot, a light band over it, breathing holes and rivets; the wilted rose plume drooping down its back; the yellow surcoat with a red chevron over baggy mail |
| `portraitBard` | the young face with ginger-gold curls, singing with a wink; the floppy red cap (a beret hanging to one side) with a long white feather; the spring-green doublet with cream puffed sleeves and the gold sash |
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
   the stone ramp for the herald and for Seren's pale face). The step from dawnRose (L 75) to tileLight (L 52) is wide
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
| `chapelInterior` | 160x96 | the chapel of the Flame inside, in `chapel`'s silhouette: a starry vault in the realm's teal with gold stars over timber ribs and a carved wall plate, a king-post truss in the chancel's gable; the belfry with its bronze bell, louvres and the spire's rafters, the bell rope with its striped grip down into the nave; cream lime-plaster walls under a red frieze of gold flames, an oak wainscot; two stone shafts with candle sconces; the four lancets at the front's lancets in stained glass (border quarries in teal and gold, a flame, a lantern, a star, a flame); the lamplighter saint as a painted relief in a starry niche (the old lamplighter in the cream and gold robe of the Flame's order, hooded, white-bearded, his lantern raised on its hooked pole, gilded rays); the altar on the chancel step with its cream and gold frontal and the Flame's emblem, the Flame's gold-rimmed stone bowl, two gold candlesticks, two iron candle stands, a vase of lilies and roses; a sanctuary lamp with red glass on its chain; five pews facing the altar; flagstones and a red runner up the nave |
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
| `chapelInterior` | the Flame | `brazierFlame` at (dx 112, dy 23), its bottom row on the gold rim of the stone bowl on the altar; its light (brazier, 54) at (cx 116, y 26) |
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
