add_rules("mode.debug", "mode.release")

add_cxxflags("clang::-stdlib=libc++")

option("stdifcsupport")
    set_default(false)
    set_showmenu(true)
option("stdimportsupport")
    set_default(false)
    set_showmenu(true)
option_end()

if has_config("stdimportsupport") then
    target("mod")
        set_languages("c++latest")
        set_kind("static")
        add_files("src/*.cpp", "src/*.mpp")

    target("test")
        set_kind("binary")
        set_languages("c++latest")
        add_files("test/*.cpp")
        add_deps("mod")
end

if has_config("stdifcsupport") then
    target("mod-msvcifc")
        set_kind("static")
        set_languages("c++latest", "clatest")
        add_files("src/*.cpp", "src/*.mpp")
        set_values("c++.msvc.enable_std_ifc", true)
        add_defines("MSVC_MODULES")

    target("test-msvcifc")
        set_kind("binary")
        set_languages("c++latest", "clatest")
        add_files("test/*.cpp")
        add_deps("mod-msvcifc")
        set_values("c++.msvc.enable_std_ifc", true)
        add_defines("MSVC_MODULES")
end
