//
//  PhysicsBackgroundDemoView.swift
//  PhysicsBackground
//
//  Five-page swipeable showcase. Each page demonstrates a distinct
//  capability of the package. Swipe horizontally to navigate.
//
//    Page 1 — SIMULATE   preset · palette · lighting pickers
//    Page 2 — COMPONENTS PhysicsButton, PhysicsProgressBar, physicsBorder
//    Page 3 — CANVAS     interactive touch-seeded drawing
//    Page 4 — MORPH      smooth parameter-space travel between presets
//    Page 5 — COMPOSE    dual-field additive blend + reveal mask
//

import SwiftUI
import UIKit

// MARK: - Root

public struct PhysicsBackgroundDemoView: View {

    @State private var page = 0

    private let titles = ["SIMULATE", "COMPONENTS", "CANVAS", "MORPH", "COMPOSE"]

    public init() {}

    public var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $page) {
                SimulatePage().tag(0)
                ComponentsPage().tag(1)
                CanvasPage().tag(2)
                MorphPage().tag(3)
                ComposePage().tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()

            // ── Page indicator ────────────────────────────────────────────
            VStack(spacing: 6) {
                Text(titles[page])
                    .font(.system(.caption2, design: .monospaced).weight(.semibold))
                    .foregroundStyle(.white.opacity(0.45))
                    .tracking(2.5)
                    .animation(.easeInOut(duration: 0.2), value: page)

                HStack(spacing: 6) {
                    ForEach(0..<titles.count, id: \.self) { i in
                        Capsule()
                            .fill(i == page ? Color.white : Color.white.opacity(0.2))
                            .frame(width: i == page ? 18 : 6, height: 6)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: page)
                    }
                }
            }
            .padding(.bottom, 36)
        }
        .background(Color.black)
        .navigationBarHidden(true)
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Page 1 · SIMULATE
// Full-screen simulation. Explore every preset, palette, and lighting mode.
// ─────────────────────────────────────────────────────────────────────────────

private struct SimulatePage: View {

    @State private var preset:   PhysicsPreset       = .coral
    @State private var palette:  PhysicsColourScheme = .neonPurple
    @State private var lighting: PhysicsLighting     = .default
    @State private var cardUp    = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                MetalSimView(config: PhysicsConfig(preset: preset, scheme: palette, lighting: lighting))
                    .id("\(preset.id)-\(palette.mid.x)")
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    ZStack(alignment: .bottomLeading) {
                        LinearGradient(colors: [.black.opacity(0.75), .clear],
                                       startPoint: .top, endPoint: .bottom)
                            .frame(height: geo.size.height * 0.25)
                            .ignoresSafeArea(edges: .top)

                        VStack(alignment: .leading, spacing: 5) {
                            Text("PhysicsBackground")
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                            Text([preset.displayName, paletteName, lightingName]
                                    .joined(separator: "  ·  ").uppercased())
                                .font(.system(.caption2).weight(.medium))
                                .foregroundStyle(.white.opacity(0.5))
                                .tracking(2)
                        }
                        .padding(.horizontal, 20).padding(.bottom, 16)
                    }
                    .frame(height: geo.size.height * 0.25)

                    Spacer()

                    // Param card
                    VStack(spacing: 0) {
                        HStack(spacing: 12) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(accent.opacity(0.18)).frame(width: 40, height: 40)
                                .overlay(Image(systemName: preset.icon).foregroundStyle(accent))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(preset.cardTitle)
                                    .font(.system(.subheadline).weight(.semibold)).foregroundStyle(.white)
                                Text(preset.cardSubtitle)
                                    .font(.system(.caption)).foregroundStyle(.white.opacity(0.55))
                            }
                            Spacer()
                            livePill
                        }
                        .padding(14)

                        Divider().background(Color.white.opacity(0.08))

                        HStack(spacing: 0) {
                            paramCell("Du",   String(format: "%.3f", preset.Du))
                            paramCell("Dv",   String(format: "%.3f", preset.Dv))
                            paramCell("feed", String(format: "%.4f", preset.feed))
                            paramCell("kill", String(format: "%.4f", preset.kill))
                            paramCell("fps",  "\(preset.stepsPerFrame) steps")
                        }
                        .padding(.vertical, 10)

                        Divider().background(Color.white.opacity(0.08))

                        Button {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            cyclePreset()
                        } label: {
                            Text("NEXT PRESET →")
                                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity).frame(height: 46)
                                .background(accent).cornerRadius(10)
                        }
                        .padding(14)
                    }
                    .background(.ultraThinMaterial)
                    .cornerRadius(18)
                    .padding(.horizontal, 18)
                    .scaleEffect(cardUp ? 1 : 0.92).opacity(cardUp ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: cardUp)

                    Spacer(minLength: 60)

                    // Pickers
                    VStack(spacing: 10) {
                        pickerRow("PRESET") {
                            ForEach(PhysicsPreset.allCases) { p in
                                pill(p.displayName, active: preset == p) {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    preset = p
                                }
                            }
                        }
                        pickerRow("PALETTE") {
                            ForEach(PhysicsColourScheme.allNamed, id: \.0) { name, s in
                                pill(name, active: palette.mid == s.mid) {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    palette = s
                                }
                            }
                        }
                        pickerRow("LIGHTING") {
                            ForEach(PhysicsLighting.allNamed, id: \.0) { name, l in
                                pill(name, active: lightingName == name) {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    lighting = l
                                }
                            }
                        }
                    }
                    .padding(.bottom, 80)
                }
            }
        }
        .background(Color.black)
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.75).delay(0.4)) { cardUp = true }
        }
    }

    private var accent: Color {
        Color(red: Double(palette.high.x), green: Double(palette.high.y), blue: Double(palette.high.z))
    }
    private var paletteName: String {
        PhysicsColourScheme.allNamed.first { $0.1.mid == palette.mid }?.0 ?? "Custom"
    }
    private var lightingName: String {
        PhysicsLighting.allNamed.first {
            $0.1.ambient == lighting.ambient && $0.1.diffuse == lighting.diffuse
        }?.0 ?? "Custom"
    }
    private var livePill: some View {
        HStack(spacing: 4) {
            Circle().fill(accent).frame(width: 6, height: 6)
            Text("LIVE").font(.system(.caption2).weight(.semibold)).foregroundStyle(accent)
        }
        .padding(.horizontal, 8).padding(.vertical, 4)
        .background(Capsule().fill(accent.opacity(0.12)))
    }
    private func paramCell(_ label: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.system(.caption, design: .monospaced).weight(.medium)).foregroundStyle(accent)
            Text(label).font(.system(.caption2)).foregroundStyle(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
    }
    @ViewBuilder
    private func pickerRow<C: View>(_ label: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(.system(.caption2).weight(.medium))
                .foregroundStyle(.white.opacity(0.3)).tracking(1.8).padding(.horizontal, 20)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 7) { content() }.padding(.horizontal, 20)
            }
        }
    }
    private func pill(_ label: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(.caption).weight(active ? .semibold : .regular))
                .foregroundStyle(active ? .white : .white.opacity(0.4))
                .padding(.horizontal, 12).padding(.vertical, 7)
                .background(Capsule().fill(active ? accent.opacity(0.85) : Color.white.opacity(0.06)))
        }
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: active)
    }
    private func cyclePreset() {
        let all = PhysicsPreset.allCases
        let idx = all.firstIndex(of: preset) ?? 0
        cardUp = false
        preset = all[(idx + 1) % all.count]
        withAnimation(.spring(response: 0.45, dampingFraction: 0.8).delay(0.1)) { cardUp = true }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Page 2 · COMPONENTS
// Live demos of PhysicsButton, PhysicsProgressBar, and physicsBorder.
// ─────────────────────────────────────────────────────────────────────────────

private struct ComponentsPage: View {

    @State private var progress: Double = 0.45
    @State private var tapCount: Int    = 0
    @State private var animating        = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {

                pageHeader("Components", subtitle: "Drop-in UI primitives")

                // ── PhysicsButton ─────────────────────────────────────────
                section("PhysicsButton") {
                    VStack(spacing: 12) {
                        PhysicsButton(preset: .turbulence, lighting: .dramatic, action: {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            tapCount += 1
                        }) {
                            Text(tapCount == 0 ? "TAP TO BURST" : "BURST ×\(tapCount)")
                                .font(.system(.subheadline, design: .rounded).weight(.bold))
                                .foregroundStyle(.white)
                        }

                        HStack(spacing: 12) {
                            PhysicsButton(preset: .coral, lighting: .soft, cornerRadius: 12, action: {}) {
                                Label("Organic", systemImage: "leaf.fill").foregroundStyle(.white)
                                    .font(.system(.caption, design: .rounded).weight(.semibold))
                            }
                            PhysicsButton(preset: .mitosis, scheme: .neonCyan, action: {}) {
                                Text("Divide").foregroundStyle(.white)
                                    .font(.system(.caption, design: .monospaced))
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }

                // ── PhysicsProgressBar ────────────────────────────────────
                section("PhysicsProgressBar") {
                    VStack(spacing: 14) {
                        PhysicsProgressBar(progress: progress, preset: .labyrinth, lighting: .dramatic)
                            .frame(height: 10)
                        PhysicsProgressBar(progress: progress, preset: .coral, lighting: .soft)
                            .frame(height: 6)
                        PhysicsProgressBar(progress: max(0, progress - 0.15), preset: .turbulence)
                            .frame(height: 14)

                        HStack {
                            Text("\(Int(progress * 100))%")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.4))
                            Slider(value: $progress, in: 0...1).tint(.white)
                        }
                    }
                }

                // ── physicsBorder ─────────────────────────────────────────
                section("physicsBorder") {
                    VStack(spacing: 16) {
                        HStack(spacing: 16) {
                            borderCard("coral", preset: .coral, width: 3)
                            borderCard("labyrinth", preset: .labyrinth, width: 2)
                        }
                        borderCard("turbulence · dramatic", preset: .turbulence,
                                   lighting: .dramatic, width: 4)
                    }
                }

                Spacer(minLength: 80)
            }
            .padding(.horizontal, 20)
            .padding(.top, 60)
        }
        .background(Color.black)
        .onAppear {
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: true)) { animating = true }
        }
    }

    private func borderCard(_ label: String, preset: PhysicsPreset,
                             lighting: PhysicsLighting = .soft, width: CGFloat) -> some View {
        Text(label)
            .font(.system(.caption, design: .monospaced))
            .foregroundStyle(.white.opacity(0.5))
            .frame(maxWidth: .infinity).frame(height: 56)
            .background(Color.white.opacity(0.04))
            .cornerRadius(12)
            .physicsBorder(preset, width: width, cornerRadius: 12, lighting: lighting)
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Page 3 · CANVAS
// Touch-reactive full-screen canvas. Tap and drag to paint V concentration.
// ─────────────────────────────────────────────────────────────────────────────

private struct CanvasPage: View {

    @State private var preset:   PhysicsPreset = .turbulence
    @State private var showHint               = true

    var body: some View {
        ZStack {
            PhysicsCanvas(preset: preset, lighting: .dramatic)

            // Hint overlay
            if showHint {
                VStack(spacing: 8) {
                    Image(systemName: "hand.draw.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.white.opacity(0.6))
                    Text("TAP OR DRAG TO PAINT")
                        .font(.system(.caption, design: .monospaced).weight(.medium))
                        .foregroundStyle(.white.opacity(0.5))
                        .tracking(2)
                }
                .padding(24)
                .background(.ultraThinMaterial)
                .cornerRadius(16)
                .transition(.opacity.combined(with: .scale))
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        withAnimation(.easeOut(duration: 0.8)) { showHint = false }
                    }
                }
            }

            // Preset switcher
            VStack {
                Spacer()
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(PhysicsPreset.allCases) { p in
                            Button {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                preset = p
                            } label: {
                                Text(p.displayName)
                                    .font(.system(.caption).weight(preset == p ? .semibold : .regular))
                                    .foregroundStyle(preset == p ? .white : .white.opacity(0.4))
                                    .padding(.horizontal, 12).padding(.vertical, 7)
                                    .background(Capsule().fill(preset == p
                                        ? Color.white.opacity(0.2) : Color.white.opacity(0.06)))
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 80)
            }
        }
        .ignoresSafeArea()
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Page 4 · MORPH
// PhysicsMorphingView — smooth parameter-space travel.
// The simulation keeps running while (Du, Dv, feed, kill) interpolate.
// ─────────────────────────────────────────────────────────────────────────────

private struct MorphPage: View {

    @State private var speed: TimeInterval = 8.0
    @State private var lighting: PhysicsLighting = .dramatic

    var body: some View {
        ZStack {
            PhysicsMorphingView(
                presets:       PhysicsPreset.allCases,
                cycleInterval: speed,
                lighting:      lighting
            )
            .ignoresSafeArea()

            VStack {
                Spacer()

                VStack(alignment: .leading, spacing: 14) {
                    Label("PhysicsMorphingView", systemImage: "arrow.triangle.2.circlepath")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundStyle(.white)

                    Text("Parameters (Du, Dv, feed, kill) interpolate smoothly between presets. The simulation never restarts — the evolved pattern transforms in place.")
                        .font(.system(.caption))
                        .foregroundStyle(.white.opacity(0.55))
                        .lineSpacing(4)

                    Divider().background(Color.white.opacity(0.1))

                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("CYCLE SPEED").font(.system(.caption2).weight(.medium))
                                .foregroundStyle(.white.opacity(0.35)).tracking(1.5)
                            Spacer()
                            Text("\(Int(speed))s").font(.system(.caption, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.5))
                        }
                        Slider(value: $speed, in: 4...20, step: 2)
                            .tint(.white)
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(PhysicsLighting.allNamed, id: \.0) { name, l in
                                Button {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    lighting = l
                                } label: {
                                    let active = lighting.ambient == l.ambient && lighting.diffuse == l.diffuse
                                    Text(name)
                                        .font(.system(.caption).weight(active ? .semibold : .regular))
                                        .foregroundStyle(active ? .white : .white.opacity(0.4))
                                        .padding(.horizontal, 12).padding(.vertical, 7)
                                        .background(Capsule().fill(active
                                            ? Color.white.opacity(0.2) : Color.white.opacity(0.06)))
                                }
                            }
                        }
                    }
                }
                .padding(18)
                .background(.ultraThinMaterial)
                .cornerRadius(18)
                .padding(.horizontal, 18)
                .padding(.bottom, 80)
            }
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Page 5 · COMPOSE
// Dual-field additive blend and reveal mask.
// ─────────────────────────────────────────────────────────────────────────────

private struct ComposePage: View {

    @State private var mode       = 0   // 0 = dual, 1 = reveal
    @State private var blend: Double = 0.55

    var body: some View {
        ZStack {
            // ── Background ────────────────────────────────────────────────
            if mode == 0 {
                PhysicsDualField(
                    primary:      PhysicsConfig(preset: .coral,     scheme: .neonPurple, lighting: .dramatic),
                    secondary:    PhysicsConfig(preset: .labyrinth, scheme: .neonCyan,   lighting: .soft),
                    blendOpacity: blend
                )
                .ignoresSafeArea()
            } else {
                ZStack {
                    Color.black.ignoresSafeArea()
                    PhysicsRevealView(preset: .mitosis, threshold: 0.25) {
                        LinearGradient(
                            colors: [.purple, .indigo, .cyan],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                        .ignoresSafeArea()
                    }
                }
            }

            // ── Info card ─────────────────────────────────────────────────
            VStack {
                Spacer()

                VStack(alignment: .leading, spacing: 14) {

                    // Mode switcher
                    HStack(spacing: 0) {
                        modeTab("Dual Field", index: 0)
                        modeTab("Reveal Mask", index: 1)
                    }
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(10)

                    if mode == 0 {
                        Text("Two independent simulations composited via .screen blend mode. Touch plants seeds in both fields simultaneously.")
                            .font(.system(.caption)).foregroundStyle(.white.opacity(0.55)).lineSpacing(4)

                        HStack {
                            Text("BLEND").font(.system(.caption2).weight(.medium))
                                .foregroundStyle(.white.opacity(0.35)).tracking(1.5)
                            Spacer()
                            Text("\(Int(blend * 100))%").font(.system(.caption, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.5))
                        }
                        Slider(value: $blend, in: 0...1).tint(.white)
                    } else {
                        Text("V concentration drives an alpha mask over arbitrary content. As the mitosis pattern evolves, it progressively reveals the gradient beneath.")
                            .font(.system(.caption)).foregroundStyle(.white.opacity(0.55)).lineSpacing(4)
                    }
                }
                .padding(18)
                .background(.ultraThinMaterial)
                .cornerRadius(18)
                .padding(.horizontal, 18)
                .padding(.bottom, 80)
            }
        }
    }

    private func modeTab(_ label: String, index: Int) -> some View {
        Button { withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { mode = index } } label: {
            Text(label)
                .font(.system(.caption).weight(mode == index ? .semibold : .regular))
                .foregroundStyle(mode == index ? .white : .white.opacity(0.4))
                .frame(maxWidth: .infinity).frame(height: 34)
                .background(mode == index ? Color.white.opacity(0.15) : Color.clear)
                .cornerRadius(8)
                .padding(3)
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Shared helpers
// ─────────────────────────────────────────────────────────────────────────────

private func pageHeader(_ title: String, subtitle: String) -> some View {
    VStack(alignment: .leading, spacing: 4) {
        Text(title)
            .font(.system(size: 26, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
        Text(subtitle)
            .font(.system(.caption).weight(.medium))
            .foregroundStyle(.white.opacity(0.35))
            .tracking(1.5)
    }
}

private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
    VStack(alignment: .leading, spacing: 12) {
        Text(title)
            .font(.system(.caption, design: .monospaced).weight(.medium))
            .foregroundStyle(.white.opacity(0.35))
            .tracking(1.5)
        content()
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - PhysicsPreset display helpers (demo-only)
// ─────────────────────────────────────────────────────────────────────────────

private extension PhysicsPreset {
    var icon: String {
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

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Named palettes (for picker)
// ─────────────────────────────────────────────────────────────────────────────

extension PhysicsColourScheme {
    static let allNamed: [(String, PhysicsColourScheme)] = [
        ("Purple", .neonPurple), ("Cyan",  .neonCyan),
        ("Red",    .neonRed),    ("Gold",  .neonGold),
        ("Ice",    .ice),        ("Mono",  .monochrome),
    ]
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Preview
// ─────────────────────────────────────────────────────────────────────────────

#Preview {
    PhysicsBackgroundDemoView()
        .preferredColorScheme(.dark)
}
