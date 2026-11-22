#!/bin/bash
# The Release app on the simulator, for a round's sh step (Lanternhold's proof before TestFlight build 2):
#   do: sh bash ../../scripts/ci/release-sim-launch.sh
# run-check.sh runs a sh step from the game's folder (games/<slug>) after booting the simulator, with REPO, CI_OUT,
# GAME_DIR, PROJECT, SCHEME and SIM exported. This script:
#   1. builds the app with -configuration Release for the simulator into build/RelSim (its own derived data);
#   2. prints every "ship languages:" line of that build's log and lists the *.lproj folders in the built app, and fails
#      if any folder other than en.lproj and Base.lproj is left (the proof of the Release-only language strip);
#   3. uninstalls the app, installs the Release app, launches it with no arguments, saves simulator screenshots after
#      3, 10 and 25 s and fails if the app is not running at 25 s;
#   4. launches it again with -GWScreen report -GWGold 999, saves proof-release-hooks-ignored-05s.png after 5 s (the
#      title must stand: the hooks are dead in Release; judged by eye at the gate) and fails unless the app's launch log
#      carries its line "debug args: none" (DebugArgs and the sweep read nothing).
# Everything lands in $CI_OUT/release-sim/, which the round publishes. Put this step last in a round: it leaves the
# Release app installed in place of the Debug one.
set -euo pipefail

: "${CI_OUT:?run this from run-check.sh (a sh step)}"
: "${PROJECT:?}" "${SCHEME:?}" "${SIM:?}"
NPROC=$(sysctl -n hw.ncpu)
OUT="$CI_OUT/release-sim"
DERIVED="build/RelSim"
mkdir -p "$OUT"

echo "== release-sim-launch: $SCHEME in $(pwd), simulator $SIM, $NPROC jobs"

# The project file, as run-check.sh's release step makes it when no build step ran before.
if [ ! -d "$PROJECT" ]; then
    command -v xcodegen >/dev/null 2>&1 || brew install xcodegen >"$OUT/xcodegen.log" 2>&1
    xcodegen generate >>"$OUT/xcodegen.log" 2>&1
fi
if [ -f Package.resolved ]; then
    mkdir -p "$PROJECT/project.xcworkspace/xcshareddata/swiftpm"
    cp Package.resolved "$PROJECT/project.xcworkspace/xcshareddata/swiftpm/"
fi

# 1. The Release build for the simulator.
build_release() {
    xcodebuild -project "$PROJECT" -scheme "$SCHEME" -configuration Release -destination "id=$SIM" \
        -derivedDataPath "$DERIVED" -jobs "$NPROC" ONLY_ACTIVE_ARCH=YES "$@" build >"$OUT/build.log" 2>&1
}
echo "== $(date +%H:%M:%S) Release build starts"
RC=0
build_release || RC=$?
if [ "$RC" -ne 0 ] && grep -qE 'requires a provisioning profile|No Accounts|requires a development team|No profiles for' "$OUT/build.log"; then
    echo "== signing failed without an Apple ID, building again unsigned"
    RC=0
    build_release CODE_SIGNING_ALLOWED=NO || RC=$?
fi
if [ "$RC" -ne 0 ]; then
    echo "FAIL: the Release build for the simulator failed (exit $RC)"
    grep -E ' error: |^error: |\*\* .* \*\*' "$OUT/build.log" | sort -u | head -60 || true
    gzip -9 -f "$OUT/build.log"
    exit 1
fi
echo "== $(date +%H:%M:%S) Release build done"

# 2. The languages.
echo "== the build's \"ship languages:\" lines"
grep 'ship languages:' "$OUT/build.log" || echo "(none: the ship-languages phase printed nothing)"
gzip -9 -f "$OUT/build.log"

APP="$DERIVED/Build/Products/Release-iphonesimulator/$SCHEME.app"
if [ ! -d "$APP" ]; then
    echo "FAIL: no app at $APP"
    exit 1
fi
echo "== the *.lproj folders in $APP"
LEFT=""
COUNT=0
while IFS= read -r DIR; do
    [ -n "$DIR" ] || continue
    NAME=$(basename "$DIR")
    echo "  $NAME"
    COUNT=$((COUNT + 1))
    case "$NAME" in
        en.lproj|Base.lproj) ;;
        *) LEFT="$LEFT $NAME" ;;
    esac
done <<EOT
$(find "$APP" -maxdepth 1 -type d -name '*.lproj' | sort)
EOT
echo "  ($COUNT folders)"
if [ ! -d "$APP/en.lproj" ]; then
    echo "FAIL: no en.lproj in the Release app (the English texts are missing)"
    exit 1
fi
if [ -n "$LEFT" ]; then
    echo "FAIL: language folders left in the Release app:$LEFT"
    exit 1
fi
echo "PASS: only en.lproj and Base.lproj in the Release app"

# 3. A plain launch of the Release app.
BUNDLE=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$APP/Info.plist")
echo "== $(date +%H:%M:%S) install $BUNDLE on $SIM"
xcrun simctl terminate "$SIM" "$BUNDLE" >/dev/null 2>&1 || true
xcrun simctl uninstall "$SIM" "$BUNDLE" >/dev/null 2>&1 || true
xcrun simctl install "$SIM" "$APP"

shot() { # <seconds since launch> <file name>
    local WAIT
    WAIT=$(($1 - $(date +%s) + START))
    if [ "$WAIT" -gt 0 ]; then sleep "$WAIT"; fi
    if xcrun simctl io "$SIM" screenshot "$OUT/$2" >/dev/null 2>&1; then
        echo "  saved $2 at $(($(date +%s) - START)) s"
    else
        echo "  WARNING: no screenshot $2 at $(($(date +%s) - START)) s"
    fi
}

# The launch call itself can take 15 s on the runner (lh-pf-1, lh-pf-2): it runs beside the shots, so they count from
# the moment the app was asked to start.
START=$(date +%s)
xcrun simctl launch "$SIM" "$BUNDLE" >"$OUT/launch.txt" 2>&1 &
LAUNCHER=$!
shot 3 proof-release-03s.png
shot 10 proof-release-10s.png
if ! wait "$LAUNCHER"; then
    echo "FAIL: simctl launch failed: $(cat "$OUT/launch.txt")"
    exit 1
fi
LAUNCHED=$(tail -1 "$OUT/launch.txt")
PID=${LAUNCHED##*: }
echo "== launched with no arguments: $LAUNCHED (the call returned by $(($(date +%s) - START)) s)"
shot 25 proof-release-25s.png
if ps -p "$PID" >/dev/null 2>&1; then
    echo "PASS: the Release app runs at 25 s (pid $PID)"
else
    echo "FAIL: the Release app is not running at 25 s (pid $PID is gone)"
    find "$HOME/Library/Logs/DiagnosticReports" -name "${SCHEME}*" -mmin -10 2>/dev/null | head -3 \
        | while IFS= read -r F; do cp "$F" "$OUT/" || true; done || true
    exit 1
fi
xcrun simctl terminate "$SIM" "$BUNDLE" >/dev/null 2>&1 || true
sleep 2

# 4. The debug hooks are dead in a Release build (build 3, lane 6): launched with -GWScreen report -GWGold 999 it must
#    stand on the title (proof-release-hooks-ignored-05s.png, judged by eye at the gate), and its launch log must carry
#    the app's line "debug args: none" (LanternholdApp, Release only; the app's stdout and stderr go to files here).
HOOKS_OUT="$OUT/hooks-stdout.txt"
HOOKS_ERR="$OUT/hooks-stderr.txt"
rm -f "$HOOKS_OUT" "$HOOKS_ERR"
START=$(date +%s)
LAUNCHED=$(xcrun simctl launch --stdout="$HOOKS_OUT" --stderr="$HOOKS_ERR" "$SIM" "$BUNDLE" -GWScreen report -GWGold 999)
echo "== $(date +%H:%M:%S) launched with -GWScreen report -GWGold 999: $LAUNCHED"
shot 5 proof-release-hooks-ignored-05s.png
xcrun simctl terminate "$SIM" "$BUNDLE" >/dev/null 2>&1 || true
if grep -q 'debug args: none' "$HOOKS_OUT" "$HOOKS_ERR" 2>/dev/null; then
    echo "PASS: the Release app says \"debug args: none\" (it read no launch argument)"
else
    echo "FAIL: no \"debug args: none\" in the Release app's launch log"
    for F in "$HOOKS_OUT" "$HOOKS_ERR"; do
        echo "--- $(basename "$F"):"
        head -20 "$F" 2>/dev/null || echo "(no file)"
    done
    exit 1
fi
echo "== $(date +%H:%M:%S) done; screenshots in release-sim/ (portrait frames of a landscape app)"
