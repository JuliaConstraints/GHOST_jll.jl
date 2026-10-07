# Build distribution source, not a solver launcher. No dependency is installed.
using Pkg, TOML, SHA
using Pkg.Artifacts
using Base.BinaryPlatforms

function build_artifact(source::String, revision::String, archive::String; download_url=nothing)
    source = abspath(source)
    archive = abspath(archive)
    for executable in ("git", "cmake", "ctest")
        Sys.which(executable) === nothing && error("Missing $executable; install your build tools explicitly")
    end
    isempty(strip(read(`git -C $source status --porcelain`, String))) || error("Native sources must be committed and clean before packaging")
    commit = strip(read(`git -C $source rev-parse $revision`, String))
    current = strip(read(`git -C $source rev-parse HEAD`, String))
    current == commit || error("The native checkout does not match the requested source revision")
    upstream = "37bbfdf612af229cf9fbb9688995cae268c53a64"
    success(`git -C $source merge-base --is-ancestor $upstream $commit`) || error("Native sources must include the pinned upstream development baseline")
    ispath(archive) && error("Refusing to replace an existing archive: $archive")
    hash = mktempdir() do directory
        build = joinpath(directory, "build")
        prefix = joinpath(directory, "prefix")
        run(`cmake -S $source -B $build -DCMAKE_BUILD_TYPE=Release -DGHOST_C_API_ONLY=ON -DNO_ASAN=ON -DBUILD_TESTING=ON`)
        run(`cmake --build $build --config Release --target ghost_c test_ghost_c_api --parallel 1`)
        run(`ctest --test-dir $build -C Release --output-on-failure`)
        run(`cmake --install $build --config Release --prefix $prefix`)
        # Carry all corresponding GPL source and licensing with the binary.
        shared = joinpath(prefix, "share", "ghost")
        mkpath(shared)
        cp(joinpath(source, "LICENSE"), joinpath(shared, "LICENSE"))
        run(`git -C $source archive --format=tar.gz --output=$(joinpath(shared,"source.tar.gz")) $commit`)
        information = Dict("native_commit" => commit, "upstream_develop_commit" => upstream,
            "abi" => "1.0", "platform" => triplet(HostPlatform()),
            "recipe_sha256" => bytes2hex(sha256(read(@__FILE__))),
            "qualification" => "native C ABI tests passed; Julia frontend qualification is separate")
        open(joinpath(shared, "provenance.toml"), "w") do io
            TOML.print(io, information; sorted=true)
        end
        create_artifact() do destination
            for entry in readdir(prefix)
                cp(joinpath(prefix, entry), joinpath(destination, entry))
            end
        end
    end
    mkpath(dirname(archive))
    checksum = archive_artifact(hash, archive)
    metadata = joinpath(@__DIR__, "..", "Artifacts.toml")
    downloads = download_url === nothing ? Tuple{String,String}[] : [(String(download_url), checksum)]
    bind_artifact!(metadata, "ghost_c", hash; platform=HostPlatform(), download_info=downloads, force=true)
    println("Native Artifact: ", hash, " (", triplet(HostPlatform()), ")")
    println("Archive SHA256: ", checksum)
    println("Julia frontend tests still need this artifact before distribution.")
    return hash
end

if abspath(PROGRAM_FILE) == @__FILE__
    length(ARGS) in (3,4) || error("Usage: julia gen/build_artifact.jl SOURCE_DIR NATIVE_COMMIT OUTPUT_TAR_GZ [DOWNLOAD_URL]")
    build_artifact(ARGS[1], ARGS[2], ARGS[3]; download_url=length(ARGS)==4 ? ARGS[4] : nothing)
end
