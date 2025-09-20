add_rules("mode.debug", "mode.release")
set_languages("c++23")
set_encodings("utf-8")

target("llvm")
    set_kind("binary")
    set_toolchains("clang")
    set_runtimes("c++_shared")
    set_policy("build.c++.modules", true)
    add_files("src/main.cpp")

if is_plat("linux") or is_plat("mingw") then
    target("gnu")
        set_kind("binary")
        set_toolchains("gcc")
        set_runtimes("stdc++_shared")
        set_policy("build.c++.modules", true)
        set_policy("build.c++.modules.gcc.cxx11abi", true)
        add_files("src/main.cpp")
end

if is_plat("windows") then
    target("msvc")
        set_kind("binary")
        set_toolchains("msvc")
        set_policy("build.c++.modules", true)
        add_files("src/main.cpp")
end
