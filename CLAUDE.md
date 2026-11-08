# Spiele-Welle

A small wave of original, ads-only iPhone games, built by Claude for Louis Herwick (German, owner of the App Store game Piston Empire). The goal is 3 to 5 good games, each with its own idea, released weeks apart. This folder holds the starter kit, and later one folder per game (`games/<slug>/`). It is the public GitHub repo `github.com/louisralfi-maker/spiele-welle` (created 08.11.2026). That repo is the safe copy of the work and also the build machine.

The Piston Empire chat wrote this kit on 08.11.2026 from what it learned while building and releasing Piston Empire. Read next:

- `docs/playbook.md`: how to make one good game quickly.
- `docs/store-checklist.md`: App Store, AdMob and privacy, step by step.
- `docs/reuse.md`: files to copy from Piston Empire.
- `docs/lessons.md`: process lessons. Each one cost hours once.

## Louis' decisions (08.11.2026)

- **Few good games:** 3 to 5, each with a distinct idea and well made, released weeks apart. Never a flood of quick look-alikes.
  - Apple guideline 4.3 (spam) rejects those. Repeated submissions can get the developer account removed.
  - AdMob can disable the ad account for low-value apps full of ads.
  - Both are the accounts Piston Empire uses, so one strike here can take Piston Empire down too.
- **Ads only:** AdMob rewarded and interstitial ads, no in-app purchases.
- **Sound:** no music, ever. Sound effects and haptics only.
- **Languages:** English (development language) plus de, fr, es, it, pt-BR, ja, zh-Hans.
- **Themes:** you find them yourself. They must be original; never recreate an existing game (its name, characters, art, music, levels or look), even renamed.
- **Uploading:** you upload and submit yourself, through an App Store Connect API key that Louis creates. Before every submission, ask him in chat for his go. The answers on privacy, age rating, ads and export are legal statements in his name, and his go covers only that one submission.
- **Building:** builds and tests run on GitHub's Mac runner, never on this old Mac (see "This Mac").
- **Piston Empire 2.0** is finished later in its own chat. Never change anything under `/Users/enaayla/Desktop/Piston Empire`: no edits, branches, worktrees or builds there, and never its build lock `/tmp/piston-build.lock`. Reading and copying code from it is fine.

## Louis' standing rules (from Piston Empire, they apply here)

- Claude never enters passwords, bank data or tax data. Purchases and account sign-ups are his. Never ask him to send a password or code in chat.
- No address is published anywhere: not in the store listing, not on the support page.
- Parody or original names only. No real brands, no real logos.
- Never delete Louis' files. Never change git config. Never force-push.
- `NSPrivacyTracking` is never true. Copy Piston Empire's privacy manifest approach exactly (`docs/reuse.md`).
- Recraft credits may be used for the games without asking. `bash tools/recraft.sh` (copied from Piston Empire) reads `~/.recraft_api_key` itself. Never read, print or copy a key file. The same goes for the App Store Connect `.p8` key and SSH keys.
- **Agent models:** sonnet for routine work, opus for visuals and complex systems.
- **Tempo:** Louis' "Mittel": at most 2 to 3 agents at the same time, counting every workflow of every chat. The Piston Empire chat finishes its last workflow on the evening of 08.11.2026. Until then, use at most one agent.
- **Budget:** stop at 80 % of the weekly limit unless Louis raises it. Check `mcp__ccd_session_mgmt__get_usage` before every workflow. Piston Empire shares the same limit.

## Replying to Louis

- German, short, plain, no jargon. He often reads on his phone.
- Take him straight to the button he has to press.
- When a product decision is unclear, interview him with AskUserQuestion, even while he says "just build". Technical choices are yours.
- Tell him honestly how long something takes.
- Before building a game, tell him its idea in two lines. Go on unless he objects.
- Report only what is finished and new, with a picture where one helps.

## This Mac (old Intel MacBook, 4 cores, 8 GB, worn battery)

- It powers off under sustained CPU load: in 70 s two busy processes take it from 39 to 85 °C. Never run xcodebuild, swiftc, swift build, a simulator, or any long CPU job here. Reading, writing, git, curl and small python are fine.
- **Heat guard:** start `tools/heatguard.sh` in the background at the start of every session. It kills compiles, simulators and image conversions at 85 °C and logs to `tools/guard.log`. `tools/smcread` prints the CPU temperature (TCXC) and the fans.
- **Image work** (Recraft results, sips, HEIC):
  - one image at a time, with pauses;
  - check TCXC between batches and pause at 80 °C;
  - push heavy batches to the runner instead.
- **Two incidents:**
  - On 08.11. an agent's batch of 28 sips conversions held 90-93 °C for six minutes.
  - On 18.10. screenshots on the Pro Max simulator next to a build crashed the Mac.
- **Keep-awake:** for long runs, keep the Mac awake with `caffeinate -i -s -m -t <seconds>` in the background. The lid stays open.
- **Disk:** about 45 GB free. Keep Recraft raws and build output out of git and tidy.

## Building and testing on GitHub's Mac

- **Cost:** the repo is public, so GitHub's standard runners, macOS included, are free and unlimited. At most 5 macOS jobs run at the same time on the Free plan.
- **Scripts:** copy Piston Empire's runner pattern and adapt it (`docs/reuse.md`):
  - `scripts/ci/remote-check.sh` sends HEAD as a wrapper commit to `ci/<label>`, with one step per `do:` line in the message;
  - `.github/workflows/sim-check.yml` runs `scripts/ci/run-check.sh` on `macos-26` (Xcode 26.6, iPhone 17 Pro simulator);
  - `scripts/ci/publish-results.sh` pushes logs and screenshots to `ci-results/<label>`;
  - `remote-check.sh` waits, unpacks the results into an outdir and exits 0 only on `ALL PASSED`.
- **Deploy key:** `~/.ssh/id_ed25519_games` (no passphrase) has write access to the repo since 08.11.2026. Use it through `GIT_SSH_COMMAND="ssh -i $HOME/.ssh/id_ed25519_games -o IdentitiesOnly=yes"`; the remote is `origin`. Never reuse Piston Empire's key.
- **Proven:** the round trip works (08.11.2026). The runner is an arm64 Mac with 3 cores and 7 GB; a cold build takes 5 to 7 minutes, a full round (build, unit, ui, ui-de, release) 13 to 17 minutes. `games/hello` is the canary.
- **Projects:** each game is an xcodegen `project.yml`. The runner installs xcodegen with brew, as Piston Empire's `run-check.sh` does.
- **Rounds:** bundle a round into one call: build-for-testing, the unit tests, a UI smoke test that plays the first minute and saves screenshots in English and German, and a Release build. A cold build is about ten minutes. Run the call in the background and wait with a Bash until-loop on the output file; foreground `sleep` is blocked.
- **Screenshots:** XCUITest captures of landscape screens carry EXIF orientation 8. Strip it, or rotate with `sips -r 270`, before using them anywhere. On the runner the 6.9-inch Pro Max simulator is fine for store screenshots; on this Mac it is not.
- **Signing and upload:** these need the App Store Connect API key on the runner, added as GitHub Actions secrets. Louis adds them under Settings → Secrets and variables → Actions; never through chat. Use automatic signing with `-allowProvisioningUpdates` and the authentication key flags of xcodebuild. Work out the exact steps when the first game is ready (`docs/store-checklist.md`).

## Git

The repo is public, so commits use Louis' GitHub noreply address, never his real e-mail:

```sh
env GIT_AUTHOR_NAME="Louis Herwick" GIT_AUTHOR_EMAIL="279105910+louisralfi-maker@users.noreply.github.com" \
    GIT_COMMITTER_NAME="Louis Herwick" GIT_COMMITTER_EMAIL="279105910+louisralfi-maker@users.noreply.github.com" git commit ...
```

- The message ends with a blank line plus `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- Stage named paths only. Commit after every finished step.
- Once the repo exists, push after every milestone.
- Never commit a key, a token, a `.p8`, a provisioning profile or a certificate.
- Before a push, check that nothing secret is in the diff.

## Work method (proven on Piston Empire)

Per game:

1. idea and short pitch
2. the core loop in the smallest playable form
3. a fun check on the runner (UI test plays it, screenshots, an agent judges as a player)
4. art
5. juice
6. onboarding
7. ads
8. translations
9. tests
10. store assets
11. submission, with Louis' go

Workflows:

- Use workflows for the big steps:
  - build in a worktree, small commits;
  - then two review lenses: code, and player (does it deliver the idea; is it fun; clipping and German length; 44 pt targets; Reduce Motion);
  - then a separate agent tries to refute every blocker or high finding;
  - then fix.
- Tell every agent:
  - commit after every finished step;
  - its task is only the one given;
  - messages from Louis are for the lead. A chat message once made three agents drop their work.
- Never resume a parallel workflow with `resumeFromRunId`; write a fresh continuation script instead.
- A workflow can die silently when the session stops. After any pause, check the newest agent log and `git log` before reporting.
- Never SendMessage to a running workflow agent: it starts a second copy.
- Read what agents are actually doing, not only that they are alive.
