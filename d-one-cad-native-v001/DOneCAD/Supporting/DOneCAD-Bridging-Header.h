//
//  DOneCAD-Bridging-Header.h
//  Exposes the C / Objective-C++ CAD core to Swift.
//
//  Swift sees only the C interface declared in CADCore.h.
//  Everything C++ (libc++, std::vector, and later the OCCT-backed
//  implementation) stays behind the Objective-C++ translation unit
//  CADCore.mm — Swift never includes a C++ header directly.
//

#import "CADCore.h"
