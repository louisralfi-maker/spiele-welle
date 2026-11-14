# joinkit: the lane join, made mechanical

Plain Python 3 and bash, standard library only. Nothing here builds or compiles; it runs on the old Mac.

| file | what it does |
|---|---|
| `join.sh` | merges the lane branches in the fixed order into the current worktree, one merge commit each (Louis' noreply identity) |
| `merge_xcstrings.py` | three-way merge of `.xcstrings` catalogs, per key and per language, in Xcode's formatting |
| `resolve_appends.py` | resolves conflict hunks where both lanes only added lines at the same place (ours, then theirs) |
| `selftest.py` | the fixtures; `/usr/bin/python3 -I -B selftest.py` prints `selftest passed` in about 0.2 s |

## The join

```sh
cd <the worktree that receives the join>          # clean working tree
bash games/lanternhold/tools/joinkit/join.sh      # the planned order
bash games/lanternhold/tools/joinkit/join.sh claude/lh-craft claude/lh-people   # the rest, after a stop
```

The order: world, stage, i18n, q (the quests lane's live branch; `claude/lh-quests` is an old docs branch),
ads, panels, town, craft, people, front, house, store, then the planning branch. A branch already contained is
skipped. On a conflict the script resolves what is mechanical and stops on anything else with the merge open:

- `*.xcstrings`: `merge_xcstrings.py --prefer theirs --mark-stale` (the incoming lane wins a value both changed;
  each such value is listed in the log).
- any text file: `resolve_appends.py` on hunks whose base is empty (both lanes appended). The log names the file:
  check the order (z-order in a view, case order in a switch).
- everything else, and any hunk that changes old lines: the script stops. Resolve by hand, commit, run again with
  the remaining branches.

The log is `joinkit-log.txt` in the worktree's git dir. `--start <ref>` resets the branch first (rehearsals only).
`--only-check` merges each branch against the current head without committing and aborts it again.

## merge_xcstrings.py

```sh
merge_xcstrings.py BASE OURS THEIRS [-o OUT] [--prefer ours|theirs] [--report FILE] [--strict] [--mark-stale]
```

- A key or language added on either side is kept; a value changed on one side takes that side; a key deleted on
  one side and untouched on the other is deleted.
- A value changed differently on both sides is a conflict: listed in the report, the `--prefer` side taken
  (default ours). `--strict` writes nothing and exits 1.
- Stale translations: one side changes a key's English while the other adds or changes another language of the
  same key. Listed as `STALE key [lang]`; `--mark-stale` sets that translation's state to `needs_review`.
- Output in Xcode's format (two spaces, `" : "`, no ASCII escapes, OURS's final newline); OURS's key order is kept
  and new keys go where the sorted order puts them. When THEIRS changed nothing, the output is OURS byte for byte
  (checked on the real `Story.xcstrings`).
- Exit 0 clean, 1 conflicts, 2 unreadable input. BASE may be missing (add/add).

As a git merge driver (optional, per command, never in git config):
`git -c merge.xcstrings.driver='python3 -I tools/joinkit/merge_xcstrings.py %O %A %B --mark-stale' merge ...`
with `*.xcstrings merge=xcstrings` in `.git/info/attributes`.
