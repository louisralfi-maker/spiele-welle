#!/usr/bin/env python3
"""Lanternhold look 2, stage 3: the rig painter of the creatures (tools/creatureart.py, tools/creatures/<id>.py).
Every frame is posed from a skeleton (two-bone limbs with planted feet, capsules and ellipses shaded from a palette
ramp, cloth polygons with torn hems) and finished with hand-set stamps (faces, hands, lanterns, the crown), a 1 px
outline and the glow strip (smouldering top contour, cracks, hollow eyes). Palette names only and no randomness
beyond a fixed hash, so a run reproduces the committed PNGs byte for byte."""
import math

# ramps, darkest first: [deep shade, shade, mid, light]
HUSK = ["nightDeep", "night0", "nightBlue", "nightSlate"]         # the smoke flesh: navy-black, even in light
ASH = ["ink", "stoneDark", "stoneMid", "stone"]                   # ashen skin, skulls, hands
BONE = ["stoneDark", "stoneMid", "stone", "stoneLight"]
RAG = ["nightDeep", "soilDark", "moorDark", "moor"]               # peat-brown rags
REALM = ["nightDeep", "roofDeep", "banner", "roofLight"]          # a rag of the realm's teal cloth
IRON = ["nightDeep", "ink", "stoneDark", "stoneMid"]
ROBE = ["night0", "night1", "night2", "nightHaze"]                # the weaver's and the king's cloth
LX, LY = -0.35, -0.94                                             # the painted light: from above, a little behind


def hsh(x, y, s=0):
    n = (int(x) * 374761393 + int(y) * 668265263 + int(s) * 2246822519) & 0xFFFFFFFF
    n = ((n ^ (n >> 13)) * 1274126177) & 0xFFFFFFFF
    n ^= n >> 16
    return (n & 0xFFFF) / 65536.0


def ik(a, b, l1, l2, bend):
    """The joint of a two-bone limb from a to b; bend -1 puts it toward +x for a limb hanging down (a knee), +1
    toward -x (an elbow)."""
    dx, dy = b[0] - a[0], b[1] - a[1]
    d = max(abs(l1 - l2) + 0.01, min(math.hypot(dx, dy), l1 + l2 - 0.01))
    a0 = math.atan2(dy, dx)
    c = (l1 * l1 + d * d - l2 * l2) / (2 * l1 * d)
    ang = a0 + bend * math.acos(max(-1.0, min(1.0, c)))
    return (a[0] + l1 * math.cos(ang), a[1] + l1 * math.sin(ang))


class Frame:
    def __init__(self, w, h, seed=0):
        self.w, self.h, self.seed = w, h, seed
        self.b = [[None] * w for _ in range(h)]
        self.g = [[None] * w for _ in range(h)]
        self.bare = set()      # body pixels that get no outline (smoke)
        self.norim = set()     # columns whose top contour does not glow

    def put(self, x, y, c, g=None, bare=False):
        x, y = int(math.floor(x + 0.5)), int(math.floor(y + 0.5))
        if 0 <= x < self.w and 0 <= y < self.h:
            self.b[y][x] = c
            self.g[y][x] = g
            if bare:
                self.bare.add((x, y))
            else:
                self.bare.discard((x, y))

    def has(self, x, y):
        return 0 <= x < self.w and 0 <= y < self.h and self.b[y][x] is not None

    def erase(self, x, y):
        if 0 <= x < self.w and 0 <= y < self.h:
            self.b[y][x] = None
            self.g[y][x] = None
            self.bare.discard((x, y))

    def glow(self, x, y, g, body=None):
        x, y = int(math.floor(x + 0.5)), int(math.floor(y + 0.5))
        if 0 <= x < self.w and 0 <= y < self.h:
            if body:
                self.b[y][x] = body
            self.g[y][x] = g

    def _lvl(self, x, y, lvl, ramp, dk, tex):
        lvl += (hsh(x, y, self.seed) - 0.5) * tex
        i = 1 if lvl < -0.3 else (3 if lvl > 0.45 else 2)
        return ramp[max(0, min(3, i - dk))]

    def seg(self, a, b, r0, r1, ramp, dk=0, tex=0.3):
        """A capsule from a to b whose radius runs from r0 to r1, shaded round."""
        x0 = int(min(a[0], b[0]) - max(r0, r1) - 1)
        x1 = int(max(a[0], b[0]) + max(r0, r1) + 2)
        y0 = int(min(a[1], b[1]) - max(r0, r1) - 1)
        y1 = int(max(a[1], b[1]) + max(r0, r1) + 2)
        dx, dy = b[0] - a[0], b[1] - a[1]
        ll = dx * dx + dy * dy
        for y in range(y0, y1):
            for x in range(x0, x1):
                t = 0.0 if ll == 0 else max(0.0, min(1.0, ((x - a[0]) * dx + (y - a[1]) * dy) / ll))
                qx, qy = a[0] + dx * t, a[1] + dy * t
                r = r0 + (r1 - r0) * t
                d = math.hypot(x - qx, y - qy)
                if d <= r:
                    lvl = 0.0 if d < 0.01 or r < 0.9 else ((x - qx) * LX + (y - qy) * LY) / r
                    self.put(x, y, self._lvl(x, y, lvl, ramp, dk, tex))

    def ell(self, c, rx, ry, ramp, dk=0, tex=0.3, fold=0.0, skew=0.0, phase=0.0):
        for y in range(int(c[1] - ry - 1), int(c[1] + ry + 2)):
            for x in range(int(c[0] - rx - 1), int(c[0] + rx + 2)):
                u, v = (x - c[0]) / rx, (y - c[1]) / ry
                if u * u + v * v <= 1.0:
                    lvl = u * LX + v * LY
                    if fold:
                        lvl = lvl * 0.6 + math.sin(x * fold + y * skew + phase) * 0.5
                    self.put(x, y, self._lvl(x, y, lvl, ramp, dk, tex))

    def poly(self, pts, ramp, dk=0, fold=0.0, skew=0.0, phase=0.0, tex=0.3):
        """A filled polygon; with fold > 0 it is cloth: folds of that frequency run down it, leaning by skew."""
        ys = [p[1] for p in pts]
        n = len(pts)
        for y in range(int(math.floor(min(ys))), int(math.ceil(max(ys))) + 1):
            xs = []
            for i in range(n):
                (xa, ya), (xb, yb) = pts[i], pts[(i + 1) % n]
                if (ya <= y < yb) or (yb <= y < ya):
                    xs.append(xa + (y - ya) * (xb - xa) / (yb - ya))
            xs.sort()
            for i in range(0, len(xs) - 1, 2):
                for x in range(int(math.ceil(xs[i] - 0.5)), int(math.floor(xs[i + 1] + 0.5)) + 1):
                    lvl = math.sin(x * fold + y * skew + phase) * 0.6 if fold else 0.0
                    self.put(x, y, self._lvl(x, y, lvl, ramp, dk, tex))

    def line(self, a, b, c, g=None, bare=False):
        n = int(max(abs(b[0] - a[0]), abs(b[1] - a[1])) + 0.5)
        for i in range(n + 1):
            t = i / n if n else 0
            self.put(a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t, c, g, bare)

    def stamp(self, x, y, rows, legend, flip=False):
        """Hand-set pixels: rows of characters, legend {char: body | (body, glow)}; '.' leaves what is there,
        '_' erases."""
        for j, row in enumerate(rows):
            for i, ch in enumerate(row):
                if ch == ".":
                    continue
                px = x + (len(row) - 1 - i if flip else i)
                if ch == "_":
                    self.erase(int(px), int(y + j))
                    continue
                v = legend[ch]
                if isinstance(v, tuple):
                    self.put(px, y + j, v[0], v[1])
                else:
                    self.put(px, y + j, v)

    def tatter(self, x0, x1, seed, depth, shift=0, y_min=0):
        """Tears the lower edge between columns x0 and x1: teeth two pixels wide of a hashed length up to depth."""
        for x in range(int(x0), int(x1) + 1):
            col = [y for y in range(self.h) if self.b[y][x] is not None]
            if not col:
                continue
            cut = int(hsh((x + shift) // 2, 7, seed) * (depth + 1))
            y = col[-1]
            while cut > 0 and y >= y_min and self.b[y][x] is not None:
                self.erase(x, y)
                y -= 1
                cut -= 1

    def crack(self, pts, hot="ember", dim="emberDim", body="tile"):
        """A glowing fissure along a polyline, on body pixels only: hot in the middle, dim at both ends."""
        cells = []
        for (a, b) in zip(pts, pts[1:]):
            n = int(max(abs(b[0] - a[0]), abs(b[1] - a[1])) + 0.5)
            for i in range(n + (1 if b is pts[-1] else 0)):
                t = i / n if n else 0
                c = (int(math.floor(a[0] + (b[0] - a[0]) * t + 0.5)), int(math.floor(a[1] + (b[1] - a[1]) * t + 0.5)))
                if c not in cells:
                    cells.append(c)
        m = len(cells)
        for i, (x, y) in enumerate(cells):
            if self.has(x, y):
                edge = i < max(1, m // 4) or i >= m - max(1, m // 4)
                self.b[y][x] = body
                self.g[y][x] = dim if edge else hot

    def wisp(self, x, y, n, seed, c="nightBlue", dx=-1.0, dy=-0.6):
        """Smoke coming off an edge: n loose pixels drifting back and up, no outline."""
        px, py = float(x), float(y)
        for i in range(n):
            px += dx * (0.6 + hsh(i, seed, 3))
            py += dy * (0.4 + hsh(i, seed, 5) * 1.2)
            xi, yi = int(math.floor(px + 0.5)), int(math.floor(py + 0.5))
            if 0 <= xi < self.w and 0 <= yi < self.h and self.b[yi][xi] is None:
                self.put(xi, yi, c, None, True)

    def finish(self, outline="nightDeep", rim="emberDim", up=3):
        """The 1 px outline, then the glowing contour: the outline pixel over each column's topmost body pixel and
        over every upward edge with at least `up` free pixels above it."""
        w, h = self.w, self.h
        body = [[self.b[y][x] is not None and (x, y) not in self.bare for x in range(w)] for y in range(h)]
        edge = []
        for y in range(h):
            for x in range(w):
                if self.b[y][x] is None and ((x > 0 and body[y][x - 1]) or (x < w - 1 and body[y][x + 1])
                                             or (y > 0 and body[y - 1][x]) or (y < h - 1 and body[y + 1][x])):
                    edge.append((x, y))
        for x, y in edge:
            self.b[y][x] = outline
        if rim:
            es = set(edge)
            for x, y in edge:
                if x in self.norim or y + 1 >= h or not body[y + 1][x]:
                    continue
                free = 0
                yy = y - 1
                while yy >= 0 and self.b[yy][x] is None and free < up:
                    free += 1
                    yy -= 1
                if yy < 0 or free >= up:
                    self.g[y][x] = rim
        return self


EYE = {"E": ("stoneLight", "wraithWhite"), "e": ("stoneMid", "wraithGlow"), "d": ("stoneDark", "wraithDim")}


def leg(f, hip, foot, l1, l2, r0, r1, r2, ramp, dk=0, bend=-1):
    knee = ik(hip, foot, l1, l2, bend)
    f.seg(hip, knee, r0, r1, ramp, dk)
    f.seg(knee, foot, r1, r2, ramp, dk)
    return knee


# hand-set frames of the small creatures: one character per pixel
SMALL = {"h": "nightBlue", "H": "nightSlate", "k": "night0", "s": "stoneMid", "S": "stone", "d": "stoneDark",
         "r": "moorDark", "R": "moor", "t": "roofDeep", "j": "night0", "i": "stoneDark",
         "n": "nightDeep",                                         # the hollow of a socket or a hood
         "E": ("stoneLight", "wraithWhite"), "e": ("stoneMid", "wraithGlow"), "w": ("stoneDark", "wraithDim"),
         "c": ("tile", "ember"), "C": ("tile", "emberDim")}


def grid(w, h, rows, seed=0, rim="emberDim", up=2):
    assert len(rows) == h and all(len(r) == w for r in rows), [len(r) for r in rows]
    f = Frame(w, h, seed)
    f.stamp(0, 0, rows, SMALL)
    return f.finish(rim=rim, up=up)
