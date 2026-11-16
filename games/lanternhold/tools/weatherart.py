#!/usr/bin/env python3
"""Lanternhold: the weather's own sprites (build 3, POLISH pass 1 step 2; docs/POLISH.md 2 "The two rains"; lane 3).

  weatherart.py ash [--out DIR]    writes DIR/ashFlake.png (default games/lanternhold/Resources/Art)

ashFlake: 12 frames of 5x5, the ash that falls west of the outermost standing wall where the rain is water on the
town's side: three sizes (frames 0-3 small, 4-7 middling, 8-11 big) by four steps of a tumble (the flake flat, turning,
edge on, turning back the other way). A soft flake: an ellipse sampled four by four per pixel, so its edge fades in
alpha, never a hard square; white with a faint grey grain, because the engine tints it by the hour
(`FrameBuilder.ashTint`: dark against a pale day sky, pale against the night). No streak and no splash: the
difference from the rain reads in the shape and the slow drift.

Pure python 3 (pixelart.py's PNG code), deterministic, well under a second.
"""
import argparse
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from pixelart import Image, write_png  # noqa: E402

ASH_S = 5
ASH_SIZES = (1.05, 1.5, 2.05)        # the flake's half length, by size
ASH_TUMBLE = 4


def h01(*k):
    v = 2166136261
    for a in k:
        v = ((v ^ (a & 0xFFFFFFFF)) * 16777619) & 0xFFFFFFFF
        v ^= v >> 13
    v = (v * 2654435761) & 0xFFFFFFFF
    return (v >> 8) / float(1 << 24)


def ash_frame(size, step):
    """One flake: half length a, its width shrinking as it turns edge on (step 2) and its axis turning a quarter of
    a half turn a step; alpha from the coverage of 16 samples per pixel."""
    a = ASH_SIZES[size]
    phase = step * math.pi / ASH_TUMBLE
    b = 0.32 + 0.5 * a * abs(math.cos(phase))
    th = math.radians(18 + 40 * step)
    c, s = math.cos(th), math.sin(th)
    cx = cy = (ASH_S - 1) / 2.0
    img = Image(ASH_S, ASH_S)
    for y in range(ASH_S):
        for x in range(ASH_S):
            hit = 0
            for j in range(4):
                for i in range(4):
                    px = x + (i + 0.5) / 4 - 0.5 - cx
                    py = y + (j + 0.5) / 4 - 0.5 - cy
                    u = px * c + py * s
                    v = -px * s + py * c
                    if (u / a) ** 2 + (v / b) ** 2 <= 1:
                        hit += 1
            if hit:
                cover = hit / 16.0
                grain = int(18 * h01(size, step, x, y))
                g = 255 - grain
                img.set(x, y, (g, g, g - 4, int(round(255 * min(1.0, cover * 1.15)))))
    return img


def ash_strip():
    frames = [ash_frame(size, step) for size in range(len(ASH_SIZES)) for step in range(ASH_TUMBLE)]
    out = Image(ASH_S * len(frames), ASH_S)
    for k, f in enumerate(frames):
        for y in range(ASH_S):
            for x in range(ASH_S):
                p = f.get(x, y)
                if p[3]:
                    out.set(k * ASH_S + x, y, p)
    return out


def main():
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest="cmd", required=True)
    a = sub.add_parser("ash")
    a.add_argument("--out", default=os.path.join(HERE, "..", "Resources", "Art"))
    args = ap.parse_args()
    os.makedirs(args.out, exist_ok=True)
    img = ash_strip()
    write_png(os.path.join(args.out, "ashFlake.png"), img)
    print(f"wrote ashFlake.png {img.w}x{img.h}")


if __name__ == "__main__":
    main()
