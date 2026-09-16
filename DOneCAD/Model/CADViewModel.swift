import Foundation
import simd

@MainActor
final class CADViewModel: ObservableObject {
    @Published private(set) var mesh = CADMeshSnapshot(vertices: [], indices: [])
    @Published var selectedFaceID: UInt32? = nil
    @Published private(set) var dimensions = SIMD3<Float>(50, 40, 30)
    @Published var status = "Ready"

    private let core = CADCoreBridge()

    init() {
        reloadMesh()
        status = core.hasOCCT ? "OCCT core" : "Prototype C++ core"
    }

    var coreLabel: String { core.hasOCCT ? "OCCT" : "C++ Prototype" }

    func resetBox() {
        _ = core.makeBox(width: 50, depth: 40, height: 30)
        selectedFaceID = nil
        reloadMesh()
        status = "New Box 50 × 40 × 30 mm"
    }

    func setBox(width: Float, depth: Float, height: Float) {
        if core.makeBox(width: width, depth: depth, height: height) {
            selectedFaceID = nil
            reloadMesh()
            status = "Box updated"
        }
    }

    func select(faceID: UInt32?) {
        selectedFaceID = faceID
        if let faceID { status = "Face \(faceID + 1) selected" }
        else { status = "Selection cleared" }
    }

    func pushPull(distance: Float) {
        guard let selectedFaceID else { return }
        guard abs(distance) > 0.0001 else { return }
        if core.pushPull(faceID: selectedFaceID, distance: distance) {
            reloadMesh()
            status = String(format: "Push/Pull %.2f mm", distance)
        }
    }

    private func reloadMesh() {
        mesh = core.mesh()
        dimensions = core.dimensions()
    }
}
