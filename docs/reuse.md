# What to copy from Piston Empire

Piston Empire lives at `/Users/enaayla/Desktop/Piston Empire` (branch `main`). Read and copy from it; never change it. Strip its names and its `PE` prefixes when you copy: use `GW` or the game's own prefix.

## Ads, consent, privacy

| File | What it does |
|---|---|
| `App/AdConfig.swift` | Every ad id in one place; Debug builds always use Google's test units. |
| `App/AdConsent.swift` | Google UMP consent form, then the ATT prompt, before any ad request. |
| `App/AdManager.swift` | Loads and shows rewarded and interstitial ads. Knows when an ad is on screen (`isShowingAd`). |
| `App/AdPacing.swift` | How often an interstitial may come; never in the first minutes. |
| `Resources/PrivacyInfo.xcprivacy` | `NSPrivacyTracking` false with no domains (read its comment: listing Google's domains or setting it true broke a build once, ITMS-91064). |
| `Resources/LaunchInfo.plist` | `GADApplicationIdentifier` from the build setting, Google's `SKAdNetworkItems`. |
| `project.yml` | Packages GoogleMobileAds (from 13.11.0) and GoogleUserMessagingPlatform (from 3.1.0). Info.plist keys (`ITSAppUsesNonExemptEncryption` NO, `NSUserTrackingUsageDescription`), `GENERATE_INFOPLIST_FILE`. |
| `docs/handoff/Package.resolved` | Package pins, copied into the generated project on the runner. |

## Feel: sounds and haptics

| File | What it does |
|---|---|
| `Audio/GameFeedback.swift` | The one hub every sound and haptic goes through (`feelBeat`, `feelBeats`, `gameFeedback`). Reduce Motion and skip aware. |
| `Audio/CueSynth.swift` | Sound cues synthesized in code (no audio files): stamp, success, coins, counter tick and more. |
| `Audio/AudioHub.swift`, `Audio/HapticHub.swift`, `Audio/HapticScore.swift` | Audio session, Core Haptics patterns. |
| `UI/Moments/Moments.swift` | `MomentTimeline` / `MomentClock`: timed beats with a tap-to-skip and Reduce Motion end states. A pattern for short celebrations. |

Skip `Audio/EngineSynth.swift` (Piston Empire's engine sound).

## Art

| File | What it does |
|---|---|
| `Designer/ArtAsset.swift` | Loads plain HEIC from `Resources/Art` at the drawn size, with a cache. |
| `scripts/recraft.sh` | Recraft API calls. It reads `~/.recraft_api_key` itself; copy it to `tools/recraft.sh`. |
| `docs/handoff/plans/recraft-notes/` | Prompt and cutting lessons from 300+ paintings. |
| `scripts/make_icon.swift` | Renders the app icon. |

## Tests and the runner

| File | What it does |
|---|---|
| `scripts/simtests.sh` | Runs xcodebuild tests, exits with xcodebuild's own status, prints one PASSED or FAILED line. |
| `scripts/ci/remote-check.sh`, `run-check.sh`, `publish-results.sh`, `.github/workflows/sim-check.yml` | The GitHub Mac runner round trip. Change the repo URL, the SSH key (`~/.ssh/id_ed25519_games`), the commit e-mail (noreply), the project and scheme names, and drop the Piston Empire steps (worlds). |
| `Tests/FoundingStrikeSheetTests.swift` | Pictures without UI tests: ImageRenderer into PNGs behind an environment variable. |

## Translations

| File | What it does |
|---|---|
| `review/i18n/tools/catupd.py` | Merges a pending JSON (`{"English key": {"de": ..., ..., "comment": ...}}`) into the String Catalog. It refuses placeholder mismatches and missing languages. |
| `review/i18n/tools/catq.py` | Looks up a key in the catalogue. |

## Store texts

`docs/handoff/plans/release-kit/`: the 1.0 checklist, metadata in German and English, age-rating and app-privacy answers, privacy policy and support pages, review notes. See `docs/store-checklist.md`.
