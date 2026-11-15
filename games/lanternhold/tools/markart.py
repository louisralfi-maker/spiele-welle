#!/usr/bin/env python3
"""Lanternhold: the marks of "touch the world" as signs alone (stage lane, step stage-3-interface, 15.11.2026).

The director's note of 15.11.2026 07:30 and HUD.md rule 2: a mark is the sign alone on the world's pixel grid, in bone
with a dark ink edge, no plate, no parchment (the parchment tag of tools/hallart.py goes). The gold rim on the marked
thing stays (the engine draws it). Each mark keeps its sprite's size, 15 x 18 per frame, two frames (idle, pressed),
so the code places it as before: the sign's 11 x 11 cell (a 9 x 9 body inside its one-pixel ink edge) stands centred
over frame x 7 with its bottom on the frame's bottom row, where the tag's tip was. Pressed, the bone turns lantern
gold. Drawn unlit; at night the engine draws the marks at three quarters of their value, warmed.

  markart.py build <id> [--out DIR]   writes DIR/<id>.png (default games/lanternhold/Resources/Art)
  markart.py list

Pure python 3 (hudart.py's edge and pixelart.py's PNG and palette code), deterministic, well under a second.
"""
import argparse
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from pixelart import Image, write_png  # noqa: E402
import hudart  # noqa: E402

FRAME_W, FRAME_H = 15, 18
CELL = 11

# The sign bodies, 9 x 9 at most: X bone, x bone in shade, i ink inside the sign, g gold, h lit gold, R a tile red.
# hudart.LEGEND names their palette colours.
GLYPHS = {
    "tapTalk": [           # a speech bubble with three dots: speak with the one who waits
        ".XXXXXXX.",
        "XXXXXXXXX",
        "XXXXXXXXX",
        "XiXXiXXiX",
        "XXXXXXXXX",
        ".XXXXXXX.",
        "..XXx....",
        ".XXx.....",
        ".x.......",
    ],
    "tapThrone": [         # the circlet: take the seat, hold the audience
        ".........",
        "X...X...X",
        "XX.XgX.XX",
        "XXXXXXXXX",
        "XxXxRxXxX",
        "XXXXXXXXX",
        ".xxxxxxx.",
    ],
    "tapBuild": [          # a claw hammer: the striking block left, the claw right, the haft under the block
        ".XXXX....",
        "XXXXXXXX.",
        "XXXXXXXXX",
        ".XXXx..XX",
        "..XX.....",
        "..XX.....",
        "..Xx.....",
        "..Xx.....",
        "..xx.....",
    ],
    "tapRepair": [         # a wall of four stones with a crack: repair
        "XXXXiXXXX",
        "XXXXiXXRX",
        "xxxxixxRx",
        "iiiiiiRii",
        "XXiXXXRXX",
        "XXiXXRXXX",
        "xxixxRxxx",
    ],
    "tapRecruit": [        # a head and shoulders and a plus: recruit
        "..XXX...g",
        ".XXXXX.gh",
        ".XXXXX..g",
        "..XXX....",
        ".........",
        ".XXXXX...",
        "XXXXXXX..",
        "XXXxXXX..",
        "XXXxXXX..",
    ],
    "tapLight": [          # a flame: light the brazier
        "....X....",
        "....XX...",
        "...XXX...",
        "..XXgXX..",
        "..XghXX..",
        ".XXghgXX.",
        ".XghhgXX.",
        "..XgggX..",
        "...XXX...",
    ],
    "tapDoor": [           # an arched double door with its ring: go in, go out (two seams read as a pause sign)
        "..XXXXX..",
        ".XXXXXXX.",
        "XXXXiXXXX",
        "XXXXiXXXX",
        "XXXXiXgXX",
        "XXXXiXXXX",
        "XXXXiXXXX",
        "xxxxixxxx",
        "xxxxxxxxx",
    ],
}

# Pressed: the bone lit to lantern gold (the rim on the thing brightens with it).
PRESSED = {"X": "h", "x": "g"}


def frame(rows, pal, pressed=False):
    if pressed:
        rows = ["".join(PRESSED.get(c, c) for c in row) for row in rows]
    sign = hudart.edged(hudart.grid_image(rows, pal), pal, CELL, CELL)
    out = Image(FRAME_W, FRAME_H)
    ox = (FRAME_W - CELL) // 2
    oy = FRAME_H - CELL
    for y in range(CELL):
        for x in range(CELL):
            c = sign.get(x, y)
            if c[3]:
                out.set(ox + x, oy + y, c)
    return out


def build(name, pal):
    rows = GLYPHS[name]
    return hudart.strip([frame(rows, pal), frame(rows, pal, pressed=True)])


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    b = sub.add_parser("build")
    b.add_argument("id")
    b.add_argument("--out", default=os.path.join(HERE, "..", "Resources", "Art"))
    sub.add_parser("list")
    a = ap.parse_args()
    if a.cmd == "list":
        print(" ".join(GLYPHS))
        return
    if a.id not in GLYPHS:
        raise SystemExit("unknown mark " + a.id)
    img = build(a.id, hudart.palette())
    path = os.path.join(a.out, a.id + ".png")
    write_png(path, img)
    print("wrote", path, "%dx%d" % (img.w, img.h))


if __name__ == "__main__":
    main()
