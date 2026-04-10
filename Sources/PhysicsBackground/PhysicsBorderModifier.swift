//
//  PhysicsBorderModifier.swift
//  PhysicsBackground
//
//  Overlays any SwiftUI view with an animated reaction-diffusion border.
//  The simulation runs full-size behind the view; a ring-shaped mask
//  (even-odd fill rule) exposes only the border strip.
//
//  Usage:
//    Text("Hello")
//        .padding(20)
//        .physicsBorder(.coral, width: 3, cornerRadius: 12)
//
//    Image("photo")
//        .physicsBorder(.turbulence, width: 2, lighting: .dramatic, opacity: 0.85)
//

import SwiftUI

// MARK: - BorderRing (even-odd mask shape)

/// A rounded-rectangle ring produced by the even-odd fill rule.
/// The outer path fills normally; the inner (inset) path "punches a hole",
/// leaving only the border strip opaque — ideal as a SwiftUI mask.
private struct BorderRing: Shape {
    let cornerRadius: CGFloat
    let lineWidth:    CGFloat

    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.addRoundedRect(
            in:         rect,
            cornerSize: CGSize(width: cornerRadius, height: cornerRadius))
        let inset       = rect.insetBy(dx: lineWidth, dy: lineWidth)
        let innerRadius = max(cornerRadius - lineWidth, 0)
        p.addRoundedRect(
            in:         inset,
            cornerSize: CGSize(width: innerRadius, height: innerRadius))
        return p
    }
}

// MARK: - PhysicsBorderModifier

private struct PhysicsBorderModifier: ViewModifier {
    let preset:       PhysicsPreset
    let lighting:     PhysicsLighting
    let lineWidth:    CGFloat
    let cornerRadius: CGFloat
    let opacity:      Double

    func body(content: Content) -> some View {
        content.overlay(
            MetalSimView(
                config: PhysicsConfig(preset: preset, lighting: lighting))
                .id(preset)
                .allowsHitTesting(false)
                // Even-odd mask: ring between outer and inner rounded rects
                .mask(
                    BorderRing(cornerRadius: cornerRadius, lineWidth: lineWidth)
                        .fill(.white, style: FillStyle(eoFill: true))
                )
                .opacity(opacity)
        )
    }
}

// MARK: - View extension

extension View {

    /// Overlay a live reaction-diffusion border on any view.
    ///
    /// - Parameters:
    ///   - preset:       The Gray-Scott pattern (`.coral`, `.turbulence`, etc.)
    ///   - width:        Border line width in points.
    ///   - cornerRadius: Corner radius matching the view's own shape.
    ///   - lighting:     Lighting preset. `.soft` works well for borders.
    ///   - opacity:      Opacity of the border overlay (0–1).
    public func physicsBorder(
        _ preset:       PhysicsPreset,
        width:          CGFloat        = 2,
        cornerRadius:   CGFloat        = 12,
        lighting:       PhysicsLighting = .soft,
        opacity:        Double         = 1.0
    ) -> some View {
        modifier(PhysicsBorderModifier(
            preset:       preset,
            lighting:     lighting,
            lineWidth:    width,
            cornerRadius: cornerRadius,
            opacity:      opacity))
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    VStack(spacing: 28) {
        Text("Coral border")
            .font(.system(.body, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 24).padding(.vertical, 12)
            .background(Color.white.opacity(0.06))
            .cornerRadius(12)
            .physicsBorder(.coral, width: 3, cornerRadius: 12, lighting: .dramatic)

        RoundedRectangle(cornerRadius: 16)
            .fill(Color.white.opacity(0.05))
            .frame(height: 80)
            .overlay(
                Text("Labyrinth border")
                    .foregroundStyle(.white.opacity(0.6))
            )
            .physicsBorder(.labyrinth, width: 2, cornerRadius: 16, lighting: .soft)

        Circle()
            .fill(Color.white.opacity(0.05))
            .frame(width: 80, height: 80)
            .physicsBorder(.turbulence, width: 4, cornerRadius: 40, lighting: .default)
    }
    .padding(40)
    .background(Color.black)
    .preferredColorScheme(.dark)
}
#endif
