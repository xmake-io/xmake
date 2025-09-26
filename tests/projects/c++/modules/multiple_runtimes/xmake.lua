add_rules("mode.debug", "mode.release")
set_languages("c++23")
set_encodings("utf-8")

if is_plat("windows") then
    -- on windows, llvm libc++ std module is currently not supported, uncommend when supported
    -- target("llvm")
    --     set_kind("binary")
    --     set_toolchains("clang")
    --     set_runtimes("c++_shared")
    --     set_policy("build.c++.modules", true)
    --     add_files("src/main.cpp")

    target("llvm-msvc")
        set_kind("binary")
        set_toolchains("clang")
        set_policy("build.c++.modules", true)
        add_files("src/main.cpp")

    target("msvc")
        set_kind("binary")
        set_toolchains("msvc")
        set_policy("build.c++.modules", true)
        add_files("src/main.cpp")
else
    target("llvm")
        set_kind("binary")
        set_toolchains("clang")
        set_runtimes("c++_shared")
        set_policy("build.c++.modules", true)
        add_files("src/main.cpp")

    target("gnu")
        set_kind("binary")
        set_toolchains("gcc")
        set_runtimes("stdc++_shared")
        set_policy("build.c++.modules", true)
        set_policy("build.c++.modules.gcc.cxx11abi", true)
        add_files("src/main.cpp")
end
