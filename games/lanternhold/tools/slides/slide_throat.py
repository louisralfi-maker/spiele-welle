"""Slide 2 of the prologue (panels lane; critic look 1 high 3): from the castle wall into the Throat, west, at night.
The Throat's walls are hand-placed masses of rock, lit from above by the moon, their inner edges cold where the fog's
light reaches them; at the far end the narrow slit of fog, the brightest cold thing in the picture, and in it three of
the Gloom's people, each with one large cold eye; the three lines across the Throat with their braziers; in front our
battlement, a brazier and House Lantern's banner. Palette art (paint.finish).
"""
import math

from paint import P, W, H, Canvas, fbm, h1, h2, step

VP = (152, 66)

ALLOWED = ["night0", "nightDeep", "nightBlue", "nightSlate", "nightHaze", "farDeep", "far", "moon", "mistDark",
           "mist", "mistLight", "farPale", "foam", "ink", "night1", "night2", "stoneDark", "stoneMid", "stone",
           "stoneLight", "stonePale", "rockDeep", "rockDark", "rock", "rockLight", "woodDark", "wood", "woodLight",
           "tile", "tileLight", "dawnRose", "banner", "roofDeep", "roofLight", "gold", "straw", "strawLight",
           "fireWhite", "fireGold", "fireOrange", "ember", "wraithWhite", "wraithGlow", "wraithDim", "soilDark"]

# Rock masses, far to near, each (points, depth 0 far ... 1 near). Placed by hand: buttresses, boulders, overhangs.
LEFT = [
    ([(126, -2), (144, -2), (143, 60), (137, 103), (130, 106), (125, 95), (128, 50)], 0.05),
    ([(98, -2), (128, 4), (132, 38), (127, 70), (133, 107), (112, 116), (95, 98), (101, 52)], 0.25),
    ([(102, 96), (125, 91), (136, 110), (121, 122), (99, 118)], 0.35),
    ([(46, -2), (100, -2), (106, 28), (97, 58), (108, 88), (100, 125), (64, 131), (40, 108), (52, 60)], 0.6),
    ([(-2, -2), (60, -2), (56, 20), (34, 38), (-2, 44)], 0.85),
    ([(-2, 40), (40, 33), (58, 66), (72, 112), (48, 134), (-2, 136)], 0.95),
]
RIGHT = [
    ([(161, -2), (179, -2), (181, 50), (183, 94), (175, 104), (168, 103), (162, 60)], 0.05),
    ([(177, 3), (211, -2), (220, 58), (213, 90), (219, 111), (195, 118), (179, 104), (182, 52)], 0.25),
    ([(175, 95), (199, 89), (211, 107), (195, 123), (171, 115)], 0.35),
    ([(209, -2), (274, -2), (284, 38), (277, 82), (289, 119), (250, 133), (213, 117), (218, 68)], 0.6),
    ([(262, -2), (322, -2), (322, 50), (296, 44), (270, 22)], 0.85),
    ([(268, 44), (322, 50), (322, 138), (284, 134), (281, 95)], 0.95),
]
# ledges and cracks inside the big masses, by hand: (polyline, kind) kind 'l' a lit ledge, 'c' a crack
MARKS = [
    ([(60, 46), (78, 44), (92, 48)], "l"), ([(56, 82), (74, 80), (98, 86)], "l"), ([(70, 104), (90, 101)], "l"),
    ([(80, 10), (76, 30), (82, 40)], "c"), ([(66, 60), (70, 76)], "c"), ([(12, 70), (30, 66), (46, 72)], "l"),
    ([(20, 96), (40, 92), (58, 100)], "l"), ([(30, 110), (28, 124)], "c"), ([(108, 30), (122, 28)], "l"),
    ([(106, 66), (124, 64)], "l"), ([(114, 80), (112, 94)], "c"),
    ([(226, 44), (246, 40), (264, 46)], "l"), ([(222, 86), (246, 82), (272, 88)], "l"),
    ([(240, 10), (244, 28), (238, 38)], "c"), ([(256, 58), (252, 74)], "c"), ([(286, 74), (304, 70), (320, 76)], "l"),
    ([(288, 100), (306, 96), (320, 102)], "l"), ([(184, 30), (200, 28)], "l"), ([(186, 66), (204, 64)], "l"),
    ([(196, 80), (198, 94)], "c"), ([(236, 104), (254, 100)], "l"),
]


def inside(pts, x, y):
    cy, cx = y + 0.5, x + 0.5
    n = len(pts)
    hit = False
    for i in range(n):
        x0, y0 = pts[i]
        x1, y1 = pts[(i + 1) % n]
        if (y0 <= cy < y1) or (y1 <= cy < y0):
            if cx < x0 + (cy - y0) * (x1 - x0) / (y1 - y0):
                hit = not hit
    return hit


def edge_normal_at(pts, x, y):
    """The outward normal of the polygon edge nearest to (x, y), and the distance to it."""
    best, nb = 9e9, (0, 0)
    n = len(pts)
    area = sum(pts[i][0] * pts[(i + 1) % n][1] - pts[(i + 1) % n][0] * pts[i][1] for i in range(n))
    sgn = 1 if area > 0 else -1
    for i in range(n):
        (x0, y0), (x1, y1) = pts[i], pts[(i + 1) % n]
        dx, dy = x1 - x0, y1 - y0
        ll = dx * dx + dy * dy or 1e-9
        t = max(0, min(1, ((x + 0.5 - x0) * dx + (y + 0.5 - y0) * dy) / ll))
        ex, ey = x0 + dx * t - x - 0.5, y0 + dy * t - y - 0.5
        d = math.hypot(ex, ey)
        if d < best:
            ln = math.sqrt(ll)
            best, nb = d, (sgn * dy / ln, -sgn * dx / ln)
    return nb, best


def rock_mass(c, pts, depth, side, seed):
    """One mass of rock broken into facets (each a flat palette colour turned to the moon at the upper left or away),
    a crack under and right of each facet, a lit edge over and left of it; the mass's edge toward the Throat's middle
    cold with the fog's light where it is near the slit."""
    ramp = ["night0", "nightDeep", "nightBlue", "nightSlate", "nightHaze"]
    b0 = 3 if depth < 0.2 else 2 if depth < 0.5 else 2 if depth < 0.8 else 1
    rim = P("mistDark") if depth < 0.3 else P("nightHaze") if depth < 0.65 else P("nightSlate")
    xs = [p[0] for p in pts]
    ys = [p[1] for p in pts]
    x0, x1, y0, y1 = int(min(xs)), int(max(xs)), int(min(ys)), int(max(ys))
    area = (x1 - x0) * (y1 - y0)
    n = max(3, int(area / (260 + 900 * depth)))
    seeds = []
    for i in range(n * 3):
        sx = x0 + h1(i, seed) * (x1 - x0)
        sy = y0 + h1(i, seed + 1) * (y1 - y0)
        if inside(pts, int(sx), int(sy)):
            # each facet's turn to the light: -1 away, 0 square on, +1 toward
            turn = -1 if h1(i, seed + 2) < 0.3 else 1 if h1(i, seed + 2) > 0.72 else 0
            seeds.append((sx, sy, turn))
        if len(seeds) >= n:
            break
    cell = {}
    for y in range(max(0, y0), min(H, y1 + 1)):
        for x in range(max(0, x0), min(W, x1 + 1)):
            if not inside(pts, x, y):
                continue
            best, idx = 9e9, 0
            for k, (sx, sy, _) in enumerate(seeds):
                d = (x - sx) ** 2 + ((y - sy) * 1.6) ** 2
                if d < best:
                    best, idx = d, k
            cell[(x, y)] = idx
    for (x, y), idx in cell.items():
        turn = seeds[idx][2] if seeds else 0
        lv = max(0, min(4, b0 + turn))
        col = P(ramp[lv])
        right, below = cell.get((x + 1, y)), cell.get((x, y + 1))
        left, above = cell.get((x - 1, y)), cell.get((x, y - 1))
        if (right is not None and right != idx) or (below is not None and below != idx):
            col = P(ramp[max(0, lv - 2)])
        elif (left is not None and left != idx) or (above is not None and above != idx):
            col = P(ramp[min(4, lv + 1)])
        (nx, ny), d = edge_normal_at(pts, x, y)
        toward = (nx > 0.55) if side == 0 else (nx < -0.55)
        if d < 1.0 and toward:
            col = rim
        elif d < 1.6 and ny < -0.45:
            col = P(ramp[min(4, lv + 1)])
        elif d < 1.2 and ny > 0.5:
            col = P("night0")
        c.c[y][x] = col


def walls(c):
    for k, (pts, d) in enumerate(LEFT):
        rock_mass(c, pts, d, 0, 851 + k * 7)
    for k, (pts, d) in enumerate(RIGHT):
        rock_mass(c, pts, d, 1, 901 + k * 7)
    for pts, kind in ():
        for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
            n = int(max(abs(x1 - x0), abs(y1 - y0))) + 1
            for k in range(n):
                x = int(round(x0 + (x1 - x0) * k / n))
                y = int(round(y0 + (y1 - y0) * k / n))
                if not (0 <= x < W and 0 <= y < H - 1):
                    continue
                if kind == "l":
                    c.c[y][x] = step(c.c[y][x], 1)
                    c.c[y + 1][x] = P("night0")
                else:
                    c.c[y][x] = P("night0")


def sky_and_slit(c):
    # the strip of night sky between the walls' tops
    for y in range(0, H):
        for x in range(W):
            c.c[y][x] = P("nightDeep") if y < 30 else P("nightBlue")
    for i in range(12):
        x = 110 + int(h1(i, 801) * 100)
        y = int(h1(i, 802) * 26) + 1
        c.c[y][x] = P("farPale") if h1(i, 803) > 0.4 else P("mist")
    # the slit at the far end: fog, lighter toward its heart, its edges torn
    for y in range(8, 106):
        for x in range(132, 174):
            t = (y - 8) / 98.0
            half = 4.5 + 9.5 * t ** 1.6 + (fbm(x * 0.2, y * 0.15, 811, 2) - 0.5) * 3.0
            d = abs(x + 0.5 - (VP[0] + 0.5 * math.sin(y * 0.08))) / half
            if d > 1.0:
                continue
            heart = d + (1 - t) * 0.5
            col = "mistLight" if heart < 0.42 else "mist" if heart < 0.75 else "mistDark" if heart < 1.0 else "nightHaze"
            c.c[y][x] = P(col)


TALL = """
...ddd....
..ddddd...
..dddddd..
..ddEEdd..
..ddEEdd..
...dddd...
...ddd....
..ddddd...
.ddddddd..
ddddddddd.
dd.ddddd.d
d..ddddd.d
d..ddddd.d
d..dddddd.
...ddddd..
...ddddd..
...dd.dd..
...dd.dd..
...d...d..
...d...d..
..dd...d..
..d....dd.
..d.....d.
"""

HUNCHED = """
.....dddd...
....dddddd..
...ddEEddd..
...ddEEddd..
....ddddd...
..dddddddd..
.dddddddddd.
ddddddddddd.
d.ddddddd.dd
d.ddddddd..d
..ddddddd..d
..dddddddd..
...dd..ddd..
...dd...dd..
..dd....dd..
..d......d..
"""

SMALL = """
..ddd..
.ddddd.
.dEEdd.
.dEEdd.
..ddd..
.ddddd.
ddddddd
d.dddd.
d.dddd.
..dd.d.
..d..d.
.dd..d.
"""


def figure(c, art, x0, base, flip=False):
    lines = art.strip("\n").split("\n")
    w = len(lines[0])
    y0 = base - len(lines)
    for j, line in enumerate(lines):
        for i, ch in enumerate(line):
            if ch == ".":
                continue
            x = x0 + (w - 1 - i if flip else i)
            y = y0 + j
            if not (0 <= x < W and 0 <= y < H):
                continue
            c.c[y][x] = P("wraithWhite") if ch == "E" else P("nightDeep")
    # the eye's cold light on the face round it
    for j, line in enumerate(lines):
        for i, ch in enumerate(line):
            if ch == "E":
                x = x0 + (w - 1 - i if flip else i)
                for dx, dy in ((-1, 0), (1, 0), (0, -1), (0, 1)):
                    X, Y = x + dx, y0 + j + dy
                    if c.c[Y][X] == P("nightDeep"):
                        c.c[Y][X] = P("wraithDim")


def gloom(c):
    """Three of the Gloom's people in the slit, dark against the fog, too tall, each with one large cold eye; two more
    eyes deeper in."""
    figure(c, HUNCHED, VP[0] - 14, 104)
    figure(c, SMALL, VP[0] + 7, 103, flip=True)
    figure(c, TALL, VP[0] - 4, 101)
    for (x, y) in ((VP[0] - 2, 52), (VP[0] + 4, 62)):
        c.c[y][x] = P("wraithWhite")
        c.c[y][x + 1] = P("wraithGlow")


def floor_and_lines(c):
    """The Throat's floor of scree running to the slit, and the three lines across it, each with its braziers: small
    warm pools held against the dark."""
    for y in range(100, 136):
        t = (y - 100) / 36.0
        half = 12 + 150 * t ** 1.4
        for x in range(int(VP[0] - half), int(VP[0] + half) + 1):
            if 0 <= x < W:
                lane = abs(x - VP[0]) < 4 + 30 * t
                n = h2(x // (2 + int(t * 5)), y // 2, 821)
                col = P("nightSlate") if lane and t < 0.5 else P("nightBlue")
                if n > 0.82:
                    col = P("nightHaze") if lane else P("nightSlate")
                elif n < 0.12:
                    col = P("nightDeep")
                c.c[y][x] = col
    for (y, hgt, fires, half) in ((106, 2, (-6, 7), 20), (113, 3, (-17, 18), 40), (124, 5, (-36, 34), 82)):
        for fx in fires:
            pool(c, VP[0] + fx, y + 1, 1.5 + hgt * 1.6, 0.8 + hgt * 0.3)
        for x in range(VP[0] - half, VP[0] + half + 1):
            for yy in range(y - hgt, y + 1):
                if 0 <= x < W:
                    c.c[yy][x] = P("night0") if yy > y - hgt else P("nightDeep")
            if (x - VP[0]) % (3 + hgt) == 0:
                for yy in range(y - hgt - max(1, hgt // 2), y - hgt):
                    if 0 <= x < W:
                        c.c[yy][x] = P("nightDeep")
        for fx in fires:
            x, top = VP[0] + fx, y - hgt - 1
            c.c[top][x] = P("fireGold")
            if hgt >= 3:
                c.c[top - 1][x] = P("fireWhite")
                c.c[top][x - 1] = P("fireOrange")
                c.c[top][x + 1] = P("fireOrange")
            if hgt >= 5:
                c.c[top - 2][x] = P("fireGold")
                c.c[top - 1][x - 1] = P("fireGold")


def pool(c, cx, cy, rx, ry):
    for y in range(int(cy - ry), int(cy + ry) + 1):
        for x in range(int(cx - rx), int(cx + rx) + 1):
            if 0 <= x < W and 0 <= y < H:
                d = math.hypot((x - cx) / float(rx), (y - cy) / float(ry))
                if d < 0.55:
                    c.c[y][x] = P("wood")
                elif d < 1.0:
                    c.c[y][x] = P("woodDark")


def battlement(c):
    """Our wall's top across the bottom: merlons and embrasures of dressed stone, cold in the night and warm by the
    brazier, in palette steps."""
    top = 136
    fire = (262, 128)

    def lv(x, y):
        d = math.hypot(x - fire[0], (y - fire[1]) * 1.4)
        return 3 if d < 26 else 2 if d < 54 else 1 if d < 100 else 0

    cold = ["nightDeep", "night2", "stoneDark", "stoneMid"]
    warm = ["stoneDark", "rockDark", "rock", "rockLight"]

    def stone(x, y):
        row = (y - top + 21) // 7
        off = (row * 5) % 11
        joint = (y - top + 21) % 7 == 6 or (x + off) % 11 == 0
        k = lv(((x + off) // 11) * 11 + 5 - off, row * 7 + top - 21 + 3)
        k2 = max(0, k - (1 if h2((x + off) // 11, row, 841) > 0.7 else 0))
        ramp = warm if k >= 2 else cold
        col = P(ramp[k2])
        if joint:
            col = P("night0") if k <= 1 else P("stoneDark")
        return col
    for y in range(top + 8, H):
        for x in range(W):
            c.c[y][x] = stone(x, y)
    x = -6
    while x < W:
        for y in range(top, top + 8):
            for xx in range(max(0, x), min(W, x + 15)):
                c.c[y][xx] = stone(xx, y)
        for xx in range(max(0, x), min(W, x + 15)):
            c.c[top - 1][xx] = step(stone(xx, top), 1)
        x += 24
    for xx in range(W):
        c.c[top + 8][xx] = step(stone(xx, top + 8), 1)


def brazier(c, x, y):
    iron = P("night0")
    for xx in range(x - 4, x + 5):
        for yy in range(y, y + 3):
            c.c[yy][xx] = iron
    for xx in range(x - 3, x + 4):
        c.c[y + 3][xx] = iron
    c.c[y + 4][x - 3] = iron
    c.c[y + 4][x + 3] = iron
    flame = [
        "....w....",
        "...wy....",
        "...yyw...",
        "..yyyy...",
        "..oyyyo..",
        ".ooyyyoo.",
        ".eooyoooe",
        "eeooooooe",
    ]
    legend = {"w": P("fireWhite"), "y": P("fireGold"), "o": P("fireOrange"), "e": P("ember")}
    for j, line in enumerate(flame):
        for i, ch in enumerate(line):
            if ch != ".":
                c.c[y - 8 + j][x - 4 + i] = legend[ch]
    for (dx, dy, n) in ((-2, -12, "fireGold"), (1, -15, "ember"), (3, -11, "fireGold"), (-1, -18, "ember")):
        c.c[y + dy][x + dx] = P(n)


def banner(c):
    """House Lantern's banner on its pole at the right edge: teal cloth in folds, the gold lantern on it, warm from the
    brazier below in palette steps."""
    px = 297
    for y in range(0, 136):
        c.c[y][px] = P("wood")
        c.c[y][px + 1] = P("woodDark")
    for x in range(px - 22, W):
        c.c[9][x] = P("wood")
        c.c[10][x] = P("woodDark")
    x0, x1 = px - 20, px + 28
    for x in range(x0, min(W, x1 + 1)):
        tail = abs(((x - x0) % 24) - 12)
        bottom = 96 + tail
        fold = (x - x0) % 8
        for y in range(11, bottom + 1):
            warm = y > 70
            col = P("roofDeep") if fold in (0, 1) else P("banner")
            if fold == 4 and warm:
                col = P("roofLight")
            if y > bottom - 2:
                col = P("gold") if (x + y) % 3 else P("roofDeep")
            c.c[y][x] = col
    emblem = [
        ".......g.......",
        "......g.g......",
        ".......g.......",
        ".....ggggg.....",
        "....gg...gg....",
        "...ggggggggg...",
        "...g.......g...",
        "..ggggggggggg..",
        "..g.yyyyyyy.g..",
        "..g.yyyWyyy.g..",
        "..g.yyWWWyy.g..",
        "..g.yWWWWWy.g..",
        "..g.yyWWWyy.g..",
        "..g.yyyWyyy.g..",
        "..g.yyyyyyy.g..",
        "..ggggggggggg..",
        "...g.......g...",
        "...ggggggggg...",
        ".....ggggg.....",
    ]
    legend = {"g": P("gold"), "y": P("wood"), "W": P("strawLight")}
    for j, line in enumerate(emblem):
        for i, ch in enumerate(line):
            if ch != ".":
                c.c[32 + j][px - 7 + i] = legend[ch]


def slide2():
    c = Canvas(P("nightDeep"))
    sky_and_slit(c)
    gloom(c)
    floor_and_lines(c)
    walls(c)
    banner(c)
    battlement(c)
    brazier(c, 262, 129)
    return c.finish(ALLOWED, protect=("fireWhite", "fireGold", "fireOrange", "ember", "wraithWhite", "wraithGlow",
                                      "farPale", "mist"))
