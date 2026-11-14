export const meta = {
  name: 'lanternhold-people-lane',
  description: 'Lanternhold: one gated Opus 5.5 lane for the cast (working people marked by life, bright children, nobles from the inner lands) and the town\'s daily life',
  phases: [{ title: 'People' }],
}

// The director (Fable 5.2) wrote this on 14.11.2026 after Louis' words about the people. The rule is docs/BARS.md section 3.
// It runs NEXT TO rebuild.js, v1-lanes.js and town-lanes.js. Every worker names its model: no Fable.
const OPUS = 'claude-opus-5-5'
const ROOT = '/Users/enaayla/Desktop/Spiele-Welle/.claude/worktrees'
const PLAN = ROOT + '/game2-planning-354541'
const DIR = PLAN + '/ci-out/director'
const G = 'games/lanternhold'

const LANES = {
  people: { name: 'people', wt: ROOT + '/lh-people', branch: 'claude/lh-people', phase: 'People',
    critic: "a pixel artist with twenty years in games, an art director and a first-time player. Open every new or repainted sheet at 400 % and at phone size. Go through bar 1 of artbar.md line by line (would a working pixel artist spot that a machine made this?) and through bar 3 line by line: does every working figure carry one mark of a life and still stand with dignity; are the children the bright, quick thing; are the nobles from another world and still the same game? Stand each new figure next to the lord, a guard and an old sheet: the same grid, outline rule and proportions? Step through every walk frame by frame for pops, sliding feet and parts that change shape. Read PEOPLE.md: original names in the voice of STORY.md, no figure of another game or film. In the running game's shots: does one glance at phone size tell the farmer from the child from the noble" },
}

function common(L, label, prefix) {
  return [
    'You are one step of a lane that finishes Lanternhold for version 1 (game 2 of the Spiele-Welle: an original, ads-only iPhone game in landscape; the lord or lady of House Lantern holds a castle in the one cleft of an unclimbable wall against the Gloom, smoke-people that shrink from light; by day you build, judge petitions and keep the town, by night the battle runs; Swift 6, SwiftUI over a custom Metal renderer, xcodegen, game folder ' + G + '). Ten lanes run at the same time in separate worktrees: the rebuild lanes (world and stage: after Louis played TestFlight build 86 they are rewriting the outdoor world, the great hall, the input and every SwiftUI screen), five version-1 lanes (quests, ads, panels, i18n, store), two lanes for Louis\' wishes of 14.11.2026 (town: taxes on foot, the treasury, the growing town; craft: travelling craftsmen) and the people lane (the cast: working people marked by life, bright children, nobles from the inner lands). You are in the ' + L.name + ' lane.',
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
    '- Never build, compile or run a simulator on this Mac. Builds and tests run on GitHub\'s runner: scripts/ci/remote-check.sh lanternhold <label> <outdir> <steps...> in the background, then wait with a Bash until-loop on its output file (foreground sleep is blocked). Your round labels: ' + prefix + '-1, ' + prefix + '-2 and so on (if a label already has a ci-results branch on origin, take the next free number); never tf-*. Outdirs go under ci-out/ in your worktree (git-ignored). The runner takes 5 macOS jobs at once and ten lanes share it: a round that waits in the queue is normal, keep waiting and never send it twice. Use unit and ui filters for quick checks. Unless your step says otherwise, end with one full round (build, unit, ui, ui-de, release) that ends ALL PASSED.',
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

const PEOPLE = [
  { label: 'people-1-cast', prefix: 'lh-p1', task: [
    'STEP people-1: the cast. Louis (14.11.): "Was auch verdammt cool wäre, wenn die Bauern und die Leute, die arbeiten, schon richtig verbraucht sind, vom Leben geprägt. Natürlich ist unser Königreich besser, da sind alle fast gleich, weil wir nie so viel Geld hatten. Alle sind vom Leben geprägt, dann ist es halt cool, wenn es lebensfrohe Kinder gibt oder abgehobene reiche Adelige. Das bringt Charakterwechsel mit rein." The rule is section 3 of ' + DIR + '/artbar.md.',
    '- Read STORY.md (the cast, the houses, the guests), SPRITES.md ("Actors", "Court and guests", "The house envoys", "The lord pass"), the ART documents and the palette, and look at the existing citizen, guest and envoy sheets at 400 %. Today the whole town is three bodies.',
    '- Write ' + G + '/docs/PEOPLE.md: who lives in Lanternhold and who visits. Twelve working people with a name, a trade, an age and the one mark life left on them (keep the named figures of STORY.md as they are); three children; the nobles of the inner lands as a kind (two bodies and a footman), fitted to the houses and guests STORY.md already has. For each: silhouette, posture, pace, cloth from the palette, the tell. A page a later artist can draw from.',
    '- Draw them under the existing contracts so that they drop into the game: repaint citizen, citizenB and citizenC (and their seated forms) as worn working people at their sizes and frames; add at least five new working bodies at the citizen contract (two farmers, an old man with a stick, a washerwoman, a labourer), each with a walk that shows the body (the limp, the stoop); work frames for the farmers (hoe, scythe, a sack on the back, a pause that straightens the back); three children (smaller: a run, a skip, an idle that fidgets); two noble bodies and a footman at the envoy contract.',
    '- Hand-placed pixels through the game\'s python art tools and the art lock, one sheet per call. A generated picture is a sketch at most; what ships is drawn onto the grid.',
    '- Register the new sprites the way SpriteID and FrameDesc do it (the smallest hooks; list them) and write their tables into a new file ' + G + '/docs/SPRITES-people.md.',
    '- Proof for the director and for Louis: (a) a line-up of the whole cast standing on the town\'s ground in day light, next to the lord and a guard, scaled 6x with nearest neighbour, as ci-out/people/lineup-day.png, and the same at dusk; (b) one strip per walk; (c) a UI-test shot of the town square by day with the new townsfolk in the running game.',
    '- Judge it as Louis would at phone size: does one glance tell the farmer from the child from the noble? Does anyone look as if a generator drew them? Is anyone finer than their neighbour who should not be?',
  ].join('\n') },
  { label: 'people-2-life', prefix: 'lh-p2', task: [
    'STEP people-2: the town lives by its people. Picture only: no rule of the simulation changes, T1 to T8 hold line for line.',
    '- Who is where: a small data table in a new file that gives every house its household from the cast (the same people every day, so that a player comes to know them), the fields their farmers, the square its passers-by.',
    '- The day of the working people: farmers out at first light, at work by day, a pause that straightens the back, home before the horn at a tired pace; the washerwoman at the well; the old man on the bench by the square. They straighten or nod when the lord passes; below 30 happiness they look away.',
    '- Children: from 45 happiness they are out (more of them at 80 and up, as today): they run, skip and fight with sticks, and one trails the lord for a few steps and falls back. At the horn a parent calls them in from the doorway and they run home. Never out at night.',
    '- Noble guests: on a day when a noble guest of the petition data is due, a coach stands at the town gate from the morning with the footman beside it, and the townsfolk give it a wide berth. The hall side waits for the join: write what it needs into the lane notes.',
    '- You build on this branch\'s world; the walked world is being rebuilt in another lane. New files, the smallest hooks, anchors as data; write for the join how each behaviour is hooked to the rebuilt town.',
    '- Reduce Motion: nobody is removed, only the small motions are fewer. The town holds its frame rate with everyone out.',
    '- A UI test that walks the lord through the town at morning, noon and dusk: shots 70-fields-morning, 71-square-noon, 72-children, 73-dusk-home, 74-noble-coach in English and German.',
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

const out = await chain(LANES.people, PEOPLE)

return { people: out }
