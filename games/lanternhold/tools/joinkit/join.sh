#!/bin/bash
# Lanternhold join: merge the lane branches in the fixed order, one merge commit each.
#
#   join.sh [--start <ref>] [--only-check] [<branch> ...]
#
# Run it inside the worktree that receives the join (its working tree must be clean).
#   --start <ref>   first reset this worktree's branch to <ref> (only for a rehearsal branch!)
#   --only-check    merge without committing, report, then abort each merge (nothing changes)
#   <branch> ...    the order; without it the planned order below.
#
# On a conflict:
#   *.xcstrings     merged by merge_xcstrings.py (per key and language; both-changed
#                   values take theirs = the incoming lane, listed in the log; stale
#                   translations are marked needs_review)
#   any text file   hunks where both lanes only added lines are kept, ours then theirs
#                   (resolve_appends.py); the log lists them so the order can be checked
#   anything else   the script stops with the merge open; resolve, commit, run again with
#                   the remaining branches.
# The log is joinkit-log.txt in the repo's git dir (never committed).
set -u
here="$(cd "$(dirname "$0")" && pwd)"
PY=/usr/bin/python3
export GIT_AUTHOR_NAME="Louis Herwick" GIT_AUTHOR_EMAIL="279105910+louisralfi-maker@users.noreply.github.com"
export GIT_COMMITTER_NAME="$GIT_AUTHOR_NAME" GIT_COMMITTER_EMAIL="$GIT_AUTHOR_EMAIL"

ORDER=(claude/lh-world claude/lh-stage claude/lh-i18n claude/lh-q claude/lh-ads claude/lh-panels
       claude/lh-town claude/lh-craft claude/lh-people claude/lh-front claude/lh-house claude/lh-store
       claude/game2-planning-354541)

start="" check=0 plan=()
while [ $# -gt 0 ]; do
  case "$1" in
    --start) start="$2"; shift 2 ;;
    --only-check) check=1; shift ;;
    -h|--help) sed -n 2,20p "$0"; exit 0 ;;
    *) plan+=("$1"); shift ;;
  esac
done
[ ${#plan[@]} -eq 0 ] && plan=("${ORDER[@]}")

top="$(git rev-parse --show-toplevel)" || exit 2
cd "$top"
log="$(git rev-parse --git-dir)/joinkit-log.txt"
if [ -n "$(git status --porcelain --untracked-files=no)" ]; then
  echo "join.sh: the working tree is not clean" >&2; exit 2
fi
if [ -n "$start" ]; then git reset -q --hard "$start" || exit 2; fi
echo "# join $(date '+%Y-%m-%d %H:%M') on $(git rev-parse --abbrev-ref HEAD) from $(git rev-parse --short HEAD)" >> "$log"

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
for br in "${plan[@]}"; do
  sha="$(git rev-parse --verify -q "$br^{commit}")" || { echo "join.sh: no branch $br" | tee -a "$log"; exit 2; }
  if git merge-base --is-ancestor "$sha" HEAD; then
    echo "== $br $sha: already in" | tee -a "$log"; continue
  fi
  echo "== $br $sha" | tee -a "$log"
  git merge --no-ff --no-commit "$sha" > "$tmp/out" 2>&1
  grep -E "^CONFLICT" "$tmp/out" | sed 's/^/   /' | tee -a "$log"
  left=()
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    case "$f" in
      *.xcstrings)
        for s in 1 2 3; do git show ":$s:$f" > "$tmp/s$s" 2>/dev/null || : > "$tmp/s$s"; done
        if "$PY" -I "$here/merge_xcstrings.py" "$tmp/s1" "$tmp/s2" "$tmp/s3" -o "$f" \
             --prefer theirs --mark-stale --quiet --report "$tmp/xr"; then
          echo "   xcstrings merged clean: $f" | tee -a "$log"
        else
          echo "   xcstrings merged, conflicts took theirs: $f" | tee -a "$log"
        fi
        [ -f "$tmp/xr" ] && sed 's/^/     /' "$tmp/xr" >> "$log" && rm -f "$tmp/xr"
        git add "$f" ;;
      *)
        if git checkout --conflict=diff3 -- "$f" 2>/dev/null && grep -Iq . "$f" 2>/dev/null \
           && "$PY" -I "$here/resolve_appends.py" "$f" > "$tmp/ra" 2>&1; then
          echo "   append+append kept (ours, then theirs; check the order): $f" | tee -a "$log"
          git add "$f"
        else
          left+=("$f")
        fi ;;
    esac
  done < <(git diff --name-only --diff-filter=U)
  if [ ${#left[@]} -gt 0 ]; then
    printf '   NEEDS A PERSON: %s\n' "${left[@]}" | tee -a "$log"
    if [ $check -eq 1 ]; then git merge --abort; continue; fi
    echo "join.sh: stopped at $br with the merge open; resolve, commit, then run again with the remaining branches." | tee -a "$log"
    exit 1
  fi
  if [ $check -eq 1 ]; then git merge --abort; continue; fi
  git commit -q -m "Lanternhold join: merge $br (${sha:0:7})" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>" || exit 2
done
echo "== done at $(git rev-parse --short HEAD)" | tee -a "$log"
