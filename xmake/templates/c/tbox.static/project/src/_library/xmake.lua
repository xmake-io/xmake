-- add target
target("${TARGETNAME}")

    -- set kind
    set_kind("static")

    -- add defines
    add_defines("__tb_prefix__=\"${TARGETNAME}\"")

    -- add the header files for installing
    add_headerfiles("../(${TARGETNAME}/**.h)")

    -- add includes directory
    add_includedirs("..", {interface = true})

    -- add packages
    add_packages("tbox")

    -- add files
    add_files("*.c")

