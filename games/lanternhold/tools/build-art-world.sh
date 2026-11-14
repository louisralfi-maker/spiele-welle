#!/bin/bash
# Rebuilds the world art of look 2 (ART-look2.md, "Stage 2: the world art") in Resources/Art: the Weltmauer with its
# cleft and the far castle, the shadow land's forest, the valley vista, the trees, the procedural plants, lanes and
# particles of tools/depthart.py, and since the world rebuild (ART-look2.md section 21) the Throat's steps, the cleft
# wall and the gate's granite (tools/cleftart.py) and the fog and the darkness bank (tools/fogart.py).
# Sources: the five Recraft paintings in build/recraft/lh/look2/world/ (git-ignored; prompts in ART-look2.md),
# converted by tools/pixelart.py (--match new) and assembled by tools/worldart.py. One image at a time with a pause
# between, and a wait while the CPU is at 80 °C or more (this old Mac's heat rule). A full run reproduces the
# committed files byte for byte. Run from anywhere:
#   bash games/lanternhold/tools/build-art-world.sh [name …]
set -euo pipefail
cd "$(dirname "$0")/../../.."
T=games/lanternhold/tools/pixelart.py
WA=games/lanternhold/tools/worldart.py
DA=games/lanternhold/tools/depthart.py
CA=games/lanternhold/tools/castleart.py
A=games/lanternhold/Resources/Art
W=build/recraft/lh/look2/world
P=$W/parts
SMC=/Users/enaayla/Desktop/Spiele-Welle/tools/smcread
mkdir -p $P

K='#FC0CBC'   # the paintings' magenta background (never --key auto: it once took the rock for the key)
FARW=farDeep,far,mistDark,moon,mist,farPale,mistLight,foam
ROCKW=rockDeep,rockDark,rock,rockLight,rockPale,soilDark,soil
GRANITE=rockDeep,rockDark,rock,rockLight,rockPale   # the cleft's flanks beside the castle: no soil darks (at dusk they went black)
FIRW=fir0,fir1,fir2,fir3,fir4
WOODS=fir0,fir1,fir2,fir3,fir4,rockDeep,rockDark,rock,rockLight,rockPale,stoneDark,stoneMid,stone,stoneLight,moorDark,moor,soilDark,soil,woodDark
CROWNS=fir0,fir1,fir2,fir3,fir4,rockLight
LEAFW=leafDeep,leafDark,leaf,meadow,leafLight,woodDark,wood,rockDeep,rockDark,rock
DEADW=rockDeep,rockDark,rock,rockLight
VISTA=fir0,fir1,fir2,fir3,fir4,leafDark,leaf,farDeep,far,mistDark,moon,mist,farPale,mistLight,foam
# the procedural plants, lanes, fog and particles of look 2 (tools/depthart.py), now game art
PLANTS="d2FgFerns d2FgMeadow d2FgReeds d2BushA d2BushB d2TreeBelt d2FirBeltFar laneMoorA laneMoorB laneMoorC laneMoorD laneCobbleA laneCobbleB laneCobbleC laneCobbleD laneEarthA laneEarthB laneEarthC laneEarthD laneScreeA laneScreeB laneScreeC laneScreeD d2LaneEnd d2Smoke d2Fireflies d2Sparks"
# World rebuild, step world-1 (14.11.2026): the hour's fog (tools/fogart.py, it replaced depthart's three banks), the
# darkness bank's sheets, the rock of the Throat and the cleft and the gate's granite (tools/cleftart.py, rockfield.py)
FOG="d2FogBank d2MistBand d2FogLow bankSheetA bankSheetB bankSheetC"
ROCK="throatStepA throatStepB throatStepC cleftWallA cleftWallB cleftWallC cleftShaft gateRockL gateRockR"
R=games/lanternhold/tools/retired-art

cool() { # wait below 70 °C when the CPU reached 80 °C
    [ -x "$SMC" ] || return 0
    local t; t=$("$SMC" | sed -n 's/.*TCXC=\([0-9]*\).*/\1/p')
    if [ -n "$t" ] && [ "$t" -ge 80 ]; then
        echo "CPU $t °C, waiting"; while t=$("$SMC" | sed -n 's/.*TCXC=\([0-9]*\).*/\1/p'); [ "$t" -ge 70 ]; do sleep 10; done
    fi
    sleep 1
}
px() { python3 -I -B $T "$@"; }
wa() { python3 -I -B $WA "$@"; }
tree() { # name box size ramp [more options]: one tree of the sheet
    local n=$1 box=$2 size=$3 ramp=$4; shift 4
    px convert $W/trees-1.png $P/$n.png --box $box --size $size --key $K --only $ramp --match new "$@"; cool
    wa main $P/$n.png $A/$n.png
}
fir() { tree $1 $2 $3 $FIRW --warm 28 --gain 1.25 --zone fir0,fir1@$4; }   # the painting's firs are navy: warmed onto the fir ramp
cliff() { # name old-sprite box [tuft boxes]: the painting's granite in an old cliff sprite's silhouette
    local size; size=$(px info $A/$2.png | sed -n '1s/.*: \([0-9]*x[0-9]*\),.*/\1/p')
    px convert $W/gorge-1.png $P/$1.png --box $3 --size $size --key none --only $GRANITE --match new --gamma 0.7; cool
    if [ -n "${4:-}" ]; then wa rockover $P/$1.png $4; fi
    wa retex $A/$2.png $P/$1.png $A/$1.png
}

build() { # name: one sprite (or one group of small ones)
    case $1 in
    weltmauer)   # the wall with its two views of the cleft, the patch that hides the valley's view, the far castles' glow, the slots' light
        px convert $W/wall-1.png $P/wallA.png --size 384x182 --key $K --only $FARW --match new; cool
        px convert $W/wall-1.png $P/wallB.png --size 420x190 --box 0,0,1400,768 --key $K --only $FARW --match new; cool
        wa wall $P/wallA.png $P/wallB.png $A/castleFront.png $A/keepTop.png $A/castleBackGate.png $A
        # world rebuild: no far castle in the first slot (the shadow land's view), and the wall sinks into the fog
        # toward the west
        python3 -I -B games/lanternhold/tools/cleftart.py noslot $A/weltmauer.png; cool
        python3 -I -B games/lanternhold/tools/cleftart.py mistleft $A/weltmauer.png ;;
    castleTiers) # the castle's tiers 2 and 3 with their building states (the art pass; from castleFront, keepTop, castleBackGate and the slots' glow)
        python3 -I -B $CA tiers $A ;;
    gorgeRock)   # the gorge's wall of the look-2 port: since the world rebuild (14.11.2026) not in the game, kept in
                 # tools/retired-art as the granite of the old walls (throatart.py); gorgeCrags with it
        px convert $W/gorge-1.png $P/gorge.png --size 448x211 --box 0,48,1536,768 --key none --only $GRANITE --match new --gamma 0.7; cool
        wa rockover $P/gorge.png 277,64,292,74 298,64,308,74 311,64,325,74 256,116,269,127   # the painting's four grass tufts (they read as hands)
        wa gorge $P/gorge.png $R/gorgeRock.png $R/gorgeCrags.png ;;
    oldWall1|oldWall2|oldWall3|palisadeAnchor|stoneWallAnchor|bastionAnchor)   # stage 7: the old walls in the Throat, the tiers' anchors (granite from gorgeRock.png)
        python3 -I -B games/lanternhold/tools/throatart.py build $1 --out $A ;;
    gloomFogBack|gloomFogMid|gloomFogFront|gloomWisp|gloomFogEyes)   # stage 7: the Gloom's fog (strips, the shred, the eyes)
        python3 -I -B games/lanternhold/tools/gloomart.py build $1 --out $A ;;
    # cleftFace, cleftFaceEnd, cleftFlank, cleftFlankB, cleftThroat: retired by the world rebuild (REVIEW-look-2.md
    # B6, H1); the files lie in tools/retired-art, their recipe in git before 14.11.2026
    throatStepA|throatStepB|throatStepC|cleftWallA|cleftWallB|cleftWallC|cleftShaft|gateRockL|gateRockR)
        python3 -I -B games/lanternhold/tools/cleftart.py build $1 --out $A ;;
    d2FogBank|d2MistBand|d2FogLow|bankSheetA|bankSheetB|bankSheetC)
        python3 -I -B games/lanternhold/tools/fogart.py build $1 --out $A ;;
    shadowForest)  # the shadow land's forest edge on the mid plane: firs, two lantern statues, a ruin, a tower stump
        px convert $W/forest-1.png $P/forestLow.png --size 224x104 --key $K --only $WOODS --zone fir0,fir1,fir2,fir3,fir4,rock,rockLight@0,0,224,66 --match new; cool
        px convert $W/forest-1.png $P/forestTop.png --size 224x104 --key $K --only $CROWNS --warm 28 --gain 1.25 --match new; cool
        px compose $P/forest.png --size 224x104 --layer $P/forestLow.png@0,0 --layer $P/forestTop.png@0,0@box=0,0,224,68
        wa taper $P/forest.png $A/shadowForest.png 72 ;;
    valleyVista)   # the valley's painted distance: three layers of fir slopes in haze, a far river
        px convert $W/valley-1.png $P/vista.png --size 448x160 --key $K --only $VISTA --match new; cool
        wa slope $P/vista.png $A/valleyVista.png ;;
    firA) fir firA 12,24,158,672 29x130 0,117,29,130 ;;   # (the last box: the trunk's foot stays dark)
    firB) fir firB 158,24,300,672 30x118 0,105,30,118 ;;
    firC) fir firC 284,176,440,704 34x106 0,84,34,106 ;;
    firD) fir firD 440,252,568,672 27x84 0,75,27,84 ;;
    deadTreeA) tree deadTreeA 572,328,652,672 17x72 $DEADW ;;
    deadTreeB) tree deadTreeB 668,336,748,672 17x70 $DEADW ;;
    linden) tree linden 760,292,976,672 52x92 $LEAFW ;;
    poplar) tree poplar 992,28,1068,672 14x116 $LEAFW ;;
    appleTree) tree appleTree 1080,432,1292,672 42x48 $LEAFW ;;
    willow) tree willow 1308,396,1516,672 52x68 $LEAFW ;;
    # stage 6 (section 18): two more paintings of every town tree, painted by tools/treeart.py on the first one's canvas
    lindenB|lindenC|poplarB|poplarC|appleTreeB|appleTreeC|willowB|willowC)
        python3 -I -B games/lanternhold/tools/treeart.py build $1 --out $A ;;
    plants) python3 -I -B $DA $A $PLANTS ;;
    *) echo "unknown sprite $1" >&2; return 1 ;;
    esac
}

ALL="weltmauer castleTiers gorgeRock oldWall1 oldWall2 oldWall3 palisadeAnchor stoneWallAnchor bastionAnchor gloomFogBack gloomFogMid gloomFogFront gloomWisp gloomFogEyes $ROCK shadowForest valleyVista firA firB firC firD deadTreeA deadTreeB linden poplar appleTree willow lindenB lindenC poplarB poplarC appleTreeB appleTreeC willowB willowC plants $FOG"
if [ "${1:-}" = "--list" ]; then echo $ALL; exit 0; fi  # the names, for build-art.sh
for name in ${@:-$ALL}; do cool; build "$name"; done
