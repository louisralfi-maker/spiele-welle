#!/usr/bin/env python3
"""Lanternhold "First light" (docs/TITLE.md sections 1, 2, 3 and 5): the launch image, the loading lantern, the title
picture in five layers, its small sprites and the lettering LANTERNHOLD. Pure numpy + PIL, every pixel placed from
the game's palette (tools/palette.txt) or a stepped blend of the eternal light's gold over it; no randomness but
hashes of positions, so a run writes the same bytes every time.

  titleart.py art   [outdir]          the art into games/lanternhold/art/title (outside Resources: not in the atlas,
                                      not in the build until the wiring agent copies it)
  titleart.py proof [proofdir]        the seven proof pictures (2622x1206 PNG + 1311x603 JPEG)
  titleart.py all                     both

Round 2 (the director's verdict): the light holds the dark. The flame lights every surface facing it within its
reach in three warm steps (amber, rust, dim plum); the darkness is a front that stops exactly at the reach.

Screen colours, not albedo: the title is shown as it is, never through the world's light shader, so the night is
painted here with the world's night blues (ART-look2.md 2.1 and 2.2), the fire ramp and the warm firelight colours.
"""
import json
import math
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
GAME = os.path.dirname(HERE)
OUT = os.path.join(GAME, "art", "title")
PROOF = "/Users/enaayla/Desktop/Spiele-Welle/.claude/worktrees/game2-planning-354541/ci-out/director/first-light"

W, H = 520, 201            # the picture
WIN_X, WIN_W = 41, 437     # the window an iPhone 17 Pro shows (scale 6), centred in the picture
LX, LY = 259, 100          # the eternal light's flame: the window's centre (window px 218, 100)


def load_palette():
    pal = {}
    for line in open(os.path.join(HERE, "palette.txt")):
        p = line.split()
        if len(p) >= 2 and p[1].startswith("#") and not line.startswith("#"):
            pal[p[0]] = tuple(int(p[1][i:i + 2], 16) for i in (1, 3, 5))
    return pal


PAL = load_palette()
BONE = (0xE4, 0xD6, 0xB4)   # Theme.bone, the cards' type
DARK = "nightDeep"          # the launch colour, #0A1124


def C(n):
    return PAL[n] if isinstance(n, str) else n


def h(x, y, s=0):
    """A stable hash in [0, 1)."""
    v = (x * 374761393 + y * 668265263 + s * 2246822519) & 0xFFFFFFFF
    v = ((v ^ (v >> 13)) * 1274126177) & 0xFFFFFFFF
    return ((v ^ (v >> 16)) & 0xFFFFFF) / float(0x1000000)


class Layer:
    def __init__(self, w=W, hh=H):
        self.w, self.h = w, hh
        self.a = np.zeros((hh, w, 4), np.uint8)

    def px(self, x, y, n, alpha=255):
        if 0 <= x < self.w and 0 <= y < self.h:
            self.a[y, x, :3] = C(n)
            self.a[y, x, 3] = alpha

    def get(self, x, y):
        if 0 <= x < self.w and 0 <= y < self.h and self.a[y, x, 3]:
            return tuple(int(v) for v in self.a[y, x, :3])
        return None

    def rect(self, x0, y0, x1, y1, n):
        for y in range(max(0, y0), min(self.h, y1 + 1)):
            for x in range(max(0, x0), min(self.w, x1 + 1)):
                self.px(x, y, n)

    def mask(self, m, n):
        self.a[m, :3] = C(n)
        self.a[m, 3] = 255

    def is_(self, x, y, n):
        return self.get(x, y) == C(n)

    def image(self):
        return Image.fromarray(self.a)


def poly_mask(pts, w=W, hh=H):
    """Scanline fill at pixel centres."""
    m = np.zeros((hh, w), bool)
    n = len(pts)
    for y in range(hh):
        yc = y + 0.5
        xs = []
        for i in range(n):
            (x0, y0), (x1, y1) = pts[i], pts[(i + 1) % n]
            if (y0 <= yc < y1) or (y1 <= yc < y0):
                xs.append(x0 + (yc - y0) * (x1 - x0) / (y1 - y0))
        xs.sort()
        for i in range(0, len(xs) - 1, 2):
            a = int(math.ceil(xs[i] - 0.5))
            b = int(math.floor(xs[i + 1] - 0.5))
            if b >= a:
                m[y, max(0, a):min(w, b + 1)] = True
    return m


def profile(points, x0=0, x1=W):
    """A top line through hand-placed points, linear between them."""
    top = np.full(W, 10 ** 6, float)
    for (ax, ay), (bx, by) in zip(points, points[1:]):
        for x in range(max(x0, ax), min(x1, bx + 1)):
            t = 0 if bx == ax else (x - ax) / (bx - ax)
            top[x] = ay + (by - ay) * t
    return top


def declump(L, keep=()):
    """Every lone pixel (no 4-neighbour of its colour) takes its most common neighbour's colour."""
    a = L.a
    keep = {C(k) for k in keep}
    out = a.copy()
    for y in range(1, L.h - 1):
        for x in range(1, L.w - 1):
            if not a[y, x, 3]:
                continue
            c = tuple(int(v) for v in a[y, x, :3])
            if c in keep:
                continue
            nb = [a[y - 1, x], a[y + 1, x], a[y, x - 1], a[y, x + 1]]
            if any(int(q[3]) and tuple(int(v) for v in q[:3]) == c for q in nb):
                continue
            cnt = {}
            for q in nb:
                if q[3]:
                    k = tuple(int(v) for v in q[:3])
                    cnt[k] = cnt.get(k, 0) + 1
            if cnt:
                best = max(cnt.items(), key=lambda kv: kv[1])
                if best[1] >= 2 and best[0] not in keep:
                    out[y, x, :3] = best[0]
    L.a[:] = out


# Round 2 (the director, 15.11.2026): "the light holds the dark". The eternal light lights every surface that faces it
# within its reach, in three warm steps; the darkness is a front that stops exactly where the reach ends.
REACH = 112          # the light's reach in game px from the flame
BAND = (45, 80, REACH)   # amber, rust, dim plum


def dist(x, y):
    return math.hypot(x - LX, y - LY)


def band_of(x, y):
    d = dist(x, y)
    for i, b in enumerate(BAND):
        if d < b:
            return i
    return None


# ------------------------------------------------------------------------------------------------- layer 1: the sky
HORIZON = 150
SKY = [(0, "nightBlue"), (58, "nightSlate"), (106, "nightHaze")]      # three clean steps, no dither
STARS_BIG = [(176, 9), (402, 14)]                                         # 9 px stars
STARS_MID = [(70, 6), (238, 4), (316, 30), (452, 8), (214, 64), (384, 58), (118, 3)]   # 5 px crosses
STARS_SMALL = [(96, 20), (150, 8), (200, 22), (226, 40), (262, 14), (290, 6), (300, 50), (338, 12), (356, 40),
               (372, 24), (420, 36), (440, 22), (196, 48), (282, 34), (330, 70), (408, 86), (210, 90), (306, 84),
               (190, 76), (360, 96), (430, 64), (250, 56)]


def draw_sky():
    L = Layer()
    for y in range(H):
        n = SKY[0][1]
        for (y0, c) in SKY:
            if y >= y0:
                n = c
        for x in range(W):
            L.px(x, y, n)
    for (x, y) in STARS_SMALL:
        if dist(x, y) > 40:
            L.px(x, y, "moon" if y > 30 else "farPale")
    for (x, y) in STARS_MID:
        L.px(x, y, "foam")
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            L.px(x + dx, y + dy, "moon")
    for (x, y) in STARS_BIG:
        L.px(x, y, "foam")
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            L.px(x + dx, y + dy, "farPale")
            L.px(x + 2 * dx, y + 2 * dy, "moon")
    return L


# ------------------------------------------------------------------------------- layer 2: the lowland through the gap
def draw_far():
    L = Layer()
    # the lowland beyond the gap: lightest at the horizon (aerial), a step darker toward us
    for x in range(W):
        for y in range(HORIZON + 1, H):
            L.px(x, y, "mistDark" if y < HORIZON + 4 else ("far" if y < HORIZON + 12 else "nightHaze"))
    # a few low far hills on the plain, left of the dawn
    for (cx, w_, hh) in ((300, 46, 7), (338, 34, 5), (366, 26, 4)):
        for x in range(cx - w_ // 2, cx + w_ // 2 + 1):
            t = (x - cx) / (w_ / 2.0)
            top = int(round(HORIZON - hh * (1 - t * t)))
            for y in range(top, HORIZON + 1):
                L.px(x, y, "far")
            if t < 0:
                L.px(x, top, "mistDark")
    # the dawn on the horizon, in two steps, breaking up toward the left
    for x in range(372, W):
        if x >= 404:
            L.px(x, HORIZON, "dawnRose")
            if x >= 426:
                L.px(x, HORIZON - 1, "dusk")
        elif any(a <= x <= b for a, b in ((373, 377), (383, 390), (395, 402))):
            L.px(x, HORIZON, "dusk")
    for (x, y) in ((392, 155), (418, 153), (447, 156), (462, 153)):
        L.px(x, y, "emberDim")
    return L


# --------------------------------------------------------------- layer 3: the Weltmauer's rock, the gap, the darkness
FLOOR = 178
# the left cliff in granite columns; each column's top (y), rising out of the frame to the left
COLUMNS = [(0, 22, -9), (22, 15, -9), (37, 19, -9), (56, 14, -9), (70, 17, -9), (87, 13, -9), (100, 20, -9),
           (120, 10, -9), (130, 9, 10), (139, 8, 50), (147, 10, 62), (157, 10, 76), (167, 9, 90), (176, 13, 104)]
CLIFF_EDGE = 188
TOWN_PTS = [(300, 162), (316, 159), (334, 160), (350, 162), (366, 165), (382, 167), (398, 169), (414, 171),
            (432, 173), (452, 175), (476, 177), (520, 178)]


def right_edge(y):
    """The far shoulder of the Weltmauer on the right: out of the frame's top, its face leaning back."""
    return 436 + int(y * 0.22) + (2 if (y // 9) % 3 == 1 else 0)


def draw_rock():
    L = Layer()
    for x in range(W):
        for y in range(FLOOR, H):
            L.px(x, y, "nightBlue")
    # the left cliff: granite columns, cold sky light on their upper left, joints between them
    for i, (x0, w_, top) in enumerate(COLUMNS):
        slope = int(round((h(i, 1, 26) - 0.5) * 6))
        joints = [max(0, top)]
        y = max(0, top)
        k = 0
        while y < FLOOR:
            y += 30 + int(h(i, k, 22) * 30)
            joints.append(min(y, FLOOR))
            k += 1
        for b, (ya, yb) in enumerate(zip(joints, joints[1:])):
            jog = int(round((h(i, b, 23) - 0.5) * 4)) if b else 0
            a = x0 + jog
            cap = lambda xx: ya + (int(round(slope * (xx - x0) / float(max(1, w_ - 1)))) if (b == 0 and top >= 0) else 0)
            for xx in range(max(0, a), x0 + w_):
                for yy in range(max(0, cap(xx)), yb):
                    L.px(xx, yy, "nightBlue")
            for yy in range(ya, yb):
                if yy >= cap(a):
                    L.px(a, yy, "nightDeep")
                if yy >= cap(a + 1):
                    L.px(a + 1, yy, "nightSlate")
                if w_ > 12 and yy >= cap(a + 2):
                    L.px(a + 2, yy, "nightSlate")
            for xx in range(max(0, a), x0 + w_):
                if cap(xx) >= 0:
                    L.px(xx, cap(xx), "night2" if b == 0 else "nightSlate")
                if b:
                    L.px(xx, ya - 1, "nightDeep")
        if w_ >= 13:
            fx = x0 + w_ // 2 + int(h(i, 9, 24) * 3)
            fy = joints[1] if len(joints) > 2 else max(0, top) + 8
            for yy in range(fy, min(FLOOR, fy + 8 + int(h(i, 8, 25) * 10))):
                L.px(fx, yy, "nightDeep")
    for y in range(FLOOR):
        if L.get(CLIFF_EDGE - 1, y):
            L.px(CLIFF_EDGE - 1, y, "nightDeep")
    # the far shoulder on the right (further away: a step lighter)
    for y in range(0, FLOOR):
        e = right_edge(y)
        for x in range(e, W):
            L.px(x, y, "nightSlate")
        for x in range(e, min(W, e + 2)):
            L.px(x, y, "night2")                      # its face toward the sky's light
        for k, jx in enumerate((e + 9, e + 22, e + 38, e + 55)):
            if jx < W and h(k, y // 23, 41) < 0.8:
                L.px(jx, y, "nightBlue")          # a joint between two slabs
                L.px(jx + 1, y, "night2")         # the next slab's lit edge
                if (y // 23 + k) % 2:
                    L.px(jx + 2, y, "night2")
    # the near shoulder under the town, falling to the lowland
    rt = profile(TOWN_PTS)
    for x in range(296, W):
        t = int(round(rt[x]))
        for y in range(t, H):
            L.px(x, y, "nightBlue")
        L.px(x, t, "nightSlate")
    light(L, gaps=("nightDeep",), face_tint=False)
    darkness(L)
    return L


# ------------------------------------------------------------------------- the darkness: a front that stops at the light
DARK_CRESTS = ((-6, 40, 22), (16, 46, 20), (40, 54, 20), (64, 64, 19), (88, 76, 18), (108, 90, 16), (126, 104, 14),
               (140, 120, 12), (150, 138, 11), (156, 156, 10))
TENDRILS = [  # start (inside the bank), direction of reach (angle in degrees), length
    ((112, 104), -8, 34), ((128, 128), 4, 28), ((94, 86), -16, 40), ((140, 152), 10, 22), ((74, 68), -22, 44)]
EYES = [  # (x, y, size): 1 small, 2 medium, 3 large; most deep inside, two near the edge
    (34, 104, 3), (66, 128, 2), (50, 158, 1), (96, 146, 2), (20, 140, 1), (112, 118, 1), (80, 102, 1),
    (140, 132, 1), (150, 164, 2)]


def fray(x, y):
    a = math.atan2(y - LY, x - LX)
    return 1.0 + 7.0 * max(0.0, math.sin(a * 17.0)) ** 2 + 3.0 * max(0.0, math.sin(a * 7.0 + 1.0))


def darkness(L):
    m = np.zeros((H, W), bool)
    yy, xx = np.mgrid[:H, :W]
    for (cx, cy, r) in DARK_CRESTS:
        m |= (xx - cx) ** 2 + (yy - cy) ** 2 <= r * r
        m |= (xx <= cx + r) & (yy >= cy) & (xx >= 0)
    m &= xx < 190
    # tendrils, 3 px thick at the root, 1 at the tip, curling as they reach
    for (sx, sy), ang, ln in TENDRILS:
        for k in range(ln):
            a = math.radians(ang + 14.0 * math.sin(k / 7.0 + sx))
            px_ = sx + k * math.cos(a)
            py_ = sy + k * math.sin(a)
            th = 2 if k < ln * 0.4 else (1 if k < ln * 0.8 else 0)
            for dy in range(-th // 2 - (th % 2), th // 2 + 1):
                X, Y = int(round(px_)), int(round(py_)) + dy
                if 0 <= X < W and 0 <= Y < H:
                    m[Y, X] = True
    # the dark stops exactly where the light's reach ends, its edge frayed
    d = np.hypot(xx - LX, yy - LY)
    keep = np.zeros_like(m)
    for y in range(H):
        for x in range(0, 192):
            if m[y, x] and d[y, x] >= REACH + 2 + fray(x, y):
                keep[y, x] = True
    m = keep
    L.mask(m, "night0")
    # inner folds: arcs of the billows inside the bank, a step bluer, for volume
    for (cx, cy, r) in DARK_CRESTS:
        for (ox, oy, rr) in ((-4, 12, r - 4), (2, 26, r - 6)):
            for x in range(cx + ox - rr, cx + ox + rr + 1):
                dy = math.sqrt(max(0, rr * rr - (x - cx - ox) ** 2))
                y = int(round(cy + oy - dy))
                if 0 <= x < W and 0 <= y < H and m[y, x] and abs(x - cx - ox) < rr - 2:
                    L.px(x, y, "nightDeep")
    # the cold on the billows' tops: night1, with a few violet and teal clusters, never a full outline
    for x in range(0, 192):
        ys = np.where(m[:, x])[0]
        if not len(ys):
            continue
        y = ys[0]
        L.px(x, y, "night1")
        q = h(x // 3, 0, 31)
        if q < 0.18:
            L.px(x, y, "violetDim")
        elif q < 0.26 and y < 120:
            L.px(x, y, "tealDim")
    # the leading edge: rust where the light's reach meets it (outer px emberDim, the next crimsonDeep)
    for y in range(H):
        for x in range(0, 192):
            if not m[y, x]:
                continue
            dd = d[y, x]
            vx, vy = (LX - x) / dd, (LY - y) / dd
            q1 = (int(round(x + vx)), int(round(y + vy)))
            q2 = (int(round(x + 2 * vx)), int(round(y + 2 * vy)))
            if not m[q1[1], q1[0]]:
                L.px(x, y, "emberDim" if dd < REACH + 9 else "crimsonDeep")
            elif not m[q2[1], q2[0]] and dd < REACH + 9:
                L.px(x, y, "crimsonDeep")
    for (x, y, sz) in EYES:
        gap = 2 if sz < 3 else 3
        for ex in (x, x + gap + (1 if sz >= 2 else 0)):
            L.px(ex, y, "wraithWhite")
            if sz >= 2:
                L.px(ex + 1, y, "wraithWhite")
            if sz == 3:
                L.px(ex, y + 1, "wraithGlow"); L.px(ex + 1, y + 1, "wraithGlow")
    return m


# ---------------------------------------------------------------------------------------- the light on the world
WARM_EDGE = (("gold", "tileLight", "tile"),          # amber
             ("tileLight", "tile", "crimsonDeep"),   # rust
             ("tile", "plum", "plumDeep"))           # dim plum, the reach's last step
DARKER = {"gold": "tileLight", "tileLight": "tile", "tile": "crimsonDeep", "crimsonDeep": "plumDeep",
          "plum": "plumDeep", "plumDeep": None}
WINDOW_KEEP = ("fireGold", "fireOrange", "ember", "emberDim", "gold", "night0")


def light(L, gaps=("nightDeep",), face_tint=False, keep=WINDOW_KEEP, gap_reach=REACH):
    """Every surface that faces the flame within its reach takes the light in three warm steps by distance; the
    depth into the surface (1 to 3 px from the edge that faces the flame) steps it down."""
    a = L.a.copy()
    gapc = {C(g) for g in gaps}
    keepc = {C(k) for k in keep}
    shade = {C("nightBlue"), C("nightDeep")}
    for y in range(H):
        for x in range(W):
            if not a[y, x, 3]:
                continue
            c = tuple(int(v) for v in a[y, x, :3])
            if c in keepc or c in gapc:
                continue
            d = dist(x, y)
            if d >= REACH or d < 1:
                continue
            b = band_of(x, y)
            vx, vy = (LX - x) / d, (LY - y) / d
            depth = None
            for k in (1, 2, 3):
                qx, qy = int(round(x + vx * k)), int(round(y + vy * k))
                if not (0 <= qx < W and 0 <= qy < H) or not a[qy, qx, 3]:
                    depth = k
                    break
                if d < gap_reach and tuple(int(v) for v in a[qy, qx, :3]) in gapc:
                    # a joint: only the block's own top row catches the light, a step lower than an open edge
                    depth = 2 if k == 1 else None
                    break
            if depth is None:
                if face_tint and d < 34:
                    L.px(x, y, "woodDark" if c not in shade else "soilDark")
                continue
            col = WARM_EDGE[b][depth - 1]
            if col and c in shade:
                col = DARKER.get(col)
            if col:
                L.px(x, y, col)


# ----------------------------------------------------------------------------- layer 4: the wall, the keep, the town
GROUND = 178
WALK = 154
KEEP = (240, 278)          # 39 px wide, centre 259
FACE, RIM, SHADE, JOINT = "nightSlate", "night2", "nightBlue", "nightDeep"
WINDOWS = []


def lit(L, x, y, n):
    L.px(x, y, n)
    WINDOWS.append((x, y, n))


def courses(L, x0, y0, x1, y1, seed, course=5):
    """Stone in courses: a joint line every 4 rows, staggered vertical joints; the light pass finds the edges."""
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            L.px(x, y, FACE)
    for row, y in enumerate(range(y0 + course, y1 + 1, course)):
        near = dist((x0 + x1) // 2, y) < 46        # in the light's amber step the courses run whole and clean
        for x in range(x0, x1 + 1):
            if near or h(x // 4, y, seed) < 0.55:
                L.px(x, y, JOINT)
        off = (row * 5 + seed) % 9
        for x in range(x0 + off, x1, 9 + (row % 3)):
            if h(x, y, seed + 3) < (0.9 if near else 0.6):
                for yy in range(y - course + 1, y):
                    if yy >= y0:
                        L.px(x, yy, JOINT)


def merlons(L, x0, x1, ytop, w_=3, gap=2, phase=0):
    x = x0 + phase
    while x + w_ - 1 <= x1:
        for xx in range(x, x + w_):
            for yy in range(ytop, ytop + 3):
                L.px(xx, yy, FACE)
            L.px(xx, ytop, RIM)
        L.px(x + w_ - 1, ytop + 1, SHADE); L.px(x + w_ - 1, ytop + 2, SHADE)
        x += w_ + gap


def tower(L, x0, x1, ytop, seed, ybot=GROUND):
    courses(L, x0, ytop + 3, x1, ybot, seed)
    merlons(L, x0, x1, ytop)
    for y in range(ytop + 3, ybot + 1):
        L.px(x0, y, RIM)
        L.px(x1, y, SHADE)
    for x in range(x0, x1 + 1):
        L.px(x, ytop + 3, RIM)
    cx = (x0 + x1) / 2.0
    hgt = int((x1 - x0) * 0.95)
    for d in range(hgt):
        half = (x1 - x0 + 3) / 2.0 * (d / float(hgt))
        y = ytop + 2 - hgt + d
        a, b = int(round(cx - half)), int(round(cx + half))
        for x in range(a, b + 1):
            L.px(x, y, "roofDeep" if x <= cx else SHADE)
        L.px(a, y, "roofLight" if d > 1 else "roofDeep")
    L.px(int(round(cx)), ytop + 1 - hgt, RIM)


def house(L, x0, base, w_, wall_h, roof_h, lights, chimney=None, back=False):
    face, side, roof, ridge = ("nightSlate", "nightBlue", "nightBlue", "night2")
    if back:
        face, side, roof, ridge = ("nightBlue", "nightDeep", "nightDeep", "nightSlate")
    for y in range(base - wall_h, base + 1):
        for x in range(x0, x0 + w_):
            L.px(x, y, face)
        L.px(x0 + w_ - 1, y, side)
    for d in range(roof_h):
        y = base - wall_h - 1 - d
        a, b = x0 - 1 + d, x0 + w_ - d
        if a > b:
            break
        for x in range(a, b + 1):
            L.px(x, y, roof)
        L.px(a, y, ridge)
    if chimney is not None:
        cx = x0 + chimney
        for y in range(base - wall_h - roof_h - 2, base - wall_h - 1):
            L.px(cx, y, side); L.px(cx + 1, y, roof)
    for (dx, dy, kind) in lights:
        x, y = x0 + dx, base - wall_h + dy
        if kind == "w2":
            lit(L, x, y, "fireGold"); lit(L, x, y + 1, "fireOrange")
        elif kind == "w1":
            lit(L, x, y, "fireOrange")
        elif kind == "d":
            lit(L, x, y, "fireOrange"); lit(L, x, y + 1, "ember"); lit(L, x + 1, y, "ember"); lit(L, x + 1, y + 1, "ember")
        elif kind == "e":
            lit(L, x, y, "ember")


def town(L):
    rt = profile(TOWN_PTS)
    base = lambda x: int(round(rt[x])) + 1
    for (x, w_, wh, rh, li) in ((340, 6, 5, 4, [(2, 1, "w1")]), (358, 8, 5, 5, [(5, 2, "w1")]), (379, 6, 4, 3, []),
                                (397, 7, 4, 4, [(2, 1, "e")]), (421, 5, 3, 3, [(2, 1, "e")])):
        house(L, x, base(x) - 5, w_, wh, rh, li, back=True)
    cx, cb = 368, base(368) - 1
    for y in range(cb - 16, cb + 1):
        for x in range(cx, cx + 5):
            L.px(x, y, "nightSlate" if x < cx + 4 else "nightBlue")
    for d in range(7):
        y = cb - 17 - d
        a, b = cx + d // 3, cx + 4 - d // 3
        for x in range(a, b + 1):
            L.px(x, y, "nightBlue")
        L.px(a, y, "night2")
    for (x, y) in ((cx + 2, cb - 24), (cx + 2, cb - 25), (cx + 1, cb - 25), (cx + 3, cb - 25)):
        L.px(x, y, "night2")
    lit(L, cx + 2, cb - 13, "fireGold"); lit(L, cx + 2, cb - 12, "fireOrange")
    house(L, cx + 5, cb, 9, 6, 5, [(2, 2, "w2")], chimney=6)
    for (x, w_, wh, rh, li, ch) in ((336, 10, 7, 6, [(2, 2, "w2"), (6, 2, "w2"), (4, 5, "d")], 2),
                                    (349, 8, 6, 5, [(5, 2, "w2")], None),
                                    (359, 7, 8, 5, [(3, 2, "w2"), (3, 6, "w1")], 4),
                                    (384, 9, 6, 5, [(2, 2, "w1"), (6, 2, "w1")], 6),
                                    (395, 7, 5, 4, [(4, 2, "w1")], None),
                                    (405, 8, 5, 4, [(2, 2, "w1")], 2),
                                    (416, 6, 4, 4, [(3, 1, "e")], None),
                                    (427, 7, 4, 3, [(2, 1, "e"), (5, 1, "e")], 4),
                                    (439, 5, 3, 3, [(2, 1, "e")], None),
                                    (450, 6, 3, 3, [], None),
                                    (461, 4, 3, 2, [(1, 1, "e")], None)):
        house(L, x, base(x + w_ // 2), w_, wh, rh, li, chimney=ch)
    lit(L, 378, base(378) - 4, "fireGold")
    for y in range(base(378) - 3, base(378) + 1):
        L.px(378, y, "nightBlue")


def draw_castle():
    del WINDOWS[:]
    L = Layer()
    courses(L, 186, WALK, 334, GROUND, 5)
    for x in range(186, 335):
        L.px(x, WALK, RIM)
    merlons(L, 186, 334, WALK - 3, phase=1)
    # the gatehouse on the dark side: two towers with teal cones, a dark arch between
    tower(L, 194, 207, 136, 11)
    tower(L, 216, 229, 136, 12)
    courses(L, 208, 142, 215, GROUND, 13)
    for x in range(208, 216):
        L.px(x, 142, RIM)
    merlons(L, 208, 215, 139, phase=1)
    gate = poly_mask([(209.5, GROUND + 1), (209.5, 166), (211, 164.5), (212.5, 164.5), (214, 166), (214, GROUND + 1)])
    L.mask(gate, "nightDeep")
    for (x, y) in ((200, 148), (223, 148), (200, 160), (223, 160)):
        for k in range(3):
            L.px(x, y + k, "nightDeep")
    # the keep: one and a half times its old height above the wall, wider, a corbelled crown
    k0, k1 = KEEP
    courses(L, k0, 115, k1, GROUND, 21)
    for y in range(115, GROUND + 1):
        L.px(k0, y, RIM)
        L.px(k1, y, SHADE)
    for x in range(k0 - 2, k1 + 3):
        L.px(x, 112, RIM); L.px(x, 113, FACE); L.px(x, 114, JOINT)
    for x in range(k0, k1 + 1):
        L.px(x, 115, JOINT if (x - k0) % 3 == 2 else FACE)
        L.px(x, 116, JOINT if (x - k0) % 3 == 2 else SHADE)
    merlons(L, k0 - 2, k1 + 2, 109)
    # the beacon's plinth on the crown (the cage stands on it)
    for x in range(LX - 6, LX + 7):
        L.px(x, 108, RIM); L.px(x, 109, FACE)
    # the house banner: realm teal, our lantern in gold
    for y in range(120, 140):
        for x in range(256, 263):
            L.px(x, y, "roofDeep")
        L.px(256, y, "banner")
    for x in range(257, 262):
        L.px(x, 140, "roofDeep")
    L.px(258, 141, "roofDeep"); L.px(260, 141, "roofDeep")
    for (x, y) in ((259, 124), (258, 125), (260, 125), (259, 126), (258, 127), (260, 127), (259, 128)):
        L.px(x, y, "gold")
    for (x, y, on) in ((246, 122, True), (272, 122, False), (246, 140, True), (272, 146, True), (250, 162, False)):
        if on:
            lit(L, x, y, "fireGold"); lit(L, x, y + 1, "fireOrange")
        else:
            L.px(x, y, "night0"); L.px(x, y + 1, "night0")
    tower(L, 320, 333, 140, 31)
    lit(L, 326, 152, "fireGold"); lit(L, 326, 153, "fireOrange")
    town(L)
    light(L, gaps=(JOINT,), gap_reach=46)
    declump(L, keep=("fireGold", "fireOrange", "ember", "gold", "nightDeep", "roofLight", "night0", "tileLight",
                     "plum", "crimsonDeep", "tile"))
    return L


# ------------------------------------------------------------------------- layer 5: three fog bands and the near ledge
LEDGE = [(0, 174), (30, 172), (60, 177), (100, 182), (150, 186), (200, 188), (260, 189), (320, 188), (356, 185),
         (376, 181), (396, 183), (440, 185), (480, 181), (520, 178)]
FOG_BANDS = [  # (base y, amplitude, phase, rim, body)
    (169, 2.0, 0.0, "far", "nightHaze"),
    (176, 2.4, 1.7, "nightHaze", "night2"),
    (182, 2.6, 3.1, "night2", "nightSlate")]
FOG_WARM = {"far": ("tileLight", "tile", "crimsonDeep")}   # only the far band's rim, by the wall, catches it
POLE = (372, 182)      # the old banner pole of the house, foot on the ledge


def draw_fog():
    L = Layer()
    for (base, amp, ph, rim, body) in FOG_BANDS:
        for x in range(W):
            t = int(round(base - amp * abs(math.sin(x / 9.0 + ph)) - 1.2 * abs(math.sin(x / 4.0 + ph * 2))))
            for y in range(t, H):
                n = rim if y < t + 2 else body
                b = band_of(x, y)
                if b is not None and n in FOG_WARM and FOG_WARM[n][b]:
                    n = FOG_WARM[n][b]
                L.px(x, y, n)
    top = profile(LEDGE)
    for x in range(W):
        t = int(round(top[x]))
        for y in range(t, H):
            L.px(x, y, "nightDeep")
        if top[x] <= top[x - 1] if x else False:
            L.px(x, t, "nightBlue")
    # dry grass on the ledge: hand-set blades in tufts
    for (x, hgt, lean) in ((44, 5, 1), (47, 7, 0), (50, 4, -1), (118, 5, 1), (121, 3, 0), (232, 3, 0), (236, 5, 1),
                           (300, 4, -1), (352, 5, 1), (355, 8, 0), (358, 6, 1), (366, 4, -1), (384, 6, 0),
                           (388, 4, 1), (428, 5, -1), (431, 7, 0), (470, 4, 1)):
        b = int(round(top[x]))
        for k in range(hgt):
            L.px(x + (lean * k) // 3, b - 1 - k, "nightDeep")
        L.px(x + 1, b - 1, "nightDeep")
    # the old banner pole of the house, leaning, its banner torn: one clear silhouette against the lit lowland
    px0, py0 = POLE
    for k in range(46):
        x = px0 - k // 9
        L.px(x, py0 - k, "nightDeep")
        if k < 30:
            L.px(x + 1, py0 - k, "nightDeep")
    tx, ty = px0 - 5, py0 - 45
    for x in range(tx - 1, tx + 8):
        L.px(x, ty, "nightDeep")                    # the crossbar
    L.px(tx - 1, ty - 1, "nightDeep"); L.px(tx + 7, ty - 1, "nightDeep")
    for y in range(ty + 1, ty + 15):
        w_ = 6 if y < ty + 10 else (4 if y < ty + 13 else 2)
        for x in range(tx + 1, tx + 1 + w_):
            if not (y > ty + 9 and x == tx + 3):    # the tear between two tongues
                L.px(x, y, "nightDeep")
        L.px(tx + 1, y, "nightBlue" if y < ty + 12 else "nightDeep")   # the sky's light on its edge
    return L


# ---------------------------------------------------------------- the beacon: the house's lantern as an iron cage (13 x 18)
LW, LH = 13, 18
LFX, LFY = 6, 10          # the flame's centre inside the sprite
BEACON_XY = (LX - LFX, LY - LFY)     # its top left on the picture: (253, 90)

FLAME = {
    0: [(6, 14, "woodDark")],
    1: [(6, 14, "ember"), (6, 13, "fireOrange")],
    2: [(6, 14, "fireOrange"), (6, 13, "fireGold"), (6, 12, "fireOrange")],
    3: [(5, 14, "ember"), (6, 14, "fireGold"), (7, 14, "ember"), (6, 13, "fireWhite"), (6, 12, "fireGold"),
        (6, 11, "fireOrange")],
    4: [(5, 14, "fireOrange"), (6, 14, "fireGold"), (7, 14, "fireOrange"), (5, 13, "fireGold"), (6, 13, "fireWhite"),
        (7, 13, "fireGold"), (6, 12, "fireWhite"), (6, 11, "fireGold"), (6, 10, "fireOrange")],
    5: [(5, 14, "fireGold"), (6, 14, "fireWhite"), (7, 14, "fireGold"), (5, 13, "fireWhite"), (6, 13, "fireWhite"),
        (7, 13, "fireWhite"), (4, 13, "fireOrange"), (8, 13, "fireOrange"), (5, 12, "fireGold"), (6, 12, "fireWhite"),
        (7, 12, "fireGold"), (6, 11, "fireWhite"), (6, 10, "fireGold"), (6, 9, "fireOrange")],
    6: [(5, 14, "fireGold"), (6, 14, "fireWhite"), (7, 14, "fireGold"), (4, 13, "fireGold"), (5, 13, "fireWhite"),
        (6, 13, "fireWhite"), (7, 13, "fireWhite"), (8, 13, "fireGold"), (4, 12, "fireGold"), (5, 12, "fireWhite"),
        (6, 12, "fireWhite"), (7, 12, "fireWhite"), (8, 12, "fireGold"), (5, 11, "fireWhite"), (6, 11, "fireWhite"),
        (7, 11, "fireWhite"), (5, 10, "fireGold"), (6, 10, "fireWhite"), (7, 10, "fireGold"), (6, 9, "fireWhite"),
        (6, 8, "fireGold"), (6, 7, "fireOrange")],
}
FLAME[7] = [(x + (1 if y <= 9 else 0), y, c) for (x, y, c) in FLAME[6]]   # the tip leans: the flicker


def lantern(step):
    """step 0 unlit; 1 to 6 the fire catches and grows; 7 the full fire's flicker twin. An iron cage: finial, cap with
    a brass brim, two corner posts and two bars in front of the fire, a brass base ring."""
    L = Layer(LW, LH)
    iron, iron_lit, iron_dk = "nightBlue", "nightHaze", "nightDeep"
    brass, brass_lit = (("soilDark", "soil"), ("soil", "soilLight"), ("soil", "soilLight"),
                        ("soilLight", "straw"), ("soilLight", "straw"), ("straw", "gold"), ("straw", "gold"),
                        ("straw", "gold"))[step]
    L.px(6, 0, iron_lit); L.px(6, 1, iron)
    for x in (5, 6, 7):
        L.px(x, 2, iron)
    L.px(5, 2, iron_lit)
    for x in range(3, 10):
        L.px(x, 3, iron)
    L.px(3, 3, iron_lit); L.px(4, 3, iron_lit)
    for x in range(1, 12):
        L.px(x, 4, brass)
    L.px(1, 4, brass_lit); L.px(2, 4, brass_lit)
    back = ("night0", "night0", "night1", "emberDim", "emberDim", "ember", "ember", "ember")[step]
    for y in range(5, 15):
        for x in range(2, 11):
            L.px(x, y, back)
    if step >= 4:     # the cage's inside brightest round the fire
        for y in range(5, 15):
            for x in range(2, 11):
                if math.hypot(x - LFX, (y - 11.5) * 0.8) < (3.0 if step == 4 else 4.2):
                    L.px(x, y, "fireOrange")
    if step <= 2:
        for (x, y) in ((4, 6), (4, 7)):
            L.px(x, y, "nightSlate")
    for y in range(5, 15):
        L.px(1, y, iron_lit if step == 0 else brass_lit)     # the left post catches the sky (or the fire's brass)
        L.px(11, y, iron)
        L.px(3, y, iron_dk)                                   # two bars in front of the fire
        L.px(9, y, iron_dk)
    for x in range(1, 12):
        L.px(x, 15, brass)
    L.px(1, 15, brass_lit); L.px(2, 15, brass_lit)
    for x in range(2, 11):
        L.px(x, 16, iron_dk)
    for x in (2, 3, 9, 10):
        L.px(x, 17, iron)
    for (x, y, c) in FLAME[step]:
        L.px(x, y, c)
    for y in range(5, 15):          # the bars stand in front of the fire
        if step >= 3:
            L.px(3, y, iron_dk); L.px(9, y, iron_dk)
    return L


LANTERN_GLOW = {0: (), 1: (3,), 2: (5, 8), 3: (6, 11, 16), 4: (8, 14, 23), 5: (10, 17, 28), 6: (11, 20, 33),
                7: (12, 21, 34)}
GLOW_ALPHA = (0.28, 0.14, 0.06)


def glow_layer(radii, alphas=GLOW_ALPHA, cx=LX, cy=LY, w=W, hh=H, colour="fireOrange"):
    a = np.zeros((hh, w, 4), np.uint8)
    yy, xx = np.mgrid[:hh, :w]
    d = np.hypot(xx - cx, yy - cy)
    for r, al in sorted(zip(radii, alphas), key=lambda t: -t[0]):
        m = d < r
        a[m, :3] = C(colour)
        a[m, 3] = int(round(al * 255))
    return Image.fromarray(a)


def lantern_glow(step, size=81):
    c = size // 2
    rr = LANTERN_GLOW[step]
    return glow_layer(rr, GLOW_ALPHA[:len(rr)], cx=c, cy=c, w=size, hh=size)


# ---------------------------------------------------------------------------------------------- the small figures
def lord(frame):
    """7 x 13, feet on the bottom row: a small caped figure facing left (the dark), the house's lantern a warm point
    of two px on its staff. 0 stands, 1 lifts, 2 raised, 3 raised and flaring. A warm rim on his left (the flame)."""
    L = Layer(7, 13)
    L.px(3, 1, "nightDeep"); L.px(4, 1, "nightDeep")
    L.px(2, 2, "tileLight"); L.px(3, 2, "nightDeep"); L.px(4, 2, "nightDeep")      # the face, turned to the dark
    L.px(3, 0, "gold")                                                               # the circlet's glint
    rows = [(2, 4), (2, 5), (2, 5), (2, 5), (2, 6), (2, 6), (2, 6), (2, 6)]
    for i, (a, b) in enumerate(rows):
        y = 3 + i
        for x in range(a, b + 1):
            L.px(x, y, "roofDeep" if x < b else "nightDeep")
        L.px(a, y, "tile" if i < 5 else "crimsonDeep")
    L.px(3, 11, "nightDeep"); L.px(5, 11, "nightDeep"); L.px(3, 12, "nightDeep"); L.px(5, 12, "nightDeep")
    lantern_y = {0: 4, 1: 2, 2: 0, 3: 0}[frame]
    top = lantern_y - 1
    for y in range(max(0, top), 12 if frame == 0 else (10 if frame == 1 else 8)):
        L.px(1, y, "woodDark")
    L.px(0, lantern_y, "fireWhite" if frame == 3 else "fireGold")
    L.px(0, lantern_y + 1, "fireGold" if frame == 3 else "fireOrange")
    L.px(1, 6 if frame == 0 else (4 if frame == 1 else 3), "tileLight")              # the hand
    return L


LORD_LANTERN_Y = {0: 4, 1: 2, 2: 0, 3: 0}


def sentry(rim_side):
    """5 x 15: a spear silhouette on the wall walk, facing left; one warm px toward the flame."""
    L = Layer(5, 15)
    for (x, y) in ((2, 2), (3, 2), (1, 3), (2, 3), (3, 3), (4, 3)):
        L.px(x, y, "nightDeep")
    L.px(2, 4, "nightDeep"); L.px(3, 4, "nightDeep")
    for y in range(5, 12):
        for x in (2, 3, 4) if y < 11 else (2, 4):
            L.px(x, y, "nightDeep")
    L.px(2, 12, "nightDeep"); L.px(4, 12, "nightDeep")
    L.px(2, 13, "nightDeep"); L.px(4, 13, "nightDeep"); L.px(2, 14, "nightDeep"); L.px(4, 14, "nightDeep")
    for y in range(1, 15):
        L.px(0, y, "nightDeep")
    L.px(0, 0, "stonePale")
    if rim_side == "right":
        L.px(4, 3, "tileLight"); L.px(4, 6, "tile")
    else:
        L.px(1, 3, "tileLight"); L.px(2, 6, "tile")
    return L


LORD_POS = (290, WALK)
SENTRIES = [((234, WALK), "right"), ((306, WALK), "left")]


# ------------------------------------------------------------------------------------------- the lettering
GH = 30


def glyph(ch):
    def R(m, x0, y0, x1, y1):
        m[max(0, y0):y1 + 1, max(0, x0):x1 + 1] = True

    def P(m, pts):
        m |= poly_mask(pts, m.shape[1], m.shape[0])

    def SF(m, x0, x1, y_out, y_in):
        m[y_out, x0:x1 + 1] = True
        m[y_in, x0 + 1:x1] = True

    if ch == "L":
        m = np.zeros((GH, 15), bool)
        R(m, 2, 0, 5, 29); SF(m, 0, 7, 0, 1); R(m, 0, 27, 14, 29); R(m, 13, 22, 14, 26); R(m, 12, 25, 12, 26)
    elif ch == "A":
        m = np.zeros((GH, 19), bool)
        P(m, [(8.0, 0.0), (11.0, 0.0), (17.0, 27.5), (13.0, 27.5)])
        P(m, [(8.0, 0.0), (9.6, 0.0), (3.4, 27.5), (1.6, 27.5)])
        R(m, 5, 18, 13, 19)
        SF(m, 0, 5, 29, 28); SF(m, 11, 18, 29, 28)
    elif ch == "N":
        m = np.zeros((GH, 18), bool)
        R(m, 2, 0, 3, 29); R(m, 14, 0, 15, 29)
        P(m, [(2.0, 0.0), (6.5, 0.0), (16.0, 29.9), (11.5, 29.9)])
        SF(m, 0, 5, 0, 1); SF(m, 12, 17, 0, 1); SF(m, 0, 5, 29, 28)
    elif ch == "T":
        m = np.zeros((GH, 17), bool)
        R(m, 0, 0, 16, 2); R(m, 0, 3, 1, 5); R(m, 15, 3, 16, 5); R(m, 6, 0, 10, 29); SF(m, 4, 12, 29, 28)
    elif ch == "E":
        m = np.zeros((GH, 15), bool)
        R(m, 2, 0, 5, 29); R(m, 0, 0, 14, 2); R(m, 13, 3, 14, 5); R(m, 2, 13, 11, 15); R(m, 11, 12, 11, 16)
        R(m, 0, 27, 14, 29); R(m, 13, 23, 14, 26); R(m, 0, 28, 1, 29)
    elif ch == "R":
        m = np.zeros((GH, 18), bool)
        R(m, 2, 0, 5, 29); R(m, 0, 0, 12, 2); R(m, 2, 13, 12, 15)
        R(m, 12, 1, 14, 2); R(m, 12, 13, 14, 14); R(m, 13, 2, 16, 13); R(m, 15, 3, 16, 12)
        P(m, [(8.0, 15.0), (12.0, 15.0), (17.5, 27.6), (13.0, 27.6)])
        SF(m, 0, 7, 29, 28); SF(m, 12, 17, 29, 28)
    elif ch == "H":
        m = np.zeros((GH, 18), bool)
        R(m, 2, 0, 5, 29); R(m, 12, 0, 15, 29); R(m, 5, 13, 12, 15)
        SF(m, 0, 7, 0, 1); SF(m, 10, 17, 0, 1); SF(m, 0, 7, 29, 28); SF(m, 10, 17, 29, 28)
    elif ch == "O":
        m = np.zeros((GH, 18), bool)
        P(m, [(4, 0), (14, 0), (18, 4), (18, 26), (14, 30), (4, 30), (0, 26), (0, 4)])
        m &= ~poly_mask([(6, 2.5), (12, 2.5), (14, 5), (14, 25), (12, 27.5), (6, 27.5), (4, 25), (4, 5)], 18, GH)
    elif ch == "D":
        m = np.zeros((GH, 18), bool)
        P(m, [(2, 0), (12, 0), (18, 5), (18, 25), (12, 30), (2, 30)])
        m &= ~poly_mask([(6, 2.5), (11, 2.5), (14, 6), (14, 24), (11, 27.5), (6, 27.5)], 18, GH)
        SF(m, 0, 5, 0, 1); SF(m, 0, 5, 29, 28)
    # a little more weight: every stroke one px wider (round 2)
    w2 = np.zeros((GH, m.shape[1] + 1), bool)
    w2[:, :-1] |= m
    w2[:, 1:] |= m
    return w2


WORD = "LANTERNHOLD"
GAP = 3
LETTER_Y = 20
RULE_Y = LETTER_Y + GH + 3


def lettering_layout():
    gl = [glyph(c) for c in WORD]
    total = sum(g.shape[1] for g in gl) + GAP * (len(gl) - 1)
    x = LX - total // 2
    boxes = []
    for g in gl:
        boxes.append((x, LETTER_Y, g.shape[1], GH))
        x += g.shape[1] + GAP
    return gl, boxes


def lettering(state):
    gl, boxes = lettering_layout()
    L = Layer()
    for g, (bx, by, bw, bh) in zip(gl, boxes):
        m = np.zeros((H, W), bool)
        m[by:by + bh, bx:bx + bw] = g
        o = np.zeros_like(m)
        o[1:, :] |= m[:-1, :]; o[:-1, :] |= m[1:, :]; o[:, 1:] |= m[:, :-1]; o[:, :-1] |= m[:, 1:]
        o &= ~m
        L.mask(o, "nightDeep")
        edge = m & ~(np.roll(m, 1, 0) & np.roll(m, -1, 0) & np.roll(m, 1, 1) & np.roll(m, -1, 1))
        inner = m & ~edge
        if state == "unlit":         # close to the sky: iron in the sky's own blue, the brass a breath lighter
            L.mask(inner, "nightBlue")
            L.mask(edge, "nightSlate")
            continue
        near = 1.0 - min(1.0, abs(bx + bw / 2.0 - LX) / 125.0)     # 1 at the centre letter, ~0 at the ends
        L.mask(inner, "stoneDark")
        ys, xs = np.where(inner)
        for y, x in zip(ys, xs):
            if y - by > bh - 6 and near > 0.35:
                L.px(x, y, "woodDark")
        ys, xs = np.where(edge)
        for y, x in zip(ys, xs):
            nx = int(not m[y, x + 1]) - int(not m[y, x - 1])
            ny = int(not m[y + 1, x]) - int(not m[y - 1, x])
            nl = math.hypot(nx, ny)
            dx, dy = LX - x, LY - y
            f = 0 if nl == 0 else (nx * dx + ny * dy) / (nl * math.hypot(dx, dy))
            if f > 0.5:
                c = "fireGold" if near > 0.72 else ("gold" if near > 0.38 else "straw")
            elif f > 0.1:
                c = "gold" if near > 0.72 else ("straw" if near > 0.3 else "soilLight")
            elif f > -0.35:
                c = "soilLight" if near > 0.3 else "soil"
            else:
                c = "soil" if near > 0.3 else "soilDark"
            L.px(x, y, c)
    rule(L, boxes, state)
    return L, boxes


def rule(L, boxes, state):
    x0 = boxes[1][0] + 2
    x1 = boxes[-2][0] + boxes[-2][2] - 3
    for x in range(x0, x1 + 1):
        if abs(x - LX) <= 6:
            continue
        near = 1.0 - min(1.0, abs(x - LX) / 120.0)
        L.px(x, RULE_Y - 1, "nightDeep")
        L.px(x, RULE_Y, "nightBlue" if state == "unlit" else "stoneDark")
        L.px(x, RULE_Y + 1, "nightSlate" if state == "unlit" else ("gold" if near > 0.6 else ("straw" if near > 0.3
                                                                                               else "soilLight")))
        L.px(x, RULE_Y + 2, "nightDeep")
    for (x, y) in ((x0 - 1, RULE_Y), (x0 - 1, RULE_Y + 1), (x1 + 1, RULE_Y), (x1 + 1, RULE_Y + 1)):
        L.px(x, y, "nightDeep")
    for dy in range(-5, 6):
        for dx in range(-5, 6):
            r = abs(dx) + abs(dy)
            x, y = LX + dx, RULE_Y + dy
            if r == 5:
                L.px(x, y, "nightDeep")
            elif r == 4:
                L.px(x, y, "nightSlate" if state == "unlit" else
                     ("fireGold" if dy > 0 else ("gold" if dy == 0 else "straw")))
            elif r <= 3:
                L.px(x, y, "nightBlue" if state == "unlit" else "stoneDark")
    if state == "lit":
        L.px(LX, RULE_Y, "fireGold")
        for (dx, dy) in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            L.px(LX + dx, RULE_Y + dy, "fireOrange")
    else:
        L.px(LX, RULE_Y, "nightSlate")


# ------------------------------------------------------------------------------------------------- composing
def over(dst, src, dx=0, dy=0):
    tmp = Image.new("RGBA", dst.size, (0, 0, 0, 0))
    tmp.paste(src, (dx, dy))
    return Image.alpha_composite(dst, tmp)


def front_merlons(castle):
    a = np.array(castle)
    f = np.zeros_like(a)
    f[WALK - 3:WALK + 1, 186:335] = a[WALK - 3:WALK + 1, 186:335]
    for (x0, x1) in ((193, 231), (KEEP[0] - 3, KEEP[1] + 4), (319, 335)):
        f[:, x0:x1] = 0
    return Image.fromarray(f)


def lord_light(frame):
    """One small step of glow round his two warm px: the four neighbours in ember at 45 %."""
    a = np.zeros((13, 7, 4), np.uint8)
    y = LORD_LANTERN_Y[frame]
    for (x, yy) in ((1, y), (1, y + 1), (0, y - 1), (0, y + 2)) + (((1, y - 1), (1, y + 2)) if frame == 3 else ()):
        if 0 <= yy < 13:
            a[yy, x, :3] = C("ember")
            a[yy, x, 3] = 115
    return Image.fromarray(a)


def scene(layers, sprites, letters=None, lord_frame=0, off=None):
    off = off or {}
    o = lambda k: off.get(k, 0)
    img = Image.new("RGBA", (W, H), C(DARK) + (255,))
    for name in ("sky", "far", "rock"):
        img = over(img, layers[name], o(name))
    img = over(img, layers["castle"], o("castle"))
    img = over(img, sprites["lantern6"].image(), o("castle") + BEACON_XY[0], BEACON_XY[1])
    for (pos, side) in SENTRIES:
        s = sprites["sentryA" if side == "right" else "sentryB"]
        img = over(img, s.image(), o("castle") + pos[0] - s.w // 2, pos[1] - s.h + 1)
    lf = sprites["lord%d" % lord_frame]
    lx0, ly0 = LORD_POS[0] - lf.w // 2 + o("castle"), LORD_POS[1] - lf.h + 1
    img = over(img, lord_light(lord_frame), lx0, ly0)
    img = over(img, lf.image(), lx0, ly0)
    img = over(img, layers["front"], o("castle"))
    img = over(img, layers["fog"], o("fog"))
    if letters is not None:
        img = over(img, letters)
    return img


def build_all():
    layers = {"sky": draw_sky().image(), "far": draw_far().image(), "rock": draw_rock().image(),
              "castle": draw_castle().image(), "fog": draw_fog().image()}
    layers["front"] = front_merlons(layers["castle"])
    sprites = {"lantern%d" % i: lantern(i) for i in range(8)}
    for f in range(4):
        sprites["lord%d" % f] = lord(f)
    sprites["sentryA"] = sentry("right")
    sprites["sentryB"] = sentry("left")
    unlit, boxes = lettering("unlit")
    litl, _ = lettering("lit")
    return layers, sprites, unlit.image(), litl.image(), boxes


LAYER_FILES = {"sky": "title1Sky", "far": "title2Far", "rock": "title3Rock", "castle": "title4Castle",
               "front": "title4Parapet", "fog": "title5Fog"}
DRIFT = {"sky": -3, "far": -2, "rock": -1, "castle": 0, "fog": 8}   # game px at the sway's peak; the castle never moves


def write_art(outdir=OUT):
    os.makedirs(outdir, exist_ok=True)
    layers, sprites, unlit, litl, boxes = build_all()
    for k, n in LAYER_FILES.items():
        layers[k].save(os.path.join(outdir, n + ".png"))
    scene(layers, sprites, letters=litl).convert("RGB").save(os.path.join(outdir, "titleComposite.png"))
    x0, x1 = boxes[0][0] - 1, boxes[-1][0] + boxes[-1][2] + 1
    crop = (x0, LETTER_Y - 1, x1, RULE_Y + 6)
    unlit.crop(crop).save(os.path.join(outdir, "letteringUnlit.png"))
    litl.crop(crop).save(os.path.join(outdir, "letteringLit.png"))
    for i in range(8):
        sprites["lantern%d" % i].image().save(os.path.join(outdir, "lantern%d.png" % i))
        if i:
            lantern_glow(i).save(os.path.join(outdir, "lanternGlow%d.png" % i))
    for f in range(4):
        sprites["lord%d" % f].image().save(os.path.join(outdir, "titleLord%d.png" % f))
        lord_light(f).save(os.path.join(outdir, "titleLordLight%d.png" % f))
    sprites["sentryA"].image().save(os.path.join(outdir, "titleSentryA.png"))
    sprites["sentryB"].image().save(os.path.join(outdir, "titleSentryB.png"))
    li = Image.new("RGBA", (LW, 21), (0, 0, 0, 0))     # flame (6, 10) at the centre of 13 x 21
    li.paste(sprites["lantern0"].image(), (0, 0))
    li.save(os.path.join(outdir, "launchLantern.png"))
    meta = {
        "picture": [W, H], "window": [WIN_X, 0, WIN_W, H], "eternalLight": [LX, LY], "reach": REACH,
        "bands": BAND, "launchColour": "#%02X%02X%02X" % C(DARK),
        "beacon": {"topLeft": list(BEACON_XY), "size": [LW, LH], "flame": [LFX, LFY]},
        "lettering": {"box": [crop[0], crop[1], crop[2] - crop[0], crop[3] - crop[1]], "order": WORD,
                      "letters": [[b[0] - 1, b[1] - 1, b[2] + 2, b[3] + 2] for b in boxes]},
        "lanternGlow": {"radii": LANTERN_GLOW, "alpha": GLOW_ALPHA, "size": 81, "loadingOnly": True},
        "lord": {"feet": list(LORD_POS), "size": [7, 13], "lanternPixel": {"x": 0, "y": LORD_LANTERN_Y}},
        "sentries": [{"feet": list(p), "size": [5, 15], "sprite": "titleSentryA" if s == "right" else "titleSentryB"}
                     for p, s in SENTRIES],
        "drift": DRIFT, "windows": WINDOWS,
    }
    with open(os.path.join(outdir, "title.json"), "w") as f:
        json.dump(meta, f, indent=1)
    for old in ("titleGlow.png", "titleGlowFlicker.png"):
        p = os.path.join(outdir, old)
        if os.path.exists(p):
            os.remove(p)
    return layers, sprites, unlit, litl, boxes


# --------------------------------------------------------------------------------------------- proof pictures
def big6(win):
    return win.resize((WIN_W * 6, H * 6), Image.NEAREST).convert("RGBA")


def save_proof(big, name, proofdir):
    big.convert("RGB").save(os.path.join(proofdir, name + ".png"))
    big.convert("RGB").resize((1311, 603), Image.NEAREST).save(os.path.join(proofdir, name + ".jpg"), quality=88)


def window_of(img):
    return img.crop((WIN_X, 0, WIN_X + WIN_W, H))


def lantern_screen(step):
    s = Image.new("RGBA", (WIN_W, H), C(DARK) + (255,))
    cx = LX - WIN_X
    if step:
        s = over(s, lantern_glow(step), cx - 40, LY - 40)
    return over(s, lantern(step).image(), cx - LFX, LY - LFY)


RING = (5, 10, 15)
RING_DARK = (0.34, 0.60, 0.82)


def reveal(win, R):
    """Inside R the picture; three stepped rings of darkness beyond (5 px each); the night past them."""
    p = np.array(win.convert("RGB")).astype(float)
    d0 = np.array(C(DARK), float)
    yy, xx = np.mgrid[:H, :WIN_W]
    d = np.hypot(xx - (LX - WIN_X), yy - LY)
    k = np.full(d.shape, 1.0)
    for r, kk in reversed(list(zip(RING, RING_DARK))):
        k = np.where(d < R + r, kk, k)
    k = np.where(d < R, 0.0, k)
    out = p * (1 - k[..., None]) + d0 * k[..., None]
    return Image.fromarray(out.round().astype(np.uint8)).convert("RGBA")


def touch_line(big):
    font = ImageFont.truetype(os.path.join(GAME, "Resources", "Fonts", "IMFeENrm28P.ttf"), 54)
    layer = Image.new("RGBA", big.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    text = "Touch to begin"
    bb = d.textbbox((0, 0), text, font=font)
    d.text(((big.width - (bb[2] - bb[0])) // 2, big.height - 92), text, font=font, fill=BONE + (178,))
    return Image.alpha_composite(big, layer)


def gear(big):
    import io
    import subprocess
    try:
        raw = subprocess.run(["git", "show", "claude/lh-hudart:games/lanternhold/Resources/Art/hudGear.png"],
                             cwd=GAME, capture_output=True, check=True).stdout
        g = Image.open(io.BytesIO(raw)).convert("RGBA")
    except Exception:
        return big
    g = g.resize((g.width * 6, g.height * 6), Image.NEAREST)
    return over(big, g, big.width - g.width - 54, 42)


def write_proofs(proofdir=PROOF, sfx="-r2", which="title"):
    os.makedirs(proofdir, exist_ok=True)
    layers, sprites, unlit, litl, boxes = build_all()
    if which in ("loading", "all"):
        save_proof(big6(lantern_screen(0)), "01-launch" + sfx, proofdir)
        save_proof(big6(lantern_screen(2)), "02-loading-small" + sfx, proofdir)
        save_proof(big6(lantern_screen(6)), "03-loading-full" + sfx, proofdir)
    pic_unlit = window_of(scene(layers, sprites, letters=unlit))
    save_proof(big6(reveal(pic_unlit, 110)), "04-glow-half" + sfx, proofdir)
    save_proof(big6(pic_unlit), "05-title-unlit" + sfx, proofdir)
    pic_lit = window_of(scene(layers, sprites, letters=litl))
    save_proof(gear(touch_line(big6(pic_lit))), "06-title" + sfx, proofdir)
    pic_raise = window_of(scene(layers, sprites, letters=litl, lord_frame=3))
    save_proof(gear(big6(pic_raise)), "07-lord-raises" + sfx, proofdir)
    ph = pic_lit.resize((874, 402), Image.NEAREST).convert("RGB")
    ph.save(os.path.join(proofdir, "_phone-874" + sfx + ".png"))
    ph.save(os.path.join(proofdir, "_phone-874" + sfx + ".jpg"), quality=88)
    pic_lit.crop((120, 60, 300, 170)).resize((720, 440), Image.NEAREST).convert("RGB").save(
        os.path.join(proofdir, "_zoom-keep" + sfx + ".png"))


if __name__ == "__main__":
    what = sys.argv[1] if len(sys.argv) > 1 else "all"
    if what in ("art", "all"):
        write_art()
    if what in ("proof", "all"):
        write_proofs(which=sys.argv[2] if len(sys.argv) > 2 else "title")
