"""The story and guest portraits (SPRITES.md "M3", "Portraits"), rendered on the template of portraitkit.py with the
court's own colours (ART-court.md, step 1): each portrait is one scene of the kit's head, the character's hair, hat,
clothes and props, so everything hides what lies behind it, then depth edges, the outline, the features and the
hand-set details. Every colour is a palette colour of tools/palette.txt; none is a swap colour.
"""
import math

import portraitkit as K
from portraitart import (Frame, Mat, Pic, W, H, chain, clamp, edge_light, hash01, mix, outline, render, sd_box,
                         sd_capsule,
                         sd_cyl, sd_ellipsoid, sd_sphere, sd_torus, smax, smin, smoothstep, stamp, tone)

HEAD, BODY = K.HEAD, K.BODY

STORY = ["portraitOdile", "portraitBrannock", "portraitPip", "portraitHesper", "portraitTamsin", "portraitBram",
         "portraitMarek", "portraitSeren", "portraitSerLudo", "portraitBard", "portraitEnvoy", "portraitHerald",
         "portraitKing", "portraitLady"]
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
    edge_light(pic, mm, mats)
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
    """Odile, the chancellor: a long, thin face (the jaw narrowed, the cheek hollow) with a long thin wedge of a nose
    hooked a little at the tip, a half-lidded near eye under a level brow and the far brow arched (the dry look), a
    thin mouth with one corner up, crow's feet; grey hair pulled up into a high bun with a pin; the aubergine robe with
    a standing collar, open down the front over the rose facing of her sprite, the collar lined in rose; the silver
    chain of office with its gold seal. Fix stage: the rendered beak was a bulb with a highlight and a nostril (a
    snout) on the round template; the nose is hand-set now."""
    P = K.face_params("long")
    P.update(jaw_r=(6.2, 8.2, 7.6), mand=((5.6, 6.2, -0.6), (1.3, 10.4, 6.0), 1.4), cheek=(5.0, 0.0, 5.8, 1.8),
             nose_a=(0.0, -1.8, 9.6), nose_b=(0.0, 3.0, 12.0), nose_r=(0.75, 0.85), wings=(1.2, 3.6, 11.0, 0.8),
             lip_w=1.9)
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
        d = K.around_neck(q, -15.2, 6.6, 1.4)
        d = smin(d, smax(K.around_neck(q, -17.2, 6.5, 1.2), -(z - 0.5), 0.5), 1.2)   # standing up behind the neck
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
        # the robe open down the front over the rose facing: a panel in the opening, in front of the throat, under
        # the standing collar
        panel = sd_box(q, (1.2, -8.6, 6.6), (3.0, 7.4, 1.6), 1.0)
        if panel < d:
            d, mat = panel, "rose"
        elif z > 1.0 and abs(x - 1.2) < 3.6 + (y + 15.0) * 0.10 and y > -15.5:
            mat = "rose"
        dc = collar(q)
        if dc < d:
            # the standing collar: its inside (towards the neck) lined in rose, the outside aubergine
            d, mat = dc, ("rose" if z > 2.5 or (z > -2.0 and K.around_neck(q, -15.2, 6.6, 0.0) < 6.6) else "robe")
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
        "rose": Mat(["tile", "dusk"], th=[0.34]),
        "chain": Mat(["stone", "stoneLight", "stonePale"], th=[0.3, 0.62],
                     tex=lambda x, y, c, v: v + (0.2 if (x + y) % 2 else -0.15)),
        "seal": Mat(["woodLight", "straw", "gold", "strawLight"], th=[0.2, 0.45, 0.78]),
    }
    L = legend_for(SKIN_ROSY, ["stoneMid", "stone", "stoneLight", "stonePale"],
                   {"t": "tile", "s": "straw", "g": "gold"})
    a = K.anchors(P)
    st = eye_stamps(P, L, eyes="lidded", brows=None, mouth=None, a=a)
    st = [x for x in st if x[1] != ["21"]]          # no nostril stamp: the nose is hand-set below
    st.append(ear_stamp(P, L))
    pic, r, mm = portrait(fn, mats, st)
    for at, rows, lg in odile_finish(K.anchors(P), L):
        stamp(pic, at, rows, lg)
    return pic


def odile_finish(a, L):
    """Odile's hand-set features over the render (fix stage): the thin wedge of a nose breaking the profile (2 px tall
    at the tip, 3-4 px beyond the cheek, hooked a little down, one shadow row under the tip, no highlight, no
    nostril), the brows, the thin mouth with its far corner up, the crow's feet and the hollow cheek."""
    ex, ey = a["eyeN"]
    fx, fy = a["eyeF"]
    mx, my = a["mouth"]
    return [
        ((ex - 2, ey - 3), [".bbbb"], L),             # the near brow, level over the half-lidded eye
        ((fx - 1, fy - 4), [".b", "b.b"], L),          # the far brow arched up: the dry look
        ((ex - 4, ey + 1), ["2", ".2"], L),            # crow's feet
        ((ex - 3, ey + 4), ["2.", ".2", ".2"], L),     # the hollow under the cheekbone
        ((29, 20), [                                   # the nose: bridge from between the eyes to the hooked tip
            "33k....",
            "333k...",
            "3333k..",
            "33333k.",
            "333333k",
            ".22223k",
            "..kkkk.",
        ], L),
        ((mx - 2, my), ["1111"], L),                   # the thin mouth...
        ((mx + 2, my - 1), ["1"], L),                  # ...its far corner tucked up
        ((mx - 1, my + 1), ["33"], L),                 # the thin lower lip catching the light
    ]


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
    """Brannock, captain of the guard: a narrow, long head (fix stage: he and Bram shared one bald dome, eyes and
    nose and read as twins), a hooked nose, a clear pale scar through the near eye, heavy frowning brows, bald with a
    grey fringe round the back, a short square iron-grey beard; steel pauldrons of three plates each with lit top
    edges (they read as rocks under a ring-mail speckle), mail below them and at the throat, the realm's teal surcoat
    with the gold lantern."""
    P = K.face_params("long")
    P.update(cran_c=(0.0, -3.4, -1.8), cran_r=(9.3, 11.2, 10.6), jaw_r=(7.2, 8.0, 7.8),
             mand=((6.2, 6.0, -0.6), (1.8, 10.2, 6.2), 1.8), chin=(0.0, 9.8, 7.0, 2.5),
             nose_a=(0.0, -1.8, 9.6), nose_b=(0.0, 3.2, 12.2), nose_r=(0.8, 0.9), wings=(1.3, 3.6, 11.0, 0.9),
             brow=(-3.6, 9.6, 2.0), ear_c=(-9.0, 0.4, -0.6), neck_r=6.0)
    fringe = shell_hair(P, 1.0, front=-2.6, temple=0.0, nape=6.4, burn=1.2)

    def band(q):
        x, y, z = q
        return smax(smax(fringe(q), -(y + 2.4 - 0.4 * smoothstep(0.0, -6.0, z)), 0.4), z - 1.2, 0.4)

    def body_m(q):
        x, y, z = q
        d = K.bust(q, 1.8)
        sur = z > 0.5 and y > -12.6 + 0.12 * abs(x - 1.0) and abs(x - 1.0) < 11.0
        m = "teal" if sur else "mail"
        for s_ in (-1, 1):
            # three overlapping plates (lames) per shoulder, the top one highest and innermost
            for k, (dx, dy, rx, ry, rz) in enumerate(((14.6, -10.2, 6.6, 3.2, 6.8), (16.4, -7.2, 6.4, 2.9, 6.6),
                                                      (18.0, -4.4, 6.0, 2.6, 6.2))):
                dp = sd_ellipsoid(q, (s_ * dx, dy, -0.2 + 0.3 * k), (rx, ry, rz))
                if dp < d:
                    d, m = dp, "steel%d" % k
        ring = K.around_neck(q, -14.8, 6.4, 1.3)
        if ring < d:
            d, m = ring, "mail"
        return d, m

    beard = beard_shape(P, t=0.8, square=True, jag=0.4)
    parts = [local(HEAD, band, "hair"), local(HEAD, beard, "beard"), localm(BODY, body_m)]
    mats = dict(skin_mats(SKIN_ROSY, th=(0.14, 0.42, 0.975)))
    plate = Mat(METAL, th=[0.15, 0.36, 0.6, 0.86])
    mats.update({
        "hair": Mat(GREY, th=[0.2, 0.46, 0.8], tex=K.strands((-6.0, -2.0, -8.0), n=9, amp=0.12)),
        "beard": Mat(GREY, th=[0.22, 0.48, 0.8], tex=lambda x, y, c, v: v + 0.10 * (hash01(x, y, 5) - 0.5)),
        "teal": Mat(TEAL, th=[0.2, 0.5, 0.9], tex=K.folds(0.08)),
        "mail": Mat(["stoneDark", "stoneMid", "stone", "stoneLight"], th=[0.2, 0.45, 0.72], tex=K.mail_tex),
        "steel0": plate, "steel1": plate, "steel2": plate,
    })
    L = legend_for(SKIN_ROSY, GREY, {"g": "gold", "s": "straw", "t": "tileLight", "p": "parchment"})
    a = K.anchors(P)
    st = eye_stamps(P, L, eyes="open", brows=None, mouth=None, a=a)
    st = [x for x in st if x[1] != ["21"]]
    st.append(ear_stamp(P, L))
    ex, ey = a["eyeN"]
    fx, fy = a["eyeF"]
    st += [
        ((ex - 3, ey - 3), ["bbbbb", "....b"], L),     # heavy brows drawn down
        ((fx - 1, fy - 3), ["bbb"], L),
        ((23, 42), [".gg.", "gssg", "gssg", ".gg."], L),   # the gold lantern on the surcoat
        ((24, 41), ["gg"], L),
    ]
    pic = std_portrait(P, parts, mats, st, SKIN_ROSY)
    for at, rows, lg in brannock_finish(a, L):
        stamp(pic, at, rows, lg)
    return pic


def brannock_finish(a, L):
    """The hooked nose breaking the profile and the clear scar (a pale seam with a dark edge) from the brow through
    the near eye to the cheek."""
    ex, ey = a["eyeN"]
    return [
        ((29, 20), [
            "33k..",
            "333k.",
            "3333k",
            "33332k",
            "3222k.",
            ".kkk..",
        ], L),
        ((ex - 2, ey - 6), ["..p", "..p", ".p1", ".p.", "...", "...", "p1.", "p1.", "1.."], L),
    ]


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
    """Mother Hesper, priestess of the Flame: an old, calm face with dark skin and white hair, eyes closed in a gentle
    smile; the broad gold-ochre mantle of her order over her shoulders with its rounded hood pushed back from her face
    (fix stage: the deep cream hood read as a lumpy mass and hid her), the cream robe showing in front with a gold
    trim along the mantle's edge."""
    P = K.face_params("old")
    cc, cr = P["cran_c"], P["cran_r"]

    def hood_m(q):
        x, y, z = q
        # a hood of thick cloth lying back on the skull: its front edge runs from above the forehead down behind the
        # ear to the nape, so the white hairline and the whole face show; it falls onto the shoulders behind
        outer = sd_ellipsoid(q, (cc[0] - 0.4, cc[1] - 0.2, cc[2] - 0.6), (cr[0] + 2.6, cr[1] + 2.4, cr[2] + 2.6))
        outer = smin(outer, sd_ellipsoid(q, (-2.0, 9.0, -6.0), (12.0, 8.5, 7.5)), 3.0)
        edge = z - (6.0 - 0.45 * (y + 12.0))
        d = smax(outer, edge, 0.8)
        d = smax(d, y - 15.0, 1.0)
        m = "mantle"
        if edge > -1.2 and outer < 0.8:
            m = "trim"
        elif outer < -0.6:
            m = "inside"
        return d, m

    def hair_m(q):
        x, y, z = q
        d = smax(sd_ellipsoid(q, cc, (cr[0] + 1.0, cr[1] + 1.0, cr[2] + 1.0)),
                 K.hairline(q, front=-8.2, temple=3.6, nape=5.0, burn=1.0, jag=0.5), 0.4)
        return d, "hair"

    def body_m(q):
        x, y, z = q
        d = K.bust(q, -1.0)
        m = "mantle"
        # the cream robe in a deep V between the mantle's edges, a gold trim along them
        v = abs(x - 1.2) - (y + 15.5) * 0.36
        if z > 2.0 and y > -15.0:
            if v < -0.6:
                m = "robe"
            elif v < 0.7:
                m = "trim"
        col = K.around_neck(q, -16.0, 6.6, 2.5)
        if col < d:
            d, m = col, ("robe" if z > 3.0 else "mantle")
        return d, m

    parts = [localm(HEAD, hood_m), localm(HEAD, hair_m), localm(BODY, body_m)]
    mats = dict(skin_mats(SKIN_BROWN, th=(0.14, 0.40, 0.90)))
    mats.update({
        "mantle": Mat(["wood", "woodLight", "straw", "strawLight"], th=[0.2, 0.46, 0.82], tex=K.folds(0.10)),
        "trim": Mat(["woodLight", "straw", "gold"], th=[0.3, 0.62]),
        "robe": Mat(CREAM, th=[0.3, 0.62]),
        "inside": Mat(["woodDark", "wood"], th=[0.6], outline="ink"),
        "hair": Mat(WHITE, th=[0.3, 0.66], tex=K.strands((-1.0, -12.0, -1.0), n=12, amp=0.14)),
    })
    L = legend_for(SKIN_BROWN, WHITE, {"g": "gold", "s": "straw", "S": "strawLight"})
    a = K.anchors(P)
    st = eye_stamps(P, L, eyes="closed", brows=None, mouth="smile", a=a)
    st.append(ear_stamp(P, L))
    ex, ey = a["eyeN"]
    fx, fy = a["eyeF"]
    st += [
        ((ex - 3, ey - 3), [".cccc"], L),          # white brows
        ((fx - 1, fy - 3), ["cc."], L),
        ((ex - 4, ey + 1), ["2", ".2"], L),
    ]
    return std_portrait(P, parts, mats, st, SKIN_BROWN)


@builder("portraitTamsin")
def tamsin():
    """Tamsin, the cook: a round, rosy face with a broad smile, a teal kerchief over her auburn hair (curls at the
    forehead, the temple and the nape show under it), knotted well behind the head with two short tails, a red-brown
    dress with a white apron's bib."""
    P = K.face_params("round")
    cc, cr = P["cran_c"], P["cran_r"]

    def scarf_m(q):
        x, y, z = q
        # the kerchief over the crown, its edge above the ear and above the nape (fix stage: it hid every hair and
        # hung to the shoulder, so on the card she had teal hair); the knot well behind the head, two short tails
        d = smax(sd_ellipsoid(q, cc, (cr[0] + 2.2, cr[1] + 2.2, cr[2] + 2.2)),
                 K.hairline(q, front=-7.4, temple=1.6, nape=1.4), 0.6)
        d = smin(d, sd_ellipsoid(q, (-4.6, -3.2, -13.2), (2.8, 2.6, 2.6)), 1.2)
        d = smin(d, chain(q, [(-5.6, -2.4, -14.0), (-8.6, -0.6, -16.4), (-11.0, 1.6, -17.0)], 1.5, 0.8), 0.5)
        d = smin(d, chain(q, [(-4.6, -1.6, -14.4), (-4.8, 2.0, -16.6), (-4.0, 4.6, -17.2)], 1.4, 0.7), 0.5)
        return d, "teal"

    def hair_m(q):
        x, y, z = q
        # auburn curls under the kerchief: at the forehead, the temple and the nape
        bump = math.sin(2.1 * x + 0.3) * math.sin(2.0 * y + 1.0) * math.sin(2.2 * z + 0.6)
        d = smax(sd_ellipsoid(q, cc, (cr[0] + 1.5, cr[1] + 1.3, cr[2] + 1.5)) - 0.6 * bump,
                 K.hairline(q, front=-6.2, temple=4.2, nape=8.4, burn=1.2, jag=0.6), 0.5)
        return d, "auburn"

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

    parts = [localm(HEAD, scarf_m), localm(HEAD, hair_m), localm(BODY, body_m)]
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
    """Bram, the smith: huge, a broad flat bald skull on a thick neck, small eyes under flat heavy brows (few words),
    a short black beard, one soft smudge of soot on the brow and one on the cheek (fix stage: grey dots read as moles,
    and he shared Brannock's head); bare sooty shoulders, the leather apron's straps over a dark shirt, the hammer
    over his near shoulder with its iron head behind his neck."""
    P = K.face_params("square")
    P.update(cran_c=(0.0, -2.0, -1.8), cran_r=(11.4, 9.4, 11.0), jaw_r=(8.6, 7.8, 8.4), neck_r=7.8,
             box_jaw=((0.0, 8.6, 4.0), (4.6, 1.6, 3.4), 1.4), mand=((7.4, 6.4, -0.4), (2.4, 9.8, 6.4), 2.3),
             socket_r=1.6)

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
    mats = dict(skin_mats(SKIN_ROSY, th=(0.14, 0.42, 0.975)))
    mats.update({
        "beard": Mat(BLACK, th=[0.25, 0.5, 0.84], tex=lambda x, y, c, v: v + 0.10 * (hash01(x, y, 6) - 0.5)),
        "shirt": Mat(SABLE, th=[0.2, 0.46, 0.84], tex=K.folds(0.08)),
        "leather": Mat(LEATHER, th=[0.3, 0.64]),
        "iron": Mat(["night0", "stoneDark", "stoneMid", "stone"], th=[0.2, 0.45, 0.76]),
        "handle": Mat(LEATHER, th=[0.3, 0.6]),
    })
    L = legend_for(SKIN_ROSY, BLACK, {"m": "stoneMid", "n": "stone"})
    a = K.anchors(P)
    ex, ey = a["eyeN"]
    fx, fy = a["eyeF"]
    st = [
        ((ex - 2, ey - 1), [".kkk", "kek."], L),       # small eyes
        ((fx - 1, fy - 1), ["kk", "e."], L),
        ((ex - 3, ey - 3), ["bbbbb"], L),             # flat, heavy brows: few words
        ((fx - 1, fy - 3), ["bbb"], L),
        ear_stamp(P, L),
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
            if outer < -0.35:
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
            "cloak": Mat(["night1", "farDeep", "far"], th=[0.26, 0.66], tex=K.folds(0.06)),
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
        dent = sd_sphere(q, (3.0, -19.4, 3.6), 4.4)
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
    """A wandering bard: a merry young face with ginger-gold curls (woodLight and straw, as his sprite), singing with
    a wink; a soft rose-red beret (dusk over tile, clearly apart from the hair) draping over the back of his head, its
    crown puffed over a band, a long white feather set into the band; a spring-green doublet with a standing collar,
    slashed cream puffs on the shoulders with the green showing in the slashes, the gold sash. Fix stage: the cap was a
    brown sausage across blond hair, the sleeves two cream balls."""
    P = K.face_params("young")
    cc, cr = P["cran_c"], P["cran_r"]

    def hair_m(q):
        x, y, z = q
        bump = math.sin(1.9 * x + 0.7) * math.sin(1.9 * y + 1.3) * math.sin(1.9 * z + 0.4)
        d = smax(sd_ellipsoid(q, cc, (cr[0] + 1.8, cr[1] + 1.4, cr[2] + 1.8)) - 0.8 * bump,
                 K.hairline(q, front=-6.2, temple=4.6, nape=7.2, burn=2.2), 0.8)
        return d, "hair"

    def cap_m(q):
        x, y, z = q
        # the band: a soft ring round the head above the brow, lower at the back
        f = Frame((0, 0, 0), roll=6.0, pitch=-12.0).to_local((x + 0.4, y + 8.2, z + 1.2))
        band = sd_torus(f, (0, 0, 0), 10.9, 1.3)
        # the crown: a wide soft disc over the band, sagging over the back of the head
        g = Frame((0, 0, 0), roll=12.0, pitch=-14.0).to_local((x + 2.2, y + 11.4, z + 2.4))
        crown = sd_ellipsoid(g, (0, 0, 0), (13.4, 3.3, 12.8))
        crown = smin(crown, sd_ellipsoid(q, (-10.0, -8.2, -6.2), (4.8, 4.4, 6.2)), 3.0)   # the drape at the back
        d, m = (crown, "cap") if crown < band - 0.15 else (band, "capBand")
        vane = chain(q, [(-10.6, -9.4, -4.0), (-13.2, -13.4, -6.0), (-15.0, -17.2, -7.4), (-15.4, -20.0, -8.0)],
                     1.3, 0.5, 0.5)
        if vane < d:
            d, m = vane, "feather"
        return d, m

    def body_m(q):
        x, y, z = q
        d = K.bust(q, -1.0)
        m = "green"
        for sgn in (-1, 1):
            puff = sd_ellipsoid(q, (sgn * 16.2, -7.4, 0.0), (5.4, 4.6, 6.2))
            if puff < d + 0.8:
                d = min(d, puff - 0.3)
                # slashed puffs: cream panels with the doublet's green in the slashes between them
                k = int(math.floor((x * 0.9 + z * 0.5 + 40.0) / 2.4))
                m = "slash" if k % 3 == 0 else "cream"
        if abs((x - 0.62 * y) - 6.0) < 1.4 and z > 0.0:
            m = "goldc"
        col = smax(K.around_neck(q, -15.6, 6.4, 1.6), -(z + 1.0), 0.5)
        if col < d:
            d, m = col, "green"
        return d, m

    parts = [localm(HEAD, hair_m), localm(HEAD, cap_m), localm(BODY, body_m)]
    mats = dict(skin_mats(SKIN_ROSY))
    mats.update({
        "hair": Mat(["wood", "woodLight", "straw"], th=[0.3, 0.72],
                    tex=lambda x, y, c, v: v + 0.12 * (hash01(x // 2, y // 2, 4) - 0.5)),
        "cap": Mat(["woodDark", "tile", "dusk"], th=[0.22, 0.52], tex=K.folds(0.08, slant=-0.4)),
        "capBand": Mat(["woodDark", "tile"], th=[0.55]),
        "feather": Mat(["stoneLight", "stonePale", "foam"], th=[0.3, 0.6]),
        "green": Mat(GREEN, th=[0.2, 0.48, 0.86], tex=K.folds(0.08)),
        "cream": Mat(CREAM, th=[0.3, 0.64]),
        "slash": Mat(["leafDark", "leaf"], th=[0.5]),
        "goldc": Mat(GOLD, th=[0.2, 0.45, 0.8]),
    })
    L = legend_for(SKIN_ROSY, ["wood", "woodLight", "straw", "strawLight"], {"r": "dusk"})
    a = K.anchors(P)
    st = eye_stamps(P, L, eyes="open", brows="raised", mouth="open", a=a)
    st.append(ear_stamp(P, L))
    fx, fy = a["eyeF"]
    st += [((fx - 1, fy - 1), ["3k3", "k3k", "333"], {"k": "ink", "3": "dawnRose"})]   # the wink
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
        pole = sd_capsule(q, (-14.0, -50.0, -9.0), (-14.0, 14.0, -9.0), 0.9)
        bar = sd_capsule(q, (-14.0, -47.0, -9.0), (-27.0, -47.0, -9.0), 0.7)
        if min(pole, bar) < d:
            d, m = min(pole, bar), "pole"
        rag = sd_box(q, (-21.0, -37.0, -9.4), (6.4, 10.0, 0.5), 0.2)
        rag = smax(rag, -(y - (-28.0 + 2.6 * math.sin(x * 1.9) + 1.6 * math.sin(x * 4.3))), 0.3)
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
    # the King's sign on the banner: a small cracked crown
    stamp(pic, (3, 4), ["s.s.s", "sssss", "s.sss", ".sss."], {"s": "stoneDark"})
    return pic


def _lord_body(q):
    x, y, z = q
    d = K.bust(q, -0.4)
    m = "cloak"
    if z > 3.0 and abs(x - 1.0) < 5.4 and y > -13.0:
        m = "tunic"
    clasp = sd_sphere(q, (-4.6, -11.6, 6.8), 1.4)
    if clasp < d + 0.3:
        d, m = min(d, clasp), "goldc"
    return d, m


def _circlet(q):
    """The narrow gold circlet of House Lantern, a size too big: it has slipped to the brow and stands off behind."""
    f = Frame((0, 0, 0), roll=-9.0).to_local(q)
    return smax(abs(math.hypot(f[0] + 0.4, f[2] + 1.6) - 11.9) - 0.75, abs(f[1] + 6.3) - 0.95, 0.3), "crown"


def _lord_mats(hair, th):
    mats = dict(skin_mats(SKIN_ROSY))
    mats.update({
        "hair": Mat(hair, th=th, tex=K.strands((-2.0, -11.0, -4.0), n=13, amp=0.34)),
        "crown": Mat(GOLD, th=[0.2, 0.45, 0.8]),
        "cloak": Mat(TEAL, th=[0.2, 0.5, 0.9], tex=K.folds(0.08)),
        "tunic": Mat(RED, th=[0.3, 0.64]),
        "goldc": Mat(GOLD, th=[0.2, 0.45, 0.8]),
    })
    return mats


@builder("portraitKing")
def king():
    """The Burgherr (STORY.md; look 2's art pass): the lamplighter of about nineteen who became lord. A young,
    beardless face, tousled brown hair with a cowlick, the narrow gold circlet a size too big low on his brow; the
    realm's teal cloak with a gold clasp over the red-brown tunic."""
    P = K.face_params("young")
    cc, cr = P["cran_c"], P["cran_r"]

    def hair_m(q):
        x, y, z = q
        bump = math.sin(1.15 * x + 0.3) * math.sin(1.05 * y + 1.0) * math.sin(1.2 * z + 0.6)
        d = smax(sd_ellipsoid(q, cc, (cr[0] + 1.6, cr[1] + 1.8, cr[2] + 1.6)) - 1.5 * bump,
                 K.hairline(q, front=-4.8, temple=3.6, nape=8.2, burn=2.4, jag=1.6), 0.4)
        d = smin(d, sd_capsule(q, (1.0, cc[1] - cr[1] - 0.6, -1.0), (3.4, cc[1] - cr[1] - 3.4, 0.6), 1.3, 0.5), 0.8)
        return d, "hair"

    parts = [localm(HEAD, hair_m), localm(HEAD, _circlet), localm(BODY, _lord_body)]
    L = legend_for(SKIN_ROSY, LEATHER)
    a = K.anchors(P)
    st = eye_stamps(P, L, eyes="open", brows="level", mouth="neutral", a=a)
    st.append(ear_stamp(P, L))
    return std_portrait(P, parts, _lord_mats(LEATHER, [0.5, 0.84]), st, SKIN_ROSY)


DARKHAIR = ["night0", "soilDark", "soil", "soilLight"]


@builder("portraitLady")
def lady():
    """The Burgherrin (STORY.md; a proposal of look 2's art pass): the same lamplighter of about nineteen, a young
    woman. Dark hair drawn back into a long plait that falls over her shoulder with a gold tie, the same circlet,
    cloak, clasp and tunic."""
    P = K.face_params("young")
    P.update(cheek=(5.4, 1.8, 6.2, 2.9), nose_r=(0.7, 1.05), neck_r=4.5)
    cc, cr = P["cran_c"], P["cran_r"]

    def hair_m(q):
        d = smax(sd_ellipsoid(q, cc, (cr[0] + 1.3, cr[1] + 1.5, cr[2] + 1.5)),
                 K.hairline(q, front=-6.0, temple=2.6, nape=6.6, burn=1.0, jag=0.3), 0.4)
        d = smin(d, sd_ellipsoid(q, (-2.0, 1.0, -10.6), (3.6, 4.2, 3.2)), 1.6)   # gathered at the nape
        return d, "hair"

    PLAIT = [(-9.6, -13.6, -1.0), (-11.6, -9.0, 4.6), (-11.4, -3.6, 8.2), (-10.2, 2.0, 9.6), (-9.2, 7.0, 9.8)]

    def plait_m(q):
        d, m = 1e9, "hair"
        for i, (a, b) in enumerate(zip(PLAIT, PLAIT[1:])):
            for k in range(3):
                t = k / 3.0
                c = tuple(a[j] + (b[j] - a[j]) * t for j in range(3))
                d = min(d, sd_sphere(q, c, 2.2 - 0.1 * i))
        tie = sd_sphere(q, PLAIT[-1], 1.9)
        if tie < d:
            d, m = tie, "crown"
        tail = sd_ellipsoid(q, (PLAIT[-1][0] + 0.4, PLAIT[-1][1] + 3.0, PLAIT[-1][2]), (1.5, 2.4, 1.4))
        if tail < d:
            d, m = tail, "hair"
        return d, m

    parts = [localm(HEAD, hair_m), localm(HEAD, _circlet), localm(BODY, _lord_body), localm(BODY, plait_m)]
    L = legend_for(SKIN_ROSY, DARKHAIR)
    a = K.anchors(P)
    st = eye_stamps(P, L, eyes="open", brows="soft", mouth="neutral", a=a)
    st.append(ear_stamp(P, L))
    return std_portrait(P, parts, _lord_mats(DARKHAIR, [0.3, 0.6, 0.86]), st, SKIN_ROSY)
