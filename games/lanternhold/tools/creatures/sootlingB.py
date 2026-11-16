"""Sootling B, the loper (POLISH.md section 7, build 3; step 3, the director's calls of 16.11.2026 04:10): a hunched
heap of soot that hauls itself along on one arm grown far too long, two pixels thick, a hooked hand at its end that
plants far ahead like a crutch, and the body is dragged and vaulted over it; behind, one short folded leg. The body is
the shadow and the rag only the accent: a short mantle of the Ash Giant's cloak (as it is in his shadow) on the
shoulders, the arm's root, and two strips of it trailing past the rump, each of its own length, their ends torn. The
head hangs in front below the hump, the one cold point in it, never two, never a face. It crawls, it never perches,
it never stands. It swings the long arm over its back and down to strike; with the arm reaching up it climbs a heap.
14 px high at the top of the arm's arch. (hordekit.py `LEGEND`: the pixels.)"""
from hordekit import draw, place, limbs

SIZE = (14, 14, 6)
HEIGHT = 14
# the torso: the mantle on the hump, the strips behind, the head hanging low in front under the shoulder; the long
# arm's shoulder at (6, 1) of the block, the hip at (4, 5)
TORSO = ["...mq.....",
         ".mmsrMM...",
         "ms.rDBBB..",
         "s..rDBBSM.",
         "3...DDBSE.",
         "....DDD.e."]
SHOULDER = (6, 1)
HIP = (4, 5)
# per frame: the torso's offset; the arm (shoulder, elbow, wrist) two pixels thick, a strut ahead of the face, never a
# frame round it; the hook (wrist, knuckle, claw tip); the leg (hip, knee, foot); the strips' torn ends trailing behind
POSE = [
    # walk 0-3 at 4 px a frame, the belly off the ground all the way: the hook plants far ahead (0), the body is hauled
    # up to it (1) and vaulted over it (2) while the arm pushes back under the shoulder, then the arm is flung up over
    # the head and forward in an arch (3, the top of the cycle) to plant again
    dict(at=(1, 4), elbow=(10, 6), wrist=(13, 11), hook=[(13, 11), (13, 13), (12, 13)],
         leg=[(5, 11), (4, 13)], tail=[(1, 9), (0, 11)], tail2=[(1, 7), (-1, 9)]),
    dict(at=(2, 4), elbow=(11, 6), wrist=(12, 11), hook=[(12, 11), (12, 13), (13, 13)],
         leg=[(6, 11), (5, 13)], tail=[(2, 9), (0, 10)], tail2=[(2, 7), (0, 8)]),
    dict(at=(3, 3), elbow=(11, 7), wrist=(10, 11), hook=[(10, 11), (10, 13), (11, 13)],
         leg=[(6, 10), (5, 12), (4, 13)], tail=[(3, 8), (0, 9)], tail2=[(3, 6), (1, 6)]),
    dict(at=(2, 4), elbow=(11, 0), wrist=(13, 2), hook=[(13, 2), (13, 4), (12, 5)],
         leg=[(6, 11), (5, 13)], tail=[(2, 9), (-1, 11)], tail2=[(2, 7), (0, 7)]),
    # attack 4: the long arm reaching up and ahead (its strike's wind-up, and its climb on a heap), the strips hanging
    dict(at=(1, 5), elbow=(11, 5), wrist=(13, 2), hook=[(13, 2), (12, 1), (11, 1)],
         leg=[(5, 12), (4, 13)], tail=[(1, 10), (0, 12)], tail2=[(1, 8), (0, 9)]),
    # attack 5: whipped down in front, the hook in the ground
    dict(at=(1, 5), elbow=(11, 8), wrist=(13, 12), hook=[(13, 12), (12, 13), (11, 13)],
         leg=[(5, 12), (3, 13)], tail=[(1, 10), (-1, 12)], tail2=[(1, 8), (-1, 9)]),
]

def frame(k):
    p = POSE[k]
    ox, oy = p["at"]
    f = draw(place(TORSO, ox, oy), seed=5)
    sh = (SHOULDER[0] + ox, SHOULDER[1] + oy)
    hip = (HIP[0] + ox, HIP[1] + oy)
    el, wr = p["elbow"], p["wrist"]
    limbs(f, [
        ([hip] + p["leg"], "l"),                                       # the short folded leg
        (p["tail"], "r"), (p["tail2"], "c"),                            # the strips' torn ends trailing behind
    ])
    # the long arm over everything but the socket, two pixels thick: its shaded half under its lit half
    limbs(f, [([(sh[0], sh[1] + 1), (el[0] - 1, el[1] + 1), (wr[0] - 1, wr[1])], "l"),
              ([sh, el, wr], "L"), (p["hook"][:2], "k")], over=True)
    return limbs(f, [(p["hook"][1:], "a")], over=True)
