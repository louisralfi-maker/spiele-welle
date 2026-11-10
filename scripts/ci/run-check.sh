#!/bin/bash
# Runs on GitHub's Mac runner. The head commit's message names the game ("game: <slug>") and the steps, one "do: <step>" each:
#   build                build-for-testing; it runs first by itself when a step needs it
#   unit [<filter>...]   scripts/simtests.sh over these filters in one run; without a filter, all of <Name>Tests
#   ui [<filter>...]     the same for the UI tests (all of <Name>UITests without a filter), in English
#   ui-de [<filter>...]  the same in German
#   release              unsigned Release build for a device
#   testflight           signed Release archive, uploaded to App Store Connect for TestFlight (ci/tf-* rounds only)
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

tests() { # <kind> <filters...>
    KIND=$1; shift
    N=$((N + 1))
    D=$(printf '%02d-%s' "$N" "$KIND")
    build
    if [ $# -eq 0 ]; then
        if [ "$KIND" = unit ]; then set -- "${NAME}Tests"; else set -- "${NAME}UITests"; fi
    fi
    export TEST_LANG="" TEST_REGION=""
    [ "$KIND" = ui-de ] && export TEST_LANG=de TEST_REGION=de_DE
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

testflight() {
    # Archives the Release build and uploads it to App Store Connect; it shows up in TestFlight after Apple's processing
    # (10 to 30 minutes). The App Store Connect API key comes from the repo secrets ASC_KEY_ID, ASC_ISSUER_ID and
    # ASC_PRIVATE_KEY, which sim-check.yml hands over on ci/tf-* branches only. The key file lives in a temporary folder
    # outside the repo during this step only. The log in ci-out has both ids blanked and never holds the key.
    N=$((N + 1))
    D=$(printf '%02d-testflight' "$N")
    # Only a build whose earlier steps all passed goes to Louis' phone: put build and unit (at least) before it.
    if [ "$FAILED" -gt 0 ]; then
        note "$(stamp) SKIP testflight: $FAILED earlier step(s) failed, nothing uploaded"
        FAILED=$((FAILED + 1))
        return
    fi
    if [ -z "${ASC_KEY_ID:-}" ] || [ -z "${ASC_ISSUER_ID:-}" ] || [ -z "${ASC_PRIVATE_KEY:-}" ]; then
        note "$(stamp) FAIL testflight: the secrets ASC_KEY_ID, ASC_ISSUER_ID and ASC_PRIVATE_KEY are not all there (ci/tf-* only)"
        FAILED=$((FAILED + 1))
        return
    fi
    [ -d "$PROJECT" ] || { brew install xcodegen >"$CI_OUT/xcodegen.log" 2>&1; xcodegen generate >>"$CI_OUT/xcodegen.log" 2>&1; }
    if [ -f Package.resolved ]; then mkdir -p "$PINS" && cp Package.resolved "$PINS/"; fi
    TF="${RUNNER_TEMP:-/tmp}/tf"
    rm -rf "$TF"
    mkdir -p "$TF/key"
    chmod 700 "$TF/key"
    KEY="$TF/key/AuthKey_$ASC_KEY_ID.p8"
    ( umask 077; printf '%s\n' "$ASC_PRIVATE_KEY" >"$KEY" )
    AUTH=(-allowProvisioningUpdates -authenticationKeyPath "$KEY" -authenticationKeyID "$ASC_KEY_ID" -authenticationKeyIssuerID "$ASC_ISSUER_ID")
    BUILD_NO=${GITHUB_RUN_NUMBER:-1}
    ARCHIVE="$TF/$NAME.xcarchive"
    cat >"$TF/ExportOptions.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key><string>app-store-connect</string>
    <key>destination</key><string>upload</string>
    <key>teamID</key><string>XLKZ9W7C7T</string>
    <key>signingStyle</key><string>automatic</string>
    <key>uploadSymbols</key><true/>
    <key>manageAppVersionAndBuildNumber</key><false/>
</dict>
</plist>
PLIST
    archive() {
        xcodebuild -project "$PROJECT" -scheme "$SCHEME" -configuration Release -destination generic/platform=iOS \
            -archivePath "$ARCHIVE" -derivedDataPath build/TF -jobs "$NPROC" "${AUTH[@]}" \
            CURRENT_PROJECT_VERSION="$BUILD_NO" "$@" archive
    }
    {
        echo "== archive with automatic signing, build $BUILD_NO"
        archive
        RC=$?
        if [ "$RC" -ne 0 ]; then
            # A team without a registered device gets no development profile; the export signs for the store anyway.
            echo "== archive again without signing (exit $RC before); the export signs it"
            rm -rf "$ARCHIVE"
            archive CODE_SIGNING_ALLOWED=NO
            RC=$?
        fi
        if [ "$RC" -eq 0 ]; then
            echo "== export and upload to App Store Connect"
            xcodebuild -exportArchive -archivePath "$ARCHIVE" -exportOptionsPlist "$TF/ExportOptions.plist" \
                -exportPath "$TF/export" "${AUTH[@]}"
            RC=$?
        fi
        echo "== exit $RC"
    } >"$TF/testflight.log" 2>&1
    rm -rf "$TF/key"
    grep -v 'PRIVATE KEY' "$TF/testflight.log" | sed -e "s/$ASC_KEY_ID/[key-id]/g" -e "s/$ASC_ISSUER_ID/[issuer-id]/g" >"$CI_OUT/$D.log"
    grep -E ' error: |^error: |ERROR|Error Domain|ITMS-|\*\* .* \*\*|Upload succeeded|Uploaded|^== ' "$CI_OUT/$D.log" | sort -u | head -80 >"$CI_OUT/$D-summary.txt"
    gzip -9 -f "$CI_OUT/$D.log"
    if [ "$RC" -eq 0 ]; then
        note "$(stamp) PASS testflight: version $(sed -n 's/^ *MARKETING_VERSION: *"\{0,1\}\([^"]*\)"\{0,1\}$/\1/p' project.yml | head -1) build $BUILD_NO uploaded"
    else
        note "$(stamp) FAIL testflight (exit $RC), see $D-summary.txt and $D.log.gz"
        FAILED=$((FAILED + 1))
    fi
}

STEPS=$(git log -1 --format=%B HEAD | sed -n 's/^do: //p')
[ -n "$STEPS" ] || { note "FAILED: no steps in the commit message"; exit 1; }
while IFS= read -r LINE; do
    set -- $LINE
    CMD=$1; shift
    case "$CMD" in
        build) build ;;
        unit|ui|ui-de) tests "$CMD" "$@" ;;
        release) release ;;
        testflight) testflight ;;
        sh) simulator; other sh bash -c "${LINE#sh }" ;;
        *) note "FAIL unknown step: $LINE"; FAILED=$((FAILED + 1)) ;;
    esac
done <<<"$STEPS"

find ~/Library/Logs/DiagnosticReports -name "${NAME}*" -mmin -180 2>/dev/null | head -5 | while read -r F; do cp "$F" "$CI_OUT/"; done
if [ "$FAILED" -eq 0 ]; then note "ALL PASSED"; else note "FAILED: $FAILED"; fi
exit "$FAILED"
