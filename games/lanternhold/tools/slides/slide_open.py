"""The Open Lantern (panels-2; STORY.md section 7, "The endings"): the King fell in the beacon's light and Aldric is
free. Its light is the first true dawn the Cleft has seen in years: rose and gold, low, warm.

  slideOpen1        the iron crown on the stone of the outer line; under the black mantle Aldric, grey and breathing
  slideOpen2Lord    the court on the wall at sunrise, seen from behind, the lord in the middle before the sun with the
  slideOpen2Lady    house's lantern raised; a child on a merlon (the leaning and the houses are said under it)
  slideOpen3        west from the Throat's mouth: the fog drawn back past the firs, a ruined castle older than ours on a
                    hill with our lantern cut over its gate; Aldric and the lord small on the road below

Palette art (paint.finish): every light is a palette colour, the soft glow is the stage's.
"""
import math

from paint import P, W, H, Canvas, fbm, fir, h1, h2, step
from figure import Layer
from ending_kit import (banded_sky, cast_shadow, cloud_wisp, cluster, dawn_sky, fog_bank, person, ragged_top,
                        rim_light, rock_mass, strata_rock)

# --- slide 2: the court on the wall at sunrise ---------------------------------------------------------------------

SUN = (160, 100)
PARAPET = 117          # the parapet's coping, beyond the court
WALK = 132             # where the wall walk's floor begins (nearer than the parapet)

O2_ALLOWED = ["night0", "night1", "night2", "nightSlate", "nightHaze", "plumDeep", "plum", "plumLight", "dusk",
              "dawnRose", "tileLight", "tile", "gold", "fireGold", "fireWhite", "fireOrange", "crimsonDeep",
              "woodDark", "ink", "farDeep", "far", "strawLight", "ember"]

# heights above the sun, low to high
SKY_STOPS = [(5, "fireWhite"), (11, "fireGold"), (17, "gold"), (29, "dawnRose"), (39, "dusk"), (57, "plumLight"),
             (70, "plum"), (89, "farDeep"), (101, "nightHaze"), (9999, "nightSlate")]


def sky_open2(c):
    dawn_sky(c, SUN, SKY_STOPS, 0, PARAPET, dip=16, dip_width=46, wobble=4.0, seed=811)

    # high clouds lit pink from below by the sun under the horizon: a lit belly, a rose body, a cooler top
    def tint(x, y, top, bottom, near):
        if y >= bottom - 1.4:
            return P("gold" if near else "dawnRose")
        if y >= bottom - 3.2:
            return P("dawnRose" if near else "dusk")
        if y <= top + 1.2:
            return P("plumLight")
        return P("dusk")
    wisps = [(4, 104, 24, 5.5, 821), (186, 316, 15, 5.0, 823), (78, 182, 40, 4.0, 825), (232, 318, 47, 3.6, 827),
             (128, 200, 9, 3.0, 829)]
    for (x0, x1, y0, th, seed) in wisps:
        near = abs((x0 + x1) / 2 - SUN[0]) < 100 and y0 > 30
        cloud_wisp(c, x0, x1, y0, th, seed, lambda x, y, t, b, n=near: tint(x, y, t, b, n), stretch=2.2)


def land_open2(c):
    for y in range(SUN[1] - 10, SUN[1] + 10):
        for x in range(SUN[0] - 10, SUN[0] + 11):
            if math.hypot(x + 0.5 - SUN[0], y + 0.5 - SUN[1]) < 9.6:
                c.c[y][x] = P("fireWhite")
    # far hills of the Morninglands, backlit, their crests catching the light near the sun
    far = [99 - 4 * fbm(x * 0.02, 0.5, 831, 3) - 2.5 * math.sin(x * 0.013 + 1.0) for x in range(W)]
    near = [106 - 5 * fbm(x * 0.03, 0.9, 833, 3) - 2 * math.sin(x * 0.021) for x in range(W)]
    for x in range(W):
        for y in range(int(far[x]), PARAPET):
            d = abs(x - SUN[0])
            if y < far[x] + 1:
                col = "gold" if d < 18 else "dawnRose" if d < 46 else "dusk" if d < 110 else "plumLight"
            else:
                col = "plumLight" if d < 60 else "plum"
            c.c[y][x] = P(col)
    # morning mist along the valley, lit where the sun stands over it
    for x in range(W):
        top = 103 + 1.5 * math.sin(x * 0.05 + 2.0) + 2 * fbm(x * 0.04, 0.2, 835, 2)
        for y in range(int(top), int(top) + 2):
            d = abs(x - SUN[0])
            c.c[y][x] = P("gold" if d < 22 else "dawnRose" if d < 80 else "dusk")
    for x in range(W):
        for y in range(int(near[x]), PARAPET):
            d = abs(x - SUN[0])
            c.c[y][x] = P("dusk" if (y < near[x] + 1 and d < 60) else "plum" if y < near[x] + 1 else "plumDeep")
    # Tallowford: roofs on the near hill with their ridges catching the sun, a lit window, two chimneys smoking
    roofs = [(34, 5), (42, 4), (49, 6), (58, 4), (250, 5), (259, 6), (268, 4), (276, 5)]
    for (rx, rw) in roofs:
        base = int(near[rx]) + 3
        for k in range(rw + 1):
            hgt = min(k, rw - k)
            for y in range(base - hgt, base + 1):
                c.c[y][rx + k] = P("plumDeep")
            if k <= rw // 2:
                c.c[base - hgt][rx + k] = P("dusk")
        if h1(rx, 837) > 0.45:
            c.c[base - 1][rx + rw // 2] = P("fireOrange")
    for (sx, seed) in ((46, 841), (263, 843)):
        y0 = int(near[sx]) - 2
        for k in range(12):
            x = sx + int(round(math.sin(k * 0.5 + seed) * 1.2 + k * 0.35))
            c.c[y0 - k][x] = P("dusk") if k < 7 else P("plumLight")


def parapet_open2(c):
    """The parapet beyond the court, in its own shadow with its coping catching the sun, and the wall walk's floor
    nearer to us. Two merlons at the right end (the child stands on one)."""
    merlons = [(286, 300), (312, 326)]
    for x in range(W):
        t = PARAPET
        for (a, b) in merlons:
            if a <= x < b:
                t = PARAPET - 12
        for y in range(t, WALK):
            c.c[y][x] = P("plumDeep")
        d = abs(x - SUN[0])
        c.c[t][x] = P("fireGold" if d < 22 else "gold" if d < 60 else "dawnRose" if d < 130 else "dusk")
        c.c[t + 1][x] = P("plum")
    for (a, b) in merlons:
        for y in range(PARAPET - 12, PARAPET):
            c.c[y][a] = P("dusk")
    # a few big stones in the parapet, their joints a step darker (placed, not a grid)
    for (x0, y0, y1) in ((26, 119, 125), (64, 124, 131), (101, 119, 124), (214, 121, 127), (247, 124, 131),
                         (304, 119, 125)):
        for yy in range(y0, y1):
            c.c[yy][x0] = P("night1")
    # the wall walk's floor: worn flags in shadow, a lit seam here and there where the sun gets through
    for y in range(WALK, H):
        for x in range(W):
            c.c[y][x] = P("plumDeep") if y < WALK + 1 else P("night1")
    for k in range(9):
        y = WALK + 3 + int(h1(k, 857) * 24)
        x0 = int(h1(k, 858) * 300)
        for x in range(x0, min(W, x0 + 8 + int(h1(k, 859) * 26))):
            c.c[y][x] = P("plumDeep")


BODY = "night0"


def court(form):
    """The court seen from behind on the wall walk, in two groups and the lord between them before the sun: Hesper
    tall and hooded beside Odile with her ledger; Brannock broad with helmet and spear; the lord with the house's
    lantern raised; Pip sitting on the parapet with his legs over the far side; Tamsin with her hands on her hips
    beside Bram, stooped, the hammer on his shoulder; a child on the merlon, waving at the sun."""
    figs = []
    # Hesper, tall, the hood to a point, the robe to the ground
    lay = Layer()
    pt = person(lay, 52, 146, 50, P(BODY), shoulders=0.9, arms="hold", robe=True, robe_hem=1.1)
    hx, hy = pt["head"]
    lay.poly([(hx, hy - 7), (hx - 4.5, hy + 2), (hx + 4.5, hy + 2)], P(BODY))
    lay.ellipse(hx, hy + 1, 4.4, 4.4, P(BODY))
    figs.append(lay)
    # Odile, narrow and upright, a bun, the ledger under her left arm
    lay = Layer()
    pt = person(lay, 78, 141, 40, P(BODY), shoulders=0.8, hips=0.95, arms="down", robe=True, robe_hem=0.9)
    hx, hy = pt["head"]
    lay.ellipse(hx, hy - 3.6, 1.8, 1.6, P(BODY))
    lay.poly([(70, 112), (74, 111), (75, 121), (71, 122)], P(BODY))
    figs.append(lay)
    # Brannock, broad, the helmet's dome and rim, the spear upright in his right hand
    lay = Layer()
    pt = person(lay, 118, 152, 54, P(BODY), shoulders=1.2, hips=1.05, arms="down", legs_apart=1.6)
    hx, hy = pt["head"]
    lay.ellipse(hx, hy - 0.5, 4.9, 4.4, P(BODY))
    lay.poly([(hx - 6, hy + 1), (hx + 6, hy + 1), (hx + 6, hy + 2), (hx - 6, hy + 2)], P(BODY))
    hand = pt["hands"][1]
    lay.line([(int(hand[0]) + 1, 154), (int(hand[0]) + 1, 70)], P(BODY))
    lay.poly([(hand[0] + 1, 62), (hand[0] + 3, 67), (hand[0] + 1, 71), (hand[0] - 1, 67)], P(BODY))
    figs.append(lay)
    # Pip, small, sitting on the parapet's coping with his back to us, the fool's hood with two drooping horns
    lay = Layer()
    px, seat = 200, PARAPET
    lay.poly([(px - 6, seat - 15), (px + 6, seat - 15), (px + 7, seat + 1), (px - 7, seat + 1)], P(BODY))
    lay.ellipse(px - 5.5, seat - 13, 2.0, 2.0, P(BODY))
    lay.ellipse(px + 5.5, seat - 13, 2.0, 2.0, P(BODY))
    lay.ellipse(px, seat - 19, 3.4, 3.8, P(BODY))
    lay.capsule((px - 2, seat - 21), (px - 7, seat - 22), 1.6, 1.0, P(BODY))
    lay.capsule((px - 7, seat - 22), (px - 9, seat - 18), 1.0, 0.8, P(BODY))
    lay.capsule((px + 2, seat - 21), (px + 7, seat - 23), 1.6, 1.0, P(BODY))
    lay.capsule((px + 7, seat - 23), (px + 10, seat - 19), 1.0, 0.8, P(BODY))
    lay.capsule((px - 6, seat - 12), (px - 9, seat - 3), 1.2, 1.1, P(BODY))
    lay.capsule((px + 6, seat - 12), (px + 9, seat - 3), 1.2, 1.1, P(BODY))
    figs.append(lay)
    bells = [(px - 9, seat - 17), (px + 10, seat - 18)]
    # Tamsin, stout, the headscarf knotted at the nape, hands on her hips
    lay = Layer()
    pt = person(lay, 236, 147, 42, P(BODY), shoulders=1.1, hips=1.35, arms="akimbo", robe=True, robe_hem=1.05)
    hx, hy = pt["head"]
    lay.ellipse(hx, hy - 0.5, 3.9, 3.9, P(BODY))
    lay.poly([(hx - 1, hy + 3), (hx + 2, hy + 6), (hx - 2, hy + 6)], P(BODY))
    figs.append(lay)
    # Bram, stooped, head low between big shoulders, the hammer over his right shoulder
    lay = Layer()
    pt = person(lay, 266, 145, 44, P(BODY), shoulders=1.35, hips=1.1, stoop=3.5, arms="down", legs_apart=1.3)
    (sx, sy) = pt["shoulders"][1]
    lay.ellipse(266, sy + 2, 8.5, 3.6, P(BODY))
    lay.line([(int(sx) - 1, int(sy) + 3), (int(sx) + 7, int(sy) - 12)], P(BODY))
    lay.line([(int(sx), int(sy) + 3), (int(sx) + 8, int(sy) - 12)], P(BODY))
    lay.poly([(sx + 4, sy - 16), (sx + 12, sy - 12), (sx + 10, sy - 8), (sx + 3, sy - 12)], P(BODY))
    figs.append(lay)
    # a child on the merlon, one arm up waving at the sun, a tuft of hair
    lay = Layer()
    pt = person(lay, 293, PARAPET - 12, 21, P(BODY), shoulders=0.95, head=1.25, arms="none", legs_apart=1.8)
    hx, hy = pt["head"]
    (lx, ly), (rx, ry) = pt["shoulders"]
    lay.capsule((lx + 1, ly + 1.5), (lx - 3, ly - 6), 0.9, 0.8, P(BODY))
    lay.capsule((rx - 1, ry + 1.5), (rx + 3, ry + 6), 0.9, 0.8, P(BODY))
    lay.put(hx - 1, hy - 4, P(BODY))
    lay.put(hx + 1, hy - 5, P(BODY))
    figs.append(lay)
    # the lord, before the sun, the house's hooked staff raised high in the right hand
    lord = Layer()
    pt = person(lord, 160, 154, 56, P(BODY), shoulders=1.05, arms="none", robe=True, robe_hem=1.15)
    hx, hy = pt["head"]
    (lx, ly), (rx, ry) = pt["shoulders"]
    if form == "lady":
        lord.poly([(hx - 4, hy - 1), (hx + 4, hy - 1), (hx + 4.5, hy + 9), (hx - 4.5, hy + 9)], P(BODY))
        lord.capsule((hx + 1, hy + 8), (hx + 2, hy + 21), 1.5, 1.0, P(BODY))
    lord.capsule((lx + 1, ly + 2.5), (lx - 0.5, ly + 17), 2.0, 1.8, P(BODY))
    elbow = (rx + 4, ry + 6)
    hand = (rx + 6, ry - 4)
    lord.capsule((rx - 1, ry + 2.5), elbow, 2.0, 1.8, P(BODY))
    lord.capsule(elbow, hand, 1.8, 1.6, P(BODY))
    top = (hand[0] + 3, hand[1] - 28)
    lord.line([(hand[0] - 1, hand[1] + 9), top], P(BODY))
    lord.line([(hand[0], hand[1] + 9), (top[0] + 1, top[1])], P(BODY))
    lord.line([(top[0] + 1, top[1]), (top[0] + 3, top[1] - 2), (top[0] + 5, top[1] - 1), (top[0] + 6, top[1] + 1)],
              P(BODY))
    return figs, bells, lord, (int(top[0]) + 6, int(top[1]) + 5), (hx, hy)


def shadows_open2(c, figs):
    """Each figure's shadow, long and thin, thrown toward us along the wall walk by the sun behind them."""
    for lay in figs:
        xs = [x for (x, y) in lay.px]
        feet = max(y for (x, y) in lay.px)
        if feet < WALK:
            continue
        cx = sum(xs) / float(len(xs))
        half = (max(xs) - min(xs)) * 0.32
        for y in range(feet, H):
            t = (y - feet) / float(H - feet + 1)
            spread = (cx - SUN[0]) * 0.18 * (y - feet) / 10.0
            for x in range(int(cx + spread - half * (1 - t * 0.5)), int(cx + spread + half * (1 - t * 0.5)) + 1):
                if 0 <= x < W:
                    c.c[y][x] = P("night0")


def lantern_lit(c, x, y):
    """The house's lantern, small and alight, hanging from the staff's hook."""
    cluster(c, x - 2, y - 1, ["..k..", ".kkk.", "kGWGk", "kWWWk", "kGWGk", ".kkk."],
            {"k": "night0", "W": "fireWhite", "G": "fireGold"})
    for (i, j) in ((-1, 3), (5, 3), (2, 6)):
        c.c[y - 1 + j][x - 2 + i] = P("fireOrange")


def slide2(form):
    c = Canvas(P("nightSlate"))
    sky_open2(c)
    land_open2(c)
    parapet_open2(c)
    figs, bells, lord, lantern, head = court(form)
    shadows_open2(c, figs + [lord])
    for lay in figs:
        rim_light(lay, SUN, "fireGold", "dawnRose", reach=64)
        # below the coping the figure stands against the dark parapet: no rim there
        for (x, y), col in list(lay.px.items()):
            if y > PARAPET + 1 and col != P(BODY):
                lay.px[(x, y)] = P(BODY)
        lay.paste(c)
    # the lord stands before the sun: the rim runs all round above the coping, white and gold near the disc
    for (x, y) in list(lord.px):
        if y <= PARAPET + 1 and any((x + dx, y + dy) not in lord.px for dx, dy in ((1, 0), (-1, 0), (0, -1))):
            d = math.hypot(x - SUN[0], y - SUN[1])
            lord.px[(x, y)] = P("fireWhite" if d < 12 else "fireGold" if d < 26 else "gold")
    lord.paste(c)
    # the circlet: a thin gold band round the back of the head
    for dx in (-2, -1, 0, 1, 2):
        c.c[int(head[1]) - 1][int(head[0]) + dx] = P("gold")
    for (bx, by) in bells:
        c.c[by][bx] = P("gold")
    lantern_lit(c, *lantern)
    return c.finish(O2_ALLOWED, protect=("fireWhite", "fireGold", "fireOrange", "gold"))


# --- slide 1: the iron crown on the stone ---------------------------------------------------------------------------
# From above, at first light: the outer line's flags; the low sun at the right (east, where the castle is) rakes them
# and throws every shadow long to the left; the Gloom's last fog creeps off to the left (west).

O1_ALLOWED = ["night0", "night1", "nightSlate", "nightHaze", "far", "farPale", "mistDark", "mist", "mistLight",
              "foam", "plumDeep", "plum", "plumLight", "dusk", "dawnRose", "tileLight", "tile", "gold", "fireGold",
              "fireWhite", "fireOrange", "ember", "rockDeep", "rockDark", "rock", "rockLight", "rockPale",
              "stoneDark", "stoneMid", "stone", "stoneLight", "stonePale", "ink", "woodDark", "wood", "plaster",
              "plasterDim", "soilDark"]


def flags_from_above(c):
    """The flags seen from above at a slant: courses growing taller toward us, the joints running toward a point far
    beyond the top of the picture, each stone one flat colour of its own size, its right edge (toward the sun) lit, its
    left joint dark; warmer toward the sun."""
    vp = (170, -260)
    y = 0
    k = 0
    while y < H:
        hgt = int(9 + y * 0.09 + h1(k, 921) * 4)
        shift = h1(k, 923) * 40
        for yy in range(y, min(H, y + hgt)):
            scale_k = (yy - vp[1]) / float(H - vp[1])
            for xx in range(W):
                u = (xx - vp[0]) / scale_k + vp[0] + shift
                # stones of uneven width along the course
                j = 0
                left = -60.0
                while True:
                    bw = 24 + h1(j + k * 13, 925) * 30
                    if left + bw > u:
                        break
                    left += bw
                    j += 1
                q = u - left
                bw = 24 + h1(j + k * 13, 925) * 30
                pick = h2(j, k, 927)
                body = "rockLight" if pick > 0.55 else "rock" if pick > 0.12 else "rockPale"
                if xx > 210 and h1(j + k * 7, 929) > 0.5:
                    body = "rockPale" if body == "rockLight" else "rockLight"
                if yy == y + hgt - 1 or q < 1.0 / scale_k:
                    col = "rockDeep"
                elif yy == y + hgt - 2 or q < 2.0 / scale_k:
                    col = "rockDark"
                elif q > bw - 1.2 / scale_k:
                    col = "dawnRose" if xx > 170 else "rockPale"
                else:
                    col = body
                c.c[yy][xx] = P(col)
        y += hgt
        k += 1


def creeping_fog(c):
    """The Gloom's last fog lying low on the stones at the left, drawing off: a soft heap of rounded lobes with a pale
    rim, and a few loose puffs going after it."""
    lobes = [(-16, 16, 26), (-8, 58, 24), (-18, 100, 26), (-4, 142, 22), (14, 34, 11), (16, 84, 10),
             (12, 122, 10)]

    def inside(x, y):
        v = 0.0
        for (lx, ly, r) in lobes:
            v += r * r / max(1.0, (x - lx) ** 2 + ((y - ly) * 1.4) ** 2)
        return v
    for y in range(H):
        for x in range(0, 100):
            v = inside(x, y)
            if v > 1.0:
                col = "mistLight" if v < 1.3 else "mist"
                c.c[y][x] = P(col)


FACE = """
.......hhhhhhhh.........
.....hhHHHHHHHHhh.......
....hHHHPPPPPHHHHhh.....
...hHHPPssssssPHHHhh....
..hhHHssssssssSSHHhh....
..hHHtssssssssssSHHhh...
.hhHttsssssssssssSHhh...
.hhHtddddssssddddSHhh...
.hhttttssssssssssSShh...
.hhtwwwwtssssswwwwSHh...
.hhtttttssssssttttSHh...
.hhttttsssSsssstttShh...
..httttsssSSssttttShh...
..htttttssSSSsttttsh....
..htttttwssswtttttsh....
..hbttPPPPPPPPPPtsbh....
..hbbPPPPPPPPPPPPPbbh...
..hbbbPPwwwwwwwPPbbbh...
..hbbbbbPPPPPPPbbbbbh...
...hbbbbbbbbbbbbbbbh....
...hbbbBbbbbbBbbbbbh....
....hbbbbbbbbbbbbbh.....
.....hbbbBbbbbbbbh......
......hbbbbbbbbbh.......
.......hbbbbbbbh........
........hhhhhhh.........
"""


def aldric_from_above(x, y):
    """Aldric on his back under the black mantle, seen from above: his face upright, grey, thin, eyes shut, the grey
    beard on his breast, the hood fallen back under his head, its dark lining round the grey hair; the mantle down to
    the frame's foot, its folds lit on their right; one thin arm out on the stone toward the crown. (x, y): the top of
    his head."""
    lay = Layer()
    # the mantle over him, widening toward his feet beyond the frame
    # the cloth spread flat round him on the stone, a shade lighter at its edge where it lies thin
    lay.poly([(x - 24, y + 26), (x + 24, y + 26), (x + 38, y + 50), (x + 34, y + 76), (x + 44, y + 98),
              (x + 36, y + 118), (x + 46, y + 142), (x - 46, y + 142), (x - 38, y + 120), (x - 46, y + 96),
              (x - 36, y + 74), (x - 40, y + 50)], P("plumDeep"))
    # his body under it: broad shoulders, the arm along his side, narrower at the hips and knees, the two feet
    lay.poly([(x - 20, y + 24), (x + 20, y + 24), (x + 26, y + 34), (x + 24, y + 70), (x + 20, y + 96),
              (x + 16, y + 124), (x + 14, y + 138), (x + 4, y + 142), (x + 1, y + 132), (x - 1, y + 132),
              (x - 4, y + 142), (x - 14, y + 138), (x - 16, y + 124), (x - 20, y + 96), (x - 24, y + 70),
              (x - 26, y + 34)], P("night0"))
    # folds across the cloth where it drapes over him, each lit on its right
    # the mantle's drapes: long folds from the shoulders down over the body, each lit along its right edge
    for f in (((x - 12, y + 30), (x - 6, y + 70), (x - 4, y + 112), (x - 3, y + 132)),
              ((x + 10, y + 30), (x + 12, y + 64), (x + 10, y + 104), (x + 8, y + 134)),
              ((x - 22, y + 46), (x - 18, y + 90), (x - 12, y + 128)),
              ((x + 22, y + 44), (x + 20, y + 88), (x + 14, y + 124)), ((x, y + 76), (x + 1, y + 120))):
        lay.line(list(f), P("plumDeep"))
        for (fx, fy) in f[1:]:
            lay.put(fx + 1, fy, P("plum"))
            lay.put(fx + 1, fy - 1, P("plum"))
    for (fx, fy) in ((x + 36, y + 60), (x + 40, y + 100), (x + 38, y + 126), (x - 40, y + 70), (x - 42, y + 108)):
        lay.line([(fx, fy), (fx + 2, fy + 10)], P("plum"))
    # the hood under his head: a dark round of lining, its rim catching the light at the right
    lay.ellipse(x, y + 12, 17, 15, P("night0"))
    for k in range(-12, 13):
        lay.put(x + 15 + (1 if abs(k) < 6 else 0), y + 12 + k, P("plumDeep"))
    # grey hair spread on the lining
    for (dx, dy) in ((-14, 4), (-15, 9), (-13, 16), (14, 5), (15, 11), (13, 17), (-10, -1), (9, -1), (0, -3),
                     (-5, -2), (5, -2)):
        lay.capsule((x + dx * 0.6, y + 10 + dy * 0.4), (x + dx, y + 10 + dy * 0.5 - 4), 1.0, 0.8, P("stone"))
    legend = {"h": P("stone"), "H": P("stoneLight"), "P": P("stonePale"), "s": P("tileLight"), "S": P("dawnRose"),
              "t": P("tile"), "d": P("stoneMid"), "w": P("woodDark"), "b": P("stoneLight"), "B": P("stonePale")}
    lay.grid(FACE.strip("\n"), x - 12, y, legend)
    # the thin arm out of the mantle to the right, the hand open on the stone
    lay.capsule((x + 26, y + 46), (x + 56, y + 40), 2.6, 2.0, P("night0"))
    hand = (x + 62, y + 39)
    lay.capsule((x + 56, y + 40), hand, 1.8, 1.5, P("tileLight"))
    for (dx, dy, col) in ((2, -2, "dawnRose"), (3, -1, "dawnRose"), (4, 0, "dawnRose"), (3, 1, "tileLight"),
                          (2, 2, "tile"), (1, -1, "tileLight")):
        lay.put(hand[0] + dx, hand[1] + dy, P(col))
    lay.outline(P("night0"), skip_bottom=False)
    return lay


def iron_crown(cx, cy):
    """The iron crown of the old country where it rolled to a stop, seen from above at a slant: a heavy ring, seven
    tall tines, old iron dark with the low sun on its right-hand edges and a little rust."""
    lay = Layer()
    tilt = 0.12
    rx, ry, th = 24.0, 12.0, 5.0

    def at(a):
        return (cx + rx * math.cos(a) * math.cos(tilt) - ry * math.sin(a) * math.sin(tilt),
                cy + rx * math.cos(a) * math.sin(tilt) + ry * math.sin(a) * math.cos(tilt))
    for k in range(120):
        a = k / 120.0 * 2 * math.pi
        x, y = at(a)
        if math.sin(a) < 0:
            for t in range(int(th) + 1):
                lay.put(round(x), round(y - t), P("night1" if t > 1 else "stoneDark"))
    # the floor seen through the ring stays; the band's front wall over it
    for k in range(120):
        a = k / 120.0 * 2 * math.pi
        x, y = at(a)
        if math.sin(a) >= 0:
            lit = math.cos(a) > 0.25
            for t in range(int(th) + 1):
                col = ("stone" if lit else "stoneMid") if t > 0 else ("tileLight" if lit else "stone")
                if math.cos(a) > 0.8:
                    col = "dawnRose" if t < 2 else "stone"
                lay.put(round(x), round(y - t), P(col))
    for i in range(7):
        a = math.pi * (1.1 + i * 0.13)
        bx, by = at(a)
        by -= th
        hgt = 11 + (4 if i == 3 else 0) + int(h1(i, 901) * 3)
        tip = (bx + (i - 3) * 1.1, by - hgt)
        lay.poly([(bx - 2, by + 1), (bx + 2, by + 1), tip], P("stoneMid"))
        lay.line([(bx + 1, by), (round(tip[0]), round(tip[1]))], P("tileLight"))
        lay.put(round(tip[0]), round(tip[1]), P("dawnRose"))
    for (dx, dy) in ((-14, 7), (-6, 11), (7, 11), (15, 6)):
        if (cx + dx, cy + dy) in lay.px:
            lay.put(cx + dx, cy + dy, P("tile"))
    lay.outline(P("night0"), skip_bottom=False)
    return lay


def snuffer_broken():
    """The King's snuffer, broken in two on the stone: the long iron pole and its cone."""
    lay = Layer()
    lay.line([(70, 154), (126, 120)], P("stoneDark"))
    lay.line([(71, 154), (127, 120)], P("stoneDark"))
    lay.line([(72, 154), (128, 120)], P("stone"))
    lay.line([(134, 114), (150, 104)], P("stoneDark"))
    lay.line([(135, 114), (151, 104)], P("stone"))
    lay.poly([(58, 152), (70, 150), (74, 159), (56, 160)], P("stoneDark"))
    lay.line([(70, 150), (74, 159)], P("stone"))
    lay.outline(P("night0"), skip_bottom=False)
    return lay


def lantern_standing(c, x, y):
    """The lord's lantern set down on the stone by Aldric's head, still burning; its small pool on the flags."""
    for yy in range(y - 8, y + 9):
        for xx in range(x - 14, x + 15):
            if 0 <= xx < W and 0 <= yy < H:
                d = math.hypot((xx - x) / 14.0, (yy - y) / 8.0)
                if d < 1 and c.c[yy][xx] in (P("rock"), P("rockLight"), P("rockPale"), P("rockDark"), P("dawnRose")):
                    c.c[yy][xx] = P("gold") if d < 0.42 else P("tileLight")
    cluster(c, x - 3, y - 7, ["..kk..", ".kkkk.", "kGWWGk", "kWWWWk", "kGWWGk", "kGWWGk", ".kkkk.", "kkkkkk"],
            {"k": "night0", "W": "fireWhite", "G": "fireGold"})
    for (i, j) in ((-1, 3), (6, 3), (-1, 4), (6, 4)):
        c.c[y - 7 + j][x - 3 + i] = P("fireOrange")


def slide1():
    c = Canvas(P("rock"))
    flags_from_above(c)
    creeping_fog(c)
    crown = iron_crown(250, 72)
    al = aldric_from_above(160, 22)
    sn = snuffer_broken()
    stone = lambda x, y: 0 <= y < H and 0 <= x < W and c.c[y][x] in (P("rock"), P("rockLight"), P("rockPale"), P("rockDark"), P("rockDeep"),  # noqa
                                       P("dawnRose"), P("mist"), P("mistLight"), P("mistDark"))
    cast_shadow(c, crown, 84, 2.2, ground=stone, darken=2, lift=0.15)
    cast_shadow(c, sn, 160, 0.4, ground=stone, darken=1)
    # Aldric lies flat: his shadow a narrow band to the left of him
    for (x, y) in list(al.px):
        for k in range(1, 6):
            if (x - k, y) not in al.px and stone(x - k, y):
                c.c[y][x - k] = step(c.c[y][x - k], -1)
    for lay in (sn, al, crown):
        lay.paste(c)
    lantern_standing(c, 120, 26)
    return c.finish(O1_ALLOWED, protect=("fireWhite", "fireGold", "fireOrange", "dawnRose", "gold"),
                    keep=lambda x, y: 146 <= x <= 176 and 20 <= y <= 50)


# --- slide 3: the ruined castle beyond the firs ----------------------------------------------------------------------
# West from the Throat's mouth, the sun just up at our backs: only the heights catch it. The ruin on its hill glows
# rose and gold above a valley still in blue shadow, where the fog is drawing back past the firs; the road with its
# statues runs out toward the hill; Aldric and the lord small on it.

O3_ALLOWED = ["night0", "night1", "nightSlate", "nightHaze", "far", "farDeep", "farPale", "mistDark", "mist",
              "mistLight", "foam", "plumDeep", "plum", "plumLight", "dusk", "dawnRose", "tileLight", "tile", "gold",
              "fireGold", "fireWhite", "rockDeep", "rockDark", "rock", "rockLight", "rockPale", "plaster",
              "plasterDim", "fir0", "fir1", "fir2", "fir3", "woodDark", "ink"]

HILL_X = 246
BASE = 100           # the ruin's foot on its hill


def sky_open3(c):
    # the western sky at sunrise: the Earth's shadow low and blue, the pink belt over it, cool lavender above
    dawn_sky(c, (160, 92), [(12, "mistDark"), (20, "mist"), (31, "dawnRose"), (43, "mistLight"), (64, "mist"),
                            (90, "farPale"), (9999, "mist")], 0, 96, dip=0, wobble=3.0, seed=951)
    for (x0, x1, y0, th, seed) in ((14, 104, 20, 3.0, 953), (150, 230, 12, 2.6, 955), (60, 150, 40, 2.0, 957)):
        cloud_wisp(c, x0, x1, y0, th, seed,
                   lambda x, y, t, b: P("dawnRose") if y >= b - 1.4 else P("mistLight") if y <= t + 1 else P("foam"))


def far_hills3(c):
    for x in range(W):
        top = 80 - 6 * fbm(x * 0.015, 0.4, 959, 3) - 3 * math.sin(x * 0.02 + 2)
        for y in range(int(top), 110):
            c.c[y][x] = P("mist" if y < top + 1 else "mistDark")


def hill3(c):
    """The hill under the ruin: its crest catching the sun, its flanks in shadow."""
    top = {}
    for x in range(W):
        d = (x - HILL_X) / 78.0
        top[x] = BASE - 2 + 26 * min(1.0, d * d) - 2 * fbm(x * 0.05, 0.2, 961, 2)
    for x in range(W):
        for y in range(int(top[x]), H):
            if y < top[x] + 1 and abs(x - HILL_X) < 60:
                col = "dawnRose"
            elif y < top[x] + 3 and abs(x - HILL_X) < 50:
                col = "dusk"
            else:
                col = "far"
            c.c[y][x] = P(col)


def ruin(c):
    """The older castle, larger than ours, in ruins: towers torn to stumps, the keep a roofless shell, the curtain
    broken in two places, windows empty. The sun just up behind us lights only its upper half (rose and gold); its
    foot is still in the valley's blue shadow. Our lantern is cut over the great gate."""
    lay = Layer()
    glow_line = BASE - 18          # above it the sun reaches

    def stone(x, y, x0, x1, side):
        lit = y < glow_line + (x % 7 == 0) * 2 - (x % 11 == 0) * 2
        edge_l, edge_r = x < x0 + 2, x >= x1 - 3
        if side == "r" and edge_r:
            return P("dusk" if lit else "farDeep")
        if side == "l" and edge_l:
            return P("dusk" if lit else "farDeep")
        row = y // 5
        joint = (y % 5 == 4 and h2(x // 6, row, 962) > 0.55) or ((x + row * 7) % 13 == 0 and y % 5 < 4
                                                                   and h2(x // 13, row, 964) > 0.5)
        worn = h2(x // 5, row, 963) > 0.88
        if lit:
            return P("tileLight" if joint else ("plaster" if worn else "dawnRose"))
        return P("mistDark" if joint else ("plumLight" if worn else "mist"))

    def block(x0, x1, y0, y1, broken=0, seed=0, side=None, crenels=True):
        for x in range(x0, x1):
            jag = 0
            if broken:
                jag = int(broken * fbm(x * 0.35, 0.2, seed, 2) + (broken * 0.6 if h1(x, seed) > 0.78 else 0))
            for y in range(y0 + jag, y1):
                lay.put(x, y, stone(x, y, x0, x1, side))
            if crenels and not broken and (x - x0) % 4 < 2:
                for y in (y0 - 1, y0 - 2):
                    lay.put(x, y, stone(x, y, x0, x1, side))
    block(180, 210, BASE - 16, BASE, seed=967, side=None)
    block(210, 222, BASE - 8, BASE, broken=8, seed=969, crenels=False)
    block(256, 276, BASE - 16, BASE, seed=971)
    block(276, 288, BASE - 5, BASE, broken=6, seed=973, crenels=False)
    block(288, 308, BASE - 15, BASE, seed=975)
    block(170, 184, BASE - 38, BASE, broken=4, seed=977, side="r")
    block(218, 234, BASE - 50, BASE, side="r", seed=979)
    block(246, 260, BASE - 44, BASE, broken=16, seed=981, side="l", crenels=False)
    block(300, 314, BASE - 30, BASE, broken=12, seed=983, side="r", crenels=False)
    block(262, 286, BASE - 60, BASE - 16, broken=14, seed=985, side="r", crenels=False)
    block(232, 254, BASE - 26, BASE, seed=987)
    for y in range(BASE - 16, BASE):
        for x in range(237, 249):
            if (y - (BASE - 16)) >= 3 or abs(x - 242.5) < 3 + (y - (BASE - 16)):
                lay.put(x, y, P("rockDeep"))
    for (x, y, w, h) in ((175, BASE - 30, 1, 5), (178, BASE - 20, 1, 4), (223, BASE - 42, 2, 6), (228, BASE - 40, 2, 6),
                         (225, BASE - 26, 1, 4), (266, BASE - 52, 2, 6), (273, BASE - 50, 2, 6), (279, BASE - 44, 2, 5),
                         (268, BASE - 34, 2, 5), (304, BASE - 20, 1, 4), (190, BASE - 10, 1, 3), (200, BASE - 10, 1, 3),
                         (294, BASE - 9, 1, 3), (252, BASE - 30, 1, 4)):
        for yy in range(y, y + h):
            for xx in range(x, x + w):
                lay.put(xx, yy, P("rockDeep"))
    for (x0, x1) in ((208, 226), (274, 290)):
        for x in range(x0, x1):
            hgt = int(3 * math.sin((x - x0) / float(x1 - x0) * math.pi) + h1(x, 989) * 2)
            for y in range(BASE - hgt, BASE + 1):
                lay.put(x, y, P("mist" if h2(x, y, 991) > 0.5 else "mistDark"))
    lay.outline(P("farDeep"), skip_bottom=True)
    lay.paste(c)
    # our lantern cut over the gate, the sun on it: the brightest gold in the picture
    cluster(c, 241, BASE - 24, [".g.", "gWg", "gWg", "ggg"], {"g": "gold", "W": "fireGold"})


def fir_cluster(c, x0, x1, base, hmin, hmax, seed):
    x = x0
    k = 0
    while x < x1:
        hgt = hmin + h1(k, seed) * (hmax - hmin)
        fir(c, x + h1(k, seed + 1) * 3, base + h1(k, seed + 2) * 3, hgt, P("fir1"), lit=P("fir2"), seed=seed + k,
            width=0.30)
        x += 4 + h1(k, seed + 3) * 6
        k += 1


def fog3(c, x0, x1, base, hgt, seed, bottom):
    """A bank of fog in the valley's shadow, drawing off: rounded billows, a pale lit top, cool below."""
    top = ragged_top(x0, x1, base, hgt, seed, freq=0.09, lumps=3)
    for x in range(max(0, x0), min(W, x1)):
        for y in range(max(0, int(math.ceil(top[x]))), min(H, bottom)):
            d = y - top[x]
            c.c[y][x] = P("mistLight" if d < 1.2 else "mist" if d < hgt * 0.5 + 2 else "mistDark")


def road3(c):
    """The road from the Throat's mouth at our feet out toward the hill, in the valley's shadow."""
    pts = []
    for y in range(112, H):
        t = (y - 112) / float(H - 112)
        cx = 186 - 60 * t ** 1.2
        half = 1.5 + 40 * t ** 1.4
        pts.append((y, cx, half))
        for x in range(int(cx - half), int(cx + half) + 1):
            if 0 <= x < W:
                rut = half > 8 and abs(abs(x - cx) - half * 0.45) < 0.7
                c.c[y][x] = P("farDeep" if rut else ("mistDark" if h2(x // 4, y // 3, 1006) > 0.8 else "mist"))
                if abs(x - cx) > half - 1:
                    c.c[y][x] = P("mistDark")
    return pts


def statues3(c, road):
    """The statues along the road, facing home toward us and going on out of sight: tall robed figures on square
    plinths, dark in the valley's shadow, the farthest catching a little of the light."""
    for k in range(7):
        t = 0.95 - k * 0.14
        if t < 0.05:
            break
        y, cx, half = road[int(t * (len(road) - 1))]
        hgt = 4 + 30 * t ** 1.3
        for side in (-1, 1):
            x = cx + side * (half + 3 + hgt * 0.25)
            lay = Layer()
            pw = max(1.0, hgt * 0.16)
            ph = max(1.0, hgt * 0.2)
            lay.poly([(x - pw, y - ph), (x + pw, y - ph), (x + pw, y), (x - pw, y)], P("farDeep"))
            person(lay, x, y - ph, hgt * 0.8, P("nightHaze"), shoulders=0.85, arms="hold", robe=True)
            hx, hy = x, y - ph - hgt * 0.8 + hgt * 0.06
            lay.ellipse(hx, hy, max(1.0, hgt * 0.07), max(1.0, hgt * 0.08), P("nightHaze"))
            # the side toward the open sky a step paler
            for (px, py), col in list(lay.px.items()):
                if (px - 1, py) not in lay.px:
                    lay.px[(px, py)] = P("far") if col == P("nightHaze") else P("mistDark")
            lay.paste(c)


def mouth3(c):
    """The Throat's mouth framing us: the dark rock at both edges, only its crest touched by the sun."""
    for x in range(W):
        lt = 166 - (44 - x) * 3.6 + 8 * fbm(x * 0.06, 0.3, 999, 2) if x < 44 else 999
        rt = 166 - (x - 284) * 3.4 + 8 * fbm(x * 0.06, 0.7, 1001, 2) if x > 284 else 999
        top = min(lt, rt)
        for y in range(max(0, int(top)), H):
            d = y - top
            c.c[y][x] = P("dawnRose" if d < 1 else "rockDark" if d < 3 else "rockDeep" if d > 18 or h2(x // 4, y // 6, 1005) > 0.3 else "rockDark")


def travellers(c):
    """Aldric and the lord small on the road, seen from behind against the fog: Aldric in the mantle leaning on the
    lord's shoulder, the lord's lantern still lit."""
    lay = Layer()
    person(lay, 150, 150, 24, P("night1"), shoulders=1.0, arms="down", robe=True)
    person(lay, 158, 150, 25, P("night0"), shoulders=1.1, arms="none", robe=True, robe_hem=1.2, stoop=2.0)
    lay.capsule((156, 133), (151, 131), 1.3, 1.1, P("night0"))
    lay.line([(144, 140), (143, 136)], P("night1"))
    lay.paste(c)
    c.c[134][143] = P("fireGold")
    c.c[135][143] = P("fireWhite")


def slide3():
    c = Canvas(P("mist"))
    sky_open3(c)
    far_hills3(c)
    hill3(c)
    ruin(c)
    fog3(c, 120, 340, 110, 9, 1007, 124)
    fir_cluster(c, 150, 230, 116, 10, 18, 1011)
    fir_cluster(c, 0, 130, 120, 12, 24, 1013)
    fog3(c, -20, 220, 118, 10, 1009, 132)
    fir_cluster(c, 268, 330, 120, 14, 22, 1015)
    road = road3(c)
    fir_cluster(c, 0, 70, 138, 22, 36, 1017)
    fir_cluster(c, 240, 330, 140, 20, 34, 1019)
    statues3(c, road)
    mouth3(c)
    travellers(c)
    return c.finish(O3_ALLOWED, protect=("fireWhite", "fireGold", "gold", "dawnRose"))


SLIDES = {
    "slideOpen1": slide1,
    "slideOpen3": slide3,
    "slideOpen2Lord": lambda: slide2("lord"),
    "slideOpen2Lady": lambda: slide2("lady"),
}
