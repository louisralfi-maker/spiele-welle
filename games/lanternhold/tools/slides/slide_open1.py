"""The Open Lantern, slide 1 (panels-2, fix round 1; critic 1 of panels-2, high 1): the reveal the chapter builds to,
seen low and from the side, close to the outer line's flags at first light.

The King's black mantle lies flat and collapsed on the stone. From under its edge come Aldric's grey face (on his back,
the nose up, eyes shut, the grey beard over his chest) and one thin hand on the stone. The iron crown, tipped on its
rim, rolls away to the right with a scrape mark behind it; the King's snuffer lies where it dropped. The beacon's warm
light falls in from the right: every edge that faces it lit in palette steps, every shadow long to the left. Behind,
the parapet with its crenels against the dawn, and the floor's own line at its foot, so the floor reads as a floor.

Palette art (paint.finish); the soft glow is the stage's.
"""
import math

from paint import P, W, H, Canvas, fbm, h1, h2, sprite, step
from figure import Layer
from ending_kit import dawn_sky

HOR = 50            # eye level (hidden behind the parapet)
FLOOR = 74          # where the floor meets the parapet: the floor line
FE = 110.0          # perspective: y - HOR = FE / z (the frame's foot is z = 1)
Z_WALL = FE / (FLOOR - HOR)
LIGHT = (3.4, 1.9, 1.7)     # the beacon's fire, out of frame at the right: world x, height, depth

ALLOWED = ["night0", "night1", "nightSlate", "nightHaze", "farDeep", "far", "mistDark", "mist", "plumDeep", "plum",
           "plumLight", "dusk", "dawnRose", "tileLight", "tile", "gold", "fireGold", "fireWhite", "fireOrange",
           "ember", "rockDeep", "rockDark", "rock",
           "rockLight", "rockPale", "stoneDark", "stoneMid", "stone", "stoneLight", "stonePale", "foam", "ink",
           "crimsonDeep"]

FLAG = ["night1", "stoneDark", "rockDeep", "rockDark", "rock", "rockLight", "rockPale"]
WALL = ["night1", "stoneDark", "rockDeep", "rockDark", "rock", "rockLight", "rockPale"]


def depth(y):
    return FE / max(0.5, y + 0.5 - HOR)


def world_x(x, z):
    return (x + 0.5 - 160) * z / FE


def light_level(X, Y, Z, near=1.0):
    """The beacon's light at a point, in steps 0 (cool dawn shadow) to 6, falling off with distance."""
    d = math.sqrt((X - LIGHT[0]) ** 2 + (Y - LIGHT[1]) ** 2 + (Z - LIGHT[2]) ** 2) * near
    v = 6.7 - 2.6 * math.log(max(0.5, d))
    return max(0, min(6, int(v)))


# --- the sky and the parapet -----------------------------------------------------------------------------------------

MERLON_TOP = 34
CRENEL = 46
BEACON = (284, 15)      # the Great Beacon's fire, on its tower beyond the parapet


def merlon_spans():
    spans = []
    x = -9
    k = 0
    while x < W:
        w = 23 + int(h1(k, 2101) * 5)
        spans.append((x, x + w))
        x += w + 12 + int(h1(k, 2103) * 3)
        k += 1
    return spans


def sky(c):
    dawn_sky(c, (330, CRENEL + 4), [(7, "dawnRose"), (15, "dusk"), (23, "plumLight"), (31, "plum"), (40, "farDeep"),
                                    (9999, "nightSlate")], 0, FLOOR, dip=4, dip_width=90, wobble=2.0, seed=2105)
    for k in range(14):
        x = int(h1(k, 2107) * 318)
        y = int(h1(k, 2108) * 14)
        if c.c[y][x] in (P("nightSlate"), P("farDeep")):
            c.c[y][x] = P("mist") if h1(k, 2109) > 0.6 else P("mistDark")


def beacon(c):
    """The Great Beacon on its tower just beyond the parapet at the right, burning: the light of the whole picture.
    A tapering tower dark against the dawn with its top lit from the bowl, the iron bowl, the fire in tongues (white at
    the heart, gold, orange, an ember edge), sparks going up; the sky round it a step warmer in rings."""
    from ending_kit import halo_rings
    halo_rings(c, BEACON[0], BEACON[1] - 4, [(13, 1)], mask=lambda x, y: y < CRENEL, squash=1.3)
    cx, top = BEACON[0], BEACON[1] + 9
    lay = Layer()
    lay.poly([(cx - 10, CRENEL + 4), (cx + 10, CRENEL + 4), (cx + 7, top + 6), (cx - 7, top + 6)], P("night1"))
    lay.poly([(cx - 10, top + 6), (cx + 10, top + 6), (cx + 10, top + 2), (cx - 10, top + 2)], P("night1"))
    for k in range(-10, 11, 4):
        lay.poly([(cx + k, top + 2), (cx + k + 2, top + 2), (cx + k + 2, top), (cx + k, top)], P("night1"))
    # its upper courses lit by the fire above, its left edge by the dawn
    for (x, y), col in list(lay.px.items()):
        if y <= top + 3:
            lay.px[(x, y)] = P("tile") if (x, y - 1) not in lay.px else P("fireOrange")
        elif y < top + 12 and (y - top) % 4 == 0:
            lay.px[(x, y)] = P("crimsonDeep")
        elif (x - 1, y) not in lay.px:
            lay.px[(x, y)] = P("plumDeep")
    lay.paste(c)
    # the bowl, and the fire in it
    for x in range(cx - 9, cx + 10):
        for y in range(top - 4, top):
            if abs(x - cx) <= 9 - (top - 1 - y):
                c.c[y][x] = P("night0")
    flames = [(-7, 4), (-5, 7), (-3, 11), (-1, 14), (1, 12), (3, 15), (5, 9), (7, 5)]
    for (dx, hgt) in flames:
        for k in range(hgt):
            y = top - 4 - k
            half = max(0, int((1 - k / float(hgt)) * 2.2))
            for x in range(cx + dx - half, cx + dx + half + 1):
                if 0 <= y < H:
                    t = k / float(hgt)
                    core = abs(x - cx) < 4 and t < 0.5
                    c.c[y][x] = P("fireWhite" if core else "fireGold" if t < 0.65 else "fireOrange" if t < 0.88
                                  else "ember")
    for (dx, dy) in ((-4, -21), (2, -24), (6, -19), (-8, -16), (9, -14), (0, -28)):
        if 0 <= top + dy < H:
            c.c[top + dy][cx + dx] = P("fireGold" if dy > -22 else "fireOrange")


def parapet(c):
    """The outer line's parapet at the far side of the flags: big blocks in courses, each one flat colour by the
    beacon's light (cool at the left, warm at the right), its top and its end toward the light a step up, its joints a
    step down; merlons with a lit coping, the dawn through the crenels."""
    spans = merlon_spans()

    def solid(x, y):
        if y >= CRENEL:
            return True
        return any(a <= x < b for a, b in spans) and y >= MERLON_TOP

    # courses from the floor line up
    y1 = FLOOR
    row = 0
    while y1 > MERLON_TOP:
        hgt = 8 + int(h1(row, 2111) * 3)
        y0 = max(MERLON_TOP, y1 - hgt)
        x = -int(h1(row, 2113) * 24)
        j = 0
        while x < W:
            bw = 15 + int(h1(j + row * 29, 2115) * 17)
            cx, cy = x + bw / 2.0, (y0 + y1) / 2.0
            X = world_x(cx, Z_WALL)
            Y = (FLOOR - cy) * Z_WALL / FE
            lv = light_level(X, Y, Z_WALL, near=0.92)
            lv += -1 if h2(j, row, 2117) > 0.78 else 0
            for yy in range(y0, y1):
                for xx in range(max(0, x), min(W, x + bw)):
                    if not solid(xx, yy):
                        continue
                    v = lv
                    if yy == y0 and lv >= 2:
                        v += 1                       # the block's top toward the light
                    if xx >= x + bw - 2 and lv >= 2:
                        v += 1                       # its end toward the light
                    if yy == y1 - 1 or xx == x:
                        v = max(0, lv - 2) if lv > 1 else 0   # the joint
                    c.c[yy][xx] = P(WALL[max(0, min(6, v))])
            x += bw
            j += 1
        y1 = y0
        row += 1
    # copings on the merlons and on the crenels' sills: a lit top, a dark shadow line under its lip
    for (a, b) in spans:
        for x in range(max(0, a), min(W, b)):
            lv = light_level(world_x(x, Z_WALL), (FLOOR - MERLON_TOP) * Z_WALL / FE, Z_WALL, near=0.92)
            c.c[MERLON_TOP][x] = P(WALL[min(6, lv + 2)] if lv >= 1 else "stoneMid")
            c.c[MERLON_TOP + 2][x] = P(WALL[max(0, lv - 2)])
        # the merlon's flank toward the light: lit; the other in shade
        for y in range(MERLON_TOP + 1, CRENEL):
            if 0 <= b - 1 < W:
                c.c[y][b - 1] = P("night1")
            if 0 <= a < W:
                lv = light_level(world_x(a, Z_WALL), 0.5, Z_WALL, near=0.92)
                c.c[y][a] = P(WALL[min(6, lv + 1)])
    for x in range(W):
        if not any(a <= x < b for a, b in spans):
            lv = light_level(world_x(x, Z_WALL), (FLOOR - CRENEL) * Z_WALL / FE, Z_WALL, near=0.92)
            c.c[CRENEL][x] = P(WALL[min(6, lv + 2)] if lv >= 1 else "stoneMid")
            c.c[CRENEL + 1][x] = P(WALL[max(0, lv - 1)])
    # an arrow slit in two of the merlons, black
    for (a, b) in spans[2:3] + spans[5:6]:
        mx = (a + b) // 2
        for y in range(MERLON_TOP + 5, CRENEL - 3):
            c.c[y][mx] = P("night0")
        c.c[MERLON_TOP + 4][mx] = P("night1")
    # the floor line: the wall's foot in its own shadow, a dark seam where stone meets stone
    for x in range(W):
        c.c[FLOOR - 1][x] = P("night1")
        c.c[FLOOR - 2][x] = step(c.c[FLOOR - 2][x], -1)


def fog_left(c):
    """The Gloom's last fog drawing off along the foot of the parapet at the left: a low bank, cool, its top ragged."""
    for x in range(0, 120):
        t = x / 120.0
        top = FLOOR - 9 * (1 - t) ** 0.8 - 2.5 * fbm(x * 0.09, 0.3, 2121, 2) + 1.5 * math.sin(x * 0.21)
        for y in range(int(math.ceil(top)), FLOOR + 3 + int(4 * (1 - t))):
            if 0 <= y < H:
                d = y - top
                c.c[y][x] = P("mist" if d < 1.0 else "mistDark" if d < 4 or t < 0.35 else "far")


# --- the floor -------------------------------------------------------------------------------------------------------

def floor(c):
    """The flags from the frame's foot to the parapet, in perspective: courses thinning toward the floor line, joints
    running toward the vanishing point, each flag one flat colour by the beacon's light, its edge toward the light a
    step up where the light is strong."""
    z_rows = []
    z = 1.0
    k = 0
    while z < Z_WALL:
        z_rows.append(z)
        z += 0.27 + h1(k, 2131) * 0.08
        k += 1
    z_rows.append(Z_WALL)
    for y in range(FLOOR, H):
        zy = depth(y)
        # which course
        r = 0
        while r + 1 < len(z_rows) and z_rows[r + 1] < zy:
            r += 1
        r_near, r_far = z_rows[r], z_rows[min(len(z_rows) - 1, r + 1)]
        y_far = HOR + FE / r_far
        y_near = HOR + FE / r_near
        X0 = world_x(0, zy)
        for x in range(W):
            X = world_x(x, zy)
            # flags along the course: uneven widths, offset per course
            u = X + h1(r, 2133) * 3.0 + 10.0
            j = 0
            left = 0.0
            while True:
                fw = 0.45 + h1(j + r * 41, 2135) * 0.35
                if left + fw > u:
                    break
                left += fw
                j += 1
            fw = 0.45 + h1(j + r * 41, 2135) * 0.35
            q = u - left
            cx_w = (left + fw / 2) - h1(r, 2133) * 3.0 - 10.0
            cz = (r_near + r_far) / 2
            lv = light_level(cx_w, 0.0, cz)
            if h2(j, r, 2137) > 0.8:
                lv -= 1
            joint_x = q * FE / zy < 1.0
            joint_y = y >= y_near - 1 if y_near - y_far > 3 else False
            v = lv
            if joint_x or joint_y:
                v = max(0, lv - 2) if lv > 1 else 0
            elif lv >= 3 and (fw - q) * FE / zy < 1.4:
                v = lv + 1      # the flag's edge toward the light
            elif lv >= 3 and y <= y_far + 0.5 and y_near - y_far > 4:
                v = lv + 1      # its far edge catching the light
            c.c[y][x] = P(FLAG[max(0, min(6, v))])
    # the floor line again, a row darker at the wall's foot
    for x in range(W):
        c.c[FLOOR][x] = step(c.c[FLOOR][x], -1)
    # a few worn hollows and cracks, placed
    for (x0, y0, ln, dx) in ((40, 150, 9, 1), (112, 104, 5, 1), (238, 110, 6, -1), (290, 154, 8, -1),
                             (198, 99, 4, 1)):
        for i in range(ln):
            X, Y = x0 + i * dx, y0 + (i // 3)
            if 0 <= X < W and 0 <= Y < H:
                c.c[Y][X] = step(c.c[Y][X], -2)


def shadow(c, pts, base, k, lift, darken=2, avoid=None):
    """A long shadow to the left: every pixel `h` above its foot `base(x)` lands `h * k` to the left and `h * lift`
    toward the wall; the floor there goes `darken` steps down."""
    hit = set()
    for (x, y) in pts:
        b = base(x)
        h = max(0.0, b - y)
        for s in range(0, int(h * k) + 1):
            X = int(round(x - s))
            Y = int(round(b - s / max(0.01, k) * lift))
            hit.add((X, Y))
    for (X, Y) in hit:
        if 0 <= X < W and FLOOR <= Y < H and (avoid is None or (X, Y) not in avoid):
            c.c[Y][X] = step(c.c[Y][X], -darken)


# --- Aldric, the mantle ----------------------------------------------------------------------------------------------

HEAD = (22, 156)        # Aldric's head on the stone: its left end and the floor under it
HEM0, HEM1 = 56, 262    # the mantle's near hem, left and right


def hem_y(x):
    return 155.0 + 1.2 * math.sin(x * 0.09 + 0.4) + 0.7 * math.sin(x * 0.23)


def mantle_height(x):
    """The cloth's height over the floor along its length, a smooth curve through Aldric's shape under it: the
    shoulder at the left edge, the chest, the belly, the hips, the knees, the shins, the feet, then flat cloth."""
    t = (x - HEM0) / float(HEM1 - HEM0)
    keys = [(0.0, 13), (0.05, 27), (0.16, 41), (0.30, 44), (0.44, 36), (0.55, 37), (0.70, 30), (0.82, 22),
            (0.90, 27), (0.95, 19), (1.0, 5)]
    v = keys[-1][1]
    for (t0, v0), (t1, v1) in zip(keys, keys[1:]):
        if t0 <= t <= t1:
            k = (t - t0) / (t1 - t0)
            k = k * k * (3 - 2 * k)
            v = v0 + (v1 - v0) * k
            break
    v += (fbm(x * 0.07, 0.4, 2141, 2) - 0.5) * 1.6
    return max(0.0, v)


def mantle():
    """The King's black mantle, empty of him and collapsed over Aldric: a low heap whose near side hangs down to the
    hem in long soft folds; each rise and each fold ridge lit on its right by the beacon in a step of plum, the top
    edge rimmed warm where it turns toward the light; the hem ragged on the stone, flat tails spreading at both
    ends."""
    lay = Layer()
    tops = {}
    for x in range(HEM0 - 10, HEM1 + 18):
        hy = hem_y(x)
        if HEM0 <= x <= HEM1:
            hgt = mantle_height(x)
        else:
            d = (HEM0 - x) if x < HEM0 else (x - HEM1)
            hgt = 3.0 - d * 0.17
            if hgt < 0.8:
                continue
        top = hy - hgt
        tops[x] = top
        for y in range(int(math.ceil(top)), int(hy) + 1):
            lay.put(x, y, P("night0"))
    # the broad lit faces: where the top rises toward the right (it faces the beacon), the cloth below it a step up,
    # down to where the fold turns under
    for x, top in tops.items():
        slope = tops.get(x + 3, top) - tops.get(x - 3, top)      # negative: rising to the right? (y grows down)
        faces = slope < -0.9
        if not faces:
            continue
        hy = hem_y(x)
        reach = (hy - top) * (0.62 if slope < -2.2 else 0.4)
        for y in range(int(math.ceil(top)) + 1, int(top + reach)):
            if (x, y) in lay.px:
                lay.px[(x, y)] = P("night1")
    # folds: long ridges hanging from the rises down to the hem, gently curving; the ridge's right face lit (plum
    # near the top, plumDeep lower), its left a dark groove
    # (x at the top, lean toward the hem, where it starts: 0 at the top edge, 1 at the hem)
    folds = [(71, 4, 0.1), (84, -3, 0.0), (101, 6, 0.05), (109, 2, 0.5), (124, -4, 0.0), (134, 5, 0.45),
             (147, 3, 0.1), (166, -5, 0.0), (174, 2, 0.6), (188, 6, 0.05), (206, -3, 0.0), (214, 3, 0.55),
             (228, 5, 0.1), (243, -3, 0.0), (253, 2, 0.3)]
    for i, (fx, lean, begin) in enumerate(folds):
        top = tops.get(fx)
        if top is None:
            continue
        bottom = hem_y(fx)
        start = top + 3 + h1(i, 2147) * 3 + (bottom - top) * begin
        for y in range(int(start), int(bottom)):
            t = (y - start) / max(1.0, bottom - start)
            x = int(round(fx + lean * t * t))
            if (x, y) not in lay.px:
                continue
            lay.px[(x, y)] = P("night0")
            if (x + 1, y) in lay.px:
                lay.px[(x + 1, y)] = P("plum") if t < 0.3 else P("plumDeep")
            if (x + 2, y) in lay.px and t < 0.6:
                lay.px[(x + 2, y)] = P("plumDeep")
    # the top edge: rimmed by the warm light where it turns toward the right, dim where it turns away
    for x, top in tops.items():
        y = int(math.ceil(top))
        if (x, y) not in lay.px:
            continue
        slope = tops.get(x + 2, top) - tops.get(x - 2, top)
        if slope < -0.5:
            lay.px[(x, y)] = P("dawnRose") if slope < -1.6 and x > 100 else P("dusk")
            if (x, y + 1) in lay.px:
                lay.px[(x, y + 1)] = P("plum")
        elif slope < 0.7:
            lay.px[(x, y)] = P("plumLight") if x > 100 else P("plum")
            if (x, y + 1) in lay.px:
                lay.px[(x, y + 1)] = P("plumDeep")
        else:
            lay.px[(x, y)] = P("plumDeep")
    # the hem on the stone: ragged, a dark lip; smoky tatters here and there
    for x in range(HEM0 - 10, HEM1 + 18):
        hy = int(hem_y(x))
        if (x, hy) in lay.px:
            if h1(x, 2145) > 0.72:
                lay.put(x, hy + 1, P("night0"))
            if h1(x, 2149) > 0.93:
                lay.put(x, hy + 1, P("night0"))
                lay.put(x + 1, hy + 2, P("night0"))
    return lay, tops


FACE = """
...........kkkkkkkkkk...........
........kkkmmmmmssssskkk........
......kkmmmmmmmssssssssSkk......
.....kmmmmmmmmmsssssssssSSk.....
....kdmmmmmmmmmmsssssssssSSk....
...kddmmmmmmmmmmmsssssssssSk....
...kgddmmmmmmmmmmssssssssssSk...
..khgddmmmmmmmmmmmssssssssshHk..
..khgdddmmmmmmmmmmmsssssssshHk..
..khggdddmmmmmmmmmmmssssssshHk..
.khhgddddmmmmmmmmmmmmssssssshHk.
.khggddccccmmmmmmmmccccsssshHHk.
.khggdcccccdmmmmmdccccccsshhHHk.
.khgddDDDDDDdmmmdDDDDDDdsshhHHk.
.khgddmdDDDDdmmmdDDDDdmssshhHHk.
.khgdddmmmmmdmsmdmmmmmmssshhHHk.
.khgdddddmmmmmsSmmmmmmsssshhHHk.
.kGgdddddmmmmmsSsmmmmssssshhHHk.
.kGgddddddmmmmsSsmmmmsssssshHk..
..kgdDdddddmmmsSsmmmsssssDshHk..
..kgdDDddddmmmsSssmmmssssDDshk..
..kgddDdddmmmdsSsdmmmsssDsshk...
..kgdddddmmmDDsssDDmmsssssshk...
..kgcddddddmmmmmmmmmmssssscck...
..kccddddcccbbbbbbbbbccsssccck..
..kcccdcbbbbbbbbbbbbbbbbccBcck..
..kccccbbbbbDDDDDDDbbbbbbBBcck..
..kccccbbbbbbbbbbbbbbbbbbBBcck..
...kcccbbbbbbbbbbbbbbbbbBBcck...
...kCcccbbbbbbbbbbbbbbbbBBcck...
...kCCcccbbbbbbbbbbbbbbBBcck....
....kCCcccbbbbbbbbbbbbBBcck.....
....kCCCcccbbbbbbbbbbBBcck......
.....kCCCcccbbbbbbbbBBcck.......
......kCCCcccbbbbbbBBck.........
.......kCCCcccbbbbBBck..........
........kCCCcccbbBBck...........
.........kCCcccbBBck............
..........kCCccBck..............
...........kkkkk................
"""


def head():
    """Aldric's head on the stone: on his back, his face turned toward us, eyes shut; grey, thin, the cheeks sunk,
    the long grey beard running over his chest in under the mantle's edge, the grey hair at the sides of a bald crown.
    Drawn upright on a hand-set grid (lit from its right), then turned a quarter so the crown lies to the left, the
    beard to the right and the lit side faces up to the beacon's light."""
    rows = FACE.strip("\n").split("\n")
    legend = {"k": "night0", "H": "stonePale", "h": "stoneLight", "g": "stone", "G": "stoneMid", "S": "dawnRose",
              "s": "rockPale", "m": "rockLight", "d": "rock", "D": "rockDeep", "B": "foam", "b": "stonePale",
              "c": "stoneLight", "C": "stone"}
    w = max(len(r) for r in rows)
    lay = Layer()
    x0, y_floor = HEAD
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            if ch in " .":
                continue
            # a quarter turn: the grid's top goes to the left, its right side up
            lay.put(x0 + y, y_floor - x, P(legend[ch]))
    # the grey hair on the flags behind the head, a few strands fanning out to the left
    for (a, b, c2, d) in ((3, -4, -4, 0), (2, -8, -5, -3), (3, -14, -3, -10), (4, -18, -1, -16), (5, -2, 0, 0)):
        n = max(abs(c2 - a), abs(d - b))
        for i in range(n + 1):
            t = i / float(n)
            X = int(round(x0 + a + (c2 - a) * t))
            Y = int(round(y_floor + b + (d - b) * t))
            if (X, Y) not in lay.px:
                lay.put(X, Y, P("stone") if t < 0.5 else P("stoneMid"))
    return lay


HAND = (158, 157)       # where the wrist comes out from under the hem


def hand():
    """One thin hand out from under the mantle's hem, lying on the stone, the long fingers reaching toward the crown;
    lit on its back from the right, the knuckles catching the light, the tendons showing."""
    lay = Layer()
    grid = """
......kkkkkkk.................
....kkpppppPPkkkkkkkkkkk......
..kktpppppppPPpppppppppPkk....
kktttpppppppptttttttttttttk...
kttttppppppppkkkkkkkkkkkkkkk..
kdtttpppppppPPpppppppppppPPkk.
kddtttppppppptttttttttttttttk.
kddddtttttttkkkkkkkkkkkkkkkk..
.kkddddddddtpppppppppppPkk....
...kkkkkkkkktttttttttttk......
...........kkkkkkkkkkkk.......
"""
    legend = {"k": P("night0"), "t": P("rockLight"), "p": P("rockPale"), "P": P("dawnRose"), "d": P("rock")}
    lay.grid(grid, HAND[0], HAND[1] - 8, legend)
    return lay


# --- the crown, the scrape, the snuffer ------------------------------------------------------------------------------

CROWN = (288, 124)      # where the crown's rim touches the floor


CROWN_GRID = """
.............kk.............
............kRLk............
............kLsk............
.kk.........kLsk.........kk.
kRLk.......kLssmk.......kLsk
kLsk.......kLssmk.......kLmk
kLsk..kk...kLssmk...kk..kLmk
kLsk.kRLk..kLssmk..kLsk.kLmk
kLsk.kLsk..kLssmk..kLmk.kLmk
kLsk.kLsk..kLssmk..kLmk.kLmk
kLsmkkLsk.kkLssmkk.kLmkkksmk
kLsmknLsmknkLssmdknkLmdknsmk
kLsmnnLsmnnkLssmdnnLsmdnnsmk
kLsmnnLsmnnLsssmdnnLsmdnnsdk
kRLLLLLLLLLsssssssssmmmmmmdk
kLssssssssssssssssmmmmmmmmdk
kLssrsssssLssssssmmmmmmrmmdk
kLssssssssssssssssmmmmmmmmdk
.kLsssssssssssssmmmmmmmmmdk.
..kmsssssssssssmmmmmmmmddk..
...kmmmsssssssmmmmmmmdddk...
....kkkmmmmmmmmmmmmdddkk....
.......kkkkkkkkkkkkkk.......
"""


def crown():
    """The iron crown of the old country, tipping over on its rim as it rolls away: drawn upright on a hand-set grid
    (the band, its dark inside between the tines, five tall tines with knobbed tips), mirrored so the light falls from
    the right, then leaned over to the right row by row (a pixel shear, so every edge stays a clean step); old iron,
    a little rust, the beacon on its edges and tips."""
    rows = CROWN_GRID.strip("\n").split("\n")
    legend = {"k": "night0", "R": "dawnRose", "L": "stoneLight", "s": "stone", "m": "stoneMid", "d": "stoneDark",
              "n": "night1", "r": "tile"}
    h = len(rows)
    w = max(len(r) for r in rows)
    lay = Layer()
    x0 = CROWN[0] - w // 2
    y0 = CROWN[1] - (h - 1)
    for y, row in enumerate(rows):
        lean = int((h - 1 - y) * 0.42)
        for x, ch in enumerate(row):
            if ch != ".":
                lay.put(x0 + (w - 1 - x) + lean, y0 + y, P(legend[ch]))
    return lay


def scrape(c):
    """The mark the crown's rim cut as it rolled: a thin pale line from the mantle's end across the flags."""
    x0, y0 = 262, 150
    x1, y1 = CROWN[0] - 3, CROWN[1] + 1
    for i in range(60):
        t = i / 59.0
        x = int(round(x0 + t * (x1 - x0)))
        y = int(round(y0 + t * (y1 - y0) - math.sin(t * math.pi) * 2.0))
        if h1(i, 2171) > 0.12 and FLOOR < y < H:
            c.c[y][x] = P("rockPale") if i > 6 else P("rockLight")
            if i % 4 == 0 and y + 1 < H:
                c.c[y + 1][x] = step(c.c[y + 1][x], -1)


def snuffer():
    """The King's snuffer where it dropped: a long iron pole across the flags behind the mantle, its bell lying on its
    side with its dark mouth toward us."""
    lay = Layer()
    x0, y0, x1, y1 = 122, 99, 238, 92
    n = x1 - x0
    for i in range(n + 1):
        x = x0 + i
        y = y0 + (y1 - y0) * i / float(n)
        lay.put(x, int(y), P("stone") if i < n * 0.4 else P("stoneLight"))
        lay.put(x, int(y) + 1, P("stoneDark"))
    bx, by = 110, 99
    lay.poly([(bx, by - 5), (bx + 13, by - 1), (bx + 13, by + 2), (bx, by + 5)], P("stoneMid"))
    for x in range(bx + 1, bx + 13):
        t = (x - bx) / 13.0
        lay.put(x, int(by - 5 + 4 * t), P("stone"))
    lay.ellipse(bx + 0.5, by, 2.2, 5.6, P("night0"))
    lay.ellipse(bx + 1.0, by, 1.0, 4.2, P("night1"))
    lay.outline(P("night0"), skip_bottom=False)
    return lay


def slide1():
    c = Canvas(P("rock"))
    sky(c)
    beacon(c)
    parapet(c)
    floor(c)
    m, tops = mantle()
    hd = head()
    hn = hand()
    cr = crown()
    sn = snuffer()
    # shadows first, long to the left and a little toward the wall
    shadow(c, list(sn.px), lambda x: 101, 0.6, 0.15, darken=1, avoid=set(sn.px))
    sn.paste(c)
    shadow(c, list(m.px), lambda x: hem_y(x), 1.3, 0.22, avoid=set(m.px))
    shadow(c, list(cr.px), lambda x: CROWN[1], 1.4, 0.07, avoid=set(cr.px))
    shadow(c, list(hd.px), lambda x: HEAD[1] + 1, 0.9, 0.15, darken=1, avoid=set(hd.px))
    scrape(c)
    for lay in (hd, m, hn, cr):
        lay.paste(c)
    return c.finish(ALLOWED, protect=("fireWhite", "fireGold", "fireOrange", "ember", "gold", "dawnRose", "foam",
                                      "dusk"))


SLIDES = {"slideOpen1": slide1}
