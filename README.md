# GHOST_jll development artifacts

Binary provider for the regenerated GHOST.jl JuMP/MOI wrapper. Version
`3.5.0+1` targets upstream GHOST's development branch with C ABI 1.0 and Julia
callbacks. It differs from the historical Windows-only `3.5.0+0` build.

`library_path()` first reuses `GHOST_LIBRARY` if it names an existing compatible
library. Otherwise it resolves the matching platform Artifact, downloading only
when that exact artifact is not already cached. It never builds or reinstalls
an existing SDK implicitly. No platform is advertised before native testing.
At this source-preparation stage, `Artifacts.toml` contains no qualified binary.

`gen/build_artifact.jl` is the native artifact build recipe. It requires an
already installed C++20 compiler, CMake and the matching GHOST development
checkout, then builds and tests the C ABI serially. It includes GPL licensing,
the complete corresponding native source archive and the source commit in the
artifact. Local qualification adds only the current platform entry; cross
platform builds must be tested on their actual runners before publication.
