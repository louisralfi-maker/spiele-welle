#!/usr/bin/env python3
"""Lanternhold art pass (look 2, stage 6; ART-look2.md section 18): the defences redrawn at the town's level. Pure
python on pixelart.py's Image; palette colours only; no randomness (hashes of the position), so a run reproduces its
files byte for byte. Called by tools/build-art-buildings.sh after a defence's grid is written:

  defenceart.py repaint <sprite.png> <id>      in place

The grid (tools/grids/buildings/, the M2b block language: every block outlined, lips and bevels) gives the sprite's
silhouette, its frames and its features; this paints the materials new inside it:
  stone   coursed ashlar as on the town's stone floors (courses 4 rows high, stones of 6 to 8 px with a split one
          here and there, lit top edges on the lit side only, soft shadowed beds instead of dark joint rows, a stone
          here and there paler or darker), shaded as a body (round: a lit band left of the middle, the side turning
          away two steps darker; flat: a lit left edge, the right quarter a step darker), a lit cap on every top
          edge, a cast shadow under a projecting crown and to the right of a banner, moss and damp at the foot;
  timber  the grid's members with the light from the upper left, grain, and the ink between members softened to
          the timber's dark;
  iron    (fire baskets, the great bowl, portcullis bars, fittings: stone colours inside a spec's iron boxes) the
          grid's values, lit left, a step darker right.
Look 2's selective outline: ink stays at the right and at the ground, the left edge is lit, the top edge is a cap.
Slits, holes, soot, banners, glass and every other colour stay as the grid sets them. In a damaged frame every pixel
that differs from frame 0 stays as the grid sets it too (cracks, knocked-out stones, fresh pale breaks). The alpha
of every pixel is the grid's, so sizes, frames and anchors hold.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import pixelart as PA  # noqa: E402
import worldart as WA  # noqa: E402

col, h01 = WA.col, WA.h01
STONES = ("stoneDark", "stoneMid", "stone", "stoneLight", "stonePale")
WOODS = ("woodDark", "wood", "woodLight", "straw", "strawLight")
ALL = ((0, 0, 999, 999),)

# id: frames, form of the stone body, block length, tone offset (the beacon's first two stages a step paler, as the
# ruin they grow from; the great beacon at the walls' tone, so its lit face holds under the beacon's light), iron boxes
# (frame coordinates), damaged frames, joints (night pixels of the old rubble count as stone), lips (pale string courses)
SPEC = {
    "palisade": dict(frames=2, damage=True),
    "stoneWall": dict(frames=2, form="flat", block=7, damage=True, joints=True, lips=(14, 43)),
    "bastion": dict(frames=2, form="flat", block=8, damage=True),
    "archerTower": dict(frames=1, iron=ALL),
    "watchtower": dict(frames=1, form="round", block=6),
    "fireTower": dict(frames=1, form="round", block=4, plain=True, iron=((0, 0, 13, 4),)),
    "beaconTower": dict(frames=1, form="round", block=8, tone=1),
    "greatBeacon": dict(frames=1, form="round", block=8, iron=((0, 0, 63, 25),)),
    "beaconBase-front": dict(frames=1, form="round", block=8, tone=1),
    "gateWood": dict(frames=3, iron=ALL, damage=True),
    "gateIron": dict(frames=3, iron=ALL, damage=True),
    "gateGreat": dict(frames=3, iron=ALL, damage=True),
    "gateBroken": dict(frames=1, iron=ALL),
    "ballista": dict(frames=2, iron=ALL),
    "catapult": dict(frames=3, iron=ALL),
    "stakePit": dict(frames=2, iron=ALL),
    "brazier": dict(frames=1, iron=ALL),
    "torchPost": dict(frames=1, iron=ALL),
}


def repaint(im, name):
    sp = SPEC[name]
    frames, form, bl = sp["frames"], sp.get("form", "flat"), sp.get("block", 7)
    tone, boxes, damage = sp.get("tone", 0), sp.get("iron", ()), sp.get("damage", False)
    joints, lips, plain = sp.get("joints", False), sp.get("lips", ()), sp.get("plain", False)
    hi = min(4, 4 + tone)
    seed = sorted(SPEC).index(name) + 11
    fw, H, ch = im.w // frames, im.h, 4
    ink = col("ink")
    sidx = dict((col(n), i) for i, n in enumerate(STONES))
    widx = dict((col(n), i) for i, n in enumerate(WOODS))
    src = [[im.get(x, y) for x in range(im.w)] for y in range(H)]

    for f in range(frames):
        x0 = f * fw

        def clear(x, y):
            return x < x0 or x >= x0 + fw or y < 0 or y >= H or src[y][x][3] == 0

        def kind(x, y):
            if clear(x, y):
                return None
            c = src[y][x]
            if c == ink:
                return "k"
            if c in sidx:
                fx = x - x0
                for (a, b, c2, d) in boxes:
                    if a <= fx <= c2 and b <= y <= d:
                        return "i"
                return "s"
            if joints and c[:3] in NIGHTS and y < H - 1:
                return "s"                                          # the old rubble's deep joints
            return "w" if c in widx else "f"

        nearc = {}

        def near(x, y):  # the material an ink pixel belongs to
            if (x, y) not in nearc:
                m = None
                for d in (1, 2, 3):
                    for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                        k = kind(x + dx * d, y + dy * d)
                        if k in ("s", "w", "i"):
                            m = k
                            break
                    if m:
                        break
                nearc[(x, y)] = m
            return nearc[(x, y)]

        ext, wext, iext = {}, {}, {}
        for y in range(H):
            for x in range(x0, x0 + fw):
                k = kind(x, y)
                if k == "k":
                    k = near(x, y)
                d = {"s": ext, "w": wext, "i": iext}.get(k)
                if d is not None:
                    a, b = d.get(y, (x, x))
                    d[y] = (min(a, x), max(b, x))

        def stone(x, y, cap=False):
            a, b = ext.get(y, (x, x))
            t = (x - a) / float(max(1, b - a)) + (0.03 if y % 2 else -0.03)
            if form == "round":
                fo = 0 if t < 0.05 else 1 if t < 0.36 else 0 if t < 0.64 else -1 if t < 0.86 else -2
            else:
                fo = 1 if t < 0.10 else 0 if t < 0.84 else -1
            yb = H - 1 - y
            k, r = yb // ch, ch - 1 - yb % ch
            sx = (x - x0) + k * 3 + int(h01(seed, k) * 5)
            n = sx // bl
            v = h01(seed, k, n)
            i = 2 if plain else 1 if v > 0.80 else 3 if v < 0.12 else 2
            if r == 0 and fo >= 0:
                i += 1
            if r == ch - 1:
                i -= 2 if h01(seed, x, y, 2) < 0.3 else 1
            i += fo + tone
            if sx % bl == 0 or (bl >= 6 and 0.3 < v < 0.5 and sx % bl == bl // 2):
                i -= 2 if 0 < r < ch - 1 and fo >= 0 else 1
            if y in lips:
                i = hi + min(0, fo)
            elif y - 1 in lips:
                i -= 1
            for dy in (1, 2, 3):
                if y - dy in ext and ext[y - dy][0] < a and ext[y - dy][1] > b:
                    i -= 1
                    break
            if kind(x - 1, y) == "f" and src[y][x - 1][:3] not in NIGHTS:
                i -= 1
            if yb < 2:
                i -= 1
            i = max(0, min(hi, i))
            if cap:
                i = hi if fo >= 0 else hi - 1
            c = STONES[i]
            if yb < 5 and h01(seed, x // 2, y, 7) < (0.2 if yb < 3 else 0.08):
                c = "leafDark" if h01(seed, x, y, 9) < 0.7 else "leaf"
            return c

        def wood(x, y, i):
            a, b = wext.get(y, (x, x))
            if b - a >= 4:
                t = (x - a) / float(b - a) + (0.03 if y % 2 else -0.03)
                if t < 0.24 and i > 0:
                    i = min(3, i + 1)
                elif t > 0.72 and i > 1:
                    i -= 1
            if i == 1 and h01(seed, x, y // 3, 5) < 0.07:
                i = 0
            elif i == 2 and h01(seed, x, y // 4, 6) < 0.06:
                i = 1
            return WOODS[i]

        def iron(x, y, i):
            a, b = iext.get(y, (x, x))
            if b - a >= 4:
                t = (x - a) / float(b - a)
                if t < 0.22 and i < 3:
                    i += 1
                elif t > 0.72 and i > 0:
                    i -= 1
            return STONES[i]

        for y in range(H):
            for x in range(x0, x0 + fw):
                k = kind(x, y)
                if k in (None, "f"):
                    continue
                c = src[y][x]
                if damage and f > 0:
                    c0 = src[y][x - x0]
                    if c0[3] and c0 != c and not (c == ink and (clear(x - 1, y) or clear(x, y - 1))
                                                  and not clear(x, y + 1) and not clear(x + 1, y)):
                        continue                                    # a damage pixel: as the grid sets it
                if k == "s":
                    im.set(x, y, col(stone(x, y, clear(x, y - 1))))
                elif k == "w":
                    im.set(x, y, col(wood(x, y, widx[c])))
                elif k == "i":
                    im.set(x, y, col(iron(x, y, sidx[c])))
                else:                                               # ink
                    m = near(x, y)
                    if m is None or clear(x, y + 1) or clear(x + 1, y):
                        continue                                    # the outline at the ground and on the shade side
                    left, top = clear(x - 1, y), clear(x, y - 1)
                    if m == "s":
                        if not left and not top and any(kind(x + dx, y + dy) in ("w", "f")
                                                        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                            im.set(x, y, col("stoneDark"))          # the reveal round a door, a slit, a banner
                        else:
                            im.set(x, y, col(stone(x, y, top)))
                    elif m == "w":
                        im.set(x, y, col("woodLight" if left or top else "woodDark"))
                    elif left or top:
                        im.set(x, y, col("stoneMid"))


NIGHTS = tuple(col(n)[:3] for n in ("night0", "night1", "night2"))


def main():
    a = sys.argv[1:]
    if len(a) != 3 or a[0] != "repaint":
        raise SystemExit(__doc__)
    im = PA.read_png(a[1])[0]
    repaint(im, a[2])
    PA.write_png(a[1], im)
    print("repainted %s" % os.path.basename(a[1]))


if __name__ == "__main__":
    main()
