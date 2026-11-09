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


def actor_frame(sid, frame, fw):
    """Frame `frame` (fw px wide) of a committed actor strip as a Canvas."""
    strip = art(sid)
    c = Canvas(fw, strip.h, strip.pal)
    for y in range(strip.h):
        for x in range(fw):
            c.px[y][x] = strip.get(frame * fw + x, y)
    return c


def lightness(pal, name):
    from pixelart import lab
    return lab(pal.color(name))[0]


def to_stone(c, ramp=("stoneDark", "stoneMid", "stone", "stoneLight", "stonePale"), cuts=(26, 40, 55, 70),
             keep=(), outline=None):
    """Recolours every pixel by its lightness into a stone ramp (a statue, a relief); `keep` names stay, an
    `outline` colour replaces ink."""
    for y in range(c.h):
        for x in range(c.w):
            v = c.px[y][x]
            if v is None or v in keep:
                continue
            if v == "ink":
                c.px[y][x] = outline or "ink"
                continue
            L = lightness(c.pal, v)
            i = sum(1 for t in cuts if L >= t)
            c.px[y][x] = ramp[i]
    return c


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

# ---------------------------------------------------------------------------------------------- chapelInterior

CHAPEL_LANCETS = ((21, 36), (57, 72), (92, 106), (127, 139))   # the front's lancets (x of their frames), rows 52-77


def stained_lancet(c, x0, x1, top, bottom, motif, seed):
    """A lancet seen from inside: a splayed stone frame, stained glass in lead cames (stoneDark): a border of teal
    and gold quarries round a coloured field with a motif stamp in the middle."""
    w = x1 - x0 + 1
    outer = arch_set(x0, top, w, bottom - top + 1, True, 0.9)
    glass = arch_set(x0 + 2, top + 2, w - 4, bottom - top - 2, True, 0.9)
    paint_set(c, outer, "ink")
    for (px, py) in outer:
        if (px, py) in glass:
            continue
        edge = any(q not in outer for q in ((px + 1, py), (px - 1, py), (px, py - 1), (px, py + 1)))
        if not edge:
            c.put(px, py, "stonePale" if px < x0 + w // 2 else "stoneLight")
    gx0 = min(p[0] for p in glass)
    gx1 = max(p[0] for p in glass)
    gy0 = min(p[1] for p in glass)
    for (px, py) in glass:
        border = px in (gx0, gx1) or py == gy0 or (px, py - 1) not in glass or py == bottom - 2
        if border:
            col = "gold" if (px + py) % 3 == 0 else "banner"
        else:
            col = pick(("roofLight", "banner", "roofLight", "daySky"), seed, (px - gx0) // 3, (py - gy0) // 4)
            if (px - gx0) % 3 == 0 or (py - gy0) % 4 == 0:
                col = "stoneDark"
        c.put(px, py, col)
    m = stamps("chapel")[motif]
    mx = gx0 + (gx1 - gx0 + 1 - m.w) // 2
    my = gy0 + (bottom - 2 - gy0 + 1 - m.h) // 2 + 1
    c.stamp(m, mx, my)


def saint_figure():
    """The lamplighter saint for the chapel's niche, a painted relief: the king's command frame (the lantern raised on
    its hooked pole) with a hood for the crown, the robe of the Flame's order in cream and gold (Mother Hesper's
    colours), the pole's wood kept, the lantern gilded."""
    f = actor_frame("king", 9, 16)
    for y in range(0, 6):
        for x in range(0, 11):
            if f.px[y][x] in ("gold", "strawLight", "straw", "banner", "ink"):
                f.px[y][x] = None
    robe = {"banner": "plaster", "roofDeep": "plasterDim", "roofLight": "parchment", "tile": "parchment",
            "tileLight": "parchment", "soil": "plasterDim", "soilDark": "plasterDim", "woodDark": "plasterDim"}
    for y in range(6, f.h):
        for x in range(0, 12):
            v = f.px[y][x]
            if v in robe:
                f.px[y][x] = robe[v]
    for y in range(0, 8):
        for x in range(10, 16):
            v = f.px[y][x]
            if v in ("stone", "stoneDark"):
                f.px[y][x] = "gold"
            elif v in ("parchment", "strawLight"):
                f.px[y][x] = "strawLight"
    f.stamp(stamps("chapel")["saintHood"], 2, 0)
    return f


def chapel_interior():
    front = art("chapel")
    W, H = front.w, front.h
    c = Canvas(W, H, front.pal)
    c.clip = alpha_set(front)
    st = stamps("chapel")
    full = sorted(c.clip)
    for (x, y) in full:
        c.put(x, y, "roofDeep")

    # --- the back wall: lime plaster over a wainscot, a painted frieze under the wall plate
    plaster(c, 0, 47, W - 1, 84, seed=21)
    for x in range(W):
        for y in (49, 50, 51):
            c.put(x, y, "tile")
        c.put(x, 48, "gold")
        c.put(x, 52, "gold")
    for x in range(2, W, 6):
        c.stamp(st["frieze"], x, 49)
    planks(c, 0, 76, W - 1, 86, seed=22, width=(4, 5), colours=("wood", "wood", "woodLight"), knots=0.0)
    c.hline(0, W - 1, 75, "woodLight")
    c.hline(0, W - 1, 74, "woodDark")
    # --- the floor: flagstones in perspective, a red runner up the nave to the chancel step
    flagstones(c, 0, 87, W - 1, 95, seed=23, grow=(2, 3))
    for x in range(0, 104):
        c.put(x, 90, "tileLight")
        c.put(x, 91, "tile")
        c.put(x, 92, "tile" if x % 7 else "gold")
    c.hline(0, W - 1, 86, "woodDark")

    # --- the roof: a starry vault in the realm's teal, ribs from the wall shafts, the wall plate
    for (x, y) in full:
        if 23 <= y <= 46 and not (x < 41 and y < 38):
            c.put(x, y, "roofDeep")
    for (x, y) in full:
        if 26 <= y <= 42 and rnd(24, x, y) < 0.022 and not (x < 41 and y < 38):
            c.put(x, y, "gold")
            if rnd(25, x, y) < 0.35:
                for (dx, dy) in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    if (x + dx, y + dy) in c.clip and 26 <= y + dy <= 42:
                        c.put(x + dx, y + dy, "strawLight")
    for sx in (43, 76):
        for y in range(27, 47):
            if (sx, y) in c.clip:
                c.put(sx - 1, y, "woodLight")
                c.put(sx, y, "wood")
                c.put(sx + 1, y, "woodDark")
    # the chancel's gable: a king-post truss over the stars (principal rafters inside both slopes, the king post,
    # two struts)
    apex_x = 133
    c.line(116, 43, 132, 25, "woodDark")
    c.line(117, 43, 133, 25, "woodLight")
    c.line(118, 43, 134, 25, "wood")
    c.line(150, 43, 135, 25, "woodDark")
    c.line(149, 43, 134, 25, "wood")
    for y in range(25, 44):
        c.put(apex_x - 1, y, "woodLight")
        c.put(apex_x, y, "wood")
        c.put(apex_x + 1, y, "woodDark")
    c.line(apex_x - 2, 41, 124, 34, "wood")
    c.line(apex_x + 2, 41, 142, 34, "woodDark")
    beam(c, 0, W - 1, 44, h=4, seed=26)
    for x in range(3, W, 8):
        c.put(x, 46, "woodLight")
        c.put(x + 1, 46, "woodDark")
    c.hline(0, W - 1, 47, "ink")

    # --- the turret: the bell in its belfry, the spire's rafters
    for (x, y) in full:
        if y < 38 and x < 43:
            c.put(x, y, "woodDark")
    for bx in (15, 21, 27, 33, 40):
        c.line(27, 1, bx, 14, "wood")
    for y in range(15, 38):
        for x in range(15, 41):
            if (x, y) in c.clip:
                c.put(x, y, "stoneMid" if (x // 5 + y // 4) % 2 else "stone")
                if y % 4 == 3:
                    c.put(x, y, "stoneDark")
    for (lx0, lx1, ly0, ly1) in ((19, 26, 18, 27), (32, 36, 21, 26)):
        c.rect(lx0, ly0, lx1, ly1, "night1")
        for y in range(ly0 + 1, ly1, 2):
            c.hline(lx0, lx1, y, "woodDark")
    beam(c, 13, 41, 14, h=3, seed=27)
    c.stamp(st["bell"], 24, 17)
    beam(c, 12, 41, 34, h=4, seed=28)
    for y in range(27, 78):
        c.put(28, y, "strawLight" if y % 3 else "straw")
    for y in range(66, 74):
        c.put(28, y, "tile" if (y // 2) % 2 else "plaster")
        c.put(29, y, "tileLight" if (y // 2) % 2 else "parchment")

    # --- the side walls in section
    for (x0, x1) in ((0, 13), (148, W - 1)):
        ashlar(c, x0, 36, x1, 94, seed=29 + x0, course=(5, 4), width=(5, 9))

    # --- shafts between the windows, rising into the ribs (the third is the saint's niche)
    for sx in (43, 76):
        for y in range(47, 87):
            c.put(sx - 2, y, "ink")
            c.put(sx - 1, y, "stonePale")
            c.put(sx, y, "stoneLight")
            c.put(sx + 1, y, "stone")
            c.put(sx + 2, y, "ink")
        c.stamp(st["capital"], sx - 3, 46)
        c.stamp(st["shaftBase"], sx - 3, 82)
        # a candle sconce on the shaft
        sc = st["sconce"]
        c.stamp(sc, sx - 2, 58)
        fire_at(c, "sconce candle", "candleFlame", sx, 57, 2)
        light_at(c, "sconce candle", "candle", sx, 56, 14)

    # --- the four lancets in stained glass
    for k, (x0, x1) in enumerate(CHAPEL_LANCETS):
        stained_lancet(c, x0, x1, 52, 77, ("flame", "lantern", "star", "flame")[k], seed=30 + k)

    # --- the saint's niche between the third and the fourth lancet, the saint in relief
    nx0, nx1, ntop, nbot = 107, 126, 49, 80
    niche = arch_set(nx0, ntop, nx1 - nx0 + 1, nbot - ntop + 1, True, 0.75)
    paint_set(c, niche, "ink")
    inner = arch_set(nx0 + 2, ntop + 2, nx1 - nx0 - 3, nbot - ntop - 1, True, 0.75)
    for (px, py) in niche:
        if (px, py) not in inner and not any(q not in niche for q in ((px + 1, py), (px - 1, py), (px, py - 1))):
            c.put(px, py, "stonePale" if px < (nx0 + nx1) // 2 else "stoneLight")
    for (px, py) in inner:
        c.put(px, py, "roofDeep")
        if rnd(41, px, py) < 0.05:
            c.put(px, py, "gold")
    c.stamp(st["rays"], 115, 51)
    c.blit(saint_figure(), 109, 51)

    # --- the chancel step, the altar with the Flame's bowl, candles, the sanctuary lamp
    c.rect(100, 90, 150, 94, "stone")
    c.hline(100, 150, 90, "stonePale")
    c.hline(100, 150, 91, "stoneLight")
    c.hline(100, 150, 94, "stoneMid")
    c.vline(99, 90, 94, "ink")
    for x in range(104, 150, 9):
        c.vline(x, 92, 94, "stoneMid")
    alt = st["altar"]
    ax = 116 - alt.w // 2
    c.stamp(alt, ax, 90 - alt.h)
    bowl = st["bowl"]
    bx = 116 - bowl.w // 2
    by = 90 - alt.h - bowl.h + 1
    c.stamp(bowl, bx, by)
    fire_at(c, "the Flame", "brazierFlame", 112, by, 8)
    light_at(c, "the Flame", "brazier", 116, by - 3, 54)
    stick = st["candlestick"]
    for cx in (ax + 2, ax + alt.w - 5):
        c.stamp(stick, cx, 90 - alt.h - stick.h + 1)
        fire_at(c, "altar candle", "candleFlame", cx + 1 - 0, 90 - alt.h - stick.h, 2)
        light_at(c, "altar candle", "candle", cx + 1, 90 - alt.h - stick.h - 1, 12)
    stand = st["candleStand"]
    for cx in (97, 131):
        c.stamp(stand, cx, 94 - stand.h + 1)
        fire_at(c, "candle stand", "candleFlame", cx + 2, 94 - stand.h, 2)
        light_at(c, "candle stand", "candle", cx + 2, 94 - stand.h - 1, 12)
    vase = st["vase"]
    c.stamp(vase, ax + alt.w - 1, 90 - vase.h)
    lamp = st["sanctuaryLamp"]
    c.stamp(lamp, 141, 48)
    glass_mask(c, "sanctuary lamp", 142, 48 + 7, 143, 48 + 8)
    light_at(c, "sanctuary lamp", "lantern", 142, 48 + 8, 22)

    # --- the pews, facing the altar
    pew = st["pew"]
    for k, x in enumerate((15, 29, 47, 61, 79)):
        c.stamp(pew, x, 91 - pew.h)
    spot(c, "hesper altar", 98, 1)
    spot(c, "hesper pews", 52, -1)

    # --- the outline: the silhouette's edge in ink, as the front's
    edge = [(x, y) for (x, y) in full if y < H - 1 and any((x + dx, y + dy) not in c.clip
            for (dx, dy) in ((1, 0), (-1, 0), (0, -1)))]
    for (x, y) in edge:
        c.put(x, y, "ink")
    for x in range(W):
        if (x, H - 1) in c.clip:
            c.put(x, H - 1, "night0")
    for (k, (x0, x1)) in enumerate(CHAPEL_LANCETS):
        pass
    return c

# --------------------------------------------------------------------------------------------- kitchenInterior

def kitchen_window(c, x0, x1, top, bottom, seed):
    """A window seen from inside: a deep plaster reveal, a wooden frame with a cross bar, panes of daylight, a sill."""
    c.rect(x0, top, x1, bottom, "ink")
    c.rect(x0 + 1, top + 1, x1 - 1, bottom - 1, "plasterDim")
    c.rect(x0 + 2, top + 2, x1 - 2, bottom - 1, "woodDark")
    gx0, gx1, gy0, gy1 = x0 + 3, x1 - 3, top + 3, bottom - 2
    for y in range(gy0, gy1 + 1):
        for x in range(gx0, gx1 + 1):
            c.put(x, y, "foam" if (x - gx0) + (gy1 - y) < 3 else "daySky")
    mx = (gx0 + gx1) // 2
    my = (gy0 + gy1) // 2
    c.vline(mx, gy0, gy1, "wood")
    c.hline(gx0, gx1, my, "wood")
    c.hline(x0 - 1, x1 + 1, bottom, "woodLight")
    c.hline(x0 - 1, x1 + 1, bottom + 1, "wood")
    c.hline(x0 - 1, x1 + 1, bottom + 2, "ink")


def kitchen_interior():
    front = art("kitchen")
    W, H = front.w, front.h
    c = Canvas(W, H, front.pal)
    c.clip = alpha_set(front)
    st = stamps("kitchen")
    full = sorted(c.clip)
    for (x, y) in full:
        c.put(x, y, "woodDark")
    # the chimney stack is outside: the same as the front's
    c.blit(front, 70, 0, box=(70, 0, 104, 8))

    # --- the roof open to the rafters: boards, rafters, the ridge beam, a purlin, the hip rafters, the tie beam
    for (x, y) in full:
        if 9 <= y <= 35 and not (70 <= x <= 104 and y <= 8):
            c.put(x, y, "woodDark" if rnd(51, x, y) > 0.06 else "soilDark")
    for x in range(10, 112, 6):
        for y in range(12, 34):
            if (x, y) in c.clip:
                c.put(x, y, "wood")
                c.put(x + 1, y, "soilDark")
    beam(c, 20, 100, 12, h=3, seed=52)
    beam(c, 6, 114, 22, h=3, seed=53)
    for y in range(9, 36):
        span = [x for x in range(W) if (x, y) in c.clip]
        if span:
            a, b = min(span), max(span)
            c.put(a + 1, y, "woodLight")
            c.put(b - 1, y, "wood")
    beam(c, 0, W - 1, 33, h=4, seed=54, top="woodLight", body="wood", bottom="woodDark")
    # the flue rising from the hearth into the stack, its stones smoked dark
    c.poly([(96, 36), (108, 36), (97, 8), (80, 8)], "stoneMid")
    for (x, y) in full:
        if c.get(x, y) == "stoneMid" and 8 <= y <= 36:
            if y % 4 == 0 or (x + (y // 4) * 3) % 7 == 0:
                c.put(x, y, "stoneDark")
            elif rnd(55, x, y) < 0.2:
                c.put(x, y, "stone")
    c.line(80, 8, 96, 36, "ink")
    c.line(97, 8, 108, 36, "ink")
    beam(c, 0, W - 1, 33, h=4, seed=54)

    # --- the upper wall: lime plaster between the timbers
    plaster(c, 0, 37, W - 1, 55, seed=56)
    for (x0, w) in ((5, 4), (57, 3), (111, 4)):
        post(c, x0, 37, 56, w=w, seed=x0)
    c.line(9, 38, 20, 55, "wood")
    c.line(10, 38, 21, 55, "woodDark")
    c.line(110, 38, 99, 55, "wood")
    beam(c, 0, W - 1, 55, h=3, seed=57)
    # the two windows (at the front's windows) with herb pots on their sills
    kitchen_window(c, 26, 40, 38, 49, seed=58)
    kitchen_window(c, 80, 93, 38, 49, seed=59)
    sp = st["sillPot"]
    c.stamp(sp, 35, 49 - sp.h + 1)
    c.stamp(sp, 82, 49 - sp.h + 1)
    # sausages smoking from the purlin by the flue
    for (name, x) in (("sausages", 74), ("sausages", 84)):
        c.stamp(st[name], x, 25)
    # herbs, garlic and a ham from the tie beam
    for (name, x) in (("herbs", 11), ("garlic", 17), ("herbsB", 21), ("ham", 45), ("herbs", 52), ("garlic", 64),
                      ("herbsB", 69)):
        c.stamp(st[name], x, 37)
    # the copper pots on their rail
    c.hline(43, 77, 41, "stoneDark")
    c.put(43, 40, "ink")
    c.put(77, 40, "ink")
    for (name, x) in (("potS", 45), ("pan", 52), ("potL", 56), ("potS", 64), ("potL", 69)):
        c.stamp(st[name], x, 41)
    # the shelf with plates, crocks and a jug
    c.hline(42, 78, 53, "woodLight")
    c.hline(42, 78, 54, "wood")
    for bx in (45, 75):
        c.put(bx, 55, "woodDark")
    for (name, x) in (("plate", 43), ("plate", 46), ("crock", 51), ("jug", 55), ("crock", 61), ("plate", 66),
                      ("plate", 69), ("crock", 74)):
        stp = st[name]
        c.stamp(stp, x, 52 - stp.h + 1)

    # --- the lower walls: whitewash too, greyer toward a stone plinth
    plaster(c, 0, 58, W - 1, 71, seed=60, speck=0.05)
    for x in range(W):
        for y in range(66, 72):
            if rnd(64, x, y) < (y - 64) * 0.07:
                c.put(x, y, "plasterDim")
    ashlar(c, 0, 72, W - 1, 75, seed=65, course=(4,), width=(6, 11), faces=("stone",) * 5 + ("stoneMid", "stoneLight"))
    c.hline(0, W - 1, 71, "stoneLight")
    # --- the floor
    flagstones(c, 0, 76, W - 1, 79, seed=61, grow=(1, 2))

    # --- the oven-hearth under the flue: stone jambs, an oak mantel beam with its shelf, a stone hood narrowing into
    # the flue, a sooty fireback, the crane with the cauldron over the fire, the logs on their irons
    hx0, hx1 = 94, 112
    hood = [(97 - (y - 38) // 1 // 4 * 0, y) for y in range(38, 52)]
    for y in range(38, 52):
        inset = (52 - y) // 4
        a, b = hx0 + 1 + inset, hx1 - 1 - inset
        c.put(a - 1, y, "ink")
        c.put(b + 1, y, "ink")
        for x in range(a, b + 1):
            c.put(x, y, "stone")
        c.put(a, y, "stoneLight")
        c.put(b, y, "stoneMid")
        if (y - 38) % 4 == 3:
            c.hline(a, b, y, "stoneMid")
        elif (y - 38) % 4 == 0:
            for x in range(a + 1, b, 6):
                c.put(x + ((y // 4) % 2) * 3, y, "stoneMid")
    # the mantel beam and its shelf with a crock and a candle stub
    c.rect(hx0 - 1, 51, hx1 + 1, 54, "ink")
    beam(c, hx0, hx1, 52, h=2, seed=63)
    c.hline(hx0, hx1, 54, "woodDark")
    stp = st["crock"]
    c.stamp(stp, 97, 50 - stp.h + 1)
    c.stamp(st["jug"], 106, 50 - st["jug"].h + 1)
    # the jambs (2 px each: the opening between them takes the 16 px hearth fire)
    for (x0, x1) in ((hx0, hx0 + 1), (hx1 - 1, hx1)):
        c.rect(x0 - (1 if x0 == hx0 else 0), 55, x1 + (1 if x1 == hx1 else 0), 77, "ink")
        for y in range(55, 77):
            for x in range(x0, x1 + 1):
                col = "stoneLight" if x == x0 else "stoneMid"
                if (y - 55) % 5 == 4:
                    col = "stoneMid" if x == x0 else "stoneDark"
                c.put(x, y, col)
    # the fireback
    fb0, fb1 = hx0 + 2, hx1 - 2
    for y in range(55, 78):
        for x in range(fb0, fb1 + 1):
            if y >= 68:
                col = "tile" if ((x + (y // 2) * 2) % 4) else "woodDark"
                if y % 2 == 1:
                    col = "woodDark"
            else:
                col = "soilDark" if rnd(62, x, y) < 0.55 else "night1"
            c.put(x, y, col)
    # the crane and the cauldron
    c.vline(fb0, 56, 66, "stoneDark")
    c.hline(fb0, fb0 + 7, 57, "stoneDark")
    c.put(fb0 + 1, 58, "stoneDark")
    c.vline(fb0 + 7, 58, 61, "ink")
    cauldron = st["cauldron"]
    c.stamp(cauldron, fb0 + 3, 62)
    # the logs on their irons
    c.rect(fb0, 76, fb1, 77, "stoneDark")
    c.hline(fb0 + 1, fb1 - 1, 75, "woodDark")
    c.hline(fb0 + 2, fb1 - 2, 74, "wood")
    c.put(fb0 + 3, 74, "woodLight")
    c.put(fb1 - 3, 74, "woodLight")
    fire_at(c, "the hearth fire", "hearthFire", 95, 74, 16)
    light_at(c, "the hearth fire", "hearth", 103, 70, 62)
    # the peel leaning on the hearth, a basket of loaves at its foot
    c.stamp(st["peel"], 91, 77 - st["peel"].h + 1)

    # --- the table with the day's bread
    tx0, tx1, ty = 20, 56, 66
    c.rect(tx0, ty - 1, tx1, ty + 1, "ink")
    c.hline(tx0 + 1, tx1 - 1, ty, "woodLight")
    c.hline(tx0 + 1, tx1 - 1, ty + 1, "wood")
    c.hline(tx0, tx1, ty + 2, "ink")
    for lx in (tx0 + 2, tx1 - 4):
        post(c, lx, ty + 3, 78, w=3, seed=lx)
        c.hline(lx - 1, lx + 3, 79, "ink")
    c.hline(tx0 + 5, tx1 - 5, 74, "woodDark")
    for (name, x) in (("loaf", 22), ("loaf", 27), ("cheese", 34), ("board", 40), ("apples", 49)):
        stp = st[name]
        c.stamp(stp, x, ty - stp.h)
    tc = st["tableCandle"]
    c.stamp(tc, 46, ty - tc.h)
    fire_at(c, "table candle", "candleFlame", 46, ty - tc.h - 1, 2)
    light_at(c, "table candle", "candle", 47, ty - tc.h - 2, 14)

    # --- barrels and sacks, the broom, the cat on its stool by the fire, the mouse hole
    b = st["barrel"]
    c.stamp(b, 8, 79 - b.h + 1)
    c.stamp(st["sack"], 58, 79 - st["sack"].h + 1)
    c.stamp(st["sack"], 65, 79 - st["sack"].h + 1, flip=True)
    c.stamp(st["broom"], 73, 79 - st["broom"].h + 1)
    stool = st["stool"]
    c.stamp(stool, 82, 79 - stool.h + 1)
    cat = st["cat"]
    c.stamp(cat, 80, 79 - stool.h - cat.h + 1)
    c.stamp(st["mouseHole"], 78, 74)
    rack = st["rack"]
    c.stamp(rack, 76, 58)
    spot(c, "tamsin table", 38, 1)
    spot(c, "tamsin hearth", 88, 1)

    # --- the outline
    edge = [(x, y) for (x, y) in full if y < H - 1 and y > 8 and any((x + dx, y + dy) not in c.clip
            for (dx, dy) in ((1, 0), (-1, 0), (0, -1)))]
    for (x, y) in edge:
        c.put(x, y, "ink")
    c.hline(0, W - 1, H - 1, "ink")
    return c


# --------------------------------------------------------------------------------------------------------- props

def stamp_sprite(name, w, h):
    """A prop that is one stamp of props.txt, bottom-aligned on a canvas of its contract size."""
    c = Canvas(w, h)
    st = stamps("props")[name]
    c.stamp(st, 0, h - st.h)
    return c


def bench():
    return stamp_sprite("bench", 32, 10)


def tax_lectern():
    return stamp_sprite("taxLectern", 12, 20)


def speaker_mark():
    return stamp_sprite("speakerMark", 14, 7)


STATUE_STONE = {
    "banner": "stoneLight", "roofDeep": "stone", "roofLight": "stonePale",        # the cloak, lit from the left
    "tile": "stone", "tileLight": "stoneLight", "gold": "stoneLight",             # the tunic, belt and clasp
    "strawLight": "stonePale", "straw": "stoneLight",                             # the crown
    "dawnRose": "stonePale", "foam": "stonePale",                                 # face and beard
    "wood": "stone", "woodLight": "stoneLight", "woodDark": "stoneMid",           # the pole
    "soil": "stoneMid", "soilDark": "stoneDark",                                  # legs and boots
    "stone": "stoneDark", "stoneDark": "stoneDark", "stoneLight": "stoneLight",   # lantern frame, beard shade
}


def statue():
    """A stone statue of the lamplighter king with his lantern raised: the king's command frame carved in pale
    stone (a colour-for-colour map, so cloak, tunic, beard and pole stay apart), the lantern's glass gilded, on a
    plinth with a bronze plaque; moss at its foot."""
    c = Canvas(20, 40)
    f = actor_frame("king", 8, 16)
    for y in range(f.h):
        for x in range(f.w):
            v = f.px[y][x]
            if v is None or v == "ink":
                continue
            if v in ("parchment", "strawLight") and x >= 10 and y <= 10:
                f.px[y][x] = "gold"
            else:
                f.px[y][x] = STATUE_STONE.get(v, "stone")
    c.blit(f, 2, 0)
    pl = stamps("props")["plinth"]
    c.stamp(pl, 0, 40 - pl.h)
    for (x, y, col) in ((1, 39, "leaf"), (2, 39, "leafDark"), (17, 38, "leaf"), (18, 39, "meadow"), (3, 30, "leaf")):
        c.put(x, y, col)
    return c


def marek_cart():
    """Marek's cart: a striped awning in rose and cream on two poles over his wares (a barrel, a crate with a rolled
    rug, bolts of cloth, jugs and a lantern), a plank bed with his sign of a gold coin, two spoked wheels, the shafts
    resting on the ground."""
    c = Canvas(48, 30)
    # the wheels behind the bed
    for (wx, col) in ((11, "wood"), (34, "wood")):
        cx, cy, r = wx + 0.5, 24.5, 5.5
        c.ellipse(cx, cy, r, r, "ink")
        c.ellipse(cx, cy, r - 1, r - 1, "woodDark")
        c.ellipse(cx, cy, r - 2, r - 2, None)
        for y in range(19, 30):
            for x in range(wx - 5, wx + 7):
                d2 = (x + 0.5 - cx) ** 2 + (y + 0.5 - cy) ** 2
                if (r - 1.2) ** 2 < d2 <= (r - 0.1) ** 2:
                    c.put(x, y, "wood" if x < wx else "woodDark")
                    if y < 23 and x < wx + 1:
                        c.put(x, y, "woodLight")
        for (dx, dy) in ((0, -4), (0, 4), (-4, 0), (4, 0), (-3, -3), (3, 3), (-3, 3), (3, -3)):
            c.line(wx, 24, wx + dx, 24 + dy, "wood")
        c.put(wx, 24, "stoneDark")
        c.put(wx + 1, 24, "ink")
    # the shafts down to the ground
    c.line(41, 19, 47, 28, "ink")
    c.line(41, 20, 46, 28, "wood")
    c.line(42, 19, 47, 27, "woodLight")
    # the bed
    c.rect(1, 16, 42, 20, "ink")
    c.hline(2, 41, 17, "woodLight")
    c.hline(2, 41, 18, "wood")
    c.hline(2, 41, 19, "woodDark")
    for x in range(6, 41, 7):
        c.vline(x, 17, 19, "woodDark")
    st = stamps("cart")
    c.stamp(st["coinSign"], 19, 16)
    # the poles and the awning
    for px in (3, 39):
        c.vline(px, 3, 16, "ink")
        c.vline(px + 1, 3, 16, "wood")
    for x in range(0, 45):
        stripe = (x // 4) % 2 == 0
        for y in range(1, 5):
            c.put(x, y, ("dusk" if y > 1 else "dawnRose") if stripe else ("parchment" if y > 1 else "plaster"))
        c.put(x, 0, "ink")
        if x % 4 in (1, 2):
            c.put(x, 5, "dusk" if stripe else "parchment")
            c.put(x, 6, "ink")
        else:
            c.put(x, 5, "ink")
    c.vline(0, 0, 5, "ink")
    c.vline(44, 0, 5, "ink")
    # the wares
    for (name, x) in (("barrel", 5), ("crate", 13), ("bolts", 24), ("jugs", 31)):
        w = st[name]
        c.stamp(w, x, 16 - w.h)
    c.stamp(st["rug"], 12, 16 - st["crate"].h - st["rug"].h + 1)
    c.stamp(st["lantern"], 36, 6)
    glass_mask(c, "cart lantern", 37, 8, 37, 9)
    light_at(c, "cart lantern", "lantern", 37, 9, 20)
    return c


SPRITES = {
    "hallFront": hall_front,
    "chapelInterior": chapel_interior,
    "kitchenInterior": kitchen_interior,
    "bench": bench,
    "taxLectern": tax_lectern,
    "marekCart": marek_cart,
    "statue": statue,
    "speakerMark": speaker_mark,
}
