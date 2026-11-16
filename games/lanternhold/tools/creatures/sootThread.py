"""The smoke thread of the small ones (POLISH.md section 7, build 3; step 3, the director's call 7: threads are soot,
and fewer): a sootling is a snuffed wick, and from the rag's torn edge at the nape of about every second one rises a
thread of soot. It is smoke, not a stick and never rain: its lower two thirds unbroken and dark (the body's navy lifted
a step, nightHaze, two pixels wide at the root), only its top third breaking into one or two paler wisps with gaps
between. Each thread has a length of its own (the body's height and up to three pixels more, by the creature's id) and
one of three curls (the wisps' side and where they turn, by id), so a file of them never stands ruled and a volley's
orphans are never a row of the same hook. It is its own strip so the engine can lean it: its tip leans up to four
pixels with the wind (Weather.wind), back against the wind while it runs, and it sways about a pixel either side of
that lean, less than the lean, so a calm and a gust differ at a glance; its wisps curl the same in both sway frames.
No outline: smoke. Albedo only, no glow strip; the engine draws it at its own colour (emissive), so it stays soot in
firelight and in the moon.

Frames: ((curl × 8 + length index) × 9 + lean + 4) × 2 + sway, with curl 0 ... 2, length index 0 ... 7 for 10 ... 17 px,
lean -4 ... +4 px at the tip and sway 0 or 1 (the bend to one side, then the other). The root is column 7 of the
bottom row."""
import math
from rig import Frame, hsh

LENGTHS = tuple(range(10, 18))
LEANS = 9
CURLS = 3
SIZE = (15, 18, CURLS * len(LENGTHS) * LEANS * 2)
GLOW = False
FLOATS = True
ROOT = 7
SOOT = "nightHaze"         # the lower two thirds: the body's navy lifted a step
WISP = ("stoneMid", "mistDark")   # the top third, thinning paler


def frame(k):
    sway_side = 1 if k % 2 else -1
    lean = (k // 2) % LEANS - 4
    li = (k // (LEANS * 2)) % len(LENGTHS)
    curl = k // (LEANS * 2 * len(LENGTHS))
    length = LENGTHS[li]
    w, h = SIZE[0], SIZE[1]
    f = Frame(w, h, seed=13)
    phase = (0.0, 2.1, 4.2)[curl] + hsh(li, 3, 29) * 0.8
    broken = int(round(length * 2 / 3))                       # the top third breaks into wisps
    gap_at = broken + (2 if curl == 1 and length >= 12 else 1)
    x_prev = ROOT
    for i in range(length):
        t = i / (length - 1)
        bend = lean * t ** 1.3                                # the wind bends it most toward the tip
        sway = sway_side * (0.5 * math.sin(math.pi * t) + 0.6 * t * t)  # about one pixel either side of the lean
        wobble = 0.5 * math.sin(t * math.pi * 2.0 + phase) * t
        x = ROOT + bend + sway + wobble
        y = h - 1 - i
        if i >= broken:
            if i == gap_at or (i > gap_at + 2 and hsh(i, li + 8 * curl, 37) < 0.4):
                continue                                      # the gaps between the wisps
            u = (i - broken) / max(1, length - broken)
            # the curl, the same in both sway frames: 0 hooks right at the top, 1 left from the middle, 2 an S
            if curl == 0:
                x += 1 if u > 0.55 else 0
            elif curl == 1:
                x -= 1 if u > 0.2 else 0
            else:
                x += (1 if u < 0.5 else -1) if u > 0.15 else 0
            c = WISP[0] if i < length - 2 else WISP[1]
        else:
            c = SOOT
        f.put(x, y, c, None, True)
        if i < 2:                                             # dense at the root: two pixels wide
            f.put(x + (1 if lean >= 0 else -1), y, SOOT, None, True)
        elif i < broken and abs(x - x_prev) >= 1.5:          # unbroken where it bends hard
            f.put((x + x_prev) / 2, y, SOOT, None, True)
        x_prev = x
    return f
