"""Slide 4 of the prologue (round 4): THE EMPTY SEAT. "The circlet passed to the last of his blood. / The heir of the
guardian house." The hall at night in side view, as the game shows it. Right of centre a dais of two stone steps and
the lord's high-backed seat, empty; on it lies the circlet, a small gold ring with one small four-ray glint, the
brightest thing after the flame. Above it the house's great lantern on its chain, a small core glow only; its light
is seen on the seat, on the steps' edges, on a pool of flagstones that falls off toward the door, and on the
lantern-side edge of three pillars. Far left the tall door open to the night, and on its threshold the heir, small
(32 px, hand-set), standing still, looking at the seat. Odile beside the dais, small and bowed, her grey bun lit.
One small gold light in a big dark. Lord and Lady differ by silhouette.
"""
import math

import numpy as np

from litkit import W, H, Pic, BAYER, core_glow, falloff, grid_parts, light_grid, poly_mask, h

LANTERN = (246, 40)
FLOOR = 136
STEP = ["night0", "nightDeep", "crimsonDeep", "tile", "tileLight", "straw"]


def lit_level(x, y, rx=150, ry=110, k=1.0):
    return int(falloff(x, y, LANTERN[0], LANTERN[1], rx, ry, 1.15) * 5.4 * k)


def great_lantern(p):
    cx, cy = LANTERN
    for y in range(0, cy - 12):
        p.px(cx, y, "nightDeep" if y % 3 else "nightBlue")
    core_glow(p, cx, cy + 1, r=7, tones=("ember", "emberDim"))
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


LORD = [
    "....HHHH.....",
    "...HHHHHH....",
    "...HHHHHHF...",
    "...HHHHHFF...",
    "....HHHFFF...",
    "....HHFFF....",
    ".....FFF.....",
    "..CCCCCCCC...",
    ".CCCCCCCCCC..",
    "CCCCCCCCCCC..",
    "CCCCCCCCCCCC.",
    "CCCCCCCCCCCC.",
    "CCCCCCCCCCCC.",
    "CCCCCCCCCCCC.",
    "CCCCCCCCCCCC.",
    "CCCCCCCCCCCC.",
    "CCCCCCCCCCCC.",
    "CCCCCCCCCCCC.",
    "CCCCCCCCCCCC.",
    "CCCCCCCCCCCC.",
    "CCCCCCCCCCCC.",
    "CCCCCCCCCCCC.",
    "CCCCCCCCCCCC.",
    "CCCCCCCCCCCC.",
    "CCCCCCCCCCCC.",
    "CCCCCCCCCCCC.",
    "CCCCCCCCCCCC.",
    ".CCCCCCCCCC..",
    "..BB...BB....",
    "..BB...BB....",
    "..BB...BBB...",
    ".BBB...BBB..."]
LADY = [
    ".....HHH.....",
    "....HHHHH....",
    "...HHHHHHF...",
    "...HHHHHFF...",
    "..HHHHHFFF...",
    "..HHHHFFF....",
    "..HHHHFF.....",
    "..HHHCCCC....",
    "..HHCCCCCC...",
    "..HHCCCCCC...",
    "..HHCCCCCCC..",
    "..HHCCCCCCC..",
    "..HHCCCCCCC..",
    "...HCCCCCCC..",
    "...HCCCCCCC..",
    "...DDDDDDDD..",
    "...DDDDDDDD..",
    "..DDDDDDDDD..",
    "..DDDDDDDDDD.",
    "..DDDDDDDDDD.",
    ".DDDDDDDDDDD.",
    ".DDDDDDDDDDD.",
    ".DDDDDDDDDDDD",
    ".DDDDDDDDDDDD",
    "DDDDDDDDDDDDD",
    "DDDDDDDDDDDDD",
    "DDDDDDDDDDDDD",
    "DDDDDDDDDDDDD",
    "DDDDDDDDDDDDD",
    "DDDDDDDDDDDDD",
    ".BB.....BB...",
    ".BB.....BB..."]
ODILE = [
    "......gg...",
    ".....gggg..",
    "..SSgggggg.",
    ".SSSgggggg.",
    "SSSSSgggg..",
    ".SSSSRRRR..",
    "...SRRRRRR.",
    "....RRRRRRR",
    "...SSRRRRRR",
    "...SSRRRRRR",
    "....RRRRRRR",
    "....RRRRRRR",
    "....RRRRRRR",
    "....RRRRRRR",
    "....RRRRRRR",
    "...RRRRRRRR",
    "...RRRRRRRR",
    "...RRRRRRRR",
    "..RRRRRRRRR",
    "..RRRRRRRRR",
    "..RRRRRRRRR",
    "..RRRRRRRRR",
    ".RRRRRRRRRR",
    ".RRRRRRRRRR"]
HEIR_LEGEND = {"H": ("night0", "tile", "night0", 1), "F": ("night0", "tile", "night0", 1),
               "C": ("night0", "tile", "night0", 1), "D": ("night0", "tile", "night0", 1),
               "B": ("night0", "tile", "night0", 1)}
ODILE_LEGEND = {"g": ("stoneMid", "stonePale", "stoneLight", 2), "S": ("crimsonDeep", "tileLight", "tile", 1),
                "R": ("night0", "crimsonDeep", "night0", 1)}


def slide4(kind):
    p = Pic()
    # the back wall: the hall's dark; courses hinted only near the lantern, on the stones it reaches
    for y in range(FLOOR):
        for x in range(W):
            lv = lit_level(x, y, 110, 90, 0.7)
            c = "night1"
            if lv >= 1 and y % 9 == 8 and h(x // 6, y, 4) < 0.6:
                c = "night0" if lv == 1 else "plumDeep"
            p.px(x, y, c)
    # the door, far left, open to the night: the sky's blue, three stars, a line of land
    door = poly_mask([(14, FLOOR), (14, 74), (20, 64), (29, 60), (38, 64), (44, 74), (44, FLOOR)])
    p.mask(door, "nightBlue")
    for y in range(64, FLOOR):
        for x in range(14, 45):
            if door[y, x] and y > 104:
                p.px(x, y, "nightSlate" if y < 122 else "nightDeep")
    for (x, y) in ((24, 72), (34, 80), (20, 92)):
        p.px(x, y, "moon")
    for y in range(58, FLOOR):                                       # the door's stone frame
        for x in (12, 13, 45, 46):
            p.px(x, y, "nightDeep")
    # the floor: flagstones; the lantern's pool falls off toward the door, one tone per stone
    for y in range(FLOOR, H):
        row = (y - FLOOR) // 6
        off = 9 if row % 2 else 0
        for x in range(W):
            sx = (x + off) // 20
            t = falloff(sx * 20 - off + 10, FLOOR + row * 6 + 3, LANTERN[0] - 6, FLOOR, 120, 26, 1.3) * 3.8
            lv = int(t)
            if t - lv > 0.7 and BAYER[y % 4][x % 4] < 6:
                lv += 1                                              # the stone's edge toward the next step
            c = STEP[min(4, lv)]
            if (x + off) % 20 == 19 or (y - FLOOR) % 6 == 5:
                c = STEP[max(0, min(4, lv) - 1)]
            p.px(x, y, c)
    for x in range(W):
        p.px(x, FLOOR, STEP[max(0, min(5, lit_level(x, FLOOR)))])
    # three pillars between the seat and the door: dark verticals, their lantern-side edge lit
    for (x0, x1) in ((88, 98), (140, 150), (186, 196)):
        for y in range(0, FLOOR):
            for x in range(x0, x1 + 1):
                p.px(x, y, "night0" if x < x1 - 1 else "nightDeep")
            lv = lit_level(x1, y, 170, 120)
            if lv >= 1:
                p.px(x1, y, STEP[min(5, lv + 1)])
                p.px(x1 - 1, y, STEP[min(5, lv)])
        for x in range(x0 - 2, x1 + 3):                             # base and capital
            p.px(x, FLOOR - 1, "nightDeep"); p.px(x, FLOOR - 2, "nightDeep")
            p.px(x, 22, "nightDeep"); p.px(x, 23, "nightDeep")
    # the dais: two stone steps, their edges lit
    for (x0, x1, y0, y1) in ((200, 294, 128, FLOOR), (210, 284, 120, 128)):
        for y in range(y0, y1):
            for x in range(x0, x1):
                lv = lit_level(x, y, 120, 100, 0.55)
                p.px(x, y, ("nightDeep", "nightBlue", "nightBlue", "crimsonDeep", "tile")[min(4, lv)] if y > y0 + 1
                     else STEP[min(5, lit_level(x, y) + 2)])
    # the high-backed seat, empty
    seat = {"back": (238, 254, 68, 106), "board": (232, 260, 104, 108), "armL": (230, 235, 98, 108),
            "armR": (257, 262, 98, 108), "legL": (233, 236, 108, 120), "legR": (256, 259, 108, 120)}
    for name, (x0, x1, y0, y1) in seat.items():
        for y in range(y0, y1):
            for x in range(x0, x1 + 1):
                top = y < y0 + 2
                inner = (name == "armL" and x >= x1 - 1) or (name == "armR" and x <= x0 + 1) or \
                        (name == "back" and (x <= x0 + 1 or x >= x1 - 1))
                lv = lit_level(x, y, 90, 80)
                if top or inner:
                    c = ("woodDark", "wood", "wood", "woodLight", "strawLight", "strawLight")[min(5, lv)]
                else:
                    c = ("night0", "woodDark", "woodDark", "wood", "wood", "woodLight")[min(5, lv // 2)]
                p.px(x, y, c)
    for (x, y) in ((246, 64), (245, 65), (247, 65), (246, 66), (246, 67)):
        p.px(x, y, "gold")                                           # the finial: the house's lantern in gold
    for y in range(72, 102, 6):
        for x in range(241, 252):
            if (x + y) % 3 == 0:
                p.px(x, y, "woodDark")                               # carving on the back
    # the circlet on the seat: a small gold ring, one small four-ray glint
    ring = [".GgggG.", "g.....g", ".gsssg."]
    for r, row in enumerate(ring):
        for q, ch in enumerate(row):
            if ch != ".":
                p.px(243 + q, 101 + r, {"g": "gold", "G": "fireGold", "s": "straw"}[ch])
    gx, gy = 248, 100
    p.px(gx, gy, "fireWhite")
    for (dx, dy) in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        p.px(gx + dx, gy + dy, "fireGold")
    for (dx, dy) in ((2, 0), (-2, 0), (0, -2)):
        p.px(gx + dx, gy + dy, "fireOrange")
    great_lantern(p)
    # Odile beside the dais, small and bowed, hands folded, her grey bun the one lit thing
    light_grid(p, grid_parts(ODILE, 288, 120 - len(ODILE), ODILE_LEGEND), LANTERN[0], LANTERN[1])
    # the heir on the threshold, small, still, looking at the seat
    rows = LORD if kind == "lord" else LADY
    light_grid(p, grid_parts(rows, 34, FLOOR - len(rows), HEIR_LEGEND), LANTERN[0], LANTERN[1] + 60)
    return p
