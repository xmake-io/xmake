
add_target("demo_c")
    set_kind("binary")
    add_deps("hello1")
    add_files("*.c")
    add_links("hello1")
    add_linkdirs("$(buildir)")
    add_includedirs("$(buildir)")
    add_cflags("-DHELLO1")

    if modes("release") then add_defines("NDEBUG") end
    if options("option1") then add_defines("OPTION1") end
    if options("option2") then add_defines("OPTION2") end
    if options("option3") then add_defines("OPTION3") end
    if options("option4") then add_defines("OPTION4") end

add_target("demo_cpp")
    set_kind("binary")
    add_deps("hello2") 
    add_files("*.cpp")
    set_config_h("$(buildir)/demo_cpp.h")
    add_linkdirs("$(buildir)")
    add_includedirs("$(buildir)")
    add_undefines("HELLO2")
    add_cxxflags("-DHELLO1")
    add_options("option1", "option2", "option3", "option4")
    set_packagescript(  function (target) 
                            print("package: " .. target.name)
                            return 1
                        end)

    if plats("macosx", "ios") then

        add_target("demo_objc")
            set_kind("binary")
            add_deps("hello3") 
            add_files("*.m")
            add_links("hello3") 
            add_linkdirs("$(buildir)/lib") 
            add_includedirs("$(buildir)/inc") 
            add_mflags("-DHELLO3", "-DPLAT=\"macosx\"", "-DARCH='armv7, arm64'")

        add_target("demo_objcpp")
            set_kind("binary")
            add_deps("hello3")
            add_files("*.mm")
            add_mxflags("-DHELLO3")
            add_ldflags("-L$(buildir)/lib", "-lhello3", "-lhello3")

            if plats("ios") then
                add_ldflags("-framework Cocoa", "-framework IOKit", "-framework CoreFoundation")
            end
    end

add_target("demo_swift")
    set_kind("binary")
    add_files("*.swift")
