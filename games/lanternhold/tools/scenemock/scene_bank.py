"""Look 2, stage 3: adds the Gloom's darkness bank (tools/bankart.py) to a scene's extras for mock.py, laid as
FrameBuilder.bankTiles lays it: the 32 px edge tile ending at <edge x>, 64 px body tiles leftward from it, their
bottom 26 px below the lane; on every body tile a frame of darknessBankGlow (cold eyes and motes) as an emissive.
    python3 -I -B scene_bank.py <in.json> <out.json> <edge x> [left x]
"""
import json
import sys

src, out, edge = sys.argv[1], sys.argv[2], int(sys.argv[3])
left = int(sys.argv[4]) if len(sys.argv) > 4 else edge - 400
ex = json.load(open(src))
ex.append(dict(s="darknessEdge", x=edge - 32, y=-26, z=20))
x, k = edge - 32 - 64, 0
while x > left - 64:
    ex.append(dict(s="darknessBank", x=x, y=-26, z=20))
    ex.append(dict(s="darknessBankGlow", glow="darknessBankGlow", x=x, y=-26, z=21, frame=k % 4, frames=4))
    x -= 64
    k += 1
json.dump(ex, open(out, "w"))
