#!/usr/bin/env python3
"""Lanternhold's cast (the people lane, docs/PEOPLE.md): proof sheets of the people standing on the town's ground.
Pure python 3 (pixelart.py's PNG helpers), one sheet per run, small and quick; run it through the art lock.

  peoplesheet.py lineup <out.png> --items "king:6 guardsman:0 citizen:4 …" [--light day|dusk] [--scale 6] [--gap 5]
        The figures side by side, feet on the ground line, on the valley's earth lane before the town's houses, in
        day light or at dusk (an approximation of the renderer's light: albedo times the hour's ambient, the dusk with
        a warm lantern pool around the lord). Each item is `id:frame` (a leading `-` mirrors it; `_:N` is a gap of N game
        px between groups); the frame size comes from the tables of SPRITES.md and docs/SPRITES-people.md.
  peoplesheet.py strip <out.png> <id> --frames 0-3 [--scale 6] [--step 4] [--loops 2]
        One walk (or any run of frames) as a film strip: on top the frames in a row; under them the feet alone (the
        last four body rows), each frame advanced by --step game px like the engine's walk (one frame per stride) and
        tinted in turn, so a planted foot that slides shows as a smear instead of one print.
  peoplesheet.py zoom <out.png> <id> [--scale 8]
        Every frame of one sprite at 800 % on a checker, for the 400 % check.
"""
import argparse
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from pixelart import Image, read_png, write_png  # noqa: E402

GAME = os.path.dirname(HERE)
ART = os.path.join(GAME, "Resources", "Art")
COURT = ("odile", "brannock", "pip", "hesper", "tamsin", "bram", "marek", "seren", "serLudo", "bard", "envoy",
         "herald", "hildVarn", "lorenzPell", "ebbaCalder", "orlaLorn")


def contract():
    """id -> (w, h, frames) from the tables of SPRITES.md and docs/SPRITES-people.md (the people tables win)."""
    out = {}
    for path in (os.path.join(GAME, "SPRITES.md"), os.path.join(GAME, "docs", "SPRITES-people.md")):
        if not os.path.exists(path):
            continue
        for line in open(path).read().splitlines():
            cells = [c.strip() for c in line.strip().strip("|").split("|")]
            if len(cells) < 3 or "`" not in cells[0]:
                continue
            ids = re.findall(r"`(\w+)`", cells[0])
            sizes = re.findall(r"(\d+)x(\d+)", cells[1])
            n = re.match(r"(\d+)", cells[2])
            if not ids or not sizes or not n:
                continue
            for k, i in enumerate(ids):
                w, h = sizes[k] if len(sizes) == len(ids) else sizes[0]
                out[i] = (int(w), int(h), int(n.group(1)))
    for i in COURT:  # the court's table has no frames column: 8 frames each
        if os.path.exists(os.path.join(ART, i + ".png")):
            img, _ = read_png(os.path.join(ART, i + ".png"))
            out[i] = (img.w // 8, img.h, 8)
    for i in ("petitionerD", "petitionerE"):
        out[i] = (12, 26, 6)
    return out


def frame_of(con, sid, k):
    w, h, n = con[sid]
    img, _ = read_png(os.path.join(ART, sid + ".png"))
    k = k % n
    return [[img.get(k * w + x, y) for x in range(w)] for y in range(h)]


def lit(c, light, x=0, lamp=None):
    r, g, b = (v / 255 for v in c[:3])
    if light == "day":
        return (r * 0.98, g * 0.97, b * 0.93)
    # dusk: the sunset's ambient, a little desaturated, plus a warm lantern pool around the lord
    amb = (0.60, 0.50, 0.58)
    lu = 0.299 * r + 0.587 * g + 0.114 * b
    r, g, b = (r + (lu - r) * 0.25, g + (lu - g) * 0.25, b + (lu - b) * 0.25)
    out = [r * amb[0], g * amb[1], b * amb[2]]
    if lamp is not None:
        d = abs(x - lamp) / 70.0
        f = max(0.0, 1 - d) ** 2 * 0.6
        out = [out[0] + r * f * 1.0, out[1] + g * f * 0.62, out[2] + b * f * 0.25]
    return tuple(out)


def to8(c):
    return tuple(min(255, max(0, int(v * 255 + 0.5))) for v in c) + (255,)


def backdrop(W, H, ground_y, light, lamp):
    """Sky, the town's houses (bottoms on the ground line, set back in the air so the figures read) and the earth
    lane under it."""
    can = [[None] * W for _ in range(H)]
    top, bot = ((0.52, 0.62, 0.70), (0.80, 0.80, 0.76)) if light == "day" else ((0.20, 0.20, 0.38), (0.70, 0.44, 0.36))
    for y in range(H):
        t = min(1.0, y / max(1, ground_y))
        c = tuple(top[i] + (bot[i] - top[i]) * t for i in range(3))
        for x in range(W):
            can[y][x] = c
    houses = ["houseB", "house", "houseC"]
    air = (0.70, 0.74, 0.78) if light == "day" else (0.36, 0.34, 0.50)
    x, k = -10, 0
    while x < W:
        img, _ = read_png(os.path.join(ART, houses[k % len(houses)] + ".png"))
        for yy in range(img.h):
            for xx in range(img.w):
                p = img.get(xx, yy)
                X, Y = x + xx, ground_y - img.h + yy
                if p[3] and 0 <= X < W and 0 <= Y < H:
                    c = lit(p, light, X, lamp)
                    can[Y][X] = tuple(c[i] + (air[i] - c[i]) * 0.42 for i in range(3))
        x += img.w + 14
        k += 1
    lanes = [read_png(os.path.join(ART, n + ".png"))[0] for n in ("laneEarthA", "laneEarthC", "laneEarthB")]
    for y in range(ground_y, H):
        for x in range(W):
            src = lanes[(x // 64) % 3]
            p = src.get(x % src.w, min(src.h - 1, y - ground_y))
            if p[3]:
                can[y][x] = lit(p, light, x, lamp)
    return can


def paste(canvas, fr, x0, ground_y, light, lamp):
    h, w = len(fr), len(fr[0])
    for y in range(h):
        for x in range(w):
            p = fr[y][x]
            if p[3]:
                X, Y = x0 + x, ground_y - h + y
                if 0 <= X < len(canvas[0]) and 0 <= Y < len(canvas):
                    canvas[Y][X] = lit(p, light, X, lamp)


def scaled(canvas, s):
    H, W = len(canvas), len(canvas[0])
    img = Image(W * s, H * s)
    px = []
    for y in range(H):
        line = []
        for x in range(W):
            line.extend([to8(canvas[y][x])] * s)
        for _ in range(s):
            px.extend(line)
    img.px = px
    return img


def cmd_lineup(a):
    con = contract()
    items = []
    for it in a.items.split():
        sid, _, k = it.partition(":")
        flip = sid.startswith("-")
        sid = sid.lstrip("-")
        if sid == "_":  # a spacer of k game px between groups
            items.append((sid, int(k or 4), False))
            continue
        if sid not in con:
            raise SystemExit(f"unknown sprite {sid} (not in SPRITES.md or docs/SPRITES-people.md)")
        items.append((sid, int(k or 0), flip))
    widths = [k if s == "_" else con[s][0] for s, k, _ in items]
    W = sum(widths) + a.gap * (len(items) + 1)
    ground_y = 52
    H = ground_y + 12
    lamp, xs, x = None, [], a.gap
    for (sid, k, flip), w in zip(items, widths):
        xs.append(x)
        if sid in ("king", "lady") and lamp is None:
            lamp = x + w * 0.8
        x += w + a.gap
    lamp = lamp if a.light == "dusk" else None
    canvas = backdrop(W, H, ground_y, a.light, lamp)
    for (sid, k, flip), x0 in zip(items, xs):
        if sid == "_":
            continue
        fr = frame_of(con, sid, k)
        if flip:
            fr = [list(reversed(r)) for r in fr]
        paste(canvas, fr, x0, ground_y, a.light, lamp)
    write_png(a.output, scaled(canvas, a.scale))
    print(f"wrote {a.output} {W * a.scale}x{H * a.scale} ({len(items)} figures)")


def frames_arg(s):
    out = []
    for part in s.split(","):
        if "-" in part:
            lo, hi = (int(v) for v in part.split("-"))
            out.extend(range(lo, hi + 1))
        else:
            out.append(int(part))
    return out


def cmd_strip(a):
    con = contract()
    w, h, n = con[a.id]
    seq = frames_arg(a.frames) * a.loops
    cell = w + 6
    W = max(cell * len(seq), int(a.step * len(seq)) + w) + 12
    band = h + 6
    feet = 4
    H = band + 6 + feet + 10
    canvas = [[None] * W for _ in range(H)]
    gy = band
    for y in range(H):
        for x in range(W):
            if gy <= y < gy + 6:
                canvas[y][x] = (0.39, 0.32, 0.25) if (x // 4 + y) % 2 else (0.34, 0.28, 0.22)
            elif y < gy:
                canvas[y][x] = (0.80, 0.82, 0.80)
            else:
                canvas[y][x] = (0.72, 0.74, 0.72)
    for i, k in enumerate(seq):
        paste(canvas, frame_of(con, a.id, k), 6 + i * cell, gy, "day", None)
    # the footprints: the bottom body rows of every frame at its advancing place, tinted in turn
    tints = [(1.0, 0.55, 0.45), (0.45, 0.65, 1.0), (0.55, 0.95, 0.55), (1.0, 0.9, 0.4)]
    fy = gy + 6 + feet + 3
    for i, k in enumerate(seq):
        fr = frame_of(con, a.id, k)
        rows = [r for r in range(h) if any(p[3] for p in fr[r])]
        last = rows[-1] if rows else h - 1
        x0 = 6 + int(i * a.step)
        for j in range(feet):
            r = last - (feet - 1) + j
            if r < 0:
                continue
            for x in range(w):
                p = fr[r][x]
                if p[3] and 0 <= x0 + x < W:
                    t = tints[i % 4]
                    canvas[fy - feet + 1 + j][x0 + x] = tuple(min(1.0, v / 255 * 0.5 + t[c] * 0.5)
                                                              for c, v in enumerate(p[:3]))
    write_png(a.output, scaled(canvas, a.scale))
    print(f"wrote {a.output} ({a.id} frames {seq}, {a.step} px a frame)")


def cmd_zoom(a):
    con = contract()
    w, h, n = con[a.id]
    W, H = n * (w + 1) + 1, h + 2
    canvas = [[(0.45, 0.48, 0.50)] * W for _ in range(H)]
    canvas = [list(r) for r in canvas]
    for k in range(n):
        fr = frame_of(con, a.id, k)
        for y in range(h):
            for x in range(w):
                p = fr[y][x]
                canvas[1 + y][1 + k * (w + 1) + x] = lit(p, "day") if p[3] else (
                    (0.66, 0.70, 0.72) if (x + y) % 2 else (0.60, 0.64, 0.66))
    write_png(a.output, scaled(canvas, a.scale))
    print(f"wrote {a.output} ({a.id}, {n} frames at {a.scale}00 %)")


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    p = sub.add_parser("lineup")
    p.add_argument("output")
    p.add_argument("--items", required=True)
    p.add_argument("--light", default="day", choices=("day", "dusk"))
    p.add_argument("--scale", type=int, default=6)
    p.add_argument("--gap", type=int, default=5)
    p.set_defaults(fn=cmd_lineup)
    p = sub.add_parser("strip")
    p.add_argument("output")
    p.add_argument("id")
    p.add_argument("--frames", default="0-3")
    p.add_argument("--scale", type=int, default=6)
    p.add_argument("--step", type=float, default=4)
    p.add_argument("--loops", type=int, default=2)
    p.set_defaults(fn=cmd_strip)
    p = sub.add_parser("zoom")
    p.add_argument("output")
    p.add_argument("id")
    p.add_argument("--scale", type=int, default=8)
    p.set_defaults(fn=cmd_zoom)
    a = ap.parse_args()
    a.fn(a)


if __name__ == "__main__":
    main()
