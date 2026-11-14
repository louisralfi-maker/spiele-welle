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
          from the west a 48 px feather, then the core, then the bank's leading face, which leans out toward the foot
          (the low fog rolls out first). The core's top and the face are swirled by noise at two scales, so they roll
          in billows and tear into wisps; the cover grows over a soft depth of 14 to 22 px in eight dithered steps,
          the body darkens inward, and the shell on the moon's side (up and west) catches a little light. The east end
          runs out clear. The engine lays them every STRIDE px westward from the bank's edge; each sheet's face then
          lies inside the core of the sheet east of it, so only the first face shows and the bank is one soft volume.
          A is tall (its core above every screen's top), B covers what stands on the lane, C is a low roll in front
          of the creatures.
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
    # h, face width, the core's top (rows from the sheet's top), how far the face leans out at the foot, the soft depth
    # (px over which the cover grows from nothing to whole), the swirl's reach, seed
    "bankSheetA": dict(h=220, face=100, top=4, lean=0.75, soft=22, swirl=16, seed=211),
    "bankSheetB": dict(h=176, face=96, top=34, lean=0.8, soft=20, swirl=15, seed=213),
    "bankSheetC": dict(h=96, face=96, top=30, lean=0.9, soft=14, swirl=10, seed=215),
}
BODY = ["night0", "nightDeep", "nightBlue", "nightSlate"]
RIM = ["nightSlate", "nightHaze", "mistDark"]


def fbm(seed, u, v):
    return 0.62 * WA.vnoise2(seed, u, v) + 0.38 * WA.vnoise2(seed + 1, u * 2.3, v * 2.3)


def sheet_depth(spec, w, x, y):
    """How deep a point lies inside the sheet (px; negative: outside): the core under its top and west of the face,
    the face leaning out toward the foot (the bank's foot rolls out first), both edges swirled by noise at two scales
    so they roll in billows and tear into wisps."""
    h = spec["h"]
    sd = spec["seed"]
    x0 = w - spec["face"]
    t = y / float(h)
    face = x0 + 12 + (spec["face"] - 34) * (t ** spec["lean"])
    sx = face - x
    sy = y - spec["top"]
    d = min(sx, sy) if sx > 0 and sy > 0 else (sx if sy > 0 else sy if sx > 0 else -math.hypot(min(0, sx), min(0, sy)))
    sw = spec["swirl"]
    d += sw * (fbm(sd, x / 30.0, y / 26.0) - 0.5) * 2.0 + sw * 0.45 * (fbm(sd + 7, x / 9.0, y / 8.0) - 0.5) * 2.0
    return d


def sheet(name):
    spec = SHEETS[name]
    w, h = 256, spec["h"]
    core1 = w - spec["face"]
    # tile k's face must lie in the core of the sheet east of it, its west feather in the core of the sheet west of
    # it: face <= stride <= core1 - (feather + clear)
    assert spec["face"] <= STRIDE <= core1 - FEATHER - FEATHER_CLEAR, "a face must lie in the next sheet's core"
    soft = float(spec["soft"])
    body = [WA.col(n) for n in BODY]
    rim = [WA.col(n) for n in RIM]
    depth = [[sheet_depth(spec, w, x + 0.5, y + 0.5) for x in range(w)] for y in range(h)]
    img = PA.Image(w, h)
    for y in range(h):
        for x in range(w):
            d = depth[y][x]
            if d <= 0 or x >= w - FEATHER_CLEAR:
                continue
            # the west feather
            if x < FEATHER + FEATHER_CLEAR:
                if bay(x, y) >= (x - FEATHER_CLEAR) / float(FEATHER):
                    continue
            # the east end runs out clear whatever the swirl does
            east = ss((w - FEATHER_CLEAR - x) / 12.0)
            # the soft edge: the cover grows over `soft` px in eight dithered steps; the foot thins under the screen
            a = ss(d / soft) * ss((h - y) / 4.0) * east
            k = max(0, min(LEVELS - 1, int(round(a * (LEVELS - 1) + bay(x + 1, y + 3) - 0.5))))
            if not k:
                continue
            alpha = int(round(255 * k / (LEVELS - 1)))
            # colour: the night body darkening inward; the outer shell on the moon's side (up and west of the edge's
            # normal) catches a little light, so the billows show their round
            deep = ss((d - 3) / (soft * 1.8))
            ci = 3 - int(round(deep * 3 + (bay(x, y + 2) - 0.5) * 0.9))
            c = body[max(0, min(3, ci))]
            gx = depth[y][min(w - 1, x + 1)] - depth[y][max(0, x - 1)]
            gy = depth[min(h - 1, y + 1)][x] - depth[max(0, y - 1)][x]
            g = math.hypot(gx, gy)
            if g > 0.05 and d < soft * 0.7:
                lit = (gx * 0.6 + gy * 0.8) / g   # the outward normal (-g) against the moon's side (-0.6, -0.8)
                if lit > 0.3 and bay(x + 2, y) < (lit - 0.3) * 1.4 * (1 - d / (soft * 0.7)):
                    c = rim[min(2, int((lit - 0.3) * 3.5))]
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
