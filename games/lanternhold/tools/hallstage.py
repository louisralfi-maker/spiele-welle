#!/usr/bin/env python3
"""The great hall as a stage (stage lane, 14.11.2026; DESIGN.md "The hall stage and touch the world", SPRITES.md
"The hall stage's light"): the day's light shafts, a dust mote and the plaster patches over the brick. The hall
itself (`greatHall`, `hallPillarNear`, `hallFire`) is tools/hallart.py's; these three sprites only add light and wear
to it.

    python3 -I -B tools/hallstage.py            # writes the three PNGs into Resources/Art
    python3 -I -B tools/hallstage.py places     # prints the plaster patches' places for Core/HallLayout.swift

Pure Python, integer hashes, palette names only (tools/palette.txt): every run writes the same bytes. One small
image at a time, so the old Mac stays cool.

- `hallShaft` (83x120): the light of one of the nave's two-light windows falling onto the floor in a soft beam,
  slanting down to the right (the sun stands left of the hall in the afternoon; the engine mirrors it for the
  morning). White: the engine draws it as an emissive glow in the daylight's colour, so its alpha is the beam's
  strength, in ordered-dither steps like the light pools.
- `hallMote` (1x1): one speck of dust in a shaft.
- `hallWash` (8 frames of 64x44): limewash and plaster patches, each cut for its own place on the wall (the places
  below): only where the hall's ashlar shows (never over a banner, a window, a shaft or the wainscot), a pale warm
  plaster in palette tones, a crumbling edge, the joints of the stone showing through where the wash is thin, and a
  one-pixel shadow under its lower edge.
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
# Each patch: the frame's top-left on the hall (x, row), the blob's centre in the frame, its half sizes, a seed. At
# different heights so they never read as a band: right of the door, high and low in both window bays, on the dais
# end beside the arms, left of the hearth's hood and right of its firebox.
WASH = (
    (80, 92, 32, 26, 14, 12, 1),
    (140, 36, 26, 22, 15, 9, 2),
    (124, 104, 28, 22, 16, 9, 3),
    (256, 40, 32, 20, 17, 10, 4),
    (316, 100, 32, 22, 13, 11, 5),
    (440, 100, 26, 20, 14, 11, 6),
    (476, 96, 14, 24, 10, 12, 7),
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


def blocks(hall, fx, fy, pal):
    """The ashlar's blocks inside a patch's frame, as sets of frame pixels: the courses lie between the rows where
    the ink joints run across, the blocks of a course between its upright joints. A block that holds anything but
    the stone ramp (a banner, a window, the wainscot) is left out."""
    ink = pal["ink"]
    stone = {pal[n] for n in STONE}

    def is_ink(x, y):
        p = hall[fy + y][fx + x]
        return p[3] == 255 and (p[0], p[1], p[2]) == ink

    def is_joint(x, y):
        p = hall[fy + y][fx + x]
        return p[3] == 255 and (p[0], p[1], p[2]) in (ink, pal["stoneMid"], pal["stoneDark"])

    # A bed joint is a row that is mostly ink and the blocks' shaded lowest course of pixels.
    joint_rows = [y for y in range(WASH_H) if sum(is_joint(x, y) for x in range(WASH_W)) * 10 >= WASH_W * 6]
    courses = []
    top = 0
    for y in joint_rows + [WASH_H]:
        if y - top >= 3:
            courses.append((top, y - 1))
        top = y + 1
    found = []
    for (y0, y1) in courses:
        rows = y1 - y0 + 1
        # A head joint: a column that is ink or the blocks' shade almost all the way down the course.
        joints = [x for x in range(WASH_W) if sum(is_joint(x, y) for y in range(y0, y1 + 1)) * 5 >= rows * 4]
        left = 0
        for x in joints + [WASH_W]:
            if x - left >= 3 and left > 0 and x < WASH_W:
                block = {(bx, by) for bx in range(left, x) for by in range(y0, y1 + 1)}
                plain = sum(1 for (bx, by) in block
                            if hall[fy + by][fx + bx][3] == 255
                            and tuple(hall[fy + by][fx + bx][:3]) in stone)
                if plain * 10 >= len(block) * 9:
                    found.append(block)
            left = x + 1
    return found


def wash(places_only=False):
    """Plaster laid over whole blocks round a centre, so its edge follows the joints; a few blocks inside left bare
    (the plaster fell off), the joints between covered blocks filled, a pale top edge and a shadow under it."""
    pal = palette()
    hall_w, hall_h, hall, _ = read_png(os.path.join(ART, "greatHall.png"))
    base, warm, light, worn = pal["rockPale"], pal["stoneLight"], pal["stonePale"], pal["stoneLight"]
    shadow = pal["stoneMid"]
    frames = []
    for (fx, fy, cx, cy, rx, ry, seed) in WASH:
        covered = set()
        for i, block in enumerate(blocks(hall, fx, fy, pal)):
            mx = sum(x for x, _ in block) / len(block)
            my = sum(y for _, y in block) / len(block)
            wobble = (h(seed, i, 3) % 100) / 100.0 * 0.5
            d = ((mx - cx) / rx) ** 2 + ((my - cy) / ry) ** 2
            if d > 0.75 + wobble:
                continue
            # Inside, now and then a bare block where the plaster fell away.
            if d < 0.5 and h(seed, i, 5) % 9 == 0:
                continue
            covered |= block
        # The joints between two covered pixels are plastered over too.
        mask = set(covered)
        for y in range(WASH_H):
            for x in range(WASH_W):
                if (x, y) in covered:
                    continue
                horiz = (x - 1, y) in covered and (x + 1, y) in covered
                vert = (x, y - 1) in covered and (x, y + 1) in covered
                if horiz or vert:
                    p = hall[fy + y][fx + x]
                    if p[3] == 255:
                        mask.add((x, y))
        img = blank(WASH_W, WASH_H)
        for (x, y) in mask:
            n = h(seed, x // 4, y // 3, 11) % 100
            colour = base if n < 62 else (warm if n < 90 else worn)
            if (x, y - 1) not in mask:
                colour = light if h(seed, x, y, 17) % 4 == 0 else base
            elif (x - 1, y) not in mask and h(seed, x, y, 19) % 2:
                colour = warm
            img[y][x] = colour + (255,)
        # A one-pixel shadow under the plaster's lower edge, on the stone below it.
        for (x, y) in mask:
            below = (x, y + 1)
            if below not in mask and y + 1 < WASH_H:
                p = hall[fy + y + 1][fx + x]
                if p[3] == 255:
                    img[y + 1][x] = shadow + (255,)
        frames.append(img)
        if places_only:
            print("        (%d, %d), // %d px" % (fx, fy, len(mask)))
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
    shaft()
    mote()
    wash()
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
