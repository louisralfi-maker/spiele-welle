# Hello (runner canary, never shipped)

The smallest app with every part a game has: logic in `Core/`, a String Catalog (en, de), unit tests, a UI test that saves
a screenshot per language, and a Release build. It proves the round trip to GitHub's Mac:

```sh
scripts/ci/remote-check.sh hello hello-<n> ci-out/hello-<n> build unit ui ui-de release
```

A new game's `project.yml` starts from this one.
