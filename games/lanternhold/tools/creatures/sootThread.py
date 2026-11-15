"""The smoke thread of the small ones (POLISH.md section 7, build 3): a sootling is a snuffed wick, and from the torn
peak of its hood rises a thread of smoke one pixel wide and as long as the body is high. It is its own strip so the
engine can lean it: with the wind (Weather.wind), back when the body runs, straight when it waits. Its root is soot,
it pales as it rises and frays at the top. No outline: smoke. Albedo only, no glow strip; the engine draws it as a
pale emissive at a low value, so the horde reads as a field of threads at night before its bodies are seen.

Frames: (length * 5 + lean) * 2 + sway, with length 0, 1, 2 for 10, 12 and 14 px (the crawler, the tumbler, the
loper), lean 0 ... 4 for a tip at -2 ... +2 px, and sway 0 or 1 (the thread's middle bends one way, then the other).
The root is column 3 of the bottom row."""
import math
from rig import Frame, hsh

SIZE = (7, 14, 30)
GLOW = False
FLOATS = True
LENGTHS = (10, 12, 14)
ROOT = 3


def frame(k):
    length = LENGTHS[k // 10]
    lean = (k // 2) % 5 - 2
    sway = k % 2
    f = Frame(7, 14, seed=13)
    for i in range(length):
        t = i / (length - 1)
        bend = 0.8 * math.sin(t * math.pi * 1.5 + sway * math.pi) * (0.3 + 0.7 * t)
        x = ROOT + lean * t ** 1.6 + bend
        y = 13 - i
        if t > 0.72 and hsh(i, sway, k // 10 + 21) < 0.38 + 0.6 * (t - 0.72):
            continue                                            # it frays at the top
        if i < 2:
            c = "nightSlate"
        elif t < 0.3:
            c = "mistDark"
        elif t < 0.62:
            c = "mistLight" if i % 3 == 1 else "mist"
        elif t < 0.85:
            c = "mist"
        else:
            c = "mistDark"
        f.put(x, y, c, None, True)
    return f
