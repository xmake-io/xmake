-- add target
target("[targetname]")

    -- set kind
    set_kind("binary")

    -- add defines
    add_defines("__tb_prefix__=\"[targetname]\"")

    -- add packages
    add_packages("tbox")

    -- add files
    add_files("*.c") 

