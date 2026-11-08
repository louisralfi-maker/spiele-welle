#!/usr/bin/env python3
"""Merge translations into a String Catalog (.xcstrings).

    python3 tools/i18n/catupd.py <catalog.xcstrings> <pending.json> [--allow-new]

pending.json: {"English key": {"de": "...", "fr": "...", ..., "comment": "..."}}
A value is a string, or a plural dict {"one": "...", "other": "..."} (CLDR categories zero/one/two/few/many/other;
"other" is required). The key "en" may carry a plural dict for the source language.

Refuses (and writes nothing) when a translation's placeholders differ from the key's, when a language is missing
(every key needs all of LANGS), or when a key is not in the catalog (unless --allow-new).
Keeps the catalog's key order, sorts each key's languages, writes Xcode's JSON style.
"""
import json, re, sys

LANGS = ["de", "fr", "es", "it", "pt-BR", "ja", "zh-Hans"]
CATEGORIES = ["zero", "one", "two", "few", "many", "other"]
PH = re.compile(r"%(?:\d+\$)?(?:lld|ld|d|@|lf|f|\.\d+f)")


def phs(s):
    return sorted(re.sub(r"\d+\$", "", p) for p in PH.findall(s))


def forms(v):
    return list(v.values()) if isinstance(v, dict) else [v]


def unit(v):
    return {"stringUnit": {"state": "translated", "value": v}}


def localization(v):
    if isinstance(v, dict):
        return {"variations": {"plural": {c: unit(v[c]) for c in CATEGORIES if c in v}}}
    return unit(v)


def main(argv):
    args = [a for a in argv if not a.startswith("--")]
    if len(args) != 2:
        print(__doc__)
        return 2
    cat_path, pending_path = args
    allow_new = "--allow-new" in argv
    d = json.load(open(cat_path, encoding="utf-8"))
    strings = d["strings"]
    pending = json.load(open(pending_path, encoding="utf-8"))
    errors = []
    for key, tr in pending.items():
        if key not in strings and not allow_new:
            errors.append(f"UNKNOWN KEY {key!r}")
        missing = [l for l in LANGS if l not in tr]
        if missing:
            errors.append(f"MISSING LANGS {key!r}: {missing}")
        for lang, v in tr.items():
            if lang == "comment":
                continue
            if lang not in LANGS + ["en"]:
                errors.append(f"UNKNOWN LANG {key!r}: {lang}")
                continue
            if isinstance(v, dict):
                bad = [c for c in v if c not in CATEGORIES]
                if bad or "other" not in v:
                    errors.append(f"BAD PLURAL {key!r} {lang}: {sorted(v)}")
            for f in forms(v):
                if not isinstance(f, str) or not f.strip():
                    errors.append(f"EMPTY {key!r} {lang}")
                elif phs(f) != phs(key):
                    errors.append(f"PLACEHOLDER MISMATCH {key!r} {lang}: {f!r}")
                elif f != f.strip():
                    errors.append(f"OUTER SPACE {key!r} {lang}: {f!r}")
    if errors:
        print("\n".join(errors))
        print(f"{len(errors)} error(s), catalog unchanged")
        return 1
    added = updated = 0
    for key, tr in pending.items():
        entry = strings.get(key)
        if entry is None:
            entry = {}
            items = list(strings.items())
            pos = next((i for i, (k, _) in enumerate(items) if k > key), len(items))
            items.insert(pos, (key, entry))
            strings.clear()
            strings.update(items)
            added += 1
        else:
            updated += 1
        if tr.get("comment"):
            entry["comment"] = tr["comment"]
        locs = entry.get("localizations", {})
        for lang, v in tr.items():
            if lang != "comment":
                locs[lang] = localization(v)
        entry["localizations"] = {l: locs[l] for l in sorted(locs)}
        # Xcode's key order inside an entry: comment, extractionState, localizations.
        ordered = {k: entry[k] for k in ("comment", "extractionState", "localizations") if k in entry}
        ordered.update({k: v for k, v in entry.items() if k not in ordered})
        entry.clear()
        entry.update(ordered)
    text = json.dumps(d, indent=2, separators=(",", " : "), ensure_ascii=False) + "\n"
    json.loads(text)
    open(cat_path, "w", encoding="utf-8").write(text)
    print(f"added {added}, updated {updated}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
