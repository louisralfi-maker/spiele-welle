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
- **Tempo:** at most 2 to 3 agents at once (Louis' "Mittel"), unless he raises it.
  - Only one agent at a time may do image work on this Mac (heat; CLAUDE.md "This Mac").
  - The runner takes at most 5 macOS jobs at once.
- **Budget:**
  - Check `mcp__ccd_session_mgmt__get_usage` before every workflow, and stop at 80 % of the weekly limit.
  - The Fable quota is separate, but its use also counts toward the weekly limit.
  - Both free Fable resets were used on 10.11. Weekly usage on 14.11. at about 13:00 was 1 %; the next reset is 21.11. at 03:00 UTC.
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
