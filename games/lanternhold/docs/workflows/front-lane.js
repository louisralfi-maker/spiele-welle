export const meta = {
  name: 'lanternhold-front-lane',
  description: 'Lanternhold: one gated Opus 5.5 lane, Core only, for the night and the dark side (being there counts, the hearth that burns low, beacons into the gorge)',
  phases: [{ title: 'Front' }],
}

// The director (Fable 5.2) wrote this on 14.11.2026 after Louis' interview of 14:32. The spec is docs/REALM.md.
// It runs NEXT TO rebuild.js, v1-lanes.js, town-lanes.js and people-lane.js. Every worker names its model: no Fable.
const OPUS = 'claude-opus-5-5'
const ROOT = '/Users/enaayla/Desktop/Spiele-Welle/.claude/worktrees'
const PLAN = ROOT + '/game2-planning-354541'
const DIR = PLAN + '/ci-out/director'
const G = 'games/lanternhold'

const LANES = {
  front: { name: 'front', wt: ROOT + '/lh-front', branch: 'claude/lh-front', phase: 'Front',
    critic: "a systems designer who has shipped tower defence and kingdom games, a test engineer and a first-time player. Read the diff in Core and every new unit test. Demand proof from the runner that T1 to T8 hold line for line with the reference bots (the bot tables before and after, not a claim). Check determinism (the same seed gives the same night), the save (an old save loads; new fields have defaults; a test proves it) and that nothing shares state with the lantern that the stage lane builds. Then judge as a player against REALM.md: can the rule be felt and understood with no HUD and no number; is it a deed or a chore; is there one dominant way to play it; can it be abused (standing in one spot all night, feeding the hearth forever, a beacon that pays for itself at once); does a loss hurt and still leave a way back. Run the numbers of the new target yourself from the test output. Read the new strings in English and German: short, dry, in the voice of STORY.md" },
}

function common(L, label, prefix) {
  return [
    'You are one step of a lane that finishes Lanternhold for version 1 (game 2 of the Spiele-Welle: an original, ads-only iPhone game in landscape; the lord or lady of House Lantern holds a castle in the one cleft of an unclimbable wall against the Gloom, smoke-people that shrink from light; by day you build, judge petitions and keep the town, by night the battle runs; Swift 6, SwiftUI over a custom Metal renderer, xcodegen, game folder ' + G + '). Eleven lanes run at the same time in separate worktrees: the rebuild lanes (world and stage: after Louis played TestFlight build 86 they are rewriting the outdoor world, the great hall, the input and every SwiftUI screen), five version-1 lanes (quests, ads, panels, i18n, store), two lanes for Louis\' wishes of 14.11.2026 (town: taxes on foot, the treasury, the growing town; craft: travelling craftsmen) and the people lane (the cast: working people marked by life, bright children, nobles from the inner lands) and the front lane (the night and the dark side, in Core: being there counts, a hearth that can burn low, beacons into the gorge). You are in the ' + L.name + ' lane.',
    '',
    'Louis\' three bars of 14.11. are in ' + DIR + '/artbar.md: read them first. Every picture and every screen of yours is judged against them.',
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
    '- Never build, compile or run a simulator on this Mac. Builds and tests run on GitHub\'s runner: scripts/ci/remote-check.sh lanternhold <label> <outdir> <steps...> in the background, then wait with a Bash until-loop on its output file (foreground sleep is blocked). Your round labels: ' + prefix + '-1, ' + prefix + '-2 and so on (if a label already has a ci-results branch on origin, take the next free number); never tf-*. Outdirs go under ci-out/ in your worktree (git-ignored). The runner takes 5 macOS jobs at once and eleven lanes share it: a round that waits in the queue is normal, keep waiting and never send it twice. Use unit and ui filters for quick checks. Unless your step says otherwise, end with one full round (build, unit, ui, ui-de, release) that ends ALL PASSED.',
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

const FRONT = [
  { label: "front-1-presence", prefix: "lh-f1", task: [
    "STEP front-1: being there counts. Louis chose it in the interview of 14.11.: \"Dabei sein zählt: wo der Burgherr steht, kämpfen seine Leute besser und halten länger. Kein Kampfmenü, man rennt dorthin, wo es brennt.\" The spec is section 3 of /Users/enaayla/Desktop/Spiele-Welle/.claude/worktrees/game2-planning-354541/games/lanternhold/docs/REALM.md; read section 6 too (why: today the night plays itself).",
    "- Core only. No SwiftUI, no renderer, no sprites, no change to a UI test: the rebuild lanes are rewriting the screens and the world, and the picture is hooked at the join. Expose what the picture will need as plain read-only state and events, and write for the join, in your lane notes, exactly what the screen must show and which touch calls which function.",
    "- New files of your own under the Core sources (and their tests); the smallest hooks into the night simulation, the save and the dawn report data, each listed in the lane notes. New saved fields have defaults and an old save loads: a unit test proves it.",
    "- Deterministic and seeded like the rest of Core. Every number is a named tuning value in one place.",
    "- The reference bots do not use the new rule, so T1 to T8 hold line for line: print the bot tables before and after in a unit test on the runner and put both into your report. Bots, tuning and long sums run on the runner, never on this Mac.",
    "- Player-facing words (the dawn report's lines) go into a new catalog Front.xcstrings in English and German, short and dry, in the voice of STORY.md.",
    "- Rounds: build and unit while you work; end with one full round (build, unit, ui, ui-de, release) that ends ALL PASSED, to prove nothing else moved.",
    "- Presence: at night, defenders within the presence radius of the lord (start 90 px) loose and strike faster (15 %) and take less harm (20 %).",
    "- Braziers: a dead brazier he passes within about 20 px is relit from his lantern, free, at most one in 4 s. Keep the old Light action working for the old screen until the join, and mark it as going.",
    "- Patching stays as it is in Core, but give it a form that takes the lord's position: the wall part he stands at.",
    "- He cannot die: a creature that reaches him throws him back about 60 px, and for 8 s he is shaken and gives no presence. This is its own small state: do not touch the lantern's radius (the stage lane builds \"Raise the lantern\").",
    "- A new bot \"present\" that walks the lord to the wall the next wave lands on. Target T13 (new): over nights 3 to 14 it loses 25 to 40 % fewer defenders than the reference bot, and presence never wins a night that the reference loses clearly. Tune by values only and show the table.",
    "- Guard against the chore: if the best play is to sprint between two walls every few seconds, the rule is wrong. Say in your report what the present bot actually does in a night, in plain words, and change radius, strength or the waves' timing until one or two good moves a night carry it.",
    "- State for the picture: who is under presence right now, a brazier just relit, the throw-back, the shaken timer.",
  ].join('\n') },
  { label: "front-2-hearth", prefix: "lh-f2", task: [
    "STEP front-2: the hearth. Louis chose it in the interview of 14.11.: \"Tut weh, geht weiter: Häuser brennen, Leute mit Namen sterben, die Stadt wird ärmer und man baut wieder auf. Ganz vorbei ist es nur, wenn das Herdfeuer ausgeht, und dann startet man am Morgen davor neu.\" The spec is section 4 of /Users/enaayla/Desktop/Spiele-Welle/.claude/worktrees/game2-planning-354541/games/lanternhold/docs/REALM.md.",
    "- Core only. No SwiftUI, no renderer, no sprites, no change to a UI test: the rebuild lanes are rewriting the screens and the world, and the picture is hooked at the join. Expose what the picture will need as plain read-only state and events, and write for the join, in your lane notes, exactly what the screen must show and which touch calls which function.",
    "- New files of your own under the Core sources (and their tests); the smallest hooks into the night simulation, the save and the dawn report data, each listed in the lane notes. New saved fields have defaults and an old save loads: a unit test proves it.",
    "- Deterministic and seeded like the rest of Core. Every number is a named tuning value in one place.",
    "- The reference bots do not use the new rule, so T1 to T8 hold line for line: print the bot tables before and after in a unit test on the runner and put both into your report. Bots, tuning and long sums run on the runner, never on this Mac.",
    "- Player-facing words (the dawn report's lines) go into a new catalog Front.xcstrings in English and German, short and dry, in the voice of STORY.md.",
    "- Rounds: build and unit while you work; end with one full round (build, unit, ui, ui-de, release) that ends ALL PASSED, to prove nothing else moved.",
    "- The hearth has four states: bright, low, embers, out. Today the realm falls when creatures reach it; from now on that is a broken night: the hearth drops one step, the night ends, and by first light one or two houses are burnt (a field or the market stall if no house stands), one to three townspeople with names are dead, a fifth of the purse is gone (at most 60) and happiness falls by 8. Seeded.",
    "- A burnt house holds nobody and owes nothing until it is rebuilt for a third of its price; its household is not lost (it shelters in the chapel). Read docs/TOWN.md: the town lane splits taxes per house on another branch, so keep your part to the house's state and say in the lane notes how the two meet at the join.",
    "- The fire recovers one step at a dawn after a night without a breach. Once a day the lord can feed it: wood for about 25 gold, one step. A function for the join's touch.",
    "- Out: the realm falls. Keep the last three dawn saves; the fall offers to wake at one of them, or a new realm. A fall never overwrites them. Prove with a test that a player can always get back to a dawn with the hearth above \"out\".",
    "- Night 20: the Lightless King at the hearth ends the chapter with the dark ending, as today, whatever the fire's state. Do not edit STORY.md; list in the lane notes which story lines speak of the fall and would need a new word.",
    "- Targets: for T1 to T8 a night in which the hearth is reached still counts as the loss it is today (the reference run stops there), so the numbers do not move: prove it. Target T14 (new): a bot that plays carelessly for one night and well afterwards has mended the damage within three days; two broken nights within three end the realm.",
    "- The dawn report's data: the burnt houses, the dead by name, the gold taken, the fire's state, each as one line in Front.xcstrings (\"The hearth burns low.\"). No number where a word does it.",
    "- Judge it as a player: does the first broken night make you want to build up again, or to put the phone away? Say which numbers you moved for that.",
  ].join('\n') },
  { label: "front-3-beacons", prefix: "lh-f3", task: [
    "STEP front-3: beacons into the gorge. Louis chose it in the interview of 14.11.: \"Ja, Leuchtfeuer: man baut Leuchtfeuer immer weiter in die Schlucht hinein. Jedes drängt den Nebel zurück und gibt neues Land frei. So hat man ein Ziel nach vorn, nicht nur Abwehr.\" The spec is section 5 of /Users/enaayla/Desktop/Spiele-Welle/.claude/worktrees/game2-planning-354541/games/lanternhold/docs/REALM.md.",
    "- Core only. No SwiftUI, no renderer, no sprites, no change to a UI test: the rebuild lanes are rewriting the screens and the world, and the picture is hooked at the join. Expose what the picture will need as plain read-only state and events, and write for the join, in your lane notes, exactly what the screen must show and which touch calls which function.",
    "- New files of your own under the Core sources (and their tests); the smallest hooks into the night simulation, the save and the dawn report data, each listed in the lane notes. New saved fields have defaults and an old save loads: a unit test proves it.",
    "- Deterministic and seeded like the rest of Core. Every number is a named tuning value in one place.",
    "- The reference bots do not use the new rule, so T1 to T8 hold line for line: print the bot tables before and after in a unit test on the runner and put both into your report. Bots, tuning and long sums run on the runner, never on this Mac.",
    "- Player-facing words (the dawn report's lines) go into a new catalog Front.xcstrings in English and German, short and dry, in the voice of STORY.md.",
    "- Rounds: build and unit while you work; end with one full round (build, unit, ui, ui-de, release) that ends ALL PASSED, to prove nothing else moved.",
    "- Four beacon sites beyond the gate at growing distances, kept as fractions of the gorge's length (the world lane is redrawing the gorge and will place them). The next one is raised by day, from day 3, by the builders in one day (about 60, 90, 130, 180 gold); each needs the one before it lit.",
    "- The fog line is one value: the furthest lit beacon, or the old edge. Creatures appear at the fog line, so they walk longer under the arrows; the beacon lights its own pool under the existing light rules.",
    "- A beacon must be held: creatures strike the furthest beacon as they pass, it has its own strength, and if it falls the fog line comes back to the one before. Relighting by day costs a third of its price.",
    "- Freed land: one named thing per stretch with one small gain, none above about 8 % on any system: the old quarry (wall and gate work cheaper), the ruined watchtower (may be raised as a forward archers' post), the charcoal burners' camp (braziers burn longer), the far stones (the Great Beacon reaches further on night 20; leave that one as a flag for the picture if the finale's tuning would move). You may better the list; every gain has a unit test.",
    "- The Great Beacon on the castle and its three stages stay exactly as they are.",
    "- A new bot \"forward\" that raises the beacons as it can afford them and keeps the wall. Target T15 (new): with all four held by night 14 clearly fewer creatures reach the wall than for the reference (set the band and show the table), and a bot that builds beacons and neglects the wall loses them and then the night. Forward must be a wager, never the one right way and never a trap.",
    "- State for the picture: the fog line, each beacon's state and strength, each freed stretch. Write for the join what the world must show when a beacon is lit, when it falls, and when land is freed.",
    "- The dawn report's lines for a beacon lit, a beacon lost and land freed, in Front.xcstrings.",
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
    'Louis\' three bars of 14.11. (art, interface, people) are in ' + DIR + '/artbar.md: read them and hold every picture and every screen against them.',
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

const out = await chain(LANES.front, FRONT)

return { front: out }
