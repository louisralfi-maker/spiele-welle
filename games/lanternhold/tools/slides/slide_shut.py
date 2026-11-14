"""The Shuttered Lantern (panels-2; STORY.md section 7, "The endings"): the realm held until dawn, but the King did
not fall. Its light is a cold grey first light, the colour of ash and frost; one small warm thing in each picture.

  slideShut1   the Lightless King, the game's own figure, walking back into the Gloom's fog at first light with the
               snuffer; the faint smoke folk going with him; the outer line's broken wall behind, a brazier smoking
  slideShut2   on the wall in the grey morning: a grey lantern standing on the coping, still burning (Seren's, if she
               was handed over; the leaning and the houses are said under it)
  slideShut3   Bram, stooped, before the herald's banner on its rack: half still black with soot, half washed, and
               under the black in gold thread our lantern beneath half a sun

Palette art (paint.finish).
"""
import math

from paint import P, W, H, Canvas, fbm, h1, h2, sprite, step
from figure import Layer
from ending_kit import cluster, dawn_sky, person, ragged_top, strata_rock

GROUND = 128
FOG_EDGE = 150

S1_ALLOWED = ["night0", "night1", "nightDeep", "nightBlue", "nightSlate", "nightHaze", "farDeep", "far", "farPale",
              "mistDark", "mist", "mistLight", "foam", "stoneDark", "stoneMid", "stone", "stoneLight", "rockDeep",
              "rockDark", "rock", "woodDark", "wood", "ember", "fireOrange", "emberDim", "wraithDim", "wraithGlow",
              "ink", "moorDark", "moor"]


def grey_sky(c, y1):
    # first light from the right (east): pale at the right, the Gloom's dark at the left
    for y in range(0, y1):
        for x in range(W):
            v = x / float(W) * 1.2 - y / float(y1) * 0.25 + (fbm(x * 0.008, y * 0.04, 1101, 3) - 0.5) * 0.35
            ramp = ["nightSlate", "farDeep", "far", "mistDark", "mist", "mistLight", "farPale"]
            c.c[y][x] = P(ramp[max(0, min(len(ramp) - 1, int((v + 0.15) * 4.2)))])


def throat_cliffs(c):
    """The Throat's walls far behind, as the fog lets them show: two layers of rock in silhouette, the nearer darker,
    their ledges a thin grey line where the first light catches them."""
    for (base, amp, seed, col, ledge) in ((40, 18, 1103, "far", "mistDark"), (62, 22, 1104, "farDeep", "far")):
        for x in range(W):
            top = base + amp * fbm(x * 0.011, 0.3, seed, 3) + 5 * math.sin(x * 0.023 + seed)
            for y in range(int(top), GROUND):
                c.c[y][x] = P(col)
            if x > 120:
                c.c[int(top)][x] = P(ledge)
        for k in range(0):
            x0 = int(h1(k, seed + 7) * 280) + 120
            y0 = int(base + amp + 10 + h1(k, seed + 9) * 40)
            ln = 8 + int(h1(k, seed + 11) * 22)
            for i in range(ln):
                X = x0 + i
                Y = y0 + int(i * 0.15)
                if 0 <= X < W and 0 <= Y < GROUND and c.c[Y][X] == P(col):
                    c.c[Y][X] = P(ledge)
                    if Y + 1 < GROUND:
                        c.c[Y + 1][X] = step(P(col), -1)


def gloom_fog(c):
    """The Gloom's fog at the left, a wall of smoke the King walks back into: billows lit grey on the side toward the
    light, dark inside with slow swirls."""
    for y in range(0, GROUND + 6):
        edge = FOG_EDGE + 14 * math.sin(y * 0.06 + 0.8) + 12 * fbm(y * 0.05, 0.6, 1107, 2) - (GROUND - y) * 0.15
        for x in range(0, int(edge) + 1):
            d = edge - x
            swirl = fbm(x * 0.03, y * 0.05, 1109, 3)
            if d < 1.5:
                col = "mistDark"
            elif d < 6:
                col = "far"
            elif swirl > 0.68:
                col = "far"
            elif swirl < 0.3:
                col = "nightSlate"
            else:
                col = "farDeep"
            c.c[y][x] = P(col)


def ground_shut1(c):
    for y in range(GROUND, H):
        for x in range(W):
            n = fbm(x * 0.02, y * 0.08, 1113, 2)
            col = "stoneDark" if n > 0.45 else "nightSlate"
            if y == GROUND:
                col = "stoneMid" if x > 120 else "farDeep"
            c.c[y][x] = P(col)
    # rubble from the night, stones placed one by one, lit on their right
    for k in range(22):
        x = int(h1(k, 1115) * 300) + 10
        y = int(GROUND + 3 + h1(k, 1116) ** 0.8 * 27)
        r = 1 + int(h1(k, 1117) * 2 + (y - GROUND) * 0.06)
        for yy in range(y - r, y + 1):
            for xx in range(x - r - 1, x + r + 2):
                if 0 <= xx < W and 0 <= yy < H and ((xx - x) / (r + 1.0)) ** 2 + ((yy - y) / float(r)) ** 2 <= 1:
                    c.c[yy][xx] = P("stone" if xx > x else "stoneMid")
        c.c[y - r][x] = P("stoneLight")
    # arrows stuck in the ground, leaning
    for k in range(9):
        x = int(170 + h1(k, 1119) * 140)
        y = int(GROUND + 3 + h1(k, 1120) * 20)
        for i in range(6):
            X, Y = x - i // 2, y - i
            if 0 <= X < W and 0 <= Y < H:
                c.c[Y][X] = P("wood" if i < 5 else "stoneLight")


def outer_wall(c):
    """The outer line's wall at the right, broken at the top in the night: dark, its edge toward the light grey; a
    brazier on it still smoking, the last warm thing; two archers watching."""
    for x in range(268, W):
        jag = 8 * fbm(x * 0.3, 0.4, 1121, 2) + (6 if 286 < x < 296 else 0)
        top = 62 + jag
        for y in range(int(top), GROUND + 2):
            col = "nightBlue"
            if x < 271:
                col = "mistDark"
            elif (y - 62) % 9 == 0 and h1(x // 14 + y, 1123) > 0.3:
                col = "nightSlate"
            c.c[y][x] = P(col)
        c.c[int(top)][x] = P("mistDark")
    # the brazier and its smoke
    cluster(c, 300, 52, ["kkkkkkk", ".kEOEk.", "..kkk..", "...k...", "...k...", "..kkk.."],
            {"k": "night0", "E": "ember", "O": "fireOrange"})
    for k in range(22):
        x = 303 + int(round(math.sin(k * 0.45) * 1.5 - k * 0.5))
        y = 50 - k
        if 0 <= y < H and 0 <= x < W:
            c.c[y][x] = P("mistDark" if k < 12 else "far")
    for (ax, ay) in ((280, 58), (320, 60)):
        lay = Layer()
        person(lay, ax, ay, 12, P("night0"), arms="down")
        lay.paste(c)


def king(c, x, feet):
    """The Lightless King, the game's own sprite (lightlessKing, a walking frame), turned to walk left into the fog:
    darkened to a silhouette against the grey, the cold first light along his back and crown."""
    rows = sprite("lightlessKing", 2, 7)
    h = len(rows)
    w = len(rows[0])
    lay = Layer()
    for yy in range(h):
        for xx in range(w):
            p = rows[yy][w - 1 - xx]
            if p[3] < 128:
                continue
            lum = (p[0] + p[1] + p[2]) / 3.0
            col = "night0" if lum < 30 else "nightDeep" if lum < 50 else "nightBlue" if lum < 75 else "nightSlate"
            lay.put(x + xx, feet - h + yy, P(col))
    for (px, py), col in list(lay.px.items()):
        if (px + 1, py) not in lay.px or (px, py - 1) not in lay.px and px > x + 26:
            lay.px[(px, py)] = P("mist") if py < feet - 30 else P("mistDark")
    lay.paste(c)
    return lay


def smoke_folk(c):
    """The Gloom's folk going back with him, already thinning: tall faint figures at the fog's edge, their eyes the
    last cold lights."""
    for (x, feet, hgt, col) in ((114, GROUND + 3, 50, "mistDark"), (86, GROUND - 2, 56, "far"),
                                (134, GROUND + 6, 30, "mistDark"), (58, GROUND - 6, 46, "far"),
                                (30, GROUND - 8, 52, "farDeep")):
        lay = Layer()
        person(lay, x, feet, hgt, P(col), shoulders=0.58, hips=0.75, head=0.8, arms="down", robe=True, robe_hem=1.5)
        lay.paste(c)
        hx = int(x)
        hy = int(feet - hgt + hgt * 0.08)
        c.c[hy][hx - 1] = P("wraithGlow")
        c.c[hy][hx + 1] = P("wraithGlow")


def slide1():
    c = Canvas(P("far"))
    grey_sky(c, GROUND)
    throat_cliffs(c)
    gloom_fog(c)
    smoke_folk(c)
    ground_shut1(c)
    outer_wall(c)
    # his long shadow toward us and to the left, thrown by the light at his back
    k = king(c, 146, GROUND + 4)
    for (px, py) in list(k.px):
        if py > GROUND - 20:
            for s in range(1, 14):
                X, Y = px - s, GROUND + 4 + s // 3
                if 0 <= X < W and 0 <= Y < H and (X, Y) not in k.px:
                    c.c[Y][X] = step(c.c[Y][X], -1)
    k.paste(c)
    # the fog's edge already over his front: a few pale wisps across him as he walks into it
    for (y0, x0, ln, seed) in ((86, 140, 22, 1131), (98, 136, 26, 1133), (112, 138, 20, 1135), (122, 132, 30, 1137),
                               (78, 146, 12, 1139)):
        for i in range(ln):
            x = x0 + i
            y = int(y0 + math.sin(i * 0.3 + seed) * 1.2)
            if 0 <= x < W and 0 <= y < H and (i < ln - 3 or h1(i, seed) > 0.5):
                c.c[y][x] = P("mistDark" if i < ln * 0.6 else "far")
    return c.finish(S1_ALLOWED, protect=("fireOrange", "ember", "wraithGlow", "mist"))


# --- slide 2: the grey lantern on the wall ----------------------------------------------------------------------------

S2_ALLOWED = ["night0", "night1", "nightDeep", "nightBlue", "nightSlate", "nightHaze", "farDeep", "far", "farPale",
              "mistDark", "mist", "mistLight", "foam", "stoneDark", "stoneMid", "stone", "stoneLight", "stonePale",
              "wraithWhite", "wraithGlow", "wraithDim", "tealDim", "ink", "woodDark", "wood", "fireOrange", "ember",
              "rockDeep", "rockDark"]


def grey_lantern(lay, cx, base, sc):
    """Seren's grey lantern drawn at size `sc` from its shapes (never scaled pixels): a ring, a pyramid cap with its
    lit face, a body of three panes in an iron frame, a flame that burns grey and gives no warmth, a heavy foot.
    (cx, base): the middle of its foot on the stone."""
    k, i, I, hi = P("night0"), P("stoneDark"), P("stoneMid"), P("stone")
    bw = 10 * sc                       # half the body's width
    body_top, body_bot = base - 30 * sc, base - 6 * sc
    cap_top = body_top - 7 * sc
    # the foot
    lay.poly([(cx - bw - 1, base), (cx + bw + 1, base), (cx + bw - 1, body_bot), (cx - bw + 1, body_bot)], i)
    for x in range(int(cx - bw), int(cx + bw)):
        lay.put(x, int(body_bot) + 1, I)
    # the body: the side panes dim, the front pane alight
    for y in range(int(body_top), int(body_bot) + 1):
        for x in range(int(cx - bw), int(cx + bw) + 1):
            u = (x - cx) / bw
            if abs(u) > 0.94 or abs(abs(u) - 0.42) < 0.07 or y in (int(body_top), int(body_bot)):
                col = k
            elif abs(u) > 0.42:
                col = P("far") if (y - int(body_top)) % int(6 * sc) == 0 else P("mistDark")
                if abs(abs(u) - 0.52) < 0.06:
                    col = P("wraithDim")
            else:
                fy = body_top + (body_bot - body_top) * 0.55
                d = math.hypot((x - cx) / (2.6 * sc), (y - fy) / ((5.8 if y < fy else 3.6) * sc))
                col = P("wraithWhite") if d < 0.55 else P("wraithGlow") if d < 1.1 else P("wraithDim")
            lay.put(x, y, col)
    # the wick
    for y in range(int(body_bot - 4 * sc), int(body_bot)):
        lay.put(int(cx), y, k)
    # the cap: a pyramid, its face toward the light a step lighter, a rim under it
    for y in range(int(cap_top), int(body_top)):
        t = (y - cap_top) / (body_top - cap_top)
        half = 2 + t * (bw + 1)
        for x in range(int(cx - half), int(cx + half) + 1):
            col = k if abs(x - (cx - half)) < 1 or abs(x - (cx + half)) < 1 else (hi if x < cx - 1 else I)
            lay.put(x, y, col)
    for x in range(int(cx - bw - 2), int(cx + bw + 3)):
        lay.put(x, int(body_top) - 1, k)
    # the ring on top
    lay.ellipse(cx, cap_top - 3 * sc, 2.6 * sc, 2.4 * sc, k)
    lay.ellipse(cx, cap_top - 3 * sc, 1.4 * sc, 1.2 * sc, P("mist"))


def slide2():
    c = Canvas(P("mist"))
    # the grey morning over the Throat seen from the wall: fog filling it in soft long bands
    ramp = ["mistLight", "mist", "mistDark", "far", "farDeep"]
    for y in range(0, H):
        for x in range(W):
            v = abs(y - 72) / 62.0 + (fbm(x * 0.006, y * 0.04, 1201, 3) - 0.5) * 0.5
            c.c[y][x] = P(ramp[max(0, min(4, int(v * 3.0)))])
    for (side, seed) in ((-1, 1203), (1, 1205)):
        for y in range(0, 120):
            edge = 46 + 24 * fbm(y * 0.03, 0.5, seed, 2) - y * 0.1
            for kk in range(int(edge)):
                x = kk if side < 0 else W - 1 - kk
                d = edge - kk
                c.c[y][x] = P("mistDark" if d < 2 else "far" if d < 14 else "farDeep")
    # far off in the middle the Great Beacon, cold, its bowl empty
    tower = Layer()
    tx, tb = 222, 94
    tower.poly([(tx - 4, tb), (tx + 4, tb), (tx + 3, tb - 24), (tx - 3, tb - 24)], P("far"))
    tower.poly([(tx - 8, tb - 29), (tx + 8, tb - 29), (tx + 5, tb - 25), (tx - 5, tb - 25)], P("far"))
    tower.paste(c)
    # the wall walk's coping running away from us to the right: big stones, their tops frosted, the face in shade
    back = lambda x: 116 - x * 0.03  # noqa: E731
    front = lambda x: 146 - x * 0.12  # noqa: E731
    vp_x = 900.0
    for x in range(W):
        bt, ft = back(x), front(x)
        for y in range(int(bt), H):
            if y < ft:
                # the top: joints running toward the far end
                col = "stonePale" if y < bt + 1 else "stoneLight"
            elif y < ft + 1:
                col = "stone"
            else:
                col = "stoneMid" if y < ft + 14 else "stoneDark"
            c.c[y][x] = P(col)
    # the joints between the coping stones, each a clean dark line from the front edge back toward the far end
    for jx in (18, 132, 222, 290):
        for y in range(int(back(jx)), int(front(jx))):
            t = (y - back(jx)) / max(1.0, front(jx) - back(jx))
            x = int(round(jx + (t - 0.5) * 6))
            if 0 <= x < W:
                c.c[y][x] = P("stoneMid")
        for y in range(int(front(jx)) + 1, H):
            x = int(round(jx + 3))
            if 0 <= x < W:
                c.c[y][x] = P("night1")
    # frost lying in little drifts on the coping, an arrow left there
    for f in range(14):
        fx = int(h1(f, 1215) * 300) + 10
        fy = int(back(fx) + 2 + h1(f, 1216) * (front(fx) - back(fx) - 4))
        for d in range(2 + int(h1(f, 1217) * 4)):
            if 0 <= fx + d < W:
                c.c[fy][fx + d] = P("foam")
    for i in range(22):
        x = 148 + i
        c.c[int(front(x)) - 4 - i // 8][x] = P("wood" if i < 18 else "stoneMid")
    # a raven further along the wall, turned toward the lantern
    rx = 262
    cluster(c, rx, int(back(rx)) - 2, ["...kk..", "..kkkk.", "kkkkkkk", ".kkkkkk", "..k.k.."], {"k": "night0"})
    # the grey lantern standing on the coping near us, its cold light pale on the frost round its foot
    lx, lb = 84, 132
    for y in range(int(back(lx)), int(front(lx))):
        for x in range(30, 140):
            d = math.hypot((x - lx) / 46.0, (y - lb + 1) / 7.0)
            if d < 1 and c.c[y][x] in (P("stoneLight"), P("stonePale"), P("foam"), P("stoneMid")):
                c.c[y][x] = P("foam") if d < 0.42 else P("mistLight")
    lan = Layer()
    grey_lantern(lan, lx, lb, 1.7)
    lan.paste(c)
    return c.finish(S2_ALLOWED, protect=("wraithWhite", "wraithGlow", "foam", "stonePale"))


# --- slide 3: Bram and the herald's banner --------------------------------------------------------------------------

S3_ALLOWED = ["night0", "night1", "nightDeep", "nightBlue", "nightSlate", "farDeep", "far", "farPale", "mistDark",
              "mist", "mistLight", "foam", "stoneDark", "stoneMid", "stone", "stoneLight", "stonePale", "banner",
              "roofDeep", "roofLight", "gold", "fireGold", "woodDark", "wood", "woodLight", "soilDark", "soil",
              "ink", "fireOrange", "ember", "waterDeep", "tile", "tileLight"]


def emblem(lay, cx, cy, col, shine):
    """Our lantern beneath half a sun, as the old arms have it, in gold thread."""
    # half a sun: an arc with rays
    for k in range(0, 181, 6):
        a = math.radians(180 + k)
        x = cx + 9 * math.cos(a)
        y = cy - 10 + 7 * math.sin(a) * 0.9
        lay.put(round(x), round(y), col)
    for k in range(0, 181, 30):
        a = math.radians(180 + k)
        for r in (11, 12, 13):
            lay.put(round(cx + r * math.cos(a)), round(cy - 10 + r * 0.8 * math.sin(a)), col)
    for x in range(cx - 9, cx + 10):
        lay.put(x, cy - 10, col)
    # the lantern: ring, cap, frame, panes, foot
    for (dx, dy) in ((0, -7), (-1, -6), (1, -6)):
        lay.put(cx + dx, cy + dy, col)
    for x in range(cx - 3, cx + 4):
        lay.put(x, cy - 5, col)
        lay.put(x, cy + 6, col)
    for y in range(cy - 4, cy + 6):
        lay.put(cx - 4, y, col)
        lay.put(cx + 4, y, col)
        lay.put(cx, y, col)
    for (dx, dy) in ((-2, -1), (2, 0), (-2, 2), (2, 3)):
        lay.put(cx + dx, cy + dy, shine)
    for x in range(cx - 5, cx + 6):
        lay.put(x, cy + 7, col)


def slide3():
    c = Canvas(P("mist"))
    # the yard wall behind in the grey light: big ashlar in uneven courses, cold
    strata_rock(c, lambda x, y: y < 130, ["nightBlue", "nightSlate", "farDeep", "far", "mistDark", "mist"],
                light_x=-1, seed=1301, band=(15, 21), block=(34, 64), tilt=0.0)
    # the yard's floor, wet and flat, the grey sky in it; a puddle under the tub with the banner in it
    for y in range(130, H):
        for x in range(W):
            c.c[y][x] = P("stoneDark" if y > 131 else "night1")
    for (x0, y0, ln) in ((10, 138, 40), (200, 136, 30), (40, 150, 60), (250, 152, 50), (150, 146, 24)):
        for i in range(ln):
            c.c[y0][x0 + i] = P("stoneMid")
    for y in range(133, 146):
        for x in range(90, 178):
            d = math.hypot((x - 134) / 46.0, (y - 139) / 7.0)
            if d < 1:
                col = "mistDark" if d > 0.85 else ("roofDeep" if 112 < x < 160 and y < 141 else "far")
                if x in (124, 131, 138) and y == 137:
                    col = "gold"
                c.c[y][x] = P(col)
    # the rack: two posts, a crossbar
    for x0 in (62, 166):
        for y in range(30, 132):
            for x in range(x0, x0 + 3):
                c.c[y][x] = P("woodDark" if x == x0 + 2 else "wood")
    for x in range(56, 175):
        for y in (30, 31, 32):
            c.c[y][x] = P("woodDark" if y == 32 else "woodLight" if y == 30 else "wood")
    # the banner hung over the bar: a long cloth with a swallowtail, half still black with soot (left), half washed
    lay = Layer()
    bx0, bx1, by0, by1 = 72, 160, 33, 112
    for x in range(bx0, bx1):
        t = (x - bx0) / float(bx1 - bx0)
        bottom = by1 + (16 * (1 - abs(t - 0.5) * 2) if False else 0)
        notch = 14 * (1 - abs(t - 0.5) * 2)
        sag = 1.5 * math.sin(t * math.pi)
        for y in range(by0, int(by1 - notch + sag) + 1):
            washed = x > 112 + 6 * math.sin(y * 0.15) + 3 * fbm(x * 0.2, y * 0.1, 1305, 2)
            fold = int((x - bx0) / 11) % 2 == 1
            if washed:
                col = "banner" if not fold else "roofDeep"
                if x >= bx1 - 2:
                    col = "roofDeep"
            else:
                streak = fbm(x * 0.45, y * 0.025, 1307, 2)
                col = "night1" if streak > 0.5 else "stoneDark" if streak > 0.38 else "night0"
                if fold:
                    col = "night0" if col == "night1" else col
            lay.put(x, y, P(col))
    # gold thread on the washed half, a smudge of it still under the soot at the edge
    em = Layer()
    emblem(em, 132, 72, P("gold"), P("fireGold"))
    for (x, y), col in em.px.items():
        if lay.has(x, y):
            under = lay.get(x, y) in (P("night1"), P("night0"), P("stoneDark"))
            lay.put(x, y, P("woodLight") if under and h1(x + y, 1309) > 0.5 else (P("night1") if under else col))
    # a border of gold along the hem
    for x in range(bx0, bx1):
        t = (x - bx0) / float(bx1 - bx0)
        notch = 14 * (1 - abs(t - 0.5) * 2)
        y = int(by1 - notch + 1.5 * math.sin(t * math.pi)) - 2
        if lay.has(x, y) and lay.get(x, y) in (P("banner"), P("roofDeep")):
            lay.put(x, y, P("gold"))
    lay.outline(P("night0"), skip_bottom=False)
    lay.paste(c)
    # water dripping from its hem into the tub, the tub of grey water
    for (x, y0, n) in ((116, 104, 3), (128, 101, 2), (142, 106, 3), (152, 110, 2)):
        for k in range(n):
            y = y0 + 4 + k * 5
            if y < 124:
                c.c[y][x] = P("mistLight")
    for y in range(118, 132):
        for x in range(96, 168):
            edge = x in (96, 167) or y == 131
            c.c[y][x] = P("woodDark" if edge else ("wood" if y > 120 else "waterDeep"))
        if y == 118:
            for x in range(97, 167):
                c.c[y][x] = P("mist")
    for x in range(98, 166):
        c.c[119][x] = P("mistDark")
        c.c[120][x] = P("woodLight" if x % 9 == 0 else "wood")
    # Bram, seen from behind, stooped, before the banner: a smith's broad rounded back, the leather apron's straps
    # crossed over his shirt, the sleeves rolled on thick bare forearms, grey hair thin on top, the scrubbing brush
    # hanging from one big hand; the light from the sky at the upper left along his shoulder and head
    br = Layer()
    bx, feet = 238, 168
    shirt, shirt_hi, shade = P("mistDark"), P("mist"), P("far")
    # legs and the apron's skirt
    br.poly([(bx - 20, feet - 50), (bx + 20, feet - 50), (bx + 22, feet), (bx - 22, feet)], P("woodDark"))
    # the back: broad, rounded over the shoulders, bowed forward
    br.poly([(bx - 26, feet - 84), (bx + 26, feet - 84), (bx + 24, feet - 48), (bx - 24, feet - 48)], shirt)
    br.ellipse(bx, feet - 86, 27, 13, shirt)
    br.ellipse(bx - 22, feet - 82, 7, 8, shirt)
    br.ellipse(bx + 22, feet - 82, 7, 8, shirt)
    # the head bowed low between the shoulders: grey hair, thin on top, the neck's fold
    br.ellipse(bx - 2, feet - 98, 7.5, 7.0, P("stone"))
    for (dx, dy, col) in ((-4, -103, "stoneLight"), (-1, -104, "stoneLight"), (2, -103, "stoneMid"),
                          (-6, -99, "stoneLight"), (4, -99, "stoneMid"), (-1, -101, "tile"), (0, -102, "tile")):
        br.put(bx + dx, feet + dy, P(col))
    br.ellipse(bx - 2, feet - 91, 5, 2.4, P("tile"))
    # the apron's straps crossing on his back, the knot at the waist
    br.line([(bx - 18, feet - 92), (bx + 12, feet - 50)], P("woodDark"))
    br.line([(bx - 17, feet - 92), (bx + 13, feet - 50)], P("woodDark"))
    br.line([(bx + 18, feet - 92), (bx - 12, feet - 50)], P("woodDark"))
    br.line([(bx + 17, feet - 92), (bx - 13, feet - 50)], P("woodDark"))
    br.ellipse(bx, feet - 50, 4, 2.2, P("wood"))
    # the arms hanging, sleeves rolled to the elbow, thick forearms, the brush in the left hand
    for side in (-1, 1):
        sx = bx + side * 28
        br.capsule((sx, feet - 82), (sx + side * 3, feet - 60), 6.0, 5.5, shirt)
        br.capsule((sx + side * 3, feet - 60), (sx + side * 2, feet - 38), 5.0, 4.4, P("tile"))
        br.ellipse(sx + side * 2, feet - 35, 4.6, 4.0, P("tile"))
        br.line([(sx + side * 3 - 4, feet - 62), (sx + side * 3 + 4, feet - 62)], shirt_hi)
    hx, hy = bx - 26, feet - 33
    br.poly([(hx - 7, hy), (hx + 3, hy), (hx + 3, hy + 6), (hx - 7, hy + 6)], P("wood"))
    for x in range(hx - 7, hx + 4):
        br.put(x, hy + 7, P("woodLight"))
    # the light from the upper left: the rim of the shoulder, the arm and the head; his far side and the cloth's
    # folds a step darker
    for (px, py), col in list(br.px.items()):
        lit_edge = (px - 1, py) not in br.px or (px, py - 1) not in br.px
        if lit_edge and px < bx + 6:
            br.px[(px, py)] = shirt_hi if col == shirt else (P("tileLight") if col == P("tile") else
                                                             (P("stoneLight") if col == P("stone") else P("wood")))
        elif px > bx + 14 and col == shirt:
            br.px[(px, py)] = shade
        elif px > bx + 14 and col == P("tile"):
            br.px[(px, py)] = P("woodDark")
    for (fx, fy0, fy1) in ((bx - 8, feet - 80, feet - 56), (bx + 6, feet - 78, feet - 54), (bx + 18, feet - 76, feet - 52)):
        for y in range(fy0, fy1):
            if (fx, y) in br.px and br.px[(fx, y)] in (shirt, shade):
                br.px[(fx, y)] = shade
    br.outline(P("night0"), skip_bottom=True)
    br.paste(c)
    return c.finish(S3_ALLOWED, protect=("gold", "fireGold", "mistLight", "foam"))


SLIDES = {
    "slideShut1": slide1,
    "slideShut2": slide2,
    "slideShut3": slide3,
}
