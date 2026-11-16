"""Sootling, the walker (POLISH.md section 7, build 3; step 7, the director's calls of 16.11.2026 11:43 and 12:02;
step 8, his calls G1 to G6 of 13:38): the Ash Giant's child, his silhouette at a hand's height. A hunched shroud taller
than wide that lopes on two stilt arms, each a single pixel wide, from the shoulder at the front of the hump down to
the ground; no hind legs: the shroud's frayed hem drags behind on the ground, and between the hem and the arms the
ground shows under the belly, the giant's inverted V. The head, three pixels wide, hangs low in front of the shoulder,
with one cold eye point, never two, never a face. The top of the hump is cold (nightHaze); under it the giant's cloth
hangs down the back in two stripes of moor with soilDark between (G3). The back falls from the apex in a stair broken
by a flat run of two and a notch in the hem (G6).
The gait (G1): the arms plant half a cycle apart, each for three frames: planted at columns 12, 8 and 4 (the walker's
stride, 4 px, back per frame), so the tip stands still on the ground while the body travels; the swinging tip is lifted
and travels forward. The hump is lowest at the plant (top row 3), highest with the planted arm upright under it (row 1)
and between at the end of the haul (row 2); the hem drags back along the ground (columns 2, 1, 0) and catches up at
the next plant. 6 the climb: the arms up the wall ahead, the hands hooked over its top, the shroud hanging. 7 the
strike: reared, the arms parted in a V, the near one raised with its hook, the far one planted (G4). 13 px tall at
the top of the walk (hordekit.py `step8`, `LEGEND`)."""
from hordekit import step8

SIZE = (14, 14, 8)
HEIGHT = 13
WALKER = dict(
    sil=dict(
        #      0123456789abcd
        P=["..............",   # the plant: the hump at its lowest, the hem at column 2
           "..............",
           "..............",
           "......##......",
           ".....####.....",
           "....#####.....",
           "..#######.....",
           "..######SSB...",
           "..######.BE...",
           "..######......",
           "...###........",   # the hem's notch
           "..###.........",
           ".l###.........",
           "..####........"],
        U=["..............",   # upright: the hump at its highest, the hem at column 1
           ".....##.......",
           "....####......",
           "...#####......",
           ".#######......",
           ".#######SSB...",
           ".#######.BE...",
           ".######.......",
           ".####.........",
           ".###..........",
           "..#...........",   # the hem's notch
           ".##...........",
           "l##...........",
           ".###.........."],
        E=["..............",   # the end of the haul: the hem dragged back to column 0
           "..............",
           ".....##.......",
           "....####......",
           "...#####......",
           ".#######......",
           ".#######SSB...",
           "########.BE...",
           ".#####........",   # the hem's notch
           "#.............",
           "#.............",
           "#.............",
           "#.............",
           "#............."],
    ),
    shoulder=dict(P=(9, 6), U=(8, 4), E=(8, 5)),
    plant=[(12, 13), (8, 13), (4, 13)],       # the planted tip: the stride (4 px) back per frame
    swing=[[(6, 10)], [(10, 10)], [(10, 11)]],  # the swinging tip, lifted, travelling forward
    climb=("P", [(12, 4), (13, 2), (13, 3)], [(12, 6), (13, 5)]),
    strike=("U", [(11, 1), (12, 0), (13, 1)], [(12, 13)]),
    depth=[3, 4, 5, 4, 5, 5, 3, 2, 0, 0, 0, 0, 0, 0],
    front=8,
    pattern="mmsB",
    seed=7,
)


def frame(k):
    return step8(WALKER, k)
