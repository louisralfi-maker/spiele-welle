#!/usr/bin/env python3
"""Lanternhold art pass (look 2, stage 4; ART-look2.md section 15): the castle grows. Pure python on pixelart.py's
Image; palette colours only; no randomness (hashes of the position), so a run reproduces its files byte for byte.
Called by tools/build-art-world.sh (lane "castleTiers", after castleFront, castleKeep and castleBackGate exist).

  castleart.py tiers <Resources/Art> [--far-only]
      the castle's tiers 2 and 3 as sprites that stand with the existing castle (proposals, SPRITES.md "The castle
      grows"), each with its building state (timber scaffolds, ladders, a crane, half-laid courses):
        keepTop2, keepTop2Build      150x140  the rise behind the front (replaces keepTop, same anchor)
        keepTop3, keepTop3Build      150x140
        castleFront3, castleFront3Build 268x236  the front with its two massive drum towers (replaces castleFront, 14 px
                                     further left)
        castleFrontScaffold          240x236  the scaffolding before the gatehouse (an overlay for any tier)
        backTop2, backTop2Build      100x140  the rise behind the back gate
        backTop3, backTop3Build      100x140
        farCastle2, farCastle2Build, farCastle3, farCastle3Build          48x48  the far castle in the Weltmauer's slot
        farCastleBack2, farCastleBack2Build, farCastleBack3, farCastleBack3Build  48x48  the same from the valley
        farCastle2Glow, farCastle3Glow, farCastleBack2Glow, farCastleBack3Glow   their lit panes (glow strips)
        farCleftGlow2, …2Build, …3, …3Build, farCleftGlowBack2, …  44x72  the slot's night glow with that castle cut out

Light from the upper left: lit top and left edges, a dark inner edge on the right, round towers shaded in bands
(the front towers' bands), sparse joints as in the castle's paintings.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import pixelart as PA  # noqa: E402
import worldart as WA  # noqa: E402

col, load, blit, h01 = WA.col, WA.load, WA.blit, WA.h01
STONE = ["stoneDark", "stoneMid", "stone", "stoneLight", "stonePale"]
SIDX = {col(n): i for i, n in enumerate(STONE)}
DARK = "night1"


def px(im, x, y, name):
    if 0 <= x < im.w and 0 <= y < im.h:
        im.set(x, y, col(name))


def rect(im, x0, y0, x1, y1, name):
    for y in range(max(0, y0), min(im.h, y1 + 1)):
        for x in range(max(0, x0), min(im.w, x1 + 1)):
            im.set(x, y, col(name))


def shift(im, x, y, d):
    i = SIDX.get(im.get(x, y))
    if i is not None and d:
        im.set(x, y, col(STONE[max(0, min(len(STONE) - 1, i + d))]))


def shade(im, x0, x1, y0, y1, d):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            shift(im, x, y, d)


def masonry(im, x0, y0, x1, y1, seed, course=7, block=12):
    """Flat stone with sparse joints in a running bond: long horizontal joints, short vertical ones, a block here and
    there one step lighter or darker (as the castle's paintings)."""
    rect(im, x0, y0, x1, y1, "stone")
    k = 0
    y = y0 + (seed % course)
    while y <= y1:
        off = (k * (block // 2) + int(h01(seed, k, 7) * 4)) % block
        bx = x0 - off
        n = 0
        while bx <= x1:
            r = h01(seed, k, n)
            if r < 0.62:                                   # the joint under this block
                for x in range(max(x0, bx + 1), min(x1, bx + block - 1) + 1):
                    px(im, x, y, "stoneMid")
            if h01(seed, k, n, 3) < 0.5 and x0 < bx < x1:   # its left joint, short
                for yy in range(y + 1, min(y1, y + 1 + int(2 + h01(seed, k, n, 5) * (course - 3))) + 1):
                    px(im, bx, yy, "stoneMid")
            t = h01(seed, k, n, 9)
            if t < 0.07 or t > 0.93:                       # a paler or darker block
                for yy in range(y + 1, min(y1, y + course - 1) + 1):
                    for x in range(max(x0, bx + 1), min(x1, bx + block - 1) + 1):
                        shift(im, x, yy, 1 if t < 0.07 else -1)
            bx += block
            n += 1
        y += course
        k += 1


BANDS = ((0.15, 0), (0.37, 1), (0.56, 0), (0.83, -1), (2.0, -2))  # a round tower's bands (the front towers')


def cylinder(im, x0, x1, y0, y1):
    w = x1 - x0 + 1
    edges, last = [], None
    for x in range(x0, x1 + 1):
        f = (x - x0 + 0.5) / w
        d = next(v for lim, v in BANDS if f < lim)
        if last is not None and d != last:
            edges.append((x, last))
        last = d
        for y in range(y0, y1 + 1):
            shift(im, x, y, d)
    for x, was in edges:                                   # soft terminators: a checker on the band's first column
        f = (x - x0 + 0.5) / w
        d = next(v for lim, v in BANDS if f < lim)
        for y in range(y0, y1 + 1):
            if (x + y) % 2:
                shift(im, x, y, was - d)


def crown(im, x0, x1, top, s, seed, pale=False):
    """A corbelled, crenellated crown over the shaft x0..x1, its merlons' tops at row top. s: 1 small, 2 large.
    Returns the first row of the shaft below it."""
    ov = 2 if s == 1 else 6
    mw, mh, gap, band, cor = ((4, 5, 3, 4, 4), (7, 9, 5, 7, 11))[s - 1]
    a, b = x0 - ov, x1 + ov
    for yy in range(top, top + mh + band + cor):             # the crown replaces the shaft's rows
        for xx in range(max(0, a), min(im.w, b + 1)):
            im.set(xx, yy, WA.CLEAR)
    n = max(2, (b - a + 1 + gap) // (mw + gap))
    span = n * mw + (n - 1) * gap
    slack = (b - a + 1) - span                               # spread over the gaps from the middle outward
    x = a
    for i in range(n):
        w = mw + (1 if i < slack - (n - 1) * (slack // max(1, n - 1)) else 0) if n == 1 else mw
        rect(im, x, top, x + w - 1, top + mh - 1, "stone")
        rect(im, x, top, x + w - 1, top, "stonePale" if pale else "stoneLight")
        for y in range(top + 1, top + mh):
            px(im, x + w - 1, y, "stoneMid")
        g = gap + (slack // (n - 1) if n > 1 else 0) + (1 if i < slack % max(1, n - 1) else 0)
        if s == 2 and i < n - 1:                              # the far parapet seen through the embrasure
            rect(im, x + w, top + 3, x + w + g - 1, top + mh - 1, "stoneDark")
            rect(im, x + w, top + 3, x + w + g - 1, top + 3, "stoneMid")
        x += w + g
    y = top + mh
    rect(im, a, y, b, y + band - 1, "stone")
    for xx in range(a, b + 1):                               # the embrasures' sills catch the light
        if not im.get(xx, y - 1)[3]:
            px(im, xx, y, "stoneLight")
    if s == 2:
        for xx in range(a + 1, b):                            # a string course
            if h01(seed, xx // 9, 31) < 0.8:
                px(im, xx, y + band - 3, "stoneMid")
    y += band
    step = 3                                                 # corbels with dark gaps, stepping in toward the shaft
    for r in range(cor):
        inset = (r * ov) // cor
        for xx in range(a + inset, b - inset + 1):
            if s == 1:
                dark = (xx - a) % 5 >= step
                px(im, xx, y + r, DARK if dark else ("stoneMid" if r == cor - 1 else "stone"))
                continue
            ph = (xx - a) % 7                                 # large: 3 px corbels, 4 px openings with arched heads
            dark = ph >= step and r >= 1
            if ph in (3, 6) and r == 1:
                dark = False
            if r >= cor - 3 and ph != 1:                      # the corbels taper to their feet
                dark = True
            if r == cor - 1:
                dark = True
            name = DARK if dark else ("stoneLight" if ph == 0 and 1 < r < cor - 3 else "stone")
            px(im, xx, y + r, name)
    y += cor
    for r in range(2 if s == 1 else 5):                      # the crown's shadow on the shaft
        for xx in range(x0, x1 + 1):
            if im.get(xx, y + r)[3]:
                shift(im, xx, y + r, -1)
    return y


def slit(im, x, y, w, h, glow=None):
    """An arched opening (its top-left at x, y); the lit ones are listed in glow as (x, y, w, h)."""
    for yy in range(y, y + h):
        for xx in range(x, x + w):
            if yy == y and w >= 4 and xx in (x, x + w - 1):
                continue
            px(im, xx, yy, DARK)
    for xx in range(x - 1, x + w + 1):
        px(im, xx, y + h, "stoneLight")
    if w >= 4:                                                # a dressed surround: lintel, jambs, a sill that juts
        for xx in range(x, x + w):
            px(im, xx, y - 1, "stoneLight")
        for yy in range(y + 1, y + h):
            px(im, x - 1, yy, "stoneLight"); px(im, x + w, yy, "stoneMid")
        px(im, x - 2, y + h, "stoneLight"); px(im, x + w + 1, y + h, "stoneLight")
        for xx in range(x - 1, x + w + 1):
            px(im, xx, y + h + 1, "stoneMid")
    if glow is not None:
        glow.append((x, y, w, h))


def inner_edges(im):
    """Light from the upper left: a lit edge where nothing stands left of a stone pixel, a dark inner edge on the
    right and under overhangs."""
    for y in range(im.h):
        for x in range(im.w):
            p = im.get(x, y)
            if not p[3] or p not in SIDX:
                continue
            if x + 1 >= im.w or not im.get(x + 1, y)[3]:
                im.set(x, y, col(DARK))
            elif x == 0 or not im.get(x - 1, y)[3]:
                shift(im, x, y, 1)


def tower(dst, x0, x1, top, bot, seed, s=1, round_=True, slits=(), glow=None, built=None, course=7, block=11, rings=()):
    """A tower on its own layer, then onto dst. built: None, or the row its half-laid courses have reached."""
    L = PA.Image(dst.w, dst.h)
    ov = 2 if s == 1 else 6
    if built is None:
        masonry(L, x0, top, x1, bot, seed, course, block)
        y = crown(L, x0, x1, top, s, seed)
        for yy in range(top, y):                             # the shaft's own pixels inside the crown rows belong to it
            pass
    else:
        masonry(L, x0, built - 2 * course, x1, bot, seed, course, block)
        ragged(L, x0, x1, built, seed, course)
    for r in rings:                                          # a string course round the shaft
        if built is None or r > built + course:
            for xx in range(x0 - 1, x1 + 2):
                px(L, xx, r, "stoneLight"); px(L, xx, r + 1, "stone"); px(L, xx, r + 2, "stoneMid")
    for sx, sy, sw, sh, lit in slits:
        if built is None or sy > built + course:
            slit(L, sx, sy, sw, sh, glow if lit and built is None else None)
    if round_:
        cylinder(L, x0 - ov, x1 + ov, top, bot)
    inner_edges(L)
    blit(dst, L, 0, 0)


def ragged(L, x0, x1, built, seed, course=7):
    """Half-laid courses: the top steps down in whole blocks, the newest stones pale."""
    x = x0
    n = 0
    while x <= x1:
        w = 5 + int(h01(seed, n, 41) * 5)
        cut = built + course * (int(h01(seed, n, 43) * 3) - 2) + 1
        for xx in range(x, min(x1, x + w - 1) + 1):
            for yy in range(0, cut):
                if 0 <= yy < L.h:
                    L.set(xx, yy, WA.CLEAR)
            if 0 <= cut < L.h:
                px(L, xx, cut, "stonePale")
                px(L, xx, cut + 1, "stoneLight")
        x += w
        n += 1


def wall(dst, x0, x1, top, bot, seed, built=None, merlons=True):
    """A curtain wall with merlons (their tops at row top)."""
    L = PA.Image(dst.w, dst.h)
    if built is None:
        masonry(L, x0, top + 5, x1, bot, seed)
        if merlons:
            x = x0
            while x + 4 <= x1:
                rect(L, x, top, x + 4, top + 4, "stone")
                rect(L, x, top, x + 4, top, "stoneLight")
                for y in range(top + 1, top + 5):
                    px(L, x + 4, y, "stoneMid")
                x += 9
        for x in range(x0, x1 + 1):
            if not L.get(x, top + 4)[3]:
                px(L, x, top + 5, "stoneLight")
        for x in range(x0, x1 + 1):                          # a corbel table under the parapet: dark arches
            px(L, x, top + 10, "stoneLight")
            ph = (x - x0) % 5
            for r in range(4):
                px(L, x, top + 11 + r, "stone" if ph < 2 or (r == 0 and ph in (2, 4)) else DARK)
            px(L, x, top + 15, "stoneMid")
    else:
        masonry(L, x0, built - 14, x1, bot, seed)
        ragged(L, x0, x1, built, seed)
    blit(dst, L, 0, 0)


# ------------------------------------------------------------------------------------------------ timber
def pole(im, x, y0, y1):
    for y in range(y0, y1 + 1):
        px(im, x, y, "woodLight" if y % 9 else "straw")      # lashings
        px(im, x + 1, y, "woodDark")


def deck(im, x0, x1, y):
    for x in range(x0, x1 + 1):
        px(im, x, y, "woodLight" if (x // 4) % 3 else "wood")
        px(im, x, y + 1, "woodDark")


def line(im, xa, ya, xb, yb, name):
    n = max(abs(xb - xa), abs(yb - ya), 1)
    for i in range(n + 1):
        px(im, int(round(xa + (xb - xa) * i / n)), int(round(ya + (yb - ya) * i / n)), name)


def ladder(im, x, y0, y1):
    for y in range(y0, y1 + 1):
        px(im, x, y, "wood"); px(im, x + 3, y, "woodDark")
        if y % 3 == 0:
            px(im, x + 1, y, "woodLight"); px(im, x + 2, y, "woodLight")


def scaffold(im, x0, x1, top, bot, bays=None, seed=0, decks=14, ladders=True):
    """A timber scaffold: poles, decks every `decks` rows, a brace per bay, a ladder between two decks."""
    xs = bays or list(range(x0, x1, 13)) + [x1 - 1]
    rows = list(range(bot - decks, top, -decks))
    for i in range(len(xs) - 1):                             # braces behind
        for j, y in enumerate(rows + [top]):
            if (i + j) % 2 == 0:
                a, b = (xs[i] + 1, xs[i + 1]) if (i + j + seed) % 4 else (xs[i + 1], xs[i] + 1)
                line(im, a, y + decks - 1, b, y + 2, "woodDark")
    for y in rows:
        deck(im, x0 - 1, x1 + 1, y)
    for x in xs:
        pole(im, x, top - 3 - int(h01(seed, x, 3) * 5), bot)
    if ladders:
        for j, y in enumerate(rows[:-1] if len(rows) > 1 else rows):
            lx = xs[(j + seed) % max(1, len(xs) - 1)] + 3
            ladder(im, lx, rows[j + 1] if j + 1 < len(rows) else top, y - 1)
    return rows


def crane(im, x, y, h, reach, drop, flip=False, block=True):
    """A slewing crane: a mast from its foot (x, y) up h rows, a jib reaching out, a rope and a hoisted stone."""
    d = -1 if flip else 1
    pole(im, x, y - h, y)
    line(im, x - 4 * d, y, x, y - h // 2, "woodDark")                    # the back stay
    tipx, tipy = x + reach * d, y - h - reach // 3
    line(im, x, y - h + 3, tipx, tipy, "woodLight")
    line(im, x, y - h + 4, tipx, tipy + 1, "woodDark")
    line(im, x, y - h // 2, tipx - 3 * d, tipy + 3, "wood")              # the jib's strut
    for yy in range(tipy + 1, tipy + drop):
        px(im, tipx, yy, "straw")
    if block:
        rect(im, tipx - 2, tipy + drop, tipx + 2, tipy + drop + 2, "stoneLight")
        rect(im, tipx - 2, tipy + drop, tipx + 2, tipy + drop, "stonePale")
        rect(im, tipx - 2, tipy + drop + 3, tipx + 2, tipy + drop + 3, "stoneMid")
    return tipx, tipy


def stack(im, x, y, n=3):
    """Cut stones waiting on a deck (their feet on row y)."""
    for i in range(n):
        xx, yy = x + (i % 2) * 5 + (2 if i >= 2 else 0), y - 3 - (3 if i >= 2 else 0)
        rect(im, xx, yy, xx + 3, yy + 2, "stoneLight")
        rect(im, xx, yy, xx + 3, yy, "stonePale")
        px(im, xx + 3, yy + 1, "stoneMid"); px(im, xx + 3, yy + 2, "stoneMid")


def flag(im, x, top, h, right=True):
    for y in range(top, top + h):
        px(im, x, y, DARK)
    d = 1 if right else -1
    for i in range(1, 12):
        yy = top + 1 + (1 if 3 < i < 8 else 0)
        for k in range(5 - (1 if i > 9 else 0)):
            px(im, x + i * d, yy + k, "roofDeep" if (i + k) % 5 else "banner")
    px(im, x + 11 * d, top + 3, "roofDeep")


def banner(im, x, y, w, h):
    """A hanging banner in the realm's teal with a lit fold and the lantern in gold."""
    rect(im, x, y, x + w - 1, y + h - 1, "roofDeep")
    rect(im, x - 1, y - 1, x + w, y - 1, "woodDark")
    for yy in range(y, y + h):
        px(im, x + 1, yy, "banner")
        if w >= 8:
            px(im, x + w - 3, yy, "banner" if yy % 7 < 4 else "roofDeep")
    c = x + w // 2
    for dx, dy in ((0, 0), (-1, 1), (0, 1), (1, 1), (-1, 2), (1, 2), (-1, 3), (0, 3), (1, 3)):
        px(im, c + dx, y + h // 2 - 2 + dy, "gold")
    for xx in range(x, x + w):                                # a swallow-tailed hem
        if abs(xx - c) < w // 4 + 1:
            px(im, xx, y + h - 1, "stone"); im.set(xx, y + h - 1, WA.CLEAR) if False else None


def masks(name, im, glow):
    """The lit panes as the layout's masks: (dx, dy from the sprite's bottom, w, h)."""
    ms = [(x, im.h - y - h, w, h) for x, y, w, h in glow]
    print(f"  {name} {im.w}x{im.h} masks {ms}")
    return ms


# ------------------------------------------------------------------------------------------------ the rise behind the front
RW, RH = 150, 140   # keepTop2/3: at keepTop's anchor (K, y 40): row r is y 180 - r; visible above the wall walk between
                    # the front's towers: columns 11..136, rows 2..53 (the gatehouse's turrets hide 36..64 and 84..110
                    # below row 26)


def keep_block(im, x0, x1, top, seed, glow, windows, built=None):
    L = PA.Image(im.w, im.h)
    if built is None:
        masonry(L, x0, top, x1, im.h - 1, seed, 8, 14)
        crown(L, x0 + 2, x1 - 2, top, 1, seed)
    else:
        masonry(L, x0, built - 16, x1, im.h - 1, seed, 8, 14)
        ragged(L, x0, x1, built, seed, 8)
    for wx, wy, ww, wh in windows:
        if built is None or wy > built + 8:
            slit(L, wx, wy, ww, wh, glow if built is None else None)
    for y in range(top, im.h):                               # the keep's lit corner
        if L.get(x0, y)[3] and L.get(x0, y) in SIDX:
            px(L, x0, y, "stoneLight")
    inner_edges(L)
    blit(im, L, 0, 0)


def rise(tier, build):
    im = PA.Image(RW, RH)
    glow = []
    # tier 2: the keep raised (its crown at y 164 instead of 144, two lit windows under it) and a slim round tower
    # at its left shoulder (crown at y 177). In its building state the old keep's crown stands (y 144, as keepTop),
    # the new storey half laid behind scaffolds, the tower begun.
    if tier == 2:
        if build:
            keep_block(im, 30, 149, 16, 5, None, [], built=31)
            scaffold(im, 40, 86, 12, RH - 1, bays=[40, 52, 64, 75, 86], seed=1, decks=13)
            crane(im, 70, 22, 13, 15, 9, flip=False)
            scaffold(im, 112, 138, 17, RH - 1, bays=[112, 125, 137], seed=2, decks=13)
            stack(im, 115, 35)
            tower(im, 14, 33, 3, RH - 1, 11, slits=[(23, 50, 2, 7, False)], built=33)
            scaffold(im, 11, 36, 14, RH - 1, bays=[11, 35], seed=3, decks=13, ladders=False)
            ladder(im, 20, 15, 27)
        else:
            keep_block(im, 30, 149, 16, 5, glow, [(71, 37, 6, 10), (120, 37, 5, 9), (139, 37, 5, 9)])
            flag(im, 74, 2, 14)
            tower(im, 14, 33, 3, RH - 1, 11, slits=[(23, 24, 2, 7, True), (23, 44, 2, 7, False)], glow=glow)
    # tier 3: the inner curtain wall (the second wall: its merlons at y 146 behind the gatehouse) between two drum
    # towers that stand inside the front's towers (crowns at y 177), the keep's crown between them
    else:
        if build:
            keep_block(im, 30, 149, 16, 5, glow, [(71, 37, 6, 10)])
            flag(im, 74, 2, 14)
            tower(im, 14, 33, 3, RH - 1, 11, slits=[(23, 24, 2, 7, True)], glow=glow)   # tier 2's tower still stands
            wall(im, 34, 110, 34, RH - 1, 21, built=44)
            tower(im, 108, 139, 3, RH - 1, 13, slits=[], built=28, block=13)
            scaffold(im, 105, 142, 12, RH - 1, bays=[105, 118, 130, 141], seed=5, decks=13)
            crane(im, 120, 13, 10, 13, 8, flip=True)
            scaffold(im, 65, 84, 30, RH - 1, bays=[65, 83], seed=6, decks=12, ladders=False)
            stack(im, 68, 42, 2)
        else:
            keep_block(im, 34, 112, 16, 5, glow, [(71, 37, 6, 10)])
            flag(im, 74, 2, 14)
            shade(im, 34, 110, 26, 40, -1)                    # the keep behind the inner wall's parapet, in its shade
            wall(im, 34, 110, 34, RH - 1, 21)
            banner(im, 70, 52, 9, 14)
            tower(im, 6, 37, 3, RH - 1, 11, slits=[(20, 24, 3, 8, True), (20, 46, 3, 8, False)], glow=glow, block=13)
            tower(im, 108, 139, 3, RH - 1, 13, slits=[(122, 24, 3, 8, True), (122, 46, 3, 8, False)], glow=glow, block=13)
    return im, glow


# ------------------------------------------------------------------------------------------------ the rise behind the back gate
BW, BH = 100, 140   # backTop2/3: at (B + 50, y 40): visible above the back gate's curtain between its towers: columns
                    # 10..90, rows 2..58


def back_rise(tier, build):
    im = PA.Image(BW, BH)
    glow = []
    if tier == 2:
        if build:
            keep_block(im, 8, 70, 16, 7, None, [], built=31)
            scaffold(im, 12, 66, 12, BH - 1, bays=[12, 26, 40, 53, 65], seed=4, decks=13)
            crane(im, 44, 22, 13, 13, 9, flip=True)
            stack(im, 15, 35)
            tower(im, 70, 89, 3, BH - 1, 15, slits=[], built=34)
            scaffold(im, 67, 92, 16, BH - 1, bays=[67, 91], seed=7, decks=13, ladders=False)
            ladder(im, 78, 18, 31)
        else:
            keep_block(im, 8, 70, 16, 7, glow, [(22, 37, 5, 9), (36, 37, 6, 10), (52, 37, 5, 9)])
            flag(im, 39, 2, 14, right=False)
            banner(im, 35, 52, 9, 14)
            tower(im, 70, 89, 3, BH - 1, 15, slits=[(79, 24, 2, 7, True), (79, 44, 2, 7, False)], glow=glow)
    else:
        if build:
            keep_block(im, 8, 70, 16, 7, glow, [(36, 37, 6, 10)])
            flag(im, 39, 2, 14, right=False)
            tower(im, 70, 89, 3, BH - 1, 15, slits=[(79, 24, 2, 7, True)], glow=glow)
            wall(im, 30, 72, 34, BH - 1, 23, built=45)
            tower(im, 8, 33, 3, BH - 1, 17, slits=[], built=30, block=13)
            scaffold(im, 5, 36, 12, BH - 1, bays=[5, 20, 35], seed=8, decks=13)
            crane(im, 22, 15, 10, 12, 8)
            stack(im, 40, 43, 2)
        else:
            keep_block(im, 30, 70, 16, 7, glow, [(46, 37, 6, 10)])
            flag(im, 50, 2, 14, right=False)
            shade(im, 30, 72, 26, 40, -1)
            wall(im, 30, 72, 34, BH - 1, 23)
            banner(im, 45, 52, 9, 14)
            tower(im, 8, 33, 3, BH - 1, 17, slits=[(19, 24, 3, 8, True), (19, 46, 3, 8, False)], glow=glow, block=13)
            tower(im, 66, 91, 3, BH - 1, 15, slits=[(77, 24, 3, 8, True), (77, 46, 3, 8, False)], glow=glow, block=13)
    return im, glow


# ------------------------------------------------------------------------------------------------ the front with massive towers
def front3(art, build):
    """castleFront with its two towers rebuilt as massive drums: 268x236, the old front 14 px to the right in it (so
    the gateway, the wall walk and the turrets keep their places); the drums' shafts 60 px wide (were 43), crowns 74,
    on battered plinths. Building state: the left drum stands, the right one is half laid inside its scaffold."""
    old = load(os.path.join(art, "castleFront.png"))
    im = PA.Image(268, 236)
    glow = []
    blit(im, old, 14 + 58, 104, box=(58, 104, 182, 236))     # the gatehouse between the old towers
    blit(im, old, 14 + 66, 0, box=(66, 0, 172, 104))         # and what stands on its wall walk
    def drum(x0, x1, seed, built, mirror):
        slits = [(x0 + 27, 97, 4, 12, True), (x0 + 27, 131, 4, 12, True), (x0 + 27, 168, 4, 12, False)]
        L = PA.Image(im.w, im.h)
        tower(L, x0, x1, 62, 235, seed, s=2, slits=slits, glow=glow if built is None else None, built=built, block=14,
              rings=(114, 152))
        for r in range(26):                                   # the battered plinth: the foot widens by 4 px
            y = 235 - r
            wdt = (26 - r) * 4 // 26
            for k in range(1, wdt + 1):
                px(L, x0 - k, y, "stoneLight" if k == wdt else "stone")
                px(L, x1 + k, y, DARK if k == wdt else "stoneDark")
        for xx in range(x0 - 4, x1 + 5):                      # the plinth's top course
            if L.get(xx, 209)[3] and L.get(xx, 209) in SIDX:
                shift(L, xx, 209, -1)
        blit(im, L, 0, 0)
    drum(12, 71, 31, None, False)
    drum(196, 255, 37, 128 if build else None, True)
    blit(im, old, 0, 212, box=(2, 212, 31, 236))             # the old towers' rubble and ivy at the drums' outer feet
    blit(im, old, 237, 212, flip=True, box=(0, 212, 31, 236))
    if build:
        scaffold(im, 190, 262, 96, 235, bays=[190, 204, 218, 232, 246, 261], seed=9, decks=22)
        crane(im, 226, 118, 20, 20, 16, flip=True)
        stack(im, 238, 213); stack(im, 202, 169, 2)
    for xx in range(0, 268):                                  # the ground contact
        if im.get(xx, 235)[3] and im.get(xx, 235) in SIDX:
            px(im, xx, 235, "stoneDark")
    return im, glow


def front_scaffold():
    """The scaffolding before the gatehouse (240x236, at castleFront's anchor, drawn before it): two bays each side of
    the gateway up to the wall walk, ladders, cut stones, and a crane on the wall walk hoisting a stone over the gate."""
    im = PA.Image(240, 236)
    scaffold(im, 60, 94, 118, 235, bays=[60, 72, 84, 94], seed=12, decks=24)
    scaffold(im, 146, 180, 118, 235, bays=[146, 156, 168, 180], seed=13, decks=24)
    stack(im, 62, 211); stack(im, 160, 187, 2); stack(im, 150, 139)
    crane(im, 112, 112, 22, 16, 22, flip=False)
    return im


# ------------------------------------------------------------------------------------------------ the far castles
FW, FH = 48, 48     # the far tiers: at the baked far castle's place (its 40x46 box centred, its foot on the last row)


def far_base(art, back):
    front = load(os.path.join(art, "castleFront.png"))
    gate = load(os.path.join(art, "castleBackGate.png"))
    keep = load(os.path.join(art, "keepTop.png"))
    big, pane = WA.far_castle(gate, keep, 20, WA.KEEP_FAR[1]) if back else WA.far_castle(front, keep, 0, WA.KEEP_FAR[0])
    m = WA.mini_castle(big)
    if back:
        f = PA.Image(m.w, m.h)
        blit(f, m, 0, 0, flip=True)
        m = f
    return m


def far_tier(art, tier, build, back):
    """The far castle as a dark silhouette before the cleft's light, grown: the baked tier 1 stays under it (every
    pixel of it is kept), the keep taller with a second tower beside it (tier 2), a higher inner wall with two massive
    towers behind the front (tier 3). Building: the new parts half high inside a lattice of poles, a crane's jib."""
    m = far_base(art, back)
    im = PA.Image(FW, FH)
    ox, oy = (FW - m.w) // 2, FH - m.h
    S, Dp = "stoneDark", "farDeep"
    add = PA.Image(FW, FH)
    tops = [next((y for y in range(m.h) if m.get(x, y)[3]), m.h) for x in range(m.w)]
    kx0 = next(x for x in range(m.w // 2 - 2, 0, -1) if tops[x] > tops[m.w // 2] + 4) + 1   # the keep's head
    kx1 = next(x for x in range(m.w // 2 + 2, m.w) if tops[x] > tops[m.w // 2] + 4) - 1
    ktop = min(tops[kx0 + 1:kx1])
    wtop = max(tops[kx0 - 3], tops[kx1 + 3])                  # the walls between keep and towers
    ttop = min(tops[2:8])                                     # the towers' tops
    sgn = -1 if back else 1
    def box(x0, y0, x1, y1, c=S):
        for y in range(y0, y1 + 1):
            for x in range(min(x0, x1), max(x0, x1) + 1):
                px(add, ox + x, oy + y, c)
    def merl(x0, x1, y):
        for x in range(min(x0, x1), max(x0, x1) + 1, 2):
            px(add, ox + x, oy + y, S)
    def lattice(x0, y0, x1, y1):
        for x in (x0, x1):
            for y in range(y0, y1 + 1):
                px(add, ox + x, oy + y, Dp)
        for y in range(y0 + 1, y1, 3):
            for x in range(x0, x1 + 1):
                px(add, ox + x, oy + y, Dp)
    cx = (kx0 + kx1) // 2
    tx = kx0 - 4 if not back else kx1 + 4                     # the second tower: at the keep's shoulder
    if tier == 2 and build:
        box(kx0, ktop - 2, kx1, ktop + 3)
        lattice(kx0 - 1, ktop - 6, kx1 + 1, ktop + 2)
        line(add, ox + cx, oy + ktop - 6, ox + cx + 5 * sgn, oy + ktop - 9, Dp); px(add, ox + cx + 5 * sgn, oy + ktop - 8, Dp)
        lattice(tx - 1, ktop - 3, tx + 2, wtop)
    if tier >= 2 and not (tier == 2 and build):
        box(kx0, ktop - 5, kx1, ktop + 3)                     # the keep, five rows taller
        merl(kx0, kx1, ktop - 6)
        box(kx0 - 1, ktop - 4, kx1 + 1, ktop - 3)             # its corbelled crown
        box(tx, ktop - 7, tx + 2, wtop + 4)                   # the slim tower beside it
        box(tx - 1, ktop - 7, tx + 3, ktop - 6); merl(tx - 1, tx + 3, ktop - 8)
    if tier == 3:
        wy = wtop - 5                                         # the inner wall, five rows above the front's
        lx, rx = 7, m.w - 8
        if build:
            box(lx, wy + 3, rx, wtop)
            lattice(lx - 3, ttop - 4, lx + 3, wtop); lattice(rx - 3, ttop - 4, rx + 3, wtop)
            box(lx - 2, ttop + 2, lx + 2, wtop); box(rx - 2, ttop + 4, rx + 2, wtop)
            line(add, ox + rx, oy + ttop - 4, ox + rx - 5, oy + ttop - 7, Dp); px(add, ox + rx - 5, oy + ttop - 6, Dp)
        else:
            box(lx, wy, rx, wtop); merl(lx, rx, wy - 1)
            for c in (lx, rx):                                # the massive towers: five wide, above the front's
                box(c - 2, ttop - 4, c + 2, wtop); box(c - 3, ttop - 4, c + 3, ttop - 2); merl(c - 3, c + 3, ttop - 5)
    blit(im, add, 0, 0)
    for y in range(FH):                                       # the moonlit left edge, paler faces
        for x in range(FW):
            if add.get(x, y)[3] and add.get(x, y) == col(S):
                mx, my = x - ox, y - oy
                under = 0 <= mx < m.w and 0 <= my < m.h and m.get(mx, my)[3]
                left = add.get(x - 1, y)[3] if x else 0
                lm = 0 <= mx - 1 < m.w and 0 <= my < m.h and m.get(mx - 1, my)[3]
                if not left and not lm:
                    im.set(x, y, col("moon"))
                elif h01(x // 2, y // 3, tier, 5) < 0.35:
                    im.set(x, y, col(Dp))
    blit(im, m, ox, oy)                                       # tier 1 stays as baked
    glow = PA.Image(FW, FH)
    if not build:
        px(glow, ox + cx, oy + ktop - 2, "fireGold")
        px(glow, ox + tx + 1, oy + ktop - 3, "fireGold")
        if tier == 3:
            px(glow, ox + 7, oy + ttop, "fireGold"); px(glow, ox + m.w - 8, oy + ttop + 2, "fireGold")
    return im, glow


def cmd_tiers(art, far_only=False):
    def out(name, im):
        PA.write_png(os.path.join(art, name + ".png"), im)
    for back in (False, True):
        for tier in (2, 3):
            for build in (False, True):
                im, g = far_tier(art, tier, build, back)
                name = "farCastle%s%d%s" % ("Back" if back else "", tier, "Build" if build else "")
                out(name, im)
                if not build:
                    out(name + "Glow", g)
                # the slot's night glow with this castle cut out of it (farCleftGlow is 44x72, its foot on the
                # castle's foot, 2 px inside the far tier's box)
                base = "farCleftGlow" + ("Back" if back else "")
                cg = load(os.path.join(art, base + ".png"))
                for y in range(cg.h):
                    for x in range(cg.w):
                        oy = y - (cg.h - FH)
                        if 0 <= oy < FH and im.get(x + (FW - cg.w) // 2, oy)[3]:
                            cg.set(x, y, WA.CLEAR)
                out(base + name[len("farCastleBack" if back else "farCastle"):], cg)
    if far_only:
        return
    for tier in (2, 3):
        for build in (False, True):
            im, g = rise(tier, build)
            name = "keepTop%d%s" % (tier, "Build" if build else "")
            out(name, im); masks(name, im, g)
            im, g = back_rise(tier, build)
            name = "backTop%d%s" % (tier, "Build" if build else "")
            out(name, im); masks(name, im, g)
    for build in (False, True):
        im, g = front3(art, build)
        name = "castleFront3" + ("Build" if build else "")
        out(name, im); masks(name, im, g)
    out("castleFrontScaffold", front_scaffold())


if __name__ == "__main__":
    a = sys.argv[1:]
    if len(a) >= 2 and a[0] == "tiers":
        cmd_tiers(a[1], "--far-only" in a)
    else:
        raise SystemExit(__doc__)
