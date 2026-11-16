"""Sootling, the crawler (POLISH.md section 7, build 3): a low mound of soot that drags itself on two clawed forearms,
a scrap of the Ash Giant's cloak over its back. No legs: the rag's loose ends drag on the ground behind it. The back
is its highest point and pumps two pixels in the scuttle; the hooded head hangs low in front, the thread of smoke
rising from the rag's torn edge at the nape (sootThread.py). One socket in the hood's mouth with a cold point of light,
never two, never a face. It rears up to claw. 10 px high. (hordekit.py: the legend and the art direction.)"""
from hordekit import paint

SIZE = (14, 14, 6)
HEIGHT = 10
E = ".............."
F = [
    # crawl 0-3 at 3 px a frame: a claw plants ahead and is dragged back, the near arm (light) and the far arm (dark)
    # take turns; the back is high on 0 and 2 and sunk 2 px on 1 and 3 (the pump); the rag's loose ends drag behind.
    [E] * 5 + [".....RRRR.....",
               "...RRRRRRRQ...",
               "..RRRRRRRRRBB.",
               ".RRRRRRRRRRBBB",
               "2R.RRRRRbRBgnB",
               "1.R.RRbbbBgEeB",
               ".1..2.l..LBbb.",
               "..1...l....L..",
               "...3.ll.....LL"],
    [E] * 7 + ["....RRRRRR....",
               "..RRRRRRRRRQ..",
               ".RRRRRRRRRRBB.",
               "2.R.RRRbbBBgnB",
               ".1..1..l.LBgEe",
               "..1....l.L.bb.",
               "...3....LL...."],
    [E] * 5 + [".....RRRR.....",
               "...RRRRRRRQ...",
               "..RRRRRRRRRBB.",
               ".RRRRRRRRRRBBB",
               "1R.RRRRRbRBgnB",
               ".2R.RRbbbBgEeB",
               "..1.3.L..lBbb.",
               ".1.....L...l..",
               "3.....LL....ll"],
    [E] * 7 + ["....RRRRRR....",
               "..RRRRRRRRRQ..",
               ".RRRRRRRRRRBB.",
               "1.R.RRRbbBBgnB",
               ".2..3..L.lBgEe",
               "1......L.l.bb.",
               ".3......ll...."],
    # attack 4-5: the front rears and the claws rise ahead (never upright: the rag's hump stays the biggest mass);
    # then it strikes down, the head low again
    [E] * 4 + ["...........LL.",
               "..........L..L",
               "......RRRQBL..",
               "...RRRRRRRBBB.",
               ".RRRRRRRRRBgnB",
               "2R.RRRRRRbgEeB",
               "1.R.RRbbbbBbb.",
               ".1..2bbbb.l...",
               "..1....l..l...",
               "...3..ll.ll..."],
    [E] * 7 + ["....RRRRRR....",
               "..RRRRRRRRRQ..",
               ".RRRRRRRRRRBB.",
               "2.R.RRRbbBBgnB",
               ".1..1...LLBgEe",
               "..1.....L..L.L",
               "...3...L....L."],
]


def frame(k):
    return paint(F[k], seed=3, phase=(0, 1, 0, 1, 0, 1)[k], rise=1)
