#!/usr/bin/env python3
"""Lanternhold art pass (look 2, stage 7; ART-look2.md section 19): the old walls in the Throat and the pieces that
anchor the built tiers in the rock. Pure python on pixelart.py's Image; palette colours only; no randomness (hashes
of the position), so a run reproduces its files byte for byte.

  throatart.py build <id> --out <Art dir>      ids: oldWall1 oldWall2 oldWall3 palisadeAnchor stoneWallAnchor
                                                    bastionAnchor

The story (STORY.md): Lady Oriel the Mason built the three lines in the year 118. What stands of them today is a
ruin; the lord's lines are built into it.

  oldWall2, oldWall3   the place of the middle and of the outer line as it lies before anything is built: two masses
                       of the Throat's granite (a horn left of the track's crossing, a tall pillar right of it) with
                       a low saddle between them. In the saddle lies what is left of the old wall: the broken courses
                       of its curtain, the stub of its round end tower against the pillar, fallen blocks, the old
                       footing in the track, a little scree. Drawn always: it is the place.
  oldWall1             what is left of Oriel's first line before the gatehouse (the gatehouse stands on it): a stretch
                       of broken wall with half a tower, scenery.
  <tier>Anchor         what the builders add with a tier, drawn over the old wall and behind the tier: the tier's
                       footing across the track (the 8 rows under the ground line) and its end piece where it meets
                       the pillar (a return of stakes on an earth bank; an end tower of ashlar toothed into the
                       granite; the bastion's taller, with a corbelled crown). The air above the walk stays open, so
                       the watch on the wall reads against the sky and the mist, never against rock.

One canvas for the five of lines 2 and 3: 128x108, the ground line 8 rows above the bottom, the wall's left edge
(Realm.wallX) at sprite x 28. Light from the upper left, as everywhere.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import pixelart as PA  # noqa: E402
import worldart as WA  # noqa: E402

col, h01 = WA.col, WA.h01
STONES = ("stoneDark", "stoneMid", "stone", "stoneLight", "stonePale")
WOODS = ("woodDark", "wood", "woodLight", "straw", "strawLight")
GRANITE = WA.GRANITE
ART = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "Resources", "Art")

W, UP, DOWN, OX = 128, 100, 8, 28
H = UP + DOWN


def sx(lx):
    return lx + OX


def sy(u):  # u: rows above the ground line (0 is the first row above it; -1 the first row of the track)
    return UP - 1 - u


def run(points, x):  # the height at x of a line through points
    x = max(x, points[0][0])
    k = max(i for i, (x0, h) in enumerate(points) if x0 <= x)
    if k + 1 == len(points):
        return points[k][1]
    (x0, h0), (x1, h1) = points[k], points[k + 1]
    return h0 + (h1 - h0) * (x - x0) / float(x1 - x0)


def hold(points, x):  # the height at x of a stepped line: each height holds until the next point
    if x < points[0][0]:
        return 0
    return points[max(i for i, (x0, h) in enumerate(points) if x0 <= x)][1]


# --- the place (lx, rows above the ground): two masses of the Throat's granite and the saddle between them --------
# The saddle is where the line stands: the air above it stays open behind the watch on the walk (the mist is what
# archers read against at night); the horn stands on the Gloom's side, the mass on the castle's.
SHOULDER = {
    2: [(-28, 0), (-26, 5), (-23, 9), (-21, 24), (-19, 30), (-17, 46), (-14, 52), (-11, 62), (-7, 66), (-3, 60),
        (-1, 44), (1, 22), (3, 18), (10, 16), (18, 20), (26, 18), (34, 22), (40, 24), (43, 44), (45, 62), (47, 76),
        (50, 86), (54, 90), (58, 97), (64, 100), (69, 95), (73, 97), (78, 90), (82, 86), (85, 70), (88, 64), (91, 46),
        (94, 32), (97, 14), (100, 0)],
    3: [(-28, 0), (-26, 4), (-23, 10), (-21, 26), (-18, 32), (-16, 44), (-13, 50), (-9, 56), (-5, 52), (-2, 42),
        (0, 26), (2, 14), (5, 12), (12, 14), (20, 10), (28, 14), (36, 18), (41, 22), (43, 40), (45, 58), (47, 68),
        (50, 80), (53, 88), (57, 84), (60, 92), (64, 98), (70, 100), (75, 96), (79, 90), (83, 92), (86, 76), (89, 70),
        (92, 48), (95, 30), (98, 12), (100, 0)],
}
TEX = {2: (150, 62), 3: (262, 30)}                    # each place its own piece of the gorge's painting
# the old masonry's broken top (stepped: lx, rows): the curtain's courses across the saddle, the end tower's stub
OLD = {
    2: [(0, 22), (5, 26), (9, 20), (13, 9), (17, 24), (21, 30), (24, 27), (26, 50), (31, 58), (36, 54), (40, 44),
        (43, 46), (46, 36), (48, 0)],
    3: [(0, 14), (4, 18), (8, 12), (12, 7), (16, 16), (20, 22), (24, 20), (27, 40), (32, 46), (37, 38), (41, 30),
        (44, 34), (47, 0)],
}
TOWER = {2: 26, 3: 27}                                # where the stub (round) begins; before it the curtain (flat)
DOOR = {2: (34, 15), 3: None}                         # the stub's doorway (its left lx, the arch's crown)
SLIT = {2: (30, 36, 44), 3: (33, 24, 31)}             # an empty slit (lx, from row, to row)
# fissures (lx, the row it starts at, its length): they part a mass into pillars
FISSURE = {2: [(-12, 44, 24), (58, 92, 44), (72, 90, 40), (84, 62, 30)],
           3: [(-13, 40, 22), (56, 82, 40), (66, 96, 46), (82, 86, 36)]}
# fallen blocks: (lx, rows above the ground of its foot, width, height); a foot below 0 lies in the track
BLOCKS = {
    2: [(-27, 0, 6, 4), (-19, 0, 5, 3), (-21, 3, 4, 3), (3, 0, 5, 3), (9, 0, 6, 4), (11, 4, 4, 3), (17, 0, 4, 3),
        (88, 0, 7, 4), (96, 0, 4, 3), (-16, -6, 6, 3), (20, -7, 5, 3), (52, -5, 6, 3), (70, -7, 4, 2)],
    3: [(-28, 0, 5, 3), (-22, 0, 7, 4), (-20, 4, 5, 3), (2, 0, 6, 4), (10, 0, 4, 2), (15, 0, 5, 3), (21, 0, 5, 4),
        (86, 0, 6, 3), (93, 0, 6, 4), (-24, -6, 5, 3), (-9, -7, 6, 3), (24, -5, 5, 3), (40, -7, 6, 3), (60, -6, 5, 3),
        (80, -7, 6, 2)],
}
FOOTING = {2: [(-4, 6), (14, 30), (36, 50)], 3: [(-5, 3), (10, 20), (30, 46)]}   # the old footing left in the track


class Sheet:
    """A canvas with a material map: 'R' rock, 'S' stone, 'W' timber, 'E' earth, 'F' a fixed colour."""

    def __init__(self, w=W, h=H):
        self.w, self.h = w, h
        self.img = PA.Image(w, h)
        self.mat = [[None] * w for _ in range(h)]

    def inside(self, x, y):
        return 0 <= x < self.w and 0 <= y < self.h

    def m(self, x, y):
        return self.mat[y][x] if self.inside(x, y) else None

    def put(self, x, y, name, mat="F"):
        if self.inside(x, y):
            self.img.set(x, y, col(name))
            self.mat[y][x] = mat


def gorge_levels():
    src = PA.read_png(os.path.join(ART, "gorgeRock.png"))[0]
    lvl = {col(n): i for i, n in enumerate(GRANITE)}
    return src.w, src.h, [[lvl.get(src.get(x, y), 0) for x in range(src.w)] for y in range(src.h)]


def rock(sh, inside, seed, off):
    """Granite in the cells inside(x, y), in the gorge's own hand: the painting's slabs as the body, every top edge
    lit, the side toward the light a step up, the side away two columns of the deep tone."""
    tw, th, tex = gorge_levels()

    def bk(x, y):
        return sh.inside(x, y) and inside(x, y)

    for y in range(sh.h):
        for x in range(sh.w):
            if not bk(x, y):
                continue
            t = tex[(y + off[1]) % th][(x + off[0]) % tw]
            i = t
            if not bk(x, y - 1):
                i = 4
            elif not bk(x, y - 2) or not bk(x - 1, y):
                i = 3
            elif not bk(x + 1, y) or not bk(x + 2, y):
                i = 0
            elif not bk(x - 2, y) or (not bk(x - 3, y) and h01(seed, x, y // 3) < 0.6):
                i = max(i, 2)
            elif not bk(x, y - 3) and h01(seed, x // 2, 5) < 0.5:
                i = max(i, 2)
            sh.put(x, y, GRANITE[i], "R")


def runs(cells):
    """Per row, the contiguous runs of a set of cells: {(x, y): (a, b)}."""
    rows = {}
    for (x, y) in cells:
        rows.setdefault(y, []).append(x)
    ext = {}
    for y, xs in rows.items():
        xs.sort()
        a = xs[0]
        for i, x in enumerate(xs):
            if i + 1 == len(xs) or xs[i + 1] != x + 1:
                for xx in range(a, x + 1):
                    ext[(xx, y)] = (a, x)
                if i + 1 < len(xs):
                    a = xs[i + 1]
    return ext


def ashlar(sh, cells, seed, tone=0, bl=7, form="flat", moss=0.0, span=None, ground=None, ch=4):
    """Coursed ashlar as on the defences (defenceart.py): courses 4 rows high, lit top edges, soft shadowed beds, a
    stone here and there paler or darker, shaded as a body, a lit cap on every top edge, moss at the foot and, with
    moss, in the beds. tone -1 is a wall in another's shade, +1 old stone weathered pale."""
    cells = set(cells)
    ext = runs(cells)
    ground = sy(0) if ground is None else ground
    hi = 4 + min(0, tone)
    for (x, y) in sorted(cells):
        a, b = span if span else ext[(x, y)]
        t = (x - a) / float(max(1, b - a)) + (0.03 if y % 2 else -0.03)
        if form == "round":
            fo = 0 if t < 0.05 else 1 if t < 0.36 else 0 if t < 0.64 else -1 if t < 0.86 else -2
        else:
            fo = 1 if t < 0.10 else 0 if t < 0.84 else -1
        yb = ground - y
        k, r = yb // ch, ch - 1 - yb % ch
        s = x + k * 3 + int(h01(seed, k) * 5)
        n = s // bl
        v = h01(seed, k, n)
        i = 1 if v > 0.80 else 3 if v < 0.12 else 2
        if r == 0 and fo >= 0:
            i += 1
        if r == ch - 1:
            i -= 2 if h01(seed, x, y, 2) < 0.3 else 1
        i += fo + tone
        if s % bl == 0 or (bl >= 6 and 0.3 < v < 0.5 and s % bl == bl // 2):
            i -= 2 if 0 < r < ch - 1 and fo >= 0 else 1
        if 0 <= yb < 2:
            i -= 1
        i = max(0, min(hi, i))
        if (x, y - 1) not in cells:
            i = hi if fo >= 0 else hi - 1
        c = STONES[i]
        if moss:
            low = 0 <= yb < 6
            p = moss * (2.2 if low else 1.0) * (1.6 if r == ch - 1 else 0.5 if r == 0 else 1.0)
            if h01(seed, x // 2, y, 7) < p * 0.085:
                c = "leafDark" if h01(seed, x, y, 9) < 0.65 else "leaf"
        sh.put(x, y, c, "S")


def edge(sh, cells, into_rock="stoneDark"):
    """Look 2's selective outline for a body of stone or timber: ink on the side away from the light where the air is
    behind it, the dark tone where rock is; under it and right of it the rock lies in its shade."""
    cells = set(cells)
    for (x, y) in sorted(cells):
        if (x + 1, y) not in cells:
            if sh.m(x + 1, y) is None:
                sh.put(x, y, "ink", sh.mat[y][x])
            else:
                sh.put(x, y, into_rock, sh.mat[y][x])
                if sh.m(x + 1, y) == "R":
                    sh.put(x + 1, y, "rockDeep", "R")


def box(lx0, lx1, u0, u1):  # cells of lx0..lx1-1, rows u0..u1-1
    return [(sx(lx), sy(u)) for lx in range(lx0, lx1) for u in range(u0, u1)]


def under(points, lx0, lx1, stepped=True, base=0):
    f = hold if stepped else run
    out = []
    for lx in range(lx0, lx1):
        top = int(round(f(points, lx)))
        out += [(sx(lx), sy(u)) for u in range(base, top)]
    return out


def knock(cells, seed, share):
    """Knocks single stones out of a broken top: where a cell has air above it, it and the cell under it may go."""
    cells = set(cells)
    out = set(cells)
    for (x, y) in cells:
        if (x, y - 1) not in cells and h01(seed, x // 3, y // 4) < share:
            out.discard((x, y))
            if h01(seed, x // 3, y // 4, 2) < 0.5:
                out.discard((x, y + 1))
    return out


def block(sh, lx, u, w, h, seed, tone=1):
    """A fallen block: a lit top, a shaded right end, ink under it where it lies on the ground."""
    for dx in range(w):
        for dy in range(h):
            i = 2 + tone
            if dy == h - 1:
                i = 4 if dx < w - 1 else 3
            elif dx == 0:
                i = min(4, i + 1)
            elif dx == w - 1:
                i -= 2
            elif dy == 0:
                i -= 1
            c = STONES[max(0, min(4, i))]
            if dy == 0 and h01(seed, lx + dx, u, 3) < 0.3:
                c = "leafDark"
            sh.put(sx(lx + dx), sy(u + dy), c, "S")
    if h01(seed, lx, u) < 0.5 and w >= 5:   # a chipped corner
        sh.put(sx(lx + w - 1), sy(u + h - 1), GRANITE[1] if sh.m(sx(lx + w), sy(u + h - 1)) == "R" else "stoneMid", "S")


def scree(sh, seed, spans, track=True):
    """A little scree: stones of two to three pixels at the shoulder's foot and in the track."""
    for (a, b, share) in spans:
        for lx in range(a, b):
            if h01(seed, lx, 1) < share:
                wdt = 2 + int(h01(seed, lx, 2) * 2)
                for dx in range(wdt):
                    sh.put(sx(lx + dx), sy(0), "rockLight" if dx == 0 else "rock", "R")
                    if h01(seed, lx, 3) < 0.5 and dx < wdt - 1:
                        sh.put(sx(lx + dx), sy(1), "rockPale", "R")
            if track and h01(seed, lx, 4) < share * 0.55:
                d = 2 + int(h01(seed, lx, 5) * 5)
                sh.put(sx(lx), sy(-d), "rockPale", "R")
                sh.put(sx(lx + 1), sy(-d), "rockLight", "R")
                sh.put(sx(lx), sy(-d - 1), "rockDark", "R")
                sh.put(sx(lx + 1), sy(-d - 1), "rockDeep", "R")


def old_wall(line):
    """The place of line 2 or 3 before anything is built."""
    sh = Sheet()
    prof, seed = SHOULDER[line], 40 + line
    tops = {}
    for lx in range(-OX, W - OX):
        hh = run(prof, (lx // 2) * 2)
        j = int(h01(seed, lx // 4) * 5) - 2 + (1 if h01(seed, lx // 2, 3) < 0.3 else 0)
        tops[lx] = max(0, min(UP, int(round(hh)) + (j if hh > 8 else 0)))

    def in_rock(x, y):
        lx, u = x - OX, UP - 1 - y
        return 0 <= u < tops.get(lx, 0)

    rock(sh, in_rock, seed, TEX[line])
    for n, (lx, top, length) in enumerate(FISSURE[line]):
        x = sx(lx)
        for k in range(length):
            y = sy(top - k)
            x += (1 if h01(seed, n, k // 5, 1) < 0.3 else -1 if h01(seed, n, k // 5, 1) > 0.8 else 0) if k % 5 == 4 else 0
            if sh.m(x, y) != "R" or sh.m(x + 2, y) != "R" or sh.m(x - 2, y) != "R":
                continue
            sh.put(x, y, "rockDeep", "R")
            if k < length - 4:
                sh.put(x - 1, y, "rockDeep" if k > 3 else "rockDark", "R")
            sh.put(x + 1, y, "rockLight" if h01(seed, n, k // 3, 2) < 0.75 else "rock", "R")
    # the old wall: the curtain's broken courses across the saddle, the end tower's stub (round) at the mass
    t0 = TOWER[line]
    low = knock(under(OLD[line], 0, t0), seed + 1, 0.22)
    stub = knock(under(OLD[line], t0, 49), seed + 2, 0.2)
    ashlar(sh, low, seed + 3, tone=1, bl=7, moss=1.0)
    ashlar(sh, stub, seed + 4, tone=1, bl=6, form="round", moss=0.8)
    edge(sh, low)
    edge(sh, stub)
    if DOOR[line]:                                            # a round arch, half filled with fallen stone
        d0, crown = DOOR[line]
        for lx in range(d0, d0 + 6):
            top = crown - (3 if lx in (d0, d0 + 5) else 1 if lx in (d0 + 1, d0 + 4) else 0)
            for u in range(0, top):
                sh.put(sx(lx), sy(u), "night0" if u >= 4 or lx > d0 + 2 else "stoneMid", "F")
            sh.put(sx(lx), sy(top), "stonePale", "S")
        for u in range(0, crown - 2):
            sh.put(sx(d0 - 1), sy(u), "stoneLight", "S")
            sh.put(sx(d0 + 6), sy(u), "stoneDark", "S")
    lx, u0, u1 = SLIT[line]
    for u in range(u0, u1):
        sh.put(sx(lx), sy(u), "night0", "F")
        sh.put(sx(lx - 1), sy(u), "stoneLight", "S")
    # the old footing in the track: a course of pale stones across it, broken where the track runs
    for (a, b) in FOOTING[line]:
        cells = [(sx(lx), sy(-d)) for lx in range(a, b) for d in range(2, 7)
                 if not (d == 6 and h01(seed, lx // 3, 8) < 0.4) and not (lx in (a, b - 1) and d in (2, 6))]
        ashlar(sh, cells, seed + 5, tone=1, bl=6, moss=0.7, ground=sy(-6), ch=5)
    for (lx, u, w, h) in BLOCKS[line]:
        block(sh, lx, u, w, h, seed + 6)
    scree(sh, seed + 7, [(-28, -8, 0.3), (50, 100, 0.2), (-8, 50, 0.08)])
    return sh


# --- the anchors -----------------------------------------------------------------------------------------------
def plinth(sh, lx0, lx1, seed, tone=0, batter=0):
    """A wall's footing across the track: two courses of large stones under the ground line, a dark bed below."""
    cells = []
    for d in range(1, 8):
        grow = batter if d >= 5 else 0
        cells += [(sx(lx), sy(-d)) for lx in range(lx0 - grow, lx1 + grow)]
    ashlar(sh, cells, seed, tone=tone, bl=8, moss=0.5, ground=sy(-7), ch=4)
    for lx in range(lx0 - batter, lx1 + batter):
        sh.put(sx(lx), sy(-8), "ink" if h01(seed, lx // 4, 2) < 0.75 else "rockDeep", "F")
    edge(sh, cells, "stoneDark")


def teeth(sh, lx, u0, u1, seed, side=1, tone=-1):
    """Toothing: every other course a stone let into the granite beside the wall's edge at lx."""
    for u in range(u0 - u0 % 4, u1, 8):
        n = 2 + int(h01(seed, u) * 3)
        for dx in range(1, n + 1):
            for du in range(0, 4):
                if u + du >= u1 or u + du < u0:
                    continue
                i = 2 + tone
                if du == 3:
                    i += 1
                elif du == 0:
                    i -= 1
                if dx == n and side > 0:
                    i -= 1
                sh.put(sx(lx + side * dx), sy(u + du), STONES[max(0, min(4, i))], "S")


def merlons(lx0, lx1, top, width, gap, height):
    cells = []
    lx = lx0
    while lx + width <= lx1 + 1:
        cells += box(lx, min(lx + width, lx1), top, top + height)
        lx += width + gap
    return cells


def stone_anchor(kind):
    """The stone tiers' end tower: right of the walk (the watch keeps the open air behind it), toothed into the mass."""
    sh = Sheet()
    if kind == "stoneWall":
        seed, w = 71, 36
        plinth(sh, -2, w + 2, seed, tone=0)
        body = box(34, 52, 0, 64) + merlons(34, 52, 64, 7, 4, 5)
        ashlar(sh, body, seed + 1, tone=-1, bl=7)
        teeth(sh, 51, 6, 58, seed + 2)
        for u in range(46, 54):                               # a slit toward the Gloom
            sh.put(sx(38), sy(u), "night0", "F")
            sh.put(sx(37), sy(u), "stoneMid", "S")
        edge(sh, body)
    else:
        seed, w = 83, 44
        plinth(sh, -3, w + 3, seed, tone=0, batter=1)
        body = []
        for u in range(0, 70):                                # a battered foot, as the bastion's own
            grow = 2 if u < 6 else 1 if u < 14 else 0
            body += [(sx(lx), sy(u)) for lx in range(42 - grow, 60 + grow)]
        crown = box(40, 62, 70, 75) + merlons(40, 62, 75, 6, 2, 6)
        ashlar(sh, body, seed + 1, tone=-1, bl=8)
        ashlar(sh, crown, seed + 3, tone=-1, bl=8, ground=sy(70))
        for lx in range(41, 61, 4):                           # the corbels under the crown
            sh.put(sx(lx), sy(69), "stoneDark", "S")
            sh.put(sx(lx + 1), sy(69), "stoneDark", "S")
            sh.put(sx(lx), sy(68), "stoneDark", "S")
        teeth(sh, 59, 8, 66, seed + 2)
        for u in range(50, 61):                               # the slit
            sh.put(sx(47), sy(u), "night0", "F")
            sh.put(sx(48), sy(u), "night0", "F")
            sh.put(sx(46), sy(u), "stoneMid", "S")
        edge(sh, body + crown)
    return sh


def stake(sh, lx, u0, top, wdt, shade=0):
    """One stake: lit on its left, the grain a step down here and there, a cut point."""
    for u in range(u0, top):
        for dx in range(wdt):
            i = 2 if dx == 0 else 1 if dx < wdt - 1 else 0
            if dx == 1 and wdt >= 4:
                i = 3 if (u + lx) % 7 else 2
            if u >= top - 2:
                if dx == 0 and u == top - 1:
                    continue
                if dx == wdt - 1 and u >= top - 2:
                    continue
                i = min(3, i + 1)
            i = max(0, i - shade)
            if i == 1 and h01(9, lx + dx, u // 3) < 0.08:
                i = 0
            sh.put(sx(lx + dx), sy(u), WOODS[i], "W")


def palisade_anchor():
    sh = Sheet()
    seed = 61
    # the footing: a bank of earth and packed stone across the track, the stakes' butts in it
    for d in range(1, 8):
        for lx in range(-3 - (d > 3), 23 + (d > 3)):
            v = h01(seed, lx // 3, d // 2)
            c = "soilLight" if d == 1 else "soil" if d < 5 else "soilDark"
            if d > 1 and v < 0.22:
                c = "stoneMid" if d < 6 else "stoneDark"
            elif d > 1 and v > 0.9:
                c = "soilDark"
            sh.put(sx(lx), sy(-d), c, "E")
    for lx in (0, 4, 8, 12, 16):
        for d in range(1, 4):
            sh.put(sx(lx), sy(-d), "woodLight" if d == 1 else "wood", "W")
            sh.put(sx(lx + 1), sy(-d), "straw" if d == 1 else "wood", "W")
            sh.put(sx(lx + 2), sy(-d), "woodDark", "W")
            sh.put(sx(lx + 3), sy(-d), "woodDark", "W")
    for lx in range(-4, 24):
        sh.put(sx(lx), sy(-8), "ink" if h01(seed, lx // 4, 2) < 0.75 else "rockDeep", "F")
    # the return: three stakes stepping down from the palisade to the old stub, a rail, the lashing
    for (lx, top) in ((19, 33), (23, 30), (27, 28)):
        stake(sh, lx, 0, top, 4, shade=1)
    for lx in range(19, 31):
        for u in (17, 18):
            sh.put(sx(lx), sy(u), "wood" if u == 18 else "woodDark", "W")
        sh.put(sx(lx), sy(19), "woodLight" if lx % 4 else "wood", "W")
    for (lx, u) in ((29, 21), (30, 21), (29, 22), (30, 20)):
        sh.put(sx(lx), sy(u), "strawLight" if (lx + u) % 2 else "straw", "W")
    for u in range(0, 27):                                    # the last stake's shaded side
        sh.put(sx(30), sy(u), "ink", "W")
    return sh


def old_wall_1():
    """What is left of the first line before the gatehouse: a stretch of broken wall, half a tower, fallen blocks."""
    w, up = 84, 52
    sh = Sheet(w, up + DOWN)
    seed = 53
    ox = 4

    def cell(lx, u):
        return (lx + ox, up - 1 - u)

    wall = [(0, 5), (5, 9), (10, 13), (14, 8), (19, 16), (24, 21), (28, 14), (33, 6), (38, 3), (41, 0)]
    stubp = [(40, 0), (44, 34), (49, 44), (54, 40), (58, 30), (62, 32), (66, 22), (70, 24), (72, 0)]
    low = knock([cell(lx, u) for lx in range(0, 41) for u in range(0, hold(wall, lx))], seed + 1, 0.22)
    stub = knock([cell(lx, u) for lx in range(44, 72) for u in range(0, hold(stubp, lx))], seed + 2, 0.2)
    g = up - 1
    ashlar(sh, low, seed + 3, tone=1, bl=7, moss=1.0, ground=g)
    ashlar(sh, stub, seed + 4, tone=1, bl=6, form="round", moss=0.8, ground=g)
    edge(sh, low)
    edge(sh, stub)
    for u in range(20, 27):
        x, y = cell(55, u)
        sh.put(x, y, "night0", "F")
        sh.put(x - 1, y, "stoneLight", "S")
    for lx in range(58, 64):                                  # the doorway, its arch fallen
        top = 9 if lx in (58, 63) else 11
        for u in range(0, top):
            x, y = cell(lx, u)
            sh.put(x, y, "night0" if u >= 3 or lx > 60 else "stoneMid", "F")
    cells = [cell(lx, -d) for lx in list(range(2, 18)) + list(range(30, 62)) for d in range(2, 7)
             if not (d == 6 and h01(seed, lx // 3, 8) < 0.4)]
    ashlar(sh, cells, seed + 5, tone=1, bl=6, moss=0.7, ground=up - 1 + 6, ch=5)
    for (lx, u, bw, bh) in ((-4, 0, 5, 3), (20, 0, 6, 4), (27, 0, 4, 3), (22, 4, 4, 3), (73, 0, 6, 4), (36, 0, 5, 3),
                            (19, -6, 6, 3), (24, -3, 4, 2), (66, -7, 5, 3), (74, -5, 5, 2)):
        for dx in range(bw):
            for dy in range(bh):
                i = 3
                if dy == bh - 1:
                    i = 4 if dx < bw - 1 else 3
                elif dx == 0:
                    i = 4
                elif dx == bw - 1:
                    i = 1
                elif dy == 0:
                    i = 2
                x, y = cell(lx + dx, u + dy)
                sh.put(x, y, STONES[i], "S")
    for lx in range(-4, 80):
        if h01(seed, lx, 1) < 0.1:
            x, y = cell(lx, 0)
            if sh.m(x, y) is None:
                sh.put(x, y, "rockLight", "R")
                sh.put(x + 1, y, "rock", "R")
        if h01(seed, lx, 4) < 0.07:
            x, y = cell(lx, -2 - int(h01(seed, lx, 5) * 5))
            if sh.m(x, y) is None:
                sh.put(x, y, "rockPale", "R")
                sh.put(x, y + 1, "rockDark", "R")
    return sh


BUILD = {
    "oldWall1": old_wall_1,
    "oldWall2": lambda: old_wall(2),
    "oldWall3": lambda: old_wall(3),
    "palisadeAnchor": palisade_anchor,
    "stoneWallAnchor": lambda: stone_anchor("stoneWall"),
    "bastionAnchor": lambda: stone_anchor("bastion"),
}


def main():
    a = sys.argv[1:]
    if len(a) != 4 or a[0] != "build" or a[2] != "--out" or a[1] not in BUILD:
        raise SystemExit(__doc__)
    sh = BUILD[a[1]]()
    path = os.path.join(a[3], a[1] + ".png")
    PA.write_png(path, sh.img)
    print("wrote %s %dx%d" % (path, sh.w, sh.h))


if __name__ == "__main__":
    main()
