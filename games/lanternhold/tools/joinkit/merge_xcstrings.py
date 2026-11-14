#!/usr/bin/env python3
"""Three-way merge for Xcode string catalogs (.xcstrings).

    merge_xcstrings.py BASE OURS THEIRS [-o OUT] [--prefer ours|theirs]
                       [--report FILE] [--strict] [--mark-stale]

Works like a git merge driver (%O %A %B): without -o the result is written over OURS.

- The merge is per key and, inside a key, per field (comment, each language's
  stringUnit, variations ...), so one lane adding French while another fixes the
  German of the same key merges cleanly.
- A value changed on one side takes that side. A value changed differently on
  both sides is a conflict: it is listed in the report and takes the side named
  by --prefer (default: ours). With --strict nothing is written and the exit
  code is 1.
- Keys (and languages) added on either side are kept. A key deleted on one side
  and untouched on the other is deleted; deleted on one side and changed on the
  other is a conflict.
- Stale translations: when one side changes a key's English (the source
  language) and the other side adds or changes another language of that key,
  the translation was made from the old English. It is listed as "stale";
  with --mark-stale its state becomes "needs_review".
- Output: Xcode's formatting (two spaces, " : ", no ASCII escaping, a final
  newline as in OURS). Keys present in OURS keep OURS's order; new keys are
  placed where Xcode's sorted order puts them, so the diff stays small.
- A missing BASE path (or /dev/null) means an empty catalog (add/add).

Exit codes: 0 clean, 1 conflicts (written with --prefer unless --strict), 2 error.
Standard library only.
"""
import argparse
import copy
import json
import os
import sys

MISSING = object()


def clone(v):
    return v if v is MISSING else copy.deepcopy(v)


def load(path):
    if path is None or path == os.devnull or not os.path.exists(path):
        return {}, True
    with open(path, encoding="utf-8") as f:
        raw = f.read()
    if not raw.strip():
        return {}, True
    return json.loads(raw), raw.endswith("\n")


def dump(obj, final_newline=True):
    out = json.dumps(obj, indent=2, separators=(",", " : "), ensure_ascii=False)
    return out + ("\n" if final_newline else "")


def ordered_union(ours_keys, theirs_keys):
    """OURS order kept; keys only in THEIRS inserted before the first OURS key
    that sorts after them (Xcode keeps catalogs sorted)."""
    result = list(ours_keys)
    present = set(result)
    for k in theirs_keys:
        if k in present:
            continue
        pos = len(result)
        for i, existing in enumerate(result):
            if existing > k:
                pos = i
                break
        result.insert(pos, k)
        present.add(k)
    return result


class Merger:
    def __init__(self, prefer):
        self.prefer = prefer
        self.conflicts = []  # (path, base, ours, theirs)

    def merge(self, base, ours, theirs, path):
        if ours is theirs or ours == theirs:
            return clone(ours)
        if base is MISSING and ours is MISSING:
            return clone(theirs)  # added on theirs only
        if base is MISSING and theirs is MISSING:
            return clone(ours)  # added on ours only
        if base is not MISSING and ours == base:
            return clone(theirs)
        if base is not MISSING and theirs == base:
            return clone(ours)
        if isinstance(ours, dict) and isinstance(theirs, dict) and (base is MISSING or isinstance(base, dict)):
            b = base if isinstance(base, dict) else {}
            out = {}
            for k in ordered_union(list(ours.keys()), list(theirs.keys())):
                bv = b.get(k, MISSING)
                ov = ours.get(k, MISSING)
                tv = theirs.get(k, MISSING)
                mv = self.merge(bv, ov, tv, path + [k])
                if mv is not MISSING:
                    out[k] = mv
            return out
        # a real conflict (leaf values, or delete against change)
        self.conflicts.append((path, base, ours, theirs))
        return clone(ours if self.prefer == "ours" else theirs)


def source_value(entry, lang):
    if not isinstance(entry, dict):
        return MISSING
    loc = entry.get("localizations", {}).get(lang, MISSING)
    return loc


def find_stale(base, ours, theirs, merged, src):
    """Keys whose source text changed on one side while the other side touched
    another language of the same key."""
    stale = []
    bs, os_, ts = (d.get("strings", {}) for d in (base, ours, theirs))
    for key, entry in merged.get("strings", {}).items():
        b = bs.get(key, MISSING)
        if b is MISSING:
            continue
        o, t = os_.get(key, MISSING), ts.get(key, MISSING)
        for changer, other, other_name in ((o, t, "theirs"), (t, o, "ours")):
            if changer is MISSING or other is MISSING:
                continue
            if source_value(changer, src) == source_value(b, src):
                continue
            if source_value(other, src) != source_value(b, src):
                continue  # both changed English: that is a conflict, not staleness
            b_locs = b.get("localizations", {}) if isinstance(b, dict) else {}
            o_locs = other.get("localizations", {}) if isinstance(other, dict) else {}
            for lang, val in o_locs.items():
                if lang == src:
                    continue
                if b_locs.get(lang, MISSING) != val:
                    stale.append((key, lang, other_name))
    return stale


def fmt_path(path):
    """`key [lang] stringUnit/value` for a catalog entry, the plain path otherwise."""
    if len(path) >= 2 and path[0] == "strings":
        key, rest = path[1], list(path[2:])
        lang = ""
        if len(rest) >= 2 and rest[0] == "localizations":
            lang, rest = f" [{rest[1]}]", rest[2:]
        return f"{key}{lang}" + (" " + "/".join(str(r) for r in rest) if rest else "")
    return "/".join(str(p) for p in path) or "(whole file)"


def short(v):
    if v is MISSING:
        return "(absent)"
    s = json.dumps(v, ensure_ascii=False)
    return s if len(s) <= 160 else s[:157] + "..."


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("base")
    ap.add_argument("ours")
    ap.add_argument("theirs")
    ap.add_argument("-o", "--out")
    ap.add_argument("--prefer", choices=("ours", "theirs"), default="ours")
    ap.add_argument("--report")
    ap.add_argument("--strict", action="store_true")
    ap.add_argument("--mark-stale", action="store_true")
    ap.add_argument("--quiet", action="store_true")
    a = ap.parse_args(argv)
    try:
        base, _ = load(a.base)
        ours, ours_nl = load(a.ours)
        theirs, _ = load(a.theirs)
    except (OSError, ValueError) as e:
        print(f"merge_xcstrings: cannot read input: {e}", file=sys.stderr)
        return 2
    m = Merger(a.prefer)
    merged = m.merge(base if base else MISSING, ours, theirs, [])
    if merged is MISSING:
        merged = {}
    src = merged.get("sourceLanguage", "en")
    stale = find_stale(base, ours, theirs, merged, src)
    if a.mark_stale:
        for key, lang, _ in stale:
            loc = merged["strings"].get(key, {}).get("localizations", {}).get(lang, {})
            unit = loc.get("stringUnit") if isinstance(loc, dict) else None
            if isinstance(unit, dict):
                unit["state"] = "needs_review"

    lines = [f"# xcstrings merge: {os.path.basename(a.ours)}",
             f"conflicts: {len(m.conflicts)} (taken: {a.prefer}), stale translations: {len(stale)}"]
    for path, b, o, t in m.conflicts:
        lines.append(f"- CONFLICT {fmt_path(path)}\n    base:   {short(b)}\n    ours:   {short(o)}\n    theirs: {short(t)}")
    for key, lang, side in stale:
        lines.append(f"- STALE {key} [{lang}] (translated on {side} from the old English)")
    report = "\n".join(lines) + "\n"
    if a.report:
        with open(a.report, "a", encoding="utf-8") as f:
            f.write(report)
    if not a.quiet and (m.conflicts or stale):
        sys.stderr.write(report)

    if m.conflicts and a.strict:
        return 1
    out = a.out or a.ours
    with open(out, "w", encoding="utf-8") as f:
        f.write(dump(merged, ours_nl))
    return 1 if m.conflicts else 0


if __name__ == "__main__":
    sys.exit(main())
