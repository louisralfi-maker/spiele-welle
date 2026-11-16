#!/bin/bash
# A 10 s clip of the horde on the simulator, for a round's sh step (Lanternhold build 3, lane 4, POLISH.md 6.6: motion
# is judged from clips, at full speed and at a quarter):
#   do: sh bash ../../scripts/ci/sim-clip.sh
# run-check.sh runs a sh step from the game's folder (games/<slug>) after booting the simulator, with REPO, CI_OUT,
# GAME_DIR, PROJECT, SCHEME and SIM exported. Put it after the build (it installs the Debug app from build/SimData)
# and after a ui step (which leaves the simulator turned to landscape). This script:
#   1. launches night 12 of the demo realm live at 23:00 with the horde's proof (step 2, Debug only: `-GWHorde
#      dark`, `HordeProof`: no archers, the outer line's fires out, one wave strung out from deep in the bank, twelve
#      already at the outer wall and, step 3, a stream of sixty more through the battle's spawn queue, one a second
#      for a minute), the lord behind the outer wall (x 660), so the camera holds the bank's edge, the
#      open and the wall, clear of the Dynamic Island. The night then runs at its own speed (12 s a game hour): the
#      small ones step out of the bank, cross the open and climb the heap while the catapult's firepots fall on it;
#   2. waits until the world is on screen, then records 10 s with `xcrun simctl io recordVideo`. The simulator shows
#      the home screen before the launch (as big a PNG as the world), so the wait first takes the home screen's size,
#      waits for the launch call to return, and then needs two probes in a row, at least 3 s later, that are over
#      250 KB and differ from the home screen by more than a tenth (the launch colour and the black before the first
#      frame are a few KB). Step 3: then it waits until the app's own value probe (tmp/horde-probe.txt in its data
#      container, `HordeProof.probe`) says ten or more small ones are drawn, and records 10 s by the clock from the
#      recorder's "Recording started". The recorder is stopped with a time limit, so a stuck recording never holds
#      the round;
#   3. turns it upright (the simulator records its portrait frame buffer: the game stands on its side in it) at the
#      shape of 2622 x 1206, 1310 x 602, under 8 MB, in $CI_OUT/clip/horde-clip.mp4: with ffmpeg when the runner has it
#      or brew can bottle it within 5 minutes, else with scripts/ci/clip-turn.swift (AVFoundation), else shrunk with
#      avconvert as it stands; clip-note.txt says which worked; plus a still at its end;
#   4. pulls three stills from the upright clip at 1, 4 and 7 s (horde-clip-1s.png ...) and sets them side by side
#      (horde-clip-stills.png), so the gate sees what the clip holds before it reports.
# Step 4 (the director's call 7, the clip shows the horde): the proof places the lord itself, a lantern's reach behind
# the outer wall (x 680, `HordeProof.lordX`: the camera's danger lead then holds the open and the heap, and his light
# burns none of them), holds the night's clock at 23:00, keeps the stream coming out of the bank's edge at one a
# second and the outer line's catapult silent (`HordeProof.drive`). Recording waits 5 s more after the probe's ten, so
# the stream has run before the clip starts; the app's value probe is read again at 1, 4 and 7 s of the recording and
# noted beside the stills ("clip probe <t> s: ..."), and the note says "NO HORDE" in its last line unless each of the
# three says seen >= 8.
# Step 5 (the director's call 3: a horde, not a file): the stream comes in spawns of their own gaps, clumps and paces
# (`HordeProof.spawnStream`, a stand-in for the packs of step B), each probe also says open:<n> (the small ones crossing
# the open, not the heap), and NO HORDE stands unless open >= 8 too; the upright clip loses its left 80 px (M5: the
# simulator's sensor pill), cut with as much of the top and bottom as keeps its shape. (clip-turn.swift, the fallback
# when ffmpeg is missing, does not cut it.)
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

CLIP_HOUR=23.0
note "start hour: $CLIP_HOUR, held; the horde's proof (dark), the lord a lantern's reach behind the outer wall"

# 1. The live night. The launch call can take 15 s on the runner; it returns once the process runs (at most 90 s here).
xcrun simctl launch "$SIM" "$BUNDLE" -GWNight 12 -GWHour "$CLIP_HOUR" -GWBuild demo -GWHorde dark:0 \
    -GWLook 2 -GWWeather breeze >"$OUT/launch.txt" 2>&1 &
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
note "== $(date +%H:%M:%S) the world is on screen after $(( $(date +%s) - START )) s"

# 2b. Step 3 (the director's call 9): the clip must show the horde. The app itself counts the small ones it draws (a
# `dark` proof writes `seen:<n> hour:<h>` into tmp/horde-probe.txt of its data container every quarter second,
# `HordeProof.probe`); recording starts once it says seen >= 10 (at most 90 s), else it records anyway and says so.
DATA=$(xcrun simctl get_app_container "$SIM" "$BUNDLE" data 2>/dev/null)
PROBE=""
[ -n "$DATA" ] && [ -d "$DATA" ] && PROBE="$DATA/tmp/horde-probe.txt"
[ -n "$PROBE" ] || note "NOTE: no data container for $BUNDLE: no value probe"
seen_now() { sed -nE 's/.*seen:([0-9]+).*/\1/p' "$PROBE" 2>/dev/null | head -1; }
SEEN=""
BEST=0
WAITED=$(date +%s)
while [ $(( $(date +%s) - WAITED )) -lt 90 ]; do
    SEEN=$(seen_now)
    [ -n "$SEEN" ] && [ "$SEEN" -gt "$BEST" ] && BEST=$SEEN
    [ -n "$SEEN" ] && [ "$SEEN" -ge 10 ] && break
    sleep 0.5
done
if [ -n "$SEEN" ] && [ "$SEEN" -ge 10 ]; then
    note "== $(date +%H:%M:%S) value probe: $(head -1 "$PROBE"); the stream runs 5 s more, then recording 10 s"
    sleep 5
else
    note "NOTE: HORDE NOT SEEN: the value probe never said seen >= 10 in 90 s (best ${BEST}, file ${PROBE:-none}:" \
        "$(head -1 "$PROBE" 2>/dev/null)); recording anyway"
fi
rm -f "$RAW"
xcrun simctl io "$SIM" recordVideo --codec=h264 --force "$RAW" >"$OUT/record.txt" 2>&1 &
RECORDER=$!
# 10 s by the clock from the moment the recorder says it records (it takes a second or two to start).
for _ in $(seq 40); do grep -q "Recording started" "$OUT/record.txt" 2>/dev/null && break; sleep 0.5; done
grep -q "Recording started" "$OUT/record.txt" 2>/dev/null || note "NOTE: the recorder never said it started"
REC0=$(date +%s)
# Step 4: the value probe at 1, 4 and 7 s of the recording, beside the stills; each must say seen >= 8. Step 5 (the
# director's call 3): and open >= 8, the small ones crossing the open (`HordeProof.inTheOpen`), not the heap.
LOW=""
probe_at() {
    local line n o
    line=$(head -1 "$PROBE" 2>/dev/null)
    n=$(echo "$line" | sed -nE 's/.*seen:([0-9]+).*/\1/p')
    o=$(echo "$line" | sed -nE 's/.*open:([0-9]+).*/\1/p')
    note "clip probe $1 s: ${line:-none}"
    if [ -z "$n" ] || [ "$n" -lt 8 ] || [ -z "$o" ] || [ "$o" -lt 8 ]; then LOW="$LOW $1"; fi
}
sleep 1; probe_at 1
sleep 3; probe_at 4
sleep 3; probe_at 7
sleep 3.5
note "recorded from $(date -r "$REC0" +%H:%M:%S) for $(( $(date +%s) - REC0 )) s by the clock; probe at the end:" \
    "$(head -1 "$PROBE" 2>/dev/null)"
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

# 3. Upright and small: 1310 x 602 (2622 x 1206's shape, even sides), the game standing as it is played.
CLIP_W=1310
CLIP_H=602
# Runs "$@" in the background for at most $1 seconds (macOS has no timeout(1)); 0 when it finished in time and well.
capped() {
    local limit=$1
    shift
    "$@" >>"$NOTE" 2>&1 &
    local pid=$! start=$(date +%s)
    while kill -0 "$pid" 2>/dev/null; do
        if [ $(( $(date +%s) - start )) -ge "$limit" ]; then
            kill "$pid" 2>/dev/null; sleep 2; kill -9 "$pid" 2>/dev/null
            note "NOTE: $1 took over $limit s and was stopped"
            return 1
        fi
        sleep 2
    done
    wait "$pid"
}
if ! command -v ffmpeg >/dev/null 2>&1 && command -v brew >/dev/null 2>&1; then
    note "== $(date +%H:%M:%S) no ffmpeg: brew install ffmpeg (at most 300 s)"
    HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_INSTALL_CLEANUP=1 capped 300 brew install --quiet ffmpeg \
        || note "NOTE: brew could not install ffmpeg"
fi
if command -v ffmpeg >/dev/null 2>&1; then
    # A portrait buffer turns a quarter counterclockwise (transpose=2): the world's west to the left, the ground down.
    TURN=""
    DIMS=$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=p=0 "$RAW" 2>/dev/null)
    W=${DIMS%%,*}
    H=${DIMS##*,}
    if [ -n "$W" ] && [ -n "$H" ] && [ "$H" -gt "$W" ] 2>/dev/null; then TURN="transpose=2,"; fi
    # The coded size decides the turn, so a rotation tag must not turn it a second time (-noautorotate); the tag is
    # noted for the record.
    ROT=$(ffprobe -v error -select_streams v:0 -show_entries stream_side_data=rotation -of csv=p=0 "$RAW" 2>/dev/null \
        | tr -d '\n')
    note "recorded frame ${DIMS:-?}, rotation tag: ${ROT:-none}"
    # Step 5 (M5): the simulator's sensor pill stands in the left 80 px of the upright clip: cut off with as much of
    # the top and the bottom as keeps the shape, then scaled back (a 6.5 % zoom).
    if capped 180 ffmpeg -y -v error -noautorotate -i "$RAW" \
        -vf "${TURN}scale=$CLIP_W:$CLIP_H,crop=$((CLIP_W - 80)):$((CLIP_H * (CLIP_W - 80) / CLIP_W / 2 * 2)):80:$((CLIP_H * 40 / CLIP_W)),scale=$CLIP_W:$CLIP_H" \
        -c:v libx264 -crf 24 \
        -preset veryfast -pix_fmt yuv420p -an -movflags +faststart "$CLIP"; then
        note "upright with ffmpeg: ${DIMS:-?} -> ${CLIP_W}x${CLIP_H}${TURN:+, turned}: $(size "$CLIP") bytes"
    else
        note "NOTE: ffmpeg failed"
        rm -f "$CLIP"
    fi
fi
if [ ! -s "$CLIP" ] && command -v swift >/dev/null 2>&1; then
    TURNER="${REPO:-$(cd "$(dirname "$0")/../.." && pwd)}/scripts/ci/clip-turn.swift"
    note "== $(date +%H:%M:%S) turning with $TURNER"
    if capped 300 swift "$TURNER" "$RAW" "$CLIP" "$CLIP_W" "$CLIP_H" && [ -s "$CLIP" ]; then
        note "upright with clip-turn.swift: $(size "$CLIP") bytes"
    else
        note "NOTE: clip-turn.swift failed"
        rm -f "$CLIP"
    fi
fi
if [ -s "$CLIP" ] && [ "$(size "$CLIP")" -gt "$LIMIT" ]; then
    note "NOTE: the upright clip is $(size "$CLIP") bytes, over 8 MB; shrinking it with avconvert"
    mv "$CLIP" "$OUT/upright.mp4"
    for P in Preset960x540 Preset640x480; do
        rm -f "$CLIP"
        if avconvert --source "$OUT/upright.mp4" --preset "$P" --output "$CLIP" --replace >>"$NOTE" 2>&1 \
            && [ -s "$CLIP" ] && [ "$(size "$CLIP")" -le "$LIMIT" ]; then
            note "avconvert $P on the upright clip: $(size "$CLIP") bytes"
            break
        fi
    done
    rm -f "$OUT/upright.mp4"
fi
if [ ! -s "$CLIP" ]; then
    if [ "$(size "$RAW")" -le "$LIMIT" ]; then
        cp "$RAW" "$CLIP"
        note "NOTE: kept as recorded (nothing could turn it: it stands on its side)"
    else
        for P in Preset1280x720 Preset960x540; do
            rm -f "$CLIP"
            if avconvert --source "$RAW" --preset "$P" --output "$CLIP" --replace >>"$NOTE" 2>&1 \
                && [ -s "$CLIP" ] && [ "$(size "$CLIP")" -le "$LIMIT" ]; then
                note "NOTE: avconvert $P as recorded: $(size "$CLIP") bytes (nothing could turn it: on its side)"
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

# 4. Step 3 (call 9: nobody sends a clip that nobody watched): three stills from the upright clip at 1, 4 and 7 s, and
# the three side by side, so the gate sees what the clip holds without playing it.
if [ -s "$CLIP" ] && command -v ffmpeg >/dev/null 2>&1; then
    LEN=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$CLIP" 2>/dev/null)
    note "clip length: ${LEN:-?} s"
    for T in 1 4 7; do
        capped 60 ffmpeg -y -v error -ss "$T" -i "$CLIP" -frames:v 1 "$OUT/horde-clip-${T}s.png" \
            || note "NOTE: no still at $T s"
    done
    if [ -s "$OUT/horde-clip-1s.png" ] && [ -s "$OUT/horde-clip-4s.png" ] && [ -s "$OUT/horde-clip-7s.png" ]; then
        capped 60 ffmpeg -y -v error -i "$OUT/horde-clip-1s.png" -i "$OUT/horde-clip-4s.png" -i "$OUT/horde-clip-7s.png" \
            -filter_complex "[0][1][2]hstack=inputs=3" "$OUT/horde-clip-stills.png" \
            && note "stills: clip/horde-clip-1s.png, -4s.png, -7s.png and side by side clip/horde-clip-stills.png" \
            || note "NOTE: the stills could not be put side by side"
    fi
else
    note "NOTE: no stills (no clip or no ffmpeg)"
fi
if [ -z "$LOW" ]; then
    note "clip probes: seen >= 8 and open >= 8 at 1, 4 and 7 s"
else
    note "NO HORDE: the value probe said seen < 8 or open < 8 (or nothing) at the clip's${LOW} s"
fi
done_
