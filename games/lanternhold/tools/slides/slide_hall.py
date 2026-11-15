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


SEAT_X = 198               # the seat at about 62 % of the width
DOOR = (16, 50, 60)        # the door's left, right and the arch's top (about 70 px high to the floor)
FLOOR2 = 132
PIERS = ((64, 77, "far"), (106, 119, "mid"), (146, 159, "near"))
LIT = {"near": ("gold", "tile"), "mid": ("tile", "crimsonDeep"), "far": ("plumDeep", "plumDeep")}
HEIR_COLD = {"H": ("night0", "nightSlate", "night0", 1), "F": ("night0", "nightSlate", "night0", 1),
             "C": ("night0", "nightSlate", "night0", 1), "D": ("night0", "nightSlate", "night0", 1),
             "B": ("night0", "nightSlate", "night0", 1)}


def flag_rows():
    """Flagstones of uneven widths (14 to 30 px), each row its own joints: never a brick bond."""
    rows = {}
    for row in range(8):
        b, x = [], -int(h(row, 0, 5) * 20)
        while x < W + 30:
            b.append(x)
            x += 14 + int(h(row, len(b), 6) * 17)
        rows[row] = b
    return rows


FLAGS = flag_rows()


def flag_at(x, y):
    """(stone centre x, stone row, is joint) for a floor px."""
    row = (y - FLOOR2) // 7
    b = FLAGS[min(7, row)]
    for i in range(len(b) - 1):
        if b[i] <= x < b[i + 1]:
            return (b[i] + b[i + 1]) / 2.0, row, (x == b[i + 1] - 1) or ((y - FLOOR2) % 7 == 6)
    return x, row, False


def slide4(kind):
    """Round 5: two lights meet across a dark hall: the moon's wedge through the door with the heir's long shadow
    reaching for the seat, the lantern's pool at the dais, the dark floor between."""
    p = Pic("night0")
    lx, ly = SEAT_X - 30, 36
    # the back wall: flat dark; large ashlar courses only in a patch round the lantern, fading
    for y in range(FLOOR2):
        row = y // 10
        off = 11 if row % 2 else 0
        for x in range(W):
            bx = (x + off) // 22
            t = falloff(bx * 22 - off + 11, row * 10 + 5, lx, ly + 20, 70, 62, 1.2)
            lv = 2 if t > 0.5 else (1 if t > 0.18 else 0)
            c = ("night0", "night1", "plumDeep")[lv]
            if lv and (y % 10 == 9 or (x + off) % 22 == 21):
                c = ("night0", "night0", "night1")[lv]
            p.px(x, y, c)
    # the vault: round arches at the top of the frame, carried by the piers
    for (a, b) in ((0, 64), (77, 106), (119, 146), (159, 240)):
        cx, r = (a + b) / 2.0, (b - a) / 2.0
        for x in range(a, b):
            top = int(round(26 - math.sqrt(max(0.0, r * r - (x + 0.5 - cx) ** 2)) * 0.7))
            for y in range(0, max(0, top)):
                p.px(x, y, "night0")
            if 0 <= top < H:
                p.px(x, top, "nightDeep")
    # the door: a tall round arch in a stone frame, open to the night (the sky a step lighter than the hall)
    dl, dr, dt = DOOR
    cx, r = (dl + dr) / 2.0, (dr - dl) / 2.0
    door = np.zeros((H, W), bool)
    for x in range(dl, dr):
        top = int(round(dt + r - math.sqrt(max(0.0, r * r - (x + 0.5 - cx) ** 2))))
        door[top:FLOOR2, x] = True
    frame = np.zeros((H, W), bool)
    for x in range(dl - 4, dr + 4):
        rr = r + 4
        top = int(round(dt + r - math.sqrt(max(0.0, rr * rr - (x + 0.5 - cx) ** 2))))
        frame[max(0, top):FLOOR2, x] = True
    frame &= ~door
    p.mask(frame, "nightDeep")
    for y, x in zip(*np.where(frame)):
        if x >= dr and x < dr + 2:
            p.px(x, y, "nightBlue")                               # the frame's inner edge toward the hall's light
    p.mask(door, "nightBlue")
    for y in range(FLOOR2 - 14, FLOOR2):
        for x in range(dl, dr):
            if door[y, x]:
                p.px(x, y, "nightDeep" if y > FLOOR2 - 6 else "nightSlate")   # the land outside, a line of it
    for (x, y) in ((24, 72), (40, 80), (28, 96)):
        p.px(x, y, "moon")
    # the floor: flagstones in stone tones, dark between the two lights
    for y in range(FLOOR2, H):
        for x in range(W):
            p.px(x, y, "nightDeep" if flag_at(x, y)[2] else "night0")
    # the moon's long cold wedge from the door over the floor, two pale steps and a broken edge
    wedge_outer = poly_mask([(dl, FLOOR2), (dr, FLOOR2), (236, H), (100, H)])
    wedge_inner = poly_mask([(dl + 6, FLOOR2), (dr - 4, FLOOR2), (196, H), (116, H)])
    for y, x in zip(*np.where(wedge_outer)):
        joint = flag_at(x, y)[2]
        inner = wedge_inner[y, x]
        edge = not poly_mask([(dl + 2, FLOOR2), (dr - 1, FLOOR2), (184, H), (100, H)])[y, x] if False else False
        c = ("nightHaze" if inner else "nightSlate")
        if joint:
            c = "nightSlate" if inner else "nightBlue"
        if not inner and BAYER[y % 4][x % 4] < 4 and h(x // 3, y, 9) < 0.5:
            c = "nightBlue"                                       # the wedge's broken edge
        p.px(x, y, c)
    # the heir's long shadow in the moonlight, pointing at the seat
    hx = (dl + dr) // 2
    for y in range(FLOOR2, H):
        k = (y - FLOOR2) / float(H - FLOOR2)
        x0 = int(hx + k * 150)
        w_ = max(1, int(round(3.5 - k * 2.5)))
        for x in range(x0 - w_, x0 + w_ + 1):
            if wedge_outer[y, x]:
                p.px(x, y, "night0")
    # the lantern's warm pool at the dais: three steps on the flagstones, gold nearest, then ember, then dark
    for y in range(FLOOR2, H):
        for x in range(140, W):
            cx_, row, joint = flag_at(x, y)
            t = falloff(cx_, FLOOR2 + row * 7 + 3, SEAT_X - 10, FLOOR2, 64, 20, 1.2)
            lv = 2 if t > 0.5 else (1 if t > 0.16 else 0)
            if not lv:
                continue
            c = ("night0", "tile", "straw")[lv]
            if joint:
                c = ("night0", "night0", "tile")[lv]
            p.px(x, y, c)
    # the piers: stone, 14 px wide, base and capital, a lit face toward the lantern in two tones
    for (x0, x1, which) in PIERS:
        for y in range(18, FLOOR2):
            for x in range(x0, x1 + 1):
                p.px(x, y, "nightDeep" if x < x1 - 4 else "nightBlue")
            l1, l2 = LIT[which]
            p.px(x1, y, l1); p.px(x1 - 1, y, l1 if which == "near" else l2); p.px(x1 - 2, y, l2)
        for x in range(x0 - 2, x1 + 3):
            for y in (FLOOR2 - 3, FLOOR2 - 2, FLOOR2 - 1, 18, 19, 20):
                p.px(x, y, "nightBlue" if x < x1 + 1 else LIT[which][1])
    # the house's banner behind the seat: the teal cloth with the gold lantern sign, tall, lit at its top
    for y in range(10, 96):
        for x in range(SEAT_X - 18, SEAT_X + 19):
            c = "banner" if y < 26 else ("roofDeep" if y < 70 else "nightBlue")
            if y < 14 or x in (SEAT_X - 18, SEAT_X + 18):
                c = "nightDeep" if x == SEAT_X + 18 else "roofLight"
            p.px(x, y, c)
    for k in range(12):
        for x in range(SEAT_X - 18 + int(k * 1.5), SEAT_X + 19 - int(k * 1.5)):
            p.px(x, 96 + k, "nightBlue")
    sign = ["..g..", ".ggg.", "ggggg", "g.f.g", "gfffg", "g.f.g", "ggggg", ".g.g."]
    for r, row in enumerate(sign):
        for q, ch in enumerate(row):
            if ch != ".":
                p.px(SEAT_X - 2 + q, 16 + r, "gold" if ch == "g" else "fireOrange")
    # the dais: two steps, a lit top edge and a shadowed riser
    for (x0, x1, y0, y1) in ((150, 248, 124, FLOOR2), (160, 238, 116, 124)):
        for y in range(y0, y1):
            for x in range(x0, x1):
                t = falloff(x, y0, lx, ly, 120, 120, 1.1)
                if y <= y0 + 1:
                    c = "straw" if t > 0.55 else ("tile" if t > 0.25 else "nightBlue")
                else:
                    c = "nightDeep"
                p.px(x, y, c)
    # the high-backed seat, about 1.4 times larger, empty; warm on the top of its back and on its arms
    seat = {"back": (SEAT_X - 11, SEAT_X + 11, 50, 108), "board": (SEAT_X - 17, SEAT_X + 17, 102, 108),
            "armL": (SEAT_X - 19, SEAT_X - 13, 92, 108), "armR": (SEAT_X + 13, SEAT_X + 19, 92, 108),
            "legL": (SEAT_X - 16, SEAT_X - 13, 108, 116), "legR": (SEAT_X + 13, SEAT_X + 16, 108, 116)}
    for name, (x0, x1, y0, y1) in seat.items():
        for y in range(y0, y1):
            for x in range(x0, x1 + 1):
                if y < y0 + 2 and name in ("back", "armL", "armR", "board"):
                    c = "strawLight" if name == "back" else "straw"
                elif name == "back" and x >= x1 - 1:
                    c = "night0"
                elif name == "back" and x <= x0 + 1:
                    c = "wood"
                elif name in ("armL", "armR") and y < y0 + 4:
                    c = "woodLight"
                else:
                    c = "woodDark"
                p.px(x, y, c)
    for y in range(58, 100, 7):
        for x in range(SEAT_X - 7, SEAT_X + 8):
            if (x + y) % 3 == 0:
                p.px(x, y, "night0")
    for (x, y) in ((SEAT_X, 45), (SEAT_X - 1, 46), (SEAT_X + 1, 46), (SEAT_X, 47), (SEAT_X, 48), (SEAT_X, 49)):
        p.px(x, y, "gold")
    # the circlet on the seat, 10 px, with its glint
    ring = ["..GggggG..", ".g......g.", "g........g", ".gsssssg.."]
    for r, row in enumerate(ring):
        for q, ch in enumerate(row):
            if ch != ".":
                p.px(SEAT_X - 5 + q, 98 + r, {"g": "gold", "G": "fireGold", "s": "straw"}[ch])
    gx, gy = SEAT_X + 2, 97
    p.px(gx, gy, "fireWhite")
    for (dx, dy) in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        p.px(gx + dx, gy + dy, "fireGold")
    for (dx, dy) in ((2, 0), (-2, 0), (0, -2)):
        p.px(gx + dx, gy + dy, "fireOrange")
    # the house's lantern above the seat
    global LANTERN
    LANTERN = (lx, ly)
    great_lantern(p)
    # the heir in the door: a pure dark shape, a cold rim on the moon's side
    rows = LORD if kind == "lord" else LADY
    light_grid(p, grid_parts(rows, hx - 6, FLOOR2 - len(rows), HEIR_COLD), hx - 60, FLOOR2 - 120)
    return p
