#!/bin/bash
# Look 2, stage 3 (ART-look2.md "Stage 3: the creatures"): renders the creatures' context scenes in look 2, each with
# the creatures of look 1 (the art of 311831c, taken from git if missing) and with the creatures of Resources/Art, the
# same frame and the same world: battle-night, battle-day, finale and giant of scene_actors.py and front-night of
# scene_look2.py, into build/recraft/lh/preview/creatures/<scene>-old.png and -new.png (437x201, upscaled x3). One
# render at a time with the heat rule (wait below 70 °C when the CPU reached 80 °C).
# Usage: run_creatures.sh [scene ...]
set -euo pipefail
cd "$(dirname "$0")/../../../.."
G=games/lanternhold
OUT=build/recraft/lh/preview/creatures
OLD=build/recraft/lh/look2/creatures-old   # only the sixteen creature strips of look 1
DEPTH=build/recraft/lh/look2/depth
SMC=/Users/enaayla/Desktop/Spiele-Welle/tools/smcread
mkdir -p $OUT
if [ ! -d $OLD ]; then
    mkdir -p $OLD
    for c in sootling sootlingB shadehound sootCrow ashBrute gloomweaver ashGiant lightlessKing; do
        for f in $c.png ${c}Glow.png; do git show "311831c:$G/Resources/Art/$f" > $OLD/$f; done
    done
fi
[ -d $DEPTH ] || python3 -I -B $G/tools/depthart.py $DEPTH
cool() {
    local t; t=$("$SMC" | sed -n 's/.*TCXC=\([0-9]*\).*/\1/p')
    if [ -n "$t" ] && [ "$t" -ge 80 ]; then
        echo "CPU $t °C, waiting"; while t=$("$SMC" | sed -n 's/.*TCXC=\([0-9]*\).*/\1/p'); [ "$t" -ge 70 ]; do sleep 10; done
    fi
}
one() { # scene, tag, art dirs
    if [ "$1" = front-night ]; then
        python3 -I -B $G/tools/scenemock/scene_look2.py $G front-night 2 $OUT/$1-$2.png depth=$DEPTH art=$3
    else
        read -r f t <<< "$(python3 -I -B $G/tools/scenemock/scene_actors.py "$1" $OUT/$1.json)"
        python3 -I -B $G/tools/scenemock/mock.py $G layout=m1b focus=$f tod=$t look=2 depth=$DEPTH art=$3 \
            extras=$OUT/$1.json king=off actors=off out=$OUT/$1-$2.png
    fi
}
for s in ${@:-battle-night battle-day finale giant front-night}; do
    for tag in ${TAGS:-old new}; do
        cool
        if [ $tag = old ]; then one "$s" old $OLD,$G/Resources/Art; else one "$s" new $G/Resources/Art; fi
        sleep 3
    done
done
