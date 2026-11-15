#!/usr/bin/env python3
"""Lanternhold's cast in the realm's three stages (the people lane, docs/PEOPLE.md section 7, docs/SPRITES-people.md
"Cloth states"). Louis, 14.11.2026: "Wir machen unsere Burg, Königreich, Stadt, Land immer wohlhabender." The people's
cloth follows the realm's stage (docs/REALM.md section 2: hamlet, village, town): patched and faded in the hamlet,
mended and whole in the village, good wool with a little colour in the town. Wealth changes the cloth, never the
people: a state only recolours cloth characters of the body's own part grid, so body, face, posture, walk and every
pixel's place stay the same.

A state is written into the body's grid as comment lines, which tools/actorart.py skips (the hamlet build stays byte
for byte):

    #@state town  n=waterDeep b=roofDeep x=soil

Several lines of one state add up. A seated form that includes its standing body's spec takes that body's state lines
first and its own after. Only characters of the legend may be remapped; the alpha of every frame stays the same.

  peoplestates.py build <spec.txt> [--out DIR] [--state village|town|all]
        Writes DIR/<id>Village.png and DIR/<id>Town.png (DIR defaults to games/lanternhold/Resources/Art), each from
        the hamlet body with the state's remaps, through actorart.py's own renderer.
  peoplestates.py check <spec.txt> [--art DIR]
        Compares the built states with the hamlet body: the alpha must match in every pixel; prints how many pixels
        each state recolours and which colours become which.
Pure python 3, one body per run, well under a second; on this old Mac run it through the director's art lock.
"""
import argparse
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import actorart  # noqa: E402
from pixelart import Image, Palette, read_png, write_png, DEFAULT_PALETTE  # noqa: E402

STATES = ("village", "town")


def state_lines(path):
    """state -> {char: palette name}, the included specs' lines first."""
    out = {}
    base = os.path.dirname(os.path.abspath(path))
    with open(path) as fh:
        lines = fh.read().splitlines()
    for raw in lines:
        if raw.startswith("include "):
            for state, remap in state_lines(os.path.join(base, raw.split()[1])).items():
                out.setdefault(state, {}).update(remap)
    for raw in lines:
        if not raw.startswith("#@state "):
            continue
        words = raw[len("#@state "):].split()
        state = words[0]
        if state not in STATES:
            raise SystemExit(f"{path}: unknown state {state} (states: {', '.join(STATES)})")
        for pair in words[1:]:
            if pair.startswith("#"):
                break
            ch, name = pair.split("=", 1)
            if len(ch) != 1:
                raise SystemExit(f"{path}: a remap takes one legend character: {pair}")
            out.setdefault(state, {})[ch] = name
    return out


def render_state(path, pal, state, remap):
    actorart.Spec.part_pixels.__defaults__[0].clear()  # the part cache is per path: a fresh legend needs fresh parts
    spec = actorart.Spec(path, pal)
    for ch, name in remap.items():
        if ch not in spec.legend or ch == ".":
            raise SystemExit(f"{path}: state {state}: {ch!r} is not a legend character")
        body, glow = spec.legend[ch]
        if body is None:
            raise SystemExit(f"{path}: state {state}: {ch!r} is glow only")
        colour = pal.color(name)
        spec.legend[ch] = (colour + (("bare",) if len(body) > 3 else ()), glow)
    spec.id = spec.id + state.capitalize()
    return spec, spec.render()


def cmd_build(a):
    pal = Palette(a.palette, True)
    states = state_lines(a.spec)
    wanted = STATES if a.state == "all" else (a.state,)
    out = a.out or actorart.ART
    for state in wanted:
        if state not in states:
            raise SystemExit(f"{a.spec}: no #@state {state} lines")
        spec, frames = render_state(a.spec, pal, state, states[state])
        W, H = spec.w * spec.frames, spec.h
        img = Image(W, H)
        for k in range(spec.frames):
            body, _ = frames[k]
            for y in range(H):
                for x in range(spec.w):
                    if body[y][x] is not None:
                        img.set(k * spec.w + x, y, body[y][x] + (255,))
        write_png(os.path.join(out, spec.id + ".png"), img)
        print(f"wrote {spec.id}.png {W}x{H} ({state}: {len(states[state])} cloth colours remapped)")


def cmd_check(a):
    pal = Palette(DEFAULT_PALETTE, True)
    names = {c: n for n, c in zip(pal.names, pal.rgb)}
    art = a.art or actorart.ART
    spec = actorart.Spec(a.spec, pal)
    base, _ = read_png(os.path.join(art, spec.id + ".png"))
    bad = False
    for state in STATES:
        path = os.path.join(art, spec.id + state.capitalize() + ".png")
        if not os.path.exists(path):
            print(f"{state}: missing {os.path.basename(path)}")
            bad = True
            continue
        img, _ = read_png(path)
        if (img.w, img.h) != (base.w, base.h):
            print(f"{state}: size {img.w}x{img.h}, the body is {base.w}x{base.h}")
            bad = True
            continue
        changed, pairs, shape = 0, {}, 0
        for y in range(base.h):
            for x in range(base.w):
                p, q = base.get(x, y), img.get(x, y)
                if (p[3] > 0) != (q[3] > 0):
                    shape += 1
                elif p[3] and p[:3] != q[:3]:
                    changed += 1
                    key = (names.get(p[:3], p[:3]), names.get(q[:3], q[:3]))
                    pairs[key] = pairs.get(key, 0) + 1
        if shape:
            bad = True
        moves = ", ".join(f"{s}>{t} {n}" for (s, t), n in sorted(pairs.items(), key=lambda kv: -kv[1]))
        print(f"{spec.id} {state}: {changed} pixels recoloured, {shape} change shape; {moves}")
    if bad:
        raise SystemExit(1)


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = p.add_subparsers(dest="cmd", required=True)
    b = sub.add_parser("build")
    b.add_argument("spec")
    b.add_argument("--out")
    b.add_argument("--state", default="all", choices=STATES + ("all",))
    b.add_argument("--palette", default=DEFAULT_PALETTE)
    b.set_defaults(fn=cmd_build)
    c = sub.add_parser("check")
    c.add_argument("spec")
    c.add_argument("--art")
    c.set_defaults(fn=cmd_check)
    a = p.parse_args()
    a.fn(a)


if __name__ == "__main__":
    main()
