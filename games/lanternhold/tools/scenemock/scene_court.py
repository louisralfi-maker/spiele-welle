"""Context scenes of the M3 court art lane (ART-court.md): the court members and guests of SPRITES.md "M3" in the M1b
world (the great hall 1700-1960, the courtyard 1420-1700), rendered by mock.py through its extras hook.

As scene_buildings.py, a scene names the layout props it replaces (`drop`: sprite id and x of a layout_m1b instance);
this file removes them by wrapping layout_m1b.instances() before mock.py runs (mock.py and layout_m1b.py stay
untouched). The M3 sprites are not in mock.py's contract table (SPRITES.md's M3 table has no frame column), so every
court extra names its strip's frame count (`frames`). Sprites that are only proposals of this lane (the seated king,
build/recraft/lh/court/proposals/) are served from a mock root: a folder of symlinks to games/lanternhold's Core,
Render, SPRITES.md and every Resources/Art PNG, plus the proposals; nothing is written into Resources/Art.

Usage (pure python, one render at a time, see run_court.sh for the heat rule):
    python3 -I scene_court.py <games/lanternhold> <scene> <out.png>
Scenes:
    hall-day         the great hall at noon: the king on the throne (the seated proposal), Odile at his side, the
                     waiting petitioners (petitionerD, petitionerE) and townsfolk at the benches' place (x 1740-1800,
                     no bench sprite yet), Pip juggling between them and the throne
    hall-night       the hall at night: Seren in its left corner with her cold grey lantern, Mother Hesper tending the
                     hearth with her staff's flame, Odile reading the ledger by the throne
    hall-herald      the herald of the Lightless King before the throne at dusk, the king seated, Odile and Brannock
    courtyard-day    the courtyard at noon: Brannock before the barracks, Bram by the smithy's forge, Marek at the
                     well, Tamsin gossiping, the king walking among them
    courtyard-guests the courtyard in the afternoon: Ser Ludo marching in, the bard playing at the well, the envoy from
                     the coast holding out his scroll, the king
    lineup-day       every court member, guest and petitioner body in a row across the hall at noon, the king first for
                     scale (idle frames; Pip juggles)
    lineup-night     the same row at night: the hearth, the candles, the king's lantern and the three glow strips
"""
import json
import os
import runpy
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import layout_m1b as LM  # noqa: E402

# the M1b look values (run_m1b.sh) plus the renderer's cap on reflected firelight, as run_actors.sh
LOOK = ('gain=3.0 lift=0.55 midHaze=0.36 midShare=0.7 fogBright=2.4 fogGlow=0.7 farCool=0.75 farWarm=0.3 midWarm=0.7 '
        'midCool=0.25 fogScale=0.7 litCap=1.6 litNeutral=0.35').split()

# frame counts of the M3 strips (SPRITES.md "M3": court and guests 8, petitioners 6) and the earlier actors used here
FRAMES = dict(odile=8, brannock=8, pip=8, hesper=8, tamsin=8, bram=8, marek=8, seren=8, serLudo=8, bard=8, envoy=8,
              herald=8, petitionerD=6, petitionerE=6, kingSeated=4, king=10, citizen=6, citizenB=6, citizenC=6,
              guardsman=9, builder=6, archer=5)
GLOW = {"hesper": "hesperGlow", "seren": "serenGlow", "herald": "heraldGlow", "king": "kingGlow",
        "kingSeated": "kingSeatedGlow"}


def actor(s, cx, frame=0, y=0, f=False, z=6, lit=True, **kw):
    d = dict(s=s, cx=cx, frame=frame, frames=FRAMES[s], y=y, f=f, z=z, lit=lit)
    if s in GLOW:
        d["glow"] = GLOW[s]
    d.update(kw)
    return d


def king(cx, frame, f=False, z=6):
    """The walking king with his lantern light at the glass (dx +5.5, dy 23; ART-actors.md)."""
    dx = -5.5 if f else 5.5
    return actor("king", cx, frame, f=f, z=z, li=[["lantern", cx + dx, 23, 40]])


def king_seated(f=True):
    """The lord on the throne (x 1817-1831, centre 1824), turned to the petitioners (left), in the seated idle
    (frame 2 of the art pass's kingSeated, 4 frames: 0-1 sit down, 2-3 idle; ART-look2.md section 15); his lantern
    light at the glass (dx 5.5, dy 22.5 on all four frames)."""
    cx = 1824
    return actor("kingSeated", cx, 2, f=f, z=4, li=[["lantern", cx + (-5.5 if f else 5.5), 22.5, 40]])


def hesper_flame(cx, frame, f=False):
    """Hesper's flame lights a little: a candle's pool at the cup before her chin (ART-court.md "Glow positions":
    dx +5.5 from her foot, dy 19; 18 in the bob frames 1, 3 and 5, 22 in talk 6 with the staff lifted)."""
    dx = -5.5 if f else 5.5
    dy = {1: 18, 3: 18, 5: 18, 6: 22}.get(frame, 19)
    return dict(li=[["candle", cx + dx, dy, 12, 0.9]])


def courtyard_buildings():
    """The courtyard as ART-buildings.md's scene places it: barracks 1480, smithy 1550 (its forge glows), the well
    1614 (moved from 1600), the builders' lodge 1640."""
    def mask(dx, dy, w, h):
        return ["mask", dx, dy, w, h, "window"]
    return [
        dict(s="barracks", x=1480, z=1,
             em=[mask(8, 26, 4, 4), mask(21, 26, 4, 4), mask(39, 26, 4, 4), mask(52, 26, 4, 4), mask(23, 14, 1, 2), mask(41, 14, 1, 2)],
             li=[["window", 1490, 28, 8], ["window", 1521, 28, 8], ["lantern", 1503, 16, 20], ["lantern", 1521, 16, 20]]),
        dict(s="smithy", x=1550, z=1, em=[["sprite", "brazierFlame", 15, 13, "fireOrange", False]], li=[["brazier", 1569, 16, 40]]),
        dict(s="well", x=1614, z=2),
        dict(s="lodge", x=1640, z=1, em=[mask(11, 11, 4, 4)], li=[["window", 1653, 13, 8]]),
    ]


def scene_hall_day():
    ex = [
        # waiting at the benches' place (x 1740-1800): townsfolk and the two petitioner bodies, facing the throne
        actor("citizenC", 1738, 4, z=5), actor("citizen", 1751, 5, z=5), actor("petitionerE", 1766, 4, z=6),
        actor("citizenB", 1779, 4, z=5, f=True), actor("petitionerD", 1792, 4, z=6),
        # Pip juggling in the open floor before the throne
        actor("pip", 1806, 6, f=True, z=7),
        # the king on the throne, Odile at his side
        king_seated(),
        actor("odile", 1843, 4, f=True, z=6),
    ]
    return dict(focus=1820, tod=0.5, extras=ex)


def scene_hall_night():
    ex = [
        # the Stranger in the hall's left corner, her lantern's cold light
        actor("seren", 1712, 4, z=6),
        # Odile with the ledger by the throne, Mother Hesper at the hearth, her staff's flame
        actor("odile", 1808, 6, z=6),
        actor("hesper", 1902, 4, f=True, z=6), hesper_flame(1902, 4, f=True),
    ]
    return dict(focus=1800, tod=0.95, extras=ex)


def scene_hall_herald():
    ex = [
        actor("herald", 1795, 6, z=6),
        king_seated(),
        actor("odile", 1843, 7, f=True, z=6),
        actor("brannock", 1859, 4, f=True, z=5),
        actor("guardsman", 1752, 0, z=5),
    ]
    return dict(focus=1810, tod=0.76, extras=ex)


def scene_courtyard_day():
    ex = courtyard_buildings() + [
        actor("brannock", 1504, 6, z=8),
        actor("bram", 1586, 4, f=True, z=8),
        actor("tamsin", 1628, 6, z=8),
        king(1648, 6, f=True, z=8),
        actor("marek", 1675, 7, f=True, z=8),
    ]
    return dict(focus=1590, tod=0.5, drop=[("well", 1600)], extras=ex)


def scene_courtyard_guests():
    ex = courtyard_buildings() + [
        actor("serLudo", 1528, 1, z=8),
        actor("bard", 1604, 6, z=8),
        king(1636, 6, z=8),
        actor("envoy", 1662, 6, f=True, z=8),
        actor("guardsman", 1500, 0, z=7),
    ]
    return dict(focus=1590, tod=0.62, drop=[("well", 1600)], extras=ex)


LINEUP = ["odile", "brannock", "pip", "hesper", "tamsin", "bram", "marek", "seren", "serLudo", "bard", "envoy", "herald",
          "petitionerD", "petitionerE"]


def scene_lineup(tod):
    ex = [king(1709, 6, z=7)]
    for k, name in enumerate(LINEUP):
        cx = 1726 + 16 * k
        ex.append(actor(name, cx, 6 if name == "pip" else 4, z=7))
        if name == "hesper":
            ex.append(hesper_flame(cx, 4))
    return dict(focus=1830, tod=tod, extras=ex)


SCENES = {
    "hall-day": scene_hall_day,
    "hall-night": scene_hall_night,
    "hall-herald": scene_hall_herald,
    "courtyard-day": scene_courtyard_day,
    "courtyard-guests": scene_courtyard_guests,
    "lineup-day": lambda: scene_lineup(0.5),
    "lineup-night": lambda: scene_lineup(0.95),
}


def mock_root(G, root):
    """A folder that mirrors games/lanternhold for mock.py (symlinks) and adds this lane's proposal sprites."""
    mr = os.path.join(root, "build/recraft/lh/court/mockroot")
    art = os.path.join(mr, "Resources", "Art")
    os.makedirs(art, exist_ok=True)
    for name in ("Core", "Render", "SPRITES.md"):
        link = os.path.join(mr, name)
        if not os.path.lexists(link):
            os.symlink(os.path.join(os.path.abspath(G), name), link)
    srcs = [os.path.join(os.path.abspath(G), "Resources", "Art"), os.path.join(root, "build/recraft/lh/court/proposals")]
    for old in os.listdir(art):
        os.remove(os.path.join(art, old))
    for src in srcs:
        if os.path.isdir(src):
            for f in os.listdir(src):
                if f.endswith(".png"):
                    os.symlink(os.path.join(src, f), os.path.join(art, f))
    return mr


def main():
    G, name, out = sys.argv[1], sys.argv[2], sys.argv[3]
    sc = SCENES[name]()
    drop = sc.get("drop", [])
    instances = LM.instances

    def patched():
        return [d for d in instances() if not any(d["s"] == s and abs(d["x"] - x) < 0.5 for s, x in drop)]

    LM.instances = patched
    root = os.path.abspath(os.path.join(HERE, "..", "..", "..", ".."))
    path = os.path.join(root, "build/recraft/lh/preview/court", "%s.json" % name)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as fh:
        json.dump(sc["extras"], fh)
    mr = mock_root(G, root)
    sys.argv = ["mock.py", mr, "layout=m1b", "focus=%s" % sc["focus"], "tod=%s" % sc["tod"], *LOOK, "extras=" + path,
                "actors=off", "king=%s" % sc.get("king", "off"), "out=" + out]
    runpy.run_path(os.path.join(HERE, "mock.py"), run_name="__main__")


if __name__ == "__main__":
    main()
