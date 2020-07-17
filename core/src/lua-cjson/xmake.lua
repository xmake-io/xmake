target("lua-cjson")
    set_kind("static")
    set_warnings("all")
    add_deps("luajit")
    if is_plat("windows") then
        set_languages("c89")
    end
    add_files("lua-cjson/*.c|fpconv.c")
    -- Use internal strtod() / g_fmt() code for performance and disable multi-thread 
    add_defines("NDEBUG", "USE_INTERNAL_FPCONV")
    if is_plat("windows") then
        -- Windows sprintf()/strtod() handle NaN/inf differently. Not supported.
        add_defines("DISABLE_INVALID_NUMBERS")
        add_defines("inline=__inline")
    end
           
