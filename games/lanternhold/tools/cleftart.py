#!/usr/bin/env python3
"""Lanternhold world rebuild, step world-1 (docs/REVIEW-look-2.md 2.3, 2.5, B5, B6, H1, H2, H6): the rock of the
Throat and the cleft. Pure python on pixelart.py's Image, palette colours only, no randomness (hashes of the position),
so a run reproduces its files byte for byte. One sprite per run of `build` (each well under 20 s on the old Mac).

  cleftart.py build <id> --out <Art dir>
  cleftart.py noslot <weltmauer.png>        the Weltmauer without the far castle in its first slot (in place)

  throatStepA    224x128, mid plane, ground: the Throat's far wall where it begins, far and pale (the far ramp), low,
                 its west end a talus that pales into the mist band. mid x 360.
  throatStepB    224x176, mid plane, ground: the second step, a value darker and taller (the slate ramp), with the
                 warden statue's niche. mid x 450.
  throatStepC    224x200, mid plane, top-anchored: the third step, the cleft's own granite: its west end a crag that
                 falls to the lane, then it climbs into the sky behind the gatehouse and goes on, pixel for pixel,
                 as cleftWallA. mid x 600.
  cleftWallA..C  256x200, 256x200, 192x200, mid plane, top-anchored: the cleft's far wall behind the whole castle, at
                 full height with a jagged slit of sky in its top rows: buttresses and chimneys catching cold light,
                 ledges, snow in the high cracks, three threads of water with spray; C ends toward the valley in crags
                 that step down to the valley floor. mid x 824, 1080, 1336.
  cleftShaft     64x200 white alpha mask: the cold shaft of light that falls through the slit by day (the engine
                 draws it at the sun's strength). mid x 1104.
  gateRockL      56x120, world plane: the granite the gatehouse's west tower grows out of (its east 16 columns lie
                 over the tower's foot). world x castle front - 40.
  gateRockR      28x64, world plane: the same at the east tower's outer foot (its west 21 columns over the tower).
                 world x castle front + 218.

Light from the upper left, as everywhere. All of C and the walls are painted on one canvas in mid-plane x, so their
joins are seamless; the steps are canvases of their own.
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import pixelart as PA  # noqa: E402
import worldart as WA  # noqa: E402

h01 = WA.h01
vnoise = WA.vnoise
vnoise2 = WA.vnoise2
CLEAR = (0, 0, 0, 0)
BAYER = [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]


def bay(x, y):
    return (BAYER[((y & 3) << 2) | (x & 3)] + 0.5) / 16


def col(name):
    return WA.col(name)


# The ramps, dark to light. The cleft is the castle's granite (warm-neutral, the engine's night pulls it blue), the
# steps grow paler and bluer with distance.
RAMPS = {
    "cleft": ["nightBlue", "rockDeep", "rockDark", "rock", "rockLight", "rockPale"],
    "slate": ["nightSlate", "stoneDark", "stoneMid", "stone", "mistDark", "stoneLight"],
    "far": ["nightSlate", "farDeep", "far", "mistDark", "mist", "farPale"],
}
SNOW = {"cleft": ("stoneLight", "mistLight", "foam"), "slate": ("mist", "mistLight", "foam"),
        "far": ("mist", "farPale", "mistLight")}


class Rock:
    """A granite face over the plane's x and rows from the canvas top, in two scales: great buttresses with a lit west
    strip, a broad front and a shaded east side, dark chimneys between them (wider where the neighbours stand at
    different depths); inside each buttress the slabs of its joints, each a little lighter or darker. Ledges that catch
    the sky with an overhang's shadow under them, wet streaks below the ledges, a light top under the slit and a dark
    foot in the cleft's shade. `sample` gives a value 0 (black) ... 1 (the palest) and the kind of pixel (chimney,
    joint, ledge, under a ledge, face)."""

    def __init__(self, seed, x0, x1, h, wmin, wmax, ledge=(26, 70), contrast=1.0, foot=0.22, top=0.18, base=0.42,
                 benches=()):
        self.seed, self.h, self.contrast, self.foot, self.top, self.base = seed, h, contrast, foot, top, base
        self.benches = benches  # rows of the great benches that cross the whole face (the strata's scale)
        self.ledge = ledge
        self.bounds = []
        x, i = x0 - 2 * wmax, 0
        while x < x1 + 2 * wmax:
            self.bounds.append((x, (h01(seed, i, 2) - 0.5) * 0.12))
            x += wmin + (wmax - wmin) * h01(seed, i, 3) ** 0.8
            i += 1
        n = len(self.bounds)
        self.depth = [h01(seed, j, 4) for j in range(n)]
        self.ridge = [0.16 + 0.18 * h01(seed, j, 5) for j in range(n)]
        self.shade = [0.62 + 0.22 * h01(seed, j, 6) for j in range(n)]
        self.joints = []
        for j in range(n):
            k = 1 + int(3 * h01(seed, j, 7))
            self.joints.append(sorted(0.15 + 0.75 * h01(seed, j, m, 8) for m in range(k)))
        self.cache = {}

    def edge(self, j, y):
        x, lean = self.bounds[j]
        return x + 9 * (vnoise(self.seed * 31 + j, y / 47.0) - 0.5) + 1.5 * (vnoise(self.seed * 37 + j, y / 9.0) - 0.5) \
            + lean * (y - self.h * 0.5)

    def column(self, x, y):
        lo, hi = 0, len(self.bounds) - 2
        while lo < hi:  # the last boundary west of x at this row (the boundaries never cross)
            mid = (lo + hi + 1) // 2
            if self.edge(mid, y) <= x:
                lo = mid
            else:
                hi = mid - 1
        a, b = self.edge(lo, y), self.edge(lo + 1, y)
        return lo, (x - a) / max(1.0, b - a), b - a

    def ledges(self, j):
        if j in self.cache:
            return self.cache[j]
        out, y, k = [], 10 + 30 * h01(self.seed, j, 9), 0
        while y < self.h:
            s0 = 0.25 * h01(self.seed, j, k, 10)
            s1 = 1.0 - 0.35 * h01(self.seed, j, k, 11)
            out.append((y, (h01(self.seed, j, k, 12) - 0.5) * 0.35, s0, s1, h01(self.seed, j, k, 13)))
            y += self.ledge[0] + (self.ledge[1] - self.ledge[0]) * h01(self.seed, j, k, 14)
            k += 1
        self.cache[j] = out
        return out

    def sample(self, x, y):
        j, s, width = self.column(x, y)
        d = self.depth[j]
        c = self.contrast
        px = s * width
        prev = self.depth[j - 1] if j > 0 else d
        # The chimney at the buttress's west side: dark, deepest at its middle; the nearer side's lip catches light.
        chim = 2.0 + 9.0 * abs(d - prev)
        if px < chim:
            u = px / chim
            v = 0.06 + 0.10 * abs(u - 0.5) * 2
            if d > prev and u > 0.75:
                v += 0.25 * c
            return v, "crack"
        s2 = (px - chim) / max(1.0, width - chim)
        r = self.ridge[j]
        if s2 < r:
            face = 0.30          # the west strip faces the light
        elif s2 < self.shade[j]:
            face = 0.12 - 0.12 * (s2 - r) / (self.shade[j] - r)   # the broad front, darker toward the east
        elif s2 < self.shade[j] + 0.12:
            face = -0.18         # the turn into shade
        else:
            face = -0.28
        v = self.base + c * face + (d - 0.5) * 0.24 * c
        kind = "face"
        # The slabs between the joints, each its own value; a joint is a thin dark line.
        slab = 0
        for m, js in enumerate(self.joints[j]):
            jx = js * width + 4 * (vnoise(self.seed * 41 + j * 7 + m, y / 21.0) - 0.5)
            if abs(px - jx) < 0.6:
                return v - 0.26 * c, "joint"
            if px > jx:
                slab = m + 1
        v += (h01(self.seed, j, slab, 15) - 0.5) * 0.14 * c
        for (ly, tilt, s0, s1, big) in self.ledges(j):
            if not (s0 <= s2 <= s1):
                continue
            dy = y - (ly + tilt * px + 2.5 * (vnoise(self.seed * 47 + j, x / 6.0) - 0.5))
            if -1.0 <= dy < 0.0:
                if vnoise(self.seed * 53 + j, x / 3.0) > 0.3:
                    v = max(v + 0.22, 0.72)
                    kind = "ledge"
                break
            under = 1.5 + 4.0 * big * vnoise(self.seed * 59 + j, x / 5.0)
            if 0.0 <= dy < under:
                v -= (0.32 - 0.24 * dy / max(1.0, under)) * c
                kind = "under"
                break
            if under <= dy < under + 30 and vnoise(self.seed * 43 + j, x / 2.0 + big * 9) > 0.78:
                v -= 0.12 * (1 - (dy - under) / 30.0)   # a wet streak runs down from the ledge
            elif -10.0 <= dy < -1.0:
                v += 0.05 * (1 + dy / 10.0)          # the slab above a ledge is lit near its foot
        for k, by in enumerate(self.benches):
            # A bench: the whole face steps back, its top catches the sky, the overhang over the next one throws a
            # deep shadow; it wanders and breaks off where a buttress stands proud.
            row = by + 7 * (vnoise(self.seed * 71 + k, x / 23.0) - 0.5) + 2 * (vnoise(self.seed * 73 + k, x / 5.0) - 0.5)
            dy = y - row
            if d > 0.82 and vnoise(self.seed * 79 + k, x / 11.0) > 0.5:
                continue
            if -2.0 <= dy < 0.0:
                v = max(v + 0.2, 0.7)
                kind = "ledge"
            elif 0.0 <= dy < 6.0 + 3 * vnoise(self.seed * 83 + k, x / 7.0):
                v = min(v, 0.14 + 0.03 * dy) * c + (1 - c) * v
                kind = "under"
        v += 0.07 * (vnoise2(self.seed * 13, x / 7.0, y / 16.0) - 0.5)
        v += 0.03 * (vnoise2(self.seed * 17, x / 2.0, y / 3.0) - 0.5)
        t = y / float(self.h)
        v += self.top * max(0.0, 1 - t / 0.45) - self.foot * max(0.0, (t - 0.66) / 0.34)
        return v, kind


def quant(ramp, v, x, y, dither=0.38):
    n = len(ramp)
    q = v * (n - 1) + (bay(x, y) - 0.5) * dither
    return ramp[max(0, min(n - 1, int(round(q))))]


def paint(img, rock, gx0, inside, ramp_name, snow_rows=0, water=(), mist_left=None, extra=None):
    """Paints the rock into img where inside(gx, y) holds (gx: the plane's x of the column). `mist_left` = (gx_a,
    gx_b): west of gx_b the rock pales toward the mist and thins away by gx_a."""
    ramp = [col(n) for n in RAMPS[ramp_name]]
    snow = [col(n) for n in SNOW[ramp_name]]
    mist, mist_dark = col("mist"), col("mistDark")
    for y in range(img.h):
        for x in range(img.w):
            gx = gx0 + x
            if not inside(gx, y):
                continue
            v, kind = rock.sample(gx, y)
            if extra:
                v = extra(gx, y, v)
            c = quant(ramp, v, gx, y)
            if snow_rows and y < snow_rows:
                share = (snow_rows - y) / float(snow_rows)
                run = vnoise(rock.seed * 61 + y, gx / 4.0)
                if kind == "ledge" and run < 0.25 + 0.6 * share:
                    c = snow[2] if v > 0.8 else snow[1]
                elif kind == "crack" and run < 0.5 * share and vnoise(rock.seed * 67, y / 3.0 + gx) < 0.6:
                    c = snow[0]
                elif kind == "under" and y < snow_rows * 0.5 and run < 0.35 * share:
                    c = snow[1]
            if mist_left and gx < mist_left[1]:
                # West of the step's body the rock pales toward the mist's colour (no holes: a dithered alpha
                # reads as a column of noise); the mist band before it does the rest.
                t = (mist_left[1] - gx) / float(mist_left[1] - mist_left[0])
                if t > 0.66 or (t > 0.33 and bay(gx, y) < (t - 0.33) * 3):
                    c = mist if v > 0.5 else mist_dark
            img.set(x, y, c)
    for w in water:
        thread(img, gx0, rock.seed, *w)


def thread(img, gx0, seed, gx, y0, y1, spray):
    """A thin thread of water falling from a ledge: one pixel wide, foam and pale mist in short runs (it reads as
    falling), a step aside here and there, spray where it lands on a ledge."""
    foam, mist, light = col("foam"), col("mist"), col("mistLight")
    x = gx - gx0
    y = y0
    while y < y1:
        if 0 <= x < img.w and img.get(x, y)[3]:
            r = h01(seed, gx, y // 2, 39)
            if r > 0.18:
                img.set(x, y, light if r > 0.62 else mist if r > 0.36 else foam)
        y += 1
        if h01(seed, gx, y, 41) < 0.02:
            x += 1 if h01(seed, gx, y, 43) < 0.5 else -1
    x = gx - gx0
    for (sy, r) in spray:
        for dy in range(-1, int(r * 1.6)):
            half = int(1 + r * (0.4 + 0.6 * max(0, dy) / (r * 1.6)))
            for dx in range(-half, half + 1):
                xx, yy = x + dx, sy + dy
                if not (0 <= xx < img.w and 0 <= yy < img.h) or not img.get(xx, yy)[3]:
                    continue
                d = (abs(dx) / float(half + 1)) + max(0, dy) / (r * 2.0)
                if bay(xx + gx0, yy) > 0.25 + 0.75 * d:
                    img.set(xx, yy, mist if d > 0.45 else light)


def rim(img, gx0, seed=911):
    """A cold rim of snow and pale stone on the rock's top edge."""
    snow, pale = col("mistLight"), col("stoneLight")
    for x in range(img.w):
        for y in range(img.h):
            if img.get(x, y)[3]:
                if y > 0 and h01(seed, gx0 + x) < 0.55:
                    img.set(x, y, snow if h01(seed + 2, gx0 + x) < 0.5 else pale)
                break


# ---------------------------------------------------------------------------------------------- the cleft's canvas

CLEFT_X0, CLEFT_X1, CLEFT_H = 600, 1528, 200
PIECES = {"throatStepC": (600, 224), "cleftWallA": (824, 256), "cleftWallB": (1080, 256), "cleftWallC": (1336, 192)}
SLIT_ROWS = 24


def slit(gx):
    """Rows from the canvas top where the rock begins along the slit: a jagged edge of teeth of every size, notches
    between them, and here and there a chockstone that bridges the slit up to the top row."""
    base = 8 + 10 * vnoise(501, gx / 31.0) + 5 * vnoise(503, gx / 9.0)
    # teeth: a walk of irregular widths, each tooth its own height and lean
    k, x0 = 0, -40.0
    while True:
        wdt = 4 + 13 * h01(505, k)
        if x0 + wdt > gx:
            break
        x0 += wdt
        k += 1
    u = (gx - x0) / wdt
    lean = 0.25 + 0.5 * h01(506, k)
    shape = u / lean if u < lean else (1 - u) / (1 - lean)
    tip = base - (3 + 9 * h01(507, k))
    t = base - (base - tip) * shape ** 0.7
    b = int((gx + 13) // 53)
    if h01(508, b) < 0.25:
        v = ((gx + 13) % 53) / 53.0
        if 0.35 < v < 0.5 + 0.18 * h01(509, b):
            t = min(t, 1 + 2 * abs(math.sin(gx * 0.7)))  # a chockstone wedged across the slit
    return max(0.0, min(SLIT_ROWS, t))


def cleft_top(gx):
    """The rock's top (rows from the canvas top) over the whole canvas: the step's west crag, the slit, the end."""
    t = slit(gx)
    if gx < 690:
        # throatStepC's west part: a lower shoulder that climbs into the slit, then a crag that falls to the lane in
        # three ledges.
        u = (690 - gx) / 90.0
        t = t + 34 * min(1.0, u) ** 1.2 + 5 * (vnoise(511, gx / 7.0) - 0.5)
        if gx < 628:
            f = (628 - gx) / 28.0
            drop = 0.0
            for edge_x, depth in ((628, 18), (622, 42), (614, 70), (607, 96)):
                if gx < edge_x:
                    drop = depth
            t += drop + 120 * max(0.0, f - 0.55) ** 1.5 + 3 * h01(513, int(gx))
    if gx > 1340:
        # cleftWallC: the cleft opens to the valley, the wall steps down in crags.
        u = (gx - 1340) / 150.0
        fall = 168 * min(1.0, u) ** 1.25
        fall += 10 * (h01(515, int(gx // 13)) - 0.5) * min(1.0, u * 3) + 6 * abs(math.sin(gx / 5.0)) * min(1.0, u * 2)
        if gx > 1490:
            fall = max(fall, 176 + (gx - 1490) * 0.6)
        t = t + fall
    return t


def cleft_piece(name):
    gx0, w = PIECES[name]
    rock = Rock(601, CLEFT_X0, CLEFT_X1, CLEFT_H, 38, 104, ledge=(26, 66), contrast=1.0, foot=0.28, top=0.20,
                base=0.40, benches=(74, 128))
    img = PA.Image(w, CLEFT_H)
    tops = {gx: cleft_top(gx) for gx in range(gx0, gx0 + w)}
    water = [  # (gx, from row, to row, [(spray row, radius)])
        (902, 52, 186, [(118, 3), (176, 5)]),
        (1131, 38, 190, [(96, 3), (150, 4), (182, 6)]),
        (1268, 64, 186, [(132, 4), (178, 5)]),
    ]
    mine = [wt for wt in water if gx0 <= wt[0] < gx0 + w]
    paint(img, rock, gx0, lambda gx, y: y >= tops[gx], "cleft", snow_rows=62, water=mine)
    rim(img, gx0)
    return img


# ---------------------------------------------------------------------------------------------- the steps

def step_a():
    w, h, gx0 = 224, 128, 360
    rock = Rock(361, gx0, gx0 + w, h, 16, 44, ledge=(14, 34), contrast=0.6, foot=0.10, top=0.10, base=0.50)

    def hgt(gx):  # rows above the canvas bottom: crags that step down westward into the mist
        u = (gx - gx0) / float(w)
        base = 10 + 100 * min(1.0, (u / 0.66)) ** 0.9
        k = int((gx - gx0) // 9)
        step = 8 * (h01(365, k) - 0.5) * min(1.0, u * 3)
        return min(h - 6, base + step + 5 * (vnoise(363, gx / 6.0) - 0.5) + 4 * abs(math.sin(gx / 3.7)) * min(1.0, u * 2.5))

    img = PA.Image(w, h)
    tops = {gx: h - hgt(gx) for gx in range(gx0, gx0 + w)}
    paint(img, rock, gx0, lambda gx, y: y >= tops[gx], "far", snow_rows=26, mist_left=(gx0, gx0 + 92))
    rim(img, gx0)
    return img


def step_b():
    w, h, gx0 = 224, 176, 450
    rock = Rock(451, gx0, gx0 + w, h, 24, 66, ledge=(18, 48), contrast=0.8, foot=0.16, top=0.14, base=0.46)

    def hgt(gx):
        u = (gx - gx0) / float(w)
        base = 20 + 136 * min(1.0, u / 0.4) ** 0.8
        k = int((gx - gx0 + 5) // 11)
        crag = 9 * (h01(455, k) - 0.5) + 6 * (vnoise(453, gx / 7.0) - 0.5)
        tooth = abs(((gx - gx0 + 5) % 11) / 5.5 - 1.0)
        east = max(0.0, gx - 640) * 1.1  # its east end sinks under throatStepC's top
        return min(h - 1, base + crag + 7 * (1 - tooth) * h01(457, k) * min(1.0, u * 2) - east)

    img = PA.Image(w, h)
    tops = {gx: h - hgt(gx) for gx in range(gx0, gx0 + w)}

    def extra(gx, y, v):
        # The warden statue's niche (the statue stands at mid 520 to 616, its crown 166 over the ground line).
        dx = abs(gx - 568.0)
        if dx < 40:
            arch = (h - 160) + 26 - math.sqrt(max(0.0, 40 * 40 - dx * dx)) * 0.65
            if y > arch:
                return v - 0.24 - 0.10 * (dx > 36)
        return v

    paint(img, rock, gx0, lambda gx, y: y >= tops[gx], "slate", snow_rows=40, mist_left=(gx0, gx0 + 44),
          extra=extra)
    rim(img, gx0)
    return img


def mist_foot(img, gx0, rows):
    """The lowest rows thin into the mist band (it lies before them in the game; the rock must not end in a line)."""
    for y in range(img.h - rows, img.h):
        t = (y - (img.h - rows)) / float(rows)
        for x in range(img.w):
            if img.get(x, y)[3] and bay(gx0 + x, y) < t * 0.6:
                img.set(x, y, col("mistDark"))


# ---------------------------------------------------------------------------------------------- the shaft

def shaft():
    """A soft diagonal beam, white with alpha in eight levels and ordered dither between them; it falls from the
    slit toward the lower right (light from the upper left) and fades out before the cleft's floor."""
    w, h = 64, 200
    img = PA.Image(w, h)
    levels = [0, 18, 36, 54, 72, 90, 108, 126]
    for y in range(h):
        cx = 14 + y * 0.18
        half = 7 + y * 0.06
        fade = min(1.0, y / 14.0) * (1 - max(0.0, (y - 130) / 70.0))
        for x in range(w):
            d = abs(x + 0.5 - cx) / half
            a = max(0.0, 1 - d) ** 1.4 * fade
            a *= 0.85 + 0.15 * math.sin(y / 9.0 + x / 5.0)
            q = a * (len(levels) - 1) + (bay(x, y) - 0.5)
            k = max(0, min(len(levels) - 1, int(round(q))))
            if levels[k]:
                img.set(x, y, (255, 255, 255, levels[k]))
    return img


# ---------------------------------------------------------------------------------------------- the gate's rock

def gate_rock(name):
    """A knoll of the cleft's granite that the tower stands on: blocky steps down to the lane away from the tower, and
    over the tower's foot a ragged top that climbs into the masonry's joints."""
    if name == "gateRockL":
        w, h, gx0, seed, tower = 56, 120, 1200, 1201, 1
    else:
        w, h, gx0, seed, tower = 28, 64, 1458, 1467, -1
    peak = h - 40 if name == "gateRockL" else h - 16
    tops = {}
    for x in range(w):
        u = x / float(w - 1) if tower > 0 else 1 - x / float(w - 1)   # 1 at the tower's side
        k = int(x // 4)
        # a rounded knoll that peaks short of the tower, then a stair of blocks down over the tower's foot (the
        # masonry stands on it, so the border is ragged, never a vertical line)
        knoll = 1 - ((u - 0.58) / 0.58) ** 2
        hg = 8 + (peak - 8) * max(0.0, knoll) ** 0.7
        if u > 0.62:
            stair = int((u - 0.62) / 0.38 * 5) / 5.0
            hg = min(hg, peak * (1 - 0.72 * stair) - 10 * h01(seed, k, 3))
        hg += 5 * (h01(seed, k) - 0.5) + 2 * (vnoise(seed + 2, x / 3.0) - 0.5)
        tops[gx0 + x] = h - max(5.0, hg)
    rock = Rock(seed, gx0, gx0 + w, h, 12, 26, ledge=(10, 22), contrast=1.0, foot=0.12, top=0.08, base=0.44)
    img = PA.Image(w, h)
    paint(img, rock, gx0, lambda gx, y: y >= tops[gx], "cleft")
    rim(img, gx0)
    return img


# ---------------------------------------------------------------------------------------------- the Weltmauer

SLOT = (298, 352)  # the first slot's columns in weltmauer.png (the far castle from the shadow land)


def noslot(path):
    """Fills the first slot with the wall beside it: each column takes the column a slot's width to its west, so the
    ridge, the snow and the granite go on; the two columns at each side of the patch are blended by dither."""
    img = PA.read_png(path)[0]
    span = SLOT[1] - SLOT[0]
    out = PA.Image(img.w, img.h, list(img.px))
    for x in range(SLOT[0] - 2, SLOT[1] + 2):
        for y in range(img.h):
            src = img.get(x - span, y)
            if SLOT[0] <= x < SLOT[1] or bay(x, y) < 0.5:
                out.set(x, y, src)
    PA.write_png(path, out)
    print("wrote", path)


def build(name, out):
    if name in PIECES:
        img = cleft_piece(name)
    elif name == "throatStepA":
        img = step_a()
    elif name == "throatStepB":
        img = step_b()
    elif name == "cleftShaft":
        img = shaft()
    elif name in ("gateRockL", "gateRockR"):
        img = gate_rock(name)
    else:
        raise SystemExit("unknown sprite " + name)
    path = os.path.join(out, name + ".png")
    PA.write_png(path, img)
    print("wrote", path, img.w, "x", img.h)


def main():
    a = sys.argv[1:]
    if len(a) >= 2 and a[0] == "noslot":
        noslot(a[1])
        return
    if len(a) >= 4 and a[0] == "build" and a[2] == "--out":
        build(a[1], a[3])
        return
    raise SystemExit(__doc__)


if __name__ == "__main__":
    main()
