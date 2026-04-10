//
//  GrayScottRenderer.swift
//  PhysicsBackground
//
//  Metal rendering engine. Conforms to MTKViewDelegate.
//  Owns the full GPU pipeline: ping-pong simulation → colorizeAndLight → render.
//
//  Extended capabilities (v2):
//    plantSeed(at:radius:)  — CPU-side V injection into shared sim texture
//    morphTo(preset:)       — smooth parameter-space travel between presets
//    smoothUpdatePreset(_:) — called by MetalSimView.updateUIView for morph views
//    updateLighting(_:)     — hot-swap lighting without restarting simulation
//    seedController         — Combine subscription for SwiftUI-driven seeding
//

import Metal
import MetalKit
import QuartzCore
import Combine
import simd

// MARK: - GPU uniform structs

struct SimUniforms {
    var Du:     Float
    var Dv:     Float
    var feed:   Float
    var kill:   Float
    var dt:     Float
    var width:  UInt32
    var height: UInt32
}

struct ColourUniforms {
    var low:      SIMD4<Float>
    var mid:      SIMD4<Float>
    var high:     SIMD4<Float>
    var midPoint: Float
    var gamma:    Float
}

/// Layout: 64 bytes (two float4 + five floats + 12-byte implicit padding).
struct LightingUniforms {
    var lightDir:    SIMD4<Float>
    var lightColour: SIMD4<Float>
    var ambient:     Float
    var diffuse:     Float
    var specular:    Float
    var shininess:   Float
    var heightScale: Float
}

// MARK: - GrayScottRenderer

public final class GrayScottRenderer: NSObject, MTKViewDelegate {

    let device: MTLDevice

    private let commandQueue:        MTLCommandQueue
    private let stepPipeline:        MTLComputePipelineState
    private let colorizePipeline:    MTLComputePipelineState
    private let colorizeLitPipeline: MTLComputePipelineState
    private let renderPipeline:      MTLRenderPipelineState

    private var pingTex:    MTLTexture
    private var pongTex:    MTLTexture
    private var displayTex: MTLTexture

    private var simUniforms:      SimUniforms
    private var colUniforms:      ColourUniforms
    private var lightingUniforms: LightingUniforms

    private let threadgroupSize:  MTLSize
    private let threadgroupCount: MTLSize
    private let stepsPerFrame:    Int
    private let texSize:          Int

    private var lighting:   PhysicsLighting
    private let startTime:  CFTimeInterval

    // ── Parameter morphing ────────────────────────────────────────────────────
    private var morphSource:    SimUniforms?
    private var morphTarget:    SimUniforms?
    private var morphStartTime: CFTimeInterval = 0
    private var morphDuration:  Double         = 6.0
    private var lastMorphKey:   String         = ""

    // ── Seed controller subscription ─────────────────────────────────────────
    private var seedCancellable: AnyCancellable?

    // MARK: init

    init?(
        config:         PhysicsConfig,
        seedController: PhysicsSeedController? = nil,
        texSize:        Int                    = 512
    ) {
        guard
            let dev   = MTLCreateSystemDefaultDevice(),
            let queue = dev.makeCommandQueue()
        else { return nil }

        self.device        = dev
        self.commandQueue  = queue
        self.texSize       = texSize
        self.stepsPerFrame = config.preset.stepsPerFrame
        self.lighting      = config.lighting
        self.startTime     = CACurrentMediaTime()
        self.lastMorphKey  = config.preset.rawValue

        guard let lib = try? dev.makeDefaultLibrary(bundle: .module) else {
            assertionFailure("GrayScottRenderer: could not load Metal library from package bundle.")
            return nil
        }

        guard
            let stepFn        = lib.makeFunction(name: "grayScottStep"),
            let colorizeFn    = lib.makeFunction(name: "colorize"),
            let colorizeLitFn = lib.makeFunction(name: "colorizeAndLight"),
            let vertFn        = lib.makeFunction(name: "vertexPassthrough"),
            let fragFn        = lib.makeFunction(name: "fragmentPassthrough")
        else { return nil }

        guard
            let stepPipe     = try? dev.makeComputePipelineState(function: stepFn),
            let colorizePipe = try? dev.makeComputePipelineState(function: colorizeFn),
            let colLitPipe   = try? dev.makeComputePipelineState(function: colorizeLitFn)
        else { return nil }

        let rpd = MTLRenderPipelineDescriptor()
        rpd.vertexFunction                  = vertFn
        rpd.fragmentFunction                = fragFn
        rpd.colorAttachments[0].pixelFormat = .bgra8Unorm

        guard let renderPipe = try? dev.makeRenderPipelineState(descriptor: rpd) else { return nil }

        self.stepPipeline        = stepPipe
        self.colorizePipeline    = colorizePipe
        self.colorizeLitPipeline = colLitPipe
        self.renderPipeline      = renderPipe

        // Simulation textures — rgba16Float, shared (CPU-writable for seeding).
        let simDesc = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba16Float, width: texSize, height: texSize, mipmapped: false)
        simDesc.usage       = [.shaderRead, .shaderWrite]
        simDesc.storageMode = .shared

        guard
            let ping    = dev.makeTexture(descriptor: simDesc),
            let pong    = dev.makeTexture(descriptor: simDesc)
        else { return nil }

        // Display texture — rgba8Unorm, GPU-private.
        let dispDesc = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba8Unorm, width: texSize, height: texSize, mipmapped: false)
        dispDesc.usage       = [.shaderRead, .shaderWrite]
        dispDesc.storageMode = .private

        guard let display = dev.makeTexture(descriptor: dispDesc) else { return nil }

        self.pingTex    = ping
        self.pongTex    = pong
        self.displayTex = display

        self.threadgroupSize  = MTLSize(width: 16, height: 16, depth: 1)
        self.threadgroupCount = MTLSize(
            width:  (texSize + 15) / 16,
            height: (texSize + 15) / 16,
            depth:  1)

        let s = config.preset
        let c = config.scheme
        self.simUniforms = SimUniforms(
            Du: s.Du, Dv: s.Dv, feed: s.feed, kill: s.kill, dt: s.dt,
            width: UInt32(texSize), height: UInt32(texSize))
        self.colUniforms = ColourUniforms(
            low: c.low, mid: c.mid, high: c.high, midPoint: c.midPoint, gamma: c.gamma)
        self.lightingUniforms = LightingUniforms(
            lightDir:    SIMD4(0, 0, 1, 0),
            lightColour: SIMD4(config.lighting.colour.x, config.lighting.colour.y,
                               config.lighting.colour.z, 0),
            ambient:  config.lighting.ambient,  diffuse:  config.lighting.diffuse,
            specular: config.lighting.specular, shininess: config.lighting.shininess,
            heightScale: config.lighting.heightScale)

        super.init()
        seed()

        // Wire up seed controller after super.init() — self is available.
        if let controller = seedController {
            seedCancellable = controller.pipe
                .receive(on: DispatchQueue.main)
                .sink { [weak self] (point, radius) in
                    self?.plantSeed(at: point, radius: radius)
                }
        }
    }

    // MARK: - Public controls

    /// Hot-swap lighting without restarting the simulation.
    func updateLighting(_ newLighting: PhysicsLighting) {
        lighting = newLighting
    }

    /// Smoothly morph simulation parameters to a new preset over `duration` seconds.
    /// Safe to call every frame — deduplicates by preset key.
    func smoothUpdatePreset(_ preset: PhysicsPreset) {
        guard preset.rawValue != lastMorphKey else { return }
        lastMorphKey = preset.rawValue
        morphTo(preset: preset, duration: 6.0)
    }

    /// Begin a smooth parameter-space transition to `preset`.
    func morphTo(preset: PhysicsPreset, duration: Double = 6.0) {
        morphSource    = simUniforms
        morphTarget    = makeSimUniforms(from: preset)
        morphStartTime = CACurrentMediaTime()
        morphDuration  = duration
    }

    // MARK: - Seed injection
    //
    // Writes V concentration into a small region of pingTex from the CPU.
    // pingTex uses .shared storage so CPU/GPU share the same physical memory
    // on Apple Silicon — no DMA transfer, only cache coherence.
    // At 30 fps the write window (between GPU frames) is ~33 ms; in practice
    // this never conflicts with an in-flight GPU read.

    func plantSeed(at normalised: CGPoint, radius: Float = 25) {
        let cx   = Float(normalised.x) * Float(texSize)
        let cy   = Float(normalised.y) * Float(texSize)
        let ir   = Int(radius) + 1
        let minX = max(0, Int(cx) - ir);  let minY = max(0, Int(cy) - ir)
        let maxX = min(texSize - 1, Int(cx) + ir)
        let maxY = min(texSize - 1, Int(cy) + ir)
        let w    = maxX - minX + 1;  let h = maxY - minY + 1

        var buf = [Float16](repeating: 0, count: w * h * 4)
        let stride = w * 4 * MemoryLayout<Float16>.stride

        pingTex.getBytes(&buf, bytesPerRow: stride,
                         from: MTLRegionMake2D(minX, minY, w, h), mipmapLevel: 0)

        for dy in 0..<h {
            for dx in 0..<w {
                let fx   = Float(minX + dx) - cx
                let fy   = Float(minY + dy) - cy
                let dist = sqrt(fx * fx + fy * fy)
                guard dist < radius else { continue }
                let t = 1.0 - dist / radius
                let i = (dy * w + dx) * 4
                buf[i]     = Float16(max(Float(buf[i])     - t * 0.4, 0))
                buf[i + 1] = Float16(min(Float(buf[i + 1]) + t * 0.8, 1))
            }
        }

        pingTex.replace(region: MTLRegionMake2D(minX, minY, w, h),
                        mipmapLevel: 0, withBytes: &buf, bytesPerRow: stride)
    }

    // MARK: - Gesture handlers (wired up by MetalSimView when interactionsEnabled)

    @objc func handleTap(_ g: UITapGestureRecognizer) {
        guard let v = g.view else { return }
        let p = g.location(in: v)
        plantSeed(at: CGPoint(x: p.x / v.bounds.width, y: p.y / v.bounds.height), radius: 28)
    }

    @objc func handlePan(_ g: UIPanGestureRecognizer) {
        guard let v = g.view else { return }
        let p = g.location(in: v)
        plantSeed(at: CGPoint(x: p.x / v.bounds.width, y: p.y / v.bounds.height), radius: 16)
    }

    // MARK: - Seed

    private func seed() {
        var pixels = [Float16](repeating: .zero, count: texSize * texSize * 4)
        for i in 0..<(texSize * texSize) {
            pixels[i * 4]     = Float16(1.0)
            pixels[i * 4 + 3] = Float16(1.0)
        }

        func plant(cx: Int, cy: Int, radius: Int) {
            for dy in -radius..<radius {
                for dx in -radius..<radius {
                    let x = cx + dx; let y = cy + dy
                    guard x >= 0, x < texSize, y >= 0, y < texSize else { continue }
                    let dist     = sqrt(Float(dx * dx + dy * dy))
                    let strength = max(0, 1.0 - dist / Float(radius))
                    let idx      = y * texSize + x
                    pixels[idx * 4]     = Float16(1.0 - strength * 0.5)
                    pixels[idx * 4 + 1] = Float16(Float.random(in: 0.6...1.0) * strength)
                }
            }
        }

        plant(cx: texSize / 2, cy: texSize / 2, radius: texSize / 10)
        var rng = XorShift64(seed: 0x50485942)
        for _ in 0..<24 {
            let cx = Int(rng.next() % UInt64(texSize - 20)) + 10
            let cy = Int(rng.next() % UInt64(texSize - 20)) + 10
            let r  = Int(rng.next() % 10) + 4
            plant(cx: cx, cy: cy, radius: r)
        }

        pingTex.replace(
            region:      MTLRegionMake2D(0, 0, texSize, texSize),
            mipmapLevel: 0,
            withBytes:   &pixels,
            bytesPerRow: texSize * 4 * MemoryLayout<Float16>.stride)
    }

    // MARK: - MTKViewDelegate

    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) { }

    public func draw(in view: MTKView) {
        guard
            let drawable       = view.currentDrawable,
            let renderPassDesc = view.currentRenderPassDescriptor,
            let cmdBuf         = commandQueue.makeCommandBuffer()
        else { return }

        // ── Parameter morphing ────────────────────────────────────────────────
        if let src = morphSource, let tgt = morphTarget {
            let t = Float(min((CACurrentMediaTime() - morphStartTime) / morphDuration, 1.0))
            let s = t * t * (3 - 2 * t)   // smoothstep easing
            simUniforms = lerpUniforms(src, tgt, t: s)
            if t >= 1.0 { morphSource = nil; morphTarget = nil }
        }

        // ── Lighting uniforms ─────────────────────────────────────────────────
        let elapsed = Float(CACurrentMediaTime() - startTime)
        let angle:  Float = lighting.animated ? elapsed * lighting.orbitSpeed * 2 * .pi / 60 : 0
        let elev          = lighting.elevation
        lightingUniforms = LightingUniforms(
            lightDir:    SIMD4(cos(angle) * cos(elev), sin(angle) * cos(elev), sin(elev), 0),
            lightColour: SIMD4(lighting.colour.x, lighting.colour.y, lighting.colour.z, 0),
            ambient:  lighting.ambient,  diffuse:  lighting.diffuse,
            specular: lighting.specular, shininess: lighting.shininess,
            heightScale: lighting.heightScale)

        // ── Simulation steps ──────────────────────────────────────────────────
        for _ in 0..<stepsPerFrame {
            guard let ce = cmdBuf.makeComputeCommandEncoder() else { continue }
            ce.setComputePipelineState(stepPipeline)
            ce.setTexture(pingTex, index: 0)
            ce.setTexture(pongTex, index: 1)
            ce.setBytes(&simUniforms, length: MemoryLayout<SimUniforms>.stride, index: 0)
            ce.dispatchThreadgroups(threadgroupCount, threadsPerThreadgroup: threadgroupSize)
            ce.endEncoding()
            swap(&pingTex, &pongTex)
        }

        // ── Colorize + light ──────────────────────────────────────────────────
        if let ce = cmdBuf.makeComputeCommandEncoder() {
            if lighting.isActive {
                ce.setComputePipelineState(colorizeLitPipeline)
                ce.setTexture(pingTex,    index: 0)
                ce.setTexture(displayTex, index: 1)
                ce.setBytes(&colUniforms,      length: MemoryLayout<ColourUniforms>.stride,   index: 0)
                ce.setBytes(&lightingUniforms, length: MemoryLayout<LightingUniforms>.stride, index: 1)
            } else {
                ce.setComputePipelineState(colorizePipeline)
                ce.setTexture(pingTex,    index: 0)
                ce.setTexture(displayTex, index: 1)
                ce.setBytes(&colUniforms, length: MemoryLayout<ColourUniforms>.stride, index: 0)
            }
            ce.dispatchThreadgroups(threadgroupCount, threadsPerThreadgroup: threadgroupSize)
            ce.endEncoding()
        }

        // ── Full-screen quad ──────────────────────────────────────────────────
        if let re = cmdBuf.makeRenderCommandEncoder(descriptor: renderPassDesc) {
            re.setRenderPipelineState(renderPipeline)
            re.setFragmentTexture(displayTex, index: 0)
            re.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
            re.endEncoding()
        }

        cmdBuf.present(drawable)
        cmdBuf.commit()
    }

    // MARK: - Helpers

    private func makeSimUniforms(from preset: PhysicsPreset) -> SimUniforms {
        SimUniforms(Du: preset.Du, Dv: preset.Dv, feed: preset.feed, kill: preset.kill,
                    dt: preset.dt, width: UInt32(texSize), height: UInt32(texSize))
    }

    private func lerpUniforms(_ a: SimUniforms, _ b: SimUniforms, t: Float) -> SimUniforms {
        func mix(_ x: Float, _ y: Float) -> Float { x + (y - x) * t }
        return SimUniforms(Du: mix(a.Du, b.Du), Dv: mix(a.Dv, b.Dv),
                           feed: mix(a.feed, b.feed), kill: mix(a.kill, b.kill),
                           dt: a.dt, width: a.width, height: a.height)
    }
}

// MARK: - XorShift64

private struct XorShift64 {
    private var state: UInt64
    init(seed: UInt64) { state = seed == 0 ? 1 : seed }
    mutating func next() -> UInt64 {
        state ^= state << 13; state ^= state >> 7; state ^= state << 17; return state
    }
}
