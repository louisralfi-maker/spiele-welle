"""The tumbler (POLISH.md section 7, build 3): a wheel of peat-brown rags and soot that rolls along the ground, torn
strips flying off its rim as it turns. The hooded head is tucked into its hub and does not turn: one socket with a
cold point of light looks out ahead. Its smoke thread rises off the top of the wheel (sootThread.py). It unfolds to
claw: the rags open like a burst and two hooked arms reach out of it, then strike down. 12 px high.
(ART-look2.md 14: no face, never two eyes, nothing of a child.)"""
import math
from rig import Frame, RAG, hsh
from hordekit import CELL, limbs

SIZE = (14, 14, 6)
HEIGHT = 12
CX, CY, R = 6.5, 8.0, 5.0          # the wheel: its body rows 3 ... 13 (the outline adds row 2: 12 px high)
SPOKES = 4                          # four rag strips round the wheel: a quarter turn repeats it
SOOT = ["nightDeep", "night0", "nightBlue", "nightSlate"]


def wheel(f, turn):
    """The wheel turned by `turn` radians (it rolls to the right: clockwise on screen)."""
    for y in range(CELL):
        for x in range(CELL):
            dx, dy = x - CX, y - CY
            d = math.hypot(dx, dy)
            if d > R + 0.35:
                continue
            a = math.atan2(dy, dx) - turn
            band = math.sin(a * SPOKES + d * 0.75)          # rag strips wound in a spiral
            lit = (-dx * 0.35 - dy * 0.94) / max(1.0, d)    # the light from above, a little behind
            ramp = RAG if band > 0.55 else SOOT
            lvl = lit * 0.8 + (0.3 if band > 0.55 else -0.1) + (hsh(x, y, 61) - 0.5) * 0.2
            i = 1 if lvl < -0.25 else (3 if lvl > 0.5 else 2)
            if d > R - 0.8 and lit < 0:
                i = max(0, i - 1)
            f.put(x, y, ramp[i])
    # torn strips flying off the rim, turning with the wheel and trailing back against the turn like a pinwheel's
    for s in range(SPOKES + 2):
        a0 = turn + s * 2 * math.pi / (SPOKES + 2) + 0.35
        n = 3 if s % 2 == 0 else 2
        for j in range(n):
            t = R + 0.7 + j * 0.9
            a = a0 - j * 0.32
            x, y = CX + math.cos(a) * t, CY + math.sin(a) * t
            if 2.5 < y < CELL - 0.5 and -0.5 < x < CELL - 0.5:
                f.put(x, y, ("moorDark", "soilDark", "nightBlue")[j], None, j == 2)


def hub(f, peak_y):
    """The tucked head in the hub, looking out ahead: the hood's mouth and the socket; the peak mark for the thread
    on the wheel's top."""
    f.stamp(7, 6, ["Hhh.",
                   "hgnn",
                   "gnEe",
                   ".nnh"],
            {"H": "nightSlate", "h": "nightBlue", "n": "nightDeep", "g": ("nightSlate", "wraithDim"),
             "E": ("stoneLight", "wraithWhite"), "e": ("stoneMid", "wraithGlow")})


PEAK = (6, 3)      # where the thread rises: the wheel's top


def frame(k):
    f = Frame(CELL, CELL, seed=7)
    if k < 4:
        # roll 0-3 at 2 px a frame (a 5 px wheel turns 22.5 degrees in 2 px): a quarter turn over the cycle
        wheel(f, k * math.pi / 2 / 4)
        hub(f, 3)
        f.finish(rim=None)
        return f
    if k == 4:
        # unfolding: the rags open upward behind, the head rises out of the hub, two hooked arms reach ahead
        wheel(f, 0.4)
        for x in range(CELL):
            for y in range(0, 7):
                if x < 10:
                    f.erase(x, y)
        # the rags flung open behind and up, a fan of torn strips out of the hub
        for (tx, ty, c) in ((0, 2, "moor"), (2, 0, "moorDark"), (4, 1, "moor"), (6, 2, "soilDark"),
                            (1, 5, "moorDark")):
            f.line((6, 7), (tx, ty), c)
            f.line((6, 8), (tx, ty + 1), "soilDark")
        hub(f, 3)
        f.finish(rim=None)
        return limbs(f, [([(10, 7), (12, 4), (13, 3)], "L"), ([(9, 9), (12, 7), (13, 5)], "l"),
                         ([(13, 3), (12, 2)], "H"), ([(13, 5), (13, 4)], "a")])
    # strike: the arms whipped down in front, the wheel half curled again
    wheel(f, 0.8)
    hub(f, 3)
    f.finish(rim=None)
    return limbs(f, [([(10, 8), (12, 10), (13, 13)], "L"), ([(9, 10), (11, 12), (12, 13)], "l"),
                     ([(13, 13), (12, 13)], "H")])
