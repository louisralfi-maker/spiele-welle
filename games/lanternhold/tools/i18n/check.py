#!/usr/bin/env python3
"""Check a translation of the story texts before it is merged.

    python3 tools/i18n/check.py <lang> [--chunk N] [--catalog-text] [--show N] [--no-warnings]

<lang> is fr, es, it, pt-BR, ja or zh-Hans (or de, which checks the catalog's German as a self-test). The translation
is read from tools/i18n/lang/<lang>/*.json (all files merged, each an object of key -> text); --catalog-text reads
the language from Story.xcstrings instead (after a merge). --chunk N checks only the keys of chunk N of
source/chunks.json (run export.py first).

Errors (exit code 1):
- a key missing, a key the catalog does not have, a key in two files;
- an empty text, a space at either end, two spaces in a row, a line break;
- placeholders: {lord} not as often as in English, a printf placeholder (%@, %lld) not as in English, a brace group
  that is neither {lord} nor {a|b}, a | outside a group;
- a text over its length budget (i18nlib.LIMITS; {lord} counts 16, each {a|b} its longer half; ja and zh-Hans in
  width units);
- a text left in English (the same as the English, English words in a Romance text, Latin letters in ja or zh-Hans);
- punctuation that breaks the language's rules (glossary.md "Punctuation"): straight quotes, three dots, the wrong
  quotation marks, French spaces, Spanish ¿ ¡, half-width punctuation in Japanese and Chinese.

Warnings (printed, exit code unchanged): a text much shorter or longer than the English, a Romance text that never
turns on lord or lady where the German or English does, both halves of a group the same, a word before {lord} that
would have to change with the name (French de/que, Portuguese articles).
"""

import argparse
import os
import re
import sys
import unicodedata

import i18nlib as lib

# English words that are not words in French, Spanish, Italian or Portuguese (no "a", "do", "he", "has", "for",
# "but", "son", "me", "in", "no", "come": each of those is a word somewhere in the Romance languages).
ENGLISH_WORDS = {
    "the", "and", "of", "you", "your", "is", "are", "was", "were", "with", "not", "this", "that", "they", "them",
    "will", "would", "have", "what", "it", "from", "my", "we", "our", "she", "his", "her", "there", "their", "which",
    "who", "all", "be", "been", "does", "did", "shall", "should", "could", "must", "into", "only", "never", "every",
}

# Names that stay as written in the Latin-script languages (glossary.md "Names"): a speaker name equal to the English
# is right there.
SAME_ALLOWED_PREFIX = ("speaker.",)
SAME_ALLOWED_SUFFIX = (".name",)

QUOTES = {
    "en": ("“”", "„«»"),
    "de": ("„“", "”«»"),
    "fr": ("«»", "“”„"),
    "es": ("«»“”", "„"),
    "it": ("«»“”", "„"),
    "pt-BR": ("“”", "«»„"),
    "ja": ("「」『』", "“”„«»"),
    "zh-Hans": ("“”‘’", "「」『』„«»"),
}

NBSP = "\u00a0"


def problems_for(lang, key, text, english, german):
    """(errors, warnings) of one text."""
    errors = []
    warnings = []
    kind = lib.kind_of(key)

    if not text.strip():
        return ["empty"], []
    if text != text.strip():
        errors.append("a space or line break at the start or end")
    if "\n" in text or "\r" in text:
        errors.append("a line break (the cards wrap by themselves)")
    if "  " in text:
        errors.append("two spaces in a row")
    if text != unicodedata.normalize("NFC", text):
        errors.append("not in NFC (composed) form")

    # Placeholders.
    for broken in lib.broken_groups(text):
        errors.append("a brace group that is neither {lord} nor {a|b}: %s" % broken)
    if any(kind == "text" and "|" in value for kind, value in lib.pieces(text)):
        errors.append("a | outside a {a|b} group")
    if lib.name_count(text) != lib.name_count(english):
        errors.append("{lord} %d times, the English has it %d times" % (lib.name_count(text), lib.name_count(english)))
    if lib.printf_specs(text) != lib.printf_specs(english):
        errors.append("printf placeholders %s, the English has %s" % (lib.printf_specs(text), lib.printf_specs(english)))
    groups = lib.choice_groups(text)
    for lord, lady in groups:
        if lord == lady:
            warnings.append("both halves of {%s|%s} are the same: write it once, without braces" % (lord, lady))
        if not lord.strip() and not lady.strip():
            errors.append("an empty {|} group")
    if lang in lib.LATIN and lang not in ("en", "de") and not groups:
        if lib.choice_groups(german):
            warnings.append("the German turns on lord or lady here and this text never does: check a Burgherrin")
        elif lib.choice_groups(english):
            warnings.append("the English turns on lord or lady here and this text never does: check a Burgherrin")

    # Length.
    if kind:
        budget = lib.limit(kind, lang)
        length = lib.longest(text, lang)
        if length > budget:
            unit = "width units" if lang in lib.CJK else "characters"
            errors.append("%d %s, the budget for a %s is %d" % (length, unit, lib.KIND_NAMES[kind], budget))
        base = lib.longest(english, "en")
        if base >= 20:
            ratio = length / float(base)
            low, high = (0.5, 1.8) if lang in lib.CJK else (0.6, 1.6)
            if ratio < low:
                warnings.append("only %.0f%% of the English length: is something missing?" % (ratio * 100))
            elif ratio > high:
                warnings.append("%.0f%% of the English length: can it be shorter?" % (ratio * 100))

    # Left in English.
    same_ok = key.startswith(SAME_ALLOWED_PREFIX) and key.endswith(SAME_ALLOWED_SUFFIX) and lang in lib.LATIN \
        and key != "speaker.stranger.name"
    if lang != "en" and text == english and not same_ok:
        errors.append("the same as the English")
    plain = lib.outside_placeholders(text)
    if lang in lib.LATIN and lang not in ("en", "de"):
        words = [w.lower() for w in re.findall(r"[A-Za-z’']+", plain)]
        hits = [w for w in words if w in ENGLISH_WORDS]
        if len(set(hits)) >= 2 or len(hits) >= 3:
            errors.append("looks English (%s)" % ", ".join(sorted(set(hits))))
    if lang in lib.CJK:
        latin = re.findall(r"[A-Za-z]+", plain)
        if latin:
            errors.append("Latin letters left (%s): names are written in %s" %
                          (", ".join(latin[:5]), "katakana" if lang == "ja" else "hanzi"))

    # Punctuation.
    errors += punctuation(lang, text, plain, warnings)

    # Words that would have to agree with the typed name.
    if "{lord}" in text:
        if lang == "fr" and re.search(r"(?i)\b(de|que|le|la|ne|je|se|ce|me|te|jusque|lorsque|puisque)\s+\{lord\}", text):
            warnings.append("a word before {lord} that elides before a vowel (d’, qu’, l’): rephrase")
        if lang == "it" and re.search(r"(?i)\b(lo|la|una|dello|della|allo|alla|dallo|dalla|nello|nella)\s+\{lord\}",
                                      text):
            warnings.append("an article before {lord}: names take none")
        if lang == "pt-BR" and re.search(r"(?i)\b(o|a|do|da|no|na|ao|à|pelo|pela)\s+\{lord\}", text):
            warnings.append("an article before {lord}: it would have to agree with the name; leave it out")
        if lang == "es" and re.search(r"(?i)\b(y|o)\s+\{lord\}", text):
            warnings.append("y or o before {lord} (e, u before some names): rephrase")
    return errors, warnings


def punctuation(lang, text, plain, warnings):
    errors = []
    if '"' in text:
        errors.append('a straight " (use the language\'s quotation marks)')
    if "..." in text:
        errors.append("three dots (use …)")
    allowed, banned = QUOTES.get(lang, ("", ""))
    used = sorted(set(ch for ch in banned if ch in text))
    if used:
        errors.append("quotation marks %s (this language uses %s)" % (" ".join(used), " ".join(allowed)))
    if lang in lib.LATIN and lang != "en" and "'" in text:
        errors.append("a straight ' (use ’)")

    if lang == "fr":
        for match in re.finditer(r"[;:!?]+", text):
            start = match.start()
            if start == 0:
                continue
            before = text[start - 1]
            if before != NBSP:
                errors.append("“%s” needs a no-break space (U+00A0) before it" % match.group(0))
                break
        for match in re.finditer("«", text):
            if text[match.end():match.end() + 1] != NBSP:
                errors.append("« needs a no-break space (U+00A0) after it")
                break
        for match in re.finditer("»", text):
            if match.start() == 0 or text[match.start() - 1] != NBSP:
                errors.append("» needs a no-break space (U+00A0) before it")
                break
        if "\u202f" in text or "\u2009" in text:
            errors.append("a narrow or thin space (the game's face lacks it; use U+00A0)")
    if lang == "es":
        for side in (0, 1):
            seen = lib.plain_text(text, side)
            q_open, q_close = seen.count("¿"), len(re.findall(r"\?+", seen))
            e_open, e_close = seen.count("¡"), len(re.findall(r"!+", seen))
            if q_open != q_close:
                errors.append("%d ¿ for %d ?" % (q_open, q_close))
                break
            if e_open != e_close:
                errors.append("%d ¡ for %d !" % (e_open, e_close))
                break
    if lang == "it":
        if re.search(r"\b[EeAaOoUuIi]'", text) or re.search(r"\bE’(?=\s)", text):
            errors.append("an apostrophe for an accent (È, not E’)")
    if lang in ("ja", "zh-Hans"):
        plain = lib.outside_placeholders(text, filler="")
        half = sorted(set(ch for ch in plain if ch in ",.!?:;()"))
        if half:
            errors.append("half-width punctuation %s (use full-width)" % " ".join(half))
        if lang == "zh-Hans" and re.search("[\u3000 ]", plain):
            errors.append("a space (Chinese text has none)")
        if lang == "ja" and " " in plain:
            errors.append("a half-width space (Japanese text has none; after ！ or ？ use U+3000)")
        if re.search(r"(?<!…)…(?!…)", plain):
            warnings.append("a single … (write …… in pairs)")
        if lang == "ja" and "·" in plain:
            errors.append("· in a name (Japanese uses ・)")
        if lang == "zh-Hans" and "・" in plain:
            errors.append("・ in a name (Chinese uses ·)")
        if lang == "ja" and re.search("[\uff01\uff1f](?=[^\u3000\u300d\u300f\uff01\uff1f\uff09\u2026\u2015])", text):
            warnings.append("！ or ？ inside a text wants a full-width space (U+3000) after it")
    return errors


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("lang", choices=lib.TARGETS + ["de"])
    parser.add_argument("--chunk", type=int, help="check only the keys of this chunk (source/chunks.json)")
    parser.add_argument("--catalog-text", action="store_true", help="read the language from Story.xcstrings")
    parser.add_argument("--catalog", default=lib.CATALOG)
    parser.add_argument("--lang-root", default=lib.LANG_ROOT, help="folder with one sub-folder per language")
    parser.add_argument("--show", type=int, default=60, help="print at most this many problems (default 60)")
    parser.add_argument("--no-warnings", action="store_true")
    args = parser.parse_args()
    errors, warnings, summary = run(args.lang, chunk=args.chunk, catalog_text=args.catalog_text or args.lang == "de",
                                    catalog=args.catalog, lang_root=args.lang_root)
    print(summary)
    shown = 0
    for line in errors:
        if shown >= args.show:
            break
        print("  ERROR   " + line)
        shown += 1
    if not args.no_warnings:
        for line in warnings:
            if shown >= args.show:
                break
            print("  warning " + line)
            shown += 1
    hidden = len(errors) + (0 if args.no_warnings else len(warnings)) - shown
    if hidden > 0:
        print("  ... and %d more (--show)" % hidden)
    print("RESULT %s: %s" % (args.lang, "FAILED" if errors else "OK"))
    return 1 if errors else 0


def run(lang, chunk=None, catalog_text=False, catalog=lib.CATALOG, lang_root=lib.LANG_ROOT):
    """(errors, warnings, summary line); merge.py calls this too."""
    _, data = lib.load_catalog(catalog)
    english = lib.texts(data, "en")
    german = lib.texts(data, "de")
    keys = list(data["strings"].keys())
    errors = []
    warnings = []
    if catalog_text:
        translation = lib.texts(data, lang)
        source = "Story.xcstrings"
    else:
        translation, file_problems = lib.load_translation(lang, lang_root)
        errors += file_problems
        source = lib.lang_dir(lang, lang_root)
        if source.startswith(lib.GAME + os.sep):
            source = os.path.relpath(source, lib.GAME)
    wanted = keys
    if chunk is not None:
        chunks = lib.read_chunks()
        match = [c for c in chunks["chunks"] if c["n"] == chunk]
        if not match:
            return ["there is no chunk %d" % chunk], [], "check %s: no chunk %d" % (lang, chunk)
        wanted = match[0]["keys"]
        if chunks.get("keys") != len(keys):
            errors.append("source/chunks.json was made from another catalog (%s keys, now %d): run export.py"
                          % (chunks.get("keys"), len(keys)))
    wanted_set = set(wanted)
    missing = [k for k in wanted if k not in translation]
    extra = [k for k in translation if k not in data["strings"]]
    outside = [k for k in translation if k in data["strings"] and k not in wanted_set] if chunk is not None else []
    for key in missing:
        errors.append("%s: missing" % key)
    for key in extra:
        errors.append("%s: not a key of the catalog" % key)
    if outside and chunk is not None:
        pass  # Other chunks' keys in the same folder are fine while checking one chunk.
    checked = 0
    for key in wanted:
        if key not in translation:
            continue
        checked += 1
        errs, warns = problems_for(lang, key, translation[key], english.get(key, ""), german.get(key, ""))
        errors += ["%s: %s" % (key, e) for e in errs]
        warnings += ["%s: %s" % (key, w) for w in warns]
    scope = "chunk %d (%d keys)" % (chunk, len(wanted)) if chunk is not None else "%d keys" % len(wanted)
    summary = "check %s from %s, %s: %d checked, %d missing, %d extra, %d errors, %d warnings" % (
        lang, source, scope, checked, len(missing), len(extra), len(errors), len(warnings))
    return errors, warnings, summary


if __name__ == "__main__":
    sys.exit(main())
