#!/usr/bin/env python3
"""Lanternhold world rebuild, step world-2 (DESIGN.md "World rebuild (14.11.2026)", ART-look2.md section 23): one castle,
exteriors only. Pure python on pixelart.py's Image; palette colours only; no randomness (hashes of the position), so a
run reproduces its files byte for byte. Hand-placed vocabulary in the gatehouse's language (castleFront): coursed
ashlar with soft joints, lit left edges and cast shadows from the upper left, crenels with lit caps, corbel tables,
teal slate, round-arched and lancet windows whose glass (night1) the layout's masks light, the realm's teal banner with
its gold lantern.

  keepart.py build <id> [<id> ...] --out <Resources/Art>
  keepart.py all --out <Resources/Art>

  keepT1, keepT2, keepT3            200x175  the one keep (mistBand parallax, drawn in the near plane's picture)
  keepT2Build, keepT3Build          200x175  the next tier under scaffolding
  curtainA, curtainB, curtainC      64x72    the curtain wall (wall walk, merlons, a corbel table)
  curtainStair                      52x66    the stair to the wall walk
  curtainTower                      44x104   a wall tower
  curtainHoard                      64x22    tier 2 and 3: a timber hoarding on the wall walk
  castleBanner                      12x30    tier 3: the realm's banner hung from the parapet
  forebuilding                      120x96 x 2  the keep's porch with the hall door (closed, open)
  hallDoorGlow                      20x30    emissive: the hall's warm light through the open door
  hallDoorWedge                     60x12    emissive: the door's warm wedge of light on the cobbles
  chapelTower                       110x132 x 2  the chapel of the Flame, a closed tower in the wall (the bell, gone)
  bakehouse                         100x62   the kitchen's lean-to with the oven's hatch and a chimney
  bakeHatchGlow                     6x6      emissive: the oven's fire through the hatch
  posternT1, posternT2, posternT3   176x112  the back gate per tier: a squat tower and the passage at x 100
  gateArchFg                        64x180   foreground: the gate passage's dark arch while the lord passes through
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import pixelart as PA  # noqa: E402
import worldart as WA  # noqa: E402
import townart as TA  # noqa: E402

col, h01 = WA.col, WA.h01
CLEAR = (0, 0, 0, 0)
S = ["stoneDark", "stoneMid", "stone", "stoneLight", "stonePale"]
SIDX = {col(n): i for i, n in enumerate(S)}
SLATE = TA.SLATE


class C:
    """A canvas in image rows (0 at the top). `r(h)` is the row of a height above the ground line (the last row is
    h 0)."""

    def __init__(self, w, h):
        self.w, self.h = w, h
        self.im = PA.Image(w, h)

    def r(self, hh):
        return self.h - 1 - hh

    def set(self, x, y, name):
        if 0 <= x < self.w and 0 <= y < self.h:
            self.im.set(x, y, col(name) if isinstance(name, str) else name)

    def get(self, x, y):
        if 0 <= x < self.w and 0 <= y < self.h:
            return self.im.get(x, y)
        return CLEAR

    def clear(self, x, y):
        if 0 <= x < self.w and 0 <= y < self.h:
            self.im.set(x, y, CLEAR)

    def rect(self, x0, y0, x1, y1, name):
        for y in range(max(0, y0), min(self.h, y1 + 1)):
            for x in range(max(0, x0), min(self.w, x1 + 1)):
                self.im.set(x, y, col(name))

    def opaque(self, x, y):
        return self.get(x, y)[3] > 0

    def is_(self, x, y, name):
        return self.get(x, y) == col(name)

    def step(self, x, y, d):
        """Moves a stone pixel d steps along the stone ramp."""
        i = SIDX.get(self.get(x, y))
        if i is not None and d:
            self.set(x, y, S[max(0, min(4, i + d))])


# ------------------------------------------------------------------------------------------------------ stone
def ashlar(c, x0, y0, x1, y1, seed, course=5, bmin=6, bmax=12, joints=1.0, darken=None, foot=0.0, light=0.07,
           dark=0.09, bed=0.8, quoins=False):
    """Coursed dressed stone over the box (image rows y0 top .. y1 bottom), calm as the gatehouse's: courses `course`
    rows high in a running bond of blocks bmin..bmax wide; most blocks the plain stone, a lit stoneLight block now and
    then (`light`, more toward the upper left) and a darker stoneMid one (`dark`, more toward the foot); the bed
    joints a step darker and broken (`bed` of them drawn), a vertical joint at a block's left (`joints` of them); only a
    lit block shows its dressed top edge. `darken(x, y)` gives an extra step (0 or -1) per block (the face turning from
    the light); `foot` the share of the lowest rows where weathered blocks darken more often. `quoins`: long and short
    corner stones at both ends, lit on the left, shaded on the right."""
    k = 0
    y = y1 + 1
    hgt = max(1, y1 - y0)
    wid = max(1, x1 - x0)
    while y > y0:
        top = max(y0, y - course)
        bot = y - 1
        off = int(h01(seed, k, 3) * bmax)
        x = x0 - off
        n = 0
        while x <= x1:
            w = bmin + int(h01(seed, k, n, 5) * (bmax - bmin + 1))
            v = h01(seed, k, n, 7)
            cx, cy = x + w // 2, (top + bot) // 2
            up = 1 - (y1 - cy) / float(hgt)          # 0 at the top, 1 at the foot
            left = (cx - x0) / float(wid)
            pl = light * (1.4 - up * 0.8) * (1.3 - left * 0.6)
            pd = dark * (0.6 + up * 0.9)
            if foot and up > 1 - foot:
                pd += 0.18
            val = 3 if v < pl else 1 if v > 1 - pd else 2
            if darken:
                val += darken(cx, cy)
            val = max(0, min(4, val))
            for yy in range(top, bot + 1):
                for xx in range(max(x, x0), min(x + w, x1 + 1)):
                    q = val
                    if yy == bot and bot - top >= 2 and h01(seed, xx, yy, 19) < bed:
                        q = max(0, min(val, 2) - 1)                            # the bed joint
                    if xx == x and yy != bot and h01(seed, k, n, 13) < joints:
                        q = max(0, min(q, 2) - 1)                              # the vertical joint
                    c.set(xx, yy, S[q])
            x += w
            n += 1
        y = top
        k += 1
    if quoins:
        k = 0
        for yy in range(y1, y0 - 1, -course):
            longq = k % 2 == 0
            ql = 7 if longq else 4
            for d in range(course):
                ry = yy - d
                if ry < y0:
                    break
                for i in range(ql):
                    lx, rx = x0 + i, x1 - i
                    c.set(lx, ry, "stonePale" if d == course - 1 and i < ql - 1 else "stoneLight")
                    c.set(rx, ry, "stoneMid" if d != 0 else "stoneDark")
                c.set(x0 + ql, ry, "stoneMid")
            k += 1


def rubble(c, x0, y0, x1, y1, seed):
    TA.rubble(c.im, x0, y0, x1, y1, seed)


def string_course(c, x0, x1, y, lit_to=None):
    """A projecting moulding at row y: a pale top row, a stone row, and its shadow on the wall under it."""
    for x in range(x0, x1 + 1):
        lit = lit_to is None or x < lit_to
        c.set(x, y, "stonePale" if lit else "stoneLight")
        c.set(x, y + 1, "stone" if lit else "stoneMid")
        c.set(x, y + 2, "stoneDark")


def corbel_table(c, x0, x1, y, period=4, depth=3):
    """A row of corbels under a parapet (rows y .. y+depth-1): dark gaps between small lit brackets."""
    for x in range(x0, x1 + 1):
        k = (x - x0) % period
        for d in range(depth):
            if k == 0:
                c.set(x, y + d, "stoneLight" if d == 0 else "stone")
            elif k == period - 1:
                c.set(x, y + d, "stoneMid")
            else:
                c.set(x, y + d, "night1" if d < depth - 1 else "stoneDark")


def machicolations(c, x0, x1, y, period=5, depth=4):
    """Machicolations: a corbelled parapet's slots (ink) between corbels that step out (lit tops)."""
    for x in range(x0, x1 + 1):
        k = (x - x0) % period
        for d in range(depth):
            if k == 0:
                c.set(x, y + d, ("stoneLight", "stone", "stoneMid", "stoneMid")[d])
            elif k == 1:
                c.set(x, y + d, ("stone", "stoneMid", "stoneMid", "stoneDark")[d])
            else:
                c.set(x, y + d, "ink" if d < depth - 1 else "stoneDark")


def merlons(c, x0, x1, ytop, mh=5, mw=5, gap=3, seed=0, phase=0):
    """Crenels from x0 to x1: merlons mw wide and mh high from row ytop down, the crenel gaps cleared (the parapet wall
    under them is the caller's). Each merlon a stone body with a lit cap and left edge and a shaded right column."""
    period = mw + gap
    for x in range(x0, x1 + 1):
        k = (x - x0 + phase) % period
        for y in range(ytop, ytop + mh):
            if k >= mw:
                c.clear(x, y)
                continue
            name = "stone"
            if y == ytop:
                name = "stonePale" if k < mw - 1 else "stoneLight"
            elif k == 0:
                name = "stoneLight"
            elif k == mw - 1:
                name = "stoneMid"
            elif h01(seed, (x - x0 + phase) // period, y) < 0.12:
                name = "stoneMid"
            c.set(x, y, name)


def slit(c, x, y, h, w=1):
    """An arrow slit from row y down h rows: a dark slot, a lit left jamb, a shaded right one, a pale sill."""
    for yy in range(y, y + h):
        for xx in range(x, x + w):
            c.set(xx, yy, "ink")
        c.set(x - 1, yy, "stoneLight")
        c.set(x + w, yy, "stoneMid")
    c.set(x, y - 1, "stoneMid")
    for xx in range(x - 1, x + w + 1):
        c.set(xx, y + h, "stonePale" if xx < x + w else "stoneLight")


def arch_window(c, x, y, w, h, kind="round", sill=True, mullion=True):
    """A window whose glass box is x, y, w, h (night1, lit by the layout's mask): a round or pointed head, a pale
    voussoir ring and left jamb, a shaded right jamb, a sill and its shadow; a mullion for a wide round window."""
    head = (w + 1) // 2 if kind == "round" else w // 2 + 2
    for yy in range(y, y + h):
        for xx in range(x, x + w):
            d = yy - y
            inside = True
            if d < head:
                if kind == "round":
                    rr = (w - 1) / 2.0
                    dx = abs(xx - x - rr)
                    inside = (dx * dx + (head - d - 0.5) ** 2) <= (rr + 0.6) ** 2
                else:
                    dx = abs(xx - x - (w - 1) / 2.0)
                    inside = dx <= (d + 0.6) * (w / 2.0) / head + 0.1
            if inside:
                c.set(xx, yy, "night1")
    ring = []
    for yy in range(y - 1, y + h + 1):
        for xx in range(x - 1, x + w + 1):
            if c.is_(xx, yy, "night1"):
                continue
            if any(c.is_(xx + ax, yy + ay, "night1") for ax, ay in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                ring.append((xx, yy))
    for xx, yy in ring:
        left = xx < x + w / 2.0
        c.set(xx, yy, "stonePale" if left and yy < y + head else "stoneLight" if left else "stoneMid")
    if mullion and w >= 5 and kind == "round":
        for yy in range(y + head, y + h):
            c.set(x + w // 2, yy, "stoneMid")
    if sill:
        for xx in range(x - 1, x + w + 1):
            c.set(xx, y + h, "stonePale" if xx < x + w else "stoneLight")
            c.set(xx, y + h + 1, "stoneDark")


def arch_ring(c, cx, spring, r_in, r_out, vw=4.0, jamb_to=0, inner="night1", recess=None):
    """A round arch of dressed voussoirs: the ring between r_in and r_out over the springing at height `spring`
    (centre column cx, may be a half), cut into blocks about `vw` px along the arc with dark joints; the left half lit
    (pale and light blocks in turn), the right half a step darker, a pale keystone; below the springing the jambs in
    long and short blocks down to `jamb_to`. Inside the ring `inner` (the opening), or `recess(x, hh)` naming a colour."""
    for hh in range(jamb_to, spring + int(r_out) + 2):
        for x in range(int(cx - r_out) - 1, int(cx + r_out) + 2):
            dx = x - cx
            if hh >= spring:
                r = math.hypot(dx, hh - spring)
                if r > r_out:
                    continue
                if r <= r_in:
                    name = recess(x, hh) if recess else inner
                    if name:
                        c.set(x, c.r(hh), name)
                    continue
                theta = math.atan2(hh - spring, dx)              # 0 at the right springing, pi at the left
                arc = theta * (r_in + r_out) / 2.0
                k = int(arc // vw)
                joint = (arc % vw) < 0.9 or r > r_out - 0.6
                left = dx < 0
                key = abs(theta - math.pi / 2) < vw / (r_in + r_out)
                if joint:
                    name = "stoneDark" if not left else "stoneMid"
                elif key:
                    name = "stonePale"
                elif left:
                    name = "stonePale" if k % 2 else "stoneLight"
                else:
                    name = "stoneLight" if k % 2 else "stone"
                c.set(x, c.r(hh), name)
            else:
                if abs(dx) <= r_in:
                    name = recess(x, hh) if recess else inner
                    if name:
                        c.set(x, c.r(hh), name)
                    continue
                if abs(dx) > r_out:
                    continue
                k = (spring - hh) // 5
                width = (r_out - r_in) * (1.0 if k % 2 else 0.6)
                if abs(dx) - r_in > width + 0.5:
                    continue
                left = dx < 0
                joint = (spring - hh) % 5 == 4
                name = ("stoneMid" if joint else ("stonePale" if left else "stone")) if left else \
                       ("stoneDark" if joint else "stoneMid")
                if not left and abs(dx) - r_in < 1.5 and not joint:
                    name = "stone"
                c.set(x, c.r(hh), name)


def gable_coping(c, cx, eave, apex, half, x0, x1):
    """A gable's coping: a thick band of dressed stone along both slopes (a lit top on the left slope, a light one on
    the right), its shadow on the gable under it, kneelers at the eaves."""
    for hh in range(eave - 1, apex + 4):
        w = (apex - hh) * float(half) / (apex - eave)
        for side in (-1, 1):
            edge = cx + side * (w + 2)
            for d in range(4):
                x = int(round(edge - side * d))
                if side < 0:
                    name = ("stonePale", "stonePale", "stone", "stoneDark")[d]
                else:
                    name = ("stoneLight", "stone", "stoneMid", "stoneDark")[d]
                c.set(x, c.r(hh), name)
    for (kx, lit) in ((x0 - 3, True), (x1 - 3, False)):
        for x in range(kx, kx + 7):
            for hh in range(eave - 3, eave + 3):
                top = hh == eave + 2
                c.set(x, c.r(hh), ("stonePale" if top else "stoneLight") if lit else ("stoneLight" if top else "stoneMid"))
            c.set(x, c.r(eave - 4), "stoneDark")


def door(c, x0, y0, x1, y1, kind="round"):
    """An oak door under a round or pointed head: planks with lit edges, two iron straps, a ring."""
    w = x1 - x0 + 1
    head = (w + 1) // 2 if kind == "round" else w // 2 + 2
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            d = y - y0
            if d < head:
                rr = (w - 1) / 2.0
                dx = abs(x - x0 - rr)
                if kind == "round":
                    if dx * dx + (head - d - 0.5) ** 2 > (rr + 0.6) ** 2:
                        continue
                elif dx > (d + 0.6) * (w / 2.0) / head + 0.1:
                    continue
            k = (x - x0) % 3
            c.set(x, y, ("woodLight", "wood", "woodDark")[k] if x < x1 else "woodDark")
    for y in (y0 + head + 1, y1 - 3):
        for x in range(x0, x1 + 1):
            if c.opaque(x, y):
                c.set(x, y, "stoneMid" if x != x0 + 1 else "stoneLight")
    c.set(x1 - 2, (y0 + y1) // 2 + 2, "stonePale")
    c.set(x1 - 2, (y0 + y1) // 2 + 3, "stoneMid")


def banner(c, x, y, w, h, emblem=True, tail=True):
    """The realm's banner hanging from a bar at row y - 1: deep teal with lit folds, a swallowtail and the gold lantern
    of the guardian house."""
    for yy in range(y, y + h):
        for xx in range(x, x + w):
            d = yy - (y + h - 4)
            if tail and d >= 0 and abs(xx - (x + (w - 1) / 2.0)) < d + 0.5:
                continue
            name = "roofDeep"
            if (xx - x) in (1, w - 3):
                name = "banner"
            if xx == x + w - 1:
                name = "night1"
            c.set(xx, yy, name)
    for xx in range(x - 1, x + w + 1):
        c.set(xx, y - 1, "woodDark")
    c.set(x - 1, y - 1, "woodLight")
    for xx in range(x, x + w - 1):
        c.set(xx, y, "banner")
    if emblem and w >= 5:
        ex = x + (w - 1) // 2 - (0 if w % 2 else 1)
        ey = y + h // 2 - 3
        for dx, dy, n in ((0, 0, "gold"), (-1, 1, "gold"), (0, 1, "fireGold"), (1, 1, "gold"), (-1, 2, "gold"),
                          (0, 2, "fireGold"), (1, 2, "gold"), (-1, 3, "gold"), (1, 3, "gold"), (0, 3, "cloth2")):
            c.set(ex + dx, ey + dy, n)


def flag(c, x, ytop, length, h=5):
    """A flag streaming right from a pole at col x: teal with a lit top edge, a ragged end, a gold point."""
    for yy in range(ytop, ytop + h):
        for xx in range(x + 1, x + 1 + length - (2 if (yy - ytop) % 2 else 0)):
            c.set(xx, yy, "banner" if yy == ytop else "roofDeep")
    c.set(x + length // 2, ytop + 2, "gold")


def pole(c, x, ytop, ybot):
    for yy in range(ytop, ybot + 1):
        c.set(x, yy, "woodDark")
    c.set(x, ytop - 1, "gold")


def outline(c, sides=("right", "bottom", "top", "left"), name="ink"):
    """The gatehouse's outline: on the left, right and bottom, `name` on the silhouette's own edge pixels that face
    transparency; on top a line of `name` laid over the silhouette, outside it, so a merlon's or a coping's lit cap
    keeps its light under the dark edge."""
    marks, over = [], []
    for y in range(c.h):
        for x in range(c.w):
            if not c.opaque(x, y):
                if "top" in sides and y + 1 < c.h and c.opaque(x, y + 1):
                    over.append((x, y))
                continue
            if (("right" in sides and x + 1 < c.w and not c.opaque(x + 1, y)) or
                    ("left" in sides and x > 0 and not c.opaque(x - 1, y)) or
                    ("bottom" in sides and y + 1 < c.h and not c.opaque(x, y + 1))):
                marks.append((x, y))
    for x, y in marks + over:
        c.set(x, y, name)


def scaffold(c, x0, x1, ybot, ytop, seed, ladder=True):
    """Timber scaffolding: standards every 9 px, ledgers every 8 rows with boards, braces, a ladder."""
    xs = list(range(x0, x1 + 1, 9))
    if xs[-1] != x1:
        xs.append(x1)
    for x in xs:
        for y in range(ytop, ybot + 1):
            c.set(x, y, "woodDark")
        c.set(x, ytop, "wood")
    for y in range(ybot - 2, ytop - 1, -8):
        for x in range(x0, x1 + 1):
            c.set(x, y, "woodLight" if (x - x0) % 9 else "wood")
            c.set(x, y + 1, "woodDark")
    for i, x in enumerate(xs[:-1]):
        if i % 2 == 0:
            for t in range(min(8, ybot - ytop)):
                c.set(x + t, ybot - 3 - t, "wood")
    if ladder:
        lx = x0 + 3 + int(h01(seed) * max(1, (x1 - x0 - 8)))
        for y in range(ytop + 6, ybot + 1):
            c.set(lx, y, "woodLight")
            c.set(lx + 3, y, "wood")
            if y % 3 == 0:
                c.set(lx + 1, y, "woodLight")
                c.set(lx + 2, y, "wood")


def torch_bracket(c, x, y):
    """An iron torch bracket on the wall, its cup's top at row y (the flame is an emitter of the layout)."""
    for xx in (x, x + 1, x + 2):
        c.set(xx, y, "woodDark")
    c.set(x, y + 1, "stoneDark")
    c.set(x + 1, y + 1, "woodDark")
    c.set(x + 2, y + 1, "stoneDark")
    c.set(x + 1, y + 2, "stoneDark")
    c.set(x + 1, y + 3, "stoneDark")
    c.set(x, y + 4, "stoneDark")
    c.set(x + 1, y + 4, "stoneDark")


def lantern_bracket(c, x, y):
    """A wall lantern on an iron arm, its cap at row y: glass (night1) cols x..x+2, rows y+1..y+4 (a lanternGlass
    emitter of the layout lights it), a base."""
    for xx in range(x - 1, x + 4):
        c.set(xx, y, "stoneDark")
    c.set(x + 1, y - 1, "stoneDark")
    c.set(x + 1, y - 2, "stoneDark")
    for yy in range(y + 1, y + 5):
        c.set(x - 1, yy, "stoneDark")
        c.set(x + 3, yy, "stoneDark")
        for xx in range(x, x + 3):
            c.set(xx, yy, "night1")
    for xx in range(x - 1, x + 4):
        c.set(xx, y + 5, "stoneDark")
    c.set(x + 1, y + 6, "stoneDark")


# -------------------------------------------------------------------------------------------------- the keep
KW, KH = 200, 175
TIERS = {
    # the corner towers' walls (to their crown), the main block's walls, the roof's ridge, the chimney's top
    1: dict(tower=106, wall=98, ridge=120, chimney=122),
    2: dict(tower=126, wall=118, ridge=140, chimney=142),
    3: dict(tower=126, wall=118, ridge=140, chimney=142),
}
KTOWERS = ((4, 37), (162, 195))
KBODY = (38, 161)


PILASTERS = (68, 98, 128)   # the main block's pilaster buttresses (left columns, 5 wide): four bays


def keep_windows(tier, building=False):
    """The keep's lit panes as (x, dy from the bottom row, w, h) for the layout's masks: the twin round-arched windows
    of the main block's upper storeys, in its two middle bays (tier 1), and the storey above in all four bays (tiers 2
    and 3; none while it is built)."""
    wins = [(79, 80, 7, 10), (110, 80, 7, 10)]
    if tier >= 2 and not building:
        wins += [(48, 100, 7, 10), (79, 100, 7, 10), (110, 100, 7, 10), (141, 100, 7, 10)]
    return wins


def twin_window(c, x, ybot, w=7, h=10):
    """A Norman twin window: two round-headed lights (3 wide) under one relieving arch, a colonnette between, a sill
    (glass night1 in the box x, ybot-h+1, w, h)."""
    y = ybot - h + 1
    arch_window(c, x, y, 3, h, "round", sill=False, mullion=False)
    arch_window(c, x + 4, y, 3, h, "round", sill=False, mullion=False)
    c.set(x + 3, y + 2, "stoneLight")
    for yy in range(y + 3, y + h):
        c.set(x + 3, yy, "stone")
    for xx in range(x - 2, x + w + 2):           # the relieving arch over both
        dx = xx - (x + w / 2.0 - 0.5)
        r = w / 2.0 + 1.5
        if abs(dx) <= r:
            yy = int(round(y + 1 - (r * r - dx * dx) ** 0.5 * 0.55))
            c.set(xx, yy, "stonePale" if dx < 0 else "stoneLight")
            c.set(xx, yy + 1, "stoneMid")
    for xx in range(x - 1, x + w + 1):
        c.set(xx, ybot + 1, "stonePale" if xx < x + w else "stoneLight")
        c.set(xx, ybot + 2, "stoneDark")


def keep_body(c, t, tier, seed, building=False):
    tw, ww = t["tower"], t["wall"]
    bx0, bx1 = KBODY

    def turn(x, y):                              # the right part turns from the light, block by block
        share = (x - bx0 - 86) / 40.0
        return -1 if share > 0 and h01(seed, x // 7, y // 4, 17) < share else 0
    ashlar(c, bx0, c.r(ww), bx1, c.r(0), seed, course=4, bmin=6, bmax=11, joints=0.45, darken=turn, foot=0.25,
           light=0.05, dark=0.08, bed=0.6)
    for x in range(bx0, bx1 + 1):                # the battered plinth
        for hh in range(0, 6):
            c.set(x, c.r(hh), "stoneMid" if hh < 5 else "stoneLight")
    # pilaster buttresses: four bays; each lit on its left, shaded on its right, its shadow on the wall to the right
    for px in PILASTERS:
        for y in range(c.r(ww - 2), c.r(5)):
            c.set(px, y, "stoneLight")
            c.set(px + 1, y, "stoneLight" if (y // 4) % 2 else "stone")
            c.set(px + 2, y, "stone")
            c.set(px + 3, y, "stoneMid")
            c.set(px + 4, y, "stoneDark")
            c.step(px + 5, y, -1)
            if (y // 2) % 2:
                c.step(px + 6, y, -1)
        c.set(px, c.r(ww - 2), "stonePale")
    string_course(c, bx0, bx1, c.r(70), lit_to=bx0 + 96)
    if ww > 100:
        string_course(c, bx0, bx1, c.r(92), lit_to=bx0 + 96)
    # the parapet on a corbel table, its merlons
    corbel_table(c, bx0, bx1, c.r(ww - 1), period=4, depth=3)
    for x in range(bx0, bx1 + 1):
        c.set(x, c.r(ww), "stoneDark")
        c.set(x, c.r(ww + 1), "stone" if x < bx1 - 26 else "stoneMid")
        c.set(x, c.r(ww + 2), "stoneLight" if x < bx1 - 26 else "stone")
    merlons(c, bx0 + 1, bx1 - 1, c.r(ww + 7), mh=5, mw=5, gap=3, seed=seed)
    # the corner towers stand forward: lighter on the left one, a step darker on the right one, quoins, slits, a
    # crown on machicolations; the left tower throws its shadow on the main block
    for i, (x0, x1) in enumerate(KTOWERS):
        ashlar(c, x0, c.r(tw), x1, c.r(0), seed + 31 * (i + 1), course=4, bmin=6, bmax=10, joints=0.45,
               foot=0.25, light=0.10 if i == 0 else 0.03, dark=0.06 if i == 0 else 0.16, bed=0.6, quoins=True,
               darken=(lambda x, y: -1 if x > 180 and h01(x // 5, y // 4, 23) < 0.7 else 0) if i == 1 else None)
        for hh in range(0, 7):
            for x in range(x0 - 1, x1 + 2):
                c.set(x, c.r(hh), "stoneMid" if hh < 6 else "stoneLight")
        string_course(c, x0, x1, c.r(70), lit_to=x0 + 26 if i == 0 else x0 + 4)
        machicolations(c, x0 - 1, x1 + 1, c.r(tw - 1), period=5, depth=4)
        for x in range(x0 - 2, x1 + 3):
            c.set(x, c.r(tw), "stoneDark")
            c.set(x, c.r(tw + 1), "stone" if x < x1 - 4 else "stoneMid")
            c.set(x, c.r(tw + 2), "stoneLight" if x < x1 - 4 else "stone")
        merlons(c, x0 - 2, x1 + 2, c.r(tw + 8), mh=6, mw=5, gap=3, seed=seed + i)
        cx = (x0 + x1) // 2
        for hh in (80, 100, 116):
            if hh + 9 < tw - 4:
                slit(c, cx, c.r(hh + 6), 7)
        if i == 0:
            for y in range(c.r(ww - 4), c.r(6)):
                for d in range(4):
                    if d < 3 or y % 2:
                        c.step(x1 + 1 + d, y, -1)
    for (x, dy, w, h) in keep_windows(tier, building):
        twin_window(c, x, c.r(dy), w, h)
    for (x, hh) in ((19, 50), (178, 50), (48, 78), (141, 78)):   # unlit openings: storerooms, a stair's slits
        if hh < 60:
            arch_window(c, x, c.r(hh + 6), 3, 7, "round", mullion=False)
        else:
            slit(c, x + 3, c.r(hh + 8), 8)


def keep_roof(c, t, seed):
    """The hip roof behind the parapet: teal slate, the eaves hidden by the merlons, the ridge at t['ridge'], a stone
    chimney stack on the right slope (its smoke is the layout's)."""
    ww, ridge = t["wall"], t["ridge"]
    bx0, bx1 = KBODY
    top, bot = c.r(ridge), c.r(ww + 4)
    run = float(bot - top)
    a0, b0 = bx0 + 5, bx1 - 5
    ra, rb = bx0 + 44, bx1 - 44
    TA.roof(c.im, top, bot, lambda y: int(round(ra - (ra - a0) * (y - top) / run)),
            lambda y: int(round(rb + (b0 - rb) * (y - top) / run)), SLATE, "slate", seed, moss=False, mid=0.55,
            shade=10)
    chx = rb + 8
    TA.chimney(c.im, chx, chx + 5, c.r(t["chimney"]), c.r(ridge - 12), seed)


def cone(c, cx, base, half, h, dim=False):
    """A conical slate cap standing on row base: courses of slate, its left part lit, the right in shade, a finial."""
    for i in range(h):
        y = base - i
        w = half * (h - i) / float(h)
        a, b = int(round(cx - w)), int(round(cx + w))
        for x in range(a, b + 1):
            t = (x - a) / max(1.0, float(b - a))
            if i % 3 == 0:
                name = "banner" if t < 0.4 else "roofDeep"
            else:
                name = "roofLight" if t < 0.3 else "banner" if t < 0.68 else "roofDeep"
            if dim:
                name = {"roofLight": "banner", "banner": "roofDeep", "roofDeep": "roofDeep"}[name]
            c.set(x, y, name)
        c.set(b, y, "night1")
    for x in range(cx - half - 1, cx + half + 2):
        c.set(x, base + 1, "night1")
    c.set(cx, base - h, "gold" if not dim else "stoneLight")
    c.set(cx, base - h - 1, "gold" if not dim else "stoneMid")


def keep_crown(c, t, seed):
    """Tier 3: round bartizans with conical slate caps on the corner towers, two smaller ones behind on the far
    corners, gilded finials."""
    tw = t["tower"]
    for cx in (60, 139):                         # the rear turrets, further back, a step darker
        base = c.r(t["ridge"] - 14)
        for y in range(base - 8, base + 1):
            for x in range(cx - 5, cx + 6):
                c.set(x, y, "stoneMid" if x > cx + 2 else "stone")
        cone(c, cx, base - 9, 7, 12, dim=True)
    for (x0, x1) in KTOWERS:
        cx = (x0 + x1) // 2
        base = c.r(tw + 8)
        for y in range(base - 11, base + 1):     # a drum corbelled out over the crown
            for x in range(cx - 10, cx + 11):
                k = x - (cx - 10)
                name = "stoneLight" if 3 <= k <= 6 else "stoneMid" if k >= 16 else "stone"
                if (base - y) % 4 == 3:
                    name = "stoneMid" if k < 16 else "stoneDark"
                c.set(x, y, name)
        for x in range(cx - 11, cx + 12):
            c.set(x, base + 1, "stoneLight" if x < cx + 6 else "stoneMid")
        slit(c, cx - 1, base - 8, 5)
        cone(c, cx, base - 12, 12, 16)


def crane(c, x, ytop):
    """A builders' crane: a mast, a jib to the right, a rope and a hanging stone."""
    for y in range(ytop, ytop + 22):
        c.set(x, y, "woodDark")
        c.set(x + 1, y, "wood")
    for i in range(16):
        c.set(x + 1 + i, ytop + 4 - i // 4, "woodLight" if i % 3 else "wood")
    rx = x + 15
    for y in range(ytop + 1, ytop + 14):
        c.set(rx, y, "soilLight")
    for y in range(ytop + 14, ytop + 18):
        for xx in range(rx - 2, rx + 3):
            c.set(xx, y, "stoneLight" if xx < rx + 1 else "stoneMid")


def keep(tier, building=False):
    c = C(KW, KH)
    seed = 4100 + tier * 10 + (5 if building else 0)
    t = dict(TIERS[tier - 1] if building else TIERS[tier])
    if not building or tier == 3:
        keep_roof(c, t, seed)
    keep_body(c, t, tier - 1 if building else tier, seed, building)
    if tier == 3 and not building:
        keep_crown(c, t, seed)
    if tier >= 2 and not building:
        tall = tier == 3
        ptop = c.r(170 if tall else 156)
        pole(c, 100, ptop, c.r(t["ridge"] - 1))
        banner(c, 101, ptop + 1, 9 if tall else 7, 22 if tall else 15)
    if building:
        nt = TIERS[tier]
        if tier == 2:
            for x in range(KBODY[0], KBODY[1] + 1):  # the next storey half laid, in ragged courses
                top = t["wall"] + 3 + int(h01(seed, x // 6) * 10)
                for hh in range(t["wall"] + 3, top):
                    c.set(x, c.r(hh), "stoneLight" if (hh // 4 + x // 7) % 3 == 0 else "stone")
            for (x0, x1) in KTOWERS:
                for x in range(x0 - 2, x1 + 3):
                    top = t["tower"] + 9 + int(h01(seed, x // 5, 3) * 8)
                    for hh in range(t["tower"] + 3, top):
                        c.set(x, c.r(hh), "stoneLight" if (hh // 4 + x // 6) % 3 == 0 else "stone")
            scaffold(c, KBODY[0] - 3, KBODY[1] + 3, c.r(t["wall"] - 8), c.r(nt["wall"] + 2), seed)
            crane(c, 146, c.r(nt["wall"] + 6))
        else:
            for (x0, x1) in KTOWERS:                 # tier 3 under way: timber cones on the corner towers
                cx = (x0 + x1) // 2
                base = c.r(t["tower"] + 8)
                for i in range(17):
                    y = base - i
                    w = 11 * (17 - i) / 17.0
                    c.set(int(round(cx - w)), y, "wood")
                    c.set(int(round(cx + w)), y, "woodDark")
                    if i % 4 == 0:
                        for x in range(int(round(cx - w)), int(round(cx + w)) + 1):
                            c.set(x, y, "woodDark")
                    c.set(cx, y, "wood")
                c.set(cx, base - 17, "woodLight")
                scaffold(c, x0 - 4, x1 + 4, c.r(t["tower"] - 8), base - 4, seed + x0, ladder=False)
            pole(c, 100, c.r(156), c.r(t["ridge"] - 1))
            banner(c, 101, c.r(156) + 1, 7, 15)
    outline(c, sides=("right",), name="stoneDark")
    return c.im


# ---------------------------------------------------------------------------------------------- the curtain
CURT_H = 64


def curtain_body(c, x0, x1, seed, top=CURT_H):
    """The curtain wall's face: big coursed ashlar on a battered plinth, a corbel table under the wall walk's parapet,
    merlons with lit caps, a row of putlog holes."""
    ashlar(c, x0, c.r(top - 4), x1, c.r(0), seed, course=6, bmin=8, bmax=15, joints=0.9, foot=0.3)
    for x in range(x0, x1 + 1):
        for hh in range(0, 5):
            c.set(x, c.r(hh), "stoneMid" if hh < 4 else "stoneLight")
        c.set(x, c.r(5), "stoneDark")
    corbel_table(c, x0, x1, c.r(top - 4), period=6, depth=3)
    for x in range(x0, x1 + 1):
        c.set(x, c.r(top - 1), "stoneDark")
        c.set(x, c.r(top), "stone")
        c.set(x, c.r(top + 1), "stoneLight")
    merlons(c, x0, x1, c.r(top + 8), mh=7, mw=9, gap=7, seed=seed, phase=3)
    for x in range(x0 + 6, x1 - 1, 16):           # putlog holes (the builders' beams once)
        c.set(x, c.r(36), "ink")
        c.set(x + 1, c.r(36), "ink")
        c.set(x, c.r(37), "stoneMid")
        c.set(x + 1, c.r(37), "stoneMid")


def ivy(c, x0, h0, w, h, seed):
    """Ivy climbing from the wall's foot: two or three stems that lean and branch, leaves in clusters of five (a lit
    meadow pixel up and left, leaf, a leafDark one down and right) along them, thinning out upward."""
    leaf = ((0, 0, "leaf"), (-1, 0, "leaf"), (1, 0, "leafDark"), (0, 1, "meadow"), (0, -1, "leafDark"),
            (-1, 1, "meadow"))
    for stem in range(3):
        x = x0 + 2 + stem * (w // 3) + int(h01(seed, stem, 41) * 3)
        top = h0 + int(h * (0.55 + 0.45 * h01(seed, stem, 43)))
        for hh in range(h0, top):
            if h01(seed, stem, hh // 4, 45) < 0.5:
                x += 1 if h01(seed, stem, hh, 47) < 0.55 else -1
            c.set(x, c.r(hh), "woodDark")
            share = 1 - (hh - h0) / float(max(1, top - h0))
            if (hh + stem) % 3 == 0 and h01(seed, stem, hh, 49) < 0.45 + 0.5 * share:
                side = -2 if h01(seed, stem, hh, 51) < 0.5 else 2
                for dx, dy, name in leaf:
                    c.set(x + side + dx, c.r(hh + dy), name)


def curtain(kind):
    c = C(64, 74)
    seed = {"curtainA": 501, "curtainB": 517, "curtainC": 533}[kind]
    curtain_body(c, 0, 63, seed)
    if kind == "curtainB":
        # an older arch, blocked with rubble: the castle was rebuilt more than once
        for x in range(18, 46):
            for hh in range(6, 34):
                dx = x - 31.5
                r2 = dx * dx + max(0, hh - 18) ** 2
                if r2 <= 11.5 ** 2:
                    c.set(x, c.r(hh), "stoneMid" if h01(seed, x // 3, hh // 2) < 0.45 else "stone")
                elif r2 <= 14 ** 2:
                    vous = (x + hh) // 2 % 2
                    c.set(x, c.r(hh), ("stonePale" if dx < 0 else "stoneLight") if vous else
                          ("stoneLight" if dx < 0 else "stone"))
    if kind == "curtainC":
        # a buttress: its lit face in courses, its shaded flank, a sloped cap, an ink edge on the shade side and its
        # shadow on the wall; a drain spout and its stain
        for x in range(23, 34):
            k = x - 23
            for hh in range(0, 46):
                if k < 2:
                    name = "stoneLight"
                elif k < 8:
                    name = "stone" if (hh // 6) % 2 or k < 7 else "stoneLight"
                else:
                    name = "stoneMid"
                if hh % 6 == 5:
                    name = "stoneMid" if k < 8 else "stoneDark"
                c.set(x, c.r(hh), name)
            for d in range(4):                    # the sloped cap
                hh = 46 + d
                if k <= 10 - d * 3:
                    c.set(x, c.r(hh), "stonePale" if k < 8 else "stoneLight")
        for hh in range(0, 46):
            c.set(34, c.r(hh), "ink")
        for hh in range(4, 44):
            c.step(35, c.r(hh), -1)
            c.step(36, c.r(hh), -1)
            if hh % 2:
                c.step(37, c.r(hh), -1)
        ivy(c, 4, 0, 16, 26, seed)
        for hh in range(30, 55):
            if h01(seed, hh) < 0.85:
                c.step(50, c.r(hh), -1)
            if h01(seed, hh, 2) < 0.5:
                c.step(51, c.r(hh), -1)
        c.set(49, c.r(56), "stoneLight")
        c.set(50, c.r(56), "stone")
        c.set(51, c.r(56), "stoneDark")
    if kind == "curtainA":
        slit(c, 40, c.r(48), 6)
        ivy(c, 50, 0, 12, 34, seed)
    outline(c, sides=("top",))
    return c.im


def curtain_stair():
    """The stair to the wall walk: a masonry ramp along the wall's face, rising leftward from the ground at the right
    to the walk at h 62, its treads lit; a store under it with a dark mouth."""
    c = C(52, 66)
    seed = 571

    def step_top(x):
        top = max(0, min(62, int(62 - (x - 2) * 62 / 49.0)))
        return top - (top % 3)
    ashlar(c, 0, c.r(62), 51, c.r(0), seed, course=5, bmin=6, bmax=11, joints=0.8, foot=0.3)
    for x in range(52):
        st = step_top(x)
        for hh in range(st + 1, 66):
            c.clear(x, c.r(hh))
        c.set(x, c.r(st), "stonePale")
        if st >= 1:
            c.set(x, c.r(st - 1), "stoneLight")
        if st >= 2 and (x == 51 or step_top(x + 1) < st):
            c.set(x, c.r(st - 1), "stoneMid")
    for x in range(30, 45):
        for hh in range(0, 11):
            q = (x - 37) ** 2 / 49.0 + hh ** 2 / 100.0
            if q < 1:
                c.set(x, c.r(hh), "night1" if (x - 37) ** 2 / 30.0 + hh ** 2 / 72.0 < 1 else
                      ("stonePale" if x < 37 else "stoneMid"))
    outline(c, sides=("right", "top"))
    return c.im


def curtain_tower():
    """A wall tower rising over the curtain: square, lit left face, slits, a crown of merlons on machicolations."""
    c = C(44, 104)
    seed = 589
    ashlar(c, 2, c.r(90), 41, c.r(0), seed, course=6, bmin=7, bmax=13, joints=0.9, foot=0.3)
    for y in range(c.r(90), c.r(0) + 1):
        c.step(2, y, 1)
        c.step(3, y, 1 if (y // 6) % 2 else 0)
        c.step(41, y, -1)
        c.step(40, y, -1)
        c.step(39, y, -1 if (y // 6) % 2 else 0)
    for x in range(0, 44):
        for hh in range(0, 5):
            c.set(x, c.r(hh), "stoneMid" if hh < 4 else "stoneLight")
    string_course(c, 2, 41, c.r(64), lit_to=30)
    machicolations(c, 1, 42, c.r(93), period=5, depth=4)
    for x in range(0, 44):
        c.set(x, c.r(94), "stoneDark")
        c.set(x, c.r(95), "stone" if x < 38 else "stoneMid")
        c.set(x, c.r(96), "stoneLight" if x < 38 else "stone")
    merlons(c, 0, 43, c.r(103), mh=7, mw=7, gap=5, seed=seed)
    slit(c, 21, c.r(86), 9)
    slit(c, 21, c.r(46), 9)
    arch_window(c, 11, c.r(78), 3, 7, "round", mullion=False)
    outline(c)
    return c.im


def curtain_hoard():
    """Tier 2 and 3: a timber hoarding on the wall walk: brackets, a planked gallery with drop slots, a pent roof of
    teal slate."""
    c = C(64, 22)
    for x in range(64):
        for y in range(6, 18):
            c.set(x, y, ("woodLight", "wood", "wood", "woodDark")[x % 4])
        if x % 8 in (2, 3):
            for y in range(13, 17):
                c.set(x, y, "night1")
        c.set(x, 17, "woodDark")
        c.set(x, 6, "woodLight")
    for x in range(0, 64, 8):
        for y in range(18, 22):
            c.set(x + 1, y, "woodDark")
        c.set(x + 2, 18, "wood")
        c.set(x + 2, 19, "woodDark")
    for x in range(64):
        for y in range(0, 6):
            name = "roofLight" if y == 0 else "banner" if (x + y) % 3 else "roofDeep"
            c.set(x, y, "night1" if y == 5 else name)
    return c.im


def castle_banner():
    c = C(12, 30)
    banner(c, 1, 1, 10, 28)
    return c.im


# ------------------------------------------------------------------------------------------- the forebuilding
FW, FH = 120, 96
DOOR = (51, 68)          # the door leaves' columns; the hall door's middle is between cols 59 and 60 (world 1830)


def forebuilding_frame(open_):
    """The keep's forebuilding: a gabled porch of dressed stone between clasping buttresses, the hall door in a deep
    round portal of two orders, torches either side, a carved plaque of the house's lantern, the lord's chamber in the
    gable (its window's candle is a mask), a stepped coping and a lantern finial."""
    c = C(FW, FH)
    seed = 701
    x0, x1 = 10, 109
    eave = 54                                    # the gable's foot; its apex at h 86 over col 59.5
    apex = 86
    ashlar(c, x0, c.r(eave), x1, c.r(0), seed, course=5, bmin=7, bmax=13, joints=0.8, foot=0.3, light=0.06,
           dark=0.08, darken=lambda x, y: -1 if x > 94 and h01(seed, x // 8, y // 5) < 0.65 else 0)
    # the gable: a triangle of the same stone, its coping stepped and lit on the left slope
    for hh in range(eave, apex + 1):
        half = (apex - hh) * 50.0 / (apex - eave)
        for x in range(int(round(59.5 - half)), int(round(59.5 + half)) + 1):
            if not c.opaque(x, c.r(hh)):
                v = h01(seed, x // 9, hh // 5)
                c.set(x, c.r(hh), "stoneMid" if v > 0.88 or x > 92 else "stone")
                if hh % 5 == 0 and h01(seed, x, hh) < 0.7:
                    c.set(x, c.r(hh), "stoneMid")
    gable_coping(c, 59.5, eave, apex, 50, x0, x1)
    for x in range(x0 - 2, x1 + 3):              # the eaves' string course across
        c.set(x, c.r(eave), "stonePale" if x < 96 else "stoneLight")
        c.set(x, c.r(eave - 1), "stone" if x < 96 else "stoneMid")
        c.set(x, c.r(eave - 2), "stoneDark")
    for hh, xs, n in ((apex + 3, (59, 60), "stoneDark"), (apex + 4, (59, 60), "gold"),
                      (apex + 5, (58, 59, 60, 61), "gold"), (apex + 6, (59, 60), "fireGold"),
                      (apex + 7, (59,), "gold")):
        for x in xs:
            c.set(x, c.r(hh), n)
    for x in range(x0, x1 + 1):                  # the plinth
        for hh in range(0, 4):
            c.set(x, c.r(hh), "stoneMid" if hh < 3 else "stoneLight")
    string_course(c, x0, x1, c.r(42), lit_to=96)
    # clasping buttresses at both corners, stepping in at h 30
    for (bx, lit) in ((x0 - 2, True), (x1 - 5, False)):
        for x in range(bx, bx + 8):
            k = x - bx
            hmax = 50 if (k < 6 if lit else k >= 2) else 30
            for hh in range(0, hmax):
                if lit:
                    name = "stoneLight" if k < 2 else "stone" if k < 6 else "stoneMid"
                else:
                    name = "stone" if k < 2 else "stoneMid" if k < 6 else "stoneDark"
                if hh % 6 == 5:
                    name = S[max(0, S.index(name) - 1)]
                c.set(x, c.r(hh), name)
            c.set(x, c.r(hmax), "stonePale" if lit else "stoneLight")
        for hh in range(0, 50 if lit else 30):
            c.set(bx + (7 if lit else 7), c.r(hh), "ink" if not lit else "stoneDark")
        if lit:
            for hh in range(4, 50):
                c.step(bx + 8, c.r(hh), -1)
                c.step(bx + 9, c.r(hh), -1)
                if hh % 2:
                    c.step(bx + 10, c.r(hh), -1)
    # the portal: a round arch of dressed voussoirs (two orders: the outer lit ring, the inner one in shadow), the
    # door recessed in the dark
    def recess(x, hh):
        return "night1" if abs(x - 59.5) <= 8.6 else "stoneDark"
    arch_ring(c, 59.5, 22, 12.6, 16.0, vw=3.6, jamb_to=2, recess=lambda x, hh: None)
    arch_ring(c, 59.5, 22, 10.0, 12.6, vw=3.0, jamb_to=2, recess=recess)
    for hh in range(2, 34):                      # the inner order's soffit in shadow
        for x in range(46, 74):
            if c.is_(x, c.r(hh), "stonePale") and abs(x - 59.5) < 12.6 and math.hypot(x - 59.5, max(0, hh - 22)) < 12.6:
                c.set(x, c.r(hh), "stone")
    if not open_:
        door(c, DOOR[0], c.r(28), DOOR[1], c.r(1), kind="round")
        for x in range(DOOR[0] + 1, DOOR[1]):    # the gap under the door: the layout's mask lights it at night
            c.set(x, c.r(1), "night1")
    else:
        for y in range(c.r(26), c.r(1) + 1):     # the leaves swung in against the recess's sides
            c.set(DOOR[0], y, "woodDark")
            c.set(DOOR[0] + 1, y, "wood")
            c.set(DOOR[1] - 1, y, "wood")
            c.set(DOOR[1], y, "woodDark")
        for y in range(c.r(22), c.r(1) + 1):     # a pillar inside, dark against the glow
            c.set(55, y, "stoneDark")
            c.set(56, y, "stoneDark")
        for y in range(c.r(24), c.r(13)):        # a banner hanging inside
            for x in (63, 64, 65):
                c.set(x, y, "crimsonDeep")
    for x in range(40, 80):                      # two steps before the portal
        c.set(x, c.r(0), "stoneMid")
        c.set(x, c.r(1), "stonePale" if x < 74 else "stoneLight")
    for x in range(42, 78):
        if not (DOOR[0] <= x <= DOOR[1]):
            c.set(x, c.r(2), "stoneLight")
    torch_bracket(c, 36, c.r(25))                # flames: emitters at cols 36 and 81, dy 26
    torch_bracket(c, 81, c.r(25))
    for x in range(53, 67):                      # a carved plaque: the lantern of the house
        for hh in range(45, 53):
            edge = x in (53, 66) or hh in (45, 52)
            if edge:
                c.set(x, c.r(hh), "stonePale" if (x == 53 or hh == 52) else "stoneMid")
            else:
                c.set(x, c.r(hh), "roofDeep" if x < 65 else "night1")
    for dx, dh, n in ((0, 2, "gold"), (-1, 1, "gold"), (0, 1, "fireGold"), (1, 1, "gold"), (-1, 0, "gold"),
                      (0, 0, "fireGold"), (1, 0, "gold"), (0, -1, "gold"), (0, 3, "gold")):
        c.set(59 + dx, c.r(48 + dh), n)
    # the lord's chamber in the gable: a round-arched window (its candle is a mask), two small ones beside it
    arch_window(c, 57, c.r(73), 5, 10, "round")
    arch_window(c, 30, c.r(36), 3, 7, "round", mullion=False)
    arch_window(c, 87, c.r(36), 3, 7, "round", mullion=False)
    outline(c)
    return c.im


def forebuilding():
    out = PA.Image(FW * 2, FH)
    WA.blit(out, forebuilding_frame(False), 0, 0)
    WA.blit(out, forebuilding_frame(True), FW, 0)
    return out


def hall_door_glow():
    """The hall's warm light through the open door (an emitter at forebuilding col 50, dy 1): warm white low and in the
    middle, deepening to gold, orange and ember toward the arch and the sides; the pillar and the banner inside stay
    dark."""
    c = C(20, 30)
    for y in range(30):
        hh = 29 - y
        for x in range(20):
            dx = abs(x - 9.5)
            if dx * dx + max(0, hh - 19) ** 2 > 9.0 ** 2:
                continue
            v = hh / 32.0 + dx / 13.0
            c.set(x, y, "fireWhite" if v < 0.32 else "fireGold" if v < 0.66 else "fireOrange" if v < 0.95 else
                  "ember")
    for hh in range(0, 22):                       # the pillar (forebuilding cols 55-56)
        c.clear(5, c.r(hh))
        c.clear(6, c.r(hh))
    for hh in range(13, 25):                      # the banner (cols 63-65)
        for x in (13, 14, 15):
            c.clear(x, c.r(hh))
    return c.im


def hall_door_wedge():
    """The door's wedge of warm light on the cobbles (an emitter just under the ground line before the door): a
    trapezoid from the door's width to about three times it, its strength falling away from the door in
    ordered-dither steps of alpha."""
    c = C(60, 12)
    bayer = ((0, 8, 2, 10), (12, 4, 14, 6), (3, 11, 1, 9), (15, 7, 13, 5))
    for y in range(12):
        half = 9 + y * 1.7
        for x in range(60):
            dx = abs(x - 29.5)
            if dx > half:
                continue
            a = (1 - y / 12.5) * (1 - (dx / half) ** 2 * 0.75)
            if a * 16 <= bayer[y % 4][x % 4]:
                continue
            c.set(x, y, "fireGold" if a > 0.55 else "fireOrange" if a > 0.3 else "ember")
    return c.im


# ------------------------------------------------------------------------------------------------ the chapel
CW, CH = 110, 132
LANCETS = (42, 55, 68)    # the three lancets' left columns (5 wide, dy 54 to 77)


def chapel_frame(bell):
    c = C(CW, CH)
    seed = 811
    tx0, tx1 = 30, 85
    # the sacristy on the right: low rubble, a lean of teal slate against the tower
    rubble(c, 86, c.r(40), 107, c.r(0), seed + 3)
    for x in range(86, 109):
        hh = 53 - (x - 86) * 12 // 22
        for h2 in range(41, hh + 1):
            c.set(x, c.r(h2), "banner" if (h2 + x // 3) % 3 else "roofDeep")
        c.set(x, c.r(hh), "roofLight")
        c.set(x, c.r(40), "night1")
    arch_window(c, 95, c.r(31), 3, 7, "point")
    # the tower
    ashlar(c, tx0, c.r(112), tx1, c.r(0), seed, course=5, bmin=6, bmax=12, joints=0.9, foot=0.3,
           darken=lambda x, y: -1 if x > 74 and h01(seed, x // 6, y // 5) < 0.55 else 0)
    for x in range(tx0 - 1, tx1 + 2):
        for hh in range(0, 5):
            c.set(x, c.r(hh), "stoneMid" if hh < 4 else "stoneLight")
    for (bx, lit) in ((tx0 - 3, True), (tx1 - 3, False)):   # clasping buttresses, stepping in twice
        for x in range(bx, bx + 7):
            k = x - bx
            hmax = 96 if 2 <= k <= 4 else 46
            for hh in range(0, hmax):
                if lit:
                    name = "stoneLight" if k < 2 else "stone" if k < 5 else "stoneMid"
                else:
                    name = "stone" if k < 2 else "stoneMid" if k < 5 else "stoneDark"
                if hh % 5 == 4:
                    name = S[max(0, S.index(name) - 1)]
                c.set(x, c.r(hh), name)
            c.set(x, c.r(hmax), "stonePale" if lit else "stoneLight")
    string_course(c, tx0 - 1, tx1 + 1, c.r(50), lit_to=75)
    string_course(c, tx0 - 1, tx1 + 1, c.r(90), lit_to=75)
    for x in LANCETS:                             # the three lancets, lit from inside (the layout's masks)
        arch_window(c, x, c.r(77), 5, 24, "point")
        for hh in (61, 69):                       # the saddle bars stay dark in a lit window
            for xx in range(x, x + 5):
                if c.is_(xx, c.r(hh), "night1"):
                    c.set(xx, c.r(hh), "stoneDark")
    for x in range(LANCETS[0] - 3, LANCETS[-1] + 9):  # a hood over the three
        c.set(x, c.r(81), "stonePale" if x < 74 else "stoneLight")
        c.set(x, c.r(80), "stoneMid")
    # the belfry: a round-arched opening with the bell (or empty: the bell melted for arrows)
    for hh in range(96, 113):
        for x in range(46, 70):
            dx = x - 57.5
            inner = (hh <= 104 and abs(dx) <= 8) or (hh > 104 and dx * dx + (hh - 104) ** 2 <= 8.4 ** 2)
            outer = (hh <= 104 and abs(dx) <= 10) or (hh > 104 and dx * dx + (hh - 104) ** 2 <= 10.4 ** 2)
            if inner:
                c.set(x, c.r(hh), "night1")
            elif outer:
                c.set(x, c.r(hh), "stonePale" if dx < 0 else "stoneLight")
    for x in range(46, 70):
        c.set(x, c.r(95), "stonePale" if x < 62 else "stoneLight")
        c.set(x, c.r(94), "stoneDark")
    for hh in range(106, 110):                    # the bell's beam
        c.set(57, c.r(hh), "woodDark")
        c.set(58, c.r(hh), "woodDark")
    if bell:
        for hh, (a, b) in zip(range(97, 106), ((54, 61), (54, 61), (55, 60), (55, 60), (55, 60), (56, 59),
                                                (56, 59), (57, 58), (57, 58))):
            for x in range(a, b + 1):
                c.set(x, c.r(hh), "gold" if x < (a + b + 1) // 2 else "cloth2")
        c.set(55, c.r(100), "fireGold")
        c.set(57, c.r(96), "stoneDark")
    else:
        c.set(57, c.r(105), "soilLight")
        c.set(57, c.r(104), "soilLight")
    # the cap: a low pyramid of teal slate on a corbelled eave, the Flame's gold finial
    for x in range(tx0 - 3, tx1 + 4):
        c.set(x, c.r(113), "stoneLight" if x < 76 else "stone")
        c.set(x, c.r(112), "stoneDark")
    top, bot = c.r(128), c.r(114)
    TA.roof(c.im, top, bot, lambda y: int(round(57 - (57 - (tx0 - 4)) * (y - top) / float(bot - top))),
            lambda y: int(round(58 + ((tx1 + 4) - 58) * (y - top) / float(bot - top))), SLATE, "slate", seed,
            moss=False, mid=0.5, shade=12)
    for hh, xs, n in ((129, (57, 58), "gold"), (130, (56, 57, 58, 59), "gold"), (131, (57, 58), "fireGold"),
                      (132, (57,), "fireGold")):
        for x in xs:
            c.set(x, c.r(hh), n)
    # the door: pointed, oak, under a hood; its step
    door(c, 50, c.r(24), 64, c.r(1), kind="point")
    for x in range(48, 67):
        c.set(x, c.r(26), "stonePale" if x < 62 else "stoneLight")
        c.set(x, c.r(25), "stoneMid")
    for x in range(46, 69):
        c.set(x, c.r(0), "stoneLight")
    outline(c)
    return c.im


def chapel_tower():
    out = PA.Image(CW * 2, CH)
    WA.blit(out, chapel_frame(True), 0, 0)
    WA.blit(out, chapel_frame(False), CW, 0)
    return out


# ---------------------------------------------------------------------------------------------- the bakehouse
def bakehouse():
    c = C(100, 62)
    seed = 911
    rubble(c, 4, c.r(40), 95, c.r(0), seed)
    for x in range(4, 96):
        for hh in range(0, 3):
            c.set(x, c.r(hh), "stoneMid" if hh < 2 else "stoneLight")
        if x > 88:
            for hh in range(3, 41):
                c.step(x, c.r(hh), -1)
    top, bot = c.r(56), c.r(41)                    # the hipped slate roof, its eave's shadow on the wall
    TA.roof(c.im, top, bot, lambda y: int(round(18 - 16 * (y - top) / float(bot - top))),
            lambda y: int(round(82 + 16 * (y - top) / float(bot - top))), SLATE, "slate", seed, moss=True,
            mid=0.55, shade=9)
    for x in range(4, 96):
        c.step(x, c.r(40), -1)
        c.step(x, c.r(39), -1)
    TA.chimney(c.im, 72, 78, c.r(61), c.r(47), seed)
    # the oven: a domed bulge of stone on the left with an iron hatch (the glow: an emitter at cols 15-20, dy 7-12)
    for x in range(6, 31):
        for hh in range(0, 24):
            dx = (x - 18) / 12.5
            if dx * dx + (hh / 23.5) ** 2 <= 1:
                t = (x - 6) / 25.0
                name = "stoneLight" if t < 0.3 else "stone" if t < 0.75 else "stoneMid"
                if int(hh + abs(x - 18) * 0.6) % 5 == 0:
                    name = "stone" if t < 0.3 else "stoneMid" if t < 0.75 else "stoneDark"
                c.set(x, c.r(hh), name)
    for x in range(14, 22):
        for hh in range(6, 14):
            edge = x in (14, 21) or hh in (6, 13)
            c.set(x, c.r(hh), "stoneDark" if edge else "night1")
    TA.door(c.im, 44, c.r(20), 52, c.r(1))
    TA.window(c.im, 63, c.r(27), 5, 5, shutters=TA.TEAL, box=True)
    for (x, hh) in ((33, 0), (37, 0), (35, 5)):   # flour sacks
        for xx in range(x, x + 4):
            for h2 in range(hh, hh + 5):
                c.set(xx, c.r(h2), "parchment" if xx < x + 2 else "plaster")
        c.set(x + 1, c.r(hh + 5), "plasterDim")
        c.set(x + 3, c.r(hh), "plasterDim")
    TA.woodpile(c.im, 82, c.r(1), 4, 4)
    for hh in range(1, 22):                        # a baker's peel leaning on the wall
        c.set(58 + hh // 7, c.r(hh), "woodLight")
    outline(c, sides=("right", "top", "left"))
    return c.im


def bake_hatch_glow():
    c = C(6, 6)
    for y in range(6):
        for x in range(6):
            v = abs(x - 2.5) / 3.0 + (5 - y) / 7.0
            c.set(x, y, "fireWhite" if v < 0.45 else "fireGold" if v < 0.8 else "fireOrange")
    return c.im


# ------------------------------------------------------------------------------------------------ the postern
PW, PH = 176, 112
PASS = (90, 110)         # the passage's columns (world 2320 to 2340 with the sprite at 2230)


def postern(tier):
    c = C(PW, PH)
    seed = 1001 + tier
    curtain_body(c, 0, 89, seed, top=58)           # the wall stretch west of the passage, a step lower
    ashlar(c, 86, c.r(70), 114, c.r(0), seed + 2, course=5, bmin=6, bmax=11, joints=0.9, foot=0.3)
    for x in range(86, 115):
        for hh in range(0, 4):
            c.set(x, c.r(hh), "stoneMid" if hh < 3 else "stoneLight")
        c.set(x, c.r(70), "stoneDark")
        c.set(x, c.r(71), "stone")
        c.set(x, c.r(72), "stoneLight")
    merlons(c, 86, 114, c.r(79), mh=7, mw=6, gap=4, seed=seed)
    cx = (PASS[0] + PASS[1]) / 2.0                 # the passage: a round arch, the open leaf, the valley beyond
    for hh in range(0, 36):
        for x in range(PASS[0] - 5, PASS[1] + 6):
            dx = x - cx + 0.5
            r2 = dx * dx + max(0, hh - 20) ** 2
            if r2 > 14.5 ** 2:
                continue
            if r2 > 10.6 ** 2:
                vous = int((hh + x) / 2) % 2
                c.set(x, c.r(hh), ("stonePale" if dx < 0 else "stoneLight") if vous else
                      ("stoneLight" if dx < 0 else "stoneMid"))
            else:
                c.set(x, c.r(hh), "night1" if abs(dx) < 8.4 else "stoneDark")
    for y in range(c.r(26), c.r(0) + 1):
        c.set(PASS[0], y, "woodLight")
        c.set(PASS[0] + 1, y, "wood")
        c.set(PASS[0] + 2, y, "woodDark")
    for x in range(PASS[0] + 3, PASS[1]):
        c.set(x, c.r(0), "stoneMid")
    lantern_bracket(c, 81, c.r(34))                # lanterns either side (glass cols 81-83 and 116-118, dy 29-32)
    lantern_bracket(c, 116, c.r(34))
    t0, t1 = 114, 170                              # the squat tower east of the passage
    ttop = 80
    ashlar(c, t0, c.r(ttop), t1, c.r(0), seed + 5, course=5, bmin=6, bmax=12, joints=0.9, foot=0.3,
           darken=lambda x, y: -1 if x > 158 and h01(seed, x // 6, y // 5) < 0.6 else 0)
    for y in range(c.r(ttop), c.r(0) + 1):
        c.step(t0, y, 1)
        c.step(t1, y, -1)
        c.step(t1 - 1, y, -1)
    for x in range(t0 - 3, t1 + 4):                # the battered foot
        for hh in range(0, 9):
            inset = hh // 3
            if t0 - 3 + inset <= x <= t1 + 3 - inset:
                c.set(x, c.r(hh), "stoneLight" if hh % 3 == 2 else "stoneMid")
    string_course(c, t0, t1, c.r(46), lit_to=158)
    slit(c, 141, c.r(72), 7)
    slit(c, 126, c.r(37), 6)
    arch_window(c, 150, c.r(33), 5, 8, "round", sill=False)   # a window with a flower box, toward the town
    for i, x in enumerate(range(149, 156)):
        c.set(x, c.r(25), ("leaf", "dusk", "meadow", "dawnRose", "leaf", "meadow", "dusk")[i % 7])
        c.set(x, c.r(24), "woodLight" if x < 155 else "wood")
        c.set(x, c.r(23), "woodDark")
    if tier == 1:
        for x in range(t0 - 1, t1 + 2):
            c.set(x, c.r(ttop + 1), "stone")
            c.set(x, c.r(ttop + 2), "stoneLight")
        merlons(c, t0 - 1, t1 + 1, c.r(ttop + 8), mh=6, mw=6, gap=4, seed=seed + 7)
    elif tier == 2:
        for x in range(t0 - 3, t1 + 4):            # a pyramid roof of teal slate on a corbelled eave
            c.set(x, c.r(ttop + 1), "stoneLight" if x < 160 else "stone")
            c.set(x, c.r(ttop), "stoneDark")
        top, bot = c.r(ttop + 22), c.r(ttop + 2)
        mid = (t0 + t1) / 2.0
        TA.roof(c.im, top, bot, lambda y: int(round(mid - 2 - (mid - 2 - (t0 - 4)) * (y - top) / float(bot - top))),
                lambda y: int(round(mid + 2 + ((t1 + 4) - mid - 2) * (y - top) / float(bot - top))), SLATE, "slate",
                seed, moss=False, mid=0.5, shade=12)
        c.set(int(mid), c.r(ttop + 23), "gold")
        c.set(int(mid), c.r(ttop + 24), "gold")
        lantern_bracket(c, 99, c.r(46))           # the great lantern over the passage (glass cols 99-101, dy 41-44)
    else:
        machicolations(c, t0 - 2, t1 + 2, c.r(ttop + 3), period=5, depth=4)
        for x in range(t0 - 3, t1 + 4):
            c.set(x, c.r(ttop + 4), "stoneDark")
            for hh in range(ttop + 5, ttop + 9):
                c.set(x, c.r(hh), "stone" if x < 160 else "stoneMid")
            c.set(x, c.r(ttop + 9), "stoneLight")
        merlons(c, t0 - 3, t1 + 3, c.r(ttop + 16), mh=7, mw=6, gap=4, seed=seed + 7)
        pole(c, 152, c.r(110), c.r(ttop + 10))
        flag(c, 152, c.r(109), 13, h=6)
        lantern_bracket(c, 99, c.r(46))
    outline(c)
    return c.im


# ------------------------------------------------------------------------------------- the bailey's lean-tos
# World-2 (REVIEW-look-2.md 2.1: "the barracks, the smithy and the builders' lodge, as lean-tos against the curtain wall
# in the castle's granite and slate; no half-timbering here: that belongs to the town"). Same sizes, the window glass
# where `EntityFrames.courtyard` puts its masks, the forge's fire where its emitter burns.
def pent_roof(c, x0, x1, h0, h1, seed):
    """A lean-to's pent roof of teal slate seen from the front: a band from the eave (h0) up to the wall it leans on
    (h1), its courses, its left part lit, the eave's dark edge and its shadow on the wall under it."""
    top, bot = c.r(h1), c.r(h0)
    TA.roof(c.im, top, bot, lambda y: x0, lambda y: x1, SLATE, "slate", seed, moss=True, mid=0.6, shade=6)
    for x in range(x0 + 1, x1):
        c.step(x, bot + 1, -1)
        c.step(x, bot + 2, -1)


def win_box(c, dx, dy, w, h):
    """A small square window whose glass is the mask box (dx, dy up from the bottom row, w, h): a pale lintel and sill,
    a lit left jamb, a shaded right one."""
    for hh in range(dy, dy + h):
        for x in range(dx, dx + w):
            c.set(x, c.r(hh), "night1")
        c.set(dx - 1, c.r(hh), "stoneLight")
        c.set(dx + w, c.r(hh), "stoneMid")
    for x in range(dx - 1, dx + w + 1):
        c.set(x, c.r(dy + h), "stonePale" if x < dx + w else "stoneLight")
        c.set(x, c.r(dy - 1), "stonePale" if x < dx + w else "stoneLight")
        c.set(x, c.r(dy - 2), "stoneDark")


def shield(c, x, hh, emblem="gold"):
    """A round shield hung on the wall: teal with a lit rim on the left, a gold boss."""
    for dy in range(-2, 3):
        for dx in range(-2, 3):
            if dx * dx + dy * dy <= 5:
                name = "banner" if dx < 0 or dy > 0 else "roofDeep"
                if dx * dx + dy * dy >= 4:
                    name = "roofLight" if dx < 0 and dy >= 0 else "night1"
                c.set(x + dx, c.r(hh + dy), name)
    c.set(x, c.r(hh), emblem)


def barracks():
    c = C(64, 48)
    seed = 1201
    ashlar(c, 2, c.r(33), 61, c.r(0), seed, course=4, bmin=5, bmax=10, joints=0.8, foot=0.3, quoins=True)
    for x in range(2, 62):
        for hh in range(0, 3):
            c.set(x, c.r(hh), "stoneMid" if hh < 2 else "stoneLight")
    pent_roof(c, 0, 63, 34, 46, seed)
    for (dx, dy, w, h) in ((8, 26, 4, 4), (21, 26, 4, 4), (39, 26, 4, 4), (52, 26, 4, 4)):
        win_box(c, dx, dy, w, h)
    for dx in (23, 41):                           # loopholes either side of the door (1 x 2 glass)
        for hh in (14, 15):
            c.set(dx, c.r(hh), "night1")
        c.set(dx - 1, c.r(14), "stoneLight")
        c.set(dx - 1, c.r(15), "stoneLight")
        c.set(dx + 1, c.r(14), "stoneMid")
        c.set(dx + 1, c.r(15), "stoneMid")
        c.set(dx, c.r(13), "stonePale")
        c.set(dx, c.r(16), "stoneMid")
    arch_ring(c, 31.5, 11, 4.2, 6.2, vw=2.6, jamb_to=1, recess=lambda x, hh: None)
    door(c, 28, c.r(14), 35, c.r(1), kind="round")
    banner(c, 30, c.r(23), 4, 6, emblem=False)
    shield(c, 9, 12)
    shield(c, 54, 12)
    for x in (14, 16, 18):                        # a rack of spears
        for hh in range(1, 22):
            c.set(x, c.r(hh), "woodLight" if x == 14 else "wood")
        c.set(x, c.r(22), "stonePale")
        c.set(x, c.r(23), "stoneLight")
    for x in range(13, 20):
        c.set(x, c.r(6), "woodDark")
        c.set(x, c.r(15), "woodDark")
    TA.barrel(c.im, 45, c.r(1), w=5, h=7)
    outline(c)
    return c.im


def forge_bay(c, x0, x1, h1, seed, hearth=(10, 24), hood=True):
    """An open forge bay under the lean-to: the dim back wall, a stone hearth (its fire is the layout's emitter on
    its top), a hood narrowing into the chimney, bellows, tools on the wall, timber posts at the front corners."""
    for hh in range(0, h1 + 1):
        for x in range(x0, x1 + 1):
            v = h01(seed, x // 6, hh // 4, 61)
            c.set(x, c.r(hh), "stoneMid" if v < 0.18 else "stoneDark" if v < 0.85 else "night1")
            if hh % 4 == 3 and h01(seed, x, hh) < 0.6:
                c.set(x, c.r(hh), "night1")
    a, b = hearth
    ashlar(c, a, c.r(11), b, c.r(0), seed + 3, course=3, bmin=3, bmax=6, joints=0.9, light=0.15, dark=0.2)
    for hh in range(0, 12):
        c.set(a, c.r(hh), "stoneLight")
        c.set(b, c.r(hh), "stoneDark")
    for x in range(a - 1, b + 2):
        c.set(x, c.r(12), "stonePale" if x < b else "stoneLight")
    if hood:
        for i, hh in enumerate(range(20, h1 + 1)):
            inset = min(i, (b - a) // 2 - 3)
            for x in range(a - 1 + inset, b + 2 - inset):
                c.set(x, c.r(hh), "stone" if x < (a + b) // 2 else "stoneMid")
            c.set(a - 1 + inset, c.r(hh), "stoneLight")
    for x in range(b + 2, b + 7):                 # the bellows
        for hh in range(5, 10 - (x - b - 2) // 2):
            c.set(x, c.r(hh), "soil" if hh > 6 else "woodDark")
    for (tx, th) in ((b + 8, 14), (b + 10, 15)):  # tongs and a hammer on the back wall
        for hh in range(th, th + 7):
            c.set(tx, c.r(hh), "stone")
        c.set(tx - 1, c.r(th), "stone")
    for px in (x0, x1):
        for hh in range(0, h1 + 1):
            c.set(px, c.r(hh), "wood" if px == x0 else "woodDark")
            c.set(px + 1, c.r(hh), "woodDark")


def anvil(c, x, hh0=0):
    for hh in range(hh0, hh0 + 4):
        for xx in range(x + 2, x + 6):
            c.set(xx, c.r(hh), "stoneDark")
    for xx in range(x, x + 9):
        c.set(xx, c.r(hh0 + 4), "stoneMid")
        c.set(xx, c.r(hh0 + 5), "stoneMid")
        c.set(xx, c.r(hh0 + 6), "stoneLight" if xx > x else "stoneMid")
    c.set(x - 1, c.r(hh0 + 6), "stoneMid")


def smithy(master=False):
    h = 56 if master else 48
    c = C(60, h)
    seed = 1301 + (7 if master else 0)
    bay_top = 30
    wall_top = 46 if master else 30
    ashlar(c, 36, c.r(wall_top), 57, c.r(0), seed, course=4, bmin=5, bmax=9, joints=0.8, foot=0.3, quoins=True)
    if master:
        ashlar(c, 3, c.r(46), 36, c.r(bay_top + 1), seed + 1, course=4, bmin=5, bmax=9, joints=0.8)
        win_box(c, 20, 41, 4, 4)
        win_box(c, 47, 16, 4, 4)
        for x in range(3, 37):                    # the loft's beam over the bay
            c.set(x, c.r(bay_top + 1), "woodDark")
            c.set(x, c.r(bay_top + 2), "wood")
    forge_bay(c, 3, 35, bay_top, seed, hearth=(10, 30) if master else (11, 23))
    for x in range(36, 58):
        for hh in range(0, 3):
            c.set(x, c.r(hh), "stoneMid" if hh < 2 else "stoneLight")
    roof_h0 = wall_top + 1
    pent_roof(c, 0, 59, roof_h0, h - 2 if master else roof_h0 + 11, seed)
    chx = 7 if master else 15
    TA.chimney(c.im, chx, chx + 5, 0 if master else 1, c.r(roof_h0 + 3), seed)
    anvil(c, 39)
    TA.barrel(c.im, 50, c.r(1), w=5, h=6)
    if not master:
        door(c, 51, c.r(20), 56, c.r(9), kind="round")
    outline(c)
    return c.im


def lodge(big=False):
    w, h = (64, 52) if big else (56, 44)
    c = C(w, h)
    seed = 1401 + (5 if big else 0)
    top = 38 if big else 30
    ashlar(c, 3, c.r(top), w - 4, c.r(0), seed, course=4, bmin=5, bmax=10, joints=0.8, foot=0.3, quoins=True)
    for x in range(3, w - 3):
        for hh in range(0, 3):
            c.set(x, c.r(hh), "stoneMid" if hh < 2 else "stoneLight")
    pent_roof(c, 0, w - 1, top + 1, h - 2, seed)
    if big:
        for (dx, dy, ww, hh) in ((9, 26, 3, 4), (22, 26, 3, 4), (35, 26, 3, 4), (47, 26, 3, 4)):
            win_box(c, dx, dy, ww, hh)
        arch_ring(c, 30.5, 14, 6.2, 8.4, vw=3.0, jamb_to=1, recess=lambda x, hh: None)
        door(c, 25, c.r(20), 36, c.r(1), kind="round")
        for x in range(w - 12, w):                # the hoist beam with its rope and block
            c.set(x, c.r(top + 2), "woodDark")
            c.set(x, c.r(top + 3), "wood")
        for hh in range(18, top + 2):
            c.set(w - 3, c.r(hh), "soilLight")
        for hh in range(14, 18):
            for x in range(w - 5, w - 1):
                c.set(x, c.r(hh), "stoneLight" if x < w - 3 else "stoneMid")
    else:
        win_box(c, 11, 11, 4, 4)
        door(c, 24, c.r(20), 35, c.r(1), kind="round")
        for x in range(23, 37):
            c.set(x, c.r(21), "stonePale" if x < 33 else "stoneLight")
    for hh in range(1, 7):                        # stacked timber and a ladder: the builders' yard
        for x in range(w - 16, w - 4):
            c.set(x, c.r(hh), "woodLight" if hh % 2 else ("wood" if x % 5 else "woodDark"))
    for hh in range(1, top - 2):
        c.set(w - 10 + hh // 9, c.r(hh), "woodLight")
        c.set(w - 7 + hh // 9, c.r(hh), "wood")
        if hh % 3 == 0:
            c.set(w - 9 + hh // 9, c.r(hh), "woodLight")
            c.set(w - 8 + hh // 9, c.r(hh), "wood")
    outline(c)
    return c.im


# ------------------------------------------------------------------------------------------ the gate's arch
def gate_arch_fg():
    """The gate passage's dark arch in the foreground while the lord passes through either gate: two jambs and the
    vault's soffit, near black, the inner edge a step lighter, the joints barely there."""
    c = C(64, 180)
    for y in range(180):
        hh = 179 - y
        for x in range(64):
            jamb = x < 9 or x > 54
            vr = (x - 31.5) ** 2 + max(0, hh - 128) ** 2
            if not (jamb or hh > 151 or (hh > 128 and vr > 23.5 ** 2)):
                continue
            edge = (x in (8, 55) and hh <= 128) or (hh > 128 and 23.5 ** 2 < vr <= 25 ** 2)
            name = "stoneDark" if edge else "night0"
            if not edge and hh % 7 == 0 and (hh // 7 + x // 9) % 2 == 0:
                name = "nightDeep"
            c.set(x, y, name)
    return c.im


BUILDERS = {
    "keepT1": lambda: keep(1), "keepT2": lambda: keep(2), "keepT3": lambda: keep(3),
    "keepT2Build": lambda: keep(2, True), "keepT3Build": lambda: keep(3, True),
    "curtainA": lambda: curtain("curtainA"), "curtainB": lambda: curtain("curtainB"),
    "curtainC": lambda: curtain("curtainC"), "curtainStair": curtain_stair, "curtainTower": curtain_tower,
    "curtainHoard": curtain_hoard, "castleBanner": castle_banner,
    "forebuilding": forebuilding, "hallDoorGlow": hall_door_glow, "hallDoorWedge": hall_door_wedge,
    "chapelTower": chapel_tower, "bakehouse": bakehouse, "bakeHatchGlow": bake_hatch_glow,
    "posternT1": lambda: postern(1), "posternT2": lambda: postern(2), "posternT3": lambda: postern(3),
    "gateArchFg": gate_arch_fg,
    "barracks": barracks, "smithy": lambda: smithy(False), "masterSmithy": lambda: smithy(True),
    "lodge": lambda: lodge(False), "bigLodge": lambda: lodge(True),
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
