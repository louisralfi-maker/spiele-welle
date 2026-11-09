"""Look 2, stage 1 (ART-look2.md): the six direction scenes, each rendered in the old look and in the new look from
the same frame. The scene content (the battle at the middle line, the courtyard's buildings, the town's buildings and
people) comes from the art lanes' context scenes; look 2 adds its depth layout itself (layout_look2.py) and, here, a
few particles (sparks over the fires, fireflies at dusk).

Usage (pure python, one render at a time; run_look2.sh does all twelve with the heat rule):
    python3 -I -B scene_look2.py <games/lanternhold> <scene> <1|2> <out.png> [art=<dir>] [depth=<dir>] [lut=<a>,<b>]
The old look (1) renders with run_m1b.sh's values, the renderer of today; the new look (2) with mock.py look=2.
"""
import json
import os
import runpy
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import layout_m1b as LM  # noqa: E402

OLD = ('gain=3.0 lift=0.55 midHaze=0.36 midShare=0.7 fogBright=2.4 fogGlow=0.7 farCool=0.75 farWarm=0.3 midWarm=0.7 '
       'midCool=0.25 fogScale=0.7 farHaze=0.34 midHazeDay=0.2 fgAmb=0.9 fgAmbNight=0.43 litCap=1.6 litNeutral=0.35 '
       'litCool=0.6 bounce=0.5 bounceDusk=2.2 duskSun=1 band=0.45 rim=0.5').split()
F = LM.CASTLE_FRONT_X
GLOW = {"sootling": "sootlingGlow", "sootlingB": "sootlingBGlow", "shadehound": "shadehoundGlow",
        "sootCrow": "sootCrowGlow", "ashBrute": "ashBruteGlow", "king": "kingGlow"}


def prop(s, x=None, cx=None, y=0, z=5, frame=0, f=False, lit=True, em=(), li=(), sh=1.0, glow=None):
    d = dict(s=s, y=y, z=z, frame=frame, f=f, lit=lit, sh=sh, em=[list(e) for e in em], li=[list(v) for v in li])
    if x is not None:
        d["x"] = x
    else:
        d["cx"] = cx
    g = glow or GLOW.get(s)
    if g:
        d["glow"] = g
    return d


def mask(dx, dy, w, h):
    return ("mask", dx, dy, w, h, "window")


def emitter(x, y, sprite, dx=0, dy=0, colour="fireGold", fades=False):
    return dict(x=x, y=y, em=[["sprite", sprite, dx, dy, colour, fades]])


# --- 1. the front at night: the middle line under attack (as the runner's shots 31 and 32) ------------------------
def front_night(look):
    ex = [
        prop("fireTower", x=913, z=3, em=[("sprite", "brazierFlame", 3, 37, "fireOrange", False)], li=[("brazier", 920, 43, 90)]),
        prop("archerTower", x=968, z=2), prop("catapult", x=990, z=1, frame=2), prop("stakePit", x=848, z=2),
        # archers on the wall (its top at y 52) and on the tower's deck (y 42), all aiming left
        prop("archer", cx=947, y=52, frame=3, f=True, z=8), prop("archer", cx=961, y=52, frame=4, f=True, z=8),
        prop("archer", cx=973, y=42, frame=2, f=True, z=8), prop("archer", cx=983, y=42, frame=0, f=True, z=8),
        # the Gloom's creatures: two in the fire tower's light at the stakes, the rest outside every light (glow only),
        # an ash brute caught in a fire arrow's pool
        prop("sootling", cx=839, frame=4, z=9), prop("sootlingB", cx=825, frame=1, z=9),
        prop("sootling", cx=805, frame=2, lit=False, z=9), prop("shadehound", cx=782, frame=1, lit=False, z=9),
        prop("ashBrute", cx=748, frame=1, z=9), prop("sootling", cx=722, frame=0, lit=False, z=9),
        prop("sootlingB", cx=706, frame=3, lit=False, z=9), prop("sootCrow", cx=868, y=74, frame=1, lit=False, z=9),
        # fire arrows in flight and burning where they landed, plain arrows, a firepot from the catapult
        prop("fireArrow", cx=905, y=78, frame=2, f=True, z=10, li=[("fireArrow", 902, 80, 12)]),
        prop("fireArrow", cx=842, y=40, frame=2, f=True, z=10, li=[("fireArrow", 839, 42, 12)]),
        prop("arrow", cx=925, y=88, frame=1, f=True, z=10), prop("arrow", cx=893, y=60, frame=2, f=True, z=10),
        dict(li=[["fireArrow", 828, 2, 22]]), dict(li=[["fireArrow", 752, 2, 22, 0.8]]),
        prop("firepot", cx=905, y=112, frame=1, z=10, li=[("firepot", 905, 114, 16)]),
        # the lord behind the wall, his lantern raised
        prop("king", cx=1004, frame=8, f=True, z=10, li=[("lantern", 998.5, 25, 40)]),
    ]
    if look == 2:  # sparks rising from the fire tower's bowl
        ex += [emitter(916, 52, "d2Sparks", colour="fireGold")]
    return dict(focus=900, tod=0.95, drop=[("brazier", 915)], extras=ex, king="off")


# --- 2. the castle front at dusk ---------------------------------------------------------------------------------
def castle_dusk(look):
    ex = [prop("gateWood", x=1337, z=6, frame=2)]
    ex += [prop("archer", cx=F + cx, y=LM.WALKWAY_Y, frame=fr, f=fl, z=8) for cx, fr, fl in ((66, 2, True), (121, 0, True), (173, 3, False))]
    ex += [prop("guardsman", cx=1404, frame=0, z=8, f=True)]
    return dict(focus=1360, tod=0.8, drop=[], extras=ex, king=1356)


# --- 3. the courtyard and the great hall at dusk -----------------------------------------------------------------
def court_dusk(look):
    ex = [
        prop("barracks", x=1480, z=1,
             em=[mask(8, 26, 4, 4), mask(21, 26, 4, 4), mask(39, 26, 4, 4), mask(52, 26, 4, 4), mask(23, 14, 1, 2), mask(41, 14, 1, 2)],
             li=[("window", 1490, 28, 8), ("window", 1521, 28, 8), ("lantern", 1503, 16, 20), ("lantern", 1521, 16, 20)]),
        prop("smithy", x=1550, z=1, em=[("sprite", "brazierFlame", 15, 13, "fireOrange", False)], li=[("brazier", 1569, 16, 40)]),
        prop("well", x=1614, z=2),
        prop("lodge", x=1640, z=1, em=[mask(11, 11, 4, 4)], li=[("window", 1653, 13, 8)]),
        prop("guardsman", cx=1512, frame=0, z=8), prop("builder", cx=1690, frame=4, z=8),
    ]
    return dict(focus=1700, tod=0.8, drop=[("well", 1600)], extras=ex, king=1742)


# --- 4./5. the town: the square at dusk, the town at noon ----------------------------------------------------------
def town(look, tod, focus, king):
    ex = [
        prop("bigHouse", x=2896, z=0,
             em=[mask(26, 24, 5, 5), mask(41, 24, 5, 5), mask(16, 9, 5, 5), mask(50, 9, 5, 5), mask(35, 40, 3, 2)],
             li=[("window", 2924, 26, 8), ("window", 2939, 26, 8), ("window", 2914, 11, 8), ("window", 2948, 11, 8)]),
        prop("market", x=3200, z=0),
        prop("tavern", x=3320, z=0,
             em=[mask(11, 25, 5, 5), mask(41, 25, 5, 5), mask(69, 25, 5, 5), mask(15, 9, 8, 5), mask(56, 9, 8, 5), mask(32, 10, 1, 2)],
             li=[("window", 3333, 27, 8), ("window", 3363, 27, 8), ("window", 3391, 27, 8), ("window", 3339, 11, 10),
                 ("window", 3380, 11, 10), ("lantern", 3352, 11, 20)]),
        prop("citizen", cx=3046, frame=1, z=8), prop("citizenB", cx=3160, frame=4, z=8, f=True),
        prop("citizenC", cx=2872, frame=2, z=8), prop("citizen", cx=2716, frame=5, z=8, f=True),
        prop("builder", cx=2990, frame=1, z=8, f=True),
    ]
    if look == 2 and tod > 0.7:  # fireflies over the fields and the verge at dusk
        ex += [emitter(2610, 8, "d2Fireflies", fades=True), emitter(3110, 6, "d2Fireflies", fades=True)]
    return dict(focus=focus, tod=tod, drop=[("houseC", 2900)], extras=ex, king=king)


# --- 6. the river end at golden hour -----------------------------------------------------------------------------
def river_golden(look):
    ex = [prop("citizenB", cx=3610, frame=2, z=8, f=True)]
    return dict(focus=3720, tod=0.745, drop=[], extras=ex, king=3700)


SCENES = {
    "front-night": front_night,
    "castle-dusk": castle_dusk,
    "court-dusk": court_dusk,
    "square-dusk": lambda look: town(look, 0.8, 3040, 3026),
    "town-noon": lambda look: town(look, 0.5, 2800, 2790),
    "river-golden": river_golden,
}


def main():
    G, name, look, out = sys.argv[1], sys.argv[2], int(sys.argv[3]), sys.argv[4]
    extra_args = sys.argv[5:]
    sc = SCENES[name](look)
    drop = sc.get("drop", [])
    instances = LM.instances

    def patched():
        return [d for d in instances() if not any(d["s"] == s and abs(d["x"] - x) < 0.5 for s, x in drop)]

    LM.instances = patched
    path = os.path.splitext(out)[0] + ".json"
    with open(path, "w") as fh:
        json.dump(sc["extras"], fh)
    look_args = ["look=2"] if look == 2 else OLD
    sys.argv = ["mock.py", G, "layout=m1b", "focus=%s" % sc["focus"], "tod=%s" % sc["tod"], *look_args,
                "extras=" + path, "actors=off", "king=%s" % sc.get("king", "off"), *extra_args, "out=" + out]
    runpy.run_path(os.path.join(HERE, "mock.py"), run_name="__main__")


if __name__ == "__main__":
    main()
