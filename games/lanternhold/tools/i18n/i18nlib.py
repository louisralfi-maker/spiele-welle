"""Shared pieces of the story-translation tools (export.py, check.py, merge.py).

Standard library only. Everything here reads the game folder two levels up from this file:
`Resources/Story.xcstrings` (the story texts), `Resources/Petitions/*.json` and `Resources/Court/lines.json` (who says
each text). The rules mirror the app's own validator (`Core/CourtValidator.swift`, `Core/Lord.swift`): the same kinds
of text, the same placeholders and, for English and German, the same length limits.
"""

import glob
import json
import os
import re
import unicodedata

HERE = os.path.dirname(os.path.abspath(__file__))
GAME = os.path.normpath(os.path.join(HERE, "..", ".."))
CATALOG = os.path.join(GAME, "Resources", "Story.xcstrings")
PETITIONS = os.path.join(GAME, "Resources", "Petitions")
LINES = os.path.join(GAME, "Resources", "Court", "lines.json")
SOURCE = os.path.join(HERE, "source")
LANG_ROOT = os.path.join(HERE, "lang")

# The six languages this step prepares; English and German are already in the catalog.
TARGETS = ["fr", "es", "it", "pt-BR", "ja", "zh-Hans"]
LATIN = {"en", "de", "fr", "es", "it", "pt-BR"}
CJK = {"ja", "zh-Hans"}
KNOWN = ["en", "de"] + TARGETS

# The longest typed name (`LordIdentity.nameLimit`): every {lord} counts as this many characters (CJK: width units).
NAME_LIMIT = 16

# Length budgets per kind of text. English and German are the app validator's numbers (CourtValidator.swift). The
# others get a fair allowance: the Romance languages run 15 to 30 % longer than English, so the scrolling kinds
# (text, hint, reaction, line, ending) get 25 % over English; the one-line slots (choice, remembered line, tile,
# speaker name and role) stay at German's numbers, because those slots do not scroll. Japanese and Chinese are
# measured in width units (a wide character counts 2, see `width`): Japanese uses about 0.6 characters per English
# character, so twice that lands near the Romance numbers; Chinese uses about 0.4, so German's numbers are fair.
LIMITS = {
    #           en   de   fr   es   it  pt-BR  ja  zh-Hans
    "text":     (240, 280, 300, 300, 300, 300, 300, 280),
    "hint":     (140, 165, 175, 175, 175, 175, 175, 165),
    "choice":   (40, 48, 48, 48, 48, 48, 48, 48),
    "reaction": (140, 165, 175, 175, 175, 175, 175, 165),
    "line":     (120, 140, 150, 150, 150, 150, 150, 140),
    "ending":   (100, 110, 120, 120, 120, 120, 120, 110),
    "remember": (56, 56, 56, 56, 56, 56, 56, 56),
    "tile":     (28, 28, 28, 28, 28, 28, 28, 28),
    "name":     (24, 24, 24, 24, 24, 24, 24, 24),
    "role":     (32, 32, 32, 32, 32, 32, 32, 32),
}

KIND_NAMES = {
    "text": "petition text", "hint": "Odile's counsel", "choice": "choice label", "reaction": "reaction",
    "line": "court line", "ending": "ending line", "remember": "remembered line", "tile": "choice tile note",
    "name": "speaker name", "role": "speaker role",
}


def limit(kind, lang):
    return LIMITS[kind][KNOWN.index(lang)]


def kind_of(key):
    """The kind of a key, from its name (the same split the app's validator makes from the petition files)."""
    parts = key.split(".")
    head = parts[0]
    if head == "petition" and len(parts) == 3:
        tail = parts[2]
        if tail == "text":
            return "text"
        if tail == "hint":
            return "hint"
        if re.fullmatch(r"c\d", tail):
            return "choice"
        if re.fullmatch(r"r\d[a-z]?", tail):
            return "reaction"
    if head == "line" and len(parts) == 2:
        return "line"
    if head == "speaker" and len(parts) == 3 and parts[2] in ("name", "role"):
        return parts[2]
    if head == "remember":
        return "tile" if key.endswith(".tile") else "remember"
    if head == "ending":
        return "ending"
    return None


# ---------------------------------------------------------------------------------------------------------------------
# The catalog

def load_catalog(path=CATALOG):
    with open(path, "rb") as handle:
        raw = handle.read()
    return raw, json.loads(raw)


def dump_catalog(data):
    """Xcode's own layout of a string catalogue: two spaces, `"key" : value`, a newline at the end. Round-trips the
    file byte for byte (merge.py checks that before it writes)."""
    return (json.dumps(data, indent=2, ensure_ascii=False, separators=(",", " : ")) + "\n").encode("utf-8")


def texts(data, lang):
    """key -> text of one language, in the catalog's order (keys without that language are left out)."""
    out = {}
    for key, entry in data["strings"].items():
        unit = entry.get("localizations", {}).get(lang, {}).get("stringUnit")
        if unit is not None:
            out[key] = unit.get("value", "")
    return out


# ---------------------------------------------------------------------------------------------------------------------
# Placeholders (`LordText` in Core/Lord.swift): {lord} is the typed name, {a|b} reads a for the Burgherr and b for the
# Burgherrin. Nothing nests; any other brace is a mistake.

PRINTF = re.compile(r"%(?:\d+\$)?(?:lld|ld|d|@|f|s|%)")


def pieces(text):
    """[(kind, value)] with kind text, name, choice (value = (lord, lady)) or broken; the same split as LordText."""
    out = []
    plain = []
    i = 0
    n = len(text)

    def flush():
        if plain:
            out.append(("text", "".join(plain)))
            del plain[:]

    while i < n:
        ch = text[i]
        if ch == "{":
            close = text.find("}", i + 1)
            flush()
            if close < 0:
                out.append(("broken", text[i:]))
                return out
            inner = text[i + 1:close]
            parts = inner.split("|")
            if inner == "lord":
                out.append(("name", None))
            elif len(parts) == 2 and "{" not in inner:
                out.append(("choice", (parts[0], parts[1])))
            else:
                out.append(("broken", "{" + inner + "}"))
            i = close + 1
        elif ch == "}":
            flush()
            out.append(("broken", "}"))
            i += 1
        else:
            plain.append(ch)
            i += 1
    flush()
    return out


def plain_text(text, side=0, name="Robin"):
    """The text as one reader sees it: {lord} as a stand-in name, each {a|b} as one side (0 lord, 1 lady)."""
    out = []
    for kind, value in pieces(text):
        if kind == "name":
            out.append(name)
        elif kind == "choice":
            out.append(value[side])
        else:
            out.append(value)
    return "".join(out)


def outside_placeholders(text, filler=" "):
    """Only the plain runs of a text (no {lord}, no {a|b} halves), each placeholder replaced by `filler`."""
    return "".join(value if kind in ("text", "broken") else filler for kind, value in pieces(text))


def width(s):
    """Width units: a wide or full-width character (CJK, kana, full-width punctuation) counts 2, everything else 1,
    a combining mark 0. On a phone a CJK glyph is about two Latin letters wide."""
    total = 0
    for ch in unicodedata.normalize("NFC", s):
        if unicodedata.combining(ch):
            continue
        total += 2 if unicodedata.east_asian_width(ch) in ("W", "F") else 1
    return total


def measure(s, lang):
    s = unicodedata.normalize("NFC", s)
    return width(s) if lang in CJK else len(s)


def longest(text, lang):
    """The longest a text can get (`LordText.longest`): {lord} as NAME_LIMIT, each {a|b} its longer half."""
    total = 0
    for kind, value in pieces(text):
        if kind == "name":
            total += NAME_LIMIT
        elif kind == "choice":
            total += max(measure(value[0], lang), measure(value[1], lang))
        else:
            total += measure(value, lang)
    return total


def name_count(text):
    return sum(1 for kind, _ in pieces(text) if kind == "name")


def choice_groups(text):
    return [value for kind, value in pieces(text) if kind == "choice"]


def broken_groups(text):
    return [value for kind, value in pieces(text) if kind == "broken"]


def printf_specs(text):
    return sorted(PRINTF.findall(text))


# ---------------------------------------------------------------------------------------------------------------------
# Who says each text (for the translators' context and for the chunks)

PETITION_ORDER = ["story", "court", "guests", "front", "town", "endless"]


def load_petitions():
    """[(file kind, petition dict)] in PETITION_ORDER, each file in its own order."""
    found = {}
    for path in glob.glob(os.path.join(PETITIONS, "petitions-*.json")):
        kind = os.path.basename(path)[len("petitions-"):-len(".json")]
        with open(path, encoding="utf-8") as handle:
            found[kind] = json.load(handle)["petitions"]
    order = [k for k in PETITION_ORDER if k in found] + sorted(k for k in found if k not in PETITION_ORDER)
    return [(kind, petition) for kind in order for petition in found[kind]]


def load_lines():
    with open(LINES, encoding="utf-8") as handle:
        return json.load(handle)["lines"]


def petition_keys(petition):
    """The petition's keys in reading order (text, Odile's counsel, then each choice and its reactions), each with
    context: [(key, extra meta)]."""
    out = [(petition["text"], {})]
    if petition.get("hint"):
        counsel = petition.get("counsel")
        out.append((petition["hint"], {"counsel": None if counsel is None else counsel + 1}))
    for index, choice in enumerate(petition["choices"], start=1):
        out.append((choice["label"], {"choice": index}))

        def walk(effect, branch):
            if effect.get("reaction"):
                meta = {"choice": index}
                if branch:
                    meta["branch"] = branch
                out.append((effect["reaction"], meta))
            chance = effect.get("chance")
            if chance:
                p = chance.get("p")
                walk(chance.get("then", {}), "when the {:.0%} chance comes up".format(p) if p else "then")
                walk(chance.get("else", {}), "when it does not" if p else "else")
        walk(choice, None)
    return out


VOICES = {
    "text": "the petitioner speaks to the lord",
    "hint": "Odile's counsel to the lord (her voice, dry); it argues for the choice named in 'counsel'",
    "choice": "the lord answers (the lord's own words: short, plain, kind without softness)",
    "reaction": "the narrator tells what happened, speaking to the lord as 'you'",
    "line": "a court member or guest speaks to the lord in the hall",
    "ending": "the narrator, at the dawn after night 20, speaking to the lord as 'you'",
    "remember": "the reaction card's one-line note of what the choice left behind (narrator, to the lord)",
    "tile": "two or three words on a choice tile",
    "name": "a name over the audience card",
    "role": "the role under the name on the audience card",
}


def speaker_label(english, speaker):
    name = english.get("speaker.%s.name" % speaker)
    role = english.get("speaker.%s.role" % speaker)
    if name and role:
        return "%s (%s)" % (name, role)
    return name or role or speaker


def key_meta(data):
    """key -> context for the translator: kind, voice, speaker, petition, days, flags."""
    english = texts(data, "en")
    meta = {}
    for file_kind, petition in load_petitions():
        speaker = petition["speaker"]
        for key, extra in petition_keys(petition):
            kind = kind_of(key)
            entry = {"kind": kind, "voice": VOICES.get(kind, ""), "petition": petition["id"],
                     "petitionKind": file_kind}
            if petition.get("days"):
                entry["days"] = petition["days"]
            if kind == "text":
                entry["speaker"] = speaker
                entry["speakerLabel"] = speaker_label(english, speaker)
            elif kind == "hint":
                entry["speaker"] = "odile"
                entry["speakerLabel"] = speaker_label(english, "odile")
                entry["petitioner"] = speaker_label(english, speaker)
            elif kind == "choice":
                entry["speaker"] = "lord"
                entry["to"] = speaker_label(english, speaker)
            else:
                entry["speaker"] = "narrator"
            entry.update({k: v for k, v in extra.items() if v is not None})
            meta[key] = entry
    for line in load_lines():
        entry = {"kind": "line", "voice": VOICES["line"], "speaker": line["speaker"],
                 "speakerLabel": speaker_label(english, line["speaker"]), "line": line["id"]}
        for field in ("days", "requires", "forbids", "about"):
            if line.get(field):
                entry[field] = line[field]
        if line.get("answer"):
            entry["answer"] = True
        meta[line["text"]] = entry
    for key in data["strings"]:
        if key in meta:
            continue
        kind = kind_of(key)
        entry = {"kind": kind, "voice": VOICES.get(kind, "")}
        if kind in ("name", "role"):
            entry["speaker"] = key.split(".")[1]
        elif kind in ("remember", "tile", "ending"):
            entry["speaker"] = "narrator"
        meta[key] = entry
    return meta


# ---------------------------------------------------------------------------------------------------------------------
# Translations on disk: lang/<code>/*.json, each an object of key -> text

def lang_dir(lang, root=LANG_ROOT):
    return os.path.join(root, lang)


def load_translation(lang, root=LANG_ROOT):
    """(key -> text, problems): every *.json file of lang/<code>/, merged; a key in two files is a problem."""
    folder = lang_dir(lang, root)
    merged = {}
    origin = {}
    problems = []
    for path in sorted(glob.glob(os.path.join(folder, "*.json"))):
        name = os.path.basename(path)
        try:
            with open(path, encoding="utf-8") as handle:
                data = json.load(handle)
        except (OSError, ValueError) as error:
            problems.append("%s: not readable JSON (%s)" % (name, error))
            continue
        if not isinstance(data, dict):
            problems.append("%s: must be one object of key to text" % name)
            continue
        for key, value in data.items():
            if not isinstance(value, str):
                problems.append("%s: %s is not a string" % (name, key))
                continue
            if key in merged:
                problems.append("%s: %s is also in %s" % (name, key, origin[key]))
                continue
            merged[key] = value
            origin[key] = name
    return merged, problems


def read_chunks(path=None):
    with open(path or os.path.join(SOURCE, "chunks.json"), encoding="utf-8") as handle:
        return json.load(handle)
