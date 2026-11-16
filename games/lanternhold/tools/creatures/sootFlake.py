"""The small ones' soot flakes (POLISH.md section 7, build 3; step 3, the director's call 6: a kill never throws up a
V): the puff of a fall is a few grey flakes, one or two pixels, round or ragged, that lift off the body, drift apart
and thin to nothing by 0.8 s (EntityFrames `effectParticles`, `HordeLook.puffFlakes`). Grey, never black; no flake
wider or higher than two pixels. Frames: 0 a single grain, 1 a ragged pair, 2 a round clump of three."""
from rig import Frame

SIZE = (3, 3, 3)
GLOW = False
FLOATS = True
SHAPES = [
    [(1, 2, "stone")],
    [(1, 2, "stoneMid"), (2, 1, "stone")],
    [(1, 1, "stone"), (1, 2, "stoneMid"), (2, 2, "stone")],
]


def frame(k):
    f = Frame(3, 3, seed=17)
    for x, y, c in SHAPES[k]:
        f.put(x, y, c, None, True)
    return f
