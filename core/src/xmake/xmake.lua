-- add target
target("xmake")

    -- make as a static library
    set_kind("static")

    -- add deps
    add_deps("luajit")

    -- add defines
    add_defines("__tb_prefix__=\"xmake\"")

    -- set the auto-generated config.h
    set_config_h("$(projectdir)/xmake.config.h")
    set_config_h_prefix("XM_CONFIG")

    -- set the object files directory
    set_objectdir("$(buildir)/.objs")

    -- add includes directory
    add_includedirs("$(projectdir)", "../luajit/src")

    -- add packages
    add_packages("tbox", "base")

    -- add the common source files
    add_files("**.c") 
       
