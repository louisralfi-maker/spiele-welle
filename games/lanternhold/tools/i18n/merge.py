#!/usr/bin/env python3
"""Merge finished translations into Resources/Story.xcstrings.

    python3 tools/i18n/merge.py [lang ...] [--dry-run] [--remove lang]

Without languages it merges every one of fr, es, it, pt-BR, ja, zh-Hans that has a folder tools/i18n/lang/<lang>/.
Each language must pass check.py with no error, or nothing is written at all. For every key it sets
localizations.<lang> = {"stringUnit": {"state": "translated", "value": ...}}, replacing an earlier merge of the same
language. English, German, every other language, the comments and the key order stay exactly as they were; the file
is written in Xcode's own layout, and the script checks all of this on the result before it replaces the catalog.
--remove takes a language out of the catalog again (never en or de).
"""

import argparse
import os
import sys
import tempfile

import check
import i18nlib as lib


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("langs", nargs="*", help="languages to merge (default: every target with a folder)")
    parser.add_argument("--dry-run", action="store_true", help="check and report, write nothing")
    parser.add_argument("--remove", action="append", default=[], choices=lib.TARGETS,
                        help="take this language out of the catalog")
    parser.add_argument("--catalog", default=lib.CATALOG)
    parser.add_argument("--lang-root", default=lib.LANG_ROOT)
    args = parser.parse_args()

    langs = args.langs or ([] if args.remove else
                           [lang for lang in lib.TARGETS if os.path.isdir(lib.lang_dir(lang, args.lang_root))])
    for lang in langs:
        if lang not in lib.TARGETS:
            print("merge: %s is not one of %s" % (lang, ", ".join(lib.TARGETS)))
            return 2
    if not langs and not args.remove:
        print("merge: no translation folders under %s" % args.lang_root)
        return 2

    raw, data = lib.load_catalog(args.catalog)
    if lib.dump_catalog(data) != raw:
        print("merge: the catalog is not in Xcode's layout (a round trip changes it); open and save it in Xcode, "
              "or check it by hand, before merging")
        return 2

    failed = []
    translations = {}
    for lang in langs:
        errors, _, summary = check.run(lang, catalog=args.catalog, lang_root=args.lang_root)
        print(summary)
        if errors:
            failed.append(lang)
            for line in errors[:10]:
                print("  ERROR   " + line)
            if len(errors) > 10:
                print("  ... %d more: python3 tools/i18n/check.py %s" % (len(errors) - 10, lang))
        else:
            translations[lang], _ = lib.load_translation(lang, args.lang_root)
    if failed:
        print("merge: nothing written; fix %s first" % ", ".join(failed))
        return 1

    before_keys = list(data["strings"].keys())
    before = {lang: lib.texts(data, lang) for lang in ("en", "de")}
    others = {}
    for key, entry in data["strings"].items():
        for lang, loc in entry.get("localizations", {}).items():
            if lang not in translations and lang not in args.remove:
                others[(key, lang)] = loc

    for key, entry in data["strings"].items():
        locs = entry.setdefault("localizations", {})
        for lang in args.remove:
            locs.pop(lang, None)
        for lang, texts in translations.items():
            locs[lang] = {"stringUnit": {"state": "translated", "value": texts[key]}}
        entry["localizations"] = {lang: locs[lang] for lang in sorted(locs)}

    out = lib.dump_catalog(data)

    # Check the result before it replaces the catalog.
    import json
    result = json.loads(out)
    problems = []
    if list(result["strings"].keys()) != before_keys:
        problems.append("the key order changed")
    for lang in ("en", "de"):
        if lib.texts(result, lang) != before[lang]:
            problems.append("the %s texts changed" % lang)
    for (key, lang), loc in others.items():
        if result["strings"][key]["localizations"].get(lang) != loc:
            problems.append("%s %s changed" % (key, lang))
            break
    for lang, texts in translations.items():
        if lib.texts(result, lang) != {k: texts[k] for k in before_keys}:
            problems.append("%s did not land as written" % lang)
    for lang in args.remove:
        if lib.texts(result, lang):
            problems.append("%s is still there" % lang)
    if problems:
        print("merge: nothing written: " + "; ".join(problems))
        return 1

    action = []
    if translations:
        action.append("merged " + ", ".join("%s (%d)" % (lang, len(before_keys)) for lang in translations))
    if args.remove:
        action.append("removed " + ", ".join(args.remove))
    if args.dry_run:
        print("merge (dry run): would have %s; the catalog would grow from %d to %d bytes"
              % (" and ".join(action), len(raw), len(out)))
        return 0
    folder = os.path.dirname(os.path.abspath(args.catalog))
    handle, temp = tempfile.mkstemp(prefix=".Story-", suffix=".xcstrings", dir=folder)
    with os.fdopen(handle, "wb") as stream:
        stream.write(out)
    os.replace(temp, args.catalog)
    where = os.path.abspath(args.catalog)
    if where.startswith(lib.GAME + os.sep):
        where = os.path.relpath(where, lib.GAME)
    print("merge: %s; wrote %s (%d bytes)" % (" and ".join(action), where, len(out)))
    print("Run the unit tests on the runner after a merge (PetitionDataTests read the catalog).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
