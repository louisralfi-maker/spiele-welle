#!/usr/bin/env python3
"""Export the story texts for translation.

    python3 tools/i18n/export.py [--out DIR] [--target N]

Writes into tools/i18n/source/ (git-ignored, rebuilt from the catalog at any time):

- story.en.json, story.de.json: one object each, key -> text, in the catalog's order.
- chunks.json: the keys in numbered chunks of about 110 (--target), kinds kept together: the names, roles,
  remembered lines and endings in one chunk, the court lines by speaker, the petitions by kind (story, court, guests,
  front, town, endless) in the files' order, never a petition or a speaker's lines split. Each chunk lists its keys
  in reading order (a petition's text, Odile's counsel, then each choice with its reactions). "meta" gives every
  key's kind, voice and speaker; "limits" the length budget of each kind per language.
- chunks/chunk-NN.json: the same chunk ready to translate: for each key the English, the German, the context and
  the budget of every target language.

The chunk numbers depend only on the catalog and the petition and line files, so every translator who runs the
export on the same commit gets the same chunks.
"""

import argparse
import json
import math
import os
import sys

import i18nlib as lib


def groups_of(data, meta):
    """The three classes, each a list of (group title, [keys in reading order])."""
    strings = data["strings"]
    english = lib.texts(data, "en")

    labels = []
    speakers = []
    for key in strings:
        if key.startswith("speaker."):
            sid = key.split(".")[1]
            if sid not in speakers:
                speakers.append(sid)
    for sid in speakers:
        keys = [k for k in ("speaker.%s.name" % sid, "speaker.%s.role" % sid) if k in strings]
        labels.append((lib.speaker_label(english, sid), keys))
    labels.append(("remembered lines", [k for k in strings if k.startswith("remember.")]))
    labels.append(("endings", [k for k in strings if k.startswith("ending.")]))

    lines = []
    order = []
    by_speaker = {}
    for line in lib.load_lines():
        sid = line["speaker"]
        if sid not in by_speaker:
            by_speaker[sid] = []
            order.append(sid)
        by_speaker[sid].append(line["text"])
    for sid in order:
        lines.append((lib.speaker_label(english, sid), by_speaker[sid]))

    petitions = []
    for file_kind, petition in lib.load_petitions():
        petitions.append(("%s:%s" % (file_kind, petition["id"]), [key for key, _ in lib.petition_keys(petition)]))

    placed = {k for _, keys in labels + lines + petitions for k in keys}
    other = [k for k in strings if k not in placed]
    classes = [("labels", labels), ("lines", lines), ("petitions", petitions)]
    if other:
        classes.append(("other", [("other", other)]))
    return classes


def split(groups, target):
    """Balanced chunks of whole groups: as many chunks as ceil(total / (1.2 * target)), filled in order."""
    total = sum(len(keys) for _, keys in groups)
    count = max(1, math.ceil(total / (1.2 * target)))
    size = total / count
    chunks = []
    current = []
    done = 0
    for title, keys in groups:
        left = count - len(chunks)
        if current and left > 1:
            filled = done + sum(len(k) for _, k in current)
            goal = size * (len(chunks) + 1)
            if filled + len(keys) - goal > goal - filled:
                chunks.append(current)
                done = filled
                current = []
        current.append((title, keys))
    if current:
        chunks.append(current)
    return chunks


def title_of(cls, chunk):
    names = [title for title, _ in chunk]
    if cls == "labels":
        return "Names and roles of the speakers, remembered lines, endings"
    if cls == "lines":
        return "Court lines: " + ", ".join(names)
    if cls == "petitions":
        kinds = []
        for name in names:
            kind = name.split(":")[0]
            if kind not in kinds:
                kinds.append(kind)
        first = names[0].split(":")[1]
        last = names[-1].split(":")[1]
        return "Petitions (%s): %s to %s, %d petitions" % (", ".join(kinds), first, last, len(names))
    return "Other keys"


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--out", default=lib.SOURCE, help="output folder (default tools/i18n/source)")
    parser.add_argument("--catalog", default=lib.CATALOG, help="the string catalogue (default Resources/Story.xcstrings)")
    parser.add_argument("--target", type=int, default=110, help="about this many keys per chunk (default 110)")
    args = parser.parse_args()

    _, data = lib.load_catalog(args.catalog)
    english = lib.texts(data, "en")
    german = lib.texts(data, "de")
    keys = list(data["strings"].keys())
    problems = []
    for key in keys:
        if key not in english:
            problems.append("%s has no English" % key)
        if key not in german:
            problems.append("%s has no German" % key)
        if lib.kind_of(key) is None:
            problems.append("%s: unknown kind of key" % key)
    meta = lib.key_meta(data)
    for key in meta:
        if key not in data["strings"]:
            problems.append("%s is used by the petitions or lines but missing in the catalog" % key)

    chunks = []
    for cls, groups in groups_of(data, meta):
        for chunk in split(groups, args.target):
            chunk_keys = [k for _, ks in chunk for k in ks if k in data["strings"]]
            chunks.append({"n": len(chunks) + 1, "class": cls, "title": title_of(cls, chunk), "size": len(chunk_keys),
                           "keys": chunk_keys})
    listed = [k for c in chunks for k in c["keys"]]
    if sorted(listed) != sorted(keys) or len(set(listed)) != len(listed):
        problems.append("the chunks do not hold every key exactly once")

    os.makedirs(os.path.join(args.out, "chunks"), exist_ok=True)

    def write(name, obj):
        with open(os.path.join(args.out, name), "w", encoding="utf-8") as handle:
            json.dump(obj, handle, ensure_ascii=False, indent=2)
            handle.write("\n")

    write("story.en.json", {k: english.get(k, "") for k in keys})
    write("story.de.json", {k: german.get(k, "") for k in keys})
    limits = {kind: {lang: lib.limit(kind, lang) for lang in lib.KNOWN} for kind in lib.LIMITS}
    write("chunks.json", {
        "catalog": os.path.relpath(args.catalog, lib.GAME),
        "keys": len(keys),
        "target": args.target,
        "languages": lib.TARGETS,
        "limits": limits,
        "limitsNote": "characters for en, de, fr, es, it, pt-BR; width units (a wide character counts 2) for ja "
                      "and zh-Hans; {lord} counts 16, each {a|b} its longer half",
        "chunks": chunks,
        "meta": {k: meta[k] for k in keys if k in meta},
    })
    for chunk in chunks:
        items = []
        for key in chunk["keys"]:
            entry = {"key": key, "en": english.get(key, ""), "de": german.get(key, "")}
            entry.update(meta.get(key, {}))
            kind = entry.get("kind")
            if kind:
                entry["limit"] = {lang: lib.limit(kind, lang) for lang in lib.TARGETS}
            items.append(entry)
        write(os.path.join("chunks", "chunk-%02d.json" % chunk["n"]),
              {"n": chunk["n"], "title": chunk["title"], "size": chunk["size"], "items": items})

    print("export: %d keys from %s" % (len(keys), os.path.relpath(args.catalog, lib.GAME)))
    for chunk in chunks:
        print("  chunk %2d  %3d keys  %s" % (chunk["n"], chunk["size"], chunk["title"]))
    print("written to %s" % os.path.relpath(args.out, os.getcwd()))
    for problem in problems:
        print("PROBLEM " + problem)
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
