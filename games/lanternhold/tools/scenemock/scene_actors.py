"""Context scenes for the actor and creature art (M2b art lane): writes the extras JSON of one scene for mock.py's
extras hook and prints the scene's focus and time of day. Usage (run_actors.sh does this for every scene):
    python3 -I scene_actors.py <scene> <out.json>
Scenes:
    battle-night   the outer line at night (focus 700, tod 0.95): sootlings, shadehounds and an ash brute come from
                   the left, the ones near the torches and a fire arrow's pool lit, the rest only their glow; archers
                   draw and loose from the tower, a guard holds behind the palisade, the king rallies with his lantern
    battle-day     the same by day (tod 0.5), everything lit
    finale         the Lightless King at the middle line (focus 930, tod 0.97), unlit inside his own aura (his cold
                   silhouette), a gloomweaver behind him, sootlings he called, archers and the king on the wall
    giant          the ash giant stomping at the stone wall (focus 930, tod 0.95), archers on the wall, a guard
    town-golden    the king among citizens in the town at golden hour (focus 2900, tod 0.75), a builder at a plot
    town-night     the same at night (tod 0.95), the king's lantern lit
Positions follow SPRITES.md ("Where things stand") and layout_m1b.py: outer line 640 (tower 662, torches 636 and
664), middle line 940 (braziers 896 and 920, torches 936 and 980 on the wall, tower 978), town plots 2832, 2932.
Every actor is placed by its foot centre (cx); creatures face right (towards the hearth), defenders on the walls face
left (f true). Frames as SPRITES.md's frame use.
"""
import json
import sys

FOCUS_TOD = {
    "battle-night": (700, 0.95), "battle-day": (700, 0.5), "finale": (930, 0.97), "giant": (930, 0.95),
    "town-golden": (2900, 0.75), "town-night": (2900, 0.95),
}

GLOW = {"sootling": "sootlingGlow", "sootlingB": "sootlingBGlow", "shadehound": "shadehoundGlow",
        "sootCrow": "sootCrowGlow", "ashBrute": "ashBruteGlow", "gloomweaver": "gloomweaverGlow",
        "ashGiant": "ashGiantGlow", "lightlessKing": "lightlessKingGlow", "king": "kingGlow"}


def actor(s, cx, frame=0, y=0, f=False, lit=True, z=5, **kw):
    d = dict(s=s, cx=cx, frame=frame, y=y, f=f, lit=lit, z=z)
    if s in GLOW:
        d["glow"] = GLOW[s]
    d.update(kw)
    return d


def king(cx, frame, y=0, f=False, z=6):
    """The king with his lantern light at the lantern glass (frames 0-7 at dx +5.5, dy 23; command 8-9 higher)."""
    lift = {8: 2, 9: 3}.get(frame, 0)
    dx = 5.5 if not f else -5.5
    return actor("king", cx, frame, y=y, f=f, z=z, li=[["lantern", cx + dx, y + 23 + lift, 40]])


def fire_arrow(x):
    """A fire arrow burning in the ground: its flame and its light pool (radius 22). Intensity 0.6: the mock has no
    cap on reflected firelight (the renderer caps it at 1.6), so a full-strength white pool blows pale ash to white."""
    return dict(x=x, y=0, em=[["sprite", "flame", 0, 0, "fireWhite", False]], li=[["fireArrow", x + 2, 3, 22, 0.6]])


def battle(day):
    lit = lambda near: True if day else near  # noqa: E731
    out = [
        dict(s="archerTower", cx=662, y=0, z=1),
        # defenders: two archers on the tower platform, a guard behind the palisade, the king rallying
        actor("archer", 657, 3, y=42, f=True),
        actor("archer", 668, 4, y=42, f=True),
        actor("guardsman", 676, 7, f=True),
        king(704, 8, f=True),
        # at the palisade, in a fire arrow's pool (602): lit; the light only reaches about 14 px on the ground
        actor("sootling", 629, 5, lit=lit(False)),
        actor("sootlingB", 608, 4, lit=lit(True)),
        actor("shadehound", 595, 0, lit=lit(True)),
        # in the dark between the pools: only their glow at night
        actor("sootling", 581, 1, lit=lit(False)),
        actor("sootlingB", 570, 2, lit=lit(False)),
        actor("sootCrow", 590, 1, y=44, lit=lit(False)),
        # a second pool (558)
        actor("sootling", 556, 3, lit=lit(True)),
        actor("shadehound", 540, 2, lit=lit(False)),
        # the ash brute caught in a third pool (512), a sootling beside it in the dark
        actor("ashBrute", 515, 1, lit=lit(True)),
        actor("sootling", 492, 0, lit=lit(False)),
    ]
    if not day:
        out += [fire_arrow(600), fire_arrow(556), fire_arrow(510)]
    return out


def finale():
    """Night 20 at the middle line: the Lightless King's own 80 px aura cancels every light around him (the braziers,
    the beacon's far reach), so he and the creatures near him are unlit and read by their glow strips alone: his cold
    teal silhouette, the gloomweaver's violet edges, the sootlings' smouldering rims and cracks. Lit in the beacon's
    reach: scene_buildings.py `beacon-finale`."""
    return [
        # the beacon's sweeping light from the left (radius 840 at x 470), far and soft here
        dict(li=[["beacon", 470, 130, 840, 0.45]]),
        actor("gloomweaver", 812, 1, y=6, lit=False),
        actor("sootling", 880, 4, lit=False),
        actor("sootlingB", 790, 1, lit=False),
        actor("sootling", 776, 2, lit=False),
        actor("lightlessKing", 852, 5, lit=False),
        # on the wall walk (the stone wall is 52 high): archers loosing at him, the king with his lantern raised
        actor("archer", 948, 4, y=52, f=True),
        king(960, 9, y=52, f=True, z=4),
        actor("archer", 972, 3, y=52, f=True),
        actor("guardsman", 992, 6, f=True),
    ]


def giant():
    return [
        dict(s="archerTower", cx=978, y=0, z=1),
        actor("ashGiant", 893, 5, lit=True),
        actor("sootling", 830, 0, lit=False),
        actor("shadehound", 815, 1, lit=False),
        actor("archer", 948, 3, y=52, f=True),
        actor("archer", 966, 4, y=52, f=True),
        actor("archer", 978, 2, y=42, f=True),
        actor("guardsman", 996, 0, f=True),
        actor("builder", 1010, 1, f=True),
    ]


def town(night):
    out = [
        dict(s="scaffold", cx=2832, y=0, z=1),
        actor("builder", 2822, 4),
        actor("builder", 2845, 5, f=True),
        actor("citizen", 2872, 4),
        king(2900, 2),
        actor("citizenB", 2934, 1, f=True),
        actor("citizenC", 2958, 4, f=True),
        actor("citizen", 3036, 0, f=True),
    ]
    return out


SCENES = {
    "battle-night": lambda: battle(False), "battle-day": lambda: battle(True), "finale": finale,
    "giant": giant, "town-golden": lambda: town(False), "town-night": lambda: town(True),
}

if __name__ == "__main__":
    name, path = sys.argv[1], sys.argv[2]
    with open(path, "w") as fh:
        json.dump(SCENES[name](), fh, indent=1)
    focus, tod = FOCUS_TOD[name]
    print(f"{focus} {tod}")
