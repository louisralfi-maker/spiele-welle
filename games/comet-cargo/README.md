# Comet Cargo

Launch a cargo rocket, drop each stage at the right moment, and release every satellite exactly inside a glowing orbit
ring. Higher rings pay more; satellites still aboard when the rocket stalls are lost. Retro space-age poster look.

- Design: `DESIGN.md`
- Status: 0.1 (core loop) written, not yet built on the runner. Core sim, rocket, rings, ratings, economy, save and
  autopilot with unit and tuning tests; hangar with ring network and upgrades, flight scene (Canvas) with HUD, results,
  settings; display-link flight driver, save store, debug launch arguments; haptics hub; String Catalog (en, de); UI smoke
  test with screenshots 01 to 06.
- Tuning: `python3 tools/tune.py` mirrors the Swift sim and prints every tuning target (starter apex 120.7 km in 23.0 s,
  maxed 1498 km in 86.8 s, ring crossings 0.59 to 2.53 s, early/late drops −44 %/−12 %, 4 to 9 % per engine or tank
  level, economy bot reaches ring 15 after 112 flights). Deviations from the design's start values: engines ×1.035 and
  tanks ×1.06 per level (geometric), new stages grow the stack under the same capsule, prices 60 × 1.8^L for engines and
  tanks, stages 800 / 10 000 / 60 000, cargo 150 / 800 / 3 000 / 10 000.
- Bundle id: `com.louisherwick.cometcargo` (not registered yet)
- AdMob app: not created yet
- Runner: `scripts/ci/remote-check.sh comet-cargo <label> ci-out/<label> build unit ui ui-de release`
