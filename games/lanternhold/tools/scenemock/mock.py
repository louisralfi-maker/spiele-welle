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
#       strength, default 1), em (as layout_m1b.py; a sprite emitter may add its frame and the strip's frame count:
#       ["sprite", id, dx, dy, colour, fades, frame, frames]), li (as layout_m1b.py, plus an optional intensity; extra
#       light kinds fireArrow, firepot, beacon)}. A prop without
#       s only adds its lights.
#   king=off|<x>  no king, or the king's foot at x (default: at the focus, frame 0, with his lantern light)
#   actors=off    without layout_m1b.ACTORS (the scale-check archers, citizens and eye glints)
#   litCap=1.6 litNeutral=0.35  the renderer's cap on reflected firelight and its neutral share (default off)
# sprite(name, frame) cuts frame n out of a horizontal strip PNG (frame width = PNG width / frame count; a PNG one
# frame wide is used for every frame, as Atlas.splitFrames does).
# Look 2 (ART-look2.md, opt-in; the default look=1 renders every old mock unchanged):
#   look=2        the farbig-düster look: the look-2 ambient ramp (core.KEYS2), stronger haze and value compression on the
#                 far and mid planes toward the hour's air colour, a near plane (parallax 0.75) and a mist band (fogM,
#                 0.62) between the mid plane and the world, the depth layout (layout_look2.py: the open shadow land,
#                 rows of trees, lane ground tiles, foreground plants), a bluer night tint, navy darks and a vignette.
#                 After the critic of stage 1: painted fog banks (d2FogBank, d2MistBand, d2FogLow) instead of the
#                 stretched strip, fog that takes the light's hue, fire pools falling off to ember, firelight displacing
#                 the cold, a moon key on the near and mid planes, a ledge light, a moonlit lane, rims for creatures and
#                 people, a warm fill inside cut-away rooms (layout_look2.INTERIORS), cloud tops in the low sun's colour.
#                 Every look-2 value below (LOOK2) can be set as name=value.
#   art=<dir>[,<dir>…]  where the sprite PNGs are (default <game>/Resources/Art); depth=<dir> the depth stand-ins
#                 (tools/depthart.py), searched first with look=2
#   lut=<old palette>,<new palette>  recolours every art PNG pixel of an old palette colour to the new palette's value of
#                 the same name (previews a palette change before build-art.sh rebuilds the art)
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
            farCool=0.0, farWarm=1.0, midWarm=1.0, midCool=0.0, cloudSun=1.1, cloudFill=1.7, cloudHaze=0.25, fogScale=1.0,
            # opt-in, as the renderer since the polish after the art review (Shaders.metal kLitCap, kLitNeutral): the
            # light a world pixel reflects is capped as a whole and reflects partly as from a neutral grey; 0 = off
            litCap=0.0, litNeutral=0.0,
            # the renderer's other polish values (Look.midHazeDay, Look.foregroundAmbientNight); the defaults keep the old
            # mocks: midHazeDay 0.12 and fgAmbNight = fgAmb (-1)
            midHazeDay=0.12, fgAmbNight=-1.0,
            # scene polish 2, opt-in (0 = off), as Shaders.metal: litCool (cool albedo reflects firelight more neutrally:
            # neutral share litNeutral + litCool x its green-blue-over-red share), bounce (by day the dark, shadowed albedo
            # takes the sky's cool light instead of the warm sun, between albedo lumas bounceLo and bounceHi), duskSun
            # (at dusk the night's violet pull spares the sunlit albedo), band (a bright haze band over the far and mid
            # planes' lowest bandH rows by day and dusk, bandWhite toward white; bandValley its share in the valley,
            # bandWarmCut its thinning at the warm hours), bounceDusk (the bounce fades with daylight x this, capped at
            # 1), rim (the king's cool rim on his screen-right edge pixels)
            litCool=0.0, bounce=0.0, bounceLo=0.2, bounceHi=0.5, duskSun=0.0, band=0.0, bandH=48.0, bandWhite=0.4,
            bandValley=0.5, bandWarmCut=0.5, bounceDusk=1.0, rim=0.0,
            # look 2, fix stage: the far plane's haze thins toward the top of the screen (farClear = the share it
            # loses at the top row, farClearH = the rows over which it returns): the Weltmauer's snow stands clear
            # of the mist that lies on its feet
            # farKey: the far plane's pale albedo (snow, the cleft's light; luma from farKeyLo up, full 0.2 above
            # it) takes a key before the haze: the moon at night, the sun's colour on the clouds by day and at dusk
            farClear=0.0, farClearH=64.0, farKey=0.0, farKeyLo=0.55)
L2 = args.get('look') == '2'
# Look 2 (ART-look2.md "Engine values"): the renderer values of the farbig-düster look, as revised after the critic of
# stage 1 (ART-look2.md "Critic and fixes"): brighter fog toward the target's periwinkle banks, a lower cap on the
# light a surface reflects, fire pools that fall off from their own colour to ember red, fog that takes the light's hue
# instead of adding to its blue, a near plane with less haze and a moon key on its lit tiers, a sky-facing ledge light,
# a moonlit lane, rims for every figure, a warm ambient inside cut-away rooms and a softer vignette.
LOOK2 = dict(lift=0.30, colorise=0.72, farShare=0.85, midShare=0.72, nearShare=1.05, midLight=0.3, nearLight=0.5,
             farHaze=0.40, farHazeShare=0.55, midHazeDay=0.14, midHazeNight=0.36, midHazeShare=0.25, nearHazeDay=0.06,
             nearHazeNight=0.20, nearHazeShare=0.06, midAir=0.86, nearAir=0.62, farCool=0.6, mist=0.25,
             fogMShare=1.0, fogMBright=1.8, fogScale=1.2, fogBright=2.6, fogGoal=0.65,
             fogGlow=0.35, gain=3.0, knee=0.95,
             glowAdd=0.06, fgLight=0.55, fgAmb=0.55, fgAmbNight=0.45, bloom=0.75, bloomLight=0.10, bloomSky=0.55,
             thr=0.34, kneeB=0.5, litCap=1.0, litNeutral=0.35, litCool=0.6, bounce=0.3, bounceLo=0.2, bounceHi=0.5,
             bounceDusk=2.2, duskSun=1.0, band=0.2, bandH=40.0, bandWhite=0.3, bandValley=0.5, bandWarmCut=0.5, rim=0.6,
             winR=1.25, winI=0.5, glassGain=1.3, fireI=1.15, cloudSun=1.0, cloudFill=1.5, cloudHaze=0.3, cloudMoon=0.7, blackR=0.22,
             groundSky=1.2, groundSkyDay=1.0, moonTrack=0.18, midGlass=0.45, smoke=0.55,
             # new after the critic: the fire pools' colour falloff (0 = off), the moon key on the near and mid planes'
             # lit albedo (luma above moonLo), the sky-facing ledge light (the top pixel of a silhouette), the rims of
             # the figures (creatures unlit, people), the warm ambient inside cut-away rooms, the vignette's width
             fireFall=1.0, moonKey=0.30, moonLo=0.26, ledge=1.4, ledgeSky=0.15, creatureRim=0.6, peopleRim=0.35,
             inter=0.30, vigX=0.6, fireCold=0.7, castleMist=0.35, farClear=0.5, farKey=0.5)
NT2 = (0.72, 0.95, 1.85)              # look 2's night tint: deep blue (the old (1.03, 0.86, 1.66) is violet)
BLACK2 = (0.030, 0.040, 0.095)        # the navy the darks lift toward
EMBER2, EMBERDIM2 = hexf(0xD9481F), hexf(0x8C2A12)  # look 2: a fire pool's colour falls off to ember, its rim emberDim
MOONRIM2 = (0.62, 0.70, 0.95)         # look 2: an unlit creature's moonlight rim (Shaders.metal kMoonRim 0.55, 0.60, 0.82)
INTERIOR2 = hexf(0xB07850)            # look 2: the warm ambient inside cut-away rooms at night (hearth and candle fill)
UNLIT2 = 0.2                          # look 2: an unlit creature's body value, as the engine (EntityFrames.unlitValue)
RIMMED2 = {'king', 'sootling', 'sootlingB', 'shadehound', 'sootCrow', 'ashBrute', 'gloomweaver', 'ashGiant', 'lightlessKing'}
PEOPLE2 = {'archer', 'guardsman', 'builder', 'citizen', 'citizenB', 'citizenC'}
if L2:
    LOOK.update(LOOK2)
for k in list(LOOK):
    if k in args: LOOK[k] = float(args[k])
ART_DIRS = [d for d in args.get('art', '').split(',') if d] or [os.path.join(G, 'Resources/Art')]
DEPTH_DIR = args.get('depth') if L2 else None
SEARCH = ([DEPTH_DIR] if DEPTH_DIR else []) + ART_DIRS
def art_path(name):
    for d in SEARCH:
        p = os.path.join(d, name + '.png')
        if os.path.exists(p): return p
    return os.path.join(ART_DIRS[0], name + '.png')
def _palette_file(path):  # name -> (r, g, b) of a palette.txt
    out = {}
    for line in open(path):
        parts = line.split()
        if not parts or parts[0].startswith('#') or len(parts) < 2: continue
        out[parts[0]] = tuple(int(parts[1].lstrip('#')[i:i + 2], 16) for i in (0, 2, 4))
    return out
LUT = None
if args.get('lut'):
    _old, _new = (_palette_file(p) for p in args['lut'].split(','))
    LUT = {_old[n]: _new[n] for n in _old if n in _new and _old[n] != _new[n]}
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
        with open(art_path(name), 'rb') as fh: head = fh.read(24)
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
    path = art_path(name)
    if os.path.exists(path):
        w, h, px, _ = read_png(path); img = [[p if p[3] > 0 else None for p in r] for r in px]
        if LUT and not (DEPTH_DIR and path.startswith(DEPTH_DIR)):  # preview a palette change (lut=)
            img = [[(LUT[p[:3]] + (p[3],) if p and p[:3] in LUT else p) for p in r] for r in img]
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
if L2:  # look 2: the mist band between the mid and near planes, the near plane between the mid plane and the world
    import layout_look2 as LL
    PAR.update(fogM=0.62, near=0.75)
GLASS = {(0x0E, 0x0B, 0x1E, 255), (0x1C, 0x18, 0x38, 255), (0x2A, 0x22, 0x30, 255)}
GLASS = {g[:3] for g in GLASS}
NAMED = dict(fireWhite=fireWhite, fireGold=fireGold, fireOrange=fireOrange, window=WIN)
NAMED['cleft'] = (0.11, 0.13, 0.19)  # look 2, fix stage: the pale light in the Weltmauer's slot behind the far castle, at night
def layout_props():
    out = []
    inst = LM.instances()
    if L2:  # look 2: the open shadow land (no far gorge wall, no rock lips) plus the depth layout
        inst = [d for d in inst if not LL.dropped(d)] + LL.instances()
    for d in inst:
        em, masks, li = [], [], []
        for e in d['em']:
            if e[0] == 'sprite': em.append((e[1], e[2], e[3], NAMED[e[4]], e[5]))
            else: masks.append((e[1], e[2], e[3], e[4], (1.0, 0.76, 0.42)))
        for (kind, x, y, r) in d['li']:
            li.append((kind, x, y, r, COL[kind], 0.8 if kind == 'window' else 1))
        plane = 'fg' if d['p'] == 'fg' else d['p']
        out.append(dict(s=d['s'], p=plane, x=d['x'], y=d['y'], z=d['z'], sh=d['sh'], f=d['f'], em=em, li=li,
                        masks=masks, anchor=d['anchor'], lp=plane, fade=d.get('fade'), mv=d.get('mv'), fadeout=d.get('fadeout'),
                        shadow=d.get('shadow'), mist=d.get('mist')))
    return out
# Scene polish 2 (FrameBuilder.sunShadowAlpha, FrameBuilder.mistAlpha): a baked cast shadow is drawn black at the sun's
# strength (the day shadow) or at the sun's strength times the evening weight (the long dusk shadow beyond it); a mist
# bank at the hour's mist strength (the torch strength times the fog density, 0 by day).
SHADOW_MAX = 0.55; MIST_MAX = 0.9
def shadow_alpha(kind, amb, hour):
    sun = min(1.0, max(0.0, (amb['sun'] + 0.12) / 0.3)); evening = ss((hour - 16.0) / 2.4)
    return SHADOW_MAX * sun * (evening if kind == 'dusk' else 1.0)
def mist_alpha(k, amb):
    return MIST_MAX * k * min(1.0, max(0.0, amb['torch'])) * min(1.25, amb['fogD'] / 0.4)
COLX = dict(COL, fireArrow=fireWhite, firepot=fireOrange, beacon=fireWhite)  # light kinds of the extras
if L2:  # look 2: the fires' light a step deeper toward orange (pools read as fire on stone, not white-gold)
    TORCH2, ARROW2 = (1.0, 0.58, 0.26), (1.0, 0.70, 0.36)
    COL.update(torch=TORCH2, lantern=(1.0, 0.64, 0.30), candle=(1.0, 0.68, 0.34), window=(1.0, 0.66, 0.32))
    COLX.update(COL, fireArrow=ARROW2)
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
            for e in d.get('em', []):  # an emitter sprite may name its frame and the strip's frame count (e[6], e[7])
                if e[0] == 'sprite': em.append((e[1], e[2], e[3], NAMED[e[4]], e[5]) + tuple(e[6:8]))
                else: masks.append((e[1], e[2], e[3], e[4], (1.0, 0.76, 0.42)))
            for l in d.get('li', []):  # (kind, x, y, radius[, intensity])
                kind, lx, ly, r = l[:4]
                li.append((kind, lx, ly, r, COLX[kind], l[4] if len(l) > 4 else (0.8 if kind == 'window' else 1)))
            out.append(dict(s=s, p=plane, x=x, y=d.get('y', 0), z=d.get('z', 5), sh=d.get('sh', 1.0), f=bool(d.get('f', False)),
                            em=em, li=li, masks=masks, anchor='ground', lp=plane, extra=True, frame=fr, frames=nf,
                            lit=d.get('lit', True), glow=d.get('glow'), gs=d.get('gs', 1.0)))
    return out
ORDER = ['sky', 'far', 'mid', 'fogA', 'world', 'fogB', 'fg']
if L2:
    ORDER = ['sky', 'far', 'mid', 'fogM', 'near', 'fogA', 'world', 'fogB', 'fg']
def render(chapelWin=((30, 52), (77, 52), (124, 52)), kitchenWin=((28, 40), (86, 40)), houseWin=((14, 14), (44, 14))):
    TW, TH = 438, 201; GROUND = TH - 26; VIS = 437
    amb = ambient2(HOUR) if L2 else ambient(HOUR); torchS = amb['torch']
    WORLD_W = LM.WORLD_WIDTH if LAYOUT else 3800
    camx = min(WORLD_W - VIS, max(0, FOCUS - VIS / 2)); whole = {k: math.floor(camx * v) for k, v in PAR.items()}
    layers = {k: [[(0.0, 0.0, 0.0, 0.0)] * TW for _ in range(TH)] for k in ORDER}
    light = [[(0.0, 0.0, 0.0)] * TW for _ in range(TH)]; emis = [[(0.0, 0.0, 0.0)] * TW for _ in range(TH)]
    if L2:  # look 2's masks: a figure's rim (strength, tone 1 moon or 2 sky), cut-away rooms, figure pixels
        rimA = [[0.0] * TW for _ in range(TH)]; rimT = [[0] * TW for _ in range(TH)]
        inter = [[0.0] * TW for _ in range(TH)]; actorpx = [[False] * TW for _ in range(TH)]
        night0_ = ss((0.75 - amb['ambI']) / 0.5)
        def mark_figure(name, img, left, top, flip, lit):  # its screen-right edge pixels take a rim (Renderer.rimmed)
            if name in RIMMED2 and name != 'king' and not lit: rs, rt = LOOK['creatureRim'] * night0_, 1
            elif name in RIMMED2: rs, rt = LOOK['rim'], 2
            elif name in PEOPLE2: rs, rt = LOOK['peopleRim'], 2
            else: rs, rt = 0.0, 0
            h_, w_ = len(img), len(img[0])
            for j in range(h_):
                y = top + j
                if not 0 <= y < TH: continue
                for i in range(w_):
                    x = left + i; p = img[j][w_ - 1 - i if flip else i]
                    if p is None or p[3] < 128 or not 0 <= x < TW: continue
                    actorpx[y][x] = True
                    q = img[j][w_ - 2 - i] if flip and i + 1 < w_ else (img[j][i + 1] if not flip and i + 1 < w_ else None)
                    if rs > 0 and (q is None or q[3] < 128): rimA[y][x] = rs; rimT[y][x] = rt
        def mark_interior(name, left, top, w_, h_, flip):  # a cut-away room: its rect takes the warm interior ambient
            box = LL.INTERIORS.get(name)
            if not box: return
            x0, x1, y0, y1 = box  # sprite x from the left, y from the bottom row up
            for j in range(h_ - y1, h_ - y0):
                y = top + j
                if not 0 <= y < TH: continue
                for i in range(x0, x1):
                    x = left + (w_ - 1 - i if flip else i)
                    if 0 <= x < TW: inter[y][x] = 1.0
    def draw(layer, img, left, top, tint=(1, 1, 1, 1), flip=False, add=False, occlude=True):
        h = len(img); w = len(img[0]); L = layers[layer] if not add else None
        occl = LAYOUT and occlude and layer in ('mid', 'near', 'world', 'fg')
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
        if L2:  # look 2: the lane under the feet, its family by region, a variant by the tile index
            hv = (k * 0x9E3779B1) & 0xFFFFFFFF; hv ^= hv >> 15
            tile = sprite(LL.lane_at(wx + 32) + 'ABCD'[(hv >> 3) & 3])
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
                shd = pr['sh'] * (1 if pr['lit'] else ((1 - (1 - UNLIT2) * night0_) if L2 else UNLIT))
                draw(pr['p'], ximg, int(left), int(top), (shd, shd, shd, 1.0), pr['f'])
                if L2:
                    mark_interior(pr['s'], int(left), int(top), w, h, pr['f'])
                    if pr['s'] in RIMMED2 or pr['s'] in PEOPLE2: mark_figure(pr['s'], ximg, int(left), int(top), pr['f'], pr['lit'])
                if pr['glow']:
                    g = pr['gs']; draw(pr['p'], sprite(pr['glow'], pr['frame'], pr['frames']), int(left), int(top), (g, g, g, 1.0), pr['f'], add=emis)
        elif pr.get('shadow'):  # a baked cast shadow: black at the sun's strength, hides no glow (scene polish 2)
            sa = shadow_alpha(pr['shadow'], amb, HOUR) * fa
            if sa > 0.003: draw(pr['p'], sprite(pr['s']), int(left), int(top), (0.0, 0.0, 0.0, sa), pr['f'], occlude=False)
        elif pr.get('mist'):  # a bank of ground mist: white at the hour's mist strength, hides no glow
            ma = mist_alpha(pr['mist'], amb) * fa * (LOOK['castleMist'] if L2 else 1.0)  # look 2: the banks do most
            if ma > 0.003: draw(pr['p'], sprite(pr['s']), int(left), int(top), (1.0, 1.0, 1.0, ma), pr['f'], occlude=False)
        else:
            draw(pr['p'], sprite(pr['s']), int(left), int(top), (pr['sh'], pr['sh'], pr['sh'], fa), pr['f'])
            if L2 and pr['p'] == 'world': mark_interior(pr['s'], int(left), int(top), w, h, pr['f'])
        for (dx, dy, mw, mh, col) in pr.get('masks', []):  # window glass: the sprite's dark pixels in a rect glow
            if torchS < 0.01: continue
            gk = (LOOK['glassGain'] * (LOOK['midGlass'] if pr['p'] == 'mid' else 1.0)) if L2 else 1.0  # look 2: far glass in haze
            img = ximg if isx else sprite(pr['s']); rgb = [c * torchS * 0.9 * gk for c in col]
            for j in range(mh):
                sy = h - 1 - (dy + j)
                for i in range(mw):
                    sx = dx + i; p = img[sy][sx] if 0 <= sy < h and 0 <= sx < w else None
                    if p is None or p[:3] not in GLASS: continue
                    X = int(left + (w - 1 - sx if pr['f'] else sx)); Y = int(top + sy)
                    if 0 <= X < TW and 0 <= Y < TH: e = emis[Y][X]; emis[Y][X] = (e[0] + rgb[0], e[1] + rgb[1], e[2] + rgb[2])
        for em_ in pr['em']:
            es, dx, dy, col, fades = em_[:5]
            st = (torchS if fades else 1.0) * (fa if L2 else 1.0)  # look 2: a fading sprite's glow fades with it
            if st < 0.01: continue
            # an extra's emitter with a frame count is cut from its strip at the strip's own frame size
            eimg = sprite(es, em_[5], em_[6]) if len(em_) > 6 else sprite(es)
            sw, sh = (len(eimg[0]), len(eimg)) if len(em_) > 6 else SIZES[es]; ex = w - dx - sw if pr['f'] else dx
            rgb = [c * st for c in col]; pk = max(max(rgb), 1e-4); hue = [c / pk for c in rgb]
            tint = [(1 + (hue[k] - 1) * 0.4) * pk for k in range(3)] + [1]
            draw('world', eimg, int(left + ex), int(GROUND - (pr['y'] + dy) - sh), tint, add=emis)
        for (kind, lx, ly, r, col, inten) in pr['li']:
            it = inten * (torchS if kind in FADES else 0.35 + 0.65 * torchS)
            it *= {'window': 0.4, 'candle': 0.7, 'lantern': 0.85}.get(kind, 1.0)
            if L2 and kind == 'window':  # look 2: warm pools under the windows (gemütlich)
                it *= LOOK['winI'] / 0.4; r *= LOOK['winR']
            elif L2:  # look 2: the fires a step stronger against the darker ambient
                it *= LOOK['fireI']
            if it > 0.01:
                li_ = (lx - whole[pr.get('lp', 'world')], GROUND - ly, r, col, it)
                lights.append(li_ + (kind != 'window',) if L2 else li_)  # look 2: fire pools fall off to ember
    if LAB:
        for row, (hgt, col, es) in enumerate(((104, (1.0, 0.62, 0.26), 'brazierFlame'), (20, (0.46, 0.62, 1.0), 'lanternGlass'))):
            for k, share in enumerate((0.17, 0.48, 0.81)):
                cx = round(VIS * share); cy = GROUND - hgt; lights.append((cx, cy, (22, 40, 64)[k], col, 1.0))
                sw, sh = SIZES[es]; pk = max(col); hue = [c / pk for c in col]; tint = [(1 + (hue[i] - 1) * 0.4) * pk for i in range(3)] + [1]
                draw('world', sprite(es), cx - sw // 2, cy - sh // 2, tint, add=emis)
    elif args.get('king') != 'off':
        # king and his lantern (king=<x> moves him, king=off leaves him out: a scene adds him as an extra)
        kx = FOCUS if 'king' not in args else float(args['king']); lights.append((kx + 9 - whole['world'], GROUND - 16, 40, COL['lantern'] if L2 else fireGold, torchS * 0.85) + ((True,) if L2 else ()))
    # fog
    fogA = (amb['fogColor'], amb['fogD'] * 0.9 * LOOK['fogScale']); fogB = (amb['fogColor'], amb['fogD'] * 0.6 * LOOK['fogScale'])
    if L2:  # look 2 (after the critic): painted banks at their own heights instead of the stretched strip: the bank
        # behind the play plane (d2FogBank), the mist band between the mid and near planes (d2MistBand) and the low
        # mist over the lane (d2FogLow), seamless, density by region per column, never flipped
        fc = amb['fogColor']
        for name, spr, bottom, dens in (('fogA', 'd2FogBank', GROUND + 4, fogA[1]), ('fogB', 'd2FogLow', GROUND + 14, fogB[1]),
                                        ('fogM', 'd2MistBand', GROUND + 2, amb['fogD'] * LOOK['fogMShare'])):
            img = sprite(spr); W_, H_ = len(img[0]), len(img); first = math.floor(whole[name] / W_) - 1; Ly_ = layers[name]
            reg = [LL.fog_region(camx + x) for x in range(TW)]
            for idx in range(first, first + TW // W_ + 3):
                left = int(idx * W_ - whole[name]); top = bottom - H_
                for j in range(H_):
                    y = top + j
                    if not 0 <= y < TH: continue
                    row = img[j]
                    for i in range(W_):
                        x = left + i; p = row[i]
                        if p is None or not 0 <= x < TW: continue
                        a = min(1.0, p[3] / 255 * dens * reg[x])
                        if a > 0.003: Ly_[y][x] = (fc[0] * a, fc[1] * a, fc[2] * a, a)
    for name, (fc, fd), fy in ((('fogA', fogA, -4), ('fogB', fogB, -14)) if not L2 else ()):
        top = GROUND - fy - 24; first = math.floor(whole[name] / 128) - 1; strip = sprite('fogStrip')
        for idx in range(first, first + TW // 128 + 3):
            left = int(idx * 128 - whole[name])
            draw(name, strip, left, top, (fc[0], fc[1], fc[2], fd), idx % 2 != 0)
    if L2:
        for (hx, fl) in LL.SMOKE:  # chimney smoke over the cottages the scene keeps, lit like the world it rises in
            if not any(p['s'] in ('house', 'houseB', 'houseC') and abs(p['x'] - hx) < 0.5 for p in props): continue
            cx_ = hx + (14 if fl else 49); sm = sprite('d2Smoke'); sl = int(cx_ - len(sm[0]) // 2 - whole['world'])
            if -20 < sl < TW: draw('world', sm, sl, GROUND - 46 - len(sm) + 1, (0.74, 0.74, 0.76, LOOK['smoke']), occlude=False)
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
    for li_ in lights:
        cx, cy, r, col0, it = li_[:5]; fall = L2 and len(li_) > 5 and li_[5] and LOOK['fireFall'] > 0
        col = col0
        for y in range(max(0, int(cy - r / 1.25) - 1), min(TH, int(cy + r / 1.25) + 2)):
            for x in range(max(0, int(cx - r) - 1), min(TW, int(cx + r) + 2)):
                d = math.hypot(x + 0.5 - cx, (y + 0.5 - cy) * 1.25) / r
                if d >= 1: continue
                if fall:  # look 2: the light's own colour only at the core, ember red by d 0.75, emberDim at the rim
                    k1 = ss((d - 0.3) / 0.45) * LOOK['fireFall']; k2 = ss((d - 0.75) / 0.25) * LOOK['fireFall']
                    col = [col0[k] + (EMBER2[k] - col0[k]) * k1 for k in range(3)]
                    col = [col[k] + (EMBERDIM2[k] - col[k]) * k2 for k in range(3)]
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
    MH = LOOK['midHazeDay'] + (LOOK['midHaze'] - LOOK['midHazeDay']) * night
    fgA = LOOK['fgAmb'] if LOOK['fgAmbNight'] < 0 else LOOK['fgAmb'] + (LOOK['fgAmbNight'] - LOOK['fgAmb']) * night
    # scene polish 2: the sky's cool light at the ambient's level (bounce), how much of it by day and dusk, the band
    day = 1 - night; bounceK = LOOK['bounce'] * min(1.0, day * LOOK['bounceDusk'])
    BLUE = (0.6, 0.68, 1.0)  # half the sky's own colour, half a plain cool blue (the noon sky alone turned rock teal)
    bounceW = [(stN_ + (BLUE[k] - stN_) * 0.5) * lvl for k, stN_ in enumerate(v / max(max(amb['skyTop']), 1e-3) for v in amb['skyTop'])]
    # the band's share in the valley (Look.bandStrength: full to focus 2150, bandValley of it from the back gate on)
    bandK = LOOK['band'] * day * (1 - (1 - LOOK['bandValley']) * ss((camx + VIS / 2 - 2150) / 180)) * (1 - LOOK['bandWarmCut'] * min(1, max(0, amb['warmth'] / 0.45))); bandC = [amb['skyBottom'][k] + (1 - amb['skyBottom'][k]) * LOOK['bandWhite'] for k in range(3)]
    def shade_share(rgb, a):  # 1 for dark (shadowed) albedo, 0 for light (sunlit) albedo
        if a <= 0: return 0.0
        lu = (0.299 * rgb[0] + 0.587 * rgb[1] + 0.114 * rgb[2]) / a
        return 1 - ss((lu - LOOK['bounceLo']) / max(1e-3, LOOK['bounceHi'] - LOOK['bounceLo']))
    def lit_amb(rgb, a, ambv, share=1.0):  # the ambient a pixel takes: the sky's cool light on its shadowed share
        if bounceK <= 0: return ambv, 1.0
        sh = shade_share(rgb, a); t = sh * bounceK
        return [ambv[k] + (bounceW[k] * share - ambv[k]) * t for k in range(3)], 1 - sh
    def band_at(y):  # the bright haze band low in the gorge (rows above the ground line)
        if bandK <= 0: return 0.0
        return bandK * (1 - ss((GROUND - 1 - y) / LOOK['bandH']))
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
    def cold(rgb, ambv, sun=0.0):
        a = [rgb[k] * ambv[k] for k in range(3)]; lu = 0.299 * a[0] + 0.587 * a[1] + 0.114 * a[2]
        kk = kcol * (1 - sun * day * LOOK['duskSun'])  # at dusk the violet pull spares the sunlit albedo
        return [a[k] + (lu * NT[k] - a[k]) * kk for k in range(3)]
    def lit_world(w, L):  # the renderer's cap and neutral share, when the look asks for them (else L and w unchanged)
        if LOOK['litCap'] > 0:
            pk = max(L); L = [v * (min(pk, LOOK['litCap']) / max(pk, 1e-4)) for v in L]
        if LOOK['litNeutral'] > 0:
            lu = 0.299 * w[0] + 0.587 * w[1] + 0.114 * w[2]; k = LOOK['litNeutral']
            if LOOK['litCool'] > 0:  # cool albedo (teal cloth) reflects firelight more neutrally: no cyan or mint pools
                hi = max(w[1], w[2]); k += LOOK['litCool'] * min(1.0, max(0.0, (hi - w[0]) / max(hi, 1e-4)))
            w = [w[k_] + (lu - w[k_]) * k for k_ in range(3)]
        return L, w
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
        bnd = band_at(y)
        f = layers['far'][y][x]
        if f[3] > 0:
            hzz = min(1, max(0, farH + low * mistv)); lit = cold(f, ambF)
            lit = [lit[k] + (farHC[k] * f[3] - lit[k]) * hzz for k in range(3)]
            if bnd > 0: lit = [lit[k] + (bandC[k] * f[3] - lit[k]) * bnd for k in range(3)]
            c = [c[k] * (1 - f[3]) + lit[k] for k in range(3)]
        m = layers['mid'][y][x]
        if m[3] > 0:
            hzz = min(1, max(0, MH + midH + low * mistv * 0.5)); am, sun = lit_amb(m, m[3], ambM, LOOK['midShare'])
            cm = cold(m, am, sun); lit = [cm[k] + m[k] * L[k] * LOOK['midLight'] for k in range(3)]
            lit = [lit[k] + (midHC[k] * m[3] - lit[k]) * hzz for k in range(3)]
            if bnd > 0: lit = [lit[k] + (bandC[k] * m[3] - lit[k]) * bnd for k in range(3)]
            c = [c[k] * (1 - m[3]) + lit[k] for k in range(3)]
        a = layers['fogA'][y][x]
        if a[3] > 0: c = [c[k] * (1 - a[3]) + a[k] * FB + L[k] * 0.6 * LOOK['fogGlow'] * a[3] for k in range(3)]
        w = layers['world'][y][x]
        if w[3] > 0:
            Lc, rf = lit_world(w, L); aw, sun = lit_amb(w, w[3], ambW)
            cw = cold(w, aw, sun); c = [c[k] * (1 - w[3]) + cw[k] + rf[k] * Lc[k] + Lc[k] * LOOK['glowAdd'] * w[3] for k in range(3)]
        return [c[k] + emis[y][x][k] for k in range(3)]
    def top(c, x, y, L):
        b = layers['fogB'][y][x]
        if b[3] > 0: c = [c[k] * (1 - b[3]) + b[k] * FB + L[k] * 0.8 * LOOK['fogGlow'] * b[3] for k in range(3)]
        f = layers['fg'][y][x]
        if f[3] > 0:
            cf = cold(f, [v * fgA for v in ambW]); c = [c[k] * (1 - f[3]) + cf[k] + f[k] * L[k] * LOOK['fgLight'] for k in range(3)]
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
    if L2:
        # ---- look 2 (ART-look2.md "Engine values"): the farbig-düster composite. Same passes as above plus the mist
        # band and the near plane; a lower lift, a blue night tint, haze toward the hour's air colour with each plane
        # one step darker than the one behind it, a sky-facing lane, navy darks and a stronger vignette.
        lift = LOOK['lift']; ac = amb['ambColor']; pk = max(ac); lvl = lift + (1 - lift) * min(1, amb['ambI'])
        ambW = [c / pk * lvl for c in ac]
        night = ss((0.75 - amb['ambI']) / 0.5); day = 1 - night
        sat = amb['sat']; vig = amb['vig']; NT = NT2; kcol = LOOK['colorise'] * night
        wv0 = min(1, max(0, amb['warmth'] / 0.45))
        ambF = desat([v * LOOK['farShare'] for v in ambW], 0.7 * wv0)
        ambM = desat([v * LOOK['midShare'] for v in ambW], 0.3 * wv0)
        ambN = [v * LOOK['nearShare'] for v in ambW]
        air = amb['air']
        farHC = [air[k] + (COOL[k] - air[k]) * LOOK['farCool'] * wv0 for k in range(3)]
        midHC = [v * LOOK['midAir'] for v in air]; nearHC = [v * LOOK['nearAir'] for v in air]
        hz = amb['haze']; farH = LOOK['farHaze'] + hz * LOOK['farHazeShare']
        MH = LOOK['midHazeDay'] + (LOOK['midHazeNight'] - LOOK['midHazeDay']) * night + hz * LOOK['midHazeShare']
        NH = LOOK['nearHazeDay'] + (LOOK['nearHazeNight'] - LOOK['nearHazeDay']) * night + hz * LOOK['nearHazeShare']
        mistv = LOOK['mist'] * (0.4 + amb['fogD'])
        fc = amb['fogColor']; fogLum = 0.299 * fc[0] + 0.587 * fc[1] + 0.114 * fc[2]
        FB = min(LOOK['fogBright'], max(1.0, 0.45 / max(fogLum, 0.01)))
        fgA = LOOK['fgAmb'] + (LOOK['fgAmbNight'] - LOOK['fgAmb']) * night
        bounceK = LOOK['bounce'] * min(1.0, day * LOOK['bounceDusk'])
        bounceW = [(stN_ + (BLUE[k] - stN_) * 0.5) * lvl for k, stN_ in enumerate(v / max(max(amb['skyTop']), 1e-3) for v in amb['skyTop'])]
        bandK = LOOK['band'] * day * (1 - (1 - LOOK['bandValley']) * ss((camx + VIS / 2 - 2150) / 180)) * (1 - LOOK['bandWarmCut'] * wv0)
        bandC = [amb['skyBottom'][k] + (1 - amb['skyBottom'][k]) * LOOK['bandWhite'] for k in range(3)]
        moonUp = min(1.0, max(0.0, amb['moon'] / 0.6)); MOONC = (0.55, 0.60, 0.92)
        gsky = LOOK['groundSkyDay'] + (LOOK['groundSky'] - LOOK['groundSkyDay']) * night
        RIM = [c * max(lvl, 0.6) for c in (0.72, 0.82, 1.0)]
        FB = min(LOOK['fogBright'], max(1.0, LOOK['fogGoal'] / max(fogLum, 0.01)))  # the banks the brightest non-fire
        torchI = min(1.0, max(0.0, torchS))
        lvlI = LOOK['lift'] + (1 - LOOK['lift']) * LOOK['inter']  # a room's fill, read like a key: colour x strength
        INTER = [ambW[k] * 0.8 + (INTERIOR2[k] / max(INTERIOR2) * lvlI - ambW[k] * 0.8) * torchI for k in range(3)]
        cloudC = amb['cloud']
        def cold2(rgb, ambv, sun=0.0, kmul=1.0):  # cold() with a share of the night pull (rooms keep their warmth)
            a = [rgb[k] * ambv[k] for k in range(3)]; lu = 0.299 * a[0] + 0.587 * a[1] + 0.114 * a[2]
            kk = kcol * (1 - sun * day * LOOK['duskSun']) * kmul
            return [a[k] + (lu * NT[k] - a[k]) * kk for k in range(3)]
        def fog_lit(c, g, gain, glowK, L):  # fog over c: inside light it takes the light's hue instead of adding to its
            a = g[3]                         # blue (fire in the periwinkle banks read pink-lilac), then a warm glow
            f = [g[k] * gain for k in range(3)]; pk = max(L)
            if pk > 1e-4:
                wl = min(1.0, 1.2 * pk); lf = 0.299 * f[0] + 0.587 * f[1] + 0.114 * f[2]
                f = [f[k] + (lf * L[k] / pk - f[k]) * wl for k in range(3)]
            return [c[k] * (1 - a) + f[k] + L[k] * glowK * LOOK['fogGlow'] * a for k in range(3)]
        def moon_key(p):  # the moon on the lit albedo of the near and mid planes at night (fir tiers, crowns, statues)
            if moonUp <= 0 or LOOK['moonKey'] <= 0: return 0.0
            lu = (0.299 * p[0] + 0.587 * p[1] + 0.114 * p[2]) / max(p[3], 1e-4)
            return LOOK['moonKey'] * moonUp * night * ss((lu - LOOK['moonLo']) / 0.12)
        def ledge(layer, x, y):  # 1 for a silhouette's top pixel (nothing above it on its plane), 0.5 for the next
            if y < 1 or layer[y][x][3] < 0.5: return 0.0
            if layer[y - 1][x][3] < 0.5: return 1.0
            if y >= 2 and layer[y - 2][x][3] < 0.5: return 0.5
            return 0.0
        def base(x, y, L):
            v = min(1, max(0, (y + 0.5) / GROUND)) ** 1.35; q = min(1, max(0, math.floor(v * 16 + bayer(x, y)) / 16))
            c = [amb['skyTop'][k] + (amb['skyBottom'][k] - amb['skyTop'][k]) * q + skyAdd[y][x][k] for k in range(3)]
            low = ss((y - (GROUND - 70)) / 70)
            s_ = layers['sky'][y][x]
            if s_[3] > 0:  # clouds: sunlit tops in the low sun's own colour, bellies the sky's top colour, the moon's light
                a_ = s_[3]; alb = [s_[k] / a_ for k in range(3)]; lu = 0.299 * alb[0] + 0.587 * alb[1] + 0.114 * alb[2]
                Lw = min(1, max(0, (lu - 0.6) / 0.3))
                lit = [alb[k] * (cloudC[k] * LOOK['cloudSun'] * Lw + amb['skyTop'][k] * LOOK['cloudFill'] * (1 - Lw)
                                 + MOONC[k] * LOOK['cloudMoon'] * moonUp) for k in range(3)]
                lit = [lit[k] + (amb['skyBottom'][k] - lit[k]) * LOOK['cloudHaze'] for k in range(3)]
                c = [c[k] * (1 - a_) + lit[k] * a_ for k in range(3)]
            bnd = band_at(y)
            f = layers['far'][y][x]
            if f[3] > 0:
                hzz = min(1, max(0, farH * (1 - LOOK['farClear'] * (1 - ss(y / LOOK['farClearH']))) + low * mistv)); lit = cold(f, ambF)
                if LOOK['farKey'] > 0:
                    fk = LOOK['farKey'] * ss(((0.299 * f[0] + 0.587 * f[1] + 0.114 * f[2]) / f[3] - LOOK['farKeyLo']) / 0.2)
                    if fk > 0: lit = [lit[k] + f[k] * fk * (MOONC[k] * moonUp * night + cloudC[k]) for k in range(3)]
                lit = [lit[k] + (farHC[k] * f[3] - lit[k]) * hzz for k in range(3)]
                if bnd > 0: lit = [lit[k] + (bandC[k] * f[3] - lit[k]) * bnd for k in range(3)]
                c = [c[k] * (1 - f[3]) + lit[k] for k in range(3)]
            m = layers['mid'][y][x]
            if m[3] > 0:
                hzz = min(1, max(0, MH + low * mistv * 0.5)); am, sun = lit_amb(m, m[3], ambM, LOOK['midShare'])
                e = ledge(layers['mid'], x, y)
                if e > 0: am = [am[k] * (1 + (LOOK['ledge'] - 1) * e) + amb['skyBottom'][k] * LOOK['ledgeSky'] * e for k in range(3)]
                cm = cold(m, am, sun); mk = moon_key(m)
                lit = [cm[k] + m[k] * L[k] * LOOK['midLight'] + m[k] * MOONC[k] * mk for k in range(3)]
                lit = [lit[k] + (midHC[k] * m[3] - lit[k]) * hzz for k in range(3)]
                if bnd > 0: lit = [lit[k] + (bandC[k] * m[3] - lit[k]) * bnd * 0.6 for k in range(3)]
                c = [c[k] * (1 - m[3]) + lit[k] for k in range(3)]
            g = layers['fogM'][y][x]
            if g[3] > 0: c = fog_lit(c, g, FB * LOOK['fogMBright'], 0.4, L)
            n = layers['near'][y][x]
            if n[3] > 0:
                an, sun = lit_amb(n, n[3], ambN, LOOK['nearShare'])
                an = [v * (1 - LOOK['fireCold'] * min(1.0, max(L) * LOOK['nearLight'] * 1.5)) for v in an]
                e = ledge(layers['near'], x, y)
                if e > 0: an = [an[k] * (1 + (LOOK['ledge'] - 1) * e) + amb['skyBottom'][k] * LOOK['ledgeSky'] * e for k in range(3)]
                cn = cold(n, an, sun); Lc, rf = lit_world(n, L); mk = moon_key(n)
                lit = [cn[k] + rf[k] * Lc[k] * LOOK['nearLight'] + n[k] * MOONC[k] * mk for k in range(3)]
                lit = [lit[k] + (nearHC[k] * n[3] - lit[k]) * NH for k in range(3)]
                c = [c[k] * (1 - n[3]) + lit[k] for k in range(3)]
            a = layers['fogA'][y][x]
            if a[3] > 0: c = fog_lit(c, a, FB, 0.6, L)
            w = layers['world'][y][x]
            if w[3] > 0:
                Lc, rf = lit_world(w, L); aw, sun = lit_amb(w, w[3], ambW); iv = inter[y][x]; kmul = 1.0
                fk = 1 - LOOK['fireCold'] * min(1.0, max(L) * 1.5)  # firelight displaces the cold inside its pool
                if fk < 1: aw = [v * fk for v in aw]
                if iv > 0:  # a cut-away room: the warm fill of its hearth and candles, no night pull
                    aw = [aw[k] + (INTER[k] - aw[k]) * iv for k in range(3)]; kmul = 1 - iv * torchI
                if GROUND <= y < GROUND + 8: aw = [v * gsky for v in aw]  # the lane's track faces the sky
                elif not actorpx[y][x]:
                    e = ledge(layers['world'], x, y)  # a silhouette's top edge catches the sky
                    if e > 0: aw = [aw[k] * (1 + (LOOK['ledge'] - 1) * e) + amb['skyBottom'][k] * LOOK['ledgeSky'] * e for k in range(3)]
                cw = cold2(w, aw, sun, kmul); c = [c[k] * (1 - w[3]) + cw[k] + rf[k] * Lc[k] + Lc[k] * LOOK['glowAdd'] * w[3] for k in range(3)]
                if GROUND <= y < GROUND + 7 and moonUp > 0:  # the moonlit track
                    c = [c[k] + w[k] * MOONC[k] * LOOK['moonTrack'] * moonUp * night for k in range(3)]
                ra = rimA[y][x]
                if ra > 0:  # a figure's rim on its screen-right edge (moon for an unlit creature), outshone by fire
                    tone = MOONRIM2 if rimT[y][x] == 1 else RIM; k_ = ra * (1 - min(1.0, max(L) * 1.5))
                    c = [c[k] + (tone[k] - c[k]) * k_ for k in range(3)]
            return [c[k] + emis[y][x][k] for k in range(3)]
        def top(c, x, y, L):
            b = layers['fogB'][y][x]
            if b[3] > 0: c = fog_lit(c, b, FB, 0.8, L)
            f = layers['fg'][y][x]
            if f[3] > 0:
                cf = cold(f, [v * fgA for v in ambW]); c = [c[k] * (1 - f[3]) + cf[k] + f[k] * L[k] * LOOK['fgLight'] for k in range(3)]
            fx = min(HW - 1.0, max(0.0, (x + 0.5) / 2 - 0.5)); fy = min(HH - 1.0, max(0.0, (y + 0.5) / 2 - 0.5)); x0, y0 = int(fx), int(fy); x1, y1 = min(HW - 1, x0 + 1), min(HH - 1, y0 + 1); tx, ty = fx - x0, fy - y0
            for k in range(3):
                c[k] += ((bl[y0][x0][k] * (1 - tx) + bl[y0][x1][k] * tx) * (1 - ty) + (bl[y1][x0][k] * (1 - tx) + bl[y1][x1][k] * tx) * ty) * LOOK['bloom']
            warm = min(1, max(0, max(L) * 1.5)); lu = 0.299 * c[0] + 0.587 * c[1] + 0.114 * c[2]
            fa = max(layers['fogA'][y][x][3], layers['fogB'][y][x][3], layers['fogM'][y][x][3])
            warmS = warm * (1 - ss((fa - 0.3) / 0.2))  # no warm saturation keep in dense fog (it made the glow pink)
            s2 = sat + (max(sat, 1.08) - sat) * warmS
            c = [lu + (c[k] - lu) * s2 for k in range(3)]; wv = amb['warmth']
            # the cold grade pushes blue (the old one added red: the violet night)
            tint = (1 + 0.10 * wv, 1 + 0.02 * wv, 1 - 0.12 * wv) if wv >= 0 else (1 + 0.20 * wv, 1 + 0.05 * wv, 1 - 0.15 * wv)
            c = [c[k] * (tint[k] + (1 - tint[k]) * warm) for k in range(3)]
            lu = 0.299 * c[0] + 0.587 * c[1] + 0.114 * c[2]; kb = amb['black'] * (1 - min(1.0, max(0.0, lu) / LOOK['blackR'])) ** 2
            c = [c[k] + BLACK2[k] * kb for k in range(3)]  # the darks lift toward navy, never to grey or black
            c = [min(v, 0.82) + 0.18 * (1 - math.exp(-max(v - 0.82, 0) / 0.18)) for v in c]
            u = ((x + 0.5) / TW * 2 - 1) * LOOK['vigX']; vv = (y + 0.5) / TH * 2 - 1; vg = 1 - vig * ss((math.hypot(u, vv) - 0.42) / 0.83)
            return [min(1, max(0, v * vg)) for v in c]
    for y in range(TH):
        for x in range(TW):
            L = lit_light(x, y); img[y][x] = top(base(x, y, L), x, y, L)
    # scene polish 2: the king keeps a cool rim (sky by day, moon at night) on his screen-right edge pixels, so he pops
    # against the ochre rock and dark stone (not a black outline: his sprite's own outline turns cool grey there)
    RIM = [c * max(lvl, 0.6) for c in (0.72, 0.82, 1.0)]
    for (name, wx, wy, tint, emissive, flip) in actors:
        spr = sprite(name, 0); w, h = len(spr[0]), len(spr); anchor = round(wx - whole['world']); left = anchor - w // 2; topy = GROUND - wy - h
        rimK = LOOK['rim'] if name == 'king' else 0.0
        for j in range(h):
            for i in range(w):
                p = spr[j][w - 1 - i if flip else i]; x, y = left + i, topy + j
                if p is None or not (0 <= x < TW and 0 <= y < TH): continue
                L = lit_light(x, y); b = base(x, y, L); al = [p[k] / 255 * tint[k] for k in range(3)]
                Lc, rf = lit_world(al, L)
                if L2:  # look 2: firelight displaces the cold; inside a cut-away room a figure takes its warm fill
                    iv = inter[y][x]; fk = 1 - LOOK['fireCold'] * min(1.0, max(L) * 1.5)
                    cl = cold2(al, [(ambW[k] + (INTER[k] - ambW[k]) * iv) * fk for k in range(3)], 1 - shade_share(al, 1.0), 1 - iv * torchI)
                else:
                    cl = cold(al, ambW, 1 - shade_share(al, 1.0)) if LOOK['duskSun'] > 0 else cold(al, ambW)
                litc = al if emissive else [cl[k] + rf[k] * Lc[k] + Lc[k] * LOOK['glowAdd'] for k in range(3)]
                if rimK > 0 and (i + 1 >= w or spr[j][w - 2 - i if flip else i + 1] is None):
                    fire = min(1.0, max(L) * 1.5)  # firelight (his lantern at night) outshines the rim
                    litc = [litc[k] + (RIM[k] - litc[k]) * rimK * (1 - fire) for k in range(3)]
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
