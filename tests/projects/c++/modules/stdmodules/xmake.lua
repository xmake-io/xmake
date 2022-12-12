add_rules("mode.debug", "mode.release")
set_languages("c++23")

add_cxxflags("clang::-stdlib=libc++")

target("mod")
    set_kind("static")
    add_files("src/*.cpp", "src/*.mpp")

target("test")
    set_kind("binary")
    add_files("test/*.cpp")
    add_deps("mod")

if is_plat("windows") then
    target("mod-msvcifc")
        set_languages("c++20")
        set_kind("static")
        add_files("src/*.cpp", "src/*.mpp")
        set_values("c++.msvc.enable_std_ifc", true)
        add_defines("MSVC_MODULES")

    target("test-msvcifc")
        set_languages("c++20")
        set_kind("binary")
        add_files("test/*.cpp")
        add_deps("mod-msvcifc")
        set_values("c++.msvc.enable_std_ifc", true)
        add_defines("MSVC_MODULES")
end
