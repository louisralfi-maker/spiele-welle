# Lanternhold 1.0: notes for App Review (App Store Connect › version 1.0 › App Review Information)

Draft of the store lane (14.11.2026). Before submitting, check every sentence marked `[check]` against the joined build:
the rebuild replaces the action button with touching the world and adds a title screen, and the ads lane adds the
ads. Lines starting with `[if shipped]` go out with the part they describe. Submission only with Louis' go.

## Fields

| Field | Value |
|---|---|
| Sign-in required | **No** (no account, no login, no demo account) |
| Contact first and last name | Louis / Herwick |
| Contact phone | Louis enters his own number (App Store Connect requires one; only Apple sees it) |
| Contact e-mail | louis.ralf@web.de |
| Attachment | none |

## Notes (paste into "Notes"; Apple allows 4000 characters, this text has about 3400)

Remove every `[check]` marker before pasting (`check_listing.py --final` fails while one is left).

```text
Lanternhold is a single-player castle game for iPhone, played in landscape. There is no account, no login and no server of ours; the game works offline and saves on the device at every in-game dawn.

THE GAME
You hold a castle in the only gap of a mountain wall. By day you build defences, recruit, set taxes and judge petitions from the throne. By night the battle runs on its own: archers, fire arrows, a ballista and a catapult against creatures of smoke that shrink from light and dissolve into soot when defeated (no blood). If they reach the hearth fire in the great hall, the realm falls. One in-game day and night take about five minutes.

FIRST MINUTES
1. [check] On the title screen, touch the screen to begin. A new game asks for the lord's name (any name, or keep "Robin") and lord or lady; tap "Begin".
2. [check] Touch a person or a thing and the lord walks there and does what it offers: build at a marked plot in front of the gate, talk to someone, sit on the throne in the great hall. Touch the ground or drag to walk. The strip at the top centre shows the whole realm; tap a point to travel there.
3. The first day starts with 60 gold: a brazier, a stake pit or archers are affordable. In the great hall, sit on the throne: a petitioner's letter offers two or three choices; "Counsel" shows the chancellor's advice.
4. At 19:00 a horn sounds and the first night begins (a few small creatures). To get there at once, open the pause menu (top left) and choose "Sound the horn". [check]
5. At dawn a report sums up the night, the taxes and the town's mood. "Continue" starts the next day.

ADS (Google AdMob; no banners)
a) Rewarded videos, always optional; each button names its reward and says that a video plays, and the reward is granted only after the video has played:
   - "Double taxes" in the dawn report (at most every second dawn);
   - "Second chance" on the defeat card if the realm falls (once per five nights): the hearth flares up and dawn comes at once;
   [if shipped] - "Merchant's gift" at the merchant's cart at the castle's back gate on every third dawn: extra gold.
   An offer appears only when a video is ready; without one the game goes on with no empty button.
b) Interstitial, rare: only after the dawn report has been read, on "Continue"; at most every third in-game day and at least 6 real minutes after any ad; never before day 4, never right after a rewarded video, never at night, during an audience or in a story scene. Day 4 is reached after about 15 minutes of play.
Consent: Google's UMP consent form appears where the regulations require it, then the iOS App Tracking Transparency prompt; both appear at the first dawn report (about five minutes in), before any ad is requested. The game works whatever the player chooses, and without a network connection. "Privacy choices" in the settings appears where UMP requires it, and the privacy policy is linked there. [check]
During review the first real ad requests may return no ad; then the offers simply stay hidden.

PURCHASES
None. The app has no in-app purchases.

OTHER
- No user-generated content shared with others, no chat, no web browsing, no location, camera or microphone, no push notifications. The lord's name stays on the device.
- No music; sound effects and haptics only, both can be switched off in the settings.
- iPhone only, iOS 17 or later, landscape.

Thank you for reviewing! Questions: louis.ralf@web.de
```

## Before sending: check against the final build (internal, not for Apple)

- [ ] The title screen and the first touch (stage-3: "the title is the world", one touch lights the lantern).
- [ ] Touch the world replaced the action button (stage-2); the name entry, "Begin", the throne, "Counsel" and the
      tax lectern still read as written; the realm strip still travels on a tap.
- [ ] "Sound the horn" is still in the pause menu, and the pause button still sits top left.
- [ ] The ads lane's offers, names and rules match: "Double taxes", "Second chance", the Merchant's gift (cut the
      line if Marek's cart is not wired at the join), the interstitial's conditions (DESIGN.md "Ads", Core's ad rules
      and their unit tests).
- [ ] UMP then ATT at the first dawn report, before any ad request; `NSUserTrackingUsageDescription` in all eight
      languages; `maxAdContentRating = .general`; Release builds use the real ad unit ids (ads lane brief), Debug the
      test ids.
- [ ] **Settings link the privacy policy.** Apple guideline 5.1.1(i) wants the privacy policy reachable inside the
      app. Comet Cargo has "Privacy policy" in Settings (`AdConfig.privacyPolicyURL`); Lanternhold's settings need
      the same row (`https://louisralfi-maker.github.io/spiele-welle/lanternhold/privacy.html`) next to the ads
      lane's PrivacyChoicesRow. Neither lane's brief names it yet: a hook for the join (lane notes).
- [ ] The German labels the support page quotes ("Datenschutzoptionen") match the app's strings; otherwise change the
      page.

## Test hints (so the app does not fail in review)

- Play about 20 minutes on a release build with real ad ids: see "Double taxes" at a dawn report and one
  interstitial after day 4.
- Let the realm fall once (a night without defences on a late day, or `-GWScreen defeat` in a debug build) and see
  "Second chance".
- Airplane mode: the game starts and plays; the offers stay hidden.
- The tracking prompt appears once, after the consent form (EEA, UK, Switzerland) at the first dawn report, never on
  top of the name entry or a story scene.
