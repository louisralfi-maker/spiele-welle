"""Writes tools/grids/people/coach.txt: the noble's coach (people-2), laid out piece by piece on its 60x34 canvas with
deliberate shapes (the body's panels and belly, the wheels as clean pixel circles with their spokes, the shafts as a
clean line), then written out as one part. The grid is the source the build reads (tools/build-art-people.sh)."""
import sys

W, H = 60, 34
grid = [["." for _ in range(W)] for _ in range(H)]


def put(x, y, c):
    if 0 <= x < W and 0 <= y < H:
        grid[y][x] = c


def rect(x0, y0, x1, y1, c):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            put(x, y, c)


def line(x0, y0, x1, y1, c, lit=None):
    dx, dy = abs(x1 - x0), -abs(y1 - y0)
    sx = 1 if x1 > x0 else -1
    sy = 1 if y1 > y0 else -1
    err = dx + dy
    x, y = x0, y0
    i = 0
    while True:
        put(x, y, lit if lit and i % 2 == 0 else c)
        if x == x1 and y == y1:
            break
        e2 = 2 * err
        if e2 >= dy:
            err += dy
            x += sx
        if e2 <= dx:
            err += dx
            y += sy
        i += 1


def circle_pts(cx, cy, r):
    """A clean midpoint circle."""
    pts = set()
    x, y, d = r, 0, 1 - r
    while x >= y:
        for a, b in ((x, y), (y, x), (-y, x), (-x, y), (-x, -y), (-y, -x), (y, -x), (x, -y)):
            pts.add((cx + a, cy + b))
        y += 1
        if d < 0:
            d += 2 * y + 1
        else:
            x -= 1
            d += 2 * (y - x) + 1
    return pts


def wheel(cx, cy, r):
    """An iron tyre (lit on its upper left), crimson spokes, a gold hub."""
    for (x, y) in circle_pts(cx, cy, r):
        lit = (x - cx) + (y - cy) < -r * 0.6
        put(x, y, "N" if lit else "K")
    for (x, y) in circle_pts(cx, cy, r - 1):
        if grid[y][x] == ".":
            put(x, y, "C")
    spokes = [(1, 0), (-1, 0), (0, 1), (0, -1)] + ([(1, 1), (-1, -1), (1, -1), (-1, 1)] if r >= 6 else [])
    for (ux, uy) in spokes:
        for k in range(2, r - 1):
            if ux and uy and k > r - 3:
                continue
            put(cx + ux * k, cy + uy * k, "r")
    rect(cx - 1, cy - 1, cx, cy, "g")
    put(cx, cy, "G")


# --- the trunk on the roof and the roof's rail ---
rect(13, 1, 27, 4, "h")
rect(13, 1, 27, 1, "l")
rect(13, 4, 27, 4, "H")
for x in (17, 23):
    rect(x, 1, x, 4, "M")
put(13, 2, "l")
put(13, 3, "l")
for x in range(8, 40):
    if not 13 <= x <= 27:
        put(x, 3, "G")
for x in (8, 11, 30, 34, 39):
    put(x, 4, "G")
# --- the roof: a lit slab and its dark overhang ---
rect(6, 5, 40, 5, "c")
rect(5, 6, 41, 6, "C")
put(5, 6, "c")
# --- the body: the upper panels and the belly curving under ---
belly = {16: (7, 38), 17: (8, 37), 18: (9, 36), 19: (10, 35), 20: (12, 33), 21: (14, 31)}
rect(6, 7, 39, 15, "r")
for y, (a, b) in belly.items():
    rect(a, y, b, y, "r")
# light from the upper left: the top and the left edge lit, the right edge and the belly's underside in shade
rect(7, 7, 38, 7, "u")
rect(6, 7, 6, 15, "u")
rect(39, 8, 39, 15, "C")
for y, (a, b) in belly.items():
    put(a, y, "u" if y < 18 else "r")
    put(b, y, "C")
rect(14, 21, 31, 21, "C")
rect(12, 20, 33, 20, "C")
put(12, 20, "r")
# the gold belt moulding and the panels' frames
rect(7, 15, 38, 15, "g")
put(38, 15, "G")
# the door: dark seams with a gold edge, the window with the curtain drawn, the gold sheaf of Goldenacre below
for x in (18, 28):
    rect(x, 8, x, 20, "C")
rect(19, 8, 27, 8, "g")
rect(19, 9, 19, 14, "g")
rect(27, 9, 27, 14, "G")
rect(20, 14, 26, 14, "G")
for x in range(20, 27):
    for y in range(9, 14):
        put(x, y, "p" if (x - 20) % 3 == 0 else "P")
rect(20, 9, 26, 9, "Q")
# the sheaf: stalks fanned at the top, the band, the ends
for (x, y) in ((23, 16), (22, 17), (23, 17), (24, 17), (23, 18), (22, 19), (24, 19)):
    put(x, y, "g")
put(23, 18, "G")
# the quarter windows, curtains drawn
for (a, b) in ((9, 15), (31, 37)):
    rect(a - 1, 8, b + 1, 8, "g")
    rect(a - 1, 9, a - 1, 13, "g")
    rect(b + 1, 9, b + 1, 13, "G")
    rect(a, 13, b, 13, "G")
    for x in range(a, b + 1):
        for y in range(9, 13):
            put(x, y, "p" if (x - a) % 3 == 0 else "P")
    rect(a, 9, b, 9, "Q")
# the iron step under the door
rect(22, 22, 25, 22, "M")
put(22, 22, "N")
# --- the coachman's box at the front, empty: the backrest, the crimson cushion, the box, the slanted footboard ---
rect(40, 9, 41, 12, "H")
put(40, 9, "h")
rect(42, 11, 47, 11, "u")
rect(42, 12, 47, 12, "r")
rect(41, 13, 48, 16, "H")
rect(41, 13, 48, 13, "h")
line(48, 16, 52, 19, "H", lit="h")
# the brass lantern on its bracket at the body's front corner (unlit by day)
put(40, 7, "G")
rect(40, 8, 41, 8, "G")
put(41, 6, "g")
rect(41, 7, 42, 7, "g")
put(42, 8, "b")
# --- the undercarriage: the perch between the axles and the iron springs ---
rect(18, 24, 42, 24, "H")
rect(18, 23, 42, 23, "h")
for (x, y) in ((19, 22), (20, 21), (21, 21), (22, 22)):
    put(x, y, "M")
for (x, y) in ((37, 22), (38, 21), (39, 21), (40, 22)):
    put(x, y, "M")
# --- the shafts, down on the lane ahead (the horses are in the tavern's stable) ---
line(47, 26, 59, 32, "h", lit="l")
put(59, 33, "H")
put(58, 33, "H")
# --- the wheels last: the big rear one and the smaller front one ---
wheel(14, 26, 7)
wheel(44, 28, 5)

HEADER = """# coach 60x34, 1 frame (docs/SPRITES-people.md; people-2, `TownDay.props`). The travelling coach of a noble guest of the
# inner lands (docs/PEOPLE.md section 4), at rest at the town's gate on the day the guest is due, the footman beside it:
# the most foreign object in the valley, Oxmoor's crimson (lit in `dusk`: the bright warm red belongs to the
# children) with gold mouldings and the gold sheaf of Goldenacre on the door, the curtains of all three windows drawn
# (plum), a trunk on the roof inside a gilt rail, the empty coachman's box with its crimson cushion and a brass lantern
# at the front, iron springs on a dark perch, crimson wheels with iron tyres and gold hubs, the shafts down on the lane
# (the horses are in the tavern's stable). It faces right as drawn; the town's gate is on its left, so it stands
# mirrored. A prop: its left edge on its x. Light from the upper left; look 2's selective outline. Laid out by
# tools/coachgrid.py (clean circles and lines, deliberate panels); this file is the source the build reads.
id coach
size 60x34
frames 1
outline ink shade

legend
    k = ink
    u = dusk
    r = crimson
    c = crimson
    C = crimsonDeep
    g = gold
    G = straw
    P = plum
    p = plumLight
    Q = plumDeep
    l = woodLight
    h = wood
    H = woodDark
    M = stoneMid
    N = stone
    K = stoneDark
    b = foam

part coach
"""


def main(path):
    text = HEADER + "".join("    " + "".join(row) + "\n" for row in grid) + "\nframe 0\n    coach 0 0\n"
    with open(path, "w") as fh:
        fh.write(text)


if __name__ == "__main__":
    main(sys.argv[1])
