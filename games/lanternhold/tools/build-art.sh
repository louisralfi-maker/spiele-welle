#!/bin/bash
# Rebuilds every milestone 1 sprite in Resources/Art from the Recraft raws in build/recraft/lh/ (git-ignored; see ART.md
# for the prompts) and the hand-set grids in tools/grids/. One image at a time with a pause between, and a wait while the
# CPU is at 80 °C or more (this old Mac's heat rule). Run from anywhere: bash games/lanternhold/tools/build-art.sh [name …]
set -euo pipefail
cd "$(dirname "$0")/../../.."
T=games/lanternhold/tools/pixelart.py
A=games/lanternhold/Resources/Art
G=games/lanternhold/tools/grids
R=build/recraft/lh
SMC=/Users/enaayla/Desktop/Spiele-Welle/tools/smcread

FAR=farDeep,far,moon,farPale,foam
ROCK=rockDeep,rockDark,rock,rockLight,rockPale,soilDark,soil,soilLight,leafDark,leaf,straw,strawLight
CAS=night0,night1,ink,stoneDark,stoneMid,stone,stoneLight,stonePale,woodDark,wood,woodLight,roofDeep,banner,roofLight,gold
TOWN=ink,night0,night1,woodDark,wood,woodLight,plaster,plasterDim,parchment,tile,tileLight,stoneDark,stoneMid,stone,stoneLight,stonePale,roofDeep,banner,roofLight,leafDark,leaf,meadow,leafLight,straw,strawLight,soilDark,soil,soilLight
COTTAGE=ink,night0,night1,woodDark,wood,woodLight,plaster,plasterDim,parchment,tile,tileLight,stoneDark,stoneMid,stone,stoneLight,stonePale,leafDark,leaf,meadow,strawLight,straw,soilDark,soil,soilLight
NAT=leafDark,leaf,meadow,leafLight,soilDark,soil,soilLight,straw,strawLight,rockDark,rock,woodDark
ST=ink,night0,stoneDark,stoneMid,stone,stoneLight,stonePale
GR=leafDark,leaf,meadow,soilDark,soil,soilLight,rockDeep,rockDark,rock,rockLight,stoneDark,stoneMid,stone,stoneLight
DOOR=night0,ink,woodDark,wood,woodLight

cool() { # wait below 70 °C when the CPU reached 80 °C
    [ -x "$SMC" ] || return 0
    local t; t=$("$SMC" | sed -n 's/.*TCXC=\([0-9]*\).*/\1/p')
    if [ -n "$t" ] && [ "$t" -ge 80 ]; then
        echo "CPU $t °C, waiting"; while t=$("$SMC" | sed -n 's/.*TCXC=\([0-9]*\).*/\1/p'); [ "$t" -ge 70 ]; do sleep 10; done
    fi
    sleep 1
}

build() { # name: one sprite
    case $1 in
    farMountain)   python3 $T convert $R/s1-far-1.png $A/farMountain.png --size 160x70 --box 16,100,916,376 --only $FAR ;;
    farPeak)       python3 $T convert $R/s1-far-1.png $A/farPeak.png --size 110x95 --box 972,40,1444,444 --only $FAR ;;
    gorgeCliff)    python3 $T convert $R/s2c-cliffs-1.png $A/gorgeCliff.png --size 70x210 --box 26,46,394,1246 --flood --tol 60 --only $ROCK --outline rockDeep ;;
    gorgeEndCliff) python3 $T convert $R/s2b-cliffs-1.png $A/gorgeEndCliff.png --size 120x220 --box 400,50,800,1240 --only $ROCK --fill rockDark:117,8,119,219 --outline rockDeep ;;
    waterfall)     python3 $T convert $R/s2-cliffs-1.png $A/waterfall.png --size 24x200 --box 266,30,340,1480 --only daySky,waterDeep,foam,farPale,moon ;;
    gatehouse)     python3 $T convert $R/s3-castle-1.png $A/gatehouse.png --size 120x100 --box 350,300,780,695 --only $CAS --outline ink --window 18,62 --window 96,62 --zone $DOOR@38,54,70,99@1.35 ;;
    castleTower)   python3 $T convert $R/s3-castle-1.png $A/castleTower.png --size 32x120 --box 55,20,345,695 --only $CAS --outline ink ;;
    castleWall)    python3 $T convert $R/s3-castle-1.png $A/castleWall.png --size 40x90 --box 826,300,948,695 --tile --only $CAS --window 17,58 --patch $G/castleWall-crenels.txt ;;
    backGate)      python3 $T convert $R/s3-castle-1.png $A/backGate.png --size 60x84 --box 1245,400,1518,695 --only $CAS --outline ink --zone $DOOR@21,48,38,83@1.35 ;;
    chapel)        python3 $T convert $R/s4-chapel-1.png $A/chapel.png --size 160x96 --box 130,75,715,668 --only $CAS,plaster,plasterDim,parchment --gain 1.15 --outline ink ;;
    hallInterior)  python3 $T convert $R/s5-hall-1.png $A/hallInterior.png --size 260x90 --box 210,0,1358,356 --only $CAS,strawLight --gain 1.1 --warm 22 --outline ink ;;
    kitchen)       python3 $T convert $R/s6-town-1.png $A/kitchen.png --size 120x80 --box 864,10,1148,296 --only $TOWN --outline ink ;;
    valleyHill)    python3 $T convert $R/s6-town-1.png $A/valleyHill.png --size 150x46 --box 800,565,1450,706 --only $NAT --outline leafDark --outline-skip-bottom ;;
    house)         python3 $T convert $R/s7-defence-1.png $A/house.png --size 64x46 --box 480,308,1080,632 --flood --only $COTTAGE --outline ink --zone ink,woodDark,tile,tileLight@0,4,63,24 --zone ink,stoneDark,stone,stoneLight,stonePale@44,0,52,12 ;;
    stoneWall)     python3 $T convert $R/s7-defence-1.png $A/stoneWall.png --size 36x52 --box 522,80,704,298 --flood --tol 60 --only $ST --fill clear:15,0,21,9 --fill stoneMid:1,49,34,50 --fill ink:35,10,35,51 --fill ink:0,49,0,51 --outline ink --outline-skip-bottom ;;
    ground)        python3 $T convert $R/s7-defence-1.png $A/ground.png --size 64x26 --box 560,673,745,737 --key none --min-count 1 --tile --only $GR ;;
    throne|hearth|well|lanternPost|field|palisade|ballista|brazier|torchPost)
                   python3 $T grid $G/$1.txt $A/$1.png ;;
    *) echo "unknown sprite $1" >&2; return 1 ;;
    esac
}

ALL="farMountain farPeak gorgeCliff gorgeEndCliff waterfall gatehouse castleTower castleWall backGate chapel hallInterior
throne hearth kitchen house valleyHill well lanternPost field palisade stoneWall ballista brazier torchPost ground"
for name in ${@:-$ALL}; do
    cool
    build "$name"
done
