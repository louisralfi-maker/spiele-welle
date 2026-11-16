#!/usr/bin/env python3
"""The wind lane's sounds (build 3, POLISH pass 1 step 3, docs/POLISH.md 2 item 8; lane 3): what the wind does to cloth
and wood, mono 16-bit WAV at 22.05 kHz like every file of Resources/Sound, made with tools/soundsynth.py's helpers
and fixed seeds, so a run writes the same bytes. Short, quiet and rare in the game (`WindSound`): no loop, no music, no
melody, signals only.

- banner_snap: a storm's gust catching a flag or banner on the screen: a heavy cloth cracking taut twice (a sharp
  band of noise, then a softer flap after it), 0.24 s.
- shutter_rattle: a gust in the town shaking a loose shutter in its frame: four to six small dry knocks of a thin
  board, uneven in time and weight, 0.42 s.

    python3 -I games/lanternhold/tools/windsound.py              # writes the two wavs, prints their MANIFEST lines
    python3 -I games/lanternhold/tools/windsound.py --manifest   # also updates MANIFEST.txt (the joiner's step:
                                                                 # MANIFEST.txt belongs to the count lane in wave 1)

Run it through the director's art lock on the old Mac (it takes well under a second).
"""
import argparse
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import soundsynth as ss  # noqa: E402


def flap(rng, length, centre, q, tau, g):
    """One crack of cloth: a burst of noise with a hard front, band-passed round `centre` and dying over `tau`."""
    n = ss.secs(length)
    burst = [rng.bipolar() * math.exp(-i / (tau * ss.SR)) for i in range(n)]
    return ss.gain(ss.biquad(burst, "bp", centre, q), g)


def banner_snap():
    """Wool cloth snapping taut in a gust: the crack (bright, 6 ms), the body of the cloth answering lower, then a
    second, softer flap 70 ms later as the fly whips back; 0.24 s."""
    rng = ss.Rng(731)
    n = ss.secs(0.24)
    x = ss.zeros(n)
    ss.add_into(x, flap(rng, 0.05, 1900, 1.1, 0.006, 1.0), 0, 1.0)
    ss.add_into(x, flap(rng, 0.12, 520, 0.8, 0.03, 1.0), ss.secs(0.004), 0.75)
    ss.add_into(x, flap(rng, 0.04, 1500, 1.0, 0.005, 1.0), ss.secs(0.07), 0.5)
    ss.add_into(x, flap(rng, 0.10, 430, 0.8, 0.025, 1.0), ss.secs(0.074), 0.4)
    # The air round it: a short breath of the gust itself, low and soft.
    air = ss.lowpass([rng.bipolar() * math.exp(-i / (0.07 * ss.SR)) for i in range(ss.secs(0.2))], 700)
    ss.add_into(x, air, 0, 0.35)
    return ss.fade(ss.normalize(ss.soft(ss.lowpass(x, 5200), 1.1), 0.8), 0.0006, 0.06)


def shutter_rattle():
    """A loose shutter knocking in its frame: small knocks of a thin board (two damped partials and a dry click each),
    at uneven times and weights, the last ones fading; 0.42 s."""
    rng = ss.Rng(733)
    n = ss.secs(0.42)
    x = ss.zeros(n)
    times = [0.0, 0.055, 0.12, 0.165, 0.245, 0.33]
    weights = [1.0, 0.6, 0.85, 0.45, 0.55, 0.3]
    for t, w in zip(times, weights):
        start = ss.secs(t + rng.uniform(-0.006, 0.006))
        k = ss.secs(0.06)
        knock = ss.zeros(k)
        ss.add_into(knock, ss.grain(k, 290 + rng.uniform(-20, 20), 0.012), 0, 1.0)
        ss.add_into(knock, ss.grain(k, 640 + rng.uniform(-40, 40), 0.006), 0, 0.45)
        click = ss.biquad([rng.bipolar() * math.exp(-i / (0.0012 * ss.SR)) for i in range(ss.secs(0.012))],
                          "bp", 2300, 1.6)
        ss.add_into(knock, click, 0, 0.5)
        ss.add_into(x, knock, start, w)
    return ss.fade(ss.normalize(ss.soft(ss.lowpass(x, 4600), 1.1), 0.7), 0.0006, 0.08)


SOUNDS = [("banner_snap", banner_snap), ("shutter_rattle", shutter_rattle)]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--manifest", action="store_true", help="also write the files' lines into MANIFEST.txt")
    args = ap.parse_args()
    lines = {}
    for name, make in SOUNDS:
        digest, size = ss.write_wav(os.path.join(ss.OUT, name + ".wav"), make())
        lines[name] = f"{name} {size} {digest}"
        print(f"MANIFEST {lines[name]}")
    if args.manifest:
        path = os.path.join(ss.OUT, "MANIFEST.txt")
        kept = [line.rstrip("\n") for line in open(path) if line.split() and line.split()[0] not in lines]
        with open(path, "w") as fh:
            for line in kept + [lines[name] for name, _ in SOUNDS]:
                fh.write(line + "\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
