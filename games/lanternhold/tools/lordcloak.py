#!/usr/bin/env python3
"""Writes the lord's mended cloak (the director's note of 14.11.2026 14:35; docs/PEOPLE.md section 7, docs/lanes/
people.md "people-2 fix round 1") as four grids in tools/grids/people/: kingMended, ladyMended, kingSeatedMended and
ladySeatedMended. Each takes its body's legend and parts (include) and replaces only the parts that carry the cloak,
with the cloak's pixels mended: the house's teal faded past the town's old house colour to a washed-out blue-grey
(`banner` to `far`, `roofLight` to `moon`; the director's fix pass of 15.11.: one step further than `waterDeep`, so
mended and good read apart at a glance), a patch of grey wool on the back (`stoneLight` lit, `stone` shaded, with a
brown stitch across it), and a darned tear in brown thread (`soilLight`). Face, hands, tunic, circlet, lantern and alpha are the body's to the pixel: wealth changes the cloth,
never the people. The glow entries become plain body colours, so no glow strip is written (the engine keeps the
body's: `kingGlow`, `ladyGlow`, `kingSeatedGlow`, `ladySeatedGlow`, whose pixels are the lantern's and the circlet's).
The frames are copied from the body's grid, so run this again whenever those change. The sheets as painted are the
good cloak of the town stage. Pure text, no image: python3 -I tools/lordcloak.py"""
import os
import re

HERE = os.path.dirname(os.path.abspath(__file__))
ACTORS = os.path.join(HERE, "grids", "actors")
PEOPLE = os.path.join(HERE, "grids", "people")

LEGEND = """legend
    J = strawLight
    Y = strawLight
    Z = parchment
    U = far
    u = moon
    X = stoneLight
    x = stone
    y = soilLight
"""

# The king's trunk: the faded cloak (legend), the patch on the back under the belt, the darn further down.
KING_BODY = """# the trunk with the mended cloak: the teal faded (legend), a patch of grey wool on the back under the belt (lit at
# its upper left, shaded at its lower right, a brown stitch across it), a darned tear lower down in brown thread
part body
    ...uUUTQR
    ..uUTTGQR
    ..UTtTQRR
    ..UTtTRRR
    ..UTtTRRr
    ..UTtTRRr
    .UUTtTHGH
    .XXxtTRRR
    .XyxTTRRr
    .UTtTTRrR
    UUTtT....
    UTytT....
    UTTyT....
    UTtTT....
"""

# The lady's trunk: the same mending; the plait hangs over cols 3-4 above the belt, so the patch and the darn sit
# below it, where the cloak shows.
LADY_BODY = """# the trunk with the mended cloak (below the plait): the teal faded, the patch under the belt, the darned tear
part body
    ....uUTQR.
    ...uUTGQR.
    ..UUTtRRR.
    ..UTtTRRr.
    ..UTtTRR..
    ..UTtTRR..
    .UUTtTHGH.
    .XXxtTRRR.
    .XyxTTRRRr
    .UTtTQRRRr
    UUTtTQRRrR
    UTytTRRRRr
    UTTyTRrRRr
    UTtTT.....
"""

# The seated king: the cloak pressed narrow between his back and the throne (cols 4-5): the faded mantle, a one-pixel
# patch pair, the darn by the seat.
KING_SIT = """# the seated trunk with the mended cloak: the teal faded, the patch on the narrow cloak, the darn by the seat
part bodySit
    ....uUTQR
    ....UTGQR
    ....UTQRR
    ....UTRRR
    ....XxRRr
    ....xxRRr
    ....UTHGH
    ....UTRRR
    ...UTyRRr
    ...TtTTrr
    ....tT...
"""

# The seated lady: the plait covers col 4 down to the belt, so the patch sits on col 5 below it.
LADY_SIT = """# the seated trunk with the mended cloak (the plait over col 4): the teal faded, the patch below the plait, the darn
part bodySit
    ....uUTQR
    ....UTGQR
    ....UTRRR
    ....UTRRr
    ....UTRR.
    ....UTRR.
    ....UTHGH
    ....UXRRR
    ...UxxRRR
    ...TyTQRR
    ....tT...
"""

SHEETS = [
    ("kingMended", "king", "16x30", 10, ["../actors/king.txt"], [KING_BODY]),
    ("ladyMended", "lady", "16x30", 10, ["../actors/king.txt", "../actors/lady.txt"], [LADY_BODY]),
    ("kingSeatedMended", "kingSeated", "16x30", 4, ["../actors/king.txt", "../actors/kingSeated.txt"],
     [KING_BODY, KING_SIT]),
    ("ladySeatedMended", "ladySeated", "16x30", 4,
     ["../actors/king.txt", "../actors/lady.txt", "../actors/kingSeated.txt", "../actors/ladySeated.txt"],
     [LADY_BODY, LADY_SIT]),
]


def frames_of(name):
    """The frame placements of a body's grid, verbatim."""
    out, keep = [], False
    for line in open(os.path.join(ACTORS, name + ".txt")).read().splitlines():
        if line and not line[0].isspace() and not line.startswith("#"):
            keep = line.startswith("frame")
        if keep and line.strip():
            out.append(line)
            if re.match(r"frame \d+ = \d+", line):
                keep = False
    return "\n".join(out) + "\n"


def main():
    for sid, body, size, n, includes, parts in SHEETS:
        text = (f"# {sid} {size}, {n} frames: `{body}` frame for frame in the mended cloak of the hamlet and the village\n"
                f"# (written by tools/lordcloak.py; docs/SPRITES-people.md \"The lord's cloak\"). Only cloak pixels differ\n"
                f"# from `{body}`; no glow strip (the engine draws `{body}Glow`).\n"
                f"id {sid}\nsize {size}\nframes {n}\noutline ink shade\n")
        text += "".join(f"include {inc}\n" for inc in includes)
        text += "\n" + LEGEND + "\n" + "\n".join(parts) + "\n" + frames_of(body)
        with open(os.path.join(PEOPLE, sid + ".txt"), "w") as fh:
            fh.write(text)
        print(f"wrote tools/grids/people/{sid}.txt")


if __name__ == "__main__":
    main()
