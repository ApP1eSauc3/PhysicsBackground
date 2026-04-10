//
//  PhysicsCanvas.swift
//  PhysicsBackground
//
//  A full-screen interactive simulation canvas.
//  Touch paints V concentration directly into the simulation field —
//  drag to draw reaction-diffusion patterns in real time.
//
//  Includes a "dual-field" mode that runs two independent simulations
//  (each with its own preset + colour scheme) and composites them via
//  additive blending. The two chemical fields evolve independently but
//  share the same screen — producing interference patterns between the
//  two reaction-diffusion systems.
//
//  Usage:
//    // Single interactive canvas
//    PhysicsCanvas(preset: .turbulence, lighting: .dramatic)
//
//    // Dual-field — two simulations blended
//    PhysicsCanvas(
//        primary:   PhysicsConfig(preset: .coral,     scheme: .neonPurple),
//        secondary: PhysicsConfig(preset: .labyrinth, scheme: .neonCyan),
//        blendOpacity: 0.55
//    )
//

import SwiftUI

// MARK: - PhysicsCanvas (single field, interactive)

public struct PhysicsCanvas: View {

    private let config: PhysicsConfig
    @StateObject private var seeds = PhysicsSeedController()

    public init(
        preset:   PhysicsPreset   = .turbulence,
        scheme:   PhysicsColourScheme? = nil,
        lighting: PhysicsLighting = .dramatic
    ) {
        self.config = PhysicsConfig(
            preset:   preset,
            scheme:   scheme ?? preset.defaultScheme,
            lighting: lighting)
    }

    public var body: some View {
        MetalSimView(
            config:              config,
            seedController:      seeds,
            interactionsEnabled: true
        )
        .id(config.preset)
        .ignoresSafeArea()
        .overlay(alignment: .bottomLeading) {
            Text("DRAW")
                .font(.system(.caption2, design: .monospaced).weight(.medium))
                .foregroundStyle(.white.opacity(0.25))
                .tracking(2)
                .padding(20)
        }
    }
}

// MARK: - PhysicsDualField

/// Two independent simulations composited additively.
/// Each field evolves with its own parameters; their V channels are
/// added together in the colour mapping, producing interference fringes
/// where the two pattern systems interact.
public struct PhysicsDualField: View {

    private let primary:      PhysicsConfig
    private let secondary:    PhysicsConfig
    private let blendOpacity: Double

    @StateObject private var seeds = PhysicsSeedController()

    public init(
        primary:      PhysicsConfig   = PhysicsConfig(preset: .coral,     scheme: .neonPurple),
        secondary:    PhysicsConfig   = PhysicsConfig(preset: .labyrinth, scheme: .neonCyan),
        blendOpacity: Double          = 0.55
    ) {
        self.primary      = primary
        self.secondary    = secondary
        self.blendOpacity = blendOpacity
    }

    public var body: some View {
        ZStack {
            // Primary field — full opacity, interactive seeding
            MetalSimView(
                config:              primary,
                seedController:      seeds,
                interactionsEnabled: true
            )
            .id("primary-\(primary.preset.id)")
            .ignoresSafeArea()

            // Secondary field — additive blend, same seed triggers
            // Both fields receive the same seeds, so touch creates
            // reactions in both systems simultaneously.
            MetalSimView(
                config:         secondary,
                seedController: seeds
            )
            .id("secondary-\(secondary.preset.id)")
            .ignoresSafeArea()
            .blendMode(.screen)    // additive: f = 1-(1-a)(1-b), never darker
            .opacity(blendOpacity)
        }
    }
}

// MARK: - PhysicsRevealView
//
// Uses the simulation as a dynamic reveal mask over arbitrary content.
// V concentration drives alpha: high-V pixels reveal the content beneath,
// low-V pixels are transparent. As the pattern evolves, the content is
// progressively revealed in the shape of the reaction-diffusion structures.

public struct PhysicsRevealView<Content: View>: View {

    private let preset:    PhysicsPreset
    private let lighting:  PhysicsLighting
    private let threshold: Double      // V level at which reveal begins (0–1)
    private let content:   Content

    public init(
        preset:    PhysicsPreset   = .coral,
        lighting:  PhysicsLighting = .off,
        threshold: Double          = 0.3,
        @ViewBuilder content: () -> Content
    ) {
        self.preset    = preset
        self.lighting  = lighting
        self.threshold = threshold
        self.content   = content()
    }

    public var body: some View {
        content
            .mask(
                // The simulation's colour output (brighter = higher V) acts as
                // the alpha mask: bright regions reveal, dark regions hide.
                MetalSimView(config: PhysicsConfig(preset: preset, lighting: lighting))
                    .id(preset)
                    .allowsHitTesting(false)
                    .contrast(1.0 / max(threshold, 0.01))   // stretch contrast around threshold
                    .brightness(-threshold)                  // shift so threshold = 0 (transparent)
            )
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Canvas") {
    PhysicsCanvas(preset: .turbulence, lighting: .dramatic)
        .preferredColorScheme(.dark)
}

#Preview("Dual Field") {
    PhysicsDualField(
        primary:      PhysicsConfig(preset: .coral,     scheme: .neonPurple, lighting: .dramatic),
        secondary:    PhysicsConfig(preset: .labyrinth, scheme: .neonCyan,   lighting: .soft),
        blendOpacity: 0.6
    )
    .preferredColorScheme(.dark)
}

#Preview("Reveal") {
    ZStack {
        Color.black.ignoresSafeArea()
        PhysicsRevealView(preset: .mitosis, threshold: 0.25) {
            LinearGradient(
                colors: [.purple, .cyan, .pink],
                startPoint: .topLeading,
                endPoint:   .bottomTrailing
            )
            .ignoresSafeArea()
        }
    }
    .preferredColorScheme(.dark)
}
#endif
