"""The small ones' fall (POLISH.md section 7, build 3): each body falls to soot in three frames, drawn from its own
walk frame 0 (hordekit.fall): the crawler on 0-2, the loper on 3-5, the tumbler on 6-8. The socket dims on the first
frame and goes out; the third is a low heap of ash that the engine fades out while the thread stands alone over it
and then goes with the wind (EntityFrames, BattleEffects `fall`)."""
import sootling
import sootlingB
import tumbler
from hordekit import fall

SIZE = (14, 14, 9)
FLOATS = True        # the heap's grains lift off the ground; nothing needs the bottom row
BODIES = [sootling, sootlingB, tumbler]


def frame(k):
    return fall(BODIES[k // 3].frame(0), k % 3, seed=11 + k)
