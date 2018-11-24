-- add target
target("[targetname]")

    -- set kind
    set_kind("static")

    -- add defines
    add_defines("__tb_prefix__=\"[targetname]\"")

    -- set the auto-generated config.h
    set_config_header("$(buildir)/[targetname]/config.h", {prefix = "CONFIG"})

    -- add the header files for installing
    add_headers("../([targetname]/**.h)")

    -- add includes directory
    add_includedirs("$(buildir)")
    add_includedirs("$(buildir)/[targetname]")

    -- add packages
    add_packages("tbox")

    -- add files
    add_files("*.cpp") 

