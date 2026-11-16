#!/bin/bash
# A 10 s clip of the horde on the simulator, for a round's sh step (Lanternhold build 3, lane 4, POLISH.md 6.6: motion
# is judged from clips, at full speed and at a quarter):
#   do: sh bash ../../scripts/ci/sim-clip.sh
# run-check.sh runs a sh step from the game's folder (games/<slug>) after booting the simulator, with REPO, CI_OUT,
# GAME_DIR, PROJECT, SCHEME and SIM exported. Put it after the build (it installs the Debug app from build/SimData)
# and after a ui step (which leaves the simulator turned to landscape). This script:
#   1. launches night 12 of the demo realm live (no frozen time: the bot plays it to the start hour, then the night
#      runs at its own speed, 12 s a game hour), the lord at the outer wall. The start hour is 0.3 game hours (about
#      4 s, the wait for the world below) before the wall's hour that HordeUITests found and noted in the ui step
#      before this one (`*-ui/209-horde-hours-en.txt`, "wall=<hour>"); without that note, 22:06, as the first wave
#      steps out of the bank;
#   2. waits until the world is on screen, then records 10 s with `xcrun simctl io recordVideo`. The simulator shows
#      the home screen before the launch (as big a PNG as the world), so the wait first takes the home screen's size,
#      waits for the launch call to return, and then needs two probes in a row, at least 3 s later, that are over
#      250 KB and differ from the home screen by more than a tenth (the launch colour and the black before the first
#      frame are a few KB). The recorder is stopped with a time limit, so a stuck recording never holds the round;
#   3. keeps the clip under 8 MB in $CI_OUT/clip/horde-clip.mp4: turned upright and shrunk to 720 rows with ffmpeg when
#      the runner has it, else shrunk with avconvert when it is too big, else as recorded; plus a still at its end.
# Everything lands in $CI_OUT/clip/ (published with the round's results by publish-results.sh). It never fails a round:
# whatever goes wrong, it says so in clip-note.txt and exits 0.
set -u
OUT="${CI_OUT:-ci-out}/clip"
mkdir -p "$OUT"
NOTE="$OUT/clip-note.txt"
RAW="$OUT/raw.mp4"
CLIP="$OUT/horde-clip.mp4"
LIMIT=8000000
note() { echo "$*" | tee -a "$NOTE"; }
done_() { note "== $(date +%H:%M:%S) done"; exit 0; }
size() { stat -f%z "$1" 2>/dev/null || echo 0; }

note "== $(date +%H:%M:%S) sim-clip: ${SCHEME:-?} in $(pwd), simulator ${SIM:-none}"
[ -n "${SIM:-}" ] || { note "NOTE: no simulator (SIM is empty), no clip"; done_; }
SCHEME=${SCHEME:-Lanternhold}
APP="build/SimData/Build/Products/Debug-iphonesimulator/$SCHEME.app"
if [ -d "$APP" ]; then
    BUNDLE=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$APP/Info.plist" 2>/dev/null)
    xcrun simctl terminate "$SIM" "$BUNDLE" >/dev/null 2>&1
    xcrun simctl install "$SIM" "$APP" >>"$NOTE" 2>&1 || note "NOTE: install failed; trying the app already there"
else
    BUNDLE=com.louisherwick.lanternhold
    note "NOTE: no Debug app at $APP; trying the app already installed ($BUNDLE)"
fi

# The home screen's size before the launch (the ui step before this one ends there).
HOME_SIZE=0
xcrun simctl io "$SIM" screenshot "$OUT/home.png" >/dev/null 2>&1 && HOME_SIZE=$(size "$OUT/home.png")
rm -f "$OUT/home.png"
note "home screen probe: $HOME_SIZE bytes"
# Not the home screen: over 250 KB and more than a tenth away from its size.
world_probe() {
    local s
    xcrun simctl io "$SIM" screenshot "$OUT/probe.png" >/dev/null 2>&1 || return 1
    s=$(size "$OUT/probe.png")
    [ "$s" -gt 250000 ] || return 1
    [ "$HOME_SIZE" -gt 0 ] || return 0
    local d=$(( s - HOME_SIZE ))
    [ "$d" -lt 0 ] && d=$(( -d ))
    [ $(( d * 10 )) -gt "$HOME_SIZE" ]
}

# The start hour from HordeUITests' note.
CLIP_HOUR=22.1
HOURS_NOTE=$(ls "${CI_OUT:-ci-out}"/*-ui/209-horde-hours-en.txt 2>/dev/null | head -1)
if [ -n "$HOURS_NOTE" ]; then
    WALL=$(sed -n 's/.*wall=\([0-9][0-9.]*\).*/\1/p' "$HOURS_NOTE" | head -1)
    if [ -n "$WALL" ]; then
        CLIP_HOUR=$(awk -v w="$WALL" 'BEGIN { s = w - 0.3; if (s < 0) s += 24; printf "%.3f", s }')
    fi
    note "hours note: $(head -1 "$HOURS_NOTE")"
else
    note "NOTE: no hours note from HordeUITests; the default start"
fi
note "start hour: $CLIP_HOUR"

# 1. The live night. The launch call can take 15 s on the runner; it returns once the process runs (at most 90 s here).
xcrun simctl launch "$SIM" "$BUNDLE" -GWNight 12 -GWHour "$CLIP_HOUR" -GWBuild demo -GWCameraX 640 -GWLook 2 \
    -GWWeather breeze >"$OUT/launch.txt" 2>&1 &
LAUNCHER=$!
START=$(date +%s)
while kill -0 "$LAUNCHER" 2>/dev/null && [ $(( $(date +%s) - START )) -lt 90 ]; do sleep 1; done
if kill -0 "$LAUNCHER" 2>/dev/null; then
    kill "$LAUNCHER" 2>/dev/null
    note "NOTE: simctl launch did not return within 90 s"
fi
wait "$LAUNCHER" 2>/dev/null || note "NOTE: simctl launch said: $(tail -1 "$OUT/launch.txt")"
LAUNCHED=$(date +%s)
note "== $(date +%H:%M:%S) launch call returned after $(( LAUNCHED - START )) s"

# 2. Wait for the world (two probes in a row, from 3 s after the launch call), then record.
READY=0
HITS=0
sleep 3
while [ $(( $(date +%s) - LAUNCHED )) -lt 120 ]; do
    if world_probe; then
        HITS=$(( HITS + 1 ))
        [ "$HITS" -ge 2 ] && { READY=1; break; }
    else
        HITS=0
    fi
    sleep 1
done
[ -f "$OUT/probe.png" ] && note "last probe: $(size "$OUT/probe.png") bytes"
rm -f "$OUT/probe.png"
if [ "$READY" != 1 ]; then
    note "NOTE: the world never came on screen within 120 s; no clip"
    xcrun simctl io "$SIM" screenshot "$OUT/horde-clip-notready.png" >/dev/null 2>&1
    xcrun simctl terminate "$SIM" "$BUNDLE" >/dev/null 2>&1
    done_
fi
note "== $(date +%H:%M:%S) the world is on screen after $(( $(date +%s) - START )) s; recording 10 s"
rm -f "$RAW"
xcrun simctl io "$SIM" recordVideo --codec=h264 --force "$RAW" >"$OUT/record.txt" 2>&1 &
RECORDER=$!
sleep 10
# Stop it with a time limit: SIGINT lets it finish the file; a recorder still running after 15 s is killed.
kill -INT "$RECORDER" 2>/dev/null
for _ in $(seq 15); do kill -0 "$RECORDER" 2>/dev/null || break; sleep 1; done
if kill -0 "$RECORDER" 2>/dev/null; then
    kill -9 "$RECORDER" 2>/dev/null
    note "NOTE: the recorder did not stop within 15 s and was killed (the file may be cut)"
fi
wait "$RECORDER" 2>/dev/null
xcrun simctl io "$SIM" screenshot "$OUT/horde-clip-end.png" >/dev/null 2>&1
xcrun simctl terminate "$SIM" "$BUNDLE" >/dev/null 2>&1
if [ ! -s "$RAW" ]; then
    note "NOTE: the recording failed: $(tail -2 "$OUT/record.txt" | tr '\n' ' ')"
    done_
fi
note "recorded $(size "$RAW") bytes"

# 3. Upright and small.
if command -v ffmpeg >/dev/null 2>&1; then
    # The simulator records its portrait frame buffer; a landscape game stands on its side in it (turn it back).
    TURN=""
    DIMS=$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=p=0 "$RAW" 2>/dev/null)
    W=${DIMS%%,*}
    H=${DIMS##*,}
    if [ -n "$W" ] && [ -n "$H" ] && [ "$H" -gt "$W" ] 2>/dev/null; then TURN="transpose=2,"; fi
    if ffmpeg -y -v error -i "$RAW" -vf "${TURN}scale=-2:720" -c:v libx264 -crf 26 -preset veryfast -an \
        -movflags +faststart "$CLIP" >>"$NOTE" 2>&1; then
        note "ffmpeg: ${DIMS:-?} -> 720 rows${TURN:+, turned upright}: $(size "$CLIP") bytes"
    else
        note "NOTE: ffmpeg failed"
        rm -f "$CLIP"
    fi
fi
if [ ! -s "$CLIP" ]; then
    if [ "$(size "$RAW")" -le "$LIMIT" ]; then
        mv "$RAW" "$CLIP"
        note "kept as recorded (no ffmpeg on the runner: the frame may stand on its side)"
    else
        for P in Preset1280x720 Preset960x540; do
            rm -f "$CLIP"
            if avconvert --source "$RAW" --preset "$P" --output "$CLIP" --replace >>"$NOTE" 2>&1 \
                && [ -s "$CLIP" ] && [ "$(size "$CLIP")" -le "$LIMIT" ]; then
                note "avconvert $P: $(size "$CLIP") bytes (the frame may stand on its side)"
                break
            fi
        done
    fi
fi
rm -f "$RAW"
if [ -s "$CLIP" ] && [ "$(size "$CLIP")" -gt "$LIMIT" ]; then
    note "NOTE: the clip is $(size "$CLIP") bytes, over the 8 MB limit; dropped"
    rm -f "$CLIP"
fi
[ -s "$CLIP" ] && note "clip: clip/horde-clip.mp4, $(size "$CLIP") bytes" || note "NOTE: no clip kept"
done_
