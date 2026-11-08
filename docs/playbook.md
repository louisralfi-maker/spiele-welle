# Playbook: one good small game, quickly

## 1. Pick the idea

- **A simple, proven mechanic with one fresh twist** that you can say in one sentence ("tap to stack falling crates, but each crate is a little magnet").
  - Avoid what Apple calls saturated or low-effort categories in guideline 4.3(b): flashlight, wallpaper, simple timers, sound effects, fortune telling, dating, drinking games, fart and burp apps.
  - Avoid a clone of any existing game.
- **Each of the 3 to 5 games must feel different from the others:** a different mechanic, look and controls. Apple judges the whole developer account; similar apps from one account read as spam.
- **Before building**, search the App Store web pages (apps.apple.com, in the built-in browser) for the core idea. If the top results already look the same, pick another twist.
- **Pitch it to Louis in two lines of German:** what you do, and why it is fun. Go on unless he objects.
- **Scope** that Claude can finish quickly and well:
  - one screen of play, 1 to 3 minutes per round;
  - fun in the first 10 seconds;
  - progression that gives a reason to come back (best score, unlocks, a daily challenge seeded by the date);
  - no online features, no accounts, no user content.

## 2. Build the smallest playable form

- **Stack:**
  - Swift 6 and SwiftUI, iOS 17+, iPhone only, xcodegen `project.yml`.
  - Pick portrait or landscape per game. Portrait suits casual one-hand play best.
- **Code layout:**
  - `Core/`: pure game logic in plain Swift (structs, Codable, a seeded random stream). Unit-testable and deterministic.
  - `UI/`: SwiftUI views. Draw with `Canvas` inside a `TimelineView(.animation)`, Piston Empire's proven tool for painted 2D. Use SpriteKit only when real physics carries the game.
  - `Audio/`: one feedback hub for every sound and haptic (`docs/reuse.md`). Sounds are synthesized, so no audio files.
  - `Ads/`: copied from Piston Empire, see 7.
  - `App/`: entry point, settings, debug launch arguments.
- **Debug launch arguments** let UI tests and screenshots reach any state:
  - `-GWAutoplay YES` plays by itself;
  - `-GWLevel 7` starts at level 7;
  - `-GWScreen gameover` opens the game-over screen.
- **Saves:** Codable JSON with a version number. New fields are optional, so old saves keep loading. Add a round-trip test.
- **Fun check** on the runner after the first playable build: the UI test autoplays a round and saves screenshots. An agent with a player lens judges them: is the goal clear, does it look good, is anything clipped. Fix before adding more.

## 3. Art

- **Recraft** (`tools/recraft.sh`, credits free to use) for painted pieces: backgrounds, characters, icons and the app icon. Paint a whole set on one sheet so the pieces share one finish, then cut it (see Piston Empire `docs/handoff/plans/recraft-notes`).
- **Format:** plain HEIC in `Resources/Art`, loaded at the drawn size by a small loader (Piston Empire `Designer/ArtAsset.swift`). The asset catalog re-encodes and bloats images.
- **Procedural art** (Canvas paths and gradients) for everything that moves or changes colour.
- **One look per game**, held to the end. Never a real brand, logo or famous character.

## 4. Juice (what makes a small game feel good)

- Every action answers within one frame: a squash or pop, a sound, a light haptic, through the feedback hub only.
- Numbers roll up with ticks, and a record shimmers. Keep big effects rare, so they stay special.
- Use screen shake, particles and flashes sparingly. Under Reduce Motion, show calm end states, never a frozen half-animation.
- Spend the most polish on the game-over and new-best moments: they decide whether a player starts another round.
- No music. Silence plus crisp effects is the house style.

## 5. Onboarding

- Playable in the first 10 seconds, with no text walls. Teach with one animated hint (a hand showing the tap) that disappears after the first success.
- No ads in the first few minutes or during the hint.

## 6. Quality bar before any store step

- 44 pt tap targets. Text never clips: German is the longest, Japanese and Chinese need their own check.
- VoiceOver labels on every button. The game itself may stay visual.
- No dead ends. Every screen has a way back. The app survives backgrounding mid-round and relaunch.
- Smooth on the oldest supported iPhone: no per-frame image decoding, no huge offscreen layers.
- Tests:
  - unit tests for the logic (seeded, deterministic);
  - a UI smoke test that plays the first minute and saves screenshots in English and German;
  - optionally "sheet tests" that render views with ImageRenderer into PNGs behind an environment variable (Piston Empire `Tests/FoundingStrikeSheetTests.swift`).

## 7. Ads (ads only, no purchases)

- Copy Piston Empire's ad code (`docs/reuse.md`). It does the following:
  - the Google UMP consent form first (required in the EU);
  - then the ATT prompt;
  - then ads;
  - Debug builds always use Google's test ad units, because clicking your own live ads can get the AdMob account closed.
- **Rewarded:** opt-in only, for a clear gift (continue a run, double the coins).
- **Interstitial:** only at natural breaks (after a game over, between levels), paced so it is never more often than about every few minutes, and never in the first minutes. Piston Empire `App/AdPacing.swift`.
- No banner over the play area. The content must clearly outweigh the ads (AdMob's low-value rule).
- Not in the Kids category: its ad rules are far stricter.

## 8. Translations

- English in code (`String(localized:)`), a String Catalog `Localizable.xcstrings` with de, fr, es, it, pt-BR, ja, zh-Hans.
- Keep text short. Write translations into a pending JSON and merge them with a script that checks placeholders and missing languages (Piston Empire `review/i18n/tools/catupd.py`, adapt it). Never hand-edit the catalogue without that check.
- The store texts (name, subtitle, description, keywords, promo text) also come in all eight languages.

## 9. Store assets and release

Follow `docs/store-checklist.md`. Release the games weeks apart, each with real updates afterwards (a fix, new levels). Apple removes apps that are never updated.
