"""The small ones as a horde (POLISH.md section 7, build 3 lane 4 step A): the shared kit of the three bodies
(sootling.py the crawler, sootlingB.py the loper, tumbler.py the tumbler), their fall (sootFall.py) and the smoke
thread (sootThread.py). Each body is a hand-set grid of 14 x 14, one character per pixel, drawn by rig.Frame with the
creatures' 1 px outline and no warm rim: the small ones are smoke and soot, and their only light is the socket's cold
point (two pixels with a faint halo, so it reads at phone size). Warm light is the castle's.

Legend:
  .  empty            n  nightDeep (hollows, the hood's mouth)   k  night0 (shade)
  h  nightBlue (mid)  H  nightSlate (the light from above)       P  nightSlate: the hood's torn peak, where the
  r  moorDark rag     R  moor rag (lit edge)                        thread rises (exactly one per frame)
  a  stoneDark ash    s  stoneMid ash                            w  smoke: nightBlue, no outline
  W  smoke: nightSlate, no outline
  l  a thin limb in shade: night0, no outline   L  a thin limb: nightBlue, no outline (an outline would fill the gaps
                                                   between limbs one pixel apart and blur the gait into a blob)
  E  the socket's core (stoneLight, glow wraithWhite)            e  its second pixel (stoneMid, glow wraithGlow)
  g  a body pixel round the socket that glows faintly (nightSlate, glow wraithDim)
"""
from rig import Frame, hsh

LEGEND = {"n": "nightDeep", "k": "night0", "h": "nightBlue", "H": "nightSlate", "P": "nightSlate",
          "r": "moorDark", "R": "moor", "a": "stoneDark", "s": "stoneMid",
          "E": ("stoneLight", "wraithWhite"), "e": ("stoneMid", "wraithGlow"), "g": ("nightSlate", "wraithDim")}
SMOKE = {"w": "nightBlue", "W": "nightSlate", "l": "night0", "L": "nightBlue"}
CELL = 14


def check(rows):
    assert len(rows) == CELL and all(len(r) == CELL for r in rows), [len(r) for r in rows]


def peak(rows):
    """The hood's peak (column, row) of a grid: where the smoke thread rises."""
    check(rows)
    found = [(x, y) for y, r in enumerate(rows) for x, ch in enumerate(r) if ch == "P"]
    assert len(found) == 1, found
    return found[0]


def socket(rows):
    found = [(x, y) for y, r in enumerate(rows) for x, ch in enumerate(r) if ch == "E"]
    return found[0] if found else None


def paint(rows, seed=0):
    """A body grid as a finished frame: the 1 px outline, no rim."""
    check(rows)
    f = Frame(CELL, CELL, seed)
    for y, r in enumerate(rows):
        for x, ch in enumerate(r):
            if ch == ".":
                continue
            if ch in SMOKE:
                f.put(x, y, SMOKE[ch], None, True)
                continue
            v = LEGEND[ch]
            if isinstance(v, tuple):
                f.put(x, y, v[0], v[1])
            else:
                f.put(x, y, v)
    return f.finish(rim=None)


def top(rows):
    """The first row with a body pixel (the outline sits one row above it)."""
    check(rows)
    return min(y for y, r in enumerate(rows) if r.strip("."))


GRAIN = ["stoneDark", "stoneMid", "nightSlate"]
ASHEN = ["stoneDark", "night0", "nightBlue"]


def fall(src, k, seed):
    """Fall frame k (0 ... 2) of a finished body frame (its walk frame 0): it sags into soot. Each column is squashed
    toward the ground to 60, 32 and 14 % of its height (its pixels sampled evenly, so the shape folds down rather
    than sinks); the socket dims on 0 and is out from 1; the top of the heap turns to ash; grains lift off it."""
    keep = (0.6, 0.32, 0.14)[k]
    f = Frame(CELL, CELL, seed)
    for x in range(CELL):
        col = [(src.b[y][x], src.g[y][x]) for y in range(CELL) if src.b[y][x] is not None]
        if not col:
            continue
        if k >= 1 and len(col) < 4:
            continue                                         # the thin limbs and the rim go first
        n = max(1, int(round(len(col) * keep)))
        if k == 2:                                           # a smear of soot with a ragged top
            if hsh(x, 3, seed) < 0.18:
                continue
            n = 1 + (hsh(x, 5, seed) > 0.55)
        for i in range(n):
            body, glow = col[min(len(col) - 1, int(i * len(col) / n))]
            y = CELL - n + i
            if glow is not None:
                if glow in ("wraithWhite", "wraithGlow") and k == 0:
                    f.put(x, y, "stoneMid", "wraithDim" if glow == "wraithWhite" else None)
                else:
                    f.put(x, y, "stoneDark" if glow in ("wraithWhite", "wraithGlow") else body)
                continue
            if k >= 1 and i == 0 and body != "nightDeep":
                body = ASHEN[(x + k) % 3]                    # the top of the heap turns to ash
            if k == 2:
                body = ("stoneDark", "night0", "nightDeep")[(x * 7 + y * 3) % 3]
            f.put(x, y, body)
    for i in range((2, 4, 5)[k]):                            # grains of ash lifting off, no outline
        gx = int(2 + hsh(i, k, seed) * 10)
        gy = int(CELL - 3 - (k + 1) * 2 - hsh(i, k + 7, seed) * 3)
        if 0 <= gy < CELL and not f.has(gx, gy):
            f.put(gx, gy, GRAIN[(i + k) % 3], None, True)
    return f


def place(block, dx, dy):
    """A body block (rows of characters) set into an empty 14 x 14 grid with its top-left at (dx, dy), clipped."""
    grid = [["."] * CELL for _ in range(CELL)]
    for j, row in enumerate(block):
        for i, ch in enumerate(row):
            x, y = dx + i, dy + j
            if ch != "." and 0 <= x < CELL and 0 <= y < CELL:
                grid[y][x] = ch
    return ["".join(r) for r in grid]


LIMB = {"l": "night0", "L": "nightBlue", "H": "nightSlate", "a": "stoneDark", "s": "stoneMid", "r": "moorDark"}


def limbs(f, segs):
    """Thin limbs over a finished frame, one pixel wide and without outline: [(points, char), ...], each a polyline
    in pixel coordinates."""
    for pts, ch in segs:
        for a, b in zip(pts, pts[1:]):
            n = int(max(abs(b[0] - a[0]), abs(b[1] - a[1])) + 0.5)
            for i in range(n + 1):
                t = i / n if n else 0
                x, y = round(a[0] + (b[0] - a[0]) * t), round(a[1] + (b[1] - a[1]) * t)
                if 0 <= x < CELL and 0 <= y < CELL and f.g[y][x] is None:   # never over the socket
                    f.put(x, y, LIMB[ch], None, True)
    return f
