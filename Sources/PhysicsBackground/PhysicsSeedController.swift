//
//  PhysicsSeedController.swift
//  PhysicsBackground
//
//  Combine-based bridge that lets SwiftUI code trigger seed injections
//  into a running GrayScottRenderer without restarting the simulation.
//
//  Usage:
//    @StateObject var seeds = PhysicsSeedController()
//
//    MetalSimView(config: ..., seedController: seeds)
//
//    Button("Burst") { seeds.burst() }
//    // or plant at a specific normalised point (0–1 each axis):
//    seeds.plant(at: CGPoint(x: 0.3, y: 0.7), radius: 30)
//

import Combine
import CoreGraphics

// MARK: - PhysicsSeedController

public final class PhysicsSeedController: ObservableObject {

    /// Each emission is a (normalisedPoint, radius) pair.
    /// The renderer subscribes and writes V concentration to the sim texture.
    let pipe = PassthroughSubject<(CGPoint, Float), Never>()

    public init() {}

    /// Plant a soft circular seed at a normalised point (x, y ∈ 0–1).
    public func plant(at point: CGPoint, radius: Float = 25) {
        pipe.send((point, radius))
    }

    /// Burst seeds from a ring of N evenly-spaced points around the centre.
    /// Use on button taps, scene transitions, or any dramatic moment.
    public func burst(
        centreX: CGFloat = 0.5,
        centreY: CGFloat = 0.5,
        count:   Int     = 6,
        ring:    CGFloat = 0.15,
        radius:  Float   = 22
    ) {
        let step = 2 * CGFloat.pi / CGFloat(max(count, 1))
        for i in 0..<count {
            let angle = CGFloat(i) * step
            let x = centreX + cos(angle) * ring
            let y = centreY + sin(angle) * ring * 0.5   // squash to ellipse
            pipe.send((CGPoint(x: x, y: y), radius))
        }
        // Centre seed
        pipe.send((CGPoint(x: centreX, y: centreY), radius * 1.4))
    }
}
