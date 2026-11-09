# Lanternhold: sprite contract for the entities (M2b and the art lane)

This file is the contract between the code lane (M2b puts the game on screen) and the art lane (paints the PNGs). It
was set by the lead on 09.11.2026. Neither lane changes it on its own. A lane that needs a change writes the deviation
into its own notes (ART.md or DESIGN.md) and reports it, and the lead updates this file.

## Rules for every sprite here

- File: `games/lanternhold/Resources/Art/<id>.png`, where `<id>` is the `SpriteID` raw value below, spelled exactly.
  The atlas loads that PNG when it exists and otherwise draws the procedural placeholder (`AtlasBuilder.frames`), so a
  missing PNG never breaks the build.
- Format: 8-bit RGBA, binary alpha, one texel is one game pixel, colours from `tools/palette.txt` only (the albedo
  ramps for bodies; the `emissive` fire ramp only in the glow strips).
- Size: one row of frames, left to right, no gaps: the PNG is (width x frames) by height.
- Anchor: the bottom centre of every frame is the foot point (x on the ground line, or the wall walk for soldiers on
  a wall). Keep the feet on the bottom row in every frame, so the sprite does not bob unless the animation means it.
- Facing: every actor faces right in the PNG. The engine mirrors it when it walks or aims left.
- Light: albedo only, as for the scene (ART.md): no baked night, no glow and no light pools in the body. Everything
  that glows goes into a separate glow strip (`<id>Glow`) of the same size and frames. The engine draws the glow strip
  additively in the emissive pass, exactly over the body frame.
- Unlit creatures: at night outside every light the engine draws only the glow strip (ember eyes and faint cracks) and
  the body at a very low value. In light the whole body shows. So the glow strip alone must still read as the creature
  (eye shape and spacing, a few crack lines), and the body must read in daylight and in firelight.

## Actors

| id | size | frames | frame use |
|---|---|---|---|
| `king` | 16x30 | 10 | walk 0-5 (as the placeholder now), idle 6-7, command 8-9 (lifts the lantern to give an order) |
| `kingGlow` | 16x30 | 10 | the lantern glass (and a glint on the crown) per frame |
| `citizen`, `citizenB`, `citizenC` | 12x26 | 6 each | walk 0-3, idle 4-5 (three different townsfolk) |
| `archer` | 12x28 | 5 | idle 0-1, draw 2-3, loose 4 |
| `guardsman` | 14x28 | 9 | idle 0-1, walk 2-5, strike 6-8 |
| `builder` | 12x24 | 6 | walk 0-3, hammer 4-5 |

## Creatures (and their glow strips, same size and frames)

| id | size | frames | frame use |
|---|---|---|---|
| `sootling`, `sootlingB` | 14x14 | 6 each | walk 0-3, attack 4-5 (two silhouettes; the engine alternates by creature id) |
| `shadehound` | 22x14 | 6 | run 0-3, attack 4-5 |
| `sootCrow` | 12x10 | 4 | fly 0-2, perch 3 |
| `ashBrute` | 44x44 | 7 | walk 0-3, attack 4-6 |
| `gloomweaver` | 30x30 | 4 | float 0-3 |
| `ashGiant` | 110x110 | 7 | walk 0-3, stomp 4-6 |
| `lightlessKing` | 64x64 | 7 | walk 0-3, attack 4-6 |

Glow strips: `sootlingGlow`, `sootlingBGlow`, `shadehoundGlow`, `sootCrowGlow`, `ashBruteGlow`, `gloomweaverGlow`,
`ashGiantGlow`, `lightlessKingGlow`. Ember eyes and cracks in the fire ramp; the gloomweaver's eyes and orb are cold
violet and the Lightless King's are a cold pale teal (add tagged `emissive` palette entries for these if needed, and
check that `build-art.sh` still rebuilds every committed sprite byte for byte).

## Buildings (frame 0 whole, frame 1 damaged below 50 % HP, unless the table says otherwise)

| id | size | frames | notes |
|---|---|---|---|
| `palisade` | 20x34 | 2 | was 1 frame |
| `stoneWall` | 36x52 | 2 | was 1 frame |
| `bastion` | 44x64 | 2 | |
| `rubbleWood` | 24x10 | 1 | a fallen palisade |
| `rubbleStone` | 40x14 | 1 | a fallen stone wall or bastion |
| `scaffold` | 24x40 | 1 | over a build in progress; the engine tiles it over wide builds |
| `gateWood`, `gateIron`, `gateGreat` | 46x60 | 3 each | closed whole 0, closed damaged 1, open 2; overlays inside the castle front's gateway (x 1337-1383); fit the painted arch of `castleFront.png` exactly |
| `gateBroken` | 46x20 | 1 | splinters and bent bars at the foot of the gateway |
| `archerTower` | 20x48 | 1 | lines 2 and 3 only (line 1 mans the painted towers) |
| `watchtower` | 24x64 | 1 | tier 2 of the tower |
| `fireTower` | 14x40 | 1 | tier 2 of the brazier; its fire is the existing `brazierFlame` glow at the top |
| `ballista` | 28x16 | 2 | loaded 0, loosed 1 (was 1 frame) |
| `catapult` | 32x24 | 3 | rest 0, wind 1, throw 2 |
| `stakePit` | 24x8 | 2 | armed 0, sprung 1 |
| `beaconBase`, `beaconTower`, `greatBeacon` | 64x130 | 1 each | the three built stages after `beaconRuin`; the great beacon carries a huge iron bowl at the top |
| `beaconFire` | 24x20 | 3 | glow strip only (fire ramp), flicker frames, sits in the great beacon's bowl |
| `barracks` | 64x48 | 1 | courtyard, always there (castle palette) |
| `smithy`, `masterSmithy` | 60x48, 60x56 | 1 each | courtyard |
| `lodge`, `bigLodge` | 56x44, 64x52 | 1 each | courtyard |
| `bigHouse` | 72x56 | 1 | town (`house`, `houseB`, `houseC`, `field` exist) |
| `market` | 90x40 | 1 | town: stalls with awnings |
| `tavern` | 90x56 | 1 | town: two storeys and a sign |
| `plotMarker` | 10x16 | 1 | stakes and a small banner on an empty, unlocked plot by day |

## Projectiles

| id | size | frames | frame use |
|---|---|---|---|
| `arrow` | 7x5 | 3 | rising 0, flat 1, falling 2 |
| `fireArrow` | 7x5 | 3 | as `arrow`; the engine adds a small glow |
| `bolt` | 11x5 | 3 | as `arrow` |
| `firepot` | 5x5 | 2 | tumbling |

## Where things stand in the world (game px; ground line as in `tools/scenemock/layout_m1b.py`)

Walls (lines 1 to 3): x 1300 (the castle gate), 940, 640. Towers 978, 662 (line 1: the painted towers). Braziers
896 and 920, 596 and 617. Engines 990, 676. Stake pits 860, 560. Beacon 470. Barracks 1480, lodge 1640, hearth 1870,
keep 1990. Town plots 2512, 2680, 2832, 2932, 3122, 3245, 3365, 3540 (from M2a on; the M1b port branch's `Realm`
still has them 100 px further left). The castle front spans 1240-1480, its wall walk is `WorldLayout.wallWalkY` (124)
and its gateway 1337-1383. Creatures come from the left (the Gloom) and walk right towards the hearth.
