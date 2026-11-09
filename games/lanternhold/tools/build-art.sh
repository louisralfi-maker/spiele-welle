#!/bin/bash
# Rebuilds every milestone 1 and M1b sprite in Resources/Art from the Recraft raws in build/recraft/lh/ (git-ignored; see ART.md
# for the prompts) and the hand-set grids in tools/grids/. One image at a time with a pause between, and a wait while the
# CPU is at 80 °C or more (this old Mac's heat rule). Run from anywhere: bash games/lanternhold/tools/build-art.sh [name …]
set -euo pipefail
cd "$(dirname "$0")/../../.."
T=games/lanternhold/tools/pixelart.py
A=games/lanternhold/Resources/Art
G=games/lanternhold/tools/grids
R=build/recraft/lh
M=build/recraft/lh/m1b         # the M1b paintings (ART.md "M1b")
PT=build/recraft/lh/m1b/parts  # intermediate parts of composed sprites
PROC=games/lanternhold/tools/procart.py
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
ROCKG=rockDeep,rockDark,rock,rockLight,rockPale,soilDark,soil,soilLight,leafDark,leaf
STONE=night1,ink,stoneDark,stoneMid,stone,stoneLight
VMID=leafDark,leaf,meadow,leafLight,straw,strawLight,soilDark,daySky,foam,plaster,roofDeep

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
    house)         python3 $T convert $R/s7-defence-1.png $A/house.png --size 64x46 --box 480,308,1080,632 --flood --only $COTTAGE --outline ink --zone ink,woodDark,tile,tileLight@0,4,63,24 --zone ink,stoneDark,stone,stoneLight,stonePale@44,0,52,12 --patch $G/house-front.txt@2,29
                   python3 $T post $A/house.png $A/house.png --remap parchment:plaster ;;  # M1b polish: clean half-timbering
    stoneWall)     python3 $T convert $R/s7-defence-1.png $A/stoneWall.png --size 36x52 --box 522,80,704,298 --flood --tol 60 --only $ST --fill clear:15,0,21,9 --fill stoneMid:1,49,34,50 --fill ink:35,10,35,51 --fill ink:0,49,0,51 --outline ink --outline-skip-bottom ;;
    ground)        python3 $T convert $R/s7-defence-1.png $A/ground.png --size 64x26 --box 560,673,745,737 --key none --min-count 1 --tile --only $GR ;;
    # --- M1b: the gorge, the castle that seals it, the open valley ---
    gorgeWall|gorgeWallA|gorgeWallB|gorgeWallC) # one panorama, seamless, cut into A-B-C
                   mkdir -p $PT
                   # M1b polish: gorgewall-b (horizontal strata and ledges; gorgewall-a's even vertical fractures and dead
                   # trees read as a night forest); the key is given (the pale rock is the commonest border colour)
                   python3 $T convert $M/gorgewall-b-1.png $PT/gorgeWall.png --size 576x190 --box 0,150,1536,740 --key '#FC1494' --tile --only $ROCKG --sat 1.4 --warm 14 --gain 0.85
                   python3 $T split $PT/gorgeWall.png $A/gorgeWallA.png $A/gorgeWallB.png $A/gorgeWallC.png ;;
    gorgeWallHigh) # the high rock, its left edge carried on from gorgeWallA's first columns (what follows gorgeWallC)
                   mkdir -p $PT
                   python3 $T convert $M/rocks-a-1.png $PT/gwh-rock.png --size 180x240 --box 16,44,540,748 --only $ROCKG,meadow --sat 1.3
                   python3 $T compose $A/gorgeWallHigh.png --size 192x240 --layer $A/gorgeWallA.png@0,50@box=0,0,40,190 --layer $PT/gwh-rock.png@12,0 ;;
    cliffFlank)    # all rock now (the masonry strip and the long highlight read as a tree trunk): the left cliff of rocks-a
                   python3 $T convert $M/rocks-a-1.png $A/cliffFlank.png --size 80x240 --box 60,44,330,748 --only $ROCKG --sat 1.3 ;;
    gorgeMouth)    # M1b polish: the slope (x 38-119, rows 150-224) repainted by procart slopebands
                   mkdir -p $PT
                   python3 $T convert $M/rocks-a-1.png $PT/gorgeMouth-raw.png --size 120x230 --box 1000,104,1520,748 --only $ROCKG,meadow,leafLight --sat 1.3
                   python3 $PROC slopebands $PT/gorgeMouth-raw.png $A/gorgeMouth.png --rect 38,150,119,224 ;;
    wardenStatue)  # M1b polish: carved in cool grey stone (the rock ramp remapped to the stone ramp) so it separates from the
                   # ochre gorge, in a dark arched niche (rockDeep, only behind the figure); the bowl reads as a bowl (lit
                   # rim, stone-dark hollow, underside) instead of a night0 bar across the chin; moss specks under 3 px merged
                   mkdir -p $PT
                   python3 $T convert $M/statue-a-1.png $PT/statue-raw.png --size 96x200 --box 0,20,768,1536 --only $ROCKG --sat 1.3
                   python3 $T post $PT/statue-raw.png $A/wardenStatue.png --remap rockPale:stoneLight,rockLight:stone,rock:stoneMid,rockDark:stoneMid,rockDeep:stoneDark,soilDark:stoneDark,soilLight:stone,soil:stoneMid --clusters 3 --fill stonePale:38,42,58,43 --fill stoneDark:37,44,59,45 --fill stoneMid:41,46,55,46 --fill-holes rockDeep:34,6,62,20 --fill-holes rockDeep:24,20,72,34 --fill-holes rockDeep:16,34,80,199 ;;
    castleFront)   # towers from castlefront-b (the left one, mirrored for the right), gatehouse from castlefront-a
                   mkdir -p $PT
                   python3 $T convert $M/castlefront-b-1.png $PT/cf-tower.png --size 58x236 --box 80,80,315,1072 --gain 1.1 --only $CAS,leafDark,leaf --outline ink --outline-skip-bottom
                   python3 $T convert $M/castlefront-a-1.png $PT/cf-gate.png --size 132x156 --box 295,420,735,895 --gain 0.86 --only $CAS --fill clear:0,0,29,28 --fill clear:102,0,131,28 --outline ink --outline-skip-bottom
                   # M1b polish: the painted shadow band on the towers' right side (night1, cols 42-53) lifted to stoneMid/stoneDark
                   # (albedo; the castle is one value step above the rock at night), the speckled left highlight
                   # cleaned into one stoneLight column, the right edge light (col 54) made a solid stonePale rim for the
                   # moon. Both towers lit from the same side: the right one is not mirrored but moved 9 px left (its
                   # transparent margin is on the left), with two arrow slits moved and a broken merlon.
                   python3 $T post $PT/cf-tower.png $PT/cf-tower-l.png --remap stonePale:stone,stoneLight:stone@11,40,16,235 --remap night1:stoneMid@42,40,46,235 --remap night1:stoneDark@47,40,53,235 --fill stoneLight:10,40,10,235 --fill stonePale:54,40,54,235
                   python3 $T post $PT/cf-tower-l.png $PT/cf-tower-r0.png --fill stone:28,68,35,85 --fill stone:28,123,35,140 --fill clear:36,0,43,4
                   python3 $T compose $PT/cf-tower-r.png --size 58x236 --layer $PT/cf-tower-r0.png@0,0 --layer $PT/cf-tower-l.png@28,62@box=28,68,36,86 --layer $PT/cf-tower-l.png@28,130@box=28,123,36,141
                   # Polish after the art review: the towers rounded (a lit band left of centre, the side turning away
                   # one step darker, soft checker terminators) and shortened by 64 rows (shaft rows 40-103 cut out;
                   # the stub of the slit under the cut filled), so their corbelled crowns stand on screen at y 132-172
                   # instead of above the top edge
                   for side in l r; do
                       python3 $PROC cylinder $PT/cf-tower-$side.png $PT/cf-tower-${side}c.png --rect 11,40,53,235 --bands 18-26:+1,34-41:-1
                       python3 $PROC cylinder $PT/cf-tower-${side}c.png $PT/cf-tower-${side}c.png --rect 2,0,56,39 --bands 12-22:+1
                       python3 $T compose $PT/cf-tower-${side}s.png --size 58x236 --layer $PT/cf-tower-${side}c.png@0,64@box=0,0,58,40 --layer $PT/cf-tower-${side}c.png@0,104@box=0,104,58,236
                       python3 $T post $PT/cf-tower-${side}s.png $PT/cf-tower-${side}s.png --fill stone:28,104,35,112
                   done
                   python3 $T compose $A/castleFront.png --size 240x236 --layer $PT/cf-gate.png@54,80 --layer $PT/cf-tower-ls.png@0,0 --layer $PT/cf-tower-rs.png@173,0 ;;
    castleKeep)    # front elevation (keepgate-b left, M1b polish): flat crenellated top like the front's towers; the painting's
                   # shaded left third lifted with a zone (albedo is evenly lit); specks under 2 px merged
                   mkdir -p $PT
                   python3 $T convert $M/keepgate-b-1.png $PT/keep-raw.png --size 150x250 --box 92,20,532,724 --gain 0.72 --only $CAS --zone night1,ink,stoneDark,stoneMid,stone,stoneLight,stonePale,banner,roofDeep@0,30,52,249@1.7 --outline ink --outline-skip-bottom
                   python3 $T post $PT/keep-raw.png $A/castleKeep.png --clusters 2 ;;
    castleBackGate) # front elevation (keepgate-b right, M1b polish): square towers with flat crenellated tops, one roof
                   # language with the front and the keep; wider than tall, so it fills 200x172 under a 28 px top margin;
                   # the see-through passage between the open doors becomes night1
                   mkdir -p $PT
                   python3 $T convert $M/keepgate-b-1.png $PT/backgate-raw.png --size 200x200 --box 740,212,1436,728 --pad 0,28,0,0 --gain 0.72 --only $CAS --outline ink --outline-skip-bottom
                   python3 $T post $PT/backgate-raw.png $A/castleBackGate.png --clusters 2 --fill-holes night1:80,105,120,199 ;;
    valleyFar|valleyFarA|valleyFarB|valleyFarC)
                   mkdir -p $PT
                   python3 $T convert $M/valleyfar-a-1.png $PT/valleyFar.png --size 576x90 --box 210,280,1450,560 --tile --only $FAR
                   python3 $T split $PT/valleyFar.png $A/valleyFarA.png $A/valleyFarB.png $A/valleyFarC.png ;;
    valleyMid|valleyMidA|valleyMidB|valleyMidC)
                   mkdir -p $PT
                   python3 $T convert $M/valleymid-a-1.png $PT/valleyMid.png --size 576x110 --box 0,300,1536,545 --key '#EC149C' --tile --warm 12 --only $VMID
                   # M1b polish: the river reads as water under warm light (deep blue body, one pale highlight row on top)
                   python3 $T post $PT/valleyMid.png $PT/valleyMid.png --remap daySky:waterDeep,foam:daySky --top-edge foam:waterDeep,daySky
                   python3 $T split $PT/valleyMid.png $A/valleyMidA.png $A/valleyMidB.png $A/valleyMidC.png ;;
    windmill)      python3 $T convert $M/props-a-1.png $A/windmill.png --size 40x60 --box 844,20,1308,492 --only stoneDark,stoneMid,stone,stoneLight,woodDark,wood,woodLight,soil,leafDark,leaf,meadow,ink --outline ink --outline-skip-bottom ;;
    beaconRuin)    # the painted fire cage floated above the stump: set down into the broken top
                   mkdir -p $PT
                   python3 $T convert $M/props-a-1.png $PT/beacon-raw.png --size 64x130 --box 360,18,620,492 --only $CAS,leafDark,leaf,meadow --outline ink --outline-skip-bottom
                   python3 $T compose $A/beaconRuin.png --size 64x130 --layer $PT/beacon-raw.png@0,29@box=0,29,64,130 --layer $PT/beacon-raw.png@0,22@box=0,22,19,29 --layer $PT/beacon-raw.png@42,22@box=42,22,64,29 --layer $PT/beacon-raw.png@17,5@box=17,0,45,29 ;;
    riverEnd)      # procedural bank, water and bridge piers (M1b polish: water up to 4 rows under the ground line, no
                   # dither, stepped voussoir stubs); the painted reeds and cattails on top
                   mkdir -p $PT
                   python3 $PROC riverbase $PT/river-base.png
                   python3 $T convert $M/props-a-1.png $PT/reeds.png --size 64x40 --box 1150,515,1516,700 --only leafDark,leaf,meadow,woodDark,wood,soilDark
                   python3 $T compose $A/riverEnd.png --size 220x64 --layer $PT/river-base.png@0,0 --layer $PT/reeds.png@156,22 --layer $PT/reeds.png@46,22@box=0,10,22,40 ;;
    clouds|cloudA|cloudB|cloudC) # sky-plane cloud bands (M1b polish), keyed from the painting's green; the painted
                   # black ground line under each band is cut off by the boxes
                   CL=foam,parchment,farPale,moon
                   python3 $T convert $M/clouds-a-1.png $A/cloudA.png --size 280x40 --box 184,68,1372,234 --key '#04BC44' --only $CL
                   python3 $T convert $M/clouds-a-1.png $A/cloudB.png --size 240x42 --box 264,288,1288,460 --key '#04BC44' --only $CL
                   python3 $T convert $M/clouds-a-1.png $A/cloudC.png --size 286x36 --box 160,534,1380,681 --key '#04BC44' --only $CL ;;
    riverFarBank)  python3 $PROC farbank $A/riverFarBank.png ;;  # M1b polish: the far shore on the mid plane
    fgRockA)       python3 $PROC fgrock $A/fgRockA.png --style a ;;
    fgRockB)       python3 $PROC fgrock $A/fgRockB.png --style b ;;
    fgRockC)       python3 $PROC fgrock $A/fgRockC.png --style c ;;
    fgOverhangA)   python3 $PROC overhang $A/fgOverhangA.png --style a ;;
    fgOverhangB)   python3 $PROC overhang $A/fgOverhangB.png --style b ;;
    throne|hearth|well|lanternPost|field|palisade|ballista|brazier|torchPost)
                   python3 $T grid $G/$1.txt $A/$1.png ;;
    *) echo "unknown sprite $1" >&2; return 1 ;;
    esac
}

ALL="farMountain farPeak gorgeCliff gorgeEndCliff waterfall gatehouse castleTower castleWall backGate chapel hallInterior
throne hearth kitchen house valleyHill well lanternPost field palisade stoneWall ballista brazier torchPost ground
gorgeWall gorgeWallHigh cliffFlank gorgeMouth wardenStatue castleFront castleKeep castleBackGate valleyFar valleyMid windmill
beaconRuin riverEnd riverFarBank clouds fgRockA fgRockB fgRockC fgOverhangA fgOverhangB"
for name in ${@:-$ALL}; do
    cool
    build "$name"
done
