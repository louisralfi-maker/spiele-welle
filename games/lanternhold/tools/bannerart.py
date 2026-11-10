#!/usr/bin/env python3
"""Lanternhold: the five houses' banners for the great hall (look 2, stage 7; ART-look2.md section 19.3, SPRITES.md
"The houses' banners").

`hallInterior` has five banners of the realm painted between its columns. A house's banner is a sprite of 20x41 that
hangs over one of them and hides it completely: the same dark line under the beam, the same 18 px of cloth between two
1 px outlines, the rectangle four rows longer and the point three rows lower than the painted ones (so every painted
banner, whose points differ by a pixel here and there, lies inside it). The cloth is painted as the hall's banners
are: a flat field, a shade under the beam and down the right edge; the charge sits where the realm's lantern sits
(the realm map's arms, docs/karte.html); a hem in the charge's metal runs along the point, which the realm's banners
do not have.

  bannerart.py build <id> [--out DIR]     writes DIR/<id>.png (default games/lanternhold/Resources/Art)
  bannerart.py list                       the ids, for build-art-court.sh
  bannerart.py place                      the five places in hallInterior (sprite left, top), for SPRITES.md

Pure python 3 (pixelart.py's PNG and palette code), deterministic, well under a second per banner.
"""
import argparse
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from pixelart import Image, Palette, write_png, DEFAULT_PALETTE  # noqa: E402

W, H = 20, 41
RECT = 31  # the last row of the rectangle (the cloth is rows 1..RECT, then the point)
# the painted banners' cloth starts at these columns of hallInterior; a sprite's left edge is one less, its top row 24
PLACES = [45, 84, 122, 159, 196]
TOP = 24

# id: (field, shade, hem, the charge's legend, the charge's rows, the charge's top row)
BANNERS = {
    # Varn: a grey cairn on green
    "bannerVarn": ("meadow", "leaf", "stoneLight", {"p": "stonePale", "l": "stoneLight", "s": "stone", "d": "stoneDark"}, [
        ".....pl.....",
        "....plls....",
        "....sddd....",
        "...pplll....",
        "..pllllls...",
        "..ssssddd...",
        "..ppplllll..",
        ".plllllllls.",
        ".llllllllss.",
        ".sssssssddd.",
    ], 9),
    # Brine: a white wave on sea blue, a thinner one under it
    "bannerBrine": ("roofLight", "banner", "stonePale", {"F": "foam", "f": "stonePale", "m": "mist"}, [
        "..FF......FF",
        ".FFFF....FFF",
        "FFmmFF..FFmm",
        "Fm..mFFFFm..",
        "m....mFFm...",
        "............",
        "..ff......ff",
        ".fmmf....fmm",
        "fm..mffffm..",
    ], 10),
    # Oxmoor: a golden sheaf on red
    "bannerOxmoor": ("crimson", "crimsonDeep", "gold", {"G": "gold", "Y": "strawLight", "y": "straw", "w": "parchment"}, [
        ".Y..Y..Y..Y.",
        "YGy.GY.Yy.GY",
        ".yG.yG.Gy.Gy",
        "..yG.GYG.Gy.",
        "...yGGYGGy..",
        "....GGYGy...",
        "....wwwww...",
        "....GGYGy...",
        "...yGGYGGy..",
        "..yG.GYG.Gy.",
        "..y..y.y..y.",
    ], 8),
    # Calder: three silver fish on black
    "bannerCalder": ("ink", "night1", "stoneLight", {"P": "stonePale", "F": "foam", "l": "stoneLight", "s": "stone"}, [
        "...FPPP....P",
        ".FPPPPPPllPP",
        "...llls....l",
        "............",
        "...FPPP....P",
        ".FPPPPPPllPP",
        "...llls....l",
        "............",
        "...FPPP....P",
        ".FPPPPPPllPP",
        "...llls....l",
    ], 8),
    # Lorn: a grey bell on plum
    "bannerLorn": ("plum", "plumDeep", "stoneLight", {"p": "stonePale", "l": "stoneLight", "s": "stone", "d": "stoneDark"}, [
        ".....ll.....",
        "....l..s....",
        ".....ls.....",
        "....plls....",
        "...pllsss...",
        "...pllsss...",
        "...pllsss...",
        "..ppllssss..",
        "..plllsssd..",
        ".ppllllsssd.",
        ".dddddddddd.",
        ".....pd.....",
    ], 8),
}


def cloth(r):
    """The cloth's first and last column in row r (None outside)."""
    if 1 <= r <= RECT:
        return 1, 18
    if RECT < r <= RECT + 8:
        k = r - RECT
        return 1 + k, 18 - k
    return None


def build(bid, pal):
    field, shade, hem, legend, rows, top = BANNERS[bid]
    c = lambda nm: pal.rgb[pal.index(nm)] + (255,)
    img = Image(W, H)
    for x in range(W):  # the dark line under the beam
        img.set(x, 0, c("night0"))
    for r in range(1, H):
        span = cloth(r)
        if span is None:  # the tip under the point
            for x in (9, 10):
                img.set(x, r, c("night1"))
            continue
        a, b = span
        edge = "night0" if r <= RECT else "night1"
        img.set(a - 1, r, c(edge))
        img.set(b + 1, r, c(edge))
        for x in range(a, b + 1):
            col = field
            # the shade under the beam (a full row, then it runs out toward the middle) and down the right edge
            if r == 1 or (r == 2 and (x <= 3 or x >= 14)) or (r == 3 and (x <= 1 or x >= 16)):
                col = shade
            elif x == b and r >= 2:
                col = shade
            elif x == b - 1 and (r <= 6 or r > RECT):
                col = shade
            if r > RECT and x in (a, b):  # the hem along the point
                col = hem
            img.set(x, r, c(col))
    x0 = (W - len(rows[0])) // 2
    for j, row in enumerate(rows):
        for i, ch in enumerate(row):
            if ch != ".":
                img.set(x0 + i, top + j, c(legend[ch]))
    return img


def main():
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest="cmd", required=True)
    b = sub.add_parser("build")
    b.add_argument("id")
    b.add_argument("--out", default=os.path.join(HERE, "..", "Resources", "Art"))
    sub.add_parser("list")
    sub.add_parser("place")
    a = ap.parse_args()
    if a.cmd == "list":
        print(" ".join(BANNERS))
        return
    if a.cmd == "place":
        for n, x in enumerate(PLACES):
            print(f"place {n + 1}: sprite left {x - 1}, top {TOP} in hallInterior (bottom {90 - TOP - H} px above its floor)")
        return
    if a.id not in BANNERS:
        raise SystemExit(f"unknown banner {a.id}")
    pal = Palette(DEFAULT_PALETTE, True)
    os.makedirs(a.out, exist_ok=True)
    write_png(os.path.join(a.out, a.id + ".png"), build(a.id, pal))
    print(f"wrote {a.id}.png {W}x{H}")


if __name__ == "__main__":
    main()
