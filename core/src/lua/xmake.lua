target("lua")
    if not is_config("lua") then
        set_default(false)
    end
    set_kind("static")
    set_warnings("all")

    -- disable c99(/TP) for windows
    if is_plat("windows") then
        set_languages("c89")
    end

    -- add header files
    add_headerfiles("lua/(*.h)", {prefixdir = "lua"})

    -- add include directories
    add_includedirs("lua", {public = true})

    -- add the common source files
    add_files("lua/*.c|lua.c")

    -- add defines
    add_defines("LUA_COMPAT_5_1", "LUA_COMPAT_5_2", "LUA_COMPAT_5_3", {public = true})
    if is_plat("windows") then
        add_defines("LUA_USE_WINDOWS")
    elseif is_plat("macosx", "iphoneos") then
        add_defines("LUA_USE_MACOSX")
    else
        add_defines("LUA_USE_LINUX")
    end

