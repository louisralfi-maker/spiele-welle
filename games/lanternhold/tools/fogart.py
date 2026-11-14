#!/usr/bin/env python3
"""Lanternhold world rebuild, step world-1 (docs/REVIEW-look-2.md B4, M1, 2.5): the fog. Pure python, palette colours
only, no randomness (hashes of the position), so a run reproduces its files byte for byte.

  fogart.py build <id> --out <Art dir>

  d2FogBank, d2MistBand, d2FogLow   the hour's three fog banks (fog A, the mist band, fog B), white alpha masks the
          engine colours: a density that is thickest at the foot and thins upward under a soft, rolling top, in eight
          alpha steps with ordered dither between them (no contour bands). Each is a tile of period P = width - 64 that
          the engine lays every P pixels: the tiles overlap by 64 px, and the two feathers inside the overlap use
          complementary dither, so where one tile's west feather lets a pixel through the other's east feather holds
          it back and the field goes on unbroken. The outer 8 px of each side are clear, the feathers 48 px wide; the
          foot feathers too. So no tile ends in a straight line, and the field itself never shows a seam.
  gloomFogBack, gloomFogMid, gloomFogFront  the Gloom's strips (stage 7's ids, sizes and frames, repainted for M1):
          2 frames each, a tile that repeats and the leading face; a rolling, swirled top periodic over the tile, the
          cover growing over a soft depth in eight dithered alpha steps, the colour darkening from a pale crest to the
          night heart in dithered steps (no flat bands, no contour lines); the face sinks to the lane and runs out clear.
  bankSheetA, bankSheetB, bankSheetC  the darkness bank (fog A, world, fog B; fix round 1): two frames each, a body
          tile periodic over w - 64 with complementary dithered feathers at both ends, and the leading face that
          leans back toward the top and tears into wisps. Painted in a light cool ramp, tinted by the hour in the
          engine (grey-violet and translucent by day, navy at night); each crest a lit shell, the body swirled in
          six value steps in clean clusters, the alpha in sixteen dithered steps. A tall and thin (its billowing
          crest near the screen's top), B darker (its crest at about half the screen), C the darkest roll at the foot.
  bankEnd     96x208: the world's west end, opaque night for 20 columns, thinning out by column 92 (drawn black).
  darknessBankGlow  four frames of 9x3: one pair of cold eyes, near and far, open and half shut (an emissive).
  cloudDeck   720x80, far plane: the deck across the Weltmauer, a ragged underside and a 48 px veil of mist under it.
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import pixelart as PA  # noqa: E402
import worldart as WA  # noqa: E402

h01 = WA.h01
BAYER8 = [
    0, 32, 8, 40, 2, 34, 10, 42, 48, 16, 56, 24, 50, 18, 58, 26, 12, 44, 4, 36, 14, 46, 6, 38, 60, 28, 52, 20, 62, 30,
    54, 22, 3, 35, 11, 43, 1, 33, 9, 41, 51, 19, 59, 27, 49, 17, 57, 25, 15, 47, 7, 39, 13, 45, 5, 37, 63, 31, 55, 23,
    61, 29, 53, 21]


def bay(x, y):
    return (BAYER8[((y & 7) << 3) | (x & 7)] + 0.5) / 64


def ss(t):
    t = min(1.0, max(0.0, t))
    return t * t * (3 - 2 * t)


def pnoise(seed, u, n):
    """Smooth value noise in [0, 1) with period n lattice cells."""
    i = math.floor(u)
    f = u - i
    f = f * f * (3 - 2 * f)
    a = h01(seed, int(i) % n)
    b = h01(seed, int(i + 1) % n)
    return a + (b - a) * f


# ---------------------------------------------------------------------------------------------- the hour's fog

OVERLAP = 64
FEATHER = 48
FEATHER_CLEAR = 8
LEVELS = 16   # sixteen alpha steps (fix round 1: eight showed a mesh at phone size)

FOG = {
    # w, h, the densest alpha, the top's range (rows above the foot), the soft share of the height, the foot's feather
    "d2FogBank": dict(w=384, h=40, peak=0.92, top=(24, 39), soft=0.62, foot=5, seed=111),
    "d2MistBand": dict(w=448, h=60, peak=0.80, top=(30, 59), soft=0.66, foot=6, seed=113),
    "d2FogLow": dict(w=320, h=24, peak=0.50, top=(11, 23), soft=0.70, foot=5, seed=115),
}


def period(name):
    return FOG[name]["w"] - OVERLAP


def fog_density(spec, x, ya):
    """The field at tile x (periodic with P) and ya rows above the foot: 0 ... peak."""
    P = spec["w"] - OVERLAP
    sd = spec["seed"]
    lo, hi = spec["top"]
    # the rolling top: two scales of billows, both periodic over P
    roll = 0.6 * pnoise(sd, x * 8.0 / P, 8) + 0.4 * pnoise(sd + 1, x * 20.0 / P, 20)
    top = lo + (hi - lo) * roll
    soft = spec["soft"] * spec["h"]
    d = ss((top - ya) / soft)
    # the body breathes: thinner places and thicker cores
    body = 0.8 + 0.2 * pnoise(sd + 2, x * 12.0 / P, 12) * (0.6 + 0.4 * pnoise(sd + 3, ya / 7.0 + x * 4.0 / P, 4))
    foot = ss((ya + 0.5) / spec["foot"])
    return spec["peak"] * d * body * foot


def fog_tile(name):
    spec = FOG[name]
    w, h = spec["w"], spec["h"]
    P = w - OVERLAP
    assert P % 8 == 0, "the period keeps the dither's phase"
    img = PA.Image(w, h)
    for y in range(h):
        ya = h - 1 - y
        for x in range(w):
            # The feathers: inside the overlap the east tile (local x) holds a pixel where bay < r, the west tile
            # (local x + P) where bay >= r; r runs 0 ... 1 over the 48 px between the clear 8 px at each end.
            u = x if x < OVERLAP else x - P if x >= P else None
            if u is not None:
                r = min(1.0, max(0.0, (u - FEATHER_CLEAR) / float(FEATHER)))
                held = bay(x, y) < r
                if (x < OVERLAP) != held:
                    continue
            a = fog_density(spec, x % P, ya)
            q = a * (LEVELS - 1) / spec["peak"] + (bay(x + 3, y + 5) - 0.5)
            k = max(0, min(LEVELS - 1, int(round(q))))
            if k:
                img.set(x, y, (255, 255, 255, int(round(255 * spec["peak"] * k / (LEVELS - 1)))))
    return img


# ---------------------------------------------------------------------------------------------- the darkness bank

# World rebuild, fix round 1 (the critic of world-1: "the day bank is still a black wall", "the night bank is a flat
# void"): each sheet is a pair of frames, a body tile that repeats westward and the leading face. The body is periodic
# over P = w - 64 and its two ends are complementary dithered feathers (as the hour's fog tiles), so the tiles hold
# every pixel exactly once and a translucent sheet stays one even veil (overlapping translucent tiles would stack into
# stripes of 100 px). The face frame starts like a body tile (its west 64 px are the body's east overlap) and ends in
# the bank's leading face. The sheets are painted in a light cool ramp (values only): the engine tints them by the hour
# (`FrameBuilder.bankTint`): grey-violet and translucent by day, navy at night; A the lightest and thinnest, B darker,
# C the darkest roll at the foot. Each crest has a lit shell (the moon's or the sky's light on the billows' tops);
# inside, the body swirls in six value steps in clean clusters (no ordered dither in the colour); only the alpha is
# dithered, in sixteen steps (the director: no mesh at phone size).
BANK_LEVELS = 16


def fbm(seed, u, v):
    return 0.62 * WA.vnoise2(seed, u, v) + 0.38 * WA.vnoise2(seed + 1, u * 2.3, v * 2.3)


SHEETS = {
    # w, h, the crest's range (rows from the sheet's top), the lit shell's depth, the soft depth (px from the shell to
    # the whole cover), how far the face leans back at the top (px), the thin places' share, the ramp (dark to light;
    # the engine tints it), seed
    "bankSheetA": dict(w=256, h=208, crest=(16, 48), shell=4, soft=34, lean=74, thin=0.22,
                       ramp=["mistDark", "moon", "mist", "farPale", "mistLight", "foam"], seed=221),
    "bankSheetB": dict(w=256, h=124, crest=(14, 38), shell=4, soft=26, lean=58, thin=0.12,
                       ramp=["nightSlate", "farDeep", "far", "mistDark", "moon", "mist"], seed=223),
    "bankSheetC": dict(w=256, h=56, crest=(8, 26), shell=3, soft=14, lean=44, thin=0.0,
                       ramp=["nightDeep", "nightBlue", "nightSlate", "farDeep", "far", "mistDark"], seed=225),
}


def bank_period(name):
    return SHEETS[name]["w"] - OVERLAP


def bank_crest(spec, u):
    """The crest's row at body phase u (periodic over P): billows of three sizes."""
    P = spec["w"] - OVERLAP
    sd = spec["seed"]
    lo, hi = spec["crest"]
    roll = 0.55 * pn(sd, u * 3.0 / P, 3) + 0.3 * pn(sd + 1, u * 8.0 / P, 8) + 0.15 * pn(sd + 2, u * 19.0 / P, 19)
    # round the billows: a hump's top is broad, its foot sharp (cumulus, never a saw)
    roll = 1 - (1 - roll) ** 1.6
    return lo + (hi - lo) * (1 - roll)


def bank_cover(spec, d):
    """The cover d rows under the crest: the lit shell rises quickly to a little under half, the body grows to whole."""
    if d <= 0:
        return 0.0
    return 0.42 * ss(d / spec["shell"]) + 0.58 * ss((d - spec["shell"] * 0.5) / spec["soft"])


def bank_value(spec, u, y, d, P):
    """0 (dark) ... 1 (light) at body phase u, row y, d rows under the crest: the lit shell on top, then the body in
    bands that follow the crest and darken downward, their edges rolling in long, flat swells (fog lies in layers;
    periodic over P)."""
    sd = spec["seed"]
    base = 1.0 - 0.9 * ss((d - 1.0) / (spec["soft"] * 2.0))
    roll = pn2(sd + 4, u * 4.0 / P + 0.25 * math.sin(y / 17.0), y / 15.0, 4)
    curl = pn2(sd + 6, u * 10.0 / P, y / 9.0, 10)
    return base + 0.2 * (roll - 0.5) * 2 * ss(d / 5.0) + 0.03 * (curl - 0.5) * 2


def bank_sheet(name):
    """Two frames side by side: 0 the body tile, 1 the leading face (see above)."""
    spec = SHEETS[name]
    w, h = spec["w"], spec["h"]
    P = w - OVERLAP
    assert P % 8 == 0, "the period keeps the dither's phase"
    sd = spec["seed"]
    ramp = [WA.col(c) for c in spec["ramp"]]
    n = len(ramp)
    img = PA.Image(2 * w, h)
    for frame in (0, 1):
        idx = [[-1] * w for _ in range(h)]
        alp = [[0.0] * w for _ in range(h)]
        for y in range(h):
            t = y / float(h - 1)
            for x in range(w):
                u = x % P
                face_dark = 0.0
                d = y - bank_crest(spec, u)
                # thin places in the body: A lets the forest show through here and there
                cover = bank_cover(spec, d) * (1 - spec["thin"] * pn2(sd + 8, u * 6.0 / P, y / 21.0, 6))
                dd = d
                if frame == 1:
                    # the leading face: it leans back toward the top (the low fog rolls out first), swirled into
                    # billows and torn wisps; the last columns run out clear whatever the swirl does
                    fx = w - 22 - spec["lean"] * (1 - t) ** 1.3
                    fx += 13 * (fbm(sd + 9, x / 26.0, y / 22.0) - 0.5) * 2 + 5 * (fbm(sd + 11, x / 8.0, y / 7.0) - 0.5) * 2
                    df = fx - x
                    cover = min(cover, bank_cover(spec, df * 1.3)) * ss((w - FEATHER_CLEAR - x) / 10.0)
                    dd = min(d, df)
                    face_dark = 0.16 * (1 - ss(df / 9.0))
                if cover <= 0.004:
                    continue
                v = bank_value(spec, u, y, d, P)
                if frame == 1:
                    v -= face_dark   # the leading face turns from the light (it faces east): a step darker
                # clean clusters: the steps' edges wander by a low noise of their own (no dither in the colour)
                wig = 0.32 * (pn2(sd + 12, u * 24.0 / P, y / 5.0, 24) - 0.5)
                k = int(round(v * (n - 1) + wig))
                # the shell on the light's side (up and west: where the crest falls toward the east) a step lighter
                if 0 < d < spec["shell"] + 1 and bank_crest(spec, (u + 2) % P) > bank_crest(spec, (u - 2) % P) + 0.4:
                    k += 1
                idx[y][x] = max(0, min(n - 1, k))
                alp[y][x] = cover
        # no lone pixels in the colour (a pixel artist's clean clusters)
        for _ in range(2):
            ch = []
            for y in range(h):
                for x in range(w):
                    c = idx[y][x]
                    if c < 0:
                        continue
                    around = [idx[yy][xx] for (xx, yy) in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1))
                              if 0 <= xx < w and 0 <= yy < h and idx[yy][xx] >= 0]
                    if len(around) >= 3 and c not in around:
                        best = max(set(around), key=around.count)
                        if around.count(best) >= 2:
                            ch.append((x, y, best))
            for (x, y, c) in ch:
                idx[y][x] = c
        for y in range(h):
            for x in range(w):
                if idx[y][x] < 0:
                    continue
                # the feathers: complementary dither inside the 64 px overlaps (body: both ends; face: the west end)
                if x < OVERLAP:
                    r = min(1.0, max(0.0, (x - FEATHER_CLEAR) / float(FEATHER)))
                    if not bay(x, y) < r:
                        continue
                elif frame == 0 and x >= P:
                    r = min(1.0, max(0.0, (x - P - FEATHER_CLEAR) / float(FEATHER)))
                    if not bay(x, y) >= r:
                        continue
                q = alp[y][x] * (BANK_LEVELS - 1) + (bay(x + 3, y + 5) - 0.5)
                k = max(0, min(BANK_LEVELS - 1, int(round(q))))
                if not k:
                    continue
                c = ramp[idx[y][x]]
                img.set(frame * w + x, y, (c[0], c[1], c[2], int(round(255 * k / (BANK_LEVELS - 1)))))
    return img


def bank_end():
    """bankEnd: where the world ends (x 0), the dark is whole: night0, opaque over the first 20 columns, then thinning
    to nothing at column 92 in sixteen dithered alpha steps; the engine draws it black on fog B."""
    w, h = 96, 208
    img = PA.Image(w, h)
    c = WA.col("night0")
    for y in range(h):
        for x in range(w):
            a = 1 - ss((x - 20) / 72.0)
            q = a * (BANK_LEVELS - 1) + (bay(x + 1, y + 2) - 0.5)
            k = max(0, min(BANK_LEVELS - 1, int(round(q))))
            if k:
                img.set(x, y, (c[0], c[1], c[2], int(round(255 * k / (BANK_LEVELS - 1)))))
    return img


def bank_eyes():
    """darknessBankGlow, since fix round 1: one pair of cold eyes in four frames of 9x3 (an emissive; the engine
    places the pairs by hand, `FrameBuilder.bankEyes`): 0 a near pair open (two lit diamonds 6 px apart), 1 the near
    pair half shut, 2 a far pair open (two points 4 px apart), 3 the far pair half shut."""
    W, H = 9, 3
    img = PA.Image(4 * W, H)
    white, glow, dim = WA.col("wraithWhite"), WA.col("wraithGlow"), WA.col("wraithDim")
    frames = [
        [".g.....g.", "gWg...gWg", ".g.....g."],
        [".........", "dgd...dgd", "........."],
        [".........", "..W...W..", "..d...d.."],
        [".........", "..g...g..", "........."],
    ]
    for f, rows in enumerate(frames):
        for y, row in enumerate(rows):
            for x, ch in enumerate(row):
                c = {"W": white, "g": glow, "d": dim}.get(ch)
                if c:
                    img.set(f * W + x, y, c)
    return img


# ---------------------------------------------------------------------------------------------- the cloud deck

DECK_W, DECK_H = 720, 80
DECK_BASE = 30   # the row the billows stand on; the underside hangs below it, the veil below that


def cloud_deck():
    """cloudDeck (far plane, world rebuild fix round 1: "the cloud deck's underside is a ruler-straight line"): one
    deck of cloud across the Weltmauer over the shadow land and the Throat, far x -100 to 620. Its top is a row of
    round billows in two ranks (big ones behind, smaller ones in front and lower), each lit from the upper left in the
    clouds' own colours (parchment where the sun catches it, mistLight, farPale, mist and moon in the shade); its
    underside hangs in lobes and rags that change all along it (16 to 20 px of swing), and under them a veil of mist
    feathers 48 px down into the wall's haze in sixteen dithered alpha steps, so the haze below begins gradually and
    never at a line. Toward both ends the billows grow smaller and part into separate puffs."""
    w, h = DECK_W, DECK_H
    img = PA.Image(w, h)
    sd = 611
    pal = {k: WA.col(k) for k in ("mistLight", "farPale", "mist", "moon", "mistDark")}
    L = (-0.62, -0.78)

    def env(x):  # the deck's strength along it: whole in the middle, puffs toward both ends
        return ss((x - 10) / 110.0) * ss((w - 10 - x) / 160.0)

    discs = []   # (cx, cy, r, rank)
    for rank, (gap, rmin, rmax, lift) in enumerate(((15, 7, 17, 0), (14, 4, 9, 6))):
        x, k = 4.0 + 7 * rank, 0
        while x < w - 4:
            e = env(x)
            # sizes vary along the deck in swells (a few big heads among many small ones), never in a regular row
            swell = 0.55 + 0.45 * pn(sd + 30 + rank, x / 47.0, 999)
            r = (rmin + (rmax - rmin) * h01(sd + rank, k) ** 1.4) * (0.45 + 0.55 * e) * (0.6 + 0.6 * swell)
            if e > 0.08 or h01(sd + 5 + rank, k) < 0.55:
                cy = DECK_BASE + lift - r * (0.35 + 0.45 * h01(sd + 9 + rank, k)) + 4 * (1 - e) \
                    - 6 * (swell - 0.5)
                discs.append((x, cy, r, rank))
            x += gap * (0.6 + 0.6 * h01(sd + 3 + rank, k)) * (0.7 + 0.3 * e) + r * 0.4
            k += 1

    def under(x):  # the underside's row: lobes and rags, never level
        lob = 0.55 * pn(sd + 13, x / 37.0, 999) + 0.3 * pn(sd + 14, x / 13.0, 999) + 0.15 * pn(sd + 15, x / 5.0, 999)
        return DECK_BASE - 4 + 34 * (lob - 0.2) * (0.4 + 0.6 * env(x))

    # the billows as a height field: each disc a dome, the deck the highest dome at each pixel (front discs stand
    # 6 px nearer); the normal of that field takes the light, so the shading runs across the billows and creases
    # where two meet (no bubble rings)
    # the billows' silhouette (the union of the discs), and the front rank's own tops inside it: a cloud is shaded
    # from its top contour down (a lit rim that is broad where the contour faces the light, thin where it turns
    # away, then the body, then the shaded belly), and the front lobes draw their own lit arcs inside the mass;
    # shading each disc as a sphere read as soap bubbles
    inside = [[False] * w for _ in range(h)]
    front = [[None] * w for _ in range(h)]       # rows under a front lobe's own top
    for (cx, cy, r, rank) in discs:
        for y in range(max(0, int(cy - r - 1)), min(h, int(cy + r + 2))):
            for x in range(max(0, int(cx - r - 1)), min(w, int(cx + r + 2))):
                dx, dy = x + 0.5 - cx, y + 0.5 - cy
                if dx * dx + dy * dy <= r * r:
                    inside[y][x] = True
                    if rank == 1:
                        top_here = cy - math.sqrt(max(0.0, r * r - dx * dx))
                        dd = y + 0.5 - top_here
                        if front[y][x] is None or dd < front[y][x]:
                            front[y][x] = dd
    tops = []
    for x in range(w):
        t = next((y for y in range(h) if inside[y][x]), None)
        if t is None and env(x) > 0.05:
            t = DECK_BASE - 2
        tops.append(t)

    for y in range(h):
        for x in range(w):
            e = env(x)
            u = under(x)
            col, a = None, 0.0
            body = inside[y][x] or (y >= DECK_BASE - 2 and y <= u and e > 0.05)
            if body and tops[x] is not None:
                d = y - tops[x]
                tl = tops[max(0, x - 2)] if tops[max(0, x - 2)] is not None else tops[x]
                tr = tops[min(w - 1, x + 2)] if tops[min(w - 1, x + 2)] is not None else tops[x]
                slope = tr - tl                          # > 0: the contour falls to the east (it faces the light)
                rim = 2 + max(0, min(3, slope))
                wob = 1.2 * (WA.vnoise2(sd + 17, x / 7.0, y / 3.0) - 0.5)
                if d + wob < rim:
                    col = "mistLight" if slope >= 0 else "farPale"
                elif d + wob < rim + 6:
                    col = "farPale"
                else:
                    col = "mist"
                fd = front[y][x]
                if fd is not None and fd < 2.2 and d > 2:
                    col = "mistLight" if fd < 1.2 else "farPale"   # a front lobe's lit arc
                if u - y < 2.5 and y > DECK_BASE - 2:
                    col = "mistDark" if WA.vnoise2(sd + 21, x / 5.0, y / 3.0) > 0.4 else "moon"
                elif u - y < 5 and y > DECK_BASE - 2 and col == "mist":
                    col = "moon"
                a = 1.0 if e > 0.3 or inside[y][x] else ss(e / 0.3)
            elif y > u and e > 0.02:
                # the veil of mist under the deck: 48 px down, thinning in dithered steps; rags hang in it
                # (fix: its rags lie in long flat wisps; streaks that ran down read as a curtain)
                g = y - u
                rag = pn2(sd + 23, x / 23.0, y / 3.5, 9999)
                a = (1 - ss(g / 48.0)) ** 1.4 * (0.35 + 0.65 * rag) * 0.5 * e
                col = "farPale" if g < 4 and rag > 0.6 else "mist" if g < 18 else "mistDark"
            if col is None:
                continue
            qa = a * (BANK_LEVELS - 1) + (bay(x + 2, y + 1) - 0.5)
            k = max(0, min(BANK_LEVELS - 1, int(round(qa))))
            if not k:
                continue
            c = pal[col]
            img.set(x, y, (c[0], c[1], c[2], int(round(255 * k / (BANK_LEVELS - 1)))))
    return img


# ---------------------------------------------------------------------------------------------- the Gloom's strips

def pn(seed, u, n):
    """Smooth value noise in [0, 1) whose lattice wraps every n cells."""
    i = math.floor(u)
    f = u - i
    f = f * f * (3 - 2 * f)
    return h01(seed, int(i) % n) * (1 - f) + h01(seed, int(i + 1) % n) * f


def pn2(seed, u, v, n):
    """Smooth 2D value noise whose lattice wraps every n cells along u."""
    i, j = math.floor(u), math.floor(v)
    f, g = u - i, v - j
    f, g = f * f * (3 - 2 * f), g * g * (3 - 2 * g)
    i0, i1 = int(i) % n, int(i + 1) % n
    a = h01(seed, i0, int(j)) * (1 - f) + h01(seed, i1, int(j)) * f
    b = h01(seed, i0, int(j) + 1) * (1 - f) + h01(seed, i1, int(j) + 1) * f
    return a * (1 - g) + b * g


GLOOM = {
    # frame width and height, the top's base and swing (rows above the bottom), the soft depth, the swirl, the
    # densest cover, the colours from the crest to the heart, where the leading frame starts to sink and where it
    # reaches the lane (px into the leading frame), seed
    "gloomFogBack": dict(w=192, h=120, base=92, swing=22, soft=46, swirl=10, peak=1.0,
                         ramp=["mist", "mistDark", "far", "farDeep", "night2", "night1", "night0"],
                         hold=36, end=184, seed=311),
    "gloomFogMid": dict(w=160, h=64, base=44, swing=14, soft=34, swirl=7, peak=0.55,
                        ramp=["mist", "mistDark", "far", "farDeep"], hold=30, end=152, seed=313),
    "gloomFogFront": dict(w=128, h=30, base=21, swing=7, soft=16, swirl=4, peak=0.78,
                          ramp=["mistDark", "far", "farDeep", "night2"], hold=24, end=120, seed=315),
}


def gloom_strip(name):
    """The Gloom's fog strips (stage 7's ids and sizes; world rebuild M1, B4): 2 frames side by side, frame 0 a tile
    that repeats seamlessly, frame 1 the leading face whose left column goes on from frame 0 and whose top sinks to the
    lane toward its right end, which runs out clear. The fog's top rolls in billows of two sizes and is swirled, both
    periodic over the tile; under it the cover grows over a soft depth in eight alpha steps and the colour darkens
    from a pale crest to the night heart in six or seven steps, both with ordered dither (no flat bands, no contour
    lines); the crest's slopes that face the moon (up and west) catch a little light."""
    spec = GLOOM[name]
    w, h = spec["w"], spec["h"]
    assert w % 8 == 0, "the tile keeps the dither's phase"
    sd = spec["seed"]
    ramp = [WA.col(n) for n in spec["ramp"]]
    n = len(ramp)
    img = PA.Image(2 * w, h)

    def top(X, ya):
        u = X % w
        t = spec["base"] + spec["swing"] * (0.62 * pn(sd, u * 5.0 / w, 5) + 0.38 * pn(sd + 1, u * 13.0 / w, 13) - 0.5)
        t += spec["swirl"] * (pn2(sd + 2, u * 8.0 / w, ya / 24.0, 8) - 0.5) * 1.2
        if X >= w:
            k = X - w
            env = 1.0 if k < spec["hold"] else 1 - ss((k - spec["hold"]) / float(spec["end"] - spec["hold"]))
            t *= env
        return t

    for y in range(h):
        ya = h - 1 - y
        for X in range(2 * w):
            if X >= w and X - w >= spec["end"]:
                continue
            t = top(X, ya)
            d = t - ya                                    # rows under the fog's top
            if d <= 0:
                continue
            a = spec["peak"] * ss(d / spec["soft"])
            if X >= w:
                a *= ss((spec["end"] - (X - w)) / 10.0)   # the face's last columns thin to nothing
            k = max(0, min(LEVELS - 1, int(round(a * (LEVELS - 1) + bay(X + 1, y + 3) - 0.5))))
            if not k:
                continue
            # the colour by depth under the top: a pale crest, the heart toward the lane
            f = min(1.0, d / float(max(spec["soft"] * 1.6, 1)))
            # clean clusters (fix round 1: the ordered dither between the colours read as a mesh at phone size)
            ci = int(round(f * (n - 1) + 0.6 * (pn2(sd + 7, (X % w) * 16.0 / w, y / 5.0, 16) - 0.5)))
            # the crest on the moon's side: where the top falls toward the east (its slope faces up and west)
            slope = top(X + 2, ya) - top(X - 2, ya)
            if d < 4 and slope < -0.6:
                ci -= 1
            c = ramp[max(0, min(n - 1, ci))]
            img.set(X, y, (c[0], c[1], c[2], int(round(255 * k / (LEVELS - 1)))))
    return img


def build(name, out):
    if name in FOG:
        img = fog_tile(name)
    elif name in SHEETS:
        img = bank_sheet(name)
    elif name in GLOOM:
        img = gloom_strip(name)
    elif name == "bankEnd":
        img = bank_end()
    elif name == "darknessBankGlow":
        img = bank_eyes()
    elif name == "cloudDeck":
        img = cloud_deck()
    else:
        raise SystemExit("unknown fog " + name)
    path = os.path.join(out, name + ".png")
    PA.write_png(path, img)
    print("wrote", path, img.w, "x", img.h)


def main():
    a = sys.argv[1:]
    if len(a) >= 4 and a[0] == "build" and a[2] == "--out":
        build(a[1], a[3])
        return
    raise SystemExit(__doc__)


if __name__ == "__main__":
    main()
