# Python twins of the Swift pieces the preview needs: SplitMix64 hash, Painter noise, AmbientRamp, art loaders.
import math, os, re, sys
M = (1 << 64) - 1
def mix(z):
    z &= M
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M
    return z ^ (z >> 31)
def h64(seed, index):
    lattice = ((index & M) * 0x9E3779B97F4A7C15) & M
    return mix(seed ^ mix((lattice + 0x632BE59BD9B4E019) & M))
def fnv(text):
    v = 0xCBF29CE484222325
    for ch in text:
        v ^= ord(ch); v = (v * 0x100000001B3) & M
    return v
class P:
    def __init__(s, w, h, salt): s.w, s.h, s.salt = w, h, salt; s.px = [[None] * w for _ in range(h)]
    def put(s, x, y, c):
        if 0 <= x < s.w and 0 <= y < s.h: s.px[y][x] = c
    def hash(s, x, y, key=0):
        idx = ((x * 73856093) & M) ^ ((y * 19349663) & M)
        bits = h64((s.salt + key * 0x9E3779B9) & M, idx) >> 11
        return bits * 2.0 ** -53
    def lattice(s, i, j, key): return s.hash((i * 31 + 7), (j * 17 + 3), (key + 0x51))
    def smooth(s, x, y, cell, key=0, period=None):
        fx, fy = x / cell, y / cell; ix, iy = math.floor(fx), math.floor(fy); tx, ty = fx - ix, fy - iy
        x0, x1 = ix, ix + 1
        if period:
            n = max(1, round(period / cell)); x0 %= n; x1 %= n
        a, b, c, d = s.lattice(x0, iy, key), s.lattice(x1, iy, key), s.lattice(x0, iy + 1, key), s.lattice(x1, iy + 1, key)
        sx, sy = tx * tx * (3 - 2 * tx), ty * ty * (3 - 2 * ty)
        top = a + (b - a) * sx; bot = c + (d - c) * sx
        return top + (bot - top) * sy
    def fractal(s, x, y, cell, key=0, period=None):
        return s.smooth(x, y, cell, key, period) * 0.68 + s.smooth(x, y, cell / 2, key + 1, period) * 0.32
BAYER = [(v + 0.5) / 16 for v in [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]]
def bayer(x, y): return BAYER[((y & 3) << 2) | (x & 3)]
def ramp(colors, v, x, y):
    sc = min(1, max(0, v)) * (len(colors) - 1); base = math.floor(sc); fr = sc - base
    i = base + 1 if fr > bayer(x, y) else base
    return colors[min(len(colors) - 1, max(0, i))]
def hexc(v): return ((v >> 16) & 255, (v >> 8) & 255, v & 255, 255)
def lerp3(a, b, t): return tuple(a[i] + (b[i] - a[i]) * t for i in range(3))
def hexf(v): return ((v >> 16 & 255) / 255, (v >> 8 & 255) / 255, (v & 255) / 255)
# AmbientRamp keyframes: hour, skyTop, skyBottom, ambColor, ambI, fogColor, fogD, haze, stars, sun, moon, torch, warmth, sat
night0, night2, dawnRose, daySky, dusk = hexf(0x0E0B1E), hexf(0x2E2A5C), hexf(0xF2A6A0), hexf(0x9CCBDD), hexf(0xC8587A)
KEYS = [
 (4.8, (0.09,0.08,0.20), (0.24,0.20,0.38), (0.42,0.46,0.78), 0.17, (0.20,0.20,0.36), 0.35, 0.30, 0.6, -0.25, 0.25, 1.0, -0.25, 0.7),
 (6.0, (0.36,0.38,0.62), dawnRose, (0.95,0.72,0.66), 0.45, (0.80,0.62,0.62), 0.45, 0.55, 0.1, 0.02, 0.05, 0.6, 0.25, 0.9),
 (7.2, (0.45,0.62,0.80), (0.90,0.82,0.70), (1.0,0.90,0.80), 0.72, (0.85,0.82,0.80), 0.25, 0.35, 0, 0.3, -0.2, 0.15, 0.12, 1.0),
 (12.0, (0.42,0.66,0.82), daySky, (1.0,0.98,0.94), 1.0, (0.80,0.86,0.88), 0.08, 0.2, 0, 1.0, -0.6, 0, 0, 1.0),
 (16.8, (0.40,0.60,0.80), (0.86,0.84,0.72), (1.0,0.92,0.80), 0.88, (0.86,0.82,0.72), 0.12, 0.3, 0, 0.45, -0.4, 0, 0.15, 1.0),
 (18.0, (0.42,0.44,0.66), (1.0,0.72,0.40), (1.0,0.76,0.48), 0.72, (0.95,0.70,0.48), 0.3, 0.6, 0, 0.12, -0.1, 0.2, 0.45, 1.1),
 (19.2, (0.20,0.16,0.38), dusk, (0.66,0.46,0.66), 0.36, (0.50,0.32,0.48), 0.45, 0.55, 0.25, -0.08, 0.1, 0.85, 0.15, 0.85),
 (20.4, night0, night2, (0.36,0.42,0.80), 0.14, (0.16,0.16,0.32), 0.4, 0.25, 1.0, -0.6, 0.6, 1.0, -0.3, 0.65),
]
FIELDS = ['hour','skyTop','skyBottom','ambColor','ambI','fogColor','fogD','haze','stars','sun','moon','torch','warmth','sat']
def ss(t): t = min(1, max(0, t)); return t * t * (3 - 2 * t)
def ambient(hour):
    h = hour % 24
    for a, b in zip(KEYS, KEYS[1:]):
        if a[0] <= h < b[0]:
            t = ss((h - a[0]) / (b[0] - a[0])); break
    else:
        a, b = KEYS[-1], KEYS[0]
        hh = h + 24 if h < b[0] else h
        t = ss((hh - a[0]) / (b[0] + 24 - a[0]))
    out = {}
    for i, f in enumerate(FIELDS):
        if i == 0: continue
        va, vb = a[i], b[i]
        out[f] = lerp3(va, vb, t) if isinstance(va, tuple) else va + (vb - va) * t
    return out
