#!/bin/bash
# Rebuilds the actors and the creatures (SPRITES.md) and their glow strips in Resources/Art. The people come from the
# hand-set part grids in tools/grids/actors/ (tools/actorart.py). The eight creatures are look 2's lost people
# (ART-look2.md, "Stage 3: the creatures"): each is a small painter in tools/creatures/<id>.py, drawn by tools/rig.py
# and written by tools/creatureart.py; no Recraft image is involved. The creature grids still lying in
# tools/grids/actors/ (sootling, shadehound, ashBrute and the others) are look 1's sources and are no longer built.
# One sprite at a time with a pause between, and a wait while the CPU is at 80 °C or more (this old Mac's heat rule).
# A full run reproduces the committed files byte for byte. Run from anywhere:
#   bash games/lanternhold/tools/build-art-actors.sh [name …]
set -euo pipefail
cd "$(dirname "$0")/../../.."
AA=games/lanternhold/tools/actorart.py
CA=games/lanternhold/tools/creatureart.py
A=games/lanternhold/Resources/Art
G=games/lanternhold/tools/grids/actors
SMC=/Users/enaayla/Desktop/Spiele-Welle/tools/smcread

cool() { # wait below 70 °C when the CPU reached 80 °C
    [ -x "$SMC" ] || return 0
    local t; t=$("$SMC" | sed -n 's/.*TCXC=\([0-9]*\).*/\1/p')
    if [ -n "$t" ] && [ "$t" -ge 80 ]; then
        echo "CPU $t °C, waiting"; while t=$("$SMC" | sed -n 's/.*TCXC=\([0-9]*\).*/\1/p'); [ "$t" -ge 70 ]; do sleep 10; done
    fi
    sleep 1
}

build() { # name: one sprite (and its glow strip)
    case $1 in
    archer|guardsman|builder|king|lady|kingSeated|ladySeated|citizen|citizenB|citizenC|citizenSeated|citizenBSeated|citizenCSeated)
        python3 -I $AA build $G/$1.txt --out $A ;;
    sootling|sootlingB|shadehound|sootCrow|ashBrute|gloomweaver|ashGiant|lightlessKing)
        python3 -I -B $CA build $1 --out $A ;;
    darknessBank)  # the Gloom's bank of look 2: darknessBank.png, darknessEdge.png and darknessBankGlow.png
        python3 -I -B games/lanternhold/tools/bankart.py --out $A ;;
    *) echo "unknown sprite $1" >&2; return 1 ;;
    esac
}

ALL="sootling sootlingB shadehound sootCrow ashBrute gloomweaver ashGiant lightlessKing darknessBank archer guardsman builder king
lady kingSeated ladySeated citizen citizenB citizenC citizenSeated citizenBSeated citizenCSeated"
if [ "${1:-}" = "--list" ]; then echo $ALL; exit 0; fi  # the names, for build-art.sh
for name in ${@:-$ALL}; do
    cool
    build "$name"
done
