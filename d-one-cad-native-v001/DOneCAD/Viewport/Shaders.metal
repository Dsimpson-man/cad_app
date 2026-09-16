#include <metal_stdlib>
using namespace metal;

struct GPUVertex {
    float4 position;
    float4 normal;
    uint faceID;
    uint3 pad;
};

struct Uniforms {
    float4x4 mvp;
    float3 cameraPosition;
    uint selectedFaceID;
};

struct VSOut {
    float4 position [[position]];
    float3 normal;
    uint faceID [[flat]];
};

vertex VSOut cadVertex(uint vid [[vertex_id]],
                       const device GPUVertex* vertices [[buffer(0)]],
                       constant Uniforms& u [[buffer(1)]]) {
    GPUVertex v = vertices[vid];
    VSOut out;
    out.position = u.mvp * v.position;
    out.normal = v.normal.xyz;
    out.faceID = v.faceID;
    return out;
}

fragment float4 cadFragment(VSOut in [[stage_in]], constant Uniforms& u [[buffer(1)]]) {
    float3 n = normalize(in.normal);
    float3 lightDir = normalize(float3(0.45, -0.3, 0.85));
    float diffuse = max(dot(n, lightDir), 0.0) * 0.45 + 0.55;
    float3 base = float3(0.72, 0.75, 0.79);
    if (in.faceID == u.selectedFaceID) {
        base = float3(0.96, 0.70, 0.12);
    }
    return float4(base * diffuse, 1.0);
}
