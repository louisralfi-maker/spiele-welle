"""Sootling B, the runt (POLISH.md section 7, build 3; step 7, the director's calls of 16.11.2026 11:43 and 12:02): the
walker's smaller sibling at 10 px, lifted from the design card of step 6B (ci-out/director/b3/horde/s6b/kin2.py
`RUNT`). The same eight frames (hordekit.py `kin`, `LEGEND`)."""
from hordekit import kin

SIZE = (14, 14, 8)
HEIGHT = 10
RUNT = dict(
    # the same construction at 10 px: a smaller hunched shroud, no cloth on the hump, an ochre scrap at the neck (3 px)
    hump=["..BB",
          ".DBO",
          "DBBO",
          "DBo."],
    skirt=[(0, 1), (0, 0)],
    head=["SB",
          "BE"],
    head_at=(4, 2),
    shoulder=(3, 1),
    seed=5,
    poses=[
        dict(at=(4, 5), near=[(10, 7), (10, 12)], far=[(8, 9), (8, 13)]),        # 0 reach
        dict(at=(4, 5), near=[(10, 7), (10, 13)], far=[(8, 9), (8, 13)]),        # 1 plant
        dict(at=(4, 4), near=[(10, 6), (10, 13)], far=[(8, 8), (8, 13)]),        # 2 haul
        dict(at=(4, 4), near=[(10, 5), (10, 13)], far=[(8, 8), (8, 13)]),        # 3 over
        dict(at=(4, 4), near=[(10, 6), (10, 10)], far=[(8, 9), (8, 13)]),        # 4 drop
        dict(at=(4, 5), near=[(10, 7), (10, 11)], far=[(8, 10), (8, 13)]),       # 5 gather
        dict(at=(4, 4), near=[(10, 4), (10, 0)], far=[(9, 6), (9, 1)], hook=True),           # 6 climb
        dict(at=(4, 4), near=[(10, 4), (10, 0)], far=[(9, 5), (8, 0)], strike=True),         # 7 strike
    ],
)


def frame(k):
    return kin(RUNT, k)
