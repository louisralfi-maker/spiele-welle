"""Slide 4 of the prologue (round 3): "The circlet passed to the last of his blood. / The heir of the guardian house."
A close two-shot: only the lantern, the heir, Odile and the circlet. The house's lantern top centre with its small core
glow; the heir on the left, three-quarter back, large, cut at the hip by the lower frame, in the house's mended cloak
(one patch catching the light); Odile on the right, three-quarter front, old and bowed from the hip, both hands
raised with the circlet between them right under the lantern at the heir's chest height: her face and hands the lit
centre, the circlet the brightest thing after the flame. Behind them the dark of the hall, a soft fan in two steps of
the night's own violet. Hand-set grids (round 3): the people lane's cast at slide scale, night versions, a dark mass
first, lit planes only on the side toward the lantern. Lord and Lady differ in the whole silhouette.
"""
import math

import numpy as np

from litkit import W, H, Pic, BAYER, core_glow, falloff, pick_air, grid_parts, light_grid

LANTERN = (160, 34)

# --- the heir, the Lord: wavy brown hair, a sliver of cheek and ear turned to Odile, the heavy straight cloak with a
# collar, broad shoulders, the patch on the right shoulder blade ---------------------------------------------------
LORD_TOP = [
    "...................HHHHH",
    "...............HHHHHHHHHHH",
    ".............HHHHHHHHHHHHHHH",
    "............HHHHHHHHHHHHHHHHH",
    "...........HHHHHHHHHHHHHHHHHHH",
    "..........HHHHHHHHHHHHHHHHHHHHH",
    ".........HHHHHHHHHHHHHHHHHHHHHHH",
    ".........HHHHHHHHHHHHHHHHHHHHHHH",
    "........HHHHHHHHHHHHHHHHHHHHHHHH",
    "........HHHHHHHHHHHHHHHHHHHHHHFF",
    ".......HHHHHHHHHHHHHHHHHHHHHHFFF",
    "........HHHHHHHHHHHHHHHHHHHHHFFF",
    "........HHHHHHHHHHHHHHHHHHHHFFFF",
    ".........HHHHHHHHHHHHHHHHHHHFFFF",
    ".........HHHHHHHHHHHHHHHHHHFFFF.",
    "..........HHHHHHHHHHHHHHHHHFFF..",
    "..........HHHHHHHHHHHHHHHHFFF...",
    "...........HHHHHHHHHHHHHHFFF....",
    "............HHHHHHHHHHHHFF......",
    ".............FFFFFFFFFFFF.......",
    "..............FFFFFFFFFF........",
    "...........KKKKKKKKKKKKKKKK......",
    ".......CCCCKKKKKKKKKKKKKKKKCCCC..",
    "....CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC",
    "..CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC",
    ".CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC",
]


def lord_rows():
    rows = list(LORD_TOP)
    for i in range(74):
        right = 39 + min(11, i // 4)
        row = ["C"] * (right + 1)
        for fx in (12, 24, 33):                     # the cloak's folds, a step darker
            if fx + i // 18 < right and (i + fx) % 23 < 19:
                row[fx + i // 18] = "f"
        if 4 <= i <= 12 and 30 <= right:            # the mended patch on the right shoulder blade
            for c in range(31, 38):
                row[c] = "P" if not (i in (4, 12) or c in (31, 37)) else "p"
        rows.append("".join(row))
    return rows


# --- the heir, the Lady: brown hair falling down her back, a plait over the right shoulder tied in gold, narrower
# shoulders, a short shoulder cape over a gown -----------------------------------------------------------------------
LADY_TOP = [
    "...................HHHH",
    "................HHHHHHHHH",
    "..............HHHHHHHHHHHHH",
    ".............HHHHHHHHHHHHHHH",
    "............HHHHHHHHHHHHHHHHH",
    "...........HHHHHHHHHHHHHHHHHHH",
    "...........HHHHHHHHHHHHHHHHHHH",
    "..........HHHHHHHHHHHHHHHHHHHHH",
    "..........HHHHHHHHHHHHHHHHHHHFF",
    "..........HHHHHHHHHHHHHHHHHHHFFF",
    "..........HHHHHHHHHHHHHHHHHHFFFF",
    "..........HHHHHHHHHHHHHHHHHHFFFF",
    "..........HHHHHHHHHHHHHHHHHFFFF",
    "..........HHHHHHHHHHHHHHHHFFFF",
    "..........HHHHHHHHHHHHHHHHFFF",
    "..........HHHHHHHHHHHHHHHFFF",
    "..........HHHHHHHHHHHHHHHFF",
    "..........HHHHHHHHHHHHHHFFF",
    "..........HHHHHHHHHHHHHHFFLL",
    "..........HHHHHHHHHHHHHHHLLL",
    "........CCHHHHHHHHHHHHHHCLLLC",
    "......CCCCHHHHHHHHHHHHHHCLLLCC",
    ".....CCCCCHHHHHHHHHHHHHCCCLLLCCC",
    "....CCCCCCHHHHHHHHHHHHHCCCLLLCCCC",
    "...CCCCCCCCHHHHHHHHHHHCCCCCLLLCCCC",
]


def lady_rows():
    rows = list(LADY_TOP)
    for i in range(75):
        right = 34 + min(8, i // 5)
        if i < 18:
            cape = True
        else:
            cape = False
        row = ["C" if cape else "D"] * (right + 1)
        if i < 18:
            # the cape's hem, scalloped, and the hair still down her back
            for c in range(11, 22 - i // 3):
                row[c] = "H"
        elif i == 18 or i == 19:
            for c in range(0, right + 1):
                row[c] = "C" if (c // 5) % 2 == (i % 2) else "D"
        if i < 26:                                  # the plait over the right shoulder, in front
            for c in (27, 28, 29):
                if c <= right:
                    row[c] = "L"
            if i == 25:
                for c in (27, 28, 29):
                    row[c] = "G"
        for fx in (8, 20, 30):
            if i > 20 and fx + i // 20 < right and (i + fx) % 21 < 17:
                row[fx + i // 20] = "f"
        rows.append("".join(row))
    return rows


# --- Odile: tall and thin, bowed from the hip; the grey hair in a high bun, the long nose; the plum robe with its rose
# facing; the silver chain to the gold seal; both hands raised to the circlet -------------------------------------
ODILE_TOP = [
    "........................ggg",
    ".......................ggggg",
    ".......................ggggg",
    "........................ggg",
    "...................ggggggggg",
    ".................ggggggggggggg",
    "................gggggggggggggg",
    "...............SSggggggggggggg",
    "..............SSSSgggggggggggg",
    ".............SSSSSSggggggggggg",
    "...........SSSSSSSSSggggggggg",
    "..........SSSSSSSSSSSgggggggg",
    "............SSSSSSSSSSggggggg",
    ".............SSSSSSSSSgggggg",
    "..............SSSSSSSSggggg",
    "...............SSSSSSSgggg",
    "................SSSSSSS.RRR",
    "...............RRRRRRRRRRRRRR",
    "............AAARRRRRRRRRRRRRRR",
    "..........AAAAARRRRRRRRRRRRRRRR",
    "........AAAAAAArcRRRRRRRRRRRRRRR",
    "......AAAAAAAAArRcRRRRRRRRRRRRRRR",
    "....AAAAAAAAA.rRRcRRRRRRRRRRRRRRRR",
    "..SSAAAAAAA...rRRRGRRRRRRRRRRRRRRRR",
    ".SSSSAAAA.....rRRRRRRRRRRRRRRRRRRRR",
    "SSSSSAA.......rRRRRRRRRRRRRRRRRRRRRR",
    ".SSSS.........rRRRRRRRRRRRRRRRRRRRRR",
]
ODILE_FAR_ARM = [   # the far arm, raised under the near one to the other side of the circlet
    "......................",
    "......................",
    ".................aaaa.",
    "..............aaaaaaa.",
    "...........aaaaaaaa...",
    "........aaaaaaaaa.....",
    "......aaaaaaaa........",
    "....aaaaaaa...........",
    "..SSaaaaa.............",
    ".SSSSaa...............",
    "SSSSS.................",
    ".SSS..................",
]


def odile_rows():
    rows = list(ODILE_TOP)
    for i in range(62):
        left = 14 + i // 9
        right = 36 + min(8, i // 6)
        row = ["."] * left + ["r"] + ["R"] * (right - left)
        if i > 8 and 30 + i // 20 < right and i % 19 < 15:
            row[30 + i // 20] = "f"                 # one fold down the robe
        rows.append("".join(row))
    return rows


LEGEND_LORD = {"C": ("nightBlue", "roofLight", "roofDeep"), "f": ("nightDeep", "roofDeep", "nightBlue"),
               "P": ("soil", "soilLight", "soilLight"), "p": ("woodDark", "soil", "woodDark"),
               "K": ("nightDeep", "gold", "straw"), "H": ("woodDark", "woodLight", "wood"),
               "F": ("crimsonDeep", "dawnRose", "tileLight")}
LEGEND_LADY = {"D": ("nightDeep", "tileLight", "crimsonDeep"), "C": ("nightBlue", "roofLight", "roofDeep"),
               "f": ("night0", "crimsonDeep", "nightDeep"), "L": ("soilDark", "soilLight", "soil"),
               "G": ("woodDark", "fireGold", "gold"), "H": ("soilDark", "soilLight", "soil"),
               "F": ("crimsonDeep", "dawnRose", "tileLight")}
LEGEND_ODILE = {"R": ("night0", "rockDark", "rockDeep"), "f": ("night0", "rockDeep", "night1"),
                "r": ("plumDeep", "dusk", "plum"), "A": ("nightDeep", "rockLight", "rockDark"),
                "a": ("night0", "rockDark", "rockDeep"), "c": ("stoneMid", "stonePale", "stoneLight"),
                "G": ("gold", "fireGold", "gold"), "g": ("stoneDark", "stonePale", "stoneLight"),
                "S": ("tile", "dawnRose", "dawnRose", 6)}


def wall(p):
    """The dark of the hall: a soft fan under the lantern in two steps of the night's own violet, dithered edges;
    a few courses hinted where it is brightest."""
    for y in range(H):
        for x in range(W):
            t = falloff(x, y, LANTERN[0], LANTERN[1] + 30, 150, 120, 1.4)
            p.px(x, y, pick_air(x, y, ["night0", "night1", "plumDeep"], t * 2.4))
    for (x0, x1, y) in ((128, 150, 52), (170, 196, 52), (118, 142, 70), (180, 204, 70), (136, 160, 61), (164, 186, 79)):
        for x in range(x0, x1):
            if p.get(x, y) == "plumDeep" and (x // 3) % 4:
                p.px(x, y, "night1")


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


CIRCLET = ["....GWWWG....", "..GG.....GG..", ".g.........g.", "g...........g", ".g.........g.",
           "..gsssssssg.."]


def scaled(rows, k):
    """The grid set larger by a whole-pixel repeat pattern (every other px doubled), so a hand-set figure grows
    without a resample."""
    out = []
    for r, row in enumerate(rows):
        wide = "".join(ch * (2 if (q % 2 == 0 and k > 1.2) else 1) for q, ch in enumerate(row))
        out.append(wide)
        if r % 2 == 0 and k > 1.2:
            out.append(wide)
    return out


def slide4(kind):
    p = Pic()
    wall(p)
    great_lantern(p)
    lx, ly = LANTERN
    # Odile behind the circlet, the far arm first
    ox, oy = 136, 54
    light_grid(p, grid_parts(scaled(ODILE_FAR_ARM, 1.5), ox - 3, oy + 24, LEGEND_ODILE), lx, ly)
    light_grid(p, grid_parts(scaled(odile_rows(), 1.5), ox, oy, LEGEND_ODILE), lx, ly)
    # the heir, large, on the left
    if kind == "lord":
        light_grid(p, grid_parts(lord_rows(), 62, 60, LEGEND_LORD), lx, ly)
    else:
        light_grid(p, grid_parts(lady_rows(), 66, 61, LEGEND_LADY), lx, ly)
    # the circlet between her hands: the brightest thing after the flame
    for r, row in enumerate(CIRCLET):
        for q, ch in enumerate(row):
            if ch != ".":
                p.px(134 + q, 89 + r, {"g": "gold", "G": "fireGold", "W": "fireWhite", "s": "straw"}[ch])
    return p
