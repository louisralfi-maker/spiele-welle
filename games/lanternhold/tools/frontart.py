#!/usr/bin/env python3
"""Lanternhold art pass (look 2; ART-look2.md section 17): the castle's chapel and kitchen fronts, repainted at the
town's level (tools/townart.py's vocabulary) inside their old silhouettes. Pure python on pixelart.py's Image; palette
colours only; no randomness (hashes of the position), so a run reproduces its files byte for byte.

  frontart.py repaint <chapel|kitchen> <sprite.png>     in place

The sprite on disk (the Recraft conversion of build-art.sh) gives only the silhouette: every opaque pixel is painted
anew, no transparent one is touched, so chapelInterior and kitchenInterior (roomscenes.py paints them inside the
fronts' silhouettes) keep their outlines. The window glass (night1) stays inside the masks of ART-court.md: the
chapel's lancets x 24-33, 60-69, 95-104 (rows 53-76) and 129-137 (rows 53-75), the kitchen's panes x 30-32, 34-36 and
84-86, 88-90 (rows 41-43, 45-47). Albedo only, the light from the upper left: lit left edges and roof slopes, a cast
shadow under every eave and beside every buttress, the right end a step darker, look 2's selective outline (ink only
at the right and at the ground).
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import pixelart as PA  # noqa: E402
import worldart as WA  # noqa: E402
import townart as TA  # noqa: E402

col, h01 = WA.col, WA.h01
px, rect = TA.px, TA.rect
DOWN = {"stonePale": "stoneLight", "stoneLight": "stone", "stone": "stoneMid", "stoneMid": "stoneDark",
        "plaster": "plasterDim", "parchment": "plaster", "roofLight": "banner", "banner": "roofDeep",
        "woodLight": "wood", "wood": "woodDark"}


def opaque(im, x, y):
    return 0 <= x < im.w and 0 <= y < im.h and im.get(x, y)[3] != 0


def span(src, y, x0=0, x1=None):
    """The first and the last opaque column of the silhouette's row y between x0 and x1."""
    xs = [x for x in range(x0, (src.w - 1 if x1 is None else x1) + 1) if opaque(src, x, y)]
    return (xs[0], xs[-1]) if xs else (x0, x0 - 1)


def darker(im, x0, y0, x1, y1):
    """A cast shadow: every stone, plaster, slate and wood pixel of the box one step down its ramp."""
    names = {col(a): b for a, b in DOWN.items()}
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            if 0 <= x < im.w and 0 <= y < im.h and im.get(x, y) in names:
                im.set(x, y, col(names[im.get(x, y)]))


def ashlar(im, x0, y0, x1, y1, seed, ch=5, wmin=7, wmax=12, body=("stone", "stoneLight", "stoneMid")):
    """Dressed stone: courses ch rows high (the last row the bed joint), blocks wmin to wmax px, staggered; a block's
    top row lit, its foot row a step darker at the right, head joints dark."""
    B, L, D = body
    for y in range(y0, y1 + 1):
        k, r = (y - y0) // ch, (y - y0) % ch
        off = int(h01(seed, k, 1) * wmax)
        for x in range(x0, x1 + 1):
            sx = x + off
            n = sx // wmax
            bw = wmin + int(h01(seed, k, n, 2) * (wmax - wmin + 1))
            i = sx % wmax
            v = h01(seed, k, n, 3)
            face = B if v < 0.62 else L if v < 0.84 else D
            c = face
            if r == ch - 1:
                c = "stoneMid" if h01(seed, k, x // 6, 4) < 0.75 else "stoneDark"
            elif i == 0 or i == bw:
                c = "stoneDark" if h01(seed, k, n, i, 5) < 0.6 else "stoneMid"
            elif r == 0 and i < bw - 2:
                c = {B: L, L: "stonePale", D: B}[face]
            elif r == ch - 2 and i > bw // 2:
                c = {B: D, L: B, D: D}[face]
            px(im, x, y, c)


def lancet(im, x0, x1, y0, y1):
    """A pointed window whose glass lies in the box x0..x1, y0..y1 (night1): dressed jambs with quoins, a pointed
    hood, two saddle bars (stoneDark: they stay dark in a lit window), a pale sill over its shadow."""
    for y in range(y0, y1 + 1):
        k = y - y0
        a, b = x0 + max(0, 4 - k), x1 - max(0, 4 - k)
        rect(im, a, y, b, y, "stoneDark" if k in (10, 17) else "night1")
        q = k > 5 and (k // 3) % 2 == 0
        rect(im, a - (2 if q else 1), y, a - 1, y, "stonePale")
        rect(im, b + 1, y, b + (2 if q else 1), y, "stoneLight")
        if k <= 4:                                                   # the hood follows the point
            px(im, a - 1, y - 1, "stonePale")
            px(im, b + 1, y - 1, "stoneLight")
    rect(im, x0 + 4, y0 - 1, x1 - 4, y0 - 1, "stonePale")
    rect(im, x0 - 2, y1 + 1, x1 + 2, y1 + 1, "stonePale")
    px(im, x1 + 2, y1 + 1, "stoneLight")
    rect(im, x0 - 1, y1 + 2, x1 + 2, y1 + 2, "stoneDark")


def buttress(im, x, seed, top=49, step=60, foot=94):
    """A two-stage buttress: the lower stage's lit face x..x+4 and its shaded side x+5..x+9, the upper stage set back
    (face x+3..x+7, side x+8, x+9) under sloped weatherings of pale stone."""
    for y in range(top, foot + 1):
        up = y < step
        f0, f1, s1 = (x + 3, x + 7, x + 9) if up else (x, x + 4, x + 9)
        joint = (y - top) % 5 == 4
        for xx in range(f0, f1 + 1):
            v = h01(seed, xx // 3, (y - top) // 5)
            c = "stonePale" if xx == f0 else "stoneLight" if v < 0.7 else "stone"
            if joint:
                c = "stoneLight" if xx == f0 else "stone"
            px(im, xx, y, c)
        for xx in range(f1 + 1, s1 + 1):
            px(im, xx, y, "stoneDark" if joint else "stoneMid")
    for i in range(3):                                               # the weatherings
        rect(im, x + i, step - 3 + i, x + 3, step - 3 + i, "stonePale")
        rect(im, x + 3 + i, top - 3 + i, x + 6, top - 3 + i, "stonePale")
        px(im, x + 7, top - 3 + i, "stoneLight")
    rect(im, x + 4, step - 1, x + 9, step - 1, "stoneLight")
    darker(im, x + 10, top, x + 11, foot)                            # its cast shadow on the wall


def finish(im, src, fill="stone"):
    """Clip to the old silhouette (an unpainted opaque pixel takes `fill`), then look 2's selective outline: ink where
    the body ends at the right and at the ground."""
    ink = col("ink")
    for y in range(im.h):
        for x in range(im.w):
            if not opaque(src, x, y):
                im.set(x, y, (0, 0, 0, 0))
            elif im.get(x, y)[3] == 0:
                im.set(x, y, col(fill))
    for y in range(im.h):
        for x in range(im.w):
            if opaque(src, x, y) and (not opaque(src, x + 1, y) or not opaque(src, x, y + 1)):
                im.set(x, y, ink)
    return im


# --- the chapel of the Flame (160x96) ---------------------------------------------------------------------------------
def chapel(src):
    im = PA.Image(160, 96)
    seed = 211
    # the nave's wall, the west corner beside the roof's end, the plinth
    ashlar(im, 2, 37, 158, 94, seed)
    darker(im, 6, 47, 114, 48)                                       # the eave's cast shadow
    rect(im, 2, 90, 158, 90, "stonePale")
    for x in range(2, 159):
        for y in range(91, 95):
            px(im, x, y, "stoneDark" if x % 13 == 5 else "stone" if y < 93 else "stoneMid")
        if h01(seed, x // 2, 7) < 0.14:
            px(im, x, 94, "leafDark")
            px(im, x, 93, "leaf" if h01(seed, x, 8) < 0.5 else "leafDark")
    for x0, x1 in ((24, 33), (60, 69), (95, 104)):
        lancet(im, x0, x1, 53, 76)
    for i, x in enumerate((7, 41, 77, 111)):
        buttress(im, x, seed + i)
    # the gabled bay at the right: its wall, the lancet, the Flame's gilded emblem, the door, the corner buttress
    ashlar(im, 116, 23, 158, 89, seed + 9, wmin=6, wmax=10)
    darker(im, 144, 23, 158, 89)
    for y in range(61, 95):                                          # the right corner's buttress
        j = (y - 61) % 5 == 4
        rect(im, 146, y, 150, y, "stone" if j else "stoneLight")
        px(im, 146, y, "stonePale")
        rect(im, 151, y, 158, y, "stoneDark" if j else "stoneMid")
    for i in range(3):
        rect(im, 146 + i, 58 + i, 150, 58 + i, "stonePale")
    lancet(im, 129, 137, 53, 75)
    for y, (a, b) in zip(range(35, 43), ((133, 133), (133, 133), (132, 134), (132, 134), (131, 135), (131, 135),
                                         (131, 135), (132, 134))):
        rect(im, a - 2, y, b + 2, y, "stoneMid")
        rect(im, a, y, b, y, "gold")
        px(im, a, y, "strawLight")
    rect(im, 132, 43, 134, 43, "stoneDark")
    px(im, 133, 40, "tileLight"); px(im, 133, 41, "tileLight")
    for y in range(80, 95):                                          # a pointed oak door in a dressed arch
        k = y - 80
        a, b = 128 + max(0, 4 - 2 * k), 138 - max(0, 4 - 2 * k)
        rect(im, a - 2, y, a - 1, y, "stonePale" if (k // 3) % 2 else "stoneLight")
        rect(im, b + 1, y, b + 2, y, "stoneLight" if (k // 3) % 2 else "stone")
        for x in range(a, b + 1):
            px(im, x, y, ("woodLight", "wood", "wood", "woodDark")[(x - 128) % 4])
        if k < 3:
            rect(im, a - 1, y - 1, b + 1, y - 1, "stonePale")
    for y in (85, 91):
        rect(im, 128, y, 138, y, "stoneMid")
        px(im, 129, y, "stoneLight"); px(im, 137, y, "stoneLight")
    rect(im, 133, 82, 133, 94, "woodDark")
    px(im, 135, 88, "gold"); px(im, 131, 88, "gold")
    rect(im, 126, 94, 140, 94, "stoneLight")
    # the nave's roof: teal slate, its lit slope, the gable's rake before its right end
    xl = lambda y: 40 if y <= 36 else int(round(30 - (y - 37) * 1.75))   # noqa: E731
    xr = lambda y: int(round(127 - (y - 27) * 12 / 19.0))                # noqa: E731
    TA.roof(im, 27, 46, xl, xr, TA.SLATE, "slate", seed, mid=0.6, shade=9)
    for y in range(23, 47):                                          # the gable's coping
        a = xr(y) + 1 if y >= 27 else span(src, y, 110)[0]
        b = span(src, y, 110)[1]
        rect(im, a, y, a + 1, y, "stonePale")
        px(im, a + 2, y, "stoneLight")
        rect(im, b - 2, y, b, y, "stoneLight")
    # the bell tower: a lit front, a shaded side, louvred openings, the string courses
    ashlar(im, 13, 16, 26, 36, seed + 3, ch=4, wmin=5, wmax=8)
    ashlar(im, 27, 16, 39, 36, seed + 4, ch=4, wmin=5, wmax=8, body=("stoneMid", "stone", "stoneDark"))
    rect(im, 15, 17, 15, 36, "stonePale")
    for y in range(18, 28):
        k = y - 18
        a, b = 19 + max(0, 2 - k), 25 - max(0, 2 - k)
        rect(im, a, y, b, y, "night1" if k % 2 == 0 or k < 2 else "stoneDark")
        px(im, a - 1, y, "stonePale"); px(im, b + 1, y, "stoneLight")
        if k < 3:
            px(im, a, y - 1, "stonePale"); px(im, b, y - 1, "stonePale")
        if y >= 21:
            rect(im, 31, y, 34, y, "night1" if k % 2 == 0 else "ink")
            px(im, 30, y, "stone"); px(im, 35, y, "stoneDark")
    rect(im, 21, 17, 23, 17, "stonePale")
    rect(im, 31, 20, 34, 20, "stone")
    rect(im, 14, 28, 26, 28, "stonePale"); rect(im, 27, 28, 40, 28, "stone")
    rect(im, 14, 29, 40, 29, "stoneDark")
    rect(im, 14, 16, 26, 16, "stoneMid"); rect(im, 27, 16, 40, 16, "stoneDark")
    # the spire: its lit and its shaded face, the broach's eave, a gilded finial
    E, S, D, B, L = TA.SLATE
    for y in range(0, 16):
        a, b = span(src, y, 0, 45)
        ridge = 29 + y // 3
        for x in range(a, b + 1):
            v, r = h01(seed, x // 3 + (y // 3) % 2, y // 3, 6), y % 3
            if y >= 13:
                c = (L if x < ridge else B) if y == 13 else (B if x < ridge else D) if y == 14 else E
            elif x < ridge:
                c = L if r == 0 and v < 0.6 else D if r == 2 else B
            else:
                c = B if r == 0 and v < 0.35 else S if r == 2 else D
            px(im, x, y, c)
        px(im, a, y, L)
    px(im, 27, 0, "gold"); px(im, 27, 1, "gold"); px(im, 26, 1, "strawLight")
    rect(im, 0, 95, 159, 95, "ink")
    return finish(im, src)


# --- the castle kitchen (120x80) --------------------------------------------------------------------------------------
def kitchen(src):
    im = PA.Image(120, 80)
    seed = 131
    # the ground floor of grey stone under the jetty, its plinth, the arched double door
    TA.rubble(im, 6, 58, 113, 79, seed, eave=3)
    TA.fieldstone(im, 6, 75, 113, 78, seed)
    rect(im, 6, 57, 113, 57, "ink")
    for x in range(10, 112, 12):
        px(im, x, 57, "wood"); px(im, x + 1, 57, "woodDark")
        px(im, x, 58, "woodDark")
    for y in range(63, 80):
        k = y - 63
        a, b = 54 + max(0, 3 - k) * 2, 70 - max(0, 3 - k) * 2
        if k:
            rect(im, a - 2, y, a - 1, y, "stonePale" if (k // 3) % 2 else "stoneLight")
            rect(im, b + 1, y, b + 2, y, "stoneLight" if (k // 3) % 2 else "stone")
        if k < 4:
            for x in range(a, b + 1):
                px(im, x, y - 1 if k else y, "stonePale" if (x // 3) % 2 else "stoneLight")
        if k:
            for x in range(a, b + 1):
                px(im, x, y, ("woodLight", "wood", "wood", "woodDark")[(x - 54) % 4])
    rect(im, 62, 64, 62, 79, "woodDark")
    for y in (68, 75):
        rect(im, 54, y, 70, y, "stoneMid")
        px(im, 55, y, "stoneLight"); px(im, 69, y, "stoneLight")
    px(im, 60, 72, "stonePale"); px(im, 64, 72, "stonePale")
    px(im, 60, 73, "stoneMid"); px(im, 64, 73, "stoneMid")
    TA.barrel(im, 22, 78, w=6, h=8)
    TA.barrel(im, 29, 78, w=5, h=6)
    TA.woodpile(im, 82, 78, 6, 4)
    TA.vine(im, 13, 61, 78, seed, w=3)
    for x, c in ((40, "leaf"), (41, "meadow"), (42, "leaf"), (45, "leafDark"), (46, "leaf")):   # herb pots by the door
        px(im, x, 75, c); px(im, x, 76, c if x % 2 else "leafDark")
    rect(im, 40, 77, 42, 78, "tile"); rect(im, 45, 77, 46, 78, "tile")
    px(im, 40, 77, "tileLight"); px(im, 45, 77, "tileLight")
    darker(im, 98, 58, 113, 79)
    # the jettied storey: plaster between oak posts, studs and braces, two shuttered windows over herb boxes
    TA.plaster(im, 5, 36, 114, 53, seed + 1, shade_from=104, eave=2)
    TA.beam(im, 5, 114, 36, h=1, lit=False)
    for x in (5, 57, 111):
        TA.post(im, x, 36, 53, w=4)
    for x in (20, 44, 72, 98):
        TA.post(im, x, 37, 53)
    TA.brace(im, 18, 40, -1, 9); TA.brace(im, 101, 40, 1, 9)
    TA.brace(im, 55, 40, -1, 8); TA.brace(im, 62, 40, 1, 8)
    TA.window(im, 30, 41, 7, 7, shutters=TA.TEAL, box=True)
    TA.window(im, 84, 41, 7, 7, shutters=TA.TEAL, box=True)
    TA.jetty(im, 5, 114, 54)
    # the hipped slate roof, its ridge knob, the big stack before it
    xl = lambda y: span(src, y)[0]                                    # noqa: E731
    xr = lambda y: span(src, y)[1]                                    # noqa: E731
    TA.roof(im, 11, 35, xl, xr, TA.SLATE, "slate", seed, mid=0.55, shade=11)
    E, S, D, B, L = TA.SLATE
    rect(im, 21, 9, 28, 13, B)
    rect(im, 21, 9, 27, 9, L); rect(im, 21, 9, 21, 13, L)
    rect(im, 22, 13, 28, 13, D)
    for y in range(0, 21):                                           # the stack: three capped flues on a stone body
        a, b = span(src, y, 70) if y < 9 else (77, span(src, y, 70)[1])
        for x in range(a, b + 1):
            k, r = y // 4, y % 4
            v = h01(seed + 5, k, (x + k * 3) // 6)
            t = (x - a) / float(max(1, b - a))
            c = "stoneLight" if v < 0.6 else "stone"
            if r == 3 or (x + k * 3) % 6 == 0:
                c = "stone" if r == 3 else "stoneMid"
            if y == 0 or y == 9:
                c = "stonePale"
            if y in (6, 7):
                c = "stoneMid" if y == 6 else "stoneDark"
            if t > 0.66:
                c = DOWN.get(c, c)
            if x == a:
                c = "stonePale"
            px(im, x, y, c)
    rect(im, 77, 21, 103, 21, "ink")
    return finish(im, src)


BUILD = {"chapel": chapel, "kitchen": kitchen}


def main():
    a = sys.argv[1:]
    if len(a) != 3 or a[0] != "repaint" or a[1] not in BUILD:
        raise SystemExit(__doc__)
    src = PA.read_png(a[2])[0]
    im = BUILD[a[1]](src)
    PA.write_png(a[2], im)
    print("repainted %s %dx%d" % (os.path.basename(a[2]), im.w, im.h))


if __name__ == "__main__":
    main()
