add_rules("mode.release", "mode.debug")
set_languages("c++20")

target("dependence")
    set_kind("binary")
    add_files("src/*.cpp", "src/*.mpp")

    if has_config("libc++") then
        set_values("c++.clang.modules.strict", true) -- clang std module clash with stl headers, header units and c++23 std module so we disable it when using libc++
    end