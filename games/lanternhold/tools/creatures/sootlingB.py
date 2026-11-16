"""Sootling B, the runt (POLISH.md section 7, build 3; step 7, the director's calls of 16.11.2026 11:43 and 12:02;
step 8, his calls G1 to G3 of 13:38): the walker's smaller sibling, the same child of the Ash Giant at 10 px: a hunched
navy shroud on two stilt arms one pixel wide, no hind legs, the frayed hem dragging behind, open air under the belly.
Its back takes the walker's ramp (G2): the apex over columns 4 and 5, the rear columns two and three rows lower, the
two by two head hung a row under the hump's front edge, with one cold eye point; never a level lid. The top of the
hump is cold (nightHaze); a scrap of the giant's cloth hangs under it in moor with soilDark beside (G3).
The gait (G1): the arms plant half a cycle apart, each for three frames, at columns 10, 7 and 4 (the runt's stride,
3 px, back per frame); the hump bobs a row (top row 5 at the plant and the end of the haul, 4 upright); the hem drags
back (columns 2, 1, 0). 6 the climb, 7 the strike (the arms in a V), as the walker's (hordekit.py `step8`)."""
from hordekit import step8

SIZE = (14, 14, 8)
HEIGHT = 10
RUNT = dict(
    sil=dict(
        #      0123456789abcd
        P=["..............",   # the plant: the hump at its lowest, the hem at column 2
           "..............",
           "..............",
           "..............",
           "..............",
           "....##........",
           "...####.......",
           "..#####SB.....",
           "..#####BE.....",
           "..###.........",
           "..###.........",
           "..##..........",
           ".l##..........",
           "..##.........."],
        U=["..............",   # upright: the hump at its highest, the hem at column 1
           "..............",
           "..............",
           "..............",
           "....##........",
           "...####.......",
           "..#####SB.....",
           ".######BE.....",
           ".#####........",
           ".###..........",
           ".##...........",
           ".#............",
           "l#............",
           ".##..........."],
        E=["..............",   # the end of the haul: the hem dragged back to column 0
           "..............",
           "..............",
           "..............",
           "..............",
           "....##........",
           "...####.......",
           "..#####SB.....",
           ".######BE.....",
           "##............",
           "#.............",
           "#.............",
           "#.............",
           "#............."],
    ),
    shoulder=dict(P=(7, 7), U=(7, 6), E=(7, 7)),
    plant=[(10, 13), (7, 13), (4, 13)],       # the planted tip: the stride (3 px) back per frame
    swing=[[(5, 10)], [(9, 10)], [(9, 11)]],
    climb=("P", [(10, 5), (11, 3), (11, 4)], [(10, 7), (11, 6)]),
    strike=("U", [(9, 3), (10, 2), (11, 3)], [(10, 13)]),
    depth=[2, 2, 3, 3, 3, 3, 2, 0, 0, 0, 0, 0, 0, 0],
    front=7,
    pattern="mmsB",
    seed=5,
)


def frame(k):
    return step8(RUNT, k)
