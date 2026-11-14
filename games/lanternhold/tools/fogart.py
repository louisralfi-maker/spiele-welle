#!/usr/bin/env python3
"""Lanternhold world rebuild, step world-1 (docs/REVIEW-look-2.md B4, M1, 2.5): the fog. Pure python, palette colours
only, no randomness (hashes of the position), so a run reproduces its files byte for byte.

  fogart.py build <id> --out <Art dir>

  d2FogBank, d2MistBand, d2FogLow   the hour's three fog banks (fog A, the mist band, fog B), white alpha masks the
          engine colours: a density that is thickest at the foot and thins upward under a soft, rolling top, in eight
          alpha steps with ordered dither between them (no contour bands). Each is a tile of period P = width - 64 that
          the engine lays every P pixels: the tiles overlap by 64 px, and the two feathers inside the overlap use
          complementary dither, so where one tile's west feather lets a pixel through the other's east feather holds
          it back and the field goes on unbroken. The outer 8 px of each side are clear, the feathers 48 px wide; the
          foot feathers too. So no tile ends in a straight line, and the field itself never shows a seam.
  bankSheetA, bankSheetB, bankSheetC  the darkness bank (fog A, world, fog B), painted in the Gloom's night colours:
          from the west a 48 px feather, then the core (whole cover), then the bank's leading face: round billows
          that fall from the core's top to the lane, their upper west rims catching a little moonlight. The engine lays
          them every STRIDE px westward from the bank's edge; each sheet's face then lies inside the core of the sheet
          east of it (face width <= stride <= the core's opaque width), so only the first face shows and the bank is one soft
          volume. A is tall (its core above every screen's top), B covers what stands on the lane, C is a low roll in
          front of the creatures.
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import pixelart as PA  # noqa: E402
import worldart as WA  # noqa: E402

h01 = WA.h01
BAYER8 = [
    0, 32, 8, 40, 2, 34, 10, 42, 48, 16, 56, 24, 50, 18, 58, 26, 12, 44, 4, 36, 14, 46, 6, 38, 60, 28, 52, 20, 62, 30,
    54, 22, 3, 35, 11, 43, 1, 33, 9, 41, 51, 19, 59, 27, 49, 17, 57, 25, 15, 47, 7, 39, 13, 45, 5, 37, 63, 31, 55, 23,
    61, 29, 53, 21]


def bay(x, y):
    return (BAYER8[((y & 7) << 3) | (x & 7)] + 0.5) / 64


def ss(t):
    t = min(1.0, max(0.0, t))
    return t * t * (3 - 2 * t)


def pnoise(seed, u, n):
    """Smooth value noise in [0, 1) with period n lattice cells."""
    i = math.floor(u)
    f = u - i
    f = f * f * (3 - 2 * f)
    a = h01(seed, int(i) % n)
    b = h01(seed, int(i + 1) % n)
    return a + (b - a) * f


# ---------------------------------------------------------------------------------------------- the hour's fog

OVERLAP = 64
FEATHER = 48
FEATHER_CLEAR = 8
LEVELS = 8

FOG = {
    # w, h, the densest alpha, the top's range (rows above the foot), the soft share of the height, the foot's feather
    "d2FogBank": dict(w=384, h=40, peak=0.92, top=(24, 39), soft=0.62, foot=5, seed=111),
    "d2MistBand": dict(w=448, h=60, peak=0.80, top=(30, 59), soft=0.66, foot=6, seed=113),
    "d2FogLow": dict(w=320, h=24, peak=0.50, top=(11, 23), soft=0.70, foot=5, seed=115),
}


def period(name):
    return FOG[name]["w"] - OVERLAP


def fog_density(spec, x, ya):
    """The field at tile x (periodic with P) and ya rows above the foot: 0 ... peak."""
    P = spec["w"] - OVERLAP
    sd = spec["seed"]
    lo, hi = spec["top"]
    # the rolling top: two scales of billows, both periodic over P
    roll = 0.6 * pnoise(sd, x * 8.0 / P, 8) + 0.4 * pnoise(sd + 1, x * 20.0 / P, 20)
    top = lo + (hi - lo) * roll
    soft = spec["soft"] * spec["h"]
    d = ss((top - ya) / soft)
    # the body breathes: thinner places and thicker cores
    body = 0.8 + 0.2 * pnoise(sd + 2, x * 12.0 / P, 12) * (0.6 + 0.4 * pnoise(sd + 3, ya / 7.0 + x * 4.0 / P, 4))
    foot = ss((ya + 0.5) / spec["foot"])
    return spec["peak"] * d * body * foot


def fog_tile(name):
    spec = FOG[name]
    w, h = spec["w"], spec["h"]
    P = w - OVERLAP
    assert P % 8 == 0, "the period keeps the dither's phase"
    img = PA.Image(w, h)
    for y in range(h):
        ya = h - 1 - y
        for x in range(w):
            # The feathers: inside the overlap the east tile (local x) holds a pixel where bay < r, the west tile
            # (local x + P) where bay >= r; r runs 0 ... 1 over the 48 px between the clear 8 px at each end.
            u = x if x < OVERLAP else x - P if x >= P else None
            if u is not None:
                r = min(1.0, max(0.0, (u - FEATHER_CLEAR) / float(FEATHER)))
                held = bay(x, y) < r
                if (x < OVERLAP) != held:
                    continue
            a = fog_density(spec, x % P, ya)
            q = a * (LEVELS - 1) / spec["peak"] + (bay(x + 3, y + 5) - 0.5)
            k = max(0, min(LEVELS - 1, int(round(q))))
            if k:
                img.set(x, y, (255, 255, 255, int(round(255 * spec["peak"] * k / (LEVELS - 1)))))
    return img


# ---------------------------------------------------------------------------------------------- the darkness bank

STRIDE = 100
SHEETS = {
    # h, face width, core top (rows from the sheet's top) and its roll, billow radii, seed
    "bankSheetA": dict(h=220, face=100, top=(2, 12), r=(18, 32), seed=211),
    "bankSheetB": dict(h=176, face=92, top=(12, 28), r=(14, 26), seed=213),
    "bankSheetC": dict(h=96, face=96, top=(16, 28), r=(10, 18), seed=215),
}
BODY = ["night0", "nightDeep", "nightBlue"]
CREST = ["nightBlue", "nightSlate", "night2"]


def sheet_shape(spec, w):
    """The billows of the face: circles along a path from the core's top east corner down to the lane, the higher ones
    larger and leaning back, the low ones creeping ahead."""
    h = spec["h"]
    x0 = w - spec["face"]
    sd = spec["seed"]
    rlo, rhi = spec["r"]
    out = []
    n = 9
    for i in range(n):
        t = (i + 0.5) / n
        r = rhi - (rhi - rlo) * t + 3 * (h01(sd, i, 1) - 0.5)
        cx = x0 - r * 0.4 + (spec["face"] - 18 + r * 0.4) * t ** 0.85 - r * 0.5 + 6 * (h01(sd, i, 2) - 0.5)
        cy = spec["top"][1] + r * 0.6 + (h - spec["top"][1] - r - 6) * t ** 1.1 + 4 * (h01(sd, i, 3) - 0.5)
        out.append((cx, cy, r))
    return out


def sheet(name):
    spec = SHEETS[name]
    w, h = 256, spec["h"]
    core1 = w - spec["face"]
    # tile k's face must lie in the core of the sheet east of it, its west feather in the core of the sheet west of
    # it: face <= stride <= core1 - (feather + clear)
    assert spec["face"] <= STRIDE <= core1 - FEATHER - FEATHER_CLEAR, "a face must lie in the next sheet's core"
    sd = spec["seed"]
    billows = sheet_shape(spec, w)
    lo, hi = spec["top"]
    body = [WA.col(n) for n in BODY]
    crest = [WA.col(n) for n in CREST]
    img = PA.Image(w, h)
    for y in range(h):
        for x in range(w):
            # signed depth inside the silhouette (px), and how much of a billow's moonlit rim the pixel is
            inside = -99.0
            rimlight = 0.0
            # the core, its east side a slope that the billows bulge out of
            top = lo + (hi - lo) * (0.7 * pnoise(sd + 5, x / 31.0, 64) + 0.3 * pnoise(sd + 6, x / 11.0, 64))
            slope = (h - top) / float(w - 8 - core1)
            east = core1 + max(0.0, y - top) / slope
            inside = min(y - top, (east - x) * 0.9)
            if 0 < inside < 3 and y - top < 3:
                rimlight = (1 - inside / 3.0) * 0.5
            for (cx, cy, r) in billows:
                dx, dy = x + 0.5 - cx, y + 0.5 - cy
                depth = r - math.sqrt(dx * dx + dy * dy)
                if depth > inside:
                    inside = depth
                if 0 < depth < 4 and dy < -r * 0.5 and dx < 0:
                    rimlight = max(rimlight, (1 - depth / 4.0) * 0.6 * min(1.0, -dy / r))
            # under the billows' path the bank is whole down to the lane
            for i in range(len(billows) - 1):
                (ax, ay, ar), (bx, by, br) = billows[i], billows[i + 1]
                if ax <= x < bx:
                    py = ay + (by - ay) * (x - ax) / (bx - ax)
                    lx, ly, lr = billows[-1]
                    toe = (lx + lr * 0.3 - x) + max(0.0, y - ly) * 0.5   # the foot creeps ahead on the lane
                    inside = max(inside, min(y - py, toe))
            if inside <= 0:
                continue
            # the west feather
            if x < FEATHER + FEATHER_CLEAR:
                if bay(x, y) >= (x - FEATHER_CLEAR) / float(FEATHER):
                    continue
            # the soft edge: eight alpha steps over 6 px, dithered
            a = ss(inside / 6.0)
            # the foot: the lowest four rows lie under every screen's bottom; they thin out
            a *= ss((h - y) / 4.0)
            k = max(0, min(LEVELS - 1, int(round(a * (LEVELS - 1) + bay(x + 1, y + 3) - 0.5))))
            if not k:
                continue
            alpha = int(round(255 * k / (LEVELS - 1)))
            # colour: the night body darkening inward, the upper west rims of the billows a little moonlit
            deep = ss((inside - 3) / 10.0)
            ci = 2 - int(round(deep * 2 + (bay(x, y + 2) - 0.5) * 0.8))
            c = body[max(0, min(2, ci))]
            if rimlight > 0.2 and bay(x + 2, y) < rimlight:
                c = crest[max(0, min(2, int(rimlight * 2.4)))]
            img.set(x, y, (c[0], c[1], c[2], alpha))
    return img


def build(name, out):
    if name in FOG:
        img = fog_tile(name)
    elif name in SHEETS:
        img = sheet(name)
    else:
        raise SystemExit("unknown fog " + name)
    path = os.path.join(out, name + ".png")
    PA.write_png(path, img)
    print("wrote", path, img.w, "x", img.h)


def main():
    a = sys.argv[1:]
    if len(a) >= 4 and a[0] == "build" and a[2] == "--out":
        build(a[1], a[3])
        return
    raise SystemExit(__doc__)


if __name__ == "__main__":
    main()
