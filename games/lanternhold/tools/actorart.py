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
  actorart.py texture <in.png> <out.png> --colour NAME --to NAME --light NAME [--cell 5] [--seed 1] [--rect x0,y0,x1,y1]
        Breaks flat areas of one colour into a seeded cobble of boulders (Voronoi cells: crevices keep the colour,
        cell interiors take --to, their upper-left rim --light), so a dark band of a converted painting gets form.
  actorart.py cracks <in.png> <out.png> --seed NAME --along NAME,… [--min 2] [--max 4] [--seed-value 1]
                     [--path x0,y0:x1,y1 …]
        Grows the lone specks of a crack colour into strokes of --min to --max pixels along the crevice colours, so
        a converted painting's scattered red dots become ember cracks between its boulders (glowmap makes them glow);
        each --path draws a long fissure first, the cheapest way between its two points along the crevices.

Spec format (`tools/grids/actors/<id>.txt`). Directives start in column 0; their content lines are indented.
    id NAME                  output sprite id (the glow strip is NAMEGlow)
    size WxH                 one frame
    frames N
    outline COLOUR [shade]   optional: transparent pixels 4-adjacent to the body become COLOUR (a 1 px outline); with
                             "shade" only the pixels right of and below the body (look 2's selective outline: the
                             shadow side and the ground contact, the lit upper left stays open)
    rim GLOW [TIP]           optional, with an outline: the top contour (the outline pixel above each column's topmost
                             body pixel) glows GLOW in every frame, a smouldering edge that carries the silhouette at
                             night; TIP lights the rim over 1 px wide spikes (crest flakes, ears, stake points)
    include FILE             optional: takes the legend and the parts of another spec beside this one (a second sprite
                             of the same figure: the lord seated); later legend entries and parts replace them
    image NAME PATH          optional: a palette PNG (e.g. a converted key pose) that parts can be cut from
    glowmap COLOUR=GLOW …    image parts: pixels of that body colour glow (the ember cracks of a converted painting)
    legend                   lines "X = body" or "X = body/glow" or "X = /glow" (palette names; "." is transparent);
                             a body name ending in "!" is drawn without an outline around it (bow strings, arrows)
    part NAME                the part's rows follow ("." transparent)
    part NAME image=IMG box=x0,y0,x1,y1 [mask=MASK:labels]
                             a part cut from an image (exclusive box ends); with a mask (a part of the same box size
                             whose characters are labels), only pixels whose label is in `labels` are taken
    part NAME image=IMG poly=x,y;x,y;…[|x,y;…]
                             cut-out animation: the image pixels inside the polygon(s), as a full-size layer whose
                             placement is an offset; the poly parts of one image are resolved in declaration order
                             (later ones lie in front, the ones behind are underpainted where they are covered)
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
        self.shade_only = False
        self.rim = None
        self.legend = {".": (None, None)}
        self.parts = {}
        self.images = {}
        self.placements = {}
        self.copies = {}
        self.bare = set()
        self.glowmap = {}
        self._parse()

    def colour(self, name):
        return self.pal.color(name) if name else None

    def _parse(self):
        base = os.path.dirname(os.path.abspath(self.path))
        block = None
        target = None
        with open(self.path) as fh:
            lines = fh.read().splitlines()
        expanded = []
        for raw in lines:  # include FILE: the legend and the parts of another spec (its other directives are skipped)
            if raw.startswith("include "):
                keep = False
                with open(os.path.join(base, raw.split()[1])) as fh:
                    for inc in fh.read().splitlines():
                        if inc.strip() and not inc[0].isspace() and not inc.startswith("#"):
                            keep = inc.split()[0] in ("legend", "part")
                        if keep:
                            expanded.append(inc)
            else:
                expanded.append(raw)
        for raw in expanded:
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
                    self.shade_only = len(words) > 2 and words[2] == "shade"
                elif key == "rim":
                    self.rim = (self.colour(words[1]), self.colour(words[2]) if len(words) > 2 else None)
                elif key == "image":
                    path = words[2]
                    if not os.path.isabs(path):
                        path = os.path.normpath(os.path.join(base, path)) if path.startswith(".") else path
                    self.images[words[1]] = path
                elif key == "glowmap":
                    for pair in words[1:]:
                        a, b = pair.split("=")
                        self.glowmap[self.colour(a)] = self.colour(b)
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
        if "image" in opts and "poly" in opts:
            rows = self._cutout(opts["image"])[name]
        elif "image" in opts:
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

    def _cutout(self, image, cache={}):
        """Cut-out animation: every `poly=` part of one image, in declaration order (later parts lie in front). A key
        pixel belongs to the frontmost part whose polygon holds it; where a part in front covers a part, the part
        behind is underpainted from its own pixels (nearest colour, spreading row-wise first), so a limb that moves
        1 or 2 px uncovers body, not a hole. Each part is a full-size layer: its placement is an offset."""
        key = (self.path, image)
        if key in cache:
            return cache[key]
        img, _ = read_png(self.images[image])
        W, H = img.w, img.h
        names = [n for n, p in self.parts.items() if p["opts"].get("image") == image and "poly" in p["opts"]]

        def polys(spec):
            out = []
            for poly in spec.split("|"):
                out.append([tuple(float(v) for v in pt.split(",")) for pt in poly.split(";")])
            return out

        def inside(pts, x, y):
            c = False
            j = len(pts) - 1
            for i in range(len(pts)):
                xi, yi = pts[i]
                xj, yj = pts[j]
                if (yi > y) != (yj > y) and x < (xj - xi) * (y - yi) / (yj - yi) + xi:
                    c = not c
                j = i
            return c

        regions = {}
        for n in names:
            ps = polys(self.parts[n]["opts"]["poly"])
            regions[n] = [[any(inside(p, x + 0.5, y + 0.5) for p in ps) for x in range(W)] for y in range(H)]
        owner = [[None] * W for _ in range(H)]
        for y in range(H):
            for x in range(W):
                if img.get(x, y)[3] == 0:
                    continue
                for n in names:  # the last match wins: front
                    if regions[n][y][x]:
                        owner[y][x] = n
        out = {}
        for idx, n in enumerate(names):
            layer = [[None] * W for _ in range(H)]
            front = set(names[idx + 1:])
            todo = set()
            for y in range(H):
                for x in range(W):
                    if owner[y][x] == n:
                        rgb = img.get(x, y)[:3]
                        layer[y][x] = (rgb, self.glowmap.get(rgb))
                    elif regions[n][y][x] and owner[y][x] in front:
                        todo.add((x, y))
            while todo:
                grown = []
                for (x, y) in todo:
                    for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
                        if 0 <= nx < W and 0 <= ny < H and layer[ny][nx] is not None:
                            grown.append(((x, y), layer[ny][nx]))
                            break
                if not grown:
                    break
                for (x, y), c in grown:
                    layer[y][x] = c
                    todo.discard((x, y))
            out[n] = layer
        cache[key] = out
        return out

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
                        for nx, ny in (((x - 1, y), (x, y - 1)) if self.shade_only
                                       else ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1))):
                            if 0 <= nx < self.w and 0 <= ny < self.h and body[ny][nx] is not None \
                                    and len(body[ny][nx]) == 3:
                                add.append((x, y))
                                break
                for x, y in add:
                    body[y][x] = self.outline
                    glow[y][x] = None
                if self.rim:
                    edge = set(add)

                    def solid(x, y):  # a body pixel of the drawing (not the outline, not a bare string or blade)
                        return 0 <= x < self.w and 0 <= y < self.h and (x, y) not in edge \
                            and body[y][x] is not None and len(body[y][x]) == 3

                    # the top contour: the outline pixel right above each column's topmost body pixel (legs and
                    # arms under the body stay dark)
                    lit, tip = self.rim
                    for x in range(self.w):
                        y = next((y for y in range(self.h) if solid(x, y)), None)
                        if y is None or (x, y - 1) not in edge:
                            continue
                        spike = tip is not None and not solid(x - 1, y) and not solid(x + 1, y)
                        glow[y - 1][x] = tip if spike else lit
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


def cmd_texture(a):
    pal = Palette(a.palette, True)
    img, _ = read_png(a.input)
    src, mid, light = pal.color(a.colour), pal.color(a.to), pal.color(a.light)
    cell = a.cell
    x0, y0, x1, y1 = (int(v) for v in a.rect.split(",")) if a.rect else (0, 0, img.w - 1, img.h - 1)

    def rnd(i, j, k):
        v = (i * 73856093) ^ (j * 19349663) ^ (k * 83492791) ^ (a.seed * 2654435761)
        v = (v ^ (v >> 13)) * 1274126177 & 0xFFFFFFFF
        return ((v ^ (v >> 16)) & 0xFFFF) / 65535.0

    seeds = {}
    for j in range(-1, img.h // cell + 2):
        for i in range(-1, img.w // cell + 2):
            seeds[(i, j)] = (i * cell + rnd(i, j, 1) * cell, j * cell + rnd(i, j, 2) * cell)
    out = Image(img.w, img.h, list(img.px))
    for y in range(max(0, y0), min(img.h, y1 + 1)):
        for x in range(max(0, x0), min(img.w, x1 + 1)):
            p = img.get(x, y)
            if not p[3] or p[:3] != src:
                continue
            ci, cj = int(x // cell), int(y // cell)
            best = []
            for j in range(cj - 1, cj + 2):
                for i in range(ci - 1, ci + 2):
                    sx, sy = seeds[(i, j)]
                    best.append(((x + 0.5 - sx) ** 2 + (y + 0.5 - sy) ** 2, sx, sy))
            best.sort()
            d1, sx, sy = best[0]
            d2 = best[1][0]
            if math.sqrt(d2) - math.sqrt(d1) < 1.1:
                continue  # crevice
            dx, dy = x + 0.5 - sx, y + 0.5 - sy
            c = light if (dx + dy < -cell * 0.45) else mid
            out.set(x, y, c + (255,))
    write_png(a.output, out)
    print(f"wrote {a.output} (texture {a.colour} -> {a.to}/{a.light}, cell {cell})")


def cmd_cracks(a):
    """Specks of a crack colour (a converted painting's lone red pixels) grown into strokes: every component smaller
    than --min pixels walks on from both ends along the crevice colours (--along, in order of preference; never into
    lit stone, the background or another crack) until it is --min to --max pixels long (a seeded choice per speck)."""
    pal = Palette(a.palette, True)
    img, _ = read_png(a.input)
    W, H = img.w, img.h
    seed = pal.color(a.seed)
    along = [pal.color(n) for n in a.along.split(",")]
    crack = {(x, y) for y in range(H) for x in range(W) if img.get(x, y)[3] and img.get(x, y)[:3] == seed}
    comps, seen = [], set()
    for p in sorted(crack, key=lambda q: (q[1], q[0])):
        if p in seen:
            continue
        stack, comp = [p], []
        seen.add(p)
        while stack:
            q = stack.pop()
            comp.append(q)
            for dx in (-1, 0, 1):
                for dy in (-1, 0, 1):
                    r = (q[0] + dx, q[1] + dy)
                    if r in crack and r not in seen:
                        seen.add(r)
                        stack.append(r)
        comps.append(sorted(comp, key=lambda q: (q[1], q[0])))

    def rnd(i, k):
        v = (i * 73856093) ^ (k * 19349663) ^ (a.seed_value * 83492791)
        v = (v ^ (v >> 13)) * 1274126177 & 0xFFFFFFFF
        return ((v ^ (v >> 16)) & 0xFFFF) / 65535.0

    dirs = [(1, 0), (1, 1), (0, 1), (-1, 1), (-1, 0), (-1, -1), (0, -1), (1, -1)]
    out = Image(W, H, list(img.px))
    # fissures first: the cheapest 8-connected path between two points through the body, cheap along the crevice
    # colours and dear across lit stone, so a long crack follows the boulders' joints
    import heapq
    fissure = set()
    def snap(p):  # the nearest body pixel
        if img.get(*p)[3]:
            return p
        ring = sorted(((dx * dx + dy * dy, dx, dy) for dx in range(-6, 7) for dy in range(-6, 7)))
        for _, dx, dy in ring:
            q = (p[0] + dx, p[1] + dy)
            if 0 <= q[0] < W and 0 <= q[1] < H and img.get(*q)[3]:
                return q
        raise SystemExit(f"cracks: no body pixel near {p}")

    for spec in a.path or []:
        (x0, y0), (x1, y1) = (snap(tuple(int(v) for v in q.split(","))) for q in spec.split(":"))
        cost = {(x0, y0): 0.0}
        prev = {}
        heap = [(0.0, x0, y0)]
        while heap:
            c, x, y = heapq.heappop(heap)
            if (x, y) == (x1, y1):
                break
            if c > cost.get((x, y), 1e9):
                continue
            for dx, dy in dirs:
                X, Y = x + dx, y + dy
                if not (0 <= X < W and 0 <= Y < H) or not img.get(X, Y)[3]:
                    continue
                col = img.get(X, Y)[:3]
                step = (1 + along.index(col) * 3) if col in along else (1 if col == seed else 14)
                nc = c + step * (1.41 if dx and dy else 1.0)
                if nc < cost.get((X, Y), 1e9):
                    cost[(X, Y)] = nc
                    prev[(X, Y)] = (x, y)
                    heapq.heappush(heap, (nc, X, Y))
        p = (x1, y1)
        if p not in prev:
            raise SystemExit(f"cracks: no path {spec}")
        while p != (x0, y0):
            fissure.add(p)
            p = prev[p]
        fissure.add((x0, y0))
    for x, y in fissure:
        out.set(x, y, seed + (255,))
    owner = {p: i for i, c in enumerate(comps) for p in c}
    for p in fissure:
        owner.setdefault(p, -1)
    grown = len(fissure)
    for i, comp in enumerate(comps):
        if len(comp) >= a.min:
            continue
        target = a.min + int(rnd(i, 1) * (a.max - a.min + 1) * 0.999)
        mine = set(comp)

        def free(p):
            x, y = p
            if not (0 <= x < W and 0 <= y < H) or p in mine:
                return None
            c = img.get(x, y)
            if not c[3] or c[:3] not in along:
                return None
            for dx in (-1, 0, 1):
                for dy in (-1, 0, 1):
                    if owner.get((x + dx, y + dy), i) != i:
                        return None  # keeps clear of the other cracks: strokes, not blobs
            return along.index(c[:3])

        # the stroke's axis: along the pair, else the direction with the longest run of crevice pixels
        if len(comp) > 1:
            d = (comp[-1][0] - comp[0][0], comp[-1][1] - comp[0][1])
            d = (max(-1, min(1, d[0])), max(-1, min(1, d[1])))
        else:
            best = None
            for k, d0 in enumerate(dirs[:4]):
                run = 0
                for sgn in (1, -1):
                    x, y = comp[0]
                    for _ in range(3):
                        x, y = x + sgn * d0[0], y + sgn * d0[1]
                        if free((x, y)) is None:
                            break
                        run += 1
                score = run + rnd(i, 10 + k) * 0.5
                if best is None or score > best[0]:
                    best = (score, d0)
            d = best[1]
        ends = [[comp[-1], d], [comp[0], (-d[0], -d[1])]]
        side = 0
        stuck = [False, False]
        while len(mine) < target and not all(stuck):
            if stuck[side]:
                side = 1 - side
                continue
            (x, y), (dx, dy) = ends[side]
            k = dirs.index((dx, dy))
            pick = None
            for turn in (0, 1, -1):
                nd = dirs[(k + turn) % 8]
                f = free((x + nd[0], y + nd[1]))
                if f is not None and (pick is None or f < pick[0]):
                    pick = (f, nd)
            if pick is None:
                stuck[side] = True
            else:
                nd = pick[1]
                p = (x + nd[0], y + nd[1])
                mine.add(p)
                owner[p] = i
                ends[side] = [p, nd]
                out.set(p[0], p[1], seed + (255,))
                grown += 1
            side = 1 - side
    write_png(a.output, out)
    print(f"wrote {a.output} ({len(comps)} cracks, {grown} pixels grown)")


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
    t = sub.add_parser("texture")
    t.add_argument("input")
    t.add_argument("output")
    t.add_argument("--colour", required=True)
    t.add_argument("--to", required=True)
    t.add_argument("--light", required=True)
    t.add_argument("--cell", type=int, default=5)
    t.add_argument("--seed", type=int, default=1)
    t.add_argument("--rect")
    t.add_argument("--palette", default=DEFAULT_PALETTE)
    t.set_defaults(fn=cmd_texture)
    c = sub.add_parser("cracks")
    c.add_argument("input")
    c.add_argument("output")
    c.add_argument("--seed", required=True, help="the crack colour (e.g. tile)")
    c.add_argument("--along", required=True, help="crevice colours a crack may grow into, best first")
    c.add_argument("--min", type=int, default=2)
    c.add_argument("--max", type=int, default=4)
    c.add_argument("--seed-value", type=int, default=1)
    c.add_argument("--path", action="append", help="x0,y0:x1,y1 a long fissure along the crevices (repeatable)")
    c.add_argument("--palette", default=DEFAULT_PALETTE)
    c.set_defaults(fn=cmd_cracks)
    a = p.parse_args()
    a.fn(a)


if __name__ == "__main__":
    main()
