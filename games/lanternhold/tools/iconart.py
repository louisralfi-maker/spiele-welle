#!/usr/bin/env python3
"""Lanternhold: the interface's circlet icon (look 2, stage 7; ART-look2.md section 19.4, SPRITES.md "The circlet
icon").

The lord of Lanternhold wears a narrow gold circlet, not a crown (portraitKing, portraitLady), so the audience's
symbol is that circlet: a narrow band seen a little from above, so it reads as a ring for a head, with one low point
at the brow that holds a small stone in the realm's teal. 24x16 art pixels, hand-set below.

  circletIcon      gold, for dark grounds (the HUD's action button): the lit rim of the front in the fire's gold, the
                   band's face in gold, its lower edge and the far side's inner face in the wood browns
  circletIconInk   the same shape in ink alone with the stone cut out, for the gold "End the audience" button, where
                   gold on gold would not read; one colour, so the interface may also tint it as a template

Each id is written three times: <id>.png (1x, 24x16), <id>@2x.png (48x32) and <id>@3x.png (72x48), every art pixel a
square of 2x2 and 3x3, so the system picks the file for the screen and a 24x16 pt icon keeps hard pixel edges on
every iPhone. The fire's gold and white are used on purpose: the icon is interface art and is never drawn in the lit
world (the emissive rule is for albedo).

  iconart.py build <id> [--out DIR]     writes the three files into DIR (default games/lanternhold/Resources/Art)
  iconart.py list                       the ids, for build-art-court.sh

Pure python 3 (pixelart.py's PNG and palette code), deterministic, well under a second.
"""
import argparse
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from pixelart import Image, Palette, write_png, DEFAULT_PALETTE  # noqa: E402

W, H = 24, 16
SCALES = (("", 1), ("@2x", 2), ("@3x", 3))

LEGEND = {
    "s": "straw",       # the far rim
    "w": "wood",        # the far side's inner face, in shade
    "d": "woodLight",   # the band's lower edge, the turn at the temples
    "g": "gold",        # the band's face
    "f": "fireGold",    # the front's lit rim
    "W": "fireWhite",   # one glint
    "c": "daySky",      # the stone
    "B": "roofLight",
    "b": "banner",
    "i": "ink",
}

CIRCLET = [
    "........................",
    "........................",
    "........ssssssss........",
    "....sssswwwwwwwwssss....",
    "..sswwww........wwwwss..",
    ".sdww..............wwds.",
    "gsd..................dsg",
    "fg....................gf",
    "gff........ff........ffg",
    "dggff.....fggf.....ffggd",
    ".ddggfWff.gcBg.ffffggdd.",
    "...ddggggffBbffggggdd...",
    ".....ddddggggggdddd.....",
    ".........dddddd.........",
    "........................",
    "........................",
]

# the ink icon: the same outline; the far side is the rim's line alone (one pixel), so the front band reads as near
INK = [
    "........................",
    "........................",
    "........iiiiiiii........",
    "....iiii........iiii....",
    "..ii................ii..",
    ".i....................i.",
    "ii....................ii",
    "ii....................ii",
    "iii........ii........iii",
    "iiiii.....iiii.....iiiii",
    ".iiiiiiii.i..i.iiiiiiii.",
    "...iiiiiiii..iiiiiiii...",
    ".....iiiiiiiiiiiiii.....",
    ".........iiiiii.........",
    "........................",
    "........................",
]

ICONS = {"circletIcon": CIRCLET, "circletIconInk": INK}


def paint(icon_id, pal):
    rows = ICONS[icon_id]
    assert len(rows) == H and all(len(r) == W for r in rows), icon_id
    img = Image(W, H)
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            if ch != ".":
                img.set(x, y, pal.color(LEGEND[ch]) + (255,))
    return img


def scaled(img, k):
    if k == 1:
        return img
    out = Image(img.w * k, img.h * k)
    for y in range(img.h):
        for x in range(img.w):
            c = img.get(x, y)
            if c[3]:
                for dy in range(k):
                    for dx in range(k):
                        out.set(x * k + dx, y * k + dy, c)
    return out


def main():
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest="cmd", required=True)
    b = sub.add_parser("build")
    b.add_argument("id")
    b.add_argument("--out", default=os.path.join(HERE, "..", "Resources", "Art"))
    sub.add_parser("list")
    a = ap.parse_args()
    if a.cmd == "list":
        print(" ".join(ICONS))
        return
    pal = Palette(DEFAULT_PALETTE, True)
    img = paint(a.id, pal)
    for suffix, k in SCALES:
        path = os.path.join(a.out, a.id + suffix + ".png")
        write_png(path, scaled(img, k))
        print("wrote", path, "%dx%d" % (W * k, H * k))


if __name__ == "__main__":
    main()
