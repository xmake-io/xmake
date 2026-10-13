inherit(".test_base")

function _build(opt)
    local output = os.iorunv(os.programfile(), {"build", "-rvD"})
    assert(not output:find("argument unused during compilation", 1, true), output)
    if opt.precompile_reduced_bmi and opt.two_phases then
        assert(output:find("--precompile-reduced-bmi", 1, true), output)
    elseif opt.two_phases then
        assert(output:find("--precompile", 1, true), output)
    else
        assert(not output:find("--precompile", 1, true), output)
    end
    os.execv(os.programfile(), {"run"})
    output = os.iorunv(os.programfile(), {"build"})
    assert(not output:find("compiling", 1, true), output)
end

function main(t)
    run_tests({compiler = "clang", version = "19", flags = {"--ccache=n"},
        precompile_reduced_bmi = false, build = _build})
    run_tests({compiler = "clang", version = "23", flags = {"--ccache=n"},
        precompile_reduced_bmi = true, build = _build})
end
