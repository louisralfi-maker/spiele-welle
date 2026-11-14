# Lanternhold: the first widow and the straw crown (14.11.2026, 16:37)

The director wrote this from Louis' words of 14.11.2026. He left every decision to the director. The numbers and the
lines are starting values: the lanes tune the numbers by values only, and the story editor may better the lines.

## Louis' words (14.11.2026)

"Wenn mal der erste Soldat stirbt, dass man so eine random Dorfbewohnerin in der Stadt hat oder als Bittstellerin, die
heult, dass ihr Mann gestorben ist, dass sie lauter Kinder hat. Unterstützt man sie mit Geld, oder muss man sie
abweisen, weil man kein Geld hat, oder nur verbal trösten, oder halt eine Antwort, dass es einen nicht interessiert!
Wär auch lustig, wenn man irgendwann mehrere Bitten verkackt hat oder sich wirklich unbeliebt macht bei der
Bevölkerung, dass sie den König schnappen und anzünden oder hängen. Wär so ein kleines Vorende, und man sieht halt,
wie man gehängt wird oder angezündet, so wie der Vorspann mit den Bildern oder halt animiert."

## The director's decision: yes to both, and neither is a new system

- Both use what the game already has: a petition, the happiness number, the unrest row (DESIGN.md, below 15) and the
  lantern-slide stage of the prologue. There is no new meter, no new menu and no new screen type.
- The widow gives the first loss a face. The straw crown gives the happiness number a floor that is seen and feared.
- Both his pictures are used: the town **burns** a straw lord as the warning and **hangs** the real one if nothing
  changes.

## 1. The first widow

**When.** At the first dawn after a night in which a soldier fell, once in a chapter. She is the first petitioner of
that morning and is never dropped. She is a young woman of the town, not the old widow of `widow_pension` (Aldric's
time, day 8 on): that one keeps three days' distance from her, if that stays one line of data.

**Who.** A townswoman marked by work (BARS.md section 3), a small child on her arm and two more at her skirt. She does
not wail: she holds herself together in front of her lord, and that is what hurts. The court is silent while she
speaks.

**The name.** She names the fallen soldier, as the dawn report does (`{fallen}`). The husband is one of the night's
fallen with a man's name. If Core's soldier names carry no such mark and it would take more than a few lines, the text
drops the name ("My husband stood on your wall last night"), and the lane reports which form is in.

**Petition `first_fallen`** (label at most 40 characters, reaction at most 140; `{lord|lady}` as everywhere):

| | English | German | effect |
|---|---|---|---|
| text | "{fallen} stood on your wall last night, my {lord\|lady}. He was mine. We have four children, and the youngest has his ears. I don't know what one asks for. I came anyway." | „{fallen} stand letzte Nacht auf Eurer Mauer, {Herr\|Herrin}. Er war meiner. Wir haben vier Kinder, und der Jüngste hat seine Ohren. Ich weiß nicht, worum man da bittet. Ich bin trotzdem gekommen." | |
| 1 | "A purse for the children" | „Ein Beutel für die Kinder" | −15 gold, +4 happiness, `widow_helped`, `town.widow.lantern`, `fallen_bow` in 6 days |
| reaction | "She holds the purse as if it were warm. By nightfall every archer on the wall has heard of it." | „Sie hält den Beutel, als wäre er warm. Bis zum Abend weiß es jeder Schütze auf der Mauer." | |
| 2 | "Sit. Tell me about him." | „Setzt Euch. Erzählt von ihm." | free, +1 happiness, `widow_heard`, `town.widow.lantern` |
| reaction | "She talks until the fire burns low. He sang badly, you learn. It costs nothing and is not nothing." | „Sie erzählt, bis das Feuer niedrig brennt. Er sang schlecht, erfahrt Ihr. Es kostet nichts und ist nicht nichts." | |
| 3 | "Soldiers die. Next." | „Soldaten sterben. Der Nächste." | −6 happiness, `widow_scorned` |
| reaction | "She goes without a word. Brannock does not look at you. 'They will hear that on the wall, lord.'" | „Sie geht ohne ein Wort. Brannock sieht Euch nicht an. ‚Das hört man auf der Mauer, Herr.'" | |

- **Louis' four answers in three tiles.** A petition holds at most three choices. "Turning her away because there is
  no money" is no tile of its own: with less than 15 gold the purse is greyed with the missing gold, as every choice
  one cannot pay. Then the lord can only give words or be cold, and the player feels the empty treasury.
- **The follow-up `fallen_bow`** (6 days after the purse): his brother brings the dead man's bow. "It knows the way
  up." Two choices: "Swear him in" (one archer for nothing, a new person if a house has room) or "Hang the bow in the
  hall. Go home to the children." (+2 happiness, `castle.hall.bow`).
- **In the walked town (build 3).** Her house is the one with a small lantern in the window (`town.widow.lantern`:
  "light is life"). After the purse or the words the children wave when the lord passes. After the cold answer the
  window stays dark and she shuts the door. If the lord walks the town that morning before the audience, he finds her
  on the chapel steps and the petition opens there: only if it stays cheap.
- Bots take the free choice. No target moves.

## 2. The straw crown (the early ending)

The fourth ending, beside the three crowns of DESIGN.md. It is the answer of a town that was not heard. It needs no
number of its own: it counts the dawns in unrest (happiness below 15, DESIGN.md's table), and every botched petition
and every hard tax already moves that number.

| dawn in unrest, in a row | what the player sees | words |
|---|---|---|
| the first | a straw lord with a straw crown hangs from the great lantern post on the market, beside the protest sign | Pip, at the audience |
| the second | at dusk the town burns the straw lord on the market; torches in the lanes; no child plays | Brannock, at dusk; Odile's counsel note |
| the third | no audience: the gate stands open, the slides play, the chapter ends | the three slides |

- **Not before day 6, not after dawn 19.** On night 20 the King comes, and the Ash Crown judges a hated lord.
- **Mending.** One dawn at 15 or more ends the count. The straw lord comes down and a child wears the straw crown for
  a day. The count starts anew at the next unrest: a lord who was warned once is warned again, never hanged at once.
- **A day with a special evening** (HOUSE.md section 9) counts neither for nor against.
- **The court stays the lord's family** (HOUSE.md): nobody at court turns on him. The guard will not draw on its own
  town, and Odile is the last to step aside. It is the town's verdict, not a betrayal.
- **Endless mode:** the same count; the verdict ends the run (record), like a fallen realm.

**Starting lines.** Pip's address as in the strings ("Your Wickship", „Eure Dochtheit").

| when | English | German |
|---|---|---|
| Pip, the first dawn | "They made a little you out of straw, Your Wickship. A good likeness. It listens just as well." | „Sie haben ein kleines Ihr aus Stroh gebaut, Eure Dochtheit. Gut getroffen. Es hört genauso gut zu." |
| Brannock, the second dusk | "They burn the straw one tonight, lord. The wall I can hold. I won't cut down my own town." | „Heute Abend brennt die Strohpuppe, Herr. Die Mauer halte ich. Meine eigene Stadt haue ich nicht nieder." |
| Odile's note, the second day | "Lower the tax, open the granary, hear them. Any of it. Today." | „Senkt die Steuer, öffnet den Speicher, hört sie an. Irgendetwas davon. Heute." |
| Pip, mended | "The straw one has retired, Your Wickship. He sends his regards." | „Der aus Stroh ist im Ruhestand, Eure Dochtheit. Er lässt grüßen." |

**The three slides**, on the prologue's lantern-slide stage (two lines of at most 60 characters, never a third):

| | the picture | English | German |
|---|---|---|---|
| 1 | the market at dusk from the castle lane: every window dark, a river of torches, the ash of the straw lord under the post | "A town can carry much. / Not everything." | „Eine Stadt trägt viel. / Nicht alles." |
| 2 | the castle gate from inside, open: the guards stand aside with lowered spears, Odile small in the torchlight | "The guard would not draw on its own town. / Odile was the last to step aside." | „Die Wache zog nicht gegen die eigene Stadt. / Odile trat als Letzte zur Seite." |
| 3 | the far view of the market: the great lantern post, a small dark shape under its arm, the crowd going home, the lamplighter's long pole reaching up, the lantern lit | "They hanged the {lord\|lady} of House Lantern from a lantern. / At dusk the lamplighter lit it all the same." | „Sie hängten {den Herrn\|die Herrin} von Haus Lantern an eine Laterne. / Am Abend zündete der Laternenanzünder sie trotzdem an." |

- **How it is shown.** Far view and silhouette only: no face, no close-up, no struggle, no blood. Slide 3 is quiet
  and a little bitter-funny, never cruel. One `bell` stroke per slide and the `lantern` sound on the last; no music.
- **The card after the slides.** Title "The Straw Crown" („Die Strohkrone"). One line: "The house went on. The next
  heir, it is said, listened." („Das Haus bestand weiter. Der nächste Erbe, heißt es, hörte zu.") Two buttons: "Back
  to the straw lord's morning" („Zurück zum Morgen der Strohpuppe"), which loads the dawn save kept on the first day
  of unrest, so the player gets his two days to mend; and "A new heir" („Ein neuer Erbe"), which starts the chapter
  anew. No ad on this card and no second chance for a video.
- Reduce Motion and VoiceOver as the prologue's slides have them.

## 3. Core, bots and tests

- **State:** the dawns in unrest in a row (0 to 3), the kept dawn save of the first of them, a flag for the first
  fallen soldier. The save format takes them with a default, so older saves load.
- **T17:** the reference bots never see the straw lord. A "tyrant" bot (high tax, the harshest choice of every
  petition) gets the verdict not before day 6 and by day 14. A "mender" bot that plays like the tyrant until the
  straw lord hangs and then gives low tax and the kind choices is out of unrest within two dawns. T4 and the Ash
  Crown hold as they are; the lane reports where the high-tax bot of T4 ends now.
- Unit tests: the count rises only on dawns below 15 and falls to zero at 15; no verdict before day 6 or on day 20;
  the kept save loads with two days left; `first_fallen` comes once and only after a loss; with 14 gold the purse
  cannot be chosen.
- The UI test saves the straw lord on the market, the burning at dusk, the three slides and the card, in English and
  German.

## 4. Not a copy, and the store

- **Not a copy:** hanging a lord from a lantern is history's own picture ("à la lanterne", 1789), told here with our
  house, our lamplighter and our stage. Nothing is taken from Yes, Your Grace or any other game: no fixed scene, line
  or picture of theirs.
- **Age rating.** An ending that shows the lord's death, even as a far silhouette, must be weighed in Apple's answers
  before any submission (the lead's task, with Louis' go). If the answers would lift the rating above the one the
  listing plans, slide 3 shows the lit lantern with the lord's circlet hanging from its arm and no shape under it; the
  caption stays.

## 5. Builds and lanes

- **Build 2 (Monday 16.11.2026):** nothing of this. Monday's build is closed for new things.
- **Build 3:** the first widow with her follow-up, then the straw crown. If time is short, in that order.
- **Words:** one story editor writes the final English and German as an additions list (`docs/verdict-words.json`),
  gated by an independent critic. The director starts it together with the house texts' apply pass
  (`docs/house-rewrite.json`), not before Monday's build is safe; then the six other languages in their second pass.
- **Lanes, all in their second round:** quests (the two petitions as data); front (the flag and the name of the first
  fallen soldier); town (the count of unrest, the kept save, the tyrant and the mender bot, T17); panels (the three
  slides and the card on its stage); people (the widow with her children, the brother with the bow, the straw lord);
  world (the lantern in her window, the straw lord on the post, its ash, the bow in the hall); ads (no placement on
  the card).
- **Gates.** The usual critics. The player critic judges: does the widow move without being a tearjerker; are the two
  warnings understood without a word; is the verdict felt as earned and fair, with a way back; is slide 3 quiet enough.
