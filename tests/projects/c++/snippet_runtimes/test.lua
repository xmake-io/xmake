import("lib.detect.find_tool")
import("core.base.semver")
import("utils.ci.is_running", {alias = "ci_is_running"})

function _build()
    if ci_is_running() then
        assert(os.iorun("xmake -rvD"))
    else
        assert(os.iorun("xmake -r"))
    end
end

function main(t)
    local clang = find_tool("clang")
    if clang and not is_subhost("windows") then
        os.exec("xmake f --toolchain=clang --runtimes=c++_shared --yes")
        _build()
    end
end
