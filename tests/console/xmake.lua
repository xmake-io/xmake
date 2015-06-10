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
