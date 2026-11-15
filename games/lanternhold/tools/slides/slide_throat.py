"""Slide 2 of the prologue: the founding (round 1 in the title's language, litkit.py). Captions it must fit: "For a
thousand years House Lantern has held it. / Nobody knows what waits on the other side." and the coming "Saint Taper
struck the Light from the bare rock. / For a thousand years House Lantern has kept the door." The bare cleft before
any castle: two huge dark rock faces with volume; low in the gap one small figure, the ancestor, his arm raised to the
rock; at his hand the first point of gold breaks out of the stone, its light climbs both faces and throws his long
shadow back east. West the dark recoils, a few eyes at its lip. One point of light in a great dark.
"""
import math

import numpy as np

from litkit import (W, H, Pic, AIR, STONE, air, eyes, falloff, lit_mass, pick_air, pick_solid, poly_mask, h,
                    edge_of)

LIGHT = (137, 104)        # the point of gold at his hand, on the left face
FLOOR = 138


def slide2():
    p = Pic("nightBlue")
    # the sky in the gap: night, a few stars, the light climbing into it
    gap = np.zeros((H, W), bool)
    gap[:FLOOR, :] = True
    for (x, y) in ((150, 10), (170, 26), (158, 44), (176, 8), (164, 62)):
        p.px(x, y, "moon")
    air(p, lambda x, y: "nightBlue" if (x, y) not in ((150, 10), (170, 26), (158, 44), (176, 8), (164, 62))
        else "moon", LIGHT[0] + 4, LIGHT[1] - 6, 46, 100, scale=4.4, g=1.6, mask=gap)
    # the two rock faces, huge, from the top edge to the floor
    left = poly_mask([(0, 0), (128, 0), (133, 22), (127, 50), (136, 78), (132, 112), (140, FLOOR), (0, FLOOR)])
    right = poly_mask([(186, 0), (W, 0), (W, FLOOR), (180, FLOOR), (187, 104), (179, 70), (189, 36), (183, 14)])
    for m, cold_dir in ((left, (-1, -1)), (right, (-1, -1))):
        p.mask(m, "nightDeep")
    # planes: big slabs, each with its own shade; joints between them
    for (pts, n) in (([(0, 0), (60, 0), (52, FLOOR), (0, FLOOR)], "night0"),
                     ([(60, 0), (98, 0), (92, 70), (84, FLOOR), (52, FLOOR)], "nightDeep"),
                     ([(98, 0), (128, 0), (133, 22), (127, 50), (120, 70), (92, 70)], "nightBlue"),
                     ([(92, 70), (120, 70), (136, 78), (132, 112), (140, FLOOR), (84, FLOOR)], "nightDeep"),
                     ([(186, 0), (230, 0), (226, 60), (232, FLOOR), (180, FLOOR), (187, 104), (179, 70),
                       (189, 36), (183, 14)], "nightDeep"),
                     ([(230, 0), (280, 0), (276, FLOOR), (232, FLOOR), (226, 60)], "night0"),
                     ([(280, 0), (W, 0), (W, FLOOR), (276, FLOOR)], "nightDeep")):
        p.mask(poly_mask(pts) & (left | right), n)
    for (pts) in (((60, 0), (52, FLOOR)), ((98, 0), (92, 70), (84, FLOOR)), ((92, 70), (120, 70)),
                  ((230, 0), (226, 60), (232, FLOOR)), ((280, 0), (276, FLOOR))):
        for (ax, ay), (bx, by) in zip(pts, pts[1:]):
            n = int(max(abs(bx - ax), abs(by - ay)))
            for k in range(n + 1):
                p.px(round(ax + (bx - ax) * k / n), round(ay + (by - ay) * k / n), "night0")
    # the light climbs both faces: the faces turned to it warm in solid steps, far up the rock
    # the light climbs both faces: each face's band toward the gap is a plane turned to the light, warm in solid
    # steps by distance, broad near the gap and fading into the rock
    # planes, not contours: each face is cut into three slabs by straight joints that jog every 18 rows; the slab
    # at the gap takes the light fully, the next half, the third a little, each in solid steps per block
    for y in range(FLOOR):
        blk = y // 18
        jog = int(round((h(blk, 0, 61) - 0.5) * 6))
        for x in range(W):
            if left[y, x]:
                cuts = (126 + jog, 112 + jog // 2)
                k = 1.0 if x >= cuts[0] else (0.5 if x >= cuts[1] else (0.18 if x >= 96 else 0))
            elif right[y, x]:
                cuts = (190 - jog, 206 - jog // 2)
                k = 1.0 if x <= cuts[0] else (0.5 if x <= cuts[1] else (0.16 if x <= 232 else 0))
            else:
                continue
            if k <= 0:
                continue
            t = falloff(x, y, LIGHT[0], LIGHT[1], 96, 150, 1.15)
            i = int(t * 6.6 * k)
            if i > 0:
                p.px(x, y, (["nightDeep"] + STONE)[min(6, i)])
        # the joints themselves, dark
        for q, jx in enumerate((126 + jog, 112 + jog // 2, 190 - jog, 206 - jog // 2)):
            if (left[y, jx] or right[y, jx]) and h(q, blk, 62) < 0.7:
                p.px(jx - (1 if jx < 160 else 0), y, "night0")
    # the slabs' joints catch a thin cold line on their left, so the rock has planes beyond the light
    for (pts) in (((60, 0), (52, FLOOR)), ((98, 0), (92, 70)), ((230, 0), (226, 60), (232, FLOOR)),
                  ((280, 0), (276, FLOOR))):
        for (ax, ay), (bx, by) in zip(pts, pts[1:]):
            n = int(max(abs(bx - ax), abs(by - ay)))
            for k in range(n + 1):
                x, y = round(ax + (bx - ax) * k / n) + 1, round(ay + (by - ay) * k / n)
                if p.get(x, y) in ("night0", "nightDeep"):
                    p.px(x, y, "nightBlue")
    # the cold sky on the faces' upper left edges
    for m in (left, right):
        e = edge_of(m) & ~np.roll(m, 1, 0)
        for y, x in zip(*np.where(e)):
            if p.get(x, y) in ("night0", "nightDeep", "nightBlue"):
                p.px(x, y, "nightSlate")
    # the floor of the gap: bare rock, lit near the light in solid steps; the dark to the west
    for y in range(FLOOR, H):
        for x in range(W):
            t = falloff((x // 6) * 6 + 3, y, LIGHT[0], LIGHT[1] + 30, 120, 44, 1.1)
            p.px(x, y, pick_solid(["nightDeep", "nightBlue"] + STONE[:4], t * 6.0))
        if y == FLOOR:
            for x in range(W):
                if p.get(x, y) == "nightDeep":
                    p.px(x, y, "nightBlue")
    # the ancestor: small, cloaked, his left arm raised to the rock, the hood back
    fig = [
        "...aa....",
        "..aaaa...",
        ".aaaaa...",
        "aaaaaa...",
        "aaaaaa...",
        ".aaaaa...",
        ".aaaaaa..",
        ".aaaaaa..",
        ".aaaaaaa.",
        ".aaaaaaa.",
        "aaaaaaaaa",
        "aaaaaaaaa",
        "aaaaaaaaa",
        ".aa...aa.",
        ".aa...aa."]
    fx, fy = 142, FLOOR - len(fig)
    fm = np.zeros((H, W), bool)
    for r, row in enumerate(fig):
        for q, ch in enumerate(row):
            if ch == "a":
                fm[fy + r, fx + q] = True
    for (x, y) in ((141, fy + 3), (140, fy + 2), (139, fy + 1), (139, fy), (138, fy - 1)):   # the raised arm
        fm[y, x] = True
    p.mask(fm, "night0")
    for y, x in zip(*np.where(edge_of(fm))):
        d = math.hypot(x - LIGHT[0], y - LIGHT[1])
        if (x - LIGHT[0]) * (x - fx - 4) <= 0 or y < fy + 5:
            p.px(x, y, "tileLight" if d < 12 else ("tile" if d < 20 else "plum"))
    # his long shadow back east, along the lit floor
    for y in range(FLOOR, FLOOR + 4):
        x0 = fx + 2 + (y - FLOOR) * 2
        for x in range(x0, x0 + 84 - (y - FLOOR) * 14):
            p.px(x, y, "nightDeep" if (y - FLOOR) < 2 else "nightBlue")
    # the point of gold breaking out of the rock at his hand, with a few sparks
    for (x, y, c) in ((138, 103, "fireWhite"), (137, 104, "fireWhite"), (136, 104, "fireWhite"), (137, 103, "fireWhite"),
                      (136, 103, "fireWhite"), (137, 102, "fireGold"), (138, 104, "fireWhite"), (139, 104, "fireGold"),
                      (138, 104, "fireGold"), (137, 105, "fireGold"), (135, 104, "fireOrange"), (137, 102, "fireOrange"),
                      (139, 103, "fireOrange"), (136, 105, "fireOrange"), (141, 100, "fireGold"), (133, 99, "fireGold"),
                      (143, 106, "fireOrange"), (139, 97, "fireOrange")):
        p.px(x, y, c)
    # the dark to the west, recoiling from the light: its front curved away, eyes at its lip
    dk = np.zeros((H, W), bool)
    for y in range(80, H):
        f = 66 + 22 * math.sin(max(0.0, (y - 80)) / 58.0 * math.pi * 0.5) - 10 * math.cos((y - 80) / 20.0)
        f += 3 * math.sin(y / 3.3)
        for x in range(0, int(f)):
            dk[y, x] = True
    p.mask(dk, "night0")
    eyes(p, [(62, 118, 2, 1, 3, 0, 1, "wraithWhite"), (74, 140, 1, 1, 3, 1, 1, "wraithGlow"),
             (40, 104, 1, 1, 2, 0, 1, "wraithDim"), (58, 150, 2, 1, 2, 0, 1, "wraithGlow"),
             (24, 130, 1, 1, 3, -1, 1, "wraithDim")], inside=dk)
    return p
