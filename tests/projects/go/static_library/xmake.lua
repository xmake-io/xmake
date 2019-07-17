-- add rules
add_rules("mode.debug", "mode.release")

-- add target
target("module")

    -- set kind
    set_kind("static")

    -- add files
    add_files("src/test/*.go") 

-- add target
target("test")

    -- set kind
    set_kind("binary")

    -- add deps
    add_deps("module")

    -- add files
    add_files("src/*.go") 

    -- add link directory
    add_linkdirs("$(buildir)/$(plat)/$(arch)/$(mode)")

    -- add include directory
    add_includedirs("$(buildir)/$(plat)/$(arch)/$(mode)")

