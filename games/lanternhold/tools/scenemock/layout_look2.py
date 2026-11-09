"""Lanternhold look 2, stage 1: the depth layout of the look mocks (ART-look2.md "Depth per region"). Plain numbers,
read by mock.py when it renders with look=2. Not the final world: stage 2 paints the real shadow land, Weltmauer and
valley art and replaces these stand-ins (tools/depthart.py) one by one.

What look 2 changes against layout_m1b.py:
- DROP: layout_m1b instances look 2 leaves out. The gorge's far wall (gorgeWallA/B/C on the mid plane before the
  throat) and the rock lips along the top edge go: the shadow land is open (DESIGN.md, Louis' decisions of 09.11.
  evening); the Weltmauer's cliffs (the throat rock, the flanks, gorgeWallHigh) stay at the cleft around the castle.
  The valley's foreground rocks give way to the meadow strips.
- PLANES: a near plane (parallax 0.75) between the mid plane and the world, and a mist band (fogM, parallax 0.62)
  between the mid and near planes.
- DEPTH: rows of trees per region on the far, mid and near planes, bushes on the world plane behind the actors, dark
  plants on the foreground plane, and the lane ground tiles (LANES) instead of the soil cross-section.

Coordinates as layout_m1b.py (plane x of the left edge, y the bottom above the ground line). `at(p, X)` is the plane x
that shows at the same screen column as world x X when the camera is centred on X, so a near tree placed with
at(0.75, X) stands behind world X in the view centred there.
"""
import layout_m1b as LM

VIEW_W = LM.VIEW_W
PARALLAX = dict(LM.PARALLAX, near=0.75, fogM=0.62)
SHADOW_END = LM.CASTLE_FRONT_X      # the shadow land: world 0 to 1240
VALLEY_START = 2430                 # past the back gate


def at(p, X):
    return VIEW_W / 2 + p * (X - VIEW_W / 2)


# ------------------------------------------------------------------------------------------------ what look 2 drops
def dropped(d):
    if d["p"] == "mid" and d["s"] in ("gorgeWallA", "gorgeWallB", "gorgeWallC") and d["x"] < 690:
        return True
    if d["p"] == "fg" and d["s"].startswith("fgOverhang"):
        return True
    if d["p"] == "fg" and d["s"].startswith("fgRock") and d["x"] > 2900:  # the valley's rocks: the meadow replaces them
        return True
    return False


# ------------------------------------------------------------------------------------------------ the lane ground
# (world x0, x1, tile family): the moor track in the shadow land, cobbles from the cleft through the castle, the earth
# lane in the valley (a cobbled market square is stage 2 art). Variants A-D by a hash of the tile index.
LANES = [
    (-64, 1240, "laneMoor"),
    (1240, 2430, "laneCobble"),
    (2430, LM.GROUND_TILE_END, "laneEarth"),
]


def lane_at(x):
    for x0, x1, fam in LANES:
        if x0 <= x < x1:
            return fam
    return "laneEarth"


# ------------------------------------------------------------------------------------------------ fog by region
def fog_region(x):
    """The mist's share by world x: thick in the shadow land, thinner in the cleft, light in the valley."""
    if x < SHADOW_END - 120:
        return 1.0
    if x < SHADOW_END + 80:
        return 1.0 - 0.3 * (x - (SHADOW_END - 120)) / 200
    if x < VALLEY_START:
        return 0.7
    return 0.45


# ------------------------------------------------------------------------------------------------ depth instances
def _w(name):
    return {"d2FirA": 59, "d2FirB": 49, "d2FirC": 37, "d2FirD": 67, "d2DeadTree": 60, "d2Linden": 84, "d2Poplar": 24,
            "d2PoplarB": 24, "d2Orchard": 40, "d2OrchardB": 34, "d2OrchardC": 46, "d2Willow": 70, "d2BushA": 30,
            "d2BushB": 22}[name]


def tree(plane, name, X, y=0, z=0, shade=1.0, flip=False):
    p = PARALLAX[plane]
    return dict(s=name, p=plane, x=round(at(p, X) - _w(name) / 2), y=y, z=z, sh=shade, f=flip)


DEPTH = [
    # --- the sky: a high cloud deck over the old bands (after the critic: a moon and few stars, the night sky a value
    # step lighter where the clouds catch the moon; at dusk their rims take the low sun)
    dict(s="cloudB", p="sky", x=60, y=152, z=-1), dict(s="cloudC", p="sky", x=330, y=160, z=-1, f=True),
    dict(s="cloudA", p="sky", x=600, y=154, z=-1),
    # --- the shadow land (world 0 to 1240): fir forest rows in fog, each farther row paler -------------------------
    # far plane: a low ridge of firs at the horizon, under the far mountains' foot
    *[dict(s="d2FirBeltFar", p="far", x=x, y=2, z=1) for x in (-120, 400)],
    # mid plane: the forest's edge; the warden statue (z 2) stands in front of it
    *[dict(s="d2FirBelt", p="mid", x=x, y=-2, z=1) for x in (-140, 380)],
    dict(s="d2FirBeltB", p="mid", x=560, y=-4, z=1, f=True),
    # near plane: single firs and dead trees in loose groups with gaps (behind the play plane; they never cover an
    # actor), the tallest far from the lines, a dead tree or a small fir near them
    tree("near", "d2FirD", 30), tree("near", "d2FirB", 70, flip=True), tree("near", "d2DeadTree", 160),
    tree("near", "d2FirA", 250), tree("near", "d2FirC", 290, flip=True), tree("near", "d2FirB", 420),
    tree("near", "d2FirD", 470, flip=True), tree("near", "d2DeadTree", 560, flip=True), tree("near", "d2FirC", 690),
    tree("near", "d2FirB", 728, flip=True), tree("near", "d2DeadTree", 800), tree("near", "d2FirC", 1040),
    # (the fir by the cleft's mouth stays low: from the castle front it would poke over the cliff into the sky)
    tree("near", "d2FirC", 1090, flip=True), tree("near", "d2FirC", 1150),
    # foreground: ferns, dead grass and roots
    *[dict(s="d2FgFerns", p="fg", x=x, y=-30, z=2) for x in (-60, 420, 900)],  # none in front of the castle front
    # --- the valley (from the back gate): a tree belt along the valley floor, trees behind the town ---------------
    *[dict(s="d2TreeBelt", p="mid", x=x, y=-2, z=1) for x in (1290, 1810)],
    # (the orchard rows mix sizes and kinds and never keep one spacing: 34 and 68 px apart on screen)
    tree("near", "d2Poplar", 2452), tree("near", "d2Linden", 2548), tree("near", "d2OrchardB", 2606),
    tree("near", "d2Orchard", 2652, flip=True), tree("near", "d2OrchardC", 2741), tree("near", "d2PoplarB", 2868),
    tree("near", "d2Poplar", 2882), tree("near", "d2Linden", 2992, flip=True), tree("near", "d2PoplarB", 3170),
    tree("near", "d2Poplar", 3186), tree("near", "d2Linden", 3300), tree("near", "d2OrchardC", 3448),
    tree("near", "d2OrchardB", 3523, flip=True), tree("near", "d2Linden", 3610),
    # the river end: a willow on the near bank
    tree("near", "d2Willow", 3684), tree("near", "d2Willow", 3790, flip=True),
    # bushes on the world plane behind the actors (z -3: behind the houses' fronts)
    tree("world", "d2BushA", 2560, z=-3), tree("world", "d2BushB", 2884, z=-3), tree("world", "d2BushA", 3080, z=-3,
                                                                                    flip=True),
    tree("world", "d2BushB", 3190, z=-3), tree("world", "d2BushA", 3440, z=-3),
    # foreground meadow (gaps in front of the square) and reeds at the bank
    dict(s="d2FgMeadow", p="fg", x=round(at(1.3, 2600) - 240), y=-26, z=2),
    dict(s="d2FgMeadow", p="fg", x=round(at(1.3, 3360) - 240), y=-26, z=2),
    dict(s="d2FgReeds", p="fg", x=round(at(1.3, 3760) - 80), y=-24, z=3),
    # where the lane ends at the river: a grassy bank over the river end's soil block (after the critic)
    dict(s="d2LaneEnd", p="world", x=3676, y=-30, z=3),
]

# cut-away rooms (mock.py look=2: their rect takes a warm interior ambient, hearth and candle fill, instead of the
# sky's): sprite -> (x0, x1, y0, y1), sprite x from the left edge, y from the bottom row up
INTERIORS = {"hallInterior": (24, 236, 0, 77), "smithy": (10, 34, 0, 31)}

# chimney smoke (world plane, drawn like a mist bank): (house x, flip, chimney dx) of the town's cottages; set by the
# scene (a cottage the scene drops loses its smoke)
SMOKE = [(2480, False), (2800, True), (3090, False)]


def instances():
    out = []
    for d in DEPTH:
        out.append(dict(s=d["s"], p=d["p"], x=d["x"], y=d.get("y", 0), z=d.get("z", 0), sh=d.get("sh", 1.0),
                        f=d.get("f", False), em=[], li=[], anchor="ground", region=None, fade=None, mv=None,
                        fadeout=None, shadow=None, mist=None))
    return out
