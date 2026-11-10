#!/usr/bin/env python3
"""Lanternhold look 2, stage 4: a preview sheet of any sprites, frame by frame, for judging art outside the mock.
Pure python 3 (pixelart.py's PNG helpers).

  artsheet.py <out.png> [--art DIR] [--scale 3] [--bands day,dusk,fire] [--gap 2] ITEM … [/ ITEM …]

ITEM is `id`, `id:FRAMEWIDTH` (a strip cut into frames of that width) or `path.png[:FRAMEWIDTH]`; `/` starts a new
row. `<id>Glow.png` beside a sprite is drawn over it (each glow pixel as its own colour, as the engine does).
Bands, one copy of every row each:
  day   the albedo on a pale look-2 day backdrop over a strip of lane
  dusk  the albedo under the dusk ambient (ART-look2.md 4: #708FD1 x 0.30 plus the navy lift), with the people's cool
        rim (0.35) on the screen-right edge pixels, against the dusk air
  fire  the albedo in a torch's light (#FF9442, falling to ember), against dark stone
"""
import argparse
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from pixelart import Image, read_png, write_png  # noqa: E402

ART = os.path.join(os.path.dirname(HERE), "Resources", "Art")
RIMC = (158, 178, 242)


def hexc(s):
    return tuple(int(s[i:i + 2], 16) for i in (1, 3, 5))


def mix(a, b, t):
    return tuple(a[i] + (b[i] - a[i]) * t for i in range(3))


def backdrop(band, y, h, x):
    ground = y >= h - 4
    if band == "day":
        if ground:
            return hexc("#6E6A58") if (x + y) % 7 else hexc("#625E4E")
        return mix(hexc("#9FB3C2"), hexc("#C9CFC4"), y / max(1, h - 5))
    if band == "dusk":
        if ground:
            return hexc("#2A2F4E") if (x * 3 + y) % 5 else hexc("#22263F")
        return mix(hexc("#3A3F78"), hexc("#7A5A6E"), y / max(1, h - 5))
    if ground:
        return hexc("#3A2018") if (x * 3 + y) % 5 else hexc("#2C1812")
    return mix(hexc("#1A1420"), hexc("#3A2220"), y / max(1, h - 5))


def shade(band, p):
    if band == "day":
        return p
    if band == "dusk":
        a = (0.44 * 0.75, 0.56 * 0.75, 0.82 * 0.75)
        return tuple(p[i] * a[i] + (8, 10, 24)[i] * 0.6 for i in range(3))
    a = (1.0, 0.58, 0.26)
    return tuple(min(255, p[i] * a[i] * 0.95 + (10, 6, 10)[i]) for i in range(3))


def load(art, item):
    name, fw = (item.rsplit(":", 1) + [None])[:2] if ":" in item else (item, None)
    path = name if name.endswith(".png") else os.path.join(art, name + ".png")
    body, _ = read_png(path)
    gp = path[:-4] + "Glow.png"
    glow = read_png(gp)[0] if os.path.exists(gp) else None
    fw = int(fw) if fw else body.w
    return fw, body.h, body.w // fw, body, glow


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("output")
    ap.add_argument("items", nargs="+")
    ap.add_argument("--art", default=ART)
    ap.add_argument("--scale", type=int, default=3)
    ap.add_argument("--bands", default="day")
    ap.add_argument("--gap", type=int, default=2)
    a = ap.parse_args()
    rows, cur = [], []
    for it in a.items:
        if it == "/":
            rows.append(cur); cur = []
        else:
            cur.append(load(a.art, it))
    rows.append(cur)
    rows = [r for r in rows if r]
    bands = a.bands.split(",")
    gap, sep, top = a.gap, 8, 5
    W = max(sum(w * n + gap * (n - 1) for w, h, n, b, g in r) + sep * (len(r) + 1) for r in rows)
    heights = [max(h for w, h, n, b, g in r) + top + 4 for r in rows]
    H = sum(heights) * len(bands)
    out = [[(0, 0, 0)] * W for _ in range(H)]
    oy = 0
    for r, bh in zip(rows, heights):
        for band in bands:
            for y in range(bh):
                for x in range(W):
                    out[oy + y][x] = backdrop(band, y, bh, x)
            ox = sep
            for w, h, n, body, glow in r:
                for k in range(n):
                    for y in range(h):
                        Y = oy + bh - 4 - h + y
                        for x in range(w):
                            p = body.get(k * w + x, y)
                            g = glow.get(k * w + x, y) if glow else (0, 0, 0, 0)
                            if g[3]:
                                out[Y][ox + x] = g[:3]
                            elif p[3]:
                                c = shade(band, p[:3])
                                if band == "dusk" and (x == w - 1 or not body.get(k * w + x + 1, y)[3]):
                                    c = mix(c, RIMC, 0.35)
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
