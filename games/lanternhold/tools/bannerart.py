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
  bannerart.py wind <id> [--out DIR]      build 3, POLISH pass 1 (docs/POLISH.md 2; lane 3): what flies in the wind,
                                          as frames side by side (build-art-world.sh):
      keepFlag      16x21, 4 frames: the realm's flag on the keep's poles (teal, the guardian house's gold lantern
                    near the hoist, a swallowtail), limp, stirring, flying, snapping (`Weather.flagFrame`). Column 0
                    is the cloth's hoist, one pixel right of the pole; row 0 its top, one row under the pole's top.
      castleBanner  18x30, 7 frames: the realm's banner hung from the curtain's parapet at tier 3 (keepart.py's
                    painting, 12 px, at cols 3 to 14), hanging still (0), its foot swung 1, 2 and 3 px toward the
                    valley (1 to 3) and toward the shadow land (4 to 6); the bar stays, the swing grows down the cloth.
                    Drawn both ways, so its light stays on its left (`WindLook`).

Pure python 3 (pixelart.py's PNG and palette code), deterministic, well under a second per banner.
"""
import argparse
import math
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


# ------------------------------------------------------------------------------------------------ in the wind
# Build 3, POLISH pass 1: the keep's flag. The cloth is a sheet hung from the hoist: a centreline from the hoist's top
# whose direction droops and waves along it, the hoist's height laid straight down from every point of it (a sheared
# sheet, right for a flag seen side on); the folds take the light by the wave's slope.
FLAG_W, FLAG_H = 16, 21
FLAG_HOIST = 7
# per frame: the cloth's length, its droop at the hoist and the droop added toward the fly (degrees, down from level),
# the wave's amplitude (degrees), its waves along the cloth and its phase
FLAG_POSES = [
    (13.0, 56.0, 16.0, 12.0, 1.9, 0.0),      # 0 limp: the cloth hangs down beside the pole in folds
    (13.0, 26.0, 24.0, 9.0, 1.1, 0.6),       # 1 stirring: lifted, its fly sagging
    (14.0, 8.0, 2.0, 15.0, 1.25, 0.0),       # 2 flying: a soft wave runs along it
    (14.5, 1.0, 0.0, 15.0, 1.6, 3.1416),     # 3 snapping: taut, the wave tighter and shifted half a length
]
FLAG_LANTERN = [".g.", "ggg", "gfg", "ggg"]  # the guardian house's lantern: its ring, its hood, the flame, its foot


def flag_frame(pal, k):
    length, droop, sag, amp, waves, phase = FLAG_POSES[k]
    c = lambda nm: pal.rgb[pal.index(nm)] + (255,)
    img = Image(FLAG_W, FLAG_H)
    seen = {}
    steps = int(length * 6)
    x, y = 0.0, 0.0
    for i in range(steps + 1):
        s = i / float(steps)
        bend = amp * (0.35 + 0.65 * s) * math.sin(2 * math.pi * waves * s + phase)
        a = math.radians(droop + sag * s + bend)
        slope = math.cos(2 * math.pi * waves * s + phase) if amp else 0.0   # > 0: the cloth turns down here
        for j in range(FLAG_HOIST * 6 + 1):
            t = j / float(FLAG_HOIST * 6)
            if s > 1 - 0.16 * (1 - abs(2 * t - 1)):                       # the swallowtail
                continue
            px, py = int(math.floor(x)), int(math.floor(y + t * (FLAG_HOIST - 0.01)))
            if 0 <= px < FLAG_W and 0 <= py < FLAG_H:
                seen[(px, py)] = (s, t, slope)
        x += (length / steps) * math.cos(a)
        y += (length / steps) * math.sin(a)
    ramp = ["roofDeep", "banner", "roofLight"]
    for (px, py), (s, t, slope) in seen.items():
        v = 2 if slope < -0.7 else 0 if slope > 0.82 else 1
        if t < 0.12:                      # the hem along the top catches the light
            v = min(2, v + 1)
        if t > 0.86 or s > 0.96:          # the lower edge and the fly in shade
            v = max(0, v - 1)
        name = ramp[v]
        if 0.16 <= s < 0.40 and 0.2 <= t < 0.8:
            ch = FLAG_LANTERN[min(3, int((t - 0.2) / 0.15))][min(2, int((s - 0.16) / 0.08))]
            if ch != ".":
                name = "gold" if ch == "g" else "fireGold"
        img.set(px, py, c(name))
    return img


BANNER_W, BANNER_SWING = 18, 3
BANNER_CHARGE = (12, 15)   # the rows of keepart's lantern on the banner: they move as one, so it never breaks


def banner_frame(base, swing):
    """keepart's hanging banner with its foot swung `swing` px (negative: to the left): row r of the cloth moves by
    swing x (r / last row) ^ 1.6, so the bar holds and the cloth bends toward its foot; the lantern's rows move by
    their middle row's shift."""
    img = Image(BANNER_W, base.h)
    last = float(base.h - 1)
    for yy in range(base.h):
        r = (BANNER_CHARGE[0] + BANNER_CHARGE[1]) / 2.0 if BANNER_CHARGE[0] <= yy <= BANNER_CHARGE[1] else yy
        shift = int(round(swing * (r / last) ** 1.6))
        for xx in range(base.w):
            p = base.get(xx, yy)
            if p[3]:
                img.set(BANNER_SWING + xx + shift, yy, p)
    return img


def wind_frames(wid, pal):
    if wid == "keepFlag":
        return [flag_frame(pal, k) for k in range(len(FLAG_POSES))]
    if wid == "castleBanner":
        import keepart  # the realm's banner as the castle paints it (keepart.py, world-2)
        base = keepart.castle_banner()
        return [banner_frame(base, s) for s in (0, 1, 2, 3, -1, -2, -3)]
    raise SystemExit(f"unknown wind sprite {wid}")


def wind_strip(wid, pal):
    frames = wind_frames(wid, pal)
    w, h = frames[0].w, frames[0].h
    out = Image(w * len(frames), h)
    for k, f in enumerate(frames):
        for yy in range(h):
            for xx in range(w):
                p = f.get(xx, yy)
                if p[3]:
                    out.set(k * w + xx, yy, p)
    return out


def main():
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest="cmd", required=True)
    b = sub.add_parser("build")
    b.add_argument("id")
    b.add_argument("--out", default=os.path.join(HERE, "..", "Resources", "Art"))
    sub.add_parser("list")
    sub.add_parser("place")
    w = sub.add_parser("wind")
    w.add_argument("id")
    w.add_argument("--out", default=os.path.join(HERE, "..", "Resources", "Art"))
    a = ap.parse_args()
    if a.cmd == "wind":
        pal = Palette(DEFAULT_PALETTE, True)
        os.makedirs(a.out, exist_ok=True)
        img = wind_strip(a.id, pal)
        write_png(os.path.join(a.out, a.id + ".png"), img)
        print(f"wrote {a.id}.png {img.w}x{img.h}")
        return
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
