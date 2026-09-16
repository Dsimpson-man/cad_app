#include "CADCore.h"

#include <algorithm>
#include <array>
#include <cmath>
#include <vector>

namespace {
struct Core {
    float minX = -25.0f;
    float maxX =  25.0f;
    float minY = -20.0f;
    float maxY =  20.0f;
    float minZ =   0.0f;
    float maxZ =  30.0f;

    std::vector<DOCADVertex> vertices;
    std::vector<uint32_t> indices;

    void rebuildBoxMesh() {
        vertices.clear();
        indices.clear();
        vertices.reserve(24);
        indices.reserve(36);

        auto face = [&](uint32_t id,
                        std::array<float,3> n,
                        std::array<std::array<float,3>,4> p) {
            uint32_t base = static_cast<uint32_t>(vertices.size());
            for (auto &v : p) {
                vertices.push_back({v[0],v[1],v[2],n[0],n[1],n[2],id});
            }
            // Counter-clockwise when viewed from outside.
            indices.insert(indices.end(), {base,base+1,base+2, base,base+2,base+3});
        };

        // +X / -X / +Y / -Y / +Z / -Z
        face(0, { 1,0,0}, {{{maxX,minY,minZ},{maxX,maxY,minZ},{maxX,maxY,maxZ},{maxX,minY,maxZ}}});
        face(1, {-1,0,0}, {{{minX,maxY,minZ},{minX,minY,minZ},{minX,minY,maxZ},{minX,maxY,maxZ}}});
        face(2, {0, 1,0}, {{{maxX,maxY,minZ},{minX,maxY,minZ},{minX,maxY,maxZ},{maxX,maxY,maxZ}}});
        face(3, {0,-1,0}, {{{minX,minY,minZ},{maxX,minY,minZ},{maxX,minY,maxZ},{minX,minY,maxZ}}});
        face(4, {0,0, 1}, {{{minX,minY,maxZ},{maxX,minY,maxZ},{maxX,maxY,maxZ},{minX,maxY,maxZ}}});
        face(5, {0,0,-1}, {{{minX,maxY,minZ},{maxX,maxY,minZ},{maxX,minY,minZ},{minX,minY,minZ}}});
    }

    bool valid() const {
        constexpr float eps = 0.1f;
        return maxX-minX > eps && maxY-minY > eps && maxZ-minZ > eps;
    }
};

static Core* asCore(DOCADHandle h) { return reinterpret_cast<Core*>(h); }
}

DOCADHandle docad_create(void) {
    auto *core = new Core();
    core->rebuildBoxMesh();
    return reinterpret_cast<DOCADHandle>(core);
}

void docad_destroy(DOCADHandle handle) {
    delete asCore(handle);
}

bool docad_make_box(DOCADHandle handle, float width, float depth, float height) {
    auto *c = asCore(handle);
    if (!c || width <= 0.1f || depth <= 0.1f || height <= 0.1f) return false;
    c->minX = -width * 0.5f; c->maxX = width * 0.5f;
    c->minY = -depth * 0.5f; c->maxY = depth * 0.5f;
    c->minZ = 0.0f;          c->maxZ = height;
    c->rebuildBoxMesh();
    return true;
}

bool docad_push_pull_face(DOCADHandle handle, uint32_t faceId, float distance) {
    auto *c = asCore(handle);
    if (!c || !std::isfinite(distance)) return false;
    Core old = *c;
    switch (faceId) {
        case 0: c->maxX += distance; break;
        case 1: c->minX -= distance; break;
        case 2: c->maxY += distance; break;
        case 3: c->minY -= distance; break;
        case 4: c->maxZ += distance; break;
        case 5: c->minZ -= distance; break;
        default: return false;
    }
    if (!c->valid()) { *c = old; return false; }
    c->rebuildBoxMesh();
    return true;
}

DOCADMeshView docad_mesh(DOCADHandle handle) {
    auto *c = asCore(handle);
    if (!c) return {nullptr,0,nullptr,0};
    return {c->vertices.data(), static_cast<uint32_t>(c->vertices.size()),
            c->indices.data(), static_cast<uint32_t>(c->indices.size())};
}

float docad_box_width(DOCADHandle handle)  { auto*c=asCore(handle); return c ? c->maxX-c->minX : 0; }
float docad_box_depth(DOCADHandle handle)  { auto*c=asCore(handle); return c ? c->maxY-c->minY : 0; }
float docad_box_height(DOCADHandle handle) { auto*c=asCore(handle); return c ? c->maxZ-c->minZ : 0; }

bool docad_has_occt(void) {
#ifdef D_ONE_WITH_OCCT
    return true;
#else
    return false;
#endif
}
