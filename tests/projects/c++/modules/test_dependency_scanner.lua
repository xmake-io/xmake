import("lib.detect.find_tool")
import("core.base.semver")
import("utils.ci.is_running", {alias = "ci_is_running"})

function _build()
    os.run("xmake f --foo=n --policies=build.c++.modules.std:n")
    local outdata
    if ci_is_running() then
        outdata = os.iorun("xmake -rvD")
    else
        outdata = os.iorun("xmake -rv")
    end
    if outdata then
        if outdata:find("FOO") then
            raise("Modules dependency scanner update does not work\n%s", outdata)
        end
    end
    outdata = os.iorun("xmake")
    if outdata then
        if outdata:find("compiling") or outdata:find("linking") or outdata:find("generating") then
            raise("Modules incremental compilation does not work\n%s", outdata)
        end
    end
end

function can_build()
    if is_subhost("windows") then
        return true
    elseif is_subhost("msys") then
        return true
    elseif is_host("linux") then
        local gcc = find_tool("gcc", {version = true})
        if gcc and gcc.version and semver.compare(gcc.version, "11.0") >= 0 then
            return true
        end
        local clang = find_tool("clang", {version = true})
        if clang and clang.version and semver.compare(clang.version, "14.0") >= 0 then
            return true
        end
    end
end

function main(t)
    if is_subhost("windows") then
        local clang = find_tool("clang", {version = true})
        if clang and clang.version and semver.compare(clang.version, "17.0") >= 0 then
            os.exec("xmake f --toolchain=clang -c --yes --policies=build.c++.modules.std:n")
            _build()
            os.exec("xmake clean -a")
            os.exec("xmake f --toolchain=clang --runtimes=c++_shared -c --yes --policies=build.c++.modules.std:n")
            _build()
        end

        os.exec("xmake clean -a")
        os.exec("xmake f -c --yes --policies=build.c++.modules.std:n")
        _build()
    elseif is_subhost("msys") then
        os.exec("xmake f -c -p mingw --yes --policies=build.c++.modules.std:n")
        _build()
    elseif is_host("linux") then
        local gcc = find_tool("gcc", {version = true})
        if gcc and gcc.version and semver.compare(gcc.version, "11.0") >= 0 then
            os.exec("xmake f -c --yes --policies=build.c++.modules.std:n")
            _build()
        end
        local clang = find_tool("clang", {version = true})
        if clang and clang.version and semver.compare(clang.version, "14.0") >= 0 then
            os.exec("xmake clean -a")
            os.exec("xmake f --toolchain=clang -c --yes --policies=build.c++.modules.std:n")
            _build()
            os.exec("xmake clean -a")
            os.exec("xmake f --toolchain=clang --runtimes=c++_shared -c --yes --policies=build.c++.modules.std:n")
            _build()
        end
    end
end
