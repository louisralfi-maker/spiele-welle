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
| `citizen`, `citizenB`, `citizenC` | 12x26 | 6 each | walk 0-3, idle 4-5 (Mother Corra, Dun Rook, Aldo Fenn) |
| `citizenSeated`, `citizenBSeated`, `citizenCSeated` | 12x22 | 2 each | seated 0, a nod 1 (on the hall's benches, as SPRITES.md "The townsfolk seated") |

## The working people (the citizen contract, with work frames after it)

| id | size | frames | frame use |
|---|---|---|---|
| `elder` | 12x26 | 6 | walk 0-3 (a shuffle for 2.5 game px a frame), idle 4-5 (Old Hemmet) |
| `labourer` | 12x26 | 6 | walk 0-3 (the limp: 0 the short step onto the bad foot, 1 the good leg swinging through with the body 2 px down, 2 the long step of the good leg, 3 the bad leg dragged through stiff with the body up), idle 4-5 (Brede Hask) |
| `washerwoman` | 12x26 | 8 | walk 0-3, idle 4-5, wring 6-7 (the basket set down before her feet, a sheet twisted between her fists) (Wenna Brisk) |
| `farmerHoe` | 12x26 | 14 | walk 0-3 and idle 4-5 with the hoe on the shoulder; work 6-7 (the hoe raised, struck into the row); straighten 8-9 (the hoe planted and the far hand at the back, then upright with the face lifted); carry 10-13 (the walk's steps with a sack on the back) (Gorm Ashby) |
| `farmerScythe` | 12x26 | 14 | walk 0-3 and idle 4-5 with the scythe on the shoulder; work 6-7 (the scythe swung back low, swung through with the blade along the ground); straighten 8-9 (leaning on the upright scythe with the far hand at the back, then the forearm across the brow); carry 10-13 (the walk's steps with a sheaf before her; 13 is a copy of 11) (Hedda Ashby) |

Anchors: the engine advances one walk frame per stride (`PeopleCast.stride`), and the stride is what the grids were
painted for: the planted foot travels from the front of one contact to the back of the next in two frames, 6 game px
for the cast's grown-ups (stride 3), 5 for Old Hemmet (2.5); the three repainted townsfolk keep the base game's 4. The farmers' tools stay inside the 12 px frame in every pose: the hoe's blade at the
ground in frame 7 is on the bottom body row at cols 9-11, the scythe's blade in frame 7 lies along row 23 at cols 6-9.

## The children

| id | size | frames | frame use |
|---|---|---|---|
| `childA`, `childB`, `childC` | 10x18 | 10 each | run 0-3 (contact 0 and 2, flight 1 and 3 with the body 1 px up and the feet off the ground; 5 game px a frame), fidget 4-5, skip 6-9 (the step 6 and 8, the hop 7 and 9 with the body 2 px up; 4 px a frame) (Pim Brisk, Wren Ashby, Fen) |

The flight and hop frames (1, 3, 7, 9) have nothing on the bottom row: the animation means it. A child is about 13 px
tall (Fen 15), a grown-up 20 to 22, the lord 29.

## The nobles of the inner lands and the footman (the guests' contract)

| id | size | frames | frame use |
|---|---|---|---|
| `nobleLord` | 14x30 | 8 | walk 0-3 (short measured steps, the cane set down on the contact), idle 4-5 (both gloves on the cane), talk 6-7 (a gloved hand turned up, rolled higher) (Ser Aubrey Oxmoor and his kind) |
| `nobleLady` | 14x30 | 8 | walk 0-3 (a glide: the gown's front steps out with a shoe's tip on 0 and 2; 3 is a copy of 1), idle 4-5 (the lace cloth at her nose), talk 6-7 (the cloth lowered, the hand turned out) |
| `footman` | 14x30 | 8 | walk 0-3 and idle 4-5 (the chest held level in both arms), talk 6-7 (the chest set down at his feet, the purse held out, offered lower) |

They have no seated strip: a noble never sits on the hall's benches. In a `SpeakerBody.court` the talk frames are
6-7; as a `SpeakerBody.townsfolk` (the `noble` petitioner) the body walks 0-3 and idles 4-5.

## Atlas

The cast adds 102 frames: 48 cells of 16x30 with padding, 30 of 14x22 and 24 of 18x34 (about 1620 px of shelf, at
most three new shelves of about 86 rows in all). `PeopleCastTests` checks that the page still fits 2048 rows.
