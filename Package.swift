// swift-tools-version: 5.9
import PackageDescription

// PhysicsBackground — Live Gray-Scott reaction-diffusion backgrounds for SwiftUI.
//
// Add to any project via:
//   File → Add Package Dependencies → point to this directory (local path)
//   OR add the folder to your workspace and link the target.
//
// Usage once linked:
//   import PhysicsBackground
//   SomeView().physicsBackground(.coral)

let package = Package(
    name: "PhysicsBackground",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "PhysicsBackground",
            targets: ["PhysicsBackground"]
        )
    ],
    targets: [
        .target(
            name: "PhysicsBackground",
            // .process("Shaders") compiles all .metal files in that folder into
            // the module's default.metallib, accessible via Bundle.module.
            resources: [.process("Shaders")]
        )
    ]
)
