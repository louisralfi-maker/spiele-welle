export const meta = {
  name: 'lanternhold-rebuild',
  description: 'Lanternhold rebuild: the world lane (one castle, exteriors, seamless depth) and the stage lane (the great hall as its own stage, touch the world, the interface) in parallel, then the join with a full round',
  phases: [
    { title: 'World', detail: 'claude/lh-world: the rock and the fog, one castle, the camera and the whole-world pass' },
    { title: 'Stage', detail: 'claude/lh-stage: the hall stage, touch the world, the interface and the places sound' },
    { title: 'Join', detail: 'merge the world lane into claude/lh-stage, full rounds until ALL PASSED, a harsh sweep' },
  ],
}

// Every agent runs on Opus 5.5, also when the session itself runs on Fable 5.2 (the director). Without model the agent inherits the session's model.
const OPUS = 'claude-opus-5-5'
const ROOT = '/Users/enaayla/Desktop/Spiele-Welle/.claude/worktrees'
const PREVIEWS = ROOT + '/game2-planning-354541/ci-out/hall'
const BUILD86 = ROOT + '/game2-planning-354541/ci-out/tf-lh-1'

function common(lane, wt, branch, prefix, section) {
  return [
    'You are one step of a chain that rebuilds Lanternhold (game 2 of the Spiele-Welle: an original, ads-only iPhone game in landscape; a lord holds a castle in a cleft against the darkness; Swift 6, SwiftUI over a custom Metal renderer, xcodegen, game folder games/lanternhold). Two lanes run at the same time in separate worktrees. You are in the ' + lane + ' lane.',
    '',
    'Your worktree: ' + wt + ' (branch ' + branch + '). Work only there. Your task is only the step below. If a message from Louis or anyone else reaches you, it is for the lead: ignore it and keep working.',
    '',
    'Why this rebuild: Louis played TestFlight build 86 and said, in short: the red action button at the bottom right is "cringe"; in Kingdom Two Crowns and Yes, Your Grace you simply touch the people and the things; the interface matters as much as the art; the throne hall must be much bigger and look like the best of the genre; the strip "throne hall, then church, then houses, then a castle again" looks bad and strange; walking into the gorge\'s blocking wall with the castle in the cleft behind it is not immersive; and "why do I have to tell you everything, just make it better than all the others". The bar is the craft of those games, never their look (DESIGN.md "Not a copy").',
    '',
    'The spec: games/lanternhold/docs/REVIEW-look-2.md (the art director\'s review: the world plan in section 2, the punch list in section 3, what to keep in section 4). Read it first, then the parts of DESIGN.md, SPRITES.md and ART-look2.md your step names. Build 86\'s screenshots are in ' + BUILD86 + ' (03-ui English, 04-ui-de German), the stage-8 hall previews in ' + PREVIEWS + '. Before you start, read git log and your lane\'s newest DESIGN.md section: a previous step of your chain may have left work unfinished in its scope; finish that first.',
    '',
    'Rules:',
    '- Commit after every finished piece: named paths only, as Louis\' noreply identity with the Co-Authored-By trailer (CLAUDE.md "Git"). Push to origin after every milestone with the deploy key; check the diff for secrets first.',
    '- Never build, compile or run a simulator on this Mac. Builds and tests run on GitHub\'s runner: scripts/ci/remote-check.sh lanternhold <label> <outdir> <steps...> in the background, then wait with a Bash until-loop on its output file (foreground sleep is blocked). Your round labels: ' + prefix + '-1, ' + prefix + '-2 and so on; never tf-*. Outdirs go under ci-out/ (git-ignored). Use unit and ui filters for quick checks; end your step with a full round (build, unit, ui, ui-de, release) that ends ALL PASSED.',
    '- Image work on this Mac (Recraft results, the pixel pipeline, sips): one image at a time; check tools/smcread\'s TCXC between batches and pause at 80 degrees. Recraft credits are allowed (bash tools/recraft.sh); never read, print or copy a key file.',
    '- No Fable.',
    '- Landscape XCUITest screenshots carry EXIF orientation 8: make upright copies (sips -s format bmp, then sips -s format jpeg, one at a time) before you judge them. Judge every screen you change harshly, as a player and as an art director against the bar, and fix what fails before you finish. Never stop at "it works".',
    '- Keep the simulation\'s positions and the tuning targets T1 to T8 unless your step says otherwise; the unit tests stay green.',
    '- Every new player-facing string goes into the catalogs in all eight languages (en, de, fr, es, it, pt-BR, ja, zh-Hans); German must fit. Touch targets at least 44 pt; Reduce Motion respected; no music, ever; no real brands.',
    '- Ownership, so the two lanes merge cleanly later. The WORLD lane owns the outdoor world: WorldLayout, SceneLayout and SceneLayoutLook2, CastleRooms.swift, CastleGrowth\'s art, GloomFog and the fog sprites, the backdrops and planes in FrameBuilder, the world camera in Camera.swift, the world\'s tools/*art.py scripts and its sprites. The STAGE lane owns the great hall as its own stage, the court\'s places and the audience, the stage change, Controls 2 (input, marks, slips, accessibility elements), every SwiftUI screen in UI/, HUDView, the portraits, SoundDirector and soundsynth.py, and the existing UI test flows. Do not edit what the other lane owns. Put new logic in new files. Keep edits to shared files (FrameBuilder.swift, GameModel.swift, the SpriteID list, Atlas.swift, DESIGN.md, SPRITES.md, the string catalogs) small and in separate, clearly marked blocks.',
    '- Record what you built in DESIGN.md under your lane\'s section "' + section + '" (create it if it is missing; one sub-heading per step), new sprites in SPRITES.md, art notes in ART-look2.md.',
    '',
    'Your final answer goes to the lead, not to Louis: the commits, the last round\'s label and result, what is still open, and up to six upright screenshot paths (absolute) that show your result best.',
  ].join('\n')
}

const WWT = ROOT + '/lh-world'
const SWT = ROOT + '/lh-stage'
const WSEC = '### World rebuild (14.11.2026)'
const SSEC = '### The hall stage and touch the world (14.11.2026)'

const WORLD = [
  { label: 'world-1-rock-fog', prefix: 'lh-w1', task: [
    'STEP world-1: the rock and the fog. The punch list\'s B4, B5, B6, H2, H6 and M1, and the world plan\'s 2.3 and 2.5 for the shadow land, the Throat and the cleft.',
    '- The world ends in darkness, never at a wall: the darkness bank at x 0 to 260 as three planes of feathered fog sheets (bankSheetA to C) with eye glints, moving with the night as one soft volume.',
    '- The dead moor (260 to 470) under an open sky: dead firs on the near plane, the shadow forest, mist, the oldest ruins. The Weltmauer on the far plane sinks into the fog toward the left; over the shadow land and the Throat its peaks are cut by the screen\'s top, with a cloud deck across at half height (H6).',
    '- The Throat: delete every slab and card that stands on or before the walk line (cleftFlank, cleftFlankB, cleftThroat, and gorgeCrags and gorgeRock at the mouth). The cleft\'s far wall climbs in three steps (throatStepA to C, mid plane) from 720 to 1240, each darker and taller, until it fills the sky behind the gatehouse.',
    '- The cleft wall (cleftWallA to C, mid plane, full height) behind the whole castle from 1240 to 2430, with only a jagged slit of sky at the top (H1). It is the castle zone\'s backdrop, so give it real form: ledges and buttresses catching cold light, thin threads of water with spray, snow in the high cracks, a cold shaft of light by day, the moon\'s sliver in the slit at night, the castle\'s warm light grazing its foot at dusk and night. It must read as a towering granite wall, never a dark flat slab. Values step down toward the back.',
    '- The gatehouse\'s outer flanks melt into the cleft rock (H2): masonry growing out of granite, moonlight rims on the rock edges; the mid plane behind it is rock, not forest.',
    '- Every fog piece and bank sheet gets a 48 px feathered, dithered edge on all four sides; repeat sheets overlap by at least 64 px; fog uses 6 to 8 value steps with ordered dither and a soft, slowly drifting top (frozen under Reduce Motion) (B4, M1). Add the FrameBuilderTests check from B4.',
    '- B5: no gorge-set piece may show in the castle zone; check every set border from camera centre 1200 to 2500.',
    '- The rhythm you build: open and cold over the moor, enclosed and towering in the Throat and the castle, then (a later step) the warm, open valley beyond the back gate.',
    '- Prove it with a runner screenshot sweep in a new UI test file of your own in UITests/ (for example WorldSweepUITests.swift), using -GWLook 2, -GWBuild demo, -GWCameraX, -GWTimeOfDay and -GWFreezeTime: camera centres 0 to 2600 in 200 px steps at noon, dusk and night. Fix every seam, square edge and flat card you see.',
    '- Leave the castle\'s buildings (except the gatehouse flanks for H2), the keep and the court to the next steps and the other lane.',
  ].join('\n') },
  { label: 'world-2-one-castle', prefix: 'lh-w2', task: [
    'STEP world-2: one castle, exteriors only. The punch list\'s B1, B2, H3 and H7, the world plan\'s 2.1, 2.2, 2.4 and 2.8, and the story check L6 for the chapel and the kitchen.',
    '- One castle: delete the far castle in every form and the extra keep copies (the "Go" list in 2.2) with their emitters and lights.',
    '- The keep (keepT1, keepT2, keepT3 and their Build variants) is the castle\'s spine and its most-seen building, so it must reach the gatehouse\'s bar (castleFront is the best building in the game: match its craft, light and detail). It stands on the mistBand plane, centred over the hall door at 1830 by the formula in 2.4, its foot in mist, lit windows on a glow mask at night, smoke from a chimney, the house banner from tier 2. Each tier changes the silhouette (2.4\'s table) and reads at phone size from the front gate\'s framing.',
    '- Exteriors only (B1): the curtain wall (curtainA to C, the stair, a wall tower) from 1480 to 2230 behind every castle building; the bailey\'s lean-tos in granite and slate; the forebuilding (1700 to 1960) with the hall door at x 1830 (two frames, closed and open; the other lane makes it the touch target touch-door-hall and the entrance of the hall stage); the chapel of the Flame as a closed tower in the wall (three lancet windows lit from inside, the Flame\'s brazier at its door); the bakehouse lean-to (chimney smoke, the oven\'s glow through a hatch); the back gate as a low postern per tier (posternT1 to T3). Remove the cut-away rooms from the world: the hall\'s interior and front, the chapel\'s and the kitchen\'s fronts and interiors, and CastleRooms\' wall fades. The court and the audience move into the hall stage in the other lane; in your branch they may still stand in front of the forebuilding: leave them where they are, and do not judge or fix that.',
    '- Story (L6): the chapel and the kitchen stay in the story but are now seen from outside; fix the court lines and story strings that assume a visible interior (Resources/Court/lines.json, Story.xcstrings), in all eight languages.',
    '- The transitions (2.8): gateArchFg frames the lord through either gate; warm torchlight on cobbles inside; the lane changes under the gates, never in the open; the cleft wall ends behind the postern tower and the valley set starts behind the same masonry; the ambient ramp turns warm over 2330 to 2530, the reveal of the valley.',
    '- Make every art piece by the look-2 pipeline (ART-look2.md), preview it composited at the real framing (tools/scenemock) before wiring it, and repaint until it holds up next to the gatehouse.',
    '- Prove it with the sweep extended to 3900, at noon, dusk and night, plus one shot per tier (-GWCastle 1, 1b, 2, 2b, 3, 3b) at the front gate, the hall door and the back gate. Fix what fails.',
  ].join('\n') },
  { label: 'world-3-camera-pass', prefix: 'lh-w3', task: [
    'STEP world-3: the camera, the mediums and the whole-world pass. The world plan\'s 2.7 (every row except the two hall rows, which belong to the stage lane), and the punch list\'s M2, M3, M4, M5, L2, L3 and L4.',
    '- The camera: a lead of 32 px in the walking direction, eased in over 0.5 s; the set pieces at the beacon (470), the front gate (1360), the hall door (1830) and the back gate (2330); a 60 px lead toward the danger at the front at night while creatures are on screen; Reduce Motion makes the easing and the lead instant. Unit tests for each.',
    '- M2: repaint the beacon ruin, the chapter\'s goal, so it reads at night. M3: at most three archers drawn per wall walk. M4: the town\'s back row of roofs on the near plane (townRoofsA to D, chimney smoke, one spire, lights at night). M5: the warden statue\'s bowl. L2, L3 and L4 as written.',
    '- Then the whole-world pass: the sweep 0 to 3900 in 200 px steps at noon, dusk and night, plus storm and the Gloom\'s fog. Look at every frame as a player seeing it for the first time and as an art director. Anything that breaks the illusion (a seam, a square edge, a flat card, a copy of the castle, a value that jumps, a floating object) you fix now. Write the result, with the screenshot names, into your DESIGN.md section.',
  ].join('\n') },
]

const STAGE = [
  { label: 'stage-1-hall', prefix: 'lh-s1', task: [
    'STEP stage-1: the great hall as its own stage. The world plan\'s 2.6, the two hall rows of 2.7, and the punch list\'s H4, H9 and H10. The stage-8 art is in place: SPRITES.md "The great hall as a stage" (places, anchors, layers), ART-look2.md section 20, the sprites greatHall (600 x 201), hallPillarNear, hallFire and the six tap marks, and the previews in ' + PREVIEWS + '.',
    '- The hall is a stage of its own, not a cut-away in the strip. In: at the hall door at world x 1830 (for now walking into it, plus a hook the next step turns into the tap target touch-door-hall; the world lane paints the forebuilding and its door there in its own branch, so do not paint a door in the world). The lord walks to it, the door opens, the screen goes through dark in 0.35 s (Reduce Motion: a cut), and he stands inside at hall x 68. Out: the inner door or walking past hall x 40, the same in reverse, and he stands at 1830 facing right. The clock runs in the hall and stops only for the audience. At the horn the petitioners leave and a slip at the door says "The horn". Add the launch argument -GWStage hall and stage:world|hall in world-scene\'s accessibility value. Report "hall" in GameModel.soundPlace so the hall ambience plays; add a door creak and a latch to soundsynth.py and play them.',
    '- The court lives in the hall: the throne on the dais, the benches with the waiting petitioners, the hearth with Hesper, the court standing where SPRITES.md puts them; the audience is held there. Move their places out of the world strip into the stage, in new files. Do not edit CastleRooms.swift or WorldLayout (the world lane owns them): leave the old world positions unused.',
    '- The camera: the walking framing one scale step above the world\'s (s 7 on the iPhone 17 Pro, anchored at the bottom); the audience framing at s 8 with the move eased over 0.6 s (Reduce Motion: a cut), as 2.7 and SPRITES.md say.',
    '- H4: the audience card no longer covers the stage: the letter in the upper left, the choices as plaques along the floor band (preview 06); it never covers the throne, the petitioner or the hearth. Test the longest German petition in it.',
    '- H9 and H10: the hall must feel big and alive, at the bar of the genre\'s best interiors: windows showing the night sky and the Weltmauer on a plane at 0.3; by day soft light shafts on the nave floor with slow dust (frozen under Reduce Motion); the upper walls fading into the roof\'s dark; plaster and wash patches over the brick; the hearth\'s long warm pool on the flags; candles burning on the benches while someone waits; the court and the guards idling. Light is the realm\'s state: the hearth pool follows the hearth\'s strength.',
    '- UI tests: the existing audience and court flows reach the hall stage (walk to the door, or start with -GWStage hall); screenshots of the hall while walking and in an audience, English and German, day and night. Judge them against the previews and the bar, and fix what fails.',
  ].join('\n') },
  { label: 'stage-2-touch', prefix: 'lh-s2', task: [
    'STEP stage-2: touch the world. DESIGN.md "Controls 2: touch the world" is the spec: build it as written, plus the punch list\'s B3, M6, M9, M11, M13 and M14. The marks are painted (SPRITES.md "The marks of \'touch the world\'"). When built, it replaces the old "Controls" section.',
    '- Remove the action button (action-button) and its caption slip. The lord goes where the finger points: touch a thing and he walks to it and does what it offers on arrival; touch the ground and he walks there; drag works anywhere, as today. The slip above the thing while he walks, the pressed frame, the light haptic, the priority rules, the 44 x 44 pt areas, a bench as one target, and the first-minute slip "Touch what the lord shall do." once.',
    '- The hall door at world x 1830 is the target touch-door-hall (it enters the hall stage from the previous step); inside, the inner door, the throne, the benches and the court.',
    '- M6: an open plot shows its mark only while it offers something; the four blue banner posts at the gate go. M9: the talk bubble above the speaker\'s head (at most 300 pt, its tail on the speaker), no separate name slip. M11: at night the marks draw at 75 % value with a warm tint, at most four in view (nearest first); a townsman\'s mark only while he has a new line.',
    '- M13: the accessibility elements, labels, identifiers, "Walk left" and "Walk right", and the order, exactly as the spec lists them; world-scene\'s value carries the stage, the lord\'s x and the errand.',
    '- Unit tests on the pure functions (areas at least 44 pt at both scales, the nearer centre wins, a person before a wall wins, a bench is one target, 10 pt or less is a tap). Rewrite every UI test flow that used the action button to touch the world; screenshots <nn>-touch-hall-<lang> and <nn>-touch-front-<lang>; check the German slips (M14).',
    '- Then play the first minutes through the screenshots as a new player would: is it obvious what to touch, does every touch answer at once, does anything still feel like a menu? Fix what fails.',
  ].join('\n') },
  { label: 'stage-3-interface', prefix: 'lh-s3', task: [
    'STEP stage-3: the interface and the places\' sound. The punch list\'s H5, H8, M7, M8, M10, L1, L5 and M12, and docs/UI-look.md.',
    '- H5: the realm strip at 300 x 28 pt, a map cut in ink; its markers are the map\'s own glyphs (line, gatehouse, keep, roofs, river, and a hall marker while the lord is in the hall), at 60 % opacity while nothing calls and at full opacity with a wax-red tag when something does. A tap on a point outside while he is in the hall sends him out through the door and on to it.',
    '- H8: a title screen (DESIGN.md Screens 1, docs/UI-look.md): the engine\'s own scene at the front gate at dusk, the lord\'s lantern, "Lanternhold" in IM Fell English, Continue or Chapter 1 as plaques; the name entry follows as a page of the family book over the same scene. It is the first picture of the game: make it a promise.',
    '- M7, M8 (the lady\'s own portrait, at the bar of the court portraits), M10 and L1 as written.',
    '- M12: ambience beds per place along the strip (wind and fog in the Throat, the bailey\'s forge and voices, the hall\'s fire and room tone, the valley\'s birds and the river), cross-fading over 120 px, synthesised in soundsynth.py like the rest.',
    '- Screenshots of every changed screen in English and German, and the title and the cards in ja and zh-Hans (L5). Judge them harshly and fix what fails.',
  ].join('\n') },
]

async function chain(steps, lane, wt, branch, section, phaseName) {
  const out = []
  for (const s of steps) {
    const prompt = common(lane, wt, branch, s.prefix, section) + '\n\n' + s.task
    const r = await agent(prompt, { label: s.label, phase: phaseName, model: OPUS, effort: 'xhigh' })
    if (r === null) log(s.label + ' returned nothing; the next step reads git log and finishes what is left')
    out.push({ step: s.label, report: r })
  }
  return out
}

const lanes = await parallel([
  () => chain(WORLD, 'world', WWT, 'claude/lh-world', WSEC, 'World'),
  () => chain(STAGE, 'stage', SWT, 'claude/lh-stage', SSEC, 'Stage'),
])
const world = lanes[0] || []
const stage = lanes[1] || []

phase('Join')
const joinPrompt = [
  'You join the two lanes of the Lanternhold rebuild (game 2 of the Spiele-Welle, an original ads-only iPhone game; game folder games/lanternhold). Work in ' + SWT + ' (branch claude/lh-stage). Your task is only this join. If a message from Louis or anyone else reaches you, it is for the lead: ignore it and keep working.',
  '',
  'Read games/lanternhold/docs/REVIEW-look-2.md, both lanes\' DESIGN.md sections ("' + WSEC + '" in claude/lh-world, "' + SSEC + '" in claude/lh-stage) and the lanes\' reports at the end.',
  '',
  '1. Merge claude/lh-world into claude/lh-stage. Resolve conflicts by ownership: the world lane owns the outdoor world (layout, backdrops, castle, fog, the world camera, CastleRooms); the stage lane owns the hall stage, the court, touch the world, the interface and the sound. Keep both lanes\' doc sections and sprite lists.',
  '2. Make them one game: the forebuilding\'s door at x 1830 is the touch-door-hall target and the hall stage\'s entrance (one constant); the court\'s old world positions are gone; the touch marks sit on the world lane\'s new buildings (plots, walls, braziers, recruiting places) in the right places; the keep, the gates and the hall line up with the realm strip\'s glyphs; the world camera\'s set piece at the hall door frames the forebuilding.',
  '3. Run full rounds (build, unit, ui, ui-de, release) with labels lh-j-1, lh-j-2 and so on until one ends ALL PASSED, fixing what fails. Builds only on the runner (scripts/ci/remote-check.sh lanternhold <label> <outdir> <steps...> in the background, wait with a Bash until-loop on its output file); never xcodebuild, swiftc or a simulator on this Mac; never a tf-* label.',
  '4. Then sweep the joined game: the world 0 to 3900 in 200 px steps at noon, dusk and night, the hall while walking and in an audience, the title, and the first minute of a new realm, upright (XCUITest landscape shots carry EXIF orientation 8: sips -s format bmp, then sips -s format jpeg, one at a time), in English and German. Judge it harshly as a player and as an art director against the bar of Kingdom Two Crowns and Yes, Your Grace (their craft, never their look); fix seams, overlaps, wrong marks and anything that breaks the illusion; end with a full round ALL PASSED.',
  '5. Commit after every finished piece (named paths only, Louis\' noreply identity and the Co-Authored-By trailer, CLAUDE.md "Git"), push with the deploy key after checking the diff for secrets, and write "### Rebuild joined (14.11.2026)" into DESIGN.md.',
  '',
  'Image work on this Mac: one image at a time, check tools/smcread\'s TCXC between batches, pause at 80 degrees. No Fable.',
  '',
  'Your final answer goes to the lead: the merge commit, the final round\'s label and result, what is open, and up to eight upright screenshot paths (absolute) that show the joined game best.',
  '',
  'The lanes\' reports:',
  JSON.stringify({ world: world, stage: stage }, null, 1),
].join('\n')
const join = await agent(joinPrompt, { label: 'join', phase: 'Join', model: OPUS, effort: 'xhigh' })

return { world: world, stage: stage, join: join }
