#!/usr/bin/env python3
"""Lanternhold pixel-art pipeline: turns a Recraft painting into true pixel art. Pure python 3, no PIL.

One image per run; every run stays well under 20 s on the old Intel Mac (its heat rule).

Commands (run from anywhere; paths are plain file paths):

  pixelart.py boxes   <sheet.png> [--key auto|#RRGGBB] [--min 2000]
        Keys the background and prints the bounding box of every painted piece (connected blobs), to pick --box values.

  pixelart.py cut     <sheet.png> <out.png> --box x0,y0,x1,y1
        Writes the raw crop of a sheet (full resolution, untouched), for looking at a piece.

  pixelart.py convert <in.png> <out.png> --size WxH [options]
        key the background colour to alpha, crop to content, block-downscale to exactly WxH (dominant colour per block,
        median fallback), map to the palette, remove orphan pixels, binary alpha, optional outline, optional seamless
        horizontal tiling. Options:
          --box x0,y0,x1,y1       cut this box of a sheet first
          --key auto|none|#hex    background colour (auto: the most common border colour); default auto
          --tol 90                key distance in RGB
          --flood                 key only background joined to the border (key-like paint inside stays)
          --fit stretch|contain|cover   how the content box meets WxH (default stretch; contain pads bottom-centre,
                                  cover crops the sides and the top)
          --pad l,t,r,b           extra transparent margin in target pixels inside WxH (contain/stretch)
          --vote rgb|palette      block colour: dominant RGB bin then palette (default), or majority palette index
          --share 0.35            dominant-bin share below which the block takes the per-channel median
          --cover 0.5             share of opaque source pixels a block needs to be opaque
          --sat 1.0 --gain 1.0 --gamma 1.0 --warm 0   colour nudges before palette mapping
          --exclude n1,n2         palette names this image must not use
          --only n1,n2            restrict the palette to these names
          --allow-emissive        allow the fire ramp colours (flames painted into albedo: avoid)
          --allow-swap            allow the portrait swap ramps (tag "swap": skin1-4, hair1-4, cloth1-4; only the
                                  composed portrait parts use them, so no other conversion may pick them)
          --orphans 2             orphan clean-up passes
          --outline none|darken|NAME   1 px outline on opaque pixels touching transparency (inside the size)
          --outline-skip-bottom   no outline along the bottom row (things standing on the ground)
          --solid-bottom N        fill transparent holes in the bottom N rows (ground contact)
          --tile                  seamless horizontally (minimum-error seam over an overlap)
          --window dx,dy          stamp a dark 6x8 window recess at a scene window offset (dy up from the bottom);
                                  repeatable; --window-frame NAME --window-glass NAME
          --zone n1,n2@x0,y0,x1,y1[@gain]  map the blocks inside this rect with only these palette colours
                                  (and an extra brightness gain); repeatable
          --patch grid.txt[@x,y]  overlay a hand-drawn text grid (see grid; "?" keeps a pixel); repeatable
          --fill NAME:x0,y0,x1,y1 paint a palette colour into a rect (inclusive, top-left origin); repeatable
          --fill-holes NAME:x0,y0,x1,y1  paint only the transparent pixels inside a rect (a see-through gateway
                                  becomes a dark passage); repeatable
          --palette path          default: palette.txt next to this file
          --match old|new         match against each colour's match= value (default: the sprite keeps the indices it
                                  had before the look-2 palette revision) or against its current value (new paintings)

  pixelart.py split   <in.png> <out1.png> <out2.png> [...]
        Cuts a sprite into equal-width tiles, left to right (a seamless --tile panorama becomes tiles A, B, C that join
        in the order A-B-C-A).

  pixelart.py compose <out.png> --size WxH --layer path@x,y[@flip][@box=x0,y0,x1,y1] [...]
        Stacks finished palette sprites on a transparent canvas, later layers on top (opaque pixels only); a layer can
        be mirrored and cropped first. For hero pieces built from parts of several paintings.

  pixelart.py post    <in.png> <out.png> [ops, applied in this order]
        Touches up a finished palette sprite (M1b polish):
          --remap a:b[,c:d][@x0,y0,x1,y1]   swap palette colours (inside a rect); repeatable
          --clusters N[@x0,y0,x1,y1]        a 4-connected run of one colour smaller than N pixels takes its most
                                            common opaque neighbour colour (kills speckle and lone moss dots)
          --rim NAME@x0,y0,x1,y1@left|right[@w]  the outermost w (default 1) opaque pixels of every row in the rect,
                                            on that side, become NAME (a clean edge light instead of speckle)
          --fill NAME:x0,y0,x1,y1 / --fill-holes NAME:x0,y0,x1,y1   as in convert ("clear" empties a rect)
          --top-edge NAME:c1,c2…            a pixel of these colours whose upper neighbour is none of them becomes
                                            NAME (a highlight row along the top of water)
          --band NAME[,NAME…]:x0,y0,x1,y1    flattens the rect: every opaque pixel takes the nearest of these
                                            colours by value (a dithered strip becomes solid bands)

  pixelart.py grid    <grid.txt> <out.png>
        Builds a sprite from a text grid: a legend block "X = paletteName" lines, a line "---", then one row of
        characters per pixel row ("." is transparent).

  pixelart.py preview <in.png> <out.png> [--scale 6] [--bg #hex|checker] [--night] [--light x,y,r]...
        Nearest-neighbour upscale for looking at a result; --night multiplies by a cold night ambient and adds warm
        point lights (falloff (1-d/r)^2), roughly as the engine will light it.

  pixelart.py info    <in.png>
        Size, colour type, opaque share, palette colours used, and anything off-palette or semi-transparent.

Output PNGs are 8-bit RGBA, non-interlaced, without colour-profile chunks.
"""
import argparse
import math
import os
import struct
import sys
import zlib

HERE = os.path.dirname(os.path.abspath(__file__))
DEFAULT_PALETTE = os.path.join(HERE, "palette.txt")


# ----------------------------------------------------------------------------------------------------------------- PNG

class Image:
    """RGBA image as a flat list of (r, g, b, a) tuples, row-major."""

    def __init__(self, w, h, px=None):
        self.w = w
        self.h = h
        self.px = px if px is not None else [(0, 0, 0, 0)] * (w * h)

    def get(self, x, y):
        return self.px[y * self.w + x]

    def set(self, x, y, c):
        self.px[y * self.w + x] = c


def _unfilter(raw, w, h, bpp, stride, last_row):
    rows = []
    prev = bytearray(stride)
    i = 0
    for y in range(min(h, last_row)):
        f = raw[i]
        line = bytearray(raw[i + 1:i + 1 + stride])
        i += 1 + stride
        if f == 0:
            pass
        elif f == 1:
            for x in range(bpp, stride):
                line[x] = (line[x] + line[x - bpp]) & 255
        elif f == 2:
            line = bytearray([(a + b) & 255 for a, b in zip(line, prev)])
        elif f == 3:
            for x in range(bpp):
                line[x] = (line[x] + (prev[x] >> 1)) & 255
            for x in range(bpp, stride):
                line[x] = (line[x] + ((line[x - bpp] + prev[x]) >> 1)) & 255
        elif f == 4:
            for x in range(bpp):
                line[x] = (line[x] + prev[x]) & 255
            for x in range(bpp, stride):
                a = line[x - bpp]
                b = prev[x]
                c = prev[x - bpp]
                pa = b - c
                pb = a - c
                pc = pa + pb
                if pa < 0:
                    pa = -pa
                if pb < 0:
                    pb = -pb
                if pc < 0:
                    pc = -pc
                if pa <= pb and pa <= pc:
                    pr = a
                elif pb <= pc:
                    pr = b
                else:
                    pr = c
                line[x] = (line[x] + pr) & 255
        else:
            raise SystemExit(f"bad PNG filter type {f} in row {y}")
        rows.append(line)
        prev = line
    return rows


def read_png(path, box=None):
    """Reads a PNG (bit depth 1 to 16, colour types 0, 2, 3, 4, 6, non-interlaced) into an Image. With box
    (x0, y0, x1, y1, exclusive ends) only that region is converted."""
    with open(path, "rb") as fh:
        data = fh.read()
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        raise SystemExit(f"{path}: not a PNG")
    pos = 8
    idat = []
    plte = None
    trns = None
    ihdr = None
    while pos < len(data):
        length, ctype = struct.unpack(">I4s", data[pos:pos + 8])
        body = data[pos + 8:pos + 8 + length]
        pos += 12 + length
        if ctype == b"IHDR":
            ihdr = struct.unpack(">IIBBBBB", body)
        elif ctype == b"PLTE":
            plte = body
        elif ctype == b"tRNS":
            trns = body
        elif ctype == b"IDAT":
            idat.append(body)
        elif ctype == b"IEND":
            break
    w, h, depth, ctype, _, _, interlace = ihdr
    if interlace:
        raise SystemExit(f"{path}: interlaced PNGs are not supported")
    channels = {0: 1, 2: 3, 3: 1, 4: 2, 6: 4}[ctype]
    bits = channels * depth
    bpp = max(1, bits // 8)
    stride = (w * bits + 7) // 8
    raw = zlib.decompress(b"".join(idat))
    x0, y0, x1, y1 = box if box else (0, 0, w, h)
    x0, y0 = max(0, x0), max(0, y0)
    x1, y1 = min(w, x1), min(h, y1)
    rows = _unfilter(raw, w, h, bpp, stride, y1)
    out = []
    pal = []
    if ctype == 3:
        pal = [tuple(plte[i:i + 3]) for i in range(0, len(plte), 3)]
        alphas = list(trns) if trns else []
    tkey = None
    if trns and ctype in (0, 2):
        vals = struct.unpack(">" + "H" * (len(trns) // 2), trns)
        tkey = vals
    for y in range(y0, y1):
        line = rows[y]
        if depth == 8:
            if ctype == 6:
                seg = line[x0 * 4:x1 * 4]
                out.extend(zip(seg[0::4], seg[1::4], seg[2::4], seg[3::4]))
            elif ctype == 2:
                seg = line[x0 * 3:x1 * 3]
                if tkey:
                    for r, g, b in zip(seg[0::3], seg[1::3], seg[2::3]):
                        out.append((r, g, b, 0 if (r, g, b) == tkey else 255))
                else:
                    out.extend((r, g, b, 255) for r, g, b in zip(seg[0::3], seg[1::3], seg[2::3]))
            elif ctype == 0:
                for v in line[x0:x1]:
                    out.append((v, v, v, 0 if tkey and v == tkey[0] else 255))
            elif ctype == 4:
                seg = line[x0 * 2:x1 * 2]
                out.extend((v, v, v, a) for v, a in zip(seg[0::2], seg[1::2]))
            elif ctype == 3:
                for i in line[x0:x1]:
                    r, g, b = pal[i]
                    out.append((r, g, b, alphas[i] if i < len(alphas) else 255))
        elif depth == 16:
            vals = line  # take the high byte of every sample
            for x in range(x0, x1):
                s = [vals[(x * channels + c) * 2] for c in range(channels)]
                if ctype == 6:
                    out.append(tuple(s))
                elif ctype == 2:
                    out.append((s[0], s[1], s[2], 255))
                elif ctype == 0:
                    out.append((s[0], s[0], s[0], 255))
                elif ctype == 4:
                    out.append((s[0], s[0], s[0], s[1]))
        else:  # 1, 2 or 4 bits, grey or palette
            per = 8 // depth
            mask = (1 << depth) - 1
            for x in range(x0, x1):
                v = (line[x // per] >> ((per - 1 - x % per) * depth)) & mask
                if ctype == 3:
                    r, g, b = pal[v]
                    out.append((r, g, b, alphas[v] if v < len(alphas) else 255))
                else:
                    g = v * 255 // mask
                    out.append((g, g, g, 255))
    return Image(x1 - x0, y1 - y0, out), (w, h, depth, ctype)


def write_png(path, img):
    raw = bytearray()
    for y in range(img.h):
        raw.append(0)
        for r, g, b, a in img.px[y * img.w:(y + 1) * img.w]:
            raw += bytes((r, g, b, a))

    def chunk(t, body):
        c = struct.pack(">I", len(body)) + t + body
        return c + struct.pack(">I", zlib.crc32(t + body) & 0xFFFFFFFF)

    png = b"\x89PNG\r\n\x1a\n"
    png += chunk(b"IHDR", struct.pack(">IIBBBBB", img.w, img.h, 8, 6, 0, 0, 0))
    png += chunk(b"IDAT", zlib.compress(bytes(raw), 9))
    png += chunk(b"IEND", b"")
    d = os.path.dirname(path)
    if d:
        os.makedirs(d, exist_ok=True)
    with open(path, "wb") as fh:
        fh.write(png)


# ------------------------------------------------------------------------------------------------------------- palette

def parse_hex(s):
    s = s.strip().lstrip("#")
    return (int(s[0:2], 16), int(s[2:4], 16), int(s[4:6], 16))


def _lin(c):
    c /= 255.0
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def lab(rgb):
    r, g, b = (_lin(v) for v in rgb)
    x = (0.4124 * r + 0.3576 * g + 0.1805 * b) / 0.95047
    y = 0.2126 * r + 0.7152 * g + 0.0722 * b
    z = (0.0193 * r + 0.1192 * g + 0.9505 * b) / 1.08883

    def f(t):
        return t ** (1 / 3) if t > 0.008856 else 7.787 * t + 16 / 116

    fx, fy, fz = f(x), f(y), f(z)
    return (116 * fy - 16, 500 * (fx - fy), 200 * (fy - fz))


# Which colour a painting's pixels are matched against (look 2, ART-look2.md "Palette"): a palette line may carry a
# tag `match=#RRGGBB`, the colour's value before the look-2 revision. By default every conversion matches against it,
# so each sprite keeps exactly the palette indices it had (its zones, fills, remaps and clusters were tuned on them)
# and only the output colours change; `convert --match new` matches against the current values (new paintings).
MATCH = "old"


class Palette:
    def __init__(self, path, allow_emissive=False, exclude=(), only=(), allow_swap=False):
        self.names = []
        self.rgb = []
        self.mrgb = []  # the value paintings are matched against (the match= tag, else the colour itself)
        self.tags = []
        with open(path) as fh:
            for line in fh:
                s = line.strip()
                if not s or s.startswith("#"):
                    continue
                parts = s.split()
                tags = set(parts[2:])
                m = next((t[6:] for t in tags if t.startswith("match=")), None)
                self.names.append(parts[0])
                self.rgb.append(parse_hex(parts[1]))
                self.mrgb.append(parse_hex(m) if m and MATCH == "old" else parse_hex(parts[1]))
                self.tags.append(tags)
        self.allowed = []
        for i, name in enumerate(self.names):
            if only and name not in only:
                continue
            if name in exclude:
                continue
            if "emissive" in self.tags[i] and not allow_emissive:
                continue
            if MATCH == "old" and "new" in self.tags[i] and not only:
                continue  # an old painting never lands on a look-2 colour unless an --only list names it
            if "swap" in self.tags[i] and not allow_swap:
                continue
            self.allowed.append(i)
        self.labs = [lab(c) for c in self.mrgb]
        self.cache = {}

    def index(self, name):
        try:
            return self.names.index(name)
        except ValueError:
            raise SystemExit(f"unknown palette colour {name}")

    def color(self, name):
        return self.rgb[self.index(name)]

    def nearest(self, rgb):
        hit = self.cache.get(rgb)
        if hit is not None:
            return hit
        L, A, B = lab(rgb)
        best = None
        bestd = 1e18
        for i in self.allowed:
            l2, a2, b2 = self.labs[i]
            # a little more weight on lightness: value structure matters most under the night ambient
            d = 1.3 * (L - l2) ** 2 + (A - a2) ** 2 + (B - b2) ** 2
            if d < bestd:
                bestd = d
                best = i
        self.cache[rgb] = best
        return best


# ------------------------------------------------------------------------------------------------------------ keying

def border_key(img):
    counts = {}
    w, h = img.w, img.h
    for x in range(w):
        for y in (0, h - 1):
            c = img.get(x, y)[:3]
            k = (c[0] >> 3, c[1] >> 3, c[2] >> 3)
            counts[k] = counts.get(k, 0) + 1
    for y in range(h):
        for x in (0, w - 1):
            c = img.get(x, y)[:3]
            k = (c[0] >> 3, c[1] >> 3, c[2] >> 3)
            counts[k] = counts.get(k, 0) + 1
    k = max(counts, key=counts.get)
    return (k[0] * 8 + 4, k[1] * 8 + 4, k[2] * 8 + 4)


def hsv(c):
    r, g, b = c[0] / 255, c[1] / 255, c[2] / 255
    mx, mn = max(r, g, b), min(r, g, b)
    d = mx - mn
    if d == 0:
        h = 0.0
    elif mx == r:
        h = 60 * (((g - b) / d) % 6)
    elif mx == g:
        h = 60 * ((b - r) / d + 2)
    else:
        h = 60 * ((r - g) / d + 4)
    return h, (d / mx if mx else 0), mx


def key_out(img, key, tol, flood=False):
    """Background colour to alpha 0, everything else alpha 255 (binary). A magenta key also removes the magenta-tinted
    anti-alias fringe."""
    kr, kg, kb = key
    tol2 = tol * tol
    khue, ksat, _ = hsv(key)
    w, h = img.w, img.h
    out = []
    for r, g, b, a in img.px:
        dr, dg, db = r - kr, g - kg, b - kb
        if a < 128 or dr * dr + dg * dg + db * db <= tol2:
            out.append((0, 0, 0, 0))
        else:
            out.append((r, g, b, 255))
    if flood:
        # only background joined to the border counts; key-like paint enclosed by the painting stays
        keep = bytearray(w * h)
        stack = [i for i in range(w * h) if (i < w or i >= w * (h - 1) or i % w in (0, w - 1)) and not out[i][3]]
        for i in stack:
            keep[i] = 1
        while stack:
            i = stack.pop()
            y, x = divmod(i, w)
            for j in (i - 1 if x > 0 else -1, i + 1 if x < w - 1 else -1, i - w, i + w):
                if 0 <= j < w * h and not keep[j] and not out[j][3]:
                    keep[j] = 1
                    stack.append(j)
        for i, p in enumerate(out):
            if not p[3] and not keep[i]:
                r, g, b, _ = img.px[i]
                out[i] = (r, g, b, 255)
    if ksat > 0.6:
        # a saturated key (magenta, pink, green): pixels of the key's hue within 2 px of the background are its
        # anti-alias fringe; inside the painting the same hue is left alone
        near = bytearray(w * h)
        for i, p in enumerate(out):
            if not p[3]:
                y, x = divmod(i, w)
                if not ((x > 0 and out[i - 1][3]) or (x < w - 1 and out[i + 1][3]) or
                        (y > 0 and out[i - w][3]) or (y < h - 1 and out[i + w][3])):
                    continue
                for yy in range(max(0, y - 2), min(h, y + 3)):
                    base = yy * w
                    for xx in range(max(0, x - 2), min(w, x + 3)):
                        near[base + xx] = 1
        for i, p in enumerate(out):
            if p[3] and near[i]:
                hh, ss, vv = hsv(p)
                dh = abs(hh - khue)
                if min(dh, 360 - dh) < 30 and ss > 0.45 and vv > 0.35:
                    out[i] = (0, 0, 0, 0)
    img.px = out
    return img


def content_box(img, min_count=3):
    w, h = img.w, img.h
    cols = [0] * w
    rows = [0] * h
    px = img.px
    for y in range(h):
        base = y * w
        n = 0
        for x in range(w):
            if px[base + x][3]:
                cols[x] += 1
                n += 1
        rows[y] = n
    xs = [x for x in range(w) if cols[x] >= min_count]
    ys = [y for y in range(h) if rows[y] >= min_count]
    if not xs or not ys:
        raise SystemExit("no content left after keying")
    return xs[0], ys[0], xs[-1] + 1, ys[-1] + 1


# --------------------------------------------------------------------------------------------------------- downscale

def _median(vals):
    vals.sort()
    return vals[len(vals) // 2]


def block_colors(img, box, tw, th, fit, pad, cover, share, vote, pal):
    """Returns a th x tw grid of RGB tuples or None (transparent), or palette indices when vote == 'palette'."""
    bx0, by0, bx1, by1 = box
    bw, bh = bx1 - bx0, by1 - by0
    pl, pt, pr, pb = pad
    aw, ah = tw - pl - pr, th - pt - pb  # area the content fills
    if fit == "stretch":
        sx, sy = bw / aw, bh / ah
        ox, oy = pl, pt
        cw, ch = aw, ah
        srcx0, srcy0 = bx0, by0
    elif fit == "contain":
        s = max(bw / aw, bh / ah)
        sx = sy = s
        cw, ch = round(bw / s), round(bh / s)
        ox = pl + (aw - cw) // 2
        oy = pt + (ah - ch)  # bottom aligned
        srcx0, srcy0 = bx0, by0
    elif fit == "cover":
        s = min(bw / aw, bh / ah)
        sx = sy = s
        cw, ch = aw, ah
        ox, oy = pl, pt
        srcx0 = bx0 + (bw - aw * s) / 2
        srcy0 = by0 + (bh - ah * s)  # keep the bottom
    else:
        raise SystemExit(f"bad --fit {fit}")
    grid = [[None] * tw for _ in range(th)]
    px = img.px
    w = img.w
    for ty in range(ch):
        ya = int(round(srcy0 + ty * sy))
        yb = max(ya + 1, int(round(srcy0 + (ty + 1) * sy)))
        for tx in range(cw):
            xa = int(round(srcx0 + tx * sx))
            xb = max(xa + 1, int(round(srcx0 + (tx + 1) * sx)))
            total = 0
            opaque = []
            for y in range(ya, min(yb, img.h)):
                base = y * w
                for x in range(xa, min(xb, w)):
                    total += 1
                    p = px[base + x]
                    if p[3]:
                        opaque.append(p)
            if not total or len(opaque) < cover * total:
                continue
            if vote == "palette":
                counts = {}
                for p in opaque:
                    i = pal.nearest(p[:3])
                    counts[i] = counts.get(i, 0) + 1
                grid[oy + ty][ox + tx] = ("i", max(counts, key=counts.get))
                continue
            bins = {}
            for p in opaque:
                k = (p[0] >> 4, p[1] >> 4, p[2] >> 4)
                bins.setdefault(k, []).append(p)
            top = max(bins.values(), key=len)
            if len(top) >= share * len(opaque):
                n = len(top)
                c = (sum(p[0] for p in top) // n, sum(p[1] for p in top) // n, sum(p[2] for p in top) // n)
            else:
                c = (_median([p[0] for p in opaque]), _median([p[1] for p in opaque]),
                     _median([p[2] for p in opaque]))
            grid[oy + ty][ox + tx] = c
    return grid


def nudge(c, sat, gain, gamma, warm):
    r, g, b = c
    if gamma != 1.0:
        r = 255 * (r / 255) ** gamma
        g = 255 * (g / 255) ** gamma
        b = 255 * (b / 255) ** gamma
    r, g, b = r * gain, g * gain, b * gain
    if sat != 1.0:
        y = 0.299 * r + 0.587 * g + 0.114 * b
        r, g, b = y + (r - y) * sat, y + (g - y) * sat, y + (b - y) * sat
    if warm:
        r, b = r + warm, b - warm
    return tuple(max(0, min(255, int(round(v)))) for v in (r, g, b))


# ----------------------------------------------------------------------------------------------------------- clean-up

def remove_orphans(idx, w, h, passes):
    """idx: list of rows of palette indices or None. A pixel whose 4 in-image neighbours are all one other value takes
    that value (a lone opaque speck in transparency goes; a lone hole in paint fills)."""
    for _ in range(passes):
        changed = 0
        new = [row[:] for row in idx]
        for y in range(h):
            for x in range(w):
                v = idx[y][x]
                nb = []
                if x > 0:
                    nb.append(idx[y][x - 1])
                if x < w - 1:
                    nb.append(idx[y][x + 1])
                if y > 0:
                    nb.append(idx[y - 1][x])
                if y < h - 1:
                    nb.append(idx[y + 1][x])
                if len(nb) >= 3 and all(n == nb[0] for n in nb) and nb[0] != v:
                    new[y][x] = nb[0]
                    changed += 1
                elif len(nb) == 4 and v is not None:
                    # a single pixel whose neighbours hold one value three times and itself none: tidy to the majority
                    counts = {}
                    for n in nb:
                        counts[n] = counts.get(n, 0) + 1
                    m = max(counts, key=counts.get)
                    if counts[m] == 3 and v not in counts and m is None:
                        new[y][x] = None
                        changed += 1
        idx = new
        if not changed:
            break
    return idx


def outline(idx, w, h, pal, how, skip_bottom):
    if how == "none":
        return idx
    fixed = None if how == "darken" else pal.index(how)
    new = [row[:] for row in idx]
    for y in range(h):
        for x in range(w):
            v = idx[y][x]
            if v is None:
                continue
            edge = False
            for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
                if 0 <= nx < w and 0 <= ny < h:
                    if idx[ny][nx] is None:
                        edge = True
                elif ny == h and skip_bottom:
                    continue
            if not edge:
                continue
            if skip_bottom and y == h - 1 and x not in (0, w - 1):
                left = idx[y][x - 1] if x > 0 else None
                right = idx[y][x + 1] if x < w - 1 else None
                up = idx[y - 1][x] if y > 0 else None
                if left is not None and right is not None and up is not None:
                    continue
            if fixed is not None:
                new[y][x] = fixed
            else:
                r, g, b = pal.mrgb[v]  # darkened from the matched value, so the outline keeps its old index
                new[y][x] = pal.nearest((int(r * 0.42), int(g * 0.38), int(b * 0.5)))
    return new


def tile_seam(idx, tw, h, overlap, pal):
    """idx is (tw + overlap) wide. Returns tw columns whose right edge continues into the left edge: the first `overlap`
    columns take the painting's continuation (columns tw ...) up to a per-row seam chosen by dynamic programming where
    the two layers agree best, then the painting itself."""
    def cost(a, b):
        if a == b:
            return 0.0
        if a is None or b is None:
            return 400.0
        la, lb = pal.labs[a], pal.labs[b]
        return (la[0] - lb[0]) ** 2 + (la[1] - lb[1]) ** 2 + (la[2] - lb[2]) ** 2

    # seam position c in 0..overlap per row; error = sum over columns near c of the mismatch at the cut
    err = [[cost(idx[y][tw + c - 1] if c > 0 else idx[y][tw - 1], idx[y][c]) if c < overlap else 1e9
            for c in range(overlap + 1)] for y in range(h)]
    for y in range(h):
        err[y][0] = 1e9  # always take at least one continuation column so the wrap is exact
    acc = [row[:] for row in err]
    back = [[0] * (overlap + 1) for _ in range(h)]
    for y in range(1, h):
        for c in range(overlap + 1):
            best, bc = 1e18, c
            for d in (-1, 0, 1):
                cc = c + d
                if 0 <= cc <= overlap and acc[y - 1][cc] < best:
                    best, bc = acc[y - 1][cc], cc
            acc[y][c] = err[y][c] + best
            back[y][c] = bc
    c = min(range(overlap + 1), key=lambda k: acc[h - 1][k])
    seams = [0] * h
    for y in range(h - 1, -1, -1):
        seams[y] = c
        c = back[y][c]
    out = []
    for y in range(h):
        c = seams[y]
        row = [idx[y][tw + x] if x < c else idx[y][x] for x in range(tw)]
        out.append(row)
    return out


# ------------------------------------------------------------------------------------------------------------ commands

def parse_box(s):
    v = [int(t) for t in s.split(",")]
    if len(v) != 4:
        raise SystemExit("--box needs x0,y0,x1,y1")
    return tuple(v)


def cmd_boxes(a):
    img, info = read_png(a.input)
    key = border_key(img) if a.key == "auto" else parse_hex(a.key)
    print(f"sheet {info[0]}x{info[1]}, key {'#%02X%02X%02X' % key}")
    step = 4
    w, h = img.w // step, img.h // step
    small = Image(w, h, [img.get(x * step, y * step) for y in range(h) for x in range(w)])
    key_out(small, key, a.tol)
    seen = [False] * (w * h)
    blobs = []
    for start in range(w * h):
        if seen[start] or not small.px[start][3]:
            continue
        stack = [start]
        seen[start] = True
        x0 = y0 = 1 << 30
        x1 = y1 = -1
        n = 0
        while stack:
            p = stack.pop()
            y, x = divmod(p, w)
            n += 1
            x0, x1, y0, y1 = min(x0, x), max(x1, x), min(y0, y), max(y1, y)
            for q in (p - 1 if x > 0 else -1, p + 1 if x < w - 1 else -1, p - w, p + w):
                if 0 <= q < w * h and not seen[q] and small.px[q][3]:
                    seen[q] = True
                    stack.append(q)
        if n * step * step >= a.min:
            blobs.append((y0, x0, x1, y1, n))
    blobs.sort()
    for y0, x0, x1, y1, n in blobs:
        print(f"box {x0 * step},{y0 * step},{(x1 + 1) * step},{(y1 + 1) * step}  "
              f"({(x1 - x0 + 1) * step}x{(y1 - y0 + 1) * step}, {n * step * step} px)")


def cmd_cut(a):
    img, _ = read_png(a.input, parse_box(a.box))
    write_png(a.output, img)
    print(f"wrote {a.output} {img.w}x{img.h}")


def put(idx, w, h, x, y, v, only_opaque=False):
    if 0 <= x < w and 0 <= y < h and (not only_opaque or idx[y][x] is not None):
        idx[y][x] = v


def cmd_convert(a):
    global MATCH
    MATCH = a.match
    tw, th = (int(v) for v in a.size.lower().split("x"))
    pal = Palette(a.palette, a.allow_emissive, set(a.exclude.split(",")) if a.exclude else set(),
                  set(a.only.split(",")) if a.only else set(), a.allow_swap)
    box = parse_box(a.box) if a.box else None
    img, info = read_png(a.input, box)
    if a.key != "none":
        key = border_key(img) if a.key == "auto" else parse_hex(a.key)
        key_out(img, key, a.tol, a.flood)
    cbox = content_box(img, a.min_count)
    pad = tuple(int(v) for v in a.pad.split(",")) if a.pad else (0, 0, 0, 0)
    overlap = 0
    gw = tw
    if a.tile:
        overlap = max(6, tw // 6)
        gw = tw + overlap
    grid = block_colors(img, cbox, gw, th, a.fit, pad, a.cover, a.share, a.vote, pal)
    idx = []
    for row in grid:
        out = []
        for c in row:
            if c is None:
                out.append(None)
            elif c[0] == "i":
                out.append(c[1])
            else:
                out.append(pal.nearest(nudge(c, a.sat, a.gain, a.gamma, a.warm)))
        idx.append(out)
    for spec in a.zone or []:
        parts = spec.split("@")
        names, rect = parts[0], parts[1]
        zgain = float(parts[2]) if len(parts) > 2 else 1.0
        x0, y0, x1, y1 = (int(v) for v in rect.split(","))
        zpal = Palette(a.palette, a.allow_emissive, set(), set(names.split(",")), a.allow_swap)
        for y in range(max(0, y0), min(th, y1 + 1)):
            for x in range(max(0, x0), min(gw, x1 + 1)):
                c = grid[y][x]
                if c is not None and c[0] != "i":
                    idx[y][x] = zpal.nearest(nudge(c, a.sat, a.gain * zgain, a.gamma, a.warm))
    if a.tile:
        idx = tile_seam(idx, tw, th, overlap, pal)
    idx = remove_orphans(idx, tw, th, a.orphans)
    if a.solid_bottom:
        for y in range(th - a.solid_bottom, th):
            row = idx[y]
            for x in range(tw):
                if row[x] is None:
                    l = next((row[i] for i in range(x - 1, -1, -1) if row[i] is not None), None)
                    r = next((row[i] for i in range(x + 1, tw) if row[i] is not None), None)
                    if l is not None and r is not None:
                        row[x] = l
    for spec in a.fill_holes or []:
        name, rect = spec.split(":")
        x0, y0, x1, y1 = (int(v) for v in rect.split(","))
        v = pal.index(name)
        for y in range(max(0, y0), min(th, y1 + 1)):
            for x in range(max(0, x0), min(tw, x1 + 1)):
                if idx[y][x] is None:
                    idx[y][x] = v
    for spec in a.fill or []:
        name, rect = spec.split(":")
        x0, y0, x1, y1 = (int(v) for v in rect.split(","))
        v = None if name == "clear" else pal.index(name)
        for y in range(max(0, y0), min(th, y1 + 1)):
            for x in range(max(0, x0), min(tw, x1 + 1)):
                idx[y][x] = v
    idx = outline(idx, tw, th, pal, a.outline, a.outline_skip_bottom)
    for spec in a.patch or []:
        path, at = spec.split("@") if "@" in spec else (spec, "0,0")
        px0, py0 = (int(v) for v in at.split(","))
        legend, rows = read_grid(path, pal)
        for y, row in enumerate(rows):
            for x, ch in enumerate(row):
                if ch == "?":
                    continue
                put(idx, tw, th, px0 + x, py0 + y, legend[ch])
    if a.window:
        frame = pal.index(a.window_frame)
        glass = pal.index(a.window_glass)
        sill = pal.index(a.window_sill)
        for spec in a.window:
            dx, dy = (int(v) for v in spec.split(","))
            top = th - dy - 8
            for y in range(top, top + 8):
                for x in range(dx, dx + 6):
                    if 0 <= x < tw and 0 <= y < th:
                        idx[y][x] = glass
            for x in (dx, dx + 5):  # arched head: the top corners stay masonry
                put(idx, tw, th, x, top, frame)
            for y in range(top, top + 8):  # jambs, only where there is wall
                for x in (dx - 1, dx + 6):
                    put(idx, tw, th, x, y, frame, only_opaque=True)
            for x in range(dx, dx + 6):  # lintel
                put(idx, tw, th, x, top - 1, frame, only_opaque=True)
            for x in range(dx - 1, dx + 7):  # a light sill under it
                put(idx, tw, th, x, top + 8, sill, only_opaque=True)
    out = Image(tw, th)
    for y in range(th):
        for x in range(tw):
            v = idx[y][x]
            if v is not None:
                r, g, b = pal.rgb[v]
                out.set(x, y, (r, g, b, 255))
    write_png(a.output, out)
    used = sorted({v for row in idx for v in row if v is not None})
    opaque = sum(1 for row in idx for v in row if v is not None)
    print(f"wrote {a.output} {tw}x{th} from {info[0]}x{info[1]} content box {cbox}, "
          f"{len(used)} colours, {100 * opaque // (tw * th)} % opaque")


def cmd_split(a):
    img, _ = read_png(a.input)
    n = len(a.outputs)
    if img.w % n:
        raise SystemExit(f"{img.w} px do not split into {n} equal tiles")
    tw = img.w // n
    for k, path in enumerate(a.outputs):
        out = Image(tw, img.h, [img.get(k * tw + x, y) for y in range(img.h) for x in range(tw)])
        write_png(path, out)
        print(f"wrote {path} {tw}x{img.h}")


def cmd_compose(a):
    tw, th = (int(v) for v in a.size.lower().split("x"))
    out = Image(tw, th)
    for spec in a.layer:
        parts = spec.split("@")
        path, at = parts[0], parts[1]
        ox, oy = (int(v) for v in at.split(","))
        flip = "flip" in parts[2:]
        box = next((parse_box(p[4:]) for p in parts[2:] if p.startswith("box=")), None)
        img, _ = read_png(path)
        x0, y0, x1, y1 = box or (0, 0, img.w, img.h)
        for y in range(y0, y1):
            for x in range(x0, x1):
                p = img.get(x1 - 1 - (x - x0) if flip else x, y)
                if p[3]:
                    tx, ty = ox + x - x0, oy + y - y0
                    if 0 <= tx < tw and 0 <= ty < th:
                        out.set(tx, ty, p)
    write_png(a.output, out)
    print(f"wrote {a.output} {tw}x{th}")


def read_grid(path, pal):
    """A text grid: legend lines "X = paletteName", a line "---", then one row of characters per pixel row.
    "." is transparent; "?" keeps what is there (patches only)."""
    with open(path) as fh:
        lines = fh.read().splitlines()
    legend = {".": None}
    i = 0
    while lines[i].strip() != "---":
        s = lines[i].strip()
        if s and not s.startswith("#"):
            ch, name = (t.strip() for t in s.split("=", 1))
            legend[ch] = pal.index(name)
        i += 1
    rows = [l.rstrip() for l in lines[i + 1:] if l.strip()]
    return legend, rows


def cmd_grid(a):
    pal = Palette(a.palette, True)
    legend, rows = read_grid(a.input, pal)
    w = max(len(r) for r in rows)
    out = Image(w, len(rows))
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            v = legend[ch]
            if v is not None:
                r, g, b = pal.rgb[v]
                out.set(x, y, (r, g, b, 255))
    write_png(a.output, out)
    print(f"wrote {a.output} {w}x{len(rows)}")


def cmd_preview(a):
    img, _ = read_png(a.input)
    s = a.scale
    lights = [tuple(float(v) for v in l.split(",")) for l in (a.light or [])]
    amb = (0.20, 0.22, 0.42)
    warm = (1.0, 0.72, 0.38)
    rows = []
    for y in range(img.h):
        row = []
        for x in range(img.w):
            r, g, b, al = img.get(x, y)
            if a.bg == "checker":
                bgc = (70, 64, 80) if ((x // 2 + y // 2) % 2) else (90, 84, 100)
            else:
                bgc = parse_hex(a.bg)
            if a.night:
                lr, lg, lb = amb
                for lx, ly, rad in lights:
                    d = math.hypot(x + 0.5 - lx, (y + 0.5 - ly) * 1.25)
                    if d < rad:
                        f = (1 - d / rad) ** 2 * 1.4
                        lr, lg, lb = lr + warm[0] * f, lg + warm[1] * f, lb + warm[2] * f
                if al:
                    r, g, b = (min(255, int(r * lr)), min(255, int(g * lg)), min(255, int(b * lb)))
                bgc = (int(bgc[0] * amb[0]), int(bgc[1] * amb[1]), int(bgc[2] * amb[2]))
            row.append((r, g, b, 255) if al else (bgc[0], bgc[1], bgc[2], 255))
        big = []
        for c in row:
            big.extend([c] * s)
        for _ in range(s):
            rows.extend(big)
    write_png(a.output, Image(img.w * s, img.h * s, rows))
    print(f"wrote {a.output} {img.w * s}x{img.h * s}")


def cmd_info(a):
    img, info = read_png(a.input)
    pal = Palette(a.palette, True)
    lut = {c: n for n, c in zip(pal.names, pal.rgb)}
    used = {}
    off = set()
    semi = 0
    opaque = 0
    for r, g, b, al in img.px:
        if 0 < al < 255:
            semi += 1
        if al:
            opaque += 1
            n = lut.get((r, g, b))
            if n:
                used[n] = used.get(n, 0) + 1
            else:
                off.add((r, g, b))
    print(f"{a.input}: {img.w}x{img.h}, depth {info[2]}, colour type {info[3]}, "
          f"{100 * opaque // max(1, img.w * img.h)} % opaque, {semi} semi-transparent, {len(off)} off-palette colours")
    for n, k in sorted(used.items(), key=lambda t: -t[1]):
        print(f"  {n:12s} {k}")


def _rect(spec, w, h):
    x0, y0, x1, y1 = (int(v) for v in spec.split(","))
    return max(0, x0), max(0, y0), min(w - 1, x1), min(h - 1, y1)


def cmd_post(a):
    img, _ = read_png(a.input)
    pal = Palette(a.palette, True)
    lut = {c: i for i, c in enumerate(pal.rgb)}
    w, h = img.w, img.h
    idx = [[(lut[img.get(x, y)[:3]] if img.get(x, y)[3] else None) for x in range(w)] for y in range(h)]
    for spec in a.remap or []:
        pairs, _, rect = spec.partition("@")
        x0, y0, x1, y1 = _rect(rect, w, h) if rect else (0, 0, w - 1, h - 1)
        m = {pal.index(f): pal.index(t) for f, t in (pr.split(":") for pr in pairs.split(","))}
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                if idx[y][x] in m:
                    idx[y][x] = m[idx[y][x]]
    for spec in a.clusters or []:
        n, _, rect = spec.partition("@")
        n = int(n)
        x0, y0, x1, y1 = _rect(rect, w, h) if rect else (0, 0, w - 1, h - 1)
        for _pass in range(3):
            seen = [[False] * w for _ in range(h)]
            changed = 0
            for sy in range(y0, y1 + 1):
                for sx in range(x0, x1 + 1):
                    v = idx[sy][sx]
                    if v is None or seen[sy][sx]:
                        continue
                    comp, stack = [], [(sx, sy)]
                    seen[sy][sx] = True
                    while stack:
                        cx, cy = stack.pop()
                        comp.append((cx, cy))
                        for nx, ny in ((cx - 1, cy), (cx + 1, cy), (cx, cy - 1), (cx, cy + 1)):
                            if x0 <= nx <= x1 and y0 <= ny <= y1 and not seen[ny][nx] and idx[ny][nx] == v:
                                seen[ny][nx] = True
                                stack.append((nx, ny))
                    if len(comp) >= n:
                        continue
                    counts = {}
                    for cx, cy in comp:
                        for nx, ny in ((cx - 1, cy), (cx + 1, cy), (cx, cy - 1), (cx, cy + 1)):
                            if 0 <= nx < w and 0 <= ny < h:
                                u = idx[ny][nx]
                                if u is not None and u != v:
                                    counts[u] = counts.get(u, 0) + 1
                    if counts:
                        u = max(counts, key=counts.get)
                        for cx, cy in comp:
                            idx[cy][cx] = u
                        changed += 1
            if not changed:
                break
    for spec in a.top_edge or []:
        name, cols = spec.split(":")
        members = {pal.index(c) for c in cols.split(",")}
        v = pal.index(name)
        new = [row[:] for row in idx]
        for y in range(1, h):
            for x in range(w):
                if idx[y][x] in members and idx[y - 1][x] not in members:
                    new[y][x] = v
        idx = new
    for spec in a.rim or []:
        parts = spec.split("@")
        v = pal.index(parts[0])
        x0, y0, x1, y1 = _rect(parts[1], w, h)
        side = parts[2]
        rw = int(parts[3]) if len(parts) > 3 else 1
        for y in range(y0, y1 + 1):
            xs = range(x1, x0 - 1, -1) if side == "right" else range(x0, x1 + 1)
            k = 0
            for x in xs:
                if idx[y][x] is not None:
                    idx[y][x] = v
                    k += 1
                    if k >= rw:
                        break
    for spec in a.band or []:
        names, rect = spec.split(":")
        x0, y0, x1, y1 = _rect(rect, w, h)
        cand = [pal.index(n) for n in names.split(",")]
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                if idx[y][x] is not None:
                    L = pal.labs[idx[y][x]][0]
                    idx[y][x] = min(cand, key=lambda c: abs(pal.labs[c][0] - L))
    for spec in a.fill_holes or []:
        name, rect = spec.split(":")
        x0, y0, x1, y1 = _rect(rect, w, h)
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                if idx[y][x] is None:
                    idx[y][x] = pal.index(name)
    for spec in a.fill or []:
        name, rect = spec.split(":")
        x0, y0, x1, y1 = _rect(rect, w, h)
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                idx[y][x] = None if name == "clear" else pal.index(name)
    out = Image(w, h)
    for y in range(h):
        for x in range(w):
            if idx[y][x] is not None:
                r, g, b = pal.rgb[idx[y][x]]
                out.set(x, y, (r, g, b, 255))
    write_png(a.output, out)
    print(f"wrote {a.output} {w}x{h} (post)")


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = p.add_subparsers(dest="cmd", required=True)

    b = sub.add_parser("boxes")
    b.add_argument("input")
    b.add_argument("--key", default="auto")
    b.add_argument("--tol", type=float, default=90)
    b.add_argument("--min", type=int, default=2000)
    b.set_defaults(fn=cmd_boxes)

    c = sub.add_parser("cut")
    c.add_argument("input")
    c.add_argument("output")
    c.add_argument("--box", required=True)
    c.set_defaults(fn=cmd_cut)

    v = sub.add_parser("convert")
    v.add_argument("input")
    v.add_argument("output")
    v.add_argument("--size", required=True)
    v.add_argument("--box")
    v.add_argument("--key", default="auto")
    v.add_argument("--tol", type=float, default=90)
    v.add_argument("--flood", action="store_true")
    v.add_argument("--min-count", type=int, default=3)
    v.add_argument("--fit", default="stretch")
    v.add_argument("--pad")
    v.add_argument("--vote", default="rgb", choices=["rgb", "palette"])
    v.add_argument("--share", type=float, default=0.35)
    v.add_argument("--cover", type=float, default=0.5)
    v.add_argument("--sat", type=float, default=1.0)
    v.add_argument("--gain", type=float, default=1.0)
    v.add_argument("--gamma", type=float, default=1.0)
    v.add_argument("--warm", type=float, default=0)
    v.add_argument("--exclude")
    v.add_argument("--only")
    v.add_argument("--allow-emissive", action="store_true")
    v.add_argument("--allow-swap", action="store_true")
    v.add_argument("--orphans", type=int, default=2)
    v.add_argument("--outline", default="none")
    v.add_argument("--outline-skip-bottom", action="store_true")
    v.add_argument("--solid-bottom", type=int, default=0)
    v.add_argument("--tile", action="store_true")
    v.add_argument("--window", action="append")
    v.add_argument("--window-frame", default="stoneDark")
    v.add_argument("--window-glass", default="night1")
    v.add_argument("--window-sill", default="stoneLight")
    v.add_argument("--fill", action="append")
    v.add_argument("--fill-holes", action="append")
    v.add_argument("--zone", action="append")
    v.add_argument("--patch", action="append")
    v.add_argument("--palette", default=DEFAULT_PALETTE)
    v.add_argument("--match", default="old", choices=["old", "new"])
    v.set_defaults(fn=cmd_convert)

    sp = sub.add_parser("split")
    sp.add_argument("input")
    sp.add_argument("outputs", nargs="+")
    sp.set_defaults(fn=cmd_split)

    cp = sub.add_parser("compose")
    cp.add_argument("output")
    cp.add_argument("--size", required=True)
    cp.add_argument("--layer", action="append", required=True)
    cp.set_defaults(fn=cmd_compose)

    g = sub.add_parser("grid")
    g.add_argument("input")
    g.add_argument("output")
    g.add_argument("--palette", default=DEFAULT_PALETTE)
    g.set_defaults(fn=cmd_grid)

    r = sub.add_parser("preview")
    r.add_argument("input")
    r.add_argument("output")
    r.add_argument("--scale", type=int, default=6)
    r.add_argument("--bg", default="checker")
    r.add_argument("--night", action="store_true")
    r.add_argument("--light", action="append")
    r.set_defaults(fn=cmd_preview)

    i = sub.add_parser("info")
    i.add_argument("input")
    i.add_argument("--palette", default=DEFAULT_PALETTE)
    i.set_defaults(fn=cmd_info)

    po = sub.add_parser("post")
    po.add_argument("input")
    po.add_argument("output")
    for opt in ("--remap", "--clusters", "--top-edge", "--rim", "--band", "--fill", "--fill-holes"):
        po.add_argument(opt, action="append")
    po.add_argument("--palette", default=DEFAULT_PALETTE)
    po.set_defaults(fn=cmd_post)

    a = p.parse_args()
    a.fn(a)


if __name__ == "__main__":
    main()
