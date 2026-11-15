"""Slide 3 of the prologue (round 2): "This autumn the Great Beacon went dark. / Lord Aldric rode out to light it. He
did not come back." A moon of 42 px, its centre low and off the tower's axis, so the beacon's empty iron basket
stands black inside the disc: a dead beacon, not a lamp. Aldric rides west, a third of the picture's height: horse
and rider dark masses (barrel, neck, head, legs in stride, the cloak one mass), his lantern lighting the horse's neck
and chest and his own front in planes, the moon one cold tone on his back and the croup. Four bearers, 15 px each,
follow him down. The last warm window at the right edge. The light is seen on what it hits (rule A, rule B).
"""
import math

import numpy as np

from litkit import (W, H, Pic, BAYER, core_glow, falloff, lit_figure, poly_mask, ellipse_mask, edge_of, h)

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
    # the lantern's pool on the ground's own planes: two steps, broken by tufts and a rut, a dithered edge
    for y in range(110, H):
        for x in range(50, 210):
            if not gm[y, x]:
                continue
            t = falloff(x, y, 120, ground_y(120) + 3, 52, 13, 1.0)
            rut = abs((y - ground_y(x)) - 5 - (x - 120) * 0.03) < 0.8
            c = "tile" if t > 0.5 else ("plum" if t > 0.18 else None)
            if c is None:
                if t > 0.08 and BAYER[y % 4][x % 4] < 6:
                    c = "plumDeep"
                else:
                    continue
            p.px(x, y, "plumDeep" if rut and c else c)
    # four bearers, 15 px each, hooded, each with a pole and its dim light, going down behind him
    for (x, hgt, carry) in ((196, 16, "pole"), (220, 15, "sack"), (244, 15, "pole"), (268, 14, "sack")):
        g = ground_y(x)
        body = P([(x - 3, g - hgt + 6), (x + 3, g - hgt + 6), (x + 5, g), (x - 5, g)])
        hood = P([(x - 3, g - hgt + 6), (x - 2, g - hgt + 1), (x + 1, g - hgt), (x + 3, g - hgt + 3), (x + 3, g - hgt + 6)])
        parts = [(body, "night0"), (hood, "night0")]
        if carry == "sack":
            parts.append((E(x + 4, g - hgt + 6, 3.5, 3), "nightDeep"))
        lit_figure(p, parts, LAMP[0], LAMP[1], depth=2, tones_near=("nightSlate", "nightBlue"),
                   tones_far=("nightSlate", "nightBlue"))
        if carry == "pole":
            for k in range(8):
                p.px(x - 3 - k // 2, g - hgt + 7 - k, "woodDark")
            p.px(x - 7, g - hgt - 2, "fireOrange"); p.px(x - 7, g - hgt - 1, "ember")
    # Aldric: horse and rider as masses
    g = ground_y(150)
    barrel = E(154, g - 24, 15, 8)
    chest = E(140, g - 25, 7, 8)
    croup = E(167, g - 25, 8, 8.5)
    neck = P([(135, g - 30), (145, g - 28), (137, g - 44), (130, g - 47), (127, g - 41)])
    head = P([(126, g - 49), (133, g - 50), (135, g - 45), (128, g - 37), (121, g - 38), (121, g - 42)])
    ear = P([(130, g - 49), (132, g - 54), (134, g - 49)])
    tail = P([(173, g - 29), (177, g - 27), (181, g - 12), (177, g - 10), (174, g - 18)])
    legs = np.zeros((H, W), bool)
    leg(legs, [(138, g - 19), (131, g - 9), (133, g)], 3)           # the near foreleg reaching
    leg(legs, [(145, g - 18), (147, g - 9), (145, g)], 2)
    leg(legs, [(161, g - 19), (167, g - 9), (164, g)], 3)
    leg(legs, [(169, g - 18), (174, g - 8), (176, g)], 2)
    rider = P([(146, g - 54), (156, g - 54), (159, g - 34), (144, g - 34)])
    rhead = E(150.5, g - 58, 3.6, 4)
    arm = P([(145, g - 50), (149, g - 49), (139, g - 44), (137, g - 47)])
    cloak = P([(153, g - 55), (166, g - 50), (180, g - 36), (183, g - 30), (172, g - 28), (157, g - 34)])
    horse = [(tail, "night0"), (legs, "night0"), (barrel, "night0"), (croup, "night0"), (chest, "night0"),
             (neck, "night0"), (head, "night0"), (ear, "night0"), (cloak, "night0"), (rider, "night0"),
             (arm, "night0"), (rhead, "crimsonDeep")]
    # the moon first: one cold tone on his back and the croup (tops turned up and back)
    lit_figure(p, horse, MOON[0] + 140, MOON[1] - 200, depth=2, tones_near=("nightSlate", "nightSlate"),
               tones_far=("nightSlate", "nightSlate"), near=1, lit_part={"crimsonDeep": ("nightSlate", "nightSlate")})
    # then his lantern: the horse's neck and chest, his front, in two warm tones, 2 to 3 px
    U = np.zeros((H, W), bool)
    for m, _ in horse:
        U |= m
    for y, x in zip(*np.where(U)):
        d = math.hypot(x - LAMP[0], y - LAMP[1]) or 1.0
        if d > 44:
            continue
        vx, vy = (LAMP[0] - x) / d, (LAMP[1] - y) / d
        for k in (1, 2, 3):
            qx, qy = int(round(x + vx * k)), int(round(y + vy * k))
            if not U[qy, qx]:
                p.px(x, y, ("tileLight" if d < 24 else "tile") if k == 1 else ("tile" if d < 24 else "plum"))
                break
    p.px(149, g - 61, "gold")                                        # the circlet's glint
    for k in range(18):                                              # the lantern pole, forward and up
        p.px(round(138 - k * 0.85), round(g - 46 - k * 0.6), "woodDark")
    core_glow(p, LAMP[0], LAMP[1], r=7, tones=("fireOrange", "emberDim"), keep=("woodDark",))
    for (x, y, c) in ((LAMP[0], LAMP[1] - 3, "nightDeep"), (LAMP[0] - 1, LAMP[1] - 2, "nightDeep"),
                      (LAMP[0] + 1, LAMP[1] - 2, "nightDeep"), (LAMP[0] - 1, LAMP[1] - 1, "fireGold"),
                      (LAMP[0], LAMP[1] - 1, "fireWhite"), (LAMP[0] + 1, LAMP[1] - 1, "fireGold"),
                      (LAMP[0] - 1, LAMP[1], "fireGold"), (LAMP[0], LAMP[1], "fireWhite"),
                      (LAMP[0] + 1, LAMP[1], "fireGold"), (LAMP[0], LAMP[1] + 1, "nightDeep")):
        p.px(x, y, c)
    return p
