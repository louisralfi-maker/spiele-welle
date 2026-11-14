export const meta = {
  name: 'lanternhold-house-lane-2',
  description: 'Lanternhold: the story editor\'s second fix round (the director\'s decisions on critic 2) with an independent critic, documents only, in the planning worktree',
  phases: [{ title: 'House 2' }],
}

// The director (Fable 5.2) wrote this on 14.11.2026 as the continuation of house-lane.js (run wf_4a940724-d4f, done).
// The write hook of this session blocks other worktrees, so the house files now live on the planning branch. No Fable.
const OPUS = 'claude-opus-5-5'
const WT = '/Users/enaayla/Desktop/Spiele-Welle/.claude/worktrees/game2-planning-354541'
const DIR = WT + '/ci-out/director'
const G = WT + '/games/lanternhold'
const STEP = 'house-1-story'
const FILES = `${G}/docs/HOUSE.md (sections 6 to 12 only), ${G}/docs/house-rewrite.json, ${G}/tools/house_rewrite_check.py`

const RULES = `
You work for the director of Lanternhold (game 2 of the Spiele-Welle). Your task is only the one given here.
- Worktree: ${WT} (branch claude/game2-planning-354541). Work only there. Never git stash, never change git config,
  never force-push. Other agents work elsewhere: touch no file but the ones named.
- This Mac is old: no xcodebuild, swiftc, simulator or long CPU job. Reading, writing, git and small python are fine.
- Messages from Louis are for the lead. Never SendMessage anyone.
- Director's notes win over this brief: ${DIR}/notes-house.md
- Read: ${G}/docs/HOUSE.md in full (sections 1 to 5 are the director's frame), ${DIR}/${STEP}-critic2.md, ${G}/STORY.md
  where needed, ${G}/docs/BARS.md. Strings: ${G}/Resources/Story.xcstrings (read with small python).
- Original work only: nothing from Yes, Your Grace or any other game.
`

const DECISIONS = `
The director's decisions on critic 2 (they win over the critic where they differ):
1. High 1: the house's own telling names no origin for Taper. Section 6.6 (the truth) stays.
2. High 2: "thief" is always tied to the fire, never to the chair or the hall ("by {his|her} borrowed fire"; "Whose fire
   is this, herald?"). Check line.herald_throne against it.
3. High 3: the King never speaks. The bitter line on night 20 is the herald's, beside him.
4. High 4: "made" goes into the prologue, which every player sees (add the prologue key to the list; if it cannot hold
   within 15 %, up to 25 % for that key, flagged for the panels lane in your report). Hesper's day-6 line stays a
   bonus in the hall; on other dusks she nods.
5. High 5, the double game gets a real, small gain and a plain price. Gain: with double_game the first push of night
   20 comes up the middle line and breaks on Brannock's doubled braziers (one value, the lane tunes it, at most about
   5 % of the night; bots never play evenings, so T1 to T8 hold). Price: whoever saw the nod (Seren, else Hild)
   stands apart on days 18 and 19, seen in the world; on night 20, when the push breaks, she steps back to the
   lord's side with one line ("A mask, then."). Drop the banner rule and Hesper carrying the flame: Seren carries
   it as always. Say the stakes plainly ("Then he takes back his fire and passes your town by").
6. High 6: take the German fixes. Choice labels may use the full 40 characters: the 15 % rule holds for all other
   strings (change the check so).
7. High 7: bring the bible lines in line with the changed strings.
8. High 8: add a third list "design" to house-rewrite.json ({"line","old","new"}) for every passage of
   ${G}/DESIGN.md that states the old premise, and let the check prove it like the bible list. Change DESIGN.md
   itself not at all. List code mentions (CourtWorld.swift and others) in your report for the join.
9. Smaller notes: take them where they are plain gains (Seren's missing German, the herald at table when Seren was
   handed over, the stiff German, 9.3's header, the oil in 8.2, tamsin_first, pip_turned, a line of ours for "At
   Highcairn the lord eats last").
10. Section 12's questions: 1 no fixed name, the player types it. 3 keep. 4 the name only: the lord carries the
   house's lantern on its hooked staff, no resprite. 5 fine. 6 Seren says "Lantern", after day 15 "lord". 7 the same
   dusk, day 17. 8 both seeds whatever the form. 9 yes, build 3's batch. 11 cut it: "Hesper, what does the Flame
   say?" with a plain answer; "on loan" is kept for chapter 2.
11. Plain (Louis: "nicht so tief, aber so soll es wirken"). Mark in each heading what build 3 ships: evenings 9.5 and
   9.4, then 9.2; the threads 8.3 and 8.2; the brother's visit and the dark cell. Everything else is marked "later"
   and stays short. Replace section 12 by "Decided" (one line each) and what is still open.
`

const GIT = `Commit as CLAUDE.md "Git" says, with the paths named on the commit itself
(git add <paths> && git commit -m "..." -- <paths>), and push claude/game2-planning-354541 with the deploy key.`

function fix(n, criticFile) {
  return RULES + DECISIONS + `
You are the story editor's fix round ${n}. Fix every high of ${DIR}/${criticFile} as decided above, in these files only:
${FILES}. Keep every rule of the list (old values exact, placeholders and line breaks kept, both German forms).
Run python3 -I ${G}/tools/house_rewrite_check.py until it prints ALL PASSED. ${GIT}
Write ${DIR}/${STEP}-fix${n}.md: each high, what you did, the check's output, the count of keys the translators must
redo, the code mentions. Your final answer is at most six lines.
`
}

function critic(n) {
  return RULES + DECISIONS + `
You are an independent critic, look ${n}: a narrative lead who has shipped story-driven strategy games, a German
editor, and a first-time player who knows nothing of the old story. You change nothing. You write only
${DIR}/${STEP}-critic${n}.md. Read the fix report ${DIR}/${STEP}-fix${n - 1}.md, HOUSE.md sections 6 to 12 and
house-rewrite.json, and run the check yourself. Judge hard against Louis' words at the top of HOUSE.md and the
decisions above: is the lord respected in every line and never a lamplighter, servant or child; does "thief" ever
read as a usurper of chair or hall; is the double game tense and plain, with a gain and a price a player sees; is the
German natural and in voice; is anything taken from another game (a blocker); is it plain enough. Search the strings
yourself for lines the list missed. A blocker breaks one of Louis' words or the check; a high is a clear flaw a
player or reader would notice. Write the verdict file (score of ten, blockers, highs, smaller notes, what is good),
then return the structured verdict.
`
}

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

phase('House 2')
const fixed2 = await agent(fix(2, STEP + '-critic2.md'), { label: STEP + '-fix2', phase: 'House 2', model: OPUS })
let verdict = await agent(critic(3), { label: STEP + '-critic3', phase: 'House 2', model: OPUS, effort: 'high', schema: VERDICT })
let fixed3 = null
if (verdict && (verdict.blockers.length > 0 || verdict.highs.length > 0)) {
  fixed3 = await agent(fix(3, STEP + '-critic3.md'), { label: STEP + '-fix3', phase: 'House 2', model: OPUS })
  const last = await agent(critic(4), { label: STEP + '-critic4', phase: 'House 2', model: OPUS, effort: 'high', schema: VERDICT })
  if (last) verdict = last
}

return { fixed2, fixed3, verdict }
