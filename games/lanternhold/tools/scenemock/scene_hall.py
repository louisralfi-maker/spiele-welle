#!/usr/bin/env python3
"""Preview scenes of look 2's stage 8 (ART-look2.md section 20): the great hall as its own stage and the marks of
"touch the world". A small renderer of its own (mock.py draws the open world; the hall is an interior stage): albedo
sprites under a night ambient and quantized warm point lights, unlit flames and marks over them, the near pillars
dark and with a parallax, the night sky and the Weltmauer behind the hall's transparent window lights.

    python3 -I -B scene_hall.py <games/lanternhold> <scene> <out.png>

Scenes (main() at the foot): audience-old, audience, audience-card, wide, marks-hall, marks-front, front-old, walk-old.
Pure python, one render at a time (the heat rule). The pictures are previews, not the engine: the light is the
renderer's rule of thumb (mock.py's falloff and four steps)."""
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.dirname(HERE))
from pngr import read_png  # noqa: E402
from pngw import write_png  # noqa: E402
import hallart as HA  # noqa: E402
from roomart import rnd  # noqa: E402

G, SCENE, OUT = sys.argv[1], sys.argv[2], sys.argv[3]
ART = os.path.join(G, "Resources", "Art")


def hexc(s):
    return tuple(int(s[i:i + 2], 16) / 255.0 for i in (0, 2, 4))


FIRE_WHITE, FIRE_GOLD, FIRE_ORANGE, EMBER = hexc("FFF2C2"), hexc("FFC65A"), hexc("FF8A2A"), hexc("D9481F")
NIGHT_DEEP, NIGHT_SLATE, NIGHT_HAZE = hexc("0A1124"), hexc("1E2B52"), hexc("2F3F72")
HEARTH = (1.0, 0.62, 0.25)
AMB_IN = (0.30, 0.32, 0.47)     # the hall at night: moonlight through the windows, a little bounce
AMB_OUT = (0.34, 0.38, 0.60)
KIND = dict(candle=(14, FIRE_GOLD, 0.55), stand=(30, FIRE_GOLD, 0.8), chandelier=(64, FIRE_GOLD, 0.95),
            torch=(34, (1.0, 0.7, 0.3), 0.9), hearth=(120, HEARTH, 1.5), lantern=(44, FIRE_GOLD, 1.1),
            brazier=(56, FIRE_ORANGE, 1.1), pool=(20, FIRE_GOLD, 0.7))
TORCH = ("..o..", ".ogo.", ".ogo.", "ogwgo", "ogwgo", ".gwg.")
SMALL_FIRE = ("....o....", "...og.o..", "..ogg.o..", ".oggwgo..", ".ogwwgoo.", "ogwwwwgo.", "ogwwwwggo")
FLAME = {"w": FIRE_WHITE, "g": FIRE_GOLD, "o": FIRE_ORANGE, "e": EMBER}


def lerp(a, b, t):
    return tuple(a[i] + (b[i] - a[i]) * t for i in range(3))


def load(name):
    w, h, rows, _ = read_png(os.path.join(ART, name + ".png"))
    return (w, h, rows)


def cut(img, i, fw):
    w, h, rows = img
    return (fw, h, [r[i * fw:(i + 1) * fw] for r in rows])


def fr(name, i, fw):
    return cut(load(name), i, fw)


class Stage:
    def __init__(self, w, h, amb):
        self.w, self.h, self.amb = w, h, amb
        self.alb = [[None] * w for _ in range(h)]
        self.over = [[None] * w for _ in range(h)]   # unlit pixels over the lit picture: flames, glow strips, marks
        self.lights = []                             # (x, y, radius, colour, strength)
        self.near = []                               # the near pillars' x at parallax 1

    def draw(self, img, x, y, over=False, flip=False):
        w, h, rows = img
        buf = self.over if over else self.alb
        for j in range(h):
            yy = y + j
            if not 0 <= yy < self.h:
                continue
            row = rows[j]
            for i in range(w):
                p = row[w - 1 - i] if flip else row[i]
                if p[3] == 0:
                    continue
                xx = x + i
                if 0 <= xx < self.w:
                    buf[yy][xx] = (p[0] / 255.0, p[1] / 255.0, p[2] / 255.0)
                    if not over:
                        self.over[yy][xx] = None

    def stand(self, img, cx, feet, flip=False, over=False):
        """Centred on cx, the sprite's lowest row is feet - 1."""
        x = int(round(cx - img[0] / 2.0))
        self.draw(img, x, feet - img[1], over, flip)
        return x, feet - img[1]

    def rim(self, img, cx, feet, flip=False, colour=(0.86, 0.63, 0.27)):
        """The touchable's warm rim: one pixel round the sprite's outline, unlit."""
        w, h, rows = img
        x0, y0 = int(round(cx - w / 2.0)), feet - h
        solid = set()
        for j in range(h):
            for i in range(w):
                if (rows[j][w - 1 - i] if flip else rows[j][i])[3]:
                    solid.add((i, j))
        for (i, j) in solid:
            for q in ((i + 1, j), (i - 1, j), (i, j - 1)):
                if q not in solid:
                    xx, yy = x0 + q[0], y0 + q[1]
                    if 0 <= xx < self.w and 0 <= yy < self.h:
                        self.over[yy][xx] = colour

    def light(self, kind, x, y, r=None, k=1.0):
        rr, col, s = KIND[kind]
        self.lights.append((x, y, r or rr, col, s * k))

    def flame(self, kind, x, y, f=0):
        if kind == "candle":
            self.over[y][x] = FIRE_WHITE
            self.over[y - 1][x] = FIRE_GOLD
            return
        rows = TORCH if kind == "torch" else SMALL_FIRE
        for j, row in enumerate(rows):
            for i, ch in enumerate(row):
                if ch in FLAME:
                    self.over[y - len(rows) + 1 + j][x - len(row) // 2 + i] = FLAME[ch]

    def bitmap(self, rows, x, y, legend, over=False):
        buf = self.over if over else self.alb
        for j, row in enumerate(rows):
            for i, ch in enumerate(row):
                if ch in legend:
                    buf[y + j][x + i] = legend[ch]


def render(st, view, scale, backdrop):
    x0, y0, vw, vh = view
    L = [[list(st.amb) for _ in range(vw)] for _ in range(vh)]
    for (lx, ly, r, col, k) in st.lights:
        for y in range(max(0, int(ly - r / 1.25) - y0), min(vh, int(ly + r / 1.25) + 2 - y0)):
            dy = (y + y0 - ly) * 1.25
            row = L[y]
            for x in range(max(0, int(lx - r) - x0), min(vw, int(lx + r) + 2 - x0)):
                dx = x + x0 - lx
                d = math.sqrt(dx * dx + dy * dy) / r
                if d >= 1.0:
                    continue
                t = (1.0 - d) ** 2
                if t < 0.04:
                    continue
                q = 0.16 if t < 0.18 else (0.42 if t < 0.4 else (0.72 if t < 0.66 else 1.0))
                c = row[x]
                c[0] += col[0] * k * q
                c[1] += col[1] * k * q
                c[2] += col[2] * k * q
    pic = []
    for y in range(vh):
        line = []
        for x in range(vw):
            sx, sy = x0 + x, y0 + y
            a = st.alb[sy][sx]
            if a is None:
                c = backdrop(sx, sy)
            else:
                li = L[y][x]
                c = (a[0] * li[0], a[1] * li[1], a[2] * li[2])
            e = st.over[sy][sx]
            if e is not None:
                c = e
            line.append(c)
        pic.append(line)
    if st.near:
        pil = load("hallPillarNear")
        cam = x0 + vw / 2.0
        for px in st.near:
            left = int(round(vw / 2.0 + (px - cam) * 1.25)) - pil[0] // 2
            for j in range(pil[1]):
                y = j - y0
                if not 0 <= y < vh:
                    continue
                for i in range(pil[0]):
                    p = pil[2][j][i]
                    x = left + i
                    if p[3] and 0 <= x < vw:
                        li = L[y][x]
                        pic[y][x] = tuple(p[n] / 255.0 * (st.amb[n] * 0.6 + (li[n] - st.amb[n]) * 0.12) for n in range(3))
    out = []
    cx, cy = vw / 2.0, vh / 2.0
    for y in range(vh):
        line = bytearray()
        for x in range(vw):
            v = 1.0 - 0.3 * (((x - cx) / cx) ** 2 * 0.6 + ((y - cy) / cy) ** 2 * 0.4) ** 1.5
            px = bytearray()
            for n in range(3):
                c = pic[y][x][n] * v
                if c > 0.8:
                    c = 0.8 + 0.2 * (1.0 - math.exp(-(c - 0.8) / 0.25))
                px.append(max(0, min(255, int(c * 255 + 0.5))))
            px.append(255)
            line += bytes(px) * scale
        for _ in range(scale):
            out.append(bytearray(line))
    write_png(OUT, vw * scale, vh * scale, out)
    print("wrote", OUT, vw * scale, "x", vh * scale)


def sky(welt, wall_top, shift, ground=None):
    """The night behind the stage: a deep blue sky, stars, the moonlit Weltmauer (its sprite's top row at wall_top)."""
    ww, wh, wrows = welt

    def f(sx, sy):
        if ground is not None and sy >= ground:
            return (0.035, 0.035, 0.06)
        c = lerp(NIGHT_DEEP, NIGHT_SLATE, min(1.0, max(0.0, (sy - 10) / 130.0)))
        if rnd(91, sx, sy) < 0.03:
            c = lerp(c, (0.85, 0.9, 1.0), 0.35 + 0.6 * rnd(92, sx, sy))
        wy = sy - wall_top
        if 0 <= wy < wh:
            p = wrows[wy][(sx + shift) % ww]
            if p[3]:
                c = (p[0] / 255.0 * 0.36 + 0.02, p[1] / 255.0 * 0.44 + 0.03, p[2] / 255.0 * 0.74 + 0.07)
        return c
    return f


# ------------------------------------------------------------------------------------------------------ the hall

def new_hall(chandeliers=True, stands=(0, 1, 2, 3), hearth=1.0, lord="seated", court=True, queue=True, walker=318,
             marks=None, pressed=None, who=None):
    st = Stage(HA.W, HA.H, AMB_IN)
    st.draw(load("greatHall"), 0, 0)
    floor, dais, wall = HA.FLOOR, HA.FLOOR - HA.RISE, HA.WALL + 6
    marks = marks or ()

    def mark(name, cx, top, press=False):
        st.stand(fr(name, 1 if press else 0, 15), cx, top - 3, over=True)

    # the lights and flames painted into the hall
    for an in HA.great_hall().anchors:
        kind, what, x, y = an[0], an[1], an[2], an[3]
        on_chandelier = y < 50 and any(abs(x - cx) <= 17 for cx in HA.CHANDELIERS)
        stand = [i for i, sx in enumerate(HA.STANDS) if abs(x - sx) <= 3 and y > 120]
        lit = True
        if on_chandelier or what == "chandelier":
            lit = chandeliers
        if stand or what == "stand":
            lit = (stand[0] if stand else [i for i, sx in enumerate(HA.STANDS) if sx == x][0]) in stands
        if not lit:
            continue
        if kind == "light":
            st.light(what, x, y, an[4], k=hearth if what == "hearth" else 1.0)
        elif what == "hallFire":
            st.stand(fr("hallFire", 2, 34), x, y + 1, over=True)
        else:
            st.flame(what, x, y)
    # at the wall: benches with the waiting, the guards at the door
    bench = load("bench")
    for cx in HA.WINDOWS:
        st.stand(bench, cx, wall)
    st.stand(fr("guardsman", 0, 14), 37, wall)
    st.stand(fr("guardsman", 0, 14), 100, wall, flip=True)
    if queue:
        sit = [("citizenSeated", 176, 0), ("citizenBSeated", 191, 1), ("citizenCSeated", 293, 0)]
        for name, cx, f in sit:
            img = fr(name, f, 12)
            st.stand(img, cx, wall)
            if "talk" in marks:
                st.rim(img, cx, wall)
        if "talk" in marks:
            st.light("pool", 184, wall - 5)
            st.light("pool", 293, wall - 5)
            mark("tapTalk", 184, wall - 22)
    st.stand(fr("pip", 6, 12), 350, wall + 2)
    # the dais: the throne, the lord, the court in its places
    throne = load("throne")
    st.stand(throne, HA.THRONE_X, dais)
    if lord == "seated":
        st.stand(fr("kingSeated", 2, 16), HA.THRONE_X, dais, flip=True)
        st.stand(fr("kingSeatedGlow", 2, 16), HA.THRONE_X, dais, flip=True, over=True)
        st.light("lantern", HA.THRONE_X - 5.5, dais - 22.5)
    elif "throne" in marks:
        st.rim(throne, HA.THRONE_X, dais)
        st.light("pool", HA.THRONE_X, dais - 5)
        mark("tapThrone", HA.THRONE_X, dais - 24, pressed == "throne")
    if court:
        st.stand(load("taxLectern"), 385, dais)
        st.stand(fr("odile", 0, 14), 397, dais, flip=True)
        st.stand(fr("brannock", 0, 16), 441, dais, flip=True)
        st.stand(fr("hesper", 0, 14), 497, dais)
        st.stand(fr("hesperGlow", 0, 14), 497, dais, over=True)
    if walker:
        img = fr(*who) if who else fr("petitionerD", 1 if lord == "seated" else 4, 12)
        st.stand(img, walker, floor)
        if who:                                  # the one who has the word stands in the glow
            st.light("pool", walker, floor - 8, 30)
        if "talk" in marks:
            st.rim(img, walker, floor)
            st.light("pool", walker, floor - 5)
            mark("tapTalk", walker, floor - 26, pressed == "talk")
    if isinstance(lord, int):
        st.stand(fr("king", 0, 16), lord, floor)
        st.stand(fr("kingGlow", 0, 16), lord, floor, over=True)
        st.light("lantern", lord + 5.5, floor - 23)
    return st


def old_hall(lord="seated"):
    """Today's hall (hallInterior, 260x90) as today's screen shows it: 437x201, the hall on the ground line."""
    st = Stage(437, 201, AMB_IN)
    ox, floor = 88, 175
    st.draw(load("hallInterior"), ox, floor - 90)
    ground = load("ground")
    for x in range(0, 437, 64):
        st.draw(ground, x, floor)
    st.draw(load("throne"), ox + 117, floor - 24)
    st.draw(load("hearth"), ox + 170, floor - 20)
    st.flame("fire", ox + 183, floor - 5)
    st.light("hearth", ox + 183, floor - 10, 70, k=0.8)
    for cx in (58, 98, 228):
        for y in range(floor - 15, floor):
            st.alb[y][ox + cx] = (0.18, 0.19, 0.24)
        st.flame("candle", ox + cx, floor - 16)
        st.light("candle", ox + cx, floor - 17, 12)
    for name, cx, f, fw in (("citizenC", 38, 4, 12), ("citizen", 51, 5, 12), ("petitionerE", 66, 4, 12),
                            ("citizenB", 79, 4, 12)):
        st.stand(fr(name, f, fw), ox + cx, floor)
    st.stand(fr("petitionerD", 4, 12), ox + 100, floor)
    if lord == "seated":
        st.stand(fr("kingSeated", 2, 16), ox + 124, floor, flip=True)
        st.stand(fr("kingSeatedGlow", 2, 16), ox + 124, floor, flip=True, over=True)
        st.light("lantern", ox + 124 - 5.5, floor - 22.5)
    else:
        st.stand(fr("king", 0, 16), ox + lord, floor)
        st.stand(fr("kingGlow", 0, 16), ox + lord, floor, over=True)
        st.light("lantern", ox + lord + 5.5, floor - 23)
    st.stand(fr("odile", 0, 14), ox + 143, floor, flip=True)
    return st


def front(marks=True):
    """The front at night: an open plot, a damaged wall, a cold brazier, a townsman to recruit; every touchable with
    its rim, its pool and its mark."""
    st = Stage(437, 201, AMB_OUT)
    floor = 175
    ground = load("ground")
    for x in range(0, 437, 64):
        st.draw(ground, x, floor)

    def mark(name, cx, top, press=False):
        st.stand(fr(name, 1 if press else 0, 15), cx, top - 3, over=True)

    def touch(img, cx, name, press=False, flip=False):
        st.stand(img, cx, floor, flip=flip)
        if marks:
            st.rim(img, cx, floor, flip=flip)
            st.light("pool", cx, floor - 5)
            mark(name, cx, floor - img[1], press)

    touch(load("plotMarker"), 86, "tapBuild")
    touch(fr("citizen", 4, 12), 150, "tapRecruit")
    st.stand(fr("king", 0, 16), 214, floor)
    st.stand(fr("kingGlow", 0, 16), 214, floor, over=True)
    st.light("lantern", 214 + 5.5, floor - 23)
    touch(load("brazier"), 268, "tapLight", press=True)
    touch(fr("stoneWall", 1, 36), 352, "tapRepair")
    st.stand(fr("guardsman", 0, 14), 316, floor)
    return st


def main():
    welt = load("weltmauer")
    hall_sky = sky(welt, 62, 150)
    if SCENE == "audience-old":
        render(old_hall(), (0, 0, 437, 201), 3, sky(welt, 20, 260, ground=201))
    elif SCENE == "walk-old":
        render(old_hall(lord=70), (0, 0, 437, 201), 3, sky(welt, 20, 260, ground=201))
    elif SCENE == "audience":
        st = new_hall()
        st.near = [254]
        render(st, (232, 50, 328, 151), 4, hall_sky)
    elif SCENE == "audience-card":
        st = new_hall(walker=338, who=("tamsin", 0, 14))
        st.near = [254]
        render(st, (232, 50, 328, 151), 4, hall_sky)
    elif SCENE == "wide":
        st = new_hall(chandeliers=False, stands=(2,), lord=300, queue=False, walker=None)
        st.near = [161, 254]
        render(st, (0, 0, 600, 201), 3, hall_sky)
    elif SCENE == "marks-hall":
        st = new_hall(lord=262, marks=("talk", "throne"), pressed="talk", walker=326)
        st.near = [254]
        render(st, (163, 0, 437, 201), 3, hall_sky)
    elif SCENE == "marks-front":
        render(front(), (0, 0, 437, 201), 3, sky(welt, 22, 40, ground=201))
    elif SCENE == "front-old":
        render(front(marks=False), (0, 0, 437, 201), 3, sky(welt, 22, 40, ground=201))
    else:
        raise SystemExit("unknown scene " + SCENE)


main()
