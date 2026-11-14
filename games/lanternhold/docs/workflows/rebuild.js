export const meta = {
  name: 'lanternhold-rebuild',
  description: 'Lanternhold rebuild: the world lane and the stage lane in parallel, every step gated by an independent art director with a fix round, then the join with a full round. All workers on Opus 5.5.',
  phases: [
    { title: 'World', detail: 'claude/lh-world: the rock and the fog, one castle, the camera and the whole-world pass; each step gated' },
    { title: 'Stage', detail: 'claude/lh-stage: the hall stage, touch the world, the interface and the places sound; each step gated' },
    { title: 'Digest', detail: 'a short digest of the game for the director' },
    { title: 'Join', detail: 'merge the world lane into claude/lh-stage, full rounds until ALL PASSED, a harsh sweep' },
  ],
}

// Every worker runs on Opus 5.5, also when the session itself runs on Fable 5.2 (the director). Without model the agent inherits the session's model.
const OPUS = 'claude-opus-5-5'
const SONNET = 'claude-sonnet-5-5'
const ROOT = '/Users/enaayla/Desktop/Spiele-Welle/.claude/worktrees'
const PLAN = ROOT + '/game2-planning-354541'
const PREVIEWS = PLAN + '/ci-out/hall'
const BUILD86 = PLAN + '/ci-out/tf-lh-1'
// The director's desk: the agents' reports, the critics' verdicts and the director's notes to each lane. Git-ignored, outside the lanes' branches.
const DIR = PLAN + '/ci-out/director'

function common(lane, wt, branch, prefix, section, label) {
  return [
    'You are one step of a chain that rebuilds Lanternhold (game 2 of the Spiele-Welle: an original, ads-only iPhone game in landscape; a lord holds a castle in a cleft against the darkness; Swift 6, SwiftUI over a custom Metal renderer, xcodegen, game folder games/lanternhold). Two lanes run at the same time in separate worktrees. You are in the ' + lane + ' lane.',
    '',
    'Your worktree: ' + wt + ' (branch ' + branch + '). Work only there. Your task is only the step below. If a message from Louis or anyone else reaches you, it is for the lead: ignore it and keep working.',
    '',
    'Why this rebuild: Louis played TestFlight build 86 and said, in short: the red action button at the bottom right is "cringe"; in Kingdom Two Crowns and Yes, Your Grace you simply touch the people and the things; the interface matters as much as the art; the throne hall must be much bigger and look like the best of the genre; the strip "throne hall, then church, then houses, then a castle again" looks bad and strange; walking into the gorge\'s blocking wall with the castle in the cleft behind it is not immersive; and "why do I have to tell you everything, just make it better than all the others". The bar is the craft of those games, never their look (DESIGN.md "Not a copy").',
    '',
    'The spec: games/lanternhold/docs/REVIEW-look-2.md (the art director\'s review: the world plan in section 2, the punch list in section 3, what to keep in section 4). Read it first, then the parts of DESIGN.md, SPRITES.md and ART-look2.md your step names. Build 86\'s screenshots are in ' + BUILD86 + ' (03-ui English, 04-ui-de German), the stage-8 hall previews in ' + PREVIEWS + '.',
    '',
    'Before you start, read in this order:',
    '- git log. The newest commits may hold a WIP snapshot of a paused agent\'s unfinished, unbuilt work, or a previous step\'s leftovers in its scope: look at it critically, keep what is good, and finish it first.',
    '- Your lane\'s newest DESIGN.md section.',
    '- The director\'s notes, ' + DIR + '/notes-' + lane + '.md, if the file exists. The director is the lead; the newest entry is at the bottom; where a note differs from this brief, the note wins.',
    '- The newest verdicts of the independent critic for your lane in ' + DIR + ' (files named *-critic*.md): blockers still open there are yours first.',
    '',
    'Rules:',
    '- Commit after every finished piece: named paths only, as Louis\' noreply identity with the Co-Authored-By trailer (CLAUDE.md "Git"). Push to origin after every milestone with the deploy key; check the diff for secrets first.',
    '- Never build, compile or run a simulator on this Mac. Builds and tests run on GitHub\'s runner: scripts/ci/remote-check.sh lanternhold <label> <outdir> <steps...> in the background, then wait with a Bash until-loop on its output file (foreground sleep is blocked). Your round labels: ' + prefix + '-1, ' + prefix + '-2 and so on (if a label already has a ci-results branch on origin, take the next free number); never tf-*. Outdirs go under ci-out/ (git-ignored). Use unit and ui filters for quick checks; end your step with a full round (build, unit, ui, ui-de, release) that ends ALL PASSED.',
    '- Image work on this Mac (Recraft results, the pixel pipeline, sips): one image at a time; check tools/smcread\'s TCXC between batches and pause at 80 degrees. Recraft credits are allowed (bash tools/recraft.sh); never read, print or copy a key file.',
    '- No Fable. If you start a helper agent, name its model: opus.',
    '- Landscape XCUITest screenshots carry EXIF orientation 8: make upright copies (sips -s format bmp, then sips -s format jpeg, one at a time) of every screenshot of your sweep, in one folder, before you judge them. Judge every screen you change harshly, as a player and as an art director against the bar, and fix what fails before you finish. Never stop at "it works". After you, an independent art director who owes you nothing looks at the same screenshots; what he finds comes back to this lane as a fix round.',
    '- Keep the simulation\'s positions and the tuning targets T1 to T8 unless your step says otherwise; the unit tests stay green.',
    '- Every new player-facing string goes into the catalogs in all eight languages (en, de, fr, es, it, pt-BR, ja, zh-Hans); German must fit. Touch targets at least 44 pt; Reduce Motion respected; no music, ever; no real brands.',
    '- Ownership, so the two lanes merge cleanly later. The WORLD lane owns the outdoor world: WorldLayout, SceneLayout and SceneLayoutLook2, CastleRooms.swift, CastleGrowth\'s art, GloomFog and the fog sprites, the backdrops and planes in FrameBuilder, the world camera in Camera.swift, the world\'s tools/*art.py scripts and its sprites. The STAGE lane owns the great hall as its own stage, the court\'s places and the audience, the stage change, Controls 2 (input, marks, slips, accessibility elements), every SwiftUI screen in UI/, HUDView, the portraits, SoundDirector and soundsynth.py, and the existing UI test flows. Do not edit what the other lane owns. Put new logic in new files. Keep edits to shared files (FrameBuilder.swift, GameModel.swift, the SpriteID list, Atlas.swift, DESIGN.md, SPRITES.md, the string catalogs) small and in separate, clearly marked blocks.',
    '- Record what you built in DESIGN.md under your lane\'s section "' + section + '" (create it if it is missing; one sub-heading per step), new sprites in SPRITES.md, art notes in ART-look2.md.',
    '',
    'Your final answer goes to the lead, not to Louis: the commits, the last round\'s label and result, what is still open, the absolute path of the folder with the upright screenshots of your last sweep, and up to six upright screenshot paths (absolute) that show your result best. As your last action, write the same report to ' + DIR + '/' + label + '.md (mkdir -p the folder).',
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
    '- The hall door is the promise of the hall (a director\'s point): its open frame shows the hall\'s warm light inside, and at dusk and night it throws a warm wedge of light onto the cobbles in front of it. Closed, a thin line of warm light under the door at night.',
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
    '- The hall is a stage of its own, not a cut-away in the strip. In: at the hall door at world x 1830 (for now walking into it, plus a hook the next step turns into the tap target touch-door-hall; the world lane paints the forebuilding and its door there in its own branch, so do not paint a door in the world). The lord walks to it, the door opens, the screen goes through dark in 0.35 s (Reduce Motion: a cut), and he stands inside at hall x 68. Out: the inner door or walking past hall x 40, the same in reverse, and he stands at 1830 facing right. The clock runs in the hall and stops only for the audience. At the horn the petitioners leave and a slip at the door says "The horn". Add the launch argument -GWStage hall and stage:world|hall in world-scene\'s accessibility value. Report "hall" in GameModel.soundPlace so the hall ambience plays; add a door creak and a latch to soundsynth.py and play them. Through the dark of the change the wind falls away and the hall\'s fire and room tone come up, so the ear arrives before the eye.',
    '- The court lives in the hall: the throne on the dais, the benches with the waiting petitioners, the hearth with Hesper, the court standing where SPRITES.md puts them; the audience is held there. Move their places out of the world strip into the stage, in new files. Do not edit CastleRooms.swift or WorldLayout (the world lane owns them): leave the old world positions unused.',
    '- The camera: the walking framing one scale step above the world\'s (s 7 on the iPhone 17 Pro, anchored at the bottom); the audience framing at s 8 with the move eased over 0.6 s (Reduce Motion: a cut), as 2.7 and SPRITES.md say.',
    '- H4: the audience card no longer covers the stage: the letter in the upper left, the choices as plaques along the floor band (preview 06); it never covers the throne, the petitioner or the hearth. Test the longest German petition in it.',
    '- H9 and H10: the hall must feel big and alive, at the bar of the genre\'s best interiors: windows showing the night sky and the Weltmauer on a plane at 0.3; by day soft light shafts on the nave floor with slow dust (frozen under Reduce Motion); the upper walls fading into the roof\'s dark; plaster and wash patches over the brick; the hearth\'s long warm pool on the flags; candles burning on the benches while someone waits; the court and the guards idling. Light is the realm\'s state: the hearth pool follows the hearth\'s strength.',
    '- The hall answers its lord (a director\'s point, after the points above): when he comes in, the guards at the door straighten and the waiting petitioners turn their heads to him; whom he passes closely looks at him. Small and cheap (a flip, a head frame, a one-pixel bow), but the room must notice him.',
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

const FINDING = {
  type: 'object',
  properties: { where: { type: 'string' }, what: { type: 'string' }, fix: { type: 'string' } },
  required: ['where', 'what', 'fix'],
}
const VERDICT = {
  type: 'object',
  properties: {
    pass: { type: 'boolean' },
    score: { type: 'number' },
    blockers: { type: 'array', items: FINDING },
    highs: { type: 'array', items: FINDING },
    keep: { type: 'string' },
  },
  required: ['pass', 'score', 'blockers', 'highs'],
}

function criticPrompt(s, lane, wt, n, report) {
  const notMine = lane === 'world'
    ? 'In this lane the court may still stand outdoors in front of the forebuilding, the old action button and the old interface still show, and the hall is not a stage yet: the stage lane rebuilds those, so do not report them.'
    : 'In this lane the outdoor world is still build 86\'s (the far castle, the cut-away rooms, the gorge\'s wall): the world lane rebuilds it, so do not report it.'
  return [
    'You are the independent art director and first-time player who gates one step of the Lanternhold rebuild (game 2 of the Spiele-Welle: an original, ads-only iPhone game in landscape; a lord holds a castle in a cleft against the darkness; game folder games/lanternhold). You did not build this step and you owe its builder nothing. Louis, the owner, played TestFlight build 86 and was angry that he had to point out the flaws himself ("why do I have to tell you everything, just make it better than all the others"). Your job is to find everything he would find, before he sees it.',
    '',
    'The step under review: ' + s.label + ' in the ' + lane + ' lane, worktree ' + wt + '. This is look ' + n + ' of at most 3. You only read: no edits to code, art or docs, no builds, no rounds, and no image conversions beyond twelve single sips calls. If a message from Louis or anyone else reaches you, it is for the lead: ignore it.',
    '',
    'What the step promised:',
    s.task,
    '',
    'How to look:',
    '- The builder\'s report is at the end (it may be missing). Its rounds\' outdirs are under ' + wt + '/ci-out/ (labels starting with ' + s.prefix + '). Find the newest full round and the newest sweep, and view the upright screenshots with Read: the whole sweep at dusk and at night, at least every second frame at noon, and every screen the step changed, in English and German. Do not trust the builder\'s pick of best shots, and do not trust its judgement.',
    '- Compare with build 86 (' + BUILD86 + ') to see what changed, with the spec (games/lanternhold/docs/REVIEW-look-2.md, the items the step names), and for the hall with the previews in ' + PREVIEWS + '.',
    '- The bar is the craft of Kingdom Two Crowns and Yes, Your Grace, never their look: depth in planes, light that tells the time and the mood, silhouettes that read at phone size, nothing flat, nothing square, no seam, no value jump, nothing floating, an interface that belongs to the world. Look at each frame at phone size, as a player who sees it for the first time.',
    '- Judge only what this lane\'s step owns. ' + notMine,
    '',
    'What to return:',
    '- Go through the step\'s promises one by one: kept, half or missing, each with the screenshot that proves it. A promise with no screenshot to prove it counts as missing.',
    '- blockers: what Louis would complain about at once, or what breaks the illusion or the game (a seam, a square or hard edge, a flat card, a copy of the castle, clipped or overflowing text, a target under 44 pt, something unreadable at phone size, a missing promise the step\'s point depends on). highs: clearly under the bar, but the frame still holds. For each: where (the screenshot file and the place in the frame), what, and the fix you would order, concretely.',
    '- score: 1 to 10 against the bar; 8 means you would show it to Louis proudly. pass is true only with no blocker and a score of 8 or more.',
    '- keep: what is good and must not be lost in the fixes.',
    '- Write the same verdict as readable text to ' + DIR + '/' + s.label + '-critic' + n + '.md (mkdir -p the folder), with the absolute paths of the three weakest and the three best frames.',
    '',
    'The builder\'s report:',
    report || '(missing: the builder returned nothing; look at git log and the newest outdirs)',
  ].join('\n')
}

function fixPrompt(s, lane, wt, branch, section, n, v) {
  return common(lane, wt, branch, s.prefix + 'f' + n, section, s.label + '-fix' + n) + '\n\n' + [
    'STEP ' + s.label + ', fix round ' + n + '. An independent art director looked at this step\'s result and did not pass it (score ' + v.score + ' of 10; 8 passes). Fix every blocker' + (n === 1 ? ' and every high' : ', and the highs as far as this round allows') + '. Where you are sure a finding is wrong, prove it with a screenshot instead of changing it. Do not start the next step\'s scope. End with a full round ALL PASSED and the same sweep as the step, upright, so the next look has fresh screenshots.',
    '',
    'What to keep: ' + (v.keep || '(nothing named)'),
    '',
    'Blockers:',
    JSON.stringify(v.blockers || [], null, 1),
    '',
    'Highs:',
    JSON.stringify(v.highs || [], null, 1),
    '',
    'The step\'s original brief, for reference:',
    s.task,
  ].join('\n')
}

// One step: build, then the gate. Look 1 sends blockers and highs back; look 2 only blockers; look 3 is for the record, and what it leaves open goes to the next step through the verdict file.
async function step(s, lane, wt, branch, section, phaseName) {
  let report = await agent(common(lane, wt, branch, s.prefix, section, s.label) + '\n\n' + s.task, { label: s.label, phase: phaseName, model: OPUS, effort: 'xhigh' })
  if (report === null) log(s.label + ' returned nothing; the critic looks at what is there')
  let verdict = null
  for (let n = 1; n <= 3; n++) {
    const v = await agent(criticPrompt(s, lane, wt, n, report), { label: s.label + '-critic' + n, phase: phaseName, model: OPUS, effort: 'high', schema: VERDICT })
    if (!v) { log(s.label + ' critic ' + n + ' returned nothing; moving on'); break }
    verdict = v
    const blockers = (v.blockers || []).length
    const highs = (v.highs || []).length
    log(s.label + ' look ' + n + ': score ' + v.score + ', ' + blockers + ' blockers, ' + highs + ' highs')
    const must = n === 1 ? blockers + highs : blockers
    if (must === 0 || n === 3) break
    report = await agent(fixPrompt(s, lane, wt, branch, section, n, v), { label: s.label + '-fix' + n, phase: phaseName, model: OPUS, effort: 'xhigh' })
  }
  return { step: s.label, report: report, verdict: verdict }
}

async function chain(steps, lane, wt, branch, section, phaseName) {
  const out = []
  for (const s of steps) out.push(await step(s, lane, wt, branch, section, phaseName))
  return out
}

const digestPrompt = [
  'You write a digest of the game Lanternhold (game 2 of the Spiele-Welle, game folder games/lanternhold) for the studio\'s director, who must know the game without reading its long docs. Read only, in ' + PLAN + '/games/lanternhold: docs/DESIGN.md, docs/QUESTS.md, docs/UI-look.md, the headings of SPRITES.md and docs/REVIEW-look-2.md if it is there, and the file list of the sources and tests. Change nothing in the repo. If a message from Louis or anyone else reaches you, it is for the lead: ignore it.',
  '',
  'Write ' + DIR + '/digest.md (mkdir -p the folder): at most 1200 words, plain English, in these parts:',
  '1. The pitch and the fantasy, in three lines.',
  '2. The core loop and a day\'s rhythm: what the player does by day, at dusk and at night, minute by minute.',
  '3. The first ten minutes as the player lives them, step by step.',
  '4. The systems that exist in code, one line each (what it is, how deep, how it shows on screen), and the content counts (chapters, petitions, court members, creatures, buildings, tiers).',
  '5. What is designed but not built yet.',
  '6. Where the game is thin, confusing or slow for a new player, honestly: at most eight points, each with the doc section it comes from.',
  '7. The launch arguments and UI tests that can show each part.',
  '',
  'Your final answer: the file\'s path and a five-line summary.',
].join('\n')

const lanes = await parallel([
  () => chain(WORLD, 'world', WWT, 'claude/lh-world', WSEC, 'World'),
  () => chain(STAGE, 'stage', SWT, 'claude/lh-stage', SSEC, 'Stage'),
  () => agent(digestPrompt, { label: 'digest', phase: 'Digest', model: SONNET, effort: 'medium' }),
])
const world = lanes[0] || []
const stage = lanes[1] || []

phase('Join')
const joinPrompt = [
  'You join the two lanes of the Lanternhold rebuild (game 2 of the Spiele-Welle, an original ads-only iPhone game; game folder games/lanternhold). Work in ' + SWT + ' (branch claude/lh-stage). Your task is only this join. If a message from Louis or anyone else reaches you, it is for the lead: ignore it and keep working.',
  '',
  'Read games/lanternhold/docs/REVIEW-look-2.md, both lanes\' DESIGN.md sections ("' + WSEC + '" in claude/lh-world, "' + SSEC + '" in claude/lh-stage), the director\'s notes in ' + DIR + ' (notes-world.md, notes-stage.md and notes-join.md, where they exist; the director is the lead and a note wins over this brief), the newest critic verdicts there (*-critic*.md: what they leave open is yours too), and the lanes\' reports at the end.',
  '',
  '1. Merge claude/lh-world into claude/lh-stage. Resolve conflicts by ownership: the world lane owns the outdoor world (layout, backdrops, castle, fog, the world camera, CastleRooms); the stage lane owns the hall stage, the court, touch the world, the interface and the sound. Keep both lanes\' doc sections and sprite lists.',
  '2. Make them one game: the forebuilding\'s door at x 1830 is the touch-door-hall target and the hall stage\'s entrance (one constant); the court\'s old world positions are gone; the touch marks sit on the world lane\'s new buildings (plots, walls, braziers, recruiting places) in the right places; the keep, the gates and the hall line up with the realm strip\'s glyphs; the world camera\'s set piece at the hall door frames the forebuilding.',
  '3. Run full rounds (build, unit, ui, ui-de, release) with labels lh-j-1, lh-j-2 and so on until one ends ALL PASSED, fixing what fails. Builds only on the runner (scripts/ci/remote-check.sh lanternhold <label> <outdir> <steps...> in the background, wait with a Bash until-loop on its output file); never xcodebuild, swiftc or a simulator on this Mac; never a tf-* label.',
  '4. Then sweep the joined game: the world 0 to 3900 in 200 px steps at noon, dusk and night, the hall while walking and in an audience, the title, and the first minute of a new realm, upright (XCUITest landscape shots carry EXIF orientation 8: sips -s format bmp, then sips -s format jpeg, one at a time), in English and German. Judge it harshly as a player and as an art director against the bar of Kingdom Two Crowns and Yes, Your Grace (their craft, never their look); fix seams, overlaps, wrong marks and anything that breaks the illusion; end with a full round ALL PASSED.',
  '5. Commit after every finished piece (named paths only, Louis\' noreply identity and the Co-Authored-By trailer, CLAUDE.md "Git"), push with the deploy key after checking the diff for secrets, and write "### Rebuild joined (14.11.2026)" into DESIGN.md.',
  '',
  'Image work on this Mac: one image at a time, check tools/smcread\'s TCXC between batches, pause at 80 degrees. No Fable; a helper agent runs on opus.',
  '',
  'Your final answer goes to the lead: the merge commit, the final round\'s label and result, what is open, the folder with the upright sweep, and up to eight upright screenshot paths (absolute) that show the joined game best. As your last action, write the same report to ' + DIR + '/join.md.',
  '',
  'The lanes\' reports and last verdicts:',
  JSON.stringify({ world: world, stage: stage }, null, 1),
].join('\n')
const join = await agent(joinPrompt, { label: 'join', phase: 'Join', model: OPUS, effort: 'xhigh' })

return { world: world, stage: stage, join: join }
