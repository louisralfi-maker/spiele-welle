"""Context scenes of the buildings art lane (ART-buildings.md): the new building, overlay and projectile sprites in the
M1b world, rendered by mock.py with its extras hook.

Each scene names the layout props it replaces (`drop`: sprite id and x of a layout_m1b instance, e.g. the stone wall a
bastion stands in for); this file removes them by wrapping layout_m1b.instances() before mock.py imports the module
(mock.py and layout_m1b.py stay untouched; the extras hook adds props but cannot remove any). The extras go to
build/recraft/lh/preview/bld-<scene>.json, then mock.py runs once.

Usage (pure python, one render at a time, see run_buildings.sh for the heat rule):
    python3 -I scene_buildings.py <games/lanternhold> <scene> <out.png>
"""
import json
import os
import runpy
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import layout_m1b as LM  # noqa: E402

# the M1b look values (run_m1b.sh)
LOOK = ('gain=3.0 lift=0.55 midHaze=0.36 midShare=0.7 fogBright=2.4 fogGlow=0.7 farCool=0.75 farWarm=0.3 midWarm=0.7 '
        'midCool=0.25 fogScale=0.7').split()
F = LM.CASTLE_FRONT_X


def prop(s, x=None, cx=None, y=0, z=5, frame=0, f=False, lit=True, glow=None, em=(), li=(), sh=1.0):
    d = dict(s=s, y=y, z=z, frame=frame, f=f, lit=lit, sh=sh, em=[list(e) for e in em], li=[list(l) for l in li])
    if x is not None:
        d['x'] = x
    else:
        d['cx'] = cx
    if glow:
        d['glow'] = glow
    return d


def light(kind, x, y, r):
    return dict(li=[[kind, x, y, r]])


def mask(dx, dy, w, h):
    return ('mask', dx, dy, w, h, 'window')


# --- the defence line (middle line, wall 940, tower 978, braziers 896/920, engine 990, trap 860) -----------------------

def line_props(day):
    """The middle line built up: a fire tower in the second brazier's slot, an archer tower, a catapult behind the wall,
    a stake pit in front."""
    return [
        prop('fireTower', x=913, z=3, em=[('sprite', 'brazierFlame', 3, 37, 'fireOrange', False)], li=[('brazier', 920, 43, 90)]),
        prop('archerTower', x=968, z=2),
        prop('catapult', x=990, z=1, frame=0 if day else 2),
        prop('stakePit', x=848, z=2, frame=0),
    ]


def scene_line_night():
    ex = line_props(day=False)
    ex += [
        # archers on the wall (feet at y 52, the wall's top) and on the tower's deck (y 42), all aiming left
        prop('archer', cx=947, y=52, frame=3, f=True, z=8), prop('archer', cx=961, y=52, frame=4, f=True, z=8),
        prop('archer', cx=973, y=42, frame=2, f=True, z=8), prop('archer', cx=983, y=42, frame=0, f=True, z=8),
        # the Gloom's creatures: two in the brazier's light at the trap, two outside every light (glow only)
        prop('sootling', cx=839, frame=4, glow='sootlingGlow', z=9), prop('sootlingB', cx=825, frame=1, glow='sootlingBGlow', z=9),
        prop('sootling', cx=805, frame=2, lit=False, glow='sootlingGlow', z=9),
        prop('shadehound', cx=780, frame=1, lit=False, glow='shadehoundGlow', z=9),
        # fire arrows in flight and one burning where it landed, plain arrows, a firepot from the catapult
        prop('fireArrow', cx=905, y=78, frame=2, f=True, z=10, li=[('fireArrow', 902, 80, 12)]),
        prop('fireArrow', cx=842, y=40, frame=2, f=True, z=10, li=[('fireArrow', 839, 42, 12)]),
        prop('arrow', cx=925, y=88, frame=1, f=True, z=10), prop('arrow', cx=893, y=60, frame=2, f=True, z=10),
        dict(li=[['fireArrow', 828, 2, 22]]),
        prop('firepot', cx=905, y=112, frame=1, z=10, li=[('firepot', 905, 114, 16)]),
    ]
    # the king beside the catapult: his lantern lights the engine
    return dict(focus=930, tod=0.95, drop=[('brazier', 915)], extras=ex, king=1022)


def scene_line_day():
    ex = line_props(day=True)
    ex += [
        prop('bastion', x=936, z=1),
        # the scaffold over the bastion being built (two tiles), a builder hammering on its upper deck, one carrying in
        prop('scaffold', x=934, z=6), prop('scaffold', x=958, z=6),
        prop('builder', cx=951, y=28, frame=4, z=8), prop('builder', cx=916, frame=1, z=8),
        prop('archer', cx=974, y=42, frame=0, f=True, z=8),
    ]
    return dict(focus=930, tod=0.5, drop=[('brazier', 915), ('stoneWall', 940)], extras=ex, king=1030)


# --- the castle gate ---------------------------------------------------------------------------------------------------

def wall_archers():
    return [prop('archer', cx=F + cx, y=LM.WALKWAY_Y, frame=fr, f=fl, z=8) for cx, fr, fl in ((66, 2, True), (121, 0, True), (173, 3, False))]


def scene_gate(tier, frame=0):
    ex = [prop(tier, x=1337, z=6, frame=frame)] + wall_archers()
    if tier == 'gateBroken':
        # creatures pouring through the breach, past the wreck of the gate
        ex += [prop('sootling', cx=1392, frame=1, glow='sootlingGlow', z=9), prop('sootlingB', cx=1405, frame=3, glow='sootlingBGlow', z=9),
               prop('sootling', cx=1318, frame=2, glow='sootlingGlow', z=9), dict(li=[['fireArrow', 1352, 4, 22]])]
    return dict(focus=1360, tod=0.95, drop=[], extras=ex, king=1296)


# --- the Great Beacon ----------------------------------------------------------------------------------------------------

def scene_beacon_night():
    ex = [prop('greatBeacon', x=438, z=-1,
               em=[('sprite', 'beaconFire', 20, 123, 'fireWhite', False), ('mask', 9, 125, 46, 1, 'window')],
               # the game's beacon light is a 600 px sweeping cone (code lane); here a warm point light above the
               # flames shows the tower lit by its fire without washing the iron bowl out
               li=[('hearth', 470, 168, 230)])]
    return dict(focus=470, tod=0.97, drop=[('beaconRuin', 438)], extras=ex, king=540)


def scene_beacon_day():
    # the four stages side by side (a lineup for the review, not a game view): the ruin with the marker of the
    # unlocked plot, the rebuilt base, the half tower, the Great Beacon
    ex = [prop('beaconRuin', x=290, z=-1), prop('plotMarker', cx=279, z=2),
          prop('beaconBase', x=362, z=-1), prop('beaconTower', x=434, z=-1), prop('greatBeacon', x=506, z=-1)]
    return dict(focus=470, tod=0.5, drop=[('beaconRuin', 438)], extras=ex, king=610)


# --- the courtyard -------------------------------------------------------------------------------------------------------

def scene_courtyard():
    ex = [
        prop('barracks', x=1480, z=1,
             em=[mask(8, 26, 4, 4), mask(21, 26, 4, 4), mask(39, 26, 4, 4), mask(52, 26, 4, 4), mask(23, 14, 1, 2), mask(41, 14, 1, 2)],
             li=[('window', 1490, 28, 8), ('window', 1521, 28, 8), ('lantern', 1503, 16, 20), ('lantern', 1521, 16, 20)]),
        prop('smithy', x=1550, z=1, em=[('sprite', 'brazierFlame', 15, 13, 'fireOrange', False)], li=[('brazier', 1569, 16, 40)]),
        prop('well', x=1614, z=2),
        prop('lodge', x=1640, z=1, em=[mask(11, 11, 4, 4)], li=[('window', 1653, 13, 8)]),
        prop('guardsman', cx=1512, frame=0, z=8), prop('builder', cx=1690, frame=4, z=8),
    ]
    return dict(focus=1600, tod=0.77, drop=[('well', 1600)], extras=ex, king=1598)


# --- the town --------------------------------------------------------------------------------------------------------------

def town_props():
    return [
        prop('bigHouse', x=2896, z=0,
             em=[mask(26, 24, 5, 5), mask(41, 24, 5, 5), mask(16, 9, 5, 5), mask(50, 9, 5, 5), mask(35, 40, 3, 2)],
             li=[('window', 2924, 26, 8), ('window', 2939, 26, 8), ('window', 2914, 11, 8), ('window', 2948, 11, 8)]),
        prop('market', x=3200, z=0),
        prop('tavern', x=3320, z=0,
             em=[mask(11, 25, 5, 5), mask(41, 25, 5, 5), mask(69, 25, 5, 5), mask(15, 9, 8, 5), mask(56, 9, 8, 5), mask(32, 10, 1, 2)],
             li=[('window', 3333, 27, 8), ('window', 3363, 27, 8), ('window', 3391, 27, 8), ('window', 3339, 11, 10),
                 ('window', 3380, 11, 10), ('lantern', 3352, 11, 20)]),
        prop('citizen', cx=3046, frame=1, z=8), prop('citizenB', cx=3160, frame=4, z=8, f=True),
        prop('citizenC', cx=2872, frame=2, z=8), prop('citizen', cx=3300, frame=5, z=8, f=True),
    ]


def scene_town(tod, focus):
    return dict(focus=focus, tod=tod, drop=[('houseC', 2900)], extras=town_props(), king=focus - 10)


SCENES = {
    'line-night': scene_line_night,
    'line-day': scene_line_day,
    'gate-wood': lambda: scene_gate('gateWood'),
    'gate-iron': lambda: scene_gate('gateIron'),
    'gate-great': lambda: scene_gate('gateGreat'),
    'gate-broken': lambda: scene_gate('gateBroken'),
    'beacon-night': scene_beacon_night,
    'beacon-day': scene_beacon_day,
    'courtyard-dusk': scene_courtyard,
    'town-golden': lambda: scene_town(0.75, 3000),
    'town-night': lambda: scene_town(0.95, 3000),
    'market-golden': lambda: scene_town(0.75, 3270),
    'market-night': lambda: scene_town(0.95, 3270),
}


def main():
    G, name, out = sys.argv[1], sys.argv[2], sys.argv[3]
    sc = SCENES[name]()
    drop = sc.get('drop', [])
    instances = LM.instances

    def patched():
        return [d for d in instances() if not any(d['s'] == s and abs(d['x'] - x) < 0.5 for s, x in drop)]

    LM.instances = patched
    root = os.path.abspath(os.path.join(HERE, '..', '..', '..', '..'))
    path = os.path.join(root, 'build/recraft/lh/preview', 'bld-%s.json' % name)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w') as fh:
        json.dump(sc['extras'], fh)
    sys.argv = ['mock.py', G, 'layout=m1b', 'focus=%s' % sc['focus'], 'tod=%s' % sc['tod'], *LOOK, 'extras=' + path,
                'actors=off', 'king=%s' % sc.get('king', 'off'), 'out=' + out]
    runpy.run_path(os.path.join(HERE, 'mock.py'), run_name='__main__')


if __name__ == '__main__':
    main()
