import simd

extension simd_float4x4 {
    static func perspective(fovY: Float, aspect: Float, near: Float, far: Float) -> simd_float4x4 {
        let y = 1 / tan(fovY * 0.5)
        let x = y / aspect
        let z = far / (near - far)
        return simd_float4x4(columns: (
            SIMD4(x,0,0,0),
            SIMD4(0,y,0,0),
            SIMD4(0,0,z,-1),
            SIMD4(0,0,z * near,0)
        ))
    }

    static func lookAt(eye: SIMD3<Float>, center: SIMD3<Float>, up: SIMD3<Float>) -> simd_float4x4 {
        let z = simd_normalize(eye - center)
        let x = simd_normalize(simd_cross(up, z))
        let y = simd_cross(z, x)
        return simd_float4x4(columns: (
            SIMD4(x.x, y.x, z.x, 0),
            SIMD4(x.y, y.y, z.y, 0),
            SIMD4(x.z, y.z, z.z, 0),
            SIMD4(-simd_dot(x, eye), -simd_dot(y, eye), -simd_dot(z, eye), 1)
        ))
    }
}

func rayTriangle(origin: SIMD3<Float>, dir: SIMD3<Float>, a: SIMD3<Float>, b: SIMD3<Float>, c: SIMD3<Float>) -> Float? {
    let eps: Float = 1e-6
    let e1 = b - a
    let e2 = c - a
    let h = simd_cross(dir, e2)
    let det = simd_dot(e1, h)
    if abs(det) < eps { return nil }
    let inv = 1 / det
    let s = origin - a
    let u = inv * simd_dot(s, h)
    if u < 0 || u > 1 { return nil }
    let q = simd_cross(s, e1)
    let v = inv * simd_dot(dir, q)
    if v < 0 || u + v > 1 { return nil }
    let t = inv * simd_dot(e2, q)
    return t > eps ? t : nil
}
