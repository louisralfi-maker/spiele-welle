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
- **The title's art is accepted and is in build 2 (15.11.2026, 02:31).** Round 5 is commit `ce729f3` on
  `claude/lh-title`: eyes alone in the dark (14 pairs, no two alike), the hand a solid shape with four claws on the
  lit cliff, the horn gone. It is the picture Louis got, in the art itself. TITLE.md section 5's condition is met
  well before Sunday noon. After the join one agent wires the launch image, the loading lantern and the title from
  `ci-out/director/first-light.md`; it also settles the type of "Touch to begin" (pixel letters or none, never smooth
  type on the picture).
- **The v1 lanes workflow is over (15.11.2026, 02:32; 46 agents).** Passed: quests (engine 9, content 8, table 8;
  round `lh-q1f1-1` on `2723f37`, 449 unit tests), ads (8, one high), the six languages (fr 8.5, es 9, it 8.5,
  pt-BR 9, ja 9, zh-Hans 9; on `claude/lh-i18n`, not in build 2) and the store kit (8.5). **Failed: the story
  slides** (prologue 6, endings 7; three highs each). The director's decisions:
  - **The prologue is redrawn in the title's language** (light against dark, volume first, quiet dither, eyes alone
    in the dark) by the title's artist, on `claude/lh-panels`, under the director's own round-by-round look, as the
    title was. Round 1 started 03:27. Slide 1 is the game's side view from far back (dark, the wall with one glowing
    door, home); slide 2 is the founding (one point of gold struck from the bare rock), so it fits HOUSE.md's
    origin and the rewritten caption; slide 3 keeps its idea with a large rider; slide 4 is the court in a half ring
    under the house's lantern, drawn as pixel people. The stage and the strings stay. It must be accepted before the
    join; if it is not, build 2 ships today's slides.
  - **The endings' slides wait for build 3.** A player reaches an ending on day 20; their highs are in
    `ci-out/director/notes-panels.md`.
  - **The ads high is fixed at the hookup:** one source for the doubled day, `Town.grantDoubleTaxes` behind one
    one-line function; the lane's own flag goes (`notes-ads.md`).
  - **Quests, for the store pass and build 3:** German "Laterne 38 ist heim" becomes "ist zurück" on chip and header
    and "ist heimgekehrt" in the openings; `report.highcairn_true.r1` reads "ride in at dusk"; the smaller open
    items are in `ci-out/director/quests-3-table-*.md`.
- **The people lane's workflow is over (15.11.2026, 03:33; 8 agents): the cast 8 of 10, the town's daily life 8 of
  10.** Last round `lh-p2f1-3` on `9a34df0`, ALL PASSED. The director looked at the line-up, the square and the
  lamplighter himself and ruled (`ci-out/director/notes-people.md`, 03:39); one Opus agent makes the director's
  pass on `claude/lh-people` (started 03:40), then the lane rests until the join.
  - **The lamplighter's evening is a dusk ritual, as a rule in data:** no street lantern before 17:00, the last at
    the horn, the Flame taken between 16:00 and 16:30. As built it was a noon chore with a lantern lit in full sun.
    He lights by hand only the posts the time allows (three or four in build 2); the town lane sets its posts
    inside that reach at the join. Build 3: the lit street grows with the realm (3, 5, 7 posts) and Fen runs a taper
    to the far posts: the wealth arc at night.
  - **The collector** keeps his post just inside the castle's town gate and is the morning's figure; the town lane
    moves `Town.collectorPost` there at the join.
  - **Names:** Ned Thatch is Ned Furrow, Saul Wicket is Saul Tolliver (a pirate joke and a film echo).
  - **Art:** Nib's red read as blood at the well (a clean kerchief instead); the children keep 14 px from Wenna; the
    lamplighter's burn read as a tongue.
  - **The lord's sheet belongs to the people lane.** The mended cloak for hamlet and village is accepted as built.
  - **For the join,** from the lane's notes (`docs/lanes/people.md` on its branch): the realm's stage into the
    cloak in place of `-GWCloth`; mended `kingKnock` and `ladyKnock`; the court's ties and the lamplighter's spot in
    the rebuilt hall; the berth and the builders' hook on the rebuilt road; `TownDay` on the people branch is now
    `TownLife`, so it no longer clashes with the town lane's `TownDay`.
- **The prologue's round 1 is back (15.11.2026, 03:41) and is not accepted: 5.5 to 6.5 of 10 by the director's own
  look** (the artist's own scores 6 to 7; the title is 8.5). Commits on `claude/lh-panels`: `889dc74` (slide 1 and
  `tools/slides/litkit.py`), `8db48b7`, `24f390a`, `710fdcb`. The compositions are mostly right.
  - **Two faults run through all four.** Every lantern has a banded ellipse of light in air, and the figures are
    flat slabs with a 1 px orange line around them.
  - **Per slide:** 1, the wall reads as tree trunks and the castle is small; 2, coloured shards, an ancestor of
    12 px, a dead right half; 3, the moon sits on the beacon's head, so the dark beacon reads as a lit lamp; 4, the
    heir stands in front of the hand-over.
  - **Round 2 started 03:45** with one narrow brief: light is seen only on what it hits, no outline anywhere, and
    one thing per slide. **Slide 2 gets a new picture: slide 1's place, closer and long ago, bare, one point of
    gold in a huge dark,** so slide 1 answers it.
  - Louis sees nothing of the prologue before it stands beside the title.
- **The prologue's round 2 is 5.5 to 7 of 10 (15.11.2026, 03:54) and not accepted.** Commits on
  `claude/lh-panels`: `16444ef` (slide 4), `4d9aa45` and `5fedfef` (slide 2), `ca6d749` (slide 3), `d2660ba`
  (slide 1). Slide 1 (7) and slide 2 (6.5) hold as pictures; on slide 3 the dark beacon reads at once (the empty
  basket black in the moon). The figures stay the weak spot: polygons cannot reach the title's hand.
  - **Round 3 started 03:56, decided with the artist:** every figure is a hand-set pixel grid, as the people lane's
    cast is, and the heir and Odile are the people of the game's own portraits. **Slide 4 is a new picture: a close
    two-shot** of the lantern, the heir, Odile and the circlet; the court and the brick wall go. On slide 3 Aldric
    rides alone (the bearers read as gravestones). Slides 1 and 2 get one pass each.
  - **Captions (the director's decision):** build 2 takes panel 2's and panel 4's text from HOUSE.md section 6,
    rule 8 (English and German), with the house texts' apply pass at the join. Panel 4 still says "The one who
    lights the lamps", which Louis turned down; it must not reach his phone again. The new pictures fit the new
    captions.
- **The prologue's round 3 is 6 to 7 of 10 (15.11.2026, 04:06) and not accepted.** Commits on `claude/lh-panels`:
  `1e65854` (slide 4), `6fcb5f5` (slide 3), `da36b05` (slide 2), `f769d4a` (slide 1). The director's scores: slide 1
  7, slide 2 6.5, slide 3 7, slide 4 6 (the artist's own: 7, 6.5, 6.5, 6.5; the title is 8.5).
  - **What the round taught:** hand-set figures of 30 to 60 px work (the rider and his horse read at once). Figures
    of 100 px do not: on slide 4 the heir is a flat blue slab, Odile a black one, the circlet is not seen and the
    ringed disc of light is back. **So no large figure stands anywhere in the prologue.**
  - **The set's one idea, held in all four:** one small gold light in a big dark. Slide 1 the door's lantern,
    slide 2 the first spark, slide 3 Aldric's lantern riding out, slide 4 the circlet under the house's lantern.
  - **Round 4 started 04:07. Slide 4 is a new picture, the empty seat:** the hall at night in side view, as the game
    shows it; the lord's seat empty on its dais with the circlet on it, the house's lantern above, the heir a small
    silhouette on the threshold of the open door, far left. The player walks into this room a moment later.
  - **The other three get one narrow pass:** slide 3 a pale road from the last window to the beacon's hill, the
    moon's cold rim on the ridges, the horse's legs in its own dark; slide 2 warm rock only near the spark (the lips
    read as red curtains) and a larger ancestor on a step; slides 1 and 2 few uneven cracks in place of the regular
    strata (they read as brick); slide 1 the castle in the night's stone tones (it reads as a painted toy).
  - Still open in a running round: the people lane's director's pass (`lh-p3-1`).
- **The prologue's round 4 is 6.5 to 7.5 of 10 (15.11.2026, 04:12) and not accepted.** Commits on
  `claude/lh-panels`: `a4cc26f` (slide 4, the empty seat), `cd7866c` (slide 3), `908adb7` (slide 2), `24e0c80`
  (slide 1). The director's scores, held beside the title's picture: slides 1 and 2 are 7, slide 3 is 7.5, slide 4
  is 6.5 (the artist's own: 7, 7, 7.5, 7).
  - **The set holds together now** as one small gold light in a big dark, and the empty seat is the right picture
    for the hand-over. What still parts it from the title is density on the main thing and depth. Slide 4 is thin:
    the pillars are poles, the wall is dashes, the floor's light reads as a red brick carpet.
  - **Round 5 started 04:12, mostly for slide 4:** the moon falls through the door as a cold wedge on the floor and
    the heir's long shadow lies in it and points at the seat; the lantern's warm pool lies at the dais; stone piers
    with arches in place of poles; the house's teal banner behind a larger seat; flagstones in stone tones.
    Slides 1 to 3 get three small things each for depth (mist at the mountain's foot, the castle standing out of
    the cleft, a clearer road, a near edge of stalks). The captions' band stays calm on all four.
  - **The rule for build 2:** round 5 is the last full round before the join. If the four slides are 7.5 or more by
    the director's look, they go in and one short round checks them; what is still weak waits for build 3.
  - Quota at 04:12: 12 % of the week, 3 % of the Fable part.
- **The town lanes' workflow is over (15.11.2026, 04:15; 16 agents).** Branch `claude/lh-town` at `2584730`,
  `claude/lh-craft` at `cc9bf4b`. The critics' last looks:
  - **Taxes in Core (town-1): passed, 8.** One high stays: the first morning is met only in Core. The chandler
    waits at his own door, far behind the throne, so a first-time player never sees the toss, the purse opens on
    44 and the first dawn says "Taxes 0".
  - **The tax screen (town-2): 7.5, not passed.** Three highs: the lord covers the household's bow at the knock;
    the coins land in the lantern's glow and not in a hand; the collector walks on while the coins fly.
  - **The growing town in Core (town-3): passed, 8.5.** It is switched off for build 2 (`TownRules.growthOpen`).
    Its one high goes to the front lane for build 3: the first line alone holds 19 nights untouched, so skipping
    the walls costs nothing until night 20 (T13 and T14; then T12 asks that the skipper's hearth is struck by
    night 14).
  - **The craftsmen (craft-1): passed, 8.** Build 3. Two text highs wait for its second round: the mason's living
    lord in stone is made deliberate in Odile's hint (this house sets its lords in stone only when dead), and the
    fire arrow's reaction says "strikes a little harder" as the offer does.
  - **The director's decisions.** Taxes on foot is Monday's centrepiece, so one Opus fix agent runs on
    `claude/lh-town` since 04:17 (fix 2): the lord steps back at the knock, the coins land in an open palm at belt
    height, the collector stands 1.5 s at a door with a strongbox, and **on the first morning the chandler walks to
    the courtyard and waits on the lord's way**, so the first minute of build 2 shows the toss. Places are named
    by anchors, because the world lane rebuilds the castle. The word "pouch" leaves TOWN.md (an open palm with a
    coin, as built). The extra coin "for the lantern" is not in build 2; it waits for build 3 with the growing
    town. Gate: one short round `lh-t2f2-<n>` and the director's own look at a sheet of four crops
    (`ci-out/director/town/fix2-sheet.jpg`).
- **The prologue's round 5 is 7 to 7.5 of 10 (15.11.2026, 04:23) and the set goes into build 2.** Commits on `claude/lh-panels`: `8d3b67f` (slide 4), `45a58d3` (slide 1), `3dfe8f9` and `e633122` (slide 2), `30c5467` (slide 3). The director's scores beside the title (8.5): slide 1 is 7.5, slide 2 is 7, slide 3 is 7.5, slide 4 is 7. Slide 4 made the biggest gain of all rounds: with two lights, the piers and the banner it reads as a real hall. Its dais is still orange and red blocks that read as brick, the lit face of the nearest pier is one bright line, and the heir's shadow is not read. **The decision, against the 7.5 rule of round 4:** the set goes in whole, because today's slides tell the origin Louis turned down and the new four fit the house's captions. There is no further full round. The artist does one narrow touch (slide 4: the dais as stone steps with a warm pool, the pier's lit face, the heir's shadow; slide 2: the struck spark throws a small glow and a warm rim on the ancestor), sets `slides.prologue.2` and `slides.prologue.4` to HOUSE.md section 6, rule 8 on the lane (one item less for the join), and runs one short round `lh-pr5-1`. The proof for Louis is the four slides as the game shows them (`ci-out/director/slides/prologue-game-1.jpg` to `-4.jpg`). Build 3 gives the set a pass for richness on the main thing. Quota: 13 % of the week.
- **The people lane's fix pass is accepted (15.11.2026, 04:34); the lane rests until the join.** `claude/lh-people` is at `def67db`; round `lh-p3-2` on `9d34276` is ALL PASSED (build, unit, `TownLifeUITests`, `PeopleUITests`), read by the director from the results branch. The director's look at `ci-out/director/people/fix2-sheet.jpg`: the line-up reads at phone size, Nib's cool white stands off the plaster, no child stands at Wenna's well, Silas' burn and his shouldered pole read, and shot 75 (he lights the lantern at the horn in violet dusk) is a picture to keep. **Open for the join:** with today's anchors Silas reaches one post only (first and last lantern at 19:00) and walks home until about 20:26. The rule is data in `TownLamps.plan(for:)`. The join's levers, in this order: the posts' places in the rebuilt town (the first post just outside the castle's town gate; four posts fit inside about 206 px, three inside about 238 px); then his pace on the way out, up to the lord's 36 px/s; his door beside the last post; never the Flame before 15:30. The join's gate for him: the first street lantern burns by 18:00 in gold light and at least three burn at the horn. `Town.collectorPost` moves to just inside the castle's town gate.
- **The prologue's touch is accepted and its round passed (15.11.2026, 04:43).** `claude/lh-panels` is at `07e45ed`: `9241fc4` (slide 4: the dais in the hall's stone, the pool in three warm stone steps, the pier's light fading, the heir's shadow 6 px wide and two tones darker), `5ea114c` (slide 2: the spark's dithered glow and the warm rim on the ancestor), `07e45ed` (the captions of panels 2 and 4, English and German, from HOUSE.md section 6, rule 8; `SlidesTests` follows). Round `lh-pr5-1` is ALL PASSED (build, unit, `SlidesUITests`), read by the director from the results branch. The director's look at the game shots (`ci-out/director/slides/prologue-game-2.jpg`, `-4.jpg`): all four slides are 7.5, the captions fit their pictures, the stage is calm. **One thing was still old:** slide 4's name label is a tilted parchment slip. The artist sets it as type only (small caps in the lit dot's gold with a hairline, upright, in the picture's top left corner) and runs `lh-pr5-2`; then Louis gets the four game shots. For build 3: the pool's lowest step is still a little blocky, and the set gets a pass for richness on the main thing.
- **The prologue is finished for build 2 and Louis has seen it (15.11.2026, 05:01).** `claude/lh-panels` is at `ea7a04b`: slide 4's name label is type only (the stage's small caps in the lit dot's gold, about 60 % of the caption's size, a 1 pt hairline at 40 % under it, upright, 16 pt in and 12 pt down inside the picture's top left corner). Round `lh-pr5-2` is ALL PASSED (build, unit, `SlidesUITests`), read by the director from the results branch. The director looked at all four game shots and both forms of slide 4 (`ci-out/director/slides/prologue-game-1.jpg` to `-4.jpg`, `prologue-game-4-lord.jpg`): no parchment, the name reads on the dark vault, the captions fit; 7.5 stays. Louis got the four shots with that score. **The panels lane rests until the join.** The join takes the five prologue files and the stage's label change together. For build 3: the label's hairline ends about a pixel from the far pier's capital (move the label 4 pt left or shorten the line), and the pool's lowest step.
- **Taxes on foot: the second fix pass is accepted; the town lane rests until the join (15.11.2026, 05:25).** `claude/lh-town` is at `f03b37f` (f982cc8 code, art and tests; 6d4ce6f TOWN.md and lane notes; 66ac711 `arcHeight` 8 to 5; f03b37f notes). Round `lh-t2f2-2` is ALL PASSED (build, 489 unit tests, `TownUITests` and `FirstDayUITests`), read by the director from the results branch; `lh-t2f2-1` passed too. The director looked at the sheet (`ci-out/director/town/fix2-sheet.jpg`) and at two full shots at phone size. **The first morning is 8 of 10:** the chandler waits in the courtyard and tosses her 16 coins into the lord's open palm as he leaves the hall, with no word and no menu; the purse goes 44, 60. **The landing is right** (the palm at belt height, 10 px under the lantern's glass). **The bow at the door is 7:** it reads, but the lord's brown coat and the household stand on the tan wall and the door, so the two figures run together at dusk (`ci-out/director/town/knock-bow-crop.jpg`). **The collector's stand-in is lost against the wall and never ships.** Louis got a crop of the first morning without the old interface (`ci-out/director/louis/steuern-erster-morgen.jpg`). **For the join, in this order:** (1) the people lane's collector draws in place of the stand-in: he reads `Scene.collector.still`, stops 1.5 s per owing door, the box mouth sits at `collectorBox` (dx 7, dy 9), then `drawsCollectorStandIn = false` and the stand-in with `SpriteID.townStrongbox` is deleted; if that does not fit into the join, the collector cannot be hired in build 2; (2) the knock in the rebuilt town: try `TownShow.knockBackStand` 15 to 18 so the lord stands clear of the door on a darker part of the wall, judged on a dusk shot at phone size; (3) `Town.firstMorningEnters` and `Town.firstMorningX` hang on `Realm.hallX`: re-run `testTheFirstMorningIsMetOnTheWayToEveryGoalOfDayOne` in the rebuilt castle; (4) a new lord body keeps the palm of knock frame 2 at `TownShow.lordHand` (5, 12); (5) `FirstDayUITests` pins 44, 60, 48 and the report's 16.
- **The castle, touch and the gorge beacons each stand at 6.5 of 10 after their first critic look; the director's corrections are in the lanes' notes (15.11.2026, 05:37).** All test rounds were through at 05:25 (234 sent, 234 done). **World-2 "one castle"** (`claude/lh-world` `e3cde5e`, round `lh-w2-4` ALL PASSED): 2 blockers, and the director agrees with both after looking at w-1830-noon, w-1830-night and w-2000-dusk. The keep is a flat grey slab in the curtain's value, and the open hall door reads as a furnace. Fix order: the keep; the hall door; the light pools; the forebuilding (no temple front, a stair to the door, the door stays at x 1830); the tiers from the front gate; then the rest. Added: at noon the three masses separate by warmth and value (keep palest and coolest, curtain middle, forebuilding lighter and warmer); the keep's night windows take the chapel lancets' treatment at about 60 %; the keep may break its symmetry inside its box. The critic's German frame is overruled (build 2 is English only). **Stage-2 "touch"** (`claude/lh-stage` `3dfa27e`, rounds `lh-s2-5` and `lh-s2-7` ALL PASSED): 2 blockers. The hall door's mark hangs over a window and the lord leaves through the wall: `touch-door-hall` hangs on the painted door's anchor, never on a fixed x. No frame shows touch at night: a launch argument and shots 153, 153b, 153c. Changed by the director: the marks' parchment tile is not softened, it goes (HUD.md rule 2: the sign alone in bone with a dark edge, plus a 1 px warm rim on the thing), in this fix pass if a round is left, otherwise as the first job of stage-3-interface; "Next petitioner" becomes a quiet night-glass plaque; no German proof for build 2. **Front-3 "beacons into the gorge"** (`claude/lh-front` `5219f14`, round `lh-f3-6` ALL PASSED, 500 unit tests; build 3 material, Core only): 1 blocker, 4 highs. The first beacon pushes no fog until night 15. Decision: two edges. The battle's bank keeps its natural edge capped by the furthest lit beacon (T1 to T8 and the idle lockstep hold); the picture gets its own veil over all land beyond the furthest lit beacon, by day and by night, so every beacon uncovers its land on the day it is lit. The sites and the land keep their places. The lane first measures whether the two edges can be one. The wager must pay at x1 ("never a trap" over whole runs, the King slain in at least 9 of 10), the beacons' fire must not beat the walls, save and continue must agree. REALM.md carries the two edges (section 5) and T14's sentence as built (two broken nights with less than two steps of mending between them). **For the join:** the hall door's anchor is one value shared by the world's forebuilding and the stage's `touch-door-hall`; walls beyond the gate decide no night at today's budget and x1.5 leaves the Great Beacon no slack, both tuned with the town's income. No picture of the new castle goes to Louis before its fix pass is checked and the shot is free of the old interface.
- **The beacons' first fix round is accepted; it found that walls beyond the gate are a liability in today's balance (15.11.2026, 07:04).** `claude/lh-front` is at `182ea37`; round `lh-f3f1-4` on `cdc905e` is ALL PASSED (build, 504 unit tests, the beacon sweep); T1 to T8 are byte for byte the same. **B1 is solved with one edge:** the sites stand inside the fog at x 300, 229, 160 and 95, each lit beacon holds the fog at the next site by day and by night, and the day's fog rests at x 300. The director's two edges of 05:36 are withdrawn (REALM.md section 5 corrected). Also built: strength 600, 500, 400, 400; the fire's pool 40; a standing beacon is whole again at dawn only while a wall beyond the gate stands; a raise waits beyond a fallen beacon and the save agrees; three new lines. **Open, for the build 3 join:** the wager barely pays (the careful bot 428 creatures against 443; the bold bot loses the finale in 6 of 10). Target: two beacons before the Great Beacon never cost the finale; prices first, with the town's income. **The finding:** front-3's walls-neglected bots still built walls. With walls really skipped, a realm with no wall beyond the gate and no beacon never falls at x1, x1.5 and x2 and slays the King 10 of 10 with no defender lost; the reference loses 8 to 13 defenders at x1 and falls in 5 of 10 at x1.5 and 10 of 10 at x2 (table: the front lane's `ci-out/lh-f3f1-4/beaconsweep.txt`). The walls pull the fight out of the light and the arrows and cost the gold that buys the Great Beacon two days earlier. **Decision:** not for build 2 (a player at the game's own strength wins either way, and T1 to T8 must not move before Monday). It is the first job of build 3's tuning, before T12 to T14: one diagnosis agent on a branch cut from the front lane (where the reference's creatures and defenders die against the walless control; whether creatures held at a wall stand outside the archers' reach and the braziers' light; whether the guards step out), then the smallest change that makes a walled realm hold at least as often as a bare one at every budget. The likely answer is that a wall must be a place the archers shoot from. **Quota at 07:04: 22 % of the week, 6 % of the Fable part** (13 % at 04:22: about 3 % an hour with three Opus agents). At that pace 80 % comes around midnight before Monday, so nothing outside Monday's critical path gets an agent until build 2 is out. The world's round `lh-w2f1-3` and the stage's round `lh-s2f1-3` were open at 07:01.
- **The beacons' second critic look: one edge confirmed, the tuning waits (15.11.2026, 07:13).** Look 2 gave 6.5 again: its blocker was the one-edge model against the 05:36 note, which the director had already accepted at 07:04; its highs (forward cannot be reached in a whole run, T15b and T15c lean on the Great Beacon's gold, no walls and no beacons is the dominant line) all hang on the base game's walls. Order to the lane: five small things in one round (`mouthFraction` becomes `deepFraction`; T15c asserts creatures at the defence against the walls-neglected control; a petition's fog shift adds to a held line; two strings; the lost defenders by place and cause), then the lane stops until the build 3 join. For build 3, after the walls: the bot that keeps the walls and raises all four after the Great Beacon (holds where the reference holds, King in at least 9 of 10, all four by about night 16), price ladders such as 40/60/90/120, T15b by night 14. Picture jobs of the build 3 join: the world lane paints the gorge's floor at x 30 to 330 (the beacons stand inside the gorge, where look2 has near firs), and the tender with a pole who walks out from the outermost wall at dawn.
- **Touch, fix round 1: both blockers fixed (15.11.2026, 07:30).** Round lh-s2f1-3 (5eae2f3) ALL PASSED with build, all unit tests and the ui classes Touch, Hall, FirstDay, Audience, Look2, Polish, Lord. The director saw 130 (the mark over the painted door), 143 (the lord in the doorway), 152 and 153 (the night's marks and the repair slip with its price) and 158 (the raised lantern). Open and ordered: the raise's ring is a smooth line and goes onto the pixel grid or goes; the arm-up pose is build 3. stage-3-interface starts as soon as stage-2 passes; its first jobs are the marks without their parchment tile, the slip and the bubble as night glass, then HUD.md's cut order. For the join: `HallDoor.paintedX` reads the world lane's one named value for the painted hall door (asked of the world lane in notes-world.md, with warmer lit slits on the gate towers at night); the stage's debug arguments `-GWDamage`, `-GWSnuff`, `-GWPressed` must do nothing in Release.
- **Touch at 7.5 after the second critic look, no blocker (15.11.2026, 07:35).** Five highs, all ordered into one fix pass with one round: the raised lantern becomes a ground light with sparks and no line; a slip replaces its thing's mark (the horn's slip lay on the door mark); Marek's cart never carries the barracks' rim and mark; a site's mark clears the heads (tip about 22 px over the walk line); at most three marks in view by day and 120 px between building marks; the rim at 0.5 by day. What the fix pass does not reach becomes the first jobs of stage-3-interface. Quota 23 % of the week, 6 % of the Fable part (07:31).
- **The castle after fix round 1 (15.11.2026, 07:42).** Round lh-w2f1-4 ALL PASSED (886a717; head 04b72be). Both of the critic's blockers are fixed by my own look: the keep stands at the gatehouse's bar, and the open hall door is a lit room with a wedge on the cobbles. Dusk and night an 8, noon a 7. Six items for the next pass in one round (notes-world.md): the front gate's near pier goes; lit windows take the fire's amber; the hearth's bright point moves off the lord's head; the hall door's one named value; sun at noon; the water thread behind the keep. Louis got two crops free of the old interface (ci-out/director/louis/burg-abend.jpg, burg-nacht.jpg).
- **The castle's second critic look (15.11.2026, 07:47).** 7 of 10, two blockers, both of one kind and both confirmed: the dark foreground piers in front of the gatehouse and the postern go, with no replacement in build 2. Ten items for fix pass 2 in one round, each sprite previewed through scenemock first (notes-world.md): the piers; the keep's night mist without periwinkle; noon with sun from the left and the mirror broken; the hall door warm by day; the buttress slabs and the chapel cone; lit windows halfway to amber; smoke and the water thread; halos cut by eave and jamb; the valley's warm ramp; the door's one named value. Withdrawn: moving the hearth's glow. Deferred: tier 2 from the front gate (the ledger panel goes in stage-3, judged after the join), the moon's notch, German frames.
- **The beacons' fix round 2 is accepted; the front lane stops (15.11.2026, 07:53).** Round lh-f3f2-1 ALL PASSED (d0ec1cc; head 3b5dd4e; 507 unit tests, T1 to T8 byte for byte). The fog's last line is `GorgeTuning.lastLineFraction` (x 37); REALM.md section 5 says so now. **For build 3's tuning, measured over 400 runs:** no player holds all four beacons at once at any price ladder; the builders' time is no lever; half prices bring the bold bot to the King in 8 of 10. The lever is holding: the far beacons' strength, the strike's reach, the relight price beside the Great Beacon. The keeper's target, reworded (the Great Beacon stands on day 15 to 17): walls kept, the Great Beacon by day 17, at least two beacons standing through nights 10 to 14, all four standing at once by about night 22, the King slain in at least 9 of 10. **Two base-game findings for the walls' tuning:** most defenders lost are archers walking on the ground at the middle line, run down by shadehounds (136 of 217 in T15a without beacons); a quarter of the reference's losses are guards walking into the Lightless King between the lines on night 20 (25 of 101). Both say the same as the walls finding: defenders belong on the wall, not in front of it. The local lh-front worktree is behind origin; fast-forward it before the join.
- **The front lane is closed (15.11.2026, 07:58).** The beacons' critic look 3: 8.5 of 10, no blocker, no high. All three steps passed (presence 8, the hearth 8, the beacons 8.5); the lane's workflow has ended. The critic's one warning for build 3, in a player's words: no surviving player ever holds all four beacons, even at half prices, so Louis' "immer weiter in die Schlucht hinein" is not yet a goal a player can reach. Build 3's tuning starts there, after the walls. Must survive the join: the petition's fog capped at the furthest lit beacon, T15c on the walls-neglected control, the defenders' table, "tended from the wall" with its picture, the ring of standing stones at the fog's last line, T1 to T8 byte for byte.
- **The pre-join runs (15.11.2026, 08:01).** The front lane's slot goes to one Opus 5.5 agent that does the half of the join which does not need the rebuild: branch `claude/lh-prejoin`, cut from planning, with i18n, quests, ads, panels, town, craft, people, front and store merged in the join kit's order (never world, stage, hudart, glass or title). Three steps: (A) merge, compile and unit tests green, T1 to T8 byte for byte; (B) the hookups already decided (the ads' double taxes through `Town.grantDoubleTaxes`; the people lane's collector replaces the town's stand-in; the lamplighter's join items); (C) the house texts in English from `house-rewrite.json`. Rounds `lh-pj-<n>`, short and filtered, at most five. Report: `ci-out/director/prejoin.md`, with the list for the final join in order. Corrections go into `ci-out/director/notes-prejoin.md`; the agent reads it before every round. **Decided with it: the plain count (PAY.md) is not in build 2.** Build 2 stays closed at the new castle, touch, the interface without parchment and taxes on foot; the count comes whole in build 3. The house texts are in build 2, in English.
- **The castle's fix round 2 accepted (15.11.2026, 09:19).** Rounds lh-w2f2-1 and lh-w2f2-2 are ALL PASSED; `claude/lh-world` stands at bc7b574. Both foreground piers are gone (gatehouse and postern stand clean), the night mist is a desaturated grey with no bright line, the keep at noon is lit from the left, the hall door is warm by day, the buttresses are removed, lit windows are halfway to amber, smoke is a plume of growing puffs, and light pools are cut by the architecture (`LightClip`; `LightQuad` is now 48 bytes). The join's anchor is `SceneLayout.castleHallDoorX` (1830); `castleForebuildingX`, `CastleRooms.doorOpen` and `castleKeepX` read it, and the stage lane's `HallDoor.paintedX` reads it at the join. For the join's list: both lanes changed the Renderer and the pool shaders (the world's `LightClip`, the stage's rim and pressed pool). Ordered for world-3-camera-pass, time-boxed to about 16:00: a step of haze on the cliff behind the castle at noon, one day factor for every fire pool, the gatehouse's corbels at the keep's noon values; then the camera, M2, M4, M3; M5 and L2 to L4 only if the time holds. Build 3: the cleft wall's end (not one layout value).
- **World-2 "one castle" has passed (15.11.2026, 09:23).** Critic look 3: 8 of 10, no blocker, on round lh-w2f2-2. Keep list, binding: the hall door at dusk and night (the dark lord in the warm doorway, the wedge on the cobbles, the line under the shut door), the keep with its mist and its noon light from the left, the tiers at the hall door, the chapel tower with three lancets and the brazier, the postern, the clean gatehouse without a foreground plane, one castle. Into world-3's whole-world pass (notes-world.md, in cut order): the cliff's haze behind the castle at noon, the lord's lantern pool that falls as a box on walls, the bakehouse glow as a wedge instead of an ellipse, smoke that can be seen, the hall door's wash under the eave, one day factor for fire pools, the gatehouse's corbels, the valley one warm step by 2530, and the mediums (the chapel's bell, the tier-3 postern's roof, a merlon stub). After the join: tier 2 from the front gate, once the ledger panel is gone.
- **The pre-join's interim and three decisions (15.11.2026, 09:23).** `claude/lh-prejoin` at 0ac79c4: A, B and C are built; lh-pj-2 and lh-pj-3 failed on four things that are fixed; lh-pj-4 runs. Decided: the craft is closed in build 2 by `CraftVisits.open = false`; the atlas grows to 2048 x 4096 by `AtlasLayout.pages = 2`, taken verbatim from the world lane's 85f9a2d; the table's T4 keeps "under 30 at dawn 8" as a hard rule, and only "the sender not above the reference" (21 against 20) becomes a strict expected failure. Build 3's tuning list against the walked town: the lampmaker (494 per mille against 60) and T4's sender. The town lane's T1 to T8 file (c801a6e0) is the truth for the merged tree; the front lane's T13, T15 and loss tables are byte for byte, the hearth reports differ only in the purse sampled at dawn.
- **The pre-join is accepted; the rolling join starts (15.11.2026, 10:03).** `claude/lh-prejoin` 5507e55: nine lanes plus the speed kit merged, B1 to B4 hooked up, the house texts applied in English (46 keys). Checked: lh-pj-4's one unit failure was the T4 sender, lh-pj-5 ALL PASSED, 780 unit cases with two strict expected failures (the lampmaker, T4's sender), T1 to T8 byte for byte the town lane's file. Gap: eight UI classes never ran on the merged tree (Craft, MidChapter, Lord, Polish, Look2, LightProbe, Probe, SweepProof); round lh-pj-6 runs them. Decided: `TownShow.collectorBox` (12, 16); the end card's Continue goes through `AdDirector.chapterEndContinues` in build 2. **The rolling join:** one Opus agent builds `claude/lh-join` from 5507e55, merges the world's accepted castle (bc7b574) and the stage's accepted touch, and does the items of prejoin.md section 5 that need no stage-3: taxes card and lectern out, the door touch, the hall door's anchor, the first morning in the new castle, the collector's hire and post, the lamplighter's posts, the atlas tests, the debug arguments off in Release. Rounds `lh-rj-<n>`, report `ci-out/director/join.md`, corrections in `notes-join.md`. The rebuild workflow's own join (world into stage, labels `lh-j-*`) stays as it is. After it, `claude/lh-stage` is merged into `claude/lh-join` as a delta; then the cards in night glass, the quests, the first-launch order with the title, the review and the `tf-*` round. Quota at 10:03: 30 % of the week.
- **The pre-join's gap is closed (15.11.2026, 10:44).** Round lh-pj-6 on 5507e55: build and the eight UI classes that had never run there, ALL PASSED (17 tests, none skipped). `CraftUITests` passes with the craft closed, because it opens the cards by debug argument; it needs no skip. Left open on purpose: 5507e55 itself never ran the full unit step (one test file differs from 0ac79c4's full run); the join's rounds run all unit tests anyway.
- **The join's first interim; the collector is hired by touch (15.11.2026, 10:52).** `claude/lh-join` 6790561, not green yet: lh-rj-1 failed one unit test (the lamplighter was seen inside the hall, because world-2 emptied `RoomFades.rooms`; fixed by `TownLife.closedRooms`), lh-rj-2 and lh-rj-3 did not build (`HallDoor.paintedX`, `TouchThings.extent`; both fixed); lh-rj-4 and lh-rj-5 run. T1 to T8 are byte for byte c801a6e0 on the merged tree. Gone with the join: the taxes card, the lectern as a target, `Economy.setTax`. Decisions: (1) the collector is hired by touch at his post (x 2290, just inside the town gate): first touch, his offer in the bubble and the slip "Take him on"; second touch hires; later touches send him away or take him on again. No petition at the audience, so the reference bots never hire and T1 to T8 stay. TOWN.md section 2 is corrected on the join branch. Cut line 17:00: the join's green comes first. (2) The lamplighter's posts are set by rule from `WorldLayout.townPlots` (post 1 just outside the postern, then the gaps between houses, never before a door, at least 40 px apart, up to four); his setting-out time moves, not his speed, so that three lanterns burn by the horn; only as pure show. (3) The collector's name is Saul Bracken (the catalog and TOWN.md); the people lane's constant "Saul Tolliver" follows. (4) `CraftUITests` keeps running, the join's skip comes out. Open: the gold above the lord waits for stage-3.
- **Stage-3-interface passed its gate; the join takes it now; two lanterns by the horn (15.11.2026, 11:39).** The
  stage lane's report is in (`claude/lh-stage` cb49c6a; gate `lh-s3-8` ALL PASSED on 35b9c8b: build, all unit tests,
  13 UI tests in seven classes; checked on the runner's results). In: nothing stands on the walked world (HUD.md 1),
  the lantern moment on a tap on the lord (HUD.md 2), the gold ticking at the lord, the realm strip on glass, every
  card on night glass, the marks as signs, the Burgherrin's portrait, four ambience beds. Not built: HUD.md section 4
  (the breathing), the ledger on the lectern, PAY.md (all build 3). My own look at frames 40, 45, 133 and 160 found no
  blocker; two points went to the lane (stock iOS glyphs on glass become kit signs; the gear gets a glass disc). The
  critic looks still run. Decision: cb49c6a is accepted for the rolling join's delta merge now, so the merged lanes'
  tests meet the HUD-less world today, not tomorrow; items 4 and 10 fall due with it; the title (item 12, ce729f3)
  follows once that is green; D moves to 19:30. The join's second interim (c8eacf0): `lh-rj-5` failed on one Slides
  test of 15 (fixed 722c50e), `lh-rj-4` and `lh-rj-6` open; the collector's hire by touch is accepted in code. The
  lamplighter reaches two posts by the horn (17:58, 18:45), not three: the castle is long and he is slow. Rule for
  build 2: no post stands that he cannot light by the horn, so two posts are drawn; the street grows with the realm in
  build 3. Correction to an earlier record: the stage lane has been in stage-3-interface since about 08:04; "fix pass
  2 at 926624e" was wrong. World-3: `lh-w3-2` ALL PASSED, head edd0976, not accepted. Quota 35 % of the week.
- **The join's round lh-rj-4 failed on two tests; two decisions (15.11.2026, 11:43).** On 7e4ad30: 878 of 879 unit tests and 8 of 9 play tests passed. (1) `StoryLanguagesTests`: six languages have 882 keys against English's 886, because the stage's new keys exist in English and German only. Build 2 ships English only, so key parity is asserted for the build's languages alone (one constant); for the others the test writes the missing keys to `i18n-missing.txt` in the round's results, the store pass's work list. Text budgets stay asserted for every text that exists. Nothing is translated now. (2) `FirstDayUITests.testFirstDay` fails at "the brazier site offers nothing": day 1's core flow, to be fixed first, with the cause named in join.md; no merged rule that moves T1 to T8 changes without a word to the director. Louis got three pictures of the stage lane's interface (hall audience, dawn report, the lantern moment cropped to the interface) and the correction that two lanterns burn by the horn.
- **Stage-3 is merged into the join; its critic's first look failed on the lady's portrait (15.11.2026, 11:54).** The join merged `claude/lh-stage` cb49c6a at 11:50 (06e3bfb; head 78a567d): the gold at the lord reads the town's shown gold (item 4), the old background names are aliases of the night glass (no parchment in the merged tree), the privacy choices are quiet words in the pause sheet; not yet proven by a round (lh-rj-6 and lh-rj-7 run on older commits). Decided: building a house up stays in build 2 by touch on the house (the door knocks); it is base game and not the old button; a house carries the hammer only while the treasury covers its price. The stage's critic look 1 gave 6.5 with one blocker (the lady still reads as the lord) and ten highs; the stage lane fixes them in its lane (the lady in deep wine facing the lord; one line that teaches the pause; pixel signs for every stock glyph; the strip's glyphs and tags), and the join restyles no card until that fix head is named.
- **The join's second interim (15.11.2026, 12:28).** Checked on the runner: lh-rj-7 ALL PASSED (11 play tests, the first day's fix proven); lh-rj-6's 11 play tests passed with the collector's hire by touch, its unit step failed only on the language test (fixed in 3060977). The title is merged (item 12, `claude/lh-join` 2348a1b); rounds lh-rj-8 (the merged tree with stage-3) and lh-rj-9 (title and the other lanes) are out. Decided: item 9 is cut for build 2 (seated strips, knock sprites, ties, cloth) except two parts, the town life's road numbers checked against the new world and the lamplighter at the Flame in the hall with existing sprites (cut line 17:00); the iOS launch screen becomes the night's darkest colour (TITLE.md section 1), the dithered reveal and the window flicker go to build 3. Quota at 12:28: 37 % of the week, 12 % of the Fable part.
- **World-3's critic, look 1 (15.11.2026, 12:37).** The world lane reported at 12:30 (`claude/lh-world` a0afd3f, gate lh-w3-4 ALL PASSED); the critic failed it at 6/10 on four blockers: the lord's lantern throws a lit box onto walls at dusk and night, the lord stands on the river at the east end, the ruined beacon's crown still reads as a handle, and the archers still stand as a picket row. Decided: the lantern box is fixed in the world lane (a picture-only spill, never the battle's light); the river end gets a timber landing with the skiff tied to it and the walk range stays; at most three archers drawn per defensive line; the built beacon's bowl is redrawn with the ruin. The join merges a0afd3f now as a first delta (the camera) and the fix head (wanted by 15:30) as a second. Kept: the town's back row, the night town, the hall door's light.
- **POLISH.md: three polish passes after build 2 (15.11.2026, 12:45).** Louis asked which small things lift the whole game and recalled the wind. Checked in `claude/lh-world`: the wind sways trees and plants, carries the chimney smoke and slants the rain; puddles exist; the windmill stands still, no flag, fire, cloth, grass, water or sound answers the wind. The rule: everything on screen answers the wind, the light or the lord. Pass 1 the wind seen and heard, pass 2 the world answers the lord, pass 3 light and depth (docs/POLISH.md). Nothing of it enters build 2 and no agent starts for it before build 2 is out; the order is settled in the review with Louis.
- **The bar: Kingdom Two Crowns and Yes, Your Grace: Snowfall (15.11.2026, 12:53).** Louis asked whether we reach their looks or better. Seen in seven store pictures and written into POLISH.md section 5: the first is calm (dark, muted, two or three strong colours, tiny figures, a water mirror that is its signature and that we do not take); the second builds its rooms in 3D with real shafts and shadows, warm against cold, dark shapes in front, a close camera. Honest standing: our critics give 6 and 6.5 of 10; the largest gap is motion. Taken in our own way: wet stone as our mirror, a palette rule per scene, warm against cold, the framed picture, the hall as the close shot, and a new pass 4 (the figures move well, proven by clips). The aim that is ours: the light as the picture's subject.
- **The two rains (15.11.2026, 12:57).** Louis' idea: normal rain on the town side, black rain or ash on the shadow side. Decided as ash, and the light decides which falls: water where the light reaches, slow cold ash where it does not, the change in the Throat; a flake in the lord's lantern light glows like an ember and is gone; wind from the shadow land carries a few flakes over the first wall; round a lit beacon (build 3) the rain is water again. Not black rain (it does not read at night). In POLISH.md under pass 1; after build 2. Open: the ash as a sign of a hard night.
- **The Ash Giant is the bar for every creature; the named people get a temper (15.11.2026, 13:07).** Louis: the new giant is the best-looking creature, "der komische ritter kackt rein", and people lack a character of their own (wild and calm children, dull and clever ones, the old with a stick, stout and thin); then: mostly the important characters, the soldiers may look basic. Read as the Lightless King (the only upright figure with a mantle and a pole; 64 px against the giant's 110). POLISH.md section 7: the giant's rule (no man's outline, one light that tells what it was, weight shown, an answer to the light) and the king redrawn after build 2 (tall and thin as a burnt wick, drifting, a stolen flame in the snuffer's bell, dead lanterns that fly home when he is hit; no Core rule). Section 8: a hand-set temper of two words per named person, shown in pace, idle habits, the greeting, the horn and the hall; Nib wild, Wren clever, Fen quiet, a fourth child the dreamer; bodies follow the realm's wealth; soldiers stay plain, the archers are pass 4's first cut. Pass 4 is now about two days. Nothing enters build 2.
- **Louis confirms: the odd knight is the Lightless King; the dread is in the coming (15.11.2026, 13:11).** "Ja den Ritter mit dem stab mein ich aber der riese ist so unheimlich … da scheisst man sich ein wenn man den kommen sieht". POLISH.md section 7: the giant's rule gets a fifth point (a boss is felt before it is seen whole) and a block "The giant's coming" (the ember heart first in the bank, a thud and a haptic tick per step, dust from the crenels, birds up, the archers step back). After build 2; picture, sound and haptics only.
- **The small ones: the horde is a creature of its own (15.11.2026, 13:19).** Louis: the small ones must look cool,
  and a small cannon-fodder kind must make every attack look thick, as in Kingdom. Checked in lh-world: the sootling
  is that kind (14 px, 8 hit points, 1 budget point; 25 on night 1, about 70 on night 20; the Lightless King calls
  six more every 15 s), but a wave leaves over ten seconds and so comes as a file, and both sootling bodies fail
  the giant's rule (A a mound, B a small man, the eye one pixel). Decided, POLISH.md section 7: a sootling is a
  snuffed wick with a thread of smoke that leans with the wind; three bodies, none a man's (crawler, loper,
  tumbler); they heap at a wall; cold points and threads in the bank before a wave. Picture only. Packs, a ragged
  pace and twice the heads at half the strength touch Core and wait for build 3's walls' tuning. The small ones
  come before the king's redraw; pass 4 grows to about three days. Nothing enters build 2. Never Kingdom's
  creatures (no mask, no coin thief, no portal).
- **The join's second interim: the merged game holds (15.11.2026, 13:34).** `claude/lh-join` 7f79c9d, not green: lh-rj-8 (unit 902 passed; UI 16 of 17, the taxes test reached the horn too early) and lh-rj-9 (UI 10 of 11, the title never uncovered by itself) each failed one test; both fixes ride on lh-rj-11. Seen by the director, upright, nine frames of the merged tree: world-3's world carries the stage's interface with nothing broken. Decisions: the noble's coach stays at the postern steps (its horses are a build 3 picture); the collector is Saul Tolliver in the code too (the merged tree still said Saul Bracken in 17 files), and his offer loses the doubled name; the title is judged on lh-rj-11's frames (the lit state of the broken round is five hard rings, a target). A trap: the runner's raw shots keep the EXIF orientation tag 8 after `sips -r 270`, so a turned file can show on its side; `ci-out/director/stripexif.py` drops the tag. Louis got two frames of the merged game (the knock at dusk, the count at the farmer).
- **The join's third interim: the first green round, and a correction (15.11.2026, 14:22).** lh-rj-11 is `ALL PASSED` on 47004d9 (unit 902, 15 UI tests, counted by the director); `claude/lh-join` stands at ffa76e3 (Saul Tolliver everywhere, no file with the old name), the title's lettering fix e6fe9bd after it. **Correction of the bullet of 13:34:** lh-rj-8, lh-rj-9 and lh-rj-11 ran on heads before the merge of world-3 (b22a058), so the merged frames seen so far show world-2 under the stage's interface, not world-3; lh-rj-12 is the first round with world-3 in it. Decisions: the world's fix head f4d9689 (lh-w3f1-2 `ALL PASSED`) is merged now as the second delta, without waiting for the critic's second look; the stage's head is merged the moment lh-s3f1-4 passes (three stage gate rounds failed on one UI test each, so its fix head slips from 14:30 to about 15:15); `LookGoldenTests` stays print-only until a world head is accepted. The title: the picture holds for build 2; still wanted are frames of the loading and the half-uncovered picture (a hold argument under DEBUG), the proof that all letters light, and "Touch to begin". The collector's bubble covered its slip; the join lifts the bubble. Picture notes for after build 2: the lord beside the lantern on the title reads as a lump at phone size; Saul's coat is close in value to the cottage wall; the unlit street lantern reads as a dark ball on a stick by day.
- **The world's fix round accepted; the stage's fourth gate failed on its walk; a sweep round died at the runner's limit (15.11.2026, 15:11).**
  - **World.** Fix round 1 of world-3 is reported: head df67321, lh-w3f1-3 `ALL PASSED` on dfec6bc (checked: unit 476, UI 13; df67321 is docs only). I looked at eleven sweep frames and five close crops: the critic's four blockers are answered (no lantern box, a timber landing at the river, a squat bowl and a moon band on the ruin, three archers a line). Accepted from my look for build 2; the join merges df67321 and pins `LookGoldenTests` when the critic's second look passes. Five picture notes go to the list after build 2 (the bank's eyes at the beacon's top, the buttress, the postern's night view, the skiff, the gate tower's pool edge).
  - **Stage.** lh-s3f1-4 on 79af3cd: `FAILED: 1` (unit 494, UI 12 passed, FirstDay failed). Two causes: a float on a 44 pt target (43.99999999999997) and no lantern moment on a touch on the lord after the brazier's order. The stage fixes it and proves it in one short round (no fifth full gate); if the game swallows the touch, the game is fixed, not the test. The join does not wait: it merges origin's 1c24a12 now (the Burgherrin's portrait, the ten highs) and the stage's next head when it is pushed.
  - **Join.** lh-rj-12 on ffa76e3: `FAILED: 1` (unit 923, UI 16 passed; FirstDay failed on the same float only). The join fixed it (f585596) and sent lh-rj-13 at 15:06.
  - **The runner's limit.** lh-rj-10 (six sweep classes in one step) was cancelled after 120 minutes and published nothing. The world's three classes pass in 29 minutes, so LightProbe, Probe or SweepProof hangs in the merged game. The join sends the world's three as one round and the other three alone or not at all for D.
  - **Lesson.** A round's state can be read without a key: `curl -s "https://api.github.com/repos/louisralfi-maker/spiele-welle/actions/runs?per_page=14"` (60 calls an hour). Look there before waiting more than an hour on a round. A job cancelled at the limit publishes no results.
- **The critic's second look on the world fails; my acceptance was too early (15.11.2026, 15:13).**
  - The look landed at 15:08: 7/10, two blockers. The Throat's new buttress (added in fix round 1) is a cobalt cut-out with a cream cut line at noon. The ruined beacon still reads as a square chimney with a pot at night.
  - At 15:11 I had accepted the head from dusk and night frames. I had not looked at the buttress at noon, and I had passed the ruin on its bowl and moon band alone. Lesson: before accepting a head, look at every changed thing at noon, dusk and night, and at phone size.
  - Fix round 2 is small and timed: 60 minutes of work, one gate round, the third look is the last. One repaint for the buttress, or it comes out for build 2. The ruin gets the most care. Highs H1, H3, H4, H2, H5 only if they take minutes; H6, H7, H8 and the small ones wait until after build 2.
  - The join merges df67321 now, sends the world's sweep round under the new interface, takes the third delta when it is pushed, and pins `LookGoldenTests` only on my note.
- **The title is proven in the merged game; two faults from my own look; the stage's touch fault was in the game (15.11.2026, 15:26).**
  - **Rounds.** lh-rj-13 `ALL PASSED` on f585596 (TitleUITests 2 of 2). The join's head 9e23de9 holds the world's df67321 and the stage's 1c24a12. lh-rj-14 (the six classes on f585596), lh-rj-15 (round A: the world's three sweep classes on 9e23de9) and the stage's lh-s3f1-5 (on 7c397e5) are running.
  - **The title.** Launch colour, the lantern catching, the reveal, all eleven letters lit and "Touch to begin" are in the game. Sent to Louis as promised.
    - Fault 1: the reveal's ellipse ends at R 260 and leaves a dark wedge in the bottom corners (the corner needs 282). The join fixes it in `TitleView.swift`.
    - Fault 2: the lord on the keep reads as a brown lump at phone size. One Opus agent redraws him on `claude/lh-title` (art only, 40 minutes, report `title-lord.md`); the join merges the delta.
    - After build 2 unless minutes are left: the reveal's dithered edge (00b shows a hard ellipse) and the windows' flicker.
  - **The stage.** FirstDay's "no realm strip" was a fault in the game: a touch on the lord standing on a site he had ordered opened the site's card. 7c397e5 lets the lord win on his body unless the finger is 3 px nearer the thing. Its 44 pt checks at 43.5 are too loose; the lane and the join round to the hundredth.
  - **The gate.** The join sends its gate on the head that holds the stage's next delta and the title's corner fix, at 16:30 at the latest.
  - **Quota:** 46 % of the week, 17 % of the Fable part.
- **The title's lord is redrawn and in the merged game; the dark corners are fixed in code (15.11.2026, 15:35).**
  - The title painter (Opus) redrew the lord on `claude/lh-title` at 1a56dc7: a standing man, 9 x 16, feet at (275, 88), hair, three skin pixels, the teal cloak with a warm rim, legs behind the merlons; his hand lantern goes from the hip to above his head in four frames (lantern rows 11, 7, 3, 1; were 4, 3, 1, 1).
  - My look at the close crops and the phone-size picture: he reads as a man beside the great lantern. Weak: the hand lantern is pale yellow on a gold sky and does not read at phone size in frame 0. That goes into pass 4's picture notes (after build 2), not into today.
  - The join merged it within a minute (59030d5) and I checked the merge: the eight files in `Resources/Title/` are identical to the lane's `art/title/`, `lordLanternRow` is `[11, 7, 3, 1]`.
  - The join's own fixes since 15:26: the title drops the reveal's mask when the reveal ends (56ea21f); the 44 pt checks measure to the hundredth in Audience, Hall and Lord (622244c).
  - My note to the join (15:35): `revealTo` 260 -> 300, so the ellipse passes the corners (282 from the flame) by itself and nothing pops when the mask drops; one Title round now, frame 00d to the desk. That frame, not the painter's proof, is the picture Louis gets.
  - Lesson: a lane that keeps its art outside `Resources/` needs the copy named in the merge note. The join did it unasked this time; say it in the brief next time.
  - Running at 15:35: lh-s3f1-5 (stage), lh-rj-14 and lh-rj-15 (join), the world's fix round 2 (uncommitted work on the beacon, the castle front and the clouds).
- **The stage's fix round 1 is green; the lady's portrait is closed from my side (15.11.2026, 15:55).**
  - Round lh-s3f1-5 on 7c397e5: `ALL PASSED`, checked by me (build, the unit tests, 13 UI tests in Touch, FirstDay, Hall, Audience, Lord, Polish, Look2). Head `claude/lh-stage` 9c37df8 (docs on top), report `ci-out/director/stage-3-interface-fix1.md`.
  - My look at 91, 97, 157b, 162 and a close crop of the portraits: the lady is her own person (braid crown, wine gown, turned to the lord); the reaction as a face with +1, the hint on glass, the strip's tags and the gear's disc are right.
  - For pass 4 after build 2: portrait finesse (the lord reads young and soft, the lady's jaw is heavy).
  - The lane did not read my 15:26 note before it ended: its 44 pt checks still allow 43.5. The join already carries the checks to the hundredth (622244c) and keeps them; the one assertion for the touch rule goes to the join too.
  - Orders: the join merges 9c37df8 now and sends its gate on the merged head at once, with the Title class folded in (no Title round of its own). The stage's critic takes its second look; a fix round 2 only on a blocker, 60 minutes, one gate.
  - The world's fix round 2: two unbuilt commits (db5b8d9 the buttress and the critic's list, 1001351 the cubes at the Throat's end), round lh-w3f2-1 sent 15:40.
  - Louis got the name entry frame (91) at 15:55: the lady was his own complaint.
- **The critic's second look on the stage: 7.5/10, no blocker, five highs; a timed fix round 2 runs on all five (15.11.2026, 16:06).**
  - The critic judged lh-s3f1-5 (`stage-3-interface-critic2.md`). I looked at 163's crop, 42 and 96 myself and agree.
  - The five highs, all met in the first ten minutes:
    - Three glyphs say the wrong thing: the horn reads as a key, play as a horn, the flame as a fist, the breach tag as paper.
    - `SeparatedText` drops the " · " at a line break, so "room on the walls for 1 more / guards 2" reads as one sentence.
    - The audience plaques stand 5 to 7 pt from the screen's edge, in the home bar's zone.
    - The lord's portrait is under the lady's new bar (a broad band across the brow, a boy's face).
    - On day 1 the call's strip and the first hint slip stack at the top centre.
  - My decisions for fix round 2 (replacing "only on a blocker" in my 15:55 note):
    - 70 minutes of work, then one gate round in lh-s3f1-5's shape. The critic's look 3 is the last.
    - The order: glyphs, plaques, line breaks, the day-1 top centre, the lord's portrait. What the time does not reach goes on the list for after build 2.
    - Glyphs stay one colour. A glyph that does not name itself at 14 pt goes, and the label stands in words only. The horn is on its third try.
    - Day 1: the call's strip waits until the hint slip has gone. The hint stays at the top centre, because a slip with a tail to the lord would say "touch the lord".
    - The barracks' head: "Archers 3 · Guards 2", then "Room on the walls for 1 more." on its own line.
  - The join merges the delta when origin moves and gives it one short round. It does not hold the gate or D for it.
  - State at 16:04: lh-w3f2-1, lh-rj-14 and lh-rj-15 run. The join's gate on the merged head (8116e03) is not sent yet.
