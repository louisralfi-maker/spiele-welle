# A Python mock of the renderer's composite (same maths as Shaders.metal at s = 1), first for the milestone 1 shots.
# M1b: `layout=m1b` draws the world from layout_m1b.py (new sprites take their size from the PNG in Resources/Art).
# Usage (pure python, about a minute per frame on the old Mac; run with python3 -I, one at a time):
#   python3 -I mock.py <games/lanternhold> layout=m1b focus=760 tod=0.95 gain=3.0 lift=0.55 midHaze=0.36 \
#       midShare=0.7 fogBright=2.4 fogGlow=0.7 out=<file.png>
# Extras hook (M2b art lane): context scenes add entities without editing the layout.
#   extras=<file.json>[,<file.json>…]  a JSON list of props, each {s (sprite id), frame (default 0), frames (optional:
#       the strip's frame count; else SPRITES.md's, else 1), p (plane, default world), x (left edge, plane px) or cx (foot
#       centre), y (bottom above the ground line, as layout_m1b.py), z (default 5: after every world prop), sh (shade,
#       default 1), f (flip), lit (default true; false draws the body at shade 0.12, as the engine draws a creature
#       outside every light), glow (id of a glow strip, drawn additively over the same frame, lit or not), gs (glow
#       strength, default 1), em, li (as layout_m1b.py; extra light kinds fireArrow, firepot, beacon)}. A prop without
#       s only adds its lights.
#   king=off|<x>  no king, or the king's foot at x (default: at the focus, frame 0, with his lantern light)
#   actors=off    without layout_m1b.ACTORS (the scale-check archers, citizens and eye glints)
# sprite(name, frame) cuts frame n out of a horizontal strip PNG (frame width = PNG width / frame count; a PNG one
# frame wide is used for every frame, as Atlas.splitFrames does).
import sys, os, math, re, json
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE)
from core import *
from pngr import read_png
from pngw import write_png
G = sys.argv[1]  # games/lanternhold
args = dict(a.split('=') for a in sys.argv[2:])
FOCUS = float(args.get('focus', 760)); HOUR = float(args.get('tod', 0.95)) * 24; OUT = args['out']
STYLE = args.get('style', 'smooth'); LAB = args.get('lab') == '1'
LOOK = dict(lift=0.46, farShare=0.9, midLight=0.32, gain=1.55, knee=0.95, fogGlow=0.5, fgLight=0.75, fgAmb=0.62,
            bloom=0.75, bloomLight=0.16, bloomSky=0.55, thr=0.34, kneeB=0.5, farHaze=0.24, farHazeShare=0.62,
            midHazeShare=0.26, mist=0.22, colorise=0.6, glowAdd=0.06, midHaze=0.18, midShare=0.8, fogBright=1.6,
            # M1b polish (renderer additions, defaults keep the old look): aerial perspective at warm hours, clouds
            farCool=0.0, farWarm=1.0, midWarm=1.0, midCool=0.0, cloudSun=1.1, cloudFill=1.7, cloudHaze=0.25, fogScale=1.0)
for k in list(LOOK):
    if k in args: LOOK[k] = float(args[k])
src = open(os.path.join(G, 'Core/FrameDesc.swift')).read()
SIZES = {m.group(1): (int(m.group(2)), int(m.group(3))) for m in re.finditer(r'case \.(\w+): return PixelSize\(width: (\d+), height: (\d+)\)', src)}
def _contract():  # SPRITES.md tables: id -> (frame width, height, frames); glow strips as their creature
    out = {}; path = os.path.join(G, 'SPRITES.md')
    if not os.path.exists(path): return out
    text = open(path).read()
    for line in text.splitlines():
        cells = [c.strip() for c in line.strip().strip('|').split('|')]
        if len(cells) < 3 or '`' not in cells[0]: continue
        ids = re.findall(r'`(\w+)`', cells[0]); sizes = re.findall(r'(\d+)x(\d+)', cells[1]); n = re.match(r'(\d+)', cells[2])
        if not ids or not sizes or not n: continue
        for k, i in enumerate(ids):
            w, h = sizes[k] if len(sizes) == len(ids) else sizes[0]; out[i] = (int(w), int(h), int(n.group(1)))
    for m in re.finditer(r'`(\w+)Glow`', text):
        if m.group(1) in out and m.group(1) + 'Glow' not in out: out[m.group(1) + 'Glow'] = out[m.group(1)]
    return out
CONTRACT = _contract()
class _Sizes(dict):
    def __missing__(self, name):  # sprites not yet in FrameDesc: SPRITES.md's frame size, else the PNG header
        if name in CONTRACT: self[name] = CONTRACT[name][:2]; return self[name]
        import struct
        with open(os.path.join(G, 'Resources/Art', name + '.png'), 'rb') as fh: head = fh.read(24)
        v = struct.unpack('>II', head[16:24]); self[name] = v; return v
SIZES = _Sizes(SIZES)
LAYOUT = args.get('layout')
if LAYOUT == 'm1b':
    import layout_m1b as LM
sp = open(os.path.join(G, 'Render/PlaceholderSprites.swift')).read()
GR = {m.group(1): [l.strip() for l in m.group(2).split('\n') if l.strip()] for m in re.finditer(r'static let (\w+) = gridRows\("""\n(.*?)\n\s*"""\)', sp, re.S)}
def pal(name):
    m = re.search(r'static let ' + name + r': \[Character: RGBA\] = \[(.*?)\n    \]', sp, re.S)
    return {k: hexc(int(v, 16)) for k, v in re.findall(r'"(.)": RGBA\(0x([0-9A-Fa-f]{6})\)', m.group(1))}
PAL, FIRE = pal('palette'), pal('firePalette')
def blank(w, h): return [[None] * w for _ in range(h)]
def stamp(c, rows, pp, x, y):
    for j, r in enumerate(rows):
        for i, ch in enumerate(r):
            if ch in '. ': continue
            if 0 <= y + j < len(c) and 0 <= x + i < len(c[0]): c[y + j][x + i] = pp[ch]
def grid(name, pp=None):
    rows = GR[name]; c = blank(len(rows[0]), len(rows)); stamp(c, rows, pp or PAL, 0, 0); return c
def king(frame):
    legs = {0: ('kingLegsIdle', 24, 0), 1: ('kingLegsIdle', 24, 0), 2: ('kingLegsContactNear', 24, 1), 3: ('kingLegsPassingNear', 23, 0)}[frame]
    c = blank(16, 30); stamp(c, GR['kingPoleRows'], PAL, 0, 5); stamp(c, GR[legs[0]], PAL, 0, legs[1]); stamp(c, GR['kingBodyRows'], PAL, 0, legs[2]); return c
def fog_strip():
    p = P(128, 24, fnv('fogStrip'))
    for y in range(24):
        rise = min(1, max(0, y / 11)); prof = rise * rise * (3 - 2 * rise) * (1 - 0.25 * min(1, max(0, (y - 16) / 7)))
        for x in range(128):
            cl = p.fractal(x, y * 2.2, 32, 1, 128); pu = p.smooth(x, y * 3, 16, 2, 128)
            d = min(1, max(0, prof * (0.25 + 0.85 * cl) * (0.8 + 0.4 * pu)))
            lvl = math.floor(d * 8 + bayer(x, y) - 0.5) / 8; a = int(min(220, max(0, lvl * 230)))
            if a > 0: p.put(x, y, (255, 255, 255, a))
    return p.px
def star_field():
    p = P(128, 64, fnv('starField')); tones = [hexc(v) for v in (0x5A5C80, 0x8E92B8, 0xC6CAE6, 0xFFFFFF, 0xFFF0D0, 0xD0E0FF)]
    for i in range(52):
        x = int(p.hash(i, 1) * 128); y = int(p.hash(i, 2) * 64); k = p.hash(i, 3)
        t = tones[0] if k < 0.45 else tones[1] if k < 0.75 else tones[2] if k < 0.9 else tones[3 + i % 3]
        p.put(x, y, t)
    for i in range(5):
        x = int(p.hash(i, 7) * 128); y = int(p.hash(i, 8) * 58) + 3; p.put(x, y, tones[3 + i % 3])
        for dx, dy in ((-1, 0), (1, 0), (0, -1), (0, 1)): p.put((x + dx) % 128, y + dy, tones[1])
    return p.px
def moon():
    p = P(14, 14, fnv('moon')); rp = [hexc(v) for v in (0x4E587E, 0x7E8AC0, 0xAEB8E0, 0xDCE2F6, 0xFAFBFF)]
    for y in range(14):
        for x in range(14):
            dx, dy = x + 0.5 - 7, y + 0.5 - 7; d = math.hypot(dx, dy)
            if d > 6.7: continue
            v = 0.86 - (dx + dy) * 0.03 - (0.14 if d > 5.5 else 0); m = p.smooth(x, y, 4, 3)
            if m > 0.6: v -= 0.22
            if m > 0.72: v -= 0.1
            p.put(x, y, ramp(rp, v, x, y))
    return p.px
def grass():
    c = blank(14, 8); g = [hexc(v) for v in (0x24381E, 0x34502A, 0x4A6E34, 0x6E9A4A, 0x94B860)]
    for bx, hh, lean in [(1, 4, -1), (3, 6, 0), (5, 8, 1), (6, 5, -1), (8, 7, 1), (10, 6, 0), (12, 4, 1)]:
        for st in range(hh):
            x = bx + int(st * lean / 3) if st * lean >= 0 else bx - int(-st * lean / 3)
            c[7 - st][x] = g[3] if st == hh - 1 else (g[1] if st < 2 else g[2])
    return c
CACHE = {}
def cut_frame(name, img, frame, frames=None):
    """Frame `frame` of a horizontal strip: frame width = PNG width / frame count (the `frames` argument, else
    SPRITES.md's count); a PNG one frame wide (SPRITES.md's width) serves every frame, as Atlas.splitFrames does."""
    n = int(frames) if frames else CONTRACT.get(name, (0, 0, 1))[2]
    W = len(img[0])
    if n <= 1 or (not frames and W == CONTRACT[name][0]): return img
    fw = W // n; k = int(frame) % n
    return [r[k * fw:(k + 1) * fw] for r in img]
def sprite(name, frame=0, frames=None):
    key = (name, frame) if frames is None else (name, frame, frames)
    if key in CACHE: return CACHE[key]
    path = os.path.join(G, 'Resources/Art', name + '.png')
    if os.path.exists(path):
        w, h, px, _ = read_png(path); img = [[p if p[3] > 0 else None for p in r] for r in px]
        img = cut_frame(name, img, frame, frames)
    elif name == 'king': img = king(frame)
    elif name == 'archer': img = grid('archerRows')
    elif name == 'citizen': img = grid('citizenRows')
    elif name in ('flame', 'brazierFlame', 'hearthFire', 'candleFlame', 'windowGlow', 'lanternGlass'): img = grid(name + 'Rows', FIRE)
    elif name == 'candleStand': img = grid('candleStandRows')
    elif name == 'fencePost': img = grid('fencePostRows')
    elif name == 'eyeGlints': img = [[FIRE['W'], None, None, None, FIRE['W']]]
    elif name == 'fogStrip': img = fog_strip()
    elif name == 'starField': img = star_field()
    elif name == 'moon': img = moon()
    elif name == 'grassTuft': img = grass()
    else: raise KeyError(name)
    CACHE[key] = img; return img
fireWhite, fireGold, fireOrange = hexf(0xFFF2C2), hexf(0xFFC65A), hexf(0xFF8A2A); WIN = (1.0, 0.74, 0.40)
RAD = dict(torch=30, brazier=56, lantern=40, hearth=70, window=14, candle=12)
COL = dict(torch=fireGold, brazier=fireOrange, lantern=fireGold, hearth=fireOrange, window=(1.0, 0.72, 0.38), candle=fireGold)
FADES = {'torch', 'window', 'lantern', 'candle'}
def build_scene(chapelWin, kitchenWin, houseWin):
    props = []
    def add(spr, plane, x, y, z=0, shade=1.0, flip=False, em=(), li=()):
        props.append(dict(s=spr, p=plane, x=x, y=y, z=z, sh=shade, f=flip, em=list(em), li=list(li)))
    def torch(cx, by): add('torchPost', 'world', cx - 2, by, 2, em=[('flame', 0, 12, fireGold, True)], li=[('torch', cx, by + 15, 30, fireGold, 1)])
    def brazier(cx): add('brazier', 'world', cx - 5, 0, 3, em=[('brazierFlame', 1, 11, fireOrange, False)], li=[('brazier', cx, 16, 56, fireOrange, 1)])
    def building(spr, x, z=0, shade=1.0, flip=False, wins=(), wr=14):
        w = SIZES[spr][0]; em = []; li = []
        for dx, dy in wins:
            em.append(('windowGlow', dx, dy, WIN, True)); gx = w - dx - 6 if flip else dx
            li.append(('window', x + gx + 3, dy + 4, wr, WIN, 0.8))
        add(spr, 'world', x, 0, z, shade, flip, em, li)
    x = -40.0; i = 0
    while x < 1300:
        add('farMountain' if i % 2 == 0 else 'farPeak', 'far', x, 0, i % 2, 0.92, i % 3 == 1); x += 96; i += 1
    for pair in range(8):
        x = 30 + 160 * pair; add('gorgeCliff', 'mid', x, 0, 0, 0.85); add('gorgeCliff', 'mid', x + 48, 0, 1, 1.0, True)
    x = 1300; i = 0
    while x < 2400: add('valleyHill', 'mid', x, 0, i % 2, 0.97, i % 2 == 1); x += 130; i += 1
    add('palisade', 'world', 640, 0, 1); torch(636, 20); torch(664, 20); add('ballista', 'world', 676, 0, 1)
    add('stoneWall', 'world', 940, 0, 1); torch(936, 38); torch(980, 38); brazier(896); brazier(920)
    add('castleTower', 'world', 1290, 0, -1); add('castleTower', 'world', 1398, 0, -1, flip=True)
    building('gatehouse', 1300, 0, wins=[(18, 62), (96, 62)]); torch(1342, 22); torch(1378, 22)
    for k in range(7):
        if k % 2 == 1: building('castleWall', 1420 + 40 * k, -2, wins=[(17, 58)])
        else: add('castleWall', 'world', 1420 + 40 * k, 0, -2)
    add('hallInterior', 'world', 1700, 0, -2); add('throne', 'world', 1817, 0, 1)
    add('hearth', 'world', 1870, 0, 1, em=[('hearthFire', 5, 3, fireOrange, False)], li=[('hearth', 1883, 10, 70, fireOrange, 1)])
    for cx in (1758, 1798, 1928): add('candleStand', 'world', cx - 2, 0, 1, em=[('candleFlame', 1, 15, fireWhite, True)], li=[('candle', cx, 17, 12, fireGold, 1)])
    add('castleTower', 'world', 2088, 0, -1)
    building('chapel', 1960, 0, wins=chapelWin); building('kitchen', 2120, 0, wins=kitchenWin); add('backGate', 'world', 2240, 0, 0)
    for n, start in enumerate((2380, 2700, 2800, 2990)):
        building('house', start, 0, 0.97, n % 2 == 1, houseWin, 18)
        add('lanternPost', 'world', start + 68, 0, 1, em=[('lanternGlass', 1, 18, fireGold, True)], li=[('lantern', start + 71, 20, 28, fireGold, 1)])
    add('field', 'world', 2500, 0, -1); add('field', 'world', 2580, 0, -1); add('well', 'world', 2913, 0, 1)
    add('waterfall', 'world', 3650, 0, -1); add('gorgeEndCliff', 'world', 3680, 0, 0)
    x = 0.0; i = 0
    while x < 5400: add('grassTuft', 'fg', round(x), -20, 0, 0.55 + 0.2 * ((i * 37) % 10) / 10, i % 2 == 1); x += 36 + (i * 53 % 17); i += 1
    post = 120.0
    while post < 5400: add('fencePost', 'fg', round(post), -24, 1, 0.6); post += 260 + (post * 7 % 80)
    return props
PAR = dict(sky=0.05 if LAYOUT else 0, far=0.2, mid=0.5, fogA=0.9, world=1.0, fogB=1.15, fg=1.3)
GLASS = {(0x0E, 0x0B, 0x1E, 255), (0x1C, 0x18, 0x38, 255), (0x2A, 0x22, 0x30, 255)}
GLASS = {g[:3] for g in GLASS}
NAMED = dict(fireWhite=fireWhite, fireGold=fireGold, fireOrange=fireOrange, window=WIN)
def layout_props():
    out = []
    for d in LM.instances():
        em, masks, li = [], [], []
        for e in d['em']:
            if e[0] == 'sprite': em.append((e[1], e[2], e[3], NAMED[e[4]], e[5]))
            else: masks.append((e[1], e[2], e[3], e[4], (1.0, 0.76, 0.42)))
        for (kind, x, y, r) in d['li']:
            li.append((kind, x, y, r, COL[kind], 0.8 if kind == 'window' else 1))
        plane = 'fg' if d['p'] == 'fg' else d['p']
        out.append(dict(s=d['s'], p=plane, x=d['x'], y=d['y'], z=d['z'], sh=d['sh'], f=d['f'], em=em, li=li,
                        masks=masks, anchor=d['anchor'], lp=plane, fade=d.get('fade'), mv=d.get('mv'), fadeout=d.get('fadeout')))
    return out
COLX = dict(COL, fireArrow=fireWhite, firepot=fireOrange, beacon=fireWhite)  # light kinds of the extras
UNLIT = 0.12  # an unlit creature's body: very low value, its glow strip carries it (SPRITES.md)
def extra_props():
    """The extras hook: props from extras=<file.json>[,…] (see the header), drawn with the layout's props."""
    out = []
    for path in [q for q in args.get('extras', '').split(',') if q]:
        for d in json.load(open(path)):
            s = d.get('s'); fr = int(d.get('frame', 0)); nf = d.get('frames'); plane = d.get('p', 'world')
            w = len(sprite(s, fr, nf)[0]) if s else 0
            x = d['x'] if 'x' in d else d.get('cx', 0) - w // 2
            em, masks, li = [], [], []
            for e in d.get('em', []):
                if e[0] == 'sprite': em.append((e[1], e[2], e[3], NAMED[e[4]], e[5]))
                else: masks.append((e[1], e[2], e[3], e[4], (1.0, 0.76, 0.42)))
            for (kind, lx, ly, r) in d.get('li', []):
                li.append((kind, lx, ly, r, COLX[kind], 0.8 if kind == 'window' else 1))
            out.append(dict(s=s, p=plane, x=x, y=d.get('y', 0), z=d.get('z', 5), sh=d.get('sh', 1.0), f=bool(d.get('f', False)),
                            em=em, li=li, masks=masks, anchor='ground', lp=plane, extra=True, frame=fr, frames=nf,
                            lit=d.get('lit', True), glow=d.get('glow'), gs=d.get('gs', 1.0)))
    return out
ORDER = ['sky', 'far', 'mid', 'fogA', 'world', 'fogB', 'fg']
def render(chapelWin=((30, 52), (77, 52), (124, 52)), kitchenWin=((28, 40), (86, 40)), houseWin=((14, 14), (44, 14))):
    TW, TH = 438, 201; GROUND = TH - 26; VIS = 437
    amb = ambient(HOUR); torchS = amb['torch']
    WORLD_W = LM.WORLD_WIDTH if LAYOUT else 3800
    camx = min(WORLD_W - VIS, max(0, FOCUS - VIS / 2)); whole = {k: math.floor(camx * v) for k, v in PAR.items()}
    layers = {k: [[(0.0, 0.0, 0.0, 0.0)] * TW for _ in range(TH)] for k in ORDER}
    light = [[(0.0, 0.0, 0.0)] * TW for _ in range(TH)]; emis = [[(0.0, 0.0, 0.0)] * TW for _ in range(TH)]
    def draw(layer, img, left, top, tint=(1, 1, 1, 1), flip=False, add=False):
        h = len(img); w = len(img[0]); L = layers[layer] if not add else None
        occl = LAYOUT and layer in ('mid', 'world', 'fg')
        for j in range(h):
            y = top + j
            if y < 0 or y >= TH: continue
            for i in range(w):
                x = left + i
                if x < 0 or x >= TW: continue
                p = img[j][w - 1 - i if flip else i]
                if p is None: continue
                a = p[3] / 255 * tint[3]
                if a <= 0.003: continue
                c = (p[0] / 255 * tint[0] * a, p[1] / 255 * tint[1] * a, p[2] / 255 * tint[2] * a)
                if add:
                    e = add[y][x]; add[y][x] = (e[0] + c[0], e[1] + c[1], e[2] + c[2])
                else:
                    d = L[y][x]; L[y][x] = (c[0] + d[0] * (1 - a), c[1] + d[1] * (1 - a), c[2] + d[2] * (1 - a), a + d[3] * (1 - a))
                    if occl and a >= 0.5: emis[y][x] = (0.0, 0.0, 0.0)  # glow behind a sprite drawn later is hidden
    props = [] if LAB else (layout_props() if LAYOUT else build_scene(chapelWin, kitchenWin, houseWin))
    if args.get('extras'): props += extra_props()
    lights = []
    ground = sprite('ground')
    if LAB:
        for row in (1, 0):
            for x in range(0, TW, 40): draw('world', sprite('castleWall'), x, GROUND - 90 * (row + 1), (0.96, 0.96, 0.96, 1))
    def edge_stone(k):  # the same hash as FrameBuilder.groundEdgeHasStone (polish after the art review)
        h = (k * 0x9E3779B1) & 0xFFFFFFFF; h ^= h >> 16; h = (h * 0x85EBCA6B) & 0xFFFFFFFF; h ^= h >> 13
        return (h >> 7) & 1 == 0
    for x in range(0, TW + 64, 64): 
        wx = math.floor(whole['world'] / 64) * 64 + x
        if LAYOUT and wx >= LM.GROUND_TILE_END: continue
        k = wx // 64
        tile = ground if not LAYOUT else sprite({(True, True): 'ground', (True, False): 'groundB', (False, True): 'groundC',
                                                (False, False): 'groundD'}[(edge_stone(k), edge_stone(k + 1))])
        draw('world', tile, int(wx - whole['world']), GROUND)
    # sky
    if amb['stars'] > 0.01:
        for row in (0, 64):
            for x in range(0, TW, 128): draw('sky', sprite('starField'), x, row, (1, 1, 1, amb['stars']), add=None)
    skyAdd = [[(0.0, 0.0, 0.0)] * TW for _ in range(TH)]
    if amb['stars'] > 0.01 and not LAB:
        st = sprite('starField')
        for row in (0, 64):
            for x0 in range(0, TW, 128):
                for j in range(64):
                    for i in range(128):
                        p = st[j][i]
                        if p and x0 + i < TW: skyAdd[row + j][x0 + i] = tuple(p[k] / 255 * amb['stars'] for k in range(3))
        layers['sky'] = [[(0.0, 0.0, 0.0, 0.0)] * TW for _ in range(TH)]
    if amb['moon'] > -0.05 and not LAB:
        lift = round(amb['moon'] * 90); top = max(2, GROUND - 70 - lift); left = round(TW * 0.72) - 7
        a = min(1, max(0, amb['moon'] * 3 + 0.3)); mc = hexf(0x8C98D0); pk = max(mc); hue = [c / pk for c in mc]
        tint = [(1 + (hue[k] - 1) * 0.4) * pk for k in range(3)]
        m = sprite('moon')
        for j in range(14):
            for i in range(14):
                p = m[j][i]
                if p: skyAdd[top + j][left + i] = tuple(skyAdd[top + j][left + i][k] + p[k] / 255 * tint[k] * a for k in range(3))
    for pr in sorted(props, key=lambda q: (ORDER.index(q['p']), q['z'])):
        isx = pr.get('extra'); ximg = sprite(pr['s'], pr['frame'], pr['frames']) if isx and pr['s'] else None
        w, h = (len(ximg[0]), len(ximg)) if ximg else ((0, 0) if isx else SIZES[pr['s']])
        left = pr['x'] - whole[pr.get('mv') or pr['p']]  # moves: another plane's parallax
        if (ximg or not isx) and (left + w < -1 or left > TW + 1): continue
        # top-anchored lips never hang below y 139 (FrameBuilder.lipLowestBottom, polish after the art review)
        top = min(pr['y'], GROUND - 139 - h) if pr.get('anchor') == 'top' else GROUND - pr['y'] - h
        fa = 1.0
        if pr.get('fade'):  # fades in with the camera's focus (the far view of the keep)
            f0, f1 = pr['fade']; fa = min(1.0, max(0.0, (camx + VIS / 2 - f0) / (f1 - f0)))
            if fa <= 0.003: continue
        if pr.get('fadeout'):  # and out again
            f2, f3 = pr['fadeout']; fa *= 1 - min(1.0, max(0.0, (camx + VIS / 2 - f2) / (f3 - f2)))
            if fa <= 0.003: continue
        if isx:  # an extra: its frame, at shade 0.12 when unlit, then its glow strip added over the same frame
            if ximg:
                shd = pr['sh'] * (1 if pr['lit'] else UNLIT)
                draw(pr['p'], ximg, int(left), int(top), (shd, shd, shd, 1.0), pr['f'])
                if pr['glow']:
                    g = pr['gs']; draw(pr['p'], sprite(pr['glow'], pr['frame'], pr['frames']), int(left), int(top), (g, g, g, 1.0), pr['f'], add=emis)
        else:
            draw(pr['p'], sprite(pr['s']), int(left), int(top), (pr['sh'], pr['sh'], pr['sh'], fa), pr['f'])
        for (dx, dy, mw, mh, col) in pr.get('masks', []):  # window glass: the sprite's dark pixels in a rect glow
            if torchS < 0.01: continue
            img = ximg if isx else sprite(pr['s']); rgb = [c * torchS * 0.9 for c in col]
            for j in range(mh):
                sy = h - 1 - (dy + j)
                for i in range(mw):
                    sx = dx + i; p = img[sy][sx] if 0 <= sy < h and 0 <= sx < w else None
                    if p is None or p[:3] not in GLASS: continue
                    X = int(left + (w - 1 - sx if pr['f'] else sx)); Y = int(top + sy)
                    if 0 <= X < TW and 0 <= Y < TH: e = emis[Y][X]; emis[Y][X] = (e[0] + rgb[0], e[1] + rgb[1], e[2] + rgb[2])
        for (es, dx, dy, col, fades) in pr['em']:
            st = torchS if fades else 1.0
            if st < 0.01: continue
            sw, sh = SIZES[es]; ex = w - dx - sw if pr['f'] else dx
            rgb = [c * st for c in col]; pk = max(max(rgb), 1e-4); hue = [c / pk for c in rgb]
            tint = [(1 + (hue[k] - 1) * 0.4) * pk for k in range(3)] + [1]
            draw('world', sprite(es), int(left + ex), int(GROUND - (pr['y'] + dy) - sh), tint, add=emis)
        for (kind, lx, ly, r, col, inten) in pr['li']:
            it = inten * (torchS if kind in FADES else 0.35 + 0.65 * torchS)
            it *= {'window': 0.4, 'candle': 0.7, 'lantern': 0.85}.get(kind, 1.0)
            if it > 0.01: lights.append((lx - whole[pr.get('lp', 'world')], GROUND - ly, r, col, it))
    if LAB:
        for row, (hgt, col, es) in enumerate(((104, (1.0, 0.62, 0.26), 'brazierFlame'), (20, (0.46, 0.62, 1.0), 'lanternGlass'))):
            for k, share in enumerate((0.17, 0.48, 0.81)):
                cx = round(VIS * share); cy = GROUND - hgt; lights.append((cx, cy, (22, 40, 64)[k], col, 1.0))
                sw, sh = SIZES[es]; pk = max(col); hue = [c / pk for c in col]; tint = [(1 + (hue[i] - 1) * 0.4) * pk for i in range(3)] + [1]
                draw('world', sprite(es), cx - sw // 2, cy - sh // 2, tint, add=emis)
    elif args.get('king') != 'off':
        # king and his lantern (king=<x> moves him, king=off leaves him out: a scene adds him as an extra)
        kx = FOCUS if 'king' not in args else float(args['king']); lights.append((kx + 9 - whole['world'], GROUND - 16, 40, fireGold, torchS * 0.85))
    # fog
    fogA = (amb['fogColor'], amb['fogD'] * 0.9 * LOOK['fogScale']); fogB = (amb['fogColor'], amb['fogD'] * 0.6 * LOOK['fogScale'])
    for name, (fc, fd), fy in (('fogA', fogA, -4), ('fogB', fogB, -14)):
        top = GROUND - fy - 24; first = math.floor(whole[name] / 128) - 1
        for idx in range(first, first + TW // 128 + 3):
            draw(name, sprite('fogStrip'), int(idx * 128 - whole[name]), top, (fc[0], fc[1], fc[2], fd), idx % 2 != 0)
    # actors (game-pixel precision in the mock)
    actors = []
    if not LAB:
        for x, kind in ((556, 's'), (571, 's'), (588, 'h'), (606, 's'), (620, 'h'), (632, 's')):
            off = (2, 9) if kind == 's' else (6, 10)
            actors.append(('eyeGlints', x + off[0], off[1], (1.0, 0.86, 0.55, 1), True, False))
        if LAYOUT:
            actors = [] if args.get('actors') == 'off' else [(n, x, y, (1.0, 0.86, 0.55, 1) if n == 'eyeGlints' else (1, 1, 1, 1), em, fl) for (n, x, y, em, fl) in LM.ACTORS]
        else:
            for k in range(3): actors.append(('archer', 946 + 12 * k, 52, (1, 1, 1, 1), False, True))
            actors.append(('citizen', 2902, 0, (1, 1, 1, 1), False, False)); actors.append(('citizen', 2944, 0, (1, 1, 1, 1), False, True))
        if args.get('king') != 'off': actors.append(('king', kx, 0, (1, 1, 1, 1), False, False))
    # light pass
    edge = 0.12
    for (cx, cy, r, col, it) in lights:
        for y in range(max(0, int(cy - r / 1.25) - 1), min(TH, int(cy + r / 1.25) + 2)):
            for x in range(max(0, int(cx - r) - 1), min(TW, int(cx + r) + 2)):
                d = math.hypot(x + 0.5 - cx, (y + 0.5 - cy) * 1.25) / r
                if d >= 1: continue
                t = (1 - d) ** 2
                if STYLE == 'smooth': lv = t if t >= edge else t * 0.55
                else:
                    if t < edge:
                        lv = 0
                        if STYLE == 'dithered' and (t - edge / 2) / (edge / 2) > bayer(x + whole['world'], y): lv = edge * 0.6
                    else:
                        s = (t - edge) / (1 - edge); k = math.floor(s * 4 + bayer(x + whole['world'], y) - 0.5) if STYLE == 'dithered' else math.floor(s * 4)
                        k = min(3, max(0, k)); lv = 0.2 + 0.8 * k / 3
                e = light[y][x]; light[y][x] = (e[0] + col[0] * it * lv, e[1] + col[1] * it * lv, e[2] + col[2] * it * lv)
    # bloom
    HW, HH = (TW + 1) // 2, (TH + 1) // 2
    bl = [[(0.0, 0.0, 0.0)] * HW for _ in range(HH)]
    for y in range(HH):
        for x in range(HW):
            s = [0, 0, 0]
            for j in range(2):
                for i in range(2):
                    xx, yy = min(TW - 1, 2 * x + i), min(TH - 1, 2 * y + j)
                    for k in range(3): s[k] += emis[yy][xx][k] + light[yy][xx][k] * LOOK['bloomLight'] + skyAdd[yy][xx][k] * LOOK['bloomSky']
            c = [v / 4 for v in s]; pk = max(c); keep = ss((pk - LOOK['thr']) / LOOK['kneeB'])
            bl[y][x] = tuple(v * keep for v in c)
    def blur(img, dx, dy):
        W, H = len(img[0]), len(img); out = [[(0.0, 0.0, 0.0)] * W for _ in range(H)]
        taps = [(0, 0.2270270270), (1.3846153846, 0.3162162162), (-1.3846153846, 0.3162162162), (3.2307692308, 0.0702702703), (-3.2307692308, 0.0702702703)]
        for y in range(H):
            for x in range(W):
                acc = [0, 0, 0]
                for off, wgt in taps:
                    fx = min(W - 1, max(0, x + dx * off * 1.6)); fy = min(H - 1, max(0, y + dy * off * 1.6))
                    x0, y0 = int(fx), int(fy); x1, y1 = min(W - 1, x0 + 1), min(H - 1, y0 + 1); tx, ty = fx - x0, fy - y0
                    for k in range(3):
                        v = (img[y0][x0][k] * (1 - tx) + img[y0][x1][k] * tx) * (1 - ty) + (img[y1][x0][k] * (1 - tx) + img[y1][x1][k] * tx) * ty
                        acc[k] += v * wgt
                out[y][x] = tuple(acc)
        return out
    bl = blur(blur(bl, 1, 0), 0, 1)
    # composite
    lift = LOOK['lift']; ac = amb['ambColor']; pk = max(ac); lvl = lift + (1 - lift) * min(1, amb['ambI'])
    ambW = [c / pk * lvl for c in ac]; ambF = [c * LOOK['farShare'] for c in ambW]
    sat = 1 + (amb['sat'] - 1) * 0.6; night = ss((0.75 - amb['ambI']) / 0.5); vig = 0.14 + 0.26 * night
    hz = amb['haze']; farH = LOOK['farHaze'] + hz * LOOK['farHazeShare']; midH = hz * LOOK['midHazeShare']; mistv = LOOK['mist'] * (0.4 + amb['fogD'])
    img = [[None] * TW for _ in range(TH)]
    NT = (1.03, 0.86, 1.66); kcol = LOOK['colorise'] * night
    fc = amb['fogColor']; fogLum = 0.299 * fc[0] + 0.587 * fc[1] + 0.114 * fc[2]
    FB = min(LOOK['fogBright'], max(1.0, 0.45 / max(fogLum, 0.01)))
    MH = 0.12 + (LOOK['midHaze'] - 0.12) * night
    # aerial perspective at warm hours (M1b polish): the far plane hazes toward a cool lavender and keeps only a share
    # of the warm light, the mid plane a larger share; w is 0 by day and at night, 1 at golden hour (warmth 0.45)
    wv0 = min(1, max(0, amb['warmth'] / 0.45)); COOL = (0.62, 0.60, 0.86)
    def desat(v, k):
        lu = 0.299 * v[0] + 0.587 * v[1] + 0.114 * v[2]; cool = (lu * 0.94, lu * 0.96, lu * 1.12)
        return [v[i] + (cool[i] - v[i]) * k for i in range(3)]
    ambF = desat(ambF, (1 - LOOK['farWarm']) * wv0)
    ambM = desat([v * LOOK['midShare'] for v in ambW], (1 - LOOK['midWarm']) * wv0)
    farHC = [amb['skyBottom'][k] + (COOL[k] - amb['skyBottom'][k]) * LOOK['farCool'] * wv0 for k in range(3)]
    midHC = [amb['skyBottom'][k] + (COOL[k] - amb['skyBottom'][k]) * LOOK['midCool'] * wv0 for k in range(3)]
    stN = [v / max(max(amb['skyTop']), 1e-3) for v in amb['skyTop']]
    def cold(rgb, ambv):
        a = [rgb[k] * ambv[k] for k in range(3)]; lu = 0.299 * a[0] + 0.587 * a[1] + 0.114 * a[2]
        return [a[k] + (lu * NT[k] - a[k]) * kcol for k in range(3)]
    def lit_light(x, y):
        l = [v * LOOK['gain'] for v in light[y][x]]; hot = max(max(l) - LOOK['knee'], 0)
        return [l[0] + 0.55 * hot, l[1] + 0.5 * hot, l[2] + 0.38 * hot]
    def base(x, y, L):
        v = min(1, max(0, (y + 0.5) / GROUND)) ** 1.35; q = min(1, max(0, math.floor(v * 16 + bayer(x, y)) / 16))
        c = [amb['skyTop'][k] + (amb['skyBottom'][k] - amb['skyTop'][k]) * q + skyAdd[y][x][k] for k in range(3)]
        low = ss((y - (GROUND - 70)) / 70)
        s_ = layers['sky'][y][x]
        if s_[3] > 0:  # clouds: sunlit tops take the warm light, shaded bellies the sky's top colour
            a_ = s_[3]; alb = [s_[k] / a_ for k in range(3)]; lu = 0.299 * alb[0] + 0.587 * alb[1] + 0.114 * alb[2]
            Lw = min(1, max(0, (lu - 0.6) / 0.3))
            lit = [alb[k] * (ambW[k] * LOOK['cloudSun'] * Lw + amb['skyTop'][k] * LOOK['cloudFill'] * (1 - Lw)) for k in range(3)]
            lit = [lit[k] + (amb['skyBottom'][k] - lit[k]) * LOOK['cloudHaze'] for k in range(3)]
            c = [c[k] * (1 - a_) + lit[k] * a_ for k in range(3)]
        f = layers['far'][y][x]
        if f[3] > 0:
            hzz = min(1, max(0, farH + low * mistv)); lit = cold(f, ambF)
            lit = [lit[k] + (farHC[k] * f[3] - lit[k]) * hzz for k in range(3)]; c = [c[k] * (1 - f[3]) + lit[k] for k in range(3)]
        m = layers['mid'][y][x]
        if m[3] > 0:
            hzz = min(1, max(0, MH + midH + low * mistv * 0.5)); cm = cold(m, ambM); lit = [cm[k] + m[k] * L[k] * LOOK['midLight'] for k in range(3)]
            lit = [lit[k] + (midHC[k] * m[3] - lit[k]) * hzz for k in range(3)]; c = [c[k] * (1 - m[3]) + lit[k] for k in range(3)]
        a = layers['fogA'][y][x]
        if a[3] > 0: c = [c[k] * (1 - a[3]) + a[k] * FB + L[k] * 0.6 * LOOK['fogGlow'] * a[3] for k in range(3)]
        w = layers['world'][y][x]
        if w[3] > 0:
            cw = cold(w, ambW); c = [c[k] * (1 - w[3]) + cw[k] + w[k] * L[k] + L[k] * LOOK['glowAdd'] * w[3] for k in range(3)]
        return [c[k] + emis[y][x][k] for k in range(3)]
    def top(c, x, y, L):
        b = layers['fogB'][y][x]
        if b[3] > 0: c = [c[k] * (1 - b[3]) + b[k] * FB + L[k] * 0.8 * LOOK['fogGlow'] * b[3] for k in range(3)]
        f = layers['fg'][y][x]
        if f[3] > 0:
            cf = cold(f, [v * LOOK['fgAmb'] for v in ambW]); c = [c[k] * (1 - f[3]) + cf[k] + f[k] * L[k] * LOOK['fgLight'] for k in range(3)]
        fx = min(HW - 1.0, max(0.0, (x + 0.5) / 2 - 0.5)); fy = min(HH - 1.0, max(0.0, (y + 0.5) / 2 - 0.5)); x0, y0 = int(fx), int(fy); x1, y1 = min(HW - 1, x0 + 1), min(HH - 1, y0 + 1); tx, ty = fx - x0, fy - y0
        for k in range(3):
            c[k] += ((bl[y0][x0][k] * (1 - tx) + bl[y0][x1][k] * tx) * (1 - ty) + (bl[y1][x0][k] * (1 - tx) + bl[y1][x1][k] * tx) * ty) * LOOK['bloom']
        warm = min(1, max(0, max(L) * 1.5)); lu = 0.299 * c[0] + 0.587 * c[1] + 0.114 * c[2]; s2 = sat + (max(sat, 1.08) - sat) * warm
        c = [lu + (c[k] - lu) * s2 for k in range(3)]; wv = amb['warmth']
        tint = (1 + 0.10 * wv, 1 + 0.02 * wv, 1 - 0.12 * wv) if wv >= 0 else (1 - 0.15 * wv, 1 + 0.10 * wv, 1 - 0.12 * wv)
        c = [c[k] * (tint[k] + (1 - tint[k]) * warm) for k in range(3)]
        c = [min(v, 0.82) + 0.18 * (1 - math.exp(-max(v - 0.82, 0) / 0.18)) for v in c]
        u = ((x + 0.5) / TW * 2 - 1) * 0.82; vv = (y + 0.5) / TH * 2 - 1; vg = 1 - vig * ss((math.hypot(u, vv) - 0.45) / 0.85)
        return [min(1, max(0, v * vg)) for v in c]
    for y in range(TH):
        for x in range(TW):
            L = lit_light(x, y); img[y][x] = top(base(x, y, L), x, y, L)
    for (name, wx, wy, tint, emissive, flip) in actors:
        spr = sprite(name, 0); w, h = len(spr[0]), len(spr); anchor = round(wx - whole['world']); left = anchor - w // 2; topy = GROUND - wy - h
        for j in range(h):
            for i in range(w):
                p = spr[j][w - 1 - i if flip else i]; x, y = left + i, topy + j
                if p is None or not (0 <= x < TW and 0 <= y < TH): continue
                L = lit_light(x, y); b = base(x, y, L); al = [p[k] / 255 * tint[k] for k in range(3)]
                cl = cold(al, ambW); litc = al if emissive else [cl[k] + al[k] * L[k] + L[k] * LOOK['glowAdd'] for k in range(3)]
                img[y][x] = top([b[k] + (litc[k] - b[k]) * tint[3] for k in range(3)], x, y, L)
    Z = 3; rows = []
    for r in img:
        line = bytearray()
        for c in r: line += bytes(int(v * 255 + 0.5) for v in c) + b'\xff'
        big = bytearray()
        for i in range(0, len(line), 4): big += line[i:i + 4] * Z
        for _ in range(Z): rows.append(big)
    write_png(OUT, TW * Z, TH * Z, rows)
    print('wrote', OUT, 'ambW', [round(v, 3) for v in ambW], 'sat', round(sat, 2), 'hour', HOUR)
FIX = args.get('fix') == '1'
if FIX: render(((18, 28), (54, 28), (89, 28)), ((26, 32), (79, 32)), ((9, 7), (44, 7)))
else: render()
