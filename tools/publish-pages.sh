#!/bin/bash
# Publishes the committed pages/ folder (every game's support and privacy page) to the gh-pages branch, which GitHub
# Pages serves at https://louisralfi-maker.github.io/spiele-welle/. Publishing is an outward step and the pages are
# legal texts in Louis' name: run it only with his go.
# Usage: tools/publish-pages.sh
set -eu
cd "$(dirname "$0")/.."
URL=${GW_PAGES_REMOTE:-git@github.com:louisralfi-maker/spiele-welle.git}
export GIT_SSH_COMMAND="ssh -i $HOME/.ssh/id_ed25519_games -o IdentitiesOnly=yes"
git cat-file -e HEAD:pages/.nojekyll 2>/dev/null || { echo "HEAD has no pages/.nojekyll: commit pages/ first"; exit 2; }
[ -z "$(git status --porcelain -- pages)" ] || { echo "pages/ has uncommitted changes: commit them first"; exit 2; }
TREE=$(git rev-parse 'HEAD:pages')
# gh-pages keeps its history, so every publish is a fast-forward (never a force-push)
PARENT=""
if git ls-remote --exit-code "$URL" refs/heads/gh-pages >/dev/null; then
    git fetch -q "$URL" refs/heads/gh-pages
    [ "$(git rev-parse 'FETCH_HEAD^{tree}')" != "$TREE" ] || { echo "gh-pages already has these pages"; exit 0; }
    PARENT="-p $(git rev-parse FETCH_HEAD)"
fi
WHO="Louis Herwick"; MAIL="279105910+louisralfi-maker@users.noreply.github.com"
MSG=$(printf 'Pages from %s\n\nCo-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>\n' "$(git rev-parse --short HEAD)")
# shellcheck disable=SC2086 # PARENT is empty or one "-p <sha>" pair
C=$(printf '%s\n' "$MSG" | env GIT_AUTHOR_NAME="$WHO" GIT_AUTHOR_EMAIL="$MAIL" GIT_COMMITTER_NAME="$WHO" \
    GIT_COMMITTER_EMAIL="$MAIL" git commit-tree "$TREE" $PARENT)
git push -q "$URL" "$C:refs/heads/gh-pages"
echo "published $C to gh-pages; live in about a minute at https://louisralfi-maker.github.io/spiele-welle/"
