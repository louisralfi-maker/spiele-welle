"""Slide 2 of the prologue (round 2): slide 1's place, closer and long ago. The same cleft in the Weltmauer, bare: no
castle, no house, no road. Low in it the ancestor, a person in a cloak, one arm raised, the first point of gold above
the hand; its light lies only on the planes close to it and facing it, in two warm tones; his long shadow runs as one
wedge over the ground toward the land. East the empty land under stars, not one window: slide 1 is the answer to this
one. West the dark recoils, a few eyes at its lip. One tiny point of gold in a huge dark.
"""
import math

import numpy as np

from litkit import (W, H, Pic, BAYER, core_glow, falloff, lit_figure, mountain, poly_mask, ellipse_mask, eyes, h)

SPARK = (149, 96)
FLOOR = 140


def slide2():
    p = Pic("nightBlue")
    # stars: few over the west, more over the empty east
    for (x, y) in ((24, 14), (46, 40), (262, 10), (280, 30), (300, 16), (312, 44), (272, 58), (292, 70), (246, 26),
                   (304, 86), (258, 80), (238, 50)):
        p.px(x, y, "moon")
    for (x, y) in ((286, 22), (250, 62)):
        p.px(x, y, "foam")
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            p.px(x + dx, y + dy, "moon")
    # the empty land east: three rows of low hills toward a dark horizon, no light
    for (base, amp, col, rim) in ((104, 3, "nightSlate", "night2"), (116, 5, "nightBlue", "nightSlate"),
                                  (132, 6, "nightDeep", "nightBlue")):
        for x in range(200, W):
            t = int(round(base - amp * abs(math.sin(x / 19.0 + base))))
            for y in range(t, H):
                p.px(x, y, col)
            p.px(x, t, rim)
    # the ground of the cleft and the west
    for y in range(FLOOR, H):
        for x in range(0, 230):
            p.px(x, y, "nightDeep")
    # the wall: two masses, wide at the foot, the cleft between, the light only on its lips
    def poly(pts):
        def f(y):
            for (ya, xa), (yb, xb) in zip(pts, pts[1:]):
                if ya <= y <= yb:
                    return xa + (xb - xa) * (y - ya) / float(yb - ya)
            return pts[-1][1]
        return f
    # straight segments, jagged: the ridge leaves the frame's top, the foot is wide
    outer_l = poly([(0, 104), (14, 96), (22, 100), (40, 86), (52, 90), (70, 72), (84, 76), (104, 58), (118, 62),
                    (FLOOR, 44)])
    inner_l = poly([(0, 141), (30, 139), (31, 136), (64, 135), (65, 138), (100, 137), (101, 134), (FLOOR, 133)])
    inner_r = poly([(0, 178), (24, 180), (25, 183), (58, 184), (59, 181), (96, 182), (97, 186), (FLOOR, 188)])
    outer_r = poly([(0, 216), (16, 224), (24, 220), (44, 234), (56, 230), (76, 246), (90, 242), (112, 258),
                    (FLOOR, 266)])
    mountain(p, outer_l, inner_l, inner_r, outer_r,
             facets_l=[(122, 84)], facets_r=[(200, 232)], light=SPARK, reach=40, lip=7, y1=FLOOR,
             warm=("gold", "tile", "crimsonDeep"))
    # a few short cracks across the planes, so the rock has volume and the light is broken by it
    for (x0, y0, x1, y1) in ((96, 40, 104, 62), (110, 90, 118, 112), (204, 30, 210, 54), (214, 96, 222, 120),
                             (128, 70, 134, 84), (180, 62, 186, 80), (126, 112, 132, 124), (182, 108, 188, 122)):
        n = max(abs(x1 - x0), abs(y1 - y0))
        for k in range(n + 1):
            x, y = round(x0 + (x1 - x0) * k / n), round(y0 + (y1 - y0) * k / n)
            if p.get(x, y) not in ("nightBlue", "night2") or True:
                p.px(x, y, "night0")
                if p.get(x + 1, y) in ("tileLight", "tile"):
                    p.px(x + 1, y, "plum")
    # the floor: a few short ember dashes near his feet, nothing more
    for (x, y, n, c) in ((136, FLOOR + 2, 4, "emberDim"), (142, FLOOR + 1, 5, "tile"), (164, FLOOR + 3, 3, "emberDim"),
                         (128, FLOOR + 4, 3, "emberDim"), (148, FLOOR + 5, 3, "emberDim"), (170, FLOOR + 1, 2, "tile")):
        for k in range(n):
            p.px(x + k, y, c)
    # his long shadow: one wedge from his feet over the ground toward the land
    fx = 156
    for y in range(FLOOR, FLOOR + 5):
        x0 = fx + (y - FLOOR) * 3
        for x in range(x0, min(W, x0 + 96 - (y - FLOOR) * 16)):
            if p.get(x, y) in ("tile", "plum", "plumDeep", "nightDeep", "nightBlue"):
                p.px(x, y, "night0")
    # a low step of rock under him, its top lit
    for y in range(FLOOR - 4, FLOOR + 1):
        for x in range(140, 172):
            if y == FLOOR - 4 and 142 <= x <= 169:
                p.px(x, y, "tile" if abs(x - SPARK[0]) < 12 else "crimsonDeep")
            elif y > FLOOR - 4 and 140 + (FLOOR - y) // 2 <= x <= 171 - (FLOOR - y) // 2:
                p.px(x, y, "nightDeep" if x < 160 else "night0")
    # the ancestor: a hand-set grid, hood, the raised arm, the hand; the spark above the hand
    lit_grid_fig(p)
    # the point of gold: small and hard, the stars' four rays drawn in gold
    sx, sy = SPARK
    p.px(sx, sy, "fireWhite")
    for d, c in ((1, "fireGold"), (2, "fireGold"), (3, "fireOrange")):
        for (dx, dy) in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            p.px(sx + dx * d, sy + dy * d, c)
    for (dx, dy) in ((1, 1), (-1, 1), (1, -1), (-1, -1)):
        p.px(sx + dx, sy + dy, "fireOrange")
    # the dark west, recoiling from the cleft: its front pulled back, a few eyes at its lip
    dk = np.zeros((H, W), bool)
    for y in range(70, H):
        f = 40 - 14 * math.cos((y - 70) / 90.0 * math.pi) + 3 * math.sin(y / 3.1) + 2 * math.sin(y / 7.0)
        dk[y, :max(0, int(f))] = True
    p.mask(dk, "night0")
    eyes(p, [(40, 112, 2, 1, 3, 0, 1, "wraithWhite"), (46, 132, 1, 1, 3, 1, 1, "wraithGlow"),
             (18, 96, 1, 1, 2, 0, 1, "wraithDim"), (30, 148, 2, 1, 2, 0, 1, "wraithGlow"),
             (10, 124, 1, 1, 3, -1, 1, "wraithDim")], inside=dk)
    return p


ANCESTOR = [
    "..FF............",
    ".FFF............",
    "..AA............",
    "..AAA...........",
    "...AA...........",
    "...AAA....HH....",
    "....AA...HHHH...",
    "....AAA.HHHHHH..",
    ".....AA.HHHHHHH.",
    ".....AAASHHHHHH.",
    "......AASSHHHHH.",
    "......AAASHHHHH.",
    ".......AACHHHHC.",
    ".......ACCCCCCCC",
    "......CCCCCCCCCC",
    "......CCCCCCCCCC",
    "......CCCCCCCCCC",
    ".....CCCCCCCCCCC",
    ".....CCCCCCCCCCC",
    ".....CCCCCCCCCCC",
    ".....CCCCCCCCCCC",
    "....CCCCCCCCCCCC",
    "....CCCCCCCCCCCC",
    "....CCCCCCCCCCCC",
    "....CCCCCCCCCCCC",
    "...CCCCCCCCCCCCC",
    "...CCCCCCCCCCCCC",
    "...CCCCCCCCCCCCC",
    "...CCCCCCCCCCCCC",
    "..CCCCCCCCCCCCCC",
    "..CCCCCCCCCCCCCC",
    "..CCCCCCC.CCCCCC",
    "..CCCCCC...CCCCC",
    ".CCCCCCC...CCCCC",
    ".CCCCCCC...CCCCC",
    ".CCCCCCC...CCCCCC"]
ANCESTOR_LEGEND = {"C": ("night0", "tileLight", "tile"), "A": ("night0", "tileLight", "tile"),
                   "H": ("night0", "tileLight", "tile"), "S": ("crimsonDeep", "dawnRose", "tileLight"),
                   "F": ("tile", "dawnRose", "dawnRose", 4)}


def lit_grid_fig(p):
    from litkit import grid_parts, light_grid
    light_grid(p, grid_parts(ANCESTOR, SPARK[0] - 1, FLOOR - 4 - len(ANCESTOR), ANCESTOR_LEGEND), SPARK[0], SPARK[1])
