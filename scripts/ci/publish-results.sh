#!/bin/bash
# Pushes ci-out/ to the branch ci-results/<label> as one parentless commit. remote-check.sh waits for that branch.
set -u
LABEL=${GITHUB_REF_NAME#ci/}
mkdir -p ci-out
[ -f ci-out/summary.txt ] || echo "FAILED: the run stopped before its first step" >ci-out/summary.txt
tail -1 ci-out/summary.txt | grep -qE '^(ALL PASSED|FAILED)' || echo "FAILED: the run stopped early" >>ci-out/summary.txt
cd ci-out
git init -q
git checkout -q --orphan results
git add .
git -c user.name="Sim check" -c user.email="noreply@github.com" commit -q -m "Results of $LABEL"
git push -q "https://x-access-token:$GITHUB_TOKEN@github.com/$GITHUB_REPOSITORY.git" "HEAD:refs/heads/ci-results/$LABEL"
