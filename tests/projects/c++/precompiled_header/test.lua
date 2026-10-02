import("core.tool.toolchain")

function test_build(t)
    t:build()
end

function test_msvc_cache(t)
    if not is_host("windows") then
        return t:skip("wrong host platform")
    end

    local msvc = toolchain.load("msvc", {plat = os.host(), arch = os.arch()})
    if not msvc or not msvc:check() then
        return t:skip("msvc not found")
    end

    local cachedir = os.tmpfile() .. ".dir"
    os.tryrm("build")
    os.exec("xmake f -c -D -y -p windows -a %s --toolchain=msvc --policies=build.ccache --ccachedir=%s", os.arch(), cachedir)
    os.exec("xmake -D")

    os.tryrm("build/.objs")
    os.exec("xmake -D")
    os.tryrm(cachedir)

    local pchfile = os.files("build/.objs/main/windows/**.pch")[1]
    assert(pchfile and os.isfile(pchfile), "precompiled header was not rebuilt when its object came from the cache")
end
