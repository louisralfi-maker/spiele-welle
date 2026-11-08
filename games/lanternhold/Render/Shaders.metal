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
