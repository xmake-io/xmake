-- add target
target("${TARGETNAME}")

    -- set kind
    set_kind("binary")

    -- add definitions
    add_defines("__tb_prefix__=\"${TARGETNAME}\"")

    -- add packages
    add_packages("tbox")

    -- add files
    add_files("*.cpp")

