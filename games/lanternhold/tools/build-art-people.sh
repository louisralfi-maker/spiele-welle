#!/bin/bash
# Rebuilds the cast of the people lane (docs/PEOPLE.md, docs/SPRITES-people.md) in Resources/Art: the three townsfolk
# repainted as worn working people and their seated forms (tools/grids/actors/citizen*.txt) and the new bodies
# (tools/grids/people/*.txt), each from its hand-set part grid through tools/actorart.py. No generated image is
# involved. Each body's cloth states follow it (tools/peoplestates.py: <id>Village.png and <id>Town.png for the working
# people and their seated forms, <id>Town.png for the children; docs/PEOPLE.md section 7). One sprite at a time with a
# pause between; on this old Mac run it through the director's art lock. A full run reproduces the committed files
# byte for byte. Run from anywhere:
#   bash games/lanternhold/tools/build-art-people.sh [name …]
set -euo pipefail
cd "$(dirname "$0")/../../.."
AA=games/lanternhold/tools/actorart.py
PS=games/lanternhold/tools/peoplestates.py
A=games/lanternhold/Resources/Art
GA=games/lanternhold/tools/grids/actors
GP=games/lanternhold/tools/grids/people

build() { # name: one sprite and its cloth states
    case $1 in
    citizen|citizenB|citizenC|citizenSeated|citizenBSeated|citizenCSeated)
        python3 -I -B $AA build $GA/$1.txt --out $A
        python3 -I -B $PS build $GA/$1.txt --out $A --state all ;;
    farmerHoe|farmerScythe|elder|washerwoman|labourer)
        python3 -I -B $AA build $GP/$1.txt --out $A
        python3 -I -B $PS build $GP/$1.txt --out $A --state all ;;
    childA|childB|childC)
        python3 -I -B $AA build $GP/$1.txt --out $A
        python3 -I -B $PS build $GP/$1.txt --out $A --state town ;;
    nobleLord|nobleLady|footman)
        python3 -I -B $AA build $GP/$1.txt --out $A ;;
    *) echo "unknown sprite $1" >&2; return 1 ;;
    esac
}

ALL="citizen citizenB citizenC citizenSeated citizenBSeated citizenCSeated farmerHoe farmerScythe elder washerwoman
labourer childA childB childC nobleLord nobleLady footman"
if [ "${1:-}" = "--list" ]; then echo $ALL; exit 0; fi
for name in ${@:-$ALL}; do
    build "$name"
    sleep 1
done
