set_version("1.0.1")
set_config_h("$(buildir)/demo.h")

if is_mode("debug") then
    set_symbols("debug")
    set_warnings("all")
    set_optimize("none")
    add_cxflags("-fsanitize=address", "-ftrapv")
end

if is_mode("release") then
    set_strip("all")
    set_symbols("hidden")
    add_cflags("-Wno-error=deprecated-declarations")
    set_warnings("all")
    set_optimize("smallest")
    add_vectorexts("sse2", "ssse3", "mmx")
end

if is_mode("profile") then
    set_symbols("debug")
    set_warnings("none")
    set_optimize("fastest")
end
  
if is_arch("x86", "x64") then
    add_defines("ARCH=\"$(arch)\"", "PLAT=$(plat)", "MODE=$(mode)", "HOST=$(host)")
end

option("option1")
    set_option_enable(true)
    set_option_showmenu(true)
    add_option_defines_h_if_ok("OPTION1_ENABLE")
    set_option_description("The option for definition and need not check.")

option("option2")
    set_option_enable(false)
    set_option_showmenu(true)
    add_option_defines_h_if_ok("OPTION2_ENABLE")
    add_option_cincludes("stdio.h", "hello1.h")
    add_option_includedirs("src/hello1")
    set_option_description("The option for finding includes.")

option("option3")
    set_option_enable(false)
    set_option_showmenu(true)
    add_option_defines_h_if_ok("OPTION3_ENABLE")
    add_option_links("hello1")
    add_option_linkdirs("$(buildir)")
    set_option_description("The option for finding links.")

option("option4")
    set_option_enable(false)
    set_option_showmenu(true)
    add_option_defines_h_if_ok("OPTION4_ENABLE")
    set_option_description("The option for finding interfaces.")
    if not is_plat("windows") then
        add_option_links("z", "sqlite3")
        add_option_cfuncs("sqlite3_open")
        add_option_cincludes("stdio.h", "sqlite3.h")
    end

target("hello1")
    set_kind("static")
    add_files("src/hello1/*.c")

target("hello2")
    set_kind("shared")
    add_files("$(projectdir)/src/hello2/*.c")

target("hello3")
    set_kind("static")
    add_files("src/hello3/*.c") 
    add_headers("src/(hello3/*.h)")
    set_headerdir("$(buildir)/inc")
    set_targetdir("$(buildir)/lib")
    set_objectdir("$(buildir)/obj")

target("hello4")
    set_kind("static")
    add_deps("hello1", "hello2")
    add_files("$(buildir)/.objs/hello1/**.o") 
    add_files("$(buildir)/.objs/hello2/**.obj") 

target("hello5")
    set_kind("static")
    add_deps("hello4", "hello1")
    add_files("$(buildir)/hello1.lib") 
    add_files("$(buildir)/libhello4.a") 

add_subdirs("src/demo")
