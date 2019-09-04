-- add rules
add_rules("mode.debug", "mode.release")

-- add target
target("merge_object")

    -- set kind
    set_kind("static")

    -- add files
    add_files("src/interface.c") 

    -- save object file
    after_build_file(function (target, sourcefile)
        os.cp(target:objectfile(sourcefile), "$(buildir)/merge_object/")
    end)

-- add target
target("test")

    -- set kind
    set_kind("binary")

    -- add deps
    add_deps("merge_object")

    -- add files
    add_files("src/test.c") 
    if is_plat("windows") then
        add_files("$(buildir)/merge_object/interface.c.obj")
    else
        add_files("$(buildir)/merge_object/interface.c.o")
    end

