-- set project version
set_version("1.6.3", {build = "%Y%m%d%H%M"})

-- set warning all as error
set_warnings("all", "error")

-- set language: c99, c++11
set_languages("c99", "cxx11")

-- add defines to config.h
set_configvar("_GNU_SOURCE", 1)
set_configvar("_REENTRANT", 1)

-- disable some compiler errors
add_cxflags("-Wno-error=deprecated-declarations", "-fno-strict-aliasing")
add_mxflags("-Wno-error=deprecated-declarations", "-fno-strict-aliasing")

-- the debug, coverage, valgrind or sanitize-address/thread mode
if is_mode("debug", "coverage", "valgrind", "asan", "tsan") then
    
    -- enable the debug symbols
    set_symbols("debug")

    -- disable optimization
    set_optimize("none")

    -- add defines for debug
    if is_mode("debug") then
        add_defines("__tb_debug__")
    end

    -- add defines for valgrind
    if is_mode("valgrind") then
        add_defines("__tb_valgrind__")
    end

    -- attempt to enable sanitize-address 
    if is_mode("asan") then
        add_cxflags("-fsanitize=address", "-ftrapv")
        add_mxflags("-fsanitize=address", "-ftrapv")
        add_ldflags("-fsanitize=address")
        add_defines("__tb_sanitize_address__")
    end

    -- attempt to enable sanitize-thread 
    if is_mode("tsan") then
        add_cxflags("-fsanitize=thread")
        add_mxflags("-fsanitize=thread")
        add_ldflags("-fsanitize=thread")
        add_defines("__tb_sanitize_thread__")
    end

    -- enable coverage
    if is_mode("coverage") then
        add_cxflags("--coverage")
        add_mxflags("--coverage")
        add_ldflags("--coverage")
    end
end

-- the release, profile mode
if is_mode("release", "profile") then

    -- the release mode
    if is_mode("release") then
        
        -- set the symbols visibility: hidden
        set_symbols("hidden")

        -- strip all symbols
        set_strip("all")

    -- the profile mode
    else
    
        -- enable the debug symbols
        set_symbols("debug")

        -- enable gprof
        add_cxflags("-pg")
        add_ldflags("-pg")
    end

    -- small or micro?
    if has_config("small", "micro") then
        set_optimize("smallest")
    else
        set_optimize("fastest")
    end

    -- disable stack protector for micro mode
    if has_config("micro") then
        add_cxflags("-fno-stack-protector")
    end
end

-- small or micro?
if has_config("small", "micro") then

    -- add defines for small
    add_defines("__tb_small__")

    -- add defines to config.h
    set_configvar("TB_CONFIG_SMALL", 1)
end

-- for the windows platform (msvc)
if is_plat("windows") then 

    -- add some defines only for windows
    add_defines("NOCRYPT", "NOGDI")

    -- the release mode
    if is_mode("release") then

        -- link libcmt.lib
        add_cxflags("-MT") 

    -- the debug mode
    elseif is_mode("debug") then

        -- enable some checkers
        add_cxflags("-Gs", "-RTC1") 

        -- link libcmtd.lib
        add_cxflags("-MTd") 
    end

    -- no msvcrt.lib
    add_ldflags("-nodefaultlib:msvcrt.lib")
    add_syslinks("ws2_32") 

elseif is_plat("android") then
    add_syslinks("m", "c") 
elseif is_plat("mingw") then
    add_syslinks("ws2_32", "pthread", "m")
else 
    add_syslinks("pthread", "dl", "m", "c") 
end

-- include project sources
includes("src") 
