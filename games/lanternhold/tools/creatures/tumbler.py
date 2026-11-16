"""The tumbler (POLISH.md section 7, build 3; step 3, the director's call 8, its last try): a scrap of the Ash Giant's
cloak and its soot rolled up into a flat torn wheel that rolls along the ground, 12 wide and 9 high. Five flat strips
wound round a navy hub, three of soot and two of the giant's cloak (as it is in his shadow), each strip its own flat
tone with a 1 px gap of the deepest navy between them, never dither. Its rim is torn where each strip ends, and two or
three loose ends trail behind the roll, flung up and back as the rear of the wheel turns upward, so each walk frame
has an outline of its own and the silhouette is a ragged wheel with streamers behind it, never a ball. The head is
tucked into the hub ahead of the middle and does not turn: one cold point looks out ahead, never two, never a face.
Its thread rises from the rear of the wheel, never off its top. To claw it squats flatter, then splits open low with
two hooked claws thrown forward at ground height and the strips splayed back (also its pose when it climbs a heap),
and closes again. The wheel is 9 px high; the ends flung up behind it make it 12. (hordekit.py `LEGEND`.)"""
import math
from rig import Frame
from hordekit import CELL, uncap

SIZE = (14, 14, 7)
HEIGHT = 12
STRIPS = 5
# each strip's flat tone: soot, cloth, soot, cloth, soot (the cloth a third of the wheel or so)
TONES = ["nightBlue", "moorDark", "night0", "soilDark", "nightSlate"]
CLOTH = {"moorDark", "soilDark"}
GAP = "nightDeep"
HUB = "night0"


def strip_at(a, turn):
    """The strip under angle `a` (screen angle, y down) for a wheel turned by `turn` (rolling right: clockwise), and
    where in it (0 ... 1, the leading edge first)."""
    u = ((a - turn) / (2 * math.pi) * STRIPS) % STRIPS
    return int(u), u - int(u)


def wheel(f, turn, cx, cy, rx, ry, hub=(8.6, 9.6), keep=None):
    """The wheel: flat strips with gaps, the hub, the rim torn at each strip's end. Returns the rim's tear points."""
    for y in range(CELL):
        for x in range(CELL):
            nx, ny = (x - cx) / rx, (y - cy) / ry
            d = (abs(nx) ** 2.6 + abs(ny) ** 2.6) ** (1 / 2.6)        # a wheel, not a lemon: rounder at its ends
            a = math.atan2(ny, nx)
            k, u = strip_at(a, turn)
            torn = 1.12 if u < 0.3 else 1.0                           # each strip's leading end juts past the rim
            if d > torn or (keep and not keep(x, y)):
                continue
            if d > 0.7 and u > 0.78 and y < cy + ry - 1:
                continue                                              # and the rim is torn where it ends
            if ((x - hub[0]) / 1.9) ** 2 + ((y - hub[1]) / 1.5) ** 2 < 1:
                f.put(x, y, HUB)                                      # the head in the hub
            elif u < 0.17 and d > 0.3:
                f.put(x, y, GAP)                                      # the gap between two strips
            else:
                f.put(x, y, TONES[k])


def moonlit(f):
    """The top pixel of each column catches the moon: moor on cloth, nightHaze on soot."""
    for x in range(CELL):
        for y in range(CELL):
            c = f.b[y][x]
            if c is None or (x, y) in f.bare:
                continue
            if c in CLOTH:
                f.b[y][x] = "moor"
            elif c in ("nightBlue", "night0", "nightSlate"):
                f.b[y][x] = "nightHaze"
            break
    return f


def eye(f, sx, sy):
    f.put(sx, sy, "stoneLight", "wraithWhite")
    f.put(sx, sy + 1, "stoneMid", "wraithGlow")
    f.put(sx - 1, sy, "nightSlate", "wraithDim")


def bare(f, pts, colours):
    for (x, y), c in zip(pts, colours):
        if 0 <= x < CELL and 0 <= y < CELL and f.b[y][x] is None:
            f.put(x, y, c, None, True)


# the loose ends behind the roll, per walk frame: polylines of bare pixels (cloth, then soot at the torn tip), flung up
# and back from the rear of the wheel; two or three a frame, each frame its own
ENDS = [
    [[(1, 8), (0, 8)], [(1, 6), (0, 5)], [(3, 5), (2, 4), (1, 4), (0, 3)]],
    [[(1, 9), (0, 9), (0, 10)], [(2, 5), (1, 4), (0, 4)]],
    [[(1, 7), (0, 7), (0, 6)], [(3, 5), (2, 4), (1, 3), (0, 3)], [(1, 10), (0, 11)]],
    [[(1, 8), (0, 7)], [(2, 5), (1, 5), (0, 4)], [(4, 5), (3, 4), (2, 3), (1, 2)]],
]
END_TONES = ["moorDark", "moorDark", "soilDark", "night0"]
PEAKS = [(3, 6), (3, 6), (3, 6), (3, 6), (3, 8), (3, 9), (3, 7)]       # the thread's root: the rear of the wheel


def frame(k):
    f = Frame(CELL, CELL, seed=7)
    if k < 4:
        # roll 0-3 at 2 px a frame: a fifth of a turn (one strip) over the cycle, so it loops
        wheel(f, k * 2 * math.pi / STRIPS / 4, 6.5, 9.4, 5.6, 3.95)
        eye(f, 9, 9)
        f.finish(rim=None)
        uncap(f)
        moonlit(f)
        for pts in ENDS[k]:
            bare(f, pts, END_TONES)
    elif k == 4:
        # gather: it squats flatter and wider, the claws tucked under its front
        wheel(f, 0.4, 6.5, 10.4, 5.9, 2.95, hub=(8.8, 10.6))
        eye(f, 9, 10)
        f.finish(rim=None)
        uncap(f)
        moonlit(f)
        bare(f, [(12, 12), (13, 13)], ["night0", "stoneDark"])
        bare(f, [(1, 9), (0, 8), (0, 7)], END_TONES)
        bare(f, [(2, 8), (1, 7), (1, 6)], END_TONES)
    elif k == 5:
        # claw: split open low, the strips splayed back, the hub forward, two hooked claws at ground height
        wheel(f, 0.9, 5.2, 10.6, 5.0, 2.9, hub=(8.4, 10.8), keep=lambda x, y: x < 7 or y > 9)
        eye(f, 9, 10)
        f.finish(rim=None)
        uncap(f)
        moonlit(f)
        bare(f, [(10, 11), (11, 11), (12, 12), (13, 12), (13, 13)], ["night0", "night0", "night0", "stoneDark",
                                                                    "stoneDark"])
        bare(f, [(10, 12), (11, 13), (12, 13)], ["nightBlue", "nightBlue", "stoneDark"])
        bare(f, [(0, 10), (0, 9)], END_TONES)
        bare(f, [(1, 8), (0, 7), (0, 6)], END_TONES)
    else:
        # recover: closing again, the claws drawn back under it
        wheel(f, 1.3, 6.5, 9.9, 5.7, 3.5, hub=(8.6, 10.1))
        eye(f, 9, 9)
        f.finish(rim=None)
        uncap(f)
        moonlit(f)
        bare(f, [(12, 12), (12, 13)], ["night0", "stoneDark"])
        bare(f, [(1, 8), (0, 7), (0, 6)], END_TONES)
    sx, sy = PEAKS[k]
    if f.b[sy][sx] is None:
        f.put(sx, sy, "nightSlate")
    return f
