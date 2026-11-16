"""The smoke thread's second curl (curl 1), a strip of its own beside sootThread.py (curl 0) and sootThreadC.py (curl 2):
the same frames, ((length index) × 9 + lean + 4) × 2 + sway, 144 of them. See sootThread.py."""
import sootThread

CURL = 1
SIZE = sootThread.SIZE
GLOW = False
FLOATS = True


def frame(k):
    return sootThread.frame(CURL * sootThread.PER_CURL + k)
