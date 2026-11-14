#!/usr/bin/env python3
"""Lanternhold world rebuild, step world-1: granite as a height field (docs/REVIEW-look-2.md H1, H2, B6). Pure python,
palette colours only, no randomness (hashes of the position), so a run reproduces its files byte for byte.

A rock face is a height field z(x, y): how far each pixel stands out toward the viewer. A `Massif` builds it from
buttresses (columns of rock whose boundaries wander down the face, each its own depth, with a lit west bevel, a broad
front and a shaded east bevel), the chimneys between them, ledges (the block below steps out: a lit top) and overhangs
(the block above steps out: a shadow under it), joints (thin V grooves), exfoliation sheets (long diagonal steps),
a slow swell and a middle grain. `shade` lights the field from the upper left and from the sky above (the cleft's slit):
Lambert on the field's normal, cast shadows marched toward the light, a cavity term, and less light deeper down. The
painter maps the light onto a ramp of palette colours in clean clusters (no dither, no lone pixels: Louis' art bar),
and adds the slit's cold light on the lit faces, snow on the faces that look up, a cold rim on the edges that meet
the sky, wet streaks and threads of water with solid puffs of spray.

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
    # fix round 1: the old walls' footings, the cleft's granite with the shade in cool greys (the director)
    "footing": ["nightDeep", "stoneDark", "rockDark", "rock", "rockLight", "rockPale"],
}
COLD = {"cleft": ["nightBlue", "stoneDark", "stoneMid", "stone", "stoneLight", "mistLight"],
        "gate": ["nightDeep", "stoneDark", "stoneMid", "stone", "stoneLight", "mistLight"]}
SNOW = {"cleft": ("stoneLight", "mistLight", "foam"), "slate": ("mist", "mistLight", "foam"),
        "far": ("mist", "farPale", "mistLight"), "gate": ("stoneLight", "mistLight", "foam"),
        "footing": ("stoneLight", "mistLight", "foam")}


class Massif:
    """The height field of a granite face over the plane's x (gx) and rows (y, 0 at the canvas top)."""

    def __init__(self, seed, x0, x1, h, wmin, wmax, relief=1.0, ledge_gap=(18, 52), sheets=True, bands=(),
                 facets=0.0, chimneys=None, sheet_amp=1.4, swell=10.0):
        self.seed, self.h, self.relief = seed, h, relief
        self.ledge_gap = ledge_gap
        self.sheets = sheets
        # Fix round 1 (the critic: "flat pale dashes for ledges", "vertical columns that read as tree trunks"):
        # bands are long ledges across many buttresses, (row, tilt, shelf, undercut, gap seed): the shelf stands out
        # over three rows (a lit top plane), the face under it is set back (a dark undershadow that casts down);
        # facets tilt each block (a buttress between two bands) a little, so the face reads as planes of rock;
        # chimneys (a share) makes only some boundaries deep clefts and the rest shallow joints; sheet_amp is the
        # height of the diagonal fracture planes, swell the slow bulge of the whole face.
        self.bands = list(bands)
        self.facets = facets
        self.chimneys = chimneys
        self.sheet_amp = sheet_amp
        self.swell = swell
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
            # a ledge runs over a quarter to two thirds of its buttress, nearly level (long tilted ledges read as
            # scratches across the face)
            s0 = -0.05 + 0.5 * h01(self.seed, j, k, 13)
            s1 = min(1.05, s0 + 0.25 + 0.4 * h01(self.seed, j, k, 14))
            out.append((y, (h01(self.seed, j, k, 15) - 0.5) * 0.14, s0, s1, step))
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

    def band_row(self, by, tilt, gs, gx, j):
        """The row of a long ledge at gx on buttress j: a slight tilt, a slow wander, a step at every buttress."""
        return by + tilt * (gx - 1000) + 2.5 * (vnoise(self.seed * 59 + gs, gx / 23.0) - 0.5) \
            + 9.0 * (h01(self.seed, j, gs, 63) - 0.5)

    def facet(self, gx, y):
        """Chiselled planes (fix round 1): the face is split into slabs around jittered seeds (much taller than wide,
        as granite breaks), each a plane of its own that turns toward the light or away from it (two families, like
        the faces of a crystal), so the light falls on it in broad flat planes with crisp edges where two meet; the
        steps between slabs are shallow, so only the buttresses' chimneys read as deep clefts."""
        cw, ch = 36.0, 74.0
        ci, cj = int(gx // cw), int(y // ch)
        best, bd = None, 1e9
        for a in (ci - 1, ci, ci + 1):
            for b in (cj - 1, cj, cj + 1):
                sx = (a + 0.1 + 0.8 * h01(self.seed, a, b, 81)) * cw
                sy = (b + 0.1 + 0.8 * h01(self.seed, a, b, 82)) * ch
                # the slabs lean: their borders run down at a slant of their own
                dd = ((gx - sx + 0.3 * (y - sy)) / cw) ** 2 + ((y - sy) / ch) ** 2
                if dd < bd:
                    best, bd = (a, b, sx, sy), dd
        a, b, sx, sy = best
        t = self.facets
        lit = h01(self.seed, a, b, 83) < 0.6
        tx = (0.45 + 0.55 * h01(self.seed, a, b, 84)) * t * (1 if lit else -1)
        ty = (h01(self.seed, a, b, 86) - 0.6) * 0.35 * t
        return (h01(self.seed, a, b, 85) - 0.5) * 1.6 * self.relief + tx * (gx - sx) + ty * (y - sy)

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
        deep = 1.0
        if self.chimneys is not None:
            # only some boundaries are deep chimneys; the rest are shallow joints
            near_b = j if px < width - px else j + 1
            deep = 1.7 if h01(self.seed, near_b, 61) < self.chimneys else 0.3
        z -= (8.0 * r * deep) * math.exp(-dw / (2.0 + 1.5 * (deep > 1)))
        if self.bands or self.facets:
            k = 0
            for (by, tilt, shelf, under, gs) in self.bands:
                # each buttress carries the ledge a little higher or lower (it steps at the chimneys)
                row = self.band_row(by, tilt, gs, gx, j)
                if y >= row:
                    k += 1
                # a band breaks here and there (its gaps a buttress wide at most)
                if h01(self.seed, gs, int((gx + 37 * gs) // 57)) < 0.45:
                    continue
                z += shelf * r * ss((y - row) / 2.4 + 0.5)
                z -= under * r * ss((y - row - 3.5) / 1.0 + 0.5)
            if self.facets:
                z += self.facet(gx, y)
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
                z += self.sheet_amp * r * ss((f - 0.12) / 0.06) * (1 - ss((f - 0.88) / 0.06)) \
                    * vnoise(self.seed * 53 + k, y / 40.0)
        z += self.swell * r * (vnoise2(self.seed * 13, gx / 60.0, y / 90.0) - 0.5)
        z += 1.6 * r * (vnoise2(self.seed * 23, gx / 12.0, y / 20.0) - 0.5)
        return z


class Field:
    """The heights of a massif over a canvas (gx0 ... gx0 + w, rows 0 ... h) with `margin` columns of context on each
    side (the cast shadows come from the west); rows above `top(gx)` are open sky (no rock)."""

    def __init__(self, massif, gx0, w, h, top, margin=48):
        self.gx0, self.w, self.h, self.m = gx0, w, h, margin
        self.top = {gx: top(gx) for gx in range(gx0 - margin, gx0 + w + margin)}
        self.z = []
        self.cols = []
        for y in range(h):
            row = []
            cols = []
            for x in range(-margin, w + margin):
                gx = gx0 + x
                row.append(massif.z(gx, y) if y >= self.top[gx] else None)
                cols.append(massif.column(gx, y)[0])
            self.z.append(row)
            self.cols.append(cols)

    def column(self, x, y):
        """The buttress a canvas pixel belongs to."""
        y = max(0, min(self.h - 1, y))
        x = max(-self.m, min(self.w + self.m - 1, x))
        return self.cols[y][x + self.m]

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


def shade(field, x, y, light=LIGHT, sky_fall=0.5, ambient=0.14, clamp=0.0):
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
    if clamp:
        # fix round 1: a step between two slabs turns the edge a little, never to a hard line of white or black
        nx, ny = max(-clamp, min(clamp, nx)), max(-clamp, min(clamp, ny))
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
    j = field.column(x, y)
    t = min(1.0, max(0.0, (y + 26 * (h01(911, j) - 0.5)) / float(field.h)))
    sky = (1.0 - sky_fall * t ** 1.2) * (1.0 + 0.25 * max(0.0, -ny))
    v = (ambient * ao + 0.92 * diff * lit * (0.85 + 0.15 * ao)) * sky
    return v, ny, lit


def paint(field, ramp_name, gain=1.0, lift=0.0, dither=0.0, snow_rows=0, snow_share=0.6, rim=0.55, mist_left=None,
          wet=(), seed=1, contrast=1.0, cold_rows=0, caps=False, lit_rim=False, clamp=0.0):
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
            v, ny, lit = shade(field, x, y, clamp=clamp)
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
            if clamp:
                # fix round 1: the lightest step is kept for the snow and the rim; a lit edge is one step over its face
                k = min(k, n - 2)
            c = ramp[k]
            if cold_rows and y < cold_rows:
                # the slit's cold light: the face's top in the castle's cool slate; its lower edge is a clean line of
                # its own on every buttress (it steps at the chimneys) that reaches further down the lit faces
                j = field.column(x, y)
                line = cold_rows * (0.35 + 0.55 * h01(seed * 71, j)) + 10 * (vnoise(seed * 73 + j, gx / 9.0) - 0.5) \
                    + 22 * max(0.0, v - 0.5)
                if y < line and k >= 3:
                    c = cold[k]   # only the lit faces catch it; the shade stays the granite's
            if snow_rows and y < snow_rows and ny < -0.42 and not caps:
                # snow lies in patches on the ledges that look up, more of it higher up
                share = (snow_rows - y) / float(snow_rows)
                if vnoise2(seed * 61, gx / 9.0, y / 4.0) < snow_share * share * 0.85 + 0.1 * (-ny) - 0.08:
                    c = snow[2] if (lit and v > 0.62) else snow[1] if v > 0.4 else snow[0]
            if snow_rows and caps and y < snow_rows and ny < -0.3:
                # fix round 1: snow caps on the shelves and in the cracks' floors (cleaned to clusters of 6 px or
                # more below), more of them higher up
                share = (snow_rows - y) / float(snow_rows)
                if vnoise(seed * 61 + int(y), gx / 13.0) < snow_share * share + 0.25 * (-ny - 0.3):
                    c = snow[2] if (lit and v > 0.55) else snow[1] if v > 0.35 else snow[0]
            edge_top = not field.inside(x, y - 1)
            if lit_rim:
                # fix round 1 (the critic: "single white rim dots"): a continuous lit edge on the faces that look up
                # or west (toward the light), none on the shaded east slopes; two pixels where the edge is steep
                west_open = not field.inside(x - 1, y)
                rising = field.inside(x + 1, y - 1) or not field.inside(x + 1, y)
                if (edge_top and (rising or west_open)) or (west_open and field.inside(x, y - 1) and
                                                             not field.inside(x - 1, y - 1)):
                    c = snow[1] if snow_rows and y < snow_rows else ramp[min(n - 1, max(k, n - 3) + 2)]
            elif rim and edge_top and h01(seed, gx) < rim:
                c = snow[1] if snow_rows and y < snow_rows else ramp[min(n - 1, k + 2)]
            if mist_left and gx < mist_left[1]:
                # the west end pales into the mist band: a boundary that leans with the slope (never a column),
                # wandering, dithered over its width
                t = (mist_left[1] - gx) / float(mist_left[1] - mist_left[0]) + 0.5 * (y / float(field.h) - 0.6) \
                    + 0.25 * (vnoise(seed * 83, y / 9.0) - 0.5)
                if t > 0.75 or (t > 0.3 and bay(gx, y) < (t - 0.3) * 2.2):
                    c = mist if v > 0.45 else mist_dark
            img.set(x, y, c)
    declump(img)
    if caps:
        clean_snow(img, snow, ramp)
    return img


def clean_snow(img, snow, ramp, least=6):
    """Snow in clusters of at least `least` pixels (the director: no patch under about 6 px): a smaller patch takes the
    rock's colour below it."""
    w, h = img.w, img.h
    flakes = set(snow)
    seen = [[False] * w for _ in range(h)]
    for y in range(h):
        for x in range(w):
            if seen[y][x] or img.get(x, y) not in flakes:
                continue
            stack, cells = [(x, y)], []
            seen[y][x] = True
            while stack:
                cx, cy = stack.pop()
                cells.append((cx, cy))
                for (nx, ny) in ((cx - 1, cy), (cx + 1, cy), (cx, cy - 1), (cx, cy + 1)):
                    if 0 <= nx < w and 0 <= ny < h and not seen[ny][nx] and img.get(nx, ny) in flakes:
                        seen[ny][nx] = True
                        stack.append((nx, ny))
            if len(cells) >= least:
                continue
            for (cx, cy) in cells:
                below = next((img.get(cx, yy) for yy in range(cy + 1, min(h, cy + 6)) if img.get(cx, yy) not in flakes
                              and img.get(cx, yy)[3]), ramp[len(ramp) - 2])
                img.set(cx, cy, below)


def declump(img, passes=2):
    """No lone pixels: an opaque pixel that no 4-neighbour shares the colour of takes its neighbours' most common
    colour (a pixel artist's clean clusters)."""
    w, h = img.w, img.h
    for _ in range(passes):
        changes = []
        for y in range(h):
            for x in range(w):
                p = img.get(x, y)
                if not p[3]:
                    continue
                around = [img.get(xx, yy) for (xx, yy) in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1))
                          if 0 <= xx < w and 0 <= yy < h]
                opaque = [q for q in around if q[3]]
                if len(opaque) < 3 or any(q == p for q in opaque):
                    continue
                best = max(set(opaque), key=opaque.count)
                if opaque.count(best) >= 2:
                    changes.append((x, y, best))
        for (x, y, c) in changes:
            img.set(x, y, c)


def thread(img, gx0, seed, gx, y0, y1, spray):
    """A thread of water's bed on the rock (fix round 1; the falling water itself is `cleftWater`, the engine's
    animated overlay): the crack it springs from (a dark notch with a lit lip), a wet streak two pixels wide that runs
    down the face and darkens it, and the spray where it lands on a ledge: a pale puff in solid clusters with a mist
    rim. The streak's column is the overlay's, so the water sits on its own wet rock."""
    foam, mist, light = col("foam"), col("mist"), col("mistLight")
    deep, dark = col("rockDeep"), col("nightBlue")
    x = gx - gx0
    # the crack: three rows of dark with a lit lip above it
    for dy in range(-3, 1):
        for dx in (-1, 0, 1, 2):
            xx, yy = x + dx, y0 + dy
            if 0 <= xx < img.w and 0 <= yy < img.h and img.get(xx, yy)[3]:
                img.set(xx, yy, dark if dy > -3 else col("rockLight"))
    # the wet streak: two columns, the rock under the water darkened
    for y in range(y0 + 1, y1):
        for dx in (-1, 0, 1):
            xx = x + dx
            if 0 <= xx < img.w and 0 <= y < img.h and img.get(xx, y)[3]:
                img.set(xx, y, deep if dx != -1 else dark)
    for (sy, r) in spray:
        # a puff where the water lands: a pale core and a mist rim, solid clusters (no dither)
        for dy in range(0, int(r * 1.5) + 1):
            half = int(round(0.6 + r * 0.6 * (1 - abs(dy - r * 0.6) / (r * 0.9 + 1))))
            for dx in range(-half, half + 1):
                xx, yy = x + dx, sy + dy
                if not (0 <= xx < img.w and 0 <= yy < img.h) or not img.get(xx, yy)[3]:
                    continue
                edge = abs(dx) == half or dy == int(r * 1.5)
                if edge and h01(seed, gx, sy, dx, dy) < 0.35:
                    continue
                img.set(xx, yy, mist if edge else foam if abs(dx) < half - 1 and dy < r else light)
