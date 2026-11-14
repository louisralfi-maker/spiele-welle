#!/usr/bin/env python3
"""Checks docs/house-rewrite.json (docs/HOUSE.md part C) against Resources/Story.xcstrings, STORY.md and DESIGN.md.

It proves: the JSON parses; every key exists; every *_old equals the file's value exactly; no new value other than a
choice label is more than 15 % longer than the old one (measured as the game shows it: the longer of the Burgherr and
Burgherrin readings, with `{lord}` counted as a 16-character name); choice labels may use their full 40 characters and
never more; English keeps the story's text limits (request 240, reaction 140, counsel 140, court line 120); `{lord}`,
printf placeholders and line breaks are kept; a value that had male and female forms still has them (except the keys in
FORMS_DROPPED, each with its reason); every brace is a `{lord}` or a `{a|b}` pair; every bible line matches STORY.md
exactly, and a prologue panel's text (STORY.md section 8) grows at most 15 %, except panel 2, which carries "made"
(the director, 14.11.: up to 25 % for that key, more than 15 % flagged for the panels lane); every design line matches DESIGN.md exactly. Then it applies the list in memory and proves that no English or
German value calls the lord a lamplighter (nor a child of the house, nor "young Taper", nor says the circlet is too
big or that the lord was never meant for it), that the house's "thief" is always tied to the fire and never to the
chair or the hall, and that no DESIGN.md line still states the old premise. It prints the
counts and exits 0 only when everything holds. It changes no file.

Run from its home games/lanternhold/tools/:   python3 tools/house_rewrite_check.py
Or point it anywhere:  python3 house_rewrite_check.py --game <games/lanternhold> --rewrite <house-rewrite.json>
"""
import argparse
import json
import os
import re
import sys

NAME_LIMIT = 16  # Core/Lord.swift LordIdentity.nameLimit
GROWTH = 1.15
CHOICE_LIMIT = 40
EN_LIMITS = [(re.compile(r'^petition\.[^.]+\.text$'), 240), (re.compile(r'^petition\.[^.]+\.c\d$'), 40),
             (re.compile(r'^petition\.[^.]+\.r\d[ab]?$'), 140), (re.compile(r'^petition\.[^.]+\.hint$'), 140),
             (re.compile(r'^line\.'), 120)]
BRACE = re.compile(r'\{([^{}]*)\}')
PRINTF = re.compile(r'%(?:\d+\$)?[-+ #0]*\d*(?:\.\d+)?(?:hh|h|ll|l|q|z|t|j)?[@dDuUxXoOfeEgGcCsSpaA%]')

# What may not stay anywhere after the rewrite. The town's lamplighter (TOWN.md 7) has no string yet; when one needs
# the word, its key goes into ALLOWED with the reason.
FORBIDDEN = [
    ('lamplighter', re.compile(r'lamp-?lighter', re.I)),
    ('Laternenanzünder', re.compile(r'Laternenanz[üu]nder', re.I)),
    ('child of the house', re.compile(r'child of the house', re.I)),
    ('Kind des Hauses', re.compile(r'Kind des Hauses', re.I)),
    ('circlet too big', re.compile(r'circlet[^.]{0,40}too big|too big[^.]{0,20}circlet', re.I)),
    ('Stirnreif zu groß', re.compile(r'Stirnreif[^.]{0,40}zu gro|zu gro[^.]{0,20}Stirnreif', re.I)),
    ('never meant for this', re.compile(r'meant for this', re.I)),
    ('nie dafür bestimmt', re.compile(r'(nie|nicht) dafür bestimmt', re.I)),
    ('young Taper', re.compile(r'young Taper', re.I)),
    ('junger Taper', re.compile(r'\{?junger?(\|junge)?\}? Taper', re.I)),
    ('the ladder joke', re.compile(r'looked at the ladder|zur Leiter', re.I)),
]
ALLOWED = {}  # key -> reason

# Keys whose new value may drop the male and female forms, because the word that needed them is gone.
_SEREN = ('Seren calls the lord "Lantern", the house\'s name: never translated and without gender (HOUSE.md 7, '
          'director 14.11.: question 6)')
FORMS_DROPPED = {k: _SEREN for k in ('line.seren_gate', 'line.seren_lantern', 'petition.seren_at_gate.text',
                                     'petition.seren_reveal.text', 'petition.seren_watch.text',
                                     'petition.stranger_gate.text')}

# The old premise in DESIGN.md (the lord a lamplighter, crowned because nobody else wanted it, the circlet too big).
DESIGN_PREMISE = FORBIDDEN + [
    ('nobody wanted the crown', re.compile(r'nobody (else )?wanted the crown', re.I)),
    ('too slow to run away', re.compile(r'too slow to run away', re.I)),
    ('a little too big', re.compile(r'(circlet|crown)[^.|]{0,20}too big', re.I)),
    ('never meant to be king', re.compile(r'never meant to be', re.I)),
    ('nobody counted on', re.compile(r'nobody counted on', re.I)),
]
DESIGN_ALLOWED = {}  # DESIGN.md line -> reason

# "Thief" is always tied to the fire, never to the chair or the hall (HOUSE.md 6.4): after apply, a value that says
# the house's "thief" must also say fire/Feuer/Flame, unless it directly follows a text that does (key -> reason).
# (The clerk in odile_ledger is another thief and is not the lord's house.)
# The forms: "heir of (a|the) thief", "before the thief", "a thief"; „des Diebes", „eines Diebes", „vor dem Dieb",
# „ein Dieb" (critic 4: 9.4's "Before the thief" / „Vor dem Dieb", 9.3's „Ein Dieb"). "Hunt the thief" / „den Dieb"
# and „die Diebe" (odile_ledger, lantern_lanes) are other thieves and match none of them.
THIEF = re.compile(r'heir of (a |the )?thief|before the thief|\ba thief\b|\b(ein|d)es Diebes|\bvor dem Dieb\b|'
                   r'\bein Dieb\b', re.I)
THIEF_FIRE = re.compile(r'fire|flame|Feuer|Flamme', re.I)
THIEF_SEAT = re.compile(r'throne|chair|seat|Thron|Stuhl|Sitz', re.I)
THIEF_FOLLOWS = {'petition.herald_demand.r2': 'the reaction to herald_demand.text, which says "by {his|her} '
                                              'borrowed fire" just before it'}
PROLOGUE_MADE_PANEL = '2'  # the panel that carries "made" (HOUSE.md 6.8); only it may grow up to 25 %
PROLOGUE_MADE_GROWTH = 1.25
PROLOGUE_GROWTH = 1.15


def resolve(text, lady):
    def sub(m):
        inner = m.group(1)
        if inner == 'lord':
            return 'N' * NAME_LIMIT
        if '|' not in inner:
            return m.group(0)
        a, b = inner.split('|', 1)
        return b if lady else a
    return BRACE.sub(sub, text)


def shown_len(text):
    return max(len(resolve(text, False)), len(resolve(text, True)))


def brace_errors(text):
    errs = []
    depth = 0
    for ch in text:
        depth += ch == '{'
        depth -= ch == '}'
        if depth < 0 or depth > 1:
            errs.append('braces nested or unbalanced')
            break
    if depth != 0 and not errs:
        errs.append('braces unbalanced')
    for inner in BRACE.findall(text):
        if inner != 'lord' and inner.count('|') != 1:
            errs.append('brace {%s} is neither {lord} nor {a|b}' % inner)
    return errs


def main():
    here = os.path.dirname(os.path.abspath(__file__))
    ap = argparse.ArgumentParser()
    ap.add_argument('--game', default=os.path.dirname(here))
    ap.add_argument('--rewrite', default=None)
    args = ap.parse_args()
    rewrite = args.rewrite or os.path.join(args.game, 'docs', 'house-rewrite.json')
    strings_path = os.path.join(args.game, 'Resources', 'Story.xcstrings')
    story_path = os.path.join(args.game, 'STORY.md')
    design_path = os.path.join(args.game, 'DESIGN.md')

    problems = []
    try:
        data = json.load(open(rewrite, encoding='utf-8'))
    except Exception as e:  # noqa: BLE001
        print('FAIL: house-rewrite.json does not parse: %s' % e)
        return 1
    strings = json.load(open(strings_path, encoding='utf-8'))['strings']
    story = open(story_path, encoding='utf-8').read().split('\n')
    design = open(design_path, encoding='utf-8').read().split('\n')

    entries = data.get('strings', [])
    bible = data.get('bible', [])
    design_list = data.get('design', [])
    if set(data) != {'strings', 'bible', 'design'}:
        problems.append('top level must be exactly {"strings","bible","design"}')

    seen = set()
    changes = {'en': 0, 'de': 0}
    for i, e in enumerate(entries):
        tag = e.get('key', '#%d' % i)
        need = {'key', 'en_old', 'en_new', 'de_old', 'de_new', 'why'}
        if set(e) != need:
            problems.append('%s: fields must be %s' % (tag, sorted(need)))
            continue
        k = e['key']
        if k in seen:
            problems.append('%s: listed twice' % k)
        seen.add(k)
        if k not in strings:
            problems.append('%s: no such key' % k)
            continue
        if not e['why'].strip():
            problems.append('%s: why is empty' % k)
        for lang in ('en', 'de'):
            old, new = e[lang + '_old'], e[lang + '_new']
            try:
                cur = strings[k]['localizations'][lang]['stringUnit']['value']
            except KeyError:
                problems.append('%s: no %s value in the file' % (k, lang))
                continue
            if old != cur:
                problems.append('%s %s: old value differs from the file' % (k, lang))
            if new != old:
                changes[lang] += 1
            lo, ln = shown_len(old), shown_len(new)
            is_choice = re.match(r'^petition\.[^.]+\.c\d$', k)
            if not is_choice and ln > lo * GROWTH:
                problems.append('%s %s: new %d chars > old %d + 15 %%' % (k, lang, ln, lo))
            if is_choice and ln > CHOICE_LIMIT:
                problems.append('%s %s: choice label %d > %d' % (k, lang, ln, CHOICE_LIMIT))
            if lang == 'en':
                for rx, lim in EN_LIMITS:
                    if rx.match(k) and ln > lim:
                        problems.append('%s en: %d > text limit %d' % (k, ln, lim))
            if old.count('{lord}') != new.count('{lord}'):
                problems.append('%s %s: {lord} not kept' % (k, lang))
            if sorted(PRINTF.findall(old)) != sorted(PRINTF.findall(new)):
                problems.append('%s %s: printf placeholders not kept' % (k, lang))
            if old.count('\n') != new.count('\n'):
                problems.append('%s %s: line breaks not kept' % (k, lang))
            if (any('|' in b for b in BRACE.findall(old)) and not any('|' in b for b in BRACE.findall(new))
                    and k not in FORMS_DROPPED):
                problems.append('%s %s: had male and female forms, new value has none' % (k, lang))
            for err in brace_errors(new):
                problems.append('%s %s: %s' % (k, lang, err))

    bible_seen = set()
    for i, b in enumerate(bible):
        if set(b) != {'line', 'old', 'new'}:
            problems.append('bible #%d: fields must be line, old, new' % i)
            continue
        n = b['line']
        if n in bible_seen:
            problems.append('bible line %d listed twice' % n)
        bible_seen.add(n)
        if not isinstance(n, int) or n < 1 or n > len(story):
            problems.append('bible line %r out of range' % n)
            continue
        if story[n - 1] != b['old']:
            problems.append('bible line %d: old differs from STORY.md' % n)
        if '\n' in b['new']:
            problems.append('bible line %d: new must be one line' % n)

    # Prologue panels (STORY.md section 8): the text column may grow 15 % at most; panel 2 ("made") up to 25 %,
    # and over 15 % there is flagged for the panels lane.
    pro_start = next((i for i, s in enumerate(story) if s.startswith('## 8. The prologue')), None)
    pro_end = next((i for i, s in enumerate(story) if pro_start is not None and i > pro_start and s.startswith('## ')),
                   len(story))
    prologue = []
    for b in bible:
        n = b.get('line')
        if pro_start is None or not isinstance(n, int) or not (pro_start < n - 1 < pro_end):
            continue
        cells_old, cells_new = b['old'].split('|'), b['new'].split('|')
        if len(cells_old) < 4 or len(cells_new) != len(cells_old) or not cells_old[1].strip().isdigit():
            problems.append('bible line %d: prologue row must keep its columns' % n)
            continue
        lo, ln = len(cells_old[2].strip()), len(cells_new[2].strip())
        panel = cells_old[1].strip()
        made = panel == PROLOGUE_MADE_PANEL
        flag = made and ln > lo * PROLOGUE_GROWTH
        prologue.append((n, panel, lo, ln, flag))
        if ln > lo * (PROLOGUE_MADE_GROWTH if made else PROLOGUE_GROWTH):
            problems.append('bible line %d: prologue panel %s text %d chars > old %d + %d %%'
                            % (n, panel, ln, lo, 25 if made else 15))

    design_seen = set()
    for i, b in enumerate(design_list):
        if set(b) != {'line', 'old', 'new'}:
            problems.append('design #%d: fields must be line, old, new' % i)
            continue
        n = b['line']
        if n in design_seen:
            problems.append('design line %d listed twice' % n)
        design_seen.add(n)
        if not isinstance(n, int) or n < 1 or n > len(design):
            problems.append('design line %r out of range' % n)
            continue
        if design[n - 1] != b['old']:
            problems.append('design line %d: old differs from DESIGN.md' % n)
        if '\n' in b['new']:
            problems.append('design line %d: new must be one line' % n)
        if b['new'] == b['old']:
            problems.append('design line %d: new equals old' % n)

    applied = {k: {lang: v['localizations'][lang]['stringUnit']['value']
                   for lang in ('en', 'de') if lang in v.get('localizations', {})}
               for k, v in strings.items()}
    for e in entries:
        if e.get('key') in applied:
            applied[e['key']]['en'] = e['en_new']
            applied[e['key']]['de'] = e['de_new']
    left = 0
    for k, langs in sorted(applied.items()):
        for lang, v in langs.items():
            for name, rx in FORBIDDEN:
                if rx.search(v) and k not in ALLOWED:
                    left += 1
                    problems.append('after apply, %s %s still says "%s": %s' % (k, lang, name, v))

    thief_keys = 0
    for k, langs in sorted(applied.items()):
        for lang, v in langs.items():
            if not THIEF.search(v):
                continue
            thief_keys += lang == 'en'
            if THIEF_SEAT.search(v):
                problems.append('after apply, %s %s ties "thief" to the chair or the hall: %s' % (k, lang, v))
            if not THIEF_FIRE.search(v) and k not in THIEF_FOLLOWS:
                problems.append('after apply, %s %s says "thief" without the fire: %s' % (k, lang, v))

    story_after = list(story)
    for b in bible:
        if isinstance(b.get('line'), int) and 1 <= b['line'] <= len(story_after):
            story_after[b['line'] - 1] = b['new']
    bible_left = [(i + 1, s) for i, s in enumerate(story_after) if re.search(r'lamp-?lighter', s, re.I)]

    design_after = list(design)
    for b in design_list:
        if isinstance(b.get('line'), int) and 1 <= b['line'] <= len(design_after):
            design_after[b['line'] - 1] = b['new']
    design_left = []
    for i, s in enumerate(design_after):
        for name, rx in DESIGN_PREMISE:
            if rx.search(s) and (i + 1) not in DESIGN_ALLOWED:
                design_left.append((i + 1, name, s))
                problems.append('after apply, DESIGN.md line %d still states the old premise ("%s"): %s'
                                % (i + 1, name, s.strip()[:110]))

    print('house-rewrite check')
    print('  strings: %d keys (%d English and %d German values change)' % (len(entries), changes['en'], changes['de']))
    print('  bible:   %d STORY.md lines' % len(bible))
    print('  scanned: %d keys x en+de after apply; forbidden words left: %d' % (len(applied), left))
    print('  "thief" values (en): %d, each tied to the fire or following one that is (%d by reason)'
          % (thief_keys, len(THIEF_FOLLOWS)))
    print('  STORY.md lines still saying "lamplighter" after apply (old title, option B, the town\'s lamplighter): %d'
          % len(bible_left))
    for n, s in bible_left:
        print('    %d: %s' % (n, s.strip()[:110]))
    print('  prologue panels changed: %d' % len(prologue))
    for n, panel, lo, ln, flag in prologue:
        print('    STORY.md %d, panel %s: %d -> %d chars%s' % (n, panel, lo, ln,
              ' (over 15 %: FLAG for the panels lane)' if flag else ''))
    print('  forms dropped by reason: %d keys' % sum(1 for e in entries if e.get('key') in FORMS_DROPPED))
    print('  design:  %d DESIGN.md lines; lines still stating the old premise after apply: %d'
          % (len(design_list), len(design_left)))
    if problems:
        print('FAIL: %d problem(s)' % len(problems))
        for p in problems:
            print('  - ' + p)
        return 1
    print('ALL PASSED')
    return 0


if __name__ == '__main__':
    sys.exit(main())
