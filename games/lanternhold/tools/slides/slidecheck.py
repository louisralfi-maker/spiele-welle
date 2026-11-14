#!/usr/bin/env python3
"""Checks the lantern slides (panels lane; critic look 1 of panels-1, blocker 2): every pixel of every picture in
Resources/Slides is a colour of tools/palette.txt, and every picture is 320 x 160. Exits 1 and names the picture and
its count of strange pixels otherwise. Light work (a few PNGs read), but run it through the art lock like any image job:

    bash <artlock.sh> python3 -I tools/slides/slidecheck.py [--swift]

--swift prints the palette as the Swift set the unit test SlidesPaletteTests keeps (paste it there when the palette
changes).
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from paint import GAME, PAL, read_png  # noqa: E402

SLIDES = os.path.join(GAME, "Resources", "Slides")


def main():
    if "--swift" in sys.argv:
        values = sorted(set(PAL.values()))
        items = ["0x%02X%02X%02X" % v for v in values]
        for i in range(0, len(items), 8):
            print("        " + ", ".join(items[i:i + 8]) + ",")
        return 0
    allowed = set(PAL.values())
    bad = 0
    names = sorted(n for n in os.listdir(SLIDES) if n.endswith(".png"))
    for name in names:
        w, h, px, _ = read_png(os.path.join(SLIDES, name))
        strange = sum(1 for row in px for p in row if (p[0], p[1], p[2]) not in allowed or p[3] != 255)
        colours = len(set((p[0], p[1], p[2]) for row in px for p in row))
        size_ok = (w, h) == (320, 160)
        print("%-24s %dx%d  %3d colours  %s" % (name, w, h, colours,
                                                 "ok" if not strange and size_ok else "%d strange pixels" % strange))
        if strange or not size_ok:
            bad += 1
    if bad:
        print("FAIL: %d picture(s) are not palette art" % bad)
        return 1
    print("all %d pictures are palette art" % len(names))
    return 0


if __name__ == "__main__":
    sys.exit(main())
