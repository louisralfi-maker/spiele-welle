#!/usr/bin/env python3
"""Lanternhold procedural foreground silhouettes (milestone M1b). Pure python 3, deterministic (seeded), palette only.

The foreground plane (parallax 1.3) frames the screen with dark shapes that carry little detail, so they are drawn
here rather than painted: a Recraft painting downscaled to a silhouette loses its texture anyway, and these stay
exactly reproducible.

  procart.py fgrock    <out.png> --style a|b|c [--seed N]   96x36 rock outcrop with ferns, grass and roots; flat
                                                            bottom edge, the profile falls to nothing at both ends
  procart.py overhang  <out.png> --style a|b   [--seed N]   128x48 rock lip for the top edge of the screen: flat top
                                                            edge, ragged underside, hanging roots and vines

Colours: rockDeep, soilDark, leafDark, with sparse rockDark rims, leaf tips and woodDark roots (all albedo).
"""
import argparse
import math
import os
import random
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from pixelart import Image, Palette, write_png, DEFAULT_PALETTE  # noqa: E402


class Canvas:
    def __init__(self, w, h, pal):
        self.w, self.h, self.pal = w, h, pal
        self.px = [[None] * w for _ in range(h)]

    def put(self, x, y, name, only_empty=False, only_full=False):
        if 0 <= x < self.w and 0 <= y < self.h:
            if only_empty and self.px[y][x] is not None:
                return
            if only_full and self.px[y][x] is None:
                return
            self.px[y][x] = name

    def get(self, x, y):
        return self.px[y][x] if 0 <= x < self.w and 0 <= y < self.h else None

    def save(self, path):
        img = Image(self.w, self.h)
        for y in range(self.h):
            for x in range(self.w):
                n = self.px[y][x]
                if n is not None:
                    r, g, b = self.pal.color(n)
                    img.set(x, y, (r, g, b, 255))
        write_png(path, img)
        print(f"wrote {path} {self.w}x{self.h}")


def value_noise(rng, n, step):
    """1-D smooth noise in [-1, 1], n samples, control points every `step` samples."""
    pts = [rng.uniform(-1, 1) for _ in range(n // step + 3)]
    out = []
    for i in range(n):
        f = i / step
        k = int(f)
        t = f - k
        t = t * t * (3 - 2 * t)
        out.append(pts[k] + (pts[k + 1] - pts[k]) * t)
    return out


def fern(c, rng, bx, by, size, lean):
    """A fern clump rooted at (bx, by) (by = top of the rock there), fronds arching outwards."""
    fronds = rng.randint(3, 5)
    for k in range(fronds):
        ang = math.radians(-90 + lean * 10 + (k - (fronds - 1) / 2) * rng.uniform(22, 32))
        length = size * rng.uniform(0.7, 1.0)
        droop = rng.uniform(0.04, 0.08)
        x, y = float(bx), float(by)
        dx, dy = math.cos(ang), math.sin(ang)
        for s in range(int(length)):
            x += dx
            y += dy
            dy += droop
            ix, iy = int(round(x)), int(round(y))
            c.put(ix, iy, "leafDark")
            if s > 1 and s % 2 == 0:  # leaflets on both sides
                nx, ny = -dy, dx
                for side in (-1, 1):
                    c.put(int(round(x + side * nx * 1.5)), int(round(y + side * ny * 1.5)), "leafDark")
            if s == int(length) - 1 and rng.random() < 0.7:
                c.put(ix, iy, "leaf")


def grass(c, rng, x0, x1, base_of):
    for x in range(x0, x1):
        if rng.random() < 0.45:
            by = base_of(x)
            if by is None:
                continue
            h = rng.randint(2, 5)
            lean = rng.choice((-1, 0, 0, 1))
            for s in range(h):
                c.put(x + (lean if s >= h - 2 else 0), by - 1 - s, "leafDark")


def cmd_fgrock(a):
    pal = Palette(a.palette, True)
    W, H = 96, 36
    rng = random.Random(a.seed * 7919 + ord(a.style))
    c = Canvas(W, H, pal)
    # boulders: (centre x, half width, height, roundness)
    shapes = {
        "a": [(34, 30, 33, 2.4), (70, 18, 20, 2.0), (12, 10, 10, 2.0)],
        "b": [(24, 20, 24, 2.2), (58, 22, 28, 2.6), (84, 10, 12, 2.0)],
        "c": [(48, 44, 15, 3.2), (30, 14, 22, 2.2), (78, 9, 10, 2.0)],
    }[a.style]
    jitter = value_noise(rng, W, 5)
    fine = value_noise(rng, W, 2)
    top = [H] * W  # first opaque row per column
    for x in range(W):
        best = 0.0
        for cx, hw, hh, p in shapes:
            u = abs(x + 0.5 - cx) / hw
            if u < 1:
                best = max(best, hh * (1 - u ** p) ** (1 / p))
        if best > 0:
            best += jitter[x] * 1.6 + fine[x] * 0.7
        h = int(round(best))
        h = max(0, min(H, h))
        top[x] = H - h
        for y in range(H - h, H):
            c.put(x, y, "rockDeep")
    # soil band along the bottom with a noisy edge
    band = value_noise(rng, W, 7)
    for x in range(W):
        b = int(round(7 + band[x] * 3))
        for y in range(H - b, H):
            c.put(x, y, "soilDark", only_full=True)
    # a broken moonlit rim on the upper left faces, and a few cracks
    for x in range(1, W):
        t = top[x]
        if t < H - 3 and top[x - 1] >= t and rng.random() < 0.55:
            c.put(x, t, "rockDark")
            if rng.random() < 0.3:
                c.put(x, t + 1, "rockDark")
    for _ in range(4 if a.style != "c" else 3):
        x = rng.randint(8, W - 8)
        if top[x] > H - 10:
            continue
        y = top[x] + rng.randint(3, 6)
        for s in range(rng.randint(3, 7)):
            c.put(x, y, "soilDark", only_full=True)
            y += 1
            x += rng.choice((-1, 0, 0, 1))
    # vegetation
    base = lambda x: top[x] if top[x] < H else None  # noqa: E731
    clumps = {"a": [(24, 9, -1), (66, 7, 1)], "b": [(54, 9, 0), (20, 6, -1)], "c": [(30, 8, -1), (80, 5, 1)]}[a.style]
    for fx, size, lean in clumps:
        fx += rng.randint(-3, 3)
        fern(c, rng, fx, top[fx] + 1, size, lean)
    grass(c, rng, 0, W, base)
    if a.style == "c":  # roots curling over the front of the ledge
        for _ in range(5):
            x = rng.randint(14, 84)
            y = top[x] + 1
            for s in range(rng.randint(4, 9)):
                c.put(x, y, "woodDark", only_full=True)
                y += 1
                x += rng.choice((-1, 1, 0))
    c.save(a.output)


def cmd_overhang(a):
    pal = Palette(a.palette, True)
    W, H = 128, 48
    rng = random.Random(a.seed * 104729 + ord(a.style))
    c = Canvas(W, H, pal)
    big = value_noise(rng, W, 16)
    mid = value_noise(rng, W, 6)
    fine = value_noise(rng, W, 2)
    lobes = {"a": [(30, 14, 10), (92, 18, 7)], "b": [(60, 22, 9), (110, 9, 5)]}[a.style]
    depth = []
    for x in range(W):
        d = 13 + big[x] * 4 + mid[x] * 2.2 + fine[x] * 0.9
        for cx, hw, extra in lobes:
            u = abs(x + 0.5 - cx) / hw
            if u < 1:
                d += extra * (1 - u * u)
        edge = min(x + 0.5, W - x - 0.5)  # taper to a thin lip at both ends
        if edge < 12:
            d *= 0.35 + 0.65 * (edge / 12) ** 0.7
        depth.append(max(3, min(H - 18, int(round(d)))))
    for x in range(W):
        for y in range(depth[x]):
            c.put(x, y, "rockDeep")
        for y in range(min(depth[x], 4 + int(round(mid[x] * 1.5)))):
            c.put(x, y, "soilDark")  # earth and turf at the very top
    # sparse rim on the underside, and cracks
    for x in range(W):
        if rng.random() < 0.35:
            c.put(x, depth[x] - 1, "rockDark")
    for _ in range(5):
        x = rng.randint(6, W - 6)
        y = rng.randint(4, max(5, depth[x] - 3))
        for s in range(rng.randint(3, 6)):
            c.put(x, y, "soilDark", only_full=True)
            y += 1
            x += rng.choice((-1, 0, 1))
    # hanging roots
    for _ in range(rng.randint(7, 10)):
        x = rng.randint(4, W - 5)
        y = depth[x]
        length = rng.randint(5, 22)
        col = rng.choice(("soilDark", "woodDark", "woodDark"))
        for s in range(length):
            c.put(x, y, col)
            y += 1
            if s % rng.randint(3, 5) == 2:
                x += rng.choice((-1, 1))
            if s > 4 and rng.random() < 0.08:  # a side rootlet
                c.put(x + 1, y, col)
                c.put(x + 2, y + 1, col)
    # vines with leaves
    for _ in range(rng.randint(3, 5)):
        x = rng.randint(6, W - 7)
        y = depth[x]
        length = rng.randint(8, 24)
        for s in range(length):
            c.put(x, y, "leafDark")
            if s % 3 == 1:
                side = 1 if (s // 3) % 2 else -1
                c.put(x + side, y, "leaf" if rng.random() < 0.5 else "leafDark")
            y += 1
            if rng.random() < 0.18:
                x += rng.choice((-1, 1))
    c.save(a.output)


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = p.add_subparsers(dest="cmd", required=True)
    r = sub.add_parser("fgrock")
    r.add_argument("output")
    r.add_argument("--style", choices=["a", "b", "c"], required=True)
    r.add_argument("--seed", type=int, default=1)
    r.add_argument("--palette", default=DEFAULT_PALETTE)
    r.set_defaults(fn=cmd_fgrock)
    o = sub.add_parser("overhang")
    o.add_argument("output")
    o.add_argument("--style", choices=["a", "b"], required=True)
    o.add_argument("--seed", type=int, default=1)
    o.add_argument("--palette", default=DEFAULT_PALETTE)
    o.set_defaults(fn=cmd_overhang)
    a = p.parse_args()
    a.fn(a)


if __name__ == "__main__":
    main()
