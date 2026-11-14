#!/usr/bin/env python3
"""Resolve "both sides appended" merge conflicts: keep ours, then theirs.

    resolve_appends.py FILE [FILE ...] [--check]

FILE must hold diff3-style conflict markers (git checkout --conflict=diff3 FILE).
A hunk is resolved only when its base part is empty, i.e. both lanes added new
lines at the same place and changed nothing old. Ours comes first, a blank line
between when both parts are prose (Markdown). Any hunk with a non-empty base is
left as it is and the file is reported.

Exit codes: 0 every hunk resolved, 1 some hunk needs a person, 2 error.
With --check nothing is written.
"""
import sys

OPEN, BASE, MID, CLOSE = "<<<<<<< ", "||||||| ", "=======", ">>>>>>> "


def resolve(text, prose):
    out, i, left = [], 0, 0
    lines = text.splitlines(keepends=True)
    while i < len(lines):
        ln = lines[i]
        if not ln.startswith(OPEN):
            out.append(ln)
            i += 1
            continue
        ours, base, theirs, part, j = [], [], [], "ours", i + 1
        has_base = False
        while j < len(lines) and not lines[j].startswith(CLOSE):
            l = lines[j]
            if l.startswith(BASE) and part == "ours":
                part, has_base = "base", True
            elif l.rstrip("\r\n") == MID and part in ("ours", "base"):
                part = "theirs"
            else:
                {"ours": ours, "base": base, "theirs": theirs}[part].append(l)
            j += 1
        if j >= len(lines):
            raise ValueError("unterminated conflict")
        if has_base and not any(b.strip() for b in base):
            if ours and not ours[-1].endswith("\n"):
                ours[-1] += "\n"
            sep = ["\n"] if prose and ours and theirs and ours[-1].strip() and theirs[0].strip() else []
            out.extend(ours + sep + theirs)
        else:
            out.extend(lines[i:j + 1])
            left += 1
        i = j + 1
    return "".join(out), left


def main(argv):
    check = "--check" in argv
    files = [a for a in argv if a != "--check"]
    if not files:
        print(__doc__, file=sys.stderr)
        return 2
    status = 0
    for f in files:
        try:
            with open(f, encoding="utf-8") as fh:
                text = fh.read()
            new, left = resolve(text, f.endswith(".md"))
        except (OSError, ValueError, UnicodeDecodeError) as e:
            print(f"resolve_appends: {f}: {e}", file=sys.stderr)
            return 2
        if left:
            print(f"{f}: {left} hunk(s) change old lines; resolve by hand")
            status = 1
        else:
            print(f"{f}: resolved (append + append)")
        if not check and new != text:
            with open(f, "w", encoding="utf-8") as fh:
                fh.write(new)
    return status


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
