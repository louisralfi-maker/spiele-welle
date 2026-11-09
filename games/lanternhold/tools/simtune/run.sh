#!/bin/bash
# The tuning harness, for GitHub's Mac runner only (a round step: sh bash tools/simtune/run.sh). It compiles the
# simulation core with -O for the Mac and writes the eight tuning targets for the balance variants of main.swift to
# $CI_OUT/simtune.txt. Never run it on the old Mac (CLAUDE.md "This Mac": no swiftc here).
set -u
cd "$(dirname "$0")/../.." || exit 1
OUT=${CI_OUT:-/tmp}
BIN="$(mktemp -d)/simtune"
SRC="Core/DayClock.swift Core/SeededRandom.swift Core/LightField.swift Core/AmbientRamp.swift Core/Balance.swift
     Core/Realm.swift Core/GameState.swift Core/Economy.swift Core/Build.swift Core/Battle.swift Core/DawnReport.swift
     Core/Sim.swift Core/Names.swift Core/Autoplay.swift Core/SaveGame.swift Core/TuningRun.swift
     tools/simtune/main.swift"
START=$(date +%s)
# shellcheck disable=SC2086
if ! xcrun swiftc -O -wmo -swift-version 5 -o "$BIN" $SRC >"$OUT/simtune-build.txt" 2>&1; then
    echo "simtune: the core did not compile"
    cat "$OUT/simtune-build.txt"
    exit 1
fi
echo "simtune: compiled in $(( $(date +%s) - START )) s" | tee "$OUT/simtune.txt"
"$BIN" >>"$OUT/simtune.txt" 2>&1
RC=$?
echo "simtune: exit $RC after $(( $(date +%s) - START )) s" | tee -a "$OUT/simtune.txt"
exit $RC
