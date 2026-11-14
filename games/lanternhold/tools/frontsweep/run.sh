#!/bin/bash
# The front lane's sweep (docs/lanes/front.md "front-1"), for GitHub's Mac runner only: a round step
#   sh bash tools/frontsweep/run.sh [probe] [variants] [stresses=1,1.5,2] [seeds=10]
# It compiles the simulation core and the front rule with -O for the Mac and writes T13 for the standard balance, the
# night budgets probe and the rule's variants to $CI_OUT/frontsweep.txt. Never run it on the old Mac (CLAUDE.md "This
# Mac": no swiftc here).
set -u
cd "$(dirname "$0")/../.." || exit 1
OUT=${CI_OUT:-/tmp}
BIN="$(mktemp -d)/frontsweep"
# simtune's core (tools/simtune/run.sh; since the look-2 pass it also needs AmbientRampLook2, and a stand-in for the
# lord's identity) plus the front rule, its bot and its runs (not FrontText: it needs the bundle).
SRC="Core/DayClock.swift Core/SeededRandom.swift Core/LightField.swift Core/AmbientRamp.swift Core/AmbientRampLook2.swift
     Core/Balance.swift
     Core/Realm.swift Core/GameState.swift Core/Economy.swift Core/Build.swift Core/Battle.swift Core/DawnReport.swift
     Core/Sim.swift Core/Names.swift Core/Autoplay.swift Core/SaveGame.swift Core/TuningRun.swift
     Core/PetitionCourtState.swift Core/PetitionData.swift Core/PetitionEngine.swift Core/PetitionNight.swift
     Core/WorldLayout.swift Core/Camera.swift Core/PixelScale.swift
     Core/Front/FrontTuning.swift Core/Front/FrontState.swift Core/Front/FrontNight.swift Core/Front/PresentBot.swift
     Core/Front/FrontTuningRun.swift
     Core/Front/HearthTuning.swift Core/Front/HearthState.swift Core/Front/Hearth.swift Core/Front/HearthNames.swift
     Core/Front/DawnRing.swift
     tools/frontsweep/stubs.swift tools/frontsweep/main.swift"
START=$(date +%s)
# shellcheck disable=SC2086
if ! xcrun swiftc -O -wmo -swift-version 5 -o "$BIN" $SRC >"$OUT/frontsweep-build.txt" 2>&1; then
    echo "frontsweep: the core did not compile"
    cat "$OUT/frontsweep-build.txt"
    exit 1
fi
echo "frontsweep: compiled in $(( $(date +%s) - START )) s" | tee "$OUT/frontsweep.txt"
# Started in the game's folder, so the petition catalogue reads Resources/Petitions (no app bundle here).
"$BIN" ${1+"$@"} >>"$OUT/frontsweep.txt" 2>&1
RC=$?
echo "frontsweep: exit $RC after $(( $(date +%s) - START )) s" | tee -a "$OUT/frontsweep.txt"
exit $RC
