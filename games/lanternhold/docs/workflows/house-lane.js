export const meta = {
  name: 'lanternhold-house-lane',
  description: 'Lanternhold: one gated Opus 5.5 story editor writes the rewrite list for the new origin of the lord, the ties inside the court, the special evenings and the two rooms (documents only)',
  phases: [{ title: 'House' }],
}

// The director (Fable 5.2) wrote this on 14.11.2026 after Louis' interview of about 14:58. The spec is docs/HOUSE.md.
// It runs NEXT TO rebuild.js, v1-lanes.js, town-lanes.js, people-lane.js and front-lane.js. Every worker names its
// model: no Fable. Never resume it; after a stop, write a continuation.
const OPUS = 'claude-opus-5-5'
const ROOT = '/Users/enaayla/Desktop/Spiele-Welle/.claude/worktrees'
const DIR = ROOT + '/game2-planning-354541/ci-out/director'
const WT = ROOT + '/lh-house'
const G = WT + '/games/lanternhold'
const STEP = 'house-1-story'

const RULES = `
You work for the director of Lanternhold (game 2 of the Spiele-Welle). Your task is only the one given here.
- Worktree: ${WT} (branch claude/lh-house). Work only there, with absolute paths. Never touch another worktree, never
  git stash, never change git config, never force-push.
- This Mac is old and overheats: no xcodebuild, swiftc, swift build, simulator or long CPU job. Reading, writing, git
  and small python are fine.
- Messages from Louis are for the lead, not for you. Never SendMessage anyone.
- Director's notes, if the file exists, win over this brief: ${DIR}/notes-house.md
- Read first: ${G}/docs/HOUSE.md (sections 1 to 5 are the director's frame and win over STORY.md), then ${G}/STORY.md
  in full, ${G}/docs/BARS.md, ${G}/docs/TOWN.md sections 2, 6 and 7, ${G}/docs/REALM.md sections 1, 2 and 4, and
  DESIGN.md "Not a copy". The strings are in ${G}/Resources/Story.xcstrings (large: read it with small python).
- Original work only. Louis named an evening scene of Yes, Your Grace as the KIND of scene he means and said "nicht
  kopieren": take nothing from that game or any other (no figure, scene, line, room, name or look).
`

const BUILD = RULES + `
You are the story editor. Louis decided on 14.11.2026: the lord never was a lamplighter; House Lantern is the guardian
house, descended from the one who made or stole the Eternal Light; everyone respects the lord; the court is the family
and its members have ties among each other; the lord's own family comes in chapter 2; two rooms one may enter and
never must; special evenings on a few days. Write the detail. You change NO existing text: other lanes are translating
Story.xcstrings right now, and your list is applied later in one pass.

Files you may write (nothing else):
- ${G}/docs/HOUSE.md: append sections 6 to 12 below section 5. Sections above stay word for word.
- ${G}/docs/house-rewrite.json: the machine list of part C.
- ${G}/tools/house_rewrite_check.py: the check of part C.

A. Section 6, the legend, in at most ten lines: the founder, the Eternal Light, "made" as the house tells it, "stolen"
   as the dark tells it, why the dark wants it back. It must fit STORY.md's secret, its endings and night 20 without a
   new plot. Say which sections of STORY.md change and which stay.
B. Section 7, the lord's sheet again: wants, the fear, what only the heir of the guardian house knows (it replaces
   "what only a lamplighter knows"), and the table "how others see the lord" rewritten for every person in it: all of
   them respect the lord, warmth shows in deeds, the herald of the Lightless King addresses the heir of a thief.
   The lord's voice rules stay (choice labels, 40 characters at most).
C. The rewrite list. Every key in Story.xcstrings whose English or German value says or implies that the lord is or
   was a lamplighter, a servant, a child, an heir nobody expected, too small for the chair, or is talked down to; and
   every passage of STORY.md that does. German has male and female forms: keep both where the file has both.
   house-rewrite.json: {"strings":[{"key","en_old","en_new","de_old","de_new","why"}],"bible":[{"line","old","new"}]}.
   Rules: every *_old equals the file's value exactly; no new value is more than 15 % longer than the old one; choice
   labels stay at 40 characters or fewer; placeholders and line breaks are kept; the tone of each speaker is kept.
   The town's lamplighter (TOWN.md section 7) may be called a lamplighter; the lord never.
   house_rewrite_check.py proves it: the JSON parses, every key exists, every old value matches, the limits hold, and
   after applying the list in memory no English or German value calls the lord a lamplighter. It prints the counts and
   exits 0 only when everything holds. Run it and put its output into your report.
D. Section 8, the court's ties: three or four threads among the people STORY.md already has at court (no new main
   figure). For each: the two people, what it is in one line, four to six beats by story day that are SEEN in the world
   (where they stand, who leaves, a line overheard, an object), and one moment where the lord can tip it, with its
   choice labels in English and German. No thread makes anyone disrespect the lord.
E. Section 9, five special evenings for chapter 1 (HOUSE.md section 4): the day, the guest (figures STORY.md already
   has where it fits), the premise in two lines, the scene as six to ten lines of dialogue in English and German, two
   or three choices, and for each choice the one consequence the player later sees (name its flag). One evening is the
   double game. Each plays in under a minute. The horn ends each one.
F. Section 10, the two rooms: which existing petitions can end with a person in the cell (name the keys and the new
   third answer where one is needed), three visits to the cell with their lines, one use of the cell for something from
   the dark, who is found in the lord's chamber when (a small table by part of the day), and the signs in the world.
G. Section 11, chapter 2's seed: two possible matches for the lord, each planted in chapter 1 with one line and no
   more. Section 12: what you were unsure about, as questions for the director.

Commit after every finished part as CLAUDE.md "Git" says (Louis' noreply identity, named paths, the trailer
"Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"), and push claude/lh-house at the end with the deploy key.
Then write your report to ${DIR}/${STEP}.md: what you wrote, the check's output, the counts (keys, bible passages),
the commits. Your final answer is at most eight lines.
`

const VERDICT = {
  type: 'object',
  properties: {
    pass: { type: 'boolean' },
    score: { type: 'number' },
    blockers: { type: 'array', items: { type: 'string' } },
    highs: { type: 'array', items: { type: 'string' } },
  },
  required: ['pass', 'score', 'blockers', 'highs'],
}

function critic(n) {
  return RULES + `
You are an independent critic, look ${n}: a narrative lead who has shipped story-driven strategy games, a German
editor, and a first-time player who knows nothing of the old story. You change nothing in the worktree. You write only
${DIR}/${STEP}-critic${n}.md.
Read the builder's report ${DIR}/${STEP}.md${n > 1 ? `, the fix report ${DIR}/${STEP}-fix${n - 1}.md and the earlier verdict` : ''}, then HOUSE.md
sections 6 to 12 and house-rewrite.json, and run python3 ${G}/tools/house_rewrite_check.py yourself.
Judge against Louis' words at the top of HOUSE.md, hard:
- Is the lord respected by everyone in every new line, and never a lamplighter, servant or child? Search Story.xcstrings
  yourself for lines the list missed (English and German), and name them by key.
- Does "made or stolen" fit STORY.md's secret and endings without a new plot hole? Name any passage that now contradicts.
- Is the German natural, in each speaker's voice, within the length limits?
- The court's ties: are they seen in the world, without a menu, and worth caring about? Any cliche a player has seen
  a hundred times?
- The evenings: under a minute, a real choice, a consequence the player sees; is the double game tense and plain?
- The rooms: never a must; do the cell's visits pay off earlier judgments?
- Is anything taken from Yes, Your Grace or any other game? That is a blocker.
- Is it plain? Louis dislikes depth for its own sake.
A blocker breaks one of Louis' words or the check. A high is a clear flaw a player or reader would notice.
Write the verdict file (score of ten, blockers, highs, smaller notes, what is good), then return the structured verdict.
`
}

function fix(n) {
  return RULES + `
You are the story editor's fix round ${n}. Read ${DIR}/${STEP}-critic${n}.md and the report ${DIR}/${STEP}.md. Fix every
blocker and every high in the same three files the builder may write (HOUSE.md sections 6 to 12 only,
docs/house-rewrite.json, tools/house_rewrite_check.py). Where you disagree with a finding, say why instead of changing
it. Run the check again. Commit as CLAUDE.md "Git" says, push claude/lh-house, and write ${DIR}/${STEP}-fix${n}.md:
each finding, what you did, the check's output. Your final answer is at most six lines.
`
}

phase('House')
const built = await agent(BUILD, { label: STEP, phase: 'House', model: OPUS })
let verdict = await agent(critic(1), { label: STEP + '-critic1', phase: 'House', model: OPUS, effort: 'high', schema: VERDICT })
let fixed = null
if (verdict && (verdict.blockers.length > 0 || verdict.highs.length > 0)) {
  fixed = await agent(fix(1), { label: STEP + '-fix1', phase: 'House', model: OPUS })
  const second = await agent(critic(2), { label: STEP + '-critic2', phase: 'House', model: OPUS, effort: 'high', schema: VERDICT })
  if (second) verdict = second
}

return { built, fixed, verdict }
