-- version
set_xmakever("2.2.2")

-- set warning all as error
set_warnings("all", "error")

-- set language: c99, c++11
set_languages("c99", "cxx11")

-- disable some compiler errors
add_cxflags("-Wno-error=deprecated-declarations", "-fno-strict-aliasing")
add_mxflags("-Wno-error=deprecated-declarations", "-fno-strict-aliasing")

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
    add_ldflags("-nodefaultlib:msvcrt.lib")
end

-- add syslinks
if is_plat("windows") then add_syslinks("ws2_32") 
elseif is_plat("android") then add_syslinks("m", "c") 
else add_syslinks("pthread", "dl", "m", "c") end

-- add requires
add_requires("tbox", {debug = is_mode("debug")})

-- include project sources
includes("src") 

${FAQ}
