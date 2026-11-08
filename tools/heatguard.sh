#!/bin/bash
# Stops heavy work when the CPU gets hot, because sustained load powers this old Mac off. Read-only sensor reader: smcread
# (build it with `clang -framework IOKit -o tools/smcread tools/smcread.c` if the binary is missing). Logs to guard.log.
# Start it once per session in the background: tools/heatguard.sh
# Agents' python runs (tuning scripts, optimizers) count as heavy work too: on 08.11. one held the CPU at 74 C.
D="$(cd "$(dirname "$0")" && pwd)"
[ -x "$D/smcread" ] || clang -framework IOKit -o "$D/smcread" "$D/smcread.c" || exit 1
while true; do
  T=$("$D/smcread" | sed -E 's/.*TCXC=([0-9]+).*/\1/')
  if [ "${T:-0}" -ge 85 ] 2>/dev/null; then
    pkill -9 -f 'xcodebuild|swift-frontend|swiftc|Simulator.app|/usr/bin/sips|magick|ffmpeg|python3 '
    echo "$(date '+%d.%m. %H:%M:%S') ${T} C: stopped heavy work" >> "$D/guard.log"
  fi
  /bin/sleep 20
done
