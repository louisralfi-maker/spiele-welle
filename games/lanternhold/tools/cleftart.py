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
  cleftWater     14x54, 12 frames: the two threads of falling water, six scrolling frames each (fix round 2).
  cleftGraze     168x96, 3 frames (west end, middle, east end), white alpha mask in three stepped bands: the castle's
                 warm light on the wall's foot (fix round 2; the engine tints it with the fire's colour at the
                 torches' strength, behind the castle's buildings only).

  cleftart.py ridges <weltmauer.png>       fix round 2: the Weltmauer's arêtes and buttress masses (in place, after
                                           `noslot`, before `mistleft`)

Fix round 2 (the critic of world-1, look 2): the cleft wall without bands or ruler lines (lens ledges scattered over
the face, creased facets on a warped, staggered grid with broken, tapering cracks, the slit's cold light on whole
facets), two water threads that fall in an S from a notch over ledges of their own, the wall's end a broken crag ridge,
the gate rocks as shoulders with tongues that climb over the towers' edges, the tor's west side in broken steps.

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
# World-2 (the critic of world-1, look 3: "the jagged slit is a ruler-straight V with a dotted rim, and too wide"): each
# wedge at most 12 % of the screen wide (half width 27) and about a quarter of its height deep; both edges broken crag
# profiles (runs of 2 to 6 px, each falling in its own curve, steep faces and shoulders), a narrow floor where the
# moon stands (its top 34 rows under the screen's top); no lit rim on the wedges' edges (`slit_rim`).
WEDGES = [(792, 27, 40, 521), (1010, 27, 50, 523)]
_WEDGE_CACHE = {}


def wedge_profile(c, half, depth, sd):
    """{canvas x: rows of sky from the top} of one wedge: from each outer edge inward, runs of 2 to 6 px (the critic's
    6 to 20 px of the phone's view), each falling by its own share of the depth in its own curve (u ** p: a steep crag
    face, a rounded shoulder, a ledge), with a broken floor 9 px either side of the centre."""
    key = (c, half, depth, sd)
    if key in _WEDGE_CACHE:
        return _WEDGE_CACHE[key]
    prof = {}
    for side in (-1, 1):
        total = half - 9
        runs, x, k = [], 0, 0
        while x < total:
            w = 2 + int(h01(sd, side + 5, k, 1) * 5)
            if total - x < w + 2:
                w = total - x
            runs.append(w)
            x += w
            k += 1
        weights = [0.08 + h01(sd, side + 5, i, 2) ** 1.6 * 1.8 for i in range(len(runs))]
        weights[0] *= 0.6
        total_w = sum(weights)
        t, x = 0.0, 0
        for i, w in enumerate(runs):
            drop = depth * weights[i] / total_w
            p = 0.35 + h01(sd, side + 5, i, 3) * 2.4
            for j in range(w):
                gx = c + side * (half - (x + j))
                prof[gx] = max(prof.get(gx, 0.0), t + drop * ((j + 1) / float(w)) ** p)
            t += drop
            x += w
        for j in range(x, half + 1):
            gx = c + side * (half - j)
            prof[gx] = max(prof.get(gx, 0.0), depth - 1 + 3.0 * h01(sd, gx // 3, 5))
    _WEDGE_CACHE[key] = prof
    return prof


def slit(gx):
    """Rows from the canvas top where the rock begins: 0 where the wall closes the sky; in a wedge its crag profile."""
    t = 0.0
    for wedge in WEDGES:
        t = max(t, wedge_profile(*wedge).get(int(round(gx)), 0.0))
    return t


def slit_rim(gx, y):
    """World-2: no lit rim on a wedge's edges (the critic: "a 1 px dotted pale line runs down one edge from the moon")."""
    return slit(gx) < 0.5


def cleft_top(gx):
    """The rock's top (rows from the canvas top) over the whole canvas: the step's west crag, the slit, the end."""
    t = slit(gx)
    if gx < 690:
        # throatStepC's west part: fix round 2 (the critic: "the climb, low to full, does not read"): C stands at full
        # height from its west crag on (only a few teeth at the screen's top), then the crag falls to the lane in
        # three ledges, a clear step up from the tor at 70 %.
        t = t + 3 * vnoise(511, gx / 5.0) * min(1.0, (690 - gx) / 30.0)
        if gx < 628:
            f = (628 - gx) / 28.0
            drop = 0.0
            for edge_x, depth in ((628, 18), (622, 42), (614, 70), (607, 96)):
                if gx < edge_x:
                    drop = depth
            t += drop + 120 * max(0.0, f - 0.55) ** 1.5 + 3 * h01(513, int(gx))
    if gx > END_X:
        t = t + end_fall(gx)
    return t


END_X = 1340


def end_points():
    """Fix round 2 (the critic: "the cleft wall ends in a straight diagonal"): where the cleft opens to the valley the
    wall comes down as a broken ridge of crags: a polyline of short runs (4 to 16 px), most of them steep (a crag's
    face), some nearly level (a shoulder), a few rising again (a tooth standing up), small at first and bigger toward
    the valley; scaled so it reaches the canvas's foot at C's east edge (mid 1527), as before. [(mid x, rows down)]"""
    pts, x, y, k = [(float(END_X), 0.0)], float(END_X), 0.0, 0
    while x < CLEFT_X1 + 40:
        dx = 4 + 12 * h01(517, k)
        r = h01(518, k)
        grow = 0.5 + min(1.0, (x - END_X) / 100.0)
        if r < 0.58:
            slope = (1.1 + 2.2 * h01(519, k)) * grow       # a crag's face
        elif r < 0.88:
            slope = (0.08 + 0.4 * h01(519, k)) * grow      # a shoulder
        else:
            slope = -(0.3 + 0.9 * h01(519, k))             # a tooth standing up
            dx = min(dx, 6)
        x += dx
        y = max(0.0, y + slope * dx)
        pts.append((x, y))
        k += 1
    # (it reaches the canvas's foot only at C's east edge: the low crags hide what stands behind the cleft's mouth)
    at = next(ya + (yb - ya) * (1527 - xa) / (xb - xa) for (xa, ya), (xb, yb) in zip(pts, pts[1:]) if xa <= 1527 < xb)
    return [(px, py * 199.0 / at) for (px, py) in pts]


END_POINTS = end_points()


def end_fall(gx):
    for (xa, ya), (xb, yb) in zip(END_POINTS, END_POINTS[1:]):
        if xa <= gx < xb:
            y = ya + (yb - ya) * (gx - xa) / (xb - xa)
            return max(0.0, y + 2.0 * (h01(520, int(gx // 2)) - 0.5) * min(1.0, (gx - END_X) / 20.0))
    return 400.0


# Fix round 2 (the critic: "each water thread is a rigid 1-2 px straight rod of one width, with no source crack and no
# visible spray; where it crosses a snow ledge it forms a cross ... a street lamp or telegraph pole"): two threads, far
# apart, high on the wall. Each springs from a dark notch with a wet stain, falls in a slight S over two or three short
# ledges of its own (it strikes each in a puff of spray and comes on from under the ledge's lip a pixel or two aside),
# and ends in spray on the last one, over the castle's roofs; the bands of ledges break where it falls, so it never
# crosses one. (notch x, notch row, legs: (rows it falls, pixels it drifts by the landing))
THREADS = [
    (893, 26, [(15, 3), (16, -4), (13, 2)]),
    (1258, 30, [(13, -3), (17, 4), (12, -2)]),
]


def thread_path(spec):
    """The thread's rows: [(row, x, leg, rows since the leg began, rows to its landing)] from under the notch to the
    last landing, and the landings [(x, row)]. Each leg leaves its lip and drifts by its pixels in an eased curve, so
    the legs together fall in an S; after a landing the water comes on from under the ledge's lip, 3 rows down."""
    nx, nr, legs = spec
    pts, lands = [], []
    x, y = float(nx), nr + 1
    for i, (fall, dx) in enumerate(legs):
        y0 = y
        y1 = nr + 1 + sum(f for f, _ in legs[:i + 1]) + 3 * i
        for yy in range(y0, y1):
            u = (yy - y0) / float(max(1, y1 - y0 - 1))
            pts.append((yy, int(round(x + dx * RF.ss(u))), i, yy - y0, y1 - 1 - yy))
        x += dx
        lands.append((int(round(x)), y1))
        y = y1 + 3
    return pts, lands


def thread_cuts():
    """Where the bands break for the water: its columns, from its notch to its last landing."""
    out = []
    for spec in THREADS:
        pts, lands = thread_path(spec)
        xs = [p[1] for p in pts] + [l[0] for l in lands]
        out.append((min(xs) - 5, max(xs) + 6, spec[1] - 6, lands[-1][1] + 6))
    return out


def thread_spots():
    """The short ledges the water lands on: (x from, x to, row, shelf, under); the last one a little broader."""
    out = []
    for spec in THREADS:
        lands = thread_path(spec)[1]
        for i, (lx, ly) in enumerate(lands):
            last = i == len(lands) - 1
            out.append((lx - (5 if last else 4), lx + (7 if last else 5), ly, 5.0 if last else 4.0, 3.5))
    return out


# fix round 2: three bands of short ledges (row, tilt, shelf, undercut, seed): each broken into ledges 16 to 40 px long
# that step 3 to 7 rows from one to the next, with gaps and crumbling lips (rockfield `pieces`); none crosses the water
CLEFT_BANDS = []


def pods():
    """Fix round 2 (the critic: "two ruler-straight bands from edge to edge"): no bands; short ledges scattered over
    the face instead, each a lens 8 to 26 px long with a lean of its own (up to 1 in 4), denser high on the wall where
    the snow lies (rows 24 to 80) and sparse below, so the granite has shelves everywhere and no line across it; none
    in the water's columns. (x from, x to, row, shelf, undercut, lean)"""
    out = []
    cuts = thread_cuts()
    for cx in range(CLEFT_X0 - 20, CLEFT_X1 + 20, 26):
        for cy in range(18, 176, 20):
            share = 0.24 if cy < 80 else 0.08
            if h01(621, cx, cy) > share:
                continue
            x0 = cx + 24 * h01(623, cx, cy)
            row = cy + 18 * h01(625, cx, cy)
            length = 8 + 18 * h01(627, cx, cy) ** 1.2
            if any(lo - 8 <= x0 + length and x0 <= hi + 8 and y0 - 6 <= row <= y1 + 6 for (lo, hi, y0, y1) in cuts):
                continue
            out.append((x0, x0 + length, row, 2.4 + 1.4 * h01(629, cx, cy), 0.5 + 0.5 * h01(631, cx, cy),
                        (h01(633, cx, cy) - 0.5) * 0.5))
    return out


def cleft_gain(gx):
    """Fix round 2 (the critic: "step B is lighter than A at noon"): the cleft's granite in the Throat a value darker
    than the tor beside it (the darkest of the three steps), back to its own value behind the castle from mid 820."""
    return 0.8 + 0.2 * RF.ss((gx - 700) / 120.0)


def cleft_massif():
    return RF.Massif(601, CLEFT_X0 - 40, CLEFT_X1 + 40, CLEFT_H, 50, 150, relief=1.0, sheets=False,
                     bands=CLEFT_BANDS, facets=0.3, chimneys=0.3, swell=3.0, ledge_gap=(40, 90), pieces=True,
                     crease=True, spots=thread_spots() + pods(), cuts=thread_cuts(), ledge_max=30, face_relief=2.6,
                     cracks=0.5)


def cleft_piece(name):
    """One piece of the cleft's canvas: the granite height field lit from the upper left and from the slit, the cold
    light of the slit on whole facets high on the face, snow on some of the high ledges, the water's beds."""
    gx0, w = PIECES[name]
    field = RF.Field(cleft_massif(), gx0, w, CLEFT_H, cleft_top)
    img = RF.paint(field, "cleft", snow_rows=24, snow_share=0.5, cold_rows=90, seed=601, contrast=1.2,
                   caps=True, lit_rim=True, clamp=0.55, rim_broken=True, gain_at=cleft_gain, rim_at=slit_rim)
    snow_caps(img, field, gx0)
    for spec in THREADS:
        if gx0 - 12 <= spec[0] < gx0 + w + 12:
            water_bed(img, field, gx0, spec)
    return img


def darker():
    """Each colour of the cleft's ramps to the one a step darker (for wet rock)."""
    out = {}
    for name in ("cleft",):
        for ramp in (RF.RAMPS[name], RF.COLD[name]):
            cols = [col(n) for n in ramp]
            for i in range(1, len(cols)):
                out.setdefault(cols[i], cols[i - 1])
    return out


def water_bed(img, field, gx0, spec):
    """The rock under a thread (fix round 2): the notch it springs from (a dark mouth with a lit lip over it) and a wet
    stain under it, its bed a step darker than the rock (it shows between the strands of falling water), and on each
    landing a puff of spray in three steps, the outer one dithered into the rock."""
    dk = darker()
    deep, lip = col("nightBlue"), col("rockLight")
    light, mist = col("mistLight"), col("mist")
    nx, nr, legs = spec
    pts, lands = thread_path(spec)

    def put(x, y, c):
        xx = x - gx0
        if 0 <= xx < img.w and 0 <= y < img.h and img.get(xx, y)[3] and field.inside(xx, y):
            img.set(xx, y, c)

    def wet(x, y):
        xx = x - gx0
        if 0 <= xx < img.w and 0 <= y < img.h and img.get(xx, y)[3]:
            p = img.get(xx, y)
            img.set(xx, y, dk.get(p, p))

    # the wet stain under the notch: four rows, narrowing
    for dy in range(1, 6):
        half = 3 - dy // 2
        for dx in range(-half, half + 2):
            if h01(613, nx, dy, dx) < 0.85:
                wet(nx + dx, nr + dy)
    for (y, x, leg, since, left) in pts:
        wet(x, y)
        if leg:
            wet(x + 1, y)
    # the notch: a dark mouth two rows deep, three or four wide, its lip lit above it
    for dx in range(-1, 3):
        put(nx + dx, nr, deep)
        if dx < 2:
            put(nx + dx, nr - 1, deep)
        put(nx + dx, nr - 2, lip)
    # the spray on each landing: a small pale core where the water strikes, mist round it, and a ring of mist
    # dithered into the rock, flatter than tall and leaning the way the water came from
    for i, (lx, ly) in enumerate(lands):
        last = i == len(lands) - 1
        rx = 3.4 if last else 2.0
        ry = 1.7 if last else 1.2
        for dy in range(-3, 2):
            for dx in range(-6, 7):
                d = math.sqrt((dx / rx) ** 2 + ((dy + 0.6) / ry) ** 2)
                if d < 0.36 and dy <= 0 and last:
                    put(lx + dx, ly + dy, light)
                elif d < 0.7:
                    put(lx + dx, ly + dy, mist)
                elif d < 1.15 and bay(lx + dx, ly + dy) < 0.4:
                    put(lx + dx, ly + dy, mist)


def snow_caps(img, field, gx0, rows=84):
    """Snow on some of the high ledges (fix round 2, the critic: "snow lumps at even spacing"): on about half of the
    pods above `rows`, a drift of its own length (3 to 14 px, never the whole pod) somewhere along it, mounded
    (deepest in its middle, one to three rows), a foam top, mistLight under it and a stoneLight lip; none near the
    water."""
    foam, light, lipc = col("foam"), col("mistLight"), col("stoneLight")
    for (xs, xe, row, shelf, under, lean) in pods():
        key = int(xs * 7 + row)
        if row > rows or xe < gx0 - 2 or xs > gx0 + img.w + 2 or h01(707, key) < 0.5:
            continue
        length = min(int(xe - xs) - 2, 3 + int(11 * h01(709, key) ** 1.4))
        if length < 3:
            continue
        x0 = xs + 1 + (xe - xs - 2 - length) * h01(711, key)
        deep = 1 + int(2.6 * h01(713, key) * min(1.0, length / 8.0))
        for i in range(length):
            gx = int(x0) + i
            u = (i + 0.5) / length
            dcol = max(1, int(round(deep * math.sin(math.pi * u) + 0.3)))
            r0 = int(math.floor(row + lean * (gx - xs)))
            x = gx - gx0
            for kk in range(dcol + 1):
                y = r0 - dcol + 1 + kk
                if 0 <= x < img.w and 0 <= y < img.h and img.get(x, y)[3] and field.inside(x, y):
                    img.set(x, y, foam if kk == 0 else light if kk < dcol else lipc)


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
    """The Throat's second step, the tor: a value darker than A and taller, with the warden statue's niche. Fix round
    2 (the critic: "step A's edge is one straight diagonal with a one-pixel rim; the climb does not read"): its west
    side climbs in broken crag steps (a steep face, a ledge, a tooth) to a shoulder at 70 % of the screen (104 rows
    over the ground line); only behind the statue does the rock rise to hold its niche (the statue's stepped backing
    must stand in rock), so the climb reads A low, the tor's shoulder at 70 %, C at full height and darkest."""
    w, h, gx0 = 224, 176, 450
    pts = [(450, 12), (452, 18), (455, 17), (457, 30), (463, 37), (466, 36), (468, 52), (471, 54), (478, 58),
           (480, 65), (483, 64), (486, 80), (489, 83), (494, 85), (496, 92), (499, 91), (501, 103),
           (509, 107), (521, 108), (524, 122), (527, 121), (530, 138), (533, 137),
           (536, 152), (598, 152), (603, 136), (608, 134), (612, 116), (620, 108), (900, 108)]

    def hgt(gx):
        for (xa, ya), (xb, yb) in zip(pts, pts[1:]):
            if xa <= gx < xb:
                base = ya + (yb - ya) * (gx - xa) / float(xb - xa)
                break
        else:
            base = pts[-1][1]
        k = int((gx - gx0 + 5) // 7)
        teeth = 3.0 * (h01(455, k) - 0.5) + 2.0 * (vnoise(453, gx / 5.0) - 0.5)
        east = max(0.0, gx - 640) * 1.1  # its east end sinks under throatStepC's top
        return min(h - 1, base + teeth - east)

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
    return RF.paint(field, "slate", snow_rows=84, snow_share=0.65, seed=451, contrast=0.9,
                    lift=0.08, rim=0.0, lit_rim=True, rim_broken=True)


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


# fix round 2: the falling water, one shape per thread (frames 0-5 the first, 6-11 the second), WATER_OX columns of
# room west of the notch; the strands scroll 3 rows a frame over a pattern 18 rows long, so six frames loop
WATER_W, WATER_FRAMES, WATER_OX, WATER_PERIOD = 14, 6, 5, 18


def water_rows():
    """The sprite's height: from the row under the highest notch's to the lowest spray's."""
    return max(thread_path(sp)[1][-1][1] - sp[1] + 3 for sp in THREADS)


def water():
    """cleftWater (fix round 2): each thread's falling water in its S, for its own path. At 60 to 70 % of the old
    white (mist, a mistLight head on each strand, mistDark on its shade side), a pixel wide under the notch and two
    below the first landing, broken into strands of four or five rows with gaps of one or two, fanning to three just
    before it strikes a ledge, a few droplets of spray leaping over each landing. Six frames at 6 a second, still
    with Reduce Motion (frame 0)."""
    h = water_rows()
    w = WATER_W
    img = PA.Image(w * WATER_FRAMES * len(THREADS), h)
    core, head, side = col("mist"), col("mistLight"), col("mistDark")
    for s_i, spec in enumerate(THREADS):
        nx, nr, legs = spec
        pts, lands = thread_path(spec)
        for f in range(WATER_FRAMES):
            ox = (s_i * WATER_FRAMES + f) * w

            def put(x, y, c):
                xx = x - nx + WATER_OX
                yy = y - nr - 1
                if 0 <= xx < w and 0 <= yy < h:
                    img.set(ox + xx, yy, c)

            for (y, x, leg, since, left) in pts:
                q = (y - 3 * f) % WATER_PERIOD
                strand = (y - 3 * f) // 9
                pos = q % 9
                gap_from = 8 if h01(741, s_i, leg, strand % 2) < 0.5 else 7
                if since > 1 and pos >= gap_from:
                    continue                                   # a gap between strands
                c = head if pos == 0 else core
                put(x, y, c)
                if (leg or since > 6) and pos < gap_from - 1:
                    put(x + 1, y, side)
                if left <= 1:
                    put(x - 1, y, side)                        # it fans as it strikes the ledge
            for i, (lx, ly) in enumerate(lands):
                for d in range(4 if i == len(lands) - 1 else 2):
                    if h01(747, s_i, f, i, d) < 0.6:
                        dx = int(round((h01(749, s_i, f, i, d) - 0.5) * 9))
                        dy = -1 - int(3 * h01(751, s_i, f, i, d))
                        put(lx + dx, ly + dy, head if h01(753, s_i, f, i, d) < 0.4 else core)
    return img


GRAZE_W, GRAZE_H, GRAZE_FRAMES = 168, 96, 3


def graze():
    """cleftGraze (fix round 2, the critic: "the promised warm graze from the castle at the wall's foot does not
    show"): the castle's warm light on the cleft wall's foot, a white alpha mask in three steps (the engine tints it
    with the fire's colour at the torches' strength behind the castle's buildings, so it shows in the gaps between
    them and as a warm rim on the rock over the roofs): strongest up to about 72 rows, a second step to about 84, a
    faint third to about 94; each step's top a jagged line (rows up or down every 3 to 7 px and a slow wander), never
    a ruler. Three frames laid side by side behind the castle: 0 the west end, 1 the middle, 2 the east end; the ends
    fade out in the same steps over 56 px, so the warmth never stops at a column."""
    w, h = GRAZE_W, GRAZE_H
    img = PA.Image(w * GRAZE_FRAMES, h)
    steps = [(72, 120), (84, 76), (94, 38)]   # (rows above the bottom, alpha)

    def edge(gx, i, base):
        seg = int((gx + 13 * i) // (3 + 4 * h01(941, i, int((gx + 13 * i) // 7))))
        return base + int(round(6 * (h01(943, i, seg) - 0.5) + 10 * (vnoise(945 + i, gx / 29.0) - 0.5)))

    for f in range(GRAZE_FRAMES):
        for x in range(w):
            gx = f * w + x                     # the three frames are one strip
            # the ends: a step down every 18 px or so, its place wandering by the row
            end = 1.0
            if f == 0:
                end = min(1.0, x / 56.0)
            elif f == GRAZE_FRAMES - 1:
                end = min(1.0, (w - 1 - x) / 56.0)
            tops = [edge(gx, i, b) for i, (b, a) in enumerate(steps)]
            for y in range(h):
                up = h - 1 - y
                a = 0
                for k, (t, (b, al)) in enumerate(zip(tops, steps)):
                    if up < t:
                        a = max(a, al)
                if a and end < 1.0:
                    q = int(end * 3 + h01(947, gx, up // 5) * 0.99)   # 0 ... 3 steps in
                    a = int(a * min(1.0, q / 3.0))
                if a:
                    img.set(f * w + x, y, (255, 255, 255, a))
    return img


# ---------------------------------------------------------------------------------------------- the gate's rock

GATE = {
    # w, h, world x of the sprite's left edge, seed, the profile: (world x, rows above the bottom) points the rock's top
    # runs through, west to east; the courses of ashlar set onto its ledges: (world x from, to, rows above the bottom).
    # The towers' shafts stand from world 1249 (west tower's outer edge) and to 1470 (east tower's). Fix round 2 (the
    # critic: "a continuous pale outline stroke and a ruler-straight stick line; on the right a lone triangle spire;
    # the towers' outer edges stay ruler-straight from top to foot"): a broad shoulder of bedrock out of the cleft's
    # floor, then three tongues of rock that climb over the tower's outer edge, the highest to about half the shaft's
    # height (76 rows), with notches between them where a course of the tower's ashlar sits on a ledge, so the tower
    # grows out of the rock; the east rock is the same shoulder mirrored, low toward the bailey.
    "gateRockL": (108, 80, 1186, 1201,
                  [(1186, 2), (1189, 9), (1193, 14), (1197, 22), (1201, 25), (1205, 33), (1210, 37), (1215, 44),
                   (1220, 47), (1226, 55), (1231, 58), (1236, 64), (1240, 66), (1243, 73), (1246, 76), (1249, 77),
                   (1252, 74), (1254, 63), (1257, 61), (1259, 56), (1261, 59), (1264, 57), (1266, 44), (1269, 42),
                   (1272, 45), (1275, 43), (1277, 31), (1281, 29), (1285, 20), (1289, 13), (1292, 6), (1294, 1)],
                  [(1255, 1260, 57), (1266, 1271, 40), (1278, 1284, 27)]),
    "gateRockR": (64, 70, 1436, 1467,
                  [(1436, 1), (1441, 4), (1446, 6), (1449, 13), (1453, 15), (1456, 14), (1458, 22), (1462, 25),
                   (1465, 24), (1467, 36), (1470, 44), (1474, 45), (1477, 41), (1481, 42), (1485, 39), (1488, 36),
                   (1491, 31), (1494, 24), (1496, 16), (1498, 8), (1499, 2)],
                  [(1449, 1453, 11), (1458, 1462, 20)]),
}


def gate_rock(name):
    """The granite the gatehouse's towers grow out of (H2): a broad shoulder of the cleft's bedrock at a tower's outer
    foot, then three tongues climbing over the tower's edge, the highest to half the shaft; creased faces, a few
    lens ledges, the light on the edges toward it in broken pieces (no outline); on each notch's ledge a course of
    the tower's ashlar sits on the rock."""
    w, h, gx0, seed, prof, blocks = GATE[name]

    def top(gx):
        for (xa, ya), (xb, yb) in zip(prof, prof[1:]):
            if xa <= gx <= xb:
                t = (gx - xa) / float(max(1, xb - xa))
                hg = ya + (yb - ya) * t
                break
        else:
            hg = 0.0
        # the edge broken: a pixel up or down every few columns, never a smooth slope
        hg += 1.6 * (h01(seed, int(gx // 3)) - 0.5)
        return h - max(0.0, hg) if hg > 1 else h + 1

    spots = []
    for i in range(7):
        x0 = gx0 + 6 + (w - 20) * h01(seed, i, 301)
        row = h - 10 - 50 * h01(seed, i, 302)
        spots.append((x0, x0 + 6 + 9 * h01(seed, i, 303), row, 2.6, 1.6, (h01(seed, i, 304) - 0.5) * 0.4))
    massif = RF.Massif(seed, gx0 - 40, gx0 + w + 40, h, 18, 40, relief=0.8, ledge_gap=(12, 22), sheets=False,
                       facets=0.3, chimneys=0.2, swell=2.0, pieces=True, crease=True, spots=spots, ledge_max=12,
                       face_relief=2.0, cracks=0.45)
    field = RF.Field(massif, gx0, w, h, top, margin=24)
    img = RF.paint(field, "footing", rim=0.0, seed=seed, contrast=1.1, lit_rim=True, clamp=0.6, rim_broken=True)
    # a course of the tower's ashlar on each notch's ledge: blocks 4 to 7 px long, three rows high, lit on top and on
    # the west, mortar between them, the rock's lip throwing a row of shadow under them
    for (x0w, x1w, step) in blocks:
        top_y = h - step - 3
        x = x0w - gx0
        k = 0
        while x < x1w - gx0:
            bw = 4 + int(4 * h01(seed, k, 91, x0w))
            for dx in range(bw):
                xx = x + dx
                if xx >= x1w - gx0 or not (0 <= xx < w):
                    continue
                for dy in range(3):
                    y = top_y + dy
                    if not (0 <= y < h):
                        continue
                    c = "stone"
                    if dy == 0 or dx == 0:
                        c = "stoneLight"
                    if dx == bw - 1 or dy == 2:
                        c = "stoneDark"
                    img.set(xx, y, col(c))
                y = top_y + 3
                if 0 <= y < h and img.get(xx, y)[3]:
                    img.set(xx, y, col("rockDeep"))
            x += bw
            k += 1
    return img


# ---------------------------------------------------------------------------------------------- the Weltmauer

SLOT = (298, 352)  # the first slot's columns in weltmauer.png (the far castle from the shadow land)


def noslot(path):
    """Fills the first slot with the wall beside it: each column takes the column a slot's width to its west, so the
    ridge, the snow and the granite go on. Fix round 2 (the critic: "a dotted one-pixel column runs down the face like a
    seam"): the patch's two edges wander a few pixels from row to row (no dithered blend columns), so no column of
    dots marks it."""
    img = PA.read_png(path)[0]
    span = SLOT[1] - SLOT[0]
    out = PA.Image(img.w, img.h, list(img.px))
    for y in range(img.h):
        lo = SLOT[0] + int(round(6 * (vnoise(931, y / 7.0) - 0.5)))
        hi = SLOT[1] + int(round(6 * (vnoise(933, y / 7.0) - 0.5)))
        for x in range(lo, hi):
            out.set(x, y, img.get(x - span, y))
    PA.write_png(path, out)
    print("wrote", path)


SLOT2 = (626, 676)  # world-2: the second slot's columns (the far castle seen from the valley; the patch covered them)


def noslot2(path):
    """World-2 (B2: one castle): fills the second slot as `noslot` fills the first, so the valley sees the Weltmauer
    whole and no far castle; the patch, the pane and the slot's glow are gone with it."""
    img = PA.read_png(path)[0]
    span = SLOT2[1] - SLOT2[0]
    out = PA.Image(img.w, img.h, list(img.px))
    for y in range(img.h):
        lo = SLOT2[0] + int(round(6 * (vnoise(941, y / 7.0) - 0.5)))
        hi = SLOT2[1] + int(round(6 * (vnoise(943, y / 7.0) - 0.5)))
        for x in range(lo, hi):
            out.set(x, y, img.get(x - span, y))
    PA.write_png(path, out)
    print("wrote", path)


# Fix round 2 (the critic: "the Weltmauer reads as a grey curtain of vertical streaks with no mass or ridgelines"):
# the arêtes that come down from the summits, (far x at the snow line, lean in px per row: + leans east going down)
def aretes():
    """(far x at the snow line, lean in px per row), 50 to 105 px apart, leaning 0.12 to 0.55 either way (mostly
    away from the last one, not always), so the buttresses never repeat as a zigzag."""
    out, x, k, sign = [], 30.0, 0, 1
    while x < 920:
        if h01(941, k) < 0.72:
            sign = -sign
        out.append((int(x), sign * (0.12 + 0.43 * h01(943, k))))
        x += 50 + 55 * h01(945, k)
        k += 1
    return out


ARETES = aretes()


def clean_peaks(img):
    """Fix round 2 (the critic: "the peak strip is torn white with blue bubble sky"): the Weltmauer's skyline as clean
    peaks: between two summits (the highest points 14 px either side) the sky's gap is a V of two straight edges down
    to the gap's lowest point; rock above the V is cut away, sky below it filled with the pixel under it."""
    w, h = img.w, img.h
    out = PA.Image(w, h, list(img.px))
    tops = [next((y for y in range(h) if img.get(x, y)[3]), h) for x in range(w)]
    peaks = [x for x in range(w) if tops[x] < h and tops[x] == min(tops[max(0, x - 14):x + 15])
             and (not 0 < x < w - 1 or tops[x - 1] >= tops[x])]
    # one summit per flat top
    peaks = [x for i, x in enumerate(peaks) if i == 0 or x - peaks[i - 1] > 3]
    for a, b in zip(peaks, peaks[1:]):
        if b - a < 6:
            continue
        g = max(range(a, b + 1), key=lambda x: tops[x])
        for x in range(a + 1, b):
            if x <= g:
                t = tops[a] + (tops[g] - tops[a]) * (x - a) / float(max(1, g - a))
            else:
                t = tops[g] + (tops[b] - tops[g]) * (x - g) / float(max(1, b - g))
            t = int(round(t))
            for y in range(h):
                p = img.get(x, y)
                if y < t and p[3]:
                    out.set(x, y, (0, 0, 0, 0))
                elif y >= t and not p[3] and y < tops[x]:
                    out.set(x, y, img.get(x, tops[x]))
    return out


def ridges(path):
    """The Weltmauer's masses: under the snow, the painting's fine vertical streaks are smoothed across (a 7 x 3
    average of its granite steps), then the wall is cut into buttresses by arêtes that run down from the summits at a
    slant (every second one leaning the other way): the flank west of each arête takes the light (a step lighter),
    the flank east of it the shade (a step darker), a gully between two buttresses a step darker still, so each
    arête is a crisp diagonal ridgeline where light meets shade. Clean clusters (no lone pixels). In place, after
    `noslot`, before `mistleft`."""
    img = PA.read_png(path)[0]
    ramp = [col(n) for n in ("rockDeep", "rockDark", "rock", "rockLight", "rockPale")]
    index = {c: i for i, c in enumerate(ramp)}
    w, h = img.w, img.h
    img = clean_peaks(img)
    tops = [next((y for y in range(h) if img.get(x, y)[3]), h) for x in range(w)]
    src = [[index.get(img.get(x, y)) for x in range(w)] for y in range(h)]
    out = PA.Image(w, h, list(img.px))

    def ridge_x(i, y):
        x0, lean = ARETES[i]
        y0 = tops[max(0, min(w - 1, x0))] + 10
        return x0 + lean * (y - y0) + 3.0 * (vnoise(951 + i, y / 13.0) - 0.5) + 1.2 * (vnoise(971 + i, y / 4.0) - 0.5)

    idx = [[None] * w for _ in range(h)]
    for y in range(h):
        xs = [ridge_x(i, y) for i in range(len(ARETES))]
        for x in range(w):
            if src[y][x] is None:
                continue
            acc, n = 0.0, 0
            for dy in (-2, -1, 0, 1, 2):
                for dx in range(-5, 6):
                    yy, xx = y + dy, x + dx
                    if 0 <= yy < h and 0 <= xx < w and src[yy][xx] is not None:
                        acc += src[yy][xx]
                        n += 1
            v = acc / n
            # which buttress: between arête i (west) and i + 1 (east)
            i = max([k for k in range(len(xs)) if xs[k] <= x] or [-1])
            shift = 0.0
            if 0 <= i < len(xs) - 1:
                a, b = xs[i], xs[i + 1]
                u = (x - a) / max(1.0, b - a)
                gully = 0.5 + 0.12 * (h01(961, i) - 0.5)
                if u < 0.24:
                    shift = -1.3                      # the arête's east flank, in its shade
                elif u > 0.68:
                    shift = 1.3                       # the next arête's west flank, in the light
                elif abs(u - gully) < 0.05:
                    shift = -1.6                      # the gully between them
            under = y - tops[x]
            fade = RF.ss((under - 6) / 18.0)          # the masses come out under the snow caps
            idx[y][x] = max(0, min(4, int(round(v + shift * fade))))
    # clean clusters
    for _ in range(2):
        ch = []
        for y in range(h):
            for x in range(w):
                c = idx[y][x]
                if c is None:
                    continue
                around = [idx[yy][xx] for (xx, yy) in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1))
                          if 0 <= xx < w and 0 <= yy < h and idx[yy][xx] is not None]
                if len(around) >= 3 and c not in around:
                    best = max(set(around), key=around.count)
                    if around.count(best) >= 2:
                        ch.append((x, y, best))
        for (x, y, c) in ch:
            idx[y][x] = c
    for y in range(h):
        for x in range(w):
            if idx[y][x] is not None:
                p = img.get(x, y)
                c = ramp[idx[y][x]]
                out.set(x, y, (c[0], c[1], c[2], p[3]))
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
    elif name == "cleftGraze":
        img = graze()
    else:
        raise SystemExit("unknown sprite " + name)
    path = os.path.join(out, name + ".png")
    PA.write_png(path, img)
    print("wrote", path, img.w, "x", img.h)


def main():
    a = sys.argv[1:]
    if len(a) >= 2 and a[0] == "noslot2":
        noslot2(a[1])
        return
    if len(a) >= 2 and a[0] == "noslot":
        noslot(a[1])
        return
    if len(a) >= 2 and a[0] == "ridges":
        ridges(a[1])
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
