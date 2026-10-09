set_languages("c++20")
set_policy("build.c++.modules.std", false)

target("pcm_include_flags")
    set_kind("binary")
    add_files("main.cpp", "answer.cppm")
    add_includedirs("local headers")
    add_sysincludedirs("system headers")
    add_cxxflags("-Werror=unused-command-line-argument", {force = true})
