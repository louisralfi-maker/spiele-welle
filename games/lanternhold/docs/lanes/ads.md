# Lanternhold: the ads lane

Branch `claude/lh-ads`, cut from the integration branch (build 86 plus sound, `d3ed497`). The rules are DESIGN.md's
"Ads (AdMob, no purchases)" and "Losing a night"; the code follows Comet Cargo's proven pattern (docs/reuse.md "Ads,
consent, privacy").

How this lane's commits were made: the session that ran the lane may not write into the `lh-ads` worktree (the app's
worktree guard), so every commit was built from a scratch copy with a private git index and pushed straight to
`origin/claude/lh-ads`. The local worktree `.claude/worktrees/lh-ads` was never touched and still stands at `d3ed497`:
before working there, `git -C .claude/worktrees/lh-ads merge --ff-only origin/claude/lh-ads`.

## ads-1: the ads in code

### What exists

**Core (pure, saved, unit-tested): `Core/AdPacing.swift`.** `AdPacing` moved here from `SaveGame.swift` and grew into
the rules' type. It stays `SaveGame.adPacing` (the save, the load and the chapter's restart already carried it), every
field decodes with a default (the frozen version 1 save still loads), and its JSON stays flat. No clock of its own:
the real time comes in as `now` from an injected `AdClock` (`WallClock` in the app: seconds since 1970, so "6 real
minutes" holds across launches; a clock set back never holds the ads for good).

- Which offer is open:
  - `doubleTaxesOpen(day:taxes:)`: at most every second dawn (taken, or passed by with Continue while it showed), only
    on a dawn that brought taxes.
  - `secondChanceFrom(night:mode:)`: once per five nights, once per ten in endless (`GameModel.defeatInfo` reads it).
  - `merchantGift(day:hour:dawnTaxes:)` / `merchantGift(_ state:)`: Marek's days (every third day, as his cart in the
    courtyard), +40 % of that dawn's taxes, at least 15 gold, once, by day until the horn (06:00 to 19:00).
- The interstitial: `interstitial(_ moment:now:)` answers `.allowed` or `.held(reason)`: never at the throne, in a story
  scene or anywhere but the dawn report (or a chapter's end); never at night; a chapter's ending at most once
  (`chapterEndings`); never before day 4; never on a story dawn (`AdPacing.storyDays`: the beat days 4, 6, 8, 10, 11,
  13, 15, 17, 19, 20 and 21, chapter mode only); never on the dawn of a rewarded video (`lastRewardedDay`); at most every
  third in-game day; at least 6 real minutes after any ad (`lastAdAt`). With those rules chapter 1 shows at most four
  (days 5, 9, 12, 16), endless one every third day.
- What was shown: `rewardedWatched(_:day:night:at:)`, `doubleTaxesPassed(day:)`, `interstitialShown(_:at:)`.

**The Ads folder (`Ads/`, a source folder of the app).**

- `AdConfig.swift`: Louis' units (rewarded `…/4289035611`, interstitial `…/4626066634`) in Release, Google's test units
  in Debug; `AdMode` (none, stub, google) by the launch arguments.
- `AdProvider.swift`: the protocol (`isRewardedReady`, `isInterstitialReady`, `start`, `showRewarded(onReward:onClose:)`,
  `showInterstitial(onClose:)`), `NoAdProvider` (no SDK call at all) and `StubAdProvider` (a "video" that ends at once
  and grants; an interstitial that ends at once; it counts).
- `GoogleAdProvider.swift`: Comet Cargo's `AdManager` without its pacing: preloads one of each after consent, reloads
  with a growing pause, drops an expired ad, `maxAdContentRating = .general`, grants only in the SDK's reward callback.
- `AdConsent.swift`: the consent info refreshed silently at launch; Google's form (UMP, where required) and then the
  ATT prompt at the first dawn report, before the first ad is ever requested (a flag `LHAdsConsentAsked` in the app's
  own defaults); later launches start the SDK right after the silent refresh. `-GWConsentEEA YES` (debug) shows the
  form as in the EU. "Privacy choices" re-opens Google's form.
- `AdDirector.swift`: the one place that asks the rules and tells the provider. `AdDirector.shared` by this launch's
  mode; the tests build their own with the stub and a counted clock. It offers the three videos, grants only when one
  was watched to its end, banks gold in the dawn (`SimDriver.bankReward`: a watched video pays after a relaunch and after
  "Replay the day" too) and saves; it stands at the report's Continue for the interstitial (over the report, the world
  still); `chapterEndContinues(chapter:day:proceed:)` waits for the story panels' chapter end.
- `AdViews.swift`: `DawnReportAds` (the report: "Double taxes +64 / Watch a short video ad" on a plaque, afterwards the
  gold that came in and the treasury now, in teal; it also starts the consent at the first report),
  `SecondChanceOffer` (the defeat card: the wax-red "Second chance / Watch a short video ad: the hearth is rekindled and
  dawn comes at once"; while it waits, the night it comes back; with no video nothing at all), `MerchantGiftCard` (a
  letter from the courtyard: Marek's portrait, his line, what the video gives in plain words, "Not now" and
  "Merchant's gift +n / Watch a short video ad"), `AdLayer` (the card over the world, the stub's `ads-log`),
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

Identifiers: `report-ad-double`, `report-ad-doubled` (value: the treasury now), `defeat-second-chance`,
`defeat-second-chance-later`, `merchant-card`, `merchant-gift`, `merchant-later`, `merchant-close`, `settings-privacy`,
`ads-log` (stub only: "mode:stub rewarded:n interstitial:n verdict:…").

**Project.** `project.yml`: the packages GoogleMobileAds (from 13.11.0) and GoogleUserMessagingPlatform (from 3.1.0),
the `Ads` source folder, `GAD_APPLICATION_IDENTIFIER` (`ca-app-pub-4855617456569312~7252229972`), the tracking text,
StoreKit and AppTrackingTransparency. `Info.plist`: `GADApplicationIdentifier` from the build setting and Google's 50
SKAdNetwork ids (Comet Cargo's list). `Package.resolved` (Comet Cargo's pins). `Resources/InfoPlist.xcstrings`: the
tracking prompt in all eight languages (Comet Cargo's text). `Resources/PrivacyInfo.xcprivacy`: still
`NSPrivacyTracking` false with no domains; only its comments changed.

**Strings.** `Resources/Ads.xcstrings` (table "Ads"), 17 strings in English and German. The six other languages follow
in the i18n pass after the join.

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
| `UI/DefeatCardView.swift` | the buttons' stack, before "Replay the day" | `SecondChanceOffer(info: info, model: model)` in place of the old second-chance button and its footnote |
| `UITests/FirstDayUITests.swift` | `testScreens`, the defeat card | asserts no `defeat-second-chance` (no ads in that launch) instead of checking its size |
| `project.yml`, `Info.plist`, `Resources/PrivacyInfo.xcprivacy` | see "Project" | the packages, settings, plist keys, comments |

`Localizable.xcstrings` keeps the old keys "Second chance", "The hearth flares up and dawn comes at once" and "A second
chance again from night %lld"; nothing uses them now (the i18n pass may drop them).

### Rounds

(filled in below as they come back)

### Open, and what waits for the join

- **Marek's cart** at the back gate (the world lane's new world): a `KingTarget` near the cart that opens
  `AdDirector.shared.openMerchantCard()` while `AdDirector.shared.merchantOffer` is not nil (only then: no video, no
  target). Until then `-GWMerchant YES` opens the card.
- **The settings** (stage lane): place `PrivacyChoicesRow()` (on the desk) beside sound and haptics, with the privacy
  policy link (store lane's page).
- **The redrawn report and defeat card** (stage lane): place `DawnReportAds` and `SecondChanceOffer` again. The
  report's own treasury figure shows the gold before the double taxes; `DawnReportAds` says the treasury now beside it.
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
