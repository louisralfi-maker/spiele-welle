#!/usr/bin/env python3
"""Query a String Catalog: catq.py <catalog.xcstrings> <regex> [langs]

Prints every key matching the regex with its translations (langs comma separated, default all seven).
A plural entry prints as {category: value}.
"""
import json, re, sys

if len(sys.argv) < 3:
    print(__doc__)
    sys.exit(2)
d = json.load(open(sys.argv[1], encoding="utf-8"))
pat = re.compile(sys.argv[2])
langs = (sys.argv[3] if len(sys.argv) > 3 and sys.argv[3] else "en,de,fr,es,it,pt-BR,ja,zh-Hans").split(",")


def show(loc):
    if loc is None:
        return None
    if "stringUnit" in loc:
        return loc["stringUnit"]["value"]
    plural = loc.get("variations", {}).get("plural", {})
    return {c: u["stringUnit"]["value"] for c, u in plural.items()} or "<var>"


for k, v in d["strings"].items():
    if pat.search(k):
        locs = v.get("localizations", {})
        print(repr(k), {l: show(locs.get(l)) for l in langs if l in locs or l != "en"})
