"""The small ones' fall (POLISH.md section 7, build 3): each body falls to soot in three frames of 0.15 s, drawn from
its own walk frame 0: the walker (sootling.py) on 0-2, the runt (sootlingB.py) on 3-5, the tumbler on 6-8. Step 7 (the
director's call 4 of 16.11.2026 12:02): drawn from the ash giant's children, the shroud folds down over the stilt arms
and the cloth on the hump sinks with it. Step 5 (the director's call 4 of
16.11.2026 08:52, a kill reads at phone size; hordekit.slump): it slumps (0.8 of its height, the socket flaring), sags
to just over half its height with the cold point sunk in it (0.15 s), and lies as a low heap with the point faint near
the ground, which the engine puts out by 0.45 s and then fades the heap; the grey flakes lift off it (sootFlake.py).
Step 4's frames (hordekit.fall) went flat at once: at 0.15 s a smear one row high."""
import sootling
import sootlingB
import tumbler
from hordekit import slump

SIZE = (14, 14, 9)
BODIES = [sootling, sootlingB, tumbler]


def frame(k):
    return slump(BODIES[k // 3].frame(0), k % 3, seed=11 + k)
