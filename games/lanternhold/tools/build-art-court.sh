#!/bin/bash
# Rebuilds the M3 court art lane's sprites (SPRITES.md "M3", ART-court.md) in Resources/Art: the court members and
# guests and their glow strips from the hand-set part grids in tools/grids/court/ (tools/actorart.py), and the
# audience card's portraits (step 2): the composed portrait parts, rendered on one head template by
# tools/portraitart.py (portraitkit.py), and the story and guest portraits, rendered by portraitstory.py on the same
# template and frozen since the fix stage as hand-finished text grids in tools/grids/court/portraits/ (actorart.py
# builds them; `portraitart.py build <story id> --out DIR` renders a draft only); the castle's rooms and the court's props
# (step 3), painted by tools/roomart.py (roomscenes.py, the stamps in tools/grids/court/rooms/; hallFront is painted
# inside hallInterior's silhouette, so build-art.sh builds the scene sprites first); and the four houses' envoys
# (bodies and portraits, built like the guests') and the five houses' hall banners (tools/bannerart.py) of look 2's
# stage 7 (ART-look2.md 19.3), and the interface's circlet icon (tools/iconart.py, ART-look2.md 19.4; each id is three
# files: 1x, @2x, @3x). One sprite at a time with a pause between,
# and a wait while the CPU is at 80 °C or more (this old Mac's heat rule). A full run reproduces the committed files
# byte for byte. The proposals in tools/grids/court/proposals/ (the seated king) are not
# contract sprites: tools/scenemock/run_court.sh builds them into build/ for the mocks only. Run from anywhere:
#   bash games/lanternhold/tools/build-art-court.sh [name …]
set -euo pipefail
cd "$(dirname "$0")/../../.."
AA=games/lanternhold/tools/actorart.py
PA=games/lanternhold/tools/portraitart.py
RA=games/lanternhold/tools/roomart.py
BA=games/lanternhold/tools/bannerart.py
IA=games/lanternhold/tools/iconart.py
A=games/lanternhold/Resources/Art
G=games/lanternhold/tools/grids/court
SMC=/Users/enaayla/Desktop/Spiele-Welle/tools/smcread

cool() { # wait below 70 °C when the CPU reached 80 °C
    [ -x "$SMC" ] || return 0
    local t; t=$("$SMC" | sed -n 's/.*TCXC=\([0-9]*\).*/\1/p')
    if [ -n "$t" ] && [ "$t" -ge 80 ]; then
        echo "CPU $t °C, waiting"; while t=$("$SMC" | sed -n 's/.*TCXC=\([0-9]*\).*/\1/p'); [ "$t" -ge 70 ]; do sleep 10; done
    fi
    sleep 1
}

build() { # name: one sprite (and its glow strip)
    case $1 in
    odile|brannock|pip|hesper|tamsin|bram|marek|seren|serLudo|bard|envoy|herald|petitionerD|petitionerE|hildVarn|lorenzPell|ebbaCalder|orlaLorn)
        python3 -I -B $AA build $G/$1.txt --out $A ;;
    portraitClothes|portraitFace|portraitBeard|portraitHair|portraitHat)
        python3 -I -B $PA build "$1" --out $A
        sleep 4 ;;
    portrait*)
        python3 -I -B $AA build $G/portraits/$1.txt --out $A ;;
    banner*)
        python3 -I -B $BA build "$1" --out $A ;;
    circletIcon*)
        python3 -I -B $IA build "$1" --out $A ;;
    hallFront|chapelInterior|kitchenInterior|bench|taxLectern|marekCart|statue|speakerMark)
        python3 -I -B $RA build "$1" --out $A ;;
    *) echo "unknown sprite $1" >&2; return 1 ;;
    esac
}

ALL="odile brannock pip hesper tamsin bram marek seren serLudo bard envoy herald petitionerD petitionerE
portraitOdile portraitBrannock portraitPip portraitHesper portraitTamsin portraitBram portraitMarek portraitSeren
portraitSerLudo portraitBard portraitEnvoy portraitHerald portraitKing portraitLady
hildVarn lorenzPell ebbaCalder orlaLorn portraitHildVarn portraitLorenzPell portraitEbbaCalder portraitOrlaLorn
bannerVarn bannerBrine bannerOxmoor bannerCalder bannerLorn
circletIcon circletIconInk
portraitClothes portraitFace portraitBeard portraitHair portraitHat
hallFront chapelInterior kitchenInterior bench taxLectern marekCart statue speakerMark"
if [ "${1:-}" = "--list" ]; then echo $ALL; exit 0; fi  # the names, for build-art.sh
for name in ${@:-$ALL}; do
    cool
    build "$name"
done
