"""Writes tools/grids/people/lamplighter.txt. The figure's parts are hand-set below (repainted in people-2's fix round 1:
the stoop, the coat tapered from the shoulder with a fold break at the waist and a hem that swings with the stride, the
burn on the neck under the ear, a soft felt hat with a drooping brim, the snuffer's bell turned down over the glass);
the pole of each pose is a clean pixel line between two hand-picked points, and the arms that hold it run from the
shoulders to the pole, so the hands always sit on it. Both are written out as parts like any other (one full-frame
layer each)."""
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


def pole(butt, tip, flame=True, snuffer=False):
    """The pole from its butt to its tip: plain wood, a lit run broken every third pixel by its shade. Lighting: the
    brass wick holder one before the tip, the small closed snuffer at the very tip, the wick's flame (glow only) beside
    the holder. Snuffing: the pole ends in its bell, turned mouth down: a lit crown beside the tip and a three-pixel
    rim under it (the lit side `e`, the shaded side `f`), so it reads apart from the wick."""
    pts = line(*butt, *tip)
    cells = {}
    n = len(pts)
    for i, p in enumerate(pts):
        if snuffer:
            cells[p] = "h" if i % 3 == 2 else "l"
        else:
            cells[p] = "e" if i == n - 1 else ("c" if i == n - 2 else ("h" if i % 3 == 2 else "l"))
    flame_at = None
    if snuffer:
        tx, ty = tip
        cells[(tx + 1, ty)] = "e"
        cells[(tx, ty + 1)] = "e"
        cells[(tx + 1, ty + 1)] = "f"
        cells[(tx + 2, ty + 1)] = "f"
    elif flame:
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
# pole raised to a lantern 6 and the wick at its glass 7, the snuffer's bell raised over the lantern 8 and lowered onto
# it 9, at the hearth the wick held into the Flame 10 and the head bowed to it 11 (docs/SPRITES-people.md; people-2,
# `TownLamps`). Silas Moth, 63, the lamplighter (docs/PEOPLE.md "Three more"; docs/TOWN.md section 7): a townsman who
# carries the house's light out into the street each dusk. Tall and thin as his pole and stooped from forty years of
# reaching up: the head and the shoulders a pixel forward of the hips, a rounded upper back; a soft felt hat whose brim
# droops over the brow; grey hair at the nape, a long thin face with a long nose; the old burn on the side
# of his neck under the ear from a lantern that burst in his hands (`dusk`, off the mouth line); a long dark coat to the
# shins, narrow at the shoulders and flaring to the hem, gathered at the waist by a cord (the fold break), its hem
# swinging a pixel with the stride; a soot-black thumb, dark breeches, worn boots. The pole, longer than he is tall, of
# plain wood with a brass wick holder and a small snuffer bell at its tip (`straw`, `stoneLight`, `stone`): never the
# lord's hooked staff with its lantern. His feet stand on the frame's middle (column 18); the pole reaches out behind
# him or ahead. Light from the upper left; look 2's selective outline (the pole without one). Walk: a long stride (4 px
# a frame), the pole in the near hand, its tip up behind him; the body a pixel higher on the passing frames, where the
# hem hangs straight; on the contacts it swings out. Idle: the pole upright at his side, a breath. Lighting: both hands
# on the pole, its tip raised to the glass of a lantern 15 px ahead of his feet at a height of 20. Snuffing: the pole
# steeper and higher, the bell above the lantern's cap (8), then down over it (9). The hearth: the tip held low ahead
# into the fire, then his head bowed to it. The glow strip carries the wick's flame; the engine draws it only while the
# wick burns (`TownLamps.pose`). Written by tools/lamplighterpoles.py: the parts are hand-set there, the poles are clean
# lines between hand-picked points and the arms run from the shoulders to the pole; this file is the source the build
# reads.
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
    w = soilLight
    N = stone
    M = stoneMid
    K = stoneDark
    l = woodLight!
    h = wood!
    c = straw!
    e = stoneLight!
    f = stone!
    * = /fireGold

# the soft felt hat: a slumped crown lit on top, the brim flat at the back and drooping two pixels over the brow
part hat
    ..wddd...
    .ddddDd..
    ddddddDDD
    .......DD

# the long thin face in profile, a pixel forward of the shoulders (the stoop): grey hair at the nape, the eye, the long
# nose, the jaw; the old burn on the side of the neck under the ear, well behind the mouth
part head
    PSSSS.
    PSSSkS
    PSSSSs
    .rSSS.
    .rS...

# the head bowed to the Flame: the face turned down, the nose lower, the burn still under the ear
part headBowed
    PSSSS.
    PSSSS.
    PSSSkS
    .rSSSs
    .rS...

# the long dark coat from the hunched shoulders to the waist: a rounded upper back (lit), the chest forward, two pale
# horn buttons on the front edge, the waist gathered by a cord (the silhouette steps in, the cloth creases)
part coat
    ..PN....
    .PNNMMK.
    .NNMMMMK
    .NMMMMKK
    .NMMMMbK
    .NMMMKK.
    .NMMMMbK
    ..NKKMK.
    .NNMMKMK

# the skirt from below the cord to the shins, flaring; the fold from the waist runs on down and forward. Standing:
part hemStand
    .NMMMMKMK.
    .NMMMMMKK.
    NNMKMMMMK.
    NMMKMMMKK.
    .NNMMMMKK.

# the walk's first contact: the stride open, the hem swung out behind and ahead
part hemSwingA
    .NMMMMKMK.
    .NMMMMMKK.
    NNMKMMMMKK
    NMMKMMMMKK
    NNNMMMMMKK

# the second contact: the other leg ahead, the hem's front kicked a pixel further
part hemSwingB
    .NMMMMKMK.
    .NMMMMMKK.
    .NMKMMMMKK
    NNMKMMMMKK
    NMMMMMMKKK

# the passing frames: the legs together, the hem hanging straight and narrow
part hemPass
    .NMMMMKMK.
    .NMMMMMKK.
    .NMKMMMMK.
    .NMKMMMKK.
    ..NMMMMK..

# the far arm hanging at his back (the walk, the idle)
part armBack
    N
    M
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
    # (frame, butt, tip, flame, snuffer, near hand target, far hand target or None, body lift, bowed)
    poses = {
        0: ((24, 20), (4, 0), True, False, (21, 17), None, 0, False),
        1: ((24, 19), (4, 0), True, False, (21, 16), None, -1, False),
        4: ((24, 29), (24, 0), True, False, (24, 17), None, 0, False),
        5: ((24, 29), (24, 0), True, False, (24, 18), None, 1, False),
        6: ((12, 29), (31, 11), True, False, (25, 18), (21, 21), 0, False),
        7: ((14, 28), (33, 9), True, False, (26, 17), (22, 21), 0, False),
        8: ((13, 29), (30, 3), False, True, (24, 15), (20, 21), 0, False),
        9: ((15, 29), (31, 6), False, True, (25, 16), (21, 22), 0, False),
        10: ((13, 14), (33, 24), True, False, (24, 19), (20, 17), 0, False),
        11: ((13, 14), (33, 24), True, False, (24, 19), (20, 17), 0, True),
    }
    legs = {0: ("legsContactA", 13, 26), 1: ("legsPass", 15, 25)}
    hems = {0: "hemSwingA", 1: "hemPass"}
    text = HEADER
    frames = []
    tips = {}
    for n, (butt, tip, flame, snuffer, near, far, lift, bowed) in sorted(poses.items()):
        pts, cells, flame_at = pole(butt, tip, flame, snuffer)
        hand = nearest(pts, near)
        shoulder = (20, 14 + lift)
        front = arm(shoulder, hand)
        back = {}
        if far is not None:
            fhand = nearest(pts, far)
            back = arm((18, 15 + lift), fhand)
        if n in (4, 5):
            front[(hand[0], hand[1] + 1)] = "k"  # the soot-black thumb under the grip
        text += f"\npart pole{n}\n" + "\n".join("    " + r for r in layer(cells)) + "\n"
        text += f"\npart armNear{n}\n" + "\n".join("    " + r for r in layer(front)) + "\n"
        if back:
            text += f"\npart armFar{n}\n" + "\n".join("    " + r for r in layer(back)) + "\n"
        tips[n] = flame_at
        leg = legs.get(n, ("legsStand", 15, 26))
        place = []
        if back:
            place.append((f"armFar{n}", 0, 0))
        else:
            place.append(("armBack", 15, 16 + lift))
        place.append(leg)
        place.append((hems.get(n, "hemStand"), 14, 21 + lift))
        place.append(("coat", 15, 12 + lift))
        if bowed:
            place += [("hat", 18, 6 + lift), ("headBowed", 19, 9 + lift)]
        else:
            place += [("hat", 17, 5 + lift), ("head", 18, 8 + lift)]
        place += [(f"pole{n}", 0, 0), (f"armNear{n}", 0, 0)]
        frames.append((n, place))
    # frame 2: the walk's other contact (the far leg ahead), the pole and arms of frame 0
    frames.append((2, [("armBack", 15, 16), ("legsContactB", 13, 26), ("hemSwingB", 14, 21), ("coat", 15, 12),
                       ("hat", 17, 5), ("head", 18, 8), ("pole0", 0, 0), ("armNear0", 0, 0)]))
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
