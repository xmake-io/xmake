import("lib.detect.find_tool")
import("core.base.semver")
import("detect.sdks.find_vstudio")
import("utils.ci.is_running", {alias = "ci_is_running"})

function _build()
    if ci_is_running() then
        os.run("xmake -rvD")
    else
        os.run("xmake -r")
    end
    local outdata = os.iorun("xmake")
    if outdata then
        if outdata:find("compiling") or outdata:find("linking") or outdata:find("generating") then
            raise("Modules incremental compilation does not work\n%s", outdata)
        end
    end
end

function main(t)
    -- TODO c++ modules with pch does not work for gcc now.
    if is_host("linux") then
        local clang = find_tool("clang", {version = true})
        if clang then
            os.exec("xmake f --toolchain=clang -c --yes --policies=build.c++.modules.std:n,build.c++.clang.fallbackscanner")
            _build()
        end
    else
        _build()
    end
end
