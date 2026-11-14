# Lanternhold: App Store listing, English (en-US)

Draft for the director (store lane, step store-1, 14.11.2026). The texts inside the `text` blocks are what goes into
App Store Connect. Lines that start with `[if shipped]` describe parts that are not in the build yet (digest section 5
and the rebuild's ideas): cut the whole line, or delete only the marker once the part is in the build. Never paste a
marker. `python3 games/lanternhold/store/tools/check_listing.py` counts every limit with the marked lines kept and with
them cut. Locale: en-US (the same text can serve en-GB, en-AU and en-CA).

## Name

```text
Lanternhold
```

## Subtitle

```text
Build by day. Hold the night.
```

## Promotional text

```text
Twenty nights to hold the only gap in a wall of mountains. Build by day, judge your people from the throne, and keep the fires lit: the Gloom fears nothing else.
```

## Description

```text
Hold the one gap in a wall of mountains against the Gloom: tall figures of smoke that shrink from light.
By day, build walls, towers and fires, judge your people's petitions and keep your town content.
By night the battle plays out on its own, and only what you built and lit stands between the dark and your hearth.

THE LAST LAMPLIGHTER
For a thousand years House Lantern has held the Cleft, the only way through the Worldwall. This autumn the Great Beacon went dark. Lord Aldric rode out to light it again and never came back. The circlet passed to the castle's young lamplighter: you. Name your lord or lady, take up the hooked lantern pole, and keep the light.

BY DAY: BUILD AND JUDGE
• Raise walls, gates, towers and braziers on the gorge floor, dig stake pits, set up a ballista and a catapult.
• Recruit archers and guards. Grow the valley town with houses, fields, a market and a tavern.
• Step into your great hall, sit on the throne and hear your people: farmers, soldiers, merchants, a bard, a knight who means every word, envoys of the other great houses. Every choice costs or earns gold and moves your people's mood, and some change the world you walk through.
• Set the taxes. A content town pays and grows. An unhappy one grumbles.
• Talk to your court: a dry chancellor, a gruff captain, a fool who tells the truth as jokes, a cook who hears every rumour, and a stranger with a grey lantern.
[if shipped] • A ledger beside the throne remembers your judgments and what came of them.

BY NIGHT: HOLD
• Light is the law of the battle. In the dark, creatures are unseen and fast. In light they slow, your archers can find them, and the small ones burn.
• Fire arrows streak through the night, braziers throw pools of light, walls crack and hold.
• Seven kinds of creature, from swarming sootlings and leaping shadehounds to the Ash Giant.
• Walk the walls with your lantern, patch a damaged wall, relight a brazier the crows have snuffed.
[if shipped] • Raise your lantern high, and whatever it touches flinches back into the dark.
• If they reach the hearth fire in your great hall, the realm falls.

TWENTY NIGHTS
Chapter 1 runs twenty nights, with more than 80 petitions and a court with secrets of its own. Rebuild the Great Beacon: only in its light can the Lightless King be hurt.
[if shipped] Three endings, told in lantern slides, turn on the last night, your people's mood and one hard choice.
[if shipped] When the chapter ends, your realm stands on through endless nights.
[if shipped] At the Lantern Table in the chapel, send riders, scouts and envoys out with numbered lanterns. Not every lantern comes home.

• Pixel art under soft, living light: warm fire against cold blue nights, fog, rain and embers
• A day and a night take about five minutes, and the game saves at every dawn
• Sound effects and haptics only, no music, so your own music can play alongside
• No account, no in-app purchases
[if shipped] • In English, German, French, Spanish, Italian, Portuguese, Japanese and Chinese
```

## Keywords

```text
castle,defense,medieval,pixel,strategy,siege,fantasy,tower,throne,lord,realm,choices,story,archer
```

## What's New (1.0)

```text
The first release of Lanternhold: chapter 1, twenty nights in the Cleft. Keep the light.
```

## Notes

- First three lines: the hook (the place and the enemy), the day, the night.
- Keywords repeat no word of the name or the subtitle (build, day, hold, night) and name no game or brand. "kingdom" is
  left out on purpose: it is a common word, but in this genre it reads as leaning on another game. Every keyword has
  at least three characters (Apple: "each greater than two characters").
- "More than 80 petitions": the catalogue has 89 (digest); the round number survives small cuts.
- What each claim rests on (digest sections 2 to 4, DESIGN.md): walls, gates and the beacon in three tiers, towers,
  braziers, stake pits, ballista, catapult, archers, guards, houses, fields, market, tavern ("The world", "Prices and
  build times"); the court of 8 (Odile, Brannock, Pip, Tamsin, Seren and others), guests such as Ser Ludo and the bard,
  5 houses with envoys ("The castle"); 7 creature kinds, the Ash Giant on night 10, the Lightless King on night 20
  ("Creatures of the Gloom"); the beacon as the only way to hurt the King ("The finale"); the lantern, Patch and Light
  at night ("The king at night"); crows snuff braziers; saves at every dawn ("Progression and saving"); the ambient
  audio session lets the player's own music play ("Sound and haptics"); taxes and happiness ("Economy").
- The rebuild replaces the cut-away rooms with the great hall as its own stage and the action button with touching
  the world. The text says "step into your great hall" and names no control, so it holds for both builds.
- `[if shipped]` lines and what they wait for: the ledger (stage-3 idea), raise the lantern (stage-2 idea), the three
  ending slides (panels lane), endless mode (not built), the Lantern Table (quests lane), the six other languages
  (i18n lane and the interface strings after the join).
