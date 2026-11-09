"""Gloomweaver: a gaunt robed figure that floats, bent over the dead lantern it carries on arms far too long. The
lantern gives no light: a violet dark leaks from it and drips. Its eyes weep cold light. The robe ends in torn
strips that trail behind."""
from rig import Frame, ik, ASH, ROBE

SIZE = (30, 30, 4)
FLOATS = True
SW = [0, 1, 0, -1]          # the lantern's swing
TAIL = [0, 1, 2, 1]         # the robe's tail, a wave running back


def frame(k):
    f = Frame(30, 30, seed=23)
    sw, tl = SW[k], TAIL[k]
    # the robe: narrow, bent forward, the tail in torn strips trailing back
    f.poly([(11, 9), (17, 9), (17, 16), (14, 21), (11, 23), (6, 23), (8, 15)], ROBE, fold=1.0, skew=0.5,
           phase=k * 0.8)
    for i, (x, n) in enumerate(((13, 4), (11, 6), (9, 4), (7, 7), (5, 3))):   # the strips
        d = tl if i % 2 else (tl + 1) // 2
        f.line((x, 22), (x - 1 - d, 22 + n), "night1" if i % 2 else "night2")
        if n > 4:
            f.line((x + 1, 22), (x - d, 21 + n), "night1")
    # the hood, hanging forward, its face a dark opening
    f.ell((15, 6.5), 4.2, 4.8, ROBE, fold=0.8, skew=-0.3)
    f.poly([(11, 4), (12, 0), (15, 1), (14, 4)], ROBE, dk=1)           # the hood's limp peak
    f.stamp(15, 5, [".vvv",
                    "vvvv",
                    "vevE",
                    "vdvd",
                    "vdvv",
                    ".vv."], {"v": "night0", "E": ("stoneLight", "wraithWhite"), "e": ("stone", "wraithGlow"),
                              "d": ("stoneDark", "wraithDim")})
    # the arms: thin, both reaching forward and down, the lantern's chain in the hands
    hand = (24, 15)
    for sh, dk in (((16, 11), 1), ((15, 12), 0)):
        el = ik(sh, hand, 6, 6, -1)
        f.seg(sh, el, 1.2, 0.8, ROBE, dk)
        f.seg(el, hand, 0.7, 0.6, ASH, dk)
    f.stamp(19, 12 + (1 if k == 2 else 0), ["r", "r", "r", "r"], {"r": "night1"})   # a sleeve's torn end
    lx = 22 + sw
    f.line((24, 16), (lx + 2, 17), "ink")
    f.stamp(lx, 18, ["..i..",
                     ".iii.",
                     "ivVvi",
                     "ivvvi",
                     "i.v.i",
                     ".iii."], {"i": "stoneMid", "v": ("night1", "violetDim"), "V": ("night2", "violetGlow")})
    f.norim.update(range(lx, lx + 5))
    # the dark dripping from it
    f.glow(lx + 2, 25 + k, "violetDim", "night1")
    if k >= 2:
        f.glow(lx + 2, 24 + k, "violetDim", "night1")
    return f.finish(rim="violetDim")
