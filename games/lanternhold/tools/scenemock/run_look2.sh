#!/bin/bash
# Look 2, stage 1 (ART-look2.md "The mocks"): paints the depth stand-ins (tools/depthart.py), then renders the six
# direction scenes (scene_look2.py) in the old look (the art of f35272a with the renderer's values of today) and in the
# new look (Resources/Art with mock.py look=2), the same frame each, one render at a time with the heat rule (wait below
# 70 °C when the CPU reached 80 °C), into build/recraft/lh/preview/look2/<scene>-old.png and -new.png (437x201,
# upscaled x3), then the two 2x3 contact sheets sheet-old.png and sheet-new.png. Usage: run_look2.sh [scene ...];
# LOOKS="new" renders the new look only (the old frames do not change: look=1 renders byte for byte as before).
set -euo pipefail
cd "$(dirname "$0")/../../../.."
G=games/lanternhold
OUT=build/recraft/lh/preview/look2
OLDART=build/recraft/lh/look2/art-old     # the art before look 2, taken from git if missing
DEPTH=build/recraft/lh/look2/depth        # the depth stand-ins
SMC=/Users/enaayla/Desktop/Spiele-Welle/tools/smcread
mkdir -p $OUT $DEPTH
if [ ! -d $OLDART ]; then
    mkdir -p $OLDART
    for f in $(git ls-tree --name-only f35272a $G/Resources/Art/); do git show "f35272a:$f" > "$OLDART/$(basename "$f")"; done
fi
cool() {
    local t; t=$("$SMC" | sed -n 's/.*TCXC=\([0-9]*\).*/\1/p')
    if [ -n "$t" ] && [ "$t" -ge 80 ]; then
        echo "CPU $t °C, waiting"; while t=$("$SMC" | sed -n 's/.*TCXC=\([0-9]*\).*/\1/p'); [ "$t" -ge 70 ]; do sleep 10; done
    fi
}
python3 -I -B $G/tools/depthart.py $DEPTH
ALL="front-night castle-dusk court-dusk square-dusk town-noon river-golden"
LOOKS=${LOOKS:-old new}
for s in ${@:-$ALL}; do
    if [[ " $LOOKS " == *" old "* ]]; then
        cool
        python3 -I -B $G/tools/scenemock/scene_look2.py $G "$s" 1 $OUT/"$s"-old.png art=$OLDART
        sleep 3
    fi
    if [[ " $LOOKS " == *" new "* ]]; then
        cool
        python3 -I -B $G/tools/scenemock/scene_look2.py $G "$s" 2 $OUT/"$s"-new.png depth=$DEPTH
        sleep 3
    fi
done
for look in old new; do
    frames=""; for s in $ALL; do frames="$frames $OUT/$s-$look.png"; done
    if ls $frames > /dev/null 2>&1; then python3 -I -B $G/tools/scenemock/sheet_look2.py $OUT/sheet-$look.png $frames; fi
done
