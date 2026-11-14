#!/usr/bin/env python3
"""The great hall as its own stage and the marks of "touch the world" (look 2, stage 8: ART-look2.md section 20,
SPRITES.md "Stage 8"). Proposals for the code lane: no Swift names these sprites yet.

    python3 -I -B tools/hallart.py build <id> [--out dir]
    python3 -I -B tools/hallart.py list
    python3 -I -B tools/hallart.py anchors <id>

Painted like the rooms of M3 with roomart.py's canvas and brushes: palette names only, binary alpha, albedo (evenly
lit daylight colours; the engine adds the night, the firelight and the flames), integer hashes only, so every run
writes the same bytes. The window lights are transparent: the sky and the Weltmauer stand behind them."""
import argparse
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from roomart import (Canvas, ART, art, stamps, rnd, arch_set, ring, ashlar, planks,  # noqa: E402
                     beam, post, flagstones, shift_ramp)

W, H = 600, 201
FLOOR = 175            # the nave's walk line: an actor's lowest pixel row is FLOOR - 1
WALL = 163             # the first floor row under the nave's back wall
RISE = 9               # the dais stands this many px above the nave floor
STEPS_X = 364          # three steps, 4 px each
DAIS_X = 376
SHAFTS = (10, 126, 242, 358, 474, 590)
PLATE = 22             # the wall plate's top row
WALLTOP = 27
SPRING = 56            # where the wall arches spring from the shafts' capitals
STONE = ("ink", "stoneDark", "stoneMid", "stone", "stoneLight", "stonePale")
THRONE_X = 416
HEARTH_X = 532
BANNERS = (137, 211, 253, 327, 368)   # left edges of the five banner places
BANNER_TOP = 62
WINDOWS = (184, 300)
CHANDELIERS = (184, 300)
STANDS = (160, 208, 276, 324)

LANTERN = ("......G......",
           ".....G.G.....",
           ".....G.G.....",
           "......G......",
           "....GGGGG....",
           "...GGGGGGG...",
           "..GGGGGGGGG..",
           "..G.yyyyy.G..",
           "..G.yyYyy.G..",
           "..G.yYYYy.G..",
           "..G.yYYYy.G..",
           "..G.yyYyy.G..",
           "..G.yyyyy.G..",
           "..GGGGGGGGG..",
           "...GGGGGGG...",
           "....GGGGG....")


def base_at(x):
    """The first floor row under the back wall at column x (the dais and its steps lift it)."""
    if x >= DAIS_X:
        return WALL - RISE
    if x >= STEPS_X:
        return WALL - 3 * ((x - STEPS_X) // 4 + 1)
    return WALL


def bitmap(c, rows, x, y, legend):
    for j, row in enumerate(rows):
        for i, ch in enumerate(row):
            if ch in legend:
                c.put(x + i, y + j, legend[ch])


def darker(v, n=1):
    if v in STONE:
        return STONE[max(0, STONE.index(v) - n)]
    return v


def intrados(x, cx, half=54, rise=24, p=1.7):
    t = min(1.0, abs(x - cx) / float(half))
    return SPRING - int(round(rise * (1.0 - t ** p)))


# ------------------------------------------------------------------------------------------------- roof and wall

def roof(c):
    """The open timber roof from below: dark boards, a rafter every 12 px, a purlin, the wall plate with dentils."""
    for y in range(0, PLATE):
        for x in range(10, 590):
            v = "woodDark"
            if y % 4 == 3 or rnd(31, x // 3, y) < 0.05:
                v = "ink"
            c.put(x, y, v)
    for x in range(16, 590, 12):
        for y in range(0, PLATE):
            c.put(x, y, "wood")
            c.put(x + 1, y, "woodDark")
            c.put(x + 2, y, "ink")
    beam(c, 10, 589, 9, h=3, seed=32)
    beam(c, 10, 589, PLATE, h=4, seed=33)
    for x in range(10, 590):
        c.put(x, PLATE + 4, "woodLight" if (x // 3) % 2 == 0 else "woodDark")


def wall(c):
    ashlar(c, 10, WALLTOP, 589, WALL - 1, seed=41, course=(7, 6), width=(10, 18))
    # the dais end is of paler dressed stone below the string course
    ashlar(c, STEPS_X, 140, 589, WALL - 1, seed=42, course=(7, 7), width=(12, 20),
           faces=("stoneLight",) * 4 + ("stone", "stonePale"), joint="stone", deep="stoneMid", light="stonePale",
           shade="stone")
    for a, b in zip(SHAFTS, SHAFTS[1:]):
        cx = (a + b) // 2
        for x in range(a + 4, b - 3):
            r = intrados(x, cx)
            for y in range(WALLTOP, r - 4):
                c.put(x, y, darker(c.get(x, y)))
            for k, col in enumerate(("stonePale", "stoneLight", "stone", "stoneMid")):
                c.put(x, r - 4 + k, col)
            if (x - cx) % 7 == 0:
                c.put(x, r - 3, "stoneMid")
                c.put(x, r - 2, "stoneMid")
            c.put(x, r, "stoneDark")
    # the string course
    for x in range(10, 590):
        c.put(x, 136, "stonePale")
        c.put(x, 137, "stoneLight")
        c.put(x, 138, "stone")
        c.put(x, 139, "stoneDark")


def wainscot(c):
    """Oak panelling along the nave's wall: a rail, framed panels, a skirting."""
    x1 = STEPS_X - 1
    planks(c, 10, 143, x1, 159, seed=43, width=(5, 6), colours=("wood", "wood", "woodLight"), knots=0.004)
    for x in range(10, x1 + 1):
        c.put(x, 140, "woodLight")
        c.put(x, 141, "wood")
        c.put(x, 142, "woodDark")
        c.put(x, 160, "woodLight")
        c.put(x, 161, "wood")
        c.put(x, 162, "ink")
    for x in range(20, x1, 22):
        for y in range(143, 160):
            c.put(x, y, "woodLight")
            c.put(x + 1, y, "woodDark")
        for xx in range(x + 4, min(x + 20, x1)):
            c.put(xx, 145, "woodDark")
            c.put(xx, 157, "woodLight")


def shaft(c, sx):
    """A wall shaft with its capital and base, the timber wall post above it and the roof's two arch braces."""
    base = base_at(sx)
    cols = ("stoneDark", "stonePale", "stoneLight", "stoneLight", "stone", "stoneMid", "stoneDark")
    for y in range(SPRING + 2, base):
        for i, col in enumerate(cols):
            v = col
            if (y - SPRING) % 17 == 0 and 0 < i < 6:
                v = "stoneMid" if i < 5 else "stoneDark"
            c.put(sx - 3 + i, y, v)
    for y, half in ((50, 6), (51, 6), (52, 6), (53, 5), (54, 5), (55, 4), (56, 4), (57, 4)):
        for x in range(sx - half, sx + half + 1):
            v = "stoneLight"
            if y == 50 or x == sx - half + 1:
                v = "stonePale"
            if y in (52, 55) or x >= sx + half - 1:
                v = "stoneMid"
            if x in (sx - half, sx + half) or y == 57:
                v = "stoneDark"
            c.put(x, y, v)
    for y, half in ((base - 6, 4), (base - 5, 5), (base - 4, 5), (base - 3, 5), (base - 2, 6), (base - 1, 6)):
        for x in range(sx - half, sx + half + 1):
            v = "stoneLight"
            if x <= sx - half + 1 or y == base - 6:
                v = "stonePale"
            if x >= sx + half - 1 or y == base - 3:
                v = "stoneMid"
            if x in (sx - half, sx + half):
                v = "stoneDark"
            c.put(x, y, v)
    post(c, sx - 2, WALLTOP, 49, w=5, seed=sx)
    for side in (-1, 1):
        for i in range(0, 23):
            x = sx + side * (3 + i)
            y = 50 - int(round(23 * math.sin(i / 22.0 * math.pi / 2)))
            if x < 11 or x > 588:
                continue
            c.put(x, y - 1, "woodLight")
            c.put(x, y, "wood")
            c.put(x, y + 1, "wood")
            c.put(x, y + 2, "woodDark")
    # a carved boss where the braces leave the post: the lantern's ring in gold
    c.put(sx, 46, "gold")
    c.put(sx - 1, 47, "gold")
    c.put(sx + 1, 47, "gold")
    c.put(sx, 48, "gold")


# ------------------------------------------------------------------------------------------------------- windows

def tall_window(c, cx, top, bottom, w=30):
    """A two-light window with an oculus in its head: a dressed surround, stone tracery, iron saddle bars. The lights
    are transparent. Returns the glass pixels."""
    x0 = cx - w // 2
    outer = arch_set(x0, top, w, bottom - top + 1, True, 0.8)
    inner = arch_set(x0 + 3, top + 3, w - 6, bottom - top - 2, True, 0.8)
    for (x, y) in outer:
        if (x, y) in inner:
            continue
        out_edge = any(q not in outer for q in ((x + 1, y), (x - 1, y), (x, y - 1)))
        in_edge = any(q in inner for q in ((x + 1, y), (x - 1, y), (x, y + 1)))
        v = "stoneLight"
        if out_edge:
            v = "stonePale" if x < cx else "stoneLight"
        if in_edge:
            v = "stoneDark" if x < cx else "stoneMid"
        if (y - top) % 8 == 7 and not in_edge:
            v = "stone"
        c.put(x, y, v)
    full = w - 6
    spring = min(y for (x, y) in inner if all((xx, y) in inner for xx in range(x0 + 3, x0 + 3 + full)))
    lw = (w - 8) // 2
    glass = set()
    for lx in (x0 + 3, x0 + 3 + lw + 2):
        glass |= arch_set(lx, spring - 3, lw, bottom - spring + 4, True, 0.8)
    orad = 4.3 if w >= 30 else 3.2
    ocy = spring - (10 if w >= 30 else 8)
    for (x, y) in inner:
        if (x - (cx - 0.5)) ** 2 + (y - ocy) ** 2 <= orad * orad:
            glass.add((x, y))
    glass &= inner
    transom = spring + int((bottom - spring) * 0.46)
    for (x, y) in list(glass):
        if y in (transom, transom + 1):
            glass.discard((x, y))
    for (x, y) in inner:
        if (x, y) in glass:
            continue
        v = "stoneLight"
        if (x - 1, y) in glass or (x, y + 1) in glass:
            v = "stonePale"
        if (x + 1, y) in glass or (x, y - 1) in glass:
            v = "stoneMid"
        if y == transom + 1:
            v = "stoneMid"
        c.put(x, y, v)
    for (x, y) in glass:
        c.put(x, y, "clear")
        if y > spring + 4 and (y - spring) % 9 == 0:
            c.put(x, y, "ink")
    for x in range(x0 - 2, x0 + w + 2):
        c.put(x, bottom + 1, "stonePale")
        c.put(x, bottom + 2, "stoneLight")
        c.put(x, bottom + 3, "stoneMid")
        if x > x0:
            c.put(x, bottom + 4, "stoneDark")
    return glass


def rose_window(c, cx, cy, r=13):
    """A wheel window: a stone ring, eight spokes round a hub, the lights transparent."""
    for y in range(cy - r - 1, cy + r + 2):
        for x in range(cx - r - 1, cx + r + 2):
            d = math.sqrt((x - cx) ** 2 + (y - cy) ** 2)
            if d > r + 0.4:
                continue
            if d > r - 2.6:
                v = "stoneLight"
                if d > r - 0.7:
                    v = "stonePale" if (x + y) < (cx + cy) else "stone"
                if d < r - 1.7:
                    v = "stoneDark" if (x + y) < (cx + cy) else "stoneMid"
                c.put(x, y, v)
                continue
            dx, dy = x - cx, y - cy
            spoke = dx == 0 or dy == 0 or abs(dx) == abs(dy)
            if d < 2.6:
                c.put(x, y, "stonePale" if d < 1.2 else "stoneLight")
            elif spoke or 5.6 < d < 6.6:
                c.put(x, y, "stoneLight" if (dx <= 0 and dy <= 0) else "stoneMid")
            else:
                c.put(x, y, "clear")


def slit(c, cx, top, bottom):
    """A narrow lancet beside the chimney breast: 4 px of night in a splayed surround."""
    for y in range(top - 2, bottom + 1):
        for x in range(cx - 4, cx + 4):
            j = y - top
            lo, hi = cx - 2, cx + 1
            if j < 0:
                lo, hi = cx, cx - 1
            elif j < 2:
                lo, hi = cx - 1, cx
            if lo <= x <= hi:
                c.put(x, y, "clear")
                if j > 4 and j % 9 == 0:
                    c.put(x, y, "ink")
            elif lo - 2 <= x <= hi + 2:
                v = "stonePale" if x < lo - 1 else ("stoneDark" if x < lo else ("stoneMid" if x <= hi + 1 else "stoneLight"))
                c.put(x, y, v)
    for x in range(cx - 5, cx + 5):
        c.put(x, bottom + 1, "stonePale")
        c.put(x, bottom + 2, "stoneMid")


# ------------------------------------------------------------------------------------------- hangings and timber

def realm_banner(c, bx, top):
    """The realm's banner in a house banner's exact outline (the houses' banners hang over it): teal, the gold
    lantern; on an iron rod."""
    src = art("bannerVarn")
    for y in range(src.h):
        for x in range(src.w):
            v = src.px[y][x]
            if v is None:
                continue
            col = "banner"
            if v == "night0":
                col = "night0"
            elif x >= src.w - 4:
                col = "roofDeep"
            elif x in (5, 6) and y > 3:
                col = "roofLight"
            c.put(bx + x, top + y, col)
    for x in range(bx + 2, bx + src.w - 2):
        c.put(x, top + 1, "gold")
    st = stamps("hall")["emblem"]
    c.stamp(st, bx + (src.w - st.w) // 2, top + 11)
    c.hline(bx - 2, bx + src.w + 1, top - 1, "ink")
    c.put(bx - 3, top - 1, "stoneDark")
    c.put(bx + src.w + 2, top - 1, "stoneDark")
    c.put(bx - 2, top - 2, "ink")
    c.put(bx + src.w + 1, top - 2, "ink")


def gallery(c):
    """The gallery over the door: a floor beam on joists and knee braces, a turned balustrade, the realm's cloth
    over the rail, a candle on each newel."""
    x0, x1 = 14, 122
    for y in list(range(80, 96)) + list(range(104, 111)):
        for x in range(x0, x1 + 1):
            c.put(x, y, darker(c.get(x, y)))
    beam(c, x0, x1, 96, h=5, seed=44)
    for x in range(x0 + 3, x1 - 2, 8):
        for y in (101, 102, 103):
            c.put(x, y, "woodLight" if y == 101 else "wood")
            c.put(x + 1, y, "wood")
            c.put(x + 2, y, "woodDark")
    for side, xa in ((1, 14), (-1, 122)):
        for i in range(0, 19):
            x = xa + side * i
            y = 124 - int(round(22 * math.sin(i / 18.0 * math.pi / 2)))
            c.put(x, y - 1, "woodLight")
            c.put(x, y, "wood")
            c.put(x, y + 1, "wood")
            c.put(x, y + 2, "woodDark")
    for x in range(x0, x1 + 1):
        c.put(x, 80, "woodLight")
        c.put(x, 81, "wood")
        c.put(x, 82, "woodDark")
        c.put(x, 95, "wood")
    for x in range(x0 + 4, x1 - 2, 5):
        for y in range(83, 95):
            wide = y in (87, 88, 89)
            c.put(x, y, "woodLight")
            c.put(x + 1, y, "wood" if not wide else "woodLight")
            if wide:
                c.put(x + 2, y, "woodDark")
                c.put(x - 1, y, "wood")
    for nx in (x0, x1 - 2):
        post(c, nx, 76, 95, w=3, seed=nx)
        c.put(nx + 1, 75, "woodLight")
        c.put(nx, 75, "wood")
        c.put(nx + 2, 75, "woodDark")
        c.put(nx + 1, 74, "stoneDark")
        c.put(nx + 1, 73, "parchment")
        c.put(nx + 1, 72, "parchment")
        c.put(nx + 1, 71, "parchment")
        c.anchor("flame", "candle", nx + 1, 70)
    # the realm's cloth over the rail
    for x in range(52, 85):
        drop = 98 + (1 if (x - 52) % 8 in (3, 4, 5) else 0)
        for y in range(80, drop + 1):
            i = (x - 52) % 8
            v = "banner"
            if i in (6, 7):
                v = "roofDeep"
            elif i == 2:
                v = "roofLight"
            if y >= drop - 1:
                v = "gold" if y == drop - 1 else "straw"
            if y == 80:
                v = "roofLight"
            c.put(x, y, v)
    for y in range(80, 99):
        c.put(51, y, "ink")
        c.put(85, y, "ink")
    st = stamps("hall")["emblem"]
    c.stamp(st, 68 - st.w // 2, 85)


def door(c, cx=68):
    """The hall door under the gallery: voussoirs on quoined jambs, two oak leaves with iron straps and ring pulls,
    a torch in an iron cup on either side."""
    x0, top, w = cx - 19, 110, 39
    opening = {p for p in arch_set(x0, top, w, WALL - top, True, 0.6) if p[1] < WALL}
    spring = min(y for (x, y) in opening if (x0, y) in opening)
    r1 = {p for p in ring(opening) if p[1] < WALL}
    r2 = {p for p in ring(opening | r1) if p[1] < WALL}
    r3 = {p for p in ring(opening | r1 | r2) if p[1] < WALL}
    r4 = {p for p in ring(opening | r1 | r2 | r3) if p[1] < WALL}
    for (x, y) in r4:
        c.put(x, y, "stoneDark")
    for (x, y) in r3:
        c.put(x, y, "stonePale" if (x < cx or y < spring) else "stoneLight")
    for (x, y) in r2:
        c.put(x, y, "stoneLight")
    for (x, y) in r1:
        c.put(x, y, "stoneDark" if x < cx else "stoneMid")
    for (x, y) in r2 | r3:
        if (y >= spring and (y - spring) % 7 == 6) or (y < spring and (x - x0) % 6 == 0):
            c.put(x, y, "stone")
    for (x, y) in opening:
        i = x - x0
        v = "wood" if (i // 4) % 3 else "woodLight"
        if i % 4 == 3:
            v = "woodDark"
        elif rnd(45, x, y // 3) < 0.06:
            v = "woodDark"
        if x == cx:
            v = "ink"
        if (x, y - 1) not in opening or (x - 1, y) not in opening:
            v = "woodDark"
        if y in (124, 125, 141, 142, 156, 157) and x != cx:
            v = "stoneDark"
            if y in (124, 141, 156) and i % 5 == 2:
                v = "stoneLight"
        c.put(x, y, v)
    for hx in (cx - 4, cx + 3):
        c.put(hx, 133, "gold")
        c.put(hx + 1, 133, "gold")
        c.put(hx - 1, 134, "gold")
        c.put(hx + 2, 134, "gold")
        c.put(hx, 135, "straw")
        c.put(hx + 1, 135, "straw")
    for tx in (cx - 30, cx + 30):
        for y in range(127, 134):
            c.put(tx, y, "ink")
        c.put(tx - 1, 127, "stoneDark")
        c.put(tx + 1, 127, "stoneDark")
        c.put(tx - 1, 126, "stoneMid")
        c.put(tx + 1, 126, "stoneMid")
        for y in range(120, 127):
            c.put(tx, y, "wood")
        for y in (117, 118, 119):
            c.put(tx - 1, y, "woodDark")
            c.put(tx, y, "soilDark")
            c.put(tx + 1, y, "woodDark")
        c.anchor("flame", "torch", tx, 116)
        c.anchor("light", "torch", tx, 116, 34)


def throne_place(c, cx=THRONE_X):
    """The cloth of estate behind the throne: a carved tester on two posts, a teal hanging with the great gold
    lantern, a fringe."""
    base = WALL - RISE
    x0, x1 = cx - 18, cx + 18
    for x in range(x0, x1 + 1):
        i = (x - x0) % 9
        for y in range(72, 151):
            v = "banner"
            if i == 3:
                v = "roofLight"
            elif i in (7, 8):
                v = "roofDeep"
            if x in (x0 + 1, x1 - 1) or y in (74, 147):
                v = "gold"
            if x in (x0, x1):
                v = "ink"
            if y >= 149:
                v = "gold" if (x + y) % 2 == 0 else "roofDeep"
            c.put(x, y, v)
    bitmap(c, LANTERN, cx - 6, 84, {"G": "gold", "y": "strawLight", "Y": "parchment"})
    for dx, dy in ((-10, 90), (10, 90), (-11, 96), (11, 96), (-9, 102), (9, 102), (0, 104), (-6, 106), (6, 106)):
        c.put(cx + dx, dy, "gold")
    # the tester
    for x in range(cx - 26, cx + 27):
        c.put(x, 62, "woodLight")
        for y in (63, 64, 65, 66):
            c.put(x, y, "wood" if rnd(46, x // 2, y) > 0.08 else "woodDark")
        c.put(x, 67, "woodDark")
        if (x - cx) % 6 == 0:
            c.put(x, 64, "gold")
            c.put(x, 65, "straw")
        depth = 3 + (2 if (x - cx) % 6 in (2, 3, 4) else 0)
        for y in range(68, 68 + depth):
            c.put(x, y, "roofDeep" if (x - cx) % 6 in (0, 5) else "banner")
        c.put(x, 68 + depth, "gold")
    c.put(cx - 27, 62, "ink")
    c.put(cx + 27, 62, "ink")
    for px in (cx - 24, cx + 22):
        post(c, px, 72, base - 1, w=3, seed=px)
        for y in (80, 81, 112, 113, 144, 145):
            for xx in (px, px + 1, px + 2):
                c.put(xx, y, "gold" if y % 2 == 0 else "straw")
    # a carved finial on the tester: the lantern's ring
    for dx, dy in ((0, 58), (-1, 59), (1, 59), (0, 60), (0, 61)):
        c.put(cx + dx, dy, "gold")


def arms(c, cx=456):
    """Right of the throne: the realm's shield over crossed spears, a two-candle sconce under it."""
    for i in range(0, 37):
        y = 112 - i
        xa = cx - 9 + int(round(i * 18 / 36.0))
        xb = cx + 9 - int(round(i * 18 / 36.0))
        for x in (xa, xb):
            c.put(x, y, "woodLight" if i < 31 else "stonePale")
            c.put(x + 1, y, "woodDark" if i < 31 else "stoneLight")
    st = stamps("hall")["crest"]
    c.stamp(st, cx - st.w // 2 + 1, 88)
    for x in range(cx - 4, cx + 5):
        c.put(x, 128, "ink")
    c.put(cx, 129, "ink")
    c.put(cx, 130, "ink")
    c.put(cx, 131, "stoneDark")
    for dx in (-4, 4):
        for y in (124, 125, 126, 127):
            c.put(cx + dx, y, "parchment")
        c.anchor("flame", "candle", cx + dx, 123)
    c.anchor("light", "candle", cx, 123, 14)


# -------------------------------------------------------------------------------------------------------- hearth

def hearth(c, cx=HEARTH_X):
    """The great hearth, the heart of the realm: a tall stone hood with the lantern carved in a niche, a mantel with
    candles, the firebox with its fire dogs and logs, a hearth stone on the dais."""
    base = WALL - RISE
    hood = set()
    for y in range(WALLTOP, 98):
        half = 13 + (y - WALLTOP) * 22 // 70
        for x in range(cx - half, cx + half + 1):
            hood.add((x, y))
    for (x, y) in hood:
        if (x + 1, y) not in hood:
            for k in (1, 2, 3):
                c.put(x + k, y, darker(c.get(x + k, y)))
    c.clip = hood
    ashlar(c, cx - 36, WALLTOP, cx + 36, 97, seed=51, course=(6, 6), width=(9, 14),
           faces=("stoneLight",) * 5 + ("stonePale", "stone"), joint="stone", deep="stoneMid", light="stonePale",
           shade="stone", pits=0.02)
    c.clip = None
    for (x, y) in hood:
        if (x - 1, y) not in hood:
            c.put(x, y, "stonePale")
        elif (x + 1, y) not in hood:
            c.put(x, y, "stoneMid")
        elif (x + 2, y) not in hood:
            c.put(x, y, "stone")
    # the niche with the lantern relief
    niche = arch_set(cx - 10, 50, 21, 34, True, 0.7)
    for (x, y) in niche:
        v = "stoneMid"
        if (x - 1, y) not in niche or (x, y - 1) not in niche:
            v = "stoneDark"
        elif (x + 1, y) not in niche:
            v = "stone"
        c.put(x, y, v)
    bitmap(c, LANTERN, cx - 6, 61, {"G": "stonePale", "y": "stone", "Y": "stonePale"})
    for x in range(cx - 11, cx + 12):
        c.put(x, 84, "stonePale")
        c.put(x, 85, "stone")
    # the mantel
    for x in range(cx - 40, cx + 41):
        c.put(x, 98, "stonePale")
        c.put(x, 99, "stoneLight")
        c.put(x, 100, "stoneLight")
        c.put(x, 101, "stone")
        if abs(x - cx) <= 38:
            c.put(x, 102, "stoneLight" if (x - cx) % 4 else "stoneMid")
            c.put(x, 103, "stoneMid")
            c.put(x, 104, "stoneDark")
    c.put(cx - 41, 98, "stoneDark")
    c.put(cx + 41, 98, "stoneDark")
    for dx in (-33, -27, 27, 33):
        tall = 4 if abs(dx) == 33 else 3
        for y in range(98 - tall, 98):
            c.put(cx + dx, y, "parchment")
        c.anchor("flame", "candle", cx + dx, 97 - tall)
    # a small casket and two cups on the mantel
    for x in range(cx - 5, cx + 6):
        c.put(x, 93, "gold" if abs(x - cx) < 5 else "straw")
        for y in (94, 95, 96, 97):
            c.put(x, y, "woodLight" if x < cx + 3 else "wood")
        c.put(x, 95, "gold")
    c.put(cx, 96, "strawLight")
    for dx in (-14, 14):
        c.put(cx + dx - 1, 94, "gold")
        c.put(cx + dx, 94, "gold")
        c.put(cx + dx + 1, 94, "straw")
        c.put(cx + dx - 1, 95, "gold")
        c.put(cx + dx, 95, "straw")
        c.put(cx + dx, 96, "gold")
        c.put(cx + dx - 1, 97, "gold")
        c.put(cx + dx, 97, "gold")
        c.put(cx + dx + 1, 97, "straw")
    # the jambs
    for side in (-1, 1):
        for y in range(105, base):
            for i in range(0, 10):
                x = cx + side * 30 - 5 + i + (0 if side < 0 else 1)
                v = "stoneLight"
                if i == 0:
                    v = "stonePale"
                elif i == 8:
                    v = "stone"
                elif i == 9:
                    v = "stoneMid"
                if (y - 105) % 9 == 8 and 0 < i < 9:
                    v = "stone"
                c.put(x, y, v)
    # the firebox
    x0, x1 = cx - 24, cx + 24
    for x in range(x0, x1 + 1):
        top = 106 + int(round(7 * (abs(x - cx) / 24.5) ** 2.4))
        for y in range(105, top):
            v = "stoneLight"
            if (x - cx) % 6 == 0:
                v = "stone"
            if y == 105:
                v = "stonePale"
            if y == top - 1:
                v = "stoneMid"
            c.put(x, y, v)
        for y in range(top, base):
            j = y - 106
            v = "soilDark"
            if j % 4 == 3 or (x + (j // 4 % 2) * 4) % 8 == 0 or y < 124:
                v = "ink"
            if y == top or x in (x0, x1):
                v = "ink"
            c.put(x, y, v)
    # fire dogs and the logs
    for dx in (-19, 18):
        for y in range(138, base):
            c.put(cx + dx, y, "stoneDark")
            c.put(cx + dx + 1, y, "ink")
        c.put(cx + dx, 137, "stoneLight")
        c.put(cx + dx + 1, 137, "stoneMid")
        c.put(cx + dx, 136, "stoneMid")
    for x in range(cx - 19, cx + 20):
        c.put(x, 151, "ink")
    st = stamps("hall")
    for name, dx, y in (("log5", -15, 146), ("log5b", -9, 146), ("log5c", -3, 146), ("log5", 3, 146),
                        ("log5b", 9, 146), ("log5c", -12, 141), ("log5", -6, 141), ("log5b", 0, 141),
                        ("log5c", 6, 141), ("log4", -4, 137), ("log4b", 1, 137)):
        c.stamp(st[name], cx + dx, y)
    c.anchor("flame", "hallFire", cx, 145, 34)   # the strip's centre column and its lowest row
    c.anchor("light", "hearth", cx, 128, 120)


def hearth_stone(c, cx=HEARTH_X):
    base = WALL - RISE
    for x in range(cx - 36, cx + 37):
        c.put(x, base, "stonePale")
        c.put(x, base + 1, "stoneLight")
        c.put(x, base + 2, "stoneLight" if (x - cx) % 9 else "stoneMid")
        c.put(x, base + 3, "stoneMid")


# --------------------------------------------------------------------------------------------------------- floor

def carpet_row(x, i):
    """The long runner, 13 rows: a dark red field between gold lines, lozenges with a gold heart."""
    if i in (1, 11):
        return "gold"
    if i in (0, 2, 10, 12):
        return "tile"
    d = abs((x % 14) - 7) + abs(i - 6)
    if d == 0:
        return "gold"
    if d == 3:
        return "tileLight"
    return "tile"


def floor(c):
    flagstones(c, 10, WALL, 589, H - 1, seed=61, grow=(2, 5))
    top = WALL - RISE
    flagstones(c, DAIS_X, top, 589, H - 1 - RISE, seed=62, colours=("stoneLight", "stone", "stoneLight", "stonePale"),
               joint="stoneMid", light="stonePale", grow=(2, 5))
    ashlar(c, DAIS_X, H - RISE, 589, H - 1, seed=63, course=(5, 4), width=(12, 20))
    for x in range(DAIS_X, 590):
        c.put(x, H - 1 - RISE, "stonePale")
        c.put(x, H - RISE, "stoneDark")
    for k in range(3):
        lift = 3 * (k + 1)
        xs = STEPS_X + 4 * k
        for x in range(xs, xs + 4):
            for y in range(WALL - lift, H - lift):
                v = "stoneLight"
                if x == xs:
                    v = "stonePale"
                elif x == xs + 3:
                    v = "stone"
                c.put(x, y, v)
            for y in range(H - lift, H):
                c.put(x, y, "stone" if x == xs else "stoneMid")
            c.put(x, H - lift, "stoneDark")
    # the runner from the door wall to the foot of the throne
    for x in range(10, THRONE_X + 22):
        lift = WALL - base_at(x)
        for i in range(13):
            c.put(x, 169 + i - lift, carpet_row(x, i))
    for i in range(13):
        if i % 2 == 0:
            c.put(THRONE_X + 22, 160 + i, "gold")
            c.put(THRONE_X + 23, 160 + i, "straw")


# ------------------------------------------------------------------------------------------------- lights' irons

def chandelier(c, cx, cy=43):
    """An iron wheel on a chain with six candles."""
    for y in range(0, cy - 15):
        c.put(cx, y, "stoneDark" if y % 3 else "stoneMid")
    for y in (cy - 15, cy - 14, cy - 13):
        c.put(cx - 1, y, "stoneDark")
        c.put(cx, y, "stoneLight" if y == cy - 14 else "stoneDark")
        c.put(cx + 1, y, "ink")
    c.line(cx, cy - 12, cx - 15, cy - 1, "ink")
    c.line(cx, cy - 12, cx + 15, cy - 1, "ink")
    c.line(cx, cy - 12, cx - 5, cy + 3, "ink")
    c.line(cx, cy - 12, cx + 5, cy + 3, "ink")
    rx, ry = 17, 4
    for x in range(cx - rx, cx + rx + 1):
        dy = int(round(ry * math.sqrt(max(0.0, 1.0 - ((x - cx) / float(rx)) ** 2))))
        c.put(x, cy - dy, "stoneDark")
        c.put(x, cy + dy, "stoneMid" if (x - cx) % 5 else "stoneLight")
        c.put(x, cy + dy + 1, "ink")
    for dx, back in ((-16, 0), (-10, 1), (-4, 0), (4, 1), (10, 0), (16, 1)):
        dy = int(round(ry * math.sqrt(max(0.0, 1.0 - (dx / float(rx)) ** 2))))
        yr = cy - dy if back else cy + dy
        for y in range(yr - 4, yr):
            c.put(cx + dx, y, "parchment" if not back else "strawLight")
        c.put(cx + dx - 1, yr, "stoneLight")
        c.put(cx + dx + 1, yr, "stoneLight")
        c.anchor("flame", "candle", cx + dx, yr - 5)
    c.anchor("light", "chandelier", cx, cy - 4, 64)


def candle_stand(c, x, foot):
    """A tall iron candle stand with three candles, standing at the wall line (its lowest row is foot - 1)."""
    for dx in (-2, -1, 0, 1, 2):
        c.put(x + dx, foot - 1, "ink")
    for dx in (-1, 0, 1):
        c.put(x + dx, foot - 2, "stoneDark")
    for y in range(foot - 23, foot - 2):
        c.put(x, y, "stoneDark" if (y - foot) % 8 else "stoneLight")
    for dx in (-3, -2, -1, 0, 1, 2, 3):
        c.put(x + dx, foot - 23, "stoneDark")
    c.put(x - 3, foot - 24, "stoneMid")
    c.put(x + 3, foot - 24, "stoneMid")
    for dx, tall in ((-3, 3), (0, 5), (3, 3)):
        for y in range(foot - 24 - tall, foot - 24):
            c.put(x + dx, y, "parchment")
        c.anchor("flame", "candle", x + dx, foot - 25 - tall)
    c.anchor("light", "stand", x, foot - 28, 26)


def end_walls(c):
    for y in range(H):
        for x in list(range(0, 10)) + list(range(591, 600)):
            v = "stoneDark"
            if y % 7 == 0 or (x + (y // 7) * 5) % 10 == 0:
                v = "ink"
            c.put(x, y, v)
        c.put(9, y, "ink")
        c.put(591, y, "ink")


# ---------------------------------------------------------------------------------------------------- the sprites

def great_hall():
    c = Canvas(W, H)
    c.rect(0, 0, W - 1, H - 1, "ink")
    roof(c)
    wall(c)
    wainscot(c)
    for cx in WINDOWS:
        tall_window(c, cx, 58, 130)
    tall_window(c, 68, 40, 74, w=22)
    rose_window(c, THRONE_X, 45)
    slit(c, HEARTH_X - 46, 60, 92)
    slit(c, HEARTH_X + 47, 60, 92)
    gallery(c)
    door(c)
    for bx in BANNERS:
        realm_banner(c, bx, BANNER_TOP)
    throne_place(c)
    arms(c)
    hearth(c)
    for sx in SHAFTS:
        shaft(c, sx)
    floor(c)
    hearth_stone(c)
    for cx in CHANDELIERS:
        chandelier(c, cx)
    for sx in STANDS:
        candle_stand(c, sx, WALL + 6)
    end_walls(c)
    return c


def hall_pillar_near():
    """A pier of the near arcade, seen close: the code draws it in front of the actors, darker and with a parallax."""
    w, h = 46, 201
    c = Canvas(w, h)
    cols = ["ink", "stonePale", "stoneLight", "stoneLight", "stoneLight", "stoneLight", "stone", "stone", "stone",
            "stone", "stone", "stone", "stone", "stone", "stoneMid", "stoneMid", "stoneMid", "stoneMid", "stoneMid",
            "stoneDark", "stoneDark", "ink"]
    for y in range(44, 183):
        for i, col in enumerate(cols):
            v = col
            if (y - 44) % 23 == 22 and 0 < i < 21:
                v = darker(col)
            elif 0 < i < 21 and rnd(71, i, y) < 0.02:
                v = darker(col)
            c.put(12 + i, y, v)
    # the capital
    for y in range(28, 44):
        half = 11 + (43 - y) * 6 // 15
        if y in (28, 29, 30):
            half = 18
        for x in range(23 - half, 23 + half):
            t = (x - (23 - half)) / float(2 * half)
            v = "stoneLight" if t < 0.3 else ("stone" if t < 0.65 else "stoneMid")
            if y in (28, 34, 40):
                v = "stonePale" if t < 0.5 else "stoneLight"
            if y in (30, 36, 43):
                v = "stoneDark"
            if x in (23 - half, 23 + half - 1):
                v = "ink"
            c.put(x, y, v)
    # the springers of two arches
    body = set()
    for y in range(0, 28):
        spread = int(round(5 * ((27 - y) / 27.0) ** 1.6))
        for x in range(5 - spread, 41 + spread):
            if 0 <= x < w:
                body.add((x, y))
    c.clip = body
    ashlar(c, 0, 0, w - 1, 27, seed=72, course=(6, 5), width=(8, 13))
    c.clip = None
    for (x, y) in body:
        if (x - 1, y) not in body or (x + 1, y) not in body:
            c.put(x, y, "ink")
        elif x > 30:
            c.put(x, y, darker(c.get(x, y)))
    # the base
    for y in range(183, h):
        half = 13 if y < 187 else (15 if y < 191 else 18)
        for x in range(23 - half, 23 + half):
            t = (x - (23 - half)) / float(2 * half)
            v = "stoneLight" if t < 0.3 else ("stone" if t < 0.65 else "stoneMid")
            if y in (183, 187, 191):
                v = "stonePale" if t < 0.5 else "stoneLight"
            if y in (186, 190):
                v = "stoneDark"
            if x in (23 - half, 23 + half - 1):
                v = "ink"
            c.put(x, y, v)
    return c


def hall_fire():
    """The great hearth's fire, an emissive strip of six frames (34x28 each): five tongues that change places, a
    white heart, gold, orange, ember tips, a few sparks. Drawn unlit over the logs."""
    fw, fh, n = 34, 28, 6
    c = Canvas(fw * n, fh)
    for f in range(n):
        tongues = []
        for k in range(5):
            tongues.append((4 + k * 6.5 + (rnd(81, f, k) - 0.5) * 4, 0.55 + 0.45 * rnd(82, f, k),
                            3.0 + 2.5 * rnd(83, f, k)))
        for x in range(fw):
            env = max(0.0, 1.0 - ((x - 16.5) / 17.0) ** 2) ** 0.7
            t = 0.0
            for (tx, amp, wid) in tongues:
                t = max(t, amp * max(0.0, 1.0 - abs(x - tx) / wid))
            hgt = int(round(fh * env * (0.38 + 0.62 * t)))
            for j in range(hgt):
                core = env * (1.0 - j / float(hgt))
                v = "ember"
                if core > 0.62:
                    v = "fireWhite"
                elif core > 0.38:
                    v = "fireGold"
                elif core > 0.16:
                    v = "fireOrange"
                c.put(f * fw + x, fh - 1 - j, v)
        for k in range(3):
            sx = 6 + int(rnd(84, f, k) * 22)
            sy = int(rnd(85, f, k) * 9)
            if c.get(f * fw + sx, sy) is None and c.get(f * fw + sx, sy + 1) is None:
                c.put(f * fw + sx, sy, "fireGold" if k else "fireOrange")
    return c


# ------------------------------------------------------------------------------------- the marks of "touch the world"

TAG = (
    "..ooooooooooo..",
    ".oGGGGGGGGGGGo.",
    "oGpppppppppppGo",
    "oGpppppppppppGo",
    "oGpppppppppppGo",
    "oGpppppppppppGo",
    "oGpppppppppppGo",
    "oGpppppppppppGo",
    "oGpppppppppppGo",
    "oGpppppppppppGo",
    "oGpppppppppppGo",
    "oGpppppppppppGo",
    "oGpppppppppppGo",
    ".oGGGGGGGGGGGo.",
    "..ooooooooooo..",
    ".....oGGGo.....",
    "......oGo......",
    ".......o.......",
)
GLYPHS = {
    "tapTalk": (          # a speech bubble: speak with the one who waits
        ".iiiiiii.",
        "i.......i",
        "i.......i",
        "i.r.r.r.i",
        "i.......i",
        ".i.iiiii.",
        ".i.i.....",
        ".ii......",
        ".i.......",
    ),
    "tapThrone": (        # the circlet: take the seat, hold the audience
        ".........",
        "....r....",
        "i...i...i",
        "ii.iii.ii",
        "iiiiiiiii",
        "i.i.r.i.i",
        "iiiiiiiii",
        ".........",
        ".........",
    ),
    "tapBuild": (         # a hammer: build or upgrade at a plot
        ".........",
        ".iiiiii..",
        ".iiiiiii.",
        ".iiiiii..",
        "...rr....",
        "...rr....",
        "...rr....",
        "...rr....",
        "...rr....",
    ),
    "tapRepair": (        # a wall with a crack: repair
        "iiiiiiiii",
        "i...ir..i",
        "iiiiriiii",
        "i.i.r.i.i",
        "iiiiiriii",
        "i...i.r.i",
        "iiiiiriii",
        "i.i..ri.i",
        "iiiiiiiii",
    ),
    "tapRecruit": (       # a head and shoulders, a plus: recruit
        "..iii..r.",
        ".iiiiirrr",
        ".iiiii.r.",
        "..iii....",
        ".........",
        ".iiiii...",
        "iiiiiii..",
        "iiiiiii..",
        "iiiiiii..",
    ),
    "tapLight": (         # a flame: light the brazier
        "....i....",
        "....ii...",
        "...iii...",
        "..iirii..",
        "..irrri..",
        ".iirgrii.",
        ".iirgrii.",
        "..iirii..",
        "...iii...",
    ),
}


def tap_mark(name):
    """A small parchment tag in the interface's ink and gold, floating above a thing the lord can touch: two frames
    of 15x18, idle and pressed. Pressing darkens the plaque, nothing moves (docs/UI-look.md). Drawn unlit."""
    def paint():
        c = Canvas(30, 18)
        for f, fill in enumerate(("parchment", "plaster")):
            bitmap(c, TAG, f * 15, 0, {"o": "ink", "G": "gold" if f == 0 else "straw", "p": fill})
            bitmap(c, GLYPHS[name], f * 15 + 3, 3, {"i": "ink", "r": "tile", "g": "gold"})
        return c
    return paint


SPRITES = {
    "greatHall": great_hall,
    "hallPillarNear": hall_pillar_near,
    "hallFire": hall_fire,
}
for _name in GLYPHS:
    SPRITES[_name] = tap_mark(_name)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    p = sub.add_parser("build")
    p.add_argument("id")
    p.add_argument("--out")
    sub.add_parser("list")
    p = sub.add_parser("anchors")
    p.add_argument("id")
    a = ap.parse_args()
    if a.cmd == "list":
        print(" ".join(SPRITES))
        return
    fn = SPRITES.get(a.id)
    if fn is None:
        raise SystemExit(f"unknown sprite {a.id} (hallart.py list)")
    canvas = fn()
    if a.cmd == "anchors":
        for an in canvas.anchors:
            print(" ".join(str(v) for v in an))
        return
    out = os.path.join(a.out or ART, a.id + ".png")
    canvas.save(out)
    print(f"wrote {out} {canvas.w}x{canvas.h}")


if __name__ == "__main__":
    main()
