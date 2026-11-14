"""A small painter for the lantern slides (panels lane, docs/lanes/panels.md). Pure python 3, no PIL.

A slide is painted like the game's own art (ART-look2.md): flat value levels and clusters, colours from
tools/palette.txt, the cold blue dark against the warm fire, light pools with an edge, dither only in the sky's bands.
The game's sprites (Resources/Art) can be placed and lit. Everything is deterministic: the same call paints the same
slide, byte for byte.
"""
import math
import os
import sys
import zlib
import struct

HERE = os.path.dirname(os.path.abspath(__file__))
GAME = os.path.normpath(os.path.join(HERE, "..", ".."))
sys.path.insert(0, os.path.join(GAME, "tools", "scenemock"))
from pngr import read_png  # noqa: E402

W, H = 320, 160


def hexc(value):
    value = value.lstrip("#")
    return (int(value[0:2], 16), int(value[2:4], 16), int(value[4:6], 16))


def load_palette():
    names = {}
    for line in open(os.path.join(GAME, "tools", "palette.txt"), encoding="utf-8"):
        line = line.split("#", 1)[0] if line.lstrip().startswith("#") else line
        parts = line.split()
        if len(parts) >= 2 and parts[1].startswith("#") and len(parts[1]) == 7:
            names[parts[0]] = hexc(parts[1])
    return names


PAL = load_palette()


def P(name):
    """A palette colour by name (or a #hex for the few painted mixes between two palette colours)."""
    if name.startswith("#"):
        return hexc(name)
    return PAL[name]


def mix(a, b, t):
    t = 0.0 if t < 0 else 1.0 if t > 1 else t
    return (a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t, a[2] + (b[2] - a[2]) * t)


def mul(a, b):
    return (a[0] * b[0] / 255.0, a[1] * b[1] / 255.0, a[2] * b[2] / 255.0)


def scale(a, k):
    return (a[0] * k, a[1] * k, a[2] * k)


def add(a, b, k=1.0):
    return (a[0] + b[0] * k, a[1] + b[1] * k, a[2] + b[2] * k)


def clamp(v, lo=0.0, hi=1.0):
    return lo if v < lo else hi if v > hi else v


def smooth(e0, e1, x):
    t = clamp((x - e0) / (e1 - e0)) if e1 != e0 else (1.0 if x >= e1 else 0.0)
    return t * t * (3 - 2 * t)


def luma(c):
    return (0.2126 * c[0] + 0.7152 * c[1] + 0.0722 * c[2]) / 255.0


# --- noise -------------------------------------------------------------------------------------------------------

def h2(x, y, seed=0):
    n = (x * 374761393 + y * 668265263 + seed * 2147483647) & 0xFFFFFFFF
    n = ((n ^ (n >> 13)) * 1274126177) & 0xFFFFFFFF
    n = n ^ (n >> 16)
    return (n & 0xFFFF) / 65535.0


def h1(x, seed=0):
    return h2(x, 7919, seed)


def vnoise(x, y, seed=0):
    xi, yi = math.floor(x), math.floor(y)
    fx, fy = x - xi, y - yi
    fx = fx * fx * (3 - 2 * fx)
    fy = fy * fy * (3 - 2 * fy)
    a = h2(xi, yi, seed)
    b = h2(xi + 1, yi, seed)
    c = h2(xi, yi + 1, seed)
    d = h2(xi + 1, yi + 1, seed)
    return a + (b - a) * fx + (c - a) * fy + (a - b - c + d) * fx * fy


def fbm(x, y, seed=0, octaves=3):
    total, amp, norm = 0.0, 1.0, 0.0
    for o in range(octaves):
        total += vnoise(x, y, seed + o * 31) * amp
        norm += amp
        x, y, amp = x * 2.03, y * 2.03, amp * 0.5
    return total / norm


def noise1(x, seed=0):
    return vnoise(x, 0.5, seed)


BAYER4 = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]


# --- the canvas ------------------------------------------------------------------------------------------------------

class Canvas:
    def __init__(self, colour=(0, 0, 0)):
        self.c = [[colour for _ in range(W)] for _ in range(H)]

    def inside(self, x, y):
        return 0 <= x < W and 0 <= y < H

    def get(self, x, y):
        return self.c[min(H - 1, max(0, int(y)))][min(W - 1, max(0, int(x)))]

    def put(self, x, y, colour, alpha=1.0):
        x, y = int(x), int(y)
        if not (0 <= x < W and 0 <= y < H):
            return
        if alpha >= 1:
            self.c[y][x] = colour
        elif alpha > 0:
            self.c[y][x] = mix(self.c[y][x], colour, alpha)

    def glow(self, x, y, colour, k):
        """Adds light (an emissive halo); k is the strength 0...1."""
        x, y = int(x), int(y)
        if 0 <= x < W and 0 <= y < H and k > 0:
            old = self.c[y][x]
            self.c[y][x] = (old[0] + colour[0] * k, old[1] + colour[1] * k, old[2] + colour[2] * k)

    def rect(self, x0, y0, x1, y1, colour, alpha=1.0):
        for y in range(max(0, int(y0)), min(H, int(y1) + 1)):
            for x in range(max(0, int(x0)), min(W, int(x1) + 1)):
                self.put(x, y, colour, alpha)

    def poly(self, pts, colour, alpha=1.0, fn=None):
        """Fills a polygon (even-odd, pixel centres). fn(x, y) may return the colour per pixel."""
        ys = [p[1] for p in pts]
        n = len(pts)
        for y in range(max(0, int(math.floor(min(ys)))), min(H, int(math.ceil(max(ys))) + 1)):
            cy = y + 0.5
            xs = []
            for i in range(n):
                x0, y0 = pts[i]
                x1, y1 = pts[(i + 1) % n]
                if (y0 <= cy < y1) or (y1 <= cy < y0):
                    xs.append(x0 + (cy - y0) * (x1 - x0) / (y1 - y0))
            xs.sort()
            for i in range(0, len(xs) - 1, 2):
                for x in range(max(0, int(math.ceil(xs[i] - 0.5))), min(W, int(math.floor(xs[i + 1] - 0.5)) + 1)):
                    self.put(x, y, fn(x, y) if fn else colour, alpha)

    def disc(self, cx, cy, r, colour, alpha=1.0):
        for y in range(int(cy - r - 1), int(cy + r + 2)):
            for x in range(int(cx - r - 1), int(cx + r + 2)):
                if (x + 0.5 - cx) ** 2 + (y + 0.5 - cy) ** 2 <= r * r:
                    self.put(x, y, colour, alpha)

    def column_fill(self, top, colour_fn, bottom=None):
        """Fills every column from top[x] down to bottom[x] (or the frame's foot) with colour_fn(x, y, depth)."""
        for x in range(W):
            t = top[x]
            if t is None:
                continue
            b = H - 1 if bottom is None else bottom[x]
            for y in range(max(0, int(math.ceil(t))), min(H, int(b) + 1)):
                c = colour_fn(x, y, y - t)
                if c is not None:
                    self.put(x, y, c)

    def halo(self, cx, cy, radius, colour, strength, steps=3, core=0.0):
        """A banded emissive glow around a light: `steps` flat rings, strongest inside (pixel art's own glow)."""
        r2 = radius * radius
        for y in range(int(cy - radius - 1), int(cy + radius + 2)):
            for x in range(int(cx - radius - 1), int(cx + radius + 2)):
                d2 = (x + 0.5 - cx) ** 2 + (y + 0.5 - cy) ** 2
                if d2 > r2:
                    continue
                d = math.sqrt(d2) / radius
                if d < core:
                    k = 1.0
                else:
                    k = (1 - d) ** 1.6
                if steps:
                    k = math.ceil(k * steps) / steps
                self.glow(x, y, colour, k * strength)

    def pool(self, cx, cy, radius, colour, strength, rim=None, squash=1.0, steps=4, mask=None):
        """A pool of firelight with a visible edge (ART-look2.md rule 1): lights what is painted (multiplies the albedo
        toward the fire's colour and adds a little), ember red toward the rim. squash < 1 flattens it on the ground."""
        rim = rim or P("ember")
        for y in range(int(cy - radius * squash - 1), int(cy + radius * squash + 2)):
            for x in range(int(cx - radius - 1), int(cx + radius + 2)):
                if not (0 <= x < W and 0 <= y < H):
                    continue
                if mask and not mask(x, y):
                    continue
                dx = (x + 0.5 - cx) / radius
                dy = (y + 0.5 - cy) / (radius * squash)
                d = math.sqrt(dx * dx + dy * dy)
                if d >= 1:
                    continue
                k = 1 - d
                k = math.ceil(k * steps) / steps if steps else k
                light = mix(rim, colour, smooth(0.15, 0.7, 1 - d))
                old = self.c[y][x]
                lit = (old[0] * (1 + light[0] / 255.0 * 2.2 * k * strength) + light[0] * 0.10 * k * strength,
                       old[1] * (1 + light[1] / 255.0 * 2.2 * k * strength) + light[1] * 0.10 * k * strength,
                       old[2] * (1 + light[2] / 255.0 * 2.2 * k * strength) + light[2] * 0.10 * k * strength)
                self.c[y][x] = lit

    def wash(self, cx, cy, rx, ry, colour, k, mask=None):
        """A soft warm (or cold) light over what is painted: multiplies toward the colour and adds a little, smooth
        falloff in an ellipse (the engine's smooth light)."""
        for y in range(int(cy - ry - 1), int(cy + ry + 2)):
            for x in range(int(cx - rx - 1), int(cx + rx + 2)):
                if not (0 <= x < W and 0 <= y < H):
                    continue
                if mask and not mask(x, y):
                    continue
                d = math.sqrt(((x + 0.5 - cx) / rx) ** 2 + ((y + 0.5 - cy) / ry) ** 2)
                if d >= 1:
                    continue
                f = (1 - d) ** 2 * k
                old = self.c[y][x]
                self.c[y][x] = (old[0] * (1 + colour[0] / 255.0 * 1.6 * f) + colour[0] * 0.08 * f,
                                old[1] * (1 + colour[1] / 255.0 * 1.6 * f) + colour[1] * 0.08 * f,
                                old[2] * (1 + colour[2] / 255.0 * 1.6 * f) + colour[2] * 0.08 * f)

    def save(self, path):
        rows = []
        for y in range(H):
            row = bytearray()
            for x in range(W):
                r, g, b = self.c[y][x]
                row += bytes((int(clamp(r, 0, 255) + 0.5), int(clamp(g, 0, 255) + 0.5), int(clamp(b, 0, 255) + 0.5),
                              255))
            rows.append(row)
        write_png(path, W, H, rows)

    def save_preview(self, path, zoom=3):
        rows = []
        for y in range(H):
            row = bytearray()
            for x in range(W):
                r, g, b = self.c[y][x]
                px = bytes((int(clamp(r, 0, 255) + 0.5), int(clamp(g, 0, 255) + 0.5), int(clamp(b, 0, 255) + 0.5),
                            255))
                row += px * zoom
            for _ in range(zoom):
                rows.append(row)
        write_png(path, W * zoom, H * zoom, rows)


def write_png(path, w, h, rows):
    raw = b"".join(b"\x00" + bytes(r) for r in rows)

    def chunk(tag, data):
        c = struct.pack(">I", len(data)) + tag + data
        return c + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)

    png = (b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0))
           + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b""))
    with open(path, "wb") as f:
        f.write(png)


# --- sky -------------------------------------------------------------------------------------------------------------

def sky(canvas, stops, y0=0, y1=H - 1, bands=16):
    """A vertical gradient in flat bands with an ordered dither between neighbours (the only dither: ART-look2.md).
    stops: [(y, colour), ...] top to bottom."""
    for y in range(y0, y1 + 1):
        # position between stops
        for i in range(len(stops) - 1):
            if stops[i][0] <= y <= stops[i + 1][0]:
                t = (y - stops[i][0]) / max(1, stops[i + 1][0] - stops[i][0])
                a, b = stops[i][1], stops[i + 1][1]
                break
        else:
            t, a, b = 0, stops[-1][1], stops[-1][1]
        level = t * bands
        lo = math.floor(level)
        frac = level - lo
        for x in range(W):
            k = lo + (1 if frac * 16 > BAYER4[y % 4][x % 4] + 0.5 else 0)
            canvas.put(x, y, mix(a, b, k / bands))


# --- shapes ----------------------------------------------------------------------------------------------------------

def sawtooth(peaks, slope_lo, slope_hi, seed, x0=0, x1=W):
    """A jagged ridge: the lower envelope of steep V shapes, one per peak. peaks: [(x, y_tip), ...]."""
    top = []
    rnd = [(px, py, slope_lo + (slope_hi - slope_lo) * h1(i, seed), slope_lo + (slope_hi - slope_lo) * h1(i, seed + 9))
           for i, (px, py) in enumerate(peaks)]
    for x in range(W):
        best = 1e9
        for px, py, sl, sr in rnd:
            s = sl if x < px else sr
            y = py + s * abs(x - px)
            if y < best:
                best = y
        best += (noise1(x * 0.7, seed + 3) - 0.5) * 1.6
        top.append(best)
    return top


def hills(base, amp, freq, seed, octaves=3):
    return [base - amp * fbm(x * freq, 0.37, seed, octaves) for x in range(W)]


def firs_on(top, seed, every=(3, 6), height=(3, 7), width=1.0, start=0, end=W):
    """Pointed fir tops along a ridge line: returns a new top line with the trees' tips (a forested ridge)."""
    out = list(top)
    x = start
    i = 0
    while x < end:
        step = every[0] + int(h1(i, seed) * (every[1] - every[0] + 1))
        hgt = height[0] + h1(i, seed + 5) * (height[1] - height[0])
        half = max(1.0, hgt * 0.42 * width)
        cx = x + h1(i, seed + 7) * 2
        for xx in range(int(cx - half - 1), int(cx + half + 2)):
            if 0 <= xx < W:
                d = abs(xx + 0.5 - cx) / half
                if d < 1:
                    y = top[min(W - 1, max(0, int(cx)))] - hgt * (1 - d) ** 1.15
                    if y < out[xx]:
                        out[xx] = y
        x += step
        i += 1
    return out


def fir(canvas, cx, base, height, colour, lit=None, seed=0, width=0.36):
    """One fir in silhouette: uneven tiers, a ragged outline; `lit` paints the tiers' upper left edges."""
    tiers = max(3, int(height / 7))
    for y in range(int(base - height), int(base) + 1):
        t = (y - (base - height)) / height
        tier = (t * tiers) % 1.0
        half = (0.6 + height * width * t) * (0.55 + 0.45 * tier)
        half += (h2(int(cx), y, seed) - 0.5) * 1.2
        trunk = 1.0 if t > 0.92 else 0
        x0 = cx - max(half, trunk)
        x1 = cx + max(half, trunk)
        for x in range(int(math.floor(x0)), int(math.ceil(x1))):
            c = colour
            if lit and x < cx - half * 0.35 and tier < 0.55 and t > 0.08:
                c = lit
            canvas.put(x, y, c)


# --- sprites ---------------------------------------------------------------------------------------------------------

_SPRITES = {}


def sprite(name, frame=0, frames=1):
    """The rows of a sprite (or one frame of a strip) from Resources/Art: [[(r, g, b, a), ...], ...]."""
    key = (name, frame, frames)
    if key in _SPRITES:
        return _SPRITES[key]
    w, h, px, _ = read_png(os.path.join(GAME, "Resources", "Art", name + ".png"))
    fw = w // frames
    rows = [row[frame * fw:(frame + 1) * fw] for row in px]
    _SPRITES[key] = rows
    return rows


def blit(canvas, rows, x0, y0, flip=False, shade=None, alpha_cut=128):
    """Places sprite rows with their top left at (x0, y0); shade(x, y, colour) returns the lit colour."""
    h = len(rows)
    w = len(rows[0]) if h else 0
    for y in range(h):
        for x in range(w):
            c = rows[y][w - 1 - x if flip else x]
            if c[3] < alpha_cut:
                continue
            X, Y = x0 + x, y0 + y
            if not canvas.inside(X, Y):
                continue
            col = (c[0], c[1], c[2])
            canvas.put(X, Y, shade(X, Y, col) if shade else col)


def lit(ambient, lights=(), floor=0.0, steps=4):
    """A shade function: albedo times a cold ambient plus warm point lights [(x, y, radius, colour, strength), ...];
    steps=0 lights smoothly (the engine's light), else in flat steps."""
    def f(x, y, c):
        r = c[0] * ambient[0] / 255.0
        g = c[1] * ambient[1] / 255.0
        b = c[2] * ambient[2] / 255.0
        for lx, ly, rad, col, k in lights:
            d = math.sqrt((x + 0.5 - lx) ** 2 + (y + 0.5 - ly) ** 2) / rad
            if d < 1:
                s = (math.ceil((1 - d) * steps) / steps if steps else (1 - d) ** 1.5) * k
                r += c[0] * col[0] / 255.0 * s
                g += c[1] * col[1] / 255.0 * s
                b += c[2] * col[2] / 255.0 * s
        return (r + floor, g + floor, b + floor)
    return f


def grid(canvas, text, x0, y0, legend, flip=False):
    """A hand-set pixel grid: one row per line, legend maps a character to a colour (space or '.' is empty)."""
    lines = [line for line in text.strip("\n").split("\n")]
    w = max(len(line) for line in lines)
    for y, line in enumerate(lines):
        for x, ch in enumerate(line):
            if ch in " .":
                continue
            X = x0 + (w - 1 - x if flip else x)
            col = legend[ch]
            if callable(col):
                col = col(X, y0 + y)
            canvas.put(X, y0 + y, col)
