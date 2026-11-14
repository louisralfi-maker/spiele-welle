# Lanternhold: App-Store-Eintrag, Deutsch (de-DE)

Entwurf für den Director (Store-Lane, Schritt store-1, 14.11.2026). Was in den `text`-Blöcken steht, kommt so in App
Store Connect. Zeilen mit `[if shipped]` am Anfang beschreiben Teile, die noch nicht im Build sind: die ganze Zeile
streichen oder nur die Marke löschen, sobald der Teil drin ist. Nie eine Marke einfügen.
`python3 games/lanternhold/store/tools/check_listing.py de` zählt alle Grenzen. Gilt auch für de-AT und de-CH (dort
ohne ß schreiben, falls ein eigener Eintrag gewünscht ist).

## Name

```text
Lanternhold
```

## Subtitle

```text
Burg bauen, Nacht überstehen
```

## Promotional text

```text
Zwanzig Nächte, um die einzige Lücke in der Weltmauer zu halten. Baue bei Tag, sprich Recht vom Thron und lass die Feuer brennen: Nur Licht hält die Düsternis fern.
```

## Description

```text
Halte die einzige Lücke in einer Mauer aus Bergen gegen die Düsternis: hohe Gestalten aus Rauch, die vor Licht zurückweichen.
Bei Tag baust du Mauern, Türme und Feuer, sprichst Recht über die Bitten deines Volkes und hältst deine Stadt bei Laune.
Bei Nacht tobt die Schlacht von selbst, und nur was du gebaut und entzündet hast, steht zwischen der Finsternis und deinem Herdfeuer.

DER LETZTE LATERNENANZÜNDER
Seit tausend Jahren hält Haus Lantern den Spalt, den einzigen Weg durch die Weltmauer. In diesem Herbst ist das Große Leuchtfeuer erloschen. Burgherr Aldric ritt hinaus, um es neu zu entzünden, und kam nie zurück. Der Stirnreif fiel an den jungen Laternenanzünder der Burg: an dich. Gib deinem Burgherrn oder deiner Burgherrin einen Namen, nimm die Laternenstange mit dem Haken und halte das Licht am Brennen.

BEI TAG: BAUEN UND RICHTEN
• Errichte Mauern, Tore, Türme und Feuerschalen in der Schlucht, hebe Pfahlgruben aus, stelle eine Balliste und ein Katapult auf.
• Wirb Bogenschützen und Wachen an. Lass die Stadt im Tal wachsen: Häuser, Felder, ein Markt und eine Schenke.
• Betritt deinen großen Saal, setz dich auf den Thron und hör dein Volk an: Bauern, Soldaten, Händler, einen Barden, einen Ritter, der jedes Wort ernst meint, Gesandte der anderen großen Häuser. Jede Entscheidung kostet oder bringt Gold und bewegt die Stimmung im Volk, und manche verändern die Welt, durch die du gehst.
• Lege die Steuern fest. Eine zufriedene Stadt zahlt und wächst. Eine unzufriedene murrt.
• Sprich mit deinem Hof: einer trockenen Kanzlerin, einem knurrigen Hauptmann, einem Narren, der die Wahrheit als Witz verpackt, einer Köchin, die jedes Gerücht kennt, und einer Fremden mit einer grauen Laterne.
[if shipped] • Ein Buch neben dem Thron hält deine Urteile fest und was aus ihnen wurde.

BEI NACHT: STANDHALTEN
• Licht ist das Gesetz der Schlacht. Im Dunkeln sind die Wesen unsichtbar und schnell. Im Licht werden sie langsam, deine Bogenschützen sehen sie, und die kleinen verbrennen.
• Brandpfeile ziehen Spuren durch die Nacht, Feuerschalen werfen Inseln aus Licht, Mauern bekommen Risse und halten.
• Sieben Arten von Wesen, von wimmelnden Rußlingen und springenden Schattenhunden bis zum Aschenriesen.
• Geh mit deiner Laterne die Mauern ab, flicke eine beschädigte Mauer, entzünde eine Feuerschale neu, die Krähen gelöscht haben.
[if shipped] • Heb deine Laterne hoch, und was ihr Licht trifft, weicht zurück ins Dunkel.
• Erreichen sie das Herdfeuer in deinem großen Saal, fällt das Reich.

ZWANZIG NÄCHTE
Kapitel 1 dauert zwanzig Nächte, mit über 80 Bittgesuchen und einem Hof, der eigene Geheimnisse hat. Baue das Große Leuchtfeuer wieder auf: Nur in seinem Licht ist der Lichtlose König verwundbar.
[if shipped] Drei Enden, erzählt in Laternenbildern, hängen an der letzten Nacht, an der Stimmung deines Volkes und an einer schweren Entscheidung.
[if shipped] Nach dem Kapitel geht dein Reich weiter, Nacht für Nacht ohne Ende.
[if shipped] Am Laternentisch in der Kapelle schickst du Reiter, Kundschafter und Gesandte mit nummerierten Laternen hinaus. Nicht jede Laterne kommt heim.

• Pixelkunst unter weichem, lebendigem Licht: warmes Feuer gegen kalte blaue Nächte, Nebel, Regen und Funken
• Ein Tag und eine Nacht dauern etwa fünf Minuten, gespeichert wird bei jedem Morgengrauen
• Nur Soundeffekte und Vibration, keine Musik: Deine eigene Musik kann nebenher laufen
• Kein Konto, keine In-App-Käufe
[if shipped] • Auf Deutsch, Englisch, Französisch, Spanisch, Italienisch, Portugiesisch, Japanisch und Chinesisch
```

## Keywords

```text
Festung,Mittelalter,Strategie,Belagerung,Verteidigung,Pixel,Fantasy,Thron,Turm,Reich,Entscheidung
```

## What's New (1.0)

```text
Die erste Version von Lanternhold: Kapitel 1, zwanzig Nächte im Spalt. Halte das Licht.
```

## Notes

- Anrede im Store: du (wie bei Comet Cargo); im Spiel selbst reden die Leute den Burgherrn mit Ihr an.
- Feste Begriffe aus STORY.md und dem Katalog: Haus Lantern, die Weltmauer, der Spalt, die Düsternis, das Große
  Leuchtfeuer, der Lichtlose König, der Stirnreif, Burgherr Aldric, Laternenanzünder, Feuerschale, Pfahlgrube,
  Balliste, Kanzlerin. Die Namen der Wesen (Rußlinge, Schattenhunde, Aschenriese) stehen noch in keinem Katalog;
  das Glossar der i18n-Lane entscheidet sie, danach hier angleichen.
- Keywords: kein Wort aus Name oder Untertitel (Burg, bauen, Nacht, überstehen), kein Spiel, keine Marke. Umlaute
  zählen zwei Bytes.
