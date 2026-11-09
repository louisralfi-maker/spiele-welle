# Lanternhold: actors and creatures (M2b art lane, 09.11.2026)

Every actor, creature and glow strip of `SPRITES.md` is real pixel art now: 15 sprites and 9 glow strips in
`Resources/Art/`, each exactly its contract size (one row of frames, frame width × frames by height), 8-bit RGBA,
binary alpha, colours from `tools/palette.txt` only (albedo in the bodies, the emissive entries only in the glow strips).
Everything faces right; the feet stand on the bottom row (fliers and floaters excepted, see the table).

The look (the lead's decisions, final): the creatures are smouldering ash, never black blobs: layered ash-grey crusts
over charcoal, 1 px ember seams, ember eyes, one silhouette and size each. The defenders wear the realm's teal over
brown leather (archers), mail with teal shields (guards) and brown smocks (builders). Every actor carries a 1 px dark
outline (ink for people, night0 for creatures), so it reads against the ochre rock by day and against the night.

## Credits

Recraft (`bash tools/recraft.sh`, `recraftv4_1`, 35 credits per image): **496 before, 391 after: 105 spent** on 3
generations (budget 200). Each step of the balance fell by exactly 35 per image of mine (496, 426 after two, 391 after
the third), so no other lane's spending is mixed in.

## Pipeline

`tools/actorart.py` (pure python, imports `pixelart.py`'s PNG and palette code; one sprite per run, the biggest, the
110x110 giant, builds in 0.2 s; the CPU stayed between 29 and 45 °C all session):

| Command | What it does |
|---|---|
| `build <spec.txt> [--out DIR]` | writes `<id>.png` and, when anything glows, `<id>Glow.png` from a spec (below); warns about clipped pixels and frames with nothing on the bottom row |
| `sheet <id> <out.png> [--scale 6]` | every frame at device scale on four strips: day on the ochre throat rock, day on castle stone, night outside every light (body at 0.12 plus the glow strip, as the engine draws an unlit creature), night in firelight |
| `dump <in.png> <out.txt>` | a palette PNG as a text grid with a generated legend |
| `texture <in> <out> --colour --to --light [--cell --seed --rect]` | breaks a flat colour area into a seeded Voronoi cobble (crevices keep the colour, cells take `--to`, their upper-left rims `--light`) |

Spec format (`tools/grids/actors/<id>.txt`): `id`, `size WxH`, `frames N`, optional `outline COLOUR` (transparent
pixels 4-adjacent to the body take it), `image NAME PATH` (a converted key pose), `glowmap COLOUR=GLOW`, a `legend`
(`X = body`, `X = body/glow`, `X = /glow`; a body name ending in `!` is drawn without an outline: bow strings, arrows,
the Lightless King's blade), `part NAME` with its rows, and `frame N` blocks of placements (`PART x y [flip]`, drawn in
order; `frame N = M` copies). A body pixel also sets or clears the glow under it, so a part in front hides what it
covers; a glow-only entry adds glow and leaves the body (sparks above a sootling, the giant's crown embers).

Cut-out animation (the four big creatures): `part NAME image=KEY poly=x,y;x,y;…` cuts the key pose's pixels inside a
polygon into a full-size layer whose placement is an offset. The poly parts of one key are resolved together in
declaration order: a key pixel belongs to the frontmost part whose polygon holds it, and a part behind is underpainted
where a part in front covers it (nearest colour, spreading from its own pixels), so a limb moved 1 to 3 px uncovers
body, never a hole. `glowmap` lets a painted crack colour glow (`tile` pixels of the converted paintings).

`tools/build-art-actors.sh [name …]` rebuilds every actor sprite from the grids and the raws in
`build/recraft/lh/actors/` (git-ignored; copy them from this worktree for a rebuild), one at a time with a pause and the
heat rule (waits below 70 °C once the CPU reaches 80 °C). A full run (20 s) reproduces every committed actor PNG byte
for byte. Intermediate key poses go to `build/recraft/lh/actors/keys/`.

### Palette additions (emissive only)

Five colours appended to `tools/palette.txt`, all tagged `emissive`, so no conversion can pick them:
`emberDim #8C2A12` (faint ember seams), `violetGlow #B48CFF` and `violetDim #5E3A9E` (the gloomweaver's eyes and orb),
`tealGlow #9FF2E4` and `tealDim #3C8A86` (the Lightless King's eyes and cold rim). `build-art.sh` rebuilds all 62
committed scene sprites byte for byte with the new palette (checked in a copy of the tree, so no file in
`Resources/Art` was touched).

## Sprites

| id | size × frames | method | frame use | notes |
|---|---|---|---|---|
| `sootling` | 14x14 × 6 | hand-set parts | walk 0-3 (knuckle-walk, the lump bobs 1 px), attack 4-5 (near arm flung up in front of the head, then raked to the ground while lunging) | hunched lump: a jagged crust of pale ash flakes on the hump, charcoal plates below, diagonal ember seams, two pale ember eyes under the brow, long thin arms, stubby legs; one rising spark per frame (glow only) |
| `sootlingB` | 14x14 × 6 | hand-set parts | walk 0-3 (a stiff-legged strut, the head bobbing), attack 4-5 (head reared back, then butted forward on braced legs) | the lean second silhouette: a burnt-out matchstick, a round head of crusted ash with ember cracks and two eyes on a thin charcoal stick, thin pale limbs |
| `shadehound` | 22x14 × 6 | hand-set parts | run 0-3 (gallop: stretched, gathered with the back arched, stretched, gathered), attack 4-5 (crouch with jaws open; lunge flat out, a leap with the feet off the ground) | lean and low, a deep chest and tucked belly, a ragged pale smoke mane on neck and shoulders, an ember seam along the spine, one ember eye, far legs one value darker |
| `sootCrow` | 12x10 × 4 | hand-set parts | fly 0-2 (wing up, level, down), perch 3 | ragged wings of separate soot flakes with gaps, an ember-edged feather, one eye; flying frames do not touch the bottom row |
| `ashBrute` | 44x44 × 7 | Recraft `brute-b`, cut-out | walk 0-3 (diagonal knuckle-walk: front fist with the hind leg, back fist with the front leg, the hump bobbing), attack 4-6 (the rearing key with both fists high; slammed down, the body thrown forward, sparks at the impact; half way back) | a golem of fused ash plates; both keys converted at one common scale (15.8 sheet px per game px); ember eyes and hand-set joint cracks as glow parts |
| `gloomweaver` | 30x30 × 4 | hand-set after the Recraft key | float 0-3 (the body bobs 1 px up and settles, the ribbons ripple through three shapes, the orb's spark breathes) | a tall pointed hood curling forward over a void with two violet eyes, a sleeve reaching to thin pale hands, a dark orb rimmed in violet, the robe trailing into smoke ribbons; it floats (nothing on the bottom row) |
| `ashGiant` | 110x110 × 7 | Recraft `creatures-a`, cut-out | walk 0-3 (each leg lifted in turn, planted feet sliding back, the body up 1 px while a leg is lifted), stomp 4-6 (the stone arm raised 6 px; slammed, the body dipping 2 px: the screen shake; raised 2 px) | burnt stone and charred wood leaning on one huge stone arm, a crown of burning stakes; its shaded half lifted one value step and its flat dark bands cobbled into boulders (`texture`); every `tile` pixel glows `emberDim` (`glowmap`), two ember eyes under the crown |
| `lightlessKing` | 64x64 × 7 | Recraft `creatures-b`, cut-out plus hand-set | walk 0-3 (contact and passing on each leg, a 1 px bob, the cloak hem swinging), attack 4-6 (sword drawn back level behind him; swept flat forward at chest height; carried through low in front) | the converted cloak with its torn teal banner rags (night0 recoloured night1, its lit folds night2, so it is no black band); blackened plate (ink, stoneDark, stoneMid, stone edges), a closed helm with a hollow face, a 2 px cold rim and two cold eyes, an extinguished dark-gold crown with a broken point, a long dark blade (edge over body, outline-free) |
| `archer` | 12x28 × 5 | hand-set parts | idle 0-1 (a breath: head, shoulders and bow 1 px down), draw 2-3 (bow raised, arrow nocked at the chest; full draw to the cheek, the bow bent, the string in a V), loose 4 (string straight, drawing hand flung back) | brown leather hood, the teal tabard with the gold lantern, belt, red-fletched quiver, longbow |
| `guardsman` | 14x28 × 9 | hand-set parts | idle 0-1, walk 2-5 (march, the shield bobbing), strike 6-8 (spear drawn back level; thrust over the shield on a lunge; pulled back) | nasal helm, mail (soft two-tone rings), teal kite shield with a gold rim and the gold lantern, spear |
| `builder` | 12x24 × 6 | hand-set parts | walk 0-3, hammer 4-5 (mallet high behind the head; struck down in front) | straw cloth cap, brown smock over a linen shirt, tool belt, the mallet in his hand by the knee while walking |
| `king` | 16x30 × 10 | hand-set parts | walk 0-5 (contact, down, passing on each leg; the lantern swings 1 px on frames 1 and 4), idle 6-7 (a breath, the lantern sways), command 8-9 (the pole lifted 2 and 3 px, lantern raised) | gold crown a size too big with a teal stone, white beard, the teal cloak with a gold clasp over a red-brown tunic, the lamplighter's lantern on its hooked pole (DESIGN.md "Not a copy"; the pole is held in his hand, the lantern hangs from the hook at head height) |
| `citizen` | 12x26 × 6 | hand-set parts | walk 0-3, idle 4-5 | townswoman: cream headscarf, red-brown dress, pale apron, a basket on her arm |
| `citizenB` | 12x26 × 6 | hand-set parts | walk 0-3, idle 4-5 | townsman: dark skin, dark curly hair and beard, green tunic, a sack on his back |
| `citizenC` | 12x26 × 6 | hand-set parts | walk 0-3, idle 4-5 | old farmer: wide straw hat, grey beard, blue smock under a brown vest, a crooked walking stick |

Glow strips: `sootlingGlow`, `sootlingBGlow`, `shadehoundGlow`, `sootCrowGlow`, `ashBruteGlow`, `gloomweaverGlow`,
`ashGiantGlow`, `lightlessKingGlow`, `kingGlow` (same size and frames as their sprite).

### Glow strip rules

- Eyes are the brightest (fireGold; the gloomweaver violetGlow, the Lightless King tealGlow); seams are fainter
  (emberDim, a few hot pixels in ember); sparks and crown embers fireOrange or ember. Alone, a glow strip still shows
  the creature: eye spacing, a seam line along the body, the hound's spine, the giant's burning crown.
- The body pixel under a glow pixel is a dark or warm albedo (seams `tile`, eyes `strawLight`, the King's hollow
  night0), so by day, if the engine dims the glow, the seam still reads red-brown and the eye pale gold.
- Sparks may lie outside the body (glow only): one per frame above the sootlings and hounds.
- The orb's glow is a violet rim (violetDim) around a dark core with one bright spark off-centre, so it reads as a
  sphere, not as an eye.
- `kingGlow` is the lantern glass (2x2: fireWhite above fireGold) and a fireWhite glint on the crown's teal stone. The
  engine should draw it with the lantern's torch strength (in the golden-hour mock at full strength the glass shows as
  a white dot by day).

### Eye and lantern positions (from the anchor: dx right, dy up from the bottom row; facing right)

| sprite | frame 0 | notes |
|---|---|---|
| sootling | eyes (2, 8) and (4, 8) | |
| sootlingB | eyes (1, 9) and (2, 8) | |
| shadehound | eye (8, 9) | one eye |
| sootCrow | eye (2, 4) | flying frame |
| ashBrute | eyes (8, 23) and (10, 23) | |
| gloomweaver | eyes (-1, 19) and (2, 19), orb spark (9, 14) | |
| ashGiant | eyes (-21, 91) and (-17, 91) | the head stands left of the frame centre |
| lightlessKing | eyes (4, 48) and (6, 48) | |
| king | lantern glass x 5-6: dy 22-23 (frames 0, 2, 3, 5, 6), 20-21 (1, 4, 7), 24-25 (8), 25-26 (9); crown glint (-1, 26 or 25) | the light should sit at about (+5.5, 22.5), not `x + 9, y 16` |

The glow strips make the old `eyeGlints` sprite unnecessary for these creatures.

## Key poses and prompts

Every prompt ends with "Crisp detailed 16-bit pixel art, side view, clean hard pixel edges, no anti-aliasing, limited
palette, rich pixel texture and form, evenly lit neutral daylight colours with gentle form shading, no cast shadows, no
glow, no fire, no smoke effects, no night, no fog, no sky, no ground, no text, no border." and the key colour.

1. `creatures-a` (2:1, magenta), used: ashGiant (right, box 864,16,1456,752 → 110x110 contain, `--gain 1.9`). "two
   separate monster characters side by side … both seen from the side in profile, walking to the right … Left: a
   hunched brute golem made of fused plates of grey ash and charcoal stone … Right: a towering humanoid colossus of
   burnt stone and charred wood … its torso a mass of cracked blackened boulders bound together by charred tree trunks
   and beams … a jagged crown of broken charred wooden stakes on its head, thin dark red cracks across its stones. …
   ash grey, charcoal, sooty brown-black and dark violet-grey … a few dark red seams …" Reject: the brute (painted
   front-on with a round head and two black eye holes, too mask-like and not side view).
2. `creatures-b` (2:1, green #00FF00; Recraft painted #1CE49C), used: lightlessKing (right, box 700,24,1262,746 →
   64x64 contain with 6 rows of headroom), gloomweaver (left, the reference for the hand-set grid). "Left: a floating
   hooded wraith woven of dark smoke ribbons, no legs … a tall pointed hood with only darkness inside it, a long robe that
   dissolves downward into many long tattered trailing ribbons of smoke, two thin bony hands … cradling a dark round
   orb … Right: a tall fallen knight king walking to the right, in blackened plate armour, a tattered ragged dark cloak
   … with torn teal-blue banner rags in it, a dull tarnished dark-gold crown on his closed helm, a hollow black face
   opening in the helm, a long straight dark sword held low …" At 30 px the weaver's ribbons fell apart into specks;
   the King's plates turned into one flat violet (so only his cloak and rags are used).
3. `brute-b` (2:1, magenta), all used: ashBrute walk key (left, box 144,176,752,704 → 38x33) and rearing key (right,
   box 892,8,1420,704 → 33x44), `--gain 0.95`. "the same monster shown twice side by side … strictly in side profile
   facing right … a hunched brute golem built of fused plates of grey ash and charcoal stone, wider than tall, a massive
   hunched back like a boulder, a small round head thrust forward and low … enormous long arms ending in huge blocky
   stone fists, short thick bent legs; thin dark red cracks along the seams … Left: walking to the right, the knuckles
   of its front fist resting on the floor ahead of it. Right: rearing up with both fists raised high above its head,
   ready to smash down." Asking for the same creature twice in two poses gave a matching anticipation key.

## Context scenes (`tools/scenemock/`)

`scene_actors.py` writes each scene's extras (`mock.py extras=`, the hook of this lane) and `run_actors.sh` renders them
to `build/recraft/lh/preview/actors-<scene>.png` (437x201 upscaled x3, about 3 s each), with the look values of
`run_m1b.sh` plus the renderer's cap on reflected firelight (`litCap=1.6 litNeutral=0.35`, new opt-in looks of
`mock.py`; without them a lit pale ash crust blew out to white). The king and the layout's scale-check actors are left
out (`king=off actors=off`) so every actor comes from the scene.

| scene | what it shows |
|---|---|
| `battle-night` (focus 700, tod 0.95) | sootlings, sootlingBs, shadehounds, a soot crow and the ash brute come from the left; three fire arrow pools light the brute and two creatures, the rest show only their glow; two archers draw and loose from the tower at 662, a guard thrusts behind the palisade, the king lifts his lantern |
| `battle-day` (tod 0.5) | the same, everything lit |
| `finale` (focus 930, tod 0.97) | the Lightless King's sword sweep left of the middle line's braziers, the beacon's far glow, a gloomweaver and sootlings in the dark behind him, archers and the king with his lantern raised on the stone wall, a guard |
| `giant` (focus 930, tod 0.95) | the ash giant's stomp at the stone wall, its upper body dark with burning crown and seams, archers on the wall and the tower at 978, a hound and a sootling in the dark |
| `town-golden` (focus 2900, tod 0.75) | the king walking among townsfolk, two builders hammering at a scaffold on plot 2832, a woman at the well |
| `town-night` (tod 0.95) | the same at night, lit by the king's lantern, the lantern post and the windows |

## Lessons

- At 14 px an auto outline makes a 1 px limb a 3 px stripe: limbs need a light core (stone, not charcoal) inside the
  outline, or they merge into one dark mass with the body.
- Eye pixels need a pale albedo under the glow (strawLight), or by day eyes and seams are the same red-brown dots.
- A detached prop in front of a face reads as a mask (the builder's mallet on his shoulder): carry it by the knee.
- The mock without the renderer's light cap blows pale lit sprites to white; judge lit actors with the cap.
- Asking Recraft for the same creature twice in two poses (walk, attack) gives a matching anticipation key; asking for
  two different creatures in one sheet gave one of them front-on.
- A Recraft painting's flat black areas stay flat after conversion; a seeded cobble texture gives them the form of the
  lit parts without hand painting 110x110 px.

## Open points

- The code lane must update `SpriteID.frameCount` (king 10, archer 5, citizen 6, sootling 6, shadehound 6) and add the
  new ids (sootlingB, sootCrow, ashBrute, gloomweaver, ashGiant, lightlessKing, guardsman, builder, citizenB,
  citizenC and the glow strips); until then the atlas crops the new strips around their bottom centre.
- The king's lantern light (`SceneActor.lantern`: x + 9, y 16) should move to the painted glass (+5.5, about 22.5);
  `kingGlow` should fade with the torch strength by day.
- No projectiles are painted in this lane (`arrow`, `fireArrow`, `bolt`, `firepot`); the scenes show fire arrows only as
  their flame and light pool.
- The sootling reads a little like a grey beetle in daylight at device scale; a jaggier crest or a lighter face could
  make it more creature-like. The matchstick sootlingB reads small next to it.
- The Lightless King's walk is a cut-out stride (legs hand-set, the converted cloak moved as two pieces); a later pass
  could give the cloak more ripple. His attack keeps the blade level (frame 64 high leaves no room for an overhead
  swing).
- The ash giant's attack is an arm slam; a true foot stomp would need a second key pose.
- The gloomweaver's darkness bubble (50 px) is the engine's; the sprite only carries its orb.
