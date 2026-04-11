# PhysicsBackground

Live Gray-Scott reaction-diffusion backgrounds for SwiftUI, GPU-accelerated via Metal.

The simulation runs entirely on the GPU — a compute pipeline advances the PDE each frame, a second pass colourises and lights the field, and a full-screen quad blits the result to the drawable. CPU involvement per frame is minimal.

**Requirements:** iOS 16+ · Swift 5.9+ · Swift Package Manager

---

## Installation

### Swift Package Manager

In Xcode: **File → Add Package Dependencies**, then enter the repository URL.

Or add to `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/ApP1eSauc3/PhysicsBackground.git", from: "1.0.0")
]
```

---

## Quick Start

```swift
import PhysicsBackground

// Preset with defaults
Text("Hello")
    .physicsBackground(.coral)

// With a lighting preset
ContentView()
    .physicsBackground(.labyrinth, lighting: .dramatic)

// With a colour scheme
ContentView()
    .physicsBackground(.mitosis, scheme: .neonCyan)

// Full control
ContentView()
    .physicsBackground(.turbulence, scheme: .neonRed, lighting: .soft)
```

---

## Presets

Five parameter sets, each producing a distinct visual character:

| Preset | Description |
|---|---|
| `.coral` | Slow-growing coral. Branching organic structures that creep outward. |
| `.mitosis` | Spots that form, grow, then split into two — endlessly. |
| `.labyrinth` | Dense parallel stripes that fill the field like a fingerprint. |
| `.turbulence` | High-energy worm chaos — fast, electric, restless. |
| `.nebula` | Extremely sparse, slow-drifting halos. Almost imperceptible motion. |

Each preset ships with a default colour scheme tuned for its visual character. Override it explicitly when needed.

---

## Colour Schemes

Six built-in palettes. All are three-stop linear-RGB gradients that map V concentration to colour in the GPU shader:

| Scheme | Character |
|---|---|
| `.neonPurple` | Black → dark purple → vivid purple. Versatile, works on any dark UI. |
| `.neonCyan` | Black → dark teal → electric cyan. Tech / music / nightlife aesthetic. |
| `.neonRed` | Black → dark red → vivid red. Energy, urgency, intensity. |
| `.neonGold` | Black → dark amber → neon gold. Luxury, warmth, premium feel. |
| `.ice` | Near-black → deep navy → ice blue-white. Clean, clinical, cool. |
| `.monochrome` | Black → dark grey → white. Minimal, design-system agnostic. |

---

## Lighting

Four built-in lighting presets. The V channel is treated as a height field; Blinn-Phong shading with an animated orbiting light source creates a 2.5D relief effect:

| Preset | Description |
|---|---|
| `.off` | Flat colour output — no normal-map shading. |
| `.soft` | Gentle fill light, low contrast. Ideal as a subtle UI background. |
| `.default` | Warm white orbit at 45°. Works with all presets. |
| `.dramatic` | Deep relief, high-contrast specular. Best with `.coral` and `.labyrinth`. |

---

## `physicsBackground` — View Modifier

The primary API. Attaches a live simulation behind any SwiftUI view.

```swift
// Preset only — default palette, default lighting
SomeView().physicsBackground(.coral)

// Preset + lighting
SomeView().physicsBackground(.coral, lighting: .dramatic)

// Preset + colour scheme
SomeView().physicsBackground(.mitosis, scheme: .neonCyan)

// Preset + colour scheme + lighting
SomeView().physicsBackground(.labyrinth, scheme: .neonCyan, lighting: .soft)

// Preset + opacity
SomeView().physicsBackground(.labyrinth, opacity: 0.6)

// Preset + colour scheme + opacity
SomeView().physicsBackground(.turbulence, scheme: .neonRed, opacity: 0.8)

// Fully assembled config
let config = PhysicsConfig(preset: .coral, scheme: .neonPurple, lighting: .dramatic)
SomeView().physicsBackground(config)
SomeView().physicsBackground(config, opacity: 0.75)
```

Preset changes trigger a full simulation restart with a new seed. Lighting and colour changes take effect on the next frame without resetting the evolved state.

---

## `physicsBorder` — Animated Border

Overlays any view with a live reaction-diffusion border. The simulation runs full-size behind the view; a ring-shaped mask exposes only the border strip.

```swift
Text("Hello")
    .padding(20)
    .physicsBorder(.coral, width: 3, cornerRadius: 12)

Image("photo")
    .physicsBorder(.turbulence, width: 2, lighting: .dramatic, opacity: 0.85)

// Full parameter set
SomeView()
    .physicsBorder(
        .labyrinth,
        width:        2,
        cornerRadius: 16,
        lighting:     .soft,
        opacity:      1.0
    )
```

The corner radius should match the view's own shape.

---

## `PhysicsButton` — Interactive Button

A SwiftUI `Button` whose background is a live simulation. Tapping fires a ring burst of seeds at the press point, creating an expanding chemical reaction that ripples outward.

```swift
PhysicsButton(preset: .turbulence, lighting: .dramatic) {
    print("tapped")
} label: {
    Text("Launch")
        .font(.headline)
        .foregroundStyle(.white)
}

// With custom scheme
PhysicsButton(preset: .mitosis, scheme: .neonCyan, action: {}) {
    Text("Divide").foregroundStyle(.white)
}

// Custom corner radius
PhysicsButton(preset: .coral, lighting: .soft, cornerRadius: 24, action: {}) {
    HStack {
        Image(systemName: "leaf.fill").foregroundStyle(.white)
        Text("Organic").foregroundStyle(.white)
    }
}
```

Includes spring-press animation and haptic feedback on tap.

---

## `PhysicsCanvas` — Interactive Drawing Surface

A full-screen canvas where touch paints V concentration directly into the simulation field. Drag to draw reaction-diffusion patterns in real time.

```swift
// Single interactive canvas
PhysicsCanvas(preset: .turbulence, lighting: .dramatic)

// Custom scheme
PhysicsCanvas(preset: .coral, scheme: .neonPurple, lighting: .soft)
```

---

## `PhysicsDualField` — Two Blended Simulations

Runs two independent simulations and composites them with additive (screen) blending. The two chemical fields evolve separately but share the screen, producing interference patterns where their structures overlap. Touch seeds both fields simultaneously.

```swift
PhysicsDualField()  // defaults: coral/neonPurple + labyrinth/neonCyan

PhysicsDualField(
    primary:      PhysicsConfig(preset: .coral,     scheme: .neonPurple, lighting: .dramatic),
    secondary:    PhysicsConfig(preset: .labyrinth, scheme: .neonCyan,   lighting: .soft),
    blendOpacity: 0.6
)
```

---

## `PhysicsRevealView` — Simulation as a Mask

Uses the simulation as a dynamic reveal mask over arbitrary content. High-V pixels reveal the content beneath; low-V pixels are transparent. The pattern gradually uncovers the content in the shape of its reaction-diffusion structures.

```swift
PhysicsRevealView(preset: .mitosis, threshold: 0.25) {
    LinearGradient(
        colors: [.purple, .cyan, .pink],
        startPoint: .topLeading,
        endPoint:   .bottomTrailing
    )
    .ignoresSafeArea()
}
```

`threshold` (0–1) sets the V level at which the content begins to appear. Lower values reveal content sooner (at lower concentrations).

---

## `PhysicsMorphingView` — Continuous Parameter Morphing

A full-screen simulation that smoothly travels through (feed, kill) parameter space, transitioning between presets over time. Unlike preset switching, the renderer is kept alive — only the simulation parameters are interpolated, so the evolved pattern state is preserved and transforms gradually.

```swift
// Cycle all presets every 12 seconds (default)
PhysicsMorphingView()

// Custom cycle
PhysicsMorphingView(
    presets:       [.coral, .labyrinth, .turbulence],
    cycleInterval: 8,
    lighting:      .dramatic
)

// As a background behind content
ZStack {
    PhysicsMorphingView(cycleInterval: 15)
    YourContent()
}
```

There is also a convenience modifier:

```swift
ContentView()
    .physicsMorphingBackground(
        presets:       [.coral, .labyrinth, .turbulence],
        cycleInterval: 10,
        lighting:      .default,
        opacity:       0.9
    )
```

Transitions produce effects not achievable by switching presets — stripes slowly emerging from branching coral, spots destabilising into chaotic worms, halos condensing into branching structures.

---

## `PhysicsProgressBar` — Live Progress Indicator

A progress bar whose fill is a live simulation, masked to the fill region. The simulation runs full-width at all times — the mask reveals only the filled portion — so the revealed area always shows an evolved, active state rather than a freshly seeded one.

```swift
PhysicsProgressBar(progress: loadProgress, preset: .labyrinth)
    .frame(height: 8)

// Full control
PhysicsProgressBar(
    progress:     downloadProgress,
    preset:       .coral,
    lighting:     .soft,
    cornerRadius: 4,
    trackOpacity: 0.12
)
.frame(height: 6)
```

`progress` is a `Double` in [0, 1]. The fill animates with a spring when the value changes.

---

## Custom Colour Schemes

```swift
let myScheme = PhysicsColourScheme(
    low:      SIMD4(0.000, 0.000, 0.000, 0),  // background — linear RGB
    mid:      SIMD4(0.100, 0.300, 0.500, 0),  // transition zone
    high:     SIMD4(0.000, 0.917, 1.000, 0),  // pattern peak
    midPoint: 0.30,                             // where mid sits in V space [0–1]
    gamma:    1.6                               // >1 sharpens edges; <1 softens
)

SomeView().physicsBackground(.coral, scheme: myScheme)
```

All colour values are **linear RGB**. To convert from sRGB, raise each channel to the power of 2.2: `linear = sRGB ^ 2.2`.

`midPoint` controls where in the V concentration range the mid colour sits. Lower values mean the accent colour blooms sooner; higher values concentrate it at the pattern peaks.

`gamma` is applied to V before colour mapping. Values above 1 produce sharper, more defined edges. Values below 1 produce a softer, more diffuse look.

---

## Custom Lighting

```swift
let myLight = PhysicsLighting(
    colour:      SIMD3(1.00, 0.95, 0.88),  // light colour in linear RGB
    ambient:     0.35,                      // minimum brightness [0–1]
    diffuse:     0.65,                      // Lambertian shading intensity [0–1]
    specular:    0.40,                      // specular highlight intensity [0–1]
    shininess:   32.0,                      // Phong exponent — higher = tighter highlights
    heightScale: 4.0,                       // relief exaggeration — 0 = flat, 8 = deep
    elevation:   .pi / 4,                   // light elevation above surface in radians
    animated:    true,                      // orbit the light around the Z axis
    orbitSpeed:  0.25                       // full orbits per minute
)

SomeView().physicsBackground(.labyrinth, lighting: myLight)
```

The light direction is computed CPU-side from `elevation` and an animated azimuth angle, then passed as a `float3` to the Metal kernel. `heightScale` controls how much the V gradient is exaggerated when computing surface normals via central differences.

---

## `PhysicsConfig` — Assembled Configuration

For use cases where the configuration is built separately from the view:

```swift
let config = PhysicsConfig(preset: .coral)
let config = PhysicsConfig(preset: .coral, lighting: .dramatic)
let config = PhysicsConfig(preset: .coral, scheme: .neonCyan)
let config = PhysicsConfig(preset: .coral, scheme: .neonCyan, lighting: .soft)

SomeView().physicsBackground(config)
SomeView().physicsBackground(config, opacity: 0.8)
```

---

## GPU Pipeline

Each frame:

1. **grayScottStep** (compute) × N — advances the Gray-Scott PDE on ping-pong `rgba16Float` textures
2. **colorizeAndLight** (compute) — maps V concentration to RGB, applies Blinn-Phong normal-map shading
3. **vertexPassthrough** (render) — full-screen quad blit to the MTKView drawable

`N` (steps per frame) varies by preset — `.turbulence` runs 12 steps per frame; `.nebula` runs 3.

The PDE:
```
dU/dt = Du·∇²U − U·V² + feed·(1 − U)
dV/dt = Dv·∇²V + U·V² − (feed + kill)·V
```

---

## License

MIT
