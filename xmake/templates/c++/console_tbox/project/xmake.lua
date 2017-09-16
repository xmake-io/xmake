-- version
set_xmakever("2.1.6")

-- set warning all as error
set_warnings("all", "error")

-- set language: c99, c++11
set_languages("c99", "cxx11")

-- disable some compiler errors
add_cxflags("-Wno-error=deprecated-declarations", "-fno-strict-aliasing")
add_mxflags("-Wno-error=deprecated-declarations", "-fno-strict-aliasing")

-- set the object files directory
set_objectdir("$(buildir)/$(mode)/$(arch)/.objs")
set_targetdir("$(buildir)/$(mode)/$(arch)")

-- the debug mode
if is_mode("debug") then
    
    -- enable the debug symbols
    set_symbols("debug")

    -- disable optimization
    set_optimize("none")

    -- add defines for debug
    add_defines("__tb_debug__")
end

-- the release mode
if is_mode("release") then

    -- set the symbols visibility: hidden
    set_symbols("hidden")

    -- strip all symbols
    set_strip("all")

    -- fomit the frame pointer
    add_cxflags("-fomit-frame-pointer")

    -- enable fastest optimization
    set_optimize("fastest")
end

-- for the windows platform (msvc)
if is_plat("windows") then 

    -- the release mode
    if is_mode("release") then

        -- link libcmt.lib
        add_cxflags("-MT") 

    -- the debug mode
    elseif is_mode("debug") then

        -- link libcmtd.lib
        add_cxflags("-MTd") 
    end

    -- no msvcrt.lib
    add_ldflags("-nodefaultlib:\"msvcrt.lib\"")
end

-- the base package
option("base")
    set_default(true)
    if is_os("windows") then add_links("ws2_32") 
    elseif is_os("android") then add_links("m", "c") 
    else add_links("pthread", "dl", "m", "c") end

-- add requires
add_requires("tboox.tbox")

-- include project sources
includes("src") 
