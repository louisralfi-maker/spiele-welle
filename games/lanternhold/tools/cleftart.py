#!/usr/bin/env python3
"""Lanternhold world rebuild, step world-1 (docs/REVIEW-look-2.md 2.3, 2.5, B5, B6, H1, H2, H6): the rock of the
Throat and the cleft. Pure python, palette colours only, no randomness (hashes of the position), so a run reproduces
its files byte for byte. The granite is a height field lit from the upper left and from the sky (tools/rockfield.py):
buttresses with lit west bevels and shaded east ones, chimneys, ledges and overhangs with their cast shadows. One
sprite per run of `build` (each under 15 s on the old Mac).

  cleftart.py build <id> --out <Art dir>
  cleftart.py noslot <weltmauer.png>        the Weltmauer without the far castle in its first slot (in place)
  cleftart.py mistleft <weltmauer.png>      then: the Weltmauer sinks into the fog toward the west (in place)

  throatStepA    224x104, mid plane, ground: the Throat's far wall where it begins, far and pale (the far ramp), low
                 (88 rows at most), its west end a talus that pales into the mist band. mid x 360.
  throatStepB    224x176, mid plane, ground: the second step, a value darker and taller (the slate ramp), with the
                 warden statue's niche. mid x 450.
  throatStepC    224x200, mid plane, top-anchored: the third step, the cleft's own granite: its west end a crag that
                 falls to the lane, then it climbs into the sky behind the gatehouse and goes on, pixel for pixel,
                 as cleftWallA. mid x 600.
  cleftWallA..C  256x200, 256x200, 192x200, mid plane, top-anchored: the cleft's far wall behind the whole castle, at
                 full height with a jagged slit of sky in its top rows: buttresses and chimneys, ledges with snow on
                 the high ones, the slit's cold light on the face's top dithering down into the warm granite, three
                 threads of water with wet streaks and spray; C ends toward the valley in crags that step down to the
                 valley floor. mid x 824, 1080, 1336.
  cleftShaft     64x200 white alpha mask: the cold shaft of light that falls through the slit by day (the engine
                 draws it at the sun's strength). mid x 1104.
  gateRockL      104x80, world plane: the bedrock shoulder the gatehouse's west tower grows out of, highest at the
                 tower's outer edge (world 1249), climbing over its foot in ledges; ashlar set into it. world x 1186.
  gateRockR      60x70, world plane: the same at the east tower's outer edge (world 1470). world x 1440.
  cleftWater     3x132, 4 frames: one thread of falling water, scrolling (fix round 1).

Light from the upper left, as everywhere. All of C and the walls are painted on one canvas in mid-plane x, so their
joins are seamless; the steps are canvases of their own.
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import pixelart as PA  # noqa: E402
import rockfield as RF  # noqa: E402
import worldart as WA  # noqa: E402

h01 = WA.h01
vnoise = WA.vnoise
vnoise2 = WA.vnoise2
CLEAR = (0, 0, 0, 0)
BAYER = [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]


def bay(x, y):
    return (BAYER[((y & 3) << 2) | (x & 3)] + 0.5) / 16


def col(name):
    return WA.col(name)


# ---------------------------------------------------------------------------------------------- the cleft's canvas

CLEFT_X0, CLEFT_X1, CLEFT_H = 600, 1528, 200
PIECES = {"throatStepC": (600, 224), "cleftWallA": (824, 256), "cleftWallB": (1080, 256), "cleftWallC": (1336, 192)}
SLIT_ROWS = 24


# Fix round 1 (the director: "the slit of sky at dusk reads as autumn leaves; give it one clear shape, a wedge of sky
# between two rock edges, wider over the gate, with a cloud or the first star; where the camera shows no slit, close it
# with rock"): the wall stands to the screen's top except in two wedges, over the gatehouse (seen when the camera is on
# the gate) and over the bailey (seen from world 1600 to 2100, where the moon stands in it at night). (centre, half
# width at the top, depth in rows, seed)
WEDGES = [(792, 62, 46, 521), (1010, 38, 50, 523)]


def slit(gx):
    """Rows from the canvas top where the rock begins: 0 where the wall closes the sky; in a wedge a V between two
    rock edges, each a stair of blocks (a few rows high, its own lean), the west edge a little steeper."""
    t = 0.0
    for (c, half, depth, sd) in WEDGES:
        d = gx - c
        if abs(d) >= half:
            continue
        u = 1 - abs(d) / float(half)
        # the edges: a stair of blocks (each 3 to 8 px wide), so the V is cut in rock, not drawn with a ruler
        k = int((gx - c + 400) // (3 + 5 * h01(sd, int((gx - c + 400) // 6))))
        stair = 3.0 * (h01(sd + 1, k) - 0.5)
        shape = u ** (1.25 if d < 0 else 1.0)
        t = max(t, depth * shape + stair * min(1.0, u * 4))
    return max(0.0, t)


def cleft_top(gx):
    """The rock's top (rows from the canvas top) over the whole canvas: the step's west crag, the slit, the end."""
    t = slit(gx)
    if gx < 690:
        # throatStepC's west part: a lower shoulder that climbs into the slit, then a crag that falls to the lane in
        # three ledges.
        u = (690 - gx) / 90.0
        t = t + 34 * min(1.0, u) ** 1.2 + 5 * (vnoise(511, gx / 7.0) - 0.5)
        if gx < 628:
            f = (628 - gx) / 28.0
            drop = 0.0
            for edge_x, depth in ((628, 18), (622, 42), (614, 70), (607, 96)):
                if gx < edge_x:
                    drop = depth
            t += drop + 120 * max(0.0, f - 0.55) ** 1.5 + 3 * h01(513, int(gx))
    if gx > 1340:
        # cleftWallC: the cleft opens to the valley, the wall steps down in crags.
        u = (gx - 1340) / 150.0
        fall = 168 * min(1.0, u) ** 1.25
        fall += 10 * (h01(515, int(gx // 13)) - 0.5) * min(1.0, u * 3) + 6 * abs(math.sin(gx / 5.0)) * min(1.0, u * 2)
        if gx > 1490:
            fall = max(fall, 176 + (gx - 1490) * 0.6)
        t = t + fall
    return t


# the cleft's threads of water: (gx, from row, to row, [(spray row, radius)]); each falls WATER_LEN rows from its
# crack to a ledge, where it lands in spray (fix round 1: the engine draws the falling water as `cleftWater`)
WATER_LEN = 132
WATER = [
    (902, 44, 44 + WATER_LEN, [(44 + WATER_LEN, 5)]),
    (1131, 36, 36 + WATER_LEN, [(36 + WATER_LEN, 6)]),
    (1268, 52, 52 + WATER_LEN, [(52 + WATER_LEN, 5)]),
]
# fix round 1: long ledges across the wall (row, tilt, shelf, undercut, gap seed): a lit top plane and an undershadow
CLEFT_BANDS = [(58, 0.03, 6.0, 2.5, 2), (128, -0.025, 7.0, 3.0, 4)]


def cleft_massif():
    return RF.Massif(601, CLEFT_X0 - 40, CLEFT_X1 + 40, CLEFT_H, 50, 150, relief=1.0, sheets=False,
                     bands=CLEFT_BANDS, facets=0.3, chimneys=0.3, swell=3.0, ledge_gap=(40, 90))


def cleft_piece(name):
    """One piece of the cleft's canvas: the granite height field lit from the upper left and from the slit, the cold
    light of the slit on the face's top, snow on the high ledges, the threads of water with their wet streaks."""
    gx0, w = PIECES[name]
    field = RF.Field(cleft_massif(), gx0, w, CLEFT_H, cleft_top)
    img = RF.paint(field, "cleft", snow_rows=24, snow_share=0.5, cold_rows=90, seed=601, contrast=1.2,
                   wet=[(wt[0], wt[1]) for wt in WATER], caps=True, lit_rim=True, clamp=0.55)
    for wt in WATER:
        if gx0 - 2 <= wt[0] < gx0 + w + 2:
            RF.thread(img, gx0, 601, *wt)
    snow_caps(img, field, gx0)
    return img


def snow_caps(img, field, gx0, rows=96):
    """Fix round 1 (the critic: "no snow"; the director: "few large snow fields that lie on ledges, no patch under 6
    px"): snow lies on the long ledges' shelves high on the wall, in drifts 8 to 30 px long and 2 or 3 rows deep, a
    foam top, mistLight under it and a stoneLight lip where it overhangs; nowhere else on the face."""
    m = cleft_massif()
    foam, light, lip = col("foam"), col("mistLight"), col("stoneLight")
    for (by, tilt, shelf, under, gs) in CLEFT_BANDS:
        for x in range(img.w):
            gx = gx0 + x
            row = m.band_row(by, tilt, gs, gx, field.column(x, int(by)))
            if row > rows or h01(m.seed, gs, int((gx + 37 * gs) // 57)) < 0.45:
                continue
            drift = vnoise(709 + gs, gx / 6.0)
            if drift < 0.6:
                continue
            r0 = int(math.floor(row))
            deep = 2 + (1 if drift > 0.8 else 0)
            for k in range(deep + 1):
                y = r0 - deep + 1 + k
                if 0 <= y < img.h and img.get(x, y)[3] and field.inside(x, y):
                    img.set(x, y, foam if k == 0 else light if k < deep else lip)


# ---------------------------------------------------------------------------------------------- the steps

def step_a():
    """The Throat's first step, far and pale: low crags that pale westward into the mist band."""
    w, h, gx0 = 224, 104, 360

    def hgt(gx):  # rows above the canvas bottom: crags that step down westward into the mist
        u = (gx - gx0) / float(w)
        base = 8 + 80 * min(1.0, (u / 0.66)) ** 0.9
        k = int((gx - gx0) // 9)
        step = 8 * (h01(365, k) - 0.5) * min(1.0, u * 3)
        return min(h - 6, base + step + 5 * (vnoise(363, gx / 6.0) - 0.5) + 4 * abs(math.sin(gx / 3.7)) * min(1.0, u * 2.5))

    field = RF.Field(RF.Massif(361, gx0 - 60, gx0 + w + 60, h, 16, 48, relief=0.55, ledge_gap=(14, 34)), gx0, w, h,
                     lambda gx: h - hgt(min(gx0 + w - 1, max(gx0, gx))))
    return RF.paint(field, "far", snow_rows=30, snow_share=0.6, mist_left=(gx0, gx0 + 92), seed=361, contrast=0.8,
                    lift=0.06)


def step_b():
    """The Throat's second step, a value darker and taller, with the warden statue's niche."""
    w, h, gx0 = 224, 176, 450

    def hgt(gx):
        u = (gx - gx0) / float(w)
        base = 20 + 136 * min(1.0, u / 0.4) ** 0.8
        k = int((gx - gx0 + 5) // 11)
        crag = 9 * (h01(455, k) - 0.5) + 6 * (vnoise(453, gx / 7.0) - 0.5)
        tooth = abs(((gx - gx0 + 5) % 11) / 5.5 - 1.0)
        east = max(0.0, gx - 640) * 1.1  # its east end sinks under throatStepC's top
        return min(h - 1, base + crag + 7 * (1 - tooth) * h01(457, k) * min(1.0, u * 2) - east)

    class Niche(RF.Massif):
        def z(self, gx, y):
            z = RF.Massif.z(self, gx, y)
            # The warden statue's niche (the statue stands at mid 520 to 616, its crown 166 over the ground line).
            dx = abs(gx - 568.0)
            if dx < 40:
                arch = (h - 160) + 26 - math.sqrt(max(0.0, 40 * 40 - dx * dx)) * 0.65
                if y > arch:
                    z -= 10.0 * RF.ss((40 - dx) / 4.0) * RF.ss((y - arch) / 3.0)
            return z

    field = RF.Field(Niche(451, gx0 - 60, gx0 + w + 60, h, 22, 70, relief=0.75, ledge_gap=(16, 44)), gx0, w, h,
                     lambda gx: h - hgt(min(gx0 + w - 1, max(gx0, gx))))
    return RF.paint(field, "slate", snow_rows=44, snow_share=0.65, seed=451, contrast=0.9,
                    lift=0.08)


# ---------------------------------------------------------------------------------------------- the shaft

def shaft():
    """A soft diagonal beam, white with alpha in eight levels and ordered dither between them; it falls from the
    slit toward the lower right (light from the upper left) and fades out before the cleft's floor."""
    w, h = 64, 200
    img = PA.Image(w, h)
    levels = [0, 14, 28, 42, 56, 70, 84, 98, 112, 126, 140, 154]   # fix round 1: stronger, in finer steps
    for y in range(h):
        cx = 14 + y * 0.18
        half = 7 + y * 0.06
        fade = min(1.0, y / 14.0) * (1 - max(0.0, (y - 130) / 70.0))
        for x in range(w):
            d = abs(x + 0.5 - cx) / half
            a = max(0.0, 1 - d) ** 1.4 * fade
            a *= 0.85 + 0.15 * math.sin(y / 9.0 + x / 5.0)
            q = a * (len(levels) - 1) + (bay(x, y) - 0.5)
            k = max(0, min(len(levels) - 1, int(round(q))))
            if levels[k]:
                img.set(x, y, (255, 255, 255, levels[k]))
    # fix round 1: dust motes hanging in the beam, single bright specks inside its core
    for m in range(14):
        y = int(18 + 108 * h01(731, m))
        cx = 14 + y * 0.18
        x = int(cx + (h01(733, m) - 0.5) * (8 + y * 0.06))
        if 0 <= x < w:
            img.set(x, y, (255, 255, 255, 235))
    return img


WATER_W, WATER_FRAMES = 5, 4
WATER_JOGS = (46, 92)   # the rows where a thread strikes a ledge, splashes and goes on a pixel or two aside


def water():
    """cleftWater (fix round 1, the critic: "water threads are dashed lines with no spray"): one thread of falling
    water, 5 x WATER_LEN, four frames that scroll it down 3 px each (the engine plays them at 6 a second, none with
    Reduce Motion). It leaves its crack a pixel wide, widens to two, strikes two ledges on the way (a splash of foam,
    then it goes on a pixel or two aside), runs in broken foam and mist (falling water, not a pole) and frays into
    droplets over its spray."""
    w, h = WATER_W, WATER_LEN
    img = PA.Image(w * WATER_FRAMES, h)
    foam, light, mist = col("foam"), col("mistLight"), col("mist")
    for f in range(WATER_FRAMES):
        for y in range(h):
            yy = y - f * 3
            x = 1 + (1 if y >= WATER_JOGS[0] else 0) + (1 if y >= WATER_JOGS[1] else 0)
            run = h01(741, (yy // 5) % 53)
            if run < 0.18 and 6 < y < h - 12:
                c = None                                       # a gap: the water falls in strands
            else:
                c = foam if run > 0.78 else light if run > 0.42 else mist
            wide = y > 30
            if y > h - 10 and h01(747, f, y) < 0.5:
                c = None                                       # it frays over the spray
            if c:
                img.set(f * w + x, y, c)
                if wide:
                    img.set(f * w + x + 1, y, mist if c == foam else light if c == mist else mist)
            for j in WATER_JOGS:                                # the splash where it strikes a ledge
                if j - 1 <= y <= j + 1:
                    for dx in (-1, 0, 1, 2):
                        xx = x + dx
                        if 0 <= xx < w and h01(749, f, y, dx) < (0.85 if dx in (0, 1) else 0.5):
                            img.set(f * w + xx, y, foam if dx in (0, 1) and y == j else light)
    return img


# ---------------------------------------------------------------------------------------------- the gate's rock

GATE = {
    # w, h, world x of the sprite's left edge, seed, the profile: (world x, rows above the bottom) points the rock's top
    # runs through, west to east; the masonry blocks set into it: (world x, rows above the bottom, width, height).
    # The towers' outer edges stand at world 1249 and 1470 (tier 3: 11 and 12 px further out). Fix round 1 (the
    # critic: "a separate triangle card leaned on a ruler-straight tower edge"): a broad shoulder of bedrock, up to a
    # third of the tower's height, that bulges out past the tower's outer edge and climbs over its foot in ledges, so
    # the tower's line is broken by rock; the tower's lowest courses step down into notches of it.
    "gateRockL": (108, 80, 1186, 1201,
                  [(1186, 2), (1188, 12), (1191, 19), (1194, 23), (1196, 36), (1200, 42), (1204, 46), (1207, 57),
                   (1212, 61), (1218, 63), (1224, 67), (1230, 69), (1236, 71), (1242, 73), (1249, 76), (1253, 74),
                   (1256, 61), (1265, 59), (1267, 47), (1277, 45), (1279, 33), (1289, 31), (1292, 18), (1294, 2)],
                  # the steps over the tower's face (from, to, the step's top): a course of ashlar in each
                  [(1250, 1255, 70), (1257, 1265, 60), (1268, 1277, 46), (1280, 1289, 32)]),
    "gateRockR": (64, 70, 1436, 1467,
                  [(1436, 2), (1438, 16), (1447, 18), (1449, 30), (1457, 32), (1459, 44), (1465, 46), (1467, 58),
                   (1470, 62), (1474, 58), (1478, 50), (1482, 40), (1485, 26), (1488, 18), (1492, 10), (1496, 4),
                   (1499, 1)],
                  [(1439, 1447, 17), (1450, 1457, 31), (1460, 1465, 45)]),
}


def gate_rock(name):
    """The granite the gatehouse's towers grow out of (H2): a broad shoulder of the cleft's bedrock at a tower's outer
    foot, highest at the tower's outer edge, bulging past it and climbing over the tower's foot in ledges; long ledges
    with lit shelves and undershadows, faceted blocks, a continuous lit edge on the faces that look up or west (none on
    the shaded slopes); the tower's lowest ashlar steps down into notches of it."""
    w, h, gx0, seed, prof, blocks = GATE[name]

    def top(gx):
        for (xa, ya), (xb, yb) in zip(prof, prof[1:]):
            if xa <= gx <= xb:
                t = (gx - xa) / float(max(1, xb - xa))
                hg = ya + (yb - ya) * t
                break
        else:
            hg = 0.0
        # the edge in blocks: every few columns a step, never a smooth slope
        hg += 2.0 * (h01(seed, int(gx // 4)) - 0.5)
        return h - max(0.0, hg) if hg > 1 else h + 1

    bands = [(h - 24, 0.05, 4.0, 3.0, 11), (h - 46, -0.04, 4.5, 3.0, 12)]
    massif = RF.Massif(seed, gx0 - 40, gx0 + w + 40, h, 20, 44, relief=0.8, ledge_gap=(12, 22), sheets=False,
                       bands=bands, facets=0.26, chimneys=0.15, swell=2.0)
    field = RF.Field(massif, gx0, w, h, top, margin=24)
    img = RF.paint(field, "footing", rim=0.0, seed=seed, contrast=1.1, lit_rim=True, clamp=0.6)
    # the tower's lowest courses step down into the rock: on each step over the tower's face a course of ashlar,
    # four rows high, its blocks 5 to 9 px long, lit on top and on the west, mortar between them, the rock's lip
    # casting a row of shadow under it
    for (x0w, x1w, step) in blocks:
        top_y = h - step
        x = x0w - gx0
        k = 0
        while x < x1w - gx0:
            bw = 5 + int(5 * h01(seed, k, 91))
            for dx in range(bw):
                xx = x + dx
                if xx >= x1w - gx0 or not (0 <= xx < w):
                    continue
                for dy in range(4):
                    y = top_y + dy
                    if not (0 <= y < h) or not img.get(xx, y)[3]:
                        continue
                    c = "stone"
                    if dy == 0:
                        c = "stoneLight"
                    if dx == 0:
                        c = "stoneLight" if dy < 3 else "stone"
                    if dx == bw - 1 or dy == 3:
                        c = "stoneDark"
                    img.set(xx, y, col(c))
                y = top_y + 4
                if 0 <= y < h and img.get(xx, y)[3]:
                    img.set(xx, y, col("rockDeep"))
            x += bw
            k += 1
    return img


# ---------------------------------------------------------------------------------------------- the Weltmauer

SLOT = (298, 352)  # the first slot's columns in weltmauer.png (the far castle from the shadow land)


def noslot(path):
    """Fills the first slot with the wall beside it: each column takes the column a slot's width to its west, so the
    ridge, the snow and the granite go on; the two columns at each side of the patch are blended by dither."""
    img = PA.read_png(path)[0]
    span = SLOT[1] - SLOT[0]
    out = PA.Image(img.w, img.h, list(img.px))
    for x in range(SLOT[0] - 2, SLOT[1] + 2):
        for y in range(img.h):
            src = img.get(x - span, y)
            if SLOT[0] <= x < SLOT[1] or bay(x, y) < 0.5:
                out.set(x, y, src)
    PA.write_png(path, out)
    print("wrote", path)


MIST_COLS = 320  # the Weltmauer's columns that sink into the fog toward the west (far x -44 ... 276)


def mistleft(path):
    """The Weltmauer sinks into the fog toward the west (REVIEW-look-2.md 2.1, 2.5): over its first MIST_COLS columns a
    bank of mist rises from its foot, slowly at first and steeply near the west end (there it hides the whole wall),
    its top rolling in humps of two sizes. Under the top the rock dissolves into the mist by an ordered dither over
    some 30 rows, so the top is soft and never a line; the mist is darker where it is thin and paler where it is
    dense (low and to the west), in clean patches, never a dither. In place; run once, after `noslot`, on the wall the
    build makes."""
    img = PA.read_png(path)[0]
    out = PA.Image(img.w, img.h, list(img.px))
    light, mist, dark = col("mistLight"), col("mist"), col("mistDark")
    for x in range(min(MIST_COLS, img.w)):
        u = (MIST_COLS - x) / float(MIST_COLS)          # 1 at the west end, 0 where the mist ends
        rise = img.h * 1.1 * RF.ss(u) ** 1.6
        rise += (10 + 26 * u) * vnoise(907, x / 29.0) + (4 + 8 * u) * vnoise(909, x / 8.0) - 6
        top = img.h - rise                                # the mist's top row in this column
        for y in range(img.h):
            p = img.get(x, y)
            if not p[3] or y < top:
                continue
            down = y - top
            share = RF.ss(down / 30.0) * (0.45 + 0.55 * RF.ss(u * 1.8))
            # the mist takes the rock in clean patches (a noise of 5 px clusters, no dither)
            if vnoise2(919, x / 5.0, y / 4.0) >= share:
                continue
            dense = RF.ss(down / 70.0) * (0.5 + 0.5 * u)
            q = dense * 2 + (vnoise2(921, x / 7.0, y / 5.0) - 0.5) * 0.8
            c = dark if q < 0.6 else mist if q < 1.45 else light
            out.set(x, y, (c[0], c[1], c[2], p[3]))
    PA.write_png(path, out)
    print("wrote", path)


def build(name, out):
    if name in PIECES:
        img = cleft_piece(name)
    elif name == "throatStepA":
        img = step_a()
    elif name == "throatStepB":
        img = step_b()
    elif name == "cleftShaft":
        img = shaft()
    elif name in ("gateRockL", "gateRockR"):
        img = gate_rock(name)
    elif name == "cleftWater":
        img = water()
    else:
        raise SystemExit("unknown sprite " + name)
    path = os.path.join(out, name + ".png")
    PA.write_png(path, img)
    print("wrote", path, img.w, "x", img.h)


def main():
    a = sys.argv[1:]
    if len(a) >= 2 and a[0] == "noslot":
        noslot(a[1])
        return
    if len(a) >= 2 and a[0] == "mistleft":
        mistleft(a[1])
        return
    if len(a) >= 4 and a[0] == "build" and a[2] == "--out":
        build(a[1], a[3])
        return
    raise SystemExit(__doc__)


if __name__ == "__main__":
    main()
