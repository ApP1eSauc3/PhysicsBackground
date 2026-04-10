//
//  MetalSimView.swift
//  PhysicsBackground
//
//  UIViewRepresentable bridge. The coordinator IS the GrayScottRenderer.
//  MTKView drives the render loop at 30 fps.
//
//  Parameters:
//    config               — preset, scheme, lighting
//    seedController       — optional Combine-based seed trigger (PhysicsSeedController)
//    interactionsEnabled  — adds tap + pan gesture recognisers for direct touch seeding
//    morphOnPresetChange  — when true, smoothly morphs params instead of hard-resetting
//                           Used by PhysicsMorphingView. Default false.
//

import SwiftUI
import MetalKit

// MARK: - MetalSimView

public struct MetalSimView: UIViewRepresentable {

    public  let config:              PhysicsConfig
    private let seedController:      PhysicsSeedController?
    private let interactionsEnabled: Bool
    private let morphOnPresetChange: Bool

    public init(
        config:              PhysicsConfig,
        seedController:      PhysicsSeedController? = nil,
        interactionsEnabled: Bool                   = false,
        morphOnPresetChange: Bool                   = false
    ) {
        self.config              = config
        self.seedController      = seedController
        self.interactionsEnabled = interactionsEnabled
        self.morphOnPresetChange = morphOnPresetChange
    }

    public func makeCoordinator() -> GrayScottRenderer {
        guard let renderer = GrayScottRenderer(config: config, seedController: seedController) else {
            fatalError("""
                PhysicsBackground: Metal initialisation failed.
                Run on a physical device or a Metal-capable simulator (iOS 17+ sim recommended).
                """)
        }
        return renderer
    }

    public func makeUIView(context: Context) -> MTKView {
        let view = MTKView(frame: .zero, device: context.coordinator.device)
        view.colorPixelFormat         = .bgra8Unorm
        view.depthStencilPixelFormat  = .invalid
        view.isPaused                 = false
        view.enableSetNeedsDisplay    = false
        view.preferredFramesPerSecond = 30
        view.framebufferOnly          = true
        view.clearColor               = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
        view.delegate                 = context.coordinator

        if interactionsEnabled {
            let tap = UITapGestureRecognizer(
                target: context.coordinator,
                action: #selector(GrayScottRenderer.handleTap(_:)))
            let pan = UIPanGestureRecognizer(
                target: context.coordinator,
                action: #selector(GrayScottRenderer.handlePan(_:)))
            view.addGestureRecognizer(tap)
            view.addGestureRecognizer(pan)
        }

        return view
    }

    public func updateUIView(_ uiView: MTKView, context: Context) {
        context.coordinator.updateLighting(config.lighting)
        if morphOnPresetChange {
            context.coordinator.smoothUpdatePreset(config.preset)
        }
    }
}
