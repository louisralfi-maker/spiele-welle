"""Figures and hand-shaped parts for the lantern slides (panels lane): a sparse layer a figure is drawn into, so it can
be outlined, rim-lit and lit in palette steps as one cluster before it goes onto the canvas; and the court's portraits
carried to a smaller scale by area vote (never by blending: every pixel stays one of the portrait's own colours).
"""
import math

from paint import P, W, H, step, _clip


class Layer:
    def __init__(self):
        self.px = {}

    def put(self, x, y, colour):
        self.px[(int(x), int(y))] = _clip(colour)

    def has(self, x, y):
        return (int(x), int(y)) in self.px

    def get(self, x, y):
        return self.px.get((int(x), int(y)))

    def poly(self, pts, colour, fn=None):
        ys = [p[1] for p in pts]
        n = len(pts)
        for y in range(int(math.floor(min(ys))), int(math.ceil(max(ys))) + 1):
            cy = y + 0.5
            xs = []
            for i in range(n):
                x0, y0 = pts[i]
                x1, y1 = pts[(i + 1) % n]
                if (y0 <= cy < y1) or (y1 <= cy < y0):
                    xs.append(x0 + (cy - y0) * (x1 - x0) / (y1 - y0))
            xs.sort()
            for i in range(0, len(xs) - 1, 2):
                for x in range(int(math.ceil(xs[i] - 0.5)), int(math.floor(xs[i + 1] - 0.5)) + 1):
                    self.put(x, y, fn(x, y) if fn else colour)

    def capsule(self, p0, p1, r0, r1, colour, fn=None):
        """A tapered limb from p0 (radius r0) to p1 (radius r1)."""
        (ax, ay), (bx, by) = p0, p1
        m = max(r0, r1)
        dx, dy = bx - ax, by - ay
        ll = dx * dx + dy * dy or 1e-9
        for y in range(int(min(ay, by) - m - 1), int(max(ay, by) + m + 2)):
            for x in range(int(min(ax, bx) - m - 1), int(max(ax, bx) + m + 2)):
                px, py = x + 0.5 - ax, y + 0.5 - ay
                t = max(0.0, min(1.0, (px * dx + py * dy) / ll))
                r = r0 + (r1 - r0) * t
                ex, ey = px - dx * t, py - dy * t
                if ex * ex + ey * ey <= r * r:
                    self.put(x, y, fn(x, y) if fn else colour)

    def ellipse(self, cx, cy, rx, ry, colour, fn=None):
        for y in range(int(cy - ry - 1), int(cy + ry + 2)):
            for x in range(int(cx - rx - 1), int(cx + rx + 2)):
                if ((x + 0.5 - cx) / rx) ** 2 + ((y + 0.5 - cy) / ry) ** 2 <= 1:
                    self.put(x, y, fn(x, y) if fn else colour)

    def rows(self, rows, x0, y0, flip=False, alpha_cut=128, remap=None):
        h = len(rows)
        w = len(rows[0]) if h else 0
        for y in range(h):
            for x in range(w):
                c = rows[y][w - 1 - x if flip else x]
                if c[3] < alpha_cut:
                    continue
                col = (c[0], c[1], c[2])
                if remap:
                    col = remap(col)
                self.put(x0 + x, y0 + y, col)

    def grid(self, text, x0, y0, legend, flip=False):
        lines = text.strip("\n").split("\n")
        w = max(len(line) for line in lines)
        for y, line in enumerate(lines):
            for x, ch in enumerate(line):
                if ch in " .":
                    continue
                col = legend[ch]
                X = x0 + (w - 1 - x if flip else x)
                self.put(X, y0 + y, col(X, y0 + y) if callable(col) else col)

    def line(self, pts, colour):
        """A 1 px polyline (Bresenham), for folds, seams and stitches."""
        for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
            x0, y0, x1, y1 = int(round(x0)), int(round(y0)), int(round(x1)), int(round(y1))
            dx, dy = abs(x1 - x0), -abs(y1 - y0)
            sx, sy = (1 if x0 < x1 else -1), (1 if y0 < y1 else -1)
            err = dx + dy
            while True:
                self.put(x0, y0, colour(x0, y0) if callable(colour) else colour)
                if x0 == x1 and y0 == y1:
                    break
                e2 = 2 * err
                if e2 >= dy:
                    err += dy
                    x0 += sx
                if e2 <= dx:
                    err += dx
                    y0 += sy

    def recolour(self, fn):
        for k in list(self.px):
            self.px[k] = _clip(fn(k[0], k[1], self.px[k]))

    def outline(self, colour=None, skip_bottom=True):
        """The outer ink line: every empty pixel beside the figure (4-neighbours) takes the ink."""
        ink = colour or P("ink")
        add = set()
        for (x, y) in self.px:
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                if skip_bottom and dy == 1:
                    continue
                if (x + dx, y + dy) not in self.px:
                    add.add((x + dx, y + dy))
        for k in add:
            self.px[k] = ink

    def paste(self, canvas, clip=None):
        for (x, y), c in self.px.items():
            if 0 <= x < W and 0 <= y < H and (clip is None or clip(x, y)):
                canvas.c[y][x] = c


def lit_steps(layer, light, rim=None, keep_ink=True):
    """Lights a layer in palette steps: light(x, y) returns the step (an int); `rim` = (lx, ly, steps) raises the
    figure's edge that faces a light behind it (a hard rim, the hearth through the hair)."""
    src = dict(layer.px)
    ink = P("ink")
    for (x, y), c in src.items():
        k = light(x, y)
        if rim:
            lx, ly, rk = rim
            sx = 1 if lx > x else -1
            n1, n2 = src.get((x + sx, y)), src.get((x + 2 * sx, y))
            if n1 is None or n1 == ink or n2 is None:
                k += rk
        if keep_ink and c == ink:
            continue
        layer.px[(x, y)] = step(c, k)


def downscale(rows, size):
    """The portrait carried to size x size by area vote: each new pixel takes the colour that covers most of its
    footprint, the ink line winning when it covers a third (so the outline survives)."""
    h = len(rows)
    w = len(rows[0])
    ink = P("ink")
    out = []
    f = w / float(size)
    for Y in range(size):
        row = []
        for X in range(size):
            votes = {}
            x0, x1 = X * f, (X + 1) * f
            y0, y1 = Y * f, (Y + 1) * f
            for y in range(int(y0), int(math.ceil(y1))):
                wy = min(y + 1, y1) - max(y, y0)
                for x in range(int(x0), int(math.ceil(x1))):
                    wx = min(x + 1, x1) - max(x, x0)
                    c = rows[min(h - 1, y)][min(w - 1, x)]
                    key = (c[0], c[1], c[2]) if c[3] >= 128 else None
                    votes[key] = votes.get(key, 0) + wx * wy
            total = sum(votes.values())
            if votes.get(ink, 0) >= total * 0.34 and votes.get(None, 0) < total * 0.5:
                best = ink
            else:
                best = max(votes.items(), key=lambda e: e[1])[0]
            row.append((0, 0, 0, 0) if best is None else (best[0], best[1], best[2], 255))
        out.append(row)
    return out
