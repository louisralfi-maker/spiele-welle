#!/usr/bin/env python3
"""Lanternhold: the castle's rooms and the court's props, painted in code (M3 art lane, step 3; ART-court.md).

A small pixel painter on a palette canvas. Shapes (rects, lines, polygons, ellipses, pointed and round arches),
material brushes that paint the castle's surfaces in its palette (ashlar courses, planks, beams, posts, slate, plaster,
flagstones and floorboards in perspective) and stamps: hand-set text grids for the small things (a cat on its stool, a
loaf, a candle, a pot), kept in tools/grids/court/rooms/*.txt. Each sprite is one paint function in roomscenes.py.
Deterministic: integer hashing only (no random module, no trigonometry), so a rebuild writes the same bytes.

Commands (run from anywhere; one sprite per run, each about a second):
  roomart.py build <id> [--out DIR]        paint one sprite into Resources/Art (or DIR)
  roomart.py list                          the sprite ids roomscenes.py paints
  roomart.py silhouette <a.png> <b.png>    compare the opaque pixels of two sprites (exit 1 when they differ)
  roomart.py anchors <id>                  print the anchors a paint function records (window glass, fire, spots)

Painted art is albedo (ART.md): even daylight colours with gentle form shading, no baked night, no glow, no cast
shadows. Window glass is painted night1 / night0 (the engine's glass masks glow those and ink), flames are left to
the engine's emissive sprites at the recorded fire anchors.
"""
import argparse
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from pixelart import Image, Palette, read_png, write_png, DEFAULT_PALETTE  # noqa: E402

ART = os.path.join(HERE, "..", "Resources", "Art")
GRIDS = os.path.join(HERE, "grids", "court", "rooms")


# ------------------------------------------------------------------------------------------------------- hashing

def hash32(*vals):
    """FNV-1a over the values' 32-bit little-endian bytes, then murmur's finaliser: a stable integer hash."""
    h = 0x811C9DC5
    for v in vals:
        v = int(v) & 0xFFFFFFFF
        for k in range(4):
            h ^= (v >> (8 * k)) & 0xFF
            h = (h * 0x01000193) & 0xFFFFFFFF
    h ^= h >> 16
    h = (h * 0x85EBCA6B) & 0xFFFFFFFF
    h ^= h >> 13
    h = (h * 0xC2B2AE35) & 0xFFFFFFFF
    h ^= h >> 16
    return h


def rnd(*vals):
    """A stable number in [0, 1) from the values."""
    return hash32(*vals) / 4294967296.0


def pick(seq, *vals):
    return seq[hash32(*vals) % len(seq)]


def irange(lo, hi, *vals):
    """A stable integer in [lo, hi]."""
    return lo + hash32(*vals) % (hi - lo + 1)


# -------------------------------------------------------------------------------------------------------- canvas

class Canvas:
    """A w x h grid of palette names (None is transparent). x right, y down, (0, 0) the top-left pixel."""

    def __init__(self, w, h, pal=None):
        self.w, self.h = w, h
        self.pal = pal or Palette(DEFAULT_PALETTE, allow_emissive=True, allow_swap=True)
        self.px = [[None] * w for _ in range(h)]
        self.clip = None          # optional set of (x, y) that may be painted
        self.anchors = []         # (kind, values ...) for ART-court.md

    # --- pixels
    def inside(self, x, y):
        return 0 <= x < self.w and 0 <= y < self.h and (self.clip is None or (x, y) in self.clip)

    def put(self, x, y, c):
        if c is None or c == "?":
            return
        if self.inside(x, y):
            if c == "clear":
                self.px[y][x] = None
                return
            if c not in self.pal.names:
                raise SystemExit(f"unknown palette colour {c}")
            self.px[y][x] = c

    def get(self, x, y):
        return self.px[y][x] if 0 <= x < self.w and 0 <= y < self.h else None

    def copy(self):
        o = Canvas(self.w, self.h, self.pal)
        o.px = [r[:] for r in self.px]
        o.clip = self.clip
        o.anchors = list(self.anchors)
        return o

    def anchor(self, *vals):
        self.anchors.append(vals)

    # --- shapes (inclusive coordinates)
    def rect(self, x0, y0, x1, y1, c):
        for y in range(min(y0, y1), max(y0, y1) + 1):
            for x in range(min(x0, x1), max(x0, x1) + 1):
                self.put(x, y, c)

    def hline(self, x0, x1, y, c):
        self.rect(x0, y, x1, y, c)

    def vline(self, x, y0, y1, c):
        self.rect(x, y0, x, y1, c)

    def line(self, x0, y0, x1, y1, c):
        """Bresenham."""
        dx, dy = abs(x1 - x0), -abs(y1 - y0)
        sx, sy = (1 if x0 < x1 else -1), (1 if y0 < y1 else -1)
        err = dx + dy
        while True:
            self.put(x0, y0, c)
            if x0 == x1 and y0 == y1:
                return
            e2 = 2 * err
            if e2 >= dy:
                err += dy
                x0 += sx
            if e2 <= dx:
                err += dx
                y0 += sy

    def poly(self, pts, c):
        """Fills a polygon (even-odd rule, pixel centres)."""
        ys = [p[1] for p in pts]
        n = len(pts)
        for y in range(int(math.floor(min(ys))), int(math.ceil(max(ys))) + 1):
            yc = y + 0.5
            xs = []
            for i in range(n):
                (xa, ya), (xb, yb) = pts[i], pts[(i + 1) % n]
                if (ya <= yc < yb) or (yb <= yc < ya):
                    xs.append(xa + (yc - ya) * (xb - xa) / (yb - ya))
            xs.sort()
            for i in range(0, len(xs) - 1, 2):
                for x in range(int(math.ceil(xs[i] - 0.5)), int(math.floor(xs[i + 1] - 0.5)) + 1):
                    self.put(x, y, c)

    def ellipse(self, cx, cy, rx, ry, c):
        """Fills the pixels whose centres lie inside the ellipse (cx, cy in pixel-edge coordinates)."""
        for y in range(int(math.floor(cy - ry)) - 1, int(math.ceil(cy + ry)) + 1):
            for x in range(int(math.floor(cx - rx)) - 1, int(math.ceil(cx + rx)) + 1):
                dx = (x + 0.5 - cx) / rx if rx else 0.0
                dy = (y + 0.5 - cy) / ry if ry else 0.0
                if dx * dx + dy * dy <= 1.0:
                    self.put(x, y, c)

    def recolour(self, x0, y0, x1, y1, mapping):
        """Inside the rect, pixels whose colour is a key of `mapping` take its value."""
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                v = self.get(x, y)
                if v in mapping:
                    self.put(x, y, mapping[v])

    def outline(self, c, x0=0, y0=0, x1=None, y1=None, skip_bottom=False):
        """Transparent pixels inside the rect that are 4-adjacent to opaque ones take colour c."""
        x1 = self.w - 1 if x1 is None else x1
        y1 = self.h - 1 if y1 is None else y1
        hits = []
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                if self.get(x, y) is not None:
                    continue
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    if skip_bottom and dy == -1:
                        continue
                    if self.get(x + dx, y + dy) is not None:
                        hits.append((x, y))
                        break
        for x, y in hits:
            self.put(x, y, c)

    def edge(self, c, x0, y0, x1, y1, only=None):
        """Opaque pixels inside the rect (of the colours in `only`, if given) that touch a transparent pixel or the
        canvas edge take colour c: an inner outline."""
        hits = []
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                v = self.get(x, y)
                if v is None or (only and v not in only):
                    continue
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    if self.get(x + dx, y + dy) is None:
                        hits.append((x, y))
                        break
        for x, y in hits:
            self.put(x, y, c)

    # --- stamps and other canvases
    def stamp(self, st, x, y, flip=False, recolour=None):
        """Draws a Stamp with its top-left at (x, y); '.' leaves a pixel, `recolour` maps names to names."""
        for j, row in enumerate(st.rows):
            for i, ch in enumerate(row):
                c = st.legend.get(ch)
                if c is None:
                    continue
                if recolour:
                    c = recolour.get(c, c)
                self.put(x + (st.w - 1 - i if flip else i), y + j, c)

    def blit(self, other, x, y, box=None, flip=False):
        """Draws the opaque pixels of another canvas (or the inclusive box of it) with its top-left at (x, y)."""
        bx0, by0, bx1, by1 = box or (0, 0, other.w - 1, other.h - 1)
        for j in range(by0, by1 + 1):
            for i in range(bx0, bx1 + 1):
                c = other.get(i, j)
                if c is not None:
                    self.put(x + ((bx1 - i) if flip else (i - bx0)), y + (j - by0), c)

    # --- io
    def to_image(self):
        img = Image(self.w, self.h)
        for y in range(self.h):
            for x in range(self.w):
                c = self.px[y][x]
                if c is not None:
                    r, g, b = self.pal.color(c)
                    img.set(x, y, (r, g, b, 255))
        return img

    def save(self, path):
        write_png(path, self.to_image())


def load_png(path, pal=None):
    """A palette PNG as a Canvas (every opaque pixel must be a palette colour)."""
    pal = pal or Palette(DEFAULT_PALETTE, allow_emissive=True, allow_swap=True)
    img, _ = read_png(path)
    lut = {c: n for n, c in zip(pal.names, pal.rgb)}
    c = Canvas(img.w, img.h, pal)
    for y in range(img.h):
        for x in range(img.w):
            p = img.get(x, y)
            if p[3]:
                if p[:3] not in lut:
                    raise SystemExit(f"{path}: off-palette pixel {p} at {x},{y}")
                c.px[y][x] = lut[p[:3]]
    return c


def art(name):
    """A committed sprite of Resources/Art as a Canvas."""
    return load_png(os.path.join(ART, name + ".png"))


def alpha_set(canvas):
    return {(x, y) for y in range(canvas.h) for x in range(canvas.w) if canvas.px[y][x] is not None}


# --------------------------------------------------------------------------------------------------------- stamps

class Stamp:
    def __init__(self, name, legend, rows):
        self.name, self.legend, self.rows = name, legend, rows
        self.w = max((len(r) for r in rows), default=0)
        self.h = len(rows)


def load_stamps(path):
    """A stamp file: a `legend` block ("X = paletteName", indented lines) shared by the file, then `stamp NAME` blocks
    of indented rows ("." is transparent). Comments start with #."""
    out = {}
    legend = {".": None}
    cur, rows, mode = None, [], None
    with open(path) as fh:
        lines = fh.read().splitlines()

    def close():
        if cur is not None:
            out[cur] = Stamp(cur, dict(legend), rows)

    for raw in lines:
        if not raw.strip() or raw.lstrip().startswith("#"):
            continue
        if not raw[0].isspace():
            word = raw.split()
            close()
            if word[0] == "legend":
                cur, rows, mode = None, [], "legend"
            elif word[0] == "stamp":
                cur, rows, mode = word[1], [], "stamp"
            else:
                raise SystemExit(f"{path}: unknown directive {raw!r}")
            continue
        s = raw.strip()
        if mode == "legend":
            ch, name = (t.strip() for t in s.split("=", 1))
            legend[ch] = name
        elif mode == "stamp":
            rows.append(s)
    close()
    for st in out.values():
        for row in st.rows:
            for ch in row:
                if ch not in st.legend:
                    raise SystemExit(f"{path}: stamp {st.name}: character {ch!r} not in the legend")
    return out


_STAMPS = {}


def stamps(fname):
    """The stamps of tools/grids/court/rooms/<fname>.txt (cached)."""
    if fname not in _STAMPS:
        _STAMPS[fname] = load_stamps(os.path.join(GRIDS, fname + ".txt"))
    return _STAMPS[fname]


# --------------------------------------------------------------------------------------------------------- arches

def arch_rows(w, h, pointed=True, sharp=0.75):
    """Per row (0 = the top) the inclusive x span of a w-wide opening h rows tall whose head is an arch, or None for a
    row above the arch. A pointed head is two arcs of radius sharp * w (sharp from 0.5, a semicircle, to 1, an
    equilateral arch), each centred on the springing line and passing through its own springing point; a round head
    is a semicircle."""
    R = max(0.5, sharp) * w if pointed else w / 2.0
    head = (R * R - (R - w / 2.0) ** 2) ** 0.5
    headr = int(round(head))
    spans = []
    for j in range(h):
        yc = headr - j - 0.5          # height above the springing line
        if yc <= 0:
            spans.append((0, w - 1))
            continue
        if yc >= R:
            spans.append(None)
            continue
        left = R - (R * R - yc * yc) ** 0.5
        if left > w / 2.0:
            spans.append(None)
            continue
        x0 = int(math.ceil(left - 0.5))
        x1 = w - 1 - x0
        spans.append((x0, x1) if x0 <= x1 else None)
    return spans


def arch_set(x, y, w, h, pointed=True, sharp=0.75):
    """The pixels of an arched opening with its top-left at (x, y)."""
    m = set()
    for j, sp in enumerate(arch_rows(w, h, pointed, sharp)):
        if sp:
            for i in range(sp[0], sp[1] + 1):
                m.add((x + i, y + j))
    return m


def ring(pixels):
    """The pixels just outside a set (4-adjacent), as a set."""
    out = set()
    for (x, y) in pixels:
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            q = (x + dx, y + dy)
            if q not in pixels:
                out.add(q)
    return out


def paint_set(c, pixels, colour):
    for (x, y) in pixels:
        c.put(x, y, colour)


# -------------------------------------------------------------------------------------------------------- brushes

def ashlar(c, x0, y0, x1, y1, seed, course=(6, 5), width=(8, 15), joint="stoneMid", deep="ink",
           faces=("stone",) * 6 + ("stoneMid", "stoneLight"), light="stoneLight", shade="stoneMid",
           pits=0.035, deep_share=0.3, phase=0):
    """Dressed stone in courses: each course `course[k]` rows tall (cycling; its last row is the bed joint), blocks
    `width` px long with a head joint, staggered by course. A block's face takes a seeded colour from `faces`; its top
    row is lit over most of its length (`light`), the right part of its lowest row shaded (`shade`), a few seeded
    pits. Joints are `joint`, a seeded share `deep_share` of them `deep` (a darker crevice)."""
    y = y0
    k = 0
    while y <= y1:
        ch = course[(k + phase) % len(course)]
        yb = min(y1, y + ch - 1)
        x = x0 - irange(0, width[1] - 1, seed, 17, k)
        b = 0
        while x <= x1:
            bw = irange(width[0], width[1], seed, k, b)
            xe = x + bw - 1
            face = pick(faces, seed, k, b, 3)
            lit_to = xe - 1 - max(1, bw // 4)
            for yy in range(y, yb):
                for xx in range(max(x, x0), min(xe - 1, x1) + 1):
                    col = face
                    if yy == y and xx <= lit_to and face != light:
                        col = light
                    elif yy == yb - 1 and yb - y > 2 and xx > x + bw // 3:
                        col = shade if face != shade else "stoneDark"
                    elif rnd(seed, xx, yy, 5) < pits:
                        col = shade if face != shade else "stoneDark"
                    c.put(xx, yy, col)
            if x0 <= xe <= x1:
                jc = deep if rnd(seed, k, b, 9) < deep_share else joint
                for yy in range(y, yb):
                    c.put(xe, yy, jc)
            x += bw
            b += 1
        if yb > y or ch == 1:
            for xx in range(x0, x1 + 1):
                c.put(xx, yb, deep if rnd(seed, k, xx // 5, 11) < deep_share else joint)
        y = yb + 1
        k += 1


def planks(c, x0, y0, x1, y1, seed, width=(3, 4), gap="woodDark", colours=("wood", "wood", "woodLight"),
           grain="woodDark", light=None, knots=0.01):
    """Vertical planks with a dark gap after each, a seeded colour each, grain streaks and knots."""
    x = x0
    k = 0
    while x <= x1:
        pw = irange(width[0], width[1], seed, k)
        col = pick(colours, seed, k, 1)
        for xx in range(x, min(x + pw - 1, x1) + 1):
            for yy in range(y0, y1 + 1):
                v = col
                if xx == x + pw - 1:
                    v = gap
                elif light and xx == x:
                    v = light
                elif rnd(seed, xx, yy // 3, 2) < 0.07:
                    v = grain
                elif rnd(seed, xx, yy, 3) < knots:
                    v = gap
                c.put(xx, yy, v)
        x += pw
        k += 1


def beam(c, x0, x1, y, h=3, top="woodLight", body="wood", bottom="woodDark", seed=0, checks=0.05):
    """A horizontal timber h rows tall: a lit top row, the body, a dark bottom row, seeded checks."""
    for xx in range(x0, x1 + 1):
        c.put(xx, y, top)
        for yy in range(y + 1, y + h - 1):
            c.put(xx, yy, bottom if rnd(seed, xx, yy, 7) < checks else body)
        if h > 1:
            c.put(xx, y + h - 1, bottom)


def post(c, x, y0, y1, w=3, left="woodLight", body="wood", right="woodDark", seed=0, checks=0.05):
    """A vertical timber w wide: a lit left column, the body, a dark right column."""
    for yy in range(y0, y1 + 1):
        c.put(x, yy, left)
        for xx in range(x + 1, x + w - 1):
            c.put(xx, yy, right if rnd(seed, xx, yy // 2, 8) < checks else body)
        if w > 1:
            c.put(x + w - 1, yy, right)


def slate(c, x0, y0, x1, y1, seed, row=3, width=(4, 6), base="banner", dark="roofDeep", light="roofLight",
          gap="night1", share=0.72):
    """Slate courses `row` rows tall with a gap row under each, staggered tiles with a dark split between them, the
    top row of most tiles lit, some tiles dark."""
    y = y0
    k = 0
    while y <= y1:
        x = x0 - irange(0, width[1], seed, k, 1)
        b = 0
        while x <= x1:
            tw = irange(width[0], width[1], seed, k, b)
            col = base if rnd(seed, k, b, 2) < share else dark
            for yy in range(y, min(y + row - 1, y1) + 1):
                for xx in range(max(x, x0), min(x + tw - 1, x1) + 1):
                    if yy == y + row - 1:
                        v = gap
                    elif xx == x + tw - 1:
                        v = dark if col == base else gap
                    elif yy == y and col == base and xx < x + tw - 2:
                        v = light
                    else:
                        v = col
                    c.put(xx, yy, v)
            x += tw
            b += 1
        y += row
        k += 1


def plaster(c, x0, y0, x1, y1, seed, base="plaster", dim="plasterDim", speck=0.03, cracks=True):
    """Lime plaster: the base colour with seeded dim specks and a few hairline cracks."""
    for yy in range(y0, y1 + 1):
        for xx in range(x0, x1 + 1):
            c.put(xx, yy, dim if rnd(seed, xx, yy, 1) < speck else base)
    if not cracks:
        return
    for k in range(max(1, (x1 - x0 + 1) * (y1 - y0 + 1) // 600)):
        x = irange(x0 + 2, max(x0 + 2, x1 - 2), seed, k, 2)
        y = irange(y0 + 1, max(y0 + 1, y1 - 4), seed, k, 3)
        for s in range(irange(2, 4, seed, k, 4)):
            c.put(x, y + s, dim)
            x += pick((-1, 0, 0, 1), seed, k, s)


def flagstones(c, x0, y0, x1, y1, seed, colours=("stone", "stoneMid", "stone", "stoneLight"), joint="stoneDark",
               light="stoneLight", grow=(2, 4)):
    """A stone-flag floor in perspective: rows from grow[0] px at the back to grow[1] px at the front, flags wider
    toward the front, joints dark, the back edge of each flag lit."""
    y = y0
    k = 0
    span = max(1, y1 - y0 + 1)
    while y <= y1:
        rh = grow[0] + ((grow[1] - grow[0] + 1) * (y - y0)) // span
        rh = max(1, min(rh, y1 - y + 1))
        x = x0 - irange(0, 14, seed, k)
        b = 0
        while x <= x1:
            fw = irange(9, 15, seed, k, b) + (y - y0) // 2
            col = pick(colours, seed, k, b, 1)
            for yy in range(y, y + rh):
                for xx in range(max(x, x0), min(x + fw - 1, x1) + 1):
                    if yy == y + rh - 1 or xx == x + fw - 1:
                        v = joint
                    elif yy == y and xx < x + fw - 3 and col != light:
                        v = light
                    else:
                        v = col
                    c.put(xx, yy, v)
            x += fw
            b += 1
        y += rh
        k += 1


def floorboards(c, x0, y0, x1, y1, seed, colours=("wood", "woodLight", "wood"), gap="woodDark", grow=(2, 4)):
    """Floorboards running across the room in perspective: rows from grow[0] px at the back to grow[1] at the
    front, a dark gap row under each, butt joints."""
    y = y0
    k = 0
    span = max(1, y1 - y0 + 1)
    while y <= y1:
        rh = grow[0] + ((grow[1] - grow[0] + 1) * (y - y0)) // span
        rh = max(1, min(rh, y1 - y + 1))
        col = pick(colours, seed, k)
        off = irange(0, 40, seed, k, 1)
        sp = irange(26, 44, seed, k, 2)
        for yy in range(y, y + rh):
            for xx in range(x0, x1 + 1):
                v = col
                if yy == y + rh - 1 and rh > 1:
                    v = gap
                elif (xx + off) % sp == 0:
                    v = gap
                elif rnd(seed, xx // 4, yy, 3) < 0.05:
                    v = gap
                c.put(xx, yy, v)
        y += rh
        k += 1


def shift_ramp(c, x0, y0, x1, y1, ramp, step):
    """Moves every pixel of a ramp colour inside the rect `step` places along the ramp (clamped)."""
    for yy in range(y0, y1 + 1):
        for xx in range(x0, x1 + 1):
            v = c.get(xx, yy)
            if v in ramp:
                i = max(0, min(len(ramp) - 1, ramp.index(v) + step))
                c.put(xx, yy, ramp[i])


# --------------------------------------------------------------------------------------------------------- checks

def same_silhouette(a, b):
    """The pixels opaque in one canvas and not in the other."""
    sa, sb = alpha_set(a), alpha_set(b)
    return sorted(sa - sb), sorted(sb - sa)


# ----------------------------------------------------------------------------------------------------------- main

def cmd_build(a):
    import roomscenes
    fn = roomscenes.SPRITES.get(a.id)
    if fn is None:
        raise SystemExit(f"unknown sprite {a.id} (roomart.py list)")
    canvas = fn()
    out = os.path.join(a.out or ART, a.id + ".png")
    canvas.save(out)
    print(f"wrote {out} {canvas.w}x{canvas.h}")


def cmd_list(a):
    import roomscenes
    print(" ".join(roomscenes.SPRITES))


def cmd_silhouette(a):
    ca, cb = load_png(a.a), load_png(a.b)
    if (ca.w, ca.h) != (cb.w, cb.h):
        print(f"sizes differ: {ca.w}x{ca.h} against {cb.w}x{cb.h}")
        sys.exit(1)
    only_a, only_b = same_silhouette(ca, cb)
    if only_a or only_b:
        print(f"{len(only_a)} pixels opaque only in {a.a}: {only_a[:12]}")
        print(f"{len(only_b)} pixels opaque only in {a.b}: {only_b[:12]}")
        sys.exit(1)
    print(f"same silhouette ({len(alpha_set(ca))} opaque pixels)")


def cmd_anchors(a):
    import roomscenes
    canvas = roomscenes.SPRITES[a.id]()
    for an in canvas.anchors:
        print(" ".join(str(v) for v in an))


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    p = sub.add_parser("build")
    p.add_argument("id")
    p.add_argument("--out")
    p.set_defaults(fn=cmd_build)
    p = sub.add_parser("list")
    p.set_defaults(fn=cmd_list)
    p = sub.add_parser("silhouette")
    p.add_argument("a")
    p.add_argument("b")
    p.set_defaults(fn=cmd_silhouette)
    p = sub.add_parser("anchors")
    p.add_argument("id")
    p.set_defaults(fn=cmd_anchors)
    a = ap.parse_args()
    a.fn(a)


if __name__ == "__main__":
    main()
