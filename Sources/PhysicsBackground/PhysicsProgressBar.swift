//
//  PhysicsProgressBar.swift
//  PhysicsBackground
//
//  A progress bar whose fill is a live reaction-diffusion simulation,
//  masked to the fill region with an animated edge.
//
//  The simulation runs full-width at all times — masking reveals only
//  the portion corresponding to `progress`. This means the pattern
//  continues to evolve at 100% even before the fill reaches that point,
//  so the revealed area always shows a live, evolved state rather than
//  a freshly seeded one.
//
//  Usage:
//    PhysicsProgressBar(progress: loadProgress, preset: .labyrinth)
//        .frame(height: 8)
//
//    PhysicsProgressBar(
//        progress:     downloadProgress,
//        preset:       .coral,
//        lighting:     .soft,
//        cornerRadius: 4,
//        trackOpacity: 0.12
//    )
//

import SwiftUI

// MARK: - PhysicsProgressBar

public struct PhysicsProgressBar: View {

    /// Fill fraction, clamped to [0, 1].
    public let progress:      Double
    public let preset:        PhysicsPreset
    public let lighting:      PhysicsLighting
    public let cornerRadius:  CGFloat
    public let trackOpacity:  Double

    public init(
        progress:     Double          = 0.5,
        preset:       PhysicsPreset   = .labyrinth,
        lighting:     PhysicsLighting = .soft,
        cornerRadius: CGFloat         = 6,
        trackOpacity: Double          = 0.10
    ) {
        self.progress     = min(max(progress, 0), 1)
        self.preset       = preset
        self.lighting     = lighting
        self.cornerRadius = cornerRadius
        self.trackOpacity = trackOpacity
    }

    public var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {

                // ── Track ─────────────────────────────────────────────────
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.white.opacity(trackOpacity))

                // ── Live fill ─────────────────────────────────────────────
                // Full-width simulation masked to the fill region.
                // Using .animation on the mask width gives a smooth
                // reveal when progress changes.
                MetalSimView(config: PhysicsConfig(preset: preset, lighting: lighting))
                    .id(preset)
                    .allowsHitTesting(false)
                    .mask(alignment: .leading) {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .frame(width: geo.size.width * CGFloat(progress))
                            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: progress)
                    }
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    struct Demo: View {
        @State var progress: Double = 0.6
        var body: some View {
            VStack(spacing: 24) {
                Text("PhysicsProgressBar")
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundStyle(.white)

                PhysicsProgressBar(progress: progress, preset: .labyrinth, lighting: .dramatic)
                    .frame(height: 10)

                PhysicsProgressBar(progress: progress, preset: .coral, lighting: .soft)
                    .frame(height: 6)

                PhysicsProgressBar(progress: progress, preset: .turbulence, lighting: .default)
                    .frame(height: 14)

                Slider(value: $progress, in: 0...1)
                    .tint(.white)
            }
            .padding(32)
            .background(Color.black)
            .preferredColorScheme(.dark)
        }
    }
    return Demo()
}
#endif
