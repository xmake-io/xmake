import("lib.detect.find_tool")
import("core.tool.toolchain")
import("utils.ci.is_running", {alias = "ci_is_running"})

function run_test(toolchain_name)
    local flags = ""
    if ci_is_running() then
        flags = "-vD"
    end

    local plat = os.host()
    local arch = os.arch()
    if is_subhost("msys") then
        plat = "mingw"
    end
    local toolchain_inst = toolchain.load(toolchain_name, {plat = plat, arch = arch})
    if not toolchain_inst or not toolchain_inst:check() then
        wprint(toolchain_name .. " not found, skipping tests")
        return
    end
    os.exec("xmake clean -a")
    os.exec("xmake f --toolchain=" .. toolchain_name .. " -c --yes " .. flags)
    os.run("xmake -r " .. flags)
end

function main(t)
    run_test("llvm")
    run_test("clang")
end
