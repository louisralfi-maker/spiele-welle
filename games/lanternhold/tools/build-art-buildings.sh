#!/bin/bash
# Rebuilds the building, overlay and projectile sprites of SPRITES.md (the M2b art lane, ART-buildings.md) in
# Resources/Art: hand-set grids in tools/grids/buildings/ (and tools/grids/palisade.txt, ballista.txt), Recraft
# conversions from the raws in build/recraft/lh/bld/ (git-ignored; prompts in ART-buildings.md) with intermediate parts
# in build/recraft/lh/bld/parts/. One image at a time with a pause between, and a wait while the CPU is at 80 °C or more
# (this old Mac's heat rule). Run from anywhere: bash games/lanternhold/tools/build-art-buildings.sh [name …]
set -euo pipefail
cd "$(dirname "$0")/../../.."
T=games/lanternhold/tools/pixelart.py
A=games/lanternhold/Resources/Art
G=games/lanternhold/tools/grids
GB=games/lanternhold/tools/grids/buildings
B=build/recraft/lh/bld          # the Recraft sheets of this lane
PB=build/recraft/lh/bld/parts   # intermediate parts
SMC=/Users/enaayla/Desktop/Spiele-Welle/tools/smcread

cool() { # wait below 70 °C when the CPU reached 80 °C
    [ -x "$SMC" ] || return 0
    local t; t=$("$SMC" | sed -n 's/.*TCXC=\([0-9]*\).*/\1/p')
    if [ -n "$t" ] && [ "$t" -ge 80 ]; then
        echo "CPU $t °C, waiting"; while t=$("$SMC" | sed -n 's/.*TCXC=\([0-9]*\).*/\1/p'); [ "$t" -ge 70 ]; do sleep 10; done
    fi
    sleep 1
}

build() { # name: one sprite
    case $1 in
    # --- walls: frame 0 whole, frame 1 damaged. palisade and ballista keep their grids in tools/grids/ (build-art.sh
    # builds them from there too, so both scripts write the same two-frame files); stoneWall's frame 0 is the
    # milestone 1 conversion written out as a grid, with frame 1 beside it
    palisade|ballista)
                   python3 -I -B $T grid $G/$1.txt $A/$1.png ;;
    stoneWall|bastion|rubbleWood|rubbleStone|scaffold|gateWood|gateIron|gateGreat|gateBroken|archerTower|watchtower|\
    fireTower|catapult|stakePit|beaconTower|greatBeacon|beaconFire|barracks|smithy|masterSmithy|lodge|bigLodge|\
    plotMarker|arrow|fireArrow|bolt|firepot)
                   python3 -I -B $T grid $GB/$1.txt $A/$1.png ;;
    # look 2, stage 4 (ART-look2.md section 15): painted by townart.py; their grids in grids/buildings stay, unused
    bigHouse|market|tavern)
                   python3 -I -B games/lanternhold/tools/townart.py build $1 --out $A ;;
    # fix stage: the first stage keeps the ruin's broken shell standing behind the new pale courses (beaconRuin.png
    # without its fire cage: the body from row 34, the two broken stubs from row 22), the shear legs rising above it
    beaconBase)    mkdir -p $PB
                   python3 -I -B $T grid $GB/beaconBase.txt $PB/beaconBase-front.png
                   python3 -I -B $T compose $A/beaconBase.png --size 64x130 --layer $A/beaconRuin.png@0,34@box=0,34,64,130 \
                       --layer $A/beaconRuin.png@0,22@box=0,22,18,34 --layer $A/beaconRuin.png@42,22@box=42,22,64,34 \
                       --layer $PB/beaconBase-front.png@0,0 ;;
    *) echo "unknown sprite $1" >&2; return 1 ;;
    esac
}

ALL="palisade stoneWall bastion rubbleWood rubbleStone scaffold gateWood gateIron gateGreat gateBroken archerTower
watchtower fireTower ballista catapult stakePit beaconBase beaconTower greatBeacon beaconFire
barracks smithy masterSmithy lodge bigLodge bigHouse market tavern plotMarker arrow fireArrow bolt firepot"
if [ "${1:-}" = "--list" ]; then echo $ALL; exit 0; fi  # the names, for build-art.sh
for name in ${@:-$ALL}; do
    cool
    build "$name"
done
