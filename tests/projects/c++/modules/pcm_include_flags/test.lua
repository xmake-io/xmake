inherit(".test_base")

function _build(opt)
    local output = os.iorunv(os.programfile(), {"build", "-rvD"})
    assert(not output:find("argument unused during compilation", 1, true), output)
    if opt.two_phases then
        assert(output:find("--precompile", 1, true), output)
    else
        assert(not output:find("--precompile", 1, true), output)
    end
    os.execv(os.programfile(), {"run"})
    output = os.iorunv(os.programfile(), {"build"})
    assert(not output:find("compiling", 1, true), output)
end

function main(t)
    local toolchains = is_subhost("windows") and {"clang-cl", "clang"} or {"clang"}
    for _, toolchain in ipairs(toolchains) do
        for _, two_phases in ipairs({true, false}) do
            build_tests(toolchain, {compiler = toolchain, version = "19",
                flags = {"--ccache=n"}, two_phases = two_phases,
                precompile_reduced_bmi = false, build = _build})
        end
    end
end
