#!/usr/bin/env python3
"""Lanternhold look 2, stage 3: the Gloom's darkness bank (ART-look2.md "Stage 3: the creatures", the bank).
Writes three PNGs at the engine's sizes (SpriteID.darknessBank 64x236, darknessEdge 32x236):

  darknessBank.png      the body: opaque navy soot in slow billows that lean toward the castle, repeating every 64 px,
                        its top 36 rows thinning in an ordered dither
  darknessEdge.png      the leading edge: the same soot thinning to the right in a dithered band with reaching fingers;
                        its left column continues the body
  darknessBankGlow.png  4 frames of 64x236 for the port: pairs of cold eyes at many heights that blink out for a frame,
                        and a few motes of cold ash; nothing in it is opaque soot

Pure python, deterministic, about two seconds.   bankart.py [--out DIR]
"""
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from pixelart import Image, Palette, write_png, DEFAULT_PALETTE  # noqa: E402

W, EW, H, TOP = 64, 32, 236, 36
LANE = H - 26                      # the lane's surface row (WorldLayout.groundRowsBelow = 26)
SOOT = ["nightDeep", "night0", "nightBlue", "nightSlate"]
BAYER = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]


def bayer(x, y):
    return (BAYER[y % 4][x % 4] + 0.5) / 16


def h2(ix, iy, key):
    n = (ix * 374761393 + iy * 668265263 + key * 2246822519) & 0xFFFFFFFF
    n = ((n ^ (n >> 13)) * 1274126177) & 0xFFFFFFFF
    return ((n ^ (n >> 16)) & 0xFFFF) / 65535.0


def smooth(x, y, cell, key, period=None):
    """Value noise; with `period` (pixels, a multiple of cell) it repeats along x."""
    fx, fy = x / cell, y / cell
    ix, iy = math.floor(fx), math.floor(fy)
    tx, ty = fx - ix, fy - iy
    tx, ty = tx * tx * (3 - 2 * tx), ty * ty * (3 - 2 * ty)
    n = period // cell if period else None

    def v(i, j):
        return h2(i % n if n else i, j, key)
    a = v(ix, iy) + (v(ix + 1, iy) - v(ix, iy)) * tx
    b = v(ix, iy + 1) + (v(ix + 1, iy + 1) - v(ix, iy + 1)) * tx
    return a + (b - a) * ty


def soot(x, y):
    """The soot's value 0..1 at a world pixel: billows leaning right, lighter at their upper left, repeating every W."""
    big = smooth(x - y * 0.25, y, 16, 1, W)
    mid = smooth(x - y * 0.25, y * 1.3, 8, 2, W)
    up = smooth(x - (y - 3) * 0.25 - 2, y - 3, 16, 1, W)          # the same billow field 3 px lower: its upper rims
    v = 0.34 + (big - 0.5) * 0.7 + (mid - 0.5) * 0.3 + max(0.0, big - up) * 2.2
    return v + (y / H - 0.5) * -0.12                               # a little lighter toward the top, densest at the lane


def colour(v, x, y):
    f = min(2.999, max(0.0, v * 3))
    i = int(f)
    return SOOT[i + (1 if f - i > bayer(x, y) * 0.9 + 0.05 else 0)]


def main():
    a = sys.argv[1:]
    out = a[a.index("--out") + 1] if "--out" in a else os.path.join(os.path.dirname(HERE), "Resources", "Art")
    pal = Palette(DEFAULT_PALETTE, True)
    body, edge, glow = Image(W, H), Image(EW, H), Image(W * 4, H)
    for y in range(H):
        for x in range(W):
            if y < TOP and bayer(x, y) > y / TOP:
                continue
            body.set(x, y, pal.color(colour(soot(x, y), x, y)) + (255,))
        for x in range(EW):
            finger = smooth(x * 0.3, y, 6, 3)
            billow = smooth(x, y, 12, 4)
            d = 1.08 - x / EW * 1.15 + (billow - 0.5) * 0.5 + (0.55 if finger > 0.64 else 0.0)
            if y < TOP:
                d -= (TOP - y) / TOP
            if x == 0 and y >= TOP:
                d = 2.0
            if d > bayer(x, y):
                edge.set(x, y, pal.color(colour(soot(x, y) - (0.1 if d < 0.6 else 0.0), x, y)) + (255,))
    # the eyes: (x of the left eye, height above the lane, gap, the frame in which the pair is shut)
    eyes = [(6, 5, 2, 0), (37, 7, 2, 2), (52, 16, 2, 3), (21, 27, 2, 1), (44, 46, 3, 0), (10, 70, 3, 2), (30, 104, 4, 3)]
    motes = [(3, 150, 0), (17, 12, 1), (26, 62, 2), (33, 181, 3), (41, 124, 0), (49, 88, 1), (58, 33, 2), (13, 196, 3),
             (55, 160, 1), (24, 140, 2)]
    for k in range(4):
        for (x, hgt, gap, shut) in eyes:
            y = LANE - hgt
            for ex in (x, x + gap):
                if k == shut:
                    continue
                glow.set(k * W + ex, y, pal.color("wraithGlow" if hgt < 60 else "wraithDim") + (255,))
                if k == (shut + 2) % 4 and hgt < 60:
                    glow.set(k * W + ex, y + 1, pal.color("wraithDim") + (255,))        # the tear
        for (x, y, ph) in motes:
            if (k + ph) % 4 < 2:
                glow.set(k * W + x, y - (k + ph) % 4, pal.color("wraithDim") + (255,))
    for name, img in (("darknessBank", body), ("darknessEdge", edge), ("darknessBankGlow", glow)):
        write_png(os.path.join(out, name + ".png"), img)
        print(f"wrote {name}.png {img.w}x{img.h}")


main()
