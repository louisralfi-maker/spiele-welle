#!/bin/bash
# Renders the actor and creature context scenes (scene_actors.py) through mock.py's extras hook into
# build/recraft/lh/preview/actors-<scene>.png (437x201, upscaled x3), one at a time with the heat rule (wait below
# 70 °C when the CPU reached 80 °C). Look values as run_m1b.sh plus the renderer's cap on reflected firelight
# (litCap 1.6, litNeutral 0.35: without it a lit actor's pale colours blow out to white). The king and the layout's scale-check actors are left
# out (king=off actors=off); every actor comes from the scene. Usage: run_actors.sh [scene ...]
set -euo pipefail
cd "$(dirname "$0")/../../../.."
G=games/lanternhold
OUT=build/recraft/lh/preview
SMC=/Users/enaayla/Desktop/Spiele-Welle/tools/smcread
mkdir -p $OUT/actors
cool() {
    local t; t=$("$SMC" | sed -n 's/.*TCXC=\([0-9]*\).*/\1/p')
    if [ -n "$t" ] && [ "$t" -ge 80 ]; then
        echo "CPU $t °C, waiting"; while t=$("$SMC" | sed -n 's/.*TCXC=\([0-9]*\).*/\1/p'); [ "$t" -ge 70 ]; do sleep 10; done
    fi
}
for name in ${@:-battle-night battle-day finale giant town-golden town-night}; do
    cool
    read -r f t <<< "$(python3 -I $G/tools/scenemock/scene_actors.py "$name" $OUT/actors/$name.json)"
    python3 -I $G/tools/scenemock/mock.py $G layout=m1b focus=$f tod=$t gain=3.0 lift=0.55 midHaze=0.36 midShare=0.7 \
        fogBright=2.4 fogGlow=0.7 farCool=0.75 farWarm=0.3 midWarm=0.7 midCool=0.25 fogScale=0.7 litCap=1.6 litNeutral=0.35 \
        extras=$OUT/actors/$name.json king=off actors=off out=$OUT/actors-$name.png
    sleep 3
done
