"""The story and guest portraits (SPRITES.md "M3", "Portraits"), rendered on the template of portraitkit.py with the
court's own colours (ART-court.md, step 1): each portrait is one scene of the kit's head, the character's hair, hat,
clothes and props, so everything hides what lies behind it, then depth edges, the outline, the features and the
hand-set details. Every colour is a palette colour of tools/palette.txt; none is a swap colour.
"""
import math

import portraitkit as K
from portraitart import (Frame, Mat, Pic, W, H, chain, clamp, hash01, mix, outline, render, sd_box, sd_capsule,
                         sd_cyl, sd_ellipsoid, sd_sphere, sd_torus, smax, smin, smoothstep, stamp, tone)

HEAD, BODY = K.HEAD, K.BODY

STORY = ["portraitOdile", "portraitBrannock", "portraitPip", "portraitHesper", "portraitTamsin", "portraitBram",
         "portraitMarek", "portraitSeren", "portraitSerLudo", "portraitBard", "portraitEnvoy", "portraitHerald",
         "portraitKing"]
STORY_FRAMES = {"portraitSeren": 2}

# skin ramps (deep to light) from the court sprites' colours
SKIN_ROSY = ["tile", "tileLight", "dawnRose", "parchment"]
SKIN_BROWN = ["woodDark", "soil", "soilLight", "rockLight"]
SKIN_MEDIUM = ["woodDark", "wood", "woodLight", "straw"]
SKIN_ASH = ["stoneDark", "stoneMid", "stone", "stoneLight"]
SKIN_PALE = ["stone", "stoneLight", "stonePale", "foam"]


def scene(*fns):
    """One distance field of several parts: the nearest surface wins, with its material."""
    def f(p):
        best, bm = 1e9, None
        for fn in fns:
            d, m = fn(p)
            if d < best:
                best, bm = d, m
        return best, bm
    return f


def prim(sdf, mat):
    """A part from a plain distance function in world coordinates."""
    return lambda p: (sdf(p), mat)


def local(frame, sdf, mat):
    """A part from a distance function in a frame's local coordinates."""
    return lambda p: (sdf(frame.to_local(p)) * frame.ds, mat)


def depth_edges(pic, matmap, raster, mats, jump=1.6, skip=()):
    """Where a part lies in front of another (a fringe on the forehead, a beard on the neck), the pixel behind it
    takes its material's darker step: the contact line the composed parts draw with their outlines."""
    out = [row[:] for row in pic.c]
    for y in range(H):
        for x in range(W):
            c = raster.px[y][x]
            if not c or matmap[y][x] in skip:
                continue
            for dx, dy in ((0, -1), (-1, 0), (1, 0), (0, 1)):
                X, Y = x + dx, y + dy
                if 0 <= X < W and 0 <= Y < H and raster.px[Y][X] and matmap[Y][X] != matmap[y][x]:
                    if raster.px[Y][X]["z"] - c["z"] > jump:
                        m = mats[matmap[y][x]]
                        out[y][x] = m.step(pic.c[y][x], -1)
                        break
    pic.c = out
    return pic


def portrait(fn, mats, stamps=(), skip_edges=(), neck_cut=None):
    """Renders a story portrait scene: tone, depth edges, the outline (not along the bottom edge), then the stamps
    (each (at, rows, legend))."""
    r = render(fn, samples=2)
    if neck_cut is not None:
        for y in range(neck_cut[0], H):
            for x in range(W):
                c = r.px[y][x]
                if c and c["mat"] in ("skin", "neck") and neck_cut[1](x, y):
                    r.px[y][x] = None
    pic, mm = tone(r, mats)
    depth_edges(pic, mm, r, mats, skip=skip_edges)
    outline(pic, mm, mats)
    for at, rows, legend in stamps:
        stamp(pic, at, rows, legend)
    return pic, r, mm


def head_part(P, mat="skin"):
    return K.face_fn(P, HEAD, mat)


def eye_stamps(P, legend, eyes="open", brows="level", mouth="neutral", a=None):
    """The kit's features as stamps of a portrait (same eyes, brows and mouths as the composed faces)."""
    a = a or K.anchors(P)
    out = []
    (nx, ny, near), (fx, fy, far) = K.EYES[eyes]
    out.append(((a["eyeN"][0] + nx, a["eyeN"][1] + ny), near, legend))
    out.append(((a["eyeF"][0] + fx, a["eyeF"][1] + fy), far, legend))
    if brows:
        (bx, by, bn), (gx, gy, bf) = K.BROWS[brows]
        out.append(((a["eyeN"][0] + bx, a["eyeN"][1] + by), bn, legend))
        out.append(((a["eyeF"][0] + gx, a["eyeF"][1] + gy), bf, legend))
    if mouth:
        mx, my, m = K.MOUTHS[mouth]
        out.append(((a["mouth"][0] + mx, a["mouth"][1] + my), m, legend))
    ex, ey = a["ear"]
    out.append(((a["nose"][0] - 2, a["nose"][1]), ["21"], legend))
    return out


def ear_stamp(P, legend):
    a = K.anchors(P)
    ex, ey = a["ear"]
    return ((ex - 2, ey - 4), K.EAR, legend)


def legend_for(skin, hair=None, extra=None):
    """Stamp letters: 1-4 the skin ramp, a-d the hair ramp, k ink, w W the eye's white and catchlight, e the iris."""
    L = {"k": "ink", "w": "parchment", "W": "foam", "e": "soilDark"}
    for i, n in enumerate(skin):
        L[str(i + 1)] = n
    if hair:
        for i, n in enumerate(hair):
            L["abcd"[i]] = n
    if extra:
        L.update(extra)
    return L


def story_frames(sid):
    fn = BUILDERS.get(sid)
    if fn is None:
        raise SystemExit(f"no story portrait {sid}")
    frames = fn()
    return frames if isinstance(frames, list) else [frames]


BUILDERS = {}


def builder(sid):
    def deco(f):
        BUILDERS[sid] = f
        return f
    return deco


# ------------------------------------------------------------------------------------------------------------ Odile

@builder("portraitOdile")
def odile():
    """Odile, the chancellor: a long face with a long sharp nose and a dry, lidded look (the far brow up, a thin wry
    mouth), grey hair pulled up into a high bun, the aubergine robe with a standing collar open over a rose facing,
    the silver chain of office with its gold seal."""
    P = K.face_params("long")
    P.update(nose_a=(0.0, -2.0, 10.0), nose_b=(0.0, 5.0, 18.2), nose_r=(0.85, 0.95), wings=(1.4, 5.0, 12.2, 1.0),
             cheek=(5.4, 0.4, 6.2, 2.1), lip_w=2.0)
    face = head_part(P)
    cc, cr = P["cran_c"], P["cran_r"]

    def hair(q):
        d = smax(sd_ellipsoid(q, cc, (cr[0] + 0.9, cr[1] + 0.9, cr[2] + 0.9)),
                 K.hairline(q, front=-8.6, temple=3.4, nape=6.0, burn=0.5), 0.4)
        return d

    def bun(q):
        return sd_sphere(q, (-2.2, -15.6, -5.0), 3.3)

    def pin(q):
        return sd_capsule(q, (-6.2, -16.6, -5.4), (2.0, -13.2, -3.6), 0.38)

    def robe(q):
        return K.bust(q, -1.6)

    def collar(q):
        x, y, z = q
        d = K.around_neck(q, -15.2, 6.6, 1.3)
        d = smin(d, smax(K.around_neck(q, -17.0, 6.4, 1.1), -(z - 1.0), 0.5), 1.2)   # standing up behind the neck
        return d

    def chainf(q):
        pts = [(-10.0, -12.8, 2.2), (-6.0, -10.4, 7.0), (-2.0, -8.6, 9.2), (1.2, -8.2, 9.8)]
        pts2 = [(1.2, -8.2, 9.8), (4.4, -9.4, 9.0), (7.6, -11.6, 5.8), (10.0, -13.2, 1.8)]
        return min(chain(q, pts, 0.62), chain(q, pts2, 0.6))

    def seal(q):
        return sd_ellipsoid(q, (1.2, -5.8, 10.2), (2.3, 2.4, 0.9))

    def robe_mat(p):
        q = BODY.to_local(p)
        x, y, z = q
        d = robe(q)
        mat = "robe"
        if z > 1.5 and abs(x - 1.0) < (y + 16.0) * 0.30 and y > -14.5:
            mat = "rose"
        dc = collar(q)
        if dc < d:
            d, mat = dc, ("rose" if z > 4.0 else "robe")
        return d, mat

    fn = scene(face, local(HEAD, hair, "hair"), local(HEAD, bun, "bun"), local(HEAD, pin, "pin"), robe_mat,
               local(BODY, chainf, "chain"),
               local(BODY, seal, "seal"))
    mats = {
        "skin": Mat(SKIN_ROSY, th=[0.14, 0.42, 0.93], inner="tile"),
        "neck": Mat(SKIN_ROSY, th=[0.30, 0.66, 1.1], inner="tile"),
        "hair": Mat(["stoneMid", "stone", "stoneLight", "stonePale"], th=[0.16, 0.42, 0.76],
                    tex=K.strands((-1.0, -12.0, -1.0), n=13, amp=0.14)),
        "pin": Mat(["woodDark", "wood"], th=[0.5]),
        "bun": Mat(["stoneMid", "stone", "stoneLight", "stonePale"], th=[0.2, 0.46, 0.8],
                   tex=K.strands((-2.2, -15.6, -5.0), n=9, amp=0.18, seed=7)),
        "robe": Mat(["night0", "night2", "rockDeep", "stoneMid"], th=[0.12, 0.30, 0.76], tex=K.folds(0.10)),
        "rose": Mat(["tile", "dusk", "dawnRose"], th=[0.32, 0.72]),
        "chain": Mat(["stone", "stoneLight", "stonePale"], th=[0.3, 0.62],
                     tex=lambda x, y, c, v: v + (0.2 if (x + y) % 2 else -0.15)),
        "seal": Mat(["woodLight", "straw", "gold", "strawLight"], th=[0.2, 0.45, 0.78]),
    }
    L = legend_for(SKIN_ROSY, ["stoneMid", "stone", "stoneLight", "stonePale"],
                   {"t": "tile", "s": "straw", "g": "gold"})
    a = K.anchors(P)
    st = eye_stamps(P, L, eyes="lidded", brows=None, mouth=None, a=a)
    st.append(ear_stamp(P, L))
    ex, ey = a["eyeN"]
    fx, fy = a["eyeF"]
    mx, my = a["mouth"]
    st += [
        ((ex - 2, ey - 3), [".bbbb"], L),             # the near brow, level
        ((fx - 1, fy - 4), [".b", "b.b"], L),          # the far brow arched up: the dry look
        ((mx - 2, my), ["1111", "...."], L),           # a thin mouth...
        ((mx + 2, my - 1), ["1"], L),                  # ...its far corner tucked up
        ((ex - 4, ey + 1), ["2", ".2"], L),            # crow's feet
        ((ex - 3, ey + 4), ["2.", ".2", ".2"], L),     # the hollow under the cheekbone
        ((27, 26), ["2", "2", ".2"], L),               # the fold from the nose's wing to the mouth
        ((28, 20), ["4", "4", "4", ".4"], L),          # the long bridge catching the light
        ((27, 43), ["kk", "kk"], {"k": "woodDark"}),   # the seal's mark
    ]
    pic, r, mm = portrait(fn, mats, st)
    return pic


# ---------------------------------------------------------------------------------------------------- the others

GREY = ["stoneMid", "stone", "stoneLight", "stonePale"]
WHITE = ["stoneLight", "stonePale", "foam"]
BLACK = ["night0", "ink", "stoneDark", "stoneMid"]
AUBURN = ["woodDark", "tile", "tileLight"]
GINGER = ["woodDark", "tile", "tileLight", "straw"]
TEAL = ["roofDeep", "banner", "roofLight", "daySky"]
RED = ["woodDark", "tile", "tileLight"]
ROSE = ["tile", "dusk", "dawnRose"]
CREAM = ["plasterDim", "plaster", "parchment"]
GOLD = ["woodLight", "straw", "gold", "strawLight"]
METAL = ["stoneDark", "stoneMid", "stone", "stoneLight", "stonePale"]
LEATHER = ["woodDark", "wood", "woodLight"]
GREEN = ["leafDark", "leaf", "meadow", "leafLight"]
SEA = ["farDeep", "far", "waterDeep", "daySky"]
BLUEGREY = ["night1", "farDeep", "far", "farPale"]
SABLE = ["night0", "night1", "stoneDark", "stoneMid"]
ASHCLOTH = ["stoneDark", "stoneMid", "stone", "stoneLight"]
YELLOW = ["wood", "straw", "strawLight", "parchment"]


def skin_mats(ramp, th=(0.14, 0.42, 0.93)):
    return {"skin": Mat(ramp, th=list(th), inner=ramp[0]), "neck": Mat(ramp, th=[0.30, 0.66, 1.1], inner=ramp[0])}


def shell_hair(P, t, **hl):
    cc, cr = P["cran_c"], P["cran_r"]

    def f(q):
        return smax(sd_ellipsoid(q, cc, (cr[0] + t, cr[1] + t, cr[2] + t)), K.hairline(q, **hl), 0.4)
    return f


def mat_of(*pairs):
    """A part made of sub-shapes with their own materials: pairs (sdf_local, material); nearest wins."""
    def f(q):
        best, bm = 1e9, None
        for sdf, m in pairs:
            d = sdf(q)
            if d < best:
                best, bm = d, m
        return best, bm
    return f


def localm(frame, f):
    """A multi-material part in a frame's local coordinates."""
    def g(p):
        d, m = f(frame.to_local(p))
        return d * frame.ds, m
    return g


def beard_shape(P, t=1.1, lift=0.0, stache=True, jag=0.5, square=False):
    """A beard on this face's own jaw (story portraits): as the kit's, the top from the sideburn under the
    cheekbone, the lips free."""
    my, mz = P["mouth"]

    def jaw(q):
        dj = smin(sd_ellipsoid(q, P["jaw_c"], P["jaw_r"]), sd_sphere(q, P["chin"][:3], P["chin"][3]), 2.0)
        (ax, ay, az), (bx, by_, bz), mr = P["mand"]
        for s in (-1, 1):
            dj = smin(dj, sd_capsule(q, (s * ax, ay, az), (s * bx, by_, bz), mr), 2.0)
        if square:
            dj = smin(dj, sd_box(q, (0.0, 9.6, 4.6), (4.6, 2.2, 3.4), 1.0), 1.5)
        return dj

    def f(q):
        x, y, z = q
        d = jaw(q) - t
        yline = mix(-1.4, 4.9, smoothstep(-1.5, 5.5, z)) - lift * smoothstep(-1.0, 3.0, z)
        yline += jag * (hash01(int(math.floor(z * 1.6 + 30)), 13) - 0.5)
        d = smax(d, yline - y, 0.5)
        d = smax(d, -(z + 2.0), 0.8)
        d = smax(d, -sd_capsule(q, (-2.3, my + 0.5, mz + 2.2 + t), (2.3, my + 0.5, mz + 2.2 + t), 1.5 + 0.3 * t), 0.5)
        if stache:
            for s in (-1, 1):
                pts = [(0.0, my - 1.3, mz + 1.9), (s * 1.8, my - 1.1, mz + 1.5), (s * 3.2, my - 0.1, mz + 0.5),
                       (s * 3.7, my + 1.0, mz - 0.6)]
                d = min(d, chain(q, pts, 1.3, 0.7, 0.5))
        return d
    return f


def std_portrait(P, parts, mats, st, skin_ramp, extra_skip=()):
    fn = scene(head_part(P), *parts)
    pic, r, mm = portrait(fn, mats, st, skip_edges=extra_skip)
    return pic


@builder("portraitBrannock")
def brannock():
    """Brannock, captain of the guard: a square, scarred face (a pale scar through the near eye), heavy frowning
    brows, bald with a grey fringe round the back, a short square iron-grey beard; steel pauldrons and mail under the
    realm's teal surcoat with the gold lantern."""
    P = K.face_params("square")
    fringe = shell_hair(P, 1.0, front=-2.6, temple=0.0, nape=6.4, burn=1.2)

    def band(q):
        x, y, z = q
        return smax(smax(fringe(q), -(y + 2.4 - 0.4 * smoothstep(0.0, -6.0, z)), 0.4), z - 1.2, 0.4)

    def body(q):
        x, y, z = q
        d = K.bust(q, 1.8)
        return d

    def body_m(q):
        x, y, z = q
        d = body(q)
        sur = z > 0.5 and y > -12.6 + 0.12 * abs(x - 1.0) and abs(x - 1.0) < 11.0
        m = "teal" if sur else "mail"
        for s in (-1, 1):
            dp = sd_ellipsoid(q, (s * 15.6, -8.6, -0.2), (6.4, 4.4, 6.8))
            dp = smin(dp, sd_ellipsoid(q, (s * 16.6, -5.6, 0.2), (6.2, 3.0, 6.4)), 1.0)
            if dp < d:
                d, m = dp, "steel"
        ring = K.around_neck(q, -14.8, 6.4, 1.3)
        if ring < d:
            d, m = ring, "mail"
        return d, m

    beard = beard_shape(P, t=0.8, square=True, jag=0.4)
    parts = [local(HEAD, band, "hair"), local(HEAD, beard, "beard"), localm(BODY, body_m)]
    mats = dict(skin_mats(SKIN_ROSY))
    mats.update({
        "hair": Mat(GREY, th=[0.2, 0.46, 0.8], tex=K.strands((-6.0, -2.0, -8.0), n=9, amp=0.12)),
        "beard": Mat(GREY, th=[0.22, 0.48, 0.8], tex=lambda x, y, c, v: v + 0.14 * (hash01(x, y, 5) - 0.5)),
        "teal": Mat(TEAL, th=[0.2, 0.5, 0.9], tex=K.folds(0.08)),
        "mail": Mat(["stoneDark", "stoneMid", "stone", "stoneLight"], th=[0.2, 0.45, 0.72], tex=K.mail_tex),
        "steel": Mat(METAL, th=[0.15, 0.36, 0.6, 0.86]),
    })
    L = legend_for(SKIN_ROSY, GREY, {"g": "gold", "s": "straw", "t": "tileLight", "p": "parchment"})
    a = K.anchors(P)
    st = eye_stamps(P, L, eyes="open", brows=None, mouth=None, a=a)
    st.append(ear_stamp(P, L))
    ex, ey = a["eyeN"]
    fx, fy = a["eyeF"]
    st += [
        ((ex - 3, ey - 3), ["bbbbb", "....b"], L),     # heavy brows drawn down
        ((fx - 1, fy - 3), ["bbb"], L),
        ((ex - 1, ey - 6), ["4", "4", "4", ".", ".", "4", "4", "4", "4"], L),   # the scar through the near eye
        ((ex, ey - 6), ["1", "1", "1", ".", ".", "1", "1", "1", "."], L),
        ((23, 42), [".gg.", "gssg", "gssg", ".gg."], L),   # the gold lantern on the surcoat
        ((24, 41), ["gg"], L),
    ]
    return std_portrait(P, parts, mats, st, SKIN_ROSY)


@builder("portraitPip")
def pip():
    """Pip, the fool: a young cheeky face with a wide grin and rosy cheeks, the two-horned cap (the back horn teal,
    the front horn rose-red) with a gold bell on each drooping tip, a parchment ruff, motley split teal and red."""
    P = K.face_params("young")
    P.update(cheek=(5.8, 1.8, 6.6, 3.1), chin=(0.0, 8.8, 7.0, 2.2))
    cc, cr = P["cran_c"], P["cran_r"]

    def cap(q):
        x, y, z = q
        return smax(sd_ellipsoid(q, cc, (cr[0] + 1.8, cr[1] + 1.8, cr[2] + 1.8)),
                    K.hairline(q, front=-6.4, temple=3.0, nape=1.0), 0.4)

    def cap_m(q):
        x, y, z = q
        d = cap(q)
        m = "teal" if (z * 0.8 - x * 0.6) < 0.0 else "red"
        hb = chain(q, [(-2.0, -12.0, -5.0), (-6.0, -16.5, -8.5), (-10.5, -16.0, -9.5), (-13.0, -12.0, -8.5),
                       (-13.4, -8.4, -7.0)], 2.8, 0.9, 1.2)
        hf = chain(q, [(1.5, -12.5, 3.0), (4.5, -17.0, 4.0), (9.0, -17.5, 4.5), (12.0, -14.0, 4.0), (12.6, -10.5, 3.6)],
                   2.8, 0.9, 1.2)
        if hb < d:
            d, m = hb, "teal"
        if hf < d:
            d, m = hf, "red"
        for c in ((-13.5, -7.0, -6.8), (12.8, -9.2, 3.6)):
            db = sd_sphere(q, c, 1.6)
            if db < d:
                d, m = db, "bell"
        band = smax(sd_ellipsoid(q, cc, (cr[0] + 2.2, cr[1] + 2.2, cr[2] + 2.2)),
                    smax(K.hairline(q, front=-6.4, temple=3.0, nape=1.0),
                         -K.hairline(q, front=-8.0, temple=3.0, nape=-0.6), 0.2), 0.3)
        if band < d:
            d, m = band, "bandc"
        return d, m

    def body_m(q):
        x, y, z = q
        d = K.bust(q, -2.0)
        m = "teal" if x < 0.8 else "red"
        ruff = K.around_neck(q, -14.4, 7.0, 2.2) - 0.5 * math.sin(math.atan2(q[2] + 1.8, q[0] + 0.2) * 9.0)
        if ruff < d:
            d, m = ruff, "ruff"
        return d, m

    parts = [localm(HEAD, cap_m), localm(BODY, body_m)]
    mats = dict(skin_mats(SKIN_ROSY))
    mats.update({
        "teal": Mat(TEAL, th=[0.2, 0.5, 0.9]),
        "red": Mat(["woodDark", "tile", "dusk", "dawnRose"], th=[0.18, 0.45, 0.86]),
        "bandc": Mat(GOLD, th=[0.2, 0.45, 0.8]),
        "bell": Mat(GOLD, th=[0.2, 0.45, 0.75]),
        "ruff": Mat(["plasterDim", "plaster", "parchment"], th=[0.3, 0.62],
                    tex=lambda x, y, c, v: v + (0.15 if (x // 2) % 2 else -0.12)),
    })
    L = legend_for(SKIN_ROSY, AUBURN, {"r": "dusk", "R": "dawnRose"})
    a = K.anchors(P)
    st = eye_stamps(P, L, eyes="wide", brows="raised", mouth=None, a=a)
    st.append(ear_stamp(P, L))
    mx, my = a["mouth"]
    ex, ey = a["eyeN"]
    st += [
        ((mx - 3, my - 1), ["1....1", "1wwww1", ".1111.", "..22.."], L),   # the grin
        ((ex - 3, ey + 3), ["rr", "rr"], L),                        # the rosy cheek
    ]
    return std_portrait(P, parts, mats, st, SKIN_ROSY)


@builder("portraitHesper")
def hesper():
    """Mother Hesper, priestess of the Flame: an old, calm face with dark skin and white brows, eyes closed in a
    gentle smile, a deep cream hood edged in gold, the cream cape with the gold flame of her order, a gold stole."""
    P = K.face_params("old")
    cc, cr = P["cran_c"], P["cran_r"]

    def hood_m(q):
        x, y, z = q
        outer = sd_ellipsoid(q, cc, (cr[0] + 2.8, cr[1] + 2.6, cr[2] + 2.8))
        outer = smin(outer, sd_ellipsoid(q, (-1.0, 10.0, -3.0), (13.6, 10.0, 10.2)), 3.0)
        outer = smax(outer, y - 16.0, 1.0)
        opening = sd_ellipsoid(q, (2.2, 2.6, 13.0), (8.8, 12.0, 9.4))
        d = smax(outer, -opening, 1.0)
        rim = opening
        m = "cream"
        if abs(rim) < 0.9 and z > 2.0:
            m = "gold"
        inner = sd_ellipsoid(q, cc, (cr[0] + 2.6, cr[1] + 2.6, cr[2] + 2.6))
        if d > 0 and inner < 0.6 and z > -2:
            m = "creamIn"
        return d, m

    def body_m(q):
        x, y, z = q
        d = K.bust(q, -1.0)
        m = "cream"
        if z > 3.0 and (abs(x + 3.0) < 1.6 or abs(x - 5.4) < 1.6) and y > -12.0:
            m = "gold"
        return d, m

    parts = [localm(HEAD, hood_m), localm(BODY, body_m)]
    mats = dict(skin_mats(SKIN_BROWN, th=(0.14, 0.40, 0.90)))
    mats.update({
        "cream": Mat(["stoneLight", "plasterDim", "plaster", "parchment"], th=[0.18, 0.42, 0.8], tex=K.folds(0.08)),
        "creamIn": Mat(["soilDark", "rockDark", "plasterDim"], th=[0.4, 0.75], outline="ink"),
        "gold": Mat(GOLD, th=[0.2, 0.45, 0.8]),
    })
    L = legend_for(SKIN_BROWN, WHITE, {"g": "gold", "s": "straw", "S": "strawLight"})
    a = K.anchors(P)
    st = eye_stamps(P, L, eyes="closed", brows=None, mouth="smile", a=a)
    ex, ey = a["eyeN"]
    fx, fy = a["eyeF"]
    st += [
        ((ex - 3, ey - 3), [".cccc"], L),          # white brows
        ((fx - 1, fy - 3), ["cc."], L),
        ((ex - 4, ey + 1), ["2", ".2"], L),
        ((25, 41), ["..S..", ".sgs.", "sgSgs", "sgggs", ".sss."], L),   # the flame of her order on the cape
    ]
    return std_portrait(P, parts, mats, st, SKIN_BROWN)


@builder("portraitTamsin")
def tamsin():
    """Tamsin, the cook: a round, rosy face with a broad smile, a teal kerchief knotted at the back with an auburn
    curl peeking out, a red-brown dress with a white apron's bib."""
    P = K.face_params("round")
    cc, cr = P["cran_c"], P["cran_r"]

    def scarf_m(q):
        x, y, z = q
        d = smax(sd_ellipsoid(q, cc, (cr[0] + 2.2, cr[1] + 2.2, cr[2] + 2.2)),
                 K.hairline(q, front=-6.8, temple=3.0, nape=7.6), 0.6)
        d = smin(d, sd_ellipsoid(q, (-5.6, 1.6, -11.0), (3.2, 3.0, 2.8)), 1.0)
        d = smin(d, chain(q, [(-6.0, 3.0, -11.2), (-9.0, 7.6, -10.4), (-9.6, 11.6, -8.6)], 2.0, 0.9), 0.6)
        d = smin(d, chain(q, [(-6.4, 3.0, -10.6), (-5.4, 8.4, -11.6), (-4.0, 12.0, -10.8)], 1.8, 0.8), 0.6)
        m = "teal"
        curl = chain(q, [(1.6, -6.8, 11.4), (3.4, -5.6, 11.8), (3.2, -4.0, 12.2), (1.8, -4.4, 12.4)], 1.2, 0.8)
        if curl < d:
            d, m = curl, "auburn"
        return d, m

    def body_m(q):
        x, y, z = q
        d = K.bust(q, 0.6)
        m = "dress"
        bib = sd_box(q, (1.4, 0.5, 8.6), (5.6, 9.5, 1.6), 1.2)
        straps = min(sd_capsule(q, (-4.0, -13.6, 0.0), (-3.4, -6.0, 8.2), 1.15),
                     sd_capsule(q, (6.8, -13.2, -0.6), (6.6, -6.0, 8.2), 1.1))
        ap = min(bib, straps) - 0.3
        if ap < d + 0.6 and y > -14.0:
            m = "apron"
        d = smin(d, ap, 0.5)
        return d, m

    parts = [localm(HEAD, scarf_m), localm(BODY, body_m)]
    mats = dict(skin_mats(SKIN_ROSY))
    mats.update({
        "teal": Mat(["roofDeep", "banner", "roofLight"], th=[0.28, 0.66], tex=K.folds(0.10, slant=-0.6)),
        "auburn": Mat(AUBURN, th=[0.3, 0.62]),
        "dress": Mat(RED, th=[0.25, 0.6], tex=K.folds(0.10)),
        "apron": Mat(CREAM, th=[0.3, 0.64]),
    })
    L = legend_for(SKIN_ROSY, AUBURN, {"r": "dusk", "R": "dawnRose"})
    a = K.anchors(P)
    st = eye_stamps(P, L, eyes="squint", brows="soft", mouth=None, a=a)
    st.append(ear_stamp(P, L))
    mx, my = a["mouth"]
    ex, ey = a["eyeN"]
    st += [
        ((mx - 3, my - 1), ["1....1", "1wwww1", ".1111.", "..22.."], L),   # a broad smile
        ((ex - 4, ey + 3), [".rr", "rrr", ".r."], L),          # rosy cheeks
        ((a["eyeF"][0] + 1, a["eyeF"][1] + 3), ["r"], L),
    ]
    return std_portrait(P, parts, mats, st, SKIN_ROSY)


@builder("portraitBram")
def bram():
    """Bram, the smith: huge and bald, a short black beard, soot on his brow and cheek, few words (a flat, steady
    look); bare sooty shoulders, the leather apron's straps over a dark shirt, the hammer over his near shoulder with
    its iron head behind his neck."""
    P = K.face_params("square")
    P.update(neck_r=6.4)

    def body_m(q):
        x, y, z = q
        d = K.bust(q, 2.6)
        m = "shirt"
        straps = min(sd_capsule(q, (-5.0, -14.6, -0.2), (-4.2, -4.0, 9.0), 1.5),
                     sd_capsule(q, (7.4, -14.0, -0.8), (7.0, -4.0, 9.0), 1.4))
        bib = sd_box(q, (1.4, 2.0, 9.0), (7.4, 10.0, 1.8), 1.6)
        ap = min(straps, bib) - 0.3
        if ap < d + 0.6 and y > -15.0:
            m = "leather"
        d = smin(d, ap, 0.5)
        return d, m

    def hammer_m(q):
        x, y, z = q
        handle = min(sd_capsule(q, (7.0, 8.0, 11.0), (-12.6, -12.6, 6.4), 1.0),
                     sd_capsule(q, (-12.6, -12.6, 6.4), (-17.0, -16.4, -1.0), 1.0))
        head = sd_box(Frame((-18.0, -17.6, -2.4), roll=40.0).to_local(q), (0, 0, 0), (2.4, 3.6, 2.6), 0.5)
        if head < handle:
            return head, "iron"
        return handle, "handle"

    beard = beard_shape(P, t=0.7, square=True, jag=0.3)
    parts = [local(HEAD, beard, "beard"), localm(BODY, body_m), localm(BODY, hammer_m)]
    mats = dict(skin_mats(SKIN_ROSY))
    mats.update({
        "beard": Mat(BLACK, th=[0.25, 0.5, 0.84], tex=lambda x, y, c, v: v + 0.14 * (hash01(x, y, 6) - 0.5)),
        "shirt": Mat(SABLE, th=[0.2, 0.46, 0.84], tex=K.folds(0.08)),
        "leather": Mat(LEATHER, th=[0.3, 0.64]),
        "iron": Mat(["night0", "stoneDark", "stoneMid", "stone"], th=[0.2, 0.45, 0.76]),
        "handle": Mat(LEATHER, th=[0.3, 0.6]),
    })
    L = legend_for(SKIN_ROSY, BLACK, {"m": "stoneMid", "n": "stone"})
    a = K.anchors(P)
    st = eye_stamps(P, L, eyes="open", brows=None, mouth=None, a=a)
    st.append(ear_stamp(P, L))
    ex, ey = a["eyeN"]
    fx, fy = a["eyeF"]
    st += [
        ((ex - 3, ey - 3), ["bbbbb"], L),          # flat, heavy brows: few words
        ((fx - 1, fy - 3), ["bbb"], L),
        ((ex - 2, ey - 6), [".mm..m", "m.mm.."], L),   # soot on the brow
        ((ex - 4, ey + 3), ["m.m", ".mm"], L),         # and on the cheek
    ]
    return std_portrait(P, parts, mats, st, SKIN_ROSY)


@builder("portraitMarek")
def marek():
    """Marek, the travelling merchant: a long, sly face (medium brown skin) with a curled black moustache, one brow
    up and a crooked smile; the wide floppy dark hat with a long rose feather sweeping back; the long green coat with
    gold trim and buttons, the satchel's strap across his chest with a gold buckle."""
    P = K.face_params("long")
    P.update(nose_b=(0.0, 4.0, 13.8))
    cc, cr = P["cran_c"], P["cran_r"]
    my, mz = P["mouth"]

    def hat_m(q):
        x, y, z = q
        tilt = y - 0.22 * z + 0.10 * x
        brim = smax(abs(tilt + 8.0 + 0.06 * (x * x + z * z) * 0.12) - 0.75, math.hypot(x, z + 0.5) - 18.0, 0.6)
        crown = smax(sd_ellipsoid(q, (-0.8, -11.0, -1.0), (10.4, 7.6, 10.8)), tilt + 7.4, 0.5)
        d, m = min((brim, "hat"), (crown, "hat"))
        band = smax(sd_ellipsoid(q, (-0.8, -11.0, -1.0), (10.8, 8.0, 11.2)),
                    smax(tilt + 7.4, -(tilt + 9.2), 0.2), 0.2)
        if band < d:
            d, m = band, "goldc"
        fe = chain(q, [(-6.0, -13.0, -6.0), (-11.0, -16.0, -8.0), (-16.5, -15.6, -8.6), (-20.5, -12.0, -7.6)],
                   1.9, 0.6, 0.8)
        if fe < d:
            d, m = fe, "feather"
        return d, m

    def stache(q):
        d = 1e9
        for s in (-1, 1):
            pts = [(0.0, my - 1.3, mz + 1.9), (s * 1.8, my - 1.1, mz + 1.5), (s * 3.2, my - 0.6, mz + 0.6),
                   (s * 3.9, my - 1.8, mz - 0.2), (s * 3.4, my - 2.8, mz - 0.4)]
            d = min(d, chain(q, pts, 1.1, 0.5, 0.4))
        return d

    def body_m(q):
        x, y, z = q
        d = K.bust(q, -0.4)
        m = "coat"
        if z > 2.0 and abs(x - 1.6 - 0.2 * (y + 10.0)) < 0.9 and y > -11.5:
            m = "goldc"
        strap = abs((x + 0.62 * y) - 6.0) < 1.3 and z > 0.0
        if strap:
            m = "strap"
        col = K.around_neck(q, -14.2, 6.8, 1.5)
        if col < d:
            d, m = col, "coat"
        return d, m

    parts = [localm(HEAD, hat_m), local(HEAD, stache, "stache"), localm(BODY, body_m)]
    mats = dict(skin_mats(SKIN_MEDIUM, th=(0.14, 0.40, 0.90)))
    mats.update({
        "hat": Mat(["night0", "night1", "rockDeep", "rockDark"], th=[0.18, 0.44, 0.82]),
        "goldc": Mat(GOLD, th=[0.2, 0.45, 0.8]),
        "feather": Mat(ROSE, th=[0.3, 0.66], tex=lambda x, y, c, v: v + (0.14 if (x + y) % 3 == 0 else 0.0)),
        "stache": Mat(BLACK, th=[0.25, 0.5, 0.84]),
        "coat": Mat(GREEN, th=[0.18, 0.46, 0.86], tex=K.folds(0.10)),
        "strap": Mat(LEATHER, th=[0.3, 0.64]),
    })
    L = legend_for(SKIN_MEDIUM, BLACK, {"g": "gold", "s": "straw"})
    a = K.anchors(P)
    st = eye_stamps(P, L, eyes="squint", brows=None, mouth=None, a=a)
    st.append(ear_stamp(P, L))
    ex, ey = a["eyeN"]
    fx, fy = a["eyeF"]
    mx, my2 = a["mouth"]
    st += [
        ((ex - 3, ey - 3), [".bbbb"], L),
        ((fx - 1, fy - 4), [".b", "b.b"], L),          # one brow up
        ((mx - 1, my2 + 1), ["111."], L),              # a crooked smile under the moustache
        ((mx + 2, my2), ["1"], L),
        ((33, 41), ["gg", "gs"], L),                   # the satchel strap's buckle
    ]
    return std_portrait(P, parts, mats, st, SKIN_MEDIUM)


@builder("portraitSeren")
def seren():
    """Seren, the Stranger: frame 0 hooded, the face in the deep blue-grey hood's shadow (only a pale chin and two
    faint glints), the pale clasp at her throat; frame 1 (from day 15) the hood thrown back: a pale, haunted face with
    shadowed eyes, ash-silver hair, the same cloak and clasp."""
    frames = []
    for revealed in (False, True):
        P = K.face_params("long")
        P.update(cheek=(5.4, 0.6, 6.0, 2.2), lip_w=2.0, chin=(0.0, 9.8, 6.8, 2.2))
        cc, cr = P["cran_c"], P["cran_r"]

        def hood_m(q, revealed=revealed):
            x, y, z = q
            if revealed:
                # the hood lies back on the shoulders: a thick fold behind the neck
                d = K.around_neck(BODY.to_local(HEAD.to_world(q)), -14.6, 8.8, 3.2) / 1.0
                d = smax(d, -(z + 2.0), 0.6) if False else d
                return d / HEAD.s, "cloak"
            outer = sd_ellipsoid(q, cc, (cr[0] + 3.4, cr[1] + 3.0, cr[2] + 3.6))
            outer = smin(outer, sd_ellipsoid(q, (-1.0, 9.0, -3.0), (14.5, 12.0, 11.0)), 4.0)
            outer = smax(outer, y - 16.0, 1.0)
            opening = sd_ellipsoid(q, (2.6, 3.6, 13.6), (7.8, 10.6, 8.6))
            d = smax(outer, -opening, 1.0)
            m = "cloak"
            inner = sd_ellipsoid(q, cc, (cr[0] + 2.6, cr[1] + 2.6, cr[2] + 2.6))
            if d > 0 and inner < 0.6 and z > -2:
                m = "cloakIn"
            return d, m

        def hair_m(q):
            x, y, z = q
            d = smax(sd_ellipsoid(q, cc, (cr[0] + 1.4, cr[1] + 1.4, cr[2] + 1.4)),
                     K.hairline(q, front=-7.6, temple=4.6, nape=10.0, burn=1.6, jag=0.8, locks=1.4), 0.4)
            d = smin(d, sd_ellipsoid(q, (-4.0, 8.0, -6.6), (6.0, 11.0, 4.6)), 2.4)
            d = smax(d, y - 16.0 - 1.2 * (hash01(int(x * 1.3 + 50), 3) - 0.5), 0.5)
            return d, "hair"

        def body_m(q):
            x, y, z = q
            d = K.bust(q, -1.2)
            m = "cloak"
            clasp = sd_ellipsoid(q, (1.0, -13.2, 7.4), (1.6, 1.4, 0.9))
            if clasp < d + 0.4:
                d, m = min(d, clasp), "clasp"
            return d, m

        face = head_part(P)
        if not revealed:
            def face_dark(p, face=face):
                d, m = face(p)
                q = HEAD.to_local(p)
                return d, ("chin" if q[1] > 6.8 and q[2] > 2.0 else m)
            face = face_dark
        parts = [face, localm(HEAD, hood_m), localm(BODY, body_m)]
        if revealed:
            parts.insert(1, localm(HEAD, hair_m))
        fn = scene(*parts)
        if revealed:
            mats = dict(skin_mats(SKIN_PALE, th=(0.16, 0.44, 0.92)))
        else:
            mats = {"skin": Mat(["night0", "night1", "farDeep", "far"], th=[0.25, 0.55, 0.95]),
                    "neck": Mat(["night0", "night1", "farDeep"], th=[0.4, 0.9]),
                    "chin": Mat(["farDeep", "stone", "stoneLight", "stonePale"], th=[0.2, 0.42, 0.72])}
        mats.update({
            "cloak": Mat(["night1", "farDeep", "far", "moon"], th=[0.2, 0.52, 0.94], tex=K.folds(0.06)),
            "cloakIn": Mat(["night0", "night1"], th=[0.6], outline="ink"),
            "clasp": Mat(["stone", "stonePale", "foam"], th=[0.3, 0.62]),
            "hair": Mat(["stone", "stoneLight", "farPale", "foam"], th=[0.2, 0.46, 0.82],
                        tex=K.strands((1.0, -12.0, 1.0), n=12, amp=0.14)),
        })
        a = K.anchors(P)
        if revealed:
            L = legend_for(SKIN_PALE, ["stone", "stoneLight", "farPale", "foam"], {"e": "farDeep", "v": "stoneMid"})
            st = eye_stamps(P, L, eyes="open", brows="soft", mouth="thin", a=a)
            st.append(ear_stamp(P, L))
            ex, ey = a["eyeN"]
            fx, fy = a["eyeF"]
            st += [((ex - 3, ey + 2), [".vvvv", "..vv."], L), ((fx - 1, fy + 2), ["vv"], L),   # haunted shadows
                   ((ex - 3, ey - 2), ["..vv."], L)]
        else:
            L = {"g": "farPale", "G": "stonePale"}
            ex, ey = a["eyeN"]
            fx, fy = a["eyeF"]
            st = [((ex, ey), ["g"], L), ((fx, fy), ["g"], L)]
        pic, r, mm = portrait(fn, mats, [(at, rows, lg) for at, rows, lg in st],
                              )
        frames.append(pic)
    return frames


@builder("portraitSerLudo")
def ser_ludo():
    """Ser Ludo, the wandering knight (comic): a dented bucket helm far too big for him, its visor lifted so two
    earnest eyes peer out, a wilted rose plume drooping down its back; a yellow surcoat with a red chevron over baggy
    mail on a skinny frame."""
    P = K.face_params("young")

    def helm_m(q):
        x, y, z = q
        body = sd_cyl(q, (0.0, -3.5, 0.5), 12.4, 13.8, 4.0)
        dent = sd_sphere(q, (5.0, -19.6, 5.0), 3.6)
        body = smax(body, -dent, 1.2)
        m = "helm"
        d = body
        visor = sd_box(q, (0.6, -1.2, 12.0), (8.0, 2.8, 2.6), 0.6)
        if visor < 0.0:
            m = "dark"
        band = sd_box(q, (0.6, -6.2, 12.4), (9.6, 1.4, 1.6), 0.6)
        if band < d + 0.5 and band < 0.3:
            m = "helmLight"
        plume = chain(q, [(-3.0, -18.0, -4.0), (-8.0, -21.0, -8.0), (-13.5, -18.0, -9.0), (-15.0, -11.0, -8.0),
                          (-14.6, -4.0, -7.0)], 2.6, 1.0, 1.2)
        if plume < d:
            d, m = plume, "plume"
        return d, m

    def body_m(q):
        x, y, z = q
        d = K.bust(q, -2.4)
        m = "mail"
        if z > 0.5 and y > -12.0 + 0.1 * abs(x) and abs(x - 1.0) < 10.5:
            m = "yellow"
            if abs(abs(x - 1.0) * 0.8 - (y + 4.0) * -0.9) < 1.6 and y > -9.5:
                m = "red"
        return d, m

    fn = scene(localm(HEAD, helm_m), localm(BODY, body_m))
    mats = {
        "helm": Mat(METAL, th=[0.14, 0.34, 0.6, 0.88]),
        "helmLight": Mat(["stone", "stoneLight", "stonePale"], th=[0.3, 0.6]),
        "dark": Mat(["night0"], th=[]),
        "plume": Mat(ROSE, th=[0.3, 0.66], tex=lambda x, y, c, v: v + (0.15 if (x + 2 * y) % 4 == 0 else 0.0)),
        "mail": Mat(["stoneDark", "stoneMid", "stone", "stoneLight"], th=[0.2, 0.45, 0.72], tex=K.mail_tex),
        "yellow": Mat(YELLOW, th=[0.2, 0.48, 0.86]),
        "red": Mat(RED, th=[0.3, 0.64]),
    }
    pic, r, mm = portrait(fn, mats, [])
    # the earnest eyes in the visor's dark, and the helm's dents and rivets, hand-set
    eyes = [c for c in [(x, y) for y in range(H) for x in range(W)] if pic.c[c[1]][c[0]] == "night0"]
    if eyes:
        xs = [x for x, y in eyes]
        ys = [y for x, y in eyes]
        cy = (min(ys) + max(ys)) // 2
        cx = (min(xs) + max(xs)) // 2
        L = {"w": "foam", "W": "parchment", "e": "ink", "k": "night0", "r": "stonePale", "R": "stoneDark"}
        stamp(pic, (cx - 6, cy - 1), ["Ww.....Ww", "we.....we"], L)
        stamp(pic, (cx + 7, cy + 4), ["k", ".", "k", ".", "k"], L)          # breathing holes
        stamp(pic, (cx - 9, cy + 7), ["r...r...r"], L)                        # rivets
    return pic


@builder("portraitBard")
def bard():
    """A wandering bard: a merry young face with ginger curls, singing with a wink, a floppy red cap with a long
    white feather, a spring-green doublet with cream puffed sleeves and a gold sash, the lute's neck at his side."""
    P = K.face_params("young")
    cc, cr = P["cran_c"], P["cran_r"]

    def hair_m(q):
        x, y, z = q
        bump = math.sin(1.9 * x + 0.7) * math.sin(1.9 * y + 1.3) * math.sin(1.9 * z + 0.4)
        d = smax(sd_ellipsoid(q, cc, (cr[0] + 2.4, cr[1] + 2.4, cr[2] + 2.4)) - 0.8 * bump,
                 K.hairline(q, front=-6.2, temple=4.6, nape=7.2, burn=2.2), 0.8)
        return d, "hair"

    def cap_m(q):
        x, y, z = q
        cap = sd_ellipsoid(q, (-2.6, -13.4, -1.4), (13.2, 5.6, 13.4))
        cap = smax(cap, -(y + 9.4 + 0.10 * z - 0.14 * x), 0.5)
        droop = sd_ellipsoid(q, (-12.6, -9.6, -4.6), (4.8, 4.6, 5.6))
        d = smin(cap, droop, 2.4)
        m = "cap"
        vane = sd_ellipsoid(Frame((0, 0, 0), yaw=-25.0, roll=-62.0).to_local((x + 9.0, y + 17.6, z + 4.0)),
                            (0.0, 0.0, 0.0), (1.6, 9.0, 0.8))
        if vane < d:
            d, m = vane, "feather"
        return d, m

    def body_m(q):
        x, y, z = q
        d = K.bust(q, -1.0)
        m = "green"
        for s in (-1, 1):
            puff = sd_ellipsoid(q, (s * 16.4, -7.0, 0.0), (5.6, 4.8, 6.4))
            if puff < d + 0.8:
                d, m = min(d, puff - 0.3), "cream"
        if abs((x - 0.62 * y) - 6.0) < 1.4 and z > 0.0:
            m = "goldc"
        return d, m

    def lute_m(q):
        neck = sd_box(q, (14.0, -12.0, 9.0), (1.1, 9.0, 0.9), 0.3)
        peg = sd_box(q, (14.6, -21.6, 8.4), (1.5, 2.2, 1.0), 0.3)
        return min(neck, peg), "wood"

    parts = [localm(HEAD, hair_m), localm(HEAD, cap_m), localm(BODY, body_m)]
    mats = dict(skin_mats(SKIN_ROSY))
    mats.update({
        "hair": Mat(GINGER, th=[0.2, 0.46, 0.84], tex=lambda x, y, c, v: v + 0.12 * (hash01(x // 2, y // 2, 4) - 0.5)),
        "cap": Mat(["woodDark", "tile", "tileLight", "dawnRose"], th=[0.2, 0.46, 0.86]),
        "feather": Mat(["stoneLight", "stonePale", "foam"], th=[0.3, 0.6]),
        "green": Mat(GREEN, th=[0.2, 0.48, 0.86], tex=K.folds(0.08)),
        "cream": Mat(CREAM, th=[0.3, 0.64], tex=lambda x, y, c, v: v + (0.12 if (x + y) % 3 == 0 else 0.0)),
        "goldc": Mat(GOLD, th=[0.2, 0.45, 0.8]),
    })
    L = legend_for(SKIN_ROSY, GINGER, {"r": "dusk"})
    a = K.anchors(P)
    st = eye_stamps(P, L, eyes="open", brows="raised", mouth="open", a=a)
    st.append(ear_stamp(P, L))
    fx, fy = a["eyeF"]
    st += [((fx - 1, fy - 1), ["...", "kkk", "..."], {"k": "ink"})]   # the wink: the far eye closed
    return std_portrait(P, parts, mats, st, SKIN_ROSY)


@builder("portraitEnvoy")
def envoy():
    """The envoy from the coast: an upright face with dark skin and a close black beard, a sea-blue round cap with
    a silver brooch, the sea-blue coat with a white collar and silver buttons, the scroll case's gold cap over his
    shoulder."""
    P = K.face_params("long")
    P.update(lip_w=2.2)
    cc, cr = P["cran_c"], P["cran_r"]

    def cap_m(q):
        x, y, z = q
        d = sd_cyl(Frame((0, 0, 0), pitch=-6.0).to_local((x + 0.6, y + 11.6, z + 0.4)), (0, 0, 0), 10.6, 3.4, 1.4)
        m = "sea"
        br = sd_sphere(q, (5.6, -11.6, 8.6), 1.3)
        if br < d:
            d, m = br, "silver"
        return d, m

    def hair_m(q):
        return smax(sd_ellipsoid(q, cc, (cr[0] + 0.8, cr[1] + 0.8, cr[2] + 0.8)),
                    K.hairline(q, front=-6.8, temple=4.4, nape=6.0, burn=2.6), 0.4), "hair"

    def body_m(q):
        x, y, z = q
        d = K.bust(q, -0.4)
        m = "sea"
        col = K.around_neck(q, -14.6, 6.6, 1.6)
        if col < d:
            d, m = col, "collar"
        for by in (-8.0, -3.6, 0.8):
            if sd_sphere(q, (2.6, by, 9.4), 0.9) < 0.4:
                m = "silver"
        case = sd_capsule(q, (-14.0, -18.0, -6.0), (-6.0, -8.0, -7.0), 1.7)
        if case < d:
            d, m = case, "case"
        capd = sd_capsule(q, (-14.8, -19.0, -6.0), (-13.6, -17.4, -6.0), 2.0)
        if capd < d:
            d, m = capd, "goldc"
        return d, m

    beard = beard_shape(P, t=0.7, jag=0.2)
    parts = [localm(HEAD, cap_m), localm(HEAD, hair_m), local(HEAD, beard, "beard"), localm(BODY, body_m)]
    mats = dict(skin_mats(SKIN_BROWN, th=(0.14, 0.40, 0.90)))
    mats.update({
        "sea": Mat(SEA, th=[0.2, 0.48, 0.88], tex=K.folds(0.08)),
        "silver": Mat(["stone", "stoneLight", "stonePale"], th=[0.3, 0.6]),
        "hair": Mat(BLACK, th=[0.25, 0.5, 0.84]),
        "beard": Mat(BLACK, th=[0.25, 0.5, 0.84], tex=lambda x, y, c, v: v + 0.12 * (hash01(x, y, 8) - 0.5)),
        "collar": Mat(["stoneLight", "stonePale", "foam"], th=[0.3, 0.62]),
        "case": Mat(LEATHER, th=[0.3, 0.64]),
        "goldc": Mat(GOLD, th=[0.2, 0.45, 0.8]),
    })
    L = legend_for(SKIN_BROWN, BLACK)
    a = K.anchors(P)
    st = eye_stamps(P, L, eyes="open", brows="level", mouth=None, a=a)
    st.append(ear_stamp(P, L))
    return std_portrait(P, parts, mats, st, SKIN_BROWN)


@builder("portraitHerald")
def herald():
    """The Lightless King's herald: a gaunt, ash-grey face with hollow eye sockets and cold teal eyes, a black iron
    circlet with three spikes, the black mantle over ragged ash robes, the tattered black banner's pole beside him."""
    P = K.face_params("long")
    P.update(cheek=(5.8, -0.2, 5.6, 1.7), jaw_r=(6.4, 8.0, 7.4), socket_r=2.6, lip_w=1.8,
             mand=((6.4, 6.4, -0.6), (1.4, 10.2, 6.0), 1.4))
    cc, cr = P["cran_c"], P["cran_r"]

    def circ_m(q):
        x, y, z = q
        d = sd_torus((x + 0.4, y + 8.4 - 0.10 * z, z + 1.0), (0, 0, 0), 10.6, 1.0)
        for ang in (-0.95, 0.0, 0.95):
            c = (10.6 * math.sin(ang) - 0.4, -9.6 - 0.10 * (10.6 * math.cos(ang) - 1.0), 10.6 * math.cos(ang) - 1.0)
            d = smin(d, sd_capsule(q, c, (c[0] * 1.03, c[1] - 6.4, c[2] * 1.03), 1.3, 0.2), 0.5)
        return d, "iron"

    def body_m(q):
        x, y, z = q
        d = K.bust(q, -1.6)
        m = "mantle"
        col = smax(K.around_neck(q, -15.6, 7.4, 2.6), -(q[2] - 1.0), 0.6)
        if col < d:
            d, m = col, "mantle"
        if z > 2.5 and abs(x - 0.6) < 4.0 + 0.3 * (y + 12.0) and y > -13.0:
            m = "ash"
            d = d - 0.5 * (hash01(int(x * 1.2 + 50), int(y * 1.2 + 50), 9) - 0.5) * 0.0
        pole = sd_capsule(q, (19.0, -44.0, 6.0), (19.0, 14.0, 6.0), 1.0)
        if pole < d:
            d, m = pole, "pole"
        rag = sd_box(q, (24.6, -32.0, 6.0), (5.4, 9.0, 0.6), 0.2)
        rag = smax(rag, -(y - (-24.0 + 3.0 * math.sin(x * 1.7))), 0.3)
        if rag < d:
            d, m = rag, "banner"
        return d, m

    face = head_part(P)
    fn = scene(face, localm(HEAD, circ_m), localm(BODY, body_m))
    mats = dict(skin_mats(SKIN_ASH, th=(0.14, 0.42, 0.9)))
    mats.update({
        "iron": Mat(["night0", "ink", "stoneDark"], th=[0.3, 0.7]),
        "mantle": Mat(SABLE, th=[0.22, 0.5, 0.88], tex=K.folds(0.10)),
        "ash": Mat(ASHCLOTH, th=[0.2, 0.46, 0.8], tex=lambda x, y, c, v: v + 0.18 * (hash01(x, y // 2, 3) - 0.5)),
        "pole": Mat(["night0", "ink"], th=[0.6]),
        "banner": Mat(["night0", "night1", "stoneDark"], th=[0.4, 0.8]),
    })
    L = legend_for(SKIN_ASH, None, {"o": "night0", "t": "daySky", "T": "roofLight"})
    a = K.anchors(P)
    ex, ey = a["eyeN"]
    fx, fy = a["eyeF"]
    st = [
        ((ex - 3, ey - 2), [".oooo.", "oooooo", ".otT o", "..oo.."], L),   # hollow sockets, cold teal eyes
        ((fx - 1, fy - 2), ["ooo", "oto", ".o."], L),
        ((a["mouth"][0] - 2, a["mouth"][1]), ["1111"], L),
        ((ex - 3, ey + 4), ["1", ".1", ".1"], L),                          # the hollow cheek
        ear_stamp(P, L),
    ]
    pic, r, mm = portrait(fn, mats, st)
    return pic


@builder("portraitKing")
def king():
    """The lamplighter king (the prologue and the endings): an old, kind face with a white beard, soft eyes and a
    gentle smile under a gold crown a size too big with a teal stone; the realm's teal cloak with a gold clasp over a
    red-brown tunic."""
    P = K.face_params("round")
    cc, cr = P["cran_c"], P["cran_r"]

    def crown_m(q):
        x, y, z = q
        f = Frame((0, 0, 0), roll=-6.0).to_local((x, y, z))
        ring = smax(abs(math.hypot(f[0] + 0.4, f[2] + 1.0) - 11.4) - 0.9, abs(f[1] + 8.6) - 2.0, 0.3)
        d = ring
        for ang in (-0.6, 0.15, 0.9):
            c = (11.4 * math.sin(ang) - 0.4, -11.2, 11.4 * math.cos(ang) - 1.0)
            d = smin(d, sd_capsule(f, c, (c[0], c[1] - 3.0, c[2]), 1.3, 0.5), 0.5)
        m = "crown"
        gem = sd_sphere(f, (11.2 * math.sin(0.15) - 0.4, -8.6, 11.4 * math.cos(0.15) - 0.6), 1.3)
        if gem < d + 0.2:
            d, m = min(d, gem), "gem"
        return d, m

    def hair_m(q):
        return smax(sd_ellipsoid(q, cc, (cr[0] + 1.2, cr[1] + 1.2, cr[2] + 1.2)),
                    K.hairline(q, front=-5.0, temple=3.0, nape=6.4, burn=2.6, jag=0.6), 0.4), "hair"

    def body_m(q):
        x, y, z = q
        d = K.bust(q, 0.2)
        m = "cloak"
        if z > 3.0 and abs(x - 1.0) < 5.4 and y > -13.0:
            m = "tunic"
        clasp = sd_sphere(q, (-4.6, -11.6, 6.8), 1.4)
        if clasp < d + 0.3:
            d, m = min(d, clasp), "goldc"
        return d, m

    beard = beard_shape(P, t=1.7, lift=0.0, jag=0.8)

    def beard_long(q):
        d = beard(q)
        d = smin(d, sd_ellipsoid(q, (0.4, 13.0, 5.8), (4.6, 7.0, 3.4)), 2.0)
        return d

    parts = [localm(HEAD, hair_m), local(HEAD, beard_long, "beard"), localm(HEAD, crown_m), localm(BODY, body_m)]
    mats = dict(skin_mats(SKIN_ROSY))
    mats.update({
        "hair": Mat(WHITE, th=[0.3, 0.66], tex=K.strands((-2.0, -11.0, -4.0), n=10, amp=0.12)),
        "beard": Mat(["stone", "stoneLight", "stonePale", "foam"], th=[0.2, 0.46, 0.8],
                     tex=lambda x, y, c, v: v + 0.16 * (hash01(x, y, 2) - 0.5)),
        "crown": Mat(GOLD, th=[0.2, 0.45, 0.8]),
        "gem": Mat(["roofDeep", "banner", "roofLight"], th=[0.3, 0.62]),
        "cloak": Mat(TEAL, th=[0.2, 0.5, 0.9], tex=K.folds(0.08)),
        "tunic": Mat(RED, th=[0.3, 0.64]),
        "goldc": Mat(GOLD, th=[0.2, 0.45, 0.8]),
    })
    L = legend_for(SKIN_ROSY, WHITE)
    a = K.anchors(P)
    st = eye_stamps(P, L, eyes="lidded", brows="soft", mouth=None, a=a)
    st.append(ear_stamp(P, L))
    return std_portrait(P, parts, mats, st, SKIN_ROSY)
