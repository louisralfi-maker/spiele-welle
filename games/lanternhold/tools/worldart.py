#!/usr/bin/env python3
"""Lanternhold look 2, stage 2: assembles the world sprites from converted paintings (ART-look2.md, "Stage 2: the
world art"). Pure python on pixelart.py's Image; every colour is a palette colour; no randomness (hashes of the
position), so a run reproduces its files byte for byte. Called by tools/build-art-world.sh.

  wall <wallA> <wallB> <castleFront> <keepTop> <castleBackGate> <out dir>
      weltmauer.png      the Weltmauer on the far plane: wallA and the mirrored wallB side by side, the cleft cut
                         through it twice (the view from the shadow land, the view from the valley), in each the far
                         castle made from the real castle sprites at 1/8
      weltmauerPatch.png the piece of unbroken wall that covers the valley's view of the cleft until the town
      farCastleGlow.png  the lit windows of the far castle seen from the shadow land (a glow strip)
      farCastlePane.png  the one lit pane of the keep seen from the town (a glow strip)
  gorge <rock> <out>     the gorge's wall: steps down to the ground at its left end (the mouth) and down to the cleft
                         face's height at its right end, lit top edges
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
def mini_castle(big, k=8):
    """big: the castle at game scale on a clear ground. Returns the castle at 1/k in the far ramp (farDeep shade and
    openings, mistDark walls, moon lit faces: a step paler than the rock around it)."""
    w, h = big.w // k, big.h // k
    out = PA.Image(w, h)
    cells = []
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
                cells.append((s / n, bx, by))
    ls = sorted(c[0] for c in cells)
    t1, t2 = ls[int(len(ls) * 0.30)], ls[int(len(ls) * 0.78)]
    for L, bx, by in cells:
        out.set(bx, by, col("farDeep" if L < t1 else "mistDark" if L < t2 else "moon"))
    return out


def castle_front(front, keep):  # the front at F with the keep behind it (K - F = 46, the keep's foot 40 px up)
    big = PA.Image(240, 240)
    blit(big, keep, 46, 240 - 40 - keep.h)
    blit(big, front, 0, 240 - front.h)
    return big


def castle_back(gate, keep):  # the back gate with the keep rising behind it (the view from the valley)
    big = PA.Image(240, 280)
    blit(big, keep, 45, 280 - 110 - keep.h)
    blit(big, gate, 20, 280 - gate.h)
    return big


# The far castles' lights, in blocks of the 1/8 castle (x from its left, y from its top; the real sprites' emitters
# in layout_m1b.py divided by 8): the front's two tower slits and the right tower's lower slit, the two watch fires on
# the wall walk; from the valley the one pane high in the keep.
FRONT_LIGHTS = [(4, 17), (25, 18), (25, 20), (12, 13), (17, 13)]
BACK_LIGHTS = [(15, 9)]


def glow_strip(mini, cells):
    out = PA.Image(mini.w, mini.h)
    for bx, by in cells:
        if not mini.get(bx, by)[3]:
            raise SystemExit(f"light {bx},{by} lies off the far castle")
        out.set(bx, by, col("fireGold"))
    return out


# ------------------------------------------------------------------------------------------------ the Weltmauer
WALL_H = 190
CASTLE_FOOT = 92   # rows from the sprite's bottom to the far castle's foot (75 px above the ground at y -17)


def cut_cleft(img, cx, mini, seed, flip):
    """The cleft at column cx: a sheer slit open to the sky from the ridge down to the far castle's foot, about 14 px
    wide with small jogs, its right inner face lit and its left one dark. The far castle stands across its mouth, the
    towers before the rock on both sides (as the real front stands between the flanks), the rock around it in shade."""
    foot = img.h - CASTLE_FOOT          # first row below the castle
    top = foot - mini.h                 # the castle's top row
    ch = mini.h - min(y for y in range(mini.h) for x in range(mini.w) if mini.get(x, y)[3])  # the castle's height
    hl = hr = 7
    dark, lit = col("farDeep"), (col("moon"), col("farPale"))
    for y in range(foot - 1, -1, -1):   # upward
        up = foot - y
        if up > ch and up % 17 == 0:  # a jog every 17 rows, on one side by the hash, 11 to 16 px wide
            d = 1 if h01(seed, up, 5) < 0.5 else -1
            if h01(seed, up) < 0.5:
                hl = max(5, min(8, hl + d))
            else:
                hr = max(6, min(8, hr + d))
        if up <= ch + 3:                # the mouth around the castle lies in shade
            for x in range(cx - 18, cx + 18):
                if img.get(x, y)[3] and h01(seed, x // 2, y // 3, 9) < 0.85:
                    img.set(x, y, dark)
        for x in range(cx - hl, cx + hr):
            img.set(x, y, CLEAR)
        for i in range(3):              # the inner faces, only where the wall stands
            xl, xr = cx - hl - 1 - i, cx + hr + i
            if img.get(xl, y)[3]:
                img.set(xl, y, dark)
            if i < 2 and img.get(xr, y)[3]:
                img.set(xr, y, lit[1] if i == 0 and h01(seed, y // 5, 7) < 0.6 else lit[0])
    blit(img, mini, cx - mini.w // 2, top, flip)
    for y in range(foot, foot + 2):     # the castle's foot on the rock
        for x in range(cx - 16, cx + 16):
            img.set(x, y, dark)
    return top


WALL_MORE, WALL_SINK, WALL_DROP = 150, 212, 104


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
    c1, c2 = 324, 650
    patch = PA.Image(38, WALL_H)
    blit(patch, img, 0, 0, box=(c2 - 19, 0, c2 + 19, WALL_H))
    m1 = mini_castle(castle_front(front, keep))
    m2 = mini_castle(castle_back(gate, keep))
    t1 = cut_cleft(img, c1, m1, 11, False)
    t2 = cut_cleft(img, c2, m2, 29, True)
    PA.write_png(os.path.join(out, "weltmauer.png"), img)
    PA.write_png(os.path.join(out, "weltmauerPatch.png"), patch)
    PA.write_png(os.path.join(out, "farCastleGlow.png"), glow_strip(m1, FRONT_LIGHTS))
    PA.write_png(os.path.join(out, "farCastlePane.png"), glow_strip(m2, BACK_LIGHTS))
    print(f"wrote weltmauer {w}x{WALL_H}: clefts at x {c1} and {c2}, castles {m1.w}x{m1.h} from row {t1} / {t2}; "
          f"patch 38x{WALL_H} at x {c2 - 19}; farCastleGlow {m1.w}x{m1.h}, farCastlePane {m2.w}x{m2.h}")


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


def cmd_gorge(a):
    img = load(a[0])
    full = img.h
    steps = [(0, 8), (10, 30), (22, 40), (34, 84), (50, 96), (60, 140), (78, 154), (90, 196), (104, full), (394, full),
             (402, 184), (414, 176), (424, 150), (437, 140), (447, 128)]
    profile_cut(img, steps, 5, slope=True)
    PA.write_png(a[1], img)
    print(f"wrote {a[1]} {img.w}x{img.h}")


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

    for y in range(shape.h):
        for x in range(shape.w):
            if not solid(x, y):
                continue
            p = rock.get(min(x, rock.w - 1), min(y, rock.h - 1))
            if not p[3]:
                p = col("rockDark")
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
