set_version("1.0.1")
set_configfile("$(buildir)/demo.h")

if modes("debug") then
    set_symbols("debug")
    set_warnings("all")
    set_optimize("none")
    add_cxflags("-fsanitize=address", "-ftrapv")
end

if modes("release") then
    set_strip("all")
    set_symbols("hidden")
    add_cflags("-Wno-error=deprecated-declarations")
    set_warnings("all")
    set_optimize("smallest")
    add_vectorexts("sse2", "ssse3", "mmx")
end

if modes("profile") then
    set_symbols("debug")
    set_warnings("none")
    set_optimize("fastest")
end

if archs("x86", "x64") then
    add_defines("ARCH=\"$(arch)\"", "PLAT=$(plat)", "MODE=$(mode)", "HOST=$(host)")
end

add_option("option1")
    set_option_default(true)
    add_option_defines_if_ok("OPTION1_ENABLE")
    set_option_description("The option for definition and need not check.")

add_option("option2")
    set_option_default(false)
    add_option_defines_if_ok("OPTION2_ENABLE")
    add_option_cincludes("stdio.h", "hello1.h")
    add_option_includedirs("src/hello1")
    set_option_description("The option for finding includes.")

add_option("option3")
    set_option_default(false)
    add_option_defines_if_ok("OPTION3_ENABLE")
    add_option_links("hello1")
    add_option_linkdirs("$(buildir)")
    set_option_description("The option for finding links.")

add_option("option4")
    set_option_default(false)
    add_option_defines_if_ok("OPTION4_ENABLE")
    add_option_cincludes("stdio.h", "hello1.h")
    add_option_includedirs("src/hello1")
    add_option_links("hello1")
    add_option_linkdirs("$(buildir)")
    add_option_cfuncs("hello1")
    set_option_description("The option for finding interfaces.")

add_target("hello1")
    set_kind("static")
    add_files("src/hello1/*.c")

add_target("hello2")
    set_kind("shared")
    add_files("$(projectdir)/src/hello2/*.c")

add_target("hello3")
    set_kind("static")
    add_files("src/hello3/*.c") 
    add_headers("src/hello3/*.h")
    set_headerdir("$(buildir)/inc")
    set_targetdir("$(buildir)/lib")
    set_objectdir("$(buildir)/obj")

add_subdirs("src/demo")
