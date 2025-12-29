add_rules("mode.debug", "mode.release")
set_languages("c++23")

target("llvm")
    set_kind("binary")
    add_files("src/*.cpp", "src/*.mpp")
    add_tests("test", { files = "test/test.cpp", remove_files = "src/main.cpp" })
