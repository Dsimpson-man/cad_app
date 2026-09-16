import SwiftUI
import MetalKit

struct CADViewport: UIViewRepresentable {
    @ObservedObject var model: CADViewModel

    func makeCoordinator() -> Coordinator { Coordinator(model: model) }

    func makeUIView(context: Context) -> CADMetalView {
        let view = CADMetalView(frame: .zero, device: MTLCreateSystemDefaultDevice())
        view.enableSetNeedsDisplay = true
        view.isPaused = true
        view.isMultipleTouchEnabled = true
        guard let renderer = CADRenderer(view: view) else { return view }
        context.coordinator.renderer = renderer
        view.delegate = renderer
        view.inputDelegate = context.coordinator
        renderer.updateMesh(model.mesh)

        let orbit = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleOrbit(_:)))
        orbit.minimumNumberOfTouches = 1
        orbit.maximumNumberOfTouches = 1
        orbit.allowedTouchTypes = [NSNumber(value: UITouch.TouchType.direct.rawValue)]
        view.addGestureRecognizer(orbit)

        let pan = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        pan.minimumNumberOfTouches = 2
        pan.maximumNumberOfTouches = 2
        view.addGestureRecognizer(pan)

        let pinch = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePinch(_:)))
        view.addGestureRecognizer(pinch)

        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        tap.allowedTouchTypes = [NSNumber(value: UITouch.TouchType.direct.rawValue), NSNumber(value: UITouch.TouchType.indirectPointer.rawValue)]
        view.addGestureRecognizer(tap)
        return view
    }

    func updateUIView(_ view: CADMetalView, context: Context) {
        context.coordinator.model = model
        context.coordinator.renderer?.selectedFaceID = model.selectedFaceID
        context.coordinator.renderer?.updateMesh(model.mesh)
        view.setNeedsDisplay()
    }

    @MainActor
    final class Coordinator: NSObject, CADMetalViewInputDelegate {
        var model: CADViewModel
        var renderer: CADRenderer?
        private var lastTranslation = CGPoint.zero

        init(model: CADViewModel) { self.model = model }

        func cadViewTap(_ point: CGPoint) {
            guard let renderer, let view = renderer.view else { return }
            model.select(faceID: renderer.pickFace(at: point, viewportSize: view.bounds.size))
        }

        func cadViewPencilDrag(delta: CGPoint, ended: Bool) {
            guard model.selectedFaceID != nil else { return }
            if !ended {
                model.pushPull(distance: Float(-delta.y) * 0.12)
            }
        }

        func cadViewOrbit(delta: CGPoint) { renderer?.orbit(dx: Float(delta.x), dy: Float(delta.y)) }
        func cadViewPan(delta: CGPoint) { renderer?.pan(dx: Float(delta.x), dy: Float(delta.y)) }
        func cadViewPinch(scale: CGFloat) { renderer?.zoom(scale: Float(scale)) }

        @objc func handleOrbit(_ g: UIPanGestureRecognizer) {
            let d = g.translation(in: g.view)
            let delta = CGPoint(x: d.x-lastTranslation.x, y: d.y-lastTranslation.y)
            if g.state == .began { lastTranslation = .zero }
            renderer?.orbit(dx: Float(delta.x), dy: Float(delta.y))
            lastTranslation = d
            if g.state == .ended || g.state == .cancelled { lastTranslation = .zero }
        }

        @objc func handlePan(_ g: UIPanGestureRecognizer) {
            let d = g.translation(in: g.view)
            let delta = CGPoint(x: d.x-lastTranslation.x, y: d.y-lastTranslation.y)
            if g.state == .began { lastTranslation = .zero }
            renderer?.pan(dx: Float(delta.x), dy: Float(delta.y))
            lastTranslation = d
            if g.state == .ended || g.state == .cancelled { lastTranslation = .zero }
        }

        @objc func handlePinch(_ g: UIPinchGestureRecognizer) {
            renderer?.zoom(scale: Float(g.scale)); g.scale = 1
        }

        @objc func handleTap(_ g: UITapGestureRecognizer) {
            guard let renderer, let view = g.view as? MTKView else { return }
            let p = g.location(in: view)
            model.select(faceID: renderer.pickFace(at: p, viewportSize: view.bounds.size))
        }
    }
}
