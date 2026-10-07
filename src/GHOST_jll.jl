module GHOST_jll

using Artifacts, Libdl
import Pkg.Artifacts: ensure_artifact_installed

const artifacts_toml = joinpath(@__DIR__, "..", "Artifacts.toml")
const artifact_name = "ghost_c"

"Resolve an existing override or an installed platform artifact; never rebuild it."
function library_path()
    existing = get(ENV, "GHOST_LIBRARY", "")
    if !isempty(existing)
        isfile(existing) || error("GHOST_LIBRARY does not point to an existing shared library: $existing")
        return abspath(existing)
    end
    hash = artifact_hash(artifact_name, artifacts_toml)
    hash === nothing && error("GHOST's callback ABI has no qualified Artifact for this platform. Supply GHOST_LIBRARY or build the matching Artifact.")
    # The artifact macro installs a declared download only when not already cached.
    ensure_artifact_installed(artifact_name, artifacts_toml)
    root = artifact_path(hash)
    file = Sys.iswindows() ? joinpath(root, "bin", "ghost_c.dll") :
        joinpath(root, "lib", "libghost_c." * Libdl.dlext)
    isfile(file) || error("The GHOST Artifact is missing its C ABI library: $file")
    return file
end

is_available() = try
    isfile(library_path())
catch
    false
end

end
