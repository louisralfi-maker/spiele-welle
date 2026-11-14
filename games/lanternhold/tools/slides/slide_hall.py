"""Slide 4 of the prologue (panels lane; HOUSE.md section 1, the director's note of 15:03, critic look 1 blocker 1):
the heir of the guardian house before the hearth, taking up the house's gold lantern from Odile, the court close
around them in a half ring. The circlet sits right; the cloak is mended; nothing of a lamplighter. Two pictures: the
Burgherr's and the Burgherrin's (the court's own portraits). Palette art: every light is a step along a palette ramp.
"""
import math

from paint import P, W, H, PAL, Canvas, h1, h2, sprite, step
from figure import Layer, downscale, lit_steps

FIRE = (163, 84)          # the Flame in the hearth
LANTERN = (164, 112)      # the house's lantern, between the two hands

ALLOWED = ["night0", "ink", "soilDark", "woodDark", "wood", "woodLight", "straw", "strawLight", "parchment",
           "rockDeep", "rockDark", "rock", "rockLight", "rockPale", "tile", "tileLight", "dawnRose", "ember",
           "fireOrange", "fireGold", "fireWhite", "gold", "banner", "roofDeep", "roofLight", "daySky", "stoneDark",
           "stoneMid", "stone", "stoneLight", "stonePale", "foam", "plumDeep", "plum", "plumLight", "crimsonDeep",
           "crimson", "crimsonLight", "dusk", "soil", "soilLight", "night2", "night1", "moorDark", "moor",
           "plasterDim", "plaster"]


def dist(x, y, p):
    return math.hypot(x + 0.5 - p[0], (y + 0.5 - p[1]) * 1.15)


def wall_level(x, y):
    """How lit the hall's stone is: the hearth's light, in hard rings."""
    d = dist(x, y, FIRE)
    if d < 46:
        return 4
    if d < 74:
        return 3
    if d < 104:
        return 2
    if d < 138:
        return 1
    return 0


ROCK = ["night0", "rockDeep", "rockDark", "rock", "rockLight", "rockPale"]


def back_wall(c):
    # stone courses, each block one flat colour (its level, sometimes a step down), mortar a step darker
    course = 9
    for row in range(0, 14):
        y0 = 6 + row * course
        x = -int(h1(row, 401) * 14)
        k = 0
        while x < W:
            bw = 13 + int(h1(k + row * 37, 403) * 9)
            dk = -1 if h2(k, row, 405) > 0.72 else 0
            lv = wall_level(x + bw // 2, y0 + course // 2)
            for y in range(y0, y0 + course):
                for xx in range(max(0, x), min(W, x + bw)):
                    mortar = (y == y0 + course - 1) or xx == x
                    i = max(0, min(5, lv + dk - (1 if mortar else 0)))
                    if mortar and lv <= 1:
                        i = 0
                    c.c[y][xx] = P(ROCK[i])
            x += bw
            k += 1
    # the roof's great beam and the dark above it
    for y in range(0, 12):
        for x in range(W):
            if y < 4:
                col = P("night0")
            elif y == 4:
                col = P("wood") if abs(x - FIRE[0]) < 110 else P("woodDark")
            elif y < 11:
                col = P("woodDark") if abs(x - FIRE[0]) < 140 else P("soilDark")
            else:
                col = P("night0")
            c.c[y][x] = col
    for bx in (34, 112, 214, 292):
        for y in range(4, 11):
            c.c[y][bx] = P("night0")


def chimney(c):
    """The chimney breast over the hearth, a step forward of the wall, and the hearth's mantel and jambs."""
    x0, x1 = 118, 208
    for y in range(12, 54):
        for x in range(x0, x1 + 1):
            row = (y - 12) // 9
            bx = (x - x0 + (9 if row % 2 else 0)) // 18
            cxb = x0 + bx * 18 - (9 if row % 2 else 0) + 9
            lv = wall_level(cxb, 12 + row * 9 + 4) + (1 if row >= 3 else 0) - (1 if h2(bx, row, 409) > 0.75 else 0)
            col = P(ROCK[min(5, max(0, lv))])
            if (y - 12) % 9 == 8 or (x - x0 + (9 if row % 2 else 0)) % 18 == 0:
                col = step(col, -1)
            if x in (x0, x0 + 1):
                col = P("rockDeep")
            if x in (x1, x1 - 1):
                col = P("rockDark") if y > 30 else P("rockDeep")
            c.c[y][x] = col
    # the mantel shelf
    for y in range(50, 58):
        for x in range(108, 219):
            if y == 50:
                col = P("rockPale") if 120 < x < 206 else P("rockLight")
            elif y < 55:
                col = P("rockLight") if 114 < x < 212 else P("rock")
            elif y == 55:
                col = P("rockDark")
            else:
                col = P("rockDeep")
            c.c[y][x] = col
    # the jambs
    for y in range(58, 112):
        for x in list(range(114, 126)) + list(range(200, 212)):
            inner = x in (124, 125, 200, 201)
            lv = 4 if inner else 2 if y < 80 else 3
            col = P(ROCK[lv])
            if inner:
                col = P("tile") if y > 70 else P("rockLight")
            if (y - 58) % 10 == 9:
                col = step(col, -1)
            if x in (114, 211):
                col = P("rockDeep")
            c.c[y][x] = col
    # the hearth's mouth: soot at the back, the fire's light on the firebrick
    for y in range(58, 108):
        for x in range(126, 200):
            d = dist(x, y, (FIRE[0], FIRE[1] + 12))
            if d < 22:
                col = P("tile")
            elif d < 32:
                col = P("woodDark")
            elif d < 44:
                col = P("soilDark")
            else:
                col = P("night0")
            if y < 61:
                col = P("night0")
            c.c[y][x] = col
    # the hearthstone
    for y in range(108, 113):
        for x in range(110, 216):
            col = P("rockLight") if y == 108 else P("rock") if y < 111 else P("rockDark")
            c.c[y][x] = col


def fire(c):
    """The Flame: logs on their irons, the fire in tongues, white at its heart."""
    cx, base = FIRE[0], 105
    lay = Layer()
    # the logs
    lay.capsule((136, base - 1), (188, base - 3), 2.6, 2.6, P("woodDark"))
    lay.capsule((142, base - 5), (182, base + 1), 2.2, 2.2, P("wood"))
    for x in range(138, 188, 5):
        lay.put(x, base - 2 + (x % 3) - 1, P("ember"))
    lay.paste(c)
    tongues = [(-14, 16, 5), (-8, 26, 6), (-2, 36, 7), (5, 30, 6), (11, 22, 5), (16, 13, 4), (-18, 10, 3),
               (1, 24, 9)]
    layers = [("ember", 1.0), ("fireOrange", 0.78), ("fireGold", 0.55), ("fireWhite", 0.28)]
    for name, k in layers:
        col = P(name)
        for dx, hgt, half in tongues:
            hh = hgt * (0.55 + 0.45 * k) if name != "ember" else hgt
            hw = half * k + (0.6 if name == "fireWhite" else 0)
            tip_dx = dx * 0.25 + (1 if dx > 0 else -1) * 1.5
            pts = [(cx + dx - hw, base - 2), (cx + dx + hw, base - 2), (cx + dx + hw * 0.45, base - 2 - hh * 0.55),
                   (cx + tip_dx + dx * 0.6, base - 2 - hh), (cx + dx - hw * 0.5, base - 2 - hh * 0.5)]
            c.poly(pts, col)
    # sparks going up the flue
    for (x, y, n) in ((158, 64, "fireGold"), (168, 60, "fireOrange"), (163, 56, "ember"), (171, 70, "fireGold")):
        c.put(x, y, P(n))


def banner(c, x0, top, length):
    """A banner of the house, old and faded: teal cloth, the gold lantern, a frayed hem."""
    w = 22
    for y in range(top, top + length):
        for x in range(x0, x0 + w):
            lv = wall_level(x, y)
            col = P("roofDeep") if lv <= 1 else P("banner")
            if (x - x0) in (0, w - 1):
                col = P("roofDeep") if lv >= 2 else P("night0")
            if lv >= 3 and (x - x0) in (3, 4, 12):
                col = P("roofLight")
            c.c[y][x] = col
    # the swallowtail hem
    for x in range(x0, x0 + w):
        drop = abs((x - x0) - w / 2.0)
        for y in range(top + length, top + length + int(7 - drop * 0.6) + 1):
            c.c[y][x] = P("roofDeep")
    for x in range(x0 + 2, x0 + w - 2, 3):
        c.c[top + length - 2][x] = P("night0")
    # the rod
    for x in range(x0 - 2, x0 + w + 2):
        c.c[top - 1][x] = P("woodDark")
    # the house's lantern on it, in faded gold
    g, d = P("gold"), P("wood")
    emblem = """
..ggg..
.g...g.
ggggggg
g.ddd.g
g.dgd.g
g.ddd.g
ggggggg
.ggggg.
"""
    lines = emblem.strip("\n").split("\n")
    ex = x0 + (w - 7) // 2
    for yy, line in enumerate(lines):
        for xx, ch in enumerate(line):
            if ch == "g":
                c.c[top + 12 + yy][ex + xx] = g if wall_level(ex + xx, top + 12 + yy) >= 2 else P("straw")
            elif ch == "d":
                c.c[top + 12 + yy][ex + xx] = d


def floor(c):
    for y in range(113, H):
        for x in range(W):
            t = (y - 113) / 47.0
            seam_y = (y - 113) in (4, 11, 21, 34)
            span = 18 + t * 30
            seam_x = int((x - FIRE[0]) / span + 100 + (0.5 if ((y - 113) // 7) % 2 else 0)) != \
                int((x + 1 - FIRE[0]) / span + 100 + (0.5 if ((y - 113) // 7) % 2 else 0))
            d = dist(x, y, (FIRE[0], 112))
            lv = 3 if d < 40 else 2 if d < 70 else 1 if d < 110 else 0
            col = P(ROCK[lv])
            if seam_y or seam_x:
                col = P(ROCK[max(0, lv - 1)])
            c.c[y][x] = col


# --- the court -------------------------------------------------------------------------------------------------------

def court_member(c, name, x0, y0, flip, body, size=32, lift=0):
    """A member of the court a little behind the two in front: the portrait carried down by area vote, the body drawn
    on below it in the portrait's own cloth, lit by the hearth from the side that faces it. The half ring opens toward
    us: those at its ends stand nearer and larger, those by the hearth smaller."""
    rows = downscale(sprite(name), size)
    lay = Layer()
    body(lay, x0, y0, flip, size / 32.0)
    lay.rows(rows, x0, y0, flip=flip)
    lay.outline()

    def light(x, y):
        d = dist(x, y, FIRE)
        return (0 if d < 72 else -1 if d < 110 else -2) + (lift if y < y0 + size else 0)
    lit_steps(lay, light, rim=(FIRE[0], FIRE[1], 2))
    lay.paste(c)


def robe(lay, cx, top, bottom, w_top, w_bot, colour, fold=None, sleeves=None, hands=None, belt=None, apron=None,
         skirt_flare=0, f=1.0):
    """A standing body from the shoulders down: a robe or tunic that narrows to the waist and falls to the floor, the
    arms hanging in their sleeves, hands at the hip, an apron or belt where the life asks for one."""
    w_top, w_bot, skirt_flare = w_top * f, w_bot * f, skirt_flare * f
    waist = top + int(34 * f)
    pts = [(cx - w_top, top), (cx + w_top, top), (cx + w_top * 0.86, waist), (cx + w_bot + skirt_flare, bottom),
           (cx - w_bot - skirt_flare, bottom), (cx - w_top * 0.86, waist)]
    lay.poly(pts, colour)
    sl = sleeves or step(colour, -1)
    for side in (-1, 1):
        sx = cx + side * (w_top - 2.5 * f)
        lay.capsule((sx, top + 3 * f), (sx + side * 1.5 * f, waist + 9 * f), 3.0 * f, 2.6 * f, sl)
        if hands:
            lay.ellipse(sx + side * 1.5 * f, waist + 11 * f, 2.2 * f, 2.0 * f, hands)
    if apron:
        lay.poly([(cx - w_top * 0.55, waist - 6 * f), (cx + w_top * 0.55, waist - 6 * f),
                  (cx + w_bot * 0.62, bottom - 6), (cx - w_bot * 0.62, bottom - 6)], apron)
    if belt:
        for x in range(int(cx - w_top * 0.86), int(cx + w_top * 0.86) + 1):
            lay.put(x, waist, belt)
            lay.put(x, waist + 1, step(belt, -1))
    if fold:
        for fx in fold:
            lay.line([(cx + fx * f, waist + 3), (cx + fx * f * 1.35, bottom - 1)], step(colour, -1))
    return waist


def body_brannock(lay, x0, y0, flip, f):
    cx = x0 + 15 * f
    waist = robe(lay, cx, y0 + 30 * f, H + 2, 14, 15, P("roofLight"), fold=(-5, 4), sleeves=P("stone"),
                 hands=P("dawnRose"), belt=P("woodDark"), f=f)
    # the mail shirt showing below the surcoat, ring rows; the sword's hilt at the belt
    for y in range(int(waist + 16 * f), H):
        for x in range(int(cx - 16 * f), int(cx + 17 * f)):
            if lay.has(x, y):
                lay.put(x, y, P("stoneMid") if y % 2 == 0 else P("stone"))
    sx = 1 if not flip else -1
    lay.capsule((cx + sx * 6 * f, waist - 2), (cx + sx * 10 * f, waist + 12 * f), 1.0, 1.0, P("stoneLight"))
    lay.put(cx + sx * 6 * f, waist - 3, P("gold"))


def body_pip(lay, x0, y0, flip, f):
    cx = x0 + 16 * f
    waist = robe(lay, cx, y0 + 29 * f, H + 2, 13, 12, P("roofLight"), sleeves=P("plum"), hands=P("dawnRose"),
                 belt=P("gold"), f=f)
    # motley: one half plum, the other teal, in lozenges of a step
    for (x, y), col in list(lay.px.items()):
        if y > y0 + 31 * f and col == P("roofLight") and (x > cx) != flip:
            lay.put(x, y, P("plum"))
    for dx in (-6, 0, 6):
        lay.put(cx + dx * f, waist + 2, P("gold"))


def body_hesper(lay, x0, y0, flip, f):
    cx = x0 + 15 * f
    waist = robe(lay, cx, y0 + 29 * f, H + 2, 14, 17, P("straw"), fold=(-6, -1, 5), sleeves=P("straw"),
                 skirt_flare=2, f=f)
    # hands folded at the front over the robe, a cord at the waist
    lay.ellipse(cx + 1, waist - 2, 3.2 * f, 2.2 * f, P("woodLight"))
    lay.line([(cx - 2 * f, waist - 2), (cx + 4 * f, waist - 2)], P("wood"))
    lay.line([(cx - 3 * f, waist + 2), (cx - 4 * f, waist + 16 * f)], P("strawLight"))


def body_bram(lay, x0, y0, flip, f):
    cx = x0 + 16 * f
    waist = robe(lay, cx, y0 + 30 * f, H + 2, 15, 14, P("rockDark"), sleeves=P("rockDark"), hands=P("tile"),
                 apron=P("wood"), fold=(-4, 5), f=f)
    # the apron's straps; scorch marks from the forge
    for side in (-6, 6):
        lay.line([(cx + side * f, y0 + 30 * f), (cx + side * f, waist - 6 * f)], P("woodDark"))
    for (dx, dy) in ((-3, 24), (4, 30), (1, 37), (-5, 42)):
        lay.put(cx + dx * f, waist + dy * f, P("woodDark"))
        lay.put(cx + dx * f + 1, waist + dy * f, P("woodDark"))


def body_tamsin(lay, x0, y0, flip, f):
    cx = x0 + 16 * f
    waist = robe(lay, cx, y0 + 29 * f, H + 2, 13, 15, P("tile"), sleeves=P("tile"), hands=P("tileLight"),
                 apron=P("plasterDim"), skirt_flare=2, f=f)
    # a patch and a stain on the apron: a worker's
    for (dx, dy) in ((-2, 26), (3, 32)):
        lay.put(cx + dx * f, waist + dy * f, P("soilLight"))
        lay.put(cx + dx * f + 1, waist + dy * f, P("soilLight"))
        lay.put(cx + dx * f, waist + dy * f + 1, P("soilLight"))


# --- the two in front ------------------------------------------------------------------------------------------------

def heir(c, form, x0, y0):
    """The heir, half length: the court's own portrait (the circlet as it sits), the house's teal cloak over a red
    tunic, the cloak old and mended at the shoulder, both hands up at the lantern's ring."""
    rows = sprite("portraitLady" if form == "lady" else "portraitKing")
    lay = Layer()
    teal, teal_dk, teal_lt = P("roofLight"), P("banner"), P("daySky")
    tunic, tunic_dk = P("crimson"), P("crimsonDeep")
    top = y0 + 47
    # the cloak falls from both shoulders, open in front over the tunic
    lay.poly([(x0 + 0, top - 6), (x0 + 22, top), (x0 + 20, H + 2), (x0 - 4, H + 2)], teal)
    lay.poly([(x0 + 21, top), (x0 + 33, top), (x0 + 34, H + 2), (x0 + 19, H + 2)], tunic)
    lay.poly([(x0 + 32, top), (x0 + 47, top - 4), (x0 + 50, H + 2), (x0 + 33, H + 2)], teal)
    # folds down the cloak
    for fx, sway in ((x0 + 6, -2), (x0 + 13, 1), (x0 + 41, 2)):
        lay.line([(fx + 1, top + 4), (fx + sway + 1, top + 30), (fx + sway * 2 + 1, H)], teal_lt)
        lay.line([(fx, top + 2), (fx + sway, top + 30), (fx + sway * 2, H)], teal_dk)
    lay.line([(x0 + 3, top + 4), (x0 + 2, H)], teal_lt)
    lay.line([(x0 + 17, top + 3), (x0 + 18, H)], teal_dk)
    # the tunic's belt
    for x in range(x0 + 21, x0 + 34):
        lay.put(x, top + 30, P("woodDark"))
        lay.put(x, top + 31, P("wood"))
    lay.put(x0 + 27, top + 30, P("gold"))
    # the mended place: an older cloth set into the cloak below the near shoulder, stitched round
    px0, py0 = x0 + 4, top + 14
    for y in range(py0, py0 + 9):
        for x in range(px0, px0 + 8):
            lay.put(x, y, P("roofDeep") if (x + y) % 5 else P("banner"))
    for x in range(px0 - 1, px0 + 9, 2):
        lay.put(x, py0 - 1, P("strawLight"))
        lay.put(x + 1, py0 + 9, P("strawLight"))
    for y in range(py0, py0 + 9, 2):
        lay.put(px0 - 1, y + 1, P("strawLight"))
        lay.put(px0 + 8, y, P("strawLight"))
    # the arms: from the near shoulder down to the elbow and forward up to the ring of the lantern
    sleeve = P("wood")
    lay.capsule((x0 + 37, top + 2), (x0 + 43, top + 22), 4.4, 4.0, teal)
    lay.capsule((x0 + 43, top + 22), (LANTERN[0] - 4, LANTERN[1] - 14), 3.6, 3.0, sleeve)
    lay.capsule((x0 + 30, top + 6), (x0 + 36, top + 24), 3.4, 3.2, sleeve)
    lay.capsule((x0 + 36, top + 24), (LANTERN[0] - 6, LANTERN[1] - 10), 3.0, 2.6, sleeve)
    tun = P("tileLight")
    lay.rows(rows, x0, y0, remap=None)
    for y in range(y0 + 36, y0 + 48):
        for x in range(x0 + 16, x0 + 36):
            if lay.get(x, y) == tun:
                lay.put(x, y, tunic)
            elif lay.get(x, y) == P("tile"):
                lay.put(x, y, tunic_dk)
    # the hands on the ring
    hand = P("dawnRose")
    lay.ellipse(LANTERN[0] - 3, LANTERN[1] - 14, 2.6, 2.4, hand)
    lay.ellipse(LANTERN[0] - 5, LANTERN[1] - 9, 2.6, 2.3, hand)
    lay.outline()

    def light(x, y):
        d = dist(x, y, LANTERN)
        if d < 15:
            return 1
        if d < 28:
            return 0
        return -1
    lit_steps(lay, light, rim=(FIRE[0], FIRE[1], 1))
    lay.paste(c)


def odile(c, x0, y0):
    """Odile, half length, facing the heir: her dark dress and her chain of office, both hands under the lantern's
    foot, giving it up."""
    rows = sprite("portraitOdile")
    lay = Layer()
    dress, dress_dk = P("stoneMid"), P("rockDeep")
    top = y0 + 47
    # mirrored: her front faces left
    lay.poly([(x0 + 1, top - 6), (x0 + 47, top - 6), (x0 + 50, H + 2), (x0 - 2, H + 2)], dress)
    lay.poly([(x0 + 17, top), (x0 + 24, top), (x0 + 23, H + 2), (x0 + 16, H + 2)], P("dusk"))
    for fx, sway in ((x0 + 7, -1), (x0 + 30, 1), (x0 + 38, 2)):
        lay.line([(fx - 1, top + 4), (fx + sway * 2 - 1, H)], P("stone"))
        lay.line([(fx, top + 2), (fx + sway * 2, H)], dress_dk)
    # the keys of the house at her girdle
    for x in range(x0 + 2, x0 + 46):
        lay.put(x, top + 29, P("woodDark"))
    for (dx, dy) in ((10, 31), (11, 33), (10, 35), (12, 32), (12, 34)):
        lay.put(x0 + dx, top + dy, P("gold"))
    # the arms: forward and a little up, both hands under the lantern's foot
    lay.capsule((x0 + 11, top + 2), (x0 + 6, top + 22), 4.4, 4.0, dress)
    lay.capsule((x0 + 6, top + 22), (LANTERN[0] + 6, LANTERN[1] + 5), 3.6, 3.0, dress)
    lay.capsule((x0 + 18, top + 6), (x0 + 13, top + 24), 3.4, 3.0, dress_dk)
    lay.capsule((x0 + 13, top + 24), (LANTERN[0] + 2, LANTERN[1] + 7), 3.0, 2.6, dress_dk)
    lay.rows(rows, x0, y0, flip=True)
    hand = P("dawnRose")
    lay.ellipse(LANTERN[0] + 4, LANTERN[1] + 5, 3.0, 2.0, hand)
    lay.ellipse(LANTERN[0] + 0, LANTERN[1] + 6, 2.8, 1.8, hand)
    lay.outline()

    def light(x, y):
        d = dist(x, y, LANTERN)
        if d < 15:
            return 1
        if d < 28:
            return 0
        return -1
    lit_steps(lay, light, rim=(FIRE[0], FIRE[1], 1))
    lay.paste(c)


LANTERN_ART = """
.......ggg.......
......g...g......
......g...g......
.......ggg.......
.....GgggggG.....
....GgGgGgGgG....
...GGGGGGGGGGG...
..gggggggggggggG.
..gGyyyyGyyyyGgG.
..gGywwyGywwyGgG.
..gGwwwwGwwwwGgG.
..gGwwWwGwWwwGgG.
..gGwwWWGWWwwGgG.
..gGwwwWGWwwwGgG.
..gGywwwGwwwyGgG.
..gGyywwGwwyyGgG.
..gGyyyyGyyyyGgG.
..gggggggggggggG.
...GGGGGGGGGGG...
....gggggggggG...
.....GGGGGGGG....
"""


def lantern(c):
    """The house's gold lantern (the banner's lantern made real): a ring, a pierced cap, four panes of light, a foot;
    and its light thrown round in hard steps."""
    lines = LANTERN_ART.strip("\n").split("\n")
    lw = len(lines[0])
    x0 = LANTERN[0] - lw // 2
    y0 = LANTERN[1] - 17
    legend = {"g": P("gold"), "G": P("wood"), "y": P("fireGold"), "w": P("fireWhite"), "W": P("fireWhite")}
    for yy, line in enumerate(lines):
        for xx, ch in enumerate(line):
            if ch != ".":
                c.c[y0 + yy][x0 + xx] = legend[ch]


def slide4(form):
    c = Canvas(P("night0"))
    back_wall(c)
    banner(c, 72, 18, 46)
    banner(c, 232, 18, 46)
    chimney(c)
    fire(c)
    floor(c)
    # the court in a half ring, close: the hearth's light on the sides that face it
    court_member(c, "portraitHesper", 74, 58, False, body_hesper, 27, lift=1)
    court_member(c, "portraitBram", 230, 58, True, body_bram, 28)
    court_member(c, "portraitPip", 40, 64, False, body_pip, 30)
    court_member(c, "portraitBrannock", -2, 58, False, body_brannock, 36)
    court_member(c, "portraitTamsin", 274, 60, True, body_tamsin, 35)
    # the two in front, the lantern between their hands
    heir(c, form, 96, 44)
    odile(c, 182, 46)
    lantern(c)
    return c.finish(ALLOWED)
