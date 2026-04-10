//
//  PhysicsMorphingView.swift
//  PhysicsBackground
//
//  A full-screen simulation that smoothly travels through (feed, kill)
//  parameter space, morphing between presets over time. The renderer is
//  kept alive across preset changes — only SimUniforms are interpolated,
//  so the evolved pattern state is preserved and transforms gradually
//  into the new pattern class.
//
//  This produces effects not achievable by switching presets:
//    coral   → labyrinth  stripes slowly emerge from branching
//    mitosis → turbulence spots destabilise into chaotic worms
//    nebula  → coral      halos condense into branching structures
//
//  Usage:
//    // Cycle all presets every 12 seconds
//    PhysicsMorphingView()
//
//    // Custom cycle
//    PhysicsMorphingView(
//        presets:       [.coral, .labyrinth, .turbulence],
//        cycleInterval: 8,
//        lighting:      .dramatic
//    )
//
//    // As a background
//    ZStack {
//        PhysicsMorphingView(cycleInterval: 15)
//        YourContent()
//    }
//

import SwiftUI

// MARK: - PhysicsMorphingView

public struct PhysicsMorphingView: View {

    private let presets:       [PhysicsPreset]
    private let cycleInterval: TimeInterval
    private let lighting:      PhysicsLighting

    @State private var current: PhysicsPreset

    public init(
        presets:       [PhysicsPreset] = PhysicsPreset.allCases,
        cycleInterval: TimeInterval    = 12.0,
        lighting:      PhysicsLighting = .default
    ) {
        let p          = presets.isEmpty ? PhysicsPreset.allCases : presets
        self.presets   = p
        self.cycleInterval = cycleInterval
        self.lighting  = lighting
        _current       = State(initialValue: p.first ?? .coral)
    }

    public var body: some View {
        // NO .id() on MetalSimView — intentional.
        // Omitting .id keeps the coordinator alive across preset changes.
        // morphOnPresetChange: true tells updateUIView to call
        // coordinator.smoothUpdatePreset(_:) instead of restarting.
        MetalSimView(
            config: PhysicsConfig(preset: current, lighting: lighting),
            morphOnPresetChange: true
        )
        .ignoresSafeArea()
        .onReceive(
            Timer.publish(every: cycleInterval, on: .main, in: .common).autoconnect()
        ) { _ in
            let idx = presets.firstIndex(of: current) ?? 0
            current = presets[(idx + 1) % presets.count]
        }
    }
}

// MARK: - PhysicsMorphingBackground
// Convenience modifier: morphing background behind any view.

extension View {
    /// Places a parameter-morphing simulation behind this view.
    public func physicsMorphingBackground(
        presets:       [PhysicsPreset] = PhysicsPreset.allCases,
        cycleInterval: TimeInterval    = 12.0,
        lighting:      PhysicsLighting = .default,
        opacity:       Double          = 1.0
    ) -> some View {
        ZStack {
            PhysicsMorphingView(
                presets:       presets,
                cycleInterval: cycleInterval,
                lighting:      lighting
            )
            .opacity(opacity)
            self
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    ZStack {
        PhysicsMorphingView(
            presets:       [.coral, .labyrinth, .turbulence, .mitosis],
            cycleInterval: 6,
            lighting:      .dramatic
        )

        VStack(spacing: 8) {
            Text("PhysicsMorphingView")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text("Morphing between presets")
                .font(.system(.caption, design: .default))
                .foregroundStyle(.white.opacity(0.5))
                .tracking(2)
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }
    .ignoresSafeArea()
    .preferredColorScheme(.dark)
}
#endif
