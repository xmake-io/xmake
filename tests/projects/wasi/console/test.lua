import("lib.detect.find_tool")

function test_build_and_run(t)
    if not find_tool("zig") then
        return t:skip("zig not found")
    end
    os.vrun("xmake f -c -y -p wasi -a wasm32 --toolchain=zigcc")
    os.vrun("xmake -y")
    t:require(os.files("build/**/*.wasm")[1])

    if not find_tool("wasmtime") then
        return t:skip("wasmtime not found, build verified but not run")
    end
    local out = os.iorunv("xmake", {"run", "-y"})
    t:require(out and out:find("hello wasi", 1, true))
end
