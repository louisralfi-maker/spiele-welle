#!/usr/bin/env python3
"""Lanternhold actors and creatures (M2b art lane): multi-frame sprite strips with their glow strips, built from hand-set
part grids or from a converted key pose cut into parts (cut-out animation), plus context preview sheets.
Pure python 3 (pixelart.py's PNG and palette helpers); one sprite per run, each well under a second.

  actorart.py build <spec.txt> [--out DIR]
        Writes DIR/<id>.png (the albedo body strip) and, when any legend entry glows, DIR/<id>Glow.png (same size and
        frames). DIR defaults to games/lanternhold/Resources/Art.
  actorart.py sheet <id> <out.png> [--art DIR] [--scale 6] [--frames N]
        A context sheet of every frame at device scale: day on the ochre gorge rock, day on castle stone, night outside
        every light (body at 0.12 plus the glow strip, as the engine draws an unlit creature) and night in firelight.
  actorart.py dump <in.png> <out.txt> [--box x0,y0,x1,y1]
        A palette PNG as a text grid with a generated legend (to start hand edits on a converted painting).

Spec format (`tools/grids/actors/<id>.txt`). Directives start in column 0; their content lines are indented.
    id NAME                  output sprite id (the glow strip is NAMEGlow)
    size WxH                 one frame
    frames N
    outline COLOUR           optional: transparent pixels 4-adjacent to the body become COLOUR (a 1 px outline)
    image NAME PATH          optional: a palette PNG (e.g. a converted key pose) that parts can be cut from
    legend                   lines "X = body" or "X = body/glow" or "X = /glow" (palette names; "." is transparent);
                             a body name ending in "!" is drawn without an outline around it (bow strings, arrows)
    part NAME                the part's rows follow ("." transparent)
    part NAME image=IMG box=x0,y0,x1,y1 [mask=MASK:labels] [glow=GLOWPART]
                             a part cut from an image (exclusive box ends); with a mask (a part of the same box size
                             whose characters are labels), only pixels whose label is in `labels` are taken
    frame N[,M…]             placements follow, drawn in order: "PART x y [flip]" (top-left of the part in the frame)
    frame N = M              frame N is a copy of frame M
A body pixel also sets (or clears) the glow under it, so a part in front hides the glow of what it covers; a glow-only
entry adds glow and leaves the body. Pixels outside the frame are clipped and reported.
"""
import argparse
import math
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from pixelart import Image, Palette, read_png, write_png, DEFAULT_PALETTE  # noqa: E402

GAME = os.path.dirname(HERE)
ART = os.path.join(GAME, "Resources", "Art")


# --------------------------------------------------------------------------------------------------------- spec

class Spec:
    def __init__(self, path, pal):
        self.path = path
        self.pal = pal
        self.id = None
        self.w = self.h = 0
        self.frames = 1
        self.outline = None
        self.legend = {".": (None, None)}
        self.parts = {}
        self.images = {}
        self.placements = {}
        self.copies = {}
        self.bare = set()
        self._parse()

    def colour(self, name):
        return self.pal.color(name) if name else None

    def _parse(self):
        base = os.path.dirname(os.path.abspath(self.path))
        block = None
        target = None
        with open(self.path) as fh:
            lines = fh.read().splitlines()
        for raw in lines:
            if not raw.strip() or raw.lstrip().startswith("#"):
                continue
            if not raw[0].isspace():
                words = raw.split()
                key = words[0]
                block = None
                if key == "id":
                    self.id = words[1]
                elif key == "size":
                    self.w, self.h = (int(v) for v in words[1].lower().split("x"))
                elif key == "frames":
                    self.frames = int(words[1])
                elif key == "outline":
                    self.outline = self.colour(words[1])
                elif key == "image":
                    path = words[2]
                    if not os.path.isabs(path):
                        path = os.path.normpath(os.path.join(base, path)) if path.startswith(".") else path
                    self.images[words[1]] = path
                elif key == "legend":
                    block = "legend"
                elif key == "part":
                    name = words[1]
                    opts = dict(w.split("=", 1) for w in words[2:])
                    self.parts[name] = {"rows": [], "opts": opts}
                    block, target = "part", name
                elif key == "frame":
                    rest = raw[len("frame"):].strip()
                    if "=" in rest:
                        n, m = (v.strip() for v in rest.split("="))
                        for k in n.split(","):
                            self.copies[int(k)] = int(m)
                        block = None
                    else:
                        target = [int(k) for k in rest.split(",")]
                        for k in target:
                            self.placements[k] = []
                        block = "frame"
                else:
                    raise SystemExit(f"{self.path}: unknown directive {key}")
                continue
            s = raw.strip()
            if block == "legend":
                ch, spec = (t.strip() for t in s.split("=", 1))
                if "/" in spec:
                    body, glow = (t.strip() or None for t in spec.split("/", 1))
                else:
                    body, glow = spec, None
                bare = bool(body and body.endswith("!"))
                if bare:
                    body = body[:-1]
                self.legend[ch] = (self.colour(body), self.colour(glow))
                if bare:
                    self.bare.add(self.colour(body) + ("bare",))
                    self.legend[ch] = (self.colour(body) + ("bare",), self.colour(glow))
            elif block == "part":
                self.parts[target]["rows"].append(s)
            elif block == "frame":
                words = s.split()
                for k in target:
                    self.placements[k].append((words[0], int(words[1]), int(words[2]), "flip" in words[3:]))
            else:
                raise SystemExit(f"{self.path}: content outside a block: {s}")

    def part_pixels(self, name, cache={}):
        """A part as rows of (body, glow) tuples or None."""
        key = (self.path, name)
        if key in cache:
            return cache[key]
        part = self.parts[name]
        opts = part["opts"]
        if "image" in opts:
            img, _ = read_png(self.images[opts["image"]])
            x0, y0, x1, y1 = (int(v) for v in opts["box"].split(","))
            labels = None
            if "mask" in opts:
                mname, allowed = opts["mask"].split(":")
                labels = (self.parts[mname]["rows"], set(allowed))
            rows = []
            for y in range(y0, y1):
                row = []
                for x in range(x0, x1):
                    r, g, b, a = img.get(x, y) if 0 <= x < img.w and 0 <= y < img.h else (0, 0, 0, 0)
                    take = a > 0
                    if take and labels:
                        mrow = labels[0][y - y0]
                        ch = mrow[x - x0] if x - x0 < len(mrow) else "."
                        take = ch in labels[1]
                    row.append(((r, g, b), None) if take else None)
                rows.append(row)
        else:
            rows = []
            for line in part["rows"]:
                row = []
                for ch in line:
                    if ch not in self.legend:
                        raise SystemExit(f"{self.path}: part {name}: no legend entry for {ch!r}")
                    body, glow = self.legend[ch]
                    row.append(None if body is None and glow is None else (body, glow))
                rows.append(row)
        cache[key] = rows
        return rows

    def render(self):
        """Every frame as (body, glow) grids of RGB tuples or None."""
        out = {}
        clipped = []
        for k in range(self.frames):
            if k in self.copies:
                continue
            if k not in self.placements:
                raise SystemExit(f"{self.path}: frame {k} has no placements")
            body = [[None] * self.w for _ in range(self.h)]
            glow = [[None] * self.w for _ in range(self.h)]
            for name, px, py, flip in self.placements[k]:
                rows = self.part_pixels(name)
                pw = max((len(r) for r in rows), default=0)
                for j, row in enumerate(rows):
                    for i in range(pw):
                        src = row[pw - 1 - i] if flip else (row[i] if i < len(row) else None)
                        if flip and pw - 1 - i >= len(row):
                            src = None
                        if src is None:
                            continue
                        x, y = px + i, py + j
                        if not (0 <= x < self.w and 0 <= y < self.h):
                            clipped.append((k, name, x, y))
                            continue
                        b, g = src
                        if b is not None:
                            body[y][x] = b
                            glow[y][x] = g
                        elif g is not None:
                            glow[y][x] = g
            if self.outline:
                add = []
                for y in range(self.h):
                    for x in range(self.w):
                        if body[y][x] is not None:
                            continue
                        for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
                            if 0 <= nx < self.w and 0 <= ny < self.h and body[ny][nx] is not None \
                                    and len(body[ny][nx]) == 3:
                                add.append((x, y))
                                break
                for x, y in add:
                    body[y][x] = self.outline
                    glow[y][x] = None
            for y in range(self.h):
                for x in range(self.w):
                    if body[y][x] is not None and len(body[y][x]) > 3:
                        body[y][x] = body[y][x][:3]
            out[k] = (body, glow)
        for k, m in self.copies.items():
            out[k] = out[m]
        if clipped:
            seen = sorted({(k, n) for k, n, _, _ in clipped})
            print(f"warning: {len(clipped)} pixels outside the frame: " + ", ".join(f"f{k}:{n}" for k, n in seen))
        return out


def cmd_build(a):
    pal = Palette(a.palette, True)
    spec = Spec(a.spec, pal)
    frames = spec.render()
    W, H = spec.w * spec.frames, spec.h
    body = Image(W, H)
    glow = Image(W, H)
    any_glow = False
    for k in range(spec.frames):
        b, g = frames[k]
        for y in range(H):
            for x in range(spec.w):
                if b[y][x] is not None:
                    body.set(k * spec.w + x, y, b[y][x] + (255,))
                if g[y][x] is not None:
                    glow.set(k * spec.w + x, y, g[y][x] + (255,))
                    any_glow = True
    out = a.out or ART
    write_png(os.path.join(out, spec.id + ".png"), body)
    msg = f"wrote {spec.id}.png {W}x{H} ({spec.frames} frames of {spec.w}x{spec.h})"
    if any_glow:
        write_png(os.path.join(out, spec.id + "Glow.png"), glow)
        msg += f" and {spec.id}Glow.png"
    print(msg)
    # every frame keeps something on the bottom row (the foot point), unless the sprite flies or floats
    for k in range(spec.frames):
        b, _ = frames[k]
        if all(v is None for v in b[H - 1]):
            print(f"  note: frame {k} has nothing on the bottom row")


# -------------------------------------------------------------------------------------------------------- sheet

NIGHT_AMB = (0.288, 0.331, 0.616)   # mock.py's ambW at tod 0.95 with the M1b look values
NT = (1.03, 0.86, 1.66)
FIRE = (1.0, 0.54, 0.16)


def contract():
    out = {}
    path = os.path.join(GAME, "SPRITES.md")
    text = open(path).read()
    for line in text.splitlines():
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if len(cells) < 3 or "`" not in cells[0]:
            continue
        ids = re.findall(r"`(\w+)`", cells[0])
        sizes = re.findall(r"(\d+)x(\d+)", cells[1])
        n = re.match(r"(\d+)", cells[2])
        if not ids or not sizes or not n:
            continue
        for k, i in enumerate(ids):
            w, h = sizes[k] if len(sizes) == len(ids) else sizes[0]
            out[i] = (int(w), int(h), int(n.group(1)))
    return out


def load_strip(path, n):
    if not os.path.exists(path):
        return None
    img, _ = read_png(path)
    fw = img.w // n
    frames = []
    for k in range(n):
        frames.append([[img.get(k * fw + x, y) for x in range(fw)] for y in range(img.h)])
    return frames


def lit_day(c):
    return tuple(min(1.0, c[i] / 255 * (1.0, 0.98, 0.94)[i]) for i in range(3))


def lit_night(c, shade, light):
    a = [c[i] / 255 * shade * NIGHT_AMB[i] for i in range(3)]
    lu = 0.299 * a[0] + 0.587 * a[1] + 0.114 * a[2]
    a = [a[i] + (lu * NT[i] - a[i]) * 0.6 for i in range(3)]
    return tuple(a[i] + c[i] / 255 * shade * light[i] for i in range(3))


def cmd_sheet(a):
    con = contract()
    art = a.art or ART
    w, h, n = con.get(a.id, (0, 0, 1))
    if a.frames:
        n = a.frames
    body = load_strip(os.path.join(art, a.id + ".png"), n)
    glow = load_strip(os.path.join(art, a.id + "Glow.png"), n)
    fw, fh = len(body[0][0]), len(body[0])
    rock, _ = read_png(os.path.join(art, "throatRock.png"))
    stone, _ = read_png(os.path.join(art, "castleWall.png"))
    ground, _ = read_png(os.path.join(art, "ground.png"))
    pad = 6
    cw, chh = fw + 2 * pad, fh + pad + 8
    rows = ["day rock", "day stone", "night unlit", "night firelit"]
    W, H = cw * n, chh * len(rows)
    out = [[(0, 0, 0)] * W for _ in range(H)]
    for r, mode in enumerate(rows):
        for k in range(n):
            ox, oy = k * cw, r * chh
            groundy = oy + chh - 8
            for y in range(chh):
                for x in range(cw):
                    X, Y = ox + x, oy + y
                    if Y >= groundy:
                        p = ground.get((X) % ground.w, min(ground.h - 1, Y - groundy))
                    else:
                        src = stone if mode == "day stone" else rock
                        p = src.get((X * 1 + 40) % src.w, (Y + 60) % src.h)
                        if p[3] == 0:
                            p = (60, 50, 60, 255)
                    if mode.startswith("day"):
                        c = lit_day(p)
                    elif mode == "night unlit":
                        c = lit_night(p, 1.0, (0, 0, 0))
                    else:
                        d = abs(x - cw * 0.85) / (cw * 1.2)
                        f = max(0.0, 1 - d) ** 2 * 1.6
                        c = lit_night(p, 1.0, tuple(v * f for v in FIRE))
                    out[Y][X] = c
            for y in range(fh):
                for x in range(fw):
                    X, Y = ox + pad + x, groundy - fh + y
                    p = body[k][y][x]
                    g = glow[k][y][x] if glow else (0, 0, 0, 0)
                    base = out[Y][X]
                    if p[3]:
                        if mode.startswith("day"):
                            c = lit_day(p)
                        elif mode == "night unlit":
                            c = lit_night(p, 0.12, (0, 0, 0))
                        else:
                            d = abs(pad + x - cw * 0.85) / (cw * 1.2)
                            f = max(0.0, 1 - d) ** 2 * 1.6
                            c = lit_night(p, 1.0, tuple(v * f for v in FIRE))
                        base = c
                    if g[3]:
                        base = tuple(base[i] + g[i] / 255 for i in range(3))
                    out[Y][X] = base
    s = a.scale
    img = Image(W * s, H * s)
    px = []
    for y in range(H):
        line = []
        for x in range(W):
            c = out[y][x]
            t = tuple(min(255, max(0, int(v * 255 + 0.5))) for v in c) + (255,)
            line.extend([t] * s)
        for _ in range(s):
            px.extend(line)
    img.px = px
    write_png(a.output, img)
    print(f"wrote {a.output} {W * s}x{H * s}")


# --------------------------------------------------------------------------------------------------------- dump

LETTERS = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"


def cmd_dump(a):
    pal = Palette(a.palette, True)
    lut = {c: n for n, c in zip(pal.names, pal.rgb)}
    img, _ = read_png(a.input)
    x0, y0, x1, y1 = (int(v) for v in a.box.split(",")) if a.box else (0, 0, img.w, img.h)
    counts = {}
    for y in range(y0, y1):
        for x in range(x0, x1):
            p = img.get(x, y)
            if p[3]:
                n = lut.get(p[:3])
                if n is None:
                    raise SystemExit(f"off-palette colour {p[:3]} at {x},{y}")
                counts[n] = counts.get(n, 0) + 1
    names = sorted(counts, key=lambda n: -counts[n])
    ch = {n: LETTERS[i] for i, n in enumerate(names)}
    with open(a.output, "w") as fh:
        fh.write("legend\n")
        for n in names:
            fh.write(f"    {ch[n]} = {n}\n")
        fh.write("part dump\n")
        for y in range(y0, y1):
            line = "".join(ch[lut[img.get(x, y)[:3]]] if img.get(x, y)[3] else "." for x in range(x0, x1))
            fh.write("    " + line + "\n")
    print(f"wrote {a.output} ({x1 - x0}x{y1 - y0}, {len(names)} colours)")


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = p.add_subparsers(dest="cmd", required=True)
    b = sub.add_parser("build")
    b.add_argument("spec")
    b.add_argument("--out")
    b.add_argument("--palette", default=DEFAULT_PALETTE)
    b.set_defaults(fn=cmd_build)
    s = sub.add_parser("sheet")
    s.add_argument("id")
    s.add_argument("output")
    s.add_argument("--art")
    s.add_argument("--scale", type=int, default=6)
    s.add_argument("--frames", type=int)
    s.set_defaults(fn=cmd_sheet)
    d = sub.add_parser("dump")
    d.add_argument("input")
    d.add_argument("output")
    d.add_argument("--box")
    d.add_argument("--palette", default=DEFAULT_PALETTE)
    d.set_defaults(fn=cmd_dump)
    a = p.parse_args()
    a.fn(a)


if __name__ == "__main__":
    main()
