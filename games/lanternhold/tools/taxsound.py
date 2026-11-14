#!/usr/bin/env python3
"""The town lane's sound (town-2, docs/TOWN.md section 1 "The knock"): one knuckle knock on a wooden door, mono 16-bit
WAV at 22.05 kHz like every file of Resources/Sound, made with tools/soundsynth.py's helpers and a fixed seed, so a run
writes the same bytes. The game plays it three times for the knock and slower and softer for the shutters closing
(`FeedbackCue.knock`, `.shutter`). No music, a signal only.

    python3 -I games/lanternhold/tools/taxsound.py          # writes Resources/Sound/knock.wav, updates MANIFEST.txt

Run it through the director's art lock on the old Mac (it takes well under a second).
"""
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import soundsynth as ss  # noqa: E402


def knock():
    """Knuckles on an oak door: the board's low thump (about 160 Hz, damped fast), its hollow ring above it, the
    knuckle's dry click, and a breath of the door's frame; 0.22 s."""
    rng = ss.Rng(301)
    n = ss.secs(0.22)
    x = ss.zeros(n)
    # The board: two damped partials of a thick plank and the panel's knock.
    ss.add_into(x, ss.grain(n, 162, 0.035), 0, 1.0)
    ss.add_into(x, ss.grain(n, 248, 0.022), 0, 0.55)
    ss.add_into(x, ss.grain(n, 410, 0.012), 0, 0.3)
    # The knuckle: a short band of noise, dry.
    click = [rng.bipolar() * math.exp(-i / (0.0018 * ss.SR)) for i in range(ss.secs(0.02))]
    click = ss.biquad(click, "bp", 1600, 1.4)
    ss.add_into(x, click, 0, 0.9)
    # The frame answering: a soft low rumble that dies within the knock.
    body = ss.lowpass([rng.bipolar() * math.exp(-i / (0.025 * ss.SR)) for i in range(ss.secs(0.12))], 420)
    ss.add_into(x, body, 0, 0.8)
    return ss.fade(ss.normalize(ss.soft(ss.lowpass(x, 4200), 1.15), 0.86), 0.0008, 0.05)


SOUNDS = [("knock", knock)]


def main():
    path = os.path.join(ss.OUT, "MANIFEST.txt")
    manifest = {}
    order = []
    if os.path.exists(path):
        for line in open(path):
            parts = line.split()
            if len(parts) == 3:
                manifest[parts[0]] = (parts[1], parts[2])
                order.append(parts[0])
    for name, make in SOUNDS:
        digest, size = ss.write_wav(os.path.join(ss.OUT, name + ".wav"), make())
        manifest[name] = (str(size), digest)
        if name not in order:
            order.append(name)
        print(f"wrote {name}.wav {size} bytes {digest[:12]}")
    with open(path, "w") as fh:
        for name in order:
            size, digest = manifest[name]
            fh.write(f"{name} {size} {digest}\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
