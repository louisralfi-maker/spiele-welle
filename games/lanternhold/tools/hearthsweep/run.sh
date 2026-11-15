#!/bin/bash
# The front lane's hearth sweep (docs/lanes/front.md "front-2"), for GitHub's Mac runner only: a round step
#   sh bash tools/hearthsweep/run.sh [variants] [seeds=10]
# It compiles the simulation core, the hearth rule and its runs with -O for the Mac and writes T14 (the careless night
# at several sizes, the doubles with one and two steps a breach), the loss table and, with "variants", the broken
# night's cost around the chosen values to $CI_OUT/hearthsweep.txt. Never run it on the old Mac (CLAUDE.md "This Mac":
# no swiftc here).
set -u
cd "$(dirname "$0")/../.." || exit 1
OUT=${CI_OUT:-/tmp}
BIN="$(mktemp -d)/hearthsweep"
# frontsweep's core (tools/frontsweep/run.sh, its stand-in for the lord's identity included) plus the hearth's runs.
SRC="Core/DayClock.swift Core/SeededRandom.swift Core/LightField.swift Core/AmbientRamp.swift Core/AmbientRampLook2.swift
     Core/Balance.swift
     Core/Realm.swift Core/GameState.swift Core/Economy.swift Core/Build.swift Core/Battle.swift Core/DawnReport.swift
     Core/Sim.swift Core/Names.swift Core/Autoplay.swift Core/SaveGame.swift Core/TuningRun.swift
     Core/PetitionCourtState.swift Core/PetitionData.swift Core/PetitionEngine.swift Core/PetitionNight.swift
     Core/WorldLayout.swift Core/Camera.swift Core/PixelScale.swift
     Core/Front/FrontTuning.swift Core/Front/FrontState.swift Core/Front/FrontNight.swift Core/Front/PresentBot.swift
     Core/Front/FrontTuningRun.swift
     Core/Front/HearthTuning.swift Core/Front/HearthState.swift Core/Front/Hearth.swift Core/Front/HearthNames.swift
     Core/Front/DawnRing.swift Core/Front/GorgeTuning.swift Core/Front/GorgeState.swift Core/Front/Gorge.swift Core/Front/HearthBot.swift Core/Front/HearthTuningRun.swift
     tools/frontsweep/stubs.swift tools/hearthsweep/main.swift"
START=$(date +%s)
# shellcheck disable=SC2086
if ! xcrun swiftc -O -wmo -swift-version 5 -o "$BIN" $SRC >"$OUT/hearthsweep-build.txt" 2>&1; then
    echo "hearthsweep: the core did not compile"
    cat "$OUT/hearthsweep-build.txt"
    exit 1
fi
echo "hearthsweep: compiled in $(( $(date +%s) - START )) s" | tee "$OUT/hearthsweep.txt"
# Started in the game's folder, so the petition catalogue reads Resources/Petitions (no app bundle here).
"$BIN" ${1+"$@"} >>"$OUT/hearthsweep.txt" 2>&1
RC=$?
echo "hearthsweep: exit $RC after $(( $(date +%s) - START )) s" | tee -a "$OUT/hearthsweep.txt"
exit $RC
