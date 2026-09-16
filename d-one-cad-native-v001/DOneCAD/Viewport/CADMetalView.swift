import MetalKit
import UIKit

protocol CADMetalViewInputDelegate: AnyObject {
    func cadViewTap(_ point: CGPoint)
    func cadViewPencilDrag(delta: CGPoint, ended: Bool)
    func cadViewOrbit(delta: CGPoint)
    func cadViewPan(delta: CGPoint)
    func cadViewPinch(scale: CGFloat)
}

final class CADMetalView: MTKView {
    weak var inputDelegate: CADMetalViewInputDelegate?
    private var pencilStart: CGPoint?
    private var lastPencil: CGPoint?

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let t = touches.first, t.type == .pencil else { return super.touchesBegan(touches, with: event) }
        let p = t.location(in: self)
        pencilStart = p
        lastPencil = p
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let t = touches.first, t.type == .pencil, let lastPencil else { return super.touchesMoved(touches, with: event) }
        let p = t.location(in: self)
        let d = CGPoint(x: p.x-lastPencil.x, y: p.y-lastPencil.y)
        self.lastPencil = p
        inputDelegate?.cadViewPencilDrag(delta: d, ended: false)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let t = touches.first, t.type == .pencil else { return super.touchesEnded(touches, with: event) }
        let p = t.location(in: self)
        if let start = pencilStart, hypot(p.x-start.x, p.y-start.y) < 8 {
            inputDelegate?.cadViewTap(p)
        } else {
            inputDelegate?.cadViewPencilDrag(delta: .zero, ended: true)
        }
        pencilStart = nil
        lastPencil = nil
    }
}
