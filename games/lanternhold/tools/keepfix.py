#!/usr/bin/env python3
"""Lanternhold world lane, world-2 fix round 1 (the critic's look 1 of step world-2, 15.11.2026; DESIGN.md "World
rebuild (14.11.2026)", ART-look2.md section 24). The pieces the critic sent back, repainted in keepart.py's language
(pure python on pixelart.py's Image, palette colours only, hashes of the position instead of randomness, so a run
reproduces its files byte for byte):

  keepT1, keepT2, keepT3, keepT2Build, keepT3Build   260x175  the one keep, rebuilt (blocker 1): the stone of the
        mistBand plane a step paler and cooler than the curtain's (the mist greys over the slate darks), a ramp from a
        dark foot to a lit crown in two values of block, round corner towers modelled like the gatehouse's drums, a
        round stair turret and its stair hall on the west (the corner the front gate sees: crenels, then a flag, then a
        cone), deep window reveals, shadows under every string course and corbel table, a brazier on the wall walk;
        the building states with heavy timber and a crane whose jib stands over the roof (high 8)
        Build 3, POLISH pass 1 (lane 3): the flags fly in the wind as a prop of their own (`keepFlag`,
        tools/bannerart.py wind; `SceneLayout.castleKeepFlags`), so the keep keeps only their poles: the great pole on
        the ridge at every tier but tier 2 under way (its roof is off; tier 1 has one now too, `MAIN_POLE`), the stair
        turret's pole at tier 2
  keepRimT1 .. keepRimT3Build  260x175  emissive: the keep's warm rim on its west edges at dusk (blocker 1)
  keepMist          320x32   the feathered mist bank on the mistBand plane at the keep's foot (dawn, dusk, night)
  keepPaneHalo      11x14    emissive: the soft warm bloom around a lit twin window of the keep
  keepFireGlow      36x24    emissive: the keep's brazier's light on its merlons and roof
  forebuilding      120x96 x 2  the porch rebuilt (high 5): a slate roof that slopes, a dormer with a thick coping
        for the lord's chamber, steps up to the door between low parapets, the threshold that catches the light
  hallDoorGlow      20x32    emissive: the view into the hall through the open door (blocker 2): dark jambs,
        flagstones receding to a lit far wall, a pillar, the hearth's glow the brightest point high in the middle
  hallDoorWedge     60x19    emissive: the door's wedge of light over the steps and the cobbles, the door's width at
        the threshold to 2.5 times it 12 rows out, smooth alpha so the stones show through
  smokePuff         8x8 (8 frames)  a puff of chimney smoke at four sizes, 2 to 5 px, and the mouth's pixel (b3-wind);
        frames 5 to 7 the town's puffs, 2 to 4 px, in wood-smoke grey under a lit cap (b3-wind step 7)
  curtainB          64x74    the curtain's blocked arch as a recess in shadow (high 6)
  posternT1..T3     176x112 (T3 176x124 since build 3: its flag's pole)  the postern's passage with depth (high 4): jamb shadow, the vault, a lit far end and
        cobbles that recede
  posternFarGlow    10x16    emissive: the lantern-warm far end of the postern's passage at night
  gateArchFg        16x116 (2 frames)  foreground: the near jamb of either gate (high 7), dark stone, a warm lit edge

  keepfix.py build <id> [<id> ...] --out <Resources/Art>
  keepfix.py all --out <Resources/Art>
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import pixelart as PA  # noqa: E402
import worldart as WA  # noqa: E402
import townart as TA  # noqa: E402
import keepart as K  # noqa: E402

col, h01 = WA.col, WA.h01
C = K.C
SLATE = TA.SLATE

# The keep's ramp (the mistBand plane: the cleft's air between it and the curtain): slate darks, then mist greys.
KR = ["stoneDark", "stoneMid", "stone", "mistDark", "mist", "mistLight"]
KREV = {col(n): i for i, n in enumerate(KR)}


def kset(c, x, y, v):
    c.set(x, y, KR[max(0, min(5, int(math.floor(v))))])


def kval(c, x, y):
    """The ramp index of a keep pixel, None for any other colour."""
    return KREV.get(c.get(x, y))


def ramp(hh):
    """The keep's value (an index of KR, fractional) at height hh: a dark foot (stoneMid and stone where it rises out
    of the curtain) to a lit crown (mistDark and mist)."""
    t = max(0.0, min(1.0, (hh - 56) / 84.0))
    return 1.75 + t * 1.8


# ---------------------------------------------------------------------------------------------------- stone
def kashlar(c, x0, x1, h0, h1, seed, course=4, bmin=6, bmax=11, turn=None, lift=0.0):
    """Coursed blocks over cols x0..x1 and heights h0..h1: each block one of two values of its height's band (the
    ramp), now and then a lit or a weathered one; the bed joint under each course and a block's left joint a step
    darker and broken. `turn(x)` gives the share (0 ... 1) by which the face turns from the light toward x1."""
    k = 0
    hh = h0
    while hh <= h1:
        top = min(h1, hh + course - 1)
        off = int(h01(seed, k, 3) * bmax)
        x = x0 - off
        n = 0
        while x <= x1:
            w = bmin + int(h01(seed, k, n, 5) * (bmax - bmin + 1))
            cx = x + w // 2
            v = ramp((hh + top) / 2.0) + lift + (0.5 if h01(seed, k, n, 7) < 0.5 else 0.0)
            if turn:
                v -= 0.9 * turn(cx)
            r = h01(seed, k, n, 11)
            if r < 0.035:
                v += 1
            elif r > 0.93:
                v -= 1
            for yy in range(hh, top + 1):
                for xx in range(max(x, x0), min(x + w - 1, x1) + 1):
                    q = v
                    if yy == hh and top > hh and h01(seed, xx, yy, 19) < 0.7:
                        q = min(v, 3.9) - 1                              # the bed joint
                    elif xx == x and h01(seed, k, n, 13) < 0.55:
                        q = min(v, 3.9) - 1                              # the vertical joint
                    kset(c, xx, c.r(yy), q)
            x += w
            n += 1
        hh = top + 1
        k += 1


def drum_shade(x, x0, x1):
    """The light across a round tower (cols x0..x1) from the upper left and a little in front: a dark rim on the
    left, the lit band at about a quarter, falling into shade toward the right (-2.4 ... +1)."""
    w = x1 - x0 + 1
    s = 2 * (x - x0 + 0.5) / w - 1
    theta = math.asin(max(-1.0, min(1.0, s)))
    return (math.cos(theta + 0.62) - 0.5) * 2.8, theta


def drum(c, x0, x1, h0, h1, seed, course=4, lift=0.0, step=0.44):
    """A round tower's masonry: courses whose blocks narrow toward both edges (equal steps of the angle around the
    drum, staggered by course), the drum's light over the ramp, joints a step darker."""
    for hh in range(h0, h1 + 1):
        k = (hh - h0) // course
        bed = (hh - h0) % course == 0
        prev = None
        for x in range(x0, x1 + 1):
            sh, theta = drum_shade(x, x0, x1)
            b = int(math.floor((theta + (step / 2 if k % 2 else 0.0) + 2) / step))
            v = ramp(hh) + lift + sh + (0.3 if h01(seed, k, b, 7) < 0.35 else 0.0)
            if h01(seed, k, b, 11) > 0.95:
                v -= 1
            joint = prev is not None and b != prev and h01(seed, k, b, 13) < 0.6
            prev = b
            if (bed and h01(seed, x, hh, 19) < 0.6) or joint:
                v = min(v, 3.9) - 1
            if x in (x0, x1):
                v -= 0.6
            if theta > 0.3:                         # fix round 2 (high 2): the flank away from the sun a step deeper
                v -= 1.0 if theta > 0.62 else 0.5
            kset(c, x, c.r(hh), v)


def kcourse(c, x0, x1, hh, lit_to=None, drum_x=None):
    """A string course at height hh: a lit top row, its moulding, and two rows of shadow under it (deep, then soft)."""
    for x in range(x0, x1 + 1):
        lit = (lit_to is None or x < lit_to)
        top, body = (4.5, 3.4) if lit else (3.6, 2.5)    # fix round 2: the lit-stone value on top, not white
        if drum_x:
            sh, _ = drum_shade(x, drum_x[0], drum_x[1])
            top, body = 4.2 + sh * 0.6, 3.1 + sh * 0.6
        kset(c, x, c.r(hh), top)
        kset(c, x, c.r(hh - 1), body)
        kset(c, x, c.r(hh - 2), 0)
        cur = kval(c, x, c.r(hh - 3))
        if cur is not None:
            kset(c, x, c.r(hh - 3), min(cur, 2) - 0.5)


def kcorbels(c, x0, x1, hh, period=4, depth=3, drum_x=None):
    """A corbel table under a parapet (rows hh down to hh-depth+1): deep slots between small lit brackets, a row of
    shadow under them."""
    for x in range(x0, x1 + 1):
        k = (x - x0) % period
        sh = drum_shade(x, drum_x[0], drum_x[1])[0] if drum_x else 0.0
        for d in range(depth):
            y = c.r(hh - d)
            if k == 0:
                kset(c, x, y, (4.6 if d == 0 else 3.2) + sh * 0.5)
            elif k == period - 1:
                kset(c, x, y, 1.5 + sh * 0.3)
            else:
                c.set(x, y, "ink" if d < depth - 1 else "night1")
        kset(c, x, c.r(hh - depth), 0)


def kmachicolations(c, x0, x1, hh, period=5, depth=4, drum_x=None):
    """Machicolations under a tower's parapet (rows hh down): corbels stepping out with lit tops, ink slots (the
    gatehouse's deep shadow)."""
    for x in range(x0, x1 + 1):
        k = (x - x0) % period
        sh = drum_shade(x, drum_x[0], drum_x[1])[0] if drum_x else 0.0
        for d in range(depth):
            y = c.r(hh - d)
            if k == 0:
                kset(c, x, y, (4.3, 3.5, 2.6, 2.0)[d] + sh * 0.5)
            elif k == 1:
                kset(c, x, y, (3.6, 2.4, 1.8, 1.0)[d] + sh * 0.5)
            else:
                c.set(x, y, "ink")
        kset(c, x, c.r(hh - depth), 0)


def kparapet(c, x0, x1, hh, rows=3, drum_x=None, lit_to=None):
    """A parapet's face (rows hh up to hh+rows-1) over its corbels: lit along its top."""
    for x in range(x0, x1 + 1):
        sh = drum_shade(x, drum_x[0], drum_x[1])[0] if drum_x else (0.0 if lit_to is None or x < lit_to else -1.0)
        for d in range(rows):
            kset(c, x, c.r(hh + d), (2.8 if d == 0 else 3.3 if d < rows - 1 else 4.1) + ramp(hh) - 3.0 + sh * 0.7)


def kmerlons(c, x0, x1, hbase, mh=5, mw=5, gap=3, phase=0, drum_x=None, lit_to=None):
    """Merlons from height hbase up mh rows (the crenels between them open to the sky): a lit cap and left edge, a
    shaded right column; on a drum each merlon takes the drum's light."""
    period = mw + gap
    for x in range(x0, x1 + 1):
        k = (x - x0 + phase) % period
        if k >= mw:
            continue
        sh = drum_shade(x, drum_x[0], drum_x[1])[0] if drum_x else (0.0 if lit_to is None or x < lit_to else -1.0)
        for d in range(mh):
            y = c.r(hbase + d)
            if d == mh - 1:
                v = 4.3 if k < mw - 1 else 3.5     # fix round 2 (high 2): the lit stone's value, not white teeth
            elif k == 0:
                v = 4.0
            elif k == mw - 1:
                v = 2.0
            else:
                v = 3.4
            kset(c, x, y, v + sh * 0.7)


def kslit(c, x, hh, h):
    """An arrow slit from height hh down h rows: an ink slot, a lit left jamb, a shaded right one, a pale sill."""
    for d in range(h):
        y = c.r(hh - d)
        c.set(x, y, "ink")
        kset(c, x - 1, y, 4.2)
        kset(c, x + 1, y, 1)
    kset(c, x, c.r(hh + 1), 1)
    for xx in (x - 1, x, x + 1):
        kset(c, xx, c.r(hh - h), 5 if xx < x + 1 else 4)


def ktwin(c, x, hb, w=7, h=10):
    """A twin window of the keep, its glass box x, heights hb .. hb+h-1 (night1, the layout's mask lights it): two
    round-headed lights under a relieving arch, a colonnette; a deep reveal (each light's right jamb in shadow inside
    the box, nightDeep, which the mask leaves dark), a splayed jamb outside, a hood with its shadow, a lit sill and
    its shadow."""
    ytop = c.r(hb + h - 1)
    for lx in (x, x + 4):
        for d in range(h):
            yy = ytop + d
            for xx in range(lx, lx + 3):
                inside = True
                if d < 2:
                    dx = abs(xx - (lx + 1))
                    inside = dx * dx + (2 - d - 0.5) ** 2 <= 1.6 ** 2
                if inside:
                    c.set(xx, yy, "night1")
        for d in range(2, h):                       # the reveal: the light's right jamb in shadow, deep
            c.set(lx + 2, ytop + d, "nightDeep")
    for d in range(2, h):                           # the colonnette
        kset(c, x + 3, ytop + d, 3.4 if d > 2 else 4.6)
    kset(c, x + 3, ytop + 1, 1)
    for d in range(-1, h + 1):                      # the splayed jambs outside the box
        kset(c, x - 1, ytop + d, 4.6)
        kset(c, x + w, ytop + d, 0.6)
        kset(c, x + w + 1, ytop + d, 1.4)
    for xx in range(x - 2, x + w + 2):              # the relieving arch / hood and its shadow
        dx = xx - (x + w / 2.0 - 0.5)
        r = w / 2.0 + 1.5
        if abs(dx) <= r:
            yy = int(round(ytop + 1 - (r * r - dx * dx) ** 0.5 * 0.55))
            kset(c, xx, yy - 1, 5.0 if dx < 0 else 4.0)
            kset(c, xx, yy, 0.5)
    for xx in range(x - 2, x + w + 2):              # the sill and its shadow
        kset(c, xx, c.r(hb - 1), 5.0 if xx < x + w else 4.0)
        kset(c, xx, c.r(hb - 2), 0)
        if h01(xx, hb, 3) < 0.6:
            kset(c, xx, c.r(hb - 3), 1)


def kshutter(c, x, hb, w=5, h=8):
    """Fix round 2 (the critic's high 2: "a mirrored front"): a small window shut with two wooden shutters (cols x ..
    x+w-1, heights hb .. hb+h-1): a round head of dark voussoirs, the leaves in plank courses (the left lit, the right
    a step darker), the gap between them, an iron strap on each, a lit sill and its shadow; a deep reveal on the
    right."""
    ytop = c.r(hb + h - 1)
    mid = x + w // 2
    for d in range(h):
        for xx in range(x, x + w):
            if d == 0 and abs(xx - mid) > 1:
                continue
            if xx == mid:
                name = "woodDark"                       # the gap between the leaves
            elif xx < mid:
                name = "woodLight" if xx == x else "wood"
            else:
                name = "wood" if xx < x + w - 1 else "woodDark"
            if d in (2, h - 2) and xx != mid:
                name = "stoneDark"                      # the iron straps
            c.set(xx, ytop + d, name)
    for d in range(-1, h + 1):                          # the reveal: lit jamb left, deep right
        kset(c, x - 1, ytop + d, 4.0)
        kset(c, x + w, ytop + d, 0.4)
    for xx in range(x - 1, x + w + 1):                  # the head's voussoirs and the sill
        kset(c, xx, ytop - 1, 3.6 if xx < mid else 2.6)
        kset(c, xx, c.r(hb - 1), 4.2 if xx < x + w else 3.4)
        kset(c, xx, c.r(hb - 2), 0)


def ksmall(c, x, hb, h=7):
    """A small round-headed window 3 wide (glass night1, heights hb .. hb+h-1), its reveal and sill."""
    ytop = c.r(hb + h - 1)
    for d in range(h):
        for xx in range(x, x + 3):
            if d == 0 and xx != x + 1:
                continue
            c.set(xx, ytop + d, "night1")
        if d > 1:
            c.set(x + 2, ytop + d, "nightDeep")
    for d in range(-1, h + 1):
        kset(c, x - 1, ytop + d, 4.6)
        kset(c, x + 3, ytop + d, 0.8)
    kset(c, x + 1, ytop - 1, 4.8)
    for xx in range(x - 1, x + 4):
        kset(c, xx, c.r(hb - 1), 5 if xx < x + 3 else 4)
        kset(c, xx, c.r(hb - 2), 0)


# ------------------------------------------------------------------------------------------------- the keep
KW, KH = 260, 175
OX = 60                              # keepart's 200-px keep stands at cols 60 to 259 of this one
TIERS = {
    # the corner towers' walls, the main block's walls, the roof's ridge, the chimney's top, the stair turret's wall,
    # the stair hall's wall
    1: dict(tower=106, wall=98, ridge=120, chimney=122, turret=120, hall=94),
    2: dict(tower=126, wall=118, ridge=140, chimney=136, turret=136, hall=108),
    3: dict(tower=126, wall=118, ridge=140, chimney=136, turret=126, hall=108),
}
# Build 3, POLISH pass 1: the top of the great pole on the ridge (height above the ground line) by the tier drawn; the
# flag hangs from the row under it. The stair turret's pole at tier 2 stands at TURRET's middle, its top at TURRET_POLE.
MAIN_POLE = {1: 140, 2: 156, 3: 170}
MAIN_POLE_X = OX + 100
TURRET_POLE = 162
KTOWERS = ((64, 97), (222, 255))     # the round corner towers
KBODY = (98, 221)                    # the main block between them
TURRET = (15, 45)                    # the stair turret on the west (centre col 30)
HALL = (45, 64)                      # the stair hall between the turret and the west tower
PILASTERS = (128, 188)               # two broad pilaster buttresses: a wide middle bay holds the hall's windows
BRAZIER_X = 129                      # the brazier on the main block's wall walk (in a crenel's gap)


def keep_panes(tier, building=False):
    """The keep's lit panes as (x, dy, w, h) for the layout's masks, in the order the layout reads them (the second is
    the one a world change darkens): the middle bay's twin windows (tier 1), the storey above (tiers 2 and 3; none
    while it is built), and the stair hall's small window."""
    wins = [(OX + 79, 80, 7, 10), (OX + 110, 80, 7, 10)]
    if tier >= 2 and not building:
        wins += [(OX + 48, 100, 7, 10), (OX + 110, 100, 7, 10), (OX + 141, 100, 7, 10)]
    wins.append((53, 70, 3, 7))
    return wins


def timber_cone(c, cx, base, half, h):
    """A cone's timber frame under way: heavy rafters in light wood and battens every three rows."""
    for i in range(h + 1):
        y = base - i
        w = half * (h - i) / float(h)
        a, b = int(round(cx - w)), int(round(cx + w))
        if i % 3 == 0:
            for x in range(a, b + 1):
                c.set(x, y, "woodLight" if x < cx + 2 else "wood")
        for x, name in ((a, "woodLight"), (a + 1, "wood"), (b - 1, "wood"), (b, "woodDark"), (cx, "woodLight"),
                        (cx + 1, "wood")):
            c.set(x, y, name)
        for s in (-1, 1):                           # two more rafters between the edges and the king post
            c.set(int(round(cx + s * w * 0.5)), y, "woodLight" if s < 0 else "wood")
    c.set(cx, base - h - 1, "woodLight")


def heavy_scaffold(c, x0, x1, hbot, htop, seed):
    """Scaffolding of heavy timber: standards two px wide every 10 px, ledgers in light wood with boards, braces."""
    xs = list(range(x0, x1 + 1, 10))
    for x in xs:
        for hh in range(hbot, htop + 1):
            c.set(x, c.r(hh), "woodLight")
            c.set(x + 1, c.r(hh), "woodDark")
    for hh in range(hbot + 3, htop + 1, 8):
        for x in range(x0, x1 + 2):
            c.set(x, c.r(hh), "woodLight")
            c.set(x, c.r(hh - 1), "wood" if (x - x0) % 10 else "woodDark")
    for i, x in enumerate(xs[:-1]):
        if i % 2 == 0:
            for d in range(min(8, htop - hbot)):
                c.set(x + 1 + d, c.r(hbot + 4 + d), "wood")


def keep_turret(c, t, tier, seed, building):
    """The stair turret: a round tower of the keep's stone, slits climbing with the stair, a corbelled crown: merlons
    (tier 1), taller with machicolations and the house's flag (tier 2), a slate cone (tier 3; its timber frame while it
    is built)."""
    x0, x1 = TURRET
    top = t["turret"]
    drum(c, x0, x1, 0, top, seed + 51, course=4)
    for hh in range(0, 6):                          # the battered foot
        for x in range(x0 - 1, x1 + 2):
            kset(c, x, c.r(hh), 1.2 if hh < 5 else 3.5)
    for i, hh in enumerate(range(52, top - 10, 14)):  # the stair's slits climb around the drum
        kslit(c, (24, 31, 37)[i % 3], hh + 6, 6)
    kcourse(c, x0, x1, 70, drum_x=(x0, x1))
    cx = (x0 + x1) // 2
    if tier == 3:
        for x in range(x0 - 1, x1 + 2):             # an eave on corbels, then the cone
            kset(c, x, c.r(top + 1), 4.4 + drum_shade(x, x0 - 1, x1 + 1)[0] * 0.6)
            kset(c, x, c.r(top), 0)
        kcorbels(c, x0, x1, top - 1, period=4, depth=2, drum_x=(x0, x1))
        if building:
            timber_cone(c, cx, c.r(top + 2), 16, 20)
        else:
            K.cone(c, cx, c.r(top + 2), 17, 19)
        return
    ext = 2
    kmachicolations(c, x0 - ext, x1 + ext, top + 3, period=5, depth=4, drum_x=(x0 - ext, x1 + ext))
    kparapet(c, x0 - ext, x1 + ext, top + 4, rows=3, drum_x=(x0 - ext, x1 + ext))
    kmerlons(c, x0 - ext, x1 + ext, top + 7, mh=5, mw=5, gap=3, phase=1, drum_x=(x0 - ext, x1 + ext))
    if tier >= 2 and not building:
        K.pole(c, cx, c.r(TURRET_POLE), c.r(top + 7))   # its flag flies as a prop of its own (build 3)


def keep_hall(c, t, seed):
    """The stair hall between the turret and the west tower: the keep's stone, a lean-to of teal slate against the
    tower, a small lit window."""
    x0, x1 = HALL
    wall = t["hall"]
    kashlar(c, x0, x1, 0, wall, seed + 61, course=4, bmin=5, bmax=9)
    kcourse(c, x0, x1, 70)
    ksmall(c, 53, 70)
    for x in range(x0, x1 + 1):                     # the lean-to: rising from the turret to the tower
        rise = wall + 2 + (x - x0) * 9 // (x1 - x0)
        for hh in range(wall + 1, rise + 1):
            k = (x + hh) % 3
            c.set(x, c.r(hh), "roofLight" if hh == rise and x < x1 - 4 else "banner" if k else "roofDeep")
        c.set(x, c.r(wall), "night1")


def keep_tower(c, x0, x1, t, tier, seed, building, i):
    """A round corner tower: the drum, a string course, slits, a corbelled crown of machicolations and merlons; tier 3
    puts a slate cone on it."""
    tw = t["tower"]
    drum(c, x0, x1, 0, tw, seed + 31 * (i + 1), course=4, lift=0.15 if i == 0 else -0.45)
    for hh in range(0, 7):
        for x in range(x0 - 1, x1 + 2):
            kset(c, x, c.r(hh), 1.2 if hh < 6 else 3.5)
    kcourse(c, x0, x1, 70, drum_x=(x0, x1))
    cx = (x0 + x1) // 2
    for hh in (82, 102, 118):
        if hh + 2 < tw - 6:
            if i == 0 and hh == 82:
                kshutter(c, cx - 5, 82)             # fix round 2: the west tower's shut window (the towers differ)
            else:
                kslit(c, cx - 3, hh + 6, 7)
    if i == 1:
        # fix round 2: the east tower's second string course, a corbelled band at the main block's upper floor
        kcourse(c, x0, x1, 94, drum_x=(x0, x1))
        for x in range(x0 + 2, x1 - 1, 4):
            kset(c, x, c.r(91), 1.2)
    ext = 2
    kmachicolations(c, x0 - ext, x1 + ext, tw - 1, period=5, depth=4, drum_x=(x0 - ext, x1 + ext))
    kparapet(c, x0 - ext, x1 + ext, tw, rows=3, drum_x=(x0 - ext, x1 + ext))
    if tier == 3 and not building:
        for x in range(x0 - ext - 1, x1 + ext + 2):  # an eave over the parapet, the cone on it (its finial at h 148)
            kset(c, x, c.r(tw + 3), 4.6 + drum_shade(x, x0 - ext - 1, x1 + ext + 1)[0] * 0.6)
        K.cone(c, cx, c.r(tw + 4), 21, 17)
    else:
        kmerlons(c, x0 - ext, x1 + ext, tw + 3, mh=6, mw=5, gap=3, phase=2, drum_x=(x0 - ext, x1 + ext))


def keep_body(c, t, tier, seed, building=False):
    """The main block: coursed stone on the ramp, the right part turning from the light, a battered plinth, two broad
    pilaster buttresses, string courses with their shadows, the twin windows with deep reveals, a parapet on a corbel
    table."""
    ww = t["wall"]
    bx0, bx1 = KBODY

    def turn(x):
        return max(0.0, min(1.0, (x - (bx0 + 84)) / 40.0))
    kashlar(c, bx0, bx1, 0, ww, seed, course=4, bmin=6, bmax=11, turn=turn)
    for x in range(bx0, bx1 + 1):
        for hh in range(0, 6):
            kset(c, x, c.r(hh), 1.2 if hh < 5 else 3.5)
    for px in PILASTERS:                            # lit face, shaded flank, its shadow on the wall to the right
        for hh in range(6, ww - 2):
            y = c.r(hh)
            base = ramp(hh)
            kset(c, px, y, base + 1.4)
            kset(c, px + 1, y, base + (1.0 if (hh // 4) % 2 else 0.5))
            kset(c, px + 2, y, base + 0.5)
            kset(c, px + 3, y, base - 0.6)
            kset(c, px + 4, y, base - 1.6)
            kset(c, px + 5, y, base - 1.4)
            if (hh // 2) % 2:
                kset(c, px + 6, y, base - 1.0)
        for d in range(5):
            kset(c, px + d, c.r(ww - 2), 5 if d < 3 else 4)
    kcourse(c, bx0, bx1, 70, lit_to=bx0 + 92)
    if ww > 100:
        kcourse(c, bx0, bx1, 92, lit_to=bx0 + 92)
    for (x, dy, w, h) in keep_panes(tier, building)[:-1]:
        ktwin(c, x, dy, w, h)
    if tier >= 2 and not building:
        kshutter(c, OX + 79, 100, w=7, h=10)        # the storey's fourth window, shuttered (fix round 2: no mirror)
    for (x, hh) in ((OX + 48, 78), (OX + 141, 78)):  # unlit: a stair's slits in the outer bays
        kslit(c, x + 3, hh + 8, 8)
    kcorbels(c, bx0, bx1, ww - 1, period=4, depth=3)
    kparapet(c, bx0, bx1, ww, rows=3, lit_to=bx1 - 26)
    kmerlons(c, bx0 + 1, bx1 - 1, ww + 3, mh=5, mw=5, gap=3, lit_to=bx1 - 26)
    x1 = KTOWERS[0][1]                              # the west tower's shadow on the block beside it
    # fix round 2 (high 2: "no light direction"): the sun from the left; the west tower, standing forward, casts a
    # broad shadow over the block's first bay, up through its parapet and merlons, its edge dithered
    for hh in range(6, ww + 9):
        for d in range(12):
            if d < 9 or (hh + d) % 2:
                v = kval(c, x1 + 1 + d, c.r(hh))
                if v is not None:
                    kset(c, x1 + 1 + d, c.r(hh), v - (1.8 if d < 7 else 1.0))
    # a drainage stain under the chimney: a spout in the parapet and its dark, broken streaks down the wall
    sx = 183 if ww < 110 else 195
    for d, (dx, length) in enumerate(((0, 26), (1, 34), (2, 18))):
        for hh in range(ww - length, ww - 1):
            if h01(sx, d, hh // 2, 71) < 0.82:
                v = kval(c, sx + dx, c.r(hh))
                if v is not None:
                    kset(c, sx + dx, c.r(hh), v - (1.0 if hh > ww - 14 else 0.6))
    c.set(sx + 1, c.r(ww), "ink")
    c.set(sx + 1, c.r(ww - 1), "stoneDark")


def keep_roof(c, t, seed):
    """The hip roof behind the parapet: teal slate, the eaves hidden by the merlons, the ridge at t['ridge'], a stone
    chimney stack on the right slope (its smoke is the layout's)."""
    ww, ridge = t["wall"], t["ridge"]
    bx0, bx1 = KBODY
    top, bot = c.r(ridge), c.r(ww + 3)              # fix round 2: down to the parapet (a clear row showed the rock)
    run = float(bot - top)
    a0, b0 = bx0 + 5, bx1 - 5
    ra, rb = bx0 + 44, bx1 - 44
    TA.roof(c.im, top, bot, lambda y: int(round(ra - (ra - a0) * (y - top) / run)),
            lambda y: int(round(rb + (b0 - rb) * (y - top) / run)), SLATE, "slate", seed, moss=False, mid=0.55,
            shade=10)
    if ridge > 130:                                 # tiers 2 and 3: low on the right slope, its smoke under the HUD
        TA.chimney(c.im, 200, 205, c.r(t["chimney"]), c.r(t["chimney"] - 12), seed)
    else:
        chx = rb + 8
        TA.chimney(c.im, chx, chx + 5, c.r(t["chimney"]), c.r(ridge - 12), seed)


def keep_brazier(c, t):
    """An iron brazier on the main block's wall walk, its bowl in a crenel's gap over the merlons' foot (its fire and
    its light are the layout's emitters)."""
    hh = t["wall"] + 6
    x = BRAZIER_X
    for xx in range(x - 1, x + 2):
        c.set(xx, c.r(hh), "woodDark")
        c.set(xx, c.r(hh - 1), "stoneDark")
    c.set(x - 1, c.r(hh + 1), "stoneDark")
    c.set(x + 1, c.r(hh + 1), "stoneDark")
    c.set(x, c.r(hh - 2), "stoneDark")


def keep_crane(c, t):
    """The builders' crane on the keep: a heavy mast on the wall walk, a jib over the roof line, its rope and a stone,
    a counterweight; every timber in two values."""
    mx = 196
    base = t["wall"] + 4
    for hh in range(base, 147):
        c.set(mx, c.r(hh), "woodDark")
        c.set(mx + 1, c.r(hh), "woodLight")
        c.set(mx + 2, c.r(hh), "wood")
    for hh in range(base, 140, 6):                  # braces up the mast
        for d in range(4):
            c.set(mx - 1 - d, c.r(hh + d), "wood")
    for i in range(46):                             # the jib, two rows of timber, out over the roof's middle
        x = mx + 1 - i
        hh = 146 - i // 12
        c.set(x, c.r(hh), "woodLight")
        c.set(x, c.r(hh - 1), "wood")
        if i % 6 == 0:
            c.set(x, c.r(hh - 2), "woodDark")
    for i in range(10):                             # the back stay to the counterweight
        c.set(mx + 3 + i // 2, c.r(146 - i), "woodDark")
    for xx in range(mx + 6, mx + 10):
        for hh in range(133, 138):
            c.set(xx, c.r(hh), "stoneLight" if xx < mx + 8 else "stoneMid")
    rx = mx - 40
    for hh in range(126, 143):                      # the rope and its stone
        c.set(rx, c.r(hh), "soilLight")
    for hh in range(121, 126):
        for xx in range(rx - 3, rx + 4):
            c.set(xx, c.r(hh), "stoneLight" if xx < rx + 1 else "stoneMid")
        c.set(rx + 3, c.r(hh), "stoneDark")


def keep(tier, building=False):
    c = C(KW, KH)
    seed = 4100 + tier * 10 + (5 if building else 0)
    shown = tier - 1 if building else tier          # a tier under way stands on the one before
    t = dict(TIERS[shown])
    if not building or tier == 3:
        keep_roof(c, t, seed)
    keep_hall(c, t, seed)
    keep_body(c, t, shown, seed, building and tier == 2)
    for i, (x0, x1) in enumerate(KTOWERS):
        keep_tower(c, x0, x1, t, shown, seed, building, i)
    if building and tier == 3:
        keep_turret(c, TIERS[3], 3, seed, True)     # the turret's cone goes up with the towers'
    else:
        keep_turret(c, t, shown, seed, building)
    if not building:
        keep_brazier(c, t)
    if shown >= 2:
        # the realm's banners hung in the outer bays: the house shows its colours once it can afford the cloth
        K.banner(c, OX + 47, c.r(90), 7, 15)
        K.banner(c, OX + 146, c.r(90), 7, 15)
    if not (building and tier == 2):
        # build 3: the great pole at every tier with a roof (tier 3 under way stands on tier 2's); its flag flies as a
        # prop of its own
        K.pole(c, MAIN_POLE_X, c.r(MAIN_POLE[3 if tier == 3 and not building else shown]), c.r(t["ridge"] - 1))
    if building:
        nt = TIERS[tier]
        if tier == 2:
            for x in range(KBODY[0], KBODY[1] + 1):  # the next storey half laid, in ragged courses
                top = t["wall"] + 3 + int(h01(seed, x // 6) * 10)
                for hh in range(t["wall"] + 3, top):
                    kset(c, x, c.r(hh), 4 if (hh // 4 + x // 7) % 3 == 0 else 3)
            for (x0, x1) in KTOWERS:
                for x in range(x0 - 2, x1 + 3):
                    top = t["tower"] + 9 + int(h01(seed, x // 5, 3) * 8)
                    for hh in range(t["tower"] + 3, top):
                        kset(c, x, c.r(hh), 4 if (hh // 4 + x // 6) % 3 == 0 else 3)
            heavy_scaffold(c, KBODY[0] - 3, KBODY[1] + 3, t["wall"] - 8, nt["wall"] + 2, seed)
            keep_crane(c, t)
        else:
            for (x0, x1) in KTOWERS:                 # tier 3 under way: heavy timber cones on the corner towers
                cx = (x0 + x1) // 2
                timber_cone(c, cx, c.r(t["tower"] + 4), 20, 18)
                heavy_scaffold(c, x0 - 4, x1 + 4, t["tower"] - 8, t["tower"] + 4, seed + x0)
    K.outline(c, sides=("right",), name="stoneDark")
    return c.im


def keep_rim(tier, building=False):
    """The keep's warm rim at dusk (an emissive overlay of its sprite, `SceneLayout.castleKeepRims`): the low sun from
    the west on every edge of the silhouette that faces west (the turret's, the towers', each merlon's), a px of it
    inside the edge at half strength, and the caps that face the sky faintly; fire-orange in smooth alpha. The engine
    shows it only while the evening is warm and the moon not yet up."""
    src = keep(tier, building)
    im = PA.Image(KW, KH)
    r, g, b, _ = col("fireOrange")

    def solid(x, y):
        return 0 <= x < KW and 0 <= y < KH and src.get(x, y)[3] > 0
    for y in range(KH):
        for x in range(KW):
            if not solid(x, y):
                continue
            a = 0.0
            if not solid(x - 1, y):
                a = 0.62
            elif not solid(x - 2, y):
                a = 0.3
            if not solid(x, y - 1):
                a = max(a, 0.22 if x < KW * 0.7 else 0.12)
            if a > 0:
                im.set(x, y, (r, g, b, int(a * 255)))
    return im


BAYER4 = ((0, 8, 2, 10), (12, 4, 14, 6), (3, 11, 1, 9), (15, 7, 13, 5))
MIST_H = 32


def keep_mist():
    """The mist bank on the mistBand plane at the keep's foot (its bottom row at y 60, the curtain's merlon tops at
    y 72): fix round 2 (the critic's high 1: "neon tiles in the crenel gaps"): one volume behind the wall that rises 4
    to 6 rows over the merlon tops in slow, low lobes and feathers out over 10 rows, both ends fading over 56 px. The
    feather's alpha is quantised to sixteen levels with a 4x4 ordered dither between neighbouring levels only (round
    lh-w2f2-1 dithered each pixel on or off: a screen-door checker over the keep at dusk), so the edge is soft, with no
    bands and no pattern. The engine gives it the hour's fog colour, at night a desaturated night grey a value step over
    the keep's foot."""
    w, h = 320, MIST_H
    im = PA.Image(w, h)
    for x in range(w):
        lobe = 1.4 * math.sin(x / 31.0 + 0.7) + 0.8 * math.sin(x / 13.0 + 2.1) + 0.5 * math.sin(x / 5.3)
        solid = 17.0 + lobe                          # rows over the bottom where the feather begins (y 77 +- 2.7)
        end = min(1.0, x / 56.0, (w - 1 - x) / 56.0)
        end = end * end * (3 - 2 * end)
        for y in range(h):
            up = h - 1 - y
            if up <= solid - 4:
                a = 0.66
            elif up <= solid:
                a = 0.66 - 0.06 * (up - (solid - 4)) / 4.0
            else:
                t = min(1.0, (up - solid) / 10.0)
                a = 0.6 * (1.0 - t) ** 1.6
            a *= end
            k = int(a * 16 + BAYER4[y % 4][x % 4] / 16.0)   # dither between neighbouring sixteenths only
            if k > 0:
                im.set(x, y, (255, 255, 255, min(255, 16 * k)))
    return im


def keep_pane_halo():
    """The bloom around a lit twin window (its 7x10 glass box at cols 2 to 8, rows 2 to 11): warm light spilling onto
    the stone 2 px out, faint over the glass box; the glass's own light is the mask's."""
    w, h = 11, 14
    im = PA.Image(w, h)
    r, g, b, _ = col("fireGold")
    for y in range(h):
        for x in range(w):
            dx = max(2 - x, 0, x - 8)
            dy = max(2 - y, 0, y - 11)
            d = (dx * dx + dy * dy) ** 0.5
            if d == 0:
                a = 0.1 if y < 4 else 0.16
            else:
                a = 0.42 * max(0.0, 1 - d / 3.2) ** 1.5
            k = int(a * 16 + 0.5)
            if k > 0:
                im.set(x, y, (r, g, b, min(255, 16 * k)))
    return im


def keep_fire_glow():
    """The keep's brazier's light (its flame at col 18, row 15 from the top): a warm pool on the merlons, the wall
    walk and the roof's foot, deepening to ember at its rim; smooth alpha."""
    w, h = 36, 24
    im = PA.Image(w, h)
    for y in range(h):
        for x in range(w):
            dx = (x - 17.5) / 17.0
            dy = (y - 14.0) / (10.0 if y < 14 else 8.0)
            d = (dx * dx + dy * dy) ** 0.5
            if d >= 1:
                continue
            a = 0.5 * (1 - d) ** 1.7
            name = "fireGold" if d < 0.35 else "fireOrange" if d < 0.7 else "ember"
            r, g, b, _ = col(name)
            k = int(a * 16 + 0.5)
            if k > 0:
                im.set(x, y, (r, g, b, min(255, 16 * k)))
    return im


# ------------------------------------------------------------------------------------------- the forebuilding
FW, FH = 120, 96
DOOR = (51, 68)          # the door leaves' columns; the hall door's middle is between cols 59 and 60 (world 1830)
SILL = 7                 # the door's lowest row (its line of light): three steps and the threshold lead up to it
EAVE = 50


def steps(c):
    """Three stone steps and the threshold up to the door between low parapets: each tread lit along its edge, each
    riser in shadow; the threshold stone pale where the door's light falls."""
    for i in range(3):                               # tread i: rows 2i .. 2i+1, narrowing upward
        a, b = 40 + 3 * i, 79 - 3 * i
        for x in range(a, b + 1):
            c.set(x, c.r(2 * i + 1), "stonePale" if x < 74 else "stoneLight")
            c.set(x, c.r(2 * i), "stoneMid" if (x + i) % 9 else "stoneDark")
    for x in range(DOOR[0] - 1, DOOR[1] + 2):        # the threshold
        c.set(x, c.r(SILL - 1), "stonePale")
    for (x0, x1, lit) in ((32, 39, True), (80, 87, False)):   # the parapets, a lit coping
        for x in range(x0, x1 + 1):
            k = x - x0
            for hh in range(0, 11):
                name = ("stoneLight" if k < 2 else "stone") if lit else ("stone" if k < 2 else "stoneMid")
                if hh % 5 == 4:
                    name = "stoneMid" if lit else "stoneDark"
                c.set(x, c.r(hh), name)
            c.set(x, c.r(11), "stoneLight" if lit else "stone")
            c.set(x, c.r(12), "stonePale" if lit and k < 6 else "stoneLight")
        for hh in range(0, 11):                      # the side toward the steps in shade
            c.set(x1 if lit else x0, c.r(hh), "stoneDark" if lit else "stoneMid")


def forebuilding_frame(open_):
    """The keep's forebuilding: a porch of dressed stone under a slate roof that slopes back to its ridge, a dormer
    with a thick stone coping for the lord's chamber (its window's candle is a mask), quoined corners, the hall door
    in a deep round portal of two orders raised on steps, torches either side; no pediment and no pilasters."""
    c = C(FW, FH)
    seed = 701
    x0, x1 = 8, 111
    K.ashlar(c, x0, c.r(EAVE - 1), x1, c.r(0), seed, course=5, bmin=7, bmax=13, joints=0.8, foot=0.3, light=0.05,
             dark=0.08, quoins=True, darken=lambda x, y: -1 if x > 96 and h01(seed, x // 8, y // 5) < 0.6 else 0)
    for x in range(x0, x1 + 1):                      # the plinth
        for hh in range(0, 3):
            c.set(x, c.r(hh), "stoneMid" if hh < 2 else "stoneLight")
    # the roof: teal slate from the eaves (h 50, the eave's shadow under it) back to its ridge at h 80, hipped
    top, bot = c.r(80), c.r(EAVE + 1)
    run = float(bot - top)
    TA.roof(c.im, top, bot, lambda y: int(round(30 - (30 - (x0 - 4)) * (y - top) / run)),
            lambda y: int(round(89 + ((x1 + 4) - 89) * (y - top) / run)), SLATE, "slate", seed, moss=True, mid=0.55,
            shade=10)
    for x in range(x0 - 3, x1 + 4):                  # the eave: a timber fascia, its shadow on the wall
        c.set(x, c.r(EAVE), "woodDark")
        c.step(x, c.r(EAVE - 1), -1)
        c.step(x, c.r(EAVE - 2), -1)
    # the dormer of the lord's chamber: a stone gable standing out of the slope, its coping thick and lit
    dx0, dx1, deave, dapex = 47, 72, 56, 79
    for hh in range(EAVE + 1, dapex + 1):
        half = 12.5 if hh <= deave else (dapex - hh) * 12.5 / (dapex - deave)
        for x in range(int(round(59.5 - half)), int(round(59.5 + half)) + 1):
            name = "stoneLight" if x < 52 else "stoneMid" if x > 68 else "stone"
            if hh % 4 == 0 and h01(seed, x, hh) < 0.6:
                name = "stoneMid" if x < 68 else "stoneDark"
            c.set(x, c.r(hh), name)
    for hh in range(deave, dapex + 3):               # the coping: three rows thick, lit on the left slope
        w = (dapex - hh) * 12.5 / (dapex - deave)
        for side in (-1, 1):
            edge = 59.5 + side * (w + 1.5)
            for d in range(3):
                x = int(round(edge - side * d))
                c.set(x, c.r(hh), ("stonePale", "stoneLight", "stoneDark")[d] if side < 0 else
                      ("stoneLight", "stone", "stoneDark")[d])
    for x in (dx0 - 1, dx0, dx1, dx1 + 1):           # kneelers
        for hh in range(deave - 1, deave + 2):
            c.set(x, c.r(hh), "stonePale" if x < 59 else "stoneLight")
    for hh, xs, n in ((dapex + 3, (59, 60), "stoneDark"), (dapex + 4, (59, 60), "gold"),
                      (dapex + 5, (58, 59, 60, 61), "gold"), (dapex + 6, (59, 60), "fireGold"),
                      (dapex + 7, (59,), "gold")):
        for x in xs:
            c.set(x, c.r(hh), n)
    K.arch_window(c, 57, c.r(73), 5, 10, "round")    # the lord's chamber (the mask at col 57, dy 64)
    # the portal, raised on the steps: a round arch of dressed voussoirs, two orders, the door recessed in the dark
    spring = 28

    def recess(x, hh):
        return "night1" if abs(x - 59.5) <= 8.6 else "stoneDark"
    K.arch_ring(c, 59.5, spring, 12.6, 16.0, vw=3.6, jamb_to=SILL, recess=lambda x, hh: None)
    K.arch_ring(c, 59.5, spring, 10.0, 12.6, vw=3.0, jamb_to=SILL, recess=recess)
    for hh in range(SILL, spring + 12):              # the inner order's soffit in shadow
        for x in range(46, 74):
            if c.is_(x, c.r(hh), "stonePale") and math.hypot(x - 59.5, max(0, hh - spring)) < 12.6:
                c.set(x, c.r(hh), "stone")
    if not open_:
        K.door(c, DOOR[0], c.r(SILL + 27), DOOR[1], c.r(SILL), kind="round")
        for x in range(DOOR[0] + 1, DOOR[1]):        # the gap under the door: the layout's mask lights it at night
            c.set(x, c.r(SILL), "night1")
    else:
        # fix round 2 (the critic's high 7: "by day a dull brown field with a grey smudge"): the room behind the open
        # door is dark by day (the darkest night, not the recess's navy), so the hall's light painted over it
        # (`hallDoorGlow`) reads warm at noon too
        for y in range(c.r(SILL + 30), c.r(SILL) + 1):
            for x in range(DOOR[0], DOOR[1] + 1):
                if c.is_(x, y, "night1"):
                    c.set(x, y, "night0")
        for y in range(c.r(SILL + 25), c.r(SILL) + 1):   # the leaves swung in against the recess's sides
            c.set(DOOR[0], y, "woodDark")
            c.set(DOOR[0] + 1, y, "wood")
            c.set(DOOR[1] - 1, y, "wood")
            c.set(DOOR[1], y, "woodDark")
        for y in range(c.r(SILL + 20), c.r(SILL + 1) + 1):   # a pillar inside, dark against the light
            c.set(55, y, "nightBlue")
            c.set(56, y, "nightSlate")
        for y in range(c.r(SILL + 21), c.r(SILL + 12) + 1):  # a banner hanging inside
            for x in (63, 64, 65):
                c.set(x, y, "crimsonDeep")
    steps(c)
    K.torch_bracket(c, 36, c.r(29))                  # flames: emitters at cols 36 and 81, dy 30
    K.torch_bracket(c, 81, c.r(29))
    for dx, dh, n in ((0, 3, "gold"), (-1, 2, "gold"), (0, 2, "fireGold"), (1, 2, "gold"), (0, 1, "gold"),
                      (-1, 0, "gold"), (1, 0, "gold")):  # the house's lantern carved over the portal
        c.set(60 + dx, c.r(45 + dh), n)
    K.arch_window(c, 22, c.r(36), 3, 7, "round", mullion=False)
    K.arch_window(c, 95, c.r(36), 3, 7, "round", mullion=False)
    K.outline(c)
    return c.im


def forebuilding():
    out = PA.Image(FW * 2, FH)
    WA.blit(out, forebuilding_frame(False), 0, 0)
    WA.blit(out, forebuilding_frame(True), FW, 0)
    return out


def hall_door_glow():
    """The view into the hall through the open door (an emitter at forebuilding col 50, dy SILL; 20 x 32, the opening
    at its cols 1 to 18): the leaves and the jambs inside dark, the ceiling's beams dim, flagstones that recede from
    the threshold to the far wall (lit, their joints converging), the far wall warm, the hearth's glow on it the
    brightest point high in the middle; the pillar and the banner inside stay dark (they are the frame's)."""
    w, h = 20, 32
    im = PA.Image(w, h)
    cx = 9.5
    far = 9                                          # the floor meets the far wall this many rows over the sill
    hearth = (11.0, 24.0)                            # col, rows over the sill: the glow's heart, over the lord's head

    def put(x, up, name, a):
        y = h - 1 - up
        if 0 <= x < w and 0 <= y < h and a > 0.01:
            r, g, b, _ = col(name)
            im.set(x, y, (r, g, b, min(255, int(round(a * 255)))))
    for up in range(h):
        for x in range(w):
            dx = abs(x - cx)
            if dx * dx + max(0, up - 20) ** 2 > 8.7 ** 2 or dx > 8.6:
                continue
            if x in (1, 2, 17, 18):                  # the leaves and the reveal: dark, a little warm light
                put(x, up, "emberDim", 0.2 if up < 22 else 0.08)
                continue
            if up > 27:                              # the ceiling: dark beams
                put(x, up, "emberDim", 0.16 if (x % 3) else 0.06)
                continue
            if up < far:                             # the floor: flagstones receding toward the far wall
                depth = up / float(far)              # 0 at the threshold, 1 at the far wall
                lane = (x - cx) / (1.0 - 0.55 * depth)
                joint = up in (2, 5, 7) or abs((lane + 40.0) % 4.2 - 2.1) < 0.45
                hd = math.hypot((x - hearth[0]) / 9.0, (up - hearth[1]) / 14.0)
                base = 0.42 + 0.3 * depth - 0.15 * min(1.0, hd)
                name = "fireOrange" if depth > 0.4 else "ember"
                put(x, up, "emberDim" if joint else name, base * 0.6 if joint else base)
                continue
            if x in (3, 16):                         # the passage's side walls, in shade toward the far wall
                put(x, up, "ember", 0.32)
                continue
            hd = math.hypot((x - hearth[0]) / 5.5, (up - hearth[1]) / 4.5)
            if up in (far, far + 1):                 # the far wall's foot, where the floor meets it
                put(x, up, "ember", 0.42)
            elif hd < 0.45:
                put(x, up, "fireWhite", 0.95)
            elif hd < 0.9:
                put(x, up, "fireGold", 0.85)
            elif hd < 1.6:
                put(x, up, "fireOrange", 0.72)
            else:
                put(x, up, "ember", 0.55)
    for up in range(1, 21):                          # the pillar (forebuilding cols 55-56)
        for x in (5, 6):
            im.set(x, h - 1 - up, (0, 0, 0, 0))
    for up in range(12, 22):                         # the banner (cols 63-65)
        for x in (13, 14, 15):
            im.set(x, h - 1 - up, (0, 0, 0, 0))
    return im


def hall_door_wedge():
    """The door's wedge of warm light (an emitter at forebuilding col 30, dy -12; 60 x 19): over the threshold and the
    steps (its top 7 rows), then out on the cobbles; the door's width (18 px) at the threshold, 2.5 times it 12 rows
    out; its strength falling away from the door and softly at its sides, smooth alpha in 16 steps (light, not art),
    low enough that the stones show through; gold near the door, orange and ember toward its end."""
    w, h = 60, 19
    im = PA.Image(w, h)
    for y in range(h):
        out = y / float(h - 1)                       # 0 at the threshold, 1 at the far end on the cobbles
        half = 9.0 + out * 13.5
        for x in range(w):
            dx = abs(x - 29.5)
            if dx > half + 1.5:
                continue
            side = 1.0 if dx <= half - 2.5 else max(0.0, (half + 1.5 - dx) / 4.0)
            side = side * side * (3 - 2 * side)
            a = 0.42 * (1 - 0.75 * out) * side
            name = "fireGold" if out < 0.35 else "fireOrange" if out < 0.75 else "ember"
            r, g, b, _ = col(name)
            k = int(a * 16 + 0.5)
            if k > 0:
                im.set(x, y, (r, g, b, min(255, 16 * k)))
    return im


PUFF = 8                                             # a puff frame's side
# b3-wind: build 3 step 6 (the director's call S1 of 16.11. 12:25: "round puffs, not a line"; proven over the live
# frames in ci-out/director/b3/wind/s6/00-smoke-leaves-python.png): four opaque puffs of 2, 3, 4 and 5 px, each in two
# values (a white body and a one-pixel darker, cooler underside), so a puff reads on the rock and on the sky; the
# engine's tint gives the hour's colour and the alpha fades it in steps. Frame 4 is one white pixel: the chimney mouth's
# warm pixel at night (a glow quad, column 3). Every puff stands on the cell's bottom row, centred in it (an odd size
# half a pixel left).
PUFF_SHAPES = [
    ["LL", "DD"],
    [".LL", "LLL", ".DD"],
    [".LL.", "LLLL", "DLLL", ".DD."],
    [".LLL.", "LLLLL", "LLLLL", "DLLLD", ".DDD."],
    ["L"],
    # b3-wind: build 3 step 7 (the director's call T3 of 16.11. 14:41: "a town puff must hold against pale mountains,
    # clouds and sky"; proven over the live town frame in ci-out/director/b3/wind/s7/00-town-smoke-python.png): the
    # town's puffs (frames 5 to 7: 2, 3 and 4 px) in a cool wood-smoke grey body (b) under a lit cap (c) and over a
    # darker underside (d), so the body holds under the pale backdrop and the cap over the dark roofs and trees.
    ["cc", "bb"],
    [".cc", "cbb", ".bd"],
    [".cc.", "cbbb", "bbbd", ".dd."],
]
PUFF_BODY = (255, 255, 255, 255)
PUFF_UNDER = (182, 186, 205, 255)
# Round lh-b3w-72: the noon light is warm and lifts the darker values toward brown, so the body is cooler in the art
# and the day tint (CastleSmoke.townDayTint) cool: the live body about (80, 86, 100), the cap about (176, 182, 194).
PUFF_TOWN = {"c": (255, 255, 255, 255), "b": (109, 130, 152, 255), "d": (78, 104, 132, 255)}


def smoke_puff():
    """A puff of chimney smoke at four sizes (frames 8 px square, 2 to 5 px across) and the mouth's pixel (b3-wind,
    step 6): hard pixel puffs with a light body and a darker underside, no soft alpha rim."""
    out = PA.Image(PUFF * len(PUFF_SHAPES), PUFF)
    for f, rows in enumerate(PUFF_SHAPES):
        n = len(rows[0])
        x0 = (PUFF - n) // 2
        y0 = PUFF - len(rows)
        for y, row in enumerate(rows):
            for x, ch in enumerate(row):
                if ch in PUFF_TOWN:
                    out.set(f * PUFF + x0 + x, y0 + y, PUFF_TOWN[ch])   # b3-wind step 7: the town's puffs
                elif ch != ".":
                    out.set(f * PUFF + x0 + x, y0 + y, PUFF_BODY if ch == "L" else PUFF_UNDER)
    return out


# ------------------------------------------------------------------------------------------------ the curtain
def curtain_b():
    """curtainB with its older arch blocked: the infill rubble a value darker than the wall, set back in a recess (a
    deep shadow under the arch's intrados and down its left jamb), the voussoirs a full ring in the wall's own stone,
    lit only on the left haunch where the light falls on them; no pale outline."""
    c = C(64, 74)
    seed = 517
    K.curtain_body(c, 0, 63, seed)
    cx = 31.5
    for x in range(16, 48):
        for hh in range(6, 36):
            dx = x - cx
            r = math.hypot(dx, max(0, hh - 18))
            if r <= 11.5:
                k = (hh // 3) * 7 + (x + (hh // 3) * 2) // 4
                name = "stone" if h01(seed, k) < 0.28 else "stoneMid"
                if hh % 3 == 0 or (x + (hh // 3) * 2) % 4 == 0:
                    name = "stoneMid" if name == "stone" else "stoneDark"
                if (hh > 18 and r > 9.7) or dx < -9.8:
                    name = "stoneDark"                   # the recess's shadow under the intrados, down the left jamb
                c.set(x, c.r(hh), name)
            elif r <= 14.2 and hh >= 16:
                theta = math.atan2(max(0, hh - 18), dx)
                arc = theta * 12.8
                joint = arc % 3.2 < 0.8
                lit = dx < 0 and theta > 1.8
                name = "stoneMid" if joint else ("stoneLight" if lit and int(arc // 3.2) % 2 else "stone")
                c.set(x, c.r(hh), name)
    K.outline(c, sides=("top",))
    return c.im


# ------------------------------------------------------------------------------------------------ the postern
PASS = K.PASS


def postern(tier):
    """keepart's postern with the passage given depth: the jambs' inner faces in shadow narrowing toward the far end,
    the vault's soffit dark above, the far end a small arch of the valley's daylight (its lantern-warm glow at night is
    posternFarGlow), and cobbles that recede to it; the open leaf against the west jamb stays."""
    im = K.postern(tier)
    c = C(K.PW, K.PH)
    c.im = im
    cx = (PASS[0] + PASS[1]) / 2.0                  # 100: the passage's middle
    far_half, far_floor, far_top = 4.5, 4, 18       # the far opening: 9 wide, its floor 4 rows up, its crown at h 18
    for hh in range(0, 31):
        for x in range(PASS[0] + 3, PASS[1] + 2):
            dx = x - cx + 0.5
            if dx * dx + max(0, hh - 20) ** 2 > 10.4 ** 2 or abs(dx) > 8.4:
                continue
            fdx = abs(dx)
            if hh < far_floor:                      # the floor: cobbles receding, narrowing to the far end
                half = 8.4 - (8.4 - far_half) * hh / float(far_floor)
                if fdx <= half:
                    depth = hh / float(far_floor)
                    pitch = 2.8 - 1.3 * depth
                    k = int((dx + 20) / pitch)
                    joint = hh == 2 or ((dx + 20) % pitch) < 0.7
                    c.set(x, c.r(hh), "stoneDark" if joint else ("stone" if k % 2 else "stoneMid"))
                else:
                    c.set(x, c.r(hh), "stoneDark" if dx < 0 else "night1")
                continue
            in_far = fdx <= far_half and hh <= far_top - (fdx * fdx) / (far_half * 2.2)
            if in_far:                              # the valley beyond: pale sky over a green rise, a tree's dark
                if hh >= 11:
                    name = "mistLight" if hh > 14 else "daySky"
                elif hh >= 7:
                    name = "meadow" if (x + hh) % 5 else "leafLight"
                else:
                    name = "leaf"
                if x == int(cx) + 2 and 7 <= hh <= 12:
                    name = "leafDark"
                c.set(x, c.r(hh), name)
                continue
            side = fdx - far_half                   # how far out from the far opening: the jambs' inner faces
            if fdx <= far_half + 1.5:
                c.set(x, c.r(hh), "stoneDark" if hh < 24 else "night1")   # the vault's soffit over the far arch
            elif dx < 0:
                c.set(x, c.r(hh), "stoneMid" if side < 2.2 and hh < far_top else "stoneDark")
            else:
                c.set(x, c.r(hh), "stoneDark" if side < 2.2 and hh < far_top else "night1")
    if tier == 3:
        return postern_pole(c.im)
    return c.im


# Build 3, POLISH pass 1 step 2 (lane 3, the critic's M6): the tier-3 postern's flag flies as a prop of its own
# (`keepFlag`, `SceneLayout.castlePosternFlag`) from a pole raised to POSTERN_POLE, so the cloth clears the roof's point
# when it hangs limp. The painting stays as it was (its rows keep their noise): the canvas grows POSTERN_RISE rows on
# top, the pole runs up through them, its gold point over it.
POSTERN_RISE = 12
POSTERN_POLE = 122
POSTERN_POLE_X = 142     # keepart.py: the squat tower's middle, (114 + 170) / 2


def postern_pole(im):
    out = PA.Image(im.w, im.h + POSTERN_RISE)
    for y in range(im.h):
        for x in range(im.w):
            out.set(x, y + POSTERN_RISE, im.get(x, y))
    top = out.h - 1 - POSTERN_POLE
    for y in range(top, POSTERN_RISE + 1):
        out.set(POSTERN_POLE_X, y, col("woodDark"))
    out.set(POSTERN_POLE_X, top - 1, col("gold"))
    return out


def postern_far_glow():
    """The postern's far end at night (an emitter over the passage's far opening, cols 95 to 104, dy 4): a lantern's
    warm light beyond the passage, brightest low in the opening, smooth alpha."""
    w, h = 10, 16
    im = PA.Image(w, h)
    for y in range(h):
        up = h - 1 - y
        for x in range(w):
            fdx = abs(x - 4.5)
            if up > 14 - (fdx * fdx) / (4.5 * 2.2) or fdx > 4.6:
                continue
            a = 0.75 - 0.03 * up - 0.05 * fdx
            name = "fireGold" if up < 6 else "fireOrange"
            r, g, b, _ = col(name)
            k = int(a * 16 + 0.5)
            if k > 0:
                im.set(x, y, (r, g, b, min(255, 16 * k)))
    return im


# ------------------------------------------------------------------------------------------- the gate's jamb
JAMB_W, JAMB_H, JAMB_UNDER = 16, 116, 26
JAMB_SPRING = (64, 20)   # the gatehouse's gateway springs at about y 62, the postern's at 20


def gate_jamb(seed, spring):
    """The near jamb of a gate passage in the foreground while the lord passes: an opaque pier of 12 px of the gate's own
    coursed stone (the wall's thickness, nearest the eye; the foreground's light keeps it a step darker), standing beside the opening's east edge from 6 rows
    under the lane (it stands nearer than the gate's own foot) up to the passage's springing, where its top is cut as
    the arch begins (rising toward the opening); a warm lit edge on its left and along that cut (the torch inside), a
    shaded right edge. A doorpost that frames the lord, never a bar across the screen (round lh-w2f1-1 drew it to the
    screen's top) and never a ghost (round lh-w2f1-2 drew it see-through)."""
    c = C(JAMB_W, JAMB_H)
    x0, x1 = 2, 13
    foot = JAMB_UNDER - 6                           # rows from the sprite's bottom where the pier stands
    for x in range(x0, x1 + 1):
        top = foot + 6 + spring + (x1 - x) // 2     # the cut rises 5 rows toward the opening (left)
        for up in range(foot, top + 1):
            y = JAMB_H - 1 - up
            k = up // 6
            off = int(h01(seed, k) * 7)
            joint = (up % 6 == 0) or ((x + off) % 9 == 0)
            if up == top or up == top - 1 and x < x1 - 2:
                name = "stonePale" if up == top else "stoneLight"   # the cut catches the passage's torch
            elif x == x0:
                name = "stoneLight" if joint else "stonePale"
            elif x == x0 + 1:
                name = "stoneMid" if joint else "stone"
            elif x == x1:
                name = "stoneDark"
            else:
                name = "stoneDark" if joint else ("stoneMid" if h01(seed, k, (x + off) // 9) < 0.6 else "stone")
            c.set(x, y, name)
    return c.im


def gate_arch_fg():
    """Frame 0: the gatehouse's near jamb (at the gateway's east side), frame 1: the postern's."""
    out = PA.Image(JAMB_W * 2, JAMB_H)
    WA.blit(out, gate_jamb(1301, JAMB_SPRING[0]), 0, 0)
    WA.blit(out, gate_jamb(2333, JAMB_SPRING[1]), JAMB_W, 0)
    return out


BUILDERS = {
    "keepT1": lambda: keep(1), "keepT2": lambda: keep(2), "keepT3": lambda: keep(3),
    "keepT2Build": lambda: keep(2, True), "keepT3Build": lambda: keep(3, True),
    "keepRimT1": lambda: keep_rim(1), "keepRimT2": lambda: keep_rim(2), "keepRimT3": lambda: keep_rim(3),
    "keepRimT2Build": lambda: keep_rim(2, True), "keepRimT3Build": lambda: keep_rim(3, True),
    "keepMist": keep_mist, "keepPaneHalo": keep_pane_halo, "keepFireGlow": keep_fire_glow,
    "forebuilding": forebuilding, "hallDoorGlow": hall_door_glow, "hallDoorWedge": hall_door_wedge,
    "smokePuff": smoke_puff, "curtainB": curtain_b,
    "posternT1": lambda: postern(1), "posternT2": lambda: postern(2), "posternT3": lambda: postern(3),
    "posternFarGlow": postern_far_glow, "gateArchFg": gate_arch_fg,
}


def main():
    a = sys.argv[1:]
    out = a[a.index("--out") + 1] if "--out" in a else "."
    if a and a[0] == "build":
        names = [n for n in a[1:] if not n.startswith("--") and n != out]
    else:
        names = list(BUILDERS)
    for n in names:
        im = BUILDERS[n]()
        path = os.path.join(out, n + ".png")
        PA.write_png(path, im)
        print("wrote", path, im.w, "x", im.h)


if __name__ == "__main__":
    main()
