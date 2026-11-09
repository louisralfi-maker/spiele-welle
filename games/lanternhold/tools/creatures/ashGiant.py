"""Ash Giant: a starved titan, stooped under a torn cloak as large as a sail. Its chest is a broken lantern: between
the bare ribs an ember heart still smoulders. The head hangs lower than the shoulders, the jaw open; the arms reach
almost to the ground. It shuffles on planted feet and stamps."""
from rig import Frame, ik, leg, HUSK, ASH, BONE, RAG

SIZE = (110, 110, 7)
# walk 0-3 at 4 px a frame: a planted foot moves back 4 px a frame, then swings; the arms swing against the legs
P = [dict(dy=1, nf=(60, 0), ff=(52, 0), arm=2, hem=0, heart=0),
     dict(dy=0, nf=(56, 0), ff=(56, 4), arm=0, hem=1, heart=1),
     dict(dy=1, nf=(52, 0), ff=(60, 0), arm=-2, hem=2, heart=0),
     dict(dy=0, nf=(56, 4), ff=(56, 0), arm=0, hem=1, heart=2),
     # stomp 4-6: the near leg drawn up high, slammed down ahead, held
     dict(dy=-2, nf=(66, 30), ff=(50, 0), arm=-5, hem=-2, heart=2, lean=-5, knee=(74, 64)),
     dict(dy=5, nf=(72, 0), ff=(48, 0), arm=7, hem=4, heart=3, lean=5),
     dict(dy=3, nf=(72, 0), ff=(48, 0), arm=4, hem=2, heart=1, lean=3)]


def hand(f, x, y, dk):
    f.stamp(int(x) - 3, int(y) - 1, [".sss..",
                                     "sssss.",
                                     "sSsSss",
                                     "s.s.Ss",
                                     "s.s.s.",
                                     "s.s.s.",
                                     "..s..."] if not dk else
            [".sss..", "sssss.", "ssssss", "s.s.ss", "s.s.s.", "..s.s."],
            {"s": "stoneDark" if dk else "stoneMid", "S": "stone"})


def frame(k):
    f = Frame(110, 110, seed=53)
    p = P[k]
    dy, ln, hem, sw = p["dy"], p.get("lean", 0), p["hem"], p["arm"]
    hip = (48, 62 + dy)
    sh = (64 + ln, 27 + dy)                    # the shoulders
    hump = (52 + ln * 0.7, 26 + dy)
    # the cloak: from the hump down the back, trailing, torn to strips
    f.poly([(46 + ln * 0.6, 15 + dy), (30 + ln * 0.3, 26 + dy), (16 - hem, 58 + dy), (8 - hem * 2, 98), (12 - hem, 106),
            (34 - hem, 104), (44, 70 + dy), (56 + ln * 0.5, 30 + dy)], RAG, dk=1, fold=0.55, skew=0.22, phase=hem * 0.3)
    f.tatter(4, 40, 13, 16, shift=hem, y_min=74)
    # far leg and far arm
    leg(f, (hip[0] + 3, hip[1]), (p["ff"][0], 108 - p["ff"][1]), 24, 25, 3.6, 2.8, 2.2, HUSK, dk=1)
    f.seg((p["ff"][0] - 2, 108 - p["ff"][1]), (p["ff"][0] + 6, 108 - p["ff"][1]), 1.6, 1.3, HUSK, dk=1)
    fh = (84 + ln - sw * 1.5, 95 + dy)
    el = ik((sh[0] + 3, sh[1] + 2), fh, 34, 36, 1)
    f.seg((sh[0] + 3, sh[1] + 2), el, 2.6, 2.0, HUSK, dk=1)
    f.seg(el, fh, 2.0, 1.6, HUSK, dk=1)
    hand(f, fh[0], fh[1], 1)
    # the pelvis and the spine
    f.ell(hip, 6.5, 5, HUSK)
    f.seg(hip, (56 + ln * 0.5, 44 + dy), 3.2, 3.0, HUSK)
    # the chest: a cage of ribs around the ember heart
    c = (60 + ln * 0.8, 40 + dy)
    f.ell(c, 11.5, 12.5, ["nightDeep"] * 4, tex=0)
    heart = [("emberDim", "emberDim", "ember"), ("emberDim", "ember", "fireOrange"), ("emberDim", "ember", "ember"),
             ("ember", "fireOrange", "fireGold")][p["heart"]]
    for (rx, ry, g) in ((6.5, 7.5, heart[0]), (4, 5, heart[1]), (1.8, 2.4, heart[2])):
        for y in range(int(c[1] + 1 - ry - 1), int(c[1] + 1 + ry + 2)):
            for x in range(int(c[0] + 1 - rx - 1), int(c[0] + 1 + rx + 2)):
                if ((x - c[0] - 1) / rx) ** 2 + ((y - c[1] - 1) / ry) ** 2 <= 1 and (x + y) % 2 == (0 if g == heart[0] else (x + y) % 2):
                    f.glow(x, y, g, "tile")
    for i in range(6):                           # the ribs: pale bars bent round the cage, two of them broken
        y = c[1] - 10 + i * 4
        half = 11.5 * (1 - ((y - c[1]) / 12.5) ** 2) ** 0.5
        x0, x1 = c[0] - half + 1, c[0] + half - 1
        if i == 2:
            x1 -= 7
        if i == 4:
            x0 += 6
        f.line((x0, y + 1), (x1, y - 1), "stoneMid")
        f.line((x0 + 1, y + 2), (x1 - 1, y), "stoneDark")
        f.put(x1, y - 1, "stone")
    f.seg((c[0] - 9, c[1] - 12), (c[0] - 11, c[1] + 10), 2.0, 1.6, HUSK)          # the spine behind the cage
    # the hump and the cloak over the shoulders
    f.ell(hump, 15, 10.5, RAG, fold=0.6, skew=-0.4, phase=hem * 0.3)
    f.ell((sh[0] - 2, sh[1] + 1), 8, 6.5, RAG, fold=0.6, skew=-0.4)
    for i, x in enumerate(range(int(hump[0]) - 10, int(hump[0]) + 16, 2)):       # rags hanging from its edge
        y = hump[1] + 10.5 * (1 - min(1, ((x - hump[0]) / 15) ** 2)) ** 0.5
        n = (3, 7, 2, 9, 4, 6, 2, 8, 3, 5, 2, 6, 3)[i]
        o = hem if n > 5 else 0
        f.line((x, y), (x - o * 0.5, y + n), "soilDark" if i % 2 else "moorDark")
    # near leg
    foot = (p["nf"][0], 108 - p["nf"][1])
    if "knee" in p:
        f.seg(hip, p["knee"], 4.2, 3.2, HUSK)
        f.seg(p["knee"], foot, 3.2, 2.4, HUSK)
    else:
        leg(f, hip, foot, 24, 25, 4.2, 3.2, 2.4, HUSK)
    f.seg((foot[0] - 2, foot[1]), (foot[0] + 7, foot[1]), 1.8, 1.4, HUSK)
    # the neck and the head: hanging forward, lower than the hump, the hood torn, the jaw open
    hx, hy = 78 + ln * 1.4, 30 + dy + (2 if k == 5 else 0)
    f.seg((sh[0] + 3, sh[1]), (hx + 2, hy + 3), 3.0, 2.6, HUSK)
    f.stamp(int(hx), int(hy), ["..rrrrrr....",
                               ".rrrrrrrrr..",
                               "rrrrssssssr.",
                               "rrrssssssss.",
                               "rrssoossooss",
                               "rrssoEssoEss",
                               "rrsssessses.",
                               ".rsssdsssd..",
                               ".rrsssssss..",
                               "..rssjjjjs..",
                               "..r.sjjjjs..",
                               "..r.sjjjjs..",
                               ".r..ssjjss..",
                               ".....ssss..."],
            {"r": "moorDark", "s": "stoneMid", "o": "night0", "j": "night0",
             "E": ("stoneLight", "wraithWhite"), "e": ("stone", "wraithGlow"), "d": ("stoneDark", "wraithDim")})
    # the near arm: too long, the hand almost on the ground
    nh = (88 + ln + sw * 1.5, 97 + dy * 0.5)
    el = ik(sh, nh, 34, 38, 1)
    f.seg(sh, el, 3.4, 2.6, HUSK)
    f.seg(el, nh, 2.6, 2.0, HUSK)
    hand(f, nh[0], nh[1], 0)
    f.crack([(el[0] - 1, el[1] - 4), (el[0], el[1]), (el[0] + 2, el[1] + 5), (el[0] + 2, el[1] + 9)])
    return f.finish()
