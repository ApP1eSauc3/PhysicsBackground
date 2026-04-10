//
//  PhysicsPreset.swift
//  PhysicsBackground
//
//  Five Gray-Scott parameter sets, each producing a distinct visual character.
//  Named after the pattern they produce, not the app context — reusable anywhere.
//
//  Reference: Pearson (1993) — Complex Patterns in a Simple System.
//  The (feed, kill) coordinate space maps to qualitatively distinct pattern classes.
//

import Foundation

// MARK: - PhysicsPreset

/// A named set of Gray-Scott simulation parameters.
/// Each preset occupies a different region of (feed, kill) space and
/// produces a visually distinct pattern class.
public enum PhysicsPreset: String, CaseIterable, Identifiable {

    /// Slow-growing coral. Branching organic structures that creep outward.
    case coral

    /// Mitosis. Spots that form, grow, then split into two — endlessly.
    case mitosis

    /// Labyrinth. Dense parallel stripes that fill the field like a fingerprint.
    case labyrinth

    /// Turbulence. High-energy worm chaos — fast, electric, restless.
    case turbulence

    /// Nebula. Extremely sparse, slow-drifting halos. Almost imperceptible motion.
    case nebula

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .coral:       return "Coral"
        case .mitosis:     return "Mitosis"
        case .labyrinth:   return "Labyrinth"
        case .turbulence:  return "Turbulence"
        case .nebula:      return "Nebula"
        }
    }
}

// MARK: - Simulation parameters
// These values feed directly into the Gray-Scott PDE:
//   dU/dt = Du·∇²U − U·V² + feed·(1 − U)
//   dV/dt = Dv·∇²V + U·V² − (feed + kill)·V

extension PhysicsPreset {

    /// Activator diffusion coefficient.
    public var Du: Float {
        switch self {
        case .coral:      return 0.210
        case .mitosis:    return 0.200
        case .labyrinth:  return 0.190
        case .turbulence: return 0.160
        case .nebula:     return 0.220
        }
    }

    /// Inhibitor diffusion coefficient. Always < Du.
    public var Dv: Float {
        switch self {
        case .coral:      return 0.105
        case .mitosis:    return 0.100
        case .labyrinth:  return 0.095
        case .turbulence: return 0.080
        case .nebula:     return 0.110
        }
    }

    /// Feed rate — replenishes activator. Higher = denser patterns.
    public var feed: Float {
        switch self {
        case .coral:      return 0.0545
        case .mitosis:    return 0.0367
        case .labyrinth:  return 0.0600
        case .turbulence: return 0.0780
        case .nebula:     return 0.0280
        }
    }

    /// Kill rate — removes inhibitor. Together with feed, determines pattern class.
    public var kill: Float {
        switch self {
        case .coral:      return 0.0630
        case .mitosis:    return 0.0649
        case .labyrinth:  return 0.0620
        case .turbulence: return 0.0610
        case .nebula:     return 0.0550
        }
    }

    /// Integration timestep. dt = 1.0 is stable for all presets at these diffusion rates.
    public var dt: Float { 1.0 }

    /// Compute steps dispatched per rendered frame. Drives perceived animation speed.
    public var stepsPerFrame: Int {
        switch self {
        case .coral:      return 6
        case .mitosis:    return 10   // needs speed — mitosis is driven by oscillation
        case .labyrinth:  return 6
        case .turbulence: return 12   // maximum energy
        case .nebula:     return 3    // intentionally slow — barely moves
        }
    }
}
