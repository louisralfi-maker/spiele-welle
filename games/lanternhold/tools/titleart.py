#!/usr/bin/env python3
"""Lanternhold "First light" (round 4: stone in volume, solid steps on surfaces, a quieter dither in the air, a
crisp dark front with claws). (docs/TITLE.md sections 1, 2, 3 and 5): the launch image, the loading lantern, the title
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
LX, LY = 259, 100          # round 1-2 anchor; round 3 raises LY to 76 below


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


# Round 3 (the director, 15.11.2026): "a pool of light in a sea of dark". Around the flame the air glows in a falloff
# of six palette steps, mixed by a 4x4 ordered dither on the game grid; every face turned to the flame takes the warm
# ramp over its whole area; the dark is the left third's frame and frays into dither where the light meets it.
LY = 76                         # the flame, raised to 38 % of the height (round 3); LX stays 259
AIR_R = (170.0, 120.0)          # the air's glow: half-width, half-height (an ellipse, not a circle)
FACE_R = (200.0, 145.0)         # the reach on solid faces
AIR = ["night2", "plum", "dusk", "tileLight", "gold", "fireGold"]       # dusk violet .. pale gold, above the night
STONE = ["plumDeep", "plum", "tile", "tileLight", "straw", "strawLight"]  # plum .. rust .. amber .. warm sand
JOINTR = ["plumDeep", "crimsonDeep", "tile"]


def ell(x, y, r):
    return math.hypot((x - LX) / r[0], (y - LY) / r[1])


def t_air(x, y):
    return max(0.0, 1.0 - ell(x, y, AIR_R)) ** 1.35


def t_face(x, y):
    return max(0.0, 1.0 - ell(x, y, FACE_R)) ** 1.1


def pick(x, y, cols, p):
    """Ordered dither between neighbouring palette steps: never a blend, never alpha."""
    if p <= 0:
        return cols[0]
    i = int(p)
    if i >= len(cols) - 1:
        return cols[-1]
    return cols[i + 1] if BAYER[y % 4][x % 4] < int((p - i) * 16) else cols[i]


def pick_air(x, y, cols, p):
    """Round 4: each step keeps 60 % of its band solid; the rest mixes in three densities (25, 50, 75 %)."""
    if p <= 0:
        return cols[0]
    i = int(p)
    if i >= len(cols) - 1:
        return cols[-1]
    f = p - i
    if f < 0.6:
        return cols[i]
    level = (4, 8, 12)[min(2, int((f - 0.6) / 0.4 * 3))]
    return cols[i + 1] if BAYER[y % 4][x % 4] < level else cols[i]


def pick_solid(cols, p):
    """Solid steps for stone, cliffs and the ledge: no dither on surfaces."""
    return cols[max(0, min(len(cols) - 1, int(p)))]


def dist(x, y):
    return math.hypot(x - LX, y - LY)


# ------------------------------------------------------------------------------------------------- layer 1: the sky
HORIZON = 140
BAYER = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]
SKY = [(0, "nightBlue"), (52, "nightSlate"), (100, "nightHaze")]
SKY_MIX = 12                    # rows over which two bands meet in dither
STARS_BIG = [(70, 9), (452, 12)]
STARS_MID = [(118, 4), (404, 30), (470, 52), (96, 40), (360, 6)]
STARS_SMALL = [(84, 22), (132, 10), (150, 30), (420, 16), (440, 36), (388, 14), (462, 28), (110, 60), (430, 70),
               (100, 84), (476, 90), (380, 48), (140, 50), (458, 62)]
CLOUDS = [(330, 63, 38, 2.6), (304, 66, 16, 1.6), (196, 64, 20, 1.8)]


def sky_base(x, y):
    n = SKY[0][1]
    for i, (y0, c) in enumerate(SKY):
        if y >= y0:
            n = c
    for i in range(1, len(SKY)):
        y0, c = SKY[i]
        d = y - (y0 - SKY_MIX // 2)
        if 0 <= d < SKY_MIX:
            return c if BAYER[y % 4][x % 4] < int(16 * (d + 0.5) / SKY_MIX) else SKY[i - 1][1]
    return n


def draw_sky():
    L = Layer()
    for y in range(H):
        for x in range(W):
            L.px(x, y, pick_air(x, y, [sky_base(x, y)] + AIR, t_air(x, y) * 6.2))
    for lst, kind in ((STARS_SMALL, 1), (STARS_MID, 2), (STARS_BIG, 3)):
        for (x, y) in lst:
            if t_air(x, y) > 0.01:
                continue              # the stars go out near the light
            L.px(x, y, "foam" if kind > 1 else ("farPale" if y < 40 else "moon"))
            if kind >= 2:
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    L.px(x + dx, y + dy, "moon" if kind == 2 else "farPale")
            if kind == 3:
                for dx, dy in ((2, 0), (-2, 0), (0, 2), (0, -2)):
                    L.px(x + dx, y + dy, "moon")
    # thin clouds near the keep, lit from below: the underside a step and a half warmer, the top a step darker
    for (cx, cy, rx, ry) in CLOUDS:
        for y in range(int(cy - ry) - 1, int(cy + ry) + 2):
            for x in range(int(cx - rx), int(cx + rx) + 1):
                e = math.hypot((x - cx) / rx, (y - cy) / ry)
                if e > 1.0 or (e > 0.8 and BAYER[y % 4][x % 4] < 8):
                    continue
                p = t_air(x, y) * 6.2 + (1.6 if y >= cy else -0.8)
                L.px(x, y, pick_air(x, y, ["nightSlate"] + AIR, p))
    return L


# ------------------------------------------------------------------------------- layer 2: the lowland through the gap
def draw_far():
    L = Layer()
    for x in range(W):
        for y in range(HORIZON + 1, H):
            base = "mistDark" if y < HORIZON + 4 else ("far" if y < HORIZON + 12 else "nightHaze")
            L.px(x, y, pick_air(x, y, [base] + AIR, t_air(x, y) * 4.0))
    for (cx, w_, hh) in ((300, 46, 7), (338, 34, 5), (366, 26, 4)):
        for x in range(cx - w_ // 2, cx + w_ // 2 + 1):
            t = (x - cx) / (w_ / 2.0)
            top = int(round(HORIZON - hh * (1 - t * t)))
            for y in range(top, HORIZON + 1):
                L.px(x, y, pick_air(x, y, ["far"] + AIR, t_air(x, y) * 4.0))
    # the dawn, two steps and a little taller: two rows of dawnRose under two of dusk, breaking up to the left
    for x in range(360, W):
        if x >= 398:
            L.px(x, HORIZON, "dawnRose"); L.px(x, HORIZON - 1, "dawnRose")
            L.px(x, HORIZON - 2, "dusk")
            if x >= 420:
                L.px(x, HORIZON - 3, "dusk")
        elif any(a <= x <= b for a, b in ((362, 366), (372, 379), (385, 396))):
            L.px(x, HORIZON, "dawnRose"); L.px(x, HORIZON - 1, "dusk")
    for (x, y) in ((392, 145), (418, 143), (447, 146), (462, 143)):
        L.px(x, y, "emberDim")
    return L


# ---------------------------------------------------------------------------- the light on solid faces (round 3)
FACE_SET = {"nightSlate", "night2", "nightBlue", "stoneMid", "stoneDark", "farDeep", "roofDeep", "roofLight"}


def light_faces(L, front=("nightSlate", "night2"), shade=("nightBlue",), joints=("nightDeep",), k_front=0.75,
                k_shade=0.2, keep=("fireGold", "fireOrange", "ember", "emberDim", "gold", "night0", "banner")):
    """Every face turned to the flame takes the stone ramp by distance over its whole area. Facing: a step toward the
    flame leaves the shape (or meets a joint) within 3 px: the face is turned to it (k 1); front faces k 0.75; faces
    turned away (shade) k 0.2. Joints follow the ramp two steps lower."""
    a = L.a.copy()
    fr = {C(n): n for n in front}
    sh = {C(n): n for n in shade}
    jo = {C(n): n for n in joints}
    kp = {C(n) for n in keep}
    for y in range(H):
        for x in range(W):
            if not a[y, x, 3]:
                continue
            c = tuple(int(v) for v in a[y, x, :3])
            if c in kp:
                continue
            tf = t_face(x, y)
            if tf <= 0:
                continue
            d = dist(x, y) or 1.0
            vx, vy = (LX - x) / d, (LY - y) / d
            facing = False
            for k in (1, 2, 3):
                qx, qy = int(round(x + vx * k)), int(round(y + vy * k))
                if not (0 <= qx < W and 0 <= qy < H) or not a[qy, qx, 3]:
                    facing = True
                    break
            if c in jo:
                L.px(x, y, pick(x, y, [jo[c]] + JOINTR, max(0.0, tf * 6.5 * k_front - 2.2)))
                continue
            name = fr.get(c) or sh.get(c)
            if name is None:
                name = next((n for n in FACE_SET if C(n) == c), None)
                if name is None:
                    continue
            k = 1.0 if facing else (k_shade if c in sh else k_front)
            L.px(x, y, pick(x, y, [name] + STONE, tf * 6.5 * k))


# --------------------------------------------------------------- layer 3: the Weltmauer's rock, the gap, the darkness
FLOOR = 178


def left_edge(y):
    return int(128 + min(y, 130) * 0.22) + (1 if (y // 11) % 3 == 1 else 0)


def right_edge(y):
    return 418 + int(y * 0.2) + (2 if (y // 9) % 3 == 1 else 0)


def rock_px(L, x, y, base, k):
    """Round 4: the cliffs step by surface (solid steps of the stone ramp, no checker)."""
    L.px(x, y, pick_solid([base] + STONE, t_face(x, (y // 8) * 8 + 4) * 6.0 * k))


def draw_rock():
    L = Layer()
    for x in range(W):
        for y in range(FLOOR, H):
            L.px(x, y, "nightBlue")
    joints_x = [118, 104, 88, 70, 50, 30, 12]
    for y in range(0, FLOOR):
        e = left_edge(y)
        for x in range(0, e + 1):
            L.px(x, y, "nightBlue")
        for i, jx in enumerate(joints_x):
            if h(i, y // 26, 51) < 0.85:
                L.px(jx, y, "nightDeep"); L.px(jx + 1, y, "nightSlate")
        # the inner face turned to the flame: two lit steps, the edge brighter
        for x in range(e - 6, e + 1):
            rock_px(L, x, y, "nightSlate", 0.95 if x >= e - 2 else 0.6)
        L.px(e - 7, y, "nightDeep")
        if y % 26 == 25:
            for x in range(e - 6, e + 1):
                L.px(x, y, "nightBlue")
    # the far shoulder on the right: its inner face in two lit steps, then the mass
    for y in range(0, FLOOR):
        e = right_edge(y)
        for x in range(e, W):
            L.px(x, y, "nightSlate")
        for x in range(e, min(W, e + 7)):
            rock_px(L, x, y, "night2", 1.0 if x < e + 3 else 0.6)
        for k, jx in enumerate((e + 14, e + 29, e + 46)):
            if jx < W and h(k, y // 23, 41) < 0.8:
                L.px(jx, y, "nightBlue"); L.px(jx + 1, y, "night2")
        if y % 23 == 22:
            for x in range(e, min(W, e + 7)):
                L.px(x, y, "nightBlue")
    return L


# ------------------------------------------------------------------- the dark: the frame of the left third (round 4)
DARK_T = 0.18          # the dark is cut sharply where the air's light passes this
CLAWS = [  # (start, angle in degrees, length, root thickness): long, distinct, reaching for the castle
    ((128, 62), 8, 64, 5),      # over the outer left tower
    ((118, 170), 1, 86, 5),     # along the ground fog toward the gate
    ((132, 112), -6, 46, 4),
    ((124, 28), 18, 50, 4),
    ((130, 140), 6, 40, 3)]
def dark_front(y):
    f = 124 + 7 * math.sin(y / 13.0) + 4 * math.sin(y / 5.3 + 1.0)
    if y < 26:
        f += (26 - y) * 0.8
    if y > 160:
        f += (y - 160) * 3.2
    return f


def claw_px(m, sx, sy, ang, ln, th0):
    for k in range(ln):
        a = math.radians(ang + 12.0 * math.sin(k / 10.0 + sx * 0.1))
        px_ = sx + k * math.cos(a)
        py_ = sy + k * math.sin(a)
        th = max(1, int(round(th0 * (1 - k / float(ln)) + 0.5)))
        for dy in range(th):
            X, Y = int(round(px_)), int(round(py_)) + dy - th // 2
            if 0 <= X < W and 0 <= Y < H:
                m[Y, X] = True
    # the claw's hooked tip: three px curling down
    X, Y = int(round(px_)), int(round(py_))
    for (dx, dy) in ((1, 1), (1, 2), (0, 3)):
        if 0 <= X + dx < W and 0 <= Y + dy < H:
            m[Y + dy, X + dx] = True


def dark_mask():
    m = np.zeros((H, W), bool)
    for y in range(H):
        f = dark_front(y)
        for x in range(0, min(W, int(f) + 1)):
            if t_air(x, y) < DARK_T:          # a crisp cut against the lit air, no fray
                m[y, x] = True
    for (sx, sy), ang, ln, th in CLAWS:       # the claws reach into the light
        claw_px(m, sx, sy, ang, ln, th)
    return m


# the hand that reaches out of the dark onto the lit cliff: a solid silhouette with four claws (round 5)
PALM = [(122, 94), (136, 92), (142, 96), (142, 104), (136, 108), (122, 110)]
FINGERS = [((140, 93), (151, 87)), ((142, 97), (153, 95)), ((142, 101), (152, 104)), ((139, 106), (147, 112))]
EYE_PAIRS = [  # (x, y, w, h, gap, right eye dy, right eye h, colour): no two alike, no outline, no halo
    (112, 80, 3, 2, 4, 0, 2, "wraithWhite"), (102, 124, 2, 2, 5, -1, 1, "wraithWhite"),
    (90, 100, 2, 1, 3, 0, 1, "wraithGlow"), (70, 60, 1, 1, 3, 1, 1, "wraithGlow"), (60, 140, 2, 1, 2, 0, 1, "wraithGlow"),
    (84, 152, 1, 2, 3, 0, 2, "wraithGlow"), (30, 30, 1, 1, 2, 0, 1, "wraithDim"), (48, 84, 1, 1, 3, -1, 1, "wraithDim"),
    (20, 104, 1, 1, 2, 0, 1, "wraithDim"), (78, 22, 2, 1, 4, 0, 1, "wraithDim"), (36, 160, 1, 1, 3, 0, 1, "wraithDim"),
    (14, 130, 1, 1, 4, 1, 1, "wraithDim"), (54, 112, 1, 1, 2, 1, 1, "wraithDim"), (24, 66, 2, 1, 2, 0, 1, "wraithDim")]


def draw_dark(L, m, ground=False):
    for y in range(H):
        for x in range(W):
            if not m[y, x] or (ground and y < 160):
                continue
            L.px(x, y, "night0")      # one near black; the violet lives in the forms and the heads
    if ground:
        return
    # the hand: solid, in the dark's own black, its claws on the lit cliff face
    L.mask(poly_mask(PALM), "night0")
    for (ax, ay), (bx, by) in FINGERS:
        n = int(max(abs(bx - ax), abs(by - ay)))
        for k in range(n + 1):
            t = k / float(n)
            x, y = int(round(ax + (bx - ax) * t)), int(round(ay + (by - ay) * t))
            L.px(x, y, "night0")
            if t < 0.55:
                L.px(x, y + 1, "night0")      # thick at the knuckle, one px at the claw
    for (x, y, w_, h_, gap, dyr, hr, col) in EYE_PAIRS:
        for (ex, ey, eh) in ((x, y, h_), (x + w_ + gap, y + dyr, hr)):
            for dx in range(w_):
                for dy in range(eh):
                    if m[ey + dy, ex + dx]:
                        L.px(ex + dx, ey + dy, col if dy == 0 or col != "wraithWhite" else "wraithGlow")


# ----------------------------------------------------------------------------- layer 4: the wall, the keep, the town
GROUND = 178
WALK = 132
WALK_LOW = 158
KEEP = (232, 286)
FACE, RIM, SHADE, JOINT = "nightSlate", "night2", "nightBlue", "nightDeep"
COURSE = 6
WINDOWS = []
KM = np.zeros((H, W))          # how much of the light each castle px takes (its face: lit, front, shadow)
JM = np.zeros((H, W), bool)    # joints (drawn one step darker, never on shadow faces)
LM = np.zeros((H, W), bool)    # single lighter stones
QX = np.zeros((H, W))          # the x where a px samples the light (its body's), so steps follow the courses


def lit(L, x, y, n):
    L.px(x, y, n)
    WINDOWS.append((x, y, n))


def body(L, x0, x1, y0, y1, seed, faces, qx=None):
    """A body of stone in courses of 6 px. faces: [(xa, xb, k)] spans of its faces (lit, front, shadow)."""
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            L.px(x, y, FACE)
            QX[y, x] = qx if qx is not None else (x // 12) * 12 + 6
            for (xa, xb, k) in faces:
                if xa <= x <= xb:
                    KM[y, x] = k
    # joints: about a third, broken, big blocks; a few single lighter stones
    for row, y in enumerate(range(y0 + COURSE, y1 + 1, COURSE)):
        for x in range(x0, x1 + 1):
            if h(x // 5, y, seed) < 0.36:
                JM[y, x] = True
        off = (row * 7 + seed) % 11
        for x in range(x0 + off, x1, 11 + (row % 3) * 2):
            if h(x, y, seed + 3) < 0.4:
                for yy in range(y - COURSE + 1, y):
                    JM[yy, x] = True
            if h(x, y, seed + 5) < 0.045:
                for yy in range(y - COURSE + 1, y):
                    for xx in range(x + 1, min(x1, x + 6)):
                        LM[yy, xx] = True


def merlons(L, x0, x1, ytop, k, w_=3, gap=2, phase=0, qx=None):
    x = x0 + phase
    while x + w_ - 1 <= x1:
        for xx in range(x, x + w_):
            for yy in range(ytop, ytop + 3):
                L.px(xx, yy, RIM if yy == ytop else FACE)
                KM[yy, xx] = 1.15 if yy == ytop else k
                QX[yy, xx] = qx if qx is not None else xx
        x += w_ + gap


def cast(x0, x1, y, rows=2):
    """The cast shadow under a battlement: 1 to 2 px a few steps darker."""
    for yy in range(y, y + rows):
        for x in range(x0, x1 + 1):
            KM[yy, x] *= 0.35


def tower(L, x0, x1, ytop, seed, lit_side):
    mid = (x0 + x1) // 2
    faces = [(x0, mid, 1.0), (mid + 1, x1, 0.4)] if lit_side == "left" else [(x0, mid, 0.4), (mid + 1, x1, 1.0)]
    body(L, x0, x1, ytop + 3, GROUND, seed, faces, qx=(x0 + x1) // 2)
    merlons(L, x0, x1, ytop, 0.9, qx=(x0 + x1) // 2)
    for x in range(x0, x1 + 1):
        L.px(x, ytop + 3, RIM)
        KM[ytop + 3, x] = 1.1
    cast(x0, x1, ytop + 4)
    cx = (x0 + x1) / 2.0
    hgt = int((x1 - x0) * 1.05)
    for d in range(hgt):
        half = (x1 - x0 + 3) / 2.0 * (d / float(hgt))
        y = ytop + 2 - hgt + d
        a, b = int(round(cx - half)), int(round(cx + half))
        for x in range(a, b + 1):
            L.px(x, y, "roofDeep")
            lit_half = (x <= cx) == (lit_side == "left")
            KM[y, x] = 1.0 if lit_half else 0.35
            QX[y, x] = cx
        L.px(a, y, "roofLight")
        KM[y, a] = 1.1 if lit_side == "left" else 0.5
    L.px(int(round(cx)), ytop + 1 - hgt, RIM)
    KM[ytop + 1 - hgt, int(round(cx))] = 1.2
    QX[ytop + 1 - hgt, int(round(cx))] = cx


def window(L, x, y):
    """A larger window: 2 x 3, warm."""
    for dx in (0, 1):
        lit(L, x + dx, y, "fireGold")
        lit(L, x + dx, y + 1, "fireOrange")
        lit(L, x + dx, y + 2, "ember")


def house(L, x0, base, w_, wall_h, roof_h, lights):
    body(L, x0, x0 + w_ - 1, base - wall_h, base, x0, [(x0, x0 + w_ - 1, 0.55)])
    for d in range(roof_h):
        y = base - wall_h - 1 - d
        a, b = x0 - 1 + d, x0 + w_ - d
        if a > b:
            break
        for x in range(a, b + 1):
            L.px(x, y, SHADE)
            KM[y, x] = 0.5
            QX[y, x] = x0
        L.px(a, y, RIM)
    for (dx, dy, kind) in lights:
        x, y = x0 + dx, base - wall_h + dy
        if kind == "w2":
            lit(L, x, y, "fireGold"); lit(L, x, y + 1, "fireOrange")
        elif kind == "w1":
            lit(L, x, y, "fireOrange")
        elif kind == "e":
            lit(L, x, y, "ember")


def town(L):
    for (x, w_, wh, rh, li) in ((354, 11, 24, 7, [(3, 4, "w2"), (7, 4, "w2")]), (367, 8, 22, 6, [(4, 4, "w2")]),
                                (377, 10, 25, 7, [(2, 3, "w2"), (6, 3, "w1")]), (389, 7, 21, 5, [(3, 4, "w1")]),
                                (398, 9, 22, 6, [(2, 4, "w1"), (6, 4, "e")]), (409, 7, 20, 5, [(3, 4, "e")]),
                                (418, 8, 21, 5, [(4, 4, "e")]), (428, 6, 19, 4, []), (436, 7, 19, 4, [(3, 4, "e")])):
        house(L, x, 176, w_, wh, rh, li)
    cx = 384
    body(L, cx, cx + 4, 140, 175, 9, [(cx, cx + 3, 0.55), (cx + 4, cx + 4, 0.3)])
    for d in range(7):
        y = 139 - d
        a, b = cx + d // 3, cx + 4 - d // 3
        for x in range(a, b + 1):
            L.px(x, y, SHADE); KM[y, x] = 0.5; QX[y, x] = cx
        L.px(a, y, RIM)
    lit(L, cx + 2, 144, "fireGold"); lit(L, cx + 2, 145, "fireOrange")


def light_castle(L):
    """Volume first: each px takes the stone ramp in solid steps, sampled at its body's x and its course's middle,
    times its face's share; the base sinks dark into the fog. Joints one step darker, lighter stones one up."""
    a = L.a
    keep = {C(n) for n in ("fireGold", "fireOrange", "ember", "emberDim", "gold", "night0", "banner", "roofDeep",
                           "fireWhite")}
    for y in range(H):
        yq = (y // COURSE) * COURSE + COURSE // 2
        sink = max(0.25, min(1.0, (GROUND - y) / 28.0))
        for x in range(W):
            if not a[y, x, 3]:
                continue
            c = tuple(int(v) for v in a[y, x, :3])
            base = {C(RIM): RIM, C(FACE): FACE, C(SHADE): SHADE, C("roofLight"): "roofLight"}.get(c)
            if c == C("roofDeep") and KM[y, x] > 0:
                base = "roofDeep"
            if base is None:
                continue
            k = (KM[y, x] or 0.55) * sink
            i = int(t_face(QX[y, x] or x, yq) * 6.0 * k)
            if LM[y, x]:
                i += 1
            if JM[y, x] and KM[y, x] >= 0.6 and base == FACE:
                if i == 0:
                    continue
                i -= 1
            L.px(x, y, pick_solid([base] + STONE, i))


def draw_castle():
    del WINDOWS[:]
    for arr in (KM, JM, LM, QX):
        arr[:] = 0
    L = Layer()
    town(L)
    body(L, 150, 336, WALK, GROUND, 5, [(150, 336, 0.6)])
    merlons(L, 150, 336, WALK - 3, 0.7, phase=1)
    for x in range(150, 337):
        L.px(x, WALK, RIM); KM[WALK, x] = 1.05
    cast(150, 336, WALK + 1)
    body(L, 336, 452, WALK_LOW, GROUND, 7, [(336, 452, 0.55)])
    merlons(L, 336, 452, WALK_LOW - 3, 0.6, phase=2)
    for x in range(336, 453):
        L.px(x, WALK_LOW, RIM); KM[WALK_LOW, x] = 0.9
    cast(336, 452, WALK_LOW + 1)
    tower(L, 174, 191, 104, 11, "right")
    tower(L, 205, 222, 104, 12, "right")
    body(L, 192, 204, 112, GROUND, 13, [(192, 204, 0.7)], qx=198)
    merlons(L, 192, 204, 109, 0.8, phase=1, qx=198)
    cast(192, 204, 113)
    # the gate: a dark arch, a portcullis, a warm slit of the gate hall behind it
    gate = poly_mask([(193.5, GROUND + 1), (193.5, 158), (196, 154.5), (198.5, 153.5), (201, 154.5), (203.5, 158),
                      (203.5, GROUND + 1)])
    L.mask(gate, "night0")
    for y in range(160, GROUND + 1):
        lit(L, 198, y, "ember" if y > 163 else "emberDim")
    lit(L, 198, 170, "fireOrange"); lit(L, 198, 171, "fireOrange")
    for x in (195, 197, 199, 201):
        for y in range(156, GROUND + 1):
            if gate[y, x]:
                L.px(x, y, "nightDeep")
    for y in (160, 166, 172):
        for x in range(194, 203):
            if gate[y, x]:
                L.px(x, y, "nightDeep")
    tower(L, 300, 315, 106, 31, "left")
    tower(L, 336, 349, 124, 33, "left")
    # the keep: a front face falling off down the courses, its side face turned away from the light
    k0, k1 = KEEP
    body(L, k0, k1, 94, GROUND, 21, [(k0, k1 - 10, 0.95), (k1 - 9, k1, 0.4)], qx=LX)
    for x in range(k0 - 2, k1 + 3):
        for y, n in ((89, RIM), (90, FACE), (91, FACE)):
            L.px(x, y, n); KM[y, x] = 1.1 if n == RIM else 0.95; QX[y, x] = LX
    for x in range(k0, k1 + 1):
        L.px(x, 92, SHADE if (x - k0) % 3 == 2 else FACE); KM[92, x] = 0.5; QX[92, x] = LX
    cast(k0, k1, 93, 2)
    merlons(L, k0 - 2, k1 + 2, 86, 1.0, qx=LX)
    for x in range(LX - 7, LX + 8):
        L.px(x, 84, RIM); L.px(x, 85, FACE); KM[84, x] = 1.2; KM[85, x] = 1.0; QX[84, x] = QX[85, x] = LX
    # the house banner, readable: realm teal with our lantern in gold
    for y in range(98, 124):
        for x in range(255, 264):
            L.px(x, y, "roofDeep")
        L.px(255, y, "banner")
    for x in range(256, 263):
        L.px(x, 124, "roofDeep")
    for x in (256, 258, 260, 262):
        L.px(x, 125, "roofDeep")
    KM[98:126, 255:264] = 0            # the banner is cloth: it keeps its own colours
    lantern_mark = ["..g..", ".ggg.", "ggggg", "g.f.g", "gfffg", "g.f.g", "ggggg", ".g.g."]
    for r, row in enumerate(lantern_mark):
        for q, ch in enumerate(row):
            if ch != ".":
                L.px(257 + q, 102 + r, "gold" if ch == "g" else "fireOrange")
    for (x, y) in ((240, 100), (276, 104), (240, 128), (184, 120), (306, 118)):
        window(L, x, y)
    lit(L, 342, 136, "fireOrange"); lit(L, 342, 137, "ember")
    light_castle(L)
    return L


# ------------------------------------------------------------------------- layer 5: three fog bands and the near ledge
LEDGE = [(0, 176), (30, 174), (60, 178), (100, 183), (150, 187), (200, 189), (260, 190), (320, 189), (356, 186),
         (376, 182), (396, 184), (440, 186), (480, 182), (520, 179)]
FOG_BANDS = [(167, 2.0, 0.0, "far", "nightHaze"), (173, 2.4, 1.7, "nightHaze", "night2"),
             (179, 2.6, 3.1, "night2", "nightSlate")]
FOGR = ["plum", "dusk", "tileLight", "gold"]
POLE = (372, 182)


def draw_fog(dark=None):
    L = Layer()
    for (base, amp, ph, rim, body) in FOG_BANDS:
        for x in range(W):
            t = int(round(base - amp * abs(math.sin(x / 9.0 + ph)) - 1.2 * abs(math.sin(x / 4.0 + ph * 2))))
            for y in range(t, H):
                n = rim if y < t + 2 else body
                L.px(x, y, pick_air(x, y, [n] + FOGR, t_face(x, y) * (5.0 if y < t + 2 else 3.6)))
    if dark is not None:
        draw_dark(L, dark, ground=True)
    top = profile(LEDGE)
    for x in range(W):
        t = int(round(top[x]))
        for y in range(t, H):
            L.px(x, y, "nightDeep")
        if x and top[x] <= top[x - 1]:
            L.px(x, t, "nightBlue")
    for (x, hgt, lean) in ((44, 5, 1), (47, 7, 0), (50, 4, -1), (118, 5, 1), (121, 3, 0), (232, 3, 0), (236, 5, 1),
                           (300, 4, -1), (352, 5, 1), (355, 8, 0), (358, 6, 1), (366, 4, -1), (384, 6, 0),
                           (388, 4, 1), (428, 5, -1), (431, 7, 0), (470, 4, 1)):
        b = int(round(top[x]))
        for k in range(hgt):
            L.px(x + (lean * k) // 3, b - 1 - k, "nightDeep")
        L.px(x + 1, b - 1, "nightDeep")
    px0, py0 = POLE
    for k in range(46):
        x = px0 - k // 9
        L.px(x, py0 - k, "nightDeep")
        if k < 30:
            L.px(x + 1, py0 - k, "nightDeep")
    tx, ty = px0 - 5, py0 - 45
    for x in range(tx - 1, tx + 8):
        L.px(x, ty, "nightDeep")
    L.px(tx - 1, ty - 1, "nightDeep"); L.px(tx + 7, ty - 1, "nightDeep")
    for y in range(ty + 1, ty + 15):
        w_ = 6 if y < ty + 10 else (4 if y < ty + 13 else 2)
        for x in range(tx + 1, tx + 1 + w_):
            if not (y > ty + 9 and x == tx + 3):
                L.px(x, y, "nightDeep")
        L.px(tx + 1, y, "nightBlue" if y < ty + 12 else "nightDeep")
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


GLOW_SCALE = {0: 0.0, 1: 0.08, 2: 0.15, 3: 0.24, 4: 0.36, 5: 0.5, 6: 0.66, 7: 0.68}   # of AIR_R, per step
LOAD = ["plumDeep", "plum", "dusk", "tileLight", "gold", "fireGold"]


def lantern_glow(step, w=WIN_W, hh=H, cx=None, cy=None):
    """The loading glow: the same dithered falloff as the title's air, on the night, scaled with the fire's step.
    Window-sized (437 x 201), opaque palette pixels where lit, transparent elsewhere; the flame at (218, 76)."""
    cx = LX - WIN_X if cx is None else cx
    cy = LY if cy is None else cy
    s = GLOW_SCALE[step]
    a = np.zeros((hh, w, 4), np.uint8)
    if s <= 0:
        return Image.fromarray(a)
    rx, ry = AIR_R[0] * s, AIR_R[1] * s
    for y in range(hh):
        for x in range(w):
            e = math.hypot((x - cx) / rx, (y - cy) / ry)
            if e >= 1:
                continue
            p = (1 - e) ** 1.35 * 6.2
            c = pick_air(x, y, [None] + LOAD, p)
            if c:
                a[y, x, :3] = C(c)
                a[y, x, 3] = 255
    return Image.fromarray(a)


# ---------------------------------------------------------------------------------------------- the small figures
def lord(frame):
    """9 x 16, feet on the bottom row: the lord on the keep's top, right of the eternal light, facing it (left). He
    stands dark against the gold air: brown hair, the face lit on the flame's side, the house's teal cloak to the
    calves with a warm rim on his left and night blue on his right, the legs behind the merlons. The house's hand
    lantern (2 x 3: the bail, the glass with one fireWhite pixel in sprite column 0, the base) hangs low at his side in frame 0 and goes up in answer to
    a touch: 1 at his chest, 2 at his shoulder, 3 above his head at arm's length, flaring. It is never in front of his
    head: a column of air stays between his arm and his face."""
    L = Layer(9, 16)
    key = {"h": "wood", "H": "woodDark", "G": "gold", "S": "dawnRose", "s": "tileLight", "R": "tileLight",
           "r": "tile", "U": "banner", "T": "roofDeep", "N": "nightBlue", "D": "nightDeep", "L": "woodDark", "F": "fireWhite",
           "f": "fireGold"}
    body = [".........",
            ".........",
            "....hH...",
            "...hGHH..",
            "...SSHH..",
            "...sSH...",
            "..RUTTNN.",
            "..RUTTNN.",
            "..RUTTNN.",
            "..rUTTNN.",
            "..rUTTNNN",
            "..rUTTNNN",
            "..rUTTNNN",
            "...D.D...",
            "...D.D...",
            "...D.D..."]
    for y, row in enumerate(body):
        for x, ch in enumerate(row):
            if ch != ".":
                L.px(x, y, key[ch])
    ly = LORD_LANTERN_Y[frame]
    glass = ("F", "F") if frame == 3 else ("F", "f")
    for dy, cells in ((-1, (".", "L")), (0, glass), (1, ("L", "L"))):
        for dx, ch in enumerate(cells):
            if ch != ".":
                L.px(dx, ly + dy, key[ch])
    if frame == 0:
        L.px(1, ly - 2, "dawnRose")                             # the hand on the bail, the arm in the cloak
    else:
        L.px(1, ly + 2, "dawnRose")                             # the hand under the lantern
        for y in range(ly + 3, 6):
            L.px(1, y, "roofDeep")                              # the raised arm in its sleeve
    return L


LORD_LANTERN_Y = {0: 11, 1: 7, 2: 3, 3: 1}


def lord_light(frame):
    """His lantern's own small glow, 15 x 15 centred on the lantern's bright pixel (sprite column 0, its row): a
    few dithered steps brighter than the gold air (fireGold, then fireWhite at the core), never a dark ring."""
    a = np.zeros((15, 15, 4), np.uint8)
    big = 1.4 if frame == 3 else 1.0
    for y in range(15):
        for x in range(15):
            d = math.hypot(x - 7, (y - 7) * 1.1) / big
            p = max(0.0, 1 - d / 4.0) * 2.4
            c = pick_air(x, y, [None, "fireGold", "fireWhite"], p)
            if c:
                a[y, x, :3] = C(c)
                a[y, x, 3] = 255
    return Image.fromarray(a)


def sentry(rim_side):
    """7 x 14: a small guard, 8 px from helmet to boots, with a spear taller than he is; facing left. The helmet and
    the side toward the flame catch it."""
    L = Layer(7, 14)
    L.px(1, 0, "stonePale"); L.px(1, 1, "stoneLight")
    for y in range(2, 14):
        L.px(1, y, "woodDark")
    for x in (3, 4):
        L.px(x, 6, "stoneMid")
    for x in (2, 3, 4, 5):
        L.px(x, 7, "stoneMid")
    L.px(2 if rim_side == "left" else 5, 7, "stoneLight")
    L.px(3, 8, "tileLight"); L.px(4, 8, "nightDeep")
    for y in (9, 10, 11):
        for x in (2, 3, 4, 5):
            if not (y == 9 and x in (2, 5)):
                L.px(x, y, "roofDeep" if x < 5 else "nightDeep")
    L.px(2, 10, "tileLight")                                 # the hand on the spear
    rim = 5 if rim_side == "right" else 2
    L.px(rim, 10, "tile"); L.px(rim, 11, "tile")
    for y in (12, 13):
        L.px(3, y, "nightDeep"); L.px(5, y, "nightDeep")
    return L


LORD_POS = (275, 88)            # on the keep's top, right of the beacon, his feet behind the merlons
SENTRIES = [((226, WALK), "right"), ((324, WALK), "left")]


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
    """The parapets drawn again over the walkers: the wall walk's (sentries) and the keep's crown (the lord)."""
    a = np.array(castle)
    f = np.zeros_like(a)
    f[WALK - 3:WALK + 1, 150:337] = a[WALK - 3:WALK + 1, 150:337]
    for (x0, x1) in ((172, 224), (KEEP[0] - 3, KEEP[1] + 4), (298, 317)):
        f[:, x0:x1] = 0
    f[86:89, KEEP[0] - 2:KEEP[1] + 3] = a[86:89, KEEP[0] - 2:KEEP[1] + 3]
    return Image.fromarray(f)


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
    img = over(img, lord_light(lord_frame), lx0 - 7, ly0 + LORD_LANTERN_Y[lord_frame] - 7)
    img = over(img, lf.image(), lx0, ly0)
    img = over(img, layers["front"], o("castle"))
    img = over(img, layers["fog"], o("fog"))
    if letters is not None:
        img = over(img, letters)
    return img


def build_all():
    dm = dark_mask()
    rock = draw_rock()
    draw_dark(rock, dm)
    layers = {"sky": draw_sky().image(), "far": draw_far().image(), "rock": rock.image(),
              "castle": draw_castle().image(), "fog": draw_fog(dm).image()}
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
        lord_light(f).save(os.path.join(outdir, "titleLordLight%d.png" % f))   # 15 x 15, centred on his lantern
    sprites["sentryA"].image().save(os.path.join(outdir, "titleSentryA.png"))
    sprites["sentryB"].image().save(os.path.join(outdir, "titleSentryB.png"))
    li = Image.new("RGBA", (LW, 69), (0, 0, 0, 0))     # 13 x 69: centred on the screen, the flame lands at y 76
    li.paste(sprites["lantern0"].image(), (0, 0))
    li.save(os.path.join(outdir, "launchLantern.png"))
    meta = {
        "picture": [W, H], "window": [WIN_X, 0, WIN_W, H], "eternalLight": [LX, LY], "airGlow": AIR_R,
        "faceReach": FACE_R, "launchColour": "#%02X%02X%02X" % C(DARK),
        "beacon": {"topLeft": list(BEACON_XY), "size": [LW, LH], "flame": [LFX, LFY]},
        "lettering": {"box": [crop[0], crop[1], crop[2] - crop[0], crop[3] - crop[1]], "order": WORD,
                      "letters": [[b[0] - 1, b[1] - 1, b[2] + 2, b[3] + 2] for b in boxes]},
        "lanternGlow": {"size": [WIN_W, H], "origin": "window (0, 0)", "scaleOfAirGlow": GLOW_SCALE},
        "lord": {"feet": list(LORD_POS), "size": [9, 16], "lanternPixel": {"x": 0, "y": LORD_LANTERN_Y},
                 "light": {"size": [15, 15], "centre": [7, 7]}},
        "sentries": [{"feet": list(p), "size": [7, 14], "sprite": "titleSentryA" if s == "right" else "titleSentryB"}
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
    s = over(s, lantern_glow(step))
    return over(s, lantern(step).image(), LX - WIN_X - LFX, LY - LFY)


REVEAL_FRAY = 16


def reveal(win, R):
    """The picture opens from the loading screen in an ellipse of the air glow's shape (R in game px along the
    long axis): inside, the picture; over the next 16 px the two meet in the 4x4 ordered dither; beyond, the loading
    screen (the night and the beacon's glow)."""
    pic = np.array(win.convert("RGBA"))
    base = np.array(lantern_screen(6))
    out = base.copy()
    asp = AIR_R[1] / AIR_R[0]
    for y in range(H):
        for x in range(WIN_W):
            d = math.hypot(x - (LX - WIN_X), (y - LY) / asp)
            f = (R - d) / REVEAL_FRAY + 1.0
            if f >= 1 or (f > 0 and BAYER[y % 4][x % 4] < int(f * 16)):
                out[y, x] = pic[y, x]
    return Image.fromarray(out)


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


def write_proofs(proofdir=PROOF, sfx="-r5", which="title"):
    os.makedirs(proofdir, exist_ok=True)
    layers, sprites, unlit, litl, boxes = build_all()
    if which in ("loading", "all"):
        save_proof(big6(lantern_screen(0)), "01-launch" + sfx, proofdir)
        save_proof(big6(lantern_screen(2)), "02-loading-small" + sfx, proofdir)
        save_proof(big6(lantern_screen(6)), "03-loading-full" + sfx, proofdir)
    pic_unlit = window_of(scene(layers, sprites, letters=unlit))
    save_proof(big6(reveal(pic_unlit, 150)), "04-glow-half" + sfx, proofdir)
    save_proof(big6(pic_unlit), "05-title-unlit" + sfx, proofdir)
    pic_lit = window_of(scene(layers, sprites, letters=litl))
    save_proof(gear(touch_line(big6(pic_lit))), "06-title" + sfx, proofdir)
    pic_raise = window_of(scene(layers, sprites, letters=litl, lord_frame=3))
    save_proof(gear(big6(pic_raise)), "07-lord-raises" + sfx, proofdir)
    ph = pic_lit.resize((874, 402), Image.NEAREST).convert("RGB")
    ph.save(os.path.join(proofdir, "_phone-874" + sfx + ".png"))
    ph.save(os.path.join(proofdir, "_phone-874" + sfx + ".jpg"), quality=88)
    pic_lit.crop((110, 40, 290, 150)).resize((720, 440), Image.NEAREST).convert("RGB").save(
        os.path.join(proofdir, "_zoom-keep" + sfx + ".png"))


if __name__ == "__main__":
    what = sys.argv[1] if len(sys.argv) > 1 else "all"
    if what in ("art", "all"):
        write_art()
    if what in ("proof", "all"):
        write_proofs(which=sys.argv[2] if len(sys.argv) > 2 else "title")
