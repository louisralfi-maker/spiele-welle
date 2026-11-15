#!/usr/bin/env python3
"""The title's light language for the prologue slides (copied and adapted from tools/titleart.py on claude/lh-title,
round 5, ce729f3): light against dark, volume before detail, a quiet ordered dither in the air (each palette step
keeps 60 % of its band solid, the rest mixes in 25 / 50 / 75 %), solid steps on surfaces, the dark in the night0
family with eyes alone. numpy + PIL for the drawing; saved through paint.write_png (paint.py itself is unchanged), so
the files are written exactly as the other slides. Deterministic: no random source, only position hashes.
"""
import math
import os
import sys

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from paint import PAL, write_png  # noqa: E402

W, H = 320, 160
BAYER = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]
AIR = ["night2", "plum", "dusk", "tileLight", "gold", "fireGold"]          # dusk violet .. pale gold
STONE = ["plumDeep", "plum", "tile", "tileLight", "straw", "strawLight"]  # plum .. rust .. amber .. warm sand
COLD = ["nightSlate", "night2", "nightHaze", "far", "moon", "farPale"]    # the moon's cold ramp


def C(n):
    return PAL[n]


def h(x, y, s=0):
    v = (x * 374761393 + y * 668265263 + s * 2246822519) & 0xFFFFFFFF
    v = ((v ^ (v >> 13)) * 1274126177) & 0xFFFFFFFF
    return ((v ^ (v >> 16)) & 0xFFFFFF) / float(0x1000000)


def pick_air(x, y, cols, p):
    if p <= 0:
        return cols[0]
    i = int(p)
    if i >= len(cols) - 1:
        return cols[-1]
    f = p - i
    if f < 0.6:
        return cols[i]
    level = (4, 8, 12)[min(2, int((f - 0.6) / 0.4 * 3))]
    return cols[i + 1] if BAYER[y % 4][x % 4] < level else cols[i]


def pick_solid(cols, p):
    return cols[max(0, min(len(cols) - 1, int(p)))]


def falloff(x, y, cx, cy, rx, ry, g=1.35):
    return max(0.0, 1.0 - math.hypot((x - cx) / rx, (y - cy) / ry)) ** g


def poly_mask(pts, w=W, hh=H):
    m = np.zeros((hh, w), bool)
    n = len(pts)
    for y in range(hh):
        yc = y + 0.5
        xs = []
        for i in range(n):
            (x0, y0), (x1, y1) = pts[i], pts[(i + 1) % n]
            if (y0 <= yc < y1) or (y1 <= yc < y0):
                xs.append(x0 + (yc - y0) * (x1 - x0) / (y1 - y0))
        xs.sort()
        for i in range(0, len(xs) - 1, 2):
            a = int(math.ceil(xs[i] - 0.5))
            b = int(math.floor(xs[i + 1] - 0.5))
            if b >= a:
                m[y, max(0, a):min(w, b + 1)] = True
    return m


def ellipse_mask(cx, cy, rx, ry, w=W, hh=H):
    yy, xx = np.mgrid[:hh, :w]
    return ((xx + 0.5 - cx) / rx) ** 2 + ((yy + 0.5 - cy) / ry) ** 2 <= 1.0


def edge_of(m):
    return m & ~(np.roll(m, 1, 0) & np.roll(m, -1, 0) & np.roll(m, 1, 1) & np.roll(m, -1, 1))


class Pic:
    """A slide: names per pixel, so every pixel stays a palette colour by construction."""

    def __init__(self, fill="night0"):
        self.n = np.full((H, W), fill, dtype=object)

    def px(self, x, y, name):
        x, y = int(x), int(y)
        if 0 <= x < W and 0 <= y < H and name:
            self.n[y, x] = name

    def get(self, x, y):
        return self.n[int(y), int(x)] if (0 <= x < W and 0 <= y < H) else None

    def mask(self, m, name):
        self.n[m] = name

    def rgb(self):
        out = np.zeros((H, W, 3), np.uint8)
        for name in set(self.n.flat):
            out[self.n == name] = C(name)
        return out

    def save(self, path):
        a = self.rgb()
        allowed = set(PAL.values())
        assert all(tuple(int(v) for v in a[y, x]) in allowed for y in range(H) for x in range(W))
        rows = [bytearray(np.concatenate([a[y], np.full((W, 1), 255, np.uint8)], axis=1).tobytes())
                for y in range(H)]
        write_png(path, W, H, rows)

    def save_preview(self, path, zoom=3):
        a = np.repeat(np.repeat(self.rgb(), zoom, 0), zoom, 1)
        rows = [bytearray(np.concatenate([a[y], np.full((W * zoom, 1), 255, np.uint8)], axis=1).tobytes())
                for y in range(H * zoom)]
        write_png(path, W * zoom, H * zoom, rows)


def lit_mass(pic, m, base, lx, ly, rx, ry, k_face=0.45, k_edge=1.0, depth=3, ramp=STONE, quant=6, g=1.25,
             cold_rim=None, cold_dir=(-1, -1)):
    """A solid mass lit by a point: the edges turned to the light (a step toward it leaves the mass) take the warm
    ramp fully, depth 1..depth px in; the rest of the face a share k_face; everything in solid steps sampled on a
    quant-px grid (so the steps follow planes, not pixels). cold_rim: a colour for edges turned to cold_dir (the sky)."""
    ys, xs = np.where(m)
    for y, x in zip(ys, xs):
        d = math.hypot(x - lx, y - ly) or 1.0
        vx, vy = (lx - x) / d, (ly - y) / d
        facing = 0
        for k in range(1, depth + 1):
            qx, qy = int(round(x + vx * k)), int(round(y + vy * k))
            if not (0 <= qx < W and 0 <= qy < H) or not m[qy, qx]:
                facing = k
                break
        t = falloff((x // quant) * quant + quant / 2.0, (y // quant) * quant + quant / 2.0, lx, ly, rx, ry, g)
        k = (k_edge * (1.0 - 0.18 * (facing - 1))) if facing else k_face
        i = int(t * len(ramp) * k)
        if i <= 0 and cold_rim:
            qx, qy = x + cold_dir[0], y + cold_dir[1]
            if not (0 <= qx < W and 0 <= qy < H) or not m[qy, qx]:
                pic.px(x, y, cold_rim)
                continue
        pic.px(x, y, ([base] + ramp)[min(len(ramp), max(0, i))])


def air(pic, base_fn, lx, ly, rx, ry, scale=6.2, g=1.35, mask=None, ramp=AIR):
    for y in range(H):
        for x in range(W):
            if mask is not None and not mask[y, x]:
                continue
            pic.px(x, y, pick_air(x, y, [base_fn(x, y)] + ramp, falloff(x, y, lx, ly, rx, ry, g) * scale))


def bands(stops, mix=10):
    """A sky of flat bands meeting in ordered dither over `mix` rows: stops [(y0, name), ...]."""
    def f(x, y):
        n = stops[0][1]
        for (y0, c) in stops:
            if y >= y0:
                n = c
        for i in range(1, len(stops)):
            y0, c = stops[i]
            d = y - (y0 - mix // 2)
            if 0 <= d < mix:
                return c if BAYER[y % 4][x % 4] < int(16 * (d + 0.5) / mix) else stops[i - 1][1]
        return n
    return f


def eyes(pic, pairs, inside=None):
    """Pairs of eyes, no two alike: (x, y, w, h, gap, right eye dy, right eye h, colour). No outline, no halo."""
    for (x, y, w_, h_, gap, dyr, hr, col) in pairs:
        for (ex, ey, eh) in ((x, y, h_), (x + w_ + gap, y + dyr, hr)):
            for dx in range(w_):
                for dy in range(eh):
                    X, Y = ex + dx, ey + dy
                    if inside is None or inside[Y, X]:
                        pic.px(X, Y, col if dy == 0 or col != "wraithWhite" else "wraithGlow")


def grid(pic, rows, x0, y0, legend, flip=False):
    """A hand-drawn sprite from text rows; '.' is empty. legend maps a char to a palette name."""
    for r, row in enumerate(rows):
        for q, ch in enumerate(row[::-1] if flip else row):
            if ch != "." and ch != " ":
                pic.px(x0 + q, y0 + r, legend[ch])


def grid_mask(rows, x0, y0, flip=False):
    m = np.zeros((H, W), bool)
    for r, row in enumerate(rows):
        for q, ch in enumerate(row[::-1] if flip else row):
            if ch != "." and ch != " " and 0 <= x0 + q < W and 0 <= y0 + r < H:
                m[y0 + r, x0 + q] = True
    return m
