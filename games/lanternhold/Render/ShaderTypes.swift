/// Swift twins of the structs in `Shaders.metal`. Every field is 4 bytes or a 16-byte SIMD4, so the layouts match the
/// Metal side without padding surprises; `ShaderLayoutTests` checks the strides.

/// `PatternUniforms`: the pixel-grid test pattern.
struct PatternUniforms: Sendable {
    var scale: UInt32
    var width: UInt32
    var height: UInt32
    var barRows: UInt32
}

/// `QuadInstance`: one textured quad, `rect` = x, y, width, height in target pixels (origin top-left), `uv` = u0, v0, u1, v1.
struct QuadInstance: Sendable {
    var rect: SIMD4<Float>
    var uv: SIMD4<Float>
}

/// `LightInstance`: one additive radial light, `circle` = centre x, centre y, radius (target pixels), intensity;
/// `color` = r, g, b, unused.
struct LightInstance: Sendable {
    var circle: SIMD4<Float>
    var color: SIMD4<Float>
}
