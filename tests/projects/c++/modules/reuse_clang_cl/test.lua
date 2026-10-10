inherit(".test_base")
import("core.base.colors")

function _build()
    local output = colors.ignore(os.iorun("xmake build -rvD"))
    local implementation_builds = 0
    for line in output:gmatch("[^\r\n]+") do
        if line:find("compiling.debug", 1, true) and line:endswith("sample.cpp") then
            implementation_builds = implementation_builds + 1
        end
    end
    assert(implementation_builds == 2, "dependency implementations must only build in their owning targets\n" .. output)
    for _, name in ipairs({"consumer_a", "consumer_b", "moduleonly_consumer"}) do
        assert(output:find("<" .. name .. "> reuse", 1, true), "expected module reuse for " .. name .. "\n" .. output)
    end
    for _, name in ipairs({"different_language", "different_define"}) do
        assert(not output:find("<" .. name .. "> reuse", 1, true), "unexpected module reuse for " .. name .. "\n" .. output)
    end
    for _, name in ipairs({"consumer_a", "consumer_b", "different_language", "different_define", "moduleonly_consumer"}) do
        os.execv(os.programfile(), {"run", name})
    end
    local incremental = os.iorun("xmake build")
    assert(not incremental:find("compiling", 1, true), incremental)
end

function main(t)
    if not is_subhost("windows") then
        return t:skip("clang-cl module reuse requires Windows")
    end
    for _, two_phases in ipairs({true, false}) do
        build_tests("clang-cl", {compiler = "clang-cl", version = clang_cl_min_ver(),
            flags = {"-m", "debug", "--ccache=n"}, two_phases = two_phases, build = _build})
    end
end
