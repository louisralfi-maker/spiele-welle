#!/bin/bash
# Renders the M3 court art lane's context scenes (scene_court.py) into build/recraft/lh/preview/court-<name>.png
# (437x201, upscaled x3) and a device-scale crop of the court in each (court-<name>-x6.png: 6 device px per game px,
# as the iPhone 17 Pro shows the game), one render at a time with the heat rule (wait below 70 °C when the CPU reached
# 80 °C) and a pause between renders. Proposals of this lane, if any lie in tools/grids/court/proposals/, are built
# first into build/recraft/lh/court/proposals/ (never into Resources/Art); the seated lord was one until the art pass
# painted kingSeated into Resources/Art (tools/grids/actors/kingSeated.txt, ART-look2.md section 15).
# Usage: run_court.sh [name ...]
set -euo pipefail
cd "$(dirname "$0")/../../../.."
G=games/lanternhold
OUT=build/recraft/lh/preview
PROP=build/recraft/lh/court/proposals
SMC=/Users/enaayla/Desktop/Spiele-Welle/tools/smcread
mkdir -p $OUT/court $PROP
cool() {
    [ -x "$SMC" ] || return 0
    local t; t=$("$SMC" | sed -n 's/.*TCXC=\([0-9]*\).*/\1/p')
    if [ -n "$t" ] && [ "$t" -ge 80 ]; then
        echo "CPU $t °C, waiting"; while t=$("$SMC" | sed -n 's/.*TCXC=\([0-9]*\).*/\1/p'); [ "$t" -ge 70 ]; do sleep 10; done
    fi
}
for p in $G/tools/grids/court/proposals/*.txt; do [ -e "$p" ] || continue; python3 -I $G/tools/actorart.py build "$p" --out $PROP; done
# the device-scale crop per scene: the box (game px of the 437x201 frame) around the court
crop() {
    case $1 in
    hall-day)         echo 112,130,262,178 ;;
    hall-night)       echo 108,128,345,178 ;;
    hall-herald)      echo 140,130,290,178 ;;
    courtyard-day)    echo 112,124,326,178 ;;
    courtyard-guests) echo 108,124,312,178 ;;
    lineup-day|lineup-night) echo 86,134,356,178 ;;
    esac
}
for name in ${@:-hall-day hall-night hall-herald courtyard-day courtyard-guests lineup-day lineup-night}; do
    cool
    python3 -I -B $G/tools/scenemock/scene_court.py $G "$name" $OUT/court-$name.png
    python3 -I -B $G/tools/scenemock/zoom.py $OUT/court-$name.png $OUT/court-$name-x6.png "$(crop $name)"
    sleep 4
done
