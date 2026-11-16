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
# Step 3 (part B, POLISH.md 2 item 4), redrawn in step 4 (the critic's H2) and again in step 5 (b3-wind, the director's
# call 4 of 16.11. 11:07: in step 4 head and fin were both open 1 px chevrons, a white "bone" at phone size): an iron
# arrow on a rod that reads at 1x and says which way the wind blows. 13 x 11, the rod at col 6, so the vane mirrors round
# its rod. Side on: the head a filled wedge on the windward end (columns of 1, 3 and 5 px: 9 px) in the lit tone, a shaft
# two rows thick (its lit top over the iron), the fin a solid plate 4 wide and 5 tall in the dark iron with a 2 px V
# notch in its trailing edge (18 px), so the tail is clearly heavier than the head in shape and in value; the lit edge
# only on the shaft's top and the head, in stoneLight, one step under the battlements' lit top (stonePale), never on
# the fin; no crossbar; a 2 x 2 ball on the rod under the arrow, its collar a row into the roof. Frames: 0 side on (the
# head west, for a wind toward the valley), 1 and 2 turned a third and two thirds away (1 is the calm's: the head's
# wedge seen from the side, two columns, no barbs), 3 end on (the fin edge on, the head's point before it, the ball), 4
# side on with the head dipped a pixel and the fin flexed (a storm's shiver). Mirrored for a wind toward the shadow land
# (`WindLook`).
VANE_W, VANE_H = 13, 11
VANE_COLOURS = {"I": (47, 48, 62, 255), "i": (70, 73, 87, 255), "k": (150, 154, 162, 255)}
VANE_ROD = ["......I......", "......I......", "......I......", ".....iIi....."]
VANE_FRAMES = [
    [".............",
     "..k......IIII",
     ".kkkkkkkkIIII",
     "kkkIIIIIIII..",
     ".kk...I..IIII",
     "..k...kk.IIII",
     "......ii....."],
    [".............",
     "........III..",
     "...kkkkkIII..",
     "..kkIIIIII...",
     "...k..I.III..",
     "......kkIII..",
     "......ii....."],
    [".............",
     "........II...",
     ".....kkkII...",
     "....kkIII....",
     ".....kI.II...",
     "......kkII...",
     "......ii....."],
    [".............",
     "......I......",
     "......I......",
     ".....kk......",
     "......I......",
     "......kk.....",
     "......ii....."],
    ["...........II",
     ".........IIII",
     "..kkkkkkkII..",
     ".kkIIIIIIIIII",
     "kkk...I..IIII",
     ".kk...kk.II..",
     "..k...ii....."],
]


def vane_strip():
    out = Image(VANE_W * len(VANE_FRAMES), VANE_H)
    for k, top in enumerate(VANE_FRAMES):
        rows = top + VANE_ROD
        assert len(rows) == VANE_H and all(len(r) == VANE_W for r in rows), k
        for y, row in enumerate(rows):
            for x, ch in enumerate(row):
                if ch != ".":
                    out.set(k * VANE_W + x, y, VANE_COLOURS[ch])
    return out


# ------------------------------------------------------------------------------------------------ the gust's leaves
# Step 3 (part B, POLISH.md 2 item 5), redrawn in step 4 (the critic's H3 (b): over the town the 5 x 4 leaves in the
# trees' own dark greens were lost in front of roofs and crowns of their value): what a gust carries across the screen.
# 6 x 5 cells, 15 frames: three leaves, each four steps of a tumble (flat, turning, edge on as a kinked sliver, turned
# over), each with a 1 px pale lit edge along its top: two greens a step lighter than the crowns (leafLight over meadow
# with a leaf vein; meadow over leaf), and an autumn straw lighter than every roof (strawLight, a pale lit edge, straw
# for the vein), which `FrameBuilder` picks for one leaf in two; then three puffs of the lane's dust (soilLight and
# rockPale, a few loose pixels low in the cell), thinning out.
# Step 5 (b3-wind, the director's call 5 of 16.11. 11:07, H3 (a), (b): at phone size the edge-on frames were 1 px dotted
# diagonals that read as rain, and the straw was cream on the pale snow): no frame is thinner than 2 px, the edge-on
# frame is a 4 x 2 sliver (its lit top over its body, a dark lower pixel); every leaf has a 1 px darker lower edge (its
# shadow side, one step under its body) under its pale top edge, so it reads on snow and cloud; the autumn leaf is a
# darker ochre (woodLight under a straw edge, wood for the vein and the shadow side) that stands on snow and cloud.
GUST_W, GUST_H = 6, 5
GUST_TONES = [  # lit edge, body, vein, shadow side
    ((178, 196, 120, 255), (120, 144, 78, 255), (53, 78, 48, 255), (79, 106, 60, 255)),   # pale, leafLight, leaf, meadow
    ((120, 144, 78, 255), (79, 106, 60, 255), (34, 52, 40, 255), (53, 78, 48, 255)),      # leafLight, meadow, leafDark, leaf
    ((166, 138, 84, 255), (138, 99, 64, 255), (102, 66, 47, 255), (102, 66, 47, 255)),    # straw, woodLight, wood, wood
]
# Step 6 (b3-wind, the director's call S3 of 16.11. 12:25: "a leaf is 2 x 2 or 3 x 2 px in the two lightest tones of
# the crown it leaves, with a 1 px darker underside, and flips between two frames"; proven over the live town frame in
# ci-out/director/b3/wind/s6/00-smoke-leaves-python.png): frames 0 and 1 a 3 x 2 leaf and its flip, 2 and 3 a 2 x 2 leaf
# and its flip; the top row in the lit edge and the body, the lower row the shadow side. The vein is no longer drawn.
GUST_LEAF = [
    ["......", "......", ".LLB..", ".BDD..", "......"],
    ["......", "......", ".BLL..", ".DDB..", "......"],
    ["......", "......", ".LB...", ".DD...", "......"],
    ["......", "......", ".BL...", ".DB...", "......"],
]
GUST_DUST = [
    ["......", "......", "......", ".p.s..", "s.p.s."],
    ["......", "......", "......", "..s...", ".p..s."],
    ["......", "......", "......", "......", "..s..."],
]
DUST = {"s": (100, 81, 63, 255), "p": (168, 156, 136, 255)}   # soilLight, rockPale


def gust_strip():
    frames = []
    for lit, body, vein, shade in GUST_TONES:
        for rows in GUST_LEAF:
            frames.append([[{"L": lit, "B": body, "V": vein, "D": shade}.get(ch) for ch in row] for row in rows])
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
