"""Lanternhold look 2: the world layout of the look mocks (ART-look2.md "Depth per region" and "Stage 2: the world
art"). Plain numbers, read by mock.py when it renders with look=2; the engine port takes its positions from here.

What look 2 changes against layout_m1b.py:
- DROP: layout_m1b instances look 2 leaves out: the old far mountains and valley hills, the old gorge walls, the far
  keep and the warden statue on the mid plane, the rock lips along the top edge, the valley's foreground rocks. The
  world plane's cliffs (cliffFlank, cliffFlankB, throatRock) are swapped for their granite versions at the same
  places (SWAP).
- PLANES: a near plane (parallax 0.75) between the mid plane and the world, and a mist band (fogM, parallax 0.62)
  between the mid and near planes.
- THE WORLD (stage 2, WORLD below): the Weltmauer on the far plane across the whole view, with the cleft as a narrow
  slot and the far castle in it; on the mid plane the shadow land's forest (world 0 to about 520), then the gorge:
  bare rock rising out of sight from its mouth (world 520 to 700) to the castle, the cleft's inner face behind the
  castle, and its end stepping down into the valley; the valley's painted distance on the far plane.
- DEPTH: single trees per region on the near plane, bushes on the world plane behind the actors, dark plants on the
  foreground plane, and the lane ground tiles (LANES) instead of the soil cross-section.

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
SWAP = {"cliffFlank": "cleftFlank", "cliffFlankB": "cleftFlankB", "throatRock": "cleftThroat"}
SWAP_SHADE = 1.0   # the granite versions' shade, as a factor on the old instances' shade


def dropped(d):
    if d["p"] == "mid" and d["s"] in ("gorgeWallA", "gorgeWallB", "gorgeWallC", "gorgeWallHigh", "gorgeMouth",
                                      "keepFar", "cliffFlank", "wardenStatue", "valleyMidA", "valleyMidB",
                                      "valleyMidC", "windmill"):
        return True
    if d["p"] == "far" and d["s"] in ("farMountain", "valleyFarA", "valleyFarB", "valleyFarC"):
        return True
    if d["p"] == "world" and d["s"] in SWAP:  # re-added as granite by instances()
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
    return {"firA": 29, "firB": 30, "firC": 34, "firD": 27, "deadTreeA": 17, "deadTreeB": 17,
            "linden": 52, "poplar": 14, "appleTree": 42, "willow": 52, "d2BushA": 30, "d2BushB": 22}[name]


def tree(plane, name, X, y=0, z=0, shade=1.0, flip=False):
    p = PARALLAX[plane]
    return dict(s=name, p=plane, x=round(at(p, X) - _w(name) / 2), y=y, z=z, sh=shade, f=flip)


# ---- stage 2: the world. Far plane x = 0.2 x camera x + screen x; mid plane x = 0.5 x camera x + screen x.
WALL_X, WALL_Y = -44, -17         # weltmauer 888x190: its ridge 135 to 173 px above the ground line
CLEFT_FRONT, CLEFT_BACK = 324, 650  # the two views of the cleft in the sprite: from the shadow land, from the valley
FAR_CASTLE_Y = 92                 # the far castles' foot above the sprite's bottom (75 above the ground line)
PATCH_FADE = (2330, 2520)         # the camera focus over which the valley's view of the cleft appears
GORGE_X, GORGE_Y = 345, -10       # gorgeRock 448x211 on the mid plane: the mouth's steps over world 520 to 700
FACE_X, FACE_Y = 740, -95         # cleftFace 448x218: its lit top edge 123 above the ground line; then cleftFaceEnd
GORGE_SHADE, FACE_SHADE = 0.42, 0.42

WORLD = [
    # --- far plane: the wall, the far castle's lights, the unbroken patch over the valley's view of the cleft
    dict(s="weltmauer", p="far", x=WALL_X, y=WALL_Y, z=-3,
         em=[("sprite", "farCastleGlow", CLEFT_FRONT - 15, FAR_CASTLE_Y, "fireGold", True)]),
    dict(s="weltmauerPatch", p="far", x=WALL_X + CLEFT_BACK - 19, y=WALL_Y, z=-2, fadeout=PATCH_FADE),
    dict(s="farCastlePane", p="far", x=WALL_X + CLEFT_BACK - 15, y=WALL_Y + FAR_CASTLE_Y, z=-1, fade=PATCH_FADE,
         em=[("sprite", "farCastlePane", 0, 0, "window", True)]),
    # a cloud deck before the wall: the peaks stand above the clouds
    dict(s="cloudA", p="far", x=-70, y=96, z=0), dict(s="cloudC", p="far", x=170, y=106, z=0, f=True),
    dict(s="cloudB", p="far", x=430, y=98, z=0), dict(s="cloudA", p="far", x=640, y=108, z=0, f=True),
    # the valley's painted distance, before the wall's end
    dict(s="valleyVista", p="far", x=620, y=-34, z=1), dict(s="valleyVista", p="far", x=1068, y=-34, z=1, f=True),
    # --- mid plane, the shadow land: the forest edge, twice, then the gorge's rock
    dict(s="shadowForest", p="mid", x=-128, y=-4, z=1), dict(s="shadowForest", p="mid", x=96, y=-4, z=1, f=True),
    dict(s="gorgeRock", p="mid", x=GORGE_X, y=GORGE_Y, z=3, sh=GORGE_SHADE),
    # --- mid plane, the cleft: the inner face behind the castle, its end toward the valley (no tree on its edge:
    # a tree there gives the cliff a scale, and a small one)
    dict(s="cleftFace", p="mid", x=FACE_X, y=FACE_Y, z=2, sh=FACE_SHADE),
    dict(s="cleftFaceEnd", p="mid", x=FACE_X + 448, y=FACE_Y, z=2, sh=FACE_SHADE),
]

DEPTH = [
    # --- the sky: a high cloud deck over the old bands (after the critic: a moon and few stars, the night sky a value
    # step lighter where the clouds catch the moon; at dusk their rims take the low sun)
    dict(s="cloudB", p="sky", x=60, y=152, z=-1), dict(s="cloudC", p="sky", x=330, y=160, z=-1, f=True),
    dict(s="cloudA", p="sky", x=600, y=154, z=-1),
    # --- the shadow land (world 0 to 1240) -------------------------------------------------------------------------
    # far plane: a low ridge of firs at the wall's foot
    *[dict(s="d2FirBeltFar", p="far", x=x, y=2, z=2) for x in (-120, 400)],
    # near plane: the open land (world 0 to 520): single firs in loose groups with gaps (behind the play plane; they
    # never cover an actor), none behind the beacon (470); the gorge's mouth (520 to 700): dead trees only; inside the
    # gorge (700 to the castle): no tree at all, only rock
    tree("near", "firB", 24), tree("near", "firD", 62, flip=True), tree("near", "deadTreeA", 150),
    tree("near", "firA", 236), tree("near", "firC", 284), tree("near", "firD", 318, flip=True),
    tree("near", "firB", 408, flip=True), tree("near", "firD", 524), tree("near", "deadTreeB", 566),
    tree("near", "deadTreeA", 622, flip=True), tree("near", "deadTreeB", 688, flip=True),
    # foreground: ferns, dead grass and roots in the open land and at the mouth; rock and scree in the gorge
    *[dict(s="d2FgFerns", p="fg", x=x, y=-30, z=2) for x in (-60, 420)],
    # --- the valley (from the back gate): a tree belt along the valley floor, trees behind the town ---------------
    *[dict(s="d2TreeBelt", p="mid", x=x, y=-2, z=3) for x in (1400, 1920)],
    # (the rows mix sizes and kinds and never keep one spacing; poplars stand in pairs)
    tree("near", "poplar", 2452), tree("near", "linden", 2548), tree("near", "appleTree", 2606),
    tree("near", "appleTree", 2658, flip=True), tree("near", "appleTree", 2741), tree("near", "poplar", 2868),
    tree("near", "poplar", 2884, flip=True), tree("near", "linden", 2992, flip=True), tree("near", "poplar", 3170),
    tree("near", "poplar", 3186, flip=True), tree("near", "linden", 3300), tree("near", "appleTree", 3448),
    tree("near", "appleTree", 3523, flip=True), tree("near", "linden", 3610, flip=True),
    # the river end: willows on the near bank
    tree("near", "willow", 3684), tree("near", "willow", 3790, flip=True),
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
    for d in WORLD + DEPTH:
        out.append(dict(s=d["s"], p=d["p"], x=d["x"], y=d.get("y", 0), z=d.get("z", 0), sh=d.get("sh", 1.0),
                        f=d.get("f", False), em=list(d.get("em", [])), li=[], anchor="ground", region=None,
                        fade=d.get("fade"), mv=None, fadeout=d.get("fadeout"), shadow=None, mist=None))
    for d in LM.instances():  # the world plane's cliffs in granite, at the old places
        if d["p"] == "world" and d["s"] in SWAP:
            out.append(dict(d, s=SWAP[d["s"]], sh=d["sh"] * SWAP_SHADE))
    return out
