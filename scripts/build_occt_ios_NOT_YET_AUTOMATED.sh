#!/usr/bin/env bash
set -euo pipefail
cat <<'MSG'
OCCT's current source contains iOS-specific CMake branches, but the current public build guide does not list iOS as a first-class supported target.
For that reason this project deliberately does NOT pretend the iOS OCCT build is one-click yet.

Next integration step on a Mac/Xcode machine:
1. Fetch a fixed OCCT release (recommend 7.9.x, not master).
2. Cross-compile arm64 device + arm64 simulator libraries with an iOS CMake toolchain.
3. Package headers/libs into an XCFramework or static-library bundle.
4. Add D_ONE_WITH_OCCT=1 and replace CADCore.mm's prototype box implementation with the OCCT adapter.

Do not static-link/distribute OCCT without reviewing its LGPL-2.1 + OCCT exception obligations.
MSG
