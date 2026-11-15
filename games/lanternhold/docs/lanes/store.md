# Lanternhold v1: the store lane (`claude/lh-store`)

The release kit for version 1: the listing in eight languages, the privacy and support pages, the draft answers for
Louis' go, the notes for App Review and the screenshot plan. Everything lives in `games/lanternhold/store/`. The lane
uploads and publishes nothing.

## store-1: the release kit (14.11.2026)

### What exists

| File | What it is |
|---|---|
| `store/listing/<lang>.md` (en, de, fr, es, it, pt-BR, ja, zh-Hans) | name, subtitle, promotional text, description, keywords and What's New for 1.0, each in a `text` block ready to paste, plus notes (register, terms, what each claim rests on). Written in each language, not translated line by line. |
| `store/tools/check_listing.py` | counts Apple's limits in every file, twice: with the `[if shipped]` lines kept and with them cut. Also the screenshot captions (40) and the review notes (4000). `--final` fails while any `[if shipped]` or `[check]` marker is left. Standard-library python; light, runs here. |
| `store/privacy.html` | the privacy policy in English and German, in Comet Cargo's published pattern, in the game's palette (parchment by day, the desk at night, House Lantern's teal band). Contact exactly as published: Louis Herwick, Germany, louis.ralf@web.de; no address. Names Google AdMob (the Google Mobile Ads SDK) and the Google User Messaging Platform, the check at launch, the form at the first dawn report, then ATT. Says the lord's name never leaves the device. Loads nothing from other servers (no web fonts). |
| `store/support.html` | the support and marketing page (published as `index.html`): pitch in English and German, the support e-mail, three questions (where the realm is saved, ad privacy choices, no music), the link to the privacy page. |
| `store/answers.md` | DRAFT for Louis' go: App Privacy (six data types from Google's page for SDK 13.12.0, linked and tracking per row), the IDFA question, the age rating (expected 13+, one line of reasoning per answer, grounded in the story catalogue), export compliance, content rights (Yes: the IM Fell typeface under the OFL and the ads are third-party content), and nine points not verified. |
| `store/review-notes.md` | App Review fields and Notes (about 3400 of 4000 characters): the game, the first minutes, the ads and where they appear, consent, no purchases, no account; `[check]` lines for what the rebuild changes; an internal checklist and test hints. |
| `store/screenshots.md` | eight landscape shots that sell the look (the hero night, the hall, building, the rule of light, the town, the court, the beacon, first light), each with a framing, starting launch arguments and a caption in eight languages; sizes and the caption strip. |

Limits as counted on the last commit (`python3 games/lanternhold/store/tools/check_listing.py`): ALL OK. Names 11,
subtitles 9 to 30, promotional texts 62 to 161, descriptions 1021 to 3489 characters with every line kept (835 to
2867 with every `[if shipped]` line cut), keywords 94 to 99 bytes, every keyword at least three characters, no word
of the name or subtitle in the keywords, captions at most 39 characters.

### What was checked on the web (14.11.2026)

- Apple, App Store Connect help, "Platform version information": promotional text 170 characters, description 4000,
  What's New 4000, keywords **100 bytes**, each keyword "greater than two characters", no app or company names.
- Apple, "App information": name 2 to 30 characters, subtitle 30.
- Apple, "Screenshot specifications": the required iPhone size is now **"iPhone with Dynamic Island (medium
  display)"**, 2622 x 1206 landscape (iPhone 17 Pro); the 6.9-inch size (2868 x 1320) is accepted but no longer the
  required one. `docs/store-checklist.md` step 7 still says 6.9-inch is required: the lead should update it (shared
  file, not edited here).
- Apple, "Age ratings values and definitions": the tiers 4+, 9+, 13+, 16+, 18+ and what each answer rates.
- Apple, "App privacy details on the App Store": the definitions of tracking, linked data, purposes and data types.
- Google, "App store data disclosure" for the Mobile Ads SDK on iOS: described as of 13.12.0, no date shown; no
  separate page for the UMP SDK.
- Recraft's documentation on ownership (paid-plan images are the user's, with commercial rights).
- A web search for "Lanternhold": no game of that name found (the App Store's own check comes when the record is
  created).

### Hooks

None in existing files: this step only added new files under `store/`, `docs/lanes/store.md` and nothing else. For the
join and the release, other places need these (none is this lane's file):

1. **Settings: a "Privacy policy" row** opening `https://louisralfi-maker.github.io/spiele-welle/lanternhold/privacy.html`,
   next to the ads lane's PrivacyChoicesRow (Apple guideline 5.1.1(i): the policy must be reachable inside the app;
   Comet Cargo has it as `AdConfig.privacyPolicyURL`). Neither the ads brief nor the stage brief names it yet.
2. **Publishing the pages** (only with Louis' go, an outward step): on `main`, where `pages/` and
   `tools/publish-pages.sh` live (this branch, cut from planning, has neither), copy `store/support.html` to
   `pages/lanternhold/index.html` and `store/privacy.html` to `pages/lanternhold/privacy.html`, commit, run
   `tools/publish-pages.sh`. The privacy page links back to `./`, which resolves to the support page only once
   published.
3. **AdMob:** the "European regulations" consent message for the Lanternhold app needs the published privacy URL
   first (Comet Cargo's lesson); without it the UMP form shows nothing.
4. **The support page quotes "Privacy choices" / "Datenschutzoptionen"**: match it to the ads lane's strings at the
   join.
5. **Terms in fr, es, it, pt-BR, ja, zh-Hans** were chosen here before the i18n lane's glossary existed (each
   listing's Notes list them; ja and zh-Hans leave the house's name out on purpose). Align them with
   `tools/i18n/glossary.md` after the join; then rerun `check_listing.py`.

### Rounds

None: the step forbids runner rounds, and nothing in the build changed.

### Open, and what waits for the join

- `[if shipped]` lines in every description: the ledger (stage-3 idea), raise the lantern (stage-2 idea), the three
  ending slides (panels lane), endless mode (not built), the Lantern Table (quests lane), the six other languages
  (i18n lane and the interface strings). One line in the review notes: the Merchant's gift at Marek's cart (ads lane,
  wired at the join). The director cuts each line or drops its marker.
- `[check]` lines in the review notes: the title screen, touching the world, "Sound the horn" in the pause menu, and
  the settings' privacy rows, all from the rebuild.
- The screenshots themselves (a later step, after the rebuild): both sizes, the caption strip, upright copies.
- `answers.md` section 6: the ads in the build, the SDKs' own privacy manifests (a runner step that prints them is
  proposed there), the SDK version, Recraft's terms in full, the IDFA question, the EU trader status, the AdMob
  consent message.
- Outside this lane, noticed on the way: Comet Cargo's published German privacy page quotes the iOS tracking button
  as „Bitten, nicht zu tracken“; iOS in German says „App bitten, kein Tracking durchzuführen“ (Lanternhold's page
  uses the latter). Worth a check on Comet Cargo's page.
