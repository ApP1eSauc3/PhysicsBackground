//
//  PhysicsLighting.swift
//  PhysicsBackground
//
//  Blinn-Phong lighting parameters for the normal-mapped 2.5D shading pass.
//  Treat V concentration as a height field, compute surface normals via
//  central-difference Sobel, and shade with a single orbiting point light.
//
//  Usage:
//    SomeView().physicsBackground(.coral, lighting: .default)
//    SomeView().physicsBackground(.labyrinth, lighting: .dramatic)
//    SomeView().physicsBackground(.nebula, lighting: .off)   // flat, v1 behaviour
//    SomeView().physicsBackground(.coral, lighting: PhysicsLighting(
//        ambient: 0.4, diffuse: 0.6, specular: 0.5, heightScale: 6.0
//    ))
//

import simd

// MARK: - PhysicsLighting

/// Controls the Blinn-Phong lighting pass applied on top of the reaction-diffusion output.
/// V concentration is treated as a height field; surface normals are computed per-pixel
/// via central differences and shaded with an animated directional light.
public struct PhysicsLighting {

    /// RGB colour of the light source in linear space.
    public var colour:      SIMD3<Float>

    /// Ambient term — minimum brightness applied to all pixels. [0–1]
    public var ambient:     Float

    /// Diffuse term — Lambertian shading from surface angle to light. [0–1]
    public var diffuse:     Float

    /// Specular highlight intensity. [0–1]
    public var specular:    Float

    /// Phong exponent. Higher = tighter, sharper specular highlights.
    public var shininess:   Float

    /// Height-field exaggeration applied before normal computation.
    /// 0 = flat surface; 8 = deep, pronounced relief.
    public var heightScale: Float

    /// Elevation of the light above the surface plane, in radians.
    /// π/4 = 45°, π/2 = directly overhead (no directional shading).
    public var elevation:   Float

    /// Orbits the light around the Z axis each frame.
    /// Creates parallax motion that reveals the 3D surface over time.
    public var animated:    Bool

    /// Full orbits per minute when `animated` is true.
    public var orbitSpeed:  Float

    public init(
        colour:      SIMD3<Float> = SIMD3(1.00, 0.95, 0.88),
        ambient:     Float        = 0.35,
        diffuse:     Float        = 0.65,
        specular:    Float        = 0.40,
        shininess:   Float        = 32.0,
        heightScale: Float        = 4.0,
        elevation:   Float        = .pi / 4,
        animated:    Bool         = true,
        orbitSpeed:  Float        = 0.25
    ) {
        self.colour      = colour
        self.ambient     = ambient
        self.diffuse     = diffuse
        self.specular    = specular
        self.shininess   = shininess
        self.heightScale = heightScale
        self.elevation   = elevation
        self.animated    = animated
        self.orbitSpeed  = orbitSpeed
    }
}

// MARK: - Built-in lighting presets

extension PhysicsLighting {

    /// Gentle orbit, warm white light. Works well with all presets.
    public static let `default` = PhysicsLighting()

    /// Deep relief, high contrast specular. Best with coral and labyrinth.
    public static let dramatic = PhysicsLighting(
        colour:      SIMD3(1.00, 0.88, 0.72),
        ambient:     0.20,
        diffuse:     0.80,
        specular:    0.65,
        shininess:   64.0,
        heightScale: 7.0,
        elevation:   .pi / 5,
        animated:    true,
        orbitSpeed:  0.15
    )

    /// Soft fill — subtle depth, low contrast. Ideal as a UI background.
    public static let soft = PhysicsLighting(
        colour:      SIMD3(0.88, 0.94, 1.00),
        ambient:     0.55,
        diffuse:     0.45,
        specular:    0.10,
        shininess:   16.0,
        heightScale: 2.5,
        elevation:   .pi / 3,
        animated:    true,
        orbitSpeed:  0.10
    )

    /// No lighting — flat colour output identical to v1 behaviour.
    public static let off = PhysicsLighting(
        colour:      SIMD3(1, 1, 1),
        ambient:     1.0,
        diffuse:     0.0,
        specular:    0.0,
        shininess:   1.0,
        heightScale: 0.0,
        elevation:   .pi / 4,
        animated:    false,
        orbitSpeed:  0.0
    )

    /// Named presets for the demo picker and any consumer wanting a list.
    public static let allNamed: [(String, PhysicsLighting)] = [
        ("Off",      .off),
        ("Soft",     .soft),
        ("Default",  .default),
        ("Dramatic", .dramatic),
    ]

    /// True when any lighting contribution beyond a flat ambient pass is active.
    var isActive: Bool { diffuse > 0 || specular > 0 }
}
