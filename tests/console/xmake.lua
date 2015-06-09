project("console")

if modes("debug") then
    symbols("debug")
    warnings("all")
    optimize("none")
    cxflags("-fsanitize=address", "-ftrapv")
end

if modes("release") then
    strip("all")
    symbols("hidden")
    cflags("-Wno-error=deprecated-declarations")
    warnings("all")
    optimize("smallest")
    vectorexts("sse2", "ssse3", "mmx")
end

if modes("profile") then
    symbols("debug")
    warnings("none")
    optimize("fastest")
end

target("hello1")
    kind("static")
    files("src/hello1/*.c")

target("hello2")
    kind("shared")
    files("$(projectdir)/src/hello2/*.c")

target("hello3")
    kind("static")
    files("src/hello3/*.c") 
    headers("src/hello3/*.h")
    headerdir("$(buildir)/inc")
    targetdir("$(buildir)/lib")
    objectdir("$(buildir)/obj")

target("demo_c")
    kind("binary")
    deps("hello1")
    files("src/demo/*.c")
    links("hello1")
    linkdirs("$(buildir)")
    includedirs("$(buildir)")
    cflags("-DHELLO1")

    if modes("release") then defines("NDEBUG") end

target("demo_cpp")
    kind("binary")
    deps("hello2") 
    files("src/demo/*.cpp")
    version("1.0.1")
    configfile("$(buildir)/demo_cpp.h")
    linkdirs("$(buildir)")
    includedirs("$(buildir)")
    undefines("HELLO2")
    cxxflags("-DHELLO1")

    if platforms("macosx", "ios") then

        target("demo_objc")
            kind("binary")
            deps("hello3") 
            files("src/demo/*.m")
            links("hello3") 
            linkdirs("$(buildir)/lib") 
            includedirs("$(buildir)/inc") 
            mflags("-DHELLO3", "-DPLAT=\"macosx\"", "-DARCH='armv7, arm64'")

        target("demo_objcpp")
            kind("binary")
            deps("hello3")
            files("src/demo/*.mm")
            mxflags("-DHELLO3")
            ldflags("-L$(buildir)/lib", "-lhello3", "-lhello3")

            if platforms("ios") then
                ldflags("-framework Cocoa", "-framework IOKit", "-framework CoreFoundation")
            end
    end
