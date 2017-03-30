-- project
set_project("xmake")

-- version
set_version("2.1.3")

-- set xmake min version
set_xmakever("2.1.2")

-- set warning all as error
set_warnings("all", "error")

-- set language: c99, c++11
set_languages("c99", "cxx11")

-- disable some compiler errors
add_cxflags("-Wno-error=deprecated-declarations", "-fno-strict-aliasing")
add_mxflags("-Wno-error=deprecated-declarations", "-fno-strict-aliasing")

-- set the symbols visibility: hidden
set_symbols("hidden")

-- strip all symbols
set_strip("all")

-- fomit the frame pointer
add_cxflags("-fomit-frame-pointer")
add_mxflags("-fomit-frame-pointer")

-- for the windows platform (msvc)
if is_plat("windows") then 

    -- add some defines only for windows
    add_defines("NOCRYPT", "NOGDI")

    -- link libcmt.lib
    add_cxflags("-MT") 

    -- no msvcrt.lib
    add_ldflags("-nodefaultlib:\"msvcrt.lib\"")
end

-- for macosx
if is_plat("macosx") then
    add_ldflags("-all_load", "-pagezero_size 10000", "-image_base 100000000")
end

-- add package directories
add_packagedirs("pkg") 

-- add projects
add_subdirs("src/luajit", "src/xmake", "src/demo") 
