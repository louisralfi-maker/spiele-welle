"""Sootling, the walker (POLISH.md section 7, build 3; step 7, the director's calls of 16.11.2026 11:43 and 12:02): the
Ash Giant's child, his silhouette at a hand's height. A hunched shroud taller than wide that lopes on two stilt arms,
each a single pixel wide, from the shoulder at the front of the hump forward and down to the ground; no hind legs: the
shroud's frayed navy hem drags behind on the ground, and between the hem and the nearest arm the ground shows under the
belly, the giant's inverted V. The head, three pixels wide, hangs low in front of the shoulder, its top four rows under
the hump's top, with one cold eye point, never two, never a face. Over the hump the giant's cloth in his two tones
(soilDark, moorDark) in stripes that run down its back, the topmost pixels catching the moon (moor); 16 pixels of it.
The gait is a haul with a bob: reach, plant, haul, over (the hump at its highest, the arms upright under it), drop,
gather; the hump's top rises and falls two pixels, the hem lags a frame behind. 6 the climb: the arms up the wall
ahead, the hands hooked over its top, the shroud hanging. 7 the strike: reared, both arms flung up overhead. 13 px tall
at the top of the walk (hordekit.py `kin`, `LEGEND`)."""
from hordekit import kin

SIZE = (14, 14, 8)
HEIGHT = 13
WALKER = dict(
    # the hump: its top catches the moon (m), the giant's cloth in stripes running down its back (s soilDark, r
    # moorDark), the front two columns the navy shoulder and chest
    hump=["...mm.",
          "..msSS",
          ".msrSB",
          ".ssrBB",
          "msrBBB"],
    # the skirt under the hump, row by row to the ground: its front edge steps back as it falls, so the hem trails
    # behind and the underside rises toward the shoulder (the last pair repeats down to the ground); the cloth runs on
    # two rows down the back, then the hem is navy
    skirt=[(0, 3, "sr"), (0, 2, "s"), (0, 1), (-1, 1), (-1, 0)],
    # the head hangs from the front of the hump, three wide at the neck, the face and its eye below
    head=["SSB",
          ".BE"],
    head_at=(5, 4),             # its top four rows under the hump's top
    shoulder=(5, 2),            # the arms' root at the front of the hump
    seed=7,
    poses=[
        # 0 reach: low, the near arm thrown forward, its hand still in the air, the far one planted
        dict(at=(2, 3), near=[(10, 8), (10, 12)], far=[(8, 9), (8, 13)]),
        # 1 plant: low, both hands down ahead, air between the arms
        dict(at=(2, 3), near=[(10, 9), (10, 13)], far=[(8, 9), (8, 13)]),
        # 2 haul: the body hauled up toward the planted hands, rising
        dict(at=(3, 2), near=[(11, 7), (11, 13)], far=[(9, 8), (9, 13)]),
        # 3 over: the hump at its highest, the arms upright under the head
        dict(at=(3, 1), near=[(11, 6), (11, 13)], far=[(9, 6), (9, 13)]),
        # 4 drop: coming down forward, the near arm lifted and swinging forward, the far arm slanting back
        dict(at=(3, 2), near=[(11, 7), (11, 11)], far=[(9, 8), (9, 13)]),
        # 5 gather: low, the near arm swung forward in the air, the far arm about to lift
        dict(at=(2, 3), near=[(10, 9), (10, 12)], far=[(8, 10), (8, 13)]),
        # 6 climb: the shroud hanging low, the arms reaching forward and up onto the wall ahead, the near hand at the
        # height of the hump, the far one under it (never a stick over its back)
        dict(at=(3, 3), near=[(11, 3), (12, 2)], far=[(10, 4), (12, 4)]),
        # 7 strike: reared to the cell's full height, both arms flung up and forward over the head, the near one further
        dict(at=(3, 1), near=[(10, 1), (12, 0)], far=[(9, 1), (10, 0)]),
    ],
)


def frame(k):
    return kin(WALKER, k)
