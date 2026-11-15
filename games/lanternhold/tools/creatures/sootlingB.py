"""Sootling B, the loper (POLISH.md section 7, build 3): a hunched husk of soot that runs on one arm grown far too
long and one leg, the arm swung ahead like a crutch and the body vaulted over it. It never stands upright: the hump
of its back is its highest point, the hooded head hangs in front below it, the hood's torn peak at the nape where its
smoke thread rises (sootThread.py). A rag of peat-brown cloth trails from the hump. One socket with a cold point of
light. It swings the long arm over and down to strike. 14 px high at the top of the vault.
(ART-look2.md 14: no pale bare head, no smock, never two eyes, nothing of a child.)"""
from hordekit import paint, place, limbs

SIZE = (14, 14, 6)
HEIGHT = 14
# the torso: a hump bent like a hook, the head hanging low in front on the end of it; the long arm's shoulder is at
# (7, 4) of the block, the hip at (3, 5)
TORSO = ["...HHHP......",
         "..rHhhhH.....",
         ".rRhhhhhH....",
         "rr.khhhhhH...",
         "r..rkkhhhhH..",
         "r...rk.khhgH.",
         "........hgnEe",
         ".........hnn."]
# per frame: the torso's offset, the arm (shoulder, elbow, hand) and the leg (hip, knee, foot) in frame pixels
POSE = [
    # run 0-3 at 4 px a frame: the hand plants 12 px ahead and moves back 4 px a frame (12, 8), lifts and swings
    # over; the leg plants under the body (7) and pushes back (3) while the body vaults over the arm
    dict(at=(0, 3), arm=[(7, 8), (10, 10), (12, 13)], hand=[(11, 13), (13, 13)],
         leg=[(3, 9), (3, 11), (1, 13)], foot=[(0, 13), (1, 13)]),
    dict(at=(0, 1), arm=[(7, 6), (8, 9), (8, 13)], hand=[(7, 13), (9, 13)],
         leg=[(3, 7), (5, 9), (4, 11)], foot=[(4, 11), (5, 11)]),
    dict(at=(1, 2), arm=[(8, 7), (11, 6), (13, 4)], hand=[(13, 4), (13, 3)],
         leg=[(4, 8), (6, 11), (6, 13)], foot=[(5, 13), (7, 13)]),
    dict(at=(0, 2), arm=[(7, 8), (10, 10), (13, 11)], hand=[(13, 11), (13, 12)],
         leg=[(3, 8), (4, 11), (3, 13)], foot=[(2, 13), (4, 13)]),
    # attack 4-5: the long arm swung up behind and over the back; whipped down in front
    dict(at=(1, 4), arm=[(8, 8), (5, 3), (4, 0)], hand=[(4, 0), (3, 0)],
         leg=[(4, 10), (5, 12), (4, 13)], foot=[(3, 13), (5, 13)]),
    dict(at=(0, 4), arm=[(7, 8), (11, 9), (13, 13)], hand=[(12, 13), (13, 13)],
         leg=[(3, 10), (2, 12), (1, 13)], foot=[(0, 13), (1, 13)]),
]


def frame(k):
    p = POSE[k]
    f = paint(place(TORSO, *p["at"]), seed=5)
    return limbs(f, [(p["leg"], "l"), (p["foot"], "l"), (p["arm"], "L"), (p["hand"], "H")])
