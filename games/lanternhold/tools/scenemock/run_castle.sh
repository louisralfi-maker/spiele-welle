#!/bin/bash
# Renders the M3 art lane's step 3 context scenes (scene_castle.py: the castle's rooms and the court's props) into
# build/recraft/lh/preview/castle-<name>.png (437x201, upscaled x3) and a device-scale crop of the room in each
# (castle-<name>-x6.png: 6 device px per game px, as the iPhone 17 Pro shows the game), one render at a time with the
# heat rule (wait below 70 °C when the CPU reached 80 °C) and a pause between renders. The seated king is a proposal
# of the lane: built first from tools/grids/court/proposals/ into build/recraft/lh/court/proposals/ (never into
# Resources/Art). Usage: run_castle.sh [name ...]
set -euo pipefail
cd "$(dirname "$0")/../../../.."
G=games/lanternhold
OUT=build/recraft/lh/preview
PROP=build/recraft/lh/court/proposals
SMC=/Users/enaayla/Desktop/Spiele-Welle/tools/smcread
mkdir -p $OUT/castle $PROP
cool() {
    [ -x "$SMC" ] || return 0
    local t; t=$("$SMC" | sed -n 's/.*TCXC=\([0-9]*\).*/\1/p')
    if [ -n "$t" ] && [ "$t" -ge 80 ]; then
        echo "CPU $t °C, waiting"; while t=$("$SMC" | sed -n 's/.*TCXC=\([0-9]*\).*/\1/p'); [ "$t" -ge 70 ]; do sleep 10; done
    fi
}
for p in $G/tools/grids/court/proposals/*.txt; do python3 -I $G/tools/actorart.py build "$p" --out $PROP; done
# the device-scale crop per scene: the box (game px of the 437x201 frame) around the room
crop() {
    case $1 in
    hall-closed-*)  echo 150,84,437,178 ;;
    hall-open-*)    echo 98,84,368,178 ;;
    chapel-open-*)  echo 140,78,358,178 ;;
    kitchen-open-*) echo 160,92,338,178 ;;
    courtyard-*)    echo 90,100,335,178 ;;
    esac
}
ALL="hall-closed-day hall-closed-night hall-open-day hall-open-night chapel-open-day chapel-open-night
kitchen-open-day kitchen-open-night courtyard-day courtyard-night"
for name in ${@:-$ALL}; do
    cool
    python3 -I -B $G/tools/scenemock/scene_castle.py $G "$name" $OUT/castle-$name.png
    python3 -I -B $G/tools/scenemock/zoom.py $OUT/castle-$name.png $OUT/castle-$name-x6.png "$(crop $name)"
    sleep 4
done
