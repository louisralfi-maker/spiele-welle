#!/usr/bin/env python3
"""Lanternhold world lane, step world-3, fix round 1 (15.11.2026; DESIGN.md "World rebuild (14.11.2026)", ART-look2.md
section 27, the critic's look 1 of world-3). Pure python on pixelart.py's Image, palette colours only, hashes of the
position instead of randomness, so a run reproduces its files byte for byte. Passes over existing sprites read their
untouched sources from tools/w3src.

  beaconRuin        64x130   the ruin's crown (blocker 3): no stem, no bar: a squat cold iron bowl seated low in the
        broken top between the broken merlons (a dark rim ellipse 3 px thick, a cold highlight on its right lip, grey
        ash heaped in it, a crack in the rim)
  beaconTower       64x130   the tower stage: the builders' crane over the crown (a bar on a post with a diagonal jib,
        "a gallows" at night) is gone; the scaffold keeps its posts and ledger below the parapet; the squat bowl sits
        in the crenels
  greatBeacon       64x130   the built beacon (high 5): the great bowl in three value steps with a lit side, its rim an
        ellipse (the mouth dark, ash at the back), two iron hoops that curve with the bowl; the slits with a dark reveal
  beaconRuinRim .. greatBeaconRim   64x130  emissive: the moon on each stage as a 2 to 3 px band of lit stone faces
        on its right, broken by the joints and by missing stones, and a faint wash on the face toward it; no outline
        on the left or the top (blocker 3: "a sticker's cut line")
  bakehouse         100x62   the oven's dome a value step down (high 6: a pale grey ring round the hatch at noon)
  riverLanding      72x20    a short timber landing from the bank's end over the water to the old bridge's first stump
        (blocker 2: the lord stood on the water), its deck the lane's height, a bollard at its end, the posts in the water
  riverSkiffMoored  34x8     the skiff tied alongside the landing, its painter rope up to the deck
  riverSkiffRim     34x8     emissive: the moon on the skiff's gunwale (high 8)
  riverLanternHalo  22x22    emissive: the far lantern's warm halo round its glass and its little pool on the bank
  riverLanternStreak 9x24    emissive: its broken reflection on the water (drawn on the water, after the world plane)
  throatButtress    96x132   near plane: a buttress of the Throat's granite with its scree fan (high 9), darker and
        cooler than the even cliff behind it
  valleyVerge, valleyVergeB  64x10  the valley lane's verge (high 10): stones of three sizes at gaps of two to five
        times, some sunk in the grass, roots; B a second painting so the row never repeats in 128 px

  w3f1art.py build <id> [<id> ...] --out <Resources/Art>
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

col, h01 = WA.col, WA.h01
put, name_at, src, copy, white = W3.put, W3.name_at, W3.src, W3.copy, W3.white
CLEAR = (0, 0, 0, 0)
ART = os.path.join(HERE, "..", "Resources", "Art")
INK = "ink"


def wa(name, a):
    """Palette colour `name` at alpha `a` in sixteenths."""
    r, g, b, _ = col(name)
    k = max(0, min(16, int(a * 16 + 0.5)))
    return (r, g, b, min(255, 16 * k)) if k else CLEAR


# --------------------------------------------------------------------------------------------- the squat bowl
def squat_bowl(im, cx, rim_y, rx, depth, crack=False, seed=1):
    """A squat cold iron bowl seen a little from above, painted onto `im`: the rim an ellipse (outer half-height 2.6,
    the ring 3 px thick at its ends), the mouth full of grey ash heaped a row or two over the back lip, the body under
    the front lip `depth` rows deep and narrowing to 0.7 of the rim, in three steps of iron (lit on the left, the
    shadow on the right), an iron band, an ink outline; a cold highlight on the right lip. Returns the painted set."""
    painted = set()
    ry_out, ry_in = 2.6, 1.3
    rin = rx - 3.0

    def setp(x, y, nm):
        if 0 <= x < im.w and 0 <= y < im.h:
            put(im, x, y, nm)
            painted.add((x, y))

    # the body: from the rim's centre line down
    for k in range(1, depth + 1):
        y = rim_y + k
        half = rx - (rx * 0.3) * (k / float(depth)) ** 1.4
        a, b = int(round(cx - half)), int(round(cx + half))
        for x in range(a, b + 1):
            t = (x - a) / float(max(1, b - a))
            nm = "stoneMid" if t < 0.28 else "stoneDark" if t < 0.72 else "night1"
            if k == max(2, depth // 2):
                nm = "night1" if t < 0.72 else INK           # the iron band
            if k == depth:
                nm = "stoneDark" if t < 0.5 else "night1"
            setp(x, y, nm)
        setp(a - 1, y, INK)
        setp(b + 1, y, INK)
    for x in range(int(round(cx - rx * 0.7)), int(round(cx + rx * 0.7)) + 1):
        setp(x, rim_y + depth + 1, INK)
    # the rim: outer ellipse minus the mouth
    for y in range(int(rim_y - ry_out) - 1, int(rim_y + ry_out) + 2):
        for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
            u, v = (x - cx) / rx, (y - rim_y) / ry_out
            if u * u + v * v > 1.0:
                continue
            ui, vi = (x - cx) / rin, (y - rim_y) / ry_in
            inside = ui * ui + vi * vi <= 1.0
            if inside:
                continue
            t = (x - (cx - rx)) / (2 * rx)
            front = y >= rim_y
            if t < 0.3:
                nm = "stone" if not front else "stoneMid"
            elif t < 0.72:
                nm = "stoneMid" if not front else "stoneDark"
            else:
                nm = "stoneDark" if not front else "night1"
            if crack and abs(x - (cx + rx * 0.55)) < 1.0 and not front:
                nm = INK
            setp(x, y, nm)
    # the mouth: grey ash, heaped toward the middle, a row over the back lip there
    for y in range(int(rim_y - ry_in) - 2, int(rim_y + ry_in) + 1):
        for x in range(int(cx - rin), int(cx + rin) + 1):
            ui, vi = (x - cx) / rin, (y - rim_y) / ry_in
            heap = 1.0 + 1.6 * max(0.0, 1 - abs(x - cx) / (rin * 0.75))
            if ui * ui + (vi if vi > 0 else vi / heap) ** 2 > 1.0:
                continue
            v = h01(seed, x, y, 31)
            nm = "stonePale" if v < 0.22 else "stoneLight" if v < 0.75 else "stone"
            if y >= rim_y + ry_in - 0.5:
                nm = "stone" if v < 0.6 else "stoneMid"      # the front lip's shadow on the ash
            setp(x, y, nm)
    # outline the top of the heap and the rim's back
    for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
        for y in range(0, im.h - 1):
            if (x, y + 1) in painted and (x, y) not in painted:
                if 0 <= x < im.w and (not im.get(x, y)[3] or y < rim_y - 1):
                    setp(x, y, INK)
                break
    for side in (-1, 1):
        for y in range(int(rim_y - ry_out) - 1, int(rim_y + ry_out) + 2):
            xs = [x for (x, yy) in painted if yy == y]
            if xs:
                x = (min(xs) - 1) if side < 0 else (max(xs) + 1)
                if (x, y) not in painted:
                    setp(x, y, INK)
    # the cold highlight on the right lip (the moon stands high in the east)
    for i in range(3):
        x = int(round(cx + rx * 0.62)) + i
        y = int(round(rim_y - ry_out * 0.75)) + (1 if i == 2 else 0)
        setp(x, y, "mistLight" if i < 2 else "stoneLight")
    return painted


def restamp(im, base, keep):
    """Puts `base`'s pixels back over `im` wherever `keep(x, y, name)` says they stand in front."""
    for y in range(im.h):
        for x in range(im.w):
            p = base.get(x, y)
            if p[3] and keep(x, y, name_at(base, x, y)):
                im.set(x, y, p)


# --------------------------------------------------------------------------------------------- the beacon's stages
def beacon_ruin():
    """The ruin: the old fire cage taken out (as world-3 did), no stem: the squat bowl seated low in the hollow of the
    broken top, between the broken merlons (cols 9-17 and 39-50), its foot behind the hollow's front lip (row 33)."""
    base = src("beaconRuin")
    im = copy(base)
    cage = {"ink", "night0", "night1", "stoneMid", "stoneDark"}
    for y in range(0, 29):
        for x in range(18, 43):
            if name_at(im, x, y) in cage:
                im.set(x, y, CLEAR)
    for y in range(29, 33):
        for x in range(21, 39):
            if name_at(im, x, y) in ("ink", "night1"):
                im.set(x, y, col("night0"))
    squat_bowl(im, 29.0, 23, 11.0, 8, crack=True, seed=71)
    # the broken merlons and the hollow's front lip stand in front of the bowl
    restamp(im, base, lambda x, y, nm: (y >= 33) or (x <= 18 and y >= 22) or (x >= 39 and y >= 26))
    return im


def beacon_tower():
    """The tower stage: the builders' timber is gone (the crane over the crown, "a gallows" at night, and with it the
    scaffold's posts, ledger and braces, which drew a frame round the crown; a stage being built shows the scaffold
    props of its own): timber outside the tower's stone is cleared, timber over its face takes the stone of the
    nearest course; the squat bowl sits in the crenels (merlons at cols 12-20, 27-34, 41-45, rows 25-28), seen
    through the gaps and over the merlons."""
    base = src("beaconTower")
    im = copy(base)
    timber = {"woodLight", "woodDark", "wood", "straw", "strawLight"}

    def is_timber(x, y):
        if y >= 100:          # the door at the foot stays
            return False
        nm = name_at(base, x, y)
        if nm in timber:
            return True
        if nm == "ink":       # the timber's own outline: ink with timber beside it and no stone
            near = [name_at(base, x + dx, y + dy) for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))
                    if 0 <= x + dx < base.w and 0 <= y + dy < base.h]
            stone = sum(1 for n in near if n and n.startswith("stone"))
            wood = sum(1 for n in near if n in timber)
            return wood > 0 and stone == 0
        return False

    def stone_at(x, y):
        nm = name_at(base, x, y)
        return nm is not None and not is_timber(x, y) and (nm.startswith("stone") or nm in ("night0", "night1"))

    spans = {}
    for y in range(base.h):
        xs = [x for x in range(base.w) if stone_at(x, y)]
        if xs:
            spans[y] = (min(xs), max(xs))
    for y in range(base.h):
        if y not in spans:
            near = [yy for yy in spans if abs(yy - y) <= 4]
            if near:
                spans[y] = spans[min(near, key=lambda yy: (abs(yy - y), -yy))]
    for y in range(base.h):
        lo, hi = spans.get(y, (99, -1))
        for x in range(base.w):
            if not is_timber(x, y):
                continue
            if lo <= x <= hi and y >= 25:
                # over the face: the stone of the nearest course in this column (below first), else in this row
                done = False
                for d in range(1, 6):
                    for yy in (y + d, y - d):
                        if 0 <= yy < base.h and stone_at(x, yy):
                            im.set(x, y, base.get(x, yy))
                            done = True
                            break
                    if done:
                        break
                if not done:
                    for d in range(1, 8):
                        for xx in (x - d, x + d):
                            if 0 <= xx < base.w and stone_at(xx, y):
                                im.set(x, y, base.get(xx, y))
                                done = True
                                break
                        if done:
                            break
                if not done:
                    im.set(x, y, col("stoneMid"))
            else:
                im.set(x, y, CLEAR)
    for y in range(0, 34):                         # the jib's iron tip, the hoisted stone and its rope
        for x in range(base.w):
            if y < 25 or x >= 53:
                im.set(x, y, CLEAR)
    # the tower's outline where the posts stood beside it: ink on the first transparent pixel right of the stone
    for y in range(25, base.h):
        xs = [x for x in range(base.w) if im.get(x, y)[3]]
        if xs:
            r = max(xs)
            if name_at(im, r, y) != INK and r + 1 < base.w:
                put(im, r + 1, y, INK)
    after = copy(im)
    squat_bowl(im, 31.0, 18, 12.0, 9, crack=False, seed=73)
    # the merlons (rows 25-28) and the parapet under them stand in front of the bowl's foot
    restamp(im, after, lambda x, y, nm: y >= 25)
    return im


def great_beacon():
    """The built beacon's great bowl (rows 3-20 of its silhouette) repainted: the rim an ellipse (the mouth dark with
    grey ash at its back, the ring lit on the left, a cold highlight on its right lip), the body in three steps of
    iron (the lit side on the left, the shadow side on the right) with two hoops that curve with it and a few rivets;
    the slits (cols 23-24 rows 66-74, cols 38-39 rows 89-96) get a dark reveal so their glow sits in the wall."""
    base = src("greatBeacon")
    im = copy(base)
    cx = 31.0
    # the silhouette's half-width per row, from the source (its opaque run)
    runs = {}
    for y in range(3, 21):
        xs = [x for x in range(im.w) if base.get(x, y)[3] and name_at(base, x, y) != "banner"]
        if xs:
            runs[y] = (min(xs), max(xs))
    rim_y, rx = 5.0, 26.5
    ry_out, ry_in = 2.6, 1.5
    rin = rx - 3.2
    for y in range(3, 21):
        if y not in runs:
            continue
        a, b = runs[y]
        for x in range(a + 1, b):
            t = (x - a) / float(max(1, b - a))
            u, v = (x - cx) / rx, (y - rim_y) / ry_out
            ui, vi = (x - cx) / rin, (y - rim_y) / ry_in
            if ui * ui + vi * vi <= 1.0:
                # the mouth: dark, the back's ash catching a little light
                nm = "night0" if y > rim_y - 0.5 else ("stone" if h01(91, x) < 0.5 else "stoneMid")
                if y <= rim_y - ry_in + 0.6:
                    nm = "stoneMid" if h01(92, x) < 0.6 else "stone"
            elif u * u + v * v <= 1.0:
                front = y >= rim_y
                if front:                                 # the front lip, lit along its top
                    nm = "stoneLight" if t < 0.3 else "stone" if t < 0.68 else "stoneMid"
                    if y >= rim_y + 1.5:
                        nm = "stone" if t < 0.3 else "stoneMid" if t < 0.68 else "stoneDark"
                else:                                     # the back of the rim, its inside face in shade
                    nm = "stone" if t < 0.3 else "stoneMid" if t < 0.7 else "stoneDark"
                    if 0.78 < t < 0.88:
                        nm = "mistLight"                  # the cold highlight on the right lip
            else:
                # the body: a rounded value turn across it (lit left, shadow right), one hoop with its highlight
                if t < 0.1:
                    nm = "stoneLight"
                elif t < 0.36:
                    nm = "stone"
                elif t < 0.64:
                    nm = "stoneMid"
                elif t < 0.86:
                    nm = "stoneDark"
                else:
                    nm = "night1"
                sag = 1 if 0.3 < t < 0.7 else 0
                if y >= 17 and t > 0.84:
                    nm = "stoneDark"                      # the reflected light under its belly
                if y == 13 + sag:
                    nm = "stoneDark" if t < 0.36 else "night1" if t < 0.86 else "night0"   # the hoop
                elif y == 12 + sag and t < 0.6:
                    nm = "stoneLight" if t < 0.36 else "stone"                            # its lit top
                if y == 8 + sag and t < 0.86:
                    nm = "stoneMid" if t < 0.36 else "stoneDark"   # the rim's shadow under the lip
                if y >= 18:
                    nm = {"stoneLight": "stone", "stone": "stoneMid", "stoneMid": "stoneDark"}.get(nm, nm)
            put(im, x, y, nm)
    # the slits' reveal: one row over, one column to the left, dark
    for (x0, y0, w, h) in ((23, 66, 2, 9), (38, 89, 2, 8)):
        for y in range(y0, y0 + h):
            for x in range(x0, x0 + w):
                put(im, x, y, "night0")
        for y in range(y0 - 1, y0 + h + 1):
            put(im, x0 - 1, y, "night1")
        for x in range(x0 - 1, x0 + w + 1):
            put(im, x, y0 - 1, "night1")
            put(im, x, y0 + h, "stoneMid")
    return im


def moon_band(im):
    """Emissive (white × the moon's colour in the engine): the moon stands high to the east, so each row's
    eastmost run of stone takes a band 2 or 3 px wide (by its stone), lit only on stone faces (a joint, ink and the
    dark between stones break it), with now and then a whole stone left out (missing, or in shadow); the face toward
    the moon takes a faint wash one level per painted stone. No outline on the left or the top."""
    out = PA.Image(im.w, im.h)
    edge = {None, "ink", "night0"}
    faces = {"stonePale", "stoneLight", "stone", "stoneMid", "stoneDark", "plaster", "parchment", "mistLight",
             "woodLight", "wood", "straw", "strawLight", "banner", "roofLight"}

    def luma(x, y):
        p = im.get(x, y)
        return (0.299 * p[0] + 0.587 * p[1] + 0.114 * p[2]) if p[3] else 0.0

    def joint(x, y):
        """A mortar line or a vertical joint: darker than both its neighbours above and below, or left and right."""
        l = luma(x, y)
        up, down = luma(x, y - 1) if y > 0 else 999, luma(x, y + 1) if y + 1 < im.h else 999
        left = luma(x - 1, y) if x > 0 else 999
        return (l + 6 < up and l + 6 < down) or (l + 6 < left and name_at(im, x + 1, y) in edge)

    def solid(x, y):
        return 0 <= x < im.w and 0 <= y < im.h and name_at(im, x, y) not in edge

    clusters = W3.clusters_x(im, solid)
    for y in range(im.h):
        xs = [x for x in range(im.w) if solid(x, y)]
        if not xs:
            continue
        right = max(xs)
        mid = clusters.get((right, y), right)
        width = 2 if h01(171, int(mid), y // 3) < 0.5 else 3
        missing = h01(172, int(mid), y // 3) < 0.22
        for i in range(width):
            x = right - i
            if not solid(x, y) or missing:
                break
            nm = name_at(im, x, y)
            if nm not in faces or joint(x, y):
                continue                                    # a joint breaks the band
            a = (0.72, 0.44, 0.24)[i]
            if nm in ("banner", "wood", "woodLight", "straw", "strawLight"):
                a *= 0.6
            out.set(x, y, white(a))
    for (x, y), mid in clusters.items():
        if out.get(x, y)[3]:
            continue
        nm = name_at(im, x, y)
        if nm not in ("stonePale", "stoneLight", "stone", "stoneMid"):
            continue
        k = (mid / float(im.w) - 0.45) / 0.55
        if k > 0:
            a = round(0.14 * k * 16) / 16.0
            if a > 0:
                out.set(x, y, white(a))
    return out


def stage_rim(name):
    painters = {"beaconRuin": beacon_ruin, "beaconTower": beacon_tower, "greatBeacon": great_beacon}
    im = painters[name]() if name in painters else PA.read_png(os.path.join(ART, name + ".png"))[0]
    return moon_band(im)


# --------------------------------------------------------------------------------------------- the bakehouse
def bakehouse():
    """The oven's dome a value step down (high 6: at noon its pale stoneLight read as a grey ring round the hatch):
    on the dome (cols 5-14, its lowest 22 rows) three of four stoneLight stones take stone; a few keep the light on
    its upper left. The hatch, its sill and the wall stay."""
    im = src("bakehouse")
    for y in range(im.h - 22, im.h):
        for x in range(5, 15):
            if name_at(im, x, y) == "stoneLight":
                row = im.h - 1 - y
                keep = h01(611, x // 3, row // 3) < 0.25 and row > 12 and x < 10
                if not keep:
                    put(im, x, y, "stone")
    return im


# --------------------------------------------------------------------------------------------- the river end
LAND_W, LAND_H = 72, 20
DECK = 4          # the deck's top row (the lane's y -1)
WATER = 8         # the water's row (y -5)
POSTS = (19, 37, 55, 69)


def river_landing():
    """The landing (72 x 20, its bottom at y -16, so its row 4 is the lane's top row y -1): a stone footing on the
    bank (cols 0-7), the deck of planks (rows 4-6: lit plank tops, the side with its joints, the shadow under it), a
    beam under it, four posts down into the water (above it wood, under it dark and fading, a pale ripple at the
    waterline either side), a bollard at the end with the painter's turns of rope, the old bridge's stump beyond."""
    im = PA.Image(LAND_W, LAND_H)
    # the footing on the bank: two courses of rough stone under the deck's end, a tuft over its corner
    for y in range(DECK + 3, DECK + 7):
        for x in range(1, 7):
            v = h01(301, x // 3, y // 2)
            nm = "stone" if (y - DECK) % 2 == 1 and x % 3 else "stoneMid" if v < 0.6 else "stoneDark"
            if x == 6:
                nm = "stoneDark"
            put(im, x, y, nm)
    for x in range(0, 8):
        put(im, x, DECK + 7, "soilDark")
    for x, nm in ((0, "leaf"), (1, "leafLight"), (2, "meadow")):
        put(im, x, DECK + 3, nm)
    # posts
    for p in POSTS:
        for y in range(DECK + 3, LAND_H):
            under = y > WATER
            if not under:
                put(im, p, y, "wood")
                put(im, p + 1, y, "woodDark")
            else:
                fade = max(0.0, 0.62 - 0.07 * (y - WATER))
                im.set(p, y, wa("woodDark", fade))
                im.set(p + 1, y, wa("night1", fade))
        for dx in (-2, -1, 2, 3):                       # the ripple at the waterline
            if 0 <= p + dx < LAND_W:
                im.set(p + dx, WATER + 1, wa("mistLight", 0.5 if dx in (-1, 2) else 0.25))
    # the deck: plank tops, side with joints, shadow
    for x in range(0, LAND_W):
        put(im, x, DECK, "woodLight" if h01(303, x // 6) < 0.7 else "wood")
        put(im, x, DECK + 1, "wood" if (x + 3) % 7 else "woodDark")
        put(im, x, DECK + 2, "woodDark")
    for x in range(0, LAND_W):
        if x % 7 == 4:
            put(im, x, DECK, "wood")                    # the plank ends on top
    put(im, LAND_W - 1, DECK + 1, INK)
    put(im, LAND_W - 1, DECK + 2, INK)
    # the beam under the deck, between the posts
    for x in range(8, LAND_W - 1):
        put(im, x, DECK + 3, "night1" if x % 9 else "woodDark")
    # the bollard at the end, with the painter's turns of rope
    bx = 65
    for y in range(0, DECK):
        put(im, bx, y, "wood")
        put(im, bx + 1, y, "woodDark")
        put(im, bx + 2, y, INK)
    put(im, bx, 0, "woodLight")
    put(im, bx + 1, 0, "wood")
    put(im, bx - 1, 1, INK)
    for x in (bx - 1, bx, bx + 1, bx + 2):
        put(im, x, 2, "straw" if x < bx + 2 else "strawLight")
    put(im, bx - 1, 3, "straw")
    return im


def river_skiff_moored():
    """The skiff alongside the landing (34 x 9; its bottom at y -12, so its sheer's middle stands at y -6 and its ends
    rise to y -4): the sheer curving up to the stem (left) and the stern (right), the lit sheer strake under it, a
    clinker strake, the tarred bottom strake, a stem post and a stern post, an oar's loom over the gunwale; under the
    waterline (row 6) the hull dark and fading into the water."""
    im = PA.Image(34, 9)
    def sheer(x):          # the gunwale's row: highest at the ends
        t = (x - 16.5) / 16.5
        return int(round(2.6 - 2.4 * t * t))
    for x in range(1, 33):
        g = sheer(x)
        bottom = 6 if 3 <= x <= 30 else 5 if 2 <= x <= 31 else 4
        for y in range(g, bottom + 1):
            k = y - g
            if k == 0:
                nm = "woodLight" if x < 24 else "wood"
            elif k == 1:
                nm = "wood" if x < 20 else "woodDark"
            elif y < 6:
                nm = "woodDark" if (x + y) % 6 else "night1"
            else:
                nm = None
            if nm:
                put(im, x, y, nm)
        for y in range(6, 9):
            if 3 <= x <= 30 and y >= 6:
                im.set(x, y, wa("night1", max(0.2, 0.75 - 0.22 * (y - 6))))
        put(im, x, g - 1, INK) if g >= 1 else None
    for y in range(0, 6):                             # the stem and the stern post
        put(im, 0, y, INK) if y < 5 else None
        put(im, 33, y, INK) if y < 5 else None
    put(im, 1, 0, "woodLight")
    put(im, 32, 0, "wood")
    for i, x in enumerate(range(9, 21)):              # an oar's loom lying over the gunwale
        y = sheer(x) - 1
        put(im, x, y, "woodLight" if i % 4 else "wood")
    for x in range(3, 31):                            # the waterline's pale lap
        if x % 3:
            im.set(x, 6, wa("mistLight", 0.44))
    return im


def river_skiff_rim():
    """Emissive: the moon on the skiff's gunwale (its top row) and on the stem head and the stern post."""
    im = river_skiff_moored()
    out = PA.Image(im.w, im.h)
    for x in range(im.w):
        for y in range(im.h):
            nm = name_at(im, x, y)
            if nm in ("woodLight", "wood") and (y == 0 or name_at(im, x, y - 1) in (None, INK)):
                out.set(x, y, white(0.55 if x > 14 else 0.38))    # the gunwale's top, brighter toward the moon
                break
    return out


def river_lantern_halo():
    """Emissive (22 x 22, centred on the far lantern's glass at its dx 9.5, dy 15.5): a warm round halo falling off
    from the glass, and the little pool its light lays on the bank at the post's foot (rows 19-21), alpha in
    sixteenths."""
    im = PA.Image(22, 22)
    cx, cy = 10.5, 5.5
    for y in range(22):
        for x in range(22):
            d = math.hypot(x - cx, (y - cy) * 1.1) / 9.0
            a = 0.0
            if d < 1:
                a = 0.5 * (1 - d) ** 1.8
            if y >= 19:
                dd = math.hypot((x - cx) / 7.0, (y - 20.5) / 1.6)
                if dd < 1:
                    a = max(a, 0.45 * (1 - dd) ** 1.5)
            if a > 0.03:
                im.set(x, y, white(a))
    return im


def river_lantern_streak():
    """Emissive (9 x 24): the lantern's reflection on the water, broken horizontal dashes under it (one row in two
    or three), widest and brightest near the shore, shifting a pixel this way or that, thinning and parting downward."""
    im = PA.Image(9, 24)
    for y in range(24):
        if h01(401, y) < 0.45 and y > 1:
            continue
        half = 2.4 - 1.9 * y / 23.0
        off = (h01(402, y) - 0.5) * 2.4
        a = 0.6 * (1 - y / 25.0) ** 1.4
        for x in range(9):
            dx = abs(x - 4 - off)
            if dx <= half:
                k = 1 - dx / (half + 1)
                im.set(x, y, white(a * (0.45 + 0.55 * k)))
    return im


# --------------------------------------------------------------------------------------------- the Throat
BUT_W, BUT_H = 96, 132


def throat_buttress():
    """A buttress of the Throat's granite on the near plane (96 x 132, the ground line its bottom row): a tall leaning
    rib of rock rising to row 6 at its crest (left of the middle), shouldering down to the right, creased faces and a
    few ledges, painted on the cool slate ramp a step darker than the mid plane's cliff; a fan of scree spilling from
    its foot to the right, stones of three sizes, the light from the upper left."""
    w, h = BUT_W, BUT_H
    gx0, seed = 6400, 6417
    pts = [(0, 0), (4, 24), (8, 50), (11, 68), (14, 82), (17, 96), (19, 102), (21, 100), (24, 108), (27, 112),
           (30, 111), (33, 113), (37, 110), (40, 104), (43, 106), (47, 98), (50, 90), (53, 92), (57, 80), (61, 70),
           (64, 72), (68, 58), (72, 46), (77, 38), (82, 26), (87, 16), (91, 8), (95, 0)]
    prof = [(gx0 + x, y) for x, y in pts]

    def top(gx):
        for (xa, ya), (xb, yb) in zip(prof, prof[1:]):
            if xa <= gx <= xb:
                t = (gx - xa) / float(max(1, xb - xa))
                hg = ya + (yb - ya) * t
                break
        else:
            hg = 0.0
        hg += 1.6 * (h01(seed, int(gx // 3)) - 0.5)
        return h - max(0.0, hg) if hg > 1 else h + 1

    spots = []
    for i in range(8):
        x0 = gx0 + 8 + (w - 30) * h01(seed, i, 301)
        row = h - 14 - 90 * h01(seed, i, 302)
        spots.append((x0, x0 + 6 + 9 * h01(seed, i, 303), row, 2.6, 1.6, (h01(seed, i, 304) - 0.5) * 0.4))
    RF.RAMPS["buttress"] = ["nightSlate", "stoneDark", "stoneMid", "stone", "mistDark", "rockLight"]
    RF.SNOW["buttress"] = RF.SNOW["footing"]
    massif = RF.Massif(seed, gx0 - 40, gx0 + w + 40, h, 18, 40, relief=0.8, ledge_gap=(12, 22), sheets=False,
                       facets=0.3, chimneys=0.2, swell=2.0, pieces=True, crease=True, spots=spots, ledge_max=12,
                       face_relief=2.0, cracks=0.45)
    field = RF.Field(massif, gx0, w, h, top, margin=24)
    img = RF.paint(field, "buttress", gain=0.9, rim=0.0, seed=seed, contrast=1.1, lit_rim=True, clamp=0.6,
                   rim_broken=True)
    # the scree fan at its foot, spilling to the right
    k = 0
    for i in range(70):
        u = h01(seed, i, 501)
        x = int(18 + 76 * u ** 0.8)
        spread = 1 - (x - 18) / 78.0
        y = h - 1 - int(10 * spread * h01(seed, i, 502))
        size = 1 if h01(seed, i, 503) < 0.55 else 2 if h01(seed, i, 503) < 0.88 else 3
        for dy in range(size):
            for dx in range(size + 1):
                xx, yy = x + dx, y - dy
                if 0 <= xx < w and 0 <= yy < h:
                    nm = "stone" if dy == size - 1 and dx < size else "stoneMid" if dx < size else "stoneDark"
                    if size == 1:
                        nm = "stoneMid" if dx == 0 else "nightSlate"
                    img.set(xx, yy, col(nm))
        k += 1
    for x in range(w):                                 # the fan's dark seat on the ground line
        for yy in (h - 1,):
            if img.get(x, yy)[3] == 0 and x > 14 and h01(seed, x, 504) < 0.7 - x / 160.0:
                img.set(x, yy, col("stoneDark"))
    return img


# --------------------------------------------------------------------------------------------- the valley verge
def valley_verge(seed=521, variant=0):
    """Where the valley's earth track meets the grass under it (64 x 10, tiling, its row 3 on the track's lower
    edge): the meadow's ragged edge, stones of three sizes (a slab 6 to 8 wide, a cobble 3 to 4, pebbles) at gaps of
    two to five times one another, some sunk so only their lit top shows over the grass, roots; the lowest rows fade
    into the band."""
    w, h = 64, 10
    im = PA.Image(w, h)
    for x in range(w):                              # the meadow's edge: a ragged line of tufts
        hh = 1 + int(3.2 * h01(seed, x // 2, 1)) + (1 if h01(seed, x, 1) < 0.2 else 0)
        if h01(seed, x // 5, 9) < 0.18:
            hh = 0
        for k in range(hh + 2):
            y = 4 - hh + k
            v = h01(seed, x, y, 2)
            nm = "leafLight" if k == 0 and v < 0.5 else "meadow" if k <= 1 else "leaf" if v < 0.6 else "leafDark"
            put(im, x, y, nm)
    # the stones: a hand-set rhythm (x, kind) with gaps of 3 to 15 px, three sizes, some sunk
    rhythms = [
        [(2, "slab", False), (13, "peb", False), (17, "cob", True), (33, "peb", False), (36, "peb", True),
         (44, "cob", False), (57, "slab", True)],
        [(5, "cob", False), (9, "peb", False), (22, "slab", False), (40, "peb", True), (47, "cob", True),
         (51, "peb", False), (60, "peb", False)],
    ]
    sizes = {"slab": (7, 3), "cob": (4, 2), "peb": (2, 1)}
    for i, (x0, kind, sunk) in enumerate(rhythms[variant]):
        sw, sh = sizes[kind]
        sw += int(2 * h01(seed, i, 11)) if kind == "slab" else 0
        sy = (2 if kind == "slab" else 3) + int(2 * h01(seed, i, 12))
        rows = range(sy, sy + (1 if sunk else sh))
        for yy in rows:
            for dx in range(sw):
                xx = (x0 + dx) % w
                last = dx == sw - 1
                if yy == sy:
                    nm = "stoneLight" if not last and dx > 0 else "stone"
                else:
                    nm = "stone" if not last else "stoneMid"
                if kind == "peb":
                    nm = "stoneLight" if dx == 0 and yy == sy else "stoneMid"
                put(im, xx, yy, nm)
        seat = sy + (1 if sunk else sh)
        for dx in range(sw + 1):
            xx = (x0 + dx) % w
            if sunk:
                put(im, xx, seat, "leaf" if h01(seed, xx, 13) < 0.6 else "meadow")   # the grass closes over it
            else:
                put(im, xx, min(h - 1, seat), "soilDark")
        if not sunk:
            put(im, (x0 + sw) % w, sy + sh - 1, "soilDark")
    for r in range(2 + variant):                    # roots crossing the edge
        rx = 8 + r * 25 + int(6 * h01(seed, r, 8)) + 9 * variant
        for i in range(8):
            yy = 3 + int(2.2 * math.sin(i * 0.7 + r)) + i // 4
            put(im, (rx + i) % w, yy, "woodDark" if i % 3 else "soil")
    for y in range(h):                              # fade the lowest rows into the band
        f = 1.0 if y < 7 else max(0.0, 1 - (y - 6) / 3.0)
        if f >= 1:
            continue
        for xx in range(w):
            p = im.get(xx, y)
            if p[3]:
                im.set(xx, y, (p[0], p[1], p[2], (int(p[3] * f) // 16) * 16))
    return im


BUILDERS = {
    "beaconRuin": beacon_ruin,
    "bakehouse": bakehouse,
    "beaconTower": beacon_tower,
    "greatBeacon": great_beacon,
    "beaconRuinRim": lambda: stage_rim("beaconRuin"),
    "beaconBaseRim": lambda: stage_rim("beaconBase"),
    "beaconTowerRim": lambda: stage_rim("beaconTower"),
    "greatBeaconRim": lambda: stage_rim("greatBeacon"),
    "riverLanding": river_landing,
    "riverSkiffMoored": river_skiff_moored,
    "riverSkiffRim": river_skiff_rim,
    "riverLanternHalo": river_lantern_halo,
    "riverLanternStreak": river_lantern_streak,
    "throatButtress": throat_buttress,
    "valleyVerge": lambda: valley_verge(521, 0),
    "valleyVergeB": lambda: valley_verge(547, 1),
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
