#!/usr/bin/env python3
"""Writes the court's ties (the director's note of 14.11.2026 15:03; docs/HOUSE.md section 2: "they have ties among
each other ... an object that changes hands") as eight grids in tools/grids/people/: <member>Tie.txt, one idle of two
frames per court member that is played toward another person (the engine mirrors it to face them). Frame 0: a nod to
the other (the head dipped a pixel). Frame 1: the thread itself, mostly something handed over: Odile the ledger she
taught the lord, Brannock the key of the wall stair, Pip a juggling ball, Tamsin a bowl of supper, Bram the clasp he
mended overnight, Marek the first orange of winter, Seren a coin (her house's debt); Mother Hesper nods with her hand on
her heart (to the lamplighter at the hearth, docs/HOUSE.md section 6). Each takes its member's legend and parts
(include) and the placements of the member's idle (frame 4) or talk-forward frame (7), so the body, its size, its
outline and its feet are the member's; only the head's dip, the giving arm and the small object are new. Hesper's and
Seren's grids keep their glow (the staff's flame, the grey lantern), so they write a glow strip too. The frames follow
the members' grids: run this again whenever those change. Pure text, no image: python3 -I tools/courtties.py"""
import os

HERE = os.path.dirname(os.path.abspath(__file__))
PEOPLE = os.path.join(HERE, "grids", "people")

# member: (size, extra legend lines, extra parts, frame 0 placements, frame 1 placements, what it is)
TIES = {
    "odile": ("14x30", ["@ = woodLight", "% = wood"],
              {"ledger": ["@@%", "%%%"]},
              ["feetTogether 6 28", "skirtPass 3 17", "torso 4 9", "head 2 3", "armLedger 6 10", "chain 4 9"],
              ["feetTogether 6 28", "skirtPass 3 17", "torso 4 9", "head 2 3", "armUpper 6 10", "chain 4 9",
               "forearmPalm 8 12", "ledger 10 10"],
              "a nod, then the ledger held out on her palm"),
    "brannock": ("16x30", ["@ = stoneLight", "% = stoneMid"],
                 {"key": ["@@", ".%"]},
                 ["scabbard 1 17", "legsStand 3 16", "skirt 5 17", "torso 4 9", "head 5 3", "hilt 11 14",
                  "armPommel 8 10"],
                 ["scabbard 1 17", "legsStand 3 16", "skirt 5 17", "torso 4 9", "head 5 3", "hilt 11 14",
                  "armThrust 8 10", "key 14 11"],
                 "a curt nod, then the iron key of the wall stair held out"),
    "pip": ("12x22", [],
            {"armOffer": ["TT.", "..S"]},
            ["legsStand 2 17", "tunic 3 12", "ruff 3 11", "head 1 6", "armDown 5 12"],
            ["legsStand 2 17", "tunic 3 12", "ruff 3 11", "head 1 6", "armOffer 6 12", "ballGold 9 12"],
            "a bob of the head, then a juggling ball held out"),
    "hesper": ("14x30", [],
               {},
               ["feetTogether 5 28", "lowerPass 2 18", "upper 2 11", "head 2 6", "staff 11 12", "flame0 11 9"],
               ["feetTogether 5 28", "lowerPass 2 18", "upperHeart 2 11", "head 2 6", "staff 11 12", "flame3 11 9"],
               "a nod, then the nod held with her hand on her heart"),
    "tamsin": ("14x28", ["@ = woodLight", "% = wood"],
               {"armBowl": ["R.@@@", "RS%%."]},
               ["feetTogether 6 26", "skirtPass 3 15", "armBack 3 10", "bodice 4 9", "head 3 4", "armLadle 9 10"],
               ["feetTogether 6 26", "skirtPass 3 15", "armBack 3 10", "bodice 4 9", "head 3 4", "armBowl 9 10"],
               "a nod, then a bowl of supper held out"),
    "bram": ("16x30", ["@ = gold"],
             {"armGive": ["SS...", "SsSS@"]},
             ["armFarDown 4 10", "legsStand 4 16", "apron 5 17", "torso 4 9", "head 6 3", "hammer 2 7", "armBent 9 10"],
             ["armFarDown 4 10", "legsStand 4 16", "apron 5 17", "torso 4 9", "head 6 3", "hammer 2 7", "armGive 9 10"],
             "a nod, then the mended clasp held out between finger and thumb"),
    "marek": ("14x30", ["@ = gold", "% = tileLight"],
              {"orange": ["@@", "@%"]},
              ["legsStand 2 16", "skirtPass 3 17", "torso 4 9", "satchel 1 9", "head 2 3", "armStrap 7 10"],
              ["legsStand 2 16", "skirtPass 3 17", "torso 4 9", "satchel 1 9", "head 2 3", "armPalm 7 10",
               "orange 10 9"],
              "a merchant's nod, then the first orange of winter on his palm"),
    "seren": ("14x30", ["@ = gold", "% = straw"],
              {"coin": ["@%"]},
              ["skirtStand 2 18", "feetStand 3 28", "cloakTop 3 11", "hood 3 5", "armLantern 7 12"],
              ["skirtStand 2 18", "feetStand 3 28", "cloakTop 3 11", "hood 3 5", "armLantern 7 12", "handOpen 9 14",
               "coin 11 13"],
              "a cool nod, then a coin of her house's debt on her open hand"),
}


TRUNKS = ("torso", "upper", "upperHeart", "bodice", "cloakTop", "tunic")


def dipped(placements):
    """The nod: the head (or the hood) placed under the trunk, so its lowest row (the neck) goes under the collar and
    the face sits a pixel lower: the chin dips, the shoulders stay."""
    head = [p for p in placements if p.split()[0] in ("head", "hood")]
    rest = [p for p in placements if p.split()[0] not in ("head", "hood")]
    at = next((i for i, p in enumerate(rest) if p.split()[0] in TRUNKS), 0)
    return rest[:at] + head + rest[at:]


def main():
    for member, (size, legend, parts, f0, f1, what) in TIES.items():
        f0, f1 = dipped(f0), dipped(f1)
        sid = member + "Tie"
        text = (f"# {sid} {size}, 2 frames: {member}'s tie, played toward another person: {what} (written by\n"
                f"# tools/courtties.py; docs/SPRITES-people.md \"The court's ties\"). The member's own parts and placements.\n"
                f"id {sid}\nsize {size}\nframes 2\noutline ink shade\ninclude ../court/kit.txt\n"
                f"include ../court/{member}.txt\n")
        if legend:
            text += "\nlegend\n" + "".join(f"    {line}\n" for line in legend)
        for name, rows in parts.items():
            text += f"\npart {name}\n" + "".join(f"    {r}\n" for r in rows)
        text += "\nframe 0\n" + "".join(f"    {p}\n" for p in f0)
        text += "\nframe 1\n" + "".join(f"    {p}\n" for p in f1)
        with open(os.path.join(PEOPLE, sid + ".txt"), "w") as fh:
            fh.write(text)
        print(f"wrote tools/grids/people/{sid}.txt")


if __name__ == "__main__":
    main()
