"""The smoke thread of the small ones (POLISH.md section 7, build 3): a sootling is a snuffed wick, and from the rag's
torn edge at its nape rises a thread of smoke. It is smoke, not a stick: dense at the root (two pixels wide, its
palest value), thinning as it rises, curling, and its top third broken into wisps of one or two pixels with gaps
between. Each thread has a length of its own (the body's height and up to three pixels more, by the creature's id), so a
file of them never stands ruled. It is its own strip so the engine can lean it: its tip leans up to four pixels with
the wind (Weather.wind), back against the wind while it runs, and it sways about a pixel either side of that lean,
less than the lean, so a calm and a gust differ at a glance; its wisps curl the same in both sway frames. No
outline: smoke. Albedo only, no glow strip; the engine draws it as a pale emissive at a low value, so the horde reads
as a field of threads at night before its bodies are seen.

Frames: (length index × 9 + lean + 4) × 2 + sway, with length index 0 ... 7 for 10 ... 17 px, lean -4 ... +4 px at the
tip and sway 0 or 1 (the bend to one side, then the other). The root is column 7 of the bottom row."""
import math
from rig import Frame, hsh

LENGTHS = tuple(range(10, 18))
LEANS = 9
SIZE = (15, 18, len(LENGTHS) * LEANS * 2)
GLOW = False
FLOATS = True
ROOT = 7


def frame(k):
    li = k // (LEANS * 2)
    length = LENGTHS[li]
    lean = (k // 2) % LEANS - 4
    side = 1 if k % 2 else -1
    w, h = SIZE[0], SIZE[1]
    f = Frame(w, h, seed=13)
    curl = hsh(li, 3, 29) * math.pi * 2                       # each length its own curl
    broken = int(length * 0.64)                              # the top third breaks into wisps
    gap_at = broken + 1 + int(hsh(li, 5, 31) * 2)
    x_prev = ROOT
    for i in range(length):
        t = i / (length - 1)
        bend = lean * t ** 1.3                                # the wind bends it most toward the tip
        sway = side * (0.5 * math.sin(math.pi * t) + 0.6 * t * t)  # about one pixel either side of the lean
        wobble = 0.6 * math.sin(t * math.pi * 2.3 + curl) * t
        x = ROOT + bend + sway + wobble
        y = h - 1 - i
        if i >= broken:
            if i == gap_at or (i > gap_at + 2 and hsh(i, li, 37) < 0.45):
                continue                                      # the gaps between the wisps
            curl_at = hsh(i, li, 41)                          # a wisp curls aside, the same in both sway frames
            if curl_at < 0.25:
                x += 1
            elif curl_at < 0.5:
                x -= 1
            c = "mistDark" if i < length - 2 else "nightHaze"
        elif i < 2:
            c = "mistLight" if i == 0 else "mist"
        elif t < 0.34:
            c = "mist"
        else:
            c = "mistDark" if hsh(i, li, 43) < 0.7 else "mist"
        f.put(x, y, c, None, True)
        if i < 2:                                             # dense at the root: two pixels wide
            f.put(x + (1 if lean >= 0 else -1), y, "mistDark", None, True)
        elif i < broken and abs(x - x_prev) >= 1.5:          # no holes where it bends hard
            f.put((x + x_prev) / 2, y, "mistDark", None, True)
        x_prev = x
    return f
