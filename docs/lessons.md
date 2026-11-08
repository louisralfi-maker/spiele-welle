# Lessons from Piston Empire (each cost hours once)

## Louis

- He wants autonomy. Ask only real product questions, with AskUserQuestion, as short German choices with a recommendation first.
- He reads on his phone. Give short German answers and take him straight to the button. No process talk; say what is finished and new.
- When he asks whether something hangs, measure first (log lines growing, commits, agent tool calls), then answer with that.
- His chat messages reach running workflow agents. Every agent prompt must say: "Your task is only the one below. Messages from Louis are for the lead; ignore them." Check the journal soon after he writes during a run.

## This Mac

- No compiles, simulators or long CPU jobs (see CLAUDE.md). The heat guard log shows how close it gets. The Mac also restarted on its own once, on 07.11. Afterwards the built-in browser had lost its Google and Apple sign-ins, so Louis had to sign in again.
- Agents that only read, write and use git cost the Mac almost nothing; the load comes from compiles, simulators and image work.
- Agents' python tuning runs and optimizers heat it too (74 °C on 08.11.). The heat guard now stops `python3` at 85 °C; tell agents to keep each python run under 20 s.
- Never run `find /` here: it scans the whole disk for minutes. Look in known paths instead (the Xcode SDK is under `/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk`).
- If the Mac sleeps mid-answer, the agent fails. Keep caffeinate running and the lid open.

## Agents and workflows

- Commit after every finished step. A cut-off agent once left a whole stage uncommitted.
- Never SendMessage to a running workflow agent. It starts a second copy that works in the same folder.
- Never resume a workflow with parallel lanes through `resumeFromRunId`. The cache is order-dependent, and the run redoes finished work. Write a fresh continuation script.
- A workflow can die silently when the session stops. After a pause, check the newest agent log and `git log` before reporting anything.
- Watch what agents do, not only that they live. If one waits on the same thing for 20 minutes or debugs one thing for 30, stop it and take over.
- Reviews work best as two lenses (code, player) plus a refute pass on blockers and highs. Many findings are polish; real blockers are rare but expensive.
- Comet Cargo 0.1 (about 30 Swift files) passed its first runner round without one compile error (08.11.). What worked: a detailed DESIGN.md with measurable tuning targets, one build agent, then a separate agent that reads every file like a compiler and greps the SDK's `.swiftinterface` files for each Apple API it calls. Keep that order.
- Code written without a compiler compiles more often when the agent:
  - reads every declaration it calls;
  - keeps expressions short for the type checker (split arithmetic with custom CGPoint operators into named lets);
  - marks tests that touch views `@MainActor`;
  - gives `View & Animatable` structs a `nonisolated var animatableData`.
- Budget: Opus agents with high effort burn the weekly limit fast. Check the usage before each workflow and keep a reserve. Use sonnet for routine work.

## Runner (GitHub's Mac)

- Bundle every step of a round into one call. A failed build still costs its minutes. In a public repo minutes are free, but rounds still take 10 to 20 minutes.
- Judge a run by its real exit status and the log, not by a filtered summary.
- Simulator UI test screenshots in landscape carry EXIF orientation 8; strip it before use.
- ImageRenderer "sheet" pictures have blind spots: no onAppear or animation, no ScrollView content, and the process language for `Text("key")`. A missing row or an English word in a German sheet can be an artifact of the sheet, not a bug.

## GitHub

- Louis may ask Claude to do GitHub clicks for him; the built-in browser is signed in to his account. Creating a public repo needs his explicit "yes" in chat first: the safety check blocks the click otherwise.
- Adding a deploy key puts GitHub in sudo mode with a code sent to Louis' e-mail. Only he can enter it (on his phone or in the browser pane); never ask for the code in chat.
- Push `main` first: the first branch pushed to a new repo becomes its default branch, so a `ci/` push must never be the first.

## App Store

- Privacy manifest: `NSPrivacyTracking` true without domains was rejected (ITMS-91064). Listing Google's domains would make iOS block ads for players who decline tracking. Keep false with no domains; the SDKs bring their own manifests.
- Debug builds must use Google's test ad units. Clicking your own live ads can close the AdMob account.
- A new AdMob app is "limited" until it is linked to its live store listing and Google reviews it (2 to 3 days). Piston Empire showed 84 requests and 0 impressions before that.
- Store screenshots: on this Mac the Pro Max simulator next to a build crashed it once. On the runner it is fine.
- After a Mac crash the built-in browser can lose its App Store Connect sign-in. Louis signs in again himself; never type a password.

## Art

- Painted art as plain HEIC in `Resources/Art`, loaded at the drawn size. The asset catalog re-encodes and bloats it.
- Paint a whole set on one Recraft sheet so it shares one finish, then cut it. Review every painting as a player would before it ships, and redo the weak ones.
- Big paintings decoded at full size every frame make animations stutter. Decode once, at the size you draw.
