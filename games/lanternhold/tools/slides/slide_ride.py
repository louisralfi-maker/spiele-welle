"""Slide 3 of the prologue (round 2): "This autumn the Great Beacon went dark. / Lord Aldric rode out to light it. He
did not come back." A moon of 42 px, its centre low and off the tower's axis, so the beacon's empty iron basket
stands black inside the disc: a dead beacon, not a lamp. Aldric rides west, a third of the picture's height: horse
and rider dark masses (barrel, neck, head, legs in stride, the cloak one mass), his lantern lighting the horse's neck
and chest and his own front in planes, the moon one cold tone on his back and the croup. Four bearers, 15 px each,
follow him down. The last warm window at the right edge. The light is seen on what it hits (rule A, rule B).
"""
import math

import numpy as np

from litkit import (W, H, Pic, BAYER, core_glow, falloff, lit_figure, poly_mask, ellipse_mask, edge_of, h,
                    grid_parts, light_grid)

MOON = (66, 60)
MOON_R = 21
LAMP = (122, 83)


def ground_y(x):
    return int(round(140 - (x - 150) * 0.12 + 1.5 * math.sin(x / 9.0)))


def P(pts):
    return poly_mask(pts)


def E(cx, cy, rx, ry):
    return ellipse_mask(cx, cy, rx, ry)


def leg(m, pts, th=2):
    for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
        n = max(abs(x1 - x0), abs(y1 - y0), 1)
        for k in range(n + 1):
            x = round(x0 + (x1 - x0) * k / n)
            y = round(y0 + (y1 - y0) * k / n)
            for dx in range(th):
                m[y, x + dx] = True


def slide3():
    p = Pic("nightBlue")
    for (x, y) in ((150, 12), (196, 30), (238, 10), (272, 44), (300, 18), (180, 56), (226, 66), (120, 20), (12, 14),
                   (28, 96)):
        p.px(x, y, "moon")
    # the moon: one disc of 42 px, one dither ring around it, nothing more
    for y in range(MOON[1] - MOON_R - 6, MOON[1] + MOON_R + 7):
        for x in range(MOON[0] - MOON_R - 6, MOON[0] + MOON_R + 7):
            d = math.hypot(x - MOON[0], y - MOON[1])
            if d < MOON_R:
                p.px(x, y, "foam" if d < MOON_R - 3 or (x - MOON[0]) + (y - MOON[1]) < 0 else "farPale")
            elif d < MOON_R + 5 and BAYER[y % 4][x % 4] < 6:
                p.px(x, y, "nightSlate")
    for (x, y, r) in ((74, 54, 3), (60, 70, 4), (78, 70, 2)):
        p.mask(E(x, y, r, r * 0.8), "farPale")                       # its seas, one step down
    # far hills
    for (base, amp, col, rim) in ((100, 4, "nightSlate", "night2"), (110, 6, "nightBlue", "nightSlate")):
        for x in range(W):
            t = int(round(base - amp * abs(math.sin(x / 23.0 + base))))
            for y in range(t, H):
                p.px(x, y, col)
            p.px(x, t, rim)
    # the crag and the dead beacon: tower and empty iron basket black against the disc
    crag = P([(0, 132), (12, 122), (20, 110), (30, 104), (36, 94), (44, 91), (62, 90), (68, 96), (74, 98),
              (82, 110), (90, 114), (100, 128), (108, 134), (108, H), (0, H)])
    tower = P([(45, 92), (47, 54), (59, 54), (61, 92)])
    p.mask(crag | tower, "night0")
    for y, x in zip(*np.where(edge_of(crag | tower))):
        if not (crag | tower)[y - 1, x] and x < 50:
            p.px(x, y, "nightSlate")                                  # one cold tone on the tops toward the moon
    # the basket: a rim, bars with the moon between them, a dark floor
    for x in range(40, 67):
        p.px(x, 44, "night0"); p.px(x, 53, "night0"); p.px(x, 54, "night0")
    for x in range(40, 67, 4):
        for y in range(44, 54):
            p.px(x, y, "night0")
    for x in range(42, 65):
        p.px(x, 52, "night0")
    for x in (39, 67):
        for y in range(43, 55):
            p.px(x, y, "night0")
    # the near slope, west and down
    gm = np.zeros((H, W), bool)
    for x in range(W):
        gm[ground_y(x):, x] = True
    p.mask(gm, "nightDeep")
    for x in range(W):
        p.px(x, ground_y(x), "nightBlue")
    # the last warm window at the right edge
    p.mask(P([(300, 96), (W, 88), (W, 128), (300, 128)]), "nightDeep")
    p.mask(P([(296, 98), (308, 86), (W, 80), (W, 88), (300, 98)]), "night0")
    for (x, y, c) in ((308, 104, "fireGold"), (309, 104, "fireGold"), (308, 105, "fireOrange"), (309, 105, "fireOrange"),
                      (308, 106, "fireOrange"), (309, 106, "ember"), (308, 107, "ember"), (309, 107, "ember")):
        p.px(x, y, c)
    # a few short ember dashes on the ground under and before the horse: all that is left of his light down there
    g0 = ground_y(130)
    for (x, dy, n, c) in ((100, 2, 3, "emberDim"), (108, 1, 4, "ember"), (116, 3, 3, "emberDim"), (122, 1, 5, "tile"),
                          (130, 2, 3, "ember"), (138, 4, 2, "emberDim"), (112, 5, 2, "emberDim"), (146, 1, 3, "tile"),
                          (154, 3, 2, "emberDim")):
        for k in range(n):
            p.px(x + k, ground_y(x + k) + dy, c)
    # Aldric and his horse: one hand-set grid, about 60 px, walking west
    ox = 104
    oy = ground_y(130) - 58
    parts = grid_parts(RIDER, ox, oy, RIDER_LEGEND)
    # the moon first: one cold tone on his back, the cloak's top and the croup
    U = np.zeros((H, W), bool)
    for m, _ in parts:
        U |= m
    for y, x in zip(*np.where(U)):
        if not U[y - 1, x] and x > ox + 24:
            p.px(x, y, "nightSlate")
    for m, spec in parts:
        for y, x in zip(*np.where(m)):
            if p.get(x, y) != "nightSlate":
                p.px(x, y, spec[0])
    lamp = (ox + 7, oy + 6)
    light_grid(p, [(m & ~(np.roll(U, 1, 0) == False), spec) for m, spec in parts], lamp[0], lamp[1], depth=3)
    # his lantern: the small sister of the hall's lantern, hanging from the pole's hook, a small core glow
    core_glow(p, lamp[0], lamp[1] + 1, r=4, tones=("emberDim", "emberDim"))
    for r, row in enumerate(SMALL_LANTERN):
        for q, ch in enumerate(row):
            if ch != ".":
                p.px(lamp[0] - 3 + q, lamp[1] - 4 + r, {"i": "nightDeep", "b": "gold", "W": "fireWhite",
                                                      "F": "fireGold", "f": "fireOrange", "s": "straw"}[ch])
    return p


SMALL_LANTERN = ["...i...", "..iii..", ".bbbbs.", ".i.F.i.", ".iFWFi.", ".ifFfi.", ".bbbbs.", "..iii.."]


def _spans_to_rows(spans, width=60, height=60):
    rows = [["."] * width for _ in range(height)]
    for (r, a, b, ch) in spans:
        for c in range(a, b + 1):
            if 0 <= c < width:
                rows[r][c] = ch
    return ["".join(r) for r in rows]


# the rider and the horse, set span by span (row, first col, last col, region); walking west, the near foreleg
# reaching, the cloak one mass over the croup
_S = []
_S += [(1, 28, 31, "G"), (2, 27, 32, "H"), (3, 28, 32, "H"), (3, 27, 27, "F"), (4, 29, 32, "H"), (4, 27, 28, "F"),
       (5, 29, 31, "H"), (5, 28, 28, "F")]
_S += [(6, 27, 32, "R"), (7, 26, 33, "R"), (8, 25, 34, "R")] + [(r, 25, 34, "R") for r in range(9, 13)]
_S += [(r, 24, 35, "R") for r in range(13, 23)] + [(r, 23, 36, "R") for r in range(23, 27)]
_S += [(7, 24, 25, "A"), (8, 22, 24, "A"), (9, 20, 22, "A"), (10, 18, 20, "A"), (11, 16, 18, "F")]
for r, b in zip(range(7, 29), (35, 37, 38, 40, 41, 43, 44, 45, 46, 47, 48, 49, 50, 50, 51, 51, 52, 52, 52, 51, 50, 49)):
    a = 34 if r < 13 else (36 if r < 23 else (37 + (r - 23)))
    _S.append((r, max(a, 34), b, "C"))
_S += [(r, 27 + (r > 32), 31, "B") for r in range(27, 37)]
_S += [(10, 6, 7, "e"), (11, 5, 7, "e"), (12, 5, 8, "e")]
for r, (a, b) in zip(range(13, 24), ((4, 9), (3, 10), (2, 11), (1, 12), (0, 12), (0, 12), (0, 12), (1, 13), (3, 14),
                                     (6, 15), (8, 16))):
    _S.append((r, a, b, "N"))
for r, (a, b) in zip(range(14, 25), ((10, 12), (11, 13), (12, 14), (13, 15), (13, 16), (14, 17), (14, 18), (15, 19),
                                     (16, 20), (17, 21), (18, 22))):
    _S.append((r, a, b, "M"))
for r, (a, b) in zip(range(24, 31), ((10, 17), (11, 19), (12, 21), (13, 23), (14, 25), (14, 26), (15, 27))):
    _S.append((r, a, b, "N"))
for r, (a, b) in zip(range(27, 43), ((24, 40), (26, 44), (27, 46), (15, 48), (15, 50), (15, 51), (15, 52), (16, 52),
                                     (16, 52), (16, 52), (16, 52), (16, 52), (17, 52), (18, 51), (19, 50), (20, 49))):
    _S.append((r, a, b, "N"))
_S += [(43, 21, 30, "N"), (43, 40, 48, "N"), (44, 21, 26, "N"), (44, 42, 48, "N")]
for r, (a, b) in zip(range(29, 49), ((52, 54), (53, 55), (53, 56)) + tuple((54, 56) for _ in range(13)) +
                     ((54, 57), (55, 57), (55, 57), (56, 57))):
    _S.append((r, a, b, "T"))
for r, (a, b) in zip(range(44, 59), ((21, 23), (20, 22), (19, 21), (19, 21), (18, 20), (18, 20), (17, 19), (17, 19),
                                     (17, 19), (16, 18), (16, 18), (16, 18), (16, 18), (15, 18), (15, 18))):
    _S.append((r, a, b, "L"))
for r in range(44, 59):
    _S.append((r, 24 if r == 44 else 25, 28 if r == 58 else 27, "L"))
for r, (a, b) in zip(range(44, 59), ((44, 47), (45, 47), (46, 48), (46, 48), (47, 49), (46, 48), (45, 47), (45, 47),
                                     (45, 47), (45, 47), (45, 47), (45, 47), (45, 47), (45, 47), (44, 47))):
    _S.append((r, a, b, "L"))
for r, (a, b) in zip(range(44, 59), ((47, 49),) + tuple((48, 50) for _ in range(6)) + tuple((49, 51) for _ in range(7))
                     + ((49, 52),)):
    _S.append((r, a, b, "K"))
for k, (c, r) in enumerate(((15, 10), (14, 9), (13, 8), (12, 7), (11, 6), (10, 5), (9, 4), (8, 3), (7, 2), (7, 1))):
    _S.append((r, c, c, "P"))
RIDER = _spans_to_rows(_S)
RIDER_LEGEND = {"N": ("night0", "tileLight", "tile"), "M": ("night0", "tile", "plum"), "e": ("night0", "tile", "plum"),
                "L": ("night0", "tile", "plum"), "K": ("night0", "plum", "night0"), "T": ("night0", "plum", "night0"),
                "C": ("nightDeep", "tile", "plum"), "R": ("night0", "tileLight", "tile"), "B": ("night0", "tile", "plum"),
                "A": ("night0", "tileLight", "tile"), "F": ("crimsonDeep", "dawnRose", "tileLight"),
                "H": ("woodDark", "woodLight", "wood"), "G": ("gold", "fireGold", "gold"),
                "P": ("woodDark", "woodLight", "wood")}
