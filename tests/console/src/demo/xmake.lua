
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
    configfile("$(buildir)/demo_cpp.h")
    linkdirs("$(buildir)")
    includedirs("$(buildir)")
    undefines("HELLO2")
    cxxflags("-DHELLO1")

    if plats("macosx", "ios") then

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

            if plats("ios") then
                ldflags("-framework Cocoa", "-framework IOKit", "-framework CoreFoundation")
            end
    end
