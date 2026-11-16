"""The tumbler (POLISH.md section 7, build 3): a scrap of the Ash Giant's cloak rolled up into a wheel that rolls along
the ground. Not a ball: a flattened wheel (12 wide, 10 high) of five rag strips wound round a navy hub, their loose ends
trailing two or three pixels out of the outline and turning with the roll, so each walk frame has an outline of its
own. The head is tucked into the hub and does not turn: one cold point looks out ahead, half under a fold of the rag,
never two, never a face. Its smoke thread rises off the top of the wheel (sootThread.py). To claw it opens low and wide:
it gathers (squats flatter), splits open like a cloak with two hooked claws thrown forward along the ground, and
closes again; never upright, never a flame. 12 px high with its loose ends. (hordekit.py: the art direction.)"""
import math
from rig import Frame, hsh
from hordekit import CELL, limbs, moon

SIZE = (14, 14, 7)
HEIGHT = 12
STRIPS = 5
CX, CY, RX, RY = 6.5, 8.6, 5.9, 4.95      # the wheel: body columns 1 ... 12, rows 4 ... 13 (10 high)


def rag(d, a, x, y, seed):
    """The rag's colour at normalised radius d and turned angle a: five strips wound in a spiral, each a lit band, a
    dark band and a seam; lit from above."""
    u = (a / (2 * math.pi) * STRIPS + d * 0.9) % 1.0
    upper = y < CY - 0.5
    if u > 0.84:
        return "nightDeep"
    if u > 0.52:
        return "soilDark"
    return "moor" if upper or u < 0.22 else "moorDark"


def wheel(f, turn, cx=CX, cy=CY, rx=RX, ry=RY, keep=None, ends=True, seed=7):
    """The wheel turned by `turn` radians (it rolls to the right: clockwise on screen). `keep(x, y)` may leave out
    pixels (the wheel split open). Returns the loose ends' pixels to draw after the outline."""
    for y in range(CELL):
        for x in range(CELL):
            nx, ny = (x - cx) / rx, (y - cy) / ry
            d = math.hypot(nx, ny)
            if d > 1.0 or (keep and not keep(x, y)):
                continue
            if d < 0.32:
                f.put(x, y, "nightBlue" if ny < 0 else "night0")      # the hub
                continue
            f.put(x, y, rag(d, math.atan2(ny, nx) - turn, x, y, seed))
    tails = []
    if ends:
        # each strip's loose end leaves the rim where the strip meets it and trails back against the turn, flung out
        for s in range(STRIPS):
            a0 = turn + (s + 0.15) * 2 * math.pi / STRIPS
            upper = math.sin(a0) < 0.2                                # the ends over the top fly longer
            n = 4 if upper and math.cos(a0) < 0.3 else 3
            for j in range(0, n + 1):
                a = a0 - 0.2 * j
                t = 0.97 + 0.15 * j
                x, y = cx + math.cos(a) * rx * t, cy + math.sin(a) * ry * t
                if y < CELL - 0.5 and -0.5 < x < CELL - 0.5:
                    tails.append((x, y, ("moor", "moorDark", "moor", "moorDark", "soilDark")[j]))
    return tails


def hub(f, sx, sy):
    """The tucked head in the hub, looking out ahead: the socket's cold point (two pixels, the second under it) with a
    fold of the rag over its upper half."""
    f.put(sx, sy, "stoneLight", "wraithWhite")
    f.put(sx, sy + 1, "stoneMid", "wraithGlow")
    f.put(sx - 1, sy + 1, "nightSlate", "wraithDim")
    f.put(sx, sy - 1, "moorDark")                                      # the fold
    f.put(sx + 1, sy - 1, "moor")
    f.put(sx - 1, sy - 1, "soilDark")


PEAK = (6, 4)      # where the thread rises: the wheel's top (the attack frames: `PEAKS`)
PEAKS = [(6, 4), (6, 4), (6, 4), (6, 4), (5, 6), (4, 6), (5, 5)]


def frame(k):
    f = Frame(CELL, CELL, seed=7)
    if k < 4:
        # roll 0-3 at 2 px a frame: a fifth of a turn (one strip) over the cycle, so it loops
        tails = wheel(f, k * 2 * math.pi / STRIPS / 4)
        hub(f, 8, 9)
        f.finish(rim=None)
    elif k == 4:
        # gather: it squats flatter and wider, the claws tucked under its front
        tails = wheel(f, 0.15, cy=9.6, rx=6.3, ry=3.95)
        hub(f, 9, 9)
        f.finish(rim=None)
        limbs(f, [([(11, 12), (12, 13), (13, 13)], "a")])
    elif k == 5:
        # claw: the wheel splits open like a cloak, its rag flung back and low, the hub forward, two hooked claws
        # thrown ahead along the ground
        tails = wheel(f, 0.5, cx=5.2, cy=9.8, rx=5.2, ry=3.8, keep=lambda x, y: x < 7 or y > 10)
        for (x, y) in ((7, 8), (8, 8), (7, 9), (8, 9), (9, 9), (7, 10), (8, 10), (9, 10)):
            f.put(x, y, "nightBlue" if y < 9 else "night0")
        hub(f, 9, 9)
        f.finish(rim=None)
        limbs(f, [([(9, 10), (11, 9), (13, 10)], "L"), ([(13, 10), (13, 11)], "s"),
                  ([(9, 11), (11, 12), (13, 12)], "l"), ([(13, 12), (13, 13)], "a")])
    else:
        # recover: closing again, the claws drawn back under it
        tails = wheel(f, 0.9, cy=9.1, rx=6.1, ry=4.45)
        hub(f, 9, 8)
        f.finish(rim=None)
        limbs(f, [([(11, 12), (12, 13)], "l")])
    for x, y, c in tails:
        xi, yi = int(math.floor(x + 0.5)), int(math.floor(y + 0.5))
        if 0 <= xi < CELL and 0 <= yi < CELL and f.g[yi][xi] is None:
            f.put(xi, yi, c, None, True)                               # over the outline: the end leaves the rim
    return moon(f)
