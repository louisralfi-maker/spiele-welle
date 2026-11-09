"""Context scenes of the M3 art lane's step 3 (ART-court.md "Step 3"): the castle's rooms and the court's props in the
M1b world, rendered by mock.py through its extras hook, with step 1's court (scene_court.py's helpers).

A room's emitters and lights come from the anchors its paint function records (roomscenes.py, the same numbers
ART-court.md lists), so the mocks show exactly what the anchor table says. As in scene_court.py, a scene names the
layout props it replaces (`drop`: sprite id and x of a layout_m1b instance), and the court's proposal sprites (the
seated king) are served from the mock root; nothing is written into Resources/Art.

The engine shows a room's front while the king is outside and fades it out when he steps in (code lane); a "closed"
scene draws the front over the interior and its furniture (and drops the interior's lights, which a wall would hide:
a note for the code lane), an "open" scene draws the interior and the court in it.

Usage (pure python, one render at a time, see run_castle.sh for the heat rule):
    python3 -I scene_castle.py <games/lanternhold> <scene> <out.png>
Scenes:
    hall-closed-day / -night     the great hall's front from the courtyard: the king walking up to the door,
                                 the courtyard's barracks, smithy, well and lodge; at night the windows, the door's
                                 lanterns and the light under the door
    hall-open-day / -night       the hall open: the benches with the waiting petitioners, the seated king, Odile at
                                 the tax lectern, Pip juggling; at night Seren in the corner, Hesper and Pip at the
                                 hearth, a speech mark over Odile
    chapel-open-day / -night     the chapel of the Flame open with Mother Hesper at the altar; the hall's front closed
                                 on the left, the kitchen's front on the right
    kitchen-open-day / -night    the kitchen open with Tamsin at the table and the cat on its stool by the oven; the
                                 chapel's front closed on the left
    courtyard-day / -night       the courtyard with Marek's cart and Marek, the statue of the lamplighter king before
                                 the hall's closed front, Brannock and Bram
"""
import json
import os
import runpy
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, ".."))
import layout_m1b as LM  # noqa: E402
import scene_court as SC  # noqa: E402
import roomscenes  # noqa: E402

HALL_X, CHAPEL_X, KITCHEN_X = 1700, 1960, 2120
SC.FRAMES.update(bench=1, taxLectern=1, marekCart=1, statue=1, speakerMark=2)

# the hall's furniture in layout_m1b (dropped while its front is closed: the front hides it, and a wall would hide
# its lights)
HALL_FURNITURE = [("throne", 1817), ("hearth", 1870), ("candleStand", 1756), ("candleStand", 1796),
                  ("candleStand", 1926)]

_ANCHORS = {}


def anchors(sid):
    if sid not in _ANCHORS:
        _ANCHORS[sid] = roomscenes.SPRITES[sid]().anchors
    return _ANCHORS[sid]


def room(sid, x, z=4, fires=True):
    """A room sprite as an extra prop at world x, with the emitters and lights its paint function recorded."""
    em, li = [], []
    for a in anchors(sid):
        if a[0] == "mask":
            _, _name, dx, dy, w, h = a
            em.append(["mask", dx, dy, w, h, "window"])
        elif a[0] == "fire" and fires:
            _, _name, spr, dx, dy, _w = a
            em.append(["sprite", spr, dx, dy, "fireWhite" if spr == "candleFlame" else "fireOrange",
                       spr == "candleFlame"])
        elif a[0] == "light":
            _, _name, kind, dx, dy, r = a
            if kind in ("hearth", "brazier", "candle") and not fires:
                continue
            li.append([kind, x + dx, dy, r])
    return dict(s=sid, x=x, z=z, em=em, li=li)


def spot(sid, name):
    for a in anchors(sid):
        if a[0] == "spot" and a[1] == name:
            return a[2], a[3]
    raise KeyError(name)


def prop(sid, x, z=2):
    return dict(s=sid, x=x, z=z, frames=SC.FRAMES.get(sid, 1))


def chapel_front():
    """The chapel's front as layout_m1b draws it (its window glows), for scenes that drop and redraw it."""
    return dict(s="chapel", x=CHAPEL_X, z=3,
                em=[["sprite", "windowGlow", dx, 28, "window", True] for dx in (18, 54, 89, 125)],
                li=[["window", CHAPEL_X + dx + 3, 32, 14] for dx in (18, 54, 89, 125)])


def hall_props():
    return [prop("bench", 1712), prop("bench", 1760), prop("taxLectern", 1834)]


def scene_hall_closed(tod):
    ex = SC.courtyard_buildings() + [
        room("hallFront", HALL_X),
        SC.king(1678, 1 if tod < 0.9 else 6, z=8),
        SC.actor("pip", 1652, 6 if tod < 0.9 else 4, z=8),
    ]
    if tod < 0.9:
        ex.append(SC.actor("citizenB", 1736, 4, z=8, f=True))
    return dict(focus=1716, tod=tod, drop=HALL_FURNITURE + [("well", 1600)], extras=ex)


def scene_hall_open(tod):
    if tod < 0.9:
        ex = hall_props() + [
            SC.actor("citizenC", 1724, 4, z=5), SC.actor("petitionerE", 1740, 4, z=6),
            SC.actor("citizen", 1772, 5, z=5), SC.actor("petitionerD", 1788, 4, z=6),
            SC.actor("pip", 1804, 6, f=True, z=7),
            SC.king_seated(),
            SC.actor("odile", 1846, 6, f=True, z=6),
            prop("speakerMark", 1843, z=9) | dict(y=31, frame=1),
        ]
        return dict(focus=1820, tod=tod, extras=ex)
    ex = hall_props() + [
        SC.actor("seren", 1950 - 16, 4, f=True, z=6),
        SC.actor("odile", 1860, 4, f=True, z=6),
        SC.actor("hesper", 1902, 4, f=True, z=6), SC.hesper_flame(1902, 4, f=True),
        SC.actor("pip", 1916, 4, f=True, z=6),
        prop("speakerMark", 1857, z=9) | dict(y=31, frame=0),
    ]
    return dict(focus=1830, tod=tod, extras=ex)


def scene_chapel_open(tod):
    hx, hf = spot("chapelInterior", "hesper altar")
    ex = [
        room("hallFront", HALL_X),
        room("chapelInterior", CHAPEL_X, z=3),
        SC.actor("hesper", CHAPEL_X + hx, 4, f=hf < 0, z=7), SC.hesper_flame(CHAPEL_X + hx, 4, f=hf < 0),
        SC.king(CHAPEL_X + 30, 6, z=8),
    ]
    return dict(focus=2040, tod=tod, drop=HALL_FURNITURE + [("chapel", CHAPEL_X)], extras=ex)


def scene_kitchen_open(tod):
    tx, tf = spot("kitchenInterior", "tamsin table")
    ex = [
        room("kitchenInterior", KITCHEN_X, z=3),
        SC.actor("tamsin", KITCHEN_X + tx, 6 if tod < 0.9 else 4, f=tf < 0, z=7),
        SC.king(KITCHEN_X + 8, 6, z=8),
    ]
    return dict(focus=2170, tod=tod, drop=[("kitchen", KITCHEN_X)], extras=ex)


def scene_courtyard(tod):
    ex = SC.courtyard_buildings() + [
        room("hallFront", HALL_X),
        prop("marekCart", 1486, z=3),
        prop("statue", 1680, z=3),
        SC.actor("marek", 1542, 7 if tod < 0.9 else 4, f=True, z=8),
        SC.king(1600, 6, f=True, z=8),
        SC.actor("bram", 1586, 4, f=True, z=7),
    ]
    if tod < 0.9:
        ex.append(SC.actor("brannock", 1452, 4, z=8))
    return dict(focus=1590, tod=tod, drop=HALL_FURNITURE + [("well", 1600)], extras=ex)


SCENES = {
    "hall-closed-day": lambda: scene_hall_closed(0.5),
    "hall-closed-night": lambda: scene_hall_closed(0.95),
    "hall-open-day": lambda: scene_hall_open(0.5),
    "hall-open-night": lambda: scene_hall_open(0.95),
    "chapel-open-day": lambda: scene_chapel_open(0.5),
    "chapel-open-night": lambda: scene_chapel_open(0.95),
    "kitchen-open-day": lambda: scene_kitchen_open(0.5),
    "kitchen-open-night": lambda: scene_kitchen_open(0.95),
    "courtyard-day": lambda: scene_courtyard(0.5),
    "courtyard-night": lambda: scene_courtyard(0.95),
}


def main():
    G, name, out = sys.argv[1], sys.argv[2], sys.argv[3]
    sc = SCENES[name]()
    drop = sc.get("drop", [])
    instances = LM.instances

    def patched():
        return [d for d in instances() if not any(d["s"] == s and abs(d["x"] - x) < 0.5 for s, x in drop)]

    LM.instances = patched
    root = os.path.abspath(os.path.join(HERE, "..", "..", "..", ".."))
    path = os.path.join(root, "build/recraft/lh/preview/castle", "%s.json" % name)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as fh:
        json.dump(sc["extras"], fh)
    mr = SC.mock_root(G, root)
    sys.argv = ["mock.py", mr, "layout=m1b", "focus=%s" % sc["focus"], "tod=%s" % sc["tod"], *SC.LOOK,
                "extras=" + path, "actors=off", "king=off", "out=" + out]
    runpy.run_path(os.path.join(HERE, "mock.py"), run_name="__main__")


if __name__ == "__main__":
    main()
