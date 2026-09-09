import("lib.detect.find_tool")

function test_conan_generator_quoted_flags(t)
    local python = find_tool("python3") or find_tool("python")
    if not python then
        return t:skip("python not found")
    end
    local generator = path.join(os.programdir(), "scripts", "conan", "extensions", "generators", "xmake_generator.py")
    local outputdir = path.absolute(".xmake/conan-generator")
    os.mkdir(outputdir)
    os.vrunv(python.program, {path.absolute("generate.py"), generator}, {curdir = outputdir})
    for _, filename in ipairs({"conanbuildinfo.xmake.lua", "conanbuildinfo_quoted.xmake.lua"}) do
        local buildinfo = io.load(path.join(outputdir, filename))
        t:require(buildinfo)
        local info = buildinfo.Windows_x86_64_Release
        t:are_equal(info.includedirs, {"C:/Program Files/quoted/include"})
        t:are_equal(info.defines, {[[ROOT=C:\new\test]], [[NAME="hello world"]]})
        t:are_equal(info.cflags, {"-O2", [[-DNAME="hello world"]]})
        t:are_equal(info.cxxflags, {[[/FI"C:\new folder\test.h"]]})
        t:are_equal(info.shflags, {[[-Wl,-rpath,"/opt/my libs"]]})
        t:are_equal(info.ldflags, {[[/LIBPATH:"C:\new folder\lib"]]})
    end
end
