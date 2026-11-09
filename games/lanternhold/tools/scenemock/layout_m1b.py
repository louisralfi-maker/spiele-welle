"""Lanternhold milestone M1b: the world layout as data (the gorge, the castle that seals it, the open valley).

The Swift scene is ported from this file. Everything here is plain numbers; `instances()` at the bottom only expands the
tile cycles into single sprite instances, in the order the scene draws them.

Coordinates
- Side view. x grows to the right in game pixels, y grows up; the ground line is y = 0. A sprite instance is placed by
  its bottom-left corner (x, y). `flip` mirrors it horizontally (emitter and window offsets are given unflipped, as
  measured on the sprite file, and mirror with it).
- Each plane has its own x coordinate: a sprite at plane x X appears at screen column X - parallax * cameraX, where
  cameraX = clamp(focus - VIEW_W / 2, 0, WORLD_WIDTH - VIEW_W). On the world plane plane x = world x.
- `anchor: "top"` (the foreground overhangs) places the sprite from the top of the screen instead of the ground:
  y is then the distance from the screen's top row to the sprite's top row (0 = flush), so the lip covers the screen
  top on every phone (154 to 181 visible rows above the ground).
- z orders instances inside one plane (low first). Actors draw on the world plane after every world prop.
- `fade: (f0, f1)` (the far view of the keep, Swift port): the instance fades in while the camera's focus moves from f0
  (invisible) to f1 (opaque), so it is not seen from the courtyard and the hall, where the real keep stands behind the
  camera.

Backdrop regions
- Every far and mid instance belongs to the gorge set or the valley set. On each plane the border between them sits at
  the plane x that shows at the back gate's passage when the camera is centred there:
      border(p) = VIEW_W / 2 + p * (BACK_GATE_X - VIEW_W / 2)
  far 641, mid 1274, world 2330 (the gate itself), fg 2964.
- The sets do not clip: an instance belongs to a set by where it stands, and two pieces lie just across the mid border
  on purpose (the first valley hill tile, which starts under the gorge mouth's slope, and the far view of the keep,
  which shows above the town). At the back-gate view both sit behind the 200 px tall back gate.

Emitters (`em`), all offsets in sprite pixels from the sprite's bottom-left, dy up:
- ("sprite", name, dx, dy, colour, fades): an emissive sprite (flame, brazierFlame, hearthFire, lanternGlass,
  windowGlow) whose bottom-left is at (dx, dy).
- ("mask", dx, dy, w, h, colour): window glass. Inside this rect every dark glass pixel of the sprite (palette night0,
  night1 or ink) glows; the scene builds the emissive mask from the palette. Windows dim when the house sleeps.
- `fades`: torches, windows and lanterns follow the ambient ramp's torch strength; braziers, the hearth and the
  statue's bowl fire burn all night (and dimly by day).
Lights (`li`): (kind, x, y, radius) with x and y in the instance's plane coordinates (absolute, not sprite-local).
Kinds as in `Core/LightField`: torch 30, brazier 56, lantern 40, hearth 70, window 8 (M1b polish: was 14 to 18;
the glow stays at the window frame), candle 12.
"""

VIEW_W = 437            # iPhone 17 Pro at s = 6 (the runner); 175 rows above the ground, 26 below
WORLD_WIDTH = 3900      # the town and the river moved 100 px right to give the castle room (was 3800)
PARALLAX = {"sky": 0.05, "far": 0.2, "mid": 0.5, "world": 1.0, "fg": 1.3}

# --- gameplay positions (unchanged) ---
SPAWN_X = 40
BEACON_X = 470          # the Great Beacon site; beaconRuin is centred on it
OUTER_LINE_X = 640
MIDDLE_LINE_X = 940
GATE_X0, GATE_X1 = 1300, 1420   # line 1, the gatehouse; its walk-through gateway is x 1337 to 1383
WALKWAY_Y = 124         # the gatehouse wall walk (archers stand here); the merlons reach 127

# --- the castle (1300 to 2430) ---
CASTLE_FRONT_X = 1240   # castleFront 240x236: towers 1240-1297 and 1422-1479, gatehouse 1294-1426
COURTYARD = (1426, 1700)
GREAT_HALL = (1700, 1960)
CHAPEL = (1960, 2120)
KITCHEN = (2120, 2240)
BACK_GATE_SPRITE_X = 2230   # castleBackGate 200x200 spans 2230-2430
BACK_GATE_X = 2330          # the back gate's passage centre (sprite x 76-124)

# --- the valley ---
TOWN = (2430, 3680)
RIVER = (3680, 3900)    # riverEnd 220x64; the water starts about 95 px in; the king's walk ends at 3760
GROUND_TILE_END = 3712  # ground tiles (64 px) run from 0 to here; the river bank covers the rest


def border(plane):
    return round(VIEW_W / 2 + PARALLAX[plane] * (BACK_GATE_X - VIEW_W / 2))


# ------------------------------------------------------------------------------------------------- tile cycles
# (plane, region, sprite names in order, first x, y, z, shade, count). Instances step by the sprite width.
CYCLES = [
    # The gorge's far wall: one panorama, A-B-C joins seamlessly and C joins A again. Six tiles end exactly where
    # gorgeWallHigh begins (its left edge continues from C). Never two copies of a tile on screen at once (576 apart).
    ("mid", "gorge", ["gorgeWallA", "gorgeWallB", "gorgeWallC"], -462, 0, 0, 1.0, 6),
    # The valley's mid hills (lead-in tile C under the gorge mouth, then A from the border).
    ("mid", "valley", ["valleyMidC", "valleyMidA", "valleyMidB", "valleyMidC", "valleyMidA", "valleyMidB"], 1082, 0,
     -2, 1.0, 6),
    # The valley's far mountains, raised so they show above the hills.
    # (lead-in tile C left of the border, seen at the left edge from the town; behind the gorge wall it only peeks
    # through the notches)
    ("far", "valley", ["valleyFarC", "valleyFarA", "valleyFarB", "valleyFarC"], 449, 55, 0, 1.0, 4),
]

# ------------------------------------------------------------------------------------------------- sky plane
# Cloud bands (M1b polish), parallax 0.05: sky x 0 to 710 covers every camera (the plane shifts at most 173 px).
# Albedo is cream tops (parchment, foam) over lavender bellies (farPale, moon). The renderer lights them like this
# (mock.py base(), cloud branch): the sunlit share Lw = clamp((luma - 0.6) / 0.3) takes ambient * cloudSun, the rest
# skyTop * cloudFill (1.7), then cloudHaze toward skyBottom; so at golden hour the tops turn gold and the
# bellies violet, at night both go dim blue. y is the band's bottom above the ground line; tops stay below row 172.
SKY = [
    dict(s="cloudA", x=-40, y=122),
    dict(s="cloudC", x=260, y=132),
    dict(s="cloudB", x=520, y=112),
    dict(s="cloudA", x=760, y=128, flip=True),
]

# ------------------------------------------------------------------------------------------------- far plane
FAR = [
    # gorge set: glimpses only (the gorge wall hides almost all of it); kept for the notches
    # (M1b polish: the farPeak pyramids are gone; one poked through the wall's notch and looked pasted in)
    dict(s="farMountain", x=-40, y=40, region="gorge", z=0, shade=0.92),
    dict(s="farMountain", x=100, y=36, region="gorge", z=0, shade=0.92, flip=True),
    dict(s="farMountain", x=240, y=40, region="gorge", z=0, shade=0.92),
    dict(s="farMountain", x=380, y=34, region="gorge", z=0, shade=0.92, flip=True),
    # The keep seen from the town (M1b polish: moved from the mid plane, where it stood beside the back gate like a
    # second castle in the valley). On the far plane at x 545 it sits behind the back gate at the back-gate view
    # (screen 123 to 273, showing only between the gate's towers above its wall walk, where the real keep stands) and at
    # the left edge of the town frame (focus 2900: screen 9 to 159), its foot behind the hills; z above the mountains.
    # It fades in from focus 2150 to the back gate (2330): from the courtyard and the hall it floated above the gorge
    # mouth as a second castle (the art review's open point).
    dict(s="castleKeep", x=545, y=-62, region="valley", z=2, fade=(2150, 2330)),
]

# ------------------------------------------------------------------------------------------------- mid plane
MID = [
    # The warden statue, carved into the wall; seen behind the king at the front (focus 600 to 1000). Its bowl fire
    # burns all night: a hearthFire in the dark hollow and a brazier light.
    # It stands 34 px low (its plinth behind the ground strip) so the crown and the bowl stay on screen.
    dict(s="wardenStatue", x=430, y=-34, region="gorge", z=2, shade=0.88,  # grey stone in a dark niche (M1b polish)
         em=[("sprite", "hearthFire", 40, 153, "fireOrange", False)],
         li=[("hearth", 478, 124, 70)]),
    # The throat: the wall rises above the screen behind the castle front (at the gate view, x 669-909 is behind the
    # front); its right end hides behind the front.
    dict(s="gorgeWallHigh", x=690, y=0, region="gorge", z=1, shade=0.85),  # under the hazy wall's value (M1b polish)
    # Inside the walls the cliffs still rise behind the courtyard and the hall.
    dict(s="gorgeWallB", x=862, y=0, region="gorge", z=0),
    # Where the gorge ends: seen above the kitchen from the back gate, falling away to the right behind the gate.
    dict(s="gorgeMouth", x=1030, y=0, region="gorge", z=3),
    # The windmill on a hill crest of valleyMidB (96 px high there), right of the keep.
    dict(s="windmill", x=1500, y=93, region="valley", z=1),
    # The river's far shore (M1b polish): seen behind the river at the world's end (focus 3720 shows mid x 1948 to
    # 2168); in front of the hills, at the ground line, so the river reads wide and closes the world.
    dict(s="riverFarBank", x=1940, y=0, region="valley", z=2),
]

# ------------------------------------------------------------------------------------------------- world plane
FIRE = "fireOrange"
GOLD = "fireGold"
WIN = "window"


def torch(cx, by):
    """A torch post standing at (cx, by)."""
    return dict(s="torchPost", x=cx - 2, y=by, z=2, em=[("sprite", "flame", 0, 12, GOLD, True)],
                li=[("torch", cx, by + 15, 30)])


def brazier(cx):
    return dict(s="brazier", x=cx - 5, y=0, z=3, em=[("sprite", "brazierFlame", 1, 11, FIRE, False)],
                li=[("brazier", cx, 16, 56)])


F = CASTLE_FRONT_X
ROCK_SHADE = 0.7    # the throat rock one value step below the castle stone, so the front separates from the cliffs
FLANK_SHADE = 0.62  # the flanks right beside the towers, darker still (rock in the castle's shadow)
K = 1286  # castleKeep x: centred behind the gatehouse, it fills the gap between the towers above the wall walk
B = BACK_GATE_SPRITE_X

WORLD = [
    # --- the front (built state for the mock: both lines manned) ---
    dict(s="beaconRuin", x=BEACON_X - 32, y=0, z=-1),
    dict(s="palisade", x=OUTER_LINE_X, y=0, z=1), torch(636, 20), torch(664, 20),
    dict(s="ballista", x=676, y=0, z=1),
    dict(s="stoneWall", x=MIDDLE_LINE_X, y=0, z=1), torch(936, 38), torch(980, 38), brazier(896), brazier(920),
    # --- the castle front, sealing the gorge's throat ---
    # The throat on the world plane: the high rock stands behind the flanks on both sides, so the castle front sits in
    # one broad mass of rock rising above the screen (a lone flank read as a tree trunk in the mock). On the right
    # it rises behind the courtyard wall.
    # (Mirrored on the left so its overhang leans out over the gorge; the straight-cut strip it carries on from
    # gorgeWallC lies behind the flanks on both sides.)
    dict(s="gorgeWallHigh", x=F - 190, y=0, z=-5, flip=True, shade=ROCK_SHADE),
    dict(s="gorgeWallHigh", x=F + 278, y=0, z=-5, shade=ROCK_SHADE),  # its cut left edge just behind the right flank;
                                                                     # shows other columns than the mirrored copy
    # cliffFlank is plain rock (the left cliff of rocks-a); its straight right edge hides behind the tower bodies,
    # which start 10 px inside the front's edges. The right one stands in FRONT of the courtyard wall (z -1), so from
    # the gate view rock rises right of the right tower from the ground to above the screen; the wall run starts
    # behind it.
    dict(s="cliffFlank", x=F - 53, y=0, z=-3, shade=FLANK_SHADE),
    dict(s="cliffFlank", x=F + 213, y=0, z=-1, flip=True, shade=FLANK_SHADE),
    dict(s="castleKeep", x=K, y=0, z=-4,  # front elevation; only its top row of windows clears the wall walk
         # only the lower 10 rows of each tall window glow (lamplight low in the room, not a full blob); one of the
         # middle windows stays dark
         em=[("mask", 69, 150, 13, 10, WIN), ("mask", 113, 150, 12, 10, WIN), ("mask", 111, 96, 13, 10, WIN),
             ("mask", 69, 35, 13, 10, WIN), ("mask", 113, 35, 13, 10, WIN)],
         li=[("window", K + 75, 160, 8), ("window", K + 119, 160, 8)]),
    dict(s="castleFront", x=F, y=0, z=0,
         em=[("sprite", "brazierFlame", 93, 130, FIRE, False), ("sprite", "brazierFlame", 138, 130, FIRE, False),
             ("sprite", "flame", 90, 61, GOLD, True), ("sprite", "flame", 145, 61, GOLD, True),
             ("mask", 29, 124, 6, 15, WIN), ("mask", 202, 124, 6, 15, WIN),   # right tower unmirrored at x 173
             ("mask", 29, 69, 6, 15, WIN), ("mask", 202, 69, 6, 15, WIN)],
         # the wall-walk braziers smaller (44, was 56) and a warm pool in the gateway, so the king at the gate is the
         # one focal point of the hero shot
         li=[("brazier", F + 97, 136, 44), ("brazier", F + 142, 136, 44),
             ("torch", F + 92, 64, 30), ("torch", F + 147, 64, 30), ("lantern", F + 120, 40, 34)]),
    # --- inside: courtyard, great hall, chapel, kitchen ---
    # the courtyard wall runs from 1580, out of the gate view: from the gate, rock (the right flank, then the high
    # rock from the ground) closes the frame right of the right tower; inside, the castle is built into the throat
    *[dict(s="castleWall", x=1580 + 40 * k, y=0, z=-2,
           em=[("mask", 17, 58, 6, 8, WIN)] if k == 1 else [],
           li=[("window", 1580 + 40 * k + 20, 62, 8)] if k == 1 else []) for k in range(3)],
    dict(s="well", x=1600, y=0, z=1),
    dict(s="hallInterior", x=1700, y=0, z=-2),
    dict(s="throne", x=1817, y=0, z=1),
    dict(s="hearth", x=1870, y=0, z=1, em=[("sprite", "hearthFire", 5, 3, FIRE, False)], li=[("hearth", 1883, 10, 70)]),
    *[dict(s="candleStand", x=cx - 2, y=0, z=1, em=[("sprite", "candleFlame", 1, 15, "fireWhite", True)],
           li=[("candle", cx, 17, 12)]) for cx in (1758, 1798, 1928)],
    dict(s="chapel", x=1960, y=0, z=0,
         em=[("sprite", "windowGlow", dx, 28, WIN, True) for dx in (18, 54, 89, 125)],
         li=[("window", 1960 + dx + 3, 32, 14) for dx in (18, 54, 89, 125)]),
    dict(s="kitchen", x=2120, y=0, z=-1,
         em=[("sprite", "windowGlow", dx, 32, WIN, True) for dx in (26, 79)],
         li=[("window", 2120 + dx + 3, 36, 14) for dx in (26, 79)]),
    # --- the back gate: the castle's friendly face towards the town ---
    dict(s="castleBackGate", x=B, y=0, z=0,  # front elevation, 200x172 under a 28 px top margin
         em=[("sprite", "lanternGlass", 51, 95, GOLD, True), ("sprite", "lanternGlass", 136, 95, GOLD, True),
             ("mask", 28, 107, 10, 20, WIN), ("mask", 166, 107, 10, 20, WIN),
             ("mask", 28, 72, 10, 20, WIN), ("mask", 166, 72, 10, 20, WIN)],
         li=[("lantern", B + 53, 97, 40), ("lantern", B + 138, 97, 40),
             ("window", B + 33, 117, 8), ("window", B + 171, 117, 8)]),
    # --- the town (moved 100 px right) ---
    *[x for n, start in enumerate((2480, 2800, 2900, 3090)) for x in (
        dict(s="house", x=start, y=0, z=0, shade=0.97, flip=n % 2 == 1,
             # window glass only (the four night1 panes of each half-timbered window), no soft glow sprite
             em=[("mask", 11, 8, 5, 6, WIN), ("mask", 46, 8, 5, 6, WIN)],
             li=[("window", start + (64 - 13 - 1 if n % 2 == 1 else 13), 11, 8),
                 ("window", start + (64 - 48 - 1 if n % 2 == 1 else 48), 11, 8)]),
        dict(s="lanternPost", x=start + 68, y=0, z=1, em=[("sprite", "lanternGlass", 1, 18, GOLD, True)],
             li=[("lantern", start + 71, 20, 28)]))],
    dict(s="field", x=2600, y=0, z=-1), dict(s="field", x=2680, y=0, z=-1),
    dict(s="well", x=3013, y=0, z=1),
    # --- the river closes the world: the bank drops to the water, two stumps of the old bridge ---
    dict(s="riverEnd", x=RIVER[0], y=-26, z=2),
]

# ------------------------------------------------------------------------------------------------- foreground plane
# fg x for something that should pass in front of world x when the camera is centred there: 1.3 * x - 65.6.
# The gorge (world 0 to 1240) is fg 0 to 1546; the gate view keeps fg 1640 to 1780 clear so the gateway shows.
FG = [
    # dark rock along the bottom edge (y -30: the tallest peaks reach 3 to 6 px above the ground line)
    dict(s="fgRockA", x=20, y=-30), dict(s="fgRockC", x=170, y=-30), dict(s="fgRockB", x=330, y=-30, flip=True),
    dict(s="fgRockA", x=505, y=-30, flip=True), dict(s="fgRockC", x=640, y=-30), dict(s="fgRockB", x=820, y=-30),
    dict(s="fgRockC", x=960, y=-30, flip=True), dict(s="fgRockA", x=1110, y=-30),
    # the throat: the rock thickens before the castle
    dict(s="fgRockB", x=1250, y=-30, flip=True), dict(s="fgRockA", x=1330, y=-26), dict(s="fgRockC", x=1410, y=-28),
    dict(s="fgRockB", x=1490, y=-24, flip=True), dict(s="fgRockA", x=1555, y=-28, flip=True),
    # the castle inside: one rock by the courtyard, none in the hall
    dict(s="fgRockC", x=1900, y=-32),
    # the valley: sparse
    dict(s="fgRockC", x=3150, y=-32), dict(s="fgRockA", x=3560, y=-32, flip=True), dict(s="fgRockB", x=4020, y=-32),
    dict(s="fgRockC", x=4480, y=-32, flip=True),
    # the gorge only: rock lips with roots along the top edge, closer together towards the throat
    dict(s="fgOverhangA", x=40, y=0, anchor="top"), dict(s="fgOverhangB", x=300, y=0, anchor="top"),
    dict(s="fgOverhangA", x=590, y=0, anchor="top", flip=True), dict(s="fgOverhangB", x=880, y=0, anchor="top", flip=True),
    dict(s="fgOverhangA", x=1120, y=0, anchor="top"), dict(s="fgOverhangB", x=1290, y=0, anchor="top"),
    dict(s="fgOverhangA", x=1400, y=0, anchor="top", flip=True), dict(s="fgOverhangB", x=1500, y=0, anchor="top"),
]

# ------------------------------------------------------------------------------------------------- actors (mock only)
# What the mock draws to judge scale: soot creatures at the outer line, archers on the middle line and on the castle's
# wall walk, two citizens in the market, the king at the focus.
ACTORS = [
    *[("eyeGlints", x + (2 if k == "s" else 6), 9 if k == "s" else 10, True, False)
      for x, k in ((556, "s"), (571, "s"), (588, "h"), (606, "s"), (620, "h"), (632, "s"))],
    # staggered spacing and one turned the other way, so they do not read as clones (the scene also gives each
    # archer its own animation phase)
    *[("archer", x, 52, False, fl) for x, fl in ((944, True), (957, False), (972, True))],
    *[("archer", F + cx, WALKWAY_Y, False, fl) for cx, fl in ((66, True), (121, True), (173, False))],
    ("citizen", 3002, 0, False, False), ("citizen", 3044, 0, False, True),
]


def instances():
    """Every sprite instance: dicts with s, p (plane: sky, far, mid, world, fg), x, y, z, sh (shade), f (flip), em, li,
    anchor, region."""
    out = []

    def add(plane, d, region=None):
        out.append(dict(s=d["s"], p=plane, x=d["x"], y=d.get("y", 0), z=d.get("z", 0), sh=d.get("shade", 1.0),
                        f=d.get("flip", False), em=d.get("em", []), li=d.get("li", []),
                        anchor=d.get("anchor", "ground"), region=region or d.get("region"), fade=d.get("fade")))

    for plane, region, names, x0, y, z, shade, count in CYCLES:
        x = x0
        for k in range(count):
            name = names[k % len(names)]
            add(plane, dict(s=name, x=x, y=y, z=z, shade=shade), region)
            x += 192  # every tile in the cycles is 192 px wide
    for d in SKY:
        add("sky", d, "all")
    for d in FAR:
        add("far", d)
    for d in MID:
        add("mid", d)
    for d in WORLD:
        add("world", d, "gorge" if d["x"] < GATE_X0 else ("castle" if d["x"] < BACK_GATE_X else "valley"))
    for d in FG:
        add("fg", d)
    return out
