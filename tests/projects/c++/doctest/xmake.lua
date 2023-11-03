add_rules("mode.debug", "mode.release")

add_requires("doctest")

target("doctest")
    set_kind("binary")
    add_files("src/*.cpp")
    add_packages("doctest")
    add_tests("test1", {files = "tests/test_1.cpp",
                        remove_files = "src/main.cpp",
                        languages = "c++11",
                        defines = "DOCTEST_CONFIG_IMPLEMENT_WITH_MAIN"})
    add_tests("test2", {files = "tests/test_2.cpp",
                        remove_files = "src/main.cpp",
                        languages = "c++11",
                        defines = "DOCTEST_CONFIG_IMPLEMENT_WITH_MAIN"})


