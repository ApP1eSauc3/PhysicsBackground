//
//  GrayScottSimulation.metal
//  PhysicsBackground
//
//  GPU kernels for the Gray-Scott reaction-diffusion system.
//  Compiled by SPM via Package.swift `.process("Shaders")` into
//  the package bundle's default.metallib, loaded by:
//
//    device.makeDefaultLibrary(bundle: Bundle.module)
//
//  ── Reaction-diffusion model ──────────────────────────────────────────────
//  Two chemicals U (activator) and V (inhibitor) evolve on a 2D grid:
//
//    dU/dt = Du·∇²U  −  U·V²  +  f·(1 − U)
//    dV/dt = Dv·∇²V  +  U·V²  −  (f + k)·V
//
//  The V concentration is what we visualise — it forms the visible patterns.
//  Different (f, k) parameter pairs produce qualitatively distinct pattern classes:
//    coral      (f=0.0545, k=0.0630)  — branching organic growth
//    mitosis    (f=0.0367, k=0.0649)  — oscillating dividing spots
//    labyrinth  (f=0.0600, k=0.0620)  — dense parallel stripes
//    turbulence (f=0.0780, k=0.0610)  — chaotic worm dynamics
//    nebula     (f=0.0280, k=0.0550)  — sparse slow-drifting halos
//
//  ── Kernel map ────────────────────────────────────────────────────────────
//   grayScottStep      — advances simulation one dt (ping → pong)
//   colorize           — maps V → RGB via three-stop gradient
//   vertexPassthrough  — full-screen NDC quad, no vertex buffer
//   fragmentPassthrough — samples display texture to drawable
//  ─────────────────────────────────────────────────────────────────────────

#include <metal_stdlib>
using namespace metal;

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Uniform structs
// Byte layout must match the Swift structs SimUniforms and ColourUniforms
// in GrayScottRenderer.swift exactly.
// ─────────────────────────────────────────────────────────────────────────────

struct SimUniforms {
    float Du;
    float Dv;
    float feed;
    float kill;
    float dt;
    uint  width;
    uint  height;
};

// float4 used throughout — Metal aligns float3 to 16 bytes (same as float4).
// Swift uses SIMD4<Float> to match.
struct ColourUniforms {
    float4 low;
    float4 mid;
    float4 high;
    float  midPoint;
    float  gamma;
};


// ─────────────────────────────────────────────────────────────────────────────
// MARK: - grayScottStep
//
// Advances the simulation by one dt using a 5-point discrete Laplacian:
//   ∇²f ≈ f(left) + f(right) + f(up) + f(down) − 4·f(centre)
//
// Texture layout: rgba16Float — R = U, G = V, B/A unused.
// Boundary conditions: periodic (wrap-around) — patterns tile seamlessly,
// no dead zones at screen edges.
// ─────────────────────────────────────────────────────────────────────────────

kernel void grayScottStep(
    texture2d<float, access::read>  inTex  [[ texture(0) ]],
    texture2d<float, access::write> outTex [[ texture(1) ]],
    constant SimUniforms& s                [[ buffer(0)  ]],
    uint2 gid                              [[ thread_position_in_grid ]]
)
{
    if (gid.x >= s.width || gid.y >= s.height) return;

    float4 c = inTex.read(gid);
    float  A = c.r;
    float  B = c.g;

    uint x = gid.x, y = gid.y;
    uint W = s.width, H = s.height;

    float4 L = inTex.read(uint2((x + W - 1u) % W, y));
    float4 R = inTex.read(uint2((x + 1u) % W,     y));
    float4 U = inTex.read(uint2(x, (y + H - 1u) % H));
    float4 D = inTex.read(uint2(x, (y + 1u) % H));

    float lapA = L.r + R.r + U.r + D.r - 4.0f * A;
    float lapB = L.g + R.g + U.g + D.g - 4.0f * B;

    float uvv = A * B * B;   // autocatalytic term

    float newA = A + (s.Du * lapA - uvv + s.feed * (1.0f - A)) * s.dt;
    float newB = B + (s.Dv * lapB + uvv - (s.feed + s.kill) * B) * s.dt;

    outTex.write(float4(saturate(newA), saturate(newB), 0.0f, 1.0f), gid);
}


// ─────────────────────────────────────────────────────────────────────────────
// MARK: - colorize
//
// Maps V concentration to RGB via a three-stop piecewise linear gradient:
//   [0, midPoint)  → low  → mid
//   [midPoint, 1]  → mid  → high
//
// Gamma is applied first — γ > 1 sharpens pattern edges (more black background),
// γ < 1 spreads colour into the background (more saturated overall feel).
//
// A specular bloom at V > 0.82 simulates the luminous core of a neon tube.
// ─────────────────────────────────────────────────────────────────────────────

kernel void colorize(
    texture2d<float, access::read>  simTex [[ texture(0) ]],
    texture2d<float, access::write> outTex [[ texture(1) ]],
    constant ColourUniforms& col           [[ buffer(0)  ]],
    uint2 gid                              [[ thread_position_in_grid ]]
)
{
    float v  = simTex.read(gid).g;
    v        = pow(saturate(v), col.gamma);

    float3 rgb;
    float  mp = col.midPoint;

    if (v < mp) {
        rgb = mix(col.low.rgb, col.mid.rgb, v / mp);
    } else {
        rgb = mix(col.mid.rgb, col.high.rgb, (v - mp) / (1.0f - mp));
    }

    // Specular bloom — neon tube core brightens toward white at high V
    float bloom = smoothstep(0.82f, 1.0f, v);
    rgb = mix(rgb, float3(1.0f), bloom * 0.35f);

    outTex.write(float4(rgb, 1.0f), gid);
}


// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Full-screen render pass
//
// Draws the colorized display texture to the MTKView drawable.
// Positions generated from vertex_id — no vertex buffer required.
//
// NDC ↔ UV (Metal: texture (0,0) = top-left):
//   vid  pos         uv
//   0    (-1, -1)    (0, 1)   bottom-left
//   1    ( 1, -1)    (1, 1)   bottom-right
//   2    (-1,  1)    (0, 0)   top-left
//   3    ( 1,  1)    (1, 0)   top-right
// Triangle strip (0,1,2),(1,2,3) covers full clip space.
// ─────────────────────────────────────────────────────────────────────────────

struct VertexOut {
    float4 position [[ position ]];
    float2 uv;
};

vertex VertexOut vertexPassthrough(uint vid [[ vertex_id ]]) {
    constexpr float2 pos[4] = {
        float2(-1, -1), float2(1, -1),
        float2(-1,  1), float2(1,  1)
    };
    constexpr float2 uvs[4] = {
        float2(0, 1), float2(1, 1),
        float2(0, 0), float2(1, 0)
    };
    VertexOut out;
    out.position = float4(pos[vid], 0, 1);
    out.uv       = uvs[vid];
    return out;
}

fragment float4 fragmentPassthrough(
    VertexOut        in  [[ stage_in   ]],
    texture2d<float> tex [[ texture(0) ]]
)
{
    constexpr sampler s(filter::linear, address::clamp_to_edge);
    return tex.sample(s, in.uv);
}


// ─────────────────────────────────────────────────────────────────────────────
// MARK: - LightingUniforms
//
// Byte layout must match LightingUniforms in GrayScottRenderer.swift exactly.
// Both float4 members provide 16-byte alignment; the five trailing floats
// (20 bytes) bring the total to 52, padded by the compiler to 64 bytes.
// Swift's MemoryLayout<LightingUniforms>.stride is also 64 bytes. ✓
// ─────────────────────────────────────────────────────────────────────────────

struct LightingUniforms {
    float4 lightDir;      // xyz = normalised direction toward light, w unused
    float4 lightColour;   // xyz = linear RGB, w unused
    float  ambient;
    float  diffuse;
    float  specular;
    float  shininess;     // Phong exponent
    float  heightScale;   // V concentration exaggeration before normal computation
    // 12 bytes implicit padding → struct total = 64 bytes
};


// ─────────────────────────────────────────────────────────────────────────────
// MARK: - colorizeAndLight
//
// Combines the colourize pass with Blinn-Phong shading in a single dispatch.
// V concentration is treated as a height field; surface normals are derived
// via 5-tap central differences with periodic (wrap) boundary conditions —
// matching the boundary treatment in grayScottStep.
//
// Shading model:
//   output = lightColour × (ambient × base
//                         + diffuse × max(N·L, 0) × base
//                         + specular × max(N·H, 0)^shininess)
//
// When lighting is disabled (diffuse = specular = 0, ambient = 1):
//   output = lightColour × base = base   (for white light)
//   — identical result to the original colorize kernel.
// ─────────────────────────────────────────────────────────────────────────────

kernel void colorizeAndLight(
    texture2d<float, access::read>  simTex  [[ texture(0) ]],
    texture2d<float, access::write> outTex  [[ texture(1) ]],
    constant ColourUniforms&        col     [[ buffer(0)  ]],
    constant LightingUniforms&      lit     [[ buffer(1)  ]],
    uint2 gid                               [[ thread_position_in_grid ]]
)
{
    const uint W = simTex.get_width();
    const uint H = simTex.get_height();
    if (gid.x >= W || gid.y >= H) return;

    const uint x = gid.x;
    const uint y = gid.y;

    // ── V concentration at centre and cardinal neighbours ────────────────────
    // Periodic boundary conditions match grayScottStep — no dead zones at edges.
    float vC = simTex.read(gid                                              ).g;
    float vL = simTex.read(uint2((x + W - 1u) % W, y                      )).g;
    float vR = simTex.read(uint2((x + 1u)     % W, y                      )).g;
    float vU = simTex.read(uint2(x,           (y + H - 1u) % H            )).g;
    float vD = simTex.read(uint2(x,           (y + 1u)     % H            )).g;

    // ── Surface normal from height field (central difference) ────────────────
    // Treat V * heightScale as elevation.
    // dh/dx = (vR − vL) / 2 × scale;  normal.x = −dh/dx  (slopes away from high)
    // dh/dy = (vD − vU) / 2 × scale;  normal.y = −dh/dy
    // normal.z = 1 (pointing toward viewer on a nearly-flat surface)
    float dhdx = (vR - vL) * 0.5f * lit.heightScale;
    float dhdy = (vD - vU) * 0.5f * lit.heightScale;
    float3 N   = normalize(float3(-dhdx, -dhdy, 1.0f));

    // ── Base colour — identical to the colorize kernel ────────────────────────
    float  v   = pow(saturate(vC), col.gamma);
    float  mp  = col.midPoint;
    float3 base;
    if (v < mp) {
        base = mix(col.low.rgb, col.mid.rgb, v / mp);
    } else {
        base = mix(col.mid.rgb, col.high.rgb, (v - mp) / (1.0f - mp));
    }
    // Specular bloom — neon tube core brightens toward white at high V
    float bloom = smoothstep(0.82f, 1.0f, v);
    base = mix(base, float3(1.0f), bloom * 0.35f);

    // ── Blinn-Phong shading ───────────────────────────────────────────────────
    // L: direction toward light (pre-normalised, set CPU-side each frame)
    // V: orthographic view direction — always straight up the +Z axis
    // H: half-vector for specular
    float3 L    = normalize(lit.lightDir.xyz);
    float3 view = float3(0.0f, 0.0f, 1.0f);
    float3 HH   = normalize(L + view);

    float  diff = max(dot(N, L),  0.0f);
    float  spec = pow(max(dot(N, HH), 0.0f), lit.shininess);

    float3 rgb = lit.lightColour.xyz * (
          lit.ambient  * base
        + lit.diffuse  * diff * base
        + lit.specular * spec
    );

    outTex.write(float4(rgb, 1.0f), gid);
}
