"""Slide 1 of the prologue: "A wall of mountains parts the world. / It has one door." (round 1 in the title's
language, litkit.py). The game's own side view, wide: west the Gloom, flat dark with a few eye pairs; in the middle one
black mountain wall from the bottom edge to the top edge with a single cleft, our castle in it, its light the
brightest thing; east the lit lands, a road, warm windows, a thin dawn on the horizon. Reads: dark | door | home.
"""
import math

import numpy as np

from litkit import (W, H, Pic, AIR, STONE, air, bands, eyes, falloff, lit_mass, pick_air, pick_solid, poly_mask,
                    h, edge_of)

LIGHT = (161, 94)
HORIZON = 106


def wall_edges(y):
    l = 106 + int(4 * math.sin(y / 9.0) + 3 * math.sin(y / 3.7))
    r = 214 + int(4 * math.sin(y / 11.0 + 1) + 3 * math.sin(y / 4.1))
    return l, r


def cleft(y):
    return 145 + int(5 * y / 160.0) + (1 if (y // 7) % 3 == 0 else 0), 177 - int(5 * y / 160.0)


def slide1():
    p = Pic()
    sky = bands([(0, "nightBlue")], mix=24)
    for y in range(H):
        for x in range(W):
            p.px(x, y, sky(x, y))
    # stars, placed, few, small
    for (x, y) in ((22, 10), (58, 26), (90, 8), (236, 14), (262, 34), (300, 9), (284, 52), (40, 44), (226, 60)):
        p.px(x, y, "moon")
    for (x, y) in ((76, 16), (276, 22)):
        p.px(x, y, "foam")
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            p.px(x + dx, y + dy, "moon")
    # the east: the sky lighter toward the dawn, the dawn a thin band on the horizon
    for y in range(30, HORIZON + 1):
        for x in range(200, W):
            t = falloff(x, y, 330, HORIZON, 150, 70, 1.1)
            p.px(x, y, pick_air(x, y, [sky(x, y), "nightSlate", "night2", "far"], t * 3.6))
    for x in range(222, W):
        p.px(x, HORIZON, "dawnRose" if x > 250 else "dusk")
        if x > 262:
            p.px(x, HORIZON - 1, "dusk")
    # the lit lands: three rows of low hills, a road, houses with warm windows
    for row, (base, amp, col, rim) in enumerate(((HORIZON + 4, 3, "nightHaze", "far"),
                                                  (HORIZON + 14, 5, "night2", "nightHaze"),
                                                  (HORIZON + 30, 7, "nightSlate", "night2"))):
        for x in range(200, W):
            t = int(round(base - amp * abs(math.sin(x / (17.0 + row * 6) + row))))
            for y in range(t, H):
                p.px(x, y, col)
            p.px(x, t, rim)
    road = [(178, 152), (196, 148), (214, 146), (232, 140), (246, 134), (262, 128), (280, 121), (296, 115),
            (310, 110), (320, 108)]
    for (ax, ay), (bx, by) in zip(road, road[1:]):
        n = max(abs(bx - ax), 1)
        for k in range(n + 1):
            x = ax + k
            y = int(round(ay + (by - ay) * k / n))
            w_ = 3 if x < 240 else (2 if x < 280 else 1)
            for dy in range(w_):
                p.px(x, y + dy, "mistDark" if x < 250 else "far")
    for (x, y, w_) in ((222, 138, 7), (238, 132, 6), (252, 126, 5), (268, 122, 5), (288, 114, 4), (300, 112, 3)):
        for yy in range(y - 4, y + 1):
            for xx in range(x, x + w_):
                p.px(xx, yy, "nightBlue")
        for d in range((w_ + 3) // 2):
            for xx in range(x - 1 + d, x + w_ + 1 - d):
                p.px(xx, y - 5 - d, "nightDeep")
        p.px(x + 1, y - 2, "fireOrange")
        if w_ >= 5:
            p.px(x + w_ - 2, y - 2, "fireGold")
    # the west: the Gloom, flat dark, a few pale eyes
    gl = np.zeros((H, W), bool)
    for x in range(0, 130):
        t = int(round(84 + 3 * math.sin(x / 13.0) + 2 * math.sin(x / 5.0)))
        gl[t:, x] = True
    p.mask(gl, "night0")
    eyes(p, [(18, 112, 2, 1, 3, 0, 1, "wraithGlow"), (44, 98, 1, 1, 2, 1, 1, "wraithDim"),
             (70, 126, 2, 1, 4, 0, 1, "wraithGlow"), (92, 104, 1, 1, 3, 0, 1, "wraithDim"),
             (34, 140, 1, 1, 2, -1, 1, "wraithDim")], inside=gl)
    # the wall: one black mass from the bottom edge to the top edge, the cleft through it
    wm = np.zeros((H, W), bool)
    for y in range(H):
        l, r = wall_edges(y)
        a, b = cleft(y)
        wm[y, l:a] = True
        wm[y, b:r + 1] = True
    p.mask(wm, "nightDeep")
    # its planes: buttresses that catch the sky on their upper left, in two solid steps
    for (x0, y0, x1, y1, w_) in ((108, 0, 120, 160, 6), (124, 0, 134, 92, 4), (130, 70, 138, 160, 4),
                                 (180, 0, 190, 70, 5), (184, 50, 196, 160, 6), (200, 0, 206, 110, 4)):
        pm = poly_mask([(x0, y0), (x0 + w_, y0), (x1 + w_, y1), (x1, y1)]) & wm
        p.mask(pm, "nightBlue")
        p.mask(edge_of(pm) & ~np.roll(pm, 1, 1), "nightSlate")
    # the cleft's inner faces turned to the light: the warm ramp in solid steps
    inner = np.zeros((H, W), bool)
    for y in range(H):
        a, b = cleft(y)
        inner[y, a - 9:a] = True
        inner[y, b:b + 9] = True
    lit_mass(p, inner & wm, "nightDeep", LIGHT[0], LIGHT[1], 60, 84, k_face=0.35, depth=4, quant=4)
    # the air in the cleft glows: the brightest thing in the picture
    cm = np.zeros((H, W), bool)
    for y in range(H):
        a, b = cleft(y)
        cm[y, a:b] = True
    air(p, lambda x, y: p.get(x, y), LIGHT[0], LIGHT[1], 40, 64, mask=cm)
    # the cleft's floor under the castle: rock
    for y in range(150, H):
        a, b = cleft(y)
        for x in range(a, b):
            p.px(x, y, "nightDeep")
    # our castle across the cleft: the wall, two towers, the keep and its beacon (crisp shapes, lit faces)
    a, b = cleft(126)
    cast = np.zeros((H, W), bool)
    cast[124:152, a - 1:b + 1] = True
    for x in range(a - 1, b + 1, 3):
        cast[122:124, x:x + 2] = True
    cast[112:152, a:a + 7] = True
    cast[112:152, b - 7:b] = True
    for (x0, x1) in ((a, a + 6), (b - 7, b - 1)):
        cx = (x0 + x1) / 2.0
        for d in range(5):
            cast[107 + d, int(round(cx - d * 0.8)):int(round(cx + d * 0.8)) + 1] = True
    cast[99:152, 155:168] = True
    for x in range(155, 168, 3):
        cast[97:99, x:x + 2] = True
    lit_mass(p, cast, "nightDeep", LIGHT[0], LIGHT[1], 34, 44, k_face=0.18, depth=2, quant=3, ramp=["nightBlue"] + STONE)
    for (x, y) in ((a + 3, 116), (b - 4, 116), (158, 104), (164, 110), (160, 120)):
        p.px(x, y, "fireOrange"); p.px(x, y + 1, "ember")
    # the beacon on the keep: a small iron cage, the fire white at its heart
    for y in range(90, 97):
        p.px(158, y, "nightDeep"); p.px(164, y, "nightDeep")
    for x in range(158, 165):
        p.px(x, 89, "nightDeep"); p.px(x, 97, "nightDeep")
    p.px(161, 88, "nightDeep")
    for (x, y, c) in ((160, 95, "fireGold"), (161, 95, "fireWhite"), (162, 95, "fireGold"), (161, 94, "fireWhite"),
                      (160, 94, "fireWhite"), (162, 94, "fireGold"), (161, 93, "fireWhite"), (161, 92, "fireGold"),
                      (160, 96, "fireOrange"), (161, 96, "fireGold"), (162, 96, "fireOrange"), (159, 95, "fireGold"),
                      (163, 95, "fireOrange"), (161, 91, "fireOrange"), (159, 94, "fireOrange"), (163, 94, "fireGold")):
        p.px(x, y, c)
    # the light spills out of the door onto the ground on both sides, a short warm tongue
    for y in range(148, H):
        for x in range(a - 26, b + 26):
            ca, cb = cleft(y)
            if wm[y, x] or cast[y, x] or ca <= x < cb:
                continue
            t = falloff(x, y, LIGHT[0], 152, 34, 12, 1.2)
            if t > 0:
                p.px(x, y, pick_air(x, y, [p.get(x, y), "plumDeep", "plum", "tile"], t * 3.4))
    return p
