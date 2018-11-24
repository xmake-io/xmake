-- add target
target("[targetname]")

    -- set kind
    set_kind("binary")

    -- add defines
    add_defines("__tb_prefix__=\"[targetname]\"")

    -- set the auto-generated config.h
    set_config_header("$(buildir)/[targetname].config.h", {prefix = "CONFIG"})

    -- add packages
    add_packages("tbox")

    -- add files
    add_files("*.c") 

