// Lanternhold shaders (DESIGN.md "Tech plan"). Compiled at build time into the default library. Keep inside the
// Simulator's Metal subset: no programmable blending, no sRGB render targets, instance arrays in `device` buffers.
#include <metal_stdlib>
using namespace metal;

// MARK: - Full-screen triangle (no vertex buffer)

struct FullscreenOut {
    float4 position [[position]];
};

vertex FullscreenOut lh_fullscreen_vertex(uint vid [[vertex_id]]) {
    float2 p = float2(float((vid << 1) & 2u), float(vid & 2u));
    FullscreenOut out;
    out.position = float4(p * 2.0f - 1.0f, 0.0f, 1.0f);
    return out;
}

// MARK: - Pixel-grid test pattern

struct PatternUniforms {
    uint scale;     // device pixels per game pixel
    uint width;     // drawable width in device pixels
    uint height;    // drawable height in device pixels
    uint barRows;   // game rows of colour bars at the top
};

constant float3 kBars[8] = {
    float3(1.00f, 1.00f, 1.00f), float3(1.00f, 0.85f, 0.20f), float3(0.20f, 0.85f, 0.90f), float3(0.25f, 0.80f, 0.30f),
    float3(0.85f, 0.30f, 0.80f), float3(0.90f, 0.25f, 0.20f), float3(0.20f, 0.30f, 0.90f), float3(0.05f, 0.05f, 0.08f)
};

// A checkerboard of single game pixels anchored at the bottom-left corner of the drawable, so every game pixel must
// come out as an exact s x s block of device pixels. Colour bars across the top rows make the picture easy to read.
fragment float4 lh_testpattern_fragment(FullscreenOut in [[stage_in]],
                                        constant PatternUniforms &u [[buffer(0)]]) {
    uint s = max(u.scale, 1u);
    uint h = max(u.height, 1u);
    uint px = uint(in.position.x);
    uint py = min(uint(in.position.y), h - 1u);
    if (py / s < u.barRows) {
        uint bar = min((px * 8u) / max(u.width, 1u), 7u);
        return float4(kBars[bar], 1.0f);
    }
    uint gx = px / s;
    uint gy = (h - 1u - py) / s;
    bool odd = ((gx + gy) & 1u) == 1u;
    return odd ? float4(0.85f, 0.15f, 0.10f, 1.0f) : float4(0.10f, 0.20f, 0.85f, 1.0f);
}

// MARK: - Textured quads (instanced, corners from the vertex id)

struct QuadInstance {
    float4 rect;    // x, y, width, height in target pixels, origin top-left
    float4 uv;      // u0, v0, u1, v1
};

struct QuadOut {
    float4 position [[position]];
    float2 uv;
};

// Triangle strip of four vertices: (0,0) (1,0) (0,1) (1,1).
vertex QuadOut lh_quad_vertex(uint vid [[vertex_id]],
                              uint iid [[instance_id]],
                              device const QuadInstance *instances [[buffer(0)]],
                              constant float4 &target [[buffer(1)]]) {
    QuadInstance q = instances[iid];
    float2 corner = float2(float(vid & 1u), float((vid >> 1) & 1u));
    float2 pixel = q.rect.xy + corner * q.rect.zw;
    float2 ndc = float2(pixel.x / target.x * 2.0f - 1.0f, 1.0f - pixel.y / target.y * 2.0f);
    QuadOut out;
    out.position = float4(ndc, 0.0f, 1.0f);
    out.uv = mix(q.uv.xy, q.uv.zw, corner);
    return out;
}

fragment float4 lh_quad_fragment(QuadOut in [[stage_in]],
                                 texture2d<float> tex [[texture(0)]]) {
    constexpr sampler nearest(coord::normalized, filter::nearest, address::clamp_to_edge);
    return tex.sample(nearest, in.uv);
}

// MARK: - Additive radial lights

struct LightInstance {
    float4 circle;  // centre x, centre y, radius in target pixels, intensity
    float4 color;   // r, g, b, unused
};

struct LightOut {
    float4 position [[position]];
    float2 local;   // -1 ... 1 across the light's square
    float3 color;
};

vertex LightOut lh_light_vertex(uint vid [[vertex_id]],
                                uint iid [[instance_id]],
                                device const LightInstance *lights [[buffer(0)]],
                                constant float4 &target [[buffer(1)]]) {
    LightInstance l = lights[iid];
    float2 corner = float2(float(vid & 1u), float((vid >> 1) & 1u)) * 2.0f - 1.0f;
    float2 pixel = l.circle.xy + corner * l.circle.z;
    float2 ndc = float2(pixel.x / target.x * 2.0f - 1.0f, 1.0f - pixel.y / target.y * 2.0f);
    LightOut out;
    out.position = float4(ndc, 0.0f, 1.0f);
    out.local = corner;
    out.color = l.color.rgb * l.circle.w;
    return out;
}

// Falloff (1 - d/r)^2, zero at the radius.
fragment float4 lh_light_fragment(LightOut in [[stage_in]]) {
    float f = saturate(1.0f - length(in.local));
    return float4(in.color * (f * f), 0.0f);
}

// =====================================================================================================================
// MARK: - The renderer (milestone 1 part B)
//
// Low-resolution passes, each (W + 1) x H game pixels: eight planes as instanced atlas quads (premultiplied alpha),
// additive light pools, the emissive pass (glow, window glass and occluders in draw order), bloom at half resolution.
// One composite pass at native resolution reads every plane with exact texel reads at floor((p + shift) / s), lights
// the clouds by the sky, hazes the far and mid planes (toward lavender at warm hours), lights the world by ambient +
// point light, lights the fog, adds emissive and bloom and grades the picture. Actors are quads in the same pass at
// device-pixel positions: their fragments composite the whole stack for their own pixel, so fog B and the foreground
// still cover them.
// =====================================================================================================================

struct SpriteQuad {
    float4 rect;    // x, y, width, height in target pixels, origin top-left
    float4 texel;   // u0, v0, u1, v1 in atlas texels (u0 > u1 when mirrored)
    float4 tint;    // rgb multiplier, alpha
};

struct SpriteOut {
    float4 position [[position]];
    float2 texel;
    float4 tint [[flat]];
};

static inline float4 lh_ndc(float2 pixel, float2 size) {
    return float4(pixel.x / size.x * 2.0f - 1.0f, 1.0f - pixel.y / size.y * 2.0f, 0.0f, 1.0f);
}

vertex SpriteOut lh_sprite_vertex(uint vid [[vertex_id]],
                                  uint iid [[instance_id]],
                                  device const SpriteQuad *quads [[buffer(0)]],
                                  constant float4 &target [[buffer(1)]]) {
    SpriteQuad q = quads[iid];
    float2 corner = float2(float(vid & 1u), float((vid >> 1) & 1u));
    SpriteOut out;
    out.position = lh_ndc(q.rect.xy + corner * q.rect.zw, target.xy);
    out.texel = mix(q.texel.xy, q.texel.zw, corner);
    out.tint = q.tint;
    return out;
}

// One texel per game pixel, read exactly; premultiplied output. The same function serves the albedo, clouds and fog
// planes (over blending) and the sky pass (additive blending).
fragment float4 lh_sprite_fragment(SpriteOut in [[stage_in]],
                                   texture2d<float> atlas [[texture(0)]]) {
    uint2 t = uint2(max(in.texel, float2(0.0f)));
    float4 c = atlas.read(t);
    float a = c.a * in.tint.a;
    if (a <= 0.003f) {
        discard_fragment();
    }
    return float4(c.rgb * in.tint.rgb * a, a);
}

// MARK: Emissive pass

// The window glass colours of the palette (night0, night1, ink): inside a glass quad these pixels glow.
static inline bool lh_is_glass(float3 c) {
    const float tolerance = 1.5f / 255.0f;
    const float3 night0 = float3(14.0f, 11.0f, 30.0f) / 255.0f;
    const float3 night1 = float3(28.0f, 24.0f, 56.0f) / 255.0f;
    const float3 ink = float3(42.0f, 34.0f, 48.0f) / 255.0f;
    return all(abs(c - night0) <= tolerance) || all(abs(c - night1) <= tolerance) || all(abs(c - ink) <= tolerance);
}

// The emissive pass blends premultiplied over, in draw order. tint.a picks the kind: 0 ... 1 a glow quad (its colour
// added with alpha 0, so it sums like additive light), -1 window glass (the sprite's glass pixels inside the quad add
// the tint colour), -2 an occluder (a sprite drawn later clears the glow under its opaque pixels).
fragment float4 lh_emissive_fragment(SpriteOut in [[stage_in]],
                                     texture2d<float> atlas [[texture(0)]]) {
    uint2 t = uint2(max(in.texel, float2(0.0f)));
    float4 c = atlas.read(t);
    float mode = in.tint.a;
    if (mode < -1.5f) {
        if (c.a < 0.5f) {
            discard_fragment();
        }
        return float4(0.0f, 0.0f, 0.0f, 1.0f);
    }
    if (mode < -0.5f) {
        if (c.a < 0.5f || !lh_is_glass(c.rgb)) {
            discard_fragment();
        }
        return float4(in.tint.rgb, 0.0f);
    }
    float a = c.a * mode;
    if (a <= 0.003f) {
        discard_fragment();
    }
    return float4(c.rgb * in.tint.rgb * a, 0.0f);
}

// MARK: Light pools

struct LightQuad {
    float4 circle;  // centre x, centre y, radius (target pixels of its plane), intensity
    float4 color;   // r, g, b, vertical squash of the pool (ellipseY)
};

struct LightPassUniforms {
    float4 target;  // width, height, world plane whole offset (anchors the dither to the world), lit threshold
    uint4 style;    // x: 0 smooth, 1 banded, 2 dithered; y: bands
};

struct LightPoolOut {
    float4 position [[position]];
    float4 circle [[flat]];
    float4 color [[flat]];
};

constant float kBayer4[16] = { 0.0f, 8.0f, 2.0f, 10.0f, 12.0f, 4.0f, 14.0f, 6.0f,
                               3.0f, 11.0f, 1.0f, 9.0f, 15.0f, 7.0f, 13.0f, 5.0f };

static inline float lh_bayer(uint2 p) {
    return (kBayer4[(p.y & 3u) * 4u + (p.x & 3u)] + 0.5f) / 16.0f;
}

// Falloff (1 - d)^2 in game pixels. Smooth: the light drops by almost half at the lit threshold, so the edge the
// creatures respect is visible. Banded: equal bands inside the lit area, nothing outside. Dithered: the bands blend
// through a 4x4 Bayer pattern anchored to the world, with a dithered fringe just outside the edge.
static inline float lh_light_level(float d, uint style, uint bands, float edge, float dither) {
    float t = saturate(1.0f - d);
    t = t * t;
    if (style == 0u) {
        return t >= edge ? t : t * 0.55f;
    }
    if (t < edge) {
        if (style == 2u) {
            float fringe = (t - edge * 0.5f) / (edge * 0.5f);
            if (fringe > dither) {
                return edge * 0.6f;
            }
        }
        return 0.0f;
    }
    float n = float(max(bands, 2u));
    float s = (t - edge) / (1.0f - edge);
    float k = style == 2u ? floor(s * n + dither - 0.5f) : floor(s * n);
    k = clamp(k, 0.0f, n - 1.0f);
    return mix(0.2f, 1.0f, k / (n - 1.0f));
}

vertex LightPoolOut lh_pool_vertex(uint vid [[vertex_id]],
                                   uint iid [[instance_id]],
                                   device const LightQuad *lights [[buffer(0)]],
                                   constant LightPassUniforms &u [[buffer(1)]]) {
    LightQuad l = lights[iid];
    float squash = max(l.color.w, 0.05f);
    float2 corner = float2(float(vid & 1u), float((vid >> 1) & 1u)) * 2.0f - 1.0f;
    float2 extent = float2(l.circle.z, l.circle.z / squash) + 1.0f;
    LightPoolOut out;
    out.position = lh_ndc(l.circle.xy + corner * extent, u.target.xy);
    out.circle = l.circle;
    out.color = l.color;
    return out;
}

fragment float4 lh_pool_fragment(LightPoolOut in [[stage_in]],
                                 constant LightPassUniforms &u [[buffer(0)]]) {
    float2 p = in.position.xy;
    float2 offset = float2(p.x - in.circle.x, (p.y - in.circle.y) * in.color.w);
    float r = max(in.circle.z, 0.5f);
    float d = length(offset) / r;
    if (d >= 1.0f) {
        discard_fragment();
    }
    uint2 cell = uint2(uint(p.x) + uint(max(u.target.z, 0.0f)), uint(p.y));
    float level = lh_light_level(d, u.style.x, u.style.y, u.target.w, lh_bayer(cell));
    float strength = abs(in.circle.w) * level;
    // A backdrop light (negative intensity: the warden statue's bowl fire on the far wall) goes to alpha only; the
    // composite lights only the mid plane with it, in the backdrop light's colour.
    if (in.circle.w < 0.0f) {
        return float4(0.0f, 0.0f, 0.0f, strength);
    }
    return float4(in.color.rgb * strength, 0.0f);
}

// MARK: Bloom

struct BloomUniforms {
    float4 size;    // low-res width, height, half-res width, height
    float4 params;  // share of point light, share of the sky emissives, threshold, knee
    float4 backdrop; // colour of the backdrop lights (the light buffer's alpha), unused
};

// Half resolution: each pixel averages 2 x 2 low-res pixels of emissive, light and sky glow, then keeps only what
// is bright (soft knee).
fragment float4 lh_bloom_prefilter_fragment(FullscreenOut in [[stage_in]],
                                            constant BloomUniforms &u [[buffer(0)]],
                                            texture2d<float> emissive [[texture(0)]],
                                            texture2d<float> light [[texture(1)]],
                                            texture2d<float> sky [[texture(2)]]) {
    uint2 base = uint2(in.position.xy) * 2u;
    uint2 limit = uint2(max(u.size.xy, float2(1.0f))) - 1u;
    float3 sum = float3(0.0f);
    for (uint j = 0u; j < 2u; j++) {
        for (uint i = 0u; i < 2u; i++) {
            uint2 t = min(base + uint2(i, j), limit);
            float4 l = light.read(t);
            sum += emissive.read(t).rgb + (l.rgb + u.backdrop.rgb * l.a) * u.params.x + sky.read(t).rgb * u.params.y;
        }
    }
    float3 c = sum * 0.25f;
    float peak = max(c.r, max(c.g, c.b));
    float keep = smoothstep(u.params.z, u.params.z + u.params.w, peak);
    return float4(c * keep, 1.0f);
}

struct BlurUniforms {
    float4 dir;     // step x, y in normalized coordinates, texture width, height
};

// Separable Gaussian, nine taps from five linear fetches.
fragment float4 lh_blur_fragment(FullscreenOut in [[stage_in]],
                                 constant BlurUniforms &u [[buffer(0)]],
                                 texture2d<float> source [[texture(0)]]) {
    constexpr sampler linear_clamp(coord::normalized, filter::linear, address::clamp_to_edge);
    float2 uv = in.position.xy / max(u.dir.zw, float2(1.0f));
    float2 d = u.dir.xy;
    float3 c = source.sample(linear_clamp, uv).rgb * 0.2270270270f;
    c += source.sample(linear_clamp, uv + d * 1.3846153846f).rgb * 0.3162162162f;
    c += source.sample(linear_clamp, uv - d * 1.3846153846f).rgb * 0.3162162162f;
    c += source.sample(linear_clamp, uv + d * 3.2307692308f).rgb * 0.0702702703f;
    c += source.sample(linear_clamp, uv - d * 3.2307692308f).rgb * 0.0702702703f;
    return float4(c, 1.0f);
}

// MARK: Composite

struct CompositeUniforms {
    float4 screen;      // device width, height, pixel scale s, lit threshold
    float4 target;      // low-res width, height, ground row, world plane whole offset
    int4 shiftsA;       // device shifts of sky, clouds, far, mid
    int4 shiftsB;       // device shifts of fog A, world, fog B, foreground
    float4 skyTop;      // rgb, star alpha
    float4 skyBottom;   // rgb, haze
    float4 ambient;     // world ambient rgb, ambient scale inside the darkness bank
    float4 ambientFar;  // far ambient rgb (cooler at warm hours), share of point light on the mid plane
    float4 fog;         // light share fog A, light share fog B, glow gain, unused
    float4 bank;        // bank edge (world target px), fade width, unused, unused
    float4 light;       // light gain, hot knee, foreground light share, foreground ambient share
    float4 bloom;       // strength, on, half-res width, half-res height
    float4 grade;       // warmth, saturation, vignette, unused
    uint4 debug;        // buffer view (0 none, 1 light, 2 emissive, 3 bloom, 4 fog), low-res inset, rings, lights
    float4 haze;        // far haze, mid haze, valley mist, unused
    float4 look;        // night colourise, light glow on albedo, mid ambient share, fog brightness
    float4 ambientMid;  // mid ambient rgb (cooler at warm hours), unused
    float4 farHaze;     // the far plane's haze colour rgb (the horizon, toward lavender at warm hours), unused
    float4 midHaze;     // the mid plane's haze colour rgb, unused
    float4 cloud;       // clouds: share of ambient on the sunlit tops, of the sky's top colour in the bellies, haze
    float4 backdropLight; // colour of the backdrop lights (the light buffer's alpha: they light only the mid plane)
};

// The cold colour of the night: ambient-lit albedo pulled toward violet by its own luminance (k = 0 by day), so
// every unlit thing joins one blue-violet band while warm light keeps its colour. Linear in albedo, so it works on
// premultiplied planes.
constant float3 kNightTint = float3(1.03f, 0.86f, 1.66f);

// How much point light reflects as from a neutral grey surface, the cap on the light a surface reflects, and the share
// of light left in the soil under the grass (polish after the art review).
constant float kLitNeutral = 0.35f;
constant float kLitCap = 1.6f;
constant float kLitUnderground = 0.25f;

static inline float3 lh_cold(float3 albedo, float3 ambient, float k) {
    float3 a = albedo * ambient;
    float luma = dot(a, float3(0.299f, 0.587f, 0.114f));
    return mix(a, luma * kNightTint, k);
}

struct PlaneCoords {
    uint2 sky;
    uint2 clouds;
    uint2 distant;
    uint2 mid;
    uint2 fogA;
    uint2 world;
    uint2 fogB;
    uint2 fg;
    float2 bloomUV;
    uint row;
};

struct PixelLight {
    float3 light;   // point light at this pixel, gain and hot shoulder applied
    float3 backdrop; // the same with the backdrop lights added: the mid plane's light
    float bank;     // ambient multiplier of the darkness bank
};

static inline uint lh_column(float px, int shift, constant CompositeUniforms &u) {
    int s = max(int(u.screen.z), 1);
    int x = (int(px) + shift) / s;
    return uint(clamp(x, 0, int(u.target.x) - 1));
}

// Exact s x s game pixels: the image is anchored at the bottom, each plane shifted by its whole device pixels.
static PlaneCoords lh_coords(float2 p, constant CompositeUniforms &u) {
    int s = max(int(u.screen.z), 1);
    int fromBottom = (int(u.screen.y) - 1 - int(p.y)) / s;
    int row = clamp(int(u.target.y) - 1 - fromBottom, 0, int(u.target.y) - 1);
    uint r = uint(row);
    PlaneCoords c;
    c.row = r;
    c.sky = uint2(lh_column(p.x, u.shiftsA.x, u), r);
    c.clouds = uint2(lh_column(p.x, u.shiftsA.y, u), r);
    c.distant = uint2(lh_column(p.x, u.shiftsA.z, u), r);
    c.mid = uint2(lh_column(p.x, u.shiftsA.w, u), r);
    c.fogA = uint2(lh_column(p.x, u.shiftsB.x, u), r);
    c.world = uint2(lh_column(p.x, u.shiftsB.y, u), r);
    c.fogB = uint2(lh_column(p.x, u.shiftsB.z, u), r);
    c.fg = uint2(lh_column(p.x, u.shiftsB.w, u), r);
    // Bloom is read once per game pixel (its centre on the world grid, rows from the bottom), so glows step in s x s
    // blocks like the art instead of a smooth full-resolution blur (polish after the art review: the sun's and the
    // bowl fire's halos were the only smeared pixels on screen).
    float xs = floor((p.x + float(u.shiftsB.y)) / float(s)) + 0.5f;
    float ys = floor(u.target.y - (u.screen.y - p.y) / float(s)) + 0.5f;
    c.bloomUV = float2(xs, ys) / max(u.bloom.zw * 2.0f, float2(1.0f));
    return c;
}

// The low-res inset (-GWShowLowRes): one device pixel per game pixel, no shifts.
static PlaneCoords lh_inset_coords(float2 p, constant CompositeUniforms &u) {
    uint2 t = uint2(min(p, u.target.xy - 1.0f));
    PlaneCoords c;
    c.row = t.y;
    c.sky = t;
    c.clouds = t;
    c.distant = t;
    c.mid = t;
    c.fogA = t;
    c.world = t;
    c.fogB = t;
    c.fg = t;
    c.bloomUV = (float2(t) + 0.5f) / max(u.bloom.zw * 2.0f, float2(1.0f));
    return c;
}

// Light gain and a hot shoulder: bright light turns gold-white.
static inline float3 lh_hot(float3 raw, constant CompositeUniforms &u) {
    float3 l = raw * u.light.x;
    float peak = max(l.r, max(l.g, l.b));
    float hot = max(peak - u.light.y, 0.0f);
    return l + float3(0.55f, 0.5f, 0.38f) * hot;
}

static PixelLight lh_pixel_light(PlaneCoords c, constant CompositeUniforms &u, texture2d<float> lightTex) {
    PixelLight info;
    float4 raw = lightTex.read(c.world);
    info.light = lh_hot(raw.rgb, u);
    info.backdrop = lh_hot(raw.rgb + u.backdropLight.rgb * raw.a, u);
    float column = float(c.world.x) + 0.5f;
    float inside = 1.0f - smoothstep(u.bank.x - u.bank.y, u.bank.x, column);
    info.bank = mix(1.0f, u.ambient.w, inside);
    return info;
}

// Dithered bands of the sky gradient, anchored to the screen.
static float3 lh_sky(PlaneCoords c, constant CompositeUniforms &u) {
    float horizon = max(u.target.z, 1.0f);
    float v = saturate((float(c.sky.y) + 0.5f) / horizon);
    v = pow(v, 1.35f);
    float steps = 16.0f;
    float q = saturate(floor(v * steps + lh_bayer(c.sky)) / steps);
    return mix(u.skyTop.rgb, u.skyBottom.rgb, q);
}

// Clouds lit by the sky: the sunlit tops (bright albedo) take the ambient light, the shaded bellies the sky's top
// colour, then a share of haze toward the horizon colour. At golden hour the tops turn gold and the bellies violet, at
// night both go dim blue.
static float3 lh_clouds(float3 color, float4 k, constant CompositeUniforms &u) {
    float3 albedo = k.rgb / max(k.a, 0.001f);
    float sun = saturate((dot(albedo, float3(0.299f, 0.587f, 0.114f)) - 0.6f) / 0.3f);
    float3 lit = albedo * (u.ambient.rgb * u.cloud.x * sun + u.skyTop.rgb * u.cloud.y * (1.0f - sun));
    lit = mix(lit, u.skyBottom.rgb, u.cloud.z);
    return mix(color, lit, k.a);
}

// Sky and clouds, far and mid planes with haze (aerial perspective), fog A, the lit world plane and its emissive parts.
// `midVisible` returns how much of the mid plane still shows (the backdrop lights grade only that share).
static float3 lh_base(PlaneCoords c, PixelLight info, constant CompositeUniforms &u,
                      texture2d<float> skyTex, texture2d<float> cloudsTex, texture2d<float> farTex,
                      texture2d<float> midTex, texture2d<float> fogATex, texture2d<float> worldTex,
                      texture2d<float> emissiveTex, thread float &midVisible) {
    float3 color = lh_sky(c, u) + skyTex.read(c.sky).rgb;
    float4 k = cloudsTex.read(c.clouds);
    if (k.a > 0.0f) {
        color = lh_clouds(color, k, u);
    }
    float horizon = max(u.target.z, 1.0f);
    float low = smoothstep(horizon - 70.0f, horizon, float(c.row));

    float4 f = farTex.read(c.distant);
    if (f.a > 0.0f) {
        float3 lit = lh_cold(f.rgb, u.ambientFar.rgb, u.look.x);
        float haze = saturate(u.haze.x + low * u.haze.z);
        lit = mix(lit, u.farHaze.rgb * f.a, haze);
        color = color * (1.0f - f.a) + lit;
    }
    float4 m = midTex.read(c.mid);
    midVisible = 0.0f;
    if (m.a > 0.0f) {
        float3 lit = lh_cold(m.rgb, u.ambientMid.rgb, u.look.x) + m.rgb * info.backdrop * u.ambientFar.w;
        float haze = saturate(u.haze.y + low * u.haze.z * 0.5f);
        lit = mix(lit, u.midHaze.rgb * m.a, haze);
        color = color * (1.0f - m.a) + lit;
        midVisible = m.a;
    }
    float4 fa = fogATex.read(c.fogA);
    if (fa.a > 0.0f) {
        float3 lit = fa.rgb * (info.bank * u.look.w) + info.light * (u.fog.x * u.fog.z * fa.a);
        color = color * (1.0f - fa.a) + lit;
        midVisible *= 1.0f - fa.a;
    }
    float4 w = worldTex.read(c.world);
    if (w.a > 0.0f) {
        // Polish after the art review: firelight reflects partly as from a neutral surface (warm light on a teal banner
        // read as a cyan halo), it is capped below white (the king's lantern blew a cottage wall out), and it fades
        // a few rows under the grass (no light shining into the earth's cross-section).
        float3 reflectance = mix(w.rgb, float3(dot(w.rgb, float3(0.299f, 0.587f, 0.114f))), kLitNeutral);
        float under = float(c.row) - u.target.z;
        // The cap scales the light as a whole, so it keeps its warm hue (a per-channel cap turned it white near the
        // torches, and white light on teal cloth read cyan again).
        float peak = max(info.light.r, max(info.light.g, info.light.b));
        float3 light = info.light * (min(peak, kLitCap) / max(peak, 0.0001f))
            * mix(1.0f, kLitUnderground, smoothstep(3.0f, 7.0f, under));
        float3 lit = lh_cold(w.rgb, u.ambient.rgb * info.bank, u.look.x) + reflectance * light
            + light * (u.look.y * w.a);
        color = color * (1.0f - w.a) + lit;
        midVisible *= 1.0f - w.a;
    }
    return color + emissiveTex.read(c.world).rgb;
}

// Warm light keeps its saturation while the cold night loses some and turns violet; a highlight shoulder instead of
// a hard clip; a vignette in whole game pixels.
static float3 lh_grade(float3 color, float3 light, PlaneCoords c, constant CompositeUniforms &u) {
    float warm = saturate(max(light.r, max(light.g, light.b)) * 1.5f);
    float luma = dot(color, float3(0.299f, 0.587f, 0.114f));
    float saturation = mix(u.grade.y, max(u.grade.y, 1.08f), warm);
    color = mix(float3(luma), color, saturation);
    float w = u.grade.x;
    float3 tint = w >= 0.0f ? float3(1.0f + 0.10f * w, 1.0f + 0.02f * w, 1.0f - 0.12f * w)
                            : float3(1.0f - 0.15f * w, 1.0f + 0.10f * w, 1.0f - 0.12f * w);
    color *= mix(tint, float3(1.0f), warm);
    float3 over = max(color - 0.82f, float3(0.0f));
    color = min(color, float3(0.82f)) + 0.18f * (1.0f - exp(-over / 0.18f));
    float2 uv = (float2(c.sky) + 0.5f) / max(u.target.xy, float2(1.0f)) * 2.0f - 1.0f;
    float vignette = 1.0f - u.grade.z * smoothstep(0.45f, 1.3f, length(uv * float2(0.82f, 1.0f)));
    return color * vignette;
}

// Fog B, the foreground, bloom and the grade: everything in front of the world plane and its actors. The grade keeps
// warm what the light warms: the world's light, and the backdrop lights on the share of the mid plane that shows.
static float3 lh_top(float3 color, PlaneCoords c, PixelLight info, constant CompositeUniforms &u,
                     texture2d<float> fogBTex, texture2d<float> fgTex, texture2d<float> bloomTex, float midVisible) {
    float4 fb = fogBTex.read(c.fogB);
    if (fb.a > 0.0f) {
        float3 lit = fb.rgb * (info.bank * u.look.w) + info.light * (u.fog.y * u.fog.z * fb.a);
        color = color * (1.0f - fb.a) + lit;
        midVisible *= 1.0f - fb.a;
    }
    float4 f = fgTex.read(c.fg);
    if (f.a > 0.0f) {
        float3 lit = lh_cold(f.rgb, u.ambient.rgb * info.bank * u.light.w, u.look.x)
            + f.rgb * info.light * u.light.z;
        color = color * (1.0f - f.a) + lit;
        midVisible *= 1.0f - f.a;
    }
    if (u.bloom.y > 0.5f) {
        constexpr sampler linear_clamp(coord::normalized, filter::linear, address::clamp_to_edge);
        color += bloomTex.sample(linear_clamp, c.bloomUV).rgb * u.bloom.x;
    }
    return lh_grade(color, mix(info.light, info.backdrop, midVisible), c, u);
}

constant ushort kDigits[10] = { 0x7B6F, 0x2C97, 0x73E7, 0x73CF, 0x5BC9, 0x79CF, 0x79EF, 0x7249, 0x7BEF, 0x7BCF };

// Two digits of a 3 x 5 pixel font with one column between them.
static bool lh_digit_pixel(int2 local, uint value) {
    if (local.y < 0 || local.y > 4 || local.x < 0 || local.x > 6) {
        return false;
    }
    uint digit = local.x < 3 ? (value / 10u) % 10u : value % 10u;
    int column = local.x < 3 ? local.x : local.x - 4;
    if (column < 0) {
        return false;
    }
    uint bit = 14u - uint(local.y * 3 + column);
    return ((uint(kDigits[digit]) >> bit) & 1u) == 1u;
}

// -GWDebugLights: the full radius in white, the lit edge in gold, the light's index at its centre.
static float3 lh_debug_lights(float3 color, PlaneCoords c, constant CompositeUniforms &u,
                              device const LightQuad *lights) {
    float2 p = float2(c.world) + 0.5f;
    uint count = min(u.debug.w, 64u);
    float litShare = 1.0f - sqrt(max(u.screen.w, 0.0f));
    for (uint i = 0u; i < count; i++) {
        LightQuad l = lights[i];
        float2 o = float2(p.x - l.circle.x, (p.y - l.circle.y) * l.color.w);
        float d = length(o);
        float r = l.circle.z;
        if (abs(d - r) < 0.6f) {
            color = mix(color, float3(1.0f), 0.85f);
        }
        if (abs(d - r * litShare) < 0.6f) {
            color = mix(color, float3(1.0f, 0.82f, 0.3f), 0.9f);
        }
        int2 local = int2(floor(p - l.circle.xy)) + int2(3, 2);
        if (lh_digit_pixel(local, i)) {
            color = float3(1.0f);
        }
    }
    return color;
}

static float3 lh_debug_view(PlaneCoords c, PixelLight info, constant CompositeUniforms &u,
                            texture2d<float> lightTex, texture2d<float> emissiveTex, texture2d<float> bloomTex,
                            texture2d<float> fogATex, texture2d<float> fogBTex) {
    if (u.debug.x == 1u) {
        float4 raw = lightTex.read(c.world);
        float3 l = raw.rgb + u.backdropLight.rgb * raw.a;
        return l / (1.0f + l) * 1.6f;
    }
    if (u.debug.x == 2u) {
        return saturate(emissiveTex.read(c.world).rgb);
    }
    if (u.debug.x == 3u) {
        constexpr sampler linear_clamp(coord::normalized, filter::linear, address::clamp_to_edge);
        return saturate(bloomTex.sample(linear_clamp, c.bloomUV).rgb * 2.0f);
    }
    float4 fa = fogATex.read(c.fogA);
    float4 fb = fogBTex.read(c.fogB);
    float3 a = fa.rgb * (info.bank * u.look.w) + info.light * (u.fog.x * u.fog.z * fa.a);
    float3 b = fb.rgb * (info.bank * u.look.w) + info.light * (u.fog.y * u.fog.z * fb.a);
    return saturate((a * (1.0f - fb.a) + b) * 1.5f);
}

fragment float4 lh_composite_fragment(FullscreenOut in [[stage_in]],
                                      constant CompositeUniforms &u [[buffer(0)]],
                                      device const LightQuad *lights [[buffer(1)]],
                                      texture2d<float> skyTex [[texture(0)]],
                                      texture2d<float> cloudsTex [[texture(1)]],
                                      texture2d<float> farTex [[texture(2)]],
                                      texture2d<float> midTex [[texture(3)]],
                                      texture2d<float> fogATex [[texture(4)]],
                                      texture2d<float> worldTex [[texture(5)]],
                                      texture2d<float> fogBTex [[texture(6)]],
                                      texture2d<float> fgTex [[texture(7)]],
                                      texture2d<float> lightTex [[texture(8)]],
                                      texture2d<float> emissiveTex [[texture(9)]],
                                      texture2d<float> bloomTex [[texture(10)]]) {
    float2 p = in.position.xy;
    bool inset = u.debug.y != 0u && p.x < u.target.x && p.y < u.target.y;
    PlaneCoords c = inset ? lh_inset_coords(p, u) : lh_coords(p, u);
    PixelLight info = lh_pixel_light(c, u, lightTex);
    if (u.debug.x != 0u && !inset) {
        float3 view = lh_debug_view(c, info, u, lightTex, emissiveTex, bloomTex, fogATex, fogBTex);
        return float4(view, 1.0f);
    }
    float midVisible = 0.0f;
    float3 color = lh_base(c, info, u, skyTex, cloudsTex, farTex, midTex, fogATex, worldTex, emissiveTex, midVisible);
    color = lh_top(color, c, info, u, fogBTex, fgTex, bloomTex, midVisible);
    if (u.debug.z != 0u) {
        color = lh_debug_lights(color, c, u, lights);
    }
    if (inset && (p.x >= u.target.x - 1.0f || p.y >= u.target.y - 1.0f)) {
        color = float3(1.0f, 0.82f, 0.3f);
    }
    return float4(saturate(color), 1.0f);
}

// MARK: Actors

struct ActorQuad {
    float4 rect;    // x, y, width, height in device pixels, origin top-left
    float4 texel;   // u0, v0, u1, v1 in atlas texels (u0 > u1 when mirrored)
    float4 tint;    // rgb multiplier, alpha
    float4 flags;   // x: 1 for emissive actors (eye glints), y: lit by the gameplay light field
};

struct ActorOut {
    float4 position [[position]];
    float2 texel;
    float4 tint [[flat]];
    float4 flags [[flat]];
};

vertex ActorOut lh_actor_vertex(uint vid [[vertex_id]],
                                uint iid [[instance_id]],
                                device const ActorQuad *actors [[buffer(0)]],
                                constant CompositeUniforms &u [[buffer(1)]]) {
    ActorQuad q = actors[iid];
    float2 corner = float2(float(vid & 1u), float((vid >> 1) & 1u));
    ActorOut out;
    out.position = lh_ndc(q.rect.xy + corner * q.rect.zw, u.screen.xy);
    out.texel = mix(q.texel.xy, q.texel.zw, corner);
    out.tint = q.tint;
    out.flags = q.flags;
    return out;
}

// An actor's texels stay s x s blocks (its quad is size x s device pixels); it is lit by the light buffer under each
// of its pixels and composited into the full stack, so the fog in front and the foreground still cover it.
fragment float4 lh_actor_fragment(ActorOut in [[stage_in]],
                                  constant CompositeUniforms &u [[buffer(0)]],
                                  device const LightQuad *lights [[buffer(1)]],
                                  texture2d<float> skyTex [[texture(0)]],
                                  texture2d<float> cloudsTex [[texture(1)]],
                                  texture2d<float> farTex [[texture(2)]],
                                  texture2d<float> midTex [[texture(3)]],
                                  texture2d<float> fogATex [[texture(4)]],
                                  texture2d<float> worldTex [[texture(5)]],
                                  texture2d<float> fogBTex [[texture(6)]],
                                  texture2d<float> fgTex [[texture(7)]],
                                  texture2d<float> lightTex [[texture(8)]],
                                  texture2d<float> emissiveTex [[texture(9)]],
                                  texture2d<float> bloomTex [[texture(10)]],
                                  texture2d<float> atlas [[texture(11)]]) {
    uint2 t = uint2(max(in.texel, float2(0.0f)));
    float4 texel = atlas.read(t);
    if (texel.a < 0.5f || in.tint.a <= 0.003f) {
        discard_fragment();
    }
    float2 p = in.position.xy;
    PlaneCoords c = lh_coords(p, u);
    PixelLight info = lh_pixel_light(c, u, lightTex);
    float midVisible = 0.0f;
    float3 base = lh_base(c, info, u, skyTex, cloudsTex, farTex, midTex, fogATex, worldTex, emissiveTex, midVisible);
    float3 albedo = texel.rgb * in.tint.rgb;
    float3 cold = lh_cold(albedo, u.ambient.rgb * info.bank, u.look.x);
    float3 lit = in.flags.x > 0.5f ? albedo : cold + albedo * info.light + info.light * u.look.y;
    float3 color = mix(base, lit, saturate(in.tint.a));
    midVisible *= 1.0f - saturate(in.tint.a);
    color = lh_top(color, c, info, u, fogBTex, fgTex, bloomTex, midVisible);
    if (u.debug.z != 0u) {
        color = lh_debug_lights(color, c, u, lights);
    }
    return float4(saturate(color), 1.0f);
}
