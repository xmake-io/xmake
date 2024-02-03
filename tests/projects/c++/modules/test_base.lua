import("lib.detect.find_tool")
import("core.base.semver")
import("utils.ci.is_running", {alias = "ci_is_running"})

function _build()
    if ci_is_running() then
        os.run("xmake -rvD")
    else
        os.run("xmake -r")
    end
end

function main(t)
    if is_subhost("windows") then
        local clang = find_tool("clang", {version = true})
        if clang and clang.version and semver.compare(clang.version, "14.0") >= 0 then
            os.exec("xmake f --toolchain=clang -c --yes")
            _build()
            os.exec("xmake clean -a")
            os.exec("xmake f --toolchain=clang --runtimes=c++_shared -c --yes")
            _build()
        end

        os.exec("xmake clean -a")
        os.exec("xmake f -c --yes")
        _build()
    elseif is_subhost("msys") then
        os.exec("xmake f -c -p mingw --yes")
        _build()
    elseif is_host("linux") then
        local gcc = find_tool("gcc", {version = true})
        if gcc and gcc.version and semver.compare(gcc.version, "11.0") >= 0 then
            os.exec("xmake f -c --yes")
            _build()
        end
        local clang = find_tool("clang", {version = true})
        if clang and clang.version and semver.compare(clang.version, "14.0") >= 0 then
            os.exec("xmake clean -a")
            os.exec("xmake f --toolchain=clang -c --yes")
            _build()
            os.exec("xmake clean -a")
            os.exec("xmake f --toolchain=clang --runtimes=c++_shared -c --yes")
            _build()
        end
    end
end
