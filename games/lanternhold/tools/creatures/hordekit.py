"""The small ones as a horde (POLISH.md section 7, build 3 lane 4): the shared kit of the three bodies (sootling.py the
crawler, sootlingB.py the loper, tumbler.py the tumbler), their fall (sootFall.py) and the smoke thread (sootThread.py).

The art direction (the director, 16.11.2026): the small ones are scraps shed from the Ash Giant's cloak that learned
to walk. Every one wears a rag over its back in the giant's cloak tones (olive moor and ochre soilDark strips with
moorDark between, ashGiant.py's RAG), a third or more of its upper outline, in strips with loose ends, never a flat
patch; limbs and underside in the giant's navy (HUSK); a 1 px moon rim on the upper outline; one cold point (the
socket), never two, never a face. The rag is what lets a body read at night, as the giant's cloak does.

A body is a hand-set silhouette of 14 x 14, one character per pixel, shaded here: the navy by its depth in its column
(the topmost pixel takes the moon rim), the rag by strips that run down and back over it; the creatures' 1 px outline,
and no warm rim: the small ones are cold.

Silhouette legend:
  .  empty
  B  navy body, shaded by depth (top: the moon rim nightHaze, then nightSlate, nightBlue, the lowest night0)
  b  navy in shade (night0, the lowest nightDeep)
  R  rag, in strips (moor, soilDark, moorDark), its top pixel the moon rim
  n  nightDeep (a hollow: the hood's mouth)          k  night0          h  nightBlue          H  nightSlate
  P  the thread's root on navy (nightSlate)          Q  the thread's root on the rag (moorDark): exactly one P or Q
  E  the socket's core (stoneLight, glow wraithWhite)    e  its second pixel (stoneMid, glow wraithGlow)
  g  a body pixel by the socket that glows faintly (nightSlate, glow wraithDim)
  l  a thin limb in shade (night0, no outline)       L  a thin limb (nightBlue, no outline)
  1  a loose rag end (moorDark, no outline)          2  a loose end catching the moon (moor, no outline)
  3  a loose end in ochre (soilDark, no outline)
  w  smoke (nightBlue, no outline)                   W  smoke (nightSlate, no outline)
"""
from rig import Frame, hsh

CELL = 14
FIXED = {"n": "nightDeep", "k": "night0", "h": "nightBlue", "H": "nightSlate", "P": "nightSlate", "Q": "moorDark"}
GLOWING = {"E": ("stoneLight", "wraithWhite"), "e": ("stoneMid", "wraithGlow"), "g": ("nightSlate", "wraithDim")}
BARE = {"l": "night0", "L": "nightBlue", "1": "moorDark", "2": "moor", "3": "soilDark", "w": "nightBlue",
        "W": "nightSlate"}
# the rag's strips: two pixels of the light cloak tone, one of the dark, shifting one pixel back every `rise` rows, so
# they hang down and back over the body like the giant's cloak
STRIP_PERIOD = 3
MOON = "nightHaze"          # the moon rim on navy
MOON_RAG = "stone"          # and on the rag: a cool grey edge where the moon catches the cloth
BODY = set("BbRnkhHPQEeg")


def check(rows):
    assert len(rows) == CELL and all(len(r) == CELL for r in rows), [len(r) for r in rows]


def peak(rows):
    """The thread's root (column, row) of a grid: exactly one P or Q."""
    check(rows)
    found = [(x, y) for y, r in enumerate(rows) for x, ch in enumerate(r) if ch in "PQ"]
    assert len(found) == 1, found
    return found[0]


def socket(rows):
    found = [(x, y) for y, r in enumerate(rows) for x, ch in enumerate(r) if ch == "E"]
    return found[0] if found else None


def top(rows):
    """The first row with a body pixel (the outline sits one row above it)."""
    check(rows)
    return min(y for y, r in enumerate(rows) if any(ch in BODY for ch in r))


def strip(x, y, phase=0, rise=2):
    """True where (x, y) lies on a light strip of the rag (moor), False on a dark one (soilDark)."""
    return (x + y // rise + phase) % STRIP_PERIOD != STRIP_PERIOD - 1


def paint(rows, seed=0, phase=0, rise=2, finish=True):
    """A silhouette grid as a finished frame: the navy shaded by depth, the rag in strips (lit near its top, shaded
    toward its torn ends), the moon rim on the upper outline, the 1 px outline, no warm rim."""
    check(rows)
    f = Frame(CELL, CELL, seed)
    for x in range(CELL):
        col = [y for y in range(CELL) if rows[y][x] in BODY]
        first = col[0] if col else None
        last = col[-1] if col else None
        rag = [y for y in range(CELL) if rows[y][x] in "RQ"]
        for y in range(CELL):
            ch = rows[y][x]
            if ch == ".":
                continue
            if ch in BARE:
                f.put(x, y, BARE[ch], None, True)
            elif ch in GLOWING:
                f.put(x, y, *GLOWING[ch])
            elif ch in FIXED:
                f.put(x, y, FIXED[ch])
            elif ch == "R":
                depth = y - rag[0]
                tip = y + 1 >= CELL or rows[y + 1][x] not in "RQ"
                light = strip(x, y, phase, rise)
                if y == first:
                    c = MOON_RAG if light else "moor"              # the moon on its top edge, broken by the strips
                elif light:
                    c = "moorDark" if tip or depth > 3 else "moor"
                else:
                    c = "nightDeep" if tip and depth > 1 else "soilDark"
                f.put(x, y, c)
            elif ch in "Bb":
                depth = col.index(y)
                if ch == "b":
                    c = "nightDeep" if y == last else "night0"
                elif y == first:
                    c = MOON
                elif y == last:
                    c = "night0"
                elif depth == 1:
                    c = "nightSlate"
                else:
                    c = "nightBlue" if hsh(x, y, seed) > 0.18 else "nightSlate"
                f.put(x, y, c)
    return f.finish(rim=None) if finish else f


def place(block, dx, dy):
    """A block (rows of characters) set into an empty 14 x 14 grid with its top-left at (dx, dy), clipped."""
    grid = [["."] * CELL for _ in range(CELL)]
    for j, row in enumerate(block):
        for i, ch in enumerate(row):
            x, y = dx + i, dy + j
            if ch != "." and 0 <= x < CELL and 0 <= y < CELL:
                grid[y][x] = ch
    return ["".join(r) for r in grid]


LIMB = {"l": "night0", "L": "nightBlue", "H": "nightSlate", "a": "stoneDark", "s": "stoneMid", "r": "moorDark",
        "o": "moor", "c": "soilDark", "k": "night0", "m": MOON}


def limbs(f, segs, over=False):
    """Thin limbs (or loose rag ends) over a finished frame, one pixel wide and without outline: [(points, char), ...],
    each a polyline in pixel coordinates. Never over the socket; over the body only with `over`."""
    for pts, ch in segs:
        for a, b in zip(pts, pts[1:]):
            n = int(max(abs(b[0] - a[0]), abs(b[1] - a[1])) + 0.5)
            for i in range(n + 1):
                t = i / n if n else 0
                x, y = round(a[0] + (b[0] - a[0]) * t), round(a[1] + (b[1] - a[1]) * t)
                if 0 <= x < CELL and 0 <= y < CELL and f.g[y][x] is None and (over or f.b[y][x] is None
                                                                              or (x, y) in f.bare):
                    f.put(x, y, LIMB[ch], None, True)
    return f


def moon(f):
    """The moon rim over a finished frame: the topmost pixel of each column that is not outline, smoke or a loose end
    turns one step lighter (nightHaze on navy; the rag's dark strips take moor). Used after limbs are drawn."""
    for x in range(CELL):
        for y in range(CELL):
            c = f.b[y][x]
            if c is None or (x, y) in f.bare:
                continue
            if c == "nightDeep" and (y + 1 < CELL and f.b[y + 1][x] is not None and (x, y + 1) not in f.bare):
                continue                                    # the outline above the body
            if f.g[y][x] is None:
                if c in ("nightBlue", "nightSlate", "night0"):
                    f.b[y][x] = MOON
                elif c in ("moorDark", "soilDark"):
                    f.b[y][x] = MOON_RAG
            break
    return f


GRAIN = ["stoneDark", "stoneMid", "nightSlate"]


def fall(src, k, seed):
    """Fall frame k (0 ... 2) of a finished body frame (its walk frame 0): it sags into soot.
    0: each column squashed toward the ground to 60 % of its height (its pixels sampled evenly, so the shape folds
       down), the socket flaring: its core keeps the white glow (the engine doubles it for this frame, the wick's last
       spark), its rim lights up around it;
    1: squashed to 30 % in uneven columns, the socket out, the top of the heap ash, the rag's strips still on it, grains
       lifting off;
    2: two or three clumps of soot and rag on the ground, uneven (never a ruled row), and one spark that falls."""
    f = Frame(CELL, CELL, seed)
    cols = {}
    for x in range(CELL):
        col = [(src.b[y][x], src.g[y][x]) for y in range(CELL) if src.b[y][x] is not None]
        if col:
            cols[x] = col
    if k == 0:
        for x, col in cols.items():
            n = max(1, int(round(len(col) * 0.6)))
            for i in range(n):
                body, glow = col[min(len(col) - 1, int(i * len(col) / n))]
                y = CELL - n + i
                if glow == "wraithWhite":
                    f.put(x, y, "stoneLight", "wraithWhite")
                    for dx, dy in ((-1, 0), (1, 0), (0, -1)):
                        if f.has(x + dx, y + dy) and f.g[y + dy][x + dx] is None:
                            f.g[y + dy][x + dx] = "wraithGlow"
                elif glow is not None:
                    f.put(x, y, body, "wraithGlow")
                else:
                    f.put(x, y, body)
            eye = [j for j, (_, glow) in enumerate(col) if glow == "wraithWhite"]
            if eye and not any(f.g[yy][x] == "wraithWhite" for yy in range(CELL)):   # the sampling skipped it
                y = CELL - n + min(n - 1, int(eye[0] * n / len(col)))
                f.put(x, y, "stoneLight", "wraithWhite")
                for dx, dy in ((-1, 0), (1, 0), (0, -1)):
                    if f.has(x + dx, y + dy) and f.g[y + dy][x + dx] is None:
                        f.g[y + dy][x + dx] = "wraithGlow"
        return f.finish(rim=None)
    if k == 1:
        for x, col in cols.items():
            if len(col) < 3:
                continue                                      # the thin limbs and the loose ends go first
            keep = 0.22 + 0.2 * hsh(x // 2, 9, seed)          # uneven: the heap slumps in lumps
            n = max(1, int(round(len(col) * keep)))
            for i in range(n):
                body, glow = col[min(len(col) - 1, int(i * len(col) / n))]
                y = CELL - n + i
                if glow is not None:
                    body = "stoneDark"
                elif i == 0 and body in ("nightBlue", "nightSlate", "nightHaze", "night0"):
                    body = ("stoneDark", "stoneMid", "night0")[(x + seed) % 3]
                f.put(x, y, body)
        f.finish(rim=None)
        for i in range(4):                                    # grains lifting off, no outline
            gx = int(2 + hsh(i, 1, seed) * 10)
            gy = int(CELL - 6 - hsh(i, 8, seed) * 4)
            if 0 <= gy < CELL and not f.has(gx, gy):
                f.put(gx, gy, GRAIN[(i + seed) % 3], None, True)
        return f
    # k == 2: two or three clumps, each one or two pixels wide and high, at uneven gaps; one is a scrap of rag
    xs = sorted(cols)
    lo, hi = (xs[0], xs[-1]) if xs else (3, 10)
    count = 2 + (hsh(1, 2, seed) > 0.45)
    at = lo + 1 + int(hsh(3, 4, seed) * 2)
    for j in range(count):
        w = 1 + (hsh(j, 5, seed) > 0.4)
        h = 1 + (hsh(j, 6, seed) > 0.55)
        for dx in range(w):
            for dy in range(h):
                x, y = at + dx, CELL - 1 - dy
                if x <= hi + 1:
                    c = ("night0", "stoneDark", "nightDeep")[(j + dx + dy) % 3]
                    if j == 1 and dy == h - 1:
                        c = "moorDark" if dx else "moor"      # a scrap of the rag
                    f.put(x, y, c)
        at += w + 2 + int(hsh(j, 7, seed) * 3)
    f.finish(rim=None)
    sx = int(lo + 2 + hsh(8, 9, seed) * max(1, hi - lo - 3))  # the last spark, falling
    f.put(sx, CELL - 5, "stoneMid", "wraithGlow", True)
    for i in range(2):
        gx = int(lo + hsh(i, 11, seed) * max(1, hi - lo))
        gy = int(CELL - 7 - hsh(i, 12, seed) * 4)
        if 0 <= gy < CELL and not f.has(gx, gy):
            f.put(gx, gy, GRAIN[(i + seed + 1) % 3], None, True)
    return f


# --- Step 5 (the director's call 4 of 16.11.2026 08:52: a kill reads at phone size) ----------------------------------
SLUMP = (0.8, 0.55)          # frames 0 and 1: the slump's height as a share of the body's own height (never under half
                             # at 0.15 s, when frame 1 starts)
HEAP = (0.36, 0.56)           # frame 2: each column of the heap keeps this share of its pixels, uneven by column


def slump(src, k, seed):
    """Fall frame k (0 ... 2) of a finished body frame (its walk frame 0), 0.15 s each: it slumps into soot and its cold
    point sinks with it and goes out last; never a smear at once, never a point alone at head height.
    0: the slump begins: each column stacked onto the ground (its pixels sampled evenly, so the rag stays on top), the
       tallest at 0.8 of the body's height; the socket flares (its core white, a ring of glow round it);
    1: slumped to 0.55 of its height (at least half: the body still reads as a body at 0.15 s), the socket sunk with it
       and dimmer (its core in the second glow, no ring);
    2: a low heap of soot in uneven lumps, the thin limbs gone, the rag's strips still on it and ash on its top, the
       cold point last of all, faint, inside the heap near the ground (the engine fades it out by 0.45 s).
    The grains that lift off are the engine's flakes (`sootFlake.py`), never part of the strip. The height is the walk
    frame's own (its top row to the ground), and no column stands more than a pixel over both its neighbours: a mound,
    never a spike."""
    f = Frame(CELL, CELL, seed)
    cols = {}
    for x in range(CELL):
        col = [(src.b[y][x], src.g[y][x]) for y in range(CELL) if src.b[y][x] is not None]
        if col:
            cols[x] = col
    height = CELL - min(y for y in range(CELL) if any(src.b[y][x] is not None for x in range(CELL)))
    tallest = max(len(c) for c in cols.values())
    eye_col = next((x for x, c in cols.items() if any(g == "wraithWhite" for _, g in c)), None)
    counts = {}
    for x, col in cols.items():
        if k < 2:
            counts[x] = max(1, int(round(len(col) * height * SLUMP[k] / tallest)))
        elif len(col) >= 3 or x == eye_col:                  # the thin limbs and the loose ends are gone
            keep = HEAP[0] + (HEAP[1] - HEAP[0]) * hsh(x // 2, 9, seed)
            counts[x] = max(1, int(round(len(col) * keep)))
    for x in sorted(counts):                                 # a mound: no column a spike over both its neighbours
        side = max(counts.get(x - 1, 0), counts.get(x + 1, 0))
        counts[x] = min(counts[x], side + 1)
    if k < 2:                                                # and the slump keeps its height
        top = max(counts.values())
        want = -(-height * SLUMP[k] // 1)
        if top < want:
            peak = max(counts, key=lambda x: (counts[x], x))
            for x in (peak - 1, peak, peak + 1):
                if x in counts:
                    counts[x] = max(counts[x], int(want) - (x != peak))
    for x, col in cols.items():
        if x not in counts:
            continue
        n = min(counts[x], len(col)) if k == 2 else counts[x]
        picked = [col[min(len(col) - 1, int(i * len(col) / n))] for i in range(n)]
        eye = [j for j, (_, g) in enumerate(col) if g == "wraithWhite"]
        if eye and not any(g == "wraithWhite" for _, g in picked):      # the sampling skipped the socket: keep it
            j = min(n - 1, int(eye[0] * n / len(col)))
            picked[j] = col[eye[0]]
        for i, (body, glow) in enumerate(picked):
            y = CELL - n + i
            if glow == "wraithWhite":
                if k == 0:
                    f.put(x, y, "stoneLight", "wraithWhite")
                elif k == 1:
                    f.put(x, y, "stoneMid", "wraithGlow")
                else:
                    f.put(x, y, "stoneDark", "wraithDim")
            elif k == 2 and i == 0 and body in ("nightBlue", "nightSlate", "nightHaze", "night0"):
                f.put(x, y, ("stoneDark", "stoneMid", "night0")[(x + seed) % 3])     # ash on the heap's top
            else:
                f.put(x, y, body)
    if k == 0:
        for y in range(CELL):
            for x in range(CELL):
                if f.g[y][x] == "wraithWhite":
                    for dx, dy in ((-1, 0), (1, 0), (0, -1)):
                        if f.has(x + dx, y + dy) and f.g[y + dy][x + dx] is None:
                            f.g[y + dy][x + dx] = "wraithGlow"
    return f.finish(rim=None)


# --- Step 3 (the director, 16.11.2026 04:10): the body is the shadow, the rag is the accent ---------------------------
# A body is hand-set pixel by pixel, flat tones and no dither: the navy and soot ramp for head, flank, belly and limbs; a
# short mantle on the shoulders and two or three strips trailing behind it in the giant's cloak tones as they are in
# his shadow (moorDark, soilDark), their top pixels catching the moon (moor); a 1 px rim on the body's upper outline
# (nightHaze, a full value step over the body); one cold point. The outline runs round the sides and the underside but
# not over the upper contour (`uncap`), so the rag's top pixels and the rim are the edge the moon catches.
LEGEND = {
    # outlined body pixels
    "D": ("night0", None, False), "B": ("nightBlue", None, False), "S": ("nightSlate", None, False),
    "M": ("nightHaze", None, False), "n": ("nightDeep", None, False),
    "r": ("moorDark", None, False), "s": ("soilDark", None, False), "m": ("moor", None, False),
    "P": ("nightSlate", None, False), "p": ("nightHaze", None, False),
    "Q": ("moorDark", None, False), "q": ("moor", None, False),
    "E": ("stoneLight", "wraithWhite", False), "e": ("stoneMid", "wraithGlow", False),
    "g": ("nightSlate", "wraithDim", False),
    # bare pixels (no outline): thin limbs, claws, the strips' loose ends
    "l": ("night0", None, True), "L": ("nightBlue", None, True), "k": ("nightDeep", None, True),
    # step 4: a bare rim pixel (the moon on a contour that keeps a notch open beside it: the neck's dip)
    "h": ("nightHaze", None, True),
    "a": ("stoneDark", None, True),
    "1": ("moorDark", None, True), "3": ("soilDark", None, True), "2": ("moor", None, True),
}
ROOTS = "PpQq"


def root(rows):
    """The thread's root (column, row) of a hand-set grid: exactly one of P, p, Q, q."""
    check(rows)
    found = [(x, y) for y, r in enumerate(rows) for x, ch in enumerate(r) if ch in ROOTS]
    assert len(found) == 1, found
    return found[0]


def uncap(f):
    """No outline over the upper contour: where a column's topmost pixel is outline over another pixel, it goes."""
    for x in range(CELL):
        for y in range(CELL):
            c = f.b[y][x]
            if c is None:
                continue
            if c == "nightDeep" and (x, y) not in f.bare and y + 1 < CELL and f.b[y + 1][x] is not None:
                f.erase(x, y)
            break
    return f


def draw(rows, seed=0):
    """A hand-set grid (`LEGEND`) as a finished frame: flat tones, the 1 px outline round the sides and the underside,
    none over the upper contour, no warm rim."""
    check(rows)
    f = Frame(CELL, CELL, seed)
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            if ch == ".":
                continue
            name, glow, bare = LEGEND[ch]
            f.put(x, y, name, glow, bare)
    f.finish(rim=None)
    return uncap(f)


# --- Step 7 (the director, 16.11.2026 12:02): the ash giant's children ------------------------------------------------
# The small ones stop being small black ponies: they are the Ash Giant shrunk to a hand's height, a hunched navy shroud
# taller than wide on two stilt arms one pixel wide that run from the shoulder forward and down to the ground, no hind
# legs (the shroud's frayed hem drags behind), open air under the belly between the hem and the nearest arm (the
# giant's inverted V), the head hung low in front of the shroud with one cold eye point, and the giant's cloth on the
# hump in stripes of his two cloth tones (soilDark, moorDark) down its back, its top catching the moon (moor). Two
# bodies: the walker (sootling.py, 13 px tall) and the runt (sootlingB.py, 10 px). Eight frames each in the 14 x 14
# cell: walk 0 ... 5 (reach, plant, haul, over, drop, gather: the hump rises and falls, so a crowd's skyline rolls),
# 6 the climb (the arms up the wall ahead, the shroud hanging), 7 the strike (reared, both arms overhead).
# A body (`kin`): a shroud block in `LEGEND` (top-left at the pose's `at`), its skirt run down to the ground row by row
# (`skirt`: block columns, the last pair repeating), the head block hung in front (`head`, `head_at`), the shoulder the
# arms leave from, and eight poses (`at`; `near` and `far`: the arms' points after the shoulder, cell coordinates).
KIN_FRAMES = 8
KIN_WALK = 6
# the ochre cloth of the design card (step 6B): soilLight where the moon catches it, soil
LEGEND.update({"O": ("soilLight", None, False), "o": ("soil", None, False)})


def polyline(pts):
    """The pixels `limbs` draws for a polyline (the same rounding)."""
    out = []
    for a, b in zip(pts, pts[1:]):
        n = int(max(abs(b[0] - a[0]), abs(b[1] - a[1])) + 0.5)
        for i in range(n + 1):
            t = i / n if n else 0
            p = (round(a[0] + (b[0] - a[0]) * t), round(a[1] + (b[1] - a[1]) * t))
            if p not in out:
                out.append(p)
    return out


def kin_layout(body, k):
    """Frame k's hand-set grid, the arms' polylines (from the shoulder), the loose soot pixels and the pose."""
    p = body["poses"][k]
    ox, oy = p["at"]
    prev = body["poses"][(k - 1) % KIN_WALK] if k < KIN_WALK else p
    surge = prev["at"][0] < ox                        # the body surged forward: the hem has not caught up yet
    g = [["."] * CELL for _ in range(CELL)]

    def put(x, y, ch):
        if 0 <= x < CELL and 0 <= y < CELL:
            g[y][x] = ch

    for j, row in enumerate(body["hump"]):
        for i, ch in enumerate(row):
            if ch != ".":
                put(ox + i, oy + j, ch)
    skirt = body["skirt"]
    for n, y in enumerate(range(oy + len(body["hump"]), CELL)):
        a, b, back = (tuple(skirt[min(n, len(skirt) - 1)]) + ("",))[:3]
        if surge and y >= CELL - 3:
            b = max(a, b - 1)                         # the hem dragged thin behind the surge (it lags a frame)
        for x in range(a, b + 1):
            # the cloth runs on down the back (`back`: its pixels from the back edge), then the navy
            put(ox + x, y, back[x - a] if x - a < len(back) else ("D" if x == a else "B"))
    # the frayed hem: it drags a pixel behind along the ground (bare, no outline: soot, not a foot), its foot bitten,
    # the bitten pixel alternating by frame
    a0 = ox + skirt[-1][0]
    put(a0 - 1, CELL - 1, "l")
    if k % 2 == 0:
        put(a0, CELL - 1, ".")
    else:
        put(a0 + (skirt[-1][1] > skirt[-1][0]), CELL - 1, ".")
        put(a0 - 1, CELL - 2, "l")
    hx0, hy0 = body["head_at"]
    for j, row in enumerate(body["head"]):
        for i, ch in enumerate(row):
            if ch != ".":
                put(ox + hx0 + i, oy + hy0 + j, ch)
    sx, sy = body["shoulder"]
    shoulder = (ox + sx, oy + sy)
    near = [shoulder] + p["near"]
    far = [shoulder] + p.get("far_from", []) + p["far"]
    # one or two loose soot pixels behind the hem, drifting back and up by frame
    d = k % 3
    loose = [(a0 - 2 - (d > 1), CELL - 2 - d)]
    if k % 2 == 0:
        loose.append((a0 - 1, CELL - 4 - (d == 1)))
    return ["".join(r) for r in g], near, far, loose, p


def kin_head(body, p):
    """The head's cells in frame coordinates."""
    ox, oy = p["at"]
    hx0, hy0 = body["head_at"]
    return {(ox + hx0 + i, oy + hy0 + j) for j, row in enumerate(body["head"]) for i, ch in enumerate(row) if ch != "."}


def kin(body, k):
    """Frame k of a body, painted: the shroud and the head (`draw`: flat tones, the outline round the sides and the
    underside), the far arm behind the body, the near arm in front of it but behind the head, the hands hooked over
    the wall's top in the climb, the loose soot. The glow holds the cold eye point only."""
    rows, near, far, loose, p = kin_layout(body, k)
    f = draw(rows, seed=body["seed"])
    limbs(f, [(far, "l")])
    keep = {(x, y): (f.b[y][x], f.g[y][x]) for (x, y) in kin_head(body, p) if 0 <= x < CELL and 0 <= y < CELL}
    limbs(f, [(near, "L")], over=True)
    for (x, y), (bb, gg) in keep.items():            # the head stays in front of the near arm
        if bb is not None:
            f.b[y][x], f.g[y][x] = bb, gg
            f.bare.discard((x, y))
    if p.get("hook"):                                 # the hands hooked over the wall's top
        limbs(f, [([near[-1], (near[-1][0] - 1, near[-1][1])], "k"), ([far[-1], (far[-1][0] - 1, far[-1][1])], "k")],
              over=True)
    loose = [q for q in loose if 0 <= q[0] < CELL and 0 <= q[1] < CELL and f.b[q[1]][q[0]] is None]
    limbs(f, [([q, q], "k") for q in loose])
    return f
