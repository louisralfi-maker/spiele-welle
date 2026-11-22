#!/usr/bin/env python3
"""Lanternhold build 3, the drill yard (docs/YARD.md sections 1, 2 and 4; wave 2, lane 2, steps 2 and 3): the yard's things
in the courtyard. Step 3 (the director's ruling of 21.11.2026, 17:10, and his pick, layout A, 17:31): the yard is the
gate's apron plus the whole front of the barracks, its bunkhouse, sand from 1442 to 1544 (103 px). Pure python on pixelart.py's Image, palette
colours only, no randomness (hashes of the position), so a run reproduces its files byte for byte. The bailey's
language (tools/keepart.py: the barracks, the smithy, the lodge): timber in the wood ramp lit from the upper left,
straw in the thatch's two tones, iron in the castle's stone ramp, the realm's teal and gold on what the house owns, an
ink edge round every silhouette. Painted art is albedo; the engine lights it by the hour and the kettle's fire is the
layout's emitter (`EntityFrames.yardProps`), never painted.

  yardart.py all --out <Resources/Art>
  yardart.py build <id> [<id> ...] --out <Resources/Art>

It runs on its own (no tools/build-art*.sh calls it yet); its PNGs are committed.

  yardGround   103x16     the drill ground: raked sand on the lane's top five rows (the sprite stands 5 px under
                          the walk line) from the gate's apron to the barracks' east wall, a low post-and-rail fence
                          only along the apron's west part, ending at its corner post at 1464 (fix step 4b, R1: no
                          rail runs behind the kettle's tripod, 1466 to 1478), a corner post at the far end (1541);
                          the bunkhouse's front stays open (its painted spear rack is the yard's arms rack)
  yardPell     9x26 x 2   a pell: a stout post with a flat cap, a tall bundle of straw bound round it with four rope
                          bands, a mound at its foot; frame 1 battered (a strand torn loose, the bundle sagging).
                          Step 4 (the critic's M3): the bundle wraps the post's head as high as a man, so the
                          bunkhouse's painted spear rack behind it (its tips at world 1495, 1497 and 1499, 23 px up)
                          no longer sticks out of the pell's top as three spikes; the barracks' art is not changed.
                          Fix step 4b (the director's R5: it read as a hooped barrel): uneven rope bands (image rows
                          3, 8, 12 and 18), the straw parted for two rows low down where the post's wood shows, and a
                          tied top knot narrower than the body
  yardButt     17x26 x 3  the archery butt: a coiled straw boss, its face (a red ring on bone round a red heart)
                          turned to the archers on its left, two arrows in it, on a timber A-frame; step 4 (the
                          critic's H3, two butts set behind each other were one sprite twice): frame 1 the butt
                          behind, turned further from the viewer (its face a narrow oval, the boss a pixel smaller,
                          the coiled straw of its side showing), one arrow low in it, the back leg of its A-frame
                          standing out behind it (the layout draws it darker and a pixel higher, farther back);
                          frame 2 the front butt with the drill's last arrow stuck in its heart (the critic's H4): its
                          tip buried, its shaft steep as it fell out of the high arc (the flight's slope at the end is
                          about 2.6 rows a column), six pixels showing up and to the left with the fletching over the
                          boss's rim (`YardLook.buttFrameStuck`). Fix step 4b (the director's R2): the frame grew six
                          rows upward (its feet and its heart, world 1537 and 13 px up, stay) so the stuck arrow
                          reads on the phone: its tip in the heart (column 9, the heart's lower row), the shaft
                          running back up and west along the fall for twelve pixels, four of them standing clear of
                          the butt against the wall, each with an ink edge on its east side, a pale fletch of two
                          pixels at its end (`stuck_arrow`)
  yardKettle   13x18 x 3  the pitch kettle's place: a tripod of three poles lashed at the top over a ring of stones;
                          frame 0 empty (a chain and its hook, cold ash), frame 1 the iron kettle (7 px, a pale lit
                          rim, black pitch) hung on its bail over split logs, cold; frame 2 the same over its fire, two
                          rows of its underside and lower flank in the fire's warm ramp (the low flame is the
                          layout's emitter, its light at the pot's middle)
  yardSite     103x10 x 2 the drill yard's site, the larger ground marked out: six stakes (the corners with teal rag
                          flags, the door's two with red ones), a thin hemp cord sagging between them at two thirds
                          of their height, open at the bunkhouse door; frame 1, ordered (until its dawn): the timber
                          delivered on the bunkhouse's front (rails stacked, a bundle of stakes, and east of the door
                          three logs stacked, their cut ends pale on the stack's east face: fix step 4b, R8; step 4's
                          straw bale read as a crate), clear of the lord's lane and the door
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
# Step 4 (M3): the bundle's top row (h over the sprite's foot); with its fringe and ink edge it covers the spear rack's
# tips (23 px up) on all three of their columns.
PELL_TOP = 23


def pell(frame):
    c = C(9, PELL_TOP + 3)
    seed = 4101 + frame
    px = 3
    # The post: 3 px, lit left, from the mound to a square top just over the bundle (never a point: a pell is a post).
    for hh in range(0, PELL_TOP + 1):
        c.seth(px, hh, "woodLight")
        c.seth(px + 1, hh, "wood")
        c.seth(px + 2, hh, "woodDark")
    c.seth(px, PELL_TOP + 1, "woodLight")
    c.seth(px + 1, PELL_TOP + 1, "woodLight")
    c.seth(px + 2, PELL_TOP + 1, "wood")
    # Notches cut by blows below the bundle.
    c.seth(px + 1, 4, "woodDark")
    c.seth(px, 3, "wood")
    # The straw bundle bound round the post from its middle to its head (rows h 7 to 23), seven wide between its four
    # rope bands and pinched to five at each band, so it reads as bound straw and never as a body (step 3: rows 7 to
    # 17, three bands).
    sag = 1 if frame == 1 else 0
    top, bot = PELL_TOP - sag, 7 - sag
    # Fix step 4b (R5): the bands fall unevenly (image rows 18, 12, 8 and 3 of the 26: h 7, 13, 17, 22), never every
    # 4 px as hoops on a barrel; between the two low ones the straw parts for two rows and the post's wood shows.
    bands = (bot, bot + 6, bot + 10, top - 1)
    parted = (bot + 3, bot + 4)
    for hh in range(bot, top + 1):
        pinch = hh in bands or hh in (bot, top) or hh in parted
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
        if hh in parted:
            # The post's wood between the parted straw: lit, mid and shaded, a straw wisp at each side.
            for x, name in ((px, "woodLight"), (px + 1, "wood"), (px + 2, "woodDark")):
                c.seth(x, hh, name)
    # Fix step 4b (R5): the straw's ends over the top band tied in a knot, three wide (the body is seven), the post's
    # head inside it (never a spike, never a head).
    for x, name in ((px, "strawLight"), (px + 1, "straw"), (px + 2, "plasterDim")):
        c.seth(x, top + 1, name)
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


# Fix step 4b (R2): the butt's frames are BUTT_LIFT rows taller than step 4's (17 x 20), all of it upward: the stuck
# arrow's shaft and fletch stand over the boss there. The feet stay on the sprite's bottom row, the heart 13 px up.
BUTT_H, BUTT_LIFT = 26, 6
BUTT_FOOT = BUTT_H - 2                              # the legs' last row (the ink edge under them)


def butt(stuck=False):
    c = C(17, BUTT_H)
    ox, oy = 4, 1 + BUTT_LIFT                       # the boss's top-left in the canvas
    # The easel: two legs splayed under the boss and a third propping it from behind, a cross bar.
    line(c, ox + 3, oy + 10, ox, BUTT_FOOT, lambda i, n, x, y: "woodLight")
    line(c, ox + 4, oy + 10, ox + 1, BUTT_FOOT, lambda i, n, x, y: "wood")
    line(c, ox + 7, oy + 10, ox + 10, BUTT_FOOT, lambda i, n, x, y: "woodDark")
    line(c, ox + 8, oy + 8, ox + 12, BUTT_FOOT, lambda i, n, x, y: "soil")
    for x in range(ox + 1, ox + 10):
        c.set(x, BUTT_FOOT - 2, "wood" if x < ox + 7 else "woodDark")
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
    if stuck:
        stuck_arrow(c, ox, oy)
    return c.im


# Fix step 4b (the director's R2): the drill's arrow stuck in the front butt, (column, row) from the boss's top-left
# (ox, oy). The tip is buried in the heart's lower row (5, 6: canvas column 9); the shaft runs back up and west along the
# fall (the flight comes down at about 2.6 rows a column), out over the boss's top: the last four pixels stand clear of
# the butt's silhouette (its ink edge included) against the wall, each with an ink edge on its east side; the fletch is
# two pale pixels at its end.
STUCK_TIP = (5, 6)
STUCK_SHAFT = ((5, 5), (5, 4), (4, 3), (4, 2), (4, 1), (3, 0), (3, -1), (3, -2), (2, -3), (2, -4), (1, -5))
STUCK_OUT = 4                                       # the last four shaft pixels stand clear of the silhouette
STUCK_FLETCH = ((1, -6), (0, -5))


def stuck_arrow(c, ox, oy):
    layer = boss_layers()
    tx, ty = STUCK_TIP
    c.set(ox + tx, oy + ty, "woodDark")             # the tip's end, buried in the heart's red
    out = STUCK_SHAFT[-STUCK_OUT:]
    for (x, y) in STUCK_SHAFT:
        depth = layer.get((x, y))
        if depth is not None and depth <= 1:
            name = "woodDark"                       # on the coiled straw: dark, so it shows on the pale coils
        else:
            name = "woodLight"                      # on the red and the bone, on the boss's ink edge, in the air
        c.set(ox + x, oy + y, name)
    for (x, y) in out:
        if not c.opaque(ox + x + 1, oy + y) and (x + 1, y) not in STUCK_SHAFT:
            c.set(ox + x + 1, oy + y, "ink")        # the shaft's ink edge, so it reads against the wall
    for (x, y) in STUCK_FLETCH:
        c.set(ox + x, oy + y, "parchment")


# The butt behind (step 4), its boss from column 4 and row 1 (image rows): a pixel smaller than the front one's 11 x 11,
# 9 wide and 10 high. Its painted face is an oval (R the ring, B the bone, H the heart, h its lit pixel) set toward
# the archers on the left; e is the straw's thin edge on that side, S the coiled side turned toward the viewer (s its
# lit coil, k the seam between the coils, d its shade).
BEHIND_BOSS = (
    "..eSSSS..",
    ".eRRRssd.",
    "eRBBBRskd",
    "eRBhBRskd",
    "eRBHBRskd",
    "eRBBBRskd",
    "eRBBBRSkd",
    ".eRRRSSd.",
    "..SSSSd..",
    "...dd....",
)
BEHIND_INK = {"R": "tile", "B": "parchment", "H": "tile", "h": "tileLight", "e": "straw", "S": "straw",
              "s": "strawLight", "k": "soilLight", "d": "plasterDim"}


def butt_behind():
    """Step 4 (the critic's H3): the butt set behind the front one, a different thing and never the same sprite twice.
    Turned further from the viewer (`BEHIND_BOSS`), one arrow low in its ring, the A-frame seen more from the side: the
    front legs closer together and the back leg standing well out behind it to the right. Fix step 4b: on the taller
    frame (BUTT_H), its feet on the same bottom row."""
    c = C(17, BUTT_H)
    ox, oy = 4, 1 + BUTT_LIFT
    # The back leg first (behind everything): from the boss's upper back down to the ground well behind it.
    line(c, ox + 8, oy + 3, 16, BUTT_FOOT, lambda i, n, x, y: "woodDark" if i % 4 else "soil")
    line(c, ox + 9, oy + 4, 16, BUTT_FOOT - 1, lambda i, n, x, y: "soil" if i > 1 else None)
    # The front legs, close together (seen from the side), and their cross bar.
    line(c, ox + 2, oy + 9, ox, BUTT_FOOT, lambda i, n, x, y: "woodLight")
    line(c, ox + 3, oy + 9, ox + 1, BUTT_FOOT, lambda i, n, x, y: "wood")
    line(c, ox + 5, oy + 9, ox + 6, BUTT_FOOT, lambda i, n, x, y: "woodDark")
    for x in range(ox + 1, ox + 7):
        c.set(x, BUTT_FOOT - 3, "wood" if x < ox + 4 else "woodDark")
    c.set(ox + 1, 15, "woodLight")
    for y, row in enumerate(BEHIND_BOSS):
        for x, ch in enumerate(row):
            if ch == ".":
                continue
            name = BEHIND_INK[ch]
            if ch == "R" and (x + y < 5):
                name = "tileLight"                  # the ring's lit upper left
            if ch == "B" and (x + y > 7):
                name = "plaster"                    # the bone in the ring's shade
            c.set(ox + x, oy + y, name)
    rim(c)
    # One arrow low in the ring, standing out toward the archers past the boss's edge.
    for i in range(4):
        c.set(ox + 1 - i, oy + 6, "woodLight" if i % 3 else "wood")
    c.set(ox - 3, oy + 6, "parchment")
    c.set(ox - 3, oy + 5, "parchment")
    c.set(ox - 4, oy + 5, "plaster")
    c.set(ox - 2, oy + 7, "ink")
    return c.im


# ----------------------------------------------------------------------------------------------- the kettle
def pole(c, x0, y0, x1, y1, name, behind=False, edge="strawLight"):
    """A tripod pole: one pixel of `name` with an edge pixel on its east side in every row (never a full outline, so
    three poles stay three lines and do not close into a dark lattice); `behind`: only where nothing is drawn yet.
    Step 3 (the critic's H3): the edge one tone over the ink (`soil`), so the legs read on the dark lane at night. Fix
    step 4b (the director's R1): the edge is one pale lit pixel per row (`strawLight`), so the legs stand free of the
    east tower's dark edge stripe and the fence by day, in all three frames."""
    edge_col = col(edge)
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
            c.im.set(x + 1, y, edge_col)


# The pot of frames 1 and 2 (step 3, the critic's H3): 7 px wide (columns 3 to 9), its lip on row 8 and its round belly
# down to row 13; on row 9 the pitch in its mouth. Its middle is row 10.5, 6.5 px over the sprite's foot: the kettle's
# light stands there (`YardLook.kettleLight`), so the pot is lit from below.
POT_ROWS = {8: (4, 8), 9: (3, 9), 10: (3, 9), 11: (3, 9), 12: (3, 9), 13: (4, 8)}


def pot(c, lit):
    for y, (x0, x1) in POT_ROWS.items():
        for x in range(x0, x1 + 1):
            if y == 8:
                # the lip, a pale rim; fix step 4b (R1): one lit row across all but its shaded end, so the cold pot
                # reads as a pot at phone size on the dark rubble behind it
                name = "stonePale" if x <= 7 else "stoneLight"
            elif y == 9:
                name = "night0" if x0 < x < x1 else ("stonePale" if x == x0 else "stoneMid")  # the pitch in its mouth
            elif x == x0:
                name = "stone" if y <= 11 else "stoneMid"                                  # the lit shoulder
            elif x == x0 + 1 and y == 10:
                name = "stoneLight"
            elif x == x1:
                name = "night1"
            else:
                name = "stoneDark"
            c.set(x, y, name)
    c.set(4, 10, "stoneMid")
    c.set(5, 11, "stoneMid")
    if lit:
        # Two rows in the fire's warm ramp: the underside brightest over the flame's middle, the lower flank's outline
        # catching it at both sides (painted albedo; the fire's light warms it more at night).
        for x, name in ((4, "fireOrange"), (5, "fireGold"), (6, "fireWhite"), (7, "fireGold"), (8, "fireOrange")):
            c.set(x, 13, name)
        for x, name in ((3, "fireOrange"), (4, "ember"), (5, "emberDim"), (6, "ember"), (7, "emberDim"),
                        (8, "ember"), (9, "fireOrange")):
            c.set(x, 12, name)
        c.set(3, 11, "ember")
        c.set(9, 11, "emberDim")
    # The lugs the bail hangs by.
    c.set(2, 9, "stoneMid")
    c.set(10, 9, "stoneDark")


def kettle(frame):
    # Step 2's review: 13 px wide (was 17), so it stands without covering its neighbours. Step 3 (H3): frames 1 and 2
    # carry a 7 px pot; frame 2 is the same kettle over its fire.
    c = C(13, 18)
    ax, ay = 6, 1                                    # the lashing
    # The ring of stones at the foot.
    for x, name in ((3, "stoneLight"), (4, "stone"), (5, "stoneMid"), (7, "stone"), (8, "stoneMid"),
                    (9, "stoneDark")):
        c.set(x, 17, name)
    c.set(4, 16, "stonePale")
    c.set(8, 16, "stoneLight")
    if frame == 0:
        c.set(5, 17, "stoneDark")
        c.set(6, 17, "soilDark")
        c.set(7, 17, "stoneDark")
        c.set(6, 16, "stoneMid")
    else:
        pot(c, lit=frame == 2)
        # Split logs crossed under it (the flame is drawn by the layout over their middle); their ends glow when lit.
        for x, y, name in ((4, 16, "woodLight"), (5, 15, "wood"), (6, 16, "woodDark"), (7, 15, "woodLight"),
                           (8, 16, "wood"), (5, 16, "woodDark"), (7, 16, "soil")):
            c.set(x, y, name)
        if frame == 2:
            c.set(5, 16, "ember")
            c.set(7, 16, "emberDim")
    rim(c)
    # The poles after the ink edge, passing behind the pot: the back one first, then the two in front, splayed wide;
    # one tone lighter than step 2's (the critic's H3).
    pole(c, ax + 1, ay + 1, 8, 17, "woodDark", behind=True)
    pole(c, ax, ay, 0, 17, "woodLight", behind=True)
    pole(c, ax, ay, 12, 17, "wood", behind=True)
    # The lashing: rope round the crossing, the poles' ends standing over it.
    c.set(ax - 1, 0, "woodLight")
    c.set(ax + 1, 0, "wood")
    c.set(ax - 1, 2, "soilLight")
    c.set(ax, 2, "strawLight")
    c.set(ax + 1, 2, "soilLight")
    # The chain, and its hook (empty) or the bail the kettle hangs by: from the hook out to the two lugs.
    bottom = 10 if frame == 0 else 6
    for y in range(3, bottom):
        c.set(ax, y, "stoneLight" if y % 2 else "stoneMid")
    if frame == 0:
        c.set(ax, 10, "stoneLight")
        c.set(ax + 1, 11, "stoneLight")
        c.set(ax + 1, 10, "stoneMid")
    else:
        c.set(ax, 6, "stoneLight")
        for (x, y, name) in ((ax - 1, 6, "stoneMid"), (ax + 1, 6, "stoneMid"), (ax - 2, 7, "stoneLight"),
                             (ax + 2, 7, "stoneMid"), (ax - 3, 8, "stoneMid"), (ax + 3, 8, "stoneDark")):
            if not c.opaque(x, y) or c.get(x, y) == col("ink"):
                c.set(x, y, name)
    return c.im


# ------------------------------------------------------------------------------------------------ the ground
# Step 3, layout A (world x = 1442 + column): the fence only along the gate's apron, the barracks' front open from 1481
# (its door at 1505 to 1516 stays clear), a corner post at 1541 (column 99). Fix step 4b (the director's R1): the
# apron's fence ends at its own corner post at 1464 (column 22, the last of FENCE_POSTS), so the kettle's tripod (1466 to
# 1478) stands free on the open apron with no rail behind it. Picture only: `Yard.fenceX` 1468 and its reach stay, the
# lord leans at the fence's corner.
GW, GH, SAND = 103, 16, 5
FENCE_POSTS = (1, 11, 22)
APRON_CORNER = FENCE_POSTS[-1]
CORNER_POST = 99


def ground():
    c = C(GW, GH)
    # The sand: the lane's top five rows (rows h 0 to 4 are under the walk line), raked along, its ends ragged; trodden
    # darker where the archer stands and loosens his feet (columns 0 to 3) and round the guard and his pell (columns 39 to
    # 60, 1481 to 1502; the drill's own wear).
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
            if h01(13, x, hh) < 0.05:
                name = "soilLight"           # a footprint, a pebble
            if hh >= SAND - 2 and (x < 4 or 39 <= x < 61) and h01(23, x, hh) < 0.45:
                name = "plasterDim"          # trodden
            c.seth(x, hh, name)
    # The fence along the apron: posts on the walk line and two rails between them, a low fence about ten rows high. No
    # full ink edge (it would close the gaps between the rails into a dark panel): each post keeps a dark right side and
    # a cap, each rail a shaded underside, so the tower's stone shows through between them.
    ink = col("ink")
    rails = (SAND + 4, SAND + 8)
    for rail in rails:
        for x in range(FENCE_POSTS[0] + 2, FENCE_POSTS[-1]):
            v = h01(17, x // 5, rail)
            c.seth(x, rail, "woodLight" if v < 0.35 else "wood")
            c.seth(x, rail - 1, "woodDark")
            if h01(19, x, rail) < 0.08:
                c.seth(x, rail, "woodDark")       # a knot, a crack

    def post(px, tall):
        for hh in range(SAND, SAND + tall):
            c.seth(px, hh, "woodLight")
            c.seth(px + 1, hh, "wood" if hh > SAND + tall - 3 else "woodDark")
            if c.get(px + 2, c.r(hh))[3] == 0:
                c.im.set(px + 2, c.r(hh), ink)
        c.seth(px, SAND + tall, "ink")
        c.seth(px + 1, SAND + tall, "ink")
        if px - 1 >= 0 and c.get(px - 1, c.r(SAND + tall - 1))[3] == 0:
            c.seth(px - 1, SAND + tall - 1, "ink")

    for px in FENCE_POSTS:
        post(px, 11 if px in (FENCE_POSTS[0], FENCE_POSTS[-1]) else 10)
    for hh in range(SAND, SAND + 10):
        c.seth(FENCE_POSTS[0] - 1, hh, "ink")
    # Fix step 4b (R1): the apron's corner post (1464), its top cut square as the far one's; no rail runs past it.
    c.seth(APRON_CORNER, SAND + 11, "woodLight")
    c.seth(APRON_CORNER + 1, SAND + 11, "ink")
    c.seth(APRON_CORNER, SAND + 12, "ink")
    # The corner post at the far end: the yard's bound, a little taller, its top cut square.
    post(CORNER_POST, 11)
    c.seth(CORNER_POST, SAND + 11, "woodLight")
    c.seth(CORNER_POST + 1, SAND + 11, "ink")
    c.seth(CORNER_POST, SAND + 12, "ink")
    return c.im


# -------------------------------------------------------------------------------------------------- the site
# Step 3, layout A: six stakes round the larger ground (world 1442, 1470, 1481, 1504, 1517, 1543), a thin hemp cord at
# two thirds of their height, open at the bunkhouse door (1504 to 1517). The corners carry teal rag flags (the house's
# colour), the door's two stakes red ones (the butt's red), each flag 2 x 2 so it shows at phone size.
SW, SH = 103, 10
# (column, height, flag, the flag's first column from the stake: inward at the corners, away from the door at the door)
STAKES = ((0, 8, "teal", 2), (28, 6, None, 0), (39, 6, None, 0), (62, 7, "red", -2), (75, 7, "red", 2),
          (101, 8, "teal", -2))
DOOR = (62, 75)
FLAGS = {"teal": ("roofLight", "banner"), "red": ("tileLight", "tile")}


def site(frame):
    c = C(SW, SH)
    for (sx, tall, _, _) in STAKES:
        for hh in range(0, tall):
            c.seth(sx, hh, "woodLight")
            c.seth(sx + 1, hh, "wood" if hh < tall - 1 else "woodLight")
        c.seth(sx, tall, "plasterDim")          # the cut top, pale
        c.seth(sx + 1, tall, "plasterDim")
    if frame == 1:
        # Delivered on the bunkhouse's front, clear of the lord's lane and the door: the fence rails stacked (1484 to
        # 1499), a bundle of stakes leaning on them, a straw bale east of the door (1522 to 1529).
        for hh in range(0, 3):
            for x in range(42, 58):
                c.seth(x, hh, "woodLight" if hh == 2 else ("wood" if (x + 2 * hh) % 7 else "woodDark"))
            c.seth(42, hh, "woodLight")              # the rails' cut ends
            c.seth(57, hh, "soilLight")
        for hh in range(0, 6):
            c.seth(55 + hh // 3, hh, "woodLight")
            c.seth(57 + hh // 3, hh, "wood")
        # Fix step 4b (R8): three logs stacked east of the door (1522 to 1529), the upper ones set back, each log two
        # rows (its lit top, its shaded underside); on the stack's east face each log's cut end shows, a pale pixel
        # over a dark ring, so the three ends read as timber and never as a crate.
        for (x0, x1, hh0) in ((80, 87, 0), (80, 86, 2), (81, 85, 4)):
            for x in range(x0, x1 + 1):
                c.seth(x, hh0 + 1, "woodLight" if (x * 5 + hh0) % 7 else "wood")
                c.seth(x, hh0, "woodDark" if (x * 3 + hh0) % 5 else "soil")
            c.seth(x1 - 1, hh0 + 1, "strawLight")
            c.seth(x1, hh0 + 1, "plaster")
            c.seth(x1 - 1, hh0, "soilLight")
            c.seth(x1, hh0, "soil")
    rim(c)
    # After the ink edge (a cord and a chalk line have none, or they would read as a rail and a kerb). The cord from
    # stake to stake at two thirds of the lower stake's height, sagging a pixel in a short span and two
    # in a long one; a dark hemp, one pixel thin, so it reads as a line on the ground, never as a rail.
    for (ax, at, _, _), (bx, bt, _, _) in zip(STAKES, STAKES[1:]):
        if (ax, bx) == DOOR:
            continue                            # the door stays open
        hh0 = (2 * min(at, bt)) // 3
        span = bx - ax
        for x in range(ax + 2, bx):
            t = (x - ax) / float(span)
            sag = 0
            if 0.2 < t < 0.8:
                sag = 1
            if span > 20 and 0.35 < t < 0.65:
                sag = 2
            if not c.opaque(x, c.r(hh0 - sag)):  # behind the delivered timber
                c.seth(x, hh0 - sag, "soilLight" if (x + sag) % 5 else "strawLight")
    # Lime marks scratched on the ground at each stake's foot: the ground is marked out.
    for (sx, _, _, _) in STAKES:
        for dx in (-2, -1, 2, 3):
            if 0 <= sx + dx < SW and not c.opaque(sx + dx, c.r(0)):
                c.seth(sx + dx, 0, "plasterDim" if dx in (-1, 2) else "plaster")
    # The flags after the ink edge (a rag has none): two rows of two on the side away from the door or the ground.
    for (sx, tall, flag, off) in STAKES:
        if not flag:
            continue
        light, dark = FLAGS[flag]
        fx = sx + off
        for dx in (0, 1):
            c.seth(fx + dx, tall - 1, light)
            c.seth(fx + dx, tall - 2, dark)
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
    # step 4: the front butt, the one behind, the front one with the drill's arrow stuck in its heart
    "yardButt": lambda: strip([butt(), butt_behind(), butt(stuck=True)]),
    "yardKettle": lambda: strip([kettle(0), kettle(1), kettle(2)]),
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
