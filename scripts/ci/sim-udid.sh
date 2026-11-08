#!/bin/sh
# Prints the udid of the simulator the scripts use: $GW_SIM_UDID when it is set, else the booted "iPhone 17 Pro", else the
# first available one. Exit 1 (message on stderr) when there is none; run-check.sh then creates one.
if [ -n "${GW_SIM_UDID:-}" ]; then
    echo "$GW_SIM_UDID"
    exit 0
fi
phones=$(xcrun simctl list devices available 2>/dev/null | grep -E '^ *iPhone 17 Pro \([0-9A-Fa-f-]{36}\)')
line=$(printf '%s\n' "$phones" | grep '(Booted)' | head -1)
[ -n "$line" ] || line=$(printf '%s\n' "$phones" | head -1)
udid=$(printf '%s\n' "$line" | sed -E 's/^ *iPhone 17 Pro \(([0-9A-Fa-f-]{36})\).*/\1/')
if [ -z "$udid" ]; then
    echo 'no available "iPhone 17 Pro" simulator; set GW_SIM_UDID' >&2
    exit 1
fi
echo "$udid"
