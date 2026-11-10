#!/usr/bin/env python3
"""Lanternhold portraits (M3 art lane, step 2): the audience card's story portraits and the composed portrait parts,
all on one head template (SPRITES.md "M3", "Portraits"; ART-court.md "Portraits").

Every portrait is a 48x48 bust turned three-quarters to the right and lit warmly from the left (the hall's hearth side).
The forms are rendered, then finished by hand: each part is a few signed-distance primitives (an ellipsoid cranium, a
jaw, a nose, a hair shell, a hat's brim ...) ray-marched in an orthographic view at one unit per pixel, lit from the
upper left (Lambert with a little wrap, ambient occlusion), and the light is cut into the material's palette ramp.
Hand-set stamps put the features on the form at the template's projected points (eyes, brows, mouths, scars,
wrinkles, buttons, emblems), and hand-set patches finish what a render cannot say. The head template (`portraitkit.py`:
cranium, eye line, mouth line, ear, neck and the shoulder line) is the same in every part and every story portrait, so
the composed parts fit each other and the story portraits share their scale and style.

Pure python 3 (pixelart.py's PNG and palette code), deterministic: the same call writes the same bytes. One sprite per
run; a part strip renders in well under 20 s on this Mac.

  portraitart.py build <id> [--out DIR]
        Renders one sprite id into DIR/<id>.png (default games/lanternhold/Resources/Art).
  portraitart.py list
        The ids, for build-art-court.sh.
  portraitart.py freeze <id> <out.txt> [--from PNG]
        Writes a story portrait (the render, or PNG) as an actorart.py spec: one 48x48 text grid per frame with the
        fixed legend FREEZE_LETTERS. Since the fix stage the 13 story portraits are frozen grids in
        tools/grids/court/portraits/, hand-finished there and built by actorart.py; `build` renders a story id only as
        a draft (pass --out).
  portraitart.py sheet story|composed|parts|archetypes <out.png> [--art DIR] [--scale 3] [--n 30] [--seed 1]
        Contact sheets on the audience card's framed dusk tile: every story portrait; random composed petitioners
        exactly as the code composes them (clothes, face, beard, hair, hat, the "none" frames skipped, each swap ramp
        mapped colour for colour to a target ramp of SPRITES.md); every part frame on the template; the code lane's
        townsfolk archetypes.
"""
import argparse
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from pixelart import Image, Palette, read_png, write_png, DEFAULT_PALETTE  # noqa: E402

GAME = os.path.dirname(HERE)
ART = os.path.join(GAME, "Resources", "Art")
W = H = 48
PAL = Palette(DEFAULT_PALETTE, True, allow_swap=True)


# ------------------------------------------------------------------------------------------------------------ maths

def length(x, y, z):
    return math.sqrt(x * x + y * y + z * z)


def clamp(v, a, b):
    return a if v < a else b if v > b else v


def mix(a, b, t):
    return a + (b - a) * t


def smoothstep(a, b, x):
    t = clamp((x - a) / (b - a), 0.0, 1.0)
    return t * t * (3 - 2 * t)


def smin(a, b, k):
    if k <= 0:
        return a if a < b else b
    h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0)
    return mix(b, a, h) - k * h * (1.0 - h)


def smax(a, b, k):
    return -smin(-a, -b, k)


def hash01(*v):
    """A deterministic value in [0, 1) from integers (textures: hair strands, straw, rags)."""
    h = 2166136261
    for x in v:
        h = ((h ^ (int(x) & 0xFFFFFFFF)) * 16777619) & 0xFFFFFFFF
    h ^= h >> 13
    h = (h * 1274126177) & 0xFFFFFFFF
    h ^= h >> 16
    return (h & 0xFFFF) / 65536.0


def sd_ellipsoid(p, c, r):
    x, y, z = p[0] - c[0], p[1] - c[1], p[2] - c[2]
    k0 = length(x / r[0], y / r[1], z / r[2])
    k1 = length(x / (r[0] * r[0]), y / (r[1] * r[1]), z / (r[2] * r[2]))
    if k1 == 0:
        return -min(r)
    return k0 * (k0 - 1.0) / k1


def sd_sphere(p, c, r):
    return length(p[0] - c[0], p[1] - c[1], p[2] - c[2]) - r


def sd_capsule(p, a, b, r, r2=None):
    """A capsule from a to b; with r2 a round cone (radius r at a, r2 at b)."""
    pa = (p[0] - a[0], p[1] - a[1], p[2] - a[2])
    ba = (b[0] - a[0], b[1] - a[1], b[2] - a[2])
    bb = ba[0] * ba[0] + ba[1] * ba[1] + ba[2] * ba[2]
    h = clamp((pa[0] * ba[0] + pa[1] * ba[1] + pa[2] * ba[2]) / bb, 0.0, 1.0) if bb else 0.0
    rr = r if r2 is None else mix(r, r2, h)
    return length(pa[0] - ba[0] * h, pa[1] - ba[1] * h, pa[2] - ba[2] * h) - rr


def sd_box(p, c, b, r=0.0):
    q = (abs(p[0] - c[0]) - b[0], abs(p[1] - c[1]) - b[1], abs(p[2] - c[2]) - b[2])
    return length(max(q[0], 0), max(q[1], 0), max(q[2], 0)) + min(max(q[0], max(q[1], q[2])), 0) - r


def sd_cyl(p, c, r, h, rr=0.0):
    """A cylinder on the y axis through c: radius r, half height h, edges rounded by rr."""
    dx = math.hypot(p[0] - c[0], p[2] - c[2]) - r + rr
    dy = abs(p[1] - c[1]) - h + rr
    return min(max(dx, dy), 0) + length(max(dx, 0), max(dy, 0), 0) - rr


def sd_torus(p, c, R, r):
    """A torus around the y axis through c (ring radius R, tube r)."""
    q = math.hypot(p[0] - c[0], p[2] - c[2]) - R
    return math.hypot(q, p[1] - c[1]) - r


def chain(p, pts, r, r2=None, k=0.0):
    """A smooth chain of capsules through the points (a feather, a braid's core, a horn); radius from r to r2."""
    d = 1e9
    n = len(pts) - 1
    for i in range(n):
        ra = r if r2 is None else mix(r, r2, i / n)
        rb = r if r2 is None else mix(r, r2, (i + 1) / n)
        d = smin(d, sd_capsule(p, pts[i], pts[i + 1], ra, rb), k)
    return d


class Frame:
    """A local frame: local +z turned `yaw` degrees towards +x (the image's right), tipped `pitch` degrees (positive
    tips the front down), rolled `roll` degrees (positive leans the top to the right), around `centre`; one local unit
    is `scale` pixels (a local distance times `ds` is a world distance). `squash` foreshortens the far half (local
    x > 0) as a portraitist does in a three-quarter view, so the far eye sits near the contour and the nose breaks
    it; distances are then scaled down with it, so the ray march stays conservative."""

    def __init__(self, centre, yaw=0.0, pitch=0.0, roll=0.0, scale=1.0, squash=1.0):
        self.c = centre
        self.s = scale
        self.k = squash
        self.ds = scale * min(1.0, squash)
        t, q, r = math.radians(yaw), math.radians(pitch), math.radians(roll)
        self.ct, self.st = math.cos(t), math.sin(t)
        self.cq, self.sq = math.cos(q), math.sin(q)
        self.cr, self.sr = math.cos(r), math.sin(r)

    def to_local(self, p):
        x, y, z = p[0] - self.c[0], p[1] - self.c[1], p[2] - self.c[2]
        x, y = x * self.cr + y * self.sr, -x * self.sr + y * self.cr
        x, z = x * self.ct - z * self.st, x * self.st + z * self.ct
        y, z = y * self.cq + z * self.sq, -y * self.sq + z * self.cq
        x, y, z = x / self.s, y / self.s, z / self.s
        if x > 0 and self.k != 1.0:
            x /= self.k
        return (x, y, z)

    def to_world(self, q):
        x = q[0] * (self.k if q[0] > 0 else 1.0)
        x, y, z = x * self.s, q[1] * self.s, q[2] * self.s
        y, z = y * self.cq - z * self.sq, y * self.sq + z * self.cq
        x, z = x * self.ct + z * self.st, -x * self.st + z * self.ct
        x, y = x * self.cr - y * self.sr, x * self.sr + y * self.cr
        return (x + self.c[0], y + self.c[1], z + self.c[2])

    def screen(self, q):
        """The pixel a local point projects to."""
        w = self.to_world(q)
        return int(math.floor(w[0])), int(math.floor(w[1]))


# ------------------------------------------------------------------------------------------------------- rendering

LIGHT = (-0.40, -0.30, 0.87)
_n = length(*LIGHT)
LIGHT = (LIGHT[0] / _n, LIGHT[1] / _n, LIGHT[2] / _n)


def march(fn, x, y, zfar=44.0):
    z = zfar
    for _ in range(260):
        d, mat = fn((x, y, z))
        if d < 0.015:
            return z, mat
        z -= max(d * 0.9, 0.03)
        if z < -zfar:
            return None
    return None


class Raster:
    """A rendered layer: per pixel None or a dict (mat, z, n, v, ao)."""

    def __init__(self):
        self.px = [[None] * W for _ in range(H)]

    def get(self, x, y):
        return self.px[y][x] if 0 <= x < W and 0 <= y < H else None

    def zmap(self):
        return [[(c["z"] if c else None) for c in row] for row in self.px]


def render(fn, ao_ctx=None, samples=2, wrap=0.15, box=(0, 0, W, H)):
    """Ray-marches a distance field fn(p) -> (distance, material): coverage from samples x samples rays (a pixel is
    drawn when half of them hit), shading at the pixel centre (or the middle hit), the normal from the field, ambient
    occlusion against fn and an optional context field that shades this layer but is not drawn."""
    out = Raster()

    def occl(p):
        d = fn(p)[0]
        if ao_ctx is not None:
            d = min(d, ao_ctx(p)[0])
        return d

    x0, y0, x1, y1 = box
    for py in range(y0, y1):
        for px in range(x0, x1):
            hits = []
            for sy in range(samples):
                for sx in range(samples):
                    r = march(fn, px + (sx + 0.5) / samples, py + (sy + 0.5) / samples)
                    if r:
                        hits.append(r)
            if len(hits) * 2 < samples * samples:
                continue
            z, mat = max(hits, key=lambda h: h[0])      # the frontmost of the pixel's hits
            p = (px + 0.5, py + 0.5, z)
            e = 0.25
            nx = fn((p[0] + e, p[1], p[2]))[0] - fn((p[0] - e, p[1], p[2]))[0]
            ny = fn((p[0], p[1] + e, p[2]))[0] - fn((p[0], p[1] - e, p[2]))[0]
            nz = fn((p[0], p[1], p[2] + e))[0] - fn((p[0], p[1], p[2] - e))[0]
            nl = length(nx, ny, nz) or 1.0
            n = (nx / nl, ny / nl, nz / nl)
            ao = 0.0
            for i in range(1, 6):
                dd = 0.55 * i
                q = (p[0] + n[0] * dd, p[1] + n[1] * dd, p[2] + n[2] * dd)
                ao += (dd - occl(q)) / (2 ** i)
            ao = clamp(1.0 - 0.85 * ao, 0.0, 1.0)
            diff = n[0] * LIGHT[0] + n[1] * LIGHT[1] + n[2] * LIGHT[2]
            lam = clamp((diff + wrap) / (1.0 + wrap), 0.0, 1.0)
            out.px[py][px] = dict(mat=mat, z=z, n=n, v=lam * (0.62 + 0.38 * ao), ao=ao, lam=lam)
    return out


def union_z(rasters):
    """Per pixel the frontmost z of several layers (None where none is drawn): the clip of the parts above them."""
    out = [[None] * W for _ in range(H)]
    for r in rasters:
        for y in range(H):
            for x in range(W):
                c = r.px[y][x]
                if c and (out[y][x] is None or c["z"] > out[y][x]):
                    out[y][x] = c["z"]
    return out


def clip_behind(raster, zfront, eps=0.3, keep=None):
    """Drops the pixels of a layer that lie behind a front surface (a part behind the head, the hood's inside around
    the face); `keep(mat)` names materials that are never dropped."""
    for y in range(H):
        for x in range(W):
            c = raster.px[y][x]
            zf = zfront[y][x]
            if c and zf is not None and c["z"] < zf - eps and not (keep and keep(c["mat"])):
                raster.px[y][x] = None
    return raster


# ------------------------------------------------------------------------------------------------------ the picture

class Pic:
    """A frame being built: palette colour names (None is transparent)."""

    def __init__(self):
        self.c = [[None] * W for _ in range(H)]

    def get(self, x, y):
        return self.c[y][x] if 0 <= x < W and 0 <= y < H else None

    def set(self, x, y, name):
        if 0 <= x < W and 0 <= y < H:
            self.c[y][x] = name

    def opaque(self, x, y):
        return 0 <= x < W and 0 <= y < H and self.c[y][x] is not None

    def over(self, other):
        for y in range(H):
            for x in range(W):
                if other.c[y][x] is not None:
                    self.c[y][x] = other.c[y][x]
        return self

    def copy(self):
        p = Pic()
        p.c = [row[:] for row in self.c]
        return p


class Mat:
    """A material: its ramp (palette names, deep to light), the light thresholds between the steps, a texture that
    nudges the light per pixel, and the outline colour around it (None: no outline)."""

    def __init__(self, ramp, th=None, tex=None, outline="ink", inner=None, rim=None):
        self.ramp = ramp
        n = len(ramp)
        self.th = th or [0.12 + 0.75 * (i + 1) / n for i in range(n - 1)]
        self.tex = tex
        self.outline = outline
        self.inner = inner if inner is not None else ramp[0]
        self.rim = rim

    def colour(self, v):
        k = 0
        for t in self.th:
            if v > t:
                k += 1
        return self.ramp[k]

    def step(self, name, d):
        """The ramp colour `d` steps from `name` (darker for negative d)."""
        k = self.ramp.index(name) if name in self.ramp else 0
        return self.ramp[clamp(k + d, 0, len(self.ramp) - 1)]


def tone(raster, mats, pic=None):
    """Cuts each rendered pixel's light into its material's ramp (after the material's texture) into a Pic, then
    tidies lone pixels: a pixel whose four neighbours of the same material agree on another colour takes it."""
    pic = pic or Pic()
    matmap = [[None] * W for _ in range(H)]
    for y in range(H):
        for x in range(W):
            c = raster.px[y][x]
            if not c:
                continue
            m = mats[c["mat"]]
            v = c["v"]
            if m.tex:
                v = m.tex(x, y, c, v)
            pic.c[y][x] = m.colour(v)
            matmap[y][x] = c["mat"]
    for _ in range(2):
        new = [row[:] for row in pic.c]
        for y in range(H):
            for x in range(W):
                if matmap[y][x] is None:
                    continue
                nb = []
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    X, Y = x + dx, y + dy
                    if 0 <= X < W and 0 <= Y < H and matmap[Y][X] == matmap[y][x]:
                        nb.append(pic.c[Y][X])
                if len(nb) >= 3 and all(v == nb[0] for v in nb) and nb[0] != pic.c[y][x]:
                    new[y][x] = nb[0]
        pic.c = new
    return pic, matmap


def rim(pic, matmap, raster, mats):
    """A warm rim of hearth light: the leftmost pixel of a material whose surface faces the light (normal to the
    left) takes the material's rim colour."""
    for y in range(H):
        for x in range(W):
            m = matmap[y][x]
            if m is None or not mats[m].rim:
                continue
            left = matmap[y][x - 1] if x > 0 else None
            c = raster.px[y][x]
            if left != m and c and c["n"][0] < -0.35 and c["lam"] > 0.55:
                pic.c[y][x] = mats[m].rim
    return pic


def outline(pic, matmap, mats, inner_mask=None, skip=None, colour="ink"):
    """A 1 px outline around the drawing: transparent pixels next to it take `colour`, or, inside `inner_mask` (where
    the part lies over a face), the darkest colour of the material next to them, so a hairline or a beard's edge on the
    cheek is a dark tone of the hair, not an ink line. `skip(x, y)` leaves a pixel out (the neck's cut at the collar)."""
    add = []
    for y in range(H):
        for x in range(W):
            if pic.c[y][x] is not None or (skip and skip(x, y)):
                continue
            nbm = None
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                X, Y = x + dx, y + dy
                if 0 <= X < W and 0 <= Y < H and pic.c[Y][X] is not None and matmap[Y][X] is not None:
                    m = mats[matmap[Y][X]]
                    if m.outline is None:
                        continue
                    nbm = m
                    break
            if nbm is None:
                continue
            if inner_mask is not None and inner_mask[y][x]:
                add.append((x, y, nbm.inner))
            else:
                add.append((x, y, nbm.outline if nbm.outline != "ink" else colour))
    for x, y, c in add:
        pic.c[y][x] = c
    return pic


def edge_light(pic, matmap, mats, steps=2, skip=()):
    """The hearth's rim on the left: in every row, the leftmost pixel of the drawing (where the outline lies to its
    left, so only the outer silhouette) is lifted `steps` along its material's ramp."""
    for y in range(H):
        for x in range(W):
            m = matmap[y][x]
            if m is None:
                if pic.c[y][x] is not None and x + 1 < W and matmap[y][x + 1] is not None:
                    continue
                if pic.c[y][x] is None:
                    continue
                break
            if m not in skip and x > 0 and pic.c[y][x - 1] is not None:
                pic.c[y][x] = mats[m].step(pic.c[y][x], steps)
            break
    return pic


def stamp(pic, at, rows, legend, mask=None):
    """Hand-set pixels: rows of characters placed with their top-left at `at`; "." keeps the pixel, "_" clears it,
    other characters are palette names through `legend`. With `mask`, only pixels already drawn are touched."""
    x0, y0 = at
    for j, row in enumerate(rows):
        for i, ch in enumerate(row):
            if ch == "." or ch == " ":
                continue
            x, y = x0 + i, y0 + j
            if not (0 <= x < W and 0 <= y < H):
                continue
            if mask and not pic.opaque(x, y):
                continue
            pic.c[y][x] = None if ch == "_" else legend[ch]
    return pic


def patch(pic, text, legend, at=(0, 0)):
    """A hand-set patch given as a block of text lines (leading/trailing blank lines ignored)."""
    lines = [l for l in text.strip("\n").split("\n")]
    return stamp(pic, at, lines, legend)


# ------------------------------------------------------------------------------------------------------- output

def to_image(frames):
    """Frames (Pics) side by side into one RGBA strip."""
    img = Image(W * len(frames), H)
    for k, f in enumerate(frames):
        for y in range(H):
            for x in range(W):
                n = f.c[y][x]
                if n is not None:
                    r, g, b = PAL.color(n)
                    img.set(k * W + x, y, (r, g, b, 255))
    return img


# ------------------------------------------------------------------------------------------------------- commands

SWAP = {
    "skin": ["#6B3A2A", "#A0583E", "#D08A62", "#F0BC94"],
    "hair": ["#2E1C16", "#4E3020", "#74482C", "#9C6A40"],
    "cloth": ["#5A3E1C", "#8A6430", "#B88E48", "#E0BC72"],
}
# the code lane's target ramps (SPRITES.md "M3"); "medium", "midBrown" and "ochre" are the swap ramps themselves
TARGETS = {
    "skin": {"pale": "#8A5A48 #C08670 #E8B49A #FFE0C8", "light": "#7A4632 #B2704E #DE9E78 #F8CCA8",
             "medium": None, "brown": "#4A2818 #7A4428 #A8683E #CC9060", "deep": "#2C1810 #4E2C1C #704030 #966048"},
    "hair": {"black": "#14101A #262030 #3A3244 #565066", "darkBrown": "#24160F #3C2618 #583A24 #7A5434",
             "midBrown": None, "blond": "#6E5226 #A88440 #D8B864 #F4E098", "red": "#5A1E10 #8E3418 #C0562A #E08448",
             "grey": "#5E5A62 #8E8A92 #C0BCC2 #ECEAEE"},
    "cloth": {"teal": "#16384A #2F6E8E #4F92AE #8CC4D6", "redBrown": "#4A1E18 #8E4A36 #B8664A #DE9474",
              "green": "#2E4630 #4A6B3A #6E9A4A #9DBF62", "blue": "#1E2A5A #34488E #5A72B8 #8EA6DC", "ochre": None,
              "plum": "#3A1A36 #5E2E58 #8A4E80 #B47EA8"},
}


def _hex(h):
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16))


def swap_map(skin, hair, cloth):
    m = {}
    for ramp, name in (("skin", skin), ("hair", hair), ("cloth", cloth)):
        to = TARGETS[ramp][name]
        if to is None:
            continue
        for a, b in zip(SWAP[ramp], to.split()):
            m[_hex(a)] = _hex(b)
    return m


def load_frames(path, n):
    img, _ = read_png(path)
    fw = img.w // n
    return [[[img.get(k * fw + x, y) for x in range(fw)] for y in range(img.h)] for k in range(n)]


def compose(layers, smap):
    """The code's composer: each layer swapped colour for colour, drawn over the last where opaque."""
    out = [[None] * W for _ in range(H)]
    for frame in layers:
        for y in range(H):
            for x in range(W):
                p = frame[y][x]
                if p[3] >= 128:
                    rgb = p[:3]
                    out[y][x] = smap.get(rgb, rgb)
    return out


def tile_rgb(y):
    """The audience card's framed dusk tile (UI/SpriteThumbnail.swift's gradient)."""
    top, mid, bot = (0x3B, 0x35, 0x66), (0x6E, 0x5A, 0x7E), (0xC9, 0x8A, 0x6A)
    t = y / (H - 1)
    a, b, u = (top, mid, t / 0.5) if t < 0.5 else (mid, bot, (t - 0.5) / 0.5)
    return tuple(int(a[i] + (b[i] - a[i]) * u) for i in range(3))


def sheet(cells, out, scale=3, cols=6, pad=4):
    """Portraits (48x48 RGB grids, None transparent) on framed dusk tiles, nearest-neighbour at `scale`."""
    rows = (len(cells) + cols - 1) // cols
    cw = W + 2 + pad
    Wd, Hd = cols * cw + pad, rows * cw + pad
    can = [[(28, 24, 32)] * Wd for _ in range(Hd)]
    frame = (0x4A, 0x2E, 0x22)
    for k, cell in enumerate(cells):
        ox, oy = pad + (k % cols) * cw, pad + (k // cols) * cw
        for y in range(-1, H + 1):
            for x in range(-1, W + 1):
                if 0 <= x < W and 0 <= y < H:
                    p = cell[y][x] if cell else None
                    can[oy + 1 + y][ox + 1 + x] = p if p else tile_rgb(y)
                else:
                    can[oy + 1 + y][ox + 1 + x] = frame
    img = Image(Wd * scale, Hd * scale)
    px = []
    for row in can:
        line = []
        for c in row:
            line.extend([c + (255,)] * scale)
        for _ in range(scale):
            px.extend(line)
    img.px = px
    write_png(out, img)
    print(f"wrote {out} {Wd * scale}x{Hd * scale}")


# part frames (PortraitPart): clothes smock 0, dress 1, tunic 2, coat 3, leather 4, mail 5, robe 6, rags 7; faces
# round 0, long 1, square 2, old 3, young 4, child 5; beards none 0, stubble 1, short 2, full 3, long 4, moustache 5;
# hair bald 0, short 1, long 2, bun 3, curly 4, braids 5, tousled 6, mop 7; hats none 0, straw 1, scarf 2, feather 3,
# hood 4, wool 5, helm 6, wreath 7
ARCHETYPES = [
    ("farmer", [dict(clothes=[0, 2], faces=[3, 2, 1, 0], beards=[3, 4, 1, 2], hair=[1, 6, 0], hats=[1, 5, 0],
                     hairColors=["grey", "midBrown", "darkBrown", "black"], cloths=["green", "ochre", "blue", "redBrown"])]),
    ("farmwife", [dict(female=True, clothes=[1, 0], faces=[0, 1, 3, 4], hair=[3, 5, 2], hats=[2, 1, 0],
                       hairColors=["darkBrown", "midBrown", "blond", "red", "grey", "black"],
                       cloths=["redBrown", "ochre", "green", "blue"])]),
    ("townswoman", [dict(female=True, clothes=[1], faces=[0, 1, 4], hair=[2, 3, 5, 4], hats=[2, 0, 7],
                         cloths=["redBrown", "plum", "blue", "teal", "green"])]),
    ("townsman", [dict(clothes=[2, 3], faces=[0, 1, 2, 4], beards=[0, 1, 2, 5], hair=[1, 4, 6], hats=[0, 5, 3],
                       cloths=["blue", "green", "ochre", "redBrown"])]),
    ("merchant", [dict(clothes=[3], faces=[0, 1, 2], beards=[2, 3, 5], hair=[1, 4, 0], hats=[3, 0],
                       cloths=["plum", "teal", "blue", "redBrown"])]),
    ("soldier", [dict(clothes=[5], faces=[2, 1, 3], beards=[1, 2, 3, 5], hair=[1, 0], hats=[6, 0],
                      hairColors=["black", "darkBrown", "midBrown", "blond", "red", "grey"], cloths=["teal"])]),
    ("builder", [dict(clothes=[4], faces=[0, 2], beards=[1, 3, 2], hair=[1, 6, 0], hats=[5, 0],
                      cloths=["ochre", "redBrown", "green"])]),
    ("widow", [dict(female=True, clothes=[1, 6], faces=[3], hair=[3, 2], hats=[2, 4], hairColors=["grey"],
                    cloths=["plum", "blue"])]),
    ("child", [dict(female=True, clothes=[0, 2], faces=[5], hair=[7, 5], hats=[0, 7],
                    cloths=["green", "ochre", "teal", "redBrown"]),
               dict(clothes=[0, 2], faces=[5], beards=[0], hair=[7], hats=[0, 5],
                    cloths=["green", "ochre", "teal", "redBrown"])]),
    ("noble", [dict(clothes=[3, 6], faces=[1, 0, 2], beards=[0, 2, 5], hair=[4, 1, 2], hats=[3, 0],
                    skins=["pale", "light", "medium", "brown"], cloths=["plum", "teal", "blue"])]),
    ("refugee", [dict(female=True, clothes=[7], faces=[1, 3, 4, 0], hair=[2, 5], hats=[4, 2, 0],
                      cloths=["ochre", "redBrown", "green"]),
                 dict(clothes=[7], faces=[1, 3, 4, 0], beards=[1, 0, 2], hair=[6, 1], hats=[4, 0],
                      cloths=["ochre", "redBrown", "green"])]),
]


def card_mock(a, parts, recipe_layers):
    """A rough audience card (parchment, the framed dusk tile with the portrait at 3 device px per art pixel, ink
    bars where the name, the request and the choices go) for three speakers: the contrast check of the portraits on
    the card. Not the code lane's layout, only its colours and scale."""
    art = a.art or ART
    s = a.scale
    picks = [load_frames(os.path.join(art, "portraitOdile.png"), 1)[0],
             compose(recipe_layers(1, 3, 0, 3, 2), swap_map("light", "grey", "plum")),
             load_frames(os.path.join(art, "portraitHerald.png"), 1)[0]]
    cw, chh, pad = 220, 64, 6
    W2, H2 = cw + 2 * pad, len(picks) * (chh + pad) + pad
    can = [[(28, 24, 32)] * W2 for _ in range(H2)]
    parch, ink, wood = _hex("#F1E3C4"), _hex("#2A2230"), _hex("#4A2E22")
    for k, f in enumerate(picks):
        ox, oy = pad, pad + k * (chh + pad)
        for y in range(chh):
            for x in range(cw):
                edge = x in (0, cw - 1) or y in (0, chh - 1)
                can[oy + y][ox + x] = wood if edge else parch
        tx, ty = ox + 6, oy + 7
        for y in range(-1, H + 1):
            for x in range(-1, W + 1):
                if 0 <= x < W and 0 <= y < H:
                    p = f[y][x]
                    can[ty + y][tx + x] = (p[:3] if len(p) > 3 and p[3] else p) if (p and (len(p) < 4 or p[3])) else tile_rgb(y)
                else:
                    can[ty + y][tx + x] = wood
        for i, (lx, ly, ln) in enumerate([(62, 8, 60), (62, 18, 140), (62, 24, 130), (62, 30, 100)]):
            for x in range(ln):
                for y in range(3 if i == 0 else 2):
                    can[oy + ly + y][ox + lx + x] = ink
        for j in range(3):
            bx, by = ox + 62 + j * 50, oy + 44
            for y in range(12):
                for x in range(44):
                    can[by + y][bx + x] = wood if (x in (0, 43) or y in (0, 11)) else (0xE8, 0xD4, 0xA8)
    img = Image(W2 * s, H2 * s)
    px = []
    for row in can:
        line = []
        for c in row:
            line.extend([tuple(c[:3]) + (255,)] * s)
        for _ in range(s):
            px.extend(line)
    img.px = px
    write_png(a.output, img)
    print(f"wrote {a.output} {W2 * s}x{H2 * s}")


def cmd_build(a):
    import portraitkit as K
    if a.id in K.PARTS:
        frames = K.part_frames(a.id)
        assert len(frames) == K.PART_FRAMES[a.id], (a.id, len(frames))
    else:
        import portraitstory as S
        frames = S.story_frames(a.id)
    out = a.out or ART
    write_png(os.path.join(out, a.id + ".png"), to_image(frames))
    print(f"wrote {a.id}.png {W * len(frames)}x{H} ({len(frames)} frames)")


# the frozen story grids' legend: one fixed letter per palette colour, so a hand edit reads the same in every grid
FREEZE_LETTERS = {
    "ink": "k", "night0": "0", "night1": "1", "night2": "2", "moon": "M",
    "stoneDark": "d", "stoneMid": "m", "stone": "s", "stoneLight": "l", "stonePale": "p",
    "woodDark": "b", "wood": "w", "woodLight": "W", "straw": "y", "strawLight": "Y", "gold": "g",
    "tile": "t", "tileLight": "T", "dawnRose": "r", "dusk": "R", "parchment": "P", "plaster": "c", "plasterDim": "C",
    "soilDark": "o", "soil": "e", "soilLight": "E", "rockDeep": "x", "rockDark": "X", "rock": "q", "rockLight": "Q",
    "rockPale": "z", "roofDeep": "n", "banner": "B", "roofLight": "N", "daySky": "a", "waterDeep": "A", "foam": "h",
    "farDeep": "F", "far": "f", "farPale": "v", "leafDark": "3", "leaf": "4", "meadow": "6", "leafLight": "5",
    "plumDeep": "u", "plum": "U", "plumLight": "V", "crimsonDeep": "i", "crimson": "I", "crimsonLight": "J",
}


def cmd_freeze(a):
    import portraitstory as S
    n = S.STORY_FRAMES.get(a.id, 1)
    if a.png:
        frames = load_frames(a.png, n)
    else:
        frames = []
        for pic in S.story_frames(a.id):
            frames.append([[(PAL.color(c) + (255,)) if c else (0, 0, 0, 0) for c in row] for row in pic.c])
    lut = {PAL.color(nm): nm for nm in FREEZE_LETTERS}
    used = []
    rows_out = []
    for f in frames:
        rows = []
        for row in f:
            line = ""
            for px in row:
                if not px[3]:
                    line += "."
                    continue
                nm = lut.get(tuple(px[:3]))
                if nm is None:
                    raise SystemExit(f"{a.id}: colour {px[:3]} has no freeze letter")
                if nm not in used:
                    used.append(nm)
                line += FREEZE_LETTERS[nm]
            rows.append(line)
        rows_out.append(rows)
    used.sort(key=lambda nm: list(FREEZE_LETTERS).index(nm))
    with open(a.output, "w") as fh:
        fh.write(f"# {a.id}: a story portrait of the audience card (SPRITES.md \"M3\", ART-court.md), 48x48 x {n}, frozen\n"
                 f"# from portraitstory.py's render and finished by hand (ART-court.md \"Fix stage\"); actorart.py builds it\n"
                 f"# (no outline directive: the outline is in the pixels). Letters: portraitart.py FREEZE_LETTERS.\n")
        fh.write(f"id {a.id}\nsize 48x48\nframes {n}\n\nlegend\n")
        for nm in used:
            fh.write(f"    {FREEZE_LETTERS[nm]} = {nm}\n")
        for k, rows in enumerate(rows_out):
            fh.write(f"\npart f{k}\n")
            for line in rows:
                fh.write("    " + line + "\n")
        for k in range(n):
            fh.write(f"\nframe {k}\n    f{k} 0 0\n")
    print(f"wrote {a.output} ({n} frames, {len(used)} colours)")


def cmd_list(a):
    import portraitkit as K
    import portraitstory as S
    print(" ".join(S.STORY + K.PARTS))


def cmd_sheet(a):
    import random
    art = a.art or ART
    if a.kind == "story":
        import portraitstory as S
        cells = []
        for sid in S.STORY:
            n = S.STORY_FRAMES.get(sid, 1)
            for f in load_frames(os.path.join(art, sid + ".png"), n):
                cells.append([[p[:3] if p[3] else None for p in row] for row in f])
        sheet(cells, a.output, a.scale, cols=a.cols or 7)
        return
    parts = {}
    for sid, n in (("portraitClothes", 8), ("portraitFace", 6), ("portraitBeard", 6), ("portraitHair", 8),
                   ("portraitHat", 8)):
        parts[sid] = load_frames(os.path.join(art, sid + ".png"), n)

    def recipe_layers(c, f, b, h, t):
        layers = [parts["portraitClothes"][c], parts["portraitFace"][f]]
        if b:
            layers.append(parts["portraitBeard"][b])
        if h:
            layers.append(parts["portraitHair"][h])
        if t:
            layers.append(parts["portraitHat"][t])
        return layers

    cells = []
    if a.kind == "composed":
        rng = random.Random(a.seed)
        for _ in range(a.n):
            female = rng.random() < 0.5
            c, f = rng.randrange(8), rng.randrange(6)
            b = 0 if female else rng.randrange(6)
            h, t = rng.randrange(8), rng.randrange(8)
            smap = swap_map(rng.choice(list(TARGETS["skin"])), rng.choice(list(TARGETS["hair"])),
                            rng.choice(list(TARGETS["cloth"])))
            cells.append(compose(recipe_layers(c, f, b, h, t), smap))
        sheet(cells, a.output, a.scale, cols=a.cols or 6)
    elif a.kind == "parts":
        ident = {}
        for f in range(6):                                  # every face in every clothes... the faces with beards
            for b in range(6):
                cells.append(compose(recipe_layers(f % 8, f, b, 1 if b else 0, 0), ident))
        for h in range(8):                                  # every hair on the round and the child face
            cells.append(compose(recipe_layers(2, 0, 0, h, 0), ident))
            cells.append(compose(recipe_layers(0, 5, 0, h, 0), ident))
        for t in range(8):                                  # every hat over short and long hair
            cells.append(compose(recipe_layers(3, 1, 0, 1, t), ident))
            cells.append(compose(recipe_layers(1, 4, 0, 2, t), ident))
        for c in range(8):
            cells.append(compose(recipe_layers(c, 2, 0, 0, 0), ident))
        sheet(cells, a.output, a.scale, cols=a.cols or 8)
    elif a.kind == "archetypes":
        # the code lane's townsfolk archetypes (Core/CourtSpeakers.swift on claude/lh-m3, 09.11.): four draws each
        rng = random.Random(a.seed)
        for name, styles in ARCHETYPES:
            for k in range(4):
                st = styles[k % len(styles)]
                female = st.get("female", False)
                pick = lambda key, default: rng.choice(st.get(key, default))
                c, f = pick("clothes", [0]), pick("faces", [0])
                b = 0 if female else pick("beards", [0])
                h, t = pick("hair", [0]), pick("hats", [0])
                smap = swap_map(pick("skins", list(TARGETS["skin"])),
                                pick("hairColors", ["black", "darkBrown", "midBrown", "blond", "red"]),
                                pick("cloths", ["ochre"]))
                cells.append(compose(recipe_layers(c, f, b, h, t), smap))
        sheet(cells, a.output, a.scale, cols=a.cols or 8)
    elif a.kind == "card":
        card_mock(a, parts, recipe_layers)
    else:
        raise SystemExit(f"no sheet {a.kind}")


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = p.add_subparsers(dest="cmd", required=True)
    b = sub.add_parser("build")
    b.add_argument("id")
    b.add_argument("--out")
    b.set_defaults(fn=cmd_build)
    li = sub.add_parser("list")
    li.set_defaults(fn=cmd_list)
    fz = sub.add_parser("freeze")
    fz.add_argument("id")
    fz.add_argument("output")
    fz.add_argument("--from", dest="png")
    fz.set_defaults(fn=cmd_freeze)
    s = sub.add_parser("sheet")
    s.add_argument("kind", choices=["story", "composed", "parts", "archetypes", "card"])
    s.add_argument("output")
    s.add_argument("--art")
    s.add_argument("--scale", type=int, default=3)
    s.add_argument("--n", type=int, default=30)
    s.add_argument("--seed", type=int, default=1)
    s.add_argument("--cols", type=int)
    s.set_defaults(fn=cmd_sheet)
    a = p.parse_args()
    a.fn(a)


if __name__ == "__main__":
    main()
