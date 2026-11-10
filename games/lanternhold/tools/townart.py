#!/usr/bin/env python3
"""Lanternhold art pass (look 2, stage 4; ART-look2.md section 15): the town's houses, repainted at the creatures'
level. Pure python on pixelart.py's Image; palette colours only; no randomness (hashes of the position), so a run
reproduces its files byte for byte. Called by tools/build-art.sh (house, houseB, houseC) and
tools/build-art-buildings.sh (bigHouse, tavern, market); the well through build-art.sh too.

  townart.py build <id> [<id> …] --out <Resources/Art>

Every id keeps its SPRITES.md size and its window glass where the layout's masks light it (night1 panes; the bars
between them are wood and stay dark). Albedo only: evenly lit daylight colours, the light from the upper left (lit
roof slope and left edges, a cast shadow under every eave, the right end a step darker), look 2's selective outline
(ink on the right side and at the ground).
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import pixelart as PA  # noqa: E402
import worldart as WA  # noqa: E402

col, h01 = WA.col, WA.h01

# roof ramps: the edge and the eave's underside, the deep shadow, the courses' shadow, the body, the light
TILE = ("woodDark", "woodDark", "wood", "tile", "tileLight")
SLATE = ("night1", "roofDeep", "roofDeep", "banner", "roofLight")
THATCH = ("soilDark", "soilDark", "soilLight", "straw", "strawLight")
TEAL = ("roofDeep", "banner", "roofLight")
RED = ("woodDark", "tile", "tileLight")
GREEN = ("leafDark", "leaf", "meadow")


def px(im, x, y, name):
    if 0 <= x < im.w and 0 <= y < im.h:
        im.set(x, y, col(name))


def rect(im, x0, y0, x1, y1, name):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            px(im, x, y, name)


def is_(im, x, y, name):
    return 0 <= x < im.w and 0 <= y < im.h and im.get(x, y) == col(name)


# --- roofs -------------------------------------------------------------------------------------------------------
def roof(im, top, bot, xl, xr, ramp, kind, seed, moss=True, mid=0.58, shade=7):
    """A roof slope between the rows top (the ridge cap) and bot (the eaves' underside); xl(y), xr(y) are its edges.
    kind: tile (courses of 4 px tiles), slate (3 px), thatch (combed strands, trimmed layers, a thick eave). The
    slope faces the light: its left part carries every highlight, the right part fewer, and a strip along the right
    edge (shade px wide) lies in shadow."""
    E, S, D, B, L = ramp
    tw = 3 if kind == "slate" else 4
    for y in range(top, bot + 1):
        a, b = xl(y), xr(y)
        ci, r = (y - top - 1) // 3, (y - top - 1) % 3
        jog = (h01(seed, ci, 99) - 0.5) * 0.07
        for x in range(a, b + 1):
            t = (x - a) / float(max(1, b - a)) + jog
            z = 2 if b - x < shade + int(jog * 30) else 0 if t < mid else 1
            if kind == "thatch":
                v = h01(seed, x, (y + (x % 2)) // 2)
                c = (L if v < 0.5 else B, L if v < 0.14 else D if v > 0.86 else B, D if v < 0.55 else B)[z]
                if (y - top) % 6 == 5 and h01(seed, x // 3, y) > 0.25:
                    c = (D, D, S)[z]
                if y <= top + 1:                                   # the ridge roll, its liggers crossed
                    c = ((D if (x + y) % 3 == 0 else L), (D if (x + y) % 3 == 0 else B), (S if (x + y) % 3 == 0 else D))[z]
                if y == bot - 2:
                    c = (L, B, D)[z]
                elif y == bot - 1:
                    c = (B, D, D)[z]
            else:
                sx = x + (ci % 2) * (tw // 2)
                joint, v = sx % tw == 0, h01(seed, ci, sx // tw)
                if y == top:
                    c = (L, L, B)[z]
                elif r == 0:
                    c = (D if joint and v > 0.5 else L, L if v < 0.45 else B, B)[z]
                elif r == 1:
                    c = (D if joint else L if v < 0.08 else B, D if joint or v > 0.9 else B, S if joint else D if v < 0.55 else B)[z]
                else:
                    c = (D, D, S)[z]
                if y == bot - 1:                                   # the tiles' rounded ends over the eave
                    c = S if joint else (L, B, D)[z]
            if moss and z == 2 and bot - 6 <= y <= bot - 2 and h01(seed, x // 2, y, 5) < 0.16:
                c = "leaf" if h01(seed, x, y, 6) < 0.5 else "leafDark"
            if x == a:
                c = L if y < bot else D
            elif x == b:
                c = "ink"
            elif x == b - 1:
                c = E
            if y == bot and a < x < b:
                c = E
            px(im, x, y, c)


def chimney(im, x0, x1, top, foot, seed):
    """A fieldstone chimney standing before the roof: a pale cap, a lit left edge, soot under the cap."""
    rect(im, x0, top + 2, x1, foot, "stoneLight")
    for y in range(top + 2, foot + 1):
        px(im, x0, y, "stonePale")
        px(im, x1 - 1, y, "stone")
        px(im, x1, y, "ink")
        for x in range(x0 + 1, x1 - 1):
            if (y - top) % 3 == 0 and h01(seed, x, y) < 0.8:
                px(im, x, y, "stone")
            elif (x + ((y - top) // 3) * 2) % 4 == 0 and (y - top) % 3 != 0:
                px(im, x, y, "stone")
    rect(im, x0 + 1, top + 2, x1 - 1, top + 2, "stoneMid")           # soot
    rect(im, x0 - 1, top, x1 + 1, top, "stonePale")
    rect(im, x0 - 1, top + 1, x1 + 1, top + 1, "stoneMid")
    px(im, x0 - 1, top + 1, "stoneLight")
    px(im, x1 + 1, top, "stoneLight")
    px(im, x1 + 1, top + 1, "ink")
    rect(im, x0, foot + 1, x1, foot + 1, "ink")                      # the flashing's shadow on the roof


# --- walls -------------------------------------------------------------------------------------------------------
def plaster(im, x0, y0, x1, y1, seed, shade_from=None, eave=2):
    """A lime-washed wall: the eave's cast shadow on its top rows, pale patches where the wash is fresh, stains
    toward the foot, the right end (from shade_from on) a step darker."""
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            c = "plaster"
            v = h01(seed, x // 4, y)
            if v < 0.1 and y > y0 + eave + 1:
                c = "parchment"
            if y - y0 < eave or (y1 - y < 2 and h01(seed, x, y, 3) < 0.45) or (v > 0.95):
                c = "plasterDim"
            if shade_from is not None and x >= shade_from and (x > shade_from or y % 2):
                c = "plasterDim" if c != "parchment" else "plaster"
            px(im, x, y, c)


def post(im, x, y0, y1, w=2):
    """A timber post: its left edge lit."""
    rect(im, x, y0, x + w - 1, y1, "woodDark")
    rect(im, x, y0, x, y1, "wood")


def beam(im, x0, x1, y, h=2, lit=True):
    """A timber beam: its top edge lit."""
    rect(im, x0, y, x1, y + h - 1, "woodDark")
    if lit:
        rect(im, x0, y, x1, y, "wood")


def brace(im, x, y, dx, n):
    """A diagonal brace of n pixels going down from (x, y), dx the step per row."""
    for i in range(n):
        px(im, x + i * dx, y + i, "woodDark")


def window(im, x, y, w, h, shutters=None, box=False, sill=True, bars=True):
    """A window whose glass is the box x, y, w, h (night1; the layout's mask lights it): an oak frame, a cross of
    glazing bars, open shutters (a ramp dark, mid, light) and a flower box or a sill under it."""
    rect(im, x - 1, y - 1, x + w, y + h, "woodDark")
    rect(im, x - 1, y - 1, x + w, y - 1, "wood")
    rect(im, x, y, x + w - 1, y + h - 1, "night1")
    if bars:
        rect(im, x + w // 2, y, x + w // 2, y + h - 1, "woodDark")
        rect(im, x, y + (h - 1) // 2, x + w - 1, y + (h - 1) // 2, "woodDark")
    if shutters:
        d, m, l = shutters
        for sx in (x - 4, x + w + 1):
            rect(im, sx, y - 1, sx + 2, y + h, m)
            rect(im, sx, y - 1, sx, y + h, l)
            rect(im, sx + 2, y - 1, sx + 2, y + h, d)
            rect(im, sx, y + h, sx + 2, y + h, d)
            px(im, sx + 1, y + 1, d)
            px(im, sx + 1, y + h - 2, d)
    if box:                                                          # flowers over a wooden box
        for i, xx in enumerate(range(x - 1, x + w + 1)):
            px(im, xx, y + h, ("leaf", "dusk", "meadow", "dawnRose", "leaf", "meadow", "dusk")[i % 7])
        rect(im, x - 1, y + h + 1, x + w, y + h + 1, "woodLight")
        px(im, x + w, y + h + 1, "wood")
        rect(im, x - 1, y + h + 2, x + w, y + h + 2, "woodDark")
    elif sill:
        rect(im, x - 2, y + h, x + w + 1, y + h, "woodLight")
        px(im, x + w + 1, y + h, "wood")


def door(im, x0, y0, x1, y1, arch=False):
    """A plank door in an oak frame: lit plank edges, two iron bands, a ring."""
    rect(im, x0 - 1, y0 - 1, x1 + 1, y1, "woodDark")
    rect(im, x0 - 1, y0 - 1, x1 + 1, y0 - 1, "wood")
    for x in range(x0, x1 + 1):
        k = (x - x0) % 4
        rect(im, x, y0, x, y1, ("woodLight", "wood", "wood", "woodDark")[k])
    if arch:
        px(im, x0, y0, "woodDark")
        px(im, x1, y0, "woodDark")
    for y in (y0 + 3, y1 - 4):
        rect(im, x0, y, x1, y, "stoneMid")
        px(im, x0 + 1, y, "stoneLight")
        px(im, x1 - 1, y, "stoneLight")
    px(im, x1 - 1, (y0 + y1) // 2 + 1, "stonePale")
    px(im, x1 - 1, (y0 + y1) // 2 + 2, "stoneMid")


def fieldstone(im, x0, y0, x1, y1, seed):
    """A plinth of field stones: a lit top course, dark joints, a stone here and there paler."""
    for y in range(y0, y1 + 1):
        k = (y - y0) // 2
        for x in range(x0, x1 + 1):
            sx = x + k * 3
            v = h01(seed, k, sx // 5)
            c = "stoneLight" if v < 0.25 else "stone"
            if (y - y0) % 2 == 1:
                c = "stone" if v < 0.25 else "stoneMid"
            if sx % 5 == 0:
                c = "stoneDark"
            px(im, x, y, c)
    rect(im, x0, y0, x1, y0, "stoneLight")
    for x in range(x0, x1 + 1):
        if (x + 0) % 5 == 0:
            px(im, x, y0, "stone")


def vine(im, x, y0, y1, seed, w=3):
    """A climbing vine up a corner."""
    for y in range(y0, y1 + 1):
        for i in range(w + (1 if h01(seed, y) < 0.4 else 0)):
            v = h01(seed, x + i, y)
            if v < 0.7:
                px(im, x + i, y, "meadow" if v < 0.2 else "leaf" if v < 0.5 else "leafDark")


def woodpile(im, x0, y1, cols, rows):
    """Split logs stacked end on: pale cut faces with dark rings."""
    for r in range(rows):
        for c in range(cols):
            x, y = x0 + c * 2 + (r % 2), y1 - r * 2
            px(im, x, y - 1, "woodLight"); px(im, x + 1, y - 1, "wood")
            px(im, x, y, "wood"); px(im, x + 1, y, "woodDark")


def barrel(im, x0, y1, w=5, h=7):
    for y in range(y1 - h + 1, y1 + 1):
        for x in range(x0, x0 + w):
            px(im, x, y, "woodLight" if x == x0 else "woodDark" if x == x0 + w - 1 else "wood")
    for y in (y1 - h + 2, y1 - 1):
        rect(im, x0, y, x0 + w - 1, y, "stoneMid")
        px(im, x0 + 1, y, "stoneLight")
    rect(im, x0 + 1, y1 - h + 1, x0 + w - 2, y1 - h + 1, "woodLight")


# --- the cottages (64x46): house (red tiles), houseB (teal slate), houseC (thatch, a dormer) -------------------------
def cottage(kind):
    im = PA.Image(64, 46)
    seed = {"house": 11, "houseB": 23, "houseC": 37}[kind]
    # the walls: cols 3-60, rows 23-44; the plinth's field stones under an oak sill beam
    plaster(im, 3, 23, 60, 40, seed, shade_from=55)
    fieldstone(im, 3, 42, 60, 44, seed)
    beam(im, 3, 60, 23, h=1, lit=False)
    beam(im, 3, 60, 40)
    for x in (3, 25, 37, 59):
        post(im, x, 23, 41)
    brace(im, 24, 26, -1, 5)
    brace(im, 39, 26, 1, 4)
    brace(im, 5, 39, 1, 0)
    sh = {"house": TEAL, "houseB": RED, "houseC": GREEN}[kind]
    window(im, 11, 32, 5, 6, shutters=sh, box=kind != "houseB", sill=True)
    window(im, 46, 32, 5, 6, shutters=sh, box=kind == "house", sill=True)
    door(im, 28, 29, 35, 43, arch=True)
    rect(im, 26, 43, 37, 43, "stoneLight")                           # the door step
    rect(im, 26, 44, 37, 44, "stone")
    px(im, 37, 43, "stone")
    # what stands at the wall
    if kind == "house":
        woodpile(im, 54, 41, 2, 3)
        vine(im, 2, 25, 41, seed)
    elif kind == "houseB":
        barrel(im, 20, 43)
        vine(im, 57, 24, 36, seed, w=4)
    else:
        rect(im, 19, 40, 24, 40, "woodLight")                        # a bench by the door
        px(im, 19, 41, "woodDark"); px(im, 24, 41, "woodDark"); px(im, 19, 42, "woodDark"); px(im, 24, 42, "woodDark")
        vine(im, 2, 30, 41, seed, w=2)
        woodpile(im, 55, 41, 1, 2)
    # the outline: the right wall and the ground
    rect(im, 61, 23, 61, 44, "ink")
    rect(im, 2, 45, 61, 45, "ink")
    # the roof: hipped, its eaves over the walls
    xl = lambda y: max(0, int(round(13 - (y - 4) * 13 / 17.0)))      # noqa: E731
    xr = lambda y: 63 - xl(y)                                        # noqa: E731
    ramp, rk = {"house": (TILE, "tile"), "houseB": (SLATE, "slate"), "houseC": (THATCH, "thatch")}[kind]
    roof(im, 4, 22, xl, xr, ramp, rk, seed, moss=kind != "houseB")
    chimney(im, 45, 50, 0, 9, seed)
    if kind == "houseC":                                             # the dormer: an eyebrow of thatch over a small window
        E, S, D, B, L = THATCH
        for y, (a, b) in zip(range(6, 10), ((27, 29), (25, 31), (24, 32), (23, 33))):
            for x in range(a, b + 1):
                px(im, x, y, L if x < 28 else B if x < 31 else D)
        rect(im, 23, 10, 33, 10, D)
        rect(im, 24, 10, 32, 10, "woodDark")
        rect(im, 25, 11, 31, 13, "plaster")
        rect(im, 25, 11, 25, 13, "woodDark"); rect(im, 31, 11, 31, 13, "woodDark")
        rect(im, 27, 11, 29, 12, "night1")
        rect(im, 26, 13, 30, 13, "woodLight")
        rect(im, 25, 14, 31, 14, "woodDark")
    return im


def dormer(im, gx, gy, ramp):
    """A small gabled dormer whose glass is the box gx, gy, 3, 2: a cap in the roof's ramp, a plaster face."""
    E, S, D, B, L = ramp
    for y, (a, b) in zip(range(gy - 5, gy - 1), ((gx, gx + 2), (gx - 2, gx + 4), (gx - 3, gx + 5), (gx - 4, gx + 6))):
        for x in range(a, b + 1):
            px(im, x, y, L if x < gx + 1 else B if x < gx + 4 else D)
        px(im, b + 1, y, "ink")
    rect(im, gx - 4, gy - 1, gx + 6, gy - 1, D)
    rect(im, gx - 3, gy - 1, gx + 5, gy - 1, "woodDark")
    rect(im, gx - 2, gy, gx + 4, gy + 2, "plaster")
    rect(im, gx - 2, gy, gx - 2, gy + 2, "woodDark")
    rect(im, gx + 4, gy, gx + 4, gy + 2, "woodDark")
    rect(im, gx, gy, gx + 2, gy + 1, "night1")
    rect(im, gx - 1, gy + 2, gx + 3, gy + 2, "woodLight")
    rect(im, gx - 2, gy + 3, gx + 4, gy + 3, "woodDark")
    rect(im, gx + 5, gy, gx + 5, gy + 3, "ink")


def jetty(im, x0, x1, y):
    """The beam of an overhanging storey (rows y, y + 1) and its joist ends in the shadow under it (row y + 2)."""
    beam(im, x0, x1, y)
    rect(im, x0, y + 2, x1, y + 2, "ink")
    for x in range(x0 + 1, x1, 4):
        px(im, x, y + 2, "woodLight")
        px(im, x + 1, y + 2, "wood")


def rubble(im, x0, y0, x1, y1, seed, eave=2):
    """A wall of coursed grey stone: courses 4 rows high, their stones 5 to 8 px, lit top edges, dark joints, a
    cast shadow on its top rows, a stone here and there paler or mossy toward the foot."""
    for y in range(y0, y1 + 1):
        k, r = (y - y0) // 4, (y - y0) % 4
        for x in range(x0, x1 + 1):
            sx = x + k * 3 + int(h01(seed, k) * 5)
            n = sx // 7
            v = h01(seed, k, n)
            edge = sx % 7 == 0 or (v < 0.3 and sx % 7 == 4)
            c = "stone" if v < 0.7 else "stoneMid"
            if r == 0:
                c = "stoneLight" if v < 0.7 else "stone"
                if v < 0.1:
                    c = "stonePale"
            elif r == 3:
                c = "stoneMid" if v < 0.7 else "stoneDark"
                if h01(seed, x, y, 2) < 0.3:
                    c = "stoneDark"
            if edge:
                c = "stoneDark" if r else "stoneMid"
            if y - y0 < eave:
                c = {"stoneLight": "stoneMid", "stonePale": "stone", "stone": "stoneMid"}.get(c, c)
            if y1 - y < 3 and h01(seed, x // 2, y, 7) < 0.12:
                c = "leafDark"
            px(im, x, y, c)


def stone_window(im, x, y, w, h, vbars):
    """A window in a stone wall whose glass is the box x, y, w, h: a pale lintel and sill, an oak frame."""
    rect(im, x - 1, y - 1, x + w, y + h, "woodDark")
    rect(im, x, y, x + w - 1, y + h - 1, "night1")
    for b in vbars:
        rect(im, x + b, y, x + b, y + h - 1, "woodDark")
    rect(im, x, y + (h - 1) // 2, x + w - 1, y + (h - 1) // 2, "woodDark")
    rect(im, x - 2, y - 2, x + w + 1, y - 2, "stonePale")
    px(im, x + w + 1, y - 2, "stoneLight")
    rect(im, x - 2, y + h + 1, x + w + 1, y + h + 1, "stonePale")
    rect(im, x - 1, y + h + 2, x + w + 1, y + h + 2, "stoneDark")


# --- the big house (72x56): two storeys, the upper one jettied, a hipped tile roof with a dormer and two chimneys ----
def big_house():
    im = PA.Image(72, 56)
    seed = 53
    # the ground floor: cols 9-62, rows 38-51 over a plinth
    plaster(im, 9, 38, 62, 51, seed, shade_from=57)
    fieldstone(im, 9, 52, 62, 54, seed)
    beam(im, 9, 62, 50)
    for x in (9, 29, 41, 61):
        post(im, x, 38, 51)
    window(im, 16, 42, 5, 5, shutters=TEAL, box=True)
    window(im, 50, 42, 5, 5, shutters=TEAL, box=True)
    door(im, 32, 41, 39, 53, arch=True)
    rect(im, 30, 53, 41, 53, "stoneLight")
    rect(im, 30, 54, 41, 54, "stone")
    px(im, 41, 53, "stone")
    for x in range(32, 40):                                          # the door's lintel carved with a lit edge
        px(im, x, 39, "woodLight" if x % 2 == 0 else "wood")
    woodpile(im, 57, 51, 2, 3)
    barrel(im, 24, 53, w=5, h=6)
    vine(im, 8, 40, 51, seed, w=3)
    rect(im, 63, 38, 63, 54, "ink")
    rect(im, 8, 55, 63, 55, "ink")
    # the upper storey: cols 5-66, rows 23-34, its beam and joist ends over the ground floor
    plaster(im, 5, 23, 66, 34, seed + 1, shade_from=61)
    beam(im, 5, 66, 23, h=1, lit=False)
    for x in (5, 19, 35, 51, 65):
        post(im, x, 23, 34)
    brace(im, 17, 25, -1, 10)
    brace(im, 54, 25, 1, 10)
    brace(im, 8, 25, 1, 0)
    window(im, 26, 27, 5, 5, shutters=TEAL)
    window(im, 41, 27, 5, 5, shutters=TEAL)
    jetty(im, 5, 66, 35)
    rect(im, 67, 23, 67, 37, "ink")
    vine(im, 4, 29, 34, seed + 2, w=2)
    # the roof and what stands on it
    xl = lambda y: max(0, int(round(10 - (y - 5) * 10 / 16.0)))      # noqa: E731
    xr = lambda y: 71 - xl(y)                                        # noqa: E731
    roof(im, 5, 22, xl, xr, TILE, "tile", seed, shade=8)
    chimney(im, 16, 21, 0, 9, seed)
    chimney(im, 48, 53, 0, 10, seed + 3)
    dormer(im, 35, 14, TILE)
    return im


# --- the tavern (90x56): a stone ground floor, a jettied half-timbered storey, a tile roof with a front gable, a sign
def tavern():
    im = PA.Image(90, 56)
    seed = 71
    # the ground floor of grey stone: cols 9-74, rows 38-54
    rubble(im, 9, 38, 74, 54, seed)
    stone_window(im, 15, 42, 8, 5, (2, 5))
    stone_window(im, 56, 42, 8, 5, (2, 5))
    for i, x in enumerate(range(34, 46)):                            # the door's arch of pale stones
        px(im, x, 39 if 1 < i < 10 else 40, "stonePale" if i % 3 else "stoneLight")
        px(im, x, 40 if 1 < i < 10 else 41, "stoneLight" if 1 < i < 10 else "stonePale")
    door(im, 36, 41, 43, 54, arch=True)
    rect(im, 34, 54, 45, 54, "stoneLight")
    # the wall lantern beside the door: an iron bracket and cage, the glass at col 32, rows 44-45 (the layout's mask)
    rect(im, 31, 42, 33, 42, "ink"); px(im, 32, 41, "ink"); rect(im, 30, 41, 30, 41, "ink")
    rect(im, 31, 43, 33, 46, "ink")
    rect(im, 32, 44, 32, 45, "night1")
    px(im, 31, 43, "stoneMid")
    # barrels left of the door, a bench under the right window
    barrel(im, 23, 54, w=5, h=7)
    barrel(im, 28, 54, w=5, h=6)
    rect(im, 54, 51, 66, 51, "woodLight"); rect(im, 54, 52, 66, 52, "woodDark")
    for x in (55, 65):
        rect(im, x, 53, x, 54, "woodDark")
    vine(im, 9, 41, 54, seed, w=3)
    rect(im, 75, 38, 75, 54, "ink")
    rect(im, 8, 55, 75, 55, "ink")
    # the upper storey: cols 5-78, rows 23-33
    plaster(im, 5, 23, 78, 33, seed + 1, shade_from=73)
    beam(im, 5, 78, 23, h=1, lit=False)
    for x in (5, 21, 35, 50, 62):
        post(im, x, 23, 33)
    rect(im, 78, 23, 78, 33, "woodDark")
    brace(im, 24, 25, 1, 9); brace(im, 33, 25, -1, 9)
    brace(im, 53, 25, 1, 8); brace(im, 60, 25, -1, 8)
    window(im, 11, 26, 5, 5, shutters=RED)
    window(im, 41, 26, 5, 5, shutters=RED)
    window(im, 69, 26, 5, 5, shutters=RED)
    jetty(im, 5, 78, 34)
    rect(im, 5, 37, 78, 37, "ink")
    for x in range(8, 77, 12):                                       # carved brackets under the jetty
        px(im, x, 37, "wood"); px(im, x + 1, 37, "woodDark")
    rect(im, 79, 23, 79, 36, "ink")
    # the roof: hipped at the left, a front gable at the right
    xl = lambda y: max(1, int(round(16 - (y - 6) * 15 / 16.0)))      # noqa: E731
    xr = lambda y: min(82, int(round(66 + (y - 6) * 16 / 16.0)))     # noqa: E731
    roof(im, 6, 22, xl, xr, TILE, "tile", seed, shade=8)
    chimney(im, 28, 34, 0, 10, seed)
    E, S, D, B, L = TILE
    ax = 62
    for y in range(8, 22):                                           # the gable: barge boards, studs on plaster
        hw = y - 8 + 1
        for x in range(ax - hw - 1, ax + hw + 2):
            d = x - ax
            if abs(d) > hw - 1:
                c = (L if abs(d) > hw else B) if d < 0 else (D if abs(d) <= hw else "ink")
            else:
                c = "plasterDim" if (hw - abs(d) < 3 or y < 12) else "plaster"
                if d % 4 == 0:
                    c = "woodDark"
                if y == 15 or y == 21:
                    c = "woodDark" if y == 15 else "wood"
            px(im, x, y, c)
    px(im, ax, 7, L); px(im, ax + 1, 7, "ink")
    rect(im, ax - 1, 17, ax + 1, 19, "night1")                       # a dark loft hatch (never lit)
    rect(im, ax - 2, 16, ax + 2, 16, "woodDark"); rect(im, ax - 2, 20, ax + 2, 20, "woodLight")
    rect(im, ax - 2, 17, ax - 2, 19, "woodDark"); rect(im, ax + 2, 17, ax + 2, 19, "woodDark")
    # the sign: an iron bracket, two chains, a board with a gold tankard
    rect(im, 76, 39, 88, 39, "ink")
    for i in range(4):
        px(im, 76 + i, 43 - i, "ink")
    px(im, 82, 40, "stoneMid"); px(im, 87, 40, "stoneMid")
    rect(im, 80, 41, 89, 49, "ink")
    rect(im, 81, 42, 88, 48, "wood")
    rect(im, 81, 42, 88, 42, "woodLight"); rect(im, 81, 42, 81, 48, "woodLight")
    rect(im, 81, 48, 88, 48, "woodDark"); rect(im, 88, 43, 88, 48, "woodDark")
    rect(im, 83, 44, 85, 47, "gold")
    rect(im, 83, 44, 83, 47, "strawLight")
    rect(im, 83, 43, 85, 43, "parchment")
    px(im, 86, 45, "gold"); px(im, 86, 46, "gold"); px(im, 85, 47, "straw")
    return im


# --- the market (90x40): three stalls under striped awnings ------------------------------------------------------------
CREAM = ("plaster", "parchment", "parchment")


def heap(im, cx, y, n, ramp):
    """A mound of round wares on the counter: n wide at its foot (row y), its top left lit."""
    d, m, l = ramp
    for r, cut in enumerate((0, 1, 3)):
        w = n - 2 * cut
        for i in range(max(0, w)):
            x = cx - n // 2 + cut + i
            px(im, x, y - r, l if (i + r) % 3 == 0 and i < w * 0.6 else d if i >= w - 1 or (i + r) % 3 == 2 else m)


def stall(im, x0, ramp, kind, seed):
    d, m, l = ramp
    # the frame and the dark cloth behind the wares
    rect(im, x0 + 3, 14, x0 + 26, 27, "soilDark")
    rect(im, x0 + 3, 14, x0 + 26, 15, "ink")                         # the awning's cast shadow
    for x in range(x0 + 6, x0 + 25, 4):
        rect(im, x, 16, x, 27, "woodDark")
    for xx in (x0 + 3, x0 + 25):
        rect(im, xx, 14, xx + 1, 39, "wood")
        rect(im, xx, 16, xx, 39, "woodLight")
        rect(im, xx + 1, 14, xx + 1, 39, "woodDark")
    rect(im, x0 + 27, 14, x0 + 27, 39, "ink")
    rect(im, x0 + 2, 14, x0 + 2, 27, "ink")
    # the awning: stripes 3 px wide, the canopy's top lit, a crease where the valance drops, scallops
    for y in range(3, 14):
        a = x0 + (3 if y < 4 else 2 if y < 8 else 1 if y < 11 else 0)
        b = x0 + 28 - (a - x0)
        for x in range(a, b + 1):
            cream = ((x - x0) // 3) % 2 == 0
            rr = CREAM if cream else ramp
            k = 2 if y < 5 else 1
            if y == 10:
                k = 0
            if b - x < 4 and k > 0 and y < 11:
                k -= 1
            if y >= 11 and b - x < 3:
                k = 0
            if y == 13:
                if (x - x0) % 3 == 1:
                    continue
                k = 0 if (x - x0) % 3 == 2 else 1
            px(im, x, y, rr[k])
        if y < 13:
            px(im, a - 1, y, "ink"); px(im, b + 1, y, "ink")
    rect(im, x0 + 3, 2, x0 + 25, 2, "ink")
    # what hangs from the canopy
    hang = {"fruit": ((8, "strawLight", "straw", 5), (19, "leaf", "leafLight", 4)),
            "bread": ((13, "leaf", "leafLight", 5), (21, "strawLight", "straw", 4)),
            "cloth": ((22, "dusk", "dawnRose", 7), (9, "roofLight", "banner", 5))}[kind]
    for hx, c1, c2, n in hang:
        for i in range(n):
            px(im, x0 + hx, 16 + i, c1 if i % 2 == 0 else c2)
        if kind == "cloth":
            rect(im, x0 + hx - 1, 17, x0 + hx - 1, 15 + n, c2 if c2 != "dawnRose" else "dusk")
    # the counter: a lit top plank, a plank front
    rect(im, x0 + 1, 28, x0 + 27, 28, "woodLight")
    rect(im, x0 + 1, 29, x0 + 27, 29, "woodDark")
    for x in range(x0 + 2, x0 + 27):
        k = (x - x0) % 4
        rect(im, x, 30, x, 39, ("woodDark", "woodLight", "wood", "wood")[k])
    rect(im, x0 + 2, 30, x0 + 26, 30, "woodDark")                    # the top plank's shadow
    rect(im, x0 + 1, 28, x0 + 1, 29, "wood"); px(im, x0 + 28, 28, "ink"); px(im, x0 + 28, 29, "ink"); px(im, x0, 28, "ink"); px(im, x0, 29, "ink")
    # the wares
    if kind == "fruit":
        rect(im, x0 + 5, 26, x0 + 12, 27, "strawLight"); rect(im, x0 + 5, 27, x0 + 12, 27, "straw")
        heap(im, x0 + 9, 25, 7, ("tile", "dusk", "dawnRose"))
        rect(im, x0 + 15, 26, x0 + 22, 27, "strawLight"); rect(im, x0 + 15, 27, x0 + 22, 27, "straw")
        heap(im, x0 + 19, 25, 7, ("leaf", "meadow", "leafLight"))
    elif kind == "bread":
        heap(im, x0 + 9, 27, 9, ("soilLight", "straw", "strawLight"))
        heap(im, x0 + 20, 27, 7, ("leafDark", "leaf", "leafLight"))
        px(im, x0 + 15, 27, "strawLight"); px(im, x0 + 16, 27, "straw")
    else:
        for i, (c1, c2) in enumerate((("banner", "roofLight"), ("parchment", "plaster"), ("dusk", "dawnRose"), ("straw", "strawLight"))):
            y = 27 - i * 2
            rect(im, x0 + 6 + (i % 2), y - 1, x0 + 12 + (i % 2), y, c1)
            rect(im, x0 + 6 + (i % 2), y - 1, x0 + 12 + (i % 2), y - 1, c2)
            px(im, x0 + 12 + (i % 2), y, "ink")
        for bx, hh in ((16, 4), (20, 5)):
            rect(im, x0 + bx, 28 - hh, x0 + bx + 2, 27, "tile")
            rect(im, x0 + bx, 28 - hh, x0 + bx, 27, "tileLight")
            px(im, x0 + bx + 2, 27, "woodDark"); px(im, x0 + bx + 1, 28 - hh, "woodDark")


def crate(im, x0, y1, w=6, h=6):
    rect(im, x0, y1 - h + 1, x0 + w - 1, y1, "wood")
    rect(im, x0, y1 - h + 1, x0 + w - 1, y1 - h + 1, "woodLight")
    rect(im, x0, y1 - h + 1, x0, y1, "woodLight")
    rect(im, x0 + w - 1, y1 - h + 2, x0 + w - 1, y1, "woodDark")
    rect(im, x0 + 1, y1, x0 + w - 1, y1, "woodDark")
    for i in range(1, min(w, h) - 1):
        px(im, x0 + i, y1 - h + 1 + i, "woodDark")


def market():
    im = PA.Image(90, 40)
    stall(im, 1, ("tile", "dusk", "dawnRose"), "fruit", 5)
    stall(im, 31, TEAL, "bread", 6)
    stall(im, 61, ("soilLight", "straw", "strawLight"), "cloth", 7)
    crate(im, 27, 39, w=6, h=6)
    barrel(im, 56, 39, w=6, h=7)
    crate(im, 84, 39, w=6, h=5)
    return im


# --- the well (18x20): a shingled roof on two posts, a windlass, rope and bucket, a ring of stones -------------------
def well():
    im = PA.Image(18, 20)
    E, S, D, B, L = TILE
    for y, (a, b) in zip(range(0, 5), ((5, 12), (3, 14), (2, 15), (1, 16), (0, 17))):
        for x in range(a, b + 1):
            c = L if y == 0 else (D if (x + y) % 4 == 0 else L if x < 8 and (x + y) % 4 == 2 else B)
            if b - x < 3:
                c = D if c != L else B
            px(im, x, y, c)
        px(im, a, y, L); px(im, b, y, "ink")
    rect(im, 0, 4, 17, 4, E); px(im, 17, 4, "ink")
    for x in (3, 13):
        rect(im, x, 5, x + 1, 12, "wood"); rect(im, x, 6, x, 12, "woodLight"); rect(im, x + 1, 5, x + 1, 12, "woodDark")
    rect(im, 5, 7, 12, 7, "woodLight"); rect(im, 5, 8, 12, 8, "woodDark")
    px(im, 15, 7, "stoneMid"); px(im, 15, 8, "stoneMid"); px(im, 16, 8, "stoneMid")   # the crank
    rect(im, 9, 9, 9, 10, "strawLight")
    rect(im, 8, 11, 10, 12, "wood"); px(im, 8, 11, "woodLight"); px(im, 10, 12, "woodDark"); px(im, 8, 12, "stoneMid"); px(im, 9, 12, "stoneMid")
    rect(im, 1, 13, 16, 13, "stonePale"); px(im, 16, 13, "stoneLight")
    rect(im, 2, 12, 15, 12, "stoneDark")
    rect(im, 8, 12, 10, 12, "wood"); px(im, 10, 12, "woodDark")
    for y in range(14, 19):
        k = (y - 14) // 2
        for x in range(1, 17):
            sx = x + k * 2
            c = ("stoneLight", "stone")[(y - 14) % 2] if k < 2 else "stoneMid"
            if sx % 5 == 0:
                c = "stoneDark"
            if x >= 14:
                c = {"stoneLight": "stone", "stone": "stoneMid"}.get(c, c)
            px(im, x, y, c)
    rect(im, 1, 14, 1, 17, "stonePale")
    px(im, 2, 18, "leafDark"); px(im, 3, 18, "leaf"); px(im, 12, 18, "leafDark")
    rect(im, 17, 13, 17, 18, "ink")
    rect(im, 1, 19, 17, 19, "ink")
    return im


BUILD = {"house": lambda: cottage("house"), "houseB": lambda: cottage("houseB"), "houseC": lambda: cottage("houseC"),
         "bigHouse": big_house, "tavern": tavern, "market": market, "well": well}



def main():
    a = sys.argv[1:]
    if len(a) < 4 or a[0] != "build" or "--out" not in a:
        raise SystemExit(__doc__)
    out = a[a.index("--out") + 1]
    for name in a[1:a.index("--out")]:
        im = BUILD[name]()
        PA.write_png(os.path.join(out, name + ".png"), im)
        print("wrote %s.png %dx%d" % (name, im.w, im.h))


if __name__ == "__main__":
    main()
