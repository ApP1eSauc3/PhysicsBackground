//
//  PhysicsColourScheme.swift
//  PhysicsBackground
//
//  Defines how V concentration (0→1) maps to visible colour.
//  SIMD4<Float> throughout — matches Metal's float4 alignment exactly (16 bytes).
//  The .w component is unused padding required for GPU struct alignment.
//
//  Usage:
//    PhysicsColourScheme.neonPurple     // vivid purple on black (default)
//    PhysicsColourScheme.neonCyan       // cyan on black — great for tech/DJ UIs
//    PhysicsColourScheme.neonRed        // red on black — energy/urgency
//    PhysicsColourScheme.neonGold       // amber on black — luxury/warmth
//    PhysicsColourScheme.ice            // cool blue-white on near-black
//    PhysicsColourScheme.monochrome     // white on black — minimal
//    PhysicsColourScheme(low:mid:high:) // fully custom
//

import simd

// MARK: - PhysicsColourScheme

/// Three-stop gradient that maps V concentration to RGB colour in the shader.
/// Struct layout matches `ColourUniforms` in GrayScottSimulation.metal exactly.
public struct PhysicsColourScheme {

    /// Colour at V ≈ 0 (background — typically near-black).
    public var low:      SIMD4<Float>
    /// Colour at V ≈ midPoint (transition zone — typically a dark accent).
    public var mid:      SIMD4<Float>
    /// Colour at V ≈ 1 (pattern peak — the accent colour).
    public var high:     SIMD4<Float>
    /// Where `mid` sits in [0, 1] V space. Lower = accent blooms sooner.
    public var midPoint: Float
    /// Gamma applied to V before mapping. >1 sharpens edges; <1 softens them.
    public var gamma:    Float

    public init(
        low:      SIMD4<Float>,
        mid:      SIMD4<Float>,
        high:     SIMD4<Float>,
        midPoint: Float = 0.30,
        gamma:    Float = 1.6
    ) {
        self.low      = low
        self.mid      = mid
        self.high     = high
        self.midPoint = midPoint
        self.gamma    = gamma
    }
}

// MARK: - Built-in palettes
// All values are linear RGB, derived from standard HSB→RGB conversion.
// The naming is aesthetic, not brand-specific — use whatever fits your project.

extension PhysicsColourScheme {

    /// Black → dark purple → neon purple. Versatile, works on any dark-theme app.
    public static let neonPurple = PhysicsColourScheme(
        low:      SIMD4(0.000, 0.000, 0.000, 0),
        mid:      SIMD4(0.312, 0.160, 0.400, 0),   // H278 S60 B40
        high:     SIMD4(0.633, 0.155, 0.910, 0),   // H278 S83 B91
        midPoint: 0.30,
        gamma:    1.6
    )

    /// Black → dark teal → electric cyan. Tech/music/nightlife aesthetic.
    public static let neonCyan = PhysicsColourScheme(
        low:      SIMD4(0.000, 0.000, 0.000, 0),
        mid:      SIMD4(0.040, 0.200, 0.260, 0),   // H185 S85 B26
        high:     SIMD4(0.000, 0.917, 1.000, 0),   // H185 S100 B100
        midPoint: 0.25,
        gamma:    2.0
    )

    /// Black → dark red → vivid red. Energy, urgency, intensity.
    public static let neonRed = PhysicsColourScheme(
        low:      SIMD4(0.000, 0.000, 0.000, 0),
        mid:      SIMD4(0.380, 0.050, 0.050, 0),   // H0 S87 B38
        high:     SIMD4(1.000, 0.080, 0.080, 0),   // H0 S92 B100
        midPoint: 0.28,
        gamma:    1.8
    )

    /// Black → dark amber → neon gold. Luxury, warmth, premium feel.
    public static let neonGold = PhysicsColourScheme(
        low:      SIMD4(0.000, 0.000, 0.000, 0),
        mid:      SIMD4(0.360, 0.220, 0.000, 0),   // H37 S100 B36
        high:     SIMD4(1.000, 0.750, 0.000, 0),   // H45 S100 B100
        midPoint: 0.30,
        gamma:    1.5
    )

    /// Near-black → deep navy → ice blue-white. Clean, clinical, cool.
    public static let ice = PhysicsColourScheme(
        low:      SIMD4(0.010, 0.015, 0.030, 0),
        mid:      SIMD4(0.100, 0.200, 0.500, 0),
        high:     SIMD4(0.750, 0.900, 1.000, 0),
        midPoint: 0.35,
        gamma:    1.3
    )

    /// Black → dark grey → white. Minimal, design-system agnostic.
    public static let monochrome = PhysicsColourScheme(
        low:      SIMD4(0.000, 0.000, 0.000, 0),
        mid:      SIMD4(0.200, 0.200, 0.200, 0),
        high:     SIMD4(1.000, 1.000, 1.000, 0),
        midPoint: 0.40,
        gamma:    1.2
    )

    /// The default palette — neon purple on black.
    public static let `default` = neonPurple
}
