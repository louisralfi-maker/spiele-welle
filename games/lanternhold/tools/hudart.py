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
  hudHollow    a hollow of the tally board (no ink edge: it is cut into the board's wood); see the count below
  hudFace      9x9, 4 frames: glad, even, grim, unrest; a townsman's head in his hood (FACE_STYLE "hood"; the
               rivals "cap", a head in profile, and "disc", the first round face, stay buildable with --face)
  hudDawn      11x9: the dawn sign, a half sun on the horizon; the day line is this sign and the day's number
  hudPeople    13x9: two heads and shoulders, one a step behind the other
  hudGear      10x10: the gear in the corner (opens the pause sheet)

The count (PAY.md, build 3 lane 1): the tally board on its post, a thing in the world (HUD.md: drawn lit by the world,
never on a plate), its bar coin and the site lantern the one who was paid lights.

  hudCoinBar   13x8, 5 frames: the bar (a hundred), a small cast ingot with a struck C, lit from the upper left;
               frames 0 to 2 its face (the glint and the stamp a pixel apart, so a board of bars is no row of copies),
               3 its end, a 3 px sliver, 4 half turned, as it turns in the air
  hudHollowBar 13x9, 4 frames: its hollow in the board, empty and holding the bar's faces 0 to 2 (no ink edge)
  payBoard     6x12, 28 frames: the board's tiles, so a board fits any price (PayBoardLayout in Core/PayCount.swift):
               0 plank's left end, 1 2 14 15 four plank middles (the count picks one per tile by a hash and shifts
               every second row by half a tile, so no streak lines up), 3 plank's right end, 4 5 6 the cap over the
               top plank (left, middle, right; in the cell's last 3 rows), 16 17 two more cap middles, 7 8 9 the foot
               under the last plank (in the cell's first 2 rows), 10 the post (every row alike, so tiles stack and
               overlap unseen), 11 the post's foot in the ground, 12 the hasp on the shut lid, 13 the post's top, the
               iron plate the lantern stands on (in the cell's last 3 rows); the lid: 18 its left end, 19 20 two
               middles, 21 its right end (a wider seam than the board's planks), 22 a batten nailed across its planks;
               step 3: the site lantern's crook, 23 24 pointing right (the post's iron-bound top bending over, then the
               arm's end with its hook and 2 px chain), 25 26 pointing left (the arm's end, then the post's top); 27 a
               fifth plank middle with a knot (the grain as streaks of 3 to 6 px: one tile in five shows a knot);
               step 4: the signpost's iron bar, 28 its left end, 29 a middle, 30 its right end (in the cell's last 4
               rows, as the cap)
  paySign      24x17, 20 frames (step 5, the builder's models at a plot with several offers: the models are the
               offer, the pay board's hollows are the price): 0 the sawhorse trestle (24 x 10 in the cell's bottom
               rows), 1 the ballista (22 x 13: a great crossbow on a post with splayed feet, its bolt's iron point out
               in front), 2 the catapult (22 x 15, step 6: an A-frame, the arm 2 px thick at 45 degrees rising
               over it to a dark iron cup, a 4 x 4 weight box hanging with air under it, two wheels with dark
               hubs), 3 any other building (a gabled house, 16 x 13); fresh pale timber in
               three tones with an ink edge all round, standing on the trestle's beam; 4 5 6 the chosen model's warm
               rim (its ink edge fire gold along the top, gold down the right), laid over it; 7-10, 11-14, 15-18 the
               glint passing over the ballista, the catapult and the house in four steps; 19 the second trestle
               of a row (a darker plank and a knot in its beam)
  siteLantern  9x13, 4 frames: the site lantern on the post, unlit (dark glass), lit (a 5x5 flame in the fire ramp,
               white at its heart), and the two frames of its bloom as it catches (the stage lane adds its light, the
               glow of its glass and its halo)
  siteHalo     25x25, 2 frames: 0 the lit lantern's halo by night, light falling off in whole pixels, ordered-dithered
               (white; the stage lane tints it with the fire's gold and adds it as light); 1 (step 4) the warm pool by
               day, an opaque disc 8 px round with an edge to 10 px kept by an ordered mask jittered per pixel (step
               5, M-e: no ring), cut past the post for a crook pointing right (the stage lane mirrors it for one
               pointing left) (white; the stage lane draws it blended over the wall toward fire gold at about 0.4,
               never added as light on a lit wall)

The count's coins in flight (build 3, the count's step 2: each coin flies from the lord's hand to its hollow, turning):

  payCoin      7x7, 5 frames: the small coin of the count (step 3: 7 px, a paler straw gold, a plain face, so one
               look tells it from the big one): 0 to 2 its faces (the glint a step along the rim, or none), 3 its edge,
               4 half turned (step 3: face, half, edge, half as it turns)
  hudCoinTen   11x11, 5 frames: the big coin, deep gold, struck with the house's lantern (as on the gate's banners)
               embossed one step lighter with a darker lower edge, 0 to 2 its faces, 3 its edge, 4 half turned
  hudHollow    7x7, hudHollowTen 11x11: 4 frames each, the hollow empty and holding the coin's faces 0 to 2

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
    "q": "strawLight",  # step 3's small coin face (kept for the record; step 4 made it gold again)
    "Q": "parchment",   # its lit rim
    "e": "cloth4",      # the count's small coin (step 4, the director's call 4): its face, the big coin's gold a step
                        # lighter and about a fifth less saturated (a fixed palette value: the portrait ramps' lightest
                        # cloth, which no look moves)
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

# the count's small coin, two more faces: the glint a step along the lit rim, the struck I a column over or leaning
COIN_B = ["..hhg..",
          ".hhwgg.",
          "hhggsgs",
          "hgggsgs",
          "ggggsgd",
          ".gggsd.",
          "..sdd.."]

COIN_C = ["..hhg..",
          ".hgggg.",
          "hwgsggs",
          "hgsgggs",
          "ggsgggd",
          ".gggsd.",
          "..sdd.."]

# the count's small coin (step 3, the director's call 7: one look tells 1 from 10): 7 px with its edge and a plain
# face. Step 4 (call 4, the critic's H4: step 3's straw read as a pebble): money again, its ramp the big coin's a step
# lighter and about a fifth less saturated (face cloth4 where the big one is gold; lit rim fireGold; shade straw), with
# a 1 px darker rim (woodLight, the big coin's deepest gold) round its lower right so it reads as a disc; three faces
# (the glint a step along the rim, or none), its edge, and half turned
PAY_SMALL = [".hhe.",
             "hweed",
             "heeed",
             "eeesd",
             ".ddd."]
PAY_SMALL_B = [".hwe.",
               "hheed",
               "heeed",
               "eeesd",
               ".ddd."]
PAY_SMALL_C = [".hhe.",
               "hheed",
               "heeed",
               "eeesd",
               ".ddd."]
PAY_SMALL_EDGE = ["h", "e", "e", "s", "d"]
PAY_SMALL_HALF = [".h.",
                  "hed",
                  "hed",
                  "esd",
                  ".d."]

# the big coin (ten), 11 px with its edge, deep gold, struck with the house's lantern, the mark of the gate's banners:
# a ring, the cap, the frame round one pane, the foot. Embossed (step 3, the director's call 7: step 2's dark-filled
# stamp read as a blot, even a padlock): the mark stands one step lighter than the face with a 1 px darker edge under
# it, no dark fill; three faces (the glint along the rim, on the ring, or none)
COIN_TEN = ["..hhhgg..",
            ".hwghggs.",
            "hhghhhgss",
            "hgghghgsd",
            "ggghghgsd",
            "ggghhhgsd",
            "gggsssgsd",
            ".gggggsd.",
            "..sdddd.."]

COIN_TEN_B = ["..hwhgg..",
              ".hhghggs.",
              "hhghhhgss",
              "hgghghgsd",
              "ggghghgsd",
              "ggghhhgsd",
              "gggsssgsd",
              ".gggggsd.",
              "..sdddd.."]

COIN_TEN_C = ["..hhhgg..",
              ".hhgwggs.",
              "hhghhhgss",
              "hgghghgsd",
              "ggghghgsd",
              "ggghhhgsd",
              "gggsssgsd",
              ".gggggsd.",
              "..sdddd.."]

COIN_TEN_EDGE = ["h", "h", "g", "g", "g", "g", "s", "s", "d"]
COIN_TEN_HALF = [".hhg.",
                 "hwhgs",
                 "hhhgs",
                 "hghgs",
                 "hghgd",
                 "hhhgd",
                 "gsssd",
                 "gggsd",
                 ".sdd."]

# the rivals kept for the director: the kit's Roman X (it can read as "cancel" at phone size, step 1's critic) and a
# long plus cross, the fallback should the lantern muddy
COIN_TEN_X = ["..hhhgg..",
              ".hwhgggs.",
              "hhdgggdgs",
              "hggdgdggs",
              "hgggdgggd",
              "gggdgdggd",
              "ggdgggdgd",
              ".ggggssd.",
              "..sdddd.."]

COIN_TEN_PLUS = ["..hhhgg..",
                 ".hwhdggs.",
                 "hhggdgggs",
                 "hgggdgggs",
                 "hgdddddgd",
                 "ggggdgggd",
                 "ggggdgggd",
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

# the small coin's hollow (step 3: 7x7 for the 7 px coin), drawn without an ink edge (cut into the board)
HOLLOW_SMALL = ["..kkk..",
                ".kKKKk.",
                "kKKKKKk",
                "kKKKKKl",
                "kkKKKll",
                ".kkKll.",
                "..lll.."]

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


# --- the count: the bar, its hollow, the board's tiles, the site lantern ------------------------------------------------
# the bar: a small cast ingot, its top face lit, a C struck on its front (C is a hundred; never a currency sign)
COIN_BAR = ["..hwhhhgg..",
            ".hhgggggggs",
            "hgggsssgggd",
            "ggggsgggggd",
            "sgggsssggdd",
            ".ssddddddd."]

# two more faces: the glint further along the top, the C struck a column over; the end as it turns (a 3 px sliver)
COIN_BAR_B = ["..hhhwhgg..",
              ".hhgggggggs",
              "hggggsssggd",
              "gggggsggggd",
              "sggggsssgdd",
              ".ssddddddd."]

COIN_BAR_C = ["..whhhhgg..",
              ".hhgggggggs",
              "hggsssggggd",
              "gggsgggggdd",
              "sggsssgggdd",
              ".ssddddddd."]

COIN_BAR_EDGE = ["h", "g", "g", "s", "d", "d"]
# the bar half turned: its front shortened, its end coming round into the light
COIN_BAR_HALF = ["..hwhg.",
                 ".hhgggs",
                 "hggssgd",
                 "gggsggd",
                 "sggssdd",
                 ".sdddd."]

HOLLOW_BAR = [".kkkkkkkkkkk.",
              "kKKKKKKKKKKKk",
              "kKKKKKKKKKKKk",
              "kKKKKKKKKKKKk",
              "kKKKKKKKKKKKk",
              "kKKKKKKKKKKKl",
              "kkKKKKKKKKKll",
              ".kkKKKKKKKll.",
              "..lllllllll.."]

# the board's colours: a plank face of weathered wood, its grain darker and lighter, the seam between planks in shade,
# iron nails at the ends, the ink edge round the whole board
BOARD_LEGEND = {
    "i": "ink",
    "F": "wood",        # the plank's face
    "L": "woodLight",   # grain catching light, the top bevel, a lit edge
    "D": "woodDark",    # grain in shade, the seam, the shaded edge, the underside
    "S": "soil",        # a knot's dark heart
    "n": "stoneMid",    # a nail head
    "N": "stoneLight",  # its glint
    "b": "stoneDark",   # iron
    "B": "stone",       # iron in light
    "w": "strawLight",  # the top edge's highest light
}

# a plank row is 12 rows: 11 of face and its seam under it
PLANK_L = ["iLFFFF",
           "iLFFFF",
           "iLFFLL",
           "iLnFFF",
           "iLNFFF",
           "iLFFFF",
           "iLFFFF",
           "iLFDSD",
           "iLFFFF",
           "iLFFFF",
           "iDFFFF",
           "iDDDDD"]
# five middles (the count picks one per tile by a hash of the thing, the row and the tile, never the same twice in a
# row, and starts every second row half a tile over). Step 3 (the director's call 9, M-c): the grain is streaks of
# 3 to 6 px, some running to the tile's edge so they go on in the next tile, one dark and one light a tile, on
# rows of their own; the fifth middle has a knot the grain flows round, so one tile in five shows a knot
PLANK_M1 = ["FFFFFF",
            "FFFFFF",
            "FLLLLF",
            "FFFFFF",
            "FFFFFF",
            "FFFFFF",
            "DDDFFF",
            "FFFFFF",
            "FFFFFF",
            "FFFFFF",
            "FFFFFF",
            "DDDDDD"]
PLANK_M2 = ["FFFFFF",
            "FFFFFF",
            "FFFFFF",
            "FFFFFF",
            "FFDDDD",
            "FFFFFF",
            "FFFFFF",
            "FFFFFF",
            "LLLLLF",
            "FFFFFF",
            "FFFFFF",
            "DDDDDD"]
PLANK_M3 = ["FFFFFF",
            "FFFFFF",
            "FFFFFF",
            "LLLFFF",
            "FFFFFF",
            "FFFFFF",
            "FFFFFF",
            "FDDDDD",
            "FFFFFF",
            "FFFFFF",
            "FFFFFF",
            "DDDDDD"]
PLANK_M4 = ["FFFFFF",
            "FFFLLL",
            "FFFFFF",
            "FFFFFF",
            "FFFFFF",
            "FDDDDF",
            "FFFFFF",
            "FFFFFF",
            "FFFFFF",
            "LLLFFF",
            "FFFFFF",
            "DDDDDD"]
PLANK_M5 = ["FFFFFF",
            "FFFFFF",
            "LLLFFF",
            "FFDDFF",
            "FDSSDF",
            "FFDDFF",
            "FFFFFF",
            "FFFFLL",
            "FFFFFF",
            "DDFFFF",
            "FFFFFF",
            "DDDDDD"]
PLANK_R = ["FFFFDi",
           "FFFFDi",
           "FFFFDi",
           "FFFnDi",
           "FFFNDi",
           "LLFFDi",
           "FFFFDi",
           "FFFFDi",
           "FFFFDi",
           "LFFFDi",
           "FFFFDi",
           "DDDDDi"]
# the cap's top edge catches the light in short runs at no fixed step (three middles, picked like the planks)
CAP_L = [".iiiii",
         "iLwwLL",
         "iLLLLL"]
CAP_M = ["iiiiii",
         "LLwwLL",
         "LLLLLL"]
CAP_M2 = ["iiiiii",
          "LLLLLw",
          "LLLLLL"]
CAP_M3 = ["iiiiii",
          "wwLLLL",
          "LLLLDL"]
CAP_R = ["iiiii.",
         "LLLwDi",
         "LLLLDi"]
FOOT_L = ["iDDDDD",
          ".iiiii"]
FOOT_M = ["DDDDDD",
          "iiiiii"]
FOOT_R = ["DDDDDi",
          "iiiii."]
POST = [".iLDi."] * 12
POST_FOOT = [".iLDi."] * 9 + [".iLDi.", "iDLDDi", "iiiiii"]
HASP = ["......",
        "......",
        "..ii..",
        ".ibBi.",
        "ibBBbi",
        "ibi.bi",
        "ibi.bi",
        "ibBBbi",
        ".ibbi.",
        "..ii..",
        "......",
        "......"]
POST_TOP = [".iiii.",
            "ibBBbi",
            "ibbbbi"]

# the lid (the seal): planks of its own with a wider seam, two battens nailed across them and the hasp in the middle,
# so the shut board reads as a lid and not as the board without its hollows
LID_L = ["iLFFFF",
         "iLFFFF",
         "iLFFFF",
         "iLnFFF",
         "iLNFFF",
         "iLFFFF",
         "iLFFLF",
         "iLFFFF",
         "iLFFFF",
         "iDFFFF",
         "iDDDDD",
         "iiDDDD"]
LID_M1 = ["FFFFFF",
          "FFFFFF",
          "FFFFFF",
          "FLLLLL",
          "FFFFFF",
          "FFFFFF",
          "FFFFFF",
          "DDDDFF",
          "FFFFFF",
          "FFFFFF",
          "DDDDDD",
          "DDDDDD"]
LID_M2 = ["FFFFFF",
          "FFFFFF",
          "FFFFFF",
          "FFFFFF",
          "FFFFFF",
          "FFDDDD",
          "FFFFFF",
          "FFFFFF",
          "LLLLFF",
          "FFFFFF",
          "DDDDDD",
          "DDDDDD"]
LID_R = ["FFFFDi",
         "FFFFDi",
         "FFFFDi",
         "FFFnDi",
         "FFFNDi",
         "LLFFDi",
         "FFFFDi",
         "FFFFDi",
         "FFFFDi",
         "FFFFDi",
         "DDDDDi",
         "DDDDii"]
# a batten across the lid's planks (one tile a plank, they stack): lit on its left, its own edge and its shadow on the
# right, a nail into every plank it crosses; it runs over the seams
BATTEN = [".LFDD.",
          ".LFDD.",
          ".LFDD.",
          ".LFDD.",
          ".NnDD.",
          ".LnDD.",
          ".LFDD.",
          ".LFDD.",
          ".LFDD.",
          ".LFDD.",
          ".LFDD.",
          ".LFDD."]

# the site lantern's crook (step 3, the director's call 5: a builder's lantern on a crook, never a street lamp): the
# lantern's own short post, cut to about the lord's shoulder, its top bound in iron that bends over toward the work and
# ends in a hook with a 2 px chain; the lantern hangs from the chain (its ring under the chain's last link). Drawn 12
# wide and cut into two tiles: the post's top with the bend (it stacks on the post tiles below) and the arm's end with
# the hook and the chain. Pointing right, and pointing left with the post's own light kept on its left.
CROOK_RIGHT = ["..iiiiiiiii.",
               ".iiBBBBBBBii",
               ".iBiiiiiiiBi",
               ".iBbi....ibi",
               ".iBbi....iii",
               ".iLDi.....b.",
               ".iLDi.....i.",
               ".iLDi.......",
               ".iLDi.......",
               ".iLDi.......",
               ".iLDi.......",
               ".iLDi......."]
CROOK_LEFT = [".iiiiiiiii..",
              "iiBBBBBBBii.",
              "iBiiiiiiiBi.",
              "ibi....iBbi.",
              "iii....iBbi.",
              ".b.....iLDi.",
              ".i.....iLDi.",
              ".......iLDi.",
              ".......iLDi.",
              ".......iLDi.",
              ".......iLDi.",
              ".......iLDi."]
# where the chain's last link hangs in the 12-wide crook (column, row): the lantern's ring (its column 4) hangs under it
CROOK_CHAIN = {"right": (10, 6), "left": (1, 6)}

# the signpost's iron bar (step 4): an iron band lit on its top, its own ink edge, the ends capped (cell's last 4 rows)
SIGN_BAR_L = [".iiiii",
              "ibBBBB",
              "ibbbbb",
              ".iiiii"]
SIGN_BAR_M = ["iiiiii",
              "BBBBBB",
              "bbbbbb",
              "iiiiii"]
SIGN_BAR_R = ["iiiii.",
              "BBBBbi",
              "bbbbbi",
              "iiiii."]

# the builder's models on their trestles (step 5, the director's notes of 16.11., 12:44, P1 to P4: the models are the
# offer, the board's hollows are the price; nothing but the things themselves stands at a plot with several offers).
# One 24 x 17 cell per frame (step 6: 13 before; the catapult's arm needs the height): 0 the sawhorse trestle (24 x 10,
# in the cell's bottom 10 rows: a beam on two splayed legs, weathered wood); 1 2 3 the models standing on it
# (bottom-aligned, centred): the ballista 22 x 13, the catapult 24 x 17 with its edge (step 6, R3) and any other
# building, a gabled house 16 x 13; fresh pale timber in three tones lit from the upper left,
# dark timber for the frames and legs, a dark ink edge all round (4 neighbours, so a diagonal stays thin) so they
# read on grey stone, on the blue banner and at night, one iron accent each (the bolt's point, the cup, the door's
# hinge); the string is parchment with no edge; 4 5 6 the chosen model's warm rim (its ink edge fire gold along the top,
# gold down the right), laid over the model; 7 to 18 the glint passing over each model in four steps (a short streak of fire white on its lit edge),
# ballista 7-10, catapult 11-14, house 15-18; 19 the row's second trestle (step 6). Drawn by hand, never reduced from the engines' sprites.
MODEL_CELL = (24, 17)
MODEL_TONES = {"T": ("strawLight", "straw", "woodLight"),   # fresh timber: lit, face, shade
               "D": ("straw", "woodLight", "wood"),         # the dark timber of frames, bolts and legs
               "W": ("woodLight", "wood", "woodDark"),      # wheels and the winch's drum
               "I": ("stonePale", "stoneLight", "stone"),   # iron
               "C": ("stoneDark", "stoneDark", "stoneDark"),  # step 6: the catapult's dark iron cup
               "L": ("stonePale", "stonePale", "stonePale"),  # its one light pixel
               "H": ("woodDark", "woodDark", "woodDark")}     # the wheels' dark hubs
# T timber, D dark timber, W wheel (the catapult's weight box since step 6), I iron, C the cup's dark iron, L its light
# pixel, H a hub, s string (parchment, no ink edge), . empty; at most 22 wide and 15 rows (the ballista 11, the house 11)
MODEL_BALLISTA = [".......DDD..........",   # facing left, as its sprite: a great crossbow on a post with
                  "......DD..s.........",   # splayed feet; the bow in dark timber, 2 px thick, its string drawn
                  ".I...DD....ss.......",   # back to the nut; the bolt in the stock's groove with its iron point
                  "IIIDDDDDDDDDDsDTTTTW",   # well out in front; the stock's butt and the winch's stub behind
                  ".I..TDDTTTTTTsTTTTTW",
                  ".....DD....DD..TTTT.",
                  "......DD..sDD.......",
                  ".......DDD.DD.......",
                  "...........DD.......",
                  "..........DDDD......",
                  "........DD.DD.DD...."]
MODEL_CATAPULT = ["...............CCC....",   # step 6 (R3), facing right: an A-frame whose pivot stands 7 px over
                  ".............TTCLC....",   # the base, the arm 2 px thick at 45 degrees rising 4 px over it to a
                  "............TT........",   # dark iron cup (3 x 2, inked, one light pixel); the 4 x 4 weight box
                  "...........TT.........",   # hangs at the arm's short end with 1 px of air over the base; the
                  "..........TT..........",   # pivot's iron pin; the base beam on two 4 x 4 wheels with dark hubs;
                  ".........TTID.........",   # its cup stands 4 px over the ballista's top (the cell is 17 high)
                  ".....WWWWT.D.D........",
                  ".....WWWW..D..D.......",
                  ".....WWWW.D...D.......",
                  ".....WWWW.D....D......",
                  "..........D....D......",
                  ".DTTDDDDDDDDDDDDDTTDD.",
                  ".THHT...........THHT..",
                  ".THHT...........THHT..",
                  "..TT.............TT..."]
MODEL_HOUSE = ["......TT......",
               ".....TTTT.....",
               "....TTTTTT....",
               "...TTTTTTTT...",
               "..TTTTTTTTTT..",
               ".DDDDDDDDDDDD.",
               "..TTTTTTTTTT..",
               "..TTTDDTTTTT..",
               "..TTTDDTTTTT..",
               "..TTTDITTTTT..",
               "..TTTDDTTTTT.."]
# the sawhorse (24 x 10): a beam lit on its top, nailed, on two pairs of legs splayed out past its ends
TRESTLE_LEGEND = {"i": "ink", "L": "woodLight", "F": "wood", "D": "woodDark", "n": "stoneMid"}
TRESTLE = ["..iiiiiiiiiiiiiiiiiiii..",
           ".iLLLLLLLLLLLLLLLLLLLLi.",
           ".iFFFnFFFFFFFFFFFFnFFFi.",
           "..iiiiiiiiiiiiiiiiiiii..",
           "..iLFi............iLFi..",
           "..iLFi............iLFi..",
           ".iLFi..............iLFi.",
           ".iLFi..............iLFi.",
           "iLFi................iLFi",
           "iLFi................iLFi"]
# step 6 (R3): the second trestle of a row, not a copy: one darker plank let into its beam and a knot
TRESTLE_B = ["..iiiiiiiiiiiiiiiiiiii..",
             ".iLLLLLLLLLLFFFFFLLLLLi.",
             ".iFFFnFFFDFFDDDDDFnFFFi.",
             "..iiiiiiiiiiiiiiiiiiii..",
             "..iLFi............iLFi..",
             "..iLFi............iLFi..",
             ".iLFi..............iLFi.",
             ".iLFi..............iLFi.",
             "iLFi................iLFi",
             "iLFi................iLFi"]


def model_grid(rows):
    """The body `rows` in the cell, centred and standing on its bottom row with a pixel for the ink edge all round."""
    cw, ch = MODEL_CELL
    w, h = len(rows[0]), len(rows)
    assert all(len(r) == w for r in rows) and w + 2 <= cw and h + 2 <= ch, rows
    ox, oy = (cw - w) // 2, ch - 1 - h
    grid = [["." for _ in range(cw)] for _ in range(ch)]
    for y, row in enumerate(rows):
        for x, c in enumerate(row):
            grid[oy + y][ox + x] = c
    return grid


def model_solid(grid, x, y):
    return 0 <= y < len(grid) and 0 <= x < len(grid[0]) and grid[y][x] not in (".", "s")


def model_image(rows, pal):
    """A model: each material in three tones (lit where its top or left is open, shaded where its foot or right is
    open), the string in parchment, an ink edge on every empty pixel beside the body (4 neighbours)."""
    grid = model_grid(rows)
    cw, ch = MODEL_CELL
    img = Image(cw, ch)
    for y in range(ch):
        for x in range(cw):
            c = grid[y][x]
            if c in MODEL_TONES:
                lit = not model_solid(grid, x, y - 1) or not model_solid(grid, x - 1, y)
                dark = not model_solid(grid, x, y + 1) or not model_solid(grid, x + 1, y)
                tone = MODEL_TONES[c][0] if lit else MODEL_TONES[c][2] if dark else MODEL_TONES[c][1]
                img.set(x, y, pal.color(tone) + (255,))
            elif c == "s":
                img.set(x, y, pal.color("parchment") + (255,))
            elif any(model_solid(grid, x + i, y + j) for i, j in ((-1, 0), (1, 0), (0, -1), (0, 1))):
                img.set(x, y, pal.color("ink") + (255,))
    return img


def model_rim(rows, pal):
    """The chosen model's warm rim, laid over it: its ink edge turns fire gold along its top and gold down its right
    side, as if the lantern's light caught it; the timber keeps its tones."""
    grid = model_grid(rows)
    cw, ch = MODEL_CELL
    img = Image(cw, ch)
    for y in range(ch):
        for x in range(cw):
            if grid[y][x] not in (".", "s"):
                continue
            if model_solid(grid, x, y - 1):
                continue
            if model_solid(grid, x, y + 1):
                img.set(x, y, pal.color("fireGold") + (255,))
            elif model_solid(grid, x - 1, y) and not model_solid(grid, x + 1, y):
                img.set(x, y, pal.color("gold") + (255,))
    return img


def model_glints(rows, pal, steps=4):
    """The glint passing over a model left to right in `steps` frames: on each, the lit timber pixels on one short
    diagonal (top-left to bottom-right) burn fire white."""
    grid = model_grid(rows)
    cw, ch = MODEL_CELL
    lit = [(x, y) for y in range(ch) for x in range(cw)
           if grid[y][x] in ("T", "D") and (not model_solid(grid, x, y - 1) or not model_solid(grid, x - 1, y))]
    lo = min(x - y for x, y in lit)
    hi = max(x - y for x, y in lit)
    frames = []
    for k in range(steps):
        band = lo + (hi - lo) * (k + 0.5) / steps
        img = Image(cw, ch)
        for x, y in lit:
            if abs((x - y) - band) <= 1.0:
                img.set(x, y, pal.color("fireWhite") + (255,))
        frames.append(img)
    return frames


def model_frames(pal):
    cw, ch = MODEL_CELL
    models = (MODEL_BALLISTA, MODEL_CATAPULT, MODEL_HOUSE)
    frames = [legend_image(TRESTLE, pal, TRESTLE_LEGEND, ch, top=False)]
    frames += [model_image(m, pal) for m in models]
    frames += [model_rim(m, pal) for m in models]
    for m in models:
        frames += model_glints(m, pal)
    # step 6 (R3): 19 the second trestle (appended, so every other frame keeps its number)
    frames.append(legend_image(TRESTLE_B, pal, TRESTLE_LEGEND, ch, top=False))
    return frames

# the site lantern (9x13, step 2's critic H2: the 7x10 one was a speck by day): a ring, a cap, a 5x5 glass in an iron
# frame, a foot; unlit its glass is the night's dark glass (as the street lanterns' heads), lit a flame stands in the
# fire ramp, white at its heart; as it catches, two frames of bloom: the glass burns white and the light spills
# through the frame's seams
LANTERN_LEGEND = {"i": "ink", "b": "stoneDark", "B": "stone", "g": "night2", "G": "night1",
                  "w": "fireWhite", "y": "fireGold", "o": "fireOrange"}
LANTERN_FRAME = ["...iii...",
                 "...i.i...",
                 "..iBBBi..",
                 ".iBBbBBi.",
                 "ibbbbbbbi",
                 "ib.....bi",
                 "ib.....bi",
                 "ib.....bi",
                 "ib.....bi",
                 "ib.....bi",
                 "ibbbbbbbi",
                 ".ibbbbbi.",
                 "..iiiii.."]
LANTERN_GLASS = {
    "unlit": ["gGggg",
              "gGggg",
              "ggGgg",
              "gggGg",
              "ggggG"],
    "lit": ["ooyoo",
            "oywyo",
            "oywyo",
            "ywwwy",
            "oyyyo"],
    "bloom1": ["ywwwy",
               "wwwww",
               "wwwww",
               "wwwww",
               "ywwwy"],
    "bloom2": ["oywyo",
               "ywwwy",
               "wwwww",
               "ywwwy",
               "oyyyo"],
}
# the light through the frame's seams while it blooms (row, column, colour) on top of the frame
LANTERN_SPILL = {
    "bloom1": [(4, 3, "y"), (4, 4, "w"), (4, 5, "y"), (10, 3, "y"), (10, 4, "y"), (10, 5, "y"),
               (6, 1, "y"), (7, 1, "y"), (6, 7, "y"), (7, 7, "y"), (1, 4, "y")],
    "bloom2": [(4, 4, "y"), (10, 4, "o"), (7, 1, "o"), (7, 7, "o")],
}


def lantern_frame(kind, pal):
    rows = [list(r) for r in LANTERN_FRAME]
    for y, row in enumerate(LANTERN_GLASS[kind]):
        for x, c in enumerate(row):
            rows[5 + y][2 + x] = c
    for y, x, c in LANTERN_SPILL.get(kind, []):
        rows[y][x] = c
    return legend_image(["".join(r) for r in rows], pal, LANTERN_LEGEND)


def halo(radius=12):
    """The lit lantern's halo (white; the stage lane tints it warm): light falling off from the middle in whole pixels,
    in ten steps of alpha ordered-dithered on a 2x2 grid, so no step shows as a ring (step 3, the director's call 6:
    step 2's four rings read as hard square bands), and its outer 2 px thinned on a checkerboard, so the edge melts
    into the night and never shows as a circle."""
    size = 2 * radius + 1
    top = 0.6
    steps = 10
    bayer = [[0.0, 0.5], [0.75, 0.25]]
    img = Image(size, size)
    for y in range(size):
        for x in range(size):
            d = ((x - radius) ** 2 + (y - radius) ** 2) ** 0.5
            if d > radius + 0.5:
                continue
            if d > radius - 1.5 and (x + y) % 2 == 1:
                continue
            a = top * max(0.0, 1.0 - d / (radius + 0.5)) ** 1.5
            q = int(a * steps / top + bayer[y % 2][x % 2]) * top / steps
            if q > 0:
                img.set(x, y, (255, 255, 255, int(round(q * 255))))
    return img


POOL_BAYER = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]
# step 5 (M-e of step 4's critic): the pool stops at the post: for a crook pointing right the post's far edge stands
# at the cell's column 3 (the pool's left is 2 px left of the post's tile), so columns 0 to 2 stay empty; the stage
# lane mirrors the pool for a crook pointing left
POOL_CUT = 3


def pool(radius=12, inner=8.0, edge=10.5):
    """The warm pool by day (step 4, the director's call 3): an opaque disc `inner` px round about the cell's middle,
    then out to `edge` a falling share of pixels kept by an ordered 4 x 4 mask jittered by a hash per pixel (step 5,
    M-e: the checkerboard drew a clean ring), so the pool's rim melts into the wall and never shows as a circle; cut at
    the post (`POOL_CUT`). White: the stage lane blends it toward fire gold."""
    size = 2 * radius + 1
    img = Image(size, size)
    for y in range(size):
        for x in range(POOL_CUT, size):
            d = ((x - radius) ** 2 + (y - radius) ** 2) ** 0.5
            if d <= inner:
                on = True
            elif d <= edge + 0.5:
                share = (edge + 0.5 - d) / (edge + 0.5 - inner)
                jitter = (((x * 73856093) ^ (y * 19349663)) % 7 - 3) / 24.0
                on = share > (POOL_BAYER[y % 4][x % 4] + 0.5) / 16.0 + jitter
            else:
                on = False
            if on:
                img.set(x, y, (255, 255, 255, 255))
    return img


def legend_image(rows, pal, legend, h=None, top=True):
    """The rows in `legend`'s colours, in a cell `h` rows high (the rows at its top, or at its bottom)."""
    w = len(rows[0])
    assert all(len(r) == w for r in rows), rows
    ch = h or len(rows)
    oy = 0 if top else ch - len(rows)
    img = Image(w, ch)
    for y, row in enumerate(rows):
        for x, c in enumerate(row):
            if c != ".":
                img.set(x, y + oy, pal.color(legend[c]) + (255,))
    return img


def board_tiles(pal):
    cell = 12
    tiles = [PLANK_L, PLANK_M1, PLANK_M2, PLANK_R]
    frames = [legend_image(t, pal, BOARD_LEGEND) for t in tiles]
    frames += [legend_image(t, pal, BOARD_LEGEND, cell, top=False) for t in (CAP_L, CAP_M, CAP_R)]
    frames += [legend_image(t, pal, BOARD_LEGEND, cell, top=True) for t in (FOOT_L, FOOT_M, FOOT_R)]
    frames.append(legend_image(POST, pal, BOARD_LEGEND))
    frames.append(legend_image(POST_FOOT, pal, BOARD_LEGEND))
    frames.append(legend_image(HASP, pal, BOARD_LEGEND))
    frames.append(legend_image(POST_TOP, pal, BOARD_LEGEND, cell, top=False))
    # step 2: 14 15 two more plank middles, 16 17 two more cap middles, 18 to 21 the lid, 22 its batten
    frames += [legend_image(t, pal, BOARD_LEGEND) for t in (PLANK_M3, PLANK_M4)]
    frames += [legend_image(t, pal, BOARD_LEGEND, cell, top=False) for t in (CAP_M2, CAP_M3)]
    frames += [legend_image(t, pal, BOARD_LEGEND) for t in (LID_L, LID_M1, LID_M2, LID_R, BATTEN)]
    # step 3: 23 24 the crook pointing right (the post's top with the bend, then the arm's end, hook and chain), 25 26
    # the crook pointing left (the arm's end, hook and chain, then the post's top with the bend)
    for crook in (CROOK_RIGHT, CROOK_LEFT):
        frames.append(legend_image([r[:6] for r in crook], pal, BOARD_LEGEND))
        frames.append(legend_image([r[6:] for r in crook], pal, BOARD_LEGEND))
    # step 3: 27 the fifth plank middle, with its knot
    frames.append(legend_image(PLANK_M5, pal, BOARD_LEGEND))
    # step 4: 28 29 30 the signpost's iron bar (left end, middle, right end)
    frames += [legend_image(t, pal, BOARD_LEGEND, cell, top=False) for t in (SIGN_BAR_L, SIGN_BAR_M, SIGN_BAR_R)]
    return frames


def coin_frames(faces, edge, half, pal, w, h):
    """A coin of the count: its faces, each with its ink edge, then its edge and its half turn as it turns, centred in
    the same cell."""
    frames = [edged(grid_image(face, pal), pal) for face in faces]
    frames.append(edged(grid_image(edge, pal), pal, w, h))
    frames.append(edged(grid_image(half, pal), pal, w, h))
    return frames


def bar_hollow(with_bar, pal, face=None):
    img = grid_image(HOLLOW_BAR, pal)
    if with_bar:
        bar = grid_image(face or COIN_BAR, pal)
        ox = (img.w - bar.w) // 2
        oy = (img.h - bar.h) // 2
        for y in range(bar.h):
            for x in range(bar.w):
                c = bar.get(x, y)
                if c[3]:
                    img.set(x + ox, y + oy, c)
    return img


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
    if sprite == "payCoin":
        return coin_frames([PAY_SMALL, PAY_SMALL_B, PAY_SMALL_C], PAY_SMALL_EDGE, PAY_SMALL_HALF, pal, 7, 7)
    if sprite == "hudCoinTen":
        return coin_frames([COIN_TEN, COIN_TEN_B, COIN_TEN_C], COIN_TEN_EDGE, COIN_TEN_HALF, pal, 11, 11)
    if sprite == "hudHollow":
        return [grid_image(HOLLOW_SMALL, pal)] + [hollow_with_coin(HOLLOW_SMALL, c, pal)
                                                  for c in (PAY_SMALL, PAY_SMALL_B, PAY_SMALL_C)]
    if sprite == "hudHollowTen":
        return [grid_image(HOLLOW_TEN, pal)] + [hollow_with_coin(HOLLOW_TEN, c, pal)
                                                for c in (COIN_TEN, COIN_TEN_B, COIN_TEN_C)]
    if sprite == "hudFace":
        faces = FACE_STYLES[face or FACE_STYLE]
        return [edged(grid_image(faces[k], pal), pal) for k in ("glad", "even", "grim", "unrest")]
    if sprite == "hudDawn":
        return [edged(grid_image(DAWN, pal), pal)]
    if sprite == "hudPeople":
        return [people(pal)]
    if sprite == "hudGear":
        return [edged(grid_image(GEAR, pal), pal)]
    if sprite == "hudCoinBar":
        return coin_frames([COIN_BAR, COIN_BAR_B, COIN_BAR_C], COIN_BAR_EDGE, COIN_BAR_HALF, pal, 13, 8)
    if sprite == "hudHollowBar":
        return [bar_hollow(False, pal)] + [bar_hollow(True, pal, c) for c in (COIN_BAR, COIN_BAR_B, COIN_BAR_C)]
    if sprite == "payBoard":
        return board_tiles(pal)
    if sprite == "siteLantern":
        return [lantern_frame(k, pal) for k in ("unlit", "lit", "bloom1", "bloom2")]
    if sprite == "siteHalo":
        return [halo(), pool()]
    if sprite == "paySign":
        return model_frames(pal)
    raise SystemExit("unknown sprite " + sprite)


SPRITES = ["hudFigures", "hudArrow", "hudCoin", "hudCoinTen", "hudHollow", "hudHollowTen", "hudFace", "hudPeople",
           "hudGear", "hudDawn", "hudCoinBar", "hudHollowBar", "payBoard", "siteLantern", "payCoin", "siteHalo",
           "paySign"]


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
