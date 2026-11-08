#!/bin/bash
# Checks one game at HEAD on GitHub's Mac runner and waits for the verdict. Nothing here changes: no file, no branch.
# Usage: scripts/ci/remote-check.sh <game> <label> <outdir> <step>...   (steps: see run-check.sh; labels are single use)
#   e.g. scripts/ci/remote-check.sh hello hello-1 ci-out/hello-1 build unit ui ui-de release
# Prints summary.txt, unpacks all results into <outdir>, exits 0 only on "ALL PASSED". A cold build takes about ten minutes,
# so run it in the background. Put all steps of a round into one call.
set -u
[ $# -ge 4 ] || { echo "usage: $0 <game> <label> <outdir> <step>..."; exit 2; }
GAME=$1; LABEL=$2; OUT=$3; shift 3
URL=${GW_CI_REMOTE:-git@github.com:louisralfi-maker/spiele-welle.git}
export GIT_SSH_COMMAND="ssh -i $HOME/.ssh/id_ed25519_games -o IdentitiesOnly=yes"
DEADLINE=$(( $(date +%s) + ${GW_CI_WAIT_MIN:-130} * 60 ))
git cat-file -e HEAD:scripts/ci/run-check.sh 2>/dev/null || { echo "HEAD has no scripts/ci: merge main first"; exit 2; }
git cat-file -e "HEAD:games/$GAME/project.yml" 2>/dev/null || { echo "HEAD has no games/$GAME/project.yml: commit it first"; exit 2; }
SHA=$(git rev-parse --short HEAD)
MSG=$(printf 'Sim check %s\n\ngame: %s\ntested: %s\nsource: %s\n' "$LABEL" "$GAME" "$SHA" "$(git rev-parse --abbrev-ref HEAD)"
      for S in "$@"; do echo "do: $S"; done)
# The repo is public: the wrapper commit carries Louis' GitHub noreply address, never his real e-mail.
WHO="Louis Herwick"; MAIL="279105910+louisralfi-maker@users.noreply.github.com"
C=$(printf '%s\n' "$MSG" | env GIT_AUTHOR_NAME="$WHO" GIT_AUTHOR_EMAIL="$MAIL" GIT_COMMITTER_NAME="$WHO" \
    GIT_COMMITTER_EMAIL="$MAIL" git commit-tree 'HEAD^{tree}' -p HEAD)
git push -q "$URL" "$C:refs/heads/ci/$LABEL" || exit 2
echo "sent $SHA ($GAME) as ci/$LABEL at $(date +%H:%M:%S), waiting"
while ! git ls-remote "$URL" "refs/heads/ci-results/$LABEL" 2>/dev/null | grep -q .; do
    [ "$(date +%s)" -lt "$DEADLINE" ] || { echo "TIMEOUT: no result for ci/$LABEL"; exit 3; }
    /bin/sleep 30
done
TMP=$(mktemp -d)
mkdir -p "$OUT"
git init -q --bare "$TMP/r" && git -C "$TMP/r" fetch -q --depth=1 "$URL" "refs/heads/ci-results/$LABEL" && git -C "$TMP/r" archive FETCH_HEAD | tar -x -C "$OUT"
rm -rf "$TMP"
cat "$OUT/summary.txt"
tail -1 "$OUT/summary.txt" | grep -q '^ALL PASSED'
