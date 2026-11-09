#!/bin/bash
# Rebuilds the M2b actors and creatures (SPRITES.md) and their glow strips in Resources/Art: the small ones from the
# hand-set part grids in tools/grids/actors/ (tools/actorart.py), the four big creatures from their Recraft key poses in
# build/recraft/lh/actors/ (git-ignored; prompts in ART-actors.md), converted by pixelart.py and cut into parts. One
# sprite at a time with a pause between, and a wait while the CPU is at 80 °C or more (this old Mac's heat rule).
# A full run reproduces the committed files byte for byte. Run from anywhere:
#   bash games/lanternhold/tools/build-art-actors.sh [name …]
set -euo pipefail
cd "$(dirname "$0")/../../.."
T=games/lanternhold/tools/pixelart.py
AA=games/lanternhold/tools/actorart.py
A=games/lanternhold/Resources/Art
G=games/lanternhold/tools/grids/actors
R=build/recraft/lh/actors          # the Recraft key-pose sheets (ART-actors.md)
K=build/recraft/lh/actors/keys     # converted key poses, the parts' source images
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
    sootling|sootlingB|shadehound|sootCrow|archer|guardsman|builder|king|citizen|citizenB|citizenC)
        python3 -I $AA build $G/$1.txt --out $A ;;
    *) echo "unknown sprite $1" >&2; return 1 ;;
    esac
}

ALL="sootling sootlingB shadehound sootCrow archer guardsman builder king citizen citizenB citizenC"
for name in ${@:-$ALL}; do
    cool
    build "$name"
done
