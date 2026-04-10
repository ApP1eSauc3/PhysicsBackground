//
//  PhysicsBackgroundDemoView.swift
//  PhysicsBackground
//
//  Self-contained showcase. Explore all five presets, six palettes,
//  and four lighting modes — no external dependencies.
//
//  Add to your app:
//    NavigationLink("Physics Demo") { PhysicsBackgroundDemoView() }
//  or navigate directly in Previews.
//

import SwiftUI
import UIKit

// MARK: - PhysicsBackgroundDemoView

public struct PhysicsBackgroundDemoView: View {

    @State private var preset:   PhysicsPreset       = .coral
    @State private var palette:  PhysicsColourScheme = .neonPurple
    @State private var lighting: PhysicsLighting     = .default
    @State private var cardUp:   Bool                = false

    public init() {}

    public var body: some View {
        GeometryReader { geo in
            ZStack {
                // ── Live simulation — full bleed ──────────────────────────
                MetalSimView(config: PhysicsConfig(
                    preset:   preset,
                    scheme:   palette,
                    lighting: lighting
                ))
                .id("\(preset.id)-\(palette.mid.x)")  // reset on preset / palette change
                .ignoresSafeArea()

                // ── Layered content ───────────────────────────────────────
                VStack(spacing: 0) {
                    header(geo: geo)
                    Spacer()
                    previewCard
                    Spacer()
                    controls
                }
                .ignoresSafeArea(edges: .bottom)
            }
        }
        .background(Color.black)
        .navigationBarHidden(true)
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.75).delay(0.5)) {
                cardUp = true
            }
        }
    }

    // MARK: - Header

    @ViewBuilder
    private func header(geo: GeometryProxy) -> some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [Color.black.opacity(0.75), Color.clear],
                startPoint: .top,
                endPoint:   .bottom
            )
            .frame(height: geo.size.height * 0.28)
            .ignoresSafeArea(edges: .top)

            VStack(alignment: .leading, spacing: 6) {
                Text("PhysicsBackground")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.white)

                Text(preset.displayName.uppercased() + "  ·  " + paletteName + "  ·  " + lightingName)
                    .font(.system(.caption, design: .default).weight(.medium))
                    .foregroundStyle(Color.white.opacity(0.55))
                    .tracking(2)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .frame(height: geo.size.height * 0.28)
    }

    // MARK: - Preview card

    @ViewBuilder
    private var previewCard: some View {
        VStack(alignment: .leading, spacing: 0) {

            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(accentColour.opacity(0.18))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: preset.iconName)
                            .foregroundStyle(accentColour)
                            .font(.system(size: 18))
                    )

                VStack(alignment: .leading, spacing: 3) {
                    Text(preset.cardTitle)
                        .font(.system(.headline, design: .default).weight(.semibold))
                        .foregroundStyle(Color.white)
                    Text(preset.cardSubtitle)
                        .font(.system(.caption, design: .default))
                        .foregroundStyle(Color.white.opacity(0.6))
                }

                Spacer()

                HStack(spacing: 4) {
                    Circle()
                        .fill(accentColour)
                        .frame(width: 6, height: 6)
                    Text("LIVE")
                        .font(.system(.caption2, design: .default).weight(.semibold))
                        .foregroundStyle(accentColour)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().fill(accentColour.opacity(0.12)))
            }
            .padding(16)

            Divider().background(Color.white.opacity(0.08))

            VStack(alignment: .leading, spacing: 8) {
                Text("SIMULATION PARAMETERS")
                    .font(.system(.caption2, design: .default).weight(.medium))
                    .foregroundStyle(Color.white.opacity(0.4))
                    .tracking(1.8)

                HStack(spacing: 0) {
                    paramCell(label: "Du",   value: String(format: "%.3f", preset.Du))
                    paramCell(label: "Dv",   value: String(format: "%.3f", preset.Dv))
                    paramCell(label: "feed", value: String(format: "%.4f", preset.feed))
                    paramCell(label: "kill", value: String(format: "%.4f", preset.kill))
                    paramCell(label: "fps",  value: "\(preset.stepsPerFrame) steps")
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider().background(Color.white.opacity(0.08))

            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                cyclePreset()
            } label: {
                Text("NEXT PRESET →")
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(accentColour)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .padding(.horizontal, 20)
        .scaleEffect(cardUp ? 1.0 : 0.92)
        .opacity(cardUp ? 1.0 : 0)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: cardUp)
    }

    // MARK: - Controls

    @ViewBuilder
    private var controls: some View {
        VStack(spacing: 12) {
            controlRow(label: "PRESET") {
                ForEach(PhysicsPreset.allCases) { p in
                    pillButton(label: p.displayName, isActive: preset == p) {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            preset = p
                        }
                    }
                }
            }

            controlRow(label: "PALETTE") {
                ForEach(PhysicsColourScheme.allNamed, id: \.0) { name, scheme in
                    pillButton(label: name, isActive: palette.mid == scheme.mid) {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            palette = scheme
                        }
                    }
                }
            }

            controlRow(label: "LIGHTING") {
                ForEach(PhysicsLighting.allNamed, id: \.0) { name, l in
                    pillButton(
                        label:    name,
                        isActive: lightingName == name
                    ) {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            lighting = l
                        }
                    }
                }
            }
        }
        .padding(.bottom, 48)
    }

    // MARK: - Helpers

    @ViewBuilder
    private func controlRow<Content: View>(
        label: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(.caption2, design: .default).weight(.medium))
                .foregroundStyle(Color.white.opacity(0.35))
                .tracking(1.8)
                .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) { content() }
                    .padding(.horizontal, 20)
            }
        }
    }

    @ViewBuilder
    private func pillButton(
        label:    String,
        isActive: Bool,
        action:   @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(.caption, design: .default)
                    .weight(isActive ? .semibold : .regular))
                .foregroundStyle(isActive ? Color.white : Color.white.opacity(0.45))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule().fill(isActive
                        ? accentColour.opacity(0.85)
                        : Color.white.opacity(0.06))
                )
        }
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isActive)
    }

    @ViewBuilder
    private func paramCell(label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(.caption, design: .monospaced).weight(.medium))
                .foregroundStyle(accentColour)
            Text(label)
                .font(.system(.caption2, design: .default))
                .foregroundStyle(Color.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
    }

    private var accentColour: Color {
        Color(
            red:   Double(palette.high.x),
            green: Double(palette.high.y),
            blue:  Double(palette.high.z)
        )
    }

    private var paletteName: String {
        PhysicsColourScheme.allNamed.first { $0.1.mid == palette.mid }?.0 ?? "Custom"
    }

    private var lightingName: String {
        PhysicsLighting.allNamed.first {
            $0.1.ambient == lighting.ambient && $0.1.diffuse == lighting.diffuse
        }?.0 ?? "Custom"
    }

    private func cyclePreset() {
        let all  = PhysicsPreset.allCases
        let idx  = all.firstIndex(of: preset) ?? 0
        let next = all[(idx + 1) % all.count]
        cardUp   = false
        preset   = next
        withAnimation(.spring(response: 0.45, dampingFraction: 0.8).delay(0.1)) {
            cardUp = true
        }
    }
}

// MARK: - PhysicsPreset display helpers (demo-only)

private extension PhysicsPreset {
    var iconName: String {
        switch self {
        case .coral:      return "leaf.fill"
        case .mitosis:    return "circle.grid.2x2.fill"
        case .labyrinth:  return "squareshape.split.3x3"
        case .turbulence: return "tornado"
        case .nebula:     return "sparkles"
        }
    }
    var cardTitle: String {
        switch self {
        case .coral:      return "Coral Growth"
        case .mitosis:    return "Cell Division"
        case .labyrinth:  return "Labyrinth"
        case .turbulence: return "Worm Turbulence"
        case .nebula:     return "Nebula Drift"
        }
    }
    var cardSubtitle: String {
        switch self {
        case .coral:      return "Slow branching · organic structures"
        case .mitosis:    return "Spots grow → divide → repeat"
        case .labyrinth:  return "Dense parallel stripes"
        case .turbulence: return "High-energy chaotic worms"
        case .nebula:     return "Sparse slow-drifting halos"
        }
    }
}

// MARK: - PhysicsColourScheme named index (for palette picker)

extension PhysicsColourScheme {
    static let allNamed: [(String, PhysicsColourScheme)] = [
        ("Purple",  .neonPurple),
        ("Cyan",    .neonCyan),
        ("Red",     .neonRed),
        ("Gold",    .neonGold),
        ("Ice",     .ice),
        ("Mono",    .monochrome),
    ]
}

// MARK: - Preview

#Preview {
    PhysicsBackgroundDemoView()
        .preferredColorScheme(.dark)
}
