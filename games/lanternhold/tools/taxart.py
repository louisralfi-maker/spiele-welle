#!/usr/bin/env python3
"""The town lane's art for the taxes on foot (town-2, docs/TOWN.md section 1, `TownSprites`). Pure python 3 through the
game's own pipeline: every figure is a hand-set part grid (tools/grids/town/*.txt, on the people lane's bodies in
tools/grids/town/base/) built by tools/actorart.py; the house overlays are cut from the house paintings themselves, so
their pixels, palette and grid are the houses' own. No generated image is involved.

  taxart.py build [name ...] [--out DIR]
        Writes Resources/Art/<id>.png (or DIR): the figures townCorra, townDun, townBrede, townHemmet, townWenna,
        townGorm, townNib (the child), the lord's knock kingKnock and ladyKnock, the coin townCoin, the collector's
        strongbox townStrongbox (grids), and the
        overlays townCottage and townBigHouse (from house.png, houseB.png, houseC.png, bigHouse.png). Without names:
        all of them.
  taxart.py proof <out.png> [--art DIR] [--scale 6]
        A proof sheet: every frame of every sprite, and the moments in context (the sign with the held coin, the toss,
        the knock, the bow, the shutters by day and by night).

The coin (fix round 1) is 4x4 with a dark rim on its shadow side; a waiting figure's coin is not in its grid but drawn
by the engine over its hands at `HELD` (keep in step with `TownSprites.heldCoin`), so it can glint and glow.

The overlays (64x46 and 72x56, the houses' sizes, drawn over the house at its place and with its mirror):
  frame 0  the open door: the door leaf swung in against the hinge side, the dark room behind, the floor's boards.
  frame 1+ the closed shutters of each painting: the painted open leaves moved over the window glass (the same
           pixels, a dark seam between them) and the wall filled in where they hung.
One image at a time and under a second each; run it through the director's art lock on the old Mac.
"""
import argparse
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from pixelart import Image, Palette, read_png, write_png, DEFAULT_PALETTE  # noqa: E402
import actorart  # noqa: E402

GAME = os.path.dirname(HERE)
ART = os.path.join(GAME, "Resources", "Art")
GRIDS = os.path.join(HERE, "grids", "town")

FIGURES = ["townCorra", "townDun", "townBrede", "townHemmet", "townWenna", "townGorm", "townNib", "kingKnock",
           "ladyKnock", "townCoin", "townStrongbox"]
OVERLAYS = ["townCottage", "townBigHouse"]
# The held coin's centre from a waiting figure's anchor (ahead of it) and above the ground, frame 0 (the breath lowers it
# a pixel on frame 1; the child's frame 4): `TownSprites.heldCoin`.
HELD = {"townCorra": (5, 14), "townDun": (5, 14), "townBrede": (5, 14), "townHemmet": (6, 9), "townWenna": (5, 14),
        "townGorm": (5, 16), "townNib": (4, 13)}
WIDTHS = {"kingKnock": 16, "ladyKnock": 16, "townCoin": 4, "townNib": 10, "townStrongbox": 6}

# The houses' doors and windows (columns and rows of the paintings, from the top left; ends inclusive).
COTTAGE_DOOR = (26, 29, 36, 42)
BIG_DOOR = (30, 41, 40, 52)
# A window: the left leaf's first column, the glass's first column, the right leaf's first column (each leaf 3 wide,
# the glass 7), the first and last row of the leaves.
COTTAGE_WINDOWS = [(7, 10, 17, 31, 37), (42, 45, 52, 31, 37)]
BIG_WINDOWS = [(12, 15, 22, 41, 46), (46, 49, 56, 41, 46), (22, 25, 32, 26, 31), (37, 40, 47, 26, 31)]


def pal():
    return Palette(DEFAULT_PALETTE, True)


# ------------------------------------------------------------------------------------------------------ figures

def build_figure(name, out):
    ns = argparse.Namespace(spec=os.path.join(GRIDS, name + ".txt"), out=out, palette=DEFAULT_PALETTE)
    actorart.cmd_build(ns)


# ----------------------------------------------------------------------------------------------------- overlays

def door_open(src, rect, p):
    """The open door over the door leaf `rect` (x0, y0, x1, y1): the leaf swung inward and seen edge-on at the hinge
    side (two columns of the door's own wood), the room dark behind it (warm dark earth, ink under the lintel and on
    the shadow side), the floor's boards in the last two rows."""
    x0, y0, x1, y1 = rect
    out = Image(src.w, src.h)
    ink = p.color("ink") + (255,)
    room = p.color("soilDark") + (255,)
    deep = p.color("night1") + (255,)
    floor = p.color("woodDark") + (255,)
    board = p.color("wood") + (255,)
    leaf_lit = p.color("woodLight") + (255,)
    leaf = p.color("wood") + (255,)
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            c = room
            if y == y0 or x == x1:
                c = ink
            elif y <= y0 + 2 or x >= x1 - 1:
                c = deep
            if y >= y1 - 1:
                c = floor if (x + y) % 4 else board
                if y == y1 - 1 and x == x1:
                    c = ink
            out.set(x, y, c)
    # the leaf against the hinge side: its lit edge and its face, a dark line where it meets the room
    for y in range(y0 + 1, y1 + 1):
        out.set(x0, y, leaf_lit)
        out.set(x0 + 1, y, leaf)
        out.set(x0 + 2, y, p.color("woodDark") + (255,))
    out.set(x0 + 1, y0 + 4, p.color("stoneMid") + (255,))   # the iron strap
    out.set(x0 + 1, y1 - 3, p.color("stoneMid") + (255,))
    return out


def shutters(src, windows, p, out=None):
    """The closed shutters: each window's painted open leaves moved over its glass (the same pixels, row by row, a dark
    seam between them) and the wall filled in where they hung (the plaster beside the leaf, plain plaster where a
    speck, an ivy leaf or a timber post stands beside it)."""
    out = out or Image(src.w, src.h)
    plain = p.color("plaster")
    seam = p.color("woodDark")
    walls = {p.color("plaster"), p.color("plasterDim")}
    for (lx, gx, rx, ya, yb) in windows:
        # the leaf colours: what the left leaf's middle column holds in most rows (the right leaf can hide behind a crate)
        leafs = {src.get(lx + c, y)[:3] for c in range(3) for y in range(ya, yb + 1)}
        last_left = last_right = None
        for y in range(ya, yb + 1):
            left = [src.get(lx + c, y) for c in range(3)]
            right = [src.get(rx + c, y) for c in range(3)]
            if any(px[:3] not in leafs for px in right) or any(px[3] == 0 for px in right):
                right = last_right or left
            if any(px[3] == 0 for px in left):
                left = last_left or right
            last_left, last_right = left, right
            for c in range(3):
                out.set(gx + c, y, left[c])
                out.set(gx + 4 + c, y, right[c])
            out.set(gx + 3, y, seam + (255,))
            # the wall where the leaves hung: the plaster beside the leaf (a speck, an ivy leaf or a timber post
            # beside it gives plain plaster)
            for side, x_beside in ((range(lx, lx + 3), lx - 1), (range(rx, rx + 3), rx + 3)):
                wall = src.get(x_beside, y)[:3]
                if wall not in walls:
                    wall = plain
                for x in side:
                    if src.get(x, y)[:3] in leafs:
                        out.set(x, y, wall + (255,))
    return out


def build_overlays(out_dir, names):
    p = pal()
    if "townCottage" in names:
        frames = []
        base, _ = read_png(os.path.join(ART, "house.png"))
        frames.append(door_open(base, COTTAGE_DOOR, p))
        for house in ("house", "houseB", "houseC"):
            src, _ = read_png(os.path.join(ART, house + ".png"))
            frames.append(shutters(src, COTTAGE_WINDOWS, p))
        write_strip(os.path.join(out_dir, "townCottage.png"), frames)
    if "townBigHouse" in names:
        src, _ = read_png(os.path.join(ART, "bigHouse.png"))
        write_strip(os.path.join(out_dir, "townBigHouse.png"), [door_open(src, BIG_DOOR, p),
                                                                shutters(src, BIG_WINDOWS, p)])


def write_strip(path, frames):
    w, h = frames[0].w, frames[0].h
    strip = Image(w * len(frames), h)
    for k, f in enumerate(frames):
        for y in range(h):
            for x in range(w):
                c = f.get(x, y)
                if c[3]:
                    strip.set(k * w + x, y, c)
    write_png(path, strip)
    print(f"wrote {os.path.basename(path)} {strip.w}x{h} ({len(frames)} frames)")


# -------------------------------------------------------------------------------------------------------- proof

def frames_of(path, w):
    img, _ = read_png(path)
    return [crop(img, k * w, 0, w, img.h) for k in range(img.w // w)]


def crop(img, x0, y0, w, h):
    out = Image(w, h)
    for y in range(h):
        for x in range(w):
            out.set(x, y, img.get(x0 + x, y0 + y))
    return out


def paste(canvas, img, x, y, flip=False, tint=None):
    for yy in range(img.h):
        for xx in range(img.w):
            c = img.get(img.w - 1 - xx if flip else xx, yy)
            if c[3] == 0:
                continue
            if tint:
                c = (int(c[0] * tint[0]), int(c[1] * tint[1]), int(c[2] * tint[2]), 255)
            cx, cy = x + xx, y + yy
            if 0 <= cx < canvas.w and 0 <= cy < canvas.h:
                canvas.set(cx, cy, c)


def cmd_proof(a):
    p = pal()
    art = a.art or ART
    scale = a.scale
    sky = p.color("farPale") + (255,)
    ground = p.color("soil") + (255,)
    W, H = 420, 340
    canvas = Image(W, H, [sky] * (W * H))

    def ground_band(y0, y1):
        for y in range(y0, y1):
            for x in range(W):
                canvas.set(x, y, ground)

    # every frame of every figure
    y = 2
    for name in FIGURES:
        path = os.path.join(art, name + ".png")
        if not os.path.exists(path):
            continue
        img, _ = read_png(path)
        w = WIDTHS.get(name, 12)
        x = 2
        for f in frames_of(path, w):
            paste(canvas, f, x, y)
            x += w + 2
        y += img.h + 2
    # the moments in context: a cottage (tile, the house painting), its door open with Corra waiting, the lord
    house, _ = read_png(os.path.join(ART, "house.png"))
    cottage = frames_of(os.path.join(art, "townCottage.png"), 64)
    corra = frames_of(os.path.join(art, "townCorra.png"), 12)
    lord = frames_of(os.path.join(ART, "king.png"), 16)
    knock = frames_of(os.path.join(art, "kingKnock.png"), 16)
    coin = frames_of(os.path.join(art, "townCoin.png"), 4)
    top = H - 60
    ground_band(top + 46, H)
    # 1 the sign: Corra in the open door facing the lord, her coin held up over her hands (mirrored with her)
    paste(canvas, house, 4, top)
    paste(canvas, cottage[0], 4, top)
    paste(canvas, corra[0], 4 + 31 - 5, top + 46 - 26, flip=True)
    held_dx, held_dy = HELD["townCorra"]
    paste(canvas, coin[0], 4 + 31 - held_dx - 2, top + 46 - held_dy - 2)
    paste(canvas, lord[6], 4 - 14, top + 46 - 30)
    # 2 the toss
    ox = 74
    paste(canvas, house, ox, top)
    paste(canvas, cottage[0], ox, top)
    paste(canvas, corra[3], ox + 31 - 5, top + 46 - 26, flip=True)
    paste(canvas, lord[6], ox + 4, top + 46 - 30)
    for k, (cx, cy) in enumerate([(ox + 24, top + 29), (ox + 19, top + 25), (ox + 14, top + 26)]):
        paste(canvas, coin[k % 4], cx, cy)
    # 3 the knock
    ox = 144
    paste(canvas, house, ox, top)
    paste(canvas, knock[1], ox + 31 - 6 - 8, top + 46 - 30)
    # 4 the bow
    ox = 214
    paste(canvas, house, ox, top)
    paste(canvas, cottage[0], ox, top)
    paste(canvas, corra[8], ox + 31 - 5, top + 46 - 26, flip=True)
    paste(canvas, knock[2], ox + 31 - 6 - 8, top + 46 - 30)
    paste(canvas, coin[0], ox + 24, top + 31)
    # 5 the shutters by day, 6 by night
    for ox, night in ((284, False), (350, True)):
        tint = (0.42, 0.45, 0.78) if night else None
        paste(canvas, house, ox, top, tint=tint)
        paste(canvas, cottage[1], ox, top, tint=tint)
    big = Image(W * scale, H * scale)
    px = []
    for yy in range(H * scale):
        row = canvas.px[(yy // scale) * W:(yy // scale + 1) * W]
        for c in row:
            px.extend([c] * scale)
    big.px = px
    write_png(a.out, big)
    print(f"wrote {a.out}")


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    b = sub.add_parser("build")
    b.add_argument("names", nargs="*")
    b.add_argument("--out")
    pr = sub.add_parser("proof")
    pr.add_argument("out")
    pr.add_argument("--art")
    pr.add_argument("--scale", type=int, default=6)
    a = ap.parse_args()
    if a.cmd == "build":
        out = a.out or ART
        names = a.names or FIGURES + OVERLAYS
        for name in names:
            if name in FIGURES:
                build_figure(name, out)
        build_overlays(out, [n for n in names if n in OVERLAYS])
    else:
        cmd_proof(a)


if __name__ == "__main__":
    main()
