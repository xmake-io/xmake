-- add target
add_target("[targetname]")

    -- set kind
    set_kind("static")

    -- add defines
    add_defines("__tb_prefix__=\"[targetname]\"")

    -- set the auto-generated config.h
    set_config_h("$(buildir)/[targetname]/config.h")
    set_config_h_prefix("CONFIG")

    -- add the header files for installing
    add_headers("../([targetname]/**.h)")

    -- add includes directory
    add_includedirs("$(buildir)")
    add_includedirs("$(buildir)/[targetname]")

    -- set the object files directory
    set_objectdir("$(buildir)/.objs")

    -- add packages
    add_options("tbox", "base")

    -- add files
    add_files("*.cpp") 

