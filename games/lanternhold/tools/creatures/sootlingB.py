"""Sootling B, the loper (POLISH.md section 7, build 3; step 4, the director's calls of 16.11.2026 06:15): a hunched
heap of soot that hauls itself along on one arm grown far too long, two pixels thick, its hand planted far ahead like
a crutch, and the body is dragged and vaulted over it; behind, one short folded leg. A scrap of the Ash Giant's cloak
that learned to walk: over the hump a short mantle of his cloak (as it is in his shadow), and from it two tails of it
hang down and back past the rump, two pixels wide and a pixel apart, their ends torn, so the rear at 1x is a fringe.
The head hangs in front below the hump behind a one-pixel dip at the neck (kept open: the pixels on either side of it
carry no outline), the one cold point in it, never two, never a face. It crawls, it never perches, it never stands;
its arm never closes into a loop: thrown forward at shoulder height at the top of its stride (step 5: never over the
head, which read as a crook), the hand points ahead and down. To
strike it lunges: the body thrown forward and down, the arm thrown out low and straight ahead with the hand in the
ground, the tails flying back; with the arm reaching up and ahead it climbs a heap. 11 px high at the top of its
vault (step 5: 14 while the arm rose over the head). (hordekit.py `LEGEND`: the pixels.)"""
from hordekit import draw, place, limbs, uncap

SIZE = (14, 14, 6)
HEIGHT = 11
# the torso: the peak of the mantle, the mantle over the hump, the two tails hanging behind it (bare cloth, no outline,
# their torn ends the deepest soot), the rump and the flank, the dip at the neck (column 8) and the head hanging low
# in front under the shoulder; the long arm's shoulder at (6, 2) of the block, the hip at (5, 5), the socket at (10, 4)
TORSO = ["...mq......",
         ".2113Mh....",
         "13.13lBh...",
         "13.13lDL.hM",
         "k..k.lDL.LE",
         ".....lDDLLe"]
# the lunge: the tails stream back level, flung by the throw
LUNGE = ["...mq......",
         "1313.Mh....",
         "k113klBh...",
         "....klDL.hM",
         ".....lDL.LE",
         ".....lDDLLe"]
SHOULDER = (6, 2)
HIP = (5, 5)
# per frame: the torso's offset; the arm (shoulder, elbow, wrist) two pixels thick; the hand (wrist, knuckle, tip),
# pointing ahead or down, never back over the arm; the leg (hip, knee, foot)
POSE = [
    # walk 0-3 at 4 px a frame, the belly off the ground all the way: the hand plants far ahead (0), the body is hauled
    # up to it (1) and vaulted over it (2) while the arm pushes back under the shoulder, then the arm is thrown up over
    # the head and ahead (3, the top of the stride), the hand pointing ahead and down to plant again
    dict(at=(0, 4), torso=TORSO, elbow=(10, 8), wrist=(12, 11), hand=[(12, 11), (13, 13), (12, 13)],
         leg=[(4, 11), (3, 13)]),
    dict(at=(1, 4), torso=TORSO, elbow=(11, 8), wrist=(12, 11), hand=[(12, 11), (12, 13), (13, 13)],
         leg=[(5, 11), (4, 13)]),
    dict(at=(2, 3), torso=TORSO, elbow=(11, 8), wrist=(10, 11), hand=[(10, 11), (10, 13), (11, 13)],
         leg=[(6, 10), (5, 12), (4, 13)]),
    # (step 5, the critic's M2: thrown over the head the hand bent down read as a crook, the staff Louis rejected: the
    # throw goes forward at shoulder height, the wrist no higher than the mantle's peak, the hand pointing down)
    dict(at=(1, 4), torso=TORSO, elbow=(9, 5), wrist=(12, 4), hand=[(12, 4), (13, 5)],
         leg=[(5, 11), (4, 13)]),
    # attack 4: the gather before the lunge, the body drawn back and low, the arm reaching up and ahead (also its climb
    # on a heap: the hand stands clear over its back), the tails hanging
    dict(at=(0, 5), torso=TORSO, elbow=(9, 4), wrist=(12, 2), hand=[(12, 2), (13, 1), (13, 3)],
         leg=[(4, 12), (3, 13)]),
    # attack 5: the lunge, the body thrown forward and down, the arm thrown out low and straight ahead, the hand in
    # the ground, the tails flying back
    dict(at=(2, 6), torso=LUNGE, elbow=(11, 10), wrist=(13, 11), hand=[(13, 11), (13, 13), (12, 13)],
         leg=[(5, 12), (2, 13)]),
]


def frame(k):
    p = POSE[k]
    ox, oy = p["at"]
    f = draw(place(p["torso"], ox, oy), seed=5)
    sh = (SHOULDER[0] + ox, SHOULDER[1] + oy)
    hip = (HIP[0] + ox, HIP[1] + oy)
    el, wr = p["elbow"], p["wrist"]
    limbs(f, [([hip] + p["leg"], "l")])                                 # the short folded leg
    # the long arm over everything but the socket, two pixels thick: its shaded half under its lit half
    limbs(f, [([(sh[0], sh[1] + 1), (el[0] - 1, el[1] + 1), (wr[0] - 1, wr[1])], "l"),
              ([sh, el, wr], "L"), (p["hand"][:2], "k")], over=True)
    # uncap again at the end, twice: the head's side outline stands two pixels high beside the socket, and with the
    # arm drawn under it the lower one would cap the arm
    return uncap(uncap(limbs(f, [(p["hand"][1:], "a")], over=True)))
