"""Sootling B, the loper (POLISH.md section 7, build 3): a hunched heap of soot under a scrap of the Ash Giant's cloak
that hauls itself along on one arm grown far too long: two pixels thick, a hooked hand at its end that plants far
ahead like a crutch, and the body is dragged and vaulted over it. The rear stays low on a short folded leg and the
rag's tail drags on the ground behind; it crawls, it never perches, it never stands. The hooded head hangs in front
below the hump, the thread of smoke rising from the rag's torn edge at the nape (sootThread.py). One socket with a
cold point of light, never two, never a face. It swings the long arm over its back and down to strike. 14 px high at
the top of the vault. (hordekit.py: the legend and the art direction.)"""
from hordekit import paint, place, limbs

SIZE = (14, 14, 6)
HEIGHT = 14
# the torso: a hump under the rag, the head hanging low in front of it below the shoulder; the long arm's shoulder is
# at (8, 2) of the block, the hip at (2, 5)
TORSO = ["...RRRQ...",
         ".RRRRRRRB.",
         "RRRRRRRRBB",
         "RRRRRRRbgB",
         "R.RRRbbgEe",
         ".R.R.bbBB.",
         "..R....bb."]
SHOULDER = (8, 2)
HIP = (2, 5)
# per frame: the torso's offset; the arm (shoulder, elbow, wrist) drawn two pixels thick, the hook (wrist, knuckle,
# claw tip); the leg (hip, knee, foot); the rag's two loose ends dragging behind
POSE = [
    # walk 0-3 at 4 px a frame, the body low all the way (it crawls): the hook plants far ahead (0), the body is hauled
    # up to it (1) and over it (2) while the arm pushes back under the shoulder, then the arm is flung up over the head
    # and forward in an arch (3, the top of the cycle) to plant again
    dict(at=(0, 5), elbow=(12, 7), wrist=(12, 12), hook=[(12, 12), (13, 13), (13, 12)],
         leg=[(4, 12), (2, 13)], tail=[(0, 10), (0, 13)], tail2=[(1, 11), (-1, 13)]),
    dict(at=(1, 4), elbow=(12, 7), wrist=(11, 12), hook=[(11, 12), (12, 13), (13, 13)],
         leg=[(5, 11), (4, 13)], tail=[(1, 9), (0, 13)], tail2=[(2, 10), (0, 12)]),
    dict(at=(2, 3), elbow=(11, 8), wrist=(9, 12), hook=[(9, 12), (10, 13), (11, 13)],
         leg=[(5, 11), (6, 12), (4, 13)], tail=[(2, 8), (0, 12)], tail2=[(3, 9), (1, 13)]),
    dict(at=(1, 4), elbow=(11, 0), wrist=(13, 5), hook=[(13, 5), (13, 7), (12, 8)],
         leg=[(5, 11), (3, 13)], tail=[(1, 9), (-1, 12)], tail2=[(2, 10), (1, 13)]),
    # attack 4-5: the long arm thrown up over the back, the hook high behind it; then whipped down in front
    dict(at=(1, 5), elbow=(8, 1), wrist=(5, 1), hook=[(5, 1), (4, 0), (3, 1)],
         leg=[(5, 12), (3, 13)], tail=[(1, 10), (-1, 13)], tail2=[(2, 11), (0, 13)]),
    dict(at=(1, 6), elbow=(13, 8), wrist=(13, 12), hook=[(13, 12), (12, 13), (11, 13)],
         leg=[(5, 12), (3, 13)], tail=[(1, 11), (-1, 13)], tail2=[(2, 12), (0, 13)]),
]


def frame(k):
    p = POSE[k]
    ox, oy = p["at"]
    f = paint(place(TORSO, ox, oy), seed=5, phase=k % 2, rise=1)
    sh = (SHOULDER[0] + ox, SHOULDER[1] + oy)
    hip = (HIP[0] + ox, HIP[1] + oy)
    el, wr = p["elbow"], p["wrist"]
    limbs(f, [
        ([hip] + p["leg"], "l"),                                       # the short folded leg
        (p["tail"], "r"), (p["tail2"], "c"),                            # the rag's tail dragging behind
    ])
    # the long arm over everything but the socket, two pixels thick: its shaded half under its lit half
    limbs(f, [([(sh[0], sh[1] + 1), (el[0] - 1, el[1] + 1), (wr[0] - 1, wr[1])], "L"),
              ([sh, el, wr], "H"), (p["hook"][:2], "a")], over=True)
    return limbs(f, [(p["hook"][1:], "s")], over=True)
