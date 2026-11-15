#!/usr/bin/env python3
"""The great hall as a stage (stage lane, 14.11.2026; DESIGN.md "The hall stage and touch the world", SPRITES.md
"The hall stage's light"): the day's light shafts, a dust mote and the plaster patches over the brick. The hall
itself (`greatHall`, `hallPillarNear`, `hallFire`) is tools/hallart.py's; these three sprites only add light and wear
to it.

    python3 -I -B tools/hallstage.py            # writes the three PNGs into Resources/Art
    python3 -I -B tools/hallstage.py places     # prints the plaster patches' places for Core/HallLayout.swift
    python3 -I -B tools/hallstage.py wash       # writes only hallWash.png

Pure Python, integer hashes, palette names only (tools/palette.txt): every run writes the same bytes. One small
image at a time, so the old Mac stays cool.

- `hallShaft` (83x120): the light of one of the nave's two-light windows falling onto the floor in a soft beam,
  slanting down to the right (the sun stands left of the hall in the afternoon; the engine mirrors it for the
  morning). White: the engine draws it as an emissive glow in the daylight's colour, so its alpha is the beam's
  strength, in ordered-dither steps like the light pools.
- `hallMote` (1x1): one speck of dust in a shaft.
- `hallWash` (8 frames of 64x44): limewash stains, each cut for its own place on the wall (the places below): only
  where the hall's ashlar shows (never over a banner, a window, a shaft or the wainscot), a ragged outline with an
  ordered-dither feather, each pixel one step warmer than the stone under it (the blocks and joints read through),
  and a few small islands of thicker plaster (fix round 1 of step stage-1: the old patches covered whole blocks and
  read as square light blocks).
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "scenemock"))
from pngr import read_png  # noqa: E402
from pngw import write_png  # noqa: E402

ART = os.path.normpath(os.path.join(HERE, "..", "Resources", "Art"))

BAYER = ((0, 8, 2, 10), (12, 4, 14, 6), (3, 11, 1, 9), (15, 7, 13, 5))

# The beam: one window's two lights (11 px each, a 2 px mullion between them, ART-look2.md 20.1) from the lancets'
# spring (hall row 72) down to the floor in front of the wall (row 191).
SHAFT_LIGHTS = ((3, 14), (16, 27))
SHAFT_TOP = 72
SHAFT_LEN = 120
SHAFT_SLANT = 0.44
SHAFT_W = 30 + int(SHAFT_SLANT * SHAFT_LEN) + 1

WASH_W, WASH_H = 64, 44
# Each patch: the frame's top-left on the hall (x, row), the stain's centre in the frame, its half sizes, a seed. At
# different heights so they never read as a band: right of the door, high and low in both window bays, high on the
# dais end above the arms, high on the gallery's wall left of its window, right of the hearth's firebox. None beside
# a sconce or a candle (fix round 1: a patch beside the throne's sconce turned into an orange square in its light).
WASH = (
    (80, 92, 32, 26, 14, 12, 1),
    (140, 36, 26, 22, 15, 9, 2),
    (124, 104, 28, 22, 16, 9, 3),
    (256, 40, 32, 20, 17, 10, 4),
    (316, 100, 32, 22, 13, 11, 5),
    (430, 30, 30, 18, 14, 9, 6),
    (14, 30, 22, 20, 12, 10, 7),
    (536, 128, 32, 22, 18, 10, 8),
)
# The hall's ashlar (tools/hallart.py `wall`): the stone ramp. The wash goes only there.
STONE = ("stoneDark", "stoneMid", "stone", "stoneLight", "stonePale")


def palette():
    colours = {}
    for line in open(os.path.join(HERE, "palette.txt")):
        if line.lstrip().startswith("#"):
            continue
        parts = line.split()
        if len(parts) >= 2 and parts[1].startswith("#") and len(parts[1]) == 7:
            colours[parts[0]] = tuple(int(parts[1][i:i + 2], 16) for i in (1, 3, 5))
    return colours


def h(*values):
    """An integer hash of a few integers, 0 ... 65535 (the same on every Python)."""
    x = 0x9E3779B9
    for v in values:
        x = (x ^ (v & 0xFFFFFFFF)) * 0x01000193 & 0xFFFFFFFF
        x ^= x >> 15
        x = x * 0x2C1B3C6D & 0xFFFFFFFF
        x ^= x >> 12
    return x & 0xFFFF


def blank(w, h_):
    return [[(0, 0, 0, 0) for _ in range(w)] for _ in range(h_)]


def save(name, img):
    hgt = len(img)
    wid = len(img[0])
    rows = []
    for row in img:
        line = bytearray()
        for p in row:
            line += bytes(p)
        rows.append(line)
    path = os.path.join(ART, name + ".png")
    write_png(path, wid, hgt, rows)
    print("wrote", path, wid, "x", hgt)


def quantize(a, x, y):
    """An alpha 0 ... 1 in eight steps with a 4x4 ordered dither between them (as the light pools)."""
    steps = 8
    v = max(0.0, min(1.0, a)) * steps
    low = int(v)
    if (v - low) * 16 > BAYER[y % 4][x % 4]:
        low += 1
    return min(steps, low) / steps


def shaft():
    img = blank(SHAFT_W, SHAFT_LEN)
    for r in range(SHAFT_LEN):
        t = r / (SHAFT_LEN - 1)
        shift = SHAFT_SLANT * r
        # Strongest just below the window, thinning toward the floor; the last rows fade where it lands.
        along = 1.0 - 0.45 * t
        if t > 0.86:
            along *= max(0.0, (1.0 - t) / 0.14) ** 0.8
        if t < 0.06:
            along *= 0.55 + 0.45 * t / 0.06
        for x in range(SHAFT_W):
            u = x - shift
            a = 0.0
            for lo, hi in SHAFT_LIGHTS:
                # Soft edges, two pixels wide, widening a little as the beam spreads.
                soft = 1.5 + 1.5 * t
                inside = min(u - lo + soft, hi - u + soft) / (2 * soft)
                a = max(a, max(0.0, min(1.0, inside)))
            # The mullion's shadow fades out as the two lights spread into one.
            if a < 0.5 and SHAFT_LIGHTS[0][1] - 1 <= u <= SHAFT_LIGHTS[1][0] + 1:
                a = max(a, 0.35 * t + 0.1)
            q = quantize(a * along, x, r)
            if q > 0:
                img[r][x] = (255, 255, 255, int(round(q * 255)))
    save("hallShaft", img)


def mote():
    save("hallMote", [[(255, 255, 255, 255)]])


def noise(seed, x, y, cell):
    """Smooth value noise in -1 ... 1: integer hashes on a grid of `cell` px, blended bilinearly (smoothstepped)."""
    gx, gy = x // cell, y // cell
    tx, ty = (x % cell) / float(cell), (y % cell) / float(cell)
    tx, ty = tx * tx * (3 - 2 * tx), ty * ty * (3 - 2 * ty)

    def corner(i, j):
        return h(seed, gx + i, gy + j, cell) / 32767.5 - 1.0

    top = corner(0, 0) + (corner(1, 0) - corner(0, 0)) * tx
    bottom = corner(0, 1) + (corner(1, 1) - corner(0, 1)) * tx
    return top + (bottom - top) * ty


# The walls end at this hall row (the dais's flags below it share the stone ramp).
WALL_BOTTOM = 152
# The wash over each tone of the ashlar (fix round 1, critic look 1: "light the patch with the wall underneath it"):
# a warm limewash stain one step warmer and at most one step lighter than the stone it lies on, so the blocks, their
# highlights and the joints read through it and it never becomes a lighter block of its own. The thin edge only warms.
WASH_CORE = {"ink": "rockDeep", "stoneDark": "rockDark", "stoneMid": "rock", "stone": "rockLight",
             "stoneLight": "rockPale", "stonePale": "stonePale"}
WASH_EDGE = {"ink": "ink", "stoneDark": "rockDeep", "stoneMid": "rockDark", "stone": "rock",
             "stoneLight": "rockPale", "stonePale": "stonePale"}


def wash(places_only=False):
    """Limewash stains over the ashlar (fix round 1): a noisy ellipse, so the outline is ragged (no straight run
    longer than three or four pixels), with one to two pixels of ordered-dither feather at its edge; each pixel takes
    the wash tone of the stone under it (`WASH_CORE` inside, `WASH_EDGE` in the feather), and a few small islands of
    thicker plaster sit where the stain is thickest, each with a one-pixel shadow under it. Only over the stone ramp
    and its ink joints: never over a banner, a window, the wood or the wainscot."""
    pal = palette()
    names = {v: k for k, v in pal.items() if k in WASH_CORE}
    hall_w, hall_h, hall, _ = read_png(os.path.join(ART, "greatHall.png"))
    frames = []
    for (fx, fy, cx, cy, rx, ry, seed) in WASH:
        img = blank(WASH_W, WASH_H)
        thick = set()
        count = 0
        for y in range(WASH_H):
            for x in range(WASH_W):
                p = hall[fy + y][fx + x]
                # Only on the walls: the flags of the dais (from hall row 152) are the same stone ramp.
                if p[3] != 255 or fy + y >= WALL_BOTTOM:
                    continue
                name = names.get((p[0], p[1], p[2]))
                if name is None:
                    continue
                d = ((x - cx) / float(rx)) ** 2 + ((y - cy) / float(ry)) ** 2
                ragged = 0.42 * noise(seed, x, y, 5) + 0.22 * noise(seed + 50, x, y, 2)
                cover = 1.0 - (d + ragged)
                if cover <= 0:
                    continue
                if cover < 0.32:
                    # The feather: an ordered dither between the bare stone and the thin edge.
                    if cover / 0.32 * 16 <= BAYER[(y + fy) % 4][(x + fx) % 4]:
                        continue
                    tone = WASH_EDGE[name]
                else:
                    # Thin wash warms the stone; only where it is thick does it lighten it a step.
                    tone = WASH_CORE[name] if cover > 0.55 or name != "stone" else WASH_EDGE[name]
                    if cover > 0.62 and name in ("stone", "stoneLight") and noise(seed + 90, x, y, 3) > 0.25:
                        thick.add((x, y))
                img[y][x] = pal[tone] + (255,)
                count += 1
        # The islands of thicker plaster: only clusters of three or more, so no lone pixel sparkles.
        for (x, y) in thick:
            near = sum((x + i, y + j) in thick for i in (-1, 0, 1) for j in (-1, 0, 1)) - 1
            if near < 2:
                continue
            img[y][x] = pal["rockPale"] + (255,)
            below = (x, y + 1)
            if below not in thick and y + 1 < WASH_H and img[y + 1][x][3] == 255:
                img[y + 1][x] = pal["rockDark"] + (255,)
        frames.append(img)
        if places_only:
            print("        (%d, %d), // %d px" % (fx, fy, count))
    if places_only:
        return
    strip = blank(WASH_W * len(frames), WASH_H)
    for i, img in enumerate(frames):
        for y in range(WASH_H):
            for x in range(WASH_W):
                strip[y][i * WASH_W + x] = img[y][x]
    save("hallWash", strip)


def main(argv):
    if argv and argv[0] == "places":
        wash(places_only=True)
        return 0
    if argv and argv[0] == "wash":
        wash()
        return 0
    shaft()
    mote()
    wash()
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
