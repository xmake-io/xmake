inherit(".test_base")
import("core.base.json")
import("utils.ci.is_running", {alias = "ci_is_running"})

-- https://github.com/xmake-io/xmake/issues/7864
function _build()
    local flags = ""
    if ci_is_running() then
        flags = "-vD "
    end
    os.run("xmake project " .. flags .. "-k compile_commands")
    local files = {}
    for _, entry in ipairs(json.loadfile("compile_commands.json")) do
        files[path.filename(entry.file)] = true
    end
    assert(files["mod.mpp"], "mod.mpp not found in compile_commands.json")
    assert(files["main.cpp"], "main.cpp not found in compile_commands.json")
end

function main(_)
    local clang_options = {compiler = "clang", version = clang_min_ver(), build = _build}
    local gcc_options = {compiler = "gcc", version = gcc_min_ver(), build = _build}
    local msvc_options = {version = msvc_min_ver(), build = _build}
    run_tests(clang_options, gcc_options, msvc_options)
end
