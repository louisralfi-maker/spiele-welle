"""Slide 1 of the prologue (round 2): "A wall of mountains parts the world. / It has one door." The game's side view,
wide: west the Gloom, flat dark with a few eye pairs; in the middle the Weltmauer, wide at the foot, leaning planes in
the night's stone tones, a jagged ridge leaving the frame's top, a cold rim on the slope that faces home, warm light
only on the two lips of the cleft; in the cleft our castle, the hero, with its own wall and gate across the cleft's
foot and the lantern tower above, its light the brightest thing; east the lit lands, a village in a cluster with a
chapel spire, field strips, few warm windows, a thin dawn on the horizon. Dark | one door | home.
"""
import math

import numpy as np

from litkit import (W, H, Pic, BAYER, core_glow, eyes, falloff, lit_figure, mountain, pick_air, poly_mask,
                    ellipse_mask, h)

BEACON = (161, 76)
HORIZON = 108
FOOT = 152


def poly(pts):
    def f(y):
        for (ya, xa), (yb, xb) in zip(pts, pts[1:]):
            if ya <= y <= yb:
                return xa + (xb - xa) * (y - ya) / float(yb - ya)
        return pts[-1][1]
    return f


def P(pts):
    return poly_mask(pts)


def house(p, x, base, w_, wall_h, roof_h, windows, col="nightBlue", roof="nightDeep"):
    for y in range(base - wall_h, base + 1):
        for xx in range(x, x + w_):
            p.px(xx, y, col)
    for d in range(roof_h):
        a, b = x - 1 + int(d * (w_ + 2) / (2.0 * roof_h)), x + w_ - int(d * (w_ + 2) / (2.0 * roof_h))
        for xx in range(a, b + 1):
            p.px(xx, base - wall_h - 1 - d, roof)
        p.px(a, base - wall_h - 1 - d, "nightSlate")
    for (dx, dy, c) in windows:
        p.px(x + dx, base - wall_h + dy, c)


def slide1():
    p = Pic("nightBlue")
    for (x, y) in ((22, 10), (58, 26), (90, 8), (40, 44), (236, 14), (262, 34), (300, 9), (284, 52), (226, 60)):
        p.px(x, y, "moon")
    for (x, y) in ((76, 16), (276, 22)):
        p.px(x, y, "foam")
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            p.px(x + dx, y + dy, "moon")
    # the east sky lightens toward the dawn, quietly; the dawn a thin line
    for y in range(30, HORIZON + 1):
        for x in range(200, W):
            t = falloff(x, y, 330, HORIZON, 150, 70, 1.1)
            p.px(x, y, pick_air(x, y, ["nightBlue", "nightSlate", "night2", "far"], t * 3.6))
    for x in range(214, W):
        p.px(x, HORIZON, "dawnRose" if x > 248 else "dusk")
        if x > 262:
            p.px(x, HORIZON - 1, "dusk")
    # the lit lands: low hills with field strips, the village in a cluster, smaller with distance
    for row, (base, amp, col, rim) in enumerate(((HORIZON + 4, 2, "nightHaze", "far"),
                                                  (HORIZON + 14, 4, "night2", "nightHaze"),
                                                  (HORIZON + 30, 6, "nightSlate", "night2"))):
        for x in range(196, W):
            t = int(round(base - amp * abs(math.sin(x / (21.0 + row * 7) + row))))
            for y in range(t, H):
                p.px(x, y, col)
            p.px(x, t, rim)
    for (x0, x1, y, c) in ((262, 300, HORIZON + 8, "far"), (270, 318, HORIZON + 11, "nightHaze"),
                           (232, 262, HORIZON + 20, "nightHaze"), (290, 320, HORIZON + 22, "nightHaze"),
                           (300, 320, HORIZON + 26, "far")):
        for x in range(x0, x1):
            p.px(x, y, c)                                              # field strips
    for (ax, ay), (bx, by) in zip([(188, FOOT), (206, 148), (222, 142), (236, 136)],
                                  [(206, 148), (222, 142), (236, 136), (246, 132)]):
        n = max(abs(bx - ax), 1)
        for k in range(n + 1):
            x = ax + k
            y = int(round(ay + (by - ay) * k / n))
            p.px(x, y, "mistDark"); p.px(x, y + 1, "mistDark" if x < 220 else "far")
    # the village: a long house, two gabled houses, a small barn, the chapel spire; few warm windows
    house(p, 240, 134, 13, 6, 4, [(3, 3, "fireOrange"), (9, 3, "fireGold")])
    house(p, 255, 131, 7, 6, 4, [(3, 2, "fireOrange")])
    house(p, 264, 129, 9, 5, 3, [])
    house(p, 276, 126, 5, 4, 3, [(2, 2, "ember")])
    house(p, 288, 123, 4, 3, 2, [])
    for y in range(110, 133):                                          # the chapel and its spire
        for x in range(250, 254):
            p.px(x, y, "nightBlue" if x < 253 else "nightDeep")
    for d in range(10):
        p.px(251 + (1 if d < 6 else 0), 109 - d, "nightDeep")
        if d < 6:
            p.px(251, 109 - d, "nightDeep"); p.px(253, 109 - d, "nightDeep")
    p.px(252, 98, "nightSlate")
    p.px(251, 118, "fireGold")
    # the west: the Gloom, flat dark, a few pale eyes
    gl = np.zeros((H, W), bool)
    for x in range(0, 120):
        t = int(round(86 + 3 * math.sin(x / 13.0) + 2 * math.sin(x / 5.0)))
        gl[t:, x] = True
    p.mask(gl, "night0")
    eyes(p, [(18, 112, 2, 1, 3, 0, 1, "wraithGlow"), (44, 98, 1, 1, 2, 1, 1, "wraithDim"),
             (70, 126, 2, 1, 4, 0, 1, "wraithGlow"), (92, 104, 1, 1, 3, 0, 1, "wraithDim"),
             (34, 140, 1, 1, 2, -1, 1, "wraithDim")], inside=gl)
    # the Weltmauer: wide at the foot, the jagged ridge leaving the top, one cleft
    outer_l = poly([(0, 122), (12, 116), (20, 119), (36, 108), (48, 111), (66, 100), (80, 103), (104, 92), (122, 94),
                    (H, 76)])
    inner_l = poly([(0, 148), (40, 147), (41, 145), (90, 144), (91, 142), (H, 140)])
    inner_r = poly([(0, 174), (36, 175), (37, 177), (86, 178), (87, 180), (H, 183)])
    outer_r = poly([(0, 198), (14, 206), (24, 203), (42, 214), (54, 211), (74, 224), (88, 221), (110, 234),
                    (H, 248)])
    mountain(p, outer_l, inner_l, inner_r, outer_r, facets_l=[(130, 100)], facets_r=[(186, 214)],
             light=BEACON, reach=48, lip=7)
    for (x0, y0, x1, y1) in ((112, 30, 118, 50), (124, 90, 130, 106), (196, 40, 202, 60), (204, 100, 210, 118)):
        n = max(abs(x1 - x0), abs(y1 - y0))
        for k in range(n + 1):
            p.px(round(x0 + (x1 - x0) * k / n), round(y0 + (y1 - y0) * k / n), "night0")
    # the cleft's sky behind the castle: dark, a little lighter at the foot (the east beyond)
    for y in range(0, FOOT):
        a, b = int(inner_l(y)), int(inner_r(y))
        for x in range(a, b + 1):
            if p.get(x, y) == "nightBlue" and y > 60 and BAYER[y % 4][x % 4] < 4:
                p.px(x, y, "nightSlate")
    # our castle across the cleft's foot: its wall and gate from lip to lip, two towers, the lantern tower above
    wall = P([(134, 124), (188, 124), (188, H), (134, H)])
    merl = np.zeros((H, W), bool)
    for x in range(134, 189, 4):
        merl[121:124, x:x + 2] = True
    tl = P([(137, 108), (146, 108), (146, H), (137, H)])
    tr = P([(176, 108), (185, 108), (185, H), (176, H)])
    roofs = P([(135, 108), (148, 108), (141.5, 98)]) | P([(174, 108), (187, 108), (180.5, 98)])
    keep = P([(154, 86), (168, 86), (168, H), (154, H)])
    kmerl = np.zeros((H, W), bool)
    for x in range(153, 170, 4):
        kmerl[83:86, x:x + 2] = True
    # each body lit on its own, so the towers and the keep stand off the wall by their lit planes
    for parts in ([(wall, "nightBlue"), (merl, "nightBlue")], [(tl, "nightSlate"), (roofs & (np.arange(W)[None, :] < 160),
                  "roofDeep")], [(tr, "nightBlue"), (roofs & (np.arange(W)[None, :] > 160), "roofDeep")],
                  [(keep, "nightSlate"), (kmerl, "nightSlate")]):
        lit_figure(p, parts, BEACON[0], BEACON[1], near=40, depth=3, tones_near=("tileLight", "tile"),
                   tones_far=("tile", "plum"), lit_part={"roofDeep": ("tile", "plum")})
    for y in range(124, 152):                                          # the dark seam where the towers meet the wall
        p.px(147, y, "night0"); p.px(175, y, "night0")
    for y in range(90, 152):
        p.px(169, y, "night0")                                         # the keep's shadow side
    # the gate: a dark arch with a warm slit; a few windows
    gate = P([(157, H), (157, 140), (159, 137), (163, 137), (165, 140), (165, H)])
    p.mask(gate, "night0")
    for y in range(141, 150):
        p.px(161, y, "ember" if y > 143 else "emberDim")
    for y in range(FOOT, H):                                           # the cleft's floor before the gate
        for x in range(128, 196):
            p.px(x, y, "nightDeep")
    for (x, y) in ((141, 114), (180, 114), (160, 96), (163, 108), (148, 132), (174, 134)):
        p.px(x, y, "fireOrange"); p.px(x, y + 1, "ember")
    # the beacon: an iron cage on the lantern tower, the fire white, a small core glow: the brightest thing
    core_glow(p, BEACON[0], BEACON[1], r=9, tones=("fireOrange", "emberDim"))
    for y in range(71, 82):
        p.px(157, y, "nightDeep"); p.px(165, y, "nightDeep")
    for x in range(157, 166):
        p.px(x, 70, "nightDeep"); p.px(x, 82, "nightDeep")
    p.px(161, 69, "nightDeep"); p.px(161, 68, "nightDeep")
    for (x, y, c) in ((160, 77, "fireWhite"), (161, 77, "fireWhite"), (162, 77, "fireWhite"), (161, 76, "fireWhite"),
                      (160, 76, "fireGold"), (162, 76, "fireGold"), (161, 75, "fireWhite"), (161, 74, "fireGold"),
                      (160, 78, "fireGold"), (161, 78, "fireWhite"), (162, 78, "fireGold"), (159, 77, "fireGold"),
                      (163, 77, "fireGold"), (161, 73, "fireOrange"), (159, 78, "fireOrange"), (163, 78, "fireOrange"),
                      (160, 79, "fireOrange"), (161, 79, "fireGold"), (162, 79, "fireOrange")):
        p.px(x, y, c)
    for y in range(71, 82):
        p.px(159, y, "nightDeep"); p.px(163, y, "nightDeep")
    return p
