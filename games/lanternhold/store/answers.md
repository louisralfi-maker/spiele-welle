# Lanternhold 1.0: App Store Connect answers (DRAFT)

> **DRAFT, NOT FOR ENTRY YET.** Every answer below is a legal statement in Louis Herwick's name (App Privacy, age
> rating, export compliance, content rights). Nothing is entered in App Store Connect until Louis has read this page
> and given his go in chat, and his go covers that one submission. Written by the store lane on 14.11.2026 from the
> build-86 code, DESIGN.md, STORY.md, the story catalogue and the ads lane's brief; re-check every row against the
> joined build (section 6 lists what could not be verified).

Sources read on 14.11.2026:

- Google, "App store data disclosure" for the Google Mobile Ads SDK on iOS
  (developers.google.com/admob/ios/privacy/data-disclosure): practices described "as of 13.12.0"; the page shows no
  "last updated" date. Google publishes no separate disclosure page for the User Messaging Platform (UMP) SDK.
- Apple, "App privacy details on the App Store" (developer.apple.com/app-store/app-privacy-details): the definitions
  of tracking, linked data, purposes and data types quoted below.
- Apple, "Age ratings values and definitions" (App Store Connect help): the categories, the levels and what each
  level rates.
- Piston Empire's live answers (release-kit `app-privacy-answers.md`, `age-rating-answers.md`; read only), which passed
  review with the same ad SDKs.

## 1. App Privacy (App Store Connect › the app › App Privacy)

**What the game's own code collects: nothing.** No account, no analytics, no server of ours, no network call of our
own. The lord's name and title stay in the save on the device; no ad request carries them (DESIGN.md "The lord pass":
"The name never leaves the device"). Every row below comes from the Google Mobile Ads SDK and the UMP SDK, which the
ads lane adds (`games/lanternhold/Ads`, packages GoogleMobileAds and GoogleUserMessagingPlatform as in Comet Cargo).

Apple's rule: declare what the app and its partners can collect when the user allows the most, so the label is the
same whether or not the player taps "Ask App Not to Track". Apple's "tracking": linking data from the app with other
companies' data for targeted ads or ad measurement, or sharing it with a data broker. "Linked": tied to the user's
identity, including through a device ID, unless it was de-identified before collection.

Question "Do you or your third-party partners collect data from this app?": **Yes.**

| Apple data type | Purposes to tick | Linked | Tracking | Reasoning, and what it rests on |
|---|---|---|---|---|
| Location › **Coarse Location** | Third-Party Advertising, Analytics | Yes | Yes | Google: "location derived from IP address or collected from the Approximate Location Services API, if allowed by users". Lanternhold never asks for location, so only the IP-derived kind applies; it feeds ad targeting with the device ID when tracking is allowed. |
| Identifiers › **Device ID** | Third-Party Advertising, Analytics | Yes | Yes | Google: "the device's advertising identifier or other app- or developer-bounded device identifiers" for "third-party advertising and analytics". The IDFA is the tracking identifier itself; the ATT prompt guards it. |
| Usage Data › **Product Interaction** | Third-Party Advertising, Analytics | Yes | Yes | Google: "app launch taps, and interaction information, like video views", "to improve advertising performance". In Lanternhold: the rewarded videos and the interstitial at the dawn report. |
| Usage Data › **Advertising Data** | Third-Party Advertising, Analytics | Yes | Yes | Google: "advertisements the user has seen", for "analytics and advertising features". |
| Diagnostics › **Crash Data** | App Functionality, Analytics, Third-Party Advertising | No | No | Google: "non-user related crash logs ... to diagnose problems and improve the SDK"; "diagnostic information may also be used for advertising and analytics". Non-user related, so not linked. |
| Diagnostics › **Performance Data** | App Functionality, Analytics, Third-Party Advertising | Yes | No | Google: "user-associated performance data such as app launch time, hang rate, or energy usage", used to evaluate behaviour and "for displaying ads". User-associated, so linked; not used to link with other companies' data, so tracking No (the safest reading would say Yes; that only adds "Diagnostics" to "Data Used to Track You"). |

Leave every other type unticked: Contact Info, Health & Fitness, Financial Info, Sensitive Info, Contacts, User
Content (the lord's name never leaves the device, so it is not "collected" in Apple's sense: data is collected when it
is transmitted off the device), Browsing History, Search History, Purchases (there are none), Surroundings, Body,
Other Data, Other Usage Data, Other Diagnostic Data. Data Apple collects itself is not ours to declare; e-mails sent to
the support address are outside the app.

Expected preview: Data Used to Track You: Location, Identifiers, Usage Data. Data Linked to You: Location,
Identifiers, Usage Data, Diagnostics. Data Not Linked to You: Diagnostics. This is the same label as Piston Empire's.

Privacy Policy URL: `https://louisralfi-maker.github.io/spiele-welle/lanternhold/privacy.html` (the page in
`store/privacy.html`; it must be published first, with Louis' go). User Privacy Choices URL: leave empty.

**The UMP SDK.** At launch it asks Google whether a consent form is needed where the player is (IP address and basic
device information), and stores the player's choices on the device. Google documents no separate data types for it;
what it sends is covered by Coarse Location and Device ID above. Verify with the SDKs' own privacy manifests
(section 6).

## 2. Advertising identifier and the tracking prompt

- Because Device ID and others say "tracking: Yes", the app must show the App Tracking Transparency prompt before the
  IDFA is read, and Info.plist needs `NSUserTrackingUsageDescription` in all eight languages. The ads lane's brief
  does both: the UMP form, then the ATT prompt, at the first dawn report, before the first ad request.
- The game's own `PrivacyInfo.xcprivacy` keeps `NSPrivacyTracking` false with no domains (the house rule; Google's
  SDKs ship their own manifests, merged at build time).
- If App Store Connect asks "Does this app use the Advertising Identifier (IDFA)?": **Yes**, tick only "Serve
  advertisements within the app", and tick the confirmation that the app honours the user's tracking choice if one is
  shown. Reasoning: the IDFA is used only by AdMob to serve ads; we attribute no installs and measure no campaigns.
  Developer reports say this question left the submission form around 2020 to 2021, when App Privacy and ATT
  replaced it; Piston Empire's checklist still lists it. If it does not appear, nothing is lost: App Privacy and the
  prompt cover it.

## 3. Age rating (App Store Connect › App Information › Age Rating)

**Expected result: 13+.** Apple's current tiers are 4+, 9+, 13+, 16+ and 18+. Three answers below each lead to 13+ on
their own (frequent fantasy violence, frequent weapons, infrequent alcohol references), so the result does not hang on
one judgement call. Do not use the higher age rating override; never the Kids category (the app shows ads with the
tracking prompt; Made for Kids: No).

| Category | Question | Answer | Rating it gives | Reasoning, and what it rests on |
|---|---|---|---|---|
| In-App Controls | Parental Controls | No | | The game has none. |
| In-App Controls | Age Assurance | No | | No age check. |
| Capabilities | Unrestricted Web Access | **No** | | No browser, web view or link of the game's own. A tapped ad opens its page through the ad SDK; the player cannot browse freely from the game. (Answering Yes would rate 16+.) |
| Capabilities | User-Generated Content | No | | The player types a name for the lord or lady; it is shown only on that device and shared with nobody (DESIGN "The lord pass"). |
| Capabilities | Social Media | No | | |
| Capabilities | Messaging and Chat | No | | Single-player, offline. |
| Capabilities | **Advertising** | **Yes** | 4+ | AdMob rewarded videos and a rare interstitial (DESIGN "Ads"). |
| Mature Themes | Profanity or Crude Humor | None | | A scan of the 882 story strings finds no swearing or crude words; Pip's jokes are dry, not crude. |
| Mature Themes | Horror/Fear Themes | **Infrequent** | 9+ | The Gloom's creatures are figures of smoke that "were once people", with hollow glowing eyes; the night ambience has far, wordless moans; the defeat card darkens the town's windows. STORY.md's tone: "dread by what is missing", no gore, no screaming, no jump scares. Mood rather than terror, so Infrequent; Frequent would also give 13+. |
| Mature Themes | Alcohol, Tobacco, or Drug Use or References | **Infrequent** | 13+ | References only, never shown being consumed in the scene: a tavern on the town plot, an alehouse brawl petition (`petition.tavern_brawl`, choice "both sides drink"), wine for a wedding (`petition.wedding_feast`), a merchant's toast (`line.marek_endless`). No tobacco, no drugs. |
| Medical or Wellness | Medical or Treatment Information | None | | |
| Medical or Wellness | Health or Wellness Topics | None | | |
| Sexuality or Nudity | Mature or Suggestive Themes | None | | A wedding and a widow's pension are the closest; nothing suggestive. |
| Sexuality or Nudity | Sexual Content or Nudity | None | | |
| Sexuality or Nudity | Graphic Sexual Content and Nudity | None | | |
| Violence | **Cartoon or Fantasy Violence** | **Frequent** | 13+ | Every night is a battle, and the night is half the game: archers and fire arrows, a ballista, a catapult's firepots, stake pits and guards against smoke creatures, which dissolve into soot; walls break; soldiers can fall and are named in the dawn report. No blood, small pixel figures (about 30 game pixels), clearly fantastical. Frequent because it is the core loop, not an occasional scene. |
| Violence | Realistic Violence | None | | Nothing violent between humans is shown. Two text-only mentions: a deserter's petition offers "Flog him, as the law says" (reaction: "The boy takes his strokes without a sound"), and an alehouse brawl is reported after the fact. If Louis prefers to count them: Infrequent, which also gives 13+, so the result stays the same. |
| Violence | Prolonged Graphic or Sadistic Realistic Violence | None | | |
| Violence | **Guns or Other Weapons** | **Frequent** | 13+ | Apple's definition covers "guns, swords, or knives" and "objects that may cause bodily harm": bows, fire arrows, ballista bolts, catapult firepots and the guards' blades are used every night. No guns. |
| Chance-Based Activities | Gambling | No | | No wager of money or anything of value. |
| Chance-Based Activities | Simulated Gambling | None | | Some petition choices have a hidden chance outcome (`chance` in the petition data); there is no betting, casino, card or dice mechanic. |
| Chance-Based Activities | Contests | None | | |
| Chance-Based Activities | Loot Boxes | No | | Nothing is sold; nothing random is bought. |

Regional ratings follow from these answers: no gambling, no loot boxes and no social features, so nothing to add for
Australia, Brazil or Korea. If App Review asks about the violence: "Side-view pixel-art battles against creatures of
smoke that dissolve into soot when defeated; no blood or gore."

Re-check when: the Lantern Table's sendings (a lost lantern means lost people; its texts are new), the ending slides
and the prologue arrive, any text mentions drink or punishment anew, or the ads' content rating changes (keep
`maxAdContentRating = .general`, as the ads lane's brief says).

## 4. Export compliance

**Answer: the app uses no non-exempt encryption.** `ITSAppUsesNonExemptEncryption = NO` is already in
`project.yml` (it was set for build 86), so App Store Connect asks no export questions at upload. Reasoning: the
game's own code encrypts nothing; the Google SDKs reach Google over HTTPS through Apple's networking stack, which is
encryption provided by the operating system and exempt. If the question appears anyway: "None of the algorithms
mentioned above" (or "standard encryption within Apple's operating system only"). No French encryption declaration
and no annual self-classification report are needed for exempt encryption.

## 5. Content rights

**Question "Does your app contain, show, or access third-party content?": Yes. "Do you have all necessary rights?":
Yes.** Reasoning, item by item:

- **The typeface:** IM Fell English by Igino Marini, under the SIL Open Font License 1.1, which allows bundling in a
  commercial app; the licence text ships in the app (`Resources/Fonts/IMFell-OFL.txt`). This is third-party content,
  so "No" would be untrue.
- **The ads:** Google AdMob shows third-party ads under Google's terms.
- **The art:** made for the game: Recraft paintings (`tools/recraft.sh`, model recraftv4_1, on Louis' paid API
  credits), converted to the palette and finished by hand in the art pipeline, plus hand-set sprite grids. Recraft's
  documentation says images generated on a paid plan are the user's own, with commercial rights, and stay so after a
  subscription ends.
- **The sound:** 26 effects synthesised from code by `tools/soundsynth.py`; no recorded or licensed audio, no music.
- **The texts:** the story, the petitions and the court lines were written for the game.
- **Names:** original (DESIGN.md "Not a copy"); no real brand, no other game's names, characters, art or levels.

## 6. What could not be verified (check before Louis' go)

1. **The build with ads.** No ad code exists in build 86. Every answer about ads rests on DESIGN.md "Ads" and the ads
   lane's brief; check against the joined build: where the offers stand, the interstitial's rules, the order UMP →
   ATT at the first dawn report, `maxAdContentRating = .general`, `NSUserTrackingUsageDescription` in eight languages.
2. **The SDKs' privacy manifests.** The label above follows Google's page, not the frameworks' own
   `PrivacyInfo.xcprivacy`. This Mac must not build, so there is no Xcode privacy report here. Proposal: a runner step
   after package resolution that prints both manifests (`plutil -p` on the GoogleMobileAds and UMP xcframeworks'
   `PrivacyInfo.xcprivacy`) into the round's log; if they list a type that is not in section 1, add it.
3. **Whether Google's data list changes with the SDK version** the ads lane pins (the page describes 13.12.0).
4. **The Unrestricted Web Access answer** assumes the SDK opens ad pages only as ads do; the game must add no web view,
   link list or "more games" page.
5. **The age rating's text basis** was a scan of the English story catalogue in build 86 (882 strings). The Lantern
   Table, the slides, the onboarding lines and the new hall texts are not written yet.
6. **Recraft's terms** were read from Recraft's own documentation (paid-plan ownership); the current Terms of Service
   were not read in full, and that the credits were bought on a paid account is Louis' fact to confirm.
7. **The IDFA question** may or may not appear in today's submission form (section 2).
8. **The EU trader status** (Digital Services Act) is set once per developer account, not per app; it was handled for
   Piston Empire. If App Store Connect asks anything new about it, ask Louis, because a trader's contact details are
   shown on EU product pages.
9. **Switzerland in the consent text.** The privacy page says the UMP form applies in the EEA, the UK and Switzerland
   (Google's EU user consent policy). Check that the AdMob "European regulations" message is published for the
   Lanternhold app before release, or the form shows nothing.
