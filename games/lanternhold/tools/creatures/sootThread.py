"""The wisp of soot over the small ones (POLISH.md section 7, build 3; step 4, the director's call 5 of 16.11.2026
06:15: wisps, not poles): a sootling is a snuffed wick, and from the mantle's peak of about every third one rises a
short wisp of soot. It is smoke, never a stick, a reed or rain: never taller than its body (6 to 10 rows, by the
creature's id), two pixels wide at the root narrowing to one, never plumb (it drifts a pixel toward its curl's side
every four or five rows, and wavers), its lower part unbroken soot (the body's navy lifted a step, nightHaze) thinning
paler upward (stoneDark), and its top breaks into two or three loose specks a pixel apart and a pixel aside (stoneMid,
mistDark), so it fades out instead of ending in a hook. Each wisp has one of three curls (the side it drifts to and
how its specks scatter, by id), so a file of them never stands ruled and a volley's orphans never curl alike. It is its
own strip so the engine can lean it: its tip leans up to four pixels with the wind (Weather.wind), back against the
wind while it runs, and it sways about a pixel either side of that lean, less than the lean. No outline: smoke. Albedo
only, no glow strip; the engine draws it at its own colour (emissive), at 0.7 at most, under the body's own fog.

Frames: ((curl × 5 + length index) × 9 + lean + 4) × 2 + sway, with curl 0 ... 2, length index 0 ... 4 for 6 ... 10 px,
lean -4 ... +4 px at the tip and sway 0 or 1. The root is column 7 of the bottom row. Each curl is a strip of its own,
90 frames (1350 px) wide: this one curl 0, sootThreadB.py curl 1 and sootThreadC.py curl 2 (round lh-b3h-32: the
simulator's image decoder refused a strip of 6480 px)."""
import math
from rig import Frame, hsh

LENGTHS = tuple(range(6, 11))
LEANS = 9
CURLS = 3
PER_CURL = len(LENGTHS) * LEANS * 2
SIZE = (15, 12, PER_CURL)   # curl 0; `frame(k)` takes the index over all three curls
GLOW = False
FLOATS = True
ROOT = 7
SOOT = "nightHaze"          # the lower part: the body's navy lifted a step
THIN = "stoneMid"           # thinning paler above it
SPECKS = ("stone", "mistDark")   # the loose specks at the top, paler still


def frame(k):
    sway_side = 1 if k % 2 else -1
    lean = (k // 2) % LEANS - 4
    li = (k // (LEANS * 2)) % len(LENGTHS)
    curl = k // (LEANS * 2 * len(LENGTHS))
    length = LENGTHS[li]
    w, h = SIZE[0], SIZE[1]
    f = Frame(w, h, seed=13)
    side = (1, -1, 1)[curl]                                   # the side it drifts to
    every = (4.0, 4.5, 5.0)[curl]                             # a pixel every four or five rows
    phase = (0.0, 2.1, 4.2)[curl] + hsh(li, 3, 29) * 0.8
    whole = max(4, length - 3)                                # the unbroken part; a gap, then the specks
    x_prev = None
    for i in range(length):
        t = i / max(1, length - 1)
        drift = side * (i + 2.5) / every                      # a pixel every four or five rows, from low down
        bend = lean * t ** 0.8                                # the wind bends it, most toward the tip
        sway = sway_side * (0.35 * math.sin(math.pi * t) + 0.6 * t * t)
        waver = 0.3 * math.sin(t * math.pi * 2.0 + phase) * t
        x = ROOT + drift + bend + sway + waver
        y = h - 1 - i
        if i >= whole:
            # the top breaks: a row of nothing, then one or two loose specks, the first a little to one side and the
            # second to the other (curl 2 the other way round), so it scatters instead of hooking
            if i == whole:
                continue
            n = i - whole - 1
            aside = (0.6 if n % 2 == 0 else -0.9) * (side if curl < 2 else -side)
            f.put(x + aside, y, SPECKS[min(1, n)], None, True)
            continue
        c = THIN if i >= whole - 1 and i >= 2 else SOOT
        f.put(x, y, c, None, True)
        if i == 0:                                            # two pixels wide at the root, behind its drift
            f.put(x - side, y, SOOT, None, True)
        elif x_prev is not None and abs(round(x) - round(x_prev)) >= 2:
            f.put((x + x_prev) / 2, y, c, None, True)        # unbroken where it bends hard
        x_prev = x
    return f
