#!/bin/bash
# Renders the M1b composition mocks into build/recraft/lh/preview/m1b-<name>.png (437x201, upscaled x3), one at a time
# with the heat rule (wait below 70 °C when the CPU reached 80 °C). Usage: run_m1b.sh [name ...]
# Look values as the renderer agent's preview: gain 3.0, lift 0.55, midHaze 0.36, midShare 0.7, fogBright 2.4, fogGlow 0.7,
# plus the M1b polish renderer additions: farCool 0.75 farWarm 0.3 midWarm 0.7 midCool 0.25 (aerial perspective at warm
# hours), cloud lighting defaults, fogScale 0.7 (thinner ground mist).
set -euo pipefail
cd "$(dirname "$0")/../../../.."
G=games/lanternhold
OUT=build/recraft/lh/preview
SMC=/Users/enaayla/Desktop/Spiele-Welle/tools/smcread
mkdir -p $OUT
shot() { # name focus tod
    case $1 in
    front-night)    echo "760 0.95" ;;
    castle-night)   echo "1360 0.95" ;;
    castle-dusk)    echo "1360 0.8" ;;
    courtyard-dusk) echo "1650 0.8" ;;
    valley-golden)  echo "2900 0.75" ;;
    valley-night)   echo "2900 0.95" ;;
    river-day)      echo "3720 0.5" ;;
    approach-day)   echo "1100 0.5" ;;
    approach-night) echo "1100 0.95" ;;
    beacon-day)     echo "470 0.5" ;;
    backgate-day)   echo "2330 0.5" ;;
    backgate-golden) echo "2330 0.75" ;;
    *) echo "unknown shot $1" >&2; return 1 ;;
    esac
}
cool() {
    local t; t=$("$SMC" | sed -n 's/.*TCXC=\([0-9]*\).*/\1/p')
    if [ -n "$t" ] && [ "$t" -ge 80 ]; then
        echo "CPU $t °C, waiting"; while t=$("$SMC" | sed -n 's/.*TCXC=\([0-9]*\).*/\1/p'); [ "$t" -ge 70 ]; do sleep 10; done
    fi
}
for name in ${@:-front-night castle-night castle-dusk courtyard-dusk valley-golden valley-night river-day approach-day approach-night beacon-day backgate-day backgate-golden}; do
    cool
    read -r f t <<< "$(shot "$name")"
    python3 -I $G/tools/scenemock/mock.py $G layout=m1b focus=$f tod=$t gain=3.0 lift=0.55 midHaze=0.36 midShare=0.7 \
        fogBright=2.4 fogGlow=0.7 farCool=0.75 farWarm=0.3 midWarm=0.7 midCool=0.25 fogScale=0.7 out=$OUT/m1b-$name.png
    sleep 3
done
