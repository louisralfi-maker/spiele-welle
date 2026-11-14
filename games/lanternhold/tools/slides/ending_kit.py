"""Shared pieces for the endings' lantern slides (panels-2, docs/lanes/panels.md): skies in uneven bands that bend
around their light (never ruled straight across), halos in flat rings, silhouettes rim-lit from the light behind them,
fog banks with ragged lit tops, rock masses with a lit and a shadow face. Everything lands on the palette in the
slide's own `finish`.
"""
import math

from paint import P, W, H, fbm, h1, h2, noise1, step, mix
from figure import Layer


def banded_sky(c, light, stops, y0=0, y1=H - 1, squash=1.0, wobble=2.0, seed=0, mask=None):
    """A sky in flat bands of palette colours. A pixel's band follows its distance from `light` (x, y) along a soft
    curve (`squash` flattens it toward the horizon) plus a low wobble, so band edges bend and undulate instead of
    running as ruled lines. stops: [(distance, colour name), ...] near to far; past the last stop the last colour."""
    lx, ly = light
    for y in range(max(0, y0), min(H, y1 + 1)):
        for x in range(W):
            if mask and not mask(x, y):
                continue
            d = math.hypot(x + 0.5 - lx, (y + 0.5 - ly) / squash)
            d += (fbm(x * 0.018, y * 0.05, seed, 2) - 0.5) * 2 * wobble
            col = stops[-1][1]
            for dist, name in stops:
                if d < dist:
                    col = name
                    break
            c.c[y][x] = P(col)


def halo_rings(c, cx, cy, rings, mask=None, squash=1.0):
    """Flat rings of light around a source, lifting what is painted one palette step per ring (rings: [(radius,
    steps), ...] inner first)."""
    for y in range(int(cy - rings[-1][0] - 1), int(cy + rings[-1][0] + 2)):
        for x in range(int(cx - rings[-1][0] - 1), int(cx + rings[-1][0] + 2)):
            if not (0 <= x < W and 0 <= y < H):
                continue
            if mask and not mask(x, y):
                continue
            d = math.hypot(x + 0.5 - cx, (y + 0.5 - cy) / squash)
            for r, k in rings:
                if d < r:
                    c.c[y][x] = step(c.c[y][x], k)
                    break


def rim_light(layer, light, colour_near, colour_far=None, reach=60, sky=None, width=1):
    """Lights a silhouette's edge that faces `light` (a point behind it): every figure pixel with an empty neighbour
    on the light's side takes the rim colour (near the light the bright one). `width` 2 adds a second, darker row."""
    lx, ly = light
    src = dict(layer.px)
    for (x, y), col in src.items():
        dx = lx - x
        dy = ly - y
        n = math.hypot(dx, dy) or 1.0
        sx = int(round(dx / n))
        sy = int(round(dy / n))
        sides = {(sx, 0), (0, sy), (sx, sy)} - {(0, 0)}
        open_side = any((x + ax, y + ay) not in src for ax, ay in sides)
        if not open_side:
            if width > 1:
                inner = any((x + 2 * ax, y + 2 * ay) not in src for ax, ay in sides)
                if inner and colour_far is not None:
                    layer.px[(x, y)] = P(colour_far) if isinstance(colour_far, str) else colour_far
            continue
        d = math.hypot(x - lx, y - ly)
        name = colour_near if (colour_far is None or d < reach) else colour_far
        layer.px[(x, y)] = P(name) if isinstance(name, str) else name


def ragged_top(x0, x1, base, height, seed, freq=0.05, lumps=3):
    """The top line of a fog bank or a heap: a base height with lumps (rounded billows) and noise."""
    top = {}
    for x in range(x0, x1):
        t = (x - x0) / max(1.0, float(x1 - x0))
        env = math.sin(t * math.pi) ** 0.6
        billow = 0.0
        for k in range(lumps):
            f = freq * (1.7 ** k)
            billow += abs(math.sin(x * f + h1(k, seed) * 6.28)) * (0.6 ** k)
        top[x] = base - height * env * (0.55 + 0.45 * billow / 1.6) - (fbm(x * 0.07, 0.3, seed, 2) - 0.5) * 3
    return top


def fog_bank(c, x0, x1, base, height, seed, lit, body, shade, bottom=None, lit_rows=1.5):
    """A bank of fog: a lit top edge (`lit`, about `lit_rows` thick), a body, and its lower part a step darker."""
    top = ragged_top(x0, x1, base, height, seed)
    bottom = H - 1 if bottom is None else bottom
    for x in range(max(0, x0), min(W, x1)):
        t = top[x]
        for y in range(max(0, int(math.ceil(t))), min(H, bottom + 1)):
            depth = y - t
            if depth < lit_rows:
                col = lit
            elif depth < (base - t) * 0.6 + 3:
                col = body
            else:
                col = shade
            c.c[y][x] = P(col)
    return top


def rock_mass(c, pts, lit_side, base="rockDeep", lit="rockDark", edge="rock", seed=0, cracks=3):
    """A rock mass: one polygon in its shadow colour, the faces turned to the light a step up (split along a ridge
    line through the mass), a lit edge on the outline toward the light, and a few cracks (short dark lines)."""
    lay = Layer()
    lay.poly(pts, P(base))
    xs = [p[0] for p in pts]
    ys = [p[1] for p in pts]
    cx = (min(xs) + max(xs)) / 2.0
    lx, ly = lit_side
    for (x, y) in list(lay.px):
        # a ridge that wanders: the half toward the light is lit
        ridge = cx + (fbm(y * 0.08, x * 0.01, seed, 2) - 0.5) * (max(xs) - min(xs)) * 0.5
        toward = (x < ridge) if lx < cx else (x > ridge)
        if toward:
            lay.px[(x, y)] = P(lit)
    # the outline toward the light
    for (x, y) in list(lay.px):
        sx = -1 if lx < x else 1
        sy = -1 if ly < y else 1
        if (x + sx, y) not in lay.px or (x, y + sy) not in lay.px:
            if lay.px[(x, y)] == P(lit):
                lay.px[(x, y)] = P(edge)
    # cracks
    for k in range(cracks):
        px = min(xs) + h1(k, seed + 3) * (max(xs) - min(xs))
        py = min(ys) + h1(k, seed + 5) * (max(ys) - min(ys))
        ln = 3 + int(h1(k, seed + 7) * 6)
        for i in range(ln):
            X = int(px + i * (0.3 if h1(k, seed + 9) > 0.5 else -0.3))
            Y = int(py + i)
            if (X, Y) in lay.px:
                lay.px[(X, Y)] = step(lay.px[(X, Y)], -1)
    lay.paste(c)
    return lay


def snow_flakes(c, n, seed, colour="mistLight", y_max=H, avoid=None, bright="foam"):
    for i in range(n):
        x = int(h1(i, seed) * W)
        y = int(h1(i, seed + 1) * y_max)
        if avoid and avoid(x, y):
            continue
        c.c[y][x] = P(bright) if h1(i, seed + 2) > 0.75 else P(colour)


def cluster(c, x, y, pattern, legend):
    """A tiny hand-set cluster (a few rows of characters) at x, y."""
    for j, line in enumerate(pattern):
        for i, ch in enumerate(line):
            if ch in " .":
                continue
            X, Y = x + i, y + j
            if 0 <= X < W and 0 <= Y < H:
                c.c[Y][X] = P(legend[ch]) if isinstance(legend[ch], str) else legend[ch]


def dawn_sky(c, sun, stops, y0, y1, dip=26.0, dip_width=70.0, wobble=2.0, seed=0, mask=None):
    """A low-sun sky in horizontal bands: a pixel's band is its height above the sun, lowered near the sun by a bump
    (`dip` rows at the sun, fading out over `dip_width`), with a low wobble, so the bands lie flat across the sky and
    bow only around the light. stops: [(height, colour name), ...] low to high."""
    sx, sy = sun
    for y in range(max(0, y0), min(H, y1 + 1)):
        for x in range(W):
            if mask and not mask(x, y):
                continue
            dx = x + 0.5 - sx
            v = (sy - y) + dip * (1 - math.exp(-(dx / dip_width) ** 2)) + abs(dx) * 0.04
            v += (fbm(x * 0.008, y * 0.035, seed, 3) - 0.5) * 2 * wobble
            v += (fbm(x * 0.05, y * 0.2, seed + 7, 2) - 0.5) * 1.2
            col = stops[-1][1]
            for hgt, name in stops:
                if v < hgt:
                    col = name
                    break
            c.c[y][x] = P(col)


def cloud_wisp(c, x0, x1, y0, thick, seed, colour_fn, stretch=1.0):
    """A clumpy wisp of cloud: a row of overlapping lumps of uneven size along a slightly wavy line, thin at its ends
    and with gaps; colour_fn(x, y, top, bottom) paints each pixel (the belly lit, the top dark)."""
    x = x0
    k = 0
    while x < x1:
        t = (x - x0) / float(max(1, x1 - x0))
        env = math.sin(t * math.pi) ** 0.7
        r = thick * env * (0.5 + 0.8 * h1(k, seed)) / (stretch ** 0.5)
        w = (7 + h1(k, seed + 1) * 15) * stretch
        cy = y0 + math.sin(x * 0.03 + seed) * 1.5 + (h1(k, seed + 2) - 0.5) * 2
        if r >= 0.9 and h1(k, seed + 3) > 0.12:
            for yy in range(int(cy - r), int(cy + r * 0.55) + 1):
                for xx in range(int(x - w / 2), int(x + w / 2) + 1):
                    if not (0 <= xx < W and 0 <= yy < H):
                        continue
                    ex = (xx + 0.5 - x) / (w / 2)
                    ey = (yy + 0.5 - cy) / (r if yy < cy else r * 0.55)
                    if ex * ex + ey * ey <= 1:
                        c.c[yy][xx] = colour_fn(xx, yy, cy - r, cy + r * 0.55)
        x += w * (0.3 + 0.25 * h1(k, seed + 4))
        k += 1


def person(lay, x, feet, height, colour, shoulders=1.0, hips=1.0, head=1.0, stoop=0.0, arms="down", robe=False,
           robe_hem=1.0, legs_apart=1.0):
    """A person seen from behind (or in silhouette), drawn into `lay` in one colour: head, a short neck, sloping
    shoulders, a torso narrowing to the waist, arms clear of the body so the sky shows between (the thing that makes a
    silhouette read as a person), and legs with a gap, or a robe to the ground. `stoop` moves the head down and forward
    (in pixels); arms: "down", "akimbo" (hands on the hips), "hold" (forearms forward, hands together), "none".
    Returns the useful points: head centre, the two hands, the two shoulders."""
    c = colour
    hh = height * 0.155 * head
    hw = hh * 0.44
    top = feet - height
    hx, hy = x + stoop * 0.4, top + hh * 0.5 + stoop
    sh_y = top + hh + 1.0 + stoop * 0.6
    sw = height * 0.165 * shoulders
    waist_y = feet - height * 0.47
    ww = height * 0.105 * hips
    hip_y = feet - height * 0.40
    hipw = height * 0.12 * hips
    # head and neck
    lay.ellipse(hx, hy, hw + 0.4, hh * 0.52, c)
    lay.capsule((hx, hy + hh * 0.3), (x, sh_y + 1), hw * 0.55, hw * 0.6, c)
    # torso: sloping shoulders down to the waist and out to the hips
    lay.poly([(x - sw * 0.35, sh_y - 0.5), (x + sw * 0.35, sh_y - 0.5), (x + sw, sh_y + 2.5), (x + ww, waist_y),
              (x + hipw, hip_y), (x - hipw, hip_y), (x - ww, waist_y), (x - sw, sh_y + 2.5)], c)
    lay.ellipse(x - sw + 1.6, sh_y + 2.4, 1.9, 1.9, c)
    lay.ellipse(x + sw - 1.6, sh_y + 2.4, 1.9, 1.9, c)
    arm_r = max(0.9, height * 0.032)
    elbow_y = waist_y - 0.5
    hand_y = hip_y + height * 0.04
    hands = []
    for side in (-1, 1):
        shoulder = (x + side * (sw - 1.2), sh_y + 2.5)
        if arms == "down":
            elbow = (x + side * (sw + 0.8), elbow_y)
            hand = (x + side * (sw + 0.4), hand_y)
        elif arms == "akimbo":
            elbow = (x + side * (sw + height * 0.12), elbow_y - height * 0.02)
            hand = (x + side * (ww + 0.5), waist_y + 1)
        elif arms == "hold":
            elbow = (x + side * (sw + 0.3), elbow_y)
            hand = (x + side * 1.5, waist_y - 1)
        else:
            continue
        lay.capsule(shoulder, elbow, arm_r + 0.3, arm_r, c)
        lay.capsule(elbow, hand, arm_r, arm_r * 0.85, c)
        hands.append(hand)
    # legs, or a robe to the ground
    if robe:
        hem = hipw * 1.25 * robe_hem
        lay.poly([(x - hipw, hip_y - 1), (x + hipw, hip_y - 1), (x + hem, feet), (x - hem, feet)], c)
    else:
        gap = max(1.0, height * 0.035) * legs_apart
        for side in (-1, 1):
            lay.capsule((x + side * hipw * 0.5, hip_y), (x + side * (hipw * 0.45 + gap), feet - 1),
                        hipw * 0.48, max(0.9, hipw * 0.34), c)
    return {"head": (hx, hy), "top": top, "hands": hands, "shoulders": ((x - sw, sh_y), (x + sw, sh_y)),
            "hip": hip_y, "waist": waist_y}


def strata_rock(c, mask, levels, light_x=1, seed=0, band=(6, 11), block=(7, 22), tilt=0.06, warm=None):
    """A rock face in strata, as a pixel artist draws a cliff: ledges a few rows high, each with a lit top row and a
    shadowed underside, broken into blocks by vertical fissures; the block end toward the light lit, the end away from
    it in shade. mask(x, y) says where the face is; levels: palette names dark to light (five or six); light_x: +1
    the light comes from the right, -1 from the left; warm(x, y) may lift a pixel one level (nearer the light)."""
    n = len(levels)
    for x in range(W):
        for y in range(H):
            if not mask(x, y):
                continue
            off = (fbm(x * 0.02, 0.4, seed, 2) - 0.5) * 8 + x * tilt
            yy = y + off
            # uneven ledges: each band's height from a hash
            k = 0
            top = -40.0
            while True:
                hgt = band[0] + h1(k, seed + 11) * (band[1] - band[0])
                if top + hgt > yy:
                    break
                top += hgt
                k += 1
            p = yy - top
            hgt = band[0] + h1(k, seed + 11) * (band[1] - band[0])
            # blocks along the ledge
            shift = h1(k, seed + 13) * 30
            bx = x + shift
            j = 0
            left = -40.0
            while True:
                bw = block[0] + h1(j + k * 31, seed + 17) * (block[1] - block[0])
                if left + bw > bx:
                    break
                left += bw
                j += 1
            bw = block[0] + h1(j + k * 31, seed + 17) * (block[1] - block[0])
            q = bx - left
            level = 2 + (1 if h2(j, k, seed + 19) > 0.7 else 0) - (1 if h2(j, k, seed + 23) < 0.15 else 0)
            if p < 1.0:
                level = n - 2
            elif p > hgt - 1.6:
                level = 1
            elif p > hgt - 3.0:
                level = min(level, 2) - (1 if p > hgt - 2.3 else 0)
            if q < 1.0:
                level = 0
            elif (light_x > 0 and q > bw - 2.0) or (light_x < 0 and q < 3.0):
                level = min(n - 2, level + 1)
            elif (light_x > 0 and q < 3.0) or (light_x < 0 and q > bw - 2.0):
                level = max(1, level - 1)
            if warm and warm(x, y) and level >= 2:
                level += 1
            c.c[y][x] = P(levels[max(0, min(n - 1, level))])


def cast_shadow(c, lay, base_y, length_per_px, direction=-1, darken=2, ground=None, lift=0.25):
    """A long shadow thrown along the ground by a low light: every pixel of the object at height h above `base_y`
    lands `h * length_per_px` pixels away (direction -1: to the left) and a little up; the ground there goes `darken`
    palette steps down."""
    hit = set()
    for (x, y) in lay.px:
        h = max(0.0, base_y - y)
        for s in range(0, int(h * length_per_px) + 2):
            X = int(round(x + direction * s))
            Y = int(round(base_y - min(h, s / max(0.1, length_per_px)) * lift))
            hit.add((X, Y))
            hit.add((X, Y + 1))
    for (X, Y) in hit:
        if 0 <= X < W and 0 <= Y < H and (ground is None or ground(X, Y)) and (X, Y) not in lay.px:
            c.c[Y][X] = step(c.c[Y][X], -darken)
