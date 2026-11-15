"""World rebuild, step world-2: a quick composite of the castle's exteriors at the game's real framing (437 x 201 game
px of the runner's iPhone 17 Pro, the ground row 175, each plane at its parallax: the cleft wall on the mid plane
top-anchored, the keep moving with the mist band, the world plane's buildings, the lane), flat albedo under one
light: shade 1 by day, a navy multiply with the windows lit at night. A sketch tool for the art before a runner round;
the runner's sweep (WorldSweepUITests) is the truth. Pure python, one frame in about a second:

    python3 -I castle_preview.py <Resources/Art> <out.png> <camera centre> [day|night] [tier] [--scale 3]
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from pngr import read_png  # noqa: E402
from pngw import write_png  # noqa: E402

W, H, GROUND = 437, 201, 175
HALF = W / 2.0
PAR = dict(mid=0.5, mistBand=0.62, near=0.75, world=1.0)
_cache = {}


def sprite(art, name, frame=0, frames=1):
    key = (name, frame, frames)
    if key not in _cache:
        w, h, px, _ = read_png(os.path.join(art, name + ".png"))
        fw = w // frames
        _cache[key] = (fw, h, [row[frame * fw:(frame + 1) * fw] for row in px])
    return _cache[key]


def pieces(tier, building=False):
    keep = {1: "keepT1", 2: "keepT2Build" if building else "keepT2", 3: "keepT3Build" if building else "keepT3"}[tier]
    built = tier - 1 if building else tier
    post = "posternT%d" % max(1, min(3, built))
    out = [("mid", "throatStepC", 600, 0, "top", 0), ("mid", "cleftWallA", 824, 0, "top", 0),
           ("mid", "cleftWallB", 1080, 0, "top", 0), ("mid", "cleftWallC", 1336, 0, "top", 0),
           ("mistBand", keep, 1118, 0, "ground", 0)]
    tiles = ["curtainA", "curtainC", "curtainB", "curtainA", "curtainC", "curtainA", "curtainB", "curtainC",
             "curtainA", "curtainB", "curtainA", "curtainC"]
    for i, t in enumerate(tiles):
        out.append(("world", t, 1474 + 64 * i, 0, "ground", 0))
    out += [("world", "curtainTower", 1680, 0, "ground", 0)]
    if tier == 3:
        out += [("world", "curtainTower", 1584, 0, "ground", 0)]
    out += [("world", "curtainStair", 1724, 0, "ground", 0)]
    if built >= 2:
        for x in (1538, 1602, 2060):
            out.append(("world", "curtainHoard", x, 54, "ground", 0))
    if built >= 3:
        for x in (1500, 1906, 2084):
            out.append(("world", "castleBanner", x, 28, "ground", 0))
    out += [("world", "barracks", 1481, 0, "ground", 0), ("world", "smithy", 1546, 0, "ground", 0),
            ("world", "lodge", 1620, 0, "ground", 0), ("world", "forebuilding", 1770, 0, "ground", 0),
            ("world", "chapelTower", 1950, 0, "ground", 0), ("world", "bakehouse", 2120, 0, "ground", 0),
            ("world", post, 2230, 0, "ground", 0),
            ("world", "castleFront3" if tier == 3 else "castleFront", 1226 if tier == 3 else 1240, 0, "ground", 0),
            ("world", "gateRockL", 1186, 0, "ground", 0), ("world", "gateRockR", 1436, 0, "ground", 0)]
    return out


FRAMES = {"forebuilding": 2, "chapelTower": 2}


def render(art, centre, night=False, tier=1, building=False, door_open=False):
    img = [[(0, 0, 0)] * W for _ in range(H)]
    for y in range(H):
        t = y / float(H)
        sky = (int(40 + 60 * t), int(60 + 70 * t), int(110 + 60 * t)) if not night else \
              (int(14 + 20 * t), int(18 + 24 * t), int(46 + 40 * t))
        img[y] = [sky] * W
    cam = centre - HALF
    for (plane, name, x, y, anchor, frame) in pieces(tier, building):
        frames = FRAMES.get(name, 1)
        if name == "forebuilding" and door_open:
            frame = 1
        sw, sh, px = sprite(art, name, frame, frames)
        left = int(x - int(PAR[plane] * cam))
        top = 0 if anchor == "top" else GROUND - y - sh
        haze = {"mid": 0.35, "mistBand": 0.15, "near": 0.1, "world": 0.0}[plane]
        for yy in range(sh):
            ty = top + yy
            if not 0 <= ty < H:
                continue
            row = px[yy]
            for xx in range(sw):
                tx = left + xx
                if not 0 <= tx < W:
                    continue
                p = row[xx]
                if p[3] < 128:
                    continue
                c = p[:3]
                glass = c in ((0x1C, 0x18, 0x38), (0x0E, 0x0B, 0x1E), (0x2A, 0x22, 0x30))
                if night:
                    if glass and plane != "mid" and name not in ("curtainA", "curtainB", "curtainC"):
                        c = (255, 196, 110)
                    else:
                        c = (int(c[0] * 0.30), int(c[1] * 0.36), int(c[2] * 0.62))
                air = img[ty][tx] if False else ((90, 110, 150) if not night else (30, 40, 80))
                c = tuple(int(c[i] * (1 - haze) + air[i] * haze) for i in range(3))
                img[ty][tx] = c
    lane = (60, 58, 70) if not night else (20, 22, 36)
    for y in range(GROUND, H):
        img[y] = [lane] * W
    return img


def main():
    a = sys.argv[1:]
    scale = 3
    if "--scale" in a:
        i = a.index("--scale")
        scale = int(a[i + 1])
        del a[i:i + 2]
    art, out, centre = a[0], a[1], float(a[2])
    night = len(a) > 3 and a[3] == "night"
    tier_arg = a[4] if len(a) > 4 else "1"
    building = tier_arg.endswith("b")
    tier = int(tier_arg.rstrip("b"))
    img = render(art, centre, night, tier, building, door_open=abs(centre - 1830) <= 18)
    rows = []
    for y in range(H):
        line = bytearray()
        for x in range(W):
            line += (bytes(img[y][x]) + b"\xff") * scale
        for _ in range(scale):
            rows.append(line)
    write_png(out, W * scale, H * scale, rows)
    print(out)


if __name__ == "__main__":
    main()
