"""Slide 3 of the prologue (panels lane; critic look 1 high 2): "This autumn the Great Beacon went dark. Lord Aldric
rode out to light it. He did not come back." Lord Aldric rides out across the moor toward the dark Great Beacon, which
stands black against the moon; his lantern raised on its pole is the warm subject; the twelve lantern bearers trail
behind him back along the road toward the Throat, each a small figure with a light. One light direction: the moon
ahead of him (left), and his lantern on the same side. Palette art (paint.finish).
"""
import math

from paint import P, W, H, Canvas, fbm, h1, h2, vnoise, step
from figure import Layer

HOR = 98
MOON = (58, 30)
LANTERN = (138, 72)

ALLOWED = ["night0", "nightDeep", "nightBlue", "nightSlate", "nightHaze", "farDeep", "far", "moon", "mistDark",
           "mist", "mistLight", "farPale", "foam", "fir0", "fir1", "moorDark", "moor", "ink", "rockDeep", "rockDark",
           "woodDark", "wood", "woodLight", "straw", "tile", "tileLight", "dawnRose", "banner", "roofDeep",
           "roofLight", "gold", "fireWhite", "fireGold", "fireOrange", "ember", "stoneDark", "stoneMid", "stone",
           "soilDark", "soil", "night1", "night2"]


def sky(c):
    for y in range(0, HOR + 4):
        for x in range(W):
            d = math.hypot(x + 0.5 - MOON[0], (y + 0.5 - MOON[1]) * 1.1)
            if d < 17:
                col = P("foam")
            elif d < 24:
                col = P("nightHaze")
            elif d < 36:
                col = P("nightSlate")
            elif d < 62:
                col = P("nightBlue")
            else:
                col = P("nightBlue") if y > 70 else P("nightDeep")
            c.c[y][x] = col
    # the moon's face: a few seas a step down
    for (x, y, r) in ((52, 26, 4.5), (62, 34, 3.5), (57, 37, 2.2), (64, 24, 2.0)):
        for yy in range(int(y - r), int(y + r) + 1):
            for xx in range(int(x - r), int(x + r) + 1):
                if (xx - x) ** 2 + ((yy - y) * 1.2) ** 2 <= r * r and c.c[yy][xx] == P("foam"):
                    c.c[yy][xx] = P("mistLight")
    # stars away from the moon
    for i in range(24):
        x = int(h1(i, 701) * 318) + 1
        y = int(h1(i, 702) * 60) + 1
        if math.hypot(x - MOON[0], y - MOON[1]) > 50:
            c.c[y][x] = P("farPale") if h1(i, 703) > 0.3 else P("mist")
    # two strands of cloud below the moon, lit on their upper edges
    for (x0, x1, y0, th, seed) in ((10, 150, 50, 3.0, 711), (170, 300, 22, 2.2, 713), (90, 200, 64, 2.0, 715)):
        for x in range(x0, x1):
            t = (x - x0) / float(x1 - x0)
            k = math.sin(t * math.pi) ** 0.7
            thick = th * k * (0.6 + 0.8 * fbm(x * 0.06, y0, seed, 2))
            top = y0 - thick + 1.2 * math.sin(x * 0.09 + seed)
            for y in range(int(math.ceil(top)), int(y0 + thick * 0.6) + 1):
                if 0 <= y < H:
                    near = math.hypot(x - MOON[0], y - MOON[1]) < 46
                    col = (P("mist") if near else P("nightHaze")) if y < top + 1.2 else \
                        (P("nightHaze") if near else P("nightSlate"))
                    c.c[y][x] = col


def beacon(c):
    """The Great Beacon on its hill, black against the moon: a tapering tower, its parapet, the great iron bowl on
    top, cold and empty; the moon's rim along its left edge."""
    lay = Layer()
    cx, base = 58, 104
    # the hill
    lay.poly([(-10, base + 4), (14, base - 6), (40, base - 10), (78, base - 9), (110, base - 2), (130, base + 6)],
             P("night0"))
    # the tower
    lay.poly([(cx - 9, base - 8), (cx + 9, base - 8), (cx + 6, base - 58), (cx - 6, base - 58)], P("night0"))
    lay.poly([(cx - 9, base - 58), (cx + 9, base - 58), (cx + 9, base - 63), (cx - 9, base - 63)], P("night0"))
    for k in range(-9, 10, 3):
        lay.poly([(cx + k, base - 63), (cx + k + 1.5, base - 63), (cx + k + 1.5, base - 65), (cx + k, base - 65)],
                 P("night0"))
    # the bowl on its legs
    lay.poly([(cx - 4, base - 65), (cx + 4, base - 65), (cx + 2, base - 69), (cx - 2, base - 69)], P("night0"))
    lay.poly([(cx - 15, base - 76), (cx + 15, base - 76), (cx + 10, base - 69), (cx - 10, base - 69)], P("night0"))
    lay.poly([(cx - 16, base - 78), (cx + 16, base - 78), (cx + 16, base - 76), (cx - 16, base - 76)], P("night0"))
    # a door at its foot and a slit window, dark against dark: a step lighter so they read
    for y in range(base - 15, base - 8):
        for x in range(cx - 2, cx + 2):
            lay.put(x, y, P("nightDeep"))
    for y in range(base - 40, base - 35):
        lay.put(cx, y, P("nightDeep"))
    # the moon's rim on the left edges
    for (x, y), col in list(lay.px.items()):
        if col == P("night0") and (x - 1, y) not in lay.px and y < base - 5:
            lay.px[(x, y)] = P("far") if math.hypot(x - MOON[0], y - MOON[1]) < 40 else P("nightSlate")
        elif col == P("night0") and (x, y - 1) not in lay.px and math.hypot(x - MOON[0], y - MOON[1]) < 44:
            lay.px[(x, y)] = P("nightSlate")
    lay.paste(c)


def land(c):
    # the far hills of the shadow land under the moon, and the mist lying in the hollows before them
    far = [HOR - 8 - 7 * fbm(x * 0.012, 0.3, 721, 3) for x in range(W)]
    for x in range(W):
        for y in range(int(far[x]), HOR + 6):
            c.c[y][x] = P("nightSlate") if y < far[x] + 1 else P("nightBlue")
    for (y0, seed, top, body) in ((HOR - 2, 731, "nightHaze", "nightSlate"), (HOR + 5, 733, "nightSlate", "nightBlue")):
        for x in range(W):
            t = y0 + 2.5 * fbm(x * 0.03, y0, seed, 2) + 1.5 * math.sin(x * 0.05 + seed)
            for y in range(int(t), y0 + 6):
                c.c[y][x] = P(top) if y < t + 1 else P(body)
    # the moor: dark peat in two bands, its dead grass in tufts placed one by one
    for y in range(HOR + 8, H):
        for x in range(W):
            t = (y - HOR - 8) / float(H - HOR - 8)
            n = fbm(x * 0.02 / (0.3 + t), y * 0.08, 741, 2)
            c.c[y][x] = P("nightBlue") if (t < 0.22 and n > 0.4) else P("nightDeep")
    for i in range(70):
        x = int(h1(i, 745) * 318) + 1
        y = int(HOR + 22 + h1(i, 746) ** 0.6 * (H - HOR - 23))
        t = (y - HOR) / float(H - HOR)
        hgt = 1 + int(t * 4 * h1(i, 747) + t * 2)
        col = P("moorDark") if t > 0.35 else P("nightSlate")
        for k in range(hgt):
            if 0 <= y - k < H:
                c.c[y - k][x] = col
            if k == hgt - 1 and hgt > 2:
                c.c[y - k][x + (1 if h1(i, 748) > 0.5 else -1)] = col


def road_path():
    """The road: from the Throat far back on the right, down across the moor to the front, then away left toward the
    beacon's hill. Returns points (x, y, half width)."""
    pts = []
    for i in range(0, 121):
        t = i / 120.0
        if t < 0.55:
            u = t / 0.55
            x = 330 - 150 * u
            y = (HOR + 7) + (152 - HOR - 7) * u ** 1.6
            w = 1.0 + 12.0 * u ** 1.6
        else:
            u = (t - 0.55) / 0.45
            x = 180 - 120 * u
            y = 152 - (152 - (HOR + 9)) * u ** 0.55
            w = 13.0 - 11.5 * u ** 0.55
        pts.append((x, y, w))
    return pts


def road(c):
    for (x, y, w) in road_path():
        for dx in range(-int(w) - 1, int(w) + 2):
            if abs(dx) > w:
                continue
            xx, yy = int(x + dx), int(y)
            if 0 <= xx < W and 0 <= yy < H:
                rut = w > 5 and abs(abs(dx) - w * 0.45) < 0.7
                c.c[yy][xx] = P("nightBlue") if rut else (P("nightHaze") if w > 3 else P("nightSlate"))
            for k in (1, 2):
                if 0 <= xx < W and 0 <= yy + k < H and w > 4 and c.c[yy + k][xx] != P("nightHaze"):
                    c.c[yy + k][xx] = P("nightBlue") if not (abs(abs(dx) - w * 0.45) < 0.7) else P("nightDeep")


def dead_tree(c, x, base, hgt, seed):
    col = P("night0")
    lay = Layer()
    lay.capsule((x, base), (x + 2, base - hgt * 0.55), 1.6, 1.0, col)
    pts = [(x + 2, base - hgt * 0.55)]
    for k in range(5):
        px, py = pts[min(len(pts) - 1, int(h1(k, seed) * len(pts)))]
        ang = -math.pi / 2 + (h1(k, seed + 1) - 0.5) * 2.0
        ln = hgt * (0.25 + 0.25 * h1(k, seed + 2))
        ex, ey = px + math.cos(ang) * ln, py + math.sin(ang) * ln
        lay.line([(px, py), (ex, ey)], col)
        pts.append((ex, ey))
        for j in range(2):
            a2 = ang + (h1(k * 3 + j, seed + 3) - 0.5) * 1.6
            l2 = ln * 0.45
            lay.line([(ex, ey), (ex + math.cos(a2) * l2, ey + math.sin(a2) * l2)], col)
    lay.paste(c)


# --- Lord Aldric -------------------------------------------------------------------------------------------------

def aldric(c, ox, oy):
    """Lord Aldric on his horse, side on, riding left: a dark bay at a walk, the lord broad in the house's teal cloak
    blown back, his lantern raised on its pole ahead of them. ox, oy: the ground under the front hooves."""
    horse = Layer()
    bay = P("woodDark")
    dark = P("night0")

    def L(x, y):
        return (ox + x, oy + y)

    # far legs first (a step darker)
    for (a, b, d) in (((16, -21), (20, -12), (16, -4)), ((33, -22), (30, -12), (31, -1))):
        horse.capsule(L(*a), L(*b), 2.6, 1.9, dark)
        horse.capsule(L(*b), L(*d), 1.6, 1.4, dark)
    # the body: barrel, chest, haunch, neck, head
    horse.ellipse(ox + 24, oy - 27, 15.5, 9.0, bay)
    horse.ellipse(ox + 11, oy - 27, 7.5, 9.0, bay)
    horse.ellipse(ox + 37, oy - 28, 9.0, 9.0, bay)
    horse.capsule(L(10, -31), L(1, -41), 6.6, 4.0, bay)
    horse.capsule(L(1, -42), L(-9, -35), 3.7, 2.4, bay)
    horse.poly([L(0, -44), L(1, -48), L(3, -44)], bay)
    horse.poly([L(2, -44), L(4, -47), L(5, -43)], bay)
    # near legs
    for (a, b, d) in (((12, -20), (11, -10), (12, -1)), ((38, -22), (40, -12), (37, -1))):
        horse.capsule(L(*a), L(*b), 2.9, 2.1, bay)
        horse.capsule(L(*b), L(*d), 1.8, 1.5, bay)
    for (hx, hy) in ((11, 0), (36, 0), (15, -3), (30, 0)):
        for k in range(3):
            horse.put(ox + hx + k, oy + hy, P("night0"))
    # mane and tail
    horse.capsule(L(2, -44), L(12, -33), 1.8, 2.0, dark)
    horse.capsule(L(45, -32), L(49, -22), 2.6, 2.2, dark)
    horse.capsule(L(49, -22), L(48, -11), 2.2, 1.3, dark)
    # the saddle cloth in the house's teal, the bridle
    horse.poly([L(18, -36), L(31, -36), L(30, -25), L(19, -25)], P("roofDeep"))
    for x in range(19, 31):
        horse.put(ox + x, oy - 25, P("gold") if x % 3 == 0 else P("roofDeep"))
    horse.line([L(-7, -38), L(1, -41), L(15, -40)], P("night0"))
    # the barrel's underside and the haunch's back turn away from the light: a step darker
    for (x, y), col in list(horse.px.items()):
        if col == bay and (y > oy - 22 and ox + 6 < x < ox + 44 or x > ox + 40):
            horse.px[(x, y)] = P("night0") if y > oy - 19 and ox + 18 < x < ox + 32 else step(bay, -1)

    rider = Layer()
    cloak = P("roofDeep")
    # the cloak blown back over the haunch
    rider.poly([L(21, -50), L(27, -50), L(41, -40), L(45, -33), L(37, -32), L(29, -36), L(22, -37)], cloak)
    rider.line([L(27, -48), L(39, -36)], P("nightDeep"))
    rider.line([L(25, -44), L(33, -34)], P("nightDeep"))
    rider.line([L(30, -47), L(44, -34)], P("nightDeep"))
    # the body, broad, and the near leg in its boot
    rider.capsule(L(24, -37), L(23, -48), 4.4, 4.0, P("banner"))
    rider.capsule(L(23, -37), L(17, -31), 2.8, 2.4, P("rockDeep"))
    rider.capsule(L(17, -31), L(18, -23), 2.2, 2.0, P("woodDark"))
    for k in range(3):
        rider.put(ox + 16 + k, oy - 22, P("night0"))
    # the head, the hood thrown back, grey hair and beard: an old lord
    rider.ellipse(ox + 22, oy - 53, 3.0, 3.3, P("tile"))
    rider.ellipse(ox + 23, oy - 55, 3.0, 2.2, P("stone"))
    rider.capsule(L(20, -51), L(21, -49), 1.3, 1.5, P("stoneMid"))
    rider.capsule(L(26, -52), L(27, -48), 2.4, 2.4, cloak)
    # the arm raised forward with the pole
    rider.capsule(L(22, -47), L(15, -51), 2.3, 1.9, P("banner"))
    rider.ellipse(ox + 14, oy - 51, 1.5, 1.5, P("tile"))
    pole_top = L(3, -63)
    rider.line([L(17, -47), pole_top], P("wood"))
    rider.line([L(16, -47), (pole_top[0] - 1, pole_top[1])], P("woodDark"))

    for lay in (horse, rider):
        lay.outline(P("night0"))
    # light: his lantern ahead and above (warm, in two hard rings); the moon's rim on the upper left edges
    lx, ly = pole_top[0], pole_top[1] + 4

    def light(lay, x, y, c0):
        d = math.hypot(x + 0.5 - lx, y + 0.5 - ly)
        if c0 == P("night0"):
            return c0
        k = 2 if d < 13 else 1 if d < 27 else 0
        rim = (x - 1, y) not in lay.px or (x, y - 1) not in lay.px
        if k == 0 and rim:
            return P("nightSlate") if c0 in (P("woodDark"), P("rockDeep")) else step(c0, 1)
        return step(c0, k)
    for lay in (horse, rider):
        src = dict(lay.px)
        for (x, y), c0 in src.items():
            lay.px[(x, y)] = light(lay, x, y, c0)
    # the pool of his lantern on the road under him and ahead
    for y in range(oy - 6, oy + 9):
        for x in range(ox - 40, ox + 50):
            if 0 <= x < W and 0 <= y < H:
                d = math.hypot((x - (ox + 8)) / 30.0, (y - (oy + 1)) / 5.5) + (h2(x // 3, y // 2, 771) - 0.5) * 0.25
                if d < 0.55:
                    c.c[y][x] = warm_ground(c.c[y][x], 2)
                elif d < 1.0:
                    c.c[y][x] = warm_ground(c.c[y][x], 1)
    horse.paste(c)
    rider.paste(c)
    lantern(c, pole_top[0], pole_top[1] + 2, big=True)


def warm_ground(col, k):
    table = {P("nightHaze"): ("wood", "woodLight"), P("nightSlate"): ("woodDark", "wood"),
             P("nightBlue"): ("woodDark", "wood"), P("nightDeep"): ("soilDark", "woodDark"),
             P("night0"): ("night0", "soilDark"), P("moorDark"): ("woodDark", "wood")}
    row = table.get(col)
    return P(row[k - 1]) if row else col


def lantern(c, x, y, big=False):
    """A lantern hanging from its pole's hook: an iron cap, the light, a warm edge of a pixel (the stage's light
    carries the soft glow)."""
    art = [
        "..k..",
        ".kkk.",
        "kGWGk",
        "kWWWk",
        "kGWGk",
        ".kkk.",
    ]
    legend = {"k": P("night0"), "W": P("fireWhite"), "G": P("fireGold")}
    x0, y0 = x - 2, y - 1
    for j, line in enumerate(art):
        for i, ch in enumerate(line):
            if ch == ".":
                continue
            c.c[y0 + j][x0 + i] = legend[ch]
    for (i, j) in ((-1, 2), (-1, 3), (-1, 4), (5, 2), (5, 3), (5, 4), (1, 6), (2, 6), (3, 6), (0, 0), (4, 0)):
        X, Y = x0 + i, y0 + j
        if 0 <= X < W and 0 <= Y < H:
            c.c[Y][X] = P("fireOrange") if j in (3,) or j == 6 else P("ember")


# --- the twelve -----------------------------------------------------------------------------------------------------

def bearer(c, x, base, hgt, seed):
    """One of the twelve lantern bearers, walking left: a hooded figure in a dark cloak, a lantern held out on a short
    pole, its light on the bearer's front and on the road. hgt: the figure's height in pixels."""
    lay = Layer()
    s = hgt / 28.0
    body = P("nightDeep") if h1(seed, 751) > 0.5 else P("night1")
    # the cloak, narrow at the shoulders, wider at the hem, walking
    lay.poly([(x - 3 * s, base - 20 * s), (x + 3.5 * s, base - 20 * s), (x + 6.5 * s, base - 3 * s),
              (x - 5 * s, base - 3 * s)], body)
    # legs in stride
    lay.capsule((x - 1 * s, base - 4 * s), (x - 3.5 * s, base), 1.3 * s + 0.3, 1.0 * s + 0.3, P("night0"))
    lay.capsule((x + 2 * s, base - 4 * s), (x + 3.5 * s, base), 1.3 * s + 0.3, 1.0 * s + 0.3, P("night0"))
    # the hood
    lay.ellipse(x, base - 24 * s, 3.0 * s + 0.4, 3.4 * s + 0.4, body)
    lay.put(x - 2 * s, base - 24 * s, P("tile"))
    # the arm raised and the pole forward, the lantern hanging high
    lay.capsule((x - 1 * s, base - 19 * s), (x - 5 * s, base - 24 * s), 1.4 * s + 0.3, 1.2 * s + 0.3, body)
    tip = (x - 9 * s, base - 31 * s)
    lay.line([(x - 5 * s, base - 24 * s), tip], P("woodDark"))
    lay.outline(P("night0"))
    # the light on its front edge
    for (px, py), col in list(lay.px.items()):
        if col != P("night0") and (px - 1, py) not in lay.px and py < base - 4 * s:
            lay.px[(px, py)] = P("tile") if s > 0.5 else P("woodDark")
    # its pool on the road
    r = max(2.0, 8.0 * s)
    for yy in range(int(base - 2), int(base + 3 * s + 2)):
        for xx in range(int(x - 10 * s - r), int(x + r)):
            if 0 <= xx < W and 0 <= yy < H:
                d = math.hypot((xx - (x - 5 * s)) / r, (yy - base) / max(1.0, 2.5 * s))
                if d < 1.0:
                    c.c[yy][xx] = warm_ground(c.c[yy][xx], 1 if d > 0.5 or s < 0.4 else 2)
    lay.paste(c)
    tx, ty = int(round(tip[0])), int(round(tip[1])) + 1
    if 0 <= tx < W and 0 <= ty < H:
        c.c[ty][tx] = P("fireWhite") if s > 0.45 else P("fireGold")
        if s > 0.45 and ty + 1 < H:
            c.c[ty + 1][tx] = P("fireGold")
            c.c[ty][tx - 1] = P("fireOrange")
            c.c[ty][tx + 1] = P("fireOrange")


def procession(c):
    pts = road_path()
    # behind him along the road toward the Throat, each smaller with the distance
    spots = [0.47, 0.43, 0.39, 0.355, 0.32, 0.29, 0.26, 0.235, 0.21, 0.19, 0.17, 0.15]
    for k in range(11, -1, -1):
        t = spots[k]
        x, y, w = pts[int(t * 120)]
        side = (-0.35 if k % 2 else 0.35) * w
        hgt = 4 + 24 * (w / 13.0) ** 1.05
        bearer(c, x + side, y, hgt, k)


def slide3():
    c = Canvas(P("nightDeep"))
    sky(c)
    land(c)
    beacon(c)
    road(c)
    dead_tree(c, 262, 112, 26, 761)
    dead_tree(c, 300, 118, 34, 763)
    dead_tree(c, 18, 126, 30, 765)
    procession(c)
    aldric(c, 152, 150)
    return c.finish(ALLOWED, protect=("fireWhite", "fireGold", "fireOrange", "ember", "farPale", "mist"))
