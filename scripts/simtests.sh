#!/bin/sh
# Usage: simtests.sh <outdir> <only-testing filter>...  – runs tests of the game in the current folder, one at a time.
# Needs PROJECT and SCHEME (run-check.sh sets them) and a build-for-testing in build/SimData; SIM is the simulator.
# Result: the script exits with xcodebuild's own status (0 = all tests passed, 65 = a test failed, anything else = build or
# setup trouble) and prints one line saying so. <outdir>/log.txt is only a filtered view for reading; the line "exit=N" at
# its end is xcodebuild's status, and <outdir>/xcodebuild.log holds the whole unfiltered output. Judge by the exit status.
# TEST_LANG=de TEST_REGION=de_DE runs the tests in that language; the tests read it as GW_LANG (for screenshot names).
# Screenshots attached to the tests land in <outdir> as <attachment name>.png.
SIM=${SIM:-$("$(dirname "$0")/ci/sim-udid.sh")} || exit 1
OUT=$1; shift
ARGS=""
for f in "$@"; do ARGS="$ARGS -only-testing:$f"; done
[ -n "${TEST_LANG:-}" ] && ARGS="$ARGS -testLanguage $TEST_LANG -testRegion ${TEST_REGION:-en_US}"
export TEST_RUNNER_GW_LANG="${TEST_LANG:-en}"
rm -rf "$OUT" "$OUT.xcresult" && mkdir -p "$OUT"
# xcodebuild's status is written to a file because a pipe in sh hides it (a plain $? after the pipe is grep's status).
{ xcodebuild -project "$PROJECT" -scheme "$SCHEME" -destination "id=$SIM" \
    -derivedDataPath build/SimData -parallel-testing-enabled NO $ARGS -resultBundlePath "$OUT.xcresult" test-without-building 2>&1
  echo $? > "$OUT/xcodebuild.status"; } \
  | tee "$OUT/xcodebuild.log" \
  | grep --line-buffered -E "error:|Test Case .*(passed|failed)|✔|✘|TEST (SUCCEEDED|FAILED)|Test run with|recorded an issue|XCTAssert|failed" > "$OUT/log.txt"
RC=$(cat "$OUT/xcodebuild.status" 2>/dev/null); RC=${RC:-1}
echo "exit=$RC" >> "$OUT/log.txt"
xcrun xcresulttool export attachments --path "$OUT.xcresult" --output-path "$OUT/raw" >/dev/null 2>&1
python3 - "$OUT" <<'PY'
import json, re, shutil, sys, os
out = sys.argv[1]
m = f"{out}/raw/manifest.json"
if os.path.exists(m):
    for test in json.load(open(m)):
        for a in test.get("attachments", []):
            f = a.get("exportedFileName", "")
            if f.endswith((".png", ".txt")):
                ext = os.path.splitext(f)[1]
                name = re.sub(r"_0_[0-9A-F-]+\.(png|txt)$", "", a.get("suggestedHumanReadableName", f))
                name = re.sub(r"\.(png|txt)$", "", name)
                shutil.copy(f"{out}/raw/{f}", f"{out}/{name}{ext}")
PY
ls "$OUT"/*.png 2>/dev/null | wc -l | xargs echo "screenshots:" >> "$OUT/log.txt"
if [ "$RC" -eq 0 ]; then
    grep -q -E "Test Case .*passed|✔" "$OUT/log.txt" || echo "WARNING: exit 0 but no passed test seen in $OUT/log.txt; check the only-testing filter"
    echo "simtests: PASSED (xcodebuild exit 0), see $OUT/log.txt"
else
    echo "simtests: FAILED (xcodebuild exit $RC), see $OUT/log.txt and $OUT/xcodebuild.log"
fi
exit "$RC"
