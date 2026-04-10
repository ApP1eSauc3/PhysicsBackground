//
//  PhysicsConfig.swift
//  PhysicsBackground
//
//  Bundles a PhysicsPreset, PhysicsColourScheme, and PhysicsLighting.
//  This is the single object that travels through the view layer.
//

import Foundation

// MARK: - PhysicsConfig

/// Combines simulation parameters (preset), colour mapping (scheme),
/// and 2.5D lighting (lighting). Pass this to `physicsBackground(_:)` or
/// `MetalSimView(config:)`.
public struct PhysicsConfig {

    public let preset:   PhysicsPreset
    public let scheme:   PhysicsColourScheme
    public let lighting: PhysicsLighting

    /// Preset with the default colour scheme and default lighting.
    public init(preset: PhysicsPreset, lighting: PhysicsLighting = .default) {
        self.preset   = preset
        self.scheme   = preset.defaultScheme
        self.lighting = lighting
    }

    /// Preset with an explicit colour scheme and optional lighting.
    public init(
        preset:   PhysicsPreset,
        scheme:   PhysicsColourScheme,
        lighting: PhysicsLighting = .default
    ) {
        self.preset   = preset
        self.scheme   = scheme
        self.lighting = lighting
    }
}

// MARK: - Default scheme per preset

extension PhysicsPreset {
    /// Each preset ships with a colour scheme that suits its visual character.
    /// Override via `PhysicsConfig(preset:scheme:)` when needed.
    public var defaultScheme: PhysicsColourScheme {
        switch self {
        case .coral:
            // Slow-branching coral looks richest with sharp neon-purple edges.
            return PhysicsColourScheme(
                low:      .init(0.000, 0.000, 0.000, 0),
                mid:      .init(0.312, 0.160, 0.400, 0),
                high:     .init(0.633, 0.155, 0.910, 0),
                midPoint: 0.30,
                gamma:    1.6
            )
        case .mitosis:
            // Spots pop most clearly with tight gamma and cyan endpoint.
            return PhysicsColourScheme(
                low:      .init(0.000, 0.000, 0.000, 0),
                mid:      .init(0.040, 0.200, 0.260, 0),
                high:     .init(0.000, 0.917, 1.000, 0),
                midPoint: 0.25,
                gamma:    2.0
            )
        case .labyrinth:
            // Stripes read best at lower contrast — softer purple, mid pushed later.
            return PhysicsColourScheme(
                low:      .init(0.000, 0.000, 0.000, 0),
                mid:      .init(0.180, 0.080, 0.280, 0),
                high:     .init(0.633, 0.155, 0.910, 0),
                midPoint: 0.40,
                gamma:    1.2
            )
        case .turbulence:
            // Over-driven palette — mid is boosted, high almost white. Feels electric.
            return PhysicsColourScheme(
                low:      .init(0.000, 0.000, 0.000, 0),
                mid:      .init(0.500, 0.100, 0.750, 0),
                high:     .init(0.850, 0.500, 1.000, 0),
                midPoint: 0.20,
                gamma:    0.8
            )
        case .nebula:
            // Barely-there — nearly invisible motion, subtle dark-purple veil.
            return PhysicsColourScheme(
                low:      .init(0.000, 0.000, 0.000, 0),
                mid:      .init(0.120, 0.060, 0.180, 0),
                high:     .init(0.400, 0.100, 0.600, 0),
                midPoint: 0.50,
                gamma:    1.0
            )
        }
    }
}
