#!/usr/bin/env python3
"""Lanternhold look 2, stage 3: the creatures as lost people (ART-look2.md "Stage 3: the creatures").
Builds a creature's albedo strip and glow strip from its rig in tools/creatures/<id>.py (rig.py is the painter).
Pure python 3 (pixelart.py's PNG and palette helpers); the largest sprite takes a few seconds.

  creatureart.py build <id>|all [--out DIR]
        Writes DIR/<id>.png and DIR/<id>Glow.png. DIR defaults to games/lanternhold/Resources/Art.
"""
import argparse
import importlib
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, "creatures"))
from pixelart import Image, Palette, write_png, DEFAULT_PALETTE  # noqa: E402

GAME = os.path.dirname(HERE)
ART = os.path.join(GAME, "Resources", "Art")
RIGGED = ["sootling", "sootlingB", "shadehound", "sootCrow", "ashBrute", "gloomweaver", "ashGiant", "lightlessKing"]


def build(name, out, pal):
    mod = importlib.import_module(name)
    w, h, n = mod.SIZE
    body, glow = Image(w * n, h), Image(w * n, h)
    for k in range(n):
        f = mod.frame(k)
        for y in range(h):
            for x in range(w):
                if f.b[y][x] is not None:
                    body.set(k * w + x, y, pal.color(f.b[y][x]) + (255,))
                if f.g[y][x] is not None:
                    glow.set(k * w + x, y, pal.color(f.g[y][x]) + (255,))
        if all(v is None for v in f.b[h - 1]) and not getattr(mod, "FLOATS", False):
            print(f"  note: {name} frame {k} has nothing on the bottom row")
    write_png(os.path.join(out, name + ".png"), body)
    write_png(os.path.join(out, name + "Glow.png"), glow)
    print(f"wrote {name}.png and {name}Glow.png {w * n}x{h} ({n} frames)")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("cmd", choices=["build"])
    ap.add_argument("name")
    ap.add_argument("--out", default=ART)
    ap.add_argument("--palette", default=DEFAULT_PALETTE)
    a = ap.parse_args()
    pal = Palette(a.palette, True)
    for name in ([n for n in RIGGED if os.path.exists(os.path.join(HERE, "creatures", n + ".py"))]
                 if a.name == "all" else [a.name]):
        build(name, a.out, pal)


if __name__ == "__main__":
    main()
