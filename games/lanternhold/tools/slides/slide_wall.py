"""Slide 1 of the prologue (panels lane; the director's note of 14:35, critic look 1 high 1): "A wall of mountains
parts the world. It has one door." A picture-book map from high above the inner lands, at night: the Worldwall across
the world, broken and uneven; the one cleft, a real gap, with our castle in it and its lantern the brightest light; the
cold dark of the Gloom beyond (west), its eyes in the smoke; the inner lands in front, moonlit fields and warm lights.
One light: the moon, out of the frame to the upper left. Palette art (paint.finish).
"""
import math

from paint import P, W, H, Canvas, fbm, h1, h2, vnoise, step, BAYER4

HOR = 15
A = float(H - HOR)
XC = 108.0                 # the cleft, in world x (near pixels; the screen's x at depth 1)
GAP = 62.0                 # half the cleft's floor
ZW = 2.05                  # the wall's crest line in depth
LIGHT = (-0.66, 0.62, -0.42)   # the moon: upper left, a little toward us

ALLOWED = ["night0", "nightDeep", "nightBlue", "nightSlate", "nightHaze", "farDeep", "far", "moon", "mistDark",
           "mist", "mistLight", "farPale", "foam", "fir0", "fir1", "fir2", "leafDeep", "leafDark",
           "moorDark", "waterDeep", "roofDeep", "roofLight", "tile", "tileLight", "woodDark", "wood",
           "stoneDark", "stoneMid", "stone", "stoneLight", "stonePale", "fireWhite", "fireGold", "fireOrange",
           "ember", "wraithWhite", "wraithGlow", "wraithDim", "ink", "rockDeep", "rockDark", "night1", "night2",
           "banner", "gold"]

# The great masses of the wall: (x, height, width) in world units; between them saddles, never a row of teeth.
MASSIFS = [(-180, 0.50, 70), (-90, 0.62, 55), (-20, 0.46, 40), (40, 0.70, 46), (78, 0.58, 30), (150, 0.74, 38),
           (196, 0.52, 34), (250, 0.66, 52), (318, 0.44, 40), (372, 0.60, 60), (450, 0.50, 55), (520, 0.64, 70)]


def zwall(X):
    return ZW + 0.08 * math.sin(X * 0.005 + 0.4) - 0.00012 * (X - 160)


def ridged(x, y, seed):
    return 1.0 - abs(2.0 * vnoise(x, y, seed) - 1.0)


def crest(X):
    m = 0.16
    for mx, mh, mw in MASSIFS:
        m = max(m, mh * math.exp(-((X - mx) / mw) ** 2))
    return m


def height(X, Z):
    zw = zwall(X)
    u = (Z - zw) / (0.42 if Z > zw else 0.42 + 0.22 * fbm(X * 0.02, 2.2, 513, 2))
    base = 0.0
    if abs(u) < 1.0:
        env = (1.0 - u * u) ** 1.5
        spur = ridged(X * 0.034 + 3.0 * u, u * 1.1 + fbm(X * 0.012, 0.5, 507, 2) * 1.4, 505)
        spur2 = ridged(X * 0.09, u * 2.6 + 0.7, 509)
        base = env * crest(X) * (0.58 + 0.32 * spur + 0.12 * spur2)
    # the cleft: one cut through the whole wall, sheer-sided
    d = abs(X - XC)
    if d < GAP + 80 and abs(u) < 1.2:
        cut = 0.018 + 0.03 * max(0.0, d - GAP) ** 1.1
        base = min(base, cut)
    return max(0.0, base)


def smoke(X, Z):
    """The Gloom's smoke over the near side: rolling banks, higher toward us, lapping at the wall's foot."""
    b = fbm(X * 0.0065 / Z ** 0.4, Z * 4.2, 551, 3)
    roll = max(0.0, b - 0.32) * 1.7
    return 0.012 + 0.07 * roll * (0.45 + 0.55 * min(1.0, (ZW - Z) * 1.3))


def project(X, Z, h):
    return 160.0 + (X - 160.0) / Z, HOR + A * (1.0 - h) / Z


def unproject_x(xs, Z):
    return 160.0 + (xs - 160.0) * Z


def slide1():
    c = Canvas(P("night0"))
    zbuf = [[99.0] * W for _ in range(H)]
    kind = [[0] * W for _ in range(H)]          # 0 sky, 1 smoke, 2 wall, 3 inner lands

    for y in range(0, HOR + 30):
        for x in range(W):
            c.c[y][x] = P("night0") if y < 6 else P("nightDeep")
    for i in range(22):
        x = int(h1(i, 531) * 318) + 1
        y = int(h1(i, 532) * (HOR - 3)) + 1
        c.c[y][x] = P("farPale") if h1(i, 533) > 0.3 else P("foam")

    for xs in range(W):
        ybuf = H
        Z = 1.0
        while Z < 16.0 and ybuf > HOR:
            X = unproject_x(xs + 0.5, Z)
            zw = zwall(X)
            if Z < zw:
                hw, hs = height(X, Z), smoke(X, Z)
                hgt, k = (hw, 2) if hw > hs else (hs, 1)
            else:
                hgt, k = height(X, Z), (2 if Z < zw + 0.45 else 3)
                if k == 2 and hgt < 0.03 and Z > zw:
                    k = 3
            _, yt = project(X, Z, hgt)
            yi = int(math.ceil(yt))
            if yi < ybuf:
                f = (lambda xx, zz: max(height(xx, zz), smoke(xx, zz))) if k == 1 else height
                e = 0.6
                dx = (f(X + e * Z, Z) - f(X - e * Z, Z)) / (2 * e * Z / A)
                dz = (f(X, Z + 0.004 * Z) - f(X, Z - 0.004 * Z)) / (0.008 * Z)
                n = (-dx, 1.0, -dz)
                ln = math.sqrt(n[0] ** 2 + n[1] ** 2 + n[2] ** 2)
                shade = (n[0] * LIGHT[0] + n[1] * LIGHT[1] + n[2] * LIGHT[2]) / ln
                slope = 1.0 - 1.0 / ln
                col = land_colour(X, Z, hgt, shade, slope, k)
                for y in range(max(HOR, yi), ybuf):
                    c.c[y][xs] = col
                    zbuf[y][xs] = Z
                    kind[y][xs] = k
                ybuf = yi
            Z += 0.004 * Z

    slivers(c, kind)
    lands(c, zbuf, kind)
    castle(c, zbuf, kind)
    gloom_eyes(c, kind, zbuf)
    creatures(c)
    return c.finish(ALLOWED, protect=("fireWhite", "fireGold", "fireOrange", "ember", "wraithWhite", "wraithGlow",
                                      "farPale", "foam"))


def slivers(c, kind):
    """The height field leaves rows a single pixel high in the smoke and the far lands: each folds into the colour
    above and below it, so every bank is a cluster with a body."""
    for _ in range(2):
        for y in range(HOR + 1, H - 1):
            for x in range(W):
                if kind[y][x] in (1, 3):
                    up, down = c.c[y - 1][x], c.c[y + 1][x]
                    if up == down and up != c.c[y][x] and kind[y - 1][x] == kind[y][x] == kind[y + 1][x]:
                        c.c[y][x] = up


def land_colour(X, Z, h, shade, slope, k):
    if k == 1:
        # the smoke: dark banks, their moonward crests a step lighter
        lv = 0 if shade < 0.52 else 1 if shade < 0.68 else 2 if shade < 0.80 else 3
        if Z < 1.25 and lv:
            lv -= 1
        return P(["nightDeep", "nightBlue", "nightSlate", "nightHaze"][lv])
    if k == 3:
        # the inner lands far off under the moon: woods, fields and meadows in the blue of distance
        sx = (X - 160.0) / Z
        n = fbm(sx * 0.045, Z * 0.35, 561, 3)
        z = Z * (0.75 + 0.5 * n) + (fbm(sx * 0.11, Z, 563, 2) - 0.5) * 1.2
        if z < 3.4:
            return P("fir0") if n < 0.5 else P("leafDeep")
        if z < 6.0:
            return P("nightBlue")
        if z < 9.5:
            return P("nightSlate")
        return P("nightHaze")
    snowline = 0.30 + 0.09 * fbm(X * 0.02, Z * 2.0, 541, 2)
    if h > snowline and slope < 0.80:
        lv = 0 if shade < 0.0 else 1 if shade < 0.28 else 2 if shade < 0.5 else 3 if shade < 0.7 else 4
        return P(["nightHaze", "far", "moon", "mist", "mistLight"][lv])
    lv = 0 if shade < 0.05 else 1 if shade < 0.32 else 2 if shade < 0.56 else 3
    if h < 0.10 and Z > zwall(X):
        return P(["fir0", "fir0", "fir1", "fir2"][lv])
    return P(["nightDeep", "nightBlue", "nightSlate", "farDeep"][lv])


def lands(c, zbuf, kind):
    """The inner lands' lights beyond the wall: towns and farms awake, a river catching the moon, the road out of the
    cleft."""
    for i in range(140):
        X = -500 + h1(i, 581) * 1400
        Z = zwall(X) + 0.6 + h1(i, 582) ** 1.4 * 11.0
        xs, ys = project(X, Z, 0.0)
        x, y = int(xs), int(ys)
        if not (0 <= x < W and HOR <= y < H) or kind[y][x] != 3 or zbuf[y][x] < Z - 0.3:
            continue
        town = h1(i, 583) > 0.82
        c.c[y][x] = P("fireGold") if h1(i, 584) > 0.4 else P("fireOrange")
        if town:
            for k in range(1 + int(h1(i, 585) * 4)):
                xx, yy = x + int((h1(i * 5 + k, 586) - 0.5) * 6), y + int((h1(i * 5 + k, 587) - 0.5) * 2)
                if 0 <= xx < W and HOR <= yy < H and kind[yy][xx] == 3:
                    c.c[yy][xx] = P("fireGold") if k % 2 else P("fireOrange")
    # the river, a thread of moonlight winding off toward the right
    Z = zwall(XC) + 0.5
    X = XC + 10
    while Z < 15:
        xs, ys = project(X, Z, 0.0)
        x, y = int(xs), int(ys)
        if 0 <= x < W and HOR <= y < H and kind[y][x] == 3 and zbuf[y][x] >= Z - 0.2:
            c.c[y][x] = P("moon") if (int(Z * 40) % 5) else P("mist")
        X += 30.0 * Z * (0.6 + 0.5 * math.sin(Z * 2.2))
        Z += 0.05 * Z
    # the road of lanterns out of the cleft into the lands
    Z = zwall(XC) + 0.15
    X = XC
    i = 0
    while Z < 6:
        xs, ys = project(X, Z, 0.0)
        x, y = int(xs), int(ys)
        if 0 <= x < W and HOR <= y < H and kind[y][x] == 3:
            c.c[y][x] = P("fireGold") if i % 3 == 0 else P("nightHaze")
        X += 9.0 * Z
        Z += 0.035 * Z
        i += 1


def gloom_eyes(c, kind, zbuf):
    """The cold eyes in the smoke, one to each of them: many and small far off, few and large in front, gathered
    toward the cleft's light."""
    for i in range(18):
        x = int(h1(i, 601) * 316) + 2
        y = int(HOR + 80 + h1(i, 602) ** 0.8 * 64)
        if not (0 <= y < H - 1) or kind[y][x] != 1:
            continue
        if kind[y - 1][x] != 1 or kind[y + 1][x] != 1 or c.c[y][x] not in (P("nightDeep"), P("nightBlue")):
            continue
        near = y > 122
        c.c[y][x] = P("wraithWhite")
        c.c[y][x - 1] = P("night0")
        c.c[y][x + 1] = P("night0")
        if near:
            c.c[y][x + 1] = P("wraithWhite")
            c.c[y][x - 1] = P("wraithDim")
            c.c[y][x + 2] = P("wraithDim")


def put_land(c, zbuf, x, y, Z, col):
    if 0 <= x < W and 0 <= y < H and zbuf[y][x] >= Z - 0.02:
        c.c[y][x] = col
        zbuf[y][x] = Z


def lamp(c, zbuf, x, y, Z, small=False):
    put_land(c, zbuf, x, y, Z, P("fireGold"))
    if not small:
        put_land(c, zbuf, x, y - 1, Z, P("fireWhite"))
    for dx, dy in ((-1, 1), (1, 1), (0, 1)):
        X, Y = x + dx, y + dy
        if 0 <= X < W and 0 <= Y < H and zbuf[Y][X] >= Z - 0.02:
            c.c[Y][X] = step(c.c[Y][X], 1)


def house(c, zbuf, x, y, Z, lit=True, big=False):
    """A cottage seen from above: a roof of two pitches, a lit window under the eave."""
    if big:
        art = [".rrR.", "rrrRR", "wwYww"] if lit else [".rrR.", "rrrRR", "wwwww"]
    else:
        art = [".rR", "rrR", "wY."] if lit else [".rR", "rrR", "ww."]
    legend = {"r": P("roofDeep"), "R": P("roofLight"), "w": P("stoneMid"), "Y": P("fireGold")}
    for j, line in enumerate(art):
        for i, ch in enumerate(line):
            if ch != ".":
                put_land(c, zbuf, x + i, y - len(art) + 1 + j, Z, legend[ch])


def town(c, zbuf, X0, Z0):
    """Tallowford on its rise at the near right: roofs crowding a chapel, lanes of light between them."""
    for i in range(30):
        X = X0 + (h1(i, 591) - 0.5) * 110
        Z = Z0 + (h1(i, 592) - 0.5) * 0.18
        xs, ys = project(X, Z, 0.012)
        x, y = int(xs), int(ys)
        w = 5 + int(h1(i, 593) * 4)
        tile = h1(i, 594) > 0.5
        roof, roof_lt = (P("tile"), P("tileLight")) if tile else (P("roofDeep"), P("roofLight"))
        for j in range(4):
            for k in range(w):
                col = roof_lt if k >= w // 2 else roof
                if j == 3:
                    col = P("stoneMid")
                put_land(c, zbuf, x + k, y - 3 + j, Z, col)
        put_land(c, zbuf, x + 1, y, Z, P("fireGold") if h1(i, 595) > 0.3 else P("fireOrange"))
        if w > 6 and h1(i, 596) > 0.4:
            put_land(c, zbuf, x + w - 2, y, Z, P("fireGold"))
    # the chapel's tower
    xs, ys = project(X0 + 6, Z0, 0.012)
    x, y = int(xs), int(ys)
    for j in range(12):
        for k in range(4):
            put_land(c, zbuf, x + k, y - j, Z0 - 0.3, P("stone") if k < 2 else P("stoneMid"))
    for k in range(5):
        put_land(c, zbuf, x - 1 + k, y - 12, Z0 - 0.3, P("roofLight") if k < 2 else P("roofDeep"))
    put_land(c, zbuf, x + 1, y - 13, Z0 - 0.3, P("roofDeep"))
    put_land(c, zbuf, x + 1, y - 7, Z0 - 0.3, P("fireGold"))
    put_land(c, zbuf, x + 2, y - 7, Z0 - 0.3, P("fireGold"))


GLOOM_FOLK = """
..dd..
.dddd.
.dEdd.
..dd..
.dddd.
dddddd
dddddd
d.dddd
..ddd.
..dd.d
..d..d
.dd..d
"""

GLOOM_SMALL = """
.dd.
dEdd
.dd.
dddd
dddd
.dd.
.d.d
.d.d
dd.d
"""


def castle(c, zbuf, kind):
    """Lanternhold in the cleft, its west face toward us and the dark: the curtain wall from cliff to cliff, the
    gatehouse in the middle with its gate shut, two towers against the rock, the keep behind with the house's lantern
    on top, the brightest light in the world. Moonlit from the left; its own light warm on the cleft and on the ground
    before the gate, where the smoke draws back from it."""
    Zc = zwall(XC) - 0.30
    cx, base = project(XC, Zc, 0.016)
    cx, base = int(round(cx)), int(round(base))
    lt, st, md, dk = P("stoneLight"), P("stone"), P("stoneMid"), P("stoneDark")
    pix = {}

    def box(x0, x1, y0, y1, round_=False):
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                t = (x - x0) / max(1, x1 - x0)
                if round_:
                    col = lt if t < 0.25 else st if t < 0.6 else md if t < 0.85 else dk
                else:
                    col = lt if x == x0 else dk if x == x1 else st
                pix[(x, y)] = col

    def crenels(x0, x1, y):
        for x in range(x0, x1 + 1):
            if (x - x0) % 3 != 2:
                pix[(x, y)] = pix.get((x, y + 1), st)

    def cone(x0, x1, y_eave, rise):
        for k in range(rise):
            a0 = x0 + k * (x1 - x0) / (2.0 * rise)
            a1 = x1 - k * (x1 - x0) / (2.0 * rise)
            for x in range(int(round(a0)), int(round(a1)) + 1):
                t = (x - a0) / max(1.0, a1 - a0)
                pix[(x, y_eave - k)] = P("roofLight") if t < 0.4 else P("roofDeep")

    # behind: the keep (right of the gate) and the hall's long roof (left)
    box(cx + 4, cx + 14, base - 40, base - 10, round_=False)
    crenels(cx + 4, cx + 14, base - 41)
    box(cx - 19, cx - 5, base - 19, base - 10)
    for k in range(6):
        for x in range(cx - 19 + k, cx - 4 - k):
            pix[(x, base - 20 - k)] = P("roofLight") if x < cx - 12 else P("roofDeep")
    # the curtain wall, cliff to cliff, with its walk and slits
    box(cx - 25, cx + 25, base - 12, base)
    crenels(cx - 25, cx + 25, base - 13)
    for x in range(cx - 25, cx + 26):
        pix[(x, base - 12)] = lt if x < cx else st
    for x in (cx - 18, cx - 12, cx + 11, cx + 17):
        pix[(x, base - 8)] = P("night0")
        pix[(x, base - 7)] = P("night0")
    # the towers against the rock, round, with cone roofs
    box(cx - 29, cx - 21, base - 24, base, round_=True)
    crenels(cx - 29, cx - 21, base - 25)
    cone(cx - 30, cx - 20, base - 26, 7)
    box(cx + 21, cx + 29, base - 22, base, round_=True)
    cone(cx + 20, cx + 30, base - 23, 7)
    # the gatehouse with two turrets and the gate, shut, its fire showing between the bars
    box(cx - 7, cx + 7, base - 21, base)
    crenels(cx - 7, cx + 7, base - 22)
    for tx in (cx - 8, cx + 6):
        box(tx, tx + 2, base - 26, base - 18, round_=True)
        cone(tx - 1, tx + 3, base - 27, 3)
    for y in range(base - 8, base + 1):
        for x in range(cx - 3, cx + 4):
            arch = y > base - 7 or abs(x - cx) < 2
            if arch:
                pix[(x, y)] = P("ember") if (x - cx) % 2 == 0 else P("night0")
    for x in range(cx - 3, cx + 4):
        pix[(x, base - 4)] = P("night0")
    # the house's banner over the gate
    for y in range(base - 19, base - 12):
        for x in range(cx - 2, cx + 3):
            pix[(x, y)] = P("banner") if y < base - 13 or x == cx else P("roofDeep")
    pix[(cx, base - 17)] = P("gold")
    pix[(cx, base - 16)] = P("gold")
    # windows awake
    for (x, y, n) in ((cx + 7, base - 35, "fireGold"), (cx + 11, base - 35, "fireGold"), (cx + 7, base - 28, "fireOrange"),
                      (cx + 11, base - 22, "fireGold"), (cx - 26, base - 18, "fireGold"), (cx + 24, base - 16, "fireOrange"),
                      (cx - 16, base - 15, "fireGold"), (cx - 10, base - 15, "fireGold"), (cx - 25, base - 9, "fireOrange"),
                      (cx + 25, base - 8, "fireGold"), (cx - 4, base - 16, "fireGold"), (cx + 3, base - 16, "fireGold")):
        pix[(x, y)] = P(n)
        pix[(x, y + 1)] = P("fireOrange") if n == "fireGold" else P("ember")
    # torches on the wall walk
    for x in (cx - 21, cx - 10, cx + 10, cx + 19):
        pix[(x, base - 14)] = P("fireGold")
    # the house's lantern on the keep, on its mast
    for y in range(base - 46, base - 41):
        pix[(cx + 9, y)] = P("woodDark")
    for (dx, dy, n) in ((0, -50, "fireWhite"), (0, -49, "fireWhite"), (-1, -49, "fireWhite"), (1, -49, "fireWhite"),
                        (-1, -50, "fireGold"), (1, -50, "fireGold"), (0, -51, "fireWhite"), (0, -52, "fireGold"),
                        (-2, -49, "fireGold"), (2, -49, "fireGold"), (-1, -48, "fireGold"), (1, -48, "fireGold"),
                        (0, -48, "fireGold"), (0, -47, "gold"), (-1, -51, "fireOrange"), (1, -51, "fireOrange"),
                        (-2, -50, "fireOrange"), (2, -50, "fireOrange"), (-2, -48, "fireOrange"),
                        (2, -48, "fireOrange"), (0, -53, "fireOrange")):
        pix[(cx + 9 + dx, base + dy)] = P(n)

    # its light on the ground before the gate: the smoke draws back from it in a ring with a hard edge
    for y in range(base - 2, min(H, base + 22)):
        for x in range(cx - 60, cx + 61):
            if not (0 <= x < W) or kind[y][x] == 2 and zbuf[y][x] < Zc - 0.05:
                continue
            d = math.hypot((x - cx) / 34.0, (y - base + 1) / 9.0) + (fbm(x * 0.25, y * 0.4, 611, 2) - 0.5) * 0.5
            if d < 0.42:
                c.c[y][x] = P("woodDark")
            elif d < 0.78:
                c.c[y][x] = P("rockDeep")
    # and on the cleft's sheer sides right beside the castle: a narrow warm edge where its windows reach the rock
    rows = {}
    for (x, y) in pix:
        lo, hi = rows.get(y, (x, x))
        rows[y] = (min(lo, x), max(hi, x))
    for y, (lo, hi) in rows.items():
        for side, x0 in ((-1, lo - 2), (1, hi + 2)):
            for k in range(3):
                x = x0 + side * k
                if 0 <= x < W and 0 <= y < H and kind[y][x] == 2 and y > base - 26:
                    c.c[y][x] = warm(c.c[y][x], 1)
    # the castle itself, outlined where it meets the dark
    ink = P("ink")
    for (x, y) in pix:
        for ddx, ddy in ((1, 0), (-1, 0), (0, -1)):
            k = (x + ddx, y + ddy)
            if k not in pix and 0 <= k[0] < W and 0 <= k[1] < H:
                c.c[k[1]][k[0]] = ink
    for (x, y), col in pix.items():
        if 0 <= x < W and 0 <= y < H:
            c.c[y][x] = col
    # the Gloom's folk at the edge of the light, dark against it, one cold eye each
    for (dx, dy, art, flip) in ((-40, 15, GLOOM_FOLK, False), (-27, 19, GLOOM_SMALL, False),
                                (31, 17, GLOOM_FOLK, True), (44, 12, GLOOM_SMALL, True), (-55, 9, GLOOM_SMALL, False)):
        lines = art.strip("\n").split("\n")
        w = len(lines[0])
        for j, line in enumerate(lines):
            for i, ch in enumerate(line):
                if ch == ".":
                    continue
                x = cx + dx + (w - 1 - i if flip else i)
                y = base + dy - len(lines) + j
                if 0 <= x < W and 0 <= y < H:
                    c.c[y][x] = P("wraithWhite") if ch == "E" else P("nightDeep")


WARM = {}


def warm(col, k):
    """A cold night colour seen by firelight: k steps toward the castle's warmth (rock to warm stone, snow to rose)."""
    table = {
        P("nightDeep"): ["rockDeep", "rockDark"], P("nightBlue"): ["rockDeep", "rockDark"],
        P("nightSlate"): ["rockDark", "tile"], P("farDeep"): ["rockDark", "tile"], P("nightHaze"): ["rockDark", "tile"],
        P("far"): ["stone", "tileLight"], P("moon"): ["stoneLight", "tileLight"], P("mist"): ["stoneLight", "tileLight"],
        P("mistLight"): ["stonePale", "tileLight"], P("fir0"): ["rockDeep", "woodDark"], P("fir1"): ["woodDark", "wood"],
        P("fir2"): ["wood", "tile"], P("leafDark"): ["woodDark", "wood"], P("moor"): ["wood", "tileLight"],
    }
    row = table.get(col)
    if not row:
        return col
    return P(row[min(1, k - 1)])


def creature(c, name, frames, frame, x0, base, flip=False, sink=0):
    """One of the game's own creatures as a shape in the dark (SPRITES.md): its body a step from black, the moon's rim
    on its upper left, its eye from its glow strip; the smoke covers its lower `sink` rows."""
    from paint import sprite
    rows = sprite(name, frame, frames)
    glow = sprite(name + "Glow", frame, frames)
    h = len(rows)
    w = len(rows[0])
    y0 = base - h
    body = {}
    for y in range(h - sink):
        for x in range(w):
            sx = w - 1 - x if flip else x
            if rows[y][sx][3] >= 128:
                body[(x0 + x, y0 + y)] = P("night0")
    for (x, y) in list(body):
        if (x - 1, y) not in body or (x, y - 1) not in body:
            body[(x, y)] = P("far")
    for y in range(h - sink):
        for x in range(w):
            sx = w - 1 - x if flip else x
            g = glow[y][sx]
            if g[3] >= 128 and (g[0], g[1], g[2]) in (P("wraithWhite"), P("wraithGlow")):
                body[(x0 + x, y0 + y)] = (g[0], g[1], g[2])
    for (x, y), col in body.items():
        if 0 <= x < W and 0 <= y < H:
            c.c[y][x] = col


def creatures(c):
    """The Gloom's own, near us in the smoke and turned toward the light in the cleft."""
    creature(c, "ashBrute", 7, 0, 6, H + 4, sink=10)
    creature(c, "gloomweaver", 4, 1, 262, 128, flip=True)
    creature(c, "sootling", 6, 0, 70, 150, sink=2)
    creature(c, "sootling", 6, 2, 226, 156, flip=True, sink=3)
    creature(c, "shadehound", 6, 0, 286, 160, flip=True, sink=3)
