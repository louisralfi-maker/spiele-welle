#!/bin/bash
# Renders the buildings art lane's context scenes (scene_buildings.py) into build/recraft/lh/preview/bld-<name>.png
# (437x201, upscaled x3), one at a time with the heat rule (wait below 70 °C when the CPU reached 80 °C) and a pause
# between renders. Usage: run_buildings.sh [name ...]
set -euo pipefail
cd "$(dirname "$0")/../../../.."
G=games/lanternhold
OUT=build/recraft/lh/preview
SMC=/Users/enaayla/Desktop/Spiele-Welle/tools/smcread
mkdir -p $OUT
cool() {
    [ -x "$SMC" ] || return 0
    local t; t=$("$SMC" | sed -n 's/.*TCXC=\([0-9]*\).*/\1/p')
    if [ -n "$t" ] && [ "$t" -ge 80 ]; then
        echo "CPU $t °C, waiting"; while t=$("$SMC" | sed -n 's/.*TCXC=\([0-9]*\).*/\1/p'); [ "$t" -ge 70 ]; do sleep 10; done
    fi
}
for name in ${@:-line-night line-day gate-wood gate-iron gate-great gate-broken gate-iron-damaged gate-great-open-day beacon-night beacon-day
courtyard-dusk courtyard-grown town-golden town-night market-golden market-night}; do
    cool
    python3 -I -B $G/tools/scenemock/scene_buildings.py $G "$name" $OUT/bld-$name.png
    sleep 5
done
