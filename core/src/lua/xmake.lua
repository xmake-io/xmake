target("lua")
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
    add_files("lua/*.c|lua.c|onelua.c|loslib.c")
    if not is_plat("iphoneos") then
        add_files("lua/loslib.c")
    end

    -- add definitions
    add_defines("LUA_COMPAT_5_1", "LUA_COMPAT_5_2", "LUA_COMPAT_5_3", {public = true})
    if is_plat("windows", "mingw") then
        -- it has been defined in luaconf.h
        --add_defines("LUA_USE_WINDOWS")
    elseif is_plat("macosx", "iphoneos") then
        add_defines("LUA_USE_MACOSX")
    else
        add_defines("LUA_USE_LINUX")
    end

    -- we just disable os.execute for ios, because os.execv do not use it
    -- @see https://github.com/xmake-io/xmake/issues/2187
    on_load("iphoneos", function (target)
        local loslib_file = target:autogenfile("loslib.c")
        os.cp(path.join(os.scriptdir(), "lua", "loslib.c"), loslib_file)
        io.replace(loslib_file, "system(cmd)", "0", {plain = true})
        target:add("files", loslib_file)
    end)
