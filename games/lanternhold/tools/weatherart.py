#!/usr/bin/env python3
"""Lanternhold: the weather's own sprites (build 3, POLISH pass 1; docs/POLISH.md 2 "The two rains"; lane 3).

  weatherart.py ash [--out DIR]    writes DIR/ashFlake.png (default games/lanternhold/Resources/Art)

ashFlake: 14 frames of 5x5, the ash that falls west of the outermost standing wall where the rain is water on the
town's side. Step 3 (the critic's H2, the director's calls 1 and 3): hard pixel clumps with no soft alpha ring, so a
flake is a thing that falls and never a smudge on the glass.

- frames 0-3 small (a 2 x 2 clump), 4-7 middling (3 x 2 or 2 x 3), 8-11 big (4 x 3 with a notch), each four steps of a
  tumble by turning the clump: flat, tilted one way, edge on, tilted the other way. Only the big size has a true edge-on
  frame, and it is a kinked sliver one pixel thick, never a straight 1 x 3 dash: no flake looks like a tiny streak.
- two tones a flake: a lit top pixel and a darker body. White and light grey, because the engine tints it by the hour
  (`FrameBuilder.ashTint`: warm soot by day; pale at night, where a faint emissive copy keeps the value).
- frames 12 and 13: the ember (the director's idea): one pixel and two pixels in fire orange, drawn as an emissive point
  where a flake that is born an ember starts its fall; it dies to the grey flake within the first third of the fall.

No streak and no splash: the difference from the rain reads in the shape, the value and the slow drift.

Pure python 3 (pixelart.py's PNG code), deterministic, well under a second.
"""
import argparse
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from pixelart import Image, write_png  # noqa: E402

ASH_S = 5
LIT = (255, 252, 246, 255)     # the lit top pixel
BODY = (184, 180, 176, 255)    # the body, a step darker
EDGE = (150, 146, 144, 255)    # the shaded underside of the big clump
EMBER_HOT = (255, 198, 90, 255)   # fireGold: the ember's heart
EMBER = (255, 138, 42, 255)       # fireOrange: the torch's orange

# The clumps, each drawn into the 5 x 5 cell (rows top to bottom): L lit, B body, D the shaded underside.
CLUMPS = [
    # small, 2 x 2: flat, tilted, edge on (lying: a 2 x 1), tilted back
    [".....", ".LB..", ".BB..", ".....", "....."],
    [".....", ".L...", ".BB..", ".....", "....."],
    [".....", ".....", ".LB..", ".....", "....."],
    [".....", "..L..", ".BB..", ".....", "....."],
    # middling, 3 x 2 and 2 x 3: flat, tilted (a parallelogram), standing, tilted back
    [".....", ".LLB.", ".BBB.", ".....", "....."],
    [".....", "..LB.", ".BB..", ".BD..", "....."],
    [".....", ".LB..", ".BB..", ".BD..", "....."],
    [".....", ".LB..", "..BB.", "..DB.", "....."],
    # big, 4 x 3 with a notch: flat, tilted, edge on (a kinked sliver), tilted back
    [".....", ".LLB.", ".BBBB", ".BD.D", "....."],
    [".....", "LLB..", ".BBB.", "..BD.", "....."],
    [".....", "..L..", "..B..", "...D.", "....."],
    [".....", "..BLL", ".BBB.", ".DB..", "....."],
]
EMBERS = [
    [".....", ".....", "..h..", ".....", "....."],
    [".....", ".....", ".ho..", ".....", "....."],
]
COLOURS = {"L": LIT, "B": BODY, "D": EDGE, "h": EMBER_HOT, "o": EMBER}


def frame(rows):
    img = Image(ASH_S, ASH_S)
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            if ch != ".":
                img.set(x, y, COLOURS[ch])
    return img


def ash_strip():
    frames = [frame(rows) for rows in CLUMPS + EMBERS]
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
