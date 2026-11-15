#!/usr/bin/env python3
"""Lanternhold: proof pictures for night glass (TITLE.md section 4). Not part of the game.

Takes real screenshots of build 86's cards and repaints only the cards' skin in place: the same rectangles, the same
words in the same type at the same place (the glyphs are lifted off the parchment by projecting every pixel onto its
ink colour, so the anti-aliasing of IM Fell survives, and set again in the night-glass colours). The world under a card
is not in the screenshot: it comes from an off-screen render of the same framing where one exists (the hall), and is
otherwise filled from the card's surroundings (a soft fill; at 12 % it is only a colour). The old cards' drop shadows
are taken out of the world (SwiftUI's shadow, inverted) because night glass has none.

  glassproof.py <proof> [--out DIR] [--notched-line]      one proof per run (each well under 20 s on this Mac)
  glassproof.py list

Writes DIR/<proof>-after.png (2622 x 1206), DIR/<proof>-before.png, and the 1311 x 603 JPEGs beside them.
"""
import argparse
import os
import sys

import numpy as np
from PIL import Image, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import glassart as ga  # noqa: E402

WT = "/Users/enaayla/Desktop/Spiele-Welle/.claude/worktrees"
OUT_DEFAULT = WT + "/game2-planning-354541/ci-out/director/night-glass"
GP = 6  # device px per game px on iPhone 17 Pro (1206 / 201 rows... 2 pt at 3x)

# --- the old ink colours (Theme.swift) ---------------------------------------------------------------------------------
DARK_CLASSES = {"ink": 0x38281A, "soft": 0x58432B, "rubric": 0x8C3423, "teal": 0x1F5C5E, "gold": 0xD19A2C}
LIGHT_CLASSES = {"bone": 0xE4D6B4, "boneDim": 0xB3A27F, "goldHi": 0xF4C85A, "seal": 0xF6E8C6}

BONE, GOLD, MIST, MIST_DIM, NAVY_DEEP = ga.BONE, ga.LANTERN_GOLD, ga.MIST, ga.MIST_DIM, ga.NAVY_DEEP
DEFAULT_DARK = {"ink": BONE, "soft": MIST, "rubric": GOLD, "teal": MIST, "gold": GOLD}
DEFAULT_LIGHT = {"bone": BONE, "boneDim": MIST, "goldHi": GOLD, "seal": GOLD}


def rgb(h):
    return np.array([(h >> 16) & 255, (h >> 8) & 255, h & 255], float)


def load(path):
    im = Image.open(path)
    im = im.convert("RGB")
    if im.size != (2622, 1206):
        raise SystemExit("%s is %s, not 2622x1206 upright" % (path, im.size))
    return np.asarray(im).astype(float)


# --- nine-slice at device pixels ---------------------------------------------------------------------------------------

def nine_px(piece, capx, capy, w, h, scale=GP):
    """SwiftUI's resizable(capInsets:) with .interpolation(.none): caps at whole game px, the middle stretched."""
    src = np.asarray(piece.convert("RGBA")).astype(float)
    sh, sw = src.shape[:2]

    def index(n, sn, cap):
        i = np.arange(n)
        out = np.full(n, cap)
        lo = i < cap * scale
        hi = i >= n - cap * scale
        out[lo] = i[lo] // scale
        out[hi] = sn - 1 - (n - 1 - i[hi]) // scale
        return out

    xs = index(w, sw, capx)
    ys = index(h, sh, capy)
    return src[ys][:, xs]


def put(dst, layer, x, y):
    """Alpha-composite an RGBA float layer onto an RGB float image at x, y (clipped)."""
    h, w = layer.shape[:2]
    H, W = dst.shape[:2]
    x0, y0, x1, y1 = max(x, 0), max(y, 0), min(x + w, W), min(y + h, H)
    if x1 <= x0 or y1 <= y0:
        return
    l = layer[y0 - y:y1 - y, x0 - x:x1 - x]
    a = l[..., 3:4] / 255.0
    dst[y0:y1, x0:x1] = l[..., :3] * a + dst[y0:y1, x0:x1] * (1 - a)


def skin(name, w, h, notched=False):
    if name.startswith("glassRibbon"):
        hgp = int(name[len("glassRibbon"):])
        piece = ga.ribbon(hgp)
        return nine_px(piece, hgp // 2 + 4, hgp, w, h)
    if name == "glassPortrait":
        return nine_px(ga.portrait(), ga.PORTRAIT_CAP, ga.PORTRAIT_CAP, w, h)
    piece = ga.pane(name, notched, INSET.get(name))
    cap = (piece.size[0] - 1) // 2
    return nine_px(piece, cap, cap, w, h)


INSET = {}  # a rival's forced inset per skin (--plaque-inset)


# --- the world: shadows out, the hidden part filled ---------------------------------------------------------------------

def gauss1d(sigma):
    r = int(3 * sigma)
    x = np.arange(-r, r + 1)
    k = np.exp(-x * x / (2 * sigma * sigma))
    return k / k.sum()


def blur_mask(mask, sigma):
    k = gauss1d(sigma)
    m = np.apply_along_axis(lambda v: np.convolve(v, k, mode="same"), 0, mask)
    return np.apply_along_axis(lambda v: np.convolve(v, k, mode="same"), 1, m)


def unshadow(world, rect, sigma, dy, opacity):
    x0, y0, x1, y1 = rect
    pad = int(3 * sigma) + abs(dy) + 2
    H, W = world.shape[:2]
    bx0, by0, bx1, by1 = max(x0 - pad, 0), max(y0 - pad, 0), min(x1 + pad, W), min(y1 + pad + abs(dy), H)
    m = np.zeros((by1 - by0, bx1 - bx0))
    m[max(y0 + dy - by0, 0):y1 + dy - by0, x0 - bx0:x1 - bx0] = 1
    s = blur_mask(m, sigma) * opacity
    world[by0:by1, bx0:bx1] /= np.clip(1 - s, 0.35, 1)[..., None]
    np.clip(world, 0, 255, out=world)


def inpaint(world, hole):
    """Fill the hole from its surroundings by a mask-weighted pyramid (soft colour, no structure)."""
    H, W = hole.shape
    img = world * (~hole)[..., None]
    wt = (~hole).astype(float)
    levels = []
    cur_i, cur_w = img, wt
    while min(cur_w.shape) > 4:
        levels.append((cur_i, cur_w))
        h2, w2 = cur_w.shape[0] // 2, cur_w.shape[1] // 2
        cur_i = cur_i[:h2 * 2, :w2 * 2].reshape(h2, 2, w2, 2, 3).sum((1, 3))
        cur_w = cur_w[:h2 * 2, :w2 * 2].reshape(h2, 2, w2, 2).sum((1, 3))
    fill = cur_i / np.maximum(cur_w, 1e-6)[..., None]
    for li, lw in reversed(levels):
        up = np.repeat(np.repeat(fill, 2, 0), 2, 1)
        hh, ww = lw.shape
        up = np.pad(up, ((0, hh - up.shape[0]), (0, ww - up.shape[1]), (0, 0)), mode="edge")
        known = li / np.maximum(lw, 1e-6)[..., None]
        a = np.clip(lw, 0, 1)[..., None]
        fill = known * a + up * (1 - a)
    out = world.copy()
    out[hole] = fill[hole]
    # soften the fill
    sm = Image.fromarray(np.clip(out, 0, 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(18))
    out[hole] = np.asarray(sm).astype(float)[hole]
    return out


# --- lifting the words off the old card ----------------------------------------------------------------------------------

def filt(arr, f):
    im = Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8))
    return np.asarray(im.filter(f)).astype(float)


def lift(src, rect, polarity="dark", classes=None, roles=None, overrides=(), extra_bg=None):
    """Return an RGBA layer (h, w, 4) of the words in rect, recoloured. roles maps old class -> new colour (hex);
    overrides is a list of (x0, y0, x1, y1, {class: hex}) in screen px, applied over roles."""
    x0, y0, x1, y1 = rect
    p = src[y0:y1, x0:x1]
    if polarity == "dark":
        classes = classes or DARK_CLASSES
        roles = dict(DEFAULT_DARK, **(roles or {}))
        bg = np.stack([filt(p[..., c], ImageFilter.MaxFilter(17)) for c in range(3)], -1)
    else:
        classes = classes or LIGHT_CLASSES
        roles = dict(DEFAULT_LIGHT, **(roles or {}))
        bg = np.stack([filt(p[..., c], ImageFilter.MinFilter(17)) for c in range(3)], -1)
    bg = np.stack([filt(bg[..., c], ImageFilter.GaussianBlur(6)) for c in range(3)], -1)
    if extra_bg is not None:
        bg = extra_bg
    d = bg - p
    names = list(classes)
    alphas, resid = [], []
    for n in names:
        v = bg - rgb(classes[n])
        vv = np.maximum((v * v).sum(-1), 1.0)
        a = (d * v).sum(-1) / vv
        r = np.sqrt(((d - a[..., None] * v) ** 2).sum(-1))
        alphas.append(a)
        resid.append(r + np.where((a < 0.03) | (a > 1.35), 1e4, 0))
    alphas = np.stack(alphas)
    resid = np.stack(resid)
    cls = resid.argmin(0)
    alpha = np.take_along_axis(alphas, cls[None], 0)[0]
    alpha = np.clip(alpha, 0, 1)
    alpha[resid.min(0) > 1e3] = 0
    # every pixel takes the class most of the strong pixels around it have (JPEG blurs the colour of a stroke's edge,
    # so a red heading would otherwise come out speckled with the ink's role)
    strong = alpha > 0.4
    votes = []
    for i in range(len(names)):
        m = ((cls == i) & strong).astype(np.uint8) * 255
        votes.append(filt(m, ImageFilter.BoxBlur(7)))
    votes = np.stack(votes)
    final = votes.argmax(0)
    final[votes.max(0) <= 0] = cls[votes.max(0) <= 0]
    colour = np.zeros(p.shape)
    for i, n in enumerate(names):
        colour[final == i] = rgb(roles.get(n, BONE))
    for (ox0, oy0, ox1, oy1, omap) in overrides:
        sx0, sy0 = max(ox0 - x0, 0), max(oy0 - y0, 0)
        sx1, sy1 = min(ox1 - x0, x1 - x0), min(oy1 - y0, y1 - y0)
        if sx1 <= sx0 or sy1 <= sy0:
            continue
        sub = final[sy0:sy1, sx0:sx1]
        for i, n in enumerate(names):
            if n in omap:
                colour[sy0:sy1, sx0:sx1][sub == i] = rgb(omap[n])
    # the paper's own unevenness is not ink: a floor, then the rest stretched back to full
    alpha = np.clip((alpha - 0.1) / 0.86, 0, 1)
    return np.concatenate([colour, alpha[..., None] * 255], -1)


def kill_rules(layer, min_frac=0.85):
    """Find the ink rules in a lifted layer (rows inked across most of the width), take them out and return their rows
    and spans so a glass rule can stand there."""
    a = layer[..., 3] / 255.0
    frac = (a > 0.4).mean(1)
    rows = np.where(frac > min_frac)[0]
    found = []
    if len(rows):
        groups = np.split(rows, np.where(np.diff(rows) > 1)[0] + 1)
        for g in groups:
            if len(g) > 5:
                continue
            ys = slice(max(g[0] - 2, 0), g[-1] + 3)
            cols = np.where((a[ys] > 0.4).any(0))[0]
            found.append(((g[0] + g[-1]) / 2.0, cols.min(), cols.max()))
            layer[ys, :, 3] = 0
    return found


def icon_layer(src, rect, bgrect=None, thresh=34, polarity="dark"):
    """Copy an icon (coin, face, sun) off the old card with its own colours, without the paper around it."""
    x0, y0, x1, y1 = rect
    p = src[y0:y1, x0:x1]
    bx0, by0, bx1, by1 = bgrect or (x0 - 12, y0 - 12, x1 + 12, y1 + 12)
    ring = src[by0:by1, bx0:bx1].reshape(-1, 3)
    paper = np.median(ring, 0) if polarity == "dark" else np.median(ring, 0)
    dist = np.sqrt(((p - paper) ** 2).sum(-1))
    a = np.clip((dist - thresh * 0.5) / thresh, 0, 1)
    # unpremultiply against the paper so the rim does not carry it
    a3 = np.maximum(a, 1e-3)[..., None]
    col = np.clip((p - (1 - a3) * paper) / a3, 0, 255)
    return np.concatenate([col, a[..., None] * 255], -1)


def glass_rule(w, colour=ga.HAZE):
    layer = np.zeros((GP, w, 4))
    layer[..., :3] = rgb(colour)
    layer[..., 3] = 255
    return layer


def gem_layer():
    g = ga.gem()
    return np.asarray(g.resize((3 * GP, 3 * GP), Image.NEAREST).convert("RGBA")).astype(float)


def switch_layer(on):
    s = ga.switch(on)
    return np.asarray(s.resize((s.size[0] * GP, s.size[1] * GP), Image.NEAREST).convert("RGBA")).astype(float)


# --- one card ------------------------------------------------------------------------------------------------------------

def draw_card(out, src, card, notched=False):
    x0, y0, x1, y1 = card["rect"]
    w, h = x1 - x0, y1 - y0
    sk = card.get("skin", "glassPanel")
    if sk:
        layer = skin(sk, w, h, notched)
        if "fill" in card:  # the pressed sweep: the pressed skin on the left part only
            rest = skin(card["fill_rest"], w, h, notched)
            cut = int(round(card["fill"] * w))
            layer[:, cut:] = rest[:, cut:]
        put(out, layer, x0, y0)
    for t in card.get("tail", []):
        tx, ty, tw = t  # a speech tail under the pane: a pixel triangle of navy, tw game px wide
        rows = (tw + 1) // 2
        lay = np.zeros((rows * GP, tw * GP, 4))
        for r in range(rows):
            lay[r * GP:(r + 1) * GP, r * GP:(tw - r) * GP] = list(ga.rgba(ga.NAVY, ga.NAVY_ALPHA))
        put(out, lay, tx - tw * GP // 2, ty)
    for pr in card.get("portraits", []):
        px0, py0, px1, py1 = pr
        inner = 12 if (px1 - px0) >= 150 else 12
        out[py0 + inner:py1 - inner, px0 + inner:px1 - inner] = src[py0 + inner:py1 - inner, px0 + inner:px1 - inner]
        put(out, skin("glassPortrait", px1 - px0, py1 - py0), px0, py0)
    for ic in card.get("icons", []):
        put(out, icon_layer(src, ic, polarity=card.get("polarity", "dark")), ic[0], ic[1])
    for sw in card.get("switches", []):
        sx0, sy0, sx1, sy1, on = sw
        lay = switch_layer(on)
        put(out, lay, (sx0 + sx1) // 2 - lay.shape[1] // 2, (sy0 + sy1) // 2 - lay.shape[0] // 2)
    for tr in card.get("text", []):
        r = tr["rect"]
        txt = lift(src, r, tr.get("polarity", card.get("polarity", "dark")), roles=tr.get("roles"),
                   overrides=tr.get("over", ()))
        for (ix0, iy0, ix1, iy1) in card.get("icons", []) + [p for p in card.get("portraits", [])] + \
                [s[:4] for s in card.get("switches", [])] + card.get("erase", []):
            ex0, ey0 = max(ix0 - 6 - r[0], 0), max(iy0 - 6 - r[1], 0)
            ex1, ey1 = min(ix1 + 6 - r[0], r[2] - r[0]), min(iy1 + 6 - r[1], r[3] - r[1])
            if ex1 > ex0 and ey1 > ey0:
                txt[ey0:ey1, ex0:ex1, 3] = 0
        if tr.get("rules", True):
            for (ry, cx0, cx1) in kill_rules(txt):
                if tr.get("flourish"):
                    continue
                lay = glass_rule(int(cx1 - cx0 + 1), tr.get("rule_colour", ga.HAZE))
                put(out, lay, r[0] + int(cx0), r[1] + int(round(ry)) - GP // 2)
        if "fill" in card:
            dark = lift(src, r, tr.get("polarity", card.get("polarity", "dark")), roles=card["fill_roles"])
            dark[..., 3] = np.minimum(dark[..., 3], txt[..., 3]) if dark.shape == txt.shape else dark[..., 3]
            cut = int(round(card["fill"] * w)) - (r[0] - x0)
            if cut > 0:
                txt[:, :cut] = dark[:, :cut]
        put(out, txt, r[0], r[1])
    for fl in card.get("flourish", []):
        fx0, fy, fx1 = fl  # a flourish: two haze rules and the gem
        mid = (fx0 + fx1) // 2
        put(out, glass_rule(mid - fx0 - 3 * GP), fx0, fy - GP // 2)
        put(out, glass_rule(fx1 - mid - 3 * GP), mid + 3 * GP, fy - GP // 2)
        put(out, gem_layer(), mid - 3 * GP // 2, fy - 3 * GP // 2)


def compose(proof, notched=False):
    src = load(proof["src"])
    world = src.copy()
    for (ppath, prect, (px, py)) in proof.get("paste", []):
        # a card lifted from another screenshot onto this world: the world under it stays the real one
        piece = load(ppath)[prect[1]:prect[3], prect[0]:prect[2]]
        src = src.copy()
        src[py:py + piece.shape[0], px:px + piece.shape[1]] = piece
    for sh in proof.get("shadows", []):
        unshadow(world, *sh)
    hole = np.zeros(src.shape[:2], bool)
    for c in proof["cards"]:
        if c.get("see"):
            continue
        x0, y0, x1, y1 = c.get("hide", c["rect"])
        hole[y0:y1, x0:x1] = True
    for extra in proof.get("hide", []):
        x0, y0, x1, y1 = extra
        hole[y0:y1, x0:x1] = True
    if proof.get("plate"):
        plate = load(proof["plate"])
        world[hole] = plate[hole]
    else:
        world = inpaint(world, hole)
    out = world.copy()
    for c in proof["cards"]:
        draw_card(out, src, c, notched)
    return src, out


def save(img, path_png):
    im = Image.fromarray(np.clip(img, 0, 255).astype(np.uint8))
    im.save(path_png)
    im.resize((1311, 603), Image.LANCZOS).save(path_png[:-4] + ".jpg", quality=88)
    return im


from glassproofs import PROOFS  # noqa: E402


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("proof")
    ap.add_argument("--out", default=OUT_DEFAULT)
    ap.add_argument("--notched-line", action="store_true")
    ap.add_argument("--suffix", default="")
    ap.add_argument("--plaque-inset", type=int, default=None)
    args = ap.parse_args()
    if args.proof == "list":
        print("\n".join(PROOFS))
        return
    proof = PROOFS[args.proof]
    if callable(proof):
        proof = proof()
    if args.plaque_inset is not None:
        for k in ga.SKINS:
            if k not in ("glassPanel", "glassInset"):
                INSET[k] = args.plaque_inset
    os.makedirs(args.out, exist_ok=True)
    if "frames" in proof:
        x0, y0, x1, y1 = proof["crop"]
        sheet = np.zeros((1206, 2622, 3)) + 12
        befores = None
        for i, fr in enumerate(proof["frames"]):
            src, out = compose(fr, args.notched_line)
            sheet[i * 300 + 40:i * 300 + 40 + (y1 - y0), 150:150 + (x1 - x0)] = out[y0:y1, x0:x1]
            befores = src
        save(sheet, os.path.join(args.out, args.proof + args.suffix + "-after.png"))
        bs = np.zeros((1206, 2622, 3)) + 12
        bs[40:40 + (y1 - y0), 150:150 + (x1 - x0)] = befores[y0:y1, x0:x1]
        save(bs, os.path.join(args.out, args.proof + "-before.png"))
        print("wrote", args.proof)
        return
    src, out = compose(proof, args.notched_line)
    name = args.proof + args.suffix
    save(out, os.path.join(args.out, name + "-after.png"))
    if not args.suffix:
        save(src, os.path.join(args.out, args.proof + "-before.png"))
    print("wrote", name)


if __name__ == "__main__":
    main()
