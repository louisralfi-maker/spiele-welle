"""Sootling B, the runt (POLISH.md section 7, build 3; step 7, the director's calls of 16.11.2026 11:43 and 12:02): the
walker's smaller sibling, the same child of the Ash Giant at 10 px: a hunched navy shroud on two stilt arms one pixel
wide, as long as the body is tall, no hind legs, the frayed hem dragging behind, open air under the belly. Its head is
two by two, hung low in front, with one cold eye point. A scrap of the giant's cloth on its hump (soilDark, moorDark,
its top catching the moon), 8 pixels. The same eight frames as the walker (walk 0 ... 5: reach, plant, haul, over,
drop, gather; 6 climb; 7 strike); its hump bobs a pixel (hordekit.py `kin`, `LEGEND`)."""
from hordekit import kin

SIZE = (14, 14, 8)
HEIGHT = 10
RUNT = dict(
    hump=[".mm.",
          "msrS",
          "ssBB",
          "rDBB"],
    skirt=[(0, 1), (0, 0)],
    head=["SB",
          "BE"],
    head_at=(4, 2),
    shoulder=(3, 1),
    seed=5,
    poses=[
        dict(at=(3, 5), near=[(9, 9), (9, 12)], far=[(7, 9), (7, 13)]),          # 0 reach
        dict(at=(3, 5), near=[(9, 9), (9, 13)], far=[(7, 10), (7, 13)]),         # 1 plant
        dict(at=(4, 4), near=[(10, 8), (10, 13)], far=[(8, 8), (8, 13)]),        # 2 haul
        dict(at=(4, 4), near=[(10, 7), (10, 13)], far=[(8, 7), (8, 13)]),        # 3 over
        dict(at=(4, 4), near=[(10, 8), (10, 11)], far=[(8, 9), (8, 13)]),        # 4 drop
        dict(at=(3, 5), near=[(9, 9), (9, 11)], far=[(7, 10), (7, 13)]),         # 5 gather
        dict(at=(4, 5), near=[(9, 5), (10, 4)], far=[(8, 6), (10, 6)]),          # 6 climb
        dict(at=(4, 4), near=[(9, 2), (10, 1)], far=[(8, 3), (9, 2)]),           # 7 strike
    ],
)


def frame(k):
    return kin(RUNT, k)
