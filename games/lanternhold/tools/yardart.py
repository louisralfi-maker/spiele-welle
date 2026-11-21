#!/usr/bin/env python3
"""Lanternhold build 3, the drill yard (docs/YARD.md sections 1, 2 and 4; wave 2, lane 2, step 2): the yard's things in
the courtyard, between the gatehouse's east tower and the barracks. Pure python on pixelart.py's Image, palette
colours only, no randomness (hashes of the position), so a run reproduces its files byte for byte. The bailey's
language (tools/keepart.py: the barracks, the smithy, the lodge): timber in the wood ramp lit from the upper left,
straw in the thatch's two tones, iron in the castle's stone ramp, the realm's teal and gold on what the house owns, an
ink edge round every silhouette. Painted art is albedo; the engine lights it by the hour and the kettle's fire is the
layout's emitter (`EntityFrames.yardProps`), never painted.

  yardart.py all --out <Resources/Art>
  yardart.py build <id> [<id> ...] --out <Resources/Art>

  yardGround   39x16      the drill ground: raked sand on the lane's top five rows (the sprite stands 5 px under
                          the walk line), a low post-and-rail fence behind it, the arms rack at its right end (two
                          practice spears and the house's round shield against the last post)
  yardPell     7x19 x 2   a pell: a stout post with a flat cap, a bundle of straw bound round its middle with two
                          rope bands, a mound at its foot; frame 1 battered (a strand torn loose, the bundle sagging)
  yardButt     13x17      the archery butt: a coiled straw boss, its face (the realm's teal ring and a gold heart)
                          turned to the archers on its left, two arrows in it, on a timber A-frame
  yardKettle   13x17 x 2  the pitch kettle's place: a tripod of three poles lashed at the top over a ring of stones;
                          frame 0 empty (a chain and its hook, cold ash), frame 1 the iron kettle hung on the chain
                          over split logs (the low fire is the layout's flame), a pale lit rim, black pitch
  yardSite     39x10 x 2  the drill yard's site: corner stakes with rag flags and a cord marked out along the
                          ground; frame 1, ordered (until its dawn): the fence rails stacked, a straw bale, a bundle of
                          stakes delivered
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import pixelart as PA  # noqa: E402
import worldart as WA  # noqa: E402

col, h01 = WA.col, WA.h01
CLEAR = (0, 0, 0, 0)


class C:
    """A canvas in image rows (0 at the top); `r(h)` is the row of a height over the sprite's bottom row."""

    def __init__(self, w, h):
        self.w, self.h = w, h
        self.im = PA.Image(w, h)

    def r(self, hh):
        return self.h - 1 - hh

    def set(self, x, y, name):
        if 0 <= x < self.w and 0 <= y < self.h:
            self.im.set(x, y, col(name) if isinstance(name, str) else name)

    def seth(self, x, hh, name):
        self.set(x, self.r(hh), name)

    def get(self, x, y):
        if 0 <= x < self.w and 0 <= y < self.h:
            return self.im.get(x, y)
        return CLEAR

    def opaque(self, x, y):
        return self.get(x, y)[3] > 0


def rim(c, keep=()):
    """An ink edge one pixel outside the silhouette (left, right, top and bottom), as the bailey's props have it;
    `keep`: (x, y) pixels left clear (a thin pole's lit side reads better without a second dark line)."""
    ink = col("ink")
    marks = []
    for y in range(c.h):
        for x in range(c.w):
            if c.opaque(x, y) or (x, y) in keep:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                if c.opaque(x + dx, y + dy) and c.get(x + dx, y + dy) != ink:
                    marks.append((x, y))
                    break
    for x, y in marks:
        c.im.set(x, y, ink)


def line(c, x0, y0, x1, y1, pick):
    """A one-pixel line (image rows) whose colour is `pick(i, n, x, y)`."""
    n = max(abs(x1 - x0), abs(y1 - y0))
    for i in range(n + 1):
        t = i / float(n) if n else 0
        x = int(round(x0 + (x1 - x0) * t))
        y = int(round(y0 + (y1 - y0) * t))
        name = pick(i, n, x, y)
        if name:
            c.set(x, y, name)


# --------------------------------------------------------------------------------------------------- the pell
def pell(frame):
    c = C(9, 22)
    seed = 4101 + frame
    px = 3
    # The post: 3 px, lit left, from the mound to a square top just over the bundle (never a point: a pell is a post).
    for hh in range(0, 18):
        c.seth(px, hh, "woodLight")
        c.seth(px + 1, hh, "wood")
        c.seth(px + 2, hh, "woodDark")
    c.seth(px, 18, "woodLight")
    c.seth(px + 1, 18, "woodLight")
    c.seth(px + 2, 18, "wood")
    # Notches cut by blows below the bundle.
    c.seth(px + 1, 4, "woodDark")
    c.seth(px, 3, "wood")
    # The straw bundle bound round the post's upper half (rows h 7 to 17), seven wide between its three rope bands
    # and pinched to five at each band, so it reads as bound straw and never as a body.
    sag = 1 if frame == 1 else 0
    top, bot = 17 - sag, 7 - sag
    bands = (bot + 1, (bot + top) // 2, top - 1)
    for hh in range(bot, top + 1):
        pinch = hh in bands or hh in (bot, top)
        x0, x1 = (px - 1, px + 3) if pinch else (px - 2, px + 4)
        for x in range(x0, x1 + 1):
            v = h01(seed, x, hh // 2, 3)
            if x <= px - 1:
                name = "strawLight" if v < 0.75 else "straw"
            elif x <= px + 1:
                name = "straw" if v < 0.6 else "strawLight"
            elif x == px + 2:
                name = "straw" if v < 0.5 else "plasterDim"
            else:
                name = "plasterDim" if v < 0.6 else "soilLight"
            c.seth(x, hh, name)
        if hh in bands:
            for x in range(x0, x1 + 1):
                c.seth(x, hh, "soilLight" if x == x0 else "soil")
    # The straw's cut ends over the top band, standing up as a ragged fringe (never a spike, never a head).
    for x, name in ((px - 1, "straw"), (px, "strawLight"), (px + 2, "straw"), (px + 3, "plasterDim")):
        c.seth(x, top + 1, name)
    c.seth(px + 1, top + 1, "woodLight")
    c.seth(px - 2, bot - 1, "plasterDim")
    c.seth(px + 4, bot - 1, "soilLight")
    if frame == 1:
        # Battered: a strand torn loose hangs on the right, the post's wood showing through a gash.
        c.seth(px + 5, bot + 2, "straw")
        c.seth(px + 5, bot + 1, "plasterDim")
        c.seth(px + 5, bot, "plasterDim")
        c.seth(px + 1, bot + 3, "wood")
        c.seth(px + 2, bot + 3, "woodDark")
    # The mound at its foot.
    for x in range(px - 2, px + 5):
        c.seth(x, 0, "soil" if x > px else "soilLight")
    c.seth(px - 1, 1, "soilLight")
    c.seth(px + 3, 1, "soil")
    rim(c)
    return c.im


# ------------------------------------------------------------------------------------------------- the butt
BOSS_ROWS = ((3, 7), (2, 8), (1, 9), (1, 9), (0, 10), (0, 10), (0, 10), (1, 9), (1, 9), (2, 8), (3, 7))


def boss_layers():
    """The boss's round (11 px) as rings peeled from its edge: 0 the edge, 1 the next, ... (four neighbours)."""
    cells = {(x, y) for y, (a, b) in enumerate(BOSS_ROWS) for x in range(a, b + 1)}
    layer, depth = {}, 0
    while cells:
        edge = {(x, y) for (x, y) in cells
                if any((x + dx, y + dy) not in cells for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))}
        for cell in edge:
            layer[cell] = depth
        cells -= edge
        depth += 1
    return layer


def butt():
    c = C(17, 20)
    ox, oy = 4, 1                                   # the boss's top-left in the canvas
    # The easel: two legs splayed under the boss and a third propping it from behind, a cross bar.
    line(c, ox + 3, oy + 10, ox, 18, lambda i, n, x, y: "woodLight")
    line(c, ox + 4, oy + 10, ox + 1, 18, lambda i, n, x, y: "wood")
    line(c, ox + 7, oy + 10, ox + 10, 18, lambda i, n, x, y: "woodDark")
    line(c, ox + 8, oy + 8, ox + 12, 18, lambda i, n, x, y: "soil")
    for x in range(ox + 1, ox + 10):
        c.set(x, 16, "wood" if x < ox + 7 else "woodDark")
    c.set(ox + 1, 16, "woodLight")
    # The boss: coiled straw, its painted face a red ring on bone round a red heart, as butts were painted; no teal
    # and no gold (those are the house's shields on the barracks' wall).
    for (x, y), depth in boss_layers().items():
        lit = x + y < 9
        shade = x + y > 12
        if depth == 0:
            name = "straw" if lit else ("soilLight" if shade else "plasterDim")
        elif depth == 1:
            name = "strawLight" if lit else ("plasterDim" if shade else "straw")
        elif depth == 2:
            name = "tileLight" if lit else "tile"
        elif depth == 3:
            name = "parchment" if not shade else "plaster"
        else:
            name = "tile"
        c.set(ox + x, oy + y, name)
    # A seam between the coils on the shaded side, and the heart's lit pixel.
    for (x, y) in ((8, 1), (9, 2), (10, 4), (10, 6), (9, 8), (8, 9), (6, 10)):
        c.set(ox + x, oy + y, "soilLight")
    c.set(ox + 5, oy + 5, "tileLight")
    rim(c)
    # Two arrows in it, drawn over the edge (a shaft is one pixel, never outlined): they stand out toward the archers
    # on the left past the boss's edge, a dark nock under each shaft, pale fletchings at the ends.
    for (ax, ay, run) in ((5, 4, 6), (7, 8, 8)):
        for i in range(run):
            x, y = ox + ax - 1 - i, oy + ay - (i // 3)
            c.set(x, y, "woodLight" if i % 3 else "wood")
        fx, fy = ox + ax - run - 1, oy + ay - ((run - 1) // 3)
        c.set(fx, fy, "parchment")
        c.set(fx, fy - 1, "parchment")
        c.set(fx - 1, fy - 1, "plaster")
        c.set(fx + 1, fy + 1, "ink")
    return c.im


# ----------------------------------------------------------------------------------------------- the kettle
def pole(c, x0, y0, x1, y1, name, behind=False):
    """A tripod pole: one pixel of `name` with a dark edge on its shaded right (never a full outline, so three poles
    stay three lines and do not close into a dark lattice); `behind`: only where nothing is drawn yet."""
    ink = col("ink")
    pts = []
    n = max(abs(x1 - x0), abs(y1 - y0))
    for i in range(n + 1):
        t = i / float(n) if n else 0
        pts.append((int(round(x0 + (x1 - x0) * t)), int(round(y0 + (y1 - y0) * t))))
    for x, y in pts:
        if not (behind and c.opaque(x, y)):
            c.set(x, y, name)
    for x, y in pts:
        if 0 <= x + 1 < c.w and 0 <= y < c.h and not c.opaque(x + 1, y):
            c.im.set(x + 1, y, ink)


def kettle(frame):
    c = C(17, 18)
    ax, ay = 8, 1                                    # the lashing
    # The ring of stones at the foot.
    for x, name in ((5, "stoneLight"), (6, "stone"), (7, "stoneMid"), (9, "stone"), (10, "stoneMid"),
                    (11, "stoneDark")):
        c.set(x, 17, name)
    c.set(6, 16, "stonePale")
    c.set(10, 16, "stoneLight")
    if frame == 0:
        c.set(7, 17, "stoneDark")
        c.set(8, 17, "soilDark")
        c.set(9, 17, "stoneDark")
        c.set(8, 16, "stoneMid")
    else:
        # The kettle: a round iron belly 7 wide (rows 9 to 14) hung low between the legs, a lit lip, the pitch black
        # in its mouth, a lit shoulder on the upper left, a lug each side.
        belly = {9: (5, 11), 10: (5, 11), 11: (5, 11), 12: (5, 11), 13: (6, 10), 14: (7, 9)}
        for y, (x0, x1) in belly.items():
            for x in range(x0, x1 + 1):
                c.set(x, y, "night1" if (x == x1 and y >= 10) else "stoneDark")
        for (x, y, name) in ((6, 10, "stone"), (7, 10, "stoneMid"), (6, 11, "stoneMid"), (6, 12, "stoneMid"),
                             (7, 11, "stoneMid")):
            c.set(x, y, name)
        for x in range(5, 12):
            c.set(x, 9, "stoneLight" if x < 10 else "stone")
        c.set(5, 9, "stonePale")
        c.set(6, 9, "stonePale")
        for x in range(8, 11):
            c.set(x, 10, "night0")
        c.set(4, 10, "stoneMid")
        c.set(12, 10, "stoneDark")
        # Split logs crossed under it (the flame is drawn by the layout over their middle).
        for x, y, name in ((6, 16, "woodLight"), (7, 15, "wood"), (8, 16, "woodDark"), (9, 15, "woodLight"),
                           (10, 16, "wood"), (7, 16, "woodDark"), (9, 16, "soil")):
            c.set(x, y, name)
    rim(c)
    # The poles: the back one behind the kettle, then the two in front, splayed wide of it.
    pole(c, ax + 1, ay + 1, 10, 17, "soil", behind=True)
    pole(c, ax, ay, 1, 17, "woodLight")
    pole(c, ax, ay, 14, 17, "woodDark")
    # The lashing: rope round the crossing, the poles' ends standing over it.
    c.set(ax - 1, 0, "woodLight")
    c.set(ax + 1, 0, "wood")
    c.set(ax - 1, 2, "soilLight")
    c.set(ax, 2, "soil")
    c.set(ax + 1, 2, "soil")
    # The chain, and its hook (empty) or the bail the kettle hangs by.
    bottom = 10 if frame == 0 else 7
    for y in range(3, bottom):
        c.set(ax, y, "stoneLight" if y % 2 else "stoneMid")
    if frame == 0:
        c.set(ax, 10, "stoneLight")
        c.set(ax + 1, 11, "stoneLight")
        c.set(ax + 1, 10, "stoneMid")
    else:
        for (x, y) in ((ax - 1, 7), (ax + 1, 7), (ax - 2, 8), (ax + 2, 8), (ax - 3, 8), (ax + 3, 8)):
            c.set(x, y, "stoneMid")
        c.set(ax - 3, 8, "stoneLight")
    return c.im


# ------------------------------------------------------------------------------------------------ the ground
GW, GH, SAND = 39, 16, 5


def ground():
    c = C(GW, GH)
    # The sand: the lane's top five rows (rows h 0 to 4 are under the walk line), raked along, its ends ragged.
    for hh in range(0, SAND):
        for x in range(GW):
            end = min(x, GW - 1 - x)
            if end < (SAND - hh) // 2 and h01(7, x, hh) < 0.7:
                continue
            v = h01(11, x // 3, hh)
            name = "plaster" if v < 0.55 else "plasterDim"
            if hh == SAND - 1:
                name = "plasterDim" if v < 0.3 else "plaster"
            if hh % 2 == 0 and (x + hh * 3) % 7 < 3:
                name = "plasterDim"          # the rake's furrows
            if h01(13, x, hh) < 0.06:
                name = "soilLight"           # a footprint, a pebble
            c.seth(x, hh, name)
    # The fence: posts on the walk line and two rails between them, a low fence about ten rows high. No full ink
    # edge (it would close the gaps between the rails into a dark panel): each post keeps a dark right side and a cap,
    # each rail a shaded underside, so the tower's stone shows through between them.
    ink = col("ink")
    posts = (1, 10, 19, 28, 36)
    rails = (SAND + 4, SAND + 8)
    for rail in rails:
        for x in range(posts[0] + 2, posts[-1]):
            v = h01(17, x // 5, rail)
            c.seth(x, rail, "woodLight" if v < 0.35 else "wood")
            c.seth(x, rail - 1, "woodDark")
            if h01(19, x, rail) < 0.08:
                c.seth(x, rail, "woodDark")       # a knot, a crack
    for px in posts:
        tall = 11 if px in (posts[0], posts[-1]) else 10
        for hh in range(SAND, SAND + tall):
            c.seth(px, hh, "woodLight")
            c.seth(px + 1, hh, "wood" if hh > SAND + tall - 3 else "woodDark")
            c.im.set(px + 2, c.r(hh), ink) if c.get(px + 2, c.r(hh))[3] == 0 else None
        c.seth(px, SAND + tall, "ink")
        c.seth(px + 1, SAND + tall, "ink")
        c.seth(px - 1, SAND + tall - 1, "ink") if px - 1 >= 0 else None
    c.im.set(posts[0] - 1, c.r(SAND + 2), ink)
    for hh in range(SAND, SAND + 10):
        c.seth(posts[0] - 1, hh, "ink")
    # The arms rack at the right end: two practice spears leaning on the last post (iron heads catching the light),
    # the house's round shield at their foot.
    for i, hh in enumerate(range(SAND, SAND + 13)):
        c.seth(33 - i // 6, hh, "woodLight")
        c.seth(31 - i // 5, hh, "wood")
    c.seth(31, SAND + 13, "stonePale")
    c.seth(31, SAND + 14, "stoneLight")
    c.seth(28, SAND + 13, "stoneLight")
    c.seth(28, SAND + 14, "stoneMid")
    for dy in range(-2, 3):
        for dx in range(-2, 3):
            d = dx * dx + dy * dy
            if d <= 6:
                name = "banner" if dx < 0 or dy > 0 else "roofDeep"
                if d >= 4:
                    name = "roofLight" if dx < 0 and dy >= 0 else "ink"
                c.seth(34 + dx, SAND + 3 + dy, name)
    c.seth(34, SAND + 3, "gold")
    c.seth(34, SAND, "ink")
    return c.im


# -------------------------------------------------------------------------------------------------- the site
SW, SH = 39, 10


def site(frame):
    c = C(SW, SH)
    stakes = ((1, 8), (13, 6), (24, 6), (36, 8))
    for (sx, tall) in stakes:
        for hh in range(0, tall):
            c.seth(sx, hh, "woodLight")
            c.seth(sx + 1, hh, "wood")
        c.seth(sx, tall, "strawLight")
        c.seth(sx + 1, tall, "strawLight")
    # Rag flags on the corner stakes.
    c.seth(3, 7, "parchment")
    c.seth(4, 7, "parchment")
    c.seth(3, 6, "plasterDim")
    c.seth(34, 7, "parchment")
    c.seth(35, 7, "plasterDim")
    # The cord from stake to stake, sagging a pixel in each span.
    for (ax, at), (bx, bt) in zip(stakes, stakes[1:]):
        for x in range(ax + 2, bx):
            t = (x - ax) / float(bx - ax)
            sag = 1 if 0.25 < t < 0.75 else 0
            c.seth(x, min(at, bt) - 1 - sag, "plaster")
    if frame == 1:
        # Delivered: the rails stacked, a straw bale, a bundle of stakes.
        for hh in range(0, 3):
            for x in range(4, 18):
                c.seth(x, hh, "woodLight" if hh == 2 else ("wood" if (x + 2 * hh) % 7 else "woodDark"))
            c.seth(4, hh, "woodLight")             # the rails' cut ends
            c.seth(17, hh, "soilLight")
        for hh in range(0, 5):
            for x in range(27, 34):
                c.seth(x, hh, "strawLight" if x < 30 and hh > 1 else "straw")
            c.seth(30, hh, "soil")
        for hh in range(0, 6):
            c.seth(20 + hh // 3, hh, "woodLight")
            c.seth(22 + hh // 3, hh, "wood")
    rim(c)
    return c.im


def strip(frames):
    w, h = frames[0].w, frames[0].h
    out = PA.Image(w * len(frames), h)
    for i, f in enumerate(frames):
        WA.blit(out, f, i * w, 0)
    return out


BUILDERS = {
    "yardGround": ground,
    "yardPell": lambda: strip([pell(0), pell(1)]),
    "yardButt": butt,
    "yardKettle": lambda: strip([kettle(0), kettle(1)]),
    "yardSite": lambda: strip([site(0), site(1)]),
}


def main():
    a = sys.argv[1:]
    out = a[a.index("--out") + 1] if "--out" in a else "."
    if a and a[0] == "build":
        names = [n for n in a[1:] if not n.startswith("--") and n != out]
    else:
        names = list(BUILDERS)
    for n in names:
        im = BUILDERS[n]()
        path = os.path.join(out, n + ".png")
        PA.write_png(path, im)
        print("wrote", path, im.w, "x", im.h)


if __name__ == "__main__":
    main()
