#!/usr/bin/env python3
"""The prologue's lantern slides (panels lane, docs/lanes/panels.md; STORY.md section 8), painted in the game's own
look: 320 x 160 pixels each, palette colours only (tools/palette.txt; every slide ends in paint.finish, and saving
refuses any other colour), written to Resources/Slides/<name>.png. One slide per run (this Mac's heat rule), through
the director's art lock:

    bash <artlock.sh> python3 -I tools/slides/slideart.py slidePrologue1 [--preview <dir>]

Slides (critic look 1 of panels-1 answered in fix round 1):
  slidePrologue1      slide_wall.py    the Worldwall from high over the Gloom: the smoke and its creatures in front,
                                       the wall across the world, the cleft with the castle, the inner lands' lights
  slidePrologue2      slide_throat.py  into the Throat from our wall: rock in facets, the fog slit, three cold eyes
  slidePrologue3      slide_ride.py    Aldric rides out toward the dark Great Beacon, the twelve bearers behind him
  slidePrologue4Lord  slide_hall.py    the heir before the hearth takes up the house's lantern from Odile (HOUSE.md 1)
  slidePrologue4Lady  slide_hall.py    the same with the Burgherrin
Check every picture afterwards: python3 -I tools/slides/slidecheck.py (fails on any colour outside the palette).
Deterministic: the same run paints the same slide, byte for byte.
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from paint import GAME  # noqa: E402
import slide_gutter  # noqa: E402
import slide_hall  # noqa: E402
import slide_open  # noqa: E402
import slide_open1  # noqa: E402
import slide_ride  # noqa: E402
import slide_shut  # noqa: E402
import slide_throat  # noqa: E402
import slide_town  # noqa: E402
import slide_wall  # noqa: E402

OUT = os.path.join(GAME, "Resources", "Slides")

SLIDES = {"slidePrologue1": slide_wall.slide1, "slidePrologue2": slide_throat.slide2,
          "slidePrologue3": slide_ride.slide3,
          "slidePrologue4Lord": lambda: slide_hall.slide4("lord"),
          "slidePrologue4Lady": lambda: slide_hall.slide4("lady")}
# The endings (panels-2): slide_open.py, slide_shut.py, slide_gutter.py, three slides each (two of them twice, for the
# lord and the lady).
for _module in (slide_open, slide_open1, slide_shut, slide_gutter, slide_town):
    SLIDES.update(_module.SLIDES)


def main():
    name = sys.argv[1]
    preview = None
    if "--preview" in sys.argv:
        preview = sys.argv[sys.argv.index("--preview") + 1]
    canvas = SLIDES[name]()
    if "--preview-only" not in sys.argv:
        os.makedirs(OUT, exist_ok=True)
        canvas.save(os.path.join(OUT, name + ".png"))
    if preview:
        os.makedirs(preview, exist_ok=True)
        canvas.save_preview(os.path.join(preview, name + ".png"), 3)
    print(name, "written")


if __name__ == "__main__":
    main()
