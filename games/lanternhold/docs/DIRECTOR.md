# Lanternhold studio: the director's brief (14.11.2026)

Louis decided on 14.11.2026: **Fable 5.2 runs the studio as the director** (the planner, the ideas, the decisions,
the quality bar), and **Opus 5.5 agents do the work**. Read this first, then CLAUDE.md, then
`games/lanternhold/docs/REVIEW-look-2.md`.

## 1. How the director works

- **The director steers and judges. It does not build.**
  - It writes no code and paints no art itself.
  - It plans, writes the agents' briefs, reads their reports, looks at the screenshots, decides, and sends fixes.
  - Broad reading goes to an agent (an Explore or opus agent). The director keeps its own context small, because every director turn costs Fable quota.
- **Every agent runs on Opus 5.5, named explicitly.** Without a model, an agent inherits the session's model, which is Fable, and burns the Fable quota.
  - Workflow `agent()` calls: `model: 'claude-opus-5-5'`.
  - The Agent tool: `model: "opus"`.
  - Sonnet is for routine work (CLAUDE.md "Agent models").
  - Build agents run at effort `xhigh`.
- **Tempo (Louis, 14.11. 13:18):** "mit Opus-5.5-Agenten kannst du reinhauen, so wie der Mac es halt verkraftet". The limit of 2 to 3 agents is lifted for Opus 5.5 agents. The Mac sets the limit now:
  - a workflow runs at most 6 agents at once on this Mac (8 logical cores minus 2); two workflows may run side by side;
  - only one image job at a time across all lanes: every lane uses `ci-out/director/artlock.sh <command>` (section 5);
  - the runner takes at most 5 macOS jobs at once, so more than five building lanes only queue;
  - watch the load, the memory and TCXC after every launch, and stop the newest workflow if the Mac strains.
- **Budget:**
  - Check `mcp__ccd_session_mgmt__get_usage` before every workflow.
  - Louis has a full weekly reset in reserve (14.11.), so the 80 % stop does not hold this week: tell him when the week passes 80 %, and go on.
  - The Fable quota is separate, but its use also counts toward the weekly limit. The director stays thrifty: it wakes only for reports and verdicts.
  - Weekly usage on 14.11. at 13:25 was 3 % (Fable 1 %); the next reset is 21.11. at 03:00 UTC.
- **Ideas:** Louis, 14.11.: "deine Ideen sind sehr gut, bring gerne mehr ein". Every brief and every notes file may carry a director's idea, with its reason. Section 6 lists them.
- **Quality:** Louis' words: "Warum muss ich dir alles vorschreiben, mach's doch einfach besser als alle anderen."
  - Before Louis sees anything, the director judges every screen harshly against the craft of Kingdom Two Crowns and Yes, Your Grace (never their look; DESIGN.md "Not a copy").
  - Obvious quality fixes need no approval. Bring ideas.
  - Ask Louis only for real product decisions, with pictures when it is about the look.
- **Method per big step** (CLAUDE.md "Work method"):
  1. Build in a worktree, with small commits.
  2. Review through two lenses: player and code.
  3. A separate agent tries to refute every blocker and high finding.
  4. Fix.
  - Never SendMessage to a running workflow agent.
  - Never resume a parallel workflow with `resumeFromRunId`; launch a fresh run instead.
- **Talking to Louis:** in German, short and plain. Name the exact button he has to press. Be honest about how long things take. Report only what is finished and new, with a picture where one helps.

## 2. Where things stand

- **TestFlight:** build 86 (1.0.0) is on Louis' iPhone; group "Louis" gets builds automatically. A round whose label starts with `tf-` uploads a new build (docs/store-checklist.md, step 10).
- **Louis' verdict on build 86:**
  - The red action button is "cringe". He wants to touch people and things directly.
  - The interface matters as much as the art.
  - The throne hall must be much bigger and at the best of the genre.
  - The strip "throne hall, then church, then houses, then a castle again" looks bad.
  - Walking into the gorge's blocking wall, with the castle in the cleft behind it, is not immersive.
- **The plan:** `docs/REVIEW-look-2.md`, the art director's review. It holds the world plan with x ranges, planes, the camera and transitions, and the punch list B1-B6, H1-H10, M1-M14 and L1-L6.
- **Branches** (all pushed):

  | branch | worktree | state |
  |---|---|---|
  | `claude/game2-planning-354541` | `.claude/worktrees/game2-planning-354541` | the integration branch: build 86 plus the sound lane (merged 76946d0, rounds lh-snd-1/2 ALL PASSED) |
  | `claude/lh-world` | `.claude/worktrees/lh-world` | world lane. ccae3aa is a WIP snapshot of step world-1 (bank sheets, cleft walls, throat steps, gate rock, fog edges), not yet built |
  | `claude/lh-stage` | `.claude/worktrees/lh-stage` | stage lane. 4012dc9 (hall light shaft, dust, plaster) and the WIP snapshot 82714d5 (HallStage, HallLayout, HallCourt, HallFrames, renderer hooks), not yet built |

- **The paused workflow:** wx2talxae (run wf_f9665060-109) was stopped on 14.11. at about 13:00 at Louis' request. Both lanes were in their first step; their unfinished work is in the WIP snapshots above.

## 3. Ready to relaunch

`docs/workflows/rebuild.js` is the rebuild, with every agent already pinned to Opus 5.5:

- **World lane:** world-1 (rock and fog), world-2 (one castle, exteriors only), world-3 (the camera and the whole-world pass).
- **Stage lane:** stage-1 (the hall as its own stage), stage-2 (touch the world), stage-3 (the interface, the title screen and the sound of each place).
- **Join:** merge lh-world into lh-stage, then full rounds labelled lh-j-* until ALL PASSED, then a harsh sweep.

The lanes run in parallel, so two agents run at once. Each step first reads git log and finishes what the step before it left, so a fresh run picks up the WIP snapshots.

**Every step is gated** (added by the director on 14.11.): after the builder, an independent critic (Opus 5.5, read-only) looks at the step's screenshots as an art director and first-time player and returns blockers, highs and a score (8 of 10 passes). Look 1 sends blockers and highs back to the lane as a fix round, look 2 only blockers, look 3 is for the record. What stays open goes to the next step through the verdict file.

To start it: `Workflow({scriptPath: "<repo>/games/lanternhold/docs/workflows/rebuild.js"})`. Read and adjust it first: the director may change the plan, split steps or add ideas.

## 4. After the rebuild

1. The director looks at the joined screenshots itself.
2. A review workflow (player and code lenses, refute), then the fixes.
3. Merge into planning, then a `tf-*` round (build, unit, testflight, ui, ui-de). That is TestFlight build 2; Louis was told Sunday or Monday.
4. Still to do for v1:
   - the Lantern Table quests (docs/QUESTS.md, 13 sendings);
   - onboarding;
   - ads in code (the AdMob ids are in the memory file project-lanternhold);
   - all 8 languages;
   - the store listing and 6.9-inch screenshots;
   - the privacy and support pages;
   - the App Privacy and age rating answers.

   Submission only with Louis' go in chat, for that one submission.

## 5. The director's desk

`ci-out/director/` in the planning worktree (git-ignored) is how the director and the agents talk without stopping a run:

| file | written by | read by |
|---|---|---|
| `notes-world.md`, `notes-stage.md`, `notes-join.md` | the director; newest entry at the bottom | every agent of that lane before it starts; a note wins over the brief |
| `<step>.md`, `<step>-fix<n>.md`, `join.md` | the builder, as its last action | the director |
| `<step>-critic<n>.md` | the critic | the next agent of the lane, and the director |
| `digest.md` | a Sonnet agent at the start of the run | the director: the game in 1200 words |

- The director is woken by a background until-loop on a report file (for example `world-1-rock-fog.md`), looks at the screenshots itself, and writes its corrections into the lane's notes file. The lane's next agent picks them up.
- Never SendMessage to a running workflow agent; the notes files are the only channel.
- `artlock.sh <command...>` on the desk is the art lock: one image job at a time across all lanes. It waits for the lock, for image jobs of agents that do not use it, and for TCXC under 78, then runs the command.

## 6. The v1 lanes and the director's ideas (14.11.2026)

`docs/workflows/v1-lanes.js` runs next to the rebuild since 14.11. at 13:30 (workflow w798y73lm, run wf_6dfc3591-4f0). Five lanes, each in its own worktree and branch cut from planning d3ed497, each step gated by a critic as in the rebuild. They keep to new files, their own string catalogs (English and German) and small listed hooks; their notes are `docs/lanes/<lane>.md` on their branches.

| lane | worktree, branch | steps |
|---|---|---|
| quests | `lh-q`, `claude/lh-q` | engine (QUESTS.md round lh-q-1), all thirteen sendings with bots and T10/T11, the table screen. The table in the chapel and the walk through the gate wait for the join |
| ads | `lh-ads`, `claude/lh-ads` | AdMob by DESIGN.md "Ads": rules in Core with an injected clock, stub and no-ads flags, consent at the first dawn report. Marek's cart in the world waits for the join |
| panels | `lh-panels`, `claude/lh-panels` | the slide stage and the prologue, then the three endings and the chapter's end card |
| i18n | `lh-i18n`, `claude/lh-i18n` | glossary and tools, then fr, es, it, pt-BR, ja, zh-Hans for Story.xcstrings (two translators at a time, an editor per language), then the merge. The interface strings follow after the join |
| store | `lh-store`, `claude/lh-store` | listing in 8 languages, privacy and support pages, draft answers for Louis' go, review notes, the screenshot list |

After both workflows: a second join (the five lanes into the joined game), the walked-world hookups, the interface strings in six languages, then the review workflow and the `tf-*` round.

**The director's ideas, and where each one went:**

| idea | why | where |
|---|---|---|
| The hall door's warm light on the cobbles | the hall calls the player home at dusk | rebuild.js, world-2 |
| The ear arrives before the eye; the hall answers its lord | the stage change feels like entering a room | rebuild.js, stage-1 |
| Dusk has a face: a lamplighter lights the lane at the horn | the game's one rule shown by a person every evening | notes-world.md, world-3 |
| Raise the lantern: hold on the lord at night | one verb of the house's own in a passive night | notes-stage.md, stage-2 |
| The lord hurries on long ways | 108 s end to end at walking pace | notes-stage.md, stage-2 |
| The title is the world: one touch lights the lantern | no menu between the player and the castle | notes-stage.md, stage-3 |
| The ledger on the lectern (the Chronicle) | a judgment's consequences become readable | notes-stage.md, stage-3 |
| Lantern slides for the prologue and the endings | the house's own way to tell a story | v1-lanes.js, panels |
| The rail is the status display; a line of light creeps across the map | who is away and when they are due, seen at a glance | v1-lanes.js, quests-3 |
| Consent at the first dawn report, not at launch | the first minutes stay clean | v1-lanes.js, ads-1 |
| The night comes closer: a closer framing at the gate, volleys, a shuddering wall | Louis: "da müssen Schüsse fliegen"; creatures are tiny at 180 rows | notes-world.md, world-3 (ranks above the lamplighter) |
| The flame shows the danger: it leans toward the next wave | a warning without an arrow or a HUD | notes-stage.md, stage-2 |

**Louis' vision as the director reads it (told to him on 14.11.; correct it when he answers):**

- A realm that is "düster und gemütlich" and looks like an expensive game: looks come first.
- A strong contrast: by day a peaceful, beautiful, working town and a mighty hall where the lord's word counts; by night a fierce fight at the gate ("da müssen Schüsse fliegen").
- The player touches people and things, never buttons. The interface matters as much as the art.
- Little arithmetic and little tactics: one money loop (taxes), happiness up or down.
- One coherent place: a mighty castle that blocks the cleft, the town behind it.
- A story that goes on: the Weltmauer, a thousand-year family of defenders; story, then endless, then more chapters.

The three widest gaps against it today: the night is small and passive; a judgment leaves too little trace in the world; the first minutes have no title and no guidance (in work).

**Still to place (a "night and life" lane after the join; the big ones may be build 3):**

- **Every creature has its entrance.** Eyes in the fog first. Each kind does one thing that is its own: the gloomweaver smothers a brazier, crows steal a torch, the Ash Giant stands as tall as the wall. Needs new sprite rows.
- **The people remember.** Whoever was judged lives on in the town where the player can see it: the smith who was helped hammers at the gate, the house of the one who was refused stays dark. Built from the flags the petitions already set.
- **Windows instead of numbers.** Mood and wealth are read from the town: lit windows, chimney smoke, market stalls and playing children when it is happy; closed shutters when it is not.
- **The morning after.** At dawn the ground before the wall shows the night: scorch marks, broken stakes, arrows in the earth, townsfolk clearing up.
- **The ancestors' gallery.** Portraits of the house line the great hall; at the chapter's end the player's lord hangs there with the ending they reached, and the heir begins the next run.
- **A light for each of the fallen** on the chapel wall, by name.
- **A picture of the realm to share** at the chapter's end or after a hard night (the castle, the house's name, the day): the game's own advertising.

**Still to place (the onboarding lane, after the join):**

- **The first sootling.** Night 1 teaches without a word: one sootling walks to the edge of the first brazier's light and shrinks back; a second one comes through where no light stands, and the guard deals with it.
- **Odile's counsel.** One line from the steward at every dawn, chosen by rule from the realm's state (a dark brazier, a damaged wall, unspent gold that would buy something useful, no archer on the wall), never the same twice in a row. It replaces a tutorial and shows the money curve.


## 7. Louis' wishes of 14.11.2026 (afternoon): taxes on foot, the growing town, craftsmen, two bars

Louis answered the director's ideas with wishes of his own and an interview. The spec is `docs/TOWN.md`; his two bars are
in `docs/BARS.md` (the desk copy every agent reads is `ci-out/director/artbar.md`).

- **The tax menu goes.** The lord walks to the houses and the people toss him their coins. To demand more he knocks at
  the door (Louis: "wenn man nachfordert und auf die Tür drückt, klopft der König dran").
- **Later:** a treasury, and a tax collector to hire. The town's buildings grow in tiers, and a town that is built up
  pays more. The director reads "die Gebäude hinten" as the town's houses plus the backdrop row behind them; Louis was
  told so and may correct it.
- **Travelling craftsmen** appear in the throne hall and offer works. Louis chose "schön und nützlich": every work is
  seen in the world and has one small effect.
- **The interface bar:** "ziemlich minimal, aufgeräumt … wie bei Kingdom Two Crowns, dass die Steuerung und alles
  selbsterklärend ist". No permanent HUD; windows instead of numbers (approved: "okay gute Idee").
- **The art bar:** "Pixel-Look, aber es sollte wie ein verdammtes Triple-A-Game aussehen, dass man gar nicht sieht, dass
  es von einer KI gemacht wurde".
- **The split (Louis):** TestFlight build 2 on Monday 16.11. has the taxes on foot and no tax menu. Build 3, some days
  later, has the treasury with the collector, the growing town and the craftsmen.

**A third workflow** runs next to the rebuild and the v1 lanes: `docs/workflows/town-lanes.js`, two gated Opus 5.5 lanes.
Started 14.11.2026 14:11 as task `w0w435zkx` (run `wf_58d17076-a6e`). Never resume it; after a stop, write a continuation.

| lane | worktree, branch | steps |
|---|---|---|
| town | `lh-town`, `claude/lh-town` | town-1 taxes on foot in Core; town-2 the same on screen (build 2); town-3 treasury, collector and growth in Core (build 3) |
| craft | `lh-craft`, `claude/lh-craft` | craft-1 the offer in the audience engine, ten craftsmen in English and German, the effects in Core (build 3) |

**Notes sent on 14.11. 14:10:** stage (no permanent HUD in stage-3, no tax card, a door as a touch target), world (door
anchors, window and shutter states, the backdrop row as its own sheet, room for a treasury), ads ("Double taxes" as a
flag for the day), panels, quests and i18n (the two bars; the tax strings will go).

**For the join:** the screen side of the taxes is re-hooked to the rebuilt town and to stage-2's touch; the townsman who
brings the first coins belongs to the onboarding lane; the store texts are read again after the tax change; the art and
the hall screens of build 3 (treasury, collector, house tiers, backdrop looks, craftsmen and their works) get a lane
of their own after the join.

**14.11. 14:20, Louis again:** "die Gebäude hinten" are the town's houses (confirmed). Farmers matter: the fields grow
too (two more plots, a farmstead tier; `docs/TOWN.md` section 3, build 3). And the people: "die Leute, die arbeiten,
schon richtig verbraucht, vom Leben geprägt … lebensfrohe Kinder … abgehobene reiche Adelige. Das bringt
Charakterwechsel mit rein." That is the third bar (`docs/BARS.md` section 3) and a fourth workflow,
`docs/workflows/people-lane.js`: one gated Opus 5.5 lane (`lh-people`, `claude/lh-people`) with people-1 (the cast in
`docs/PEOPLE.md`, the three townsfolk repainted, new working bodies, children, nobles and a footman, a line-up picture
for Louis) and people-2 (who lives where, the working day, the children, the noble's coach; picture only). Notes went
to town, craft, world, stage, panels and quests.
Started 14.11.2026 14:21 as task `wq6eijh3t` (run `wf_1b69237b-515`). Never resume it; after a stop, write a continuation.

**14.11. 14:30, Louis on the premise, and an interview:** the premise in his words (a wall of mountains, one passage,
our castle with its wall in it, behind us a continent with the other lands and their rulers) and the direction "wir
machen unsere Burg, Königreich, Stadt, Land immer wohlhabender; nicht so tief, aber so soll es wirken". He asked what
is not fun yet and what the hits do better. The director's answer and his three decisions are `docs/REALM.md`: the
dark can be pushed back with beacons into the gorge; a lost night hurts and the game goes on (the hearth burns bright,
low, embers, out; waking at a dawn before); at night being there counts (presence, braziers relit in passing). The
people bar now says: poor and even at first, visibly richer in three stages (hamlet, village, town). A fifth workflow,
`docs/workflows/front-lane.js`: one gated Opus 5.5 lane (`lh-front`, `claude/lh-front`), Core only, with front-1
(presence, target T13), front-2 (the hearth, T14) and front-3 (the beacons, T15); the picture is hooked at the join.
Notes went to people (a second cloth state), stage, world, town, panels and craft. Presence comes into build 2 only
if its step has passed its gate by Sunday; the rest is build 3.
Started 14.11.2026 14:36 as task `wftfwoyny` (run `wf_511c43f9-6d6`). Never resume it; after a stop, write a continuation.

**14.11. 14:45, Louis on the director's two doubts:** there is one front only (the gorge), so the night is no run
between walls (`docs/REALM.md` section 3 corrected; the front lane's brief had it wrong, a note went there). The
collector can be hired from the first day and comes into build 2; the lord still collects and knocks himself
(`docs/TOWN.md` section 2). New: a lamplighter who lights the street lanterns at dusk "wie im alten Prag"
(`docs/TOWN.md` section 7; the house's founder was one). Notes went to front, stage, town, people and world.

**14.11. 15:03, Louis on family, rooms and the lord's origin (by interview):** the court is the family and has ties among
each other, everyone respects the lord, a family of the lord's own comes in chapter 2. The lord never was a lamplighter:
House Lantern is the guardian house, descended from the one who made or stole the Eternal Light. Two rooms one may
enter and never must (the lord's chamber, a dungeon); special evenings with a guest on a few days, never daily. The
spec is `docs/HOUSE.md`. Notes went to quests, panels, i18n, people, stage and world. A story editor writes the exact
rewrite list on `claude/lh-house` (`docs/workflows/house-lane.js`); it is applied to the texts in one pass after the
translations, never by the running lanes.

The house lane started 14.11.2026 15:05 as task `wa3dtuo3c` (run `wf_4a940724-d4f`). Never resume it; after a stop, write a continuation.

**House lane, 14.11.2026 15:44.** The story editor delivered (run `wf_4a940724-d4f`, done): HOUSE.md sections 6 to 12,
`docs/house-rewrite.json` (45 keys, 73 STORY.md lines) and `tools/house_rewrite_check.py` (ALL PASSED). Critic 2: 7 of
ten, no blocker, eight highs. This session's write hook blocks the Write tool in other worktrees and the editor did not
go around it, so the house files live on the planning branch now; `claude/lh-house` stays at cb4b7b4, unused. The
director's decisions on the highs and on section 12's questions are in `docs/workflows/house-lane-2.js` (fix round 2
with critic 3, in the planning worktree). Never resume it; after a stop, write a continuation.
The second house round started 14.11.2026 15:44 as task `wz57nek4b` (run `wf_d2951a3c-d0c`). The editor commits on
the planning branch with the paths named on the commit; the lead does the same while it runs.

**The drill yard, 14.11.2026 16:04.** Louis asked for a barracks at the wall where the soldiers train and are upgraded
(fire arrows, a better bow) and left the decision and the whole plan to the director. Decided: yes, for build 3. The
plan is `docs/YARD.md`: three stages (barracks, drill yard, armoury), recruit or trained, two works (the pitch kettle,
the pavises), the soldiers' day, recruiting at the muster board, target T16. Nothing of it is in build 2. Core comes as
a second front round after the lane's present steps; the picture in the second rounds of the world and people lanes;
the words with build 3's batch. Notes went to the world, people, stage and front lanes: keep the room and the ids, no
work now.

**The house texts passed their gate, 14.11.2026 16:16.** The second house round (`wz57nek4b`) ended with critic 4: 8
of ten, pass, no blocker, five highs. The director took all five and every smaller note; one Opus editor fixed them
(fix round 4, commit e5684b4; report `ci-out/director/house-1-story-fix4.md`). Decided there: Pip opens evening 9.4
after the herald walked out ("He left the hall. He did not leave the house."); on the `herald_alone` path Brannock is
the witness of the double game (no step behind the lord at the dusks of days 18 and 19, then "A mask, then." on night
20); `line.herald_throne` says "a thousand years before yours"; prologue panel 2 names House Lantern; 9.2's third
choice is "Tamsin, more pie. Then the wall." The director added the three stale voice lines of DESIGN.md (2059 to
2061) to the design list. The list is final: 46 keys, 76 bible lines, 18 design lines; the check prints ALL PASSED.
Still to do: the apply pass (strings, bible, design, on top of the i18n and quests branches), the second pass for the
46 keys in six languages, the code mentions for the join (fix report), and the tuning value for night 20's first push
(front lane, build 3). Whether the corrected words reach build 2 is decided on Sunday 15.11.

**The count, 14.11.2026 16:13.** Louis asked how buying can feel as good as in Kingdom Two Crowns, where holding or
tapping throws coin after coin, without copying it. The answer is `docs/PAY.md`: a touch brings up a tally board with
one hollow per coin; holding or tapping counts the coins onto it, each with a rising clink and a tick in the hand;
letting go early pays nothing; the last coin seals it, the one who was paid lights the site lantern, and the work
starts at once. Ours: the lord pays a person hand to hand, no coin touches the ground, and every purchase ends with a
light. Core is untouched (one order when the last coin lands). Build 2 gets the plain form if the stage lane can take
it without risk for Monday (decided on Sunday 15.11.); build 3 gets all of it, with the foreman, Brannock and Bram
holding the board. TOWN.md section 3 and YARD.md sections 2, 4 and 6 point to it. Notes went to the stage, town, craft,
front, people and world lanes.

**The first widow and the straw crown, 14.11.2026 16:39.** Louis' two ideas, decided in `docs/VERDICT.md`: a young
widow as the first petitioner after the first fallen soldier (a purse, words, or a cold answer; an empty treasury greys
the purse), and a fourth, early ending: three dawns in unrest in a row, with a straw lord hung and then burnt as the
two warnings, end in three lantern slides ("They hanged the lord of House Lantern from a lantern"). Neither is a new
system. Build 3. The words wait for the house texts' apply pass. The age rating answers must be weighed before any
submission.

**Scope, 14.11.2026 16:39.** Louis asked whether his ideas overload the project. The director's rule from now on:

- **Build 2 (Monday 16.11.) is closed.** It ships what the running lanes hold: the rebuilt castle, taxes on foot, the
  touch. Nothing new enters, whatever its size.
- **Build 3 is full.** If time is short, in this order: (1) whatever build 2 left out; (2) the treasury, the town's
  growth, the craftsmen, the count in full; (3) the house texts and the first widow; (4) the drill yard with training
  and the kettle; (5) the straw crown; (6) the hearth, the beacons, the lord's chamber, the dungeon, the armoury, the
  pavises, evening 9.2. From (4) on a thing may slip to build 4 without asking Louis.
- **Every new idea is sorted at once:** one that uses what exists (a petition, a line, a prop) joins build 3's list;
  one that needs a system of its own goes to "later" and is told to Louis as such.
- **Quota, 16:39:** weekly 29 % (21 % at 15:45, with five workflows running). No sixth workflow before the rebuild
  joins.

**world-1 (the rock and the fog), 14.11.2026 17:12.** The lane's report is in (round lh-w1-6 ALL PASSED on 9e9cda9,
head e9ec11f). The director's own look: about 7 of ten, a clear step up from build 86 (the wall of rock, the warden's
niche, the bank at night). Five corrections went to the lane's notes: the far wall's speckled snow, the fog's dither
mesh, the slit of sky at dusk, the warm crags' palette, the muddy cleft wall at dusk. Louis sees a picture after the
fix round.

**Quota, 14.11.2026 17:14.** Louis: "Bis 99% und dann resete ich." The 80 % stop is lifted for the week to 21.11.: work
up to 99 %, tell him when 95 % is near, and after his reset check every workflow before going on.

**The HUD, 14.11.2026 18:26.** Louis: "das UI sieht auch scheiße aus", and he asked for five proposals. He saw five
quick sketches (`ci-out/hud-proposals`, not in git), found none a hit and left the choice to the director. The
finding: build 86 lays smooth parchment on a world of pixels and keeps three framed things on the picture; no better
frame mends that. The decision is `docs/HUD.md`: nothing stands on the walked world; a touch on the lord raises his
lantern and the world stands still (pause, purse, mood, people, the realm strip, the gear); the gold shows above him
only while coins move; the time is told by the world and by his lantern before the horn. It is the interface bar
spelled out, not a new system, so it is in build 2 through stage-3-interface, with a cut order. Notes went to the
stage, town, craft and people lanes. No sketch goes to Louis again: he sees it in a real screenshot after the
director's look. Lesson: a quick vector sketch of an interface is not a picture for Louis.


**Speed, 14.11.2026 18:46.** Louis: "Können wir den Entwicklungsprozess beschleunigen, ohne dass der Mac abschmiert?
Wenn ja, mach es."

- **Measured.** The Mac is not the brake: 33 °C, fans off, load 1.3 with five workflows running. GitHub is. There are
  five Mac slots, and a full round holds one for 70 to 90 minutes (lh-s1-5: build 6, unit 7, ui 26, ui-de 24,
  release 6). Four lanes sent full rounds, so a round waited 4 to 90 minutes for a slot: a median of 71 minutes from
  push to verdict. A round with a filter runs 6 to 12 minutes.
- **The rule, in every code lane's notes:** short rounds while working; the gate as up to three rounds side by side
  (a `build unit`; b the lane's UI test classes; c the same in German, only when words changed); never the whole `ui`,
  `ui-de` or `release` in a lane; no second round while the first waits.
- **Joins:** the whole check goes out as five rounds side by side (a `build unit release`; b and c the UI classes in
  English in two halves; d and e the same in German): about 25 minutes instead of 75.
- **The join kit** (one Opus agent, branch `claude/lh-joinkit`, report `ci-out/director/join-rehearsal.md`): a trial
  merge of all lane branches now, the conflicts by lane, a three-way merge tool for the `.xcstrings` files, and one
  `build unit` round on the trial merge. Nothing is merged for real.
- **Left out, and why.** Core's tests on Linux runners: Core needs only Foundation and two `mix` calls, but with the
  rule a Core round is 8 minutes, so the port is not worth its risk before Monday (a candidate for build 3). A cache
  for the build: a stale cache gives a wrong verdict. Cancelling other lanes' waiting rounds: they are theirs.
- **The quota is the second brake.** Faster rounds mean more work per hour, so 99 % comes earlier than 01:30. If Louis
  sleeps then, the night is lost. He is asked to reset before he goes to bed.

**Faster screen tests, 14.11.2026 18:53.** Louis: "Können wir nicht die Tests noch mehr beschleunigen, vielleicht dass
das Game schneller läuft, schneller Screenshots?"

- **Measured.** Every picture is one launch of the app: 96 launches for 17 tests in 25.2 minutes, 16 s a picture
  (lh-s1-5). The world lane's sweep class alone runs 27 minutes that way. The app reads all its test switches in one
  place (`App/DebugArgs.swift`), and `-GWTimeScale` (up to 20 times) exists but is used once.
- **The speed kit** (one Opus agent, branch `claude/lh-speed`, report `ci-out/director/speed-kit.md`): a whole sweep
  in one launch, 3 s a picture or less, additive, proven on the runner by the same pixels as the old way; a patch for
  the world lane's sweep; recipes for the played tests (`-GWTimeScale`, fewer launches); the build's flags, measured.
- **German rounds only for screens with words.** With `docs/HUD.md` the walked world carries no words, so its sweeps
  are never run with `ui-de`.
- **Order of adoption:** the world lane first, once the proof is in and looked at; every other class at the join, in
  one pass. No lane changes anything before that.

**Languages until build 2, 14.11.2026 19:19.** Louis: "Sollen wir vielleicht erstmal nur Englisch machen? Damit es
schneller geht."

- **Found.** The story is in all eight languages since 16:12 (`Story.xcstrings`, 882 keys, the i18n lane). The
  interface (`Localizable.xcstrings`, 207 keys) is in English and German only. Ahead lay: the interface in six
  languages, and the six again for every text that changes (the house texts, the new petitions). At 19:07 five rounds
  ran on GitHub's Macs and six waited.
- **Decided: yes, for the six.** Until build 2 the lanes write English and German and test in English. Nothing is
  translated into fr, es, it, pt-BR, ja or zh-Hans before the texts are final; then one pass before the store
  submission (`tools/i18n/changed.py` lists what is new, changed and gone). What is translated stays in the build; a
  missing key shows English. The store still gets all eight (CLAUDE.md).
- **German stays in the game.** Louis plays on a German phone and judges the words in German; the specs carry both
  lines already. But no `ui-de` round in a lane any more: the unit tests guard German (every key, the budgets, the
  braces), and the German screens with words are looked at once, at the join.
- **At the join:** `StoryLanguagesTests` allows a missing key in the six languages (valid where present); German stays
  strict. The second pass of the house texts and the interface in six languages move behind build 2.
- If Louis says English is enough on his phone, German waits for the store pass too.

**Full speed, 14.11.2026 19:36.** Louis: "Englisch passt auch, gib einfach Vollgas mit dem Game."

- **Build 2 is English only.** This replaces "German stays" of 19:19. German and the six other languages stay in the
  repo untouched and are not looked at before the store pass: no German critic, no German fix round, no `ui-de` round,
  also not at the join (its rounds d and e are gone). The TestFlight round switches every language but English off in
  the build, so a German phone shows no half-German game; the join's agent proves it with one screenshot on a German
  simulator. The store still gets all eight languages (CLAUDE.md), in one pass when the texts are final.
- **The gate is one round:** `build unit "ui <the lane's classes>"`. The slots are the brake (rounds waited up to 50
  minutes this evening), so one build per gate beats two rounds side by side. This replaces the three rounds of 18:46.
- **The stage and world lanes are Monday's critical path;** every other lane sends a round only when it decides
  something.
- **The join was rehearsed** (`ci-out/director/join-rehearsal.md`; tools on `claude/lh-joinkit`, the trial tree on the
  local branch `lh-join-rehearsal`). All eleven lanes merge with three small hand fixes (`Core/Economy.swift`,
  `App/DebugArgs.swift`, `docs/TOWN.md`), and the joined tree builds. Five unit tests fail; each lane has its line in
  its notes. For the join itself:
  1. the ads' double taxes must call the town's `Town.grantDoubleTaxes`, or the day's taxes are paid twice (no test
     catches it);
  2. the town's taxes on foot move numbers that quests (`TableNeutralityTests`) and craft (the lampmaker, 494 against
     60 per mille) pinned: re-pin with the town's reference habit, then tune by values;
  3. `AudienceFlowTests.testThePetitionSample` is explained and fixed (stage lane, 29390db): the first standing
     guest had moved to the door bay, so the herald's walk took 2 s against the test's 1.8 s;
  4. the atlas is at about 1960 of 2048 rows after the join: the world lane brings the second page first in world-2;
  5. the quests lane's branch is `claude/lh-q`; `claude/lh-quests` is an old docs branch;
  6. the hall's lectern still opens the old tax card when nobody waits (`openCard(.taxes, ...)` in the stage
     lane's hall): the calls go at the join, once the town's taxes on foot are in. Build 2 has no tax menu;
  7. the speed kit (`claude/lh-speed`, cb12b7d and da894be) cherry-picks cleanly onto all ten lanes; the join
     takes it and converts the still sweeps. Watch the ads lane's `AdDirector.shared.attach`, called once per
     shot in a sweep.
- **An interface art kit ahead of stage-3** (one Opus agent, branch `claude/lh-hudart`, report
  `ci-out/director/hud-kit.md`, pictures in `ci-out/director/hud-kit/`): the figures, the coins, the four faces, the
  people, the arrows and the gear of HUD.md, with proof pictures on real screenshots at noon, dusk and night. The
  director judges it; then the stage lane takes the commit and Louis sees one picture.
- Quota 49 % of the week at 19:35 (Fable 9 %).
- **The queue, measured (20:22, from GitHub's own job times):** five Macs ran and four rounds waited. The waits were
  58, 51, 63 and 63 minutes. Six of the nine open rounds were still full rounds (`build unit ui ui-de release`): the
  closing rounds of agents that began their step before the 18:46 note. **A note reaches only an agent that starts
  after it; a running agent keeps its brief.** The agents that started later sent short rounds (quests, people,
  panels). A sent round cannot be stopped from here: there is no token.
- **The round guard (20:35):** `scripts/ci/remote-check.sh` refuses a `ui` without a class filter, every `ui-de` and
  `release` for a game that has `games/<game>/ci-short-rounds`; `GW_CI_FULL=1` lifts it. It is on the planning branch,
  so it holds for every workflow started from it and from the join on. The join merges planning first.
- **A rule that must reach everyone at once** goes into a script the agents call, never only into a note.
- **stage-1-hall is accepted (22:17):** the director judged `lh-s1-8` (the hall by day, the audience, the night).
  The hall is big and alive, the audience picture is strong, the night with the hearth is the best picture so far.
  Five corrections ride in stage-2's rounds (`ci-out/director/notes-stage.md`): the near pillar, the lord on the
  throne, the lantern pool's colour, the five identical banners, the hearth light's hard edge.
- **The queue at 21:30:** an agent that started before the 19:35 note still sends one full round as its gate
  (people 20:24, world 21:17). Quota 63 % at 21:34, about 9 % an hour.
- **The speed kit is proven (22:36):** `claude/lh-speed` (cb12b7d the kit, da894be the round scripts, 2a8bd2b the
  proof class). A sweep of stills runs 2.5 to 5.7 times as fast, and 72 of 72 compared pairs have the same pixels
  (`lh-spd-1`, `lh-spd-3`). The world sweep's 31 shots went from 475 s to 149 s. The world lane takes it now
  (`ci-out/director/notes-world.md`, the patch `speed-kit-world.patch`); every other lane at the join. Not proven:
  the tap fallback, a German run, shots with `-GWStage`, `-GWScreen` or the ads lane's `AdDirector`. The build
  flags saved 21 s and are not kept.
- **First light and night glass (15.11.2026, 01:50).** Two Opus artists draw for `docs/TITLE.md`: the title
  (`claude/lh-title`, art in `games/lanternhold/art/title/`, report `ci-out/director/first-light.md`) and the
  card skin (`claude/lh-glass`, report `ci-out/director/night-glass.md`). The title's round 1 (d5f53b1) is 6.5 of
  10 and is not shown to Louis: the light lit nothing and the picture sat in one band of navy. Round 2 has one
  idea, "the light holds the dark": lit surfaces inside the light's reach in place of glow discs, the darkness as
  a front that stops at the reach, four value planes, the castle in the one gap of the Weltmauer, a taller keep
  with a real beacon, a near ledge, the dawn line, lettering lit from the flame. Every lane's notes say: no new
  parchment, and a critic's finding about the parchment look is answered with the note.
- **Night glass is accepted (15.11.2026, 02:12).** 8 of 10 on the audience and the dawn report; Louis has both
  pictures. Commits `2f0d556`, `adadad5`, `62c17fd` on `claude/lh-glass`, files added only. The last
  `UI/NightGlass.swift` was never built (round lh-glass-2 failed on a doubled paste, the repair had no round left):
  the stage lane's gate round is its first build, and `2f0d556` holds the file that passed. Plaques carry the brass
  line 1 game px in, the pane 2. Still to do at the wiring: the HUD kit's pixel coin and face on the cards. The
  ledger slip is not re-skinned, it goes. The stage lane's notes say all this.
- **The image lock stalled and is repaired (15.11.2026, 02:10).** `ci-out/director/artlock.sh` counted the shells of
  agents waiting for the lock as other image jobs (their command lines named an art script), so every holder waited
  its full 20 minutes before it ran. Now only real python and sips processes count. Six jobs had waited up to 15
  minutes; the queue was empty a minute after the repair. The old script is `artlock.sh.before-0210`.
- **The title's round 2 is 7 of 10 (15.11.2026, 02:14).** Commit `01cf941` on `claude/lh-title`; not shown to
  Louis. The lettering, the beacon and the gap with the dawn line are right. The light lit only edges (the
  director's "no glow discs" was read as "no glow in the air"), the dark was a round bush with a red outline, the
  sky had hard rectangles, the castle was small. Round 3 has one idea, "a pool of light in a sea of dark": a
  dithered falloff of six palette steps in the air, lit faces filled by distance, the dark as the frame of the
  left third, the castle 1.4 times as large from cliff to cliff, the lord 14 game px tall beside the beacon.
- **The title's round 3 is 8 of 10 (15.11.2026, 02:22).** Commit `c494e94` on `claude/lh-title`. The picture is
  there: a dome of light in six dithered steps, the castle large in the pass, the lettering lit from below, the lord
  beside the beacon. Anchors: the flame at (259, 76), the lord's feet at (275, 88), the lettering box unchanged, the
  launch lantern 13 x 69. Round 4 is one narrow pass: the castle's stone as volume (lit face, shadow face, joints one
  step darker and sparse; it was near-black joints over flat plum), a quieter dither in the air, a crisp front for
  the dark with distinct tendrils and more eyes. Louis sees the title after round 4.
- **Louis reset the week's quota (15.11.2026, between 02:13 and 02:22).** 90 % before, 1 % after. All five workflows
  ran through (newest logs 02:13 to 02:22).
- **The title's round 4 is 8.5 of 10 and Louis has seen it (15.11.2026, 02:29).** Commit `06e302e` on
  `claude/lh-title`. The castle has volume, the air is quieter, the dark's front is crisp. The two heads, the horn
  and the hand were thin violet outlines (`#5E3A9E`) and read as cartoon masks at phone size. Louis got the loading
  picture (`03-loading-full-r3`) and the title with the outlines painted out by the director (`06-title-r4-eyes`,
  proofs only, in `ci-out/director/first-light/`). Round 5 makes the same change in the art: eyes alone, the hand as
  a solid silhouette, no two eye pairs alike, nothing else touched. Still open after that: the long wall is plain,
  the lord is small, "Touch to begin" stands in smooth type on pixels (a question for the wiring).
