#!/usr/bin/env python3
"""Lanternhold art pass (look 2, stage 7; ART-look2.md section 19.2): the Gloom's fog. At dusk the Gloom comes up the
Throat as a creeping bank of fog with cold eyes in it, and the creatures step out of it. Pure python, palette colours
only, no randomness (hashes of the position), so a run reproduces its files byte for byte.

  gloomart.py build <id> --out <Art dir>      ids: gloomFogBack gloomFogMid gloomFogFront gloomWisp gloomFogEyes

  gloomFogBack    the bank itself, behind the creatures: six rows of low rolls, pale grey-violet crests with a rim
                  of moonlight on their upper left, a heart that darkens to night toward the lane. 2 frames of
                  192x120: frame 0 repeats seamlessly, frame 1 is the bank's leading face (its left column goes on
                  from frame 0; the rows end one after the other, the dark heart first, each in round noses that
                  step down to the lane).
  gloomFogMid     a thinner veil before the creatures: 2 frames of 160x64, built the same way.
  gloomFogFront   the fog creeping along the lane before everything: 2 frames of 128x30, the lowest 8 rows under the
                  ground line; its leading frame runs out in long low tongues.
  gloomWisp       a shred that tears off the front and thins away: 6 frames of 40x16, the shred's life.
  gloomFogEyes    the cold eyes in the bank's heart, an emissive: 4 frames of 64x72 (the tile the bank's glow lies
                  on), nine pairs, the near ones two px wide with a white spark; each pair is shut in one frame.

The paint is the fog's colour at night and it is flat: every pixel is one palette colour at one of a few alpha
levels, no dither, so the engine can move the strips against each other and cut the light pools out of their alpha.
Light from the upper left, as everywhere.
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import pixelart as PA  # noqa: E402
import worldart as WA  # noqa: E402

h01 = WA.h01


def tone(name, alpha):
    r, g, b = WA.col(name)[:3]
    return (r, g, b, alpha)


# One row of billows: top = the range of its puffs' crowns (px above the sprite's bottom), r = their radii, body and
# rim = (colour, alpha), glint = the brightest crowns, hold and end = where the leading frame starts to sink and where
# it reaches the lane (px from the leading frame's left edge), cyc = whole waves per tile.
STRIPS = {
    "gloomFogBack": dict(w=192, h=120, key=71, flat=0.62, levels=[
        dict(top=(100, 117), r=(10, 16), body=("far", 107), rim=("mistDark", 178), hold=56, end=190, cyc=2),
        dict(top=(84, 103), r=(12, 19), body=("far", 204), rim=("mistDark", 235), glint=("mist", 235),
             hold=52, end=180, cyc=3),
        dict(top=(66, 86), r=(13, 20), body=("farDeep", 235), rim=("far", 245), hold=48, end=164, cyc=2),
        dict(top=(48, 68), r=(13, 20), body=("night2", 245), rim=("farDeep", 255), hold=44, end=146, cyc=3),
        dict(top=(27, 48), r=(12, 18), body=("night1", 255), rim=("night2", 255), hold=40, end=128, cyc=2),
        dict(top=(8, 27), r=(10, 15), body=("night0", 255), rim=("night1", 255), hold=36, end=110, cyc=3),
    ]),
    "gloomFogMid": dict(w=160, h=64, key=83, flat=0.55, levels=[
        dict(top=(44, 60), r=(10, 16), body=("far", 64), rim=("mistDark", 102), hold=34, end=156, cyc=2),
        dict(top=(26, 42), r=(10, 16), body=("far", 92), rim=("mistDark", 128), hold=32, end=124, cyc=3),
        dict(top=(9, 24), r=(9, 14), body=("farDeep", 128), rim=("far", 158), hold=30, end=92, cyc=2),
    ]),
    "gloomFogFront": dict(w=128, h=30, key=97, flat=0.5, levels=[
        dict(top=(20, 29), r=(7, 12), body=("far", 102), rim=("mistDark", 148), hold=28, end=126, cyc=2),
        dict(top=(11, 19), r=(6, 10), body=("farDeep", 184), rim=("far", 204), hold=26, end=102, cyc=3),
        dict(top=(3, 9), r=(5, 8), body=("night2", 214), rim=("farDeep", 230), hold=24, end=72, cyc=2),
    ]),
}


def puffs(spec, w, key):
    """One row's puffs over one tile: [cx, top, r], spaced so that neighbours overlap."""
    lo, hi = spec["top"]
    rlo, rhi = spec["r"]
    steps, rs, total, i = [], [], 0.0, 0
    while total < w:
        r = rlo + (rhi - rlo) * h01(key, i, 1)
        s = r * (0.85 + 0.5 * h01(key, i, 2))
        steps.append(s)
        rs.append(r)
        total += s
        i += 1
    k = w / total
    out, x = [], 0.0
    ph = h01(key, 7) * 6.283
    for i, (s, r) in enumerate(zip(steps, rs)):
        wave = 0.5 + 0.35 * math.sin(6.283 * spec["cyc"] * x / w + ph) + 0.15 * math.sin(6.283 * (spec["cyc"] + 2) * x / w)
        out.append([x, lo + (hi - lo) * (0.7 * wave + 0.3 * h01(key, i, 3)), r])
        x += s * k
    return out


def sink(spec, w, X):
    """How much of its height a row keeps at X: 1 in the tile and up to its hold, then down the face to the lane, a
    slope with a low toe creeping ahead."""
    t = (X - w - spec["hold"]) / float(spec["end"] - spec["hold"])
    return 1.0 if t <= 0 else 0.0 if t >= 1 else (1 - t) ** 1.2


SKIRT = 6


def roll(d, rr, flat):
    """How far a roll's surface lies under its crown at d from its centre: a cap (flat: a low one), then a short
    steep foot, so a roll that stands above its neighbour ends in a round nose and not in a sheer side."""
    u = abs(d) / rr
    if u <= 0.95:
        return flat * rr * (1 - math.sqrt(1 - u * u))
    return 0.69 * flat * rr + (abs(d) - 0.95 * rr) * 2.5


def profile(spec, w, key, flat=1.0):
    """The row's top over the tile and the leading frame (2w columns) and the puff that makes it. The row's floor is
    a smooth slope down the face, low; the rolls stand on it, ragged: some tall, some lying flat (the face's lobes)."""
    ps = puffs(spec, w, key)
    assert max(p[2] for p in ps) + SKIRT <= spec["hold"], "a roll of the leading frame would reach into the tile"
    lo = spec["top"][0] - 2
    tops, who = [], []
    for X in range(2 * w):
        best, arg = 0.62 * lo * sink(spec, w, X), None
        for n in (-1, 0, 1, 2):
            for i, (cx, top, r) in enumerate(ps):
                ux = cx + n * w
                if abs(X + 0.5 - ux) >= r + SKIRT:
                    continue
                e = sink(spec, w, ux) if ux > w + spec["hold"] else 1.0
                if e <= 0:
                    continue
                g = 1 + (h01(key, i, n, 5) - 0.5) * 1.3 * min(1.0, 2.5 * (1 - e))  # the roll's own raggedness
                rr = max(3.0, r * (0.55 + 0.45 * e))
                fl = flat + (1 - flat) * min(1.0, 2.5 * (1 - e))        # down the face the rolls are round noses
                d = X + 0.5 - ux
                if abs(d) >= rr + SKIRT:
                    continue
                y = min(top, lo * e * (0.62 + 0.38 * g) + (top - lo) * (0.4 + 0.6 * e) * g) - roll(d, rr, fl)
                if y > best:
                    best, arg = y, (ux, rr, r >= 12 and h01(key, i, 9) < 0.6)
        tops.append(int(round(best)))
        who.append(arg)
    return tops, who


def strip(name):
    spec = STRIPS[name]
    w, h = spec["w"], spec["h"]
    rows = [profile(lv, w, spec["key"] * 16 + k, spec["flat"]) for k, lv in enumerate(spec["levels"])]
    px = [[None] * (2 * w) for _ in range(h)]
    for X in range(2 * w):
        L = X - 1 if X else w - 1                      # the tile repeats: column 0's left neighbour is its last one
        for yb in range(h):
            k = None
            for i in range(len(rows) - 1, -1, -1):     # the lowest row is the nearest
                if yb < rows[i][0][X]:
                    k = i
                    break
            if k is None:
                continue
            lv, (tops, who) = spec["levels"][k], rows[k]
            c = tone(*lv["body"])
            crown = yb == tops[X] - 1 and tops[L] <= tops[X]
            if crown or yb >= tops[L]:                 # facing up and left: the rim
                c = tone(*lv["rim"])
                a = who[X]
                if crown and lv.get("glint") and a and a[2] and a[0] - 0.8 * a[1] <= X + 0.5 <= a[0] - 0.1 * a[1]:
                    c = tone(*lv["glint"])
            px[h - 1 - yb][X] = c
    declump(px, w)
    return px


def declump(px, w):
    """No lone pixels: a pixel no 4-neighbour shares the value of takes its neighbours' most common value."""
    h, W = len(px), len(px[0])
    for _ in range(2):
        changes = []
        for y in range(h):
            for x in range(W):
                nb = []
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    xx, yy = x + dx, y + dy
                    if xx < 0:
                        xx = w - 1 if w else None
                    if xx is None or xx >= W or not 0 <= yy < h:
                        continue
                    nb.append(px[yy][xx])
                if px[y][x] in nb or len(nb) < 3:
                    continue
                changes.append((x, y, max(nb, key=lambda v: (nb.count(v), v is not None))))
        for x, y, v in changes:
            px[y][x] = v


# The shred's life, six frames: ellipses (cx, cy above the frame's bottom, rx, ry) and the body's alpha.
WISP = [
    (128, [(9, 6, 8, 5), (19, 7, 9, 6), (30, 5, 8, 4)]),
    (128, [(9, 6, 7, 4), (20, 7, 9, 5), (32, 6, 6, 3)]),
    (115, [(9, 7, 7, 3.5), (22, 8, 8, 4), (34, 7, 4, 2.2)]),
    (115, [(9, 8, 6, 3), (24, 9, 7, 3)]),
    (87, [(10, 9, 5, 2.4), (25, 10, 5, 2.2), (34, 9, 3, 1.6)]),
    (87, [(11, 10, 4, 1.7), (26, 11, 3, 1.6)]),
]


def wisp():
    fw, fh = 40, 16
    px = [[None] * (fw * len(WISP)) for _ in range(fh)]
    for f, (alpha, parts) in enumerate(WISP):
        def inside(x, yb):
            return any(((x + 0.5 - cx) / rx) ** 2 + ((yb + 0.5 - cy) / ry) ** 2 <= 1 for cx, cy, rx, ry in parts)
        for x in range(fw):
            for yb in range(fh):
                if not inside(x, yb):
                    continue
                lit = not inside(x, yb + 1) or not inside(x - 1, yb)
                low = not inside(x, yb - 1) and not lit
                c = tone("mistDark", alpha + 40) if lit else tone("farDeep", alpha + 20) if low else tone("far", alpha)
                px[fh - 1 - yb][f * fw + x] = c
    declump(px, 0)
    return px


# The eyes in the bank: (x of the left eye, height above the lane, an eye's width, the gap, the frame in which the
# pair is shut). The near pairs are low and two pixels wide, the far ones higher, smaller and dimmer.
EYES = [(5, 9, 2, 3, 0), (25, 15, 2, 2, 2), (45, 8, 2, 3, 3), (57, 24, 1, 2, 1), (13, 31, 2, 3, 3), (36, 40, 1, 3, 1),
        (50, 54, 1, 2, 0), (7, 58, 1, 2, 2), (28, 66, 1, 2, 0)]


def eyes():
    """gloomFogEyes: 4 frames of 64x72, an emissive like darknessBankGlow: every pair shuts for one frame and is a
    slit (dim) in the frame before."""
    fw, fh = 64, 72
    px = [[None] * (fw * 4) for _ in range(fh)]
    for f in range(4):
        for x, hgt, ew, gap, shut in EYES:
            if f == shut:
                continue
            slit = f == (shut + 3) % 4
            near = hgt < 36
            for ex in (x, x + ew + gap):
                for i in range(ew):
                    px[fh - 1 - hgt][f * fw + ex + i] = tone("wraithDim" if slit or not near else "wraithGlow", 255)
                if near and not slit and ew == 2:      # the near eye: a white spark on its inner pixel, a dim lid above
                    inner = ex + 1 if ex == x else ex
                    px[fh - 1 - hgt][f * fw + inner] = tone("wraithWhite", 255)
                    px[fh - 2 - hgt][f * fw + (ex if ex == x else ex + 1)] = tone("wraithDim", 255)
    return px


def build(name, out):
    px = wisp() if name == "gloomWisp" else eyes() if name == "gloomFogEyes" else strip(name)
    img = PA.Image(len(px[0]), len(px))
    for y, row in enumerate(px):
        for x, c in enumerate(row):
            if c:
                img.set(x, y, c)
    path = os.path.join(out, name + ".png")
    PA.write_png(path, img)
    print("wrote %s %dx%d" % (path, img.w, img.h))


IDS = ("gloomFogBack", "gloomFogMid", "gloomFogFront", "gloomWisp", "gloomFogEyes")


def main():
    a = sys.argv[1:]
    if len(a) != 4 or a[0] != "build" or a[1] not in IDS or a[2] != "--out":
        sys.exit(__doc__)
    build(a[1], a[3])


if __name__ == "__main__":
    main()
