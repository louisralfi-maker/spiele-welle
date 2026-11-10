#!/usr/bin/env python3
"""Lanternhold art pass (look 2, stage 6; ART-look2.md section 18): two more paintings each of the town's trees, so
that every kind stands in three variants (linden, lindenB, lindenC and so on). Pure python on pixelart.py's Image;
palette colours only; no randomness (hashes of the position), so a run reproduces its files byte for byte. Called by
tools/build-art-world.sh.

  treeart.py build <id> [<id> …] --out <Resources/Art>

Painted in the hand of the four paintings of `trees-1` (section 13): a crown that is leafDeep for the most part, with
lit caps of leaf on the upper left of every clump and a little meadow in the caps' cores; a trunk in the rock ramp,
lit on the left, an outline of leafDeep on the right and a line of shadow at the foot. Each variant keeps the canvas
of its kind (linden 52x92, poplar 14x116, appleTree 42x48, willow 52x68) and stands with its foot on the bottom row,
the trunk at the canvas' centre, so a variant takes the place of the first painting at the same trunk x.
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import pixelart as PA  # noqa: E402
import worldart as WA  # noqa: E402

h01 = WA.h01
NAMES = {"#": "leafDeep", "d": "leafDark", "l": "leaf", "m": "meadow", "R": "rockDeep", "r": "rockDark", "k": "rock",
         "a": "tile", "A": "tileLight"}


class Grid:
    """A canvas of letters (NAMES), '.' clear."""

    def __init__(self, w, h):
        self.w, self.h = w, h
        self.c = [["."] * w for _ in range(h)]

    def get(self, x, y):
        return self.c[y][x] if 0 <= x < self.w and 0 <= y < self.h else "."

    def set(self, x, y, ch):
        if 0 <= x < self.w and 0 <= y < self.h:
            self.c[y][x] = ch

    def image(self):
        im = PA.Image(self.w, self.h)
        for y in range(self.h):
            for x in range(self.w):
                if self.c[y][x] != ".":
                    im.set(x, y, WA.col(NAMES[self.c[y][x]]))
        return im


def lerp(pts, y):
    """The value at y of a line through (y, v…) points."""
    if y <= pts[0][0]:
        return pts[0][1:]
    for a, b in zip(pts, pts[1:]):
        if y <= b[0]:
            t = (y - a[0]) / float(b[0] - a[0])
            return tuple(p + (q - p) * t for p, q in zip(a[1:], b[1:]))
    return pts[-1][1:]


# ----------------------------------------------------------------------------------------------------------- wood
def bark(n, i, seed, y):
    """The letter of column i of n across a trunk: lit on the left, a groove, the dark side, the outline."""
    if n <= 2:
        return "k#"[i] if n == 2 else "r"
    if i == n - 1:
        return "#"
    lit = max(1, int(round(n * 0.52)))
    if i < lit:
        groove = lit - 2 if lit >= 4 else -1
        if i == groove and h01(seed, y // 3, 1) < 0.7:
            return "r" if h01(seed, y, 2) < 0.7 else "R"
        if i == 0 and n >= 7 and h01(seed, y // 2, 3) < 0.45:
            return "r"
        return "k"
    if i == lit:
        return "r"
    return "R"


def trunk(g, path, seed, foot=None):
    """A trunk along path [(y, centre x, width) …], top to bottom. foot (rows, left reach, right reach) flares the
    roots over the last rows, with dark between the toes, and lays the line of shadow on the row below."""
    y0, y1 = path[0][0], path[-1][0]
    rows, left, right = foot or (0, 0, 0)
    for y in range(y0, y1 + 1):
        xc, w = lerp(path, y)
        n = max(1, int(round(w)))
        x0 = int(round(xc - n / 2.0))
        j = y - (y1 - rows)
        if j <= 0:
            for i in range(n):
                g.set(x0 + i, y, bark(n, i, seed, y))
            continue
        t = j / float(rows)
        a = x0 - int(round(left * t * t))
        b = x0 + n - 1 + int(round(right * t * t))
        for x in range(a, b + 1):
            if x < x0:
                ch = ("R" if j < rows - 1 else "r") if x == a else ("r" if (x + j) % 3 == 0 else "k")
            elif x > x0 + n - 1:
                ch = "#" if x >= b - 1 else ("r" if (x + 2 * j) % 5 == 0 else "R")
            else:
                ch = bark(n, x - x0, seed, y)
            g.set(x, y, ch)
        if rows >= 4:                                      # the dark between the toes fans out with the roots
            for k, fx in enumerate((0.30, 0.58, 0.80)):
                if j >= rows - 3 + (k == 1):
                    x = int(round(x0 + n * fx + (fx - 0.5) * 2.4 * (j - (rows - 3)) * (left + right) / 8.0))
                    g.set(x, y, "#")
                    if j == rows and k != 1:
                        g.set(x + (1 if fx > 0.5 else -1), y, "#")
    if foot:
        xc, w = lerp(path, y1)
        n = max(1, int(round(w)))
        x0 = int(round(xc - n / 2.0))
        for x in range(x0 - left - 3, x0 + n + right + 4):
            g.set(x, y1 + 1, "#")


def limb(g, pts, w0=2, w1=1, lit=True, over=None):
    """A branch through pts [(x, y) …], w0 px thick at the start, w1 at the end; with `over`, only on those letters
    (a branch seen inside the crown's dark)."""
    seg = [math.hypot(q[0] - p[0], q[1] - p[1]) for p, q in zip(pts, pts[1:])]
    total, done = sum(seg), 0.0
    for (p, q), ln in zip(zip(pts, pts[1:]), seg):
        n = int(max(abs(q[0] - p[0]), abs(q[1] - p[1])))
        steep = abs(q[1] - p[1]) >= abs(q[0] - p[0])
        for i in range(n + 1):
            f = i / float(max(1, n))
            t = (done + ln * f) / total
            x, y = p[0] + (q[0] - p[0]) * f, p[1] + (q[1] - p[1]) * f
            w = max(1, int(round(w0 + (w1 - w0) * t)))
            for j in range(w):
                px, py = (int(round(x)) + j, int(round(y))) if steep else (int(round(x)), int(round(y)) + j)
                ch = "R"
                if lit and w >= 2:
                    ch = ("k" if w >= 3 else "r") if j == 0 else ("r" if j < w - 1 else "R")
                if over is None or g.get(px, py) in over:
                    g.set(px, py, ch)
        done += ln


# --------------------------------------------------------------------------------------------------------- leaves
def clump(cx, cy, rx, ry, seed):
    """The pixels of one clump of leaves: an ellipse with a scalloped edge."""
    pts = set()

    def disc(ax, ay, bx, by):
        for y in range(int(math.floor(ay - by)), int(math.ceil(ay + by)) + 1):
            for x in range(int(math.floor(ax - bx)), int(math.ceil(ax + bx)) + 1):
                u, v = (x + 0.5 - ax) / bx, (y + 0.5 - ay) / by
                if u * u + v * v <= 1.0:
                    pts.add((x, y))

    disc(cx, cy, rx, ry)
    n = max(6, int((rx + ry) * 0.8))
    for i in range(n):
        a = 2 * math.pi * (i + 0.6 * h01(seed, i, 1)) / n
        r = 1.4 + 1.9 * h01(seed, i, 2)
        disc(cx + (rx - 0.6) * math.cos(a), cy + (ry - 0.6) * math.sin(a), r, r * 0.85)
    return pts


def crown(g, lobes, seed):
    """A crown of clumps (cx, cy, rx, ry, lit, core), painted back to front. A clump is leafDeep; where lit is a
    number its upper left wears a cap of leaf (the lower the number the larger the cap), with meadow in the cap's
    core above `core`. The silhouette keeps a dark outline, broken by leafDark on the lit side."""
    parts = [clump(cx, cy, rx, ry, seed + 31 * i) for i, (cx, cy, rx, ry, _, _) in enumerate(lobes)]
    whole = set()
    for p in parts:
        whole |= p

    def inside(x, y):
        return (x, y) in whole and 0 <= x < g.w and 0 <= y < g.h

    for i, (cx, cy, rx, ry, lit, core) in enumerate(lobes):
        sd = seed + 31 * i
        for (x, y) in sorted(parts[i]):
            if not (0 <= x < g.w and 0 <= y < g.h):
                continue
            g.set(x, y, "#")
            if lit is None:
                continue
            u, v = (x + 0.5 - cx) / rx, (y + 0.5 - cy) / ry
            s = -(0.60 * u + 0.80 * v) + (h01(sd, y, (x + int(h01(sd, y, 9) * 4)) // 4) - 0.5) * 0.20
            edge = not (inside(x - 1, y) and inside(x + 1, y) and inside(x, y - 1) and inside(x, y + 1))
            if edge:
                if s > lit + 0.15:
                    q = h01(sd, x, y, 4)
                    g.set(x, y, "d" if q < 0.34 else ("r" if q < 0.42 else "#"))
                continue
            if s > lit:
                ch = "l"
                if core is not None and u * u + v * v < 0.62:
                    s2 = -(0.60 * u + 0.80 * v) + (h01(sd, y, (x + int(h01(sd, y, 8) * 5)) // 5, 3) - 0.5) * 0.30
                    if s2 > core:
                        ch = "m"
                g.set(x, y, ch)
            elif s > lit - 0.13 and h01(sd, x // 2, y, 5) < 0.55:
                g.set(x, y, "d")
    return whole


def holes(g, discs):
    """Sky through the crown's ragged underside."""
    for (cx, cy, r) in discs:
        for y in range(int(cy - r) - 1, int(cy + r) + 2):
            for x in range(int(cx - r) - 1, int(cx + r) + 2):
                if (x + 0.5 - cx) ** 2 + (y + 0.5 - cy) ** 2 <= r * r:
                    g.set(x, y, ".")


# ------------------------------------------------------------------------------------------------------- lindens
def linden_b():
    """The slim one: a tall egg of a crown on a straight young trunk that forks low."""
    g = Grid(52, 92)
    crown(g, [
        (26, 10, 10, 9, -0.10, 0.45),
        (35, 24, 9, 12, None, None), (18, 25, 11, 10, -0.10, 0.50), (28, 31, 10, 9, 0.05, 0.62),
        (36, 42, 9, 11, None, None), (17, 43, 12, 11, -0.15, 0.50), (29, 47, 9, 8, 0.12, None),
        (21, 56, 10, 6, None, None), (32, 55, 9, 6, None, None),
    ], 11)
    holes(g, [(27.5, 62.5, 2.4), (17, 62.5, 1.6), (36, 61.5, 1.8), (22, 63.5, 1.3)])
    limb(g, [(24, 72), (20, 66), (18, 60)], 3, 2)
    limb(g, [(28, 70), (32, 64), (34, 59)], 3, 1, lit=False)
    limb(g, [(26, 66), (27, 58)], 2, 1, lit=False)
    trunk(g, [(62, 26.5, 8), (68, 26.5, 6), (80, 26.3, 7), (90, 26.0, 8)], 12, foot=(5, 5, 4))
    return g


def linden_c():
    """The old broad one: a low wide crown on a thick short trunk, a heavy limb to either side."""
    g = Grid(52, 92)
    crown(g, [
        (24, 31, 12, 9, -0.10, 0.45),
        (38, 36, 10, 9, 0.35, None), (11, 42, 10, 10, -0.10, 0.50), (26, 44, 12, 9, 0.00, 0.60),
        (41, 47, 10, 10, None, None), (17, 54, 12, 8, 0.05, None), (33, 55, 12, 8, 0.30, None),
        (9, 57, 8, 6, None, None), (22, 63, 10, 5, None, None), (35, 62, 8, 6, None, None), (44, 57, 6, 6, None, None),
    ], 21)
    holes(g, [(13.5, 67.5, 2.3), (30.5, 69.5, 2.0), (41.5, 67.5, 2.0), (3, 62.5, 2.0), (48.5, 62.5, 1.8)])
    limb(g, [(21, 76), (15, 71), (11, 65)], 4, 2)
    limb(g, [(31, 75), (37, 70), (40, 64)], 4, 2, lit=False)
    trunk(g, [(65, 26.5, 14), (71, 26.5, 10), (80, 26.3, 10), (90, 26.0, 12)], 22, foot=(6, 7, 5))
    return g


# ------------------------------------------------------------------------------------------------------- poplars
def poplar(top, base, belly, girth, seed, lean=0.0, notch=None):
    """A column of stacked clumps from row top to row base, widest (girth, half the width) at `belly` of the way
    down, the left of every clump lit; a thin trunk below. lean shifts the tip to the right by that many px; notch
    (t0, t1) leaves the right side thin over that stretch (a side the wind took)."""
    g = Grid(14, 116)
    ys, i = [top], 0
    while ys[-1] < base - 9:
        ys.append(ys[-1] + 6 + int(h01(seed, i, 1) * 5))
        i += 1
    ys.append(base + 1)
    span = float(base - top)
    for k in range(len(ys) - 1):
        a, b = ys[k], ys[k + 1]
        inner = h01(seed, k, 6) < 0.55
        for y in range(a, b):
            t = (y - top) / span
            if t < belly:
                hw = 1.1 + (girth - 1.1) * (t / belly) ** 0.6
            else:
                hw = girth - (girth - 1.6) * ((t - belly) / (1.0 - belly)) ** 2.4
            ph = (y - a) / float(b - a)
            sc = math.sin(math.pi * ph)
            mid = 7.0 + lean * (1.0 - t) ** 1.5
            cut = 0.0
            if notch and notch[0] <= t <= notch[1]:
                cut = 2.4 * math.sin(math.pi * (t - notch[0]) / (notch[1] - notch[0]))
            xl = int(round(mid - hw - 0.9 * sc + 0.7))
            xr = int(round(mid + hw + 0.8 * math.sin(math.pi * ((ph + 0.45) % 1.0)) - 1.6 - cut))
            xl, xr = max(0, xl), min(13, max(xr, xl))
            n = xr - xl + 1
            lw = max(1, int(round(n * 0.40)))
            for x in range(xl, xr + 1):
                rel, q = x - xl, h01(seed, x, y, 2)
                ch = "#"
                if 0.04 <= ph <= 0.80 and rel < lw:
                    ch = "l"
                    if rel == 0:
                        ch = "d" if ph > 0.55 else ("m" if q < 0.25 else ("k" if q < 0.45 else ("r" if q < 0.6 else "l")))
                    elif ph < 0.42 and rel <= 2 and h01(seed, x, y // 2, 3) < 0.42:
                        ch = "m" if q < 0.7 else "k"
                    elif rel == lw - 1 and q < 0.4:
                        ch = "d"
                    elif ph > 0.66 and q < 0.5:
                        ch = "d"
                elif ph > 0.80 and rel < lw - 1 and q < 0.35:
                    ch = "d"
                elif inner and n >= 9 and lw + 1 <= rel <= lw + 2 and 0.18 <= ph <= 0.62:
                    ch = "l" if 0.24 <= ph <= 0.55 or q < 0.5 else "d"
                if rel == n - 1 and n > 3 and ch != "#":
                    ch = "#"
                g.set(x, y, ch)
    for y in range(base - 5, 114):                                   # the trunk, thicker at the foot
        if g.get(6, y) == "." or y > base:
            g.set(6, y, "r" if y > 100 and y % 4 == 0 else "k")
            g.set(7, y, "#")
            if y >= 105:
                g.set(5, y, "k" if y % 5 else "r")
                g.set(6, y, "R")
    for x, ch in zip(range(4, 9), "rRr##"):
        g.set(x, 114, ch)
    for x in range(2, 10):
        g.set(x, 115, "#")
    return g


# --------------------------------------------------------------------------------------------------- apple trees
def apple_b():
    """The low spreading one: a flat wide crown of small clumps on two stems that wind round each other."""
    g = Grid(42, 48)
    crown(g, [
        (9, 12, 6, 4, -0.10, 0.50), (20, 9, 7, 5, -0.10, 0.45), (31, 11, 6, 4, -0.05, 0.50),
        (4, 18, 4, 4, 0.00, None), (14, 17, 7, 4, 0.05, 0.60), (26, 16, 7, 5, 0.10, 0.65), (37, 17, 4, 5, 0.35, None),
        (9, 23, 6, 3, None, None), (20, 22, 6, 4, None, None), (31, 23, 7, 3, None, None), (36, 21, 4, 4, None, None),
    ], 31)
    holes(g, [(15, 26.6, 1.7), (26, 26.2, 1.9), (3.5, 23.5, 1.2)])
    limb(g, [(17, 31), (13, 28), (9, 25)], 3, 2)
    limb(g, [(25, 31), (30, 28), (33, 25)], 3, 2, lit=False)
    limb(g, [(21, 30), (21, 25)], 2, 1, lit=False)
    trunk(g, [(29, 24.5, 4), (33, 24.0, 4), (38, 20.5, 4), (42, 19.0, 4), (46, 19.5, 5)], 33)   # the stem behind
    trunk(g, [(29, 18.5, 4), (33, 19.5, 4), (38, 22.5, 4), (42, 23.5, 5), (46, 22.5, 6)], 32, foot=(3, 5, 4))
    for x in range(12, 17):                                              # the stem behind stands on its own root
        g.set(x, 46, "r" if x % 2 else "k")
    return g


def apple_c():
    """The round one in fruit: a higher crown on a short bent trunk, apples in the dark of the crown."""
    g = Grid(42, 48)
    crown(g, [
        (20, 6, 7, 5, -0.10, 0.45), (29, 8, 5, 4, 0.20, None),
        (11, 11, 6, 5, -0.05, 0.50), (33, 14, 5, 6, 0.35, None), (22, 13, 8, 5, 0.05, 0.60),
        (7, 17, 4, 4, 0.05, None), (15, 19, 6, 4, 0.20, None),
        (11, 22, 6, 3, None, None), (30, 21, 7, 4, None, None), (21, 22, 7, 4, None, None),
    ], 41)
    holes(g, [(17, 26, 1.5), (26.5, 25.6, 1.4)])
    for x, y in ((8, 20), (13, 23), (18, 21), (24, 22), (28, 18), (33, 21), (35, 16)):
        if g.get(x, y) == "#":
            g.set(x, y, "a")
    limb(g, [(19, 32), (15, 28), (12, 24)], 3, 2)
    limb(g, [(24, 31), (28, 27), (31, 24)], 3, 2, lit=False)
    trunk(g, [(26, 22.0, 5), (30, 22.5, 6), (35, 19.5, 6), (39, 19.5, 6), (43, 21.5, 7), (46, 21.5, 8)], 42,
          foot=(4, 5, 4))
    return g


# -------------------------------------------------------------------------------------------------------- willows
def willow(arch, hang, lit_to, seed, trunk_path, foot, limbs, ghosts=()):
    """A dome (arch: the top line through (x, y) points) from which the branches hang in strands down to the line
    `hang`; every strand ends in a tongue, the strands left of lit_to carry a lit line, the dome's top its lit
    clumps. The trunk and its fork (limbs) show where the strands end high; ghosts are branches inside the dark."""
    g = Grid(52, 68)
    for pts, w0, w1 in limbs:
        limb(g, pts, w0, w1)
    trunk(g, trunk_path, seed + 5, foot=foot)
    x0, x1 = arch[0][0], arch[-1][0]
    x, k, strands = x0, 0, []
    while x <= x1:
        w = 3 + int(h01(seed, k, 1) * 3)
        strands.append((x, min(x1, x + w - 1)))
        x, k = x + w, k + 1
    if strands[-1][1] - strands[-1][0] < 2 and len(strands) > 1:           # no sliver at the right end
        last = strands.pop()
        strands[-1] = (strands[-1][0], last[1])
    for k, (a, b) in enumerate(strands):
        c = (a + b) / 2.0
        sb = int(round(lerp(hang, c)[0] + (h01(seed, k, 2) - 0.5) * 8 + (5 if h01(seed, k, 12) < 0.2 else 0)))
        sb = min(sb, 66)
        tops = {}
        for x in range(a, b + 1):
            d = abs(x - c)
            lump = 1.6 * math.sin(math.pi * (x - a + 0.5) / (b - a + 1.0))
            top = max(0, int(round(lerp(arch, x)[0] - lump + 0.8)))
            bot = sb - int(d * 2.0) - (1 if h01(seed, x, 4) < 0.4 else 0)
            if x in (a, b) and b - a >= 2:                               # sky between the strands' ends
                bot = sb - 5 - int(h01(seed, x, 17) * 10)
            tops[x] = top
            for y in range(top, bot + 1):
                g.set(x, y, "#")
        lit = c < lit_to
        dim = c > lit_to * 0.70
        line = lit and h01(seed, k, 13) < 0.88
        for x in range(a, b + 1):
            top = tops[x]
            if lit and a < x < b:                                        # the dome's top: a rim, then leaf, meadow
                g.set(x, top, "d" if h01(seed, x, 5) < 0.6 else "r")
                depth = 2 + int(1.4 * math.sin(math.pi * (x - a) / float(b - a)) + h01(seed, x, 14))
                for j in range(1, depth + 1):
                    q = h01(seed, x, top + j, 6)
                    ch = "m" if (not dim and j <= 2 and h01(seed, x // 2, top + j, 15) < 0.4) else "l"
                    g.set(x, top + j, "d" if (dim and q < 0.3) or (j == depth and q < 0.4) else ch)
            if line and (x == a + 1 or (x == a + 2 and b - a >= 3 and not dim and h01(seed, k, 16) < 0.7)):
                end = top + 5 + int((sb - 5 - top) * (0.6 + 0.4 * h01(seed, k, 7)))
                for y in range(top + 5, end + 1):
                    if h01(seed, k, y // 4, 8) < 0.16 or h01(seed, x, y, 9) < 0.06:
                        continue
                    g.set(x, y, "d" if y >= end - 1 or (dim and h01(seed, x, y, 10) < 0.35) else "l")
        if k == 0:                                                       # the lit left edge of the whole tree
            for y in range(tops[a] + 2, sb - 6):
                q = h01(seed, y, 11)
                g.set(a, y, "r" if q < 0.4 else ("k" if q < 0.6 else ("m" if q < 0.75 else "l")))
                if g.get(a + 1, y) == "#" and q > 0.3:
                    g.set(a + 1, y, "l")
    for pts, w0, w1 in ghosts:
        limb(g, pts, w0, w1, lit=False, over="#")
    return g


BUILD = {
    "lindenB": linden_b, "lindenC": linden_c,
    "poplarB": lambda: poplar(17, 96, 0.58, 6.4, 51),
    "poplarC": lambda: poplar(1, 90, 0.42, 5.6, 61, lean=1.0, notch=(0.52, 0.72)),
    "appleTreeB": apple_b, "appleTreeC": apple_c,
    "willowB": lambda: willow(
        [(5, 38), (6, 30), (9, 24), (13, 19), (18, 16), (23, 15), (27, 18), (31, 15), (36, 17), (40, 21), (44, 27),
         (47, 36)],
        [(5, 60), (12, 63), (17, 54), (21, 47), (31, 46), (35, 52), (40, 58), (47, 54)], 37, 71,
        [(42, 24.5, 4), (50, 26.5, 5), (58, 27.0, 5), (66, 26.0, 7)], (4, 4, 3),
        [([(24, 46), (21, 41), (19, 36)], 2, 1), ([(26, 45), (29, 40), (32, 36)], 2, 1)],
        [([(19, 36), (16, 30)], 1, 1), ([(32, 36), (35, 31)], 1, 1)]),
    "willowC": lambda: willow(
        [(0, 30), (2, 20), (6, 12), (11, 8), (16, 3), (22, 1), (27, 3), (31, 6), (35, 3), (40, 5), (45, 11), (49, 19),
         (51, 30)],
        [(0, 48), (6, 54), (12, 47), (17, 40), (22, 37), (33, 38), (37, 46), (42, 60), (47, 63), (51, 57)], 40, 81,
        [(27, 25.0, 5), (36, 26.0, 6), (44, 27.5, 7), (56, 27.5, 8), (66, 26.5, 10)], (5, 6, 4),
        [([(23, 40), (19, 35), (16, 29)], 3, 2), ([(28, 38), (33, 33), (36, 28)], 3, 1)],
        [([(16, 29), (12, 22)], 1, 1), ([(36, 28), (40, 21)], 1, 1), ([(26, 33), (27, 24)], 1, 1)]),
}


def main():
    a = sys.argv[1:]
    if len(a) < 4 or a[0] != "build" or "--out" not in a:
        raise SystemExit(__doc__)
    out = a[a.index("--out") + 1]
    for name in a[1:a.index("--out")]:
        im = BUILD[name]().image()
        PA.write_png(os.path.join(out, name + ".png"), im)
        print("wrote %s.png %dx%d" % (name, im.w, im.h))


if __name__ == "__main__":
    main()
