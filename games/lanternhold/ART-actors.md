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

Look 2, stage 3 (09.11.2026): the eight creatures no longer come from this pipeline. They are painted by
`tools/rig.py` and `tools/creatures/<id>.py` through `tools/creatureart.py` (ART-look2.md, section 10); no Recraft
image was used for them (credits 251 before and after). What follows describes the people (archer, guardsman,
builder, king, citizens) and look 1's creatures, whose key poses, prompts and grids stay in the repo as history.

`tools/actorart.py` (pure python, imports `pixelart.py`'s PNG and palette code; one sprite per run, the biggest, the
110x110 giant, builds in 0.2 s; the CPU stayed between 29 and 45 °C all session):

| Command | What it does |
|---|---|
| `build <spec.txt> [--out DIR]` | writes `<id>.png` and, when anything glows, `<id>Glow.png` from a spec (below); warns about clipped pixels and frames with nothing on the bottom row |
| `sheet <id> <out.png> [--scale 6]` | every frame at device scale on four strips: day on the ochre throat rock, day on castle stone, night outside every light (body at 0.12 plus the glow strip, as the engine draws an unlit creature), night in firelight |
| `dump <in.png> <out.txt>` | a palette PNG as a text grid with a generated legend |
| `texture <in> <out> --colour --to --light [--cell --seed --rect]` | breaks a flat colour area into a seeded Voronoi cobble (crevices keep the colour, cells take `--to`, their upper-left rims `--light`) |
| `cracks <in> <out> --seed C --along C1,C2 [--min --max --seed-value --path x0,y0:x1,y1 …]` | fix stage: each `--path` draws a long fissure in the crack colour, the cheapest 8-connected way between its two points through the body (cheap along the crevice colours, dear across lit stone, so it follows the boulders' joints); then every speck of the crack colour smaller than `--min` grows along the crevices into a stroke of `--min` to `--max` pixels (seeded, never touching another crack) |

Spec format (`tools/grids/actors/<id>.txt`): `id`, `size WxH`, `frames N`, optional `outline COLOUR` (transparent
pixels 4-adjacent to the body take it), optional `rim GLOW [TIP]` (fix stage, with an outline: the outline pixel above
each column's topmost body pixel glows GLOW in every frame, TIP over 1 px wide spikes; legs and arms under the body
stay dark), `image NAME PATH` (a converted key pose), `glowmap COLOUR=GLOW`, a `legend`
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
| `sootling` | 14x14 × 6 | look 2 painter `tools/creatures/sootling.py` (hand-set frames) | crawl 0-3 (on hands and knees, the reaching hand planted and moving back 3 px a frame, then the other arm reaches), attack 4-5 (rears up with the claw high above the head; strikes down in front) | a lost child: a husk on all fours, the pale head too big and hanging forward, two hollow eyes weeping cold light, a rag of a shirt on its back, a dark jaw |
| `sootlingB` | 14x14 × 6 | look 2 painter `tools/creatures/sootlingB.py` (hand-set frames) | walk 0-3 (stooped, on stick legs, the head bobbing 1 px, the long arm dragged behind the step), attack 4-5 (the long arm swung up behind the head; whipped forward at chest height) | the second child: upright and thin as a stick, a rag of a smock, one arm grown far too long and dragged along the ground |
| `shadehound` | 22x14 × 6 | look 2 painter `tools/creatures/shadehound.py` (hand-set frames) | run 0-3 (gathered, push off, stretched in the air with nothing on the bottom row, landing on the hands; 6 px a frame), attack 4-5 (crouched back, the jaw wide; the lunge flat out) | a man on all fours: arms as long as the legs, elbows and knees too high, the spine arched, a shirt rag on the ribs, the pale head hanging low on a long neck, the jaw unhinged |
| `sootCrow` | 12x10 × 4 | look 2 painter `tools/creatures/sootCrow.py` (hand-set frames) | fly 0-2 (wings up, level, down), perch 3 (hunched, the wings a hood) | a crow of torn cloak scraps: a rag tail, a pale skull face with one hollow eye and a grey beak; flying frames do not touch the bottom row |
| `ashBrute` | 44x44 × 7 | look 2 painter `tools/creatures/ashBrute.py` (rig) | walk 0-3 (near foot planted at x 23, 19, 15 then swung, far foot two frames later, the fist planted and lifted like a third leg, the body down 1 px on the contacts), attack 4-6 (the fist reared back over the hump, leaning back; slammed down in front, the body thrown 3 px forward and 2 px down; held) | a swollen night watchman: a hump under a patched cloak with hanging rag strands, the torn cloak behind, a bare smoke belly with two ember cracks, a small skull head sunk between the shoulders, one arm as thick as a trunk ending in a fist, the other withered, his pole across the hump with a dead lantern cage dangling over the head (one emberDim spark) |
| `gloomweaver` | 30x30 × 4 | look 2 painter `tools/creatures/gloomweaver.py` (rig) | float 0-3 (the robe's five strips wave, the lantern swings 1 px, its violet drips fall a pixel a frame) | a robed figure bent forward, no feet, the robe ending in torn strips; a limp hood over a face of darkness with two weeping eyes; two thin arms hold out a dead lantern that leaks violet light downward |
| `ashGiant` | 110x110 × 7 | look 2 painter `tools/creatures/ashGiant.py` (rig) | walk 0-3 (near foot planted at x 60, 56, 52 then lifted 4 px and swung, far foot two frames later; the hands swing, the cloak hem follows, the heart flickers), stomp 4-6 (the near knee drawn up to the belly, leaning back 5 px, the heart dims; the foot slammed down 12 px ahead, the body 5 px down and forward, the heart flares to fireGold: the screen shake; held) | a starved giant bent double: a hump under a sail of a cloak torn into hanging strips, stilt legs, arms that reach the ground with open hands, a hooded skull hanging lower than the shoulders with weeping sockets and an open jaw, and in the bare chest a cage of pale ribs (two broken) around an ember heart |
| `lightlessKing` | 64x64 × 7 | look 2 painter `tools/creatures/lightlessKing.py` (rig) | walk 0-3 (he glides: the foot tips under the hem planted and moving back 5 px a frame, the pole's foot planted, then lifted and set ahead, the train swaying), attack 4-6 (the snuffer lifted level over the crown, leaning back; brought down in front, the bell on the ground, leaning forward; held) | the full frame height: a tall mantled shape with a torn train and shoulder cape, a cowl whose face is a void ringed by a cold crescent, a crown of uneven iron thorns, two dead lanterns on chains at the belt, a long-fingered hand, and a pole taller than himself that ends in a crook with a candle snuffer bell. No circlet, no sword, no teal |
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

The creatures' strips follow look 2 (ART-look2.md "Stage 3: the creatures"); the rules of the fix stage (ember rim
with fireOrange spikes, fireGold eyes, the King in teal) no longer apply.

- A glow strip alone still shows the creature: its top contour, its eyes, its one sign.
- The common folk of the Gloom (sootlings, hound, crow, brute, giant): an `emberDim` line on the top contour (on the
  outline pixel above every body pixel that has two or three free pixels over it), `ember` only inside cracks, and
  cold weeping eyes: one `wraithWhite` pixel each with a `wraithGlow` or `wraithDim` pixel below it (the tear). No
  fireOrange spikes, no fireGold eyes: a creature never looks like a fire.
- The giant's ember heart is the one warm sign of size: `emberDim` dithered around `ember`, a core that flickers
  (`ember`, `fireOrange`, `fireGold` on the stomp).
- The gloomweaver: a `violetDim` top contour, weeping eyes, and the dead lantern leaking violet (`violetGlow` core,
  `violetDim` cage and drips).
- The Lightless King is cold only: a `wraithDim` top contour, `wraithGlow` on the crown's thorn tips and as a crescent
  around the cowl's void. No eyes, no ember, no teal.
- The body pixel under a glow pixel is a dark or neutral albedo (cracks `tile`, eyes `stoneLight`, tears `stoneMid`
  or `stoneDark`), so by day the eye is a pale grey pixel and the crack red-brown.
- No glow pixel and no body pixel lies loose outside the silhouette: the engine's moonlight rim lights every
  screen-right edge pixel of an unlit creature, so a loose smoke pixel becomes a bright speck. Torn edges are
  connected cloth.
- `kingGlow` is the lantern glass (2x2: fireWhite above fireGold) and a fireWhite glint on the crown's teal stone. The
  engine should draw it with the lantern's torch strength (in the golden-hour mock at full strength the glass shows as
  a white dot by day).

### Eye and lantern positions (from the anchor: dx right, dy up from the bottom row; facing right)

| sprite | frame 0 | notes |
|---|---|---|
| sootling | eyes (2, 5) and (4, 5) | crawling; attack frame 4: (0, 8) and (2, 8) |
| sootlingB | eyes (-3, 10) and (-1, 10) | walk frames 1 and 3 one pixel lower |
| shadehound | eyes (5, 7) and (7, 7) | two eyes now; in the air (frame 2) at (7, 8) and (9, 8) |
| sootCrow | eye (3, 5); perched (2, 4) | |
| ashBrute | eyes (10, 28) and (12, 28); dead lantern spark about (7, 36) | the lantern cage swings 1 px |
| gloomweaver | eyes (1, 22) and (3, 22); lantern core (9, 9) | the engine's bob moves all of it |
| ashGiant | eyes (28, 73) and (32, 73); heart centre (5, 68), radius 7 | the head hangs right of the frame centre now |
| lightlessKing | no eyes; cowl crescent (-6..-3, 50..54); crown tips up to (-2, 63) | the sprite fills the frame's 64 px |
| king | lantern glass x 5-6: dy 22-23 (frames 0, 2, 3, 5, 6), 20-21 (1, 4, 7), 24-25 (8), 25-26 (9); crown glint (-1, 26 or 25) | the light should sit at about (+5.5, 22.5), not `x + 9, y 16` |

The glow strips make the old `eyeGlints` sprite unnecessary for these creatures. Positions are of look 2 (stage 3).

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
| `finale` (focus 930, tod 0.97) | the Lightless King's sword sweep left of the middle line's braziers, unlit inside his own aura with the creatures near him (fix stage: before, he was drawn lit by the braziers, which the game never does), so he reads by his cold teal silhouette; the beacon's far glow, a gloomweaver and sootlings in the dark, archers and the king with his lantern raised on the stone wall, a guard. Lit in the beacon's reach: `bld-beacon-finale` (ART-buildings.md) |
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
- The sootling's dome still reads a little like a grey beetle in daylight at device scale (the jagged crest and the
  ember mouth helped); the matchstick sootlingB reads small next to it.
- The Lightless King's walk is a cut-out stride (legs hand-set, the converted cloak moved as two pieces); a later pass
  could give the cloak more ripple. His attack keeps the blade level (frame 64 high leaves no room for an overhead
  swing).
- The ash giant's attack is an arm slam; a true foot stomp would need a second key pose.
- The gloomweaver's darkness bubble (50 px) is the engine's; the sprite only carries its orb.

## Fix stage (09.11.2026, after the art review)

The review's blocker and its high finding on this lane, and one medium, all fixed; no Recraft images (credits **391
before, 391 after**). Sheets of every creature: `build/recraft/lh/preview/actors/sheet-<id>.png` (the four strips of
`actorart.py sheet`; "before" copies of the sootling, sootlingB and hound in `actors/before/`).

| Finding | Fix |
|---|---|
| unlit, the creatures read as black blobs with ember eye dots (7 to 16 glow pixels a frame; the giant's ~120 isolated specks) | `rim` on the outline's top contour (ember, fireOrange spikes) for every ember creature; connected crack networks: the sootling's Y of seams, the hound's spine line and two flank cracks, the brute's joined plate seams on both keys, the giant's six fissures and its specks grown into 3-4 px strokes (`cracks`); sootlingB and the crow get the rim. Glow pixels a frame now: sootling 25-26, sootlingB 17-19, hound 26-28, crow 9-13, brute 77-87 (52 on the rearing key), giant 403-416 |
| the Lightless King reads as a dark shape with two teal dots inside his aura (4 glow pixels a frame), and `actors-finale` showed him lit by the braziers | a cold silhouette (tealDim rim, tealGlow crown points, teal rags, the blade's light edge to a tealGlow point, the visor's edge, glints; 124-132 glow pixels a frame, was 4); the finale rendered twice: `actors-finale` unlit inside his aura, `bld-beacon-finale` lit in the beacon's reach; the gloomweaver's violetDim hood line |
| the hound's head ran out of the frame (the snout cut flat in column 21) | the torso 2 px shorter (two columns cut from the middle of each body pose), the fore legs 2 px left, the snout tapering to an ink nose at column 20 with its outline in column 21 in every frame; its glow strip rebuilt with the shift |

### Notes for the lead (engine and contract)

- SPRITES.md's unlit rule should change: the engine should draw an unlit creature's body opaque (never as a
  translucent ghost) and give it the moonlight rim DESIGN.md "Readable at night" asks for, the king's rim pass (cool
  rim on the screen-right edge pixels, outshone by firelight), so its lower half separates from the dark ground where
  no glow lies. The glow strips now carry the top contour and the cracks; the rim pass would carry the rest.
- The planning branch's actor shader draws an emissive actor (a glow strip) as its flat colour over the body
  (`mix(base, albedo, alpha)`), not additively as SPRITES.md says. The new strips are made for both: the rims lie on
  the outline (a dark pixel either way), the cracks on dark seam albedo. Additive drawing, as the contract says, would
  let a lit crust keep its colour under a crack pixel.
- The rims make an unlit creature visible from its top edge; the light pools still read, because a lit creature shows
  its whole grey crust and an unlit one only its edge and cracks.
- shadehound's eye moved to (6, 9) from the anchor (was (8, 9)).

### Lessons

- A dark creature reads in the dark by its silhouette's edge, not by its eyes: the outline's top contour is the cheapest
  pixel row that carries the whole shape, and it stays a dark line in firelight.
- emberDim alone is too dim under the ground fog in the mock; the rim needs ember, the cracks may stay emberDim.
- A long crack drawn along a converted painting's crevices (a cheapest path) looks painted; random specks never join.

## M2b review (09.11.2026)

No Recraft images. Rebuilt through `build-art-actors.sh`; every other actor PNG rebuilds byte for byte.

| Finding | Fix |
|---|---|
| lit by the beacon and the braziers the pale crusts blew out: cream sootling domes, a pink brute, a white hound | the crust one value step darker: the sootling's, sootlingB's and the hound's legend P/L/S now stoneLight/stone/stoneMid (were stonePale/stoneLight/stone); both brute key poses remapped the same way after their conversion (`post --remap stonePale:stoneLight,stoneLight:stone,stone:stoneMid`). In the engine creatures also reflect at most 1.2 of point light (the world 1.6) |
| the king's teal cloak read beige by his own lantern and sage by a fire | the cloak roofDeep, banner teal only on its lit folds (legend T, t roofDeep, U banner; a fold line down the body part) |
| the Ash Giant's crown stakes reached row 0 and blinked every other walk frame | the torso's cut polygon starts 2 rows down: the stakes are 2 px shorter, nothing is clipped any more |
| the giant and the king slide their planted feet | the engine's stride: the giant 4 px a walk frame (was 6), the king 4 (was 7); the giant's true fix (a second leg key pose with the planted foot moving back) is open |

The engine side: unlit creatures keep a 0.9 moonlight rim (`EntityFrames.unlitRim`), bodies a shade by id (0.85 to 1),
drawn left to right; the king's glow strip lights only from the dusk.
