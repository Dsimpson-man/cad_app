#pragma once

#include <stdbool.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef void* DOCADHandle;

typedef struct {
    float x, y, z;
    float nx, ny, nz;
    uint32_t faceId;
} DOCADVertex;

typedef struct {
    const DOCADVertex* vertices;
    uint32_t vertexCount;
    const uint32_t* indices;
    uint32_t indexCount;
} DOCADMeshView;

DOCADHandle docad_create(void);
void docad_destroy(DOCADHandle handle);

bool docad_make_box(DOCADHandle handle, float width, float depth, float height);
bool docad_push_pull_face(DOCADHandle handle, uint32_t faceId, float distance);
DOCADMeshView docad_mesh(DOCADHandle handle);

float docad_box_width(DOCADHandle handle);
float docad_box_depth(DOCADHandle handle);
float docad_box_height(DOCADHandle handle);

// Returns true when an OCCT-backed implementation is compiled in.
bool docad_has_occt(void);

#ifdef __cplusplus
}
#endif
