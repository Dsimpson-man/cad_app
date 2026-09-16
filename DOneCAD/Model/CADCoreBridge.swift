import Foundation
import simd

struct CADMeshSnapshot {
    struct Vertex {
        let position: SIMD3<Float>
        let normal: SIMD3<Float>
        let faceID: UInt32
    }
    var vertices: [Vertex]
    var indices: [UInt32]
}

final class CADCoreBridge {
    private var handle: DOCADHandle?

    init() {
        handle = docad_create()
    }

    deinit {
        if let handle { docad_destroy(handle) }
    }

    var hasOCCT: Bool { docad_has_occt() }

    @discardableResult
    func makeBox(width: Float, depth: Float, height: Float) -> Bool {
        guard let handle else { return false }
        return docad_make_box(handle, width, depth, height)
    }

    @discardableResult
    func pushPull(faceID: UInt32, distance: Float) -> Bool {
        guard let handle else { return false }
        return docad_push_pull_face(handle, faceID, distance)
    }

    func dimensions() -> SIMD3<Float> {
        guard let handle else { return .zero }
        return SIMD3(docad_box_width(handle), docad_box_depth(handle), docad_box_height(handle))
    }

    func mesh() -> CADMeshSnapshot {
        guard let handle else { return CADMeshSnapshot(vertices: [], indices: []) }
        let view = docad_mesh(handle)
        guard let vertexPtr = view.vertices, let indexPtr = view.indices else {
            return CADMeshSnapshot(vertices: [], indices: [])
        }
        let vertices = UnsafeBufferPointer(start: vertexPtr, count: Int(view.vertexCount)).map {
            CADMeshSnapshot.Vertex(
                position: SIMD3($0.x, $0.y, $0.z),
                normal: SIMD3($0.nx, $0.ny, $0.nz),
                faceID: $0.faceId
            )
        }
        let indices = Array(UnsafeBufferPointer(start: indexPtr, count: Int(view.indexCount)))
        return CADMeshSnapshot(vertices: vertices, indices: indices)
    }
}
