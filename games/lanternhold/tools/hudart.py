#!/usr/bin/env python3
"""Lanternhold: the small kit shown above the lord (HUD.md sections 2 and 3, the lantern moment and the gold at the lord).

Rule 2 of HUD.md holds for every piece: drawn on the world's pixel grid (one art pixel is one game pixel, never
scaled by anything but the world's own scale), from the shared palette, bone with an even dark edge in ink, no plate,
no parchment, no smooth shape, no shadow, no system type. The pieces are interface art: the stage lane draws them
unlit (shade 1) over the dimmed world, so they read the same on noon sky, dusk and night.

Sprites (each a horizontal strip of equal frames, AtlasBuilder.splitFrames cuts it):

  hudFigures   7x9, 12 frames: 0 1 2 3 4 5 6 7 8 9 + -   a hand-cut, heavy ledger numeral: thick downstrokes, thin
               joins, a flat-topped 3, a crossed 7, a flagged 1 on its foot. Tabular: every figure advances 6 game
               pixels, so the dark edges of neighbours overlap by one pixel and a ticking number never jumps.
  hudArrow     8x9, 2 frames: up, down (the change notes of HUD.md section 3; they stand like a figure)
  hudCoin      9x9: the small coin (one; PAY.md), the row's gold sign
  hudCoinTen   11x11: the big coin (ten), struck with the Roman X
  hudHollow    9x9, 2 frames: a hollow of the tally board, empty and holding a small coin (no ink edge: it is cut
               into the board's wood, which the world lane draws)
  hudHollowTen 11x11, 2 frames: the same for the big coin
  hudFace      9x9, 4 frames: glad, even, grim, unrest; a townsman's head in his hood (FACE_STYLE "hood"; the
               rivals "cap", a head in profile, and "disc", the first round face, stay buildable with --face)
  hudDawn      11x9: the dawn sign, a half sun on the horizon; the day line is this sign and the day's number
  hudPeople    13x9: two heads and shoulders, one a step behind the other
  hudGear      10x10: the gear in the corner (opens the pause sheet)

The row of the lantern moment is 9 game pixels high (figures, coin, face, people); the big coin and its hollow are
board and flight pieces only.

  hudart.py build <id> [--out DIR] [--face hood|cap|disc]   writes DIR/<id>.png (default games/lanternhold/Resources/Art)
  hudart.py list                     the ids
  hudart.py advance                  the figure advance and the row's spacing, for the stage lane

Pure python 3 (pixelart.py's PNG and palette code), deterministic, well under a second.
"""
import argparse
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from pixelart import Image, Palette, write_png, DEFAULT_PALETTE  # noqa: E402

ADVANCE = 6      # game pixels from one figure to the next (the 1-px edges overlap)
GAP = 1          # game pixels between a sign's edge and its figures' edge (edges touching counts as 0)
SPACE = 5        # game pixels between two groups of the row (coin+figures, face, people+figures)

LEGEND = {
    "X": "parchment",   # bone
    "x": "plaster",     # bone in shade (the far figure of the people, the coin hollow's lip)
    "i": "ink",         # the dark edge and the features
    "g": "gold",
    "h": "fireGold",    # a coin's lit rim
    "w": "fireWhite",   # one glint
    "s": "straw",       # a coin's shaded rim and struck ring
    "d": "woodLight",   # the deepest shade of gold
    "k": "woodDark",    # a hollow's shadowed wall
    "K": "soilDark",    # a hollow's floor
    "l": "woodLight",   # a hollow's lit lower wall
    "r": "tileLight",   # unrest's flush
    "R": "tile",
    "c": "banner",      # a townsman's hood, the realm's blue cloth
    "C": "roofDeep",    # the hood in shade
    "m": "crimsonLight",  # unrest's hood, red-brown
    "M": "crimson",
    "p": "leaf",        # the cap of the second rival
    "P": "leafDark",
}

# --- the figures, 5x7 bone bodies; the ink edge is added around them ------------------------------------------------
FIG_HAND = {
    "0": [".XXX.",
          "XX.XX",
          "XX.XX",
          "XX.XX",
          "XX.XX",
          "XX.XX",
          ".XXX."],
    "1": ["..XX.",
          ".XXX.",
          "..XX.",
          "..XX.",
          "..XX.",
          "..XX.",
          ".XXXX"],
    "2": [".XXX.",
          "XX.XX",
          "...XX",
          "..XX.",
          ".XX..",
          "XX...",
          "XXXXX"],
    "3": ["XXXXX",
          "...XX",
          "..XX.",
          ".XXX.",
          "...XX",
          "...XX",
          "XXXX."],
    "4": ["...XX",
          "..XXX",
          ".X.XX",
          "XX.XX",
          "XXXXX",
          "...XX",
          "...XX"],
    "5": ["XXXXX",
          "XX...",
          "XXXX.",
          "...XX",
          "...XX",
          "...XX",
          "XXXX."],
    "6": ["..XX.",
          ".XX..",
          "XX...",
          "XXXX.",
          "XX.XX",
          "XX.XX",
          ".XXX."],
    "7": ["XXXXX",
          "...XX",
          "..XX.",
          ".XXXX",
          ".XX..",
          ".XX..",
          ".XX.."],
    "8": [".XXX.",
          "XX.XX",
          "XX.XX",
          ".XXX.",
          "XX.XX",
          "XX.XX",
          ".XXX."],
    "9": [".XXX.",
          "XX.XX",
          "XX.XX",
          ".XXXX",
          "...XX",
          "..XX.",
          ".XX.."],
    "+": [".....",
          "..X..",
          "..X..",
          "XXXXX",
          "..X..",
          "..X..",
          "....."],
    "-": [".....",
          ".....",
          ".....",
          "XXXXX",
          ".....",
          ".....",
          "....."],
}

# rival 1, "book": a light bookhand, 1-px strokes with foot serifs (5x7)
FIG_BOOK = {
    "0": [".XXX.", "X...X", "X..XX", "X.X.X", "XX..X", "X...X", ".XXX."],
    "1": ["..X..", ".XX..", "..X..", "..X..", "..X..", "..X..", ".XXX."],
    "2": [".XXX.", "X...X", "....X", "...X.", "..X..", ".X...", "XXXXX"],
    "3": [".XXX.", "X...X", "....X", "..XX.", "....X", "X...X", ".XXX."],
    "4": ["...X.", "..XX.", ".X.X.", "X..X.", "XXXXX", "...X.", "..XXX"],
    "5": ["XXXXX", "X....", "XXXX.", "....X", "....X", "X...X", ".XXX."],
    "6": ["..XX.", ".X...", "X....", "XXXX.", "X...X", "X...X", ".XXX."],
    "7": ["XXXXX", "....X", "...X.", "..X..", ".X...", ".X...", ".X..."],
    "8": [".XXX.", "X...X", "X...X", ".XXX.", "X...X", "X...X", ".XXX."],
    "9": [".XXX.", "X...X", "X...X", ".XXXX", "....X", "...X.", ".XX.."],
    "+": [".....", "..X..", "..X..", "XXXXX", "..X..", "..X..", "....."],
    "-": [".....", ".....", ".....", "XXXXX", ".....", ".....", "....."],
}

# rival 2, "carved": a 6x8 body cut with a knife, 2-px strokes everywhere and wedge ends (cell 8x10, advance 7)
FIG_CARVED = {
    "0": [".XXXX.", "XXXXXX", "XX..XX", "XX..XX", "XX..XX", "XX..XX", "XXXXXX", ".XXXX."],
    "1": ["..XX..", ".XXX..", "XXXX..", "..XX..", "..XX..", "..XX..", "..XX..", "XXXXXX"],
    "2": [".XXXX.", "XX..XX", "....XX", "...XX.", "..XX..", ".XX...", "XX....", "XXXXXX"],
    "3": ["XXXXXX", "....XX", "...XX.", "..XXX.", "....XX", "....XX", "XX..XX", ".XXXX."],
    "4": ["...XX.", "..XXX.", ".XXXX.", "XX.XX.", "XXXXXX", "...XX.", "...XX.", "..XXXX"],
    "5": ["XXXXXX", "XX....", "XXXXX.", "....XX", "....XX", "....XX", "XX..XX", ".XXXX."],
    "6": ["..XXX.", ".XX...", "XX....", "XXXXX.", "XX..XX", "XX..XX", "XX..XX", ".XXXX."],
    "7": ["XXXXXX", "....XX", "...XX.", "..XX..", ".XXXX.", ".XX...", ".XX...", ".XX..."],
    "8": [".XXXX.", "XX..XX", "XX..XX", ".XXXX.", "XX..XX", "XX..XX", "XX..XX", ".XXXX."],
    "9": [".XXXX.", "XX..XX", "XX..XX", "XX..XX", ".XXXXX", "....XX", "...XX.", ".XXX.."],
    "+": ["......", "..XX..", "..XX..", "XXXXXX", "XXXXXX", "..XX..", "..XX..", "......"],
    "-": ["......", "......", "......", "XXXXXX", "XXXXXX", "......", "......", "......"],
}

FIGURE_SETS = {"hand": FIG_HAND, "book": FIG_BOOK, "carved": FIG_CARVED}
FIGURE_ORDER = "0123456789+-"

ARROWS = {
    "up": ["..XX..",
           ".XXXX.",
           "XXXXXX",
           "..XX..",
           "..XX..",
           "..XX..",
           "......"],
    "down": ["......",
             "..XX..",
             "..XX..",
             "..XX..",
             "XXXXXX",
             ".XXXX.",
             "..XX.."],
}

# --- signs: bodies in colour; the ink edge is added around them -----------------------------------------------------
# the small coin is struck with a Roman I, the big one with an X (never a currency symbol); lit from the upper left
COIN = ["..hhg..",
        ".hwggg.",
        "hhgsggs",
        "hggsggs",
        "gggsggd",
        ".gggsd.",
        "..sdd.."]

COIN_TEN = ["..hhhgg..",
            ".hwhgggs.",
            "hhdgggdgs",
            "hggdgdggs",
            "hgggdgggd",
            "gggdgdggd",
            "ggdgggdgd",
            ".ggggssd.",
            "..sdddd.."]

FACES = {
    "glad": ["..XXX..",
             ".XXXXX.",
             "XXiXiXX",
             "XXXXXXX",
             "XiXXXiX",
             ".XiiiX.",
             "..XXX.."],
    "even": ["..XXX..",
             ".XXXXX.",
             "XXiXiXX",
             "XXXXXXX",
             "XXiiiXX",
             ".XXXXX.",
             "..XXX.."],
    "grim": ["..xxx..",
             ".xxxxx.",
             "xxixixx",
             "xxxxxxx",
             "xxiiixx",
             ".ixxxi.",
             "..xxx.."],
    "unrest": ["..rrr..",
               ".irrri.",
               "rririrr",
               "rrrrrrr",
               "rriiirr",
               ".riiir.",
               "..rrr.."],
}

# the face rival "hood" (the pick): a townsman's head in his hood, the face in bone. The mood is told by the mass of
# colour and the silhouette first: glad throws the hood back (a broad bone face, raised, smiling), even wears it as
# it is, grim pulls it down over the brow (the eyes in its shadow, the head bowed, little bone shows), unrest wears
# the red-brown hood and shouts (an open mouth, the brows down).
FACES_HOOD = {
    "glad": ["..ccc..",
             ".cXXXc.",
             "cXiXiXc",
             "cXXXXXc",
             "ciXXXic",
             "cXiiiXc",
             "CcXXXcC"],
    "even": ["..ccc..",
             ".ccccc.",
             "ccXXXcc",
             "cXiXiXc",
             "cXXXXXc",
             "cciiicc",
             "CcccccC"],
    "grim": ["..ccc..",
             ".ccccc.",
             "ccccccc",
             "cCiCiCc",
             "cCxxxCc",
             "ccCiCcc",
             "CcccccC"],
    "unrest": ["..mmm..",
               ".mMMMm.",
               "miXXXim",
               "mXiXiXm",
               "mXiiiXm",
               "mmiiimm",
               "MmmmmmM"],
}

# the face rival "cap": a townsman in profile under a green cap, looking right. Glad lifts the chin, even looks
# ahead, grim bows the head (the cap's peak over the eye), unrest shouts with the mouth wide and the cap gone red.
FACES_CAP = {
    "glad": ["..ppp..",
             ".ppppp.",
             ".PXXXX.",
             ".XXiXX.",
             ".XXXXXX",
             ".XXXii.",
             "..XXX.."],
    "even": [".ppp...",
             "pppppp.",
             ".PXXX..",
             ".XXiXX.",
             ".XXXXXX",
             ".XXXXi.",
             "..XXX.."],
    "grim": [".......",
             ".ppp...",
             "ppppppp",
             ".PXiXX.",
             ".XXXXX.",
             ".XXXiXX",
             "..XXX.."],
    "unrest": [".mmm...",
               "mmmmmm.",
               ".MXiX..",
               ".XXXXXX",
               ".XXXii.",
               ".XXXii.",
               "..XXXX."],
}

FACE_STYLES = {"disc": FACES, "hood": FACES_HOOD, "cap": FACES_CAP}
FACE_STYLE = "hood"     # the pick; `hudart.py build hudFace --face cap` (or disc) switches

# the dawn sign (the day line under the row: the sign and the day's number, no word): a half sun with five rays in a fan on
# the horizon, bone with the ink edge; the gap above the horizon becomes ink, so the line stands apart
DAWN = ["X...X...X",
        ".X..X..X.",
        "...XXX...",
        "..XXXXX..",
        ".XXXXXXX.",
        ".........",
        "XXXXXXXXX"]

# the dawn sign's rival: three rays only (it read as a covered dish, the top ray as its knob; kept for the director)
DAWN_RIVAL = ["....X....",
              ".X.....X.",
              "...XXX...",
              "..XXXXX..",
              ".XXXXXXX.",
              ".........",
              "XXXXXXXXX"]

# one of the people: a round head over the shoulders (6x7); the sign is two of them, the far one a step behind and
# in shade, each with its own ink edge so the near one stands clear of the far one
PERSON = ["..XX..",
          ".XXXX.",
          ".XXXX.",
          "..XX..",
          "......",
          ".XXXX.",
          "XXXXXX"]

GEARS = {
    "a": ["...XX...",
          ".X.XX.X.",
          "..XXXX..",
          "XXX..XXX",
          "XXX..XXX",
          "..XXXX..",
          ".X.XX.X.",
          "...XX..."],
    "b": ["...XX...",
          ".XXXXXX.",
          ".XX..XX.",
          "XX....XX",
          "XX....XX",
          ".XX..XX.",
          ".XXXXXX.",
          "...XX..."],
    "c": ["..X..X..",
          ".XXXXXX.",
          "XXX..XXX",
          ".X....X.",
          ".X....X.",
          "XXX..XXX",
          ".XXXXXX.",
          "..X..X.."],
}
GEAR = GEARS["c"]

# hollows: drawn without an ink edge (cut into the board); 9x9 and 11x11
HOLLOW = ["..kkkkk..",
          ".kKKKKKk.",
          "kKKKKKKKk",
          "kKKKKKKKk",
          "kKKKKKKKk",
          "kKKKKKKKl",
          "kkKKKKKll",
          ".kkkKlll.",
          "..lllll.."]

HOLLOW_TEN = ["...kkkkk...",
              ".kkKKKKKkk.",
              ".kKKKKKKKk.",
              "kKKKKKKKKKk",
              "kKKKKKKKKKk",
              "kKKKKKKKKKk",
              "kKKKKKKKKKl",
              "kkKKKKKKKll",
              ".kkKKKKKll.",
              ".kkkKKKlll.",
              "...lllll..."]


def grid_image(rows, pal):
    h = len(rows)
    w = len(rows[0])
    assert all(len(r) == w for r in rows), rows
    img = Image(w, h)
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            if ch != ".":
                img.set(x, y, pal.color(LEGEND[ch]) + (255,))
    return img


def edged(body, pal, w=None, h=None):
    """The body inside a cell one pixel larger on every side (or w x h, centred), with an ink edge on every empty
    pixel that touches the body (8 neighbours), so the edge is one even pixel all round."""
    cw = w or body.w + 2
    ch = h or body.h + 2
    ox = (cw - body.w) // 2
    oy = (ch - body.h) // 2
    out = Image(cw, ch)
    ink = pal.color("ink") + (255,)
    for y in range(body.h):
        for x in range(body.w):
            c = body.get(x, y)
            if c[3]:
                out.set(x + ox, y + oy, c)
    for y in range(ch):
        for x in range(cw):
            if out.get(x, y)[3]:
                continue
            for dy in (-1, 0, 1):
                for dx in (-1, 0, 1):
                    xx, yy = x + dx - ox, y + dy - oy
                    if 0 <= xx < body.w and 0 <= yy < body.h and body.get(xx, yy)[3]:
                        out.set(x, y, ink)
                        break
                else:
                    continue
                break
    return out


def strip(frames):
    w = frames[0].w
    h = frames[0].h
    out = Image(w * len(frames), h)
    for i, f in enumerate(frames):
        assert f.w == w and f.h == h
        for y in range(h):
            for x in range(w):
                c = f.get(x, y)
                if c[3]:
                    out.set(i * w + x, y, c)
    return out


def hollow_with_coin(hollow_rows, coin_rows, pal):
    img = grid_image(hollow_rows, pal)
    coin = grid_image(coin_rows, pal)
    o = (img.w - coin.w) // 2
    for y in range(coin.h):
        for x in range(coin.w):
            c = coin.get(x, y)
            if c[3]:
                img.set(x + o, y + o, c)
    return img


def people(pal):
    """Two of the people (13x9): the far one in shade, 5 px to the right, the near one over it with its own edge."""
    near = edged(grid_image(PERSON, pal), pal)
    far = edged(grid_image([r.replace("X", "x") for r in PERSON], pal), pal)
    out = Image(13, 9)
    for img, ox in ((far, 5), (near, 0)):
        for y in range(img.h):
            for x in range(img.w):
                c = img.get(x, y)
                if c[3]:
                    out.set(x + ox, y, c)
    return out


def figures(pal, style="hand"):
    glyphs = FIGURE_SETS[style]
    return [edged(grid_image(glyphs[c], pal), pal) for c in FIGURE_ORDER]


def frames_for(sprite, pal, style="hand", face=None):
    if sprite == "hudFigures":
        return figures(pal, style)
    if sprite == "hudArrow":
        return [edged(grid_image(ARROWS[k], pal), pal) for k in ("up", "down")]
    if sprite == "hudCoin":
        return [edged(grid_image(COIN, pal), pal)]
    if sprite == "hudCoinTen":
        return [edged(grid_image(COIN_TEN, pal), pal)]
    if sprite == "hudHollow":
        return [grid_image(HOLLOW, pal), hollow_with_coin(HOLLOW, COIN, pal)]
    if sprite == "hudHollowTen":
        return [grid_image(HOLLOW_TEN, pal), hollow_with_coin(HOLLOW_TEN, COIN_TEN, pal)]
    if sprite == "hudFace":
        faces = FACE_STYLES[face or FACE_STYLE]
        return [edged(grid_image(faces[k], pal), pal) for k in ("glad", "even", "grim", "unrest")]
    if sprite == "hudDawn":
        return [edged(grid_image(DAWN, pal), pal)]
    if sprite == "hudPeople":
        return [people(pal)]
    if sprite == "hudGear":
        return [edged(grid_image(GEAR, pal), pal)]
    raise SystemExit("unknown sprite " + sprite)


SPRITES = ["hudFigures", "hudArrow", "hudCoin", "hudCoinTen", "hudHollow", "hudHollowTen", "hudFace", "hudPeople",
           "hudGear", "hudDawn"]


def palette():
    return Palette(DEFAULT_PALETTE, True, allow_swap=True)


def main():
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest="cmd", required=True)
    b = sub.add_parser("build")
    b.add_argument("id")
    b.add_argument("--out", default=os.path.join(HERE, "..", "Resources", "Art"))
    b.add_argument("--face", choices=sorted(FACE_STYLES), help="hudFace only: which face (default %s)" % FACE_STYLE)
    sub.add_parser("list")
    sub.add_parser("advance")
    a = ap.parse_args()
    if a.cmd == "list":
        print(" ".join(SPRITES))
        return
    if a.cmd == "advance":
        print("figure advance %d, sign-to-figure gap %d, group space %d" % (ADVANCE, GAP, SPACE))
        return
    pal = palette()
    img = strip(frames_for(a.id, pal, face=a.face))
    path = os.path.join(a.out, a.id + ".png")
    write_png(path, img)
    print("wrote", path, "%dx%d" % (img.w, img.h))


if __name__ == "__main__":
    main()
