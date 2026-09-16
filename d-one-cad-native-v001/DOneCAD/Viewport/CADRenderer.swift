import MetalKit
import simd

final class CADRenderer: NSObject, MTKViewDelegate {
    struct GPUVertex {
        var position: SIMD4<Float>
        var normal: SIMD4<Float>
        var faceID: UInt32
        var pad: SIMD3<UInt32> = .zero
    }

    struct Uniforms {
        var mvp: simd_float4x4
        var cameraPosition: SIMD3<Float>
        var selectedFaceID: UInt32
    }

    weak var view: MTKView?
    private let device: MTLDevice
    private let queue: MTLCommandQueue
    private let pipeline: MTLRenderPipelineState
    private let depthState: MTLDepthStencilState

    private var vertexBuffer: MTLBuffer?
    private var indexBuffer: MTLBuffer?
    private(set) var mesh = CADMeshSnapshot(vertices: [], indices: [])

    var selectedFaceID: UInt32? = nil
    var yaw: Float = -0.7
    var pitch: Float = 0.55
    var distance: Float = 135
    var target = SIMD3<Float>(0,0,15)

    init?(view: MTKView) {
        guard let device = view.device ?? MTLCreateSystemDefaultDevice(),
              let queue = device.makeCommandQueue(),
              let library = device.makeDefaultLibrary(),
              let vs = library.makeFunction(name: "cadVertex"),
              let fs = library.makeFunction(name: "cadFragment") else { return nil }

        self.view = view
        self.device = device
        self.queue = queue

        let desc = MTLRenderPipelineDescriptor()
        desc.vertexFunction = vs
        desc.fragmentFunction = fs
        desc.colorAttachments[0].pixelFormat = .bgra8Unorm
        desc.depthAttachmentPixelFormat = .depth32Float
        do { pipeline = try device.makeRenderPipelineState(descriptor: desc) }
        catch { return nil }

        let d = MTLDepthStencilDescriptor()
        d.depthCompareFunction = .less
        d.isDepthWriteEnabled = true
        guard let depth = device.makeDepthStencilState(descriptor: d) else { return nil }
        depthState = depth
        super.init()

        view.device = device
        view.colorPixelFormat = .bgra8Unorm
        view.depthStencilPixelFormat = .depth32Float
        view.clearColor = MTLClearColor(red: 0.105, green: 0.115, blue: 0.13, alpha: 1)
        view.preferredFramesPerSecond = 60
    }

    func updateMesh(_ mesh: CADMeshSnapshot) {
        self.mesh = mesh
        let gpu = mesh.vertices.map { GPUVertex(position: SIMD4($0.position,1), normal: SIMD4($0.normal,0), faceID: $0.faceID) }
        vertexBuffer = gpu.withUnsafeBytes { bytes in
            guard let base = bytes.baseAddress, bytes.count > 0 else { return nil }
            return device.makeBuffer(bytes: base, length: bytes.count, options: .storageModeShared)
        }
        indexBuffer = mesh.indices.withUnsafeBytes { bytes in
            guard let base = bytes.baseAddress, bytes.count > 0 else { return nil }
            return device.makeBuffer(bytes: base, length: bytes.count, options: .storageModeShared)
        }
        view?.setNeedsDisplay()
    }

    func cameraPosition() -> SIMD3<Float> {
        let cp = cos(pitch), sp = sin(pitch), cy = cos(yaw), sy = sin(yaw)
        return target + SIMD3<Float>(distance * cp * cy, distance * cp * sy, distance * sp)
    }

    func viewProjection(size: CGSize) -> simd_float4x4 {
        let aspect = Float(max(size.width, 1) / max(size.height, 1))
        let p = simd_float4x4.perspective(fovY: 45 * .pi / 180, aspect: aspect, near: 0.1, far: 2000)
        let v = simd_float4x4.lookAt(eye: cameraPosition(), center: target, up: SIMD3(0,0,1))
        return p * v
    }

    func orbit(dx: Float, dy: Float) {
        yaw -= dx * 0.007
        pitch = max(-1.45, min(1.45, pitch + dy * 0.007))
        view?.setNeedsDisplay()
    }

    func zoom(scale: Float) {
        distance = max(20, min(800, distance / max(scale, 0.01)))
        view?.setNeedsDisplay()
    }

    func pan(dx: Float, dy: Float) {
        let eye = cameraPosition()
        let forward = simd_normalize(target - eye)
        let right = simd_normalize(simd_cross(forward, SIMD3<Float>(0,0,1)))
        let up = simd_normalize(simd_cross(right, forward))
        let factor = distance * 0.0015
        target += (-right * dx + up * dy) * factor
        view?.setNeedsDisplay()
    }

    func pickFace(at point: CGPoint, viewportSize: CGSize) -> UInt32? {
        guard !mesh.indices.isEmpty else { return nil }
        let x = Float((2 * point.x / max(viewportSize.width, 1)) - 1)
        let y = Float(1 - (2 * point.y / max(viewportSize.height, 1)))
        let inv = simd_inverse(viewProjection(size: viewportSize))
        func unproject(_ z: Float) -> SIMD3<Float> {
            var p = inv * SIMD4<Float>(x,y,z,1)
            p /= p.w
            return SIMD3(p.x,p.y,p.z)
        }
        let near = unproject(0)
        let far = unproject(1)
        let dir = simd_normalize(far - near)

        var bestT = Float.greatestFiniteMagnitude
        var bestFace: UInt32?
        for i in stride(from: 0, to: mesh.indices.count, by: 3) {
            let i0 = Int(mesh.indices[i]), i1 = Int(mesh.indices[i+1]), i2 = Int(mesh.indices[i+2])
            guard i0 < mesh.vertices.count, i1 < mesh.vertices.count, i2 < mesh.vertices.count else { continue }
            let a = mesh.vertices[i0].position, b = mesh.vertices[i1].position, c = mesh.vertices[i2].position
            if let t = rayTriangle(origin: near, dir: dir, a: a, b: b, c: c), t < bestT {
                bestT = t
                bestFace = mesh.vertices[i0].faceID
            }
        }
        return bestFace
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let pass = view.currentRenderPassDescriptor,
              let vb = vertexBuffer, let ib = indexBuffer,
              let command = queue.makeCommandBuffer(),
              let encoder = command.makeRenderCommandEncoder(descriptor: pass) else { return }

        var uniforms = Uniforms(
            mvp: viewProjection(size: view.bounds.size),
            cameraPosition: cameraPosition(),
            selectedFaceID: selectedFaceID ?? UInt32.max
        )
        encoder.setRenderPipelineState(pipeline)
        encoder.setDepthStencilState(depthState)
        encoder.setCullMode(.back)
        encoder.setFrontFacing(.counterClockwise)
        encoder.setVertexBuffer(vb, offset: 0, index: 0)
        encoder.setVertexBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: 1)
        encoder.setFragmentBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: 1)
        encoder.drawIndexedPrimitives(type: .triangle,
                                      indexCount: mesh.indices.count,
                                      indexType: .uint32,
                                      indexBuffer: ib,
                                      indexBufferOffset: 0)
        encoder.endEncoding()
        command.present(drawable)
        command.commit()
    }
}
