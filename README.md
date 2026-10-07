# GHOST_jll development artifacts

Binary provider for the regenerated GHOST.jl JuMP/MOI wrapper. Version
`3.5.0+2` targets upstream GHOST's development branch with C ABI 1.0 and Julia
callbacks. It differs from the historical Windows-only `3.5.0+0` build.

`library_path()` first reuses `GHOST_LIBRARY` if it names an existing compatible
library. Otherwise it resolves the matching platform Artifact, downloading only
when that exact artifact is not already cached. It never builds or reinstalls
an existing SDK implicitly. No platform is advertised before native testing.
`Artifacts.toml` binds tested Linux x86_64/aarch64, macOS Intel/Apple Silicon
and Windows x86_64 binaries from
[the callback ABI release](https://github.com/JuliaConstraints/GHOST_jll.jl/releases/tag/ghost-cabi-20261007-r2).
The native C ABI tests passed on all five build hosts; the Julia wrapper has its
own qualification gate. The macOS builds were tested on macOS 15; older macOS
versions have not been qualified.

`gen/build_artifact.jl` is the native artifact build recipe. It requires an
already installed C++20 compiler, CMake and the matching GHOST development
checkout, then builds and tests the C ABI serially. It includes GPL licensing,
the complete corresponding native source archive and the source commit in the
artifact. Local qualification adds only the current platform entry. The
[native CI workflow](https://github.com/JuliaConstraints/GHOST_jll.jl/actions/runs/37613088663)
qualified the published builds on their actual runners before publication.

The Li-Lim handoff pins the tested source revision and binary release. Updating
this README does not move that frozen cohort or replace existing Artifacts.
