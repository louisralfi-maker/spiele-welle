#!/usr/bin/env python3
"""The prologue's lantern slides (panels lane, docs/lanes/panels.md; STORY.md section 8), painted in the game's own
look: 320 x 160 pixels each, written to Resources/Slides/<name>.png. One slide per run (this Mac's heat rule), through
the director's art lock:

    bash <artlock.sh> python3 -I tools/slides/slideart.py slidePrologue1 [--preview <dir>]

Slides: slidePrologue1 (the Worldwall at dusk), slidePrologue2 (into the Throat), slidePrologue3 (Aldric rides out),
slidePrologue4Lord, slidePrologue4Lady (the hall: the young lamplighter and the circlet). Deterministic.
"""
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from paint import (W, H, P, Canvas, add, blit, clamp, fbm, fir, firs_on, grid, h1, h2, hexc, hills, lit, luma, mix,  # noqa
                   noise1, sawtooth, scale, sky, smooth, sprite, vnoise, GAME)

OUT = os.path.join(GAME, "Resources", "Slides")


# =====================================================================================================================
# 1. A wall of mountains parts the world. It has one door.
#    The Worldwall from far off at dusk: snow peaks above the clouds, one black upright cleft, and in it a small castle
#    with lit windows. Warm valley lights below, right.
# =====================================================================================================================

CLEFT_X = 108


def slide1():
    c = Canvas()
    # The sky behind the wall: the sun is down behind it (the west), so the wall stands dark against an afterglow.
    sky_stops = [(0, hexc("#121A3E")), (10, hexc("#1C2452")), (18, hexc("#3A3670")), (26, hexc("#8A4A6E")),
                 (33, hexc("#D0705E")), (40, hexc("#F0A060")), (60, hexc("#F6B670"))]
    sky(c, sky_stops, 0, 60, bands=12)
    for i in range(14):
        x = int(h1(i, 11) * 300) + 4
        y = int(h1(i, 12) * 12) + 1
        if 250 < x < 300:
            continue
        c.put(x, y, P("farPale") if h1(i, 13) > 0.35 else P("foam"))
    moon(c, 284, 9)

    # The Worldwall: a rampart of big broken teeth of nearly one height across the whole frame (never a pyramid); two
    # tall teeth stand like door posts either side of the cleft.
    ridge = [27 + 10 * (fbm(x * 0.018, 0.4, 29, 2) - 0.5) for x in range(W)]
    teeth = [(CLEFT_X - 9, 7, 5, 21), (CLEFT_X + 10, 5, 8, 18)]
    x = -8
    i = 0
    while x < W + 10:
        if abs(x - CLEFT_X) > 20:
            teeth.append((x, 3 + h1(i, 24) * 9, 3 + h1(i, 25) * 10, 5 + h1(i, 21) * 13))
        x += 6 + int(h1(i, 23) * 13)
        i += 1
    base_line = list(ridge)
    for px, wl, wr, hgt in teeth:
        for x in range(int(px - wl) - 1, int(px + wr) + 2):
            if 0 <= x < W:
                d = (px - x) / wl if x < px else (x - px) / wr
                if d < 1:
                    y = base_line[min(W - 1, max(0, int(px)))] - hgt * (1 - d) ** 0.95
                    ridge[x] = min(ridge[x], y)
    for x in range(W):
        rough = (fbm(x * 0.33, 3.1, 33, 3) - 0.5) * 3.5
        ridge[x] = min(40.0, max(5.0, ridge[x] + rough))
    face_hi = hexc("#36407A")
    face_lo = hexc("#1F2750")
    rib = hexc("#424E8A")
    rib_lt = hexc("#56629E")
    gully = hexc("#1A2046")
    snow_sh = hexc("#8D96C4")
    snow_lt = hexc("#C9CEE4")
    rim_warm = hexc("#F2B088")
    rim_rose = hexc("#C47C88")

    def wall(x, y, depth):
        big = fbm(x * 0.05, y * 0.008, 39, 2)
        crack = fbm(x * 0.28, y * 0.018, 41, 2)
        base = mix(face_hi, face_lo, smooth(4, 85, depth))
        if big > 0.6:
            base = mix(base, rib_lt if big > 0.68 and depth < 50 else rib, 0.7)
        elif big < 0.42:
            base = mix(base, gully, 0.75)
        # the rock beside the cleft catches the light that comes through it
        near = abs(x - CLEFT_X)
        if near < 16:
            base = mix(base, rib_lt, 0.35 * smooth(16, 6, near) * smooth(90, 20, y))
        col = base
        if crack < 0.28:
            col = gully
        cap = (3 + 6 * fbm(x * 0.11, 1.7, 47, 2)) * smooth(30, 14, ridge[x])
        if depth < cap:
            col = snow_lt if fbm(x * 0.4, y * 0.4, 49, 2) > 0.5 and depth < cap - 2 else snow_sh
        elif depth < cap + 12 and crack > 0.72:
            col = snow_sh
        return col

    c.column_fill(ridge, wall, bottom=[120] * W)
    for x in range(W):
        y = int(math.ceil(ridge[x]))
        if 0 <= y < H:
            hi = ridge[x] < 18
            c.put(x, y, rim_warm if hi else rim_rose)
            if hi and (ridge[x - 1] if x else 99) > ridge[x]:
                c.put(x, y + 1, mix(rim_warm, snow_lt, 0.5))

    # The cleft: one black upright slit through the whole wall. Where it opens through the ridge the afterglow shows
    # through it; below, it is black down to the foot, a little wider where the castle sits.
    steps = [hexc("#F0A060"), hexc("#D0705E"), hexc("#A04A60"), hexc("#5E2E58"), hexc("#3A1A36"), hexc("#1C1430")]
    top = 14
    for y in range(top, 120):
        t = (y - top) / 106
        half = 2.4 + 4.4 * clamp(t) ** 1.6
        wob = (noise1(y * 0.2, 61) - 0.5) * 2.0
        l, r = CLEFT_X + wob - half, CLEFT_X + wob + half
        k = (y - 22) // 4
        col = steps[k] if 0 <= k < len(steps) else (None if k < 0 else P("nightDeep"))
        for xx in range(int(round(l)), int(round(r)) + 1):
            c.put(xx, y, col if col else c.get(xx, min(H - 1, y)))
        if y > 22:
            c.put(int(round(l)) - 1, y, hexc("#6874B0") if y < 70 else hexc("#4C5892"))
            c.put(int(round(r)) + 1, y, hexc("#141936"))

    # The cloud deck across the wall's middle: snow peaks above, the cleft left open.
    cloud_puffs(c, 66, 8, gap=(CLEFT_X - 10, CLEFT_X + 10), seed=71, span=(-10, 98))
    cloud_puffs(c, 62, 10, gap=(CLEFT_X - 10, CLEFT_X + 12), seed=75, span=(121, 222))
    cloud_puffs(c, 69, 7, gap=(0, 0), seed=77, span=(214, 330))
    wisps(c, 92, seed=73, gap=(CLEFT_X - 14, CLEFT_X + 14))

    # The castle wedged in the cleft's foot: stone lit by its own windows, the house's lantern on the keep.
    castle_far(c, CLEFT_X, 119)

    # Mist lying at the wall's foot.
    mist_band(c, 113, 124, seed=81, colour_top=hexc("#6A6CA8"), colour=hexc("#4C5088"),
              keep=(CLEFT_X - 11, CLEFT_X + 11, 120))

    # The valley at dusk: forested hills, each nearer row darker.
    far = firs_on(hills(127, 6, 0.022, 91), 92, every=(2, 4), height=(2, 4))
    c.column_fill(far, lambda x, y, d: hexc("#2C3566") if d < 1.2 and h2(x, y, 3) > 0.4 else hexc("#222A52"))
    river(c)
    mid = firs_on(hills(138, 9, 0.017, 93), 94, every=(2, 5), height=(3, 6))
    c.column_fill(mid, lambda x, y, d: hexc("#161C3C"))
    mist_band(c, 146, 150, seed=83, colour_top=hexc("#3A3F72"), colour=hexc("#2A2F5C"), keep=None,
              x_range=(140, 320))
    town(c)
    near = firs_on(hills(154, 7, 0.02, 95), 96, every=(3, 6), height=(4, 8))
    c.column_fill(near, lambda x, y, d: hexc("#0D1229"))
    road_lights(c)
    # The foreground: a dark crest and firs framing the view.
    crest = [148 - 22 * smooth(110, 0, x) + (noise1(x * 0.2, 97) - 0.5) * 3 for x in range(W)]
    c.column_fill(crest, lambda x, y, d: hexc("#080A18") if x < 140 else None)
    fir(c, 13, 160, 96, hexc("#070915"), lit=hexc("#131A33"), seed=3)
    fir(c, 34, 160, 66, hexc("#080B19"), lit=hexc("#151C38"), seed=4)
    fir(c, 304, 160, 44, hexc("#080A17"), lit=hexc("#121830"), seed=6)
    ferns(c, 0, 320, 156, hexc("#05070E"), seed=5)
    return c


def wisps(c, y0, seed, gap):
    """A few loose strands of mist low on the wall."""
    for k in range(5):
        x0 = int(h1(k, seed) * 280)
        length = 18 + int(h1(k, seed + 1) * 30)
        y = y0 + int(h1(k, seed + 2) * 8) - 4
        for x in range(x0, x0 + length):
            if gap[0] <= x <= gap[1]:
                continue
            edge = min(x - x0, x0 + length - x)
            c.put(x, y, hexc("#5A5E9C"), 0.85 if edge > 3 else 0.45)
            if 4 < edge and h2(x, y, seed) > 0.5:
                c.put(x, y + 1, hexc("#474B88"), 0.7)


def moon(c, cx, cy):
    for y in range(cy - 5, cy + 6):
        for x in range(cx - 5, cx + 6):
            d = math.hypot(x + 0.5 - cx, y + 0.5 - cy)
            d2 = math.hypot(x + 0.5 - cx - 2.2, y + 0.5 - cy + 1.0)
            if d <= 4.2 and d2 > 3.6:
                c.put(x, y, P("foam") if d < 3.6 else P("farPale"))
    c.halo(cx, cy, 7, hexc("#2A3260"), 0.25, steps=1)


def cloud_puffs(c, centre, thick, gap, seed, thin=False, span=(-8, W + 8)):
    """A deck of clouds made of puffs, flat levels lit from above by the afterglow, a flat foot; open at `gap`."""
    lit_top = hexc("#E3A49E") if not thin else hexc("#9A88B4")
    upper = hexc("#9C8CB8") if not thin else hexc("#5E62A0")
    body = hexc("#6A6CA8") if not thin else hexc("#4A4E8C")
    under = hexc("#4C5090") if not thin else hexc("#3A3E78")
    puffs = []
    x = float(span[0])
    i = 0
    while x < span[1]:
        edge = min(x - span[0], span[1] - x) / max(1, (span[1] - span[0]) * 0.25)
        r = (thick * 0.45 + h1(i, seed) * thick * 1.0) * (0.6 if thin else 1) * (0.55 + 0.45 * min(1, edge))
        if not (gap[0] - r * 0.6 < x < gap[1] + r * 0.6):
            puffs.append((x, centre + (h1(i, seed + 1) - 0.5) * thick * 0.6, r))
        x += r * (0.9 + h1(i, seed + 2) * 0.9)
        i += 1
    foot = centre + thick * (0.55 if not thin else 0.4)
    for y in range(int(centre - thick * 2), int(foot) + 2):
        for x in range(max(0, span[0]), min(W, span[1])):
            top = None
            for px, py, r in puffs:
                dx = x + 0.5 - px
                if abs(dx) < r:
                    t = py - math.sqrt(r * r - dx * dx)
                    if top is None or t < top:
                        top = t
            if top is None or y < top or y > foot:
                continue
            depth = y - top
            if depth < 1.2:
                col = lit_top
            elif depth < thick * 0.45:
                col = upper
            elif y < foot - 1.5:
                col = body
            else:
                col = under
            c.put(x, y, col)


def cloud_deck(c, top, bottom, gap, seed, thin=False):
    """Flat scalloped cloud levels across the frame, lit from behind and above by the afterglow."""
    lit_top = hexc("#D69A9C") if not thin else hexc("#8A7AA8")
    body = hexc("#6E6CA6") if not thin else hexc("#4E5290")
    under = hexc("#4E5290") if not thin else hexc("#3C4078")
    for x in range(W):
        # taper the deck into the gap around the cleft
        g = 0.0
        if gap[0] - 16 < x < gap[1] + 16:
            g = smooth(16, 0, min(abs(x - gap[0]), abs(x - gap[1]))) if not (gap[0] <= x <= gap[1]) else 1.0
        if g >= 1:
            continue
        scallop = 0.0
        for k, (period, amp) in enumerate(((23, 3.0), (11, 1.6), (6, 0.8))):
            ph = h1(k, seed) * 6.28
            scallop += amp * abs(math.sin(x * math.pi / period + ph))
        t = top + 6 - scallop + g * 9
        b = bottom - 2 * fbm(x * 0.07, 3.3, seed + 1) - g * 6
        band2 = top + 9 + 2 * fbm(x * 0.05, 9.1, seed + 2)
        for y in range(int(math.ceil(t)), int(b) + 1):
            if y < t + 1.5:
                col = lit_top
            elif y < band2:
                col = mix(body, lit_top, 0.35)
            elif y < b - 2:
                col = body
            else:
                col = under
            c.put(x, y, col)


def mist_band(c, top, bottom, seed, colour_top, colour, keep=None, x_range=(0, W)):
    for x in range(*x_range):
        t = top + 3 * fbm(x * 0.06, 5.5, seed) + 1.5 * abs(math.sin(x * 0.21 + 1.3))
        if keep and keep[0] <= x <= keep[1]:
            t = max(t, keep[2])
        for y in range(int(math.ceil(t)), bottom + 1):
            c.put(x, y, colour_top if y < t + 1.5 else colour)


def castle_far(c, cx, base):
    """The castle in the cleft, about 22 px tall: a keep with two towers and a curtain, its stone lit warm from its own
    windows so it stands clear against the black."""
    lit_ = hexc("#8A6A78")
    stone = hexc("#5A5684")
    shade = hexc("#2E3060")
    c.wash(cx, base - 6, 12, 14, P("fireOrange"), 1.0, mask=lambda x, y: luma(c.get(x, y)) < 0.1)
    # curtain wall across the cleft, crenellated
    c.rect(cx - 8, base - 6, cx + 8, base, stone)
    for x in range(cx - 8, cx + 9, 2):
        c.put(x, base - 7, stone)
    c.rect(cx + 3, base - 6, cx + 8, base, shade)
    c.rect(cx - 8, base - 6, cx - 8, base, lit_)
    # side towers with teal-slate cones
    for tx in (cx - 6, cx + 6):
        c.rect(tx - 1, base - 13, tx + 1, base, stone)
        c.rect(tx + 1, base - 13, tx + 1, base, shade)
        c.put(tx - 1, base - 13, lit_)
        c.rect(tx - 1, base - 14, tx + 1, base - 14, P("roofDeep"))
        c.put(tx, base - 15, P("roofLight"))
        c.put(tx, base - 16, P("roofDeep"))
    # the keep
    c.rect(cx - 2, base - 19, cx + 2, base, stone)
    c.rect(cx + 1, base - 19, cx + 2, base, shade)
    c.rect(cx - 2, base - 19, cx - 2, base - 7, lit_)
    for x in (cx - 2, cx, cx + 2):
        c.put(x, base - 20, stone)
    # warm windows
    gold, orange = P("fireGold"), P("fireOrange")
    for (x, y, col) in ((cx - 1, base - 16, gold), (cx, base - 12, orange), (cx - 1, base - 8, gold),
                        (cx - 6, base - 10, orange), (cx + 6, base - 9, gold), (cx - 4, base - 3, orange),
                        (cx + 1, base - 3, gold), (cx + 5, base - 3, orange), (cx - 6, base - 5, gold)):
        c.put(x, y, col)
    # the gate, lit
    c.rect(cx - 1, base - 2, cx, base, P("fireOrange"))
    # the house's lantern on the keep: a small flame and its glow
    c.put(cx, base - 21, P("fireGold"))
    c.put(cx, base - 22, P("fireWhite"))
    for dx, dy in ((-1, -22), (1, -22), (0, -23), (-1, -21), (1, -21)):
        c.glow(cx + dx, base + dy, P("fireOrange"), 0.35)


def river(c):
    """The river from the cleft's foot down through the valley, catching the afterglow in the gaps between hills."""
    pts = []
    y = 121
    x = CLEFT_X + 2.0
    while y < 160:
        pts.append((x, y))
        x += 2.3 + math.sin(y * 0.33) * 2.6
        y += 1
    for i, (x, y) in enumerate(pts):
        col = hexc("#C27E86") if (i // 3) % 3 == 0 else hexc("#7C70A8")
        c.put(int(x), int(y), col)
        c.put(int(x) + 1, int(y), hexc("#5C5890"))


def town(c):
    """Tallowford on its hill, lower right: steep roofs, warm windows, a chapel tower, smoke, the warmth of it on the
    slope."""
    house = hexc("#1A1C38")
    wall_warm = hexc("#4A3442")
    roof = hexc("#24284E")
    roof_lt = hexc("#3A4274")
    gold, orange = P("fireGold"), P("fireOrange")
    c.wash(262, 141, 60, 20, P("fireOrange"), 0.9)
    houses = [(212, 8, 5, 0), (222, 9, 6, 1), (233, 7, 5, 0), (242, 10, 7, 1), (254, 8, 5, 0), (264, 9, 6, 2),
              (276, 7, 6, 0), (285, 10, 7, 1), (297, 8, 5, 0), (227, 7, 5, 3), (259, 7, 5, 3), (281, 8, 5, 3)]
    for i, (x, w, h, row) in enumerate(houses):
        by = 144 + int(3 * math.sin(x * 0.045)) + row * 3
        c.rect(x, by - h, x + w - 1, by, house)
        c.rect(x, by - h + 1, x + 1, by, wall_warm)
        rise = (w + 1) // 2
        for k in range(rise):
            c.rect(x - 1 + k, by - h - k - 1, x + w - k, by - h - k - 1, roof if k else roof_lt)
        c.put(x - 1, by - h, roof)
        if h2(i, 1, 7) > 0.08:
            wx = x + 2
            c.rect(wx, by - 3, wx + 1, by - 2, gold if h2(i, 2, 7) > 0.4 else orange)
        if w > 7 and h2(i, 3, 7) > 0.25:
            c.put(x + w - 3, by - 3, orange)
            c.put(x + w - 3, by - 2, orange)
        if h2(i, 5, 7) > 0.5:
            c.put(x + w // 2, by - h - rise + 2, gold)
        if i in (1, 3, 7):
            for s_ in range(12):
                c.put(x + w - 2 + int(math.sin(s_ * 0.6) * 1.2) + s_ // 4, by - h - rise - 1 - s_, hexc("#3E4676"),
                      0.6 - s_ * 0.04)
    # the chapel tower
    c.rect(270, 122, 273, 140, house)
    c.rect(270, 123, 270, 140, wall_warm)
    for k in range(3):
        c.rect(270 + k // 2, 119 + k, 273 - k // 2, 119 + k, roof_lt if k == 0 else roof)
    c.put(271, 118, roof_lt)
    c.rect(271, 126, 272, 127, gold)
    # lanterns in the lanes
    for x, y in ((238, 146), (270, 147), (293, 146)):
        c.put(x, y, P("fireWhite"))
        c.pool(x, y + 2, 9, P("fireGold"), 0.6, squash=0.45, steps=3)


def road_lights(c):
    """Lanterns along the road from the town toward the cleft."""
    road = hexc("#2A3060")
    pts = [(212, 147), (196, 144), (180, 141), (164, 139), (148, 137), (132, 136)]
    for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
        n = abs(x1 - x0)
        for k in range(n):
            c.put(round(x0 + (x1 - x0) * k / n), round(y0 + (y1 - y0) * k / n) + 1, road)
    for (x, y) in pts[1:-1]:
        c.put(x, y, P("fireGold"))
        c.glow(x - 1, y, P("fireOrange"), 0.25)
        c.glow(x + 1, y, P("fireOrange"), 0.25)
        c.glow(x, y - 1, P("fireOrange"), 0.25)


def ferns(c, x0, x1, base, colour, seed):
    for i, x in enumerate(range(x0, x1, 5)):
        hgt = 3 + int(h1(i, seed) * 5)
        lean = (h1(i, seed + 1) - 0.5) * 2
        for k in range(hgt):
            c.put(int(x + lean * k * 0.5), base + 4 - k, colour)
            if k % 2 == 0:
                c.put(int(x + lean * k * 0.5) - 1, base + 4 - k, colour)
                c.put(int(x + lean * k * 0.5) + 1, base + 3 - k, colour)


# =====================================================================================================================
# 2. For a thousand years House Lantern has held it. Nobody knows what waits on the other side.
#    Seen from the castle wall, looking west: black rock walls of the Throat, no plant anywhere, and at the far end a
#    narrow slit of grey-violet fog with cold eyes in it. A teal banner with the gold lantern at the frame's edge.
# =====================================================================================================================

VP = (141.0, 76.0)


def slide2():
    c = Canvas(hexc("#0A0F22"))
    vx, vy = VP
    # The strip of night sky between the Throat's walls.
    sky(c, [(0, hexc("#0E1430")), (30, hexc("#18204A")), (60, hexc("#2A3266"))], 0, 80, bands=10)
    for i in range(10):
        x = 96 + int(h1(i, 201) * 120)
        y = int(h1(i, 202) * 30) + 2
        c.put(x, y, P("farPale") if h1(i, 203) > 0.4 else P("mist"))

    # The far end: a narrow slit of grey-violet fog, the brightest cold thing in the picture.
    fog_core = hexc("#9AA0EE")
    fog_mid = hexc("#7078CC")
    fog_dim = hexc("#4E58A6")
    fog_far = hexc("#3A447E")
    for y in range(36, 104):
        for x in range(118, 166):
            dy = (y - 98) / 50.0
            dx = (x + 0.5 - vx) / (13.0 + (98 - y) * 0.05)
            d = dx * dx + dy * dy * 1.4
            wob = (fbm(x * 0.15, y * 0.09, 211, 2) - 0.5) * 0.5
            d += wob
            if d < 0.16:
                col = fog_core
            elif d < 0.38:
                col = fog_mid
            elif d < 0.7:
                col = fog_dim
            elif d < 1.05:
                col = fog_far
            else:
                continue
            c.put(x, y, col)
    # The Gloom's people in the fog: dark, too tall, each with one cold eye.
    gloom_figures(c)

    # The Throat's floor: bare stone and scree running to the fog, catching its cold light down the middle.
    floor_pts = [(vx - 9, 99), (vx + 9, 99), (330, 160), (-30, 160)]

    def floor(x, y):
        dy = max(0.6, y + 0.5 - vy)
        z = 40.0 / dy
        lateral = (x + 0.5 - vx) * z / 40.0
        t = (y - 99) / 61.0
        lane = smooth(1.6, 0.0, abs(lateral)) * smooth(1.2, 0.0, t)
        base = mix(hexc("#1C2246"), hexc("#0E1330"), smooth(0, 1, t))
        col = mix(base, hexc("#4A5294"), lane * 0.75)
        cell = vnoise(lateral * 3.0, z * 2.2, 221)
        if cell > 0.68:
            col = mix(col, hexc("#3A4278"), 0.55)
        elif cell < 0.28:
            col = mix(col, hexc("#080C20"), 0.55)
        return col
    c.poly(floor_pts, None, fn=floor)

    # The three lines across the Throat, each with its braziers: small warm pools held against the dark.
    for k, (y, h, fires) in enumerate(((101, 2, (vx - 4, vx + 6)), (108, 3, (vx - 14, vx + 15)),
                                       (121, 6, (vx - 33, vx + 31)))):
        t = (y - 99) / 61.0
        half = 9 + t * 170
        for fx in fires:
            c.pool(fx, y + 1 + t * 3, 3 + t * 28, P("fireGold"), 0.8, squash=0.32, steps=0)
        wall_c = hexc("#121834")
        c.rect(vx - half, y - h, vx + half, y, wall_c)
        step = max(2, int(2 + t * 6))
        for x in range(int(vx - half), int(vx + half) + 1, step):
            c.rect(x, y - h - max(1, int(t * 4)), x + max(0, int(step / 2) - 1), y - h, wall_c)
        for x in range(int(vx - half), int(vx + half) + 1):
            if c.get(x, y - h - 1) != wall_c:
                pass
        for fx in fires:
            fy = y - h - 1 - max(1, int(t * 4))
            c.wash(fx, fy + 2, 3 + t * 14, 2 + t * 8, P("fireOrange"), 1.2)
            c.put(fx, fy, P("fireGold"))
            if t > 0.1:
                c.put(fx, fy - 1, P("fireWhite"))
                c.put(fx - 1, fy, P("fireOrange"))
                c.put(fx + 1, fy, P("fireOrange"))
                c.put(fx, fy - 2, P("fireGold"))

    # The Throat's walls: black rock in slabs, ledges running to the far end, the faces near the fog in its cold light.
    left = [(-2, -2), (96, -2), (vx - 9, 62), (vx - 9, 99), (-30, 160), (-2, 160)]
    right = [(322, -2), (206, -2), (vx + 9, 62), (vx + 9, 99), (330, 160), (322, 160)]
    tones = [hexc("#0E142E"), hexc("#141B3A"), hexc("#1A2246"), hexc("#111832"), hexc("#18203F")]

    def rock(side):
        def f(x, y):
            run = (vx - x - 0.5) if side == 0 else (x + 0.5 - vx)
            run = max(1.0, run)
            u = 600.0 / run                      # depth along the wall
            v = (y + 0.5 - vy) / run             # height on the wall
            slab = int(math.floor(u / 9.0 + (vnoise(v * 3.0, u * 0.05, 231 + side) - 0.5) * 0.8))
            col = tones[(slab * 7 + side * 3) % len(tones)]
            frac = (u / 9.0 + (vnoise(v * 3.0, u * 0.05, 231 + side) - 0.5) * 0.8) % 1.0
            if frac < 0.08 * min(1.0, run / 30):
                col = hexc("#080B1C")
            lv = v * 3.2 + (vnoise(u * 0.12, 1.0, 233 + side) - 0.5) * 0.9
            ledge = lv % 1.0
            broken = vnoise(u * 0.35, math.floor(lv) * 1.7, 235 + side) > 0.45
            if broken and ledge < 0.05:
                col = mix(col, hexc("#283060"), 0.75)
            elif broken and ledge < 0.13:
                col = mix(col, hexc("#070A1A"), 0.55)
            dist = math.hypot(x - vx, y - vy)
            col = mix(col, hexc("#3A4488"), 0.65 * smooth(60, 8, dist) * smooth(-0.6, 0.4, v + 0.2))
            return col
        return f
    c.poly(left, None, fn=rock(0))
    c.poly(right, None, fn=rock(1))
    for y in range(60, 100):
        c.put(int(vx - 10), y, hexc("#5A64B0"))
        c.put(int(vx + 9), y, hexc("#48529A"))
    for (x0, y0), (x1, y1) in (((96, 0), (vx - 9, 62)), ((206, 0), (vx + 9, 62))):
        n = int(abs(y1 - y0))
        for k in range(n):
            x = x0 + (x1 - x0) * k / n
            c.put(int(x), int(y0 + (y1 - y0) * k / n), hexc("#3A4482"))

    # Our wall in front: merlons and embrasures lit warm by a brazier, the banner of House Lantern at the edge.
    banner(c)
    battlement(c)
    brazier(c, 262, 129)
    return c


def gloom_figures(c):
    """Three of the Gloom's people standing in the far fog: navy silhouettes, gaunt and too long, one cold eye each,
    and more eyes deeper in the fog."""
    dark = P("nightBlue")
    deep = P("nightDeep")
    eye = P("wraithWhite")
    tall = """
..dd.
.ddd.
.dEd.
..dd.
.ddd.
dddd.
dddd.
.ddd.
.d.dd
.d..d
.d..d
d...d
"""
    small = """
.dd.
dEd.
.dd.
dddd
.dd.
.dd.
d..d
d..d
"""
    crouch = """
..dd..
.dEdd.
..dddd
.dddd.
dd..dd
d....d
"""
    legend = {"d": dark, "E": eye}
    grid(c, tall, 139, 86, legend)
    grid(c, small, 131, 91, legend)
    grid(c, crouch, 147, 93, legend, flip=True)
    for (x, y) in ((136, 80), (151, 84), (127, 87), (156, 90), (143, 74)):
        c.put(x, y, eye)
        c.put(x - 1, y, P("wraithDim"))
    c.put(141, 98, deep)


def battlement(c):
    """The castle wall's top across the bottom of the frame: merlons and embrasures of big dressed stones, cold in the
    night and warm near the fire."""
    stone = P("stone")
    stone_dk = P("stoneMid")
    stone_sh = P("stoneDark")
    stone_lt = P("stoneLight")
    top = 134
    shade = lit((58, 66, 108), [(262, 126, 150, P("fireOrange"), 1.15), (262, 126, 55, P("fireGold"), 0.8)], steps=0)

    def stone_at(x, y, base):
        row = (y - top + 20) // 7
        off = (row * 5) % 11
        course = (y - top + 20) % 7 == 6
        joint = ((x + off) % 11) == 0
        col = base
        if course or joint:
            col = stone_sh
        else:
            n = h2((x + off) // 11, row, 241)
            if n > 0.7:
                col = stone_dk
            elif n < 0.15:
                col = stone_lt
        return shade(x, y, col)
    for y in range(top + 9, H):
        for x in range(W):
            c.put(x, y, stone_at(x, y, stone))
    x = -8
    while x < W:
        x0, x1 = x, x + 15
        for y in range(top, top + 9):
            for xx in range(max(0, x0), min(W, x1 + 1)):
                c.put(xx, y, stone_at(xx, y, stone if xx < x1 - 2 else stone_dk))
        for xx in range(max(0, x0), min(W, x1 + 1)):
            c.put(xx, top - 1, shade(xx, top - 1, stone_lt))
        x += 24
    for x in range(W):
        c.put(x, top + 9, shade(x, top + 9, stone_lt))
        c.put(x, top + 10, shade(x, top + 10, stone_sh))


def brazier(c, x, y):
    """An iron brazier on the parapet: the fire, its sparks, its light."""
    iron = hexc("#1A1416")
    c.rect(x - 4, y, x + 4, y + 2, iron)
    c.rect(x - 3, y + 3, x + 3, y + 3, iron)
    c.put(x - 3, y + 4, iron)
    c.put(x + 3, y + 4, iron)
    flame = """
....w....
...wy....
...yyw...
..yyyy...
..oyyyo..
.ooyyyoo.
.eooyoooe
eeooooooe
"""
    grid(c, flame, x - 4, y - 8, {"w": P("fireWhite"), "y": P("fireGold"), "o": P("fireOrange"), "e": P("ember")})
    for (dx, dy) in ((-2, -12), (1, -15), (3, -11), (-1, -18)):
        c.put(x + dx, y + dy, P("fireGold") if dy > -14 else P("ember"))
    c.halo(x, y - 3, 16, P("fireOrange"), 0.22, steps=0)
    c.halo(x, y - 4, 6, P("fireGold"), 0.25, steps=0)


def banner(c):
    """House Lantern's banner on its pole at the frame's right edge: teal cloth in folds, the gold lantern on it, lit
    from below by the brazier."""
    pole = P("woodDark")
    pole_lt = P("wood")
    px = 296
    c.rect(px, 0, px + 1, 134, pole)
    c.rect(px, 0, px, 134, pole_lt)
    # the crossbar
    c.rect(px - 22, 9, px + 30, 10, pole)
    c.rect(px - 22, 9, px + 30, 9, pole_lt)
    teal, teal_dk, teal_lt = P("banner"), P("roofDeep"), P("roofLight")
    warm = lit((96, 108, 150), [(262, 126, 130, P("fireOrange"), 1.2)], steps=0)
    x0, x1 = px - 19, px + 28
    for x in range(x0, x1 + 1):
        sway = int(2.2 * math.sin((x - x0) * 0.25))
        bottom = 104 - (8 if (x - x0) % 16 < 8 and False else 0)
        tail = abs(((x - x0) % 24) - 12)
        bottom = 96 + tail
        for y in range(11, bottom + 1):
            fold = math.sin((x - x0) * 0.55 + y * 0.03)
            col = teal
            if fold < -0.55:
                col = teal_dk
            elif fold > 0.7:
                col = teal_lt
            if y > bottom - 2:
                col = P("gold") if (x + y) % 3 else teal_dk
            c.put(x + (sway if y > 30 else 0) * (y - 30) // 70, y, warm(x, y, col))
    # the gold lantern on the cloth
    lantern = """
......g......
.....g.g.....
......g......
....ggggg....
...gg...gg...
..ggggggggg..
..g.yyyyy.g..
..g.yyWyy.g..
..g.yWWWy.g..
..g.yyWyy.g..
..g.yyyyy.g..
..ggggggggg..
...gg...gg...
....ggggg....
"""
    gold_lit = lit((150, 150, 170), [(262, 126, 130, P("fireOrange"), 1.0)], steps=0)
    grid(c, lantern, px - 6, 36, {"g": lambda x, y: gold_lit(x, y, P("gold")),
                                  "y": lambda x, y: gold_lit(x, y, hexc("#B8862E")),
                                  "W": lambda x, y: gold_lit(x, y, P("strawLight"))})


# =====================================================================================================================
# 3. This autumn the Great Beacon went dark. Lord Aldric rode out to light it. He did not come back.
#    The Throat's mouth: the dark beacon tower on the left, a broad rider in a teal cloak with a lit lantern going out
#    along a rutted road between two statues that face us, firs and fog beyond. Twelve small lights follow him.
# =====================================================================================================================

HORIZON = 84


def slide3():
    c = Canvas()
    # The shadow land's night: deep blue, a high moonlit cloud deck, the fog bright and periwinkle at the horizon.
    sky(c, [(0, hexc("#141B44")), (26, hexc("#232C62")), (60, hexc("#3E4886")), (HORIZON + 6, hexc("#5E68AC"))],
        0, HORIZON + 6, bands=14)
    for i in range(12):
        x = int(h1(i, 301) * 310) + 5
        y = int(h1(i, 302) * 20) + 2
        c.put(x, y, P("farPale"))
    # the moon behind the high cloud
    c.halo(236, 22, 26, hexc("#4A5498"), 0.35, steps=0)
    c.disc(236, 22, 7, P("foam"))
    c.disc(238, 21, 2, P("farPale"))
    moonlit_clouds(c)
    # far ridge and a row of firs behind the fog
    ridge = [HORIZON - 16 - 8 * fbm(x * 0.012, 0.3, 311, 3) for x in range(W)]
    c.column_fill(ridge, lambda x, y, d: hexc("#3C4686"), bottom=[HORIZON + 4] * W)
    row1 = firs_on([HORIZON - 3 + 3 * fbm(x * 0.03, 1, 313) for x in range(W)], 314, every=(2, 4), height=(5, 12))
    c.column_fill(row1, lambda x, y, d: hexc("#2C3670"), bottom=[HORIZON + 8] * W)
    # the bright fog bank the near shapes stand against
    fog_level(c, HORIZON - 1, HORIZON + 26, hexc("#9AA2EC"), hexc("#7C86D4"), 321)
    fog_level(c, HORIZON + 10, HORIZON + 26, hexc("#7C86D4"), hexc("#626CBC"), 322)
    # firs standing in the fog, half lost
    for k in range(9):
        x = 70 + int(h1(k, 324) * 250)
        if 100 < x < 200:
            continue
        fir(c, x, HORIZON + 14, 18 + h1(k, 325) * 16, hexc("#46509A"), seed=326 + k)
    # the moor in front: dead grass and peat, the road running out into the fog
    moor_top = [HORIZON + 20 + 2 * fbm(x * 0.05, 3, 317) for x in range(W)]
    c.column_fill(moor_top, lambda x, y, d: moor_at(x, y))
    road(c)
    # a near row of firs on the right and dead trees, dark against the fog
    for k, (x, base, hgt) in enumerate(((304, 136, 96), (290, 126, 64), (318, 146, 120), (272, 116, 38))):
        fir(c, x, base, hgt, hexc("#0E1530"), lit=hexc("#1E2A54"), seed=330 + k)
    dead_tree(c, 236, 110, 30, 341)
    dead_tree(c, 82, 112, 26, 343)
    # the two statues that face us, either side of the road where it turns away
    statue_front(c, 116, 120)
    statue_front(c, 190, 118)
    # the twelve lights following him along the road, and Lord Aldric at their head, riding out
    procession(c)
    aldric(c, 152, 121)
    # the dark beacon on the left: the Great Beacon, unlit, its bowl cold
    tower = sprite("greatBeacon")
    shade = lit((50, 58, 104), [(150, 100, 80, P("fireOrange"), 0.15)], steps=0)
    blit(c, tower, -6, 26, shade=shade)
    for y in range(26, 160):
        row = tower[y - 26] if y - 26 < len(tower) else None
        if not row:
            continue
        for x in range(len(row) - 1, -1, -1):
            if row[x][3] > 128:
                c.put(-6 + x, y, mix(c.get(-6 + x, y), hexc("#8090D8"), 0.5))
                break
    # the near ground, dark, with dead grass
    near = [151 + 4 * fbm(x * 0.04, 4, 319) - 10 * smooth(70, 0, x) for x in range(W)]
    c.column_fill(near, lambda x, y, d: hexc("#0A0E20"))
    ferns(c, 0, 320, 155, hexc("#05070F"), seed=351)
    return c


def moonlit_clouds(c):
    for k in range(3):
        y0 = 10 + k * 8
        x0 = int(h1(k, 361) * 200) - 20
        length = 90 + int(h1(k, 362) * 120)
        for x in range(max(0, x0), min(W, x0 + length)):
            edge = min(x - x0, x0 + length - x)
            thick = 1 + int(3 * smooth(0, 30, edge) * fbm(x * 0.05, k, 363))
            for y in range(y0, y0 + thick):
                c.put(x, y, hexc("#7270AA") if y == y0 else hexc("#4A4C81"))


def fog_level(c, top, bottom, lit_col, col, seed):
    for x in range(W):
        t = top + 2.5 * abs(math.sin(x * 0.09 + h1(1, seed) * 6)) + 2 * fbm(x * 0.04, 0.5, seed)
        for y in range(int(math.ceil(t)), bottom + 1):
            c.put(x, y, lit_col if y < t + 1.5 else col)


def moor_at(x, y):
    t = (y - HORIZON - 20) / 50.0
    level = 0 if t < 0.2 else 1 if t < 0.5 else 2
    base = [hexc("#30366A"), hexc("#222852"), hexc("#161B3A")][level]
    n = fbm(x * 0.06, y * 0.22, 371, 2)
    if n > 0.66:
        return mix(base, hexc("#3E4578"), 0.55)
    if n < 0.3:
        return mix(base, hexc("#0E1228"), 0.5)
    return base


def road_points():
    """The road: in from the right edge, across the moor, turning away between the statues into the fog."""
    pts = []
    for i in range(0, 101):
        t = i / 100.0
        if t < 0.55:
            u = t / 0.55
            x = 334 - (334 - 156) * u
            y = 146 - (146 - 123) * u ** 0.9
            w = 20 - 9 * u
        else:
            u = (t - 0.55) / 0.45
            x = 156 - 16 * u + 5 * math.sin(u * 3)
            y = 123 - (123 - (HORIZON + 21)) * u ** 0.8
            w = 11 - 9.5 * u
        pts.append((x, y, w))
    return pts


def road(c):
    pts = road_points()
    for (x, y, w) in pts:
        for dy in range(-int(w * 0.25) - 1, int(w * 0.25) + 2):
            for dx in range(-int(w), int(w) + 1):
                if dx * dx / (w * w + 0.01) + dy * dy / ((w * 0.25 + 0.6) ** 2) <= 1:
                    xx, yy = int(x + dx), int(y + dy)
                    rut = abs(abs(dx) - w * 0.45) < 0.8 and w > 4
                    col = hexc("#3C4680") if not rut else hexc("#1E2448")
                    if w < 4:
                        col = hexc("#5A64A8")
                    c.put(xx, yy, col)


def dead_tree(c, x, base, hgt, seed):
    col = hexc("#121834")
    for y in range(base - hgt, base + 1):
        lean = int((noise1(y * 0.2, seed) - 0.5) * 3)
        c.put(x + lean, y, col)
        if (base - y) > hgt * 0.4 and h2(x, y, seed) > 0.8:
            d = 1 if h2(y, x, seed) > 0.5 else -1
            for k in range(1, 4 + int(h2(y, y, seed) * 4)):
                c.put(x + lean + d * k, y - k // 2, col)


STATUE = """
.......hhhh.......
......hhhhhR......
......hHssHR......
......hssssR......
......hHssHR......
.......hhhR.......
....mmmmmmmmmR....
...mmmmmmmmmmmR...
..mmmmmmmmmmmmmR..
..mmmaaLLLaammmR..
..mmaa.LYL.aammR..
..mma..LLL..ammR..
..mmm...L...mmmR..
..mmmm.....mmmmR..
..mmmmmmmmmmmmmR..
..mmmmdmmmdmmmmR..
..mmmmdmmmdmmmmR..
..mmmmdmmmdmmmmR..
..mmmmdmmmdmmmmR..
.mmmmmdmmmdmmmmmR.
.mmmmmdmmmdmmmmmR.
.mmmmmdmmmdmmmmmR.
.mmmmmdmmmdmmmmmR.
.mmmmmdmmmdmmmmmR.
.mmmmdmmmmmdmmmmR.
mmmmmdmmmmmdmmmmmR
mmmmmdmmmmmdmmmmmR
mmmmmdmmmmmdmmmmmR
mmmmmdmmmmmdmmmmmR
mmmmdmmmmmmmdmmmmR
mmmmdmmmmmmmdmmmmR
PPPPPPPPPPPPPPPPPP
pppppppppppppppppp
pppppppppppppppqqq
pppppppppppppppqqq
pppppppppppppppqqq
qqqqqqqqqqqqqqqqqq
"""


def statue_front(c, cx, base):
    """One of the old statues facing home: a robed, hooded lord on a plinth holding a dead lantern before him,
    weathered stone dark against the fog, moonlit down its right side, moss in the folds."""
    lines = STATUE.strip("\n").split("\n")
    legend = {"h": hexc("#232A54"), "H": hexc("#3A4478"), "s": hexc("#0E1230"), "R": hexc("#9AA4DA"),
              "m": hexc("#283060"), "a": hexc("#323A6C"), "d": hexc("#1A2046"), "L": hexc("#141832"),
              "Y": hexc("#3A4A7A"), "P": hexc("#4A548C"), "p": hexc("#2C3464"), "q": hexc("#1A2044")}
    x0 = cx - 9
    y0 = base - len(lines) + 1
    grid(c, STATUE, x0, y0, legend)
    for k in range(6):
        x = x0 + 3 + int(h1(k, base) * 12)
        y = y0 + 8 + int(h1(k, base + 1) * 22)
        if c.get(x, y) == legend["m"]:
            c.put(x, y, hexc("#2A3E3C"))


WALKER = """
.....kk...
....kkkk..
....kkkk..
....ckkc..
...cccccc.
..acccccc.
.a.cccccc.
p..cccccc.
L..cccccc.
Y..cccccc.
L...ccccc.
....cc.cc.
....cc.cc.
....c...c.
...cc...cc
"""

WALKER_SMALL = """
...kk..
..kkkk.
..ckkc.
.acccc.
a.cccc.
L.cccc.
Y.cccc.
..cc.c.
..c..c.
.cc..cc
"""


def procession(c):
    """Twelve lantern bearers trailing the rider along the road, dark shapes on the moor, each a small warm light."""
    pts = road_points()
    cloak = hexc("#141A34")
    hood = hexc("#1C2244")
    legend = {"k": hood, "c": cloak, "a": hexc("#1E2448"), "p": P("woodDark"), "L": hexc("#1A1416"),
              "Y": P("fireGold")}
    for k in range(11, -1, -1):
        t = 0.51 - k * 0.0415
        x, y, w = pts[int(t * 100)]
        x += (1.5 if k % 2 else -1.5)
        big = k >= 5
        art = WALKER if big else WALKER_SMALL
        hgt = 15 if big else 10
        lx = int(x) - 3
        top = int(y) - hgt
        c.pool(lx + 1, y + 1, 9 if big else 6, P("fireGold"), 0.6, squash=0.4, steps=0)
        grid(c, art, lx, top, legend)
        ly = top + (9 if big else 6)
        c.put(lx, ly, P("fireWhite") if big else P("fireGold"))
        c.glow(lx - 1, ly, P("fireOrange"), 0.45)
        c.glow(lx + 1, ly, P("fireOrange"), 0.3)
        c.glow(lx, ly - 1, P("fireOrange"), 0.35)
        c.glow(lx, ly + 1, P("fireOrange"), 0.3)
        # the light on the bearer's front
        for dy in range(3, hgt - 2):
            for xx in range(lx + 2, lx + 5):
                col = c.get(xx, top + dy)
                if col == cloak:
                    c.put(xx, top + dy, mix(cloak, P("fireOrange"), 0.28))
                    break


ALDRIC = """
..ppp..................................
.p...p.................................
.p....p................................
.L.....p...............................
LLL.....p..............................
LYL......p.............................
LWL.......p............................
LYL........p......kkk..................
LLL.........p....kkkkk.................
.............p...kkkkk.................
..............p..fkkkk.................
...............aattcccc................
................attcccccc..............
................ttcccccccc.............
...............tcccccccccccc...........
.....nn.......tccccccccccccccc.........
....nnnn....mmmccccccccccccccccc.......
...nnnnnnmmmmmmBBBBccccccccccccccc.....
..nnnnn.mmmmmBBBBBBBBBBBccccccccccc....
..nnn....mmBBBBBBBBBBBBBBBBBBcccccc....
.nn.......BBBBBBBBBBBBBBBBBBBBBBTcc....
..........BBBBBBBBBBBBBBBBBBBBBBTT.....
..........BBBBBBBBBBBBBBBBBBBBBBTT.....
..........BBBBBBBBBBBBBBBBBBBBBB.TT....
...........BBB.BB.........BBB.BB..T....
...........BB..BB.........BB..BB.......
...........BB...BB........BB...B.......
..........BB....BB.......BB....BB......
..........B......B.......B......B......
.........BB......BB.....BB......BB.....
"""


def aldric(c, x, base):
    """Lord Aldric on his horse at the head of them, riding away into the fog: broad, a teal cloak, his lantern raised
    on its pole ahead of him, warm on his shoulders and on the road."""
    lines = ALDRIC.strip("\n").split("\n")
    x0, y0 = x - 14, base - len(lines) + 1
    c.pool(x0 + 4, base + 1, 28, P("fireGold"), 0.6, squash=0.36, steps=0)
    horse = hexc("#2A1E22")
    horse_lt = hexc("#5A3E34")
    legend = {"L": hexc("#1A1416"), "Y": P("fireGold"), "W": P("fireWhite"), "p": P("woodDark"),
              "k": hexc("#1A3A4C"), "f": hexc("#7A5040"), "c": P("banner"), "t": P("roofLight"), "a": P("roofDeep"),
              "m": horse_lt, "n": horse_lt, "B": horse, "T": hexc("#1E1618")}
    grid(c, ALDRIC, x0, y0, legend)
    # folds in the cloak, the lantern's light on the horse's chest and the rider's front
    for (dx, dy) in ((22, 16), (25, 17), (28, 18), (20, 14), (24, 19), (30, 19)):
        c.put(x0 + dx, y0 + dy, P("roofDeep"))
    for (dx, dy) in ((10, 19), (10, 20), (11, 18), (12, 17), (11, 21), (10, 21)):
        c.put(x0 + dx, y0 + dy, horse_lt)
    lx, ly = x0 + 1, y0 + 6
    c.halo(lx, ly, 14, P("fireOrange"), 0.28, steps=0)
    c.halo(lx, ly, 5, P("fireGold"), 0.4, steps=0)


# =====================================================================================================================
# 4. The circlet passed to the last of his blood. The one who lights the lamps.
#    The hall, warm: the hearth fire, the empty seat, the court in a half ring. In the middle a young lamplighter with a
#    wick pole, soot on one cheek, the gold circlet slipped over one eyebrow. Odile is holding out a folded strip of
#    paper. Two pictures: the Burgherr's and the Burgherrin's (the court's own portraits, ART-court.md).
# =====================================================================================================================

HEARTH = (69, 70)
CIRCLET = []


def slide4(form):
    c = Canvas(hexc("#140E0C"))
    hall_light = lit((128, 96, 80), [(HEARTH[0], HEARTH[1], 150, P("fireOrange"), 1.05),
                                     (HEARTH[0], HEARTH[1], 60, P("fireGold"), 0.6),
                                     (282, 44, 110, P("fireOrange"), 0.45)], steps=0)
    # the dark of the roof over the hall
    for y in range(H):
        for x in range(W):
            c.put(x, y, mix(hexc("#120C0A"), hexc("#2A1A12"), smooth(0, 120, y)))
    # the great hall behind them: its back wall, the banners, the beams, the dais
    blit(c, sprite("hallInterior"), 30, 16, shade=hall_light)
    # the floor coming toward us under the two in front
    for y in range(106, H):
        t = (y - 106) / 54.0
        for x in range(W):
            board = int((x - 160) / (6 + t * 10) + 1000)
            seam = abs(((x - 160) / (6 + t * 10)) % 1.0) < 0.08
            base = P("woodDark") if seam else (P("wood") if h2(board, 3, 401) > 0.4 else P("woodLight"))
            c.put(x, y, hall_light(x, y, base))
    # the hearth on the back wall with its fire
    blit(c, sprite("hearth"), HEARTH[0] - 13, 63, shade=hall_light)
    fire = """
.....w.....
...w.yw....
..wyyyy.w..
..yyyyyyy..
.oyyywyyyo.
.ooyyyyyoo.
eooooyoooe.
eeoooooooee
.eeeeeeeee.
"""
    grid(c, fire, HEARTH[0] - 6, 69, {"w": P("fireWhite"), "y": P("fireGold"), "o": P("fireOrange"),
                                      "e": P("ember")})
    c.halo(HEARTH[0], 74, 34, P("fireOrange"), 0.26, steps=0)
    c.halo(HEARTH[0], 74, 11, P("fireGold"), 0.3, steps=0)
    # the empty seat on the dais
    blit(c, sprite("throne"), 151, 59, shade=hall_light)
    # the court in a half ring at either side
    for name, x, base, frames, flip in (("brannock", 40, 103, 8, False), ("hesper", 86, 96, 7, False),
                                         ("pip", 238, 96, 6, True), ("tamsin", 252, 99, 7, True),
                                         ("bram", 268, 104, 8, True)):
        rows = sprite(name, 0, frames)
        blit(c, rows, x, base - len(rows), flip=flip, shade=hall_light)
    # push the hall back a little: a warm haze between it and the two in front
    for y in range(H):
        for x in range(W):
            c.c[y][x] = mix(c.c[y][x], hexc("#2C1A12"), 0.24)
    # the lamplighter's wick pole, held up beside the new lord, its little flame lit
    pole_x = 96
    for y in range(40, H):
        lean = (H - y) * 0.05
        c.put(pole_x + lean, y, P("woodDark"))
        c.put(pole_x + lean + 1, y, hall_light(pole_x, y, P("woodLight")))
    top_x = int(pole_x + (H - 40) * 0.05)
    hook = """
.mmm.
m...m
m...m
.m...
"""
    grid(c, hook, top_x - 1, 35, {"m": hexc("#4A3C3C")})
    c.put(top_x + 3, 39, P("fireGold"))
    c.put(top_x + 3, 38, P("fireWhite"))
    c.halo(top_x + 3, 39, 8, P("fireOrange"), 0.32, steps=0)
    # the two in front, half length: the new lord, and Odile holding out the folded strip of paper
    bust_light = lit((210, 176, 156), [(40, 80, 240, P("fireOrange"), 0.55)], steps=0)
    lord = extend_bust(lord_portrait(form), 44)
    blit(c, lord, 100, 72, shade=bust_light)
    rim(c, lord, 100, 72, hexc("#FFB070"), side=-1)
    # the circlet keeps its gold in the warm light: a bright band, a glint, a shadow under it
    band = {(x, y) for x, y, _ in CIRCLET}
    for x, y, px in CIRCLET:
        col = (px[0], px[1], px[2])
        top = (x, y - 1) not in band
        c.put(100 + x, 72 + y, P("fireGold") if top and x % 5 == 2 else (P("gold") if top else mix(col, P("gold"), 0.5)))
        if (x, y + 1) not in band and lord[y + 1][x][3] > 128:
            c.put(100 + x, 72 + y + 1, mix(c.get(100 + x, 72 + y + 1), P("ink"), 0.55))
    odile = extend_bust([tuple(r) for r in sprite("portraitOdile")], 40)
    blit(c, odile, 190, 76, flip=True, shade=lit((190, 160, 142), [(40, 80, 280, P("fireOrange"), 0.45)],
                                                  steps=0))
    paper_and_hand(c)
    return c


def extend_bust(rows, extra):
    """The portrait's chest carried on down to half length: each column keeps the colour of the portrait's last row, a
    little darker as it goes; the body flares toward the arms, a dark seam parts each arm from the chest, the outer
    edge keeps its ink line, and the lowest rows sink into the dark of the floor."""
    rows = [list(r) for r in rows]
    w = len(rows[0])
    last = rows[-1]
    xs = [x for x in range(w) if last[x][3] > 128 and tuple(last[x][:3]) != P("ink")]
    left, right = min(xs), max(xs)
    ink = P("ink")
    dark = hexc("#1A100C")
    out = rows
    for k in range(1, extra + 1):
        t = k / extra
        flare = int(round(6 * (1 - (1 - t) ** 2)))
        lo, hi = left - flare, right + flare
        sink = smooth(0.55, 1.0, t)
        row = []
        for x in range(w):
            if x < max(0, lo - 1) or x > min(w - 1, hi + 1):
                row.append((0, 0, 0, 0))
                continue
            if x in (lo - 1, hi + 1):
                col = ink
            else:
                src = last[min(right, max(left, x))]
                f = 1.0 - 0.006 * k
                col = (src[0] * f, src[1] * f, src[2] * f)
                if x <= lo + 5 or x >= hi - 5:
                    col = scale(col, 0.82)
                if x in (lo + 6, hi - 6):
                    col = scale(col, 0.55)
            col = mix(col, dark, sink * 0.85)
            row.append((int(col[0]), int(col[1]), int(col[2]), 255))
        out.append(row)
    # the canvas keeps its width: what flares past the portrait's edge is cut there
    return [tuple(r) for r in out]


def lord_portrait(form):
    """The court's portrait of the chosen lord (portraitKing or portraitLady) with the prologue's touches: the circlet
    slipped down over one eyebrow, and soot on the near cheek."""
    rows = [list(r) for r in sprite("portraitLady" if form == "lady" else "portraitKing")]
    band = {P("gold"), P("strawLight"), P("straw")}
    hair = P("soil") if form == "lady" else P("wood")
    skin = P("dawnRose")
    moved = []
    for y in range(12, 18):
        for x in range(4, 31):
            px = rows[y][x]
            if px[3] > 128 and tuple(px[:3]) in band:
                moved.append((x, y, px))
    for x, y, px in moved:
        rows[y][x] = (skin + (255,)) if x >= 23 else (hair + (255,))
    global CIRCLET
    CIRCLET = []
    for x, y, px in moved:
        shift = 0 if x < 13 else 1 if x < 22 else 2
        if 0 <= y + shift < 48:
            rows[y + shift][x] = px
            CIRCLET.append((x, y + shift, px))
    # an ink line under the slipped band where it crosses the brow
    for x in range(22, 30):
        y = 18
        if rows[y][x][3] > 128 and tuple(rows[y][x][:3]) == skin:
            rows[y][x] = P("tileLight") + (255,)
    # soot on the near cheek: a lamplighter's smudge
    soot = hexc("#6A5450")
    soot_lt = hexc("#9A7464")
    for (x, y) in ((19, 23), (20, 23), (20, 24), (21, 24)):
        if rows[y][x][3] > 128:
            rows[y][x] = soot + (255,)
    for (x, y) in ((18, 24), (21, 23), (19, 24), (22, 24), (20, 25)):
        if rows[y][x][3] > 128:
            rows[y][x] = soot_lt + (255,)
    return [tuple(r) for r in rows]


def rim(c, rows, x0, y0, colour, side=-1):
    """A thin warm rim of firelight on one side of a figure (side -1: its left edge)."""
    for y, row in enumerate(rows):
        xs = [x for x, px in enumerate(row) if px[3] > 128]
        if not xs:
            continue
        x = xs[0] if side < 0 else xs[-1]
        c.put(x0 + x, y0 + y, mix(c.get(x0 + x, y0 + y), colour, 0.45))


def paper_and_hand(c):
    """Odile's hand held out before her dark dress, a small strip of paper folded thick in her fingers, offered to the
    new lord for the circlet that is too big (she folds it into the band, STORY.md day 1)."""
    sleeve = hexc("#2E2028")
    sleeve_lt = hexc("#5A4040")
    skin = hexc("#D8A288")
    skin_dk = hexc("#A06A54")
    paper = hexc("#F6ECD4")
    paper_sh = hexc("#C0AE8C")
    art = """
..............ssss
...........sssssss
.ppppppppp.Ksssssss
ppPpPpPpPpkkkKsssss
pppppppppkkkkkksss.
.pPPPPPPpkkkkkKss..
.ppppppp.kKKKK.....
"""
    grid(c, art, 174, 123, {"p": paper, "P": paper_sh, "k": skin, "K": skin_dk, "s": sleeve})
    for (x, y) in ((187, 124), (190, 123), (193, 124)):
        c.put(x, y, sleeve_lt)


SLIDES = {"slidePrologue1": slide1, "slidePrologue2": slide2, "slidePrologue3": slide3,
          "slidePrologue4Lord": lambda: slide4("lord"), "slidePrologue4Lady": lambda: slide4("lady")}


def main():
    name = sys.argv[1]
    preview = None
    if "--preview" in sys.argv:
        preview = sys.argv[sys.argv.index("--preview") + 1]
    canvas = SLIDES[name]()
    os.makedirs(OUT, exist_ok=True)
    canvas.save(os.path.join(OUT, name + ".png"))
    if preview:
        os.makedirs(preview, exist_ok=True)
        canvas.save_preview(os.path.join(preview, name + ".png"), 3)
    print(name, "written")


if __name__ == "__main__":
    main()
