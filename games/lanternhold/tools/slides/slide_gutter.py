"""The Guttering Lantern (panels-2; STORY.md section 7, "The endings"): the door held, but the town did not love its
lord. Its light is a low red ember on a winter night, the light of a wick about to drown.

  slideGutter1        (slide_town.py) Tallowford on a winter night, five houses of its street, half their windows
                      dark; a family pulling a handcart out of the picture; the castle on the wall's shoulder
  slideGutter2Lord    the great hall at night, the hearth burned down to embers; the lord alone in the high chair, seen
  slideGutter2Lady    from behind; the court's benches empty (the leaning and the houses are said under it)
  slideGutter3        on the outer line among the rags of the night, Tamsin on her knees holding up a small coat in the
                      house's teal; a brazier low beside her; snow

Palette art (paint.finish).
"""
import math

from paint import P, W, H, Canvas, fbm, h1, h2, sprite, step, lit
from figure import Layer
from ending_kit import cluster, person, snow_flakes

# --- slide 1 lives in slide_town.py (fix round 1: five houses of their own, the castle on the wall's shoulder) -----


# --- slide 2: alone before the low hearth -----------------------------------------------------------------------------

G2_ALLOWED = ["night0", "night1", "night2", "nightDeep", "ink", "woodDark", "wood", "woodLight", "soilDark", "soil",
              "rockDeep", "rockDark", "tile", "crimsonDeep", "crimson", "emberDim", "ember", "fireOrange", "fireGold",
              "gold", "plumDeep"]

HEARTH = (214, 106)


def ember_level(x, y):
    d = math.hypot((x + 0.5 - HEARTH[0]) / 1.25, y + 0.5 - HEARTH[1])
    d += (fbm(x * 0.05, y * 0.05, 1511, 2) - 0.5) * 8
    if d < 30:
        return 3
    if d < 56:
        return 2
    if d < 90:
        return 1
    return 0


def hall_wall(c):
    """The hall's stone in the dark, warmed only near the hearth, in hard rings of deep red; big blocks in courses."""
    ramp = ["night0", "night1", "plumDeep", "crimsonDeep"]
    y0 = 0
    row = 0
    while y0 < 120:
        hgt = 12 + int(h1(row, 1501) * 5)
        x = -int(h1(row, 1503) * 30)
        j = 0
        while x < W:
            bw = 26 + int(h1(j + row * 11, 1505) * 22)
            lv_block = ember_level(x + bw // 2, y0 + hgt // 2)
            for y in range(y0, min(120, y0 + hgt)):
                for xx in range(max(0, x), min(W, x + bw)):
                    lv = lv_block
                    # the block's edge toward the fire a step brighter, the far edge a step darker
                    if lv > 0 and ((xx > x + bw - 3 and x + bw // 2 < HEARTH[0]) or (xx < x + 3 and x + bw // 2 > HEARTH[0])):
                        lv = min(3, lv + 1) if y < y0 + hgt - 2 else lv
                    joint = y == y0 + hgt - 1 or xx == x
                    c.c[y][xx] = P("night0" if joint and lv < 2 else ramp[max(0, lv - 1)] if joint else ramp[lv])
            x += bw
            j += 1
        y0 += hgt
        row += 1


def hearth(c):
    """The great hearth burned low: the stone surround warm only at its inner edge, the firebox dark, a bed of embers
    and one small flame."""
    hx = HEARTH[0]
    lay = Layer()
    lay.poly([(hx - 48, 40), (hx + 48, 40), (hx + 48, 49), (hx - 48, 49)], P("plumDeep"))
    lay.poly([(hx - 42, 49), (hx - 30, 49), (hx - 30, 118), (hx - 42, 118)], P("plumDeep"))
    lay.poly([(hx + 30, 49), (hx + 42, 49), (hx + 42, 118), (hx + 30, 118)], P("plumDeep"))
    lay.poly([(hx - 30, 53), (hx + 30, 53), (hx + 30, 118), (hx - 30, 118)], P("night0"))
    lay.paste(c)
    for x in range(hx - 48, hx + 49):
        c.c[48][x] = P("crimsonDeep")
    for y in range(49, 118):
        c.c[y][hx - 31] = P("crimson" if y > 90 else "crimsonDeep")
        c.c[y][hx + 30] = P("crimson" if y > 90 else "crimsonDeep")
    for x in range(hx - 26, hx + 27):
        top = 106 + 2.5 * math.sin(x * 0.4) + 2 * h1(x, 1507)
        for y in range(int(top), 118):
            n = fbm(x * 0.35, y * 0.5, 1509, 2)
            c.c[y][x] = P("fireOrange" if n > 0.66 else "ember" if n > 0.45 else "emberDim")
    for (x0, x1, y) in ((hx - 20, hx + 4, 105), (hx - 8, hx + 18, 108)):
        for x in range(x0, x1):
            c.c[y][x] = P("night0")
            c.c[y - 1][x] = P("emberDim") if x % 5 else P("ember")
    cluster(c, hx - 2, 96, ["..O..", ".OGO.", ".OGO.", "OGGGO", ".OOO."], {"O": "fireOrange", "G": "fireGold"})


def high_chair(form):
    """The lord in the high chair, seen from behind and a little to the left: the chair's tall back with its carved
    crest, the lord's head and shoulders above it (the circlet a thread of gold), the right arm on the armrest toward
    the fire."""
    lay = Layer()
    cx = 140
    wood = P("night1")
    # the high back: two posts with knobs, the crest between them carved, the back's panel
    lay.poly([(cx - 19, 150), (cx + 19, 150), (cx + 17, 104), (cx - 17, 104)], wood)

    for px in (cx - 19, cx + 17):
        lay.poly([(px, 106), (px + 3, 106), (px + 3, 150), (px, 150)], wood)
    # the armrests and the legs, the floor showing between them
    lay.poly([(cx + 18, 124), (cx + 34, 124), (cx + 34, 128), (cx + 18, 128)], wood)
    lay.poly([(cx - 34, 124), (cx - 18, 124), (cx - 18, 128), (cx - 34, 128)], wood)
    for lx in (cx - 33, cx - 20, cx + 18, cx + 31):
        lay.poly([(lx, 128), (lx + 3, 128), (lx + 3, 160), (lx, 160)], wood)
    lay.poly([(cx - 34, 146), (cx + 34, 146), (cx + 34, 150), (cx - 34, 150)], wood)
    lay.capsule((cx + 20, 106), (cx + 26, 122), 3.6, 3.2, P("night0"))
    lay.capsule((cx + 26, 122), (cx + 34, 124), 3.0, 2.4, P("night0"))
    lay.ellipse(cx, 104, 19, 6, P("night0"))
    lay.ellipse(cx + 1, 84, 8.0, 9.0, P("night0"))
    lay.capsule((cx + 1, 90), (cx, 100), 4.0, 5.0, P("night0"))
    if form == "lady":
        lay.poly([(cx - 7, 84), (cx + 9, 84), (cx + 10, 104), (cx - 8, 104)], P("night0"))
        lay.ellipse(cx + 1, 76, 5.0, 3.6, P("night0"))
    # the lord's hair: short and full for the Burgherr, a knot for the Burgherrin (above)
    if form != "lady":
        lay.ellipse(cx + 1, 79, 7.0, 4.0, P("night0"))
    return lay, (cx + 1, 80)


def slide2(form):
    c = Canvas(P("night0"))
    hall_wall(c)
    hearth(c)
    # the floor in the dark, a warm sheen spreading from the hearth
    for y in range(118, H):
        row = (y - 118) // 6
        for x in range(W):
            seg = (x + row * 17) // 30
            lv = ember_level(seg * 30 + 15 - row * 17, 118 + row * 6 + 3)
            joint = (y - 118) % 6 == 5 or (x + row * 17) % 30 == 0
            col = ["night0", "night1", "plumDeep", "crimsonDeep"][max(0, lv - (1 if joint else 0))]
            c.c[y][x] = P(col)
    for x in range(W):
        c.c[118][x] = P("rockDeep" if ember_level(x, 118) < 2 else "crimson")
    # the court's benches along the left wall, empty; the long table at the far right with nobody at it
    for (x0, x1, y) in ((6, 70, 132), (268, 318, 128)):
        for x in range(x0, x1):
            for yy in range(y, y + 4):
                lv = ember_level(x, yy)
                c.c[yy][x] = P(["night1", "woodDark", "wood", "woodLight"][lv] if yy == y else "night0")
        for lx in (x0 + 4, x1 - 6):
            for yy in range(y + 4, y + 12):
                c.c[yy][lx] = P("night0")
    chair, head = high_chair(form)
    # the lord's long shadow thrown away from the fire across the floor, to the left
    for (x, y) in list(chair.px):
        if y > 140:
            for s in range(1, 30):
                X = x - s
                if 0 <= X < W and (X, y) not in chair.px:
                    c.c[y][X] = P("night0")
    # the ember light along the edges that face the hearth
    for (x, y), col in list(chair.px.items()):
        if (x + 1, y) not in chair.px or ((x, y - 1) not in chair.px and x > 108):
            chair.px[(x, y)] = P("ember" if ember_level(x, y) >= 2 else "crimson")
    chair.paste(c)
    for dx in range(-4, 5):
        c.c[head[1]][head[0] + dx] = P("gold") if dx > -2 else P("crimsonDeep")
    return c.finish(G2_ALLOWED, protect=("fireGold", "fireOrange", "ember", "gold", "crimson"))


# --- slide 3: Tamsin and the small coat -------------------------------------------------------------------------------

G3_ALLOWED = ["night0", "night1", "nightDeep", "nightBlue", "nightSlate", "farDeep", "far", "mistDark", "mist",
              "mistLight", "stoneDark", "stoneMid", "stone", "woodDark", "wood", "woodLight", "soilDark", "soil",
              "tile", "tileLight", "crimsonDeep", "crimson", "emberDim", "ember", "fireOrange", "fireGold", "banner",
              "roofDeep", "roofLight", "tealDim", "ink", "plumDeep", "rockDeep", "rockDark"]

BRAZIER = (226, 116)
FLOOR3 = 124


def fire_d(x, y):
    return math.hypot(x + 0.5 - BRAZIER[0], (y + 0.5 - BRAZIER[1]) * 1.3) + (fbm(x * 0.09, y * 0.09, 1613, 2) - 0.5) * 8


def slide3():
    c = Canvas(P("nightDeep"))
    # the outer wall's face behind in the dark, its stones only where the fire reaches, a strip of night sky above
    for y in range(0, 22):
        for x in range(W):
            c.c[y][x] = P("nightDeep")
    y0 = 23
    row = 0
    while y0 < FLOOR3:
        hgt = 11 + int(h1(row, 1619) * 5)
        x = -int(h1(row, 1621) * 30)
        j = 0
        while x < W:
            bw = 24 + int(h1(j + row * 11, 1623) * 22)
            d = fire_d(x + bw / 2.0, y0 + hgt / 2.0)
            lv = 3 if d < 40 else 2 if d < 66 else 1 if d < 96 else 0
            for y in range(y0, min(FLOOR3, y0 + hgt)):
                for xx in range(max(0, x), min(W, x + bw)):
                    joint = y == y0 + hgt - 1 or xx == x
                    ramp = ["nightDeep", "night1", "plumDeep", "crimsonDeep"]
                    c.c[y][xx] = P(ramp[max(0, lv - 1)] if joint else ramp[lv])
            x += bw
            j += 1
        y0 += hgt
        row += 1
    for x in range(W):
        c.c[22][x] = P("farDeep")
    # the walk's stones under the snow, each flag lit as a whole by the fire, the snow on their front edge
    for y in range(FLOOR3, H):
        row = (y - FLOOR3) // 7
        for x in range(W):
            seg = (x + row * 13) // 34
            cxs = seg * 34 + 17 - row * 13
            d = fire_d(cxs, FLOOR3 + row * 7 + 3)
            lv = 2 if d < 34 else 1 if d < 62 else 0
            joint = (y - FLOOR3) % 7 == 6 or (x + row * 13) % 34 == 0
            if y < FLOOR3 + 2:
                col = ["mistDark", "tile", "tileLight"][lv]
            else:
                col = ["night1", "crimsonDeep", "tile"][max(0, lv - (1 if joint else 0))]
                if joint and lv == 0:
                    col = "nightDeep"
            c.c[y][x] = P(col)
    # the rags of the night heaped along the walk: grey, torn, their edges toward the fire catching it
    rags = Layer()
    for k in range(8):
        x = int(12 + k * 26 + h1(k, 1601) * 10)
        if 100 < x < 250:
            continue
        rx = 10 + h1(k, 1602) * 9
        ry = 4 + h1(k, 1603) * 5
        for yy in range(int(FLOOR3 + 8 - ry), FLOOR3 + 9):
            for xx in range(int(x - rx), int(x + rx) + 1):
                torn = fbm(xx * 0.4, yy * 0.3, 1604, 2)
                if ((xx - x) / rx) ** 2 + ((yy - FLOOR3 - 8) / ry) ** 2 <= 1 - (0.3 if torn > 0.6 else 0):
                    rags.put(xx, yy, P("stoneDark" if torn > 0.45 else "night1"))
    for (x, y), col in list(rags.px.items()):
        if (x, y - 1) not in rags.px:
            rags.px[(x, y)] = P("stoneMid") if fire_d(x, y) > 58 else P("tile")
    rags.paste(c)
    cluster(c, 52, FLOOR3 + 1, [".kk.", "k..k", "kkkk", ".kk."], {"k": "night0"})
    # the brazier, its fire low: an iron bowl on legs, coals and a few tongues of flame
    bx, by = BRAZIER
    cluster(c, bx - 12, by - 8 - 4, [".......G.........G......",
                                     "......GOG.......GOG.....",
                                     "......OGO...G...OGO.....",
                                     ".....O.O...OGO...O.O....",".......O.......O........",
                                 "....O..OO...O..OO..O.....",
                                 "...OGO.OGO.OGO.OGOOGO....",
                                 "..oOGOoOGOoOGOoOGOoOGOo..",
                                 ".ooooooooooooooooooooooo.",
                                 "kkkkkkkkkkkkkkkkkkkkkkkkk",
                                 ".kkkkkkkkkkkkkkkkkkkkkkk.",
                                 "...kkkkkkkkkkkkkkkkkkk...",
                                 ".....kk...........kk.....",
                                 "....kk.............kk....",
                                 "...kk...............kk...",
                                 "..kk.................kk.."],
            {"k": "night0", "o": "ember", "O": "fireOrange", "G": "fireGold"})
    # Tamsin on her knees, side on, facing the fire: a stout dark shape, the kerchief knotted at her nape, her back
    # bowed, her skirt spread on the snow behind her; both arms out holding the small coat up to the light
    t = Layer()
    tx, base = 140, FLOOR3 + 12
    body = P("night0")
    t.poly([(tx - 36, base), (tx + 4, base), (tx + 2, base - 16), (tx - 26, base - 14)], body)
    t.ellipse(tx - 12, base - 22, 15, 14, body)
    t.ellipse(tx - 6, base - 38, 13, 12, body)
    t.ellipse(tx + 1, base - 56, 7.5, 8.0, body)
    t.poly([(tx - 6, base - 60), (tx - 14, base - 52), (tx - 9, base - 50)], body)
    t.poly([(tx - 8, base - 54), (tx - 15, base - 46), (tx - 12, base - 45)], body)
    t.capsule((tx + 2, base - 44), (tx + 20, base - 48), 3.6, 3.0, body)
    t.capsule((tx, base - 38), (tx + 20, base - 40), 3.4, 2.8, body)
    # the face in profile toward the fire: brow, nose, the lips pressed shut, the chin
    for (dx, dy) in ((7, -61), (8, -60), (8, -59), (9, -58), (10, -57), (9, -56), (8, -55), (9, -54), (8, -53),
                     (7, -52)):
        t.put(tx + dx, base + dy, body)
    # the fire's light on every edge that faces it: the face, the knuckles, the kerchief's front, the shoulder
    for (x, y), col in list(t.px.items()):
        if (x + 1, y) not in t.px or ((x, y - 1) not in t.px and x > tx - 4):
            t.px[(x, y)] = P("fireOrange" if y < base - 50 and x > tx + 4 else "ember")
        elif (x + 2, y) not in t.px and y < base - 30:
            t.px[(x, y)] = P("crimson")
    t.paste(c)
    c.c[base - 57][tx + 5] = P("tile")
    # the coat: small, in the house's teal, held up by its shoulders, sleeves hanging, a hood fallen back, a torn hem;
    # the fire lights its side toward it
    coat = Layer()
    cx0, cy0 = tx + 18, base - 52
    coat.poly([(cx0, cy0 + 4), (cx0 + 20, cy0 + 4), (cx0 + 23, cy0 + 30), (cx0 - 3, cy0 + 30)], P("banner"))
    coat.ellipse(cx0 + 10, cy0 + 3, 7, 3.5, P("roofDeep"))
    coat.poly([(cx0, cy0 + 4), (cx0 - 6, cy0 + 20), (cx0 - 3, cy0 + 21), (cx0 + 3, cy0 + 10)], P("roofDeep"))
    coat.poly([(cx0 + 20, cy0 + 4), (cx0 + 26, cy0 + 20), (cx0 + 23, cy0 + 21), (cx0 + 17, cy0 + 10)], P("banner"))
    for y in range(cy0 + 6, cy0 + 29):
        coat.put(cx0 + 10, y, P("roofDeep"))
    for y in range(cy0 + 9, cy0 + 28, 5):
        coat.put(cx0 + 12, y, P("tealDim"))
    for x in range(cx0 - 3, cx0 + 24):
        if h1(x, 1615) > 0.55:
            coat.put(x, cy0 + 30, P("roofDeep"))
        if h1(x, 1617) > 0.8:
            coat.px.pop((x, cy0 + 29), None)
    for (x, y), col in list(coat.px.items()):
        if (x + 1, y) not in coat.px:
            coat.px[(x, y)] = P("roofLight")
    coat.outline(P("night0"), skip_bottom=False)
    coat.paste(c)
    # her two hands at the coat's shoulders, the knuckles lit
    for (hx, hy) in ((cx0 + 1, cy0 + 4), (cx0 + 19, cy0 + 4)):
        cluster(c, hx - 2, hy - 2, [".kk.", "kOOk", ".kk."], {"k": "night0", "O": "ember"})
    snow_flakes(c, 60, 1611, colour="mistDark", bright="mist", y_max=FLOOR3)
    return c.finish(G3_ALLOWED, protect=("fireGold", "fireOrange", "ember", "roofLight", "banner", "tealDim"))


SLIDES = {
    "slideGutter2Lord": lambda: slide2("lord"),
    "slideGutter2Lady": lambda: slide2("lady"),
    "slideGutter3": slide3,
}
