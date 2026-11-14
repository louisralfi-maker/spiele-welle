#!/usr/bin/env python3
"""Lanternhold: the Lantern Table's art (docs/QUESTS.md section 6; the quests lane, step quests-3).

Hand-set pixel art on the shared palette (tools/palette.txt), drawn from rules and text grids, never generated: the
carved oak table top seen from above with the Wend inlaid in the realm's teal and a western third of bare planed wood,
the two knife-scratch overlays and the span for that bare wood and the old bridge, the cloth of day 1, the brass place
pins (house pins in the house's colour), the burning road lantern and the boxwood tokens on the table, and the hook
rail of the screen (the board, the iron hook, the dark lantern, the soot of a lost lantern, the chalk stroke, the
plate's digits), and Odile's seal. One texel is one table pixel; the screen draws them at whole device pixels.

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
RIM = MAP["rim"]
PLANED = MAP["planed"]
HOME = tuple(MAP["home"])
PLACES = {p["id"]: p for p in MAP["places"]}
SEAMS = [33, 62, 91, 120]  # the oak's plank seams (rows)


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


def oak_field(g, r):
    for y in range(H):
        for x in range(W):
            g.set(x, y, "wood")
    # the waxed oak keeps its grain quiet: the carving is what shows; only the plank seams run through it
    for sy in SEAMS:
        for x in range(W):
            g.set(x, sy, "woodDark")
            if x % 37 == 5:
                g.set(x, sy + 1, "soil")


def bare_west(g, r):
    """Lord Edric's planed third: raw oak lighter than the waxed east, its grain flowing round two knots."""
    knots = [(60, 108, 2)]
    for y in range(RIM, H - RIM):
        for x in range(RIM, PLANED):
            g.set(x, y, "straw")
    for top, bottom in zip([RIM] + SEAMS, SEAMS + [H - RIM]):
        flowing_grain(g, RIM, PLANED - 1, top + 1, bottom, r, "plasterDim", 4, 0.9, 90, knots, cover=0.8)
        flowing_grain(g, RIM, PLANED - 1, top + 2, bottom, r, "woodLight", 13, 1.1, 120, knots, cover=0.55)
        flowing_grain(g, RIM, PLANED - 1, top + 1, bottom, r, "strawLight", 9, 0.8, 100, knots, cover=0.35)
    for sy in SEAMS:
        for x in range(RIM, PLANED):
            g.set(x, sy, "woodLight")
    for (kx, ky, kr) in knots:
        for (x, y) in disc(kx, ky, kr + 0.8, kr * 0.6 + 0.4):
            g.set(x, y, "woodLight")
        for (x, y) in disc(kx, ky, kr - 0.6, max(0.5, kr * 0.3)):
            g.set(x, y, "wood")
    # the cut: the step's face catches the light from the west, the waxed edge above it a shade darker
    for y in range(RIM, H - RIM):
        g.set(PLANED, y, "strawLight")
        g.set(PLANED + 1, y, "woodDark")


def rim(g):
    """The table's moulded edge, lit on its west and north sides."""
    for y in range(H):
        for x in range(W):
            d = min(x, y, W - 1 - x, H - 1 - y)
            if d >= RIM:
                continue
            topleft = (d == y or d == x) and not (d == H - 1 - y or d == W - 1 - x)
            if d == 0:
                g.set(x, y, "soilDark")
            elif d == 1:
                g.set(x, y, "straw" if topleft else "woodDark")
            elif d == 2:
                g.set(x, y, "woodLight" if topleft else "wood")
            else:
                g.set(x, y, "soilDark")


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


def mountains(g, r):
    """The Weltmauer: a ridge of overlapping carved peaks, the one cleft at home, the Throat running west from it."""
    peaks = []
    for band in ((3, 66), (92, 140)):
        y = band[0]
        while y < band[1]:
            # the crest: big peaks, never in a line
            ax = 112 + r.range(-3, 3)
            h = r.range(7, 10)
            peaks.append((ax, y, r.range(5, 8), r.range(4, 7), h, True))
            # the west side: smaller, cut off at the planed edge
            peaks.append((r.range(93, 101), y + r.range(1, 4), r.range(3, 5), r.range(3, 5), r.range(4, 7), False))
            # the east foothills
            if r.next() % 3:
                peaks.append((r.range(123, 129), y + r.range(2, 5), r.range(2, 4), r.range(2, 3), r.range(3, 5),
                              False))
            y += r.range(5, 8)
    for (ax, ay, hl, hr, h, crease) in sorted(peaks, key=lambda p: p[1] + p[4]):
        if ay + h > 73 and ay < 87:
            continue
        if ay + h >= H - RIM:
            h = H - RIM - ay
            if h < 3:
                continue
        peak(g, ax, ay, hl, hr, h, crease)
    # the Throat: a narrow gorge cut west from the cleft to the planed edge
    for x in range(PLANED + 2, 112):
        for y in range(77, 84):
            g.set(x, y, "soil")
        g.set(x, 76, "soilDark")
        g.set(x, 84, "woodLight")


CASTLE = [
    "K.K.......K.K..",
    "KLK.K.K.K.KLK..",
    "KLMKKKKKKKKLMK.",
    "KLMKLMMMMDKLMK.",
    "KLMKLMGgMDKLMK.",
    "KLMKLMGGMDKLMK.",
    "KLMKLMMMMDKLMK.",
    "KLMMMMMMMMMMMDK",
    "KLMMMKKKKKMMMDK",
    "KLMMKDDDDDKMMDK",
    "KLMMKD...DKMMDK",
    "KKKKKK...KKKKKK",
]
CASTLE_LEGEND = {"K": "woodDark", "L": "strawLight", "M": "woodLight", "D": "soil", "G": "gold", "g": "fireGold"}


def castle(g):
    x0 = HOME[0] - 7
    y0 = HOME[1] - 6
    # the cleft's floor round it
    for x in range(110, 130):
        for y in range(71, 89):
            if g.get(x, y) in ("tile", "soil", "woodLight", "woodDark", "strawLight", "straw"):
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
        if y < H - RIM:
            g.set(x, y, "roofDeep")
    for (x, y) in core:
        if y < H - RIM:
            g.set(x, y, "banner")
    for i, (x, y) in enumerate(pts):
        if i % 9 in (0, 1, 2) and y < H - RIM - 1:
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
    for x in range(124, W - RIM):
        y = shore_y(x)
        for yy in range(y + 1, H - RIM):
            g.set(x, yy, "soil")
        g.set(x, y, "woodDark")
    rows = [(MAP["coast"] + 3, 0), (MAP["coast"] + 5, 4)]
    for row, shift in rows:
        for x in range(127 + shift, W - RIM - 4, 8):
            if abs(x + 2 - mouth) <= 4 or row <= shore_y(x) + 1 or row <= shore_y(x + 3) + 1:
                continue
            for (dx, dy) in ((0, 0), (1, 0), (2, 0), (3, 0)):
                if row + dy < H - RIM:
                    g.set(x + dx, row + dy, "wood")
            g.set(x + 1, row - 1, "woodLight")
            g.set(x + 2, row - 1, "woodLight")


def hill(g, x, y, w, h=None):
    """A carved down: a smooth mound, its west shoulder lit, its east side and foot in shade."""
    h = h or max(3, round(w / 3))
    for dx in range(w):
        t = dx / (w - 1)
        top = y - round(math.sin(t * math.pi) ** 0.8 * h)
        for yy in range(top, y + 1):
            if t < 0.42:
                n = "straw" if yy == top else ("woodLight" if yy < top + 2 or t < 0.25 else "tile")
            elif t < 0.6:
                n = "woodLight" if yy == top else "tile"
            else:
                n = "woodDark" if yy == top or dx == w - 1 else "soil"
            g.set(x + dx, yy, n)
    # its shadow on the field, to the east
    for dx in range(w // 2, w + 1):
        g.set(x + dx, y + 1, "soil")


CROWN = [".LL.", "LssD", "sssD", ".DD."]


def forest(g, r, cx, cy, rx, ry):
    """A wood: round crowns packed close, back to front, lit from the west, its edge falling into shade."""
    spots = []
    y = cy - ry
    row = 0
    while y <= cy + ry:
        x = cx - rx + (2 if row % 2 else 0)
        while x <= cx + rx:
            if ((x - cx) / (rx + 0.5)) ** 2 + ((y - cy) / (ry + 0.5)) ** 2 <= 1:
                spots.append((x + r.range(-1, 1), y))
            x += 4
        y += 3
        row += 1
    for (x, y) in spots:
        g.stamp(CROWN, {"L": "straw", "s": "woodLight", "D": "soil"}, x - 2, y - 2)
    # the wood's foot: one dark row under the front crowns
    front = {}
    for (x, y) in spots:
        for dx in range(-1, 3):
            front[x + dx] = max(front.get(x + dx, -1), y + 2)
    for x, y in front.items():
        if g.get(x, y) not in ("banner", "roofDeep", "roofLight"):
            g.set(x, y, "soilDark")


def land(g, r):
    # the downs north of the valley under Highcairn, and the long downs of the Morninglands
    for (x, y, w, h) in [(130, 22, 15, 5), (160, 18, 17, 6), (188, 30, 13, 4), (218, 26, 19, 6), (260, 24, 15, 5),
                         (276, 66, 13, 4), (236, 84, 17, 5), (196, 96, 11, 3), (152, 68, 11, 3), (278, 104, 11, 3),
                         (200, 46, 11, 3)]:
        hill(g, x, y, w, h)
    for (cx, cy, rx, ry) in [(228, 64, 9, 5), (262, 88, 7, 4), (206, 130, 8, 3), (190, 80, 4, 3), (282, 16, 7, 3),
                             (184, 50, 4, 3), (240, 130, 5, 2)]:
        forest(g, r, cx, cy, rx, ry)


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


def table_top():
    g = Grid(W, H)
    r = Rand(0x7AB1E)
    oak_field(g, r)
    land(g, r)
    sea(g)
    mountains(g, r)
    roads(g)
    wend(g)
    mere(g)
    icons(g)
    pin_shadows(g)
    castle(g)
    bare_west(g, r)
    rim(g)
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
    empty = xs[11]
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
    """What the lamp room saw: the moor's edge, and far out one low light that never flickers."""
    g = Grid(96, H)
    r = Rand(0x30E)
    edge = []
    x = 30
    for y in range(14, 138):
        if y % 6 == 0:
            x += 1 if r.next() % 2 else -1
            x = max(26, min(34, x))
        edge.append((x, y))
    scratch(g, [(x, y) for (x, y) in edge if not (70 <= y <= 90)])
    # tussocks west of the edge: small v cuts
    for (tx, ty) in [(12, 22), (20, 34), (9, 46), (17, 98), (8, 112), (21, 124), (13, 132), (22, 58), (10, 92)]:
        scratch(g, [(tx, ty), (tx + 1, ty + 1)])
        scratch(g, [(tx + 2, ty)])
    # the light: a small ring with its point
    lx, ly = 13, 68
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
IRON_DULL = {"K": "ink", "H": "stoneLight", "S": "stone", "s": "stoneMid", "m": "stoneDark", "d": "rockDeep"}
IRON_LIT = {"K": "ink", "H": "stonePale", "S": "stoneLight", "s": "stone", "m": "stoneMid", "d": "stoneDark"}
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

RAIL_W, RAIL_H = 128, 32
RAIL_SLOTS = [16, 48, 80, 112]  # the hooks' x (centres)


def rail():
    """The board on the chapel wall: a beam along the top, oak below it, a brass plate under each hook."""
    g = Grid(RAIL_W, RAIL_H)
    for y in range(RAIL_H):
        for x in range(RAIL_W):
            g.set(x, y, "woodLight")
    r = Rand(0x4A11)
    for _ in range(9):
        y = r.range(7, RAIL_H - 3)
        x = r.range(0, RAIL_W - 30)
        length = r.range(20, 60)
        step = r.range(12, 20)
        for i in range(length):
            g.set(x + i, y + (1 if (i // step) % 2 else 0), "wood")
    for x in range(RAIL_W):
        g.set(x, 0, "soilDark")
        g.set(x, 1, "strawLight")
        g.set(x, 2, "straw")
        g.set(x, 3, "wood")
        g.set(x, 4, "woodDark")
        g.set(x, RAIL_H - 1, "woodDark")
        g.set(x, RAIL_H - 2, "wood")
    for y in range(RAIL_H):
        g.set(0, y, "soilDark")
        g.set(RAIL_W - 1, y, "soilDark")
    for y in range(5, RAIL_H - 2):
        g.set(1, y, "straw")
        g.set(RAIL_W - 2, y, "wood")
    plate = [
        "KKKKKKKKKKK",
        "KHsssssssmK",
        "KHsssssssmK",
        "KHsssssssmK",
        "KHsssssssmK",
        "KHsssssssmK",
        "KKKKKKKKKKK",
    ]
    for cx in RAIL_SLOTS:
        g.stamp(plate, {"K": "woodDark", "H": "strawLight", "s": "gold", "m": "straw"}, cx - 5, 24)
    for x in (4, RAIL_W - 6):
        g.stamp(["KK", "KK"], {"K": "soilDark"}, x, 6)
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


RAIL_LANTERN = [
    "....K....",
    "...K.K...",
    "....K....",
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


def rail_lanterns():
    """The dark road lantern on its hook (frame 0) and the blank one Bram hangs on a lost lantern's hook (frame 1)."""
    g = Grid(18, 14)
    g.stamp(RAIL_LANTERN, {"K": "ink", "g": "straw", "w": "woodDark", "n": "soilDark", "s": "stone", "m": "rockDark"},
            0, 0)
    g.stamp(RAIL_LANTERN, {"K": "stoneDark", "g": "stone", "w": "stoneMid", "n": "stoneMid", "s": "stoneMid",
                           "m": "stoneMid"}, 9, 0)
    return g


SOOT = [
    "....sss......",
    "...sddds.....",
    "..sddddds....",
    "..sdddddds...",
    ".sddkkkddds..",
    ".sdkkkkkdds..",
    "sddkkkkkkdds.",
    "sdkkkkkkkkds.",
    "sdkkkkkkkkds.",
    "sddkkkkkkdds.",
    ".sdkkkkkkds..",
    ".sddkkkkdds..",
    "..sddddddss..",
    "...ssddds....",
    ".....sss.....",
    ".............",
]


def soot():
    g = Grid(13, 16)
    g.stamp(SOOT, {"s": "wood", "d": "soil", "k": "soilDark"}, 0, 0)
    return g


CHALK = [
    ".....FF",
    "...FFp.",
    ".FFp...",
    "Fp.....",
]


def chalk():
    g = Grid(7, 4)
    g.stamp(CHALK, {"F": "foam", "p": "parchment"}, 0, 0)
    return g


DIGITS = [
    ["KKK", "K.K", "K.K", "K.K", "KKK"],
    [".K.", "KK.", ".K.", ".K.", "KKK"],
    ["KKK", "..K", "KKK", "K..", "KKK"],
    ["KKK", "..K", ".KK", "..K", "KKK"],
    ["K.K", "K.K", "KKK", "..K", "..K"],
    ["KKK", "K..", "KKK", "..K", "KKK"],
    ["KKK", "K..", "KKK", "K.K", "KKK"],
    ["KKK", "..K", ".K.", ".K.", ".K."],
    ["KKK", "K.K", "KKK", "K.K", "KKK"],
    ["KKK", "K.K", "KKK", "..K", "KKK"],
]


def digits():
    g = Grid(30, 5)
    for i, rows in enumerate(DIGITS):
        g.stamp(rows, {"K": "ink"}, 3 * i, 0)
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
