#!/usr/bin/env python3
"""Lanternhold world lane, step world-3 (15.11.2026; DESIGN.md "World rebuild (14.11.2026)", ART-look2.md section 26,
docs/REVIEW-look-2.md M2, M4, M5, L3, L4 and the director's notes of 15.11. 09:19 and 09:23). Pure python on
pixelart.py's Image, palette colours only, hashes of the position instead of randomness, so a run reproduces its files
byte for byte. The passes over existing sprites read their untouched source from tools/w3src (copied there once,
before the first pass), so a pass can run again without stacking on itself.

  bakeHatchWedge    30x14    emissive: the oven's wedge of light from the hatch's sill down the dome's foot and out on
        the lane, brightest against the wall, fading in 10 rows toward the viewer (the critic's high 1 of look 3)
  beaconRuin        64x130   the ruin's crown repainted (M2): the old fire cage (a "handle" at night) becomes the
        Great Beacon's cold iron bowl, cracked, a heap of grey ash in it, on a stub of a stem in the broken top
  beaconRuinRim, beaconBaseRim, beaconTowerRim, greatBeaconRim   64x130  emissive: the moon's rim on each beacon
        stage's right and upper edges and a faint wash on its pale stones (lit at night), so the chapter's goal reads
        as a shape in the dark, never a flat black block
  wardenStatue      96x200   the statue's bowl (M5): a stone basin in its hands where the fire sits (its emitter one
        row higher), the rim warm where the fire lights it
  castleFront, castleFront3, castleFront3Build   the gatehouse's crenels and corbel band at the keep's values (the
        director's 09:19, 1c): their night-black gaps a slate dark and mid, never the window glass's black
  townRoofsA .. townRoofsD  120x72   the town's back row (M4): tall narrow town houses, a church spire, chimneys,
        dormers and small lit windows over a garden wall and a hedge; drawn on the near plane at 70 % value
  riverFarLantern   12x26    the far shore's lantern on its post (L4), its glass a mask
  riverSkiff        34x10    a skiff moored on the far bank (L4), its rope to a stake
  valleyVerge       64x10    the valley lane's verge (L3): stones, roots and the meadow's edge in the top rows of the
        band under the lane (drawn on the foreground plane, the valley set only)

  w3art.py build <id> [<id> ...] --out <Resources/Art>
  w3art.py all --out <Resources/Art>
"""
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import pixelart as PA  # noqa: E402
import worldart as WA  # noqa: E402
import townart as TA  # noqa: E402

col, h01 = WA.col, WA.h01
SRC = os.path.join(HERE, "w3src")
ART = os.path.join(HERE, "..", "Resources", "Art")
CLEAR = (0, 0, 0, 0)


def names():
    """Palette colour (r, g, b) -> name."""
    out = {}
    for line in open(os.path.join(HERE, "palette.txt")):
        p = line.split()
        if len(p) >= 2 and p[1].startswith("#") and len(p[1]) == 7 and not line.startswith("#"):
            h = p[1][1:]
            out[(int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16))] = p[0]
    return out


NAME = names()


def name_at(im, x, y):
    p = im.get(x, y)
    if not p[3]:
        return None
    return NAME.get(p[:3])


def put(im, x, y, name):
    if 0 <= x < im.w and 0 <= y < im.h:
        im.set(x, y, col(name) if isinstance(name, str) else name)


def src(name):
    return PA.read_png(os.path.join(SRC, name + ".png"))[0]


def copy(im):
    return PA.Image(im.w, im.h, list(im.px))


def white(a):
    k = max(0, min(16, int(a * 16 + 0.5)))
    return (255, 255, 255, min(255, 16 * k)) if k else CLEAR


# --------------------------------------------------------------------------------------------- the bakehouse's wedge
def bake_hatch_wedge():
    """An emitter at bakehouse col 3, dy -10 (30 x 14): its top 4 rows on the oven dome's foot under the hatch (cols
    15-20 of the bakehouse, its sill at row 7), its 10 lower rows on the lane. The hatch's width at the top, about
    four times it at the foot; the strength peaks at the wall's foot and falls away toward the viewer; the sides
    soften over 4 px; alpha in sixteenths, so the stones show through; gold by the wall, orange, then ember."""
    w, h = 30, 14
    im = PA.Image(w, h)
    cx = 14.5
    for y in range(h):
        out = y / float(h - 1)
        half = 3.5 + out * 10.5
        if y <= 3:
            strength = 0.62 + 0.38 * y / 3.0
        else:
            strength = max(0.0, 1 - (y - 3) / 10.5) ** 1.6
        for x in range(w):
            dx = abs(x - cx)
            if dx > half + 1.5:
                continue
            side = 1.0 if dx <= half - 2.5 else max(0.0, (half + 1.5 - dx) / 4.0)
            side = side * side * (3 - 2 * side)
            a = 0.46 * strength * side
            nm = "fireGold" if out < 0.3 else "fireOrange" if out < 0.7 else "ember"
            r, g, b, _ = col(nm)
            k = int(a * 16 + 0.5)
            if k > 0:
                im.set(x, y, (r, g, b, min(255, 16 * k)))
    return im


# --------------------------------------------------------------------------------------------- the beacon (M2)
IRON_OUT = "ink"


def beacon_ruin():
    """The ruin with its crown repainted: the fire cage over the broken top (rows 5-33, cols 18-42) is taken out;
    the hollow of the broken top stays dark; the Great Beacon's old bowl sits on a stub of its iron stem: a wide
    shallow basin of black iron (a lit lip where the sky catches it, two straps, a bite broken out of its right rim),
    a low heap of cold grey ash in it with a charred log end. Outlined in ink like the ruin."""
    im = copy(src("beaconRuin"))
    cage = {"ink", "night0", "night1", "stoneMid", "stoneDark"}
    for y in range(0, 28):
        for x in range(18, 43):
            if name_at(im, x, y) in cage:
                im.set(x, y, CLEAR)
    for x in range(19, 43):                        # row 28: the cage's foot over the broken top
        if name_at(im, x, 28) in cage:
            im.set(x, 28, CLEAR)
    for y in range(29, 33):                        # the hollow of the broken top: dark, its bars gone
        for x in range(21, 39):
            if name_at(im, x, y) in ("ink", "night1"):
                im.set(x, y, col("night0"))
    cx = 31
    # the stem's stub, into the hollow
    for y in range(26, 33):
        for x in range(cx - 2, cx + 3):
            put(im, x, y, "stoneDark" if x < cx + 1 else "night1")
        put(im, cx - 3, y, IRON_OUT)
        put(im, cx + 3, y, IRON_OUT)
    for x in range(cx - 4, cx + 5):               # a collar where the stem meets the bowl
        put(im, x, 25, "stoneMid" if x < cx else "stoneDark")
    put(im, cx - 5, 25, IRON_OUT)
    put(im, cx + 5, 25, IRON_OUT)
    # the basin: rows 18 (lip) to 24 (foot), half-width 12 at the lip, 6 at the foot
    rows = [(18, 12.5), (19, 12), (20, 11), (21, 10), (22, 9), (23, 7.5), (24, 6)]
    bite = range(cx + 6, cx + 10)                  # a piece broken out of the right rim
    for y, half in rows:
        a, b = int(round(cx - half)), int(round(cx + half))
        for x in range(a, b + 1):
            t = (x - a) / float(max(1, b - a))
            if y == 18:
                nm = "stone" if t < 0.55 else "stoneMid"
                if x in bite:
                    continue
            elif y == 19:
                nm = "stoneMid" if t < 0.4 else "stoneDark"
                if x in bite and x > cx + 7:
                    continue
            else:
                nm = "stoneMid" if t < 0.18 else "stoneDark" if t < 0.7 else "night1"
            if y >= 20 and x in (cx - 6, cx + 5):  # two straps
                nm = "night1" if t > 0.5 else "stoneDark"
            put(im, x, y, nm)
        put(im, a - 1, y, IRON_OUT)
        put(im, b + 1, y, IRON_OUT)
    for x in range(cx - 13, cx + 14):             # the lip's top edge
        if x not in bite:
            put(im, x, 17, IRON_OUT)
    for x in bite:                                 # the broken edge's face
        put(im, x, 19, IRON_OUT)
    # cold ash heaped over the lip, a charred log end on the left
    ash = [(16, cx - 8, cx + 4), (15, cx - 6, cx + 2), (14, cx - 3, cx)]
    for y, a, b in ash:
        for x in range(a, b + 1):
            v = h01(77, x, y)
            put(im, x, y, "stonePale" if v < 0.25 else "stoneLight" if v < 0.8 else "stone")
        put(im, a - 1, y, IRON_OUT)
        put(im, b + 1, y, IRON_OUT)
    for x in range(cx - 8, cx + 5):
        put(im, x, 17, "stoneLight" if h01(78, x) < 0.6 else "stone")
    for x in range(cx - 3, cx + 1):
        put(im, x, 13, IRON_OUT)
    put(im, cx - 10, 16, "woodDark")
    put(im, cx - 11, 16, "woodDark")
    put(im, cx - 11, 15, IRON_OUT)
    put(im, cx - 10, 15, IRON_OUT)
    put(im, cx - 12, 16, IRON_OUT)
    put(im, cx - 9, 16, "soilDark")
    return im


def moon_rim(im):
    """Emissive (white × the moon's colour in the engine): the moon stands high to the east, so each shape's right
    edge (the first pixel inside its ink outline) takes 0.85, the next two 0.45 and 0.26, a top edge 0.62, and the
    stone of its face a wash that grows from its west third to 0.22 at its east edge, so the shape has inner values at
    night (round lh-w3-1: with edges alone it read as a dark block with a thin outline)."""
    out = PA.Image(im.w, im.h)
    edge = {None, "ink", "night0"}

    def solid(x, y):
        return 0 <= x < im.w and 0 <= y < im.h and name_at(im, x, y) not in edge

    for y in range(im.h):
        for x in range(im.w):
            if not solid(x, y):
                continue
            nm = name_at(im, x, y)
            a = 0.0
            if not solid(x + 1, y):
                a = 0.85
            elif not solid(x + 2, y):
                a = 0.45
            elif not solid(x + 3, y):
                a = 0.26
            if not solid(x, y - 1):
                a = max(a, 0.62 if not solid(x + 1, y - 1) or x > im.w * 0.4 else 0.45)
            stone = nm in ("stonePale", "stoneLight", "stone", "stoneMid", "stoneDark", "plaster", "parchment")
            if stone and a < 0.2:                   # the face toward the moon: a wash that grows to the east
                k = (x / float(im.w) - 0.35) / 0.65
                if k > 0:
                    a = max(a, 0.22 * k)             # from nothing, so the wash shows no seam (round lh-w3-2)
            if nm in ("leaf", "leafDark", "meadow", "night1", "nightDeep"):
                a *= 0.4
            if 0 < a < 0.25:                        # the wash: dithered between neighbouring sixteenths, no bands
                lv = a * 16
                lo = int(lv)
                a = (lo + (1 if (lv - lo) > BAYER4[(y % 4) * 4 + (x % 4)] else 0)) / 16.0
            if a > 0:
                out.set(x, y, white(a))
    return out


BAYER4 = [(v + 0.5) / 16.0 for v in (0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5)]


def beacon_rim(name):
    return moon_rim(beacon_ruin() if name == "beaconRuin" else PA.read_png(os.path.join(ART, name + ".png"))[0])


# --------------------------------------------------------------------------------------------- the warden statue (M5)
def warden_statue():
    """The statue's bowl: a stone basin held at its chest (rows 41-48, cols 35-60), its fire (the engine's hearthFire,
    16 x 10, now at dy 156: rows 34-43) seated in it. A lip catching the fire in warm granite, an inside in deep
    shadow, a body in the statue's cool stone darkening to its right, a foot on the hands' slab; the old flat slab's
    pale row goes under the basin."""
    im = copy(src("wardenStatue"))
    cx = 48
    rows = [(41, 13), (42, 13), (43, 12), (44, 11), (45, 10), (46, 8), (47, 6), (48, 4)]
    for y, half in rows:
        a, b = cx - half, cx + half - 1
        for x in range(a, b + 1):
            t = (x - a) / float(max(1, b - a))
            if y == 41:
                nm = "rockPale" if t < 0.5 else "rockLight"      # the lip, warm where the fire lights it
            elif y == 42:
                nm = "rockDeep" if 2 < x - a < (b - a) - 2 else "rockLight"   # the inside, where the fire sits
            else:
                nm = "stone" if t < 0.22 else "stoneMid" if t < 0.6 else "stoneDark"
                if y == 43:
                    nm = "rockLight" if t < 0.4 else "rock" if t < 0.75 else "stoneMid"   # the fire on its shoulder
                if y == 44:
                    nm = "stoneMid" if t < 0.5 else "stoneDark"                       # under the lip's roll
                if y == 48:
                    nm = "stoneDark" if t < 0.6 else "rockDeep"
            put(im, x, y, nm)
        put(im, a - 1, y, "stoneDark" if y > 41 else "rockLight")
        put(im, b + 1, y, "rockDeep")
    for x in range(cx - 3, cx + 3):                # the foot standing on the hands' slab
        put(im, x, 49, "rockDeep")
    darker = {"stonePale": "stoneLight", "stoneLight": "stone", "stone": "stoneMid", "stoneMid": "stoneDark"}
    for y in (49, 50, 51):                         # the bowl's shadow on the robe under it
        for x in range(cx - 10 + (y - 49) * 2, cx + 10 - (y - 49) * 2):
            nm = name_at(im, x, y)
            if nm in darker and not (y == 49 and cx - 3 <= x < cx + 3):
                put(im, x, y, darker[nm])
    return im


# --------------------------------------------------------------------------------------------- the gatehouse (1c)
GATE_MASKS = {   # glass masks (dx, dy, w, h from the sprite's bottom-left) and the braziers' niches: kept as painted
    "castleFront": [(29, 96, 6, 15), (202, 89, 6, 15), (29, 69, 6, 15), (202, 69, 6, 15)],
    "castleFront3": [(39, 127, 4, 12), (39, 93, 4, 12), (223, 127, 4, 12), (223, 93, 4, 12)],
    "castleFront3Build": [(39, 127, 4, 12), (39, 93, 4, 12)],
}
GATE_NICHE_SHIFT = {"castleFront": 0, "castleFront3": 14, "castleFront3Build": 14}
GATE_BAND = (48, 146)   # image rows of the crowns, the wall walk's crenels and the corbel band


def gate_lift(name):
    """The crenels' and corbel band's night-black gaps a slate dark (night0) and mid (night1), as the keep's are,
    outside the slits' glass and the wall-walk braziers' niches (their fire burns in the dark). The ink outline stays."""
    im = copy(src(name))
    keep = set()
    for (dx, dy, w, h) in GATE_MASKS[name]:
        for y in range(im.h - dy - h - 1, im.h - dy + 1):
            for x in range(dx - 1, dx + w + 1):
                keep.add((x, y))
    s = GATE_NICHE_SHIFT[name]
    for (x0, x1) in ((84 + s, 112 + s), (129 + s, 157 + s)):
        for y in range(80, 113):
            for x in range(x0, x1 + 1):
                keep.add((x, y))
    for y in range(GATE_BAND[0], GATE_BAND[1] + 1):
        for x in range(im.w):
            if (x, y) in keep:
                continue
            nm = name_at(im, x, y)
            if nm == "night0":
                im.set(x, y, col("stoneDark"))
            elif nm == "night1":
                im.set(x, y, col("stoneMid"))
    return im


# --------------------------------------------------------------------------------------------- the town's back row (M4)
TR_W = 120
TR_HEIGHTS = {"townRoofsA": 72, "townRoofsB": 72, "townRoofsC": 96, "townRoofsD": 72}


def timber(im, x0, x1, y0, y1, seed, kind):
    """Half-timbering over a plaster wall (rows y0 .. y1): the posts at its ends and every 9 to 12 px, a rail at mid
    height, braces in the end bays (kind 1: a cross in the middle bay too)."""
    xs = [x0]
    x = x0
    while x + 12 < x1:
        x += 9 + int(4 * h01(seed, x, 31))
        if x1 - x >= 6:
            xs.append(x)
    xs.append(x1 - 1)
    for x in xs:
        TA.post(im, x, y0, y1)
    rail = (y0 + y1) // 2
    TA.beam(im, x0, x1, rail, h=1)
    if len(xs) >= 2:
        TA.brace(im, xs[0] + 2, y0 + 1, 1, max(2, rail - y0 - 1))
        TA.brace(im, xs[-1] - 1, y0 + 1, -1, max(2, rail - y0 - 1))
    if kind == 1 and len(xs) >= 4:
        m = len(xs) // 2
        a, b = xs[m - 1] + 2, xs[m] - 1
        n = min(b - a, y1 - rail - 1)
        TA.brace(im, a, rail + 1, 1, n)
        TA.brace(im, b, rail + 1, -1, n)


def town_house(im, base, x0, w, eave, ridge, roof_kind, seed, chimney=None, dormer=False, wins=(), gable=False,
               ground="plaster", frame=0):
    """A tall narrow town house standing on row `base`: plaster walls (half-timbered when `frame`), or a stone
    ground floor, small windows (night1 glass: `wins` as (dx, h) of each 3 x 4 pane from the house's left and its
    bottom row's height over the ground). A side-on house has a long ridge with short hips (the cottage's shape);
    a `gable` house turns its gable to the lane: a plaster triangle under two tiled verges that meet at the ridge.
    A chimney at `chimney` (dx) and a dormer."""
    y_eave = base - eave
    TA.plaster(im, x0, y_eave + 1, x0 + w - 1, base, seed, shade_from=x0 + w - 4)
    if ground == "stone":
        TA.fieldstone(im, x0, y_eave + 1 + eave // 2, x0 + w - 1, base, seed)
        TA.beam(im, x0, x0 + w - 1, y_eave + eave // 2, h=1)
    if frame:
        timber(im, x0, x0 + w - 1, y_eave + 1, y_eave + (eave // 2 if ground == "stone" else eave - 2), seed, frame)
    TA.beam(im, x0, x0 + w - 1, y_eave + 1, h=1, lit=False)
    for (dx, hh) in wins:
        gy = base - hh - 3
        TA.window(im, x0 + dx, gy, 3, 4, shutters=None, sill=True, bars=False)
    TA.rect(im, x0 + w, y_eave + 1, x0 + w, base, "ink")
    ramp = {"tile": TA.TILE, "slate": TA.SLATE, "thatch": TA.THATCH}[roof_kind]
    E, S, D, B, L = ramp
    top, bot = base - ridge, y_eave
    over = 2
    if not gable:
        inset = max(3, (w + 2 * over) // 6)
        xl = lambda y: int(round(x0 - over + inset * (bot - y) / float(max(1, bot - top))))  # noqa: E731
        xr = lambda y: int(round(x0 + w - 1 + over - inset * (bot - y) / float(max(1, bot - top))))  # noqa: E731
        TA.roof(im, top, bot, xl, xr, ramp, roof_kind, seed, moss=roof_kind != "slate")
        if dormer:
            TA.dormer(im, x0 + w // 2 - 1, top + (bot - top) // 2 + 2, ramp)
    else:
        cxh = x0 + (w - 1) / 2.0
        span = float(max(1, bot - top))
        for y in range(top, bot + 1):
            f = (y - top) / span
            a = int(round(cxh - (cxh - x0 + over) * f))
            b = int(round(cxh + (x0 + w - 1 + over - cxh) * f))
            for x in range(a, b + 1):
                edge_l = x - a < 3
                edge_r = b - x < 3
                if edge_l:
                    nm = L if x - a < 2 else B
                elif edge_r:
                    nm = D if b - x > 0 else "ink"
                else:                               # the gable's plaster (its top a step darker under the verges)
                    nm = "plasterDim" if (y - top) < 3 or (x - a) < 4 or (b - x) < 4 else "plaster"
                    if frame and (abs(x - cxh) < 1 or (y - top) == int(span * 0.6)):
                        nm = "woodDark"
                TA.px(im, x, y, nm)
            if y == bot:
                for x in range(a, b + 1):
                    TA.px(im, x, y, E if a + 2 < x < b - 2 else D)
        gx = int(cxh) - 1                           # a small pane high in the gable
        gy = top + int(span * 0.62) + 1
        if bot - gy > 4:
            TA.window(im, gx, gy, 3, 3, shutters=None, sill=False, bars=False)
    if chimney is not None:
        TA.chimney(im, x0 + chimney, x0 + chimney + 4, max(0, top - 3), top + 3 + (bot - top) // 3, seed)


def gable_pane(base, x0, w, eave, ridge):
    """The gable's small pane (dx from the sprite's left, dy over its bottom), as `town_house` paints it."""
    top, bot = base - ridge, base - eave
    span = float(max(1, bot - top))
    cxh = x0 + (w - 1) / 2.0
    gx = int(cxh) - 1
    gy = top + int(span * 0.62) + 1
    if bot - gy > 4:
        return (gx, base - (gy + 2), 3, 3)
    return None


def spire(im, base, x0, seed, tall=52, point=94):
    """The church: a stone tower (cols x0 .. x0 + 19) to height `tall` with buttressed corners, a louvred belfry and a
    lancet low on its face (a mask), a tall slate spire on a corbelled eave to height `point`, lucarnes on it, a gold
    finial."""
    w = 20
    for y in range(base - tall, base + 1):
        for x in range(x0, x0 + w):
            k = y - (base - tall)
            course = k // 4
            sx = x + (course % 2) * 3
            nm = "stone" if h01(seed, course, sx // 6) < 0.7 else "stoneLight"
            if k % 4 == 3 or sx % 6 == 0:
                nm = "stoneMid"
            if x - x0 < 2:
                nm = "stonePale" if k % 4 != 3 else "stoneLight"
            elif x >= x0 + w - 4:
                nm = "stoneMid" if nm != "stoneMid" else "stoneDark"
            put(im, x, y, nm)
        put(im, x0 + w, y, "ink")
    bel = base - tall + 4
    for y in range(bel, bel + 9):                   # the belfry's twin openings with louvres
        for x in (x0 + 5, x0 + 6, x0 + 12, x0 + 13):
            put(im, x, y, ("night1" if (y - bel) % 2 else "stoneDark") if y > bel else "stoneMid")
    for x in range(x0 - 1, x0 + w + 1):            # string courses and the eave's corbels
        put(im, x, bel + 10, "stonePale" if x < x0 + w - 4 else "stoneLight")
        put(im, x, bel + 11, "stoneDark")
        put(im, x, base - tall, "stoneLight" if x < x0 + w - 3 else "stone")
        put(im, x, base - tall + 1, "stoneDark" if x % 3 else "stoneMid")
    for y in range(base - 24, base - 15):          # the lancet (a mask: lit at night)
        for x in (x0 + 9, x0 + 10):
            put(im, x, y, "night1")
    put(im, x0 + 9, base - 25, "stoneDark")
    put(im, x0 + 10, base - 25, "stoneDark")
    for y in range(base - 8, base + 1):            # the door
        for x in range(x0 + 8, x0 + 12):
            put(im, x, y, "woodDark" if x in (x0 + 8, x0 + 11) else "wood")
    cxs = x0 + (w - 1) / 2.0
    top, bot = base - point + 1, base - tall - 1
    TA.roof(im, top, bot, lambda y: int(round(cxs - 0.5 - (w / 2.0) * (y - top) / float(bot - top))),
            lambda y: int(round(cxs + 0.5 + (w / 2.0) * (y - top) / float(bot - top))), TA.SLATE, "slate", seed,
            moss=False, mid=0.5, shade=5)
    luc = bot - (bot - top) // 3                    # a lucarne on the spire's face
    for y in range(luc - 3, luc + 1):
        for x in range(int(cxs) - 1, int(cxs) + 2):
            put(im, x, y, "night1" if y > luc - 3 else "roofLight")
    for y, xs, nm in ((top - 1, (int(cxs), int(cxs) + 1), "gold"), (top - 2, (int(cxs),), "gold"),
                      (top - 3, (int(cxs),), "fireGold")):
        for x in xs:
            put(im, x, y, nm)


def garden(im, base, seed, x0=0, x1=TR_W - 1):
    """The foot of the back row: a field-stone garden wall to height 6 with a hedge and fruit trees' crowns over it
    in gaps, so the row stands on the ground behind the front houses (never a floating edge)."""
    a, b = x0 + 2, x1 - 2
    TA.fieldstone(im, a, base - 5, b, base, seed)
    for k, keep in enumerate((1, 3, 4)):            # the wall's ends crumble in steps (no cut at the sprite's edge)
        for x in (a + k, b - k):
            for y in range(base - 5, base - keep + 1):
                im.set(x, y, CLEAR)
    for x in range(a + 4, b - 3):
        top = 9 + int(5 * h01(seed, x // 7)) + (1 if h01(seed, x, 2) < 0.3 else 0)
        if h01(seed, x // 9, 4) < 0.35 or min(x - a, b - x) < 6 and h01(seed, x, 5) < 0.5:
            continue
        for hh in range(6, top + 1):
            v = h01(seed, x, hh)
            nm = "leafDark" if hh < top - 2 or v < 0.5 else "leaf"
            if hh == top and v < 0.3:
                nm = "leafLight"
            put(im, x, base - hh, nm)


# Each back-row sprite: its houses back to front (x0, w, eave, ridge, roof, seed, chimney dx, dormer, windows,
# gable, ground, frame); they overlap, so the row reads as a town, not a line of boxes. townRoofsC holds the church.
TOWN_ROWS = {
    "townRoofsA": [(26, 40, 40, 62, "tile", 402, 26, True, ((8, 24), (28, 24)), False, "plaster", 1),
                   (0, 30, 44, 68, "tile", 401, None, False, ((6, 30), (20, 30), (13, 16)), True, "stone", 1),
                   (64, 30, 38, 56, "thatch", 404, None, False, ((8, 22), (20, 22)), False, "plaster", 0),
                   (88, 30, 46, 70, "tile", 403, 20, False, ((7, 32), (20, 32), (13, 18)), True, "plaster", 1)],
    "townRoofsB": [(30, 44, 36, 58, "thatch", 413, None, True, ((9, 22), (30, 22)), False, "plaster", 0),
                   (0, 36, 42, 64, "slate", 411, 24, False, ((7, 28), (24, 28), (15, 14)), False, "stone", 1),
                   (70, 26, 48, 70, "tile", 412, None, False, ((5, 34), (16, 34), (10, 20)), True, "plaster", 1),
                   (94, 26, 40, 60, "tile", 414, 14, False, ((6, 26), (16, 26)), False, "plaster", 0)],
    "townRoofsC": [(0, 40, 40, 62, "tile", 421, 26, False, ((7, 26), (26, 26)), False, "plaster", 1),
                   (64, 54, 42, 64, "tile", 423, 38, True, ((8, 28), (24, 28), (40, 28)), False, "stone", 1)],
    "townRoofsD": [(40, 30, 50, 72, "slate", 432, 18, False, ((6, 36), (18, 36), (12, 22)), True, "plaster", 1),
                   (0, 46, 42, 62, "tile", 431, 32, True, ((7, 28), (34, 28), (7, 14)), False, "stone", 1),
                   (76, 44, 38, 58, "thatch", 433, None, False, ((8, 22), (30, 22)), False, "plaster", 0)],
}
TOWN_SPIRE = {"townRoofsC": 42}


def town_roofs(name):
    h = TR_HEIGHTS[name]
    base = h - 1
    im = PA.Image(TR_W, h)
    seed = 400 + sorted(TOWN_ROWS).index(name)
    houses = TOWN_ROWS[name]
    for (x0, w, eave, ridge, kind, s, chim, dorm, wins, gable, ground, frame) in houses:
        town_house(im, base, x0, w, eave, ridge, kind, s, chimney=chim, dormer=dorm, wins=wins, gable=gable,
                   ground=ground, frame=frame)
    if name in TOWN_SPIRE:
        spire(im, base, TOWN_SPIRE[name], seed)
    garden(im, base, seed)
    return im


def town_masks(name):
    """The back row's glass for the layout (dx, dy from the bottom-left, w, h): every pane still seen after the
    houses in front of it (`town_roofs` paints back to front), the dormers' and gables' panes and the church's
    lancet."""
    h = TR_HEIGHTS[name]
    base = h - 1
    im = town_roofs(name)
    glass = col("night1")
    out = []
    houses = TOWN_ROWS[name]
    rects = []
    for (x0, w, eave, ridge, kind, s, chim, dorm, wins, gable, ground, frame) in houses:
        for (dx, hh) in wins:
            rects.append((x0 + dx, hh, 3, 4))
        if dorm and not gable:
            top, bot = base - ridge, base - eave
            gy = top + (bot - top) // 2 + 2
            rects.append((x0 + w // 2 - 1, base - (gy + 1), 3, 2))
        if gable:
            pane = gable_pane(base, x0, w, eave, ridge)
            if pane:
                rects.append(pane)
    if name in TOWN_SPIRE:
        rects.append((TOWN_SPIRE[name] + 9, 16, 2, 9))
    for (dx, dy, w, hh) in rects:
        rows = range(h - dy - hh, h - dy)
        if all(im.get(x, y) == glass for x in range(dx, dx + w) for y in rows):
            out.append((dx, dy, w, hh))
    return out


def town_chimney(name):
    """The frontmost chimney's middle column and the height of its mouth (for the layout's smoke)."""
    h = TR_HEIGHTS[name]
    best = None
    for (x0, w, eave, ridge, kind, s, chim, dorm, wins, gable, ground, frame) in TOWN_ROWS[name]:
        if chim is not None:
            best = (x0 + chim + 2, h - 1 - max(0, h - 1 - ridge - 3))
    return best


# --------------------------------------------------------------------------------------------- the river end (L4)
def river_far_lantern():
    """A lantern on a post on the far shore (12 x 26): a weathered post, an arm, a small iron lantern whose 3 x 4
    glass is a mask (lit at dusk and night), a stone at its foot."""
    im = PA.Image(12, 26)
    for y in range(4, 25):
        put(im, 5, y, "wood")
        put(im, 6, y, "woodDark")
    for x in range(5, 11):
        put(im, x, 4, "woodDark")
    put(im, 5, 3, "woodLight")
    put(im, 6, 3, "woodDark")
    for y in range(5, 7):
        put(im, 9, y, "ink")
    for y in range(7, 13):                          # the lantern: cap, glass, base
        for x in range(7, 12):
            put(im, x, y, "ink")
    for x in range(8, 11):
        put(im, x, 7, "stoneMid")
    for y in range(8, 12):
        for x in range(8, 11):
            put(im, x, y, "night1")
    for x in range(3, 9):
        put(im, x, 25, "stone" if x < 6 else "stoneMid")
    put(im, 4, 24, "stoneLight")
    put(im, 5, 24, "stone")
    return im


def river_skiff():
    """A skiff moored on the far bank (34 x 10): a dark tarred hull with a lit sheer strake, two thwarts, an oar
    across, its painter rope to a stake on the bank."""
    im = PA.Image(34, 10)
    hull = [(4, 2, 27), (5, 2, 27), (6, 3, 26), (7, 5, 24), (8, 7, 22)]
    for y, a, b in hull:
        for x in range(a, b + 1):
            put(im, x, y, "woodDark" if y > 4 else "wood")
        put(im, a - 1, y, "ink")
        put(im, b + 1, y, "ink")
    for x in range(1, 30):                          # the sheer strake catches the sky
        put(im, x, 3, "woodLight" if x < 20 else "wood")
    put(im, 0, 2, "woodLight")
    put(im, 29, 2, "wood")
    for x in (10, 19):
        put(im, x, 2, "woodDark")
    for i, x in enumerate(range(6, 24)):            # the oar across the thwarts
        put(im, x, 1 + (1 if i > 12 else 0), "woodLight" if i % 4 else "wood")
    put(im, 30, 1, "woodDark")                      # the painter to a stake
    put(im, 31, 2, "woodDark")
    put(im, 32, 3, "woodDark")
    for y in range(1, 9):
        put(im, 33, y, "woodDark")
    put(im, 33, 0, "wood")
    for x in range(1, 30):                          # the water's dark line along the hull
        put(im, x, 9, "night1" if x % 3 else "night2")
    return im


# --------------------------------------------------------------------------------------------- the valley verge (L3)
def valley_verge():
    """Where the valley's earth track meets the grass under it (64 x 10, tiling, its row 3 on the track's lower
    edge): the meadow's edge in tufts that grow up into the track (lit tops), stones half bedded in the earth (lit
    from the upper left, a dark seat under each), roots crossing; the lowest rows fade into the band."""
    w, h = 64, 10
    im = PA.Image(w, h)
    seed = 521
    for x in range(w):                              # the meadow's edge: a ragged line of tufts
        hh = 1 + int(3.2 * h01(seed, x // 2, 1)) + (1 if h01(seed, x, 1) < 0.2 else 0)
        if h01(seed, x // 5, 9) < 0.18:
            hh = 0
        for k in range(hh + 2):
            y = 4 - hh + k
            v = h01(seed, x, y, 2)
            nm = "leafLight" if k == 0 and v < 0.5 else "meadow" if k <= 1 else "leaf" if v < 0.6 else "leafDark"
            put(im, x, y, nm)
    k = 0
    x = 1
    while x < w - 4:                                # stones bedded in the earth
        sw = 3 + int(4 * h01(seed, k, 3))
        sy = 1 + int(4 * h01(seed, k, 4))
        sh = 2 + int(2 * h01(seed, k, 5))
        if h01(seed, k, 6) < 0.75:
            for yy in range(sy, min(h - 2, sy + sh)):
                for xx in range(x, min(w, x + sw)):
                    last = xx == x + sw - 1
                    nm = "stoneLight" if yy == sy and not last else "stone" if not last else "stoneMid"
                    if yy == sy + sh - 1 and not last:
                        nm = "stoneMid"
                    put(im, xx, yy, nm)
                put(im, min(w - 1, x + sw), yy, "soilDark")
            for xx in range(x, min(w, x + sw + 1)):
                put(im, xx, min(h - 1, sy + sh), "soilDark")
        x += sw + 2 + int(5 * h01(seed, k, 7))
        k += 1
    for r in range(3):                              # roots crossing the edge
        rx = 6 + r * 21 + int(6 * h01(seed, r, 8))
        for i in range(9):
            yy = 3 + int(2.4 * math.sin(i * 0.7 + r)) + i // 4
            put(im, rx + i, yy, "woodDark" if i % 3 else "soil")
    for y in range(h):                              # fade the lowest rows into the band
        f = 1.0 if y < 7 else max(0.0, 1 - (y - 6) / 3.0)
        if f >= 1:
            continue
        for xx in range(w):
            p = im.get(xx, y)
            if p[3]:
                im.set(xx, y, (p[0], p[1], p[2], (int(p[3] * f) // 16) * 16))
    return im


OUT = "."
BUILDERS = {
    "bakeHatchWedge": bake_hatch_wedge,
    "beaconRuin": beacon_ruin,
    "beaconRuinRim": lambda: beacon_rim("beaconRuin"),
    "beaconBaseRim": lambda: beacon_rim("beaconBase"),
    "beaconTowerRim": lambda: beacon_rim("beaconTower"),
    "greatBeaconRim": lambda: beacon_rim("greatBeacon"),
    "wardenStatue": warden_statue,
    "castleFront": lambda: gate_lift("castleFront"),
    "castleFront3": lambda: gate_lift("castleFront3"),
    "castleFront3Build": lambda: gate_lift("castleFront3Build"),
    "townRoofsA": lambda: town_roofs("townRoofsA"),
    "townRoofsB": lambda: town_roofs("townRoofsB"),
    "townRoofsC": lambda: town_roofs("townRoofsC"),
    "townRoofsD": lambda: town_roofs("townRoofsD"),
    "riverFarLantern": river_far_lantern,
    "riverSkiff": river_skiff,
    "valleyVerge": valley_verge,
}


def main():
    global OUT
    a = sys.argv[1:]
    OUT = a[a.index("--out") + 1] if "--out" in a else "."
    if a and a[0] == "masks":
        for n in sorted(TOWN_ROWS):
            print(n, town_masks(n), "chimney", town_chimney(n))
        return
    if a and a[0] == "build":
        todo = [n for n in a[1:] if not n.startswith("--") and n != OUT]
    else:
        todo = list(BUILDERS)
    for n in todo:
        im = BUILDERS[n]()
        path = os.path.join(OUT, n + ".png")
        PA.write_png(path, im)
        print("wrote", path, im.w, "x", im.h)


if __name__ == "__main__":
    main()
