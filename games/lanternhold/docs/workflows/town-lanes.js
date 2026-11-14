export const meta = {
  name: 'lanternhold-town-lanes',
  description: 'Lanternhold: two gated Opus 5.5 lanes for Louis\' wishes of 14.11. (taxes on foot, the growing town, travelling craftsmen)',
  phases: [{ title: 'Town' }, { title: 'Craftsmen' }],
}

// The director (Fable 5.2) wrote this on 14.11.2026 after Louis' interview. The spec is docs/TOWN.md.
// It runs NEXT TO rebuild.js and v1-lanes.js. Every worker names its model: no Fable.
const OPUS = 'claude-opus-5-5'
const ROOT = '/Users/enaayla/Desktop/Spiele-Welle/.claude/worktrees'
const PLAN = ROOT + '/game2-planning-354541'
const DIR = PLAN + '/ci-out/director'
const G = 'games/lanternhold'

const LANES = {
  town: { name: 'town', wt: ROOT + '/lh-town', branch: 'claude/lh-town', phase: 'Town',
    critic: "a game designer, a first-time player and a senior Swift reviewer. Check each line of the step's sections of docs/TOWN.md against the code, the unit tests and the round's logs (test counts, T1 to T8 line for line or the reported before and after). Read the Core changes for determinism and save safety (an old save must load). Where the step has pictures, judge them harshly at phone size as a player who has never seen the game: is it plain without a word that these people owe, that they pay when the lord comes, and what a knock costs? Does the toss feel good? Does any picture show a generator's tell (mixed pixel sizes, blur, stray pixels, melted shapes)? Read the English and the German of every new string" },
  craft: { name: 'craft', wt: ROOT + '/lh-craft', branch: 'claude/lh-craft', phase: 'Craftsmen',
    critic: "a narrative designer, a game designer and a senior Swift reviewer. Read EVERY craftsman's texts in English and German: is each one a person a player remembers, in the court's voice of STORY.md, original (no real brand, no figure of another game), within the card's length? Is every work seen in the world and is its one effect small, clear in two lines and covered by a unit test? Check the arrival rules, the save, and that a run in which nobody is commissioned equals today's run line for line" },
}

function common(L, label, prefix) {
  return [
    'You are one step of a lane that finishes Lanternhold for version 1 (game 2 of the Spiele-Welle: an original, ads-only iPhone game in landscape; the lord or lady of House Lantern holds a castle in the one cleft of an unclimbable wall against the Gloom, smoke-people that shrink from light; by day you build, judge petitions and keep the town, by night the battle runs; Swift 6, SwiftUI over a custom Metal renderer, xcodegen, game folder ' + G + '). Nine lanes run at the same time in separate worktrees: the rebuild lanes (world and stage: after Louis played TestFlight build 86 they are rewriting the outdoor world, the great hall, the input and every SwiftUI screen), five version-1 lanes (quests, ads, panels, i18n, store) and two lanes for Louis\' wishes of 14.11.2026 (town: taxes on foot, the treasury, the growing town; craft: travelling craftsmen). You are in the ' + L.name + ' lane.',
    '',
    'Louis\' two bars of 14.11. are in ' + DIR + '/artbar.md: read them first. Every picture and every screen of yours is judged against them.',
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
    '- Never build, compile or run a simulator on this Mac. Builds and tests run on GitHub\'s runner: scripts/ci/remote-check.sh lanternhold <label> <outdir> <steps...> in the background, then wait with a Bash until-loop on its output file (foreground sleep is blocked). Your round labels: ' + prefix + '-1, ' + prefix + '-2 and so on (if a label already has a ci-results branch on origin, take the next free number); never tf-*. Outdirs go under ci-out/ in your worktree (git-ignored). The runner takes 5 macOS jobs at once and nine lanes share it: a round that waits in the queue is normal, keep waiting and never send it twice. Use unit and ui filters for quick checks. Unless your step says otherwise, end with one full round (build, unit, ui, ui-de, release) that ends ALL PASSED.',
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

const TOWN = [
  { label: 'town-1-taxes-core', prefix: 'lh-t1', task: [
    'STEP town-1: taxes on foot, in Core. The spec is ' + G + '/docs/TOWN.md, section 1 (read the whole file first: Louis\' words and decisions are at the top). Also DESIGN.md "Economy" and "Tuning targets".',
    '- Core: what each paying place owes at dawn, collect(place), the people keeping what was not collected by the horn, the knock (once per house and day, the second knock from story day 8), unrest, the day flag that doubles every toss (the ads lane will set it). Pure, deterministic, saved; an old save loads.',
    '- The tax rate leaves the player\'s side. Decide whether a rate stays inside Core for the bots; there must be one source of truth. The reference bots collect everything at dawn; a bot that set High knocks at every house. Prove T1 to T8 (line for line where you can; otherwise tuned by values only, with before and after in your report). Mirror tools/tune.py.',
    '- The dawn report\'s data: what was collected yesterday, what was left to the people, who was knocked at. Strings in English and German in ' + G + '/Resources/Town.xcstrings.',
    '- Unit tests for every rule of section 1. No screen work in this step; do not touch Scene or UI files beyond what compiles.',
    '- Write the numbers you chose back into TOWN.md section 1.',
  ].join('\n') },
  { label: 'town-2-taxes-screen', prefix: 'lh-t2', task: [
    'STEP town-2: taxes on foot, on screen. TOWN.md section 1, "The sign", "The knock", "The interface", "The picture". This goes into TestFlight build 2 on Monday.',
    '- The household in the doorway with its pouch, the toss (coins in an arc, the coin sound, the light haptic, gold rising as they land), the wave or the turned back by happiness, the knock (the lord walks up, three knocks with sound and haptic, the hand-over with bowed heads, the shutters, the dark window at night). The farmer and the stall keeper likewise.',
    '- It must explain itself without a word: Louis wants the interface minimal and tidy and the controls self-explaining. No prompt, no label, no HUD mark. Judge your filmstrip as someone who has never played.',
    '- The tax card and its buttons leave the throne; the lectern stays as furniture. Do not restyle the HUD (the stage lane does).',
    '- Art through the game\'s own pipeline (ART.md, SPRITES.md, tools/, the palette) and the art lock: the poses (toss, hand over, knock), the pouch, the coins, the shutters. Louis\' bar: pixel art at triple-A level, and nobody may see that a generator was involved: one pixel grid, palette colours only, no blur, no stray pixels, no melted shapes.',
    '- You build on this branch\'s world; the walked world is being rebuilt in another lane. So: new files, door anchors as data, the smallest hooks, and proximity for collecting. The knock needs one touch on a door: use the smallest hit test you can and write in the lane notes exactly how the join re-hooks it to the rebuilt town and to the stage lane\'s touch.',
    '- Debug arguments in the house pattern (for example -GWTown owed|paid|knock) and a UI test that collects from every house, knocks at one and sees the night: shots 50-tax-waiting, 51-toss, 52-knock, 53-shutters-night in English and German. Reduce Motion: the coins fade in at the lord.',
  ].join('\n') },
  { label: 'town-3-growth-core', prefix: 'lh-t3', task: [
    'STEP town-3: the treasury, the collector and the growing town, in Core (TestFlight build 3). TOWN.md sections 2 and 3.',
    '- Core, saved and deterministic: the treasury, the collector (his morning round as simulated time, his wage, never a knock, the lord first, unrest), the third house tier, the second tier of market and tavern, the town\'s standing and its 3 % per point, the three looks of the backdrop row as a value the scene can read.',
    '- The new target T12 as a unit test with a bot that grows the town; bots that do not grow it give today\'s numbers (a neutrality test). Mirror tools/tune.py.',
    '- Strings in English and German (Town.xcstrings): the build options, the collector\'s name and his few lines in the voice of STORY.md.',
    '- No screen work. Write into TOWN.md sections 2 and 3 the numbers you chose, and into the lane notes a list of the art and the screen work the join needs (the treasury\'s place in the rebuilt castle, the collector\'s sprites, the house tiers, the three backdrop looks, the price shown as coins over a door).',
  ].join('\n') },
]

const CRAFT = [
  { label: 'craft-1-craftsmen', prefix: 'lh-c1', task: [
    'STEP craft-1: the travelling craftsmen (TestFlight build 3). The spec is ' + G + '/docs/TOWN.md, section 4 (read the whole file first), with DESIGN.md "The throne: audiences and decisions", "Petition data" and STORY.md for the voice.',
    '- The offer as a kind of audience in the petition engine, driven by data (' + G + '/Resources/Petitions/craftsmen.json or the pattern you find): the arrival rules, commission, "not now" with one return, send on; the work\'s building time; the save.',
    '- Ten craftsmen. Start from the director\'s list and better it: every work is seen in the world and has one small effect; three are works of pride. Each craftsman is a person: an original name, where they come from, one line a player remembers, a reaction to each answer. English and German in ' + G + '/Resources/Craftsmen.xcstrings, within the audience card\'s lengths.',
    '- Every effect lives in Core behind a flag with a unit test; a run in which nobody is commissioned equals today\'s run line for line (a neutrality test). No effect moves a system by more than about 5 %.',
    '- On screen only what the existing audience card gives: the offer as a card with its price and its two lines, reachable by a debug argument, with a UI test in English and German (shots 60-craft-offer, 61-craft-commissioned).',
    '- No new art in this step. Write into the lane notes the art list for the join: each craftsman\'s sprite (which existing body it can start from) and each work with its place in the rebuilt world.',
    '- Write your final list and numbers back into TOWN.md section 4.',
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
    'Louis\' two bars of 14.11. (the art bar and the interface bar) are in ' + DIR + '/artbar.md: read them and hold every picture and every screen against them.',
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

const lanes = await parallel([
  () => chain(LANES.town, TOWN),
  () => chain(LANES.craft, CRAFT),
])

return { town: lanes[0], craft: lanes[1] }
