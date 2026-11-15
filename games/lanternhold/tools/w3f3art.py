#!/usr/bin/env python3
"""Lanternhold world lane, step world-3, fix round 3 (15.11.2026; the critic's look 3 of world-3:
ci-out/director/world-3-camera-pass-critic3.md). Pure python on pixelart.py's Image, hashes of the position instead of
randomness, so a run reproduces its files byte for byte. Every pass starts from fix round 2's painting
(tools/w3f2art.py, which reads its own sources from tools/w3f2src), so no new source files.

  beaconTower       64x130   the chapter's goal at night (blocker 1): the shaft re-laid as blocks (each block one
        value, 2 to 3 value steps along a course, the joints one step under their block, never a dark dash), the left
        edge broken by two missing blocks; the bowl a wide shallow dish seen a little from above (its rim ellipse
        visible, a dark inside, grey ash lying low in it, no heap over the lip) on two cold iron struts
  beaconTowerRim    64x130   emissive: the moon on the right face as whole blocks (no dotted band, no wash over the
        faces: the wash lifted every face evenly and, under the night's desaturating grade, turned the tower grey),
        the dish's right lip and the ash
  gateRockL, gateRockR       the gate rocks (blocker 2): no lit edge on the slope at all; the shadow pockets in the
        cliff's own granite, one step under the lit face and a little bluer (no navy-black nightDeep, no slate)
  oldWall1          84x60    the first line's rubble (high 1): the porcelain stone ramp down onto the granite ramp, the
        lit tops at most rockLight, the moss a step darker in shadow
  castleFront3, castleFront3Build   the gate banners' lantern emblems (high 6): a dull gold thread one step over the
        cloth, lit only on the side toward the gate's torch, no neon outline
  bakehouse         100x62   the chimney over the battlement (high 8): the stack in the wall's stone, a pot with a dark
        mouth, no pale fill (the light at its mouth is gone in SceneLayoutCastle)

  w3f3art.py build <id> [<id> ...] --out <Resources/Art>
"""
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import pixelart as PA  # noqa: E402
import worldart as WA  # noqa: E402
import w3art as W3  # noqa: E402
import w3f2art as F2  # noqa: E402

col, h01 = WA.col, WA.h01
put, name_at, copy, white = W3.put, W3.name_at, W3.copy, W3.white
CLEAR = (0, 0, 0, 0)
ART = os.path.join(HERE, "..", "Resources", "Art")

RAMP = ["stoneDark", "stoneMid", "stone", "stoneLight", "stonePale"]
TOWER_TOP = F2.TOWER_TOP
DISH = dict(cx=29.0, rim_y=14, rx=17.0, ry=4.0, depth=5)


# ------------------------------------------------------------------------------------------------- blocker 1: the dish
def wide_dish(im, cx, rim_y, rx, depth, seed=91):
    """Replaces fix round 2's deep narrow bowl (read as a hat with the ash heaped like its crown): a wide shallow dish
    seen a little from above. The rim an ellipse 2 px thick whose whole ring shows; inside it dark (the far inner wall
    rockDeep, the floor ink) with grey ash lying low in its front half; under the front arc a shallow iron belly 3 rows
    deep; two cold iron struts slant from the belly down to the wall's top. The arguments of the old call are ignored
    (the dish's own place is DISH)."""
    cx, rim_y, rx, ry, depth = DISH["cx"], DISH["rim_y"], DISH["rx"], DISH["ry"], DISH["depth"]
    parts = {"body": set(), "rim": set(), "lip": set(), "ash": set(), "ashtop": set(), "strut": set()}
    rin, ryin = rx - 2.7, ry - 1.5

    def setp(x, y, nm, part):
        if 0 <= x < im.w and 0 <= y < im.h:
            put(im, x, y, nm)
            for q in parts.values():
                q.discard((x, y))
            parts[part].add((x, y))

    def outer(x, y):
        u, v = (x + 0.5 - cx) / rx, (y + 0.5 - rim_y) / ry
        return u * u + v * v <= 1.0

    def inner(x, y):
        u, v = (x + 0.5 - cx) / rin, (y + 0.5 - rim_y) / ryin
        return u * u + v * v <= 1.0

    # the struts first (the belly and the parapet lie over their ends)
    for (x0, y0, x1, y1) in [(21, 21, 22, 24), (37, 21, 36, 24)]:
        n = max(abs(x1 - x0), abs(y1 - y0))
        for i in range(n + 1):
            x = int(round(x0 + (x1 - x0) * i / float(n)))
            y = int(round(y0 + (y1 - y0) * i / float(n)))
            setp(x, y, "stoneDark", "strut")
            setp(x + 1, y, "rockDeep", "strut")
    # the belly: under the front arc, a shallow curve
    for x in range(int(cx - rx), int(cx + rx) + 1):
        u = (x + 0.5 - cx) / rx
        if abs(u) >= 1:
            continue
        front = rim_y + ry * math.sqrt(1 - u * u)
        bottom = rim_y + ry + depth * math.sqrt(max(0.0, 1 - (u / 0.86) ** 2)) - 0.5
        t = (u + 1) / 2
        for y in range(int(math.floor(front)), int(math.floor(bottom)) + 1):
            if outer(x, y):
                continue
            k = y - front
            nm = "stoneMid" if t < 0.3 else "stoneDark" if t < 0.7 else "rockDeep"
            if k < 1.0:
                nm = "rockDeep"                        # the lip's shadow under the front arc
            elif y >= bottom - 0.5:
                nm = "rockDeep"
            setp(x, y, nm, "body")
    # the rim ring
    for y in range(int(rim_y - ry) - 1, int(rim_y + ry) + 2):
        for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
            if not outer(x, y) or inner(x, y):
                continue
            t = (x + 0.5 - (cx - rx)) / (2 * rx)
            if y + 0.5 < rim_y:                        # the back arc: its top face toward us
                nm = "stoneLight" if t < 0.35 else "stone"
            else:                                      # the front arc: its top lit, its outer face darker
                nm = "stoneLight" if inner(x, y - 1) or inner(x, y - 2) else "stone" if t < 0.5 else "stoneMid"
            part = "rim"
            if t > 0.8 and y + 0.5 < rim_y + 1 and not outer(x + 1, y):
                nm, part = "stoneLight", "lip"        # the right lip, where the moon catches it
            setp(x, y, nm, part)
    # inside: the far inner wall a step lit, then dark, the floor ink; the ash low in the front half
    for y in range(int(rim_y - ryin) - 1, int(rim_y + ryin) + 2):
        for x in range(int(cx - rin) - 1, int(cx + rin) + 2):
            if not inner(x, y):
                continue
            v = (y + 0.5 - rim_y) / ryin
            nm = "stoneMid" if v < -0.6 else "rockDeep" if v < -0.1 else "ink"
            setp(x, y, nm, "body")
            u = (x + 0.5 - cx) / (rin * 0.55)
            w = (y + 0.5 - (rim_y + 0.9)) / 1.1
            if u * u + w * w <= 1.0:
                a = h01(seed, x, y)
                nm = "stone" if a < 0.45 else "stoneMid" if a < 0.85 else "stoneLight"
                setp(x, y, nm, "ash" if a < 0.85 else "ashtop")
    return parts


# --------------------------------------------------------------------------------------------- blocker 1: the shaft
def reblock(im):
    """The shaft's courses (4 rows, the mortar on rows 4k+1) re-laid as blocks: each block one value from the ramp
    (the day's light from the left, a hash for each block), the joint row and the head joints one step under their
    block, so a course reads as 2 to 3 value steps of stone, never as pale strips ruled by dark dashes."""
    ramp = set(RAMP)
    out = copy(im)
    for y in range(TOWER_TOP, im.h):
        xs = [x for x in range(im.w) if im.get(x, y)[3]]
        if not xs:
            continue
        a, b = min(xs), max(xs)
        course = (y - 2) // 4
        r = (y - 2) % 4
        off = (course % 2) * 3 + int(h01(311, course) * 3)
        for x in xs:
            nm = name_at(im, x, y)
            if nm not in ramp:
                continue
            if y >= 123 and (x < 8 or x > 53):
                continue                              # the fallen blocks at the foot stay
            t = (x - a) / float(max(1, b - a))
            bx = (x + off) // 7
            v = 3.0 - 2.1 * t + (h01(313, course, bx) - 0.5) * 1.7
            vi = max(1, min(3, int(round(v))))
            if r == 3 or (x + off) % 7 == 0:
                vi -= 1                               # a joint: one step under its block
            elif h01(317, x, y) < 0.06:
                vi = max(1, vi - 1)                   # a pit in the face
            if nm == "stoneDark" and x >= b - 1:
                vi = min(vi, 0)                       # the shade edge stays dark
            put(out, x, y, RAMP[max(0, vi)])
    return out


def break_left(im):
    """Two blocks missing from the left edge (courses 11 and 19): the edge 5 px in for one course, the break's inner
    face a step dark, the course below's top lit, the overhang's underside in shadow."""
    for course in (11, 19):
        y0 = course * 4 + 2
        rows = range(y0, y0 + 4)
        lefts = []
        for y in list(rows) + [y0 + 4]:
            xs = [x for x in range(im.w) if im.get(x, y)[3]]
            lefts.append(min(xs) if xs else None)
        a = lefts[0]
        if a is None:
            continue
        depth = 5 if course == 11 else 4
        for i, y in enumerate(rows):
            for x in range(a, a + depth):
                im.set(x, y, CLEAR)
            put(im, a + depth, y, "stoneDark" if i else "stoneMid")
        for x in range(a, a + depth):
            put(im, x, y0 - 1, "stoneDark")           # the overhang's underside
            put(im, x, y0 + 4, "stoneLight")          # the lower course's top
    return im


def beacon_tower():
    """Fix round 2's tower with the wide dish in place of its bowl (its merlons stand in front of the dish), the shaft
    re-laid as blocks and the left edge broken."""
    old = F2.cold_bowl
    F2.cold_bowl = wide_dish
    try:
        im, parts = F2.beacon_tower()
    finally:
        F2.cold_bowl = old
    im = reblock(im)
    im = break_left(im)
    parts = wide_dish(im, 0, 0, 0, 0)                 # the dish again, in front of the broken merlons
    return im, parts


def face_band(im, parts=None, top=TOWER_TOP - 1):
    """Emissive: the moon from the east on whole blocks of the right face (the block's value, 0.3 to 0.5, its joints
    at a third), fading over 7 px into the face; no wash elsewhere (fix round 2's wash over every face lifted the
    stone evenly toward grey under the night's grade, and its band lit every second course only: a dotted row)."""
    out = PA.Image(im.w, im.h)
    ramp = set(RAMP)
    for y in range(im.h):
        xs = [x for x in range(im.w) if im.get(x, y)[3] and name_at(im, x, y) in ramp]
        if not xs or y < top:
            continue
        b = max(x for x in range(im.w) if im.get(x, y)[3])
        course = (y - 2) // 4
        r = (y - 2) % 4
        off = (course % 2) * 3 + int(h01(311, course) * 3)
        for x in xs:
            d = b - x
            if d > 7:
                continue
            bx = (x + off) // 7
            a = (0.3 + 0.2 * h01(331, course, bx)) * (1 - d / 8.0) ** 1.2
            if r == 3 or (x + off) % 7 == 0:
                a *= 0.35
            if a > 0.03:
                out.set(x, y, white(a))
    if not parts:
        return out
    for (x, y) in parts["lip"]:
        out.set(x, y, white(0.7))
    for (x, y) in parts["rim"]:
        if x > DISH["cx"] + 6:
            out.set(x, y, white(0.35 if y < DISH["rim_y"] else 0.22))
    for (x, y) in parts["ashtop"] | parts["ash"]:
        if x > DISH["cx"]:
            out.set(x, y, white(0.18))
    rows = {}
    for (x, y) in parts["body"] | parts["strut"]:
        rows.setdefault(y, []).append(x)
    for y, xs in rows.items():
        r = max(xs)
        if (r, y) not in parts["body"] or y <= DISH["rim_y"] + 1:
            continue
        out.set(r, y, white(0.4))
    return out


def tower_rim():
    im, parts = beacon_tower()
    return face_band(im, parts)


def stage_rim(name):
    """The other stages' moon: the same block band on their right face, no wash."""
    painters = {"beaconRuin": F2.F1.beacon_ruin, "greatBeacon": F2.F1.great_beacon}
    im = painters[name]() if name in painters else PA.read_png(os.path.join(ART, name + ".png"))[0]
    return face_band(im, top=0)


# --------------------------------------------------------------------------------------------- blocker 2: gate rocks
GRANITE_SHADE = (78, 74, 82, 255)      # rockDark (84, 77, 75) a hair darker and about 15 % bluer
GRANITE_DEEP = (66, 62, 72, 255)       # the deepest pockets, still the granite, never nightDeep's navy


def gate_rock(name):
    im = F2.gate_rock(name)
    w, h = im.w, im.h
    remap = {"nightDeep": GRANITE_DEEP, "stoneDark": GRANITE_DEEP, "stoneMid": GRANITE_SHADE, "stone": col("rock"),
             "rockDeep": GRANITE_DEEP}
    out = copy(im)
    for y in range(h):
        for x in range(w):
            nm = name_at(im, x, y)
            if nm in remap:
                out.set(x, y, remap[nm])
    # no lit edge on the slopes: every outline pixel (an opaque pixel with a clear neighbour above or to the side)
    # takes the colour of the stone inside it
    final = copy(out)
    for y in range(h):
        for x in range(w):
            if not out.get(x, y)[3]:
                continue
            edge = any(not (0 <= x + dx < w and 0 <= y + dy < h) or not out.get(x + dx, y + dy)[3]
                       for dx, dy in ((-1, 0), (1, 0), (0, -1)))
            if not edge:
                continue
            for dx, dy in ((1, 1), (-1, 1), (0, 1), (1, 0), (-1, 0), (2, 1), (-2, 1), (0, 2)):
                xx, yy = x + dx, y + dy
                if 0 <= xx < w and 0 <= yy < h and out.get(xx, yy)[3]:
                    nb = [(xx + ex, yy + ey) for ex, ey in ((-1, 0), (1, 0), (0, -1))]
                    if all(0 <= p < w and 0 <= q < h and out.get(p, q)[3] for p, q in nb):
                        c = out.get(xx, yy)
                        if c[:3] == col("rockLight")[:3]:
                            c = col("rock")
                        final.set(x, y, c)
                        break
            else:
                c = out.get(x, y)
                if c[:3] == col("rockLight")[:3]:
                    final.set(x, y, col("rock"))
    # The shader's ledge (Shaders.metal `lh2_ledge`): a world sprite's pixel with nothing above it takes 1.4 x the
    # ambient and a share of the horizon's colour, the one under it half of that; on a slope every row's first pixel
    # is such a ledge, so the lit edge came back as a pale stepped line (lh-w3f3-1, t-3-1360). Those pixels are
    # painted dark enough that the ledge lifts them to the face's value, never over it.
    out = copy(final)
    for y in range(h):
        for x in range(w):
            if not final.get(x, y)[3]:
                continue
            if y == 0 or not final.get(x, y - 1)[3]:
                out.set(x, y, LEDGE_TOP)
            elif (y < 2 or not final.get(x, y - 2)[3]) and lum3(final.get(x, y)) > lum3(GRANITE_DEEP):
                out.set(x, y, GRANITE_DEEP)
    return out


def lum3(c):
    return 0.299 * c[0] + 0.587 * c[1] + 0.114 * c[2]


LEDGE_TOP = (50, 47, 55, 255)          # under the ledge's lift it lands on the shade's value


# ------------------------------------------------------------------------------------------------- high 1: oldWall1
def old_wall_one():
    im = F2.old_wall_one()
    remap = {"stonePale": col("rockLight"), "stoneLight": col("rock"), "stone": col("rockDark"),
             "stoneMid": GRANITE_SHADE, "stoneDark": GRANITE_DEEP, "leaf": col("rockDark")}
    leaf_names = {"leaf", "leafLight", "moss", "mossLight", "fir1", "meadow", "grass", "grassLight"}
    out = copy(im)
    for y in range(im.h):
        for x in range(im.w):
            nm = name_at(im, x, y)
            if nm in remap and nm != "leaf":
                out.set(x, y, remap[nm])
            elif nm in leaf_names or (nm is None and im.get(x, y)[3] and _greenish(im.get(x, y))):
                r, g, b, a = im.get(x, y)
                out.set(x, y, (int(r * 0.62), int(g * 0.62), int(b * 0.7), a))   # the moss in shadow
    return out


def _greenish(c):
    r, g, b = c[:3]
    return g > r + 8 and g > b


# ------------------------------------------------------------------------------------------- high 6: banner emblems
THREAD = (86, 72, 44, 255)             # dull gold thread, one value step over the cloth (roofDeep, 27 58 78)
THREAD_LIT = (124, 98, 54, 255)        # its side toward the gate's torch, a step more


def castle_front3(name):
    """The gate banners' lantern emblems (t-3-1360, w-1400-night: orange outline lanterns that glowed like neon under
    the torches): the emblem's gold a thread one step over the cloth, lit only on the side toward the torch between
    the banner and the gate (the left banner's right side, the right banner's left side); the lantern's glass the
    cloth again."""
    im = F2.castle_front3(name)
    gold = [(x, y) for y in range(im.h) for x in range(im.w) if name_at(im, x, y) == "gold"]
    for side in (0, 1):
        pts = [(x, y) for x, y in gold if (x < im.w // 2) == (side == 0)]
        if not pts:
            continue
        x0, x1 = min(p[0] for p in pts), max(p[0] for p in pts)
        y0, y1 = min(p[1] for p in pts), max(p[1] for p in pts)
        mid = (x0 + x1) / 2.0
        for x, y in pts:
            lit = x > mid if side == 0 else x < mid
            im.set(x, y, THREAD_LIT if lit else THREAD)
        for y in range(y0, y1 + 1):                    # the glass inside the frame
            for x in range(x0 + 1, x1):
                if name_at(im, x, y) in ("stone", "stoneLight", "stonePale", "parchment"):
                    put(im, x, y, "roofDeep")
    return im


# ------------------------------------------------------------------------------------------- high 8: the chimney pot
def bakehouse():
    """The bakehouse's chimney over the curtain's battlement (w-2400-dusk, w-2330-dusk, w-2200-night: a pale box with
    a lit squiggle, read as a "?" glyph): the stack in the wall's stone, lit on the left and in shade on the right (no
    pale fill), and a pot with a dark mouth seen a little from above, so the smoke starts over it."""
    im = F2.F1.bakehouse()
    stack = range(72, 79)                              # inside the stack's ink outline (cols 71 and 78/79)
    for y in range(0, 15):
        for x in stack:
            nm = name_at(im, x, y)
            if nm in (None, "ink"):
                continue
            t = (x - 72) / 6.0
            v = "stone" if t < 0.3 else "stoneMid" if t < 0.75 else "stoneDark"
            if y >= 4 and (y - 4) % 4 == 3:
                v = "stoneMid" if t < 0.75 else "stoneDark"     # a course joint
            put(im, x, y, v)
    # the pot: its rim (row 1) lit, its mouth (row 0) dark inside the rim's ends
    for x in range(72, 79):
        put(im, x, 0, "stoneMid" if x in (72, 78) else "ink" if 73 < x < 77 else "rockDeep")
        put(im, x, 1, "stoneLight" if x < 75 else "stone" if x < 77 else "stoneMid")
    return im


BUILDERS = {
    "beaconTower": lambda: beacon_tower()[0],
    "beaconTowerRim": tower_rim,
    "beaconRuinRim": lambda: stage_rim("beaconRuin"),
    "beaconBaseRim": lambda: stage_rim("beaconBase"),
    "greatBeaconRim": lambda: stage_rim("greatBeacon"),
    "gateRockL": lambda: gate_rock("gateRockL"),
    "gateRockR": lambda: gate_rock("gateRockR"),
    "oldWall1": old_wall_one,
    "bakehouse": bakehouse,
    "castleFront3": lambda: castle_front3("castleFront3"),
    "castleFront3Build": lambda: castle_front3("castleFront3Build"),
}


def main():
    args = sys.argv[1:]
    out = ART
    if "--out" in args:
        i = args.index("--out")
        out = args[i + 1]
        args = args[:i] + args[i + 2:]
    if not args or args[0] != "build":
        print(__doc__)
        sys.exit(1)
    for name in args[1:]:
        img = BUILDERS[name]()
        PA.write_png(os.path.join(out, name + ".png"), img)
        print(name, img.w, img.h)


if __name__ == "__main__":
    main()
