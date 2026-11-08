# Comet Cargo

Launch a cargo rocket, drop each stage at the right moment, and release every satellite exactly inside a glowing orbit
ring. Higher rings pay more; satellites still aboard when the rocket stalls are lost. Retro space-age poster look.

- Design: `DESIGN.md`
- Status: 0.2 (review fixes) written, not yet built on the runner. 0.1 built and passed every test on the runner. 0.2:
  the cargo hatch is the release point, touch-down input, in-band cues (rings, hatch, release button), a readable tank
  gauge with a drop cue beside the rocket, ring bands that grow with speed, predicted apex, fast-forward after the
  cargo, results with ring progress and the next upgrade, hangar with every row above the Launch bar, tolerant save with
  a corrupt-file backup, more unit and UI tests (manual controls, filmstrip).
- Tuning: `python3 tools/tune.py` mirrors the Swift sim and prints every tuning target (starter apex 120.7 km in 23.0 s,
  maxed 1498 km in 86.8 s, ring crossings 0.88 to 2.53 s, early/late drops −44 %/−12 %, 4 to 9 % per engine or tank
  level, economy bot reaches ring 15 after 112 flights). Deviations from the design's start values: engines ×1.035 and
  tanks ×1.06 per level (geometric), new stages grow the stack under the same capsule, prices 60 × 1.8^L for engines and
  tanks (level 0 → 1 costs 30), stages 800 / 10 000 / 60 000, cargo 150 / 800 / 3 000 / 10 000; ring bands
  `max(2.8 + 0.018 h, 0.45 s × v)`, capped at 45 % of the gap to the next ring.
- Bundle id: `com.louisherwick.cometcargo` (not registered yet)
- AdMob app: not created yet
- Runner: `scripts/ci/remote-check.sh comet-cargo <label> ci-out/<label> build unit ui ui-de release`
