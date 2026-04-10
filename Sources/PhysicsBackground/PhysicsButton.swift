//
//  PhysicsButton.swift
//  PhysicsBackground
//
//  A SwiftUI Button whose background is a live reaction-diffusion simulation.
//  Tapping fires a ring burst of seeds at the press point, creating an
//  expanding chemical reaction that ripples outward through the simulation.
//
//  Usage:
//    PhysicsButton(preset: .turbulence, lighting: .dramatic) {
//        print("tapped")
//    } label: {
//        Text("Launch")
//            .font(.headline)
//            .foregroundStyle(.white)
//    }
//

import SwiftUI
import UIKit

// MARK: - PhysicsButton

public struct PhysicsButton<Label: View>: View {

    private let action:       () -> Void
    private let preset:       PhysicsPreset
    private let scheme:       PhysicsColourScheme
    private let lighting:     PhysicsLighting
    private let cornerRadius: CGFloat
    private let label:        Label

    @StateObject private var seeds = PhysicsSeedController()
    @State       private var pressed = false

    public init(
        preset:       PhysicsPreset        = .turbulence,
        scheme:       PhysicsColourScheme? = nil,
        lighting:     PhysicsLighting      = .dramatic,
        cornerRadius: CGFloat              = 14,
        action:       @escaping () -> Void,
        @ViewBuilder label: () -> Label
    ) {
        self.action       = action
        self.preset       = preset
        self.scheme       = scheme ?? preset.defaultScheme
        self.lighting     = lighting
        self.cornerRadius = cornerRadius
        self.label        = label()
    }

    public var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            seeds.burst(count: 8, ring: 0.18, radius: 20)
            action()
        } label: {
            label
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity)
                .background(
                    MetalSimView(
                        config:         PhysicsConfig(preset: preset, scheme: scheme, lighting: lighting),
                        seedController: seeds
                    )
                    .id(preset)
                    .allowsHitTesting(false)
                )
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                .contentShape(RoundedRectangle(cornerRadius: cornerRadius))
                .scaleEffect(pressed ? 0.96 : 1.0)
                .brightness(pressed ? 0.08 : 0)
                .animation(.spring(response: 0.2, dampingFraction: 0.55), value: pressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in pressed = true  }
                .onEnded   { _ in pressed = false }
        )
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    VStack(spacing: 20) {
        PhysicsButton(preset: .turbulence, lighting: .dramatic, action: {}) {
            Text("LAUNCH")
                .font(.system(.headline, design: .rounded).weight(.bold))
                .foregroundStyle(.white)
        }

        PhysicsButton(preset: .coral, lighting: .soft, action: {}) {
            HStack(spacing: 8) {
                Image(systemName: "leaf.fill").foregroundStyle(.white)
                Text("Organic").foregroundStyle(.white)
            }
            .font(.system(.subheadline, design: .rounded))
        }

        PhysicsButton(preset: .mitosis, scheme: .neonCyan, action: {}) {
            Text("Divide").foregroundStyle(.white)
                .font(.system(.subheadline, design: .monospaced))
        }
    }
    .padding(32)
    .background(Color.black)
    .preferredColorScheme(.dark)
}
#endif
