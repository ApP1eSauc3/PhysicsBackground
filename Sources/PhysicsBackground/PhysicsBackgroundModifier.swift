//
//  PhysicsBackgroundModifier.swift
//  PhysicsBackground
//
//  The public surface of the package.
//  Import PhysicsBackground, call .physicsBackground(), done.
//
//  ─── API summary ─────────────────────────────────────────────────────────
//
//  // Preset, default palette, default lighting
//  SomeView().physicsBackground(.coral)
//
//  // Preset + lighting preset
//  SomeView().physicsBackground(.coral, lighting: .dramatic)
//
//  // Preset + named palette
//  SomeView().physicsBackground(.mitosis, scheme: .neonCyan)
//
//  // Preset + palette + lighting
//  SomeView().physicsBackground(.labyrinth, scheme: .neonCyan, lighting: .soft)
//
//  // Preset + opacity
//  SomeView().physicsBackground(.labyrinth, opacity: 0.6)
//
//  // Preset + palette + opacity
//  SomeView().physicsBackground(.turbulence, scheme: .neonRed, opacity: 0.8)
//
//  // Fully custom config
//  SomeView().physicsBackground(PhysicsConfig(preset: .coral, scheme: myScheme))
//
//  ─────────────────────────────────────────────────────────────────────────
//
//  Preset changes trigger `.id(config.preset)` → SwiftUI destroys and recreates
//  MetalSimView → makeCoordinator() → fresh renderer → fresh seed.
//  Without the `.id`, SwiftUI would reuse the old coordinator and old state.
//
//  Lighting changes are applied via updateUIView → coordinator.updateLighting(_:)
//  and take effect on the next draw call without resetting the simulation.
//

import SwiftUI

// MARK: - PhysicsBackgroundModifier

struct PhysicsBackgroundModifier: ViewModifier {
    let config:  PhysicsConfig
    let opacity: Double

    func body(content: Content) -> some View {
        ZStack {
            MetalSimView(config: config)
                .id(config.preset)
                .opacity(opacity)
                .ignoresSafeArea()
            content
        }
    }
}

// MARK: - View extensions (public API)

extension View {

    /// Live physics background using the preset's default colour palette and lighting.
    public func physicsBackground(_ preset: PhysicsPreset) -> some View {
        modifier(PhysicsBackgroundModifier(
            config:  PhysicsConfig(preset: preset),
            opacity: 1.0
        ))
    }

    /// Live physics background with a specific lighting setup.
    public func physicsBackground(
        _ preset:  PhysicsPreset,
        lighting:  PhysicsLighting
    ) -> some View {
        modifier(PhysicsBackgroundModifier(
            config:  PhysicsConfig(preset: preset, lighting: lighting),
            opacity: 1.0
        ))
    }

    /// Live physics background with a specific colour scheme.
    public func physicsBackground(
        _ preset: PhysicsPreset,
        scheme:   PhysicsColourScheme
    ) -> some View {
        modifier(PhysicsBackgroundModifier(
            config:  PhysicsConfig(preset: preset, scheme: scheme),
            opacity: 1.0
        ))
    }

    /// Live physics background with a specific colour scheme and lighting.
    public func physicsBackground(
        _ preset:  PhysicsPreset,
        scheme:    PhysicsColourScheme,
        lighting:  PhysicsLighting
    ) -> some View {
        modifier(PhysicsBackgroundModifier(
            config:  PhysicsConfig(preset: preset, scheme: scheme, lighting: lighting),
            opacity: 1.0
        ))
    }

    /// Live physics background at a specific opacity (0–1).
    /// Values ≤ 0.5 produce a subtle texture behind existing backgrounds.
    public func physicsBackground(
        _ preset:  PhysicsPreset,
        opacity:   Double
    ) -> some View {
        modifier(PhysicsBackgroundModifier(
            config:  PhysicsConfig(preset: preset),
            opacity: opacity
        ))
    }

    /// Live physics background with full control over scheme and opacity.
    public func physicsBackground(
        _ preset:  PhysicsPreset,
        scheme:    PhysicsColourScheme,
        opacity:   Double
    ) -> some View {
        modifier(PhysicsBackgroundModifier(
            config:  PhysicsConfig(preset: preset, scheme: scheme),
            opacity: opacity
        ))
    }

    /// Live physics background from a fully assembled PhysicsConfig.
    public func physicsBackground(
        _ config:  PhysicsConfig,
        opacity:   Double = 1.0
    ) -> some View {
        modifier(PhysicsBackgroundModifier(config: config, opacity: opacity))
    }
}
