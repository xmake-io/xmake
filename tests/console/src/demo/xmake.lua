
add_target("demo_c")
    set_kind("binary")
    add_deps("hello1")
    add_files("src/demo/*.c")
    add_links("hello1")
    add_linkdirs("$(buildir)")
    add_includedirs("$(buildir)")
    add_cflags("-DHELLO1")

    if modes("release") then add_defines("NDEBUG") end
    if option("option1") then add_defines("OPTION1") end
    if option("option2") then add_defines("OPTION2") end
    if option("option3") then add_defines("OPTION3") end
    if option("option4") then add_defines("OPTION4") end

add_target("demo_cpp")
    set_kind("binary")
    add_deps("hello2") 
    add_files("src/demo/*.cpp")
    set_configfile("$(buildir)/demo_cpp.h")
    add_linkdirs("$(buildir)")
    add_includedirs("$(buildir)")
    add_undefines("HELLO2")
    add_cxxflags("-DHELLO1")
    add_options("option1", "option2", "option3", "option4")

    if plats("macosx", "ios") then

        add_target("demo_objc")
            set_kind("binary")
            add_deps("hello3") 
            add_files("src/demo/*.m")
            add_links("hello3") 
            add_linkdirs("$(buildir)/lib") 
            add_includedirs("$(buildir)/inc") 
            add_mflags("-DHELLO3", "-DPLAT=\"macosx\"", "-DARCH='armv7, arm64'")

        add_target("demo_objcpp")
            set_kind("binary")
            add_deps("hello3")
            add_files("src/demo/*.mm")
            add_mxflags("-DHELLO3")
            add_ldflags("-L$(buildir)/lib", "-lhello3", "-lhello3")

            if plats("ios") then
                add_ldflags("-framework Cocoa", "-framework IOKit", "-framework CoreFoundation")
            end
    end
