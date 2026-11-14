#!/usr/bin/env python3
"""List the story keys a language must translate again after the catalog changed, ready to translate.

    python3 tools/i18n/changed.py [lang ...] [--since GIT-REV] [--stamp]

For each language (default: every one with a stamp in tools/i18n/base/) it compares the catalog's English and German
with what the language was translated from (base/<lang>.json, written by merge.py) and prints:

- new keys (in the catalog, not in the translation): translate them;
- changed keys (the English or German changed since the merge): translate them again;
- gone keys (in the translation, no longer in the catalog): delete them from lang/<lang>/.

It writes tools/i18n/source/changed/<lang>.json (git-ignored), one item per new or changed key, in the chunk files'
form: the English, the German, the current translation, the context (who speaks to whom, the petition, the choice)
and the budget. With --since REV each changed item also carries the English as it was at that git revision (for
example the commit of the last merge), so the translator sees exactly what moved.

The translator edits only those keys in lang/<lang>/story.<lang>.json, runs check.py <lang> to OK, and merge.py writes
the catalog and the new stamp. --stamp writes the stamp without a merge (when an English change needs no new
translation, a typo fixed in the source for example).
"""

import argparse
import json
import os
import subprocess
import sys

import i18nlib as lib


def english_at(rev):
    path = os.path.relpath(lib.CATALOG, lib.GAME)
    try:
        raw = subprocess.check_output(["git", "show", "%s:./%s" % (rev, path)], cwd=lib.GAME,
                                      stderr=subprocess.DEVNULL)
    except (OSError, subprocess.CalledProcessError):
        return None
    return lib.texts(json.loads(raw), "en")


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("langs", nargs="*")
    parser.add_argument("--since", help="a git revision whose English to show beside each changed key")
    parser.add_argument("--stamp", action="store_true", help="write the stamp from the current catalog, list nothing")
    parser.add_argument("--catalog", default=lib.CATALOG)
    args = parser.parse_args()

    langs = args.langs or [lang for lang in lib.TARGETS if lib.load_base(lang) is not None]
    for lang in langs:
        if lang not in lib.TARGETS:
            print("changed: %s is not one of %s" % (lang, ", ".join(lib.TARGETS)))
            return 2
    if not langs:
        print("changed: no language has a stamp yet (merge.py writes it)")
        return 2

    _, data = lib.load_catalog(args.catalog)
    if args.stamp:
        for lang in langs:
            lib.write_base(lang, data)
            print("changed: stamped %s at the catalog's %d keys" % (lang, len(data["strings"])))
        return 0

    english = lib.texts(data, "en")
    german = lib.texts(data, "de")
    before = english_at(args.since) if args.since else None
    if args.since and before is None:
        print("changed: cannot read the catalog at %s" % args.since)
        return 2
    meta = lib.key_meta(data)
    out_dir = os.path.join(lib.SOURCE, "changed")
    os.makedirs(out_dir, exist_ok=True)
    total = 0
    for lang in langs:
        translation, _ = lib.load_translation(lang)
        base = lib.load_base(lang) or {}
        stale = set(lib.stale_keys(lang, data) or [])
        new = [k for k in data["strings"] if k not in translation or (base and k not in base)]
        changed = [k for k in data["strings"] if k in stale and k not in new]
        gone = [k for k in translation if k not in data["strings"]]
        items = []
        for key in new + changed:
            entry = {"key": key, "why": "new" if key in new else "changed", "en": english.get(key, ""),
                     "de": german.get(key, ""), "now": translation.get(key)}
            if before is not None and key in changed:
                entry["enBefore"] = before.get(key)
            entry.update(meta.get(key, {}))
            kind = entry.get("kind")
            if kind:
                entry["limit"] = lib.limit(kind, lang)
            items.append(entry)
        with open(os.path.join(out_dir, lang + ".json"), "w", encoding="utf-8") as handle:
            json.dump({"lang": lang, "new": len(new), "changed": len(changed), "gone": gone, "items": items},
                      handle, ensure_ascii=False, indent=2)
            handle.write("\n")
        total += len(new) + len(changed) + len(gone)
        print("%-7s %3d new, %3d changed, %3d gone  -> %s" % (
            lang, len(new), len(changed), len(gone), os.path.relpath(os.path.join(out_dir, lang + ".json"),
                                                                      os.getcwd())))
        for key in (new + changed + gone)[:12]:
            print("          %s" % key)
        if len(new + changed + gone) > 12:
            print("          … and %d more" % (len(new + changed + gone) - 12))
    print("changed: %s" % ("nothing to translate" if total == 0 else "%d keys to look at" % total))
    return 0


if __name__ == "__main__":
    sys.exit(main())
