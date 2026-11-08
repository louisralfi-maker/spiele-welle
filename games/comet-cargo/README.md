# Comet Cargo

Launch a cargo rocket, drop each stage at the right moment, and release every satellite exactly inside a glowing orbit
ring. Higher rings pay more; satellites still aboard when the rocket stalls are lost. Retro space-age poster look.

- Design: `DESIGN.md`
- Status: 0.3 built and passed every test on the runner (08.11.2026): painted art (Recraft) and app icon, synthesized
  sounds, haptics, juice, first-flight hints. Next: ads, the six other languages, store assets.
- Tuning: `python3 tools/tune.py` mirrors the Swift sim and prints every tuning target (starter apex 120.7 km in 23.0 s,
  maxed 1498 km in 86.8 s, ring crossings 0.88 to 2.53 s, early/late drops −44 %/−12 %, 4 to 9 % per engine or tank
  level, economy bot reaches ring 15 after 112 flights). Deviations from the design's start values: engines ×1.035 and
  tanks ×1.06 per level (geometric), new stages grow the stack under the same capsule, prices 60 × 1.8^L for engines and
  tanks (level 0 → 1 costs 30), stages 800 / 10 000 / 60 000, cargo 150 / 800 / 3 000 / 10 000; ring bands
  `max(2.8 + 0.018 h, 0.45 s × v)`, capped at 45 % of the gap to the next ring.
- Bundle id: `com.louisherwick.cometcargo` (not registered yet)
- AdMob (created 08.11.2026, Louis' go): app `ca-app-pub-4855617456569312~2107555400`; interstitial
  `ca-app-pub-4855617456569312/2243286779`; rewarded ("Double it") `ca-app-pub-4855617456569312/4813609790`.
  The EU consent message (Privacy & messaging, European regulations) is not created yet: it needs the privacy policy
  URL first. Before asking Louis for the go: publish the privacy page, create and publish that message for the app,
  then run one runner round with `-GWConsentEEA YES` and without `-GWNoAds` (debug build) to see the form come up and
  the tracking question follow it.
- Privacy policy URL: `https://louisralfi-maker.github.io/comet-cargo/privacy.html` (`AdConfig.privacyPolicyURL`, linked
  from Settings → "Privacy policy"; the same URL goes into App Store Connect). The page is not live yet (404 on
  08.11.2026): publish it on Louis' Pages site before the first submission.
- Ads (Louis, 08.11.2026): interstitials rarely (not in the first 3 minutes of play, then at most every 3 to 4
  minutes, only after the flight report); one rewarded offer: double the flight's coins, once per flight. No booster.
- Store texts: `store/metadata.json`. Keywords stay within 100 UTF-8 bytes in every language (App Store Connect may count
  bytes: ja 92, zh-Hans 97) and repeat no word of the name or subtitle.
- Runner: `scripts/ci/remote-check.sh comet-cargo <label> ci-out/<label> build unit ui ui-de release`
