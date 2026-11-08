# Lighting and rendering research: pixel-art kingdom game (iOS 17+, A12 floor)

Research only, 8 Nov 2026. Nothing built or run. All web sources are listed in section 7.

Evidence labels used below:

- **[proven]**: stated in Apple or GitHub documentation, or shown by a public CI log or issue.
- **[likely]**: strong indirect evidence, but no source shows it for our exact setup.
- **[unverified]**: no source found; the prototype must test it.
- **[estimate]**: my own calculation or engineering judgement.

---

## 0. Answers at a glance

**Recommendation.** Write a small custom Metal renderer (`MTKView`):

- Draw each parallax plane into its own low-resolution offscreen texture of about 440 x 200 game pixels.
- Do the lighting, fog, glow and light shafts at that low resolution.
- Finish with one composite pass at native resolution. It upscales by an integer factor using exact texel reads, shifted by a whole number of device pixels for smooth sub-pixel scrolling.
- Keep SwiftUI as the app shell and draw the HUD on top in SwiftUI. Keep all game logic, including the light field that creatures react to, in plain Swift.
- Do not use `SKLightNode`, and do not use SpriteKit at all: a SpriteKit frame-rate regression on iOS 26 is still open with no workaround (Oct 2026).
- Keep SwiftUI `Canvas` as Plan B. It is the only rendering path already proven on our runner.

**Runner verdict.**

- **[proven]** Metal works on the macOS side of GitHub's arm64 runners. The VM exposes an "Apple Paravirtual device", and llama.cpp and MLX run real Metal work and correctness tests on hosted arm64 runners.
- **[proven]** The Simulator sends Metal calls to the host GPU and offers roughly `MTLGPUFamily.apple2` features, with documented limits.
- **[proven]** The Simulator's own UI has a software fallback when no Metal is available. So Comet Cargo's Canvas screenshots do not prove that Metal works in the Simulator.
- **[likely, unverified]** Metal inside the iOS Simulator on `macos-26` works, and XCUITest screenshots capture Metal content. No public source shows this for our exact setup.
- **[proven]** The Metal Toolchain, which compiles `.metal` files, is a separate component in Xcode 26. It has been missing or intermittent on `macos-26` images, so the build needs a guard step.
- Round 1 must therefore be a cheap Metal probe (section 2.5).

**Virtual resolution rule.**

- Integer scale `s = floor(physicalLandscapeHeight / 180)`.
- Visible rows `= ceil(H / s)`, which gives 180 to 207. Visible columns `= ceil(W / s)`, which gives 334 to 448.
- The render target is one column wider (plus 1) for sub-pixel scrolling.
- The image is anchored at the bottom, so extra rows show more sky. There are no black bars.
- Always size from `UIScreen.nativeBounds` and use `contentScaleFactor = nativeScale`.
- The iPhone 17 Pro test simulator gets s = 6 and 437 x 201. The 17 Pro Max gets s = 7 and 410 x 189. Full table in section 3.

**Top 3 risks.**

1. Metal in the runner's Simulator is unproven, and screenshots are our only eyes. Mitigation: probe first; Plan B is Canvas.
2. GPU code is written blind with no GPU debugger. Mitigation: shaders compiled at build time, offscreen render tests with pixel readback, and debug views of each buffer.
3. Real-device performance and frame pacing on an A12 and on iOS 26 are unmeasured. The runner VM gives no usable timing. Mitigation: a TestFlight check on an iPhone XS/XR and on a recent iPhone, with an on-screen frame-time overlay.

---

## 1. Approaches to dynamic 2D lighting (question 1)

### 1a. SpriteKit `SKLightNode` with normal maps

Facts:

- **[proven]** A sprite is lit when `light.categoryBitMask & sprite.lightingBitMask != 0`. The masks `shadowCastBitMask` and `shadowedBitMask` add hard shadows. A sprite that matches no light renders unlit, so the sky and backgrounds must also be lit sprites. (Apple, SKLightNode)
- **[proven]** The WWDC 2014 "What's New in SpriteKit" transcript says SpriteKit will "support up to 8 lights, like, for a single sprite". It adds that the number of lights "lighting the very same sprite actually matters", and that with more of them "you might not be able to stay on constant 60 on certain iOS hardwares".
- Field reports are old and anecdotal:
  - two lights in one scene gave about 20 fps on an iPhone 5;
  - a four-light game ran on an iPhone 7 but not on older phones;
  - the advice is one or two lights per sprite or scene;
  - one light on a 3rd-generation iPad dropped a scene from 60 to about 13 fps (Stack Overflow 25320450, seen only as a search snippet).
  - Sources: the Stack Overflow mirror in section 7.
- **[proven]** Normal maps can be generated with `SKTexture.generatingNormalMap()`. It filters the colour data "to generate a map based on pixel contrast", which in effect treats brightness as height.
  - **[estimate]** On pixel art that gives noisy bumps. Good normal maps are hand-made for every sprite, which doubles the art work, and Recraft does not produce them.
- **[estimate] How it looks with nearest-neighbour pixel art:**
  - SpriteKit renders at the view's native resolution, so light falloff, specular highlights and shadow edges are smooth at device-pixel level, laid over chunky texels.
  - There is no way to snap the light to the game-pixel grid.
  - Shadows are hard sprite silhouettes and cost extra.
- **[estimate] Fit for our scene:** we need 10 to 40 lights at once (braziers, torches, windows, lanterns), so many sprites would sit under more than one light. That exceeds the 8-lights-per-sprite cap, and the cost would be too high on an A12.
- **[proven] SpriteKit-wide risk:**
  - A minimal `SpriteView` scene stalls at about 40 fps on iOS 26 (iPhone 13, 11 Pro, 16e). It was fixed in 26.2 and came back in 26.3 and 26.4.
  - Apple DTS, May 2026: the bug "remains open" and has an engineer assigned. Oct 2026: retest on the iOS 27.2 beta. No fix is confirmed and no workaround is known. The tickets are FB21914640 and FB22038921. (Forum threads 800952, 815783, 816719)
  - A related bug: a SwiftUI `Menu` over an `SKView` or `ARView` drops its frame rate (FB20808104).
- **Verdict:** not suitable as the light system. At most one hero light.

### 1b. SpriteKit with custom `SKShader`, or `SKEffectNode` light maps

Facts:

- **[proven]** `SKShader` source is written in the OpenGL ES 2.0 shading language. SpriteKit appends it to its own preamble and compiles it at runtime.
  - Built-in symbols: `u_texture`, `u_time`, `v_tex_coord`, `v_color_mix`, `SKDefaultShading()`.
  - Per-frame data goes in `SKUniform`s; per-node data goes in `SKAttribute`s, which keeps one shared shader per batch.
  - Apple's advice: compile shaders at launch and share them. Changing the source or the uniform list recompiles the shader. (Apple, SKShader and "Creating a Custom Fragment Shader")
- **[proven]** `SKUniformType` covers float, vec2 to vec4, mat2 to mat4 and texture. **There are no arrays.**
  - **[estimate]** N lights must be packed into mat4 uniforms (two lights per mat4, so 16 lights use 8 uniforms) or into a small data texture (`SKMutableTexture`).
- **[estimate] Typical design:**
  - One full-screen "darkness" sprite with an `SKShader` that sums the N lights. It uses `blendMode = .multiply`, or `.multiplyX2` so lights can brighten above 1.
  - Additive glow sprites on top, and emissive sprites above the overlay.
  - That costs one draw call at native resolution. The light can be snapped to game pixels in the shader through `v_tex_coord` times the virtual size.
- **[proven]** An `SKEffectNode` renders its children into a private buffer every frame, optionally through a Core Image filter. `shouldRasterize` only helps static content.
  - An old report (iOS 8 era) used a full-screen effect node with a multiply sprite and a screen-blended light sprite. It cut the frame rate noticeably and fell to about 4 fps when the light's alpha flickered. Other old reports describe similar collapses.
- **[proven]** `SKRenderer` (iOS 11+) renders an `SKScene` into our own Metal command buffer. That is the only clean way to get a real low-resolution SpriteKit render plus custom passes, but then we write the Metal half anyway.
- **Pros:**
  - batching, atlases, actions and `SKEmitterNode` particles (embers, sparks, snow) for free;
  - less code than raw Metal.
- **Cons:**
  - shader errors show up only at runtime (GLSL dialect translated at runtime);
  - native-resolution rendering;
  - no HDR or multi-pass without `SKRenderer`;
  - the iOS 26 SpriteKit frame-rate regression above.
- **Verdict:** the sensible middle path in earlier years. In 2026 the open SpriteKit regression decides against it.

### 1c. Custom Metal renderer (`MTKView`) at low resolution: **recommended**

The pipeline per frame **[estimate: design]**:

1. **CPU (plain Swift):** build an immutable `FrameDesc` (sprite instances, lights, emissives, fog parameters, ambient values, camera) from game state. Copy it into a triple-buffered instance buffer.
2. **Low-resolution passes:**
   - Render targets: about (W+1) x H game pixels, private storage. Use `rgba8Unorm` for planes and `rgba16Float` for the light and bloom buffers.
   - **Planes:** sky gradient, far, mid, world (with actors), foreground, fog A and fog B.
     - Each plane is one instanced draw of textured quads from an atlas.
     - Each plane gets its own integer camera offset: camera x times the parallax factor, floored.
   - **Emissive:** windows, embers, eyes and stars go to their own target.
   - **Light accumulation:**
     - Clear to zero, then draw additive instanced light quads.
     - The falloff is optionally quantized to 3 to 5 bands with 4x4 Bayer dithering in game-pixel space, which gives true pixel-art light.
     - Flicker values arrive per instance from the CPU.
   - **Bloom:** threshold the lit image plus emissive, then half resolution, then two separable blur passes.
3. **Composite at native resolution:** one full-screen triangle. For each device pixel:
   - Read each plane with `texture.read(uint2)` at `floor((p + shift_i) / s)`, where `shift_i = round(frac_i * s)` device pixels.
   - Far planes get the ambient colour ramp.
   - World = albedo x (ambient + light) + emissive.
   - Fog = fog colour x (ambient + k x light), which makes halos in the mist around braziers.
   - Add bloom (linear upsampled, soft on purpose), then a final grade per time of day.
4. **SwiftUI HUD** on top (crisp system text in 8 languages, 44 pt targets).

Why this approach:

- **Beauty.** Full control over the look:
  - pixel-true banded or dithered light, warm pools against a cold ambient, light scattered in fog, real bloom;
  - shafts as additive beams or a cheap radial blur at low resolution;
  - colour grading per time of day, emissive windows;
  - optional 2D occlusion later: a horizontal wall clip on the CPU, or a low-res occluder mask with a 16 to 24 step raymarch per light.
  - Everything costs almost nothing at about 90k pixels.
- **Blind coding.**
  - **[proven]** Apple's best practice: "Compile your functions and build your library at build time". The default library built from `.metal` files is "the fastest and most efficient build option".
  - So shader syntax errors fail the runner build with a message.
  - Offscreen render tests can read pixels back and assert on them, a check neither SpriteKit nor SwiftUI shaders give as easily.
- **Frame pacing.** **[proven]** Apple says SwiftUI's animation schedule "doesn't promise" a rate, and points to Metal driven by a display link for precise control (forum 850664).
- **Cost:** the most code of the four options. **[estimate]** About 1,000 to 1,500 lines of Swift for the renderer plus 200 to 300 lines of MSL:
  - device and pipelines;
  - instance batcher (quad corners from `vertex_id`, no vertex buffer);
  - atlas loader or packer;
  - render-target management on resize;
  - 5 to 6 passes;
  - stats.
- **Simulator subset.** Keep to what the Simulator supports **[proven, Apple]**. Section 2.2 has the list.
- **A12 support.** No Metal 4 APIs: they need newer GPUs and OS versions. The classic `MTLRenderCommandEncoder` path covers iOS 17 on an A12 (Apple5 family).

### 1d. SwiftUI `Canvas` with blend modes and iOS 17 shaders

Facts:

- **[proven]** `Canvas` is immediate-mode. It "might provide better performance for a complex drawing that involves dynamic data" than views. It offers blend modes, layers and filters through `GraphicsContext`.
- **[proven] iOS 17 shaders:**
  - `ShaderLibrary` functions are `[[ stitchable ]]`.
  - `Shader.Argument.floatArray` maps to `device const float *ptr, int count`, so N lights fit easily.
  - "Currently only one image parameter is supported per Shader instance."
  - `layerEffect` gets `SwiftUI::Layer.sample()`, which returns a **linearly filtered** pixel. For a nearest look, sample at texel centres yourself.
  - The same filter exists inside Canvas as `GraphicsContext.Filter.layerShader`.
- **[proven]** "Views backed by AppKit or UIKit views may not render into the filtered layer." So a SwiftUI shader can never sit over an `SKView` or `MTKView`. This option is pure SwiftUI or nothing.
- **[proven]** SwiftUI shaders fail silently:
  - an extra image argument breaks layer sampling;
  - shaders fail without an error after a certain number or size of arguments;
  - there are no runtime errors for argument mismatches.
  - (robb/ShaderBugs) This is bad for blind coding.
- `.metal` files for `ShaderLibrary` also need the Metal Toolchain at build time (section 2).
- **[proven, anecdote]** 1,024 circles in Canvas plus `TimelineView` used about 50 % CPU on an iPhone 8 (A11).
- **Can it carry our scene on an A12 at 60 fps?** **[estimate]**
  - About 300 sprites plus 5 parallax layers, fog and a light pass: probably 60 fps in simple scenes, with little headroom.
  - Everything is re-encoded on the main thread every frame.
  - Every layer fills at native resolution, about 10 to 15 full-screen layers, or 35 to 50 MP per frame on an XS Max.
  - Frame pacing cannot be controlled.
  - Pixel-snapped light needs shader quantization.
- **Shader-free variant, possible on Canvas:**
  - Inside `context.drawLayer`, fill with the ambient colour using `.multiply`, then draw pre-made pixelated light sprites (images with `interpolation(.none)`) using `.plusLighter`.
  - That gives a light map with no custom shaders and no Metal Toolchain.
- **Verdict:** Plan B, if the round-1 probe shows that Metal does not work in the runner's Simulator. The rendering path is proven on our runner, and the team knows it from Comet Cargo.

### Comparison (1 = poor, 5 = best) **[estimate]**

| Criterion | a SKLightNode | b SpriteKit + SKShader | c Metal low-res | d Canvas (+ shaders) |
|---|---|---|---|---|
| Beauty, pixel-true light | 2 | 3 | 5 | 3 |
| Fog, glow, shafts, flicker cost | 2 | 3 (bloom is costly) | 5 | 3 |
| Code to write | 4 | 3 | 2 | 4 |
| Debuggable without a local compiler | 3 | 2 (runtime GLSL errors) | 4 (build errors, readback tests) | 2 (silent shader failures) |
| Runner rendering | needs Metal in Simulator | needs Metal in Simulator | needs Metal in Simulator, plus offscreen tests | Canvas proven; shaders need Metal |
| A12 performance and heat | 1 | 3 | 5 | 3 |
| OS risk | SpriteKit iOS 26 regression | same | lowest | SwiftUI behaviour shifts between 17 and 26 |

---

## 2. What GitHub's runner Simulator can render (question 2)

### 2.1 Proven

- The standard arm64 runner is a VM with "3 (M1)" CPUs, 7 GB RAM and 14 GB disk. Labels include `macos-26`. "Nested-virtualization is not supported due to the limitation of Apple's Virtualization Framework." (GitHub docs)
- `macos-26` arm64 image: Xcode 26.6 is the default (26.0.1 to 26.6 installed). The installed simulators are iPhone 17 Pro and 17 Pro Max on iOS 26.2, 26.4 and 26.5. (runner-images README)
  - There is no iOS 17 or 18 runtime. A12 phones top out at iOS 18, so iOS 17 and 18 behaviour cannot be tested on the runner without extra runtime downloads.
- macOS guests on Apple silicon get a paravirtualized GPU:
  - system_profiler shows "Apple Paravirtualized Graphics Device, Metal Support: Metal 2, 64 MB" (JDK-8375466);
  - Cua reports the stock guest's feature band as "roughly an Apple 5-era family".
- That device appears in GitHub CI. PyTorch skips it for MPS because it lacks `MTLGPUFamilyMac2`. The CI log line reads "Found device Apple Paravirtual device ... supports Metal false", where "supports Metal" is PyTorch's own Mac2 check. (PyTorch commit for #111576)
- Real Metal work runs on GitHub's hosted arm64 runners:
  - llama.cpp's `macOS-latest-arm64` job builds with Metal and runs tests with all layers on the GPU (`-ngl 99`). It turns Metal off only on the Intel runner, "due to intermittent failures with Github runners not having a GPU".
  - An MLX project probed `macos-14` and `macos-15` on 16 Sep 2026. The device was "Apple Paravirtual device", custom Metal kernels ran, and 24 reference-comparison tests passed. Their conclusion: usable "for Metal correctness tests but not performance benchmarks". (VeloxQuant-MLX #395)
- No Metal at all on older or Intel VMs:
  - `MTLCreateSystemDefaultDevice()` returned nil on GitHub's macOS 10.15 runners in 2020 ("doesn't allow us to provide GPU passthrough", #1779);
  - CircleCI: "no gpu/hardware acceleration ... due to being run in a VM".
  - CircleCI also notes "the iOS simulator ... is usually hardware accelerated but has a fallback", while Metal has no fallback.
  - Xcode 11 notes (third-party summary): on macOS before 10.15, simulators "continue to use software rendered OpenGL".
- Simulator (Apple):
  - `MTLCreateSystemDefaultDevice()` "returns a device instance that connects to Simulator", which forwards to the host GPU.
  - Its capabilities are "similar to an Apple family 2 GPU".
  - Apple says to use a real device to design and tune the rendering engine.

### 2.2 Simulator Metal limits we must respect [proven, Apple doc "Developing Metal apps that run in Simulator"]

- **Programmable blending is not supported.** Fragment shaders cannot read colour attachments, so every multi-pass effect uses separate passes and textures.
- **Constant buffers:** ≤ 64 KB each, offsets aligned to **256 bytes**, ≤ 14 per pipeline. Large arrays (sprite and light instances) go in `device` buffers; per-frame uniform slices are 256-byte aligned.
- **No writing to sRGB textures.** Use `bgra8Unorm` drawables and `rgba8Unorm`/`rgba16Float` targets. Load PNGs with `MTKTextureLoader` option `.SRGB: false`. Do the colour maths in sRGB space, which is normal for 2D pixel art.
- **Pixel formats to avoid:** `r8Unorm_srgb`, `b5g6r5`, `a1bgr5`, `abgr4`, `bgr5A1`, XR10, YUV. No rendering to `rgb9e5Float`.
- **Storage:** depth, stencil and MSAA textures private only; no MSAA x2 (we use no MSAA at all); heaps private only; textures made from buffers cannot be render targets.
- WWDC19: memoryless and shared textures are supported in the Simulator. We do not need memoryless.
- Keep atlases ≤ 2048² anyway. **[estimate]** That stays well under the Apple2-class limits.

### 2.3 Likely, but not shown by any public source for our setup

- **[likely]** In the iOS Simulator on `macos-26` arm64, `MTLCreateSystemDefaultDevice()` returns a device, and `MTKView`, SpriteKit and SwiftUI shaders render. The guest has a working Metal device and the Simulator forwards Metal to it.
  - Against: the paravirtual device lacks the Mac2 family, and two of five Apple Metal sample apps failed in a VM (Eclectic Light). If the Simulator wanted more than the device offers, it would quietly use its software fallback.
- **[likely]** XCUITest screenshots (`XCUIScreen`) capture the composited display, so `CAMetalLayer` content appears in them.
- **[proven]** In-process captures do **not** show Metal content: `drawHierarchy`, `layer.render(in:)` and Xcode's View Debugger ("does not render content for Metal views", forum 743902). For automated image checks, render offscreen into an `MTLTexture` and read it back.
- **[proven]** Comet Cargo's Canvas screenshots say nothing about Metal, because the software fallback exists.
- MapLibre runs its iOS unit tests with the Metal renderer on `macos-26`, but sends its render tests to real devices (AWS Device Farm). That is a hint that teams do not trust Simulator pixels for golden images.

### 2.4 Build-time issue: the Metal Toolchain [proven]

- Since Xcode 26 the Metal compiler is a separate component. Without it, a build with `.metal` files, including SwiftUI `ShaderLibrary` shaders, fails with "cannot execute tool 'metal' due to missing Metal Toolchain".
- The `macos-26` README does not list it.
- runner-images #13014 ("Metal Toolchain on macOS 26 Runners with Xcode 26") is still open (assigned 30 Oct 2026).
- #14013 ("occasionally missing on macos-26 runners") was closed in May 2026. The maintainers' fix: use the latest installed Xcode ("0 fails on 300 attempts").
- **Guard step for `run-check.sh`:** `xcodebuild -showComponent MetalToolchain` and, if it is missing, `xcodebuild -downloadComponent MetalToolchain`. The download is about 700 to 750 MB per #12856 and #13094. Its duration on the runner is **[unverified]**.
- Fallback if the toolchain keeps failing: compile the same MSL source at runtime with `device.makeLibrary(source:)`. No toolchain is needed; errors surface in a unit test instead of the build. Apple calls runtime compilation a "significant performance cost", which for us is a one-time launch cost **[estimate]**.
- SpriteKit `SKShader` compiles at runtime and never needs the toolchain.

### 2.5 What round 1 on the runner must verify (cheap probe, one round of about 15 minutes)

1. `MetalProbeTests`, a unit test in the Simulator:
   - log the device name, `supportsFamily` for apple2 to apple9 and mac2, and maximum buffer size;
   - **fail loudly** if the device is nil, so an environment change can never pass silently.
2. `OffscreenRenderTests`:
   - render a clear colour, one textured quad and one additive radial light into a 64 x 32 `rgba16Float` and `rgba8Unorm` target;
   - blit to a buffer, read the pixels back and assert exact or nearly exact values;
   - attach a PNG.
3. A UI test with an `MTKView` test pattern (1-px checkerboard, colour bars, gradient):
   - take an XCUITest screenshot;
   - **pixel-check it inside the test**: every game pixel must be an exact s x s block, and the colours must match.
4. Time the Metal Toolchain guard step and note whether the component was already there.
5. Optional, so a decision is never made blind: the same pattern through a SwiftUI `.layerEffect` and through a `SpriteView`.
6. Log the frame rate the Simulator reaches, for information only. Timing on a 3-core VM means nothing.

If step 1 or 3 fails, switch to Plan B (shader-free Canvas, section 1d).

---

## 3. Pixel-perfect rendering on iPhone landscape (question 3)

### 3.1 Landscape pixel sizes and the proposed rule (target 180 rows)

Physical pixels come from iosref.com. The 12 and 13 mini use a 3x logical scale downsampled to 2.88x.

Rule:

- `s = max(2, floor(H / 180))`
- visible rows = `H / s`, rendered as `ceil(H / s)`
- visible columns = `W / s`
- render target = `ceil(W / s) + 1` columns by `ceil(H / s)` rows, plus 1 row if the screen shakes.

| Devices | Landscape W x H px | s | Visible game px | Render target |
|---|---|---|---|---|
| iPhone SE 2nd/3rd gen | 1334 x 750 | 4 | 333.5 x 187.5 | 335 x 188 |
| iPhone XR, 11 (A12 floor: XR) | 1792 x 828 | 4 | 448 x 207 | 449 x 207 |
| iPhone 12 mini, 13 mini (at `nativeScale` 2.88) | 2340 x 1080 | 6 | 390 x 180 | 391 x 180 |
| iPhone XS, 11 Pro (A12 floor: XS) | 2436 x 1125 | 6 | 406 x 187.5 | 407 x 188 |
| iPhone 12, 12 Pro, 13, 13 Pro, 14, 16e, 17e | 2532 x 1170 | 6 | 422 x 195 | 423 x 195 |
| iPhone 14 Pro, 15, 15 Pro, 16 | 2556 x 1179 | 6 | 426 x 196.5 | 427 x 197 |
| iPhone 16 Pro, 17, 17 Pro (runner sim) | 2622 x 1206 | 6 | 437 x 201 | 438 x 201 |
| iPhone XS Max, 11 Pro Max (A12) | 2688 x 1242 | 6 | 448 x 207 | 449 x 207 |
| iPhone Air | 2736 x 1260 | 7 | 390.9 x 180 | 392 x 180 |
| iPhone 12 Pro Max, 13 Pro Max, 14 Plus | 2778 x 1284 | 7 | 396.9 x 183.4 | 398 x 184 |
| iPhone 14 Pro Max, 15 Plus, 15 Pro Max, 16 Plus | 2796 x 1290 | 7 | 399.4 x 184.3 | 401 x 185 |
| iPhone 16 Pro Max, 17 Pro Max (runner sim) | 2868 x 1320 | 7 | 409.7 x 188.6 | 411 x 189 |

Why 180 rows **[estimate]**:

- The visible height varies only 180 to 207 rows (+15 %).
- The width is 334 to 448 columns, which suits a side-scroller where threats come from the left.
- A game pixel is about 0.31 to 0.39 mm on every device.
- 180 is the classic 320 x 180 / 1080p pixel-art grid.
- The alternatives are worse:
  - 200 rows: 201 to 250 visible rows (the SE gets 250);
  - 135 rows: a chunkier look with 135 to 151 rows, but only 267 to 328 columns of view.
  - 135 is a valid art-direction choice if Louis wants bigger pixels. The prototype can show both (`-GWVirtualHeight 135|180`).

Leftover pixels and the safe area:

- No letterboxing.
- Render `ceil` rows and anchor the composite at the **bottom**: the ground line is exact and the partial top row is sky.
- Gameplay-critical content lives in a 180-row band. Rows 181 to 207 are sky and decor only.
- The width is variable:
  - design the gameplay for 334 visible columns (the SE);
  - wider phones simply see more world;
  - the camera look-ahead uses the real width.
- In landscape the notch or Dynamic Island covers about 59 to 62 pt on one side, about 30 game px at s = 6.
  - Render full-bleed underneath it, but keep focus and threats out of the outer about 30 game px.
  - The SwiftUI HUD respects the safe area. Support both landscape orientations.
- Always compute from `UIScreen.nativeBounds` and set `contentScaleFactor = nativeScale`. That makes the minis exact (1080 = 6 x 180) and survives Display Zoom.
  - **[proven]** Apple's Metal best practice: "Render drawables at the exact pixel size of your target display."
  - **[proven]** `MTKView` supports native scale automatically.

### 3.2 Smooth scrolling without shimmer

**Option A: snap the camera to whole game pixels.** **[estimate]**

- This is the simplest option and has zero shimmer.
- But at walking speed (for example 30 game px/s, half a pixel per frame) the whole screen jumps 6 to 7 device pixels at an uneven cadence. That reads as judder on 460-ppi screens. Not recommended.

**Option B, recommended: low-res target with a margin, shifted by the sub-pixel remainder.**

- **[proven technique]** Make the camera surface "1 pixel wider/taller", keep its coordinates rounded, and offset the upscaled image by the fraction (yal.cc). MonoGame and Godot users describe the same idea for parallax.

How it applies here **[estimate: design]**:

- Per plane i with parallax factor `p_i`:
  - `o_i = cameraX * p_i`
  - `n_i = floor(o_i)`, which drives the low-res render
  - `f_i = o_i - n_i`
  - the composite shifts plane i by `round(f_i * s)` whole device pixels.
- Because the shift is a whole number of device pixels and the upscale is an exact `read()`, every game pixel is exactly s x s device pixels. No shimmer and no uneven texel widths, while motion resolves to 1/s of a game pixel.
- Parallax needs one low-res texture per plane, since each plane has its own fraction. At about 90k pixels each, five or six planes cost almost nothing, and the composite reads them all in one native-resolution pass.

**Actors against the smooth camera.**

- **[estimate]** If the camera tracks the king and the king is snapped into the world texture, the king shivers by up to one game pixel (6 device px) on screen.
- Two fixes, both worth comparing in the prototype (`-GWActorMode snapped|smooth`):
  - the camera follows the king's snapped position, with lag only when he starts or stops;
  - recommended: draw actors (king, people, creatures) as quads in the composite pass at native resolution. Their positions are rounded to device pixels, their texels stay s x s blocks, and they are lit by reading the low-res light buffer at their position. Actor pixels may then sit a fraction of a game pixel off the ground grid, which is barely visible at 6x.
- A unit test can assert the king's on-screen jitter is ≤ 1 device pixel while walking. This is pure camera maths in `Core`.

Other rules:

- No sprite rotation, or rotate only inside the low-res buffer.
- Nearest sampling everywhere except bloom.
- Pad atlas cells by 1 to 2 px.

---

## 4. Performance budget on an A12 at 60 fps (question 4)

A12 GPU: 4-core Apple GPU, Apple5 family. Third-party specs give about 8.8 GPixel/s fill, about 17.6 GTexel/s and about 560 GFLOPS (hmc-tech, not from Apple). Native landscape sizes on A12 phones:

- XR: 1792 x 828 = 1.48 MP
- XS: 2436 x 1125 = 2.74 MP
- XS Max: 2688 x 1242 = 3.34 MP

Fill estimate **[estimate]**:

- **Recommended pipeline.** About 4 to 5 MP per frame on an XS Max:
  - low-res work: about 0.9 MP (6 planes, light, emissive, bloom);
  - **one** native composite: 3.34 MP, which is the dominant cost;
  - total about 270 MP/s, roughly 3 % of the A12's peak fill rate.
  - The composite reads about 8 texels per pixel, about 1.6 GT/s or 9 % of peak texture rate.
  - Expected GPU time is 2 to 3 ms of the 16.7 ms frame, leaving large thermal headroom.
- **Native-resolution approaches (SpriteKit or Canvas).** 10 to 15 full-screen alpha layers plus a light pass make about 35 to 50 MP per frame, roughly 2 to 3 GPixel/s, about 25 to 35 % of peak. Workable, but warmer, with less headroom and more throttling risk in long sessions.

Budget (recommended renderer) **[estimate]**:

| Item | Budget | Note |
|---|---|---|
| CPU per frame | ≤ 4 ms | logic + `FrameDesc` + encoding; target under 2 ms |
| GPU per frame | ≤ 6 ms | expected 2 to 3 ms on A12 |
| Draw calls | ≤ 30 | one instanced draw per plane/material, about 6 low-res passes, bloom 3, composite 1 |
| Sprite instances | ≤ 1,500 (design 300) | one triple-buffered instance buffer |
| Visible point lights | ≤ 64 (design 16 to 40) | additive quads at low resolution, culled by camera |
| Atlases | 1 to 2, ≤ 2048², `rgba8Unorm`, nearest, padded | load at launch, never per frame |
| Low-res passes | ≤ 12 full-screen equivalents | about 90k px each |
| Native-resolution passes | exactly 1 | the composite |
| GPU memory | < 40 MB | targets about 1 MB each |

Frame rate, ProMotion, battery and thermals:

- **[proven]** `MTKView.preferredFramesPerSecond` defaults to 60, and the actual rate is a factor of the screen's maximum.
- **[proven]** On ProMotion iPhones, apps need `CADisableMinimumFrameDurationOnPhone` to go above 60 Hz.
- **Recommendation:**
  - Do **not** set `CADisableMinimumFrameDurationOnPhone`. Cap at 60 for a steady cadence, half the GPU work and less heat. Pixel art gains little from 120 Hz.
  - Pause the `MTKView` (`isPaused`) in static menus and in the background.
- **[proven]** Apple: rates are only a hint. Faster rates can be off in Low Power Mode or when the phone is hot, so never assume a rate. The simulation runs on a fixed 60 Hz step with an accumulator.
- Watch `ProcessInfo.thermalState` and Low Power Mode, and step effects down:
  - `.serious`: no bloom, one fog plane;
  - `.critical`: 30 fps.
- Respect Reduce Motion: flicker amplitude about x0.25 and slower, no screen shake.
- **iOS 26 frame-pacing caveat:**
  - Unity saw an iOS 26 frame-rate drop with `CADisplayLink`, reported for "around 20% of our iOS26 users". Unity enabled `CAMetalDisplayLink` (iOS 17+) as the fix but hit hangs on older iOS versions.
  - **[unverified]** A search snippet from another forum thread claims iOS 26.1 fixed the drop.
  - Keep the render loop swappable (`MTKView` internal, `CADisplayLink`, `CAMetalDisplayLink`) and test on a device.
- Keep the SwiftUI HUD plain (no glass materials or animated menus over the running game) because of FB20808104.
- **On-device measurement:**
  - Our own overlay (`-GWStats YES` or a hidden gesture) shows CPU ms, GPU ms (`commandBuffer.gpuEndTime - gpuStartTime`), fps, thermal state and s.
  - The Metal Performance HUD can be turned on from code with `CAMetalLayer.developerHUDProperties` (iOS 16+).
  - **[unverified]** whether the HUD shows in TestFlight builds.

---

## 5. Architecture sketch (question 5)

Folders follow the Comet Cargo convention: `Core/`, `Render/` (new: Swift + one `.metal` file), `UI/`, `App/`, `Tests/`, `UITests/`.

### 5.1 Layers, back to front

1. **Sky:** a vertical gradient from the day ramp, plus stars (emissive, fade by time) and a sun or moon disc. Parallax 0.
2. **Far plane** (hills, distant forest), parallax about 0.2. Ambient tint only, with a haze colour by time.
3. **Mid plane** (trees, distant roofs), parallax about 0.5. Ambient tint plus a weak light share.
4. **Fog A** (behind the world), parallax about 0.9. Tileable pixel-noise strips drifting slowly.
5. **World plane**, parallax 1.0: ground, palisade and walls at the left front, the castle facade or interior cut-away in the middle, town and fields on the right. Fully lit.
6. **Actors** (king, people, creatures) drawn in the composite at device-pixel precision, lit from the light buffer.
7. **Emissive:** castle windows, brazier and torch flames, embers (CPU particles, seeded), creature eyes, lit signs.
8. **Fog B** (in front), parallax about 1.15. Lit: halos around braziers.
9. **Foreground** (grass, fence posts), parallax about 1.3, darker, with a light rim from the light buffer.
10. **Light shafts:** additive beams at dawn and dusk (sun through trees and castle windows) and moonbeams. Optional low-res radial blur from emissive pixels.
11. **Bloom**, then the final grade.
12. **SwiftUI HUD** (not part of the low-res image).

### 5.2 Light model

- **Ambient ramp.** Keyframes over the day, about 8 per day in `Core`, interpolated with smoothstep:
  - midnight 0.00, pre-dawn 0.20, dawn 0.25, morning 0.30, noon 0.50, late afternoon 0.70, golden hour 0.75, dusk 0.80, night 0.85.
  - Each keyframe sets: sky top and bottom colours, ambient colour and intensity, fog colour and density, haze, star alpha, sun or moon height, torch multiplier (torches fade in at dusk), and grade values.
  - Night ambient is cold and dim (blue, about 0.12 to 0.2). Lights are warm (about 255/170/90), and the grade keeps warm light saturated while cold areas lose saturation. That is the "warm pools versus cold night" pillar.
- **Point lights.** `LightSource { x, y, radius, color, intensity, kind, flickerSeed }`.
  - Falloff `(1 - d/r)^2`, optionally an ellipse so light pools sit flat on the ground, quantized to bands with Bayer dithering. The style is a lab toggle: `-GWLightStyle smooth|banded|dithered`.
  - Flicker uses a deterministic noise of `(seed, simTime)`: intensity ±15 %, radius jitter in whole pixels, a slight colour shift.
- **Emissive sprites** are added after lighting and feed the bloom. Windows can flicker gently and darken when the house sleeps.
- **Occlusion (optional, v2).** Walls clip light horizontally: on the CPU, from wall segments in `Core`, the light quad is cut at the wall. This is cheap and suits a side view. Later option: a low-res occluder mask with a short raymarch per light.
- **Light as a mechanic.** `Core.LightField.illumination(x, y)` uses the **same** `LightSource` list, without flicker so the AI does not jitter.
  - Creatures avoid ground above a threshold.
  - The outer band of the rendered falloff is drawn exactly at that threshold radius, so players can read the safe zone.
  - Never read the GPU light buffer back for gameplay.

### 5.3 Deterministic logic, testable apart from rendering

- `Core` (no UIKit, Metal or SwiftUI imports):
  - `GameState` value types and `Sim.step(state, input)` with a fixed 1/60 s step;
  - a seeded RNG (SplitMix64);
  - `DayClock`, `LightField`, the camera maths, the resolution rule;
  - all time is simulation time (no `Date()`).
- `FrameBuilder.build(state) -> FrameDesc`, pure Swift: sprites, lights, emissives, fog, ambient values, per-plane `n_i`/`f_i`.
  - Tests check budgets (instances, lights), sorting, and determinism (same seed and time give the same `FrameDesc` hash).
- `Render` consumes only a `FrameDesc`. It holds no game rules. It counts its draw calls and passes into a stats struct for tests and the overlay.
- `UI`: SwiftUI shell, a `GameView` with the `MTKView` in a `UIViewRepresentable`, and the HUD overlay.
  - After a debug "freeze" it sets an accessibility value (`frame:N`, `ready`) so UI tests wait until frames are stable before a screenshot.

### 5.4 First "lighting and feel" prototype (what runner screenshots must prove)

**Scene (`-GWScene kingdom`).** About 3 screens wide, about 1,300 x 180 game px:

- **Left front:** palisade, 2 braziers, torch posts, a fog bank, a few creature silhouettes with glowing eyes standing outside the light.
- **Middle:** castle facade with 8 to 12 lit windows, a gate with torches, and an interior cut-away (throne room with torches, `-GWScene castleInterior`).
- **Right:** town with lanterns, fields, the moon.
- The king walks on autoplay.
- Placeholder pixel sprites are generated in code at launch (palette blocks), so round 1 needs no image work on this Mac.

**Light lab (`-GWScene lightlab`).** A grey wall and floor with a grid of lights at three radii and two colours. It checks falloff, banding, dither, bloom and fog scattering.

**Debug launch arguments** (repo convention `-GW...`):

- `-GWScene kingdom|lightlab|castleInterior`
- `-GWTimeOfDay 0..1`, `-GWFreezeTime YES`, `-GWFlickerTime <s>`, `-GWSeed <n>`
- `-GWCameraX <px>`, `-GWAutoplay walk`, `-GWActorMode snapped|smooth`
- `-GWVirtualHeight 180|135`, `-GWScaleOverride <s>`, `-GWLightStyle smooth|banded|dithered`
- `-GWEffects all|nobloom|nofog|minimal`, `-GWShowLowRes YES` (raw buffer, no upscale), `-GWShowBuffer light|emissive|bloom|fog`
- `-GWDebugLights YES` (radius rings and ids), `-GWStats YES`, `-GWReduceMotion YES`

**Captures** (iPhone 17 Pro at s = 6; a subset on 17 Pro Max at s = 7 to prove the other scale; iPhone SE at s = 4 if that simulator can be created on the runner **[unverified]**):

- **Front:** noon 0.50, golden hour 0.75, dusk 0.80, night 0.95, dawn 0.25.
- **Castle:** dusk, night; throne room at night.
- **Town:** golden hour, night, pre-dawn 0.20.
- **Light lab:** night in all three light styles.
- **Raw low-res buffer** and **each debug buffer** at night.
- **Filmstrip** at dusk: about 8 frames while the king walks, with king and camera positions exposed through accessibility, so the test can compute jitter.
- **Reduced effects** at night (`minimal`), and one HUD shot in German for text length.

**Automated checks:**

- **Unit:** `DayCycleTests` (continuity, night darkness), `FlickerTests` (deterministic, bounded, Reduce Motion), `LightFieldTests` (illumination and wall clip), `CameraTests` (plane `n_i`/`f_i`, king jitter ≤ 1 device px in smooth mode), `ResolutionTests` (the table in 3.1), `FrameBuilderTests` (budgets, determinism hash).
- **GPU:** `MetalProbeTests` and `OffscreenRenderTests`, using threshold asserts on readback rather than exact golden images, because the Simulator GPU is not the device GPU.
- **UI:** screenshots plus the in-test pixel-grid check on a test-pattern strip (s x s blocks).

**Device check.** One TestFlight build with `-GWStats` reachable through a hidden gesture, on an A12 phone (XS/XR) and a current iPhone. The runner cannot measure performance.

---

## 6. Risks and open points (ranked)

1. **Metal inside the runner Simulator is unproven** (section 2.3). If it fails, we lose our only visual check for GPU code. Mitigation: the round-1 probe; Plan B is shader-free Canvas.
2. **Blind GPU development.** Wrong pixels are the only symptom, and there is no frame capture. Mitigation:
   - build-time shader compile with the toolchain guard;
   - offscreen readback tests;
   - debug buffer views;
   - small, well-known techniques only (instanced quads, additive lights, separable blur);
   - stay inside the Simulator subset.
3. **Device performance and pacing are unmeasured.** The A12 has no runner equivalent, and iOS 26 has had pacing bugs. Mitigation: low-res design with large headroom, a TestFlight stats overlay, a swappable render loop.
4. **Metal Toolchain flakiness on `macos-26`** (#13014 open, #14013). Mitigation: the guard step; runtime-compile fallback.
5. **Untested OS versions.** A12 users are on iOS 17 or 18, and the runner only has iOS 26.x simulators. Lower risk for plain Metal than for SwiftUI rendering.
6. **SwiftUI overlay over a Metal view** (FB20808104). Keep the HUD plain and pause world rendering under menus.
7. **Art pipeline.** True pixel art (palette, 1x sprites, padded atlas) is a separate topic. Recraft output needs conversion. Not researched here.
8. **Look-alike risk (outside this research, flagged because the look is the pillar).** A monarch walking left and right, building defences by day and attacked at night, in side-view pixel art at dusk and night, is close to *Kingdom* / *Kingdom Two Crowns* (Raw Fury). Louis' rules forbid recreating another game's look.
   - Our differences: one front on the left, a castle you walk through, light as the defence mechanic.
   - Avoid that series' signatures: mirror-water reflections along the bottom, its palette, the coin-pouch economy.

Open product questions for Louis (art direction; the prototype should show both options):

- 180 versus 135 game-pixel rows;
- smooth versus banded or dithered light.

---

## 7. Sources

SpriteKit lighting and shaders:

- Apple, SKLightNode: https://developer.apple.com/documentation/spritekit/sklightnode
- Apple, SKSpriteNode.lightingBitMask: https://developer.apple.com/documentation/spritekit/skspritenode/lightingbitmask
- WWDC 2014 session 606 transcript (8 lights per sprite, 60 fps warning): https://nonstrict.eu/wwdcindex/wwdc2014/606/ (video: https://developer.apple.com/videos/play/wwdc2014/606/)
- Apple, SKTexture.generatingNormalMap(withSmoothness:contrast:): https://developer.apple.com/documentation/spritekit/sktexture/generatingnormalmap(withsmoothness:contrast:)
- SKLightNode frame-rate reports (SO mirror): https://kaweah.freedombox.rocks/kiwix/stackoverflow.com_en_all_2023-11/questions/42338196/sklightnodes-causing-frame-rate-issues-in-spritekit
- Full-screen lighting via SKEffectNode, 4 fps with flicker (SO mirror): https://kaweah.freedombox.rocks/kiwix/stackoverflow.com_en_all_2023-11/questions/30273473/spritekit-fast-fullscreen-vignette-lighting-with-alpha-blending
- Apple, SKShader: https://developer.apple.com/documentation/spritekit/skshader
- Apple, Creating a Custom Fragment Shader: https://developer.apple.com/documentation/spritekit/creating-a-custom-fragment-shader
- Apple, SKUniformType (no arrays): https://developer.apple.com/documentation/spritekit/skuniformtype
- Apple, SKRenderer: https://developer.apple.com/documentation/spritekit/skrenderer
- Apple, SKEffectNode.shouldRasterize: https://developer.apple.com/documentation/spritekit/skeffectnode/shouldrasterize
- SpriteKit iOS 26 frame-rate regression: https://developer.apple.com/forums/thread/800952 , https://developer.apple.com/forums/thread/815783 , https://developer.apple.com/forums/thread/816719
- SpriteKit/RealityKit + SwiftUI overlay regression (FB20808104): https://developer.apple.com/forums/thread/804973

SwiftUI:

- Apple, Canvas: https://developer.apple.com/documentation/swiftui/canvas
- Apple, Shader.Argument: https://developer.apple.com/documentation/swiftui/shader/argument
- Apple, layerEffect(_:maxSampleOffset:isEnabled:): https://developer.apple.com/documentation/swiftui/view/layereffect(_:maxsampleoffset:isenabled:)
- Apple, GraphicsContext.Filter.layerShader: https://developer.apple.com/documentation/swiftui/graphicscontext/filter/layershader(_:maxsampleoffset:)
- SwiftUI shader silent failures: https://github.com/robb/ShaderBugs
- Apple DTS on SwiftUI frame pacing vs Metal + CADisplayLink: https://developer.apple.com/forums/thread/850664
- Canvas + TimelineView CPU anecdote (SO mirror): https://kaweah.freedombox.rocks/kiwix/stackoverflow.com_en_all_2023-11/questions/68964585/ios-15-swiftui-canvas-timelineview-terrible-performance

Metal and the Simulator:

- Apple, Developing Metal apps that run in Simulator: https://developer.apple.com/documentation/metal/developing-metal-apps-that-run-in-simulator
- Apple, Supporting Simulator in a Metal app: https://developer.apple.com/documentation/metal/supporting-simulator-in-a-metal-app
- WWDC19 418 Getting the Most Out of Simulator (transcript): https://nonstrict.eu/wwdcindex/wwdc2019/418/ (video: https://developer.apple.com/videos/play/wwdc2019/418/)
- Apple, Metal Best Practices, Functions and Libraries: https://developer.apple.com/library/archive/documentation/3DDrawing/Conceptual/MTLBestPracticesGuide/FunctionsandLibraries.html
- Apple, Metal Best Practices, Native Screen Scale: https://developer.apple.com/library/archive/documentation/3DDrawing/Conceptual/MTLBestPracticesGuide/NativeScreenScale.html
- Apple, MTKView.preferredFramesPerSecond: https://developer.apple.com/documentation/metalkit/mtkview/preferredframespersecond
- Apple, CAMetalLayer.developerHUDProperties: https://developer.apple.com/documentation/quartzcore/cametallayer/developerhudproperties
- Apple forum, View Debugger does not render Metal content: https://developer.apple.com/forums/thread/743902
- Xcode 11 Simulator Metal and software OpenGL fallback (third-party summary of release notes): https://developerinsider.co/whats-new-in-xcode-11/

GitHub runners and CI evidence:

- GitHub-hosted runners (specs, nested virtualization): https://docs.github.com/en/actions/reference/runners/github-hosted-runners
- Larger runners (M1 xlarge with GPU acceleration): https://docs.github.com/en/actions/reference/runners/larger-runners and https://github.blog/news-insights/product-news/introducing-the-new-apple-silicon-powered-m1-macos-larger-runner-for-github-actions/
- M1 runner announcement for open source: https://github.blog/changelog/2024-01-30-github-actions-introducing-the-new-m1-macos-runner-available-to-open-source/
- runner-images #9254 (M1 runner, no nested virtualization): https://github.com/actions/runner-images/issues/9254
- runner-images #1779 (MTLCreateSystemDefaultDevice nil, 2020, Intel): https://github.com/actions/runner-images/issues/1779
- runner-images #7085 (Metal passthrough request, 2023): https://github.com/actions/runner-images/issues/7085
- macos-26 arm64 image README: https://github.com/actions/runner-images/blob/main/images/macos/macos-26-arm64-Readme.md
- Metal Toolchain issues: https://github.com/actions/runner-images/issues/13014 , https://github.com/actions/runner-images/issues/14013 , https://github.com/actions/runner-images/issues/13094 , https://github.com/actions/runner-images/issues/12856 (search: https://api.github.com/search/issues?q=repo:actions/runner-images+metal+toolchain)
- PyTorch "Skip virtualized devices" (Apple Paravirtual device in GitHub CI): https://android.googlesource.com/platform/external/pytorch/+/ca5f6f7af3 (PR: https://github.com/pytorch/pytorch/pull/111576 ; issue https://github.com/pytorch/pytorch/issues/111449)
- llama.cpp CI (Metal tests on hosted arm64; disabled on Intel "not having a GPU"), mirror: https://huggingface.co/datasets/echodict/llama.cpp/blob/main/.github/workflows/build.yml
- MLX Metal probe on macos-14/15 runners (Sep 2026): https://github.com/rajveer43/VeloxQuant-MLX/issues/395
- JDK-8375466 (system_profiler: Apple Paravirtualized Graphics Device, Metal 2): https://bugs.openjdk.org/browse/JDK-8375466
- Cua, Metal capability band of stock macOS VMs: https://cua.ai/blog/gpu-passthrough-macos-vms
- Eclectic Light, GPU access in Apple-silicon VMs (2 of 5 Metal demos failed): https://eclecticlight.co/2023/10/26/how-good-is-gpu-access-for-apple-silicon-virtual-machines/
- CircleCI, no Metal device in VM; Simulator has a fallback: https://support.circleci.com/hc/en-us/articles/360052160592-Tests-Fail-With-Error-There-is-no-available-Metal-device-on-this-system
- MapLibre iOS CI (Metal unit tests on macos-26; render tests to AWS Device Farm): https://github.com/maplibre/maplibre-native/blob/main/.github/workflows/ios-ci.yml

Pixel-perfect rendering and 2D lighting technique:

- iPhone resolutions: https://iosref.com/res
- Smooth pixel-perfect camera (+1 px surface, fractional offset): https://yal.cc/gamemaker-smooth-pixel-perfect-camera/
- Smooth parallax in a low-res game: https://community.monogame.net/t/smooth-parallax-scrolling-for-low-res-2d-game/10741
- 2D light maps (additive light target, multiply composite): https://gamedev.net/forums/topic/661019-simple-2d-lighting-effects
- Further reading, 2D lighting techniques overview (page did not render for me): https://www.slembcke.net/blog/2DLightingTechniques/

Performance and frame rate:

- A12 GPU third-party specs: https://hmc-tech.com/gpus/apple-4-core-a12-vs-qualcomm-adreno-630 ; https://en.wikipedia.org/wiki/Apple_A12
- ProMotion opt-in key (iMore on Apple docs): https://www.imore.com/apple-clears-120hz-iphone-13-pro-confusion-developers ; forum: https://www.developer.apple.com/forums/thread/792011
- Unity on iOS 26 frame-rate drop, CADisplayLink vs CAMetalDisplayLink: https://discussions.unity.com/t/6000-0-57f1-6000-0-56f1-builds-hangs-on-start-for-iphone-11/1682210?page=3
