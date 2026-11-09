"""Cuts a box (in game pixels) out of a mock render (437x201 game px drawn at x3) and scales it to device scale, so a
detail is judged as the iPhone 17 Pro shows it (6 device px per game px). Usage:
    python3 -I zoom.py <mock.png> <out.png> x0,y0,x1,y1 [--scale 6] [--src 3]
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from pngr import read_png  # noqa: E402
from pngw import write_png  # noqa: E402


def main():
    args = sys.argv[1:]
    scale, src = 6, 3
    if "--scale" in args:
        i = args.index("--scale"); scale = int(args[i + 1]); del args[i:i + 2]
    if "--src" in args:
        i = args.index("--src"); src = int(args[i + 1]); del args[i:i + 2]
    path, out, box = args
    x0, y0, x1, y1 = (int(v) for v in box.split(","))
    w, h, px, _ = read_png(path)
    rows = []
    for gy in range(y0, y1):
        line = bytearray()
        for gx in range(x0, x1):
            p = px[min(h - 1, gy * src + src // 2)][min(w - 1, gx * src + src // 2)]
            line += bytes(p[:3]) + b"\xff"
        big = bytearray()
        for i in range(0, len(line), 4):
            big += line[i:i + 4] * scale
        for _ in range(scale):
            rows.append(big)
    write_png(out, (x1 - x0) * scale, (y1 - y0) * scale, rows)
    print("wrote", out, (x1 - x0) * scale, "x", (y1 - y0) * scale)


if __name__ == "__main__":
    main()
