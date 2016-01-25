-- add target
add_target("demo")

    -- set kind
    set_kind("binary")

    -- add deps
    add_deps("[targetname]")

    -- add defines
    add_defines("__tb_prefix__=\"demo\"")

    -- set the object files directory
    set_objectdir("$(buildir)/.objs")

    -- add links directory
    add_linkdirs("$(buildir)")

    -- add includes directory
    add_includedirs("$(buildir)")
    add_includedirs("$(buildir)/[targetname]")

    -- add links
    add_links("[targetname]")

    -- add packages
    add_options("tbox", "base")

    -- add files
    add_files("*.c") 

