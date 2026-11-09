"""The Lightless King: a tall crowned shape whose face is a void. A long mantle with a torn train, a crown of iron
thorns, and in its hand a snuffer on a long pole, the tool that puts lights out. No eyes: a cold ring of light leaks
around the hollow of the cowl. Cold only, no ember."""
from rig import Frame, ik, ASH, ROBE, IRON, HUSK

SIZE = (64, 64, 7)
MANTLE = ["nightDeep", "night0", "night1", "night2"]
# walk 0-3 at 5 px a frame: the foot tips under the hem and the pole's foot are planted and move back 5 px a frame
P = [dict(dy=0, feet=(34, 24), pole=(45, 63), top=(41, 5), tr=0),
     dict(dy=1, feet=(29, None), pole=(40, 63), top=(43, 5), tr=1),
     dict(dy=0, feet=(24, 34), pole=(41, 60), top=(46, 6), tr=2),
     dict(dy=1, feet=(None, 29), pole=(50, 63), top=(39, 5), tr=1),
     # attack 4-6: the snuffer lifted high behind the crown, brought down ahead, held on the ground
     dict(dy=-1, feet=(30, 24), pole=(52, 14), top=(8, 5), tr=-1, lean=-2, hand=(37, 11)),
     dict(dy=2, feet=(34, 24), pole=(30, 26), top=(60, 55), tr=3, lean=3, hand=(42, 36)),
     dict(dy=1, feet=(34, 24), pole=(31, 27), top=(59, 57), tr=2, lean=2, hand=(41, 36))]


def frame(k):
    f = Frame(64, 64, seed=37)
    p = P[k]
    dy, ln, tr = p["dy"], p.get("lean", 0), p["tr"]
    sx = 26 + ln                               # the spine's top
    # the train: the mantle trailing behind, torn
    f.poly([(sx - 5, 17 + dy), (sx - 9, 30 + dy), (10 - tr, 48), (3 - tr * 1.5, 61), (4 - tr, 63), (24, 63),
            (sx - 1, 30 + dy)], MANTLE, dk=1, fold=0.45, skew=0.3, phase=tr * 0.5)
    f.tatter(1, 20, 9, 9, shift=tr, y_min=44)
    # the foot tips
    for x in p["feet"]:
        if x is not None:
            f.seg((x - 2, 63), (x + 2, 63), 1.0, 0.8, IRON)
    # the robe's front
    f.poly([(sx - 5, 17 + dy), (sx + 5, 17 + dy), (sx + 6, 34 + dy), (36, 62), (33, 63), (17, 63), (sx - 7, 36 + dy)],
           MANTLE, fold=0.5, skew=0.1, phase=1.0 + tr * 0.3)
    f.tatter(18, 36, 4, 3, shift=tr, y_min=56)
    # the near arm: hanging, too long, the fingers past the knee
    hs = (sx - 2, 20 + dy)
    hh = (sx - 3 - tr * 0.5, 45 + dy)
    f.seg(hs, hh, 2.6, 1.6, MANTLE)
    f.stamp(int(hh[0]) - 1, int(hh[1]) + 1, ["sss", "sSs", "s.S", "s.s", "s.s", "..s"], {"s": "stoneMid", "S": "stone"})
    # the dead lanterns at its belt, the lights it has put out
    for (bx, n, ph) in ((sx + 2, 5, 0), (sx + 5, 9, 1)):
        ox = (0, 1, 0, -1, -1, 2, 1)[(k + ph) % 7 if k < 4 else k]
        f.line((bx, 34 + dy), (bx + ox, 34 + dy + n), "ink")
        f.stamp(bx + ox - 1, 35 + dy + n, [".i.", "iji", "iji", ".i."], {"i": "stoneMid", "j": "night0"})
    # the shoulder cape, torn
    f.poly([(sx - 7, 16 + dy), (sx + 7, 16 + dy), (sx + 8, 22 + dy), (sx + 6, 26 + dy), (sx + 5, 23 + dy),
            (sx + 3, 27 + dy), (sx + 1, 24 + dy), (sx - 1, 28 + dy), (sx - 3, 24 + dy), (sx - 5, 27 + dy),
            (sx - 6, 23 + dy), (sx - 8, 25 + dy)], ROBE, fold=0.7, skew=0.2)
    hx, hy = sx + 1, 11 + dy
    f.ell((hx, hy), 4.6, 5.6, ROBE)
    f.ell((hx + 1.6, hy + 0.6), 2.6, 3.6, ["night0"] * 4, tex=0)
    for (gx, gy, g) in ((-1, -2, "wraithDim"), (-2, -1, "wraithDim"), (-2, 0, "wraithGlow"), (-2, 1, "wraithGlow"),
                        (-2, 2, "wraithDim"), (-1, 3, "wraithDim"), (0, -3, "wraithDim"), (1, -3, "wraithGlow"),
                        (2, -3, "wraithDim"), (0, 4, "wraithDim"), (1, 4, "wraithDim")):
        f.glow(hx + 1 + gx, hy + 0.6 + gy, g, "stoneMid")
    # the crown of thorns: uneven iron spikes, the tallest in front, one broken
    f.stamp(hx - 5, hy - 14, [".....T....",
                              ".....c....",
                              ".T...c....",
                              ".c...c..T.",
                              ".c...c..c.",
                              ".c.T.c..c.",
                              ".c.c.c.cc.",
                              ".cccccccc.",
                              "..cccccc.."], {"c": "stoneMid", "T": ("stoneLight", "wraithGlow")})
    f.norim.update(range(int(hx) - 5, int(hx) + 5))
    # the snuffer: a long pole, a crook at its top, the bell hanging from the crook
    bot, top = p["pole"], p["top"]
    hy2 = 31 + dy
    hand = p.get("hand", (bot[0] + (top[0] - bot[0]) * (hy2 - bot[1]) / (top[1] - bot[1]), hy2))
    f.line(bot, top, "stoneDark")
    ux, uy = top[0] - bot[0], top[1] - bot[1]
    n = (ux * ux + uy * uy) ** 0.5
    ux, uy = ux / n, uy / n
    if k == 4:                                  # lifted over the crown: the bell hangs from the far end
        f.stamp(int(top[0]) - 2, int(top[1]) + 1, ["..i..", ".iii.", ".iii.", "iiiii", "i.n.i"],
                {"i": "stoneMid", "n": "night0"})
    elif k < 4:                                 # carried upright: the bell hangs from the crook
        c = (top[0] + 4, top[1] - 1)
        f.line(top, c, "stoneDark")
        f.stamp(int(c[0]) - 2, int(c[1]) + 1, ["..i..", ".iii.", ".iii.", "iiiii", "i.n.i"],
                {"i": "stoneMid", "n": "night0"})
    else:                                       # struck down: the bell over the ground, mouth down
        f.stamp(int(top[0]) - 2, int(top[1]) + 1, ["..i..", ".iii.", ".iii.", "iiiii", "iinii"],
                {"i": "stoneMid", "n": "night0"})
    # the far arm holding it
    s2 = (sx + 4, 20 + dy)
    el = ik(s2, hand, 8, 9, 1)
    f.seg(s2, el, 2.4, 2.0, MANTLE)
    f.seg(el, hand, 1.8, 1.3, MANTLE)
    f.poly([(el[0] - 2, el[1]), (el[0] + 2, el[1] + 1), (el[0] + 1 - tr * 0.5, el[1] + 9), (el[0] - 2, el[1] + 5)],
           MANTLE, dk=1)                        # the sleeve's torn end
    f.stamp(int(hand[0]) - 1, int(hand[1]) - 1, ["ss", "ss", "s."], {"s": "stoneMid"})
    return f.finish(rim="wraithDim")
