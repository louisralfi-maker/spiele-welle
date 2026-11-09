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
# palette subsets of the key-pose conversions
GI=ink,rockDeep,soilDark,woodDark,stoneDark,stoneMid,stone,stoneLight,rockDark,rock,tile,wood
BR=ink,rockDeep,stoneDark,stoneMid,stone,stoneLight,stonePale,tile
LK=ink,night0,stoneDark,stoneMid,stone,stoneLight,banner,roofDeep,roofLight,rock,woodLight,soilLight,straw,woodDark,rockDeep
GW=night0,night1,night2,ink,stoneDark,stoneMid,stone,stoneLight,stonePale,moon

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
    ashBrute)      # two key poses of brute-b at one common scale (15.8 sheet px per game px)
        mkdir -p $K
        python3 -I $T convert $R/brute-b-1.png $K/ashBrute-walk.png --size 38x33 --box 144,176,752,704 --only $BR --gain 0.95
        python3 -I $T convert $R/brute-b-1.png $K/ashBrute-attack.png --size 33x44 --box 892,8,1420,704 --only $BR --gain 0.95
        python3 -I $AA build $G/ashBrute.txt --out $A ;;
    gloomweaver)   # the conversion is the reference the hand-set grid follows (hood slant, orb); the sprite is the grid
        mkdir -p $K
        python3 -I $T convert $R/creatures-b-1.png $K/gloomweaver-conv.png --size 30x30 --box 150,12,690,744 --fit contain --key '#1CE49C' --tol 70 --only $GW
        python3 -I $AA build $G/gloomweaver.txt --out $A ;;
    ashGiant)      # the shaded side lifted one value step (ink to rockDeep, rockDeep to stoneDark, stoneDark to stoneMid)
        mkdir -p $K
        python3 -I $T convert $R/creatures-a-1.png $K/ashGiant-conv.png --size 110x110 --box 864,16,1456,752 --fit contain --only $GI --gain 1.9
        python3 -I $T post $K/ashGiant-conv.png $K/ashGiant-key.png --remap ink:rockDeep,rockDeep:stoneDark,stoneDark:stoneMid
        python3 -I $AA build $G/ashGiant.txt --out $A ;;
    lightlessKing) # the cloak recoloured (night0 to night1, its lit folds to night2) so it is no black band
        mkdir -p $K
        python3 -I $T convert $R/creatures-b-1.png $K/lightlessKing-conv.png --size 64x64 --box 700,24,1262,746 --fit contain --pad 2,6,2,0 --key '#1CE49C' --tol 70 --only $LK --gain 1.1
        python3 -I $T post $K/lightlessKing-conv.png $K/lightlessKing-key.png --remap night0:night1,stoneDark:night2,ink:night0
        python3 -I $AA build $G/lightlessKing.txt --out $A ;;
    *) echo "unknown sprite $1" >&2; return 1 ;;
    esac
}

ALL="sootling sootlingB shadehound sootCrow ashBrute gloomweaver ashGiant lightlessKing archer guardsman builder king
citizen citizenB citizenC"
for name in ${@:-$ALL}; do
    cool
    build "$name"
done
