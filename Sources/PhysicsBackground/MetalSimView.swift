//
//  MetalSimView.swift
//  PhysicsBackground
//
//  UIViewRepresentable bridge. The coordinator IS the GrayScottRenderer —
//  MTKView drives the render loop by calling renderer.draw(in:) at 30 fps.
//
//  Not used directly. Always access via View.physicsBackground(_:) modifier.
//

import SwiftUI
import MetalKit

// MARK: - MetalSimView

public struct MetalSimView: UIViewRepresentable {

    public let config: PhysicsConfig

    public init(config: PhysicsConfig) {
        self.config = config
    }

    // makeCoordinator is called once before makeUIView.
    // The renderer IS the coordinator — it handles all Metal work.
    public func makeCoordinator() -> GrayScottRenderer {
        guard let renderer = GrayScottRenderer(config: config) else {
            fatalError("""
                PhysicsBackground: Metal initialisation failed.
                Ensure you are running on a physical device or a Metal-capable simulator.
                If running in a simulator, use iOS 17+ sim with Metal support.
                """)
        }
        return renderer
    }

    public func makeUIView(context: Context) -> MTKView {
        let view = MTKView(frame: .zero, device: context.coordinator.device)
        view.colorPixelFormat        = .bgra8Unorm
        view.depthStencilPixelFormat = .invalid
        view.isPaused                = false
        view.enableSetNeedsDisplay   = false
        view.preferredFramesPerSecond = 30     // plenty for a background; saves battery
        view.framebufferOnly         = true    // no drawable readback needed
        view.clearColor              = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
        view.delegate                = context.coordinator
        return view
    }

    // Preset changes are handled by `.id(config.preset)` — full SwiftUI recreation.
    // Lighting changes are applied here without restarting the simulation.
    public func updateUIView(_ uiView: MTKView, context: Context) {
        context.coordinator.updateLighting(config.lighting)
    }
}
