inherit("test_base")

GCC_MIN_VER = "11"
MSVC_MIN_VER = "14.30"

function main(t)
    local gcc_options = {fallbackscanner = true, compiler = "gcc", version = GCC_MIN_VER}
    -- gcc/arm64: internal compiler error: in core_vals, at cp/module.cc:6108
    -- on windows, mingw modulemapper doesn't handle headeunit path correctly, but it's working with mingw on macOS / Linux
    if os.arch() == "arm64" or is_subhost("msys") then
        gcc_options = nil
    end
    local msvc_options = {version = MSVC_MIN_VER}
    -- skip clang tests, headerunits with clang is not stable
    run_tests(nil, gcc_options, msvc_options)
end
