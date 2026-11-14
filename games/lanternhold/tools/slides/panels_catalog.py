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

def _strings():
    return [
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
     "Der Stirnreif ging an {den Letzten|die Letzte} seines Blutes.\n{An den, der|An die, die} abends die Lampen "
     "anzündet."),
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
    ("slides.position", "VoiceOver value of a story slide. %1$d is its number, %2$d how many there are.",
     "Slide %1$d of %2$d",
     "Bild %1$d von %2$d"),
    ("slides.end", "VoiceOver hint on the last slide of an ending: a tap shows the chapter's end card.",
     "Shows the chapter's end",
     "Zeigt das Ende des Kapitels"),
] + ENDINGS

# The three endings (panels-2; STORY.md section 7 "The endings"): three slides each, two short lines a slide. The first
# slide tells what happened, the second names the lord's leaning in one sentence (as the ending's mood says it) and on
# its second line the houses whose banners hung (or, in the Shuttered Lantern with Seren handed over, her lantern), the
# third is the first big hint. STORY.md's words, cut to two lines of at most 64 characters in English.
LEANINGS = ("openHand", "shutGate", "honestLamp")
ENDINGS = [
    ("slides.ending1.1", "The Open Lantern (the King slain, Aldric freed), slide 1 of 3: the iron crown on the stone, "
     "Aldric under the black mantle at first light.",
     "The iron crown rolled across the stone.\nUnder the mantle lay Aldric, grey, thin, and breathing.",
     "Die eiserne Krone rollte über den Stein.\nUnter dem Mantel lag Aldric, grau, mager, und er atmete."),
    ("slides.ending1.lean.openHand", "The Open Lantern, slide 2, line 1: the lord let people in (the open hand).",
     "You kept the gate open, and the valley came through it.",
     "Ihr hieltet das Tor offen, und das Tal kam herein."),
    ("slides.ending1.lean.shutGate", "The Open Lantern, slide 2, line 1: the lord took no risk (the shut gate).",
     "You kept the gate shut, and the town behind it slept.",
     "Ihr hieltet das Tor geschlossen, und die Stadt dahinter schlief."),
    ("slides.ending1.lean.honestLamp", "The Open Lantern, slide 2, line 1: the lord told the truth (the honest "
     "lamp).",
     "You told the town the truth, and it stood in the light.",
     "Ihr sagtet der Stadt die Wahrheit, und sie stand im Licht."),
    ("slides.ending1.3", "The Open Lantern, slide 3 of 3: west from the Throat's mouth at dawn, a ruined castle older "
     "than ours with the house's lantern cut over its gate. Aldric calls the lord cousin.",
     "Past the firs stood a ruined castle, our lantern on its gate.\n“They had the crown ready, cousin,” said "
     "Aldric.",
     "Hinter den Tannen lag eine Burgruine, unsere Laterne über dem Tor.\n„Sie hatten die Krone bereit, Vetter“, "
     "sagte Aldric."),
    ("slides.ending2.1", "The Shuttered Lantern (the King held off until dawn), slide 1 of 3: the King walks back "
     "into the fog with his snuffer.",
     "He did not fall. At first light he turned\nand walked back into the fog, and the snuffer went with him.",
     "Er fiel nicht. Im ersten Licht wandte er sich um\nund ging zurück in den Nebel, und das Löschhorn ging mit "
     "ihm."),
    ("slides.ending2.lean.openHand", "The Shuttered Lantern, slide 2, line 1: the open hand.",
     "You let them in, every one. The door held all the same.",
     "Ihr ließt sie alle herein. Die Tür hielt trotzdem."),
    ("slides.ending2.lean.shutGate", "The Shuttered Lantern, slide 2, line 1: the shut gate.",
     "You barred the gate and kept it barred. It held.",
     "Ihr verriegeltet das Tor und hieltet es verriegelt. Es hielt."),
    ("slides.ending2.lean.honestLamp", "The Shuttered Lantern, slide 2, line 1: the honest lamp.",
     "You told them what was coming. They stayed anyway.",
     "Ihr sagtet ihnen, was kommt. Sie blieben trotzdem."),
    ("slides.ending2.3", "The Shuttered Lantern, slide 3 of 3: Bram washes the herald's banner; under the soot the "
     "old arms in gold thread, the house's lantern under half a sun.",
     "Bram washed the herald's banner. Under the soot, gold thread:\nour lantern beneath half a sun. Nobody knew "
     "who had sewn it.",
     "Bram wusch das Banner des Herolds. Unter dem Ruß: Goldfaden,\nunsere Laterne unter halber Sonne. Niemand "
     "wusste, wer sie stickte."),
    ("slides.seren.lantern", "The Shuttered Lantern, slide 2, line 2, when Seren was handed over to the herald: her "
     "grey lantern stayed on the wall.",
     "Seren's grey lantern stood on the wall, still burning.",
     "Serens graue Laterne stand auf der Mauer und brannte noch."),
    ("slides.ending3.1", "The Guttering Lantern (the town unhappy), slide 1 of 3: Tallowford in winter, half its "
     "windows dark because people left.",
     "The door held. Half the windows of Tallowford\nstayed dark that winter, and not for the dead.",
     "Die Tür hielt. Die Hälfte der Fenster von Tallowford\nblieb in jenem Winter dunkel, und nicht wegen der "
     "Toten."),
    ("slides.ending3.lean.openHand", "The Guttering Lantern, slide 2, line 1: the open hand.",
     "You opened the gate to all, and the bread ran short.",
     "Ihr öffnetet das Tor für alle, und das Brot wurde knapp."),
    ("slides.ending3.lean.shutGate", "The Guttering Lantern, slide 2, line 1: the shut gate.",
     "You kept the gate shut. The town learned to shut its doors.",
     "Ihr hieltet das Tor zu. Die Stadt lernte, ihre Türen zu schließen."),
    ("slides.ending3.lean.honestLamp", "The Guttering Lantern, slide 2, line 1: the honest lamp.",
     "You told them the truth. It was more than they could carry.",
     "Ihr sagtet ihnen die Wahrheit. Sie war mehr, als sie tragen konnten."),
    ("slides.ending3.3", "The Guttering Lantern, slide 3 of 3: among the creatures' rags a small coat in the house's "
     "teal, of an old weave; Tamsin folds it. Quiet: never say what it means.",
     "Among the rags lay a child's coat in our teal.\nNo loom here wove it. Tamsin folded it and said nothing.",
     "Unter den Lumpen lag ein Kindermantel in unserem Blaugrün.\nKein Webstuhl hier hat ihn gewebt. Tamsin "
     "faltete ihn und schwieg."),
    ("slides.houses.some", "An ending's slide 2, line 2: the houses whose banners hung in the hall. %@ is their names "
     "joined as a list (never translated: Varn, Brine, Oxmoor, Calder, Lorn).",
     "The banners of %@ hung in our hall.",
     "Die Banner von %@ hingen in unserem Saal."),
    ("slides.houses.all", "An ending's slide 2, line 2: all five houses' banners hung.",
     "The banners of all five houses hung in our hall.",
     "Die Banner aller fünf Häuser hingen in unserem Saal."),
    ("slides.houses.few", "An ending's slide 2, line 2: banners were hung, but no house stood with the realm.",
     "A few banners hung in our hall. No house rode to us.",
     "Ein paar Banner hingen im Saal. Kein Haus ritt zu uns."),
    ("slides.houses.alone", "An ending's slide 2, line 2: the lord hung no house's banner.",
     "No banner hung in our hall but our own.",
     "In unserem Saal hing kein Banner außer unserem."),
    # The chapter's end card (a page of the house chronicle).
    ("end.name.ending1", "The end card's title: the ending's name (was The Bright Crown).",
     "The Open Lantern", "Die offene Laterne"),
    ("end.name.ending2", "The end card's title: the ending's name (was The Iron Crown).",
     "The Shuttered Lantern", "Die verschlossene Laterne"),
    ("end.name.ending3", "The end card's title: the ending's name (was The Ash Crown).",
     "The Guttering Lantern", "Die verlöschende Laterne"),
    ("end.leaning.openHand", "The end card: the name of the lord's way (lets people in).",
     "The Open Hand", "Die offene Hand"),
    ("end.leaning.shutGate", "The end card: the name of the lord's way (takes no risk).",
     "The Shut Gate", "Das verschlossene Tor"),
    ("end.leaning.honestLamp", "The end card: the name of the lord's way (tells the truth).",
     "The Honest Lamp", "Die ehrliche Lampe"),
    ("end.lord", "The end card's first line: the lord's name. {lord} is the typed name; {a|b}: Burgherr | "
     "Burgherrin.",
     "{lord}, {Lord|Lady} Lantern", "{Burgherr|Burgherrin} {lord}"),
    ("end.chapter", "The end card's first line, after the lord's name: the chapter that ended.",
     "Chapter 1, The Dark Beacon", "Kapitel 1, Das dunkle Leuchtfeuer"),
    ("end.nights", "The end card's ledger: nights the realm held.", "Nights held", "Gehaltene Nächte"),
    ("end.judgments", "The end card's ledger: petitions heard and judged.", "Judgments spoken",
     "Gesprochene Urteile"),
    ("end.fallen", "The end card's ledger: soldiers fallen in this realm.", "Fallen on the walls",
     "Gefallen auf den Mauern"),
    ("end.way", "The end card's ledger: the lord's leaning, by its name.", "Your way", "Euer Weg"),
    ("end.stood", "The end card: heading over the houses' banners (who stood with the realm).", "Stood by you",
     "An Eurer Seite"),
    ("end.alone", "The end card, under 'Stood by you', when no house stood with the realm.",
     "House Lantern alone", "Haus Lantern allein"),
    ("end.begin", "The end card's quiet button (it asks first): a new realm from day 1.", "Begin again",
     "Neu beginnen"),
    ("end.begin.ask", "The end card, after 'Begin again' was tapped once: the question.", "Begin a new realm?",
     "Ein neues Reich beginnen?"),
    ("end.begin.ends", "The end card, under the question: what a new realm means.",
     "This realm ends here. The Chronicle keeps its records.",
     "Dieses Reich endet hier. Die Chronik bewahrt seine Taten."),
    ("end.cancel", "The end card's question: keep this realm (the main button).", "Cancel", "Abbrechen"),
    ("end.begin.hint", "VoiceOver hint of 'Begin again'.", "A new realm from the first day.",
     "Ein neues Reich vom ersten Tag an."),
    ("end.hold", "The end card's main button: this realm goes on in the endless Long Watch.", "Hold the realm",
     "Das Reich halten"),
    ("end.hold.hint", "VoiceOver hint of 'Hold the realm'.", "This realm goes on into the Long Watch, from night 21.",
     "Dieses Reich geht weiter in die Lange Wacht, ab Nacht 21."),
]


def unit(value):
    return {"stringUnit": {"state": "translated", "value": value}}


def main():
    strings = {}
    for key, comment, en, de in sorted(_strings()):
        strings[key] = {"comment": comment, "extractionState": "manual",
                        "localizations": {"de": unit(de), "en": unit(en)}}
    catalog = {"sourceLanguage": "en", "strings": strings, "version": "1.0"}
    text = json.dumps(catalog, ensure_ascii=False, indent=2, separators=(",", " : "), sort_keys=True)
    with open(OUT, "w", encoding="utf-8") as f:
        f.write(text + "\n")
    print(OUT, len(strings), "keys")


if __name__ == "__main__":
    main()
