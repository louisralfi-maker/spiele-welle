#!/usr/bin/env python3
"""Lanternhold world lane, step world-3, fix round 2 (15.11.2026; DESIGN.md "World rebuild (14.11.2026)", ART-look2.md
section 28, the critic's look 2 of world-3: ci-out/director/world-3-camera-pass-critic2.md). Pure python on
pixelart.py's Image, palette colours only, hashes of the position instead of randomness, so a run reproduces its
files byte for byte. Passes over existing sprites read their untouched sources from tools/w3f2src.

  throatButtress    96x132   near plane (blocker 1): a rib of the Throat's own granite, no cut line round it; its
        shade in the cliff's warm slate (rockDeep, never nightSlate's cobalt), the light from the upper left; the left
        slope broken by three ledges with lit shelves, a broad crest leaning back, and its feet in scree fans that run
        out on both sides to the ground, so it stands rooted, a rib of the wall, not a needle on a stage
  beaconTower       64x130   the chapter's goal at the tower stage (blocker 2): the parapet broken (the left merlon
        chipped, the middle one knocked down to a stub, the right corner fallen 16 rows in steps that follow the
        courses), fallen blocks at the foot, the 2-row gap under the old parapet closed with courses; the cold bowl a
        value step above its body at the rim (an ellipse 3 px thick), a cold highlight on its right lip and a grey ash
        crown heaped over the back lip
  beaconRuinRim .. greatBeaconRim  64x130  emissive: the moon's band on the right broken at every second course (lit
        stone faces, never a rim line), a wash that lifts the faces a value step at night (west 2/16, east 3/16, the
        joints left dark), the bowl's right lip and the ash crown's top
  castleFront, castleFront3, castleFront3Build   the gate towers' slits (high 2): a dark reveal round a 2 px glass
        core, no glass in the frame (the frame's glass lit as a "[ ]" glyph)
  watchtower        24x64    the front tower's slits (high 2): the shuttered window (lit as an "r" hook) a plain
        arrow loop, a 2 px glass core in a dark reveal
  cloudA, cloudB, cloudC     the clouds' undersides (high 7): the checker dither teeth (a pinking-shears seam across
        the sky) taken out, the notches filled, the underside in broad soft scallops 12 to 28 px long and 0 to 2 rows
        deep, its last row a value step darker (the cloud's belly)
  riverSkiffMoored  40x12    the skiff (high 5): a hull that reads, its bow raised (right), a light gunwale line, the
        planking a step darker, a thwart, the painter rope from the stern up to the old stump
  riverSkiffRim     40x12    emissive: the moon on the gunwale and the bow
  riverLanternStreak 7x26    emissive: the far lantern's reflection, a broken streak 3 to 4 px wide that fades
        downward (white x amber in the engine)
  riverLanternHalo  22x22    emissive: the halo a step smaller and fainter (fire-gold in the engine)
  posternNightView  10x14    the postern's far view at night (high 4): the valley under the moon, its sky a deep
        blue, the hills a step darker, a faint lit meadow; laid over the painted view by the night's share
  gloomGroundFog    320x28   the Gloom's ground fog (high 8), 2 frames of 160x28 (body, leading face): a cold low
        mist that rises 16 to 22 rows over the lane, densest at the ground, its top in soft irregular billows
  oldWall1          84x60    Oriel's first line at the Throat's end (smaller): the stepped blocks rounded into rubble, the
        tops chipped, heaps of rubble at the foot
  darknessBankGlow  36x3     the bank's near eyes open: almonds, not "+" crosses
  gateRockL, gateRockR       the gate rocks' lit edge a step down (rockPale to rockLight): no cream cut line up the slope
  valleyVerge, valleyVergeB  the verge (smaller): stones at irregular gaps (3 to 17 px), no two gaps alike in a row

  w3f2art.py build <id> [<id> ...] --out <Resources/Art>
"""
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import pixelart as PA  # noqa: E402
import worldart as WA  # noqa: E402
import rockfield as RF  # noqa: E402
import w3art as W3  # noqa: E402
import w3f1art as F1  # noqa: E402

col, h01 = WA.col, WA.h01
put, name_at, copy, white = W3.put, W3.name_at, W3.copy, W3.white
CLEAR = (0, 0, 0, 0)
ART = os.path.join(HERE, "..", "Resources", "Art")
SRC2 = os.path.join(HERE, "w3f2src")


def src2(name):
    return PA.read_png(os.path.join(SRC2, name + ".png"))[0]


def wa(name, a):
    return F1.wa(name, a)


def luma(p):
    return 0.299 * p[0] + 0.587 * p[1] + 0.114 * p[2]


# --------------------------------------------------------------------------------------------- blocker 1: the buttress
BUT_W, BUT_H = 96, 132


def throat_buttress():
    """A rib of the Throat's granite (96 x 132, the ground line its bottom row), light from the upper left. The shade
    is the cliff's own warm slate (`rockDeep`, a touch bluer than the lit `rock`: never nightSlate's cobalt); no lit
    rim, no outline. The left slope climbs in three ledges (lit shelves over dark risers), the crest is broad and
    leans back to the right, the right side falls in a shoulder with a fourth ledge; an apron of scree runs along its
    whole foot and out to both ends on the ground, so the rock stands rooted at the wall's foot."""
    w, h = BUT_W, BUT_H
    gx0, seed = 6600, 6629
    pts = [(0, 0), (4, 6), (8, 12), (12, 17), (14, 22), (15, 30), (17, 40), (22, 38), (24, 45), (26, 58), (27, 63),
           (35, 61), (37, 69), (38, 77), (42, 79), (44, 87), (46, 100), (48, 104), (53, 108), (58, 110), (64, 109),
           (70, 106), (74, 100), (77, 90), (80, 79), (86, 77), (87, 66), (89, 50), (91, 34), (92, 24), (93, 14),
           (94, 7), (95, 2)]
    shelves = [(17, 22, 40), (27, 35, 62), (38, 42, 78), (80, 86, 79)]
    prof = [(gx0 + x, y) for x, y in pts]

    def height(lx):
        for (xa, ya), (xb, yb) in zip(pts, pts[1:]):
            if xa <= lx <= xb:
                t = (lx - xa) / float(max(1, xb - xa))
                return ya + (yb - ya) * t
        return 0.0

    def top(gx):
        hg = height(gx - gx0) + 0.9 * (h01(seed, int(gx // 3)) - 0.5)
        return h - max(0.0, hg) if hg > 1 else h + 1

    spots = [(gx0 + 52, gx0 + 62, h - 96, 2.4, 1.5, 0.06), (gx0 + 62, gx0 + 72, h - 70, 2.4, 1.5, -0.06),
             (gx0 + 22, gx0 + 32, h - 30, 2.2, 1.4, 0.0)]
    RF.RAMPS["buttress2"] = ["rockDeep", "rockDeep", "rockDark", "rock", "rockLight", "rockPale"]
    RF.SNOW["buttress2"] = RF.SNOW["footing"]
    massif = RF.Massif(seed, gx0 - 40, gx0 + w + 40, h, 18, 40, relief=0.8, ledge_gap=(14, 24), sheets=False,
                       facets=0.3, chimneys=0.2, swell=2.0, pieces=True, crease=True, spots=spots, ledge_max=12,
                       face_relief=2.0, cracks=0.4)
    field = RF.Field(massif, gx0, w, h, top, margin=24)
    img = RF.paint(field, "buttress2", gain=0.9, rim=0.0, seed=seed, contrast=1.05, lit_rim=False, clamp=0.6)
    # the ledges: a lit shelf (two rows) on each, its riser's foot in shadow under the next shelf's lip
    for x0, x1, hh in shelves:
        for x in range(x0, x1 + 1):
            ys = [y for y in range(h) if img.get(x, y)[3]]
            if not ys:
                continue
            t = min(ys)
            put(img, x, t, "rockLight" if h01(seed, x, 701) < 0.8 else "rock")
            put(img, x, t + 1, "rock")
            put(img, x, t + 2, "rockDark")
        rx = x1 + 1                                     # the riser over the shelf's east end: its foot in shadow
        ys = [y for y in range(h) if img.get(rx, y)[3]]
        if ys:
            for y in range(min(ys) + 3, min(h, h - hh + 4)):
                if img.get(rx, y)[3]:
                    put(img, rx, y, "rockDeep")
    # the scree apron along the foot: grit and stones, 9 to 18 rows high, rising into the skirts at both ends
    def apron(x):
        a = 9 + 3 * math.sin(x / 7.0 + 1.1) + 2 * h01(seed, x // 5, 702)
        if height(x) < 24:                              # the skirts where the rock runs out
            a = max(a, height(x))
        return a
    for x in range(w):
        a = apron(x)
        for y in range(h):
            up = h - 1 - y
            if up > a or not img.get(x, y)[3]:
                continue
            v = h01(seed, x, y, 703)
            edge = up > a - 1.5
            nm = "rockDark" if v < 0.5 else "rockDeep" if v < 0.8 else "rock"
            if edge:
                nm = "rock" if v < 0.6 else "rockDark"
            put(img, x, y, nm)
    # stones on the apron, three sizes, lit tops
    for i in range(46):
        x = int(w * h01(seed, i, 711))
        a = apron(x)
        y = h - 1 - int((a - 1) * h01(seed, i, 712) ** 1.4)
        v = h01(seed, i, 713)
        size = 1 if v < 0.45 else 2 if v < 0.85 else 3
        for dy in range(size):
            for dx in range(size + 1):
                xx, yy = x + dx, y - dy
                if not (0 <= xx < w and 0 <= yy < h) or not img.get(xx, yy)[3]:
                    continue
                if dy == size - 1 and dx < size:
                    nm = "rockLight" if size > 1 else "rock"
                elif dx < size:
                    nm = "rockDark"
                else:
                    nm = "rockDeep"
                put(img, xx, yy, nm)
    return img


# --------------------------------------------------------------------------------------------- blocker 2: the beacon
TOWER_TOP = 26         # the shaft's courses from this row down (4-row courses, the mortar on rows 4k+1)


def cold_bowl(im, cx, rim_y, rx, depth, seed=91):
    """The cold iron bowl seen a little from above, in clear value steps: the body under the rim `depth` rows deep and
    narrowing, dark iron lit on the left (stoneMid, stoneDark, rockDeep) with one band; the rim an ellipse 3 px thick
    at its ends, a value step above the body (its back arc stonePale to stone, its front arc stone to stoneDark) with
    the lip's shadow under it; inside, the bowl's back wall in shadow and the ash; over the back lip a crown of grey
    ash heaped in the middle; a cold highlight on the right lip. Returns the painted cells by part."""
    parts = {"body": set(), "rim": set(), "lip": set(), "ash": set(), "ashtop": set()}
    ry_out, rin, ry_in = 3.0, rx - 3.0, 1.5

    def setp(x, y, nm, part):
        if 0 <= x < im.w and 0 <= y < im.h:
            put(im, x, y, nm)
            for q in parts.values():
                q.discard((x, y))
            parts[part].add((x, y))

    def outer(x, y):
        u, v = (x - cx) / rx, (y - rim_y) / ry_out
        return u * u + v * v <= 1.0

    def inner(x, y):
        u, v = (x - cx) / rin, (y - rim_y) / ry_in
        return u * u + v * v <= 1.0

    for k in range(1, depth + 1):                      # the body
        y = rim_y + k
        half = (rx - 0.5) - (rx * 0.3) * (k / float(depth)) ** 1.2
        a, b = int(round(cx - half)), int(round(cx + half))
        for x in range(a, b + 1):
            t = (x - a) / float(max(1, b - a))
            nm = "stoneMid" if t < 0.24 else "stoneDark" if t < 0.62 else "rockDeep"
            if 0.1 < t < 0.2:
                nm = "stone"                           # the lit flank's highlight
            if k == depth // 2 + 1:
                nm = "stoneDark" if t < 0.24 else "rockDeep"   # the iron band
            if k == depth:
                nm = "rockDeep"
            setp(x, y, nm, "body")
    for y in range(int(rim_y - ry_out) - 1, int(rim_y + ry_out) + 2):   # the rim
        for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
            if not outer(x, y) or inner(x, y):
                continue
            t = (x - (cx - rx)) / (2 * rx)
            if y < rim_y:
                nm = "stonePale" if t < 0.3 else "stoneLight" if t < 0.72 else "stone"
            else:
                nm = "stone" if t < 0.3 else "stoneMid" if t < 0.72 else "stoneDark"
            part = "rim"
            if 0.76 < t < 0.94 and y < rim_y and not outer(x, y - 1):
                nm, part = "stonePale", "lip"          # the cold highlight on the right lip
            setp(x, y, nm, part)
    for x in range(int(cx - rx), int(cx + rx) + 1):    # the lip's shadow on the body under the front arc
        ys = [y for y in range(rim_y, rim_y + 4) if outer(x, y)]
        if ys:
            y = max(ys) + 1
            if (x, y) in parts["body"]:
                setp(x, y, "rockDeep", "body")
    for y in range(int(rim_y - ry_in) - 1, int(rim_y + ry_in) + 2):     # inside: the back wall, the ash
        for x in range(int(cx - rin), int(cx + rin) + 1):
            if not inner(x, y):
                continue
            back = not inner(x, y - 1)
            v = h01(seed, x, y, 7)
            nm = "stoneDark" if back else "stone" if v < 0.55 else "stoneLight"
            setp(x, y, nm, "ash")
    for x in range(int(cx - rin * 0.75), int(cx + rin * 0.75) + 1):    # the ash crown over the back lip
        d = abs(x - cx) / (rin * 0.75)
        heap = int(round(2.6 * max(0.0, 1 - d ** 4) ** 0.5 + 0.6 * h01(seed, x, 1)))
        if heap <= 0:
            continue
        base_y = int(math.floor(rim_y - ry_in))
        for i in range(heap + 1):
            y = base_y - heap + i
            v = h01(seed, x, y, 9)
            nm = "stonePale" if i == 0 else "stoneLight" if v < 0.55 else "stone"
            setp(x, y, nm, "ashtop" if i == 0 else "ash")
    return parts


def beacon_tower():
    """The tower stage's crown repainted (rows 0 to 45) over the shaft of tools/w3f2src/beaconTower.png."""
    base = src2("beaconTower")
    im = copy(base)
    w = im.w
    left, right = 11, 53                                # the shaft's outline columns
    # 1. the shaft's courses up to TOWER_TOP: rows 26-33 take the bond of rows 34-41 (the 2-row gap under the old
    #    parapet closed; the outline columns as below)
    for y in range(0, 34):
        for x in range(w):
            im.set(x, y, CLEAR)
    for y in range(TOWER_TOP, 34):
        sy = y + 8
        for x in range(w):
            im.set(x, y, base.get(x, sy))
    # 2. the fallen corner: east of col 42 the courses broke away in steps that follow them, the corner 16 rows down
    steps = [(42, 45, TOWER_TOP + 4), (46, 49, TOWER_TOP + 9), (50, right, TOWER_TOP + 16)]
    for x0, x1, top in steps:
        for x in range(x0, x1 + 1):
            jag = 1 if h01(77, x) < 0.35 else 0
            for y in range(0, top + jag):
                im.set(x, y, CLEAR)
            t = top + jag
            put(im, x, t, "stoneLight" if h01(78, x) < 0.7 else "stone")    # the broken course's top
            put(im, x, t + 1, "stone")
    for (x0, x1, top), nxt in zip(steps, steps[1:]):
        # the break's face toward the east at each step: rough core, a value under the course faces
        for y in range(top + 1, nxt[2] + 1):
            put(im, x1, y, "stoneMid" if (y + x1) % 3 else "stoneDark")
    # 3. the parapet: a string course on the wall's top, the left merlon chipped, the middle one a stub
    for x in range(left, 42):
        put(im, x, TOWER_TOP - 1, "stonePale" if x % 5 else "stoneLight")
        put(im, x, TOWER_TOP, "stoneMid")
    # 4. the bowl, seated on the wall's top behind the merlons
    parts = cold_bowl(im, 29.0, 15, 11.0, 9)
    merlons = [(11, 18, 17), (26, 32, 22)]              # (x0, x1, top row): the left one whole, the middle a stub
    for mi, (x0, x1, top) in enumerate(merlons):
        for x in range(x0, x1 + 1):
            t = top
            if mi == 0 and x <= x0 + 2:
                t = top + 2 + (1 if x == x0 else 0)       # the left merlon's chipped corner
            if mi == 1:
                t = top + int(3 * h01(79, x))             # the stub's broken top
            for y in range(t, TOWER_TOP - 1):
                k = y - t
                nm = "stonePale" if k == 0 else "stoneLight" if x < x0 + (x1 - x0) * 0.6 else "stone"
                if (y - t) % 4 == 3:
                    nm = "stoneMid"                       # a joint
                if x == x1:
                    nm = "stoneDark" if k else "stoneMid"   # its east side in shade, before the bowl
                put(im, x, y, nm)
                for p in parts.values():
                    p.discard((x, y))
    # 5. fallen blocks at the foot: two on the right, one on the left, lit tops, lying askew
    blocks = [(50, 125, 5, 4), (56, 126, 4, 3), (59, 124, 3, 2), (2, 126, 4, 3)]
    for bx, by, bw, bh in blocks:
        for y in range(by, by + bh + 1):
            for x in range(bx, bx + bw + 1):
                if x >= w or y >= im.h:
                    continue
                if y == by:
                    nm = "stonePale" if x < bx + bw else "stoneLight"
                elif x == bx + bw or y == by + bh:
                    nm = "stoneDark"
                else:
                    nm = "stoneLight" if x < bx + 2 else "stone"
                put(im, x, y, nm)
    return im, parts


def course_band(im, keep_parts=None):
    """Emissive: the moon to the east. On every stone row the eastmost run takes a band 2 or 3 px wide on its stone
    faces, broken at every second course (the course's 4 rows left dark, so the band reads as lit stone faces, never
    a rim line), the joints left out; a wash over the faces lifts them a value step at night (2/16 on the west half,
    3/16 on the east half, joints dark)."""
    out = PA.Image(im.w, im.h)
    edge = {None, "ink", "night0"}
    faces = {"stonePale", "stoneLight", "stone", "stoneMid", "stoneDark", "plaster", "parchment", "mistLight",
             "woodLight", "wood", "straw", "strawLight", "banner", "roofLight"}

    def solid(x, y):
        return 0 <= x < im.w and 0 <= y < im.h and name_at(im, x, y) not in edge

    def lum(x, y):
        return luma(im.get(x, y)) if solid(x, y) else 0.0

    def joint(x, y):
        l = lum(x, y)
        up = lum(x, y - 1) if y > 0 else 999
        down = lum(x, y + 1) if y + 1 < im.h else 999
        return l + 6 < up and l + 6 < down

    xs_all = [x for y in range(im.h) for x in range(im.w) if solid(x, y)]
    if not xs_all:
        return out
    mid_x = (min(xs_all) + max(xs_all)) / 2.0
    for y in range(im.h):
        xs = [x for x in range(im.w) if solid(x, y)]
        if not xs:
            continue
        right = max(xs)
        course = (y - 2) // 4
        lit_course = course % 2 == 0
        width = 3 if h01(181, course) < 0.5 else 2
        for i in range(width):
            x = right - i
            if not lit_course or not solid(x, y):
                break
            nm = name_at(im, x, y)
            if nm not in faces or joint(x, y):
                continue
            out.set(x, y, white((0.6, 0.4, 0.22)[i]))
        for x in xs:
            if out.get(x, y)[3]:
                continue
            nm = name_at(im, x, y)
            if nm not in faces or joint(x, y):
                continue
            out.set(x, y, white(3 / 16.0 if x > mid_x else 2 / 16.0))
    if keep_parts:
        for (x, y) in keep_parts.get("lip", ()):
            out.set(x, y, white(0.75))
        for (x, y) in keep_parts.get("ashtop", ()):
            out.set(x, y, white(0.5 if x > 26 else 0.34))
        rim_rows = {}
        for (x, y) in keep_parts.get("rim", ()):
            rim_rows.setdefault(x, []).append(y)
        for x, ys in rim_rows.items():               # the back arc's top row: the moon along the rim's ellipse
            if x > 22:
                out.set(x, min(ys), white(0.3))
        body = keep_parts.get("body", set()) | keep_parts.get("rim", set())
        rows = {}
        for (x, y) in body:
            rows.setdefault(y, []).append(x)
        for y, xs in rows.items():
            r = max(xs)
            out.set(r, y, white(0.45))
            out.set(r - 1, y, white(0.22))
    return out


def stage_rim(name):
    if name == "beaconTower":
        im, parts = beacon_tower()
        return course_band(im, parts)
    painters = {"beaconRuin": F1.beacon_ruin, "greatBeacon": F1.great_beacon}
    im = painters[name]() if name in painters else PA.read_png(os.path.join(ART, name + ".png"))[0]
    return course_band(im)


# --------------------------------------------------------------------------------------------- high 2: the slits
def slit(im, x0, y0, w, h):
    """A slit in the box (x0, y0 top-left, w x h): the outer columns and the sill a dark reveal (stoneDark), the
    rest of the box a deeper reveal (rockDeep), and only the middle two columns glass (night0) under the head's two
    rows: the glow is a 2 px core, never a frame."""
    cx0 = x0 + (w - 2) // 2
    for y in range(y0, y0 + h):
        for x in range(x0, x0 + w):
            if not im.get(x, y)[3]:
                continue
            k = y - y0
            if x in (x0, x0 + w - 1) or y == y0 + h - 1:
                nm = "stoneDark"
            elif x in (cx0, cx0 + 1) and k >= 2:
                nm = "night0"
            else:
                nm = "rockDeep"
            put(im, x, y, nm)


def glassy(im, x, y):
    return name_at(im, x, y) in ("night0", "night1", "ink")


def slit_boxes(im, boxes):
    """Repaint each mask box (dx, dy from the bottom-left, w, h) as a slit, grown to the glass pixels it covers."""
    for dx, dy, w, h in boxes:
        x0, y0 = int(dx), im.h - int(dy) - h
        ys = [y for y in range(y0 - 1, y0 + h + 1) for x in range(x0, x0 + w) if glassy(im, x, y)]
        if not ys:
            continue
        top, bottom = min(ys), max(ys)
        slit(im, x0, top, w, bottom - top + 2)


def castle_front():
    im = src2("castleFront")
    slit_boxes(im, [(29, 96, 6, 15), (202, 89, 6, 15), (29, 69, 6, 15), (202, 69, 6, 15)])
    return im


def castle_front3(name):
    im = src2(name)
    slit_boxes(im, [(39, 127, 4, 12), (39, 93, 4, 12), (223, 127, 4, 12), (223, 93, 4, 12)])
    return im


def watchtower():
    """The front tower: the upper slit kept (a 2 px core) with a dark reveal round it; the shuttered window under it
    (its glass round a wooden cross, lit as an "r" hook) a plain arrow loop of the same kind."""
    im = src2("watchtower")
    for y in range(34, 40):                             # the lower window: rows 34-39, cols 10-13
        for x in range(10, 14):
            put(im, x, y, "night0" if x in (11, 12) and y >= 35 else "rockDeep")
    for y in range(21, 28):                             # the upper slit's reveal
        put(im, 10, y, "rockDeep")
        put(im, 13, y, "rockDeep")
    return im


# --------------------------------------------------------------------------------------------- high 7: the clouds
def cloud_underside(name, seed):
    """The cloud's dithered underside (a checker of single pixels, a regular sawtooth at phone size) taken out; the
    notches between what is left filled to the lower neighbour; the underside then hangs in broad soft scallops (12
    to 28 px long, 0 to 2 rows deep) in the belly colour, their last row a value darker; no tooth, no loose pixel."""
    im = src2(name)
    w, h = im.w, im.h

    def op(img, x, y):
        return 0 <= x < w and 0 <= y < h and img.get(x, y)[3] > 0

    out = copy(im)
    for y in range(h):
        for x in range(w):
            if not op(im, x, y):
                continue
            lone = not op(im, x - 1, y) and not op(im, x + 1, y)
            below_clear = all(not op(im, x, yy) for yy in range(y + 1, min(h, y + 4)))
            if lone and below_clear:
                out.set(x, y, CLEAR)
    # a second pass: what the first left as a lone tooth
    im = out
    out = copy(im)
    for y in range(h):
        for x in range(w):
            if op(im, x, y) and not op(im, x - 1, y) and not op(im, x + 1, y) and not op(im, x, y + 1):
                out.set(x, y, CLEAR)
    im = out
    colours = sorted({im.get(x, y)[:3] for x in range(w) for y in range(h) if im.get(x, y)[3]}, key=luma)

    def darker(c):
        i = colours.index(c) if c in colours else 0
        return colours[max(0, i - 1)]

    bottoms = {}
    for x in range(w):
        ys = [y for y in range(h) if im.get(x, y)[3]]
        if ys:
            bottoms[x] = max(ys)
    lowest = max(bottoms.values()) if bottoms else h
    # the belly: the commonest colour on the underside's lowest pixels, darker than the lit tops
    counts = {}
    for x, bottom in bottoms.items():
        if bottom >= lowest - 8:
            c = im.get(x, bottom)[:3]
            counts[c] = counts.get(c, 0) + 1
    belly = max(counts, key=counts.get) if counts else colours[0]
    if luma(belly) > luma(colours[len(colours) // 2]):
        belly = colours[max(0, len(colours) // 2 - 1)]
    out = copy(im)
    # 1. notches filled: where a column's underside stands higher than both neighbours' within 3 px, it hangs to the
    #    lower of them (no dark tooth between two lobes)
    for x, bottom in bottoms.items():
        if bottom < lowest - 8:
            continue
        left = max([bottoms.get(xx, -1) for xx in range(x - 3, x)] or [-1])
        right = max([bottoms.get(xx, -1) for xx in range(x + 1, x + 4)] or [-1])
        fill = min(left, right)
        for y in range(bottom + 1, fill + 1):
            out.set(x, y, (belly[0], belly[1], belly[2], 255))
        if fill > bottom:
            bottoms[x] = fill
    im = out
    # 2. broad soft scallops 12 to 28 px long, 0 to 2 rows deep, in the belly colour, their last row a value darker
    edges, pos, k = [], 0.0, 0
    while pos < w + 30:
        edges.append(pos)
        pos += 12 + 16 * h01(seed, k, 1)
        k += 1

    def depth_at(x):
        for i in range(len(edges) - 1):
            if edges[i] <= x < edges[i + 1]:
                t = (x - edges[i]) / (edges[i + 1] - edges[i])
                peak = 0.4 + 1.8 * h01(seed, i, 2)
                return int(round(peak * math.sin(math.pi * t) ** 1.5))
        return 0

    out = copy(im)
    for x, bottom in bottoms.items():
        if bottom < lowest - 8:          # the cloud's flanks rise there: nothing hangs from them
            continue
        c = im.get(x, bottom)[:3]
        if luma(c) > luma(belly):
            c = belly                    # a lit pixel never ends the underside
            out.set(x, bottom, (c[0], c[1], c[2], 255))
        d = depth_at(x)
        for kk in range(1, d + 1):
            y = bottom + kk
            if y < h:
                cc = belly if kk < d else darker(belly)
                out.set(x, y, (cc[0], cc[1], cc[2], 255))
        if d == 0:
            dc = darker(belly)
            out.set(x, bottom, (dc[0], dc[1], dc[2], 255))
    # 3. no single column hanging below both neighbours, no loose pixel
    final = copy(out)
    for y in range(h):
        for x in range(w):
            if not out.get(x, y)[3]:
                continue
            if not op(out, x - 1, y) and not op(out, x + 1, y) and not op(out, x, y + 1):
                final.set(x, y, CLEAR)
    return final


# --------------------------------------------------------------------------------------------- high 5: the river end
SKIFF_W, SKIFF_H = 40, 12


def skiff_sheer(x):
    """The near gunwale's row: low and level aft (left), sweeping up to the raised bow (right)."""
    t = x / float(SKIFF_W - 1)
    return int(round(6.0 - 0.8 * (1 - t) - 4.6 * max(0.0, (t - 0.55) / 0.45) ** 2.0))


def river_skiff_moored():
    """The skiff (40 x 12, the waterline its row 10), seen a little from above: the far gunwale a lit line two rows
    over the near one, the dark inside of the hull between them (a thwart across), the near gunwale a light line
    (woodLight), the planking under it a step darker with one plank line; both gunwales meet at the raised stem on
    the right and at a low transom on the left; under the waterline the hull dark and fading; the painter rope from
    the stern up out of the sprite's top left (to the stump)."""
    im = PA.Image(SKIFF_W, SKIFF_H)
    water = 10
    for x in range(1, SKIFF_W - 1):
        g = skiff_sheer(x)
        t = x / float(SKIFF_W - 1)
        gap = 2 if 0.08 < t < 0.82 else 1 if 0.04 < t < 0.92 else 0     # far gunwale over the near one
        if gap:
            put(im, x, g - gap, "wood")                    # the far gunwale, lit
            for y in range(g - gap + 1, g):
                put(im, x, y, "soilDark")                  # the dark inside
        keel = water
        if t > 0.88:
            keel = water - int((t - 0.88) / 0.12 * 5)      # the forefoot rises to the stem
        for y in range(g, keel + 1):
            k = y - g
            if k == 0:
                nm = "woodLight"                           # the near gunwale's light line
            elif k == 1:
                nm = "wood"
            elif y == g + 3 and 0.08 < t < 0.86:
                nm = "woodDark"                            # a plank line
            elif y >= water:
                nm = None
            else:
                nm = "wood" if k == 2 else "woodDark"
            if nm:
                put(im, x, y, nm)
        for y in range(water, SKIFF_H):                    # the hull under the water, fading
            if 0.08 < t < 0.86:
                im.set(x, y, wa("woodDark", max(0.2, 0.55 - 0.25 * (y - water))))
    sx = SKIFF_W - 2
    put(im, sx, skiff_sheer(sx) - 1, "woodLight")         # the stem head
    for y in range(skiff_sheer(1) - 1, water):
        put(im, 0, y, "woodDark")                          # the transom
    put(im, 0, skiff_sheer(1) - 1, "wood")
    for x in (17, 18):                                     # a thwart across the inside
        put(im, x, skiff_sheer(x) - 1, "woodDark")
    for i, (x, y) in enumerate(((2, 3), (2, 2), (1, 1), (1, 0))):
        put(im, x, y, "straw" if i % 2 else "strawLight")  # the painter rope
    for x in range(3, 34):
        if h01(611, x) < 0.55:
            im.set(x, water, wa("mistLight", 0.4))         # the waterline's lap, broken
    return im


def river_skiff_rim():
    """Emissive: the moon on the near gunwale's light line, brighter toward the raised bow, and on the stem head."""
    im = river_skiff_moored()
    out = PA.Image(im.w, im.h)
    for x in range(im.w):
        for y in range(im.h):
            if name_at(im, x, y) == "woodLight":
                out.set(x, y, white(0.3 + 0.3 * x / float(im.w)))
                break
    return out


def river_lantern_streak():
    """Emissive (7 x 26): the far lantern's reflection, a broken streak 3 to 4 px wide (a row or two lit, then one
    or two dark), swaying a pixel either way, its alpha falling from 0.5 to nothing downward."""
    im = PA.Image(7, 26)
    y = 0
    while y < 26:
        a = 0.52 * (1 - y / 26.0) ** 1.5
        width = 4 if h01(631, y) < 0.5 and y < 14 else 3
        off = int(round((h01(632, y) - 0.5) * 2))
        x0 = 3 - width // 2 + off
        run = 1 if y > 10 else 1 + int(h01(633, y) < 0.4)
        for kk in range(run):
            for x in range(x0, x0 + width):
                if 0 <= x < 7 and y + kk < 26:
                    edge = x in (x0, x0 + width - 1)
                    im.set(x, y + kk, white(a * (0.6 if edge else 1.0)))
        y += run + 1 + int(h01(634, y) < 0.45)
    return im


def river_lantern_halo():
    """Emissive (22 x 22, the glass at 10.5, 5.5): a small warm halo and the little pool on the bank, fainter than
    fix round 1's (it read as a white lamp at night)."""
    im = PA.Image(22, 22)
    cx, cy = 10.5, 5.5
    for y in range(22):
        for x in range(22):
            d = math.hypot(x - cx, (y - cy) * 1.1) / 7.0
            a = 0.0
            if d < 1:
                a = 0.34 * (1 - d) ** 2.0
            if y >= 19:
                dd = math.hypot((x - cx) / 6.0, (y - 20.5) / 1.5)
                if dd < 1:
                    a = max(a, 0.3 * (1 - dd) ** 1.5)
            if a > 0.03:
                im.set(x, y, white(a))
    return im


# --------------------------------------------------------------------------------------------- high 4: the postern
def postern_night_view():
    """The passage's far view at night (10 x 14, laid over posternT1-T3 cols 95-104, rows 4-17): the sky deep blue at
    the top, the far hills a step darker, the meadow a faint band, the lane's end; drawn over the painted day view by
    the night's share, so through the postern the valley is never brighter than the valley beside it."""
    im = PA.Image(10, 14)
    for y in range(14):
        for x in range(10):
            if y < 6:
                nm = "nightBlue" if y < 3 else "farDeep"
            elif y < 9:
                nm = "nightSlate" if h01(651, x, y) < 0.7 else "farDeep"
            elif y < 12:
                nm = "leafDark" if (x + y) % 3 else "leafDeep"
            else:
                nm = "soilDark"
            put(im, x, y, nm)
    return im


# --------------------------------------------------------------------------------------------- high 8: ground fog
FOG_W, FOG_H = 160, 28


def gloom_ground_fog():
    """2 frames of 160 x 28 side by side (the bottom 6 rows under the ground line): a cold low mist, densest at the
    ground, thinning upward in alpha steps to a top of soft billows 16 to 22 rows over the line; frame 0 repeats
    seamlessly, frame 1 is its leading face (the billows lower and thinner toward the right, out in long tongues)."""
    im = PA.Image(FOG_W * 2, FOG_H)
    ground = FOG_H - 6
    for f in range(2):
        for x in range(FOG_W):
            top = 18 + 2.2 * math.sin(2 * math.pi * x / 40.0) + 1.6 * math.sin(2 * math.pi * x / 32.0 + 1.3) \
                + 1.2 * (h01(671, x // 4) - 0.5)
            face = 1.0
            if f == 1:
                face = max(0.0, 1 - (x / float(FOG_W)) ** 1.6)
                top = 4 + (top - 4) * face
            for y in range(FOG_H):
                up = ground - y
                if up > top:
                    continue
                depth = (top - up) / max(1.0, top)
                a = 0.14 + 0.6 * depth ** 0.8
                if y >= ground:
                    a = 0.74 - 0.08 * (y - ground)
                if f == 1:
                    a *= face
                nm = "mist" if up > top - 2.5 else "mistDark" if depth < 0.55 else "far"   # cold, a step over the haze
                kk = max(0, min(16, int(a * 16 + 0.5)))
                if kk:
                    r, g, b, _ = col(nm)
                    im.set(f * FOG_W + x, y, (r, g, b, 16 * kk))
    return im


# --------------------------------------------------------------------------------------------- the verge
def valley_verge(seed=561, variant=0):
    """As fix round 1's verge, but its stones at gaps that never repeat in a row (3 to 17 px, drawn from a hash),
    three sizes, some sunk."""
    base = F1.valley_verge(521 if variant == 0 else 547, variant)
    im = PA.Image(base.w, base.h)
    stone_names = {"stone", "stoneMid", "stoneDark", "stoneLight", "stonePale", "rock", "rockDark", "rockLight",
                   "rockDeep"}
    for y in range(base.h):
        for x in range(base.w):
            p = base.get(x, y)
            if p[3] and name_at(base, x, y) not in stone_names:
                im.set(x, y, p)
    x = 1 + int(3 * h01(seed, 1))
    i = 0
    while x < base.w - 3:
        kind = h01(seed, i, 2)
        sw, sh = (6, 3) if kind < 0.25 else (3, 2) if kind < 0.65 else (2, 1)
        sunk = h01(seed, i, 3) < 0.35
        y_top = 4 - sh + (1 if sunk else 0)
        for yy in range(y_top, 5):
            for xx in range(x, min(base.w, x + sw)):
                if yy == y_top:
                    nm = "stoneLight" if xx < x + sw - 1 else "stone"
                elif xx == x + sw - 1:
                    nm = "stoneDark"
                else:
                    nm = "stone" if yy < 4 else "stoneMid"
                put(im, xx, yy, nm)
        if x + sw < base.w:
            put(im, x + sw, 4, "soilDark")
        x += sw + 3 + int(14 * h01(seed, i, 4) ** 1.3)
        i += 1
    return im


def old_wall_one():
    """Oriel's first line before the gatehouse (84 x 60, tools/w3f2src): its stepped blocks read as grey cubes at the
    Throat's end (the critic, w-1000-dusk). The steps' outer corners are knocked off twice (rounded), every top is
    chipped 0 to 2 rows by a hash so no top runs straight, the new tops take the old top's light, and heaps of rubble
    lean on the foot of the low wall and the stump."""
    im = src2("oldWall1")
    w, h = im.w, im.h

    def op(img, x, y):
        return 0 <= x < w and 0 <= y < h and img.get(x, y)[3] > 0

    tops = {}
    for x in range(w):
        ys = [y for y in range(h) if op(im, x, y)]
        if ys:
            tops[x] = (min(ys), im.get(x, min(ys)))
    for _ in range(2):                                 # round the outer corners
        out = copy(im)
        for y in range(h - 8):
            for x in range(w):
                if not op(im, x, y) or op(im, x, y - 1):
                    continue
                if not op(im, x - 1, y) or not op(im, x + 1, y):
                    out.set(x, y, CLEAR)
        im = out
    out = copy(im)
    for x in range(w):                                 # chip every top a little
        ys = [y for y in range(h - 8) if op(im, x, y)]
        if not ys:
            continue
        chip = int(3 * h01(733, x // 2)) - 1
        for k in range(max(0, chip)):
            out.set(x, min(ys) + k, CLEAR)
    im = out
    for x in range(w):                                 # the new tops keep the light
        ys = [y for y in range(h) if op(im, x, y)]
        if ys and x in tops and min(ys) > tops[x][0] and min(ys) < h - 8:
            im.set(x, min(ys), tops[x][1])
    heaps = [(0, 30, 8, 10), (60, 84, 6, 20)]          # (x0, x1, height, peak offset from x0)
    for hi, (x0, x1, hh, peak) in enumerate(heaps):
        for x in range(x0, x1):
            d = abs(x - (x0 + peak)) / float(max(peak, x1 - x0 - peak))
            top = int(hh * max(0.0, 1 - d) ** 1.3 + h01(741, hi, x) * 1.5)
            for k in range(top):
                y = h - 9 - k
                if op(im, x, y):
                    continue
                v = h01(743, x, y)
                nm = "stoneLight" if k == top - 1 and v < 0.6 else "stone" if v < 0.45 else "stoneMid" \
                    if v < 0.8 else "stoneDark"
                if v > 0.93:
                    nm = "leaf"
                put(im, x, y, nm)
    return im


def gate_rock(name):
    """The gate rocks at the gatehouse's feet (tools/w3f2src): their lit edge in broken pieces still read as a cream cut
    line up the slope at night and at noon (t-3-1360, w-1200-noon), the same sticker line the critic took off the
    buttress: the edge's `rockPale` a step down to `rockLight`, its `stoneLight` to `stone`, so the edge is a lit face
    of the rock, not a stroke round it."""
    im = src2(name)
    for y in range(im.h):
        for x in range(im.w):
            nm = name_at(im, x, y)
            if nm == "rockPale":
                put(im, x, y, "rockLight")
            elif nm == "stoneLight":
                put(im, x, y, "stone")
    return im


def darkness_bank_glow():
    """The bank's eyes (4 frames of 9 x 3, tools/w3f2src): the near pair open (frame 0) was two 3 x 3 crosses, a
    "+" glyph at phone size; now each eye an almond, a bright core between two dimmer pixels with a faint lid over
    it. The other frames as they were."""
    im = src2("darknessBankGlow")
    for y in range(3):
        for x in range(9):
            im.set(x, y, CLEAR)
    for ex in (0, 6):
        im.set(ex, 1, white(0.62))
        im.set(ex + 1, 1, white(1.0))
        im.set(ex + 2, 1, white(0.62))
        im.set(ex + 1, 0, white(0.3))
    return im


BUILDERS = {
    "throatButtress": throat_buttress,
    "beaconTower": lambda: beacon_tower()[0],
    "beaconRuinRim": lambda: stage_rim("beaconRuin"),
    "beaconBaseRim": lambda: stage_rim("beaconBase"),
    "beaconTowerRim": lambda: stage_rim("beaconTower"),
    "greatBeaconRim": lambda: stage_rim("greatBeacon"),
    "castleFront": castle_front,
    "castleFront3": lambda: castle_front3("castleFront3"),
    "castleFront3Build": lambda: castle_front3("castleFront3Build"),
    "watchtower": watchtower,
    "cloudA": lambda: cloud_underside("cloudA", 701),
    "cloudB": lambda: cloud_underside("cloudB", 707),
    "cloudC": lambda: cloud_underside("cloudC", 709),
    "riverSkiffMoored": river_skiff_moored,
    "riverSkiffRim": river_skiff_rim,
    "riverLanternStreak": river_lantern_streak,
    "riverLanternHalo": river_lantern_halo,
    "posternNightView": postern_night_view,
    "gloomGroundFog": gloom_ground_fog,
    "darknessBankGlow": darkness_bank_glow,
    "gateRockL": lambda: gate_rock("gateRockL"),
    "gateRockR": lambda: gate_rock("gateRockR"),
    "oldWall1": old_wall_one,
    "valleyVerge": lambda: valley_verge(561, 0),
    "valleyVergeB": lambda: valley_verge(587, 1),
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
