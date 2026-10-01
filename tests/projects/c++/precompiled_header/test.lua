import("core.tool.toolchain")

function test_build(t)
    t:build()
end

function test_clang_cl_dependencies(t)
    if not is_host("windows") then
        return t:skip("wrong host platform")
    end

    local clang_cl = toolchain.load("clang-cl", {plat = os.host(), arch = os.arch()})
    if not clang_cl or not clang_cl:check() then
        return t:skip("clang-cl not found")
    end

    os.tryrm("build")
    os.exec("xmake f -c -D -y -p windows -a %s --toolchain=clang-cl --cxflags=-external:W0", os.arch())

    local wrapperfile = os.files("build/.gens/main/windows/**/header.h")[1]
    assert(wrapperfile and os.isfile(wrapperfile), "precompiled header wrapper not found")
    local wrapper = io.readfile(wrapperfile)
    io.writefile(wrapperfile, "#pragma system_header\n" .. wrapper)

    os.exec("xmake f -c -D -y -p windows -a %s --toolchain=clang-cl --cxflags=-external:W0", os.arch())
    assert(io.readfile(wrapperfile) == wrapper, "stale precompiled header wrapper was not updated")

    local wrappermtime = os.mtime(wrapperfile)
    os.sleep(1000)
    os.exec("xmake f -c -D -y -p windows -a %s --toolchain=clang-cl --cxflags=-external:W0", os.arch())
    assert(os.mtime(wrapperfile) == wrappermtime, "unchanged precompiled header wrapper was rewritten")

    os.exec("xmake -D")

    local pchfile = os.files("build/.objs/main/windows/**/header.h.pch")[1]
    assert(pchfile and os.isfile(pchfile), "precompiled header not found")
    local objectfile = os.files("build/.objs/main/windows/**/main.cpp.obj")[1]
    assert(objectfile and os.isfile(objectfile), "object file not found")
    local pchmtime = os.mtime(pchfile)
    local objectmtime = os.mtime(objectfile)

    os.sleep(1000)
    os.touch("src/header2.h", {mtime = os.time()})
    os.exec("xmake -D")
    assert(os.mtime(pchfile) > pchmtime, "precompiled header was not rebuilt after an included header changed")
    assert(os.mtime(objectfile) > objectmtime, "object file was not rebuilt after a precompiled header dependency changed")
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
