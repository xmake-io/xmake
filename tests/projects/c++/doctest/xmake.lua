add_rules("mode.debug", "mode.release")

add_requires("doctest")

target("doctest")
    set_kind("binary")
    add_files("src/*.cpp")
    for _, testfile in ipairs(os.files("tests/*.cpp")) do
        add_tests(path.basename(testfile), {
            files = testfile,
            remove_files = "src/main.cpp",
            languages = "c++11",
            packages = "doctest",
            defines = "DOCTEST_CONFIG_IMPLEMENT_WITH_MAIN"})
    end

target("doctest_shared")
    set_kind("shared")
    add_files("src/foo.cpp")
    for _, testfile in ipairs(os.files("tests/*.cpp")) do
        add_tests(path.basename(testfile), {
            kind = "binary",
            files = testfile,
            languages = "c++11",
            packages = "doctest",
            defines = "DOCTEST_CONFIG_IMPLEMENT_WITH_MAIN"})
    end

