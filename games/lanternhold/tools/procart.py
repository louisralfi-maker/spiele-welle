#!/usr/bin/env python3
"""Lanternhold procedural foreground silhouettes (milestone M1b). Pure python 3, deterministic (seeded), palette only.

The foreground plane (parallax 1.3) frames the screen with dark shapes that carry little detail, so they are drawn
here rather than painted: a Recraft painting downscaled to a silhouette loses its texture anyway, and these stay
exactly reproducible.

  procart.py fgrock    <out.png> --style a|b|c [--seed N]   96x36 rock outcrop with ferns, grass and roots; flat
                                                            bottom edge, the profile falls to nothing at both ends
  procart.py overhang  <out.png> --style a|b   [--seed N]   128x48 rock lip for the top edge of the screen: flat top
                                                            edge, ragged underside, hanging roots and vines
  procart.py riverbase <out.png> [--seed N]                 220x64 base of riverEnd (placed at y -26): the grass
                                                            bank level with the ground tile at its left edge (row 38)
                                                            slopes down to the water at row 50; water to the right
                                                            edge and the bottom; tile/build-art.sh adds the painted
                                                            bridge stumps and reeds

  procart.py farbank   <out.png> [--seed N]                 240x30 the river's far bank for the mid plane: tree line,
                                                            reeds, the far bridge stump (M1b polish)
  procart.py slopebands <in.png> <out.png> --rect x0,y0,x1,y1   repaints a grass slope in a finished sprite: irregular
                                                            edge, three value bands, tuft clusters (M1b polish)
  procart.py cylinder  <in.png> <out.png> --rect x0,y0,x1,y1 --bands a-b:+1,c-d:-1 [--ramp names]
                                                            rounds a flat tower: shifts every ramp colour in the rect
                                                            by its column's band (+1 one step lighter), the band edges
                                                            dithered in a checker (polish after the art review)

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


def bayer4(x, y):
    m = [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]
    return (m[(y & 3) * 4 + (x & 3)] + 0.5) / 16


def cmd_riverbase(a):
    """M1b polish: the water fills everything below the bank (surface 4 rows under the ground line), solid bands
    instead of dither, a dark wet line where the bank meets the water, two highlight rows, and stepped voussoir stubs
    on the piers instead of the hook-shaped springers."""
    pal = Palette(a.palette, True)
    W, H, GL, WS = 220, 64, 38, 42
    rng = random.Random(a.seed * 31337)
    c = Canvas(W, H, pal)
    wob = value_noise(rng, W, 9)
    surf = []  # top of the bank per column; the bank face drops steeply into the water
    for x in range(W):
        t = min(1.0, max(0.0, (x - 30) / 34))
        t = t * t * (3 - 2 * t)
        surf.append(int(round(GL + (H - GL) * t + (wob[x] * 0.8 if 0.05 < t < 0.9 else 0))))
    for x in range(W):
        top = surf[x]
        for y in range(top, H):
            d = y - top
            if d < 3 and top <= WS:
                n = "leaf"
            elif d < 5 and top <= WS:
                n = "leafDark"
            elif y >= H - 3:
                n = "soilDark"
            elif y >= H - 7:
                n = "soil"
            else:
                n = "soilLight"
            c.put(x, y, n)
    # water: every empty pixel at or below the surface
    for x in range(W):
        for y in range(WS, H):
            if c.get(x, y) is not None:
                continue
            d = y - WS
            if d == 0:
                n = "foam" if (x * 7 + x // 5) % 11 == 0 else "daySky"
            elif d == 1:
                n = "daySky" if (x // 4 + x // 9) % 3 else "waterDeep"
            elif d < 12:
                n = "waterDeep"
            else:
                n = "roofDeep"
            c.put(x, y, n)
    # the wet line: bank pixels touching water on their right or below turn soilDark
    for x in range(W - 1):
        for y in range(GL, H):
            if c.get(x, y) in ("soilLight", "soil", "leafDark", "leaf") and y >= WS - 1:
                if c.get(x + 1, y) in ("waterDeep", "daySky", "foam", "roofDeep"):
                    c.put(x, y, "soilDark")
    for _ in range(18):  # ripples: short pale dashes on fixed rows (no checker)
        x = rng.randint(70, W - 8)
        y = rng.choice((WS + 4, WS + 6, WS + 9))
        for k in range(rng.randint(3, 6)):
            if c.get(x + k, y) == "waterDeep":
                c.put(x + k, y, "daySky")
    # two piers of the old bridge, each with a broken stepped arch springer (voussoir stubs) leaning out over the water
    for px0, pw, top, side in ((98, 15, 24, 1), (158, 15, 29, -1)):
        brk = value_noise(rng, 40, 3)
        for x in range(px0, px0 + pw):
            for y in range(top + int(abs(brk[x - px0]) * 3), H):
                col = x - px0
                course = (y - top) // 4
                joint = (col + (2 if course % 2 else 0)) % 6 == 0
                n = "stone"
                if (y - top) % 4 == 3 or joint:
                    n = "stoneDark"
                elif col == pw - 1 or col == pw - 2:
                    n = "stoneMid"
                elif col < 2 or (y - top) % 4 == 0:
                    n = "stoneLight"
                if col in (0, pw - 1):
                    n = "ink" if col == pw - 1 else n
                if WS - 2 <= y <= WS:
                    n = "stoneDark" if y == WS else "leafDark"  # moss and the wet line
                c.put(x, y, n)
        # voussoir stubs: three wedge blocks stepping up and out from the pier top, the last one broken
        for k in range(3):
            bw, bh = 4, 7 - k
            bx0 = px0 + pw + 4 * k if side > 0 else px0 - 4 * (k + 1)
            by0 = top - 2 - 3 * k
            for x in range(bx0, bx0 + bw):
                for y in range(by0, by0 + bh):
                    edge_out = (x == bx0 + bw - 1) if side > 0 else (x == bx0)
                    if k == 2 and y < by0 + 2 and edge_out:
                        continue  # the broken end
                    n = "stone"
                    if y == by0:
                        n = "stoneLight"
                    elif y == by0 + bh - 1:
                        n = "stoneDark"
                    if edge_out:
                        n = "stoneDark"
                    c.put(x, y, n)
            # fill under each block down to the pier top line so the stubs read as one masonry mass
            for x in range(bx0, bx0 + bw):
                for y in range(by0 + bh, top + 2):
                    if c.get(x, y) is None:
                        c.put(x, y, "stoneMid" if y < top else "stoneDark")
    for x in range(0, 60):  # grass tufts on the bank
        if rng.random() < 0.35:
            h = rng.randint(1, 3)
            for k in range(h):
                c.put(x, surf[x] - 1 - k, "leafDark" if k else "leaf")
    c.save(a.output)


def cmd_farbank(a):
    """M1b polish: the river's far bank for the mid plane (240x30): a low tree line and reeds on a thin strip of
    shore, and the far stump of the old bridge, so the river reads wide and closes the world."""
    pal = Palette(a.palette, True)
    W, H = 240, 30
    rng = random.Random(a.seed * 7919 + 3)
    c = Canvas(W, H, pal)
    base = H - 3  # shore line
    for x in range(W):  # the shore strip
        for y in range(base, H):
            c.put(x, y, "soilDark" if y == base else "leafDark")
    x = 0
    while x < W:  # tree crowns: overlapping rounded blobs, a light rim on top
        r = rng.randint(4, 8)
        h = rng.randint(10, 20)
        cx = x + r
        cy = base - h + r
        for yy in range(cy - r, base):
            for xx in range(cx - r, cx + r + 1):
                inside = (xx - cx) ** 2 + ((yy - cy) * 1.15) ** 2 <= r * r or (yy > cy and abs(xx - cx) <= 1)
                if inside and 0 <= xx < W and 0 <= yy < H:
                    c.put(xx, yy, "leafDark" if yy > cy - r // 2 else "leaf")
        x += rng.randint(r, 2 * r + 4)
        if rng.random() < 0.25:
            x += rng.randint(8, 20)  # gaps in the tree line
    for x in range(W):  # a light rim along the crown tops
        for y in range(H):
            if c.get(x, y) == "leaf" and (y == 0 or c.get(x, y - 1) is None):
                c.put(x, y, "meadow")
                break
    for _ in range(40):  # reeds along the shore
        x = rng.randint(0, W - 1)
        for k in range(rng.randint(2, 5)):
            c.put(x, base - 1 - k, "leaf" if k else "leafDark")
    px0, pw, top = 150, 8, base - 14  # the far bridge stump
    for x in range(px0, px0 + pw):
        for y in range(top, base + 1):
            n = "stoneMid" if (y - top) % 3 == 2 else "stone"
            if x == px0:
                n = "stoneLight"
            if x == px0 + pw - 1:
                n = "stoneDark"
            c.put(x, y, n)
    for k in range(2):  # its stub reaching back towards the near piers
        for x in range(px0 - 3 * (k + 1), px0 - 3 * k):
            for y in range(top - 2 - 2 * k, top + 3 - k):
                c.put(x, y, "stone" if y > top - 2 - 2 * k else "stoneLight")
    c.save(a.output)


def cmd_slopebands(a):
    """M1b polish: repaints the grass slope of a finished sprite (gorgeMouth) inside a rect: the ruler-straight top
    edge gets a seeded irregular profile (bumps and dips of 1 to 3 px), the flat meadow becomes three value bands that
    follow the edge (leafLight lip, meadow, leaf deeper, with a noisy boundary), and lone 1 px tufts merge away."""
    from pixelart import read_png
    pal = Palette(a.palette, True)
    img, _ = read_png(a.input)
    lut = {c: n for n, c in zip(pal.names, pal.rgb)}
    W, H = img.w, img.h
    c = Canvas(W, H, pal)
    for y in range(H):
        for x in range(W):
            p = img.get(x, y)
            if p[3]:
                c.px[y][x] = lut[p[:3]]
    x0, y0, x1, y1 = (int(v) for v in a.rect.split(","))
    rng = random.Random(a.seed * 104729)
    jit = value_noise(rng, W + 8, 5)
    bnd = value_noise(rng, W + 8, 7)
    grass = {"meadow", "leaf", "leafLight", "leafDark", "soilDark"}
    tops = {}
    for x in range(x0, x1 + 1):
        top = next((y for y in range(0, y1 + 1) if c.get(x, y) is not None), None)
        if top is None or c.get(x, top) not in grass:
            continue  # only columns whose top edge (seen from the sky) is the grass slope get the new edge
        j = int(round(jit[x] * 2.4))
        if j > 0:  # a dip: cut the top j pixels
            for y in range(top, min(y1, top + j)):
                c.px[y][x] = None
            top += j
        elif j < 0:  # a bump: grow -j pixels
            for y in range(max(0, top + j), top):
                c.px[y][x] = "meadow"
            top += j
        tops[x] = top
    # columns under the crag take the slope's straight-line fit as their virtual top, so the bands run on diagonally
    n = len(tops)
    mx = sum(tops) / n
    my = sum(tops.values()) / n
    b = sum((x - mx) * (t - my) for x, t in tops.items()) / max(1e-6, sum((x - mx) ** 2 for x in tops))
    for x in range(x0, x1 + 1):
        top = tops.get(x, my + b * (x - mx))
        for y in range(max(0, y0), y1 + 1):
            nm = c.get(x, y)
            if nm not in ("meadow", "leaf", "leafLight"):
                continue
            d = y - top
            lip = 2 if (x // 3) % 4 else 3
            deep = 16 + int(round(bnd[x] * 2))
            if x in tops and d < lip:
                c.px[y][x] = "leafLight"
            else:
                c.px[y][x] = "meadow" if d < deep else "leaf"
        if x in tops:
            c.px[tops[x]][x] = "leafDark"  # a dark rim along the new edge
    # tufts: small clusters of 2-3 px (leafLight over the lip, leafDark in the deep band), never single pixels
    for _ in range(a.tufts):
        x = rng.randint(x0 + 2, x1 - 4)
        top = next((y for y in range(y0, y1 + 1) if c.get(x, y) is not None), None)
        if top is None:
            continue
        y = top + rng.randint(4, 30)
        if y > y1 or c.get(x, y) not in ("meadow", "leaf"):
            continue
        n = "leafDark" if c.get(x, y) == "leaf" else "leaf"
        for dx, dy in ((0, 0), (1, 0), (1, -1))[: rng.randint(2, 3)]:
            if c.get(x + dx, y + dy) in ("meadow", "leaf"):
                c.px[y + dy][x + dx] = n
    c.save(a.output)


def cmd_cylinder(a):
    """Polish after the art review: a tower painted as a flat strip reads as cardboard. Every pixel inside the rect whose
    colour is on the ramp (default the castle stone ramp, darkest first) moves along it by its column's band: a lit
    band left of centre one step lighter, the side turning away one step darker. Pixels at a band's first and last
    column move only on a checker, so the terminator steps softly. Colours off the ramp (slits, moss, outline ink)
    stay; the ramp's darkest colour never moves (mortar shadows keep their depth)."""
    from pixelart import read_png
    pal = Palette(a.palette, True)
    img, _ = read_png(a.input)
    ramp = a.ramp.split(",")
    rgb = {n: pal.rgb[pal.index(n)] for n in ramp}
    index = {rgb[n]: i for i, n in enumerate(ramp)}
    x0, y0, x1, y1 = (int(v) for v in a.rect.split(","))
    bands = []
    for spec in a.bands.split(","):
        span, delta = spec.split(":")
        b0, b1 = (int(v) for v in span.split("-"))
        bands.append((b0, b1, int(delta)))
    out = img
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            p = img.get(x, y)
            if not p[3] or p[:3] not in index:
                continue
            i = index[p[:3]]
            if i == 0:
                continue
            d = 0
            for b0, b1, delta in bands:
                if b0 <= x <= b1:
                    edge = x == b0 or x == b1
                    if not edge or (x + y) % 2 == 0:
                        d += delta
            j = min(len(ramp) - 1, max(1, i + d))
            r, g, b = rgb[ramp[j]]
            out.set(x, y, (r, g, b, 255))
    write_png(a.output, out)
    print(f"wrote {a.output} {img.w}x{img.h} (cylinder)")


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
    rb = sub.add_parser("riverbase")
    rb.add_argument("output")
    rb.add_argument("--seed", type=int, default=1)
    rb.add_argument("--palette", default=DEFAULT_PALETTE)
    rb.set_defaults(fn=cmd_riverbase)
    fb = sub.add_parser("farbank")
    fb.add_argument("output")
    fb.add_argument("--seed", type=int, default=1)
    fb.add_argument("--palette", default=DEFAULT_PALETTE)
    fb.set_defaults(fn=cmd_farbank)
    sb = sub.add_parser("slopebands")
    sb.add_argument("input")
    sb.add_argument("output")
    sb.add_argument("--rect", required=True)
    sb.add_argument("--seed", type=int, default=1)
    sb.add_argument("--tufts", type=int, default=24)
    sb.add_argument("--palette", default=DEFAULT_PALETTE)
    sb.set_defaults(fn=cmd_slopebands)
    cy = sub.add_parser("cylinder")
    cy.add_argument("input")
    cy.add_argument("output")
    cy.add_argument("--rect", required=True)
    cy.add_argument("--bands", required=True)
    cy.add_argument("--ramp", default="night1,stoneDark,stoneMid,stone,stoneLight,stonePale")
    cy.add_argument("--palette", default=DEFAULT_PALETTE)
    cy.set_defaults(fn=cmd_cylinder)
    a = p.parse_args()
    a.fn(a)


if __name__ == "__main__":
    main()
