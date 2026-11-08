#!/usr/bin/env python3
"""Check a String Catalog: catcheck.py <catalog.xcstrings> [swift source dirs...]

- valid JSON, every key translated into all seven languages, placeholders match the key;
- with source dirs: lists Text("...") / String(localized: "...") literals whose key is missing from the catalog
  (interpolations become %lld for Int-looking and %@ otherwise, so treat the list as a hint).
Exit 1 on any catalog error.
"""
import json, os, re, sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from catupd import LANGS, phs  # noqa: E402

if len(sys.argv) < 2:
    print(__doc__)
    sys.exit(2)
d = json.load(open(sys.argv[1], encoding="utf-8"))
errors = 0
counts = {l: 0 for l in LANGS}
for key, entry in d["strings"].items():
    if entry.get("shouldTranslate") is False:
        continue
    locs = entry.get("localizations", {})
    for l in LANGS:
        loc = locs.get(l)
        if loc is None:
            print(f"MISSING {l} {key!r}")
            errors += 1
            continue
        if "stringUnit" in loc:
            values = [loc["stringUnit"]["value"]]
        else:
            values = [u["stringUnit"]["value"] for u in loc.get("variations", {}).get("plural", {}).values()]
        for v in values:
            if phs(v) != phs(key):
                print(f"PLACEHOLDER {l} {key!r}: {v!r}")
                errors += 1
        counts[l] += 1
print(f"{len(d['strings'])} keys; translated per language: {counts}")
def strip_interpolations(raw):
    """Replaces each \\( ... \\) (nested parentheses allowed) with %@."""
    out, i = [], 0
    while i < len(raw):
        if raw.startswith("\\(", i):
            depth, i = 1, i + 2
            while i < len(raw) and depth:
                depth += {"(": 1, ")": -1}.get(raw[i], 0)
                i += 1
            out.append("%@")
        else:
            out.append(raw[i])
            i += 1
    return "".join(out)


lit = re.compile(r'(?:Text|String\(localized:)\(?\s*"((?:[^"\\]|\\.)*)"')
for root in sys.argv[2:]:
    for dp, _, files in os.walk(root):
        for f in files:
            if not f.endswith(".swift"):
                continue
            src = open(os.path.join(dp, f), encoding="utf-8").read()
            for m in lit.finditer(src):
                raw = m.group(1)
                key = strip_interpolations(raw)
                if key in d["strings"]:
                    continue
                alt = re.sub(r"%@", "%lld", key)
                if alt in d["strings"] or any(re.sub(r"%(lld|@)", "", k) == re.sub(r"%(lld|@)", "", key) for k in d["strings"]):
                    continue
                print(f"NOT IN CATALOG {f}: {raw!r}")
sys.exit(1 if errors else 0)
