add_rules("mode.release", "mode.debug")
set_languages("c++20")

target("hello")
    set_kind("binary")
    set_pcxxheader("src/test.h")
    add_files("src/*.cpp", "src/*.mpp")
