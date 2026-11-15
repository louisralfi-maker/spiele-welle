#!/usr/bin/env python3
"""Lanternhold: the Lantern Table's art (docs/QUESTS.md section 6; the quests lane, step quests-3).

Hand-set pixel art on the shared palette (tools/palette.txt), drawn from rules and text grids, never generated: the
whole oak table the screen stands on (the slab, planks running off every edge of the screen) with the realm carved into
it inside one groove, the Wend inlaid in the realm's teal, the downs and woods as hand-drawn relief lit from the
north-west, the Weltmauer peak by peak, the castle with the house's flame in gold leaf, and Lord Edric's planed west
across the table's whole depth; the realm cut from the slab as the table top; the two knife-scratch overlays and the
span for the bare wood and the old bridge, the cloth of day 1, the brass place pins (house pins in the house's colour),
the burning road lantern and the boxwood tokens on the table, and the hook rail of the screen (the board, the iron hook,
the lantern dark, blank, kept in red cloth and lit, the soot and chalk of a lost lantern, the plates' figures in the
interface kit's face), and Odile's seal. One texel is one table pixel; the screen draws them at whole device pixels.

Every position on the table comes from Resources/TableArt/table-map.json, which UI/Table/TableMap.swift reads too, so
the pins, lanterns and lines of light stand exactly on what is carved here.

  tableart.py build <id> [--out DIR] [--zoom N]   writes <id>.png into DIR (default games/lanternhold/Resources/TableArt)
  tableart.py list                                the ids

Pure python 3 (pixelart.py's PNG and palette code), deterministic, well under a second per image. Run every build
through the art lock (ci-out/director/artlock.sh), one image per call.
"""
import argparse
import json
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from pixelart import Image, Palette, write_png, DEFAULT_PALETTE  # noqa: E402

GAME = os.path.dirname(HERE)
OUT = os.path.join(GAME, "Resources", "TableArt")
MAP = json.load(open(os.path.join(OUT, "table-map.json")))


# ------------------------------------------------------------------------------------------------------------ canvas

class Grid:
    """A picture of palette names (None is clear)."""

    def __init__(self, w, h, fill=None):
        self.w = w
        self.h = h
        self.c = [[fill] * w for _ in range(h)]

    def inside(self, x, y):
        return 0 <= x < self.w and 0 <= y < self.h

    def set(self, x, y, name):
        if self.inside(x, y):
            self.c[y][x] = name

    def get(self, x, y):
        return self.c[y][x] if self.inside(x, y) else None

    def stamp(self, rows, legend, x0, y0, mirror=False):
        """Draws a text grid: '.' leaves the pixel, any other letter is looked up in `legend`."""
        for dy, row in enumerate(rows):
            if mirror:
                row = row[::-1]
            for dx, ch in enumerate(row):
                if ch == ".":
                    continue
                self.set(x0 + dx, y0 + dy, legend[ch])

    def image(self, pal):
        img = Image(self.w, self.h)
        for y in range(self.h):
            for x in range(self.w):
                n = self.c[y][x]
                if n is not None:
                    r, g, b = pal.color(n)
                    img.set(x, y, (r, g, b, 255))
        return img


def bresenham(x0, y0, x1, y1):
    pts = []
    dx = abs(x1 - x0)
    dy = -abs(y1 - y0)
    sx = 1 if x0 < x1 else -1
    sy = 1 if y0 < y1 else -1
    err = dx + dy
    while True:
        pts.append((x0, y0))
        if x0 == x1 and y0 == y1:
            return pts
        e2 = 2 * err
        if e2 >= dy:
            err += dy
            x0 += sx
        if e2 <= dx:
            err += dx
            y0 += sy


def polyline(points):
    out = []
    for (a, b) in zip(points, points[1:]):
        seg = bresenham(a[0], a[1], b[0], b[1])
        if out and out[-1] == seg[0]:
            seg = seg[1:]
        out.extend(seg)
    return out


class Rand:
    """A small deterministic stream (the art never changes between builds)."""

    def __init__(self, seed):
        self.s = seed & 0xFFFFFFFF

    def next(self):
        self.s = (1103515245 * self.s + 12345) & 0x7FFFFFFF
        return self.s >> 8

    def range(self, a, b):
        return a + self.next() % (b - a + 1)


def disc(cx, cy, rx, ry):
    """Pixels of a filled ellipse."""
    pts = []
    for y in range(int(cy - ry) - 1, int(cy + ry) + 2):
        for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
            if ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 <= 1.0:
                pts.append((x, y))
    return pts


# ----------------------------------------------------------------------------------------------------- the table top

W, H = MAP["size"]
PLANED = MAP["planed"]
HOME = tuple(MAP["home"])
PLACES = {p["id"]: p for p in MAP["places"]}
SW, SH = MAP["slab"]["size"]   # the whole table the screen stands on
SX, SY = MAP["slab"]["realm"]  # where the carved realm (the 300 x 150 table top) lies in it
SEAMS = [33, 62, 91, 120]      # the oak's plank seams (rows of the realm); every 29 rows across the slab
LOW = H - 3                    # the frame's south groove (row 147): the carving lies above it
EAST = W - 3                   # the frame's east groove (column 297)


class Offset:
    """The realm's carving drawn straight onto the slab: realm coordinates in, slab pixels out."""

    def __init__(self, g, dx, dy):
        self.g = g
        self.dx = dx
        self.dy = dy
        self.w = W
        self.h = H

    def inside(self, x, y):
        return 0 <= x < self.w and 0 <= y < self.h

    def set(self, x, y, name):
        if self.inside(x, y):
            self.g.set(x + self.dx, y + self.dy, name)

    def get(self, x, y):
        return self.g.get(x + self.dx, y + self.dy) if self.inside(x, y) else None

    def stamp(self, rows, legend, x0, y0, mirror=False):
        Grid.stamp(self, rows, legend, x0, y0, mirror)


def carved_route(place):
    pts = [HOME] + [tuple(p) for p in place["route"]] + [tuple(place["pin"])]
    return polyline(pts)


def flowing_grain(g, x0, x1, y0, y1, r, color, spacing, amp, period, knots=(), cover=0.7, keep=None):
    """Long grain lines that wave gently and bend round the knots; each runs for part of the width only."""
    lines = (y1 - y0) // spacing + 1
    for k in range(lines):
        base = y0 + k * spacing + r.range(0, spacing - 1)
        phase = r.range(0, 628) / 100.0
        length = int((x1 - x0) * (cover + (r.range(0, 30) / 100.0)))
        start = x0 + r.range(0, max(0, (x1 - x0) - length))
        prev = None
        for x in range(start, min(x1, start + length)):
            y = base + amp * math.sin(2 * math.pi * x / period + phase)
            for (kx, ky, kr) in knots:
                d = (x - kx) / (kr * 2.2)
                if abs(d) < 1.0 and abs(base - ky) < kr * 3:
                    push = (kr * 1.6) * (1 - d * d) * (1 if base >= ky else -1)
                    y += push * (1 - abs(base - ky) / (kr * 3))
            yi = int(round(y))
            col = [yi] if prev is None or abs(yi - prev) <= 1 else list(range(min(yi, prev) + 1, max(yi, prev) + 1))
            for yy in col:
                if y0 <= yy < y1 and (keep is None or keep(x, yy)):
                    g.set(x, yy, color)
            prev = yi


def slab_seams():
    """The seams' rows on the slab, in step with the realm's."""
    return list(range((SY + SEAMS[0]) % 29, SH, 29))


def knot(g, kx, ky, kr, ring, core):
    for (x, y) in disc(kx, ky, kr + 0.8, kr * 0.6 + 0.4):
        g.set(x, y, ring)
    for (x, y) in disc(kx, ky, kr - 0.6, max(0.5, kr * 0.3)):
        g.set(x, y, core)


# Plank ends on the bare slab, never inside the carving's frame: (the seam row above the plank, x).
JOINTS = [(15, 236), (15, 398), (44, 344), (73, 421), (102, 333), (131, 389), (160, 352), (189, 120), (189, 410)]


def slab_ground(g, r):
    """The waxed oak of the whole table (the critic of quests-3: the table is the screen's ground): planks running east
    and west, their seams every 29 rows, a quiet long grain, two knots and the plank ends, outside the carving."""
    for y in range(SH):
        for x in range(SW):
            g.set(x, y, "wood")
    seams = slab_seams()
    knots = [(262, 24, 2), (380, 120, 2)]
    for top, bottom in zip([0] + seams, seams + [SH]):
        flowing_grain(g, 0, SW, top + 2, bottom - 1, r, "soilLight", 6, 0.8, 150, knots, cover=0.5)
    for (kx, ky, kr) in knots:
        knot(g, kx, ky, kr, "soilLight", "woodDark")
    for sy in seams:
        for x in range(SW):
            g.set(x, sy, "woodDark")
            if (x - SX) % 37 == 5:
                g.set(x, sy + 1, "soil")
    for (seam, x) in JOINTS:
        for y in range(max(0, seam + 1), min(SH, seam + 29)):
            if SX - 1 <= x <= SX + W and SY - 1 <= y <= SY + H:
                continue
            g.set(x, y, "woodDark")
            g.set(x + 1, y, "woodLight")


def planed_band(g, r):
    """Lord Edric's planed west, across the whole table: raw oak lighter than the waxed east, its grain flowing round
    two knots, the seams in the lighter wood, and the cut where the carving was planed away."""
    edge = SX + PLANED
    knots = [(68, 148, 2), (84, 27, 2)]
    for y in range(SH):
        for x in range(edge):
            g.set(x, y, "straw")
    seams = slab_seams()
    for top, bottom in zip([0] + seams, seams + [SH]):
        flowing_grain(g, 0, edge - 1, top + 1, bottom, r, "plasterDim", 4, 0.9, 90, knots, cover=0.8)
        flowing_grain(g, 0, edge - 1, top + 2, bottom, r, "woodLight", 13, 1.1, 120, knots, cover=0.55)
        flowing_grain(g, 0, edge - 1, top + 1, bottom, r, "strawLight", 9, 0.8, 100, knots, cover=0.35)
    for sy in seams:
        for x in range(edge):
            g.set(x, sy, "woodLight")
    for (kx, ky, kr) in knots:
        knot(g, kx, ky, kr, "woodLight", "wood")
    # the cut: the step's face catches the light from the west, the waxed edge above it a shade darker
    for y in range(SH):
        g.set(edge, y, "strawLight")
        g.set(edge + 1, y, "woodDark")


def frame(g):
    """The carving's one frame: a groove cut round the realm on the north, east and south (the plane took the west),
    dark on its near wall and lit on its far one."""
    for x in range(PLANED + 2, W - 1):
        g.set(x, 1, "soilDark")
        g.set(x, 2, "woodLight")
        g.set(x, LOW, "soilDark")
        g.set(x, LOW + 1, "woodLight")
    for y in range(1, LOW + 1):
        g.set(EAST, y, "soilDark")
    for y in range(2, LOW + 2):
        g.set(EAST + 1, y, "woodLight")


# ------------------------------------------------------------------------------------------------- carved relief

def emboss(g, rows, x0, y0):
    """A carved relief from a hand-drawn mask (the critic of quests-3: carved, not piled). Each lowercase letter is one
    raised piece and its uppercase twin the piece's upper step. The light comes from the north-west: a piece's north
    and west edges catch it, its south and east edges fall into shade, and the undercut throws a one-pixel shadow on the
    field to the south-east. The tops keep the oak's own colour, so the shape is told by its edges, as in a carving."""
    cells = {}
    for dy, row in enumerate(rows):
        for dx, ch in enumerate(row):
            if ch != ".":
                cells[(x0 + dx, y0 + dy)] = (ch.lower(), ch.isupper())
    _relief(g, cells)


def _relief(g, cells):
    def piece(p):
        return cells[p][0] if p in cells else None

    def upper(p, name):
        return p in cells and cells[p][0] == name and cells[p][1]

    for (x, y) in cells:
        q = (x + 1, y + 1)
        if q not in cells:
            g.set(q[0], q[1], "woodDark")
    for (x, y), (name, up) in cells.items():
        n = piece((x, y - 1)) != name
        w = piece((x - 1, y)) != name
        s = piece((x, y + 1)) != name
        e = piece((x + 1, y)) != name
        colour = None
        if n and w:
            colour = "straw"
        elif n or w:
            colour = "woodLight"
        elif s and e:
            colour = "woodDark"
        elif s or e:
            colour = "soil"
        elif up:
            un = not upper((x, y - 1), name)
            uw = not upper((x - 1, y), name)
            us = not upper((x, y + 1), name)
            ue = not upper((x + 1, y), name)
            if un and uw:
                colour = "straw"
            elif un or uw:
                colour = "woodLight"
            elif us or ue:
                colour = "soil"
        g.set(x, y, colour or "wood")


# The downs, each drawn by hand (lowercase: the down; uppercase: its upper step). No two alike.
DOWNS = {
    "long": [
        "....aaaaa........",
        "..aaaAAAAaaaa....",
        ".aaAAAAAAAAaaaa..",
        "aaaaAAAAAAaaaaaaa",
        ".aaaaaaaaaaaaaaa.",
        "....aaaaaaaa.....",
    ],
    "knoll": [
        "...aaaa....",
        ".aaaAAaaa..",
        "aaAAAAAaaa.",
        ".aaaAAaaaaa",
        "...aaaaaa..",
    ],
    "twin": [
        "...aaaaa........bbbb...",
        ".aaaAAAaaa...bbbBBbbb..",
        "aaaAAAAAaaaabbbBBBBbbb.",
        ".aaaaAAaaaaa.bbbBBbbbbb",
        "..aaaaaaaaa...bbbbbbbb.",
        ".....aaaa.......bbbb...",
    ],
    "ridge": [
        "aaaa............",
        ".aaaaaaa........",
        "..aaAAAAaaa.....",
        "....aaaAAAAaaa..",
        ".......aaaAAaaaa",
        "..........aaaaa.",
    ],
    "swell": [
        "..aaaaa..",
        "aaaaaaaaa",
        "..aaaaaa.",
    ],
    "shoulder": [
        ".aaaa........",
        "aaAAaaaaaa...",
        "aaAAAAAAaaaa.",
        ".aaaaaAAAaaaa",
        "...aaaaaaaa..",
    ],
    "low": [
        "..aaaa..",
        ".aaAAaa.",
        "aaaaaaaa",
        "..aaaa..",
    ],
    "tiny": [
        ".aaaa..",
        "aaAaaaa",
        ".aaaaa.",
    ],
    "bean": [
        ".aaaa..aaa.",
        "aaAAaaaaaaa",
        ".aaaaaaaaaa",
        "...aaaaa...",
    ],
}
DOWNS_AT = [("knoll", 132, 17), ("long", 158, 12), ("shoulder", 188, 25), ("twin", 216, 20), ("bean", 262, 20),
            ("low", 278, 62), ("ridge", 236, 78), ("swell", 197, 93), ("tiny", 154, 65), ("knoll", 279, 100),
            ("low", 201, 43), ("tiny", 283, 41)]

# Tree crowns, and the woods composed of them by hand: (crown, dx, dy), back to front. A wood is carved as one raised
# mass whose edge follows its crowns; inside, each crown is marked by a glint on its north-west and a short cut on its
# south-east, the way a carver cuts a forest: a clear shape and few marks.
CROWNS = {
    "o": [".aa.", "aaaa", "aaaa", ".aa."],
    "O": [".aaa.", "aaaaa", "aaaaa", ".aaa."],
    "Q": [".aaaa.", "aaaaaa", "aaaaaa", "aaaaaa", ".aaaa."],
    "v": [".aaa", "aaaa", "aaa."],
}
WOODS = {
    "great": [("Q", 3, 0), ("O", 9, 0), ("o", 14, 1), ("O", 0, 3), ("Q", 7, 4), ("O", 13, 4), ("o", 3, 7),
              ("O", 10, 8), ("v", 15, 8)],
    "east": [("O", 2, 0), ("o", 7, 0), ("v", 11, 1), ("Q", 0, 3), ("O", 6, 4), ("o", 11, 4), ("v", 5, 7)],
    "shore": [("v", 0, 1), ("O", 3, 0), ("o", 8, 0), ("O", 12, 1), ("o", 6, 2)],
    "copse": [("O", 0, 0), ("o", 4, 1), ("v", 1, 3)],
    "north": [("o", 0, 1), ("O", 3, 0), ("v", 8, 0), ("o", 11, 1), ("O", 6, 2)],
    "grove": [("o", 0, 0), ("O", 3, 1), ("v", 1, 3)],
    "strand": [("O", 0, 0), ("v", 4, 1), ("o", 7, 0)],
    "spinney": [("v", 0, 0), ("O", 3, 0), ("o", 2, 2)],
}
WOODS_AT = [("great", 219, 59), ("east", 255, 84), ("shore", 198, 127), ("copse", 186, 77), ("north", 275, 13),
            ("grove", 180, 47), ("strand", 236, 128), ("spinney", 230, 92)]


def wood(g, name, x0, y0):
    """A wood: one raised mass with a scalloped edge, each crown marked inside it."""
    cells = {}
    crowns = []
    for (crown, dx, dy) in WOODS[name]:
        rows = CROWNS[crown]
        for ry, row in enumerate(rows):
            for rx, ch in enumerate(row):
                if ch != ".":
                    cells[(x0 + dx + rx, y0 + dy + ry)] = ("a", False)
        crowns.append((x0 + dx, y0 + dy, len(rows[0]), len(rows)))
    _relief(g, cells)
    interior = {p for p in cells if g.get(*p) == "wood"}
    for (x, y, w, h) in crowns:
        if (x + 1, y + 1) in interior:
            g.set(x + 1, y + 1, "woodLight")
        for p in [(x + w - 2, y + h - 1), (x + w - 3, y + h - 1), (x + w - 1, y + h - 2)]:
            if p in interior:
                g.set(p[0], p[1], "soil")


def land(g):
    """The downs north of the valley under Highcairn and the long downs of the Morninglands, and the woods."""
    for (name, x, y) in DOWNS_AT:
        emboss(g, DOWNS[name], x, y)
    for (name, x, y) in WOODS_AT:
        wood(g, name, x, y)


# ---------------------------------------------------------------------------------------------- the Weltmauer

def peak(g, ax, ay, hl, hr, h, crease=False):
    """A carved mountain: its west face lit, its east face in shade, a lit ridge and a dark east edge."""
    for dy in range(h):
        t = dy / max(1, h - 1)
        left = round(t * hl)
        right = round(t * hr)
        for x in range(ax - left, ax + right + 1):
            g.set(x, ay + dy, "woodLight" if x < ax else ("soil" if x > ax else "straw"))
        if dy > 0:
            g.set(ax - left, ay + dy, "straw")
            g.set(ax + right, ay + dy, "woodDark")
    g.set(ax, ay, "strawLight")
    if crease and h >= 6:
        # a gully down the lit face
        for dy in range(2, h - 1):
            x = ax - 1 - dy // 2
            if g.get(x, ay + dy) == "woodLight":
                g.set(x, ay + dy, "tile")


# The Weltmauer peak by peak, placed by hand (apex x, apex y, west spread, east spread, height, a gully): a crest that
# wanders, two giants, the guardians either side of the cleft, smaller peaks the plane cut off in the west, a few low
# foothills east. No two stand in a row.
PEAKS = [
    # north: the west, cut by the plane
    (94, 4, 4, 3, 6, False), (100, 10, 3, 4, 5, False), (92, 16, 3, 3, 5, False), (97, 22, 5, 4, 7, False),
    (103, 31, 3, 3, 4, False), (93, 35, 4, 3, 6, False), (99, 42, 3, 4, 5, False), (93, 52, 3, 2, 4, False),
    (95, 62, 3, 4, 6, False), (104, 65, 3, 3, 5, False),
    # north: the crest
    (109, 3, 6, 5, 9, True), (116, 6, 5, 6, 8, True), (111, 14, 7, 6, 11, True), (119, 20, 4, 5, 7, True),
    (106, 26, 5, 4, 8, True), (114, 30, 6, 7, 10, True), (110, 41, 5, 5, 8, True), (118, 44, 5, 4, 7, True),
    (108, 50, 6, 5, 9, True), (115, 54, 7, 6, 10, True), (111, 61, 6, 5, 9, True), (119, 63, 4, 4, 6, True),
    # north: the foothills east
    (125, 4, 3, 2, 4, False), (129, 12, 2, 3, 3, False), (123, 26, 3, 3, 5, False), (128, 34, 2, 2, 3, False),
    (124, 47, 3, 2, 4, False), (130, 52, 2, 3, 3, False), (125, 58, 3, 3, 5, False), (123, 66, 2, 2, 3, False),
    # south: the west
    (93, 90, 3, 4, 6, False), (97, 113, 4, 3, 6, False), (92, 120, 3, 3, 5, False), (100, 124, 3, 4, 6, False),
    (94, 131, 4, 3, 6, False), (102, 136, 3, 3, 5, False), (93, 140, 3, 3, 5, False),
    # south: the crest
    (113, 90, 6, 6, 9, True), (108, 99, 5, 5, 7, True), (117, 101, 5, 6, 9, True), (113, 110, 6, 6, 10, True),
    (120, 116, 4, 4, 6, True), (107, 119, 5, 5, 8, True), (114, 124, 6, 6, 9, True), (109, 132, 5, 5, 8, True),
    (117, 135, 5, 4, 7, True), (112, 139, 6, 5, 7, True),
    # south: the foothills east
    (124, 92, 3, 2, 4, False), (122, 110, 2, 3, 4, False), (126, 118, 3, 2, 3, False), (123, 127, 3, 3, 5, False),
    (127, 138, 2, 3, 4, False),
]


# The Weltmauer's shelf under the peaks, its east foot by hand (row, x), drawn in between: the wall is one raised mass
# and the peaks stand on it, opening only at the cleft.
SHELF_NORTH = [(3, 133), (10, 131), (18, 134), (27, 130), (36, 132), (45, 129), (53, 133), (60, 130), (66, 127),
               (70, 123)]
SHELF_SOUTH = [(90, 124), (95, 128), (103, 125), (111, 129), (120, 127), (128, 130), (136, 128), (143, 131),
               (146, 130)]


def shelf_edge(points, y):
    for (y0, x0), (y1, x1) in zip(points, points[1:]):
        if y0 <= y <= y1:
            return round(x0 + (x1 - x0) * (y - y0) / max(1, y1 - y0))
    return None


def shelf(g):
    cells = {}
    for points in (SHELF_NORTH, SHELF_SOUTH):
        for y in range(points[0][0], points[-1][0] + 1):
            for x in range(PLANED + 2, shelf_edge(points, y) + 1):
                cells[(x, y)] = ("a", False)
    _relief(g, cells)


def mountains(g):
    """The Weltmauer: its shelf, a ridge of overlapping carved peaks on it, the one cleft at home, the Throat running west
    from it."""
    shelf(g)
    for (ax, ay, hl, hr, h, crease) in sorted(PEAKS, key=lambda p: p[1] + p[4]):
        h = min(h, LOW - ay)
        if h >= 3:
            peak(g, ax, ay, hl, hr, h, crease)
    # the Throat: a narrow gorge cut west from the cleft to the planed edge
    for x in range(PLANED + 2, 112):
        for y in range(77, 84):
            g.set(x, y, "soil")
        g.set(x, 76, "soilDark")
        g.set(x, 84, "woodLight")


# The castle in the cleft, the clear centre of the table: two towers, the curtain wall with its gate, the keep, and the
# house's flame over it in gold leaf (the screen lays its light over the flame).
CASTLE = [
    ".........g.........",
    "........gGg........",
    "........GwG........",
    ".......gGwGg.......",
    ".......KsssK.......",
    "K.K.K..KLMDK..K.K.K",
    "KKKKK..KLMDK..KKKKK",
    "KLMDK..KLMDK..KLMDK",
    "KLMDKK.KLGDK.KKLMDK",
    "KLMDKKKKLMDKKKKLMDK",
    "KLMDKLMMMMMMMDKLMDK",
    "KLMDKLMMKKKMMDKLMDK",
    "KLMDKLMKDDDKMDKLMDK",
    "KLMDKLMKD.DKMDKLMDK",
    "KLMDKLMKD.DKMDKLMDK",
    "KKKKKKKKK.KKKKKKKKK",
    ".DDDDDDDD.DDDDDDDD.",
]
CASTLE_LEGEND = {"K": "woodDark", "L": "strawLight", "M": "woodLight", "D": "soil", "G": "gold", "g": "fireGold",
                 "w": "fireWhite", "s": "straw"}
# The flame's centre in table pixels, for the screen's light (UI/Table/TableScreen.swift reads it from table-map.json).
FLAME = (HOME[0], HOME[1] - 6)


def castle(g):
    x0 = HOME[0] - 9
    y0 = HOME[1] - 8
    # the cleft's floor round it
    for x in range(110, 131):
        for y in range(71, 90):
            if g.get(x, y) in ("tile", "soil", "soilDark", "woodLight", "woodDark", "strawLight", "straw"):
                g.set(x, y, "wood")
    g.stamp(CASTLE, CASTLE_LEGEND, x0, y0)


def wend(g):
    """The river inlaid in the realm's teal: a channel two pixels wide in a dark seam, glints on its upper edge."""
    pts = polyline([tuple(p) for p in MAP["wend"]])
    core = set()
    for (x, y) in pts:
        core.add((x, y))
        core.add((x + 1, y))
    border = set()
    for (x, y) in core:
        for (dx, dy) in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            n = (x + dx, y + dy)
            if n not in core:
                border.add(n)
    for (x, y) in border:
        if y < LOW:
            g.set(x, y, "roofDeep")
    for (x, y) in core:
        if y < LOW:
            g.set(x, y, "banner")
    for i, (x, y) in enumerate(pts):
        if i % 9 in (0, 1, 2) and y < LOW - 1:
            g.set(x, y, "roofLight")


def mere(g):
    cx, cy, rx, ry = MAP["mere"]
    inner = set(disc(cx, cy, rx, ry))
    outer = set(disc(cx, cy, rx + 1, ry + 1)) - inner
    for (x, y) in outer:
        g.set(x, y, "roofDeep")
    for (x, y) in inner:
        g.set(x, y, "banner")
    for (x, y) in [(cx - 4, cy - 2), (cx - 3, cy - 2), (cx - 2, cy - 2), (cx + 2, cy), (cx + 3, cy)]:
        g.set(int(x), int(y), "roofLight")


def shore_y(x):
    return MAP["coast"] + round(2.2 * math.sin(x / 11.0) + 1.4 * math.sin(x / 4.7 + 1.3))


def sea(g):
    """The south coast: the land stands over a lower sea; the shore in shade, carved swells on the water."""
    mouth = MAP["wend"][-1][0]
    for x in range(124, EAST):
        y = shore_y(x)
        for yy in range(y + 1, LOW):
            g.set(x, yy, "soil")
        g.set(x, y, "woodDark")
    rows = [(MAP["coast"] + 3, 0), (MAP["coast"] + 5, 4)]
    for row, shift in rows:
        for x in range(127 + shift, EAST - 4, 8):
            if abs(x + 2 - mouth) <= 4 or row <= shore_y(x) + 1 or row <= shore_y(x + 3) + 1:
                continue
            for dx in range(4):
                if row < LOW:
                    g.set(x + dx, row, "wood")
            g.set(x + 1, row - 1, "woodLight")
            g.set(x + 2, row - 1, "woodLight")


def roads(g):
    """The carved roads: a groove with a lit lip, home to every place (to the planed edge for the Moor Road)."""
    drawn = set()
    for place in MAP["places"]:
        for (x, y) in carved_route(place):
            if x <= PLANED + 1:
                continue
            drawn.add((x, y))
    for (x, y) in drawn:
        if (x, y + 1) not in drawn:
            g.set(x, y + 1, "woodLight")
    for (x, y) in drawn:
        g.set(x, y, "soilDark")


ICON_LEGEND = {"S": "strawLight", "L": "straw", "s": "woodLight", "D": "soil", "m": "tile", "K": "woodDark",
               "G": "gold"}
ICONS = {
    # Tallowford: a huddle of roofs and the chapel's spire
    "town": ([
        "......S......",
        ".....LsD.....",
        "..L..LsD..L..",
        ".LsD.LsD.LsD.",
        "LssDLssDLssDD",
        "LmmDLmmDLmmDD",
        "KKKKKKKKKKKKK",
    ], -15, 2),
    # the windmill and its four sails
    "mill": ([
        "S.....D",
        ".S...D.",
        "..SKD..",
        "..LKD..",
        ".DLsDS.",
        "D.LsD.S",
        "..LsD..",
        "..KKK..",
    ], 6, -10),
    # Highcairn: a keep on its cairn
    "cairn": ([
        "...LsD...",
        "...LKD...",
        "..LssDD..",
        ".LssssDD.",
        "LssssssDD",
        "KKKKKKKKK",
    ], -15, -4),
    # Greybell: the bell tower
    "bell": ([
        "..S..",
        ".LsD.",
        ".LsD.",
        "LsGsD",
        "LGGGD",
        "LsssD",
        "LsKsD",
        "KKKKK",
    ], 7, -6),
    # Saltgate: two towers and the sea gate
    "gate": ([
        "LD...LD",
        "LsDDDsD",
        "LsKKKsD",
        "LsK.KsD",
        "KKK.KKK",
    ], -14, -3),
    # Goldenacre: furrowed fields and a barn
    "fields": ([
        "....LsD.......",
        "...LssDD......",
        "...LmmDD.S.S.S",
        "...KKKK.D.D.D.",
        "S.S.S.S.S.S.S.",
        ".D.D.D.D.D.D.D",
    ], -18, 1),
    # the Great Beacon: a tower with its iron basket
    "tower": ([
        "K.K.K",
        "KGGGK",
        ".LsD.",
        ".LsD.",
        ".LKD.",
        ".LsD.",
        "LssDD",
        "KKKKK",
    ], 6, -6),
    # Beaconfoot: three huts
    "huts": ([
        ".L...L...L.",
        "LsDLLsDLLsD",
        "LmDDLmDDLmD",
        "KKKKKKKKKKK",
    ], 6, 2),
}
ICON_OF = {"tallowford": "town", "windmill": "mill", "highcairn": "cairn", "greybell": "bell", "saltgate": "gate",
           "goldenacre": "fields", "beacon": "tower", "beaconfoot": "huts"}


def icons(g):
    for pid, name in ICON_OF.items():
        rows, dx, dy = ICONS[name]
        px, py = PLACES[pid]["pin"]
        g.stamp(rows, ICON_LEGEND, px + dx, py + dy)
    # the old bridge's stumps, either side of the Wend
    bx, by = MAP["bridge"]
    for sx in (bx - 5, bx + 5):
        g.stamp(["LD", "DK"], {"L": "straw", "D": "soil", "K": "woodDark"}, sx, by - 1)


def pin_shadows(g):
    """Where each pin stands, its shadow falls to the lower right."""
    for place in MAP["places"]:
        if place["pins"] == "none":
            continue
        cx, cy = place["pin"]
        for y in range(cy - 6, cy + 8):
            for x in range(cx - 6, cx + 8):
                inside_pin = (x - cx) ** 2 + (y - cy) ** 2 <= 4.6 ** 2
                in_shadow = (x - cx - 1.3) ** 2 + (y - cy - 1.3) ** 2 <= 4.6 ** 2
                if in_shadow and not inside_pin:
                    g.set(x, y, "soilDark")


def slab():
    """The whole table the screen stands on: the waxed oak, the realm carved into it at (SX, SY) inside its frame, and
    the planed west across the full depth of the table."""
    g = Grid(SW, SH)
    slab_ground(g, Rand(0x51AB))
    realm = Offset(g, SX, SY)
    land(realm)
    sea(realm)
    mountains(realm)
    roads(realm)
    wend(realm)
    mere(realm)
    icons(realm)
    pin_shadows(realm)
    castle(realm)
    frame(realm)
    planed_band(g, Rand(0x7AB1E))
    return g


def table_top():
    """The carved realm cut from the slab, pixel for pixel: the screen draws the slab and lays this picture (with its
    pins and lines of light) exactly over its place."""
    s = slab()
    g = Grid(W, H)
    for y in range(H):
        for x in range(W):
            g.set(x, y, s.get(SX + x, SY + y))
    return g


# ------------------------------------------------------------------------------------------- the bare wood's scratches

def scratch(g, pts):
    """A knife line in the bare wood: a dark cut with a light lip under it."""
    s = set(pts)
    for (x, y) in pts:
        if (x, y + 1) not in s:
            g.set(x, y + 1, "strawLight")
    for (x, y) in pts:
        g.set(x, y, "wood")


MOOR_ROAD = [(PLANED - 1, 81), (72, 80), (56, 79), (40, 80), (24, 79), (10, 78)]


def west_one():
    """What the scouts saw from the stair: the Moor Road with sixty statues, one plinth empty."""
    g = Grid(96, H)
    road = polyline(MOOR_ROAD)
    scratch(g, road)
    ys = {}
    for (x, y) in road:
        ys.setdefault(x, y)
    xs = []
    x = PLANED - 4
    gap = [2, 3]
    i = 0
    while len(xs) < 30:
        xs.append(x)
        x -= gap[i % 2]
        i += 1
    # the empty plinth stands where every phone shows it, west of the planed edge but clear of the screen's corner
    empty = xs[5]
    for side in (-1, 1):
        for x in xs:
            y = ys.get(x, 80)
            top = y - 4 if side < 0 else y + 3
            if side < 0 and x == empty:
                g.set(x, y - 2, "wood")  # the plinth, nobody on it
                continue
            g.set(x, top, "wood")
            g.set(x, top + 1, "wood")
    return g


def west_two():
    """What the lamp room saw: the moor's edge, and far out one low light that never flickers. Drawn in the strip of
    bare wood every phone shows (the table runs off the screen's west edge)."""
    g = Grid(96, H)
    r = Rand(0x30E)
    edge = []
    x = 70
    for y in range(14, 138):
        if y % 6 == 0:
            x += 1 if r.next() % 2 else -1
            x = max(66, min(74, x))
        edge.append((x, y))
    scratch(g, [(x, y) for (x, y) in edge if not (70 <= y <= 90)])
    # tussocks west of the edge: small v cuts
    for (tx, ty) in [(52, 22), (60, 34), (49, 46), (57, 98), (48, 112), (61, 124), (53, 132), (62, 58), (50, 92)]:
        scratch(g, [(tx, ty), (tx + 1, ty + 1)])
        scratch(g, [(tx + 2, ty)])
    # the light: a small ring with its point, north of the Throat's line where no corner of a phone hides it
    lx, ly = 58, 30
    ring = [(lx - 1, ly - 2), (lx, ly - 2), (lx + 1, ly - 2), (lx + 2, ly - 1), (lx + 2, ly), (lx + 2, ly + 1),
            (lx - 2, ly - 1), (lx - 2, ly), (lx - 2, ly + 1), (lx - 1, ly + 2), (lx, ly + 2), (lx + 1, ly + 2)]
    for (x, y) in ring:
        g.set(x, y, "wood")
    g.set(lx, ly, "woodDark")
    for (x, y) in [(lx - 1, ly + 3), (lx, ly + 3), (lx + 1, ly + 3)]:
        g.set(x, y, "strawLight")
    return g


SPAN = [
    "................",
    ".KKKKKKKKKKKKKK.",
    "KHHHHHHHHHHHHHHK",
    "KHsHsHsHsHsHsHsK",
    "KssssssssssssssK",
    "KmmmmmmmmmmmmmmK",
    ".KKKKKKKKKKKKKK.",
    "................",
]


def span():
    g = Grid(16, 8)
    g.stamp(SPAN, {"K": "woodDark", "H": "strawLight", "s": "straw", "m": "woodLight"}, 0, 0)
    return g


def cloth():
    """Day 1: a linen cloth over the whole table, its folds lit from the west."""
    g = Grid(W, H)
    for y in range(H):
        for x in range(W):
            g.set(x, y, "plaster")
    folds = [((-20, 10), (120, 150)), ((40, -6), (200, 150)), ((110, -4), (250, 140)), ((170, -8), (330, 120)),
             ((230, -4), (320, 60)), ((-10, 70), (60, 150))]
    for (a, b) in folds:
        line = bresenham(a[0], a[1], b[0], b[1])
        for (x, y) in line:
            g.set(x, y, "parchment")
            g.set(x + 1, y, "parchment")
            g.set(x + 3, y, "plasterDim")
            g.set(x + 4, y, "plasterDim")
    for y in range(H):
        for x in range(W):
            d = min(x, y, W - 1 - x, H - 1 - y)
            if d == 0:
                g.set(x, y, "plasterDim")
            elif d == 2:
                g.set(x, y, "plasterDim" if (x + y) % 4 else "plaster")
    return g


# ---------------------------------------------------------------------------------------------- pins, lantern, tokens

PIN = [
    "..KKKKK..",
    ".KsSSssK.",
    "KsSHSsmmK",
    "KSHHSsmmK",
    "KSSSsmmmK",
    "KssmmmmdK",
    "KsmmmmddK",
    ".KmmdddK.",
    "..KKKKK..",
]
ENAMEL = [
    ".........",
    ".........",
    "...eee...",
    "..eEeee..",
    "..eeeeD..",
    "..eeeDD..",
    "...DDD...",
    ".........",
    ".........",
]
BRASS_DULL = {"K": "soilDark", "H": "strawLight", "S": "gold", "s": "straw", "m": "woodLight", "d": "wood"}
BRASS_LIT = {"K": "woodDark", "H": "fireWhite", "S": "fireGold", "s": "gold", "m": "straw", "d": "woodLight"}
# iron a step lighter than the oak's shade, its crown catching the light, so it reads as a pin and not as a hole
IRON_DULL = {"K": "ink", "H": "foam", "S": "stonePale", "s": "stoneLight", "m": "stone", "d": "stoneMid"}
IRON_LIT = {"K": "ink", "H": "fireWhite", "S": "foam", "s": "stonePale", "m": "stoneLight", "d": "stone"}
HOUSES = {
    "varn": ("leafLight", "meadow", "leaf"),
    "brine": ("roofLight", "banner", "roofDeep"),
    "lorn": ("plumLight", "plum", "plumDeep"),
    "calder": ("stoneLight", "ink", "nightDeep"),
    "oxmoor": ("crimsonLight", "crimson", "crimsonDeep"),
}
PIN_KINDS = ["brass", "iron", "varn", "brine", "lorn", "calder", "oxmoor"]


def pins():
    """A strip of 9x9 pins, two frames per kind (dull, lit), in PIN_KINDS order."""
    g = Grid(9 * 2 * len(PIN_KINDS), 9)
    for k, kind in enumerate(PIN_KINDS):
        for lit in (0, 1):
            x0 = (2 * k + lit) * 9
            metal = (IRON_LIT if lit else IRON_DULL) if kind == "iron" else (BRASS_LIT if lit else BRASS_DULL)
            g.stamp(PIN, metal, x0, 0)
            if kind in HOUSES:
                light, mid, dark = HOUSES[kind]
                g.stamp(ENAMEL, {"E": light, "e": mid, "D": dark}, x0, 0)
    return g


LANTERN = [
    [
        "...K...",
        "..K.K..",
        "..KgK..",
        ".KgggK.",
        ".KwwwK.",
        ".KGFGK.",
        ".KFFGK.",
        ".KGFOK.",
        ".KOOOK.",
        ".KwwwK.",
        "..KKK..",
    ],
    [
        "...K...",
        "..K.K..",
        "..KgK..",
        ".KgggK.",
        ".KwwwK.",
        ".KGGGK.",
        ".KGFGK.",
        ".KFFOK.",
        ".KOGOK.",
        ".KwwwK.",
        "..KKK..",
    ],
]
LANTERN_LEGEND = {"K": "ink", "g": "gold", "w": "woodDark", "F": "fireWhite", "G": "fireGold", "O": "fireOrange"}


def lantern():
    g = Grid(14, 11)
    for i, rows in enumerate(LANTERN):
        g.stamp(rows, LANTERN_LEGEND, 7 * i, 0)
    return g


# The boxwood pieces: pale carved wood, lit from the west, each on a round foot.
TOKEN_LEGEND = {"K": "woodDark", "H": "strawLight", "s": "straw", "m": "woodLight", "d": "wood", "b": "gold",
                "B": "stoneLight", "n": "stone"}
RIDER = [
    "....KK......",
    "...KHsK.....",
    "...KssK..KK.",
    "..KHssK.KHsK",
    ".KHHsssKKssK",
    "KHssssssssmK",
    "KsssssssmmK.",
    ".KsK..KmK...",
    "KKKKKKKKKKKK",
    "KHHsssssmmdK",
]
WALKER = [
    "..KK..K.",
    ".KHsK.K.",
    ".KssK.K.",
    "..KK..K.",
    ".KHsKKK.",
    "KHssmKK.",
    "KHssmKK.",
    "KHsmmdK.",
    "KKKKKKKK",
    "KHssmmdK",
]
CART = [
    ".KKKKKKKKKKK..",
    "KHHHsssssmmdK.",
    "KHssssssmmmdKK",
    "KKKKKKKKKKKKK.",
    "..KK.....KK...",
    ".KHsK...KHsK..",
    ".KsdK...KsdK..",
    "..KK.....KK...",
    "..............",
]
BEARERS = [
    "..KK........KK..",
    ".KHsK......KHsK.",
    ".KssK......KssK.",
    "KKKKKKKKKKKKKKKK",
    "KHsK...KK...KHsK",
    "KHsK..KBnK..KHsK",
    "KHmK..KBnK..KHmK",
    "KKKK.KBBnnK.KKKK",
    "KHdK..KKKK..KHdK",
    "KKKK........KKKK",
]


def token(rows):
    g = Grid(len(rows[0]), len(rows))
    g.stamp(rows, TOKEN_LEGEND, 0, 0)
    return g


# --------------------------------------------------------------------------------------------------------- the rail

RAIL_W, RAIL_H = 128, 30
RAIL_SLOTS = [16, 48, 80, 112]  # the hooks' x (centres)
PLATE_Y = 19                    # the brass plates' top row (17 x 11: lit top and west edges, shaded east and south)


def rail():
    """The board on the chapel wall: a beam along the top, oak below it, a brass plate under each hook, wide enough
    for its number in the interface kit's figures."""
    g = Grid(RAIL_W, RAIL_H)
    for y in range(RAIL_H):
        for x in range(RAIL_W):
            g.set(x, y, "woodLight")
    r = Rand(0x4A11)
    for _ in range(8):
        y = r.range(6, RAIL_H - 4)
        x = r.range(0, RAIL_W - 30)
        length = r.range(20, 60)
        step = r.range(12, 20)
        for i in range(length):
            g.set(x + i, y + (1 if (i // step) % 2 else 0), "wood")
    for x in range(RAIL_W):
        g.set(x, 0, "soilDark")
        g.set(x, 1, "strawLight")
        g.set(x, 2, "straw")
        g.set(x, 3, "woodDark")
        g.set(x, RAIL_H - 1, "woodDark")
        g.set(x, RAIL_H - 2, "wood")
    for y in range(RAIL_H):
        g.set(0, y, "soilDark")
        g.set(RAIL_W - 1, y, "soilDark")
    for y in range(4, RAIL_H - 2):
        g.set(1, y, "straw")
        g.set(RAIL_W - 2, y, "wood")
    plate = ["HHHHHHHHHHHHHHHHm"] + ["Hsssssssssssssssd"] * 9 + ["mdddddddddddddddd"]
    for cx in RAIL_SLOTS:
        g.stamp(plate, {"H": "strawLight", "s": "gold", "m": "straw", "d": "woodDark"}, cx - 8, PLATE_Y)
    for x in (4, RAIL_W - 6):
        g.stamp(["KK", "KK"], {"K": "soilDark"}, x, 5)
    return g


HOOK = [
    ".KK..",
    "KnBK.",
    ".KK..",
    "..K..",
    "..K..",
    "K.K..",
    "KnK..",
    ".K...",
]


def hook():
    g = Grid(5, 8)
    g.stamp(HOOK, {"K": "ink", "n": "stone", "B": "stoneLight"}, 0, 0)
    return g


# The road lantern on its hook, 9 x 13: the ring the hook goes through, the cap, the glass, the foot.
RAIL_LANTERN = [
    "....K....",
    "...K.K...",
    "..KKKKK..",
    ".KgggggK.",
    ".KwwwwwK.",
    ".KnsnnnK.",
    ".KnsnnnK.",
    ".KnnnnnK.",
    ".KnnnnnK.",
    ".KnnnnmK.",
    ".KwwwwwK.",
    "..KgggK..",
    "...KKK...",
]
DARK = {"K": "ink", "g": "straw", "w": "woodDark", "n": "soilDark", "s": "stone", "m": "rockDark"}
BLANK = {"K": "stoneDark", "g": "stone", "w": "stoneMid", "n": "stoneMid", "s": "stoneMid", "m": "stoneMid"}
# Kept for one ride (lantern 41): dark, its glass bound in a strip of red cloth knotted at the side, the tails hanging.
KEPT_CLOTH = [
    ".........",
    ".........",
    ".........",
    ".........",
    ".........",
    ".........",
    "lllllllll",
    "cccccccdd",
    "......dcd",
    ".......c.",
    ".......dc",
    "........d",
    ".........",
]
CLOTH = {"l": "crimsonLight", "c": "crimson", "d": "crimsonDeep"}
# Home with its report, and hung again until the lord says Done: the flame still burns behind the glass.
LIT_GLASS = [
    ".........",
    ".........",
    ".........",
    ".........",
    ".........",
    "..OGGGO..",
    "..GGFGG..",
    "..GFwFG..",
    "..OGFGO..",
    "..OOGOO..",
    ".........",
    ".........",
    ".........",
]
FIRE = {"O": "fireOrange", "G": "fireGold", "F": "fireWhite", "w": "fireWhite"}


def rail_lanterns():
    """The lantern on its hook, four frames of 9 x 13: dark at home (0), the blank one Bram hangs on a lost lantern's hook
    (1), kept for one ride and bound in red cloth (2), lit, home with its report (3)."""
    g = Grid(36, 13)
    g.stamp(RAIL_LANTERN, DARK, 0, 0)
    g.stamp(RAIL_LANTERN, BLANK, 9, 0)
    g.stamp(RAIL_LANTERN, DARK, 18, 0)
    g.stamp(KEPT_CLOTH, CLOTH, 18, 0)
    g.stamp(RAIL_LANTERN, dict(DARK, g="gold"), 27, 0)
    g.stamp(LIT_GLASS, FIRE, 27, 0)
    return g


# A lost lantern's hook: the soot its last flame left on the board above, and a chalk stroke where it should hang.
SOOT = [
    "...sss.....",
    "..sddds....",
    ".sddddds...",
    ".sddkddds..",
    "sddkkkdds..",
    ".sddkdds...",
    "..sddds....",
    "...sss.....",
]


def soot():
    g = Grid(11, 8)
    g.stamp(SOOT, {"s": "wood", "d": "soilLight", "k": "soil"}, 0, 0)
    return g


CHALK = [
    "......FF",
    ".....FFp",
    "....FFp.",
    "...FFp..",
    "..FFp...",
    ".FFp....",
    "FFp.....",
]


def chalk():
    g = Grid(8, 7)
    g.stamp(CHALK, {"F": "foam", "p": "plasterDim"}, 0, 0)
    return g


# The plates' numbers: the interface kit's figures (tools/hudart.py on claude/lh-hudart, FIG_HAND, the 5 x 7 bodies),
# engraved dark into the brass. Every figure advances 6 pixels.
FIGURES = {
    "0": [".XXX.", "XX.XX", "XX.XX", "XX.XX", "XX.XX", "XX.XX", ".XXX."],
    "1": ["..XX.", ".XXX.", "..XX.", "..XX.", "..XX.", "..XX.", ".XXXX"],
    "2": [".XXX.", "XX.XX", "...XX", "..XX.", ".XX..", "XX...", "XXXXX"],
    "3": ["XXXXX", "...XX", "..XX.", ".XXX.", "...XX", "...XX", "XXXX."],
    "4": ["...XX", "..XXX", ".X.XX", "XX.XX", "XXXXX", "...XX", "...XX"],
    "5": ["XXXXX", "XX...", "XXXX.", "...XX", "...XX", "...XX", "XXXX."],
    "6": ["..XX.", ".XX..", "XX...", "XXXX.", "XX.XX", "XX.XX", ".XXX."],
    "7": ["XXXXX", "...XX", "..XX.", ".XXXX", ".XX..", ".XX..", ".XX.."],
    "8": [".XXX.", "XX.XX", "XX.XX", ".XXX.", "XX.XX", "XX.XX", ".XXX."],
    "9": [".XXX.", "XX.XX", "XX.XX", ".XXXX", "...XX", "..XX.", ".XX.."],
}


def digits():
    g = Grid(50, 7)
    for i in range(10):
        g.stamp(FIGURES[str(i)], {"X": "ink"}, 5 * i, 0)
    return g


SEAL = [
    "..ddddd..",
    ".dLLbbbd.",
    "dLbBBBbbd",
    "dLBbLbBbd",
    "dbBLbbBbd",
    "dbBbbbBdd",
    "dbbBBBbdd",
    ".ddbbbdd.",
    "..ddddd..",
]


def seal():
    g = Grid(9, 9)
    g.stamp(SEAL, {"d": "roofDeep", "L": "roofLight", "b": "banner", "B": "roofDeep"}, 0, 0)
    return g


BUILDERS = {
    "tableSlab": slab,
    "tableTop": table_top,
    "tableWest1": west_one,
    "tableWest2": west_two,
    "tableSpan": span,
    "tableCloth": cloth,
    "tablePins": pins,
    "tableLantern": lantern,
    "tableRider": lambda: token(RIDER),
    "tableWalker": lambda: token(WALKER),
    "tableCart": lambda: token(CART),
    "tableBearers": lambda: token(BEARERS),
    "tableRail": rail,
    "tableHook": hook,
    "tableRailLanterns": rail_lanterns,
    "tableSoot": soot,
    "tableChalk": chalk,
    "tableDigits": digits,
    "tableSeal": seal,
}


def main():
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest="cmd", required=True)
    b = sub.add_parser("build")
    b.add_argument("id")
    b.add_argument("--out", default=OUT)
    b.add_argument("--zoom", type=int, default=0, help="also write <id>-x<zoom>.png (nearest neighbour) for a look")
    b.add_argument("--zoom-out", default=None, help="the folder of the zoomed copy (default: --out)")
    sub.add_parser("list")
    a = ap.parse_args()
    if a.cmd == "list":
        print("\n".join(BUILDERS))
        return
    if a.id not in BUILDERS:
        raise SystemExit(f"unknown id {a.id}")
    pal = Palette(DEFAULT_PALETTE, allow_emissive=True, allow_swap=False)
    img = BUILDERS[a.id]().image(pal)
    write_png(os.path.join(a.out, a.id + ".png"), img)
    if a.zoom:
        z = a.zoom
        big = Image(img.w * z, img.h * z)
        for y in range(big.h):
            for x in range(big.w):
                big.set(x, y, img.get(x // z, y // z))
        write_png(os.path.join(a.zoom_out or a.out, f"{a.id}-x{z}.png"), big)
    print(f"{a.id}: {img.w}x{img.h}")


if __name__ == "__main__":
    main()
