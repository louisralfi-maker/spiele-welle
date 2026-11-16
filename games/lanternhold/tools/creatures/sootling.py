"""Sootling, the crawler (POLISH.md section 7, build 3; step 4, the director's calls of 16.11.2026 06:15): a small
hunched thing of soot on four spindly legs, a scrap of the Ash Giant's cloak that learned to walk. The body is the
shadow and the cloth only the accent: over the shoulders a short mantle of the giant's cloak (as it is in his shadow),
and from it two tails of it hang down and back past the rump, two pixels wide, five and three long, a pixel apart,
their ends torn to a single pixel, so the rear at 1x is a fringe like the hem of the giant's cloak. The back rises
highest over the mantle; the head juts forward below it behind a one-pixel dip at the neck (kept open: the pixels on
either side of it carry no outline), the one cold point in it, never two, never a face. Between the thin legs the
ground shows under the belly. The back pumps a pixel in the scuttle (its peak sinks, the belly stays off the ground);
the near legs and the far legs take turns. It rears with a fore claw two pixels thick reaching up and ahead, three
pixels over its back (also its pose when it climbs a heap: the claw stands clear of the heap's outline), and strikes
down. 10 px high. (hordekit.py `LEGEND`: the pixels.)"""
from hordekit import draw

SIZE = (14, 14, 6)
HEIGHT = 10
E = ".............."
F = [
    # walk 0: the back high, the near hind leg pushing back, the near fore leg reaching ahead
    [E, E, E, E,
     ".....mq.......",
     "...113SMh.....",
     ".13.13.lBh....",
     ".13.13.lBL.hM.",
     "13..k..lDSLLE.",
     "k......lDD.Le.",
     ".......l..ll..",
     "......l...l.l.",
     ".....l...l...l",
     "....l....l...l"],
    # walk 1: the peak sunk a pixel (the pump), the belly as high, the legs passing under it
    [E, E, E, E, E,
     "..213mqMh.....",
     ".13.13.lBh....",
     ".13.13.lBL.hM.",
     "13..k..lDSLLE.",
     "k......lDD.Le.",
     ".......l.l.l..",
     "......l..l..l.",
     "......l..l..l.",
     ".....l...l...l"],
    # walk 2: high, the far legs reaching, the near ones drawn under; the long tail swung back a pixel
    [E, E, E, E,
     ".....mq.......",
     "...113SMh.....",
     ".13.13.lBh....",
     "13..13.lBL.hM.",
     "k...k..lDSLLE.",
     ".......lDD.Le.",
     "........l.l.l.",
     "........l.l..l",
     ".......l..l...",
     ".......l...l.."],
    # walk 3: the peak sunk, the legs passing under it the other way
    [E, E, E, E, E,
     "..213mqMh.....",
     ".13.13.lBh....",
     ".13.13.lBL.hM.",
     "13..k..lDSLLE.",
     "k......lDD.Le.",
     "......l...ll..",
     ".....l....l.l.",
     ".....l....l.l.",
     "....l.....l..l"],
    # attack 4: it rears, the head up a row, a fore claw two pixels thick reaching up and ahead over its back, the
    # tails hanging (also its climb on a heap: the claw stands three pixels clear of its back)
    [E,
     "...........kk.",
     "..........LL.k",
     ".........LL...",
     ".....mq.LL....",
     "...113SMh.....",
     ".13.13.lBh.hM.",
     ".13.13.lBSLLE.",
     "13..k..lDB.Le.",
     "k......lDD....",
     "......l..l....",
     "......l..l....",
     ".....l...l....",
     "....l....l...."],
    # attack 5: it strikes down, the head low, the claws hooked on the ground ahead, the tails flung back
    [E, E, E, E, E,
     ".....mq.......",
     "2131313MM.....",
     "k.k.k.lBBBMh..",
     "......lDBBSLL.",
     "......lDDBBLE.",
     ".......DD..Le.",
     "......l..l..lk",
     ".....l...l...k",
     "....l....l..kk"],
]


def frame(k):
    return draw(F[k], seed=3)
