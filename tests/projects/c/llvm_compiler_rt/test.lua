import("lib.detect.find_tool")
import("core.tool.toolchain")
import("utils.ci.is_running", {alias = "ci_is_running"})

function main(t)
    local flags = ""
    if ci_is_running() then
        flags = "-vD"
    end

    local llvm = toolchain.load("llvm")
    if not llvm or not llvm:check() then
        wprint("llvm not found, skipping tests")
        return
    end
    os.exec("xmake clean -a")
    os.exec("xmake f --toolchain=llvm -c --yes " .. flags)
    os.run("xmake -r " .. flags)
end
