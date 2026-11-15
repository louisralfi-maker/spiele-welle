#!/usr/bin/env python3
"""Lanternhold world rebuild, fix round 2 (the critic: "the cobble lane ends in a straight vertical seam against the
meadow just past the postern tower"): `laneCobbleEnd`, the lane tile where the castle's cobbles give way to the
valley's earth lane (world 2432 to 2496). Pure python, palette colours of its two sources only, no randomness (hashes
of the position), so a run reproduces its file byte for byte.

The tile is the earth tile with the cobble tile laid over it in whole stones: the cobbles are cut into stones (the
cobble tile's dark joints bound them), and a stone stays while a wandering line, feathered over 48 px, has not passed
it; stones near the line sink (their lit top goes, they take the earth's darkest step at their foot), so the cobbles
thin out stone by stone into the mud, never along a column.

  lanejoin.py build laneCobbleEnd --out <Art dir>
  lanejoin.py build laneScreeCobble --out <Art dir>   (world-2: scree to cobbles under the gatehouse's gateway)
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import pixelart as PA  # noqa: E402
import worldart as WA  # noqa: E402

h01 = WA.h01
vnoise = WA.vnoise


def luma(c):
    return 0.3 * c[0] + 0.59 * c[1] + 0.11 * c[2]


def stones(img):
    """The cobble tile's stones: 4-connected areas of pixels lighter than the tile's joints (its darkest third)."""
    w, h = img.w, img.h
    ls = sorted(luma(img.get(x, y)) for y in range(h) for x in range(w) if img.get(x, y)[3])
    joint = ls[len(ls) // 3] if ls else 0
    label = [[-1] * w for _ in range(h)]
    n = 0
    for y in range(h):
        for x in range(w):
            p = img.get(x, y)
            if label[y][x] >= 0 or not p[3] or luma(p) <= joint:
                continue
            stack = [(x, y)]
            label[y][x] = n
            while stack:
                cx, cy = stack.pop()
                for (nx, ny) in ((cx - 1, cy), (cx + 1, cy), (cx, cy - 1), (cx, cy + 1)):
                    if 0 <= nx < w and 0 <= ny < h and label[ny][nx] < 0:
                        q = img.get(nx, ny)
                        if q[3] and luma(q) > joint:
                            label[ny][nx] = n
                            stack.append((nx, ny))
            n += 1
    return label, n


def join(cobble, earth):
    w, h = cobble.w, cobble.h
    out = PA.Image(w, h, list(earth.px))
    label, n = stones(cobble)
    # each stone's centre
    sx, sy, cnt = [0.0] * n, [0.0] * n, [0] * n
    for y in range(h):
        for x in range(w):
            k = label[y][x]
            if k >= 0:
                sx[k] += x
                sy[k] += y
                cnt[k] += 1
    keep = []
    for k in range(n):
        cx, cy = sx[k] / max(1, cnt[k]), sy[k] / max(1, cnt[k])
        # the line wanders with the row; feathered over 48 px (x 8 ... 56): a stone stays with a chance that falls
        # from 1 to 0 across it
        line = 8 + 48 * (cx - 8 + 10 * (vnoise(821, cy / 5.0) - 0.5)) / 48.0
        u = min(1.0, max(0.0, (line - 8) / 48.0))
        keep.append(h01(823, k, int(cx), int(cy)) > u ** 0.9)
    sunk = [keep[k] and h01(827, k) < (min(1.0, max(0.0, (sx[k] / max(1, cnt[k]) - 20) / 36.0))) for k in range(n)]
    earth_dark = min((earth.get(x, y) for y in range(h) for x in range(w) if earth.get(x, y)[3]), key=luma)
    for y in range(h):
        for x in range(w):
            k = label[y][x]
            # joints next to kept stones stay (the stone's own outline); elsewhere the earth shows
            if k < 0:
                near = [label[yy][xx] for (xx, yy) in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1))
                        if 0 <= xx < w and 0 <= yy < h and label[yy][xx] >= 0]
                if near and any(keep[j] for j in near) and x < 8 + 48 * 0.8:
                    out.set(x, y, cobble.get(x, y))
                elif x < 6:
                    out.set(x, y, cobble.get(x, y))
                continue
            if not keep[k]:
                continue
            c = cobble.get(x, y)
            if sunk[k]:
                # a sinking stone: no lit top, its lowest row in the earth's dark
                above = y > 0 and label[y - 1][x] == k
                below = y + 1 < h and label[y + 1][x] == k
                if not above:
                    c = cobble.get(x, min(h - 1, y + 1)) if below else c
                if not below:
                    c = earth_dark
            out.set(x, y, c)
    return out


def flipped(img):
    out = PA.Image(img.w, img.h)
    for y in range(img.h):
        for x in range(img.w):
            out.set(img.w - 1 - x, y, img.get(x, y))
    return out


def main():
    a = sys.argv[1:]
    if len(a) == 4 and a[0] == "build" and a[1] == "laneScreeCobble" and a[2] == "--out":
        # World-2 (2.8: the lane changes under the gates, never in the open): under the gatehouse's gateway the Throat's
        # scree gives way to the castle's cobbles, stone by stone: the same join, mirrored (the cobbles to the east).
        art = a[3]
        cobble = flipped(PA.read_png(os.path.join(art, "laneCobbleA.png"))[0])
        scree = flipped(PA.read_png(os.path.join(art, "laneScreeC.png"))[0])
        img = flipped(join(cobble, scree))
        path = os.path.join(art, "laneScreeCobble.png")
        PA.write_png(path, img)
        print("wrote", path, img.w, "x", img.h)
        return
    if len(a) == 4 and a[0] == "build" and a[1] == "laneCobbleEnd" and a[2] == "--out":
        art = a[3]
        cobble = PA.read_png(os.path.join(art, "laneCobbleB.png"))[0]
        earth = PA.read_png(os.path.join(art, "laneEarthA.png"))[0]
        img = join(cobble, earth)
        path = os.path.join(art, "laneCobbleEnd.png")
        PA.write_png(path, img)
        print("wrote", path, img.w, "x", img.h)
        return
    raise SystemExit(__doc__)


if __name__ == "__main__":
    main()
