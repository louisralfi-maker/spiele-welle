#!/usr/bin/env python3
"""Lanternhold look 2, stage 2: assembles the world sprites from converted paintings (ART-look2.md, "Stage 2: the
world art"). Pure python on pixelart.py's Image; every colour is a palette colour; no randomness (hashes of the
position), so a run reproduces its files byte for byte. Called by tools/build-art-world.sh.

  wall <wallA> <wallB> <castleFront> <keepTop> <castleBackGate> <out dir>
      weltmauer.png      the Weltmauer on the far plane: wallA and the mirrored wallB side by side, its ridge set to
                         seven massifs, regraded to granite below a snow line, the cleft cut through it twice (the
                         view from the shadow land, the view from the valley), in each the far castle as a dark
                         silhouette at 1/6 before the cleft's light (ART-look2.md 14)
      weltmauerPatch.png the piece of unbroken wall that covers the valley's view of the cleft until the town
      farCastleGlow.png  the lit windows of the far castle seen from the shadow land (a glow strip)
      farCastlePane.png  the one lit pane of the keep seen from the town (a glow strip)
      farCleftGlow.png, farCleftGlowBack.png
                         the light in each slot without the castle before it (emissive strips for the night)
  gorge <rock> <out> <out crags>
                         the gorge's wall in granite: steps down to the ground at its left end (the mouth) and down to
                         the cleft face's height at its right end, lit top edges; and the crags that stand before
                         its mouth as a sprite of their own (near plane)
  face <rock> <out> <out end>
                         the cleft's inner face with a lit top edge, and its end stepping down toward the valley
  slope <vista> <out>    the valley vista with its left end cut to a rising slope (it stands before the wall's end)
  taper <forest> <out> <span>
                         the forest with its left end sinking to the ground in fir-shaped teeth
  main <in> <out>        keeps the largest connected piece of a sprite (a tree cut from a sheet loses the neighbours'
                         fragments)
  retex <shape> <rock> <out>
                         a cliff in an old sprite's silhouette: the rock painting inside the old sprite's alpha, lit
                         top and left edges, a dark right edge (the cleft's flanks keep their sizes and positions)
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import pixelart as PA  # noqa: E402

PA.MATCH = "new"
PAL = PA.Palette(PA.DEFAULT_PALETTE, True)
CLEAR = (0, 0, 0, 0)


def col(name):
    r, g, b = PAL.color(name)[:3]
    return (r, g, b, 255)


def load(path):
    return PA.read_png(path)[0]


def h01(*k):  # a hash of integers in [0, 1)
    v = 2166136261
    for a in k:
        v = ((v ^ (a & 0xFFFFFFFF)) * 16777619) & 0xFFFFFFFF
        v ^= v >> 13
    v = (v * 2654435761) & 0xFFFFFFFF
    return (v >> 8) / float(1 << 24)


def blit(dst, src, ox, oy, flip=False, box=None):
    x0, y0, x1, y1 = box or (0, 0, src.w, src.h)
    for y in range(y0, y1):
        for x in range(x0, x1):
            p = src.get(x1 - 1 - (x - x0) if flip else x, y)
            if p[3]:
                tx, ty = ox + x - x0, oy + y - y0
                if 0 <= tx < dst.w and 0 <= ty < dst.h:
                    dst.set(tx, ty, p)


def lum(p):
    return 0.299 * p[0] + 0.587 * p[1] + 0.114 * p[2]


# ------------------------------------------------------------------------------------------------ the far castle
FAR_K = 6   # the far castle's scale: the real castle at 1/6 (40 px wide; at 1/8 it was lost in the slot)


def mini_castle(big, k=FAR_K):
    """big: the castle at game scale on a clear ground. Returns the castle at 1/k as a dark silhouette before the
    cleft's light (fix stage, ART-look2.md 14): stoneDark, its paler faces farDeep, and a 1 px moonlit left edge
    wherever nothing stands left of a cell."""
    w, h = big.w // k, big.h // k
    out = PA.Image(w, h)
    cells = {}
    for by in range(h):
        for bx in range(w):
            n, s = 0, 0.0
            for y in range(by * k, by * k + k):
                for x in range(bx * k, bx * k + k):
                    p = big.get(x, y)
                    if p[3]:
                        n += 1
                        s += lum(p)
            if n >= k * k * 0.45:
                cells[(bx, by)] = s / n
    ls = sorted(cells.values())
    t = ls[int(len(ls) * 0.62)]
    for (bx, by), L in cells.items():
        edge = (bx - 1, by) not in cells
        out.set(bx, by, col("moon" if edge else "stoneDark" if L < t else "farDeep"))
    return out


KEEP_FAR = (0.6, 0.46)  # the keep stands deeper in the cleft than the walls before it: seen from far it is smaller
                        # (from the shadow land, from the valley: each fits the gap between that side's two towers)
KEEP_RISE = 152         # and its foot stands this far above the castle's (the cleft's floor rises behind the walls)
KEEP_PANE = (79, 46)    # the lit pane: (79, 36) in keepTop.png, set one far cell lower, off the merlons' row


def shrink(img, f):
    out = PA.Image(int(round(img.w * f)), int(round(img.h * f)))
    for y in range(out.h):
        for x in range(out.w):
            out.set(x, y, img.get(min(img.w - 1, int((x + 0.5) / f)), min(img.h - 1, int((y + 0.5) / f))))
    return out


def far_castle(walls, keep, ox, f):
    """The castle as the far plane sees it, at game scale on a 240x280 ground: the walls (the front, or the back gate
    at ox) with the keep behind them, smaller and higher, so that its head rises free above the two towers and the
    cleft's light shows between it and each tower (fix stage: at its true size and height the keep filled the gap
    between the towers and the far castle was one square block). Returns the picture and the keep's pane in it."""
    big = PA.Image(240, 280)
    k = shrink(keep, f)
    kx, ky = 120 - k.w // 2, 280 - KEEP_RISE - k.h
    blit(big, k, kx, ky)
    for y in range(ky + k.h, 280 - 60):     # its shaft runs on down behind the walls
        for x in range(k.w):
            big.set(kx + x, y, k.get(x, k.h - 1))
    blit(big, walls, ox, 280 - walls.h)
    return big, (kx + int(KEEP_PANE[0] * f), ky + int(KEEP_PANE[1] * f))


# The far castles' lights as pixels of the real castle picture (x from its left, y from its top; the real sprites'
# emitters in layout_m1b.py): the front's two tower slits and the right tower's lower slit and the two watch fires on
# the wall walk, plus the pane high in the keep; from the valley that pane alone. glow_strip() divides by the far
# castle's scale.
FRONT_LIGHTS = [(36, 180), (204, 188), (204, 204), (100, 148), (140, 148)]


def glow_strip(mini, lights, flip=False, k=FAR_K):
    out = PA.Image(mini.w, mini.h)
    for px, py in lights:
        bx, by = px // k, py // k
        if not mini.get(bx, by)[3]:
            raise SystemExit(f"light {bx},{by} lies off the far castle")
        out.set(mini.w - 1 - bx if flip else bx, by, col("fireGold"))
    return out


# ------------------------------------------------------------------------------------------------ the Weltmauer
WALL_H = 190
CASTLE_FOOT = 92   # rows from the sprite's bottom to the far castle's foot (75 px above the ground at y -17)
CLEFTS = (324, 650)
FARW = ("farDeep", "far", "mistDark", "moon", "mist", "farPale", "mistLight", "foam")

# The ridge (fix stage): the painting's row of equal teeth is drawn again as seven broad massifs. (x, row): the ridge's
# envelope, hand-set; between the points a straight line. Each massif has a summit, a shoulder or a second peak, and a
# saddle to the next one; the overall height stays even (summits at rows 6 to 14, saddles at 30 to 36). The painting's
# teeth ride on it at RIDGE_TEETH of their size. Beside each cleft (x 324 and 650) the lips: a horn on the left, a
# free pillar on the right.
RIDGE = [
    (40, 34), (52, 30), (70, 24), (84, 12), (96, 16), (104, 23), (116, 15), (128, 24), (138, 26), (150, 36),
    (158, 28), (170, 18), (184, 14), (196, 9), (206, 15), (222, 17), (236, 16), (244, 27), (252, 34),
    (262, 24), (276, 20), (288, 10), (296, 6), (304, 13), (310, 19), (324, 30), (338, 23), (342, 14), (347, 17),
    (352, 31), (360, 22), (372, 12), (384, 8), (394, 14), (404, 21), (414, 16), (424, 24), (440, 27), (452, 35),
    (462, 22), (472, 11), (482, 20), (492, 13), (500, 7), (512, 18), (524, 26), (532, 33),
    (544, 25), (556, 22), (566, 13), (580, 10), (590, 17), (604, 20), (616, 15), (626, 19), (636, 23), (650, 30),
    (664, 22), (669, 13), (674, 18), (680, 29), (690, 21), (712, 24),
]
RIDGE_TEETH, RIDGE_MEAN, RIDGE_BASE = 0.4, 18, 150   # the teeth's share, their mean row, the row the remap ends at
# each massif's lit side and shade side, by its summit: (x of the saddle left, x of the summit, x of the saddle right)
MASSIFS = [(40, 84, 150), (150, 196, 252), (252, 296, 352), (352, 384, 452), (452, 500, 532), (532, 580, 680),
           (680, 700, 760)]
SNOW_ROW = 44      # the snow line's mean row: snow on the top quarter and in the gullies, rock below
GULLY_REACH = 46   # a gully's snow runs at most this far below the snow line
COULOIRS = [(150, 37), (252, 35), (452, 36), (532, 34), (104, 24), (482, 21), (404, 22), (604, 21)]  # (x, row) heads


def vnoise(seed, u):  # smooth value noise in [0, 1)
    i = int(u) if u >= 0 else int(u) - 1
    f = u - i
    f = f * f * (3 - 2 * f)
    return h01(seed, i) * (1 - f) + h01(seed, i + 1) * f


def wall_tops(img):
    return [next((y for y in range(img.h) if img.get(x, y)[3]), img.h) for x in range(img.w)]


def reprofile(img):
    """The ridge drawn again: each column between x 40 and 712 is stretched or squeezed between its new top (RIDGE
    plus the painting's teeth at RIDGE_TEETH) and row RIDGE_BASE; the columns below that row stay. Returns the new
    tops."""
    tops = wall_tops(img)
    out = PA.Image(img.w, img.h)
    blit(out, img, 0, 0)
    for x in range(RIDGE[0][0], RIDGE[-1][0]):
        t = tops[x]
        if t >= RIDGE_BASE - 20:
            continue
        T = _run(RIDGE, x) + RIDGE_TEETH * (min(t, 34) - RIDGE_MEAN)
        wgt = min(1.0, (x - RIDGE[0][0]) / 14.0, (RIDGE[-1][0] - x) / 22.0)  # the ends keep the painting's line
        T = int(round(t + (T - t) * wgt))
        T = max(1, T)
        for y in range(RIDGE_BASE):
            if y < T:
                out.set(x, y, CLEAR)
            else:
                sy = t + (y - T) * (RIDGE_BASE - t) / float(RIDGE_BASE - T)
                out.set(x, y, img.get(x, min(RIDGE_BASE - 1, int(sy))))
    return out, wall_tops(out)


def massif_side(x, y):
    """-1 on a massif's lit side (left of its summit), +1 on its shade side (the right flank), 0 between; the limits
    wander with the row so no straight seam shows."""
    xx = x + int(14 * (vnoise(71, y / 29.0) - 0.5)) - (y - 60) // 9
    for x0, xs, x1 in MASSIFS:
        if x0 <= xx < x1:
            if xx < xs - (xs - x0) * 0.12:
                return -1
            if xx > xs + (x1 - xs) * 0.38:
                return 1
            return 0
    return 0


def snow_row(x):  # the snow line: no straight band (the painting's ran level at rows 48 to 65)
    return int(SNOW_ROW + 0.3 * (_run(RIDGE, min(max(x, RIDGE[0][0]), RIDGE[-1][0] - 1)) - RIDGE_MEAN)
               + 16 * (vnoise(31, x / 43.0) - 0.5) + 7 * (vnoise(37, x / 11.0) - 0.5) + 3 * h01(41, x // 2))


def vnoise2(seed, u, v):  # smooth value noise over a plane, in [0, 1)
    i, j = int(u // 1), int(v // 1)
    f, g = u - i, v - j
    f, g = f * f * (3 - 2 * f), g * g * (3 - 2 * g)
    a = h01(seed, i, j) * (1 - f) + h01(seed, i + 1, j) * f
    b = h01(seed, i, j + 1) * (1 - f) + h01(seed, i + 1, j + 1) * f
    return a * (1 - g) + b * g


def regrade(img, tops):
    """The wall in granite with snow (fix stage). The painting gives three kinds of pixel (shade, lit, snow); the
    colour comes from the kind, the massif's side and the snow line. Above the snow line a massif's lit side is one
    snow cap (mistLight, the painting's shaded facets as folds of moon), its summit as painted (snow and shaded snow
    of far, dark rock in patches), its shade flank dark rock with shaded snow. Below the line the wall is the granite
    ramp: the lit side rock and rockLight with rockDark shade, the shade flank rockDark with rockDeep shade; snow
    only in the gullies, for GULLY_REACH rows."""
    lvl = {col(n): i for i, n in enumerate(FARW)}
    c = {n: col(n) for n in ("rockDeep", "rockDark", "rock", "rockLight", "rockPale", "far", "moon", "mist", "farPale",
                             "mistLight", "foam", "farDeep")}
    kind = [[None] * img.w for _ in range(img.h)]   # 0 shade, 1 lit, 2 snow in the painting
    for y in range(img.h):
        for x in range(img.w):
            p = img.get(x, y)
            if p[3]:
                i = lvl[p]
                kind[y][x] = 0 if i <= 1 else 1 if i <= 4 else 2
    out = PA.Image(img.w, img.h)

    def k(x, y):
        return kind[y][x] if 0 <= x < img.w and 0 <= y < img.h else None

    for x in range(img.w):
        sl = snow_row(x)
        for y in range(img.h):
            q = kind[y][x]
            if q is None:
                continue
            side = massif_side(x, y)
            patch = vnoise2(59, (x + y * 0.35) / 7.0, y / 19.0)
            arete = q != 0 and (k(x + 1, y) == 0 or k(x + 2, y) == 0)       # a lit face's edge to the shade right of it
            core = q == 0 and (k(x - 1, y) not in (0, None) or k(x - 2, y) not in (0, None))  # the shade right under an edge
            if y < sl:                                   # the snow cap
                if side < 0:
                    v = "mistLight" if q == 2 else "farPale" if q == 1 else ("moon" if core or patch < 0.62 else "mist")
                    if q == 2 and arete:
                        v = "foam" if h01(43, x, y // 2) < 0.0 else "mistLight"
                elif side == 0:
                    v = "mistLight" if q == 2 else "mist" if q == 1 else ("rockDark" if patch > 0.6 and not core else "far")
                    if q == 2 and patch < 0.22:
                        v = "farPale"
                else:
                    v = ("farPale" if patch < 0.6 else "mist") if q == 2 else "moon" if q == 1 else \
                        ("far" if patch > 0.56 else "rockDeep")
            else:                                        # the rock
                b = y - sl
                if q == 2:
                    v = "farPale" if b < GULLY_REACH else "rockLight"
                elif q == 1:
                    crack = h01(67, x, y // 7) < 0.05
                    if side < 0:
                        v = "rockLight" if arete or patch > 0.7 else "rockDark" if crack else "rock"
                    elif side == 0:
                        v = "rockLight" if arete else "rockDark" if crack or patch < 0.18 else "rock"
                    else:
                        v = "rock" if arete else "rockDark"
                    if b < 5 and h01(73, x // 2, y) < 0.45 - 0.08 * b:   # the snow's ragged hem
                        v = "mist"
                else:
                    if side < 0:
                        v = "rockDeep" if core else "rockDark"
                    elif side == 0:
                        v = "rockDark" if patch > 0.66 and not core else "rockDeep"
                    else:
                        v = "rockDeep"
                    if b < 4 and h01(83, x // 2, y) < 0.3:
                        v = "far"
            out.set(x, y, c[v])
    for hx, hy in COULOIRS:                               # snow couloirs below the saddles and notches
        x = float(hx)
        y0 = max(hy, tops[hx] + 1)
        ln = 34 + int(30 * h01(89, hx))
        for i in range(ln):
            y = y0 + i
            x += (h01(97, hx, i // 3) - 0.5) * 1.2
            wd = max(1.0, 3.0 - 2.4 * i / ln)
            for j in range(int(round(wd))):
                xx = int(x) + j
                if 0 <= xx < img.w and out.get(xx, y)[3] and y > tops[xx] + 1:
                    out.set(xx, y, c["mistLight" if j == 0 and i < ln * 0.6 else "farPale"])
    return out


SLOT_HALF, SLOT_TOP = 20, 13   # the cleft's half width at the castle (as wide as the castle) and toward the ridge
SLOT_LIGHT = (("foam", 5), ("mistLight", 11), ("farPale", 10), ("mist", 9))   # the levels from the castle's top upward


def cut_cleft(img, cx, mini, seed, flip, tops):
    """The cleft at column cx: a sheer slot from the ridge down to the far castle's foot, as wide as the castle at its
    mouth and narrower by jogs above it, its right inner face lit and its left one dark. The far castle stands in its
    mouth as a dark silhouette. Behind it the slot is filled with the cleft's light in flat levels (foam behind the
    castle, then mistLight, farPale and mist, the last rows broken), above that it is open to the sky: the slot is the
    lightest part of the wall at every hour (fix stage). Returns the castle's top row and the light as a sprite of its
    own (the slot's emissive strip for the night)."""
    foot = img.h - CASTLE_FOOT          # first row below the castle
    top = foot - mini.h                 # the castle's top row
    ch = mini.h - min(y for y in range(mini.h) for x in range(mini.w) if mini.get(x, y)[3])  # the castle's height
    levels = [("foam", ch + SLOT_LIGHT[0][1])] + list(SLOT_LIGHT[1:])
    hl = hr = SLOT_HALF
    gw = 2 * SLOT_HALF + 4
    glow = PA.Image(gw, sum(n for _, n in levels))
    for y in range(foot - 1, -1, -1):   # upward
        up = foot - y
        if up > ch - 8 and up % 7 == 0:  # above the towers a jog every 7 rows, each side by its own hash
            hl = max(SLOT_TOP, hl - (1 if h01(seed, up, 5) < 0.5 else 2))
            hr = max(SLOT_TOP + 1, hr - (2 if h01(seed, up, 6) < 0.5 else 1))
        for x in range(cx - hl, cx + hr):
            ue = up + int(3 * h01(seed, x // 3, 17))   # the levels' limits a little ragged
            acc, name = 0, None
            for nm, n in levels:
                acc += n
                if ue <= acc:
                    name = nm
                    break
            thin = (ue - (acc - levels[-1][1])) / float(levels[-1][1])   # the last level thins out into the sky
            if name and not (name == "mist" and h01(seed, x, y, 13) < thin):
                img.set(x, y, col(name))
                glow.set(x - (cx - gw // 2), glow.h - up, col(name))
            else:
                img.set(x, y, CLEAR)
        snow = y < snow_row(cx)
        for i in range(3):              # the inner faces, only where the wall stands
            xl, xr = cx - hl - 1 - i, cx + hr + i
            if img.get(xl, y)[3] and y > tops[xl]:
                img.set(xl, y, col("rockDeep"))
            if i < 2 and img.get(xr, y)[3] and y > tops[xr]:
                lit = ("mistLight", "farPale") if snow else ("rockPale", "rockLight")
                img.set(xr, y, col(lit[0] if i == 0 and h01(seed, y // 5, 7) < 0.6 else lit[1]))
    ox = cx - mini.w // 2
    blit(img, mini, ox, top, flip)
    for y in range(mini.h):             # the castle hides the light behind it
        for x in range(mini.w):
            if mini.get(mini.w - 1 - x if flip else x, y)[3]:
                gx, gy = ox + x - (cx - gw // 2), glow.h - (foot - (top + y))
                if 0 <= gx < glow.w and 0 <= gy < glow.h:
                    glow.set(gx, gy, CLEAR)
    for y in range(foot, foot + 2):     # the castle's foot on the rock
        for x in range(cx - mini.w // 2 - 2, cx + mini.w // 2 + 2):
            img.set(x, y, col("rockDeep"))
    return top, glow


WALL_MORE, WALL_SINK, WALL_DROP = 150, 212, 104
PATCH_W = 52


def cmd_wall(a):
    wa, wb, front, keep, gate, out = load(a[0]), load(a[1]), load(a[2]), load(a[3]), load(a[4]), a[5]
    w = 318 + wb.w + WALL_MORE
    img = PA.Image(w, WALL_H)
    blit(img, wb, 318, WALL_H - wb.h, flip=True)
    blit(img, wb, 318 + wb.w, WALL_H - wb.h, box=(0, 0, WALL_MORE, wb.h))  # the mirrored wall runs on
    blit(img, wa, 0, WALL_H - wa.h, box=(0, 0, 330, wa.h))
    for x in range(w - WALL_SINK, w):  # the wall's shoulder toward the valley: each column sinks, the ridge keeps its teeth
        t = (x - (w - WALL_SINK)) / float(WALL_SINK - 1)
        d = int(round(WALL_DROP * t * t * (3 - 2 * t)))
        for y in range(WALL_H - 1, -1, -1):
            img.set(x, y, img.get(x, y - d) if y - d >= 0 else CLEAR)
    img, tops = reprofile(img)
    img = regrade(img, tops)
    c1, c2 = CLEFTS
    patch = PA.Image(PATCH_W, WALL_H)
    blit(patch, img, 0, 0, box=(c2 - PATCH_W // 2, 0, c2 + PATCH_W // 2, WALL_H))
    b1, p1 = far_castle(front, keep, 0, KEEP_FAR[0])
    b2, p2 = far_castle(gate, keep, 20, KEEP_FAR[1])
    m1, m2 = mini_castle(b1), mini_castle(b2)
    t1, g1 = cut_cleft(img, c1, m1, 11, False, tops)
    t2, g2 = cut_cleft(img, c2, m2, 29, True, tops)
    PA.write_png(os.path.join(out, "weltmauer.png"), img)
    PA.write_png(os.path.join(out, "weltmauerPatch.png"), patch)
    PA.write_png(os.path.join(out, "farCastleGlow.png"), glow_strip(m1, FRONT_LIGHTS + [p1]))
    PA.write_png(os.path.join(out, "farCastlePane.png"), glow_strip(m2, [p2], True))
    PA.write_png(os.path.join(out, "farCleftGlow.png"), g1)
    PA.write_png(os.path.join(out, "farCleftGlowBack.png"), g2)
    print(f"wrote weltmauer {w}x{WALL_H}: clefts at x {c1} and {c2}, castles {m1.w}x{m1.h} from row {t1} / {t2}; "
          f"patch {PATCH_W}x{WALL_H} at x {c2 - PATCH_W // 2}; farCastleGlow {m1.w}x{m1.h}, farCastlePane {m2.w}x{m2.h}; "
          f"farCleftGlow {g1.w}x{g1.h}, farCleftGlowBack {g2.w}x{g2.h}")


# ------------------------------------------------------------------------------------------------ rock walls
def profile_cut(img, steps, seed, lit_left=True, slope=False):
    """Cuts the top of img to a stepped height profile: steps = [(x0, height), ...] from left to right (each height
    holds until the next x0). Tops jitter by a pixel or two; every top edge is lit (rockPale over rockLight); a riser
    facing the light takes a rockLight edge, one facing away a rockDeep edge. With slope the height runs from
    each point to the next (steep faces and flatter ledges by the points' spacing) instead of holding."""
    hts = []
    for x in range(img.w):
        k = max(i for i, (x0, h) in enumerate(steps) if x0 <= x)
        hh = steps[k][1]
        if slope and k + 1 < len(steps):  # a crag: the height runs on to the next point, in 3 px blocks
            x0, x1 = steps[k][0], steps[k + 1][0]
            xb = min(x1, (x // 3) * 3 + 1)
            hh = int(round(hh + (steps[k + 1][1] - hh) * (xb - x0) / float(x1 - x0)))
        if hh < img.h:
            hh += int(h01(seed, x // 5) * 5) - 2 + (1 if h01(seed, x // 2, 3) < 0.3 else 0)
        hts.append(max(0, min(img.h, hh)))
    for x in range(img.w):
        topy = img.h - hts[x]
        for y in range(0, topy):
            img.set(x, y, CLEAR)
        if hts[x] < img.h:
            for i, name in enumerate(("rockPale", "rockLight")):
                if topy + i < img.h:
                    img.set(x, topy + i, col(name))
    for x in range(1, img.w):  # the risers
        a, b = hts[x - 1], hts[x]
        if abs(a - b) < 6:
            continue
        rising = b > a
        xs = (x, x + 1) if rising else (x - 1, x - 2)
        name = "rockLight" if rising == lit_left else "rockDeep"
        for y in range(img.h - max(a, b) + 2, img.h - min(a, b)):
            for xx in xs:
                if 0 <= xx < img.w and img.get(xx, y)[3]:
                    img.set(xx, y, col(name))
    return hts


GRANITE = ("rockDeep", "rockDark", "rock", "rockLight", "rockPale")
# The gorge's mouth (fix stage, ART-look2.md 14), in two depths. GORGE_BACK is the face's own left edge on the mid
# plane (sprite x, height above the sprite's bottom; the height runs from point to point). GORGE_CRAGS are the five
# crags of gorgeCrags, a sprite of its own on the near plane, cut by hand: (x0, x1, lean in px per 100 rows, top
# points, bite). A bite (from row, to row, depth) cuts a wedge into the crag's left side under a ledge: an overhang.
GORGE_BACK = [(0, 0), (12, 0), (14, 34), (24, 46), (27, 40), (33, 92), (46, 108), (49, 100), (55, 148), (70, 160),
              (74, 196), (90, 204), (94, 211), (394, 211), (402, 184), (414, 176), (424, 150), (437, 140), (447, 128)]
CRAGS_W, CRAGS_H = 160, 200
GORGE_CRAGS = [
    (6, 19, 20, [(6, 50), (10, 60), (15, 57), (19, 40)], None),                                  # a leaning pillar
    (22, 54, 0, [(22, 64), (28, 86), (34, 90), (37, 68), (41, 72), (44, 98), (54, 92)], None),   # a notch, two prongs
    (48, 88, -6, [(48, 110), (51, 130), (58, 139), (71, 136), (74, 121), (88, 116)], (70, 108, 10)),  # an overhang
    (80, 124, 0, [(80, 150), (86, 176), (96, 184), (104, 170), (112, 178), (124, 160)], None),   # the tall one
    (116, 157, 0, [(116, 150), (126, 146), (130, 112), (140, 104), (143, 60), (150, 52), (153, 20), (156, 0)], None),
]
GORGE_JOINTS = (131, 171, 214, 268, 301, 352, 407)   # straight joints through the face (sprite x)


def _run(points, x):  # the height at x of a line through points
    x = max(x, points[0][0])
    k = max(i for i, (x0, h) in enumerate(points) if x0 <= x)
    if k + 1 == len(points):
        return points[k][1]
    (x0, h0), (x1, h1) = points[k], points[k + 1]
    return h0 + (h1 - h0) * (x - x0) / float(x1 - x0)


def _jit(seed, x):
    return int(h01(seed, x // 4) * 5) - 2 + (1 if h01(seed, x // 2, 3) < 0.3 else 0)


def cmd_gorge(a):
    """The gorge's wall on the monster side, readable in the dark: granite only, a dark body, the slabs' upper and
    left edges lit (the moon stands upper left), straight dark joints. Two depths at the mouth: the face (gorgeRock,
    mid plane) with a broken left edge, and five dark crags before it (gorgeCrags, near plane), so the mist of the
    plane between lies between them."""
    src = load(a[0])
    w, h = src.w, src.h
    ramp = [col(n) for n in GRANITE]
    lvl = {c: i for i, c in enumerate(ramp)}
    tex = [[lvl[src.get(x, y)] for x in range(w)] for y in range(h)]
    back = []
    for x in range(w):
        hh = _run(GORGE_BACK, (x // 3) * 3)
        back.append(int(round(hh)) + (_jit(5, x) if 0 < hh < h else 0))

    def bk(x, y):
        return 0 <= x < w and 0 <= y < h and h - 1 - y < back[x]

    img = PA.Image(w, h)
    for y in range(h):
        for x in range(w):
            if not bk(x, y):
                continue
            t = tex[y][x]
            i = (0, 0, 1, 1, 2)[t]                              # the body: a step down, so the lit edges carry it
            if not bk(x, y - 1):
                i = 4
            elif not bk(x, y - 2) or not bk(x - 1, y):
                i = 3
            elif not bk(x + 1, y) or not bk(x + 2, y):
                i = 0
            elif t >= 2 and y >= 2 and tex[y - 1][x] <= 1 and tex[y - 2][x] == 0:
                i = 4 if h01(7, x // 3, y // 2) < 0.3 else 3    # a slab's top under a dark crack
            elif t >= 2 and x >= 2 and tex[y][x - 1] <= 1 and tex[y][x - 2] == 0:
                i = 3                                           # a slab's left edge beside a dark joint
            img.set(x, y, ramp[i])
    for jx in GORGE_JOINTS:  # straight joints, each jogging where a slab ends: two dark columns, the slab right of
        for y in range(h):   # them lit on its edge
            x = jx + int(h01(11, jx, y // 41) * 5) - 2
            if bk(x, y - 3) and bk(x + 3, y) and bk(x - 2, y) and h01(13, jx, y // 19) < 0.8:
                img.set(x, y, ramp[0])
                img.set(x + 1, y, ramp[0])
                if h01(17, jx, y // 7) < 0.45:
                    img.set(x + 2, y, ramp[3])
    PA.write_png(a[1], img)
    print(f"wrote {a[1]} {w}x{h}")

    cw, ch = CRAGS_W, CRAGS_H
    front = [[0] * cw for _ in range(ch)]     # the crag's number, 0 for none; the lower crag stands before the higher
    for k, (x0, x1, lean, pts, bite) in reversed(list(enumerate(GORGE_CRAGS, 1))):
        for y in range(ch):
            up = ch - 1 - y
            for x in range(cw):
                xs = x - lean * up / 100.0
                if not x0 <= xs < x1:
                    continue
                top = _run(pts, int(xs) // 2 * 2)
                if up >= top + (_jit(40 + k, x) if top > 8 else 0):
                    continue
                if bite and bite[0] <= up < bite[1] and xs < x0 + bite[2] * (bite[1] - up) / float(bite[1] - bite[0]):
                    continue
                front[y][x] = k

    def fr(x, y):
        return front[y][x] if 0 <= x < cw and 0 <= y < ch else 0

    def free(k, n):  # the neighbour n leaves crag k's edge free: air, or a crag behind
        return n != k and (n == 0 or n > k)

    crags = PA.Image(cw, ch)
    for y in range(ch):
        for x in range(cw):
            k = front[y][x]
            if not k:
                continue
            t = tex[y + 8][(x + 236 + 37 * k) % w]              # each crag its own piece of the painting
            i = (0, 0, 1, 1, 2)[t]
            if free(k, fr(x, y - 1)) or (free(k, fr(x, y - 2)) and h01(23, x // 2, k) < 0.6):
                i = 4
            elif free(k, fr(x, y - 2)) or free(k, fr(x, y - 3)) or free(k, fr(x - 1, y)):
                i = 3
            elif free(k, fr(x + 1, y)) or free(k, fr(x + 2, y)) or free(k, fr(x + 3, y)):
                i = 0
            elif free(k, fr(x - 2, y)) or (free(k, fr(x - 3, y)) and h01(19, x, y // 3) < 0.6):
                i = 2 if t <= 1 else 3
            elif t >= 2 and tex[y + 7][(x + 236 + 37 * k) % w] <= 1 and tex[y + 6][(x + 236 + 37 * k) % w] == 0:
                i = 3 if h01(7, x // 3, y // 2) < 0.7 else 2    # a ledge under a crack
            crags.set(x, y, ramp[i])
    PA.write_png(a[2], crags)
    print(f"wrote {a[2]} {cw}x{ch}")


def light_top(img):
    for x in range(img.w):
        for y in range(img.h):
            if img.get(x, y)[3]:
                img.set(x, y, col("rockPale"))
                if y + 1 < img.h and img.get(x, y + 1)[3]:
                    img.set(x, y + 1, col("rockLight"))
                break


def cmd_face(a):
    src = load(a[0])
    face = PA.Image(src.w, src.h, list(src.px))
    light_top(face)
    PA.write_png(a[1], face)
    end = PA.Image(240, src.h)
    blit(end, src, 0, 0, box=(60, 0, 300, src.h))
    light_top(end)
    h = src.h
    profile_cut(end, [(0, h), (96, h), (112, h - 26), (134, h - 38), (152, h - 70), (176, h - 82), (196, h - 108),
                      (218, h - 118), (239, h - 128)], 9, slope=True)
    PA.write_png(a[2], end)
    print(f"wrote {a[1]} {face.w}x{face.h}, {a[2]} {end.w}x{end.h}")


def cmd_slope(a):
    img = load(a[0])
    span = 150  # the left end rises from the ground to the full height over this many columns
    for x in range(span):
        t = x / span
        keep = int(img.h * (0.10 + 0.90 * (t * t * (3 - 2 * t)))) + int(h01(3, x // 3) * 4)
        for y in range(0, max(0, img.h - keep)):
            img.set(x, y, CLEAR)
    PA.write_png(a[1], img)
    print(f"wrote {a[1]} {img.w}x{img.h}")


def cmd_taper(a):
    """The forest's left end: the tree line sinks to the ground over `span` columns in fir-shaped teeth."""
    img, span = load(a[0]), int(a[2])
    for x in range(span):
        t = x / float(span)
        tooth = 1.0 - abs(((x + 3) % 11) - 5) / 5.0          # a fir tip every 11 px
        keep = int(img.h * (0.10 + 0.72 * t * t) + 16 * tooth * (0.3 + 0.7 * t)) + 4
        for y in range(0, max(0, img.h - keep)):
            img.set(x, y, CLEAR)
    PA.write_png(a[1], img)
    print(f"wrote {a[1]} {img.w}x{img.h}")


def cmd_main(a):
    img = load(a[0])
    seen = [False] * (img.w * img.h)
    best = []
    for y0 in range(img.h):
        for x0 in range(img.w):
            if seen[y0 * img.w + x0] or not img.get(x0, y0)[3]:
                continue
            seen[y0 * img.w + x0] = True
            part, stack = [], [(x0, y0)]
            while stack:
                x, y = stack.pop()
                part.append((x, y))
                for dx in (-1, 0, 1):
                    for dy in (-1, 0, 1):
                        nx, ny = x + dx, y + dy
                        if 0 <= nx < img.w and 0 <= ny < img.h and not seen[ny * img.w + nx] and img.get(nx, ny)[3]:
                            seen[ny * img.w + nx] = True
                            stack.append((nx, ny))
            if len(part) > len(best):
                best = part
    out = PA.Image(img.w, img.h)
    for x, y in best:
        out.set(x, y, img.get(x, y))
    PA.write_png(a[1], out)
    print(f"wrote {a[1]} {out.w}x{out.h}: kept {len(best)} px")


def cmd_retex(a):
    shape, rock = load(a[0]), load(a[1])
    out = PA.Image(shape.w, shape.h)

    def solid(x, y):
        return 0 <= x < shape.w and 0 <= y < shape.h and shape.get(x, y)[3] > 0

    def deep(x, y):
        return rock.get(min(max(x, 0), rock.w - 1), min(max(y, 0), rock.h - 1))[:3] == col("rockDeep")[:3]

    for y in range(shape.h):
        for x in range(shape.w):
            if not solid(x, y):
                continue
            p = rock.get(min(x, rock.w - 1), min(y, rock.h - 1))
            if not p[3]:
                p = col("rockDark")
            elif deep(x, y) and all(deep(x + i, y + j) for i in (-1, 0, 1) for j in (-1, 0, 1)):
                p = col("rockDark")  # the inside of a shadowed slab one step up: only cracks and slab edges stay rockDeep
            if y > 0 and not solid(x, y - 1):
                p = col("rockPale")
            elif y > 1 and not solid(x, y - 2):
                p = col("rockLight")
            elif x > 0 and not solid(x - 1, y):
                p = col("rockLight") if h01(17, y // 4) < 0.7 else col("rock")
            elif x < shape.w - 1 and not solid(x + 1, y):
                p = col("rockDeep")
            out.set(x, y, p)
    PA.write_png(a[2], out)
    print(f"wrote {a[2]} {out.w}x{out.h}")


if __name__ == "__main__":
    cmds = dict(wall=cmd_wall, gorge=cmd_gorge, face=cmd_face, slope=cmd_slope, main=cmd_main, retex=cmd_retex, taper=cmd_taper)
    if len(sys.argv) < 2 or sys.argv[1] not in cmds:
        raise SystemExit(__doc__)
    cmds[sys.argv[1]](sys.argv[2:])
