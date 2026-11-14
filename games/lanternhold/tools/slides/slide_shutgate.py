"""The Shuttered Lantern's middle slide, twice (panels-2, fix round 1; critic 1 of panels-2, high 3): the picture follows
its second line (`RealmTale.middlePicture`).

  slideShut2       Seren was handed over: her grey lantern stands in a crenel of the parapet in the grey morning, a
                   third of the way across, snow on its roof, its cold light on the stones; the parapet with its
                   merlons and its stone running away to the right; the Throat's walls faint in the fog beyond
  slideShut2Gate   otherwise: the great gate shut and barred in the grey morning, the house's banners hanging from
                   their poles on either side, wet and grey, dripping; a brazier's last ember the one warm thing

Palette art (paint.finish).
"""
import math

from paint import P, W, H, Canvas, fbm, h1, h2, step
from figure import Layer
from ending_kit import cluster, halo_rings, snow_flakes
from slide_shut import emblem, grey_lantern

ALLOWED = ["night0", "night1", "nightDeep", "nightBlue", "nightSlate", "nightHaze", "farDeep", "far", "farPale",
           "mistDark", "mist", "mistLight", "foam", "stoneDark", "stoneMid", "stone", "stoneLight", "stonePale",
           "wraithWhite", "wraithGlow", "wraithDim", "ink", "woodDark", "wood", "rockDeep", "rockDark",
           "fireOrange", "ember", "emberDim", "roofDeep", "banner", "straw", "soilDark", "soil"]

STONE = ["night1", "stoneDark", "stoneMid", "stone", "stoneLight", "stonePale", "foam"]


def fog_view(c, y0, y1, seed):
    """The Throat beyond the wall in the grey morning: its rock walls faint at both sides in two layers, fog filling it
    in long soft banks, palest in the middle."""
    for y in range(y0, y1):
        for x in range(W):
            v = abs(y - (y0 + (y1 - y0) * 0.55)) / ((y1 - y0) * 0.6) + (fbm(x * 0.01, y * 0.05, seed, 3) - 0.5) * 0.45
            c.c[y][x] = P(["mistLight", "mist", "mistDark", "far"][max(0, min(3, int(v * 2.6)))])
    for (side, seed2, reach, col, lit) in ((-1, seed + 3, 70, "mistDark", "mist"), (1, seed + 5, 64, "mistDark", "mist"),
                                           (-1, seed + 7, 40, "far", "mistDark"), (1, seed + 9, 34, "far", "mistDark")):
        for y in range(y0, y1):
            t = (y - y0) / float(max(1, y1 - y0))
            edge = reach * (0.55 + 0.45 * t) + 12 * fbm(y * 0.04, 0.5, seed2, 3) - 6
            for k in range(int(edge)):
                x = k if side < 0 else W - 1 - k
                d = edge - k
                ledge = (y + int(h1(int(k / 9), seed2) * 6)) % 9 == 0 and d < edge * 0.8
                c.c[y][x] = P(lit if (d < 1.5 or ledge) else col)


# --- slideShut2: Seren's grey lantern in a crenel ----------------------------------------------------------------------

LANTERN_X = 107


def s_at(x):
    """The perspective along the parapet: how big a stone is at x (the wall runs away to the right)."""
    return 1.0 - 0.42 * x / W


def parapet_lines(x):
    top = 34 + 26 * x / W          # the merlons' tops
    sill = 76 + 12 * x / W         # the crenels' sills
    foot = 134 - 22 * x / W        # where the parapet meets the walk
    return top, sill, foot


def crenels():
    """The crenel gaps along the parapet (x0, x1), placed so one is centred on the lantern."""
    s0 = s_at(LANTERN_X)
    gaps = [(LANTERN_X - 21 * s0, LANTERN_X + 21 * s0)]
    while gaps[-1][1] < W + 20:
        e = gaps[-1][1]
        a = e + 48 * s_at(e)
        gaps.append((a, a + 34 * s_at(a)))
    while gaps[0][0] > -40:
        a = gaps[0][0]
        e = a - 48 * s_at(max(0, a))
        gaps.insert(0, (e - 34 * s_at(max(0, e)), e))
    return gaps


def slide2():
    c = Canvas(P("mist"))
    fog_view(c, 0, 120, 2301)
    gaps = crenels()

    def in_gap(x):
        return any(a <= x < b for a, b in gaps)
    # the parapet: its inner face in courses that thin to the right, each block one flat stone colour with its top
    # a step lighter and its joints dark; the merlons stand above the sill between the gaps
    for x in range(W):
        top, sill, foot = parapet_lines(x)
        start = sill if in_gap(x) else top
        s = s_at(x)
        for y in range(int(start), int(foot)):
            course_h = (12 + h1(int((y - top) / (12 * s)), 2302) * 3) * s
            row = int((y - top) / course_h)
            yy = (y - top) - row * course_h
            off = h1(row, 2305) * 40
            # stones of uneven length along the course
            j, left = 0, -40.0
            while True:
                bw = (24 + h1(j + row * 23, 2303) * 26) * s
                if left + bw > x + off:
                    break
                left += bw
                j += 1
            q = x + off - left
            lv = 2 + (1 if h2(j, row, 2307) > 0.62 else 0) - (1 if h2(j, row, 2309) < 0.12 else 0)
            if yy < 1.0 and lv >= 2:
                lv += 1
            if q > bw - 1.6 and lv >= 2:
                lv += 1                     # the stone's end toward the morning light
            if yy > course_h - 1.2 or q < 1.0:
                lv = 0 if lv <= 1 else 1
            c.c[y][x] = P(STONE[max(0, min(6, lv))])
        # the merlon's coping: snow on top, its lip a dark line
        if not in_gap(x):
            c.c[int(top)][x] = P("mistLight")
            c.c[int(top) + 1][x] = P("stonePale")
            c.c[int(top) + 2][x] = P("stoneDark")
        else:
            # the sill's top seen from just above: frosted, its front edge a lit line, a dark line under its lip
            c.c[int(sill)][x] = P("foam")
            c.c[int(sill) + 1][x] = P("stonePale")
            c.c[int(sill) + 2][x] = P("stoneLight")
            c.c[int(sill) + 3][x] = P("stoneDark")
    # each merlon's flank toward us (its left side, seen in the gap before it), and the merlon's edge
    for (a, b) in gaps:
        for x in range(int(math.ceil(b)), int(b + 4 * s_at(b)) + 1):
            if 0 <= x < W:
                top, sill, foot = parapet_lines(x)
                for y in range(int(top), int(sill)):
                    c.c[y][x] = P("stoneMid") if (y - int(top)) % 7 else P("stoneDark")
                c.c[int(top)][x] = P("mistLight")
        xa = int(math.floor(a)) - 1
        if 0 <= xa < W:
            top, sill, foot = parapet_lines(xa)
            for y in range(int(top) + 1, int(sill)):
                c.c[y][xa] = P("stonePale")
    # the walk's floor in front: flags running away to the right, frost in the joints, an arrow left lying
    rows_y = [0, 5, 11, 19, 30, 46]
    for x in range(W):
        foot = parapet_lines(x)[2]
        c.c[int(foot)][x] = P("night1")
        for y in range(int(foot) + 1, H):
            d = y - foot
            row = max(i for i, r in enumerate(rows_y) if r <= d)
            scale = 0.5 + d / 30.0
            bw = (30 + h1(row, 2311) * 20) * scale
            u = x + h1(row, 2313) * 40 + (y - foot) * 0.6
            j = int(u / bw)
            q = u - j * bw
            edge = d - rows_y[row] < 1 or q < 1.0
            lv = 2 + (1 if h2(j, row, 2315) > 0.6 else 0)
            c.c[y][x] = P("mistDark" if (edge and d > 3) else "stoneDark" if edge else STONE[lv])
    for i in range(26):
        x, y = 196 + i, 146 - i // 7
        c.c[y][x] = P("wood" if i < 22 else "stoneLight")
        c.c[y + 1][x] = P("woodDark") if i < 22 else P("stoneMid")
    for (x, y) in ((193, 147), (194, 146), (194, 148)):
        c.c[y][x] = P("stoneLight")
    # Seren's grey lantern on the sill of its crenel: its cold light on the stones round it, snow on its roof
    top, sill, foot = parapet_lines(LANTERN_X)
    base = int(sill) + 1
    stoneish = set(P(n) for n in STONE[1:6])
    halo_rings(c, LANTERN_X, base - 10, [(13, 2), (24, 1)],
               mask=lambda x, y: c.c[y][x] in stoneish and y <= base + 5, squash=0.8)
    lan = Layer()
    grey_lantern(lan, LANTERN_X, base, 1.25)
    # snow on its roof: the cap's top and its rim white, a hanging lip, and the iron's outline over the snow
    body_top = base - 30 * 1.25
    src = dict(lan.px)
    for (x, y), col in src.items():
        if y <= body_top and (x, y - 1) not in src and y > body_top - 12:
            lan.px[(x, y)] = P("foam") if x <= LANTERN_X + 2 else P("mistLight")
            if (x, y + 1) in src and y + 1 < body_top - 1:
                lan.px[(x, y + 1)] = P("mistLight") if x <= LANTERN_X else P("mist")
    for (x, y) in ((LANTERN_X - 13, int(body_top)), (LANTERN_X - 12, int(body_top) + 1),
                   (LANTERN_X + 12, int(body_top))):
        lan.put(x, y, P("mistLight"))
    lan.outline(P("night0"), skip_bottom=True)
    lan.paste(c)
    # a raven on a merlon further along, turned toward the lantern
    rx = 268
    rtop = int(parapet_lines(rx)[0])
    cluster(c, rx, rtop - 5, ["..kk...", ".kkkk..", "kkkkkkk", ".kkkkkk", "..k.k.."], {"k": "night0"})
    snow_flakes(c, 50, 2317, colour="mistLight", bright="foam", y_max=110,
                avoid=lambda x, y: c.c[y][x] in (P("wraithWhite"), P("wraithGlow")))
    return c.finish(ALLOWED, protect=("wraithWhite", "wraithGlow", "foam", "mistLight"))


# --- slideShut2Gate: the shut gate and the wet banners -----------------------------------------------------------------

GROUND = 138
ARCH = (160, 30, 46)       # the arch's centre x, its crown, its half width


def gate_wall(c):
    """The gatehouse's inner face: big blocks in courses, each one flat grey with a lit top and dark joints; the
    morning's grey light from above."""
    y = 0
    row = 0
    while y < GROUND:
        hgt = 10 + int(h1(row, 2401) * 6)
        x = -int(h1(row, 2403) * 30)
        j = 0
        while x < W:
            bw = 18 + int(h1(j + row * 17, 2405) * 34)
            lv = 2 + (1 if h2(j, row, 2407) > 0.66 else 0) - (1 if h2(j, row, 2409) < 0.14 else 0)
            for yy in range(y, min(GROUND, y + hgt)):
                for xx in range(max(0, x), min(W, x + bw)):
                    v = lv + (1 if yy == y else 0) + (1 if (xx >= x + bw - 2 and lv >= 2) else 0)
                    if yy == y + hgt - 1 or xx == x:
                        v = 0 if lv <= 1 else 1
                    c.c[yy][xx] = P(STONE[max(0, min(6, v))])
            x += bw
            j += 1
        y += hgt
        row += 1


def arch_inside(x, y):
    """Inside the gate's round arch."""
    cx, crown, hw = ARCH
    spring = crown + hw
    if abs(x + 0.5 - cx) > hw or y >= GROUND:
        return False
    return y >= spring or (x + 0.5 - cx) ** 2 + (y + 0.5 - spring) ** 2 <= hw * hw


def gate(c):
    """The great gate shut: the arch's voussoirs, two leaves of heavy planks with iron straps and studs, the wicket
    shut, the huge bar across in its iron brackets with frost on its top; water standing at its foot."""
    cx, crown, hw = ARCH
    # the voussoirs round the arch: a ring of wedge stones, lit on top
    spring = crown + hw
    for y in range(crown - 9, GROUND):
        for x in range(int(cx - hw - 9), int(cx + hw + 10)):
            if arch_inside(x, y):
                continue
            if y < spring:
                r = math.hypot(x + 0.5 - cx, y + 0.5 - spring)
                if r > hw + 8:
                    continue
                a = math.atan2(y + 0.5 - spring, x + 0.5 - cx)
                k = int((a + math.pi) / (math.pi / 9))
                joint = abs((a + math.pi) / (math.pi / 9) - k) < 0.1 or r > hw + 7
                lit = r < hw + 1.2
                c.c[y][x] = P("night1" if joint else "stoneDark" if lit else ("stone" if k % 2 else "stoneMid"))
            elif abs(x + 0.5 - cx) <= hw + 8:
                # the jambs: dressed stones, the inner edge in shadow
                k = int((y - spring) / 12)
                joint = (y - spring) % 12 == 11 or abs(abs(x + 0.5 - cx) - hw - 8) < 0.6
                inner = abs(x + 0.5 - cx) < hw + 1.5
                c.c[y][x] = P("night1" if joint else "stoneDark" if inner else ("stone" if k % 2 else "stoneMid"))
    # the leaves: planks, iron straps, studs, the seam between them
    for y in range(crown, GROUND):
        for x in range(int(cx - hw), int(cx + hw) + 1):
            if not arch_inside(x, y):
                continue
            plank = int((x - (cx - hw)) / 6)
            col = "night1" if (x - (cx - hw)) % 6 == 0 else ("soil" if plank % 3 == 1 else "woodDark")
            if abs(x - cx) < 1:
                col = "night0"
            c.c[y][x] = P(col)
    for sy in (52, 78, 108, 128):
        for x in range(int(cx - hw), int(cx + hw) + 1):
            for yy in (sy, sy + 1):
                if arch_inside(x, yy) and abs(x - cx) >= 1:
                    c.c[yy][x] = P("stoneDark") if yy == sy else P("night1")
            if (x - int(cx - hw)) % 5 == 2 and arch_inside(x, sy):
                c.c[sy][x] = P("stone")
    # the wicket in the left leaf, shut
    for y in range(110, GROUND):
        for x in range(int(cx - 30), int(cx - 14)):
            if y == 110 or x in (int(cx - 30), int(cx - 15)):
                c.c[y][x] = P("night0")
    c.c[124][int(cx - 17)] = P("stone")
    # the bar across: a squared beam in two brackets, frost along its top, its face in shade
    by = 90
    for x in range(int(cx - hw - 14), int(cx + hw + 15)):
        for y in range(by, by + 9):
            c.c[y][x] = P("woodDark") if y > by + 1 else P("wood")
        c.c[by][x] = P("mistLight") if h1(x, 2411) > 0.25 else P("stonePale")
        c.c[by + 9][x] = P("night0")
    for bx in (int(cx - hw - 10), int(cx + hw + 4)):
        for y in range(by - 3, by + 12):
            for x in range(bx, bx + 7):
                c.c[y][x] = P("stoneDark") if (y in (by - 3, by + 11) or x in (bx, bx + 6)) else P("night1")
        c.c[by - 3][bx + 3] = P("stoneLight")


def wet_banner(c, x0, top, width, length, seed):
    """One of the house's banners hanging from its pole, wet through: the teal gone grey and heavy, the cloth hanging
    straight with a few clinging folds, its lower part darker with the water, the swallowtail's points dripping, the
    gold thread of the lantern dull."""
    # the pole from the wall, an iron bracket, a finial
    for x in range(x0 - 4, x0 + width + 4):
        c.c[top - 2][x] = P("woodDark")
        c.c[top - 1][x] = P("night1")
    c.c[top - 3][x0 + width + 3] = P("stoneLight")
    lay = Layer()
    for x in range(x0, x0 + width):
        t = (x - x0) / float(width - 1)
        notch = 9 * (1 - abs(t - 0.5) * 2)
        cling = 1.5 * math.sin(t * math.pi * 3 + seed)
        for y in range(top, int(top + length - notch + cling)):
            u = (y - top) / float(length)
            fold = int((x - x0 + int(u * 3)) / 4) % 2 == 1
            wet = u > 0.55 + 0.1 * math.sin(x * 0.7 + seed)
            col = ("roofDeep" if fold else "banner") if not wet else ("nightBlue" if fold else "roofDeep")
            lay.put(x, y, P(col))
    # its border, dull gold thread gone dark with the wet
    for (x, y), col in list(lay.px.items()):
        if (x - 1, y) not in lay.px or (x + 1, y) not in lay.px:
            lay.px[(x, y)] = P("mistDark")
    # the house's lantern in dulled thread
    em = Layer()
    emblem(em, x0 + width // 2, top + 30, P("straw"), P("stoneLight"))
    for (x, y), col in em.px.items():
        if (x, y) in lay.px:
            lay.px[(x, y)] = col
    lay.outline(P("night0"), skip_bottom=False)
    lay.paste(c)
    # drips from the points, and the drops on their way down
    for (dx, k) in ((0, 0), (width - 1, 1), (width // 2, 2)):
        x = x0 + dx
        y_end = max(y for (xx, y) in lay.px if xx == x) + 1
        c.c[y_end][x] = P("mist")
        for n in range(3):
            y = y_end + 5 + n * 9 + int(h1(n + k * 5, seed) * 4)
            if y < GROUND:
                c.c[y][x] = P("mistLight")


def brazier(c, x, base):
    """A guard's brazier by the wall, burned out in the night: an iron basket on three legs, the ash grey, two embers
    left in it, a thread of smoke going up."""
    cluster(c, x - 9, base - 22, ["kkkkkkkkkkkkkkkkkkk",
                                  "kmmdmEOdmmdmmEdmmmk",
                                  ".kmmmmmmmmmmmmmmmk.",
                                  "..kkdkdkdkdkdkdkk..",
                                  "...kkkkkkkkkkkkk...",
                                  ".......k...k.......",
                                  "......k.....k......",
                                  "......k.....k......",
                                  ".....k...k...k.....",
                                  ".....k...k...k.....",
                                  "....k....k....k....",
                                  "....k....k....k....",
                                  "...k.....k.....k...",
                                  "...k.....k.....k...",
                                  "..k......k......k..",
                                  "..k......k......k..",
                                  ".kk.....kkk.....kk."],
            {"k": "night0", "d": "stoneDark", "m": "stoneMid", "E": "ember", "O": "fireOrange"})
    for k in range(26):
        xx = x - 2 + int(round(math.sin(k * 0.45) * 1.6 - k * 0.25))
        y = base - 24 - k
        c.c[y][xx] = P("mist" if k < 11 else "mistDark")


def slide2gate():
    c = Canvas(P("stone"))
    gate_wall(c)
    gate(c)
    wet_banner(c, 64, 26, 24, 82, 2421)
    wet_banner(c, 232, 26, 24, 82, 2423)
    # the yard's wet flags, the grey sky lying in a puddle before the gate
    rows_y = [0, 4, 9, 15, 22]
    for y in range(GROUND, H):
        d = y - GROUND
        row = max(i for i, r in enumerate(rows_y) if r <= d)
        for x in range(W):
            bw = (22 + h1(row, 2427) * 16) * (0.7 + d / 30.0)
            u = x + h1(row, 2429) * 30 + (x - 160) * d * 0.02
            j = int(u / bw)
            q = u - j * bw
            edge = d - rows_y[row] < 1 or q < 1.0
            lv = 1 + (1 if h2(j, row, 2431) > 0.55 else 0)
            c.c[y][x] = P("night1" if (edge or d < 1) else STONE[lv])
        if d == 0:
            for x in range(W):
                c.c[y][x] = P("night0")
    for y in range(GROUND + 3, GROUND + 14):
        for x in range(100, 222):
            d = math.hypot((x - 160) / 62.0, (y - GROUND - 8) / 6.0)
            if d < 1:
                c.c[y][x] = P("mistDark" if d > 0.86 else ("woodDark" if abs(x - 160) < 46 and y < GROUND + 7 else
                                                            "far"))
    brazier(c, 30, GROUND + 6)
    snow_flakes(c, 26, 2425, colour="mist", bright="mistLight", y_max=GROUND)
    return c.finish(ALLOWED, protect=("ember", "emberDim", "fireOrange", "mistLight", "foam"))


SLIDES = {"slideShut2": slide2, "slideShut2Gate": slide2gate}
