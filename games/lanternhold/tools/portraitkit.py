"""The portrait template and parts (SPRITES.md "M3", "Portraits"): one head turned three-quarters right, lit from the
left, in a 48x48 frame. portraitart.py renders these.

The template (world pixels, x right, y down; the same in every part and every story portrait):
    head frame      centre (23.5, 21.5), turned 30 degrees to the right
    head frame      one local unit is 1.15 px
    cranium         top at y 6 (bald), the back of the skull at x 10, the shared top and back of every face
    eye line        y 20 (the near eye's centre at x 24, the far eye's at x 31)
    nose tip        y 25, mouth y 28, chin y 34 (the long face's 35)
    ear             x 11-15, y 17-25
    neck            x 16-28, cut at the collar line y 39 (the clothes take over below it)
    shoulder line   the clothes' top: the trapezius from the neck at y 37-38 to the shoulders at y 42-43
Faces differ below the eyes (jaw, cheeks, chin) and in their features; their cranium, ear and nape are shared, so the
hair, the hats and the beards fit every face. The child keeps the cranium but has a smaller, lower face (big
forehead, eyes at y 22, a small round jaw and chin at y 32) and a thinner neck.
"""
import math

from portraitart import (Frame, Mat, chain, clamp, hash01, mix, sd_box, sd_capsule, sd_cyl, sd_ellipsoid,
                         sd_sphere, sd_torus, smax, smin, smoothstep)

HEAD = Frame((23.0, 21.5, 0.0), yaw=34.0, scale=1.15, squash=0.78)
NECK_CUT = 36          # the face's neck stops here: the clothes' collar line in front of it

SKIN = ["skin1", "skin2", "skin3", "skin4"]
HAIR = ["hair1", "hair2", "hair3", "hair4"]
CLOTH = ["cloth1", "cloth2", "cloth3", "cloth4"]

# ---------------------------------------------------------------------------------------------------------- faces

FACE = dict(
    cran_c=(0.0, -3.0, -1.8), cran_r=(10.0, 10.8, 10.9),
    jaw_c=(0.0, 2.2, 3.2), jaw_r=(7.6, 7.6, 8.0), jaw_k=3.0,
    mand=((6.4, 5.8, -0.6), (1.6, 9.8, 6.4), 1.6),
    cheek=(5.8, 1.0, 6.4, 2.7),
    brow=(-3.6, 9.4, 1.8),
    eye=(3.6, -1.4, 9.2), socket_r=2.0,
    nose_a=(0.0, -1.8, 9.6), nose_b=(0.0, 3.4, 13.0), nose_r=(1.0, 1.6),
    wings=(1.7, 3.7, 11.4, 1.3),
    mouth=(6.2, 10.4), lip_w=2.4,
    chin=(0.0, 9.4, 7.0, 2.4),
    ear_c=(-9.7, 0.4, -0.6), ear_r=(1.7, 3.4, 2.6),
    neck_r=5.6, neck_x=0.0,
    jowl=None, box_jaw=None,
)


def face_params(kind):
    P = dict(FACE)
    if kind == "round":
        P.update(jaw_r=(8.2, 8.0, 8.4), cheek=(5.9, 1.6, 6.6, 3.1), chin=(0.0, 9.2, 7.0, 2.8),
                 mand=((6.6, 6.0, -0.4), (1.8, 9.6, 6.2), 2.1))
    elif kind == "long":
        P.update(jaw_c=(0.0, 2.8, 3.0), jaw_r=(7.0, 8.2, 7.8), cheek=(5.6, 0.6, 6.2, 2.3),
                 chin=(0.0, 10.0, 7.0, 2.3), mand=((6.2, 6.2, -0.6), (1.4, 10.4, 6.2), 1.5),
                 mouth=(6.6, 10.0), nose_b=(0.0, 3.8, 13.2), wings=(1.6, 4.1, 11.5, 1.3))
    elif kind == "square":
        P.update(jaw_r=(8.2, 7.8, 8.2), chin=(0.0, 9.4, 7.2, 2.7), box_jaw=((0.0, 8.6, 4.0), (4.0, 1.6, 3.4), 1.4),
                 mand=((7.0, 6.4, -0.4), (2.2, 9.8, 6.4), 2.1), brow=(-3.6, 9.6, 2.0), neck_r=6.0)
    elif kind == "old":
        P.update(jaw_c=(0.0, 2.6, 3.0), jaw_r=(7.6, 8.0, 8.0), jowl=((5.6, 7.4, 3.6), 1.9),
                 chin=(0.0, 9.8, 6.8, 2.3), cheek=(5.6, 0.8, 6.2, 2.4), nose_b=(0.0, 3.8, 13.2),
                 wings=(1.7, 4.0, 11.4, 1.4), mand=((6.2, 6.4, -0.6), (1.6, 10.2, 6.0), 1.6))
    elif kind == "young":
        P.update(jaw_r=(7.4, 7.4, 7.8), chin=(0.0, 9.2, 6.8, 2.3), cheek=(5.6, 1.4, 6.4, 2.8),
                 nose_b=(0.0, 3.2, 12.6), nose_r=(0.9, 1.5), wings=(1.6, 3.5, 11.2, 1.2), neck_r=5.2,
                 mand=((6.2, 5.8, -0.6), (1.5, 9.6, 6.0), 1.5))
    elif kind == "child":
        P.update(jaw_c=(0.0, 3.2, 2.8), jaw_r=(7.6, 7.0, 7.6), cheek=(5.4, 3.2, 6.0, 3.2), chin=(0.0, 8.6, 6.4, 2.3),
                 mand=((6.2, 6.0, -0.4), (1.6, 8.8, 5.6), 1.8),
                 brow=(-1.6, 9.0, 1.5), eye=(3.6, 0.6, 9.0), socket_r=1.6,
                 nose_a=(0.0, 0.6, 9.4), nose_b=(0.0, 4.2, 11.6), nose_r=(0.8, 1.4), wings=(1.4, 4.4, 10.6, 1.1),
                 mouth=(7.0, 9.4), lip_w=1.8, neck_r=4.4)
    return P


def face_fn(P, frame=HEAD, mat="skin"):
    cran_c, cran_r = P["cran_c"], P["cran_r"]
    ex, ey, ez = P["eye"]

    def fn(p):
        q = frame.to_local(p)
        d = sd_ellipsoid(q, cran_c, cran_r)
        d = smin(d, sd_ellipsoid(q, P["jaw_c"], P["jaw_r"]), P["jaw_k"])
        if P["box_jaw"]:
            c, b, r = P["box_jaw"]
            d = smin(d, sd_box(q, c, b, r), 2.0)
        (ax, ay, az), (bx, by_, bz), mr = P["mand"]
        for s in (-1, 1):
            d = smin(d, sd_capsule(q, (s * ax, ay, az), (s * bx, by_, bz), mr), 2.0)
        cx, cy, cz, cr = P["cheek"]
        for s in (-1, 1):
            d = smin(d, sd_sphere(q, (s * cx, cy, cz), cr), 2.0)
        if P["jowl"]:
            (jx, jy, jz), jr = P["jowl"]
            for s in (-1, 1):
                d = smin(d, sd_sphere(q, (s * jx, jy, jz), jr), 1.5)
        by, bz, br = P["brow"]
        d = smin(d, sd_capsule(q, (-5.0, by, bz), (5.0, by, bz), br), 1.5)
        for s in (-1, 1):
            d = smax(d, -sd_sphere(q, (s * ex, ey, ez + 1.6), P["socket_r"]), 1.0)
        d = smin(d, sd_capsule(q, P["nose_a"], P["nose_b"], P["nose_r"][0], P["nose_r"][1]), 1.0)
        wx, wy, wz, wr = P["wings"]
        for s in (-1, 1):
            d = smin(d, sd_sphere(q, (s * wx, wy, wz), wr), 0.8)
        my, mz = P["mouth"]
        lw = P["lip_w"]
        d = smin(d, sd_capsule(q, (-lw, my - 0.6, mz), (lw, my - 0.6, mz), 0.9), 1.0)
        d = smin(d, sd_capsule(q, (-lw * 0.85, my + 0.8, mz - 0.2), (lw * 0.85, my + 0.8, mz - 0.2), 1.0), 1.0)
        chx, chy, chz, chr_ = P["chin"]
        d = smin(d, sd_sphere(q, (chx, chy, chz), chr_), 2.0)
        d = smin(d, sd_ellipsoid(q, P["ear_c"], P["ear_r"]), 0.6)
        nx = P["neck_x"]
        dn = sd_capsule(q, (nx, 6.0, -1.5), (nx, 30.0, -1.5), P["neck_r"])
        m = mat
        if dn < d - 0.4 and mat == "skin":
            m = "neck"                      # the neck under the jaw, a step darker
        d = smin(d, dn, 2.5)
        return d * frame.ds, m
    return fn


def nose_line(P, frame=HEAD):
    """The pixels of the nose's bridge (its lit near side), from between the eyes to above the tip."""
    a, b = P["nose_a"], P["nose_b"]
    out = []
    for i in range(6):
        t = 0.15 + 0.7 * i / 5
        q = (mix(a[0], b[0], t) - 0.9, mix(a[1], b[1], t), mix(a[2], b[2], t) + 0.6)
        pt = frame.screen(q)
        if pt not in out:
            out.append(pt)
    return out


def anchors(P, frame=HEAD):
    """Screen pixels of the face's landmarks, for the stamps."""
    ex, ey, ez = P["eye"]
    by, bz, _ = P["brow"]
    my, mz = P["mouth"]
    return dict(
        eyeN=frame.screen((-ex, ey, ez)), eyeF=frame.screen((ex, ey, ez)),
        browN=frame.screen((-ex, by - 0.4, bz)), browF=frame.screen((ex, by - 0.4, bz)),
        nose=frame.screen(P["nose_b"]), mouth=frame.screen((0.0, my, mz + 0.6)),
        chin=frame.screen((P["chin"][0], P["chin"][1], P["chin"][2] + P["chin"][3])),
        ear=frame.screen(P["ear_c"]),
    )


SKIN_MAT = Mat(SKIN, th=[0.15, 0.40, 0.88], inner="skin1")
NECK_MAT = Mat(SKIN, th=[0.30, 0.66, 1.1], inner="skin1")


# -------------------------------------------------------------------------------------------------------- features
# Stamps: rows of characters around a landmark. Letters: k ink, w eye white, e iris, 1-4 the skin ramp, a-d the hair
# ramp (brows), "." keeps the pixel.

EYES = {
    # the near eye (left of the nose) and the far eye: (dx, dy of the top-left corner from the landmark, rows)
    "open": ((-3, -1, ["..kkkk", ".kwWek", "..2ee."]), (-1, -1, ["kkk", "Wek", "ee."])),
    "wide": ((-3, -2, ["..kkk.", ".kwWek", ".kwee.", "..22.."]), (-1, -2, [".kk", "Wek", "ee.", "2.."])),
    "lidded": ((-3, -1, ["..kkkk", ".k2kkk", "..wee."]), (-1, -1, ["kkk", "kkk", "ee."])),
    "closed": ((-3, 0, ["..kkk.", ".k...k"]), (-1, 0, ["kk.", "..k"])),
    "squint": ((-3, -1, ["...kk.", ".kkWek", "..22.."]), (-1, -1, [".kk", "kek", "..."])),
}
BROWS = {
    "level": ((-2, -3, [".bbbb"]), (-1, -3, ["bbb"])),
    "raised": ((-2, -4, ["..bb.", ".b..b"]), (-1, -3, ["bbb"])),
    "frown": ((-2, -3, [".bbb.", "....b"]), (-1, -3, ["bbb"])),
    "soft": ((-2, -3, ["..bbb"]), (-1, -3, ["bb."])),
}
MOUTHS = {
    # (dx, dy of the top-left corner from the mouth landmark, rows): the line in the deepest skin, the lower lip lit
    "neutral": (-3, -1, [".2222.", "111111", ".3443.", "..22.."]),
    "smile": (-3, -1, ["1....1", "311113", ".3443.", "..22.."]),
    "grin": (-3, -1, ["1....1", "1wwww1", ".1111.", "..22.."]),
    "frown": (-3, -1, [".1111.", "13333.1", ".3443.", "..22.."]),
    "thin": (-3, 0, ["111111", ".3443."]),
    "open": (-2, -1, [".111.", "1kkk1", ".1k1.", "..2.."]),
}


def features(pic, P, legend, eyes="open", brows="level", mouth="neutral", a=None):
    a = a or anchors(P)
    (nx, ny, near), (fx, fy, far) = EYES[eyes]
    from portraitart import stamp
    stamp(pic, (a["eyeN"][0] + nx, a["eyeN"][1] + ny), near, legend)
    stamp(pic, (a["eyeF"][0] + fx, a["eyeF"][1] + fy), far, legend)
    (bx, by, bn), (gx, gy, bf) = BROWS[brows]
    stamp(pic, (a["eyeN"][0] + bx, a["eyeN"][1] + by), bn, legend)
    stamp(pic, (a["eyeF"][0] + gx, a["eyeF"][1] + gy), bf, legend)
    mx, my, m = MOUTHS[mouth]
    stamp(pic, (a["mouth"][0] + mx, a["mouth"][1] + my), m, legend)
    return pic


# ------------------------------------------------------------------------------------------------------------ hair

def hairline(q, front=-7.0, temple=5.0, nape=7.0, burn=0.0, jag=0.0, seed=1, locks=0.0):
    """How far a local point lies below the hairline (negative inside the hair): the forehead line at `front`, the
    temples `temple` lower, the nape at `nape`, sideburns `burn` lower in front of the ears; `jag` roughens it."""
    x, y, z = q
    ft = smoothstep(-3.0, 7.0, z)
    side = smoothstep(5.0, 8.5, abs(x))
    Y = mix(nape, front, ft) + side * ft * temple
    if burn:
        Y += burn * side * math.exp(-((z - 1.8) / 1.8) ** 2)
    if jag:
        k = int(math.floor(x * 1.4 + 40))
        Y += jag * (hash01(k, seed) - 0.5)
    if locks:
        u = (x * 0.42 + 40.0) % 1.0
        Y += locks * ft * (1.0 - u)
    return y - Y


def strands(whorl, n=11, amp=0.16, seed=3, frame=HEAD):
    """A texture: streaks fanning out from the whorl (a screen point), so the hair's light breaks into locks."""
    wx, wy = frame.screen(whorl)

    def tex(x, y, c, v):
        a = math.atan2(y + 0.5 - wy, x + 0.5 - wx)
        b = int(math.floor((a + math.pi) * n / math.pi))
        r = math.hypot(x - wx, y - wy)
        k = int(r // 5)
        return v + amp * (hash01(b, seed) - 0.5) + 0.06 * (hash01(b, k, seed) - 0.5)
    return tex


def hair_fn(style, P=None, frame=HEAD):
    """The hair styles of portraitHair (frame 1-7): short, long, bun, curly, braids, tousled, child's mop."""
    P = P or FACE
    cc, cr = P["cran_c"], P["cran_r"]

    def shell(q, t):
        return sd_ellipsoid(q, cc, (cr[0] + t, cr[1] + t, cr[2] + t))

    def fn(p):
        q = frame.to_local(p)
        x, y, z = q
        mat = "hair"
        if style == "short":
            d = smax(shell(q, 1.5), hairline(q, front=-7.8, temple=4.4, nape=6.0, burn=2.6, jag=0.6, locks=2.2), 0.4)
        elif style == "long":
            d = smax(shell(q, 1.8), hairline(q, front=-7.6, temple=4.0, nape=9.0, burn=1.0, jag=0.8), 0.6)
            # the fall down the back to the shoulders, and the far side's strand behind the cheek
            d = smin(d, sd_ellipsoid(q, (-4.2, 7.5, -6.5), (6.4, 12.5, 5.0)), 2.5)
            d = smin(d, sd_ellipsoid(q, (-8.6, 6.0, -1.5), (2.6, 10.5, 4.6)), 1.5)
            d = smin(d, sd_ellipsoid(q, (8.9, 3.0, -1.0), (2.0, 8.5, 4.0)), 1.5)
            d = smax(d, y - 18.5 - 1.2 * (hash01(int(x * 1.3 + 50), 7) - 0.5), 0.5)
        elif style == "bun":
            d = smax(shell(q, 1.1), hairline(q, front=-7.8, temple=3.6, nape=6.5), 0.5)
            d = smin(d, sd_sphere(q, (-2.5, -10.8, -10.4), 4.4), 0.8)
        elif style == "curly":
            bump = math.sin(1.9 * x + 0.7) * math.sin(1.9 * y + 1.3) * math.sin(1.9 * z + 0.4)
            d = smax(shell(q, 2.6) - 0.75 * bump, hairline(q, front=-6.6, temple=4.2, nape=6.8, burn=1.5), 0.8)
        elif style == "braids":
            d = smax(shell(q, 1.2), hairline(q, front=-7.6, temple=4.0, nape=6.0), 0.5)
            for s, top, bot in ((-1, (-8.6, 2.0, -2.2), (-8.0, 16.5, 2.4)), (1, (8.6, 2.0, -2.2), (8.4, 15.5, 1.0))):
                n = 7
                for i in range(n):
                    t = i / (n - 1)
                    c = (mix(top[0], bot[0], t) + 0.6 * (1 if i % 2 else -1), mix(top[1], bot[1], t),
                         mix(top[2], bot[2], t))
                    d = smin(d, sd_ellipsoid(q, c, (1.45, 1.35, 1.45)), 0.4)
                tip = (bot[0], bot[1] + 1.6, bot[2])
                dt = sd_ellipsoid(q, tip, (1.0, 0.9, 1.0))
                if dt < d:
                    d, mat = dt, "tie"
        elif style == "tousled":
            spike = math.sin(2.3 * x + 1.1) * math.sin(2.1 * z + 0.3) * (0.6 + 0.4 * math.sin(1.7 * y))
            d = smax(shell(q, 2.0) - 0.9 * max(0.0, spike) * smoothstep(-2.0, -12.0, y),
                     hairline(q, front=-6.2, temple=4.6, nape=6.4, burn=2.0, jag=2.6, seed=5), 0.5)
        elif style == "mop":
            d = smax(shell(q, 2.3), hairline(q, front=-3.4, temple=2.4, nape=6.0, jag=0.6, seed=9, locks=1.6), 0.4)
        else:
            return 1e9, mat
        return d * frame.ds, mat
    return fn


HAIR_STYLES = ["short", "long", "bun", "curly", "braids", "tousled", "mop"]
HAIR_WHORL = {"short": (-2.0, -11.5, -5.0), "long": (1.5, -12.0, 1.0), "bun": (-2.5, -10.8, -10.4),
              "curly": (-2.0, -11.5, -5.0), "braids": (0.5, -12.5, 0.5), "tousled": (-1.0, -12.0, -3.0),
              "mop": (-1.0, -12.5, -2.0)}


# ----------------------------------------------------------------------------------------------------------- beards

ADULTS = ["round", "long", "square", "old", "young"]


def jaw_union(q):
    """The widest adult jaw at a local point (so a beard covers every adult face's jaw)."""
    d = 1e9
    for kind in ADULTS:
        P = face_params(kind)
        dj = smin(sd_ellipsoid(q, P["jaw_c"], P["jaw_r"]), sd_sphere(q, P["chin"][:3], P["chin"][3]), 2.0)
        (ax, ay, az), (bx, by_, bz), mr = P["mand"]
        for s in (-1, 1):
            dj = smin(dj, sd_capsule(q, (s * ax, ay, az), (s * bx, by_, bz), mr), 2.0)
        if P["box_jaw"]:
            c, b, r = P["box_jaw"]
            dj = smin(dj, sd_box(q, c, b, r), 2.0)
        d = min(d, dj)
    return d


def beard_fn(style, frame=HEAD):
    """portraitBeard frames 1-5: stubble, short, full, long, moustache (stubble is a texture, see beard_stubble)."""
    P = FACE

    def lips(q, deep=0.0):
        my, mz = P["mouth"]
        return sd_capsule(q, (-2.3, my + 0.5, mz + 2.2 + deep), (2.3, my + 0.5, mz + 2.2 + deep), 1.5 + 0.3 * deep)

    def stache(q, droop=1.0):
        my, mz = P["mouth"]
        d = 1e9
        for s in (-1, 1):
            pts = [(0.0, my - 1.3, mz + 1.9), (s * 1.8, my - 1.1, mz + 1.5), (s * 3.2, my - 0.1, mz + 0.5),
                   (s * 3.7, my + 1.2 * droop, mz - 0.6)]
            d = min(d, chain(q, pts, 1.3, 0.7, 0.5))
        return d

    def fn(p):
        q = frame.to_local(p)
        x, y, z = q
        if style == "moustache":
            return stache(q, 1.4) * frame.ds, "stache"
        else:
            t = {"stubble": 0.35, "short": 1.0, "full": 1.9, "long": 1.9}[style]
            bump = 0.0
            if style in ("full", "long"):
                bump = 0.45 * math.sin(2.2 * x + 0.4) * math.sin(2.0 * y + 1.1) * math.sin(2.1 * z)
            d = jaw_union(q) - t - bump
            # the beard line: the sideburn in front of the ear, down the cheek under the cheekbone, to the corner
            # of the moustache beside the nose's wing
            lift = {"stubble": 0.0, "short": 0.0, "full": 0.35, "long": 0.35}[style]
            # the top runs from the sideburn (joining the hair in front of the ear) down under the cheekbone; the
            # lips stay free below the moustache
            yline = mix(-1.4, 4.9, smoothstep(-1.5, 5.5, z)) - lift * smoothstep(-1.0, 3.0, z)
            if style in ("full", "long", "short"):
                yline += (0.9 if style != "short" else 0.5) * (hash01(int(math.floor(z * 1.6 + 30)), 13) - 0.5)
            d = smax(d, yline - y, 0.5)
            d = smax(d, -(z + 2.0), 0.8)    # nothing behind the ear
            if style == "long":
                d = smin(d, sd_ellipsoid(q, (0.4, 14.0, 6.2), (4.6, 8.0, 3.6)), 2.0)
                d = smin(d, sd_capsule(q, (0.6, 16.0, 6.0), (1.0, 22.5, 5.0), 2.4, 0.6), 1.5)
            d = smax(d, -lips(q, 1.2 if style in ("full", "long") else 0.0), 0.5)
            if style != "stubble":
                ds = stache(q)
                if ds < d:
                    return ds * frame.ds, "stache"
        return d * frame.ds, ("stubble" if style == "stubble" else "hair")
    return fn


def stubble_tex(x, y, c, v):
    """Stubble: a sparse grain of the hair ramp on the skin (the gaps are cleared after toning)."""
    return v


BEARD_STYLES = ["stubble", "short", "full", "long", "moustache"]

# ------------------------------------------------------------------------------------------------------------ hats

def hat_fn(style, frame=HEAD):
    """portraitHat frames 1-7: straw hat, headscarf, cap with feather, hood, wool cap, helm, flower wreath."""
    cc, cr = FACE["cran_c"], FACE["cran_r"]

    def shell(q, t):
        return sd_ellipsoid(q, cc, (cr[0] + t, cr[1] + t, cr[2] + t))

    def fn(p):
        q = frame.to_local(p)
        x, y, z = q
        mat = "cloth"
        if style == "straw":
            tilt = y - 0.30 * z                                   # tipped forward: the brim's top shows
            brim = smax(abs(tilt + 8.2) - 0.7, math.hypot(x, z + 0.5) - 17.5, 0.5)
            crown = smax(sd_ellipsoid(q, (-0.6, -10.5, -1.0), (10.8, 9.0, 11.2)), tilt + 7.6, 0.5)
            band = smax(sd_ellipsoid(q, (-0.6, -10.5, -1.0), (11.2, 9.4, 11.6)),
                        smax(tilt + 7.6, -(tilt + 10.0), 0.2), 0.2)
            d, mat = min((brim, "straw"), (crown, "straw"), (band - 0.05, "cloth"))
        elif style == "scarf":
            d = smax(shell(q, 2.8), hairline(q, front=-6.6, temple=3.2, nape=8.5), 0.6)
            d = smin(d, sd_ellipsoid(q, (-3.0, 5.5, -10.5), (2.6, 2.4, 2.4)), 1.0)          # the knot
            d = smin(d, chain(q, [(-3.0, 6.5, -10.5), (-4.4, 11.0, -10.0), (-4.0, 15.0, -9.0)], 1.6, 0.8), 0.6)
        elif style == "feather":
            # a soft cap pulled to one side, a turned-up brim, a white feather in its band sweeping back
            cap = sd_ellipsoid(q, (-1.4, -11.6, -1.4), (11.0, 5.4, 11.6))
            cap = smax(cap, -(y + 8.4 + 0.10 * z - 0.12 * x), 0.5)
            brim = smax(sd_ellipsoid(q, (-0.6, -9.0, -0.6), (12.0, 1.6, 12.4)), -(y + 10.2), 0.3)
            plume = chain(q, [(-8.6, -11.4, -2.4), (-12.0, -15.0, -4.6), (-16.0, -16.6, -6.0), (-19.2, -15.0, -6.4)],
                          1.7, 0.5, 0.6)
            d, mat = min((cap, "cloth"), (brim - 0.05, "cuff"), (plume, "feather"))
        elif style == "hood":
            outer = shell(q, 3.6)
            outer = smin(outer, sd_ellipsoid(q, (-1.0, 10.0, -3.0), (14.5, 12.0, 11.0)), 4.0)
            outer = smax(outer, y - 17.0, 1.0)
            opening = sd_ellipsoid(q, (1.5, 2.2, 12.5), (8.6, 11.8, 9.0))
            d = smax(outer, -opening, 1.0)
            if outer < -0.35:
                mat = "clothIn"
        elif style == "wool":
            d = smax(shell(q, 2.6), hairline(q, front=-7.8, temple=1.8, nape=1.5) + 0.0, 0.5)
            cuff = smax(shell(q, 3.2), smax(hairline(q, front=-7.8, temple=1.8, nape=1.5),
                                            -hairline(q, front=-10.4, temple=1.8, nape=-1.5), 0.2), 0.3)
            if cuff < d:
                d, mat = cuff, "cuff"
            d = smin(d, sd_sphere(q, (-2.0, -14.4, -2.0), 1.6), 0.8)                       # the top knot
        elif style == "helm":
            d = smax(shell(q, 2.4), hairline(q, front=-6.2, temple=2.4, nape=3.6), 0.4)
            rim = smax(shell(q, 2.9), smax(hairline(q, front=-6.2, temple=2.4, nape=3.6),
                                           -hairline(q, front=-8.0, temple=2.4, nape=1.8), 0.2), 0.3)
            nasal = sd_box(q, (0.0, -4.0, 11.0), (0.8, 4.4, 0.9), 0.3)
            ridge = sd_capsule(q, (0.0, -15.6, 5.0), (0.0, -14.6, -9.0), 0.9)
            d = min(smin(d, ridge, 0.6), rim - 0.01, nasal)
            mat = "metal"
        elif style == "wreath":
            ring = sd_torus((x, y + 10.2 + 0.18 * z, z + 0.6), (0, 0, 0), 11.2, 1.25)
            d = ring
            a = math.atan2(z + 0.6, x)
            k = int(math.floor((a + math.pi) * 14 / (2 * math.pi)))
            mat = "flower" + "abc"[k % 3] if hash01(k, 3) > 0.45 else "leaf"
        else:
            return 1e9, mat
        return d * frame.ds, mat
    return fn


HAT_STYLES = ["straw", "scarf", "feather", "hood", "wool", "helm", "wreath"]

# ---------------------------------------------------------------------------------------------------------- clothes

BODY = Frame((24.0, 50.5, -3.0), yaw=16.0, scale=1.0)
NECK_AXIS = (-0.2, -1.8)       # the neck's axis in BODY's local x, z


def bust(q, broad=0.0):
    """The shoulders and chest (local to BODY): a chest, two shoulders, the trapezius rising to the neck, the upper
    arms; `broad` widens it (a captain, a smith)."""
    d = sd_ellipsoid(q, (0.0, 0.5, 0.0), (16.0 + broad, 13.0, 9.2))
    for s in (-1, 1):
        d = smin(d, sd_sphere(q, (s * (17.0 + broad), -7.2, -0.5), 5.8), 3.5)
        d = smin(d, sd_capsule(q, (s * 4.4, -14.2, -2.0), (s * (15.6 + broad), -9.6, -0.8), 3.5), 3.0)
        d = smin(d, sd_capsule(q, (s * (19.2 + broad), -4.5, -0.5), (s * (21.0 + broad), 14.0, 0.5), 5.6), 2.5)
    return d


def around_neck(q, y, R, r):
    """A ring around the neck's axis at height y (a collar, a drawstring, a fur, a cowl)."""
    return sd_torus((q[0] - NECK_AXIS[0], q[1] - y, q[2] - NECK_AXIS[1]), (0, 0, 0), R, r)


def folds(amp=0.12, seed=2, slant=0.35, width=3):
    """Soft folds: the light breaks into slanting columns."""
    def tex(x, y, c, v):
        k = int((x + slant * y) // width)
        return v + amp * (hash01(k, seed) - 0.5)
    return tex


def mail_tex(x, y, c, v):
    """Ring mail: staggered rings, each a lit upper rim over a dark gap."""
    r = (x + (y // 2) % 2) % 2
    return v + (0.17 if (y % 2 == 0 and r == 0) else -0.13 if y % 2 else 0.0)


def fur_tex(x, y, c, v):
    return v + 0.26 * (hash01(x, y, 11) - 0.5)


def clothes_fn(style, frame=BODY):
    """portraitClothes frames 0-7: smock, dress with apron, tunic, fine coat, leather apron, mail and surcoat, robe,
    rags. The material per point: the garment's cloth (the swap ramp) and its fixed parts."""
    def fn(p):
        q = frame.to_local(p)
        x, y, z = q
        broad = 1.2 if style in ("leather", "mail") else 0.0
        d = bust(q, broad)
        mat = "cloth"
        if style == "smock":
            # a wide gathered neckline: a puckered band and a drawstring with a bow at the front
            band = around_neck(q, -14.6, 6.9, 1.5)
            d = smin(d, band, 0.6)
            if band < 0.7:
                mat = "clothLight"
            bow = min(sd_sphere(q, (1.6, -12.4, 7.0), 1.2), sd_capsule(q, (1.6, -11.8, 7.4), (2.4, -7.5, 8.6), 0.6))
            if bow < 0.6:
                mat = "cord"
            d = smin(d, bow, 0.3)
        elif style == "dress":
            # a square neckline over a pale chemise; the apron's bib with straps over the shoulders
            chem = (abs(x - 0.8) < 6.2 and y < -10.6 and z > 1.5)
            bib = sd_box(q, (1.4, 0.5, 8.6), (5.6, 9.5, 1.6), 1.2)
            straps = min(sd_capsule(q, (-4.0, -13.6, 0.0), (-3.4, -6.0, 8.2), 1.15),
                         sd_capsule(q, (6.8, -13.2, -0.6), (6.6, -6.0, 8.2), 1.1))
            ap = min(bib, straps)
            d = smin(d, ap - 0.3, 0.5)
            if chem:
                mat = "white"
            if ap < 0.9 and y > -14.0:
                mat = "apron"
        elif style == "tunic":
            # a V-neck with a dark inner and crossed laces, a stitched trim along it
            v = abs(x - 0.8) - (y + 14.5) * 0.42
            if -14.5 < y < -5.0 and z > 0.5:
                if v < -0.2:
                    mat = "clothDark"
                    lace = abs(abs(x - 0.8) - ((y + 14.5) * 0.42) * 0.5) < 0.6 and int(math.floor(y)) % 3 != 0
                    if lace and y > -13.0:
                        mat = "lace"
                elif v < 1.0:
                    mat = "clothLight"
        elif style == "coat":
            # a pale fur collar round the neck and down the lapel, a white shirt, gold buttons
            fur = around_neck(q, -14.2, 7.4, 2.4)
            fur = smin(fur, sd_capsule(q, (-3.4, -12.0, 6.8), (-4.6, 6.0, 8.6), 2.1), 1.2)
            d = smin(d, fur, 1.0)
            shirt = (abs(x - 1.0) < 2.6 and y < -5.0 and z > 3.0)
            if shirt:
                mat = "white"
            if fur < 0.9:
                mat = "fur"
            for by in (-4.0, 0.5, 5.0):
                if sd_sphere(q, (3.6, by, 9.0), 0.85) < 0.3:
                    mat = "gold"
        elif style == "leather":
            # a sleeved shirt under a long leather bib on two straps, rivets at the corners
            bib = sd_box(q, (1.2, 1.0, 8.8), (6.8, 11.0, 1.6), 1.6)
            straps = min(sd_capsule(q, (-4.6, -14.2, -0.2), (-4.0, -5.0, 8.6), 1.3),
                         sd_capsule(q, (7.0, -13.6, -0.8), (6.8, -5.0, 8.6), 1.2))
            ap = min(bib, straps)
            d = smin(d, ap - 0.3, 0.5)
            if ap < 0.9 and y > -14.6:
                mat = "leather"
                for rx in (-4.4, 6.4):
                    if math.hypot(x - rx, y + 4.6) < 0.8:
                        mat = "rivet"
        elif style == "mail":
            # ring mail on the shoulders and arms, the surcoat over the chest with a round neckline
            if z > 0.5 and y > -12.4 + 0.16 * abs(x - 1.0) and abs(x - 1.0) < 11.5:
                mat = "cloth"
                if abs(x - 1.0) < 2.2 and -6.5 < y < -2.0:
                    mat = "gold"
            else:
                mat = "metal"
            ring = around_neck(q, -14.8, 6.3, 1.2)
            if ring < 0.6:
                mat = "metal"
            d = smin(d, ring, 0.4)
        elif style == "robe":
            # a thick rolled cowl round the neck and a trimmed front opening
            cowl = around_neck(q, -14.0, 7.2, 2.8)
            d = smin(d, cowl, 1.6)
            if cowl < 0.7:
                mat = "cloth"
            if abs(x - 1.6 - 0.2 * (y + 10.0)) < 1.1 and z > 2.0 and y > -11.2:
                mat = "clothLight"
        elif style == "rags":
            # torn edges, a patch, a rope tie
            d = d + 0.8 * (hash01(int(x * 1.3 + 99), int(y * 1.3 + 99), 4) - 0.5) * smoothstep(-8.0, -15.0, y)
            if sd_box(q, (-8.5, -3.0, 6.0), (2.6, 2.4, 6.0)) < 0.0:
                mat = "patch"
            if sd_box(q, (7.5, 3.0, 6.0), (2.2, 2.6, 6.0)) < 0.0:
                mat = "patch2"
            rope = sd_capsule(q, (-2.0, -13.0, 7.0), (0.5, 4.0, 8.6), 0.7)
            if rope < 0.5:
                mat = "rope"
            d = smin(d, rope, 0.3)
        return d * frame.ds, mat
    return fn


CLOTHES_STYLES = ["smock", "dress", "tunic", "coat", "leather", "mail", "robe", "rags"]


# Garment details: hand-set over the rendered bust (the neck ends at row 35, x 15-28; the bust's top runs from x 12 at
# row 34 out to the shoulders). Letters: 1-4 the cloth ramp, k ink, a-d the skin ramp (a V-neck's chest), w W v
# white linen (parchment, plaster, plasterDim), c C cord (woodDark, wood), l L leather (wood, woodLight), m M metal,
# g G gold (straw, gold), f F fur (plasterDim, parchment), x stitches (ink).
GARMENT_LEGEND = {
    "1": "cloth1", "2": "cloth2", "3": "cloth3", "4": "cloth4", "k": "ink",
    "a": "skin1", "b": "skin2", "c": "skin3", "d": "skin4",
    "w": "parchment", "W": "plaster", "v": "plasterDim",
    "o": "woodDark", "O": "wood", "l": "wood", "L": "woodLight", "n": "woodDark",
    "m": "stoneMid", "M": "stoneLight", "s": "stone", "S": "stonePale",
    "g": "straw", "G": "gold", "f": "plasterDim", "F": "parchment", "x": "ink", "r": "straw",
}

GARMENT_STAMPS = {
    "smock": [((14, 35), [
        "k...............k",
        "k2424242424242424k",
        ".k343434343434343k",
        "..4.3.4..3o4.3.4.",
        "..3.2.3.ooOo.2.3.",
        "..3...3..oO.o..2.",
        "........o..O.o...",
        "........o...o....",
    ])],
    "dress": [((15, 35), [
        "kkkkkkkkkkkkkk",
        "kWwwwwwwwwwwWk",
        "2kvWWWWWWWWvk2",
        "w2kkkkkkkkkk2w",
        ".w2..........w",
        ".W2..wwwwwww.W",
        ".W..wwwwwwwwWv",
        ".W..WwwwwwwwWv",
        ".v..WwwwwwwwWv",
        "....WwwwwwwwWv",
        "....vWWWWWWWvv",
        "....vvWWWWWWv.",
    ])],
    "tunic": [((19, 35), [
        "k3kccccccccck3k",
        ".k4kbcccccbk4k.",
        "..k4kbcccbk4k..",
        "..k34kbcbk43k..",
        "...k34kbk43k...",
        "....k34k43k....",
        ".....k343k.....",
        "......k3k......",
    ]), ((22, 36), [
        "o...o",
        ".o.o.",
        "..o..",
        ".o.o.",
    ])],
    "coat": [((10, 32), [
        "....fFF...........fF...",
        "..fFFfFF.........fFFFk.",
        ".fFfFFfFf.......fFfFFfk",
        "fFfFfFfFFf.....kwfFfFFk",
        "fFfffFfFFff....kwwfFfFk",
        ".ffffffffff....kwvffFfk",
        "...............kwvfFffk",
        "...............kWvffFfk",
        "................kvfffFk",
        "................kfffFfkG",
        "................kffFfk..",
        "................kfFffkG.",
        "................kffffk..",
        "................kfffFkG.",
        "................kfffk...",
        "................kffk..G.",
    ])],
    "leather": [((13, 35), [
        "k3333333333333333k",
        "kn443344443344L3nk",
        "..nL4334434443Lln.",
        "...lL.........lL..",
        "...lL.nnnnnnnnlL..",
        "...SlnLLLLLLLLnS..",
        "....nLLlllllllLn..",
        "....nLllllllllln..",
        "....nLllllllllln..",
        "....nLllllllllln..",
        "....nLllllllllln..",
        "....nLllllllllln..",
    ])],
    "mail": [((12, 34), [
        "kmMsmMsmMsmMsmMsmMsk",
        "kMsmMsmMsmMsmMsmMsmk",
        ".ksmMk4444444444kMsk",
        "..km4k3333333333k4mk",
        "...k4k3333GG3333k4k.",
        "....43333GGGG3333k..",
        "....4333GGkkGG333...",
        "....43333GkkG3333...",
        "....433333GG33333...",
        "....43333333333333..",
    ])],
    "robe": [((10, 32), [
        "....................kk",
        "...kkk..............k3k",
        ".kk343k...........kk343k",
        "k344443k........kk34443k",
        "k3444443kkkkkkkk3444433k",
        ".k33444433333333444443k.",
        "..kk3344444444444433kk..",
        "....kk2333333333332kk...",
        "......kk22222222kk1.....",
        "................k41.....",
        "................k41.....",
        "................k41.....",
        "................k41.....",
        "................k41.....",
        "................k41.....",
        "................k41.....",
    ])],
    "rags": [((14, 35), [
        "k2k.k2kk.k2k.k2kk",
        ".k2k2.2k2.2k.k2k.",
        "..k..k...k..k.k..",
    ]), ((3, 39), [
        "kxkxkxk",
        "x22222x",
        "k21122k",
        "x22222x",
        "kxkxkxk",
    ]), ((34, 41), [
        "kxkxkx",
        "x4444x",
        "k4334k",
        "x4444x",
        "kxkxkx",
    ]), ((24, 37), [
        "o.",
        "Oo",
        ".O",
        ".o",
        ".O",
        "..o",
        "..O",
        "..o",
        "..O",
        "..o",
        "...O",
    ])],
}


# ------------------------------------------------------------------------------------------------- the parts' build

from portraitart import (Pic, Raster, W, H, render, tone, outline, stamp, union_z, clip_behind,  # noqa: E402
                         edge_light)

FACES = ["round", "long", "square", "old", "young", "child"]
FACE_LEGEND = {"k": "ink", "w": "parchment", "e": "soilDark", "1": "skin1", "2": "skin2", "3": "skin3", "4": "skin4",
               "a": "hair1", "b": "hair2", "c": "hair3", "d": "hair4", "W": "foam"}

# the ear: the helix lit from the left, the dark bowl, the lobe (top-left at the ear landmark + (-2, -4))
EAR = [".22.",
       "2443",
       "2412",
       "2412",
       "2421",
       ".241",
       ".43.",
       "..2."]

AGE_MARKS = {
    # extra lines per face, relative to the landmarks: (landmark, dx, dy, rows)
    "old": [("browN", -2, -3, ["..222", "2222."]), ("eyeN", -3, 1, ["2...", ".2.."]), ("eyeN", -1, 2, [".22."]),
            ("eyeF", 2, 0, ["2"]), ("nose", -4, 2, ["2", ".2", ".2"]), ("mouth", -3, 0, ["2"]),
            ("mouth", 3, 1, ["2"])],
    "long": [("nose", -4, 2, ["2", ".2"]), ("eyeN", -4, 3, ["2", "2"])],
    "square": [("chin", -1, 1, [".2."]), ("browN", -2, 0, [".2222"])],
    "round": [("eyeN", -4, 3, ["44"])],
    "young": [],
    "child": [],
}
FACE_FEATURES = {
    "round": dict(eyes="open", brows="level", mouth="neutral"),
    "long": dict(eyes="open", brows="level", mouth="thin"),
    "square": dict(eyes="open", brows="frown", mouth="thin"),
    "old": dict(eyes="lidded", brows="soft", mouth="thin"),
    "young": dict(eyes="wide", brows="soft", mouth="neutral"),
    "child": dict(eyes="wide", brows="soft", mouth="smile"),
}


def drop_specks(raster, minsize=6):
    """Removes the small islands a clip leaves (fewer than minsize 4-connected pixels)."""
    seen = [[False] * W for _ in range(H)]
    for y in range(H):
        for x in range(W):
            if seen[y][x] or not raster.px[y][x]:
                continue
            comp, st = [], [(x, y)]
            seen[y][x] = True
            while st:
                cx, cy = st.pop()
                comp.append((cx, cy))
                for nx, ny in ((cx + 1, cy), (cx - 1, cy), (cx, cy + 1), (cx, cy - 1)):
                    if 0 <= nx < W and 0 <= ny < H and not seen[ny][nx] and raster.px[ny][nx]:
                        seen[ny][nx] = True
                        st.append((nx, ny))
            if len(comp) < minsize:
                for cx, cy in comp:
                    raster.px[cy][cx] = None
    return raster


def face_raster(kind, frame=HEAD):
    P = face_params(kind)
    r = render(face_fn(P, frame))
    for y in range(NECK_CUT, H):
        for x in range(W):
            r.px[y][x] = None
    return P, r


def face_pic(kind, P, r, mats=None, legend=None, feats=None, ear=True, marks=True):
    mats = mats or {"skin": SKIN_MAT, "neck": NECK_MAT}
    legend = legend or FACE_LEGEND
    pic, mm = tone(r, mats)
    outline(pic, mm, mats, skip=lambda x, y: y >= NECK_CUT)
    edge_light(pic, mm, mats)
    a = anchors(P)
    if ear:
        ex, ey = a["ear"]
        stamp(pic, (ex - 2, ey - 4), EAR, legend, mask=True)
    if marks:
        for lm, dx, dy, rows in AGE_MARKS.get(kind, []):
            lx, ly = a[lm]
            stamp(pic, (lx + dx, ly + dy), rows, legend, mask=True)
    # the nose: the bridge's lit edge down from between the eyes, the shadow under the tip, the nostril
    nx, ny = a["nose"]
    for (x, y) in nose_line(P):
        if pic.opaque(x, y):
            pic.set(x, y, legend["4"])
    stamp(pic, (nx - 2, ny), ["221"], legend, mask=True)
    f = dict(FACE_FEATURES.get(kind, {}))
    f.update(feats or {})
    features(pic, P, legend, **f, a=a)
    return pic


def face_union(frame=HEAD):
    rs = [face_raster(k, frame)[1] for k in FACES]
    zu = union_z(rs)
    mask = [[z is not None for z in row] for row in zu]
    return zu, mask


PART_MATS = {
    "skin": SKIN_MAT,
    "neck": NECK_MAT,
    "hair": Mat(HAIR, th=[0.16, 0.42, 0.80], inner="hair1"),
    "tie": Mat(["cloth2", "cloth3", "cloth4"], th=[0.35, 0.65]),
    "cloth": Mat(CLOTH, th=[0.2, 0.5, 0.84], tex=folds()),
    "clothLight": Mat(["cloth2", "cloth3", "cloth4"], th=[0.3, 0.62]),
    "clothDark": Mat(["cloth1", "cloth2"], th=[0.6]),
    "clothIn": Mat(["cloth1", "cloth2"], th=[0.62], outline="ink"),
    "cuff": Mat(CLOTH, th=[0.12, 0.38, 0.66]),
    "straw": Mat(["wood", "straw", "strawLight"], th=[0.3, 0.66]),
    "feather": Mat(["stoneLight", "stonePale", "foam"], th=[0.32, 0.62]),
    "metal": Mat(["stoneDark", "stoneMid", "stone", "stoneLight", "stonePale"], th=[0.15, 0.36, 0.6, 0.84]),
    "leaf": Mat(["leafDark", "leaf", "leafLight"], th=[0.32, 0.64]),
    "flowera": Mat(["dusk", "dawnRose"], th=[0.45]),
    "flowerb": Mat(["straw", "gold"], th=[0.45]),
    "flowerc": Mat(["stonePale", "foam"], th=[0.45]),
    "white": Mat(["plasterDim", "plaster", "parchment"], th=[0.3, 0.62]),
    "apron": Mat(["plasterDim", "plaster", "parchment"], th=[0.28, 0.6]),
    "lace": Mat(["woodDark"], th=[]),
    "cord": Mat(["woodDark", "wood"], th=[0.5]),
    "fur": Mat(["stoneLight", "plasterDim", "plaster", "parchment"], th=[0.25, 0.48, 0.72], tex=fur_tex),
    "leather": Mat(["woodDark", "wood", "woodLight"], th=[0.3, 0.62]),
    "gold": Mat(["straw", "gold"], th=[0.45]),
    "rivet": Mat(["stone", "stonePale"], th=[0.5]),
    "patch": Mat(["cloth1", "cloth2", "cloth3"], th=[0.3, 0.6]),
    "patch2": Mat(["cloth2", "cloth3", "cloth4"], th=[0.3, 0.6]),
    "rope": Mat(["woodDark", "straw"], th=[0.45]),
    "stubble": Mat(["hair2", "hair3"], th=[0.5], outline=None),
    "stache": Mat(HAIR, th=[0.16, 0.42, 0.80], inner="hair1"),
}


def part_frames(sprite):
    """The frames of one part strip as Pics."""
    mats = dict(PART_MATS)
    if sprite == "portraitFace":
        return [face_pic(k, *face_raster(k)) for k in FACES]
    zu, mask = face_union()
    if sprite == "portraitHair":
        out = [Pic()]
        for st in HAIR_STYLES:
            r = drop_specks(clip_behind(render(hair_fn(st)), zu))
            m = dict(mats)
            m["hair"] = Mat(HAIR, th=[0.16, 0.42, 0.80], inner="hair1", tex=strands(HAIR_WHORL[st]))
            pic, mm = tone(r, m)
            outline(pic, mm, m, inner_mask=mask)
            edge_light(pic, mm, m)
            out.append(pic)
        return out
    if sprite == "portraitBeard":
        out = [Pic()]
        for st in BEARD_STYLES:
            r = drop_specks(clip_behind(render(beard_fn(st)), zu, keep=lambda m: m == "stache"))
            if st == "stubble":
                # a sparse random grain (about one pixel in three), never two side by side in a row
                for y in range(H):
                    for x in range(W):
                        if r.px[y][x] and (hash01(x, y, 21) > 0.36 or (x > 0 and r.px[y][x - 1] is not None)):
                            r.px[y][x] = None
            pic, mm = tone(r, mats)
            outline(pic, mm, mats, inner_mask=mask)
            edge_light(pic, mm, mats)
            out.append(pic)
        return out
    if sprite == "portraitHat":
        out = [Pic()]
        for st in HAT_STYLES:
            r = drop_specks(clip_behind(render(hat_fn(st)), zu, keep=lambda m: m == "clothIn" and False))
            pic, mm = tone(r, mats)
            outline(pic, mm, mats, inner_mask=mask)
            edge_light(pic, mm, mats)
            out.append(pic)
        return out
    if sprite == "portraitClothes":
        out = []
        for st in CLOTHES_STYLES:
            r = render(clothes_fn(st))
            pic, mm = tone(r, mats)
            outline(pic, mm, mats)
            edge_light(pic, mm, mats)
            for at, rows in GARMENT_STAMPS.get(st, []):
                stamp(pic, at, rows, GARMENT_LEGEND)
            out.append(pic)
        return out
    raise SystemExit(f"no part {sprite}")


PARTS = ["portraitClothes", "portraitFace", "portraitBeard", "portraitHair", "portraitHat"]
PART_FRAMES = {"portraitClothes": 8, "portraitFace": 6, "portraitBeard": 6, "portraitHair": 8, "portraitHat": 8}
