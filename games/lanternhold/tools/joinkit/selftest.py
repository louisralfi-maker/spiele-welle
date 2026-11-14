#!/usr/bin/env python3
"""Self-test of merge_xcstrings.py and resolve_appends.py on small fixtures (runs in well under a second).

    /usr/bin/python3 -I -B selftest.py
"""
import contextlib
import io
import json
import os
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import merge_xcstrings as mx  # noqa: E402
import resolve_appends as ra  # noqa: E402


def unit(en, de=None, state="translated", **more):
    locs = {}
    if de is not None:
        locs["de"] = {"stringUnit": {"state": state, "value": de}}
    locs["en"] = {"stringUnit": {"state": "translated", "value": en}}
    for lang, v in more.items():
        locs[lang.replace("_", "-")] = {"stringUnit": {"state": "translated", "value": v}}
    return {"extractionState": "manual", "localizations": dict(sorted(locs.items()))}


def cat(strings):
    return {"sourceLanguage": "en", "strings": strings, "version": "1.0"}


BASE = cat({
    "a.keep": unit("Keep", "Behalten"),
    "b.ours": unit("Old", "Alt"),
    "c.theirs": unit("Old", "Alt"),
    "d.both": unit("Old", "Alt"),
    "e.gone": unit("Gone", "Weg"),
    "f.fr": unit("Bread", "Brot"),
    "g.stale": unit("Lamp", "Lampe"),
})
OURS = cat({
    "a.keep": unit("Keep", "Behalten"),
    "aa.new_ours": unit("Ours", "Unseres"),
    "b.ours": unit("New", "Neu"),
    "c.theirs": unit("Old", "Alt"),
    "d.both": unit("Ours", "Unseres"),
    "f.fr": unit("Bread", "Brot!"),
    "g.stale": unit("Lantern", "Laterne"),
})
THEIRS = cat({
    "a.keep": unit("Keep", "Behalten"),
    "b.ours": unit("Old", "Alt"),
    "c.theirs": unit("New", "Neu"),
    "ca.new_theirs": unit("Theirs", "Ihres"),
    "d.both": unit("Theirs", "Ihres"),
    "e.gone": unit("Gone", "Weg"),
    "f.fr": unit("Bread", "Brot", fr="Pain"),
    "g.stale": unit("Lamp", "Lampe", fr="Lampe"),
    "z.last": unit("Z", "Z"),
})


def write(d, path, nl=True):
    with open(path, "w", encoding="utf-8") as f:
        f.write(mx.dump(d, nl))


def run(argv):
    err = io.StringIO()
    with contextlib.redirect_stderr(err):
        code = mx.main(argv)
    return code, err.getvalue()


def main():
    failures = []

    def check(cond, what):
        if not cond:
            failures.append(what)

    with tempfile.TemporaryDirectory() as t:
        p = {n: os.path.join(t, n + ".xcstrings") for n in ("base", "ours", "theirs", "out")}
        write(BASE, p["base"])
        write(OURS, p["ours"])
        write(THEIRS, p["theirs"])

        # 1. the full case, conflicts taking ours
        rep = os.path.join(t, "report.txt")
        code, _ = run([p["base"], p["ours"], p["theirs"], "-o", p["out"], "--report", rep, "--mark-stale"])
        out = json.load(open(p["out"], encoding="utf-8"))
        s = out["strings"]
        check(code == 1, "exit code 1 on a conflict")
        check(list(s) == ["a.keep", "aa.new_ours", "b.ours", "c.theirs", "ca.new_theirs", "d.both", "f.fr",
                          "g.stale", "z.last"], f"key order: {list(s)}")
        en = lambda k: s[k]["localizations"]["en"]["stringUnit"]["value"]  # noqa: E731
        check(en("b.ours") == "New", "changed on ours only takes ours")
        check(en("c.theirs") == "New", "changed on theirs only takes theirs")
        check(en("d.both") == "Ours", "both changed takes --prefer ours")
        check("e.gone" not in s, "deleted on one side, untouched on the other: deleted")
        check(s["f.fr"]["localizations"]["fr"]["stringUnit"]["value"] == "Pain", "French added on theirs kept")
        check(s["f.fr"]["localizations"]["de"]["stringUnit"]["value"] == "Brot!", "German fixed on ours kept")
        check(list(s["f.fr"]["localizations"]) == ["de", "en", "fr"], "languages in sorted order")
        check(s["g.stale"]["localizations"]["fr"]["stringUnit"]["state"] == "needs_review", "stale French marked")
        check(s["f.fr"]["localizations"]["fr"]["stringUnit"]["state"] == "translated", "fresh French not marked")
        report = open(rep, encoding="utf-8").read()
        check("CONFLICT d.both" in report and "STALE g.stale [fr]" in report, "report lists conflict and stale")
        check(report.count("CONFLICT") == 2, f"two conflicting leaves (en, de of d.both): {report}")

        # 2. --prefer theirs, --strict
        code, _ = run([p["base"], p["ours"], p["theirs"], "-o", p["out"], "--prefer", "theirs", "--quiet"])
        check(json.load(open(p["out"], encoding="utf-8"))["strings"]["d.both"]["localizations"]["en"]
              ["stringUnit"]["value"] == "Theirs", "--prefer theirs")
        os.remove(p["out"])
        code, _ = run([p["base"], p["ours"], p["theirs"], "-o", p["out"], "--strict", "--quiet"])
        check(code == 1 and not os.path.exists(p["out"]), "--strict writes nothing")

        # 3. nothing changed on theirs: output byte for byte ours
        write(BASE, p["theirs"])
        code, _ = run([p["base"], p["ours"], p["theirs"], "-o", p["out"]])
        check(code == 0 and open(p["out"], "rb").read() == open(p["ours"], "rb").read(), "identity is byte exact")

        # 4. add/add with no base, and no final newline kept
        write(cat({"x": unit("X")}), p["ours"], nl=False)
        write(cat({"y": unit("Y")}), p["theirs"])
        code, _ = run([os.path.join(t, "missing"), p["ours"], p["theirs"], "-o", p["out"]])
        raw = open(p["out"], encoding="utf-8").read()
        check(code == 0 and list(json.loads(raw)["strings"]) == ["x", "y"] and not raw.endswith("\n"), "add/add")
        check('"sourceLanguage" : "en"' in raw and "\n  \"strings\" : {" in raw, "Xcode's separators and indent")

        # 5. resolve_appends: an append+append hunk and a real one
        doc = ("head\n<<<<<<< ours\nA1\n||||||| base\n=======\nB1\n>>>>>>> theirs\nmid\n"
               "<<<<<<< ours\nx = 1\n||||||| base\nx = 0\n=======\nx = 2\n>>>>>>> theirs\ntail\n")
        new, left = ra.resolve(doc, prose=False)
        check(left == 1 and new.startswith("head\nA1\nB1\nmid\n<<<<<<< ours"), "resolve_appends keeps a real conflict")
        new, left = ra.resolve("<<<<<<< o\n# A\n||||||| b\n=======\n# B\n>>>>>>> t\n", prose=True)
        check(left == 0 and new == "# A\n\n# B\n", "prose appends get a blank line")

    if failures:
        print("selftest FAILED:\n- " + "\n- ".join(failures))
        return 1
    print("selftest passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
