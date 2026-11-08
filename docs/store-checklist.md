# App Store, AdMob and privacy: per game

Piston Empire went through all of this for its 1.0 (live since 04.11.2026). Its texts are templates in `/Users/enaayla/Desktop/Piston Empire/docs/handoff/plans/release-kit/`:

- `checklist.md`
- `metadata-de.md`, `metadata-en.md`
- `age-rating-answers.md`, `app-privacy-answers.md`
- `privacy-policy.html`, `support.html`
- `review-notes.md`

## Accounts and ids

- **Apple:** developer Louis Herwick, team `XLKZ9W7C7T`.
  - Bundle ids: `com.louisherwick.<slug>`, lowercase.
  - The developer program fee is already paid, so new free apps cost nothing.
  - The Paid Apps agreement is not needed for free apps with ads.
- **AdMob:** publisher `ca-app-pub-4855617456569312`.
  - Every game needs its own AdMob app and its own ad units (rewarded, interstitial).
  - Louis creates them in the AdMob console, or you do it in the built-in browser if he is signed in and gives his go.
- **app-ads.txt** is already live at `https://louisralfi-maker.github.io/app-ads.txt`. It covers every app whose store listing names a marketing website on that host; the crawler strips the path, so a game's own page there counts.
- **Pages:** each game's support and privacy pages live in `pages/<slug>/` and go out with `tools/publish-pages.sh` to the `gh-pages` branch, which GitHub Pages serves at `https://louisralfi-maker.github.io/spiele-welle/<slug>/` (Comet Cargo since 08.11.2026). Never publish an address there. Publishing a page is an outward step: say what you publish.

## Steps

1. **Build settings** (see `docs/reuse.md`):
   - AdMob app id as the build setting `GAD_APPLICATION_IDENTIFIER`, read into Info.plist as `GADApplicationIdentifier`;
   - Google's `SKAdNetworkItems` list in Info.plist;
   - `NSUserTrackingUsageDescription`;
   - `ITSAppUsesNonExemptEncryption = NO`;
   - the privacy manifest with `NSPrivacyTracking` false.
2. **AdMob:**
   - Privacy & messaging: publish the EU consent message (GDPR) for the app. Without it, the UMP form shows nothing and EU users get no personalised ads.
3. **App Store Connect API key** (once, Louis): Users and Access → Integrations → App Store Connect API → Team Keys → "+".
   - He picks the role **Admin** and downloads the `.p8` once. App Manager is not enough for the runner: `xcodebuild -exportArchive -allowProvisioningUpdates` with an API key needs Admin to create the cloud-managed distribution certificate ("Cloud signing permission error" otherwise; Apple developer forums threads 698117 and 690676, checked 08.11.2026).
   - He keeps it at `~/.appstoreconnect/private_keys/AuthKey_<KEYID>.p8` on this Mac, and adds it as Actions secrets in the repo for the runner.
   - He tells you the Key ID and Issuer ID, which are not secret. The key file never goes through chat.
4. **Bundle id:** register it through the API, or let automatic signing create it.
5. **App record:**
   - If the API cannot create the app record, Louis clicks "+" → "New App" in App Store Connect. Guide him with the exact fields: platform iOS, name, primary language, bundle id, SKU = slug.
   - Check the name is free first; App Store names are unique.
6. **Store listing in all eight languages:** name (30 characters), subtitle (30), description, keywords (100 characters, comma-separated, no spaces after commas, no competitor names), promotional text, support URL, marketing URL, privacy policy URL.
7. **Screenshots:** the 6.9-inch set is required (1320 x 2868 portrait or 2868 x 1320 landscape), from the UI tests on the runner. A caption strip in the game's style helps. Strip the EXIF orientation of landscape captures.
8. **App Privacy:** AdMob collects the device id (advertising), coarse location from IP, product interaction and diagnostics. Copy and adapt Piston Empire's `app-privacy-answers.md`; the game's own code collects nothing.
9. **Age rating** questionnaire: adapt `age-rating-answers.md`.
   - Answer "Advertising: Yes". Apple lists that as 4+, so it does not raise the rating.
   - Keep the ads' own content in line: Piston Empire's `AdManager` sets `MobileAds.shared.requestConfiguration.maxAdContentRating = .general`.
   - Do not use the higher age rating override, and never the Kids category.
10. **Upload:**
    - archive and export on the runner with `xcodebuild -exportArchive` and an export options plist with method `app-store-connect` and destination `upload`, plus `-allowProvisioningUpdates` and the `-authenticationKeyPath/-authenticationKeyID/-authenticationKeyIssuerID` flags;
    - processing takes 10 to 30 minutes;
    - the build number goes up with every upload.
11. **Review notes:** how to play, that there is no login, and that the ads are Google AdMob test ads in review builds only if that applies.
12. **Submit:** ask Louis in chat first: "Spiel X ist fertig, alle Angaben gesetzt. Darf ich einreichen?" Submit only after his go.
    - The go covers that one submission. The legal answers (privacy, age, export, content rights) are statements in his name.
    - Then tell him what was sent.
13. **After approval:**
    - link the AdMob app to the store listing (AdMob → App settings → link to a store); Google's review takes 2 to 3 days;
    - watch the first crash and ad reports;
    - ship a small update within a few weeks.

## If Apple rejects

Read the message calmly and fix the real cause. If it cites 4.3, do not resubmit the same app. Tell Louis and change the game substantially, or drop it. Repeated 4.3 rejections endanger the account.
