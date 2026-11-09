"""Lanternhold: the paint functions of the castle's rooms and the court's props (M3 art lane, step 3; ART-court.md).

Each function returns a roomart.Canvas of its sprite's contract size (SPRITES.md "M3"). Coordinates are sprite pixels
with y down (0 = the top row); the anchors are recorded in the engine's convention (dx from the left edge, dy up from
the bottom row, as ART-buildings.md "Anchors for the engine") with canvas.anchor(...), which `roomart.py anchors <id>`
prints for ART-court.md.

The fronts and the interiors share one silhouette pixel for pixel (the front fades out when the king steps inside):
hallFront is painted inside hallInterior's opaque pixels; chapelInterior and kitchenInterior inside chapel's and
kitchen's.
"""
from roomart import (Canvas, art, alpha_set, arch_set, ring, paint_set, ashlar, planks, beam, post, slate, plaster,
                     flagstones, floorboards, shift_ramp, stamps, rnd, irange, pick)

STONE = ["ink", "stoneDark", "stoneMid", "stone", "stoneLight", "stonePale"]


def glass_mask(c, name, x0, y0, x1, y1):
    """Records a window glass mask (inclusive top-down rect) in the engine's convention: (dx, dy, w, h), dy up from
    the bottom row to the rect's bottom row."""
    c.anchor("mask", name, x0, c.h - 1 - y1, x1 - x0 + 1, y1 - y0 + 1)


def light_at(c, name, kind, x, y, r):
    """Records a light at sprite pixel (x, y) (top-down): (dx, dy) from the bottom-left, kind and radius."""
    c.anchor("light", name, kind, x, c.h - 1 - y, r)


def fire_at(c, name, sprite, x, y_bottom, w):
    """Records an emissive flame sprite whose bottom-left pixel sits at (x, y_bottom) (top-down)."""
    c.anchor("fire", name, sprite, x, c.h - 1 - y_bottom, w)


def spot(c, name, x, facing):
    """Records where a court member stands (dx of the foot from the left edge) and which way he faces."""
    c.anchor("spot", name, x, facing)


# ---------------------------------------------------------------------------------------------- shared pieces

def head_rows(w, h, sharp, pointed=True):
    """How many rows of an arched opening's top are its head (before the span is the full width)."""
    from roomart import arch_rows
    n = 0
    for sp in arch_rows(w, h, pointed, sharp):
        if sp == (0, w - 1):
            break
        n += 1
    return n


def stone_surround(c, x, top, w, bottom, inset, sharp=0.62, pointed=True, tooth=2, joints=((2, -1), (4, -5), (2, -9))):
    """A dressed-stone surround round an arched opening; returns the opening's pixels and its springing row. The outer
    arch is w wide from `top` to `bottom`, the opening inset by `inset` px. The head is a ring of voussoirs split by
    radial joints (`joints`: integer directions of the right half, mirrored for the left), stonePale on the lit
    left, stoneLight on the right, the keystone pale; the jambs are quoins of 5 and 4 rows, every other one long
    (toothing `tooth` px into the wall), each outlined in ink; the opening's rim is ink."""
    H = bottom - top + 1
    outer = arch_set(x, top, w, H, pointed, sharp)
    wo = w - 2 * inset
    opening = arch_set(x + inset, top + inset, wo, H - inset, pointed, sharp)
    spring = top + inset + head_rows(wo, H - inset, sharp, pointed)
    # the jambs' quoins (the long ones tooth into the wall)
    y = bottom
    k = 0
    while y >= spring:
        bh = 5 if k % 2 == 0 else 4
        y0 = max(spring, y - bh + 1)
        long = k % 2 == 0
        for side in (0, 1):
            if side == 0:
                bx0, bx1 = x - (tooth if long else 0), x + inset - 1
            else:
                bx0, bx1 = x + w - inset, x + w - 1 + (tooth if long else 0)
            c.rect(bx0, y0, bx1, y, "ink")
            for yy in range(y0 + 1, y):
                for xx in range(bx0 + 1, bx1):
                    col = "stonePale" if side == 0 else "stoneLight"
                    if yy == y - 1:
                        col = "stoneLight" if side == 0 else "stone"
                    c.put(xx, yy, col)
        y = y0 - 1
        k += 1
    # the head: a ring of voussoirs
    head = [(px, py) for (px, py) in outer if py < spring and (px, py) not in opening]
    xl = x + (w - 1) // 2
    xr = x + w // 2
    for (px, py) in head:
        c.put(px, py, "stonePale" if px <= xl else "stoneLight")
    hs = set(head)
    for (dx, dy) in joints:
        for (sx, sdx) in ((xr, dx), (xl, -dx)):
            x1, y1 = sx + sdx * 12, spring + dy * 12
            # Bresenham from the springing centre outward; only the ring's pixels take the joint
            ax, ay = sx, spring
            ddx, ddy = abs(x1 - ax), -abs(y1 - ay)
            stx, sty = (1 if ax < x1 else -1), (1 if ay < y1 else -1)
            err = ddx + ddy
            while True:
                if (ax, ay) in hs:
                    c.put(ax, ay, "stoneMid")
                if ax == x1 and ay == y1:
                    break
                e2 = 2 * err
                if e2 >= ddy:
                    err += ddy
                    ax += stx
                if e2 <= ddx:
                    err += ddx
                    ay += sty
    for (px, py) in head:
        if any(q not in outer for q in ((px + 1, py), (px - 1, py), (px, py - 1))):
            c.put(px, py, "ink")
    for (px, py) in ring(opening):
        if (px, py) in outer:
            c.put(px, py, "ink")
    c.hline(x - tooth, x + inset - 1, spring, "ink")
    c.hline(x + w - inset, x + w - 1 + tooth, spring, "ink")
    return opening, spring


def banner(c, x, top, w=12, length=26):
    """A hanging banner of the realm as on the castle front: deep teal cloth with two lit folds, a gold lantern
    emblem, a gold top hem, a pointed foot; hung from an iron rod with finials."""
    c.hline(x - 2, x + w + 1, top - 1, "ink")
    c.put(x - 3, top - 1, "stoneDark")
    c.put(x + w + 2, top - 1, "stoneDark")
    c.put(x - 2, top - 2, "ink")
    c.put(x + w + 1, top - 2, "ink")
    point = w // 2
    for j in range(length + point):
        y = top + j
        if j < length:
            x0, x1 = x, x + w - 1
        else:
            k = j - length + 1
            x0, x1 = x + k, x + w - 1 - k
            if x0 > x1:
                break
        for xx in range(x0, x1 + 1):
            i = xx - x
            col = "roofDeep"
            if i in (2, 3) or (i in (8, 9) and not (8 <= j <= 16)):
                col = "banner"
            if j == 0:
                col = "gold"
            elif j == 1:
                col = "woodLight" if i % 2 == 0 else "gold"
            c.put(xx, y, col)
        if j > 0:
            c.put(x0, y, "ink")
            c.put(x1, y, "ink")
    c.hline(x + 1, x + w - 2, top + length - 1, "banner")
    st = stamps("hall")["emblem"]
    c.stamp(st, x + (w - st.w) // 2, top + 9)


def lantern(c, x, y, name, flip=False, r=24):
    """An iron wall lantern on its wall plate (5x10, top-left at (x, y)); its 3x3 glass recorded as a mask."""
    st = stamps("hall")["wallLantern"]
    c.stamp(st, x, y, flip=flip)
    glass_mask(c, name, x + 1, y + 3, x + 3, y + 5)
    light_at(c, name, "lantern", x + 2, y + 4, r)


def ivy(c, x, y, w, h, seed=0, vines=7):
    """Ivy hanging from about (x, y) down and to the left over w x h px: seeded vines (woodDark) that wander down,
    leaf clusters along them in three greens."""
    leaves = ("leaf", "leaf", "leafDark", "meadow", "leaf")
    for v in range(vines):
        vx = x - irange(0, w // 2, seed, v, 1)
        vy = y + irange(0, 4, seed, v, 2)
        length = irange(h // 3, h, seed, v, 3)
        for s in range(length):
            if not (x - w < vx <= x):
                break
            c.put(vx, vy, "woodDark")
            if rnd(seed, v, s, 4) < 0.7:
                for (dx, dy) in ((pick((-1, 1), seed, v, s, 5), 0), (0, -1), (pick((-1, 1), seed, v, s, 6), -1)):
                    if rnd(seed, v, s, dx, dy, 7) < 0.75:
                        c.put(vx + dx, vy + dy, pick(leaves, seed, v, s, dx, dy, 8))
                if rnd(seed, v, s, 9) < 0.35:
                    c.put(vx + pick((-2, 2), seed, v, s, 10), vy - 1, "meadow")
                    c.put(vx + pick((-2, 2), seed, v, s, 10), vy, "leafDark")
            vy += 1
            r = rnd(seed, v, s, 11)
            if r < 0.30:
                vx -= 1
            elif r < 0.40:
                vx += 1


def log_pile(c, x, bottom, layout):
    """Firewood stacked end-on: `layout` is a list of (stamp name, dx, dy-up) per round, relative to (x, bottom);
    each round's box is filled woodDark first (the gaps between the rounds), then the round stamped."""
    st = stamps("hall")
    for (name, dx, up) in layout:
        r = st[name]
        c.rect(x + dx, bottom - up - r.h + 1, x + dx + r.w - 1, bottom - up, "woodDark")
    for (name, dx, up) in layout:
        r = st[name]
        c.stamp(r, x + dx, bottom - up - r.h + 1)


# --------------------------------------------------------------------------------------------------- hallFront

def hall_window(c, x, top, bottom, name):
    """A tall two-light window, 15 px wide (x .. x+14): a dressed stone surround with a pointed head, two lights of
    dark glass with lead cames (stoneDark, they stay dark when the glass glows) and a stone mullion, a stone sill."""
    w = 15
    opening, spring = stone_surround(c, x, top, w, bottom, inset=3, sharp=0.68, tooth=1, joints=((4, -3), (1, -3)))
    gtop = min(py for (px, py) in opening)
    for (px, py) in opening:
        col = "night1" if py < (gtop + bottom) // 2 + 2 else "night0"
        if (py - spring) % 7 == 5 and py > spring:
            col = "stoneDark"
        c.put(px, py, col)
    mx = x + w // 2
    for py in range(spring - 1, bottom + 1):
        c.put(mx, py, "stoneLight")
    c.put(mx, spring - 2, "stone")
    # the sill
    c.hline(x - 1, x + w, bottom + 1, "stonePale")
    c.hline(x - 1, x + w, bottom + 2, "stoneMid")
    c.hline(x - 1, x + w, bottom + 3, "ink")
    c.put(x - 2, bottom + 1, "ink")
    c.put(x + w + 1, bottom + 1, "ink")
    c.put(x - 2, bottom + 2, "ink")
    c.put(x + w + 1, bottom + 2, "ink")
    glass_mask(c, name, x + 3, gtop, x + w - 4, bottom)
    light_at(c, name, "window", mx, (gtop + bottom) // 2, 8)


def hall_door(c, x, top, bottom):
    """The main door (x .. x+25): an arch of voussoirs on quoined jambs, two oak leaves with iron straps, studs and
    ring handles, the dark threshold gap (night0: warm light under the door at night) and a hood mould."""
    w = 26
    opening, spring = stone_surround(c, x, top, w, bottom, inset=4, sharp=0.6, tooth=2)
    lx0, lx1 = x + 4, x + w - 5
    tmp = Canvas(c.w, c.h, c.pal)
    planks(tmp, lx0, top, lx1, bottom, seed=31, width=(3, 3), colours=("wood", "wood", "woodLight"), knots=0.0)
    for (px, py) in opening:
        c.put(px, py, tmp.get(px, py))
    mid = x + w // 2
    for (px, py) in opening:
        if px == mid - 1:
            c.put(px, py, "woodDark")
        elif px == mid:
            c.put(px, py, "ink")
    for sy in (spring + 2, spring + 11, bottom - 5):
        for px in range(lx0, lx1 + 1):
            if (px, sy) in opening and px not in (mid - 1, mid):
                c.put(px, sy, "stoneDark")
                c.put(px, sy + 1, "ink")
        for px in range(lx0 + 1, lx1, 3):
            if (px, sy) in opening and px not in (mid - 1, mid):
                c.put(px, sy, "stoneLight")
    hy = spring + 6
    for hx, dirx in ((mid - 3, -1), (mid + 2, 1)):
        c.put(hx, hy - 1, "stoneDark")
        c.put(hx, hy, "gold")
        c.put(hx + dirx, hy + 1, "gold")
        c.put(hx, hy + 2, "gold")
        c.put(hx - dirx, hy + 1, "strawLight")
    c.hline(lx0, lx1, bottom, "night0")
    glass_mask(c, "door gap", lx0, bottom, lx1, bottom)
    # the hood mould over the head: a lit band one px outside the voussoirs, with stops
    outer = arch_set(x, top, w, bottom - top + 1, True, 0.6)
    hood = {p for p in ring(outer) if p[1] <= spring - 1 and p not in outer}
    for (px, py) in hood:
        c.put(px, py, "stonePale" if px < x + w / 2 else "stoneLight")
    for (px, py) in ring(hood):
        if (px, py) not in outer and (px, py) not in hood and py < spring:
            above = py < min(q[1] for q in hood if q[0] == px) if any(q[0] == px for q in hood) else True
            if above:
                c.put(px, py, "ink")
    for sx in (x - 2, x + w + 1):
        c.rect(sx, spring - 1, sx, spring, "stoneMid")
    return mid


def buttress(c, x, w, top, bottom, step):
    """A buttress (x .. x+w-1) from `top` to `bottom`: its face in courses, a lit left edge, a darker right one,
    widening by a px each side at `step` under a sloped weathering cap."""
    for (x0, x1, y0, y1) in ((x, x + w - 1, top, step - 1), (x - 1, x + w, step, bottom)):
        c.rect(x0, y0, x1, y1, "ink")
        for yy in range(y0, y1 + 1):
            for xx in range(x0 + 1, x1):
                col = "stone"
                if xx == x0 + 1:
                    col = "stoneLight"
                elif xx == x1 - 1:
                    col = "stoneMid"
                if (yy - y0) % 6 == 5:
                    col = "stoneMid"
                    if (yy // 6) % 2 == 0 and xx == x0 + (x1 - x0) // 2:
                        col = "ink"
                c.put(xx, yy, col)
    c.hline(x - 1, x + w, step, "ink")
    c.hline(x, x + w - 1, step + 1, "stoneLight")
    c.hline(x, x + w - 1, step + 2, "stone")
    c.put(x - 1, step + 1, "ink")
    c.put(x + w, step + 1, "ink")


def hall_front():
    interior = art("hallInterior")
    W, H = interior.w, interior.h
    c = Canvas(W, H, interior.pal)
    c.clip = alpha_set(interior)
    # the end walls: the interior's own masonry (stacks, caps and pilasters stay put when the front fades)
    c.blit(interior, 0, 0, box=(0, 0, 20, H - 1))
    c.blit(interior, 239, 0, box=(239, 0, W - 1, H - 1))
    X0, X1 = 21, 238
    # the wall: dressed stone courses, lighter than the interior's back wall (outside, in daylight)
    ashlar(c, X0, 32, X1, 82, seed=11, course=(6, 5), width=(10, 17), faces=("stone",) * 9 + ("stoneMid",),
           deep_share=0.18, pits=0.02)
    # the roof: teal slate to the eave, the ridge tiles and iron cresting on top (the interior's beam ends)
    slate(c, X0, 17, X1, 26, seed=5, row=3, width=(4, 7))
    c.hline(X0, X1, 26, "roofDeep")
    for x in range(X0, X1 + 1):
        tops = [y for y in range(H) if (x, y) in c.clip]
        top = tops[0]
        if top <= 16:
            for y in range(top, 17):
                c.put(x, y, "stoneDark" if y < 15 else "roofDeep")
            c.put(x, top, "ink")
    for x in range(X0, X1 + 1):
        if (x, 15) in c.clip and (x, 14) in c.clip:
            c.put(x, 15, "banner" if x % 4 else "roofDeep")
        if (x, 13) in c.clip:
            c.put(x, 13, "ink")
            c.put(x, 14, "stoneMid" if (x - 1, 13) not in c.clip else "stoneDark")
    c.hline(X0, X1, 16, "night1")
    # the cornice and the corbel table under the eave
    c.hline(X0, X1, 27, "ink")
    c.hline(X0, X1, 28, "stonePale")
    c.hline(X0, X1, 29, "stoneLight")
    c.hline(X0, X1, 30, "stoneMid")
    c.hline(X0, X1, 31, "ink")
    for x in range(X0 + 4, X1 - 3, 8):
        c.rect(x, 32, x + 2, 33, "stoneLight")
        c.put(x + 2, 33, "stone")
        c.hline(x, x + 2, 34, "ink")
        c.vline(x + 3, 32, 34, "ink")
        c.vline(x - 1, 32, 34, "ink")
    # the plinth
    c.hline(X0, X1, 82, "ink")
    for x in range(X0, X1 + 1):
        c.put(x, 83, "stonePale")
        for y in range(84, 88):
            c.put(x, y, "stone" if y < 87 else "stoneMid")
        if (x - X0) % 15 == 7:
            for y in range(84, 88):
                c.put(x, y, "ink")
        c.put(x, 88, "stoneMid")
    c.hline(X0, X1, 89, "night0")
    c.vline(X0, 17, 88, "ink")
    c.vline(X1, 17, 88, "ink")

    # --- buttresses between the windows, the banners hung on them
    for bx in (113, 159):
        buttress(c, bx, 8, 35, 82, 70)
    banner(c, 111, 38, w=12, length=24)
    banner(c, 157, 38, w=12, length=24)

    # --- the door, its lanterns, the realm's crest, the notice board
    mid = hall_door(c, 34, 42, 81)
    lantern(c, 25, 50, "lantern left")
    lantern(c, 64, 50, "lantern right")
    crest = stamps("hall")["crest"]
    c.stamp(crest, 47 - crest.w // 2, 33)
    c.stamp(stamps("hall")["noticeBoard"], 70, 56)
    bay = stamps("hall")["potBay"]
    c.stamp(bay, 23, 82 - bay.h)
    c.stamp(bay, 62, 82 - bay.h, flip=True)
    # pigeons on the cornice
    c.stamp(stamps("hall")["pigeon"], 100, 24)
    c.stamp(stamps("hall")["pigeonB"], 106, 24)
    c.stamp(stamps("hall")["pigeon"], 205, 24, flip=True)

    # --- three tall windows
    for k, wx in enumerate((89, 132, 178)):
        hall_window(c, wx, 37, 71, "window %d" % (k + 1))

    # --- the right bay: the hearth's firewood under a lean-to, ivy from the corner
    roof_y = 63
    for px in range(198, 234):
        c.put(px, roof_y, "ink")
        c.put(px, roof_y + 1, "woodLight" if (px * 7) % 5 else "wood")
        c.put(px, roof_y + 2, "wood" if (px // 3) % 2 else "woodDark")
        c.put(px, roof_y + 3, "woodDark")
        c.put(px, roof_y + 4, "ink")
    c.put(197, roof_y + 1, "ink")
    c.put(197, roof_y + 2, "ink")
    c.put(234, roof_y + 1, "ink")
    c.put(234, roof_y + 2, "ink")
    for xx in (200, 230):
        post(c, xx, roof_y + 5, 81, w=3, seed=xx)
    log_pile(c, 203, 81, [
        ("log5", 0, 0), ("log5b", 5, 0), ("log5", 10, 0), ("log5c", 15, 0), ("log5b", 20, 0), ("log4", 25, 0),
        ("log5c", 2, 4), ("log5", 7, 4), ("log5b", 12, 4), ("log5", 17, 4), ("log4b", 22, 5),
        ("log5b", 5, 8), ("log4", 10, 9), ("log5c", 14, 8), ("log4b", 19, 9)])
    blk = stamps("hall")["chopBlock"]
    c.stamp(blk, 189, 82 - blk.h)
    ivy(c, X1 - 1, 33, 22, 36, seed=9)
    for x in range(X0 + 1, X1):
        if rnd(3, x) < 0.07:
            c.put(x, 81, "leaf")
            if rnd(4, x) < 0.5:
                c.put(x, 80, "leafDark")
    return c


SPRITES = {
    "hallFront": hall_front,
}
