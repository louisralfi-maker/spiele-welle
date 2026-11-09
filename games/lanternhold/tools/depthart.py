#!/usr/bin/env python3
"""Lanternhold look 2, stage 1: the depth stand-ins for the look mocks (ART-look2.md "Depth per region"). Not game art:
simple, seeded, procedural trees, bushes, foreground plants, lane ground tiles and a few particle sprites, painted from
the shared palette with the light from the upper left, so the mocks show rows of trees, a lane under the feet and dark
plants in front before stage 2 paints the real world. Adapted from the lead's depth prototype (depth_art.py, 09.11.).

Usage (pure python, about ten seconds for the whole set; run with python3 -I -B):
    python3 -I -B depthart.py <out dir> [--palette tools/palette.txt] [name ...]
Writes <out dir>/<name>.png, 8-bit RGBA, binary alpha except the trees' contact shadows, the smoke and the particle
sprites. Every colour comes from the palette by name, so a palette change repaints the set. Names: SET at the bottom.
"""
import argparse
import math
import os
import random
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from pixelart import Image, Palette, write_png, DEFAULT_PALETTE  # noqa: E402

BAYER = [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]
Lx, Ly, Lz = -0.62, -0.70, 0.36  # light from the upper left, a little toward the viewer
_n = math.sqrt(Lx * Lx + Ly * Ly + Lz * Lz)
Lx, Ly, Lz = Lx / _n, Ly / _n, Lz / _n
PAL = None


def bay(x, y):
    return (BAYER[((y & 3) << 2) | (x & 3)] + 0.5) / 16


def C(name):
    return PAL.color(name)


class Img:
    def __init__(s, w, h):
        s.w, s.h = w, h
        s.px = [[None] * w for _ in range(h)]

    def put(s, x, y, c, a=255):
        if c is None:
            return
        x, y = int(x), int(y)
        if 0 <= x < s.w and 0 <= y < s.h:
            s.px[y][x] = (c[0], c[1], c[2], a)

    def get(s, x, y):
        x, y = int(x), int(y)
        return s.px[y][x] if 0 <= x < s.w and 0 <= y < s.h else None

    def save(s, out, name):
        img = Image(s.w, s.h)
        for y in range(s.h):
            for x in range(s.w):
                p = s.px[y][x]
                if p:
                    img.set(x, y, p)
        write_png(os.path.join(out, name + ".png"), img)


# ------------------------------------------------------------------------------------------------ shading helpers

def clumps(seed, cell, period=None):
    """Leaf clumps: jittered cells, each a small dome with its own lit upper left."""
    cache = {}

    def center(i, j):
        ii = i % period if period else i
        k = (ii, j)
        if k not in cache:
            r = random.Random((seed * 1000003 + ii * 7919 + j * 104729) & 0xFFFFFFFF)
            cache[k] = (r.uniform(0.15, 0.85) * cell, r.uniform(0.15, 0.85) * cell, r.uniform(0.8, 1.2))
        ox, oy, sz = cache[k]
        return i * cell + ox, j * cell + oy, sz

    def near(x, y):
        i, j = int(x // cell), int(y // cell)
        best = None
        for a in (-1, 0, 1):
            for b in (-1, 0, 1):
                cx, cy, sz = center(i + a, j + b)
                rad = cell * 0.62 * sz
                dx, dy = (x - cx) / rad, (y - cy) / rad
                d = math.hypot(dx, dy)
                if best is None or d < best[0]:
                    best = (d, dx, dy)
        return best
    return near


def crown(img, blobs, ramp, seed, cell=4.0, bump=1.3, low=0.30, holes=(), outline=None, bias=0.0, gain=0.5,
          local=0.30):
    """A union of shaded spheres (cx, cy, r, z offset) with leaf clumps, a dithered ramp, an optional dark outline on
    the shadow side."""
    near = clumps(seed, cell)
    top = min(b[1] - b[2] for b in blobs)
    bot = max(b[1] + b[2] for b in blobs)
    x0 = int(min(b[0] - b[2] for b in blobs)) - 3
    x1 = int(max(b[0] + b[2] for b in blobs)) + 4
    vals = {}
    for y in range(max(0, int(top) - 3), min(img.h, int(bot) + 4)):
        for x in range(max(0, x0), min(img.w, x1)):
            px, py = x + 0.5, y + 0.5
            d, cdx, cdy = near(px, py)
            dome = max(0.0, 1 - d * d)
            best = None
            for (bx, by, r, zo) in blobs:
                dx, dy = px - bx, py - by
                dd = math.hypot(dx, dy)
                if dd <= r + bump * (dome * 2 - 1):
                    q = min(dd, r) / r
                    z = r * math.sqrt(max(0.0, 1 - q * q)) + zo
                    if best is None or z > best[0]:
                        best = (z, dx / r, dy / r, math.sqrt(max(0.0, 1 - q * q)))
            if best is None:
                continue
            if any(math.hypot(px - hx_, py - hy_) < hr for (hx_, hy_, hr) in holes):
                continue
            _, nx, ny, nz = best
            g = nx * Lx + ny * Ly + nz * Lz
            lz = math.sqrt(max(0.0, 1 - min(1.0, cdx * cdx + cdy * cdy)))
            lo = cdx * Lx + cdy * Ly + lz * Lz
            v = 0.40 + gain * g + local * (lo - 0.3) + bias
            t = (py - top) / max(1.0, bot - top)
            v -= low * max(0.0, t - 0.45) * 1.8
            vals[(x, y)] = v
    for (x, y), v in vals.items():
        edge = any((x + a, y + b) not in vals for a, b in ((1, 0), (0, 1), (-1, 0), (0, -1)))
        q = v + (bay(x, y) - 0.5) * 0.20
        k = min(len(ramp) - 1, max(0, int(q * len(ramp))))
        img.put(x, y, outline if (edge and outline and v < 0.42) else ramp[k])
    return vals


def trunk(img, cx, yb, yt, wb, wt, seed, cols, flare=2.0, marks=None):
    r = random.Random(seed)
    for y in range(yt, yb + 1):
        t = (y - yt) / max(1, yb - yt)
        w = wt + (wb - wt) * t
        if y > yb - 3:
            w += flare * (y - (yb - 3)) / 3
        left = cx - w / 2
        for x in range(int(math.floor(left)), int(math.ceil(left + w))):
            u = (x + 0.5 - left) / max(0.5, w)
            if u < 0 or u > 1:
                continue
            c = cols[0] if u < 0.25 else cols[1] if u < 0.55 else cols[2] if u < 0.86 else cols[3]
            if marks and r.random() < marks[0] and 0.2 < u < 0.85:
                c = marks[1]
            img.put(x, y, c)


def line(img, x0, y0, x1, y1, w0, w1, col):
    n = int(max(abs(x1 - x0), abs(y1 - y0))) + 1
    for i in range(n + 1):
        t = i / n
        x = x0 + (x1 - x0) * t
        y = y0 + (y1 - y0) * t
        w = w0 + (w1 - w0) * t
        for a in range(-int(w // 2), int((w + 1) // 2)):
            img.put(int(round(x + a)), int(round(y)), col)


def foot_shadow(img, cx, y, rx):
    """A soft contact shadow (black with alpha) under a tree."""
    for x in range(int(cx - rx), int(cx + rx) + 1):
        q = abs(x + 0.5 - cx) / rx
        if q < 1 and img.get(x, y) is None:
            img.put(x, y, (0, 0, 0), int(110 * (1 - q * q)))


# ------------------------------------------------------------------------------------------------ deciduous (valley)

def leaves():
    return [C("leafDark"), C("leaf"), C("meadow"), C("leafLight")]


def linden(out, name, seed, w=84, h=98):
    img = Img(w, h)
    cx = w // 2
    foot = h - 2
    trunk(img, cx, foot, 52, 8, 5, seed, (C("woodLight"), C("wood"), C("woodDark"), C("ink")), marks=(0.10, C("woodDark")))
    for (x1, y1, a, b) in ((cx - 15, 40, 4, 2), (cx + 14, 38, 4, 2), (cx - 4, 26, 3, 1), (cx + 6, 30, 3, 1),
                           (cx - 22, 48, 3, 1), (cx + 21, 47, 3, 1)):
        line(img, cx, 58, x1, y1, a, b, C("woodDark"))
    blobs = [(cx, 38, 24, 0), (cx - 16, 41, 15, -2), (cx + 16, 41, 15, -2), (cx - 10, 24, 16, 1), (cx + 10, 24, 16, 1),
             (cx, 13, 13, 2), (cx - 26, 49, 10, -5), (cx + 26, 49, 10, -5), (cx, 52, 14, -7), (cx - 20, 30, 11, -1),
             (cx + 21, 30, 11, -1)]
    holes = [(cx - 12, 55, 3.6), (cx + 11, 53, 3.2), (cx + 2, 59, 2.6)]
    crown(img, blobs, leaves(), seed, cell=4.2, holes=holes, outline=C("leafDark"), low=0.5, gain=0.62, bias=-0.06)
    foot_shadow(img, cx, foot + 1, 20)
    img.save(out, name)


def poplar(out, name, seed, w=24, h=92):
    img = Img(w, h)
    cx = w // 2
    foot = h - 2
    trunk(img, cx, foot, h - 22, 4, 3, seed, (C("wood"), C("woodDark"), C("woodDark"), C("ink")), flare=1.0)
    r = random.Random(seed)
    blobs = []
    n = int((h - 22) / 4.6)
    for k in range(n):
        y = 6 + k * 4.6
        t = (y - 4) / (h - 22)
        rad = 2.5 + 7.5 * math.sin(min(1.0, t * 1.15) * math.pi * 0.62) if t < 0.86 else 6.0
        blobs.append((cx + r.uniform(-1.2, 1.2), y, rad, r.uniform(-1, 1)))
    blobs.append((cx, 3.5, 2.4, 1))
    crown(img, blobs, leaves(), seed, cell=3.4, bump=1.0, low=0.22, outline=C("leafDark"), bias=-0.08)
    foot_shadow(img, cx, foot + 1, 8)
    img.save(out, name)


def orchard(out, name, seed, w=40, h=40):
    """A small apple tree: a round crown low on a short trunk, a few fruit."""
    img = Img(w, h)
    cx = w // 2
    foot = h - 2
    trunk(img, cx, foot, 22, 4, 3, seed, (C("woodLight"), C("wood"), C("woodDark"), C("ink")), flare=1.5)
    line(img, cx, 25, cx - 7, 18, 2, 1, C("woodDark"))
    line(img, cx, 25, cx + 8, 17, 2, 1, C("woodDark"))
    blobs = [(cx, 14, 11, 0), (cx - 9, 17, 7, -1), (cx + 9, 17, 7, -1), (cx - 4, 8, 7, 1), (cx + 5, 9, 7, 1)]
    crown(img, blobs, leaves(), seed, cell=3.6, low=0.4, outline=C("leafDark"), gain=0.6, bias=-0.04)
    r = random.Random(seed + 5)
    for _ in range(6):
        x, y = cx + r.randint(-10, 10), r.randint(8, 22)
        if img.get(x, y):
            img.put(x, y, C("tile"))
    foot_shadow(img, cx, foot + 1, 9)
    img.save(out, name)


def willow(out, name, seed, w=70, h=74):
    """A willow by the river: a broad crown whose long strands hang down toward the bank."""
    img = Img(w, h)
    cx = w // 2
    foot = h - 2
    trunk(img, cx, foot, 30, 7, 4, seed, (C("woodLight"), C("wood"), C("woodDark"), C("ink")), flare=2.5,
          marks=(0.12, C("woodDark")))
    blobs = [(cx, 22, 18, 0), (cx - 14, 26, 12, -1), (cx + 14, 26, 12, -1), (cx - 6, 12, 11, 1), (cx + 7, 13, 11, 1)]
    crown(img, blobs, leaves(), seed, cell=3.4, low=0.35, outline=None, gain=0.5, bias=-0.02)
    r = random.Random(seed)
    for k in range(34):  # hanging strands
        x0 = cx + r.uniform(-26, 26)
        y0 = 18 + abs(x0 - cx) * 0.3 + r.uniform(0, 6)
        ln = r.uniform(14, 30)
        for i in range(int(ln)):
            t = i / ln
            x = x0 + math.sin(t * 2.2 + k) * 0.8
            y = y0 + i
            if y >= foot - 4:
                break
            col = C("leaf") if (k + i // 3) % 3 else C("meadow")
            if t > 0.7:
                col = C("leafDark")
            img.put(x, y, col)
    foot_shadow(img, cx, foot + 1, 16)
    img.save(out, name)


def bush(out, name, seed, w, h, blobs):
    img = Img(w, h)
    crown(img, blobs, leaves(), seed, cell=3.6, bump=1.1, low=0.25, outline=C("leafDark"), bias=-0.02)
    for x in range(w):  # a flat foot on the ground line
        if img.px[h - 2][x] and not img.px[h - 1][x]:
            img.put(x, h - 1, C("leafDark"))
    img.save(out, name)


def tree_belt(out, name, seed, w=520, h=58):
    """A mid-plane line of trees and hedges: round crowns, a few poplars, a hedge along the foot."""
    img = Img(w, h)
    r = random.Random(seed)
    blobs = []
    x = 4.0
    while x < w - 4:
        kind = r.random()
        if kind < 0.16:  # poplar
            hgt = r.uniform(30, 46)
            for k in range(16):
                t = k / 15
                y = h - 8 - t * hgt
                rad = 1.6 + 4.2 * math.sin(min(1.0, (1 - t) * 1.1) * math.pi * 0.6)
                blobs.append((x + r.uniform(-0.5, 0.5), y, rad, 0))
            x += r.uniform(9, 14)
        elif kind < 0.75:  # round tree
            rad = r.uniform(7, 13)
            cy = h - 6 - rad - r.uniform(2, 12)
            blobs += [(x, cy, rad, 0), (x - rad * 0.6, cy + rad * 0.35, rad * 0.65, -1),
                      (x + rad * 0.6, cy + rad * 0.3, rad * 0.62, -1)]
            if r.random() < 0.6:
                trunk(img, int(x), h - 4, int(cy + rad * 0.6), 2, 2, r.randrange(1 << 20),
                      (C("wood"), C("woodDark"), C("woodDark"), C("ink")), flare=0)
            x += rad * r.uniform(1.1, 1.8)
        else:  # a gap with the low hedge only
            x += r.uniform(10, 26)
    for k in range(int(w / 3.5) + 2):  # the hedge along the foot
        blobs.append((k * 3.5 + r.uniform(-1, 1), h - 5 - r.uniform(0, 1.5), r.uniform(4.0, 5.5), -2))
    crown(img, blobs, leaves(), seed, cell=3.8, bump=0.9, low=0.35, bias=-0.06, gain=0.45, local=0.22)
    img.save(out, name)


# ------------------------------------------------------------------------------------------------ the shadow land

def firs():
    return [C("fir0"), C("fir1"), C("fir2"), C("fir3")]


def fir(out, name, seed, h=96, w=None, tips=True):
    """A dark fir: stacked drooping tiers, lit on the upper left, the shadow side deep, a short trunk."""
    w = w or (int(h * 0.44) | 1)
    img = Img(w, h)
    r = random.Random(seed)
    cx = w / 2
    foot = h - 2
    trunk(img, int(cx), foot, foot - int(h * 0.12), 4, 3, seed, (C("wood"), C("woodDark"), C("woodDark"), C("ink")),
          flare=1.0)
    ramp = firs()
    top = 1
    base = foot - int(h * 0.09)
    tiers = max(6, int(h / 10))
    vals = {}
    for k in range(tiers):
        t0 = k / tiers
        t1 = (k + 1.35) / tiers
        y0 = top + (base - top) * t0
        y1 = top + (base - top) * min(1.0, t1)
        half_top = 0.6 + (w * 0.5 - 1) * t0 * 0.8
        half_bot = 1.5 + (w * 0.5 - 1.5) * min(1.0, t1) * 0.98
        jag = r.uniform(-1.2, 1.2)
        for y in range(int(y0), int(y1) + 1):
            u = min(1.0, max(0.0, (y - y0) / max(1.0, y1 - y0)))
            half = half_top + (half_bot - half_top) * (u ** 0.75)
            for x in range(int(cx - half) - 1, int(cx + half) + 2):
                dx = (x + 0.5 - cx - jag * u) / max(1.0, half)
                if abs(dx) > 1:
                    continue
                sag = 2.4 * dx * dx + r.uniform(0, 1.4)  # the tier's lower edge droops toward the tips, ragged
                if u > 1 - sag / max(4.0, (y1 - y0)) and abs(dx) > 0.3:
                    continue
                lit = -dx * 0.6 + (1 - u) * 0.35 + 0.10 * math.sin(x * 1.7 + y * 0.9 + k)
                v = 0.26 + 0.45 * lit + (bay(x, y) - 0.5) * 0.22
                vals[(x, y)] = max(vals.get((x, y), -9), v)
    for (x, y), v in vals.items():
        img.put(x, y, ramp[min(len(ramp) - 1, max(0, int(v * len(ramp))))])
    if tips:  # a few needle tips catch the light on the lit side
        for (x, y), v in vals.items():
            if v > 0.72 and (x - 1, y) not in vals and r.random() < 0.6:
                img.put(x, y, C("fir4"))
    foot_shadow(img, cx, foot + 1, w * 0.36)
    img.save(out, name)


def dead_tree(out, name, seed, w=60, h=96):
    """A dead tree of the moor: a split grey trunk, crooked bare branches, no leaves."""
    img = Img(w, h)
    r = random.Random(seed)
    cx = w // 2
    foot = h - 2
    cols = (C("rockLight"), C("rock"), C("rockDark"), C("ink"))
    trunk(img, cx, foot, int(h * 0.42), 7, 4, seed, cols, flare=3.0, marks=(0.12, C("rockDeep")))

    def branch(x, y, ang, ln, wd, depth):
        if depth == 0 or ln < 3:
            return
        x1 = x + math.cos(ang) * ln
        y1 = y + math.sin(ang) * ln
        line(img, x, y, x1, y1, wd, max(1, wd - 1), C("rockDark") if wd > 1 else C("rockDeep"))
        if wd >= 2:
            line(img, x - 0.5, y, x1 - 0.5, y1, 1, 1, C("rock"))  # the lit upper-left edge
        for _ in range(2 if depth > 1 else 1):
            branch(x1, y1, ang + r.uniform(-0.75, 0.75), ln * r.uniform(0.55, 0.75), max(1, wd - 1), depth - 1)
    for a in (-2.3, -1.75, -1.2, -0.85):
        branch(cx, int(h * 0.44), a + r.uniform(-0.15, 0.15), r.uniform(16, 24), 3, 4)
    branch(cx, int(h * 0.6), -2.7, 12, 2, 3)
    branch(cx, int(h * 0.55), -0.4, 12, 2, 3)
    foot_shadow(img, cx, foot + 1, 10)
    img.save(out, name)


def fir_belt(out, name, seed, w=520, h=72, ramp_names=("fir0", "fir1", "fir2"), hmin=22):
    """The edge of a fir forest for the mid or far plane: firs of many heights close together, a dark undergrowth.
    Seamless horizontally."""
    img = Img(w, h)
    r = random.Random(seed)
    ramp = [C(n) for n in ramp_names]
    x = 2.0
    vals = {}
    while x < w + 6:
        hgt = r.uniform(h * 0.55, h - 2) if r.random() < 0.7 else r.uniform(hmin, h * 0.55)
        half = hgt * r.uniform(0.16, 0.21)
        topy = h - 3 - hgt
        ph = r.uniform(0, 6)
        for y in range(int(topy), h):
            u = (y - topy) / hgt
            hw = 0.6 + half * u
            hw *= 1 - 0.22 * (math.sin(u * hgt / 3.0 + ph) * 0.5 + 0.5) * (u > 0.1)  # the tiers' notches
            for xx in range(int(x - hw) - 1, int(x + hw) + 2):
                xw = xx % w
                dx = (xx + 0.5 - x) / max(0.6, hw)
                if abs(dx) > 1:
                    continue
                v = 0.34 - dx * 0.30 + (1 - u) * 0.16 + (bay(xw, y) - 0.5) * 0.2
                vals[(xw, y)] = max(vals.get((xw, y), -9), v)
        x += half * r.uniform(0.8, 1.5)
    for xx in range(w):
        for y in range(h - 6 - int(2 * math.sin(xx * 0.21) + 2), h):
            vals[(xx, y)] = min(vals.get((xx, y), 0.2), 0.18)
    for (x, y), v in vals.items():
        img.put(x, y, ramp[min(len(ramp) - 1, max(0, int(v * len(ramp))))])
    img.save(out, name)


def fg_ferns(out, name, seed, w=480, h=48):
    """The shadow land's foreground: fern fans, a fallen branch, dead grass and low mounds on a dark root band."""
    img = Img(w, h)
    r = random.Random(seed)
    dark = [C("nightDeep"), C("fir0"), C("fir1"), C("moorDark")]
    blobs = []
    x = r.uniform(4, 20)
    while x < w - 10:
        if r.random() < 0.5:
            rad = r.uniform(6, 13)
            blobs += [(x, h - rad * 0.5, rad, 0), (x - rad * 0.7, h - rad * 0.2, rad * 0.6, -2)]
            x += rad * r.uniform(2.0, 3.4)
        else:
            x += r.uniform(14, 30)
    for k in range(int(w / 4) + 1):  # the root band
        blobs.append((k * 4 + r.uniform(-1, 1), h + 1, r.uniform(4, 6), -4))
    crown(img, blobs, dark, seed, cell=4.4, bump=1.5, low=0.35, bias=-0.06, gain=0.5, local=0.35)
    for k in range(int(w / 26)):  # fern fans: arched fronds with leaflets
        x0 = r.uniform(6, w - 6)
        for f in range(r.randint(3, 6)):
            side = -1 if f % 2 == 0 else 1
            ang = -math.pi / 2 + side * r.uniform(0.25, 1.1)
            ln = r.uniform(12, 24)
            for i in range(int(ln)):
                t = i / ln
                xx = x0 + math.cos(ang) * i * (1 + 0.4 * t)
                yy = h - 3 + math.sin(ang) * i + 8 * t * t
                img.put(xx, yy, C("fir1") if t < 0.6 else C("fir2"))
                if i % 2 == 0 and 1 < i < ln - 1:
                    img.put(xx - side, yy + 1, C("fir0"))
                    img.put(xx + side, yy - 1 + (t > 0.5), C("fir1"))
    for k in range(int(w / 120)):  # a fallen branch
        x0 = r.uniform(10, w - 60)
        y0 = h - r.uniform(5, 10)
        line(img, x0, y0, x0 + r.uniform(30, 50), y0 - r.uniform(-4, 4), 2, 2, C("rockDeep"))
    for k in range(int(w / 9)):  # dead grass blades
        cxg = r.uniform(0, w)
        for j in range(r.randint(2, 5)):
            x0 = cxg + r.uniform(-3, 3)
            hgt = r.randint(5, 14)
            lean = r.uniform(-0.5, 0.5)
            for i in range(hgt):
                t = i / hgt
                img.put(x0 + lean * i + lean * 1.5 * t * t, h - 2 - i, C("moorDark") if t < 0.6 else C("moor"))
    img.save(out, name)


def fg_meadow(out, name, seed, w=480, h=44):
    """The valley's foreground: bush mounds, grass clumps and a few flowers on a dark root band."""
    img = Img(w, h)
    r = random.Random(seed)
    blobs = []
    x = r.uniform(4, 20)
    while x < w - 10:
        if r.random() < 0.45:
            rad = r.uniform(7, 15)
            blobs += [(x, h - rad * 0.55, rad, 0), (x - rad * 0.7, h - rad * 0.25, rad * 0.65, -2),
                      (x + rad * 0.75, h - rad * 0.3, rad * 0.6, -2)]
            x += rad * r.uniform(2.2, 3.6)
        else:
            x += r.uniform(14, 34)
    for k in range(int(w / 4) + 1):
        blobs.append((k * 4 + r.uniform(-1, 1), h + 1, r.uniform(4, 6), -4))
    crown(img, blobs, [C("nightBlue"), C("leafDark"), C("leaf"), C("meadow")], seed, cell=4.4, bump=1.5, low=0.35,
          bias=-0.04, gain=0.55, local=0.35)
    for k in range(int(w / 9)):
        cxg = r.uniform(0, w)
        for j in range(r.randint(3, 7)):
            x0 = cxg + r.uniform(-3, 3)
            hgt = r.randint(5, 15)
            lean = r.uniform(-0.45, 0.45)
            for i in range(hgt):
                t = i / hgt
                img.put(x0 + lean * i + lean * 1.5 * t * t, h - 2 - i,
                        C("leafDark") if t < 0.5 else C("leaf") if t < 0.85 else C("meadow"))
    for k in range(int(w / 45)):
        x0 = int(r.uniform(0, w))
        hgt = r.randint(8, 14)
        col = r.choice([C("tile"), C("gold"), C("parchment"), C("dusk")])
        for i in range(hgt):
            img.put(x0, h - 2 - i, C("leafDark"))
        for (a, b) in ((0, 0), (1, 0), (-1, 0), (0, -1)):
            img.put(x0 + a, h - 2 - hgt + b, col)
    img.save(out, name)


def fg_reeds(out, name, seed, w=160, h=50):
    """Reeds and cattails at the river bank."""
    img = Img(w, h)
    r = random.Random(seed)
    for k in range(int(w * 0.5)):
        x0 = r.uniform(0, w)
        hgt = r.randint(10, h - 4)
        lean = r.uniform(-0.25, 0.25)
        for i in range(hgt):
            t = i / hgt
            img.put(x0 + lean * i * t, h - 1 - i, C("leafDark") if t < 0.5 else C("leaf") if t < 0.9 else C("meadow"))
        if r.random() < 0.18:  # a cattail head
            xh = x0 + lean * hgt
            for j in range(4):
                img.put(xh, h - 1 - hgt - j, C("woodDark"))
                img.put(xh + 1, h - 1 - hgt - j, C("wood") if j < 2 else C("woodDark"))
    img.save(out, name)


# ------------------------------------------------------------------------------------------------ lane ground tiles

def lane(out, name, seed, kind, w=64, h=26):
    """A ground tile seen at a shallow angle (look 2: a lane under the feet instead of the soil cross-section). Row 0
    lies under the feet; rows 0-6 are the walked track, 7-9 its near edge, 10-25 the bank toward the viewer, darker
    downward (the foreground plants cover most of it). Seamless horizontally."""
    img = Img(w, h)
    r = random.Random(seed)
    near = clumps(seed, 3.0, period=w // 3)
    if kind == "moor":
        track = [C("soilDark"), C("soil"), C("moor")]
        edge = [C("moorDark"), C("moor")]
        bank = [C("nightDeep"), C("moorDark"), C("fir0"), C("fir1")]
        stone = C("rock")
    elif kind == "cobble":
        track = [C("stoneDark"), C("stoneMid"), C("stone")]
        edge = [C("stoneDark"), C("stoneLight")]
        bank = [C("nightDeep"), C("rockDeep"), C("soilDark"), C("rockDark")]
        stone = C("stoneLight")
    else:  # earth
        track = [C("soil"), C("soilLight"), C("straw")]
        edge = [C("leafDark"), C("leaf")]
        bank = [C("nightBlue"), C("leafDark"), C("leaf"), C("meadow")]
        stone = C("stonePale")
    for y in range(h):
        for x in range(w):
            d, cdx, cdy = near(x + 0.5, y + 0.5)
            lz = math.sqrt(max(0.0, 1 - min(1.0, cdx * cdx + cdy * cdy)))
            lo = cdx * Lx + cdy * Ly + lz * Lz
            if y < 7:
                if kind == "cobble":  # cobbles in a running bond seen low: rows of flat stones, dark joints
                    row = y // 2
                    sx = (x + (row % 2) * 3) % 6
                    joint = y % 2 == 1 or sx == 0
                    v = 0.55 + 0.25 * (lo - 0.3) - 0.03 * y + (bay(x, y) - 0.5) * 0.15
                    c = track[0] if joint else (track[2] if v > 0.6 else track[1])
                else:
                    v = 0.58 + 0.25 * (lo - 0.3) - 0.04 * y + (bay(x, y) - 0.5) * 0.2
                    c = track[2] if v > 0.66 else track[1] if v > 0.4 else track[0]
                    if y in (2, 5) and (x * 7 + 3 * seed) % 11 > 2:
                        c = track[0]  # two worn ruts
                    if r.random() < 0.02:
                        c = stone
            elif y < 10:
                c = edge[1] if (y == 7 and (x + seed) % 3) else edge[0]
            else:
                v = 0.6 + 0.3 * (lo - 0.3) - 0.62 * (y - 10) / (h - 10) + (bay(x, y) - 0.5) * 0.16
                c = bank[min(len(bank) - 1, max(0, int(v * len(bank))))]
            img.put(x, y, c)
    for k in range(10 if kind != "cobble" else 4):  # tufts on the near edge
        x0 = r.randrange(w)
        hh = r.randint(2, 4)
        for i in range(hh):
            img.put((x0 + (i // 2)) % w, 9 - i, edge[1] if i < hh - 1 else (C("moor") if kind == "moor" else C("meadow")))
    img.save(out, name)


# ------------------------------------------------------------------------------------------------ particles

def smoke(out, name, w=16, h=56):
    """A chimney's smoke column: white with alpha (the mock lights it like the fog)."""
    img = Img(w, h)
    for y in range(h):
        t = 1 - y / (h - 1)  # 0 at the chimney, 1 at the top
        cx = w / 2 + math.sin(t * 3.1) * 2.5 * t + t * 3
        rad = 1.2 + 5.5 * t
        for x in range(w):
            d = abs(x + 0.5 - cx) / rad
            if d >= 1:
                continue
            puff = 0.6 + 0.4 * math.sin(y * 0.7 + x * 0.3)
            a = (1 - d * d) * (1 - t) ** 0.6 * puff
            lvl = math.floor(a * 6 + bay(x, y) - 0.5) / 6
            if lvl > 0:
                img.put(x, y, (255, 255, 255), int(min(200, 200 * lvl)))
    img.save(out, name)


def dots(out, name, seed, w, h, n, cols):
    """Scattered emissive dots (fireflies in the valley at dusk, sparks over a brazier)."""
    img = Img(w, h)
    r = random.Random(seed)
    for _ in range(n):
        img.put(r.randrange(w), r.randrange(h), r.choice(cols))
    img.save(out, name)


# ------------------------------------------------------------------------------------------------ the set

def build(out, name):
    if name == "d2FirA": fir(out, name, 91, 118)
    elif name == "d2FirB": fir(out, name, 93, 96)
    elif name == "d2FirC": fir(out, name, 95, 72)
    elif name == "d2FirD": fir(out, name, 97, 132)
    elif name == "d2DeadTree": dead_tree(out, name, 99)
    elif name == "d2FirBelt": fir_belt(out, name, 101, 520, 74)
    elif name == "d2FirBeltB": fir_belt(out, name, 103, 520, 58)
    elif name == "d2FirBeltFar": fir_belt(out, name, 105, 520, 40, ("fir1", "fir2", "fir3"), hmin=12)
    elif name == "d2FgFerns": fg_ferns(out, name, 107)
    elif name == "d2Linden": linden(out, name, 11)
    elif name == "d2Poplar": poplar(out, name, 21)
    elif name == "d2PoplarB": poplar(out, name, 23, h=80)
    elif name == "d2Orchard": orchard(out, name, 25)
    elif name == "d2Willow": willow(out, name, 27)
    elif name == "d2BushA": bush(out, name, 31, 30, 15, [(8, 9, 6.5, 0), (16, 7, 7.5, 1), (23, 9, 6, 0)])
    elif name == "d2BushB": bush(out, name, 33, 22, 12, [(7, 7, 5.5, 0), (14, 6, 6, 1)])
    elif name == "d2TreeBelt": tree_belt(out, name, 41)
    elif name == "d2FgMeadow": fg_meadow(out, name, 81)
    elif name == "d2FgReeds": fg_reeds(out, name, 83)
    elif name.startswith("laneMoor"): lane(out, name, 70 + "ABCD".index(name[-1]), "moor")
    elif name.startswith("laneCobble"): lane(out, name, 74 + "ABCD".index(name[-1]), "cobble")
    elif name.startswith("laneEarth"): lane(out, name, 78 + "ABCD".index(name[-1]), "earth")
    elif name == "d2Smoke": smoke(out, name)
    elif name == "d2Fireflies": dots(out, name, 61, 96, 30, 9, [C("fireGold"), C("fireWhite")])
    elif name == "d2Sparks": dots(out, name, 63, 14, 24, 7, [C("fireGold"), C("fireOrange"), C("ember")])
    else: raise SystemExit("unknown depth sprite " + name)


SET = ("d2FirA d2FirB d2FirC d2FirD d2DeadTree d2FirBelt d2FirBeltB d2FirBeltFar d2FgFerns d2Linden d2Poplar "
       "d2PoplarB d2Orchard d2Willow d2BushA d2BushB d2TreeBelt d2FgMeadow d2FgReeds "
       "laneMoorA laneMoorB laneMoorC laneMoorD laneCobbleA laneCobbleB laneCobbleC laneCobbleD "
       "laneEarthA laneEarthB laneEarthC laneEarthD d2Smoke d2Fireflies d2Sparks").split()


def main():
    global PAL
    ap = argparse.ArgumentParser()
    ap.add_argument("out")
    ap.add_argument("names", nargs="*")
    ap.add_argument("--palette", default=DEFAULT_PALETTE)
    a = ap.parse_args()
    PAL = Palette(a.palette, True)
    os.makedirs(a.out, exist_ok=True)
    for name in a.names or SET:
        build(a.out, name)
    print("wrote", len(a.names or SET), "depth sprites to", a.out)


if __name__ == "__main__":
    main()
