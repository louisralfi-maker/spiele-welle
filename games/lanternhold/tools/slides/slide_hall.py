"""Slide 4 of the prologue: "The circlet passed to the last of his blood." (round 1 in the title's language,
litkit.py; HOUSE.md section 1: the heir of the guardian house, never a lamplighter). The hall at night. The house's
great lantern hangs behind the heir, the only light: the heir is rim-lit, and the circlet catches the gold as Odile's
old hands hold it out. The court stands in a loose half ring, told by shape: Brannock broad with a spear, Pip small in
a fool's cap, Bram in the smith's apron; two backs in dark silhouette in the foreground. Real pixel people at the
slide's own scale, no portrait faces. Two files: the Lord and the Lady as the heir; everything else identical.
"""
import math

import numpy as np

from litkit import W, H, Pic, AIR, STONE, air, falloff, pick_air, pick_solid, poly_mask, ellipse_mask, edge_of, h

LANTERN = (160, 40)        # the great lantern's fire
FLOOR = 142
RIM = ["plum", "tile", "tileLight", "gold", "fireGold"]


def hall_wall(p):
    """The back wall: big stone blocks in solid steps of the lantern's light; two pillars turned to the centre."""
    for y in range(FLOOR):
        for x in range(W):
            row = y // 9
            off = 7 if row % 2 else 0
            bx = (x + off) // 16
            t = falloff(bx * 16 - off + 8, row * 9 + 4.5, LANTERN[0], LANTERN[1], 150, 120, 1.2)
            i = int(t * 6.0 * (0.62 if h(bx, row, 70) < 0.8 else 0.8))
            c = (["night0", "nightDeep"] + STONE)[min(7, i)]
            joint = (y % 9 == 8) or ((x + off) % 16 == 15)
            if joint and i > 0:
                c = (["night0", "night0", "nightDeep"] + STONE)[min(7, i)]
            p.px(x, y, c)
    for (x0, x1, face) in ((40, 60, "right"), (260, 280, "left")):
        for y in range(FLOOR):
            for x in range(x0, x1):
                t = falloff(x, (y // 9) * 9 + 4.5, LANTERN[0], LANTERN[1], 170, 130, 1.2)
                turned = (x >= x1 - 6) if face == "right" else (x < x0 + 6)
                i = int(t * 6.0 * (0.85 if turned else 0.3))
                p.px(x, y, (["night0", "nightDeep"] + STONE)[min(7, i)])
            p.px(x1 if face == "right" else x0 - 1, y, "night0")
    # the floor, lit under the lantern in solid steps
    for y in range(FLOOR, H):
        for x in range(W):
            t = falloff((x // 8) * 8 + 4, y, LANTERN[0], FLOOR + 4, 120, 30, 1.1)
            p.px(x, y, (["night0", "nightDeep", "plumDeep", "plum", "tile"])[min(4, int(t * 5.0))])


def great_lantern(p):
    """The house's great lantern: an iron cage of 17 x 24 on a chain, the fire white at its heart."""
    cx, cy = LANTERN
    for y in range(0, cy - 14):
        p.px(cx, y, "nightDeep" if y % 3 else "nightBlue")
    rows = [
        "........i........",
        ".......iii.......",
        ".....iiiiiii.....",
        "...bbbbbbbbbbb...",
        "..iiiiiiiiiiiii..",
        "..i.b.......b.i..",
        "..i.b.......b.i..",
        "..i.b.......b.i..",
        "..i.b.......b.i..",
        "..i.b.......b.i..",
        "..i.b.......b.i..",
        "..i.b.......b.i..",
        "..i.b.......b.i..",
        "..i.b.......b.i..",
        "..i.b.......b.i..",
        "..i.b.......b.i..",
        "..i.b.......b.i..",
        "..bbbbbbbbbbbbb..",
        "...iiiiiiiiiii...",
        ".....iiiiiii.....",
        "......i...i......"]
    x0, y0 = cx - 8, cy - 14
    for r, row in enumerate(rows):
        for q, ch in enumerate(row):
            if ch == "i":
                p.px(x0 + q, y0 + r, "nightDeep")
            elif ch == "b":
                p.px(x0 + q, y0 + r, "gold" if q < 8 else "straw")
            elif 5 <= r <= 16 and 3 <= q <= 13:
                d = math.hypot(q - 8, (r - 11) * 0.8)
                p.px(x0 + q, y0 + r, "fireWhite" if d < 1.8 else ("fireGold" if d < 3.2 else
                                                                 ("fireOrange" if d < 4.6 else "ember")))
    for r in range(5, 17):     # the bars stand in front of the fire
        p.px(x0 + 4, y0 + r, "nightDeep"); p.px(x0 + 12, y0 + r, "nightDeep")


def figure_masks(parts):
    m = np.zeros((H, W), bool)
    for pm, _ in parts:
        m |= pm
    return m


def light_figure(p, parts, rim_depth=2):
    """Back-lit people: the edges turned to the lantern take the warm ramp by distance, the rest keeps its cloth's
    dark colour."""
    U = figure_masks(parts)
    for pm, base in parts:
        for y, x in zip(*np.where(pm)):
            d = math.hypot(x - LANTERN[0], y - LANTERN[1]) or 1.0
            vx, vy = (LANTERN[0] - x) / d, (LANTERN[1] - y) / d
            facing = 0
            for k in range(1, rim_depth + 1):
                qx, qy = int(round(x + vx * k)), int(round(y + vy * k))
                if not (0 <= qx < W and 0 <= qy < H) or not U[qy, qx]:
                    facing = k
                    break
            if facing:
                t = falloff(x, y, LANTERN[0], LANTERN[1], 170, 150, 1.0)
                i = int(t * 5.6 * (1.0 if facing == 1 else 0.55))
                p.px(x, y, RIM[min(4, i)] if i > 0 else base)
            else:
                p.px(x, y, base)


def person(x, foot, hgt, body="cloak", cloth="night1", head_c="crimsonDeep", broad=1.0, hunch=0.0, hair=None,
           arms=True):
    """A standing figure from masses: a head with hair, a neck, rounded shoulders, arms apart from the body by a dark
    seam, a cloak or a gown to the floor. Returns parts (mask, base colour), back to front."""
    hr = max(3.0, hgt * 0.075)
    hx = x - hunch * hgt * 0.18
    hy = foot - hgt + hr
    head = ellipse_mask(hx, hy, hr * 0.85, hr)
    neck_y = hy + hr
    neck = poly_mask([(hx - hr * 0.4, neck_y - 1), (hx + hr * 0.4, neck_y - 1), (hx + hr * 0.4, neck_y + 2),
                      (hx - hr * 0.4, neck_y + 2)])
    sy = neck_y + 2 + hunch * 3
    sh = hgt * 0.16 * broad
    sx = x - hunch * 7
    waist = sy + hgt * 0.30
    hem = sh * (1.3 if body == "gown" else 1.0)
    torso = poly_mask([(sx - sh + 2, sy), (sx + sh - 2, sy), (sx + sh, sy + 3), (x + sh * 0.9, waist),
                       (x + hem, foot), (x - hem, foot), (x - sh * 0.9, waist), (sx - sh, sy + 3)])
    parts = [(torso, cloth), (neck, "nightDeep"), (head, head_c)]
    if arms:
        for side in (-1, 1):
            ax = sx + side * (sh + 0.5)
            arm = poly_mask([(ax - 2, sy + 2), (ax + 2, sy + 2), (ax + 2 + side, waist + 6), (ax - 2 + side, waist + 6)])
            parts.insert(1, (arm, cloth))
    if hair:
        parts.append((ellipse_mask(hx, hy - hr * 0.35, hr * 0.95, hr * 0.75), hair))
    return parts


def seams(p, parts):
    """A dark seam where an arm meets the body, so the figure reads as a person, not a slab."""
    torso = parts[0][0]
    for pm, _ in parts[1:3]:
        e = edge_of(pm) & np.roll(torso, 0, 1)
        for y, x in zip(*np.where(e & torso)):
            if p.get(x, y) not in ("plum", "tile", "tileLight", "gold", "fireGold"):
                p.px(x, y, "night0")


def slide4(heir):
    p = Pic()
    hall_wall(p)
    air(p, lambda x, y: p.get(x, y), LANTERN[0], LANTERN[1], 76, 58, scale=5.0, g=1.6,
        mask=np.ones((H, W), bool), ramp=["plumDeep", "plum", "dusk", "tileLight", "gold", "fireGold"])
    great_lantern(p)
    # the court in a loose half ring, behind and to the sides, smaller (further back)
    court = []
    brannock = person(98, FLOOR - 4, 64, cloth="nightDeep", broad=1.45)
    court.append(brannock)
    pip = person(124, FLOOR - 6, 40, cloth="plumDeep")
    court.append(pip)
    bram = person(222, FLOOR - 4, 60, cloth="soilDark", broad=1.3)
    court.append(bram)
    other = person(246, FLOOR - 8, 56, body="gown", cloth="night1", hair="nightDeep")
    court.append(other)
    for parts in court:
        light_figure(p, parts)
        seams(p, parts)
    # their tells: Brannock's spear, Pip's fool's cap with two bells, Bram's apron
    for y in range(FLOOR - 82, FLOOR - 2):
        p.px(84, y, "woodDark")
    for (x, y, c) in ((84, FLOOR - 86, "stonePale"), (84, FLOOR - 85, "stoneLight"), (84, FLOOR - 84, "stoneLight"),
                      (83, FLOOR - 83, "stoneMid"), (85, FLOOR - 83, "stoneMid")):
        p.px(x, y, c)
    cap = poly_mask([(118, FLOOR - 42), (130, FLOOR - 42), (136, FLOOR - 52), (128, FLOOR - 45), (124, FLOOR - 50),
                     (120, FLOOR - 45), (112, FLOOR - 52)])
    light_figure(p, [(cap, "crimsonDeep")])
    p.px(112, FLOOR - 52, "gold"); p.px(136, FLOOR - 52, "gold")
    apron = poly_mask([(216, FLOOR - 42), (228, FLOOR - 42), (230, FLOOR - 6), (214, FLOOR - 6)])
    p.mask(apron, "woodDark")
    for y in range(FLOOR - 42, FLOOR - 6):
        p.px(228 if y < FLOOR - 30 else 229, y, "tile")
    # Odile, old and bent, her hands holding out the circlet toward the heir
    odile = person(190, FLOOR, 60, body="gown", cloth="nightDeep", hunch=1.1, head_c="crimsonDeep",
                   hair="stoneMid", arms=False)
    light_figure(p, odile)
    seams(p, odile)
    arms = poly_mask([(184, FLOOR - 44), (189, FLOOR - 42), (175, FLOOR - 33), (171, FLOOR - 35)])
    light_figure(p, [(arms, "nightDeep")])
    for (x, y) in ((170, FLOOR - 35), (171, FLOOR - 35), (170, FLOOR - 34), (169, FLOOR - 34), (171, FLOOR - 34),
                   (172, FLOOR - 33)):
        p.px(x, y, "tileLight")                                  # the old hands, lit
    # the heir, in the middle, rim-lit by the lantern behind
    if heir == "lord":
        parts = person(154, FLOOR + 2, 74, cloth="roofDeep", broad=1.15, hair="soilDark")
    else:
        parts = person(154, FLOOR + 2, 72, body="gown", cloth="roofDeep", broad=1.0, hair="soilDark")
        parts.append((poly_mask([(148, FLOOR - 66), (160, FLOOR - 66), (162, FLOOR - 50), (146, FLOOR - 50)]),
                      "soilDark"))                                 # the long hair down her back
    light_figure(p, parts, rim_depth=2)
    seams(p, parts)
    # the circlet between the hands: it catches the gold
    ring = [".gGWGg.", "g.....g", "s.....s", ".sggSs."]
    for r, row in enumerate(ring):
        for q, ch in enumerate(row):
            if ch != ".":
                p.px(162 + q, FLOOR - 40 + r, {"g": "gold", "G": "fireGold", "W": "fireWhite", "s": "straw",
                                               "S": "gold"}[ch])
    # two backs in the foreground, dark against the lit floor, cut by the bottom edge
    for (cx, w_, top) in ((66, 44, 112), (262, 48, 106)):
        back = ellipse_mask(cx, top + 9, 8, 9) | poly_mask([(cx - w_ / 2, H), (cx - w_ / 2 + 2, top + 24),
                                                            (cx - w_ / 2 + 8, top + 19), (cx + w_ / 2 - 8, top + 19),
                                                            (cx + w_ / 2 - 2, top + 24), (cx + w_ / 2, H)])
        p.mask(back, "night0")
        e = edge_of(back) & ~np.roll(back, 1, 0)
        for y, x in zip(*np.where(e)):
            if y < H - 1:
                p.px(x, y, "tile" if y < top + 10 else "plum")
    return p
