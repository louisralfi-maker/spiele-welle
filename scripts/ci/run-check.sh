#!/bin/bash
# Runs on GitHub's Mac runner. The head commit's message names the game ("game: <slug>") and the steps, one "do: <step>" each:
#   build                build-for-testing; it runs first by itself when a step needs it
#   unit [<filter>...]   scripts/simtests.sh over these filters in one run; without a filter, all of <Name>Tests
#   ui [<filter>...]     the same for the UI tests (all of <Name>UITests without a filter), in English
#   ui-de [<filter>...]  the same in German; ui-<lang> for any other language (fr, es, it, pt-BR, ja, zh-Hans)
#   release              unsigned Release build for a device
#   sh <command>         any command from the game's folder; it may write files to $CI_OUT
# The game's folder is games/<slug>; its project.yml's "name:" is the project, scheme and app name. A failed step does not
# stop the later ones, except a failed build. Everything lands in ci-out/ at the repo root, whose summary.txt ends with
# "ALL PASSED" or "FAILED: <n>". publish-results.sh pushes the folder to ci-results/<label>.
set -u
REPO=$(pwd)
export REPO CI_OUT="$REPO/ci-out"
mkdir -p "$CI_OUT"
SUM="$CI_OUT/summary.txt"
NPROC=$(sysctl -n hw.ncpu)
FAILED=0
BUILT=0
N=0
note() { echo "$*" | tee -a "$SUM"; }
stamp() { date +%H:%M:%S; }

note "machine: macOS $(sw_vers -productVersion) $(uname -m), $NPROC cores, $(( $(sysctl -n hw.memsize) / 1073741824 )) GB"
note "xcode: $(xcodebuild -version | tr '\n' ' ')"
git log -1 --format=%B HEAD | grep -E '^(game|tested|source): ' | tee -a "$SUM"

GAME=$(git log -1 --format=%B HEAD | sed -n 's/^game: //p' | head -1)
if [ -z "$GAME" ] || [ ! -f "games/$GAME/project.yml" ]; then
    note "FAILED: no game line in the commit message, or no games/$GAME/project.yml"
    exit 1
fi
cd "games/$GAME" || exit 1
NAME=$(sed -n 's/^name: *//p' project.yml | head -1)
export GAME_DIR="$REPO/games/$GAME" PROJECT="$NAME.xcodeproj" SCHEME="$NAME"
PINS="$PROJECT/project.xcworkspace/xcshareddata/swiftpm"

simulator() {
    [ -n "${SIM:-}" ] && return 0
    SIM=$("$REPO/scripts/ci/sim-udid.sh" 2>/dev/null) || SIM=""
    if [ -z "$SIM" ]; then
        RT=$(xcrun simctl list runtimes available | grep -oE 'com\.apple\.CoreSimulator\.SimRuntime\.iOS-[0-9-]+' | tail -1)
        SIM=$(xcrun simctl create "iPhone 17 Pro" com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro "$RT")
    fi
    export SIM
    xcrun simctl boot "$SIM" 2>/dev/null
    xcrun simctl bootstatus "$SIM" -b >/dev/null 2>&1
    note "simulator: $SIM ($(xcrun simctl list devices | grep "$SIM" | sed -E 's/ \(.*//;s/^ *//'), $(xcrun simctl list runtimes available | grep -oE 'iOS [0-9.]+' | tail -1))"
}

build() {
    [ "$BUILT" = 1 ] && return 0
    note "$(stamp) build starts ($NAME)"
    simulator
    brew install xcodegen >"$CI_OUT/xcodegen.log" 2>&1
    xcodegen generate >>"$CI_OUT/xcodegen.log" 2>&1
    # Package pins, when the game has any (games/<slug>/Package.resolved): the same versions on every run.
    if [ -f Package.resolved ]; then mkdir -p "$PINS" && cp Package.resolved "$PINS/"; fi
    run_build() {
        xcodebuild -project "$PROJECT" -scheme "$SCHEME" -destination "id=$SIM" \
            -derivedDataPath build/SimData -jobs "$NPROC" "$@" build-for-testing >"$CI_OUT/build.log" 2>&1
    }
    run_build
    RC=$?
    if [ "$RC" -ne 0 ] && grep -qE 'requires a provisioning profile|No Accounts|requires a development team|No profiles for' "$CI_OUT/build.log"; then
        note "build: signing failed without an Apple ID, trying unsigned"
        run_build CODE_SIGNING_ALLOWED=NO
        RC=$?
    fi
    grep -E ' error: |^error: |BUILD (SUCCEEDED|FAILED)|\*\* .* \*\*' "$CI_OUT/build.log" | sort -u | head -80 >"$CI_OUT/build-errors.txt"
    grep -E ' warning: ' "$CI_OUT/build.log" | grep -v '/SourcePackages/' | sort -u | head -80 >"$CI_OUT/build-warnings.txt"
    gzip -9 -f "$CI_OUT/build.log"
    # The resolved package versions, to commit as games/<slug>/Package.resolved the first time.
    [ -f "$PINS/Package.resolved" ] && cp "$PINS/Package.resolved" "$CI_OUT/Package.resolved"
    if [ "$RC" -ne 0 ]; then
        note "$(stamp) FAIL build (exit $RC), see build-errors.txt"
        note "FAILED: build"
        exit 1
    fi
    BUILT=1
    note "$(stamp) PASS build"
}

region() { # <language> → the region the UI tests run in
    case "$1" in
        de) echo de_DE ;; fr) echo fr_FR ;; es) echo es_ES ;; it) echo it_IT ;;
        pt-BR) echo pt_BR ;; ja) echo ja_JP ;; zh-Hans) echo zh_CN ;; *) echo en_US ;;
    esac
}

tests() { # <kind> <filters...>
    KIND=$1; shift
    N=$((N + 1))
    D=$(printf '%02d-%s' "$N" "$KIND")
    build
    if [ $# -eq 0 ]; then
        if [ "$KIND" = unit ]; then set -- "${NAME}Tests"; else set -- "${NAME}UITests"; fi
    fi
    export TEST_LANG="" TEST_REGION=""
    case "$KIND" in
        ui-*) TEST_LANG=${KIND#ui-}; TEST_REGION=$(region "$TEST_LANG") ;;
    esac
    "$REPO/scripts/simtests.sh" "$CI_OUT/$D" "$@" >/dev/null 2>&1
    RC=$?
    rm -rf "$CI_OUT/$D.xcresult" "$CI_OUT/$D/raw"
    [ -f "$CI_OUT/$D/xcodebuild.log" ] && gzip -9 -f "$CI_OUT/$D/xcodebuild.log"
    if [ "$RC" -eq 0 ]; then note "$(stamp) PASS $KIND $*"; else note "$(stamp) FAIL $KIND $* (exit $RC), see $D/log.txt"; FAILED=$((FAILED + 1)); fi
}

other() { # <step name> <command...>
    STEP=$1; shift
    N=$((N + 1))
    D=$(printf '%02d-%s' "$N" "$STEP")
    "$@" >"$CI_OUT/$D.log" 2>&1
    RC=$?
    gzip -9 -f "$CI_OUT/$D.log"
    if [ "$RC" -eq 0 ]; then note "$(stamp) PASS $STEP"; else note "$(stamp) FAIL $STEP (exit $RC), see $D.log.gz"; FAILED=$((FAILED + 1)); fi
}

release() {
    # Needs the project file even when no step built for the simulator first.
    [ -d "$PROJECT" ] || { brew install xcodegen >"$CI_OUT/xcodegen.log" 2>&1; xcodegen generate >>"$CI_OUT/xcodegen.log" 2>&1; }
    if [ -f Package.resolved ]; then mkdir -p "$PINS" && cp Package.resolved "$PINS/"; fi
    other release xcodebuild -project "$PROJECT" -scheme "$SCHEME" -configuration Release \
        -destination generic/platform=iOS -derivedDataPath build/RelMain -jobs "$NPROC" CODE_SIGNING_ALLOWED=NO build
}

STEPS=$(git log -1 --format=%B HEAD | sed -n 's/^do: //p')
[ -n "$STEPS" ] || { note "FAILED: no steps in the commit message"; exit 1; }
while IFS= read -r LINE; do
    set -- $LINE
    CMD=$1; shift
    case "$CMD" in
        build) build ;;
        unit|ui|ui-*) tests "$CMD" "$@" ;;
        release) release ;;
        sh) simulator; other sh bash -c "${LINE#sh }" ;;
        *) note "FAIL unknown step: $LINE"; FAILED=$((FAILED + 1)) ;;
    esac
done <<<"$STEPS"

find ~/Library/Logs/DiagnosticReports -name "${NAME}*" -mmin -180 2>/dev/null | head -5 | while read -r F; do cp "$F" "$CI_OUT/"; done
if [ "$FAILED" -eq 0 ]; then note "ALL PASSED"; else note "FAILED: $FAILED"; fi
exit "$FAILED"
