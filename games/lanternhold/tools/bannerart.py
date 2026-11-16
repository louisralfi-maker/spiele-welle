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
      keepFlag      16x21, 10 frames: the realm's flag on the keep's poles (teal, the guardian house's gold lantern
                    near the hoist, a swallowtail): limp (0), stirring (1), a flying cycle (2-5) and a snapping cycle
                    (6-9) in which a fold runs from the hoist to the fly (`Weather.flagFrame`; step 2, the critic's
                    H1 and H2). Column 0 is the cloth's hoist, one pixel right of the pole; row 0 one row under the
                    pole's top, the cloth from row 2.
      keepFlagRim   16x21, 20 frames, emissive: the keep's dusk rim on the flag (0-9 streaming east, 10-19 for the
                    mirrored flag streaming west; step 2, the critic's M7).
      castleBanner  18x30, 7 frames: the realm's banner hung from the curtain's parapet at tier 3 (keepart.py's
                    painting, 12 px, at cols 3 to 14), hanging still (0), its foot swung 1, 2 and 3 px toward the
                    valley (1 to 3) and toward the shadow land (4 to 6); the bar stays, the swing grows down the cloth
                    as a curve with in-between pixels, a lit edge down its left (step 2, the critic's M4). Drawn both
                    ways, so its light stays on its left (`WindLook`).

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
# Build 3, POLISH pass 1: the keep's flag. Step 2 (the critic's H1 and H2): limp hangs straight down by the pole in
# folds, stirring lifts it to about 30 degrees with a belly, and flying and snapping are cycles of four frames in which a
# fold and its lit ridge run from the hoist to the fly. A flag seen side on is drawn as columns: each column of cloth
# from its top row down the hoist's height, its folds vertical bands lit by the wave's slope.
FLAG_W, FLAG_H = 16, 21
FLAG_TOP = 2          # the hoist's top row: the pole's tip and its gold point stand above the cloth
FLAG_HOIST = 7
FLAG_FRAMES = 10      # 0 limp, 1 stirring, 2-5 flying, 6-9 snapping (`Weather.flagFrame`)
FLAG_RAMP = ["roofDeep", "banner", "roofLight"]
FLAG_LEGEND = {"L": "roofLight", "B": "banner", "D": "roofDeep", "G": "gold", "g": "straw"}
# limp: the cloth hangs down beside the pole, folded to six columns and 13 rows (shorter than the fly: it is folded),
# a lit ridge and a dark crease running down it, the swallowtail's two points at its foot, the lantern a gold glint
# half in the ridge's fold, the hoist's corner tight to the pole
FLAG_LIMP = [
    "LLLBB.",
    "BLBBD.",
    "BLBDBD",
    "BLBDBD",
    "GgBDBD",
    "ggBDBD",
    "BLBDBD",
    "BLBDBD",
    "BLBDDD",
    "BLBDBD",
    "BLD.BD",
    "BL...D",
    "B.....",
]
FLAG_LANTERN = [".g.", "ggg", "gfg", "ggg"]  # the guardian house's lantern: its ring, its hood, the flame, its foot


def _flag_columns(pal, length, top, height, slope, notch):
    """A flag as columns: column x from row top(x), height(x) rows, no column a step of more than a pixel from its
    neighbour; lit by slope(x) (< 0: the cloth turns up toward the light, > 0: it turns away), the hem along the top
    lit and the lower edge in shade; notch(x) rows cut out of the middle of the fly (the swallowtail); the lantern
    near the hoist rides on the cloth as one."""
    c = lambda nm: pal.rgb[pal.index(nm)] + (255,)
    img = Image(FLAG_W, FLAG_H)
    last = None
    for x in range(length):
        t, h = top(x), height(x)
        if last is not None:
            t = max(last[0] - 1, min(last[0] + 1, t))
            b = max(last[1] - 1, min(last[1] + 1, t + h - 1))
            h = b - t + 1
        last = (t, t + h - 1)
        s = slope(x)
        val = 2 if s < -0.3 else 0 if s > 0.3 else 1
        n = notch(x)
        mid = t + (h - 1) / 2.0
        for r in range(h):
            y = t + r
            if n > 0 and abs(y - mid) < n / 2.0:
                continue
            v = min(2, val + 1) if r == 0 else max(0, val - 1) if r == h - 1 else val
            if 0 <= y < FLAG_H:
                img.set(x, y, c(FLAG_RAMP[v]))
    ly = top(4) + 1
    for j, row in enumerate(FLAG_LANTERN):
        for i, ch in enumerate(row):
            if ch != ".":
                img.set(3 + i, ly + j, c("gold" if ch == "g" else "fireGold"))
    return img


def _flag_limp(pal):
    c = lambda nm: pal.rgb[pal.index(nm)] + (255,)
    img = Image(FLAG_W, FLAG_H)
    for y, row in enumerate(FLAG_LIMP):
        for x, ch in enumerate(row):
            if ch != ".":
                img.set(x, FLAG_TOP + y, c(FLAG_LEGEND[ch]))
    return img


def _flag_stirring(pal):
    """Lifted to about 30 degrees below level, 12 columns long, a belly of air under its middle."""
    length = 12
    th = math.tan(math.radians(30))
    dy = lambda x: th * x - 1.4 * math.sin(math.pi * x / (length - 1))
    return _flag_columns(pal, length, lambda x: FLAG_TOP + int(round(dy(x))),
                         lambda x: FLAG_HOIST - 1 - (1 if x > 8 else 0),
                         lambda x: -0.5 if x in (2, 3, 4) else 0.5 if x in (8, 9) else 0.0,
                         lambda x: {10: 1, 11: 3}.get(x, 0))


def _flag_wave(pal, phase, k, a0, a1, sag, notch0, notch_swing, taper, folds_thin):
    """One frame of a travelling wave (phase steps a quarter wave a frame, so the fold runs from hoist to fly): its
    amplitude grows from a0 at the hoist to a1 at the fly, the fly sags by `sag`, the swallowtail's points open and
    close with the phase."""
    length = 14
    amp = lambda x: a0 + (a1 - a0) * x / (length - 1)
    dy = lambda x: amp(x) * math.sin(k * x - phase) + sag * (x / (length - 1)) ** 2
    turn = lambda x: amp(x) * k * math.cos(k * x - phase)

    def height(x):
        thin = 1 if folds_thin and abs(turn(x)) > 0.55 else 0     # a soft fold turns edge on and looks narrower
        return FLAG_HOIST - (1 if x >= length - taper else 0) - thin

    def notch(x):
        depth = notch0 + notch_swing * math.sin(phase)
        return max(0, int(round(2 * (x - (length - 1 - depth)) + 1))) if x > length - 1 - depth else 0
    return _flag_columns(pal, length, lambda x: FLAG_TOP + int(round(dy(x))), height,
                         lambda x: turn(x) + 2 * sag * x / (length - 1) ** 2, notch)


def flag_frame(pal, k):
    if k == 0:
        return _flag_limp(pal)
    if k == 1:
        return _flag_stirring(pal)
    if k < 6:   # flying: a long soft wave, the fly sagging a pixel, rising and falling a pixel with it
        return _flag_wave(pal, (k - 2) * math.pi / 2, 2 * math.pi / 10, 0.15, 1.1, 1.0, 1.6, 0.6, 3, True)
    # snapping: taut and level, a short wave whipping the fly up to two pixels, the points crossing
    return _flag_wave(pal, (k - 6) * math.pi / 2 + 0.4, 2 * math.pi / 8, 0.1, 1.5, 0.0, 1.4, 0.8, 2, False)


def flag_rim(frames, west):
    """keepFlagRim: the keep's dusk rim on the flag's cloth (`SceneLayout.castleKeepRims`' rule, keepfix.py
    `keep_rim`): fire orange on the edges that face the low sun in the west, a px inside at half, the top faintly.
    Frames 0-9 for a flag streaming east (its west edges), 10-19 for one mirrored to stream west: drawn on the edges
    that face east in the unmirrored frame, so mirrored they face the sun."""
    out = []
    for f in frames:
        im = Image(FLAG_W, FLAG_H)
        solid = lambda x, y: 0 <= x < FLAG_W and 0 <= y < FLAG_H and f.get(x, y)[3] > 0
        side = 1 if west else -1
        for y in range(FLAG_H):
            for x in range(FLAG_W):
                if not solid(x, y):
                    continue
                a = 0.0
                if not solid(x + side, y):
                    a = 0.62
                elif not solid(x + 2 * side, y):
                    a = 0.3
                if not solid(x, y - 1):
                    a = max(a, 0.34)
                if a > 0:
                    im.set(x, y, FLAG_RIM + (int(a * 255),))
        out.append(im)
    return out


FLAG_RIM = (255, 138, 42)   # fireOrange

BANNER_W, BANNER_SWING = 18, 3
BANNER_CHARGE = (12, 15)   # the rows of keepart's lantern on the banner: they move as one, so it never breaks


def banner_frame(base, swing, pal):
    """keepart's hanging banner with its foot swung `swing` px (negative: to the left) along a curve: row r moves by
    swing x (r / last row) ^ 1.6; where the curve is between two whole pixels the row is drawn at the nearer one and
    the step gets an in-between pixel (the leading edge stretched a pixel before the step, the trailing edge held a
    pixel after it), so the outline bends instead of stepping in blocks. The lantern's rows move as one. Step 2 (the
    critic's M4): a 1 px lit edge (roofLight) down the cloth's light side, so it reads against the curtain at dusk."""
    lit = pal.rgb[pal.index("roofLight")] + (255,)
    img = Image(BANNER_W, base.h)
    last = float(base.h - 1)
    sign = 1 if swing > 0 else -1
    def curve(r):
        f = abs(swing) * (r / last) ** 1.6
        whole = int(math.floor(f))
        return sign * (whole + (1 if f - whole >= 0.5 else 0)), f - whole
    charge = curve((BANNER_CHARGE[0] + BANNER_CHARGE[1]) / 2.0)[0]
    lantern = {pal.rgb[pal.index(nm)] + (255,) for nm in ("gold", "fireGold", "cloth2")}
    for yy in range(base.h):
        shift, frac = curve(yy)
        xs = [xx for xx in range(base.w) if base.get(xx, yy)[3]]
        if not xs:
            continue
        marks = []
        for xx in xs:
            p = base.get(xx, yy)
            if BANNER_CHARGE[0] <= yy <= BANNER_CHARGE[1] and p in lantern:
                marks.append((xx, p))
                p = base.get(xs[-4], yy)                      # the field under the lantern (right of it)
            if yy >= 2 and xx == xs[0] and p != base.get(xx, 0):
                p = lit                                   # the lit edge (never on the bar)
            img.set(BANNER_SWING + xx + shift, yy, p)
        for xx, p in marks:                               # the lantern's rows move as one, over the curved cloth
            img.set(BANNER_SWING + xx + charge, yy, p)
        if yy >= 2 and swing != 0 and 0.25 <= frac < 0.75:
            lead, trail = (xs[-1], xs[0]) if sign > 0 else (xs[0], xs[-1])
            if frac < 0.5:      # before the step: the leading edge reaches a pixel on
                img.set(BANNER_SWING + lead + shift + sign, yy, base.get(lead, yy))
            else:               # after it: the trailing edge stays a pixel behind
                p = base.get(trail, yy)
                img.set(BANNER_SWING + trail + shift - sign, yy, lit if sign > 0 else p)
    return img


def wind_frames(wid, pal):
    if wid == "keepFlag":
        return [flag_frame(pal, k) for k in range(FLAG_FRAMES)]
    if wid == "keepFlagRim":
        frames = [flag_frame(pal, k) for k in range(FLAG_FRAMES)]
        return flag_rim(frames, False) + flag_rim(frames, True)
    if wid == "castleBanner":
        import keepart  # the realm's banner as the castle paints it (keepart.py, world-2)
        base = keepart.castle_banner()
        return [banner_frame(base, s, pal) for s in (0, 1, 2, 3, -1, -2, -3)]
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
