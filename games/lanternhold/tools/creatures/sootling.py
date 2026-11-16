"""Sootling, the crawler (POLISH.md section 7, build 3; step 3, the director's calls of 16.11.2026 04:10): a small
hunched thing of soot on four spindly legs, the body the shadow and the rag only the accent. Its back rises highest
over the shoulders; the head juts forward below it, the one cold point in it, never two, never a face. A short mantle
of the Ash Giant's cloak (as it is in his shadow) lies on its shoulders, and two strips of it trail behind past its
rump, each of its own length, their ends torn. Between the thin legs the ground shows under the belly. The back pumps a
pixel in the scuttle (the hump; the belly stays off the ground); the near legs and the far legs take turns. It rears with a fore claw reaching up (also its pose
when it climbs a heap) and strikes down. 10 px high. (hordekit.py `LEGEND`: the pixels.)"""
from hordekit import draw

SIZE = (14, 14, 6)
HEIGHT = 10
E = ".............."
F = [
    # walk 0: the back high, the near hind leg pushing back, the near fore leg reaching ahead
    [E, E, E, E,
     ".......mq.....",
     ".....mmsrM....",
     "..2ms.rDBBM...",
     ".1.s..rDBBSMM.",
     "1..3..DDBBSBE.",
     "......l.DD.De.",
     "......l..ll...",
     ".....l...l.l..",
     "....l...l...l.",
     "...l....l...l."],
    # walk 1: the hump sunk a pixel (the pump), the belly as high, the legs passing under it
    [E, E, E, E, E,
     ".....mmqrM....",
     ".2.ms.rDBBM...",
     "2..s..rDBBSMM.",
     ".1.1..DDBBSBE.",
     "......l.DD.De.",
     "......l.l.l...",
     ".....l..l..l..",
     ".....l..l..l..",
     "....l...l...l."],
    # walk 2: high, the far legs reaching, the near ones drawn under
    [E, E, E, E,
     ".......mq.....",
     ".....mmsrM....",
     ".2.ms.rDBBM...",
     "2..s..rDBBSMM.",
     ".1.1..DDBBSBE.",
     "1.....l.DD.De.",
     ".......l.l.l..",
     ".......l.l..l.",
     "......l..l...l",
     "......l...l..l"],
    # walk 3: the hump sunk, the legs passing under it the other way
    [E, E, E, E, E,
     ".....mmqrM....",
     "..2ms.rDBBM...",
     ".1.s..rDBBSMM.",
     "1..3..DDBBSBE.",
     "......l.DD.De.",
     ".....l...ll...",
     "....l....l.l..",
     "....l....l.l..",
     "...l.....l..l."],
    # attack 4: it rears, a fore claw reaching up and ahead, the strips hanging down (also its climb on a heap)
    [E, E,
     "............Lk",
     "...........L.k",
     ".......mq.l...",
     ".....mmsrMB...",
     "...2ms.rDBBSM.",
     "..1s..rDBBBSE.",
     "..3...DDBBDBe.",
     "......l.DD.n..",
     ".....l..l.....",
     ".....l..l.....",
     "....l...l.....",
     "...l....l....."],
    # attack 5: it strikes down, the head low, the claws hooked on the ground ahead
    [E, E, E, E, E,
     ".......mq.....",
     "..2..mmsrM....",
     ".1.ms.rDBBBMM.",
     "1..s..rDDBBSB.",
     "...3..DDDBBBE.",
     "......l.DD.De.",
     ".....l...l..lk",
     "....l....l...k",
     "...l.....l..kk"],
]


def frame(k):
    return draw(F[k], seed=3)
