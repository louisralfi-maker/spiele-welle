# Lanternhold: the ads lane

Branch `claude/lh-ads`, cut from the integration branch (build 86 plus sound, `d3ed497`). The rules are DESIGN.md's
"Ads (AdMob, no purchases)" and "Losing a night"; the code follows Comet Cargo's proven pattern (docs/reuse.md "Ads,
consent, privacy").

How this lane's commits were made: the session that ran the lane may not write into the `lh-ads` worktree (the app's
worktree guard), so every commit was built from a scratch copy with a private git index and pushed straight to
`origin/claude/lh-ads`. Fix round 1 found the same guard and worked the same way; at its start it fast-forwarded the
clean local worktree to `e08de4b` (`git merge --ff-only origin/claude/lh-ads`, as advised here), and nothing in it was
written after that. Before working there again: `git -C .claude/worktrees/lh-ads merge --ff-only origin/claude/lh-ads`.

## ads-1: the ads in code

### What exists

**Core (pure, saved, unit-tested): `Core/AdPacing.swift`.** `AdPacing` moved here from `SaveGame.swift` and grew into
the rules' type. It stays `SaveGame.adPacing` (the save, the load and the chapter's restart already carried it), every
field decodes with a default (the frozen version 1 save still loads), and its JSON stays flat. No clock of its own:
the real time comes in as `now` from an injected `AdClock` (`WallClock` in the app: seconds since 1970, so "6 real
minutes" holds across launches; a clock set back never holds the ads for good).

- Double taxes are **a saved flag for the day** (the director's note of 14.11., 14:10): `taxesDoubledDay` and
  `taxesDoubled(day:)` ("every tax payment of that day counts twice"), set by the reward, read as false on any other
  day, so the next dawn clears it. See "Fix round 1" for the town lane.
- Which offer is open:
  - `doubleTaxesOpen(day:taxes:storyDawn:)`: a dawn that owes taxes, never a story dawn, not when today is already
    doubled, never after another video gave its reward on this dawn (`lastRewardGivenDay`: one video per dawn), at most
    every second dawn (taken, or passed by with Continue while it showed).
  - `secondChanceFrom(night:mode:)`: once per five nights, once per ten in endless (`GameModel.defeatInfo` reads it).
  - `merchantGift(day:hour:taxes:)` / `merchantGift(_ state:)`: Marek's days (every third day, as his cart in the
    courtyard), 40 % of the realm's day of taxes at the Normal rate (`dayOfTaxes`, from the state, never a dawn sum),
    at least 15 gold, once, by day until the horn (06:00 to 19:00).
- The interstitial: `interstitial(_ moment:now:)` answers `.allowed` or `.held(reason)`: never at the throne, in a story
  scene or anywhere but the dawn report (or a chapter's end); never at night; a chapter's ending at most once
  (`chapterEndings`); never before day 4; never on a story dawn (`AdPacing.storyDays`: the beat days 1, 2, 4, 6, 8, 10,
  11, 13, 15, 17, 19, 20 and 21, chapter mode only); never on the dawn of a rewarded video, watched or closed early
  (`lastRewardedDay`); at most every third in-game day; at least 6 real minutes after any ad (`lastAdAt`, from the
  ad's end). With those rules chapter 1 shows at most four (days 5, 9, 12, 16), endless one every third day.
- What was shown and given: `videoShown(day:at:)` on the close of every rewarded video (watched or not: the 6
  minutes, no interstitial on that dawn), `rewardGiven(_:day:night:)` only on the reward (the offer's own memory:
  the day's flag, Marek's day, the second chance's night), `rewardedWatched` (both, the tests' shorthand),
  `doubleTaxesPassed(day:)`, `interstitialShown(_:at:)`.

**The Ads folder (`Ads/`, a source folder of the app).**

- `AdConfig.swift`: Louis' units (rewarded `…/4289035611`, interstitial `…/4626066634`) in Release, Google's test units
  in Debug; `AdMode` (none, stub, google) by the launch arguments.
- `AdProvider.swift`: the protocol (`isRewardedReady`, `isInterstitialReady`, `isShowingAd`, `showingChanged`, `start`,
  `showRewarded(onReward:onClose:)`, `showInterstitial(onClose:)`), `NoAdProvider` (no SDK call at all) and
  `StubAdProvider` (a "video" that ends at once and grants; an interstitial that ends at once; it counts; the tests can
  make a video close early without its reward, `grants = false`, or stay on screen until `finish()`,
  `closesAtOnce = false`).
- `GoogleAdProvider.swift`: Comet Cargo's `AdManager` without its pacing: preloads one of each after consent, reloads
  with a growing pause, drops an expired ad, `maxAdContentRating = .general`, grants only in the SDK's reward callback.
- `AdConsent.swift`: the consent info refreshed silently at launch; Google's form (UMP, where required) and then the
  ATT prompt at the first dawn report, before the first ad is ever requested (a flag `LHAdsConsentAsked` in the app's
  own defaults); later launches start the SDK right after the silent refresh, never with a prompt (a flow cut short
  before the tracking question was answered finishes at the next dawn report). The world stands still while the form
  is on screen (it does not make the app inactive; the tracking question does). `-GWConsentEEA YES` (debug) shows the
  form as in the EU. "Privacy choices" re-opens Google's form.
- `AdDirector.swift`: the one place that asks the rules and tells the provider. `AdDirector.shared` by this launch's
  mode; the tests build their own with the stub and a counted clock. A rewarded video in three moments: in the
  reward callback the reward is banked in the dawn (`SimDriver.bankReward`: a watched video pays after a relaunch and
  after "Replay the day" too) and saved; when the ad has gone, `AdPacing.videoShown` notes it, watched or closed early;
  then, only if it was watched, the payoff the player sees and hears (the coins' sound, Marek's slip, the report's
  treasury counting up). It stands at the report's Continue for the interstitial (over the report, the world still);
  `chapterEndContinues(chapter:day:proceed:)` waits for the story panels' chapter end. An ad that does not come on
  screen within 4 s is given up (`showTimeout`), so neither Continue nor an offer can ever be left dead; an ad that
  comes later after all holds the world while it shows (`showingChanged`). Marek's card closes when its gift can no
  longer be had (`merchantOfferLost`: an expired video).
- `AdViews.swift`: `DawnReportAds` (the report: "Double taxes today / Watch a short video ad" on a plaque, no figure;
  afterwards "Taxes doubled / Every tax counts twice today" in teal; it also starts the consent at the first report),
  `ReportTreasury` (the report's own treasury figure, counting up by the bridge's gold once the video has gone; one
  treasury on the card),
  `SecondChanceOffer` (the defeat card: the wax-red "Second chance / Watch a short video ad: the hearth is rekindled and
  dawn comes at once"; while it waits, the night it comes back; with no video nothing at all), `MerchantGiftCard` (a
  letter from the courtyard: Marek's portrait, his line, what the video gives in plain words, "Not now" and
  "Merchant's gift +n / Watch a short video ad"; it stands below the HUD's ledger), `GiftLandedSlip` (3.5 s under the
  realm strip after the gift: "Marek's gift: +25 gold"), `AdLayer` (the card and the slip over the world, the stub's
  `ads-log`),
  `PrivacyChoicesRow` (for the settings, only where UMP requires privacy options).

Launch arguments (none of them is in `DebugArgs`; `AdMode` reads them):

| Argument | Effect |
|---|---|
| `-GWNoAds YES` | no SDK call at all, no offer, no consent |
| (any `-GW` argument without an ad argument, debug) | the same: every existing UI test and screenshot run has no ads without naming it |
| `-GWAdStub YES` | debug: the stub (offers always ready, rewards at once, an interstitial that ends at once) |
| `-GWAds google` | debug: Google's test ads beside other `-GW` arguments |
| `-GWMerchant YES` | debug: Marek's card opens at launch when his gift is open (until the join wires his cart) |
| `-GWConsentEEA YES` | debug: the consent form as in the EEA; with the stub the privacy row shows |
| `-GWAdsNoFill YES` | debug: every load fails, as offline |

Identifiers: `report-ad-double`, `report-ad-doubled`, `report-treasury` (value: the report's treasury), `defeat-second-chance`,
`defeat-second-chance-later`, `merchant-card`, `merchant-gift`, `merchant-later`, `merchant-close`,
`merchant-gift-landed`, `settings-privacy`,
`ads-log` (stub only: "mode:stub rewarded:n interstitial:n verdict:…").

**Project.** `project.yml`: the packages GoogleMobileAds (from 13.11.0) and GoogleUserMessagingPlatform (from 3.1.0),
the `Ads` source folder, `GAD_APPLICATION_IDENTIFIER` (`ca-app-pub-4855617456569312~7252229972`), the tracking text,
StoreKit and AppTrackingTransparency. `Info.plist`: `GADApplicationIdentifier` from the build setting and Google's 50
SKAdNetwork ids (Comet Cargo's list). `Package.resolved` (Comet Cargo's pins). `Resources/InfoPlist.xcstrings`: the
tracking prompt in all eight languages (Comet Cargo's text). `Resources/PrivacyInfo.xcprivacy`: still
`NSPrivacyTracking` false with no domains; only its comments changed.

**Strings.** `Resources/Ads.xcstrings` (table "Ads"), 18 strings in English and German (fix round 1 swapped the five
double-taxes strings with figures for five without). The six other languages follow in the i18n pass after the join.

### The hooks (apply them again at the join)

| File | Where | What and why |
|---|---|---|
| `Core/SaveGame.swift` | after `SaveSettings` | the `AdPacing` struct removed (it lives in `Core/AdPacing.swift` now); a two-line comment points there |
| `Core/SimDriver.swift` | after `setLord` | `mutating func bankReward(gold:)`: the reward into the state and the dawn snapshot (`dawnSnapshot` is `private(set)`) |
| `App/GameModel.swift` | `secondChanceGap`, `secondChanceGapEndless` | read from `AdPacing` |
| `App/GameModel.swift` | the stored properties | `adPacing` internal (was private) so the director reads and notes it; new `adGate` closure |
| `App/GameModel.swift` | `continueReport()` | asks `adGate` first; the old body is `beginDay(after:)`, which runs only while that report is still open |
| `App/GameModel.swift` | `secondChanceFrom(night:mode:)` | its body is `adPacing.secondChanceFrom(night:mode:)` |
| `App/LanternholdApp.swift` | `RootView`, where the model is made | `AdDirector.shared.attach(made)` |
| `UI/GameView.swift` | after `OverlayView(model:)` | `AdLayer(model: model)` (Marek's card over everything) |
| `UI/ReportCardView.swift` | footer, between the spacer and Continue | `DawnReportAds(model: model)`; place it on every report (the first one asks for consent) |
| `UI/ReportCardView.swift` | footer, after "Treasury" | `ReportTreasury(gold: card.goldAfter, model: model)` in place of `GoldAmount(amount: card.goldAfter, size: 17)`: the one treasury figure counts up after the double taxes (fix round 1) |
| `UI/DefeatCardView.swift` | the buttons' stack, before "Replay the day" | `SecondChanceOffer(info: info, model: model)` in place of the old second-chance button and its footnote |
| `UITests/FirstDayUITests.swift` | `testScreens`, the defeat card | asserts no `defeat-second-chance` (no ads in that launch) instead of checking its size |
| `project.yml`, `Info.plist`, `Resources/PrivacyInfo.xcprivacy` | see "Project" | the packages, settings, plist keys, comments |

`Localizable.xcstrings` keeps the old keys "Second chance", "The hearth flares up and dawn comes at once" and "A second
chance again from night %lld"; nothing uses them now (the i18n pass may drop them).

### Rounds

| Round | Commit | Steps | Result |
|---|---|---|---|
| `lh-ad1-1` | `f0f0314` | build, unit, ui (ads, first day's screens), ui-de (ads) | build FAILED: a nonisolated unit test read `GameModel.secondChanceGap` (main actor); fixed in `aa32838` |
| `lh-ad1-2` | `406047f` | the same | ALL PASSED: 439 unit tests (28 of them the ads'), `AdsUITests` (5) in English and German, `FirstDayUITests.testScreens` |
| `lh-ad1-3` | `0c82c44` | build, unit, ui, ui-de, release (the full round) | ALL PASSED: 439 unit tests, 21 UI tests in English and in German, the Release build |
| `lh-ad1-4` | `f3d7321` | build, unit, ui, ui-de, release (the full round) | ALL PASSED: 439 unit tests, 21 UI tests in English and in German, the Release build |

Judged from `lh-ad1-2`'s shots (upright copies in the lane's report folder): the report's offer and the doubled note fit
the footer in English and German, the defeat card's second chance reads well in both; Marek's card failed the bar: its
"Not now" stood one letter per line, and in German the card ran off the screen; after the gift the card just vanished.
Fixed in `0c82c44` (a fixed "Not now", a wider card, a slip under the realm strip: "Marek's gift: +25 gold").
From `lh-ad1-3`'s shots: the card reads well in both languages, but in German its top edge covered the HUD's gold (the
very number the gift adds to), and the slip (2.6 s) had gone before the shot. Then: the card stands in the room below
the HUD's ledger, the slip shows 3.5 s, and the UI test shoots while it shows. `lh-ad1-4`'s shots confirm both.

The product question of these rounds (two videos on one dawn after a second chance) is answered in fix round 1: one
video per dawn.

### Open, and what waits for the join

- **Marek's cart** at the back gate (the world lane's new world): a `KingTarget` near the cart that opens
  `AdDirector.shared.openMerchantCard()` while `AdDirector.shared.merchantOffer` is not nil (only then: no video, no
  target). Until then `-GWMerchant YES` opens the card.
- **The settings** (stage lane): place `PrivacyChoicesRow()` (on the desk) beside sound and haptics, with the privacy
  policy link (store lane's page).
- **The redrawn report and defeat card** (stage lane): place `DawnReportAds`, `ReportTreasury` (or let the redrawn
  treasury add `AdDirector.shared.treasuryGain(on:)`, 0 once the bridge is gone) and `SecondChanceOffer` again.
  Without a video the defeat card has only "Replay the day", which is a quiet button: the redrawn card may make it the
  main button when `SecondChanceOffer` shows nothing.
- **Story panels** (panels lane): call `AdDirector.shared.chapterEndContinues(chapter:day:proceed:)` on the chapter
  end's last Continue; if the panels know their own beat dawns, pass them as `InterstitialMoment.storyDawn` (today
  `AdPacing.storyDays`).
- **Onboarding**: no hint should sit on the first dawn report while the consent form and the tracking question come.
- **Languages**: `Ads.xcstrings` needs fr, es, it, pt-BR, ja, zh-Hans.
- **Store** (store lane): the App Privacy answers now include the SDKs' data (Comet Cargo's answers fit), the age
  rating's ads question, and the review notes (rewarded videos are optional; how to reach each).
- **On a device**: the real Google flow (the consent form in the EEA, the tracking question, a video) has not run in
  this lane; the runner has no ads network test. The next TestFlight build (Release: live units) shows it; nobody may
  tap a live ad there (AdMob policy, the account Piston Empire shares): watch only that the consent, the tracking
  question and the offers appear.

### Fix round 1 (critic look 1, `ads-1-critic1.md`)

Two blockers and four highs, all fixed:

- **Double taxes are a saved flag for the day** (blocker 1, the director's note 1 of 14.11., 14:10). `AdPacing` holds
  `taxesDoubledDay` (decoded with a default, 0: none) and `taxesDoubled(day:)`; the reward sets it
  (`rewardGiven(.doubleTaxes, day:)`), any other day reads it as false, so the next dawn clears it. Never on a story
  dawn: `doubleTaxesOpen` takes `storyDawn` (the director passes `AdPacing.isStoryDawn`; day 2, the first report, is a
  story dawn now too). The button says "Double taxes today / Watch a short video ad" with no figure.
  - **The bridge:** this build still pays the day's taxes at dawn, before the report, so the reward pays this dawn's
    taxes once more at that point (`AdDirector.takeDoubleTaxes`, the constant `bridge`), banked in the dawn snapshot.
  - **For the town lane (the join):** the flag is `AdPacing.taxesDoubledDay` / `AdPacing.taxesDoubled(day:)` in
    `Core/AdPacing.swift`, saved as `SaveGame.adPacing`, held by `GameModel.adPacing`. The town lane already has its
    own per-ledger flag (`Town.grantDoubleTaxes(&state)`, `TownDay.doubled`, read by `Town.collect` and `Town.knock`).
    At the join, in `AdDirector.takeDoubleTaxes`'s `grant`: replace `model.withDriver { $0.bankReward(gold: bridge) }`
    by a grant on the state and on the dawn snapshot (a small `SimDriver.grantDoubleTaxes()` beside `bankReward` that
    calls `Town.grantDoubleTaxes` on both, so "Replay the day" keeps it), and set `bridge` to 0. `AdPacing.taxesDoubled`
    stays the ads' memory (the report's note, the offer closed); `doubleTaxesOpen`'s `taxes` becomes the day's owed sum
    (the town's ledger), and the offer stays at dawn, before the first coins fly. `Town.grantDoubleTaxes` refuses the
    first morning; day 2 is a story dawn here, so the offer never shows there anyway.
- **A video closed early** (blocker 2). On the close of every rewarded video that was shown, `AdPacing.videoShown`
  notes `lastAdAt` (the 6 minutes) and `lastRewardedDay` (no interstitial on that dawn's Continue); the offer's own
  memory comes only with the reward (`rewardGiven`). A video asked for that failed to come counts as shown, on the safe
  side. The interstitial notes `lastAdAt` again at its end. The stub can close a video without its reward; director
  tests for each offer: no reward, no gold, no slot used, the offer comes back while a video is ready, Continue held
  with `.afterRewarded`.
- **One video per dawn** (high 1): `lastRewardGivenDay`; the dawn a second chance brought offers no double taxes
  (unit test, director test, UI test on the day-4 report).
- **The payoff in front of the player** (high 2): the reward is banked and saved in the callback; the coins' sound, the
  HUD, Marek's slip and the card's close, and the report's treasury counting up wait for the ad's close
  (`watch(day:grant:payoff:)`). The second chance keeps its state change in the callback (robust if the app dies
  under the end card); the report it brings is on screen when the ad goes.
- **Negative tests at the director's level** (high 3): `StubAdProvider.grants`, `closesAtOnce`, `finish()`.
- **One treasury on the report** (high 4): the note says "Taxes doubled / Every tax counts twice today"; the report's own
  treasury (`ReportTreasury`, a one-line hook) counts up by what came in (`AdDirector.treasuryGain`).
- **Marek's gift without a dawn sum** (blocker 1's last point): `AdPacing.dayOfTaxes(state)`, the realm's day of taxes
  at the Normal rate and its present happiness (`Economy.taxes` with the rate set to Normal; 0 in unrest, then the
  15-gold floor). It never reads the report. At the join, if `GameState.tax` is gone, drop the line `normal.tax =
  .normal` (the town branch's `Economy.taxes` has one rate).
- Smaller points of the critic, also done: Marek's card closes when its video stops being ready (`merchantOfferLost`,
  from the close of a video without reward and from `AdLayer` when `rewardedReady` falls); any ad on screen holds the
  world (`AdProvider.showingChanged`, Google's delegate calls it), so a late interstitial never runs over a moving day.
  Left as it is: "Eure Strahlkraft" is Story.xcstrings' own German for "Your Radiance" (Marek says it in every line).
  The report's "Heute Nacht ist niemand gefallen" after a lost night is the report's logic (stage or people lane).

New hooks in this round: `UI/ReportCardView.swift` (the treasury line, in the table above). The protocol change
(`showingChanged`) and everything else stay inside `Ads/`, `Core/AdPacing.swift` and the ads' tests.
