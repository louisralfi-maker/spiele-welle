# Lanternhold: the cast's sprites (the people lane, 14.11.2026)

The sprite contract of the people lane's bodies (docs/PEOPLE.md says who they are). The rules at the top of SPRITES.md
hold for every one: `Resources/Art/<id>.png`, 8-bit RGBA with binary alpha, one texel one game pixel, palette colours
only, one row of frames left to right, the foot at the bottom centre (the feet on the frame's last body row with the
outline under them on the bottom row), facing right, albedo only, no glow strip. Every body is a hand-set part grid
read by `tools/actorart.py`: the repaints in `tools/grids/actors/`, the new ones in `tools/grids/people/`;
`tools/build-art-people.sh` rebuilds all of them byte for byte (run it through the director's art lock on this Mac).
`tools/peoplesheet.py` draws the proof sheets (the line-up on the town's ground, a walk strip, an 800 % zoom).

In code: the ids are `SpriteID` cases (one line at the end of the enum); `SpriteID.size` and `SpriteID.frameCount`
ask `PeopleCast.size(of:)` and `PeopleCast.frameCount(of:)`; `PeopleCast.Frames` names the ranges below;
`PlaceholderCast` draws stand-ins when a PNG is missing.

## The three townsfolk, repainted (contract unchanged)

| id | size | frames | frame use |
|---|---|---|---|
| `citizen`, `citizenB`, `citizenC` | 12x26 | 6 each | walk 0-3, idle 4-5 (Mother Corra, Dun Rook, Ned Furrow) |
| `citizenSeated`, `citizenBSeated`, `citizenCSeated` | 12x22 | 2 each | seated 0, a nod 1 (on the hall's benches, as SPRITES.md "The townsfolk seated") |

## The working people (the citizen contract, with work frames after it)

| id | size | frames | frame use |
|---|---|---|---|
| `elder` | 12x26 | 6 | walk 0-3 (a shuffle for 2.5 game px a frame), idle 4-5 (Old Hemmet) |
| `labourer` | 12x26 | 6 | walk 0-3 (the limp: 0 the short step onto the bad foot, 1 the good leg swinging through with the body 2 px down, 2 the long step of the good leg, 3 the bad leg dragged through stiff with the body up), idle 4-5 (Brede Hask) |
| `washerwoman` | 12x26 | 10 | walk 0-3, idle 4-5 (the basket on her near hip under her arm, the bare red forearm laid across the linen), wring 6-7 (the basket set down before her feet, a sheet held level across her chest between her two red fists, its twist banding a pixel on between the frames, a drop falling), call 8-9 (people-2: in her doorway at the horn, the far fist on her hip, the near raw hand cupped at her mouth, then the near arm raised high, beckoning) (Wenna Brisk) |
| `farmerHoe` | 12x26 | 14 | walk 0-3 and idle 4-5 with the hoe on the shoulder; work 6-7 (the hoe raised, struck into the row); straighten 8-9 (the hoe planted and the far hand at the back, then upright with the face lifted); carry 10-13 (the walk's steps with a sack on the back) (Gorm Ashby) |
| `farmerScythe` | 12x26 | 14 | walk 0-3 and idle 4-5 with the scythe on the shoulder; mow 6-7 (the snath across her body: swung back with the blade's curve along the ground behind her heels, swung through with it before her feet; the upper body a pixel back, then forward; the apron straight); straighten 8-9 (leaning on the upright scythe, its blade curved over her head, the far hand at the back, then the forearm across the brow); carry 10-13 (the walk's steps with a sheaf before her; 13 is a copy of 11) (Hedda Ashby) |

Anchors: the engine advances one walk frame per stride (`PeopleCast.stride`), and the stride is what the grids were
painted for: the planted foot travels from the front of one contact to the back of the next in two frames, 6 game px
for the cast's grown-ups (stride 3), 5 for Old Hemmet (2.5); the three repainted townsfolk keep the base game's 4. The farmers' tools stay inside the 12 px frame in every pose: the hoe's thin blade at the
ground in frame 7 is on the bottom row at cols 9-11; the scythe's blade lies along rows 22-23 at cols 0-3 in frame 6
and at cols 9-11 in frame 7.

## The children

| id | size | frames | frame use |
|---|---|---|---|
| `childA`, `childB` | 12x18 | 12 each | run 0-3 (contact 0 and 2, flight 1 and 3 with the body 1 px up and the feet off the ground; 5 game px a frame), fidget 4-5, skip 6-9 (the step 6 and 8, the hop 7 and 9 with the body 2 px up; 4 px a frame), the stick fight 10-11 (people-2: the stick raised back over the head, then thrust level ahead in a lunge; 12 wide from people-2 so the stick fits) (Nib Brisk, Wren Ashby) |
| `childC` | 10x18 | 10 | as Nib's and Wren's 0-9 (Fen) |

The children's tops are a value step above any grown-up's cloth and each carries the children's red where it shows at
phone size (Nib's whole kerchief and a patch, Wren's pinafore and ribbons, Fen's cap). The flight and hop frames (1, 3,
7, 9) have nothing on the bottom row: the animation means it. A child is about 13 px
tall (Fen 15), a grown-up 20 to 22, the lord 29.

## The nobles of the inner lands and the footman (the guests' contract)

| id | size | frames | frame use |
|---|---|---|---|
| `nobleLord` | 14x30 | 10 | walk 0-3 (short measured steps, the cane set down on the contact), idle 4-5 (both gloves on the cane), talk 6-7 (a gloved hand turned up, rolled higher), bow 8-9 (the glove laid on the chest, then the head and hat inclined with the knees a pixel bent; no cane, as in the talk) (Ser Aubrey Oxmoor and his kind) |
| `nobleLady` | 14x30 | 10 | walk 0-3 (a glide: the gown's front steps out with a shoe's tip on 0 and 2; 3 is a copy of 1; the cloth held at her chest), idle 4-5 (the lace cloth pressed to her nose and mouth by the gloved hand, inside the face's outline), talk 6-7 (the cloth lowered, the hand turned out), bow 8-9 (the hand with the cloth at the chest, then the head inclined and the body a pixel lower) |
| `footman` | 14x30 | 8 | walk 0-3 and idle 4-5 (the chest held level in both arms), talk 6-7 (the chest set down at his feet, the purse held out, offered lower) |

They have no seated strip: a noble never sits on the hall's benches. In a `SpeakerBody.court` the talk frames are
6-7; as a `SpeakerBody.townsfolk` (the `noble` petitioner) the body walks 0-3 and idles 4-5.

The bow plays only when the realm is a town (`PeopleCast.bowFrame`: 8 for 0.5 s, 9 for 0.8 s, 8 for 0.3 s after the
noble comes before the lord); the footman never bows.

## Cloth states (the realm's stage: hamlet, village, town)

The realm's three stages change the cloth of the working people and the children, never their bodies (docs/PEOPLE.md
section 7). A state is its body's grid with cloth characters remapped by `#@state village …` / `#@state town …` comment
lines in the grid itself (tools/actorart.py skips them, so the hamlet build is unchanged); `tools/peoplestates.py build`
writes `<id>Village.png` and `<id>Town.png`, `check` proves the alpha is the body's in every pixel (the unit test does
the same on the atlas). Where a garment shared a glyph with a tool, skin or hair, the grid gives the garment its own
glyph (the same colour), so only cloth moves: Ned's vest `v V`, Hemmet's cape `y v V`, Brede's jerkin `j J`, Gorm's
smock `y o v` and shin rags `Q U`, Hedda's skirt `y o v`, Dun's worn boot toes `o`, the patches and darns `p`. The nobles
and the footman have no states.

| id | size | frames | frame use |
|---|---|---|---|
| `citizenVillage`, `citizenBVillage`, `citizenCVillage`, `citizenTown`, `citizenBTown`, `citizenCTown` | 12x26 | 6 each | as their bodies |
| `citizenSeatedVillage`, `citizenBSeatedVillage`, `citizenCSeatedVillage`, `citizenSeatedTown`, `citizenBSeatedTown`, `citizenCSeatedTown` | 12x22 | 2 each | as their bodies |
| `elderVillage`, `elderTown`, `labourerVillage`, `labourerTown` | 12x26 | 6 each | as their bodies |
| `washerwomanVillage`, `washerwomanTown` | 12x26 | 10 each | as their body |
| `farmerHoeVillage`, `farmerHoeTown`, `farmerScytheVillage`, `farmerScytheTown` | 12x26 | 14 each | as their bodies |
| `childATown`, `childBTown` | 12x18 | 12 each | as their bodies (the children have no village state) |
| `childCTown` | 10x18 | 10 | as its body |
| `elderSeatedVillage`, `elderSeatedTown` | 12x22 | 2 each | as their body (people-2) |

In code: `SpriteID` has the 25 ids in one case block after the cast; their size and frames are their body's
(`PeopleCast.body(dressedAs:)`); `PeopleCast.dressed(body, state)` picks the sprite; `PeopleCast.ClothState(standing:)`
maps the town's standing (0-2 hamlet, 3-6 village, 7-10 town).


## Atlas

The cast adds 106 frames (the nobles' bow 4 of them) and the cloth states 200 more: 25 strips of 12x26, 12x22 and
10x18 frames, in cells of 16x30, 16x26 and 14x22 with padding. `PeopleCastTests` packs the page again without the
clamp, prints the rows used ("people lane: atlas … rows used") and checks that it fits 2048 rows; AtlasTests checks
every cell lies inside the page. If the joined game needs the room, the village states go first (the town's stay).

## People-2: the town's day (docs/PEOPLE.md section 5, `TownLife`, `TownLamps`)

All hand-set part grids through `tools/actorart.py` (tools/grids/people/), rebuilt by `tools/build-art-people.sh`.

| id | size | frames | frame use |
|---|---|---|---|
| `lamplighter` | 36x30 | 12 | walk 0-3 (a long stride, 4 game px a frame; the pole on the near shoulder, its tip up behind him), idle 4-5 (the pole upright at his side, a breath), light 6-7 (both hands on the pole, its tip raised to a lantern's glass 15 px ahead of his feet at a height of 20, then the wick at the glass), snuff 8-9 (the pole steeper and higher, the snuffer's bell turned mouth down above the lantern's cap, then over it), hearth 10-11 (the tip held low ahead into the Flame, then the head bowed to it). His feet on the frame's middle column (18) (Silas Moth) |
| `lamplighterGlow` | 36x30 | 12 | the wick's flame at the pole's tip in every frame but 8-9 (`fireGold`); drawn only while the wick burns. The tip from his feet (facing right): walk (-12.5, 29.5), idle (7.5, 28.5), 6 (12.5, 18.5), 7 (14.5, 20.5), 10-11 (14.5, 6.5) (`TownLamps.poleTip`) |
| `collector` | 34x24 | 8 | push 0-3 (leaning into the handcart's handles one-handed, the strap over his shoulder; 4 game px a frame; the wheel's spokes turn), idle 4-5 (at his post by the hall door, the hand on the strongbox), take 6-7 (at a door: the hand held out, then the coin dropped through the box's slot with a nod). His feet on column 8.5, the cart ahead of him (`PeopleCast.feetColumn`) (Saul Bracken) |
| `coach` | 60x34 | 1 | the noble's travelling coach at rest, facing the gate: Oxmoor's crimson and gold, the shafts down on the lane (the horses are in the tavern's stable), the trunk on the roof, the curtains drawn. A prop (left edge on its x) |
| `elderSeated` | 12x22 | 2 | seated 0, a nod 1 (on the bench by the square, the hall's bench drawn behind him; facing out like the seated townsfolk, the head in profile) (Old Hemmet) |

## The lord's cloak (people-2 fix round 1; the director's note of 14.11. 14:35, `LordCloak`)

The lord's own cloak in two states, like the townsfolk's cloth (REALM.md section 2): **mended** in the hamlet and the
village, **good** in the town. The good state is the lord's sheets as painted (`king`, `lady`, `kingSeated`,
`ladySeated`); the mended state is four sheets that take their body's parts and change only cloak pixels (written by
`tools/lordcloak.py`, built by `tools/build-art-people.sh`): the mantle's bright edge (`roofLight`) faded to the house
colour (`banner`), a patch of grey-blue wool on the back below the belt (`far` lit at its upper left, `farDeep`), and a
darned tear lower down in brown thread (`soilLight`). Same size, frames, alpha and lantern anchors; no glow strip of
their own (the engine draws the body's glow strip over them). The lord is not repainted beyond the cloak.

| id | size | frames | frame use |
|---|---|---|---|
| `kingMended` | 16x30 | 10 | `king` frame for frame in the mended cloak (glow: `kingGlow`) |
| `ladyMended` | 16x30 | 10 | `lady` frame for frame in the mended cloak, the patch and the darn below her plait (glow: `ladyGlow`) |
| `kingSeatedMended` | 16x30 | 4 | `kingSeated` frame for frame, the patch on the narrow cloak between his back and the throne (glow: `kingSeatedGlow`) |
| `ladySeatedMended` | 16x30 | 4 | `ladySeated` frame for frame, the patch on the cloak below the plait (glow: `ladySeatedGlow`) |

## The court's ties (people-2 fix round 1; the director's note of 14.11. 15:03, docs/HOUSE.md section 2, `CourtTies`)

One more idle per court member that is played toward another person (the engine mirrors it to face them): frame 0 a
nod (the head under the collar a pixel lower, the shoulders still), frame 1 the thread itself, mostly something
handed over. Each sheet takes its member's parts and the placements of the member's idle or talk frame (written by
`tools/courtties.py`, built by `tools/build-art-people.sh`), so the size, the outline and the feet are the member's.
Separate sheets, so the members' own sheets (8 frames each) stay untouched for the hall's rebuild.

| id | size | frames | frame use |
|---|---|---|---|
| `odileTie` | 14x30 | 2 | a nod, then the ledger held out on her palm (Odile taught the lord the ledger) |
| `brannockTie` | 16x30 | 2 | a curt nod, then the iron key of the wall stair held out |
| `pipTie` | 12x22 | 2 | a bob of the head, then a juggling ball held out |
| `hesperTie` | 14x30 | 2 | a nod, then the nod held with her hand on her heart (to the lamplighter at the hearth, HOUSE.md section 6) |
| `hesperTieGlow` | 14x30 | 2 | the staff's flame on the same frames (`hesperGlow`'s) |
| `tamsinTie` | 14x28 | 2 | a nod, then a bowl of supper held out |
| `bramTie` | 16x30 | 2 | a nod, then the mended clasp held out between finger and thumb |
| `marekTie` | 14x30 | 2 | a merchant's nod, then the first orange of winter on his palm |
| `serenTie` | 14x30 | 2 | a cool nod, then a coin of her house's debt on her open hand |
| `serenTieGlow` | 14x30 | 2 | the grey lantern's light on the same frames (`serenGlow`'s) |

