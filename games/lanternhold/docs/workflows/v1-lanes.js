export const meta = {
  name: 'lanternhold-v1-lanes',
  description: 'Lanternhold v1: five gated Opus 5.5 lanes next to the rebuild (Lantern Table, ads, story slides, six languages, store kit)',
  phases: [{ title: 'Quests' }, { title: 'Ads' }, { title: 'Panels' }, { title: 'Languages' }, { title: 'Store' }],
}

// The director (Fable 5.2) wrote this on 14.11.2026 after Louis lifted the agent limit for Opus 5.5 agents.
// It runs NEXT TO docs/workflows/rebuild.js (world and stage lanes). Every worker names its model: no Fable.
const OPUS = 'claude-opus-5-5'
const ROOT = '/Users/enaayla/Desktop/Spiele-Welle/.claude/worktrees'
const PLAN = ROOT + '/game2-planning-354541'
const DIR = PLAN + '/ci-out/director'
const G = 'games/lanternhold'

const LANES = {
  quests: { name: 'quests', wt: ROOT + '/lh-q', branch: 'claude/lh-q', phase: 'Quests',
    critic: "a game designer and a senior Swift reviewer. Check each promise of the step against the code, the tests and the round's logs (the unit log: test counts, the neutrality test, the targets); read the engine for determinism and save safety; read EVERY English and German text of the step for voice, length and craft (the court's voice of STORY.md; German must read as written, not translated); view the step's screenshots in English and German" },
  ads: { name: 'ads', wt: ROOT + '/lh-ads', branch: 'claude/lh-ads', phase: 'Ads',
    critic: "an App Review and AdMob policy reviewer and a senior Swift reviewer. Check every rule of DESIGN.md's section 'Ads (AdMob, no purchases)' against the code and its unit tests: no ad can show in a forbidden moment; the consent order (UMP, then ATT, then ads); NSPrivacyTracking false with no tracking domains; Google's test units in Debug and the real ids only in Release; a reward is granted only on the SDK's earned callback; a missing or failed ad never blocks play; every offer names its reward and says that a video plays; no dark patterns; the no-ads and stub flags work in the UI tests; the screenshots in English and German" },
  panels: { name: 'panels', wt: ROOT + '/lh-panels', branch: 'claude/lh-panels', phase: 'Panels',
    critic: "an art director and a first-time player. Judge every slide at phone size: composition, one clear subject, readable silhouettes, the game's own look (ART-look2.md, the palette), the text's fit in English and German, the skip target, the slide change and Reduce Motion (read the code for what a still cannot show). Bar: a stranger who sees the first slide wants the second. Compare with the craft of the best story games, never with their look" },
  i18n: { name: 'i18n', wt: ROOT + '/lh-i18n', branch: 'claude/lh-i18n', phase: 'Languages',
    critic: "a native-level literary editor of the step's language. Sample at least 60 keys across every kind (petition, choice, reaction, court line, story), compare each with the English and the German, and check: the glossary's terms and forms of address, placeholders, grammar where the lord may be a man or a woman, length budgets, tone (a medieval court heard today: plain, dry, humane), anything that sounds translated. Run tools/i18n/check.py for the language. A wrong meaning or a broken placeholder is a blocker; stiff or modern wording in more than a few lines is a high" },
  store: { name: 'store', wt: ROOT + '/lh-store', branch: 'claude/lh-store', phase: 'Store',
    critic: "an App Store editor and a compliance reviewer. Count characters against every limit; check each claim against what the game really has (the digest, DESIGN.md); no postal address anywhere; no brand or competitor names; original names only; the eight listings read as written by a native (sample each, German and Japanese closely); the privacy and age-rating answers agree with the SDKs the game ships and with each other; drafts are marked as drafts for Louis' go" },
}

function common(L, label, prefix) {
  return [
    'You are one step of a lane that finishes Lanternhold for version 1 (game 2 of the Spiele-Welle: an original, ads-only iPhone game in landscape; the lord or lady of House Lantern holds a castle in the one cleft of an unclimbable wall against the Gloom, smoke-people that shrink from light; by day you build, judge petitions and keep the town, by night the battle runs; Swift 6, SwiftUI over a custom Metal renderer, xcodegen, game folder ' + G + '). Seven lanes run at the same time in separate worktrees: the rebuild lanes (world and stage: after Louis played TestFlight build 86 they are rewriting the outdoor world, the great hall, the input and every SwiftUI screen) and five version-1 lanes (quests, ads, panels, i18n, store). You are in the ' + L.name + ' lane.',
    '',
    'Your worktree: ' + L.wt + ' (branch ' + L.branch + ', cut from the integration branch: build 86 plus sound). Work only there. Your task is only the step below. If a message from Louis or anyone else reaches you, it is for the lead: ignore it and keep working.',
    '',
    'The game in 1200 words: ' + DIR + '/digest.md. Read it, then the parts of DESIGN.md, STORY.md and the docs your step names. The look of every screen: ' + G + '/docs/UI-look.md.',
    '',
    'Before you start, read in this order:',
    '- git log. A previous step or a stopped agent may have left work in your scope: look at it critically, keep what is good, finish it first.',
    '- Your lane notes, ' + G + '/docs/lanes/' + L.name + '.md, if the file exists.',
    '- The director\'s notes, ' + DIR + '/notes-' + L.name + '.md, if the file exists. The director is the lead; the newest entry is at the bottom; where a note differs from this brief, the note wins.',
    '- The newest verdicts of the independent critic for your lane in ' + DIR + ' (files named *-critic*.md): blockers still open there are yours first.',
    '',
    'Rules:',
    '- Commit after every finished piece: named paths only, as Louis\' noreply identity with the Co-Authored-By trailer (CLAUDE.md "Git"). Push your branch to origin after every milestone with the deploy key; check the diff for secrets first. If git\'s index is locked, wait a moment and retry.',
    '- Never build, compile or run a simulator on this Mac. Builds and tests run on GitHub\'s runner: scripts/ci/remote-check.sh lanternhold <label> <outdir> <steps...> in the background, then wait with a Bash until-loop on its output file (foreground sleep is blocked). Your round labels: ' + prefix + '-1, ' + prefix + '-2 and so on (if a label already has a ci-results branch on origin, take the next free number); never tf-*. Outdirs go under ci-out/ in your worktree (git-ignored). The runner takes 5 macOS jobs at once and seven lanes share it: a round that waits in the queue is normal, keep waiting and never send it twice. Use unit and ui filters for quick checks. Unless your step says otherwise, end with one full round (build, unit, ui, ui-de, release) that ends ALL PASSED.',
    '- This Mac is old and powers off under load. Every image job (python art scripts, sips, Recraft downloads) goes through the art lock, one image per call where you can: bash ' + DIR + '/artlock.sh <command...> (it waits for the lock, for other lanes\' image jobs and for a cool CPU). Long number crunching (bots, tuning, optimizers) runs in unit tests on the runner, never here. Recraft credits are allowed (bash tools/recraft.sh); never read, print or copy a key file.',
    '- No Fable. If you start a helper agent, name its model: opus, and run at most one helper at a time.',
    '- Landscape XCUITest screenshots carry EXIF orientation 8: make upright copies (through the art lock: sips -s format bmp, then sips -s format jpeg, one at a time) of every screenshot you judge, in one folder. Judge your own result harshly, as a player and against the bar, and fix what fails before you finish. Never stop at "it works". After you, an independent critic who owes you nothing checks the same result; what the critic finds comes back to this lane as a fix round.',
    '- Keep the simulation and the tuning targets T1 to T8 unless your step says otherwise; the unit tests stay green.',
    '- Merge safety. Your branch joins the rebuilt game later, and the rebuild lanes are changing most existing files right now. So: put your work in new files and folders of your own; touch existing files only with the smallest hooks; list every hook (file, place, why) in your lane notes so the join can apply it again; do not edit DESIGN.md, SPRITES.md, ART-look2.md, Localizable.xcstrings or Story.xcstrings unless your step says so. Your player-facing strings go into a string catalog of your own (named in your step), in English and German now (German runs about 35 % longer and must fit); the six other languages follow in one pass after the join.',
    '- Touch targets at least 44 pt; Reduce Motion respected; no music, ever (sound effects and haptics only); original names only, no real brands; no postal address anywhere.',
    '- Record what you built in ' + G + '/docs/lanes/' + L.name + '.md (create it; one heading per step: what exists, the hooks, the rounds and their results, what is open and what waits for the join).',
    '',
    'Your final answer goes to the lead, not to Louis: the commits, the last round\'s label and result, what is still open, and (if your step has pictures) the absolute path of the folder with the upright screenshots and up to six absolute paths that show your result best. As your last action, write the same report to ' + DIR + '/' + label + '.md (mkdir -p the folder).',
  ].join('\n')
}

const QUESTS = [
  { label: 'quests-1-engine', prefix: 'lh-q1', task: [
    'STEP quests-1: the engine of the Lantern Table.',
    'The spec is ' + G + '/docs/QUESTS.md: sendings on the realm map, thirteen for chapter 1. Louis decided (its section "Louis\' decisions"): the full table of thirteen at launch; a lost lantern leaves its hook empty for the chapter; the map opens only at the table. Read all of it.',
    '- Build what its section 7.2 calls round lh-q-1: the data format and its loader, ErrandEngine, TableState, the save, the validator, and TableNeutralityTests (with the table\'s files loaded and nobody sent, the reference bot\'s run equals today\'s line for line).',
    '- Sendings 1, 5 and 11 complete in English and German.',
    '- A plain list screen, reachable through the house\'s debug arguments (-GWScreen table or the pattern you find), good enough for a UI test: it sends Pip on day 2 and reads his report on day 3.',
    '- Hooks into Core (the day\'s clock, the dawn report\'s data, the save) are allowed, small and listed. Strings: ' + G + '/Resources/Quests.xcstrings.',
    '- Deterministic and seeded as section 4.2 says. Unit tests for every rule of section 2 that the three sendings use.',
  ].join('\n') },
  { label: 'quests-2-content', prefix: 'lh-q2', task: [
    'STEP quests-2: all thirteen sendings, and the numbers.',
    '- QUESTS.md section 3: every sending in English and German: slip, orders, report cards, within section 5.5\'s budgets. Writing bar: each slip and report is a small story in the court\'s voice of STORY.md, with one detail a player remembers; no filler, no modern words; the German is written, not translated.',
    '- Section 4.3 and 4.4: the sender bot and the greedy bot, the targets T10 and T11 and the table of section 4.4, tuned by values only. Bots and tuning run in unit tests on the runner.',
    '- T1 to T8 stay as they are for a player who never sends anyone (the neutrality test of step 1 stays green).',
    '- The validator covers all thirteen; every risk of section 2.7 has a test.',
    '- If section 7.5 lists points for the story lane to confirm, decide them yourself in the spirit of STORY.md and write down what you decided.',
  ].join('\n') },
  { label: 'quests-3-table', prefix: 'lh-q3', task: [
    'STEP quests-3: the table as a real screen.',
    '- QUESTS.md sections 5.2 to 5.5 and 6: Overlay.table in the look of docs/UI-look.md: the carved realm map with the places of section 3.1, the lantern rail, the slip, the choice of orders, the report card. Reduce Motion as 5.4; German lengths as 5.5. It replaces the plain list of step 1.',
    '- A director\'s idea, unless section 2.1 already says it better: the rail is the status display. A lantern whose bearer is away burns on the map at the place it went to, and its hook on the rail is bare; a lantern at home stands dark on its hook; a lost lantern\'s hook stays empty and a little charred. One glance tells who is away and where. On the map a thin line of light creeps from the castle toward the place as the days pass, so "due tomorrow" is seen, not read.',
    '- The art of section 6 through the game\'s own pipeline (ART.md, tools/, the palette) and the art lock.',
    '- Not yours, because the walked world is being rebuilt: the table and rail standing in the chapel, the bearer leaving and coming home through the gate, the strip pip. Describe in the lane notes exactly how the join wires them.',
    '- The UI test sends Pip on day 2 and reads his report on day 3, with the shots 40-table, 41-slip, 42-report and 43-hook-empty in English and German.',
  ].join('\n') },
]

const ADS = [
  { label: 'ads-1', prefix: 'lh-ad1', task: [
    'STEP ads-1: the ads, in code, by the rules of DESIGN.md\'s section "Ads (AdMob, no purchases)". Read it and the section "Losing a night".',
    '- Copy the proven pattern: games/comet-cargo/Ads/AdConsent.swift and AdManager.swift, Comet Cargo\'s project.yml (packages GoogleMobileAds and GoogleUserMessagingPlatform, the Info.plist keys, SKAdNetwork items), its PrivacyInfo.xcprivacy and docs/reuse.md\'s section on ads. NSPrivacyTracking is never true and no tracking domains are listed. /Users/enaayla/Desktop/Piston Empire is read-only.',
    '- The ids (not secret): AdMob app ca-app-pub-4855617456569312~7252229972, rewarded ca-app-pub-4855617456569312/4289035611, interstitial ca-app-pub-4855617456569312/4626066634. Release uses them; Debug uses Google\'s published test units. maxAdContentRating general.',
    '- A folder of its own (' + G + '/Ads). Behind a protocol: the Google provider, a stub (-GWAdStub YES: a rewarded "video" that ends at once and grants, for UI tests) and none (-GWNoAds YES: no SDK call at all; every existing UI test and every screenshot run uses it).',
    '- The rules live in Core as a pure, saved, unit-tested type with an injected clock: which offer is open at this dawn, the interstitial\'s conditions (at most every third in-game day, at least 6 real minutes after any ad, never before day 4, never on a story dawn, never right after a rewarded video, never at night, at the throne or in a story scene, at most once after a chapter ending). One test per rule.',
    '- Consent without spoiling the first minutes: the consent info is refreshed silently at launch; the UMP form and then the ATT prompt appear at the first dawn report, before the first ad is ever requested. A PrivacyChoicesRow view for the settings screen (shown when UMP requires privacy options); the stage lane\'s settings include it at the join.',
    '- The three rewarded offers, each naming its reward on the button and saying plainly that a video plays: Double taxes in the dawn report; Second chance on the defeat card (in the fiction: the hearth is rekindled); the Merchant\'s gift as Core state plus an offer card. Marek\'s cart standing at the back gate is wired at the join; until then the card opens through a debug argument for the UI test. An offer shows only when a video is ready; without one the game goes on with no dead button.',
    '- The interstitial on "Continue" of the dawn report, by the rules above.',
    '- Strings: ' + G + '/Resources/Ads.xcstrings, and the tracking prompt\'s text for all eight languages as Comet Cargo does it. UI test with the stub: each offer in English and German, the reward lands.',
    '- The dawn report and the defeat card are being redrawn by the stage lane: keep your hooks there to one small view each that the join can place again.',
  ].join('\n') },
]

const PANELS = [
  { label: 'panels-1-prologue', prefix: 'lh-pn1', task: [
    'STEP panels-1: the slide stage and the prologue.',
    'The story\'s pictures do not exist yet. STORY.md has the prologue (four panels before day 1, skippable, one tap each; the fourth shows the chosen lord or lady), the three endings (three panels each) and their texts; the keys are in Story.xcstrings. Read STORY.md\'s sections on the prologue, the endings and the voice.',
    '- The director\'s idea, and the look of every panel: LANTERN SLIDES. Each panel is a painted glass slide thrown on the dark by a lantern: a dark surround, a warm vignette that breathes very slightly, soft dust in the beam, the picture a little brighter at its centre. A tap changes the slide: the old glass slides out sideways, a soft click (an existing sound effect), the next one settles. The text sits under the picture in the serif of docs/UI-look.md, two short lines at most. A small "skip" in a corner. Reduce Motion: cross-fades and no breathing. It is the house\'s own way of telling a story (House Lantern) and no other game\'s.',
    '- The pictures: painted in the game\'s own look (ART.md, ART-look2.md, tools/palette.txt; tools/portraitstory.py and the court\'s portraits are the reference for the people), wide, composed like a picture book: one clear subject, strong silhouettes, the lantern\'s warm light against the Gloom\'s cold dark. Bar: a stranger who sees the first slide wants the second. Original work only. Through the art lock.',
    '- Do not rewrite the story\'s texts. If a text is missing, add it to ' + G + '/Resources/Panels.xcstrings in English and German and say so in your report.',
    '- Code in a folder of its own (' + G + '/UI/Slides): a SlideShow driven by data (picture, text key, timing), reusable for the endings and later story beats. One hook: where day 1 begins after the name page. A debug argument -GWSlides prologue opens it directly.',
    '- A UI test taps through the prologue in English and German and saves every slide.',
  ].join('\n') },
  { label: 'panels-2-endings', prefix: 'lh-pn2', task: [
    'STEP panels-2: the three endings and the chapter\'s end.',
    '- The three endings as lantern slides, three each, by STORY.md (the first tells what happened, the second names the lord\'s leaning in one sentence, the third as the story says). Same stage, same bar as the prologue; each ending has its own light (which one is yours to decide from the story) so a player who sees a second ending feels the difference at once.',
    '- After the last slide, the chapter\'s end card in the look of docs/UI-look.md: the realm\'s tale in the few numbers a player cares about (nights held, judgments spoken, the leaning\'s name, who stood by you), then "Begin again" (a new realm). Only if Core already has the endless mode: also "Hold the realm". Do not build the endless mode; report what Core has.',
    '- Hook: the end of the finale (night 20), by outcome. Debug arguments -GWSlides ending1|ending2|ending3|end.',
    '- A UI test shows each ending and the end card in English and German.',
  ].join('\n') },
]

const LANGS = [
  ['fr', 'French'], ['es', 'Spanish (neutral, for Spain and Latin America)'], ['it', 'Italian'],
  ['pt-BR', 'Brazilian Portuguese'], ['ja', 'Japanese'], ['zh-Hans', 'Simplified Chinese'],
]

const GLOSSARY = { label: 'i18n-0-glossary', prefix: 'lh-i18n0', task: [
  'STEP i18n-0: prepare the six missing languages (fr, es, it, pt-BR, ja, zh-Hans) for the story texts.',
  'Scope: ' + G + '/Resources/Story.xcstrings (petitions, choices, reactions, court lines, the story; English and German exist). The interface strings in Localizable.xcstrings are NOT in scope yet (the interface is being rebuilt). No runner round in this step.',
  '1. Find how the catalogs, the validator and the text limits work (DESIGN.md "Languages and text", STORY.md, the tests and tools).',
  '2. In ' + G + '/tools/i18n/ write: export.py (writes story.en.json and story.de.json, each an object of key to text in the catalog\'s order, and chunks.json: the keys in numbered chunks of about 110, kinds kept together); check.py <lang> (every key present and none extra, the same set of placeholders such as {lord} in each text, the length budgets with a fair allowance per language, no empty text, no text left in English; prints a short report and exits non-zero on errors); merge.py (writes the six languages into Story.xcstrings and leaves English, German and the key order untouched). Standard-library python only; they are light, run them here. A README.md says how a translator works with them.',
  '3. Write glossary.md and decide everything; leave no options open. For each of the six languages: the fixed terms (House Lantern, the Gloom, every creature kind, every court office, every house); the names (which stay, which are transcribed, with katakana and hanzi fixed once); how the court addresses the lord and the lady and how the lord speaks to the people (the register for each language); how a text is written when the lord may be a man or a woman (follow what the catalog does for English and German); the voice in two sentences (a medieval court heard today: plain, dry, humane; no modern slang, no fantasy cliché); punctuation and quotation rules; when the German text decides an ambiguous English line.',
  'Commit and push.',
].join('\n') }

function langStep(code, name) {
  return { label: 'i18n-' + code, prefix: 'lh-i18n-' + code, task: [
    'STEP i18n-' + code + ': translate the story into ' + name + '.',
    'You are a literary translator and a native speaker. The bar is a published book, not a localization kit: every petition must read as if it had been written in ' + name + '.',
    '- Read ' + G + '/tools/i18n/README.md and glossary.md, and STORY.md\'s part on the voice. Work chunk by chunk through chunks.json from story.en.json, with story.de.json as the second witness of the meaning.',
    '- Write only ' + G + '/tools/i18n/story.' + code + '.json. Other languages\' translators work in this same worktree at the same time: touch no other file, stage and commit only your file, never run merge.py.',
    '- Keep the placeholders exactly; keep within the length budgets (a card must fit); follow the glossary to the letter. If the glossary is wrong for your language, write the correction and its reason into your report; do not edit the glossary.',
    '- Run python3 ' + G + '/tools/i18n/check.py ' + code + ' until it is clean. Then read forty petitions of your own text at random as a reader would and rewrite what sounds translated.',
    '- No runner round in this step, no pictures. Your report: the counts, the check\'s last output, ten lines you are proud of and five you are unsure of (with their keys).',
  ].join('\n') }
}

const MERGE = { label: 'i18n-merge', prefix: 'lh-i18n', task: [
  'STEP i18n-merge: bring the six languages into the catalog.',
  '- Read the six translators\' reports and the editors\' verdicts in ' + DIR + ' (i18n-*.md). Apply glossary corrections that a translator and an editor agree on, across that language\'s file.',
  '- Run check.py for all six until clean, then merge.py. Story.xcstrings is yours to edit in this step. Make the game\'s own validator and tests cover the six new languages where they cover German.',
  '- One round (build, unit) with label ' + 'lh-i18n-1' + ' (next free number) until ALL PASSED.',
  '- In the lane notes: how to translate keys that change later (the same tools, only the changed keys), and what is still missing (the interface strings, the new lanes\' catalogs).',
].join('\n') }

const STORE = [
  { label: 'store-1-kit', prefix: 'lh-st1', task: [
    'STEP store-1: the release kit, as files under ' + G + '/store/. You upload and publish nothing: no App Store Connect, no pages publishing, no runner round.',
    '1. listing/<lang>.md for en, de, fr, es, it, pt-BR, ja, zh-Hans: name (at most 30 characters), subtitle (30), promotional text (170), description (4000; its first three lines carry it), keywords (100 characters with the commas; no word of the name, no brand, no other game), what\'s new for 1.0. Written natively in each language, not word for word. Honest: only what the game has (the digest, DESIGN.md). Mark what is not built yet (the Lantern Table and anything else the digest lists as missing) with [if shipped] so the director can cut it. Never name or lean on another game.',
    '2. privacy.html and support.html in the pattern of the wave\'s published pages (docs/store-checklist.md, docs/reuse.md, tools/publish-pages.sh, Comet Cargo; /Users/enaayla/Desktop/Piston Empire is read-only): no postal address anywhere; the contact exactly as the published pages have it; AdMob and Google\'s consent platform named truthfully.',
    '3. answers.md, a DRAFT: App Privacy (the data the AdMob and UMP SDKs collect as Google documents it, linked or not, tracking), the age rating questionnaire (read what the game shows: battles against smoke creatures, no blood; judge honestly), export compliance, content rights, the advertising identifier. One line of reasoning per answer and what in the game it rests on. Each answer is a legal statement in Louis\' name: mark the file as a draft for his go and list what you could not verify.',
    '4. review-notes.md for App Review (what the game is; ads are AdMob rewarded and interstitial; no purchases; no account; where the ads appear), and screenshots.md: a list of eight 6.9-inch store screenshots that sell the game\'s look, with a caption per language (at most 40 characters). The captures come after the rebuild.',
    'If you have a web search tool, check Apple\'s current limits and Google\'s current data-disclosure page, and say what you checked.',
  ].join('\n') },
]

const FINDING = { type: 'object', properties: { where: { type: 'string' }, what: { type: 'string' }, fix: { type: 'string' } }, required: ['where', 'what', 'fix'] }
const VERDICT = { type: 'object', properties: { pass: { type: 'boolean' }, score: { type: 'number' },
  blockers: { type: 'array', items: FINDING }, highs: { type: 'array', items: FINDING }, keep: { type: 'string' } },
  required: ['pass', 'score', 'blockers', 'highs'] }

function criticPrompt(L, s, n, report) {
  return [
    'You are the independent critic of one step of Lanternhold\'s ' + L.name + ' lane (game 2 of the Spiele-Welle; game folder ' + G + '; the game in 1200 words: ' + DIR + '/digest.md). You owe the builder nothing. You are ' + L.critic + '.',
    '',
    'Read-only: change no file in the worktree ' + L.wt + ', make no commit, start no round. Never build or run a simulator on this Mac. If you need upright copies of screenshots that the builder did not make, write them to a folder under ' + DIR + ' through bash ' + DIR + '/artlock.sh, one at a time. No Fable; no helper agents.',
    '',
    'This is look ' + n + ' at step ' + s.label + '. The step\'s brief:',
    s.task,
    '',
    'The director\'s notes for the lane, if the file exists (they win over the brief): ' + DIR + '/notes-' + L.name + '.md. Earlier verdicts for this step are in ' + DIR + ' (' + s.label + '-critic*.md): say which of their findings are fixed.',
    '',
    'The builder\'s report (it may be missing; then look at git log, the lane notes ' + G + '/docs/lanes/' + L.name + '.md and the newest outdirs under ' + L.wt + '/ci-out/):',
    report || '(missing)',
    '',
    'How to judge:',
    '- Go through the brief promise by promise: kept, half, or missing. Look at the real thing (the code, the texts, the logs, the pictures), not at the report\'s words.',
    '- Louis\' bar: "mach\'s doch einfach besser als alle anderen". A player has never read a design document. What would make them put the phone down?',
    '- A blocker: the step\'s purpose is not reached, something is broken, a rule of the house is broken (ads in a forbidden moment, tracking, an address, a brand, a copied work, music), or a text or picture would embarrass the game. A high: clearly below the bar, but the step stands. Smaller things go into "keep" as one short list. Every finding names where (file, key or screenshot), what, and the fix you would make.',
    '- Score from 1 to 10 against the bar; 8 passes. pass is true only with no blocker and a score of 8 or more.',
    '- In "keep", also name what is good and must survive the fix round.',
    '',
    'Before you answer, write your verdict as readable text to ' + DIR + '/' + s.label + '-critic' + n + '.md (mkdir -p). Then return the structured verdict.',
  ].join('\n')
}

function fixPrompt(L, s, n, v) {
  return common(L, s.label + '-fix' + n, s.prefix + 'f' + n) + '\n\n' + [
    'FIX ROUND ' + n + ' for step ' + s.label + '. The independent critic looked at the step\'s result and found what follows. Fix every blocker' + (n === 1 ? ' and every high' : '') + '. If you are sure a finding is wrong, say why in your report and leave it; do not argue with a finding you can simply fix. Keep what the critic says to keep. The readable verdict is ' + DIR + '/' + s.label + '-critic' + n + '.md.',
    '',
    'Blockers: ' + JSON.stringify(v.blockers || []),
    'Highs: ' + JSON.stringify(v.highs || []),
    '',
    'The step\'s original brief, for reference (its rules on rounds, files and scope still hold):',
    s.task,
  ].join('\n')
}

async function gate(L, s, effort) {
  let report = await agent(common(L, s.label, s.prefix) + '\n\n' + s.task, { label: s.label, phase: L.phase, model: OPUS, effort: effort || 'xhigh' })
  if (report === null) log(s.label + ' returned nothing; the critic looks at what is there')
  let verdict = null
  for (let n = 1; n <= 3; n++) {
    const v = await agent(criticPrompt(L, s, n, report), { label: s.label + '-critic' + n, phase: L.phase, model: OPUS, effort: 'high', schema: VERDICT })
    if (!v) { log(s.label + ' critic ' + n + ' returned nothing; moving on'); break }
    verdict = v
    const blockers = (v.blockers || []).length
    const highs = (v.highs || []).length
    log(s.label + ' look ' + n + ': score ' + v.score + ', ' + blockers + ' blockers, ' + highs + ' highs')
    const must = n === 1 ? blockers + highs : blockers
    if (must === 0 || n === 3) break
    report = await agent(fixPrompt(L, s, n, v), { label: s.label + '-fix' + n, phase: L.phase, model: OPUS, effort: effort || 'xhigh' })
  }
  return { step: s.label, report: report, verdict: verdict }
}

async function chain(L, steps) {
  const out = []
  for (const s of steps) out.push(await gate(L, s))
  return out
}

async function languages() {
  const L = LANES.i18n
  const glossary = await agent(common(L, GLOSSARY.label, GLOSSARY.prefix) + '\n\n' + GLOSSARY.task, { label: GLOSSARY.label, phase: L.phase, model: OPUS, effort: 'xhigh' })
  if (glossary === null) log('i18n-0-glossary returned nothing; the translators read what is there')
  // Two translators at a time: with the four other lanes that is six agents, this workflow's limit on this Mac.
  const groups = [LANGS.slice(0, 3), LANGS.slice(3)]
  const langs = await parallel(groups.map(g => async () => {
    const out = []
    for (const l of g) out.push(await gate(L, langStep(l[0], l[1]), 'high'))
    return out
  }))
  const merge = await agent(common(L, MERGE.label, MERGE.prefix) + '\n\n' + MERGE.task, { label: MERGE.label, phase: L.phase, model: OPUS, effort: 'xhigh' })
  return { glossary: glossary, langs: langs, merge: merge }
}

const lanes = await parallel([
  () => chain(LANES.quests, QUESTS),
  () => chain(LANES.ads, ADS),
  () => chain(LANES.panels, PANELS),
  () => languages(),
  () => chain(LANES.store, STORE),
])

return { quests: lanes[0], ads: lanes[1], panels: lanes[2], languages: lanes[3], store: lanes[4] }
