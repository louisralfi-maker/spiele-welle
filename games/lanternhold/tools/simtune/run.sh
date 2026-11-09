#!/bin/bash
# The tuning harness, for GitHub's Mac runner only (a round step: sh bash tools/simtune/run.sh [finale]). It compiles
# the simulation core with -O for the Mac and writes the eight tuning targets for the balance variants of main.swift to
# $CI_OUT/simtune.txt; with "finale" it sweeps the Lightless King's departure, its jitter and his walk on night 20 over
# seeds 1 to 20 instead (main.swift, `SimTune.finale`). Never run it on the old Mac (CLAUDE.md "This Mac": no swiftc
# here).
set -u
cd "$(dirname "$0")/../.." || exit 1
OUT=${CI_OUT:-/tmp}
BIN="$(mktemp -d)/simtune"
# The core the bots play (M3: the petitions the reference bot hears, their night modifiers and the court's state; since
# the M2b review the battle's line-1 torches read WorldLayout, which needs Camera's planes and the pixel scale).
SRC="Core/DayClock.swift Core/SeededRandom.swift Core/LightField.swift Core/AmbientRamp.swift Core/Balance.swift
     Core/Realm.swift Core/GameState.swift Core/Economy.swift Core/Build.swift Core/Battle.swift Core/DawnReport.swift
     Core/Sim.swift Core/Names.swift Core/Autoplay.swift Core/SaveGame.swift Core/TuningRun.swift
     Core/PetitionCourtState.swift Core/PetitionData.swift Core/PetitionEngine.swift Core/PetitionNight.swift
     Core/WorldLayout.swift Core/Camera.swift Core/PixelScale.swift
     tools/simtune/main.swift"
START=$(date +%s)
# shellcheck disable=SC2086
if ! xcrun swiftc -O -wmo -swift-version 5 -o "$BIN" $SRC >"$OUT/simtune-build.txt" 2>&1; then
    echo "simtune: the core did not compile"
    cat "$OUT/simtune-build.txt"
    exit 1
fi
echo "simtune: compiled in $(( $(date +%s) - START )) s" | tee "$OUT/simtune.txt"
# Started in the game's folder, so the petition catalogue reads Resources/Petitions (no app bundle here).
"$BIN" ${1+"$@"} >>"$OUT/simtune.txt" 2>&1
RC=$?
echo "simtune: exit $RC after $(( $(date +%s) - START )) s" | tee -a "$OUT/simtune.txt"
exit $RC
