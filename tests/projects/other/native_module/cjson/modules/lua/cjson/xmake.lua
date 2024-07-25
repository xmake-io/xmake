add_rules("mode.debug", "mode.release")

target("cjson")
    add_rules("module.shared")
    set_warnings("all")
    if is_plat("windows") then
        set_languages("c89")
    end
    add_files("src/*.c")
    add_files("../../../../../../../../core/src/lua-cjson/lua-cjson/*.c|fpconv.c")
    -- Use internal strtod() / g_fmt() code for performance and disable multi-thread
    add_defines("NDEBUG", "USE_INTERNAL_FPCONV")
    add_defines("XM_CONFIG_API_HAVE_LUA_CJSON")
    if is_plat("windows") then
        -- Windows sprintf()/strtod() handle NaN/inf differently. Not supported.
        add_defines("DISABLE_INVALID_NUMBERS")
        add_defines("inline=__inline")
    end

