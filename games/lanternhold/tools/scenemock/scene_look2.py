"""Look 2, stage 1 (ART-look2.md): the six direction scenes, each rendered in the old look and in the new look from
the same frame. The scene content (the battle at the middle line, the courtyard's buildings, the town's buildings and
people) comes from the art lanes' context scenes; look 2 adds its depth layout itself (layout_look2.py) and, here, a
few particles (sparks over the fires, fireflies at dusk).

Stage 2 added three walk points of the world for the previews (look 2 only): shadow-night, wall-dusk, valley-golden.

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
        "sootCrow": "sootCrowGlow", "ashBrute": "ashBruteGlow", "king": "kingGlow", "lady": "ladyGlow",
        "kingSeated": "kingSeatedGlow", "ladySeated": "ladySeatedGlow", "hesper": "hesperGlow"}


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


def line_night(look):
    """The soldiers at night on the middle line (the art pass): archers on the wall and the tower's deck, the
    guardsmen at the wall's foot in the fire tower's light, one thrusting at a sootling, a builder at the stakes."""
    ex = [
        prop("fireTower", x=913, z=3, em=[("sprite", "brazierFlame", 3, 37, "fireOrange", False)], li=[("brazier", 920, 43, 90)]),
        prop("archerTower", x=968, z=2), prop("stakePit", x=816, z=2),
        prop("archer", cx=947, y=52, frame=3, f=True, z=8), prop("archer", cx=961, y=52, frame=4, f=True, z=8),
        prop("archer", cx=974, y=42, frame=2, f=True, z=8), prop("archer", cx=985, y=42, frame=0, f=True, z=8),
        prop("guardsman", cx=872, frame=7, f=True, z=9), prop("guardsman", cx=885, frame=0, f=True, z=9),
        prop("guardsman", cx=1010, frame=3, f=True, z=9), prop("builder", cx=1026, frame=1, f=True, z=9),
        prop("sootling", cx=855, frame=4, z=9), prop("sootlingB", cx=838, frame=1, z=9),
        prop("shadehound", cx=812, frame=1, lit=False, z=9), prop("sootling", cx=790, frame=2, lit=False, z=9),
        prop("arrow", cx=905, y=70, frame=1, f=True, z=10),
        prop("brazier", x=1038, z=3, em=[("sprite", "brazierFlame", 1, 11, "fireOrange", False)], li=[("brazier", 1043, 16, 56)]),
    ]
    if look == 2:
        ex += [emitter(916, 52, "d2Sparks", colour="fireGold")]
    return dict(focus=930, tod=0.95, drop=[("brazier", 915)], extras=ex, king="off")


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


# --- stage 2, the world (look 2 only; ART-look2.md section 13): three walk points for the previews -----------------
def shadow_night(look):
    """The outer line at the gorge's mouth at night: the forest to the left, the rock rising to the right, the
    creatures coming out of the fog toward the palisade and its braziers."""
    ex = [
        prop("brazier", x=599, z=3, em=[("sprite", "brazierFlame", 1, 11, "fireOrange", False)], li=[("brazier", 604, 16, 56)]),
        prop("brazier", x=617, z=3, em=[("sprite", "brazierFlame", 1, 11, "fireOrange", False)], li=[("brazier", 622, 16, 56)]),
        prop("sootling", cx=588, frame=4, z=9), prop("sootlingB", cx=570, frame=1, z=9),
        prop("ashBrute", cx=532, frame=1, lit=False, z=9), prop("shadehound", cx=500, frame=2, lit=False, z=9),
        prop("sootling", cx=474, frame=2, lit=False, z=9), prop("gloomweaver", cx=436, frame=0, lit=False, z=9),
        prop("sootlingB", cx=404, frame=3, lit=False, z=9), prop("shadehound", cx=372, frame=0, lit=False, z=9),
        prop("sootCrow", cx=556, y=66, frame=1, lit=False, z=9), prop("sootCrow", cx=462, y=84, frame=0, lit=False, z=9),
        prop("archer", cx=688, frame=3, f=True, z=8), prop("guardsman", cx=704, frame=0, f=True, z=8),
        prop("king", cx=726, frame=8, f=True, z=10, li=[("lantern", 720.5, 25, 40)]),
        emitter(602, 22, "d2Sparks", colour="fireGold"),
    ]
    return dict(focus=556, tod=0.95, drop=[], extras=ex, king="off")


def wall_dusk(look):
    """The view back at dusk from the open shadow land: the Weltmauer across the whole view, the cleft's slot with
    the castle's lit windows in it, the gorge's first crag at the right."""
    return dict(focus=250, tod=0.8, drop=[], extras=[], king=306)


# --- stage 4, the art pass (look 2 only; ART-look2.md section 15) -------------------------------------------------
THRONE_X = 1830  # the throne's left edge before the middle of the hall's painted dais (the layout's: 1817)


def _throned(lord):
    """The throne at THRONE_X, the seated lord (or lady) on it turned to the hall, Odile behind the throne's side."""
    cx = THRONE_X + 7
    return [
        dict(prop("throne", x=THRONE_X, z=1), frames=1),
        dict(prop(lord, cx=cx, frame=2, f=True, z=5, li=[("lantern", cx - 5.5, 22.5, 40)]), frames=4),
        dict(prop("odile", cx=cx + 20, frame=4, f=True, z=6), frames=8),
    ]


def hall_audience(look, lord="kingSeated"):
    """The audience in the great hall: the lord (or the lady) seated on the throne, turned to the petitioners, the
    lantern's light at the glass (dx 5.5, dy 22.5); Odile at the side, the townsfolk waiting at the benches, one
    petitioner speaking. The throne stands before the middle of the hall's painted dais (THRONE_X, centre 1837:
    ART-look2.md 15.2 and 16), not at the layout's x 1817 where it stood before the dais's left end."""
    ex = [
        prop("citizenC", cx=1738, frame=4, z=5), prop("citizen", cx=1751, frame=5, z=5),
        dict(prop("petitionerE", cx=1766, frame=4, z=6), frames=6),
        prop("citizenB", cx=1779, frame=4, z=5, f=True),
        dict(prop("petitionerD", cx=1810, frame=4, z=6), frames=6),
    ] + _throned(lord)
    return dict(focus=1800, tod=0.5, drop=[("throne", 1817)], extras=ex, king="off")


def hall_benches(look, lord="kingSeated"):
    """The audience with the waiting townsfolk seated on two petitioners' benches (bench 32x10 at x 1722 and 1760;
    the seated proposals citizenSeated, citizenBSeated, citizenCSeated, 12x22, their bottoms on the floor)."""
    def seat(s, x, frame=0):
        return dict(prop(s, x=x, frame=frame, z=5), frames=2)
    ex = [
        _one("bench", x=1722, z=4), _one("bench", x=1760, z=4),
        seat("citizenCSeated", 1724), seat("citizenSeated", 1740, 1),
        seat("citizenBSeated", 1763), seat("citizenSeated", 1778),
        dict(prop("petitionerD", cx=1810, frame=4, z=6), frames=6),
    ] + _throned(lord)
    return dict(focus=1790, tod=0.5, drop=[("throne", 1817)], extras=ex, king="off")


# --- the castle grows (the art pass, SPRITES.md "The castle grows"): tiers 1 to 3, each also in its building state ---
RISE_MASKS = {"keepTop2": [(71, 93, 6, 10), (120, 94, 5, 9), (139, 94, 5, 9), (23, 109, 2, 7)],
              "keepTop3": [(71, 93, 6, 10), (20, 108, 3, 8), (122, 108, 3, 8)],
              "keepTop3Build": [(71, 93, 6, 10), (23, 109, 2, 7)],
              "backTop2": [(22, 94, 5, 9), (36, 93, 6, 10), (52, 94, 5, 9), (79, 109, 2, 7)],
              "backTop3": [(46, 93, 6, 10), (19, 108, 3, 8), (77, 108, 3, 8)],
              "backTop3Build": [(36, 93, 6, 10), (79, 109, 2, 7)],
              "castleFront3": [(39, 127, 4, 12), (39, 93, 4, 12), (223, 127, 4, 12), (223, 93, 4, 12)],
              "castleFront3Build": [(39, 127, 4, 12), (39, 93, 4, 12)]}


def _one(s, **kw):
    d = prop(s, **kw)
    d["frames"] = 1
    return d


def castle_tier(look, tier, build, view="gate", tod=0.8):
    """The castle at tier 1 to 3 (build: the tier's scaffolding state, that is the tier being built on the one
    before). view: gate (from the Throat, close), back (the back gate from the valley, close), far (the slot from
    the shadow land), farback (the slot from the valley)."""
    B_, K_ = 2230, 1286
    ex, drop = [], []
    rise = None if tier == 1 else "%s%d%s" % ("keepTop" if view == "gate" else "backTop", tier, "Build" if build else "")
    if view == "gate":
        ex += [prop("gateWood", x=1337, z=6, frame=2)]
        ex += [prop("archer", cx=F + cx, y=LM.WALKWAY_Y, frame=fr, f=fl, z=8) for cx, fr, fl in ((66, 2, True), (173, 3, False))]
        if rise:
            drop.append(("keepTop", K_))
            ex.append(_one(rise, x=K_, y=40, z=-4, em=[mask(*m) for m in RISE_MASKS.get(rise, [])]))
        if tier == 3:
            name = "castleFront3Build" if build else "castleFront3"
            drop.append(("castleFront", F))
            ex.append(_one(name, x=F - 14, z=0,
                           em=[("sprite", "brazierFlame", 107, 130, "fireOrange", False), ("sprite", "brazierFlame", 152, 130, "fireOrange", False),
                               ("sprite", "flame", 104, 61, "fireGold", True), ("sprite", "flame", 159, 61, "fireGold", True)]
                              + [mask(*m) for m in RISE_MASKS[name]],
                           li=[("brazier", F + 97, 136, 44), ("brazier", F + 142, 136, 44), ("torch", F + 92, 64, 30),
                               ("torch", F + 147, 64, 30), ("lantern", F + 120, 40, 34)]))
        if tier == 1 and build:
            ex.append(_one("castleFrontScaffold", x=F, z=0.5))
            ex.append(prop("builder", cx=F + 78, y=LM.WALKWAY_Y, frame=1, z=8))
        return dict(focus=1360, tod=tod, drop=drop, extras=ex, king=1356)
    if view == "back":
        if rise:
            ex.append(_one(rise, x=B_ + 50, y=40, z=-4, em=[mask(*m) for m in RISE_MASKS.get(rise, [])]))
        return dict(focus=2330, tod=tod, drop=drop, extras=ex, king=2420)
    far = "farCastle%s%d%s" % ("Back" if view == "farback" else "", tier, "Build" if build else "")
    cleft = 650 if view == "farback" else 324            # layout_look2's CLEFT_BACK, CLEFT_FRONT; WALL_X -44, WALL_Y -17
    if tier > 1:
        d = _one(far, x=-44 + cleft - 24, y=-17 + 92, z=-0.5,
                 em=[] if build else [("sprite", far + "Glow", 0, 0, "fireGold", True)])
        d["p"] = "far"
        ex.append(d)
    sw = {} if tier == 1 else {"farCleftGlowBack" if view == "farback" else "farCleftGlow":
                               "farCleftGlow%s%d%s" % ("Back" if view == "farback" else "", tier, "Build" if build else "")}
    if view == "farback":
        return dict(focus=2560, tod=tod, drop=drop, extras=ex, king=2604, swap=sw)
    return dict(focus=250, tod=tod, drop=drop, extras=ex, king=306, swap=sw)


SCENES = {
    # the castle's tiers: tier<1|2|3>[b]-<gate|back|far|farback>[-day] (b: the building state; -day: at noon)
    **{"tier%d%s-%s%s" % (t, "b" if b else "", v, d): (lambda look, t=t, b=b, v=v, d=d: castle_tier(look, t, b, v, 0.5 if d else 0.8))
       for v in ("gate", "back", "far", "farback") for t in (1, 2, 3) for b in (False, True) for d in ("", "-day")},
    "hall-audience": hall_audience,
    "hall-audience-lady": lambda look: hall_audience(look, "ladySeated"),
    "hall-benches": hall_benches,
    "hall-empty": lambda look: dict(focus=1800, tod=0.5, drop=[], extras=[], king="off"),
    "shadow-night": shadow_night,
    "wall-dusk": wall_dusk,
    "valley-golden": lambda look: town(look, 0.745, 2560, 2604),
    "front-night": front_night,
    "line-night": line_night,
    "castle-dusk": castle_dusk,
    "court-dusk": court_dusk,
    "square-dusk": lambda look: town(look, 0.8, 3040, 3026),
    "market-dusk": lambda look: town(look, 0.8, 3285, 3300),  # stage 4: the market and the tavern at dusk
    "town-noon": lambda look: town(look, 0.5, 2800, 2790),
    "river-golden": river_golden,
}


def main():
    G, name, look, out = sys.argv[1], sys.argv[2], int(sys.argv[3]), sys.argv[4]
    extra_args = sys.argv[5:]
    sc = SCENES[name](look)
    drop = sc.get("drop", [])
    instances = LM.instances

    swap = sc.get("swap", {})                                # emitter sprites replaced by name (the far tiers' slot glow)

    def patched():
        return [d for d in instances() if not any(d["s"] == s and abs(d["x"] - x) < 0.5 for s, x in drop)]

    if swap and look == 2:                                   # the look-2 world list (the Weltmauer and its slot glows)
        import layout_look2 as LL2
        LL2.WORLD[:] = [dict(d, em=[(e[0], swap.get(e[1], e[1])) + tuple(e[2:]) if e[0] == "sprite" else e for e in d["em"]])
                        if d.get("em") else d for d in LL2.WORLD]

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
