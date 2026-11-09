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
 (19.2, (0.20,0.16,0.38), (0.90,0.54,0.38), (0.94,0.68,0.42), 0.5, (0.48,0.36,0.40), 0.35, 0.32, 0.25, -0.08, 0.1, 0.85, 0.32, 1.0),
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
# Look 2 (ART-look2.md "Light per hour"): eleven keyframes with a long dusk and a deep blue night. Each also sets the
# air (the colour distance fades to), the vignette, the navy lift of the darks and the light on the clouds' sunlit
# tops (cloud: the low sun's colour times its strength, exempt from the cold grade; 0 at night, when the moon lights
# them). Opt-in: mock.py look=2. After the critic of stage 1 (ART-look2.md "Critic and fixes"): the night a value step
# lighter toward look2-4-farbe (sky, air and fog), fewer stars under a moonlit cloud deck, an orange afterglow at
# dusk instead of mauve, a golden hour that keeps the greens green, a little more colour at noon.
def _k2(name, hour, skyTop, skyBottom, amb, ambI, fog, fogD, haze, stars, sun, moon, torch, warmth, sat, air, vig, black,
        cloud):
    return dict(name=name, hour=hour, skyTop=skyTop, skyBottom=skyBottom, ambColor=amb, ambI=ambI, fogColor=fog,
                fogD=fogD, haze=haze, stars=stars, sun=sun, moon=moon, torch=torch, warmth=warmth, sat=sat, air=air,
                vig=vig, black=black, cloud=cloud)
KEYS2 = [
 _k2('pre-dawn',   4.6, (0.10,0.11,0.26), (0.27,0.30,0.52), (0.40,0.46,0.82), 0.15, (0.36,0.40,0.70), 0.50, 0.45, 0.3, -0.30, 0.30, 1.0, -0.25, 0.80, (0.24,0.29,0.54), 0.34, 1.0, (0.08,0.08,0.14)),
 _k2('dawn',       5.9, (0.26,0.30,0.52), (0.88,0.62,0.56), (0.90,0.72,0.70), 0.40, (0.66,0.60,0.66), 0.55, 0.60, 0.1,  0.02, 0.05, 0.7,  0.18, 0.88, (0.66,0.60,0.68), 0.26, 0.5, (0.94,0.68,0.58)),
 _k2('morning',    7.4, (0.38,0.52,0.70), (0.82,0.78,0.72), (1.00,0.92,0.84), 0.74, (0.80,0.80,0.80), 0.28, 0.45, 0.0,  0.30, -0.2, 0.1,  0.08, 0.92, (0.76,0.78,0.80), 0.18, 0.2, (0.85,0.80,0.74)),
 _k2('noon',      12.0, (0.34,0.50,0.66), (0.66,0.74,0.78), (0.96,0.96,0.94), 0.92, (0.74,0.78,0.82), 0.10, 0.32, 0.0,  1.00, -0.6, 0.0,  0.00, 0.96, (0.68,0.75,0.80), 0.16, 0.2, (0.92,0.92,0.90)),
 _k2('afternoon', 16.2, (0.34,0.48,0.66), (0.78,0.74,0.66), (1.00,0.90,0.78), 0.84, (0.80,0.76,0.70), 0.14, 0.38, 0.0,  0.50, -0.4, 0.0,  0.14, 0.96, (0.74,0.72,0.70), 0.18, 0.2, (0.90,0.81,0.70)),
 _k2('golden',    17.8, (0.30,0.34,0.56), (0.96,0.64,0.38), (1.00,0.82,0.64), 0.66, (0.90,0.64,0.46), 0.28, 0.55, 0.0,  0.14, -0.1, 0.2,  0.32, 1.00, (0.82,0.62,0.52), 0.22, 0.3, (1.15,0.84,0.55)),
 _k2('sunset',    18.8, (0.16,0.17,0.40), (0.92,0.46,0.30), (0.92,0.66,0.46), 0.44, (0.52,0.40,0.48), 0.32, 0.45, 0.05,-0.02, 0.00, 0.6,  0.32, 1.02, (0.50,0.40,0.50), 0.28, 0.5, (1.40,0.77,0.41)),
 _k2('dusk',      19.5, (0.11,0.13,0.33), (0.69,0.39,0.31), (0.44,0.56,0.82), 0.30, (0.38,0.41,0.70), 0.38, 0.42, 0.2, -0.15, 0.15, 1.0,  0.08, 0.95, (0.34,0.37,0.62), 0.30, 0.8, (0.85,0.44,0.35)),
 _k2('blue hour', 20.3, (0.11,0.14,0.33), (0.31,0.36,0.66), (0.40,0.50,0.90), 0.18, (0.36,0.41,0.78), 0.42, 0.40, 0.25,-0.40, 0.40, 1.0, -0.22, 0.86, (0.27,0.33,0.63), 0.34, 1.0, (0.06,0.06,0.10)),
 _k2('night',     21.4, (0.11,0.13,0.32), (0.29,0.33,0.62), (0.36,0.45,0.88), 0.14, (0.36,0.40,0.80), 0.45, 0.40, 0.3, -0.60, 0.60, 1.0, -0.30, 0.82, (0.25,0.31,0.60), 0.34, 1.0, (0.00,0.00,0.00)),
]
def ambient2(hour, keys=None):
    keys = keys or KEYS2
    h = hour % 24
    for a, b in zip(keys, keys[1:]):
        if a['hour'] <= h < b['hour']:
            t = ss((h - a['hour']) / (b['hour'] - a['hour'])); break
    else:
        a, b = keys[-1], keys[0]
        hh = h + 24 if h < b['hour'] else h
        t = ss((hh - a['hour']) / (b['hour'] + 24 - a['hour']))
    out = {}
    for f, va in a.items():
        if f in ('name', 'hour'): continue
        vb = b[f]
        out[f] = lerp3(va, vb, t) if isinstance(va, tuple) else va + (vb - va) * t
    return out
