#!/usr/bin/env python3
"""Lanternhold world rebuild, step world-1: granite as a height field (docs/REVIEW-look-2.md H1, H2, B6). Pure python,
palette colours only, no randomness (hashes of the position), so a run reproduces its files byte for byte.

A rock face is a height field z(x, y): how far each pixel stands out toward the viewer. A `Massif` builds it from
buttresses (columns of rock whose boundaries wander down the face, each its own depth, with a lit west bevel, a broad
front and a shaded east bevel), the chimneys between them, ledges (the block below steps out: a lit top) and overhangs
(the block above steps out: a shadow under it), joints (thin V grooves), exfoliation sheets (long diagonal steps),
a slow swell and a fine grain. `shade` lights the field from the upper left and from the sky above (the cleft's slit):
Lambert on the field's normal, cast shadows marched toward the light, a cavity term, and less light deeper down. The
painter maps the light onto a ramp of palette colours with a sparse ordered dither, and adds snow on the faces that
look up, a cold rim on the edges that meet the sky, wet streaks and threads of water.

Light from the upper left, as everywhere in the game.
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
BAYER = [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]


def bay(x, y):
    return (BAYER[((y & 3) << 2) | (x & 3)] + 0.5) / 16


def ss(t):
    t = min(1.0, max(0.0, t))
    return t * t * (3 - 2 * t)


def col(name):
    return WA.col(name)


RAMPS = {
    # dark to light. The cleft is the castle's own granite, warm-neutral (the engine's night pulls it blue); the
    # Throat's steps pale and cool with distance; the gate's rock is the cleft's, a step stronger (the world plane).
    "cleft": ["nightBlue", "rockDeep", "rockDark", "rock", "rockLight", "rockPale"],
    "slate": ["nightSlate", "stoneDark", "stoneMid", "stone", "mistDark", "stoneLight"],
    "far": ["nightSlate", "farDeep", "far", "mistDark", "mist", "farPale"],
    "gate": ["nightDeep", "rockDeep", "rockDark", "rock", "rockLight", "rockPale"],
}
COLD = {"cleft": ["nightBlue", "stoneDark", "stoneMid", "stone", "stoneLight", "mistLight"],
        "gate": ["nightDeep", "stoneDark", "stoneMid", "stone", "stoneLight", "mistLight"]}
SNOW = {"cleft": ("stoneLight", "mistLight", "foam"), "slate": ("mist", "mistLight", "foam"),
        "far": ("mist", "farPale", "mistLight"), "gate": ("stoneLight", "mistLight", "foam")}


class Massif:
    """The height field of a granite face over the plane's x (gx) and rows (y, 0 at the canvas top)."""

    def __init__(self, seed, x0, x1, h, wmin, wmax, relief=1.0, ledge_gap=(18, 52), sheets=True):
        self.seed, self.h, self.relief = seed, h, relief
        self.ledge_gap = ledge_gap
        self.sheets = sheets
        self.bounds = []
        x, i = x0 - 2 * wmax, 0
        while x < x1 + 2 * wmax:
            self.bounds.append((x, (h01(seed, i, 2) - 0.5) * 0.10))
            x += wmin + (wmax - wmin) * h01(seed, i, 3) ** 0.9
            i += 1
        n = len(self.bounds)
        # each buttress: its depth (how far it stands out), its bevels (shares of its width), how deep they cut
        self.depth = [h01(seed, j, 4) for j in range(n)]
        self.west = [0.10 + 0.18 * h01(seed, j, 5) for j in range(n)]
        self.east = [0.18 + 0.24 * h01(seed, j, 6) for j in range(n)]
        self.bevel = [6.0 + 9.0 * h01(seed, j, 7) for j in range(n)]
        self.cache_ledges = {}
        self.cache_joints = {}

    # -- the buttresses
    def edge(self, j, y):
        x, lean = self.bounds[j]
        return x + 10 * (vnoise(self.seed * 31 + j, y / 53.0) - 0.5) + 2.0 * (vnoise(self.seed * 37 + j, y / 11.0) - 0.5) \
            + lean * (y - self.h * 0.5)

    def column(self, gx, y):
        lo, hi = 0, len(self.bounds) - 2
        while lo < hi:
            mid = (lo + hi + 1) // 2
            if self.edge(mid, y) <= gx:
                lo = mid
            else:
                hi = mid - 1
        a, b = self.edge(lo, y), self.edge(lo + 1, y)
        return lo, gx - a, max(1.0, b - a)

    def ledges(self, j):
        """Rows where a buttress steps: (row, tilt, span start, span end, step); a positive step is a ledge (the block
        below stands out), a negative one an overhang."""
        if j in self.cache_ledges:
            return self.cache_ledges[j]
        out, y, k = [], 6 + 30 * h01(self.seed, j, 9), 0
        lo, hi = self.ledge_gap
        while y < self.h + 10:
            step = 1.5 + 4.5 * h01(self.seed, j, k, 10)
            if h01(self.seed, j, k, 11) < 0.32:
                step = -(1.0 + 3.0 * h01(self.seed, j, k, 12))
            s0 = 0.30 * h01(self.seed, j, k, 13) - 0.1
            s1 = 1.1 - 0.4 * h01(self.seed, j, k, 14)
            out.append((y, (h01(self.seed, j, k, 15) - 0.5) * 0.5, s0, s1, step))
            y += lo + (hi - lo) * h01(self.seed, j, k, 16)
            k += 1
        self.cache_ledges[j] = out
        return out

    def joints(self, j):
        """Thin joints inside a buttress: (share across, wander seed, from row, to row)."""
        if j in self.cache_joints:
            return self.cache_joints[j]
        out = []
        for m in range(int(1 + 3 * h01(self.seed, j, 20))):
            a = h01(self.seed, j, m, 21) * self.h
            b = a + (0.3 + 0.7 * h01(self.seed, j, m, 22)) * self.h
            out.append((0.2 + 0.6 * h01(self.seed, j, m, 23), self.seed * 41 + j * 7 + m, a, b))
        self.cache_joints[j] = out
        return out

    def z(self, gx, y):
        j, px, width = self.column(gx, y)
        s = px / width
        r = self.relief
        z = 22.0 * self.depth[j] * r
        # the bevels: the west one faces the light, the east one turns into shade; the chimney between two buttresses
        # is the lowest ground, and deeper where the neighbours stand out further
        w, e, b = self.west[j], self.east[j], self.bevel[j] * r
        if s < w:
            t = s / w
            z += b * (t ** 0.8) - b
        elif s > 1 - e:
            t = (1 - s) / e
            z += b * (t ** 1.3) - b
        dw = min(px, width - px)
        z -= (8.0 * r) * math.exp(-dw / 2.0)
        for (ly, tilt, s0, s1, step) in self.ledges(j):
            if s < s0 or s > s1:
                continue
            row = ly + tilt * px + 2.0 * (vnoise(self.seed * 47 + j, gx / 7.0) - 0.5)
            fade = ss((s - s0) / 0.12) * ss((s1 - s) / 0.12)
            z += step * r * fade * ss((y - row) / 1.6 + 0.5)
        for (share, sd, a, b2) in self.joints(j):
            if a <= y <= b2:
                jx = share * width + 5 * (vnoise(sd, y / 23.0) - 0.5)
                d = abs(px - jx)
                if d < 2.0:
                    taper = ss((y - a) / 8.0) * ss((b2 - y) / 8.0)
                    z -= 2.6 * r * (1 - d / 2.0) * taper
        if self.sheets:
            # exfoliation sheets: long steps that run down to the east at about 60 degrees
            u = gx * 0.55 + y * 0.32
            k = int(u // 37)
            if h01(self.seed, k, 30) < 0.3:
                f = (u - k * 37) / 37.0
                z += 1.4 * r * ss((f - 0.12) / 0.06) * (1 - ss((f - 0.88) / 0.06)) * vnoise(self.seed * 53 + k, y / 40.0)
        z += 10.0 * r * (vnoise2(self.seed * 13, gx / 60.0, y / 90.0) - 0.5)
        z += 1.6 * r * (vnoise2(self.seed * 23, gx / 12.0, y / 20.0) - 0.5)
        z += 0.45 * r * (vnoise2(self.seed * 17, gx / 3.0, y / 4.0) - 0.5)
        return z


class Field:
    """The heights of a massif over a canvas (gx0 ... gx0 + w, rows 0 ... h) with `margin` columns of context on each
    side (the cast shadows come from the west); rows above `top(gx)` are open sky (no rock)."""

    def __init__(self, massif, gx0, w, h, top, margin=48):
        self.gx0, self.w, self.h, self.m = gx0, w, h, margin
        self.top = {gx: top(gx) for gx in range(gx0 - margin, gx0 + w + margin)}
        self.z = []
        for y in range(h):
            row = []
            for x in range(-margin, w + margin):
                gx = gx0 + x
                row.append(massif.z(gx, y) if y >= self.top[gx] else None)
            self.z.append(row)

    def at(self, x, y):
        """Height at canvas x, y (None: sky)."""
        if y < 0:
            return None
        y = min(self.h - 1, y)
        x = max(-self.m, min(self.w + self.m - 1, x))
        return self.z[y][x + self.m]

    def inside(self, x, y):
        return self.at(x, y) is not None


LIGHT = (-0.52, -0.66, 0.54)   # toward the light: west, up, out


def shade(field, x, y, light=LIGHT, sky_fall=0.5, ambient=0.17):
    """The light on a rock pixel: 0 (black) ... about 1, and the normal's y (negative: the face looks up)."""
    z0 = field.at(x, y)
    zl = field.at(x - 1, y)
    zr = field.at(x + 1, y)
    zu = field.at(x, y - 1)
    zd = field.at(x, y + 1)
    # an edge against the sky is a face that turns away toward it (the top looks up, a side looks sideways)
    zl = z0 - 6 if zl is None else zl
    zr = z0 - 6 if zr is None else zr
    zu = z0 - 6 if zu is None else zu
    zd = z0 if zd is None else zd
    nx, ny, nz = -(zr - zl) * 0.5, -(zd - zu) * 0.5, 1.0
    n = math.sqrt(nx * nx + ny * ny + nz * nz)
    nx, ny, nz = nx / n, ny / n, nz / n
    lx, ly, lz = light
    ll = math.sqrt(lx * lx + ly * ly + lz * lz)
    lx, ly, lz = lx / ll, ly / ll, lz / ll
    diff = max(0.0, nx * lx + ny * ly + nz * lz)
    # cast shadow: march toward the light over the field
    hxy = math.sqrt(lx * lx + ly * ly)
    dx, dy, rise = lx / hxy, ly / hxy, lz / hxy
    lit = 1.0
    if diff > 0:
        t = 1.5
        while t < 48:
            sx, sy = int(round(x + dx * t)), int(round(y + dy * t))
            if sy < 0:
                break
            zz = field.at(sx, sy)
            if zz is not None and zz > z0 + rise * t + 1.2:
                lit = 0.0
                break
            t += 1.0
    # cavity: lower than the mean around it
    acc, cnt = 0.0, 0
    for (ox, oy) in ((-4, 0), (4, 0), (0, -4), (0, 4), (-3, -3), (3, -3), (-3, 3), (3, 3)):
        zz = field.at(x + ox, y + oy)
        if zz is not None:
            acc += zz
            cnt += 1
    cav = 0.0 if not cnt else max(-1.0, min(1.0, (z0 - acc / cnt) / 4.0))
    ao = 0.78 + 0.22 * cav
    # the sky light falls off down the face (deep in the cleft); the up-facing faces take more of it
    t = y / float(field.h)
    sky = (1.0 - sky_fall * t ** 1.2) * (1.0 + 0.25 * max(0.0, -ny))
    v = (ambient * ao + 0.86 * diff * lit * (0.85 + 0.15 * ao)) * sky
    return v, ny, lit


def paint(field, ramp_name, gain=1.0, lift=0.0, dither=0.45, snow_rows=0, snow_share=0.6, rim=0.55, mist_left=None,
          wet=(), seed=1, contrast=1.0, cold_rows=0):
    """The field painted on a new image: light → ramp index with a sparse ordered dither; snow on the faces that look
    up in the top `snow_rows`; a cold rim on the edges against the sky; `wet` streaks below water threads; west of
    `mist_left` = (gx_a, gx_b) the rock pales toward the mist."""
    ramp = [col(n) for n in RAMPS[ramp_name]]
    cold = [col(n) for n in COLD.get(ramp_name, RAMPS[ramp_name])]
    snow = [col(n) for n in SNOW[ramp_name]]
    mist, mist_dark = col("mist"), col("mistDark")
    img = PA.Image(field.w, field.h)
    n = len(ramp)
    for y in range(field.h):
        for x in range(field.w):
            if not field.inside(x, y):
                continue
            gx = field.gx0 + x
            v, ny, lit = shade(field, x, y)
            v = (v - 0.5) * contrast + 0.5
            v = v * gain + lift
            for (wx, w0) in wet:
                if y > w0:
                    spread = 1.0 + (y - w0) / 60.0
                    d = abs(gx - wx)
                    if d < spread + 1:
                        v -= 0.10 * (1 - d / (spread + 1))
            q = v * (n - 1) + (bay(gx, y) - 0.5) * dither
            k = max(0, min(n - 1, int(round(q))))
            c = ramp[k]
            if cold_rows and y < cold_rows:
                # the slit's cold light: the face's top in the castle's cool slate; its lower edge wanders (with the
                # light that reaches down the lit buttresses) and dithers over a few rows into the granite
                line = cold_rows * (0.35 + 0.65 * vnoise(seed * 71, gx / 23.0)) + 24 * max(0.0, v - 0.45)
                if y < line - 12 or (y < line + 12 and bay(gx + 2, y + 1) < (line + 12 - y) / 24.0):
                    c = cold[k]
            if snow_rows and y < snow_rows and ny < -0.32:
                share = (snow_rows - y) / float(snow_rows)
                if vnoise2(seed * 61, gx / 5.0, y / 3.0) < snow_share * share + 0.15 * (-ny):
                    c = snow[2] if (lit and v > 0.62) else snow[1] if v > 0.4 else snow[0]
            if rim and not field.inside(x, y - 1) and h01(seed, gx) < rim:
                c = snow[1] if snow_rows and y < snow_rows else ramp[min(n - 1, k + 2)]
            if mist_left and gx < mist_left[1]:
                # the west end pales into the mist band: a boundary that leans with the slope (never a column),
                # wandering, dithered over its width
                t = (mist_left[1] - gx) / float(mist_left[1] - mist_left[0]) + 0.5 * (y / float(field.h) - 0.6) \
                    + 0.25 * (vnoise(seed * 83, y / 9.0) - 0.5)
                if t > 0.75 or (t > 0.3 and bay(gx, y) < (t - 0.3) * 2.2):
                    c = mist if v > 0.45 else mist_dark
            img.set(x, y, c)
    return img


def thread(img, gx0, seed, gx, y0, y1, spray):
    """A thin thread of water falling from a ledge: one pixel wide, foam and pale mist in short runs (it reads as
    falling), a step aside here and there, spray where it lands on a ledge."""
    foam, mist, light = col("foam"), col("mist"), col("mistLight")
    x = gx - gx0
    y = y0
    while y < y1:
        if 0 <= x < img.w and img.get(x, y)[3]:
            r = h01(seed, gx, y // 3, 39)
            gap = h01(seed, gx, y // 9, 45) < 0.12
            if r > 0.12 and not gap:
                img.set(x, y, light if r > 0.62 else foam if r > 0.35 else mist)
            if r > 0.8 and 0 <= x + 1 < img.w and img.get(x + 1, y)[3]:
                img.set(x + 1, y, mist)
        y += 1
        if h01(seed, gx, y, 41) < 0.018:
            x += 1 if h01(seed, gx, y, 43) < 0.5 else -1
    x = gx - gx0
    for (sy, r) in spray:
        for dy in range(-1, int(r * 1.8)):
            half = int(1 + r * (0.4 + 0.6 * max(0, dy) / (r * 1.8)))
            for dx in range(-half, half + 1):
                xx, yy = x + dx, sy + dy
                if not (0 <= xx < img.w and 0 <= yy < img.h) or not img.get(xx, yy)[3]:
                    continue
                d = (abs(dx) / float(half + 1)) + max(0, dy) / (r * 2.0)
                if bay(xx + gx0, yy) > 0.25 + 0.75 * d:
                    img.set(xx, yy, mist if d > 0.45 else light)
