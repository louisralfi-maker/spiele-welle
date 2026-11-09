#!/usr/bin/env python3
"""Lanternhold look 2, stage 3: one sheet of the creatures, every frame, lit by day and unlit at night.
Pure python 3 (pixelart.py's PNG helpers), a few seconds for the full sheet.

  creaturesheet.py <out.png> [--art DIR] [--scale 4] [--ids a,b,…] [--bands day,fog,dark]

Bands per row of creatures:
  day   the albedo strip in daylight, on a pale look-2 day backdrop
  fog   unlit at night as the engine draws it (EntityFrames: the body at unlitValue 0.2 under the night ambient, a
        moon rim of 0.9 on the screen-right edge pixels, the glow strip replacing the body's pixels), against the
        bright periwinkle fog of ART-look2.md 2.2
  dark  the same against the dark fir belt and lane, where the glow strip alone has to carry the creature
"""
import argparse
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from pixelart import Image, read_png, write_png  # noqa: E402

GAME = os.path.dirname(HERE)
ART = os.path.join(GAME, "Resources", "Art")
SIZES = {"sootling": (14, 14, 6), "sootlingB": (14, 14, 6), "shadehound": (22, 14, 6), "sootCrow": (12, 10, 4),
         "ashBrute": (44, 44, 7), "gloomweaver": (30, 30, 4), "ashGiant": (110, 110, 7), "lightlessKing": (64, 64, 7)}
LAYOUT = [["sootling", "sootlingB", "shadehound", "sootCrow"], ["ashBrute", "gloomweaver"], ["lightlessKing"],
          ["ashGiant"]]
NIGHT_AMB = (0.42, 0.52, 1.0)      # the look-2 night ambient's hue (ART-look2.md 4), normalised to blue
MOON = (140, 153, 209)         # Shaders.metal kMoonRim
UNLIT, RIM = 0.2, 0.9


def hexc(s):
    return tuple(int(s[i:i + 2], 16) for i in (1, 3, 5))


def mix(a, b, t):
    return tuple(a[i] + (b[i] - a[i]) * t for i in range(3))


def backdrop(band, y, h, x):
    """Colour of the backdrop at row y of a band h tall (the last 4 rows are the lane)."""
    ground = y >= h - 4
    if band == "day":
        if ground:
            return hexc("#6E6A58") if (x + y) % 7 else hexc("#625E4E")
        return mix(hexc("#9FB3C2"), hexc("#C9CFC4"), y / max(1, h - 5))
    if ground:
        return hexc("#15223E") if (x * 3 + y) % 5 else hexc("#101A32")
    if band == "fog":
        return mix(hexc("#8D95F4"), hexc("#535FBE"), y / max(1, h - 5))
    return mix(hexc("#24346A"), hexc("#141F42"), y / max(1, h - 5))


def strip(art, name):
    w, h, n = SIZES[name]
    body, _ = read_png(os.path.join(art, name + ".png"))
    gp = os.path.join(art, name + "Glow.png")
    glow = read_png(gp)[0] if os.path.exists(gp) else None
    return w, h, n, body, glow


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("output")
    ap.add_argument("--art", default=ART)
    ap.add_argument("--scale", type=int, default=4)
    ap.add_argument("--ids", default="")
    ap.add_argument("--bands", default="day,fog,dark")
    a = ap.parse_args()
    ids = [i for i in a.ids.split(",") if i]
    bands = a.bands.split(",")
    layout = [[n for n in row if not ids or n in ids] for row in LAYOUT]
    layout = [r for r in layout if r]
    gap, sep, top = 2, 10, 6
    widths = [sum(SIZES[n][0] * SIZES[n][2] + gap * (SIZES[n][2] - 1) for n in r) + sep * (len(r) + 1) for r in layout]
    W = max(widths)
    heights = [max(SIZES[n][1] for n in r) + top + 4 for r in layout]
    H = sum(heights) * len(bands)
    out = [[(0, 0, 0)] * W for _ in range(H)]
    oy = 0
    for r, bh in zip(layout, heights):
        loaded = [strip(a.art, n) for n in r]
        for band in bands:
            for y in range(bh):
                row = out[oy + y]
                for x in range(W):
                    row[x] = backdrop(band, y, bh, x)
            ox = sep
            for w, h, n, body, glow in loaded:
                for k in range(n):
                    for y in range(h):
                        Y = oy + bh - 4 - h + y
                        for x in range(w):
                            p = body.get(k * w + x, y)
                            g = glow.get(k * w + x, y) if glow else (0, 0, 0, 0)
                            if not p[3] and not g[3]:
                                continue
                            if band == "day":
                                c = g[:3] if g[3] else p[:3]
                            else:
                                c = out[Y][ox + x]
                                if p[3]:
                                    edge = x == w - 1 or not body.get(k * w + x + 1, y)[3]
                                    c = tuple(p[i] * UNLIT * NIGHT_AMB[i] + (3, 5, 12)[i] for i in range(3))
                                    if edge:   # Shaders.metal: mix(lit, kMoonRim, 0.9)
                                        c = tuple(c[i] + (MOON[i] - c[i]) * RIM for i in range(3))
                                if g[3]:
                                    c = g[:3]
                            out[Y][ox + x] = c
                    ox += w + gap
                ox += sep - gap
            oy += bh
    s = a.scale
    img = Image(W * s, H * s)
    px = []
    for y in range(H):
        line = []
        for x in range(W):
            t = tuple(min(255, max(0, int(v + 0.5))) for v in out[y][x]) + (255,)
            line.extend([t] * s)
        for _ in range(s):
            px.extend(line)
    img.px = px
    write_png(a.output, img)
    print(f"wrote {a.output} {W * s}x{H * s}")


if __name__ == "__main__":
    main()
