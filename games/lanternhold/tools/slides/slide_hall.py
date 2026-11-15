"""Slide 4 of the prologue: "The circlet passed to the last of his blood." (round 2; HOUSE.md section 1: the heir of
the guardian house, never a lamplighter). The hall at night, lit only by the house's great lantern. The hand-over is
the picture: the heir a little left of centre, three-quarter back; past the heir's shoulder Odile, slight and old,
bent forward from the hip, both arms out, the circlet in both hands, the brightest thing after the flame. The court
by silhouette: Brannock broad and bearded with the spear's shaft in his fist, Pip half as tall in the two-horned cap,
Bram wide with bare forearms over the apron. Two backs in front. The light is seen on what it hits (rule A); people
are dark masses with lit planes on the side toward the lantern, no outline (rule B). Lord and Lady differ in the
whole silhouette.
"""
import math

import numpy as np

from litkit import (W, H, Pic, BAYER, core_glow, falloff, lit_figure, poly_mask, ellipse_mask, h)

LANTERN = (160, 34)
FLOOR = 148


def wall_and_floor(p):
    """The back wall dark; a soft fan of light in two steps under the lantern, courses drawn only where it is lit.
    The floor's flagstones take the pool in solid steps per stone."""
    for y in range(FLOOR):
        row = y // 9
        off = 8 if row % 2 else 0
        for x in range(W):
            bx = (x + off) // 18
            t = falloff(bx * 18 - off + 9, row * 9 + 4.5, LANTERN[0], LANTERN[1] + 24, 80, 92, 1.2)
            step = 2 if t > 0.55 else (1 if t > 0.22 else 0)
            c = ("night0", "plumDeep", "plum")[step]
            if step and y % 9 == 8 and h(x // 7, row, 3) < 0.55:
                c = ("night0", "night0", "plumDeep")[step]        # a few courses, only where it is lit
            p.px(x, y, c)
    for y in range(FLOOR, H):
        row = (y - FLOOR) // 4
        off = 11 if row % 2 else 0
        for x in range(W):
            bx = (x + off) // 22
            t = falloff(bx * 22 - off + 11, y, 156, FLOOR + 2, 96, 16, 1.1)
            step = 3 if t > 0.55 else (2 if t > 0.3 else (1 if t > 0.1 else 0))
            c = ("night0", "plumDeep", "plum", "tile")[step]
            if step and ((y - FLOOR) % 4 == 3 or (x + off) % 22 == 21):
                c = ("night0", "night0", "plumDeep", "plum")[step]
            p.px(x, y, c)


def great_lantern(p):
    cx, cy = LANTERN
    for y in range(0, cy - 12):
        p.px(cx, y, "nightDeep" if y % 3 else "nightBlue")
    core_glow(p, cx, cy + 1, r=8, tones=("fireOrange", "emberDim"))
    rows = [
        "......i......",
        ".....iii.....",
        "...iiiiiii...",
        "..bbbbbbbbb..",
        ".iiiiiiiiiii.",
        ".i.b.....b.i.",
        ".i.b.....b.i.",
        ".i.b.....b.i.",
        ".i.b.....b.i.",
        ".i.b.....b.i.",
        ".i.b.....b.i.",
        ".i.b.....b.i.",
        ".i.b.....b.i.",
        ".bbbbbbbbbbb.",
        "..iiiiiiiii..",
        "....i...i...."]
    x0, y0 = cx - 6, cy - 11
    for r, row in enumerate(rows):
        for q, ch in enumerate(row):
            if ch == "i":
                p.px(x0 + q, y0 + r, "nightDeep")
            elif ch == "b":
                p.px(x0 + q, y0 + r, "gold" if q < 6 else "straw")
            elif 5 <= r <= 12 and 2 <= q <= 10:
                d = math.hypot(q - 6, (r - 9) * 0.8)
                p.px(x0 + q, y0 + r, "fireWhite" if d < 1.6 else ("fireGold" if d < 2.8 else "fireOrange"))
    for r in range(5, 13):
        p.px(x0 + 3, y0 + r, "nightDeep"); p.px(x0 + 9, y0 + r, "nightDeep")


def P(pts, dx=0, dy=0, flip=None):
    if flip is not None:
        pts = [(2 * flip - x, y) for (x, y) in pts]
    return poly_mask([(x + dx, y + dy) for (x, y) in pts])


def E(cx, cy, rx, ry):
    return ellipse_mask(cx, cy, rx, ry)


def brannock(x, f):
    """Broad, bearded, a round helm, the spear's shaft in his fist."""
    body = P([(x - 15, f - 50), (x + 13, f - 50), (x + 16, f - 44), (x + 13, f), (x - 13, f), (x - 17, f - 44)])
    head = E(x - 1, f - 57, 5, 6)
    helm = P([(x - 6, f - 58), (x + 5, f - 58), (x + 4, f - 63), (x - 1, f - 65), (x - 5, f - 63)])
    beard = P([(x - 5, f - 55), (x + 4, f - 55), (x + 3, f - 46), (x - 1, f - 43), (x - 4, f - 46)])
    arm = P([(x - 17, f - 46), (x - 11, f - 46), (x - 12, f - 28), (x - 19, f - 26), (x - 20, f - 32)])
    fist = E(x - 19, f - 28, 3, 3)
    spear = np.zeros((H, W), bool)
    spear[f - 82:f, x - 20:x - 18] = True
    tip = P([(x - 21, f - 82), (x - 17, f - 82), (x - 19, f - 89)])
    return [(spear, "woodDark"), (tip, "stoneMid"), (body, "nightDeep"), (arm, "nightDeep"), (fist, "crimsonDeep"),
            (head, "crimsonDeep"), (beard, "soilDark"), (helm, "stoneDark")]


def pip(x, f):
    """Half as tall, the two-horned cap."""
    body = P([(x - 6, f - 22), (x + 6, f - 22), (x + 8, f), (x - 8, f)])
    head = E(x, f - 26, 4, 4)
    cap = P([(x - 5, f - 27), (x + 5, f - 27), (x + 10, f - 34), (x + 3, f - 30), (x, f - 33), (x - 3, f - 30),
             (x - 10, f - 34)])
    return [(body, "plumDeep"), (head, "crimsonDeep"), (cap, "crimsonDeep")]


def bram(x, f):
    """Wide; the apron; bare forearms crossed over it."""
    body = P([(x - 15, f - 46), (x + 15, f - 46), (x + 17, f - 40), (x + 14, f), (x - 14, f), (x - 17, f - 40)])
    head = E(x, f - 53, 5, 6)
    hair = P([(x - 5, f - 54), (x + 5, f - 54), (x + 4, f - 59), (x - 4, f - 59)])
    apron = P([(x - 9, f - 38), (x + 9, f - 38), (x + 10, f - 4), (x - 10, f - 4)])
    arms = P([(x - 15, f - 40), (x - 9, f - 40), (x + 10, f - 30), (x + 12, f - 26), (x - 8, f - 26), (x - 16, f - 32)])
    arms2 = P([(x + 15, f - 40), (x + 9, f - 40), (x - 8, f - 30), (x - 10, f - 27), (x + 9, f - 24), (x + 16, f - 32)])
    return [(body, "nightDeep"), (apron, "woodDark"), (head, "crimsonDeep"), (hair, "soilDark"),
            (arms, "tile"), (arms2, "crimsonDeep")]


def odile(x, f):
    """Slight and old, bent forward from the hip toward the heir, both arms out to the circlet."""
    skirt = P([(x - 6, f - 30), (x + 6, f - 30), (x + 8, f), (x - 8, f)])
    torso = P([(x - 5, f - 30), (x + 6, f - 31), (x - 6, f - 50), (x - 15, f - 48)])
    head = E(x - 15, f - 52, 4, 4.5)
    scarf = P([(x - 19, f - 53), (x - 11, f - 55), (x - 9, f - 51), (x - 12, f - 47), (x - 18, f - 49)])
    arm1 = P([(x - 13, f - 48), (x - 9, f - 47), (x - 22, f - 41), (x - 25, f - 43)])
    arm2 = P([(x - 8, f - 45), (x - 4, f - 43), (x - 19, f - 37), (x - 22, f - 39)])
    return [(skirt, "nightDeep"), (torso, "nightDeep"), (arm2, "nightDeep"), (head, "crimsonDeep"),
            (scarf, "stoneMid"), (arm1, "nightDeep")]


def heir(kind, x, f):
    """Three-quarter back, turned to Odile (right). Lord: broad shoulders, short hair, a heavy straight cloak with a
    collar. Lady: narrower shoulders, long hair down the back, the cloak shorter over a gown that flares."""
    if kind == "lord":
        cloak = P([(x - 14, f - 56), (x + 12, f - 56), (x + 17, f - 48), (x + 15, f), (x - 15, f), (x - 17, f - 48)])
        collar = P([(x - 8, f - 60), (x + 7, f - 60), (x + 9, f - 55), (x - 9, f - 55)])
        head = E(x, f - 65, 5, 6)
        hair = P([(x - 5, f - 66), (x + 3, f - 70), (x + 5, f - 66), (x + 4, f - 63), (x - 5, f - 62)])
        arm = P([(x + 11, f - 52), (x + 16, f - 50), (x + 26, f - 42), (x + 23, f - 39)])
        return [(cloak, "nightBlue"), (arm, "nightBlue"), (collar, "roofDeep"), (head, "crimsonDeep"),
                (hair, "soilDark")]
    gown = P([(x - 9, f - 30), (x + 9, f - 30), (x + 17, f), (x - 17, f)])
    cloak = P([(x - 11, f - 54), (x + 10, f - 54), (x + 13, f - 46), (x + 11, f - 24), (x - 12, f - 24), (x - 13, f - 46)])
    head = E(x, f - 62, 4.5, 5.5)
    hair = P([(x - 5, f - 63), (x, f - 68), (x + 5, f - 64), (x + 4, f - 58), (x + 2, f - 40), (x - 4, f - 40),
              (x - 6, f - 58)])
    arm = P([(x + 9, f - 50), (x + 14, f - 48), (x + 25, f - 42), (x + 22, f - 39)])
    return [(gown, "roofDeep"), (cloak, "nightBlue"), (arm, "nightBlue"), (head, "crimsonDeep"), (hair, "soilDark")]


def back(x, top, w_):
    head = E(x, top + 9, 8, 9)
    sh = P([(x - w_ / 2, H), (x - w_ / 2 + 2, top + 26), (x - w_ / 2 + 9, top + 19), (x + w_ / 2 - 9, top + 19),
            (x + w_ / 2 - 2, top + 26), (x + w_ / 2, H)])
    return [(sh, "nightDeep"), (head, "nightDeep")]


SKIN = {"crimsonDeep": ("tileLight", "tile"), "tile": ("dawnRose", "tileLight"), "stoneMid": ("stonePale", "stone"),
        "stoneDark": ("stoneLight", "stoneMid"), "woodDark": ("woodLight", "wood"), "soilDark": ("tile", "woodDark")}


def slide4(kind):
    p = Pic()
    wall_and_floor(p)
    great_lantern(p)
    lx, ly = LANTERN
    for parts in (brannock(92, FLOOR - 6), pip(116, FLOOR - 7), bram(228, FLOOR - 6)):
        lit_figure(p, parts, lx, ly, near=90, lit_part=SKIN)
    lit_figure(p, odile(186, FLOOR - 1), lx, ly, near=90, lit_part=SKIN)
    # the old hands and the circlet: the brightest thing after the flame
    for (x, y) in ((161, FLOOR - 42), (162, FLOOR - 42), (164, FLOOR - 39), (165, FLOOR - 38)):
        p.px(x, y, "dawnRose")
    lit_figure(p, heir(kind, 141, FLOOR + 2), lx, ly, near=90, lit_part=SKIN)
    ring = ["...GWWG...", ".GG....GG.", "g........g", "g........g", ".ggsssgg.."]
    for r, row in enumerate(ring):
        for q, ch in enumerate(row):
            if ch != ".":
                p.px(155 + q, FLOOR - 52 + r, {"g": "gold", "G": "fireGold", "W": "fireWhite", "s": "straw"}[ch])
    for parts in (back(62, 110, 50), back(262, 104, 54)):
        lit_figure(p, parts, lx, ly, depth=2, tones_near=("plum", "plumDeep"), tones_far=("plum", "plumDeep"))
    return p
