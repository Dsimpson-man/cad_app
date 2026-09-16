// Reference implementation for the next milestone. This file is NOT included in the app target yet.
// Enable only after an iOS OCCT build has been linked into the Xcode project.

#if defined(D_ONE_WITH_OCCT)
#include <BRepPrimAPI_MakeBox.hxx>
#include <BRepMesh_IncrementalMesh.hxx>
#include <BRep_Tool.hxx>
#include <TopExp_Explorer.hxx>
#include <TopoDS.hxx>
#include <TopoDS_Shape.hxx>
#include <TopLoc_Location.hxx>
#include <Poly_Triangulation.hxx>
#include <gp_Pnt.hxx>

static TopoDS_Shape makeBoxOCCT(double w, double d, double h) {
    return BRepPrimAPI_MakeBox(w, d, h).Shape();
}

// The renderer should consume tessellation only. The authoritative model stays TopoDS_Shape/B-Rep.
static void tessellateForGPU(const TopoDS_Shape& shape) {
    BRepMesh_IncrementalMesh mesh(shape, 0.2, false, 0.35, true);
    for (TopExp_Explorer ex(shape, TopAbs_FACE); ex.More(); ex.Next()) {
        const TopoDS_Face face = TopoDS::Face(ex.Current());
        TopLoc_Location loc;
        Handle(Poly_Triangulation) tri = BRep_Tool::Triangulation(face, loc);
        if (tri.IsNull()) continue;
        // Copy tri->Node(i).Transformed(loc.Transformation()) and tri->Triangle(i)
        // into the platform-neutral GPU mesh cache here.
    }
}
#endif
