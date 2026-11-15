"""Slide 3 of the prologue: "This autumn the Great Beacon went dark. / Lord Aldric rode out to light it. He did not
come back." (round 1 in the title's language, litkit.py). The beacon tower stands unlit and black on its crag
against a cold moon whose glow is dithered, never banded. The rider is the subject: a third of the picture's height,
his lantern's pool the warmest spot, horse and cloak one strong silhouette with a lit edge. Four small bearers follow
him down into the dark. He rides west, to the left, away from the last warm window at the right edge.
"""
import math

import numpy as np

from litkit import (W, H, Pic, AIR, COLD, air, falloff, pick_air, pick_solid, poly_mask, ellipse_mask, edge_of, h)

MOON = (54, 38)
LAMP = (124, 92)           # the rider's lantern


def ground_y(x):
    return int(round(140 - (x - 150) * 0.12 + 1.5 * math.sin(x / 9.0)))


def slide3():
    p = Pic("nightBlue")
    # the moon's cold glow, dithered in the 60 % steps, never banded
    air(p, lambda x, y: "nightBlue", MOON[0], MOON[1], 90, 64, scale=4.6, g=1.5,
        ramp=["nightSlate", "night2", "nightHaze", "far", "moon"])
    for (x, y) in ((150, 12), (196, 30), (238, 10), (272, 44), (300, 18), (180, 56), (226, 66), (120, 20)):
        if falloff(x, y, MOON[0], MOON[1], 90, 64) == 0:
            p.px(x, y, "moon")
    p.mask(ellipse_mask(MOON[0], MOON[1], 9.5, 9.5), "farPale")
    p.mask(ellipse_mask(MOON[0] + 1.5, MOON[1] + 1.5, 7, 7), "foam")
    for (x, y) in ((51, 35), (56, 41), (58, 34)):
        p.px(x, y, "farPale")
    # far hills in the cold, two rows
    for (base, amp, col, rim) in ((100, 4, "nightSlate", "night2"), (110, 6, "nightBlue", "nightSlate")):
        for x in range(W):
            t = int(round(base - amp * abs(math.sin(x / 23.0 + base))))
            for y in range(t, H):
                p.px(x, y, col)
            p.px(x, t, rim)
    # the crag and the dark beacon tower, black against the moon
    crag = poly_mask([(0, 132), (12, 122), (20, 110), (30, 104), (36, 94), (44, 91), (62, 90), (68, 96), (74, 98),
                      (82, 110), (90, 114), (100, 128), (108, 134), (108, H), (0, H)])
    tower = poly_mask([(45, 92), (47, 52), (59, 52), (61, 92)])
    bowl = poly_mask([(41, 46), (65, 46), (62, 53), (44, 53)])
    tm = crag | tower | bowl
    p.mask(tm, "night0")
    for y, x in zip(*np.where(edge_of(tm))):
        if not tm[y - 1, x] and x < 62:
            p.px(x, y, "nightSlate")                       # the moon's thin rim on its tops
    for y in range(56, 90, 8):
        p.px(52, y, "nightDeep"); p.px(53, y, "nightDeep")
    # the near slope he rides down, west
    gm = np.zeros((H, W), bool)
    for x in range(W):
        gm[ground_y(x):, x] = True
    p.mask(gm, "nightDeep")
    for x in range(W):
        p.px(x, ground_y(x), "nightBlue")
    # the last warm window, at the right edge: the corner of a house
    house = poly_mask([(300, 96), (W, 88), (W, 128), (300, 128)])
    roof = poly_mask([(296, 98), (308, 86), (W, 80), (W, 88), (300, 98)])
    p.mask(house, "nightDeep")
    p.mask(roof, "night0")
    for (x, y, c) in ((308, 104, "fireGold"), (309, 104, "fireGold"), (308, 105, "fireOrange"), (309, 105, "fireOrange"),
                      (308, 106, "fireOrange"), (309, 106, "ember"), (308, 107, "ember"), (309, 107, "ember")):
        p.px(x, y, c)
    # four small bearers following him down, each a dim point of light
    for (x, hgt) in ((200, 10), (222, 9), (246, 9), (270, 8)):
        g = ground_y(x)
        fm = ellipse_mask(x, g - hgt + 1.5, 1.6, 1.6) | poly_mask([(x - 2, g - hgt + 3), (x + 2, g - hgt + 3),
                                                                   (x + 3, g), (x - 3, g)])
        p.mask(fm, "night0")
        p.px(x - 3, g - hgt + 3, "fireOrange"); p.px(x - 3, g - hgt + 4, "ember")
        p.px(x - 3, g - hgt + 2, "woodDark")
    # the lantern's pool on the ground ahead of him: the warmest spot
    for y in range(100, H):
        for x in range(60, 200):
            if not gm[y, x]:
                continue
            t = falloff(x, y, 126, ground_y(126) + 2, 56, 14, 1.2)
            if t > 0:
                p.px(x, y, pick_air(x, y, ["nightDeep", "plumDeep", "plum", "tile", "tileLight", "gold"], t * 5.6))
    air(p, lambda x, y: p.get(x, y), LAMP[0], LAMP[1], 26, 22, scale=4.4, g=1.6, mask=~gm,
        ramp=["plum", "dusk", "tileLight", "gold", "fireGold"])
    # Aldric: horse, rider, cloak and lantern pole, one silhouette, riding left
    g = ground_y(150)
    sil = (ellipse_mask(153, g - 22, 17, 9)                                     # the horse's body
           | ellipse_mask(141, g - 24, 7, 8)                                   # its chest
           | poly_mask([(140, g - 26), (146, g - 28), (136, g - 40), (130, g - 42), (128, g - 38)])   # neck
           | poly_mask([(127, g - 44), (133, g - 44), (134, g - 39), (126, g - 33), (121, g - 35)])   # head
           | poly_mask([(130, g - 45), (132, g - 48), (133, g - 44)])            # ear
           | poly_mask([(164, g - 26), (168, g - 24), (172, g - 12), (168, g - 10)])                  # tail
           | poly_mask([(146, g - 52), (156, g - 52), (158, g - 30), (144, g - 30)])                  # the rider
           | ellipse_mask(151, g - 55, 3.2, 3.6)                                 # his head
           | poly_mask([(154, g - 51), (172, g - 44), (180, g - 30), (174, g - 26), (158, g - 32)]))  # the cloak
    for (x0, y0, x1, y1) in ((141, g - 16, 137, g - 8), (137, g - 8, 134, g - 6), (145, g - 16, 145, g),
                             (159, g - 16, 157, g), (163, g - 17, 165, g)):          # legs, one front leg lifted
        n = max(abs(x1 - x0), abs(y1 - y0))
        for k in range(n + 1):
            x = round(x0 + (x1 - x0) * k / n)
            y = round(y0 + (y1 - y0) * k / n)
            sil[y, x] = True
            sil[y, x + 1] = True
            if k < n * 0.5:
                sil[y, x + 2] = True
    for k in range(26):                                                           # the lantern pole, forward
        sil[round(g - 44 - k * 0.55), round(146 - k * 0.85)] = True
    p.mask(sil, "night0")
    # the lit edge: warm where it faces his lantern, cold on top where it faces the moon
    for y, x in zip(*np.where(edge_of(sil))):
        d = math.hypot(x - LAMP[0], y - LAMP[1])
        if x < 150 or d < 22:
            if not sil[y, x - 1] or not sil[y - 1, x] or not sil[y + 1, x]:
                p.px(x, y, "gold" if d < 12 else ("tileLight" if d < 22 else ("tile" if d < 34 else "plum")))
        elif not sil[y - 1, x]:
            p.px(x, y, "nightSlate")
    p.px(149, g - 56, "gold")                                                     # the circlet's glint
    # the lantern itself
    for (x, y, c) in ((LAMP[0], LAMP[1] - 3, "nightDeep"), (LAMP[0] - 1, LAMP[1] - 2, "nightDeep"),
                      (LAMP[0] + 1, LAMP[1] - 2, "nightDeep"), (LAMP[0] - 1, LAMP[1] - 1, "fireGold"),
                      (LAMP[0], LAMP[1] - 1, "fireWhite"), (LAMP[0] + 1, LAMP[1] - 1, "fireGold"),
                      (LAMP[0] - 1, LAMP[1], "fireOrange"), (LAMP[0], LAMP[1], "fireWhite"),
                      (LAMP[0] + 1, LAMP[1], "fireOrange"), (LAMP[0], LAMP[1] + 1, "nightDeep")):
        p.px(x, y, c)
    return p
