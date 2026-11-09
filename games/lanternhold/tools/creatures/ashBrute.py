"""Ash Brute: a swollen giant in a tattered cloak. A hump higher than its head, the small head sunk between the
shoulders, one huge arm it walks on, one withered arm, and strapped to its back the pole of a night watchman's
lantern: the smashed cage dangles dead above its face."""
from rig import Frame, ik, leg, EYE, HUSK, ASH, RAG

SIZE = (44, 44, 7)
# walk 0-3 at 4 px a frame: a planted foot or fist moves back 4 px a frame, the other swings
P = [dict(dy=1, nf=(23, 0), ff=(15, 0), fist=(31, 39), sw=0, hem=0),
     dict(dy=0, nf=(19, 0), ff=(19, 3), fist=(35, 34), sw=1, hem=1),
     dict(dy=1, nf=(15, 0), ff=(23, 0), fist=(39, 39), sw=0, hem=0),
     dict(dy=0, nf=(19, 3), ff=(19, 0), fist=(35, 39), sw=-1, hem=-1),
     # attack 4-6: rears back with the fist high, slams it down, holds
     dict(dy=-1, nf=(20, 0), ff=(14, 0), fist=(26, 6), sw=-2, hem=-1, lean=-3),
     dict(dy=2, nf=(22, 0), ff=(13, 0), fist=(39, 39), sw=3, hem=2, lean=3),
     dict(dy=2, nf=(22, 0), ff=(13, 0), fist=(38, 39), sw=1, hem=1, lean=2)]


def frame(k):
    f = Frame(44, 44, seed=11)
    p = P[k]
    dy, ln, hem, sw = p["dy"], p.get("lean", 0), p["hem"], p["sw"]
    hip = (17, 30 + dy)
    sh = (25 + ln, 14 + dy)
    hump = (15 + ln * 0.6, 15 + dy)
    # the cloak hanging behind, torn
    f.poly([(8 + ln * 0.5, 9 + dy), (3 + hem, 24 + dy), (2 + hem * 2, 38 + dy), (13 + hem, 39 + dy), (16, 22 + dy)],
           RAG, dk=1, fold=1.1, skew=0.25)
    f.tatter(1, 15, 5, 6, shift=hem)
    # far leg, far arm (withered, hanging)
    leg(f, (hip[0] + 2, hip[1]), (p["ff"][0], 43 - p["ff"][1]), 7, 7.5, 3, 2.6, 2.2, HUSK, dk=1)
    f.seg((p["ff"][0] - 1, 43 - p["ff"][1]), (p["ff"][0] + 3, 43 - p["ff"][1]), 1.2, 1.0, HUSK, dk=1)
    hand = (33 + ln - sw, 33 + dy)
    el = ik((29 + ln, 15 + dy), hand, 9, 10, 1)
    f.seg((29 + ln, 15 + dy), el, 1.2, 0.9, ASH, dk=1)
    f.seg(el, hand, 0.9, 0.7, ASH, dk=1)
    f.stamp(int(hand[0]) - 1, int(hand[1]), ["sss", "s.s", "s.s"], {"s": "stoneDark"})
    # the belly (bare, splitting), the hump under the cloak
    f.ell((22 + ln * 0.4, 25 + dy), 8.5, 7.5, HUSK)
    f.ell(hump, 11.5, 9.5, RAG, fold=0.9, skew=-0.5, phase=hem * 0.4)
    f.ell((sh[0] - 1, sh[1] + 1), 5.5, 5, RAG, fold=0.9, skew=-0.5)
    for i, x in enumerate(range(int(hump[0]) - 6, int(hump[0]) + 12, 2)):     # rags hanging from the cloak's edge
        y = hump[1] + 9.5 * (1 - ((x - hump[0]) / 11.5) ** 2) ** 0.5
        n = (2, 4, 1, 5, 3, 2, 4, 1, 3)[i]
        f.line((x + (hem if n > 3 else 0), y), (x + (hem if n > 3 else 0), y + n), "soilDark" if i % 2 else "moorDark")
    # near leg
    leg(f, hip, (p["nf"][0], 43 - p["nf"][1]), 7, 7.5, 3.6, 3, 2.4, HUSK)
    f.seg((p["nf"][0] - 1, 43 - p["nf"][1]), (p["nf"][0] + 4, 43 - p["nf"][1]), 1.3, 1.1, HUSK)
    # where the belly splits
    f.crack([(20 + ln * 0.4, 26 + dy), (22 + ln * 0.4, 28 + dy), (21 + ln * 0.4, 31 + dy)])
    f.crack([(25 + ln * 0.4, 26 + dy), (26 + ln * 0.4, 29 + dy)])
    # the watchman's pole across the hump, the dead cage dangling from its tip
    tip = (27 + ln, 1 + max(0, dy))
    f.line((8 + ln * 0.5, 15 + dy), tip, "woodDark")
    f.line((8 + ln * 0.5, 16 + dy), (14 + ln * 0.5, 12 + dy), "woodDark")
    f.norim.update(range(int(tip[0]) - 12, int(tip[0]) + 1))
    cx = tip[0] + 1 + sw
    f.line((tip[0], tip[1] + 1), (cx + 1, tip[1] + 2), "ink")
    f.stamp(cx - 1, tip[1] + 3, ["..i..", ".iii.", "i.o.i", "i...i", ".iii."],
            {"i": "stoneMid", "o": ("tile", "emberDim")})
    # head: small, sunk, hanging forward
    hx, hy = 30 + ln, 12 + dy + (1 if k == 5 else 0)
    f.stamp(hx, hy, [".rrrr.",          # a cowl of rags over a husk head: one socket, one eye low in it, the jaw
                     "rrhHHh",          # hanging (fix stage: no pale skull, never two eyes)
                     "rhhnnH",
                     "rhhnnh",
                     ".hhnE.",
                     ".hddw.",
                     "..dd.."],
            dict(EYE, r="moorDark", h="nightBlue", H="nightSlate", n="nightDeep", d="stoneDark",
                 w=("stoneDark", "wraithDim")))
    # the huge near arm and its fist
    fist = p["fist"]
    el = ik(sh, fist, 12, 13, 1)
    f.seg(sh, el, 3.6, 3.4, HUSK)
    f.seg(el, fist, 3.2, 4.0, HUSK)
    f.ell(fist, 4.6, 4.2, HUSK)
    f.stamp(fist[0] - 2, fist[1] + 1, ["s.s.s"], {"s": "stoneDark"})
    f.crack([(el[0] - 1, el[1] - 1), (el[0] + 1, el[1] + 2), (el[0] + 1, el[1] + 5)])
    # smoke off the hump
    return f.finish()
