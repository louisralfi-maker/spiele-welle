#!/usr/bin/env python3
"""Checks the App Store listing texts in games/lanternhold/store/listing/<lang>.md against Apple's limits.

Each file has sections '## Name', '## Subtitle', '## Promotional text', '## Description', '## Keywords' and
"## What's New (1.0)", each with its text in a ```text fence. Lines that start with '[if shipped]' are parts not in the
build yet. Every limit is checked twice: with those lines kept (marker removed) and with them cut.

Limits (Apple, App Store Connect help, read 14.11.2026): name 2 to 30 characters, subtitle 30, promotional text 170,
description 4000, What's New 4000, keywords 100 bytes (UTF-8 counted here, the strict reading) with every keyword
longer than two characters, no app name or company name in the keywords, no names of other apps or companies.

Usage: python3 check_listing.py [--final] [lang ...]
  --final  also fails on any '[if shipped]' marker still in a text (run it before pasting into App Store Connect).
Exit 0 when every check passes. Standard library only.
"""
import os
import re
import sys
import unicodedata

HERE = os.path.dirname(os.path.abspath(__file__))
LISTING = os.path.join(HERE, '..', 'listing')
LANGS = ['en', 'de', 'fr', 'es', 'it', 'pt-BR', 'ja', 'zh-Hans']
FIELDS = {
    'Name': ('name', 30),
    'Subtitle': ('subtitle', 30),
    'Promotional text': ('promo', 170),
    'Description': ('description', 4000),
    'Keywords': ('keywords', 100),
    "What's New (1.0)": ('whatsnew', 4000),
}
MARK = '[if shipped]'
# Other games and brands of the genre that a listing must never name or lean on (lowercase, matched as words).
BANNED = ['kingdom', 'two crowns', 'new lands', 'your grace', 'reigns', 'stronghold', 'frostpunk', 'bad north',
          'billions', 'clash of', 'rush royale', 'kingdom rush', 'raven software', 'noio', 'raw fury', 'apple', 'google']
CJK = {'ja', 'zh-Hans'}


def parse(path):
    text = open(path, encoding='utf-8').read()
    out = {}
    for m in re.finditer(r'^## (.+?)\n+```text\n(.*?)\n```', text, re.S | re.M):
        head = m.group(1).strip()
        if head in FIELDS:
            out[FIELDS[head][0]] = m.group(2)
    return out


def variant(s, keep):
    lines = []
    for line in s.split('\n'):
        if line.startswith(MARK):
            if keep:
                lines.append(line[len(MARK):].lstrip())
        else:
            lines.append(line)
    return re.sub(r'\n{3,}', '\n\n', '\n'.join(lines)).strip('\n')


def chars(s):
    return len(unicodedata.normalize('NFC', s))


def words(s):
    return {w for w in re.findall(r"[\w'’-]+", s.lower()) if w}


def check(lang, final):
    errors, notes = [], []
    path = os.path.join(LISTING, lang + '.md')
    if not os.path.exists(path):
        return ['missing file ' + path], notes
    f = parse(path)
    for key, (field, _) in FIELDS.items():
        if field not in f or not f[field].strip():
            errors.append('missing or empty: ' + key)
    if errors:
        return errors, notes
    for field in ('name', 'subtitle', 'promo', 'keywords'):
        if MARK in f[field]:
            errors.append(field + ' carries an [if shipped] marker; keep these fields to what is built')
    if final:
        for field, s in f.items():
            if MARK in s:
                errors.append(field + ': [if shipped] marker left (decide: cut the line or drop the marker)')
    for keep in (True, False):
        tag = 'kept' if keep else 'cut'
        v = {k: variant(s, keep) for k, s in f.items()}
        for key, (field, limit) in FIELDS.items():
            if field == 'keywords':
                n = len(v[field].encode('utf-8'))
                unit = 'bytes'
            else:
                n = chars(v[field])
                unit = 'chars'
            if n > limit:
                errors.append('%s (%s): %d %s > %d' % (key, tag, n, unit, limit))
            if keep:
                notes.append('%-18s %5d %s (limit %d)' % (key, n, unit, limit))
        if not keep:
            notes.append('%-18s %5d chars when every [if shipped] line is cut' % ('Description', chars(v['description'])))
    name = f['name'].strip()
    if chars(name) < 2:
        errors.append('name shorter than 2 characters')
    kw_raw = f['keywords'].strip()
    if '\n' in kw_raw:
        errors.append('keywords on more than one line')
    seps = re.split(r'[,，]', kw_raw)
    kws = [k.strip() for k in seps]
    if any(k != k.strip() or k == '' for k in seps):
        errors.append('keywords: empty entry or a space next to a comma (spaces cost bytes)')
    low = [k.lower() for k in kws]
    if len(set(low)) != len(low):
        errors.append('keywords: duplicates')
    for k in kws:
        if chars(k) <= 2:
            errors.append('keyword "%s" has two characters or fewer' % k)
        if 'lanternhold' in k.lower():
            errors.append('keyword "%s" repeats the app name' % k)
    sub = f['subtitle'].strip()
    if lang in CJK:
        for k in kws:
            if k in sub:
                errors.append('keyword "%s" already stands in the subtitle' % k)
    else:
        dup = words(sub) & set(low)
        for k in sorted(dup):
            errors.append('keyword "%s" already stands in the subtitle' % k)
    alltext = '\n'.join(f.values()).lower()
    for b in BANNED:
        if re.search(r'(?<![\w])' + re.escape(b) + r'(?![\w])', alltext):
            errors.append('names another game, company or brand: "%s"' % b)
    first3 = variant(f['description'], False).split('\n')[:3]
    notes.append('first three lines: ' + ' | '.join(str(chars(x)) for x in first3) + ' chars')
    notes.append('keywords: %d entries' % len(kws))
    return errors, notes


def main():
    args = sys.argv[1:]
    final = '--final' in args
    langs = [a for a in args if not a.startswith('--')] or LANGS
    bad = 0
    for lang in langs:
        errors, notes = check(lang, final)
        print('== %s: %s' % (lang, 'OK' if not errors else '%d problem(s)' % len(errors)))
        for n in notes:
            print('   ' + n)
        for e in errors:
            print('   ERROR ' + e)
        bad += len(errors)
    print('ALL OK' if not bad else 'FAILED: %d problem(s)' % bad)
    sys.exit(1 if bad else 0)


if __name__ == '__main__':
    main()
