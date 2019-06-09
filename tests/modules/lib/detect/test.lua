import("lib.detect.find_toolname")

function test_find_toolname(t)
    t:are_equal(find_toolname("xcrun -sdk macosx clang"), "clang")
    t:are_equal(find_toolname("xcrun -sdk macosx clang++"), "clangxx")
    t:are_equal(find_toolname("/usr/bin/arm-linux-gcc"), "gcc")
    t:are_equal(find_toolname("/usr/bin/arm-linux-g++"), "gxx")
    t:are_equal(find_toolname("/usr/bin/arm-linux-ar"), "ar")
    t:are_equal(find_toolname("link.exe -lib"), "link")
    t:are_equal(find_toolname("arm-android-clang++"), "clangxx")
    t:are_equal(find_toolname("pkg-config"), "pkg_config")
    t:are_equal(find_toolname("gcc-5"), "gcc")
end

