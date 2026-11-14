#!/usr/bin/env python3
"""Lanternhold world rebuild, step world-1 (docs/REVIEW-look-2.md 2.3, 2.5, B5, B6, H1, H2, H6): the rock of the
Throat and the cleft. Pure python, palette colours only, no randomness (hashes of the position), so a run reproduces
its files byte for byte. The granite is a height field lit from the upper left and from the sky (tools/rockfield.py):
buttresses with lit west bevels and shaded east ones, chimneys, ledges and overhangs with their cast shadows. One
sprite per run of `build` (each under 15 s on the old Mac).

  cleftart.py build <id> --out <Art dir>
  cleftart.py noslot <weltmauer.png>        the Weltmauer without the far castle in its first slot (in place)

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
  gateRockL      72x60, world plane: the granite plinth the gatehouse's west tower grows out of, highest at the
                 tower's outer edge (world 1249), falling under the tower in a ragged stair. world x 1200.
  gateRockR      56x50, world plane: the same at the east tower's outer edge (world 1470). world x 1446.

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


def slit(gx):
    """Rows from the canvas top where the rock begins along the slit: a jagged edge of teeth of every size, notches
    between them, and here and there a chockstone that bridges the slit up to the top row."""
    base = 8 + 10 * vnoise(501, gx / 31.0) + 5 * vnoise(503, gx / 9.0)
    # teeth: a walk of irregular widths, each tooth its own height and lean
    k, x0 = 0, -40.0
    while True:
        wdt = 4 + 13 * h01(505, k)
        if x0 + wdt > gx:
            break
        x0 += wdt
        k += 1
    u = (gx - x0) / wdt
    lean = 0.25 + 0.5 * h01(506, k)
    shape = u / lean if u < lean else (1 - u) / (1 - lean)
    tip = base - (3 + 9 * h01(507, k))
    t = base - (base - tip) * shape ** 0.7
    b = int((gx + 13) // 53)
    if h01(508, b) < 0.25:
        v = ((gx + 13) % 53) / 53.0
        if 0.35 < v < 0.5 + 0.18 * h01(509, b):
            t = min(t, 1 + 2 * abs(math.sin(gx * 0.7)))  # a chockstone wedged across the slit
    return max(0.0, min(SLIT_ROWS, t))


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


WATER = [  # the cleft's threads of water: (gx, from row, to row, [(spray row, radius)])
    (902, 52, 186, [(118, 3), (176, 5)]),
    (1131, 38, 190, [(96, 3), (150, 4), (182, 6)]),
    (1268, 64, 186, [(132, 4), (178, 5)]),
]


def cleft_massif():
    return RF.Massif(601, CLEFT_X0 - 40, CLEFT_X1 + 40, CLEFT_H, 30, 120, relief=1.0, sheets=False)


def cleft_piece(name):
    """One piece of the cleft's canvas: the granite height field lit from the upper left and from the slit, the cold
    light of the slit on the face's top, snow on the high ledges, the threads of water with their wet streaks."""
    gx0, w = PIECES[name]
    field = RF.Field(cleft_massif(), gx0, w, CLEFT_H, cleft_top)
    img = RF.paint(field, "cleft", snow_rows=70, snow_share=0.75, cold_rows=90, seed=601,
                   wet=[(wt[0], wt[1]) for wt in WATER])
    for wt in WATER:
        if gx0 - 2 <= wt[0] < gx0 + w + 2:
            RF.thread(img, gx0, 601, *wt)
    return img


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
                    lift=0.02)


# ---------------------------------------------------------------------------------------------- the shaft

def shaft():
    """A soft diagonal beam, white with alpha in eight levels and ordered dither between them; it falls from the
    slit toward the lower right (light from the upper left) and fades out before the cleft's floor."""
    w, h = 64, 200
    img = PA.Image(w, h)
    levels = [0, 18, 36, 54, 72, 90, 108, 126]
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
    return img


# ---------------------------------------------------------------------------------------------- the gate's rock

GATE = {
    # w, h, world x of the sprite's left edge, seed, the profile: (world x, rows above the bottom) points the rock's top
    # runs through, west to east. The towers' outer edges stand at world 1249 and 1470 (tier 3: 14 px further out).
    "gateRockL": (72, 60, 1200, 1201, [(1200, 2), (1203, 7), (1206, 10), (1211, 14), (1216, 22), (1221, 25),
                                        (1226, 33), (1232, 36), (1238, 43), (1244, 50), (1249, 55), (1253, 47),
                                        (1257, 41), (1260, 31), (1264, 27), (1267, 17), (1270, 10), (1272, 3)]),
    "gateRockR": (56, 50, 1446, 1467, [(1446, 2), (1448, 7), (1452, 15), (1456, 25), (1460, 30), (1464, 37),
                                        (1468, 44), (1470, 47), (1474, 41), (1479, 33), (1484, 30), (1489, 20),
                                        (1494, 13), (1499, 6), (1502, 2)]),
}


def gate_rock(name):
    """The granite the gatehouse's towers grow out of (H2): a broad plinth of the cleft's rock at a tower's outer foot,
    highest right at the tower's outer edge (the masonry climbs out of it), falling under the tower in a ragged stair
    and down to the lane outside in blocks; lit from the upper left, its top edges rimmed with cold light."""
    w, h, gx0, seed, prof = GATE[name]

    def top(gx):
        for (xa, ya), (xb, yb) in zip(prof, prof[1:]):
            if xa <= gx <= xb:
                t = (gx - xa) / float(max(1, xb - xa))
                hg = ya + (yb - ya) * t
                break
        else:
            hg = 0.0
        hg += 2.5 * (h01(seed, int(gx // 3)) - 0.5) + 1.5 * (vnoise(seed + 2, gx / 2.5) - 0.5)
        return h - max(0.0, hg) if hg > 1 else h + 1

    massif = RF.Massif(seed, gx0 - 40, gx0 + w + 40, h, 9, 22, relief=0.7, ledge_gap=(7, 15), sheets=False)
    field = RF.Field(massif, gx0, w, h, top, margin=24)
    return RF.paint(field, "gate", rim=0.8, seed=seed, contrast=1.1)


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
    if len(a) >= 4 and a[0] == "build" and a[2] == "--out":
        build(a[1], a[3])
        return
    raise SystemExit(__doc__)


if __name__ == "__main__":
    main()
