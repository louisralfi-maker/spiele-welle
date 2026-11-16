"""The small ones' soot flakes (POLISH.md section 7, build 3; step 3, the director's call 6: a kill never throws up a
V): the puff of a fall is a few grey flakes, one or two pixels, round or ragged, that lift off the body, drift apart
and thin to nothing by 0.8 s (EntityFrames `effectParticles`, `HordeLook.puffFlakes`). Grey, never black; no flake
wider or higher than two pixels. Step 5 (the director's call 4 of 16.11.2026 08:52, a kill reads at phone size):
each flake has one pixel a step darker at its core, so by the fires it stands as grey soot against the orange ground
(the engine takes the fire's hue out of it). Frames: 0 a grain of two, 1 a ragged three, 2 a round clump of four."""
from rig import Frame

SIZE = (3, 3, 3)
GLOW = False
FLOATS = True
SHAPES = [
    [(1, 1, "stone"), (1, 2, "stoneDark")],
    [(1, 1, "stone"), (2, 1, "stoneMid"), (1, 2, "stoneDark")],
    [(1, 1, "stone"), (2, 1, "stone"), (1, 2, "stoneMid"), (2, 2, "stoneDark")],
]


def frame(k):
    f = Frame(3, 3, seed=17)
    for x, y, c in SHAPES[k]:
        f.put(x, y, c, None, True)
    return f
