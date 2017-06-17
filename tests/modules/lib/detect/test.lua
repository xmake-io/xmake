import("lib.detect.find_toolname")

function main()
    assert(find_toolname("xcrun -sdk macosx clang") == "clang")
    assert(find_toolname("xcrun -sdk macosx clang++") == "clangxx")
    assert(find_toolname("/usr/bin/arm-linux-gcc") == "gcc")
    assert(find_toolname("/usr/bin/arm-linux-g++") == "gxx")
    assert(find_toolname("/usr/bin/arm-linux-ar") == "ar")
    assert(find_toolname("link.exe -lib") == "link")
    assert(find_toolname("arm-android-clang++") == "clangxx")
    assert(find_toolname("pkg-config") == "pkg_config")
    assert(find_toolname("gcc-5") == "gcc")
end

