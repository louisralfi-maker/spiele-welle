# Translating Lanternhold's story texts

The story texts (petitions, choices, reactions, Odile's counsel, court lines, speakers, remembered lines, endings) live
in `Resources/Story.xcstrings`, 882 keys in English and German. These tools bring in French (fr), Spanish (es),
Italian (it), Brazilian Portuguese (pt-BR), Japanese (ja) and Simplified Chinese (zh-Hans). Standard-library Python 3
only; they are light and may run on any Mac (no build, no simulator). Run them from the game folder
`games/lanternhold/`.

| File | What it does |
|---|---|
| `glossary.md` | Every decision a translator needs: the voice, the address, the lord or lady, every fixed term and name in all six languages, punctuation. **Read it whole before the first text.** |
| `export.py` | Writes `source/` (git-ignored): `story.en.json`, `story.de.json`, `chunks.json` and `chunks/chunk-NN.json`. |
| `check.py` | Checks one language: keys, placeholders, length budgets, English left over, punctuation. Exit code 1 on any error. |
| `merge.py` | Writes finished languages into `Story.xcstrings`; English, German and the key order stay byte for byte. |
| `i18nlib.py` | The shared rules (kinds of text, budgets, placeholders); the same rules as `Core/CourtValidator.swift`. |
| `lang/<code>/` | The translations: one or more JSON files per language, each an object of key to text. Committed. |

## How a translator works

1. **Export.** `python3 tools/i18n/export.py` prints the chunks (9 at 882 keys: one of names, roles, remembered lines
   and endings; two of court lines by speaker; six of petitions by kind, story first). The numbers depend only on
   the catalog, so everyone on the same commit gets the same chunks.
2. **Take one chunk and one language.** `source/chunks/chunk-NN.json` lists, in reading order, every key with its
   English, its German, who speaks to whom (`voice`, `speakerLabel`, `to`), the petition and its days, which choice a
   reaction follows (`choice`, `branch` for a chance) and which choice Odile's counsel argues for (`counsel`), and
   the budget in each language (`limit`).
3. **Write** `lang/<code>/chunk-NN.json`: one JSON object, key to text, exactly that chunk's keys, any order, UTF-8,
   real characters (no `\u` escapes needed). Keep `{lord}` and write `{lord form|lady form}` groups as glossary.md
   section 3 says.
4. **Check** `python3 tools/i18n/check.py <code> --chunk NN` until it ends `RESULT <code>: OK`. Read every warning:
   a warning is not a failure, but each one is a question to answer (a lady who would read the masculine, a text much
   shorter than the English, a word before `{lord}` that changes with the name).
5. **Notes.** Anything the glossary did not settle, or a line where it reads wrong, goes into
   `lang/<code>/NOTES.md` (key, the problem, what you did). The lead decides and changes the glossary; never change
   a decision alone.
6. **Commit** the chunk file and the notes.
7. When all chunks of a language are in: `python3 tools/i18n/check.py <code>` over the whole language (it also finds
   a key missing between chunks or written twice).
8. **Merge** `python3 tools/i18n/merge.py <code> [<code> ...]` (`--dry-run` first if you like). It refuses to write
   anything while a language has an error. Then `python3 tools/i18n/check.py <code> --catalog-text` reads the result
   back from the catalog. `merge.py --remove <code>` takes a language out again.
9. **Prove it in the game** on the runner: the unit round (PetitionDataTests read the catalog) and screenshots of an
   audience, the court talk and a report in that language, judged for clipping and voice.

If the catalog changes after a translation started (a story fix), run the export again: chunk numbers may move, but
translations are kept by key, not by chunk, and `check.py` reads every file in the language's folder whatever its
name, so it shows exactly which keys are new or gone.

## What check.py enforces

Errors (exit code 1): a key missing, unknown or in two files; an empty text, a space at either end, two spaces in a
row, a line break; `{lord}` not exactly as often as in the English, a printf placeholder not as in the English, a
brace group that is neither `{lord}` nor `{a|b}`, a `|` outside a group; a text over its budget; a text the same as
the English (speaker names excepted in the Latin-script languages), English words in a Romance text, Latin letters
in Japanese or Chinese; straight quotes, three dots, another language's quotation marks, French spaces, Spanish
¿ ¡, Italian accents written as apostrophes, half-width punctuation or spaces in Japanese and Chinese.

Budgets, in characters (Latin-script languages) or width units (Japanese and Chinese: a wide character counts 2).
`{lord}` counts 16, each `{a|b}` its longer half, as in the app's validator:

| Kind | en | de | fr | es | it | pt-BR | ja | zh-Hans |
|---|---|---|---|---|---|---|---|---|
| petition text | 240 | 280 | 300 | 300 | 300 | 300 | 300 | 280 |
| Odile's counsel | 140 | 165 | 175 | 175 | 175 | 175 | 175 | 165 |
| choice label | 40 | 48 | 48 | 48 | 48 | 48 | 48 | 48 |
| reaction | 140 | 165 | 175 | 175 | 175 | 175 | 175 | 165 |
| court line | 120 | 140 | 150 | 150 | 150 | 150 | 150 | 140 |
| ending line | 100 | 110 | 120 | 120 | 120 | 120 | 120 | 110 |
| remembered line | 56 | 56 | 56 | 56 | 56 | 56 | 56 | 56 |
| choice tile note | 28 | 28 | 28 | 28 | 28 | 28 | 28 | 28 |
| speaker name | 24 | 24 | 24 | 24 | 24 | 24 | 24 | 24 |
| speaker role | 32 | 32 | 32 | 32 | 32 | 32 | 32 | 32 |

English and German are the app's own limits (`CourtValidator.swift`); `python3 tools/i18n/check.py de` checks the
catalog's German against them as a self-test and passes. The others: the scrolling kinds get 25 % over English (the
Romance languages run 15 to 30 % longer); the one-line slots (choice, remembered line, tile, name, role) do not
scroll and keep German's numbers; Japanese needs about 0.6 characters per English character, twice that in width,
so it gets the Romance numbers; Chinese needs about 0.4, so German's numbers are fair. These are the budgets for the
current cards; the rebuilt interface is judged again in screenshots of every language.

## For the lead

- A translation batch is one language and one chunk, about 110 keys, one helper at a time. A full language is
  nine batches; the six languages are 54.
- Hand a translator: this README, `glossary.md`, the chunk file, and the instruction to write
  `lang/<code>/chunk-NN.json`, run `check.py <code> --chunk NN` to `OK`, and note open points in `NOTES.md`.
- An independent reader per language then reads the merged texts in screenshots, for voice and clipping, before a
  language ships.
