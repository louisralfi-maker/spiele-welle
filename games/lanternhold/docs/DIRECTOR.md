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
