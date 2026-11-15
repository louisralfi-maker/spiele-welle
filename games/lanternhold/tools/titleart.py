#!/usr/bin/env python3
"""Lanternhold "First light" (docs/TITLE.md sections 1, 2, 3 and 5): the launch image, the loading lantern, the title
picture in five layers, its small sprites and the lettering LANTERNHOLD. Pure numpy + PIL, every pixel placed from
the game's palette (tools/palette.txt) or a stepped blend of the eternal light's gold over it; no randomness but
hashes of positions, so a run writes the same bytes every time.

  titleart.py art   [outdir]          the art into games/lanternhold/art/title (outside Resources: not in the atlas,
                                      not in the build until the wiring agent copies it)
  titleart.py proof [proofdir]        the seven proof pictures (2622x1206 PNG + 1311x603 JPEG)
  titleart.py all                     both

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


# ------------------------------------------------------------------------------------------------- layer 1: the sky
HORIZON = 146
BAYER = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]
SKY_STEP = 12    # rows of ordered steps between two sky colours (2/16 .. 14/16)
BRIGHT_STARS = [(64, 12), (176, 8), (338, 6), (452, 18), (500, 40), (116, 58)]


SKY_DOMES = [("nightSlate", 470, 150, 0.10), ("night2", 300, 80, 0.12), ("nightHaze", 170, 34, 0.16)]
DAWN = (520, 146)


def sky_colour(x, y):
    """The night sky lightens toward the dawn on the right horizon in nested domes (ellipses round the dawn point):
    curved edges, each crossed in ordered steps, so there is no straight band anywhere. The Gloom's side, left, keeps
    the deepest blue."""
    name = "nightBlue"
    for (n, rx, ry, soft) in SKY_DOMES:
        e = math.hypot((x - DAWN[0]) / float(rx), (y - DAWN[1]) / float(ry))
        if e < 1.0 - soft:
            name = n
        elif e < 1.0:
            level = int(16 * (1.0 - e) / soft)          # 0..15 across the edge
            if BAYER[y % 4][x % 4] < level:
                name = n
    return name


def teeth_profile():
    pts = [(0, 30), (7, 9), (13, 20), (19, 12), (27, 34), (36, 17), (44, 26), (51, 22), (60, 44), (70, 30),
           (78, 38), (88, 26), (99, 52), (110, 43), (118, 49), (128, 62), (139, 56), (151, 76), (163, 68),
           (174, 86), (186, 80), (199, 102), (212, 96), (226, 118), (238, 128), (244, 140)]
    rpts = [(276, 140), (284, 126), (296, 114), (306, 118), (318, 98), (330, 104), (342, 84), (353, 92),
            (364, 74), (375, 82), (383, 70), (392, 76), (402, 60), (413, 72), (421, 66), (432, 88), (444, 96),
            (452, 110), (462, 118), (474, 132), (488, 146), (500, 160)]
    return np.minimum(profile(pts), profile(rpts))


def draw_sky():
    L = Layer()
    for y in range(H):
        for x in range(W):
            L.px(x, y, sky_colour(x, y))
    # stars: few and small, thinning toward the horizon, on a hash grid so no two touch; none in the halo
    for gy in range(0, 110, 7):
        for gx in range(0, W, 7):
            if h(gx, gy, 7) > 0.24 * (1.0 - gy / 120.0) ** 1.5:
                continue
            x = gx + int(h(gx, gy, 8) * 5)
            y = gy + int(h(gx, gy, 9) * 5)
            if math.hypot(x - LX, y - LY) < 48:
                continue
            L.px(x, y, "farPale" if h(gx, gy, 10) < 0.3 and y < 60 else "moon")
    for (x, y) in BRIGHT_STARS:     # six bright ones, set by hand: a small cross each
        L.px(x, y, "foam")
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            L.px(x + dx, y + dy, "moon")
    # the dawn: a thin line on the far horizon, right, breaking up in steps toward the left
    for x in range(380, W):
        if x >= 470:
            L.px(x, HORIZON, "dawnRose")
            L.px(x, HORIZON - 1, "dusk")
            if x >= 492:
                L.px(x, HORIZON - 2, "dusk")
        elif x >= 432:
            L.px(x, HORIZON, "dusk")
            if x >= 456:
                L.px(x, HORIZON - 1, "dusk")
        elif any(a <= x <= b for a, b in ((384, 387), (393, 399), (405, 413), (418, 428))):
            L.px(x, HORIZON, "dusk")
    for x in range(W):
        for y in range(HORIZON + 1, H):
            L.px(x, y, "nightHaze")
    # the Weltmauer's black teeth
    top = teeth_profile()
    for x in range(W):
        if top[x] > H:
            continue
        ti = int(round(top[x]))
        for y in range(max(0, ti), H):
            L.px(x, y, "nightDeep")
        if x > 0 and top[x - 1] < H and top[x] - top[x - 1] >= 0.5 and ti < 150:
            L.px(x, ti, "nightBlue")
            if top[x] - top[x - 1] >= 1.2:
                L.px(x, ti + 1, "nightBlue")
    # no declump here: the sky's ordered steps are lone pixels on purpose
    return L


# ----------------------------------------------------------------------------------------- layer 2: the far peaks
FAR_PTS = [(150, 150), (166, 140), (178, 132), (190, 126), (200, 131), (214, 120), (226, 126), (238, 116),
           (252, 122), (264, 112), (276, 118), (290, 106), (302, 112), (314, 102), (326, 110), (338, 100),
           (350, 106), (362, 98), (374, 108), (386, 114), (396, 124), (406, 132), (418, 140), (430, 146)]


def draw_far():
    L = Layer()
    top = profile(FAR_PTS, 150, 431)
    pts = FAR_PTS
    peaks = [p for i, p in enumerate(pts[1:-1], 1) if p[1] < pts[i - 1][1] and p[1] < pts[i + 1][1]]
    for x in range(150, 431):
        for y in range(int(round(top[x])), H):
            L.px(x, y, "nightSlate")
    # facets: from every peak a lit slope down to the left (the sky's own light), shade to the right
    for (px_, py_) in peaks:
        for y in range(py_, min(H, py_ + 40)):
            d = y - py_
            xl = px_ - d * 1.25
            xr = px_ - d * 0.25 - (2 if d > 6 else 0)
            for x in range(int(xl), int(xr) + 1):
                if 150 <= x <= 430 and y >= top[x]:
                    L.px(x, y, "night2")
            if px_ in (314, 338, 362) and d < 5:   # snow only on the three highest, on their lit side
                for x in range(int(px_ - d * 1.25), px_ + (1 if d < 2 else 0)):
                    if 150 <= x <= 430 and y >= top[x]:
                        L.px(x, y, "moon" if d < 2 else "far")
    for x in range(151, 431):
        t = int(round(top[x]))
        if top[x] - top[x - 1] <= -0.5 and L.is_(x, t, "nightSlate"):
            L.px(x, t, "night2")
    # mist at the ranges' foot: flat scalloped levels
    for x in range(140, W):
        s = 2.6 * abs(math.sin(x / 8.0)) + 1.6 * abs(math.sin(x / 3.7 + 1.0))
        mt = int(round(138 - s))
        for y in range(mt, H):
            L.px(x, y, "nightHaze" if y < mt + 2 else "night2")
    # the inner lands beyond the horizon: the plain, and the far lights of other villages
    for x in range(380, W):
        for y in range(HORIZON + 1, H):
            L.px(x, y, "night2" if (y - HORIZON) % 7 == 3 else "nightSlate")
        L.px(x, HORIZON + 1, "night2")
    for (x, y) in ((446, 149), (471, 151), (497, 149), (509, 153)):
        L.px(x, y, "emberDim")
    declump(L, keep=("moon", "far", "emberDim"))
    return L


# --------------------------------------------------------------------------- layer 3: the gorge's rock and the Throat
CLIFF_EDGE = 188      # the Throat's granite ends here in a sheer face; the wall starts against it
FLOOR = 178
SHOULDER_PTS = [(300, 150), (316, 147), (334, 148), (350, 150), (366, 153), (382, 156), (398, 159), (414, 162),
                (432, 165), (452, 168), (476, 171), (520, 174)]


def crest(x):
    """The granite's skyline over the Throat: high at the far left, a saddle, highest at the cleft."""
    pts = [(0, 74), (40, 82), (86, 102), (120, 88), (160, 62), (176, 56), (188, 60)]
    for (ax, ay), (bx, by) in zip(pts, pts[1:]):
        if ax <= x <= bx:
            t = (x - ax) / float(bx - ax)
            t = t * t * (3 - 2 * t)
            return ay + (by - ay) * t
    return 60


def slabs():
    """Granite in slabs (ART-look2.md 14.2): straight joints that jog where a slab ends; each slab has its own top."""
    widths = [12, 9, 15, 11, 8, 14, 10, 13, 9, 16, 12, 10, 14, 11, 9, 13]
    out, x = [], 0
    for i, w_ in enumerate(widths):
        if x > CLIFF_EDGE:
            break
        w_ = min(w_, CLIFF_EDGE + 1 - x)
        top = int(round(crest(x + w_ / 2.0) + (h(i, 0, 21) - 0.5) * 16))
        out.append((x, w_, top, i))
        x += w_
    return out


def draw_rock():
    L = Layer()
    for x in range(W):
        for y in range(FLOOR, H):
            L.px(x, y, "nightBlue")
    for (x0, w_, top, i) in slabs():
        recessed = i % 3 == 1
        lit_w = 1 if recessed else 2
        body = "nightBlue"
        # joints down the slab, 14 to 30 px apart, each block jogging its left joint by -2..2
        slope = int(round((h(i, 1, 26) - 0.5) * 7))     # the cap leans: -3..3 px across the slab
        joints = [top]
        y = top
        k = 0
        while y < FLOOR:
            y += 30 + int(h(i, k, 22) * 34)
            joints.append(min(y, FLOOR))
            k += 1
        for b, (ya, yb) in enumerate(zip(joints, joints[1:])):
            jog = int(round((h(i, b, 23) - 0.5) * 4)) if b else 0
            a = x0 + jog
            cap = lambda xx: ya + (int(round(slope * (xx - x0) / float(max(1, w_ - 1)))) if b == 0 else 0)
            for xx in range(max(0, a), x0 + w_):
                for yy in range(cap(xx), yb):
                    L.px(xx, yy, body)
            for yy in range(ya, yb):
                if yy >= cap(a):
                    L.px(a, yy, "nightDeep")                   # the joint on the slab's left
                for q in range(1, lit_w + 1):
                    if yy >= cap(a + q):
                        L.px(a + q, yy, "nightSlate")           # the slab's lit left edge
            for xx in range(max(0, a), x0 + w_):
                L.px(xx, cap(xx), "night2" if b == 0 or not recessed else "nightSlate")   # the block's lit top
                if b:
                    L.px(xx, ya - 1, "nightDeep")               # the joint over it
        # a short fracture in the larger slabs, down from a block's top
        if w_ >= 12:
            fx = x0 + w_ // 2 + int(h(i, 9, 24) * 3)
            fy = joints[1] if len(joints) > 2 else top + 6
            for yy in range(fy, min(FLOOR, fy + 6 + int(h(i, 8, 25) * 8))):
                L.px(fx, yy, "nightDeep")
                L.px(fx + 1, yy, "nightSlate")
    for y in range(FLOOR):
        for x in (CLIFF_EDGE - 1, CLIFF_EDGE):
            if L.get(x, y) and L.get(x, y - 1):
                L.px(x, y, "nightDeep")
    # the right shoulder of the cleft, under the town, falling to the inner lands
    rt = profile(SHOULDER_PTS)
    for x in range(300, W):
        t = int(round(rt[x]))
        for y in range(t, H):
            L.px(x, y, "nightBlue")
        L.px(x, t, "nightSlate")
    # the darkness bank: a wall of black fog filling the Throat's floor, rolling toward the wall, a cold rim, eyes
    bank = np.zeros((H, W), bool)
    yy, xx = np.ogrid[:H, :W]
    BILLOWS = ((4, 112, 20), (30, 110, 18), (52, 122, 17), (74, 132, 16), (96, 142, 14), (116, 150, 12),
               (136, 157, 11), (154, 163, 9), (170, 169, 7))
    for (cx, cy, r) in BILLOWS:
        bank |= (xx - cx) ** 2 + (yy - cy) ** 2 <= r * r
        bank[cy:FLOOR + 1, max(0, cx - r):cx + r + 1] = True
    bank[FLOOR:, :178] = True
    L.mask(bank, "nightDeep")
    # inner billows: arcs of their upper halves inside the bank, a step lighter, so the fog has volume
    for (cx, cy, r) in ((14, 134, 12), (40, 138, 12), (62, 148, 11), (84, 156, 10), (106, 162, 9),
                        (126, 168, 8), (20, 160, 10), (50, 166, 9)):
        for x in range(cx - r, cx + r + 1):
            dy = math.sqrt(max(0, r * r - (x - cx) ** 2))
            y = int(round(cy - dy))
            if bank[y, x] and abs(x - cx) < r - 1:
                L.px(x, y, "nightBlue")
    # the cold rim on the bank's top: broken, never a full outline
    # the cold rim: only on the upper left of each billow (the Gloom's own cold light), never a full outline
    for (cx, cy, r) in BILLOWS:
        for x in range(cx - r, cx + 1):
            ys = np.where(bank[:, x])[0] if 0 <= x < W else []
            if len(ys):
                y = ys[0]
                if abs(math.hypot(x - cx, y - cy) - r) < 1.0 and x < cx - 1:
                    L.px(x, y, "wraithDim")
    for (x, y) in ((22, 128), (55, 136), (78, 146), (99, 152), (118, 160), (38, 152), (134, 165), (8, 146)):
        L.px(x, y, "wraithWhite")
        L.px(x + 2, y, "wraithWhite")
    declump(L, keep=("wraithWhite", "wraithDim", "nightDeep"))
    return L


# ----------------------------------------------------------------------------- layer 4: the wall, the keep, the town
GROUND = 178
WALK = 146               # the wall walk: feet of the lord and the sentries
KEEP = (245, 273)        # x range of the keep (centre 259)
WINDOWS = []             # (x, y, colour) of every lit window pixel: the wiring flickers them


def merlons(L, x0, x1, ytop, h_=3, w_=3, gap=2, phase=0):
    x = x0 + phase
    while x + w_ - 1 <= x1:
        for xx in range(x, x + w_):
            for yy in range(ytop, ytop + h_):
                L.px(xx, yy, "nightBlue")
            L.px(xx, ytop, "night2")
        L.px(x, ytop + 1, "nightSlate")
        L.px(x + w_ - 1, ytop + 1, "nightDeep")
        L.px(x + w_ - 1, ytop + 2, "nightDeep")
        x += w_ + gap


def masonry(L, x0, y0, x1, y1, seed, course=5, face="nightBlue", joint="nightDeep"):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            L.px(x, y, face)
    for row, y in enumerate(range(y0 + course - 1, y1, course)):
        x = x0 + (row * 5 + seed) % 9
        while x < x1:
            ln = 2 + int(h(x, y, seed) * 3)
            if h(x, y, seed + 1) < 0.55:
                for xx in range(x, min(x1, x + ln)):
                    L.px(xx, y, joint)
            x += 9


def tower(L, x0, x1, ytop, seed, roof=True, ybot=GROUND):
    masonry(L, x0, ytop + 3, x1, ybot, seed)
    merlons(L, x0, x1, ytop)
    for y in range(ytop + 3, ybot + 1):
        L.px(x0, y, "night2" if y < ytop + 22 else "nightSlate")
        L.px(x0 + 1, y, "nightSlate") if y < ytop + 22 else None
        L.px(x1, y, "nightDeep")
    for x in range(x0, x1 + 1):
        L.px(x, ytop + 3, "night2")
    if roof:
        cx = (x0 + x1) / 2.0
        hgt = int((x1 - x0) * 0.95)
        for d in range(hgt):
            half = (x1 - x0 + 3) / 2.0 * (d / float(hgt))
            y = ytop + 2 - hgt + d
            a, b = int(round(cx - half)), int(round(cx + half))
            for x in range(a, b + 1):
                L.px(x, y, "roofDeep" if x <= cx else "nightBlue")
            L.px(a, y, "roofLight" if d > 1 else "roofDeep")
        L.px(int(round(cx)), ytop + 1 - hgt, "nightSlate")


def lit(L, x, y, n):
    L.px(x, y, n)
    WINDOWS.append((x, y, n))


def window(L, x, y, on=True):
    if on:
        lit(L, x, y, "fireGold")
        lit(L, x, y + 1, "fireOrange")
    else:
        L.px(x, y, "night0")
        L.px(x, y + 1, "night0")


def house(L, x0, base, w_, wall_h, roof_h, lights, chimney=None, back=False):
    face, side, roof, ridge = ("night2", "nightSlate", "nightBlue", "nightSlate")
    if back:
        face, side, roof, ridge = ("nightSlate", "nightBlue", "nightBlue", "night2")
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
            L.px(cx, y, side)
            L.px(cx + 1, y, roof)
    for (dx, dy, kind) in lights:
        x, y = x0 + dx, base - wall_h + dy
        if kind == "w2":
            lit(L, x, y, "fireGold")
            lit(L, x, y + 1, "fireOrange")
        elif kind == "w1":
            lit(L, x, y, "fireOrange")
        elif kind == "d":
            lit(L, x, y, "fireOrange"); lit(L, x, y + 1, "ember")
            lit(L, x + 1, y, "ember"); lit(L, x + 1, y + 1, "ember")
        elif kind == "e":
            lit(L, x, y, "ember")
        elif kind == "x":
            L.px(x, y, "nightBlue")


def town(L):
    rt = profile(SHOULDER_PTS)
    base = lambda x: int(round(rt[x])) + 1
    back = [(337, 6, 5, 4, [(2, 1, "w1")]), (356, 8, 5, 5, [(5, 2, "w1")]), (377, 6, 4, 3, []),
            (395, 7, 4, 4, [(2, 1, "e")]), (420, 5, 3, 3, [(2, 1, "e")]), (441, 6, 3, 3, [])]
    for (x, w_, wh, rh, li) in back:
        house(L, x, base(x) - 5, w_, wh, rh, li, back=True)
    # the chapel with its little bell tower (the town's one tall shape)
    cx, cb = 366, base(366) - 1
    for y in range(cb - 16, cb + 1):
        for x in range(cx, cx + 5):
            L.px(x, y, "night2" if x < cx + 4 else "nightSlate")
    for d in range(7):
        y = cb - 17 - d
        a, b = cx + d // 3, cx + 4 - d // 3
        for x in range(a, b + 1):
            L.px(x, y, "nightBlue")
        L.px(a, y, "nightSlate")
    for (x, y) in ((cx + 2, cb - 24), (cx + 2, cb - 25), (cx + 1, cb - 25), (cx + 3, cb - 25)):
        L.px(x, y, "nightSlate")
    lit(L, cx + 2, cb - 13, "fireGold")
    lit(L, cx + 2, cb - 12, "fireOrange")
    house(L, cx + 5, cb, 9, 6, 5, [(2, 2, "w2"), (6, 2, "x")], chimney=6)
    front = [(334, 10, 7, 6, [(2, 2, "w2"), (6, 2, "w2"), (4, 5, "d")], 2),
             (347, 8, 6, 5, [(2, 2, "x"), (5, 2, "w2")], None),
             (357, 7, 8, 5, [(3, 2, "w2"), (3, 6, "w1")], 4),
             (382, 9, 6, 5, [(2, 2, "w1"), (6, 2, "w1")], 6),
             (393, 7, 5, 4, [(4, 2, "w1")], None),
             (403, 8, 5, 4, [(2, 2, "w1"), (5, 2, "x")], 2),
             (414, 6, 4, 4, [(3, 1, "e")], None),
             (425, 7, 4, 3, [(2, 1, "e"), (5, 1, "e")], 4),
             (437, 5, 3, 3, [(2, 1, "e")], None),
             (448, 6, 3, 3, [], None),
             (459, 4, 3, 2, [(1, 1, "e")], None)]
    for (x, w_, wh, rh, li, ch) in front:
        house(L, x, base(x + w_ // 2), w_, wh, rh, li, chimney=ch)
    lit(L, 376, base(376) - 4, "fireGold")
    for y in range(base(376) - 3, base(376) + 1):
        L.px(376, y, "nightBlue")


def draw_castle():
    del WINDOWS[:]
    L = Layer()
    masonry(L, 182, WALK, 330, GROUND, 5)
    for x in range(182, 331):
        L.px(x, WALK, "night2")
    merlons(L, 182, 330, WALK - 3, phase=1)
    # buttresses: stepped piers against the wall's face, their left side catching the sky
    for bx in (185, 233, 282, 304):
        for y in range(WALK + 6, GROUND + 1):
            step = 1 if y > WALK + 16 else 0
            L.px(bx - step, y, "nightSlate")
            L.px(bx + 1 - step, y, "nightBlue")
            L.px(bx + 2, y, "nightBlue")
            L.px(bx + 3, y, "nightDeep")
        for x in range(bx, bx + 4):
            L.px(x, WALK + 5, "night2")
        L.px(bx - 1, WALK + 16, "night2")
    # a dark plinth where the wall meets the rock
    for x in range(182, 331):
        for y in range(GROUND - 3, GROUND + 1):
            if L.is_(x, y, "nightBlue"):
                L.px(x, y, "nightDeep")
    # the gatehouse (left: the side of the dark): two towers and the gate between, a torch inside
    tower(L, 194, 206, 130, 11)
    tower(L, 215, 227, 130, 12)
    for y in range(134, GROUND + 1):
        for x in range(207, 215):
            L.px(x, y, "nightBlue")
    for x in range(207, 215):
        L.px(x, 133, "night2")
    # the gate: a small arch, a torch burning inside it
    gate = poly_mask([(208.5, GROUND + 1), (208.5, 168), (209.5, 166.5), (211, 166), (212.5, 166.5),
                      (213.5, 168), (213.5, GROUND + 1)])
    L.mask(gate, "emberDim")
    for (x, y) in ((210, 169), (211, 169), (210, 170), (211, 170), (210, 171), (211, 171), (209, 170),
                   (212, 170), (210, 172), (211, 172)):
        L.px(x, y, "ember")
    L.px(210, 170, "fireOrange"); L.px(211, 170, "fireOrange"); L.px(210, 169, "fireGold")
    for y in range(165, GROUND + 1):
        L.px(207, y, "nightBlue")
    for (x, y) in ((200, 140), (221, 140), (200, 156), (221, 156)):
        for k in range(3):
            L.px(x, y + k, "nightDeep")
    # the keep: tall and plain, its crown carrying the eternal light
    k0, k1 = KEEP
    masonry(L, k0, 113, k1, GROUND, 21)
    for y in range(113, GROUND + 1):
        L.px(k0, y, "night2" if y < 150 else "nightSlate"); L.px(k0 + 1, y, "nightSlate")
        L.px(k1, y, "nightDeep")
    for x in range(k0 - 1, k1 + 2):
        L.px(x, 112, "night2"); L.px(x, 113, "nightSlate"); L.px(x, 114, "nightBlue")
    merlons(L, k0 - 1, k1 + 1, 109)
    for x in range(k0, k1 + 1):                      # the corbel table under the parapet
        L.px(x, 115, "nightDeep" if (x - k0) % 3 == 2 else "nightSlate")
        L.px(x, 116, "nightDeep" if (x - k0) % 3 == 2 else "nightBlue")
    # the house banner on the keep: realm teal, our lantern on it in gold
    for y in range(118, 133):
        for x in range(257, 262):
            L.px(x, y, "roofDeep")
        L.px(257, y, "banner")
    for x in range(258, 261):
        L.px(x, 133, "roofDeep")
    L.px(259, 134, "roofDeep")
    for (x, y) in ((259, 122), (258, 123), (260, 123), (259, 124), (259, 125)):
        L.px(x, y, "gold")
    window(L, 250, 120); window(L, 268, 120, on=False); window(L, 250, 136); window(L, 268, 154)
    # the lantern's cradle: an iron post with two arms, behind the merlons
    for y in range(106, 113):
        L.px(LX, y, "nightDeep")
    for (x, y) in ((LX - 2, 110), (LX - 1, 111), (LX + 2, 110), (LX + 1, 111)):
        L.px(x, y, "nightDeep")
    tower(L, 318, 330, 134, 31)
    window(L, 323, 146)
    town(L)
    # the torch's pool on the ground before the gate
    for x in range(203, 222):
        d = abs(x - 211)
        L.px(x, GROUND + 1, "ember" if d < 3 else ("emberDim" if d < 7 else "crimsonDeep"))
        if d < 5:
            L.px(x, GROUND + 2, "emberDim")
    warm(L)
    declump(L, keep=("fireGold", "fireOrange", "ember", "gold", "nightDeep", "emberDim", "roofLight", "crimsonDeep",
                     "night0"))
    return L


WARM = {   # the eternal light on the castle's stone, by distance band
    "night2": ("tileLight", "tile", "crimsonDeep"),
    "nightSlate": ("tile", "crimsonDeep", "woodDark"),
    "nightBlue": ("crimsonDeep", "woodDark", None),
    "nightDeep": ("woodDark", None, None),
    "roofDeep": ("tile", "crimsonDeep", None),
    "roofLight": ("tileLight", "tile", "crimsonDeep"),
}
BANDS = (15, 27, 41)


def warm(L):
    inv = {C(k): k for k in WARM}
    for y in range(H):
        for x in range(W):
            if not L.a[y, x, 3]:
                continue
            n = inv.get(tuple(int(v) for v in L.a[y, x, :3]))
            if n is None:
                continue
            d = math.hypot(x - LX, (y - LY) * 1.1)
            band = next((i for i, b in enumerate(BANDS) if d < b), None)
            if band is None:
                continue
            # the light stands above the keep's crown: below the parapet only the sky-lit rims catch it
            if y > 114 and (n != "night2" or L.a[y - 1, x, 3]):
                continue
            t = WARM[n][band]
            if t:
                L.px(x, y, t)


# ------------------------------------------------------------------------------- layer 5: the fog and the foreground
FG_PTS = [(0, 176), (6, 170), (12, 172), (20, 162), (26, 168), (34, 166), (44, 176), (60, 180), (80, 184),
          (110, 188), (150, 191), (186, 193), (200, 190), (212, 191), (226, 194), (260, 195), (300, 194),
          (316, 191), (326, 192), (344, 190), (370, 189), (410, 187), (440, 185), (470, 183), (500, 180),
          (520, 178)]


def draw_fog():
    L = Layer()
    # one low bank along the whole floor: two flat levels with a scalloped top; higher in the Throat
    for x in range(W):
        s_ = 1.6 * math.sin(x / 7.0) + 1.0 * math.sin(x / 3.1 + 2.0) + 3.0 * math.sin(x / 23.0 + 0.6)
        base = 171 if x < 180 else (171 + (x - 180) * 0.16 if x < 230 else 179)
        t = int(round(base + s_))
        for y in range(t, H):
            L.px(x, y, "nightHaze" if y < t + 2 else "night2")
    top = profile(FG_PTS)
    for x in range(W):
        for y in range(int(round(top[x])), H):
            L.px(x, y, "nightDeep")
    for (fx_, fb, fh) in ((16, 172, 28), (30, 170, 20), (52, 180, 22), (63, 182, 15), (8, 172, 18)):
        for d in range(fh):
            y = fb - fh + d
            half = d * 0.28 + (1 if d % 5 in (3, 4) else 0) * (d / float(fh)) * 1.4
            for x in range(int(round(fx_ - half)), int(round(fx_ + half)) + 1):
                L.px(x, y, "nightDeep")
            if d % 5 == 3 and d > 4:
                L.px(int(round(fx_ - half)), y, "nightBlue")
    for (x, hgt, lean) in ((350, 5, 1), (353, 3, 0), (392, 6, -1), (396, 4, 0), (452, 5, 1), (456, 3, 1),
                           (488, 6, -1), (491, 4, 0), (120, 4, 1), (124, 6, 0), (170, 4, -1)):
        b = int(round(top[x]))
        for k in range(hgt):
            L.px(x + (lean * k) // 3, b - 1 - k, "nightDeep")
        L.px(x + 1, b - 1, "nightDeep")
    declump(L)
    return L


# ------------------------------------------------------------------------------- the glow of the eternal light
GLOW_ALPHA = (0.28, 0.14, 0.06)


def glow_layer(radii=(11, 20, 33), alphas=GLOW_ALPHA, cx=LX, cy=LY, w=W, hh=H, colour="fireOrange"):
    """Stepped rings of the light's colour: hard edges on the game grid, one alpha per ring."""
    a = np.zeros((hh, w, 4), np.uint8)
    yy, xx = np.mgrid[:hh, :w]
    d = np.hypot(xx - cx, yy - cy)
    for r, al in sorted(zip(radii, alphas), key=lambda t: -t[0]):
        m = d < r
        a[m, :3] = C(colour)
        a[m, 3] = int(round(al * 255))
    return Image.fromarray(a)


# ------------------------------------------------------------------------------------------ the lantern (13 x 23)
LW, LH = 13, 23
LFX, LFY = 6, 13          # the flame's centre inside the sprite

FLAME = {
    0: [(6, 16, "woodDark")],
    1: [(6, 16, "ember"), (6, 15, "fireOrange")],
    2: [(6, 16, "fireOrange"), (6, 15, "fireGold"), (6, 14, "fireOrange")],
    3: [(5, 16, "ember"), (6, 16, "fireGold"), (7, 16, "ember"), (6, 15, "fireGold"), (6, 14, "fireGold"),
        (6, 13, "fireOrange")],
    4: [(5, 16, "fireOrange"), (6, 16, "fireGold"), (7, 16, "fireOrange"), (5, 15, "fireOrange"),
        (6, 15, "fireWhite"), (7, 15, "fireOrange"), (6, 14, "fireGold"), (6, 13, "fireGold"), (6, 12, "fireOrange")],
    5: [(5, 16, "fireGold"), (6, 16, "fireWhite"), (7, 16, "fireGold"), (5, 15, "fireGold"), (6, 15, "fireWhite"),
        (7, 15, "fireGold"), (5, 14, "fireGold"), (6, 14, "fireWhite"), (7, 14, "fireGold"), (6, 13, "fireWhite"),
        (6, 12, "fireGold"), (6, 11, "fireGold")],
    6: [(5, 16, "fireGold"), (6, 16, "fireWhite"), (7, 16, "fireGold"), (4, 15, "fireGold"), (5, 15, "fireWhite"),
        (6, 15, "fireWhite"), (7, 15, "fireWhite"), (8, 15, "fireGold"), (5, 14, "fireWhite"), (6, 14, "fireWhite"),
        (7, 14, "fireWhite"), (5, 13, "fireGold"), (6, 13, "fireWhite"), (7, 13, "fireGold"), (6, 12, "fireWhite"),
        (6, 11, "fireGold"), (6, 10, "fireGold")],
}
FLAME[7] = [(x + (1 if y <= 12 else 0), y, c) for (x, y, c) in FLAME[6]]   # the tip leans one px: the flicker


def lantern(step):
    """step 0 unlit; 1 to 6 the wick catches and the flame grows; 7 the full flame's flicker twin."""
    L = Layer(LW, LH)
    iron, iron_lit, iron_dk = "nightBlue", "nightHaze", "nightDeep"
    brass, brass_lit = (("soilDark", "soil"), ("soil", "soilLight"), ("soil", "soilLight"),
                        ("soilLight", "straw"), ("soilLight", "straw"), ("straw", "gold"), ("straw", "gold"),
                        ("straw", "gold"))[step]
    for x in (5, 6, 7):
        L.px(x, 0, iron_lit if x < 7 else iron)
    L.px(5, 1, iron_lit); L.px(7, 1, iron)
    L.px(6, 2, iron); L.px(6, 3, iron)
    for x in range(5, 8):
        L.px(x, 4, iron)
    L.px(5, 4, iron_lit)
    for x in range(3, 10):
        L.px(x, 5, iron)
    L.px(3, 5, iron_lit); L.px(4, 5, iron_lit)
    for x in range(2, 11):
        L.px(x, 6, brass)
    L.px(2, 6, brass_lit); L.px(3, 6, brass_lit)
    for x in range(1, 12):
        L.px(x, 7, iron_dk)
    L.px(1, 7, iron)
    glass = ("night0", "night0", "night1", "emberDim", "emberDim", "ember", "ember", "ember")[step]
    for y in range(8, 18):
        L.px(2, y, iron_lit if step == 0 else brass_lit)
        L.px(10, y, iron)
        for x in range(3, 10):
            L.px(x, y, glass)
    if step <= 2:   # a cold reflection on the dark glass
        for (x, y) in ((4, 9), (4, 10), (4, 11)):
            L.px(x, y, "nightSlate")
    if step >= 4:   # the glass brightest round the flame: one stepped ring, so the flame stays the brightest shape
        for y in range(9, 18):
            for x in range(3, 10):
                r = math.hypot(x - LFX, (y - 14) * 0.8)
                if r < (2.6 if step == 4 else 3.6):
                    L.px(x, y, "ember" if step == 4 else "fireOrange")
    for x in (2, 10):
        L.px(x, 12, iron_dk if step == 0 else brass)
    for x in range(2, 11):
        L.px(x, 18, brass)
    L.px(2, 18, brass_lit); L.px(3, 18, brass_lit)
    for x in range(1, 12):
        L.px(x, 19, iron_dk)
    L.px(1, 19, iron)
    for x in range(3, 10):
        L.px(x, 20, iron)
    L.px(3, 20, iron_lit)
    for x in range(5, 8):
        L.px(x, 21, iron)
    L.px(6, 22, iron_dk)
    for (x, y, c) in FLAME[step]:
        L.px(x, y, c)
    return L


LANTERN_GLOW = {  # step: radii of the stepped rings around the flame
    0: (), 1: (3,), 2: (5, 8), 3: (6, 11, 16), 4: (8, 14, 23), 5: (10, 17, 28), 6: (11, 20, 33),
    7: (12, 21, 34),
}


def lantern_glow(step, size=81):
    c = size // 2
    rr = LANTERN_GLOW[step]
    return glow_layer(radii=rr, alphas=GLOW_ALPHA[:len(rr)], cx=c, cy=c, w=size, hh=size)


# ---------------------------------------------------------------------------------------------- the small figures
def lord(frame):
    """9 x 16, feet on the bottom row: the lord with the house's lantern on its hooked staff, facing left (the
    dark). 0 stands; 1 lifts; 2 raised; 3 raised, the lantern flaring. A warm rim on his left, toward the light."""
    L = Layer(9, 16)
    cloak, cloak_d, skin, rim = "roofDeep", "nightBlue", "tileLight", "tile"
    oy = 2
    L.px(4, oy + 1, "gold"); L.px(5, oy + 1, "gold")
    L.px(4, oy + 2, skin); L.px(5, oy + 2, "woodDark")
    L.px(4, oy + 3, skin); L.px(5, oy + 3, "woodDark")
    L.px(4, oy + 0, "woodDark"); L.px(5, oy + 0, "woodDark")
    rows = [(3, 6), (3, 6), (3, 7), (3, 7), (2, 7), (2, 7), (2, 7), (2, 7)]
    for i, (a, b) in enumerate(rows):
        y = oy + 4 + i
        for x in range(a, b + 1):
            L.px(x, y, cloak if x < b else cloak_d)
        L.px(a, y, rim)
    for y in (oy + 12, oy + 13):
        L.px(3, y, "woodDark"); L.px(5, y, "woodDark")
    L.px(2, oy + 13, "soilDark"); L.px(4, oy + 13, "soilDark")
    if frame == 0:
        for y in range(oy + 1, oy + 14):
            L.px(1, y, "wood")
        L.px(1, oy + 0, "woodDark"); L.px(0, oy + 1, "woodDark")
        L.px(0, oy + 2, "nightBlue")
        L.px(0, oy + 3, "fireGold"); L.px(0, oy + 4, "fireOrange")
        L.px(2, oy + 6, skin)
    elif frame == 1:
        for y in range(oy - 1, oy + 11):
            L.px(1, y, "wood")
        L.px(1, oy - 2, "woodDark"); L.px(0, oy - 1, "woodDark")
        L.px(0, oy, "nightBlue")
        L.px(0, oy + 1, "fireGold"); L.px(0, oy + 2, "fireOrange")
        L.px(2, oy + 4, skin)
    else:
        for y in range(0, oy + 9):
            L.px(1, y, "wood")
        L.px(0, 0, "woodDark")
        L.px(0, 1, "fireWhite" if frame == 3 else "fireGold")
        L.px(0, 2, "fireGold" if frame == 3 else "fireOrange")
        L.px(2, oy + 2, skin); L.px(2, oy + 3, cloak)
    return L


LORD_LANTERN_Y = {0: 5, 1: 3, 2: 1, 3: 1}   # his lantern's row in each frame (column 0)


def sentry(rim_side):
    """7 x 16, feet on the bottom row: a guard in a kettle hat with a spear, facing left (the dark). One warm px on
    the hat's brim and one on the shoulder, on the side that faces the eternal light."""
    L = Layer(7, 16)
    for x in (3, 4):
        L.px(x, 2, "stoneMid")
    for x in (2, 3, 4, 5):
        L.px(x, 3, "stoneMid")
    L.px(2, 3, "stoneLight")
    L.px(3, 4, "tile"); L.px(4, 4, "woodDark")
    L.px(3, 5, "tile"); L.px(4, 5, "nightBlue")
    for y in range(6, 13):
        for x in (2, 3, 4, 5):
            if y == 6 and x in (2, 5):
                continue
            L.px(x, y, "nightSlate" if x < 4 else "nightBlue")
    for x in (3, 4):
        L.px(x, 9, "woodDark")                                       # the belt
    for y in (13, 14, 15):
        L.px(3, y, "nightBlue"); L.px(4, y, "nightBlue")
    L.px(2, 15, "nightDeep"); L.px(5, 15, "nightDeep")
    for y in range(1, 16):
        L.px(1, y, "woodDark")                                       # the spear's shaft
    L.px(1, 0, "stonePale")
    L.px(2, 8, "tile")                                               # the hand on the shaft
    if rim_side == "right":
        L.px(5, 3, "tile"); L.px(5, 7, "crimsonDeep")
    else:
        L.px(2, 3, "tile"); L.px(2, 7, "crimsonDeep")
    return L


LORD_POS = (279, WALK)
SENTRIES = [((236, WALK), "right"), ((303, WALK), "left")]


# ------------------------------------------------------------------------------------------- the lettering
GH = 30


def glyph(ch):
    """Tall capitals on a 30 px grid: thick stems of 4, hairlines of 2, flared serifs. A bool mask."""
    def R(m, x0, y0, x1, y1):
        m[max(0, y0):y1 + 1, max(0, x0):x1 + 1] = True

    def P(m, pts):
        m |= poly_mask(pts, m.shape[1], m.shape[0])

    def SF(m, x0, x1, y_out, y_in):
        """A bracketed serif: the outer row full, the inner row one px shorter at each end (a wedge, not a slab)."""
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
    return m


WORD = "LANTERNHOLD"
GAP = 4
LETTER_Y = 20


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
        if state == "unlit":
            L.mask(inner, "nightBlue")
            L.mask(edge, "nightSlate")
            continue
        L.mask(inner, "stoneDark")
        ys, xs = np.where(inner)
        for y, x in zip(ys, xs):
            if y - by > bh - 6:
                L.px(x, y, "woodDark")
        ys, xs = np.where(edge)
        for y, x in zip(ys, xs):
            nx = int(not m[y, x + 1]) - int(not m[y, x - 1])
            ny = int(not m[y + 1, x]) - int(not m[y - 1, x])
            nl = math.hypot(nx, ny)
            dx, dy = LX - x, LY - y
            f = 0 if nl == 0 else (nx * dx + ny * dy) / (nl * math.hypot(dx, dy))
            near = 1.0 - min(1.0, abs(x - LX) / 140.0)
            if f > 0.55 and near > 0.62:
                c = "fireGold"
            elif f > 0.55:
                c = "gold"
            elif f > 0.15:
                c = "straw"
            elif f > -0.3:
                c = "soilLight"
            else:
                c = "soil"
            L.px(x, y, c)
    rule(L, boxes, state)
    return L, boxes


RULE_Y = LETTER_Y + GH + 3


def rule(L, boxes, state):
    """A thin rule of iron and brass under the word, broken at its centre by a small diamond, the lantern's mark:
    the brass faces down, toward the light."""
    x0 = boxes[1][0] + 2
    x1 = boxes[-2][0] + boxes[-2][2] - 3
    for x in range(x0, x1 + 1):
        if abs(x - LX) <= 6:
            continue
        L.px(x, RULE_Y - 1, "nightDeep")
        L.px(x, RULE_Y, "nightBlue" if state == "unlit" else "stoneDark")
        near = 1.0 - min(1.0, abs(x - LX) / 120.0)
        L.px(x, RULE_Y + 1, "nightSlate" if state == "unlit" else ("gold" if near > 0.55 else "straw"))
        L.px(x, RULE_Y + 2, "nightDeep")
    for (x, y) in ((x0 - 1, RULE_Y), (x0 - 1, RULE_Y + 1), (x1 + 1, RULE_Y), (x1 + 1, RULE_Y + 1)):
        L.px(x, y, "nightDeep")
    # the diamond: radius 4, an iron ring with a brass lower edge round a heart that glows when lit
    for dy in range(-5, 6):
        for dx in range(-5, 6):
            r = abs(dx) + abs(dy)
            x, y = LX + dx, RULE_Y + dy
            if r == 5:
                L.px(x, y, "nightDeep")
            elif r == 4:
                if state == "unlit":
                    L.px(x, y, "nightSlate")
                else:
                    L.px(x, y, "fireGold" if dy > 0 else ("gold" if dy == 0 else "straw"))
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
    """The wall's parapet drawn again over the walkers, so their feet stand behind it."""
    a = np.array(castle)
    f = np.zeros_like(a)
    f[WALK - 3:WALK + 1, 182:331] = a[WALK - 3:WALK + 1, 182:331]
    f[:, KEEP[0] - 1:KEEP[1] + 2] = 0
    f[:, 194:228] = 0
    f[:, 318:331] = 0
    return Image.fromarray(f)


def scene(layers, sprites, letters=None, lord_frame=0, off=None):
    off = off or {}
    o = lambda k: off.get(k, 0)
    img = Image.new("RGBA", (W, H), C(DARK) + (255,))
    for name in ("sky", "far", "rock"):
        img = over(img, layers[name], o(name))
    img = over(img, layers["glow"], o("castle"))
    img = over(img, layers["castle"], o("castle"))
    img = over(img, sprites["lantern6"].image(), o("castle") + LX - LFX, LY - LFY)
    for (pos, side) in SENTRIES:
        s = sprites["sentryA" if side == "right" else "sentryB"]
        img = over(img, s.image(), o("castle") + pos[0] - s.w // 2, pos[1] - s.h + 1)
    lf = sprites["lord%d" % lord_frame]
    lx0, ly0 = LORD_POS[0] - lf.w // 2 + o("castle"), LORD_POS[1] - lf.h + 1
    rr = (3, 6) if lord_frame < 3 else (5, 9)
    img = over(img, glow_layer(radii=rr, alphas=(0.30, 0.14), cx=lx0, cy=ly0 + LORD_LANTERN_Y[lord_frame]))
    img = over(img, lf.image(), lx0, ly0)
    img = over(img, layers["front"], o("castle"))
    img = over(img, layers["fog"], o("fog"))
    if letters is not None:
        img = over(img, letters)
    return img


def build_all():
    layers = {"sky": draw_sky().image(), "far": draw_far().image(), "rock": draw_rock().image(),
              "castle": draw_castle().image(), "fog": draw_fog().image(), "glow": glow_layer()}
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
               "front": "title4Parapet", "fog": "title5Fog", "glow": "titleGlow"}
DRIFT = {"sky": -3, "far": -2, "rock": -1, "castle": 0, "fog": 8}   # game px at the sway's peak; the castle (and the light) never move


def write_art(outdir=OUT):
    os.makedirs(outdir, exist_ok=True)
    layers, sprites, unlit, litl, boxes = build_all()
    for k, n in LAYER_FILES.items():
        layers[k].save(os.path.join(outdir, n + ".png"))
    glow_layer(radii=LANTERN_GLOW[7]).save(os.path.join(outdir, "titleGlowFlicker.png"))
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
    sprites["sentryA"].image().save(os.path.join(outdir, "titleSentryA.png"))
    sprites["sentryB"].image().save(os.path.join(outdir, "titleSentryB.png"))
    li = Image.new("RGBA", (LW, 27), (0, 0, 0, 0))
    li.paste(sprites["lantern0"].image(), (0, 0))
    li.save(os.path.join(outdir, "launchLantern.png"))
    meta = {
        "picture": [W, H], "window": [WIN_X, 0, WIN_W, H], "eternalLight": [LX, LY],
        "launchColour": "#%02X%02X%02X" % C(DARK),
        "lettering": {"box": [crop[0], crop[1], crop[2] - crop[0], crop[3] - crop[1]], "order": WORD,
                      "letters": [[b[0] - 1, b[1] - 1, b[2] + 2, b[3] + 2] for b in boxes]},
        "lantern": {"size": [LW, LH], "flame": [LFX, LFY], "glowRadii": LANTERN_GLOW, "glowAlpha": GLOW_ALPHA,
                    "glowSize": 81},
        "lord": {"feet": list(LORD_POS), "size": [9, 16], "lanternPixel": {"x": 0, "y": LORD_LANTERN_Y}},
        "sentries": [{"feet": list(p), "sprite": "titleSentryA" if s == "right" else "titleSentryB"}
                     for p, s in SENTRIES],
        "drift": DRIFT, "windows": WINDOWS,
    }
    with open(os.path.join(outdir, "title.json"), "w") as f:
        json.dump(meta, f, indent=1)
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


RING = (5, 10, 15)      # the three dark steps beyond the light's front, in game px
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
    img = Image.fromarray(out.round().astype(np.uint8)).convert("RGBA")
    return over(img, lantern_glow(6), LX - WIN_X - 40, LY - 40)


def touch_line(big):
    font = ImageFont.truetype(os.path.join(GAME, "Resources", "Fonts", "IMFeENrm28P.ttf"), 54)
    layer = Image.new("RGBA", big.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    text = "Touch to begin"
    bb = d.textbbox((0, 0), text, font=font)
    d.text(((big.width - (bb[2] - bb[0])) // 2, big.height - 108), text, font=font, fill=BONE + (178,))
    return Image.alpha_composite(big, layer)


def gear(big):
    import subprocess
    try:
        raw = subprocess.run(["git", "show", "claude/lh-hudart:games/lanternhold/Resources/Art/hudGear.png"],
                             cwd=GAME, capture_output=True, check=True).stdout
        import io
        g = Image.open(io.BytesIO(raw)).convert("RGBA")
    except Exception:
        return big
    g = g.resize((g.width * 6, g.height * 6), Image.NEAREST)
    return over(big, g, big.width - g.width - 54, 42)


def write_proofs(proofdir=PROOF):
    os.makedirs(proofdir, exist_ok=True)
    layers, sprites, unlit, litl, boxes = build_all()
    save_proof(big6(lantern_screen(0)), "01-launch", proofdir)
    save_proof(big6(lantern_screen(2)), "02-loading-small", proofdir)
    save_proof(big6(lantern_screen(6)), "03-loading-full", proofdir)
    pic_unlit = window_of(scene(layers, sprites, letters=unlit))
    save_proof(big6(reveal(pic_unlit, 110)), "04-glow-half", proofdir)
    save_proof(big6(pic_unlit), "05-title-unlit", proofdir)
    pic_lit = window_of(scene(layers, sprites, letters=litl))
    save_proof(gear(touch_line(big6(pic_lit))), "06-title", proofdir)
    pic_raise = window_of(scene(layers, sprites, letters=litl, lord_frame=3))
    save_proof(gear(big6(pic_raise)), "07-lord-raises", proofdir)
    pic_lit.resize((874, 402), Image.NEAREST).convert("RGB").save(os.path.join(proofdir, "_phone-874.png"))
    # a 4x crop round the keep for the self-review (not a deliverable)
    pic_lit.crop((150, 60, 300, 150)).resize((600, 360), Image.NEAREST).convert("RGB").save(
        os.path.join(proofdir, "_zoom-keep.png"))


if __name__ == "__main__":
    what = sys.argv[1] if len(sys.argv) > 1 else "all"
    arg = sys.argv[2] if len(sys.argv) > 2 else None
    if what in ("art", "all"):
        write_art(arg if (arg and what == "art") else OUT)
    if what in ("proof", "all"):
        write_proofs(arg if (arg and what == "proof") else PROOF)
