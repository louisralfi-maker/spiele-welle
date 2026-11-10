"""Look 2, stage 1: a contact sheet of the direction mocks (run_look2.sh). Lays same-sized frames out in a grid on a dark
ground, two columns by default, at the frames' own scale. Usage:
    python3 -I -B sheet_look2.py <out.png> <frame.png> [<frame.png> …] [cols=2] [gap=8]"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from pngr import read_png  # noqa: E402
from pngw import write_png  # noqa: E402

out = sys.argv[1]
opts = dict(a.split("=") for a in sys.argv[2:] if "=" in a)
paths = [a for a in sys.argv[2:] if "=" not in a]
cols, gap = int(opts.get("cols", 2)), int(opts.get("gap", 8))
imgs = [read_png(p) for p in paths]
w, h = imgs[0][0], imgs[0][1]
rows = (len(imgs) + cols - 1) // cols
W, H = cols * w + (cols + 1) * gap, rows * h + (rows + 1) * gap
ground = bytes((14, 16, 26, 255))
canvas = [bytearray(ground * W) for _ in range(H)]
for n, (iw, ih, px, _) in enumerate(imgs):
    cx, cy = gap + (n % cols) * (w + gap), gap + (n // cols) * (h + gap)
    for y in range(min(h, ih)):
        line = canvas[cy + y]
        line[cx * 4:(cx + min(w, iw)) * 4] = b"".join(bytes((p[0], p[1], p[2], 255)) for p in px[y][:w])
write_png(out, W, H, canvas)
print("wrote", out, W, "x", H)
