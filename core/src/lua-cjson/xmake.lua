target("lua-cjson")
    set_kind("static")
    set_warnings("all")
    if is_config("runtime", "luajit") then
        add_deps("luajit")
    else
        add_deps("lua")
    end
    if is_plat("windows") then
        set_languages("c89")
    end
    add_files("lua-cjson/*.c|fpconv.c")
    -- Use internal strtod() / g_fmt() code for performance and disable multi-thread
    add_defines("NDEBUG", "USE_INTERNAL_FPCONV")
    add_defines("XM_CONFIG_API_HAVE_LUA_CJSON", {public = true})
    if is_plat("windows") then
        add_defines("inline=__inline")
    end

