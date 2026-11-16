"""The smoke thread's third curl (curl 2), a strip of its own beside sootThread.py (curl 0) and sootThreadB.py (curl 1):
the same frames, ((length index) × 9 + lean + 4) × 2 + sway, 90 of them. See sootThread.py."""
import sootThread

CURL = 2
SIZE = sootThread.SIZE
GLOW = False
FLOATS = True


def frame(k):
    return sootThread.frame(CURL * sootThread.PER_CURL + k)
