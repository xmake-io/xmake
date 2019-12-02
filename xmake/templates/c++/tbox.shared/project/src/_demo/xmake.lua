-- add target
target("demo")

    -- set kind
    set_kind("binary")

    -- add deps
    add_deps("${TARGETNAME}")

    -- add defines
    add_defines("__tb_prefix__=\"demo\"")

    -- add files
    add_files("*.cpp")

    -- add packages
    add_packages("tbox")

