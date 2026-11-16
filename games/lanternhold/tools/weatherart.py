#!/usr/bin/env python3
"""Lanternhold: the weather's own sprites (build 3, POLISH pass 1; docs/POLISH.md 2 "The two rains"; lane 3).

  weatherart.py ash [--out DIR]    writes DIR/ashFlake.png (default games/lanternhold/Resources/Art)
  weatherart.py vane [--out DIR]   writes DIR/weatherVane.png
  weatherart.py gust [--out DIR]   writes DIR/gustLeaf.png

ashFlake: 16 frames of 5x5, the ash that falls west of the outermost standing wall where the rain is water on the
town's side. Step 3 (the critic's H2, the director's calls 1 and 3): hard pixel clumps with no soft alpha ring, so a
flake is a thing that falls and never a smudge on the glass.

- frames 0-3 small (a 2 x 2 clump), 4-7 middling (3 x 2 or 2 x 3), 8-11 big (4 x 3 with a notch), each four steps of a
  tumble by turning the clump: flat, tilted one way, edge on, tilted the other way. Only the big size has a true edge-on
  frame, and it is a kinked sliver one pixel thick, never a straight 1 x 3 dash: no flake looks like a tiny streak.
- two tones a flake: a lit top pixel and a darker body. White and light grey, because the engine tints it by the hour
  (`FrameBuilder.ashTint`: warm soot by day; pale at night, where a faint emissive copy keeps the value).
- frames 12 and 13: the ember's body by day (the director's idea): one pixel, and two by two in fire gold over the
  torch's orange, where a flake that is born an ember starts its fall; it dies to the grey flake.
- frames 14 and 15 (step 4, the critic's H1): the same pixels in the window glass's ink (42, 34, 48). The ember's light
  goes out as a glass quad over them, and the renderer lights only glass-ink pixels in a glass quad, its colour as it
  is (the glow quad kept 40 % of the hue and the ember came out pale peach).

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
GLASS_INK = (42, 34, 48, 255)    # the palette's ink: a glass pixel for the renderer's glass quad
EMBERS = [
    [".....", ".....", "..h..", ".....", "....."],
    [".....", ".....", ".hh..", ".ho..", "....."],
    [".....", ".....", "..g..", ".....", "....."],
    [".....", ".....", ".gg..", ".gg..", "....."],
]
COLOURS = {"L": LIT, "B": BODY, "D": EDGE, "h": EMBER_HOT, "o": EMBER, "g": GLASS_INK}


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


# ------------------------------------------------------------------------------------------------ the weather vane
# Step 3 (part B, POLISH.md 2 item 4): a small iron vane on the keep's east tower (the cone's apex at tier 3, the
# merlons at tiers 1 and 2), seen side on: a knob on the rod, an arrow whose head points into the wind, a swallowtail fin
# downwind (kin of the keep's flag), a small cross bar on the rod and its collar on the roof. Iron in the keep's slate
# values (stoneDark body, stoneMid on the lit upper edges, stoneLight on the knob). 9 x 12, the rod at col 4, so the
# vane mirrors round its rod. Frames: 0 side on (the head west, for a wind toward the valley), 1 and 2 turned a third and
# two thirds away, 3 end on, 4 side on with the fin flexed and the head dipped (a storm's shiver). Mirrored for a wind
# toward the shadow land (`WindLook`).
VANE_W, VANE_H = 9, 12
VANE_COLOURS = {"I": (47, 48, 62, 255), "i": (70, 73, 87, 255), "k": (150, 154, 162, 255), "F": (70, 73, 87, 255),
                "f": (47, 48, 62, 255)}
VANE_ROD = ["....I....", "...iIi...", "....I....", "....I....", "....I....", "....I....", "...IIi..."]
VANE_FRAMES = [
    ["....k....", ".i..I..FF", "iIIIIIIFf", ".I..I..f."],
    ["....k....", "..i.I.FF.", ".iIIIIFf.", "..I.I.f.."],
    ["....k....", "....IF...", "..iIIf...", "....I...."],
    ["....k....", "....I....", "...iIi...", "....I...."],
    ["....k..F.", ".i..I..Ff", "iIIIIIIf.", ".I..I...."],
]


def vane_strip():
    out = Image(VANE_W * len(VANE_FRAMES), VANE_H)
    for k, top in enumerate(VANE_FRAMES):
        for y, row in enumerate(top + ["....I...."] + VANE_ROD):
            for x, ch in enumerate(row):
                if ch != ".":
                    out.set(k * VANE_W + x, y, VANE_COLOURS[ch])
    return out


# ------------------------------------------------------------------------------------------------ the gust's leaves
# Step 3 (part B, POLISH.md 2 item 5): what a gust carries across the screen. 5 x 4 cells, 15 frames: three leaves
# (the trees' own greens, leaf over leafLight and leafDark over leaf, and one autumn tone, straw over strawLight), each
# four steps of a tumble (flat, turning, edge on, turned over); then three puffs of the lane's dust (soilLight and
# rockPale, a few loose pixels low in the cell), thinning out.
GUST_W, GUST_H = 5, 4
GUST_TONES = [((53, 78, 48, 255), (120, 144, 78, 255)),     # leaf, leafLight
              ((34, 52, 40, 255), (53, 78, 48, 255)),       # leafDark, leaf
              ((166, 138, 84, 255), (196, 168, 114, 255))]  # straw, strawLight: the autumn leaf
GUST_LEAF = [
    [".....", ".LB..", "..BB.", "....."],
    [".....", "..L..", ".BB..", "....."],
    [".....", "...L.", "..B..", ".B..."],
    [".....", ".BB..", "..BL.", "....."],
]
GUST_DUST = [
    [".....", ".....", ".p.s.", "s.p.s"],
    [".....", ".....", "..s..", ".p..s"],
    [".....", ".....", ".....", "..s.."],
]
DUST = {"s": (100, 81, 63, 255), "p": (168, 156, 136, 255)}   # soilLight, rockPale


def gust_strip():
    frames = []
    for body, lit in GUST_TONES:
        for rows in GUST_LEAF:
            frames.append([[{"L": lit, "B": body}.get(ch) for ch in row] for row in rows])
    for rows in GUST_DUST:
        frames.append([[DUST.get(ch) for ch in row] for row in rows])
    out = Image(GUST_W * len(frames), GUST_H)
    for k, f in enumerate(frames):
        for y, row in enumerate(f):
            for x, c in enumerate(row):
                if c:
                    out.set(k * GUST_W + x, y, c)
    return out


def main():
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest="cmd", required=True)
    for cmd in ("ash", "vane", "gust"):
        a = sub.add_parser(cmd)
        a.add_argument("--out", default=os.path.join(HERE, "..", "Resources", "Art"))
    args = ap.parse_args()
    os.makedirs(args.out, exist_ok=True)
    name, img = {"ash": ("ashFlake", ash_strip), "vane": ("weatherVane", vane_strip),
                 "gust": ("gustLeaf", gust_strip)}[args.cmd]
    img = img()
    write_png(os.path.join(args.out, name + ".png"), img)
    print(f"wrote {name}.png {img.w}x{img.h}")


if __name__ == "__main__":
    main()
