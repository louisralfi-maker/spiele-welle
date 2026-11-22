#!/usr/bin/env python3
"""The polish pass's sounds (polish-audit.md law 4, "Sounds"; lane D, step D1 "the night's weight"), made with
tools/soundsynth.py's helpers: mono 16-bit WAV at 22.05 kHz like every file of Resources/Sound, a fixed seed per
sound, so a run writes the same bytes and MANIFEST.txt's sha256 can check it. Signals only, never music, never a word.

    python3 -I games/lanternhold/tools/polishsound.py man_fall     # one file (the old Mac: one per call, artlock.sh)
    python3 -I games/lanternhold/tools/polishsound.py --list

D1's files:
- man_fall: a body on packed earth (90 Hz) and a chink of mail, 0.45 s (a man falls; step 3).
- grunt_1, grunt_2: a soldier struck, a short wordless "hff", 0.12 s: a breath and a body, no tune (a man hit; step 2).
- wall_crack: stone splitting at 3 kHz, then grit, 0.5 s (a wall below half; step 3).
The re-made wall_break (its 55 Hz sub thud) stays in soundsynth.py, where the old one was.
"""
import math
import os
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import soundsynth as ss  # noqa: E402


def thump(n, f0, f1, tau, sweep=0.05):
    """A low body blow: a sine falling from f0 to f1 over `sweep` s, damped with `tau`, a 3 ms attack."""
    tone = ss.sine(n, lambda t: f1 + (f0 - f1) * max(0.0, 1.0 - t / sweep))
    return ss.mul(tone, ss.decay(n, tau, attack=0.003))


def man_fall():
    """A man falls (F5): a body hitting packed earth, a low thud at 90 Hz (tau 0.08 s) with the dull earth burst above
    it; a softer second thud 0.09 s later (the shoulders and legs come down after the hips); a short chink of mail,
    three grains between 2.4 and 3.1 kHz inside 0.15 s; no voice; 0.45 s."""
    rng = ss.Rng(401)
    x = ss.zeros(ss.secs(0.45))
    n = ss.secs(0.4)
    ss.add_into(x, thump(n, 135, 90, 0.08), 0, 1.0)
    earth = ss.lowpass(ss.lowpass([rng.bipolar() * math.exp(-i / (0.03 * ss.SR)) for i in range(n)], 520), 520)
    ss.add_into(x, earth, 0, 2.6)
    ss.add_into(x, thump(n, 120, 82, 0.06), ss.secs(0.09), 0.55)
    second = ss.lowpass([rng.bipolar() * math.exp(-i / (0.025 * ss.SR)) for i in range(n)], 420)
    ss.add_into(x, second, ss.secs(0.09), 1.3)
    # The mail: three small rings struck as the body lands and settles (no pitch to follow: three different grains).
    for at, f, g in ((0.012, 2450.0, 0.34), (0.058, 3080.0, 0.26), (0.128, 2720.0, 0.2)):
        m = ss.secs(0.07)
        ring = ss.grain(m, f, 0.014, rng, noisy=0.35)
        ring2 = ss.grain(m, f * 1.37, 0.008, rng, noisy=0.5)
        ss.add_into(x, ring, ss.secs(at), g)
        ss.add_into(x, ring2, ss.secs(at), g * 0.5)
    # The grit of the earth under him, short.
    dust = ss.highpass([rng.bipolar() * math.exp(-i / (0.05 * ss.SR)) for i in range(ss.secs(0.2))], 1800)
    ss.add_into(x, dust, ss.secs(0.004), 0.08)
    return ss.fade(ss.normalize(ss.soft(ss.lowpass(x, 6000), 1.9)), 0.001, 0.08)


def grunt(seed, f1, f2, pitch0, pitch1):
    """A soldier struck: the blow on his body (a short low knock) and the breath pushed out of him through a closed
    throat, "hff": noise through two formants with only a little buzz, the buzz falling an octave in 0.06 s so no pitch
    stands to be heard as a sung note; 0.12 s, no word, no scream."""
    rng = ss.Rng(seed)
    n = ss.secs(0.12)
    x = ss.zeros(n)
    breath = ss.formant_voice(n, rng, lambda t: f1 - 900 * t, lambda t: f2 - 1500 * t, q=4.0,
                              pitch=lambda t: pitch1 + (pitch0 - pitch1) * max(0.0, 1.0 - t / 0.06), breath=0.8)
    env = [min(1.0, i / (0.006 * ss.SR)) * math.exp(-max(0.0, i / ss.SR - 0.006) / 0.032) for i in range(n)]
    ss.add_into(x, ss.lowpass(ss.mul(breath, env), 2400), 0, 1.0)
    body = ss.mul(ss.sine(n, lambda t: 150 - 50 * min(1.0, t / 0.03)), ss.decay(n, 0.022, attack=0.002))
    ss.add_into(x, body, 0, 0.55)
    knock = ss.lowpass([rng.bipolar() * math.exp(-i / (0.006 * ss.SR)) for i in range(ss.secs(0.03))], 900)
    ss.add_into(x, knock, 0, 0.6)
    return ss.fade(ss.normalize(ss.soft(x, 1.6)), 0.001, 0.03)


def grunt_1():
    return grunt(411, 520.0, 960.0, 118.0, 62.0)


def grunt_2():
    return grunt(412, 460.0, 840.0, 104.0, 55.0)


def wall_crack():
    """A wall below half (F11): stone splitting. Two bright cracks (a band at 3 kHz over a dry click) 0.03 s apart,
    the block's low groan under them (a low body for the step's weight), then grit trickling out of the split; 0.5 s."""
    rng = ss.Rng(421)
    x = ss.zeros(ss.secs(0.5))
    for at, g in ((0.0, 1.0), (0.031, 0.7)):
        m = ss.secs(0.06)
        burst = [rng.bipolar() * math.exp(-i / (0.004 * ss.SR)) for i in range(m)]
        ss.add_into(x, ss.biquad(burst, "bp", 3000, 3.5), ss.secs(at), 2.4 * g)
        ss.add_into(x, ss.highpass(burst, 1500), ss.secs(at), 0.5 * g)
    n = ss.secs(0.3)
    ss.add_into(x, thump(n, 170, 120, 0.07, sweep=0.04), 0, 0.75)
    groan = ss.lowpass([rng.bipolar() * math.exp(-i / (0.05 * ss.SR)) for i in range(n)], 700)
    ss.add_into(x, groan, 0, 1.1)
    # The grit: small stones and sand out of the crack, thinning out.
    for k in range(18):
        t = 0.04 + 0.38 * (rng.random() ** 1.6)
        m = ss.secs(0.05)
        stone = ss.grain(m, rng.uniform(1400, 4200), rng.uniform(0.004, 0.012), rng, noisy=0.5)
        ss.add_into(x, stone, ss.secs(t), 0.32 * rng.uniform(0.3, 1.0) * (1.0 - 0.7 * (t - 0.04) / 0.38))
    sand = ss.highpass([rng.bipolar() for _ in range(ss.secs(0.42))], 2200)
    env = [min(1.0, i / (0.02 * ss.SR)) * math.exp(-i / (0.12 * ss.SR)) for i in range(len(sand))]
    ss.add_into(x, ss.mul(sand, env), ss.secs(0.035), 0.14)
    return ss.fade(ss.normalize(ss.soft(ss.lowpass(x, 7000), 1.5)), 0.0005, 0.06)


SOUNDS = [("man_fall", man_fall), ("grunt_1", grunt_1), ("grunt_2", grunt_2), ("wall_crack", wall_crack)]


def main(argv):
    if "--list" in argv:
        for name, _ in SOUNDS:
            print(name)
        return 0
    wanted = [a for a in argv if not a.startswith("-")]
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
        if wanted and name not in wanted:
            continue
        ss.cool_down()
        began = time.time()
        x = ss.without_dc(name, make())
        digest, size = ss.write_wav(os.path.join(ss.OUT, name + ".wav"), x)
        manifest[name] = (str(size), digest)
        if name not in order:
            order.append(name)
        print(f"{name:14s} {len(x) / ss.SR:5.2f} s {size / 1024:7.1f} KB  {time.time() - began:5.1f} s", flush=True)
    with open(path, "w") as fh:
        for name in order:
            size, digest = manifest[name]
            fh.write(f"{name} {size} {digest}\n")
    total = sum(int(manifest[n][0]) for n in order)
    print(f"total {total} bytes in {len(order)} files")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
