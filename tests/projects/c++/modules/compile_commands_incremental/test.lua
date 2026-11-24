inherit(".test_base")
import("utils.ci.is_running", {alias = "ci_is_running"})

-- generating the project files must not touch the existing build inputs,
-- otherwise the next incremental build will recompile the object files
-- again
--
-- e.g. gcc module mapper files are recorded as dependencies by the
-- compiler depfiles and are rewritten by the project generator.
function _build()
    local flags = ""
    if ci_is_running() then
        flags = "-vD "
    end

    -- build for the first time
    os.exec("xmake -r " .. flags)

    os.sleep(1100) -- mtime has 1sec resolution, wait for 1.1 sec

    -- generate project files
    if os.isfile("compile_commands.json") then
        os.rm("compile_commands.json")
    end
    os.exec("xmake project " .. flags .. "-k compile_commands --lsp=clangd")
    assert(os.isfile("compile_commands.json"), "compile_commands.json not generated!")

    -- incremental build
    local outdata = os.iorun("xmake " .. flags)
    if outdata then
        for _, keyword in ipairs({"compiling", "linking", "archiving"}) do
            if outdata:find(keyword, 1, true) then
                raise("incremental build after generating compile_commands.json recompiles the project ('%s' found)\n%s", keyword, outdata)
            end
        end
    end
end

function main(_)
    local clang_options = {compiler = "clang", version = clang_min_ver(), build = _build}
    local gcc_options = {compiler = "gcc", version = gcc_min_ver(), build = _build}
    local msvc_options = {version = msvc_min_ver(), build = _build}
    run_tests(clang_options, gcc_options, msvc_options)
end
