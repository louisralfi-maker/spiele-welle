"""Bakes the castle's cast shadows (scene polish 2) from the world as layout_m1b.py places it.

The sun lights the castle front from the upper left by day and from low in the west at dusk, so the front and its
towers throw their shadow to the right: onto the throat rock right of the right tower, onto the ground strip at the
foot of the walls, and (the left tower) onto the gatehouse wall beside it. A shadow is the caster's silhouette swept
along the light (every offset from 0 to the light's full offset, as a solid tower throws it onto the rock behind),
kept only on the receivers (rock and ground; the gatehouse wall for the left tower). Each place gets two sprites:
the day shadow (offset `DAY`) and the long dusk shadow minus the day one (offset `DUSK`); the scene draws the first
with the sun's strength and the second with the sun's strength times the evening weight, so they never darken a pixel
twice (`FrameBuilder.sunShadowAlpha`, mock.py `shadow_alpha`).

Every shadow pixel lies on an opaque receiver pixel drawn before it, so a plain over-blend of black at the shadow's
alpha darkens only what it should (never the sky): the renderer needs no new blend mode. The boxes come from
layout_m1b.SHADOWS (sprite size and bottom-left); the bake fails when a shadow does not fit its box.

Usage (from anywhere): python3 -I tools/scenemock/bake_shadows.py [--out <dir>] [--check]
  --check  only prints the shadow boxes the current layout needs (no files written)
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, '..'))
import layout_m1b as L  # noqa: E402
from pixelart import Image, read_png, write_png  # noqa: E402

G = os.path.normpath(os.path.join(HERE, '..', '..'))
ART = os.path.join(G, 'Resources', 'Art')

# Light offsets in game pixels: right (+x) and down (+rows). By day the sun stands high in the upper left; at dusk it
# is low in the west and the shadow reaches far to the right and barely down.
DAY = dict(rock=(10, 8), ground=(10, 6), gate=(9, 6))
DUSK = dict(rock=(90, 4), ground=(90, 3), gate=(30, 2))
ROCK = {'cliffFlank', 'cliffFlankB', 'throatRock'}
RIGHT_TOWER_X = 1413  # the front's right tower starts at sprite column 173
SHADOW_COLOUR = (0x0E, 0x0B, 0x1E, 255)  # night0; the scene tints it black, the colour only keeps to the palette

# The canvas: world x X0 ..< X1, rows from TOP (245 px above the ground line) down to the bottom of the ground strip.
X0, X1 = 1100, 1640
TOP = 245
ROWS = TOP + 26
FULL = (1 << (X1 - X0)) - 1


def mask_of(name, flip=False):
    img, _ = read_png(os.path.join(ART, name + '.png'))
    rows = []
    for y in range(img.h):
        bits = 0
        for x in range(img.w):
            if img.get(img.w - 1 - x if flip else x, y)[3]:
                bits |= 1 << x
        rows.append(bits)
    return img.w, img.h, rows


def place(rows_out, mask, x, y):
    """ORs a sprite mask into canvas rows at world bottom-left (x, y)."""
    w, h, rows = mask
    shift = x - X0
    for j, bits in enumerate(rows):
        r = TOP - y - h + j
        if 0 <= r < ROWS and bits:
            rows_out[r] |= (bits << shift if shift >= 0 else bits >> -shift) & FULL


def sweep(rows, dx, dy):
    """Every offset t * (dx, dy), t from 0 to 1, ORed (whole pixels along the longer axis)."""
    steps = max(abs(dx), abs(dy), 1)
    out = [0] * ROWS
    for k in range(steps + 1):
        ox = round(dx * k / steps)
        oy = round(dy * k / steps)
        for r in range(ROWS):
            src = r - oy
            if 0 <= src < ROWS and rows[src]:
                out[r] |= rows[src] << ox
    return [v & FULL for v in out]


def world_layers():
    """The receivers before the castle front (rock and ground that are the topmost pixel), the front's mask, the left
    tower and the gatehouse wall (the front between its towers)."""
    world = [d for d in L.instances() if d['p'] == 'world']
    order = sorted(range(len(world)), key=lambda i: (world[i]['z'], i))
    rock = [0] * ROWS
    other = [0] * ROWS
    front = None
    for i in order:
        d = world[i]
        if d['s'] == 'castleFront':
            front = d
            break
        if d['s'] in L.SHADOW_SPRITES:
            continue
        m = [0] * ROWS
        place(m, mask_of(d['s'], d['f']), d['x'], d['y'])
        if not any(m):
            continue
        for r in range(ROWS):
            if d['s'] in ROCK:
                rock[r] |= m[r]
                other[r] &= ~m[r]
            else:
                other[r] |= m[r]
                rock[r] &= ~m[r]
    ground = [0] * ROWS
    for r in range(TOP, ROWS):
        ground[r] = FULL & ~rock[r] & ~other[r]
    fmask = mask_of('castleFront')
    caster = [0] * ROWS
    place(caster, fmask, front['x'], front['y'])
    # The left tower (sprite columns 0 to 57) and the gatehouse wall between the towers (58 to 173).
    w, h, rows = fmask
    left = (w, h, [bits & ((1 << 58) - 1) for bits in rows])
    gate = (w, h, [bits & (((1 << 174) - 1) ^ ((1 << 58) - 1)) for bits in rows])
    tower = [0] * ROWS
    wall = [0] * ROWS
    place(tower, left, front['x'], front['y'])
    place(wall, gate, front['x'], front['y'])
    return rock, ground, caster, tower, wall


def filled(rows):
    """Each row's span from its first to its last set pixel (the castle's own outline, holes and gaps closed)."""
    out = []
    for bits in rows:
        if not bits:
            out.append(0)
            continue
        low = (bits & -bits).bit_length() - 1
        high = bits.bit_length()
        out.append(((1 << high) - 1) ^ ((1 << low) - 1))
    return out


def shadows():
    rock, ground, caster, tower, wall = world_layers()
    inside = filled(caster)
    out = {}
    for name, rec, cast, key in (('castle', rock, caster, 'rock'), ('ground', ground, caster, 'ground'),
                                 ('gate', wall, tower, 'gate')):
        day = sweep(cast, *DAY[key])
        dusk = sweep(cast, *DUSK[key])
        # Rock behind the castle shows only right of it (holes in the front's outline and the notches of the left
        # tower's rubble are no shadow anyone sees): the rock shadow starts at the right tower.
        right = FULL ^ ((1 << (RIGHT_TOWER_X - X0)) - 1)
        keep = [rec[r] & ~cast[r] & ((~inside[r] & right) if key == 'rock' else FULL) for r in range(ROWS)]
        base = [day[r] & keep[r] for r in range(ROWS)]
        long = [dusk[r] & keep[r] & ~base[r] for r in range(ROWS)]
        out[name + 'Shadow'] = base
        out[name + 'ShadowLong'] = long
    return out


def bbox(rows):
    xs = [x for r in rows if r for x in range(X1 - X0) if r >> x & 1]
    rs = [i for i, r in enumerate(rows) if r]
    if not xs:
        return None
    x0, x1 = min(xs), max(xs) + 1
    r0, r1 = min(rs), max(rs) + 1
    return X0 + x0, TOP - r1, x1 - x0, r1 - r0  # world x, y (bottom above the ground line), width, height


def main():
    out_dir = ART
    check = '--check' in sys.argv
    if '--out' in sys.argv:
        out_dir = sys.argv[sys.argv.index('--out') + 1]
    boxes = {d['s']: d for d in L.SHADOWS}
    ok = True
    for name, rows in shadows().items():
        box = bbox(rows)
        print(f"{name}: needs x={box[0]} y={box[1]} {box[2]}x{box[3]}" if box else f"{name}: empty")
        if check or box is None:
            continue
        d = boxes.get(name)
        if d is None:
            print(f"  layout_m1b.SHADOWS has no {name}")
            ok = False
            continue
        w, h = d['w'], d['h']
        if box[0] < d['x'] or box[1] < d['y'] or box[0] + box[2] > d['x'] + w or box[1] + box[3] > d['y'] + h:
            print(f"  does not fit its box x={d['x']} y={d['y']} {w}x{h}")
            ok = False
            continue
        img = Image(w, h)
        for j in range(h):
            r = TOP - d['y'] - h + j
            bits = rows[r] if 0 <= r < ROWS else 0
            for i in range(w):
                c = d['x'] - X0 + i
                if 0 <= c < X1 - X0 and bits >> c & 1:
                    img.set(i, j, SHADOW_COLOUR)
        write_png(os.path.join(out_dir, name + '.png'), img)
        print(f"  wrote {name}.png {w}x{h}")
    if not ok:
        sys.exit(1)


if __name__ == '__main__':
    main()
