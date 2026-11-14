#!/usr/bin/env python3
"""Writes Resources/Panels.xcstrings, the panels lane's string catalog (docs/lanes/panels.md), in Xcode's own layout.

The prologue's four texts are STORY.md section 8, word for word (Story.xcstrings had none of them); German follows
STORY.md's fixed names (die Weltmauer, Haus Lantern, das Große Leuchtfeuer, der Stirnreif, Burgherr Aldric) and its
"{a|b}" form for Burgherr and Burgherrin. Run: python3 tools/slides/panels_catalog.py (from games/lanternhold).
The six other languages join in one pass after the lanes are joined.
"""
import json
import os

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "..", "Resources", "Panels.xcstrings")

STRINGS = [
    ("slides.prologue.1", "Prologue, slide 1 of 4 (two short lines, split by the line break): the Worldwall from far "
     "off at dusk, one cleft with a small castle in it.",
     "A wall of mountains parts the world.\nIt has one door.",
     "Eine Mauer aus Bergen teilt die Welt.\nSie hat nur eine Tür."),
    ("slides.prologue.2", "Prologue, slide 2 of 4: from the castle wall, looking west into the Throat; fog with cold "
     "eyes at its far end. 'it' is the door.",
     "For a thousand years House Lantern has held it.\nNobody knows what waits on the other side.",
     "Seit tausend Jahren hält Haus Lantern sie.\nNiemand weiß, was auf der anderen Seite wartet."),
    ("slides.prologue.3", "Prologue, slide 3 of 4: the dark beacon at the Throat's mouth, Lord Aldric riding out "
     "with twelve lights.",
     "This autumn the Great Beacon went dark.\nLord Aldric rode out to light it. He did not come back.",
     "In diesem Herbst erlosch das Große Leuchtfeuer.\nBurgherr Aldric ritt aus, um es zu entzünden. Er kam nicht "
     "zurück."),
    ("slides.prologue.4", "Prologue, slide 4 of 4: the warm hall, the young lamplighter with the circlet. {a|b}: "
     "Burgherr | Burgherrin.",
     "The circlet passed to the last of his blood.\nThe one who lights the lamps.",
     "Der Stirnreif ging an {den Letzten|die Letzte} seines Blutes.\n{An den, der|An die, die} die Lampen anzündet."),
    ("slides.prologue.4.label", "The paper label on the last prologue slide: the name Odile wrote into the family "
     "book. {lord} is the typed name (up to 16 letters); {a|b}: Burgherr | Burgherrin.",
     "{lord}, {Lord|Lady} Lantern",
     "{Burgherr|Burgherrin} {lord}"),
    ("slides.skip", "The small button in the corner of the story slides that ends them at once.",
     "Skip",
     "Überspringen"),
    ("slides.next", "VoiceOver hint on a story slide: a tap shows the next slide.",
     "Next slide",
     "Nächstes Bild"),
    ("slides.begin", "VoiceOver hint on the last story slide: a tap ends the slides and the day begins.",
     "Begins the day",
     "Beginnt den Tag"),
    ("slides.position", "VoiceOver value of a story slide. {n} is its number, {count} how many there are.",
     "Slide {n} of {count}",
     "Bild {n} von {count}"),
]


def unit(value):
    return {"stringUnit": {"state": "translated", "value": value}}


def main():
    strings = {}
    for key, comment, en, de in sorted(STRINGS):
        strings[key] = {"comment": comment, "extractionState": "manual",
                        "localizations": {"de": unit(de), "en": unit(en)}}
    catalog = {"sourceLanguage": "en", "strings": strings, "version": "1.0"}
    text = json.dumps(catalog, ensure_ascii=False, indent=2, separators=(",", " : "), sort_keys=True)
    with open(OUT, "w", encoding="utf-8") as f:
        f.write(text + "\n")
    print(OUT, len(strings), "keys")


if __name__ == "__main__":
    main()
