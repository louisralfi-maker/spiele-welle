"""Writes tools/grids/people/lamplighter.txt. The figure's parts are hand-set below; the pole of each pose is a clean
pixel line between two hand-picked points, and the arms that hold it run from the shoulders to the pole, so the hands
always sit on it. Both are written out as parts like any other (one full-frame layer each)."""
import sys

W, H = 36, 30


def line(x0, y0, x1, y1):
    """A clean pixel line (Bresenham) from (x0, y0) to (x1, y1), both ends included."""
    pts = []
    dx, dy = abs(x1 - x0), -abs(y1 - y0)
    sx = 1 if x1 > x0 else -1
    sy = 1 if y1 > y0 else -1
    err = dx + dy
    x, y = x0, y0
    while True:
        pts.append((x, y))
        if x == x1 and y == y1:
            break
        e2 = 2 * err
        if e2 >= dy:
            err += dy
            x += sx
        if e2 <= dx:
            err += dx
            y += sy
    return pts


def layer(cells):
    grid = [["." for _ in range(W)] for _ in range(H)]
    for (x, y), c in cells.items():
        if 0 <= x < W and 0 <= y < H:
            grid[y][x] = c
    return ["".join(r) for r in grid]


def pole(butt, tip, flame=True):
    """The pole from its butt to its tip: plain wood, a lit run broken every third pixel by its shade, the brass wick
    holder one before the tip, the snuffer cone at the very tip; the wick's flame (glow only) beside the holder."""
    pts = line(*butt, *tip)
    cells = {}
    n = len(pts)
    for i, p in enumerate(pts):
        cells[p] = "e" if i == n - 1 else ("c" if i == n - 2 else ("h" if i % 3 == 2 else "l"))
    flame_at = None
    if flame:
        hx, hy = pts[-2]
        away = 1 if tip[0] >= butt[0] else -1
        for cand in [(hx, hy - 1), (hx + away, hy), (hx - away, hy - 1)]:
            if cand not in cells:
                cells[cand] = "*"
                flame_at = cand
                break
    return pts, cells, flame_at


def nearest(pts, target):
    return min(pts, key=lambda p: (p[0] - target[0]) ** 2 + (p[1] - target[1]) ** 2)


def arm(shoulder, hand, sleeve="M"):
    """A sleeve from the shoulder to the hand (the hand's pixel skin)."""
    cells = {}
    pts = line(*shoulder, *hand)
    for p in pts[:-1]:
        cells[p] = sleeve
    cells[pts[-1]] = "S"
    return cells


HEADER = """# lamplighter 36x30, 12 frames, and lamplighterGlow (the wick's flame on the same frames): walk 0-3, idle 4-5, the
# pole raised to a lantern 6 and the wick at its glass 7, the snuffer raised 8 and lowered on the glass 9, at the hearth
# the wick held into the Flame 10 and the head bowed to it 11 (docs/SPRITES-people.md; people-2, `TownLamps`). Silas
# Moth, 63, the lamplighter (docs/PEOPLE.md "Three more"; docs/TOWN.md section 7): a townsman who carries the house's
# light out into the street each dusk. Tall and thin as his pole and a little stooped: a narrow-brimmed felt hat, grey
# hair at the nape, a long thin face, the old burn up the side of his neck and jaw from a lantern that burst in his
# hands (`dusk`), a long dark coat to the shins, a soot-black thumb and forefinger, dark breeches, worn boots. The
# pole, longer than he is tall, of plain wood with a brass wick holder and a snuffer cone at its tip (`straw`,
# `stoneLight`): never the lord's hooked staff with its lantern. His feet stand on the frame's middle (column 18); the
# pole reaches out behind him or ahead. Light from the upper left; look 2's selective outline (the pole without one).
# Walk: a long stride (4 px a frame), the pole on the near shoulder, its tip up behind him. Idle: the pole upright at his
# side, a breath. Lighting and snuffing: both hands on the pole, its tip up to the glass of a lantern 15 px ahead of his
# feet at a height of 20. The hearth: the tip held low ahead into the fire, then his head bowed to it. The glow strip
# carries the wick's flame; the engine draws it only while the wick burns (`TownLamps.pose`). Written by
# tools/lamplighterpoles.py's rules: the poles are clean lines between hand-picked points and the arms run from the shoulders to
# the pole; this file is the source the build reads.
id lamplighter
size 36x30
frames 12
outline ink shade

legend
    k = ink
    S = dawnRose
    s = tileLight
    r = dusk
    P = stoneLight
    b = stonePale
    d = soil
    D = soilDark
    N = stone
    M = stoneMid
    K = stoneDark
    l = woodLight!
    h = wood!
    c = straw!
    e = stoneLight!
    * = /fireGold

# the narrow-brimmed felt hat
part hat
    ..dd..
    .dddD.
    ddddDD

# the long thin face in profile looking ahead: grey hair at the nape, the long nose, the old burn up the side of his
# jaw and neck below the ear
part head
    PSSS..
    PSSkSs
    .SSSS.
    .Srs..

# the bowed head (the hearth): the face turned down, the nose lower, the burn at the jaw
part headBowed
    PSSS..
    PSSSS.
    .SSkS.
    .SrSs.

# the long dark coat to the shins, narrow as he is, a little stooped (the collar a pixel forward), lit on the left, a
# fold down its back, two pale horn buttons on its front edge
part coat
    ..NMK.
    .NNMMK
    .NMMMb
    .NMKMK
    NNMKMb
    NMMKMK
    NMMKMKK
    NMMKMMK
    NMMKMMK
    NMMKMMK
    NMMMMMK
    NMMMMMK
    .NMMMK.

# the far arm hanging at his back (the walk, the idle)
part armBack
    N
    M
    s

part legsStand
    ..KK..
    ..KK..
    ..KK..
    .DDdD.

part legsPass
    ..KM..
    ..KM..
    ..KM..
    .DDdD.

part legsContactA
    ..KK...MM..
    .KK.....MM.
    .K.......M.
    DD.......DDd

part legsContactB
    ..MM...KK..
    .MM.....KK.
    .M.......K.
    DD.......DDd
"""


def main(path):
    # (frame, butt, tip, flame, near hand target, far hand target or None, body lift, bowed)
    poses = {
        0: ((23, 20), (3, 0), True, (20, 17), None, 0, False),
        1: ((23, 19), (3, 0), True, (20, 16), None, -1, False),
        4: ((23, 29), (23, 0), True, (23, 17), None, 0, False),
        5: ((23, 29), (23, 0), True, (23, 18), None, 1, False),
        6: ((12, 29), (31, 11), True, (24, 18), (20, 21), 0, False),
        7: ((14, 28), (33, 9), True, (25, 17), (21, 21), 0, False),
        8: ((12, 29), (31, 11), False, (24, 18), (20, 21), 0, False),
        9: ((14, 28), (33, 9), False, (25, 17), (21, 21), 0, False),
        10: ((13, 14), (33, 24), True, (23, 19), (19, 17), 0, False),
        11: ((13, 14), (33, 24), True, (23, 19), (19, 17), 0, True),
    }
    legs = {0: ("legsContactA", 13), 1: ("legsPass", 15), 2: ("legsContactA", 13)}
    text = HEADER
    frames = []
    tips = {}
    for n, (butt, tip, flame, near, far, lift, bowed) in sorted(poses.items()):
        pts, cells, flame_at = pole(butt, tip, flame)
        hand = nearest(pts, near)
        shoulder = (19, 14 + lift)
        front = arm(shoulder, hand)
        back = {}
        if far is not None:
            fhand = nearest(pts, far)
            back = arm((17, 15 + lift), fhand)
        if n in (4, 5):
            front[(hand[0], hand[1] + 1)] = "k"  # the soot-black thumb under the grip
        text += f"\npart pole{n}\n" + "\n".join("    " + r for r in layer(cells)) + "\n"
        text += f"\npart armNear{n}\n" + "\n".join("    " + r for r in layer(front)) + "\n"
        if back:
            text += f"\npart armFar{n}\n" + "\n".join("    " + r for r in layer(back)) + "\n"
        tips[n] = flame_at
        leg = legs.get(n, ("legsStand", 15))
        place = []
        if back:
            place.append((f"armFar{n}", 0, 0))
        else:
            place.append(("armBack", 15, 16 + lift))
        place.append((leg[0], leg[1], 26))
        place.append(("coat", 15, 13 + lift))
        if bowed:
            place += [("hat", 17, 7 + lift), ("headBowed", 17, 10 + lift)]
        else:
            place += [("hat", 16, 6 + lift), ("head", 16, 9 + lift)]
        place += [(f"pole{n}", 0, 0), (f"armNear{n}", 0, 0)]
        frames.append((n, place))
    # frame 2: the walk's other contact (the far leg ahead), the pole and arms of frame 0
    frames.append((2, [("armBack", 15, 16), ("legsContactB", 13, 26), ("coat", 15, 13), ("hat", 16, 6),
                       ("head", 16, 9), ("pole0", 0, 0), ("armNear0", 0, 0)]))
    text += "\n"
    for n, place in sorted(frames):
        text += f"frame {n}\n" + "".join(f"    {a} {x} {y}\n" for a, x, y in place) + "\n"
        if n == 2:
            text += "frame 3 = 1\n\n"
    with open(path, "w") as fh:
        fh.write(text.rstrip() + "\n")
    for n, t in sorted(tips.items()):
        if t:
            print(f"frame {n}: flame at {t}, dx {t[0] + 0.5 - 18:+.1f}, dy {30 - t[1] - 0.5:.1f}")


if __name__ == "__main__":
    main(sys.argv[1])
