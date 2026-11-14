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
              "rockDeep", "rockDark", "tile", "tileLight", "crimsonDeep", "crimson", "emberDim", "ember",
              "fireOrange", "fireGold", "gold", "plumDeep"]

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


LORD_X = 156             # the middle of the lord's back


def chair_and_lord(form):
    """The lord alone in the high chair before the low hearth, seen from behind and to the left (three quarters from
    the back): the chair's back in front of us up to the shoulder blades, its posts with their knobs; above it the
    lord's back and shoulders under the mended cloak, slumped, the head bowed toward the embers; the right arm along
    the chair's arm with the hand hanging limp over its end before the fire; the circlet a few pixels of gold on the
    hair where the ember catches it. The Burgherrin's hair falls down her back in a braid. Returns the figure (a
    layer, unlit: one colour per part) and the parts' keys for lighting."""
    cx = LORD_X
    parts = {}

    def put(lay, key, pts=None, ellipse=None, capsule=None):
        sub = Layer()
        if pts:
            sub.poly(pts, P("night0"))
        if ellipse:
            sub.ellipse(*ellipse, P("night0"))
        if capsule:
            sub.capsule(*capsule, P("night0"))
        for k in sub.px:
            lay.px[k] = P("night0")
            parts[k] = key
    lay = Layer()
    # the cloak over the back and the slumped shoulders, falling behind the chair; the right shoulder a little higher
    # and nearer the fire
    put(lay, "cloak", pts=[(cx - 21, 88), (cx - 8, 81), (cx + 10, 80), (cx + 21, 85), (cx + 25, 104), (cx + 23, 126),
                           (cx - 25, 126), (cx - 26, 104)])
    put(lay, "cloak", ellipse=(cx - 17, 90, 8.5, 7.0))
    put(lay, "cloak", ellipse=(cx + 16, 87, 8.5, 7.0))
    # the head bowed forward toward the fire: only the back of the head, the hair, a sliver of cheek and ear
    # (the head is a hand-set grid, laid on after the light: HEAD_LORD / HEAD_LADY)
    if form == "lady":
        # her hair gathered in a braid down her back over the cloak
        for k in range(10):
            y = 86 + k * 2.2
            put(lay, "braid", ellipse=(cx + 5 - k * 0.3, y, 2.4 - k * 0.06, 1.6))
    # the right arm along the chair's arm toward the fire, the hand hanging over its end
    put(lay, "sleeve", capsule=((cx + 19, 90), (cx + 26, 108), 4.4, 3.8))
    put(lay, "sleeve", capsule=((cx + 26, 108), (cx + 37, 112), 3.6, 3.0))
    put(lay, "hand", pts=[(cx + 38, 110), (cx + 42, 111), (cx + 43, 116), (cx + 42, 121), (cx + 39, 121),
                          (cx + 38, 116)])
    # the chair: its back in front of the lord, the two posts with knobs, the right arm and its front post, the legs
    put(lay, "chair", pts=[(cx - 24, 99), (cx + 19, 98), (cx + 19, 136), (cx - 24, 136)])
    put(lay, "post", pts=[(cx - 27, 92), (cx - 22, 92), (cx - 22, 152), (cx - 27, 152)])
    put(lay, "post", pts=[(cx + 18, 91), (cx + 23, 91), (cx + 23, 152), (cx + 18, 152)])
    put(lay, "post", ellipse=(cx - 24.5, 90, 3.2, 3.0))
    put(lay, "post", ellipse=(cx + 20.5, 89, 3.2, 3.0))
    put(lay, "chair", pts=[(cx + 23, 112), (cx + 38, 113), (cx + 38, 117), (cx + 23, 117)])
    put(lay, "post", pts=[(cx + 34, 117), (cx + 37, 117), (cx + 37, 150), (cx + 34, 150)])
    put(lay, "chair", pts=[(cx - 24, 136), (cx + 19, 136), (cx + 19, 141), (cx - 24, 141)])
    return lay, parts


HEAD_LORD = """
.....kkkkkk......
...kkhhhhhhkk....
..khhhhhhhhhCk...
.khhhhhhhhhhhCk..
.khhhhhhhhhhhCRk.
khhhhhhhhhhhhhCRk
khhhhhhhhhhhhgGGk
khhhhhhhhhhhhSsRk
khhhhhhhhhhhhssOk
.khhhhhhhhhhhssOk
.khhhhhhhhhhhsOk.
..khhhhhhhhhhsk..
...knnnnnnnnnk...
....knnnnnnnk....
"""
HEAD_LADY = """
.....kkkkkk......
...kkhhhhhhkk....
..khhhhhhhhhCk...
.khhhhhhhhhhhCk..
.khhhhhhhhhhhCRk.
khhhhhhhhhhhhhCRk
khhhhhhhhhhhhgGGk
khhhhhhhhhhhhhSRk
khhhhhhhhhhhhhsOk
khhhhhhhhhhhhhsOk
.khhhhhhhhhhhhRk.
.khhhhhhhhhhhhk..
..khhhhhhhhhhk...
...khhhhhhhhk....
"""


def head_grid(c, form):
    """The bowed head from behind and to the left: the hair, a line of the circlet across the back of it, dark where
    the light is not and gold where it turns toward the fire; a sliver of cheek and ear lit; the nape under the hair
    (the Burgherrin's hair hides it, gathered into the braid)."""
    grid = HEAD_LADY if form == "lady" else HEAD_LORD
    legend = {"k": "night0", "h": "night1", "C": "crimsonDeep", "R": "ember", "g": "crimsonDeep", "G": "gold",
              "S": "tileLight", "s": "tile", "O": "fireOrange", "n": "crimsonDeep"}
    rows = grid.strip("\n").split("\n")
    x0, y0 = LORD_X - 3, 70
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            if ch != ".":
                col = legend[ch]
                if ch == "h" and h2(x, y, 1533) > 0.78 and x > 6:
                    col = "plumDeep"            # a few strands catching the warm dark
                c.c[y0 + y][x0 + x] = P(col)
    # the gold at the circlet's turn, a pixel brighter where the ember strikes it
    c.c[y0 + 6][x0 + 14] = P("fireGold")


def light_lord(lay, parts, form):
    """The ember light on the lord and the chair, as the hall's stones have it: whole parts a step up where they face
    the fire, a hard rim on every edge toward it, the far side in the dark; carved panels on the chair's back; the
    cloak's mend; the circlet's gold where the ember catches it."""
    hx = HEARTH[0]
    src = dict(lay.px)
    for (x, y) in src:
        key = parts[(x, y)]
        near = ember_level(x, y)
        facing = (x + 1, y) not in src or parts.get((x + 1, y)) not in (key, None) and False
        right_open = (x + 1, y) not in src
        right2 = (x + 2, y) not in src
        top_open = (x, y - 1) not in src
        if key == "cloak":
            base = "night1" if x < LORD_X - 6 else "plumDeep" if x < LORD_X + 10 else "crimsonDeep"
            if right_open:
                col = "fireOrange" if near >= 3 else "ember"
            elif right2:
                col = "crimson"
            elif top_open and x > LORD_X - 6:
                col = "crimsonDeep"
            else:
                col = base
        elif key == "hair":
            col = "night0" if x < LORD_X + 6 else "night1"
            if right_open:
                col = "ember"
            elif right2 or (top_open and x > LORD_X + 6):
                col = "crimsonDeep"
            elif h2(x, y, 1531) > 0.8 and x > LORD_X + 1:
                col = "plumDeep"
        elif key == "braid":
            col = "ember" if right_open else "crimsonDeep" if (y % 2 == 0 and x > LORD_X + 3) else "night0"
        elif key == "skin":
            col = "fireOrange" if right_open else "tile" if x > LORD_X + 9 else "crimsonDeep"
        elif key == "sleeve":
            col = "ember" if (right_open or top_open) else "plumDeep" if y < 104 else "crimsonDeep"
        elif key == "hand":
            col = "fireOrange" if right_open else "tile" if x > LORD_X + 39 else "crimson"
        elif key == "post":
            col = "ember" if right_open else "woodDark" if near >= 1 else "night1"
            if top_open:
                col = "wood" if x > LORD_X else "woodDark"
        else:  # the chair's back and arm
            col = "night1"
            if right_open:
                col = "ember"
            elif top_open:
                col = "woodDark"
        lay.px[(x, y)] = P(col)
    # the chair back's carved panels: two sunk frames, their lower and left edges dark, upper lit dim
    for (x0, x1) in ((LORD_X - 20, LORD_X - 4), (LORD_X - 1, LORD_X + 15)):
        for x in range(x0, x1 + 1):
            for y in (104, 130):
                if (x, y) in lay.px:
                    lay.px[(x, y)] = P("night0" if y == 130 else "woodDark")
        for y in range(104, 131):
            for x in (x0, x1):
                if (x, y) in lay.px:
                    lay.px[(x, y)] = P("night0" if x == x0 else "woodDark")
    # the mended cloak: an older cloth let in below the left shoulder, stitched round
    for (x, y) in ((LORD_X - 14, 92), (LORD_X - 12, 93), (LORD_X - 10, 92), (LORD_X - 8, 93), (LORD_X - 15, 95),
                   (LORD_X - 7, 95)):
        if (x, y) in lay.px:
            lay.px[(x, y)] = P("plumDeep")
    # the folds of the cloak over the shoulders and down the back, catching the light on their right
    for (x0, y0, ln) in ((LORD_X - 6, 86, 12), (LORD_X + 6, 85, 13), (LORD_X + 15, 92, 6)):
        for i in range(ln):
            X, Y = x0 + i // 5, y0 + i
            if (X, Y) in lay.px and lay.px[(X, Y)] in (P("night1"), P("plumDeep")):
                lay.px[(X, Y)] = P("night0")
                if (X + 1, Y) in lay.px and lay.px[(X + 1, Y)] in (P("night1"), P("plumDeep")):
                    lay.px[(X + 1, Y)] = P("crimsonDeep")
    # the hanging hand's fingers, the knuckles lit
    for (x, y, col) in ((LORD_X + 39, 122, "crimson"), (LORD_X + 41, 122, "tile"), (LORD_X + 42, 121, "fireOrange"),
                        (LORD_X + 40, 123, "crimsonDeep")):
        lay.put(x, y, P(col))
    lay.outline(P("night0"), skip_bottom=True)


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
    lord, parts = chair_and_lord(form)
    # the lord's long shadow thrown away from the fire across the floor, to the left
    for (x, y) in list(lord.px):
        if y > 140:
            for k in range(1, 34):
                X = x - k
                if 0 <= X < W and (X, y) not in lord.px:
                    c.c[y][X] = P("night0")
    light_lord(lord, parts, form)
    lord.paste(c)
    head_grid(c, form)
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
