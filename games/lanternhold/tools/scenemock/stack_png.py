"""Stacks PNGs of one width top to bottom with a dark gap (old above new, for previews).
    python3 -I -B stack_png.py <out.png> <a.png> <b.png> ... [--crop x,y,w,h] [--scale n]
--crop cuts the same rectangle out of each input first; --scale repeats every pixel n times (nearest neighbour)."""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from pixelart import Image, read_png, write_png  # noqa: E402


def main():
    a = sys.argv[1:]
    crop, scale = None, 1
    if "--crop" in a:
        i = a.index("--crop"); crop = [int(v) for v in a[i + 1].split(",")]; del a[i:i + 2]
    if "--scale" in a:
        i = a.index("--scale"); scale = int(a[i + 1]); del a[i:i + 2]
    out, ins = a[0], a[1:]
    imgs = [read_png(p)[0] for p in ins]
    x0, y0, w, h = crop or (0, 0, imgs[0].w, imgs[0].h)
    gap = 4
    res = Image(w * scale, (h * scale) * len(imgs) + gap * (len(imgs) - 1))
    for n, im in enumerate(imgs):
        top = n * (h * scale + gap)
        for y in range(h):
            row = [im.get(x0 + x, y0 + y) for x in range(w)]
            for sy in range(scale):
                for x in range(w):
                    for sx in range(scale):
                        res.set(x * scale + sx, top + y * scale + sy, row[x])
    for n in range(len(imgs) - 1):
        for y in range(gap):
            for x in range(w * scale):
                res.set(x, (n + 1) * (h * scale) + n * gap + y, (8, 10, 20, 255))
    write_png(out, res)
    print("wrote", out, res.w, "x", res.h)


main()
