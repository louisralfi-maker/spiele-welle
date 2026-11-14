"""The Guttering Lantern, slide 1 (panels-2, fix round 1; critic 1 of panels-2, high 2): Tallowford on a winter night,
half its windows dark. "The door held. Half the windows of Tallowford stayed dark that winter, and not for the dead."

Five houses of the street, each its own (heights, roof pitch, a lean-to, an overhanging upper storey, one shuttered
and broken), their dark windows the subject; two windows still lit. A family pulls a handcart out of the picture. Above
the town, under one sky, the Worldwall with snow on its ledges, and on its shoulder the castle with its own outline and
one weak ember window. The moon at the upper left is the one light of the sky; the lit windows the only warmth.

Palette art (paint.finish).
"""
import math

from paint import P, W, H, Canvas, fbm, h1, h2, step
from figure import Layer
from ending_kit import cluster, halo_rings, person, snow_flakes

STREET = 142
MOON = (46, 20)

ALLOWED = ["night0", "night1", "night2", "nightDeep", "nightBlue", "nightSlate", "nightHaze", "farDeep", "far",
           "mistDark", "mist", "mistLight", "foam", "moon", "woodDark", "wood", "soilDark", "soil", "roofDeep",
           "ember", "emberDim", "fireOrange", "fireGold", "fireWhite", "ink", "crimsonDeep", "moorDark", "moor",
           "plumDeep", "tile", "dawnRose", "plasterDim"]


# --- the sky, the moon, the Worldwall ----------------------------------------------------------------------------------

def sky(c):
    """One sky: deep at the top, a step lighter toward the mountains, the band edges wavering; a few stars."""
    for y in range(0, STREET):
        for x in range(W):
            v = y / 96.0 + (fbm(x * 0.012, y * 0.05, 2201, 3) - 0.5) * 0.22 - 0.12 * math.exp(-((x - MOON[0]) / 60.0) ** 2)
            c.c[y][x] = P("nightDeep" if v < 0.34 else "nightBlue" if v < 0.7 else "nightSlate")
    halo_rings(c, MOON[0], MOON[1], [(9, 1)])
    c.disc(MOON[0], MOON[1], 4.6, P("mistLight"))
    c.disc(MOON[0] + 1.4, MOON[1] - 0.8, 3.6, P("foam"))
    for (dx, dy) in ((-2, 1), (1, 2), (-1, -1)):
        c.c[MOON[1] + dy][MOON[0] + dx] = P("mist")
    for k in range(26):
        x = int(h1(k, 2203) * 318)
        y = int(h1(k, 2204) * 44)
        if c.c[y][x] in (P("nightDeep"), P("nightBlue")) and math.hypot(x - MOON[0], y - MOON[1]) > 22:
            c.c[y][x] = P("mist") if h1(k, 2205) > 0.7 else P("nightHaze")


# The Worldwall's masses: (peak x, its top, slope to the left, slope to the right, flat top's half width)
PEAKS = [(16, 7, 0.75, 0.62, 0), (66, 22, 0.8, 0.85, 0), (137, 48, 1.2, 1.25, 33), (214, 27, 1.7, 0.62, 0),
         (244, 9, 0.9, 0.7, 0), (292, 5, 0.75, 0.9, 0), (336, 18, 0.8, 0.8, 0)]


def mass_top(i, x):
    px, top, sl, sr, flat = PEAKS[i]
    d = abs(x - px) - flat
    if d <= 0:
        return top
    return top + (sl if x < px else sr) * d


def ridge(x):
    """The Worldwall's skyline: high at both sides, a broad shoulder left of the middle where the castle stands, the
    cleft just right of it; every peak its own, a little ragged."""
    return min(mass_top(i, x) for i in range(len(PEAKS))) + (fbm(x * 0.11, 0.3, 2207, 3) - 0.5) * 3.0


def mountains(c):
    """The rock in moonlight from the upper left, as big masses: each peak's face toward the moon lit, the other in
    shade, the line between them running down from the peak; snow over the upper part of each lit face with a ragged
    edge, thinner on the shaded side; a few ravines running down as dark streaks; the foot lost in the valley's
    dark."""
    tops = [ridge(x) for x in range(W)]
    for x in range(W):
        owner = min(range(len(PEAKS)), key=lambda i: mass_top(i, x))
        px, ptop, sl, sr, flat = PEAKS[owner]
        for y in range(int(math.ceil(tops[x])), 112):
            depth = y - ptop
            edge = px + flat * (0 if x < px else 1) * 0 + depth * 0.28 + (fbm(x * 0.06, y * 0.06, 2209, 2) - 0.5) * 10
            lit = x < edge if flat == 0 else (x < px - flat * 0.2 + depth * 0.2)
            low = y - tops[x]
            if lit:
                col = "nightHaze" if low < 30 else "nightSlate" if low < 52 else "night1"
            else:
                col = "nightBlue" if low < 34 else "night1" if low < 56 else "nightDeep"
            snow_line = 16 + 9 * fbm(x * 0.08, 0.7, 2213, 2) - (6 if not lit else 0)
            if flat:
                snow_line = 3 + 3 * fbm(x * 0.15, 0.7, 2213, 2)     # the shoulder: snow only on its ledge
            if depth < snow_line and low < 40:
                col = ("mist" if (low < 2 and x < 120) else "mistDark") if lit else "far"
            if low < 1.0:
                col = "mistDark" if lit else "nightHaze"
            c.c[y][x] = P(col)
    # ravines: dark streaks running down the faces from under the snow
    for i, (px, ptop, sl, sr, flat) in enumerate(PEAKS):
        for k in range(4):
            x0 = px + (h1(k, 2215 + i) - 0.5) * 50
            y0 = ptop + 12 + h1(k, 2217 + i) * 10
            ln = 14 + int(h1(k, 2219 + i) * 26)
            for j in range(ln):
                X = int(round(x0 + j * (0.35 + h1(k, 2221 + i) * 0.3) + math.sin(j * 0.4 + k) * 0.8))
                Y = int(round(y0 + j))
                if 0 <= X < W and 0 <= Y < 110 and Y > tops[X] + 2:
                    c.c[Y][X] = step(c.c[Y][X], -1)
    return tops


def castle(c, tops):
    """The castle on the shoulder of the wall, with its own outline against the sky: the curtain with its crenels, a
    round tower with a cone roof, a square tower, the keep between them; snow on every crenel and roof; one weak ember
    window in the keep."""
    lay = Layer()
    base = 49
    col = P("nightBlue")
    lay.poly([(112, base + 2), (166, base + 2), (166, 38), (112, 38)], col)                 # the curtain
    for x in range(112, 166, 4):
        lay.poly([(x, 38), (x + 2, 38), (x + 2, 35), (x, 35)], col)
    lay.poly([(110, base + 2), (121, base + 2), (121, 27), (110, 27)], col)                 # the square tower
    for x in range(110, 121, 3):
        lay.poly([(x, 27), (x + 1.6, 27), (x + 1.6, 24), (x, 24)], col)
    lay.poly([(132, base), (152, base), (152, 19), (132, 19)], col)                         # the keep
    for x in range(132, 152, 4):
        lay.poly([(x, 19), (x + 2, 19), (x + 2, 16), (x, 16)], col)
    lay.poly([(146, 19), (151, 19), (151, 11), (146, 11)], col)                             # the keep's turret
    lay.poly([(145.5, 11), (151.5, 11), (148.5, 5)], col)
    lay.poly([(158, base + 2), (169, base + 2), (169, 24), (158, 24)], col)                 # the round tower
    lay.poly([(157, 24), (170, 24), (163.5, 11)], col)
    # moonlight on the faces toward the upper left, the far faces dark
    for (x, y), v in list(lay.px.items()):
        if (x - 1, y) not in lay.px or (x, y - 1) not in lay.px:
            lay.px[(x, y)] = P("nightHaze")
        elif x in (121, 152, 169) or (x > 163 and y > 24):
            lay.px[(x, y)] = P("night1")
    # snow on the crenels, the roofs' moonward slopes and the wall walk
    for (x, y) in list(lay.px):
        if (x, y - 1) not in lay.px:
            lay.px[(x, y)] = P("mistDark")
    for y in range(11, 25):
        for x in range(157, 170):
            if (x, y) in lay.px and x < 163.5 - (y - 11) * 0.0 and x <= 163:
                if (x, y) in lay.px and lay.px[(x, y)] != P("mistDark"):
                    lay.px[(x, y)] = P("far") if x < 162 else lay.px[(x, y)]
    # windows: black slits, and one ember window in the keep
    for (x, y) in ((115, 31), (115, 40), (163, 30), (164, 40), (137, 26), (143, 34)):
        lay.put(x, y, P("night0"))
        lay.put(x, y + 1, P("night0"))
    lay.put(140, 27, P("ember"))
    lay.put(141, 27, P("emberDim"))
    lay.put(140, 28, P("emberDim"))
    lay.put(141, 28, P("crimsonDeep"))
    lay.outline(P("night0"), skip_bottom=True)
    lay.paste(c)
    # the shoulder under it: the rock's ledge, snow lying on it
    for x in range(104, 176):
        y = int(base + 2 + 1.5 * math.sin(x * 0.2))
        for yy in range(y, y + 3):
            if c.c[yy][x] not in (P("night0"),):
                c.c[yy][x] = P("far") if yy == y else P("nightBlue")


def far_roofs(c):
    """The rest of Tallowford down the valley behind the street: a band of roofs, snow on their edges, one small warm
    window."""
    for x in range(W):
        k = int(x / 9)
        hgt = 6 + int(h1(k, 2211) * 6)
        peak = (x % 9) < 5
        top = 106 - hgt + (abs((x % 9) - 4) if peak else 2) * 0.8
        for y in range(int(top), STREET):
            c.c[y][x] = P("mistDark" if y < top + 1 else "nightSlate" if y < top + 3 else "night1")
    for (x, y) in ((58, 108), (214, 106)):
        c.c[y][x] = P("fireOrange")
        c.c[y][x + 1] = P("ember")


# --- the five houses ---------------------------------------------------------------------------------------------------

def window(c, x, y, w, h, lit=False, shutter=None, broken=False, sill=True):
    """A window: its frame, the glass dark (or warm and lit), snow on its sill; `shutter` 'shut' or 'hang' (one
    leaf torn half off); `broken`: a pane knocked out, a pale shard left."""
    for yy in range(y - 1, y + h + 1):
        for xx in range(x - 1, x + w + 1):
            c.c[yy][xx] = P("woodDark")
    for yy in range(y, y + h):
        for xx in range(x, x + w):
            if lit:
                c.c[yy][xx] = P("fireGold") if (yy - y) < h - 2 and (xx - x) % (w // 2 + 1) != w // 2 else \
                    P("fireOrange")
            else:
                c.c[yy][xx] = P("night0")
    mx, my = x + w // 2, y + h // 2
    for yy in range(y, y + h):
        c.c[yy][mx] = P("woodDark") if not lit else P("ember")
    for xx in range(x, x + w):
        c.c[my][xx] = P("woodDark") if not lit else P("ember")
    if not lit and not shutter:
        c.c[y][x + w - 1] = P("nightSlate")          # the moon's glint on the glass
    if broken:
        for (dx, dy) in ((0, 0), (1, 0), (0, 1), (1, 1), (2, 1)):
            c.c[y + dy][x + dx] = P("night0")
        c.c[y + 1][x] = P("mist")
        c.c[y][x + 1] = P("nightHaze")
    if shutter:
        for yy in range(y - 1, y + h + 1):
            for xx in range(x - 1, x + w + 1):
                if shutter == "hang" and xx >= mx:
                    continue
                c.c[yy][xx] = P("soilDark") if (xx - x) % 3 else P("night1")
        if shutter == "hang":
            # the right leaf hangs from one hinge, skewed down and out
            for k in range(h + 2):
                for j in range(w // 2 + 1):
                    X, Y = mx + 1 + j + k // 4, y - 1 + k + j // 2
                    if 0 <= X < W and 0 <= Y < H:
                        c.c[Y][X] = P("soilDark") if j % 3 else P("night1")
    if sill:
        for xx in range(x - 2, x + w + 2):
            c.c[y + h + 1][xx] = P("mist")
        c.c[y + h + 2][x - 1] = P("mistDark")


def snow_roof(c, pts, apex_x, depth=3, lit_left=True):
    """Snow on a roof outline: along its top edge, `depth` rows, the slope toward the moon (left) lighter; a soft
    lower edge and a few icicles."""
    xs = [p[0] for p in pts]
    for x in range(int(min(xs)), int(max(xs)) + 1):
        if not 0 <= x < W:
            continue
        # the roof's top at this column, from the polygon itself
        ys = []
        n = len(pts)
        for i in range(n):
            (x0, y0), (x1, y1) = pts[i], pts[(i + 1) % n]
            if (x0 <= x + 0.5 <= x1) or (x1 <= x + 0.5 <= x0):
                if x1 != x0:
                    ys.append(y0 + (x + 0.5 - x0) * (y1 - y0) / (x1 - x0))
        if not ys:
            continue
        top = int(math.ceil(min(ys)))
        d = depth + (1 if h1(x, 2221) > 0.6 else 0)
        for k in range(d):
            if 0 <= top + k < H:
                left = x < apex_x
                c.c[top + k][x] = P(("mistLight" if left else "mist") if k < d - 1 else "mistDark")


def roof_gable(c, x0, x1, eave, apex, material, overhang=2):
    """A gable end toward us: the roof's triangle with its verge boards, the gable wall's plaster or boards inside."""
    cx = (x0 + x1) / 2.0
    pts = [(x0 - overhang, eave), (x1 + overhang, eave), (cx, apex)]
    c.poly(pts, P("night1"))
    inner = [(x0 + 2, eave), (x1 - 2, eave), (cx, apex + 3)]
    c.poly(inner, P(material))
    snow_roof(c, pts, cx, depth=3)
    return pts


def timber(c, x0, x1, y0, y1, seed):
    """Timber framing over a plaster wall: posts, a rail, a few braces."""
    for x in (x0, x1 - 1) + tuple(range(x0 + 9 + int(h1(seed, 2223) * 4), x1 - 6, 13)):
        for y in range(y0, y1):
            c.c[y][x] = P("night1")
    ym = (y0 + y1) // 2
    for x in range(x0, x1):
        c.c[ym][x] = P("night1")
        c.c[y0][x] = P("night1")
    for k, xs in enumerate(range(x0 + 2, x1 - 8, 26)):
        for i in range(min(8, ym - y0)):
            X, Y = xs + i, ym - 1 - i
            if x0 < X < x1 and y0 < Y < y1:
                c.c[Y][X] = P("night1")


def house1(c):
    """The tall house: two floors, timber framing over plaster, a steep gable toward us, the chimney cold; every
    window dark."""
    x0, x1 = 4, 58
    wall_top = 98
    for y in range(wall_top, STREET):
        for x in range(x0, x1):
            c.c[y][x] = P("farDeep") if x > x0 + 1 else P("far")
    timber(c, x0, x1, wall_top, STREET, 1)
    for x in range(x0 + 20, x0 + 30):
        c.c[wall_top + 1][x] = P("night1")
    roof_gable(c, x0, x1, wall_top, 64, "farDeep")
    # the chimney on the right slope, cold, a cap of snow
    for y in range(68, 84):
        for x in range(46, 52):
            c.c[y][x] = P("nightSlate") if x < 49 else P("night1")
    for x in range(45, 53):
        c.c[67][x] = P("mistLight")
    for (x, y, w, h) in ((10, 104, 8, 9), (42, 104, 8, 9), (26, 76, 6, 8), (10, 122, 8, 9)):
        window(c, x, y, w, h)
    # the door, shut, snow banked against it
    for y in range(120, STREET):
        for x in range(36, 46):
            c.c[y][x] = P("woodDark") if (x - 36) % 3 else P("night1")
    for x in range(34, 48):
        c.c[STREET - 1][x] = P("mist")


def house2(c):
    """The low stone cottage with its long roof to the street, a lean-to on its right with a woodpile; someone still
    lives here: one window lit, the chimney smoking."""
    x0, x1 = 64, 106
    wall_top = 118
    for y in range(wall_top, STREET):
        row = (y - wall_top) // 5
        for x in range(x0, x1):
            joint = (y - wall_top) % 5 == 4 or (x + row * 4) % 9 == 0
            c.c[y][x] = P("night1" if joint else "nightSlate" if h2(x // 9, row, 2225) > 0.3 else "nightHaze")
    # the long roof seen from the front: a slope rising back to its ridge, thatch under the snow
    roof = [(x0 - 3, wall_top), (x1 + 3, wall_top), (x1 - 1, 99), (x0 + 1, 99)]
    c.poly(roof, P("soil"))
    for y in range(99, wall_top):
        for x in range(x0 - 3, x1 + 4):
            if c.c[y][x] == P("soil"):
                k = (y - 99) / float(wall_top - 99) + (fbm(x * 0.25, y * 0.3, 2229, 2) - 0.5) * 0.35
                c.c[y][x] = P("mistLight" if k < 0.18 else "mist" if k < 0.55 else "mistDark" if k < 0.8 else "soil")
    for x in range(x0 - 3, x1 + 4):
        c.c[wall_top][x] = P("soilDark")
        if h1(x, 2227) > 0.7:
            c.c[wall_top + 1][x] = P("mistLight")      # an icicle
    # the chimney, smoking
    for y in range(92, 103):
        for x in range(92, 97):
            c.c[y][x] = P("nightHaze") if x < 94 else P("night1")
    for x in range(91, 98):
        c.c[91][x] = P("mistLight")
    for k in range(18):
        x = 94 + int(round(math.sin(k * 0.5) * 1.6 + k * 0.45))
        y = 89 - k
        c.c[y][x] = P("mistDark") if k < 10 else P("nightHaze")
        if k < 8:
            c.c[y][x + 1] = P("nightHaze")
    window(c, 72, 124, 8, 8, lit=True)
    window(c, 94, 124, 6, 8)
    for y in range(128, STREET):
        for x in range(83, 90):
            c.c[y][x] = P("woodDark") if (x - 83) % 3 else P("night1")
    # the lean-to: boards under a single slope, the woodpile under it
    for y in range(124, STREET):
        for x in range(106, 121):
            c.c[y][x] = P("soilDark") if (x - 106) % 4 else P("night1")
    for x in range(105, 123):
        y = int(121 + (x - 105) * 0.35)
        for k in range(3):
            c.c[y + k][x] = P("mistLight" if k == 0 else "mist" if k == 1 else "night1")
    for (lx, ly) in ((108, 136), (112, 136), (116, 136), (110, 133), (114, 133)):
        cluster(c, lx, ly, [".kk.", "kwWk", ".kk."], {"k": "night1", "w": "woodDark", "W": "wood"})
    # the warm window's light on the snow below it
    for y in range(STREET, STREET + 3):
        for x in range(69, 85):
            if abs(x - 76.5) < 7.5 - (y - STREET) * 2.5:
                c.c[y][x] = P("plasterDim") if (y == STREET and abs(x - 76.5) < 4) else P("mistDark")


def house3(c):
    """The narrow tall house nobody lives in now: the shutters nailed shut, one torn half off and hanging, the door
    boarded across, slates gone from the roof so the rafters show, snow drifted against the door."""
    x0, x1 = 128, 162
    wall_top = 100
    for y in range(wall_top, STREET):
        for x in range(x0, x1):
            c.c[y][x] = P("farDeep") if (x + y) % 23 else P("nightSlate")
    for x in (x0, x1 - 1):
        for y in range(wall_top, STREET):
            c.c[y][x] = P("night1")
    pts = roof_gable(c, x0, x1, wall_top, 72, "nightSlate", overhang=3)
    # the hole in the roof: slates gone, rafters dark against the dark loft
    for y in range(83, 92):
        for x in range(150, 158):
            if (x - 150) + (91 - y) * 0.6 < 9 and c.c[y][x] != P("night1"):
                c.c[y][x] = P("night0") if (x - 150) % 3 else P("woodDark")
    # the ridge sags in the middle: a step down
    c.c[73][145] = P("nightBlue")
    window(c, 134, 106, 7, 9, shutter="shut")
    window(c, 149, 106, 7, 9, shutter="hang")
    window(c, 134, 124, 7, 8, shutter="shut")
    for y in range(120, STREET):
        for x in range(148, 158):
            c.c[y][x] = P("woodDark") if (x - 148) % 3 else P("night1")
    # two planks nailed across the door
    for i in range(12):
        for (yy, dx) in ((124 + i // 2, i), (134 - i // 2, i)):
            X = 147 + dx
            if 147 <= X <= 158:
                c.c[yy][X] = P("soil")
                c.c[yy + 1][X] = P("soilDark")
    # the drift against the door
    for x in range(140, 164):
        hgt = int(6 * math.exp(-((x - 152) / 7.0) ** 2))
        for y in range(STREET - hgt, STREET):
            c.c[y][x] = P("mist") if y > STREET - hgt else P("mistLight")


def house4(c):
    """The house with an overhanging upper storey: stone below, plaster and timber above on its jetty, a half-hipped
    roof; three dark windows above, two below, one pane knocked out."""
    x0, x1 = 170, 228
    for y in range(120, STREET):
        row = (y - 120) // 5
        for x in range(x0 + 2, x1 - 2):
            joint = (y - 120) % 5 == 4 or (x + row * 5) % 11 == 0
            c.c[y][x] = P("night1" if joint else "nightSlate")
    # the jetty's shadow line, the upper storey wider
    for x in range(x0 - 1, x1 + 1):
        c.c[120][x] = P("night0")
        c.c[121][x] = P("night1")
    for y in range(96, 120):
        for x in range(x0 - 1, x1 + 1):
            c.c[y][x] = P("far") if x < x0 + 2 else P("farDeep")
    timber(c, x0 - 1, x1 + 1, 96, 120, 4)
    # the half-hipped roof: a gable clipped at its top
    cx = (x0 + x1) / 2.0
    pts = [(x0 - 4, 96), (x1 + 4, 96), (cx + 10, 80), (cx - 10, 80)]
    c.poly(pts, P("roofDeep"))
    c.poly([(cx - 12, 96), (cx + 12, 96), (cx + 7, 84), (cx - 7, 84)], P("farDeep"))
    snow_roof(c, pts, cx, depth=4)
    for (x, y, w, h, br) in ((176, 102, 7, 9, False), (195, 102, 7, 9, True), (214, 102, 7, 9, False),
                             (178, 126, 7, 8, False), (212, 126, 7, 8, False)):
        window(c, x, y, w, h, broken=br)
    for y in range(126, STREET):
        for x in range(194, 204):
            c.c[y][x] = P("woodDark") if (x - 194) % 3 else P("night1")


def house5(c):
    """The small boarded house at the end of the street: a low gable, a crooked chimney with a thread of smoke, one
    window still lit."""
    x0, x1 = 234, 276
    wall_top = 114
    for y in range(wall_top, STREET):
        for x in range(x0, x1):
            c.c[y][x] = P("soilDark") if (y - wall_top) % 4 else P("night1")
    for x in (x0, x1 - 1):
        for y in range(wall_top, STREET):
            c.c[y][x] = P("night1")
    roof_gable(c, x0, x1, wall_top, 94, "soilDark", overhang=3)
    for y in range(96, 106):
        x = 268 + (106 - y) // 4
        for k in range(4):
            c.c[y][x + k] = P("nightHaze") if k < 2 else P("night1")
    for k in range(4):
        c.c[95][269 + k] = P("mistLight")
    for k in range(14):
        x = 271 + int(round(math.sin(k * 0.6) * 1.3 + k * 0.3))
        c.c[93 - k][x] = P("mistDark") if k < 8 else P("nightHaze")
    window(c, 241, 122, 8, 8, lit=True)
    for y in range(126, STREET):
        for x in range(259, 267):
            c.c[y][x] = P("woodDark") if (x - 259) % 3 else P("night1")
    for y in range(STREET, STREET + 3):
        for x in range(237, 255):
            if abs(x - 245.5) < 7.5 - (y - STREET) * 2.5:
                c.c[y][x] = P("plasterDim") if (y == STREET and abs(x - 245.5) < 4) else P("mistDark")


def street(c):
    for y in range(STREET, H):
        for x in range(W):
            if c.c[y][x] in (P("plasterDim"), P("tile")):
                continue
            n = fbm(x * 0.03, y * 0.1, 2231, 2)
            c.c[y][x] = P("mist" if y < STREET + 2 else ("mistDark" if n > 0.5 else "far"))
    # cart ruts and footprints going right, out of the town
    for x in range(110, 320):
        if h1(x, 2233) > 0.25:
            c.c[STREET + 9 + (x // 60) % 2][x] = P("farDeep")
        if h1(x, 2235) > 0.3:
            c.c[STREET + 13][x] = P("farDeep")
    for k in range(18):
        x = 40 + k * 9 + (3 if k % 2 else 0)
        y = STREET + 5 + (2 if k % 2 else 0)
        c.c[y][x] = P("farDeep")
        c.c[y][x + 1] = P("farDeep")


def street_lantern(c, x, base):
    """A street lantern on its post, guttering: a low red flame in a sooted glass, its weak pool on the snow."""
    for y in range(base - 30, base):
        c.c[y][x] = P("woodDark")
        c.c[y][x + 1] = P("night1")
    cluster(c, x - 2, base - 37, [".kkkk.", "kkkkkk", "k.ee.k", "k.Oe.k", "kkkkkk"],
            {"k": "night0", "e": "emberDim", "O": "ember", ".": "night1"})
    for y in range(base - 39, base - 37):
        c.c[y][x] = P("night0")
    for xx in range(x - 5, x + 7):
        for yy in range(base - 1, base + 1):
            if abs(xx - x - 0.5) < 5 - (yy - base + 1) * 2:
                c.c[yy][xx] = P("crimsonDeep") if abs(xx - x - 0.5) < 2 else P("plumDeep")


def leaving(c):
    """A family pulling a handcart out of the picture to the right: the father in the shafts, the mother pushing, a
    child holding her skirt, their bundles, a small lantern on the cart."""
    lay = Layer()
    lay.poly([(284, STREET + 6), (308, STREET + 6), (308, STREET + 1), (284, STREET + 1)], P("woodDark"))
    lay.ellipse(292, STREET + 9, 4.5, 4.5, P("night1"))
    lay.ellipse(292, STREET + 9, 1.5, 1.5, P("woodDark"))
    for (bx, by, rx, ry) in ((289, STREET - 3, 6, 4), (299, STREET - 4, 5, 5), (305, STREET - 2, 4, 3)):
        lay.ellipse(bx, by, rx, ry, P("soil"))
    lay.line([(308, STREET + 3), (318, STREET + 1)], P("woodDark"))
    person(lay, 320, STREET + 8, 24, P("night0"), shoulders=1.0, stoop=3, arms="hold")
    person(lay, 276, STREET + 8, 21, P("night0"), shoulders=0.9, arms="hold", robe=True)
    person(lay, 268, STREET + 8, 11, P("night0"), head=1.3, arms="down")
    lay.paste(c)
    c.c[STREET - 9][286] = P("fireOrange")
    c.c[STREET - 8][286] = P("ember")


def slide1():
    c = Canvas(P("nightBlue"))
    sky(c)
    tops = mountains(c)
    castle(c, tops)
    far_roofs(c)
    house1(c)
    house2(c)
    house3(c)
    house4(c)
    house5(c)
    street(c)
    street_lantern(c, 123, STREET + 3)
    leaving(c)
    snow_flakes(c, 120, 2241, colour="mist", bright="mistLight",
                avoid=lambda x, y: c.c[y][x] in (P("fireGold"), P("fireOrange"), P("ember")))
    return c.finish(ALLOWED, protect=("fireWhite", "fireGold", "fireOrange", "ember", "mistLight", "foam"))


SLIDES = {"slideGutter1": slide1}
