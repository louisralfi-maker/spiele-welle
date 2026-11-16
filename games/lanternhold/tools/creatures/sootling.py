"""Sootling, the walker (POLISH.md section 7, build 3; step 7, the director's calls of 16.11.2026 11:43 and 12:02): the
Ash Giant's child, lifted from the design card of step 6B (ci-out/director/b3/horde/s6b/kin2.py `WALKER`): a hunched
shroud on two stilt arms one pixel wide, no hind legs, the hem dragging behind, open air under the belly, the head hung
low in front with one cold eye point, a torn patch of ochre cloth on the hump. Walk 0 ... 5 (reach, plant, haul, over,
drop, gather), 6 the climb, 7 the strike (hordekit.py `kin`, `LEGEND`)."""
from hordekit import kin

SIZE = (14, 14, 8)
HEIGHT = 13
WALKER = dict(
    # the hump: the top of the hunched shroud, its front at the right; the ochre cloth a torn patch over the hump's top
    # and down its back (10 px, mostly soilLight so it reads on the mist), its back a slope down to the left like the giant's cloak. Under it the skirt (`skirt`) slants down and back to the hem on the ground.
    hump=["...OO",
          "..OOo",
          ".OoSS",
          ".OsBS",
          "oDBBB"],
    # the skirt under the hump, row by row from the hump's foot to the ground: (left, right) block columns. Its front
    # edge steps back as it falls, so the hem trails behind and the underside rises to the shoulder: the inverted V.
    skirt=[(0, 3), (0, 2), (0, 2), (0, 1)],              # the last pair repeats down to the ground
    head=["SB",
          "BE"],
    head_at=(5, 4),             # in front of the shroud, its top 4 rows under the hump's top
    shoulder=(5, 3),            # the arms' root: the front of the hump, over the head
    seed=7,
    poses=[
        # 0 reach: low, both arms thrown forward, the near hand still in the air, the far one planted
        dict(at=(3, 3), near=[(10, 7), (11, 12)], far=[(9, 9), (9, 13)]),
        # 1 plant: low, both hands down ahead, a slit of air between the arms
        dict(at=(3, 3), near=[(10, 7), (11, 13)], far=[(9, 9), (9, 13)]),
        # 2 haul: the body hauled up toward the planted hands, rising; the hem drags a frame behind
        dict(at=(4, 2), near=[(12, 6), (12, 13)], far=[(10, 8), (10, 13)]),
        # 3 over: the hump at its highest, the arms upright under the head's front
        dict(at=(4, 1), near=[(12, 5), (12, 13)], far=[(10, 7), (10, 13)]),
        # 4 drop: coming down forward, the near arm lifted and swinging forward, the far arm slanting back
        dict(at=(4, 2), near=[(12, 6), (13, 10)], far=[(10, 9), (9, 13)]),
        # 5 gather: low, the near arm swung forward in the air, the far arm about to lift
        dict(at=(3, 3), near=[(10, 7), (12, 12)], far=[(9, 10), (9, 13)]),
        # 6 climb: the arms up the wall ahead, the hands hooked over its top, the shroud hanging below
        dict(at=(4, 2), near=[(13, 4), (13, 0)], far=[(11, 6), (11, 1)], hook=True),
        # 7 strike: reared, both arms flung up overhead to the cell's top row, splayed, the hands open
        dict(at=(4, 2), near=[(12, 4), (13, 0)], far=[(11, 5), (10, 0)], strike=True),
    ],
)


def frame(k):
    return kin(WALKER, k)
